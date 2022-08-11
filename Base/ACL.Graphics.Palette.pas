{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*       Material Design like Palette        *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.Palette;

{$I ACL.Config.inc}

// Based on:
// https://android.googlesource.com/platform/frameworks/base.git/+/master/packages/SystemUI/src/com/android/systemui/statusbar/notification/MediaNotificationProcessor.java
// https://developer.android.com/training/material/palette-colors#extract-color-profiles

{.$DEFINE DEBUG_DUMP_ACCENT_PALETTE_QUANTANIZER}

interface

uses
  Winapi.Windows,
  // System
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Math,
  System.SysUtils,
  System.Types,
  // VCL
  Vcl.Graphics,
  // ACL
  ACL.Classes.Collections,
  ACL.Graphics,
  ACL.Graphics.Layers,
  ACL.FastCode;

type
  TACLPaletteSwatchType = (pstDominant, pstBackground, pstForeground,
    pstLightVibrant, pstVibrant, pstDarkVibrant, pstLightMuted, pstMuted, pstDarkMuted);

  { TACLPaletteSwatch }

  TACLPaletteSwatch = record
    H, S, L: Byte;
    Population: Word;

    class operator Equal(const S1, S2: TACLPaletteSwatch): Boolean;
    class operator NotEqual(const S1, S2: TACLPaletteSwatch): Boolean;
    function IsLigth: Boolean;
    function ToColor: TColor;
  end;

  { TACLPaletteSwatches }

  TACLPaletteSwatches = class(TACLEnumerable<TACLPaletteSwatch>)
  strict private
    FData: TACLDictionary<Integer, TACLPaletteSwatch>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const H, S, L: Byte);
    function GetEnumerator: IACLEnumerator<TACLPaletteSwatch>; override;
  end;

  { TACLPalette }

  TACLPalette = class
  protected const
    BufferSize = 112;
    MinImageFraction = 0.002;
    MinSaturationWhenDeciding = 48;
    PopulationFractionForBlackAndWhite = 2.5;
    PopulationFractionForDominant = 0.01;
    BlackMaxLightness = 20;  // 0.08
    WhiteMinLightness = 230; // 0.90
  strict private const
    QuantizeFactorH = 1;
    QuantizeFactorL = 4;
    QuantizeFactorS = 4;
    QuantizeMaskH = (MaxByte shr QuantizeFactorH) shl QuantizeFactorH;
    QuantizeMaskL = (MaxByte shr QuantizeFactorL) shl QuantizeFactorL;
    QuantizeMaskS = (MaxByte shr QuantizeFactorS) shl QuantizeFactorS;
  strict private type
    TFilterFunc = reference to function (const S: TACLPaletteSwatch): Boolean;
  {$REGION 'Private Types'}
    TTarget = record
      LMax: Byte;
      LMin: Byte;
      LTarget: Byte;
      SMax: Byte;
      SMin: Byte;
      STarget: Byte;
    end;
  {$ENDREGION}
  strict private const
    DarkMuted:    TTarget = (LMax: 115; LMin:   0; LTarget:  66; SMax: 102; SMin:  0; STarget:  77);
    DarkVibrant:  TTarget = (LMax: 115; LMin:   0; LTarget:  66; SMax: 255; SMin: 89; STarget: 255);
    LightMuted:   TTarget = (LMax: 255; LMin: 140; LTarget: 189; SMax: 102; SMin:  0; STarget:  77);
    LightVibrant: TTarget = (LMax: 255; LMin: 140; LTarget: 189; SMax: 255; SMin: 89; STarget: 255);
    Muted:        TTarget = (LMax: 179; LMin:  77; LTarget: 128; SMax: 102; SMin:  0; STarget:  77);
    Vibrant:      TTarget = (LMax: 179; LMin:  77; LTarget: 128; SMax: 255; SMin: 89; STarget: 255);
  strict private
    function GetColor(AIndex: TACLPaletteSwatchType): TColor;
    function GetSwatch(AIndex: TACLPaletteSwatchType): TACLPaletteSwatch;
  protected
    FSwatches: array[TACLPaletteSwatchType] of TACLPaletteSwatch;

    procedure CalculateBackground(ASwatches: TACLPaletteSwatches; var ASwatch: TACLPaletteSwatch);
    procedure CalculateDominant(ASwatches: TACLPaletteSwatches; var ASwatch: TACLPaletteSwatch; AFilterProc: TFilterFunc = nil);
    procedure CalculateForeground(ASwatches: TACLPaletteSwatches; var ASwatch: TACLPaletteSwatch);
    procedure CalculateTarget(ASwatches: TACLPaletteSwatches; ATarget: TTarget; var ASwatch: TACLPaletteSwatch);
    procedure GenerateCore(AColors: PRGBQuad; ACount: Integer);
    function HasEnoughPopulation(const ASwatch: TACLPaletteSwatch): Boolean;
    function IsBlackOrWhite(const ASwatch: TACLPaletteSwatch): Boolean; inline;
    function IsContrastWithBackground(const ASwatch: TACLPaletteSwatch): Boolean;
    function QuantizeColors(AColors: PRGBQuad; ACount: Integer): TACLPaletteSwatches;
    function SelectMutedCandidate(const S1, S2: TACLPaletteSwatch): TACLPaletteSwatch;
    function SelectVibrantCandidate(const S1, S2: TACLPaletteSwatch): TACLPaletteSwatch;
  public
    procedure Generate(ABitmap: TBitmap); overload;
    procedure Generate(ALayer: TACLBitmapLayer); overload;
    procedure Generate(DC: HDC; const R: TRect); overload;
    procedure Reset;

    property Colors[Index: TACLPaletteSwatchType]: TColor read GetColor;
    property Swatches[Index: TACLPaletteSwatchType]: TACLPaletteSwatch read GetSwatch;
  end;

