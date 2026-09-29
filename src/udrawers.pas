unit udrawers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Forms;

type
  
  { TBasicBarcodeDrawer }
  
  TBasicBarcodeDrawer = class
  private
    FBackColor: TColor;
    FBarColor: TColor;
    FTextColor: TColor;
    FFontName: String;
    FFontSize: Integer;
    FFontStyle: TFontStyles;
    FWidth: Double;
    FHeight: Double;
    FLeft: Double;
    FTop: Double;
  public
    constructor Create(AWidth, AHeight: Double);
    constructor Create(ALeft, ATop, ARight, ABottom: Double);
    procedure BeginDrawing; virtual; abstract;
    procedure EndDrawing; virtual; abstract;
    procedure DrawBar(x1, y1, x2, y2: Double); virtual; abstract;
    procedure DrawCenteredText(x, y: Double; const AText: String); virtual; abstract;
    procedure DrawHexagon(x, y, wx: Double); virtual; abstract;
    procedure DrawRing(x, y, rOuter, rInner: Double); virtual; abstract;
    property BackColor: TColor read FBackColor write FBackColor;
    property BarColor: TColor read FBarColor write FBarColor;
    property TextColor: TColor read FTextColor write FTextColor;
    property FontName: String read FFontName write FFontName;
    property FontSize: Integer read FFontSize write FFontSize;
    property FontStyle: TFontStyles read FFontStyle write FFontStyle;
    property Width: Double read FWidth;
    property Height: Double read FHeight;
  end;

  
  { TCanvasBarcodeDrawer }
  
  TCanvasBarcodeDrawer = class(TBasicBarcodeDrawer)
  private
    FCanvas: TCanvas;
  protected
    property Canvas: TCanvas read FCanvas;
  public
    constructor Create(ACanvas: TCanvas; AWidth, AHeight: Double);
    constructor Create(ACanvas: TCanvas; ALeft, ATop, ARight, ABottom: Double);
    procedure BeginDrawing; override;
    procedure EndDrawing; override;
    procedure DrawBar(x1, y1, x2, y2: double); override;
    procedure DrawCenteredText(x, y: double; const AText: String); override;
    procedure DrawHexagon(x, y, wx: Double); override;
    procedure DrawRing(x, y, rOuter, rInner: Double); override;
  end;
  
  
  { TTextBarcodeDrawer }
  
  TTextBarcodeDrawer = class(TBasicBarcodeDrawer)
  protected
    FList: TStrings;
    FTitle: String;
    FFormatSettings: TFormatSettings;
  public
    constructor Create(AWidth, AHeight: Double; const ATitle: String);
    constructor Create(ALeft, ATop, ARight, ABottom: Double; const ATitle: String);
    destructor Destroy; override;
    procedure SaveToFile(const AFileName: String);
    procedure SaveToStream(const AStream: TStream);
  end;

  
  { TSvgBarcodeDrawer }

  TSvgBarcodeDrawer = class(TTextBarcodeDrawer)
  private
    function SvgColor(AColor: TColor): String;
  public
    procedure BeginDrawing; override;
    procedure EndDrawing; override;
    procedure DrawBar(x1, y1, x2, y2: double); override;
    procedure DrawCenteredText(x, y: double; const AText: String); override;
    procedure DrawHexagon(x, y, wx: Double); override;
    procedure DrawRing(x, y, rOuter, rInner: Double); override;
  end;

  { TEpsBarcodeDrawer }
  
  TEpsBarcodeDrawer = class(TTextBarcodeDrawer)
  private
    FStoredColor: TColor;
    procedure EpsColor(AColor: TColor; out cR,cG,cB: Double);
  public
    procedure BeginDrawing; override;
    procedure EndDrawing; override;
    procedure DrawBar(x1, y1, x2, y2: Double); override;
    procedure DrawCenteredText(x, y: Double; const AText: String); override;
    procedure DrawHexagon(x, y, wx: Double); override;
    procedure DrawRing(x, y, rOuter, rInner: Double); override;
  end;
  
  
implementation

type
  TDblPoint = record 
    X, Y: Double; 
  end;
  
const
  H = 1.0 / sqrt(3.0);
  HH = H + H;
  HEXAGON: array[0..5] of TDblPoint = (   //              0
    (X: 0.0; Y: HH),                      //           /     \
    (X:-1.0; Y: H),                       //         1         5
    (X:-1.0; Y:-H),                       //         |         |
    (X: 0.0; Y:-HH),                      //         2        4
    (X: 1.0; Y:-H),                       //           \     /
    (X: 1.0; Y: H)                        //              3  
  );

  { TBasicBarcodeDrawer }

constructor TBasicBarcodeDrawer.Create(AWidth, AHeight: Double);
begin
  Create(0.0, 0.0, AWidth, AHeight);
end;

