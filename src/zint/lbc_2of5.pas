{  lbc_2of5.pas - Handles "two-of-five" code variants

  Based on Zint (done by Robin Stuart and the Zint team)
    http://github.com/zint/zint
  and Pascal adaption by TheUnknownOnes
    http://theunknownones.net
    
  Refactoring: W.Pamler
  
  Generated bar codes checked against 
    https://products.aspose.app/barcode/de/generate/
} 

unit lbc_2of5;

{$mode objfpc}{$H+}

interface

uses
  zint;

{ Code 2 of 5 Matrix }
function matrix_two_of_five(ASymbol: PZintSymbol; const ASource: String): Integer; 

{ Code 2 of 5 IATA }
function iata_two_of_five(ASymbol: PZintSymbol; const ASource: String): Integer; 

{ Code 2 of 5 Industrial }
function industrial_two_of_five(ASymbol: PZintSymbol; const ASource: String): Integer;

{ Code 2 of 5 Data Logic }
function logic_two_of_five(ASymbol: PZintSymbol; const ASource: String): Integer;

{ Code 2 of 5 Interleaved }
function interleaved_two_of_five(ASymbol: PZintSymbol; const ASource: String): Integer;

{ ITF-14 }
function itf14(ASymbol: PZintSymbol; const ASource: String): Integer;

{ Deutsche Post Identcode }
function dpident(ASymbol: PZintSymbol; const ASource: String): Integer;

{ Deutsche Post Leitcode }
function dpleit(ASymbol: PZintSymbol; const ASource: String): Integer;


implementation

uses
  SysUtils, lbc_helper;

const
  C25MatrixTable: array[0..9] of String = (
    '113311', '311131', '131131', '331111', '113131', 
    '313111', '133111', '111331', '311311', '131311'
  );

  C25IndustTable: array[0..9] of String = (
    '1111313111', '3111111131', 
    '1131111131', '3131111111', 
    '1111311131', '3111311111', 
    '1131311111', '1111113131', 
    '3111113111', '1131113111'
  );
  
  C25InterTable: array[0..9] of String = (
    '11331', '31113', '13113', '33111', '11313', 
    '31311', '13311', '11133', '31131', '13131'
  );   
  
function check_digit(count: Integer): Char; inline;
begin
  Result := itoc((10 - count mod 10) mod 10);
end;
 
{ Calculates the check digit for ITF-14 It is the same method as used for EAN-13 }
function CheckSum_EAN13(ASource: String): String;
var
  i,n, sum: Integer;
begin
  sum := 0;
  for i := Length(ASource) downto 1 do
  begin
    n := ctoi(ASource[i]);
    inc(sum, n);
    if odd(i) then
      Inc(sum, 2 * n);
  end;  
  Result := check_digit(sum);
end;
  
{ Calculates the check sum digit for Deutsche Post codes. }
function CheckSum_DP(ASource: String): String;
var
  i, n, sum: Integer;
begin
  sum := 0;
  for i := Length(ASource) downto 1 do
  begin
    n := ctoi(ASource[i]);
    inc(sum, 4*n);
    if not odd(i) then
      inc(sum, 5*n);
  end;
  Result := check_digit(sum);
end;

          
{ Basic encoder for interleaved two-of-five barcodes - they all work in
  the same way, only with different parameters:
    MaxLen - maximum length of input string
    AllowedChars - a string containing the allowed characters for this barcode type
    StartCode - starting code pattern
    CharCodes - code pattern for each allowed character
    StopCode - ending code pattern. 
    CheckCharsFunc - function to calculate a checksum
}
function basic_interleaved_two_of_five(ASymbol: PZIntSymbol; const ASource: String;
  MaxLen: Integer; const AllowedChars, StartCode: String; 
  const CharCodes: array of string; const StopCode: String;
  CheckSumFunc: TCheckSumFunc): Integer;
var
  i, j: Integer;
  src, dest, bars, spaces: String; 
