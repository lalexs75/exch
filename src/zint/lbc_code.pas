{  lbc_code.pas - Handles Code 11, 39, 39+ and 93, as well as channel_code

  Based on Zint (done by Robin Stuart and the Zint team)
    http://github.com/zint/zint
  and Pascal adaption by TheUnknownOnes
    http://theunknownones.net
    
  Refactoring: W.Pamler
} 

unit lbc_code;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, zint;

function code_11(ASymbol: PZintSymbol; const ASource: String): Integer;
function c39(ASymbol: PZintSymbol; const ASource: String): Integer;
function pharmazentral(ASymbol: PZintSymbol; const ASource: String): Integer;
function ec39(ASymbol: PZIntSymbol; const ASource: String): Integer;
function c93(ASymbol: PZintSymbol; const ASource: String): Integer;
function channel_code(ASymbol: PZintSymbol; const ASource: String): Integer;


implementation
          
uses
  lbc_helper;
           
const 
  C11Table: array[0..10] of String = (
    '111121', '211121', '121121', '221111', '112121',  
    '212111', '122111',	'111221', '211211', '211111', 
    '112111'                                           
  );   

  { Code 39 tables checked against ISO/IEC 16388:2007 }
  C39Table: array[0..42] of String = ( 
    // bar-space-bar-space-bar-space-..., given in width units
    '1112212111', '2112111121', '1122111121', '2122111111', '1112211121',   // '0', '1', ...
    '2112211111', '1122211111', '1112112121', '2112112111', '1122112111',  
    '2111121121', '1121121121', '2121121111', '1111221121', '2111221111',   // 'A', 'B', ...
    '1121221111', '1111122121', '2111122111', '1121122111', '1111222111',   
    '2111111221', '1121111221', '2121111211', '1111211221', '2111211211',   
    '1121211211', '1111112221', '2111112211', '1121112211', '1111212211',   
    '2211111121', '1221111121', '2221111111', '1211211121', '2211211111',   
    '1221211111', '1211112121', '2211112111', '1221112111', '1212121111',   // 'Z', '-', ..
    '1212111211', '1211121211', '1112121211'                               
  );    // Code 39 character assignments (Table 1)
  
  { Encoding the full ASCII character set in Code 39 (Table A2) } 
  const EC39Ctrl: array[0..127] of String = (
    '%U', '$A', '$B', '$C', '$D', '$E', '$F', '$G', '$H', '$I', 
    '$J', '$K', '$L', '$M', '$N', '$O', '$P', '$Q', '$R', '$S', 
    '$T', '$U', '$V', '$W', '$X', '$Y', '$Z', '%A', '%B', '%C', 
    '%D', '%E', ' ',  '/A', '/B', '/C', '/D', '/E', '/F', '/G', 
    '/H', '/I', '/J', '/K', '/L', '-',  '.',  '/O', '0',  '1', 
    '2',  '3',  '4',  '5',  '6',  '7',  '8',  '9',  '/Z', '%F',
    '%G', '%H', '%I', '%J', '%V', 'A',  'B',  'C',  'D',  'E', 
    'F',  'G',  'H',  'I',  'J',  'K',  'L',  'M',  'N',  'O', 
    'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W',  'X',  'Y', 
    'Z',  '%K', '%L', '%M', '%N', '%O', '%W', '+A', '+B', '+C',
    '+D', '+E', '+F', '+G', '+H', '+I', '+J', '+K', '+L', '+M', 
    '+N', '+O', '+P', '+Q', '+R', '+S', '+T', '+U', '+V', '+W', 
    '+X', '+Y', '+Z', '%P', '%Q', '%R', '%S', '%T'
  );
  
  const C93Ctrl: array[0..127] of String = (
    'bU', 'aA', 'aB', 'aC', 'aD', 'aE', 'aF', 'aG', 'aH', 'aI', 
    'aJ', 'aK', 'aL', 'aM', 'aN', 'aO', 'aP', 'aQ', 'aR', 'aS', 
    'aT', 'aU', 'aV', 'aW', 'aX', 'aY', 'aZ', 'bA', 'bB', 'bC',
    'bD', 'bE', ' ',  'cA', 'cB', 'cC', 'cD', 'cE', 'cF', 'cG', 
    'cH', 'cI', 'cJ', 'cK', 'cL', 'cM', 'cN', 'cO', '0',  '1', 
    '2',  '3',  '4',  '5',  '6',  '7',  '8',  '9',  'cZ', 'bF',
    'bG', 'bH', 'bI', 'bJ', 'bV', 'A',  'B',  'C',  'D',  'E', 
    'F',  'G',  'H',  'I',  'J',  'K',  'L',  'M',  'N',  'O', 
    'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W',  'X',  'Y', 
    'Z',  'bK', 'bL', 'bM', 'bN', 'bO', 'bW', 'dA', 'dB', 'dC', 
    'dD', 'dE', 'dF', 'dG', 'dH', 'dI', 'dJ', 'dK', 'dL', 'dM', 
    'dN', 'dO', 'dP', 'dQ', 'dR', 'dS', 'dT', 'dU', 'dV', 'dW', 
    'dX', 'dY', 'dZ', 'bP', 'bQ', 'bR', 'bS', 'bT'
  );

  const C93Table: array[0..46] of String = (
    '131112', '111213', '111312', '111411', '121113', '121212',    // '0'..'5'
    '121311', '111114', '131211', '141111', '211113', '211212',    // '6'..'B'
    '211311', '221112', '221211', '231111', '112113', '112212',    // 'C'..'H'
    '112311', '122112', '132111', '111123', '111222', '111321',    // 'I'..'N'
    '121122', '131121', '212112', '212211', '211122', '211221',    // 'O'..'T'
    '221121', '222111', '112122', '112221', '122121', '123111',    // 'U'..'Z'
    '121131', '311112', '311211', '321111', '112131', '113121',    // '-', '.', ' ', '$', '/', '+' 
    '211131', '121221', '312111', '311121', '122211'               // '%', 'a', 'b', 'c', 'c'
  );


