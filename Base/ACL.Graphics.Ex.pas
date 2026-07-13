////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             Extended Graphics Library
//             v7.0
//
//  Purpose:   General Classes
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Graphics.Ex;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.GDIPAPI,
  Winapi.Messages,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // VCL
  {Vcl.}Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.ByteBuffer,
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex.Stub,
  ACL.Graphics.Images,
  ACL.Graphics.SkinImage,
  ACL.Math,
  ACL.Threading,
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

type

{$REGION ' Blur '}

  { IACLBlurFilterCore }

  IACLBlurFilterCore = interface
  ['{89DD6E84-C6CB-4367-90EC-3943D5593372}']
    procedure Apply(Colors: PACLPixel32; Width, Height: Integer);
    function GetSize: Integer;
  end;

  { TACLBlurFilter }

  TACLBlurFilter = class
  public const
    MaxRadius = 35;
  strict private
    FCore: IACLBlurFilterCore;
    FRadius: Integer;
    FSize: Integer;

    procedure SetRadius(AValue: Integer);
  protected
    class var FCreateCoreProc: TFunc<Integer, IACLBlurFilterCore>;
    class var FShare: TACLValueCacheManager<Integer, IACLBlurFilterCore>;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure FlushCache;
  public
    procedure Apply(AColors: PACLPixel32; AWidth, AHeight: Integer); overload;
    procedure Apply(ALayer: TACLBaseDib); overload;
    //# Properties
    property Radius: Integer read FRadius write SetRadius;
    property Size: Integer read FSize;
  end;

{$ENDREGION}

