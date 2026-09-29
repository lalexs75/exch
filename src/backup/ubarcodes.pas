unit ubarcodes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, LResources, Graphics, Types,
  zint, udrawers;

type 

  TBarcodeType = (
  // TBarcodeC11
    bctCode11,
  // TBarcode128
    bctCode128, bctEAN128,   
  // TBarcode2of5
    bctCode25DataLogic, bctCode25IATA, bctCode25Industrial, 
    bctCode25Interleaved, bctCode25Standard, bctITF14,
  // TBarcode3of9
    bctCode39, bctCode39Ext, bctLOGMARS, bctCode93,
  // TBarcodeEAN
    bctEAN, bctEAN14, bctISBN, bctNVE18, bctUPCA, bctUPCE,
  // TBarcodeChannelCode
    bctChannelCode,
  // TBarcodePlessey
    bctPlessey, bctMSIPlessey,
  // TBarcodeTelePen
    bctTelepen, bctTelepenNum,
  // TBarcodeMedical
    bctCodaBar, bctCode32, bctPharmaOne, bctPharmaTwo, bctPZN7, bctPZN8,
  // TBarcodePostal
    bctAustraliaPostCustomer, bctAustraliaPostReplyPaid, bctAustraliaPostRoute,
    bctAustraliaPostRedirect, bctDaft, 
    bctDeutschePostIdentCode, bctDeutschePostLeitCode, 
    bctFIM, bctJapanPost, bctKix, bctKoreaPost, bctPlanet, bctPostNet, bctRM4SCC,
    
  // TBarcodePDF417
    bctPDF417, bctPDF417trunc, bctMicroPDF417,
    
  // TBarcodeQR
    bctQR,
  // TBarcodeMicroQR
    bctMicroQR,
  // TBarcodeAztec
    bctAztec,
  // TBarcodeAztecRune
    bctAztecRune,
  // TBarcodeDataMatrix
    bctDataMatrix,
    
  // TBarcodeMaxicode
    bctMaxicode
  );
  TBarcodeTypes = set of TBarcodeType;
  
  TBarcodeBearerBarMode = (bbmNone, bbmBearerBars, bbmBox);

  { TLazBarcodeCustomBase }

  TLazBarcodeCustomBase=class(TGraphicControl)
  private
    FSymbol: PZintSymbol;
    //FQR: PointerTo_zint_symbol;  // deprecated, use FSymbol instead
    FBackgroundColor: TColor;
    FBearerBarMode: TBarcodeBearerBarMode;
    FForegroundColor: TColor;
    FLastErrorString: String;
    FMargin: Integer;
    FRecommendedSymbolSize: Boolean;
    FScale: Integer;
    FSymbolHeight: Integer;
    FMinSymbolHeight: Integer;
    FWhitespaceWidth: Integer;
    procedure SetBackgroundColor(const AValue: TColor);
    procedure SetBearerBarMode(const AValue: TBarcodeBearerBarMode);
    procedure SetForegroundColor(const AValue: TColor);
    procedure SetMargin(const AValue: Integer);
    procedure SetMinSymbolHeight(const AValue: Integer);
    procedure SetRecommendedSymbolSize(const AValue: Boolean);
    procedure SetScale(const AValue: Integer);
    procedure SetWhitespaceWidth(const AValue: Integer);
    procedure SetSymbolHeight(const AValue: Integer);
  protected
    FIsPainting: Integer;
    procedure DoOnResize; override;
    procedure GenerateAndInvalidate;
    class function GetControlClassDefaultSize: TSize; override;
    procedure InitSymbol(ASymbology: Integer); virtual;
    procedure IntfPaintOnCanvas(const aTargetCanvas: TCanvas; const aRect: TRect); virtual;
    procedure Paint; override;
    procedure SetRecommendedSymbolSizeParams; virtual;
    procedure UpdateAutoSize;
    property BackgroundColor: TColor read FBackgroundColor write SetBackgroundColor default clWhite;
    property BearerBarMode: TBarcodeBearerBarMode read FBearerBarMode write SetBearerBarMode default bbmNone;
    property ForegroundColor: TColor read FForegroundColor write SetForegroundColor default clBlack;
    property Margin: Integer read FMargin write SetMargin default 4;
    property MinSymbolHeight: Integer read FMinSymbolHeight write SetMinSymbolHeight default 0;
    property RecommendedSymbolSize: Boolean read FRecommendedSymbolSize write SetRecommendedSymbolSize default true;
    property Scale: Integer read FScale write SetScale default 0;
    property WhitespaceWidth: Integer read FWhitespaceWidth write SetWhitespaceWidth default 4;
    property SymbolHeight: Integer read FSymbolHeight write SetSymbolHeight default 0;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CopyToClipboard;
    procedure Generate; virtual; abstract;
    procedure PaintOnCanvas(const aTargetCanvas: TCanvas; const aRect: TRect); virtual;
    procedure SaveSymbolToFile(const AFileName, OnStr, OffStr: String);
    procedure SaveToEpsFile(const AFileName: String);
    procedure SaveToEpsStream(const {%H-}AStream: TStream); virtual;
    procedure SaveToFile(const AFileName: String; AImageClass: TFPImageBitmapClass = nil;
      AWidth: Integer = -1; AHeight: Integer = -1);
    procedure SaveToStream(const AStream: TStream; AImageClass: TFPImageBitmapClass = nil;
      AWidth: Integer = -1; AHeight: Integer = -1); virtual;
    procedure SaveToSvgFile(const AFileName: String); 
    procedure SaveToSvgStream(const AStream: TStream); virtual;
    property ErrorString: String read FLastErrorString;
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Color default clWhite;
    property Constraints;
    property ParentColor;
    property OnPaint;
    property OnResize;
    property OnShowHint;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnStartDock;
    property OnStartDrag;
  end;
  
  { TLazBarcodeCustomText }
  
  TLazBarcodeCustomText=class(TLazBarcodeCustomBase)
  private
    FShowHumanReadableText: Boolean;
    procedure SetShowHumanReadableText(const AValue: Boolean);
    procedure SetText(const AValue: TCaption);
  protected
    FText: TCaption;
    function GetSampleText: String; virtual;
    property ShowHumanReadableText: Boolean read FShowHumanReadableText write SetShowHumanReadableText default true;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SampleText;
  published
    property Text: TCaption read FText write SetText;
  end;
  
  
  { TCustomLazBarcode }
  
  TCustomBarcode = class(TLazBarcodeCustomText)
  protected
    FBarcodeType: TBarcodeType;
    FErrorCode: Integer;
    FValidBarcodeTypes: TBarcodeTypes;
    procedure FontChanged(Sender: TObject); override;
    procedure InitSymbol(ASymbology: Integer); override;
    function InternalGenerate: Integer; virtual; 
    procedure IntfPaintOnCanvas(const aTargetCanvas: TCanvas; const aRect: TRect); override;  
    procedure SetBarcodeType(const AValue: TBarcodeType);
  protected
    property BarcodeType: TBarcodeType read FBarcodeType write SetBarcodeType;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Generate; override;
  published
    property BackgroundColor;
    property ForegroundColor;
    property Margin;
    property ParentColor;
    property Scale;
    property Font;
    property ParentFont;
  end;
    
  
  { TSimpleBarcode 
  
    These bar codes types implement their own drawing procedure which is simpler
    and more flexible than the complex Zint routine. }

  TSimpleBarcode = class(TCustomBarcode)
  private
    FAddCheckSum: Boolean;
    FDisplayCheckSum: Boolean;
    procedure SetAddCheckSum(const AValue: Boolean);
    procedure SetDisplayCheckSum(const AValue: Boolean);    
  protected   
    function CalcFactor(AWidth, {%H-}AHeight: Integer): Integer; virtual;
    procedure CalcSize(AFactor: Integer; out ATotalWidth, ATotalHeight,
      ASymbolWidth, ASymbolHeight, ATextWidth, ATextHeight, 
      ABorderWidth, AWhitespaceWidth: Integer); virtual;
    function CalcSymbolStart(ABorderWidth, AWhiteSpaceWidth: Integer): Integer; virtual;
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer;
      WithThemeSpace: Boolean); override;
    procedure DrawBarcode(ADrawer: TBasicBarcodeDrawer; AFactor: Double); virtual;
    function GetLastLine: PZintRenderLine;
    procedure GetTextSize(const AText: String; out AWidth, AHeight: Integer); 
    function InternalGenerate: Integer; override;
    procedure IntfPaintOnCanvas(const aTargetCanvas: TCanvas; const aRect: TRect); override;
    procedure Paint; override;
    procedure Render(AWidth, AHeight: Integer); virtual;
    procedure RenderBearerBars(AWidth, AHeight, ABorder: Integer; var ALastLine: PZintRenderline);
    procedure RenderBox(AWidth, AHeight, ABorder: Integer; var ALastLine: PZintRenderLine);
    procedure RenderSymbol(xLeft, yTop, {%H-}ASymbolWidth, ASymbolHeight, {%H-}ATextHeight, AFactor: Integer); virtual; 
    procedure RenderText(ASymbolWidth, ASymbolStart, ATextPos: Integer); virtual;
    property AddCheckSum: Boolean read FAddCheckSum write SetAddCheckSum default true;
    property DisplayCheckSum: Boolean read FDisplayCheckSum write SetDisplayCheckSum default false;
  public
    constructor Create(AOwner: TComponent); override;
    procedure PaintOnCanvas(const ACanvas: TCanvas; const ARect: TRect); override;

    procedure SaveToEpsStream(const AStream: TStream); override;
    procedure SaveToStream(const AStream: TStream; AImageClass: TFPImageBitmapClass = nil;
      AWidth: Integer = -1; AHeight: Integer = -1); override;
    procedure SaveToSvgStream(const AStream: TStream); override;
  published
    property AutoSize;
    property RecommendedSymbolSize;
  end;
    
  
  { TBarcodeC11 }
  
  TBarcodeC11 = class(TSimpleBarcode)
  protected
    class function GetControlClassDefaultSize: TSize; override;
    function GetSampleText: String; override;
    function InternalGenerate: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property AddChecksum;
    property BearerBarMode;
    property DisplayChecksum;
    property ShowHumanReadableText;
    property SymbolHeight;
    property WhiteSpaceWidth;
  end;
  
  
  { TBarcodeC128 }
  
  TBarcodeTypeC128 = bctCode128..bctEAN128;
  
  TBarcodeC128 = class(TSimpleBarcode)
  private
    function GetBarcodeType: TBarcodeTypeC128;
    procedure SetBarcodeType(const AValue: TBarcodeTypeC128);
  protected
    class function GetControlClassDefaultSize: TSize; override;
    function GetSampleText: String; override;
    function InternalGenerate: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BarcodeType: TBarcodeTypeC128
      read GetBarcodeType write SetBarcodeType default bctCode128;
    property ShowHumanReadableText;
    property SymbolHeight;
    property WhiteSpaceWidth;
  end;
  
  
  { TBarcode2of5 }
  
  TBarcodeType2of5 = bctCode25DataLogic..bctITF14;

  TBarcode2of5 = class(TSimpleBarcode)
  private
    function GetBarcodeType: TBarcodeType2of5;
    procedure SetBarcodeType(const AValue: TBarcodeType2of5);
  protected
    class function GetControlClassDefaultSize: TSize; override;
    function GetSampleText: String; override;
    function InternalGenerate: Integer; override;
    procedure SetRecommendedSymbolSizeParams; override;
  public
    constructor Create(AOwner: TComponent); override;  
  published
    property BarcodeType: TBarcodeType2of5 
      read GetBarcodeType write SetBarcodeType default bctCode25DataLogic;
    property AddChecksum;
    property BearerBarMode;
    property DisplayChecksum;
    property ShowHumanReadableText;
    property SymbolHeight;
    property WhiteSpaceWidth;
  end;
    
  
  { TBarcode3of9 }
  
  TBarcodeType3of9 = bctCode39..bctCode93;
  
  TBarcode3of9 = class(TSimpleBarcode)
  private
    function GetBarcodeType: TBarcodeType3of9;
    procedure SetBarcodeType(const AValue: TBarcodeType3of9);
  protected
    class function GetControlClassDefaultSize: TSize; override;
    function GetSampleText: String; override;
    function InternalGenerate: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BarcodeType: TBarcodeType3of9 
      read GetBarcodeType write SetBarcodeType default bctCode39;
    property AddChecksum;
    property BearerBarMode;
    property DisplayChecksum;
    property ShowHumanReadableText;
    property SymbolHeight;
    property WhiteSpaceWidth;
  end;
  
  
  { TBarcodeEAN }
  
  TBarcodeTypeEAN = bctEAN..bctUPCE;
  
  TBarcodeEAN = class(TSimpleBarcode)  //CustomBarcode)
  private
    const
      SPACER = '00';
    function GetBarcodeType: TBarcodeTypeEAN;
    procedure SetBarcodeType(const AValue: TBarcodeTypeEAN);
  protected
    procedure CalcSize(AFactor: Integer; out ATotalWidth, ATotalHeight, 
      ASymbolWidth, ASymbolHeight, ATextWidth, ATextHeight, 
      ABorderWidth, AWhitespaceWidth: Integer); override;
    function CalcSymbolStart(ABorderWidth, AWhiteSpaceWidth: Integer): integer; override;
    function GetAddOnText: String;
    class function GetControlClassDefaultSize: TSize; override;
    function GetLeftText: String;
    function GetRightText: String;
    function GetSampleText: String; override;
    function InternalGenerate: Integer; override;
    procedure RenderSymbol(xLeft, yTop, ASymbolWidth, ASymbolHeight, ATextHeight, AFactor: Integer); override; 
    procedure RenderText(ASymbolWidth, ASymbolStart, ATextPos: Integer); override;
    procedure SetRecommendedSymbolSizeParams; override;
    function UPC_EAN_Flag: Integer;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BarcodeType: TBarcodeTypeEAN read GetBarcodeType write SetBarcodeType default bctEAN;
    property ShowHumanReadableText;
    property SymbolHeight;
    property WhiteSpaceWidth;
  end;
   
  
  { TBarcodeChannelCode }
  
  TBarcodeChannelCode = class(TSimpleBarcode)  //CustomBarcode)
  private
    FChannelCount: integer;  // only 0, 3..8 
    procedure SetChannelCount(const AValue: Integer);
  protected
    class function GetControlClassDefaultSize: TSize; override;
    function GetSampleText: String; override;
    function InternalGenerate: Integer; override;
    procedure SetRecommendedSymbolSizeParams; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ChannelCount: Integer read FChannelCount write SetChannelCount default 0;
    property ShowHumanReadableText;
    property SymbolHeight;
    property WhiteSpaceWidth;
  end;
  
  { TBarcodePlessey }
  
  TBarcodeTypePlessey = bctPlessey..bctMSIPlessey;
  TPlesseyCheckChar = (pcOneMod10, pcTwoMod10, pcOneMod11, pcOneMod10Mod11);
  
  TBarcodePlessey = class(TSimpleBarcode)
  private
    FCheckChar: TPlesseyCheckChar;
    function GetBarcodeType: TBarcodeTypePlessey;
    procedure SetBarcodeType(const AValue: TBarcodeTypePlessey);
    procedure SetCheckChar(const AValue: TPlesseyCheckChar);
  protected
    class function GetControlClassDefaultSize: TSize; override;
    function GetSampleText: String; override;
    function InternalGenerate: Integer; override;
    procedure SetRecommendedSymbolSizeParams; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BarcodeType: TBarcodeTypePlessey read GetBarcodeType write SetBarcodeType default bctPlessey;
    property CheckChar: TPlesseyCheckChar read FCheckChar write SetCheckChar default pcOneMod10;
    property AddChecksum;
    property DisplayChecksum;
    property ShowHumanReadableText;
    property SymbolHeight;
    property WhiteSpaceWidth;
  end;
  
  
  { TBarcodeTelepen }
  
  TBarcodeTypeTelepen = bctTelepen..bctTelepenNum;
  
  TBarcodeTelepen = class(TSimpleBarcode)  //CustomBarcode)
  private
    function GetBarcodeType: TBarcodeTypeTelepen;
    procedure SetBarcodeType(const AValue: TBarcodeTypeTelepen);
  protected
    class function GetControlClassDefaultSize: TSize; override;
    function GetSampleText: String; override;
    function InternalGenerate: Integer; override;
    procedure SetRecommendedSymbolSizeParams; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BarcodeType: TBarcodeTypeTelepen read GetBarcodeType write SetBarcodeType default bctTelepen;
    property ShowHumanReadableText;
    property SymbolHeight;
    property WhiteSpaceWidth;
  end;
  
  
  { TBarcodeMedical }
  
  TBarcodeTypeMedical = bctCodaBar..bctPZN8;
  
  TBarcodeMedical = class(TSimpleBarcode)  
  private
    function GetBarcodeType: TBarcodeTypeMedical;
    procedure SetBarcodeType(const AValue: TBarcodeTypeMedical);
  protected
    class function GetControlClassDefaultSize: TSize; override;
    function GetSampleText: String; override;
    function InternalGenerate: Integer; override;
    procedure SetRecommendedSymbolSizeParams; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BarcodeType: TBarcodeTypeMedical read GetBarcodeType write SetBarcodeType default bctCodaBar;
    property ShowHumanReadableText;
    property SymbolHeight;
    property WhiteSpaceWidth;
  end;
  
  
  { TBarcodePostal }
  
  TBarcodeTypePostal = bctAustraliaPostCustomer..bctRM4SCC;
  
  TBarcodePostal = class(TSimpleBarcode)
  private
    FGrouped: Boolean;
    function GetBarcodeType: TBarcodeTypePostal;
    procedure SetBarcodeType(const AValue: TBarcodeTypePostal);
    procedure SetGrouped(const AValue: Boolean);
  protected
    class function GetControlClassDefaultSize: TSize; override;
    function GetSampleText: String; override;
    function InternalGenerate: Integer; override;
    procedure SetRecommendedSymbolSizeParams; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BarcodeType: TBarcodeTypePostal read GetBarcodeType write SetBarcodeType default bctPostNet;
    property Grouped: Boolean read FGrouped write SetGrouped default true;
    property ShowHumanReadableText;
    property SymbolHeight;
    property WhiteSpaceWidth;
  end;
    
  
  { TBarcodePDF417 }
  
  TBarcodeTypePDF417 = bctPDF417..bctMicroPDF417;
  TPDF417CheckDigitCount = -1..8;
  TPDF417Cols = 0..30;

  TBarcodePDF417 = class(TSimpleBarcode)
  private
    FCols: TPdf417Cols;
    FCheckDigitCount: TPDF417CheckDigitCount;
    function GetBarcodeType: TBarcodeTypePDF417;
    function GetRowHeightRatio: Integer;
    procedure SetBarcodeType(const AValue: TBarcodeTypePDF417);
    procedure SetCheckDigitCount(const AValue: TPDF417CheckDigitCount);
    procedure SetCols(const AValue: TPDF417Cols);
    procedure SetRowHeightRatio(const AValue: Integer);
  protected
    procedure CalcSize(AFactor: Integer; out ATotalWidth, ATotalHeight,
      ASymbolWidth, ASymbolHeight, ATextWidth, ATextHeight, 
      ABorderWidth, AWhitespaceWidth: Integer); override;
    function CalcSymbolStart(ABorderWidth, {%H-}AWhiteSpaceWidth: integer): Integer; override;
    class function GetControlClassDefaultSize: TSize; override;
    {
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer;
      WithThemeSpace: Boolean); override;    
    }
    function InternalGenerate: Integer; override;
    procedure InitSymbol(ASymbology: Integer); override;
    procedure SetRecommendedSymbolSizeParams; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BarcodeType: TBarcodeTypePDF417 read GetBarcodeType write SetBarcodeType default bctPDF417;
    property CheckDigitCount: TPDF417CheckDigitCount read FCheckDigitCount write SetCheckDigitCount default -1;
    property Columns: TPdf417Cols read FCols write SetCols default 0;
    property RowHeightRatio: Integer read GetRowHeightRatio write SetRowHeightRatio default 3;
  end;
    
  
  { TBarcodeSquare }
    
  TBarcodeSquare = class(TSimpleBarcode)
  protected
    function CalcFactor(AWidth, AHeight: Integer): Integer; override;
    procedure CalcSize(AFactor: Integer; out ATotalWidth, ATotalHeight,
      ASymbolWidth, ASymbolHeight, ATextWidth, ATextHeight, 
      ABorderWidth, AWhitespaceWidth: Integer); override;
    function CalcSymbolStart(ABorderWidth, {%H-}AWhiteSpaceWidth: integer): Integer; override;
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer;
      WithThemeSpace: Boolean); override;
    class function GetControlClassDefaultSize: TSize; override;
    procedure SetRecommendedSymbolSizeParams; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;
    
  
  { TBarcodeQR }
  
  TBarcodeQR_ECCLevel= (eBarcodeQR_ECCLevel_Auto=0,
                        eBarcodeQR_ECCLevel_L=1,eBarcodeQR_ECCLevel_M=2,
                        eBarcodeQR_ECCLevel_Q=3,eBarcodeQR_ECCLevel_H=4);

  TBarcodeQR = class(TBarcodeSquare) 
  private
    procedure SetECCLevel(const AValue: TBarcodeQR_ECCLevel);
  protected
    FECCLevel: TBarcodeQR_ECCLevel;
    procedure UpdateECCLevel;
    function InternalGenerate: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ECCLevel: TBarcodeQR_ECCLevel read FECCLevel write SetECCLevel default eBarcodeQR_ECCLevel_Auto;
  end;

  
  { TBarcodeMicroQR }
  
  TBarcodeMicroQR = class(TBarcodeQR)
  protected
    function InternalGenerate: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

    
  { TBarcodeAztec }
  
  TBarcodeAztec = class(TBarcodeSquare) 
  protected
    function InternalGenerate: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;
  
    
  { TBarcodeAztecRune }
  
  TBarcodeAztecRune_Value= 0..999;

  TBarcodeAztecRune = class(TBarcodeSquare)
  private
    function GetValue: TBarcodeAztecRune_Value;
    procedure SetValue(const AValue: TBarcodeAztecRune_Value);
  protected
    FValue: TBarcodeAztecRune_Value;
    function GetSampleText: String; override;
    function InternalGenerate: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Value: TBarcodeAztecRune_Value read GetValue write SetValue;
  end;
  
    
  { TBarcodeDataMatrix }
  
  TBarcodeDataMatrix = class(TBarcodeSquare)  
  protected
    function InternalGenerate: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;


  { TBarcodeMaxiCode }
  TBarcodeMaxicodeMode = (mcmAuto, mcmMode2, mcmMode3, mcmMode4, mcmMode5, mcmMode6);
  
  TBarcodeMaxiCode = class(TSimpleBarcode)
  private
    FMode: TBarcodeMaxicodeMode;
    FPostcode: String;
    FPrimary: String;
    FCountryCode: Integer;
    FServiceCode: Integer;
    procedure SetCountryCode(AValue: Integer);
    procedure SetMode(AValue: TBarcodeMaxicodeMode);
    procedure SetPostCode(AValue: String);
    procedure SetPrimary(AValue: String);
    procedure SetServiceCode(AValue: Integer);
  protected
    function BuildPrimary: String;
    function CalcFactor(AWidth, AHeight: Integer): Integer; override;
    procedure CalcSize(AFactor: Integer;
      out ATotalWidth, ATotalHeight, ASymbolWidth, ASymbolHeight, 
      ATextWidth, ATextHeight, ABorderWidth, AWhitespaceWidth: Integer); override;
    function CalcSymbolStart(ABorderWidth, {%H-}AWhiteSpaceWidth: Integer): Integer; override;
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer;
      WithThemeSpace: Boolean); override;
    procedure DrawBarcode(ADrawer: TBasicBarcodeDrawer; AFactor: Double); override;
    class function GetControlClassDefaultSize: TSize; override;
    function InternalGenerate: Integer; override;
    procedure RenderSymbol(xLeft, yTop, ASymbolWidth, ASymbolHeight, {%H-}ATextHeight, AFactor: Integer); override; 
    procedure SetRecommendedSymbolSizeParams; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Mode: TBarcodeMaxicodeMode read FMode write SetMode default mcmAuto;
    property Primary: String read FPrimary write SetPrimary;
    property Postcode: String read FPostCode write SetPostcode;
    property CountryCode: Integer read FCountryCode write SetCountryCode default 0;
    property ServiceCode: Integer read FServiceCode write SetServiceCode default 0;
  end;


