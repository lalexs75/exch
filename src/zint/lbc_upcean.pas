{  lbc_upcean.pas - Handles EAN-based codes

  Based on Zint (done by Robin Stuart and the Zint team)
    http://github.com/zint/zint
  and Pascal adaption by TheUnknownOnes
    http://theunknownones.net
    
  Refactoring: W. Pamler
} 

unit lbc_upcean;

{$mode objfpc}{$H+}

interface

uses
  zint;

function eanx(ASymbol: PZintSymbol; const ASource: String): Integer;

implementation

uses
  SysUtils, lbc_helper;

const
  SODIUM = '0123456789+';
  EAN2 = 102;
  EAN5 = 105;

{ UPC and EAN tables checked against EN 797:1996 }
const
  { Number set for UPC-E symbol (EN Table 4) }  
  UPCParity0: array[0..9] of String = (
    'BBBAAA', 'BBABAA', 'BBAABA', 'BBAAAB', 'BABBAA', 
    'BAABBA', 'BAAABB', 'BABABA', 'BABAAB', 'BAABAB'
  ); 
  
  { Not covered by BS EN 797:1995 }
  UPCParity1: array[0..9] of String = (
    'AAABBB', 'AABABB', 'AABBAB', 'AABBBA', 'ABAABB', 
    'ABBAAB', 'ABBBAA', 'ABABAB', 'ABABBA', 'ABBABA'); 
  
  { Number sets for 2-digit add-on (EN Table 6) }
  EAN2Parity: array[0..3] of String = (
    'AA', 'AB', 'BA', 'BB'
  ); 
  
  { Number set for 5-digit add-on (EN Table 7) }
  EAN5Parity: Array[0..9] of String = (
    'BBAAA', 'BABAA', 'BAABA', 'BAAAB', 'ABBAA', 
    'AABBA', 'AAABB', 'ABABA', 'ABAAB', 'AABAB'
  ); 
  
  { Left hand of the EAN-13 symbol (EN Table 3) }
  EAN13Parity: Array[0..9] of String = (
    'AAAAA', 'ABABB', 'ABBAB', 'ABBBA', 'BAABB', 
    'BBAAB', 'BBBAA', 'BABAB', 'BABBA', 'BBABA'
  ); 

  { Representation set A and C (EN Table 1) }
  EANsetA: Array[0..9] of String = (
    '3211', '2221', '2122', '1411', '1132', 
    '1231', '1114', '1312', '1213', '3112'
  ); 

  { Representation set B (EN Table 1) }
  EANsetB: Array [0..9] of String = (
    '1123', '1222', '2212', '1141', '2311', 
    '1321', '4111', '2131', '3121', '2113'
  ); 

{-------------------------------------------------------------------------------
                                 UPC-A, UPC-E
-------------------------------------------------------------------------------}

{ UPC A is usually used for 12 digit numbers, but this function takes a 
  source of any length }
procedure upca_draw(const ASource: String; var dest: String);
var
  i, half_way: Cardinal;
begin 
  // START character 
  dest := '111';

  half_way := Length(ASource) div 2 + 1;
  for i := 1 to Length(ASource) do
  begin
    if (i = half_way) then
    begin
      { middle character - separates manufacturer no. from product no. }
      { also inverts right hand characters }
      dest := dest + '11111';
    end;

    lookup(NEON, EANsetA, ASource[i], dest);
  end;

  // STOP character 
  dest := dest + '111';
end;

