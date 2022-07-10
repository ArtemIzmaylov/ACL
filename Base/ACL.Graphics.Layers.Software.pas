{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*  Bitmap Layers, Software Implementation   *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.Layers.Software;

{$I ACL.Config.inc}

interface

uses
  UITypes, Types, Windows, SysUtils, Classes, Graphics, Messages, Math,
  // ACL
  ACL.Classes.Collections,
  ACL.Graphics,
  ACL.Graphics.Images,
  ACL.Graphics.Layers,
  ACL.Graphics.SkinImage,
  ACL.Math,
  ACL.Threading,
  ACL.Utils.Common;

type

  { TACLBlendModeSoftwareImpl }

  TACLBlendModeSoftwareImpl = class
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
    class procedure Initialize;
    class procedure Finalize;
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

  { TACLGaussianBlurSoftwareImpl }

  TACLGaussianBlurSoftwareImpl = class(TInterfacedObject, IACLBlurFilterCore)
  strict private type
  {$REGION 'Internal Types'}

    TChunk = class
    strict private
      FBuffer: PRGBQuad;
      FFilter: TACLGaussianBlurSoftwareImpl;
    protected
      Colors: PRGBQuad;
      Index1: Integer;
      Index2: Integer;
      LineWidth: Integer;
      ScanCount: Integer;
      ScanStep: Integer;
    public
      constructor Create(AFilter: TACLGaussianBlurSoftwareImpl; AMaxLineSize: Integer);
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
    class function DoCreateBlurFilterCore: IACLBlurFilterCore; static;
    // IACLBlurFilterCore
    procedure Apply(DC: HDC; AColors: PRGBQuad; AWidth, AHeight: Integer);
    function GetSize: Integer;
    procedure Setup(ARadius: Integer);
  end;

  { TACLStackBlurSoftwareImpl }

  // Stack Blur Algorithm by Mario Klingemann <mario@quasimondo.com>
  TACLStackBlurSoftwareImpl = class(TInterfacedObject, IACLBlurFilterCore)
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
    destructor Destroy; override;
    class function DoCreateBlurFilterCore: IACLBlurFilterCore; static;
    // IACLBlurFilterCore
    procedure Apply(DC: HDC; AColors: PRGBQuad; AWidth, AHeight: Integer);
    function GetSize: Integer;
    procedure Setup(ARadius: Integer);
  end;

implementation

uses
  ACL.FastCode;

{ TACLBlendModeSoftwareImpl }

class procedure TACLBlendModeSoftwareImpl.Initialize;
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

class procedure TACLBlendModeSoftwareImpl.Finalize;
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

class procedure TACLBlendModeSoftwareImpl.DoAddition(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FAdditionMatrix, CalculateAdditionMatrix, AAlpha);
end;

class procedure TACLBlendModeSoftwareImpl.DoDarken(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FDarkenMatrix, CalculateDarkenMatrix, AAlpha);
end;

class procedure TACLBlendModeSoftwareImpl.DoDifference(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FDifferenceMatrix, CalculateDifferenceMatrix, AAlpha);
end;

class procedure TACLBlendModeSoftwareImpl.DoDivide(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FDivideMatrix, CalculateDivideMatrix, AAlpha);
end;

class procedure TACLBlendModeSoftwareImpl.DoGrayScale(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, @ProcessGrayScale, AAlpha);
end;

class procedure TACLBlendModeSoftwareImpl.DoLighten(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FLightenMatrix, CalculateLightenMatrix, AAlpha);
end;

class procedure TACLBlendModeSoftwareImpl.DoMultiply(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FMultiplyMatrix, CalculateMultiplyMatrix, AAlpha);
end;

class procedure TACLBlendModeSoftwareImpl.DoNormal(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  AForegroundLayer.DrawBlend(ABackgroundLayer.Handle, NullPoint, AAlpha);
end;

class procedure TACLBlendModeSoftwareImpl.DoOverlay(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FOverlayMatrix, CalculateOverlayMatrix, AAlpha);
end;

class procedure TACLBlendModeSoftwareImpl.DoScreen(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FScreenMatrix, CalculateScreenMatrix, AAlpha);
end;

class procedure TACLBlendModeSoftwareImpl.DoSubstract(ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte);
begin
  Run(ABackgroundLayer, AForegroundLayer, FSubstractMatrix, CalculateSubstractMatrix, AAlpha);
end;

class procedure TACLBlendModeSoftwareImpl.Run(
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

class procedure TACLBlendModeSoftwareImpl.Run(
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

class function TACLBlendModeSoftwareImpl.BuildChunks(ATarget, ASource: TACLBitmapLayer): TChunks;
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

class procedure TACLBlendModeSoftwareImpl.InitializeMatrix(var AMatrix: PACLPixelMap; AProc: TCalculateMatrixProc);
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

class procedure TACLBlendModeSoftwareImpl.ProcessByMatrix(Chunk: TChunk);
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

class procedure TACLBlendModeSoftwareImpl.ProcessGrayScale(Chunk: TChunk);
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

class function TACLBlendModeSoftwareImpl.CalculateAdditionMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := ASource + ATarget;
end;

class function TACLBlendModeSoftwareImpl.CalculateDarkenMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := Min(ASource, ATarget);
end;

class function TACLBlendModeSoftwareImpl.CalculateDifferenceMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := Abs(ASource - ATarget);
end;

class function TACLBlendModeSoftwareImpl.CalculateDivideMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := MulDiv(256, ATarget, ASource + 1);
end;

class function TACLBlendModeSoftwareImpl.CalculateLightenMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := Max(ASource, ATarget);
end;

class function TACLBlendModeSoftwareImpl.CalculateMultiplyMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := (ASource * ATarget) shr 8;
end;

class function TACLBlendModeSoftwareImpl.CalculateOverlayMatrix(const ASource, ATarget: Integer): Integer;
begin
  if ATarget < 128 then
    Result := (2 * ASource * ATarget) shr 8
  else
    Result := MaxByte - 2 * ((MaxByte - ASource) * (MaxByte - ATarget)) shr 8;
end;

class function TACLBlendModeSoftwareImpl.CalculateScreenMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := MaxByte - ((MaxByte - ASource) * (MaxByte - ATarget)) shr 8;
end;

class function TACLBlendModeSoftwareImpl.CalculateSubstractMatrix(const ASource, ATarget: Integer): Integer;
begin
  Result := ATarget - ASource;
end;

{ TACLGaussianBlurSoftwareImpl }

class function TACLGaussianBlurSoftwareImpl.DoCreateBlurFilterCore: IACLBlurFilterCore;
begin
  Result := TACLGaussianBlurSoftwareImpl.Create;
end;

function TACLGaussianBlurSoftwareImpl.GetSize: Integer;
begin
  Result := FSize;
end;

procedure TACLGaussianBlurSoftwareImpl.Apply(DC: HDC; AColors: PRGBQuad; AWidth, AHeight: Integer);

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

procedure TACLGaussianBlurSoftwareImpl.Setup(ARadius: Integer);
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

{ TACLGaussianBlurSoftwareImpl.TChunk }

constructor TACLGaussianBlurSoftwareImpl.TChunk.Create(AFilter: TACLGaussianBlurSoftwareImpl; AMaxLineSize: Integer);
begin
  inherited Create;
  FFilter := AFilter;
  FBuffer := AllocMem((AMaxLineSize + 2 * FFilter.Size + 1) * SizeOf(TRGBQuad))
end;

destructor TACLGaussianBlurSoftwareImpl.TChunk.Destroy;
begin
  FreeMem(FBuffer);
  inherited Destroy;
end;

procedure TACLGaussianBlurSoftwareImpl.TChunk.ApplyTo;
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

procedure TACLGaussianBlurSoftwareImpl.TChunk.ApplyTo(AColors: PRGBQuad; ACount, AStep: Integer);
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

class procedure TACLGaussianBlurSoftwareImpl.Process(Chunk: Pointer);
begin
  TChunk(Chunk).ApplyTo;
end;

{ TACLStackBlurSoftwareImpl }

destructor TACLStackBlurSoftwareImpl.Destroy;
begin
  FreeMem(FDivValues);
  FreeMem(FStackOffsets);
  FreeMem(FStack);
  inherited;
end;

class function TACLStackBlurSoftwareImpl.DoCreateBlurFilterCore: IACLBlurFilterCore;
begin
  Result := TACLStackBlurSoftwareImpl.Create;
end;

function TACLStackBlurSoftwareImpl.GetSize: Integer;
begin
  Result := FRadius;
end;

procedure TACLStackBlurSoftwareImpl.Apply(DC: HDC; AColors: PRGBQuad; AWidth, AHeight: Integer);
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

procedure TACLStackBlurSoftwareImpl.Setup(ARadius: Integer);
var
  I: Integer;
begin
  if ARadius <> FRadius then
  begin
    FRadius := ARadius;
    FValueDiv := 2 * FRadius + 1;
    FStackOffset := FValueDiv - FRadius;
    FDivSum := Sqr((FValueDiv + 1) shr 1);

    ReallocMem(FDivValues, 256 * FDivSum * SizeOf(Integer));
    for I := 0 to 256 * FDivSum - 1 do
      FDivValues^[I] := I div FDivSum;

    ReallocMem(FStack, FValueDiv * SizeOf(TAlphaColor));
    ReallocMem(FStackOffsets, 2 * FValueDiv * SizeOf(Integer));
    for I := 0 to 2 * FValueDiv - 1 do
      FStackOffsets[I] := I mod FValueDiv;
    for I := -FRadius to FRadius do
      FRadiusBias[I] := FRadius + 1 - FastAbs(I);
  end;
end;

initialization
  TACLBlendModeSoftwareImpl.Initialize;
  FCreateBlurFilterCore := TACLStackBlurSoftwareImpl.DoCreateBlurFilterCore;

finalization
  TACLBlendModeSoftwareImpl.Finalize;
end.
