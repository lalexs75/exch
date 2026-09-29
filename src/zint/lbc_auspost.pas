{  lbc_auspost.pas - Handles Australian post barcodes.

  Based on Zint (done by Robin Stuart and the Zint team)
    http://github.com/zint/zint
  and Pascal adaption by TheUnknownOnes
    http://theunknownones.net
    
  Refactoring: W. Pamler
} 

unit lbc_auspost;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  Types, SysUtils, zint;

function australia_post(ASymbol: PZintSymbol; ASource: String): Integer;

implementation

uses
  lbc_reedsolomon, lbc_helper;

const 
  GDSET: String = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz #';

  AusNTable: array[0..9] of String = (
    '00', '01', '02', '10', '11', '12', '20', '21', '22', '30'
  );

  AusCTable: array[0..63] of String = (
    '222', '300', '301', '302', '310', '311', '312', '320', '321', '322',
    '000', '001', '002', '010', '011', '012', '020', '021', '022', '100', 
    '101', '102', '110', '111', '112', '120', '121', '122', '200', '201', 
    '202', '210', '211', '212', '220', '221', '023', '030', '031', '032', 
    '033', '103', '113', '123', '130', '131', '132', '133', '203', '213', 
    '223', '230', '231', '232', '233', '303', '313', '323', '330', '331', 
    '332', '333', '003', '013'
  );

  AusBarTable: array[0..63] of String = (
    '000', '001', '002', '003', '010', '011', '012', '013', '020', '021',
    '022', '023', '030', '031', '032', '033', '100', '101', '102', '103', 
    '110', '111', '112', '113', '120', '121', '122', '123', '130', '131', 
    '132', '133', '200', '201', '202', '203', '210', '211', '212', '213',
    '220', '221', '222', '223', '230', '231', '232', '233', '300', '301', 
    '302', '303', '310', '311', '312', '313', '320', '321', '322', '323', 
    '330', '331', '332', '333'
  );

function convert_pattern(data: Char; shift: Integer): Byte; inline;
begin
  Result := (Ord(data) - Ord('0')) shl shift;
end;

{ Adds Reed-Solomon error correction to auspost }
procedure rs_error_correction(var data_pattern: String);
var
  i, triple_writer: Integer;
  triple: TByteDynArray = nil;
  inv_triple: TByteDynArray = nil;
  res : TByteDynArray = nil;
begin
  triple_writer := 0;
  SetLength(triple, 31);
  SetLength(inv_triple, 31);
  SetLength(res, 5);

  i := 3;
  while i <= Length(data_pattern) do
  begin
    triple[triple_writer] := 
      convert_pattern(data_pattern[i    ], 4) + 
      convert_pattern(data_pattern[i + 1], 2) + 
      convert_pattern(data_pattern[i + 2], 0);
    Inc(i, 3);
    Inc(triple_writer);
  end;

  for i := 0 to triple_writer - 1 do
    inv_triple[i] := triple[(triple_writer - 1) - i];

  rs_init_gf($43);
  rs_init_code(4, 1);
  rs_encode(triple_writer, @inv_triple[0], @res[0]);
  for i := 3 downto 0 do
    data_pattern := data_pattern + AusBarTable[res[i]];
  rs_free();
end;

{ Handles Australia Posts's 4 State Codes }
function australia_post(ASymbol: PZintSymbol; ASource: String): Integer;
{ Customer Standard Barcode, Barcode 2 or Barcode 3 system determined automatically
   (i.e. the FCC doesn't need to be specified by the user) dependent
   on the length of the input string }

{ The contents of data_pattern conform to the following standard:
   0 := Tracker, Ascender and Descender
   1 := Tracker and Ascender
   2 := Tracker and Descender
   3 := Tracker only }
var
  i, len, writer: Integer;
  data_pattern: String;
  fcc: String; 
  dpid: String;
  localstr: String;
begin
  Result := 0;
  localstr := ASource;
  
  // Do all of the _length checking first to avoid stack smashing
  if (ASymbol^.symbology = BARCODE_AUSPOST) then
  begin
    // Format control code (FCC)
    case Length(ASource) of
      8 : fcc := '11';
      16: begin
            Result := is_sane(NEON, ASource);
            fcc := '59';
          end;
      13: fcc := '59';
      23: begin
            Result := is_sane(NEON, ASource);
            fcc := '62';
          end;
      18: fcc := '62';
    else
          ASymbol^.SetErrorText('Auspost input is wrong length');
          Result := ERROR_TOO_LONG; 
          exit;
    end;
    if (Result = ERROR_INVALID_DATA) then
    begin
      ASymbol^.SetErrorText('Invalid characters in data');
      exit;
    end;
  end
  else
  begin
    if (Length(ASource) > 8) then
    begin
      ASymbol^.SetErrorText('Auspost input is too long');
      Result := ERROR_TOO_LONG; 
      exit;
    end;
    case ASymbol^.symbology of
      BARCODE_AUSREPLY:
        fcc := '45';
      BARCODE_AUSROUTE:
        fcc := '87';
      BARCODE_AUSREDIRECT:
        fcc := '92';
    end;

    //Add leading zeros as required
    localstr := StringOfChar('0', 8 - Length(ASource)) + localstr;
  end;

  Result := is_sane(GDSET, localstr);
  if (Result = ERROR_INVALID_DATA) then
  begin
    ASymbol^.SetErrorText('Invalid characters in data');
    exit;
  end;

  // Verifiy that the first 8 characters are numbers
  dpid := copy(localstr, 1, 8);
  Result := is_sane(NEON, dpid);
  if (Result = ERROR_INVALID_DATA) then
  begin
    ASymbol^.SetErrorText('Invalid characters in DPID');
    exit;
  end;

  // START character
  data_pattern := '13';

  // Encode the FCC
  for i := 1  to 2 do
    lookup(NEON, AusNTable, fcc[i], data_pattern);

  // Delivery Point Identifier (DPID)
  for i := 1 to 8 do
    lookup(NEON, AusNTable, dpid[i], data_pattern);

  // Customer Information
  len := Length(localstr);
  if (len > 8) then
  begin
    if (len = 13) or (len = 18) then
    begin
      for i := 9 to len do
        lookup(GDSET, AusCTable, localstr[i], data_pattern);
    end
    else if (len = 16) or (len = 23) then
    begin
      for i := 9 to len do
        lookup(NEON, AusNTable, localstr[i], data_pattern);
    end;
  end;

  // Filler bar
  len := Length(data_pattern);
  if (len = 22) or (len = 37) or (len = 52) then
    data_pattern := data_pattern + '3';

  // Reed Solomon error correction
  rs_error_correction(data_pattern);

  // STOP character
  data_pattern := data_pattern + '13';

  // Turn the symbol into a bar pattern ready for plotting
  writer := 0;
  len := Length(data_pattern);
  for i := 1 to len do
  begin
    if ((data_pattern[i] = '1') or (data_pattern[i] = '0')) then
      set_module(ASymbol, 0, writer);
    set_module(ASymbol, 1, writer);
    if ((data_pattern[i] = '2') or (data_pattern[i] = '0')) then
      set_module(ASymbol, 2, writer);
    Inc(writer, 2);
  end;

  // Store parameters in Zint symbol
  ASymbol^.rows := 3;
  ASymbol^.row_height[0] := 3;
  ASymbol^.row_height[1] := 2;
  ASymbol^.row_height[2] := 3;
  ASymbol^.width := writer - 1;
  ASymbol^.SetText(localstr);
end;

end.

