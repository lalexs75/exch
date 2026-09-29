unit lbc_helper;

{$mode objfpc}{$H+}

interface

uses 
  sysutils, types, zint;

type
  TCheckSumFunc = function(ASource: String): String;

const 
  RHODIUM = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:';
  SILVER  = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%abcd';  // 47 chars
  NEON    = '0123456789';
  SODIUM  = '0123456789-';
  
  OPTION_ADD_CHECKSUM = 1;
  OPTION_DISPLAY_CHECKSUM = 2;
  OPTION_GROUPED_CHARS = 4;
  
  NO_PADDING = #0;
  
function IsTrue(aBoolean: Boolean): Boolean;
function IsTrue(aInteger: Integer): Boolean;
function iif(const aBoolean: integer; const aCh1,aCh2: pchar): pchar; overload;
function iif(const aBoolean: integer; const aCh1,aCh2: char): char; overload;
function iif(const aBoolean: Boolean; const aStr1,aStr2: String): String; overload;
function iif(const aBoolean: Boolean; const aCh1,ach2: char): char; overload;
function iif(const aBoolean: Boolean; const aV1,aV2: Word): word; overload;
procedure concat(const aText: pchar; const aChar: char);
procedure concat(const aText: pchar; const aText2: pchar);
procedure concat(var aText: array of char; const aText2: pchar);
procedure strcpy(const aText: pchar; const aText2: pchar);
procedure strcpy(const aText: pchar; const aText2: TByteDynArray);
procedure strcpy(var aText: array of char; const aText2: pchar); 
procedure strcpy(var aText: array of byte; const aText2: pchar);
procedure strcpy(var AText: array of byte; const aText2: TByteDynArray);
function posn(const aText: pchar; const aChar: Char): integer;
function strlen(const aText: array of char): integer;
function is_sane(test_string: PChar; source: PByte; length: Integer): Integer; overload;
function is_sane(test_string: PChar; const source: TByteDynArray; length: Integer): Integer; overload;
function is_sane(const AllowedChars, ASource: String): Integer; overload;
function utf8toutf16(symbol: PointerTo_zint_symbol; source: PByte; vals: PInteger; length: PInteger): Integer;
procedure set_module(symbol: PointerTo_zint_symbol; y_coord: Integer; x_coord: Integer);
procedure unset_module(symbol: PointerTo_zint_symbol; y_coord: Integer; x_coord: Integer);
function module_is_set(symbol: PointerTo_zint_symbol; y_coord: Integer; x_coord: Integer): Boolean;
function PostInc(var v: integer): integer;
function PostDec(var v: integer): integer;
function is_extendable(symbology: Integer): Boolean;
function is_stackable(symbology: Integer): Boolean;
function NotBoolean(const aValue: integer): Boolean;
function NotBoolean(const aValue: Boolean): Boolean;
function latin1_process(symbol: PointerTo_zint_symbol; source: PBYTE; preprocessed: PBYTE; length: PInteger): Integer;
function ctoi(c: char): integer;
function ctoi(c: BYTE): integer;
function BooleanNot(const aValue: integer): Boolean;
procedure memset(const p: Pointer; const aValue: BYTE; const aSize: integer);
function istwodigits(source: PByte; position: Integer): Boolean;
procedure to_upper(a: PByte);
procedure to_upper(const a: TByteDynArray);
procedure Lookup(const Set_String: PChar; const ATable: array of String; const AData: Char; var ADest: TCharDynArray);
procedure Lookup(const Set_String: PChar; const ATable: array of String; const AData: Byte; var ADest: TCharDynArray);

procedure Lookup(const Set_String: String; const ATable: array of String; const AData: Char; var ADest: String);
                                                            {
procedure lookup(const set_string : TArrayOfChar; const table : array of String; const data : Char; var dest : TArrayOfChar); overload;
procedure lookup(const set_string : TArrayOfChar; const table : array of String; const data : Byte; var dest : TArrayOfChar); overload;
procedure lookup(const ASet_string : String; const ATable : array of String; const AData : Byte; var ADest : TArrayOfChar); overload;
procedure lookup(const ASet_string : String; const ATable : array of String; const AData : Char; var ADest : TArrayOfChar); overload;
                                                             }
