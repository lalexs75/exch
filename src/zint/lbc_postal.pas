{  lbc_postal - Handles postal bar codes

  Based on Zint (done by Robin Stuart and the Zint team)
    http://github.com/zint/zint
  and Pascal adaption by TheUnknownOnes
    http://theunknownones.net
    
  Refactoring: W. Pamler
} 

unit lbc_postal;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, zint;

function post_plot(ASymbol: PZintSymbol; const ASource: String): Integer;
function planet_plot(ASymbol: PZintSymbol; const ASource: String): Integer;
function korea_post(ASymbol: PZintSymbol; const ASource: String): Integer;
function fim(ASymbol: PZintSymbol; const ASource: String): Integer;
function royal_plot(ASymbol: PZintSymbol; const ASource: String): Integer;
function kix_code(ASymbol: PZintSymbol; const ASource: String): Integer;
function daft_code(ASymbol: PZintSymbol; const ASource: String): Integer;
function flattermarken(ASymbol: PZintSymbol; const ASource: String): Integer;
function japan_post(ASymbol: PZintSymbol; const ASource: String): Integer;

implementation

uses 
  lbc_helper;

const 
  DAFTSET = 'DAFT';
  KRSET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  KASUTSET = '1234567890-abcdefgh';
  CHKASUTSET = '0123456789-abcdefgh';
  SHKASUTSET = '1234567890-ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  { PostNet number encoding table - In this table L is long as S is short }
  PNTable: array[0..9] of string = (
    'LLSSS', 'SSSLL', 'SSLSL', 'SSLLS', 'SLSSL', 
    'SLSLS', 'SLLSS', 'LSSSL', 'LSSLS', 'LSLSS'
  );
  
  PLTable: array[0..9] of string = (
    'SSLLL', 'LLLSS', 'LLSLS', 'LLSSL', 'LSLLS', 
    'LSLSL', 'LSSLL', 'SLLLS','SLLSL', 'SLSLL'
  );

  RoyalValues: array[0..35] of string = (
    '11', '12', '13', '14', '15', '10', '21', '22', '23', '24', 
    '25', '20', '31', '32', '33', '34', '35', '30', '41', '42', 
    '43', '44', '45', '40', '51', '52',	'53', '54', '55', '50', 
    '01', '02', '03', '04', '05', '00'
  );

  { 0 = Full, 1 = Ascender, 2 = Descender, 3 = Tracker }
  RoyalTable: array[0..35] of string = (
    '3300', '3210', '3201', '2310', '2301', 
    '2211', '3120', '3030', '3021', '2130', 
    '2121', '2031', '3102', '3012', '3003', 
    '2112', '2103', '2013', '1320', '1230',
    '1221', '0330', '0321', '0231', '1302', 
    '1212', '1203', '0312', '0303', '0213', 
    '1122', '1032', '1023', '0132', '0123', 
    '0033'
  );

  FlatTable: array[0..9] of string = (
    '0504', '18', '0117', '0216', '0315', 
    '0414', '0513', '0612', '0711', '0810'
  );

  KoreaTable: array[0..9] of string = (
    '1313150613', '0713131313', '0417131313', '1506131313', '0413171313', 
    '17171313', '1315061313', '0413131713', '17131713', '13171713'
  );

  JapanTable: array[0..18] of string = (
    '114', '132', '312', '123', '141', '321', '213', '231', '411', '144',
    '414', '324', '342', '234', '432', '243', '423', '441', '111'
  );

{ ------------------------------------------------------------------------------
                                  PostNet
                                  
  Handles the PostNet system used for Zip codes in the US 
-------------------------------------------------------------------------------}
function postnet(ASymbol: PZintSymbol; const ASource: String; 
  var ADest: String): Integer;
var
  i, sum, check_digit, src_len: Integer;
  error_number: Integer;