procedure Register;

implementation

{$R lazbarcodes_icons.res}

uses
  lconvencoding, clipbrd, propedits,
  lbc_basic, lbc_helper, lbc_render, lbc_svg, 
  lbc_code, lbc_code128, lbc_2of5, lbc_upcean, lbc_plessey, lbc_telepen, 
  lbc_medical, lbc_postal, lbc_auspost, 
  lbc_pdf417, lbc_datamatrix, lbc_qr, lbc_aztec, lbc_maxicode;

procedure Register;
begin
  RegisterComponents('Laz Barcodes', [
    // 1D barcodes
    TBarcodeC11, TBarcodeC128, TBarcode2of5, TBarcode3of9, TBarcodeEAN,
    TBarcodeChannelCode, TBarcodePlessey, TBarcodeTelepen, 
    TBarcodeMedical, TBarcodePostal,
    
    // 2D barcodes
    TBarcodeQR, TBarcodeMicroQR, 
    TBarcodeAztec, TBarcodeAztecRune,
    TBarcodeDataMatrix,
    TBarcodePDF417,
    TBarcodeMaxicode
  ]);
  
  RegisterPropertyEditor(TypeInfo(TCaption), TLazBarcodeCustomText, 'Text', TCaptionPropertyEditor);
  RegisterPropertyToSkip(TLazBarcodeCustomBase, 'StrictSize', 'Deprecated', '');
end;

function ColorToChars(AColor: TColor): TColorChars;
type
  TRGBA = packed record 
    r, g, b, a: byte; 
  end;
var
  s: String;
  c: TRGBA;
  i: Integer;
begin
  c := TRGBA(ColorToRGB(AColor));
  s := Format('%.2x%.2x%.2x', [c.R, c.G, c.B]);
  Result := Default(TColorChars);
  for i := 1 to Length(s) do
    Result[i-1] := s[i];
end;

function InchToMillimeters(AValue: Double): Double;
begin
  Result := AValue * 25.4;
end;

function InchToPixels(AValue: Double): Integer;
begin
  Result := round(AValue * ScreenInfo.PixelsPerInchX);
end;

function MillimetersToInch(AValue: Double): Double;
begin
  Result := AValue / 25.4;
end;

function MillimetersToPixels(AValue: Double): Integer;
begin
  Result := round(MillimetersToInch(AValue) * ScreenInfo.PixelsPerInchX);
end;

function GetSymbology(ABarcodeType: TBarcodeType): Integer;
begin
  case ABarcodeType of
    bctCode11: 
      Result := BARCODE_CODE11;
    bctCode128: 
      Result := BARCODE_CODE128;
    bctEAN128:
      Result := BARCODE_EAN128;
    bctCode25DataLogic: 
      Result := BARCODE_C25LOGIC;
    bctCode25IATA: 
      Result := BARCODE_C25IATA;
    bctCode25Industrial: 
      Result := BARCODE_C25IND;
    bctCode25Interleaved: 
      Result := BARCODE_C25INTER;
    bctCode25Standard: 
      Result := BARCODE_C25MATRIX;
    bctITF14: 
      Result := BARCODE_ITF14;
    bctCode39:
      Result := BARCODE_CODE39;
    bctCode39Ext: 
      Result := BARCODE_EXCODE39;
    bctLOGMARS:
      Result := BARCODE_LOGMARS;
    bctCode93:
      Result := BARCODE_CODE93;
    bctEAN:
      Result := BARCODE_EANX;
    bctEAN14:
      Result := BARCODE_EAN14;
    bctISBN:
      Result := BARCODE_ISBNX;
    bctNVE18:
      Result := BARCODE_NVE18;
    bctUPCA:
      Result := BARCODE_UPCA;
    bctUPCE:
      Result := BARCODE_UPCE;
    bctChannelCode:
      Result := BARCODE_CHANNEL;
    bctPlessey: 
      Result := BARCODE_PLESSEY;
    bctMSIPlessey: 
      Result := BARCODE_MSI_PLESSEY;
    bctTelepen: 
      Result := BARCODE_TELEPEN;
    bctTelepenNum: 
      Result := BARCODE_TELEPEN_NUM;
    bctCodaBar: 
      Result := BARCODE_CODABAR;
    bctCode32: 
      Result := BARCODE_CODE32;
    bctPharmaOne:
      Result := BARCODE_PHARMA;
    bctPharmaTwo:
      Result := BARCODE_PHARMA_TWO;
    bctPZN7:
      Result := BARCODE_PZN;
    bctPZN8: 
      Result := BARCODE_PZN;
    bctAustraliaPostCustomer:
      Result := BARCODE_AUSPOST;
    bctAustraliaPostReplyPaid:
      Result := BARCODE_AUSREPLY;
    bctAustraliaPostRoute:
      Result := BARCODE_AUSROUTE;
    bctAustraliaPostRedirect:
      Result := BARCODE_AUSREDIRECT;
    bctDaft:
      Result := BARCODE_DAFT;
    bctDeutschePostIdentCode:
      Result := BARCODE_DPIDENT;
    bctDeutschePostLeitCode:
      Result := BARCODE_DPLEIT;
    bctFIM:
      Result := BARCODE_FIM;
    bctJapanPost:
      Result := BARCODE_JAPANPOST;
    bctKIX:
      Result := BARCODE_KIX;
    bctKoreaPost:
      Result := BARCODE_KOREAPOST;
    bctPlanet:
      Result := BARCODE_PLANET;
    bctPostNet:
      Result := BARCODE_POSTNET;
    bctRM4SCC:
      Result := BARCODE_RM4SCC;
    bctPDF417: 
      Result := BARCODE_PDF417;
    bctPDF417Trunc: 
      Result := BARCODE_PDF417TRUNC;
    bctMicroPDF417: 
      Result := BARCODE_MICROPDF417;
    bctQR:
      Result := BARCODE_QRCODE;
    bctMicroQR:
      Result := BARCODE_MICROQR;
    bctAztec:
      Result := BARCODE_AZTEC;
    bctAztecRune:
      Result := BARCODE_AZRUNE;
    bctDataMatrix:
      Result := BARCODE_DATAMATRIX;
    bctMaxiCode:
      Result := BARCODE_MAXICODE;
    else
      Result := -1
  end;