{$REGION ' Abstract 2D Render '}

  TACL2DRender = class;
  TACL2DRenderStrokeStyle = (ssSolid, ssDash, ssDot, ssDashDot, ssDashDotDot);
  TACL2DRenderTextAntialiasMode = (tamDefault, tamNone, tamGrayscale, tamClearType);

  TACL2DRenderSourceUsage = (
    suCopy,      // Copy required data from the source
    suReference, // Use data directly from the source throughout lifetime of the resource
    suOwned      // Use data directly from the source throughout lifetime of the resource, destroy the source with the resource
  );

  { IACL2DRenderGdiCompatible }

  TACL2DRenderGdiDrawProc = reference to procedure (DC: HDC; out UpdateRect: TRect);
  IACL2DRenderGdiCompatible = interface
  ['{D4065B50-E628-4E99-AD58-DF771293C551}']
    procedure GdiDraw(Proc: TACL2DRenderGdiDrawProc);
  end;

  { IACL2DRenderWndBased }

  IACL2DRenderWndBased = interface
  ['{90451EAC-9428-467B-8702-42035FDF253B}']
    procedure SetWndHandle(AWndHandle: HWND);
  end;

  { TACL2DRenderResource }

  TACL2DRenderResource = class
  protected
    FOwner: TACL2DRender;
    FOwnerSerial: Integer;
  public
    constructor Create(AOwner: TACL2DRender);
    procedure Release; virtual;
  end;

  { TACL2DRenderImage }

  PACL2DRenderImage = ^TACL2DRenderImage;
  TACL2DRenderImage = class(TACL2DRenderResource)
  protected
    FOwnedData: TObject;
    FOwnedDataPtr: Pointer;
    FHeight: Integer;
    FWidth: Integer;
  public
    destructor Destroy; override;
    function ClientRect: TRect; inline;
    function Empty: Boolean; inline;
    property Height: Integer read FHeight;
    property Width: Integer read FWidth;
  end;

  { TACL2DRenderImageAttributes }

  TACL2DRenderImageAttributes = class(TACL2DRenderResource)
  strict private
    FAlpha: Byte;
    FTintColor: TAlphaColor;
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
    procedure AddArc(CenterX, CenterY, RadiusX, RadiusY: Single;
      StartAngle, SweepAngle: Single); virtual; abstract;
    procedure AddLine(X1, Y1, X2, Y2: Single); virtual; abstract;
    procedure AddRect(const R: TRectF); virtual;
    procedure AddRoundRect(const R: TRectF; RadiusX, RadiusY: Single);
    procedure FigureClose; virtual; abstract;
    procedure FigureStart; virtual; abstract;
  end;

  { TACL2DRender }

  TACL2DRenderRawData = type Pointer;

  TACL2DRenderClass = class of TACL2DRender;
  TACL2DRender = class(TACLUnknownObject)
  strict private
    FSerial: Integer;
  protected
    FLock: TACLCriticalSection;
    FOrigin: TPoint;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure BeginPaint(DC: HDC); overload; virtual;
    procedure BeginPaint(DC: HDC; const BoxRect: TRect); overload;
    procedure BeginPaint(DC: HDC; const BoxRect, UpdateRect: TRect); overload; virtual; abstract;
    procedure BeginPaint(ACanvas: TCanvas); overload; virtual;
    procedure EndPaint; virtual; abstract;

    // General
    function FriendlyName: string; virtual; abstract;
    function Name: string; virtual; abstract;
    // Resources
    function IsValid(const AResource: TACL2DRenderResource): Boolean; inline;

    // Clipping
    function Clip(const R: TRect; out Data: TACL2DRenderRawData): Boolean; virtual; abstract;
    procedure ClipRestore(Data: TACL2DRenderRawData); virtual; abstract;
    function IsVisible(const R: TRect): Boolean; virtual; abstract;

    // Curve
    procedure DrawCurve(AColor: TAlphaColor;
      const APoints: array of TPoint; ATension: Single; APenWidth: Single = 1.0); virtual;
    procedure FillCurve(AColor: TAlphaColor;
      const APoints: array of TPoint; ATension: Single); virtual;

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
    function CreateImage(Colors: PACLPixel32; Width, Height: Integer;
      AlphaFormat: TAlphaFormat = afDefined;
      Usage: TACL2DRenderSourceUsage = suCopy): TACL2DRenderImage; overload; virtual; abstract;
    function CreateImage(Image: TACLDib;
      Usage: TACL2DRenderSourceUsage = suCopy): TACL2DRenderImage; overload; virtual;
    function CreateImage(Image: TACLImage;
      Usage: TACL2DRenderSourceUsage = suCopy): TACL2DRenderImage; overload; virtual;
    function CreateImageAttributes: TACL2DRenderImageAttributes; virtual;
    procedure DrawImage(Image: TACLDib;
      const TargetRect: TRect; Cache: PACL2DRenderImage = nil); overload; virtual;
    procedure DrawImage(Image: TACL2DRenderImage;
      const TargetRect: TRect; Alpha: Byte = MaxByte); overload;
    procedure DrawImage(Image: TACL2DRenderImage;
      const TargetRect, SourceRect: TRect; Alpha: Byte = MaxByte); overload; virtual; abstract;
    procedure DrawImage(Image: TACL2DRenderImage;
      const TargetRect, SourceRect: TRect; Attributes: TACL2DRenderImageAttributes); overload; virtual; abstract;
    procedure TileImage(Image: TACL2DRenderImage;
      const TargetRect, SourceRect: TRect; Attributes: TACL2DRenderImageAttributes); overload; virtual;

    // Rectangles
    procedure Rectangle(const R: TRect; Color, StrokeColor: TAlphaColor;
      StrokeWidth: Single = 1; StrokeStyle: TACL2DRenderStrokeStyle = ssSolid);
    procedure DrawRectangle(const R: TRect; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); overload;
    procedure DrawRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid); overload; virtual; abstract;
    procedure FillHatchRectangle(const R: TRect;
      Color1, Color2: TAlphaColor; Size: Integer); virtual; abstract;
    procedure FillRectangle(const R: TRect; Color: TAlphaColor); overload;
    procedure FillRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor); overload; virtual; abstract;
    procedure FillRectangleByGradient(const R: TRect;
      Color1, Color2: TAlphaColor; Vertical: Boolean); virtual; abstract;

    // Text
    function MeasureText(const Text: string; Font: TFont;
      MaxWidth: Integer = -1; WordWrap: Boolean = False): TSize; overload;
    procedure MeasureText(const Text: string; Font: TFont;
      var Rect: TRect; WordWrap: Boolean); overload; virtual; abstract;
    procedure DrawText(const Text: string; const R: TRect;
      Color: TAlphaColor; Font: TFont;
      HorzAlign: TAlignment = taLeftJustify;
      VertAlign: TVerticalAlignment = taVerticalCenter;
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
    procedure SaveWorldTransform(out State: TACL2DRenderRawData); virtual; abstract;
    procedure RestoreWorldTransform(State: TACL2DRenderRawData); virtual; abstract;
    procedure ModifyWorldTransform(const XForm: TXForm); virtual; abstract;
    procedure ScaleWorldTransform(Scale: Single); overload;
    procedure ScaleWorldTransform(ScaleX, ScaleY: Single); overload; virtual;
    procedure SetWorldTransform(const XForm: TXForm); virtual; abstract;
    procedure TransformPoints(Points: PPointF; Count: Integer); virtual; abstract;
    procedure TranslateWorldTransform(OffsetX, OffsetY: Single); virtual;

    // WindowOrg
    function ModifyOrigin(DeltaX, DeltaY: Integer): TPoint{Previous}; virtual;
    procedure SetOrigin(const Origin: TPoint); virtual;

    // Options
    procedure SetGeometrySmoothing(AValue: TACLBoolean); virtual;
    procedure SetImageSmoothing(AValue: TACLBoolean); virtual;
    procedure SetPixelOffsetMode(AMode: TACLImagePixelOffsetMode); virtual;
    procedure SetTextAntialiasMode(AMode: TACL2DRenderTextAntialiasMode); virtual;
  protected
    property Origin: TPoint read FOrigin write SetOrigin;
    property Serial: Integer read FSerial;
  end;

{$ENDREGION}

  // BackgroundLayer is a target layer
  TACLBlendFunction = procedure (Background, Foreground: TACLBaseDib; Alpha: Byte) of object;

var
  BlendFunctions: array[TACLBlendMode] of TACLBlendFunction;
  BlendFunctionsThreadingThreshold: Integer = 800 * 800; // px
  ExPainter: TACL2DRender = nil;

implementation

uses
  ACL.FastCode;

type
  TACLImageAccess = class(TACLImage);

{$REGION ' Software-based filters implementation '}
type

  { TACLSoftwareImplBlendMode }

  TACLSoftwareImplBlendMode = class
  strict private type
  {$REGION 'Internal Types'}
    TCalculateMatrixProc = function (const Source, Target: Integer): Integer;
    TChunk = class
    public
      Count: Integer;
      Source: PACLPixel32;
      Target: PACLPixel32;
    end;
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
    class var FWorkChunk: TChunk;
    class var FWorkChunks: array of TChunk;
    class var FWorkMatrix: PACLPixelMap;
    class var FWorkOpacity: Byte;

    class procedure InitializeMatrix(var AMatrix: PACLPixelMap; AProc: TCalculateMatrixProc);
    class procedure ProcessAlphaBlend(Chunk: TChunk); static;
    class procedure ProcessByMatrix(Chunk: TChunk); static;
    class procedure ProcessGrayscale(Chunk: TChunk); static;

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
    class procedure Run(ABackground, AForeground: TACLBaseDib;
      AProc: TACLMultithreadedOperation.TFilterProc; AOpacity: Byte); overload;
    class procedure Run(ABackground, AForeground: TACLBaseDib;
      var AMatrix: PACLPixelMap; AProc: TCalculateMatrixProc; AOpacity: Byte); overload;
  public
    class procedure Register;
    class procedure Unregister;
    // Blend Functions
    class procedure DoAddition(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoDarken(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoDifference(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoDivide(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoGrayScale(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoLighten(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoMultiply(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoNormal(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoOverlay(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoScreen(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
    class procedure DoSubstract(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
  end;

  { TACLSoftwareImplGaussianBlur }

  TACLSoftwareImplGaussianBlur = class(TInterfacedObject, IACLBlurFilterCore)
  strict private type
  {$REGION ' Internal Types '}

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

    TChunks = class(TACLObjectListOf<TChunk>);
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
    procedure Apply(AColors: PACLPixel32; AWidth, AHeight: Integer);
    function GetSize: Integer;
  end;

  { TACLSoftwareImplStackBlur }

  // Stack Blur Algorithm by Mario Klingemann <mario@quasimondo.com>
  TACLSoftwareImplStackBlur = class(TInterfacedObject, IACLBlurFilterCore)
  strict private type
    PByteArrayOfInt32 = ^TByteArrayOfInt32;
    TByteArrayOfInt32 = array[Byte] of Integer;
  strict private
    class var FBufferA: TACLByteBuffer;
    class var FBufferB: TACLByteBuffer;
    class var FBufferG: TACLByteBuffer;
    class var FBufferM: TACLByteBuffer;
    class var FBufferR: TACLByteBuffer;
    class function GetBuffer(var ABuffer: TACLByteBuffer; ASize: Integer): TACLByteBuffer; inline;
  strict private
    FDivValues: PIntegerArray;
    FLock: TACLCriticalSection;
    FRadius: Integer;
    FRadiusBias: array[-TACLBlurFilter.MaxRadius..TACLBlurFilter.MaxRadius] of TByteArrayOfInt32;
    FStack: PAlphaColorArray;
    FStackOffset: Integer;
    FStackOffsets: PIntegerArray;
  public
    constructor Create(ARadius: Integer);
    destructor Destroy; override;
    // IACLBlurFilterCore
    procedure Apply(AColors: PACLPixel32; AWidth, AHeight: Integer);
    function GetSize: Integer;
  public
    class function CreateBlurFilterCore(ARadius: Integer): IACLBlurFilterCore; static;
    class destructor Destroy;
    class procedure Register;
  end;

{ TACLSoftwareImplBlendMode }

class procedure TACLSoftwareImplBlendMode.Register;
begin
  FLock := TACLCriticalSection.Create;
  FWorkChunk := TChunk.Create;
  BlendFunctions[bmAddition] := DoAddition;
  BlendFunctions[bmDarken] := DoDarken;
  BlendFunctions[bmDifference] := DoDifference;
  BlendFunctions[bmDivide] := DoDivide;
  BlendFunctions[bmGrayscale] := DoGrayScale;
  BlendFunctions[bmLighten] := DoLighten;
  BlendFunctions[bmMultiply] := DoMultiply;
  BlendFunctions[bmNormal] := DoNormal;
  BlendFunctions[bmOverlay] := DoOverlay;
  BlendFunctions[bmScreen] := DoScreen;
  BlendFunctions[bmSubstract] := DoSubstract;
end;

class procedure TACLSoftwareImplBlendMode.Unregister;
var
  I: Integer;
begin
  for I := Low(FWorkChunks) to High(FWorkChunks) do
    FreeAndNil(FWorkChunks[I]);
  FreeMemAndNil(FAdditionMatrix);
  FreeMemAndNil(FDarkenMatrix);
  FreeMemAndNil(FDifferenceMatrix);
  FreeMemAndNil(FDivideMatrix);
  FreeMemAndNil(FLightenMatrix);
  FreeMemAndNil(FMultiplyMatrix);
  FreeMemAndNil(FOverlayMatrix);
  FreeMemAndNil(FScreenMatrix);
  FreeMemAndNil(FSubstractMatrix);
  FreeAndNil(FWorkChunk);
  FreeAndNil(FLock);
end;

class procedure TACLSoftwareImplBlendMode.DoAddition(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  Run(ABackground, AForeground, FAdditionMatrix, CalculateAdditionMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoDarken(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  Run(ABackground, AForeground, FDarkenMatrix, CalculateDarkenMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoDifference(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  Run(ABackground, AForeground, FDifferenceMatrix, CalculateDifferenceMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoDivide(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  Run(ABackground, AForeground, FDivideMatrix, CalculateDivideMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoGrayScale(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  Run(ABackground, AForeground, @ProcessGrayscale, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoLighten(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  Run(ABackground, AForeground, FLightenMatrix, CalculateLightenMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoMultiply(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  Run(ABackground, AForeground, FMultiplyMatrix, CalculateMultiplyMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoNormal(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  Run(ABackground, AForeground, @ProcessAlphaBlend, AAlpha);
//  AForeground.DrawBlend(ABackground.Canvas, NullPoint, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoOverlay(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  Run(ABackground, AForeground, FOverlayMatrix, CalculateOverlayMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoScreen(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  Run(ABackground, AForeground, FScreenMatrix, CalculateScreenMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.DoSubstract(ABackground, AForeground: TACLBaseDib; AAlpha: Byte);
begin
  Run(ABackground, AForeground, FSubstractMatrix, CalculateSubstractMatrix, AAlpha);
end;

class procedure TACLSoftwareImplBlendMode.Run(
  ABackground, AForeground: TACLBaseDib;
  AProc: TACLMultithreadedOperation.TFilterProc; AOpacity: Byte);
var
  I: Integer;
  LChunk: TChunk;
  LChunkCount: Integer;
  LChunkSize: Integer;
  LChunkTail: Integer;
  LScanSource: PACLPixel32;
  LScanTarget: PACLPixel32;
begin
  if (ABackground.Width  <> AForeground.Width) or
     (ABackground.Height <> AForeground.Height)
  then
    raise EInvalidOperation.Create('Cannot blend DIBs with different sizes');

  FLock.Enter;
  try
    FWorkOpacity := AOpacity;
    if AForeground.ColorCount >= BlendFunctionsThreadingThreshold then
    begin
      if Length(FWorkChunks) = 0 then
      begin
        SetLength(FWorkChunks, Max(CPUCount, 1));
        for I := 0 to Length(FWorkChunks) - 1 do
          FWorkChunks[I] := TChunk.Create;
      end;
      LChunk := nil;
      LChunkCount := Length(FWorkChunks);
      LScanTarget := @ABackground.Colors[0];
      LScanSource := @AForeground.Colors[0];
      LChunkSize := AForeground.ColorCount div LChunkCount;
      LChunkTail := AForeground.ColorCount mod LChunkCount;
      for I := 0 to LChunkCount - 1 do
      begin
        LChunk := FWorkChunks[I];
        LChunk.Count  := LChunkSize;
        LChunk.Source := LScanSource;
        LChunk.Target := LScanTarget;
        Inc(LScanTarget, LChunkSize);
        Inc(LScanSource, LChunkSize);
      end;
      Inc(LChunk.Count, LChunkTail);
      TACLMultithreadedOperation.Run(@FWorkChunks[0], LChunkCount, AProc);
    end
    else
    begin
      FWorkChunk.Count  := ABackground.ColorCount;
      FWorkChunk.Source := @AForeground.Colors^;
      FWorkChunk.Target := @ABackground.Colors^;
      AProc(FWorkChunk);
    end;
  finally
    FLock.Leave;
  end;
end;

class procedure TACLSoftwareImplBlendMode.Run(
  ABackground, AForeground: TACLBaseDib; var AMatrix: PACLPixelMap;
  AProc: TCalculateMatrixProc; AOpacity: Byte);
begin
  FLock.Enter;
  try
    InitializeMatrix(AMatrix, AProc);
    FWorkMatrix := AMatrix;
    Run(ABackground, AForeground, @ProcessByMatrix, AOpacity);
  finally
    FLock.Leave;
  end;
end;

class procedure TACLSoftwareImplBlendMode.InitializeMatrix(
  var AMatrix: PACLPixelMap; AProc: TCalculateMatrixProc);
var
  ASource, ATarget: Byte;
begin
  if AMatrix = nil then
  begin
    AMatrix := AllocMem(SizeOf(TACLPixelMap));
    for ASource := 0 to MaxByte do
      for ATarget := 0 to MaxByte do
        AMatrix[ASource, ATarget] := EnsureRange(AProc(ASource, ATarget), 0, MaxByte);
  end;
end;

class procedure TACLSoftwareImplBlendMode.ProcessAlphaBlend(Chunk: TChunk);
begin
  while Chunk.Count > 0 do
  begin
    TACLColors.AlphaBlend(Chunk.Target^, Chunk.Source^, FWorkOpacity);
    Inc(Chunk.Source);
    Inc(Chunk.Target);
    Dec(Chunk.Count);
  end;
end;

class procedure TACLSoftwareImplBlendMode.ProcessByMatrix(Chunk: TChunk);
var
  LSource: TACLPixel32;
  LTarget: TACLPixel32;
begin
  while Chunk.Count > 0 do
  begin
    TAlphaColor(LSource) := PAlphaColor(Chunk.Source)^;
    if LSource.A > 0 then
    begin
      if LSource.A < MaxByte then
      begin
        LSource.G := TACLColors.UnpremultiplyTable[LSource.G, LSource.A];
        LSource.B := TACLColors.UnpremultiplyTable[LSource.B, LSource.A];
        LSource.R := TACLColors.UnpremultiplyTable[LSource.R, LSource.A];
      end;

      TAlphaColor(LTarget) := TAlphaColor(Chunk.Target^);
      if LTarget.A = MaxByte then
      begin
        LSource.B := FWorkMatrix[LSource.B, LTarget.B];
        LSource.G := FWorkMatrix[LSource.G, LTarget.G];
        LSource.R := FWorkMatrix[LSource.R, LTarget.R];
      end
      else
        if LTarget.A > 0 then
        begin
          LTarget.R := TACLColors.PremultiplyTable[FWorkMatrix[LSource.R, LTarget.R], LTarget.A];
          LTarget.G := TACLColors.PremultiplyTable[FWorkMatrix[LSource.G, LTarget.G], LTarget.A];
          LTarget.B := TACLColors.PremultiplyTable[FWorkMatrix[LSource.B, LTarget.B], LTarget.A];

          LTarget.A := MaxByte - LTarget.A;

          LSource.R := TACLColors.PremultiplyTable[LSource.R, LTarget.A] + LTarget.R;
          LSource.G := TACLColors.PremultiplyTable[LSource.G, LTarget.A] + LTarget.G;
          LSource.B := TACLColors.PremultiplyTable[LSource.B, LTarget.A] + LTarget.B;
        end;

      if LSource.A < MaxByte then
      begin
        LSource.R := TACLColors.PremultiplyTable[LSource.R, LSource.A];
        LSource.B := TACLColors.PremultiplyTable[LSource.B, LSource.A];
        LSource.G := TACLColors.PremultiplyTable[LSource.G, LSource.A];
      end;

      TACLColors.AlphaBlend(Chunk.Target^, LSource, FWorkOpacity);
    end;
    Inc(Chunk.Source);
    Inc(Chunk.Target);
    Dec(Chunk.Count);
  end;
end;

class procedure TACLSoftwareImplBlendMode.ProcessGrayscale(Chunk: TChunk);
var
  LSource: TACLPixel32;
begin
  while Chunk.Count > 0 do
  begin
    TAlphaColor(LSource) := PAlphaColor(Chunk.Target)^;
    TACLColors.Grayscale(LSource);
    TACLColors.AlphaBlend(Chunk.Target^, LSource,
      TACLColors.PremultiplyTable[FWorkOpacity, Chunk.Source^.A]);
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

procedure TACLSoftwareImplGaussianBlur.Apply(AColors: PACLPixel32; AWidth, AHeight: Integer);

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
  I, J, K: Integer;
  LDivSum: Integer;
  LDivValue: Integer;
begin
  FRadius := ARadius;
  LDivValue := 2 * FRadius + 1;
  FStackOffset := LDivValue - FRadius;
  LDivSum := Sqr((LDivValue + 1) shr 1);

  FDivValues := AllocMem(256 * LDivSum * SizeOf(Integer));
  for I := 0 to 256 * LDivSum - 1 do
    FDivValues^[I] := I div LDivSum;

  FStack := AllocMem(LDivValue * SizeOf(TAlphaColor));
  FStackOffsets := AllocMem(2 * LDivValue * SizeOf(Integer));
  for I := 0 to 2 * LDivValue - 1 do
    FStackOffsets[I] := I mod LDivValue;
  for I := -FRadius to FRadius do
  begin
    K := FRadius + 1 - FastAbs(I);
    for J := 0 to 255 do
      FRadiusBias[I][J] := K * J;
  end;
  FLock := TACLCriticalSection.Create;
end;

destructor TACLSoftwareImplStackBlur.Destroy;
begin
  FreeAndNil(FLock);
  FreeMem(FDivValues);
  FreeMem(FStackOffsets);
  FreeMem(FStack);
  inherited;
end;

class function TACLSoftwareImplStackBlur.CreateBlurFilterCore(ARadius: Integer): IACLBlurFilterCore;
begin
  Result := TACLSoftwareImplStackBlur.Create(ARadius);
end;

class destructor TACLSoftwareImplStackBlur.Destroy;
begin
  FreeAndNil(FBufferA);
  FreeAndNil(FBufferB);
  FreeAndNil(FBufferG);
  FreeAndNil(FBufferR);
  FreeAndNil(FBufferM);
end;

class procedure TACLSoftwareImplStackBlur.Register;
begin
  TACLBlurFilter.FCreateCoreProc := CreateBlurFilterCore;
end;

class function TACLSoftwareImplStackBlur.GetBuffer(
  var ABuffer: TACLByteBuffer; ASize: Integer): TACLByteBuffer;
begin
  Result := AtomicExchange(Pointer(ABuffer), nil);
  if (Result = nil) or (Result.Size < ASize) then
  begin
    Result.Free;
    Result := TACLByteBuffer.Create(ASize);
  end;
end;

function TACLSoftwareImplStackBlur.GetSize: Integer;
begin
  Result := FRadius;
end;

procedure TACLSoftwareImplStackBlur.Apply(AColors: PACLPixel32; AWidth, AHeight: Integer);
{$PUSHOPT}
{$OPTIMIZATION ON}
{$Q-}{$R-}
var
  LBufferA: TACLByteBuffer;
  LBufferB: TACLByteBuffer;
  LBufferG: TACLByteBuffer;
  LBufferM: TACLByteBuffer;
  LBufferR: TACLByteBuffer;
  LColor: PACLPixel32;
  LColors: PAlphaColorArray absolute AColors;
  LInputSumA: Integer;
  LInputSumB: Integer;
  LInputSumG: Integer;
  LInputSumR: Integer;
  LOutputSumA: Integer;
  LOutputSumB: Integer;
  LOutputSumG: Integer;
  LOutputSumR: Integer;
  LRadiusBias: PByteArrayOfInt32;
  LSize: Integer;
  LStack: PACLPixel32;
  LStackCursor: Integer;
  LSumA: Integer;
  LSumB: Integer;
  LSumG: Integer;
  LSumR: Integer;
  LValue: TAlphaColor;
  M: PInteger;
  R, G, B, A: PByteArray;
  X, Y, I, K: Integer;
  Yp, Yi, Yw: Integer;
  Wi, Hi: Integer;
begin
  if FRadius < 1 then
    Exit;

  FLock.Enter;
  try
    Wi := AWidth - 1;
    Hi := AHeight - 1;

    LSize := AWidth * AHeight;
    LBufferA := GetBuffer(FBufferA, LSize);
    LBufferR := GetBuffer(FBufferR, LSize);
    LBufferG := GetBuffer(FBufferG, LSize);
    LBufferB := GetBuffer(FBufferB, LSize);
    LSize := Max(AWidth, AHeight) * SizeOf(Integer);
    LBufferM := GetBuffer(FBufferM, LSize);

    A := PByteArray(LBufferA.Data);
    R := PByteArray(LBufferR.Data);
    G := PByteArray(LBufferG.Data);
    B := PByteArray(LBufferB.Data);

    Yw := 0;
    Yi := 0;

  {$REGION ' Horizontal '}
    M := PInteger(LBufferM.Data);
    for X := 0 to AWidth - 1 do
    begin
      M^ := Min(X + FRadius + 1, Wi);
      Inc(M);
    end;
    for Y := 0 to AHeight - 1 do
    begin
      LInputSumR := 0;
      LInputSumG := 0;
      LInputSumB := 0;
      LInputSumA := 0;

      LOutputSumR := 0;
      LOutputSumG := 0;
      LOutputSumB := 0;
      LOutputSumA := 0;

      LSumR := 0;
      LSumG := 0;
      LSumB := 0;
      LSumA := 0;

      LRadiusBias := @FRadiusBias[-FRadius];
      LStack := @FStack[0];
      LValue := LColors[Yi];
      for I := -FRadius to 0 do
      begin
        PAlphaColor(LStack)^ := LValue;
        Inc(LSumR, LRadiusBias[LStack^.R]);
        Inc(LSumG, LRadiusBias[LStack^.G]);
        Inc(LSumB, LRadiusBias[LStack^.B]);
        Inc(LSumA, LRadiusBias[LStack^.A]);
        Inc(LOutputSumR, LStack^.R);
        Inc(LOutputSumG, LStack^.G);
        Inc(LOutputSumB, LStack^.B);
        Inc(LOutputSumA, LStack^.A);
        Inc(LRadiusBias);
        Inc(LStack);
      end;
      for I := 1 to FRadius do
      begin
        PAlphaColor(LStack)^ := LColors[Yi + Min(I, Wi)];
        Inc(LSumR, LRadiusBias[LStack^.R]);
        Inc(LSumG, LRadiusBias[LStack^.G]);
        Inc(LSumB, LRadiusBias[LStack^.B]);
        Inc(LSumA, LRadiusBias[LStack^.A]);
        Inc(LInputSumR, LStack^.R);
        Inc(LInputSumG, LStack^.G);
        Inc(LInputSumB, LStack^.B);
        Inc(LInputSumA, LStack^.A);
        Inc(LRadiusBias);
        Inc(LStack);
      end;
      LStackCursor := FRadius;

      M := PInteger(LBufferM.Data);
      for X := 0 to AWidth - 1 do
      begin
        R[Yi] := FDivValues[LSumR];
        G[Yi] := FDivValues[LSumG];
        B[Yi] := FDivValues[LSumB];
        A[Yi] := FDivValues[LSumA];

        Dec(LSumR, LOutputSumR);
        Dec(LSumG, LOutputSumG);
        Dec(LSumB, LOutputSumB);
        Dec(LSumA, LOutputSumA);

        LStack := @FStack[FStackOffsets[LStackCursor + FStackOffset]];

        Dec(LOutputSumR, LStack^.R);
        Dec(LOutputSumG, LStack^.G);
        Dec(LOutputSumB, LStack^.B);
        Dec(LOutputSumA, LStack^.A);

        PAlphaColor(LStack)^ := LColors[Yw + M^];

        Inc(LInputSumR, LStack^.R);
        Inc(LInputSumG, LStack^.G);
        Inc(LInputSumB, LStack^.B);
        Inc(LInputSumA, LStack^.A);

        Inc(LSumR, LInputSumR);
        Inc(LSumG, LInputSumG);
        Inc(LSumB, LInputSumB);
        Inc(LSumA, LInputSumA);

        LStackCursor := FStackOffsets[LStackCursor + 1];
        LStack := @FStack[LStackCursor];

        Inc(LOutputSumR, LStack^.R);
        Inc(LOutputSumG, LStack^.G);
        Inc(LOutputSumB, LStack^.B);
        Inc(LOutputSumA, LStack^.A);

        Dec(LInputSumR, LStack^.R);
        Dec(LInputSumG, LStack^.G);
        Dec(LInputSumB, LStack^.B);
        Dec(LInputSumA, LStack^.A);

        Inc(M);
        Inc(Yi);
      end;
      Inc(Yw, AWidth);
    end;
  {$ENDREGION}

  {$REGION ' Vertical '}
    M := PInteger(LBufferM.Data);
    for Y := 0 to AHeight - 1 do
    begin
      M^ := Min(Y + FRadius + 1, Hi) * AWidth;
      Inc(M);
    end;
    for X := 0 to AWidth - 1 do
    begin
      LInputSumR := 0;
      LInputSumG := 0;
      LInputSumB := 0;
      LInputSumA := 0;

      LOutputSumR := 0;
      LOutputSumG := 0;
      LOutputSumB := 0;
      LOutputSumA := 0;

      LSumR := 0;
      LSumG := 0;
      LSumB := 0;
      LSumA := 0;

      LStack := @FStack[0];
      LRadiusBias := @FRadiusBias[-FRadius];
      Yp := -FRadius * AWidth;

      for I := -FRadius to 0 do
      begin
        Yi := X;
        if Yp > 0 then
          Inc(Yi, Yp);
        //if I < Hi then
        //  Inc(Yp, AWidth);
        Inc(Yp, AWidth);

        LStack^.R := R[Yi];
        LStack^.G := G[Yi];
        LStack^.B := B[Yi];
        LStack^.A := A[Yi];

        Inc(LSumR, LRadiusBias[LStack^.R]);
        Inc(LSumG, LRadiusBias[LStack^.G]);
        Inc(LSumB, LRadiusBias[LStack^.B]);
        Inc(LSumA, LRadiusBias[LStack^.A]);
        Inc(LRadiusBias);

        Inc(LOutputSumR, LStack^.R);
        Inc(LOutputSumG, LStack^.G);
        Inc(LOutputSumB, LStack^.B);
        Inc(LOutputSumA, LStack^.A);
        Inc(LStack);
      end;
      for I := 1 to FRadius do
      begin
        Yi := X;
        if Yp > 0 then
          Inc(Yi, Yp);
        if I < Hi then
          Inc(Yp, AWidth);

        LStack^.R := R[Yi];
        LStack^.G := G[Yi];
        LStack^.B := B[Yi];
        LStack^.A := A[Yi];

        Inc(LSumR, LRadiusBias[LStack^.R]);
        Inc(LSumG, LRadiusBias[LStack^.G]);
        Inc(LSumB, LRadiusBias[LStack^.B]);
        Inc(LSumA, LRadiusBias[LStack^.A]);
        Inc(LRadiusBias);

        Inc(LInputSumR, LStack^.R);
        Inc(LInputSumG, LStack^.G);
        Inc(LInputSumB, LStack^.B);
        Inc(LInputSumA, LStack^.A);
        Inc(LStack);
      end;

      LColor := @LColors^[X];
      LStackCursor := FRadius;
      M := PInteger(LBufferM.Data);
      for Y := 0 to AHeight - 1 do
      begin
        LColor^.B := FDivValues[LSumB];
        LColor^.G := FDivValues[LSumG];
        LColor^.R := FDivValues[LSumR];
        LColor^.A := FDivValues[LSumA];
        Inc(LColor, AWidth);

        Dec(LSumR, LOutputSumR);
        Dec(LSumG, LOutputSumG);
        Dec(LSumB, LOutputSumB);
        Dec(LSumA, LOutputSumA);

        LStack := @FStack[FStackOffsets[LStackCursor + FStackOffset]];

        Dec(LOutputSumR, LStack^.R);
        Dec(LOutputSumG, LStack^.G);
        Dec(LOutputSumB, LStack^.B);
        Dec(LOutputSumA, LStack^.A);

        K := X + M^;
        Inc(M);
        LStack^.R := R[K];
        LStack^.G := G[K];
        LStack^.B := B[K];
        LStack^.A := A[K];

        Inc(LInputSumR, LStack^.R);
        Inc(LInputSumG, LStack^.G);
        Inc(LInputSumB, LStack^.B);
        Inc(LInputSumA, LStack^.A);

        Inc(LSumR, LInputSumR);
        Inc(LSumG, LInputSumG);
        Inc(LSumB, LInputSumB);
        Inc(LSumA, LInputSumA);

        LStackCursor := FStackOffsets[LStackCursor + 1];
        LStack := @FStack[LStackCursor];

        Inc(LOutputSumR, LStack^.R);
        Inc(LOutputSumG, LStack^.G);
        Inc(LOutputSumB, LStack^.B);
        Inc(LOutputSumA, LStack^.A);

        Dec(LInputSumR, LStack^.R);
        Dec(LInputSumG, LStack^.G);
        Dec(LInputSumB, LStack^.B);
        Dec(LInputSumA, LStack^.A);
      end;
    end;
  {$ENDREGION}

    TObject(AtomicExchange(Pointer(FBufferA), Pointer(LBufferA))).Free;
    TObject(AtomicExchange(Pointer(FBufferR), Pointer(LBufferR))).Free;
    TObject(AtomicExchange(Pointer(FBufferG), Pointer(LBufferG))).Free;
    TObject(AtomicExchange(Pointer(FBufferB), Pointer(LBufferB))).Free;
    TObject(AtomicExchange(Pointer(FBufferM), Pointer(LBufferM))).Free;
  finally
    FLock.Leave;
  end;
{$POPOPT}
end;

{$ENDREGION}

{$REGION ' Blur '}

{ TACLBlurFilter }

class constructor TACLBlurFilter.Create;
begin
  FShare := TACLValueCacheManager<Integer, IACLBlurFilterCore>.Create(8);
end;

class destructor TACLBlurFilter.Destroy;
begin
  FreeAndNil(FShare);
end;

class procedure TACLBlurFilter.FlushCache;
begin
  FShare.Clear;
end;

procedure TACLBlurFilter.Apply(ALayer: TACLBaseDib);
begin
  if Size > 0 then
    FCore.Apply(ALayer.Colors, ALayer.Width, ALayer.Height);
end;

procedure TACLBlurFilter.Apply(AColors: PACLPixel32; AWidth, AHeight: Integer);
begin
  if Size > 0 then
    FCore.Apply(AColors, AWidth, AHeight);
end;

procedure TACLBlurFilter.SetRadius(AValue: Integer);
begin
  AValue := EnsureRange(AValue, 0, MaxRadius);
  if FRadius <> AValue then
  begin
    FSize := 0;
    FCore := nil;
    FRadius := AValue;
    if FRadius > 0 then
    begin
      if not FShare.Get(FRadius, FCore) then
      begin
        FCore := FCreateCoreProc(AValue);
        FShare.Add(AValue, FCore);
      end;
      FSize := FCore.GetSize;
    end;
  end;
end;

{$ENDREGION}

{$REGION ' Abstract 2D Render '}

{ TACL2DRenderResource }

constructor TACL2DRenderResource.Create(AOwner: TACL2DRender);
begin
  FOwner := AOwner;
  if AOwner <> nil then
    FOwnerSerial := AOwner.Serial;
end;

procedure TACL2DRenderResource.Release;
begin
  FOwnerSerial := 0;
  FOwner := nil;
end;

{ TACL2DRenderImage }

destructor TACL2DRenderImage.Destroy;
begin
  FreeAndNil(FOwnedData);
  FreeMem(FOwnedDataPtr);
  inherited;
end;

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

constructor TACL2DRender.Create;
begin
  FSerial := acRandom(MaxInt) + 1;
  FLock := TACLCriticalSection.Create(Self);
end;

destructor TACL2DRender.Destroy;
begin
  FreeAndNil(FLock);
  inherited Destroy;
end;

procedure TACL2DRender.BeginPaint(DC: HDC);
var
  LRect: TRect;
begin
  LRect := NullRect;
  GetClipBox(DC, {$IFDEF FPC}@{$ENDIF}LRect);
  BeginPaint(DC, LRect);
end;

procedure TACL2DRender.BeginPaint(DC: HDC; const BoxRect: TRect);
begin
  BeginPaint(DC, BoxRect, BoxRect)
end;

procedure TACL2DRender.BeginPaint(ACanvas: TCanvas);
begin
  BeginPaint(ACanvas.Handle);
end;

function TACL2DRender.CreateImage(Image: TACLImage;
  Usage: TACL2DRenderSourceUsage = suCopy): TACL2DRenderImage;
{$IFDEF FPC}
begin
  if not Image.Empty then
  begin
    if Usage = suOwned then
    begin
      Result := CreateImage(TACLImageAccess(Image).Handle, suReference);
      Result.FOwnedData := Image;
    end
    else
      Result := CreateImage(TACLImageAccess(Image).Handle, Usage);
  end
{$ELSE}
var
  LAlphaFormat: TAlphaFormat;
  LData: TBitmapData;
  LPixelFormat: Integer;
begin
  LPixelFormat := TACLImageAccess(Image).GetPixelFormat;
  if GetPixelFormatSize(LPixelFormat) <> 32 then
    LPixelFormat := PixelFormat32bppARGB;
  if TACLImageAccess(Image).BeginLock(LData, LPixelFormat) then
  try
    case LData.PixelFormat of
      PixelFormat32bppARGB:
        LAlphaFormat := afDefined;
      PixelFormat32bppPARGB:
        LAlphaFormat := afPremultiplied;
      PixelFormat32bppRGB:
        LAlphaFormat := afIgnored;
    else
      raise EInvalidArgument.Create('Unexpected pixel format');
    end;
    if Usage = suOwned then
    begin
      Result := CreateImage(LData.Scan0, LData.Width, LData.Height, LAlphaFormat, suReference);
      Result.FOwnedData := Image;
    end
    else
      Result := CreateImage(LData.Scan0, LData.Width, LData.Height, LAlphaFormat, Usage);
  finally
    TACLImageAccess(Image).EndLock(LData);
  end
{$ENDIF}
  else
    Result := nil;
end;

function TACL2DRender.CreateImage(Image: TACLDib; Usage: TACL2DRenderSourceUsage): TACL2DRenderImage;
begin
  if Image.Empty then
    Exit(nil);
  if Usage = suOwned then
  begin
    Result := CreateImage(Image.Colors, Image.Width, Image.Height, afPremultiplied, suReference);
    Result.FOwnedData := Image;
  end
  else
    Result := CreateImage(Image.Colors, Image.Width, Image.Height, afPremultiplied, Usage);
end;

function TACL2DRender.CreateImageAttributes: TACL2DRenderImageAttributes;
begin
  Result := TACL2DRenderImageAttributes.Create(Self);
end;

procedure TACL2DRender.DrawImage(Image: TACLDib; const TargetRect: TRect; Cache: PACL2DRenderImage);
var
  LImage: TACL2DRenderImage;
begin
  if Cache <> nil then
  begin
    if not IsValid(Cache^) then
    begin
      FreeAndNil(Cache^);
      Cache^ := CreateImage(Image, suReference);
    end;
    DrawImage(Cache^, TargetRect);
  end
  else
  begin
    LImage := CreateImage(Image, suReference);
    try
      DrawImage(LImage, TargetRect);
    finally
      LImage.Free;
    end;
  end;
end;

function TACL2DRender.IsValid(const AResource: TACL2DRenderResource): Boolean;
begin
  Result := (AResource <> nil) and
    (AResource.FOwner = Self) and
    (AResource.FOwnerSerial = Serial);
end;

procedure TACL2DRender.DrawImage(
  Image: TACL2DRenderImage; const TargetRect: TRect; Alpha: Byte);
begin
  DrawImage(Image, TargetRect, Image.ClientRect, Alpha);
end;

procedure TACL2DRender.TileImage(Image: TACL2DRenderImage;
  const TargetRect, SourceRect: TRect; Attributes: TACL2DRenderImageAttributes);
var
  LClipData: TACL2DRenderRawData;
  R: TRect;
  W, H: Integer;
  X, XCount: Integer;
  Y, YCount: Integer;
begin
  W := SourceRect.Width;
  H := SourceRect.Height;
  XCount := acCalcPatternCount(TargetRect.Width, W);
  YCount := acCalcPatternCount(TargetRect.Height, H);

  if Clip(TargetRect, LClipData) then
  try
    R := TargetRect.Split(srTop, H);
    for Y := 1 to YCount do
    begin
      R.Left := TargetRect.Left;
      R.Right := TargetRect.Left + W;
      for X := 1 to XCount do
      begin
        DrawImage(Image, R, SourceRect, Attributes);
        Inc(R.Right, W);
        Inc(R.Left, W);
      end;
      Inc(R.Bottom, H);
      Inc(R.Top, H);
    end;
  finally
    ClipRestore(LClipData);
  end;
end;

procedure TACL2DRender.DrawEllipse(const R: TRect;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  DrawEllipse(R.Left, R.Top, R.Right, R.Bottom, Color, Width, Style);
end;

procedure TACL2DRender.DrawRectangle(const R: TRect;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  DrawRectangle(R.Left, R.Top, R.Right, R.Bottom, Color, Width, Style)
end;

procedure TACL2DRender.DrawCurve(AColor: TAlphaColor;
  const APoints: array of TPoint; ATension, APenWidth: Single);
begin
  Line(APoints, AColor, APenWidth);
end;

procedure TACL2DRender.FillCurve(AColor: TAlphaColor;
  const APoints: array of TPoint; ATension: Single);
begin
  FillPolygon(APoints, AColor);
end;

procedure TACL2DRender.Ellipse(const R: TRect;
  Color, StrokeColor: TAlphaColor; StrokeWidth: Single; StrokeStyle: TACL2DRenderStrokeStyle);
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

procedure TACL2DRender.Line(const Points: array of TPoint;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
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

function TACL2DRender.MeasureText(const Text: string; Font: TFont;
  MaxWidth: Integer = -1; WordWrap: Boolean = False): TSize;
var
  LRect: TRect;
begin
  LRect := Rect(0, 0, IfThen(MaxWidth > 0, MaxWidth, MaxWord), MaxWord);
  MeasureText(Text, Font, LRect, WordWrap);
  Result := LRect.Size;
end;

function TACL2DRender.ModifyOrigin(DeltaX, DeltaY: Integer): TPoint;
begin
  Result := FOrigin;
  FOrigin.Offset(-DeltaX, -DeltaY);
end;

procedure TACL2DRender.SetOrigin(const Origin: TPoint);
begin
  FOrigin := Origin;
end;

procedure TACL2DRender.SetPixelOffsetMode(AMode: TACLImagePixelOffsetMode);
begin
  // unsupported
end;

procedure TACL2DRender.SetTextAntialiasMode(AMode: TACL2DRenderTextAntialiasMode);
begin
  // unsupported
end;

procedure TACL2DRender.SetGeometrySmoothing(AValue: TACLBoolean);
begin
  // unsupported
end;

procedure TACL2DRender.SetImageSmoothing(AValue: TACLBoolean);
begin
  // unsupported
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
  FreeAndNil(ExPainter);
end.
