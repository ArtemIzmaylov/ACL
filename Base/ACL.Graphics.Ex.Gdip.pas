////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             Extended Graphics Library
//             v6.0
//
//  Purpose:   Gdi+ Wrappers
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Graphics.Ex.Gdip;

{$I ACL.Config.inc}

{$IFNDEF MSWINDOWS}
  {$MESSAGE FATAL 'Windows platform is required'}
{$ENDIF}

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

{$REGION ' Aliases '}
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
    //# Properties
    property Status: GpStatus read FStatus;
  end;

{$REGION ' GDI+ Cache '}

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

{$REGION ' 2D Render '}

  { TACLGdiplusRender }

  TACLGdiplusRender = class(TACL2DRender,
    IACL2DRenderGdiCompatible)
  strict private
    FPixelThickness: Single;

    procedure AdjustRectToGdiLikeAppearance(var X2, Y2: Single); inline;
    procedure GdipSetOrigin(ASet: Boolean); inline;
    function GetInterpolationMode: TInterpolationMode;
    function GetPixelOffsetMode: TPixelOffsetMode;
    function GetSmoothingMode: TSmoothingMode;
    procedure SetInterpolationMode(AValue: TInterpolationMode);
    procedure SetPixelOffsetMode(AValue: TPixelOffsetMode);
    procedure SetSmoothingMode(AValue: TSmoothingMode);
    procedure UpdatePixelThickness;
  protected
    FGraphics: GpGraphics;

    // IACL2DRenderGdiCompatible
    procedure GdiDraw(Proc: TACL2DRenderGdiDrawProc);
  public
    constructor Create; overload; virtual;
    constructor Create(DC: HDC); overload;
    constructor Create(Graphics: GpGraphics); overload;
    destructor Destroy; override;
    procedure BeginPaint(DC: HDC; const Unused1, Unused2: TRect); override;
    procedure EndPaint; override;

    // Clipping
    function Clip(const R: TRect; out Data: TACL2DRenderRawData): Boolean; override;
    procedure ClipRestore(Data: TACL2DRenderRawData); override;
    function IsVisible(const R: TRect): Boolean; override;

    // Images
    function CreateImage(Colors: PACLPixel32; Width, Height: Integer;
      AlphaFormat: TAlphaFormat = afDefined): TACL2DRenderImage; override;
    function CreateImage(Image: TACLImage): TACL2DRenderImage; override;
    function CreateImageAttributes: TACL2DRenderImageAttributes; override;
    procedure DrawImage(Image: TACL2DRenderImage;
      const TargetRect, SourceRect: TRect; Attributes: TACL2DRenderImageAttributes); override;
    procedure DrawImage(Image: TACL2DRenderImage;
      const TargetRect, SourceRect: TRect; Alpha: Byte = MaxByte); override;

    // Curves
    procedure DrawCurve(AColor: TAlphaColor;
      const APoints: array of TPoint; ATension: Single; AWidth: Single = 1.0); override;
    procedure FillCurve(AColor: TAlphaColor;
      const APoints: array of TPoint; ATension: Single); override;

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
    procedure FillHatchRectangle(const R: TRect; Color1, Color2: TAlphaColor; Size: Integer); override;
    procedure FillRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor); override;
    procedure FillRectangleByGradient(AColor1, AColor2: TAlphaColor; const R: TRect; AVertical: Boolean);

    // Text
    procedure DrawText(const Text: string; const R: TRect; Color: TAlphaColor; Font: TFont;
      HorzAlign: TAlignment = taLeftJustify; VertAlign: TVerticalAlignment = taVerticalCenter;
      WordWrap: Boolean = False); override;
    procedure MeasureText(const Text: string; Font: TFont; var Rect: TRect; WordWrap: Boolean);

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
    procedure RestoreWorldTransform(State: TACL2DRenderRawData); override;
    procedure SaveWorldTransform(out State: TACL2DRenderRawData); override;
    procedure ScaleWorldTransform(ScaleX, ScaleY: Single); override;
    procedure SetWorldTransform(const XForm: TXForm); override;
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
    procedure BeginPaint(Canvas: TCanvas); reintroduce; overload;
    procedure BeginPaint(DC: HDC); reintroduce; overload;
    procedure BeginPaint(DC: HDC; const Unused1, Unused2: TRect); override;
    procedure EndPaint; override;
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
procedure GdipFree;
procedure GdipInit;

