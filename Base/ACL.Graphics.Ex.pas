{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*         Extended Graphic Library          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.Ex;

{$I ACL.Config.inc}

interface

uses
  Winapi.GDIPAPI,
  Winapi.Messages,
  Winapi.Windows,
  // System
  System.Classes,
  System.Math,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // VCL
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Graphics,
  ACL.Graphics.Images,
  ACL.Graphics.SkinImage,
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

type
  // Refer to following articles for more information:
  //  https://en.wikipedia.org/wiki/Blend_modes
  //  https://en.wikipedia.org/wiki/Alpha_compositing
  TACLBlendMode = (bmNormal, bmMultiply, bmScreen, bmOverlay, bmAddition,
    bmSubstract, bmDifference, bmDivide, bmLighten, bmDarken, bmGrayscale);

{$REGION ' Layers '}

  { TACLBitmapLayer }

  TACLBitmapLayer = class(TACLDib)
  public
    procedure DrawBlend(DC: HDC; const P: TPoint;
      AMode: TACLBlendMode; AAlpha: Byte = MaxByte); overload;
    procedure DrawBlend(DC: HDC; const R: TRect;
      AAlpha: Byte = MaxByte; ASmoothStretch: Boolean = False); overload;
  end;

  { TACLCacheLayer }

  TACLCacheLayer = class(TACLBitmapLayer)
  strict private
    FIsDirty: Boolean;
  public
    procedure AfterConstruction; override;
    function CheckNeedUpdate(const R: TRect): Boolean;
    procedure Drop;
    //
    property IsDirty: Boolean read FIsDirty write FIsDirty;
  end;

  { TACLMaskLayer }

  TACLMaskLayer = class(TACLBitmapLayer)
  strict private
    FMask: PByte;
    FMaskFrameIndex: Integer;
    FMaskInfo: TACLSkinImageFrameState;
    FMaskInfoValid: Boolean;
    FOpaqueRange: TPoint;

    procedure ApplyMaskCore(AClipArea: PRect = nil); overload;
    procedure ApplyMaskCore(AMask: PByte; AColors: PACLPixel32; ACount: Integer); overload; inline;
  protected
    procedure FreeHandles; override;
  public
    procedure ApplyMask; overload; inline;
    procedure ApplyMask(const AClipArea: TRect); overload; inline;
    procedure LoadMask; overload;
    procedure LoadMask(AImage: TACLSkinImage; AMaskFrameIndex: Integer); overload;
    procedure UnloadMask;
  end;

{$ENDREGION}

{$REGION ' Blur '}

  { IACLBlurFilterCore }

  IACLBlurFilterCore = interface
  ['{89DD6E84-C6CB-4367-90EC-3943D5593372}']
    procedure Apply(LayerDC: HDC; Colors: PACLPixel32; Width, Height: Integer);
    function GetSize: Integer;
  end;

  { TACLBlurFilter }

  TACLBlurFilter = class
  public const
    MaxRadius = 32;
  strict private
    FCore: IACLBlurFilterCore;
    FRadius: Integer;
    FSize: Integer;

    procedure SetRadius(AValue: Integer);
  protected
    class var FCreateCoreProc: TFunc<Integer, IACLBlurFilterCore>;
  {$IFDEF ACL_BLURFILTER_USE_SHARED_RESOURCES}
    class var FShare: TACLValueCacheManager<Integer, IACLBlurFilterCore>;
  {$ENDIF}
  public
  {$IFDEF ACL_BLURFILTER_USE_SHARED_RESOURCES}
    class constructor Create;
    class destructor Destroy;
  {$ENDIF}
    constructor Create;
    procedure Apply(ALayer: TACLBitmapLayer); overload;
    procedure Apply(ALayerDC: HDC; AColors: PACLPixel32; AWidth, AHeight: Integer); overload;
    //
    property Radius: Integer read FRadius write SetRadius;
    property Size: Integer read FSize;
  end;

{$ENDREGION}

{$REGION ' Abstract 2D Render '}

  TACL2DRender = class;
  TACL2DRenderStrokeStyle = (ssSolid, ssDash, ssDot, ssDashDot, ssDashDotDot);

  { IACL2DRenderGdiCompatible }

  TACL2DRenderGdiDrawProc = reference to procedure (DC: HDC; out UpdateRect: TRect);
  IACL2DRenderGdiCompatible = interface
  ['{D4065B50-E628-4E99-AD58-DF771293C551}']
    procedure GdiDraw(Proc: TACL2DRenderGdiDrawProc);
  end;

  { TACL2DRenderResource }

  TACL2DRenderResource = class
  protected
    FOwner: TACL2DRender;
  public
    constructor Create(AOwner: TACL2DRender);
    procedure Release; virtual;
  end;

  { TACL2DRenderImage }

  PACL2DRenderImage = ^TACL2DRenderImage;
  TACL2DRenderImage = class(TACL2DRenderResource)
  protected
    FHeight: Integer;
    FWidth: Integer;
  public
    function ClientRect: TRect; inline;
    function Empty: Boolean; inline;
    property Height: Integer read FHeight;
    property Width: Integer read FWidth;
  end;

  { TACL2DRenderImageAttributes }

  TACL2DRenderImageAttributes = class(TACL2DRenderResource)
  strict private
    FTintColor: TAlphaColor;
    FAlpha: Byte;
  protected
    procedure SetAlpha(AValue: Byte); virtual;
    procedure SetTintColor(AValue: TAlphaColor); virtual;
  public
    procedure AfterConstruction; override;
    property Alpha: Byte read FAlpha write SetAlpha;
    property TintColor: TAlphaColor read FTintColor write SetTintColor;
  end;

  { TACL2DRenderPath }

  TACL2DRenderPath = class(TACL2DRenderResource)
  public
    procedure AddArc(CX, CY, RadiusX, RadiusY, StartAngle, SweepAngle: Single); virtual; abstract;
    procedure AddLine(X1, Y1, X2, Y2: Single); virtual; abstract;
    procedure AddRect(const R: TRectF); virtual;
    procedure AddRoundRect(const R: TRectF; RadiusX, RadiusY: Single);
    procedure FigureClose; virtual; abstract;
    procedure FigureStart; virtual; abstract;
  end;

  { TACL2DRender }

  TACL2DRender = class(TACLUnknownObject)
  public
    procedure BeginPaint(DC: HDC; const BoxRect: TRect); overload;
    procedure BeginPaint(DC: HDC; const BoxRect, UpdateRect: TRect); overload; virtual; abstract;
    procedure EndPaint; virtual; abstract;

    function IsValid(const AResource: TACL2DRenderResource): Boolean; inline;

    // Clipping
    function IntersectClipRect(const R: TRect): Boolean; virtual; abstract;
    function IsVisible(const R: TRect): Boolean; virtual; abstract;
    procedure RestoreClipRegion; virtual; abstract;
    procedure SaveClipRegion; virtual; abstract;

    // Ellipse
    procedure Ellipse(const R: TRect; Color, StrokeColor: TAlphaColor;
      StrokeWidth: Single = 1; StrokeStyle: TACL2DRenderStrokeStyle = ssSolid);
    procedure DrawEllipse(const R: TRect; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); overload;
    procedure DrawEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); overload; virtual; abstract;
    procedure FillEllipse(const R: TRect; Color: TAlphaColor); overload;
    procedure FillEllipse(X1, Y1, X2, Y2: Single; Color: TAlphaColor); overload; virtual; abstract;

    // Line
    procedure Line(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); overload; virtual; abstract;
    procedure Line(const Points: array of TPoint; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); overload;
    procedure Line(const Points: PPoint; Count: Integer; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); overload; virtual; abstract;

    // Images
    function CreateImage(Bitmap: TBitmap): TACL2DRenderImage; overload; virtual;
    function CreateImage(Colors: PACLPixel32; Width, Height: Integer;
      AlphaFormat: TAlphaFormat = afDefined): TACL2DRenderImage; overload; virtual; abstract;
    function CreateImage(Image: TACLBitmapLayer): TACL2DRenderImage; overload; virtual;
    function CreateImage(Image: TACLImage): TACL2DRenderImage; overload; virtual;
    function CreateImageAttributes: TACL2DRenderImageAttributes; virtual; abstract;
    procedure DrawImage(Image: TACLBitmapLayer; const TargetRect: TRect; Cache: PACL2DRenderImage = nil); overload;
    procedure DrawImage(Image: TACL2DRenderImage; const TargetRect: TRect; Alpha: Byte = MaxByte); overload;
    procedure DrawImage(Image: TACL2DRenderImage;
      const TargetRect, SourceRect: TRect; Alpha: Byte = MaxByte); overload; virtual; abstract;
    procedure DrawImage(Image: TACL2DRenderImage;
      const TargetRect, SourceRect: TRect; Attributes: TACL2DRenderImageAttributes); overload; virtual; abstract;

    // Rectangles
    procedure Rectangle(const R: TRect; Color, StrokeColor: TAlphaColor;
      StrokeWidth: Single = 1; StrokeStyle: TACL2DRenderStrokeStyle = ssSolid);
    procedure DrawRectangle(const R: TRect; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); overload;
    procedure DrawRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); overload; virtual; abstract;
    procedure FillHatchRectangle(const R: TRect; Color1, Color2: TAlphaColor; Size: Integer); virtual; abstract;
    procedure FillRectangle(const R: TRect; Color: TAlphaColor); overload;
    procedure FillRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor); overload; virtual; abstract;

    // Text
    procedure DrawText(const Text: string; const R: TRect; Color: TAlphaColor; Font: TFont;
      HorzAlign: TAlignment = taLeftJustify; VertAlign: TVerticalAlignment = taVerticalCenter;
      WordWrap: Boolean = False); virtual; abstract;

    // Paths
    function CreatePath: TACL2DRenderPath; virtual; abstract;
    procedure DrawPath(Path: TACL2DRenderPath; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); virtual; abstract;
    procedure FillPath(Path: TACL2DRenderPath; Color: TAlphaColor); virtual; abstract;

    // Polygons
    procedure Polygon(const Points: array of TPoint; Color, StrokeColor: TAlphaColor;
      StrokeWidth: Single = 1; StrokeStyle: TACL2DRenderStrokeStyle = ssSolid); virtual;
    procedure DrawPolygon(const Points: array of TPoint; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); virtual; abstract;
    procedure FillPolygon(const Points: array of TPoint; Color: TAlphaColor); virtual; abstract;

    // World Transform
    procedure ModifyWorldTransform(const XForm: TXForm); virtual; abstract;
    procedure RestoreWorldTransform; virtual; abstract;
    procedure SaveWorldTransform; virtual; abstract;
    procedure ScaleWorldTransform(Scale: Single); overload;
    procedure ScaleWorldTransform(ScaleX, ScaleY: Single); overload; virtual;
    procedure SetWorldTransform(const XForm: TXForm); virtual; abstract;
    procedure TransformPoints(Points: PPointF; Count: Integer); virtual; abstract;
    procedure TranslateWorldTransform(OffsetX, OffsetY: Single); virtual;
  end;

