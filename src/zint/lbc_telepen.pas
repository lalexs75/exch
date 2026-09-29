{  lbc_telepen.pas - Handles telepen alpha, and telepen numeric barcodes.

  Based on Zint (done by Robin Stuart and the Zint team)
    http://github.com/zint/zint
  and Pascal adaption by TheUnknownOnes
    http://theunknownones.net
    
  Refactoring: W.Pamler
    
  Fixes: Usage of character 'X' in input string.
} 
unit lbc_telepen;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, zint;

function telepen(ASymbol: PZintSymbol; const ASource: String): Integer;
function telepen_num(ASymbol: PZintSymbol; const ASource: String): Integer;

implementation

uses 
  lbc_helper;
 
const TeleTable: array[0..126] of String = (
  '1111111111111111', '1131313111',     '33313111',     '1111313131',     '3111313111',
  '11333131',         '13133131',       '111111313111', '31333111',       '1131113131',
  '33113131',         '1111333111',     '3111113131',   '1113133111',     '1311133111',
  '111111113131',     '3131113111',     '11313331',     '333331',         '111131113111',
  '31113331',         '1133113111',     '1313113111',   '1111113331',     '31131331',
  '113111113111',     '3311113111',     '1111131331',   '311111113111',   '1113111331',
  '1311111331',       '11111111113111', '31313311',     '1131311131',     '33311131',
  '1111313311',       '3111311131',     '11333311',     '13133311',       '111111311131',
  '31331131',         '1131113311',     '33113311',     '1111331131',     '3111113311',
  '1113131131',       '1311131131',     '111111113311', '3131111131',     '1131131311',
  '33131311',         '111131111131',   '3111131311',   '1133111131',     '1313111131',
  '111111131311',     '3113111311',     '113111111131', '3311111131',     '111113111311',
  '311111111131',     '111311111311',   '131111111311', '11111111111131', '3131311111',
  '11313133',         '333133',         '111131311111', '31113133',       '1133311111',
  '1313311111',       '1111113133',     '313333',       '113111311111',   '3311311111',
  '11113333',         '311111311111',   '11131333',     '13111333',       '11111111311111',
  '31311133',         '1131331111',     '33331111',     '1111311133',     '3111331111',
  '11331133',         '13131133',       '111111331111', '3113131111',     '1131111133',
  '33111133',         '111113131111',   '3111111133',   '111311131111',   '131111131111',
  '111111111133',     '31311313',       '113131111111', '3331111111',     '1111311313',
  '311131111111',     '11331313',       '13131313',     '11111131111111', '3133111111',
  '1131111313',       '33111313',       '111133111111', '3111111313',     '111313111111', 
  '131113111111',     '111111111313',   '313111111111', '1131131113',     '33131113',
  '11113111111111',   '3111131113',     '113311111111', '131311111111',   '111111131113',
  '3113111113',       '11311111111111', '331111111111', '111113111113',   '31111111111111',
  '111311111113',     '131111111113'
);

function CheckSum_telepen(ASource: String): String;
var
  i, sum: Integer;
  check_digit: Integer;
begin
  sum := 0;
  for i := 1 to Length(ASource) do
    inc(sum, ord(ASource[i]));
  
  check_digit := 127 - sum mod 127;
  if (check_digit = 127) then check_digit := 0;
  
  Result := char(check_digit);
end;

function telepen(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  i: Integer;
begin
  for i := 1 to Length(ASource) do
    if ASource[i] > #127 then       // wp: was #126, but this is against doc. 
    begin
      // Cannot encode extended ASCII
      ASymbol^.SetErrorText('Invalid characters in input data.');
      Result := ERROR_INVALID_DATA;
      exit;
    end;
  
  Result := basic_encoder(ASymbol, ASource, 
    30, '', TeleTable[ord('_')], TeleTable, TeleTable[ord('z')], @CheckSum_telepen, false);
end;

function telepen_num(ASymbol: PZintSymbol; const ASource: String): Integer;
const
  VALID_CHARS = NEON + 'X';
var
  src, dest: String;
  i, pair, checksum: Integer;
begin
  if Length(ASource) > 60 then
  begin
    ASymbol^.SetErrorText('Input too long (max 60 characters).');
    Result := ERROR_TOO_LONG;
    exit;
  end;
  
  src := UpperCase(ASource);
  Result := is_sane(VALID_CHARS, src);
  if Result = ERROR_INVALID_DATA then
  begin
    ASymbol^.SetErrorText('Invalid characters in data.');
    exit;
  end;
  
  // Add a leading zero if required (the input string length must be even).
  if odd(Length(src)) then
    src := '0' +src;
  
  // START character
  dest := TeleTable[ord('_')];
  
  // Extract pairs of digits. Their numerical value is encoded. An 'X' is 
  // allowed to identify single-digit numbers; it must be the LAST character of
  // a pair.
  // Example: 466X33 is valid     (pairs 46, 6X, 33)
  //          46X333 is not valid (pairs 46, X3, 33)
  i := 1;
  checksum := 0;
  while i < Length(src) do
  begin
    if src[i] = 'X' then
    begin
       ASymbol^.SetErrorText('Invalid position of X in Telepen data.');
       Result := ERROR_INVALID_DATA;
       exit;
    end;
    if src[i+1] = 'X' then
      pair := StrToInt(src[i]) + 17
    else
      pair := StrToInt(src[i] + src[i+1]) + 27;
    dest := dest + TeleTable[pair];
    inc(checksum, pair);
    inc(i, 2);
  end;
  
  checksum := 127 - checksum mod 127;
  if checksum = 127 then checksum := 0;
  dest := dest + TeleTable[checksum];
  
  // STOP character
  dest := dest + TeleTable[ord('z')];
  
  // Expand to modules
  expand(ASymbol, dest);
  
  // Store human-readable text.
  ASymbol^.SetText(src);
end;

end.
                

