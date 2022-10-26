{*********************************************}
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
  ACL.Classes.Collections,
  ACL.Math;

type
  GpHandle = type Pointer;

  TGpSmoothingMode = (
    smInvalid      = -1,
    smDefault      = 0,
    smHighSpeed    = 1,
    smHighQuality  = 2,
    smNone         = 3,
    smAntiAlias    = 4
  );

  TGpInterpolationMode = (
    imDefault             = 0,
    imLowQuality          = 1,
    imHighQuality         = 2,
    imBilinear            = 3,
    imBicubic             = 4,
    imNearestNeighbor     = 5,
    imHighQualityBilinear = 6,
    imHighQualityBicubic  = 7
  );

  TGpPixelOffsetMode = (
    pomInvalid     = Ord(QualityModeInvalid),
    pomDefault     = Ord(QualityModeDefault),
    pomHighSpeed   = Ord(QualityModeLow),
    pomHighQuality = Ord(QualityModeHigh),
    pomNone        = Ord(QualityModeHigh) + 1, // No pixel offset
    pomHalf        = Ord(QualityModeHigh) + 2  // Offset by -0.5, -0.5 for fast anti-alias perf
  );

  TGpCompositingMode = (
    cmSourceOver = 0,
    cmSourceCopy = 1
  );

  TGpLinearGradientMode = (
    gmHorizontal = 0,
    gmVertical = 1,
    gmForwardDiagonal = 2,
    gmBackwardDiagonal = 3
  );

  TGpTextRenderingHint = (
    trhSystemDefault,                // Glyph with system default rendering hint
    trhSingleBitPerPixelGridFit,     // Glyph bitmap with hinting
    trhSingleBitPerPixel,            // Glyph bitmap without hinting
    trhAntiAliasGridFit,             // Glyph anti-alias bitmap with hinting
    trhAntiAlias,                    // Glyph anti-alias bitmap without hinting
    trhClearTypeGridFit              // Glyph CT bitmap with hinting
  );

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

  { TACLGdiplusObject }

  TACLGdiplusObject = class
  public
    class function NewInstance: TObject; override;
    procedure FreeInstance; override;
  end;

  { TACLGdiplusCustomGraphicObject }

  TACLGdiplusCustomGraphicObject = class(TACLGdiplusObject)
  strict private
    FChangeLockCount: Integer;
    FHandle: GpHandle;

    FOnChange: TNotifyEvent;

    function GetHandle: GpHandle;
    function GetHandleAllocated: Boolean;
  protected
    procedure Changed; virtual;
    procedure DoCreateHandle(out AHandle: GpHandle); virtual; abstract;
    procedure DoFreeHandle(AHandle: GpHandle); virtual; abstract;
  public
    procedure BeforeDestruction; override;
    procedure FreeHandle;
    procedure HandleNeeded; virtual;
    //
    property Handle: GpHandle read GetHandle;
    property HandleAllocated: Boolean read GetHandleAllocated;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  { TACLGdiplusBrush }

  TACLGdiplusBrush = class(TACLGdiplusCustomGraphicObject)
  strict private
    FColor: TAlphaColor;

    procedure SetColor(AValue: TAlphaColor);
  protected
    procedure DoCreateHandle(out AHandle: GpHandle); override;
    procedure DoFreeHandle(AHandle: GpHandle); override;
  public
    procedure AfterConstruction; override;
    //
    property Color: TAlphaColor read FColor write SetColor;
  end;

  { TACLGdiplusPen }

  TACLGdiplusPenStyle = (gpsSolid, gpsDash, gpsDot, gpsDashDot, gpsDashDotDot);

  TACLGdiplusPen = class(TACLGdiplusCustomGraphicObject)
  strict private
    FColor: TAlphaColor;
    FStyle: TACLGdiplusPenStyle;
    FWidth: Single;

    procedure SetColor(AValue: TAlphaColor);
    procedure SetStyle(AValue: TACLGdiplusPenStyle);
    procedure SetWidth(AValue: Single);
  protected
    procedure DoCreateHandle(out AHandle: GpHandle); override;
    procedure DoFreeHandle(AHandle: GpHandle); override;
    procedure DoSetDashStyle(AHandle: GpHandle);
  public
    procedure AfterConstruction; override;
    //
    property Color: TAlphaColor read FColor write SetColor;
    property Style: TACLGdiplusPenStyle read FStyle write SetStyle;
    property Width: Single read FWidth write SetWidth;
  end;

  { TACLGdiplusCanvas }

  TACLGdiplusCanvas = class(TACLGdiplusObject)
  strict private
    FBrush: TACLGdiplusBrush;
    FPen: TACLGdiplusPen;

    function GetInterpolationMode: TGpInterpolationMode;
    function GetPixelOffsetMode: TGpPixelOffsetMode;
    function GetSmoothingMode: TGpSmoothingMode;
    procedure SetInterpolationMode(const Value: TGpInterpolationMode);
    procedure SetSmoothingMode(const Value: TGpSmoothingMode);
    procedure SetPixelOffsetMode(const Value: TGpPixelOffsetMode);
  protected
    FHandle: GpGraphics;
  public
    constructor Create; overload; virtual;
    constructor Create(DC: HDC); overload;
    constructor Create(AHandle: GpGraphics); overload;
    destructor Destroy; override;

    // Closed Curve
    procedure FillClosedCurve2(ABrush: TACLGdiplusBrush; const APoints: array of TPoint; ATension: Single); overload;
    procedure FillClosedCurve2(AColor: TAlphaColor; const APoints: array of TPoint; ATension: Single); overload;
    procedure DrawClosedCurve2(APen: TACLGdiplusPen; const APoints: array of TPoint; ATension: Single); overload;
    procedure DrawClosedCurve2(APenColor: TAlphaColor; const APoints: array of TPoint; ATension: Single;
      APenStyle: TACLGdiplusPenStyle = gpsSolid; APenWidth: Single = 1.0); overload;

    // Curve
    procedure DrawCurve2(APen: TACLGdiplusPen; APoints: array of TPoint; ATension: Single); overload;
    procedure DrawCurve2(APenColor: TAlphaColor; APoints: array of TPoint; ATension: Single;
      APenStyle: TACLGdiplusPenStyle = gpsSolid; APenWidth: Single = 1.0); overload;

    // Lines
    procedure DrawLine(APen: TACLGdiplusPen; X1, Y1, X2, Y2: Integer); overload;
    procedure DrawLine(APenColor: TAlphaColor; X1, Y1, X2, Y2: Integer;
      APenStyle: TACLGdiplusPenStyle = gpsSolid; APenWidth: Single = 1.0); overload;
    procedure DrawLine(APenColor: TAlphaColor; const APoints: array of TPoint;
      APenStyle: TACLGdiplusPenStyle = gpsSolid; APenWidth: Single = 1.0); overload;

    // Ellipse
    procedure DrawEllipse(APen: TACLGdiplusPen; const R: TRect); overload;
    procedure DrawEllipse(APenColor: TAlphaColor; const R: TRect;
      APenStyle: TACLGdiplusPenStyle = gpsSolid; APenWidth: Single = 1.0); overload;
    procedure FillEllipse(ABrush: TACLGdiplusBrush; const R: TRect); overload;
    procedure FillEllipse(AColor: TAlphaColor; const R: TRect); overload;

    // Rectangle
    procedure FillRectangle(ABrush: TACLGdiplusBrush; const R: TRect; AMode: TGpCompositingMode = cmSourceOver); overload;
    procedure FillRectangle(AColor: TAlphaColor; const R: TRect; AMode: TGpCompositingMode = cmSourceOver); overload;
    procedure FillRectangleByGradient(AColor1, AColor2: TAlphaColor; const R: TRect; AMode: TGpLinearGradientMode);
    procedure DrawRectangle(APen: TACLGdiplusPen; const R: TRect); overload;
    procedure DrawRectangle(APenColor: TAlphaColor; const R: TRect;
      APenStyle: TACLGdiplusPenStyle = gpsSolid; APenWidth: Single = 1.0); overload;

    // Text
    procedure TextOut(const AText: UnicodeString; const R: TRect; AFont: TFont; AHorzAlign: TAlignment;
      AVertAlign: TVerticalAlignment; AWordWrap: Boolean; ATextColor: TAlphaColor;
      ARendering: TGpTextRenderingHint = trhSystemDefault);

    property Handle: GpGraphics read FHandle;
    property InterpolationMode: TGpInterpolationMode read GetInterpolationMode write SetInterpolationMode;
    property PixelOffsetMode: TGpPixelOffsetMode read GetPixelOffsetMode write SetPixelOffsetMode;
    property SmoothingMode: TGpSmoothingMode read GetSmoothingMode write SetSmoothingMode;
  end;

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

  { TACLGdiplusSolidBrushCache }

  TACLGdiplusSolidBrushCache = class
  strict private
    class var FInstance: TACLValueCacheManager<TAlphaColor, GpBrush>;

    class procedure RemoveValueHandler(Sender: TObject; const ABrush: GpBrush);
  public
    class destructor Destroy;
    class procedure Flush;
    class function GetOrCreate(AColor: TAlphaColor): GpBrush;
  end;