{-------------------------------------------------------------------------------
                                Code 11

  Allowed characters: 
    numeric digits (0-9), the hyphen character (-) 
    (Code 11 derives its name from these 11 characters).
  Length: 
    basically unlimited (function errors after 121 characters, though).
-------------------------------------------------------------------------------}  
function CheckSum_C11(ASource: String): String;
var
  i, len: Integer;
  c_digit, c_weight, c_count: Integer;
  k_digit, k_weight, k_count: Integer;
  weight: array of Integer = nil;
begin
  len := Length(ASource);
  SetLength(weight, len + 1);
  
  // Determine weights
  for i := 0 to len-1 do 
  begin
    if ASource[i+1] = '-' then
      weight[i] := 10
    else
      weight[i] := ctoi(ASource[i+1]);
  end;   
  
  // Calculate C checksum
  c_weight := 1;
  c_count := 0;
  for i := len-1 downto 0 do
  begin
    inc(c_count, c_weight * weight[i]);
    inc(c_weight);
    if (c_weight > 10) then
      c_weight := 1;
  end;
  c_digit := c_count mod 11;
  weight[len] := c_digit;     
    // weight is 0-based and has been allocated for len+1 elements.
  
  // Calculate K checksum
  k_weight := 1;
  k_count := 0;
  for i := len downto 0 do
  begin
    inc(k_count, k_weight * weight[i]);
    inc(k_weight);
    if (k_weight > 9) then
      k_weight := 1;
  end;
  k_digit := k_count mod 11;  
  
  // Convert checksum to string
  Result := itoc(c_digit) + itoc(k_digit);
  if (Result[1] = 'A') then Result[1] := '-';
  if (Result[2] = 'A') then Result[2] := '-';     
end;
  
function code_11(ASymbol: PZintSymbol; const ASource: String): Integer;
begin
  Result := basic_encoder(ASymbol, ASource,
    121, SODIUM, '112211', C11Table, '11221', @CheckSum_C11, false);
end;
               
    
{-------------------------------------------------------------------------------
                                    Code 39 
-------------------------------------------------------------------------------}
function CheckSum_C39(ASource: String): String;
var
  i, sum: Integer;