begin
  if Length(ASource) > MaxLen then
  begin
    ASymbol^.SetErrorText('Input too long (max ' + IntToStr(MaxLen) + ' digits).');
    Result := ERROR_TOO_LONG;
    exit;
  end;
  
  Result := is_sane(AllowedChars, ASource);
  if Result = ERROR_INVALID_DATA then
  begin
    ASymbol^.SetErrorText('Invalid characters in data.');
    exit;
  end;
  
  src := ASource;
  
  // Add check digit(s) if a calculation function is provided
  if CheckSumFunc <> nil then
    src := src + CheckSumFunc(src);
  
  // Input must be an even number of characters for Interlaced 2 of 5 to work:
  // if an odd number of characters has been entered then add a leading zero.
  if odd(Length(src)) then
    src := '0' + src;

  // START character
  dest := StartCode;
  
  // Add encoded input string characters, but in an interleaved way
  i := 1;
  while i <= Length(src) do
  begin
    // Look up the bars and the spaces and put them in two strings 
    bars := '';
    lookup(AllowedChars, CharCodes, src[i], bars);
    spaces := '';
    lookup(AllowedChars, CharCodes, src[i + 1], spaces);

    // Then merge (interlace) the strings together
    for j := 1 to 5 do
      dest := dest + bars[j] + spaces[j];

    Inc(i, 2);
  end; 
  
  // STOP character
  dest := dest + StopCode;
  
  // Create symbol
  expand(ASymbol, dest);
  
  // Store human-readable text
  if ASymbol^.Option and OPTION_DISPLAY_CHECKSUM = OPTION_DISPLAY_CHECKSUM then
    ASymbol^.SetText(src)
  else
    ASymbol^.SetText(ASource);
end;