end;

{ TLazBarcodeCustomBase }

constructor TLazBarcodeCustomBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  with GetControlClassDefaultSize do
    SetInitialBounds(0, 0, CX, CY);
  
  Color := clWhite;
  FBackgroundColor := clWhite;
  FMargin := 4;
  FForegroundColor := clBlack;
//  FStrictSize := true;
  FWhiteSpaceWidth := 4;
  
  SetRecommendedSymbolSize(true);
end;

destructor TLazBarcodeCustomBase.Destroy;
begin
  if Assigned(FSymbol) then begin
    ZBarcode_Delete(FSymbol);
    FSymbol := nil;
  end;
  inherited Destroy;
end;

procedure TLazBarcodeCustomBase.CopyToClipboard;
var
  stream: TStream;
begin
  stream := TMemoryStream.Create;
  try
    SaveToStream(stream);
    stream.Position := 0;
    Clipboard.AddFormat(CF_BITMAP, stream);
  finally
    stream.Free;
  end;
end;

procedure TLazBarcodeCustomBase.DoOnResize;
begin
  inherited; 
//  if (FScale = 0) or (FSymbolheight = 0) then     // no display at designtime with this
    Generate;
end;

procedure TLazBarcodeCustomBase.GenerateAndInvalidate;
begin
  FLastErrorString := '';
  Generate;
  Self.Invalidate;
end;

class function TLazBarcodeCustomBase.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 200;
  Result.CY := 80;
end;

function GetTextHeight(AFont: TFont): Integer;
var
  bmp: TBitmap;
begin
  bmp := TBitmap.Create;
  try
    bmp.SetSize(10, 10);
    bmp.Canvas.Font.Assign(AFont);
    Result := bmp.Canvas.TextHeight('Tg');
  finally
    bmp.Free;
  end;
end;

procedure TLazBarcodeCustomBase.InitSymbol(ASymbology: Integer);
begin
  if ASymbology = -1 then
    exit;
  
  with FSymbol^ do
  begin
    symbology := ASymbology;
    border_width := FMargin;
    font_height := GetTextHeight(Font);
    scale := FScale;
    option_1 := -1;
    option_2 := 0;
    option_3 := 928;
    case FBearerBarMode of
      bbmNone: 
        ;
      bbmBearerBars: 
        output_options := output_options or BARCODE_BIND;
      bbmBox: 
        output_options := output_options or BARCODE_BOX;
    end;
    fgColour := ColorToChars(FForegroundColor);
    bgColour := ColorToChars(FBackgroundColor);
    FillChar(encoded_data, SizeOf(encoded_data), 0);
  end;
end;

procedure TLazBarcodeCustomBase.IntfPaintOnCanvas(const aTargetCanvas: TCanvas;
  const aRect: TRect);
var
  ErrorCode: integer;
  Line: PointerTo_zint_render_line;
  BaseX,BaseY: integer;
  X,Y: integer;
  
  procedure ClearBackground;
  begin
    aTargetCanvas.Brush.Color:=FBackgroundColor;
    aTargetCanvas.FillRect(aRect);
  end;
  
begin
  if not aTargetCanvas.HandleAllocated then exit;
  if not Assigned(FSymbol) then begin
    ClearBackground;
    exit;
  end;
  if not Assigned(FSymbol^.rendered) then begin
    X := aRect.Right - aRect.Left + 1;
    Y := aRect.Bottom - aRect.Top + 1;
    {
    if FStrictSize then begin
      BaseX := FSymbol^.width + FSymbol^.border_width*2;
      BaseY := FSymbol^.rows + FSymbol^.border_width*2;
      ErrorCode := render_plot(FSymbol, X-(X mod BaseX), Y-(Y mod BaseY));
    end else   // not strict size: stretch over full width of control
    }
      ErrorCode := render_plot(FSymbol,X,Y);
    if ErrorCode<>1 then begin
      FLastErrorString := FSymbol^.errtxt;
      exit;
    end else begin
      FLastErrorString:='';
    end;
  end;
  
  if Assigned(FSymbol^.rendered) then begin
    baseX := round((aRect.Left + aRect.Right - FSymbol^.rendered^.exact_width) / 2);
    if baseX < aRect.Left then baseX := aRect.Left;
    baseY := aRect.Top;
    
    Line:=FSymbol^.rendered^.lines;
    ClearBackground;
    aTargetCanvas.Brush.Color:=FForegroundColor;
    while Assigned(Line) do begin
      aTargetCanvas.FillRect( 
        round(Line^.x)+baseX, //aRect.Left,
        round(Line^.y)+baseY, //aRect.Top,
        round(Line^.x+Line^.width)+baseX, //aRect.Left,
        round(Line^.y+Line^.length)+baseY  //aRect.Top
      );
      Line:=Line^.next;
    end;
  end;
end;

procedure TLazBarcodeCustomBase.Paint;
begin
  if FIsPainting = 0 then 
  begin
    inc(FIsPainting);
    try
      IntfPaintOnCanvas(Canvas, ClientRect);
    finally
      dec(FIsPainting);
    end;
  end;
end;

procedure TLazBarcodeCustomBase.PaintOnCanvas(const aTargetCanvas: TCanvas;
  const aRect: TRect);
begin
  //Destroy rendering
  Generate;
  //Create new rendering
  IntfPaintOnCanvas(aTargetCanvas,aRect);
  //Destroy rendering, new rendering generated when paint called.
  Generate;
end;

procedure TLazBarcodeCustomBase.SaveSymbolToFile(const AFileName, OnStr,OffStr: String);
var
  r, c: Integer;
  s: String;
  F: TextFile;
begin
  AssignFile(F, AFileName);
  Rewrite(F);
  for r := 0 to FSymbol^.rows-1 do
  begin
    s := '';
    for c := 0 to FSymbol^.width-1 do
      s := s + iif(module_is_set(FSymbol, r, c), OnStr, OffStr);
    WriteLn(F, s);
  end;
  CloseFile(F);
end;

procedure TLazBarcodeCustomBase.SaveToFile(const AFileName: String;
  AImageClass: TFPImageBitmapClass = nil;
  AWidth: Integer = -1; AHeight: Integer = -1);
var
  stream: TStream;
begin
  stream := TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(stream, AImageClass, AWidth, AHeight);
  finally
    stream.Free;
  end;
end;

procedure TLazBarcodeCustomBase.SaveToEpsFile(const AFileName: String);
var
  stream: TFileStream;
begin
  stream := TFileStream.Create(AFileName, fmCreate + fmShareDenyWrite);
  try
    SaveToEpsStream(stream);
  finally
    stream.Free;
  end;
end;

procedure TLazBarcodeCustomBase.SaveToEpsStream(const AStream: TStream);
begin
  // to be done (is overriden by TSimpleBarcode)
end;

procedure TLazBarcodeCustomBase.SaveToStream(const AStream: TStream;
  AImageClass: TFPImageBitmapClass = nil;
  AWidth: Integer = -1; AHeight: Integer = -1);
var
  bmp: TFPImageBitmap;
begin
  if AImageClass = nil then
    bmp := TBitmap.Create
  else
    bmp := AImageClass.Create;
  if AWidth = -1 then AWidth := Width;
  if AHeight = -1 then AHeight := Height;
  try
    bmp.SetSize(AWidth, AHeight);
    bmp.Canvas.Brush.Color := clWhite;
    bmp.Canvas.FillRect(0, 0, bmp.Width, bmp.Height);
    PaintOnCanvas(bmp.Canvas, Rect(0, 0, bmp.Width, bmp.Height));
    bmp.SaveToStream(AStream);
  finally
    bmp.Free;
  end;
end;

procedure TLazBarcodeCustomBase.SaveToSvgFile(const AFileName: String);
var
  stream: TFileStream;
begin
  stream := TFileStream.Create(AFileName, fmCreate + fmShareDenyWrite);
  try
    SaveToSvgStream(stream);
  finally
    stream.Free;
  end;
end;

procedure TLazBarcodeCustomBase.SaveToSvgStream(const AStream: TStream);
begin
  svg_plot(AStream, FSymbol);
end;

procedure TLazBarcodeCustomBase.SetBackgroundColor(const AValue: TColor);
begin
  if FBackgroundColor<>AValue then begin
    FBackgroundColor:=AValue;
    GenerateAndInvalidate;
  end;
end;

procedure TLazBarcodeCustomBase.SetBearerBarMode(const AValue: TBarcodeBearerBarMode);
begin
  if FBearerBarMode <> AValue then
  begin
    FBearerBarMode := AValue;
    FRecommendedSymbolSize := false;
    GenerateAndInvalidate;
  end;
end;

procedure TLazBarcodeCustomBase.SetForegroundColor(const AValue: TColor);
begin
  if FForegroundColor<>AValue then begin
    FForegroundColor:=AValue;
    GenerateAndInvalidate;
  end;
end;

procedure TLazBarcodeCustomBase.SetMargin(const AValue: Integer);
begin
  if FMargin <> AValue then
  begin
    FMargin := AValue;
    GenerateAndInvalidate;
  end;
end;

procedure TLazBarcodeCustomBase.SetMinSymbolHeight(const AValue: Integer);
begin
  if FMinSymbolHeight <> AValue then
  begin
    FMinSymbolHeight := AValue;
    GenerateAndInvalidate;
  end;
end;

procedure TLazBarcodeCustomBase.SetRecommendedSymbolSize(const AValue: Boolean);
begin
  //if FRecommendedSymbolSize = AValue then exit;  // this is harmful here.

  FRecommendedSymbolSize := AValue;
  if FRecommendedSymbolSize then
    SetRecommendedSymbolSizeParams;
  GenerateAndInvalidate;
end;

procedure TLazBarcodeCustomBase.SetRecommendedSymbolSizeParams;
begin
  FScale := 2;
  FSymbolHeight := 60;
end;

procedure TLazBarcodeCustomBase.SetScale(const AValue: Integer);
begin
  if FScale = AValue then exit;
  FScale := AValue;
  FRecommendedSymbolSize := false;
  GenerateAndInvalidate;
end;

procedure TLazBarcodeCustomBase.SetWhitespaceWidth(const AValue: Integer);
begin
  if FWhitespaceWidth <> AValue then
  begin
    FWhitespaceWidth := AValue;
    FRecommendedSymbolSize := false;
    GenerateAndInvalidate;
  end;
end;

procedure TLazBarcodeCustomBase.SetSymbolHeight(const AValue: Integer);
begin
  if FSymbolHeight <> AValue then
  begin
    FSymbolHeight := AValue;
    FRecommendedSymbolSize := false;
    GenerateAndInvalidate;
  end;
end;

procedure TLazBarcodeCustomBase.UpdateAutoSize;
begin
  InvalidatePreferredSize;
  AdjustSize;
end;


{ TLazBarcodeCustomText }

constructor TLazBarcodeCustomText.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FText := GetSampleText; 
  FShowHumanReadableText := true;
end;

function TLazBarcodeCustomText.GetSampleText: String;
begin
  Result := ClassName;
end;

procedure TLazBarcodeCustomText.SampleText;
begin
  SetText(GetSampleText);
end;

procedure TLazBarcodeCustomText.SetShowHumanReadableText(const AValue: Boolean);
begin
  if FShowHumanReadableText = AValue then exit;
  FShowHumanReadableText := AValue;
  GenerateAndInvalidate;
end;

procedure TLazBarcodeCustomText.SetText(const AValue: TCaption);
begin
  if FText <> AValue then begin
    if AValue = '' then
      FText := GetSampleText
    else
      FText := AValue;
    FLastErrorString := '';
    GenerateAndInvalidate;
  end;
end;


{ TCustomBarcode }

constructor TCustomBarcode.Create(AOwner: TComponent);
begin
  inherited;
end;

procedure TCustomBarcode.FontChanged(Sender: TObject);
begin
  GenerateAndInvalidate;
end;

procedure TCustomBarcode.Generate;
var
  len: Integer;
  sym: Integer;
begin
  if Assigned(FSymbol) then begin
    ZBarcode_Delete(FSymbol);
    FSymbol := nil;
  end;

  len := Length(FText);
  if len = 0 then
    exit;

  sym := GetSymbology(FBarcodeType);
  if (sym = -1) then
    raise Exception.Create('Barcode type not supported.');
  
  FSymbol := ZBarcode_Create();
  InitSymbol(sym);
  FErrorCode := InternalGenerate;
  if FErrorCode = 0 then
    UpdateAutoSize
  else
    FLastErrorString := FSymbol^.errtxt;
end; 
  
procedure TCustomBarcode.InitSymbol(ASymbology: Integer);
begin 
  inherited InitSymbol(ASymbology);
  FSymbol^.show_hrt := ord(FShowHumanReadableText);
end;

function TCustomBarcode.InternalGenerate: Integer;
begin
  Result := 0;
end;

procedure TCustomBarcode.IntfPaintOnCanvas(const aTargetCanvas: TCanvas; 
  const aRect: TRect); 
var
  str: PointerTo_zint_render_string;
  baseX, baseY, w, x, y: Integer;