// The origin of the coordinate system is in the top/left corner.
constructor TBasicBarcodeDrawer.Create(ALeft, ATop, ARight, ABottom: Double);
begin
  inherited Create;

  if ALeft < ARight then
  begin
    FLeft := ALeft;
    FWidth := ARight - ALeft;
  end else
  begin
    FLeft := ARight;
    FWidth := ALeft - ARight;
  end;

  if ATop < ABottom then
  begin
    FTop := ATop;
    FHeight := ABottom - ATop;
  end else
  begin
    FTop := ABottom;
    FHeight := ATop - ABottom;
  end;
  
  FBarColor := clBlack;
  FTextColor := clBlack;
  FFontName := Screen.MenuFont.Name;
  FFontSize := 10; 
  FFontStyle := [];
end;


{ TCanvasBarcodeDrawer }

constructor TCanvasBarcodeDrawer.Create(ACanvas: TCanvas; AWidth, AHeight: Double);
begin
  inherited Create(AWidth, AHeight);
  FCanvas := ACanvas;
end;

constructor TCanvasBarcodeDrawer.Create(ACanvas: TCanvas;
  ALeft, ATop, ARight, ABottom: Double);
begin
  inherited Create(ALeft, ATop, ARight, ABottom);
  FCanvas := ACanvas;
end;

// Fill the background
procedure TCanvasBarcodeDrawer.BeginDrawing;
begin
  FCanvas.Pen.Style := psClear;
  FCanvas.Brush.Color := FBackColor;
  FCanvas.Brush.Style := bsSolid;
  FCanvas.FillRect(round(FLeft), round(FTop), round(FLeft + FWidth), round(FTop + FHeight));
end;

procedure TCanvasBarcodeDrawer.EndDrawing;
begin
  // Nothing to do in this drawer
end;

procedure TCanvasBarcodeDrawer.DrawBar(x1, y1, x2, y2: double);
begin
  FCanvas.Brush.Color := FBarColor;
  FCanvas.Brush.Style := bsSolid;
  FCanvas.FillRect(round(FLeft + x1), round(FTop + y1), round(FLeft + x2), round(FTop + y2));
end;

procedure TCanvasBarcodeDrawer.DrawCenteredText(x, y: double; const AText: String);
var
  w: Integer;
begin
  FCanvas.Font.Name := FFontName;
  FCanvas.Font.Size := FFontSize;
  FCanvas.Font.Style := FFontStyle;
  FCanvas.Font.Color := FTextColor;
  FCanvas.Brush.Style := bsClear;
  w := FCanvas.TextWidth(AText);
  FCanvas.TextOut(round(FLeft + x - w/2), round(FTop + y), AText);
end;
  
procedure TCanvasBarcodeDrawer.DrawHexagon(x, y, wx: Double);
var
  P: array[0..5] of TPoint;
  i: Integer;
begin
  x := FLeft + x;
  y := FTop + y;
  for i := 0 to 5 do
    P[i] := Point(round(x + HEXAGON[i].X * wx), round(y + HEXAGON[i].Y * wx));
  FCanvas.Brush.Color := FBarColor;
  FCanvas.Brush.Style := bsSolid;
  FCanvas.Pen.Style := psClear;
  FCanvas.Polygon(P);
end;
  
procedure TCanvasBarcodeDrawer.DrawRing(x, y, rOuter, rInner: Double); 
var
  r: Double;
begin
  FCanvas.Pen.Color := FBarColor;
  FCanvas.Pen.Style := psSolid;
  FCanvas.Brush.Style := bsClear;
  
  if rOuter > rInner then
    FCanvas.Pen.Width := round(rOuter - rInner)
  else
    FCanvas.Pen.Width := round(rInner - rOuter);
  
  r := (rOuter + rInner) / 2;
  x := FLeft + x;
  y := FTop + y;
  FCanvas.Ellipse(round(x + r), round(y + r), round(x - r), round(y - r));
end;


{ TTextBarcodeDrawer }

constructor TTextBarcodeDrawer.Create(AWidth, AHeight: Double; const ATitle: String);
begin
  Create(0.0, 0.0, AWidth, AHeight, ATitle);
end;

constructor TTextBarcodeDrawer.Create(ALeft, ATop, ARight, ABottom: Double;
  const ATitle: String);
begin
  inherited Create(ALeft, ATop, ARight, ABottom);
  FTitle := ATitle;
  FList := TStringList.Create;
  FFormatSettings := DefaultFormatSettings;
  FFormatSettings.DecimalSeparator := '.';
end;

destructor TTextBarcodeDrawer.Destroy;
begin
  FList.Free;
  inherited;
end;

procedure TTextBarcodeDrawer.SaveToFile(const AFileName: String);
begin
  FList.SaveToFile(AFileName);
end;

procedure TTextBarcodeDrawer.SaveToStream(const AStream: TStream);
begin
  FList.SaveToStream(AStream);
