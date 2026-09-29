unit lbc_common;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Types, zint;
  
function ustrlen(const AData: TByteDynArray): NativeInt;
procedure ustrcpy(var ATarget: TByteDynArray; const ASource: TByteDynArray);
procedure ustrcpy(var ATarget: TByteDynArray; const ASource: String);
procedure uconcat(var ADest: TByteDynArray; const ASource: TByteDynArray); 
procedure uconcat(var ADest: TByteDynArray; const ASource: TCharDynArray); 
procedure uconcat(var ADest: TByteDynArray; const ASource: String);


implementation

{ Local replacement for strlen() with uint8_t strings }
function ustrlen(const AData: TByteDynArray): NativeInt;
var
  i: NativeInt;
begin
  Result := High(AData) - Low(AData) + 1;
  for i := Low(AData) to High(AData) do
    if AData[i] = 0 then
    begin
      Result := i - Low(AData);
      break;
    end;
end;

{ Local replacement for strcpy() with uint8_t strings }
procedure ustrcpy(var ATarget: TByteDynArray; const ASource: TByteDynArray);
var
  len: NativeInt;
begin
  len := ustrlen(ASource);
  if len > 0 then
  begin
    Move(ASource[0], ATarget[0], Len+1);
    ATarget[len] := 0;   // Be sure we have zero terminal
  end;
end;

procedure ustrcpy(var ATarget: TByteDynArray; const ASource: String);
var
  len: NativeInt;
begin
  len := Length(ASource);
  if len > 0 then 
  begin
    Move(ASource[1], ATarget[0], Len+1);
    ATarget[len] := 0;
  end;
end;

{ Concatinates dest[] with the contents of source[], copying /0 as well }
procedure uconcat(var ADest: TByteDynArray; const ASource: TByteDynArray);
var
  j, n: NativeInt;
begin
  j := ustrlen(ADest);
  n := ustrlen(ASource);
  Move(ASource[0], ADest[j], n);
  ADest[j+n] := 0;
end;

procedure uconcat(var ADest: TByteDynArray; const ASource: TCharDynArray);
var
  j, n: NativeInt;
begin
  j := ustrlen(ADest);
  n := System.strlen(PChar(ASource));
  Move(ASource[0], ADest[j], n);
  ADest[j+n] := 0;
end;

procedure uconcat(var ADest: TByteDynArray; const ASource: String);
begin
  uconcat(ADest, PChar(ASource));
end;

end.