begin
  sum := 0;
  for i := 1 to Length(ASource) do
    inc(sum, pos(ASource[i], SILVER) - 1);

  sum := sum mod 43;
  
  if (sum < 10) then
    Result := itoc(sum)
  else
  begin
    if (sum < 36) then
      Result := Char((sum - 10) + Ord('A'))
    else
      case sum of
        36: Result := '-';
        37: Result := '.';
        38: Result := ' ';
        39: Result := '$';
        40: Result := '/';
        41: Result := '+';
        42: Result := #37;
        else
            Result := ' ';
      end;
  end;

  { Display a space check digit as _, otherwise it looks like an error }
  if (Result = ' ') then
    Result := '_';
end;

{ LOGMARS uses wider 'wide' bars than normal Code 39 }
procedure WiderBars(var s: String);
var
  i: Integer;
begin
  for i := 1 to Length(s) do
    if s[i]='2' then s[i] := '3';
end;
  
function c39(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  i, maxlen: Integer;
  startcode, stopcode: String;
  charcodes: array[0..42] of String;
  checkSumFunc: TCheckSumFunc;
begin
  startcode := '1211212111';
  stopcode  := '121121211';
  charcodes := C39Table;
  checkSumFunc := nil;
  maxlen := 74;
  
  if (ASymbol^.symbology = BARCODE_LOGMARS) or (ASymbol^.symbology = BARCODE_HIBC_39) then
  begin
    WiderBars(startcode);
    WiderBars(stopcode);
    for i := Low(charcodes) to High(charcodes) do
      WiderBars(charcodes[i]);
  end;
  
  if (ASymbol^.symbology = BARCODE_LOGMARS) or 
     (ASymbol^.option_2 = 1) or 
     (ASymbol^.option and OPTION_ADD_CHECKSUM = OPTION_ADD_CHECKSUM) then
  begin
    checkSumFunc := @CheckSum_C39;
    ASymbol^.Option := ASymbol^.Option or OPTION_ADD_CHECKSUM;
  end;
  
  if (ASymbol^.symbology = BARCODE_LOGMARS) then
    maxlen := 59;
  
  Result := basic_encoder(ASymbol, Uppercase(ASource),
    maxlen, SILVER, startcode, charcodes, stopcode, checkSumFunc, false);
  
  if ASymbol^.symbology = BARCODE_CODE39 then
    ASymbol^.SetText('*' + ASymbol^.GetText + '*');
end;


{-------------------------------------------------------------------------------
                           Pharmazentral Nummer (PZN) 
-------------------------------------------------------------------------------}
function pharmazentral(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  i, i0, error_number, zeros, digits, maxDigits, sum, src_len: Integer;
  localstr: String = '';
  check_digit: byte;
begin
  digits := ASymbol^.option_3;
  if not (digits in [7, 8]) then
    raise Exception.Create('[pharmazentral] Number of digits can only be 7 or 8');
  
  maxDigits := digits - 1;  // check-digit included

  src_len := Length(ASource);
  if (src_len > maxDigits) then
  begin
    ASymbol^.SetErrorText('Wrong input length');
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

  zeros := maxDigits - src_len;
  localstr := '-' + StringOfChar('0', zeros) + ASource;

  i0 := 7 - MaxDigits;
  sum := 0;
  for i := 1 to maxDigits do
    inc(sum, (i + i0) * ctoi(localstr[i+1]));  
    // wp: i+1 is correct because '-' was added to localStr
  
  check_digit := sum mod 11;
  localstr := localstr + itoc(check_digit);
  if check_digit = ord('A') then
  begin
    ASymbol^.SetErrorText('Invalid PZN Data');
    Result := ERROR_INVALID_DATA; 
    exit;
  end;

  Result := c39(ASymbol, localstr);
  
  ASymbol^.SetText('PZN' + localstr);
end;


{-------------------------------------------------------------------------------
                    Extended Code 39 - ISO/IEC 16388:2007 Annex A 
-------------------------------------------------------------------------------}

function ec39(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  i: Integer;
  buffer: string;
  check: char;
begin
  if (Length(ASource) > 74) then
  begin
    ASymbol^.SetErrorText('Input too long (max 74 characters).');
    Result := ERROR_TOO_LONG; 
    exit;
  end;

  { Creates a buffer string and places control characters into it }
  buffer := '';
  for i := 1 to Length(ASource) do
  begin
    if ASource[i] > #127 then
    begin
      { Cannot encode extended ASCII }
      ASymbol^.SetErrorText('Invalid character in input data');
      Result := ERROR_INVALID_DATA; 
      exit;
    end;
    buffer := buffer + EC39Ctrl[byte(ASource[i])];
  end;

  { Then send the buffer to the C39 function }
  Result := c39(ASymbol, buffer);
  
  if ASymbol^.Option and OPTION_DISPLAY_CHECKSUM = OPTION_DISPLAY_CHECKSUM then
  begin
    // Retrieve appended check character
    buffer := ASymbol^.GetText;
    check := buffer[Length(buffer)];
    ASymbol^.SetText(aSource + check);
  end else
    ASymbol^.SetText(ASource);
end;


{-------------------------------------------------------------------------------
                                  Code 93
                                  
  An advancement on Code 39 and the definition is a lot tighter 
  
  SILVER includes the extra characters a, b, c and d to represent Code 93 specific
  shift characters 1, 2, 3 and 4 respectively. These characters are never used by
  c39() and ec39() 
-------------------------------------------------------------------------------}
function CheckSum_C93(ASource: String): String;
var
  values: Array of Integer = nil;
  i: Integer;
  c, k, weight, len: Integer;
begin
  len := Length(ASource);
  SetLength(values, len + 1);   // Allocate one more element for check digit C
  for i := 1 to len do
    values[i-1] := pos(ASource[i], SILVER) - 1;
  
  { Check digit C }
  c := 0;
  weight := 1;
  for i := len-1 downto 0 do
  begin
    Inc(c, values[i] * weight);
    Inc(weight);
    if (weight = 21) then
      weight := 1;
  end;
  c := c mod 47;
  values[len] := c;      // Element at index len has been allocated above!

  { Check digit K }
  k := 0;
  weight := 1;
  for i := len downto 0 do  // Use len (rather than len-1) because of extra allocation
  begin
    Inc(k, values[i] * weight);
    Inc(weight);
    if (weight = 16) then
      weight := 1;
  end;
  k := k mod 47;
  
  Result := SILVER[c+1] + SILVER[k+1];
end;
                      
function c93(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  i: Integer;
  buffer: String;
  check: String;
begin
  if Length(ASource) > 107 then
  begin
    ASymbol^.SetErrorText('Input too long (max 107 characters).');
    Result := ERROR_TOO_LONG;
    exit;
  end;
  
  // Prepare message content
  buffer := '';
  for i := 1 to Length(ASource) do
  begin
    if ASource[i] > #127 then
    begin
      // Cannot encode extended ASCII
      ASymbol^.SetErrorText('Invalid characters in input data.');
      Result := ERROR_INVALID_DATA;
      exit;
    end;
    buffer := buffer + C93Ctrl[byte(ASource[i])];
  end;
  
  Result := basic_encoder(ASymbol, buffer, 
    107, SILVER, '111141', C93Table, '1111411', @CheckSum_C93, false
  ); 
  
  // Show the original input string as human-readable text
  if (Result = 0) then
  begin
    // If input string contains #0 replace it by space
    buffer := ASource;
    for i := 1 to Length(buffer) do
      if buffer[i] = #0 then buffer[i] := ' ';
    if (ASymbol^.Option and OPTION_DISPLAY_CHECKSUM <> 0) then
    begin
      // Extract check chars from generated symbol code...
      check := Copy(ASymbol^.GetText, Length(ASymbol^.GetText)-1, 2);
      // ... and append to original input string
      ASymbol^.SetText(buffer + check);
    end else
      ASymbol^.SetText(buffer);
  end;
end;           
              

{-------------------------------------------------------------------------------
                              channel_code
                              
 NextS() and NextB() are from ANSI/AIM BC12-1998 and are Copyright (c) AIM 1997 
 
 They are used here on the understanding that they form part of the 
 specification for Channel Code and therefore their use is permitted under the 
 following terms set out in that document:

 "It is the intent and understanding of AIM [t]hat the symbology presented in 
 this specification is entirely in the public domain and free of all use 
 restrictions, licenses and fees. AIM USA, its member companies, or individual 
 officers assume no liability for the use of this document." 
-------------------------------------------------------------------------------}

procedure CheckCharacter(var APattern: String; const AValue, ATarget_Value: Integer;
  const S, B: array of Integer);
var
  i: Integer;
begin
  if (AValue = ATarget_value) then
  begin
    { Target reached - save the generated pattern }
    APattern := '11110';
    for i := 0 to 10 do
      APattern := APattern + itoc(S[i]) + itoc(B[i]);
  end;
end;

procedure NextS(Chan, i, MaxS, MaxB: Integer; var S, B: array of Integer;
  var AValue, ATarget_value: Integer; var APattern: String); forward;

procedure NextB(chan, i, MaxB, MaxS: Integer; var S, B: array of Integer;
  var AValue, ATarget_value: Integer; var APattern: String);
var
  _b: Integer;
begin
  if (S[i] + B[i-1] + S[i-1] + B[i-2] > 4) then 
    _b := 1 
  else 
    _b := 2;
  
  if (i < Chan + 2) then
  begin
    while _b <= MaxB do
    begin
      B[i] := _b;
      NextS(Chan, i + 1, MaxS, MaxB + 1 - _b, S, B, AValue, ATarget_value, APattern);
      Inc(_b);
    end;
  end else 
  if (_b <= MaxB) then
  begin
    B[i] := MaxB;
    CheckCharacter(APattern, AValue, ATarget_value, S, B);
    Inc(AValue);
  end;
end;      

procedure NextS(Chan, i, MaxS, MaxB: Integer; var S, B: Array of Integer;
  var AValue, ATarget_value: Integer; var APattern: String);
var
  _s: Integer;
begin
  if (i < Chan + 2) then 
    _s := 1 
  else 
    _s := MaxS;
  while _s <= MaxS do
  begin
    S[i] := _s;
    NextB(Chan, i, MaxB, MaxS + 1 - _s, S, B, AValue, ATarget_value, APattern);
    Inc(_s);
  end;
end;   

{ Channel Code - According to ANSI/AIM BC12-1998 }
function channel_code(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  S: array[0..10] of Integer = (0,0,0,0,0,0,0,0,0,0,0);
  B: array[0..10] of Integer = (0,0,0,0,0,0,0,0,0,0,0);
  pattern: String = '';
  value, target_value: Integer;
  channels, i: Integer;
  error_number, zeros, src_len: Integer;
  outOfRange: Boolean;
begin
  src_len := Length(ASource);
  
  if (src_len > 7) then
  begin
    ASymbol^.SetErrorText('Input too long');
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

  if (ASymbol^.option_2 < 3) or (ASymbol^.option_2 > 8) then 
    channels := 0 
  else 
    channels := ASymbol^.option_2;
  if (channels = 0) then 
    channels := src_len + 1;
  if (channels = 2) then 
    channels := 3;

  target_value := 0;
  for i := 1 to src_len do
    target_value := target_value * 10 + ctoi(ASource[i]);

  outOfRange := false;
  case channels of
    3: if (target_value > 26) then outOfRange := true;
    4: if (target_value > 292) then outOfRange := true;
    5: if (target_value > 3493) then outOfRange := true;
    6: if (target_value > 44072) then outOfRange := true;
    7: if (target_value > 576688) then outOfRange := true;
    8: if (target_value > 7742862) then outOfRange := true;
    else outOfRange := true;
  end;
  if outOfRange then
  begin
    ASymbol^.SetErrorText('Value out of range');
    Result := ERROR_INVALID_DATA; 
    exit;
  end;

  B[0] := 1; 
  S[1] := 1; 
  B[1] := 1; 
  S[2] := 1; 
  B[2] := 1;
  value := 0;
  NextS(channels, 3, channels, channels, S, B, value, target_value, pattern);

  expand(ASymbol, pattern);
  
  zeros := channels - 1 - src_len;
  ASymbol^.SetText(StringOfChar('0', zeros) + ASource);

  Result := error_number; 
end;
        

end.