end;



{ TSvgBarcodeDrawer 
  Units are millimeters. }

procedure TSvgBarcodeDrawer.BeginDrawing;
begin
  // svg header
  FList.Add(
    '<?xml version="1.0" standalone="no"?>'
  );
  FList.Add(
    '<!DOCTYPE svg PUBLIC "-//W3C/DTD SVG 1.1/EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'
  );
  FList.Add(Format(
    '<svg width="%.3fmm" height="%.3fmm" version="1.1" xmlns="http://www.w3.org/2000/svg">', [
      FWidth, FHeight], 
      FFormatSettings
  ));
    
  if FTitle <> '' then 
    FList.Add('  <desc>%s</desc>', [FTitle])
  else
    FList.Add('  <desc>Symbol generated by LazBarcodes</desc>');
  
  // Background
  FList.Add(
    '  <rect width="100%%" height="100%%" fill="#%s"/>', [SvgColor(FBackColor)]);
  
  // Begin group for symbol and text
  FList.Add(
    '  <g id="barcode">');
end;

procedure TSvgBarcodeDrawer.EndDrawing;
begin
  FList.Add('  </g>');
  FList.Add('</svg>');
end;

procedure TSvgBarcodeDrawer.DrawBar(x1, y1, x2, y2: Double);
begin
  FList.Add(Format(
    '    <rect x="%.3fmm" y="%.3fmm" width="%.3fmm" height="%.3fmm" fill="#%s" />', [
    FLeft + x1, FTop + y1, x2-x1, y2-y1, SvgColor(FBarColor)],
    FFormatSettings
  ));
end;

procedure TSvgBarcodeDrawer.DrawCenteredText(x, y: Double; const AText: String);
begin
  // Move the text start point by a font height because svg vertical position 
  // refers to the font baseline while LCL refers to the top.
  y := y + FFontSize / 72 * 25.4;  // Convert Fontsize (pts) to mm
  FList.Add(Format(
    '    <text x="%.3fmm" y="%.3fmm" text-anchor="middle" font-family="%s" font-size="%.1fpt" fill="#%s">%s</text>', [
    FLeft + x, FTop + y, FFontName, 1.0*FFontSize, SvgColor(FTextColor), AText],
    FFormatSettings
  ));
end;

procedure TSvgBarcodeDrawer.DrawHexagon(x, y, wx: Double);
var
  P: array[0..5] of TDblPoint;
  i: Integer;
begin
  x := FLeft + x;
  y := FTop + y;
  for i := 0 to 5 do
  begin
    P[i].X := x + HEXAGON[i].X * wx;
    P[i].Y := y + HEXAGON[i].Y * wx;
  end;
  
  FList.Add(Format(
    '    <polygon fill="%s" points="%.3fmm,%.3fmm %.3fmm,%.3fmm %.3fmm,%.3fmm %.3fmm,%.3fmm %.3fmm,%.3fmm %.3fmm,%.3fmm" />', 
    [SvgColor(FBarColor), P[0].X, P[0].Y, P[1].X, P[1].Y, P[2].X, P[2].Y, P[3].X, P[3].Y, P[4].X, P[4].Y, P[5].X, P[5].Y],
    FFormatSettings
  ));
end;

procedure TSvgBarcodeDrawer.DrawRing(x, y, rOuter, rInner: Double); 
begin
  FList.Add(Format(
    '    <circle cx="%.3fmm" cy="%.3fmm" r="%.3fmm" stroke-width="%.3fmm" stroke="%s" fill="none" />', [
    FLeft + x, FTop + y, (rOuter + rInner)/2, abs(rOuter - rInner), SvgColor(FBarColor)],
    FFormatSettings
  ));
end;

function TSvgBarcodeDrawer.SvgColor(AColor: TColor): String;
type
  TRgb = packed record
    R, G, B: Byte;
  end;
var
  rgb: TRgb absolute AColor;
begin
  Result := Format('%.2x%.2x%.2x', [rgb.R, rgb.G, rgb.B]);
end;
  