{ Make a UPC A barcode when we haven't been given the check digit }
procedure upca(ASymbol: PZintSymbol; const ASource: String; var dest: String);
var
  gtin: String;
begin 
  gtin := ASource + upc_checksum(ASource);
  upca_draw(gtin, dest);
  ASymbol^.SetText(gtin);
end;

{ UPC E is a zero-compressed version of UPC A }
procedure upce(ASymbol: PZintSymbol; ASource: String; var dest: String);
var
  i, num_system: Cardinal;
  emode: char;
  check: Integer;
  check_digit: String;
  equivalent: String;
  parity: String = '';
  temp: String = '';
  hrt: String = '';   // "human-readable text"
begin 
  { Two number systems can be used - system 0 and system 1 }
  if Length(ASource) = 7 then
  begin
    case ASource[1] of
      '0': num_system := 0;
      '1': num_system := 1;
    else
      num_system := 0;
      ASource[1] := '0';
    end;
    temp := ASource;
    hrt := ASource;
    for i := 2 to 8 do
      ASource[i-1] := temp[i];
  end
  else
  begin
    num_system := 0;
    hrt := '0' + ASource;
  end;

  { Expand the zero-compressed UPCE code to make a UPCA equivalent (EN Table 5) }
  emode := ASource[6];
  equivalent := StringOfChar('0', 11);
  if (num_system = 1) then equivalent[1] := temp[1];
  equivalent[2] := ASource[1];
  equivalent[3] := ASource[2];

  case emode of
    '0',
    '1',
    '2': begin
      equivalent[4] := emode;
      equivalent[9] := ASource[3];
      equivalent[10] := ASource[4];
      equivalent[11] := ASource[5];
      end;
    '3': begin
      equivalent[4] := ASource[3];
      equivalent[10] := ASource[4];
      equivalent[11] := ASource[5];
      if (ASource[3] in ['0', '1', '2']) then
        { Note 1 - 'X3 shall not be equal to 0, 1 or 2' }
        ASymbol^.SetErrorText('Invalid UPC-E data');
      end;
    '4': begin
      equivalent[4] := ASource[3];
      equivalent[5] := ASource[4];
      equivalent[11] := ASource[5];
      if (ASource[4] = '0') then
        { Note 2 - 'X4 shall not be equal to 0' }
        ASymbol^.SetErrorText('Invalid UPC-E data');
      end;
    '5',
    '6',
    '7',
    '8',
    '9': begin
      equivalent[4] := ASource[3];
      equivalent[5] := ASource[4];
      equivalent[6] := ASource[5];
      equivalent[11] := emode;
      if (ASource[5] = '0') then
        { Note 3 - 'X5 shall not be equal to 0' }
        ASymbol^.SetErrorText('Invalid UPC-E data');
      end;
  end;

  // Get the check digit from the expanded UPCA code
  check_digit := upc_checksum(equivalent);
  check := StrToInt(check_digit);

  // Use the number system and check digit information to choose a parity scheme
  if (num_system = 1) then
    parity := UPCParity1[check]
  else
    parity := UPCParity0[check];

  // Take all this information and make the barcode pattern

  // START character 
  dest := '111';

  for i := 1 to Length(ASource) do
    case parity[i] of
      'A': lookup(NEON, EANsetA, ASource[i], dest);
      'B': lookup(NEON, EANsetB, ASource[i], dest);
    end;

  // STOP character 
  dest := dest + '111111';

  hrt := hrt + check_digit;
  ASymbol^.SetText(hrt);
end;

{ EAN-2 and EAN-5 add-on codes }
procedure add_on(const ASource: String; var dest: String; mode: Integer);
var
  parity: String;
  code_type: Integer;
  code_value: Integer;
  parity_bit: Integer;
  parity_sum: Integer;
  i: Integer;
begin
  // If an add-on then append with space
  if (mode <> 0) then
    dest := dest  + '9';

  // START character
  dest := dest + '112';

  // Determine EAN2 or EAN5 add-on
  if Length(ASource) = 2 then
    code_type := EAN2
  else
    code_type := EAN5;

  // Calculate parity for EAN2
  if (code_type = EAN2) then
  begin
    code_value := StrToInt(copy(ASource, 1, 2));
    parity_bit := code_value mod 4;
    parity := EAN2Parity[parity_bit];
  end else
  // Calculate parity for EAN5
  if (code_type = EAN5) then
  begin
    parity_sum := 
      3 * (StrToInt(ASource[1]) + StrToInt(ASource[3]) + StrToInt(ASource[5])) +
      9 * (StrToInt(ASource[2]) + StrToInt(ASource[4]));
    parity_bit := parity_sum mod 10;
    parity := EAN5Parity[parity_bit];
  end;

  for i := 1 to Length(ASource) do
  begin
    case parity[i] of
      'A': lookup(NEON, EANsetA, ASource[i], dest);
      'B': lookup(NEON, EANsetB, ASource[i], dest);
    end;
  
    { Glyph separator }
    if i <> Length(ASource) then
      dest := dest + '11';
  end;
end;
  

{-------------------------------------------------------------------------------
                                  EAN-13
-------------------------------------------------------------------------------}

{ Calculate the correct check digit for an EAN-13 barcode }
function ean_checksum(const ASource: String): String;
var
  i, sum, check_digit, char_val: Integer;
begin 
  sum := 0;

  for i := Length(ASource) downto 1 do
  begin
    char_val := StrToInt(ASource[i]);
    inc(sum, char_val);
    if not odd(i) then
      inc(sum, 2 * char_val);
  end;

  check_digit := 10 - sum mod 10;
  if (check_digit = 10) then check_digit := 0;
  
  Result := IntToStr(check_digit);
end;

procedure ean13(ASymbol: PZintSymbol; const ASource: String; var dest: String);
var
  i, half_way: Integer;
  gtin: String;
  parity: String;
begin
  // Add the appropriate check digit 
  gtin := ASource + ean_checksum(ASource);

  // Get parity for first half of the symbol
  parity := '';
  lookup(SODIUM, EAN13Parity, gtin[1], parity);

  // Now get on with the cipher
  half_way := 8;

  // START character
  dest := '111';
  for i := 2 to  Length(gtin) do
  begin
    if (i = half_way) then
    begin
      // middle character - separates manufacturer no. from product no. 
      // also inverses right hand characters 
      dest := dest + '11111';
    end;
    if (i > 2) and (i < 8) and (parity[i - 2] = 'B') then
      lookup(NEON, EANsetB, gtin[i], dest)
    else
      lookup(NEON, EANsetA, gtin[i], dest)
  end;

  // STOP character
  dest := dest + '111';

  ASymbol^.SetText(gtin);
end;


{-------------------------------------------------------------------------------
                                EAN-8

  Make an EAN-8 barcode when we haven't been given the check digit.
  EAN-8 is basically the same as UPC-A but with fewer digits 
-------------------------------------------------------------------------------}
procedure ean8(ASymbol: PZintSymbol; const ASource: String; var dest: String);
var
  gtin: String;
begin 
  gtin := ASource + upc_checksum(ASource);
  upca_draw(gtin, dest);
  ASymbol^.SetText(gtin);
end;


{-------------------------------------------------------------------------------
                                ISBN
-------------------------------------------------------------------------------}
{ For ISBN(13) only }
function isbn13_checksum(const ASource: String): String; 
var
  i, weight, sum, check: Integer;
begin
  sum := 0;
  weight := 1;
  for i := 1 to Length(ASource)-1 do      // Do no include check digit in calculation
  begin
    inc(sum, StrToInt(ASource[i]) * weight);
    if weight = 1 then
      weight := 3
    else
      weight := 1;
  end;

  check := sum mod 10;
  check := 10 - check;
  if (check = 10) then check := 0;
  
  Result := IntToStr(check);
end;

{ For ISBN(10) and SBN only }
function isbn_checksum(const ASource: String): String;
var
  i, weight, sum, check: Integer;
begin
  sum := 0;
  weight := 1;
  for i := 1 to Length(ASource)-1 do  // do not include check digit in calculation
  begin
    inc(sum, StrToInt(ASource[i]) * weight);
    inc(weight);
  end;

  check := sum mod 11;
  if check = 10 then
    Result := 'X'
  else
    Result := IntToStr(check);
end;

{ Make an EAN-13 barcode from an SBN or ISBN }
function isbn(ASymbol: PZintSymbol; var ASource: String; var dest: String): Integer; 
var
  check_digit: String;
  s: String;
begin
  // Input must be 9, 10 or 13 characters
  if not (Length(ASource) in [9, 10, 13]) then
  begin
    ASymbol^.SetErrorText('Wrong input length (9, 10, or 13 characters)');
    Result := ERROR_TOO_LONG;
    exit;
  end;

  Result := is_sane('0123456789Xx', ASource);
  if (Result = ERROR_INVALID_DATA) then
  begin
    ASymbol^.SetErrorText('Invalid characters in input');
    exit;
  end;
  
  case Length(ASource) of
    13: begin  // Using 13 character ISBN
          s := copy(ASource, 1, 3);
          if not ((s = '978') or (s = '979')) then
          begin
            ASymbol^.SetErrorText('Invalid ISBN');
            Result := ERROR_INVALID_DATA;
            exit;
          end;
          check_digit := isbn13_checksum(ASource);
          if ASource[Length(ASource)] <> check_digit[1] then
          begin
            ASymbol^.SetErrorText('Incorrect ISBN checksum');
            Result := ERROR_INVALID_CHECK;
            exit;
          end;
          Delete(ASource, Length(ASource), 1);  // Remove check digit for EAN13
          ean13(ASymbol, ASource, dest);
        end;  

    10: begin  // Using 10 digit ISBN
          check_digit := isbn_checksum(ASource);
          if check_digit[1] <> ASource[Length(ASource)] then
          begin
            ASymbol^.SetErrorText('Incorrect ISBN checksum');
            Result := ERROR_INVALID_CHECK;
            exit;
          end;
          ASource := '978' + ASource;
          Delete(ASource, Length(ASource), 1);  // Remove check digit for EAN13
          ean13(ASymbol, ASource, dest);
        end;
    
     9: begin   // Using 9 digit SBN
          // Add leading zero
          ASource := '0' + ASource;
          // Verify check digit
          check_digit := isbn_checksum(ASource);
          if check_digit[1] <> ASource[Length(ASource)] then
          begin
            ASymbol^.SetErrorText('Incorrect SBN checksum');
            Result := ERROR_INVALID_CHECK;
            exit;
          end;
          // Convert to EAN-13 number
          ASource := '978' + ASource;
          // Remove check digit for EAN13
          Delete(ASource, Length(ASource), 1);
          // Encode
          ean13(ASymbol, ASource, dest);
        end;
  end;
end;

{ Add leading zeroes to EAN and UPC strings }
procedure ean_leading_zeroes(ASymbol: PZintSymbol; 
  const ASource: String; var local_source: String);
var
  first_part: string;
  second_part: string;
  zfirst_part: string;
  zsecond_part: string;
  with_addon: Boolean;
  first_len, second_len: Integer;
  zfirst_len: Integer = 0;
  zsecond_len: Integer = 0;
  p, len: Integer;
begin
  len := Length(ASource);
  
  // Split input at '+' into two strings
  p := pos('+', ASource);
  with_addon := p > 0;
  if with_addon then
  begin
    first_len := p-1;
    second_len := len - p;
    first_part := copy(ASource, 1, first_len);
    second_part := copy(ASource, p+1, second_len);
  end else
  begin
    first_len := len;
    second_len := 0;
    first_part := ASource;
    second_part := '';
  end;

  { Calculate target lengths }
  if (second_len <= 5) then zsecond_len := 5;
  if (second_len <= 2) then zsecond_len := 2;
  if (second_len = 0) then zsecond_len := 0;
  
  case ASymbol^.symbology of
    BARCODE_EANX,
    BARCODE_EANX_CC: 
      begin
        if (first_len <= 12) then zfirst_len := 12;
        if (first_len <= 7) then zfirst_len := 7;
        if (second_len = 0) then
        begin
          if (first_len <= 5) then zfirst_len := 5;
          if (first_len <= 2) then zfirst_len := 2;
        end;
      end;
    BARCODE_UPCA,
    BARCODE_UPCA_CC:
      zfirst_len := 11;
    BARCODE_UPCE,
    BARCODE_UPCE_CC: 
      begin
        if (first_len = 7) then zfirst_len := 7;
        if (first_len <= 6) then zfirst_len := 6;
      end;
    BARCODE_ISBNX:
      if (first_len <= 9) then zfirst_len := 9;
  end;

  // Add leading zeros
  zfirst_part := StringOfChar('0', zfirst_len - first_len) + first_part;
  zsecond_part := StringOfChar('0', zsecond_len - second_len) + second_part;
   
  // Copy adjusted data back to local_source }
  local_source := zfirst_part;
  if zsecond_len <> 0 then
    local_source := local_source + '+' + zsecond_part;
end;

function eanx(ASymbol: PZintSymbol; const ASource: String): integer;
var
  i, p: Integer;
  src_len: Integer;
  local_source: String = '';
  first_part, second_part: String;
  dest: String = '';
  with_addon: Boolean;
begin
  src_len := Length(ASource);
  
  if (src_len > 19) then
  begin
    ASymbol^.SetErrorText('Input too long');
    Result := ERROR_TOO_LONG;
    Exit;
  end;
  
  if (ASymbol^.symbology <> BARCODE_ISBNX) then
  begin
    { ISBN has it's own checking routine }
    Result := is_sane('0123456789+', ASource);
    if (Result = ERROR_INVALID_DATA) then
    begin
      ASymbol^.SetErrorText('Invalid characters in data');
      exit;
    end;
  end else
  begin
    Result := is_sane('0123456789Xx+', ASource);
    if (Result = ERROR_INVALID_DATA) then
    begin
      ASymbol^.SetErrorText('Invalid characters in input');
      exit;
    end;
  end;

  // Add leading zeroes 
  ean_leading_zeroes(ASymbol, ASource, local_source);
  if (ASymbol^.symbology = BARCODE_ISBNX) then
    local_source := Uppercase(local_source);

  // Split string to parts before and after '+' parts}
  p := pos('+', local_source);
  with_addon := p > 0;
  if with_addon then
  begin
    first_part := copy(local_source, 1, p - 1);
    second_part := copy(local_source, p + 1);
  end else
  begin
    first_part := local_source;
    second_part := '';
  end;
      
  case ASymbol^.symbology of
    BARCODE_EANX:
      case Length(first_part) of
        2: begin       // EAN-2
             add_on(first_part, dest, 0);
             ASymbol^.SetText(first_part);
           end;
        5: begin       // EAN-5
             add_on(first_part, dest, 0);
             ASymbol^.SetText(first_part);
           end;
        7: ean8(ASymbol, first_part, dest);
       12: ean13(ASymbol, first_part, dest);
       else
           ASymbol^.SetErrorText('Invalid input length');
           Result := ERROR_TOO_LONG;
           exit;
      end;
    
    BARCODE_EANX_CC:
      case Length(first_part) of
        // Adds vertical separator bars according to ISO/IEC 24723 section 11.4
        7: begin
             set_module(ASymbol, ASymbol^.rows, 1);
             set_module(ASymbol, ASymbol^.rows, 67);
             set_module(ASymbol, ASymbol^.rows + 1, 0);
             set_module(ASymbol, ASymbol^.rows + 1, 68);
             set_module(ASymbol, ASymbol^.rows + 2, 1);
             set_module(ASymbol, ASymbol^.rows + 1, 67);
             ASymbol^.row_height[ASymbol^.rows] := 2;
             ASymbol^.row_height[ASymbol^.rows + 1] := 2;
             ASymbol^.row_height[ASymbol^.rows + 2] := 2;
             Inc(ASymbol^.rows, 3);
             ean8(ASymbol, first_part, dest);
           end;
       12: begin
             set_module(ASymbol, ASymbol^.rows, 1);
             set_module(ASymbol, ASymbol^.rows, 95);
             set_module(ASymbol, ASymbol^.rows + 1, 0);
             set_module(ASymbol, ASymbol^.rows + 1, 96);
             set_module(ASymbol, ASymbol^.rows + 2, 1);
             set_module(ASymbol, ASymbol^.rows + 2, 95);
             ASymbol^.row_height[ASymbol^.rows] := 2;
             ASymbol^.row_height[ASymbol^.rows + 1] := 2;
             ASymbol^.row_height[ASymbol^.rows + 2] := 2;
             Inc(ASymbol^.rows, 3);
             ean13(ASymbol, first_part, dest);
           end;
        else
           ASymbol^.SetErrorText('Invalid EAN input length');
           Result := ERROR_TOO_LONG;
           exit;
      end;         
        
    BARCODE_UPCA:
      if Length(first_part) = 11 then
        upca(ASymbol, first_part, dest)
      else
      begin
        ASymbol^.SetErrorText('Wrong input length');
        Result := ERROR_TOO_LONG;
        Exit;
      end;
    
    BARCODE_UPCA_CC:
      if Length(first_part) = 11 then
      begin
        set_module(ASymbol, ASymbol^.rows, 1);
        set_module(ASymbol, ASymbol^.rows, 95);
        set_module(ASymbol, ASymbol^.rows + 1, 0);
        set_module(ASymbol, ASymbol^.rows + 1, 96);
        set_module(ASymbol, ASymbol^.rows + 2, 1);
        set_module(ASymbol, ASymbol^.rows + 2, 95);
        ASymbol^.row_height[ASymbol^.rows] := 2;
        ASymbol^.row_height[ASymbol^.rows + 1] := 2;
        ASymbol^.row_height[ASymbol^.rows + 2] := 2;
        Inc(ASymbol^.rows, 3);
        upca(ASymbol, first_part, dest);
      end
      else
      begin
        ASymbol^.SetErrorText('Wrong UPC-A input length');
        Result := ERROR_TOO_LONG;
        Exit;
      end;
    
    BARCODE_UPCE:
      if Length(first_part) in [6, 7] then
        upce(ASymbol, first_part, dest)
      else
      begin
        ASymbol^.SetErrorText('Input wrong length');
        Result := ERROR_TOO_LONG;
        Exit;
      end;
      
    BARCODE_UPCE_CC:
      if Length(first_part) in [6, 7] then
      begin
        set_module(ASymbol, ASymbol^.rows, 1);
        set_module(ASymbol, ASymbol^.rows, 51);
        set_module(ASymbol, ASymbol^.rows + 1, 0);
        set_module(ASymbol, ASymbol^.rows + 1, 52);
        set_module(ASymbol, ASymbol^.rows + 2, 1);
        set_module(ASymbol, ASymbol^.rows + 2, 51);
        ASymbol^.row_height[ASymbol^.rows] := 2;
        ASymbol^.row_height[ASymbol^.rows + 1] := 2;
        ASymbol^.row_height[ASymbol^.rows + 2] := 2;
        Inc(ASymbol^.rows, 3);
        upce(ASymbol, first_part, dest);
      end
      else
      begin
        ASymbol^.SetErrorText('Wrong UPC-E input length');
        Result := ERROR_TOO_LONG;
        Exit;
      end;
    
    BARCODE_ISBNX:
      begin
        Result := isbn(ASymbol, first_part, dest);
        if (Result > 4) then
          Exit;
      end;
  end;
  
  case Length(second_part) of
    0: ;
    2: begin
         add_on(second_part, dest, 1);
         ASymbol^.SetText(ASymbol^.GetText + '+' + second_part);
       end;
    5: begin
         add_on(second_part, dest, 1);
         ASymbol^.SetText(ASymbol^.GetText + '+' + second_part);
       end;
    else
       ASymbol^.SetErrorText('Invalid length input');
       Result := ERROR_TOO_LONG;
       Exit;
  end;

  expand(ASymbol, dest);

  case ASymbol^.symbology of
    BARCODE_EANX_CC,
    BARCODE_UPCA_CC,
    BARCODE_UPCE_CC:
      begin
        { shift the symbol to the right one space to allow for separator bars }
        for i := (ASymbol^.width + 1) downto 1 do
        begin
          if module_is_set(ASymbol, ASymbol^.rows - 1, i - 1) then
            set_module(ASymbol, ASymbol^.rows - 1, i)
          else
            unset_module(ASymbol, ASymbol^.rows - 1, i);
        end;
        unset_module(ASymbol, ASymbol^.rows - 1, 0);
        Inc(ASymbol^.width, 2);
      end;
  end;

  if (Result = 0) and (ASymbol^.GetErrorText <> '') and (ASymbol^.GetErrorText[1] = 'w') then
    Result := 1;  { flag UPC-E warnings }
end;

end.