begin
  inherited;

  if (FSymbol = nil) or (FSymbol^.rendered = nil) then
    exit;
  
  baseX := round((aRect.Left + aRect.Right - FSymbol^.rendered^.exact_width) / 2);
  baseY := aRect.Top; 

  // Draw the symbol's human-readable text, if requested.
  if FShowHumanReadableText then begin
    aTargetCanvas.Font.Assign(Font);
    if aTargetCanvas.Font.Size = 0 then
      aTargetcanvas.Font.Height := GetFontData(aTargetCanvas.Font.Handle).Height;
    aTargetCanvas.Font.Color := FForegroundColor;
    aTargetCanvas.Brush.Style := bsClear;
    str := FSymbol^.rendered^.strings;
    while Assigned(str) do begin
      w := aTargetCanvas.TextWidth(PChar(str^.Text));
      x := round(str^.x - w*0.5) + baseX;
      y := round(str^.y) + baseY;
      aTargetCanvas.TextOut(x, y, PChar(str^.text));
      str := str^.next;
    end;
  end;
end;

procedure TCustomBarcode.SetBarcodeType(const AValue: TBarcodeType);
begin
  if (FBarcodeType = AValue) or not (AValue in FValidBarcodeTypes) then
    exit;
  FBarcodeType := AValue;
  GenerateAndInvalidate;
end;


{ TSimpleBarcode }

constructor TSimpleBarcode.Create(AOwner: TComponent);
begin
  inherited;
  FAddCheckSum := true;
  FDisplayCheckSum := false;
  FText := GetSampleText;
end;

function TSimpleBarcode.CalcFactor(AWidth, AHeight: Integer): Integer;
var
  wtotal, htotal, wsymbol, hsymbol, wtext, htext, border, wwhite: Integer;
begin
  CalcSize(1, wtotal, htotal, wsymbol, hsymbol, wtext, htext, border, wwhite);
  Result := AWidth div wtotal;
  if Result = 0 then Result := 1;
end;

{ Calculates the dimensions of the barcode. 
  The scaling factor has been applied. }
procedure TSimpleBarcode.CalcSize(AFactor: Integer;
  out ATotalWidth, ATotalHeight, ASymbolWidth, ASymbolHeight, 
  ATextWidth, ATextHeight, ABorderWidth, AWhitespaceWidth: Integer);
begin
  // Calculate size of human-readable text and length of the bars
  if FShowHumanReadableText and (FSymbol^.GetText <> '') then
    GetTextSize(FSymbol^.GetText, ATextWidth, ATextHeight)
  else
  begin
    ATextWidth := 0;
    ATextHeight := 0;
  end;
    
  ASymbolWidth := FSymbol^.Width * AFactor;
  
  if FBearerBarMode <> bbmNone then
  begin
    ABorderWidth := FMargin * AFactor;
    AWhitespaceWidth := FWhitespaceWidth * AFactor;
  end else
  begin
    ABorderWidth := FMargin;
    AWhiteSpaceWidth := FWhiteSpaceWidth;
  end;
    
  ATotalWidth := ASymbolWidth + 2 * AWhiteSpaceWidth;
  if FBearerBarMode = bbmBox then
    inc(ATotalWidth, 2*ABorderWidth);
  
  if SymbolHeight = 0 then
  begin
    ATotalHeight := ClientHeight;
    ASymbolHeight := ATotalHeight - 2*ABorderWidth - ATextHeight;
    if ASymbolHeight < FMinSymbolHeight then begin
      ASymbolHeight := FMinSymbolHeight;
      ATotalHeight := ASymbolHeight + 2*ABorderWidth + ATextWidth;
    end;
  end else
  begin
    if SymbolHeight < FMinSymbolHeight then
      ASymbolHeight := FMinSymbolHeight
    else
      ASymbolHeight := SymbolHeight;
    ATotalHeight := ASymbolHeight + 2*ABorderWidth + ATextHeight;
  end;
end;
  
{ Calculates the x coordinate at which the first bar will begin. }
function TSimpleBarCode.CalcSymbolStart(ABorderWidth, AWhiteSpaceWidth: integer): Integer;
begin
  Result := AWhiteSpaceWidth;
  if FBearerBarMode = bbmBox then 
    inc(Result, ABorderWidth);
end;
 
procedure TSimpleBarcode.CalculatePreferredSize(
  var PreferredWidth, PreferredHeight: Integer;
  WithThemeSpace: Boolean); 
var
  wtot, htot, wsym, hsym, wtxt, htxt, wb, wws: Integer;
begin
  inherited;

  if (FScale <> 0) and (FSymbolHeight <> 0) and (FSymbol <> nil) then //and (not FShowCodeAsText or (FSymbol^.GetText <> '')) then
  begin
    CalcSize(FScale, wtot, htot, wsym, hsym, wtxt, htxt, wb, wws);
    PreferredWidth := wtot;
    PreferredHeight := htot;
  end;
end;

procedure TSimpleBarcode.DrawBarcode(ADrawer: TBasicBarcodeDrawer; AFactor: Double);
var
  line: PZintRenderLine;
  str: PZintRenderString;
  fd: TFontData;
begin
  // Prepare drawer
  if FBackgroundColor = clDefault then
    ADrawer.BackColor := GetDefaultColor(dctBrush)
  else
    ADrawer.BackColor := ColorToRGB(FBackgroundColor);
  
  if FForegroundColor = clDefault then
    ADrawer.BarColor := GetDefaultColor(dctFont)
  else
    ADrawer.BarColor := ColorToRGB(FForegroundColor);
  
  if Font.Color = clDefault then
    ADrawer.TextColor := GetDefaultColor(dctFont)
  else
    ADrawer.TextColor := ColorToRGB(Font.Color);

  ADrawer.FontName := Font.Name;
  ADrawer.FontSize := Font.Size;
  if (Font.Name = 'default') or (Font.Size = 0) then
  begin
    fd := GetFontData(Font.Reference.Handle);
    if Font.Name = 'default' then
      ADrawer.FontName := fd.Name;
    if Font.Size = 0 then
    begin
      ADrawer.FontSize := fd.Height * 72 div Font.PixelsPerInch;
      if ADrawer.FontSize < 0 then ADrawer.FontSize := -ADrawer.FontSize;
    end;
  end;
  ADrawer.FontStyle := Font.Style;
  
  // Start drawing, clear background 
  ADrawer.BeginDrawing;  

  // Draw the lines (bars, bearing bars, box)
  line := FSymbol^.Rendered^.lines;
  while Assigned(line) do begin
    ADrawer.DrawBar(
      AFactor * line^.x, 
      AFactor * line^.y, 
      AFactor * (line^.x + line^.width), 
      AFactor * (line^.y + line^.length)
    );
    line := line^.next;
  end;

  // Draw the text
  if FShowHumanReadableText then begin
    str := FSymbol^.Rendered^.strings;
    while Assigned(str) do begin
      ADrawer.DrawCenteredText(AFactor * str^.x, AFactor * str^.y, PChar(str^.Text));
      str := str^.next;
    end;
  end;

  // Finish drawing
  ADrawer.EndDrawing;
end;

function TSimpleBarcode.GetLastLine: PZintRenderline;
var
  next_line: PZintRenderline;
begin
  Result := nil;
  if (FSymbol <> nil) and (FSymbol^.rendered <> nil) then 
  begin
    Result := FSymbol^.rendered^.Lines;
    if Result <> nil then
    begin
      next_line := Result^.next;
      while next_line <> nil do
      begin
        Result := next_line;
        next_line := Result^.next;
      end;
    end;
  end;
end;

{ Measures size of the specified text in pixels using the current barcode font. }
procedure TSimpleBarCode.GetTextSize(const AText: String; out AWidth, AHeight: Integer);
var
  bmp: TBitmap;
  extent: TSize;
begin
  bmp := TBitmap.Create;
  try
    bmp.SetSize(1, 1);
    bmp.Canvas.Pixels[0, 0] := clWhite;  // get the handle
    bmp.Canvas.Font.Assign(Font);
    extent := bmp.Canvas.TextExtent(AText);
    AWidth := extent.CX;
    AHeight := extent.CY;
  finally
    bmp.Free;
  end;
end;

function TSimpleBarcode.InternalGenerate: Integer;
begin
  Result := inherited;
  
  // FAddCheckSum and FShowCheckSum set bits 1 and 2 of the Zint symbol's
  // option.
  FSymbol^.Option := 0;
  if FAddCheckSum then
  begin
    FSymbol^.Option := FSymbol^.Option or OPTION_ADD_CHECKSUM;
    if FDisplayCheckSum then
      FSymbol^.Option := FSymbol^.Option or OPTION_DISPLAY_CHECKSUM;
  end;
end;

{ Adaption of the inherited method to allow for simplified drawing of 
  simple single-row linear barcodes. }
procedure TSimpleBarcode.IntfPaintOnCanvas(const ATargetCanvas: TCanvas; 
  const ARect: TRect); 
var
  drawer: TCanvasBarcodeDrawer;
begin
  if FSymbol^.Rendered = nil then
    Render(ARect.Width, ARect.Height);