implementation

uses
  ACL.Utils.Common;

{ TACLPaletteSwatch }

class operator TACLPaletteSwatch.Equal(const S1, S2: TACLPaletteSwatch): Boolean;
begin
  Result := CompareMem(@S1, @S2, SizeOf(S1));
end;

function TACLPaletteSwatch.IsLigth: Boolean;
begin
  Result := L > 128;
end;

class operator TACLPaletteSwatch.NotEqual(const S1, S2: TACLPaletteSwatch): Boolean;
begin
  Result := not (S1 = S2);
end;

function TACLPaletteSwatch.ToColor: TColor;
begin
  if Population > 0 then
    TACLColors.HSLtoRGBi(H, S, L, Result)
  else
    Result := clDefault;
end;

{ TACLPaletteSwatches }

constructor TACLPaletteSwatches.Create;
begin
  FData := TACLDictionary<Integer, TACLPaletteSwatch>.Create(1024);
end;

destructor TACLPaletteSwatches.Destroy;
begin
  FreeAndNil(FData);
  inherited;
end;

procedure TACLPaletteSwatches.Add(const H, S, L: Byte);
var
  AKey: Integer;
  AValue: TACLPaletteSwatch;
begin
  AKey := (H shl 16) or (S shl 8) or L;

  if FData.TryGetValue(AKey, AValue) then
    Inc(AValue.Population)
  else
  begin
    AValue.H := H;
    AValue.S := S;
    AValue.L := L;
    AValue.Population := 1;
  end;

  FData.AddOrSetValue(AKey, AValue);
end;

function TACLPaletteSwatches.GetEnumerator: IACLEnumerator<TACLPaletteSwatch>;
begin
  Result := FData.GetValues.GetEnumerator;
end;

{ TACLPalette }

procedure TACLPalette.Generate(ABitmap: TBitmap);
begin
  Generate(ABitmap.Canvas.Handle, Rect(0, 0, ABitmap.Width, ABitmap.Height));
end;

procedure TACLPalette.Generate(ALayer: TACLBitmapLayer);
begin
  Generate(ALayer.Handle, ALayer.ClientRect);
end;

procedure TACLPalette.Generate(DC: HDC; const R: TRect);
var
  AWorkLayer: TACLBitmapLayer;
begin
  Reset;
  if not IsRectEmpty(R) then
  begin
//  {$IFDEF DEBUG_DUMP_ACCENT_PALETTE_QUANTANIZER}
//    AWorkLayer := TACLBitmapLayer.Create(R.Width, R.Height);
//  {$ELSE}
    AWorkLayer := TACLBitmapLayer.Create(Min(BufferSize, R.Width), Min(BufferSize, R.Height));
