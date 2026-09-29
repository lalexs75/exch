{
  Based on Zint (done by Robin Stuart and the Zint team)
    http://github.com/zint/zint

  and translation by TheUnknownOnes
    http://theunknownones.net
    
  Refactoring: W. Pamler
}

unit lbc_gs1;

{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Types, 
  zint;

function gs1_verify(ASymbol: PZintSymbol; ASource: PByte; const src_len: Integer; 
  var reduced: TCharDynArray): Integer;
function ugs1_verify(ASymbol: PZintSymbol; ASource: PByte; src_len: Integer; 
  var reduced: TByteDynArray): Integer;

implementation

uses 
  lbc_helper;

function Between(a, a1, a2: Integer): Boolean;
begin
  Result := (a >= a1) and (a <= a2);
end;

function gs1_verify(ASymbol: PZintSymbol; ASource: PByte; const src_len: Integer; 
  var reduced: TCharDynArray): Integer;
var
  i, j, last_ai, ai_latch : Integer;
  ai_string: String;
  bracket_level, max_bracket_level, ai_length, max_ai_length, min_ai_length: Integer;
  ai_value, ai_location, data_location, data_length: array[0..99] of Integer;
  ai_count: Integer;
  error_latch: Integer;
  P: PByte;
  ch: Char;
begin
  { Detect extended ASCII characters }
  P := PByte(ASource);
  for i := 0 to src_len - 1 do
  begin
    if P^ >= 128 then
    begin
      ASymbol^.SetErrorText('Extended ASCII characters are not supported by GS1');
      Result := ERROR_INVALID_DATA; 
      exit;
    end;
    if P^ < 32 then
    begin
      ASymbol^.SetErrorText('Control characters are not supported by GS1');
      Result := ERROR_INVALID_DATA; 
      exit;
    end;
    inc(P);
  end;

  if ASource^ <> Ord('[') then
  begin
    ASymbol^.SetErrorText('Data does not start with an Application identifier');
    Result := ERROR_INVALID_DATA; 
    exit;
  end;

  { Check the position of the brackets }
  bracket_level := 0;
  max_bracket_level := 0;
  ai_length := 0;
  max_ai_length := 0;
  min_ai_length := 5;
  j := 0;
  ai_latch := 0;
  P := ASource;
  for i := 0 to src_len - 1 do
  begin
    Inc(ai_length, j);
    if ((j = 1) and (P^ <> Ord(']'))) and 
       ((P^ < Ord('0')) or (P^ > Ord('9'))) 
    then 
      ai_latch := 1;
    if (P^ = Ord('[')) then begin 
      Inc(bracket_level); 
      j := 1; 
    end;
    if (P^ = Ord(']')) then
    begin
      Dec(bracket_level);
      if (ai_length < min_ai_length) then min_ai_length := ai_length;
      j := 0;
      ai_length := 0;
    end;
    if (bracket_level > max_bracket_level) then 
      max_bracket_level := bracket_level;
    if (ai_length > max_ai_length) then 
      max_ai_length := ai_length;
    inc(P);
  end;
  Dec(min_ai_length);

  if (bracket_level <> 0) then
  begin
    { Not all brackets are closed }
    ASymbol^.SetErrorText('Malformed Application Identifier in input data (brackets don''t match)');
    Result := ERROR_INVALID_DATA; 
    exit;
  end;

  if (max_bracket_level > 1) then
  begin
    { Nested brackets }
    ASymbol^.SetErrorText('Found nested brackets in input data');
    Result := ERROR_INVALID_DATA; 
    exit;
  end;

  if (max_ai_length > 4) then
  begin
    { AI is too long }
    ASymbol^.SetErrorText('Invalid Application Identifier (AI) in input data (AI too long - max 4 characters)');
    Result := ERROR_INVALID_DATA; 
    exit;
  end;

  if (min_ai_length <= 1) then
  begin
    { AI is too short }
    ASymbol^.SetErrorText('Invalid Application Identifier (AI) in input data (AI too short, at least 2 characters)');
    result := ERROR_INVALID_DATA; 
    exit;
  end;

  if (ai_latch = 1) then
  begin
    { Non-numeric data in AI }
    ASymbol^.SetErrorText('Invalid Application Identifier (AI) in input data (non-numeric characters in AI)');
    result := ERROR_INVALID_DATA; 
    exit;
  end;

  ai_count := 0;
  i := 1;
  while i < src_len do
  begin
    if char(ASource[i-1]) = '[' then
    begin
      ai_location[ai_count] := i;
      ch := char(ASource[i]);
      ai_string := '';
      while ch <> ']' do
      begin
        ai_string := ai_string + ch;
        inc(i);
        ch := char(ASource[i]);
      end;
      ai_value[ai_count] := StrToInt(ai_string);
      inc(ai_count);
    end else
      inc(i);
  end;
  
  for i := 0 to ai_count - 1 do
  begin
    data_location[i] := ai_location[i] + 3;
    if (ai_value[i] >= 100) then Inc(data_location[i]);
    if (ai_value[i] >= 1000) then Inc(data_location[i]);
    data_length[i] := 0;
    repeat
      inc(data_length[i]);
    until not ((ASource[data_location[i] + data_length[i] - 1] <> Ord('[')) and 
               (ASource[data_location[i] + data_length[i] - 1] <> 0));
    dec(data_length[i]);
  end;

  for i := 0 to ai_count - 1 do
  begin
    if (data_length[i] = 0) then
    begin
      { No data for given AI }
      ASymbol^.SetErrorText('Empty data field in input data');
      Result := ERROR_INVALID_DATA; 
      exit;
    end;
  end;

  error_latch := 0;
  ai_string := '';
  for i := 0 to ai_count - 1 do
  begin
    case ai_value[i] of
      0: 
        if (data_length[i] <> 18) then error_latch := 1;
      1, 2, 3: 
        if (data_length[i] <> 14) then error_latch := 1;
      4: 
        if (data_length[i] <> 16) then error_latch := 1;
      11, 12, 13, 14, 15, 16, 17, 18, 19: 
        if(data_length[i] <> 6) then error_latch := 1;
      20: 
        if(data_length[i] <> 2) then error_latch := 1;
      23, 24, 25, 39, 40, 41, 42, 70, 80, 81: 
        error_latch := 2;
    end;

    if Between(ai_value[i], 100, 179) or Between(ai_value[i], 1000, 1799) or 
       Between(ai_value[i], 200, 229) or Between(ai_value[i], 2000, 2299) or
       Between(ai_value[i], 300, 309) or Between(ai_value[i], 3000, 3099) or 
       Between(ai_value[i],  31,  36) or Between(ai_value[i],  310,  369)
    then
      error_latch := 2;
    
    if Between(ai_value[i], 3100, 3699) then
    begin
      if (data_length[i] <> 6) then
        error_latch := 1;
    end;

    if Between(ai_value[i], 370, 379) or Between(ai_value[i], 3700, 3799) then
      error_latch := 2;
      
    if Between(ai_value[i], 410, 415) then
    begin
      if (data_length[i] <> 13) then
        error_latch := 1;
    end;

    if Between(ai_value[i], 4100, 4199) or
       Between(ai_value[i], 700, 703) or
       Between(ai_value[i], 800, 810) or
       Between(ai_value[i], 900, 999) or 
       Between(ai_value[i], 9000, 9999)
    then
      error_latch := 2;

    if ((error_latch < 4) and (error_latch > 0)) then
    begin
      { error has just been detected: capture AI }
      ai_string := FormatFloat('(00)', ai_value[i]);
      Inc(error_latch, 4);
    end;
  end;

  if (error_latch = 5) then
  begin
    ASymbol^.SetErrorText('Invalid data length for Application Identifier ' + ai_string);
    Result := ERROR_INVALID_DATA; 
    exit;
  end;

  if (error_latch = 6) then
  begin
    ASymbol^.SetErrorText('Invalid Application Identifier value ' + ai_string);
    result := ERROR_INVALID_DATA; 
    exit;
  end;

  { Resolve AI data - put resulting string in 'reduced' }
  j := 0;

  //last_ai := 0;
  ai_latch := 1;
  for i := 0 to src_len - 1 do
  begin
    if ((ASource[i] <> Ord('[')) and (ASource[i] <> Ord(']'))) then
    begin
      reduced[j] := Char(ASource[i]);
      Inc(j);
    end;
    if (ASource[i] = Ord('[')) then
    begin
      { Start of an AI string }
      if(ai_latch = 0) then
      begin
        reduced[j] := '[';
        Inc(j);
      end;
      ai_string := Char(ASource[i+1]) + Char(ASource[i+2]);
      last_ai := StrToInt(ai_string);
      ai_latch := 0;

      { The following values from "GS-1 General Specification version 8.0 issue 2, May 2008"
        figure 5.4.8.2.1 - 1 "Element Strings with Pre-Defined Length Using Application Identifiers" }
      if (last_ai in [0..4, 11..20, 23, 31..36, 41]) then
         ai_latch := 1;
    end;
    
    { The ']' character is simply dropped from the input }
  end;
  reduced[j] := #0;

  { the character '[' in the reduced string refers to the FNC1 character }
  Result := 0;
end;

function ugs1_verify(ASymbol: PZintSymbol; ASource: PByte; src_len: Integer; 
  var reduced: TByteDynArray): Integer;
var
  temp: TCharDynArray = nil;
begin
  SetLength(temp, src_len + 5);
  Result := gs1_verify(ASymbol, ASource, src_len, temp);
  if (Result <> 0) then 
    exit;

  if (strlen(temp) < src_len + 5) then begin
    strcpy(PChar(@reduced[0]), PChar(@temp[0]));
    Result := 0;
    exit;
  end;

  ASymbol^.SetErrorText('ugs1_verify overflow');
  result := ERROR_INVALID_DATA;
end;

end. 