function itoc(AValue: Integer): Char;

procedure expand(ASymbol: PointerTo_zint_symbol; AData: TCharDynArray);
procedure expand(ASymbol: PointerTo_zint_symbol; const AData: string);
         
function CharArrayToStr(AData: TCharDynArray): String;
function StrToCharArray(AText: String): TCharDynArray;

function basic_encoder(ASymbol: PZIntSymbol; const ASource: String;
  MaxLen: Integer; const AllowedChars, StartCode: String; 
  const CharCodes: array of string; const StopCode: String;
  CheckSumFunc: TCheckSumFunc; SourceInverted: Boolean): Integer;

function upc_checksum(ASource: String): String;

implementation  

uses
  Math;

function istwodigits(source: PBYTE; position: Integer): Boolean;
begin
  if (Char(source[position]) in ['0'..'9']) and (Char(source[position+1]) in ['0'..'9']) then begin
    Result:=true;
  end else begin
    Result:=false;
  end;
end;

function PostInc(var v: integer): integer;
begin
  Result:=v;
  inc(v);
end;

function PostDec(var v: integer): integer;
begin
  Result:=v;
  Dec(v);
end;

function IsTrue(aBoolean: Boolean): Boolean;
begin
  Result:=aBoolean;
end;

function IsTrue(aInteger: Integer): Boolean;
begin
  if aInteger=0 then Result:=false else Result:=true;
end;

function iif(const aBoolean: integer; const aCh1, aCh2: pchar): pchar;
begin
  if aBoolean=0 then begin
    Result:=aCh2;
  end else begin
    Result:=aCh1;
  end;
end;

function iif(const aBoolean: integer; const aCh1,aCh2: char): char;
begin
  if aBoolean=0 then begin
    Result:=aCh2;
  end else begin
    Result:=aCh1;
  end;
end;

function iif(const aBoolean: Boolean; const aStr1,aStr2: String): String;
begin
  if aBoolean then
    Result := aStr1
  else
    Result := aStr2;
end;

function iif(const aBoolean: Boolean; const aCh1,aCh2: char): char;
begin
  if aBoolean then
    Result := aCh1
  else
    Result := aCh2;
end;

function iif(const aBoolean: Boolean; const aV1,aV2: Word): word;
begin
  if aBoolean then Result:=aV1 else Result:=aV2;
end;

procedure concat(const aText: pchar; const aChar: char);
var
  i: integer;
begin
  i:=sysutils.strlen(aText);
  aText[i]:=aChar;
  inc(i);
  aText[i]:=#0;
end;

procedure concat(const aText: pchar; const aText2: pchar);
var
  i: integer;
begin
  i:=sysutils.strlen(aText);
  move(aText2^,aText[i],sysutils.strlen(aText2)+1);
end;

procedure concat(var aText: array of char; const aText2: pchar);
begin
  concat(pchar(@aText[0]), aText2);
end;

procedure strcpy(const aText: pchar; const aText2: pchar);
begin
  move(aText2^,aText^,sysutils.strlen(aText2)+1);
end;

procedure strcpy(const aText: pchar; const aText2: TByteDynArray);
var
  len: Integer;
begin
  len := sysutils.strlen(PChar(@aText2[0]));
  move(aText2[0], aText^, len+1);
end;

procedure strcpy(var aText: array of char; const aText2: pchar);
begin
  move(aText2^,aText[0],sysutils.strlen(aText2)+1);
end;

procedure strcpy(var AText: array of byte; const aText2: PChar);
begin
  Move(aText2^, aText[0], sysUtils.strLen(aText2)+1);
end;