function GpCreateBitmap(AWidth, AHeight: Integer;
  ABits: PByte = nil; APixelFormat: Integer = PixelFormat32bppPARGB): GpImage;
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

  { TACLGdiplusAlphaBlendAttributes }

  TACLGdiplusAlphaBlendAttributes = class
  strict private
    class var FAlpha: Byte;
    class var FColorMatrix: TColorMatrix;
    class var FHandle: GpImageAttributes;
  public
    class constructor Create;
    class procedure Finalize;
    class function Get(Alpha: Byte): GpImageAttributes;
  end;

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
  strict private
    FHandle: GpImageAttributes;
    FMatrix: TColorMatrix;

    procedure ApplyColorMatrix;
    procedure SetAlpha(AValue: Byte); override;
    procedure SetTintColor(AValue: TAlphaColor); override;
  public
    constructor Create(AOwner: TACL2DRender);
    destructor Destroy; override;
    property Handle: GpImageAttributes read FHandle;
  end;

  { TACLGdiplusRenderPath }

  TACLGdiplusRenderPath = class(TACL2DRenderPath)
  protected
    Handle: GpPath;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddArc(CX, CY, RadiusX, RadiusY, StartAngle, SweepAngle: Single); override;
    procedure AddLine(X1, Y1, X2, Y2: Single); override;
    procedure AddRect(const R: TRectF); override;
    procedure FigureClose; override;
    procedure FigureStart; override;
  end;

//------------------------------------------------------------------------------
// General
//------------------------------------------------------------------------------

var
  gdiplusTokenOwned: Boolean = False;

procedure GdipFree;
begin
  FreeAndNil(GpPaintCanvas);
  TACLGdiplusAlphaBlendAttributes.Finalize;
  TACLGdiplusResourcesCache.Flush;
  if gdiplusTokenOwned then
  begin
    GdiplusShutdown(gdiplusToken);
    gdiplusToken := 0;
  end;
end;

procedure GdipInit;
begin
  if gdiplusToken = 0 then
  begin
    ZeroMemory(@StartupInput, SizeOf(StartupInput));
    StartupInput.GdiplusVersion := 1;
    GdiplusStartup(gdiplusToken, @StartupInput, nil);
    gdiplusTokenOwned := gdiplusToken <> 0;
  end;
end;

procedure GdipCheck(AStatus: GpStatus);
begin
  if AStatus <> Ok then
    raise EGdipException.Create(AStatus);
end;

//------------------------------------------------------------------------------
// Internal Routines
//------------------------------------------------------------------------------

function GpCreateBitmap(AWidth, AHeight: Integer; ABits: PByte = nil;
  APixelFormat: Integer = PixelFormat32bppPARGB): GpImage;
begin
  if GdipCreateBitmapFromScan0(AWidth, AHeight, AWidth * 4, APixelFormat, ABits, Result) <> Ok then
    Result := nil;
end;

//------------------------------------------------------------------------------
// Fill Rect
//------------------------------------------------------------------------------

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

//------------------------------------------------------------------------------
// DrawImage
//------------------------------------------------------------------------------

procedure GpDrawImage(AGraphics: GpGraphics; AImage: GpImage; AImageAttributes: GpImageAttributes;
  const ADestRect, ASourceRect: TRect; ATileDrawingMode: Boolean); overload;

  function GpIsRectVisible(AGraphics: GpGraphics; const R: TRect): LongBool;
  begin
    try
      Result := GdipIsVisibleRectI(AGraphics, R.Left, R.Top, R.Width, R.Height, Result) = Ok;
    except
      Result := False; // Wine, "floating point operation" in GdipInvertMatrix
    end;
  end;

  function CreateTextureBrush(const R: TRect; out ATexture: GpTexture): Boolean;
  begin
    Result := GdipCreateTexture2I(AImage, WrapModeTile, R.Left, R.Top, R.Width, R.Height, ATexture) = Ok;
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
        StretchPart(R, TRect.Create(ASourceRect.TopLeft, R.Width, R.Height));
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
  const ADestRect, ASourceRect: TRect; ATileDrawingMode: Boolean;
  const AAlpha: Byte = $FF); overload;
begin
  GpDrawImage(AGraphics, AImage,
    TACLGdiplusAlphaBlendAttributes.Get(AAlpha),
    ADestRect, ASourceRect, ATileDrawingMode);
end;