{-------------------------------------------------------------------------------
                       Code 2 of 5 Standard (Code 2 of 5 Matrix) 
-------------------------------------------------------------------------------}
function matrix_two_of_five(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  checksumFunc: TChecksumFunc;
begin
  if ASymbol^.Option and OPTION_ADD_CHECKSUM <> 0 then
    checksumFunc := @upc_checksum
  else
    checksumFunc := nil;
  Result := basic_encoder(ASymbol, ASource,
    80, NEON, '411111', C25MatrixTable, '41111', checksumFunc, false
  );
end;

{-------------------------------------------------------------------------------
                             Code 2 of 5 Industrial 
-------------------------------------------------------------------------------}
function industrial_two_of_five(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  checksumFunc: TChecksumFunc;
begin
  if ASymbol^.Option and OPTION_ADD_CHECKSUM <> 0 then
    checksumFunc := @upc_checksum
  else
    checksumFunc := nil;
  Result := basic_encoder(ASymbol, ASource,
    45, NEON, '313111', C25IndustTable, '31113', checksumFunc, false
  );
end;
         
{-------------------------------------------------------------------------------
                               Code 2 of 5 IATA 
-------------------------------------------------------------------------------}
function iata_two_of_five(ASymbol: PZintSymbol; const ASource: string): Integer;  
var
  checksumFunc: TChecksumFunc;
begin
  if ASymbol^.Option and OPTION_ADD_CHECKSUM <> 0 then
    checksumFunc := @upc_checksum
  else
    checksumFunc := nil;
  Result := basic_encoder(ASymbol, ASource,
    45, NEON, '1111', C25IndustTable, '311', checksumFunc, false
  );
end;

{-------------------------------------------------------------------------------
                          Code 2 of 5 Data Logic 
-------------------------------------------------------------------------------}
function logic_two_of_five(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  checksumFunc: TChecksumFunc;
begin
  if ASymbol^.Option and OPTION_ADD_CHECKSUM <> 0 then
    checksumFunc := @upc_checksum
  else
    checksumFunc := nil;
  Result := basic_encoder(ASymbol, ASource,
    80, NEON, '1111', C25MatrixTable, '311', checksumFunc, false
  );
end;


{-------------------------------------------------------------------------------
                         Code 2 of 5 Interleaved 
-------------------------------------------------------------------------------}
function interleaved_two_of_five(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  checksumFunc: TChecksumFunc;
begin
  if ASymbol^.Option and OPTION_ADD_CHECKSUM <> 0 then
    checksumFunc := @upc_checksum
  else
    checksumFunc := nil;
  Result := basic_interleaved_two_of_five(ASymbol, ASource,
    89, NEON, '1111', C25InterTable, '311', checksumFunc);
end;


{-------------------------------------------------------------------------------
                                ITF-14
-------------------------------------------------------------------------------}
function itf14(ASymbol: PZintSymbol; const ASource: String): Integer;
const
  MaxLength = 13;
var
  n: Integer;  // number of filler zeros
  src: String;
  checksumFunc: TChecksumFunc;
begin
  if Length(ASource) < MaxLength then
  begin
    n := MaxLength - Length(ASource);
    src := StringOfChar('0', n) + ASource;
  end else
    src := ASource;

  if ASymbol^.Option and OPTION_ADD_CHECKSUM <> 0 then
    checksumFunc := @CheckSum_EAN13
  else
    checksumFunc := nil;
      
  Result := basic_interleaved_two_of_five(ASymbol, src,
    MaxLength, NEON, '1111', C25InterTable, '311', checksumFunc);
end;


{-------------------------------------------------------------------------------
                         Deutsche Post Leitcode 
  
  Deutsche Post Leitcode encodes a string of 14 digits, as follows:
    - Five-digit postal code
    - Three-digit street identifier
    - Three-digit house number
    - Two-digit product code
    - One-digit check digit
  (https://barcodeguide.seagullscientific.com/Content/Symbologies/Leitcode.htm)
-------------------------------------------------------------------------------}
function dpleit(ASymbol: PZintSymbol; const ASource: String): Integer;
const
  MaxLength = 13;
var
  n: Integer;   // Number of filler zeros
  s: String;
begin
  if Length(ASource) < MaxLength then
  begin
    n := MaxLength - Length(ASource);
    s := StringOfChar('0', n) + ASource;
  end else
    s := ASource;

  Result := basic_interleaved_two_of_five(ASymbol, s,
    MaxLength, NEON, '1111', C25InterTable, '311', @CheckSum_DP);
  
  // Grouped output: "12345678901234" --> "12345.678.901.23 4"
  if (Result = 0) and (ASymbol^.Option and OPTION_GROUPED_CHARS = OPTION_GROUPED_CHARS) then
  begin
    s := ASymbol^.GetText;
    Insert(' ', s, 14);
    Insert('.', s, 12);
    Insert('.', s, 9);
    Insert('.', s, 6);
    ASymbol^.SetText(s);
  end;
end;

{-------------------------------------------------------------------------------
                         Deutsche Post Identcode 

  Deutsche Post Identcode encodes a string of (11 or) 12 digits, as follows:
    - Two-digit mail center distribution identifier
    - Three-digit customer code
    - Six-digit delivery identifier
    - One-digit check digit (optional - here it is always included.)
  (https://barcodeguide.seagullscientific.com/Content/Symbologies/Identcode.htm)
-------------------------------------------------------------------------------}
function dpident(ASymbol: PZintSymbol; const ASource: string): Integer;
const
  MaxLength = 11;
var
  n: Integer;  // Number of filler zeros
  s: String;
begin
  if Length(ASource) < MaxLength then
  begin
    n := MaxLength - Length(ASource);
    s := StringOfChar('0', n) + ASource;
  end else
    s := ASource;

  Result := basic_interleaved_two_of_five(ASymbol, s,
    MaxLength, NEON, '1111', C25InterTable, '311', @CheckSum_DP);
  
  // Grouped output: "12345678901" --> "12.345 678.901 2"
  if (Result = 0) and (ASymbol^.Option and OPTION_GROUPED_CHARS = OPTION_GROUPED_CHARS) then
  begin
    s := ASymbol^.GetText;
    Insert(' ', s, 12);
    Insert('.', s, 9);
    Insert(' ', s, 6);
    Insert('. ', s, 3);
    ASymbol^.SetText(s);
  end;
end;

end.