procedure strcpy(var AText: array of byte; const aText2: TByteDynArray);
var
  len: Integer;
begin
  len := sysUtils.strLen(PChar(@aText2[0]));
  Move(aText2[0], aText[0], len+1);
end;

function posn(const aText: pchar; const aChar: Char): integer;
var
  p: Pchar;
  c: integer;
begin
  p:=aText;
  c:=0;
  while p^<>#0 do begin
    if p^<>aChar then begin
      inc(c);
      inc(p);
    end else begin
      Exit(c);
    end;
  end;
  Result:=0;
end;

function strlen(const aText: array of char): integer;
begin
  Result:=sysutils.strlen(pchar(@aText[0]));
end;

{ Checks whether each character of ASource is contained in string AllowedChars.
  Returns 0 if successful, otherwise error code ERROR_INVALID_DATA. }
function is_sane(const AllowedChars, ASource: String): Integer;
var
  i: Integer;
begin
  for i := 1 to Length(ASource) do
    if pos(ASource[i], AllowedChars) = 0 then
    begin
      Result := ERROR_INVALID_DATA;
      exit;
    end;
  Result := 0;
end;

function is_sane(test_string: PChar; source: PByte; length: Integer): Integer;
var
  latch: Boolean;
  j: Cardinal;
  i: Integer;
  lt: Cardinal;
begin
  {INITCODE} lt := sysutils.strlen (test_string);
  i := 0;
  while i < length do
  begin
    latch := FALSE;
    j := 0;
    while j < lt do
    begin
      if Boolean(source[i] = BYTE(test_string[j])) then
      begin
        latch := TRUE;
        break;
      end;
      Inc (j);
    end;
    if Boolean(NotBoolean (latch)) then
    begin
      exit (ERROR_INVALID_DATA);
    end;
    Inc (i);
  end;
  exit (0);
end;

function is_sane(test_string: PChar; const source: TByteDynArray; Length: Integer): Integer;
begin
  Result := is_sane(test_string, PByte(@source[0]), Length);
end;

function utf8toutf16(symbol: PointerTo_zint_symbol; source: PBYTE; vals: PInteger; length: PInteger): Integer;
var
  error_number: Integer;
  jpos: Integer;
  bpos: Integer;
  next: Integer;
begin
  bpos := 0;
  jpos := 0;
  error_number := 0;
  next := 0;
  repeat
    if source[bpos] <= $7F then
    begin
      vals[jpos] := source[bpos];
      next := bpos + 1;
      Inc (jpos);
    end else begin
      if (source[bpos] >= $80) and (source[bpos] <= $BF) then
      begin
        strcpy (symbol^.errtxt, 'Corrupt Unicode data');
        exit (ERROR_INVALID_DATA);
      end;
      if (source[bpos] >= $C0) and (source[bpos] <= $C1) then
      begin
        strcpy (symbol^.errtxt, 'Overlong encoding not supported');
        exit (ERROR_INVALID_DATA);
      end;
      if (source[bpos] >= $C2) and (source[bpos] <= $DF) then
      begin
        vals[jpos] := ((source[bpos] and $1F) shl 6) + (source[bpos + 1] and $3F);
        next := bpos + 2;
        Inc (jpos);
      end else begin
        if (source[bpos] >= $E0) and (source[bpos] <= $EF) then
        begin
          vals[jpos] := ((source[bpos] and $0F) shl 12) + ((source[bpos + 1] and $3F) shl 6) + (source[bpos + 2] and $3F);
          next := bpos + 3;
          Inc (jpos);
        end else begin
          if source[bpos] >= $F0 then
          begin
            strcpy (symbol^.errtxt, 'Unicode sequences of more than 3 bytes not supported');
            exit (ERROR_INVALID_DATA);
          end;
        end;
      end;
    end;
    bpos := next;
  until not (bpos < length^);
  length^ := jpos;
  exit (error_number);
end;
  
