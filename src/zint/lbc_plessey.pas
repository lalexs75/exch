{  lbc_plessey - Handles plessey bar codes

  Based on Zint (done by Robin Stuart and the Zint team)
    http://github.com/zint/zint
  and Pascal adaption by TheUnknownOnes
    http://theunknownones.net
    
  Refactoring: W.Pamler
  
  The results were checked against https://www.free-barcode-generator.net/msi/
} 

unit lbc_plessey;

{$mode objfpc}{$H+}

interface

uses                 
  SysUtils, zint;

function plessey(ASymbol: PZintSymbol; const ASource: String): Integer;
function msi_plessey(ASymbol: PZintSymbol; const ASource: String): Integer;

implementation

uses      
  lbc_helper;

const
  SSET = '0123456789ABCDEF';

  // Idea: These are the bits in a nibble: 13 = 0, 31 = 1, LSB at left
  PlesseyTable: array[0..15] of String = (
    '13131313', '31131313', '13311313', '31311313', '13133113', 
    '31133113',	'13313113', '31313113', '13131331', '31131331', 
    '13311331', '31311331', '13133131', '31133131', '13313131', 
    '31313131'
  );

  MSITable: array[0..9] of String = (
    '12121212', '12121221', '12122112', '12122121', '12211212', 
    '12211221', '12212112', '12212121', '21121212', '21121221'
  );

  
{-------------------------------------------------------------------------------
                  Not MSI/Plessey, but the older Plessey standard 
-------------------------------------------------------------------------------}
function CheckSum_Plessey(ASource: String): String;
const
  grid: array[0..8] of Byte = (1,1,1,1,0,1,0,0,1);
var
  i, j, check: Integer;
  checkptr: array of byte = nil;
begin
  SetLength(checkptr, Length(ASource)* 4 + 8);

  for i := 0 to Length(ASource) - 1 do
  begin
    j := i+1;
    check := pos(ASource[j], SSET) - 1;
    checkptr[4*i] := check and 1;
    checkptr[4*i+1] := (check shr 1) and 1;
    checkptr[4*i+2] := (check shr 2) and 1;
    checkptr[4*i+3] := (check shr 3) and 1;
  end;

  // CRC check digit code adapted from code by Leonid A. Broukhis
  // used in GNU Barcode
  for i := 0 to 4 * Length(ASource) - 1 do
  begin
    if (checkptr[i] <> 0) then
      for j := 0 to 8 do
        checkptr[i+j] := checkptr[i+j] xor grid[j];
  end;

  check := 0;
  for i := 0 to 7 do
    if checkptr[Length(ASource) * 4 + i] = 1 then
      check := check or (1 shl i);
  
  Result := SSET[succ(check and $0F)] + SSET[succ((check and $F0) shr 4)];   
end;
             
function plessey(ASymbol: PZintSymbol; const ASource: String): Integer;
begin
  Result := basic_encoder(ASymbol, ASource,
    65, SSET, '31311331', PlesseyTable, '331311313', @CheckSum_Plessey, false);
  if Result = 0 then
    ASymbol^.SetText(ASource);
end;           


{-------------------------------------------------------------------------------
     MSI Plessey Modulo 10 and Modulo 11 check digit calculation routines
                    
  Algorithm from Barcode Island, http://www.barcodeisland.com/ 
  (wp: page no longer available)
-------------------------------------------------------------------------------}
function PartialString(ASource: String; OddIndices: boolean): String;
var
  i: Integer;
begin
  Result := '';
  if OddIndices then i := 1 else i := 2;
  while i <= Length(ASource) do
  begin
    Result := Result + ASource[i];
    inc(i, 2);
  end;
end;

function SumOfDigits(s: String): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(s) do
    Result := Result + StrToInt(s[i]);
end;

function SumOfDigits(s: String; OddIndices: Boolean): Integer;
var
  i: Integer;
