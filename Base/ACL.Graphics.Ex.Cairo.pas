////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             Extended Graphics Library
//             v7.0
//
//  Purpose:   Cairo Wrappers
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       Gtk2/Gtk3
//
unit ACL.Graphics.Ex.Cairo;

{$I ACL.Config.inc}

{$DEFINE ACL_CAIRO_FONTS_SUBSTITUTION}
{$RANGECHECKS OFF}
{$POINTERMATH ON}

interface

uses
  Cairo,
{$IFDEF MSWINDOWS}
  CairoWin32,
  Windows,
{$ENDIF}
{$IFDEF LCLGtk2}
  GLib2,
  Gdk2,
  Gtk2Def,
  Gtk2Proc,
{$ENDIF}
{$IFDEF LCLGtk3}
  Gtk3Int,
  Gtk3Objects,
{$ENDIF}
{$IFDEF FPC}
  LazUtf8,
  LCLIntf,
  LCLType,
{$ENDIF}
  // System
  Classes,
  Math,
  SysUtils,
  System.UITypes,
  Types,
  // Vcl
  Graphics,
  // ACL
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.Ex.Stub,
  ACL.Graphics.TextLayout,
  ACL.Threading,
  ACL.Utils.Common,
  ACL.Utils.Logger,
  ACL.Utils.Strings;

type
  PCairoGlyphArray = ^TCairoGlyphArray;
  TCairoGlyphArray = array[0..0] of cairo_glyph_t;

  { EGSCairoError }

  EGSCairoError = class(Exception);

  { TCairoColor }

  TCairoColor = record
  public
    R, G, B, A: Double;
    class function From(A, R, G, B: Byte): TCairoColor; overload; static;
    class function From(Color: TAlphaColor): TCairoColor; overload; static;
    class function From(Color: TColor): TCairoColor; overload; static;
    class function From(Font: TFont): TCairoColor; overload; static;
  end;

  { TCairoContext }

  PCairoContext = ^TCairoContext;
  TCairoContext = record
  public
    Ownership: TStreamOwnership;
  {$IFDEF MSWINDOWS}
    DC: HDC;
    Index: Integer;
  {$ENDIF}
  end;

  { TCairoFontMetrics }

  TCairoFontMetrics = record
  public
    // same to cairo_font_extents_t
    ascent: Double;
    descent: Double;
    height: Double;
    max_x_advance: Double;
    max_y_advance: Double;
    // our extensions:
    baseline: Double;
    line_thickness: Double;
  end;

  { TACLTextLayoutCairoRender }

  TACLTextLayoutCairoRender = class(TACLTextLayoutCanvasRender)
  strict private
    FContext: PCairoContext;
    FFillColor: TCairoColor;
    FFillColorAssigned: Boolean;
    FFont: Pcairo_scaled_font_t;
    FFontColor: TCairoColor;
    FFontHasLines: Boolean;
    FFontMetrics: TCairoFontMetrics;
    FHandle: Pcairo_t;
    FHandleOwnership: TStreamOwnership;
    FLineHeight: Integer;
    FOrigin: TPoint;
    FSurface: Pcairo_surface_t;
  public
    constructor Create(ACanvas: TCanvas); override;
    constructor CreateEx(ACairo: Pcairo_t); overload;
    constructor CreateEx(ADib: TACLBaseDib); overload;
    destructor Destroy; override;
    function CreateCompatibleRender(ADib: TACLDib): TACLTextLayoutRender; override;
    // Drawing
    procedure DrawImage(ADib: TACLDib; const R: TRect); override;
    procedure DrawText(ABlock: TACLTextLayoutBlockText; X, Y: Integer); override;
    procedure DrawUnderline(const R: TRect); override;
    procedure FillBackground(const R: TRect); override;
    function GetClipBox(out R: TRect): Boolean; override;
    // Measuring
    procedure GetMetrics(out ABaseline, ALineHeight, ASpaceWidth: Integer); override;
    procedure Measure(ABlock: TACLTextLayoutBlockText); override;
    // Metrics
    class function GetChar(ABlock: TACLTextLayoutBlockText; var AOffset: Integer): PChar; override;
    class function GetCharPos(ABlock: TACLTextLayoutBlock; AOffset: Integer): TRect; override;
    class procedure Shrink(ABlock: TACLTextLayoutBlockText; AMaxSize: Integer); override;
    // Setup
    procedure SetFill(AValue: TColor); override;
    procedure SetFont(AFont: TFont); override;
    // Properties
    property Origin: TPoint read FOrigin write FOrigin;
  end;