var
  GpDefaultColorMatrix: TColorMatrix = (
    (1.0, 0.0, 0.0, 0.0, 0.0),
    (0.0, 1.0, 0.0, 0.0, 0.0),
    (0.0, 0.0, 1.0, 0.0, 0.0),
    (0.0, 0.0, 0.0, 1.0, 0.0),
    (0.0, 0.0, 0.0, 0.0, 1.0)
  );

procedure GdipCheck(AStatus: GpStatus);
function GpPaintCanvas: TACLGdiplusPaintCanvas;

function GpCreateBitmap(AWidth, AHeight: Integer; ABits: PByte = nil; APixelFormat: Integer = PixelFormat32bppPARGB): GpImage;
function GpGetCodecByMimeType(const AMimeType: UnicodeString; out ACodecID: TGUID): Boolean;
procedure GpFillRect(DC: HDC; const R: TRect; AColor: TAlphaColor; AMode: TGpCompositingMode = cmSourceOver);
procedure GpFocusRect(DC: HDC; const R: TRect; AColor: TAlphaColor);
procedure GpFrameRect(DC: HDC; const R: TRect; AColor: TAlphaColor; AFrameSize: Integer);
procedure GpDrawImage(AGraphics: GpGraphics; AImage: GpImage; AImageAttributes: GpImageAttributes;
  const ADestRect, ASourceRect: TRect; ATileDrawingMode: Boolean); overload;