//------------------------------------------------------------------------------
// Codecs
//------------------------------------------------------------------------------

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

{ TACLGdiplusAlphaBlendAttributes }

class constructor TACLGdiplusAlphaBlendAttributes.Create;
begin
  FAlpha := MaxByte;
  FColorMatrix := GpDefaultColorMatrix;
end;

class procedure TACLGdiplusAlphaBlendAttributes.Finalize;
begin
  if FHandle <> nil then
  begin
    GdipDisposeImageAttributes(FHandle);
    FHandle := nil;
  end;
end;

class function TACLGdiplusAlphaBlendAttributes.Get(Alpha: Byte): GpImageAttributes;
begin
  if Alpha = MaxByte then
    Exit(nil);
  if Alpha <> FAlpha then
  begin
    FAlpha := Alpha;
    FColorMatrix[3, 3] := FAlpha / MaxByte;
    if FHandle = nil then
      GdipCheck(GdipCreateImageAttributes(FHandle));
    if FHandle <> nil then
      GdipCheck(GdipSetImageAttributesColorMatrix(FHandle,
        ColorAdjustTypeBitmap, True, @FColorMatrix, nil, ColorMatrixFlagsDefault));
  end;
  Result := FHandle;
end;

{ EGdipException }

constructor EGdipException.Create(AStatus: GpStatus);
begin
  CreateFmt(sErrorInvalidGdipOperation, [Ord(AStatus)]);
  FStatus := AStatus;
end;

//------------------------------------------------------------------------------
// GDI + Cache
//------------------------------------------------------------------------------

{$REGION ' GDI+ Cache '}

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

class function TACLGdiplusResourcesCache.PenGet(
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle): GpPen;
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

//------------------------------------------------------------------------------
// 2D Render
//------------------------------------------------------------------------------

{$REGION ' 2D Render '}

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

procedure TACLGdiplusRenderImageAttributes.SetAlpha(AValue: Byte);
begin
  if Alpha <> AValue then
  begin
    inherited;
    ApplyColorMatrix;
  end;
end;

procedure TACLGdiplusRenderImageAttributes.SetTintColor(AValue: TAlphaColor);
begin
  if TintColor <> AValue then
  begin
    inherited;
    ApplyColorMatrix;
  end;
end;

procedure TACLGdiplusRenderImageAttributes.ApplyColorMatrix;
begin
  if TintColor.IsValid then
  begin
    ZeroMemory(@FMatrix, SizeOf(FMatrix));
    FMatrix[4, 0] := TintColor.R / MaxByte;
    FMatrix[4, 1] := TintColor.G / MaxByte;
    FMatrix[4, 2] := TintColor.B / MaxByte;
    FMatrix[4, 4] := TintColor.A / MaxByte;
  end
  else
    FMatrix := GpDefaultColorMatrix;

  FMatrix[3, 3] := Alpha / MaxByte;
  GdipCheck(GdipSetImageAttributesColorMatrix(FHandle,
    ColorAdjustTypeBitmap, True, @FMatrix, nil, ColorMatrixFlagsDefault));
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

procedure TACLGdiplusRenderPath.AddArc(CX, CY, RadiusX, RadiusY, StartAngle, SweepAngle: Single);
begin
  GdipCheck(GdipAddPathArc(Handle, CX - RadiusX, CY - RadiusY, 2 * RadiusX, 2 * RadiusY, StartAngle, SweepAngle));
end;

procedure TACLGdiplusRenderPath.AddLine(X1, Y1, X2, Y2: Single);
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
  FPixelThickness := 1.0;
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
    GdipDeleteGraphics(FGraphics);
  inherited;
end;

procedure TACLGdiplusRender.AdjustRectToGdiLikeAppearance(var X2, Y2: Single);
begin
  X2 := X2 - FPixelThickness;
  Y2 := Y2 - FPixelThickness;
end;

procedure TACLGdiplusRender.BeginPaint(DC: HDC; const Unused1, Unused2: TRect);
begin
  if FGraphics <> nil then
    raise EInvalidGraphicOperation.Create('Render is already in paint stage');
  GdipCheck(GdipCreateFromHDC(DC, FGraphics));
end;

procedure TACLGdiplusRender.EndPaint;
begin
  if FGraphics <> nil then
  try
    GdipDeleteGraphics(FGraphics);
  finally
    FGraphics := nil;
  end;
end;

