{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*            Graphics Utilities             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics;

{$I ACL.Config.inc}

interface

uses
  Winapi.GDIPAPI,
  Winapi.Windows,
  // Vcl
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
  ACL.Utils.Common;

type
  TRGBColors = array of TRGBQuad;
  TACLArrowKind = (makLeft, makRight, makTop, makBottom);

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

  { TACLPixel32 }

  PACLPixel32 = ^TACLPixel32;
  TACLPixel32 = packed record
  public const
    EssenceMask = $00FFFFFF;
  public
    B, G, R, A: Byte; // TRGBQuad's order
    class function Create(A, R, G, B: Byte): TACLPixel32; overload; static; inline;
    class function Create(AColor: TAlphaColor): TACLPixel32; overload; static;
    class function Create(AColor: TColor; AAlpha: Byte = MaxByte): TACLPixel32; overload; static;
    class operator Implicit(const Value: TRGBQuad): TACLPixel32; overload;
    class operator Implicit(const Value: TACLPixel32): TRGBQuad; overload;
    function ToColor: TColor;
  end;

  PACLPixel32Array = ^TACLPixel32Array;
  TACLPixel32Array = array [0..0] of TACLPixel32;
  TACLPixel32DynArray = array of TACLPixel32;

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
    class function FromColor(const AColor: TACLPixel32): TAlphaColor; overload; static;
    class function FromString(AColor: UnicodeString): TAlphaColor; static;
    function IsDefault: Boolean; inline;
    function IsValid: Boolean; inline;
    function ToColor: TColor;
    function ToPixel: TACLPixel32;
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

  { TACLDib }

  TACLDib = class
  strict private
    FBitmap: HBITMAP;
    FCanvas: TCanvas;
    FColorCount: Integer;
    FColors: PACLPixel32Array;
    FHandle: HDC;
    FHeight: Integer;
    FOldBmp: HBITMAP;
    FWidth: Integer;

    function GetCanvas: TCanvas;
    function GetClientRect: TRect; inline;
    function GetEmpty: Boolean; inline;
  protected
    procedure CreateHandles(W, H: Integer); virtual;
    procedure FreeHandles; virtual;
  public
    constructor Create(const R: TRect); overload;
    constructor Create(const S: TSize); overload;
    constructor Create(const W, H: Integer); overload; virtual;
    destructor Destroy; override;
    procedure Assign(ALayer: TACLDib);
    procedure AssignParams(DC: HDC);
    function Clone(out AData: PACLPixel32Array): Boolean;
    function CoordToFlatIndex(X, Y: Integer): Integer; inline;
    //# Processing
    procedure ApplyTint(const AColor: TColor); overload;
    procedure ApplyTint(const AColor: TACLPixel32); overload;
    procedure Flip(AHorizontally, AVertically: Boolean);
    procedure MakeDisabled(AIgnoreMask: Boolean = False);
    procedure MakeMirror(ASize: Integer);
    procedure MakeOpaque;
    procedure MakeTransparent(AColor: TColor);
    procedure Premultiply(R: TRect); overload;
    procedure Premultiply; overload;
    procedure Reset(const R: TRect); overload;
    procedure Reset; overload;
    procedure Resize(ANewWidth, ANewHeight: Integer); overload;
    procedure Resize(const R: TRect); overload;
    //# Draw
    procedure DrawBlend(ACanvas: TCanvas; const R: TRect; AAlpha: Byte = MaxByte); overload;
    procedure DrawBlend(DC: HDC; const P: TPoint; AAlpha: Byte = MaxByte); overload;
    procedure DrawCopy(DC: HDC; const P: TPoint); overload;
    procedure DrawCopy(DC: HDC; const R: TRect; ASmoothStretch: Boolean = False); overload;
    //# Properties
    property Bitmap: HBITMAP read FBitmap;
    property Canvas: TCanvas read GetCanvas;
    property ClientRect: TRect read GetClientRect;
    property ColorCount: Integer read FColorCount;
    property Colors: PACLPixel32Array read FColors;
    property Empty: Boolean read GetEmpty;
    property Handle: HDC read FHandle;
    property Height: Integer read FHeight;
    property Width: Integer read FWidth;
  end;

  { TACLColorList }

  TACLColorList = class(TACLList<TColor>);

  { TACLBitmap }

  TACLBitmap = class(TBitmap, IACLColorSchema)
  strict private
    function GetClientRect: TRect;
  public
    constructor CreateEx(const S: TSize; APixelFormat: TPixelFormat = pf32bit; AResetContent: Boolean = False); overload;
    constructor CreateEx(const R: TRect; APixelFormat: TPixelFormat = pf32bit; AResetContent: Boolean = False); overload;
    constructor CreateEx(W, H: Integer; APixelFormat: TPixelFormat = pf32bit; AResetContent: Boolean = False); overload;
    procedure LoadFromResource(Inst: HINST; const AName, AType: UnicodeString);
    procedure LoadFromStream(Stream: TStream); override;
    procedure SetSize(const R: TRect); reintroduce; overload;
    // Effects
    procedure ApplyColorSchema(const AValue: TACLColorSchema);
    procedure MakeOpaque;
    procedure MakeTransparent(AColor: TColor);
    procedure Reset;
    // Properties
    property ClientRect: TRect read GetClientRect;
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
    MaskPixel: TACLPixel32 = (B: 255; G: 0; R: 255; A: 0); // clFuchsia
    NullPixel: TACLPixel32 = (B: 0; G: 0; R: 0; A: 0);
  public class var
    PremultiplyTable: TACLPixelMap;
    UnpremultiplyTable: TACLPixelMap;
  public
    class constructor Create;
    class function CompareRGB(const Q1, Q2: TACLPixel32): Boolean; inline; static;
    class function IsDark(Color: TColor): Boolean;
    class function IsMask(const P: TACLPixel32): Boolean; inline; static;

    class procedure AlphaBlend(var D: TColor; S: TColor; AAlpha: Integer = 255); overload; inline; static;
    class procedure AlphaBlend(var D: TACLPixel32; const S: TACLPixel32;
      AAlpha: Integer = 255; AProcessPerChannelAlpha: Boolean = True); overload; inline; static;
    class procedure ApplyColorSchema(AColors: PACLPixel32;
      ACount: Integer; const AValue: TACLColorSchema); overload; inline; static;
    class procedure ApplyColorSchema(const AFont: TFont; const AValue: TACLColorSchema); overload;
    class procedure ApplyColorSchema(var AColor: TAlphaColor; const AValue: TACLColorSchema); overload;
    class procedure ApplyColorSchema(var AColor: TColor; const AValue: TACLColorSchema); overload;
    class procedure ApplyColorSchema(var AColor: TACLPixel32; const AValue: TACLColorSchema); overload;
    class function ArePremultiplied(AColors: PACLPixel32; ACount: Integer): Boolean;
    class procedure Flip(AColors: PACLPixel32Array; AWidth, AHeight: Integer; AHorizontally, AVertically: Boolean);
    class procedure Flush(var P: TACLPixel32); inline; static;
    class procedure Grayscale(P: PACLPixel32; Count: Integer; IgnoreMask: Boolean = False); overload; static;
    class procedure Grayscale(var P: TACLPixel32; IgnoreMask: Boolean = False); overload; inline; static;
    class function Hue(Color: TColor): Single; overload; static;
    class function Invert(Color: TColor): TColor; static;
    class function Lightness(Color: TColor): Single; overload; static;
    class procedure MakeDisabled(P: PACLPixel32; Count: Integer; IgnoreMask: Boolean = False); overload; static;
    class procedure MakeDisabled(var P: TACLPixel32; IgnoreMask: Boolean = False); overload; inline; static;
    class procedure MakeTransparent(P: PACLPixel32; ACount: Integer; const AColor: TACLPixel32); overload;
    class procedure Premultiply(P: PACLPixel32; ACount: Integer); overload; static;
    class procedure Premultiply(var P: TACLPixel32); overload; inline; static;
    class procedure Unpremultiply(P: PACLPixel32; ACount: Integer); overload; static;
    class procedure Unpremultiply(var P: TACLPixel32); overload; inline; static;

    // Coloration
    // Pixels must be unpremultiplied
    class procedure ChangeColor(P: PACLPixel32; ACount: Integer; const AColor: TACLPixel32); static;
    class procedure ChangeHue(P: PACLPixel32; ACount: Integer; AHue: Byte; AIntensity: Byte = 100); overload; static;
    class procedure ChangeHue(var P: TACLPixel32; AHue: Byte; AIntensity: Byte = 100); overload; inline; static;
    class procedure Tint(P: PACLPixel32; ACount: Integer; const ATintColor: TACLPixel32); overload; static;

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
procedure acAlphaBlend(Dest, Src: HDC;
  const DR, SR: TRect; AAlpha: Integer = 255; AUseSourceAlpha: Boolean = True); overload;
procedure acAlphaBlend(Dest: HDC; ABitmap: TBitmap;
  const DR: TRect; AAlpha: Integer = 255; AUseSourceAlpha: Boolean = True); overload;
procedure acAlphaBlend(Dest: HDC; ABitmap: TBitmap;
  const DR, SR: TRect; AAlpha: Integer = 255; AUseSourceAlpha: Boolean = True); overload;
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
procedure acDrawColorPreview(ACanvas: TCanvas; R: TRect; AColor: TAlphaColor;
  ABorderColor, AHatchColor1, AHatchColor2: TColor); overload;
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
procedure acFillRect(DC: HDC; const ARect: TRect; AColor: TAlphaColor); overload;
procedure acFillRect(DC: HDC; const ARect: TRect; AColor: TColor); overload;
procedure acFitFileName(ACanvas: TCanvas; ATargetWidth: Integer; var S: UnicodeString); deprecated;
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
function acRegionFromBitmap(AColors: PACLPixel32; AWidth, AHeight: Integer; ATransparentColor: TColor): HRGN; overload;

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
procedure acGetBitmapBits(ABitmap: THandle; AWidth, AHeight: Integer;
  out AColors: TRGBColors; out ABitmapInfo: TBitmapInfo); overload;
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

function acTextAlign(const R: TRect; const ATextSize: TSize; AHorzAlignment: TAlignment;
  AVertAlignment: TVerticalAlignment; APreventTopLeftExceed: Boolean = False): TPoint;
function acTextEllipsize(ACanvas: TCanvas;
  var AText: UnicodeString; var ATextSize: TSize; AMaxWidth: Integer): Integer;
procedure acTextDraw(ACanvas: TCanvas; const S: UnicodeString; const R: TRect;
  AHorzAlignment: TAlignment = taLeftJustify; AVertAlignment: TVerticalAlignment = taAlignTop;
  AEndEllipsis: Boolean = False; APreventTopLeftExceed: Boolean = False; AWordWrap: Boolean = False);
procedure acTextDrawHighlight(ACanvas: TCanvas; const S: UnicodeString; const R: TRect;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AEndEllipsis: Boolean;
  AHighlightStart, AHighlightFinish: Integer; AHighlightColor, AHighlightTextColor: TColor);
procedure acTextDrawVertical(ACanvas: TCanvas; const S: UnicodeString; const R: TRect; AHorzAlignment: TAlignment;
  AVertAlignment: TVerticalAlignment; AEndEllipsis: Boolean = False); overload;
procedure acTextOut(ACanvas: TCanvas; X, Y: Integer; const S: UnicodeString; AFlags: Integer; ARect: PRect = nil); inline;

function acTextSize(ACanvas: TCanvas; const AText: PWideChar; ALength: Integer): TSize; overload;
function acTextSize(ACanvas: TCanvas; const AText: UnicodeString;
  AStartIndex: Integer = 1; ALength: Integer = MaxInt): TSize; overload;
function acTextSize(Font: TFont; const AText: UnicodeString;
  AStartIndex: Integer = 1; ALength: Integer = MaxInt): TSize; overload;
function acTextSize(Font: TFont; const AText: PWideChar; ALength: Integer): TSize; overload;
function acTextSizeMultiline(ACanvas: TCanvas;
  const AText: UnicodeString; AMaxWidth: Integer = 0): TSize;

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

function acRegionFromBitmap(AColors: PACLPixel32; AWidth, AHeight: Integer; ATransparentColor: TColor): HRGN;

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
  ATransparent: TACLPixel32;
  X, Y: Integer;
begin
  Result := 0;
  ATransparent.B := GetBValue(ATransparentColor);
  ATransparent.G := GetGValue(ATransparentColor);
  ATransparent.R := GetRValue(ATransparentColor);
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

function acTextAlign(const R: TRect; const ATextSize: TSize; AHorzAlignment: TAlignment;
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
  LTextRect: TRect;
begin
  LTextRect := Rect(0, 0, AMaxWidth, 2);
  acSysDrawText(ACanvas, LTextRect, AText, DT_CALCRECT or DT_WORDBREAK);
  Result := LTextRect.Size;
end;

procedure acTextDraw(ACanvas: TCanvas; const S: UnicodeString; const R: TRect;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment;
  AEndEllipsis, APreventTopLeftExceed, AWordWrap: Boolean);
var
  LMultiLine: Boolean;
  LText: UnicodeString;
  LTextFlags: Integer;
  LTextOffset: TPoint;
  LTextRect: TRect;
  LTextSize: TSize;
begin
  if (S <> '') and acRectVisible(ACanvas.Handle, R) then
  begin
    LMultiLine := acPos(#13, S) > 0;
    if AWordWrap or LMultiLine then
    begin
      LTextRect := R;
      LTextFlags := acTextAlignHorz[AHorzAlignment] or acTextAlignVert[AVertAlignment];
      if AEndEllipsis then
        LTextFlags := LTextFlags or DT_END_ELLIPSIS;
      if AWordWrap then
        LTextFlags := LTextFlags or DT_WORDBREAK
      else if not LMultiLine then
        LTextFlags := LTextFlags or DT_SINGLELINE;
      acSysDrawText(ACanvas, LTextRect, S, LTextFlags);
    end
    else
      if (AHorzAlignment <> taLeftJustify) or (AVertAlignment <> taAlignTop) or AEndEllipsis then
      begin
        LText := S;
        LTextSize := acTextSize(ACanvas, LText);
        if AEndEllipsis then
          acTextEllipsize(ACanvas, LText, LTextSize, R.Width);
        LTextOffset := acTextAlign(R, LTextSize, AHorzAlignment, AVertAlignment, APreventTopLeftExceed);
        acTextOut(ACanvas, LTextOffset.X, LTextOffset.Y, LText, ETO_CLIPPED, @R);
      end
      else
        acTextOut(ACanvas, R.Left, R.Top, S, ETO_CLIPPED, @R);
  end;
end;

procedure acTextDrawHighlight(ACanvas: TCanvas; const S: UnicodeString; const R: TRect;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AEndEllipsis: Boolean;
  AHighlightStart, AHighlightFinish: Integer; AHighlightColor, AHighlightTextColor: TColor);
var
  LHighlightRect: TRect;
  LHighlightTextSize: TSize;
  LPrevTextColor: TColor;
  LSaveRgn: HRGN;
  LText: UnicodeString;
  LTextOffset: TPoint;
  LTextPart: UnicodeString;
  LTextPartSize: TSize;
  LTextSize: TSize;
begin
  if AHighlightFinish > AHighlightStart then
  begin
    LText := S;
    LTextSize := acTextSize(ACanvas, LText);
    if AEndEllipsis then
      AHighlightFinish := Min(AHighlightFinish, acTextEllipsize(ACanvas, LText, LTextSize, R.Width));
    LTextOffset := acTextAlign(R, LTextSize, AHorzAlignment, AVertAlignment, True);
    LTextPart := Copy(LText, 1, AHighlightStart);
    LTextPartSize := acTextSize(ACanvas, LTextPart);
    LTextPart := Copy(LText, 1, AHighlightFinish);
    LHighlightTextSize := acTextSize(ACanvas, LTextPart);
    Dec(LHighlightTextSize.cx, LTextPartSize.cx);

    LHighlightRect := R;
    LHighlightRect.Left := LTextOffset.X + LTextPartSize.cx;
    LHighlightRect.Right := LHighlightRect.Left + LHighlightTextSize.cx;

    LSaveRgn := acSaveClipRegion(ACanvas.Handle);
    try
      acExcludeFromClipRegion(ACanvas.Handle, LHighlightRect);
      acTextOut(ACanvas, LTextOffset.X, LTextOffset.Y, LText, ETO_CLIPPED, @R);
    finally
      acRestoreClipRegion(ACanvas.Handle, LSaveRgn);
    end;

    LSaveRgn := acSaveClipRegion(ACanvas.Handle);
    try
      if acIntersectClipRegion(ACanvas.Handle, LHighlightRect) then
      begin
        acFillRect(ACanvas.Handle, LHighlightRect, AHighlightColor);
        LPrevTextColor := ACanvas.Font.Color;
        ACanvas.Font.Color := AHighlightTextColor;
        acTextOut(ACanvas, LTextOffset.X, LTextOffset.Y, LText, ETO_CLIPPED, @R);
        ACanvas.Font.Color := LPrevTextColor;
      end;
    finally
      acRestoreClipRegion(ACanvas.Handle, LSaveRgn);
    end;
  end
  else
    acTextDraw(ACanvas, S, R, AHorzAlignment, AVertAlignment, AEndEllipsis);
end;

procedure acTextDrawVertical(ACanvas: TCanvas; const S: UnicodeString; const R: TRect;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AEndEllipsis: Boolean = False);
const
  MapVert: array[TAlignment] of TVerticalAlignment = (taAlignBottom, taAlignTop, taVerticalCenter);
var
  LText: string;
  LTextOffset: TPoint;
  LTextSize: TSize;
begin
  ACanvas.Font.Orientation := 900;
  try
    LText := S;
    LTextSize := acTextSize(ACanvas, LText);
    if AEndEllipsis then
      acTextEllipsize(ACanvas, LText, LTextSize, R.Height);
    acExchangeIntegers(LTextSize.cx, LTextSize.cy);
    LTextOffset := acTextAlign(R, LTextSize, TAlignment(AVertAlignment), MapVert[AHorzAlignment]);
    acTextOut(ACanvas, LTextOffset.X, LTextOffset.Y + LTextSize.cy, LText, 0);
  finally
    ACanvas.Font.Orientation := 0;
  end;
end;

function acTextEllipsize(ACanvas: TCanvas;
  var AText: UnicodeString;
  var ATextSize: TSize; AMaxWidth: Integer): Integer;
begin
  if ATextSize.cx > AMaxWidth then
  begin
    GetTextExtentExPointW(ACanvas.Handle, PChar(AText), Length(AText),
      Max(0, AMaxWidth - acTextSize(ACanvas, acEndEllipsis).cx), @Result, nil, ATextSize);
    AText := Copy(AText, 1, Result) + acEndEllipsis;
    ATextSize := acTextSize(ACanvas, AText);
  end
  else
    Result := Length(AText);
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
//            acTextAlign(R, ALayout.MeasureSize,
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
  ASize := R.Size;
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
    R.CenterHorz(1);
    R.CenterVert(1);
    ABrush := CreateSolidBrush(ColorToRGB(AColor));
    while Count > 0 do
    begin
      FillRect(DC, R, ABrush);
      R.Content(Extends);
      Dec(Count);
    end;
    DeleteObject(ABrush);
  end;

var
  ASize: Integer;
begin
  ASize := MulDiv(2, ATargetDPI, acDefaultDPI);
  if AArrowKind in [makLeft, makRight] then
  begin
    R.CenterHorz(ASize + 1);
    R.CenterVert(ASize * 2 + 1);
  end
  else
  begin
    R.CenterHorz(ASize * 2 + 1);
    R.CenterVert(ASize + 1);
  end;

  case AArrowKind of
    makLeft:
      Draw(R.Split(srLeft, 1), Rect(1, -1, -1, -1), ASize + 1);
    makRight:
      Draw(R.Split(srLeft, R.Right, 1), Rect(-1, -1, 1, -1), ASize + 1);
    makTop:
      Draw(R.Split(srTop, 1), Rect(-1, 1, -1, -1), ASize + 1);
    makBottom:
      Draw(R.Split(srTop, R.Bottom, 1), Rect(-1, -1, -1, 1), ASize + 1);
  end;
end;

function acGetArrowSize(AArrowKind: TACLArrowKind; ATargetDPI: Integer): TSize;
var
  ASize: Integer;
begin
  ASize := MulDiv(2, ATargetDPI, acDefaultDPI);
  if AArrowKind in [makLeft, makRight] then
    Result := TSize.Create(ASize + 1, ASize * 2 + 1)
  else
    Result := TSize.Create(ASize * 2 + 1, ASize + 1);
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

procedure acDrawColorPreview(ACanvas: TCanvas; R: TRect;
  AColor: TAlphaColor; ABorderColor, AHatchColor1, AHatchColor2: TColor);
var
  APrevFontColor: TColor;
begin
  acDrawFrame(ACanvas.Handle, R, ABorderColor);
  R.Inflate(-1);
  acDrawFrame(ACanvas.Handle, R, AHatchColor1);
  R.Inflate(-1);
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
  acExcludeFromClipRegion(ACanvas.Handle, R.InflateTo(2));
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
begin
  Result := TACLBitmap.CreateEx(2 * ASize, 2 * ASize, pf24bit);
  acFillRect(Result.Canvas.Handle, Bounds(0,         0, ASize, ASize), AColor2);
  acFillRect(Result.Canvas.Handle, Bounds(0,     ASize, ASize, ASize), AColor1);
  acFillRect(Result.Canvas.Handle, Bounds(ASize,     0, ASize, ASize), AColor1);
  acFillRect(Result.Canvas.Handle, Bounds(ASize, ASize, ASize, ASize), AColor2);
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
  R1.Inflate(-1);
  acDrawFrame(DC, R1, ABorderColor);
  R1.Inflate(-2);
  acFillRect(DC, R1.CenterTo(R1.Right - R1.Left, 1), AColor);
  if not AExpanded then
    acFillRect(DC, R1.CenterTo(1, R1.Bottom - R1.Top), AColor);
end;

procedure acTileBlt(DC, SourceDC: HDC; const ADest, ASource: TRect);
var
  ABrush: HBRUSH;
  ABrushBitmap: TACLDib;
  AClipRgn: HRGN;
  AOrigin: TPoint;
  R: TRect;
  W, H: Integer;
  X, Y, XCount, YCount: Integer;
begin
  if not (ADest.IsEmpty or ASource.IsEmpty) and RectVisible(DC, ADest) then
  begin
    W := ASource.Right - ASource.Left;
    H := ASource.Bottom - ASource.Top;
    R := ADest;
    R.Height := H;
    XCount := acCalcPatternCount(ADest.Right - ADest.Left, W);
    YCount := acCalcPatternCount(ADest.Bottom - ADest.Top, H);

    if XCount * YCount > 10 then
    begin
      ABrushBitmap := TACLDib.Create(W, H);
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

procedure acDrawFrameEx(DC: HDC; const ARect: TRect;
  AColor: TColor; ABorders: TACLBorders; AThickness: Integer = 1);
var
  LClipRegion: HRGN;
  LClipRect: TRect;
begin
  if AColor <> clNone then
  begin
    LClipRegion := acSaveClipRegion(DC);
    try
      LClipRect := ARect;
      LClipRect.Content(AThickness, ABorders);
      acExcludeFromClipRegion(DC, LClipRect);
      acFillRect(DC, ARect, AColor);
    finally
      acRestoreClipRegion(DC, LClipRegion);
    end;
  end;
end;

procedure acDrawFrameEx(DC: HDC; ARect: TRect;
  AColor: TAlphaColor; ABorders: TACLBorders; AThickness: Integer = 1);
var
  LClipRegion: HRGN;
  LClipRect: TRect;
begin
  if AColor.IsValid then
  begin
    LClipRegion := acSaveClipRegion(DC);
    try
      LClipRect := ARect;
      LClipRect.Content(AThickness, ABorders);
      acExcludeFromClipRegion(DC, LClipRect);
      acFillRect(DC, ARect, AColor);
    finally
      acRestoreClipRegion(DC, LClipRegion);
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
      ARect.Left, ARect.Top, ARect.Width, ARect.Height);
    GdipDeleteGraphics(AHandle);
  end;
end;

procedure acDrawComplexFrame(DC: HDC; const R: TRect;
  AColor1, AColor2: TColor; ABorders: TACLBorders = acAllBorders);
var
  LInnerFrame: TRect;
begin
  LInnerFrame := R;
  LInnerFrame.Content(1, ABorders);
  acDrawFrameEx(DC, R, AColor1, ABorders);
  acDrawFrameEx(DC, LInnerFrame, AColor2, ABorders);
end;

procedure acDrawComplexFrame(DC: HDC; const R: TRect;
  AColor1, AColor2: TAlphaColor; ABorders: TACLBorders = acAllBorders);
var
  LInnerFrame: TRect;
begin
  LInnerFrame := R;
  LInnerFrame.Content(1, ABorders);
  acDrawFrameEx(DC, R, AColor1, ABorders);
  acDrawFrameEx(DC, LInnerFrame, AColor2, ABorders);
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
  if not R.IsEmpty then
  begin
    AValue := 0;
    ADelta := 1.0 / R.Width;
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
  if not R.IsEmpty then
  begin
    AValue := 0;
    ADelta := 1.0 / R.Width;
    for I := R.Left to R.Right do
    begin
      TACLColors.HSLtoRGB(AValue, 1.0, 0.5, AColor);
      acFillRect(ACanvas.Handle, Rect(I, R.Top, I + 1, R.Bottom), AColor);
      AValue := AValue + ADelta;
    end;
  end;
end;

{ TACLPixel32 }

class function TACLPixel32.Create(A, R, G, B: Byte): TACLPixel32;
begin
  Result.B := B;
  Result.G := G;
  Result.R := R;
  Result.A := A;
end;

class function TACLPixel32.Create(AColor: TAlphaColor): TACLPixel32;
begin
  Result.B := AColor.B;
  Result.G := AColor.G;
  Result.R := AColor.R;
  Result.A := AColor.A;
end;

class function TACLPixel32.Create(AColor: TColor; AAlpha: Byte = MaxByte): TACLPixel32;
begin
  AColor := ColorToRGB(AColor);
  Result.R := GetRValue(AColor);
  Result.G := GetGValue(AColor);
  Result.B := GetBValue(AColor);
  Result.A := AAlpha;
end;

class operator TACLPixel32.Implicit(const Value: TACLPixel32): TRGBQuad;
begin
  DWORD(Result) := DWORD(Value);
end;

function TACLPixel32.ToColor: TColor;
begin
  Result := RGB(R, G, B);
end;

class operator TACLPixel32.Implicit(const Value: TRGBQuad): TACLPixel32;
begin
  DWORD(Result) := DWORD(Value);
end;

{ TAlphaColorHelper }

class function TAlphaColorHelper.ApplyColorSchema(
  AColor: TAlphaColor; const ASchema: TACLColorSchema): TAlphaColor;
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
    Exit(TAlphaColor.Default);
  if AColor = clNone then
    Exit(TAlphaColor.None);
  Result := FromColor(TACLPixel32.Create(AColor, AAlpha));
end;

class function TAlphaColorHelper.FromColor(const AColor: TACLPixel32): TAlphaColor;
begin
  Result := FromARGB(AColor.A, AColor.R, AColor.G, AColor.B);
end;

class function TAlphaColorHelper.FromString(AColor: UnicodeString): TAlphaColor;
var
  P: TACLPixel32;
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

  P.A := StrToIntDef('$' + Copy(AColor, 1, 2), 0);
  P.R := StrToIntDef('$' + Copy(AColor, 3, 2), 0);
  P.G := StrToIntDef('$' + Copy(AColor, 5, 2), 0);
  P.B := StrToIntDef('$' + Copy(AColor, 7, 2), 0);
  Result := TAlphaColor.FromColor(P);
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

function TAlphaColorHelper.ToPixel: TACLPixel32;
begin
  Result.B := Byte(Self shr BlueShift);
  Result.G := Byte(Self shr GreenShift);
  Result.R := Byte(Self shr RedShift);
  Result.A := Self shr AlphaShift;
end;

function TAlphaColorHelper.ToString: string;
begin
  if Self = TAlphaColor.None then
    Result := 'None'
  else
    if Self = TAlphaColor.Default then
      Result := 'Default'
    else
      with ToPixel do
        Result :=
          IntToHex(A, 2) +
          IntToHex(R, 2) +
          IntToHex(G, 2) +
          IntToHex(B, 2);
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
    R.Offset(-R.Left, -R.Top);
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
      ARect.Add(AScanR^);
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

{ TACLDib }

constructor TACLDib.Create(const R: TRect);
begin
  Create(R.Width, R.Height);
end;

constructor TACLDib.Create(const S: TSize);
begin
  Create(S.cx, S.cy);
end;

constructor TACLDib.Create(const W, H: Integer);
begin
  CreateHandles(W, H);
end;

destructor TACLDib.Destroy;
begin
  FreeHandles;
  inherited Destroy;
end;

procedure TACLDib.Assign(ALayer: TACLDib);
begin
  if ALayer <> Self then
  begin
    Resize(ALayer.Width, ALayer.Height);
    acBitBlt(Handle, ALayer.Handle, ClientRect, NullPoint);
//    FastMove(ALayer.Colors^, Colors^, ColorCount * SizeOf(TACLPixel32));
  end;
end;

procedure TACLDib.AssignParams(DC: HDC);
begin
  SelectObject(Handle, GetCurrentObject(DC, OBJ_BRUSH));
  SelectObject(Handle, GetCurrentObject(DC, OBJ_FONT));
  SetTextColor(Handle, GetTextColor(DC));
end;

function TACLDib.Clone(out AData: PACLPixel32Array): Boolean;
var
  ASize: Integer;
begin
  ASize := ColorCount * SizeOf(TACLPixel32);
  Result := ASize > 0;
  if Result then
  begin
    AData := AllocMem(ASize);
    FastMove(FColors^, AData^, ASize);
  end;
end;

function TACLDib.CoordToFlatIndex(X, Y: Integer): Integer;
begin
  if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
    Result := X + Y * Width
  else
    Result := -1;
end;

procedure TACLDib.ApplyTint(const AColor: TColor);
begin
  ApplyTint(TAlphaColor.FromColor(AColor).ToPixel);
end;

procedure TACLDib.ApplyTint(const AColor: TACLPixel32);
var
  P: PACLPixel32;
  I: Integer;
begin
  P := @FColors^[0];
  for I := 0 to ColorCount - 1 do
  begin
    if P^.A > 0 then
    begin
      TACLColors.Unpremultiply(P^);
      P^.B := AColor.B;
      P^.G := AColor.G;
      P^.R := AColor.R;
      TACLColors.Premultiply(P^);
    end;
    Inc(P);
  end;
end;

procedure TACLDib.DrawBlend(ACanvas: TCanvas; const R: TRect; AAlpha: Byte);
begin
  acAlphaBlend(ACanvas.Handle, Handle, R, ClientRect, AAlpha);
end;

procedure TACLDib.DrawBlend(DC: HDC; const P: TPoint; AAlpha: Byte = 255);
begin
  acAlphaBlend(DC, Handle, Bounds(P.X, P.Y, Width, Height), ClientRect, AAlpha);
end;

procedure TACLDib.DrawCopy(DC: HDC; const P: TPoint);
begin
  acBitBlt(DC, Handle, Bounds(P.X, P.Y, Width, Height), NullPoint);
end;

procedure TACLDib.DrawCopy(DC: HDC; const R: TRect; ASmoothStretch: Boolean = False);
var
  AMode: Integer;
begin
  if ASmoothStretch and not R.EqualSizes(ClientRect) then
  begin
    AMode := SetStretchBltMode(DC, HALFTONE);
    acStretchBlt(DC, Handle, R, ClientRect);
    SetStretchBltMode(DC, AMode);
  end
  else
    acStretchBlt(DC, Handle, R, ClientRect);
end;

procedure TACLDib.Flip(AHorizontally, AVertically: Boolean);
begin
  TACLColors.Flip(Colors, Width, Height, AHorizontally, AVertically);
end;

procedure TACLDib.MakeDisabled(AIgnoreMask: Boolean = False);
begin
  TACLColors.MakeDisabled(@FColors^[0], ColorCount, AIgnoreMask);
end;

procedure TACLDib.MakeMirror(ASize: Integer);
var
  AAlpha: Single;
  AAlphaDelta: Single;
  AIndex: Integer;
  I, J, O1, O2, R: Integer;
begin
  if (ASize > 0) and (ASize < Height div 2) then
  begin
    AAlpha := 60;
    AAlphaDelta := AAlpha / ASize;
    O2 := Width;
    O1 := O2 * (Height - ASize);

    AIndex := O1;
    for J := 0 to ASize - 1 do
    begin
      R := Round(AAlpha);
      for I := 0 to O2 - 1 do
      begin
        TACLColors.AlphaBlend(Colors^[AIndex], Colors^[O1 + I], R, False);
        Inc(AIndex);
      end;
      AAlpha := AAlpha - AAlphaDelta;
      Dec(O1, O2);
    end;
  end;
end;

procedure TACLDib.MakeOpaque;
var
  I: Integer;
  P: PACLPixel32;
begin
  P := @FColors^[0];
  for I := 0 to ColorCount - 1 do
  begin
    P^.A := $FF;
    Inc(P);
  end;
end;

procedure TACLDib.MakeTransparent(AColor: TColor);
var
  I: Integer;
  P: PACLPixel32;
  R: TACLPixel32;
begin
  P := @FColors^[0];
  R := TACLPixel32.Create(AColor);
  for I := 0 to ColorCount - 1 do
  begin
    if TACLColors.CompareRGB(P^, R) then
      TACLColors.Flush(P^)
    else
      P^.A := $FF;
    Inc(P);
  end;
end;

procedure TACLDib.Premultiply(R: TRect);
var
  Y: Integer;
begin
  IntersectRect(R, R, ClientRect);
  for Y := R.Top to R.Bottom - 1 do
    TACLColors.Premultiply(@FColors^[Y * Width + R.Left], R.Right - R.Left - 1);
end;

procedure TACLDib.Premultiply;
begin
  TACLColors.Premultiply(@FColors^[0], ColorCount);
end;

procedure TACLDib.Reset;
var
  APrevPoint: TPoint;
begin
  SetWindowOrgEx(Handle, 0, 0, @APrevPoint);
  acResetRect(Handle, ClientRect);
  SetWindowOrgEx(Handle, APrevPoint.X, APrevPoint.Y, nil);
end;

procedure TACLDib.Reset(const R: TRect);
begin
  acResetRect(Handle, R);
end;

procedure TACLDib.Resize(const R: TRect);
begin
  Resize(R.Width, R.Height);
end;

procedure TACLDib.Resize(ANewWidth, ANewHeight: Integer);
begin
  if (ANewWidth <> Width) or (ANewHeight <> Height) then
  begin
    FreeHandles;
    CreateHandles(ANewWidth, ANewHeight);
  end;
end;

procedure TACLDib.CreateHandles(W, H: Integer);
var
  AInfo: TBitmapInfo;
begin
  if (W <= 0) or (H <= 0) then
    Exit;

  FWidth := W;
  FHeight := H;
  FColorCount := W * H;
  FHandle := CreateCompatibleDC(0);
  acFillBitmapInfoHeader(AInfo.bmiHeader, Width, Height);
  FBitmap := CreateDIBSection(0, AInfo, DIB_RGB_COLORS, Pointer(FColors), 0, 0);
  FOldBmp := SelectObject(Handle, Bitmap);
  if FColors = nil then
  begin
    FreeHandles;
    raise EInvalidGraphicOperation.CreateFmt('Unable to create bitmap layer (%dx%d)', [W, H]);
  end;
end;

procedure TACLDib.FreeHandles;
begin
  FreeAndNil(FCanvas);
  if Handle <> 0 then
  begin
    SelectObject(Handle, FOldBmp);
    DeleteObject(Bitmap);
    DeleteDC(Handle);
    FColorCount := 0;
    FColors := nil;
    FHeight := 0;
    FBitmap := 0;
    FHandle := 0;
    FWidth := 0;
  end;
end;

function TACLDib.GetCanvas: TCanvas;
begin
  if FCanvas = nil then
  begin
    FCanvas := TCanvas.Create;
    FCanvas.Lock;
    FCanvas.Handle := Handle;
    FCanvas.Brush.Style := bsClear;
  end;
  Result := FCanvas;
end;

function TACLDib.GetClientRect: TRect;
begin
  Result := Rect(0, 0, Width, Height);
end;

function TACLDib.GetEmpty: Boolean;
begin
  Result := FColorCount = 0;
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

procedure TACLBitmap.MakeOpaque;
var
  ABits: TRGBColors;
begin
  ABits := acGetBitmapBits(Self);
  try
    for var I := 0 to Length(ABits) - 1 do
      ABits[I].rgbReserved := MaxByte;
  finally
    acSetBitmapBits(Self, ABits);
  end;
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
      TACLColors.MakeTransparent(@ABits[0], Length(ABits), TACLPixel32.Create(AColor));
    finally
      acSetBitmapBits(Self, ABits);
    end;
  end;
end;

procedure TACLBitmap.Reset;
begin
  acResetRect(Canvas.Handle, ClientRect);
end;

procedure TACLBitmap.SetSize(const R: TRect);
begin
  SetSize(Max(0, R.Width), Max(0, R.Height));
end;

{ TACLColors }

class constructor TACLColors.Create;
var
  I, J: Integer;
begin
  for I := 1 to 255 do
    for J := I to 255 do
    begin
      PremultiplyTable[I, J] := MulDiv(I, J, 255);
      PremultiplyTable[J, I] := PremultiplyTable[I, J];

      UnpremultiplyTable[I, J] := MulDiv(I, 255, J);
      UnpremultiplyTable[J, I] := UnpremultiplyTable[I, J];
    end;
end;

class function TACLColors.CompareRGB(const Q1, Q2: TACLPixel32): Boolean;
begin
  Result := (Q1.B = Q2.B) and (Q1.G = Q2.G) and (Q1.R = Q2.R);
end;

class function TACLColors.IsDark(Color: TColor): Boolean;
begin
  Result := Lightness(Color) < 0.45;
end;

class function TACLColors.IsMask(const P: TACLPixel32): Boolean;
begin
  Result := (P.G = MaskPixel.G) and (P.B = MaskPixel.B) and (P.R = MaskPixel.R);
end;

class procedure TACLColors.AlphaBlend(var D: TColor; S: TColor; AAlpha: Integer = 255);
var
  DQ, SQ: TACLPixel32;
begin
  DQ := TACLPixel32.Create(D);
  SQ := TACLPixel32.Create(S);
  AlphaBlend(DQ, SQ, AAlpha);
  D := DQ.ToColor;
end;

class procedure TACLColors.AlphaBlend(var D: TACLPixel32; const S: TACLPixel32;
  AAlpha: Integer = 255; AProcessPerChannelAlpha: Boolean = True);
var
  A: Integer;
begin
  if AProcessPerChannelAlpha then
    A := PremultiplyTable[S.A, AAlpha]
  else
    A := AAlpha;

  if (A <> MaxByte) or (AAlpha <> MaxByte) then
  begin
    A := MaxByte - A;
    D.R := PremultiplyTable[D.R, A] + PremultiplyTable[S.R, AAlpha];
    D.B := PremultiplyTable[D.B, A] + PremultiplyTable[S.B, AAlpha];
    D.G := PremultiplyTable[D.G, A] + PremultiplyTable[S.G, AAlpha];
    D.A := PremultiplyTable[D.A, A] + PremultiplyTable[S.A, AAlpha];
  end
  else
    TAlphaColor(D) := TAlphaColor(S);
end;

class procedure TACLColors.ApplyColorSchema(var AColor: TColor; const AValue: TACLColorSchema);
var
  P: TACLPixel32;
begin
  if AValue.IsAssigned then
  begin
    P := TACLPixel32.Create(AColor);
    ApplyColorSchema(P, AValue);
    AColor := P.ToColor;
  end;
end;

class procedure TACLColors.ApplyColorSchema(
  AColors: PACLPixel32; ACount: Integer; const AValue: TACLColorSchema);
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
  P: TACLPixel32;
begin
  if AColor.IsValid and AValue.IsAssigned then
  begin
    P := TACLPixel32.Create(AColor);
    ApplyColorSchema(P, AValue);
    AColor := TAlphaColor.FromColor(P);
  end;
end;

class procedure TACLColors.ApplyColorSchema(var AColor: TACLPixel32; const AValue: TACLColorSchema);
begin
  if AValue.IsAssigned then
    ChangeHue(AColor, AValue.Hue, AValue.HueIntensity);
end;

//#AI: https://github.com/chromium/chromium/blob/master/ui/base/clipboard/clipboard_win.cc#L652
class function TACLColors.ArePremultiplied(AColors: PACLPixel32; ACount: Integer): Boolean;
begin
  while ACount > 0 do
  begin
    with AColors^ do
    begin
      if R > A then Exit(False);
      if G > A then Exit(False);
      if B > A then Exit(False);
    end;
    Inc(AColors);
    Dec(ACount);
  end;
  Result := True;
end;

class procedure TACLColors.ChangeColor(P: PACLPixel32; ACount: Integer; const AColor: TACLPixel32);
var
  Cmax, Cmin: Integer;
  H, S, L: Byte;
begin
  RGBtoHSLi(AColor.R, AColor.G, AColor.B, H, S, L);
  while ACount > 0 do
  begin
    if not IsMask(P^) then
    begin
      Cmax := Max(P^.R, Max(P^.G, P^.B));
      Cmin := Min(P^.R, Min(P^.G, P^.B));
      HSLtoRGBi(H, S, MulDiv(MaxByte, Cmax + Cmin, 2 * MaxByte), P^.R, P^.G, P^.B);
    end;
    Dec(ACount);
    Inc(P);
  end;
end;

class procedure TACLColors.ChangeHue(var P: TACLPixel32; AHue: Byte; AIntensity: Byte = 100);
var
  H, S, L: Byte;
begin
  if not IsMask(P) then
  begin
    TACLColors.RGBtoHSLi(P.R, P.G, P.B, H, S, L);
    TACLColors.HSLtoRGBi(AHue, MulDiv(S, AIntensity, 100), L, P.R, P.G, P.B);
  end;
end;

class procedure TACLColors.ChangeHue(P: PACLPixel32; ACount: Integer; AHue: Byte; AIntensity: Byte = 100);
begin
  while ACount > 0 do
  begin
    ChangeHue(P^, AHue, AIntensity);
    Dec(ACount);
    Inc(P);
  end;
end;

class procedure TACLColors.Flip(AColors: PACLPixel32Array; AWidth, AHeight: Integer; AHorizontally, AVertically: Boolean);
var
  I: Integer;
  Q1, Q2, Q3: PACLPixel32;
  Q4: TACLPixel32;
  RS: Integer;
begin
  if AVertically then
  begin
    Q1 := @AColors^[0];
    Q2 := @AColors^[(AHeight - 1) * AWidth];
    RS := AWidth * SizeOf(TACLPixel32);
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

class procedure TACLColors.Flush(var P: TACLPixel32);
begin
  PCardinal(@P)^ := 0;
end;

class procedure TACLColors.Grayscale(P: PACLPixel32; Count: Integer; IgnoreMask: Boolean = False);
begin
  while Count > 0 do
  begin
    Grayscale(P^, IgnoreMask);
    Dec(Count);
    Inc(P);
  end;
end;

class procedure TACLColors.Grayscale(var P: TACLPixel32; IgnoreMask: Boolean = False);
begin
  if IgnoreMask or not IsMask(P) then
  begin
    P.B := PremultiplyTable[P.B, 77] + PremultiplyTable[P.G, 150] + PremultiplyTable[P.R, 28];
    P.G := P.B;
    P.R := P.B;
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

class procedure TACLColors.MakeDisabled(P: PACLPixel32; Count: Integer; IgnoreMask: Boolean = False);
begin
  while Count > 0 do
  begin
    MakeDisabled(P^, IgnoreMask);
    Dec(Count);
    Inc(P);
  end;
end;

class procedure TACLColors.MakeDisabled(var P: TACLPixel32; IgnoreMask: Boolean = False);
var
  APixel: Byte;
begin
  if (P.A > 0) and (IgnoreMask or not IsMask(P)) then
  begin
    Unpremultiply(P);
    P.A := PremultiplyTable[P.A, 128];
    APixel := PremultiplyTable[P.B, 77] + PremultiplyTable[P.G, 150] + PremultiplyTable[P.R, 28];
    APixel := PremultiplyTable[APixel, P.A];
    P.B := APixel;
    P.G := APixel;
    P.R := APixel;
  end;
end;

class procedure TACLColors.MakeTransparent(P: PACLPixel32; ACount: Integer; const AColor: TACLPixel32);
begin
  while ACount > 0 do
  begin
    if CompareRGB(P^, AColor) then
      PDWORD(P)^ := 0
    else
      P^.A := MaxByte;
    Dec(ACount);
    Inc(P);
  end;
end;

class procedure TACLColors.Tint(P: PACLPixel32; ACount: Integer; const ATintColor: TACLPixel32);
var
  AAlpha: Byte;
begin
  if ATintColor.A = 0 then
    Exit;
  if ATintColor.A = MaxByte then
  begin
    while ACount > 0 do
    begin
      P.B := ATintColor.B;
      P.G := ATintColor.G;
      P.R := ATintColor.R;
      Dec(ACount);
      Inc(P);
    end;
  end
  else
  begin
    AAlpha := MaxByte - ATintColor.A;
    while ACount > 0 do
    begin
      P.B := PremultiplyTable[P.B, AAlpha] + PremultiplyTable[ATintColor.B, ATintColor.A];
      P.G := PremultiplyTable[P.G, AAlpha] + PremultiplyTable[ATintColor.G, ATintColor.A];
      P.R := PremultiplyTable[P.R, AAlpha] + PremultiplyTable[ATintColor.R, ATintColor.A];
      Dec(ACount);
      Inc(P);
    end;
  end;
end;

class procedure TACLColors.Premultiply(var P: TACLPixel32);
begin
  if P.A = 0 then
    DWORD(P) := 0
  else
    if P.A < 255 then
    begin
      P.R := PremultiplyTable[P.R, P.A];
      P.B := PremultiplyTable[P.B, P.A];
      P.G := PremultiplyTable[P.G, P.A];
    end;
end;

class procedure TACLColors.Premultiply(P: PACLPixel32; ACount: Integer);
begin
  while ACount > 0 do
  begin
    Premultiply(P^);
    Dec(ACount);
    Inc(P);
  end;
end;

class procedure TACLColors.Unpremultiply(var P: TACLPixel32);
begin
  if (P.A > 0) and (P.A < MaxByte) then
  begin
    P.G := UnpremultiplyTable[P.G, P.A];
    P.B := UnpremultiplyTable[P.B, P.A];
    P.R := UnpremultiplyTable[P.R, P.A];
  end;
end;

class procedure TACLColors.Unpremultiply(P: PACLPixel32; ACount: Integer);
begin
  while ACount > 0 do
  begin
    Unpremultiply(P^);
    Dec(ACount);
    Inc(P);
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