{$ENDREGION}

  // BackgroundLayer is a target layer
  TACLBlendFunction = procedure (BackgroundLayer, ForegroundLayer: TACLBitmapLayer; Alpha: Byte) of object;

var
  FBlendFunctions: array[TACLBlendMode] of TACLBlendFunction;

implementation

uses
  // ACL
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics.Ex.Gdip,
  ACL.Math,
  ACL.Threading;

type
  TACLImageAccess = class(TACLImage);

{$REGION 'Software-based filters implementation'}
type

  { TACLSoftwareImplBlendMode }

  TACLSoftwareImplBlendMode = class
  strict private type
  {$REGION 'Internal Types'}
    TChunk = class
    protected
      Count: Integer;
      Source: PACLPixel32;
      Target: PACLPixel32;
    end;

    TChunks = class(TACLObjectList<TChunk>);

    TCalculateMatrixProc = function (const Source, Target: Integer): Integer;
  {$ENDREGION}
  strict private
    class var FAdditionMatrix: PACLPixelMap;
    class var FDarkenMatrix: PACLPixelMap;
    class var FDifferenceMatrix: PACLPixelMap;
    class var FDivideMatrix: PACLPixelMap;
    class var FLightenMatrix: PACLPixelMap;
    class var FMultiplyMatrix: PACLPixelMap;
    class var FOverlayMatrix: PACLPixelMap;
    class var FScreenMatrix: PACLPixelMap;
    class var FSubstractMatrix: PACLPixelMap;

    class var FLock: TACLCriticalSection;
    class var FWorkMatrix: PACLPixelMap;
    class var FWorkOpacity: Byte;

    class function BuildChunks(ATarget, ASource: TACLBitmapLayer): TChunks;
    class procedure InitializeMatrix(var AMatrix: PACLPixelMap; AProc: TCalculateMatrixProc);
    class procedure ProcessByMatrix(Chunk: TChunk); static;
    class procedure ProcessGrayScale(Chunk: TChunk); static;

    class function CalculateAdditionMatrix(const ASource, ATarget: Integer): Integer; static;
    class function CalculateDarkenMatrix(const ASource, ATarget: Integer): Integer; static;
    class function CalculateDifferenceMatrix(const ASource, ATarget: Integer): Integer; static;
    class function CalculateDivideMatrix(const ASource, ATarget: Integer): Integer; static;
    class function CalculateLightenMatrix(const ASource, ATarget: Integer): Integer; static;
    class function CalculateMultiplyMatrix(const ASource, ATarget: Integer): Integer; static;
    class function CalculateOverlayMatrix(const ASource, ATarget: Integer): Integer; static;
    class function CalculateScreenMatrix(const ASource, ATarget: Integer): Integer; static;
    class function CalculateSubstractMatrix(const ASource, ATarget: Integer): Integer; static;
  protected
    // General
    class procedure Run(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer;
      AProc: TACLMultithreadedOperation.TFilterProc; AOpacity: Byte); overload;
    class procedure Run(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer;
      var AMatrix: PACLPixelMap; AProc: TCalculateMatrixProc; AOpacity: Byte); overload;
  public
    class procedure Register;
    class procedure Unregister;
    // Blend Functions
    class procedure DoAddition(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
    class procedure DoDarken(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
    class procedure DoDifference(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
    class procedure DoDivide(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
    class procedure DoGrayScale(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
    class procedure DoLighten(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
    class procedure DoMultiply(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
    class procedure DoNormal(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
    class procedure DoOverlay(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
    class procedure DoScreen(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
    class procedure DoSubstract(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
  end;

  { TACLSoftwareImplGaussianBlur }

  TACLSoftwareImplGaussianBlur = class(TInterfacedObject, IACLBlurFilterCore)
  strict private type
  {$REGION 'Internal Types'}

    TChunk = class
    strict private
      FBuffer: PACLPixel32;
      FFilter: TACLSoftwareImplGaussianBlur;
    protected
      Colors: PACLPixel32;
      Index1: Integer;
      Index2: Integer;
      LineWidth: Integer;
      ScanCount: Integer;
      ScanStep: Integer;
    public
      constructor Create(AFilter: TACLSoftwareImplGaussianBlur; AMaxLineSize: Integer);
      destructor Destroy; override;
      procedure ApplyTo; overload;
      procedure ApplyTo(AColors: PACLPixel32; ACount, AStep: Integer); overload;
    end;

    TChunks = class(TACLObjectList<TChunk>);
  {$ENDREGION}
  strict private
    FRadius: Double;
    FSize: Integer;
  protected const
    MaxSize = 20;
    WeightResolution = 10000;
  protected
    FWeights: array [-MaxSize..MaxSize, Byte] of Integer;

    class procedure Process(Chunk: Pointer); static;
    property Size: Integer read FSize;
  public
    constructor Create(ARadius: Integer);
    class function CreateBlurFilterCore(ARadius: Integer): IACLBlurFilterCore; static;
    // IACLBlurFilterCore
    procedure Apply(DC: HDC; AColors: PACLPixel32; AWidth, AHeight: Integer);
    function GetSize: Integer;
  end;

  { TACLSoftwareImplStackBlur }

  // Stack Blur Algorithm by Mario Klingemann <mario@quasimondo.com>
  TACLSoftwareImplStackBlur = class(TInterfacedObject, IACLBlurFilterCore)
  strict private
    FDivSum: Integer;
    FDivValues: PIntegerArray;
    FRadius: Integer;
    FRadiusBias: array[-TACLBlurFilter.MaxRadius..TACLBlurFilter.MaxRadius] of Integer;
    FStack: PAlphaColorArray;
    FStackOffset: Integer;
    FStackOffsets: PIntegerArray;
    FValueDiv: Integer;
  public
    constructor Create(ARadius: Integer);
    destructor Destroy; override;
    class function CreateBlurFilterCore(ARadius: Integer): IACLBlurFilterCore; static;
    class procedure Register;
    // IACLBlurFilterCore
    procedure Apply(DC: HDC; AColors: PACLPixel32; AWidth, AHeight: Integer);
    function GetSize: Integer;
  end;

{ TACLSoftwareImplBlendMode }

class procedure TACLSoftwareImplBlendMode.Register;
begin
  FLock := TACLCriticalSection.Create;
  FBlendFunctions[bmAddition] := DoAddition;
  FBlendFunctions[bmDarken] := DoDarken;
  FBlendFunctions[bmDifference] := DoDifference;
  FBlendFunctions[bmDivide] := DoDivide;
  FBlendFunctions[bmGrayscale] := DoGrayScale;
  FBlendFunctions[bmLighten] := DoLighten;
  FBlendFunctions[bmMultiply] := DoMultiply;
  FBlendFunctions[bmNormal] := DoNormal;
  FBlendFunctions[bmOverlay] := DoOverlay;
  FBlendFunctions[bmScreen] := DoScreen;
  FBlendFunctions[bmSubstract] := DoSubstract;
end;

class procedure TACLSoftwareImplBlendMode.Unregister;
begin
  FreeMemAndNil(Pointer(FAdditionMatrix));
  FreeMemAndNil(Pointer(FDarkenMatrix));
  FreeMemAndNil(Pointer(FDifferenceMatrix));
  FreeMemAndNil(Pointer(FDivideMatrix));
  FreeMemAndNil(Pointer(FLightenMatrix));
  FreeMemAndNil(Pointer(FMultiplyMatrix));
  FreeMemAndNil(Pointer(FOverlayMatrix));
  FreeMemAndNil(Pointer(FScreenMatrix));
  FreeMemAndNil(Pointer(FSubstractMatrix));
  FreeAndNil(FLock);
end;

class procedure TACLSoftwareImplBlendMode.DoAddition(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FAdditionMatrix, CalculateAdditionMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoDarken(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FDarkenMatrix, CalculateDarkenMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoDifference(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FDifferenceMatrix, CalculateDifferenceMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoDivide(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FDivideMatrix, CalculateDivideMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoGrayScale(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, @ProcessGrayScale, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoLighten(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FLightenMatrix, CalculateLightenMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoMultiply(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FMultiplyMatrix, CalculateMultiplyMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoNormal(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  AForegroundLayer.DrawBlend(ABackgroundLayer.Handle, NullPoint, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoOverlay(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FOverlayMatrix, CalculateOverlayMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoScreen(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FScreenMatrix, CalculateScreenMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoSubstract(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FSubstractMatrix, CalculateSubstractMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.Run(
  ABackgroundLayer, AForegroundLayer: TACLBitmapLayer;
  AProc: TACLMultithreadedOperation.TFilterProc; AOpacity: Byte);
var
  AChunks: TChunks;
begin
  FLock.Enter;
  try
    FWorkOpacity := AOpacity;
    AChunks := BuildChunks(ABackgroundLayer, AForegroundLayer);
    try
      TACLMultithreadedOperation.Run(@AChunks.List[0], AChunks.Count, AProc);
    finally
      AChunks.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

class procedure TACLSoftwareImplBlendMode.Run(
  ABackgroundLayer, AForegroundLayer: TACLBitmapLayer;
  var AMatrix: PACLPixelMap; AProc: TCalculateMatrixProc; AOpacity: Byte);
begin
  FLock.Enter;
  try
    InitializeMatrix(AMatrix, AProc);
    FWorkMatrix := AMatrix;
    Run(ABackgroundLayer, AForegroundLayer, @ProcessByMatrix, AOpacity);
  finally
    FLock.Leave;
  end;
end;

class function TACLSoftwareImplBlendMode.BuildChunks(ATarget, ASource: TACLBitmapLayer): TChunks;
var
  AChunk: TChunk;
  AChunkCount: Integer;
  AChunkSize: Integer;
  ASourceScan: PACLPixel32;
  ATargetScan: PACLPixel32;
  I: Integer;
begin
  if (ATarget.Width <> ASource.Width) or (ATarget.Height <> ASource.Height) then
    raise EInvalidOperation.Create(ClassName);

  if ASource.ColorCount > 256 * 256 then
    AChunkCount := CPUCount
  else
    AChunkCount := 1;

  AChunkSize := ASource.ColorCount div AChunkCount;
  ASourceScan := @ASource.Colors[0];
  ATargetScan := @ATarget.Colors[0];

  Result := TChunks.Create;
  Result.Capacity := AChunkCount;
  for I := 0 to AChunkCount - 1 do
  begin
    AChunk := TChunk.Create;
    AChunk.Count := AChunkSize;
    AChunk.Source := ASourceScan;
    AChunk.Target := ATargetScan;
    Inc(ATargetScan, AChunkSize);
    Inc(ASourceScan, AChunkSize);
    Result.Add(AChunk);
  end;
  Inc(Result.Last.Count, ASource.ColorCount mod AChunkCount);
end;

class procedure TACLSoftwareImplBlendMode.InitializeMatrix(var AMatrix: PACLPixelMap; AProc: TCalculateMatrixProc);
var
  ASource, ATarget: Byte;
begin
  if AMatrix = nil then
  begin
    AMatrix := AllocMem(SizeOf(TACLPixelMap));
    for ASource := 0 to MaxByte do
      for ATarget := 0 to MaxByte do
        AMatrix[ASource, ATarget] := MinMax(AProc(ASource, ATarget), 0, MaxByte);
  end;
end;

class procedure TACLSoftwareImplBlendMode.ProcessByMatrix(Chunk: TChunk);
var
  AAlpha: Byte;
  ASource: TACLPixel32;
  ATarget: TACLPixel32;
begin
  while Chunk.Count > 0 do
  begin
    PAlphaColor(@ASource)^ := PAlphaColor(Chunk.Source)^;
    if ASource.A > 0 then
    begin
      PAlphaColor(@ATarget)^ := PAlphaColor(Chunk.Target)^;

      if ATarget.A = MaxByte then
      begin
        TACLColors.Unpremultiply(ASource);
        ASource.B := FWorkMatrix[ASource.B, ATarget.B];
        ASource.G := FWorkMatrix[ASource.G, ATarget.G];
        ASource.R := FWorkMatrix[ASource.R, ATarget.R];
        TACLColors.Premultiply(ASource);
      end
      else
        if ATarget.A > 0 then
        begin
          TACLColors.Unpremultiply(ASource);
          AAlpha := MaxByte - ATarget.A;
          ASource.R := TACLColors.PremultiplyTable[ASource.R, AAlpha] +
            TACLColors.PremultiplyTable[FWorkMatrix[ASource.R, ATarget.R], ATarget.A];
          ASource.B := TACLColors.PremultiplyTable[ASource.B, AAlpha] +
            TACLColors.PremultiplyTable[FWorkMatrix[ASource.B, ATarget.B], ATarget.A];
          ASource.G := TACLColors.PremultiplyTable[ASource.G, AAlpha] +
            TACLColors.PremultiplyTable[FWorkMatrix[ASource.G, ATarget.G], ATarget.A];
          TACLColors.Premultiply(ASource);
        end;

      TACLColors.AlphaBlend(Chunk.Target^, ASource, FWorkOpacity);
    end;
    Inc(Chunk.Source);
    Inc(Chunk.Target);
    Dec(Chunk.Count);
  end;
end;

class procedure TACLSoftwareImplBlendMode.ProcessGrayScale(Chunk: TChunk);
var
  ASource: TACLPixel32;
begin
  while Chunk.Count > 0 do
  begin
    ASource := Chunk.Target^;
    TACLColors.Grayscale(ASource);
    TACLColors.AlphaBlend(Chunk.Target^, ASource, TACLColors.PremultiplyTable[FWorkOpacity, Chunk.Source^.A]);
    Inc(Chunk.Source);
    Inc(Chunk.Target);
    Dec(Chunk.Count);
  end;
end;

class function TACLSoftwareImplBlendMode.CalculateAdditionMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := ASource + ATarget;
end;

class function TACLSoftwareImplBlendMode.CalculateDarkenMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := Min(ASource, ATarget);
end;

class function TACLSoftwareImplBlendMode.CalculateDifferenceMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := Abs(ASource - ATarget);
end;

class function TACLSoftwareImplBlendMode.CalculateDivideMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := MulDiv(256, ATarget, ASource + 1);
end;

class function TACLSoftwareImplBlendMode.CalculateLightenMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := Max(ASource, ATarget);
end;

class function TACLSoftwareImplBlendMode.CalculateMultiplyMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := (ASource * ATarget) shr 8;
end;

class function TACLSoftwareImplBlendMode.CalculateOverlayMatrix(const ASource, ATarget: Integer): Integer;
begin
  if ATarget < 128 then
    Result := (2 * ASource * ATarget) shr 8
  else
    Result := MaxByte - 2 * ((MaxByte - ASource) * (MaxByte - ATarget)) shr 8;
end;

class function TACLSoftwareImplBlendMode.CalculateScreenMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := MaxByte - ((MaxByte - ASource) * (MaxByte - ATarget)) shr 8;
end;

class function TACLSoftwareImplBlendMode.CalculateSubstractMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := ATarget - ASource;
end;

{ TACLSoftwareImplGaussianBlur }

class function TACLSoftwareImplGaussianBlur.CreateBlurFilterCore(ARadius: Integer): IACLBlurFilterCore;
begin
  Result := TACLSoftwareImplGaussianBlur.Create(ARadius);
end;

constructor TACLSoftwareImplGaussianBlur.Create(ARadius: Integer);
type
  TWeights = array [-MaxSize..MaxSize] of Double;

  procedure NormalizeWeights(var AWeights: TWeights; ASize: Cardinal);
  var
    ATemp: Double;
    J: integer;
  begin
    ATemp := 0;
    for J := -ASize to ASize do
      ATemp := ATemp + AWeights[J];
    ATemp := 1 / ATemp;
    for J := -ASize to ASize do
      AWeights[J] := AWeights[J] * ATemp;
  end;

const
  Delta = 1 / (2 * MaxByte);
var
  ATemp: Double;
  AWeights: TWeights;
  I, J: Integer;
begin
  FSize := 0;
  FRadius := ARadius;
  if FRadius > 0 then
  begin
    for I := -MaxSize to MaxSize do
      AWeights[I] := Exp(-Sqr(I / FRadius) * 0.5);
    NormalizeWeights(AWeights, MaxSize);

    ATemp := 0;
    FSize := MaxSize;
    while (ATemp < Delta) and (FSize > 1) do
    begin
      ATemp := ATemp + 2 * AWeights[FSize];
      Dec(FSize);
    end;

    NormalizeWeights(AWeights, FSize);

    for I := -MaxSize to MaxSize do
    begin
      for J := 0 to MaxByte do
        FWeights[I, J] := Trunc(WeightResolution * AWeights[I] * J);
    end;
  end;
end;

function TACLSoftwareImplGaussianBlur.GetSize: Integer;
begin
  Result := FSize;
end;

procedure TACLSoftwareImplGaussianBlur.Apply(DC: HDC; AColors: PACLPixel32; AWidth, AHeight: Integer);

  function CreateChunks(ACount: Integer): TChunks;
  var
    I: Integer;
  begin
    Result := TChunks.Create;
    Result.Capacity := ACount;
    for I := 0 to ACount - 1 do
      Result.Add(TChunk.Create(Self, Max(AWidth, AHeight)));
  end;

  function GetChunkCount: Integer;
  begin
    Result := MaxMin(Min(AWidth, AHeight) div 64, 1, CPUCount);
  end;

  procedure Initialize(AList: TChunks; ARowCount, AScanCount, AScanStep, ALineWidth: Integer);
  var
    AChunk: TChunk;
    AChunkSize: Integer;
    AChunksLeft: Integer;
    AFinishIndex: Integer;
    AStartIndex: Integer;
    I: Integer;
  begin
    AChunkSize := ARowCount div AList.Count;
    AChunksLeft := ARowCount mod AList.Count;

    AStartIndex := 0;
    for I := 0 to AList.Count - 1 do
    begin
      AChunk := AList.List[I];
      AFinishIndex := AStartIndex + AChunkSize - 1;
      if AChunksLeft > 0 then
      begin
        Inc(AFinishIndex);
        Dec(AChunksLeft);
      end;

      AChunk.Colors := AColors;
      AChunk.Index1 := AStartIndex;
      AChunk.Index2 := AFinishIndex;
      AChunk.LineWidth := ALineWidth;
      AChunk.ScanCount := AScanCount;
      AChunk.ScanStep := AScanStep;

      AStartIndex := AFinishIndex + 1;
    end;
  end;

var
  AChunks: TChunks;
begin
  AChunks := CreateChunks(GetChunkCount);
  try
    Initialize(AChunks, AHeight, AWidth, 1, AWidth);
    TACLMultithreadedOperation.Run(@AChunks.List[0], AChunks.Count, Process);
    Initialize(AChunks, AWidth, AHeight, AWidth, 1);
    TACLMultithreadedOperation.Run(@AChunks.List[0], AChunks.Count, Process);
  finally
    AChunks.Free;
  end;
end;

{ TACLSoftwareImplGaussianBlur.TChunk }

constructor TACLSoftwareImplGaussianBlur.TChunk.Create(AFilter: TACLSoftwareImplGaussianBlur; AMaxLineSize: Integer);
begin
  inherited Create;
  FFilter := AFilter;
  FBuffer := AllocMem((AMaxLineSize + 2 * FFilter.Size + 1) * SizeOf(TACLPixel32))
end;

destructor TACLSoftwareImplGaussianBlur.TChunk.Destroy;
begin
  FreeMem(FBuffer);
  inherited Destroy;
end;

procedure TACLSoftwareImplGaussianBlur.TChunk.ApplyTo;
var
  AScan: PACLPixel32;
  I: Integer;
begin
  AScan := Colors;
  Inc(AScan, Index1 * LineWidth);
  for I := Index1 to Index2 do
  begin
    ApplyTo(AScan, ScanCount, ScanStep);
    Inc(AScan, LineWidth);
  end;
end;

procedure TACLSoftwareImplGaussianBlur.TChunk.ApplyTo(AColors: PACLPixel32; ACount, AStep: Integer);
var
  D: TACLPixel32;
  I, N: Integer;
  R, G, B: Integer;
  S, P: PACLPixel32;
begin
  // Preparing the temporary buffer
  P := AColors;
  S := FBuffer;
  D := P^;
  for I := 1 to FFilter.Size do
  begin
    S^ := D;
    Inc(S);
  end;

  if AStep = 1 then
  begin
    FastMove(P^, S^, ACount * SizeOf(TACLPixel32));
    Inc(P, ACount);
    Inc(S, ACount);
  end
  else
    for I := 1 to ACount do
    begin
      S^ := P^;
      Inc(P, AStep);
      Inc(S);
    end;

  Dec(P, AStep);
  D := P^;
  for I := 1 to FFilter.Size do
  begin
    S^ := D;
    Inc(S);
  end;

  // Applying filter to the destination colors
  for I := 0 to ACount - 1 do
  begin
    R := 0;
    G := 0;
    B := 0;
    S := FBuffer;
    Inc(S, I);
    for N := -FFilter.Size to FFilter.Size do
    begin
      Inc(R, FFilter.FWeights[N, S^.R]);
      Inc(G, FFilter.FWeights[N, S^.G]);
      Inc(B, FFilter.FWeights[N, S^.B]);
      Inc(S);
    end;
    AColors^.B := B div FFilter.WeightResolution;
    AColors^.G := G div FFilter.WeightResolution;
    AColors^.R := R div FFilter.WeightResolution;
    Inc(AColors, AStep);
  end;
end;

class procedure TACLSoftwareImplGaussianBlur.Process(Chunk: Pointer);
begin
  TChunk(Chunk).ApplyTo;
end;

{ TACLSoftwareImplStackBlur }

constructor TACLSoftwareImplStackBlur.Create(ARadius: Integer);
var
  I: Integer;
begin
  FRadius := ARadius;
  FValueDiv := 2 * FRadius + 1;
  FStackOffset := FValueDiv - FRadius;
  FDivSum := Sqr((FValueDiv + 1) shr 1);

  FDivValues := AllocMem(256 * FDivSum * SizeOf(Integer));
  for I := 0 to 256 * FDivSum - 1 do
    FDivValues^[I] := I div FDivSum;

  FStack := AllocMem(FValueDiv * SizeOf(TAlphaColor));
  FStackOffsets := AllocMem(2 * FValueDiv * SizeOf(Integer));
  for I := 0 to 2 * FValueDiv - 1 do
    FStackOffsets[I] := I mod FValueDiv;
  for I := -FRadius to FRadius do
    FRadiusBias[I] := FRadius + 1 - FastAbs(I);
end;

destructor TACLSoftwareImplStackBlur.Destroy;
begin
  FreeMem(FDivValues);
  FreeMem(FStackOffsets);
  FreeMem(FStack);
  inherited;
end;

class procedure TACLSoftwareImplStackBlur.Register;
begin
  TACLBlurFilter.FCreateCoreProc := CreateBlurFilterCore;
end;

class function TACLSoftwareImplStackBlur.CreateBlurFilterCore(ARadius: Integer): IACLBlurFilterCore;
begin
  Result := TACLSoftwareImplStackBlur.Create(ARadius);
end;

function TACLSoftwareImplStackBlur.GetSize: Integer;
begin
  Result := FRadius;
end;

procedure TACLSoftwareImplStackBlur.Apply(DC: HDC; AColors: PACLPixel32; AWidth, AHeight: Integer);
var
  AColor: PACLPixel32;
  AInputSumA: Integer;
  AInputSumB: Integer;
  AInputSumG: Integer;
  AInputSumR: Integer;
  AMinValues: PIntegerArray;
  AOutputSumA: Integer;
  AOutputSumB: Integer;
  AOutputSumG: Integer;
  AOutputSumR: Integer;
  ARadiusBias: Integer;
  AStackCursor: Integer;
  AStackScan: PACLPixel32;
  ASumA: Integer;
  ASumB: Integer;
  ASumG: Integer;
  ASumR: Integer;
  R, G, B, A: PIntegerArray;
  X, Y, I, Yp, Yi, Yw, Wm, Hm, WH, K: Integer;
begin
  if FRadius < 1 then
    Exit;

  Wm := AWidth - 1;
  Hm := AHeight - 1;
  WH := AWidth * AHeight;

  GetMem(R, WH * SizeOf(Integer));
  GetMem(G, WH * SizeOf(Integer));
  GetMem(B, WH * SizeOf(Integer));
  GetMem(A, WH * SizeOf(Integer));
  GetMem(AMinValues, max(AWidth, AHeight) * SizeOf(Integer));
  try
    Yw := 0;
    Yi := 0;

    for Y := 0 to AHeight - 1 do
    begin
      AInputSumR := 0;
      AInputSumG := 0;
      AInputSumB := 0;
      AInputSumA := 0;

      AOutputSumR := 0;
      AOutputSumG := 0;
      AOutputSumB := 0;
      AOutputSumA := 0;

      ASumR := 0;
      ASumG := 0;
      ASumB := 0;
      ASumA := 0;

      AStackScan := @FStack[0];
      for I := -FRadius to FRadius do
      begin
        PAlphaColor(AStackScan)^ := PAlphaColorArray(AColors)[Yi + MinMax(I, 0, Wm)];
        ARadiusBias := FRadiusBias[I];
        Inc(ASumR, AStackScan.R * ARadiusBias);
        Inc(ASumG, AStackScan.G * ARadiusBias);
        Inc(ASumB, AStackScan.B * ARadiusBias);
        Inc(ASumA, AStackScan.A * ARadiusBias);
        if I > 0 then
        begin
          Inc(AInputSumR, AStackScan.R);
          Inc(AInputSumG, AStackScan.G);
          Inc(AInputSumB, AStackScan.B);
          Inc(AInputSumA, AStackScan.A);
        end
        else
        begin
          Inc(AOutputSumR, AStackScan.R);
          Inc(AOutputSumG, AStackScan.G);
          Inc(AOutputSumB, AStackScan.B);
          Inc(AOutputSumA, AStackScan.A);
        end;
        Inc(AStackScan);
      end;
      AStackCursor := FRadius;

      for X := 0 to AWidth - 1 do
      begin
        R[Yi] := FDivValues[ASumR];
        G[Yi] := FDivValues[ASumG];
        B[Yi] := FDivValues[ASumB];
        A[Yi] := FDivValues[ASumA];

        Dec(ASumR, AOutputSumR);
        Dec(ASumG, AOutputSumG);
        Dec(ASumB, AOutputSumB);
        Dec(ASumA, AOutputSumA);

        AStackScan := @FStack[FStackOffsets[AStackCursor + FStackOffset]];

        Dec(AOutputSumR, AStackScan.R);
        Dec(AOutputSumG, AStackScan.G);
        Dec(AOutputSumB, AStackScan.B);
        Dec(AOutputSumA, AStackScan.A);

        if Y = 0 then
          AMinValues[X] := Min(X + FRadius + 1, Wm);

        PAlphaColor(AStackScan)^ := PAlphaColorArray(AColors)[Yw + AMinValues[X]];

        Inc(AInputSumR, AStackScan.R);
        Inc(AInputSumG, AStackScan.G);
        Inc(AInputSumB, AStackScan.B);
        Inc(AInputSumA, AStackScan.A);

        Inc(ASumR, AInputSumR);
        Inc(ASumG, AInputSumG);
        Inc(ASumB, AInputSumB);
        Inc(ASumA, AInputSumA);

        AStackCursor := FStackOffsets[AStackCursor + 1];
        AStackScan := @FStack[AStackCursor];

        Inc(AOutputSumR, AStackScan.R);
        Inc(AOutputSumG, AStackScan.G);
        Inc(AOutputSumB, AStackScan.B);
        Inc(AOutputSumA, AStackScan.A);

        Dec(AInputSumR, AStackScan.R);
        Dec(AInputSumG, AStackScan.G);
        Dec(AInputSumB, AStackScan.B);
        Dec(AInputSumA, AStackScan.A);

        Inc(Yi);
      end;
      Inc(Yw, AWidth);
    end;

    for X := 0 to AWidth - 1 do
    begin
      AInputSumR := 0;
      AInputSumG := 0;
      AInputSumB := 0;
      AInputSumA := 0;

      AOutputSumR := 0;
      AOutputSumG := 0;
      AOutputSumB := 0;
      AOutputSumA := 0;

      ASumR := 0;
      ASumG := 0;
      ASumB := 0;
      ASumA := 0;

      Yp := -FRadius * AWidth;
      AStackScan := @FStack[0];
      for I := -FRadius to FRadius do
      begin
        Yi := Max(0, Yp) + X;

        AStackScan.R := R[Yi];
        AStackScan.G := G[Yi];
        AStackScan.B := B[Yi];
        AStackScan.A := A[Yi];

        ARadiusBias := FRadiusBias[I];

        Inc(ASumR, R[Yi] * ARadiusBias);
        Inc(ASumG, G[Yi] * ARadiusBias);
        Inc(ASumB, B[Yi] * ARadiusBias);
        Inc(ASumA, A[Yi] * ARadiusBias);

        if I > 0 then
        begin
          Inc(AInputSumR, AStackScan.R);
          Inc(AInputSumG, AStackScan.G);
          Inc(AInputSumB, AStackScan.B);
          Inc(AInputSumA, AStackScan.A);
        end
        else
        begin
          Inc(AOutputSumR, AStackScan.R);
          Inc(AOutputSumG, AStackScan.G);
          Inc(AOutputSumB, AStackScan.B);
          Inc(AOutputSumA, AStackScan.A);
        end;

        if I < Hm then
          Inc(Yp, AWidth);
        Inc(AStackScan);
      end;

      AColor := @PAlphaColorArray(AColors)^[X];
      AStackCursor := FRadius;
      for Y := 0 to AHeight - 1 do
      begin
        AColor^.B := FDivValues[ASumB];
        AColor^.G := FDivValues[ASumG];
        AColor^.R := FDivValues[ASumR];
        AColor^.A := FDivValues[ASumA];

        Dec(ASumR, AOutputSumR);
        Dec(ASumG, AOutputSumG);
        Dec(ASumB, AOutputSumB);
        Dec(ASumA, AOutputSumA);

        AStackScan := @FStack[FStackOffsets[AStackCursor + FStackOffset]];

        Dec(AOutputSumR, AStackScan.R);
        Dec(AOutputSumG, AStackScan.G);
        Dec(AOutputSumB, AStackScan.B);
        Dec(AOutputSumA, AStackScan.A);

        if X = 0 then
          AMinValues[Y] := Min(Y + FRadius + 1, Hm) * AWidth;

        K := X + AMinValues[Y];
        AStackScan.R := R[K];
        AStackScan.G := G[K];
        AStackScan.B := B[K];
        AStackScan.A := A[K];

        Inc(AInputSumR, AStackScan.R);
        Inc(AInputSumG, AStackScan.G);
        Inc(AInputSumB, AStackScan.B);
        Inc(AInputSumA, AStackScan.A);

        Inc(ASumR, AInputSumR);
        Inc(ASumG, AInputSumG);
        Inc(ASumB, AInputSumB);
        Inc(ASumA, AInputSumA);

        AStackCursor := FStackOffsets[AStackCursor + 1];
        AStackScan := @FStack[AStackCursor];

        Inc(AOutputSumR, AStackScan.R);
        Inc(AOutputSumG, AStackScan.G);
        Inc(AOutputSumB, AStackScan.B);
        Inc(AOutputSumA, AStackScan.A);

        Dec(AInputSumR, AStackScan.R);
        Dec(AInputSumG, AStackScan.G);
        Dec(AInputSumB, AStackScan.B);
        Dec(AInputSumA, AStackScan.A);

        Inc(AColor, AWidth);
      end;
    end;
  finally
    FreeMem(AMinValues);
    FreeMem(A);
    FreeMem(R);
    FreeMem(G);
    FreeMem(B);
  end;
end;

{$ENDREGION}

{$REGION 'Layers'}

procedure TACLBitmapLayer.DrawBlend(DC: HDC; const P: TPoint; AMode: TACLBlendMode; AAlpha: Byte = MaxByte);
var
  ALayer: TACLBitmapLayer;
begin
  if Empty then
    Exit;
  if AMode = bmNormal then
    DrawBlend(DC, P, AAlpha)
  else
  begin
    ALayer := TACLBitmapLayer.Create(Width, Height);
    try
      acBitBlt(ALayer.Handle, DC, ALayer.ClientRect, P);
      FBlendFunctions[AMode](ALayer, Self, AAlpha);
      ALayer.DrawCopy(DC, P);
    finally
      ALayer.Free;
    end;
  end;
end;

procedure TACLBitmapLayer.DrawBlend(DC: HDC; const R: TRect; AAlpha: Byte = 255; ASmoothStretch: Boolean = False);
var
  AClipBox: TRect;
  AImage: TACLImage;
  ALayer: TACLDib;
begin
  if ASmoothStretch and not (Empty or R.EqualSizes(ClientRect)) then
  begin
    if (GetClipBox(DC, AClipBox) <> NULLREGION) and IntersectRect(AClipBox, AClipBox, R) then
    begin
      AImage := TACLImage.Create(PRGBQuad(Colors), Width, Height);
      try
        AImage.StretchQuality := sqLowQuality;
        AImage.PixelOffsetMode := ipomHalf;

        // Layer is used for better performance
        ALayer := TACLDib.Create(AClipBox);
        try
          SetWindowOrgEx(ALayer.Handle, AClipBox.Left, AClipBox.Top, nil);
          AImage.Draw(ALayer.Handle, R);
          SetWindowOrgEx(ALayer.Handle, 0, 0, nil);
          ALayer.DrawBlend(DC, AClipBox.TopLeft);
        finally
          ALayer.Free;
        end;
      finally
        AImage.Free;
      end;
    end;
  end
  else
    acAlphaBlend(DC, Handle, R, ClientRect, AAlpha);
end;

{ TACLCacheLayer }

procedure TACLCacheLayer.AfterConstruction;
begin
  inherited AfterConstruction;
  IsDirty := True;
end;

function TACLCacheLayer.CheckNeedUpdate(const R: TRect): Boolean;
begin
  if not R.EqualSizes(ClientRect) then
  begin
    Resize(R);
    IsDirty := True;
  end
  else
    if IsDirty then
      Reset;

  Result := IsDirty;
end;

procedure TACLCacheLayer.Drop;
begin
  Resize(0, 0);
end;

{ TACLMaskLayer }

procedure TACLMaskLayer.ApplyMask;
begin
  ApplyMaskCore(nil);
end;

procedure TACLMaskLayer.ApplyMask(const AClipArea: TRect);
begin
  ApplyMaskCore(@AClipArea)
end;

procedure TACLMaskLayer.LoadMask;
var
  AColor: PACLPixel32;
  AColorIndex: Integer;
  AMask: PByte;
  AOpaqueCounter: Integer;
begin
  FOpaqueRange := NullPoint;
  FMaskInfoValid := False;
  if FMask = nil then
    FMask := AllocMem(ColorCount);

  AMask := FMask;
  AColor := @Colors^[0];
  AOpaqueCounter := 0;
  for AColorIndex := 0 to ColorCount - 1 do
  begin
    AMask^ := AColor^.A;

    if AMask^ = MaxByte then
      Inc(AOpaqueCounter)
    else
    begin
      if AOpaqueCounter > FOpaqueRange.Y - FOpaqueRange.X then
      begin
        FOpaqueRange.Y := AColorIndex - 1;
        FOpaqueRange.X := FOpaqueRange.Y - AOpaqueCounter;
      end;
      AOpaqueCounter := 0;
    end;

    Inc(AMask);
    Inc(AColor);
  end;

  if FOpaqueRange.Y - FOpaqueRange.X < ColorCount div 3 then
    FOpaqueRange := NullPoint;
end;

procedure TACLMaskLayer.LoadMask(AImage: TACLSkinImage; AMaskFrameIndex: Integer);
begin
  if (FMask = nil) or (FMaskFrameIndex <> AMaskFrameIndex) then
  begin
    Reset;
    FMaskFrameIndex := AMaskFrameIndex;
    FMaskInfo := AImage.FrameInfo[AMaskFrameIndex];
    if {FMaskInfo.IsColor or }FMaskInfo.IsOpaque or FMaskInfo.IsTransparent then
    begin
      UnloadMask;
      FMaskInfoValid := True;
    end
    else
    begin
      AImage.Draw(Handle, ClientRect, AMaskFrameIndex);
      LoadMask;
    end;
  end;
end;

procedure TACLMaskLayer.UnloadMask;
begin
  FreeMemAndNil(Pointer(FMask));
  FMaskInfoValid := False;
end;

procedure TACLMaskLayer.FreeHandles;
begin
  inherited FreeHandles;
  UnloadMask;
end;

procedure TACLMaskLayer.ApplyMaskCore(AClipArea: PRect = nil);
var
  AIndex: Integer;
  AMask: PByte;
  ARange1: TPoint;
  ARange2: TPoint;
begin
  if FMaskInfoValid then
  begin
    if FMaskInfo.IsOpaque then
      Exit;
    if FMaskInfo.IsTransparent then
    begin
      Reset;
      Exit;
    end;
  end;

  AMask := FMask;

  ARange1.X := 0;
  ARange1.Y := ColorCount;
  ARange2.X := 0;
  ARange2.Y := 0;

  if FOpaqueRange <> NullPoint then
  begin
    ARange1.Y := Min(ARange1.Y, FOpaqueRange.X - 1);
    ARange2.X := FOpaqueRange.Y;
    ARange2.Y := ColorCount;
  end;

  if AClipArea <> nil then
  begin
    AIndex := CoordToFlatIndex(AClipArea^.Left, AClipArea^.Top);
    if AIndex > 0 then
    begin
      ARange1.X := Max(ARange1.X, AIndex);
      ARange2.X := Max(ARange2.X, AIndex);
    end;

    AIndex := CoordToFlatIndex(AClipArea^.Right, AClipArea^.Bottom);
    if AIndex > 0 then
    begin
      ARange1.Y := Min(ARange1.Y, AIndex);
      ARange2.Y := Min(ARange2.Y, AIndex);
    end;
  end;

  if ARange1.Y > ARange1.X then
    ApplyMaskCore(AMask + ARange1.X, @Colors^[ARange1.X], ARange1.Y - ARange1.X);
  if ARange2.Y > ARange2.X then
    ApplyMaskCore(AMask + ARange2.X, @Colors^[ARange2.X], ARange2.Y - ARange2.X);
end;

procedure TACLMaskLayer.ApplyMaskCore(AMask: PByte; AColors: PACLPixel32; ACount: Integer);
var
  AAlpha: Byte;
begin
  while ACount > 0 do
  begin
    AAlpha := AMask^;
    if AAlpha = 0 then
      DWORD(AColors^) := 0
    else
      if AAlpha < MaxByte then
      begin
        // less quality, but 2x faster
        //    TACLColors.Unpremultiply(C^);
        //    C^.A := TACLColors.PremultiplyTable[C^.A, S^];
        //    TACLColors.Premultiply(C^);
        AColors^.B := TACLColors.PremultiplyTable[AColors^.B, AAlpha];
        AColors^.G := TACLColors.PremultiplyTable[AColors^.G, AAlpha];
        AColors^.A := TACLColors.PremultiplyTable[AColors^.A, AAlpha];
        AColors^.R := TACLColors.PremultiplyTable[AColors^.R, AAlpha];
      end;

    Inc(AMask);
    Inc(AColors);
    Dec(ACount);
  end;
end;

{$ENDREGION}

{$REGION 'Blur'}

{ TACLBlurFilter }

{$IFDEF ACL_BLURFILTER_USE_SHARED_RESOURCES}
class constructor TACLBlurFilter.Create;
begin
  FShare := TACLValueCacheManager<Integer, IACLBlurFilterCore>.Create(8);
end;

class destructor TACLBlurFilter.Destroy;
begin
  FreeAndNil(FShare);
end;
{$ENDIF}

constructor TACLBlurFilter.Create;
begin
{$IFNDEF ACL_BLURFILTER_USE_SHARED_RESOURCES}
  FCore := FCreateBlurFilterCore;
{$ENDIF}
  Radius := 20;
end;

procedure TACLBlurFilter.Apply(ALayer: TACLBitmapLayer);
begin
  Apply(ALayer.Handle, PACLPixel32(ALayer.Colors), ALayer.Width, ALayer.Height);
end;

procedure TACLBlurFilter.Apply(ALayerDC: HDC; AColors: PACLPixel32; AWidth, AHeight: Integer);
begin
  if FSize > 0 then
    FCore.Apply(ALayerDC, AColors, AWidth, AHeight);
end;

procedure TACLBlurFilter.SetRadius(AValue: Integer);
begin
  AValue := MinMax(AValue, 0, MaxRadius);
  if FRadius <> AValue then
  begin
    FRadius := AValue;
  {$IFDEF ACL_BLURFILTER_USE_SHARED_RESOURCES}
    if not FShare.Get(FRadius, FCore) then
    begin
      FCore := FCreateCoreProc(AValue);
      FShare.Add(AValue, FCore);
    end;
  {$ELSE}
    FCore := FCreateCoreProc(AValue);
  {$ENDIF}
    FSize := FCore.GetSize;
  end;
end;

{$ENDREGION}

{$REGION 'Abstract 2D Render'}

{ TACL2DRenderResource }

constructor TACL2DRenderResource.Create(AOwner: TACL2DRender);
begin
  FOwner := AOwner;
end;

procedure TACL2DRenderResource.Release;
begin
  FOwner := nil;
end;

{ TACL2DRenderImage }

function TACL2DRenderImage.ClientRect: TRect;
begin
  Result := Rect(0, 0, Width, Height);
end;

function TACL2DRenderImage.Empty: Boolean;
begin
  Result := (Width = 0) or (Height = 0);
end;

{ TACL2DRenderImageAttributes }

procedure TACL2DRenderImageAttributes.AfterConstruction;
begin
  inherited;
  FAlpha := MaxByte;
  FTintColor := TAlphaColor.None;
end;

procedure TACL2DRenderImageAttributes.SetAlpha(AValue: Byte);
begin
  FAlpha := AValue;
end;

procedure TACL2DRenderImageAttributes.SetTintColor(AValue: TAlphaColor);
begin
  FTintColor := AValue;
end;

{ TACL2DRender }

function TACL2DRender.IsValid(const AResource: TACL2DRenderResource): Boolean;
begin
  Result := (AResource <> nil) and (AResource.FOwner = Self);
end;

procedure TACL2DRender.BeginPaint(DC: HDC; const BoxRect: TRect);
begin
  BeginPaint(DC, BoxRect, BoxRect)
end;

function TACL2DRender.CreateImage(Image: TACLImage): TACL2DRenderImage;
var
  AData: TBitmapData;
  AFormat: TAlphaFormat;
  APixelFormat: Integer;
begin
  APixelFormat := TACLImageAccess(Image).GetPixelFormat;
  if GetPixelFormatSize(APixelFormat) <> 32 then
    APixelFormat := PixelFormat32bppARGB;
  if TACLImageAccess(Image).BeginLock(AData, APixelFormat) then
  try
    case AData.PixelFormat of
      PixelFormat32bppARGB:
        AFormat := afDefined;
      PixelFormat32bppPARGB:
        AFormat := afPremultiplied;
      PixelFormat32bppRGB:
        AFormat := afIgnored;
    else
      raise EInvalidArgument.Create('Unexpected pixel format');
    end;
    Result := CreateImage(AData.Scan0, AData.Width, AData.Height, AFormat);
  finally
    TACLImageAccess(Image).EndLock(AData);
  end
  else
    Result := nil;
end;

function TACL2DRender.CreateImage(Bitmap: TBitmap): TACL2DRenderImage;
var
  AColors: TRGBColors;
begin
  Result := nil;
  if not Bitmap.Empty then
    with TACLBitmapBits.Create(Bitmap.Handle) do
    try
      if ReadColors(AColors) then
        Result := CreateImage(@AColors[0], Bitmap.Width, Bitmap.Height, Bitmap.AlphaFormat);
    finally
      Free;
    end;
end;

function TACL2DRender.CreateImage(Image: TACLBitmapLayer): TACL2DRenderImage;
begin
  if Image.Empty then
    Result := nil
  else
    Result := CreateImage(PACLPixel32(Image.Colors), Image.Width, Image.Height, afPremultiplied);
end;

procedure TACL2DRender.DrawImage(Image: TACLBitmapLayer; const TargetRect: TRect; Cache: PACL2DRenderImage);
var
  AImage: TACL2DRenderImage;
begin
  if Cache <> nil then
  begin
    if not IsValid(Cache^) then
    begin
      FreeAndNil(Cache^);
      Cache^ := CreateImage(Image);
    end;
    DrawImage(Cache^, TargetRect);
  end
  else
  begin
    AImage := CreateImage(Image);
    try
      DrawImage(AImage, TargetRect);
    finally
      AImage.Free;
    end;
  end;
end;

procedure TACL2DRender.DrawImage(Image: TACL2DRenderImage; const TargetRect: TRect; Alpha: Byte);
begin
  DrawImage(Image, TargetRect, Image.ClientRect, Alpha);
end;

procedure TACL2DRender.DrawEllipse(const R: TRect; Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  DrawEllipse(R.Left, R.Top, R.Right, R.Bottom, Color, Width, Style);
end;

procedure TACL2DRender.DrawRectangle(const R: TRect; Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  DrawRectangle(R.Left, R.Top, R.Right, R.Bottom, Color, Width, Style)
end;

procedure TACL2DRender.Ellipse(const R: TRect; Color, StrokeColor: TAlphaColor; StrokeWidth: Single; StrokeStyle: TACL2DRenderStrokeStyle);
begin
  FillEllipse(R, Color);
  DrawEllipse(R, StrokeColor, StrokeWidth, StrokeStyle);
end;

procedure TACL2DRender.FillEllipse(const R: TRect; Color: TAlphaColor);
begin
  FillEllipse(R.Left, R.Top, R.Right, R.Bottom, Color);
end;

procedure TACL2DRender.FillRectangle(const R: TRect; Color: TAlphaColor);
begin
  FillRectangle(R.Left, R.Top, R.Right, R.Bottom, Color);
end;

procedure TACL2DRender.Line(const Points: array of TPoint; Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
var
  L: Integer;
begin
  L := Length(Points);
  if L > 0 then
    Line(@Points[0], L, Color, Width, Style);
end;

procedure TACL2DRender.Polygon(const Points: array of TPoint;
  Color, StrokeColor: TAlphaColor; StrokeWidth: Single; StrokeStyle: TACL2DRenderStrokeStyle);
begin
  FillPolygon(Points, Color);
  DrawPolygon(Points, StrokeColor, StrokeWidth, StrokeStyle);
end;

procedure TACL2DRender.Rectangle(const R: TRect;
  Color, StrokeColor: TAlphaColor; StrokeWidth: Single; StrokeStyle: TACL2DRenderStrokeStyle);
begin
  FillRectangle(R, Color);
  DrawRectangle(R, StrokeColor, StrokeWidth, StrokeStyle);
end;

procedure TACL2DRender.ScaleWorldTransform(Scale: Single);
begin
  ScaleWorldTransform(Scale, Scale);
end;

procedure TACL2DRender.ScaleWorldTransform(ScaleX, ScaleY: Single);
begin
  ModifyWorldTransform(TXForm.CreateScaleMatrix(ScaleX, ScaleY));
end;

procedure TACL2DRender.TranslateWorldTransform(OffsetX, OffsetY: Single);
begin
  ModifyWorldTransform(TXForm.CreateTranslateMatrix(OffsetX, OffsetY));
end;

{ TACL2DRenderPath }

procedure TACL2DRenderPath.AddRect(const R: TRectF);
begin
  FigureStart;
  try
    AddLine(R.Left, R.Top, R.Right, R.Top);
    AddLine(R.Right, R.Top, R.Right, R.Bottom);
    AddLine(R.Right, R.Bottom, R.Left, R.Bottom);
  finally
    FigureClose;
  end;
end;

procedure TACL2DRenderPath.AddRoundRect(const R: TRectF; RadiusX, RadiusY: Single);
begin
  RadiusX := Min(RadiusX, R.Width / 3);
  RadiusY := Min(RadiusY, R.Height / 3);

  if (RadiusX > 0) and (RadiusY > 0) and not IsZero(RadiusX) and not IsZero(RadiusY) then
  begin
    FigureStart;
    try
      AddLine(R.Left + RadiusX, R.Top, R.Right - RadiusX, R.Top);
      AddArc(R.Right - RadiusX, R.Top + RadiusY, RadiusX, RadiusY, 270, 90);
      AddLine(R.Right, R.Top + RadiusY, R.Right, R.Bottom - RadiusY);
      AddArc(R.Right - RadiusX, R.Bottom - RadiusY, RadiusX, RadiusY, 0, 90);
      AddLine(R.Right - RadiusX, R.Bottom, R.Left + RadiusX, R.Bottom);
      AddArc(R.Left + RadiusX, R.Bottom - RadiusY, RadiusX, RadiusY, 90, 90);
      AddLine(R.Left, R.Bottom - RadiusY, R.Left, R.Top + RadiusY);
      AddArc(R.Left + RadiusX, R.Top + RadiusY, RadiusX, RadiusY, 180, 90);
    finally
      FigureClose;
    end;
  end
  else
    AddRect(R);
end;

{$ENDREGION}

initialization
  TACLSoftwareImplBlendMode.Register;
  TACLSoftwareImplStackBlur.Register;
finalization
  TACLSoftwareImplBlendMode.Unregister;
end.