{ TEpsBarcodeDrawer 
  Units are poins (1 pt = 1/72 inch) 
  Check generated eps files with https://www.fviewer.com/de/view-eps. }

procedure TEpsBarcodeDrawer.BeginDrawing;
var
  R, G, B: Double;
begin
  // Start writing the header
  FList.Add('%!PS-Adobe-3.0 EPSF-3.0');
  
  FList.Add('%%Creator: LazBarcodes');
  
  if FTitle <> '' then 
    FList.Add('%%%%Title: %s', [FTitle])
  else
    FList.Add('%%Title: Symbol generated by LazBarcodes');
  FList.Add('%%Pages: 1');
  FList.Add(Format('%%%%BoundingBox: 0 0 %.2f %.2f', [FWidth, FHeight], FFormatSettings));
  FList.Add('%%EndComments');
   
  // Background
  EpsColor(FBackColor, R,G,B);
  FList.Add(Format('%.2f %.2f %.2f setrgbcolor', [R, G, B], FFormatSettings));
  FList.Add(Format('%.2f %.2f %.2f %.2f rectfill', [0.0, 0.0, 1.0*FWidth, 1.0*FHeight], FFormatSettings));

  // Set bar color
  EpsColor(FBarColor, R,G,B);
  FList.Add(Format('%.2f %.2f %.2f setrgbcolor', [R, G, B], FFormatSettings));
  FStoredColor := FBarColor;
  
  // Set font
  // Todo: Find out how the real font name can be used. Most of the Windows 
  // fonts are not accepted. 
  FList.Add(Format('/mainfont /%s findfont %.2f scalefont def', ['Helvetica', 1.0*FFontSize], FFormatSettings));
  Flist.Add('mainfont setfont');  
end;

procedure TEpsBarcodeDrawer.EndDrawing;
begin
  FList.Add('');
  FList.Add('showpage');
end;

procedure TEpsBarcodeDrawer.DrawBar(x1, y1, x2, y2: Double); 
var
  cR, cG, cB: Double;
begin
  if FStoredColor <> FBarColor then
  begin
    EpsColor(FBarColor, cR,cG,cB);
    FList.Add(Format('%.2f %.2f %.2f setrgbcolor', [cR, cG, cB], FFormatSettings));
    FStoredColor := FBarColor;
  end;
  FList.Add(Format('%0:.2f %1:.2f moveto %0:.2f %2:.2f lineto %3:.2f setlinewidth stroke', 
    [(x1 + x2) / 2, FHeight-y1, FHeight-y2, abs(x2 - x1)], FFormatSettings));
end;

procedure TEpsBarcodeDrawer.DrawCenteredText(x, y: Double; const AText: String);
var
  cR, cG, cB: Double;
begin
  if FStoredColor <> FTextColor then
  begin
    EpsColor(FTextColor, cR,cG,cB);
    FList.Add(Format('%.2f %.2f %.2f setrgbcolor', [cR, cG, cB], FFormatSettings));
    FStoredColor := FTextColor;
  end;
  
  FList.Add(Format('%.2f %.2f moveto', [x, FHeight-y], FFormatSettings));
  FList.Add(Format('(%s) dup stringwidth pop 2 div neg -%.2f rmoveto show', [AText, 1.0*FFontSize], FFormatSettings));
end;

procedure TEpsBarcodeDrawer.DrawHexagon(x, y, wx: Double);
var
  P: array[0..5] of TDblPoint;
  i: Integer;
  cR, cG, cB: Double;
begin
  for i := 0 to 5 do
  begin
    P[i].X := x + HEXAGON[i].X * wx;
    P[i].Y := y + HEXAGON[i].Y * wx;
  end;

  if FStoredColor <> FBarColor then
  begin
    EpsColor(FBarColor, cR,cG,cB);
    FList.Add(Format('%.2f %.2f %.2f setrgbcolor', [cR, cG, cB], FFormatSettings));
    FStoredColor := FBarColor;
  end;
  
  FList.Add(Format(
    'newpath '+
    '%.2f %.2f moveto '+
    '%.2f %.2f lineto '+
    '%.2f %.2f lineto '+
    '%.2f %.2f lineto '+
    '%.2f %.2f lineto '+
    '%.2f %.2f lineto '+
    '0 setlinewidth '+
    'closepath '+
    'fill', 
    [P[0].X, P[0].Y, P[1].X, P[1].Y, P[2].X, P[2].Y, P[3].X, P[3].Y, P[4].X, P[4].Y, P[5].X, P[5].Y],
    FFormatSettings
  ));
end;

procedure TEpsBarcodeDrawer.DrawRing(x, y, rOuter, rInner: Double); 
var
  cR, cG, cB: Double;
begin
  if FStoredColor <> FBarColor then
  begin
    EpsColor(FBarColor, cR,cG,cB);
    FList.Add(Format('%.2f %.2f %.2f setrgbcolor', [cR, cG, cB], FFormatSettings));
    FStoredColor := FBarColor;
  end;
  
  FList.Add(Format(
    '%.2f setlinewidth %.2f %.2f %.2f 0 360 arc closepath', 
    [abs(rOuter-rInner), x, y, (rOuter + rInner) / 2],
    FFormatSettings
  ));
end;

procedure TEpsBarcodeDrawer.EpsColor(AColor: TColor; out cR,cG,cB: Double);
type
  TRgb = packed record
    R, G, B: Byte;
  end;
var
  rgb: TRgb absolute AColor;
begin
  cR := rgb.R / 255;
  cG := rgb.G / 255;
  cB := rgb.B / 255;
end;

end.
