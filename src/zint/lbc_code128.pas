{  lbc_code128.pas - Handles Code_128, ean_128, ean_14, nve_18 

  Based on Zint (done by Robin Stuart and the Zint team)
    http://github.com/zint/zint
  and Pascal adaption by TheUnknownOnes
    http://theunknownones.net
} 

unit lbc_code128;

{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  Types, 
  zint;

function code_128(ASymbol: PointerTo_zint_symbol; ASource: PByte; ALength: Integer): Integer;
function ean_128(ASymbol: PointerTo_zint_symbol; ASource: PByte; ALength: Integer): Integer;
function nve_18(ASymbol: PointerTo_zint_symbol; ASource: PByte; ALength: Integer): Integer;
function ean_14(Asymbol: PointerTo_zint_symbol; ASource: PByte; ALength: Integer): Integer;

implementation

uses
  SysUtils, lbc_common, lbc_gs1, lbc_helper;

const
  {%H-}DPDSET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ*';

type
  TGlobalList = array[0..1] of array[0..169] of Integer;

const
  {Code 128 tables checked against ISO/IEC 15417:2007 }

  // Code 128 character encodation - Table 1 
  C128Table : array[0..106] of String = (
    '212222', '222122', '222221', '121223', '121322', 
    '131222', '122213', '122312', '132212', '221213', 
    '221312', '231212', '112232', '122132', '122231', 
    '113222', '123122', '123221', '223211', '221132', 
    '221231', '213212', '223112', '312131', '311222',
    '321122', '321221', '312212', '322112', '322211',
    '212123', '212321', '232121', '111323', '131123', 
    '131321', '112313', '132113', '132311', '211313', 
    '231113', '231311', '112133', '112331', '132131', 
    '113123', '113321', '133121', '313121', '211331', 
    '231131', '213113', '213311', '213131', '311123', 
    '311321', '331121', '312113', '312311', '332111', 
    '314111', '221411', '431111', '111224', '111422', 
    '121124', '121421', '141122', '141221', '112214',
    '112412', '122114', '122411', '142112', '142211', 
    '241211', '221114', '413111', '241112', '134111', 
    '111242', '121142', '121241', '114212', '124112', 
    '124211', '411212', '421112', '421211', '212141', 
    '214121', '412121', '111143', '111341', '131141', 
    '114113', '114311', '411113', '411311', '113141',
    '114131', '311141', '411131', '211412', '211214', 
    '211232', '2331112'
  );
  
  {%H-}_TRUE = 1;
  _FALSE = 0;
  SHIFTA = 90;
  LATCHA = 91;
  SHIFTB = 92;
  LATCHB = 93;
  {%H-}SHIFTC = 94;
  LATCHC = 95;
  AORB = 96;
  ABORC = 97;
  {%H-}CANDB = 98;
  {%H-}CANDBB = 99;

  
function parunmodd(llyth: Byte): Integer;
var
  modd: Integer;
begin
  modd := SHIFTB;

  if (llyth <= 31) then
    modd := SHIFTA
  else if ((llyth >= 48) and (llyth <= 57)) then
    modd := ABORC
  else if (llyth <= 95) then
    modd := AORB
  else if (llyth <= 127) then
    modd := SHIFTB
  else if (llyth <= 159) then
    modd := SHIFTA
  else if (llyth <= 223) then
    modd := AORB;

  Result := modd; 
end;

function parunmodd(llyth: Char): Integer;
begin
  Result := parunmodd(Ord(llyth));
end;


{ Bring together same type blocks }
procedure grwp(var indexlist: Integer; var list: TGlobalList);
var
  i, j: Integer;
begin
  if (indexlist <= 1) then
    exit;

  // Because i is modified inside the loop, we have to use "while"
  i := 1;
  while i < indexlist do
  begin
    if (list[1, i - 1] = list[1, i]) then
    begin
      { bring together }
      list[0, i - 1] := list[0, i - 1] + list[0, i];

      { decrease the list }
      for j := i + 1 to indexlist - 1 do
      begin
        list[0, j - 1] := list[0, j];
        list[1, j - 1] := list[1, j];
      end;
      dec(indexlist);
      dec(i);
    end;
    inc(i);
  end;
end;

 { Implements rules from ISO 15417 Annex E }
procedure dxsmooth(var indexlist: Integer; var list: TGlobalList);
var
  i, current, _length, last, next: Integer;
begin
  for i := 0  to indexlist- 1 do
  begin
    current := list[1, i];
    _length := list[0, i];

    if (i <> 0) then
      last := list[1, i - 1]
    else
      last := _FALSE;

    if (i <> indexlist - 1) then
      next := list[1, i + 1]
    else
      next := _FALSE;

    if(i = 0) then
    begin { first block }
      if ((indexlist = 1) and (_length = 2) and (current = ABORC)) then
        { Rule 1a }
        list[1, i] := LATCHC;

      if (current = ABORC) then
      begin
        if (_length >= 4) then
          { Rule 1b }
          list[1, i] := LATCHC
        else
        begin
          list[1, i] := AORB; 
          current := AORB;
        end;
      end;

      if (current = SHIFTA) then
        { Rule 1c }
        list[1, i] := LATCHA;
      
      if (current = AORB) and (next = SHIFTA) then
      begin
        { Rule 1c }
        list[1, i] := LATCHA; 
        current := LATCHA;
      end;
      
      if (current = AORB) then
        { Rule 1d }
        list[1, i] := LATCHB;
    end
    else
    begin
      if (current = ABORC) and (_length >= 4) then
      begin
        { Rule 3 }
        list[1, i] := LATCHC; 
        current := LATCHC;
      end;
      if (current = ABORC) then
      begin
        list[1, i] := AORB; 
        current := AORB;
      end;
      if (current = AORB) and (last = LATCHA) then
      begin
        list[1, i] := LATCHA; 
        current := LATCHA;
      end;
      if (current = AORB) and (last = LATCHB) then
      begin
        list[1, i] := LATCHB; 
        current := LATCHB;
      end;
      if (current = AORB) and (next = SHIFTA) then
      begin
        list[1, i] := LATCHA; 
        current := LATCHA;
      end;
      if (current = AORB) and (next = SHIFTB) then
      begin
        list[1, i] := LATCHB; 
        current := LATCHB;
      end;
      if (current = AORB) then
      begin
        list[1, i] := LATCHB; 
        current := LATCHB;
      end;
      if (current = SHIFTA) and (_length > 1) then
      begin
        { Rule 4 }
        list[1, i] := LATCHA; 
        current := LATCHA;
      end;
      if (current = SHIFTB) and (_length > 1) then
      begin
        { Rule 5 }
        list[1, i] := LATCHB; 
        current := LATCHB;
      end;
      if (current = SHIFTA) and (last = LATCHA) then
      begin
        list[1, i] := LATCHA; 
        current := LATCHA;
      end;
      if (current = SHIFTB) and (last = LATCHB) then
      begin
        list[1, i] := LATCHB; 
        current := LATCHB;
      end;
      if (current = SHIFTA) and (last = LATCHC) then
      begin
        list[1, i] := LATCHA; 
        current := LATCHA;
      end;
      if (current = SHIFTB) and (last = LATCHC) then
      begin
        list[1, i] := LATCHB; //current := LATCHB;
      end;
    end; { Rule 2 is implimented elsewhere, Rule 6 is implied }
  end;
  grwp(indexlist, list);
end;

 { Translate Code 128 Set A characters into barcodes.
   This set handles all control characters NULL to US. }
procedure c128_set_a(source: Byte; var dest: String;
  var values: TIntegerDynArray; var bar_chars: Integer);
begin
  { limit the range to 0-127 }
  source := source and 127;

  if (source < 32) then
    source := source + 64
  else
    source := source - 32;

  dest := dest + C128Table[source];
  values[bar_chars] := source;
  Inc(bar_chars);
end;

 { Translate Code 128 Set B characters into barcodes.
   This set handles all characters which are not part of long numbers and not
   control characters. }
procedure c128_set_b(source: Byte; var dest: String;
  var values: TIntegerDynArray; var bar_chars: Integer);
begin
  { limit the range to 0-127 }
  source := source and 127;
  source := source - 32;

  dest := dest + C128Table[source];
  values[bar_chars] := source;
  Inc(bar_chars);
end;

 { Translate Code 128 Set C characters into barcodes.
   This set handles numbers in a compressed form. }
procedure c128_set_c(source_a: Byte; source_b: Byte; var dest: String;
  var values: TIntegerDynArray; var bar_chars: Integer);
var
  weight: Integer;
 begin
   weight := (10 * StrToInt(Chr(source_a))) + StrToInt(Chr(source_b));
   dest := dest + C128Table[weight];
   values[bar_chars] := weight;
   Inc(bar_chars);
end;

{ Handles Code 128 and NVE-18. }
function code_128(ASymbol: PointerTo_zint_symbol; ASource: PByte; 
  ALength: Integer): Integer;
var
  i, j, k, bar_characters, read, total_sum: Integer;
  values: TIntegerDynArray = nil;
  error_number, indexchaine, indexlist, sourcelen, f_state: Integer;
  _set: TCharDynArray = nil;
  fset: TCharDynArray = nil;
  last_set, current_set: Char;
  mode: Integer;
  glyph_count: Single;
  dest: String;
  list: TGlobalList;
  P: PByte;
begin
  list := Default(TGlobalList);
  
  SetLength(_set, 170);
  FillChar(_set[0], Length(_set), ord(' '));
  
  SetLength(fset, 170);
  FillChar(fset[0], Length(fset), ord(' '));
  
  SetLength(values, 170);
  
  current_set := ' ';
  error_number := 0;

  sourcelen := ALength;

  bar_characters := 0;
  f_state := 0;

  if (sourcelen > 160) then
  begin
    { This only blocks ridiculously long input - the actual length of the
      resulting barcode depends on the type of data, so this is trapped later }
    ASymbol^.SetErrorText('Input too long (max 80 characters)');
    Result := ERROR_TOO_LONG; 
    exit;
  end;

  { Detect extended ASCII characters }
  P := ASource;
  for i := 0 to sourcelen - 1 do
  begin
    if (P^ >= 128) then
      fset[i] := 'f';
    inc(P);
  end;
  fset[sourcelen] := #0;

  { Decide when to latch to extended mode - Annex E note 3 }
  j := 0;
  for i := 0 to sourcelen - 1 do
  begin
    if (fset[i] = 'f') then
      inc(j)
    else
      j := 0;

    if (j >= 5) then
    begin
      for k := i downto (i - 4) do
        fset[k] := 'F';
    end;

    if ((j >= 3) and (i = sourcelen - 1)) then
    begin
      for k := i downto i - 2 do
        fset[k] := 'F';
    end;
  end;

  { Decide if it is worth reverting to 646 encodation for a few
    characters as described in 4.3.4.2 (d) }
  for i := 1 to sourcelen - 1 do
  begin
    if ((fset[i - 1] = 'F') and (fset[i] = ' ')) then
    begin
      { Detected a change from 8859-1 to 646 - count how long for }
      j := 0;
      while (fset[i + j] = ' ') and (i + j < sourcelen) do
        Inc(j);

      if (j < 5) or ((j < 3) and (i + j = sourcelen - 1)) then
      begin
        { Uses the same figures recommended by Annex E note 3 }
        { Change to shifting back rather than latching back }
        for k := 0 to j - 1 do
          fset[i + k] := 'n';
      end;
    end;
  end;

  { Decide on mode using same system as PDF417 and rules of ISO 15417 Annex E }
  indexlist := 0;
  indexchaine := 0;

  mode := parunmodd(ASource[indexchaine]);
  if ((ASymbol^.symbology = BARCODE_CODE128B) and (mode = ABORC)) then
    mode := AORB;

  FillChar(list[0], 170, 0);

  repeat
    list[1, indexlist] := mode;
    while ((list[1, indexlist] = mode) and (indexchaine < sourcelen)) do
    begin
      Inc(list[0, indexlist]);
      Inc(indexchaine);
      mode := parunmodd(ASource[indexchaine]);
      if ((ASymbol^.symbology = BARCODE_CODE128B) and (mode = ABORC)) then
        mode := AORB;
    end;
    Inc(indexlist);
  until not (indexchaine < sourcelen);

  dxsmooth(indexlist, list);

  { Resolve odd length LATCHC blocks }
  if ((list[1, 0] = LATCHC) and ((list[0, 0] and 1) <> 0)) then
  begin
    { Rule 2 }
    Inc(list[0, 1]);
    Dec(list[0, 0]);
    if (indexlist = 1) then
    begin
      list[0, 1] := 1;
      list[1, 1] := LATCHB;
      indexlist := 2;
    end;
  end;
  if (indexlist > 1) then
  begin
    for i := 1 to indexlist - 1 do
    begin
      if ((list[1, i] = LATCHC) and ((list[0, i] and 1) <> 0)) then
      begin
        { Rule 3b }
	Inc(list[0, i - 1]);
	Dec(list[0, i]);
      end;
    end;
  end;

  { Put set data into set[] }

  read := 0;
  for i := 0 to indexlist - 1 do
  begin
    for j := 0 to list[0, i] - 1 do
    begin
      case(list[1, i]) of
        SHIFTA: _set[read] := 'a';
	LATCHA: _set[read] := 'A';
	SHIFTB: _set[read] := 'b';
	LATCHB: _set[read] := 'B';
  	LATCHC: _set[read] := 'C';
      end;
      Inc(read);
    end;
  end;

  { Adjust for strings which start with shift characters - make them latch instead }
  i := 0;
  while _set[i] = 'a' do
  begin
    _set[i] := 'A';
    Inc(i);
  end;

  i := 0;
  while _set[i] = 'b' do
  begin
    _set[i] := 'B';
    Inc(i);
  end;

  { Now we can calculate how long the barcode is going to be - and stop it from
    being too long }
  last_set := ' ';
  glyph_count := 0.0;
  for i := 0 to sourcelen - 1 do
  begin
    if ((_set[i] = 'a') or (_set[i] = 'b')) then
      glyph_count := glyph_count + 1.0;

    if ((fset[i] = 'f') or (fset[i] = 'n')) then
      glyph_count := glyph_count + 1.0;

    if (((_set[i] = 'A') or (_set[i] = 'B')) or (_set[i] = 'C')) then
    begin
      if (_set[i] <> last_set) then
      begin
        last_set := _set[i];
	glyph_count := glyph_count + 1.0;
      end;
    end;
    if (i = 0) then
    begin
      if (fset[i] = 'F') then
        glyph_count := glyph_count + 2.0;
    end
    else
    begin
      if ((fset[i] = 'F') and (fset[i - 1] <> 'F')) then
        glyph_count := glyph_count + 2.0;

      if ((fset[i] <> 'F') and (fset[i - 1] = 'F')) then
        glyph_count := glyph_count + 2.0;
    end;

    if(_set[i] = 'C') then
      glyph_count := glyph_count + 0.5
    else
      glyph_count := glyph_count + 1.0;
  end;
  
  if (glyph_count > 80.0) then
  begin
    ASymbol^.SetErrorText('Input too long (max 80 characters)');
    Result := ERROR_TOO_LONG; 
    exit;
  end;

  { So now we know what start character to use - we can get on with it! }
  dest := '';
  if (ASymbol^.output_options and READER_INIT) <> 0 then
  begin
    { Reader Initialisation mode }
    case _set[0] of
      'A': { Start A }
        begin
	  dest := dest + C128Table[103];
	  values[0] := 103;
	  current_set := 'A';
	  dest := dest + C128Table[96]; { FNC3 }
	  values[1] := 96;
	  Inc(bar_characters);
        end;
      'B': { Start B }
        begin
	  dest := dest + C128Table[104];
	  values[0] := 104;
	  current_set := 'B';
	  dest := dest + C128Table[96]; { FNC3 }
	  values[1] := 96;
	  Inc(bar_characters);
        end;
      'C': { Start C }
        begin
	  dest := dest + C128Table[104]; { Start B }
	  values[0] := 105;
	  dest := dest + C128Table[96];  { FNC3 }
	  values[1] := 96;
	  dest := dest + C128Table[99];  { Code C }
	  values[2] := 99;
	  Inc(bar_characters, 2);
	  current_set := 'C';
        end;
    end;
  end
  else
  begin
    { Normal mode }
    case _set[0] of
      'A': { Start A }
        begin
	  dest := dest + C128Table[103];
	  values[0] := 103;
	  current_set := 'A';
        end;
      'B': { Start B }
        begin
	  dest := dest + C128Table[104];
	  values[0] := 104;
	  current_set := 'B';
	end;
      'C': { Start C }
        begin
	  dest := dest + C128Table[105];
	  values[0] := 105;
	  current_set := 'C';
	end;
    end;
  end;
  Inc(bar_characters);
  //last_set := _set[0];

  if(fset[0] = 'F') then
  begin
    case current_set of
      'A':
        begin
	  dest := dest + C128Table[101];
	  dest := dest + C128Table[101];
	  values[bar_characters] := 101;
	  values[bar_characters + 1] := 101;
	end;
      'B':
        begin
	  dest := dest + C128Table[100];
	  dest := dest + C128Table[100];
	  values[bar_characters] := 100;
	  values[bar_characters + 1] := 100;
	end;
    end;
    Inc(bar_characters, 2);
    f_state := 1;
  end;

  { Encode the data }
  read := 0;
  repeat
    if ((read <> 0) and (_set[read] <> current_set)) then
    begin { Latch different code set }
      case _set[read] of
        'A':
          begin
            dest := dest + C128Table[101];
	    values[bar_characters] := 101;
	    Inc(bar_characters);
	    current_set := 'A';
	  end;
	'B':
          begin
            dest := dest + C128Table[100];
	    values[bar_characters] := 100;
	    Inc(bar_characters);
	    current_set := 'B';
	  end;
	'C':
          begin
            dest := dest + C128Table[99];
	    values[bar_characters] := 99;
	    Inc(bar_characters);
	    current_set := 'C';
	  end;
      end;
    end;

    if (read <> 0) then
    begin
      if ((fset[read] = 'F') and (f_state = 0)) then
      begin
        { Latch beginning of extended mode }
	case current_set of
	  'A':
            begin
	      dest := dest + C128Table[101];
	      dest := dest + C128Table[101];
	      values[bar_characters] := 101;
	      values[bar_characters + 1] := 101;
	    end;
	  'B':
            begin
	      dest := dest + C128Table[100];
	      dest := dest + C128Table[100];
	      values[bar_characters] := 100;
	      values[bar_characters + 1] := 100;
	    end;
	end;
	Inc(bar_characters, 2);
	f_state := 1;
      end;
      if ((fset[read] = ' ') and (f_state = 1)) then
      begin
        { Latch end of extended mode }
	  case current_set of
	    'A':
              begin
	        dest := dest + C128Table[101];
		dest := dest + C128Table[101];
		values[bar_characters] := 101;
		values[bar_characters + 1] := 101;
              end;
            'B':
              begin
	        dest := dest + C128Table[100];
		dest := dest + C128Table[100];
		values[bar_characters] := 100;
		values[bar_characters + 1] := 100;
              end;
          end;
	  Inc(bar_characters, 2);
	  f_state := 0;
      end;
    end;

    if ((fset[read] = 'f') or (fset[read] = 'n')) then
    begin
      { Shift to or from extended mode }
      case current_set of
        'A':
          begin
	    dest := dest + C128Table[101]; { FNC 4 }
	    values[bar_characters] := 101;
          end;
        'B':
          begin
	    dest := dest + C128Table[100]; { FNC 4 }
	    values[bar_characters] := 100;
          end;
      end;
      Inc(bar_characters);
    end;

    if ((_set[read] = 'a') or (_set[read] = 'b')) then
    begin
      { Insert shift character }
      dest := dest + C128Table[98];
      values[bar_characters] := 98;
      Inc(bar_characters);
    end;

    case _set[read] of
      { Encode data characters }
      'a', 'A':
        begin
          c128_set_a(ASource[read], dest, values, bar_characters);
	  Inc(read);
	end;
      'b', 'B':
        begin
          c128_set_b(ASource[read], dest, values, bar_characters);
	  Inc(read);
	end;
      'C':
        begin
          c128_set_c(ASource[read], ASource[read + 1], dest, values, bar_characters);
          Inc(read, 2);
        end;
    end;
  until not (read < sourcelen);

  { check digit calculation }
  total_sum := 0;

  for i := 0 to bar_characters - 1 do
  begin
    if (i > 0) then
      values[i] := values[i] * i;
    Inc(total_sum, values[i]);
  end;
  dest := dest + C128Table[total_sum mod 103];

  // STOP character
  dest := dest + C128Table[106];
  expand(ASymbol, dest);
  
  ASymbol^.SetText(PChar(ASource));
  
  result := error_number; 
end;

{ Handle EAN-128 (Now known as GS1-128) }
function ean_128(ASymbol: PointerTo_zint_symbol; ASource: PByte; 
  ALength: Integer): Integer;
var
  values: TIntegerDynArray = nil;
  bar_characters, read, total_sum: Integer;
  error_number, indexchaine, indexliste: Integer;
  _set: TCharDynArray = nil;
  mode: Integer;
  last_set: Char;
  glyph_count: Single;
  dest: String;
  separator_row, linkage_flag, c_count: Integer;
  reduced: TCharDynArray = nil;
  i, j: Integer;
  list: TGlobalList;
  P: PByte;
begin
  list := Default(TGlobalList);
  
  SetLength(values, 170);
  SetLength(_set, 170);
  SetLength(reduced, ALength + 1);
  error_number := 0;
  linkage_flag := 0;
  bar_characters := 0;
  separator_row := 0;

  FillChar(_set[0], Length(_set), ord(' '));

  if (ALength > 160) then
  begin
    { This only blocks ridiculously long input - the actual Length(source) of the
      resulting barcode depends on the type of data, so this is trapped later }
    ASymbol^.SetErrorText('Input too long (max 160 characters)');
    Result := ERROR_TOO_LONG; 
    exit;
  end;

  P := ASource;
  for i := 0 to ALength - 1 do
  begin
    if (P^ = 0) then
    begin
      { Null characters not allowed! }
      ASymbol^.SetErrorText('NULL character in input data');
      Result := ERROR_INVALID_DATA; 
      exit;
    end;
    inc(P);
  end;

  { If part of a composite symbol make room for the separator pattern }
  if (ASymbol^.symbology = BARCODE_EAN128_CC) then
  begin
    separator_row := ASymbol^.rows;
    ASymbol^.row_height[ASymbol^.rows] := 1;
    inc(ASymbol^.rows);
  end;

  if(ASymbol^.input_mode <> GS1_MODE) then
  begin
    { GS1 data has not been checked yet }
    error_number := gs1_verify(ASymbol, ASource, ALength, reduced);
    if (error_number <> 0) then begin 
      Result := error_number; 
      exit; 
    end;
  end;

  { Decide on mode using same system as PDF417 and rules of ISO 15417 Annex E }
  indexliste := 0;
  indexchaine := 0;

  mode := parunmodd(Ord(reduced[indexchaine]));
  if (reduced[indexchaine] = '[') then
    mode := ABORC;

  FillChar(list[0], Length(list[0]), 0);

  repeat
    list[1, indexliste] := mode;
    while ((list[1, indexliste] = mode) and (indexchaine < strlen(reduced))) do
    begin
      inc(list[0, indexliste]);
      Inc(indexchaine);
      mode := parunmodd(reduced[indexchaine]);
      if (reduced[indexchaine] = '[') then mode := ABORC;
    end;
    inc(indexliste);
  until not (indexchaine < strlen(reduced));

  dxsmooth(indexliste, list);

  { Put set data into _set[] }
  read := 0;
  for i := 0 to indexliste - 1 do
  begin
    for j := 0 to list[0][i] - 1 do
    begin
      case list[1, i] of
        SHIFTA: _set[read] := 'a';
	LATCHA: _set[read] := 'A';
	SHIFTB: _set[read] := 'b';
	LATCHB: _set[read] := 'B';
	LATCHC: _set[read] := 'C';
      end;
      Inc(read);
    end;
  end;

  { Watch out for odd-Length(source) Mode C blocks }
  c_count := 0;
  for i := 0 to read - 1 do
  begin
    if (_set[i] = 'C') then
    begin
      if (reduced[i] = '[') then
      begin
        if (c_count and 1) <> 0 then
        begin
	  if ((i - c_count) <> 0) then
	    _set[i - c_count] := 'B'
          else
	    _set[i - 1] := 'B';
        end;
	c_count := 0;
      end
      else
        Inc(c_count);
    end
    else
    begin
      if (c_count and 1) <> 0 then
      begin
        if ((i - c_count) <> 0) then
	  _set[i - c_count] := 'B'
        else
	  _set[i - 1] := 'B';
      end;
      c_count := 0;
    end;
  end;

  if (c_count and 1) <> 0 then
  begin
    if (read - c_count <> 0) then
      _set[read - c_count] := 'B'
    else
      _set[read - 1] := 'B';
  end;

  for i := 1 to read - 2 do
  begin
    if ((_set[i] = 'C') and ((_set[i - 1] = 'B') and (_set[i + 1] = 'B'))) then
      _set[i] := 'B';
  end;

  { Now we can calculate how long the barcode is going to be - and stop it from
    being too long }
  last_set := ' ';
  glyph_count := 0.0;
  for i := 0 to strlen(reduced) - 1 do
  begin
    if ((_set[i] = 'a') or (_set[i] = 'b')) then
      glyph_count := glyph_count + 1.0;

    if (((_set[i] = 'A') or (_set[i] = 'B')) or (_set[i] = 'C')) then
    begin
      if (_set[i] <> last_set) then
      begin
        last_set := _set[i];
	glyph_count := glyph_count + 1.0;
      end;
    end;

    if ((_set[i] = 'C') and (reduced[i] <> '[')) then
      glyph_count := glyph_count + 0.5
    else
      glyph_count := glyph_count + 1.0;
  end;
  
  if(glyph_count > 80.0) then
  begin
    ASymbol^.SetErrorText('Input too long (max 80 characters)');
    result := ERROR_TOO_LONG; 
    exit;
  end;

  { So now we know what start character to use - we can get on with it! }
  dest := '';
  case _set[1] of
    'A': { Start A }
      begin
        dest := dest + C128Table[103];
	values[0] := 103;
      end;
    'B': { Start B }
      begin
        dest := dest + C128Table[104];
	values[0] := 104;
      end;
    'C': { Start C }
      begin
        dest := dest + C128Table[105];
	values[0] := 105;
      end;
  end;
  Inc(bar_characters);

  dest := dest + C128Table[102];
  values[1] := 102;
  Inc(bar_characters);

    { Encode the data }
    read := 0;
    repeat
      if ((read <> 0) and (_set[read] <> _set[read - 1])) then
      begin { Latch different code set }
        case (_set[read]) of
	'A':
          begin
	    dest := dest + C128Table[101];
	    values[bar_characters] := 101;
	    inc(bar_characters);
	  end;
			 
        'B':
          begin
	    dest := dest + C128Table[100];
	    values[bar_characters] := 100;
	    inc(bar_characters);
	  end;
	'C':
          begin
	    dest := dest + C128Table[99];
	    values[bar_characters] := 99;
	    Inc(bar_characters);
	  end
	end;
      end;

      if (_set[read] = 'a') or (_set[read] = 'b') then
      begin
        { Insert shift character }
	dest := dest + C128Table[98];
	values[bar_characters] := 98;
	Inc(bar_characters);
      end;

      if (reduced[read] <> '[') then
      begin
        { Encode data characters }
	case _set[read] of
	  'A', 'a':
            begin
	      c128_set_a(Ord(reduced[read]), dest, values, bar_characters);
	      Inc(read);
	    end;
	  'B', 'b':
            begin
	      c128_set_b(Ord(reduced[read]), dest, values, bar_characters);
	      Inc(read);
	    end;
	  'C':
            begin
              c128_set_c(Ord(reduced[read]), Ord(reduced[read + 1]), dest, values, bar_characters);
              Inc(read, 2);
	  end;
	end;
      end
      else
      begin
        dest := dest + C128Table[102];
	values[bar_characters] := 102;
	Inc(bar_characters);
	Inc(read);
      end;
    until not (read < strlen(reduced));

    { "...note that the linkage flag is an extra code set character between
        the last data character and the Symbol Check Character"
        (GS1 Specification) }

    { Linkage flags in GS1-128 are determined by ISO/IEC 24723 section 7.4 }

    case ASymbol^.option_1 of
      1, 2:
        begin  // CC-A or CC-B 2D component 
          case _set[strlen(reduced )- 1] of
            'A': linkage_flag := 100;
            'B': linkage_flag := 99;
            'C': linkage_flag := 101;
          end;
        end;
      3:
        begin  // CC-C 2D component
          case _set[strlen(reduced) - 1] of
            'A': linkage_flag := 99;
            'B': linkage_flag := 101;
            'C': linkage_flag := 100;
          end;
        end;
    end;

    if (linkage_flag <> 0) then
    begin
      dest := dest + C128Table[linkage_flag];
      values[bar_characters] := linkage_flag;
      Inc(bar_characters);
    end;

    { check digit calculation }
    total_sum := 0;
    for i := 0 to bar_characters do
    begin
      if (i > 0) then
        values[i] := values[i] * i;
      inc(total_sum, values[i]);
    end;
    dest := dest + C128Table[total_sum mod 103];
    values[bar_characters] := total_sum mod 103;
    Inc(bar_characters);

    // STOP character
    dest := dest + C128Table[106];
    values[bar_characters] := 106;
    Inc(bar_characters);
    
    expand(ASymbol, dest);

    { Add the separator pattern for composite symbols }
    if (ASymbol^.symbology = BARCODE_EAN128_CC) then
    begin
      for i := 0 to ASymbol^.width - 1 do
      begin
        if not module_is_set(ASymbol, separator_row + 1, i) then
          set_module(ASymbol, separator_row, i);
      end;
    end;

    ASymbol^.text[0] := 0;
    P := ASource;
    for i := 0 to ALength - 1 do
    begin
      if ((P^ <> Ord('[')) and (P^ <> Ord(']'))) then
        ASymbol^.text[i] := P^;

      if (P^ = Ord('[')) then
        ASymbol^.text[i] := Ord('(');

      if (P^ = Ord(']')) then
        ASymbol^.text[i] := Ord(')');
      
      inc(P);
    end;

    Result := error_number; 
end;

{ Add check digit if encoding an NVE18 symbol }
function nve_18(ASymbol: PointerTo_zint_symbol; ASource: PByte;
  ALength: Integer): Integer;
var
  error_number, zeroes, nve_check, total_sum, sourcelen: Integer;
  ean128_equiv: TByteDynArray = nil;
  i: Integer;
begin
  SetLength(ean128_equiv, 25);
  FillChar(ean128_equiv[0], 25, 0);
  
  sourcelen := ALength;
  if (sourcelen > 17) then
  begin
    ASymbol^.SetErrorText('Input too long (max 17 characters)');
    Result := ERROR_TOO_LONG; 
    exit;
  end;

  error_number := is_sane(NEON, ASource, ALength);
  if (error_number = ERROR_INVALID_DATA) then
  begin
    ASymbol^.SetErrorText('Invalid characters in data');
    Result := error_number; 
    exit;
  end;

  zeroes := 17 - sourcelen;
  ustrcpy(ean128_equiv, '[00]');
  FillChar(ean128_equiv[4], zeroes, Ord('0'));
  ean128_equiv[4 + zeroes] := 0;
  concat(PChar(@ean128_equiv[0]), PChar(ASource));

  total_sum := 0;
  for i := sourcelen - 1 downto 0 do
  begin
    inc(total_sum, ctoi(Char(ASource[i])));
    if (((sourcelen - 1 - i) and 1) = 0) then
      Inc(total_sum, 2 * ctoi(Char(ASource[i])));
  end;
  nve_check := 10 - total_sum mod 10;
  if (nve_check = 10) then nve_check := 0;
  ean128_equiv[21] := Ord(itoc(nve_check));
  ean128_equiv[22] := 0;

  error_number := ean_128(ASymbol, @ean128_equiv[0], ustrlen(ean128_equiv));
  result := error_number; 
end;

{ EAN-14 - A version of EAN-128 }
function ean_14(ASymbol: PointerTo_zint_symbol; ASource: PByte; ALength: Integer): Integer;
var
  i, sum, check_digit, zeros: Integer;
  ean128_equiv: String;
  b: byte;
begin
  if (ALength > 13) then
  begin
    ASymbol^.SetErrorText('Input wrong length (max 13 characters)');
    Result := ERROR_TOO_LONG; 
    exit;
  end;

  Result := is_sane(NEON, ASource, ALength);
  if (Result = ERROR_INVALID_DATA) then
  begin
    ASymbol^.SetErrorText('Invalid character in data');
    exit;
  end;

  sum := 0;
  for i := ALength - 1 downto 0 do
  begin
    b := StrToInt(Char(ASource[i]));
    inc(sum, b);
    if not odd(ALength - 1 - i) then //(((ALength - 1 - i) and 1) = 0) then
      Inc(sum, 2 * b);
  end;
  check_digit := 10 - sum mod 10;
  if (check_digit = 10) then 
    check_digit := 0;

  zeros := 13 - ALength;
  ean128_equiv := '[01]' + StringOfChar('0', zeros) + PChar(ASource) + IntToStr(check_digit);

  Result := ean_128(ASymbol, PByte(@ean128_equiv[1]), Length(ean128_equiv));
end;

end.