//    raise Exception.Create('Bar code must have been rendered before drawing.');
  
  drawer := TCanvasBarcodeDrawer.Create(ATargetCanvas, ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
  try
    DrawBarcode(drawer, 1.0);
  finally
    drawer.Free;
  end;
end;

{ Paints the barcode on the control's canvas. Draws to an intermediate bitmap
  first which is then centered on the control. }
procedure TSimpleBarcode.Paint;
var
  bmp: TBitmap;
  w, h: Integer;
  ts: TTextstyle;
begin
  if Color = clDefault then
    Canvas.Brush.Color := GetDefaultColor(dctBrush)
  else
    Canvas.Brush.Color := ColorToRGB(Color);
  Canvas.FillRect(0, 0, ClientWidth, ClientHeight);
  
  if (FSymbol = nil) or (FText = '') then
    exit;

  if FSymbol^.rendered = nil then
    Render(ClientWidth, ClientHeight);
   
  if (FErrorCode > 2) then
  begin
    ts := Canvas.TextStyle;
    ts.Alignment := taCenter;
    ts.Layout := tlCenter;
    ts.Wordbreak := true;
    ts.SingleLine := false;
    Canvas.Font.Assign(Font);
    Canvas.TextRect(ClientRect, 0, 0, 'Error: ' + LineEnding + ErrorString, ts);
    exit;
  end;
    
  w := round(FSymbol^.Rendered^.Exact_Width);
  h := round(FSymbol^.Rendered^.Exact_Height);
  
  bmp := TBitmap.Create;
  try
    bmp.SetSize(w, h);
    IntfPaintOnCanvas(bmp.Canvas, Rect(0, 0, w, h));
    Canvas.Draw((ClientWidth - w) div 2, (ClientHeight - h) div 2, bmp);
  finally
    bmp.Free;
  end;
end;

procedure TSimpleBarCode.PaintOnCanvas(const ACanvas: TCanvas; const ARect: TRect);
begin
  IntfPaintOnCanvas(ACanvas, ARect);
end;

{ Creates the bar code pattern. Stores it as "lines" and "strings" in the 
  "rendered" record of the TZintSymbol. }
procedure TSimpleBarcode.Render(AWidth, AHeight: Integer);
var
  wtotal: Integer;   // total width of the barcode, from left-mode to right-most feature
  htotal: Integer;   // total height of the barcode, incl. text and borders
  wsymbol: Integer;  // width from first and to last bar
  hsymbol: Integer;  // height of the barcode symbol, i.e. bars only.
  wtext: Integer;    // width of the human-readable text
  htext: Integer;    // height of the human-readable text
  border: Integer;   // width of the margin around symbol. Occupied by bearer bars.
  wwhite: Integer;   // width of the white space before and after the symbol, used for bearer bars or box
  factor: Integer;   // scaling factor for width
  x, y: Integer;
  rendered: PZintRender;  // Pointer to Zint rendering record. It collects the rendered results.
  lastLine: PZintRenderLine = nil;
begin
  if FSymbol^.rendered <> nil then
    exit;
  
  if FRecommendedSymbolSize then
    SetRecommendedSymbolSizeParams;
  
  // The rendered pattern will be stored in the Rendered record of the Zint symbol.
  GetMem(FSymbol^.rendered, SizeOf(zint_render));
  rendered := FSymbol^.rendered;
  rendered^.Lines := nil;
  rendered^.Strings := nil;
  rendered^.Rings := nil;
  rendered^.Hexagons := nil;

  // Calculate  size of barcode 
  if (FScale <= 0) then    // automatic sizing
    factor := CalcFactor(AWidth, AHeight)
  else
    factor := FScale;
  CalcSize(factor, wtotal, htotal, wsymbol, hsymbol, wText, hText, border, wwhite);
  
  // Set size of barcode and get x position of 1st bar.
  if wtext > wtotal then begin
    AWidth := wtext;
    AHeight := htotal;
    x := (wtext - wsymbol) div 2;
  end else
  begin
    AWidth := wtotal;
    AHeight := htotal;
    x := CalcSymbolStart(border, wwhite);
  end;
  
  // Render bars and spaces
  RenderSymbol(x, border, wsymbol, hsymbol, htext, factor);
             
  // Render the human-readable text
  if FShowHumanReadableText then
  begin
    y := htotal - htext;
    {
    if FShowBearerBars or FShowBox then
      dec(y, border);
      }
    RenderText(wsymbol, x, y);
  end;
  
  // Render the horizontal bearer bars
  lastline := GetLastLine;
  if FBearerBarMode <> bbmNone then
    RenderBearerBars(AWidth, hsymbol, border, lastline);
  
  // Draw box
  if FBearerBarMode = bbmBox then
    RenderBox(AWidth, hsymbol, border, lastline);

  // Store the symbol's rendered dimensions
  rendered^.exact_width := AWidth;
  rendered^.exact_height := AHeight;
end;

{ Renders the horizontal bearer bars. 
  - AWidth: total width of the symbol incl Border and WhiteSpaceWidth
  - AHeight: height of the symbol (without text)
  - ABorder: line width of the bearer bar }
procedure TSimpleBarcode.RenderBearerBars(AWidth, AHeight, ABorder: Integer;
  var ALastLine: PZintRenderLine);
var
  line: PZintRenderLine;
begin
  line := render_plot_create_line(0, 0, AWidth, ABorder);
  render_plot_add_line(FSymbol, line, @ALastLine);
  
  line := render_plot_create_line(0, ABorder + AHeight, AWidth, ABorder);
  render_plot_add_line(FSymbol, line, @ALastLine);
end;

{ Renders the vertical lines of the box. The horizontal lines of the box already
  have been render by RenderBearerBars. 
  - AWidth: total width of the symbol incl Border and WhiteSpaceWidth
  - AHeight: height of the symbol (without text)
  - ABorder: width of the box border }
procedure TSimpleBarcode.RenderBox(AWidth, AHeight, ABorder: Integer;
  var ALastLine: PZintRenderLine);
var
  line: PZintRenderLine;
begin
  line := render_plot_create_line(0, 0, ABorder, ABorder + AHeight + ABorder);
  render_plot_add_line(FSymbol, line, @ALastLine);
  
  line := render_plot_create_line(AWidth - ABorder, 0, AWidth, ABorder + AHeight + ABorder);
  render_plot_add_line(FSymbol, line, @ALastLine);
end;

{ Renders bars and spaces.
  - xLeft, yTop: left/top corner of the first bar
  - ASymbolWidth: width of the entire symbol (without border and whitespace)
  - ASymbolHeight: height of the entire symbol (without text)
  - ATextHeight: height of the human-readable text. Needed by EAN code bar extensions.
  - AFactor: current scaling factor with respect to pixels }
procedure TSimpleBarcode.RenderSymbol(xLeft, yTop, ASymbolWidth, ASymbolHeight, 
  ATextHeight, AFactor: Integer);
var
  i: Integer;        // general loop variable
  x, y: Integer;     // coordinates of the left/top corner of the currently rendered bar.
  row: Integer;      // index of the currently rendered row
  total_row_height: Integer;  // some of the heights stored in the Zint symbol record
  hrow: Integer;     // height of the currently rendered row
  wblock: Integer;   // width of an individual bar or space
  isBar: Boolean;    // flag indication whether the currently rendered feature is a bar or a space
  line, lastline: PZintRenderLine;
begin
  lastLine := GetLastLine;

  // Calculate total row height from the Zint symbol
  total_row_height := 0;
  for row := 0 to FSymbol^.rows-1 do
    total_row_height := total_row_height + FSymbol^.row_height[row];

  // y loop to render the symbol's bars and spaces
  y := yTop;
  for row := 0 to FSymbol^.rows-1 do
  begin   
    if total_row_height = 0 then
      hrow := ASymbolHeight div FSymbol^.Rows
    else
      hrow := round(ASymbolHeight * FSymbol^.row_height[row] / total_row_height);
    
    isBar := module_is_set(FSymbol, row, 0);
    x := xLeft;
    i := 0;
    while i < FSymbol^.Width do
    begin
      // Get width of current bar or space ("block")
      wblock := 0;
      repeat
        inc(wblock);
      until 
        (i + wblock >= FSymbol^.Width) or 
        (module_is_set(FSymbol, row, i + wblock) <> module_is_set(FSymbol, row, i));
      
      // Render bar. If no bar: skip this block
      if isBar then 
      begin
        line := render_plot_create_line(x, y, wblock*AFactor, hrow);
        render_plot_add_line(FSymbol, line, @lastLine);
      end;
  
      // Advance to next block
      inc(i, wblock);
      inc(x, wblock*AFactor);
      isBar := not isBar;
    end;
    
    // Advance to next row
    y := y + hrow;
  end;
end;

{ Renders the symbol's human-readable text. 
  - ASymbolWidth: width of the symbol, the text is centered
  - ASymbolstart: the x coordinate at which the first bar is drawn
  - ATextPos: vertical coordinate of the text position, refers to top of text. }
procedure TSimpleBarcode.RenderText(ASymbolWidth, ASymbolStart, ATextPos: Integer);
var
  lastString: PZintRenderString = nil;
  x: Integer;
begin
  x := ASymbolStart + ASymbolWidth div 2;
  render_plot_add_string(FSymbol, FSymbol^.text, x, ATextPos, 0, 0, @laststring); 
end;

{ Renders the barcode and saves it to the specified stream in the EPS format.
  Converts the rendered pixels of the barcode to the same size in the Symbol.
  Coordinates are points (1pt = 1/72 inch. }
procedure TSimpleBarcode.SaveToEpsStream(const AStream: TStream);
var
  factor, w, h: Double;
  drawer: TEpsBarcodeDrawer;
begin
  if (FSymbol^.rendered = nil) then
    Render(ClientWidth, ClientHeight);
  
  factor := 72.0 / ScreenInfo.PixelsPerInchX;   // Conversion from pixels to pts
  w := FSymbol^.rendered^.exact_width * factor; // Barcode width in pt
  h := FSymbol^.rendered^.exact_height * factor;// Barcode height in pt
  
  drawer := TEpsBarcodeDrawer.Create(w, h, FSymbol^.GetText);
  try
    DrawBarcode(drawer, factor);
    drawer.SaveToStream(AStream);
  finally
    drawer.Free;
  end;
end;

{ Renders the barcode and saves it as a graphic image to the specified stream.
  AImageClass is the image class to be created, e.g. TPortableNetworkGraphic
  (default, if omitted: TBitmap)
  AWidth and AHeight set the size of the bitmap which is assumed to be equal
  to the size of the rendered barcode if omitted. }
procedure TSimpleBarcode.SaveToStream(const AStream: TStream; 
  AImageClass: TFPImageBitmapClass = nil;
  AWidth: Integer = -1; AHeight: Integer = -1);
var
  img: TFPImageBitmap;
begin 
  if FSymbol^.rendered = nil then
    Render(ClientWidth, ClientHeight);

  if AWidth = -1 then 
    AWidth := round(FSymbol^.Rendered^.Exact_Width);
  if AHeight = -1 then 
    AHeight := round(FSymbol^.Rendered^.Exact_Height);

  if AImageClass = nil then
    img := TBitmap.Create
  else
    img := AImageClass.Create;  
  try
    img.SetSize(AWidth, AHeight);
    img.Canvas.Brush.Color := clWhite;
    img.Canvas.FillRect(0, 0, img.Width, img.Height);
    PaintOnCanvas(img.Canvas, Rect(0, 0, img.Width, img.Height));
    img.SaveToStream(AStream);
  finally
    img.Free;
  end;
end;

{ Renders the barcode and saves it as a svg image to the specified stream. 
  Converts the rendered pixels of the barcode to the same size in the svg.
  svg coordinates are millimeters. }
procedure TSimpleBarcode.SaveToSvgStream(const AStream: TStream);
var
  factor, w, h: Double;
  drawer: TSvgBarcodeDrawer;
begin
  if (FSymbol^.rendered = nil) then
    Render(ClientWidth, ClientHeight);
  
  factor := 25.4 / ScreenInfo.PixelsPerInchX;  // Conversion from pixels to mm
  w := FSymbol^.rendered^.exact_width * factor;    // Barcode width in mm
  h := FSymbol^.rendered^.exact_height * factor;   // Barcode height in mm
  
  drawer := TSvgBarcodeDrawer.Create(w, h, FSymbol^.GetText);
  try
    DrawBarcode(drawer, factor);
    drawer.SaveToStream(AStream);
  finally
    drawer.Free;
  end;
end;

procedure TSimpleBarcode.SetAddCheckSum(const AValue: Boolean);
begin
  if FAddCheckSum <> AValue then
  begin
    FAddCheckSum := AValue;
    GenerateAndInvalidate;
  end;
end;

procedure TSimpleBarcode.SetDisplayCheckSum(const AValue: Boolean);
begin
  if FDisplayCheckSum <> AValue then
  begin
    FDisplayCheckSum := AValue;
    GenerateAndInvalidate;
  end;
end;


{ TBarcodeC11 }

constructor TBarcodeC11.Create(AOwner: TComponent);
begin
  FBarcodeType := bctCode11;
  FValidBarcodeTypes := [bctCode11];
  inherited;
end;

class function TBarcodeC11.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 220;
  Result.CY := 80;
end;

function TBarcodeC11.GetSampleText: String;
begin
  Result := '012345678';
end;

function TBarcodeC11.InternalGenerate: Integer;
begin
  Result := inherited;
  if Result = 0 then
    Result := code_11(FSymbol, FText);
end;


{ TBarcodeC128 }

constructor TBarcodeC128.Create(AOwner: TComponent);
var
  bct: TBarcodeTypeC128;
begin
  FBarcodeType := bctCode128;
  for bct in TBarcodeTypeC128 do
    Include(FValidBarcodeTypes, bct);
  inherited;
end;

function TBarcodeC128.GetBarcodeType: TBarcodeTypeC128;
begin
  Result := TBarcodeTypeC128(FBarcodeType);
end;

class function TBarcodeC128.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 460;
  Result.CY := 80;
end;

function TBarcodeC128.GetSampleText: String;
begin
  case FBarcodeType of
    bctCode128: 
      Result := 'Sample-Code-128';
    bctEAN128:
      Result := '[01]Sample-EAN-128';
  end;
end;

function TBarcodeC128.InternalGenerate: Integer;
begin
  Result := inherited;
  if Result = 0 then
    case FBarcodeType of
      bctCode128: 
        Result := code_128(FSymbol, @FText[1], Length(FText));
      bctEAN128: 
        Result := ean_128(FSymbol, @FText[1], Length(FText));
      else 
        raise Exception.Create('Barcode type not supported.');
    end;
end;

procedure TBarcodeC128.SetBarcodeType(const AValue: TBarcodeTypeC128);
begin
  inherited SetBarcodeType(AValue);
end;


{ TBarcode2of5 }

constructor TBarcode2of5.Create(AOwner: TComponent);
var
  bct: TBarcodeType2of5;
begin
  FBarcodeType := bctCode25DataLogic;
  for bct in TBarcodeType2of5 do
    Include(FValidBarcodeTypes, bct);
  inherited;
end;

function TBarcode2of5.GetBarcodeType: TBarcodeType2of5;
begin
  Result := TBarcodeType2of5(FBarcodeType);
end;

class function TBarcode2of5.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 430;
  Result.CY := 80;
end;

function TBarcode2of5.GetSampleText: String;
begin
  Result := '012345678';
end;

function TBarcode2of5.InternalGenerate: Integer;
begin
  Result := inherited;
  
  if Result = 0 then 
  begin
    case FBarcodeType of
      bctCode25DataLogic:
        Result := logic_two_of_five(FSymbol, FText);
      bctCode25IATA:
        Result := iata_two_of_five(FSymbol, FText);
      bctCode25Industrial:
        Result := industrial_two_of_five(FSymbol, FText);
      bctCode25Interleaved:
        Result := interleaved_two_of_five(FSymbol, FText);
      bctCode25Standard:
        Result := matrix_two_of_five(FSymbol, FText);
      bctITF14:
        Result := itf14(FSymbol, FText);
      else 
        raise Exception.Create('Barcode type not supported.');
    end;
  end;
end; 
  
procedure TBarcode2of5.SetBarcodeType(const AValue: TBarcodeType2of5);
begin
  inherited SetBarcodeType(AValue);
end;

procedure TBarcode2of5.SetRecommendedSymbolSizeParams;
begin
  inherited;
  case FBarcodeType of
    bctITF14:
      begin
        // https://www.gs1ie.org/standards/data-carriers/barcodes/itf-14/
        FScale := MillimetersToPixels(1.016);
        FSymbolHeight := MillimetersToPixels(32.0);
      end;
    else
      ;
  end;
end;


{ TBarcode3of9 }

constructor TBarcode3of9.Create(AOwner: TComponent);
var
  bct: TBarcodeType3of9;
begin
  FBarcodeType := bctCode39;
  for bct in TBarcodeType3of9 do
    Include(FValidBarcodeTypes, bct);
  inherited;
end;

function TBarcode3of9.GetBarcodeType: TBarcodeType3of9;
begin
  Result := TBarcodeType3of9(FBarcodeType);
end;

class function TBarcode3of9.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 430;
  Result.CY := 80;
end;

function TBarcode3of9.GetSampleText: String;
begin
  Result := 'Barcode';
end;

function TBarcode3of9.InternalGenerate: Integer;
begin
  Result := inherited;
  if Result = 0 then
    case FBarcodeType of
      bctCode39, 
      bctLOGMARS: 
        Result := c39(FSymbol, FText);
      bctCode39Ext: 
        Result := ec39(FSymbol, FText);
      bctCode93:
        Result := c93(FSymbol, FText);
      else 
        raise Exception.Create('Barcode type not supported.');
    end;
end; 

procedure TBarcode3of9.SetBarcodeType(const AValue: TBarcodeType3of9);
begin
  inherited SetBarcodeType(AValue);
end;


{ TBarcodeEAN }

constructor TBarcodeEAN.Create(AOwner: TComponent); 
var
  bct: TBarcodeTypeEAN;
begin
  FBarcodeType := bctEAN;
  for bct in TBarcodeTypeEAN do
    Include(FValidBarcodeTypes, bct);
  
  inherited;
end;

{ Reserve space for the pre-text printed to the left of the symbol. }
procedure TBarcodeEAN.CalcSize(AFactor: Integer; out ATotalWidth, ATotalHeight,
  ASymbolWidth, ASymbolHeight, ATextWidth, ATextHeight, 
  ABorderWidth, AWhitespaceWidth: Integer);
var
  leftText, rightText: String;
  wLeftText, wRightText, h: Integer;
begin
  inherited CalcSize(AFactor, ATotalWidth, ATotalHeight, 
    ASymbolWidth, ASymbolHeight, ATextWidth, ATextHeight, 
    ABorderWidth, AWhiteSpaceWidth);

  if FShowHumanReadableText then
  begin
    leftText := GetLeftText;
    if leftText <> '' then
    begin
      GetTextSize(leftText + SPACER, wLeftText, h);
      inc(ATotalWidth, wLeftText);
    end;
    
    rightText := GetRightText;
    if rightText <> '' then
    begin
      GetTextSize(SPACER + rightText , wRightText, h);
      inc(ATotalWidth, wRightText);
    end;
  end;
end;

function TBarcodeEAN.CalcSymbolStart(ABorderWidth, AWhiteSpaceWidth: Integer): Integer;
var
  leftText: String;
  wLeftText, h: Integer;
begin
  Result := inherited CalcSymbolStart(ABorderWidth, AWhiteSpaceWidth);
  if FShowHumanReadableText then
  begin
    leftText := GetLeftText;
    if leftText <> '' then
    begin
      GetTextSize(leftText + SPACER, wLeftText, h);
      inc(Result, wLeftText div 2);  
        // advance only by half of the text width since the text will be centered.
    end;
  end;
end;

function TBarcodeEAN.GetAddOnText: String;
var
  txt: String;
  p: Integer;
begin
  txt := FSymbol^.GetText;
  p := pos('+', txt);
  if p > 0 then
    Result := Copy(txt, p+1)
  else
    Result := '';
end;

function TBarcodeEAN.GetBarcodeType: TBarcodeTypeEAN;
begin
  Result := TBarcodeTypeEAN(FBarcodeType);
end;

class function TBarcodeEAN.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 330;
  Result.CY := 110;
end;

function TBarcodeEAN.GetLeftText: String;
var
  txt: String;
begin
  txt := FSymbol^.GetText;
  if UPC_EAN_Flag in [13, 12, 6] then  // EAN-13, UPC-A, UPC-E
    Result := txt[1]
  else
    Result := '';
end;

function TBarCodeEAN.GetRightText: String;
var
  txt: String;
begin
  txt := FSymbol^.GetText;
  case UPC_EAN_Flag of
    12: Result := txt[12];   // UPC-A
     6: Result := txt[8];    // UPC-E
    else Result := '';
  end;
end;

function TBarcodeEAN.GetSampleText: String;
begin
  case FBarcodeType of
    bctEAN: 
      Result := '012345678';
    bctEAN14: 
      Result := '1845678901001';
    bctISBN: 
      Result := '9781234567897';
    bctNVE18: 
      Result := '614141123456789';
    bctUPCA: 
      Result := '72527273070';
    bctUPCE: 
      Result := '0123456';
    else 
      Result := inherited;
  end;
end;
  
function TBarcodeEAN.InternalGenerate: Integer;
var
  len: integer;
begin
  len := Length(FText);
  case FBarcodeType of
    bctEAN:
      Result := eanx(FSymbol, FText);
    bctEAN14:
      Result := ean_14(FSymbol, @FText[1], len);
    bctISBN:
      Result := eanx(FSymbol, FText);
    bctNVE18:
      Result := nve_18(FSymbol, @FText[1], len);
    bctUPCA:
      Result := eanx(FSymbol, FText);
    bctUPCE:
      Result := eanx(FSymbol, FText);
    else 
      raise Exception.Create('Barcode type not supported.');
  end;
end; 
                
{ Is overridden to handle the bar extensions of most of the UPC/EAN codes, i.e.
  some bars are drawn longer than the others.}
procedure TBarcodeEAN.RenderSymbol(xLeft, yTop, ASymbolWidth, ASymbolHeight, 
  ATextHeight, AFactor: Integer); 
var
  i, n: Integer;
  line: PZintRenderLine;
  upc_ean: Integer;
  extendBar: boolean;
begin
  inherited;
  
  // Count the bars
  n := 0;
  line := FSymbol^.rendered^.lines;
  while line <> nil do
  begin
    Inc(n);
    line := line^.next;
  end;

  // Draw the bar extensions
  upc_ean := UPC_EAN_Flag;
  i := 0;
  line := FSymbol^.rendered^.lines;
  while line <> nil do
  begin
    extendBar := false;
    case upc_ean of
      8:  // EAN-8
        if (i in [0, 1, 10, 11, 20, 21]) then extendBar := true;
      13: // EAN-13
        if (i in [0, 1, 14, 15, 28, 29]) then extendBar := true;
      12: // UPC-A
        if (i in [0, 1, 2, 3, 14, 15, 26, 27, 28, 29]) then extendBar := true;
      6:  // UPC-E
        if (i in [0, 1, 14, 15, 16]) then extendBar := true;
      else 
        ;
    end;
    if extendBar then
      line^.length := line^.length + ATextHeight;
    Inc(i);
    line := line^.next;
  end;
end;
                
{ Is overridden to show text in groups and before and after the symbol }
procedure TBarcodeEAN.RenderText(ASymbolWidth, ASymbolStart, ATextPos: Integer); 

  function TextCenter(LineL, LineR: Integer): Integer;
  var
    i: Integer;
    line: PZintRenderLine;
    x1, x2: Integer;
  begin
    x1 := -999;
    x2 := -999;
    i := 0;
    line := FSymbol^.rendered^.lines;
    while line <> nil do
    begin
      if i = LineL then
        x1 := round(line^.x + line^.width)
      else 
      if (LineR <> -1) and (i = LineR) then
        x2 := round(line^.x)
      else
      if (LineR = -1) then
        x2 := round(line^.x);
      line := line^.next;
      inc(i);
    end;
    Result := (x1 + x2) div 2;
  end;
    
var
  lastString: PZintRenderString = nil;
  fullText: String;
  text14: String = '';  // text centered 1/4 of the width
  text34: String = '';  // text centered at 3/4 of the width
  text24: String = '';  // text centered over the full width
  textL: String = '';   // text to the left of the first bar
  textR: String = '';   // text to the right of the last bar
  textAddOn: String = ''; // add-on text
  x14, x24, x34, xaddon: Integer;
  w, h: Integer;
begin
  fullText := FSymbol^.GetText;
  if fullText = '' then
    exit;
  
  textL := GetLeftText;
  textR := GetRightText;
  textAddOn := GetAddOnText;
  case UPC_EAN_Flag of
    8:  // EAN-8
      begin
        text14 := copy(fullText, 1, 4);
        text34 := copy(fullText, 5, 4);
        x14 := TextCenter(1, 10);
        x34 := TextCenter(11, 20);
        if textAddOn <> '' then xAddOn := TextCenter(22, -1);
      end;
    13:  // EAN-13
      begin
        text14 := copy(fullText, 2, 6);
        text34 := copy(fullText, 8, 6);
        x14 := TextCenter(1, 14);
        x34 := TextCenter(15, 28);
        if textAddOn <> '' then xAddOn := TextCenter(30, -1);
      end;
    12:  // UPC-A
      begin
        text14 := copy(fullText, 2, 5);
        text34 := copy(fullText, 7, 6);
        x14 := TextCenter(3, 14);
        x34 := TextCenter(15, 26);
        if textAddOn <> '' then xAddOn := TextCenter(30, -1);
      end;
    6:   // UPC-E
      begin
        text24 := copy(fullText, 2, 6);
        x24 := TextCenter(1, 14);
        if textAddOn <> '' then xAddOn := TextCenter(17, -1);
      end;
    else
      text24 := fullText;
      x24 := ASymbolStart + ASymbolWidth div 2;
  end;
  
  if textL <> '' then
  begin
    GetTextSize(textL + SPACER, w, h);
    render_plot_add_string(FSymbol, PByte(textL), ASymbolStart - w div 2, ATextPos, 0, 0, @laststring);
  end;
  
  if text14 <> '' then
    render_plot_add_string(FSymbol, PByte(text14), x14, ATextPos, 0, 0, @laststring); 
  
  if text34 <> '' then
    render_plot_add_string(FSymbol, PByte(text34), x34, ATextPos, 0, 0, @laststring);
  
  if (text24 <> '') then
    render_plot_add_string(FSymbol, PByte(text24), x24, ATextPos, 0, 0, @laststring);
  
  if textR <> '' then
  begin
    GetTextSize(SPACER + textR, w, h);
    render_plot_add_string(FSymbol, PByte(textR), ASymbolStart + ASymbolWidth + w div 2, ATextPos, 0, 0, @laststring);
  end;  
  
  if textAddOn <> '' then
    render_plot_add_string(FSymbol, PByte(textAddOn), xAddOn, ATextPos, 0, 0, @laststring);
end;

procedure TBarcodeEAN.SetBarcodeType(const AValue: TBarcodeTypeEAN);
begin
  inherited SetBarcodeType(AValue);
end;

procedure TBarcodeEAN.SetRecommendedSymbolSizeParams; 
begin
  inherited;
  
  FScale := MillimetersToPixels(0.330);
  if FScale < 2 then FScale := 2;
  case UPC_EAN_FLAG of
    6, 12:
      begin // UPC-A, UPC-E
        FSymbolHeight := MillimetersToPixels(22.85);  
      end;
    13:
      begin // EAN-13
        // https://www.gs1ie.org/standards/data-carriers/barcodes/ean-13/
        FSymbolHeight := MillimetersToPixels(22.85);  
        FWhiteSpaceWidth := MillimetersToPixels(3.63);   
          // not implemented: the left and right margins should be different...
      end;
    8: 
      begin // EAN-8
        // https://www.gs1ie.org/standards/data-carriers/barcodes/ean-8/
        FScale := MillimetersToPixels(0.330);
        FSymbolHeight := MillimetersToPixels(18.23);
        FWhiteSpaceWidth := MillimetersToPixels(2.31);   
      end;
    2, 5:       // EAN-2 and EAN-5
      FSymbolHeight := MillimetersToPixels(21.10);
    else
      ;
  end;
end;

function TBarcodeEAN.UPC_EAN_Flag: Integer;
var
  len: Integer;
begin
  Result := 0;
  if FSymbol = nil then
    exit;

  len := Length(FSymbol^.GetText);
  
  if ((FSymbol^.symbology = BARCODE_EANX) and (FSymbol^.rows = 1)) or 
      (FSymbol^.symbology = BARCODE_EANX_CC) or 
      (FSymbol^.symbology = BARCODE_ISBNX) then
  begin
    case len of
      13, 16, 19: Result := 13;
      2: Result := 2;
      5: Result := 5;
      else Result  := 8;
    end;
  end 
  else
  if ((FSymbol^.symbology = BARCODE_UPCA) and (FSymbol^.rows = 1)) or 
      (FSymbol^.symbology = BARCODE_UPCA_CC) 
  then
    Result := 12
  else
  if ((FSymbol^.symbology = BARCODE_UPCE)) and (FSymbol^.rows = 1) or 
      (FSymbol^.symbology = BARCODE_UPCE_CC) 
  then
    Result := 6;
end;
  

{ TBarcodeChannelCode }

constructor TBarcodeChannelCode.Create(AOwner: TComponent);
begin
  FBarcodeType := bctChannelCode;
  FValidBarcodeTypes := [bctChannelCode];
  inherited;
end;

class function TBarcodeChannelCode.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 90;
  Result.CY := 90;
end;

function TBarcodeChannelCode.GetSampleText: String;
begin
  Result := '1234567';
end;

function TBarcodeChannelCode.InternalGenerate: Integer;
begin
  FSymbol^.option_2 := FChannelCount;
  Result := channel_code(FSymbol, FText);
end; 

procedure TBarcodeChannelCode.SetChannelCount(const AValue: Integer);
begin
  if FChannelCount <> AValue then
  begin
    FChannelCount := AValue;
    GenerateAndInvalidate;
  end;
end;

procedure TBarcodeChannelCode.SetRecommendedSymbolSizeParams; 
begin
  inherited;
  // https://barcodeguide.seagullscientific.com/Content/Symbologies/Channel_Code.htm
  FWhitespaceWidth := 2*FScale;
  FMinSymbolHeight := MillimetersToPixels(5.0);
end;


{ TBarcodeTypePlessey }

constructor TBarcodePlessey.Create(AOwner: TComponent);
var
  bct: TBarcodeTypePlessey;
begin
  FBarcodeType := bctPlessey;
  for bct in TBarcodeTypePlessey do
    Include(FValidBarcodeTypes, bct);
  inherited;
  FBearerBarMode := bbmNone;
end;

function TBarcodePlessey.GetBarcodeType: TBarcodeTypePlessey;
begin
  Result := TBarcodeTypePlessey(FBarcodeType);
end;

class function TBarcodePlessey.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 450;
  Result.CY := 80;
end;

function TBarcodePlessey.GetSampleText: String;
begin
  Result := '012345678';
end;

function TBarcodePlessey.InternalGenerate: Integer;
begin
  Result := inherited;
  if Result = 0 then
    case FBarcodeType of
      bctPlessey: 
        Result := plessey(FSymbol, FText);
      bctMSIPlessey: 
        begin
          if FSymbol^.Option AND OPTION_ADD_CHECKSUM <> 0 then
            // Select type of checksum
            FSymbol^.Option_2 := ord(FCheckChar) + 1
          else
            FSymbol^.Option_2 := 0;
          Result := msi_plessey(FSymbol, FText);
        end;
      else 
        raise Exception.Create('Barcode type not supported.');
    end;
end;

procedure TBarcodePlessey.SetBarcodeType(const AValue: TBarcodeTypePlessey);
begin
  inherited SetBarcodeType(AValue);
end;

procedure TBarcodePlessey.SetCheckChar(const AValue: TPlesseyCheckChar);
begin
  if FCheckChar = AValue then exit;
  FCheckChar := AValue;
  GenerateAndInvalidate;
end;

procedure TBarcodePlessey.SetRecommendedSymbolSizeParams; 
begin
  inherited;
  // https://barcodeguide.seagullscientific.com/content/Symbologies/Plessey.htm
  FWhiteSpaceWidth := InchToPixels(0.125);
  FBearerBarMode := bbmNone;
end;  


{ TBarcodeTelepen }

constructor TBarcodeTelepen.Create(AOwner: TComponent);
var
  bct: TBarcodeTypeTelepen;
begin
  FBarcodeType := bctTelepen;
  for bct in TBarcodeTypeTelepen do
    Include(FValidBarcodeTypes, bct);
  inherited;
  FBearerBarMode := bbmNone;
end;

function TBarcodeTelepen.GetBarcodeType: TBarcodeTypeTelepen;
begin
  Result := TBarcodeTypeTelepen(FBarcodeType);
end;

class function TBarcodeTelepen.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 280;
  Result.CY := 80;
end;

function TBarcodeTelepen.GetSampleText: String;
begin
  case FBarcodeType of
    bctTelepenNum: 
      Result := '012345678';
    else 
      Result := 'Telepen';
  end;
end;

function TBarcodeTelepen.InternalGenerate: Integer;
begin
  case FBarcodeType of
    bctTelepen: 
      Result := telepen(FSymbol, FText);
    bctTelepenNum: 
      Result := telepen_num(FSymbol, FText);
    else 
      raise Exception.Create('Barcode type not supported.');
  end;
end;

procedure TBarcodeTelepen.SetBarcodeType(const AValue: TBarcodeTypeTelepen);
begin
  inherited SetBarcodeType(AValue);
end;

procedure TBarcodeTelepen.SetRecommendedSymbolSizeParams; 
begin
  inherited;
  FWhiteSpaceWidth := MillimetersToPixels(2.54);
  FBearerBarMode := bbmNone;
end;


{ TBarcodeMedical }

constructor TBarcodeMedical.Create(AOwner: TComponent); 
var
  bct: TBarcodeTypeMedical;
begin
  FBarcodeType := bctCodaBar;
  for bct in TBarcodeTypeMedical do
    Include(FValidBarcodeTypes, bct);
  inherited;
  FBearerBarMode := bbmNone;
end;

function TBarcodeMedical.GetBarcodeType: TBarcodeTypeMedical;
begin
  Result := TBarcodeTypeMedical(FBarcodeType);
end;

class function TBarcodeMedical.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 330;
  Result.CY := 80;
end;

function TBarcodeMedical.GetSampleText: String;
begin
  case FBarcodeType of
    bctCodaBar:
      Result := '012345678';
    bctCode32:
      Result := '01234567';
    bctPharmaOne:
      Result := '123456';
    bctPharmaTwo:
      Result := '12345678';
    bctPZN7:
      Result := '123456';
    bctPZN8:
      Result := '1234567';
    else
      Result := inherited;
  end;
end;

function TBarcodeMedical.InternalGenerate: Integer;
begin
  case FBarcodeType of
    bctCodaBar:
      Result := codabar(FSymbol, FText);
    bctCode32:
      Result := code32(FSymbol, FText);
    bctPharmaOne:
      Result := pharma_one(FSymbol, FText);
    bctPharmaTwo:
      Result := pharma_two(FSymbol, FText);
    bctPZN7:
      begin
        FSymbol^.option_3 := 7;
        Result := Pharmazentral(FSymbol, FText);
      end;
    bctPZN8:
      begin
        FSymbol^.option_3 := 8;
        Result := Pharmazentral(FSymbol, FText);
      end;
    else 
      raise Exception.Create('Barcode type not supported.');
  end;
end; 
  
procedure TBarcodeMedical.SetBarcodeType(const AValue: TBarcodeTypeMedical);
begin
  inherited SetBarcodeType(AValue);
end;

procedure TBarcodeMedical.SetRecommendedSymbolSizeParams;
begin
  inherited;
  FBearerBarMode := bbmNone;
  case FBarcodeType of
    bctCodabar:
      begin
        FScale := 2;
        FWhitespaceWidth := 10 * FScale;
        FMinSymbolHeight := MillimetersToPixels(5.0);
      end;
    bctPharmaOne:
      begin
        // https://help.commonvisionblox.com/Barcode/html_1dpharmacode_hints.htm
        FScale := MillimetersToPixels(0.5);
        FSymbolHeight := MillimetersToPixels(8.0);
        // https://barcodeguide.seagullscientific.com/Content/Symbologies/Phamacode.htm
        FWhitespaceWidth := MillimetersToPixels(6.0);
      end;
    bctPharmaTwo:
      begin
        // https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&ved=2ahUKEwjnua28sZb2AhXwSPEDHYfuAN4QFnoECCkQAQ&url=http%3A%2F%2Fwww.gomaro.ch%2Fftproot%2FLaetus_PHARMA-CODE.pdf&usg=AOvVaw05Tz-byyhJWQ15iDMIEqe1
        // https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&ved=2ahUKEwj-yumGsJb2AhVISPEDHbeKAec4ChAWegQIGRAB&url=http%3A%2F%2Fwww.gomaro.ch%2Fftproot%2FLaetus_PHARMA-CODE.pdf&usg=AOvVaw05Tz-byyhJWQ15iDMIEqe1
        FScale := MillimetersToPixels(0.8);
        FSymbolHeight := MillimetersToPixels(12.0);
        // https://barcodeguide.seagullscientific.com/Content/Symbologies/TwoTrackPharmacode.htm
        FWhitespaceWidth := MillimetersToPixels(6.0);
      end;
    else
      ;
  end;
end;


{ TBarcodePostal }

constructor TBarcodePostal.Create(AOwner: TComponent);
var
  bct: TBarcodeTypePostal;
begin
  FBarcodeType := bctPostNet;
  for bct in TBarcodeTypePostal do
    Include(FValidBarcodeTypes, bct);
  
  inherited;

  FBearerBarMode := bbmNone;
  FGrouped := true;
end;

function TBarcodePostal.GetBarcodeType: TBarcodeTypePostal;
begin
  Result := TBarcodeTypePostal(FBarcodeType);
end;

class function TBarcodePostal.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 390;
  Result.CY := 92;
end;

function TBarcodePostal.GetSampleText: String;
begin
  case FBarcodeType of
    bctAustraliaPostCustomer:
      Result := '12345678Abcde';
    bctAustraliaPostReplyPaid:
      Result := '12345678';
    bctAustraliaPostRoute:
      Result := '12345678';
    bctAustraliaPostRedirect:
      Result := '12345678';
    bctDaft:
      Result := 'DAFTDAFTDAFT';
    bctDeutschePostIdentCode:
      Result := '12345678901';
    bctDeutschePostLeitCode:
      Result := '1234567890123';
    bctFIM:
      Result := 'A';
    bctJapanPost:
      Result := '0123456789';
    bctKoreaPost:
      Result := '123456';
    bctKIX:
      Result := 'ABC123456';
    bctPlanet:
      Result := '123456789';
    bctPostNet:
      Result := '12345678901';
    bctRM4SCC:
      Result := '1234567ABC';
    else
      Result := inherited;
  end;
end;

function TBarcodePostal.InternalGenerate: Integer;
begin
  if FGrouped then
    FSymbol^.Option := OPTION_GROUPED_CHARS;
  
  case FBarcodeType of
    bctAustraliaPostCustomer,
    bctAustraliaPostReplyPaid,
    bctAustraliaPostRoute,
    bctAustraliaPostRedirect:
//      Result := australia_post(FSymbol, PByte(FText), Length(FText)); // strLen(PChar(@FSymbol^.Text[0])));
      Result := australia_post(FSymbol, FText);
    bctDaft:
      Result := daft_code(FSymbol, FText);
    bctDeutschePostIdentCode:
      Result := dpident(FSymbol, FText);
    bctDeutschePostLeitCode:
      Result := dpleit(FSymbol, FText);
    bctFIM:
      Result := fim(FSymbol, FText);
    bctJapanPost:
      Result := japan_post(FSymbol, FText);
    bctKix:
      Result := kix_code(FSymbol, FText);
    bctKoreaPost:
      Result := korea_post(FSymbol, FText);
    bctPlanet:
      Result := planet_plot(FSymbol, FText);
    bctPostNet:
      Result := post_plot(FSymbol, FText);
    bctRM4SCC:
      Result := royal_plot(FSymbol, FText);
    else 
      raise Exception.Create('Barcode type not supported.');
  end;
end; 
  
procedure TBarcodePostal.SetBarcodeType(const AValue: TBarcodeTypePostal);
begin
  inherited SetBarcodeType(AValue);
end;

procedure TBarcodePostal.SetGrouped(const AValue: Boolean);
begin
  if FGrouped = AValue then exit;
  FGrouped := AValue;
  GenerateAndInvalidate;
end;

procedure TBarcodePostal.SetRecommendedSymbolSizeParams;
begin
  inherited;
  case FBarcodeType of
    bctAustraliaPostCustomer,
    bctAustraliaPostReplyPaid,
    bctAustraliaPostRoute,
    bctAustraliaPostRedirect:
      begin
        // https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&ved=2ahUKEwiVn67kxJ72AhW3SfEDHa6TDKQQFnoECBEQAQ&url=https%3A%2F%2Fauspost.com.au%2Fcontent%2Fdam%2Fauspost_corp%2Fmedia%2Fdocuments%2Fbarcoding-fact-sheet-oct14.pdf&usg=AOvVaw1lhoTgaNWAS9uF68b9a4Z0
        FScale := MillimetersToPixels(0.4);
        FSymbolHeight :=  MillimetersToPixels(5.0);
        FMinSymbolHeight := MillimetersToPixels(4.2);
        FMargin := MillimetersToPixels(2.0);
        FWhiteSpaceWidth := MillimetersToPixels(4.0);
      end;
    bctFIM:
      begin
        // https://barcodeguide.seagullscientific.com/Content/Symbologies/FIM.htm
        FScale := InchToPixels(0.03125);
        FSymbolHeight := InchToPixels(0.625);
      end;
    bctPostNet, bctPlanet:
      begin
        // https://pe.usps.com/Archive/NHTML/DMMArchive20170807/204.htm#ep1125449
        // "A full bar must be 0.125 ±0.010 inch high"
        // "A half bar must be 0.050 ±0.010 inch high."
        // "All bars must be 0.020 ±0.005 inch wide"
        FSymbolHeight := InchToPixels(0.125);
        FScale := InchToPixels(0.020);
      end;
    bctKIX, bctRM4SCC:
      begin
        // from lbc_render.pas
        FScale := (ScreenInfo.PixelsPerInchY div 2) div 22;  // 22 bars per inch
        FSymbolHeight := MillimetersToPixels(5.22);
      end;
    bctJapanPost:
      begin
        // at least 2 mm quiet zone on all sides
        FMargin := MillimetersToPixels(2.0);
        FWhiteSpaceWidth := 0;
      end;
    else
      ;
  end;
  FBearerBarMode := bbmNone;
end;


{ TBarcodePDF417 }

constructor TBarcodePDF417.Create(AOwner: TComponent);
var
  bct: TBarcodeTypePDF417;
begin
  FBarcodeType := bctPDF417;
  for bct in TBarcodeTypePDF417 do
    Include(FValidBarcodeTypes, bct);
  
  inherited;

  FShowHumanReadableText := false;
  FSymbolHeight := 3;
  FWhiteSpaceWidth := 0;
  FCheckDigitCount := -1;
end;

procedure TBarcodePDF417.CalcSize(AFactor: Integer; out ATotalWidth, ATotalHeight,
  ASymbolWidth, ASymbolHeight, ATextWidth, ATextHeight, 
  ABorderWidth, AWhitespaceWidth: Integer); 
var
  x_factor, y_factor: Integer;
begin
  inherited;
  if FSymbol <> nil then
  begin
    x_factor := AFactor;
    if FSymbolHeight <= 0 then
      y_factor := 3 * x_factor
    else
      y_factor := FSymbolHeight * x_factor;   // FSymbolHeight is interpreted as row height here.
    ASymbolHeight := FSymbol^.rows * y_factor;
    ATotalHeight := ASymbolHeight + 2*ABorderWidth;
    ATotalWidth := ATotalWidth + 2*ABorderWidth;
  end;
end;

function TBarCodePDF417.CalcSymbolStart(ABorderWidth, AWhiteSpaceWidth: integer): Integer;
begin
  Result := ABorderWidth;
end;

function TBarcodePDF417.GetBarcodeType: TBarcodeTypePDF417;
begin
  Result := TBarcodeTypePDF417(FBarcodeType);
end;

class function TBarcodePDF417.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 225;
  Result.CY := 110;
end;

function TBarcodePDF417.GetRowHeightRatio: Integer;
begin
  Result := FSymbolHeight;
end;

procedure TBarcodePDF417.InitSymbol(ASymbology: Integer);
begin
  inherited InitSymbol(ASymbology);
  FSymbol^.Option_1 := FCheckDigitCount;
  FSymbol^.Option_2 := FCols;
end;

function TBarcodePDF417.InternalGenerate: Integer;
begin
  case FBarcodeType of
    bctPDF417: 
      Result := pdf417(FSymbol, PByte(FText), Length(FText));
    bctPDF417trunc: 
      Result := pdf417enc(FSymbol, PByte(Text), Length(FText));
    bctMicroPDF417: 
      Result := micro_pdf417(FSymbol, PByte(Text), Length(FText));
    else 
      raise Exception.Create('Barcode type not supported.');
  end;
end;

procedure TBarcodePDF417.SetBarcodeType(const AValue: TBarcodeTypePDF417);
begin
  inherited SetBarcodeType(AValue);
end;

procedure TBarcodePDF417.SetCheckDigitCount(const AValue: TPDF417CheckDigitCount);
begin
  if AValue <> FCheckDigitCount then
    FCheckDigitCount := AValue;
end;

procedure TBarcodePDF417.SetCols(const AValue: TPDF417Cols);
begin
  if AValue <> FCols then
    FCols := AValue;
end;

procedure TBarcodePDF417.SetRecommendedSymbolSizeParams;
begin
  inherited;
  FSymbolHeight := 3;
end;
  
procedure TBarcodePDF417.SetRowHeightRatio(const AValue: Integer);
begin
  SetSymbolHeight(AValue);
end;


{ TBarcodeSquare - a hierarchy of barcodes with a square symbol }

constructor TBarcodeSquare.Create(AOwner: TComponent);
begin
  inherited;
  FScale := 0;
  FShowHumanReadableText := false;
  FSymbolHeight := 0;
  FWhiteSpaceWidth := 0;
  if (Width = 0) or (Height = 0) then
  begin
    Width := 88;
    Height := 88;
  end;
end;

{ Calculates the pixel multiplication factor to fill the entire control as much
  as possible. Needed when FScale = 0. Considers only integer multiples of
  pixels}
function TBarcodeSquare.CalcFactor(AWidth, AHeight: Integer): Integer;
begin
  if (FSymbol = nil) or (FSymbol^.Width = 0) then
    Result := 1
  else
  begin
    if AWidth > AHeight then
      Result := AHeight div FSymbol^.Width
    else
      Result := AWidth div FSymbol^.Width;
    if Result = 0 then
      Result := 1;
  end;
end;

{ Calculates scaled size parameters for the barcode. }
procedure TBarcodeSquare.CalcSize(AFactor: Integer; out ATotalWidth, ATotalHeight,
  ASymbolWidth, ASymbolHeight, ATextWidth, ATextHeight, 
  ABorderWidth, AWhitespaceWidth: Integer); 
begin
  if FSymbol = nil then
    exit;

  ABorderWidth := FMargin;
  AWhiteSpaceWidth := 0;

  // These barcodes do not show human-readable text
  ATextWidth := 0;
  ATextHeight := 0;
  
  ASymbolWidth := (FSymbol^.Width) * AFactor;
  ASymbolHeight := ASymbolWidth;
     
  ATotalWidth := ASymbolWidth + 2*ABorderWidth;
  ATotalHeight := ATotalWidth;
end;

function TBarCodeSquare.CalcSymbolStart(ABorderWidth, AWhiteSpaceWidth: integer): Integer;
begin
  Result := ABorderWidth;
end;

procedure TBarcodeSquare.CalculatePreferredSize(
  var PreferredWidth, PreferredHeight: Integer;
  WithThemeSpace: Boolean); 
var
  wtot, htot, wsym, hsym, wtxt, htxt, wb, wws: Integer;
  factor: Integer;
begin
  inherited;
  if FSymbol = nil then
    with GetControlClassDefaultSize do
    begin
      PreferredWidth := CX;
      PreferredHeight := CY;
    end
  else
  begin
    if FScale = 0 then
      factor := CalcFactor(ClientWidth, ClientHeight)
    else
      factor := FScale;
    CalcSize(factor, wtot, htot, wsym, hsym, wtxt, htxt, wb, wws);
    PreferredWidth := wtot;
    PreferredHeight := htot;
  end;
end;

class function TBarcodeSquare.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 88;
  Result.CY := 88;
end;

procedure TBarcodeSquare.SetRecommendedSymbolSizeParams;
begin
  FScale := 0;
  FSymbolHeight := 0;
  FShowHumanReadableText := false;
end;


{ TBarcodeQR }

constructor TBarcodeQR.Create(AOwner: TComponent); 
begin
  FBarcodeType := bctQR;
  FValidBarcodeTypes := [bctQR];
  inherited;
end;

function TBarcodeQR.InternalGenerate: Integer;
begin
  UpdateECCLevel;
  Result := qr_code(FSymbol, @FText[1], Length(FText));
end;

procedure TBarcodeQR.SetECCLevel(const AValue: TBarcodeQR_ECCLevel);
begin
  if FECCLevel=AValue then exit;
  FECCLevel:=AValue;
  GenerateAndInvalidate;
end;

procedure TBarcodeQR.UpdateECCLevel;
begin
  FSymbol^.option_1 := ord(FECCLevel);
end;


{ TBarcodeMicroQR }

constructor TBarcodeMicroQR.Create(AOwner: TComponent);
begin
  FBarcodeType := bctMicroQR;
  FValidBarcodeTypes := [bctMicroQR];
  inherited;
end;

function TBarcodeMicroQR.InternalGenerate: Integer;
begin
  UpdateECCLevel;
  Result := microqr(FSymbol, @FText[1], Length(FText));
end;


{ TBarcodeAztec }

constructor TBarcodeAztec.Create(AOwner: TComponent); 
begin
  FBarcodeType := bctAztec;
  FShowHumanReadableText := false;
  FValidBarcodeTypes := [bctAztec];
  inherited;
end;

function TBarcodeAztec.InternalGenerate: Integer;
begin
  FShowHumanReadableText := false;
  Result := aztec(FSymbol, @FText[1], Length(FText));
end;


{ TBarcodeAztecRune }

constructor TBarcodeAztecRune.Create(AOwner: TComponent);
begin
  FBarcodeType := bctAztecRune;
  FValidBarcodetypes := [bctAztecRune];

  inherited;
  
  FShowHumanReadableText := false;
end;

function TBarcodeAztecRune.GetSampleText: String;
begin
  Result := '123';
end;
  
function TBarcodeAztecRune.GetValue: TBarcodeAztecRune_Value;
begin
  Result := StrToInt(FText);
end;

function TBarcodeAztecRune.InternalGenerate: Integer;
begin
  Result := aztec_runes(FSymbol, @FText[1], Length(FText));
end;

procedure TBarcodeAztecRune.SetValue(const AValue: TBarcodeAztecRune_Value);
var
  txt: String;
begin
  txt := IntToStr(AValue);
  if FText = txt then exit;
  FText := txt;
  GenerateAndInvalidate;
end;


{ TBarcodeDataMatrix }

constructor TBarcodeDataMatrix.Create(AOwner: TComponent);
begin
  FBarcodeType := bctDataMatrix;
  FValidBarcodeTypes := [bctDataMatrix];

  inherited;

  FShowHumanReadableText := false;
end;

function TBarcodeDataMatrix.InternalGenerate: Integer; 
begin
  Result := dmatrix(FSymbol, @FText[1], Length(FText));
end;


{ TBarcodeMaxiCode }

const
  W_HEXAGON = 2.0;
  H_HEXAGON = 4.0/sqrt(3.0);

constructor TBarcodeMaxiCode.Create(AOwner: TComponent);
begin
  FBarcodeType := bctMaxiCode;
  FValidBarcodeTypes := [bctMaxiCode];
  
  inherited;
  
  FMode := mcmAuto;
  FShowHumanReadableText := false;
end;

function TBarcodeMaxiCode.BuildPrimary: String;
var
  i: Integer;
  isMode2: Boolean;
  postcodeStr, countrycodeStr, servicecodeStr: String;
begin
  Result := '';
  isMode2 := true;
  case FMode of
    mcmAuto:
      begin
        for i := 1 to Length(FPostCode) do
          if not (UpCase(FPostcode[i]) in ['0'..'9']) then
          begin
            isMode2 := false;
            break;
          end;
        if isMode2 and (Length(FPostCode) > 9) then
          SetLength(FPostcode, 9)
        else if (not isMode2) and (Length(FPostCode) > 6) then
          SetLength(FPostCode, 6);
      end;
    mcmMode2:
      if (Length(FPostCode) > 9) then 
        SetLength(FPostcode, 9);
    mcmMode3:
      if (Length(FPostcode) > 6) then
        SetLength(FPostcode, 6);
    else
      exit;
  end;
  
  postcodeStr := FPostcode + StringOfChar(' ', 9 - Length(FPostCode));
  countrycodeStr := FormatFloat('000', FCountryCode);
  servicecodeStr := FormatFloat('000', FServiceCode);
  
  Result := postcodeStr + countrycodeStr + servicecodeStr;
end;
  
{ Calculates the pixel multiplication factor to fill the entire control as much
  as possible. Needed when FScale = 0. Considers only integer multiples of
  pixels. For MaxiCode the aspect ratio (height/width) is constant 26.93mm/28.14mm.}
function TBarcodeMaxiCode.CalcFactor(AWidth, AHeight: Integer): Integer;
var
  h, w: Double;
  fx, fy: Double;
begin
  h := H_HEXAGON * (FSymbol^.Rows + 2);
  w := W_HEXAGON * (FSymbol^.Width + 2);
  fx := AWidth/w;
  fy := AHeight/h;
  if fx < fy then
    Result := round(fx)
  else
    Result := round(fy);
  if Result = 0 then
    Result := 1;
end;
    
    
{ Calculates the dimensions of the maxi code symgol. 
  The scaling factor has been applied. }
procedure TBarcodeMaxiCode.CalcSize(AFactor: Integer;
  out ATotalWidth, ATotalHeight, ASymbolWidth, ASymbolHeight, 
  ATextWidth, ATextHeight, ABorderWidth, AWhitespaceWidth: Integer);
begin
  // +2 for an empty hexagon around the symbol
  ASymbolWidth := round(W_HEXAGON * (FSymbol^.Width + 2) * AFactor);  
  ASymbolHeight := round(H_HEXAGON * 0.75 * (FSymbol^.Rows + 1.5) * AFactor);

  // No human-readable text 
  ATextWidth := 0;
  ATextHeight := 0;
      
  ABorderWidth := FMargin;
  AWhitespaceWidth := 0;   // No white-space
    
  ATotalWidth := ASymbolWidth + 2 * ABorderWidth;
  ATotalHeight := ASymbolHeight + 2 * ABorderWidth;
end;

function TBarcodeMaxicode.CalcSymbolStart(ABorderWidth, AWhiteSpaceWidth: Integer): Integer; 
begin
  Result := ABorderWidth;
end;

procedure TBarcodeMaxiCode.CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer;
  WithThemeSpace: Boolean);
var
  wtot, htot, wsym, hsym, wtxt, htxt, wb, wws: Integer;
  factor: Integer;
begin
  inherited;
  if FScale = 0 then
    factor := CalcFactor(ClientWidth, ClientHeight)
  else
    factor := FScale;
  CalcSize(factor, wtot, htot, wsym, hsym, wtxt, htxt, wb, wws);
  PreferredWidth := wtot;
  PreferredHeight := htot;
end;

procedure TBarcodeMaxiCode.DrawBarcode(ADrawer: TBasicBarcodeDrawer; AFactor: Double);
var
  ring: PZintRenderRing;
  hexagon: PZintRenderHexagon;
  wx: Double;
  rInner, rOuter: Double;
begin
  // Prepare drawer
  if FBackgroundColor = clDefault then
    ADrawer.BackColor := GetDefaultColor(dctBrush)
  else
    ADrawer.BackColor := ColorToRGB(FBackgroundColor);
  
  if FForegroundColor = clDefault then
    ADrawer.BarColor := GetDefaultColor(dctFont)
  else
    ADrawer.BarColor := ColorToRGB(FForegroundColor);
  
  // Start drawing, clear background
  ADrawer.BeginDrawing;
  
  // Hexagon horizontal width
  if FScale = 0 then
    wx := AFactor * CalcFactor(ClientWidth, ClientHeight)
  else
    wx := AFactor * FScale;
  
  // Draw the rings
  ring := FSymbol^.Rendered^.rings;
  while Assigned(ring) do
  begin
    rInner := ring^.radius - ring^.line_width/2;
    rOuter := ring^.radius + ring^.line_width/2;
    ADrawer.DrawRing(ring^.x, ring^.y, rOuter, rInner);
    ring := ring^.Next;
  end;
  
  // Draw the hexagons
  hexagon := FSymbol^.Rendered^.hexagons;
  while Assigned(hexagon) do begin
    ADrawer.DrawHexagon(hexagon^.x, hexagon^.y, wx);
    hexagon := hexagon^.Next;
  end;
  
  // Finish drawing
  ADrawer.EndDrawing;
end;
  
class function TBarcodeMaxiCode.GetControlClassDefaultSize: TSize; 
begin
  Result.CX := 264;
  Result.CY := 257;
end;
  
function TBarcodeMaxiCode.InternalGenerate: Integer;
begin
  FSymbol^.option_1 := ord(FMode);
  if FMode in [mcmAuto, mcmMode2, mcmMode3] then
    FSymbol^.SetPrimary(FPrimary);

  Result := maxicode(FSymbol, UTF8ToISO_8859_1(FText));
end;

procedure TBarcodeMaxiCode.RenderSymbol(xLeft, yTop, ASymbolWidth, ASymbolHeight, 
  {%H-}ATextHeight, AFactor: Integer); 
var
  ring, last_ring: PZintRenderRing;
  hexagon, last_hexagon: PZintRenderHexagon;
  i, j: Integer;
  x, y: Double;
  xc, yc: Double;
  xFactor, yFactor, linewidth: Double;
begin
  xFactor := W_HEXAGON * AFactor;
  yFactor := H_HEXAGON * AFactor * 0.75;

  // Rings
  xc := xLeft + ASymbolWidth / 2 - xFactor*0.5;
  yc := yTop + ASymbolHeight / 2;
  last_ring := nil;
  // The radius coefficients are empirical values derived from Zint code
  linewidth := 0.8816 * xFactor;
  ring := render_plot_create_ring(xc, yc, 0.9659*xFactor, linewidth);   
  render_plot_add_ring(FSymbol, ring, @last_ring);
  ring := render_plot_create_ring(xc, yc, 2.500*xFactor, linewidth);
  render_plot_add_ring(FSymbol, ring, @last_ring);
  ring := render_plot_create_ring(xc, yc, 4.0227*xFactor, linewidth);
  render_plot_add_ring(FSymbol, ring, @last_ring);
  
  // Hexagons
  last_hexagon := nil;
  for j := 0 to FSymbol^.Rows - 1 do
  begin
    y := yFactor * (j + 1) + yTop;
    for i := 0 to FSymbol^.Width - 1 do
      if module_is_set(FSymbol, j, i) then
      begin
        if odd(j) then
          x := xFactor * (i + 2) + xLeft
        else
          x := xFactor * (i + 1.5) + xLeft;
        hexagon := render_plot_create_hexagon(x, y);
        render_plot_add_hexagon(FSymbol, hexagon, @last_hexagon);
      end;
  end;
  
  (*
  h := ASymbolHeight - 2 * yTop;
  w := h;
  xc := ASymbolHeight div 2;
  yc := ASymbolHeight div 2;
  
  ring := render_plot_create_ring(xc, yc, r, dr);
  

  scaler := GL_CONST;  // Converts from millimeters to the scale used by glabels
  render^.width := 28.16 * scaler;
  render^.height := 26.86 * scaler;
  
  // Central bullseye pattern
  ring := render_plot_create_ring (13.64 * scaler, 13.43 * scaler, 0.85 * scaler, 0.67 * scaler);
  render_plot_add_ring (symbol, ring, @last_ring);
  ring := render_plot_create_ring (13.64 * scaler, 13.43 * scaler, 2.20 * scaler, 0.67 * scaler);
  render_plot_add_ring (symbol, ring, @last_ring);
  ring := render_plot_create_ring (13.64 * scaler, 13.43 * scaler, 3.54 * scaler, 0.67 * scaler);
  render_plot_add_ring (symbol, ring, @last_ring);
  
  // Hexagons
  for r := 0 to symbol^.rows-1 do
  begin
    for i := 0 to symbol^.width-1 do
      if module_is_set(symbol,r, i) then
      begin
        if r and 1 <> 0 then
          hexagon := render_plot_create_hexagon((i*0.88 + 1.76) * scaler, (r*0.76 + 0.76)*scaler)
        else
          hexagon := render_plot_create_hexagon((i*0.88 + 1.32) * scaler, (r*0.76 + 0.76)*scaler);
      end;
  end; 
  *)
end;

procedure TBarcodeMaxicode.SetCountryCode(AValue: Integer);
begin
  if AValue = FCountryCode then exit;
  if (AValue > 0) and (AValue < 1000) then
  begin
    FCountryCode := AValue;
    if FMode in [mcmAuto, mcmMode2, mcmMode3] then
    begin
      FPrimary := BuildPrimary;
      GenerateAndInvalidate;
    end;
  end else
    raise Exception.Create('Maxicode country code must be > 0 and < 1000');
end;

procedure TBarcodeMaxicode.SetMode(AValue: TBarcodeMaxicodeMode);
begin
  if FMode = AValue then exit;
  FMode := AValue;
  if FMode in [mcmAuto, mcmMode2, mcmMode3] then
    FPrimary := BuildPrimary;
  GenerateAndInvalidate;
end;

procedure TBarcodeMaxicode.SetPostcode(AValue: String);
begin
  if AValue = FPostcode then exit;
  FPostcode := AValue;
  if FMode in [mcmAuto, mcmMode2, mcmMode3] then
  begin
    FPrimary := BuildPrimary;
    GenerateAndInvalidate;
  end;
end;

procedure TBarcodeMaxicode.SetPrimary(AValue: String);
begin
  if AValue = FPrimary then exit;
  FPrimary := AValue;
  FPostCode := Copy(FPrimary, 1, 9);
  FCountryCode := StrToIntDef(Copy(FPrimary, 10, 3), 0);
  FServiceCode := StrToIntDef(Copy(FPrimary, 13, 3), 0);
  if FMode = mcmAuto then
    GenerateAndInvalidate;
end;

procedure TBarcodeMaxicode.SetServiceCode(AValue: Integer);
begin
  if AValue = FServiceCode then exit;
  if (AValue > 0) and (AValue < 1000) then
  begin
    FServiceCode := AValue;
    if FMode in [mcmAuto, mcmMode2, mcmMode3] then
    begin
      FPrimary := BuildPrimary;
      GenerateAndInvalidate;
    end;
  end else
    raise Exception.Create('Maxicode Service code must be > 0 and < 1000');
end;

procedure TBarcodeMaxiCode.SetRecommendedSymbolSizeParams;
begin
  FScale := 4;
  FSymbolHeight := 0;
  FShowHumanReadableText := false;
end;

end.