procedure GpDrawImage(AGraphics: GpGraphics; AImage: GpImage;
  const ADestRect, ASourceRect: TRect; ATileDrawingMode: Boolean; const AAlpha: Byte = $FF); overload;
implementation

uses
  System.Math,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings,
  ACL.Utils.Stream;

const
  sErrorInvalidGdipOperation = 'Invalid operation in GDI+ (Code: %d)';
  sErrorPaintCanvasAlreadyBusy = 'PaintCanvas is already busy!';

var
  FPaintCanvas: TACLGdiplusPaintCanvas;

procedure GdipCheck(AStatus: GpStatus);
begin
  if AStatus <> Ok then
    raise EGdipException.Create(AStatus);
end;

function GpPaintCanvas: TACLGdiplusPaintCanvas;
begin
  if FPaintCanvas = nil then
    FPaintCanvas := TACLGdiplusPaintCanvas.Create;
  Result := FPaintCanvas;
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

procedure GpFillRect(DC: HDC; const R: TRect; AColor: TAlphaColor; AMode: TGpCompositingMode = cmSourceOver);
begin
  if (AColor <> TAlphaColor.None) or (AMode = cmSourceCopy) then
  begin
    GpPaintCanvas.BeginPaint(DC);
    try
      GpPaintCanvas.FillRectangle(AColor, R, AMode);
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
      GpPaintCanvas.DrawRectangle(AColor, R, gpsSolid, AFrameSize);
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
        GpPaintCanvas.DrawRectangle(AColor, R, gpsDot);
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
          if acSameText(PWideChar(ACodecInfo^.MimeType), AMimeType) then
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
    if acSameText(AMimeType, 'image/jpg') then
      Result := GpGetCodecByMimeType('image/jpeg', ACodecID)
  end;
end;

{ EGdipException }

constructor EGdipException.Create(AStatus: GpStatus);
begin
  CreateFmt(sErrorInvalidGdipOperation, [Ord(AStatus)]);
  FStatus := AStatus;
end;

{ TACLGdiplusObject }

class function TACLGdiplusObject.NewInstance: TObject;
begin
  Result := InitInstance(GdipAlloc(InstanceSize));
end;

procedure TACLGdiplusObject.FreeInstance;
begin
  CleanupInstance;
  GdipFree(Self);
