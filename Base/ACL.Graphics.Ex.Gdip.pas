﻿{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*         Extended Graphic Library          *}
{*            GDI+ Integration               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.Ex.Gdip;

{$I ACL.Config.inc}

interface

uses
  Winapi.ActiveX,
  Winapi.Windows,
  Winapi.GDIPOBJ,
  Winapi.GDIPAPI,
  // System
  System.Classes,
  System.Contnrs,
  System.SysUtils,
  System.Types,
  System.UiTypes,
  // Vcl
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.FontCache,
  ACL.Graphics.Images,
  ACL.Math,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Stream;

{$REGION 'Aliases'}
const
  pomInvalid     = PixelOffsetModeInvalid;
  pomDefault     = PixelOffsetModeDefault;
  pomHighSpeed   = PixelOffsetModeHighSpeed;
  pomHighQuality = PixelOffsetModeHighQuality;
  pomNone        = PixelOffsetModeNone;
  pomHalf        = PixelOffsetModeHalf;

  smInvalid      = SmoothingModeInvalid;
  smDefault      = SmoothingModeDefault;
  smHighSpeed    = SmoothingModeHighSpeed;
  smHighQuality  = SmoothingModeHighQuality;
  smNone         = SmoothingModeNone;
  smAntiAlias    = SmoothingModeAntiAlias;

  gmBackwardDiagonal = LinearGradientModeBackwardDiagonal;
  gmForwardDiagonal  = LinearGradientModeForwardDiagonal;
  gmHorizontal       = LinearGradientModeHorizontal;
  gmVertical         = LinearGradientModeVertical;
{$ENDREGION}

type

  { EGdipException }

  EGdipException = class(Exception)
  strict private
    FStatus: GpStatus;
  public
    constructor Create(AStatus: GpStatus);
    //
    property Status: GpStatus read FStatus;
  end;

{$REGION 'GDI+ Cache'}

  { TACLGdiplusResourcesCache }

  TACLGdiplusResourcesCache = class
  strict private type
  {$REGION 'Internal Types'}
    TPenKey = record
      Color: TAlphaColor;
      Style: TACL2DRenderStrokeStyle;
      Width: Single;
    end;
  {$ENDREGION}
  strict private
    class var FBrushes: TACLValueCacheManager<TAlphaColor, GpBrush>;
    class var FFonts: TACLValueCacheManager<TACLFontData, GpFont>;
    class var FPens: TACLValueCacheManager<TPenKey, GpPen>;

    class procedure HandlerOnRemoveBrush(Sender: TObject; const ABrush: GpBrush);
    class procedure HandlerOnRemoveFont(Sender: TObject; const AFont: GpFont);
    class procedure HandlerOnRemovePen(Sender: TObject; const APen: GpPen);
  public
    class procedure Flush;
    class function BrushGet(AColor: TAlphaColor): GpBrush;
    class function FontGet(const AFont: TACLFontData): GpFont; overload;
    class function FontGet(const AFont: TFont): GpFont; overload;
    class function PenGet(Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle): GpPen;
  end;

{$ENDREGION}

{$REGION '2D Render'}

  { TACLGdiplusRender }

  TACLGdiplusRender = class(TACL2DRender)
  strict private
    FSavedClipRegion: TStack;
    FSavedWorldTransforms: TStack;

    function GetInterpolationMode: TInterpolationMode;
    function GetPixelOffsetMode: TPixelOffsetMode;
    function GetSmoothingMode: TSmoothingMode;
    procedure SetInterpolationMode(AValue: TInterpolationMode);
    procedure SetPixelOffsetMode(AValue: TPixelOffsetMode);
    procedure SetSmoothingMode(AValue: TSmoothingMode);
  protected
    FGraphics: GpGraphics;
  public
    constructor Create; overload; virtual;
    constructor Create(DC: HDC); overload;
    constructor Create(Graphics: GpGraphics); overload;
    destructor Destroy; override;

    // Clipping
    function IsVisible(const R: TRect): Boolean; override;
    function IntersectClipRect(const R: TRect): Boolean; override;
    procedure RestoreClipRegion; override;
    procedure SaveClipRegion; override;

    // Images
    function CreateImage(Colors: PRGBQuad; Width, Height: Integer;
      AlphaFormat: TAlphaFormat = afDefined): TACL2DRenderImage; override;
    function CreateImage(Image: TACLImage): TACL2DRenderImage; override;
    function CreateImageAttributes: TACL2DRenderImageAttributes; override;
    procedure DrawImage(Image: TACL2DRenderImage; const TargetRect, SourceRect: TRect;
      Attributes: TACL2DRenderImageAttributes = nil); override;

    // Curves
    procedure DrawCurve2(APenColor: TAlphaColor; APoints: array of TPoint;
      ATension: Single; APenStyle: TACL2DRenderStrokeStyle = ssSolid; APenWidth: Single = 1.0);
    procedure DrawClosedCurve2(APenColor: TAlphaColor; const APoints: array of TPoint;
      ATension: Single; APenStyle: TACL2DRenderStrokeStyle = ssSolid; APenWidth: Single = 1.0);
    procedure FillClosedCurve2(AColor: TAlphaColor; const APoints: array of TPoint; ATension: Single);

    // Ellipse
    procedure DrawEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      StrokeWidth: Single = 1; StrokeStyle: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure FillEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor); override;

    // Line
    procedure Line(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure Line(const Points: PPoint; Count: Integer; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;

    // Rectangle
    procedure DrawRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      StrokeWidth: Single = 1; StrokeStyle: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure FillRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor); override;
    procedure FillRectangleByGradient(AColor1, AColor2: TAlphaColor; const R: TRect; AMode: TLinearGradientMode);

    // Text
    procedure DrawText(const Text: string; const R: TRect; Color: TAlphaColor; Font: TFont;
      HorzAlign: TAlignment = taLeftJustify; VertAlgin: TVerticalAlignment = taVerticalCenter;
      WordWrap: Boolean = False); override;

    // Path
    function CreatePath: TACL2DRenderPath; override;
    procedure DrawPath(Path: TACL2DRenderPath; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure FillPath(Path: TACL2DRenderPath; Color: TAlphaColor); override;

    // Polygon
    procedure DrawPolygon(const Points: array of TPoint; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure FillPolygon(const Points: array of TPoint; Color: TAlphaColor); override;

    // World Transform
    procedure ModifyWorldTransform(const XForm: TXForm); override;
    procedure RestoreWorldTransform; override;
    procedure SaveWorldTransform; override;
    procedure ScaleWorldTransform(ScaleX, ScaleY: Single); override;
    procedure TransformPoints(Points: PPointF; Count: Integer); override;
    procedure TranslateWorldTransform(OffsetX, OffsetY: Single); override;

    property NativeHandle: GpGraphics read FGraphics;
    property InterpolationMode: TInterpolationMode read GetInterpolationMode write SetInterpolationMode;
    property PixelOffsetMode: TPixelOffsetMode read GetPixelOffsetMode write SetPixelOffsetMode;
    property SmoothingMode: TSmoothingMode read GetSmoothingMode write SetSmoothingMode;
  end;

{$ENDREGION}

  { TACLGdiplusCanvas }

  TACLGdiplusCanvas = TACLGdiplusRender;

  { TACLGdiplusPaintCanvas }

  TACLGdiplusPaintCanvas = class(TACLGdiplusCanvas)
  strict private
    FSavedHandles: TStack;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure BeginPaint(DC: HDC);
    procedure EndPaint;
  end;

  { TACLGdiplusStream }

  TACLGdiplusStream = class(TStreamAdapter)
  public
    function Stat(out AStatStg: TStatStg; AStatFlag: DWORD): HResult; override; stdcall;
  end;

var
  GpDefaultColorMatrix: TColorMatrix = (
    (1.0, 0.0, 0.0, 0.0, 0.0),
    (0.0, 1.0, 0.0, 0.0, 0.0),
    (0.0, 0.0, 1.0, 0.0, 0.0),
    (0.0, 0.0, 0.0, 1.0, 0.0),
    (0.0, 0.0, 0.0, 0.0, 1.0)
  );
  GpPaintCanvas: TACLGdiplusPaintCanvas;

procedure GdipCheck(AStatus: GpStatus);
function GpCreateBitmap(AWidth, AHeight: Integer; ABits: PByte = nil; APixelFormat: Integer = PixelFormat32bppPARGB): GpImage;
function GpGetCodecByMimeType(const AMimeType: UnicodeString; out ACodecID: TGUID): Boolean;
procedure GpFillRect(DC: HDC; const R: TRect; AColor: TAlphaColor);
procedure GpFocusRect(DC: HDC; const R: TRect; AColor: TAlphaColor);
procedure GpFrameRect(DC: HDC; const R: TRect; AColor: TAlphaColor; AFrameSize: Integer);
procedure GpDrawImage(AGraphics: GpGraphics; AImage: GpImage; AImageAttributes: GpImageAttributes;
  const ADestRect, ASourceRect: TRect; ATileDrawingMode: Boolean); overload;
procedure GpDrawImage(AGraphics: GpGraphics; AImage: GpImage;
  const ADestRect, ASourceRect: TRect; ATileDrawingMode: Boolean; const AAlpha: Byte = $FF); overload;
implementation

uses
  System.Math;

const
  sErrorInvalidGdipOperation = 'Invalid operation in GDI+ (Code: %d)';
  sErrorPaintCanvasAlreadyBusy = 'PaintCanvas is already busy!';

type
  TACLImageAccess = class(TACLImage);

{$REGION '2D Render'}

  { TACLGdiplusRenderImage }

  TACLGdiplusRenderImage = class(TACL2DRenderImage)
  protected
    FHandle: GpImage;
  public
    constructor Create(AOwner: TACL2DRender; AHandle: GpImage);
    destructor Destroy; override;
  end;

  { TACLGdiplusRenderImageAttributes }

  TACLGdiplusRenderImageAttributes = class(TACL2DRenderImageAttributes)
  protected
    FHandle: GpImageAttributes;
  public
    constructor Create(AOwner: TACL2DRender);
    destructor Destroy; override;
    procedure SetColorMatrix(const AColorMatrix: ColorMatrix); override;
  end;

  { TACLGdiplusRenderPath }

  TACLGdiplusRenderPath = class(TACL2DRenderPath)
  protected
    Handle: GpPath;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddArc(const X, Y, Width, Height, StartAngle, SweepAngle: Single); override;
    procedure AddLine(const X1, Y1, X2, Y2: Single); override;
    procedure AddRect(const R: TRectF); override;
    procedure FigureClose; override;
    procedure FigureStart; override;
  end;

{$ENDREGION}

procedure GdipCheck(AStatus: GpStatus);
begin
  if AStatus <> Ok then
    raise EGdipException.Create(AStatus);
end;

//----------------------------------------------------------------------------------------------------------------------
// Internal Routines
//----------------------------------------------------------------------------------------------------------------------

function GpCreateBitmap(AWidth, AHeight: Integer; ABits: PByte = nil; APixelFormat: Integer = PixelFormat32bppPARGB): GpImage;
begin
  if GdipCreateBitmapFromScan0(AWidth, AHeight, AWidth * 4, APixelFormat, ABits, Result) <> Ok then
    Result := nil;
end;

//----------------------------------------------------------------------------------------------------------------------
// Fill Rect
//----------------------------------------------------------------------------------------------------------------------

procedure GpFillRect(DC: HDC; const R: TRect; AColor: TAlphaColor);
begin
  if AColor.IsValid then
  begin
    GpPaintCanvas.BeginPaint(DC);
    try
      GpPaintCanvas.FillRectangle(R, AColor);
    finally
      GpPaintCanvas.EndPaint;
    end;
  end;
end;

procedure GpFrameRect(DC: HDC; const R: TRect; AColor: TAlphaColor; AFrameSize: Integer);
begin
  if AColor <> TAlphaColor.None then
  begin
    GpPaintCanvas.BeginPaint(DC);
    try
      GpPaintCanvas.DrawRectangle(R, AColor, AFrameSize);
    finally
      GpPaintCanvas.EndPaint;
    end;
  end;
end;

procedure GpFocusRect(DC: HDC; const R: TRect; AColor: TAlphaColor);
var
  APrevOrg, AOrg: TPoint;
begin
  if AColor <> TAlphaColor.None then
  begin
    GetWindowOrgEx(DC, AOrg);
    SetBrushOrgEx(DC, AOrg.X, AOrg.Y, @APrevOrg);
    try
      GpPaintCanvas.BeginPaint(DC);
      try
        GpPaintCanvas.DrawRectangle(R, AColor, 1, ssDot);
      finally
        GpPaintCanvas.EndPaint;
      end;
    finally
      SetBrushOrgEx(DC, APrevOrg.X, APrevOrg.Y, nil);
    end;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// DrawImage
//----------------------------------------------------------------------------------------------------------------------

procedure GpDrawImage(AGraphics: GpGraphics; AImage: GpImage; AImageAttributes: GpImageAttributes;
  const ADestRect, ASourceRect: TRect; ATileDrawingMode: Boolean); overload;

  function GpIsRectVisible(AGraphics: GpGraphics; const R: TRect): LongBool;
  begin
    Result := GdipIsVisibleRectI(AGraphics, R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top, Result) = Ok;
  end;

  function CreateTextureBrush(const R: TRect; out ATexture: GpTexture): Boolean;
  begin
    Result := GdipCreateTexture2I(AImage, WrapModeTile, R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top, ATexture) = Ok;
  end;

  procedure StretchPart(const ADstRect, ASrcRect: TRect);
  var
    APixelOffsetMode: TPixelOffsetMode;
    SW, SH, DW, DH: Integer;
  begin
    if GpIsRectVisible(AGraphics, ADstRect) then
    begin
      SH := ASrcRect.Bottom - ASrcRect.Top;
      SW := ASrcRect.Right - ASrcRect.Left;
      DW := ADstRect.Right - ADstRect.Left;
      DH := ADstRect.Bottom - ADstRect.Top;

      GdipCheck(GdipGetPixelOffsetMode(AGraphics, APixelOffsetMode));
      if APixelOffsetMode <> PixelOffsetModeHalf then
      begin
        if (DH > SH) and (SH > 1) then Dec(SH);
        if (DW > SW) and (SW > 1) then Dec(SW);
      end;

      GdipDrawImageRectRectI(AGraphics, AImage, ADstRect.Left, ADstRect.Top, DW, DH,
        ASrcRect.Left, ASrcRect.Top, SW, SH, UnitPixel, AImageAttributes, nil, nil);
    end;
  end;

  procedure TilePartManual(const ADest: TRect; ADestWidth, ADestHeight, ASourceWidth, ASourceHeight: Integer);
  var
    AColumn, ARow: Integer;
    AColumnCount, ARowCount: Integer;
    R: TRect;
  begin
    ARowCount := acCalcPatternCount(ADestHeight, ASourceHeight);
    AColumnCount := acCalcPatternCount(ADestWidth, ASourceWidth);
    for ARow := 0 to ARowCount - 1 do
    begin
      R.Top := ADest.Top + ASourceHeight * ARow;
      R.Bottom := Min(ADest.Bottom, R.Top + ASourceHeight);
      for AColumn := 0 to AColumnCount - 1 do
      begin
        R.Left := ADest.Left + ASourceWidth * AColumn;
        R.Right := Min(ADest.Right, R.Left + ASourceWidth);
        StretchPart(R, acRectSetSize(ASourceRect, R.Right - R.Left, R.Bottom - R.Top));
      end;
    end;
  end;

  function TilePartBrush(const R, ASource: TRect): Boolean;
  var
    ABitmap: GpBitmap;
    ABitmapGraphics: GpGraphics;
    ATexture: GpTexture;
    AWidth, AHeight: Integer;
  begin
    Result := (AImageAttributes = nil) and CreateTextureBrush(ASource, ATexture);
    if Result then
    try
      AWidth := R.Right - R.Left;
      AHeight := R.Bottom - R.Top;
      ABitmap := GpCreateBitmap(AWidth, AHeight);
      if ABitmap <> nil then
      try
        GdipCheck(GdipGetImageGraphicsContext(ABitmap, ABitmapGraphics));
        GdipCheck(GdipFillRectangleI(ABitmapGraphics, ATexture, 0, 0, AWidth, AHeight));
        GdipCheck(GdipDrawImageRectI(AGraphics, ABitmap, R.Left, R.Top, AWidth, AHeight));
        GdipCheck(GdipDeleteGraphics(ABitmapGraphics));
      finally
        GdipCheck(GdipDisposeImage(ABitmap));
      end;
    finally
      GdipCheck(GdipDeleteBrush(ATexture));
    end;
  end;

var
  DW, DH, SW, SH: Integer;
begin
  DW := ADestRect.Right - ADestRect.Left;
  DH := ADestRect.Bottom - ADestRect.Top;
  SW := ASourceRect.Right - ASourceRect.Left;
  SH := ASourceRect.Bottom - ASourceRect.Top;
  if (SH <> 0) and (SW <> 0) and (DW <> 0) and (DH <> 0) then
  begin
    if ATileDrawingMode and ((DW <> SW) or (DH <> SH)) then
    begin
      if not TilePartBrush(ADestRect, ASourceRect) then
        TilePartManual(ADestRect, DW, DH, SW, SH);
    end
    else
      StretchPart(ADestRect, ASourceRect);
  end;
end;

procedure GpDrawImage(AGraphics: GpGraphics; AImage: GpImage;
  const ADestRect, ASourceRect: TRect; ATileDrawingMode: Boolean; const AAlpha: Byte = $FF); overload;
var
  AColorMatrix: PColorMatrix;
  AImageAttributes: GpImageAttributes;
begin
  if AAlpha = $FF then
  begin
    GpDrawImage(AGraphics, AImage, nil, ADestRect, ASourceRect, ATileDrawingMode);
    Exit;
  end;

  GdipCreateImageAttributes(AImageAttributes);
  try
    AColorMatrix := GdipAlloc(SizeOf(TColorMatrix));
    try
      AColorMatrix^ := GpDefaultColorMatrix;
      AColorMatrix[3, 3] := AAlpha / $FF;
      GdipSetImageAttributesColorMatrix(AImageAttributes, ColorAdjustTypeBitmap, True, AColorMatrix, nil, ColorMatrixFlagsDefault);
      GpDrawImage(AGraphics, AImage, AImageAttributes, ADestRect, ASourceRect, ATileDrawingMode);
    finally
      GdipFree(AColorMatrix);
    end;
  finally
    GdipDisposeImageAttributes(AImageAttributes);
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// Codec
//----------------------------------------------------------------------------------------------------------------------

function GpGetCodecByMimeType(const AMimeType: UnicodeString; out ACodecID: TGUID): Boolean;
var
  ACodecInfo, AStartInfo: PImageCodecInfo;
  ACount: Cardinal;
  ASize, I: Cardinal;
begin
  Result := False;
  if (GdipGetImageEncodersSize(ACount, ASize) = Ok) and (ASize > 0) then
  begin
    GetMem(AStartInfo, ASize);
    try
      ACodecInfo := AStartInfo;
      if GdipGetImageEncoders(ACount, ASize, ACodecInfo) = Ok then
      begin
        for I := 1 to ACount do
        begin
          if SameText(PWideChar(ACodecInfo^.MimeType), AMimeType) then
          begin
            ACodecID := ACodecInfo^.Clsid;
            Exit(True);
          end;
          Inc(ACodecInfo);
        end;
      end;
    finally
      FreeMem(AStartInfo, ASize);
    end;
    if SameText(AMimeType, 'image/jpg') then
      Result := GpGetCodecByMimeType('image/jpeg', ACodecID)
  end;
end;

{ EGdipException }

constructor EGdipException.Create(AStatus: GpStatus);
begin
  CreateFmt(sErrorInvalidGdipOperation, [Ord(AStatus)]);
  FStatus := AStatus;
end;

//----------------------------------------------------------------------------------------------------------------------
// GDI + Cache
//----------------------------------------------------------------------------------------------------------------------

{$REGION 'GDI+ Cache'}

function acCreateFont(const AData: TACLFontData): GpFont;
const
  DefaultTrueTypeFont: PChar = 'Tahoma';
var
  AError: GpStatus;
  ALogFont: TLogFontW;
begin
  ZeroMemory(@ALogFont, SizeOf(ALogFont));

  ALogFont.lfHeight := AData.Height;
  ALogFont.lfEscapement := AData.Orientation;
  ALogFont.lfOrientation := AData.Orientation;
  ALogFont.lfWeight := IfThen(fsBold in AData.Style, FW_BOLD, FW_NORMAL);
  ALogFont.lfItalic := Ord(fsItalic in AData.Style);
  ALogFont.lfUnderline := Byte(fsUnderline in AData.Style);
  ALogFont.lfStrikeOut := Byte(fsStrikeOut in AData.Style);
  ALogFont.lfQuality := Ord(AData.Quality);

  if (AData.Charset = DEFAULT_CHARSET) and (DefFontData.Charset <> DEFAULT_CHARSET) then
    ALogFont.lfCharSet := DefFontData.Charset
  else
    ALogFont.lfCharSet := Byte(AData.Charset);

  ALogFont.lfClipPrecision := CLIP_DEFAULT_PRECIS;
  if ALogFont.lfOrientation <> 0 then
    ALogFont.lfOutPrecision := OUT_TT_ONLY_PRECIS
  else
    ALogFont.lfOutPrecision := OUT_DEFAULT_PRECIS;

  case AData.Pitch of
    fpVariable:
      ALogFont.lfPitchAndFamily := VARIABLE_PITCH;
    fpFixed:
      ALogFont.lfPitchAndFamily := FIXED_PITCH;
  else
    ALogFont.lfPitchAndFamily := DEFAULT_PITCH;
  end;

  StrLCopy(@ALogFont.lfFaceName[0], PChar(AData.Name), Length(ALogFont.lfFaceName));

  AError := GdipCreateFontFromLogfontW(MeasureCanvas.Handle, @ALogFont, Result);
  if AError = NotTrueTypeFont then
  begin
    StrLCopy(@ALogFont.lfFaceName[0], DefaultTrueTypeFont, Length(ALogFont.lfFaceName));
    AError := GdipCreateFontFromLogfontW(MeasureCanvas.Handle, @ALogFont, Result);
  end;
  GdipCheck(AError);
end;

{ TACLGdiplusResourcesCache }

class procedure TACLGdiplusResourcesCache.Flush;
begin
  FreeAndNil(FBrushes);
  FreeAndNil(FFonts);
  FreeAndNil(FPens);
end;

class function TACLGdiplusResourcesCache.BrushGet(AColor: TAlphaColor): GpBrush;
begin
  if FBrushes = nil then
  begin
    FBrushes := TACLValueCacheManager<TAlphaColor, GpBrush>.Create;
    FBrushes.OnRemove := HandlerOnRemoveBrush;
  end;
  if not FBrushes.Get(AColor, Result) then
  begin
    GdipCheck(GdipCreateSolidFill(AColor, Result));
    FBrushes.Add(AColor, Result);
  end;
end;

class function TACLGdiplusResourcesCache.FontGet(const AFont: TFont): GpFont;
begin
  Result := FontGet(TACLFontData.Create(AFont));
end;

class function TACLGdiplusResourcesCache.FontGet(const AFont: TACLFontData): GpFont;
begin
  if FFonts = nil then
  begin
    FFonts := TACLValueCacheManager<TACLFontData, GpFont>.Create(16);
    FFonts.OnRemove := HandlerOnRemoveFont;
  end;
  if not FFonts.Get(AFont, Result) then
  begin
    Result := acCreateFont(AFont);
    FFonts.Add(AFont, Result);
  end;
end;

class function TACLGdiplusResourcesCache.PenGet(Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle): GpPen;
const
  Map: array[TACL2DRenderStrokeStyle] of TDashStyle = (
    DashStyleSolid, DashStyleDash, DashStyleDot, DashStyleDashDot, DashStyleDashDotDot
  );
var
  AKey: TPenKey;
begin
  if FPens = nil then
  begin
    FPens := TACLValueCacheManager<TPenKey, GpPen>.Create(64);
    FPens.OnRemove := HandlerOnRemovePen;
  end;
  AKey.Color := Color;
  AKey.Style := Style;
  AKey.Width := Width;
  if not FPens.Get(AKey, Result) then
  begin
    GdipCheck(GdipCreatePen1(AKey.Color, AKey.Width, UnitPixel, Result));
    GdipCheck(GdipSetPenDashStyle(Result, Map[AKey.Style]));
    FPens.Add(AKey, Result);
  end;
end;

class procedure TACLGdiplusResourcesCache.HandlerOnRemoveBrush(Sender: TObject; const ABrush: GpBrush);
begin
  GdipDeleteBrush(ABrush);
end;

class procedure TACLGdiplusResourcesCache.HandlerOnRemoveFont(Sender: TObject; const AFont: GpFont);
begin
  GdipDeleteFont(AFont)
end;

class procedure TACLGdiplusResourcesCache.HandlerOnRemovePen(Sender: TObject; const APen: GpPen);
begin
  GdipDeletePen(APen);
end;

{$ENDREGION}

//----------------------------------------------------------------------------------------------------------------------
// 2D Render
//----------------------------------------------------------------------------------------------------------------------

{$REGION '2D Render'}

{ TACLGdiplusRenderImage }

constructor TACLGdiplusRenderImage.Create(AOwner: TACL2DRender; AHandle: GpImage);
begin
  inherited Create(AOwner);
  FHandle := AHandle;
  if GdipGetImageHeight(FHandle, Cardinal(FHeight)) <> Ok then
    FHeight := 0;
  if GdipGetImageWidth(FHandle, Cardinal(FWidth)) <> Ok then
    FWidth := 0;
end;

destructor TACLGdiplusRenderImage.Destroy;
begin
  GdipDisposeImage(FHandle);
  inherited;
end;

{ TACLGdiplusRenderImageAttributes }

constructor TACLGdiplusRenderImageAttributes.Create(AOwner: TACL2DRender);
begin
  inherited Create(AOwner);
  GdipCheck(GdipCreateImageAttributes(FHandle));
end;

destructor TACLGdiplusRenderImageAttributes.Destroy;
begin
  GdipCheck(GdipDisposeImageAttributes(FHandle));
  inherited;
end;

procedure TACLGdiplusRenderImageAttributes.SetColorMatrix(const AColorMatrix: ColorMatrix);
begin
  GdipCheck(GdipSetImageAttributesColorMatrix(FHandle, ColorAdjustTypeBitmap, True, @AColorMatrix, nil, ColorMatrixFlagsDefault));
end;

{ TACLGdiplusRenderPath }

constructor TACLGdiplusRenderPath.Create;
begin
  GdipCheck(GdipCreatePath(FillModeAlternate, Handle));
end;

destructor TACLGdiplusRenderPath.Destroy;
begin
  GdipCheck(GdipDeletePath(Handle));
  inherited;
end;

procedure TACLGdiplusRenderPath.AddArc(const X, Y, Width, Height, StartAngle, SweepAngle: Single);
begin
  GdipCheck(GdipAddPathArc(Handle, X, Y, Width, Height, StartAngle, SweepAngle));
end;

procedure TACLGdiplusRenderPath.AddLine(const X1, Y1, X2, Y2: Single);
begin
  GdipCheck(GdipAddPathLine(Handle, X1, Y1, X2, Y2));
end;

procedure TACLGdiplusRenderPath.AddRect(const R: TRectF);
begin
  GdipCheck(GdipAddPathRectangle(Handle, R.Left, R.Top, R.Width, R.Height));
end;

procedure TACLGdiplusRenderPath.FigureClose;
begin
  GdipCheck(GdipClosePathFigure(Handle));
end;

procedure TACLGdiplusRenderPath.FigureStart;
begin
  GdipCheck(GdipStartPathFigure(Handle));
end;

{ TACLGdiplusRender }

constructor TACLGdiplusRender.Create;
begin
  FSavedClipRegion := TStack.Create;
  FSavedWorldTransforms := TStack.Create;
end;

constructor TACLGdiplusRender.Create(Graphics: GpGraphics);
begin
  Create;
  FGraphics := Graphics;
end;

constructor TACLGdiplusRender.Create(DC: HDC);
begin
  Create;
  GdipCheck(GdipCreateFromHDC(DC, FGraphics));
end;

destructor TACLGdiplusRender.Destroy;
begin
  if FGraphics <> nil then
    GdipCheck(GdipDeleteGraphics(FGraphics));
  while FSavedClipRegion.Count > 0 do
    GdipDeleteRegion(FSavedClipRegion.Pop);
  while FSavedWorldTransforms.Count > 0 do
    GdipDeleteMatrix(FSavedWorldTransforms.Pop);
  FreeAndNil(FSavedWorldTransforms);
  FreeAndNil(FSavedClipRegion);
  inherited;
end;

function TACLGdiplusRender.CreatePath: TACL2DRenderPath;
begin
  Result := TACLGdiplusRenderPath.Create;
end;

{$REGION 'Clipping'}
function TACLGdiplusRender.IntersectClipRect(const R: TRect): Boolean;
begin
  GdipSetClipRectI(FGraphics, R.Left, R.Top, R.Width, R.Height, CombineModeIntersect);
  Result := IsVisible(R);
end;

function TACLGdiplusRender.IsVisible(const R: TRect): Boolean;
var
  LResult: LongBool;
begin
  Result := (GdipIsVisibleRectI(FGraphics, R.Left, R.Top, R.Width, R.Height, LResult) = Ok) and LResult;
end;

procedure TACLGdiplusRender.RestoreClipRegion;
var
  AHandle: GpRegion;
begin
  AHandle := FSavedClipRegion.Pop;
  GdipSetClipRegion(FGraphics, AHandle, CombineModeReplace);
  GdipDeleteRegion(AHandle);
end;

procedure TACLGdiplusRender.SaveClipRegion;
var
  AHandle: Pointer;
begin
  GdipCheck(GdipCreateRegion(AHandle));
  GdipCheck(GdipGetClip(FGraphics, AHandle));
  FSavedClipRegion.Push(AHandle);
end;
{$ENDREGION}

{$REGION 'World Transform'}

procedure TACLGdiplusRender.ModifyWorldTransform(const XForm: TXForm);
var
  AMatrix: GpMatrix;
begin
  GdipCheck(GdipCreateMatrix2(XForm.eM11, XForm.eM12, XForm.eM21, XForm.eM22, XForm.eDx, XForm.eDy, AMatrix));
  GdipCheck(GdipMultiplyWorldTransform(FGraphics, AMatrix, MatrixOrderPrepend));
  GdipCheck(GdipDeleteMatrix(AMatrix));
end;

procedure TACLGdiplusRender.RestoreWorldTransform;
var
  AHandle: GpMatrix;
begin
  AHandle := FSavedWorldTransforms.Pop;
  GdipSetWorldTransform(FGraphics, AHandle);
  GdipDeleteMatrix(AHandle);
end;

procedure TACLGdiplusRender.SaveWorldTransform;
var
  AHandle: GpMatrix;
begin
  GdipCheck(GdipCreateMatrix(AHandle));
  GdipCheck(GdipGetWorldTransform(FGraphics, AHandle));
  FSavedWorldTransforms.Push(AHandle);
end;

procedure TACLGdiplusRender.ScaleWorldTransform(ScaleX, ScaleY: Single);
begin
  GdipCheck(GdipScaleWorldTransform(FGraphics, ScaleX, ScaleY, MatrixOrderPrepend));
end;

procedure TACLGdiplusRender.TransformPoints(Points: PPointF; Count: Integer);
var
  AHandle: GpMatrix;
begin
  GdipCheck(GdipCreateMatrix(AHandle));
  GdipCheck(GdipGetWorldTransform(FGraphics, AHandle));
  GdipCheck(GdipTransformMatrixPoints(AHandle, PGpPointF(Points), Count));
  GdipCheck(GdipDeleteMatrix(AHandle));
end;

procedure TACLGdiplusRender.TranslateWorldTransform(OffsetX, OffsetY: Single);
begin
  GdipCheck(GdipTranslateWorldTransform(FGraphics, OffsetX, OffsetY, MatrixOrderPrepend));
end;
{$ENDREGION}

function TACLGdiplusRender.CreateImage(Colors: PRGBQuad; Width, Height: Integer; AlphaFormat: TAlphaFormat): TACL2DRenderImage;
const
  FormatMap: array[TAlphaFormat] of Integer = (PixelFormat32bppRGB, PixelFormat32bppARGB, PixelFormat32bppPARGB);
var
  AHandle: GpBitmap;
begin
  GdipCheck(GdipCreateBitmapFromScan0(Width, Height, Width * 4, FormatMap[AlphaFormat], PByte(Colors), AHandle));
  Result := TACLGdiplusRenderImage.Create(Self, AHandle);
end;

function TACLGdiplusRender.CreateImage(Image: TACLImage): TACL2DRenderImage;
begin
  Result := TACLGdiplusRenderImage.Create(Self, TACLImageAccess(Image).CloneHandle);
end;

function TACLGdiplusRender.CreateImageAttributes: TACL2DRenderImageAttributes;
begin
  Result := TACLGdiplusRenderImageAttributes.Create(Self);
end;

procedure TACLGdiplusRender.DrawImage(Image: TACL2DRenderImage;
  const TargetRect, SourceRect: TRect; Attributes: TACL2DRenderImageAttributes = nil);
var
  AImageAttributes: GpImageAttributes;
begin
  if IsValid(Image) then
  begin
    if IsValid(Attributes) then
      AImageAttributes := TACLGdiplusRenderImageAttributes(Attributes).FHandle
    else
      AImageAttributes := nil;

    GpDrawImage(FGraphics, TACLGdiplusRenderImage(Image).FHandle, AImageAttributes, TargetRect, SourceRect, False);
  end;
end;

procedure TACLGdiplusRender.FillClosedCurve2(
  AColor: TAlphaColor; const APoints: array of TPoint; ATension: Single);
begin
  GdipCheck(GdipFillClosedCurve2I(FGraphics, TACLGdiplusResourcesCache.BrushGet(AColor),
    @APoints[0], Length(APoints), ATension, FillModeWinding));
end;

procedure TACLGdiplusRender.DrawClosedCurve2(APenColor: TAlphaColor;
  const APoints: array of TPoint; ATension: Single; APenStyle: TACL2DRenderStrokeStyle; APenWidth: Single);
begin
  GdipCheck(GdipDrawClosedCurve2I(FGraphics,
    TACLGdiplusResourcesCache.PenGet(APenColor, APenWidth, APenStyle),
    @APoints[0], Length(APoints), ATension));
end;

procedure TACLGdiplusRender.DrawCurve2(APenColor: TAlphaColor;
  APoints: array of TPoint; ATension: Single; APenStyle: TACL2DRenderStrokeStyle; APenWidth: Single);
begin
  GdipCheck(GdipDrawCurve2I(FGraphics,
    TACLGdiplusResourcesCache.PenGet(APenColor, APenWidth, APenStyle),
    @APoints[0], Length(APoints), ATension));
end;

procedure TACLGdiplusRender.DrawEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor; StrokeWidth: Single; StrokeStyle: TACL2DRenderStrokeStyle);
begin
  if (X2 > X1) and (Y2 > Y1) and Color.IsValid and (StrokeWidth > 0) then
    GdipDrawEllipse(FGraphics, TACLGdiplusResourcesCache.PenGet(Color, StrokeWidth, StrokeStyle), X1, Y1, X2 - X1, Y2 - Y1);
end;

procedure TACLGdiplusRender.DrawPath(Path: TACL2DRenderPath; Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if Color.IsValid and (Width > 0) then
    GdipDrawPath(FGraphics, TACLGdiplusResourcesCache.PenGet(Color, Width, Style), TACLGdiplusRenderPath(Path).Handle);
end;

procedure TACLGdiplusRender.DrawPolygon(const Points: array of TPoint; Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if (Length(Points) > 1) and Color.IsValid and (Width > 0) then
    GdipDrawPolygonI(FGraphics, TACLGdiplusResourcesCache.PenGet(Color, Width, Style), @Points[0], Length(Points));
end;

procedure TACLGdiplusRender.DrawRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor; StrokeWidth: Single; StrokeStyle: TACL2DRenderStrokeStyle);
begin
  if (X2 > X1) and (Y2 > Y1) and Color.IsValid and (StrokeWidth > 0) then
    GdipDrawRectangle(FGraphics, TACLGdiplusResourcesCache.PenGet(Color, StrokeWidth, StrokeStyle), X1, Y1, X2 - X1, Y2 - Y1);
end;

procedure TACLGdiplusRender.DrawText(const Text: string; const R: TRect; Color: TAlphaColor;
  Font: TFont; HorzAlign: TAlignment; VertAlgin: TVerticalAlignment; WordWrap: Boolean);
const
  AlignmentToStringAlignment: array[TAlignment] of TStringAlignment = (
    StringAlignmentNear, StringAlignmentFar, StringAlignmentCenter
  );
  VerticalAlignmentToLineAlignment: array[TVerticalAlignment] of TStringAlignment = (
    StringAlignmentNear, StringAlignmentFar, StringAlignmentCenter
  );
var
  ARectF: TGPRectF;
  AStringFormat: GpStringFormat;
begin
  if Color.IsValid and not R.IsEmpty and (Text <> '') then
  begin
    GdipCheck(GdipCreateStringFormat(StringFormatFlagsMeasureTrailingSpaces or
      IfThen(WordWrap, 0, StringFormatFlagsNoWrap), 0, AStringFormat));
    try
      GdipCheck(GdipSetStringFormatAlign(AStringFormat, AlignmentToStringAlignment[HorzAlign]));
      GdipCheck(GdipSetStringFormatLineAlign(AStringFormat, VerticalAlignmentToLineAlignment[VertAlgin]));
      ARectF := MakeRect(Single(R.Left), R.Top, R.Width, R.Height);
      GdipDrawString(FGraphics, PChar(Text), Length(Text),
        TACLGdiplusResourcesCache.FontGet(Font), @ARectF, AStringFormat,
        TACLGdiplusResourcesCache.BrushGet(Color));
    finally
      GdipCheck(GdipDeleteStringFormat(AStringFormat));
    end;
  end;
end;

procedure TACLGdiplusRender.FillEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor);
begin
  if (X2 > X1) and (Y2 > Y1) and Color.IsValid then
    GdipFillEllipse(FGraphics, TACLGdiplusResourcesCache.BrushGet(Color), X1, Y1, X2 - X1, Y2 - Y1);
end;

procedure TACLGdiplusRender.FillPath(Path: TACL2DRenderPath; Color: TAlphaColor);
begin
  if Color.IsValid then
    GdipFillPath(FGraphics, TACLGdiplusResourcesCache.BrushGet(Color), TACLGdiplusRenderPath(Path).Handle);
end;

procedure TACLGdiplusRender.FillPolygon(const Points: array of TPoint; Color: TAlphaColor);
begin
  if (Length(Points) > 1) and Color.IsValid then
    GdipFillPolygonI(FGraphics, TACLGdiplusResourcesCache.BrushGet(Color), @Points[0], Length(Points), FillModeAlternate);
end;

procedure TACLGdiplusRender.FillRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor);
begin
  if (X2 > X1) and (Y2 > Y1) and Color.IsValid then
    GdipFillRectangle(FGraphics, TACLGdiplusResourcesCache.BrushGet(Color), X1, Y1, X2 - X1, Y2 - Y1);
end;

procedure TACLGdiplusRender.FillRectangleByGradient(
  AColor1, AColor2: TAlphaColor; const R: TRect; AMode: TLinearGradientMode);
var
  ABrush: GpBrush;
  ABrushRect: TGpRect;
begin
  ABrushRect.X := R.Left - 1;
  ABrushRect.Y := R.Top - 1;
  ABrushRect.Width := acRectWidth(R) + 2;
  ABrushRect.Height := acRectHeight(R) + 2;
  GdipCheck(GdipCreateLineBrushFromRectI(@ABrushRect, AColor1, AColor2, TLinearGradientMode(AMode), WrapModeTile, ABrush));
  GdipCheck(GdipFillRectangleI(FGraphics, ABrush, R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top));
  GdipCheck(GdipDeleteBrush(ABrush));
end;

procedure TACLGdiplusRender.Line(X1, Y1, X2, Y2: Single; Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if Color.IsValid and (Width > 0) then
    GdipDrawLine(FGraphics, TACLGdiplusResourcesCache.PenGet(Color, Width, Style), X1, Y1, X2, Y2);
end;

procedure TACLGdiplusRender.Line(const Points: PPoint; Count: Integer;
  Color: TAlphaColor; Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid);
begin
  if (Count > 0) and Color.IsValid and (Width > 0) then
    GdipDrawLinesI(FGraphics, TACLGdiplusResourcesCache.PenGet(Color, Width, Style), PGPPoint(Points), Count);
end;

function TACLGdiplusRender.GetInterpolationMode: TInterpolationMode;
begin
  GdipCheck(GdipGetInterpolationMode(FGraphics, Result));
end;

function TACLGdiplusRender.GetPixelOffsetMode: TPixelOffsetMode;
begin
  GdipCheck(GdipGetPixelOffsetMode(FGraphics, Result));
end;

function TACLGdiplusRender.GetSmoothingMode: TSmoothingMode;
begin
  GdipCheck(GdipGetSmoothingMode(FGraphics, Result));
end;

procedure TACLGdiplusRender.SetInterpolationMode(AValue: TInterpolationMode);
begin
  GdipSetInterpolationMode(FGraphics, AValue)
end;

procedure TACLGdiplusRender.SetPixelOffsetMode(AValue: TPixelOffsetMode);
begin
  GdipSetPixelOffsetMode(FGraphics, AValue);
end;

procedure TACLGdiplusRender.SetSmoothingMode(AValue: TSmoothingMode);
begin
  GdipSetSmoothingMode(FGraphics, AValue);
end;

{$ENDREGION}

//----------------------------------------------------------------------------------------------------------------------
// Other
//----------------------------------------------------------------------------------------------------------------------

{ TACLGdiplusStream }

function TACLGdiplusStream.Stat(out AStatStg: TStatStg; AStatFlag: DWORD): HResult; stdcall;
begin
  ZeroMemory(@AStatStg, SizeOf(AStatStg));
  Result := inherited Stat(AStatStg, AStatFlag);
end;

{ TACLGdiplusPaintCanvas }

constructor TACLGdiplusPaintCanvas.Create;
begin
  inherited Create;
  FSavedHandles := TStack.Create;
end;

destructor TACLGdiplusPaintCanvas.Destroy;
begin
  FreeAndNil(FSavedHandles);
  inherited Destroy;
end;

procedure TACLGdiplusPaintCanvas.BeginPaint(DC: HDC);
begin
  if FGraphics <> nil then
    FSavedHandles.Push(FGraphics);
  GdipCheck(GdipCreateFromHDC(DC, FGraphics));
end;

procedure TACLGdiplusPaintCanvas.EndPaint;
begin
  try
    GdipDeleteGraphics(FGraphics);
  finally
    if FSavedHandles.Count > 0 then
      FGraphics := FSavedHandles.Pop
    else
      FGraphics := nil;
  end;
end;

initialization
  GpPaintCanvas := TACLGdiplusPaintCanvas.Create;

finalization
  TACLGdiplusResourcesCache.Flush;
  FreeAndNil(GpPaintCanvas);
end.