function module_is_set(symbol: PointerTo_zint_symbol; y_coord, x_coord: Integer): Boolean;
begin
  Result := symbol^.encoded_data[y_coord, x_coord];
end;

procedure set_module(symbol: PointerTo_zint_symbol; y_coord, x_coord: Integer);
begin
  symbol^.encoded_data[y_coord, x_coord] := true;
end;

procedure unset_module(symbol: PointerTo_zint_symbol; y_coord, x_coord: Integer);
begin
  symbol^.encoded_data[y_coord, x_coord] := false;
end;

procedure to_upper(a: PByte);
begin
  while a^<>0 do begin
    if char(a^) in ['a'..'z'] then begin
      a^:=Byte(upCase(char(a^)));
    end;
    inc(a);
  end;
end;

procedure to_upper(const a: TByteDynArray);
begin
  to_upper(PByte(@a[0]));
end;

function ctoi(c: char): integer;
begin
  if c in ['0'..'9'] then begin
    Result:=BYTE(c)-48;
  end else begin
    Result:=-1;
  end;
end;

function ctoi(c: BYTE): integer;
begin
  Result:=ctoi(char(c));
end;

function BooleanNot(const aValue: integer): Boolean;
begin
  Result:=NotBoolean(aValue);
end;

procedure memset(const p: Pointer; const aValue: BYTE; const aSize: integer);
begin
  FillByte(PBYTE(p)^,aSize,aValue);
end;

function is_extendable(symbology: Integer): Boolean;
begin
  Result := true;
  if symbology = BARCODE_EANX then exit;
  if symbology = BARCODE_UPCA then exit;
  if symbology = BARCODE_UPCE then exit;
  if symbology = BARCODE_ISBNX then exit;
  if symbology = BARCODE_UPCA_CC then exit;
  if symbology = BARCODE_UPCE_CC then exit;
  if symbology = BARCODE_EANX_CC then exit;
  Result := false;
end;

function is_stackable(symbology: Integer): Boolean;
begin
  Result := true;
  if symbology < BARCODE_PDF417 then exit;
  if symbology = BARCODE_CODE128B then exit;
  if symbology = BARCODE_ISBNX then exit;
  if symbology = BARCODE_EAN14 then exit;
  if symbology = BARCODE_NVE18 then exit;
  if symbology = BARCODE_KOREAPOST then exit;
  if symbology = BARCODE_PLESSEY then exit;
  if symbology = BARCODE_TELEPEN_NUM then exit;
  if symbology = BARCODE_ITF14 then exit;
  if symbology = BARCODE_CODE32 then exit;
  Result := false;
end;

function NotBoolean(const aValue: integer): Boolean;
begin
  Result := (aValue = 0);
end;

function NotBoolean(const aValue: Boolean): Boolean;
begin
  Result := not aValue;
end;

function latin1_process(symbol: PointerTo_zint_symbol; source: PBYTE; preprocessed: PBYTE; length: PInteger): Integer;
var
  next: Integer;
  i: Integer;
  j: Integer;
begin
  j := 0;
  i := 0;
  repeat
    next := -1;
    if Boolean(source[i] < 128) then
    begin
      preprocessed[j] := source[i];
      Inc (j);
      next := i + 1;
    end else begin
      if Boolean(source[i] = $C2) then
      begin
        preprocessed[j] := source[i + 1];
        Inc (j);
        next := i + 2;
      end;
      if Boolean(source[i] = $C3) then
      begin
        preprocessed[j] := source[i + 1] + 64;
        Inc (j);
        next := i + 2;
      end;
    end;
    if Boolean(next = -1) then
    begin
      strcpy (symbol^.errtxt, 'error: Invalid character in input string (only Latin-1 characters supported)');
      exit (ERROR_INVALID_DATA);
    end;
    i := next;
  until not (i < length^);
  preprocessed[j] := 0;
  length^ := j;
  exit (0);
end;