end;

{ TACLGdiplusCustomGraphicObject }

procedure TACLGdiplusCustomGraphicObject.BeforeDestruction;
begin
  inherited BeforeDestruction;
  FreeHandle;
end;

procedure TACLGdiplusCustomGraphicObject.FreeHandle;
begin
  if HandleAllocated then
  begin
    DoFreeHandle(FHandle);
    FHandle := nil;
  end;
end;

procedure TACLGdiplusCustomGraphicObject.HandleNeeded;
begin
  if FHandle = nil then
  begin
    Inc(FChangeLockCount);
    try
      DoCreateHandle(FHandle);
    finally
      Dec(FChangeLockCount);
    end;
  end;
end;

procedure TACLGdiplusCustomGraphicObject.Changed;
begin
  if FChangeLockCount = 0 then
    CallNotifyEvent(Self, OnChange);
end;

function TACLGdiplusCustomGraphicObject.GetHandle: GpHandle;
begin
  HandleNeeded;
  Result := FHandle;
end;

function TACLGdiplusCustomGraphicObject.GetHandleAllocated: Boolean;
begin
  Result := FHandle <> nil;
end;

{ TACLGdiplusBrush }

procedure TACLGdiplusBrush.AfterConstruction;
begin
  inherited AfterConstruction;
  FColor := TAlphaColor.Black;
end;

procedure TACLGdiplusBrush.DoCreateHandle(out AHandle: GpHandle);
begin
  GdipCheck(GdipCreateSolidFill(Color, GpBrush(AHandle)));
end;

procedure TACLGdiplusBrush.DoFreeHandle(AHandle: GpHandle);
begin
  GdipCheck(GdipDeleteBrush(AHandle));
end;

