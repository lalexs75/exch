{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit lazbarcodes; 

interface

uses
  zint, lbc_aztec, lbc_basic, lbc_datamatrix, lbc_helper, lbc_qr, lbc_reedsolomon, 
  lbc_render, lbc_sjis, ubarcodes, LazarusPackageIntf;

implementation

procedure Register; 
begin
  RegisterUnit('ubarcodes', @ubarcodes.Register); 
end; 

initialization
  RegisterPackage('LazBarCodes', @Register); 
end.