{ Replaces huge switch statements for looking up in tables }
procedure Lookup(const Set_String: PChar; const ATable: array of String;
  const AData: Char; var ADest: TCharDynArray);
var
  i, n: integer;
begin
  n := System.Strlen(Set_String);
  for i := 0 to n-1 do
    if AData = Set_String[i] then
      concat(ADest, PChar(ATable[i]));
end;

procedure Lookup(const Set_String: PChar; const ATable: array of String; 
  const AData: Byte; var ADest: TCharDynArray);
begin
  LookUp(set_string, ATable, char(AData), ADest);
end;

{ Set_string is a string with the allowed characters.
  ATable is the bar-space pattern for each of these allowed characters.
  AData is the character to be encoded.
  ADest is the output string.
  The routines searches the character in the list of allowed characters and
  appends its bar-space pattern to ADest. }
procedure Lookup(const Set_String: String; const ATable: array of String; 
  const AData: Char; var ADest: String);
var
  i: Integer;
begin
  i := pos(AData, Set_String);
  if i > 0 then
    ADest := ADest + ATable[i-1];
end;


{ Converts an integer value to its hexadecimal character }
function itoc(AValue: Integer): Char;
begin
 if (AValue >= 0) and (AValue <= 9) then
   Result := Char(Ord('0') + AValue)
 else
   Result := Char(Ord('A') + (AValue - 10));
end;


{ Expands from a width pattern to a bit pattern */ }
procedure expand(ASymbol: PointerTo_zint_symbol; const AData: String);
var
  reader, writer, i: Integer;
  latch: boolean;
begin
  writer := 0;
  latch := true;
  
  for reader := 1 to Length(AData) do
  begin
    for i := 1 to ctoi(AData[reader]) do
    begin
      if latch then
        set_module(ASymbol, ASymbol^.rows, writer);
      inc(writer);
    end;
    latch := not latch;
  end;

  if ASymbol^.symbology <> BARCODE_PHARMA then
  begin
    if writer > ASymbol^.width then
      ASymbol^.width := writer;
  end else
  begin
    { Pharmacode One ends with a space - adjust for this }
    if (writer > ASymbol^.width + 2) then
      ASymbol^.width := writer - 2;
  end;

  ASymbol^.rows := ASymbol^.rows + 1;
end;
    
procedure expand(ASymbol: PointerTo_zint_symbol; AData: TCharDynArray);
var
  reader, n : Cardinal;
  writer, i : Integer;
  latch : Char;
begin
  n := strlen(AData);
  writer := 0;
  latch := '1';

  for reader := 0 to n - 1 do
  begin
    for i := 0 to ctoi(AData[reader]) - 1 do
    begin
      if (latch = '1') then 
        set_module(ASymbol, ASymbol^.rows, writer);
      Inc(writer);
    end;

    if latch = '1' then latch := '0' else latch := '1';
  end;

  if(ASymbol^.symbology <> BARCODE_PHARMA) then
  begin
    if(writer > ASymbol^.width) then
      ASymbol^.width := writer;
  end else
  begin
    { Pharmacode One ends with a space - adjust for this }
    if(writer > ASymbol^.width + 2) then
      ASymbol^.width := writer - 2;
  end;

  ASymbol^.rows := ASymbol^.rows + 1;
end;

function CharArrayToStr(AData: TCharDynArray): String;
var
  len: Integer;
begin
  Result := '';
  len := Length(AData);
  SetLength(Result, len);
  if len > 0 then
    Move(AData[0], Result[1], len*SizeOf(Char));
end;

function StrToCharArray(AText: String): TCharDynArray;
var
  len: Integer;
begin
  Result := nil;
  len := Length(AText);
  SetLength(Result, len + 1);
  if len > 0 then
    Move(AText[1], Result[0], len*SizeOf(Char));
  Result[len] := #0;
end;