begin
  Result := 0;
  if OddIndices then i := 1 else i := 2;
  while i <= Length(s) do
  begin
    Result := Result + StrToInt(s[i]);
    inc(i, 2);
  end;
end;

{ Calculation of a mod 10 check digit.
  Algorithm from Barcode Island, http://www.barcodeisland.com/ 
  (wp: page no longer available) }
function CheckSum_Plessey_Mod10(ASource: String): String;
var
  s: String;
  sum: Integer;
  check: Integer;
begin
  s := PartialString(ASource, odd(Length(ASource)));
  s := IntToStr(StrToInt(s)*2);
  sum := SumOfDigits(s) + SumOfDigits(ASource, not odd(Length(ASource)));
  check := 10 - sum mod 10;
  if check = 10 then check := 0;
  Result := IntToStr(check);
end;

{ Calculation of two mod 10 check digits.
  Based on above Barcode Island code. }
function CheckSum_Plessey_Mod10_Mod10(ASource: String): String;
var
  s: String;
  sum: Integer;
  check: Integer;
begin
  // Calculate first check digit
  Result := CheckSum_Plessey_Mod10(ASource);
  
  // Calculate second check digit
  s := PartialString(ASource, not odd(Length(ASource))) + Result;
  s := IntToStr(StrToInt(s)*2);
  sum := SumOfDigits(s) + SumOfDigits(ASource, odd(Length(ASource)));
  check := 10 - sum mod 10;
  if check = 10 then check := 0;
  
  Result := Result + IntToStr(check);
end;

{  Calculates a Modulo 11 check digit using the system discussed on Wikipedia -
  see http://en.wikipedia.org/wiki/Talk:MSI_Barcode 
  Uses the IBM weight system }
function CheckSum_Plessey_Mod11(ASource: String): String;
var
  i, sum, weight, check: Integer;
begin
  sum := 0;
  weight := 2;
  for i := Length(ASource) downto 1 do
  begin
    inc(sum, weight * StrToInt(ASource[i]));
    inc(weight);
    if weight > 7 then weight := 2;
  end;
  check := (11 - sum mod 11) mod 11;
  
  Result := IntToStr(check);
end;

{ Calculates a Modulo 11 and a Modulo 10 check digit.
  Combines the Barcode Island and Wikipedia code 
  Verified against http://www.bokai.com/BarcodeJSP/applet/BarcodeSampleApplet.htm 
  Weighted using the IBM system  }
function Checksum_Plessey_Mod11_Mod10(ASource: String): String;
var
  ch1, ch2: string;
begin
  // Calculate first digit (mod 11)
  ch1 := Checksum_Plessey_Mod11(ASource);
  
  // Calculated second digit (mod 10);
  ch2 := CheckSum_Plessey_Mod10(ASource + ch1);
  
  Result := ch1 + ch2;
end;


{ ------------------------------------------------------------------------------
                             Main MSI/Plessey routine
-------------------------------------------------------------------------------}
function msi_plessey(ASymbol: PZintSymbol; const ASource: String): Integer;
var
  maxlen: Integer;
  checkSumFunc: TCheckSumFunc;
begin
  case ASymbol^.Option_2 of
    1: begin      // one mod 10 check digit
         checkSumFunc := @CheckSum_Plessey_Mod10;
         maxlen := 18;
       end;
    2: begin      // two mod 10 check digits
         checksumfunc := @CheckSum_Plessey_Mod10_Mod10;
         maxlen := 18;
       end;
    3: begin     // one mod 11 check digit
         checksumfunc := @Checksum_Plessey_Mod11;
         maxlen := 55;
       end;
    4: begin     // a mod 11 and a mod 10 check digit
         checksumfunc := @Checksum_Plessey_Mod11_Mod10;
         maxLen := 18;
       end;  
    else
       begin    // no check digits
         checkSumFunc := nil;
         maxLen := 55;
       end;
  end;
  
  Result := basic_encoder(ASymbol, ASource,
    maxlen, NEON, '21', MSITable, '121', checksumFunc, false); 
end;

end.

