{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*            Graphics Utilities             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics;

{$I ACL.Config.inc}

interface

uses
  Winapi.GDIPAPI,
  Winapi.Windows,
  Winapi.Messages,
  // Vcl
{$IFNDEF ACL_BASE_NOVCL}
  Vcl.Controls,
{$ENDIF}
  Vcl.Graphics,
  // System
  System.Classes,
  System.Math,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // ACL
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

type
  TRGBQuadArray = array [0..0] of TRGBQuad;
  PRGBQuadArray = ^TRGBQuadArray;
  TRGBColors = array of TRGBQuad;

  TACLArrowKind = (makLeft, makRight, makTop, makBottom);

  TACLBitmapRotation = (br0, br90, br180, br270);

const
  acDropArrowSize: TSize = (cx: 7; cy: 3);
  acMeasureTextPattern = 'Qq';
  acEndEllipsis: string = '…';
  acFocusRectIndent = 1;
  acTextIndent = 2;

  acDragImageAlpha = 150;
  acDragImageColor = $8F2929;
  acHatchDefaultColor1 = clWhite;
  acHatchDefaultColor2 = $BFBFBF;
  acHatchDefaultSize = 8;

  acTextAlignHorz: array[TAlignment] of Integer = (DT_LEFT, DT_RIGHT, DT_CENTER);
  acTextAlignVert: array [TVerticalAlignment] of Integer = (DT_TOP, DT_BOTTOM, DT_VCENTER);

type

  { TACLColorSchema }

  TACLColorSchema = record
    Hue: Byte;
    HueIntensity: Byte;

    constructor Create(AHue: Byte; AHueIntensity: Byte = 100);
    class function CreateFromColor(AColor: TAlphaColor): TACLColorSchema; static;
    class function Default: TACLColorSchema; static;
    function IsAssigned: Boolean;

    class operator Equal(const C1, C2: TACLColorSchema): Boolean;
    class operator NotEqual(const C1, C2: TACLColorSchema): Boolean;
  end;

  { IACLColorSchema }

  IACLColorSchema = interface
  ['{19F1214B-9BE2-4E0A-B70C-28771671ABAF}']
    procedure ApplyColorSchema(const ASchema: TACLColorSchema);
  end;

type
  PAlphaColor = ^TAlphaColor;
  TAlphaColor = System.UITypes.TAlphaColor;
  PAlphaColorArray = ^TAlphaColorArray;
  TAlphaColorArray = array[0..0] of TAlphaColor;

  { TAlphaColorHelper }

  TAlphaColorHelper = record helper for TAlphaColor
  strict private type
    PARGB = ^TARGB;
    TARGB = array[0..3] of Byte;
  strict private
    function GetAlpha(const Index: Integer): Byte;
    function GetComponent(const Index: Integer): Byte;
    procedure SetComponent(const Index: Integer; const Value: Byte);
  public const
    None = TAlphaColor(0);
    Default = TAlphaColor($00010203);
    Black = TAlphaColor($FF000000);
    White = TAlphaColor($FFFFFFFF);
  public
    class function ApplyColorSchema(AColor: TAlphaColor; const ASchema: TACLColorSchema): TAlphaColor; static;
    class function FromARGB(const A, R, G, B: Byte): TAlphaColor; static;
    class function FromColor(const AColor: TColor; AAlpha: Byte = MaxByte): TAlphaColor; overload; static;
    class function FromColor(const AColor: TRGBQuad): TAlphaColor; overload; static;
    class function FromString(AColor: UnicodeString): TAlphaColor; static;
    function IsDefault: Boolean; inline;
    function IsValid: Boolean; inline;
    function ToColor: TColor;
    function ToQuad: TRGBQuad;
    function ToString: string;

    property A: Byte index 3 read GetAlpha write SetComponent;
    property R: Byte index 2 read GetComponent write SetComponent;
    property G: Byte index 1 read GetComponent write SetComponent;
    property B: Byte index 0 read GetComponent write SetComponent;
  end;

  { TFontHelper }

  TFontHelper = class helper for TFont
  public
    function Clone: TFont;
    procedure SetSize(ASize: Integer; ATargetDpi: Integer);
  end;

  { TACLColorList }

  TACLColorList = class(TACLList<TColor>);

  { TACLBitmap }

  TACLBitmap = class(TBitmap, IACLColorSchema)
  strict private
    FStretchMode: TACLStretchMode;

    function GetClientRect: TRect;
  public
    constructor CreateEx(const S: TSize; APixelFormat: TPixelFormat = pf32bit; AResetContent: Boolean = False); overload;
    constructor CreateEx(const R: TRect; APixelFormat: TPixelFormat = pf32bit; AResetContent: Boolean = False); overload;
    constructor CreateEx(W, H: Integer; APixelFormat: TPixelFormat = pf32bit; AResetContent: Boolean = False); overload;
    procedure Clear;
    procedure LoadFromResource(Inst: HINST; const AName, AType: UnicodeString);
    procedure LoadFromStream(Stream: TStream); override;
    procedure SetSizeEx(const R: TRect);
    // Drawing
    procedure DrawMargins(ACanvas: TCanvas; const ADest, AMargins: TRect); overload; virtual;
    procedure DrawMargins(ACanvas: TCanvas; const ADest, ASource, AMargins: TRect); overload; virtual;
    procedure DrawStretch(ACanvas: TCanvas; const ADest, ASource: TRect); overload; virtual;
    procedure DrawStretch(ACanvas: TCanvas; const ADest: TRect); overload; virtual;
    procedure DrawTo(ACanvas: TCanvas; X, Y: Integer); virtual;
    // Effects
    procedure ApplyColorSchema(const AValue: TACLColorSchema);
    procedure ChangeAlpha(AValue: Byte);
    procedure MakeDisabled;
    procedure MakeOpaque;
    procedure MakeTransparent(AColor: TColor);
    procedure Reset;
    procedure Rotate(ARotation: TACLBitmapRotation; AFlipVertically: Boolean = False);
    // Properties
    property ClientRect: TRect read GetClientRect;
    property StretchMode: TACLStretchMode read FStretchMode write FStretchMode;
  end;

  { TACLRegion }

  TACLRegionCombineFunc = (rcmOr, rcmAnd, rcmXor, rcmDiff, rcmCopy);

  TACLRegion = class
  strict private const
    CombineFuncMap: array[TACLRegionCombineFunc] of Integer = (RGN_OR, RGN_AND, RGN_XOR, RGN_DIFF, RGN_COPY);
  strict private
    FHandle: THandle;

    function GetBounds: TRect;
    function GetIsEmpty: Boolean;
    procedure FreeHandle;
    procedure SetHandle(const Value: THandle);
  public
    constructor Create; virtual;
    constructor CreateRect(const R: TRect);
    constructor CreateFromDC(DC: HDC);
    constructor CreateFromHandle(AHandle: HRGN);
    constructor CreateFromWindow(AWnd: HWND);
    destructor Destroy; override;
    //
    function Clone: THandle;
    function Contains(const P: TPoint): Boolean; overload; inline;
    function Contains(const R: TRect): Boolean; overload; inline;
    procedure Combine(ARegion: TACLRegion; ACombineFunc: TACLRegionCombineFunc; AFreeRegion: Boolean = False); overload;
    procedure Combine(const R: TRect; ACombineFunc: TACLRegionCombineFunc); overload;
    procedure Offset(X, Y: Integer);
    procedure Reset;
    procedure SetToWindow(AHandle: HWND; ARedraw: Boolean = True);
    //
    property Bounds: TRect read GetBounds;
    property Empty: Boolean read GetIsEmpty;
    property Handle: THandle read FHandle write SetHandle;
  end;

  { TACLRegionData }

  TACLRegionData = class
  strict private
    FCount: Integer;
    FData: PRgnData;
    FDataSize: Integer;

    function GetRect(Index: Integer): TRect;
    procedure SetRect(Index: Integer; const R: TRect);
    procedure SetRectsCount(AValue: Integer);
    procedure DataAllocate(ARectsCount: Integer);
    procedure DataFree;
  public
    constructor Create(ACount: Integer); virtual;
    destructor Destroy; override;
    function CreateHandle: HRGN; overload;
    function CreateHandle(const ARegionBounds: TRect): HRGN; overload;
    //
    property Data: PRgnData read FData;
    property Rects[Index: Integer]: TRect read GetRect write SetRect;
    property RectsCount: Integer read FCount write SetRectsCount;
  end;

  { TACLBitmapBits }

  TACLBitmapBits = class
  strict private
    FDIB: TDIBSection;
    FValid: Boolean;

    function GetBits: Integer;
    function GetRow(ARow: Integer): Pointer;
  protected
    procedure ReadColors24(var AColors: TRGBColors);
    procedure ReadColors32(var AColors: TRGBColors);
    procedure WriteColors24(const AColors: TRGBColors);
    procedure WriteColors32(const AColors: TRGBColors);
  public
    constructor Create(ABitmapHandle: THandle);
    //
    function ReadColors(out AColors: TRGBColors): Boolean;
    function WriteColors(const AColors: TRGBColors): Boolean;
    //
    property Bits: Integer read GetBits;
    property Row[Index: Integer]: Pointer read GetRow;
    property Valid: Boolean read FValid;
  end;

  { TACLScreenCanvas }

  TACLScreenCanvas = class(TCanvas)
  strict private
    FDeviceContext: HDC;
  protected
    procedure CreateHandle; override;
    procedure FreeHandle;
  public
    destructor Destroy; override;
    procedure Release;
  end;

  { TACLMeasureCanvas }

  TACLMeasureCanvas = class(TCanvas)
  strict private
    FBitmap: TBitmap;
  protected
    procedure CreateHandle; override;
    procedure FreeHandle;
  public
    destructor Destroy; override;
  end;

  PACLPixelMap = ^TACLPixelMap;
  TACLPixelMap = array[Byte, Byte] of Byte;

  { TACLColors }

  TACLColors = class
  public const
    MaskPixel: TRGBQuad = (rgbBlue: 255; rgbGreen: 0; rgbRed: 255; rgbReserved: 0); // clFuchsia
    NullPixel: TRGBQuad = (rgbBlue: 0; rgbGreen: 0; rgbRed: 0; rgbReserved: 0);
  public class var
    PremultiplyTable: TACLPixelMap;
    UnpremultiplyTable: TACLPixelMap;
  public
    class constructor Create;
    class function CompareRGB(const Q1, Q2: TRGBQuad): Boolean; inline; static;
    class function IsDark(Color: TColor): Boolean;
    class function IsMask(const Q: TRGBQuad): Boolean; inline; static;
    class function ToColor(const Q: TRGBQuad): TColor; static;
    class function ToQuad(A, R, G, B: Byte): TRGBQuad; overload; static; inline;
    class function ToQuad(AColor: TAlphaColor): TRGBQuad; overload; static;
    class function ToQuad(AColor: TColor; AAlpha: Byte = MaxByte): TRGBQuad; overload; static;

    class procedure AlphaBlend(var D: TColor; S: TColor; AAlpha: Integer = 255); overload; inline; static;
    class procedure AlphaBlend(var D: TRGBQuad; const S: TRGBQuad; AAlpha: Integer = 255; AProcessPerChannelAlpha: Boolean = True); overload; inline; static;
    class procedure ApplyColorSchema(AColors: PRGBQuad; ACount: Integer; const AValue: TACLColorSchema); overload; inline; static;
    class procedure ApplyColorSchema(const AFont: TFont; const AValue: TACLColorSchema); overload;
    class procedure ApplyColorSchema(var AColor: TAlphaColor; const AValue: TACLColorSchema); overload;
    class procedure ApplyColorSchema(var AColor: TColor; const AValue: TACLColorSchema); overload;
    class procedure ApplyColorSchema(var AColor: TRGBQuad; const AValue: TACLColorSchema); overload;
    class function ArePremultiplied(AColors: PRGBQuad; ACount: Integer): Boolean;
    class procedure Flip(AColors: PRGBQuadArray; AWidth, AHeight: Integer; AHorizontally, AVertically: Boolean);
    class procedure Flush(var Q: TRGBQuad); inline; static;
    class procedure Grayscale(Q: PRGBQuad; Count: Integer; IgnoreMask: Boolean = False); overload; static;
    class procedure Grayscale(var Q: TRGBQuad; IgnoreMask: Boolean = False); overload; inline; static;
    class function Hue(Color: TColor): Single; overload; static;
    class function Invert(Color: TColor): TColor; static;
    class function Lightness(Color: TColor): Single; overload; static;
    class procedure MakeDisabled(Q: PRGBQuad; Count: Integer; IgnoreMask: Boolean = False); overload; static;
    class procedure MakeDisabled(var Q: TRGBQuad; IgnoreMask: Boolean = False); overload; inline; static;
    class procedure MakeTransparent(Q: PRGBQuad; ACount: Integer; const AColor: TRGBQuad); overload;
    class procedure Premultiply(Q: PRGBQuad; ACount: Integer); overload; static;
    class procedure Premultiply(var Q: TRGBQuad); overload; inline; static;
    class procedure Unpremultiply(Q: PRGBQuad; ACount: Integer); overload; static;
    class procedure Unpremultiply(var Q: TRGBQuad); overload; inline; static;

    // Coloration
    // Pixels must be unpremultiplied
    class procedure ChangeColor(Q: PRGBQuad; ACount: Integer; const AColor: TRGBQuad); static;
    class procedure ChangeHue(Q: PRGBQuad; ACount: Integer; AHue: Byte; AIntensity: Byte = 100); overload; static;
    class procedure ChangeHue(var Q: TRGBQuad; AHue: Byte; AIntensity: Byte = 100); overload; inline; static;
    class procedure Tint(Q: PRGBQuad; ACount: Integer; const ATintColor: TRGBQuad); overload; static;

    // RGB <-> HSL
    class function HSLtoRGB(H, S, L: Single): TColor; overload;
    class procedure HSLtoRGB(H, S, L: Single; out AColor: TColor); overload;
    class procedure HSLtoRGB(H, S, L: Single; out R, G, B: Byte); overload;
    class procedure HSLtoRGBi(H, S, L: Byte; out AColor: TColor); overload;
    class procedure HSLtoRGBi(H, S, L: Byte; out R, G, B: Byte); overload;
    class procedure RGBtoHSL(AColor: TColor; out H, S, L: Single); overload;
    class procedure RGBtoHSL(R, G, B: Byte; out H, S, L: Single); overload;
    class procedure RGBtoHSLi(AColor: TColor; out H, S, L: Byte); overload;
    class procedure RGBtoHSLi(R, G, B: Byte; out H, S, L: Byte); overload;

    // RGB <-> HSV
    class function HSVtoRGB(H, S, V: Single): TColor; overload;
    class procedure HSVtoRGB(H, S, V: Single; out AColor: TColor); overload;
    class procedure HSVtoRGB(H, S, V: Single; out R, G, B: Byte); overload;
    class procedure RGBtoHSV(AColor: TColor; out H, S, V: Single); overload;
    class procedure RGBtoHSV(R, G, B: Byte; out H, S, V: Single); overload;
  end;

  { TACLRegionManager }

  TACLRegionManager = class
  strict private const
    CacheSize = 8;
  strict private
    class var Cache: array[0..Pred(CacheSize)] of HRGN;
  public
    class destructor Finalize;
    class function Get: HRGN; inline;
    class procedure Release(var ARegion: HRGN); inline;
  end;

// acAlphaBlend
procedure acAlphaBlend(Dest, Src: HDC; const DR, SR: TRect; AAlpha: Integer = 255; AUseSourceAlpha: Boolean = True); overload;
procedure acAlphaBlend(Dest: HDC; ABitmap: TBitmap; const DR: TRect; AAlpha: Integer = 255; AUseSourceAlpha: Boolean = True); overload;
procedure acAlphaBlend(Dest: HDC; ABitmap: TBitmap; const DR, SR: TRect; AAlpha: Integer = 255; AUseSourceAlpha: Boolean = True); overload;
procedure acUpdateLayeredWindow(Wnd: THandle; SrcDC: HDC; const R: TRect; AAlpha: Integer = 255); overload;

// DoubleBuffer
function acCreateMemDC(ASourceDC: HDC; const R: TRect; out AMemBmp: HBITMAP; out AClipRegion: HRGN): HDC;
procedure acDeleteMemDC(AMemDC: HDC; AMemBmp: HBITMAP; AClipRegion: HRGN);

// GDI
procedure acBitBlt(DC, SourceDC: HDC; const R: TRect; const APoint: TPoint); overload; inline;
procedure acBitBlt(DC: HDC; ABitmap: TBitmap; const ADestPoint: TPoint); overload; inline;
procedure acBitBlt(DC: HDC; ABitmap: TBitmap; const R: TRect; const APoint: TPoint); overload; inline;
procedure acDrawArrow(DC: HDC; R: TRect; AColor: TColor; AArrowKind: TACLArrowKind; ATargetDPI: Integer);
function acGetArrowSize(AArrowKind: TACLArrowKind; ATargetDPI: Integer): TSize;
procedure acDrawComplexFrame(DC: HDC; const R: TRect; AColor1, AColor2: TColor; ABorders: TACLBorders = acAllBorders); overload;
procedure acDrawComplexFrame(DC: HDC; const R: TRect; AColor1, AColor2: TAlphaColor; ABorders: TACLBorders = acAllBorders); overload;
procedure acDrawColorPreview(ACanvas: TCanvas; R: TRect; AColor: TAlphaColor); overload;
procedure acDrawColorPreview(ACanvas: TCanvas; R: TRect; AColor: TAlphaColor; ABorderColor, AHatchColor1, AHatchColor2: TColor); overload;
procedure acDrawDotsLineH(DC: HDC; X1, X2, Y: Integer; AColor: TColor);
procedure acDrawDotsLineV(DC: HDC; X, Y1, Y2: Integer; AColor: TColor);
procedure acDrawDragImage(ACanvas: TCanvas; const R: TRect; AAlpha: Byte = acDragImageAlpha);
procedure acDrawDropArrow(DC: HDC; const R: TRect; AColor: TColor); overload;
procedure acDrawDropArrow(DC: HDC; const R: TRect; AColor: TColor; const AArrowSize: TSize); overload;
procedure acDrawExpandButton(DC: HDC; const R: TRect; ABorderColor, AColor: TColor; AExpanded: Boolean);
procedure acDrawFocusRect(ACanvas: TCanvas; const R: TRect); overload;
procedure acDrawFocusRect(DC: HDC; const R: TRect; AColor: TColor); overload;
procedure acDrawFrame(DC: HDC; ARect: TRect; AColor: TColor; AThickness: Integer = 1); overload;
procedure acDrawFrame(DC: HDC; ARect: TRect; AColor: TAlphaColor; AThickness: Integer = 1); overload;
procedure acDrawFrameEx(DC: HDC; const ARect: TRect; AColor: TColor; ABorders: TACLBorders; AThickness: Integer = 1); overload;
procedure acDrawFrameEx(DC: HDC; ARect: TRect; AColor: TAlphaColor; ABorders: TACLBorders; AThickness: Integer = 1); overload;
procedure acDrawGradient(DC: HDC; const ARect: TRect; AFrom, ATo: TColor; AVertical: Boolean = True); overload;
procedure acDrawGradient(DC: HDC; const ARect: TRect; AFrom, ATo: TAlphaColor; AVertical: Boolean = True); overload;
procedure acDrawHatch(DC: HDC; const R: TRect); overload;
procedure acDrawHatch(DC: HDC; const R: TRect; AColor1, AColor2: TColor; ASize: Integer); overload;
procedure acDrawHueColorBar(ACanvas: TCanvas; const R: TRect);
procedure acDrawHueIntensityBar(ACanvas: TCanvas; const R: TRect; AHue: Byte = 0);
procedure acDrawSelectionRect(DC: HDC; const R: TRect; AColor: TAlphaColor);
procedure acDrawShadow(ACanvas: TCanvas; const ARect: TRect; ABKColor: TColor; AShadowSize: Integer = 5);
{$IFNDEF ACL_BASE_NOVCL}
procedure acDrawTransparentControlBackground(AControl: TWinControl; DC: HDC; R: TRect; APaintWithChildren: Boolean = True);
{$ENDIF}
procedure acFillRect(DC: HDC; const ARect: TRect; AColor: TAlphaColor); overload;
procedure acFillRect(DC: HDC; const ARect: TRect; AColor: TColor); overload;
procedure acFitFileName(ACanvas: TCanvas; ATargetWidth: Integer; var S: UnicodeString);
procedure acResetFont(AFont: TFont);
procedure acResetRect(DC: HDC; const R: TRect); inline;
procedure acStretchBlt(DC, SourceDC: HDC; const ADest, ASource: TRect); inline;
procedure acStretchDraw(DC, SourceDC: HDC; const ADest, ASource: TRect; AMode: TACLStretchMode);
procedure acTileBlt(DC, SourceDC: HDC; const ADest, ASource: TRect);
function acHatchCreatePattern(ASize: Integer; AColor1, AColor2: TColor): TBitmap;

// Clippping
function acCombineWithClipRegion(DC: HDC; ARegion: HRGN; AOperation: Integer; AConsiderWindowOrg: Boolean = True): Boolean;
procedure acExcludeFromClipRegion(DC: HDC; const R: TRect); overload; inline;
procedure acExcludeFromClipRegion(DC: HDC; ARegion: HRGN; AConsiderWindowOrg: Boolean = True); overload; inline;
function acIntersectClipRegion(DC: HDC; const R: TRect): Boolean; overload; inline;
function acIntersectClipRegion(DC: HDC; ARegion: HRGN; AConsiderWindowOrg: Boolean = True): Boolean; overload; inline;
function acRectVisible(DC: HDC; const R: TRect): Boolean; inline;
procedure acRestoreClipRegion(DC: HDC; ARegion: HRGN); inline;
function acSaveClipRegion(DC: HDC): HRGN; inline;

// Regions
function acRegionClone(ARegion: HRGN): HRGN;
function acRegionCombine(ATarget, ASource: HRGN; AOperation: Integer): Integer; overload;
function acRegionCombine(ATarget: HRGN; const ASource: TRect; AOperation: Integer): Integer; overload;
procedure acRegionFree(var ARegion: HRGN); inline;
function acRegionFromBitmap(ABitmap: TBitmap): HRGN; overload;
function acRegionFromBitmap(AColors: PRGBQuad; AWidth, AHeight: Integer; ATransparentColor: TColor): HRGN; overload;

// WindowOrg
function acMoveWindowOrg(DC: HDC; const P: TPoint): TPoint; overload; inline;
function acMoveWindowOrg(DC: HDC; DX, DY: Integer): TPoint; overload;
procedure acRegionMoveToWindowOrg(DC: HDC; ARegion: THandle); inline;
procedure acRestoreWindowOrg(DC: HDC; const P: TPoint); inline;

// WorldTransform
procedure acWorldTransformFlip(DC: HDC; const AArea: TRect;
  AFlipHorizontally, AFlipVertically: Boolean; APrevWorldTransform: PXForm); overload;
procedure acWorldTransformFlip(DC: HDC; const APivotPoint: TPointF;
  AFlipHorizontally, AFlipVertically: Boolean; APrevWorldTransform: PXForm); overload;

// Bitmaps
procedure acFillBitmapInfoHeader(out AHeader: TBitmapInfoHeader; AWidth, AHeight: Integer);
function acGetBitmapBits(ABitmap: TBitmap): TRGBColors; overload;
procedure acGetBitmapBits(ABitmap: THandle; AWidth, AHeight: Integer; out AColors: TRGBColors; out ABitmapInfo: TBitmapInfo); overload;
procedure acSetBitmapBits(ABitmap: TBitmap; var AColors: TRGBColors);

// Colors
procedure acApplyColorSchema(AObject: TObject; const AColorSchema: TACLColorSchema); inline;
procedure acBuildColorPalette(ATargetList: TACLColorList; ABaseColor: TColor);
function acGetActualColor(AColor, ADefaultColor: TAlphaColor): TAlphaColor; overload;
function acGetActualColor(AColor, ADefaultColor: TColor): TColor; overload;
function ColorToString(AColor: TColor): UnicodeString;
function StringToColor(AColor: UnicodeString): TColor;

// Unicode Text
function acFontHeight(Canvas: TCanvas): Integer; overload;
function acFontHeight(Font: TFont): Integer; overload;

function acTextSize(ACanvas: TCanvas; const AText: PWideChar; ALength: Integer): TSize; overload;
function acTextSize(ACanvas: TCanvas; const AText: UnicodeString; AStartIndex: Integer = 1; ALength: Integer = MaxInt): TSize; overload;
function acTextSize(Font: TFont; const AText: UnicodeString; AStartIndex: Integer = 1; ALength: Integer = MaxInt): TSize; overload;
function acTextSize(Font: TFont; const AText: PWideChar; ALength: Integer): TSize; overload;
function acTextSizeMultiline(ACanvas: TCanvas; const AText: UnicodeString; AMaxWidth: Integer = 0): TSize;

function acAlignText(const R: TRect; const ATextSize: TSize; AHorzAlignment: TAlignment;
  AVertAlignment: TVerticalAlignment; APreventTopLeftExceed: Boolean = False): TPoint;
function acTextPrepare(ACanvas: TCanvas; const R: TRect; AEndEllipsis: Boolean; AHorzAlignment: TAlignment;
  AVertAlignment: TVerticalAlignment; var AText: UnicodeString; out ATextSize: TSize; out ATextOffset: TPoint): Integer; overload;
function acTextPrepare(ACanvas: TCanvas; const R: TRect; AEndEllipsis: Boolean; AHorzAlignment: TAlignment;
  AVertAlignment: TVerticalAlignment; var AText: UnicodeString; out ATextSize: TSize; out ATextOffset: TPoint;
  const ATextExtends: TRect; APreventTopLeftExceed: Boolean = False): Integer; overload;

procedure acTextDraw(ACanvas: TCanvas; const S: UnicodeString; const R: TRect;
  AHorzAlignment: TAlignment = taLeftJustify; AVertAlignment: TVerticalAlignment = taAlignTop;
  AEndEllipsis: Boolean = False; APreventTopLeftExceed: Boolean = False; AWordWrap: Boolean = False);
procedure acTextDrawHighlight(ACanvas: TCanvas; const S: UnicodeString; const R: TRect;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AEndEllipsis: Boolean;
  AHighlightStart, AHighlightFinish: Integer; AHighlightColor, AHighlightTextColor: TColor);
procedure acTextDrawVertical(ACanvas: TCanvas; const S: UnicodeString; const R: TRect; AHorzAlignment: TAlignment;
  AVertAlignment: TVerticalAlignment; AEndEllipsis: Boolean = False); overload;
procedure acTextOut(ACanvas: TCanvas; X, Y: Integer; const S: UnicodeString; AFlags: Integer; ARect: PRect = nil); inline;

procedure acSysDrawText(ACanvas: TCanvas; var R: TRect; const AText: UnicodeString; AFlags: Cardinal);

// Screen
function MeasureCanvas: TACLMeasureCanvas;
function ScreenCanvas: TACLScreenCanvas;
implementation

uses
  System.StrUtils,
  // ACL
  ACL.FastCode,
  ACL.Math,
  ACL.Graphics.Ex,
  ACL.Graphics.Ex.Gdip,
  ACL.Utils.Strings,
  ACL.Utils.DPIAware;

type
  TBitmapAccess = class(TBitmap);

//#AI: Check the definition of Hacked classes in new version of Delphi
{$IF (CompilerVersion >= 24) AND (CompilerVersion <= 30)}

  TBitmapImageHack = class(TSharedImage)
  private
    FHandle: HBITMAP;     // DDB or DIB handle, used for drawing
    FMaskHandle: HBITMAP; // DDB handle
    FPalette: HPALETTE;
    FDIBHandle: HBITMAP;  // DIB handle corresponding to TDIBSection
    FDIB: TDIBSection;
  public
    property Handle: HBITMAP read FHandle;
    property MaskHandle: HBITMAP read FMaskHandle;
    property Palette: HPALETTE read FPalette;
    property DIBHandle: HBITMAP read FDIBHandle;
    property DIB: TDIBSection read FDIB;
  end;

  TBitmapHack = class(TGraphic)
  private
    FImage: TBitmapImageHack;
  public
    property Image: TBitmapImageHack read FImage;
  end;
{$ELSE}
{$IF CompilerVersion >= 31}
  TBitmapHack = class(TBitmap);
  TBitmapImageHack = class(TBitmapImage);
{$IFEND}
{$IFEND}

  PRectArray = ^TRectArray;
  TRectArray = array [0..0] of TRect;

var
  FMeasureCanvas: TACLMeasureCanvas = nil;
  FScreenCanvas: TACLScreenCanvas = nil;

procedure acApplyColorSchema(AObject: TObject; const AColorSchema: TACLColorSchema);
var
  ASchema: IACLColorSchema;
begin
  if Supports(AObject, IACLColorSchema, ASchema) then
    ASchema.ApplyColorSchema(AColorSchema)
end;

procedure acBuildColorPalette(ATargetList: TACLColorList; ABaseColor: TColor);
const
  BasePalette: array [0..6] of Single = (0.61, 0.99, 0.74, 0.35, 0.9, 0.08, 0.55);

  procedure DoBuild(ATargetList: TACLColorList; ALightnessDelta: Single);
  var
    H, S, L: Single;
    I: Integer;
  begin
    TACLColors.RGBtoHSL(ABaseColor, H, S, L);
    L := EnsureRange(L, 0.4, 0.8);
    S := Max(S, 0.4);
    L := EnsureRange(L + ALightnessDelta, 0.2, 0.9);
    for I := 0 to Length(BasePalette) - 1 do
      ATargetList.Add(TACLColors.HSLtoRGB(BasePalette[I], S, L));
  end;

begin
  ATargetList.Count := 0;
  ATargetList.Capacity := Length(BasePalette) * 3;
  DoBuild(ATargetList, 0);
  DoBuild(ATargetList, -0.15);
  DoBuild(ATargetList, 0.15);
end;

function acGetActualColor(AColor, ADefaultColor: TAlphaColor): TAlphaColor;
begin
  if AColor.IsDefault then
    Result := ADefaultColor
  else
    Result := AColor;
end;

function acGetActualColor(AColor, ADefaultColor: TColor): TColor;
begin
  if AColor = clDefault then
    Result := ADefaultColor
  else
    Result := AColor;
end;

function ColorToString(AColor: TColor): UnicodeString;
begin
  if AColor = clNone then
    Result := 'None'
  else
    if AColor = clDefault then
      Result := 'Default'
    else
      Result :=
        IntToHex(GetRValue(AColor), 2) +
        IntToHex(GetGValue(AColor), 2) +
        IntToHex(GetBValue(AColor), 2);
end;

function StringToColor(AColor: UnicodeString): TColor;

  function RemoveInvalidChars(const AColor: UnicodeString): UnicodeString;
  var
    I: Integer;
  begin
    Result := acLowerCase(AColor);
    for I := Length(Result) downto 1 do
    begin
      if not CharInSet(Result[I], ['0'..'9', 'a'..'f']) then
        Delete(Result, I, 1);
    end;
  end;

begin
  Result := clNone;
  if not (IdentToColor(AColor, LongInt(Result)) or (IdentToColor('cl' + AColor, LongInt(Result)))) then
  begin
    AColor := RemoveInvalidChars(AColor);
    AColor := acDupeString('0', Length(AColor) mod 2) + AColor;
    AColor := AColor + acDupeString('0', 6 - Length(AColor));
    Result := RGB(
      TACLHexCode.Decode(AColor[1], AColor[2]),
      TACLHexCode.Decode(AColor[3], AColor[4]),
      TACLHexCode.Decode(AColor[5], AColor[6]));
  end;
end;

{$IFNDEF ACL_BASE_NOVCL}
procedure acDrawTransparentControlBackground(AControl: TWinControl; DC: HDC; R: TRect; APaintWithChildren: Boolean = True);

  procedure DrawControl(DC: HDC; AControl: TWinControl);
  begin
    if IsWindowVisible(AControl.Handle) then
    begin
      AControl.ControlState := AControl.ControlState + [csPaintCopy];
      try
        AControl.Perform(WM_ERASEBKGND, DC, DC);
        AControl.Perform(WM_PAINT, DC, 0);
      finally
        AControl.ControlState := AControl.ControlState - [csPaintCopy];
      end;
    end;
  end;

  procedure PaintControlTo(ADrawControl: TWinControl; AOffsetX, AOffsetY: Integer; R: TRect);
  var
    AChildControl: TControl;
    I: Integer;
  begin
    MoveWindowOrg(DC, AOffsetX, AOffsetY);
    try
      if not RectVisible(DC, R) then
        Exit;

      DrawControl(DC, ADrawControl);
      if APaintWithChildren then
      begin
        for I := 0 to ADrawControl.ControlCount - 1 do
        begin
          AChildControl := ADrawControl.Controls[I];
          if (AChildControl = AControl) and AControl.Visible then
            Break;
          if (AChildControl is TWinControl) and AChildControl.Visible then
          begin
            R := AChildControl.BoundsRect;
            OffsetRect(R, -R.Left, -R.Top);
            PaintControlTo(TWinControl(AChildControl),
              AChildControl.Left, AChildControl.Top, R);
          end;
        end;
      end;
    finally
      MoveWindowOrg(DC, -AOffsetX, -AOffsetY);
    end;
  end;

var
  AParentControl: TWinControl;
  ASaveIndex: Integer;
begin
  AParentControl := AControl.Parent;
  if (AParentControl = nil) and (AControl.ParentWindow <> 0) then
  begin
    AParentControl := FindControl(AControl.ParentWindow);
    APaintWithChildren := False;
  end;
  if Assigned(AParentControl) then
  begin
    ASaveIndex := SaveDC(DC);
    try
      acIntersectClipRegion(DC, R);
      OffsetRect(R, AControl.Left, AControl.Top);
      PaintControlTo(AParentControl, -R.Left, -R.Top, R);
    finally
      RestoreDC(DC, ASaveIndex);
    end;
  end;
end;
{$ENDIF}

procedure acFitFileName(ACanvas: TCanvas; ATargetWidth: Integer; var S: UnicodeString);
const
 CollapsedPath = '...';
var
  APos: Integer;
  APosPrev: Integer;
begin
  APosPrev := acPos(PathDelim, S);
  while ACanvas.TextWidth(S) > ATargetWidth do
  begin
    APos := Pos(PathDelim, S, APosPrev + 1);
    if APos = 0 then
      Break;
    S := Copy(S, 1, APosPrev) + CollapsedPath + Copy(S, APos, MaxInt);
    Inc(APosPrev, Length(CollapsedPath) + 1);
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// Clipping
//----------------------------------------------------------------------------------------------------------------------

function acCombineWithClipRegion(DC: HDC; ARegion: HRGN; AOperation: Integer; AConsiderWindowOrg: Boolean = True): Boolean;
var
  AClipRegion: HRGN;
  AOrigin: TPoint;
begin
  AClipRegion := CreateRectRgnIndirect(NullRect);
  try
    GetClipRgn(DC, AClipRegion);

    if AConsiderWindowOrg then
    begin
      GetWindowOrgEx(DC, AOrigin);
      OffsetRgn(ARegion, -AOrigin.X, -AOrigin.Y);
      CombineRgn(AClipRegion, AClipRegion, ARegion, AOperation);
      OffsetRgn(ARegion, AOrigin.X, AOrigin.Y);
    end
    else
      CombineRgn(AClipRegion, AClipRegion, ARegion, AOperation);

    Result := SelectClipRgn(DC, AClipRegion) <> NULLREGION;
  finally
    DeleteObject(AClipRegion);
  end;
end;

procedure acExcludeFromClipRegion(DC: HDC; const R: TRect);
begin
  ExcludeClipRect(DC, R.Left, R.Top, R.Right, R.Bottom);
end;

procedure acExcludeFromClipRegion(DC: HDC; ARegion: HRGN; AConsiderWindowOrg: Boolean = True);
begin
  acCombineWithClipRegion(DC, ARegion, RGN_DIFF, AConsiderWindowOrg);
end;

function acIntersectClipRegion(DC: HDC; const R: TRect): Boolean;
begin
  Result := IntersectClipRect(DC, R.Left, R.Top, R.Right, R.Bottom) <> NULLREGION;
end;

function acIntersectClipRegion(DC: HDC; ARegion: HRGN; AConsiderWindowOrg: Boolean = True): Boolean;
begin
  Result := acCombineWithClipRegion(DC, ARegion, RGN_AND, AConsiderWindowOrg);
end;

function acRectVisible(DC: HDC; const R: TRect): Boolean;
begin
  Result := not R.IsEmpty and Winapi.Windows.RectVisible(DC, R);
end;

procedure acRestoreClipRegion(DC: HDC; ARegion: HRGN);
begin
  SelectClipRgn(DC, ARegion);
  TACLRegionManager.Release(ARegion);
end;

function acSaveClipRegion(DC: HDC): HRGN;
begin
  Result := TACLRegionManager.Get;
  if GetClipRgn(DC, Result) = 0 then
  begin
    TACLRegionManager.Release(Result);
    Result := 0;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// Regions
//----------------------------------------------------------------------------------------------------------------------

function acRegionClone(ARegion: HRGN): HRGN;
begin
  Result := CreateRectRgnIndirect(NullRect);
  CombineRgn(Result, Result, ARegion, RGN_COPY);
end;

function acRegionCombine(ATarget, ASource: HRGN; AOperation: Integer): Integer;
begin
  Result := CombineRgn(ATarget, ATarget, ASource, AOperation);
end;

function acRegionCombine(ATarget: HRGN; const ASource: TRect; AOperation: Integer): Integer;
var
  ASourceRgn: HRGN;
begin
  ASourceRgn := CreateRectRgnIndirect(ASource);
  try
    Result := acRegionCombine(ATarget, ASourceRgn, AOperation);
  finally
    DeleteObject(ASourceRgn);
  end;
end;

procedure acRegionFree(var ARegion: HRGN);
begin
  if ARegion <> 0 then
  begin
    DeleteObject(ARegion);
    ARegion := 0;
  end;
end;

function acRegionFromBitmap(ABitmap: TBitmap): HRGN;
var
  AColors: TRGBColors;
begin
  AColors := acGetBitmapBits(ABitmap);
  Result := acRegionFromBitmap(@AColors[0], ABitmap.Width, ABitmap.Height,
    IfThen(ABitmap.PixelFormat = pf1bit, clWhite, clFuchsia));
end;

function acRegionFromBitmap(AColors: PRGBQuad; AWidth, AHeight: Integer; ATransparentColor: TColor): HRGN;

  procedure FlushRegion(X, Y: Integer; var ACount: Integer; var ACombined: HRGN);
  var
    ARgn: HRGN;
  begin
    if ACount > 0 then
    begin
      ARgn := CreateRectRgn(X - ACount, Y, X, Y + 1);
      if ACombined = 0 then
        ACombined := ARgn
      else
      begin
        CombineRgn(ACombined, ACombined, ARGN, RGN_OR);
        DeleteObject(ARgn);
      end;
      ACount := 0;
    end;
  end;

var
  ACount: Integer;
  ATransparent: TRGBQuad;
  X, Y: Integer;
begin
  Result := 0;
  ATransparent.rgbBlue := GetBValue(ATransparentColor);
  ATransparent.rgbGreen := GetGValue(ATransparentColor);
  ATransparent.rgbRed := GetRValue(ATransparentColor);
  for Y := 0 to AHeight - 1 do
  begin
    ACount := 0;
    for X := 0 to AWidth - 1 do
    begin
      if TACLColors.CompareRGB(AColors^, ATransparent) then
        FlushRegion(X, Y, ACount, Result)
      else
        Inc(ACount);

      Inc(AColors);
    end;
    FlushRegion(AWidth, Y, ACount, Result);
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// Window Org
//----------------------------------------------------------------------------------------------------------------------

function acMoveWindowOrg(DC: HDC; const P: TPoint): TPoint;
begin
  Result := acMoveWindowOrg(DC, P.X, P.Y);
end;

function acMoveWindowOrg(DC: HDC; DX, DY: Integer): TPoint;
begin
  GetWindowOrgEx(DC, Result);
  SetWindowOrgEx(DC, Result.X - DX, Result.Y - DY, nil);
end;

procedure acRegionMoveToWindowOrg(DC: HDC; ARegion: THandle);
var
  P: TPoint;
begin
  if GetWindowOrgEx(DC, P) then
    OffsetRgn(ARegion, -P.X, -P.Y);
end;

procedure acRestoreWindowOrg(DC: HDC; const P: TPoint);
begin
  SetWindowOrgEx(DC, P.X, P.Y, nil);
end;

//----------------------------------------------------------------------------------------------------------------------
// TextDraw Utilities
//----------------------------------------------------------------------------------------------------------------------

function acAlignText(const R: TRect; const ATextSize: TSize; AHorzAlignment: TAlignment;
  AVertAlignment: TVerticalAlignment; APreventTopLeftExceed: Boolean = False): TPoint;
begin
  case AVertAlignment of
    taAlignTop:
      Result.Y := R.Top;
    taAlignBottom:
      Result.Y := (R.Bottom - ATextSize.cy);
  else
    Result.Y := (R.Bottom + R.Top - ATextSize.cy) div 2;
  end;
  if APreventTopLeftExceed then
    Result.Y := Max(Result.Y, R.Top);

  case AHorzAlignment of
    taRightJustify:
      Result.X := (R.Right - ATextSize.cx);
    taCenter:
      Result.X := (R.Right + R.Left - ATextSize.cx) div 2;
  else
    Result.X := R.Left;
  end;
  if APreventTopLeftExceed then
    Result.X := Max(Result.X, R.Left);
end;

function acFontHeight(Canvas: TCanvas): Integer;
begin
  Result := acTextSize(Canvas, acMeasureTextPattern).cy;
end;

function acFontHeight(Font: TFont): Integer;
begin
  Result := acTextSize(Font, acMeasureTextPattern).cy;
end;

function acTextSize(Font: TFont; const AText: UnicodeString; AStartIndex, ALength: Integer): TSize;
begin
  MeasureCanvas.Font := Font;
  Result := acTextSize(MeasureCanvas, AText, AStartIndex, ALength);
end;

function acTextSize(Font: TFont; const AText: PWideChar; ALength: Integer): TSize;
begin
  MeasureCanvas.Font := Font;
  Result := acTextSize(MeasureCanvas, AText, ALength);
end;

function acTextSize(ACanvas: TCanvas; const AText: PWideChar; ALength: Integer): TSize; overload;
var
  AMetrics: TTextMetricW;
begin
  if ALength <= 0 then
    Exit(NullSize);

  GetTextExtentPoint32W(ACanvas.Handle, AText, ALength, Result);

  //# https://forums.embarcadero.com/thread.jspa?messageID=667590&tstart=0
  //# https://github.com/virtual-treeview/virtual-treeview/issues/465
  GetTextMetricsW(ACanvas.Handle, AMetrics);
  if IsWine or (AMetrics.tmItalic <> 0) then
    Inc(Result.cx, AMetrics.tmAveCharWidth div 2);
end;

function acTextSize(ACanvas: TCanvas; const AText: UnicodeString; AStartIndex, ALength: Integer): TSize;
begin
  ALength := MaxMin(ALength, 0, Length(AText) - AStartIndex + 1);
  if ALength > 0 then
    Result := acTextSize(ACanvas, @AText[AStartIndex], ALength)
  else
    Result := NullSize;
end;

function acTextSizeMultiline(ACanvas: TCanvas; const AText: UnicodeString; AMaxWidth: Integer = 0): TSize;
var
  ATextRect: TRect;
begin
  ATextRect := Rect(0, 0, AMaxWidth, 2);
  acSysDrawText(ACanvas, ATextRect, AText, DT_CALCRECT or DT_WORDBREAK);
  Result := acSize(ATextRect);
end;

procedure acTextDraw(ACanvas: TCanvas; const S: UnicodeString; const R: TRect; AHorzAlignment: TAlignment;
  AVertAlignment: TVerticalAlignment; AEndEllipsis, APreventTopLeftExceed, AWordWrap: Boolean);
var
  AMultiLine: Boolean;
  AText: UnicodeString;
  ATextFlags: Integer;
  ATextOffset: TPoint;
  ATextRect: TRect;
  ATextSize: TSize;
begin
  if (S <> '') and acRectVisible(ACanvas.Handle, R) then
  begin
    AMultiLine := acPos(#13, S) > 0;
    if AWordWrap or AMultiLine then
    begin
      ATextRect := R;
      ATextFlags := acTextAlignHorz[AHorzAlignment] or acTextAlignVert[AVertAlignment];
      if AEndEllipsis then
        ATextFlags := ATextFlags or DT_END_ELLIPSIS;
      if AWordWrap then
        ATextFlags := ATextFlags or DT_WORDBREAK
      else if not AMultiLine then
        ATextFlags := ATextFlags or DT_SINGLELINE;
      acSysDrawText(ACanvas, ATextRect, S, ATextFlags);
    end
    else
      if (AHorzAlignment <> taLeftJustify) or (AVertAlignment <> taAlignTop) or AEndEllipsis then
      begin
        AText := S;
        acTextPrepare(ACanvas, R, AEndEllipsis, AHorzAlignment, AVertAlignment,
          AText, ATextSize, ATextOffset, NullRect, APreventTopLeftExceed);
        acTextOut(ACanvas, ATextOffset.X, ATextOffset.Y, AText, ETO_CLIPPED, @R);
      end
      else
        acTextOut(ACanvas, R.Left, R.Top, S, ETO_CLIPPED, @R);
  end;
end;

procedure acTextDrawHighlight(ACanvas: TCanvas; const S: UnicodeString; const R: TRect;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AEndEllipsis: Boolean;
  AHighlightStart, AHighlightFinish: Integer; AHighlightColor, AHighlightTextColor: TColor);
var
  AHighlightRect: TRect;
  AHighlightTextSize: TSize;
  APrevTextColor: TColor;
  ASaveRgn: HRGN;
  AText: UnicodeString;
  ATextOffset, X: TPoint;
  ATextPart: UnicodeString;
  ATextPartSize: TSize;
  ATextSize: TSize;
  ATextVisibleCount: Integer;
begin
  if AHighlightFinish > AHighlightStart then
  begin
    AText := S;
    ATextVisibleCount := acTextPrepare(ACanvas, R, AEndEllipsis, AHorzAlignment, AVertAlignment, AText, ATextSize, ATextOffset);
    AHighlightFinish := Min(AHighlightFinish, ATextVisibleCount);
    ATextPart := Copy(AText, 1, AHighlightStart);
    acTextPrepare(ACanvas, R, False, taLeftJustify, taAlignTop, ATextPart, ATextPartSize, X);
    ATextPart := Copy(AText, 1, AHighlightFinish);
    acTextPrepare(ACanvas, R, False, taLeftJustify, taAlignTop, ATextPart, AHighlightTextSize, X);
    Dec(AHighlightTextSize.cx, ATextPartSize.cx);

    AHighlightRect := R;
    AHighlightRect.Left := ATextOffset.X + ATextPartSize.cx;
    AHighlightRect.Right := AHighlightRect.Left + AHighlightTextSize.cx;

    ASaveRgn := acSaveClipRegion(ACanvas.Handle);
    try
      acExcludeFromClipRegion(ACanvas.Handle, AHighlightRect);
      acTextOut(ACanvas, ATextOffset.X, ATextOffset.Y, AText, ETO_CLIPPED, @R);
    finally
      acRestoreClipRegion(ACanvas.Handle, ASaveRgn);
    end;

    ASaveRgn := acSaveClipRegion(ACanvas.Handle);
    try
      if acIntersectClipRegion(ACanvas.Handle, AHighlightRect) then
      begin
        acFillRect(ACanvas.Handle, AHighlightRect, AHighlightColor);
        APrevTextColor := ACanvas.Font.Color;
        ACanvas.Font.Color := AHighlightTextColor;
        acTextOut(ACanvas, ATextOffset.X, ATextOffset.Y, AText, ETO_CLIPPED, @R);
        ACanvas.Font.Color := APrevTextColor;
      end;
    finally
      acRestoreClipRegion(ACanvas.Handle, ASaveRgn);
    end;
  end
  else
    acTextDraw(ACanvas, S, R, AHorzAlignment, AVertAlignment, AEndEllipsis);
end;

procedure acTextDrawVertical(ACanvas: TCanvas; const S: UnicodeString; const R: TRect;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AEndEllipsis: Boolean = False);
var
  ABitmap: TACLBitmap;
begin
  ABitmap := TACLBitmap.CreateEx(R);
  try
    ABitmap.Canvas.Brush.Style := bsClear;
    acBitBlt(ABitmap.Canvas.Handle, ACanvas.Handle, ABitmap.ClientRect, R.TopLeft);
    ABitmap.Rotate(br270);
    ABitmap.Canvas.Lock;
    try
      ABitmap.Canvas.Font := ACanvas.Font;
      acTextDraw(ABitmap.Canvas, S, ABitmap.ClientRect, AHorzAlignment, AVertAlignment, AEndEllipsis);
    finally
      ABitmap.Canvas.Unlock;
    end;
    ABitmap.Rotate(br90);
    acBitBlt(ACanvas.Handle, ABitmap, R.TopLeft);
  finally
    ABitmap.Free;
  end;
end;

function acTextPrepare(ACanvas: TCanvas; const R: TRect; AEndEllipsis: Boolean; AHorzAlignment: TAlignment;
  AVertAlignment: TVerticalAlignment; var AText: UnicodeString; out ATextSize: TSize; out ATextOffset: TPoint): Integer;
begin
  Result := acTextPrepare(ACanvas, R, AEndEllipsis, AHorzAlignment, AVertAlignment, AText, ATextSize, ATextOffset, NullRect);
end;

function acTextPrepare(ACanvas: TCanvas; const R: TRect; AEndEllipsis: Boolean; AHorzAlignment: TAlignment;
  AVertAlignment: TVerticalAlignment; var AText: UnicodeString; out ATextSize: TSize; out ATextOffset: TPoint;
  const ATextExtends: TRect; APreventTopLeftExceed: Boolean = False): Integer;
var
  AEllipsisSize: TSize;
begin
  ATextSize := acTextSize(ACanvas, AText);

  if AEndEllipsis and (ATextSize.cx > R.Right - R.Left) then
  begin
    AEllipsisSize := acTextSize(ACanvas, acEndEllipsis);
    GetTextExtentExPointW(ACanvas.Handle, PWideChar(AText), Length(AText),
      Max(0, acRectWidth(R) - AEllipsisSize.cx), @Result, nil, ATextSize);
    AText := Copy(AText, 1, Result) + acEndEllipsis;
    ATextSize := acTextSize(ACanvas, AText);
  end
  else
    Result := Length(AText);

  Inc(ATextSize.cy, acMarginHeight(ATextExtends));
  Inc(ATextSize.cx, acMarginWidth(ATextExtends));

  ATextOffset := acAlignText(R, ATextSize, AHorzAlignment, AVertAlignment, APreventTopLeftExceed);
end;

procedure acTextOut(ACanvas: TCanvas; X, Y: Integer; const S: UnicodeString; AFlags: Integer; ARect: PRect = nil);
begin
  ExtTextOutW(ACanvas.Handle, X, Y, AFlags, ARect, PWideChar(S), Length(S), nil);
end;

procedure acSysDrawText(ACanvas: TCanvas; var R: TRect; const AText: UnicodeString; AFlags: Cardinal);
const
  HorzAlignMap: array[Boolean, Boolean] of TAlignment = (
    (taLeftJustify, taCenter), (taRightJustify, taRightJustify)
  );
  VertAlignMap: array[Boolean, Boolean] of TVerticalAlignment = (
    (taAlignTop, taVerticalCenter), (taAlignBottom, taAlignBottom)
  );
var
//  ALayout: TACLTextLayout;
  AMetrics: TTextMetricW;
begin
//  if IsWine then
//  begin
//    ALayout := TACLTextLayout.Create(ACanvas.Font);
//    try
//      ALayout.Bounds := R;
//      ALayout.SetText(AText, TACLTextFormatSettings.PlainText);
//      ALayout.SetOption(TACLTextLayoutOption.tloEditControl, AFlags and DT_EDITCONTROL <> 0);
//      ALayout.SetOption(TACLTextLayoutOption.tloEndEllipsis, AFlags and DT_END_ELLIPSIS <> 0);
//      ALayout.SetOption(TACLTextLayoutOption.tloWordWrap, AFlags and DT_WORDBREAK <> 0);
//      if AFlags and DT_CALCRECT <> 0 then
//      begin
//        ALayout.SetOption(TACLTextLayoutOption.tloAutoWidth, R.Width = 0);
//        R := acRect(ALayout.MeasureSize);
//      end
//      else
//        ALayout.DrawTo(ACanvas, R,
//          acPointOffsetNegative(
//            acAlignText(R, ALayout.MeasureSize,
//              HorzAlignMap[AFlags and DT_RIGHT <> 0, AFlags and DT_CENTER <> 0],
//              VertAlignMap[AFlags and DT_BOTTOM <> 0, AFlags and DT_VCENTER <> 0], True),
//            R.TopLeft));
//    finally
//      ALayout.Free;
//    end;
//  end
//  else
  begin
    DrawTextW(ACanvas.Handle, PWideChar(AText), Length(AText), R, AFlags);
    if AFlags and DT_CALCRECT <> 0 then
    begin
      GetTextMetricsW(ACanvas.Handle, AMetrics);
      if IsWine or (AMetrics.tmItalic <> 0) then
        Inc(R.Right, AMetrics.tmAveCharWidth div 2);
    end;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// ScreenCanvas
//----------------------------------------------------------------------------------------------------------------------

function ScreenCanvas: TACLScreenCanvas;
begin
  if FScreenCanvas = nil then
    FScreenCanvas := TACLScreenCanvas.Create;
  Result := FScreenCanvas;
end;

{ TACLScreenCanvas }

destructor TACLScreenCanvas.Destroy;
begin
  FreeHandle;
  inherited Destroy;
end;

procedure TACLScreenCanvas.CreateHandle;
begin
  FDeviceContext := GetDCEx(0, 0, DCX_CACHE or DCX_LOCKWINDOWUPDATE);
  Handle := FDeviceContext;
end;

procedure TACLScreenCanvas.Release;
begin
  if LockCount = 0 then
    FreeHandle;
end;

procedure TACLScreenCanvas.FreeHandle;
begin
  if FDeviceContext <> 0 then
  begin
    Handle := 0;
    ReleaseDC(0, FDeviceContext);
    FDeviceContext := 0;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// MeasureCanvas
//----------------------------------------------------------------------------------------------------------------------

function MeasureCanvas: TACLMeasureCanvas;
begin
  if FMeasureCanvas = nil then
    FMeasureCanvas := TACLMeasureCanvas.Create;
  Result := FMeasureCanvas;
end;

{ TACLMeasureCanvas }

destructor TACLMeasureCanvas.Destroy;
begin
  FreeHandle;
  inherited Destroy;
end;

procedure TACLMeasureCanvas.CreateHandle;
begin
  FBitmap := TACLBitmap.CreateEx(1, 1, pf32bit);
  FBitmap.Canvas.Lock;
  Handle := FBitmap.Canvas.Handle;
end;

procedure TACLMeasureCanvas.FreeHandle;
begin
  if HandleAllocated then
  begin
    Handle := 0;
    FBitmap.Canvas.Unlock;
    FreeAndNil(FBitmap);
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// Bitmaps
//----------------------------------------------------------------------------------------------------------------------

procedure acResetFont(AFont: TFont);
var
  ATempFont: TFont;
begin
  ATempFont := TFont.Create;
  try
    AFont.Assign(ATempFont);
  finally
    ATempFont.Free;
  end;
end;

procedure acResetRect(DC: HDC; const R: TRect);
begin
  FillRect(DC, R, GetStockObject(BLACK_BRUSH));
end;

procedure acFillBitmapInfoHeader(out AHeader: TBitmapInfoHeader; AWidth, AHeight: Integer);
begin
  ZeroMemory(@AHeader, SizeOf(AHeader));
  AHeader.biSize := SizeOf(TBitmapInfoHeader);
  AHeader.biWidth := AWidth;
  AHeader.biHeight := -AHeight;
  AHeader.biPlanes := 1;
  AHeader.biBitCount := 32;
  AHeader.biSizeImage := ((AWidth shl 5 + 31) and -32) shr 3 * AHeight;
  AHeader.biCompression := BI_RGB;
end;

procedure acGetBitmapBits(ABitmap: THandle; AWidth, AHeight: Integer;
  out AColors: TRGBColors; out ABitmapInfo: TBitmapInfo); overload;
begin
  with TACLBitmapBits.Create(ABitmap) do
  try
    if not ReadColors(AColors) then
    begin
      SetLength(AColors, AWidth * AHeight);
      acFillBitmapInfoHeader(ABitmapInfo.bmiHeader, AWidth, AHeight);
      GetDIBits(MeasureCanvas.Handle, ABitmap, 0, AHeight, AColors, ABitmapInfo, DIB_RGB_COLORS);
    end;
  finally
    Free;
  end;
end;

function acGetBitmapBits(ABitmap: TBitmap): TRGBColors; overload;
var
  AInfo: TBitmapInfo;
begin
  acGetBitmapBits(ABitmap.Handle, ABitmap.Width, ABitmap.Height, Result, AInfo);
end;

procedure acSetBitmapBits(ABitmap: TBitmap; var AColors: TRGBColors);
var
  AInfo: TBitmapInfo;
begin
  with TACLBitmapBits.Create(ABitmap.Handle) do
  try
    if not WriteColors(AColors) then
    begin
      acFillBitmapInfoHeader(AInfo.bmiHeader, ABitmap.Width, ABitmap.Height);
      SetDIBits(MeasureCanvas.Handle, ABitmap.Handle, 0, ABitmap.Height, AColors, AInfo, DIB_RGB_COLORS);
    end;
    TBitmapAccess(ABitmap).Changed(ABitmap);
    AColors := nil;
  finally
    Free;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// WorldTransfrom functions
//----------------------------------------------------------------------------------------------------------------------

procedure acWorldTransformFlip(DC: HDC; const AArea: TRect;
  AFlipHorizontally, AFlipVertically: Boolean; APrevWorldTransform: PXForm); overload;
begin
  acWorldTransformFlip(DC,
    PointF(0.5 * (AArea.Left + AArea.Right - 1), 0.5 * (AArea.Top + AArea.Bottom - 1)),
    AFlipHorizontally, AFlipVertically, APrevWorldTransform);
end;

procedure acWorldTransformFlip(DC: HDC; const APivotPoint: TPointF;
  AFlipHorizontally, AFlipVertically: Boolean; APrevWorldTransform: PXForm);
const
  FlipValueMap: array[Boolean] of Single = (1, -1);
var
  ATransform: TXForm;
begin
  SetGraphicsMode(DC, GM_ADVANCED);
  if APrevWorldTransform <> nil then
    GetWorldTransform(DC, APrevWorldTransform^);
  ZeroMemory(@ATransform, SizeOf(ATransform));
  ATransform.eM11 := FlipValueMap[AFlipHorizontally];
  ATransform.eM22 := FlipValueMap[AFlipVertically];
  ATransform.eDx := IfThen(AFlipHorizontally, 2 * APivotPoint.X);
  ATransform.eDy := IfThen(AFlipVertically, 2 * APivotPoint.Y);
  ModifyWorldTransform(DC, ATransform, MWT_RIGHTMULTIPLY);
end;

//----------------------------------------------------------------------------------------------------------------------
// Alpha Blend Functions
//----------------------------------------------------------------------------------------------------------------------

procedure acAlphaBlend(Dest: HDC; ABitmap: TBitmap; const DR: TRect;
  AAlpha: Integer = 255; AUseSourceAlpha: Boolean = True); overload;
begin
  acAlphaBlend(Dest, ABitmap, DR, Rect(0, 0, ABitmap.Width, ABitmap.Height), AAlpha, AUseSourceAlpha);
end;

procedure acAlphaBlend(Dest: HDC; ABitmap: TBitmap;
  const DR, SR: TRect; AAlpha: Integer = 255; AUseSourceAlpha: Boolean = True);
begin
  acAlphaBlend(Dest, ABitmap.Canvas.Handle, DR, SR, AAlpha, AUseSourceAlpha);
end;

procedure acAlphaBlend(Dest, Src: HDC; const DR, SR: TRect;
  AAlpha: Integer = 255; AUseSourceAlpha: Boolean = True);
const
  FormatMap: array[Boolean] of Integer = (AC_SRC_OVER, AC_SRC_ALPHA);
var
  ABlendFunc: TBlendFunction;
begin
  ZeroMemory(@ABlendFunc, SizeOf(ABlendFunc));
  ABlendFunc.BlendOp := AC_SRC_OVER;
  ABlendFunc.AlphaFormat := FormatMap[AUseSourceAlpha];
  ABlendFunc.SourceConstantAlpha := AAlpha;
  AlphaBlend(Dest, DR.Left, DR.Top, DR.Right - DR.Left, DR.Bottom - DR.Top,
    Src, SR.Left, SR.Top, SR.Right - SR.Left, SR.Bottom - SR.Top, ABlendFunc);
end;

procedure acUpdateLayeredWindow(Wnd: THandle; SrcDC: HDC; const R: TRect; AAlpha: Integer = 255);
var
  ABlendFunc: TBlendFunction;
  ASize: TSize;
  AStyle: Cardinal;
  ATopLeft, N: TPoint;
begin
  AStyle := GetWindowLong(Wnd, GWL_EXSTYLE);
  if AStyle and WS_EX_LAYERED = 0 then
    SetWindowLong(Wnd, GWL_EXSTYLE, AStyle or WS_EX_LAYERED);

  ZeroMemory(@ABlendFunc, SizeOf(ABlendFunc));
  ABlendFunc.BlendOp := AC_SRC_OVER;
  ABlendFunc.AlphaFormat := AC_SRC_ALPHA;
  ABlendFunc.SourceConstantAlpha := AAlpha;

  N := NullPoint;
  ASize := acSize(R);
  ATopLeft := R.TopLeft;
  UpdateLayeredWindow(Wnd, 0, @ATopLeft, @ASize, SrcDC, @N, 0, @ABlendFunc, ULW_ALPHA);
end;

//----------------------------------------------------------------------------------------------------------------------
// DoubleBuffer
//----------------------------------------------------------------------------------------------------------------------

function acCreateMemDC(ASourceDC: HDC; const R: TRect; out AMemBmp: HBITMAP; out AClipRegion: HRGN): HDC;
var
  AClipRect: TRect;
begin
  AClipRegion := 0;
  Result := CreateCompatibleDC(ASourceDC);
  AMemBmp := CreateCompatibleBitmap(ASourceDC, R.Right - R.Left, R.Bottom - R.Top);
  SelectObject(Result, AMemBmp);
  SetWindowOrgEx(Result, R.Left, R.Top, nil);
  if GetClipBox(ASourceDC, AClipRect) <> RGN_ERROR then
    acIntersectClipRegion(Result, AClipRect);
end;

procedure acDeleteMemDC(AMemDC: HDC; AMemBmp: HBITMAP; AClipRegion: HRGN);
begin
  DeleteDC(AMemDC);
  DeleteObject(AMemBmp);
  DeleteObject(AClipRegion)
end;

//----------------------------------------------------------------------------------------------------------------------
// GDI
//----------------------------------------------------------------------------------------------------------------------

procedure acBitBlt(DC, SourceDC: HDC; const R: TRect; const APoint: TPoint);
begin
  BitBlt(DC, R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top, SourceDC, APoint.X, APoint.Y, SRCCOPY);
end;

procedure acBitBlt(DC: HDC; ABitmap: TBitmap; const ADestPoint: TPoint);
begin
  BitBlt(DC, ADestPoint.X, ADestPoint.Y, ABitmap.Width, ABitmap.Height, ABitmap.Canvas.Handle, 0, 0, SRCCOPY);
end;

procedure acBitBlt(DC: HDC; ABitmap: TBitmap; const R: TRect; const APoint: TPoint);
begin
  acBitBlt(DC, ABitmap.Canvas.Handle, R, APoint);
end;

procedure acDrawArrow(DC: HDC; R: TRect; AColor: TColor; AArrowKind: TACLArrowKind; ATargetDPI: Integer);

  procedure Draw(R: TRect; const Extends: TRect; Count: Integer);
  var
    ABrush: HBRUSH;
  begin
    ABrush := CreateSolidBrush(ColorToRGB(AColor));
    while Count > 0 do
    begin
      FillRect(DC, R, ABrush);
      R := acRectContent(R, Extends);
      Dec(Count);
    end;
    DeleteObject(ABrush);
  end;

var
  ASize: Integer;
begin
  ASize := MulDiv(2, ATargetDPI, acDefaultDPI);
  if AArrowKind in [makLeft, makRight] then
    R := acRectCenter(R, ASize + 1, ASize * 2 + 1)
  else
    R := acRectCenter(R, ASize * 2 + 1, ASize + 1);

  case AArrowKind of
    makLeft:
      Draw(acRectCenter(acRectSetWidth(R, 1), 1, 1), Rect(1, -1, -1, -1), ASize + 1);
    makRight:
      Draw(acRectCenter(acRectSetLeft(R, R.Right, 1), 1, 1), Rect(-1, -1, 1, -1), ASize + 1);
    makTop:
      Draw(acRectCenter(acRectSetHeight(R, 1), 1, 1), Rect(-1, 1, -1, -1), ASize + 1);
    makBottom:
      Draw(acRectCenter(acRectSetTop(R, R.Bottom, 1), 1, 1), Rect(-1, -1, -1, 1), ASize + 1);
  end;
end;

function acGetArrowSize(AArrowKind: TACLArrowKind; ATargetDPI: Integer): TSize;
var
  ASize: Integer;
begin
  ASize := MulDiv(2, ATargetDPI, acDefaultDPI);
  if AArrowKind in [makLeft, makRight] then
    Result := acSize(ASize + 1, ASize * 2 + 1)
  else
    Result := acSize(ASize * 2 + 1, ASize + 1);
end;

procedure acDrawDotsLineV(DC: HDC; X, Y1, Y2: Integer; AColor: TColor);
var
  ABrush: HBRUSH;
  I: Integer;
  R: TRect;
begin
  BeginPath(DC);
  ABrush := CreateSolidBrush(ColorToRGB(AColor));
  R := Rect(X, Y1, X + 1, Y1 + 1);
  for I := 0 to (Y2 - Y1) div 3 do
  begin
    FillRect(DC, R, ABrush);
    Inc(R.Bottom, 3);
    Inc(R.Top, 3);
  end;
  DeleteObject(ABrush);
  EndPath(DC);
end;

procedure acDrawDotsLineH(DC: HDC; X1, X2, Y: Integer; AColor: TColor);
var
  ABrush: HBRUSH;
  I: Integer;
  R: TRect;
begin
  BeginPath(DC);
  ABrush := CreateSolidBrush(ColorToRGB(AColor));
  R := Rect(X1, Y, X1 + 1, Y + 1);
  for I := 0 to (X2 - X1) div 3 do
  begin
    FillRect(DC, R, ABrush);
    Inc(R.Left, 3);
    Inc(R.Right, 3);
  end;
  DeleteObject(ABrush);
  EndPath(DC);
end;

procedure acDrawColorPreview(ACanvas: TCanvas; R: TRect; AColor: TAlphaColor);
begin
  acDrawColorPreview(ACanvas, R, AColor, clGray, acHatchDefaultColor1, acHatchDefaultColor2);
end;

procedure acDrawColorPreview(ACanvas: TCanvas; R: TRect; AColor: TAlphaColor; ABorderColor, AHatchColor1, AHatchColor2: TColor);
var
  APrevFontColor: TColor;
begin
  acDrawFrame(ACanvas.Handle, R, ABorderColor);
  InflateRect(R, -1, -1);
  acDrawFrame(ACanvas.Handle, R, AHatchColor1);
  InflateRect(R, -1, -1);
  if AColor.IsDefault then
  begin
    APrevFontColor := ACanvas.Font.Color;
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Color := ABorderColor;
    acFillRect(ACanvas.Handle, R, AHatchColor1);
    acTextDraw(ACanvas, '?', R, taCenter, taVerticalCenter);
    ACanvas.Font.Color := APrevFontColor;
  end
  else
  begin
    acDrawHatch(ACanvas.Handle, R, AHatchColor1, AHatchColor2, 4);
    acFillRect(ACanvas.Handle, R, AColor);
  end;
  acExcludeFromClipRegion(ACanvas.Handle, acRectInflate(R, 2));
end;

procedure acDrawFocusRect(ACanvas: TCanvas; const R: TRect);
begin
  acDrawFocusRect(ACanvas.Handle, R, ACanvas.Font.Color);
end;

procedure acDrawFocusRect(DC: HDC; const R: TRect; AColor: TColor);
begin
  if AColor <> clNone then
    GpFocusRect(DC, R, TAlphaColor.FromColor(acGetActualColor(AColor, clBlack)));
end;

procedure acDrawHatch(DC: HDC; const R: TRect);
begin
  acDrawHatch(DC, R, acHatchDefaultColor1, acHatchDefaultColor2, acHatchDefaultSize);
end;

procedure acDrawHatch(DC: HDC; const R: TRect; AColor1, AColor2: TColor; ASize: Integer);
var
  ABrush: HBRUSH;
  ABrushBitmap: TBitmap;
  AOrigin: TPoint;
begin
  ABrushBitmap := acHatchCreatePattern(ASize, AColor1, AColor2);
  try
    GetWindowOrgEx(DC, AOrigin);
    SetBrushOrgEx(DC, R.Left - AOrigin.X, R.Top - AOrigin.Y, @AOrigin);

    ABrush := CreatePatternBrush(ABrushBitmap.Handle);
    FillRect(DC, R, ABrush);
    DeleteObject(ABrush);

    SetBrushOrgEx(DC, AOrigin.X, AOrigin.Y, nil);
  finally
    ABrushBitmap.Free;
  end;
end;

function acHatchCreatePattern(ASize: Integer; AColor1, AColor2: TColor): TBitmap;
var
  ARect: TRect;
begin
  Result := TACLBitmap.CreateEx(2 * ASize, 2 * ASize, pf24bit);
  ARect := Rect(0, 0, ASize, ASize);
  acFillRect(Result.Canvas.Handle, ARect, AColor2);
  acFillRect(Result.Canvas.Handle, acRectOffset(ARect, 0, ASize), AColor1);
  acFillRect(Result.Canvas.Handle, acRectOffset(ARect, ASize, 0), AColor1);
  acFillRect(Result.Canvas.Handle, acRectOffset(ARect, ASize, ASize), AColor2);
end;

procedure acDrawSelectionRect(DC: HDC; const R: TRect; AColor: TAlphaColor);
begin
  if not R.IsEmpty then
  begin
    acFillRect(DC, R, TAlphaColor.FromColor(AColor.ToColor, 100));
    acDrawFrame(DC, R, AColor.ToColor);
  end;
end;

procedure acDrawShadow(ACanvas: TCanvas; const ARect: TRect; ABKColor: TColor; AShadowSize: Integer = 5);

  procedure DrawShadow(const R: TRect);
  var
    AShadowColor: TColor;
  begin
    ABKColor := ColorToRGB(ABKColor);
    AShadowColor := RGB(
      MulDiv(GetRValue(ABKColor), 200, 255),
      MulDiv(GetGValue(ABKColor), 200, 255),
      MulDiv(GetBValue(ABKColor), 200, 255));
    acFillRect(ACanvas.Handle, R, AShadowColor);
  end;

var
  R1: TRect;
begin
  R1 := ARect;
  R1.Top := R1.Bottom - AShadowSize;
  Inc(R1.Left, AShadowSize);
  DrawShadow(R1);

  R1 := ARect;
  R1.Left := R1.Right - AShadowSize;
  Inc(R1.Top, AShadowSize);
  DrawShadow(R1);
end;

procedure acStretchBlt(DC, SourceDC: HDC; const ADest, ASource: TRect);
begin
  StretchBlt(DC, ADest.Left, ADest.Top, ADest.Right - ADest.Left,
    ADest.Bottom - ADest.Top, SourceDC, ASource.Left, ASource.Top,
    ASource.Right - ASource.Left, ASource.Bottom - ASource.Top, SRCCOPY);
end;

procedure acDrawExpandButton(DC: HDC; const R: TRect; ABorderColor, AColor: TColor; AExpanded: Boolean);
var
  R1: TRect;
begin
  R1 := R;
  InflateRect(R1, -1, -1);
  acDrawFrame(DC, R1, ABorderColor);
  InflateRect(R1, -2, -2);
  acFillRect(DC, acRectCenter(R1, R1.Right - R1.Left, 1), AColor);
  if not AExpanded then
    acFillRect(DC, acRectCenter(R1, 1, R1.Bottom - R1.Top), AColor);
end;

procedure acTileBlt(DC, SourceDC: HDC; const ADest, ASource: TRect);
var
  ABrush: HBRUSH;
  ABrushBitmap: TACLBitmapLayer;
  AClipRgn: HRGN;
  AOrigin: TPoint;
  R: TRect;
  W, H: Integer;
  X, Y, XCount, YCount: Integer;
begin
  if not (acRectIsEmpty(ADest) or acRectIsEmpty(ASource)) and RectVisible(DC, ADest) then
  begin
    W := ASource.Right - ASource.Left;
    H := ASource.Bottom - ASource.Top;
    R := acRectSetHeight(ADest, H);
    XCount := acCalcPatternCount(ADest.Right - ADest.Left, W);
    YCount := acCalcPatternCount(ADest.Bottom - ADest.Top, H);

    if XCount * YCount > 10 then
    begin
      ABrushBitmap := TACLBitmapLayer.Create(W, H);
      try
        acBitBlt(ABrushBitmap.Handle, SourceDC, ABrushBitmap.ClientRect, ASource.TopLeft);

        GetWindowOrgEx(DC, AOrigin);
        SetBrushOrgEx(DC, ADest.Left - AOrigin.X, ADest.Top - AOrigin.Y, @AOrigin);

        ABrush := CreatePatternBrush(ABrushBitmap.Bitmap);
        FillRect(DC, ADest, ABrush);
        DeleteObject(ABrush);

        SetBrushOrgEx(DC, AOrigin.X, AOrigin.Y, nil);
      finally
        ABrushBitmap.Free;
      end;
    end
    else
    begin
      AClipRgn := acSaveClipRegion(DC);
      try
        acIntersectClipRegion(DC, ADest);
        for Y := 1 to YCount do
        begin
          R.Left := ADest.Left;
          R.Right := ADest.Left + W;
          for X := 1 to XCount do
          begin
            acBitBlt(DC, SourceDC, R, ASource.TopLeft);
            Inc(R.Left, W);
            Inc(R.Right, W);
          end;
          Inc(R.Top, H);
          Inc(R.Bottom, H);
        end;
      finally
        acRestoreClipRegion(DC, AClipRgn);
      end;
    end;
  end;
end;

procedure acStretchDraw(DC, SourceDC: HDC; const ADest, ASource: TRect; AMode: TACLStretchMode);
begin
  case AMode of
    isTile:
      acTileBlt(DC, SourceDC, ADest, ASource);
    isStretch, isCenter:
      acStretchBlt(DC, SourceDC, ADest, ASource);
  end;
end;

procedure acDrawDragImage(ACanvas: TCanvas; const R: TRect; AAlpha: Byte);
begin
  acFillRect(ACanvas.Handle, R, TAlphaColor.FromColor(acDragImageColor, AAlpha));
  acDrawFrame(ACanvas.Handle, R, TAlphaColor.FromColor(clBlack, AAlpha), MulDiv(1, acGetSystemDpi, acDefaultDpi));
end;

procedure acDrawDropArrow(DC: HDC; const R: TRect; AColor: TColor);
begin
  acDrawDropArrow(DC, R, AColor, acDropArrowSize);
end;

procedure acDrawDropArrow(DC: HDC; const R: TRect; AColor: TColor; const AArrowSize: TSize);
var
  ABrush: THandle;
  APoints: array[0..2] of TPoint;
  ARegion: THandle;
  X, Y: Integer;
begin
  if not IsRectEmpty(R) then
  begin
    X := (R.Right + R.Left - AArrowSize.cx) div 2;
    Y := (R.Bottom + R.Top - AArrowSize.cy) div 2;
    APoints[0] := Point(X, Y);
    APoints[1] := Point(X + AArrowSize.cx, Y);
    APoints[2] := Point(X + AArrowSize.cx div 2, Y + AArrowSize.cy + 1);

    ABrush := CreateSolidBrush(ColorToRGB(AColor));
    ARegion := CreatePolygonRgn(APoints, Length(APoints), WINDING);
    FillRgn(DC, ARegion, ABrush);
    DeleteObject(ARegion);
    DeleteObject(ABrush);
  end;
end;

procedure acDrawFrame(DC: HDC; ARect: TRect; AColor: TColor; AThickness: Integer = 1);
begin
  acDrawFrameEx(DC, ARect, AColor, acAllBorders, AThickness);
end;

procedure acDrawFrame(DC: HDC; ARect: TRect; AColor: TAlphaColor; AThickness: Integer = 1);
begin
  acDrawFrameEx(DC, ARect, AColor, acAllBorders, AThickness);
end;

procedure acDrawFrameEx(DC: HDC; const ARect: TRect; AColor: TColor; ABorders: TACLBorders; AThickness: Integer = 1);
var
  AClipRegion: HRGN;
begin
  if AColor <> clNone then
  begin
    AClipRegion := acSaveClipRegion(DC);
    try
      acExcludeFromClipRegion(DC, acRectContent(ARect, AThickness, ABorders));
      acFillRect(DC, ARect, AColor);
    finally
      acRestoreClipRegion(DC, AClipRegion);
    end;
  end;
end;

procedure acDrawFrameEx(DC: HDC; ARect: TRect; AColor: TAlphaColor; ABorders: TACLBorders; AThickness: Integer = 1);
var
  AClipRegion: HRGN;
begin
  if AColor.IsValid then
  begin
    AClipRegion := acSaveClipRegion(DC);
    try
      acExcludeFromClipRegion(DC, acRectContent(ARect, AThickness, ABorders));
      acFillRect(DC, ARect, AColor);
    finally
      acRestoreClipRegion(DC, AClipRegion);
    end;
  end;
end;

procedure acFillRect(DC: HDC; const ARect: TRect; AColor: TColor);
var
  ABrush: HBRUSH;
begin
  if AColor <> clNone then
  begin
    ABrush := CreateSolidBrush(ColorToRGB(AColor));
    FillRect(DC, ARect, ABrush);
    DeleteObject(ABrush);
  end;
end;

procedure acFillRect(DC: HDC; const ARect: TRect; AColor: TAlphaColor);
var
  AHandle: GpGraphics;
begin
  if AColor.IsValid then
  begin
    GdipCreateFromHDC(DC, AHandle);
    GdipFillRectangleI(AHandle,
      TACLGdiplusResourcesCache.BrushGet(AColor),
      ARect.Left, ARect.Top, acRectWidth(ARect), acRectHeight(ARect));
    GdipDeleteGraphics(AHandle);
  end;
end;

procedure acDrawComplexFrame(DC: HDC; const R: TRect; AColor1, AColor2: TColor; ABorders: TACLBorders = acAllBorders);
begin
  acDrawFrameEx(DC, R, AColor1, ABorders);
  acDrawFrameEx(DC, acRectContent(R, 1, ABorders), AColor2, ABorders);
end;

procedure acDrawComplexFrame(DC: HDC; const R: TRect; AColor1, AColor2: TAlphaColor; ABorders: TACLBorders = acAllBorders);
begin
  acDrawFrameEx(DC, R, AColor1, ABorders);
  acDrawFrameEx(DC, acRectContent(R, 1, ABorders), AColor2, ABorders);
end;

procedure acDrawGradient(DC: HDC; const ARect: TRect; AFrom, ATo: TColor; AVertical: Boolean = True);
begin
  if AFrom = clNone then
    acFillRect(DC, ARect, ATo)
  else
    if (ATo = clNone) or (AFrom = ATo) then
      acFillRect(DC, ARect, AFrom)
    else
      acDrawGradient(DC, ARect, TAlphaColor.FromColor(AFrom), TAlphaColor.FromColor(ATo), AVertical);
end;

procedure acDrawGradient(DC: HDC; const ARect: TRect; AFrom, ATo: TAlphaColor; AVertical: Boolean = True);
const
  ModeMap: array[Boolean] of TLinearGradientMode = (gmHorizontal, gmVertical);
begin
  if (AFrom = ATo) or not AFrom.IsValid then
    acFillRect(DC, ARect, ATo)
  else
    if ATo.IsValid then
    begin
      GpPaintCanvas.BeginPaint(DC);
      GpPaintCanvas.FillRectangleByGradient(AFrom, ATo, ARect, ModeMap[AVertical]);
      GpPaintCanvas.EndPaint;
    end
    else
      acFillRect(DC, ARect, AFrom);
end;

procedure acDrawHueIntensityBar(ACanvas: TCanvas; const R: TRect; AHue: Byte = 0);
var
  AColor: TColor;
  ADelta: Single;
  AValue: Single;
  I: Integer;
begin
  if not acRectIsEmpty(R) then
  begin
    AValue := 0;
    ADelta := 1.0 / acRectWidth(R);
    for I := R.Left to R.Right do
    begin
      TACLColors.HSLtoRGB(AHue / 255, AValue, 0.5, AColor);
      acFillRect(ACanvas.Handle, Rect(I, R.Top, I + 1, R.Bottom), AColor);
      AValue := AValue + ADelta;
    end;
  end;
end;

procedure acDrawHueColorBar(ACanvas: TCanvas; const R: TRect);
var
  AColor: TColor;
  ADelta: Single;
  AValue: Single;
  I: Integer;
begin
  if not acRectIsEmpty(R) then
  begin
    AValue := 0;
    ADelta := 1.0 / acRectWidth(R);
    for I := R.Left to R.Right do
    begin
      TACLColors.HSLtoRGB(AValue, 1.0, 0.5, AColor);
      acFillRect(ACanvas.Handle, Rect(I, R.Top, I + 1, R.Bottom), AColor);
      AValue := AValue + ADelta;
    end;
  end;
end;

{ TACLRegion }

constructor TACLRegion.Create;
begin
  CreateRect(NullRect);
end;

constructor TACLRegion.CreateRect(const R: TRect);
begin
  FHandle := CreateRectRgnIndirect(R);
end;

constructor TACLRegion.CreateFromDC(DC: HDC);
const
  MaxRegionSize = 30000;
var
  APoint: TPoint;
begin
  CreateRect(NullRect);
  GetClipRgn(DC, Handle);
  if Empty then
    SetRectRgn(Handle, 0, 0, MaxRegionSize, MaxRegionSize)
  else
  begin
    GetWindowOrgEx(DC, APoint);
    Offset(APoint.X, APoint.Y);
  end;
end;

constructor TACLRegion.CreateFromHandle(AHandle: HRGN);
begin
  FHandle := AHandle;
end;

constructor TACLRegion.CreateFromWindow(AWnd: HWND);
var
  R: TRect;
begin
  CreateRect(NullRect);
  GetWindowRgn(AWnd, Handle);
  if Empty then
  begin
    GetWindowRect(AWnd, R);
    OffsetRect(R, -R.Left, -R.Top);
    SetRectRgn(Handle, R.Left, R.Top, R.Right, R.Bottom);
  end;
end;

destructor TACLRegion.Destroy;
begin
  FreeHandle;
  inherited Destroy;
end;

procedure TACLRegion.FreeHandle;
begin
  if FHandle <> 0 then
  begin
    DeleteObject(FHandle);
    FHandle := 0;
  end;
end;

function TACLRegion.GetBounds: TRect;
begin
  if GetRgnBox(Handle, Result) = NULLREGION then
    Result := NullRect;
end;

function TACLRegion.GetIsEmpty: Boolean;
var
  R: TRect;
begin
  Result := GetRgnBox(Handle, R) = NULLREGION;
end;

function TACLRegion.Clone: THandle;
begin
  Result := CreateRectRgnIndirect(NullRect);
  CombineRgn(Result, Result, Handle, RGN_OR);
end;

procedure TACLRegion.Combine(ARegion: TACLRegion; ACombineFunc: TACLRegionCombineFunc; AFreeRegion: Boolean = False);
begin
  CombineRgn(Handle, Handle, ARegion.Handle, CombineFuncMap[ACombineFunc]);
  if AFreeRegion then
    FreeAndNil(ARegion);
end;

procedure TACLRegion.Combine(const R: TRect; ACombineFunc: TACLRegionCombineFunc);
var
  ARgn: THandle;
begin
  ARgn := CreateRectRgnIndirect(R);
  if ACombineFunc <> rcmCopy then
    CombineRgn(Handle, Handle, ARgn, CombineFuncMap[ACombineFunc])
  else
    acExchangePointers(FHandle, ARgn);

  DeleteObject(ARgn)
end;

function TACLRegion.Contains(const R: TRect): Boolean;
begin
  Result := RectInRegion(Handle, R);
end;

function TACLRegion.Contains(const P: TPoint): Boolean;
begin
  Result := PtInRegion(Handle, P.X, P.Y);
end;

procedure TACLRegion.Offset(X, Y: Integer);
begin
  OffsetRgn(Handle, X, Y);
end;

procedure TACLRegion.Reset;
begin
  SetRectRgn(Handle, 0, 0, 0, 0);
end;

procedure TACLRegion.SetHandle(const Value: THandle);
begin
  if (Value <> 0) and (Value <> FHandle) then
  begin
    FreeHandle;
    FHandle := Value;
  end;
end;

procedure TACLRegion.SetToWindow(AHandle: HWND; ARedraw: Boolean = True);
begin
  SetWindowRgn(AHandle, Clone, ARedraw);
end;

{ TACLBitmapBits }

constructor TACLBitmapBits.Create(ABitmapHandle: THandle);
begin
  FValid :=
    (GetObject(ABitmapHandle, SizeOf(FDIB), @FDIB) <> 0) and
    (FDIB.dsBmih.biCompression = BI_RGB) and
    (FDIB.dsBmih.biBitCount in [32, 24]);
end;

function TACLBitmapBits.GetBits: Integer;
begin
  Result := FDIB.dsBmih.biBitCount;
end;

function TACLBitmapBits.GetRow(ARow: Integer): Pointer;
begin
  if FDIB.dsBmih.biHeight > 0 then
    ARow := FDIB.dsBm.bmHeight - ARow - 1;
  if ARow < 0 then
    raise EInvalidArgument.Create('Row is negative');
  Result := Pointer(NativeUInt(FDIB.dsBm.bmBits) + NativeUInt(ARow * FDIB.dsBm.bmWidthBytes));
end;

function TACLBitmapBits.ReadColors(out AColors: TRGBColors): Boolean;
begin
  Result := Valid;
  if Result then
  begin
    SetLength(AColors, FDIB.dsBm.bmWidth * FDIB.dsBm.bmHeight);
    case Bits of
      24: ReadColors24(AColors);
      32: ReadColors32(AColors);
    end;
  end;
end;

function TACLBitmapBits.WriteColors(const AColors: TRGBColors): Boolean;
begin
  Result := Valid;
  if Result then
  begin
    case Bits of
      24: WriteColors24(AColors);
      32: WriteColors32(AColors);
    end;
  end;
end;

procedure TACLBitmapBits.ReadColors24(var AColors: TRGBColors);

  procedure Convert24(ABuf32: PRGBQuad; ABuf24: PRGBTriple; APixelsCount: Integer);
  begin
    while APixelsCount > 0 do
    begin
      ABuf32^.rgbRed := ABuf24^.rgbtRed;
      ABuf32^.rgbBlue := ABuf24^.rgbtBlue;
      ABuf32^.rgbGreen := ABuf24^.rgbtGreen;
      ABuf32^.rgbReserved := 255;
      Dec(APixelsCount);
      Inc(ABuf32);
      Inc(ABuf24);
    end;
  end;

var
  ARow: Integer;
begin
  for ARow := 0 to FDIB.dsBm.bmHeight - 1 do
    Convert24(@AColors[ARow * FDIB.dsBm.bmWidth], Row[ARow], FDIB.dsBm.bmWidth);
end;

procedure TACLBitmapBits.ReadColors32(var AColors: TRGBColors);
var
  ARow: Integer;
begin
  for ARow := 0 to FDIB.dsBm.bmHeight - 1 do
    CopyMemory(@AColors[ARow * FDIB.dsBm.bmWidth], Row[ARow], FDIB.dsBm.bmWidthBytes);
end;

procedure TACLBitmapBits.WriteColors24(const AColors: TRGBColors);

  procedure Convert24(ABuf24: PRGBTriple; ABuf32: PRGBQuad; APixelsCount: Integer);
  begin
    while APixelsCount > 0 do
    begin
      ABuf24^.rgbtRed := ABuf32^.rgbRed;
      ABuf24^.rgbtBlue := ABuf32^.rgbBlue;
      ABuf24^.rgbtGreen := ABuf32^.rgbGreen;
      Dec(APixelsCount);
      Inc(ABuf32);
      Inc(ABuf24);
    end;
  end;

var
  ARow: Integer;
begin
  for ARow := 0 to FDIB.dsBm.bmHeight - 1 do
    Convert24(Row[ARow], @AColors[ARow * FDIB.dsBm.bmWidth], FDIB.dsBm.bmWidth);
end;

procedure TACLBitmapBits.WriteColors32(const AColors: TRGBColors);
var
  ARow: Integer;
begin
  for ARow := 0 to FDIB.dsBm.bmHeight - 1 do
    CopyMemory(Row[ARow], @AColors[ARow * FDIB.dsBm.bmWidth], FDIB.dsBm.bmWidthBytes);
end;

{ TACLRegionData }

constructor TACLRegionData.Create(ACount: Integer);
begin
  inherited Create;
  DataAllocate(ACount);
end;

destructor TACLRegionData.Destroy;
begin
  DataFree;
  inherited Destroy;
end;

function TACLRegionData.CreateHandle: HRGN;
var
  ARect: TRect;
  AScanR: PRect;
  I: Integer;
begin
  if RectsCount > 0 then
  begin
    AScanR := @FData.Buffer[0];
    ARect := AScanR^;
    Inc(AScanR);
    for I := 1 to RectsCount - 1 do
    begin
      acRectUnion(ARect, AScanR^);
      Inc(AScanR);
    end;
  end
  else
    ARect := NullRect;

  Result := CreateHandle(ARect);
end;

function TACLRegionData.CreateHandle(const ARegionBounds: TRect): HRGN;
begin
  if RectsCount > 0 then
  begin
    FData^.rdh.rcBound := ARegionBounds;
    Result := ExtCreateRegion(nil, FDataSize, FData^);
  end
  else
    Result := CreateRectRgnIndirect(NullRect);
end;

procedure TACLRegionData.DataAllocate(ARectsCount: Integer);
begin
  FCount := ARectsCount;
  FDataSize := SizeOf(TRgnData) + SizeOf(TRect) * RectsCount;
  FData := AllocMem(FDataSize);
  FData^.rdh.dwSize := SizeOf(FData^.rdh);
  FData^.rdh.iType := RDH_RECTANGLES;
  FData^.rdh.nCount := RectsCount;
  FData^.rdh.nRgnSize := 0;
end;

procedure TACLRegionData.DataFree;
begin
  FreeMemAndNil(Pointer(FData));
  FDataSize := 0;
  FCount := 0;
end;

function TACLRegionData.GetRect(Index: Integer): TRect;
begin
  Result := PRectArray(@FData^.Buffer[0])^[Index];
end;

procedure TACLRegionData.SetRect(Index: Integer; const R: TRect);
begin
  PRectArray(@FData^.Buffer[0])^[Index] := R;
end;

procedure TACLRegionData.SetRectsCount(AValue: Integer);
begin
  if RectsCount <> AValue then
  begin
    DataFree;
    DataAllocate(AValue);
  end;
end;

{ TAlphaColorHelper }

class function TAlphaColorHelper.ApplyColorSchema(AColor: TAlphaColor; const ASchema: TACLColorSchema): TAlphaColor;
begin
  Result := AColor;
  TACLColors.ApplyColorSchema(Result, ASchema);
end;

class function TAlphaColorHelper.FromARGB(const A, R, G, B: Byte): TAlphaColor;
begin
  Result := (A shl 24) or (R shl 16) or (G shl 8) or B;
end;

class function TAlphaColorHelper.FromColor(const AColor: TColor; AAlpha: Byte): TAlphaColor;
begin
  if AColor = clDefault then
    Result := TAlphaColor.Default
  else
    if AColor <> clNone then
      Result := FromColor(TACLColors.ToQuad(AColor, AAlpha))
    else
      Result := TAlphaColor.None;
end;

class function TAlphaColorHelper.FromColor(const AColor: TRGBQuad): TAlphaColor;
begin
  Result := FromARGB(AColor.rgbReserved, AColor.rgbRed, AColor.rgbGreen, AColor.rgbBlue);
end;

class function TAlphaColorHelper.FromString(AColor: UnicodeString): TAlphaColor;
var
  Q: TRGBQuad;
begin
  if AColor = '' then
    Exit(Default);
  if Length(AColor) < 6 then
    AColor := AColor + DupeString('0', 6 - Length(AColor));
  if Length(AColor) = 6 then
    AColor := 'FF' + AColor
  else
    if Length(AColor) < 8 then
      AColor := DupeString('0', 8 - Length(AColor)) + AColor;

  Q.rgbReserved := StrToIntDef('$' + Copy(AColor, 1, 2), 0);
  Q.rgbRed := StrToIntDef('$' + Copy(AColor, 3, 2), 0);
  Q.rgbGreen := StrToIntDef('$' + Copy(AColor, 5, 2), 0);
  Q.rgbBlue := StrToIntDef('$' + Copy(AColor, 7, 2), 0);
  Result := TAlphaColor.FromColor(Q);
end;

function TAlphaColorHelper.IsDefault: Boolean;
begin
  Result := Self = TAlphaColor.Default;
end;

function TAlphaColorHelper.IsValid: Boolean;
begin
  Result := (Self <> TAlphaColor.None) and (Self <> TAlphaColor.Default);
end;

function TAlphaColorHelper.ToColor: TColor;
begin
  if Self = TAlphaColor.Default then
    Result := clDefault
  else
    if Self = TAlphaColor.None then
      Result := clNone
    else
      Result := (GetRValue(Self) shl 16) or (GetGValue(Self) shl 8) or (GetBValue(Self));
end;

function TAlphaColorHelper.ToQuad: TRGBQuad;
begin
  Result.rgbBlue := Byte(Self shr BlueShift);
  Result.rgbGreen := Byte(Self shr GreenShift);
  Result.rgbRed := Byte(Self shr RedShift);
  Result.rgbReserved := Self shr AlphaShift;
end;

function TAlphaColorHelper.ToString: string;
begin
  if Self = TAlphaColor.None then
    Result := 'None'
  else
    if Self = TAlphaColor.Default then
      Result := 'Default'
    else
      with ToQuad do
        Result :=
          IntToHex(rgbReserved, 2) +
          IntToHex(rgbRed, 2) +
          IntToHex(rgbGreen, 2) +
          IntToHex(rgbBlue, 2);
end;

function TAlphaColorHelper.GetAlpha(const Index: Integer): Byte;
begin
  if IsDefault then
    Result := MaxByte
  else
    Result := GetComponent(Index);
end;

function TAlphaColorHelper.GetComponent(const Index: Integer): Byte;
begin
  Result := PARGB(@Self)^[Index];
end;

procedure TAlphaColorHelper.SetComponent(const Index: Integer; const Value: Byte);
begin
  PARGB(@Self)^[Index] := Value;
end;

{ TACLColorSchema }

constructor TACLColorSchema.Create(AHue, AHueIntensity: Byte);
begin
  Hue := AHue;
  HueIntensity := AHueIntensity;
end;

class function TACLColorSchema.CreateFromColor(AColor: TAlphaColor): TACLColorSchema;
var
  H, S, L: Byte;
begin
  if AColor.IsValid then
  begin
    TACLColors.RGBtoHSLi(AColor.R, AColor.G, AColor.B, H, S, L);
    Result := TACLColorSchema.Create(H, MulDiv(100, S, MaxByte));
  end
  else
    Result := TACLColorSchema.Default;
end;

class function TACLColorSchema.Default: TACLColorSchema;
begin
  Result := TACLColorSchema.Create(0);
end;

function TACLColorSchema.IsAssigned: Boolean;
begin
  Result := Hue > 0;
end;

class operator TACLColorSchema.Equal(const C1, C2: TACLColorSchema): Boolean;
begin
  Result := (C1.Hue = C2.Hue) and (C1.HueIntensity = C2.HueIntensity);
end;

class operator TACLColorSchema.NotEqual(const C1, C2: TACLColorSchema): Boolean;
begin
  Result := not (C1 = C2);
end;

{ TFontHelper }

function TFontHelper.Clone: TFont;
begin
  Result := TFont.Create;
  Result.Assign(Self);
end;

procedure TFontHelper.SetSize(ASize, ATargetDpi: Integer);
begin
  Size := MulDiv(ASize, ATargetDpi, PixelsPerInch);
end;

{ TACLBitmap }

constructor TACLBitmap.CreateEx(const S: TSize; APixelFormat: TPixelFormat = pf32bit; AResetContent: Boolean = False);
begin
  CreateEx(S.cx, S.cy, APixelFormat, AResetContent);
end;

constructor TACLBitmap.CreateEx(const R: TRect; APixelFormat: TPixelFormat = pf32bit; AResetContent: Boolean = False);
begin
  CreateEx(R.Right - R.Left, R.Bottom - R.Top, APixelFormat, AResetContent);
end;

constructor TACLBitmap.CreateEx(W, H: Integer; APixelFormat: TPixelFormat = pf32bit; AResetContent: Boolean = False);
begin
  Create;
  PixelFormat := APixelFormat;
  SetSize(W, H);
  if AResetContent then
    Reset;
end;

function TACLBitmap.GetClientRect: TRect;
begin
  Result := Rect(0, 0, Width, Height);
end;

procedure TACLBitmap.DrawStretch(ACanvas: TCanvas; const ADest, ASource: TRect);
begin
  acStretchDraw(ACanvas.Handle, Self.Canvas.Handle, ADest, ASource, StretchMode);
end;

procedure TACLBitmap.DrawStretch(ACanvas: TCanvas; const ADest: TRect);
begin
  DrawStretch(ACanvas, ADest, ClientRect);
end;

procedure TACLBitmap.DrawTo(ACanvas: TCanvas; X, Y: Integer);
begin
  ACanvas.Draw(X, Y, Self);
end;

procedure TACLBitmap.DrawMargins(ACanvas: TCanvas; const ADest, AMargins: TRect);
begin
  DrawMargins(ACanvas, ADest, ClientRect, AMargins);
end;

procedure TACLBitmap.DrawMargins(ACanvas: TCanvas; const ADest, ASource, AMargins: TRect);
var
  ADestParts: TACLMarginPartBounds;
  ASourceParts: TACLMarginPartBounds;
  APart: TACLMarginPart;
begin
  if acMarginIsEmpty(AMargins) then
    DrawStretch(ACanvas, ADest, ASource)
  else
  begin
    acMarginCalculateRects(ASource, AMargins, ASource, ASourceParts, StretchMode);
    acMarginCalculateRects(ADest, AMargins, ASource, ADestParts, StretchMode);
    for APart := Low(APart) to High(APart) do
    begin
      if acMarginIsPartFixed(APart, StretchMode) then
        acBitBlt(ACanvas.Handle, Self, ADestParts[APart], ASourceParts[APart].TopLeft)
      else
        DrawStretch(ACanvas, ADestParts[APart], ASourceParts[APart]);
    end;
  end;
end;

procedure TACLBitmap.Clear;
begin
  SetSize(0, 0);
end;

procedure TACLBitmap.LoadFromResource(Inst: HINST; const AName, AType: UnicodeString);
var
  AStream: TStream;
begin
  AStream := TResourceStream.Create(Inst, AName, PWideChar(AType));
  try
    LoadFromStream(AStream);
  finally
    AStream.Free;
  end;
end;

procedure TACLBitmap.LoadFromStream(Stream: TStream);
var
  AHack: TBitmapImageHack;
begin
  inherited LoadFromStream(Stream);
  if not Empty then
  begin
    //#AI: Workaround for bitmap that created via old version of delphies
    AHack := TBitmapImageHack(TBitmapHack(Self).FImage);
    if (AHack <> nil) and (AHack.FDIB.dsBmih.biBitCount > 16) then
      AHack.FDIB.dsBmih.biClrUsed := 0;
  end;
end;

procedure TACLBitmap.SetSizeEx(const R: TRect);
begin
  SetSize(Max(0, acRectWidth(R)), Max(0, acRectHeight(R)));
end;

procedure TACLBitmap.ApplyColorSchema(const AValue: TACLColorSchema);
var
  ABits: TRGBColors;
begin
  if AValue.IsAssigned then
  begin
    ABits := acGetBitmapBits(Self);
    try
      TACLColors.ApplyColorSchema(@ABits[0], Length(ABits), AValue);
    finally
      acSetBitmapBits(Self, ABits);
    end;
  end;
end;

procedure TACLBitmap.ChangeAlpha(AValue: Byte);
var
  ABits: TRGBColors;
  I: Integer;
begin
  ABits := acGetBitmapBits(Self);
  try
    for I := 0 to Length(ABits) - 1 do
      ABits[I].rgbReserved := AValue;
  finally
    acSetBitmapBits(Self, ABits);
  end;
end;

procedure TACLBitmap.MakeDisabled;
var
  ABits: TRGBColors;
begin
  ABits := acGetBitmapBits(Self);
  try
    TACLColors.MakeDisabled(@ABits[0], Length(ABits));
  finally
    acSetBitmapBits(Self, ABits);
  end;
end;

procedure TACLBitmap.MakeOpaque;
begin
  ChangeAlpha(MaxByte);
end;

procedure TACLBitmap.MakeTransparent(AColor: TColor);
var
  ABits: TRGBColors;
begin
  if not Empty then
  begin
    PixelFormat := pf32bit;
    ABits := acGetBitmapBits(Self);
    try
      TACLColors.MakeTransparent(@ABits[0], Length(ABits), TACLColors.ToQuad(AColor));
    finally
      acSetBitmapBits(Self, ABits);
    end;
  end;
end;

procedure TACLBitmap.Rotate(ARotation: TACLBitmapRotation; AFlipVertically: Boolean = False);
var
  ARow, ACol, H, W, ASourceI, ADestI: Integer;
  ASource, ADest: TRGBColors;
begin
  if (ARotation = br0) and not AFlipVertically then
    Exit;

  H := Height;
  W := Width;
  ASource := acGetBitmapBits(Self);
  SetLength(ADest, Length(ASource));
  for ARow := 0 to H - 1 do
  begin
    for ACol := 0 to W - 1 do
    begin
      ASourceI := ARow * W + ACol;
      case ARotation of
        br90:
          if AFlipVertically then
            ADestI := ACol * H + ARow
          else
            ADestI := (W - ACol - 1) * H + ARow;

        br180:
          if AFlipVertically then
            ADestI := ARow * W + W - ACol - 1
          else
            ADestI := (H - ARow - 1) * W + W - ACol - 1;

        br270:
          if AFlipVertically then
            ADestI := (W - ACol - 1) * H + H - ARow - 1
          else
            ADestI := H - 1 + ACol * H - ARow;

        else
          if AFlipVertically then
            ADestI := (H - 1 - ARow) * W + ACol
          else
            ADestI := ASourceI;
      end;
      ADest[ADestI] := ASource[ASourceI];
    end;
  end;
  if ARotation in [br90, br270] then
    SetSize(H, W);
  acSetBitmapBits(Self, ADest);
end;

procedure TACLBitmap.Reset;
begin
  acResetRect(Canvas.Handle, ClientRect);
end;

{ TACLColors }

class constructor TACLColors.Create;
var
  I, J: Integer;
begin
  for I := 0 to 255 do
    for J := I to 255 do
    begin
      PremultiplyTable[I, J] := MulDiv(I, J, 255);
      PremultiplyTable[J, I] := PremultiplyTable[I, J];

      UnpremultiplyTable[I, J] := MulDiv(I, 255, J);
      UnpremultiplyTable[J, I] := UnpremultiplyTable[I, J];
    end;
end;

class function TACLColors.CompareRGB(const Q1, Q2: TRGBQuad): Boolean;
begin
  Result := (Q1.rgbBlue = Q2.rgbBlue) and (Q1.rgbGreen = Q2.rgbGreen) and (Q1.rgbRed = Q2.rgbRed);
end;

class function TACLColors.IsDark(Color: TColor): Boolean;
begin
  Result := Lightness(Color) < 0.45;
end;

class function TACLColors.IsMask(const Q: TRGBQuad): Boolean;
begin
  Result := (Q.rgbGreen = MaskPixel.rgbGreen) and (Q.rgbBlue = MaskPixel.rgbBlue) and (Q.rgbRed = MaskPixel.rgbRed);
end;

class function TACLColors.ToQuad(A, R, G, B: Byte): TRGBQuad;
begin
  Result.rgbBlue := B;
  Result.rgbGreen := G;
  Result.rgbRed := R;
  Result.rgbReserved := A;
end;

class function TACLColors.ToQuad(AColor: TAlphaColor): TRGBQuad;
begin
  Result.rgbBlue := AColor.B;
  Result.rgbGreen := AColor.G;
  Result.rgbRed := AColor.R;
  Result.rgbReserved := AColor.A;
end;

class function TACLColors.ToQuad(AColor: TColor; AAlpha: Byte = MaxByte): TRGBQuad;
begin
  AColor := ColorToRGB(AColor);
  Result.rgbRed := GetRValue(AColor);
  Result.rgbGreen := GetGValue(AColor);
  Result.rgbBlue := GetBValue(AColor);
  Result.rgbReserved := AAlpha;
end;

class function TACLColors.ToColor(const Q: TRGBQuad): TColor;
begin
  Result := RGB(Q.rgbRed, Q.rgbGreen, Q.rgbBlue);
end;

class procedure TACLColors.AlphaBlend(var D: TColor; S: TColor; AAlpha: Integer = 255);
var
  DQ, SQ: TRGBQuad;
begin
  DQ := ToQuad(D);
  SQ := ToQuad(S);
  AlphaBlend(DQ, SQ, AAlpha);
  D := ToColor(DQ);
end;

class procedure TACLColors.AlphaBlend(var D: TRGBQuad; const S: TRGBQuad; AAlpha: Integer = 255; AProcessPerChannelAlpha: Boolean = True);
var
  A: Integer;
begin
  if AProcessPerChannelAlpha then
    A := PremultiplyTable[S.rgbReserved, AAlpha]
  else
    A := AAlpha;

  if (A <> MaxByte) or (AAlpha <> MaxByte) then
  begin
    A := MaxByte - A;
    D.rgbRed      := PremultiplyTable[D.rgbRed, A]      + PremultiplyTable[S.rgbRed, AAlpha];
    D.rgbBlue     := PremultiplyTable[D.rgbBlue, A]     + PremultiplyTable[S.rgbBlue, AAlpha];
    D.rgbGreen    := PremultiplyTable[D.rgbGreen, A]    + PremultiplyTable[S.rgbGreen, AAlpha];
    D.rgbReserved := PremultiplyTable[D.rgbReserved, A] + PremultiplyTable[S.rgbReserved, AAlpha];
  end
  else
    TAlphaColor(D) := TAlphaColor(S);
end;

class procedure TACLColors.ApplyColorSchema(var AColor: TColor; const AValue: TACLColorSchema);
var
  Q: TRGBQuad;
begin
  if AValue.IsAssigned then
  begin
    Q := ToQuad(AColor);
    ApplyColorSchema(Q, AValue);
    AColor := ToColor(Q);
  end;
end;

class procedure TACLColors.ApplyColorSchema(AColors: PRGBQuad; ACount: Integer; const AValue: TACLColorSchema);
begin
  if AValue.IsAssigned then
    ChangeHue(AColors, ACount, AValue.Hue, AValue.HueIntensity);
end;

class procedure TACLColors.ApplyColorSchema(const AFont: TFont; const AValue: TACLColorSchema);
var
  AColor: TColor;
begin
  if AValue.IsAssigned then
  begin
    AColor := AFont.Color;
    ApplyColorSchema(AColor, AValue);
    AFont.Color := AColor;
  end;
end;

class procedure TACLColors.ApplyColorSchema(var AColor: TAlphaColor; const AValue: TACLColorSchema);
var
  Q: TRGBQuad;
begin
  if AColor.IsValid and AValue.IsAssigned then
  begin
    Q := ToQuad(AColor);
    ApplyColorSchema(Q, AValue);
    AColor := TAlphaColor.FromColor(Q);
  end;
end;

class procedure TACLColors.ApplyColorSchema(var AColor: TRGBQuad; const AValue: TACLColorSchema);
begin
  if AValue.IsAssigned then
    ChangeHue(AColor, AValue.Hue, AValue.HueIntensity);
end;

//#AI: https://github.com/chromium/chromium/blob/master/ui/base/clipboard/clipboard_win.cc#L652
class function TACLColors.ArePremultiplied(AColors: PRGBQuad; ACount: Integer): Boolean;
begin
  while ACount > 0 do
  begin
    with AColors^ do
    begin
      if Max(Max(rgbBlue, rgbGreen), rgbRed) > rgbReserved then
        Exit(False);
    end;
    Inc(AColors);
    Dec(ACount);
  end;
  Result := True;
end;

class procedure TACLColors.ChangeColor(Q: PRGBQuad; ACount: Integer; const AColor: TRGBQuad);
var
  Cmax, Cmin: Integer;
  H, S, L: Byte;
begin
  RGBtoHSLi(AColor.rgbRed, AColor.rgbGreen, AColor.rgbBlue, H, S, L);
  while ACount > 0 do
  begin
    if not IsMask(Q^) then
    begin
      Cmax := Max(Q^.rgbRed, Max(Q^.rgbGreen, Q^.rgbBlue));
      Cmin := Min(Q^.rgbRed, Min(Q^.rgbGreen, Q^.rgbBlue));
      HSLtoRGBi(H, S, MulDiv(MaxByte, Cmax + Cmin, 2 * MaxByte), Q^.rgbRed, Q^.rgbGreen, Q^.rgbBlue);
    end;
    Dec(ACount);
    Inc(Q);
  end;
end;

class procedure TACLColors.ChangeHue(var Q: TRGBQuad; AHue: Byte; AIntensity: Byte = 100);
var
  H, S, L: Byte;
begin
  if not IsMask(Q) then
  begin
    TACLColors.RGBtoHSLi(Q.rgbRed, Q.rgbGreen, Q.rgbBlue, H, S, L);
    TACLColors.HSLtoRGBi(AHue, MulDiv(S, AIntensity, 100), L, Q.rgbRed, Q.rgbGreen, Q.rgbBlue);
  end;
end;

class procedure TACLColors.ChangeHue(Q: PRGBQuad; ACount: Integer; AHue: Byte; AIntensity: Byte = 100);
begin
  while ACount > 0 do
  begin
    ChangeHue(Q^, AHue, AIntensity);
    Dec(ACount);
    Inc(Q);
  end;
end;

class procedure TACLColors.Flip(AColors: PRGBQuadArray; AWidth, AHeight: Integer; AHorizontally, AVertically: Boolean);
var
  I: Integer;
  Q1, Q2, Q3: PRGBQuad;
  Q4: TRGBQuad;
  RS: Integer;
begin
  if AVertically then
  begin
    Q1 := @AColors^[0];
    Q2 := @AColors^[(AHeight - 1) * AWidth];
    RS := AWidth * SizeOf(TRGBQuad);
    Q3 := AllocMem(RS);
    try
      while NativeUInt(Q1) < NativeUInt(Q2) do
      begin
        FastMove(Q2^, Q3^, RS);
        FastMove(Q1^, Q2^, RS);
        FastMove(Q3^, Q1^, RS);
        Inc(Q1, AWidth);
        Dec(Q2, AWidth);
      end;
    finally
      FreeMem(Q3, RS);
    end;
  end;

  if AHorizontally then
    for I := 0 to AHeight - 1 do
    begin
      Q1 := @AColors^[I * AWidth];
      Q2 := @AColors^[I * AWidth + AWidth - 1];
      while NativeUInt(Q1) < NativeUInt(Q2) do
      begin
        Q4  := Q2^;
        Q2^ := Q1^;
        Q1^ := Q4;
        Inc(Q1);
        Dec(Q2);
      end;
    end;
end;

class procedure TACLColors.Flush(var Q: TRGBQuad);
begin
  PCardinal(@Q)^ := 0;
end;

class procedure TACLColors.Grayscale(Q: PRGBQuad; Count: Integer; IgnoreMask: Boolean = False);
begin
  while Count > 0 do
  begin
    Grayscale(Q^, IgnoreMask);
    Dec(Count);
    Inc(Q);
  end;
end;

class procedure TACLColors.Grayscale(var Q: TRGBQuad; IgnoreMask: Boolean = False);
begin
  if IgnoreMask or not IsMask(Q) then
  begin
    Q.rgbBlue := PremultiplyTable[Q.rgbBlue, 77] + PremultiplyTable[Q.rgbGreen, 150] + PremultiplyTable[Q.rgbRed, 28];
    Q.rgbGreen := Q.rgbBlue;
    Q.rgbRed := Q.rgbBlue;
  end;
end;

class function TACLColors.Invert(Color: TColor): TColor;
begin
  Result := $FFFFFF xor ColorToRGB(Color);
end;

class function TACLColors.Lightness(Color: TColor): Single;
var
  H, S: Single;
begin
  TACLColors.RGBtoHSL(Color, H, S, Result);
end;

class procedure TACLColors.MakeDisabled(Q: PRGBQuad; Count: Integer; IgnoreMask: Boolean = False);
begin
  while Count > 0 do
  begin
    MakeDisabled(Q^, IgnoreMask);
    Dec(Count);
    Inc(Q);
  end;
end;

class procedure TACLColors.MakeDisabled(var Q: TRGBQuad; IgnoreMask: Boolean = False);
var
  APixel: Byte;
begin
  if (Q.rgbReserved > 0) and (IgnoreMask or not IsMask(Q)) then
  begin
    Unpremultiply(Q);
    Q.rgbReserved := PremultiplyTable[Q.rgbReserved, 128];
    APixel := PremultiplyTable[Q.rgbBlue, 77] + PremultiplyTable[Q.rgbGreen, 150] + PremultiplyTable[Q.rgbRed, 28];
    APixel := PremultiplyTable[APixel, Q.rgbReserved];
    Q.rgbBlue := APixel;
    Q.rgbGreen := APixel;
    Q.rgbRed := APixel;
  end;
end;

class procedure TACLColors.MakeTransparent(Q: PRGBQuad; ACount: Integer; const AColor: TRGBQuad);
begin
  while ACount > 0 do
  begin
    if CompareRGB(Q^, AColor) then
      PDWORD(Q)^ := 0
    else
      Q^.rgbReserved := MaxByte;
    Dec(ACount);
    Inc(Q);
  end;
end;

class procedure TACLColors.Tint(Q: PRGBQuad; ACount: Integer; const ATintColor: TRGBQuad);
var
  AAlpha: Byte;
begin
  if ATintColor.rgbReserved = 0 then
    Exit;
  if ATintColor.rgbReserved = MaxByte then
  begin
    while ACount > 0 do
    begin
      Q.rgbBlue := ATintColor.rgbBlue;
      Q.rgbGreen := ATintColor.rgbGreen;
      Q.rgbRed := ATintColor.rgbRed;
      Dec(ACount);
      Inc(Q);
    end;
  end
  else
  begin
    AAlpha := MaxByte - ATintColor.rgbReserved;
    while ACount > 0 do
    begin
      Q.rgbBlue  := PremultiplyTable[Q.rgbBlue,  AAlpha] + PremultiplyTable[ATintColor.rgbBlue,  ATintColor.rgbReserved];
      Q.rgbGreen := PremultiplyTable[Q.rgbGreen, AAlpha] + PremultiplyTable[ATintColor.rgbGreen, ATintColor.rgbReserved];
      Q.rgbRed   := PremultiplyTable[Q.rgbRed,   AAlpha] + PremultiplyTable[ATintColor.rgbRed,   ATintColor.rgbReserved];
      Dec(ACount);
      Inc(Q);
    end;
  end;
end;

class procedure TACLColors.Premultiply(var Q: TRGBQuad);
begin
  if Q.rgbReserved = 0 then
    DWORD(Q) := 0
  else
    if Q.rgbReserved < 255 then
    begin
      Q.rgbRed   := PremultiplyTable[Q.rgbRed,   Q.rgbReserved];
      Q.rgbBlue  := PremultiplyTable[Q.rgbBlue,  Q.rgbReserved];
      Q.rgbGreen := PremultiplyTable[Q.rgbGreen, Q.rgbReserved];
    end;
end;

class procedure TACLColors.Premultiply(Q: PRGBQuad; ACount: Integer);
begin
  while ACount > 0 do
  begin
    Premultiply(Q^);
    Dec(ACount);
    Inc(Q);
  end;
end;

class procedure TACLColors.Unpremultiply(var Q: TRGBQuad);
begin
  if (Q.rgbReserved > 0) and (Q.rgbReserved < MaxByte) then
  begin
    Q.rgbGreen := UnpremultiplyTable[Q.rgbGreen, Q.rgbReserved];
    Q.rgbBlue  := UnpremultiplyTable[Q.rgbBlue,  Q.rgbReserved];
    Q.rgbRed   := UnpremultiplyTable[Q.rgbRed,   Q.rgbReserved];
  end;
end;

class procedure TACLColors.Unpremultiply(Q: PRGBQuad; ACount: Integer);
begin
  while ACount > 0 do
  begin
    Unpremultiply(Q^);
    Dec(ACount);
    Inc(Q);
  end;
end;

class procedure TACLColors.HSLtoRGB(H, S, L: Single; out R, G, B: Byte);

  function HueToColor(M1, M2, Hue: Single): Byte;
  var
    V, AHue6: Double;
  begin
    Hue := Hue - Floor(Hue);
    AHue6 := 6 * Hue;
    if AHue6 < 1 then
      V := M1 + (M2 - M1) * AHue6
    else if AHue6 < 3 then // 2 * Hue < 1
      V := M2
    else if AHue6 < 4 then // 3 * Hue < 2
      V := M1 + (M2 - M1) * (4 - AHue6)
    else
      V := M1;

    Result := Round(255 * V);
  end;

var
  M1, M2: Single;
begin
  if S = 0 then
  begin
    R := Round(255 * L);
    G := R;
    B := R;
  end
  else
  begin
    if L <= 0.5 then
      M2 := L * (1 + S)
    else
      M2 := L + S - L * S;

    M1 := 2 * L - M2;
    R := HueToColor(M1, M2, H + 1 / 3);
    G := HueToColor(M1, M2, H);
    B := HueToColor(M1, M2, H - 1 / 3)
  end;
end;

class procedure TACLColors.HSLtoRGBi(H, S, L: Byte; out AColor: TColor);
var
  R, G, B: Byte;
begin
  HSLtoRGBi(H, S, L, R, G, B);
  AColor := RGB(R, G, B);
end;

class procedure TACLColors.HSLtoRGBi(H, S, L: Byte; out R, G, B: Byte);
const
  PartOfSix = MaxByte div 6;
  PartOfTwo = MaxByte div 2;
  PartOfTwoThirds = 2 * MaxByte div 3;

  function HueToColor(M1, M2, Hue: Integer): Byte;
  begin
    if Hue < 0 then
      Inc(Hue, MaxByte);
    if Hue > MaxByte then
      Dec(Hue, MaxByte);

    if Hue < PartOfSix then
      Result := Min(M1 + ((M2 - M1) * Hue) div PartOfSix, MaxByte)
    else if Hue < PartOfTwo then
      Result := Min(M2, MaxByte)
    else if Hue < PartOfTwoThirds then
      Result := Min(M1 + ((M2 - M1) * (4 * MaxByte - 6 * Hue)) div MaxByte, MaxByte)
    else
      Result := Min(M1, MaxByte);
  end;

var
  M1: Integer;
  M2: Integer;
begin
  if S = 0 then
  begin
    R := L;
    G := L;
    B := L;
  end
  else
  begin
    if L <= 128 then
      M2 := L * (MaxByte + S) div MaxByte
    else
      M2 := L + S - PremultiplyTable[L, S];

    M1 := 2 * L - M2;
    R := HueToColor(M1, M2, H + 85);
    G := HueToColor(M1, M2, H);
    B := HueToColor(M1, M2, H - 85)
  end;
end;

class function TACLColors.HSLtoRGB(H, S, L: Single): TColor;
begin
  HSLtoRGB(H, S, L, Result);
end;

class procedure TACLColors.HSLtoRGB(H, S, L: Single; out AColor: TColor);
var
  R, G, B: Byte;
begin
  HSLtoRGB(H, S, L, R, G, B);
  AColor := RGB(R, G, B);
end;

class procedure TACLColors.RGBtoHSL(AColor: TColor; out H, S, L: Single);
begin
  AColor := ColorToRGB(AColor);
  RGBtoHSL(GetRValue(AColor), GetGValue(AColor), GetBValue(AColor), H, S, L);
end;

class procedure TACLColors.RGBtoHSL(R, G, B: Byte; out H, S, L: Single);
var
  ADelta, Cmax, Cmin: Integer;
begin
  Cmax := Max(R, Max(G, B));
  Cmin := Min(R, Min(G, B));
  L := (Cmax + Cmin) / (2 * MaxByte);
  H := 0;
  S := 0;

  ADelta := Cmax - Cmin;
  if ADelta <> 0 then
  begin
    if L < 0.5 then
      S := ADelta / (Cmax + Cmin)
    else
      S := ADelta / (2 * MaxByte - Cmax - Cmin);

    if R = Cmax then
      H := (G - B) / ADelta
    else if G = Cmax then
      H := 2 + (B - R) / ADelta
    else
      H := 4 + (R - G) / ADelta;

    H := H / 6;
    if H < 0 then
      H := H + 1
  end;
end;

class procedure TACLColors.RGBtoHSLi(AColor: TColor; out H, S, L: Byte);
begin
  AColor := ColorToRGB(AColor);
  RGBtoHSLi(GetRValue(AColor), GetGValue(AColor), GetBValue(AColor), H, S, L);
end;

class procedure TACLColors.RGBtoHSLi(R, G, B: Byte; out H, S, L: Byte);
var
  AHue, ADelta, Cmax, Cmin: Integer;
begin
  Cmax := Max(R, Max(G, B));
  Cmin := Min(R, Min(G, B));
  L := MulDiv(MaxByte, Cmax + Cmin, 2 * MaxByte);
  H := 0;
  S := 0;

  ADelta := Cmax - Cmin;
  if ADelta <> 0 then
  begin
    if L < 128 then
      S := MulDiv(MaxByte, ADelta, Cmax + Cmin)
    else
      S := MulDiv(MaxByte, ADelta, 2 * MaxByte - Cmax - Cmin);

    if R = Cmax then
      AHue := MulDiv(MaxByte, G - B, ADelta)
    else if G = Cmax then
      AHue := 2 * MaxByte + MulDiv(MaxByte, B - R, ADelta)
    else
      AHue := 4 * MaxByte + MulDiv(MaxByte, R - G, ADelta);

    AHue := AHue div 6;
    if AHue < 0 then
      Inc(AHue, MaxByte);
    H := AHue;
  end;
end;

class function TACLColors.HSVtoRGB(H, S, V: Single): TColor;
var
  R, G, B: Byte;
begin
  HSVtoRGB(H, S, V, R, G, B);
  Result := RGB(R, G, B);
end;

class procedure TACLColors.HSVtoRGB(H, S, V: Single; out AColor: TColor);
begin
  AColor := HSVtoRGB(H, S, V);
end;

class procedure TACLColors.HSVtoRGB(H, S, V: Single; out R, G, B: Byte);

  procedure SetResult(RS, GS, BS: Single);
  begin
    R := Round(RS);
    G := Round(GS);
    B := Round(BS);
  end;

var
  AFrac: Single;
  AMax: Single;
  AMid1: Single;
  AMid2: Single;
  AMin: Single;
  ASector: Byte;
begin
  AMax := V * 255;
  AMin := AMax * (1 - S);
  ASector := Trunc(H / 60) mod 6;
  AFrac := H / 60 - ASector;
  AMid1 := AMax * (1 - AFrac * S);
  AMid2 := AMax * (1 - (1 - AFrac) * S);
  case ASector of
    0: SetResult(AMax, AMid2, AMin);
    1: SetResult(AMid1, AMax, AMin);
    2: SetResult(AMin, AMax, AMid2);
    3: SetResult(AMin, AMid1, AMax);
    4: SetResult(AMid2, AMin, AMax);
  else // 5
    SetResult(AMax, AMin, AMid1);
  end;
end;

class function TACLColors.Hue(Color: TColor): Single;
var
  S, L: Single;
begin
  RGBToHSL(Color, Result, S, L);
end;

class procedure TACLColors.RGBtoHSV(R, G, B: Byte; out H, S, V: Single);
var
  AMax, AMin: Byte;
begin
  AMax := Max(Max(B, G), R);
  AMin := Min(Min(B, G), R);

  V := AMax / 255;
  if V = 0 then
    S := 0
  else
    S := 1 - AMin / AMax;

  if AMax = AMin then
    H := 0
  else if AMax = R then
    H := 60 * (G - B) / (AMax - AMin) + 0
  else if AMax = G then
    H := 60 * (B - R) / (AMax - AMin) + 120
  else if AMax = B then
    H := 60 * (R - G) / (AMax - AMin) + 240;

  if H < 0 then
    H := H + 360;
end;

class procedure TACLColors.RGBtoHSV(AColor: TColor; out H, S, V: Single);
begin
  AColor := ColorToRGB(AColor);
  RGBtoHSV(GetRValue(AColor), GetGValue(AColor), GetBValue(AColor), H, S, V);
end;

{ TACLRegionManager }

class destructor TACLRegionManager.Finalize;
var
  I: Integer;
begin
  for I := 0 to CacheSize - 1 do
    DeleteObject(Cache[I]);
end;

class function TACLRegionManager.Get: HRGN;
var
  AIndex: Integer;
begin
  Result := 0;
  AIndex := 0;
  while (Result = 0) and (AIndex < CacheSize) do
  begin
    Result := AtomicExchange(Cache[AIndex], 0);
    Inc(AIndex);
  end;
  if Result = 0 then
    Result := CreateRectRgn(0, 0, 0, 0);
end;

class procedure TACLRegionManager.Release(var ARegion: HRGN);
var
  AIndex: Integer;
begin
  AIndex := 0;
  while (ARegion <> 0) and (AIndex < CacheSize) do
  begin
    ARegion := AtomicExchange(Cache[AIndex], ARegion);
    Inc(AIndex);
  end;
  DeleteObject(ARegion)
end;

initialization

finalization
  FreeAndNil(FMeasureCanvas);
  FreeAndNil(FScreenCanvas);
end.