function TACLGdiplusRender.CreatePath: TACL2DRenderPath;
begin
  Result := TACLGdiplusRenderPath.Create;
end;

{$REGION ' Clipping '}

function TACLGdiplusRender.Clip(const R: TRect; out Data: TACL2DRenderRawData): Boolean;
begin
  Result := IsVisible(R);
  if Result then
  begin
    GdipCheck(GdipCreateRegion(GpRegion(Data)));
    GdipCheck(GdipGetClip(NativeHandle, GpRegion(Data)));
    GdipSetClipRectI(NativeHandle,
      R.Left - Origin.X, R.Top - Origin.Y,
      R.Width, R.Height, CombineModeIntersect);
  end;
end;

procedure TACLGdiplusRender.ClipRestore(Data: TACL2DRenderRawData);
begin
  GdipSetClipRegion(NativeHandle, Data, CombineModeReplace);
  GdipDeleteRegion(Data);
end;

function TACLGdiplusRender.IsVisible(const R: TRect): Boolean;
var
  LResult: LongBool;
begin
  Result := (GdipIsVisibleRectI(NativeHandle,
    R.Left - Origin.X, R.Top - Origin.Y,
    R.Width, R.Height, LResult) = Ok) and LResult;
end;
{$ENDREGION}

{$REGION ' World Transform '}

procedure TACLGdiplusRender.ModifyWorldTransform(const XForm: TXForm);
var
  AMatrix: GpMatrix;
begin
  GdipCheck(GdipCreateMatrix2(XForm.eM11, XForm.eM12, XForm.eM21, XForm.eM22, XForm.eDx, XForm.eDy, AMatrix));
  GdipCheck(GdipMultiplyWorldTransform(NativeHandle, AMatrix, MatrixOrderPrepend));
  GdipCheck(GdipDeleteMatrix(AMatrix));
  UpdatePixelThickness;
end;

procedure TACLGdiplusRender.RestoreWorldTransform(State: TACL2DRenderRawData);
var
  LHandle: GpMatrix absolute State;
begin
  GdipSetWorldTransform(NativeHandle, LHandle);
  GdipDeleteMatrix(LHandle);
  UpdatePixelThickness;
end;

procedure TACLGdiplusRender.SaveWorldTransform(out State: TACL2DRenderRawData);
var
  LHandle: GpMatrix;
begin
  GdipCheck(GdipCreateMatrix(LHandle));
  GdipCheck(GdipGetWorldTransform(NativeHandle, LHandle));
  State := TACL2DRenderRawData(LHandle);
end;

procedure TACLGdiplusRender.ScaleWorldTransform(ScaleX, ScaleY: Single);
begin
  GdipCheck(GdipScaleWorldTransform(NativeHandle, ScaleX, ScaleY, MatrixOrderPrepend));
  UpdatePixelThickness;
end;

procedure TACLGdiplusRender.SetWorldTransform(const XForm: TXForm);
var
  AMatrix: GpMatrix;
begin
  GdipCheck(GdipCreateMatrix2(XForm.eM11, XForm.eM12, XForm.eM21, XForm.eM22, XForm.eDx, XForm.eDy, AMatrix));
  GdipCheck(GdipSetWorldTransform(NativeHandle, AMatrix));
  GdipCheck(GdipDeleteMatrix(AMatrix));
  UpdatePixelThickness;
end;

procedure TACLGdiplusRender.TransformPoints(Points: PPointF; Count: Integer);
var
  AHandle: GpMatrix;
begin
  GdipCheck(GdipCreateMatrix(AHandle));
  GdipCheck(GdipGetWorldTransform(NativeHandle, AHandle));
  GdipCheck(GdipTransformMatrixPoints(AHandle, PGpPointF(Points), Count));
  GdipCheck(GdipDeleteMatrix(AHandle));
end;

procedure TACLGdiplusRender.TranslateWorldTransform(OffsetX, OffsetY: Single);
begin
  GdipTranslateWorldTransform(NativeHandle, OffsetX, OffsetY, MatrixOrderPrepend);
end;

procedure TACLGdiplusRender.UpdatePixelThickness;
var
  LLength: Single;
  LPoint: array[0..1] of TPointF;
