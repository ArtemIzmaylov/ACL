{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*         Extended Graphic Library          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.Ex;

{$I ACL.Config.inc}

interface

uses
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

{$REGION 'Layers'}

  { TACLBitmapLayer }

  TACLBitmapLayer = class
  strict private
    FBitmap: HBITMAP;
    FCanvas: TCanvas;
    FColorCount: Integer;
    FColors: PRGBQuadArray;
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
    procedure Assign(ALayer: TACLBitmapLayer);
    procedure AssignParams(DC: HDC);
    function Clone(out AData: PRGBQuadArray): Boolean;
    function CoordToFlatIndex(X, Y: Integer): Integer;
    //
    procedure ApplyTint(const AColor: TColor); overload;
    procedure ApplyTint(const AColor: TRGBQuad); overload;
    procedure Flip(AHorizontally, AVertically: Boolean);
    procedure MakeDisabled;
    procedure MakeMirror(ASize: Integer);
    procedure MakeOpaque;
    procedure MakeTransparent(AColor: TColor);
    procedure Premultiply(R: TRect); overload;
    procedure Premultiply; overload;
    procedure Reset(const R: TRect); overload;
    procedure Reset; overload;
    procedure Resize(ANewWidth, ANewHeight: Integer); overload;
    procedure Resize(const R: TRect); overload;
    //
    procedure DrawBlend(DC: HDC; const P: TPoint; AAlpha: Byte = MaxByte); overload;
    procedure DrawBlend(DC: HDC; const P: TPoint; AMode: TACLBlendMode; AAlpha: Byte = MaxByte); overload;
    procedure DrawBlend(DC: HDC; const R: TRect; AAlpha: Byte = MaxByte; ASmoothStretch: Boolean = False); overload;
    procedure DrawCopy(DC: HDC; const P: TPoint); overload;
    procedure DrawCopy(DC: HDC; const R: TRect; ASmoothStretch: Boolean = False); overload;
    //
    property Bitmap: HBITMAP read FBitmap;
    property Canvas: TCanvas read GetCanvas;
    property ClientRect: TRect read GetClientRect;
    property ColorCount: Integer read FColorCount;
    property Colors: PRGBQuadArray read FColors;
    property Empty: Boolean read GetEmpty;
    property Handle: HDC read FHandle;
    property Height: Integer read FHeight;
    property Width: Integer read FWidth;
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
    procedure ApplyMaskCore(AMask: PByte; AColors: PRGBQuad; ACount: Integer); overload; inline;
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

{$REGION 'Blur'}

  { IACLBlurFilterCore }

  IACLBlurFilterCore = interface
  ['{89DD6E84-C6CB-4367-90EC-3943D5593372}']
    procedure Apply(LayerDC: HDC; Colors: PRGBQuad; Width, Height: Integer);
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
    procedure Apply(ALayerDC: HDC; AColors: PRGBQuad; AWidth, AHeight: Integer); overload;
    //
    property Radius: Integer read FRadius write SetRadius;
    property Size: Integer read FSize;
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

{$REGION 'Software-based filters implementation'}
type

  { TACLSoftwareImplBlendMode }

  TACLSoftwareImplBlendMode = class
  strict private type
  {$REGION 'Internal Types'}
    TChunk = class
    protected
      Count: Integer;
      Source: PRGBQuad;
      Target: PRGBQuad;
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
      FBuffer: PRGBQuad;
      FFilter: TACLSoftwareImplGaussianBlur;
    protected
      Colors: PRGBQuad;
      Index1: Integer;
      Index2: Integer;
      LineWidth: Integer;
      ScanCount: Integer;
      ScanStep: Integer;
    public
      constructor Create(AFilter: TACLSoftwareImplGaussianBlur; AMaxLineSize: Integer);
      destructor Destroy; override;
      procedure ApplyTo; overload;
      procedure ApplyTo(AColors: PRGBQuad; ACount, AStep: Integer); overload;
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
    procedure Apply(DC: HDC; AColors: PRGBQuad; AWidth, AHeight: Integer);
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
    procedure Apply(DC: HDC; AColors: PRGBQuad; AWidth, AHeight: Integer);
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
  ASourceScan: PRGBQuad;
  ATargetScan: PRGBQuad;
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
  ASource: TRGBQuad;
  ATarget: TRGBQuad;
begin
  while Chunk.Count > 0 do
  begin
    PAlphaColor(@ASource)^ := PAlphaColor(Chunk.Source)^;
    if ASource.rgbReserved > 0 then
    begin
      PAlphaColor(@ATarget)^ := PAlphaColor(Chunk.Target)^;

      if ATarget.rgbReserved = MaxByte then
      begin
        TACLColors.Unpremultiply(ASource);
        ASource.rgbBlue  := FWorkMatrix[ASource.rgbBlue, ATarget.rgbBlue];
        ASource.rgbGreen := FWorkMatrix[ASource.rgbGreen, ATarget.rgbGreen];
        ASource.rgbRed   := FWorkMatrix[ASource.rgbRed, ATarget.rgbRed];
        TACLColors.Premultiply(ASource);
      end
      else
        if ATarget.rgbReserved > 0 then
        begin
          TACLColors.Unpremultiply(ASource);
          AAlpha := MaxByte - ATarget.rgbReserved;
          ASource.rgbRed := TACLColors.PremultiplyTable[ASource.rgbRed, AAlpha] +
            TACLColors.PremultiplyTable[FWorkMatrix[ASource.rgbRed, ATarget.rgbRed], ATarget.rgbReserved];
          ASource.rgbBlue := TACLColors.PremultiplyTable[ASource.rgbBlue, AAlpha] +
            TACLColors.PremultiplyTable[FWorkMatrix[ASource.rgbBlue, ATarget.rgbBlue], ATarget.rgbReserved];
          ASource.rgbGreen := TACLColors.PremultiplyTable[ASource.rgbGreen, AAlpha] +
            TACLColors.PremultiplyTable[FWorkMatrix[ASource.rgbGreen, ATarget.rgbGreen], ATarget.rgbReserved];
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
  ASource: TRGBQuad;
begin
  while Chunk.Count > 0 do
  begin
    ASource := Chunk.Target^;
    TACLColors.Grayscale(ASource);
    TACLColors.AlphaBlend(Chunk.Target^, ASource, TACLColors.PremultiplyTable[FWorkOpacity, Chunk.Source^.rgbReserved]);
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

procedure TACLSoftwareImplGaussianBlur.Apply(DC: HDC; AColors: PRGBQuad; AWidth, AHeight: Integer);

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
  FBuffer := AllocMem((AMaxLineSize + 2 * FFilter.Size + 1) * SizeOf(TRGBQuad))
end;

destructor TACLSoftwareImplGaussianBlur.TChunk.Destroy;
begin
  FreeMem(FBuffer);
  inherited Destroy;
end;

procedure TACLSoftwareImplGaussianBlur.TChunk.ApplyTo;
var
  AScan: PRGBQuad;
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

procedure TACLSoftwareImplGaussianBlur.TChunk.ApplyTo(AColors: PRGBQuad; ACount, AStep: Integer);
var
  D: TRGBQuad;
  I, N: Integer;
  R, G, B: Integer;
  S, P: PRGBQuad;
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
    FastMove(P^, S^, ACount * SizeOf(TRGBQuad));
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
      Inc(R, FFilter.FWeights[N, S^.rgbRed]);
      Inc(G, FFilter.FWeights[N, S^.rgbGreen]);
      Inc(B, FFilter.FWeights[N, S^.rgbBlue]);
      Inc(S);
    end;
    AColors^.rgbBlue := B div FFilter.WeightResolution;
    AColors^.rgbGreen := G div FFilter.WeightResolution;
    AColors^.rgbRed := R div FFilter.WeightResolution;
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

procedure TACLSoftwareImplStackBlur.Apply(DC: HDC; AColors: PRGBQuad; AWidth, AHeight: Integer);
var
  AColor: PRGBQuad;
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
  AStackScan: PRGBQuad;
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
        Inc(ASumR, AStackScan.rgbRed * ARadiusBias);
        Inc(ASumG, AStackScan.rgbGreen * ARadiusBias);
        Inc(ASumB, AStackScan.rgbBlue * ARadiusBias);
        Inc(ASumA, AStackScan.rgbReserved * ARadiusBias);
        if I > 0 then
        begin
          Inc(AInputSumR, AStackScan.rgbRed);
          Inc(AInputSumG, AStackScan.rgbGreen);
          Inc(AInputSumB, AStackScan.rgbBlue);
          Inc(AInputSumA, AStackScan.rgbReserved);
        end
        else
        begin
          Inc(AOutputSumR, AStackScan.rgbRed);
          Inc(AOutputSumG, AStackScan.rgbGreen);
          Inc(AOutputSumB, AStackScan.rgbBlue);
          Inc(AOutputSumA, AStackScan.rgbReserved);
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

        Dec(AOutputSumR, AStackScan.rgbRed);
        Dec(AOutputSumG, AStackScan.rgbGreen);
        Dec(AOutputSumB, AStackScan.rgbBlue);
        Dec(AOutputSumA, AStackScan.rgbReserved);

        if Y = 0 then
          AMinValues[X] := Min(X + FRadius + 1, Wm);

        PAlphaColor(AStackScan)^ := PAlphaColorArray(AColors)[Yw + AMinValues[X]];

        Inc(AInputSumR, AStackScan.rgbRed);
        Inc(AInputSumG, AStackScan.rgbGreen);
        Inc(AInputSumB, AStackScan.rgbBlue);
        Inc(AInputSumA, AStackScan.rgbReserved);

        Inc(ASumR, AInputSumR);
        Inc(ASumG, AInputSumG);
        Inc(ASumB, AInputSumB);
        Inc(ASumA, AInputSumA);

        AStackCursor := FStackOffsets[AStackCursor + 1];
        AStackScan := @FStack[AStackCursor];

        Inc(AOutputSumR, AStackScan.rgbRed);
        Inc(AOutputSumG, AStackScan.rgbGreen);
        Inc(AOutputSumB, AStackScan.rgbBlue);
        Inc(AOutputSumA, AStackScan.rgbReserved);

        Dec(AInputSumR, AStackScan.rgbRed);
        Dec(AInputSumG, AStackScan.rgbGreen);
        Dec(AInputSumB, AStackScan.rgbBlue);
        Dec(AInputSumA, AStackScan.rgbReserved);

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

        AStackScan.rgbRed := R[Yi];
        AStackScan.rgbGreen := G[Yi];
        AStackScan.rgbBlue := B[Yi];
        AStackScan.rgbReserved := A[Yi];

        ARadiusBias := FRadiusBias[I];

        Inc(ASumR, R[Yi] * ARadiusBias);
        Inc(ASumG, G[Yi] * ARadiusBias);
        Inc(ASumB, B[Yi] * ARadiusBias);
        Inc(ASumA, A[Yi] * ARadiusBias);

        if I > 0 then
        begin
          Inc(AInputSumR, AStackScan.rgbRed);
          Inc(AInputSumG, AStackScan.rgbGreen);
          Inc(AInputSumB, AStackScan.rgbBlue);
          Inc(AInputSumA, AStackScan.rgbReserved);
        end
        else
        begin
          Inc(AOutputSumR, AStackScan.rgbRed);
          Inc(AOutputSumG, AStackScan.rgbGreen);
          Inc(AOutputSumB, AStackScan.rgbBlue);
          Inc(AOutputSumA, AStackScan.rgbReserved);
        end;

        if I < Hm then
          Inc(Yp, AWidth);
        Inc(AStackScan);
      end;

      AColor := @PAlphaColorArray(AColors)^[X];
      AStackCursor := FRadius;
      for Y := 0 to AHeight - 1 do
      begin
        AColor^.rgbBlue := FDivValues[ASumB];
        AColor^.rgbGreen := FDivValues[ASumG];
        AColor^.rgbRed := FDivValues[ASumR];
        AColor^.rgbReserved := FDivValues[ASumA];

        Dec(ASumR, AOutputSumR);
        Dec(ASumG, AOutputSumG);
        Dec(ASumB, AOutputSumB);
        Dec(ASumA, AOutputSumA);

        AStackScan := @FStack[FStackOffsets[AStackCursor + FStackOffset]];

        Dec(AOutputSumR, AStackScan.rgbRed);
        Dec(AOutputSumG, AStackScan.rgbGreen);
        Dec(AOutputSumB, AStackScan.rgbBlue);
        Dec(AOutputSumA, AStackScan.rgbReserved);

        if X = 0 then
          AMinValues[Y] := Min(Y + FRadius + 1, Hm) * AWidth;

        K := X + AMinValues[Y];
        AStackScan.rgbRed := R[K];
        AStackScan.rgbGreen := G[K];
        AStackScan.rgbBlue := B[K];
        AStackScan.rgbReserved := A[K];

        Inc(AInputSumR, AStackScan.rgbRed);
        Inc(AInputSumG, AStackScan.rgbGreen);
        Inc(AInputSumB, AStackScan.rgbBlue);
        Inc(AInputSumA, AStackScan.rgbReserved);

        Inc(ASumR, AInputSumR);
        Inc(ASumG, AInputSumG);
        Inc(ASumB, AInputSumB);
        Inc(ASumA, AInputSumA);

        AStackCursor := FStackOffsets[AStackCursor + 1];
        AStackScan := @FStack[AStackCursor];

        Inc(AOutputSumR, AStackScan.rgbRed);
        Inc(AOutputSumG, AStackScan.rgbGreen);
        Inc(AOutputSumB, AStackScan.rgbBlue);
        Inc(AOutputSumA, AStackScan.rgbReserved);

        Dec(AInputSumR, AStackScan.rgbRed);
        Dec(AInputSumG, AStackScan.rgbGreen);
        Dec(AInputSumB, AStackScan.rgbBlue);
        Dec(AInputSumA, AStackScan.rgbReserved);

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

{ TACLBitmapLayer }

constructor TACLBitmapLayer.Create(const R: TRect);
begin
  Create(acRectWidth(R), acRectHeight(R));
end;

constructor TACLBitmapLayer.Create(const S: TSize);
begin
  Create(S.cx, S.cy);
end;

constructor TACLBitmapLayer.Create(const W, H: Integer);
begin
  CreateHandles(W, H);
end;

destructor TACLBitmapLayer.Destroy;
begin
  FreeHandles;
  inherited Destroy;
end;

procedure TACLBitmapLayer.Assign(ALayer: TACLBitmapLayer);
begin
  if ALayer <> Self then
  begin
    Resize(ALayer.Width, ALayer.Height);
    FastMove(ALayer.Colors^, Colors^, ColorCount * SizeOf(TRGBQuad));
  end;
end;

procedure TACLBitmapLayer.AssignParams(DC: HDC);
begin
  SelectObject(Handle, GetCurrentObject(DC, OBJ_BRUSH));
  SelectObject(Handle, GetCurrentObject(DC, OBJ_FONT));
  SetTextColor(Handle, GetTextColor(DC));
end;

function TACLBitmapLayer.Clone(out AData: PRGBQuadArray): Boolean;
var
  ASize: Integer;
begin
  ASize := ColorCount * SizeOf(TRGBQuad);
  Result := ASize > 0;
  if Result then
  begin
    AData := AllocMem(ASize);
    FastMove(FColors^, AData^, ASize);
  end;
end;

function TACLBitmapLayer.CoordToFlatIndex(X, Y: Integer): Integer;
begin
  if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
    Result := X + Y * Width
  else
    Result := -1;
end;

procedure TACLBitmapLayer.ApplyTint(const AColor: TColor);
begin
  ApplyTint(TAlphaColor.FromColor(AColor).ToQuad);
end;

procedure TACLBitmapLayer.ApplyTint(const AColor: TRGBQuad);
var
  Q: PRGBQuad;
  I: Integer;
begin
  Q := @FColors^[0];
  for I := 0 to ColorCount - 1 do
  begin
    if Q^.rgbReserved > 0 then
    begin
      TACLColors.Unpremultiply(Q^);
      Q^.rgbBlue := AColor.rgbBlue;
      Q^.rgbGreen := AColor.rgbGreen;
      Q^.rgbRed := AColor.rgbRed;
      TACLColors.Premultiply(Q^);
    end;
    Inc(Q);
  end;
end;

procedure TACLBitmapLayer.DrawBlend(DC: HDC; const P: TPoint; AAlpha: Byte = 255);
begin
  DrawBlend(DC, Bounds(P.X, P.Y, Width, Height), AAlpha);
end;

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
  ALayer: TACLBitmapLayer;
begin
  if ASmoothStretch and not (Empty or acRectIsEqualSizes(R, ClientRect)) then
  begin
    if (GetClipBox(DC, AClipBox) <> NULLREGION) and IntersectRect(AClipBox, AClipBox, R) then
    begin
      AImage := TACLImage.Create(PRGBQuad(Colors), Width, Height);
      try
        AImage.StretchQuality := sqLowQuality;
        AImage.PixelOffsetMode := ipomHalf;

        // Layer is used for better performance
        ALayer := TACLBitmapLayer.Create(AClipBox);
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

procedure TACLBitmapLayer.DrawCopy(DC: HDC; const P: TPoint);
begin
  acBitBlt(DC, Handle, Bounds(P.X, P.Y, Width, Height), NullPoint);
end;

procedure TACLBitmapLayer.DrawCopy(DC: HDC; const R: TRect; ASmoothStretch: Boolean = False);
var
  AMode: Integer;
begin
  if ASmoothStretch and not acRectIsEqualSizes(R, ClientRect) then
  begin
    AMode := SetStretchBltMode(DC, HALFTONE);
    acStretchBlt(DC, Handle, R, ClientRect);
    SetStretchBltMode(DC, AMode);
  end
  else
    acStretchBlt(DC, Handle, R, ClientRect);
end;

procedure TACLBitmapLayer.Flip(AHorizontally, AVertically: Boolean);
begin
  TACLColors.Flip(Colors, Width, Height, AHorizontally, AVertically);
end;

procedure TACLBitmapLayer.MakeDisabled;
begin
  TACLColors.MakeDisabled(@FColors^[0], ColorCount);
end;

procedure TACLBitmapLayer.MakeMirror(ASize: Integer);
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

procedure TACLBitmapLayer.MakeOpaque;
var
  I: Integer;
  Q: PRGBQuad;
begin
  Q := @FColors^[0];
  for I := 0 to ColorCount - 1 do
  begin
    Q^.rgbReserved := $FF;
    Inc(Q);
  end;
end;

procedure TACLBitmapLayer.MakeTransparent(AColor: TColor);
var
  I: Integer;
  Q: PRGBQuad;
  R: TRGBQuad;
begin
  Q := @FColors^[0];
  R := TACLColors.ToQuad(AColor);
  for I := 0 to ColorCount - 1 do
  begin
    if TACLColors.CompareRGB(Q^, R) then
      TACLColors.Flush(Q^)
    else
      Q^.rgbReserved := $FF;
    Inc(Q);
  end;
end;

procedure TACLBitmapLayer.Premultiply(R: TRect);
var
  Y: Integer;
begin
  IntersectRect(R, R, ClientRect);
  for Y := R.Top to R.Bottom - 1 do
    TACLColors.Premultiply(@FColors^[Y * Width + R.Left], R.Right - R.Left - 1);
end;

procedure TACLBitmapLayer.Premultiply;
begin
  TACLColors.Premultiply(@FColors^[0], ColorCount);
end;

procedure TACLBitmapLayer.Reset;
var
  APrevPoint: TPoint;
begin
  SetWindowOrgEx(Handle, 0, 0, @APrevPoint);
  acResetRect(Handle, ClientRect);
  SetWindowOrgEx(Handle, APrevPoint.X, APrevPoint.Y, nil);
end;

procedure TACLBitmapLayer.Reset(const R: TRect);
begin
  acResetRect(Handle, R);
end;

procedure TACLBitmapLayer.Resize(const R: TRect);
begin
  Resize(acRectWidth(R), acRectHeight(R));
end;

procedure TACLBitmapLayer.Resize(ANewWidth, ANewHeight: Integer);
begin
  if (ANewWidth <> Width) or (ANewHeight <> Height) then
  begin
    FreeHandles;
    CreateHandles(ANewWidth, ANewHeight);
  end;
end;

procedure TACLBitmapLayer.CreateHandles(W, H: Integer);
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
end;

procedure TACLBitmapLayer.FreeHandles;
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

function TACLBitmapLayer.GetCanvas: TCanvas;
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

function TACLBitmapLayer.GetClientRect: TRect;
begin
  Result := Rect(0, 0, Width, Height);
end;

function TACLBitmapLayer.GetEmpty: Boolean;
begin
  Result := FColorCount = 0;
end;

{ TACLCacheLayer }

procedure TACLCacheLayer.AfterConstruction;
begin
  inherited AfterConstruction;
  IsDirty := True;
end;

function TACLCacheLayer.CheckNeedUpdate(const R: TRect): Boolean;
begin
  if not acRectIsEqualSizes(R, ClientRect) then
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
  AColor: PRGBQuad;
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
    AMask^ := AColor^.rgbReserved;

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

procedure TACLMaskLayer.ApplyMaskCore(AMask: PByte; AColors: PRGBQuad; ACount: Integer);
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
        //    C^.rgbReserved := TACLColors.PremultiplyTable[C^.rgbReserved, S^];
        //    TACLColors.Premultiply(C^);
        AColors^.rgbBlue := TACLColors.PremultiplyTable[AColors^.rgbBlue, AAlpha];
        AColors^.rgbGreen := TACLColors.PremultiplyTable[AColors^.rgbGreen, AAlpha];
        AColors^.rgbReserved := TACLColors.PremultiplyTable[AColors^.rgbReserved, AAlpha];
        AColors^.rgbRed := TACLColors.PremultiplyTable[AColors^.rgbRed, AAlpha];
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
  Apply(ALayer.Handle, PRGBQuad(ALayer.Colors), ALayer.Width, ALayer.Height);
end;

procedure TACLBlurFilter.Apply(ALayerDC: HDC; AColors: PRGBQuad; AWidth, AHeight: Integer);
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

initialization
  TACLSoftwareImplBlendMode.Register;
  TACLSoftwareImplStackBlur.Register;
finalization
  TACLSoftwareImplBlendMode.Unregister;
end.