{ Basic encoding routine for barcodes - most of them work all in the same way
  only with different parameters:
    MaxLen - maximum length of input string
    AllowedChars - a string containing the allowed characters for this barcode type.
      If empty, all characters are allowed (any check musts be done by the caller).
    StartCode - starting code pattern
    CharCodes - code pattern for each allowed character
    StopCode - ending code pattern
    CheckSumFunc - function to calculate a checksum which is appended to the
      input string
    SourceInverted - input string is encoded from last to first char
}
function basic_encoder(ASymbol: PZIntSymbol; const ASource: String;
  MaxLen: Integer; const AllowedChars, StartCode: String; 
  const CharCodes: array of string; const StopCode: String;
  CheckSumFunc: TCheckSumFunc; SourceInverted: Boolean): Integer;
var
  i: Integer;
  src, dest: String; 
  check: String;
begin
  Result := 0;
  
  if Length(ASource) > MaxLen then
  begin
    ASymbol^.SetErrorText('Input too long (max ' + IntToStr(MaxLen) + ' digits).');
    Result := ERROR_TOO_LONG;
    exit;
  end;
  
  src := ASource; 

  // START character
  dest := StartCode;

  // Check whether all characters of the input string are allowed.
  if AllowedChars <> '' then
  begin
    Result := is_sane(AllowedChars, ASource);
    if Result = ERROR_INVALID_DATA then
    begin
      ASymbol^.SetErrorText('Invalid characters in data.');
      exit;
    end;
      
    // Add encoded input string characters to destination string
    if SourceInverted then
      for i := Length(src) downto 1 do
        lookup(AllowedChars, CharCodes, src[i], dest)
    else
      for i := 1 to Length(src) do
        lookup(AllowedChars, CharCodes, src[i], dest);
  
    // Add check digit(s) if a calculation function is provided
    if (ASymbol^.Option and OPTION_ADD_CHECKSUM = OPTION_ADD_CHECKSUM) and
      (CheckSumFunc <> nil) then
    begin
      check := CheckSumFunc(src);
      src := src + check;
      for i := 1 to Length(check) do
        lookup(AllowedChars, CharCodes, check[i], dest);
    end;
  end 
  else
  // All characters are allowed -> lookup not needed
  begin
    // Add encoded input string characters to destination string
    if SourceInverted then
      for i := Length(src) downto 1 do
        dest := dest + CharCodes[ord(src[i])]
    else
      for i := 1 to Length(src) do
        dest := dest + CharCodes[ord(src[i])];
    
    // Add check digit(s) if a calculation function is provided
    if (ASymbol^.Option and OPTION_ADD_CHECKSUM = OPTION_ADD_CHECKSUM) and
       (ChecksumFunc <> nil) then
    begin
      check := CheckSumFunc(src);
      src := src + check;
      for i := 1 to Length(check) do
        dest := dest + CharCodes[ord(check[i])];
    end;
  end;
  
  // STOP character
  dest := dest + StopCode;
  
  // Expand the RLE-encoded bar/space widths to modules 
  // Example: '121' --> 1001 where 1 = black, 0 = white
  // This information is stored in the ZintSymbol.
  expand(ASymbol, dest);
  
  // Store human-readable text
  if ASymbol^.Option and OPTION_DISPLAY_CHECKSUM = OPTION_DISPLAY_CHECKSUM then
    ASymbol^.SetText(src)
  else
    ASymbol^.SetText(ASource);
end;

{ Calculate the correct check digit for a UPC barcode.
  Needed by 2-of-5 and EAN bar codes. }
function upc_checksum(ASource: String): String;
var
  i, n, sum, check_digit: Integer;
begin
  sum := 0;
  for i := 1 to Length(ASource) do
  begin
    n := StrToInt(ASource[i]);
    inc(sum, n);
    if odd(i) then
      inc(sum, 2 * n);
  end;

  check_digit := 10 - sum mod 10;
  if (check_digit = 10) then check_digit := 0;

  Result := IntToStr(check_digit);
end;


end.