begin
  src_len := Length(ASource);
  
  if (src_len > 38) then
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
  
  sum := 0;

  // START character 
  ADest := 'L';

  for i := 1 to src_len do
  begin
    lookup(NEON, PNTable, ASource[i], ADest);
    Inc(sum, ctoi(ASource[i]));
  end;
  check_digit := (10 - sum mod 10) mod 10;
  ADest := ADest + PNTable[check_digit];

  // STOP character 
  ADest := ADest + 'L';

  Result := error_number; 
end;

{ Puts PostNet barcodes into the pattern matrix }
function post_plot(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  height_pattern: String = '';
  i, writer: Integer;
  error_number: Integer;
begin
  error_number := postnet(ASymbol, ASource, height_pattern);
  if (error_number <> 0) then
  begin
    Result := error_number; 
    exit;
  end;

  writer := 0;
  for i := 1 to Length(height_pattern) do
  begin
    if height_pattern[i] = 'L' then
      set_module(ASymbol, 0, writer);
    set_module(ASymbol, 1, writer);
    inc(writer, 3);
  end;

  ASymbol^.rows := 2;
  ASymbol^.row_height[0] := 6;
  ASymbol^.row_height[1] := 6;
  ASymbol^.width := writer - 1;
  
  ASymbol^.SetText(ASource);

  Result := error_number; 
end;


{ ------------------------------------------------------------------------------
                                USPS Planet
                                
  Handles the PLANET system used for item tracking in the US 
-------------------------------------------------------------------------------}
function planet(ASymbol: PZintSymbol; const ASource: String;
  var ADest: String): Integer;
var
  i, sum, check_digit, src_len: Integer;
  error_number: Integer;
begin
  src_len := Length(ASource);
  
  if src_len > 38 then
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
  
  // START character 
  ADest := 'L';

  sum := 0;
  for i := 1 to src_len do
  begin
    lookup(NEON, PLTable, ASource[i], ADest);
    inc(sum, ctoi(ASource[i]));
  end;

  check_digit := (10 - sum mod 10) mod 10;
  ADest := ADest + PLTable[check_digit];

  // STOP character 
  ADest := ADest + 'L';

  Result := error_number; 
end;

{ Puts PLANET barcodes into the pattern matrix }
function planet_plot(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  height_pattern: string = '';
  i, writer: Integer;
  error_number: Integer;
begin
  error_number := planet(ASymbol, ASource, height_pattern);
  if (error_number <> 0) then
  begin
    Result := error_number; 
    exit;
  end;

  writer := 0;
  for i := 1 to Length(height_pattern) do
  begin
    if height_pattern[i] = 'L' then
      set_module(ASymbol, 0, writer);
    set_module(ASymbol, 1, writer);
    inc(writer, 3);
  end;

  ASymbol^.rows := 2;
  ASymbol^.row_height[0] := 6;
  ASymbol^.row_height[1] := 6;
  ASymbol^.width := writer - 1;
  
  ASymbol^.SetText(ASource);
  
  Result := error_number; 
end;


{-------------------------------------------------------------------------------
                          Korean Postal Authority 
-------------------------------------------------------------------------------}
function CheckSum_Korea(ASource: String): String;
var
  i, sum, check: Integer;
begin
  sum := 0;
  for i := 1 to Length(ASource) do
    inc(sum, ctoi(ASource[i]));

  check := 10 - sum mod 10;
  if check = 10 then check := 0;
  
  Result := itoc(check);
end;
      
function korea_post(ASymbol: PZintSymbol; const ASource: String): Integer;
const
  MaxLength = 6;
var
  n: Integer;
  src: String;
begin
  if Length(ASource) < MaxLength then
  begin
    n := MaxLength - Length(ASource);
    src := StringOfChar('0', n) + ASource;
  end else
    src := ASource;

  ASymbol^.Option := OPTION_ADD_CHECKSUM or OPTION_DISPLAY_CHECKSUM;
  Result := basic_encoder(ASymbol, src,
    MaxLength, NEON, '', KoreaTable, '', @CheckSUM_Korea, true
  );
end;
        

{-------------------------------------------------------------------------------
                       FIM (facing identification mark)
                       
  Was developed by the United States Postal Service (USPS) to allow automatic 
  facing, or orientation, of the mail piece for cancellation. It also 
  identifies reply mail that uses a preprinted USPS POSTNET barcode symbol. 
  Mail that uses a FIM can be routed to a high-speed sorter. 
  
  The simplest barcode symbology ever! Supported by MS Word, so here it is! 
 
  Glyphs from http://en.wikipedia.org/wiki/Facing_Identification_Mark 
-------------------------------------------------------------------------------}
function fim(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  src_len: Integer;
  dest: String;
begin         
  src_len := Length(ASource);
  
  if (src_len > 1) then
  begin
    ASymbol^.SetErrorText('Input too long');
    Result := ERROR_TOO_LONG; 
    exit;
  end;

  case ASource[1] of
    'a', 'A': dest := '111515111';
    'b', 'B': dest := '13111311131';
    'c', 'C': dest := '11131313111';
    'd', 'D': dest := '1111131311111';
    else
      ASymbol^.SetErrorText('Invalid characters in data');
      Result := ERROR_INVALID_DATA; 
      exit;
  end;

  expand(ASymbol, dest);
  
  Result := 0; 
end;


{-------------------------------------------------------------------------------
                 UK Royal Mail 4-State Customer Code (RM4SCC)
                 
  Handles the 4 State barcodes used in the UK by Royal Mail 
-------------------------------------------------------------------------------}
function rm4scc(const ASource: String; var ADest: string): Char;
var
  i, j: Integer;
  top, bottom, row, column, check_digit: Integer;
  values: string;
begin
  top := 0;
  bottom := 0;

  // START character }
  ADest := '1';

  for i := 1 to Length(ASource) do
  begin
    lookup(KRSET, RoyalTable, ASource[i], ADest);
    j := Pos(ASource[i], KRSET);
    values := RoyalValues[j - 1];  // -1 because RoyalValues is a string
    Inc(top, ctoi(values[1]));
    Inc(bottom, ctoi(values[2]));
  end;

  // Calculate the check digit
  row := top mod 6 - 1;
  column := bottom mod 6 - 1;
  if (row = -1) then row := 5;
  if (column = -1) then column := 5;
  check_digit := 6 * row + column;
  ADest := ADest + RoyalTable[check_digit];

  // STOP character 
  ADest := ADest + '0';

  result := KRSET[check_digit + 1]; // +1 because KRSET is a string
end;

{ Puts RM4SCC into the data matrix }
function royal_plot(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  height_pattern: string = ''; 
  localStr: String;
  i, writer, error_number, src_len: Integer;
begin
  src_len := Length(ASource);
  
  if (src_len > 120) then
  begin
    ASymbol^.SetErrorText('Input too long');
    Result := ERROR_TOO_LONG; 
    exit;
  end;
  
  localStr := Uppercase(ASource);
  
  error_number := is_sane(KRSET, localStr);
  if (error_number = ERROR_INVALID_DATA) then
  begin
    ASymbol^.SetErrorText('Invalid characters in data');
    Result := error_number; 
    exit;
  end;

  rm4scc(localStr, height_pattern);

  writer := 0;
  for i := 1 to Length(height_pattern) do
  begin
    if (height_pattern[i] in ['1', '0']) then
      set_module(ASymbol, 0, writer);
    set_module(ASymbol, 1, writer);
    if (height_pattern[i] in ['2', '0']) then
      set_module(ASymbol, 2, writer);
    Inc(writer, 2);
  end;

  ASymbol^.rows := 3;
  ASymbol^.row_height[0] := 3;
  ASymbol^.row_height[1] := 2;
  ASymbol^.row_height[2] := 3;
  ASymbol^.width := writer - 1;

  Result := error_number; 
end;


{-------------------------------------------------------------------------------
                          KIX barcode (Klant index)

  Used for mail sorting by the postal service of the Netherlands, 
  Koninklijke TNT Post (Royal TNT Post)
  
  The same as RM4SCC but without check digit 
  
  Specification at 
  http://www.tntpost.nl/zakelijk/klantenservice/downloads/kIX_code/download.aspx 
  
  https://support.honeywellaidc.com/s/article/What-is-KIX-code-and-is-it-supported-on-Honeywell-barcode-readers

  "The structure of the information in the KIX will be (from left to right):
    special prefix (optional)          two letters                fixed length
    postcode                           4 digits, 2 alpha char's.  fixed length
    house number,  P.O.Box number      maximal 5 digits           variable length
    separator (optional)               alpha char: "X"            fixed length
    house number extension (optional)  maximal 6 characters       variable length"
-------------------------------------------------------------------------------}
function kix_code(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  height_pattern: string = '';
  localstr: string;
  writer, i, error_number, src_len: Integer;
begin
  src_len := Length(ASource);
  
  if (src_len > 18) then
  begin
    ASymbol^.SetErrorText('Input too long (max 18 characters).');
    Result := ERROR_TOO_LONG; 
    exit;
  end;
  
  localStr := Uppercase(ASource);
  
  error_number := is_sane(KRSET, localStr);
  if (error_number = ERROR_INVALID_DATA) then
  begin
    ASymbol^.SetErrorText('Invalid characters in data');
    Result := error_number; 
    exit;
  end;

  { Encode data }
  for i := 1 to 18 do
    lookup(KRSET, RoyalTable, localstr[i], height_pattern);

  writer := 0;
  for i := 1 to Length(height_pattern) do
  begin
    if (height_pattern[i] in ['1', '0']) then
      set_module(ASymbol, 0, writer);
    set_module(ASymbol, 1, writer);
    if (height_pattern[i] in ['2', '0']) then
      set_module(ASymbol, 2, writer);
    Inc(writer, 2);
  end;

  ASymbol^.rows := 3;
  ASymbol^.row_height[0] := 3;
  ASymbol^.row_height[1] := 2;
  ASymbol^.row_height[2] := 3;
  ASymbol^.width := writer - 1;
  
  ASymbol^.SetText(localStr);

  Result := error_number; 
end;

{-------------------------------------------------------------------------------
                                DAFT symbol
                          
  Handles DAFT Code symbols 
  Presumably 'daft' doesn't mean the same thing in Germany as it does in the UK! 
-------------------------------------------------------------------------------}
function daft_code(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  localStr, height_pattern: String;
  writer, i, error_number, src_len: Integer;
begin
  src_len := Length(ASource);
  
  if (src_len > 50) then
  begin
    ASymbol^.SetErrorText('Input too long (max 50 characters)');
    Result := ERROR_TOO_LONG; 
    exit;
  end;
  
  localStr := Uppercase(ASource);
  
  error_number := is_sane(DAFTSET, localStr);
  if (error_number = ERROR_INVALID_DATA) then
  begin
    ASymbol^.SetErrorText('Invalid characters in data');
    Result := error_number; 
    exit;
  end;

  height_pattern := '';
  for i := 1 to src_len do
    case localStr[i] of
      'D': height_pattern := height_pattern + '2';
      'A': height_pattern := height_pattern + '1';
      'F': height_pattern := height_pattern + '0';
      'T': height_pattern := height_pattern + '3';
      else ;
    end;

  writer := 0;
  for i := 1 to Length(height_pattern) do
  begin
    if (height_pattern[i] in ['1', '0']) then
      set_module(ASymbol, 0, writer);
    set_module(ASymbol, 1, writer);
    if (height_pattern[i] in ['2', '0']) then
      set_module(ASymbol, 2, writer);
    Inc(writer, 2);
  end;

  ASymbol^.rows := 3;
  ASymbol^.row_height[0] := 3;
  ASymbol^.row_height[1] := 2;
  ASymbol^.row_height[2] := 3;
  ASymbol^.width := writer - 1;

  Result := error_number; 
end;


{-------------------------------------------------------------------------------
                                    Flattermarken
                                    
  Flattermarken (a German plural; the singular is "flattermarke") are the marks 
  used on the edge of printed material such as sections of books to facilitate 
  their being arranged in the proper order. The symbology allows for the coding 
  of any sequence of numbers through the position of bars. The bars themselves 
  are of the same size and shape, but their position varies.   
-------------------------------------------------------------------------------}
function flattermarken(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  i, error_number, src_len: Integer;
  dest: string;
begin                     
  src_len := Length(ASource);
  
  if (src_len > 90) then
  begin
    ASymbol^.SetErrorText('Input too long (max 90 characters).');
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
  
  dest := '';
  for i := 1 to src_len do
    lookup(NEON, FlatTable, ASource[i], dest);

  expand(ASymbol, dest);
  
  Result := error_number; 
end;

                 
{-------------------------------------------------------------------------------
                      Japanese Postal Code (Kasutama Barcode) 
-------------------------------------------------------------------------------}
function japan_post(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  writer, inter_posn, i, j, sum, check, error_number, src_len: Integer;
  check_char: Char;
  pattern: String;
  inter: String;
  localStr: string;
begin
  src_len := Length(ASource);
  localStr := Uppercase(ASource);

  error_number := is_sane(SHKASUTSET, localStr);
  if (error_number = ERROR_INVALID_DATA) then
  begin
    ASymbol^.SetErrorText('Invalid characters in data');
    Result := error_number; 
    exit;
  end;

  // Pad character CC4
  inter := StringOfChar('d', 20);  

  i := 1;
  inter_posn := 1;
  repeat
    if (localStr[i] in ['0'..'9', '-']) then
    begin
      inter[inter_posn] := localStr[i];
      Inc(inter_posn);
    end else
    begin
      if (localStr[i] in ['A'..'J']) then
      begin
        inter[inter_posn] := 'a';
        inter[inter_posn + 1] := Char(ord(localStr[i]) - ord('A') + Ord('0'));
        Inc(inter_posn, 2);
      end;
      if (localStr[i] in ['K'..'T']) then
      begin
        inter[inter_posn] := 'b';
        inter[inter_posn + 1] := Char(ord(localStr[i]) - Ord('K') + Ord('0'));
        Inc(inter_posn, 2);
      end;
      if (localStr[i] in ['U'..'Z']) then
      begin
        inter[inter_posn] := 'c';
        inter[inter_posn + 1] := Char(ord(localStr[i]) - Ord('U') + Ord('0'));
        Inc(inter_posn, 2);
      end;
    end;
    Inc(i);
  until  (i > src_len) or (inter_posn > 20);

  // START character
  pattern := '13';   

  sum := 0;
  for i := 1 to 20 do
  begin
    j := pos(inter[i], KASUTSET) - 1;  // -1 to become 0-based again because inter is a string
    pattern := pattern + JapanTable[j];
    j := pos(inter[i], CHKASUTSET) - 1;
    inc(sum, j);
  end;

  // Calculate check digit 
  check := 19 - sum mod 19;
  if (check = 19) then check := 0;
  if (check <= 9) then
    check_char := Char(check + Ord('0'))
  else
  if (check = 10) then
    check_char := '-'
  else
    check_char := Char((check - 11) + Ord('a'));

  j := pos(check_char, KASUTSET) - 1;
  pattern := pattern + JapanTable[j];

  // STOP character
  pattern := pattern + '31'; 

  // Resolve pattern to 4-state symbols
  writer := 0;
  for i := 1 to Length(pattern) do
  begin
    if (pattern[i] in ['2', '1']) then
      set_module(ASymbol, 0, writer);
    set_module(ASymbol, 1, writer);
    if (pattern[i] in ['3', '1']) then
      set_module(ASymbol, 2, writer);
    Inc(writer, 2);
  end;

  ASymbol^.rows := 3;
  ASymbol^.row_height[0] := 3;
  ASymbol^.row_height[1] := 2;
  ASymbol^.row_height[2] := 3;
  ASymbol^.width := writer - 1;

  ASymbol^.SetText(localStr);
  
  Result := error_number; 
end;
             

end. 