procedure TACLGdiplusBrush.SetColor(AValue: TAlphaColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    if HandleAllocated then
      GdipCheck(GdipSetSolidFillColor(Handle, Color));
    Changed;
  end;
end;

{ TACLGdiplusPen }

procedure TACLGdiplusPen.AfterConstruction;
begin
  inherited AfterConstruction;
  FColor := TAlphaColor.Black;
  FWidth := 1.0;
end;

procedure TACLGdiplusPen.DoCreateHandle(out AHandle: GpHandle);
begin
  GdipCheck(GdipCreatePen1(Color, Width, UnitPixel, GpPen(AHandle)));
  DoSetDashStyle(AHandle);
end;

procedure TACLGdiplusPen.DoFreeHandle(AHandle: GpHandle);
begin
  GdipCheck(GdipDeletePen(AHandle));
end;

procedure TACLGdiplusPen.DoSetDashStyle(AHandle: GpHandle);
const
  Map: array[TACLGdiplusPenStyle] of TDashStyle = (
    DashStyleSolid, DashStyleDash, DashStyleDot, DashStyleDashDot, DashStyleDashDotDot
  );
begin
  GdipCheck(GdipSetPenDashStyle(AHandle, Map[Style]));
end;

procedure TACLGdiplusPen.SetColor(AValue: TAlphaColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    if HandleAllocated then
      GdipCheck(GdipSetPenColor(Handle, Color));
    Changed;
  end;
end;

procedure TACLGdiplusPen.SetStyle(AValue: TACLGdiplusPenStyle);
begin
  if FStyle <> AValue then
  begin
    FStyle := AValue;
    if HandleAllocated then
      DoSetDashStyle(Handle);
    Changed;
  end;
end;

procedure TACLGdiplusPen.SetWidth(AValue: Single);
begin
  AValue := Max(0, AValue);
  if AValue <> FWidth then
  begin
    FWidth := AValue;
    if HandleAllocated then
      GdipCheck(GdipSetPenWidth(Handle, Width));
    Changed;
  end;
end;

{ TACLGdiplusCanvas }

constructor TACLGdiplusCanvas.Create;
begin
  inherited Create;
  FPen := TACLGdiplusPen.Create;
  FBrush := TACLGdiplusBrush.Create;
end;

constructor TACLGdiplusCanvas.Create(DC: HDC);
begin
  Create;
  GdipCheck(GdipCreateFromHDC(DC, FHandle));
end;

constructor TACLGdiplusCanvas.Create(AHandle: GpGraphics);
begin
  Create;
  FHandle := AHandle;
end;

destructor TACLGdiplusCanvas.Destroy;
begin
  FreeAndNil(FPen);
  FreeAndNil(FBrush);
  if Handle <> nil then
    GdipCheck(GdipDeleteGraphics(Handle));
  inherited Destroy;
end;

procedure TACLGdiplusCanvas.DrawLine(APen: TACLGdiplusPen; X1, Y1, X2, Y2: Integer);
begin
  GdipCheck(GdipDrawLineI(Handle, APen.Handle, X1, Y1, X2, Y2));
end;

procedure TACLGdiplusCanvas.FillClosedCurve2(ABrush: TACLGdiplusBrush; const APoints: array of TPoint; ATension: Single);
begin
  GdipCheck(GdipFillClosedCurve2I(Handle, ABrush.Handle, @APoints[0], Length(APoints), ATension, FillModeWinding));
end;

procedure TACLGdiplusCanvas.FillClosedCurve2(AColor: TAlphaColor; const APoints: array of TPoint; ATension: Single);
begin
  FBrush.Color := AColor;
  FillClosedCurve2(FBrush, APoints, ATension);
end;

procedure TACLGdiplusCanvas.DrawClosedCurve2(APen: TACLGdiplusPen; const APoints: array of TPoint; ATension: Single);
begin
  GdipCheck(GdipDrawClosedCurve2I(Handle, APen.Handle, @APoints[0], Length(APoints), ATension));
end;

procedure TACLGdiplusCanvas.DrawClosedCurve2(APenColor: TAlphaColor; const APoints: array of TPoint;
  ATension: Single; APenStyle: TACLGdiplusPenStyle = gpsSolid; APenWidth: Single = 1.0);
begin
  FPen.Color := APenColor;
  FPen.Style := APenStyle;
  FPen.Width := APenWidth;
  DrawClosedCurve2(FPen, APoints, ATension);
end;

procedure TACLGdiplusCanvas.DrawCurve2(APen: TACLGdiplusPen; APoints: array of TPoint; ATension: Single);
begin
  GdipCheck(GdipDrawCurve2I(Handle, APen.Handle, @APoints[0], Length(APoints), ATension));
end;

procedure TACLGdiplusCanvas.DrawCurve2(APenColor: TAlphaColor; APoints: array of TPoint; ATension: Single;
  APenStyle: TACLGdiplusPenStyle = gpsSolid; APenWidth: Single = 1.0);
begin
  FPen.Color := APenColor;
  FPen.Style := APenStyle;
  FPen.Width := APenWidth;
  DrawCurve2(FPen, APoints, ATension);
end;

procedure TACLGdiplusCanvas.DrawLine(APenColor: TAlphaColor; X1, Y1, X2, Y2: Integer;
  APenStyle: TACLGdiplusPenStyle = gpsSolid; APenWidth: Single = 1.0);
begin
  FPen.Color := APenColor;
  FPen.Style := APenStyle;
  FPen.Width := APenWidth;
  DrawLine(FPen, X1, Y1, X2, Y2);
end;

procedure TACLGdiplusCanvas.DrawLine(APenColor: TAlphaColor; const APoints: array of TPoint;
  APenStyle: TACLGdiplusPenStyle = gpsSolid; APenWidth: Single = 1.0);
begin
  FPen.Color := APenColor;
  FPen.Style := APenStyle;
  FPen.Width := APenWidth;
  GdipDrawLinesI(Handle, FPen.Handle, @APoints[0], Length(APoints));
end;

procedure TACLGdiplusCanvas.DrawEllipse(APen: TACLGdiplusPen; const R: TRect);
begin
  GdipDrawEllipseI(Handle, APen.Handle, R.Left, R.Top, R.Width, R.Height);
end;

procedure TACLGdiplusCanvas.DrawEllipse(APenColor: TAlphaColor; const R: TRect;
  APenStyle: TACLGdiplusPenStyle = gpsSolid; APenWidth: Single = 1.0);
begin
  FPen.Color := APenColor;
  FPen.Style := APenStyle;
  FPen.Width := APenWidth;
  DrawEllipse(FPen, R);
end;

procedure TACLGdiplusCanvas.FillEllipse(ABrush: TACLGdiplusBrush; const R: TRect);
begin
  GdipFillEllipseI(Handle, ABrush.Handle, R.Left, R.Top, R.Width, R.Height);
end;

procedure TACLGdiplusCanvas.FillEllipse(AColor: TAlphaColor; const R: TRect);
begin
  FBrush.Color := AColor;
  FillEllipse(FBrush, R);
end;

procedure TACLGdiplusCanvas.FillRectangle(ABrush: TACLGdiplusBrush; const R: TRect; AMode: TGpCompositingMode = cmSourceOver);
var
  APrevMode: TCompositingMode;
begin
  if not acRectIsEmpty(R) then
  begin
    GdipGetCompositingMode(Handle, APrevMode);
    try
      GdipSetCompositingMode(Handle, TCompositingMode(AMode));
      GdipFillRectangleI(Handle, ABrush.Handle, R.Left, R.Top, R.Width, R.Height);
    finally
      GdipSetCompositingMode(Handle, APrevMode);
    end;
  end;
end;

procedure TACLGdiplusCanvas.FillRectangle(AColor: TAlphaColor; const R: TRect; AMode: TGpCompositingMode = cmSourceOver);
begin
  if (AColor <> TAlphaColor.None) or (AMode = cmSourceCopy) then
  begin
    FBrush.Color := AColor;
    FillRectangle(FBrush, R, AMode);
  end;
end;

procedure TACLGdiplusCanvas.FillRectangleByGradient(AColor1, AColor2: TAlphaColor; const R: TRect; AMode: TGpLinearGradientMode);
var
  ABrush: GpBrush;
  ABrushRect: TGpRect;
begin
  ABrushRect.X := R.Left - 1;
  ABrushRect.Y := R.Top - 1;
  ABrushRect.Width := acRectWidth(R) + 2;
  ABrushRect.Height := acRectHeight(R) + 2;
  GdipCheck(GdipCreateLineBrushFromRectI(@ABrushRect, AColor1, AColor2, TLinearGradientMode(AMode), WrapModeTile, ABrush));
  GdipCheck(GdipFillRectangleI(Handle, ABrush, R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top));
  GdipCheck(GdipDeleteBrush(ABrush));
end;

procedure TACLGdiplusCanvas.DrawRectangle(APen: TACLGdiplusPen; const R: TRect);
begin
  if not acRectIsEmpty(R) then
    GdipDrawRectangleI(Handle, APen.Handle, R.Left, R.Top, R.Width - 1, R.Height - 1);
end;

procedure TACLGdiplusCanvas.DrawRectangle(APenColor: TAlphaColor;
  const R: TRect; APenStyle: TACLGdiplusPenStyle = gpsSolid; APenWidth: Single = 1.0);
begin
  FPen.Color := APenColor;
  FPen.Style := APenStyle;
  FPen.Width := APenWidth;
  DrawRectangle(FPen, R);
end;

procedure TACLGdiplusCanvas.TextOut(const AText: UnicodeString; const R: TRect; AFont: TFont;
  AHorzAlign: TAlignment; AVertAlign: TVerticalAlignment; AWordWrap: Boolean; ATextColor: TAlphaColor;
  ARendering: TGpTextRenderingHint = trhSystemDefault);
const
  HorzAlignMap: array[TAlignment] of TStringAlignment = (StringAlignmentNear, StringAlignmentFar, StringAlignmentCenter);
  VertAlignMap: array[TVerticalAlignment] of TStringAlignment = (StringAlignmentNear, StringAlignmentFar, StringAlignmentCenter);
  WordWrapMap: array[Boolean] of Integer = (StringFormatFlagsNoWrap, 0);
var
  ABrush: GpBrush;
  AFontHandle: GpFont;
  AFontInfo: TLogFontW;
  ARect: TGPRectF;
  AStringFormat: GpStringFormat;
begin
  if acRectIsEmpty(R) or (AText = '') then Exit;

  if ATextColor = TAlphaColor.Default then
    ATextColor := TAlphaColor.FromColor(AFont.Color);

  ZeroMemory(@AFontInfo, SizeOf(AFontInfo));
  GetObjectW(AFont.Handle, SizeOf(AFontInfo), @AFontInfo);
  GdipCheck(GdipCreateFontFromLogfontW(MeasureCanvas.Handle, @AFontInfo, AFontHandle));
  try
    GdipCheck(GdipSetTextRenderingHint(Handle, TTextRenderingHint(ARendering)));
    GdipCheck(GdipCreateStringFormat(WordWrapMap[AWordWrap], LANG_NEUTRAL, AStringFormat));
    try
      GdipCheck(GdipSetStringFormatAlign(AStringFormat, HorzAlignMap[AHorzAlign]));
      GdipCheck(GdipSetStringFormatLineAlign(AStringFormat, VertAlignMap[AVertAlign]));
      GdipCheck(GdipCreateSolidFill(ATextColor, ABrush));
      try
        ARect.X := R.Left;
        ARect.Y := R.Top;
        ARect.Width := R.Width;
        ARect.Height := R.Height;
        GdipCheck(GdipDrawString(Handle, PWideChar(AText), Length(AText), AFontHandle, @ARect, AStringFormat, ABrush));
      finally
        GdipCheck(GdipDeleteBrush(ABrush));
      end;
    finally
      GdipCheck(GdipDeleteStringFormat(AStringFormat));
    end;
  finally
    GdipCheck(GdipDeleteFont(AFontHandle));
  end;
end;

function TACLGdiplusCanvas.GetInterpolationMode: TGpInterpolationMode;
var
  M: TInterpolationMode;
begin
  GdipCheck(GdipGetInterpolationMode(Handle, M));
  Result := TGpInterpolationMode(M);
end;

function TACLGdiplusCanvas.GetPixelOffsetMode: TGpPixelOffsetMode;
var
  AMode: TPixelOffsetMode;
begin
  GdipCheck(GdipGetPixelOffsetMode(Handle, AMode));
  Result := TGpPixelOffsetMode(AMode);
end;

function TACLGdiplusCanvas.GetSmoothingMode: TGpSmoothingMode;
var
  M: TSmoothingMode;
begin
  GdipCheck(GdipGetSmoothingMode(Handle, M));
  Result := TGpSmoothingMode(M);
end;

procedure TACLGdiplusCanvas.SetInterpolationMode(const Value: TGpInterpolationMode);
begin
  GdipCheck(GdipSetInterpolationMode(Handle, TInterpolationMode(Value)));
end;

procedure TACLGdiplusCanvas.SetPixelOffsetMode(const Value: TGpPixelOffsetMode);
begin
  GdipCheck(GdipSetPixelOffsetMode(Handle, TPixelOffsetMode(Value)));
end;

procedure TACLGdiplusCanvas.SetSmoothingMode(const Value: TGpSmoothingMode);
begin
  GdipCheck(GdipSetSmoothingMode(Handle, TSmoothingMode(Value)));
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
  if FHandle <> nil then
    FSavedHandles.Push(FHandle);
  GdipCheck(GdipCreateFromHDC(DC, FHandle));
end;

procedure TACLGdiplusPaintCanvas.EndPaint;
begin
  try
    GdipDeleteGraphics(FHandle);
  finally
    if FSavedHandles.Count > 0 then
      FHandle := FSavedHandles.Pop
    else
      FHandle := nil;
  end;
end;

{ TACLGdiplusStream }

function TACLGdiplusStream.Stat(out AStatStg: TStatStg; AStatFlag: DWORD): HResult; stdcall;
begin
  ZeroMemory(@AStatStg, SizeOf(AStatStg));
  Result := inherited Stat(AStatStg, AStatFlag);
end;

{ TACLGdiplusSolidBrushCache }

class destructor TACLGdiplusSolidBrushCache.Destroy;
begin
  FreeAndNil(FInstance);
end;

class procedure TACLGdiplusSolidBrushCache.Flush;
begin
  if FInstance <> nil then
    FInstance.Clear;
end;

class function TACLGdiplusSolidBrushCache.GetOrCreate(AColor: TAlphaColor): GpBrush;
begin
  if FInstance = nil then
  begin
    FInstance := TACLValueCacheManager<TAlphaColor, GpBrush>.Create(512);
    FInstance.OnRemove := RemoveValueHandler;
  end;
  if not FInstance.Get(AColor, Result) then
  begin
    GdipCheck(GdipCreateSolidFill(AColor, Result));
    FInstance.Add(AColor, Result);
  end;
end;

class procedure TACLGdiplusSolidBrushCache.RemoveValueHandler(Sender: TObject; const ABrush: GpBrush);
begin
  GdipDeleteBrush(ABrush);
end;

initialization

finalization
  FreeAndNil(FPaintCanvas);
end.