begin
  LPoint[0] := PointF(0.0, 0.0);
  LPoint[1] := PointF(1.0, 1.0);
  TransformPoints(@LPoint[0], 2);
  LLength := Sqrt(
    Sqr(LPoint[1].X - LPoint[0].X) +
    Sqr(LPoint[1].Y - LPoint[0].Y));
  if LLength > 0 then
    FPixelThickness := Sqrt(2) / LLength
  else
    FPixelThickness := 1.0;
end;
{$ENDREGION}

function TACLGdiplusRender.CreateImage(Colors: PACLPixel32;
  Width, Height: Integer; AlphaFormat: TAlphaFormat): TACL2DRenderImage;
const
  FormatMap: array[TAlphaFormat] of Integer = (
    PixelFormat32bppRGB, PixelFormat32bppARGB, PixelFormat32bppPARGB
  );
var
  AHandle: GpBitmap;
begin
  GdipCheck(GdipCreateBitmapFromScan0(Width, Height,
    Width * 4, FormatMap[AlphaFormat], PByte(Colors), AHandle));
  Result := TACLGdiplusRenderImage.Create(Self, AHandle);
end;

function TACLGdiplusRender.CreateImage(Image: TACLImage): TACL2DRenderImage;
var
  AHandle: GpImage;
begin
  GdipCheck(GdipCloneImage(TACLImageAccess(Image).Handle, AHandle));
  Result := TACLGdiplusRenderImage.Create(Self, AHandle);
end;

function TACLGdiplusRender.CreateImageAttributes: TACL2DRenderImageAttributes;
begin
  Result := TACLGdiplusRenderImageAttributes.Create(Self);
end;

procedure TACLGdiplusRender.DrawImage(Image: TACL2DRenderImage;
  const TargetRect, SourceRect: TRect; Attributes: TACL2DRenderImageAttributes);
var
  LAttrs: GpImageAttributes;
begin
  if IsValid(Image) then
  begin
    if IsValid(Attributes) then
      LAttrs := TACLGdiplusRenderImageAttributes(Attributes).Handle
    else
      LAttrs := nil;

    GpDrawImage(NativeHandle,
      TACLGdiplusRenderImage(Image).FHandle, LAttrs,
      TargetRect.OffsetTo(-Origin.X, -Origin.Y), SourceRect, False);
  end;
end;

procedure TACLGdiplusRender.DrawImage(
  Image: TACL2DRenderImage; const TargetRect, SourceRect: TRect; Alpha: Byte);
begin
  if IsValid(Image) then
    GpDrawImage(NativeHandle,
      TACLGdiplusRenderImage(Image).FHandle,
      TACLGdiplusAlphaBlendAttributes.Get(Alpha),
      TargetRect.OffsetTo(-Origin.X, -Origin.Y), SourceRect, False);
end;

procedure TACLGdiplusRender.DrawCurve(AColor: TAlphaColor;
  const APoints: array of TPoint; ATension: Single; AWidth: Single = 1.0);
begin
  GdipSetOrigin(True);
  try
    GdipDrawCurve2I(NativeHandle,
      TACLGdiplusResourcesCache.PenGet(AColor, AWidth, ssSolid),
      @APoints[0], Length(APoints), ATension);
  finally
    GdipSetOrigin(False);
  end;
end;

procedure TACLGdiplusRender.FillCurve(AColor: TAlphaColor;
  const APoints: array of TPoint; ATension: Single);
begin
  GdipSetOrigin(True);
  try
    GdipFillClosedCurve2I(
      NativeHandle, TACLGdiplusResourcesCache.BrushGet(AColor),
      @APoints[0], Length(APoints), ATension, FillModeWinding);
  finally
    GdipSetOrigin(False);
  end;
end;

procedure TACLGdiplusRender.DrawEllipse(X1, Y1, X2, Y2: Single;
  Color: TAlphaColor; StrokeWidth: Single; StrokeStyle: TACL2DRenderStrokeStyle);
begin
  if (X2 > X1) and (Y2 > Y1) and Color.IsValid and (StrokeWidth > 0) then
    GdipDrawEllipse(NativeHandle,
      TACLGdiplusResourcesCache.PenGet(Color, StrokeWidth, StrokeStyle),
      X1 - Origin.X, Y1 - Origin.Y, X2 - X1, Y2 - Y1);
end;