{$REGION ' Render2D '}

  { TACLCairoRender }

  TACLCairoRender = class(TACL2DRender)
  strict private
    FContext: PCairoContext;
    FHandle: Pcairo_t;
    FHandleOwnership: TStreamOwnership;
    FImageSmoothStretching: TACLBoolean;
    FTargetSurface: Pcairo_surface_t;

    procedure CheckRecursivePaint;
    procedure PathEllipseArc(X1, Y1, X2, Y2: Double);
    procedure PathPolyline(Points: PPoint; Count: Integer; ClosePath: Boolean);
  public
    procedure BeginPaint(ACairo: Pcairo_t); overload;
    procedure BeginPaint(ACanvas: TCanvas); override;
    procedure BeginPaint(AColors: PACLPixel32; AWidth, AHeight: Integer); overload;
    procedure BeginPaint(ADib: TACLBaseDib); overload;
    procedure BeginPaint(ASurface: Pcairo_surface_t); overload;
    procedure BeginPaint(DC: HDC; const BoxRect, UpdateRect: TRect); overload; override;
    procedure EndPaint; override;

    // General
    function FriendlyName: string; override;
    function Name: string; override;

    // Clipping
    function Clip(const R: TRect; out Data: TACL2DRenderRawData): Boolean; overload; override;
    function Clip(const R: TACLRegionData; out Data: TACL2DRenderRawData): Boolean; reintroduce; overload;
    procedure ClipRestore(Data: TACL2DRenderRawData); override;
    function IsVisible(const R: TRect): Boolean; override;

    // Ellipse
    procedure DrawEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      Width: Single; Style: TACL2DRenderStrokeStyle); override;
    procedure FillEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor); override;

    // Line
    procedure Line(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure Line(const Points: PPoint; Count: Integer; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;

    // Images
    function CreateImage(Colors: PACLPixel32; Width, Height: Integer;
      AlphaFormat: TAlphaFormat; Usage: TACL2DRenderSourceUsage): TACL2DRenderImage; override;
    procedure DrawImage(Image: TACLDib;
      const TargetRect: TRect; Cache: PACL2DRenderImage = nil); override;
    procedure DrawImage(Image: TACL2DRenderImage;
      const TargetRect, SourceRect: TRect; Alpha: Byte = MaxByte); override;
    procedure DrawImage(Image: TACL2DRenderImage;
      const TargetRect, SourceRect: TRect; Attributes: TACL2DRenderImageAttributes); override;

    // Rectangles
    procedure DrawRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure FillHatchRectangle(const R: TRect; Color1, Color2: TAlphaColor; Size: Integer); override;
    procedure FillRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor); override;
    procedure FillRectangleByGradient(const ARect: TRect;
      AFrom, ATo: TAlphaColor; AVertical: Boolean); override;
    procedure FillSurface(const ATargetRect, ASourceRect: TRect;
      ASurface: Pcairo_surface_t; AAlpha: Double; ATileMode: Boolean;
      AOperator: cairo_operator_t = CAIRO_OPERATOR_OVER);

    // Text
    procedure MeasureText(const Text: string;
      Font: TFont; var Rect: TRect; WordWrap: Boolean); override;
    procedure DrawText(const Text: string; const R: TRect;
      Color: TAlphaColor; Font: TFont; HorzAlign: TAlignment = taLeftJustify;
      VertAlign: TVerticalAlignment = taVerticalCenter; WordWrap: Boolean = False); override;

    // Paths
    function CreatePath: TACL2DRenderPath; override;
    procedure DrawPath(Path: TACL2DRenderPath; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure FillPath(Path: TACL2DRenderPath; Color: TAlphaColor); override;

    // Polygons
    procedure DrawPolygon(const Points: array of TPoint; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure FillPolygon(const Points: array of TPoint; Color: TAlphaColor); override;

    // World Transform
    procedure ModifyWorldTransform(const XForm: TXForm); override;
    procedure RestoreWorldTransform(State: TACL2DRenderRawData); override;
    procedure SaveWorldTransform(out State: TACL2DRenderRawData); override;
    procedure ScaleWorldTransform(ScaleX, ScaleY: Single); overload; override;
    procedure SetWorldTransform(const XForm: TXForm); override;
    procedure TransformPoints(Points: PPointF; Count: Integer); override;
    procedure TranslateWorldTransform(OffsetX, OffsetY: Single); override;

    //# Options
    procedure SetGeometrySmoothing(AValue: TACLBoolean); override;
    procedure SetImageSmoothing(AValue: TACLBoolean); override;

    //# Properties
    property Handle: Pcairo_t read FHandle;
    property Origin;
    property TargetSurface: Pcairo_surface_t read FTargetSurface; // nullable
  end;

{$ENDREGION}

{$REGION ' Blend Mode '}

  TCairoBlendFunctions = class
  public const
    ModeMap: array[TACLBlendMode] of cairo_operator_t = (
      CAIRO_OPERATOR_OVER,
      CAIRO_OPERATOR_MULTIPLY,
      CAIRO_OPERATOR_SCREEN,
      CAIRO_OPERATOR_OVERLAY,
      CAIRO_OPERATOR_ADD,
      CAIRO_OPERATOR_OVER, // bmSubstract, unsupported
      CAIRO_OPERATOR_DIFFERENCE,
      CAIRO_OPERATOR_OVER, // bmDivide, unsupported
      CAIRO_OPERATOR_LIGHTEN,
      CAIRO_OPERATOR_DARKEN,
      CAIRO_OPERATOR_OVER  // bmGrayscale, unsupported
    );
    Supported = [Low(TACLBlendMode)..High(TACLBlendMode)] - [bmSubstract, bmDivide, bmGrayscale];
  strict private
    class procedure DoBlend(ABackground, AForeground: TACLBaseDib;
      AAlpha: Byte; AOperator: cairo_operator_t); overload;
//    class procedure DoBlend(Canvas: TCanvas; Foreground: TACLBaseDib;
//      const Origin: TPoint; Mode: TACLBlendMode; Alpha: Byte); overload; static;
    // BlendFunctions
    class procedure DoAddition(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoDarken(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoDifference(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoLighten(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoMultiply(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoOverlay(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoScreen(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
  public
    class procedure Register;
  end;

{$ENDREGION}

var
  CairoPainter: TACLCairoRender;

(*
  Флаги, поддерживаемые имплементацей на чистом cairo:
    DT_LEFT, DT_CENTER, DT_RIGHT, DT_CALCRECT, DT_TOP, DT_VCENTER, DT_BOTTOM,
    DT_SINGLELINE, DT_HIDEPREFIX, DT_NOPREFIX, DT_NOCLIP, DT_EDITCONTROL,
    DT_WORDBREAK, DT_END_ELLIPSIS
*)
procedure CairoDrawText(ACanvas: TCanvas; const S: string; var R: TRect; AFlags: Cardinal);

// GetTextExtPoint & TextOut
function CairoTextGetLastVisible(ACanvas: TCanvas; const S: string; AMaxWidth: Integer): Integer;
procedure CairoTextOut(ACanvas: TCanvas; X, Y: Integer; AText: PChar; ALength: Integer; AClipRect: PRect = nil);
procedure CairoTextSize(ACanvas: TCanvas; const S: string; AWidth, AHeight: PInteger);

// Context
function cairo_create_context(DC: HDC; out Origin: TPoint;
  out SavedContext: PCairoContext): pcairo_t; overload;
function cairo_create_context(ACanvas: TCanvas;
  out ASurface: Pcairo_surface_t; out AOrigin: TPoint;
  out ASavedContext: PCairoContext): pcairo_t; overload;
procedure cairo_destroy_context(ACairo: pcairo_t;
  ASurface: Pcairo_surface_t; ASavedContext: PCairoContext);

// Surface
function cairo_create_surface(AWidth, AHeight: LongInt): Pcairo_surface_t; overload;
function cairo_create_surface(AData: PACLPixel32; AWidth, AHeight: LongInt): Pcairo_surface_t; overload;

// Utilities
function cairo_create_region_ex(ARects: PRectArray; ACount: Integer): Pcairo_region_t;
procedure cairo_set_source_color(ACairo: pcairo_t; const AColor: TAlphaColor); overload;
procedure cairo_set_source_color(ACairo: pcairo_t; const AColor: TACLPixel32); overload;
procedure cairo_set_source_color(ACairo: pcairo_t; const AColor: TCairoColor); overload;

procedure cairo_fill_surface(ACairo: pcairo_t; ASurface: Pcairo_surface_t;
  const ATargetRect, ASourceRect: TRect; const AOrigin: TPoint;
  AAlpha: Double; ATileMode: Boolean;
  AOperator: cairo_operator_t = CAIRO_OPERATOR_OVER;
  AFilter: cairo_filter_t = CAIRO_FILTER_NEAREST);
procedure cairo_reset_rect(ACairo: pcairo_t; const R: TRect);

procedure cairo_lock;
procedure cairo_unlock;
implementation

uses
  ACL.Graphics.FontCache;

{$REGION ' DrawText '}
const
  CairoTextStyleLines = [fsUnderline, fsStrikeOut];
  GLYPH_MASK_FONTINDEX  = $FF000000;
  GLYPH_MASK_GLYPHINDEX = $00FFFFFF;

type
  TTextBlock = class(TACLTextLayoutBlockText);

  PCairoTextClusterArray = ^TCairoTextClusterArray;
  TCairoTextClusterArray = array[0..0] of cairo_text_cluster_t;

  { TCairoTextLayoutMetrics }

  PCairoTextLayoutMetrics = ^TCairoTextLayoutMetrics;
  TCairoTextLayoutMetrics = packed record
  public
    Capacity: Integer;
    Count: Integer;
    HasSubstitutions: Boolean;
    Glyphs: TCairoGlyphArray; // last!
    class function Allocate(ACount: Integer): PCairoTextLayoutMetrics; static;
    procedure Calculate(ACairo: Pcairo_t; AText: PChar; ATextLength: Integer);
    function MeasureWidth(ACairo: Pcairo_t): Double;
  end;

  { TCairoTextMapping }

  TCairoTextMapping = record
  public
    TextOffsets: array of Integer;
    TextReference: PAnsiChar;
    procedure Free;
    // кластеры будут прибиты автоматически
    procedure Init(AText: PAnsiChar; AGlyphCount: Integer;
      AClusters: Pcairo_text_cluster_t; AClusterCount: Integer);
    function TextAt(AGlyphIndex: Integer): PAnsiChar;
  end;

  { TCairoTextGlyphs }

  TCairoTextGlyphs = record
  public
    GlyphCount: Integer;
    Glyphs: PCairoGlyphArray;
    HasSubstitutions: Boolean;
    Mapping: TCairoTextMapping;
    procedure Free;
    function Init(ACairo: Pcairo_t; AText: PChar; ATextLength: Integer): Boolean;
    function MeasureWidth(ACairo: Pcairo_t): Double;
  end;

  { TCairoTextLine }

  PCairoTextLine = ^TCairoTextLine;
  TCairoTextLine = record
  public
    Glyphs: PCairoGlyphArray;
    GlyphCount: Integer;
    Width: Double;
    NextLine: PCairoTextLine;
    procedure Align(ARightBound: Integer; AAlignment: THorzRectAlign);
    procedure CalcMetrics(ACairo: Pcairo_t);
    function GetCount: Integer;
    function GetMaxWidth: Double;
    procedure Init(AGlyphs: PCairoGlyphArray; AIndex, ACount: Integer);
    function Push(AGlyphs: PCairoGlyphArray; AIndex, ACount: Integer): PCairoTextLine;
    procedure Free;
  end;

  { TCairoHelper }

  TCairoHelper = class
  strict private
    class var FMeasurer: Pcairo_t;
    class var FMeasurerFont: TFont;
    class var FMeasurerSurface: Pcairo_surface_t;
    class var FDefaultFontName: TFontDataName;
    class var FDefaultFontSize: Integer;
    class var FUsedFonts: TStringList;
    class var FUtf8Buffer: PAnsiChar;
    class var FUtf8BufferSize: Integer;
    class procedure InitDefaultFont;
  protected
    // Не должно вызываться вне cairo_lock/unlock
    class procedure SelectFont(ACairo: Pcairo_t; const AFontName: string); overload;
    class procedure SelectFont(ACairo: Pcairo_t; const AFontId: LongWord); overload;
    class function UseFont(const AFontName: string): Integer;
  public
    class destructor Destroy;
    class function DefaultFontName: TFontDataName;
    class function DefaultFontSize: Integer;
    class function Measurer(ACanvas: TCanvas): Pcairo_t;
    class function ToUtf8(AText: PAnsiChar; ATextLen: Integer; out Utf8Len: Integer): PAnsiChar; overload;
    class function ToUtf8(AText: PWideChar; ATextLen: Integer; out Utf8Len: Integer): PAnsiChar; overload;
    class function ResolveUnknownGlyphs(ACairo: Pcairo_t;
      AGlyphs: Pcairo_glyph_t; AGlyphCount: Integer;
      const AMapping: TCairoTextMapping): Boolean;
  end;

{$ENDREGION}

{$REGION ' Render2D '}

  { TACLCairoRenderImage }

  TACLCairoRenderImage = class(TACL2DRenderImage)
  strict private
    FHandle: Pcairo_surface_t;
  public
    constructor Create(ARender: TACL2DRender; AColors: PACLPixel32;
      AWidth, AHeight: Integer; AAlphaFormat: TAlphaFormat;
      AUsage: TACL2DRenderSourceUsage);
    destructor Destroy; override;
    property Handle: Pcairo_surface_t read FHandle;
  end;

  { TACLCairoRenderPath }

  TACLCairoRenderPath = class(TACL2DRenderPath)
  strict private type
  {$REGION ' Items '}
    TItem = class
    public
      X, Y: Single;
      constructor Create(X, Y: Single);
      procedure Write(Handle: Pcairo_t; dX, dY: Single); virtual; abstract;
    end;

    TArc = class(TItem)
    public
      CX, CY, RX, RY, Angle1, Angle2: Single;
      procedure Write(Handle: Pcairo_t; dX, dY: Single); override;
    end;

    TMoveTo = class(TItem)
    public
      procedure Write(Handle: Pcairo_t; dX, dY: Single); override;
    end;

    TLineTo = class(TItem)
    public
      procedure Write(Handle: Pcairo_t; dX, dY: Single); override;
    end;

    TFigure = TACLObjectListOf<TItem>;
  {$ENDREGION}
  strict private
    FFigure: TFigure;
    FFigures: TACLObjectListOf<TFigure>;

    function StartFigureIfNecessary(X, Y: Single): TFigure;
  protected
    procedure Write(Handle: Pcairo_t; dX, dY: Single);
  public
    destructor Destroy; override;
    procedure AddArc(CenterX, CenterY, RadiusX, RadiusY, StartAngle, SweepAngle: Single); override;
    procedure AddLine(X1, Y1, X2, Y2: Single); override;
    procedure FigureClose; override;
    procedure FigureStart; override;
  end;

{$ENDREGION}

{$REGION ' Generic '}
var
  CairoLock: TACLCriticalSection;

procedure cairo_lock;
begin
  CairoLock.Enter;
end;

procedure cairo_unlock;
begin
  CairoLock.Leave;
end;

function cairo_create_context(DC: HDC; out Origin: TPoint; out SavedContext: PCairoContext): pcairo_t;
{$IF DEFINED(MSWINDOWS)}
var
  LSurface: Pcairo_surface_t;
begin
  //#AI, 28.10.2024:
  // Текст рендерится на PaintBox-е обрезанным. Эксперименты говорят,
  // что клиппинг для текста учитывает Origin с противоположным знаком.
  // Посему врубаем нашу реализацию Origin + ClipBox и для Windows.
  New(SavedContext);
  SavedContext^.DC := DC;
  SavedContext^.Index := SaveDC(DC);
  SavedContext^.Ownership := soOwned;
  SetWindowOrgEx(DC, 0, 0, @Origin);

  LSurface := cairo_win32_surface_create(DC);
  Result := cairo_create(LSurface);
  cairo_surface_destroy(LSurface);
{$ELSEIF DEFINED(LCLGtk3)}
var
  LContext: TGtk3DeviceContext absolute DC;
begin
  New(SavedContext);
  SavedContext^.Ownership := soReference;
  Result := Pcairo_t(LContext.pcr);
  cairo_save(Result);
  Origin := NullPoint;
{$ELSEIF DEFINED(LCLGtk2)}
var
  LContext: TGtkDeviceContext absolute DC;
begin
  SavedContext := nil;
  Origin := NullPoint;
  GetWindowOrgEx(DC, Origin);

  Result := gdk_cairo_create(LContext.Drawable);
  if LContext.Offset <> NullPoint then
    cairo_translate(Result, LContext.Offset.X, LContext.Offset.Y);
{$ENDIF}
end;

function cairo_create_context(ACanvas: TCanvas;
  out ASurface: Pcairo_surface_t; out AOrigin: TPoint;
  out ASavedContext: PCairoContext): pcairo_t;
var
  LDib: TACLBaseDib;
{$IFDEF LCLGtk2}
  LDibHandle: HDC;
{$ENDIF}
begin
  ASavedContext := nil;
  ASurface := nil;
  if ACanvas.ClassType = TACLDibCanvas then
  begin
    AOrigin := NullPoint;
    LDib := TACLDibCanvas(ACanvas).Owner;
    if ACanvas.HandleAllocated then
    begin
    {$IFDEF LCLGtk2}
      // Вот без этого трюка Cairo рисует без альфа-канала
      // на некоторых Linux-ах (Alt.Linux 11 Gnome).
      // Похоже из-за того, что gdk_visual_get_system^.depth = 24 бит
      LDibHandle := ACanvas.Handle;
      ASurface := cairo_create_surface(LDib.Colors, LDib.Width, LDib.Height);
      Result := cairo_create(ASurface);
      // Запрос Colors отключил канвас, и если не вернуть DC -
      // следующий за нами вызов не получит выставленных AOrigin и Clipping.
      ACanvas.Handle := LDibHandle;
      GetWindowOrgEx(LDibHandle, AOrigin);
    {$ELSE}
      Result := cairo_create_context(ACanvas.Handle, AOrigin, ASavedContext);
    {$ENDIF}
    end
    else // multi-threading
    begin
      ASurface := cairo_create_surface(LDib.Colors, LDib.Width, LDib.Height);
      Result := cairo_create(ASurface);
    end;
  end
  else
    Result := cairo_create_context(ACanvas.Handle, AOrigin, ASavedContext);
end;

procedure cairo_destroy_context(ACairo: pcairo_t;
  ASurface: Pcairo_surface_t; ASavedContext: PCairoContext);
begin
  if ACairo <> nil then
  begin
    if (ASavedContext <> nil) and (ASavedContext^.Ownership = soReference) then
      cairo_restore(ACairo)
    else
      cairo_destroy(ACairo);
  end;
  if ASurface <> nil then
    cairo_surface_destroy(ASurface);
  if ASavedContext <> nil then
  try
  {$IFDEF MSWINDOWS}
    RestoreDC(ASavedContext^.DC, ASavedContext^.Index);
  {$ENDIF}
  finally
    Dispose(ASavedContext);
  end;
end;

function cairo_create_surface(AWidth, AHeight: LongInt): Pcairo_surface_t;
begin
  Result := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, AWidth, AHeight);
end;

function cairo_create_surface(AData: PACLPixel32; AWidth, AHeight: LongInt): Pcairo_surface_t;
begin
  Result := cairo_image_surface_create_for_data(
    PByte(AData), CAIRO_FORMAT_ARGB32, AWidth, AHeight, AWidth * 4);
end;

function cairo_create_region_ex(ARects: PRectArray; ACount: Integer): Pcairo_region_t;
var
  I: Integer;
begin
  for I := 0 to ACount - 1 do
  begin
    ARects^[I].Bottom := ARects^[I].Height;
    ARects^[I].Right := ARects^[I].Width;
  end;
  Result := cairo_region_create_rectangles(@ARects^[0], ACount);
  for I := 0 to ACount - 1 do
  begin
    ARects^[I].Height := ARects^[I].Bottom;
    ARects^[I].Width := ARects^[I].Right;
  end;
end;

function cairo_get_glyph_index(ACairo: Pcairo_t; AText: PAnsiChar; ATextLen: Integer): LongWord;
var
  LGlyph: cairo_glyph_t;
  LGlyphNum: Integer;
  LGlyphPtr: Pcairo_glyph_t;
begin
  LGlyphNum := 1;
  LGlyphPtr := @LGlyph;
  cairo_scaled_font_text_to_glyphs(cairo_get_scaled_font(ACairo),
    0, 0, AText, ATextLen, @LGlyphPtr, @LGlyphNum, nil, nil, nil);
  Result := LGlyph.index;
end;

procedure cairo_font_metrics(AFont: Pcairo_scaled_font_t; out AMetrics: TCairoFontMetrics);
begin
  cairo_scaled_font_extents(AFont, @AMetrics);
  AMetrics.height := RoundTo(AMetrics.height, -1);
  AMetrics.baseline := AMetrics.height - AMetrics.descent;
  AMetrics.line_thickness := Max(1.0, Round(AMetrics.height / 16.0));
end;

procedure cairo_matrix_init(out matrix: cairo_matrix_t; const form: TXForm);
begin
  matrix.xx := form.eM11;
  matrix.yx := form.eM12;
  matrix.xy := form.eM21;
  matrix.yy := form.eM22;
  matrix.x0 := form.eDx;
  matrix.y0 := form.eDy;
end;

function cairo_set_clipping(ACairo: pcairo_t; DC: HDC): Boolean; overload;
var
  I: Integer;
  LData: TACLRegionData;
  LOrigin: TPoint;
  LRect: TRect;
begin
  Result := False;
  case GetClipBox(DC, {$IFDEF FPC}@{$ENDIF}LRect) of
    NullRegion:
      begin
        cairo_rectangle(ACairo, 0, 0, 0, 0);
        cairo_clip(ACairo);
      end;

    SimpleRegion:
      begin
        LOrigin := NullPoint;
        GetWindowOrgEx(DC, LOrigin);
        LRect.Offset(-LOrigin.X, -LOrigin.Y);
        cairo_rectangle(ACairo, LRect.Left, LRect.Top, LRect.Width, LRect.Height);
        cairo_clip(ACairo);
        Result := True;
      end;

    ComplexRegion:
      begin
        LData := TACLRegionData.CreateFromDC(DC);
        try
          for I := 0 to LData.Count - 1 do
          begin
            with LData.Rects^[I] do
              cairo_rectangle(ACairo, Left, Top, Width, Height);
          end;
          cairo_clip(ACairo);
        finally
          LData.Free;
        end;
        Result := True;
      end;
  end;
end;

function cairo_set_clipping(ACairo: pcairo_t;
  ACanvas: TCanvas; ACanvasContext: PCairoContext): Boolean; overload;
begin
  Result := True;
  if not ACanvas.HandleAllocated and (ACanvas.ClassType = TACLDibCanvas) then
  begin
    with TACLDibCanvas(ACanvas).ClipRect do
      cairo_rectangle(ACairo, Left, Top, Width, Height);
    cairo_clip(ACairo);
  end
  else
    if (ACanvasContext = nil) or (ACanvasContext.Ownership <> soReference) then
      Result := cairo_set_clipping(ACairo, ACanvas.Handle);
end;

procedure cairo_set_dash(ACairo: pcairo_t; const ADashes: array of Double); overload;
begin
  Cairo.cairo_set_dash(ACairo, @ADashes[0], Length(ADashes), 0);
end;

procedure cairo_set_line(ACairo: pcairo_t; AWidth: Single; AStyle: TACL2DRenderStrokeStyle);
begin
  case AStyle of
    ssDashDotDot:
      cairo_set_dash(ACairo, [4 * AWidth, AWidth, AWidth, AWidth, AWidth, AWidth]);
    ssDashDot:
      cairo_set_dash(ACairo, [4 * AWidth, AWidth, AWidth, AWidth]);
    ssDash:
      cairo_set_dash(ACairo, [4 * AWidth, AWidth]);
    ssDot:
      cairo_set_dash(ACairo, [AWidth]);
  else
    Cairo.cairo_set_dash(ACairo, nil, 0, 0);
  end;
  cairo_set_line_width(ACairo, AWidth);
end;

procedure cairo_set_font(ACairo: pcairo_t; AFont: TFont);
var
  LName: AnsiString;
  LSlant: cairo_font_slant_t;
  LWeight: cairo_font_weight_t;
begin
  if fsItalic in AFont.Style then
    LSlant := CAIRO_FONT_SLANT_ITALIC
  else
    LSlant := CAIRO_FONT_SLANT_NORMAL;

  if fsBold in AFont.Style then
    LWeight := CAIRO_FONT_WEIGHT_BOLD
  else
    LWeight := CAIRO_FONT_WEIGHT_NORMAL;

  if AFont.Name = 'default' then
    LName := TCairoHelper.DefaultFontName
  else
    LName := acAString(AFont.Name);

  cairo_select_font_face(ACairo, PAnsiChar(LName), LSlant, LWeight);
  if AFont.Height = 0 then
    cairo_set_font_size(ACairo, TCairoHelper.DefaultFontSize)
  else
    cairo_set_font_size(ACairo, Abs(acResolveFontHeight(AFont, AFont.Height)));
end;

procedure cairo_set_source_color(ACairo: pcairo_t; const AColor: TAlphaColor);
begin
  cairo_set_source_rgba(ACairo, AColor.R / 255, AColor.G / 255, AColor.B / 255, AColor.A / 255);
end;

procedure cairo_set_source_color(ACairo: pcairo_t; const AColor: TACLPixel32);
begin
  cairo_set_source_rgba(ACairo, AColor.R / 255, AColor.G / 255, AColor.B / 255, AColor.A / 255);
end;

procedure cairo_set_source_color(ACairo: pcairo_t; const AColor: TCairoColor);
begin
  cairo_set_source_rgba(ACairo, AColor.R, AColor.G, AColor.B, AColor.A);
end;

procedure cairo_fill_surface(ACairo: pcairo_t; ASurface: Pcairo_surface_t;
  const ATargetRect, ASourceRect: TRect;
  const AOrigin: TPoint; AAlpha: Double; ATileMode: Boolean;
  AOperator: cairo_operator_t; AFilter: cairo_filter_t);
var
  LCairo: Pcairo_t;
  LMatrix: cairo_matrix_t;
  LPrevOperator: cairo_operator_t;
  LSurface: Pcairo_surface_t;
  LSourceW, LSourceH: LongInt;
  LTargetW, LTargetH: Double;
  X, Y: LongInt;
begin
  LSourceH := ASourceRect.Height;
  LSourceW := ASourceRect.Width;
  LTargetH := ATargetRect.Height;
  LTargetW := ATargetRect.Width;
  X := ATargetRect.Left - AOrigin.X;
  Y := ATargetRect.Top - AOrigin.Y;
  if (LSourceW <= 0) or (LSourceH <= 0) or (LTargetH <= 0) or (LTargetW <= 0) then
    Exit;

  LPrevOperator := cairo_get_operator(ACairo);
  cairo_set_operator(ACairo, AOperator);
  if ATileMode then
  begin
    LSurface := cairo_create_surface(LSourceW, LSourceH);

    LCairo := cairo_create(LSurface);
    cairo_set_source_surface(LCairo, ASurface, -ASourceRect.Left, -ASourceRect.Top);
    cairo_rectangle(LCairo, 0, 0, LSourceW, LSourceH);
    cairo_paint_with_alpha(LCairo, AAlpha);
    cairo_destroy(LCairo);

    cairo_set_source_surface(ACairo, LSurface, X, Y);
    cairo_pattern_set_extend(cairo_get_source(ACairo), CAIRO_EXTEND_REPEAT);
    cairo_rectangle(ACairo, X, Y, LTargetW, LTargetH);
    cairo_fill(ACairo);
    cairo_surface_destroy(LSurface);
  end
  else
  begin
    cairo_set_source_surface(ACairo, ASurface, 0, 0);
    cairo_matrix_init_identity(@LMatrix);
    cairo_matrix_translate(@LMatrix, ASourceRect.Left, ASourceRect.Top);
    cairo_matrix_scale(@LMatrix, LSourceW / LTargetW, LSourceH / LTargetH);
    cairo_matrix_translate(@LMatrix, -X, -Y);
    cairo_pattern_set_matrix(cairo_get_source(ACairo), @LMatrix);
    cairo_pattern_set_filter(cairo_get_source(ACairo), AFilter);
    cairo_rectangle(ACairo, X, Y, LTargetW, LTargetH);
    if AAlpha < 1.0 then
    begin
      cairo_save(ACairo);
      cairo_clip(ACairo);
      cairo_paint_with_alpha(ACairo, AAlpha);
      cairo_restore(ACairo);
    end
    else
      cairo_fill(ACairo);
  end;
  cairo_set_operator(ACairo, LPrevOperator);
end;

procedure cairo_reset_rect(ACairo: pcairo_t; const R: TRect);
var
  LPrevOperator: cairo_operator_t;
begin
  LPrevOperator := cairo_get_operator(ACairo);
  cairo_set_operator(ACairo, CAIRO_OPERATOR_SOURCE);
  cairo_set_source_color(ACairo, TCairoColor.From(0, 0, 0, 0));
  cairo_rectangle(ACairo, R.Left, R.Top, R.Right, R.Bottom);
  cairo_fill(ACairo);
  cairo_set_operator(ACairo, LPrevOperator);
end;

{ TCairoColor }

class function TCairoColor.From(A, R, G, B: Byte): TCairoColor;
begin
  Result.R := R / 255;
  Result.G := G / 255;
  Result.B := B / 255;
  Result.A := A / 255;
end;

class function TCairoColor.From(Color: TAlphaColor): TCairoColor;
begin
  Result := From(Color.A, Color.R, Color.G, Color.B);
end;

class function TCairoColor.From(Color: TColor): TCairoColor;
begin
  Color := ColorToRGB(Color);
  Result := From(255, GetRValue(Color), GetGValue(Color), GetBValue(Color));
end;

class function TCairoColor.From(Font: TFont): TCairoColor;
begin
  Result := From(acGetActualColor(Font));
end;
{$ENDREGION}

{$REGION ' DrawText '}

procedure OffsetGlyphs(AGlyphs: PCairoGlyphArray; ACount: Integer; ADeltaX, ADeltaY: Double);
var
  I: Integer;
begin
  for I := 0 to ACount - 1 do
    with AGlyphs^[I] do
    begin
      X := X + ADeltaX;
      Y := Y + ADeltaY;
    end;
end;

function CairoCalculateGlyphWidth(ACairo: Pcairo_t; AGlyphIndex: LongWord): cairo_text_extents_t;
var
  LGlyph: cairo_glyph_t;
  LSwitchFont: Boolean;
begin
  cairo_lock;
  try
    LSwitchFont := AGlyphIndex and GLYPH_MASK_FONTINDEX <> 0;
    if LSwitchFont then
    begin
      cairo_save(ACairo);
      TCairoHelper.SelectFont(ACairo, AGlyphIndex and GLYPH_MASK_FONTINDEX);
      AGlyphIndex := AGlyphIndex and GLYPH_MASK_GLYPHINDEX;
    end;
    LGlyph.x := 0;
    LGlyph.y := 0;
    LGlyph.index := AGlyphIndex;
    cairo_scaled_font_glyph_extents(cairo_get_scaled_font(ACairo), @LGlyph, 1, @Result);
    if LSwitchFont then
      cairo_restore(ACairo);
  finally
    cairo_unlock;
  end;
end;

procedure CairoCalculateTextLayout(ACairo: Pcairo_t;
  const AMapping: TCairoTextMapping; ALines: PCairoTextLine;
  const ARect: TRect; AFlags: Cardinal);
const
  Epsilon = 0.1;
  WordBreaks = AnsiString(#13#10#9' ');
var
  LGlyphCount: Integer;
  LGlyphs: PCairoGlyphArray;

  function CalculateEndEllipse(out AGlyph: LongWord): Double;
  var
    LGlyphs: TCairoTextGlyphs;
  begin
    Result := 0;
    AGlyph := 0;
    if LGlyphs.Init(ACairo, '.', 1) then
    try
      AGlyph := LGlyphs.Glyphs^[0].index;
      Result := CairoCalculateGlyphWidth(ACairo, AGlyph).x_advance;
    finally
      LGlyphs.Free;
    end;
  end;

  procedure ProcessLineBreak(var Index: Integer);
  var
    LSize: Integer;
  begin
    if (AMapping.TextAt(Index)^ = #13) and
       (Index + 1 < LGlyphCount) and (AMapping.TextAt(Index + 1)^ = #10)
    then //#13#10
      LSize := 2
    else
      LSize := 1; // #13 or #10

    Inc(Index, LSize);
    Dec(ALines.Push(LGlyphs, Index, LGlyphCount)^.GlyphCount, LSize);
  end;

var
  I, J: Integer;
  LDeltaY: Double;
  LEndEllipsis: LongWord;
  LFont: Pcairo_scaled_font_t;
  LFontMetrics: TCairoFontMetrics;
  LGlyphWidth: Double;
  LGlyphWidths: TDoubleDynArray;
  LHeight: Double;
  LLineScan: PCairoTextLine;
  LLineStart: Integer;
  LOffsetX, LOffsetY: Double;
  LWidth: Double;
begin
  LGlyphs := ALines^.Glyphs;
  LGlyphCount := ALines^.GlyphCount;
  LFont := cairo_get_scaled_font(ACairo);
  cairo_font_metrics(LFont, LFontMetrics);

  // Считаем лейаут
  if AFlags and DT_SINGLELINE = 0 then
  begin
    LOffsetX := 0;
    LOffsetY := 0;
    LGlyphWidth := 0;

    // В этом режиме мы переносим строки только по CR/LF
    if AFlags and DT_WORDBREAK = 0 then
    begin
      I := 0;
      while I < LGlyphCount do
      begin
        if I + 1 < LGlyphCount then
          LGlyphWidth := LGlyphs^[I + 1].X - LGlyphs^[I].X;
        LGlyphs^[I].X := LOffsetX;
        LGlyphs^[I].Y := LOffsetY;
        LOffsetX := LOffsetX + LGlyphWidth;
        if CharInSet(AMapping.TextAt(I)^, [#13, #10]) then
        begin
          ProcessLineBreak(I);
          LOffsetY := LOffsetY + LFontMetrics.height;
          LOffsetX := 0;
          Continue;
        end;
        Inc(I);
      end;
    end
    else // Wordbreak
    begin
      SetLength(LGlyphWidths{%H-}, LGlyphCount);
      for I := 0 to LGlyphCount - 2 do
        LGlyphWidths[I] := LGlyphs^[I + 1].X - LGlyphs^[I].X;
      LGlyphWidths[LGlyphCount - 1] := CairoCalculateGlyphWidth(
        ACairo, LGlyphs^[LGlyphCount - 1].index).x_advance;

      I := 0;
      LLineStart := 0;
      LWidth := ARect.Width;
      while I < LGlyphCount do
      begin
        // слово не влезает - откатываемся к ближайшему разделителю
        if (LOffsetX + LGlyphWidths[I] > LWidth) and not
          // при условии, что это не перенос строки, он будет обработан отдельно
           (CharInSet(AMapping.TextAt(I)^, [#13, #10])) then
        begin
          J := I;
          while (J > LLineStart) and not acContains(AMapping.TextAt(J)^, WordBreaks) do
            Dec(J);

          // не влезает wordbreak-сепаратор? оставляем его в конце строки
          if (J > LLineStart) and (J = I) then
          begin
            // в режиме редактора переносим wordbreak-сепаратор на следующую
            // строку, при условии, что он не единственный символ в текущей строке
            if (AFlags and DT_EDITCONTROL <> 0) and (J > LLineStart + 1) then
              J := I - 1
            else
            begin
              LGlyphs^[I].X := LOffsetX;
              LGlyphs^[I].Y := LOffsetY;
            end;
          end;

          // Если в текущей строке не нашлось ни одного разделителя -
          // разбиваем посимвольно, как это делает винда для русской локали.
          if (J = LLineStart) {and (SysLocale.FarEast or (AFlags and DT_CHARBREAK <> 0))} then
            J := I - 1;

          // В противном случае - переносим строку.
          if J > LLineStart then
          begin
            LLineStart := J + 1;
            ALines.Push(LGlyphs, LLineStart, LGlyphCount);
            LOffsetY := LOffsetY + LFontMetrics.height;
            LOffsetX := 0;
            I := LLineStart;
            Continue;
          end;
        end;

        LGlyphs^[I].X := LOffsetX;
        LGlyphs^[I].Y := LOffsetY;
        LOffsetX := LOffsetX + LGlyphWidths[I];
        LOffsetX := LOffsetX + LGlyphWidth;
        if CharInSet(AMapping.TextAt(I)^, [#13, #10]) then
        begin
          ProcessLineBreak(I);
          LOffsetY := LOffsetY + LFontMetrics.height;
          LOffsetX := 0;
          LLineStart := I;
          Continue;
        end;
        Inc(I);
      end;
    end;
  end;

  // EndEllipsis
  if AFlags and (DT_CALCRECT or DT_END_ELLIPSIS) = DT_END_ELLIPSIS then
  begin
    // Считаем метрики
    ALines.CalcMetrics(ACairo);
    // Ищем последнюю видимую строку
    LLineScan := ALines;
    LHeight := ARect.Height;
    // В случае DT_EDITCONTROL - нам нужна последняя полностью видимая строка!
    LOffsetY := IfThen(AFlags and DT_EDITCONTROL <> 0, LFontMetrics.height, 0);
    repeat
      LHeight := LHeight - LFontMetrics.height;
      if (LLineScan.NextLine <> nil) and (CompareValue(LOffsetY, LHeight, Epsilon) <= 0) then
        LLineScan := LLineScan.NextLine
      else
        Break;
    until False;
    // Текст-то обрезан у нас?
    if (LLineScan^.NextLine <> nil) or // не все строки влезли
       (LLineScan^.Width > ARect.Width) then
    begin
      // Инициализируем '...'
      LOffsetX := CalculateEndEllipse(LEndEllipsis);
      LWidth := ARect.Width - 3 * LOffsetX;
      // Теперь ищем позицию по x, куда можно вставить '...'
      I := LLineScan^.GlyphCount - 1;
      // Вот тут интересно: если мы не в самом конце строки - стараемся использовать
      // свободные (невидимые) глифы со следующий строки. Точки по ширине меньше букв,
      // и так многоточие будет ближе к правой границе
      if LLineScan^.NextLine <> nil then
        Dec(I, 2 - Min(LLineScan^.NextLine^.GlyphCount, 2))
      else
        Dec(I, 2);

      while I >= 0 do
      begin
        if (LLineScan^.Glyphs^[I].X <= LWidth) or (I = 0) then
        begin
          // Подменяем имеющиеся глифы на глиф точки
          LLineScan^.Glyphs^[I + 0].index := LEndEllipsis;
          LLineScan^.Glyphs^[I + 1].index := LEndEllipsis;
          LLineScan^.Glyphs^[I + 1].x := LLineScan^.Glyphs^[I].x + LOffsetX;
          LLineScan^.Glyphs^[I + 1].y := LLineScan^.Glyphs^[I].y;
          LLineScan^.Glyphs^[I + 2].index := LEndEllipsis;
          LLineScan^.Glyphs^[I + 2].x := LLineScan^.Glyphs^[I].x + LOffsetX * 2;
          LLineScan^.Glyphs^[I + 2].y := LLineScan^.Glyphs^[I].y;
          LLineScan^.GlyphCount := I + 3;
          // Усекаем лейаут по текущей строке (последующие строки будут освобождены)
          LLineScan^.Free;
          // Мы уже учли DT_EDITCONTROL - нет смысла делать работу еще раз
          AFlags := AFlags and not DT_EDITCONTROL;
          Break;
        end;
        Dec(I);
      end;
    end;
  end;

  // Считаем метрики
  ALines.CalcMetrics(ACairo);

  // Позиционирование
  if AFlags and DT_CALCRECT = 0 then
  begin
    // DT_EDITCONTROL - скрываем частично видимые строки
    if AFlags and DT_EDITCONTROL <> 0 then
    begin
      LHeight := 0;
      LLineScan := ALines;
      while LLineScan <> nil do
      begin
        LOffsetY := LHeight + LFontMetrics.height;
        if CompareValue(LOffsetY, ARect.Height, Epsilon) <= 0 then
        begin
          LHeight := LOffsetY;
          LLineScan := LLineScan.NextLine;
        end
        else
          Break;
      end;
      // Усекаем лейаут по последней видимой строке (последующие строки будут освобождены)
      // Себя оставляем, ведь мы можем быть строкой-инициализатором
      if LLineScan <> nil then
      begin
        if LLineScan <> ALines then // Windows никогда не скрывает первую строку
          LLineScan^.GlyphCount := 0;
        LLineScan^.Free;
      end;
    end
    else
      LHeight := ALines.GetCount * LFontMetrics.height;

    // Выравнивание по горизонтали
    if AFlags and DT_CENTER <> 0 then
      ALines.Align(ARect.Width, THorzRectAlign.Center)
    else if AFlags and DT_RIGHT <> 0 then
      ALines.Align(ARect.Width, THorzRectAlign.Right);

    // Выравнивание по вертикали
    if AFlags and DT_VCENTER <> 0 then
      LDeltaY := (ARect.Top + ARect.Bottom - LHeight) / 2
    else if AFlags and DT_BOTTOM <> 0 then
      LDeltaY := ARect.Bottom - LHeight
    else
      LDeltaY := ARect.Top;

    OffsetGlyphs(LGlyphs, LGlyphCount, ARect.Left, LDeltaY + LFontMetrics.baseline);
  end;
end;

procedure CairoDrawGlyphs(ACairo: Pcairo_t;
  AGlyphs: Pcairo_glyph_t; AGlyphCount: Integer; AHasSubstitutions: Boolean);

  // Тут предполагается, что у всего массива выставлен один и тот же шрифт
  procedure ShowGlyphs(AGlyphs: Pcairo_glyph_t; AGlyphCount: Integer);
  var
    I: Integer;
    LFont: LongWord;
    LGlyph: cairo_glyph_t;
  begin
    if AGlyphCount = 0 then Exit;

    LFont := AGlyphs^.index and GLYPH_MASK_FONTINDEX;
    if LFont = 0 then
    begin
      cairo_show_glyphs(ACairo, AGlyphs, AGlyphCount);
      Exit;
    end;

    cairo_save(ACairo);
    TCairoHelper.SelectFont(ACairo, LFont);
    // Вот такой код работает быстрее, чем выводить глифы посимвольно
    if AGlyphCount > 1 then
    begin
      // Выставляем правильные glyph-индексы
      for I := 0 to AGlyphCount - 1 do
        AGlyphs[I].index := AGlyphs[I].index and GLYPH_MASK_GLYPHINDEX;
      // Выводим
      cairo_show_glyphs(ACairo, AGlyphs, AGlyphCount);
      // Восстанавливаем фейковые glyph-индексы
      for I := 0 to AGlyphCount - 1 do
        AGlyphs[I].index := AGlyphs[I].index or LFont;
    end
    else
    begin
      LGlyph := AGlyphs^;
      LGlyph.index := LGlyph.index and GLYPH_MASK_GLYPHINDEX;
      cairo_show_glyphs(ACairo, @LGlyph, 1);
    end;
    cairo_restore(ACairo);
  end;

var
  LCurrGlyph: Pcairo_glyph_t;
  LPrevGlyph: Pcairo_glyph_t;
  LFontIndex: LongWord;
begin
  if AHasSubstitutions then
  begin
    cairo_lock;
    try
      LFontIndex := 0;
      LCurrGlyph := AGlyphs;
      LPrevGlyph := AGlyphs;
      while AGlyphCount > 0 do
      begin
        if (LCurrGlyph^.index and GLYPH_MASK_FONTINDEX) <> LFontIndex then
        begin
          ShowGlyphs(LPrevGlyph, LCurrGlyph - LPrevGlyph);
          LFontIndex := LCurrGlyph^.index and GLYPH_MASK_FONTINDEX;
          LPrevGlyph := LCurrGlyph;
        end;
        Dec(AGlyphCount);
        Inc(LCurrGlyph);
      end;
      ShowGlyphs(LPrevGlyph, LCurrGlyph - LPrevGlyph);
    finally
      cairo_unlock;
    end;
  end
  else
    cairo_show_glyphs(ACairo, AGlyphs, AGlyphCount);
end;

procedure CairoDrawTextStyleLines(ACairo: Pcairo_t; AFontStyle: TFontStyles;
  X, Y, AWidth: Double; const AMetrics: TCairoFontMetrics); overload;
begin
  if CairoTextStyleLines * AFontStyle <> [] then
  begin
    if fsUnderline in AFontStyle then
      cairo_rectangle(ACairo, X, Y + AMetrics.baseline + AMetrics.line_thickness, AWidth, AMetrics.line_thickness);
    if fsStrikeOut in AFontStyle then
      cairo_rectangle(ACairo, X, Y + AMetrics.height / 2, AWidth, AMetrics.line_thickness);
    cairo_fill(ACairo);
  end;
end;

procedure CairoDrawTextLines(ACairo: Pcairo_t; ALines: PCairoTextLine;
  AFontStyle: TFontStyles; const AFontMetrics: TCairoFontMetrics;
  AHasSubstitutions: Boolean);
begin
  while ALines <> nil do
  begin
    if ALines^.GlyphCount > 0 then
    begin
      CairoDrawGlyphs(ACairo,
        @ALines^.Glyphs^[0], ALines^.GlyphCount, AHasSubstitutions);
      CairoDrawTextStyleLines(ACairo, AFontStyle,
        ALines^.Glyphs^[0].X, ALines^.Glyphs^[0].Y - AFontMetrics.baseline,
        ALines^.Width, AFontMetrics);
    end;
    ALines := ALines^.NextLine;
  end;
end;

procedure CairoDrawTextCore(ACanvas: TCanvas;
  const S: string; var R: TRect; AFlags: Cardinal);
var
  LCairo: Pcairo_t;
  LContext: PCairoContext;
  LFont: Pcairo_scaled_font_t;
  LFontMetrics: TCairoFontMetrics;
  LGlyphs: TCairoTextGlyphs;
  LLines: TCairoTextLine;
  LOrigin: TPoint;
  LRect: TRect;
  LSurface: Pcairo_surface_t;
begin
  cairo_lock;
  try
    LCairo := cairo_create_context(ACanvas, LSurface, LOrigin, LContext);
    try
      cairo_set_font(LCairo, ACanvas.Font);
      LFont := cairo_get_scaled_font(LCairo);
      if LGlyphs.Init(LCairo, PChar(S), Length(S)) then
      try
        cairo_font_metrics(LFont, LFontMetrics);
        if AFlags and DT_CALCRECT <> 0 then
        begin
          LLines.Init(LGlyphs.Glyphs, 0, LGlyphs.GlyphCount);
          try
            CairoCalculateTextLayout(LCairo, LGlyphs.Mapping, @LLines, R, AFlags);
            R.Height := Ceil(LLines.GetCount * LFontMetrics.height);
            R.Width := Ceil(LLines.GetMaxWidth);
          finally
            LLines.Free;
          end;
        end
        else
          if cairo_set_clipping(LCairo, ACanvas, LContext) then
          begin
            LRect := R;
            LRect.Offset(-LOrigin.X, -LOrigin.Y);
            LLines.Init(LGlyphs.Glyphs, 0, LGlyphs.GlyphCount);
            try
              CairoCalculateTextLayout(LCairo, LGlyphs.Mapping, @LLines, LRect, AFlags);
              cairo_set_source_color(LCairo, TCairoColor.From(ACanvas.Font));
              if AFlags and DT_NOCLIP = 0 then
              begin
                cairo_rectangle(LCairo, LRect.Left, LRect.Top, LRect.Width, LRect.Height);
                cairo_clip(LCairo);
              end;
              CairoDrawTextLines(LCairo, @LLines,
                ACanvas.Font.Style, LFontMetrics, LGlyphs.HasSubstitutions);
            finally
              LLines.Free;
            end;
          end;
      finally
        LGlyphs.Free;
      end;
    finally
      cairo_destroy_context(LCairo, LSurface, LContext);
    end;
  finally
    cairo_unlock;
  end;
end;

procedure CairoDrawText(ACanvas: TCanvas; const S: string; var R: TRect; AFlags: Cardinal);
var
  LText: string;
begin
  if S = '' then
  begin
    if AFlags and DT_CALCRECT <> 0 then
    begin
      CairoTextSize(ACanvas, S, @R.Right, @R.Bottom);
      Inc(R.Bottom, R.Top);
      Inc(R.Right, R.Left);
    end;
    Exit;
  end;

  LText := S;
  if AFlags and DT_NOPREFIX = 0 then
  begin
    if AFlags and DT_HIDEPREFIX <> 0 then
      acExpandPrefixes(LText, AFlags, True)
    else
      if LText.Contains('&') then // Может просто DT_NOPREFIX забыли?
      begin
        acAdvDrawText(ACanvas, S, R, AFlags, 0);
        Exit;
      end;
  end;

  CairoDrawTextCore(ACanvas, LText, R, AFlags);
end;

function CairoTextGetLastVisible(ACanvas: TCanvas; const S: string; AMaxWidth: Integer): Integer;
var
  LCairo: pcairo_t;
  LGlyphs: TCairoTextGlyphs;
  LWidth: Double;
begin
  cairo_lock;
  try
    Result := 0;
    LCairo := TCairoHelper.Measurer(ACanvas);
    if LGlyphs.Init(LCairo, PChar(S), Length(S)) then
    try
      Result := LGlyphs.GlyphCount - 1;
      LWidth := LGlyphs.MeasureWidth(LCairo);
      while (Result > 0) and (LWidth > AMaxWidth) do
      begin
        LWidth := LGlyphs.Glyphs^[Result].x;
        Dec(Result);
      end;
      Result := LGlyphs.Mapping.TextOffsets[Result];
    finally
      LGlyphs.Free;
    end;
  finally
    cairo_unlock;
  end;
end;

procedure CairoTextOut(ACanvas: TCanvas; X, Y: Integer;
  AText: PChar; ALength: Integer; AClipRect: PRect = nil);
var
  LCairo: pcairo_t;
  LContext: PCairoContext;
  LGlyphs: TCairoTextGlyphs;
  LMetrics: TCairoFontMetrics;
  LOrigin: TPoint;
  LSurface: Pcairo_surface_t;
begin
  cairo_lock;
  try
    LCairo := cairo_create_context(ACanvas, LSurface, LOrigin, LContext);
    try
      if cairo_set_clipping(LCairo, ACanvas, LContext) then
      begin
        if AClipRect <> nil then
        begin
          cairo_rectangle(LCairo, AClipRect.Left - LOrigin.X,
            AClipRect.Top - LOrigin.Y, AClipRect.Width, AClipRect.Height);
          cairo_clip(LCairo);
        end;

        Dec(X, LOrigin.X);
        Dec(Y, LOrigin.Y);

        cairo_set_font(LCairo, ACanvas.Font);
        cairo_set_source_color(LCairo, TCairoColor.From(ACanvas.Font));

        if LGlyphs.Init(LCairo, AText, ALength) then
        try
          cairo_font_metrics(cairo_get_scaled_font(LCairo), LMetrics);
          OffsetGlyphs(LGlyphs.Glyphs, LGlyphs.GlyphCount, X, Y + LMetrics.baseline);
          CairoDrawGlyphs(LCairo, @LGlyphs.Glyphs^[0], LGlyphs.GlyphCount, LGlyphs.HasSubstitutions);
          if CairoTextStyleLines * ACanvas.Font.Style <> [] then
            CairoDrawTextStyleLines(LCairo, ACanvas.Font.Style, X, Y, LGlyphs.MeasureWidth(LCairo), LMetrics);
        finally
          LGlyphs.Free;
        end;
      end;
    finally
      cairo_destroy_context(LCairo, LSurface, LContext);
    end;
  finally
    cairo_unlock;
  end;
end;

procedure CairoTextSize(ACanvas: TCanvas; const S: string; AWidth, AHeight: PInteger);
var
  LCairo: pcairo_t;
  LFontExtents: cairo_font_extents_t;
  LGlyphs: TCairoTextGlyphs;
begin
  cairo_lock;
  try
    LCairo := TCairoHelper.Measurer(ACanvas);
    if AHeight <> nil then
    begin
      cairo_font_extents(LCairo, @LFontExtents);
      AHeight^ := Round(LFontExtents.height);
    end;
    if AWidth <> nil then
    begin
      AWidth^ := 0;
      if LGlyphs.Init(LCairo, PChar(S), Length(S)) then
      try
        AWidth^ := Round(LGlyphs.MeasureWidth(LCairo));
      finally
        LGlyphs.Free;
      end;
    end;
  finally
    cairo_unlock;
  end;
end;

{ TCairoHelper }

class destructor TCairoHelper.Destroy;
begin
  if FMeasurer <> nil then
    cairo_destroy(FMeasurer);
  if FMeasurerSurface <> nil then
    cairo_surface_destroy(FMeasurerSurface);
  FreeAndNil(FMeasurerFont);
  FreeAndNil(FUsedFonts);
  FreeMem(FUtf8Buffer);
end;

class function TCairoHelper.DefaultFontName: TFontDataName;
begin
  if FDefaultFontName = '' then
    InitDefaultFont;
  Result := FDefaultFontName;
end;

class function TCairoHelper.DefaultFontSize: Integer;
begin
  if FDefaultFontSize = 0 then
    InitDefaultFont;
  Result := FDefaultFontSize;
end;

class procedure TCairoHelper.InitDefaultFont;
var
  LFont: TLogFont;
begin
  cairo_lock;
  try
    GetObject(GetStockObject(DEFAULT_GUI_FONT), SizeOf(TLogFont), @LFont);
    FDefaultFontName := TFontDataName(string(LFont.lfFaceName));
    FDefaultFontSize := LFont.lfHeight;
    if FDefaultFontName = '' then
    {$IF DEFINED(LCLGtk3)}
      FDefaultFontName := GTK3WidgetSet.DefaultAppFontName;
    {$ELSEIF DEFINED(LCLGtk2)}
      FDefaultFontName := GetDefaultFontName;
    {$ELSE}
      FDefaultFontName := DefFontData.Name;
    {$ENDIF}
    if FDefaultFontSize = 0 then
      FDefaultFontSize := DefFontData.Height;
    if FDefaultFontSize = 0 then
      FDefaultFontSize := -11;
  finally
    cairo_unlock;
  end;
end;

class function TCairoHelper.Measurer(ACanvas: TCanvas): Pcairo_t;
begin
  CheckIsMainThread;
  if FMeasurerFont = nil then
  begin
    FMeasurerFont := TFont.Create;
    FMeasurerFont.Assign(ACanvas.Font);
    FMeasurerFont.Height := ACanvas.Font.Height; // PPI
    FMeasurerSurface := cairo_create_surface(1, 1);
    FMeasurer := cairo_create(FMeasurerSurface);
    cairo_set_font(FMeasurer, FMeasurerFont);
  end
  else
    if FMeasurerFont.Handle <> ACanvas.Font.Handle then
    //if not ACanvas.Font.IsEqual(FMeasurerFont) then
    begin
      FMeasurerFont.Assign(ACanvas.Font);
      FMeasurerFont.Height := ACanvas.Font.Height; // PPI
      cairo_set_font(FMeasurer, FMeasurerFont);
    end;

  Result := FMeasurer;
end;

class function TCairoHelper.ResolveUnknownGlyphs(
  ACairo: Pcairo_t; AGlyphs: Pcairo_glyph_t; AGlyphCount: Integer;
  const AMapping: TCairoTextMapping): Boolean;

  function GetCharCode(AChar: PAnsiChar; ACharLen: Integer): LongWord;
  begin
    Result := 0;
    if ACharLen > 4 then
      Exit;
    while ACharLen > 0 do
    begin
      Result := (Result shl 8) or Ord(AChar^);
      Dec(ACharLen);
      Inc(AChar);
    end;
  end;

  function HasUnknownGlyphs: Boolean;
  var
    I: Integer;
  begin
    for I := 0 to AGlyphCount - 1 do
    begin
      if AGlyphs[I].index = 0 then
        Exit(True);
    end;
    Result := False;
  end;

var
  LChar: PAnsiChar;
  LCharCode: LongWord;
  LCharLen: Integer;
  LDelta: Double;
  LFontId: LongWord;
  LFontName: string;
  LFonts: TACLFontSubstitutions;
  LGlyphIndex: LongWord;
  LMoveCount: Integer;
  I, J: Integer;
begin
  Result := False;
  if HasUnknownGlyphs then
  begin
    cairo_lock;
    cairo_save(ACairo);
    try
      LFontId := 0;
      LFontName := acString(cairo_toy_font_face_get_family(cairo_get_font_face(ACairo)));
      LFonts := TACLFontCache.GetSubstitutions(LFontName);
      for I := 0 to AGlyphCount - 1 do
      begin
        if AGlyphs[I].index <> 0 then
          Continue;

        LChar := AMapping.TextAt(I);
        LCharLen := acUtf8CharLength(LChar);
        LCharCode := GetCharCode(LChar, LCharLen);
        if LCharCode = 0 then
          Continue;

        if LFonts.Find(LCharCode, LGlyphIndex) then
          AGlyphs[I].index := LGlyphIndex
        else
        begin
          // шрифт мог быть переключен на предыдущем символе.
          // посему проверяем, нет ли в нем и такого глифа
          LGlyphIndex := cairo_get_glyph_index(ACairo, LChar, LCharLen);
          if LGlyphIndex = 0 then
            for J := 0 to LFonts.Count - 1 do
            begin
              SelectFont(ACairo, LFonts[J]);
              LGlyphIndex := cairo_get_glyph_index(ACairo, LChar, LCharLen);
              if LGlyphIndex <> 0 then
              begin
                LogEntry(acGeneralLogFileName, 'FontCache',
                  'Substitute(%x: %s -> %s)', [LCharCode, LFontName, LFonts[J]]);
                LFontId := UseFont(LFonts[J]);
                Break;
              end;
            end;

          if LGlyphIndex <> 0 then
          begin
            AGlyphs[I].index :=
              (LFontId and GLYPH_MASK_FONTINDEX) or
              (LGlyphIndex and GLYPH_MASK_GLYPHINDEX);
            LFonts.Push(LCharCode, AGlyphs[I].index);
          end
          else
            LFonts.Push(LCharCode, 0);
        end;

        if LGlyphIndex <> 0 then
        begin
          LMoveCount := AGlyphCount - I - 1;
          if LMoveCount > 0 then
          begin
            LDelta := CairoCalculateGlyphWidth(ACairo, LGlyphIndex).width - (AGlyphs[I + 1].x- AGlyphs[I].x);
            if LDelta <> 0 then
              OffsetGlyphs(@AGlyphs[I + 1], LMoveCount, LDelta, 0);
          end;
          Result := True; // Eсть подстановка!
        end;
      end;
    finally
      cairo_restore(ACairo);
      cairo_unlock;
    end;
  end;
end;

class procedure TCairoHelper.SelectFont(ACairo: Pcairo_t; const AFontName: string);
var
  LFace: Pcairo_font_face_t;
  LFont: Pcairo_scaled_font_t;
begin
  LFont := cairo_get_scaled_font(ACairo);
  LFace := cairo_scaled_font_get_font_face(LFont);
  cairo_select_font_face(ACairo, PAnsiChar(acAString(AFontName)),
    cairo_toy_font_face_get_slant(LFace),
    cairo_toy_font_face_get_weight(LFace));
end;

class procedure TCairoHelper.SelectFont(ACairo: Pcairo_t; const AFontId: LongWord);
var
  LFont: LongWord;
begin
  LFont := AFontId shr 24;
  if (FUsedFonts <> nil) and InRange(LFont, 0, FUsedFonts.Count - 1) then
    SelectFont(ACairo, FUsedFonts.Strings[LFont]);
end;

class function TCairoHelper.ToUtf8(AText: PAnsiChar; ATextLen: Integer; out Utf8Len: Integer): PAnsiChar;
begin
  Result := AText;
  Utf8Len := ATextLen;
end;

class function TCairoHelper.ToUtf8(AText: PWideChar; ATextLen: Integer; out Utf8Len: Integer): PAnsiChar;
begin
  if FUtf8BufferSize < 3 * ATextLen + 1 then
  begin
    FUtf8BufferSize := 3 * ATextLen + 1;
    ReallocMem(FUtf8Buffer, FUtf8BufferSize);
  end;
  Result := FUtf8Buffer;
  Utf8Len := acUnicodeToUtf8(Result, FUtf8BufferSize - 1, AText, ATextLen);
  Result[Utf8Len] := #0;
end;

class function TCairoHelper.UseFont(const AFontName: string): Integer;
begin
  if FUsedFonts = nil then
  begin
    FUsedFonts := TStringList.Create;
    FUsedFonts.Add(acString(DefaultFontName));
  end;
  Result := FUsedFonts.IndexOf(AFontName);
  if Result < 0 then
    Result := FUsedFonts.Add(AFontName);
  Result := Result shl 24;
end;

{ TCairoTextGlyphs }

procedure TCairoTextGlyphs.Free;
begin
  if Glyphs <> nil then
    cairo_glyph_free(@Glyphs^[0]);
  Mapping.Free;
  GlyphCount := 0;
  Glyphs := nil;
end;

function TCairoTextGlyphs.Init(ACairo: Pcairo_t; AText: PChar; ATextLength: Integer): Boolean;
var
  LClusterCount: Integer;
  LClusterFlags: cairo_text_cluster_flags_t;
  LClusters: Pcairo_text_cluster_t;
  LUtf8: PAnsiChar;
  LUtf8Len: Integer;
begin
  Glyphs := nil;
  GlyphCount := 0;
  LClusters := nil;
  LClusterCount := 0;
  LUtf8 := TCairoHelper.ToUtf8(AText, ATextLength, LUtf8Len);
  cairo_scaled_font_text_to_glyphs(cairo_get_scaled_font(ACairo), 0, 0,
    LUtf8, LUtf8Len, @Glyphs, @GlyphCount, @LClusters, @LClusterCount, @LClusterFlags);
  Result := Glyphs <> nil;
  if Result then
  begin
    Mapping.Init(LUtf8, GlyphCount, LClusters, LClusterCount);
  {$IFDEF ACL_CAIRO_FONTS_SUBSTITUTION}
    HasSubstitutions := TCairoHelper.ResolveUnknownGlyphs(ACairo, @Glyphs^[0], GlyphCount, Mapping);
  {$ELSE}
    HasSubstitutions := False;
  {$ENDIF}
  end;
end;

function TCairoTextGlyphs.MeasureWidth(ACairo: Pcairo_t): Double;
var
  LLine: TCairoTextLine;
begin
  LLine.Init(Glyphs, 0, GlyphCount);
  LLine.CalcMetrics(ACairo);
  Result := LLine.Width;
end;

{ TCairoTextLine }

procedure TCairoTextLine.Align(ARightBound: Integer; AAlignment: THorzRectAlign);
var
  LDeltaX: Double;
begin
  if GlyphCount > 0 then
  begin
    if AAlignment = THorzRectAlign.Center then
      LDeltaX := (ARightBound - (Glyphs^[0].x * 2 + Width)) / 2
    else if AAlignment = THorzRectAlign.Right then
      LDeltaX := (ARightBound - (Glyphs^[0].x + Width))
    else
      LDeltaX := -Glyphs^[0].x;

    if LDeltaX <> 0 then
      OffsetGlyphs(Glyphs, GlyphCount, LDeltaX, 0);
  end;
  if NextLine <> nil then
    NextLine^.Align(ARightBound, AAlignment);
end;

procedure TCairoTextLine.CalcMetrics(ACairo: Pcairo_t);
begin
  if GlyphCount > 0 then
  begin
    Width := CairoCalculateGlyphWidth(ACairo,
      Glyphs^[GlyphCount - 1].index).x_advance +
      Glyphs^[GlyphCount - 1].x - Glyphs^[0].x;
  end
  else
    Width := 0;

  if NextLine <> nil then
    NextLine^.CalcMetrics(ACairo);
end;

function TCairoTextLine.GetCount: Integer;
begin
  Result := 1;
  if NextLine <> nil then
    Inc(Result, NextLine^.GetCount);
end;

procedure TCairoTextLine.Free;
begin
  if NextLine <> nil then
  begin
    NextLine^.Free;
    Dispose(NextLine);
    NextLine := nil;
  end;
end;

function TCairoTextLine.GetMaxWidth: Double;
begin
  Result := Width;
  if NextLine <> nil then
    Result := Max(Result, NextLine^.GetMaxWidth);
end;

procedure TCairoTextLine.Init(AGlyphs: PCairoGlyphArray; AIndex, ACount: Integer);
begin
  Glyphs := @AGlyphs[AIndex];
  GlyphCount := ACount - AIndex;
  NextLine := nil;
  Width := -1;
end;

function TCairoTextLine.Push(AGlyphs: PCairoGlyphArray; AIndex, ACount: Integer): PCairoTextLine;
var
  LCurr: PCairoTextLine;
begin
  LCurr := @Self;
  while LCurr^.NextLine <> nil do
    LCurr := LCurr^.NextLine;
  New(LCurr^.NextLine);
  LCurr^.NextLine^.Init(AGlyphs, AIndex, ACount);
  LCurr^.GlyphCount := LCurr^.NextLine^.Glyphs - LCurr^.Glyphs;
  Result := LCurr;
end;

{ TCairoTextLayoutMetrics }

class function TCairoTextLayoutMetrics.Allocate(ACount: Integer): PCairoTextLayoutMetrics;
begin
  Result := AllocMem(SizeOf(TCairoTextLayoutMetrics) + ACount * SizeOf(cairo_glyph_t));
  Result^.Capacity := ACount;
  Result^.Count := 0;
end;

procedure TCairoTextLayoutMetrics.Calculate(
  ACairo: Pcairo_t; AText: PChar; ATextLength: Integer);
var
  LGlyphs: Pcairo_glyph_t;
  LGlyphCount: Integer;
{$IFDEF ACL_CAIRO_FONTS_SUBSTITUTION}
  LClusterCount: Integer;
  LClusterFlags: cairo_text_cluster_flags_t;
  LClusters: Pcairo_text_cluster_t;
  LMapping: TCairoTextMapping;
{$ENDIF}
  LUtf8: PAnsiChar;
  LUtf8Len: Integer;
begin
  if ATextLength > Capacity then
    raise EInvalidArgument.CreateFmt('TCairoTextLayoutMetrics capacity exceeded (%d -> %d)', [ATextLength, Capacity]);

  // используем для глифов память, что мы сами выделили. Дабы избежать реалокации и move
  LGlyphs := @Glyphs[0];
  LGlyphCount := Capacity;
{$IFDEF ACL_CAIRO_FONTS_SUBSTITUTION}
  LClusterCount := 0;
  LClusters := nil;
{$ENDIF}
  LUtf8 := TCairoHelper.ToUtf8(AText, ATextLength, LUtf8Len);
  cairo_scaled_font_text_to_glyphs(cairo_get_scaled_font(ACairo), 0, 0,
    LUtf8, LUtf8Len, @LGlyphs, @LGlyphCount,
  {$IFDEF ACL_CAIRO_FONTS_SUBSTITUTION}
    @LClusters, @LClusterCount, @LClusterFlags
  {$ELSE}
    nil, nil, nil
  {$ENDIF});

  if LGlyphs <> @Glyphs[0] then // хм, что-то пошло не так - cairo перетер наш буфер
    raise EInvalidArgument.CreateFmt('TCairoTextLayoutMetrics glyphs reallocated (%d -> %d)', [LGlyphCount, Capacity]);
  Count := LGlyphCount;

{$IFDEF ACL_CAIRO_FONTS_SUBSTITUTION}
  LMapping.Init(LUtf8, LGlyphCount, LClusters, LClusterCount);
  HasSubstitutions := TCairoHelper.ResolveUnknownGlyphs(ACairo, LGlyphs, Count, LMapping);
{$ELSE}
  HasSubstitutions := False;
{$ENDIF}
end;

function TCairoTextLayoutMetrics.MeasureWidth(ACairo: Pcairo_t): Double;
var
  LLine: TCairoTextLine;
begin
  LLine.Init(@Glyphs, 0, Count);
  LLine.CalcMetrics(ACairo);
  Result := LLine.Width;
end;

{ TCairoTextMapping }

procedure TCairoTextMapping.Free;
begin
  TextReference := nil;
  TextOffsets := nil;
end;

procedure TCairoTextMapping.Init(AText: PAnsiChar; AGlyphCount: Integer;
  AClusters: Pcairo_text_cluster_t; AClusterCount: Integer);
var
  LGlyphIndex: Integer;
  LTextOffset: Integer;
  I, J: Integer;
begin
  try
    LGlyphIndex := 0;
    LTextOffset := 0;
    TextReference := AText;
    SetLength(TextOffsets, AGlyphCount);
    for I := 0 to AClusterCount - 1 do
    begin
      for J := 1 to AClusters[I].num_glyphs do
      begin
        TextOffsets[LGlyphIndex] := LTextOffset;
        Inc(LGlyphIndex);
      end;
      Inc(LTextOffset, AClusters[I].num_bytes);
    end;
  finally
    cairo_text_cluster_free(AClusters);
  end;
end;

function TCairoTextMapping.TextAt(AGlyphIndex: Integer): PAnsiChar;
begin
  Result := TextReference + TextOffsets[AGlyphIndex];
end;

{ TACLTextLayoutCairoRender }

constructor TACLTextLayoutCairoRender.Create(ACanvas: TCanvas);
begin
  cairo_lock;
  inherited Create(ACanvas);
  FHandle := cairo_create_context(Canvas, FSurface, FOrigin, FContext);
  FHandleOwnership := soOwned;
  cairo_set_clipping(FHandle, Canvas, FContext);
end;

constructor TACLTextLayoutCairoRender.CreateEx(ACairo: Pcairo_t);
begin
  cairo_lock;
  inherited Create(MeasureCanvas);
  FHandle := ACairo;
  FHandleOwnership := soReference;
end;

constructor TACLTextLayoutCairoRender.CreateEx(ADib: TACLBaseDib);
begin
  cairo_lock;
  inherited Create(MeasureCanvas);
  FSurface := cairo_create_surface(ADib.Colors, ADib.Width, ADib.Height);
  FHandle := cairo_create(FSurface);
  FHandleOwnership := soOwned;
end;

destructor TACLTextLayoutCairoRender.Destroy;
begin
  if FHandleOwnership = soOwned then
    cairo_destroy_context(FHandle, FSurface, FContext);
  cairo_unlock;
  inherited Destroy;
end;

function TACLTextLayoutCairoRender.CreateCompatibleRender(ADib: TACLDib): TACLTextLayoutRender;
begin
  Result := TACLTextLayoutCairoRender.CreateEx(ADib);
end;

procedure TACLTextLayoutCairoRender.DrawImage(ADib: TACLDib; const R: TRect);
var
  LSurface: Pcairo_surface_t;
begin
  LSurface := cairo_create_surface(ADib.Colors, ADib.Width, ADib.Height);
  if LSurface <> nil then
  try
    cairo_fill_surface(FHandle, LSurface, R, ADib.ClientRect, FOrigin, 1.0, False);
  finally
    cairo_surface_destroy(LSurface);
  end;
end;

procedure TACLTextLayoutCairoRender.DrawText(ABlock: TACLTextLayoutBlockText; X, Y: Integer);
var
  LBlock: TTextBlock absolute ABlock;
  LMetrics: PCairoTextLayoutMetrics;
begin
  LMetrics := PCairoTextLayoutMetrics(LBlock.FMetrics);
  if (LMetrics <> nil) and (LMetrics^.Count > 0) and (ABlock.TextLengthVisible > 0) then
  begin
    Dec(X, FOrigin.X);
    Dec(Y, FOrigin.Y);

    if FFillColorAssigned then
    begin
      cairo_set_source_color(FHandle, FFillColor);
      cairo_rectangle(FHandle, X, Y, LBlock.TextWidth, LBlock.TextHeight);
      cairo_fill(FHandle);
      cairo_set_source_color(FHandle, FFontColor);
    end;

    OffsetGlyphs(@LMetrics^.Glyphs[0], LMetrics^.Count,  X,  Y + FFontMetrics.baseline);
    CairoDrawGlyphs(FHandle, @LMetrics^.Glyphs[0], LMetrics^.Count, LMetrics^.HasSubstitutions);
    OffsetGlyphs(@LMetrics^.Glyphs[0], LMetrics^.Count, -X, -Y - FFontMetrics.baseline);

    if FFontHasLines then
      CairoDrawTextStyleLines(FHandle, Canvas.Font.Style, X, Y, ABlock.TextWidth, FFontMetrics);
  end;
end;

procedure TACLTextLayoutCairoRender.DrawUnderline(const R: TRect);
begin
  if FFontHasLines then
    CairoDrawTextStyleLines(FHandle, Canvas.Font.Style,
      R.Left - FOrigin.X, R.Top - FOrigin.Y, R.Width, FFontMetrics);
end;

procedure TACLTextLayoutCairoRender.FillBackground(const R: TRect);
begin
  if FFillColorAssigned then
  begin
    cairo_set_source_color(FHandle, FFillColor);
    cairo_rectangle(FHandle, R.Left - FOrigin.X, R.Top - FOrigin.Y, R.Width, R.Height);
    cairo_fill(FHandle);
    cairo_set_source_color(FHandle, FFontColor);
  end;
end;

class function TACLTextLayoutCairoRender.GetChar(
  ABlock: TACLTextLayoutBlockText; var AOffset: Integer): PChar;
var
  LBlock: TTextBlock absolute ABlock;
  LChars: Integer;
  LMetrics: PCairoTextLayoutMetrics;
  LNextPos: Single;
  I: Integer;
begin
  Result := LBlock.Text;
  if LBlock.FMetrics <> nil then
  begin
    LMetrics := LBlock.FMetrics;
    LChars := LMetrics^.Count;
    for I := 0 to LMetrics^.Count - 1 do
      if AOffset < LMetrics^.Glyphs[I].X then
      begin
        LChars := I;
        Break;
      end;

    // Если курсор ближе к предыдущему символу, чем к текущему - декрементим позицию
    if LChars > 0 then
    begin
      LNextPos := LBlock.FWidth;
      if LChars < LMetrics^.Count then
        LNextPos := LMetrics^.Glyphs[LChars].X;
      if Abs(LMetrics^.Glyphs[LChars - 1].X - AOffset) < Abs(LNextPos - AOffset) then
        Dec(LChars);
    end;

    if LChars > 0 then
    {$IFDEF UNICODE}
      Inc(Result, LChars);
    {$ELSE}
      Inc(Result, UTF8CodepointToByteIndex(ABlock.Text, ABlock.TextLength, LChars));
    {$ENDIF}
    if LChars < LMetrics^.Count then
      AOffset := Round(LMetrics^.Glyphs[LChars].X)
    else
      AOffset := LBlock.FWidth;
  end;
end;

class function TACLTextLayoutCairoRender.GetCharPos(
  ABlock: TACLTextLayoutBlock; AOffset: Integer): TRect;
var
  LChar: Integer;
{$IFNDEF UNICODE}
  LCharLen: Integer;
  LText: PChar;
{$ENDIF}
  LMetrics: PCairoTextLayoutMetrics;
begin
  Result := ABlock.Bounds;
  if ABlock is TACLTextLayoutBlockText then
  begin
    LMetrics := TTextBlock(ABlock).FMetrics;
    if LMetrics <> nil then
    begin
      LChar := 0;
    {$IFNDEF UNICODE}
      LText := ABlock.PositionInText;
    {$ENDIF}
      while (AOffset > 0) and (LChar < LMetrics^.Count) do
      begin
      {$IFDEF UNICODE}
        Dec(AOffset);
      {$ELSE}
        LCharLen := acUtf8CharLength(LText);
        Dec(AOffset, LCharLen);
        Inc(LText, LCharLen);
      {$ENDIF}
        Inc(LChar);
      end;
      if LChar < LMetrics^.Count then
        Result.Left  := ABlock.Position.X + Round(LMetrics^.Glyphs[LChar].x);
      if LChar < LMetrics^.Count - 1 then
        Result.Right := ABlock.Position.X + Round(LMetrics^.Glyphs[LChar + 1].x);
    end;
  end;
end;

function TACLTextLayoutCairoRender.GetClipBox(out R: TRect): Boolean;
begin
  Result := False;
end;

procedure TACLTextLayoutCairoRender.GetMetrics(out ABaseline, ALineHeight, ASpaceWidth: Integer);
var
  LTextExtents: cairo_text_extents_t;
begin
  cairo_text_extents(FHandle, ' ', @LTextExtents);
  ASpaceWidth := Round(LTextExtents.x_advance);
  ALineHeight := Round(FFontMetrics.height);
  ABaseLine := Round(FFontMetrics.baseline);
  FLineHeight := ALineHeight;
end;

procedure TACLTextLayoutCairoRender.Measure(ABlock: TACLTextLayoutBlockText);
var
  LBlock: TTextBlock absolute ABlock;
  LMetrics: PCairoTextLayoutMetrics;
begin
  if LBlock.FMetrics = nil then
    LBlock.FMetrics := TCairoTextLayoutMetrics.Allocate(LBlock.TextLength);
  LMetrics := PCairoTextLayoutMetrics(LBlock.FMetrics);
  LMetrics.Calculate(FHandle, LBlock.Text, LBlock.TextLength);
  LBlock.FLengthVisible := LBlock.TextLength;
  LBlock.FWidth := Round(LMetrics^.MeasureWidth(FHandle));
  LBlock.FHeight := FLineHeight;
end;

procedure TACLTextLayoutCairoRender.SetFill(AValue: TColor);
begin
  FFillColor := TCairoColor.From(AValue);
  FFillColorAssigned := AValue <> clNone;
end;

procedure TACLTextLayoutCairoRender.SetFont(AFont: TFont);
begin
  Canvas.Font := AFont; // иначе TFont.GetColor не сработает
  cairo_set_font(FHandle, AFont);
  FFontColor := TCairoColor.From(Canvas.Font);
  cairo_set_source_color(FHandle, FFontColor);
  FFont := cairo_get_scaled_font(FHandle);
  cairo_font_metrics(FFont, FFontMetrics);
  FFontHasLines := CairoTextStyleLines * AFont.Style <> [];
  FLineHeight := Round(FFontMetrics.height);
end;

class procedure TACLTextLayoutCairoRender.Shrink(
  ABlock: TACLTextLayoutBlockText; AMaxSize: Integer);
var
  LBlock: TTextBlock absolute ABlock;
  LGlyph: Pcairo_glyph_t;
  LMetrics: PCairoTextLayoutMetrics;
  LWidth: Double;
begin
  LMetrics := PCairoTextLayoutMetrics(LBlock.FMetrics);
  LGlyph := @LMetrics^.Glyphs[LMetrics^.Count - 1];
  LWidth := LBlock.FWidth;
  while LMetrics^.Count > 0 do
  begin
    LWidth := LGlyph^.x;
    Dec(LMetrics^.Count);
    if LWidth <= AMaxSize then Break;
    Dec(LGlyph);
  end;
  LBlock.FWidth := Round(LWidth);
{$IFDEF UNICODE}
  LBlock.FLengthVisible := LMetrics^.Count;
{$ELSE}
  LBlock.FLengthVisible := UTF8CodepointToByteIndex(LBlock.Text, LBlock.TextLength, LMetrics^.Count);
{$ENDIF}
end;
{$ENDREGION}

{$REGION ' Render2D '}

{ TACLCairoRender }

procedure TACLCairoRender.BeginPaint(ACairo: Pcairo_t);
begin
  FLock.Enter;
  try
    CheckRecursivePaint;
    FTargetSurface := nil;
    FHandle := ACairo;
    FHandleOwnership := soReference;
    FImageSmoothStretching := TACLBoolean.Default;
    FOrigin := NullPoint;
  except
    FLock.Leave;
    raise;
  end;
end;

procedure TACLCairoRender.BeginPaint(ACanvas: TCanvas);
begin
  FLock.Enter;
  try
    CheckRecursivePaint;
    FHandleOwnership := soOwned;
    FHandle := cairo_create_context(ACanvas, FTargetSurface, FOrigin, FContext);
    FImageSmoothStretching := TACLBoolean.Default;
    cairo_set_clipping(Handle, ACanvas, FContext);
  except
    FLock.Leave;
    raise;
  end;
end;

procedure TACLCairoRender.BeginPaint(AColors: PACLPixel32; AWidth, AHeight: Integer);
begin
  FLock.Enter;
  try
    CheckRecursivePaint;
    FOrigin := NullPoint;
    FTargetSurface := cairo_create_surface(AColors, AWidth, AHeight);
    FHandleOwnership := soOwned;
    FHandle := cairo_create(FTargetSurface);
    FImageSmoothStretching := TACLBoolean.Default;
  except
    FLock.Leave;
    raise;
  end;
end;

procedure TACLCairoRender.BeginPaint(ADib: TACLBaseDib);
begin
  BeginPaint(ADib.Colors, ADib.Width, ADib.Height);
end;

procedure TACLCairoRender.BeginPaint(ASurface: Pcairo_surface_t);
begin
  FLock.Enter;
  try
    CheckRecursivePaint;
    FTargetSurface := nil;
    FHandleOwnership := soOwned;
    FHandle := cairo_create(ASurface);
    FImageSmoothStretching := TACLBoolean.Default;
    FOrigin := NullPoint;
  except
    FLock.Leave;
    raise;
  end;
end;

procedure TACLCairoRender.BeginPaint(DC: HDC; const BoxRect, UpdateRect: TRect);
begin
  FLock.Enter;
  try
    CheckRecursivePaint;
    FTargetSurface := nil;
    FHandleOwnership := soOwned;
    FHandle := cairo_create_context(DC, FOrigin, FContext);
    FImageSmoothStretching := TACLBoolean.Default;
    cairo_rectangle(FHandle,
      UpdateRect.Left - FOrigin.X,
      UpdateRect.Top - FOrigin.Y,
      UpdateRect.Width, UpdateRect.Height);
    cairo_clip(FHandle);
  except
    FLock.Leave;
    raise;
  end;
end;

procedure TACLCairoRender.EndPaint;
begin
  try
    if FHandleOwnership = soOwned then
      cairo_destroy_context(FHandle, FTargetSurface, FContext);
  finally
    FTargetSurface := nil;
    FContext := nil;
    FHandle := nil;
    FLock.Leave;
  end;
end;

function TACLCairoRender.CreateImage(Colors: PACLPixel32;
  Width, Height: Integer; AlphaFormat: TAlphaFormat;
  Usage: TACL2DRenderSourceUsage): TACL2DRenderImage;
begin
  Result := TACLCairoRenderImage.Create(Self, Colors, Width, Height, AlphaFormat, Usage);
end;

function TACLCairoRender.CreatePath: TACL2DRenderPath;
begin
  Result := TACLCairoRenderPath.Create(Self);
end;

function TACLCairoRender.Clip(const R: TRect; out Data: TACL2DRenderRawData): Boolean;
begin
  Result := IsVisible(R);
  if Result then
  begin
    Data := nil;
    cairo_save(Handle);
    cairo_rectangle(Handle, R.Left - Origin.X, R.Top - Origin.Y, R.Width, R.Height);
    cairo_clip(Handle);
  end;
end;

function TACLCairoRender.Clip(const R: TACLRegionData; out Data: TACL2DRenderRawData): Boolean;
var
  LRect: PRect;
  I: Integer;
begin
  Result := R.Count > 0;
  if Result then
  begin
    Data := nil;
    cairo_save(Handle);
    LRect := @R.Rects^[0];
    for I := 0 to R.Count - 1 do
    begin
      cairo_rectangle(Handle,
        LRect^.Left - Origin.X, LRect^.Top - Origin.Y,
        LRect^.Width, LRect^.Height);
      Inc(LRect);
    end;
    cairo_clip(Handle);
  end;
end;

procedure TACLCairoRender.ClipRestore(Data: TACL2DRenderRawData);
var
  LMatrix: cairo_matrix_t;
begin
  cairo_get_matrix(Handle, @LMatrix);
  cairo_restore(Handle);
  cairo_set_matrix(Handle, @LMatrix);
end;

function TACLCairoRender.IsVisible(const R: TRect): Boolean;
begin
  Result := True;
end;

procedure TACLCairoRender.DrawEllipse(X1, Y1, X2, Y2: Single;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if (X2 > X1) and (Y2 > Y1) and Color.IsValid then
  begin
    PathEllipseArc(X1, Y1, X2, Y2);
    cairo_set_line(Handle, Width, Style);
    cairo_set_source_color(Handle, Color);
    cairo_stroke(Handle);
  end;
end;

procedure TACLCairoRender.FillEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor);
begin
  if (X2 > X1) and (Y2 > Y1) and Color.IsValid then
  begin
    PathEllipseArc(X1, Y1, X2, Y2);
    cairo_set_source_color(Handle, Color);
    cairo_fill(Handle);
  end;
end;

procedure TACLCairoRender.Line(X1, Y1, X2, Y2: Single;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  cairo_move_to(Handle, X1 - Origin.X, Y1 - Origin.Y);
  cairo_line_to(Handle, X2 - Origin.X, Y2 - Origin.Y);
  cairo_set_source_color(Handle, Color);
  cairo_set_line(Handle, Width, Style);
  cairo_stroke(Handle);
end;

procedure TACLCairoRender.Line(const Points: PPoint; Count: Integer;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if (Count > 1) and Color.IsValid and (Width > 0) then
  begin
    PathPolyline(Points, Count, False);
    cairo_set_source_color(Handle, Color);
    cairo_set_line(Handle, Width, Style);
    cairo_stroke(Handle);
  end;
end;

procedure TACLCairoRender.DrawImage(
  Image: TACLDib; const TargetRect: TRect; Cache: PACL2DRenderImage);
begin
  if Cache <> nil then
    inherited
  else
    Image.DrawBlend(Handle, TargetRect, Image.ClientRect);
end;

procedure TACLCairoRender.DrawImage(Image: TACL2DRenderImage;
  const TargetRect, SourceRect: TRect; Alpha: Byte);
begin
  if IsValid(Image) then
    FillSurface(TargetRect, SourceRect, TACLCairoRenderImage(Image).Handle, Alpha / 255, False);
end;

procedure TACLCairoRender.DrawImage(Image: TACL2DRenderImage;
  const TargetRect, SourceRect: TRect; Attributes: TACL2DRenderImageAttributes);

  procedure DoDrawMaskSurface;
  var
    LClipRgn: TACL2DRenderRawData;
    LTemp: TACLCairoRender;
    LTempRect: TRect;
    LTempSurface: Pcairo_surface_t;
  begin
    if (SourceRect.Top = 0) and (SourceRect.Left = 0) and TargetRect.EqualSizes(SourceRect) then
    begin
      if Clip(TargetRect, LClipRgn) then
      try
        cairo_mask_surface(Handle,
          TACLCairoRenderImage(Image).Handle,
          TargetRect.Left - Origin.X, TargetRect.Top - Origin.Y);
      finally
        ClipRestore(LClipRgn)
      end;
    end
    else
    begin
      LTempRect := TargetRect - TargetRect.TopLeft;
      LTempSurface := cairo_create_surface(LTempRect.Right, LTempRect.Bottom);
      try
        LTemp := TACLCairoRender.Create;
        try
          LTemp.BeginPaint(LTempSurface);
          LTemp.FillSurface(LTempRect, SourceRect,
            TACLCairoRenderImage(Image).Handle, 1.0, False);
          LTemp.EndPaint;
        finally
          LTemp.Free;
        end;
        cairo_mask_surface(Handle, LTempSurface,
          TargetRect.Left - Origin.X, TargetRect.Top - Origin.Y);
      finally
        cairo_surface_destroy(LTempSurface);
      end;
    end;
  end;

var
  LColor: TCairoColor;
begin
  if TargetRect.IsEmpty then
    Exit;
  if SourceRect.IsEmpty then
    Exit;
  if not IsValid(Image) then
    Exit;
  if not IsValid(Attributes) then
  begin
    DrawImage(Image, TargetRect, SourceRect);
    Exit;
  end;

  if Attributes.TintColor.IsValid then
  begin
    LColor := TCairoColor.From(Attributes.TintColor);
    LColor.A := LColor.A * Attributes.Alpha / MaxByte;
    cairo_set_source_color(Handle, LColor);
    DoDrawMaskSurface;
  end
  else
    DrawImage(Image, TargetRect, SourceRect, Attributes.Alpha);
end;

procedure TACLCairoRender.DrawRectangle(X1, Y1, X2, Y2: Single;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if (X2 > X1) and (Y2 > Y1) then
  begin
    cairo_rectangle(Handle, X1 - Origin.X, Y1 - Origin.Y, X2 - X1, Y2 - Y1);
    cairo_set_source_color(Handle, Color);
    cairo_set_line(Handle, Width, Style);
    cairo_stroke(Handle);
  end;
end;

procedure TACLCairoRender.FillHatchRectangle(
  const R: TRect; Color1, Color2: TAlphaColor; Size: Integer);
var
  LTemp: Pcairo_t;
  LTempSurface: Pcairo_surface_t;
  X, Y: Double;
begin
  LTempSurface := cairo_create_surface(2 * Size, 2 * Size);
  try
    LTemp := cairo_create(LTempSurface);
    try
      // Color1
      cairo_set_source_color(LTemp, Color1);
      cairo_rectangle(LTemp,    0,    0, Size, Size);
      cairo_rectangle(LTemp, Size, Size, Size, Size);
      cairo_fill(LTemp);
      // Color2
      cairo_set_source_color(LTemp, Color2);
      cairo_rectangle(LTemp,    0, Size, Size, Size);
      cairo_rectangle(LTemp, Size,    0, Size, Size);
      cairo_fill(LTemp);
    finally
      cairo_destroy(LTemp);
    end;

    X := R.Left - Origin.X;
    Y := R.Top - Origin.Y;
    cairo_set_source_surface(Handle, LTempSurface, X, Y);
    cairo_pattern_set_extend(cairo_get_source(Handle), CAIRO_EXTEND_REPEAT);
    cairo_rectangle(Handle, X, Y, R.Width, R.Height);
    cairo_fill(Handle);
  finally
    cairo_surface_destroy(LTempSurface);
  end;
end;

procedure TACLCairoRender.FillRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor);
begin
  if (X2 > X1) and (Y2 > Y1) then
  begin
    cairo_set_source_color(Handle, Color);
    cairo_rectangle(Handle, X1 - Origin.X, Y1 - Origin.Y, X2 - X1, Y2 - Y1);
    cairo_fill(Handle);
  end;
end;

procedure TACLCairoRender.FillRectangleByGradient(
  const ARect: TRect; AFrom, ATo: TAlphaColor; AVertical: Boolean);
var
  LPattern: Pcairo_pattern_t;
begin
  if AVertical then
    LPattern := cairo_pattern_create_linear(0, ARect.Top - Origin.Y, 0, ARect.Bottom - Origin.Y)
  else
    LPattern := cairo_pattern_create_linear(ARect.Left - Origin.X, 0, ARect.Right - Origin.X, 0);

  with TCairoColor.From(AFrom) do
    cairo_pattern_add_color_stop_rgba(LPattern, 0.0, R, G, B, A);
  with TCairoColor.From(ATo) do
    cairo_pattern_add_color_stop_rgba(LPattern, 1.0, R, G, B, A);

  cairo_rectangle(Handle, ARect.Left - Origin.X,
    ARect.Top - Origin.Y, ARect.Width, ARect.Height);
  cairo_set_source(Handle, LPattern);
  cairo_fill(Handle);

  cairo_pattern_destroy(LPattern);
end;

procedure TACLCairoRender.FillSurface(const ATargetRect, ASourceRect: TRect;
  ASurface: Pcairo_surface_t; AAlpha: Double; ATileMode: Boolean;
  AOperator: cairo_operator_t = CAIRO_OPERATOR_OVER);
const
  Map: array[TACLBoolean] of cairo_filter_t = (
    CAIRO_FILTER_NEAREST, // default
    CAIRO_FILTER_NEAREST, // false
    CAIRO_FILTER_BEST     // true
  );
begin
  cairo_fill_surface(Handle, ASurface, ATargetRect, ASourceRect,
    FOrigin, AAlpha, ATileMode, AOperator, Map[FImageSmoothStretching]);
end;

function TACLCairoRender.FriendlyName: string;
begin
  Result := 'Cairo Graphics';
end;

function TACLCairoRender.Name: string;
begin
  Result := 'Cairo';
end;

procedure TACLCairoRender.MeasureText(
  const Text: string; Font: TFont; var Rect: TRect; WordWrap: Boolean);
var
  LFont: Pcairo_scaled_font_t;
  LFontMetrics: TCairoFontMetrics;
  LGlyphs: TCairoTextGlyphs;
  LLines: TCairoTextLine;
  LFlags: Cardinal;
begin
  cairo_lock;
  try
    cairo_set_font(Handle, Font);
    LFont := cairo_get_scaled_font(Handle);
    if LGlyphs.Init(Handle, PChar(Text), Length(Text)) then
    try
      LFlags := DT_CALCRECT;
      if WordWrap then
        LFlags := LFlags or DT_WORDBREAK;

      LLines.Init(LGlyphs.Glyphs, 0, LGlyphs.GlyphCount);
      try
        CairoCalculateTextLayout(FHandle, LGlyphs.Mapping, @LLines, Rect, LFlags);
        cairo_font_metrics(LFont, LFontMetrics);
        Rect.Height := Ceil(LLines.GetCount * LFontMetrics.height);
        Rect.Width := Ceil(LLines.GetMaxWidth);
      finally
        LLines.Free;
      end;
    finally
      LGlyphs.Free;
    end;
  finally
    cairo_unlock;
  end;
end;

procedure TACLCairoRender.DrawText(const Text: string; const R: TRect;
  Color: TAlphaColor; Font: TFont; HorzAlign: TAlignment;
  VertAlign: TVerticalAlignment; WordWrap: Boolean);
var
  LFont: Pcairo_scaled_font_t;
  LFontMetrics: TCairoFontMetrics;
  LGlyphs: TCairoTextGlyphs;
  LLines: TCairoTextLine;
  LFlags: Cardinal;
begin
  if R.IsEmpty or not Color.IsValid or (Text = '') then
    Exit;

  cairo_lock;
  try
    cairo_set_font(Handle, Font);
    LFont := cairo_get_scaled_font(Handle);
    if LGlyphs.Init(Handle, PChar(Text), Length(Text)) then
    try
      LFlags := acTextAlignHorz[HorzAlign] or acTextAlignVert[VertAlign];
      if WordWrap then
        LFlags := LFlags or DT_WORDBREAK;

      LLines.Init(LGlyphs.Glyphs, 0, LGlyphs.GlyphCount);
      try
        CairoCalculateTextLayout(Handle, LGlyphs.Mapping, @LLines, R - Origin, LFlags);
        cairo_font_metrics(LFont, LFontMetrics);
        cairo_set_source_color(Handle, Color);
        CairoDrawTextLines(Handle, @LLines, Font.Style, LFontMetrics, LGlyphs.HasSubstitutions);
      finally
        LLines.Free;
      end;
    finally
      LGlyphs.Free;
    end;
  finally
    cairo_unlock;
  end;
end;

procedure TACLCairoRender.DrawPath(Path: TACL2DRenderPath;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if IsValid(Path) then
  begin
    TACLCairoRenderPath(Path).Write(Handle, -Origin.X, -Origin.Y);
    cairo_set_source_color(Handle, Color);
    cairo_set_line(Handle, Width, Style);
    cairo_stroke(Handle);
  end;
end;

procedure TACLCairoRender.FillPath(Path: TACL2DRenderPath; Color: TAlphaColor);
begin
  if IsValid(Path) then
  begin
    TACLCairoRenderPath(Path).Write(Handle, -Origin.X, -Origin.Y);
    cairo_set_source_color(Handle, Color);
    cairo_fill(Handle);
  end;
end;

procedure TACLCairoRender.DrawPolygon(const Points: array of TPoint;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if (Length(Points) > 1) and Color.IsValid and (Width > 0) then
  begin
    PathPolyline(@Points[0], Length(Points), True);
    cairo_set_source_color(Handle, Color);
    cairo_set_line(Handle, Width, Style);
    cairo_stroke(Handle);
  end;
end;

procedure TACLCairoRender.FillPolygon(const Points: array of TPoint; Color: TAlphaColor);
begin
  if (Length(Points) > 1) and Color.IsValid then
  begin
    PathPolyline(@Points[0], Length(Points), True);
    cairo_set_source_color(Handle, Color);
    cairo_fill(Handle);
  end;
end;

procedure TACLCairoRender.ModifyWorldTransform(const XForm: TXForm);
var
  LMatrix: cairo_matrix_t;
begin
  cairo_matrix_init(LMatrix, XForm);
  cairo_transform(Handle, @LMatrix);
end;

procedure TACLCairoRender.RestoreWorldTransform(State: TACL2DRenderRawData);
var
  LMatrix: pcairo_matrix_t absolute State;
begin
  cairo_set_matrix(Handle, LMatrix);
  Dispose(LMatrix);
end;

procedure TACLCairoRender.SaveWorldTransform(out State: TACL2DRenderRawData);
var
  LMatrix: pcairo_matrix_t absolute State;
begin
  New(LMatrix);
  cairo_get_matrix(Handle, LMatrix);
end;

procedure TACLCairoRender.ScaleWorldTransform(ScaleX, ScaleY: Single);
begin
  cairo_scale(Handle, ScaleX, ScaleY);
end;

procedure TACLCairoRender.SetGeometrySmoothing(AValue: TACLBoolean);
const
  Map: array[TACLBoolean] of cairo_antialias_t = (
    CAIRO_ANTIALIAS_DEFAULT, CAIRO_ANTIALIAS_NONE, CAIRO_ANTIALIAS_SUBPIXEL
  );
begin
  cairo_set_antialias(Handle, Map[AValue]);
end;

procedure TACLCairoRender.SetImageSmoothing(AValue: TACLBoolean);
begin
  FImageSmoothStretching := AValue;
end;

procedure TACLCairoRender.SetWorldTransform(const XForm: TXForm);
var
  LMatrix: cairo_matrix_t;
begin
  cairo_matrix_init(LMatrix, XForm);
  cairo_set_matrix(Handle, @LMatrix);
end;

procedure TACLCairoRender.TranslateWorldTransform(OffsetX, OffsetY: Single);
begin
  cairo_translate(Handle, OffsetX, OffsetY);
end;

procedure TACLCairoRender.TransformPoints(Points: PPointF; Count: Integer);
var
  LMatrix: cairo_matrix_t;
  LPoint: TPointF;
begin
  cairo_get_matrix(Handle, @LMatrix);
  while Count > 0 do
  begin
    LPoint := Points^;
    Points^.X := LPoint.X * LMatrix.xx + LPoint.Y * LMatrix.yx + LMatrix.x0;
    Points^.Y := LPoint.X * LMatrix.xy + LPoint.Y * LMatrix.yy + LMatrix.y0;
    Inc(Points);
    Dec(Count);
  end;
end;

procedure TACLCairoRender.CheckRecursivePaint;
begin
  if Handle <> nil then
    raise EInvalidGraphicOperation.Create(ClassName + ' recursive calls not yet supported');
end;

procedure TACLCairoRender.PathEllipseArc(X1, Y1, X2, Y2: Double);
begin
  if (X2 > X1) and (Y2 > Y1) then
  begin
    cairo_save(Handle);
    try
      cairo_translate(Handle, (X1 + X2) * 0.5 - Origin.X, (Y1 + Y2) * 0.5 - Origin.Y);
      cairo_scale(Handle, (X2 - X1) * 0.5, (Y2 - Y1) * 0.5);
      cairo_move_to(Handle, 1, 0);
      cairo_arc(Handle, 0, 0, 1, 0, 2 * PI);
    finally
      cairo_restore(Handle);
    end;
  end;
end;

procedure TACLCairoRender.PathPolyline(Points: PPoint; Count: Integer; ClosePath: Boolean);
var
  LFirstPoint: PPoint;
begin
  if Count > 1 then
  begin
    LFirstPoint := Points;
    cairo_move_to(Handle, Points^.X - Origin.X, Points^.Y - Origin.X);
    while Count > 1 do
    begin
      Inc(Points);
      Dec(Count);
      cairo_line_to(Handle, Points^.X - Origin.X, Points^.Y - Origin.X);
    end;
    if ClosePath then
      cairo_line_to(Handle, LFirstPoint^.X - Origin.X, LFirstPoint^.Y - Origin.X);
  end;
end;

{ TACLCairoRenderImage }

constructor TACLCairoRenderImage.Create(ARender: TACL2DRender;
  AColors: PACLPixel32; AWidth, AHeight: Integer; AAlphaFormat: TAlphaFormat;
  AUsage: TACL2DRenderSourceUsage);
begin
  inherited Create(ARender);
  if (AUsage = suReference) and (AAlphaFormat <> afPremultiplied) then
    AUsage := suCopy;
  if (AUsage = suCopy) then
    TACLColors.Clone(AColors, AWidth, AHeight);
  if (AAlphaFormat <> afPremultiplied) then
  begin
    if AAlphaFormat = afDefined then
      TACLColors.Premultiply(AColors, AWidth * AHeight);
    if AAlphaFormat = afIgnored then
      TACLColors.MakeOpaque(AColors, AWidth * AHeight);
  end;
  if AUsage <> suReference then
    FOwnedDataPtr := AColors;
  FHandle := cairo_create_surface(AColors, AWidth, AHeight);
  FHeight := AHeight;
  FWidth := AWidth;
end;

destructor TACLCairoRenderImage.Destroy;
begin
  cairo_surface_destroy(FHandle);
  inherited;
end;

{ TACLCairoRenderPath }

destructor TACLCairoRenderPath.Destroy;
begin
  FreeAndNil(FFigures);
  inherited Destroy;
end;

procedure TACLCairoRenderPath.AddArc(
  CenterX, CenterY, RadiusX, RadiusY, StartAngle, SweepAngle: Single);
var
  LItem: TArc;
  LAngle1: Single;
  LAngle2: Single;
  P1, P2: TPointF;
begin
  LAngle1 := DegToRad(StartAngle);
  LAngle2 := DegToRad(StartAngle + SweepAngle);
  acCalcArcSegment(CenterX, CenterY, RadiusX, RadiusY, 2 * PI - LAngle1, 2 * PI - LAngle2, P1, P2);
  LItem := TArc.Create(P2.X, P2.Y);
  LItem.CX := CenterX;
  LItem.CY := CenterY;
  LItem.RX := RadiusX;
  LItem.RY := RadiusY;
  LItem.Angle1 := LAngle1;
  LItem.Angle2 := LAngle2;
  StartFigureIfNecessary(P1.X, P1.Y).Add(LItem);
end;

procedure TACLCairoRenderPath.AddLine(X1, Y1, X2, Y2: Single);
begin
  StartFigureIfNecessary(X1, Y1).Add(TLineTo.Create(X2, Y2));
end;

procedure TACLCairoRenderPath.FigureClose;
var
  LLast, LFirst: TItem;
begin
  if FFigure <> nil then
  begin
    if FFigure.Count > 0 then
    begin
      LLast := FFigure.Last;
      LFirst := FFigure.First;
      if not (SameValue(LLast.X, LFirst.X) and SameValue(LLast.Y, LFirst.Y)) then
        FFigure.Add(TLineTo.Create(LFirst.X, LFirst.Y));
    end;
    FFigure := nil;
  end;
end;

procedure TACLCairoRenderPath.FigureStart;
begin
  FigureClose;
end;

function TACLCairoRenderPath.StartFigureIfNecessary(X, Y: Single): TFigure;
begin
  if FFigure = nil then
  begin
    if FFigures = nil then
      FFigures := TACLObjectListOf<TFigure>.Create(True);
    FFigure := TFigure.Create;
    FFigures.Add(FFigure);
  end;

  if (FFigure.Count = 0) or
    not SameValue(X, FFigure.Last.X) or
    not SameValue(Y, FFigure.Last.Y)
  then
    FFigure.Add(TMoveTo.Create(X, Y));

  Result := FFigure;
end;

procedure TACLCairoRenderPath.Write(Handle: Pcairo_t; dX, dY: Single);
var
  LFigure: TFigure;
  I, J: Integer;
begin
  if FFigures = nil then
    Exit;
  for I := 0 to FFigures.Count - 1 do
  begin
    LFigure := FFigures.List[I];
    for J := 0 to LFigure.Count - 1 do
      LFigure.List[J].Write(Handle, dX, dY);
  end;
end;

{ TACLCairoRenderPath.TArc }

procedure TACLCairoRenderPath.TArc.Write(Handle: Pcairo_t; dX, dY: Single);
begin
  cairo_save(Handle);
  try
    cairo_translate(Handle, CX + dX, CY + dY);
    cairo_scale(Handle, RX, RY);
    if Angle2 > Angle1 then
      cairo_arc(Handle, 0, 0, 1, Angle1, Angle2)
    else
      cairo_arc_negative(Handle, 0, 0, 1, Angle1, Angle2);
  finally
    cairo_restore(Handle);
  end;
end;

{ TACLCairoRenderPath.TItem }

constructor TACLCairoRenderPath.TItem.Create(X, Y: Single);
begin
  Self.X := X;
  Self.Y := Y;
end;

{ TACLCairoRenderPath.TMoveTo }

procedure TACLCairoRenderPath.TMoveTo.Write(Handle: Pcairo_t; dX, dY: Single);
begin
  cairo_move_to(Handle, X + dX, Y + dY);
end;

{ TACLCairoRenderPath.TLineTo }

procedure TACLCairoRenderPath.TLineTo.Write(Handle: Pcairo_t; dX, dY: Single);
begin
  cairo_line_to(Handle, X + dX, Y + dY);
end;
{$ENDREGION}

{$REGION ' Blend Mode '}

{ TCairoBlendFunctions }

class procedure TCairoBlendFunctions.DoAddition(
  ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  DoBlend(ABackground, AForeground, AAlpha, CAIRO_OPERATOR_ADD);
end;

class procedure TCairoBlendFunctions.DoBlend(
  ABackground, AForeground: TACLBaseDib; AAlpha: Byte; AOperator: cairo_operator_t);
var
  LCairo: Pcairo_t;
  LBackground: Pcairo_surface_t;
  LForeground: Pcairo_surface_t;
begin
  LBackground := cairo_create_surface(ABackground.Colors, ABackground.Width, ABackground.Height);
  LForeground := cairo_create_surface(AForeground.Colors, AForeground.Width, AForeground.Height);
  try
    LCairo := cairo_create(LBackground);
    try
      cairo_fill_surface(LCairo, LForeground, ABackground.ClientRect,
        AForeground.ClientRect, NullPoint, AAlpha / 255, False, AOperator);
    finally
      cairo_destroy(LCairo);
    end;
  finally
    cairo_surface_destroy(LBackground);
    cairo_surface_destroy(LForeground);
  end;
end;

//class procedure TCairoBlendFunctions.DoBlend(Canvas: TCanvas;
//  Foreground: TACLDib; const Origin: TPoint; Mode: TACLBlendMode; Alpha: Byte);
//var
//  LCairo: Pcairo_t;
//  LContext: PCairoContext;
//  LForeground: Pcairo_surface_t;
//  LOrigin: TPoint;
//begin
//  if Mode in Supported then
//  begin
//    LForeground := cairo_create_surface(Foreground.Colors, Foreground.Width, Foreground.Height);
//    try
//      LCairo := cairo_create_context(Canvas.Handle, LOrigin, LContext);
//      try
//        cairo_fill_surface(LCairo, LForeground,
//          Foreground.ClientRect, Foreground.ClientRect,
//          LOrigin + Origin, Alpha / 255, False, ModeMap[Mode]);
//      finally
//        cairo_destroy_context(LCairo, LContext);
//      end;
//    finally
//      cairo_surface_destroy(LForeground);
//    end;
//  end
//  else
//    acDrawBlendFunc(Canvas, Foreground, Origin, Mode, Alpha);
//end;

class procedure TCairoBlendFunctions.DoDarken(
  ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  DoBlend(ABackground, AForeground, AAlpha, CAIRO_OPERATOR_DARKEN);
end;

class procedure TCairoBlendFunctions.DoDifference(
  ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  DoBlend(ABackground, AForeground, AAlpha, CAIRO_OPERATOR_DIFFERENCE);
end;

class procedure TCairoBlendFunctions.DoLighten(
  ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  DoBlend(ABackground, AForeground, AAlpha, CAIRO_OPERATOR_LIGHTEN);
end;

class procedure TCairoBlendFunctions.DoMultiply(
  ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  DoBlend(ABackground, AForeground, AAlpha, CAIRO_OPERATOR_MULTIPLY);
end;

class procedure TCairoBlendFunctions.DoOverlay(
  ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  DoBlend(ABackground, AForeground, AAlpha, CAIRO_OPERATOR_OVERLAY);
end;

class procedure TCairoBlendFunctions.DoScreen(
  ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  DoBlend(ABackground, AForeground, AAlpha, CAIRO_OPERATOR_SCREEN);
end;

class procedure TCairoBlendFunctions.Register;
begin
//  BlendModeDraw := DoBlend;
  BlendFunctions[bmAddition] := DoAddition;
  BlendFunctions[bmAddition] := DoAddition;
  BlendFunctions[bmDarken] := DoDarken;
  BlendFunctions[bmDifference] := DoDifference;
  BlendFunctions[bmLighten] := DoLighten;
  BlendFunctions[bmMultiply] := DoMultiply;
  BlendFunctions[bmOverlay] := DoOverlay;
  BlendFunctions[bmScreen] := DoScreen;
end;

{$ENDREGION}

initialization
  CairoLock := TACLCriticalSection.Create(nil, 'CairoLock');
  CairoPainter := TACLCairoRender.Create;

finalization
  FreeAndNil(CairoPainter);
  FreeAndNil(CairoLock);
end.
