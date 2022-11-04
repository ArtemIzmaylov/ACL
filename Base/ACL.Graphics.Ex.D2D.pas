{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*         Extended Graphic Library          *}
{*           Direct2D Integration            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.Ex.D2D;

{$I ACL.Config.inc}

interface

uses
  Winapi.D2D1,
  Winapi.DxgiFormat,
  Winapi.GDIPAPI,
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Classes,
  System.Generics.Collections,
  System.Math,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.Ex.D2D.Types,
  ACL.Graphics.Ex.Gdip,
  ACL.Math,
  ACL.Utils.Common;

type

  { EACLDirect2DError }

  EACLDirect2DError = class(Exception)
  public
    constructor Create(const AErrorCode: HRESULT); overload;
  end;

  { TACLDirect2DEffect }

  TACLDirect2DEffect = class
  public
    class function SetEnumValue(const Effect: ID2D1Effect; ID: Integer; Value: Integer): Boolean; overload;
    class function SetValue(const Effect: ID2D1Effect; ID: Integer; Value: Integer): Boolean; overload;
    class function SetValue(const Effect: ID2D1Effect; ID: Integer; Value: Single): Boolean; overload;
  end;

  { TACLDirect2DAbstractRender }

  TACLDirect2DAbstractRender = class(TACL2DRender)
  strict private type
  strict private
    FCacheHatchBrushes: TACLValueCacheManager<UInt64, ID2D1Brush>;
    FCacheSolidBrushes: TACLValueCacheManager<TAlphaColor, ID2D1SolidColorBrush>;
    FCacheStrokeStyles: array[TACL2DRenderStrokeStyle] of ID2D1StrokeStyle1;
    FClipCounter: Integer;
    FSavedClipRects: TStack<Integer>;
    FSavedWorldTransforms: TStack<TD2D1Matrix3x2F>;
    FWorldTransform: TD2D1Matrix3x2F;

    FOnRecreateNeeded: TNotifyEvent;

    procedure AbandonResources;
    procedure ApplyWorldTransform;
    procedure RollbackClipRectChanges(ATargetLevel: Integer);
  protected
    FDeviceContext: ID2D1DeviceContext;
    FRecreateContextNeeded: Boolean;
    FResources: TList;

    function CacheGetHatchBrush(AColor1, AColor2: TAlphaColor; ASize: Word): ID2D1Brush;
    function CacheGetSolidBrush(AColor: TAlphaColor): ID2D1SolidColorBrush;
    function CacheGetStrokeStyle(AStyle: TACL2DRenderStrokeStyle): ID2D1StrokeStyle1;
    function CreateCompatibleRenderTarget(const ASize: TSize; out ABitmapTarget: ID2D1BitmapRenderTarget): Boolean;
    function CreatePathGeometry(APoints: PPoint; ACount: Integer;
      AFigureBegin: TD2D1FigureBegin; AFigureEnd: TD2D1_FigureEnd): ID2D1PathGeometry1;
    procedure DoBeginDraw(const AClipRect: TRect);
    procedure DoEndDraw; virtual;
    procedure ReleaseDevice; virtual;
  public
    constructor Create(OnRecreateNeeded: TNotifyEvent);
    destructor Destroy; override;
    procedure EndPaint; override;
    procedure FlushCache;

    // Clipping
    function IsVisible(const R: TRect): Boolean; override;
    function IntersectClipRect(const R: TRect): Boolean; override;
    procedure RestoreClipRegion; override;
    procedure SaveClipRegion; override;

    // Images
    function CreateImage(Colors: PRGBQuad; Width, Height: Integer; AlphaFormat: TAlphaFormat = afDefined): TACL2DRenderImage; override;
    function CreateImageAttributes: TACL2DRenderImageAttributes; override;
    procedure DrawImage(Image: TACL2DRenderImage; const TargetRect, SourceRect: TRect; Attributes: TACL2DRenderImageAttributes); override;
    procedure DrawImage(Image: TACL2DRenderImage; const TargetRect, SourceRect: TRect; Alpha: Byte); override;

    // Ellipse
    procedure DrawEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure FillEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor); override;

    // Line
    procedure Line(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure Line(const Points: PPoint; Count: Integer; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;

    // Rectangle
    procedure DrawRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure FillHatchRectangle(const R: TRect; Color1, Color2: TAlphaColor; Size: Integer); override;
    procedure FillRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor); override;

    // Text
    procedure DrawText(const Text: string; const R: TRect; Color: TAlphaColor; Font: TFont;
      HorzAlign: TAlignment = taLeftJustify; VertAlign: TVerticalAlignment = taVerticalCenter;
      WordWrap: Boolean = False); override;

    // Path
    function CreatePath: TACL2DRenderPath; override;
    procedure DrawPath(Path: TACL2DRenderPath; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure FillPath(Path: TACL2DRenderPath; Color: TAlphaColor); override;
    procedure Geometry(const AHandle: ID2D1Geometry; BackgroundColor: TAlphaColor;
      StrokeColor: TAlphaColor = 0; StrokeWidth: Single = 1; StrokeStyle: TACL2DRenderStrokeStyle = ssSolid);

    // Polygon
    procedure Polygon(const Points: array of TPoint; Color, StrokeColor: TAlphaColor;
      StrokeWidth: Single = 1; StrokeStyle: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure DrawPolygon(const Points: array of TPoint; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); override;
    procedure FillPolygon(const Points: array of TPoint; Color: TAlphaColor); override;

    // World Transform
    procedure ModifyWorldTransform(const XForm: TXForm); override;
    procedure RestoreWorldTransform; override;
    procedure SaveWorldTransform; override;
    procedure SetWorldTransform(const XForm: TXForm); override;
    procedure TransformPoints(Points: PPointF; Count: Integer); override;
  end;

  { TACLDirect2DGdiCompatibleRender }

  TACLDirect2DGdiCompatibleRender = class(TACLDirect2DAbstractRender,
    IACL2DRenderGdiCompatible)
  strict private
    FRenderTarget: ID2D1DCRenderTarget;
    FUpdateRect: TRect;

    procedure CreateRenderTarget;
  protected
    // IACL2DRenderGdiCompatible
    procedure GdiDraw(Proc: TACL2DRenderGdiDrawProc);
  public
    constructor Create(OnRecreateNeeded: TNotifyEvent);
    procedure BeginPaint(DC: HDC; const BoxRect, UpdateRect: TRect); override;
  end;

  { TACLDirect2DHwndBasedRender }

  TACLDirect2DHwndBasedRender = class(TACLDirect2DAbstractRender)
  strict private
    FBufferIsValid: Boolean;
    FCopyToDC: HDC;
    FDevice: IDXGIDevice1;
    FDevice3D: ID3D11Device;
    FDevice3DContext: ID3D11DeviceContext;
    FFrontBufferContent: ID3D11Texture2D;
    FFrontBufferContentSize: TSize;
    FFrontBufferSurface: IDXGISurface;
    FPresentParameters: TDXGIPresentParameters;
    FSwapChain: IDXGISwapChain1;
    FTextureSize: TSize;
    FUpdateRect: TRect;
    FWindowHandle: HWND;

    procedure CheckCreateFrontBufferContent;
    procedure CopyToDC(DC: HDC); overload;
    procedure CopyToDC(DC: HDC; const ATargetRect, ASourceRect: TRect); overload;
  protected
    procedure CreateTexture;
    procedure DoEndDraw; override;
    procedure ReleaseDevice; override;
    procedure ReleaseTexture;

    property Device: IDXGIDevice1 read FDevice;
    property Device3D: ID3D11Device read FDevice3D;
    property Device3DContext: ID3D11DeviceContext read FDevice3DContext;
  public
    constructor Create(OnRecreateNeeded: TNotifyEvent;
      const ADevice: IDXGIDevice1; const AContext: ID2D1DeviceContext;
      const ADevice3D: ID3D11Device; const ADevice3DContext: ID3D11DeviceContext);
    procedure BeginPaint(DC: HDC; const BoxRect, UpdateRect: TRect); override;
    procedure EndPaint; override;
    procedure SetWndHandle(AHandle: HWND);
  end;

  { TACLDirect2D }

  TACLDirect2D = class
  strict private type
  {$REGION 'Internal Types'}
    TD2D1CreateFactoryFunc = function (factoryType: D2D1_FACTORY_TYPE; const riid: TGUID;
      pFactoryOptions: PD2D1FactoryOptions; out ppIFactory): HRESULT; stdcall;
    TD3D11CreateDeviceFunc = function (pAdapter: IDXGIAdapter; DriverType: TD3DDriveType; Software: HMODULE;
      Flags: UINT; pFeatureLevels: PD3DFeatureLevel; FeatureLevels: UINT; SDKVersion: UINT; out ppDevice: ID3D11Device;
      pFeatureLevel: PD3DFeatureLevel; out ppImmediateContext: ID3D11DeviceContext): HRESULT; stdcall;
    TDWriteCreateFactoryFunc = function (factoryType: DWRITE_FACTORY_TYPE; const iid: TGUID; out factory: IDWriteFactory): HRESULT; stdcall;
  {$ENDREGION}
  strict private
    class var FAvailable: TACLBoolean;
    class var FD2D1CreateFactory: TD2D1CreateFactoryFunc;
    class var FD2D1Library: THandle;
    class var FD3D11CreateDevice: TD3D11CreateDeviceFunc;
    class var FD3D11Library: THandle;
    class var FDWriteCreateFactory: TDWriteCreateFactoryFunc;
    class var FDWriteFactory: IDWriteFactory;
    class var FDWriteLibrary: THandle;
    class var FFactory: ID2D1Factory1;
    class var FSwapChainSize: Integer;
    class var FVSync: Boolean;

    class function CreateDevice3DContext(out ADevice: ID3D11Device; out ADeviceContext: ID3D11DeviceContext): Boolean;
    class procedure SetSwapChainSize(AValue: Integer); static;
  protected
    class procedure CheckInitialized;
    class function NeedRecreateContext(AErrorCode: HRESULT): Boolean;
    class function NeedSwitchToGdiRenderMode(const AErrorCode: HRESULT = S_OK): Boolean; overload;
    class function NeedSwitchToGdiRenderMode(const AException: Exception): Boolean; overload;

    class property Factory: ID2D1Factory1 read FFactory;
    class property DWriteFactory: IDWriteFactory read FDWriteFactory;
  public
    class constructor Create;
    class destructor Destroy;
    class function Initialize: Boolean;
    class function TryCreateRender(AOnRecreateNeeded: TNotifyEvent; AWndHandle: THandle; out ARender: TACL2DRender): Boolean;

    class property SwapChainSize: Integer read FSwapChainSize write SetSwapChainSize;
    class property VSync: Boolean read FVSync write FVSync;
  end;

implementation

type

  { TACLDirect2DRenderImage }

  TACLDirect2DRenderImage = class(TACL2DRenderImage)
  public
    Handle: ID2D1Bitmap;
    constructor Create(AOwner: TACLDirect2DAbstractRender;
      AColors: PRGBQuad; AWidth, AHeight: Integer; AAlphaFormat: TAlphaFormat);
    destructor Destroy; override;
    procedure Release; override;
  end;

  { TACLDirect2DRenderPath }

  TACLDirect2DRenderPath = class(TACL2DRenderPath)
  strict private
    FFigureStarted: Boolean;
    FHandle: ID2D1PathGeometry1;
    FSink: ID2D1GeometrySink;

    procedure CloseSink;
    procedure FinishFigureIfNecessary(const AMode: TD2D1_FigureEnd); inline;
    procedure StartFigureIfNecessary(const P: TD2D1Point2F); inline;
  public
    constructor Create(AOwner: TACLDirect2DAbstractRender);
    destructor Destroy; override;
    function Handle: ID2D1PathGeometry1;
    procedure Release; override;
    // commands
    procedure AddArc(CX, CY, RadiusX, RadiusY, StartAngle, SweepAngle: Single); override;
    procedure AddLine(X1, Y1, X2, Y2: Single); override;
    // figures
    procedure FigureClose; override;
    procedure FigureStart; override;
  end;

procedure D2D1Check(AValue: HRESULT);
begin
  if Failed(AValue) then
    raise EACLDirect2DError.Create(AValue);
end;

//----------------------------------------------------------------------------------------------------------------------
// Utilities
//----------------------------------------------------------------------------------------------------------------------

{$REGION 'Utilities'}

function D2D1Bitmap(ATarget: ID2D1RenderTarget; ABits: PRGBQuad; AWidth, AHeight: Integer; AAlphaFormat: TAlphaFormat): ID2D1Bitmap; overload;
const
  AlphaModeMap: array[TAlphaFormat] of D2D1_ALPHA_MODE = (
    D2D1_ALPHA_MODE_IGNORE,
    D2D1_ALPHA_MODE_STRAIGHT,
    D2D1_ALPHA_MODE_PREMULTIPLIED
  );
var
  ABitmapProperties: TD2D1BitmapProperties;
  ATempBits: PRGBQuad;
  ATempBitsCount: Integer;
begin
  if AAlphaFormat = afDefined then
  begin
    ATempBitsCount := AWidth * AHeight;
    ATempBits := AllocMem(SizeOf(TRGBQuad) * ATempBitsCount);
    try
      FastMove(ABits^, ATempBits^, SizeOf(TRGBQuad) * ATempBitsCount);
      TACLColors.Premultiply(ATempBits, ATempBitsCount);
      Result := D2D1Bitmap(ATarget, ATempBits, AWidth, AHeight, afPremultiplied);
    finally
      FreeMem(ATempBits);
    end;
  end
  else
  begin
    ZeroMemory(@ABitmapProperties, SizeOf(ABitmapProperties));
    ABitmapProperties.pixelFormat.format := DXGI_FORMAT_B8G8R8A8_UNORM;
    ABitmapProperties.pixelFormat.alphaMode := AlphaModeMap[AAlphaFormat];
    D2D1Check(ATarget.CreateBitmap(D2D1SizeU(AWidth, AHeight), ABits, 4 * AWidth, ABitmapProperties, Result));
  end;
end;

function D2D1Bitmap(ATarget: ID2D1RenderTarget; ABitmap: TBitmap; AAlphaFormat: TAlphaFormat): ID2D1Bitmap; overload;
var
  ABitmapHandle: HBITMAP;
  ABitmapInfo: TBitmapInfo;
  ABuffer: PRGBQuad;
begin
  ABuffer := AllocMem(ABitmap.Width * ABitmap.Height * 4);
  try
    ABitmapHandle := ABitmap.Handle;
    acFillBitmapInfoHeader(ABitmapInfo.bmiHeader, ABitmap.Width, ABitmap.Height);
    GetDIBits(ABitmap.Canvas.Handle, ABitmapHandle, 0, ABitmap.Height, ABuffer, ABitmapInfo, DIB_RGB_COLORS);
    Result := D2D1Bitmap(ATarget, ABuffer, ABitmap.Width, ABitmap.Height, AAlphaFormat);
  finally
    FreeMem(ABuffer);
  end;
end;

//function TACLDirect2DAbstractRender.ImageToBitmap(const Image: ID2D1Image; const ImageSize: TD2D1SizeU): ID2D1Bitmap;
//var
//  ABitmapProperties: TD2D1BitmapProperties1;
//  ANewTarget: ID2D1Bitmap1;
//  AOldTarget: ID2D1Image;
//begin
//  ZeroMemory(@ABitmapProperties, SizeOf(ABitmapProperties));
//  ABitmapProperties.bitmapOptions := D2D1_BITMAP_OPTIONS_TARGET;
//  ABitmapProperties.pixelFormat.format := DXGI_FORMAT_B8G8R8A8_UNORM;
//  ABitmapProperties.pixelFormat.alphaMode := D2D1_ALPHA_MODE_PREMULTIPLIED;
//  D2D1Check(FDeviceContext.CreateBitmap(ImageSize, nil, 0, @ABitmapProperties, ANewTarget));
//  FDeviceContext.GetTarget(AOldTarget);
//  FDeviceContext.SetTarget(ANewTarget);
//  FDeviceContext.DrawImage(Image);
//  FDeviceContext.SetTarget(AOldTarget);
//  Result := ANewTarget;
//end;

function D2D1Ellipse(X1, Y1, X2, Y2: Single): TD2D1Ellipse;
begin
  Result.point.x := (X1 + X2) * 0.5;
  Result.point.y := (Y1 + Y2) * 0.5;
  Result.radiusX := (X2 - X1) * 0.5;
  Result.radiusY := (Y2 - Y1) * 0.5;
end;

function D2D1Matrix3x2(const XForm: TXForm): TD2D1Matrix3x2F; overload;
begin
  Result._11 := XForm.eM11;
  Result._12 := XForm.eM12;
  Result._21 := XForm.eM21;
  Result._22 := XForm.eM22;
  Result._31 := XForm.eDx;
  Result._32 := XForm.eDy;
end;

function D2D1Matrix3x2(const M11, M12, M21, M22, DX, DY: Single): TD2D1Matrix3x2F; overload;
begin
  Result._11 := M11;
  Result._12 := M12;
  Result._21 := M21;
  Result._22 := M22;
  Result._31 := Dx;
  Result._32 := Dy;
end;

function D2D1PointF(const X, Y: Single): TD2D1Point2F;
begin
  Result.x := X;
  Result.y := Y;
end;

function D2D1SizeU(const W, H: Integer): TD2D1SizeU;
begin
  Result.Height := H;
  Result.Width := W;
end;

function D2D1Rect(X1, Y1, X2, Y2: Single): TD2D1RectF; inline;
begin
  Result.left := X1;
  Result.top := Y1;
  Result.right := X2;
  Result.bottom := Y2;
end;

function D2D1ColorF(const AColor: TAlphaColor): TD2D1ColorF; inline;
begin
  Result.r := AColor.R / 255;
  Result.g := AColor.G / 255;
  Result.b := AColor.B / 255;
  Result.a := AColor.A / 255;
end;

function D2D1NormalizeAngle(const AAngle: Single): Single; inline;
const
  PI2 = 2 * PI;
begin
  Result := AAngle;
  while Result < 0 do
    Result := Result + PI2;
  while Result > PI2 do
    Result := Result - PI2;
end;

function D2D1CalculateArcPoint(const ACenter, APoint: TD2D1Point2F; AAngle: Single; const ARadius: TD2D1SizeF): TD2D1Point2F;
var
  AA, BB: Single;
  ASlope: Single;
begin
  AAngle := D2D1NormalizeAngle(AAngle);

  AA := Sqr(ARadius.width);
  BB := Sqr(ARadius.height);
  ASlope := Sqr(APoint.Y - ACenter.y) / Max(Sqr(APoint.X - ACenter.x), 0.1);

  Result.x := Sqrt(AA * BB / (BB + AA * ASlope));
  Result.y := Sqrt(BB * (1 - Min(Sqr(Result.x) / AA, 1)));

  if (AAngle < Pi / 2) or (AAngle > 3 * PI / 2) then
    Result.x := ACenter.x + Result.x
  else
    Result.x := ACenter.x - Result.x;

  if AAngle > PI then
    Result.y := ACenter.y + Result.y
  else
    Result.y := ACenter.y - Result.y;
end;

procedure D2D1CalculateArcSegmentCore(ACenterX, ACenterY, ARadiusX, ARadiusY, AStartAngle, ASweepAngle: Single; out AStartPoint, AEndPoint: TPointF);
//
//                      A * B
//  V = ---------------------------------------------
//      Sqrt(A^2 * Sin^2(Alpha) + B^2 * Cos^2(Alpha))
//
//  Radial.X = V * Cos(Alpha)
//  Radial.Y = V * Sin(Alpha)
//
//  where:
//    A - horizontal ellipse semiaxis
//    B - vertical ellipse semiaxis
//    Angle - an angle between Radius-Vector and A calculated in counterclockwise direction
//
var
  A, B, C: Double;
  ASin, ACos, AValue: Extended;
begin
  if IsZero(ARadiusX) or IsZero(ARadiusY) then
  begin
    AStartPoint := PointF(ACenterX, ACenterY);
    AEndPoint := AStartPoint;
  end
  else
  begin
    C := ARadiusX * ARadiusY;
    A := Sqr(ARadiusX);
    B := Sqr(ARadiusY);

    SinCos(DegToRad(AStartAngle), ASin, ACos);
    AValue := C / Sqrt(A * Sqr(ASin) + B * Sqr(ACos));
    AStartPoint.X := ACenterX + AValue * ACos;
    AStartPoint.Y := ACenterY - AValue * ASin;

    if IsZero(ASweepAngle) then
      AEndPoint := AStartPoint
    else
    begin
      SinCos(DegToRad(AStartAngle + ASweepAngle), ASin, ACos);
      AValue := C / Sqrt(A * Sqr(ASin) + B * Sqr(ACos));
      AEndPoint.X := ACenterX + AValue * ACos;
      AEndPoint.Y := ACenterY - AValue * ASin;
    end;
  end;
end;

function D2D1CalculateArcSegment(CenterX, CenterY, RadiusX, RadiusY: Single;
  StartAngle, SweepAngle: Single; out AStartPoint: TD2D1Point2F): TD2D1ArcSegment;
var
  P3, P4: TPointF;
begin
  ZeroMemory(@Result, SizeOf(Result));
  Result.Size.Width := RadiusX;
  Result.Size.Height := RadiusY;

  if SweepAngle > 0 then
    Result.sweepDirection := D2D1_SWEEP_DIRECTION_COUNTER_CLOCKWISE
  else
    Result.sweepDirection := D2D1_SWEEP_DIRECTION_CLOCKWISE;

  if Abs(SweepAngle) > 180 then
    Result.arcSize := D2D1_ARC_SIZE_LARGE
  else
    Result.arcSize := D2D1_ARC_SIZE_SMALL;

  D2D1CalculateArcSegmentCore(CenterX, CenterY, RadiusX, RadiusY, StartAngle, SweepAngle, P3, P4);
  AStartPoint := D2D1PointF(P3.X, P3.Y);
  Result.point := D2D1PointF(P4.X, P4.Y);

//  AStartPoint := D2D1CalculateArcPoint(ACenter, D2D1PointF(P3.X, P3.Y), DegToRad(AStartAngle), Result.size);
//  Result.point := D2D1CalculateArcPoint(ACenter, D2D1PointF(P4.X, P4.Y), DegToRad(AStartAngle + ASweepAngle), Result.size);
end;

{$ENDREGION}

//----------------------------------------------------------------------------------------------------------------------
// Classes
//----------------------------------------------------------------------------------------------------------------------

{ TACLDirect2D }

class procedure TACLDirect2D.CheckInitialized;
begin
  if FAvailable = TACLBoolean.Default then
    raise EACLDirect2DError.Create('Direct2D is not initialized. Call the TACLDirect2D.Initialize method');
  if FAvailable = TACLBoolean.False then
    raise EACLDirect2DError.Create('Direct2D is not unavailable on this device.');
end;

class constructor TACLDirect2D.Create;
begin
  // Direct2D support has been added in Windows 7 Platform update,
  // but it works not so perfect. Disabling it for Windows 7 at all.
  if IsWine or not IsWin8OrLater then
    FAvailable := TACLBoolean.False;
  SwapChainSize := 2;
  VSync := True;
end;

class destructor TACLDirect2D.Destroy;
begin
  FAvailable := TACLBoolean.False;
  FFactory := nil;
  FDWriteFactory := nil;
  if FD2D1Library <> 0 then
  begin
    FreeLibrary(FD2D1Library);
    FD2D1Library := 0;
  end;
  if FD3D11Library <> 0 then
  begin
    FreeLibrary(FD3D11Library);
    FD3D11Library := 0;
  end;
end;

class function TACLDirect2D.Initialize: Boolean;
begin
  if FAvailable = TACLBoolean.Default then
  try
    FD2D1Library := LoadLibrary(d2d1lib);
    FD2D1CreateFactory := GetProcAddress(FD2D1Library, 'D2D1CreateFactory');

    FD3D11Library := LoadLibrary(d3d11lib);
    FD3D11CreateDevice := GetProcAddress(FD3D11Library, 'D3D11CreateDevice');

    FDWriteLibrary := LoadLibrary(dwritelib);
    FDWriteCreateFactory := GetProcAddress(FDWriteLibrary, 'DWriteCreateFactory');

    if Assigned(FDWriteCreateFactory) then
      D2D1Check(FDWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, IDWriteFactory, FDWriteFactory));
    if Assigned(FD2D1CreateFactory) then
      D2D1Check(FD2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, ID2D1Factory1, nil, FFactory));
    if (FFactory <> nil) and (FDWriteFactory <> nil) then
      FAvailable := TACLBoolean.True;
  except
    FAvailable := TACLBoolean.False;
  end;
  Result := FAvailable = TACLBoolean.True;
end;

class function TACLDirect2D.TryCreateRender(AOnRecreateNeeded: TNotifyEvent; AWndHandle: THandle; out ARender: TACL2DRender): Boolean;
var
  AContext: ID2D1DeviceContext;
  ADevice: IDXGIDevice1;
  ADevice2D: ID2D1Device;
  ADevice3D: ID3D11Device;
  ADevice3DContext: ID3D11DeviceContext;
begin
  if not Initialize then
    Exit(False);
  if not CreateDevice3DContext(ADevice3D, ADevice3DContext) then
    Exit(False);
  if not Supports(ADevice3D, IDXGIDevice1, ADevice) then
    Exit(False);
  if Failed(Factory.CreateDevice(ADevice, ADevice2D)) then
    Exit(False);
  if Failed(ADevice2D.CreateDeviceContext(D2D1_DEVICE_CONTEXT_OPTIONS_NONE, AContext)) then
    Exit(False);
  ARender := TACLDirect2DHwndBasedRender.Create(AOnRecreateNeeded, ADevice, AContext, ADevice3D, ADevice3DContext);
  try
    TACLDirect2DHwndBasedRender(ARender).SetWndHandle(AWndHandle);
    Result := True;
  except
    FreeAndNil(ARender);
    Result := False;
  end;
end;

class function TACLDirect2D.NeedRecreateContext(AErrorCode: HRESULT): Boolean;
begin
  Result := NeedSwitchToGdiRenderMode(AErrorCode) or
    (AErrorCode = DXGI_ERROR_DEVICE_REMOVED) or
    (AErrorCode = DXGI_ERROR_DEVICE_RESET) or
    (AErrorCode = D2DERR_RECREATE_TARGET);
end;

class function TACLDirect2D.NeedSwitchToGdiRenderMode(const AException: Exception): Boolean;
begin
  Result := (AException is EAccessViolation) or (AException is EOutOfMemory);
  if Result then
    FAvailable := TACLBoolean.False;
end;

class function TACLDirect2D.NeedSwitchToGdiRenderMode(const AErrorCode: HRESULT): Boolean;
begin
  Result := AErrorCode = DXGI_ERROR_UNSUPPORTED;
  if Result then
    FAvailable := TACLBoolean.False;
end;

class function TACLDirect2D.CreateDevice3DContext(out ADevice: ID3D11Device; out ADeviceContext: ID3D11DeviceContext): Boolean;
const
  Windows8Features: array[0..1] of TD3DFeatureLevel = (D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_11_1);
var
  AErrorCode: HRESULT;
  AFeatureCount: Integer;
  AFeatures: PD3DFeatureLevel;
begin
  if IsWin8OrLater then
  begin
    AFeatures := @Windows8Features[0];
    AFeatureCount := Length(Windows8Features);
  end
  else
  begin
    AFeatures := nil;
    AFeatureCount := 0;
  end;

  if Assigned(FD3D11CreateDevice) then
    AErrorCode := FD3D11CreateDevice(nil, D3D_DRIVER_TYPE_HARDWARE, 0,
      D3D11_CREATE_DEVICE_BGRA_SUPPORT or D3D11_CREATE_DEVICE_SINGLETHREADED,
      AFeatures, AFeatureCount, D3D11_SDK_VERSION, ADevice, nil, ADeviceContext)
  else
    AErrorCode := DXGI_ERROR_UNSUPPORTED;

  NeedSwitchToGdiRenderMode(AErrorCode);
  Result := AErrorCode = S_OK;
end;

class procedure TACLDirect2D.SetSwapChainSize(AValue: Integer);
begin
  FSwapChainSize := EnsureRange(AValue, 2, 8);
end;

{ EACLDirect2DError }

constructor EACLDirect2DError.Create(const AErrorCode: HRESULT);
begin
  CreateFmt('Direct2D error (%x)', [AErrorCode]);
end;

{ TACLDirect2DEffect }

class function TACLDirect2DEffect.SetEnumValue(const Effect: ID2D1Effect; ID, Value: Integer): Boolean;
begin
  Result := Succeeded(Effect.SetValue(ID, D2D1_PROPERTY_TYPE_ENUM, @Value, SizeOf(Value)));
end;

class function TACLDirect2DEffect.SetValue(const Effect: ID2D1Effect; ID: Integer; Value: Single): Boolean;
begin
  Result := Succeeded(Effect.SetValue(ID, D2D1_PROPERTY_TYPE_FLOAT, @Value, SizeOf(Value)));
end;

class function TACLDirect2DEffect.SetValue(const Effect: ID2D1Effect; ID, Value: Integer): Boolean;
begin
  Result := Succeeded(Effect.SetValue(ID, D2D1_PROPERTY_TYPE_INT32, @Value, SizeOf(Value)));
end;

{ TACLDirect2DRenderImage }

constructor TACLDirect2DRenderImage.Create(AOwner: TACLDirect2DAbstractRender;
  AColors: PRGBQuad; AWidth, AHeight: Integer; AAlphaFormat: TAlphaFormat);
begin
  inherited Create(AOwner);
  AOwner.FResources.Add(Self);
  Handle := D2D1Bitmap(AOwner.FDeviceContext, AColors, AWidth, AHeight, AAlphaFormat);
  FHeight := AHeight;
  FWidth := AWidth;
end;

destructor TACLDirect2DRenderImage.Destroy;
begin
  if FOwner <> nil then
    TACLDirect2DAbstractRender(FOwner).FResources.Remove(Self);
  inherited;
end;

procedure TACLDirect2DRenderImage.Release;
begin
  Handle := nil;
  inherited;
end;

{ TACLDirect2DRenderPath }

constructor TACLDirect2DRenderPath.Create(AOwner: TACLDirect2DAbstractRender);
begin
  inherited Create(AOwner);
  AOwner.FResources.Add(Self);
  if Failed(TACLDirect2D.Factory.CreatePathGeometry(FHandle)) or Failed(FHandle.Open(FSink)) then
  begin
    FHandle := nil;
    FSink := nil;
  end;
end;

destructor TACLDirect2DRenderPath.Destroy;
begin
  CloseSink;
  if FOwner <> nil then
    TACLDirect2DAbstractRender(FOwner).FResources.Remove(Self);
  inherited;
end;

function TACLDirect2DRenderPath.Handle: ID2D1PathGeometry1;
begin
  CloseSink;
  Result := FHandle;
end;

procedure TACLDirect2DRenderPath.Release;
begin
  CloseSink;
  FHandle := nil;
  inherited;
end;

procedure TACLDirect2DRenderPath.AddArc(CX, CY, RadiusX, RadiusY, StartAngle, SweepAngle: Single);
var
  AArcSegment: TD2D1ArcSegment;
  AStartPoint: TD2D1Point2F;
begin
  if FSink <> nil then
  begin
    AArcSegment := D2D1CalculateArcSegment(CX, CY, RadiusX, RadiusY, 360 - StartAngle, -SweepAngle, AStartPoint);
    StartFigureIfNecessary(AStartPoint);
    FSink.AddArc(AArcSegment);
  end;
end;

procedure TACLDirect2DRenderPath.AddLine(X1, Y1, X2, Y2: Single);
begin
  if FSink <> nil then
  begin
    StartFigureIfNecessary(D2D1PointF(X1, Y1));
    FSink.AddLine(D2D1PointF(X1, Y1));
    FSink.AddLine(D2D1PointF(X2, Y2));
  end;
end;

procedure TACLDirect2DRenderPath.CloseSink;
begin
  FinishFigureIfNecessary(D2D1_FIGURE_END_OPEN);
  if FSink <> nil then
  try
    FSink.Close;
  finally
    FSink := nil;
  end;
end;

procedure TACLDirect2DRenderPath.FigureClose;
begin
  FinishFigureIfNecessary(D2D1_FIGURE_END_CLOSED);
end;

procedure TACLDirect2DRenderPath.FigureStart;
begin
  FinishFigureIfNecessary(D2D1_FIGURE_END_OPEN);
end;

procedure TACLDirect2DRenderPath.FinishFigureIfNecessary(const AMode: TD2D1_FigureEnd);
begin
  if FFigureStarted then
  begin
    FSink.EndFigure(AMode);
    FFigureStarted := False;
  end;
end;

procedure TACLDirect2DRenderPath.StartFigureIfNecessary(const P: TD2D1Point2F);
begin
  if (FSink <> nil) and not FFigureStarted then
  begin
    FSink.BeginFigure(P, D2D1_FIGURE_BEGIN_FILLED);
    FFigureStarted := True;
  end;
end;

{ TACLDirect2DAbstractRender }

constructor TACLDirect2DAbstractRender.Create(OnRecreateNeeded: TNotifyEvent);
begin
  FOnRecreateNeeded := OnRecreateNeeded;
  FResources := TList.Create;
  FResources.Capacity := 1024;
  FSavedClipRects := TStack<Integer>.Create;
  FSavedWorldTransforms := TStack<TD2D1Matrix3x2F>.Create;
  FCacheHatchBrushes := TACLValueCacheManager<UInt64, ID2D1Brush>.Create;
  FCacheSolidBrushes := TACLValueCacheManager<TAlphaColor, ID2D1SolidColorBrush>.Create;
end;

destructor TACLDirect2DAbstractRender.Destroy;
begin
  ReleaseDevice;
  FreeAndNil(FCacheHatchBrushes);
  FreeAndNil(FCacheSolidBrushes);
  FreeAndNil(FSavedWorldTransforms);
  FreeAndNil(FSavedClipRects);
  FreeAndNil(FResources);
  inherited;
end;

function TACLDirect2DAbstractRender.IntersectClipRect(const R: TRect): Boolean;
begin
  FDeviceContext.PushAxisAlignedClip(R, D2D1_ANTIALIAS_MODE_ALIASED);
  Inc(FClipCounter);
  Result := IsVisible(R);
end;

function TACLDirect2DAbstractRender.IsVisible(const R: TRect): Boolean;
begin
  Result := True;
end;

procedure TACLDirect2DAbstractRender.RestoreClipRegion;
begin
  RollbackClipRectChanges(FSavedClipRects.Pop);
end;

procedure TACLDirect2DAbstractRender.RollbackClipRectChanges(ATargetLevel: Integer);
begin
  while FClipCounter > ATargetLevel do
  begin
    FDeviceContext.PopAxisAlignedClip;
    Dec(FClipCounter);
  end;
end;

procedure TACLDirect2DAbstractRender.SaveClipRegion;
begin
  FSavedClipRects.Push(FClipCounter);
end;

function TACLDirect2DAbstractRender.CreateImage(Colors: PRGBQuad;
  Width, Height: Integer; AlphaFormat: TAlphaFormat): TACL2DRenderImage;
begin
  Result := TACLDirect2DRenderImage.Create(Self, Colors, Width, Height, AlphaFormat);
end;

function TACLDirect2DAbstractRender.CreateImageAttributes: TACL2DRenderImageAttributes;
begin
  Result := TACL2DRenderImageAttributes.Create(Self);
end;

function TACLDirect2DAbstractRender.CreatePath: TACL2DRenderPath;
begin
  Result := TACLDirect2DRenderPath.Create(Self);
end;

function TACLDirect2DAbstractRender.CreateCompatibleRenderTarget(
  const ASize: TSize; out ABitmapTarget: ID2D1BitmapRenderTarget): Boolean;
var
  ADesiredFormat: TD2D1PixelFormat;
  ADesiredPixelSize: TD2D1SizeU;
begin
  ADesiredPixelSize := D2D1SizeU(ASize.cx, ASize.cy);
  ADesiredFormat := D2D1PixelFormat(DXGI_FORMAT_A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED);
  Result := Succeeded(FDeviceContext.CreateCompatibleRenderTarget(nil,
    @ASize, @ADesiredFormat, D2D1_COMPATIBLE_RENDER_TARGET_OPTIONS_NONE, ABitmapTarget));
end;

function TACLDirect2DAbstractRender.CreatePathGeometry(APoints: PPoint; ACount: Integer;
  AFigureBegin: TD2D1FigureBegin; AFigureEnd: TD2D1_FigureEnd): ID2D1PathGeometry1;
var
  ASink: ID2D1GeometrySink;
begin
  if ACount <= 0 then
    Exit(nil);
  if Failed(TACLDirect2D.Factory.CreatePathGeometry(Result)) then
    Exit(nil);
  if Succeeded(Result.Open(ASink)) then
  try
    ASink.BeginFigure(APoints^, AFigureBegin);
    Inc(APoints);
    Dec(ACount);

    while ACount > 0 do
    begin
      ASink.AddLine(APoints^);
      Inc(APoints);
      Dec(ACount);
    end;
    ASink.EndFigure(AFigureEnd);
  finally
    ASink.Close;
  end;
end;

procedure TACLDirect2DAbstractRender.DrawEllipse(X1, Y1, X2, Y2: Single;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if Color.IsValid and (Width > 0) then
    FDeviceContext.DrawEllipse(D2D1Ellipse(X1, Y1, X2, Y2), CacheGetSolidBrush(Color), Width, CacheGetStrokeStyle(Style));
end;

procedure TACLDirect2DAbstractRender.DrawImage(Image: TACL2DRenderImage; const TargetRect, SourceRect: TRect; Alpha: Byte);
var
  ASourceRectangle: TD2D1RectF;
  ATargetRectangle: TD2D1RectF;
begin
  if IsValid(Image) then
  begin
    ASourceRectangle := SourceRect;
    ATargetRectangle := TargetRect;
    FDeviceContext.DrawBitmap(TACLDirect2DRenderImage(Image).Handle, @ATargetRectangle,
      Alpha / MaxByte, D2D1_INTERPOLATION_MODE_NEAREST_NEIGHBOR, @ASourceRectangle);
  end;
end;

procedure TACLDirect2DAbstractRender.DrawImage(Image: TACL2DRenderImage;
  const TargetRect, SourceRect: TRect; Attributes: TACL2DRenderImageAttributes);
var
  ABitmap: ID2D1Bitmap;
  ABitmapRectangle: TD2D1RectF;
  ABitmapTarget: ID2D1BitmapRenderTarget;
  AColor: TAlphaColor;
  ASourceRectangle: TD2D1RectF;
  ATargetRectangle: TD2D1RectF;
begin
  if not IsValid(Image) then
    Exit;

  if not IsValid(Attributes) then
  begin
    DrawImage(Image, TargetRect, SourceRect, MaxByte);
    Exit;
  end;

  if Attributes.TintColor.IsValid then
  begin
    ABitmap := TACLDirect2DRenderImage(Image).Handle;
    ASourceRectangle := SourceRect;
    ATargetRectangle := TargetRect;

    if not acSizeIsEqual(TargetRect, SourceRect) then
    begin
      if CreateCompatibleRenderTarget(TargetRect.Size, ABitmapTarget) then
      begin
        ABitmapRectangle := D2D1Rect(0, 0, TargetRect.Width, TargetRect.Height);
        ABitmapTarget.BeginDraw;
        try
          ABitmapTarget.Clear(D2D1ColorF(TAlphaColor.None));
          ABitmapTarget.DrawBitmap(ABitmap, @ABitmapRectangle, 1.0,
            D2D1_BITMAP_INTERPOLATION_MODE_NEAREST_NEIGHBOR, @ASourceRectangle);
        finally
          ABitmapTarget.EndDraw;
        end;
        D2D1Check(ABitmapTarget.GetBitmap(ABitmap));
        ASourceRectangle := ABitmapRectangle;
      end;
    end;

    AColor := Attributes.TintColor;
    AColor.A := MulDiv(AColor.A, Attributes.Alpha, MaxByte);
    FDeviceContext.FillOpacityMask(ABitmap, CacheGetSolidBrush(AColor), @ATargetRectangle, @ASourceRectangle);
  end
  else
    DrawImage(Image, TargetRect, SourceRect, Attributes.Alpha);
end;

procedure TACLDirect2DAbstractRender.DrawPath(Path: TACL2DRenderPath;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if IsValid(Path) and Color.IsValid and (Width > 0) then
    Geometry(TACLDirect2DRenderPath(Path).Handle, TAlphaColor.None, Color, Width, Style);
end;

procedure TACLDirect2DAbstractRender.DrawPolygon(const Points: array of TPoint;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  Polygon(Points, TAlphaColor.None, Color, Width, Style);
end;

procedure TACLDirect2DAbstractRender.DrawRectangle(X1, Y1, X2, Y2: Single;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  FDeviceContext.DrawRectangle(D2D1Rect(X1, Y1, X2, Y2), CacheGetSolidBrush(Color), Width, CacheGetStrokeStyle(Style));
end;

procedure TACLDirect2DAbstractRender.DrawText(const Text: string; const R: TRect;
  Color: TAlphaColor; Font: TFont; HorzAlign: TAlignment; VertAlign: TVerticalAlignment; WordWrap: Boolean);
const
  HorzAlignMap: array[TAlignment] of DWRITE_TEXT_ALIGNMENT = (
    DWRITE_TEXT_ALIGNMENT_LEADING, DWRITE_TEXT_ALIGNMENT_TRAILING, DWRITE_TEXT_ALIGNMENT_CENTER
  );
  VertAlignMap: array[TVerticalAlignment] of DWRITE_PARAGRAPH_ALIGNMENT = (
    DWRITE_PARAGRAPH_ALIGNMENT_NEAR, DWRITE_PARAGRAPH_ALIGNMENT_FAR, DWRITE_PARAGRAPH_ALIGNMENT_CENTER
  );
  WordWrapMap: array[Boolean] of TDWriteWordWrapping = (
    DWRITE_WORD_WRAPPING_NO_WRAP, DWRITE_WORD_WRAPPING_WRAP
  );
var
  ATextFormat: IDWriteTextFormat;
  ATextLength: Integer;
begin
  ATextLength := Length(Text);
  if (ATextLength > 0) and Color.IsValid then
  begin
    TACLDirect2D.DWriteFactory.CreateTextFormat(PChar(Font.Name), nil,
      TACLMath.IfThen(fsBold in Font.Style, DWRITE_FONT_WEIGHT_BOLD, DWRITE_FONT_WEIGHT_NORMAL),
      TACLMath.IfThen(fsItalic in Font.Style, DWRITE_FONT_STYLE_ITALIC, DWRITE_FONT_STYLE_NORMAL),
      DWRITE_FONT_STRETCH_NORMAL, -Font.Height, 'en-us', ATextFormat);
    ATextFormat.SetTextAlignment(HorzAlignMap[HorzAlign]);
    ATextFormat.SetParagraphAlignment(VertAlignMap[VertAlign]);
    ATextFormat.SetWordWrapping(WordWrapMap[WordWrap]);
    FDeviceContext.DrawText(PChar(Text), ATextLength, ATextFormat, R, CacheGetSolidBrush(Color), D2D1_DRAW_TEXT_OPTIONS_CLIP);
  end;
end;

procedure TACLDirect2DAbstractRender.EndPaint;
begin
  DoEndDraw;
  if FRecreateContextNeeded then
    CallNotifyEvent(Self, FOnRecreateNeeded);
end;

procedure TACLDirect2DAbstractRender.FillEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor);
begin
  if Color.IsValid then
    FDeviceContext.FillEllipse(D2D1Ellipse(X1, Y1, X2, Y2), CacheGetSolidBrush(Color));
end;

procedure TACLDirect2DAbstractRender.FillHatchRectangle(const R: TRect; Color1, Color2: TAlphaColor; Size: Integer);
begin
  FDeviceContext.FillRectangle(R, CacheGetHatchBrush(Color1, Color2, Size));
end;

procedure TACLDirect2DAbstractRender.FillPath(Path: TACL2DRenderPath; Color: TAlphaColor);
begin
  if IsValid(Path) and Color.IsValid then
    Geometry(TACLDirect2DRenderPath(Path).Handle, Color);
end;

procedure TACLDirect2DAbstractRender.FillPolygon(const Points: array of TPoint; Color: TAlphaColor);
begin
  Polygon(Points, Color, TAlphaColor.None);
end;

procedure TACLDirect2DAbstractRender.FillRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor);
begin
  FDeviceContext.FillRectangle(D2D1Rect(X1, Y1, X2, Y2), CacheGetSolidBrush(Color));
end;

procedure TACLDirect2DAbstractRender.FlushCache;
begin
  for var I := Low(FCacheStrokeStyles) to High(FCacheStrokeStyles) do
    FCacheStrokeStyles[I] := nil;
  FCacheSolidBrushes.Clear;
  FCacheHatchBrushes.Clear;
end;

procedure TACLDirect2DAbstractRender.Geometry(const AHandle: ID2D1Geometry;
  BackgroundColor, StrokeColor: TAlphaColor; StrokeWidth: Single; StrokeStyle: TACL2DRenderStrokeStyle);
begin
  if BackgroundColor.IsValid then
    FDeviceContext.FillGeometry(AHandle, CacheGetSolidBrush(BackgroundColor));
  if StrokeColor.IsValid and (StrokeWidth > 0) then
    FDeviceContext.DrawGeometry(AHandle, CacheGetSolidBrush(StrokeColor), StrokeWidth, CacheGetStrokeStyle(StrokeStyle));
end;

procedure TACLDirect2DAbstractRender.Line(const Points: PPoint;
  Count: Integer; Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if Color.IsValid and (Width > 0) and (Count > 0) then
    Geometry(CreatePathGeometry(Points, Count, D2D1_FIGURE_BEGIN_HOLLOW, D2D1_FIGURE_END_OPEN),
      TAlphaColor.None, Color, Width, Style);
end;

procedure TACLDirect2DAbstractRender.Line(X1, Y1, X2, Y2: Single;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  if Color.IsValid and (Width > 0) then
    FDeviceContext.DrawLine(D2D1PointF(X1, Y1), D2D1PointF(X2, Y2),
      CacheGetSolidBrush(Color), Width, CacheGetStrokeStyle(Style));
end;

procedure TACLDirect2DAbstractRender.ApplyWorldTransform;
//var
//  ATransform: TD2D1Matrix3x2F;
begin
//  ATransform := D2D1Matrix3x2(1, 0, 0, 1, -FWindowOrg.X, -FWindowOrg.Y);
//  ATransform := FWorldTransform * ATransform;
  FDeviceContext.SetTransform(FWorldTransform);
end;

procedure TACLDirect2DAbstractRender.ModifyWorldTransform(const XForm: TXForm);
begin
  FWorldTransform := D2D1Matrix3x2(XForm) * FWorldTransform;
  ApplyWorldTransform;
end;

procedure TACLDirect2DAbstractRender.RestoreWorldTransform;
begin
  FWorldTransform := FSavedWorldTransforms.Pop;
  ApplyWorldTransform;
end;

procedure TACLDirect2DAbstractRender.SaveWorldTransform;
begin
  FSavedWorldTransforms.Push(FWorldTransform);
end;

procedure TACLDirect2DAbstractRender.SetWorldTransform(const XForm: TXForm);
begin
  FWorldTransform := D2D1Matrix3x2(XForm);
  ApplyWorldTransform;
end;

procedure TACLDirect2DAbstractRender.TransformPoints(Points: PPointF; Count: Integer);
var
  XForm: TXForm;
begin
  with FWorldTransform do
    XForm := TXForm.CreateMatrix(_11, _12, _21, _22, _31, _32);
  while Count > 0 do
  begin
    Points^ := XForm.Transform(Points^);
    Inc(Points);
    Dec(Count);
  end;
end;

procedure TACLDirect2DAbstractRender.Polygon(const Points: array of TPoint;
  Color, StrokeColor: TAlphaColor; StrokeWidth: Single; StrokeStyle: TACL2DRenderStrokeStyle);
begin
  if StrokeColor.IsValid and (StrokeWidth > 0) or Color.IsValid then
    Geometry(CreatePathGeometry(@Points[0], Length(Points),
      D2D1_FIGURE_BEGIN_FILLED, D2D1_FIGURE_END_CLOSED),
      Color, StrokeColor, StrokeWidth, StrokeStyle);
end;

procedure TACLDirect2DAbstractRender.AbandonResources;
begin
  for var I := FResources.Count - 1 downto 0 do
    TACL2DRenderResource(FResources.List[I]).Release;
  FResources.Count := 0;
end;

procedure TACLDirect2DAbstractRender.DoBeginDraw(const AClipRect: TRect);
begin
  SetWorldTransform(TXForm.CreateIdentityMatrix);
  FDeviceContext.SetAntialiasMode(D2D1_ANTIALIAS_MODE_ALIASED);
  FDeviceContext.SetTextAntialiasMode(D2D1_TEXT_ANTIALIAS_MODE_DEFAULT);
  FDeviceContext.BeginDraw;
  IntersectClipRect(AClipRect);
end;

procedure TACLDirect2DAbstractRender.DoEndDraw;
begin
  RollbackClipRectChanges(0);
  if TACLDirect2D.NeedRecreateContext(FDeviceContext.EndDraw) then
    FRecreateContextNeeded := True;
end;

procedure TACLDirect2DAbstractRender.ReleaseDevice;
begin
  FlushCache;
  AbandonResources;
  FDeviceContext := nil;
end;

function TACLDirect2DAbstractRender.CacheGetHatchBrush(AColor1, AColor2: TAlphaColor; ASize: Word): ID2D1Brush;
var
  ABitmap: ID2D1Bitmap;
  ABitmapBrush: ID2D1BitmapBrush1;
  ABitmapBrushProperties: TD2D1BitmapBrushProperties1;
  APattern: TBitmap;
  AKey: UInt64;
begin
  AKey := UInt64(ASize and $FFFF) or
    (UInt64(AColor2 and not AlphaMask) shl 16) or
    (UInt64(AColor1 and not AlphaMask) shl 40);
  if not FCacheHatchBrushes.Get(AKey, Result) then
  begin
    APattern := acHatchCreatePattern(ASize, AColor1.ToColor, AColor2.ToColor);
    try
      ABitmap := D2D1Bitmap(FDeviceContext, APattern, afIgnored);
      ZeroMemory(@ABitmapBrushProperties, SizeOf(ABitmapBrushProperties));
      ABitmapBrushProperties.extendModeX := D2D1_EXTEND_MODE_WRAP;
      ABitmapBrushProperties.extendModeY := D2D1_EXTEND_MODE_WRAP;
      ABitmapBrushProperties.interpolationMode := D2D1_INTERPOLATION_MODE_NEAREST_NEIGHBOR;
      if Succeeded(FDeviceContext.CreateBitmapBrush(ABitmap, @ABitmapBrushProperties, nil, ABitmapBrush)) then
        Result := ABitmapBrush;
      FCacheHatchBrushes.Add(AKey, Result);
    finally
      APattern.Free;
    end;
  end;
end;

function TACLDirect2DAbstractRender.CacheGetSolidBrush(AColor: TAlphaColor): ID2D1SolidColorBrush;
begin
  if not FCacheSolidBrushes.Get(AColor, Result) then
  begin
    FDeviceContext.CreateSolidColorBrush(D2D1ColorF(AColor), nil, Result);
    FCacheSolidBrushes.Add(AColor, Result);
  end;
end;

function TACLDirect2DAbstractRender.CacheGetStrokeStyle(AStyle: TACL2DRenderStrokeStyle): ID2D1StrokeStyle1;
const
  Styles: array[TACL2DRenderStrokeStyle] of TD2D1DashStyle = (
    D2D1_DASH_STYLE_SOLID,
    D2D1_DASH_STYLE_DASH,
    D2D1_DASH_STYLE_DOT,
    D2D1_DASH_STYLE_DASH_DOT,
    D2D1_DASH_STYLE_DASH_DOT_DOT
  );
var
  AProperties: TD2D1StrokeStyleProperties1;
begin
  if AStyle = ssSolid then
    Exit(nil);

  Result := FCacheStrokeStyles[AStyle];
  if Result = nil then
  begin
    ZeroMemory(@AProperties, SizeOf(AProperties));
    AProperties.StartCap := D2D1_CAP_STYLE_FLAT;
    AProperties.EndCap := D2D1_CAP_STYLE_FLAT;
    AProperties.dashCap := D2D1_CAP_STYLE_SQUARE;
    AProperties.LineJoin := D2D1_LINE_JOIN_MITER;
    AProperties.MiterLimit := 10;
    AProperties.DashStyle := Styles[AStyle];
    AProperties.DashOffset := 0;
    AProperties.TransformType := D2D1_STROKE_TRANSFORM_TYPE_NORMAL;
    TACLDirect2D.Factory.CreateStrokeStyle(@AProperties, nil, 0, Result);
    FCacheStrokeStyles[AStyle] := Result;
  end;
end;

{ TACLDirect2DGdiCompatibleRender }

constructor TACLDirect2DGdiCompatibleRender.Create(OnRecreateNeeded: TNotifyEvent);
begin
  inherited;
  CreateRenderTarget;
end;

procedure TACLDirect2DGdiCompatibleRender.BeginPaint(DC: HDC; const BoxRect, UpdateRect: TRect);
begin
  FRenderTarget.BindDC(DC, BoxRect);
  FUpdateRect := UpdateRect;
  DoBeginDraw(UpdateRect);
end;

procedure TACLDirect2DGdiCompatibleRender.CreateRenderTarget;
var
  AProperties: TD2D1RenderTargetProperties;
begin
  TACLDirect2D.CheckInitialized;
  ZeroMemory(@AProperties, SizeOf(AProperties));
  AProperties.&type := D2D1_RENDER_TARGET_TYPE_DEFAULT;
  AProperties.pixelFormat := D2D1PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED);
  AProperties.usage := D2D1_RENDER_TARGET_USAGE_GDI_COMPATIBLE;
  D2D1Check(TACLDirect2D.Factory.CreateDCRenderTarget(AProperties, FRenderTarget));
  FDeviceContext := FRenderTarget as ID2D1DeviceContext;
  FRecreateContextNeeded := False;
end;

procedure TACLDirect2DGdiCompatibleRender.GdiDraw(Proc: TACL2DRenderGdiDrawProc);
var
  ATarget: ID2D1GdiInteropRenderTarget;
  ATargetDC: HDC;
  AUpdateRect: TRect;
begin
  if Supports(FDeviceContext, ID2D1GdiInteropRenderTarget, ATarget) then
  begin
    D2D1Check(ATarget.GetDC(D2D1_DC_INITIALIZE_MODE_COPY, ATargetDC));
    try
      Proc(ATargetDC, AUpdateRect);
    finally
      D2D1Check(ATarget.ReleaseDC(AUpdateRect));
    end;
  end;
end;

{ TACLDirect2DHwndBasedRender }

constructor TACLDirect2DHwndBasedRender.Create(OnRecreateNeeded: TNotifyEvent;
  const ADevice: IDXGIDevice1; const AContext: ID2D1DeviceContext;
  const ADevice3D: ID3D11Device; const ADevice3DContext: ID3D11DeviceContext);
begin
  inherited Create(OnRecreateNeeded);
  FDevice := ADevice;
  FDevice3D := ADevice3D;
  FDevice3DContext := ADevice3DContext;
  FDeviceContext := AContext;
  FPresentParameters.DirtyRectsCount := 1;
  FPresentParameters.pDirtyRects := @FUpdateRect;
end;

procedure TACLDirect2DHwndBasedRender.BeginPaint(DC: HDC; const BoxRect, UpdateRect: TRect);
begin
  FCopyToDC := DC;
  if TACLDirect2D.VSync then
    FUpdateRect := UpdateRect
  else
    FUpdateRect := BoxRect;

  if FTextureSize <> BoxRect.Size then
  begin
    ReleaseTexture;
    FTextureSize := BoxRect.Size;
    D2D1Check(FSwapChain.ResizeBuffers(0, FTextureSize.cx, FTextureSize.cy, DXGI_FORMAT_UNKNOWN, 0));
    CreateTexture;
    FUpdateRect := acRect(FTextureSize);
  end;

  DoBeginDraw(FUpdateRect);
end;

procedure TACLDirect2DHwndBasedRender.EndPaint;
begin
  inherited;
  if FBufferIsValid and (FCopyToDC <> 0) then
    CopyToDC(FCopyToDC);
end;

procedure TACLDirect2DHwndBasedRender.SetWndHandle(AHandle: HWND);
const
  ScalingMode: array[Boolean] of TDXGIScaling = (DXGI_SCALING_STRETCH, DXGI_SCALING_NONE);
var
  AAdapter: IDXGIAdapter;
  AFactory: IDXGIFactory2;
  ASwapChainDescription: TDXGISwapChainDesc1;
begin
  if FWindowHandle <> AHandle then
  begin
    if FWindowHandle <> 0 then
    begin
      ReleaseTexture;
      FSwapChain := nil;
      FWindowHandle := 0;
    end;
    if AHandle <> 0 then
    begin
      FWindowHandle := AHandle;

      D2D1Check(FDevice.SetMaximumFrameLatency(TACLDirect2D.SwapChainSize - 1));
      D2D1Check(FDevice.GetAdapter(AAdapter));
      D2D1Check(AAdapter.GetParent(IDXGIFactory2, AFactory));

      ZeroMemory(@ASwapChainDescription, SizeOf(ASwapChainDescription));
      ASwapChainDescription.Format := DXGI_FORMAT_B8G8R8A8_UNORM;
      ASwapChainDescription.SampleDesc.Count := 1;
      ASwapChainDescription.BufferUsage := DXGI_USAGE_RENDER_TARGET_OUTPUT;
      ASwapChainDescription.BufferCount := TACLDirect2D.SwapChainSize;
      ASwapChainDescription.SwapEffect := DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL;
      ASwapChainDescription.Scaling := ScalingMode[IsWin8OrLater];

      D2D1Check(AFactory.CreateSwapChainForHwnd(FDevice3D, AHandle, @ASwapChainDescription, nil, nil, FSwapChain));
    end;
    FBufferIsValid := False;
  end;
end;

procedure TACLDirect2DHwndBasedRender.CreateTexture;
var
  ABufferProperties: TD2D1BitmapProperties1;
  ACanvasTarget: ID2D1Bitmap1;
  ASurface: IDXGISurface;
begin
  FSwapChain.GetBuffer(0, IDXGISurface, ASurface);
  FSwapChain.GetBuffer(1, IDXGISurface, FFrontBufferSurface);

  ZeroMemory(@ABufferProperties, SizeOf(ABufferProperties));
  ABufferProperties.pixelFormat.format := DXGI_FORMAT_B8G8R8A8_UNORM;
  ABufferProperties.pixelFormat.alphaMode := D2D1_ALPHA_MODE_PREMULTIPLIED;
  ABufferProperties.bitmapOptions := D2D1_BITMAP_OPTIONS_TARGET or D2D1_BITMAP_OPTIONS_CANNOT_DRAW;
  D2D1Check(FDeviceContext.CreateBitmapFromDxgiSurface(ASurface, ABufferProperties, ACanvasTarget));
  FDeviceContext.SetTarget(ACanvasTarget);
  FBufferIsValid := False;
end;

procedure TACLDirect2DHwndBasedRender.ReleaseDevice;
begin
  ReleaseTexture;
  inherited;
end;

procedure TACLDirect2DHwndBasedRender.ReleaseTexture;
begin
  FFrontBufferSurface := nil;
  FFrontBufferContent := nil;
  FFrontBufferContentSize := NullSize;
  FDeviceContext.SetTarget(nil);
  FTextureSize := NullSize;
  FBufferIsValid := False;
end;

procedure TACLDirect2DHwndBasedRender.CheckCreateFrontBufferContent;
var
  ATextureDescription: TD3D11Texture2DDesc;
  AFrontBufferTexture: ID3D11Texture2D;
begin
  if not acSizeIsEqual(FTextureSize, FFrontBufferContentSize) then
    FFrontBufferContent := nil;

  if FFrontBufferContent = nil then
  begin
    AFrontBufferTexture := FFrontBufferSurface as ID3D11Texture2D;
    AFrontBufferTexture.GetDesc(ATextureDescription);

    ATextureDescription.BindFlags := D3D11_BIND_RENDER_TARGET;
    ATextureDescription.Usage := D3D11_USAGE_DEFAULT;
    ATextureDescription.MiscFlags := D3D11_RESOURCE_MISC_GDI_COMPATIBLE;
    ATextureDescription.MipLevels := 1;
    ATextureDescription.SampleDesc.Count := 1;
    ATextureDescription.SampleDesc.Quality := 0;

    D2D1Check(Device3D.CreateTexture2D(ATextureDescription, nil, FFrontBufferContent));
    FFrontBufferContentSize := FTextureSize;
  end;
end;

procedure TACLDirect2DHwndBasedRender.CopyToDC(DC: HDC);
begin
  CopyToDC(DC, acRect(FTextureSize), acRect(FTextureSize));
end;

procedure TACLDirect2DHwndBasedRender.CopyToDC(DC: HDC; const ATargetRect, ASourceRect: TRect);
var
  ASourceBox: TD3D11Box;
  ASourceDC: HDC;
  ASurface: IDXGISurface1;
begin
  if ATargetRect.IsEmpty or ASourceRect.IsEmpty then
    Exit;

  CheckCreateFrontBufferContent;

  ASourceBox := TD3D11Box.Create(ASourceRect);
  Device3DContext.CopySubResourceRegion(
    FFrontBufferContent, 0, ASourceRect.Left, ASourceRect.Top, 0,
    FFrontBufferSurface as ID3D11Resource, 0, @ASourceBox);

  if Supports(FFrontBufferContent, IDXGISurface1, ASurface) then
  begin
    ASurface.GetDC(False, ASourceDC);
    acBitBlt(DC, ASourceDC, ATargetRect, ASourceRect.TopLeft);
    ASurface.ReleaseDC(nil);
  end;
end;

procedure TACLDirect2DHwndBasedRender.DoEndDraw;
begin
  inherited;
  if not FUpdateRect.IsEmpty then
  try
    FSwapChain.Present1(0, IfThen(TACLDirect2D.VSync, 0, DXGI_PRESENT_DO_NOT_WAIT), @FPresentParameters);
    FBufferIsValid := not FRecreateContextNeeded;
  except
    on E: Exception do
    begin
      if TACLDirect2D.NeedSwitchToGdiRenderMode(E) then
        FRecreateContextNeeded := True
      else
        raise;
    end;
  end;
end;

end.