procedure TACLGdiplusRender.DrawPath(Path: TACL2DRenderPath;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if Color.IsValid and (Width > 0) then
  begin
    GdipSetOrigin(True);
    GdipDrawPath(NativeHandle,
      TACLGdiplusResourcesCache.PenGet(Color, Width, Style),
      TACLGdiplusRenderPath(Path).Handle);
    GdipSetOrigin(False);
  end;
end;

procedure TACLGdiplusRender.DrawPolygon(const Points: array of TPoint;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if (Length(Points) > 1) and Color.IsValid and (Width > 0) then
  begin
    GdipSetOrigin(True);
    GdipDrawPolygonI(NativeHandle,
      TACLGdiplusResourcesCache.PenGet(Color, Width, Style),
      @Points[0], Length(Points));
    GdipSetOrigin(False);
  end;
end;

procedure TACLGdiplusRender.DrawRectangle(X1, Y1, X2, Y2: Single;
  Color: TAlphaColor; StrokeWidth: Single; StrokeStyle: TACL2DRenderStrokeStyle);
begin
  AdjustRectToGdiLikeAppearance(X2, Y2);
  if (X2 > X1) and (Y2 > Y1) and Color.IsValid and (StrokeWidth > 0) then
    GdipDrawRectangle(NativeHandle,
      TACLGdiplusResourcesCache.PenGet(Color, StrokeWidth, StrokeStyle),
      X1 - Origin.X, Y1 - Origin.Y, X2 - X1, Y2 - Y1);
end;

procedure TACLGdiplusRender.DrawText(const Text: string; const R: TRect;
  Color: TAlphaColor; Font: TFont; HorzAlign: TAlignment; VertAlign: TVerticalAlignment;
  WordWrap: Boolean);
const
  AlignmentToStringAlignment: array[TAlignment] of TStringAlignment = (
    StringAlignmentNear, StringAlignmentFar, StringAlignmentCenter
  );
  VerticalAlignmentToLineAlignment: array[TVerticalAlignment] of TStringAlignment = (
    StringAlignmentNear, StringAlignmentFar, StringAlignmentCenter
  );
var
  AFlags: Integer;
  AFont: GpFont;
  ARectF: TGPRectF;
  AStringFormat: GpStringFormat;
begin
  if Color.IsValid and not R.IsEmpty and (Text <> '') then
  begin
//    SaveClipRegion;
//    try
//      IntersectClipRect(R);

      AFont := TACLGdiplusResourcesCache.FontGet(Font);
      ARectF := MakeRect(Single(R.Left - Origin.X), R.Top - Origin.X, R.Width, R.Height);

//      // GDI+ adds a small amount (1/6 em) to each end of every string displayed.
//      // This 1/6 em allows >for glyphs with overhanging ends (such as italic 'f'),
//      // and also gives GDI+ a small amount >of leeway to help with grid fitting expansion.
//      if GdipGetFontSize(AFont, APadding) = Ok then
//      begin
//        APadding := APadding / 6;
//        ARectF.X := ARectF.X - APadding;
//        ARectF.Y := ARectF.Y - APadding;
//        ARectF.Height := ARectF.Height + 2 * APadding;
//        ARectF.Width := ARectF.Width + 2 * APadding;
//      end;

      AFlags := StringFormatFlagsMeasureTrailingSpaces;
      if not WordWrap then
        AFlags := AFlags or StringFormatFlagsNoWrap;

      GdipCheck(GdipCreateStringFormat(AFlags, 0, AStringFormat));
      try
        GdipSetStringFormatAlign(AStringFormat, AlignmentToStringAlignment[HorzAlign]);
        GdipSetStringFormatLineAlign(AStringFormat, VerticalAlignmentToLineAlignment[VertAlign]);
        GdipDrawString(NativeHandle, PChar(Text), Length(Text), AFont,
          @ARectF, AStringFormat, TACLGdiplusResourcesCache.BrushGet(Color));
      finally
        GdipDeleteStringFormat(AStringFormat);
      end;
//    finally
//      RestoreClipRegion;
//    end;
  end;
end;

procedure TACLGdiplusRender.MeasureText(const Text: string; Font: TFont; var Rect: TRect; WordWrap: Boolean);
var
  ACalcRect: TGPRectF;
  AFlags: Integer;
  AStringFormat: GpStringFormat;
begin
  ACalcRect := MakeRect(Single(Rect.Left), Rect.Top, Rect.Width, Rect.Height);

  AFlags := StringFormatFlagsMeasureTrailingSpaces;
  if not WordWrap then
    AFlags := AFlags or StringFormatFlagsNoWrap;

  GdipCheck(GdipCreateStringFormat(AFlags, LANG_NEUTRAL, AStringFormat));
  try
    GdipCheck(GdipMeasureString(NativeHandle, PWideChar(Text), Length(Text),
      TACLGdiplusResourcesCache.FontGet(Font), @ACalcRect,
      AStringFormat, @ACalcRect, nil, nil));
    Rect.Left := Trunc(ACalcRect.X);
    Rect.Top := Trunc(ACalcRect.Y);
    Rect.Right := Trunc(ACalcRect.X + ACalcRect.Width);
    Rect.Bottom := Trunc(ACalcRect.Y + ACalcRect.Height);
  finally
    GdipDeleteStringFormat(AStringFormat);
  end;
end;

procedure TACLGdiplusRender.FillEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor);
begin
  if (X2 > X1) and (Y2 > Y1) and Color.IsValid then
    GdipFillEllipse(NativeHandle, TACLGdiplusResourcesCache.BrushGet(Color),
      X1 - Origin.X, Y1 - Origin.Y, X2 - X1, Y2 - Y1);
end;

procedure TACLGdiplusRender.FillHatchRectangle(const R: TRect; Color1, Color2: TAlphaColor; Size: Integer);
var
  ABitmap: GpBitmap;
  ABitmapGraphics: GpGraphics;
  ABitmapBrush: GpTexture;
  ABrush: GpBrush;
begin
  ABitmap := GpCreateBitmap(2 * Size, 2 * Size);
  if ABitmap <> nil then
  try
    // Generate Pattern
    if GdipGetImageGraphicsContext(ABitmap, ABitmapGraphics) = Ok then
    try
      ABrush := TACLGdiplusResourcesCache.BrushGet(Color2);
      GdipFillRectangleI(ABitmapGraphics, ABrush, 0, 0, Size, Size);
      GdipFillRectangleI(ABitmapGraphics, ABrush, Size, Size, Size, Size);
      ABrush := TACLGdiplusResourcesCache.BrushGet(Color1);
      GdipFillRectangleI(ABitmapGraphics, ABrush, 0, Size, Size, Size);
      GdipFillRectangleI(ABitmapGraphics, ABrush, Size, 0, Size, Size);
    finally
      GdipCheck(GdipDeleteGraphics(ABitmapGraphics));
    end;

    // Draw
    if GdipCreateTexture(ABitmap, WrapModeTile, ABitmapBrush) = Ok then
    try
      GdipFillRectangle(NativeHandle, ABitmapBrush,
        R.Left - Origin.X, R.Top - Origin.Y, R.Width, R.Height);
    finally
      GdipDeleteBrush(ABitmapBrush);
    end;
  finally
    GdipDisposeImage(ABitmap);
  end;
end;

procedure TACLGdiplusRender.FillPath(Path: TACL2DRenderPath; Color: TAlphaColor);
begin
  if Color.IsValid then
  begin
    GdipSetOrigin(True);
    GdipFillPath(NativeHandle,
      TACLGdiplusResourcesCache.BrushGet(Color),
      TACLGdiplusRenderPath(Path).Handle);
    GdipSetOrigin(False);
  end;
end;

procedure TACLGdiplusRender.FillPolygon(const Points: array of TPoint; Color: TAlphaColor);
begin
  if (Length(Points) > 1) and Color.IsValid then
  begin
    GdipSetOrigin(True);
    GdipFillPolygonI(NativeHandle,
      TACLGdiplusResourcesCache.BrushGet(Color),
      @Points[0], Length(Points), FillModeAlternate);
    GdipSetOrigin(False);
  end;
end;

procedure TACLGdiplusRender.FillRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor);
begin
  if (X2 > X1) and (Y2 > Y1) and Color.IsValid then
  try
    GdipFillRectangle(NativeHandle,
      TACLGdiplusResourcesCache.BrushGet(Color),
      X1 - Origin.X, Y1 - Origin.Y, X2 - X1, Y2 - Y1);
  except
    // Wine, "floating point operation" in GdipInvertMatrix
  end;
