{  lbc_medical.pas - Handles Pharmacode One-Track and Two-Track, 
                     CodaBar as well as Code 32

  Based on Zint (done by Robin Stuart and the Zint team)
    http://github.com/zint/zint
  and Pascal adaption by TheUnknownOnes
    http://theunknownones.net
    
  Refactoring: W. Pamler
} 

unit lbc_medical;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, zint;

function pharma_one(ASymbol: PZintSymbol; const ASource: String): Integer;
function pharma_two(ASymbol: PZintSymbol; const ASource: String): Integer;
function codabar(ASymbol: PZintSymbol; const ASource: String): Integer;
function code32(Asymbol: PZintSymbol; const ASource: String): Integer;

implementation

uses
  math,
  lbc_code, lbc_helper;
  
{ 'Pharmacode can represent only a single integer from 3 to 131070. Unlike other
   commonly used one-dimensional barcode schemes, pharmacode does not store the 
   data in a form corresponding to the human-readable digits; the number is 
   encoded in binary, rather than decimal. 
   Pharmacode is read from right to left: with n as the bar position starting
   at 0 on the right, each narrow bar adds 2n to the value and each wide bar 
   adds 2(2^n).
   The minimum barcode is 2 bars and the maximum 16, so the smallest number 
   that could be encoded is 3 (2 narrow bars) and the biggest is 131070 
   (16 wide bars).'
 - http://en.wikipedia.org/wiki/Pharmacode 

  This code uses the One Track Pharamacode calculating algorithm as recommended 
  by the specification at http://www.laetus.com/laetus.php?request=file&id=69 }
function pharma_one(ASymbol: PZintSymbol; const ASource: string): Integer;
var
  tester, counter, error_number, src_len: Integer;
  inter: String;
  dest: String;
begin
  src_len := Length(ASource);
  
  if (src_len > 6) then
  begin
    ASymbol^.SetErrorText('Input too long (max 6 characters)');
    Result := ERROR_TOO_LONG; 
    exit;
  end;
  
  error_number := is_sane(NEON, ASource);
  if (error_number = ERROR_INVALID_DATA) then
  begin
    ASymbol^.SetErrorText('Invalid characters in data');
    Result := error_number; 
    exit;
  end;

  tester := StrToIntDef(ASource, 0);
  if (tester < 3) or (tester > 131070) then
  begin
    ASymbol^.SetErrorText('Data out of range');
    Result := ERROR_INVALID_DATA; 
    exit;
  end;

  inter := '';
  repeat
    if tester and 1 = 0 then
    begin
      inter := inter + 'W';
      tester := (tester - 2) div 2;
    end else
    begin
      inter := inter + 'N';
      tester := (tester - 1) div 2;
    end;
  until (tester = 0);

  dest := '';
  for counter := Length(inter) downto 1 do
  begin
    if (inter[counter] = 'W') then
      dest := dest + '32'
    else
      dest := dest + '12';
  end;
  expand(ASymbol, dest);
  
  ASymbol^.SetText(PChar(ASource));

  Result := error_number; 
end;
  
  
{ This code uses the Two Track Pharmacode defined in the document at
  http://www.laetus.com/laetus.php?request=file&id=69 and using a modified
  algorithm from the One Track system. This standard accepts integet values
  from 4 to 64570080. }

function pharma_two_calc(ASymbol: PZintSymbol; const ASource: string;
  var dest: string): Integer;
var
  tester, counter: Integer;
  inter: String;
  error_number: Integer;
begin
  tester := StrToIntDef(ASource, 0);

  if (tester < 4) or (tester > 64570080) then
  begin
    ASymbol^.SetErrorText('Data out of range');
    Result := ERROR_INVALID_DATA; 
    exit;
  end;
  
  error_number := 0;
  inter := '';
  repeat
    case tester mod 3 of
      0: begin
           inter := inter + '3';
           tester := (tester - 3) div 3;
         end;
      1: begin
           inter := inter + '1';
           tester := (tester - 1) div 3;
         end;
      2: begin
           inter := inter + '2';
           tester := (tester - 2) div 3;
         end;
    end;
  until tester = 0;

  dest := '';
  for counter := Length(inter) downto 1 do
    dest := dest + inter[counter];

  Result := error_number; 
end;

{ Draws the patterns for two track pharmacode }
function pharma_two(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  height_pattern: string = ''; 
  i, src_len, writer, error_number: Integer;
begin
  src_len := Length(ASource);
  
  if (src_len > 8) then
  begin
    ASymbol^.SetErrorText('Input too long (max 8 characters).');
    Result := ERROR_TOO_LONG; 
    exit;
  end;
  
  error_number := is_sane(NEON, ASource);
  if (error_number = ERROR_INVALID_DATA) then
  begin
    ASymbol^.SetErrorText('Invalid characters in data');
    Result := error_number; 
    exit;
  end;
  
  error_number := pharma_two_calc(ASymbol, ASource, height_pattern);
  if (error_number <> 0) then
  begin
    Result := error_number; 
    exit;
  end;

  writer := 0;
  for i := 1 to Length(height_pattern) do
  begin
    if ((height_pattern[i] = '2') or (height_pattern[i] = '3')) then
    begin
      set_module(ASymbol, 0, writer);
    end;
    if ((height_pattern[i] = '1') or (height_pattern[i] = '3')) then
    begin
      set_module(ASymbol, 1, writer);
    end;
    Inc(writer, 2);
  end;
  ASymbol^.rows := 2;
  ASymbol^.width := writer - 1;
  
  ASymbol^.SetText(ASource);

  Result := error_number; 
end;
  
                  
{ The Codabar system consisting of simple substitution }
//chaosben: some changes where made based on the article at http://en.wikipedia.org/wiki/Codabar}
function codabar(ASymbol: PZintSymbol; const ASource: String): Integer;
const
  CALCIUM = 
    '0123456789-$:/.+ABCD';
  CODA_TABLE: array[0..19] of string = (
    '11111221', '11112211', '11121121', '22111111', '11211211', 
    '21111211',	'12111121', '12112111', '12211111', '21121111', 
    '11122111', '11221111', '21112121', '21211121', '21212111', 
    '11212121', '11221211', '12121121', '11121221', '11122211'
  );   
  CODABAR_DELIMITERS: array[0..7] of Char = (
    'A', 'B', 'C', 'D', 'T', 'N', '*', 'E'
  );
var
  i, j: Integer;
  localSource: String;
begin
  localSource := Uppercase(ASource);
  
  // Replace alternate delimiters
  for i := 1 to Length(localSource) do
    for j := 4 to 7 do
      if localSource[i] = CODABAR_DELIMITERS[j] then
        localSource[i] := CODABAR_DELIMITERS[j - 4];
  
  // Check correct usage of delimiters
  for i := 2 to Length(localSource) - 1 do
  begin
    for j := Low(CODABAR_DELIMITERS) to High(CODABAR_DELIMITERS) do
    begin
      if localSource[i] = CODABAR_DELIMITERS[j] then
      begin
        ASymbol^.SetErrorText('The character "' + ASource[i] + '" can only be used as first and/or last character.');
        Result := ERROR_INVALID_DATA; 
        exit;
      end;
    end;
  end;   
  
  Result := basic_encoder(ASymbol, localsource,
    60, CALCIUM, '', CODA_TABLE, '', nil, false);
  
  if Result = 0 then
    ASymbol^.SetText(ASource);
end;    


{ Italian Pharmacode }
function code32(ASymbol: PZintSymbol; const ASource: String): Integer;
const
  TABLE = '0123456789BCDFGHJKLMNPQRSTUVWXYZ';
var
  i, j, error_number, checksum, checkpart: Integer;
  localstr: String = '';
  resultstr: String = '';
  pharmacode, divisor: Integer;
  remainder: Integer = 0;
  codeword: array[0..5] of Integer = (0, 0, 0, 0, 0, 0);
begin
  { Validate the input }
  if (Length(ASource) > 8) then
  begin
    ASymbol^.SetErrorText('Input too long (max 8 characters)');
    Result := ERROR_TOO_LONG; 
    exit;
  end;
  
  error_number := is_sane(NEON, ASource);
  if (error_number = ERROR_INVALID_DATA) then
  begin
    ASymbol^.SetErrorText('Invalid characters in data');
    Result := error_number; 
    exit;
  end;

  { Add leading zeros as required }
  localstr := StringOfChar('0', 8 - Length(ASource)) + ASource; 

  { Calculate the check digit }
  checksum := 0;
  for i := 0 to 3 do
  begin
    j := i * 2 + 1;
    checkpart := StrToInt(localstr[j]);
    Inc(checksum, checkpart);
    checkpart := 2 * StrToInt(localstr[j + 1]); 
    if (checkpart >= 10) then
      inc(checksum, (checkpart - 10) + 1)
    else
      inc(checksum, checkpart);
  end;

  { Add check digit to data string }
  localstr := localstr + IntToStr(checksum mod 10);

  { Convert string into an integer value }
  pharmacode := StrToIntDef(localstr, 0);

  { Convert from decimal to base-32 }
  divisor := 33554432;
  for i := 5 downto 0 do
  begin
    DivMod(pharmacode, divisor, codeword[i], remainder);
    pharmacode := remainder;
    divisor := divisor div 32;
  end;
  
  { Look up values in 'Tabella di conversione' } 
  SetLength(resultstr, 6);
  for i := 5 downto 0 do
    resultstr[5 - i + 1] := TABLE[codeword[i]+1];
  
  { Plot the barcode using Code 39 }
  error_number := c39(ASymbol, resultstr);
  if (error_number <> 0) then 
  begin 
    Result := error_number; 
    exit; 
  end;

  { Override the normal text output with the Pharmacode number }
  ASymbol^.SetText('A' + localstr);

  Result := error_number; 
end;

end.