//  {$ENDIF}
    try
      SetStretchBltMode(AWorkLayer.Handle, HALFTONE);
      acStretchBlt(AWorkLayer.Handle, DC, AWorkLayer.ClientRect, R);
      GenerateCore(@AWorkLayer.Colors^[0], AWorkLayer.ColorCount);

    {$IFDEF DEBUG_DUMP_ACCENT_PALETTE_QUANTANIZER}
      with TACLBitmap.CreateEx(AWorkLayer.Width, AWorkLayer.Height) do
      try
        acBitBlt(Canvas.Handle, AWorkLayer.Handle, ClientRect, NullPoint);
        SaveToFile('B:\1.bmp');
      finally
        Free;
      end;
    {$ENDIF}
    finally
      AWorkLayer.Free;
    end;
  end;
end;

procedure TACLPalette.Reset;
var
  I: TACLPaletteSwatchType;
begin
  for I := Low(FSwatches) to High(FSwatches) do
    FSwatches[I].Population := 0;
end;

procedure TACLPalette.CalculateBackground(ASwatches: TACLPaletteSwatches; var ASwatch: TACLPaletteSwatch);
var
  AIndex: TACLPaletteSwatch;
  AMaxPopulation: Integer;
begin
  ASwatch := FSwatches[pstDominant];

  if IsBlackOrWhite(ASwatch) then
  begin
    AMaxPopulation := 0;
    for AIndex in ASwatches do
    begin
      if (AIndex.Population > AMaxPopulation) and not IsBlackOrWhite(AIndex) then
      begin
        AMaxPopulation := AIndex.Population;
        ASwatch := AIndex;
      end;
    end;
    if AMaxPopulation = 0 then
      Exit;
    // The dominant swatch is very dominant, lets take it!
    if (FSwatches[pstDominant].Population / AMaxPopulation > PopulationFractionForBlackAndWhite) then
      ASwatch := FSwatches[pstDominant];
  end;
end;

procedure TACLPalette.CalculateDominant(ASwatches: TACLPaletteSwatches; var ASwatch: TACLPaletteSwatch; AFilterProc: TFilterFunc = nil);
var
  AIndex: TACLPaletteSwatch;
  AMaxPopulation: Integer;
begin
  AMaxPopulation := 0;
  for AIndex in ASwatches do
  begin
    if Assigned(AFilterProc) and not AFilterProc(AIndex) then
      Continue;
    if AIndex.Population > AMaxPopulation then
    begin
      AMaxPopulation := AIndex.Population;
      ASwatch := AIndex;
    end;
  end;
end;

procedure TACLPalette.CalculateForeground(ASwatches: TACLPaletteSwatches; var ASwatch: TACLPaletteSwatch);
const
  MutedMap: array[Boolean] of TACLPaletteSwatchType = (pstDarkMuted, pstLightMuted);
  VibrantMap: array[Boolean] of TACLPaletteSwatchType = (pstDarkVibrant, pstLightVibrant);
var
  AForegroundDominant: TACLPaletteSwatch;
  AIsLight: Boolean;
begin
  if IsBlackOrWhite(FSwatches[pstBackground]) then
    CalculateDominant(ASwatches, AForegroundDominant, IsBlackOrWhite)
  else
    CalculateDominant(ASwatches, AForegroundDominant, IsContrastWithBackground);

  AIsLight := FSwatches[pstBackground].IsLigth;
  ASwatch := SelectVibrantCandidate(Swatches[VibrantMap[AIsLight]], Swatches[pstVibrant]);
  if (ASwatch.Population = 0) then
    ASwatch := SelectMutedCandidate(Swatches[MutedMap[AIsLight]], Swatches[pstVibrant]);
  if (ASwatch.Population > 0) and (AForegroundDominant <> ASwatch) then
  begin
    if (ASwatch.Population < PopulationFractionForDominant * AForegroundDominant.Population) then
    begin
      if AForegroundDominant.H > MinSaturationWhenDeciding then
        ASwatch := AForegroundDominant;
    end;
  end;
end;

procedure TACLPalette.CalculateTarget(ASwatches: TACLPaletteSwatches; ATarget: TTarget; var ASwatch: TACLPaletteSwatch);
var
  AIndex: TACLPaletteSwatch;
  AMaxPopulation: Word;
  AMaxScore: Single;
  AScore: Single;