end;

procedure TACLGdiplusRender.FillRectangleByGradient(
  AColor1, AColor2: TAlphaColor; const R: TRect; AVertical: Boolean);
var
  ABrush: GpBrush;
  ABrushRect: TGpRect;
begin
  ABrushRect.X := R.Left - 1 - Origin.X;
  ABrushRect.Y := R.Top - 1 - Origin.Y;
  ABrushRect.Width := R.Width + 2;
  ABrushRect.Height := R.Height + 2;
  if (ABrushRect.Width > 0) and (ABrushRect.Height > 0) then
  try
    if GdipCreateLineBrushFromRectI(@ABrushRect, AColor1, AColor2,
      TACLMath.IfThen(AVertical, gmVertical, gmHorizontal),
      WrapModeTile, ABrush) = Ok then
    try
      GdipFillRectangleI(NativeHandle, ABrush,
        R.Left - Origin.X, R.Top - Origin.Y, R.Width, R.Height);
    finally
      GdipDeleteBrush(ABrush);
    end;
  except
    // Wine, "floating point operation" in GdipInvertMatrix
  end;
end;

procedure TACLGdiplusRender.Line(X1, Y1, X2, Y2: Single; 
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if Color.IsValid and (Width > 0) then
    GdipDrawLine(NativeHandle,
      TACLGdiplusResourcesCache.PenGet(Color, Width, Style),
      X1 - Origin.X, Y1 - Origin.Y, X2, Y2);
end;

procedure TACLGdiplusRender.Line(const Points: PPoint; Count: Integer;
  Color: TAlphaColor; Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid);
begin
  if (Count > 0) and Color.IsValid and (Width > 0) then
  begin
    GdipSetOrigin(True);
    GdipDrawLinesI(NativeHandle,
      TACLGdiplusResourcesCache.PenGet(Color, Width, Style),
      PGPPoint(Points), Count);
    GdipSetOrigin(False);
  end;
end;

procedure TACLGdiplusRender.GdiDraw(Proc: TACL2DRenderGdiDrawProc);
var
  DC: HDC;
  R: TRect;
begin
  GdipCheck(GdipGetDC(NativeHandle, DC));
  try
    Proc(DC, R);
  finally
    GdipCheck(GdipReleaseDC(NativeHandle, DC));
  end;
end;

procedure TACLGdiplusRender.GdipSetOrigin(ASet: Boolean);
begin
  if (Origin.X <> 0) or (Origin.X <> 0) then
  begin
    GdipTranslateWorldTransform(NativeHandle,
      -Signs[ASet] * Origin.X,
      -Signs[ASet] * Origin.Y, MatrixOrderPrepend);
  end;
end;

function TACLGdiplusRender.GetInterpolationMode: TInterpolationMode;
begin
  GdipCheck(GdipGetInterpolationMode(NativeHandle, Result));
end;

function TACLGdiplusRender.GetPixelOffsetMode: TPixelOffsetMode;
begin
  GdipCheck(GdipGetPixelOffsetMode(NativeHandle, Result));
end;

function TACLGdiplusRender.GetSmoothingMode: TSmoothingMode;
begin
  GdipCheck(GdipGetSmoothingMode(NativeHandle, Result));
end;

procedure TACLGdiplusRender.SetInterpolationMode(AValue: TInterpolationMode);
begin
  GdipSetInterpolationMode(NativeHandle, AValue)
end;

procedure TACLGdiplusRender.SetPixelOffsetMode(AValue: TPixelOffsetMode);
begin
  GdipSetPixelOffsetMode(NativeHandle, AValue);
end;

procedure TACLGdiplusRender.SetSmoothingMode(AValue: TSmoothingMode);
begin
  GdipSetSmoothingMode(NativeHandle, AValue);
end;

{$ENDREGION}

//------------------------------------------------------------------------------
// Other
//------------------------------------------------------------------------------

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

procedure TACLGdiplusPaintCanvas.BeginPaint(Canvas: TCanvas);
begin
  BeginPaint(Canvas.Handle);
end;

procedure TACLGdiplusPaintCanvas.BeginPaint(DC: HDC);
begin
  if NativeHandle <> nil then
    FSavedHandles.Push(NativeHandle);
  GdipCheck(GdipCreateFromHDC(DC, FGraphics));
end;

procedure TACLGdiplusPaintCanvas.BeginPaint(DC: HDC; const Unused1, Unused2: TRect);
begin
  BeginPaint(DC)
end;

procedure TACLGdiplusPaintCanvas.EndPaint;
begin
  try
    GdipDeleteGraphics(NativeHandle);
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
  if IsLibrary then // shutdown must not be called from DLL finalization
    GdiplusTokenOwned := False;
  GdipFree;
end.