begin
  AMaxPopulation := FSwatches[pstDominant].Population;
  if AMaxPopulation = 0 then
    Exit;

  AMaxScore := 0;
  for AIndex in ASwatches do
  begin
    if not InRange(AIndex.S, ATarget.SMin, ATarget.SMax) then
      Continue;
    if not InRange(AIndex.L, ATarget.LMin, ATarget.LMax) then
      Continue;

    AScore :=
      0.24 * (AIndex.Population / AMaxPopulation) +
      0.52 * (MaxByte - FastAbs(AIndex.L - ATarget.LTarget)) +
      0.24 * (MaxByte - FastAbs(AIndex.S - ATarget.STarget));

    if AScore > AMaxScore then
    begin
      AMaxScore := AScore;
      ASwatch := AIndex;
    end;
  end;
end;

procedure TACLPalette.GenerateCore(AColors: PRGBQuad; ACount: Integer);
var
  ASwatches: TACLPaletteSwatches;
begin
  Reset;
  ASwatches := QuantizeColors(AColors, ACount);
  try
    // DO NOT CHANGE THE ORDER
    CalculateDominant(ASwatches, FSwatches[pstDominant]);

    CalculateTarget(ASwatches, LightVibrant, FSwatches[pstLightVibrant]);
    CalculateTarget(ASwatches, Vibrant, FSwatches[pstVibrant]);
    CalculateTarget(ASwatches, DarkVibrant, FSwatches[pstDarkVibrant]);

    CalculateTarget(ASwatches, LightMuted, FSwatches[pstLightMuted]);
    CalculateTarget(ASwatches, Muted, FSwatches[pstMuted]);
    CalculateTarget(ASwatches, DarkMuted, FSwatches[pstDarkMuted]);

    CalculateBackground(ASwatches, FSwatches[pstBackground]);
    CalculateForeground(ASwatches, FSwatches[pstForeground]);
  finally
    ASwatches.Free;
  end;
end;

function TACLPalette.QuantizeColors(AColors: PRGBQuad; ACount: Integer): TACLPaletteSwatches;
var
  H, S, L: Byte;
begin
  Result := TACLPaletteSwatches.Create;
  while ACount > 0 do
  begin
    with AColors^ do
      TACLColors.RGBtoHSLi(rgbRed, rgbGreen, rgbBlue, H, S, L);

    H := H and QuantizeMaskH;
    L := L and QuantizeMaskL;
    S := S and QuantizeMaskS;

    Result.Add(H, S, L);
  {$IFDEF DEBUG_DUMP_ACCENT_PALETTE_QUANTANIZER}
    with AColors^ do
      TACLColors.HSLtoRGBi(H, S, L, rgbRed, rgbGreen, rgbBlue);
  {$ENDIF}

    Inc(AColors);
    Dec(ACount);
  end;
end;

function TACLPalette.GetColor(AIndex: TACLPaletteSwatchType): TColor;
begin
  Result := FSwatches[AIndex].ToColor;
end;

function TACLPalette.GetSwatch(AIndex: TACLPaletteSwatchType): TACLPaletteSwatch;
begin
  Result := FSwatches[AIndex];
end;

function TACLPalette.IsBlackOrWhite(const ASwatch: TACLPaletteSwatch): Boolean;
begin
  Result := not InRange(ASwatch.L, BlackMaxLightness, WhiteMinLightness);
end;

function TACLPalette.IsContrastWithBackground(const ASwatch: TACLPaletteSwatch): Boolean;
begin
  Result := not IsBlackOrWhite(ASwatch) and (FastAbs(ASwatch.H - FSwatches[pstBackground].H) > 7); // 7 = 10°/360° * 255
end;

function TACLPalette.SelectMutedCandidate(const S1, S2: TACLPaletteSwatch): TACLPaletteSwatch;
begin
  if HasEnoughPopulation(S1) and HasEnoughPopulation(S2) then
  begin
    if S1.S * S1.Population > S2.S * S2.Population then
      Result := S1
    else
      Result := S2;
  end
  else
    if HasEnoughPopulation(S1) then
      Result := S1
    else
      Result := S2
end;

function TACLPalette.SelectVibrantCandidate(const S1, S2: TACLPaletteSwatch): TACLPaletteSwatch;
begin
  if HasEnoughPopulation(S1) and HasEnoughPopulation(S2) then
  begin
    if S1.Population < S2.Population then
      Result := S2
    else
      Result := S1;
  end
  else
    if HasEnoughPopulation(S1) then
      Result := S1
    else
      Result := S2
end;

function TACLPalette.HasEnoughPopulation(const ASwatch: TACLPaletteSwatch): Boolean;
begin
  Result := ASwatch.Population / TACLPalette.BufferSize > MinImageFraction;
end;

end.
