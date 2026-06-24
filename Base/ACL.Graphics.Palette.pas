////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Material Design like Color Palette
//  Based on:
//             https://android.googlesource.com/platform/prebuilts/fullsdk/sources/android-30/+/refs/heads/androidx-activity-release/com/android/systemui/statusbar/notification/MediaNotificationProcessor.java
//             https://developer.android.com/training/material/palette-colors#extract-color-profiles
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Graphics.Palette;

{$I ACL.Config.inc}
{.$DEFINE DEBUG_DUMP_ACCENT_PALETTE_QUANTANIZER}

interface

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ELSE}
  LCLType,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Generics.Defaults,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // VCL
  {Vcl.}Graphics,
  // ACL
  ACL.Classes.Collections,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.FastCode,
  ACL.Utils.Common;

type
  TACLMaterialColorPaletteSwatchType = (pstDominant,
    pstLightVibrant, pstVibrant, pstDarkVibrant,
    pstLightMuted, pstMuted, pstDarkMuted);

  { TACLMaterialColorPaletteSwatch }

  TACLMaterialColorPaletteSwatch = record
    H, S, L: Byte;
    Population: Word;

    class operator Equal(const S1, S2: TACLMaterialColorPaletteSwatch): Boolean;
    class operator NotEqual(const S1, S2: TACLMaterialColorPaletteSwatch): Boolean;
    function Coloration: Integer;
    function IsLight: Boolean;
    function Luminance: Double;
    function ToColor: TColor;
  end;

  { TACLMaterialColorPalette }

  TACLMaterialColorPalette = class(TACLEnumerable<TACLMaterialColorPaletteSwatch>)
  strict private const
    QuantizeFactorH = 1;
    QuantizeFactorL = 4;
    QuantizeFactorS = 4;
    QuantizeMaskH = (MaxByte shr QuantizeFactorH) shl QuantizeFactorH;
    QuantizeMaskL = (MaxByte shr QuantizeFactorL) shl QuantizeFactorL;
    QuantizeMaskS = (MaxByte shr QuantizeFactorS) shl QuantizeFactorS;
  strict private type
    TTarget = record
      LMax, LMin, LTarget: Byte;
      SMax, SMin, STarget: Byte;
    end;
  strict private const
    DarkMuted:    TTarget = (LMax: 115; LMin:   0; LTarget:  66; SMax: 102; SMin:  0; STarget:  77);
    DarkVibrant:  TTarget = (LMax: 115; LMin:   0; LTarget:  66; SMax: 255; SMin: 89; STarget: 255);
    LightMuted:   TTarget = (LMax: 255; LMin: 140; LTarget: 189; SMax: 102; SMin:  0; STarget:  77);
    LightVibrant: TTarget = (LMax: 255; LMin: 140; LTarget: 189; SMax: 255; SMin: 89; STarget: 255);
    Muted:        TTarget = (LMax: 179; LMin:  77; LTarget: 128; SMax: 102; SMin:  0; STarget:  77);
    Vibrant:      TTarget = (LMax: 179; LMin:  77; LTarget: 128; SMax: 255; SMin: 89; STarget: 255);
  strict private
    FData: TACLDictionary<Integer, TACLMaterialColorPaletteSwatch>;
    procedure Add(const H, S, L: Byte);
    function CalculateDominant: TACLMaterialColorPaletteSwatch;
    function CalculateTarget(const ATarget: TTarget): TACLMaterialColorPaletteSwatch;
  public type
    TFilterProc = function (const H, S, L: Byte): Boolean of object;
  public
    Swatches: array[TACLMaterialColorPaletteSwatchType] of TACLMaterialColorPaletteSwatch;
    constructor Create(AColors: PACLPixel32; ACount: Integer; AFilter: TFilterProc = nil);
    destructor Destroy; override;
    function GetEnumerator: IACLEnumerator<TACLMaterialColorPaletteSwatch>; override;
  end;

  { TACLMediaBasedColorTheme }

  TACLMediaBasedColorTheme = record
  strict private const
    MinForegroundContrast = 3.5;
    MinImageFraction = 0.002;
    MinSaturationWhenDeciding = 48;
    PopulationFractionForDominant = 0.01;
    BlackMaxLightness = 20;  // 0.08
    WhiteMinLightness = 230; // 0.90
    PopulationFractionForBlackAndWhite = 2.5;
  strict private
    function BuildPalette(AImage: TACLDib; ALeftPcs, ARightPcs: Single;
      AFilter: TACLMaterialColorPalette.TFilterProc = nil): TACLMaterialColorPalette;
    function CalculateAccent(APalette: TACLMaterialColorPalette): TACLMaterialColorPaletteSwatch;
    function CalculateBackground(APalette: TACLMaterialColorPalette): TACLMaterialColorPaletteSwatch;
    function CalculateForeground(APalette: TACLMaterialColorPalette): TACLMaterialColorPaletteSwatch;
    procedure EnsureContrast;
    function HasEnoughPopulation(const ASwatch: TACLMaterialColorPaletteSwatch): Boolean;
    function IsBlackOrWhite(const H, S, L: Byte): Boolean;
    function IsColorful(const ASwatch: TACLMaterialColorPaletteSwatch): Boolean;
    function IsContrastWithBackground(const H, S, L: Byte): Boolean;
    function SelectMutedCandidate(const S1, S2: TACLMaterialColorPaletteSwatch): TACLMaterialColorPaletteSwatch;
    function SelectVibrantCandidate(const S1, S2: TACLMaterialColorPaletteSwatch): TACLMaterialColorPaletteSwatch;
  public const
    BufferSize = 150;
  public
    Accent: TACLMaterialColorPaletteSwatch;
    Background: TACLMaterialColorPaletteSwatch;
    Foreground: TACLMaterialColorPaletteSwatch;
    procedure Build(AImage: TACLDib);
  end;

implementation

{ TACLMaterialColorPaletteSwatch }

class operator TACLMaterialColorPaletteSwatch.Equal(
  const S1, S2: TACLMaterialColorPaletteSwatch): Boolean;
begin
  if S1.H <> S2.H then
    Exit(False);
  if S1.S <> S2.S then
    Exit(False);
  if S1.L <> S2.L then
    Exit(False);
  if S1.Population <> S2.Population then
    Exit(False);
  Result := True;
end;

class operator TACLMaterialColorPaletteSwatch.NotEqual(
  const S1, S2: TACLMaterialColorPaletteSwatch): Boolean;
begin
  Result := not (S1 = S2);
end;

function TACLMaterialColorPaletteSwatch.Coloration: Integer;
begin
  Result := MulDiv(S, 255 - 2 * (128 - L), 255);
end;

function TACLMaterialColorPaletteSwatch.IsLight: Boolean;
begin
  Result := L > 128;
end;

function TACLMaterialColorPaletteSwatch.Luminance: Double;
begin
  Result := TACLColors.Luminance(TACLPixel32.Create(ToColor));
end;

function TACLMaterialColorPaletteSwatch.ToColor: TColor;
begin
  if Population > 0 then
    Result := TACLColors.HSLtoRGBi(H, S, L)
  else
    Result := clDefault;
end;

{ TACLMaterialColorPalette }

constructor TACLMaterialColorPalette.Create(
  AColors: PACLPixel32; ACount: Integer; AFilter: TFilterProc);
var
  H, S, L: Byte;
begin
  FData := TACLDictionary<Integer, TACLMaterialColorPaletteSwatch>.Create(ACount div 10);

  while ACount > 0 do
  begin
    with AColors^ do
      TACLColors.RGBtoHSLi(R, G, B, H, S, L);

    H := H and QuantizeMaskH;
    S := S and QuantizeMaskS;
    L := L and QuantizeMaskL;

  {$IFDEF DEBUG_DUMP_ACCENT_PALETTE_QUANTANIZER}
    with AColors^ do
      TACLColors.HSLtoRGBi(H, S, L, R, G, B);
  {$ENDIF}

    if Assigned(AFilter) and not AFilter(H, S, L) then
    {$IFDEF DEBUG_DUMP_ACCENT_PALETTE_QUANTANIZER}
      TACLColors.Flush(AColors^)
    {$ENDIF}
    else
      Add(H, S, L);

    Inc(AColors);
    Dec(ACount);
  end;

  Swatches[pstDominant] := CalculateDominant;

  Swatches[pstLightVibrant] := CalculateTarget(LightVibrant);
  Swatches[pstVibrant] := CalculateTarget(Vibrant);
  Swatches[pstDarkVibrant] := CalculateTarget(DarkVibrant);

  Swatches[pstLightMuted] := CalculateTarget(LightMuted);
  Swatches[pstMuted] := CalculateTarget(Muted);
  Swatches[pstDarkMuted] := CalculateTarget(DarkMuted);
end;

destructor TACLMaterialColorPalette.Destroy;
begin
  FreeAndNil(FData);
  inherited;
end;

procedure TACLMaterialColorPalette.Add(const H, S, L: Byte);
var
  LKey: Integer;
  LValue: TACLMaterialColorPaletteSwatch;
begin
  LKey := (H shl 16) or (S shl 8) or L;

  if FData.TryGetValue(LKey, LValue) then
    Inc(LValue.Population)
  else
  begin
    LValue.H := H;
    LValue.S := S;
    LValue.L := L;
    LValue.Population := 1;
  end;

  FData.AddOrSetValue(LKey, LValue);
end;

function TACLMaterialColorPalette.CalculateDominant: TACLMaterialColorPaletteSwatch;
var
  LIndex: TACLMaterialColorPaletteSwatch;
begin
  Result := Default(TACLMaterialColorPaletteSwatch);
  for LIndex in Self do
  begin
    if LIndex.Population > Result.Population then
      Result := LIndex;
  end;
end;

function TACLMaterialColorPalette.CalculateTarget(const ATarget: TTarget): TACLMaterialColorPaletteSwatch;
var
  LIndex: TACLMaterialColorPaletteSwatch;
  LMaxPopulation: Word;
  LMaxScore: Single;
  LScore: Single;
begin
  Result := Default(TACLMaterialColorPaletteSwatch);
  LMaxPopulation := Swatches[pstDominant].Population;
  if LMaxPopulation > 0 then
  begin
    LMaxScore := 0;
    for LIndex in Self do
    begin
      if not InRange(LIndex.S, ATarget.SMin, ATarget.SMax) then
        Continue;
      if not InRange(LIndex.L, ATarget.LMin, ATarget.LMax) then
        Continue;

      LScore :=
        0.24 * (LIndex.Population / LMaxPopulation) +
        0.52 * (MaxByte - FastAbs(Integer(LIndex.L - ATarget.LTarget))) +
        0.24 * (MaxByte - FastAbs(Integer(LIndex.S - ATarget.STarget)));

      if LScore > LMaxScore then
      begin
        LMaxScore := LScore;
        Result := LIndex;
      end;
    end;
  end;
end;

function TACLMaterialColorPalette.GetEnumerator: IACLEnumerator<TACLMaterialColorPaletteSwatch>;
begin
  Result := FData.GetValues.GetEnumerator;
end;

{ TACLMediaBasedColorTheme }

procedure TACLMediaBasedColorTheme.Build(AImage: TACLDib);
var
  LPalette: TACLMaterialColorPalette;
begin
  Accent := Default(TACLMaterialColorPaletteSwatch);
  Background := Default(TACLMaterialColorPaletteSwatch);
  Foreground := Default(TACLMaterialColorPaletteSwatch);
  if (AImage <> nil) and not AImage.Empty then
  begin
    LPalette := BuildPalette(AImage, 0, 0.5);
    try
      Background := CalculateBackground(LPalette);
    finally
      LPalette.Free;
    end;

    LPalette := BuildPalette(AImage, 0.4, 1.0, IsContrastWithBackground);
    try
      Foreground := CalculateForeground(LPalette);
      Accent := CalculateAccent(LPalette);
    finally
      LPalette.Free;
    end;

    EnsureContrast;
  end;
end;

function TACLMediaBasedColorTheme.BuildPalette(
  AImage: TACLDib; ALeftPcs, ARightPcs: Single;
  AFilter: TACLMaterialColorPalette.TFilterProc = nil): TACLMaterialColorPalette;
var
  LSize: TSize;
  LWork: TACLDib;
begin
  LSize.cy := Min(BufferSize, AImage.Height);
  LSize.cx := Min(BufferSize, AImage.Width);
  LWork := TACLDib.Create(Round(LSize.cx * (ARightPcs - ALeftPcs)), LSize.cy);
  try
    AImage.DrawCopy(LWork.Canvas, Bounds(Round(-ALeftPcs * LSize.cx), 0, LSize.cx, LSize.cy), True);
    Result := TACLMaterialColorPalette.Create(LWork.Colors, LWork.ColorCount, AFilter);
  {$IFDEF DEBUG_DUMP_ACCENT_PALETTE_QUANTANIZER}
    LWork.SaveToBitmapFile('B:\1.bmp'); {$MESSAGE 'TODO - Debug'}
  {$ENDIF}
  finally
    LWork.Free;
  end;
end;

function TACLMediaBasedColorTheme.CalculateAccent(
  APalette: TACLMaterialColorPalette): TACLMaterialColorPaletteSwatch;
begin
  if IsColorful(Background) then
    Exit(Background);
  if IsColorful(APalette.Swatches[pstDominant]) then
    Exit(APalette.Swatches[pstDominant]);
  if Foreground.Coloration > 0 then
    Exit(Foreground);
  Result := Default(TACLMaterialColorPaletteSwatch);
end;

function TACLMediaBasedColorTheme.CalculateBackground(
  APalette: TACLMaterialColorPalette): TACLMaterialColorPaletteSwatch;
var
  LIndex: TACLMaterialColorPaletteSwatch;
  LMaxPopulation: Integer;
begin
  Result := APalette.Swatches[pstDominant];
  if IsBlackOrWhite(Result.H, Result.S, Result.L) then
  begin
    LMaxPopulation := 0;
    for LIndex in APalette do
    begin
      if (LIndex.Population > LMaxPopulation) and not IsBlackOrWhite(LIndex.H, LIndex.S, LIndex.L) then
      begin
        LMaxPopulation := LIndex.Population;
        Result := LIndex;
      end;
    end;
    if LMaxPopulation = 0 then Exit;
    // The dominant swatch is very dominant, lets take it!
    if APalette.Swatches[pstDominant].Population / LMaxPopulation > PopulationFractionForBlackAndWhite then
      Result := APalette.Swatches[pstDominant];
  end;
end;

function TACLMediaBasedColorTheme.CalculateForeground(
  APalette: TACLMaterialColorPalette): TACLMaterialColorPaletteSwatch;
var
  LDominant: TACLMaterialColorPaletteSwatch;
  LMoreMuted: TACLMaterialColorPaletteSwatchType;
  LMoreVibrant: TACLMaterialColorPaletteSwatchType;
begin
  LDominant := APalette.Swatches[pstDominant];
  if Background.IsLight then
  begin
    LMoreMuted := pstDarkMuted;
    LMoreVibrant := pstDarkVibrant;
  end
  else
  begin
    LMoreMuted := pstLightMuted;
    LMoreVibrant := pstLightVibrant;
  end;

  Result := SelectVibrantCandidate(APalette.Swatches[LMoreVibrant], APalette.Swatches[pstVibrant]);
  if (Result.Population = 0) then
    Result := SelectMutedCandidate(APalette.Swatches[pstMuted], APalette.Swatches[LMoreMuted]);
  if (Result.Population > 0) and (LDominant <> Result) then
  begin
    if Result.Population < PopulationFractionForDominant * LDominant.Population then
    begin
      if (LDominant.S > MinSaturationWhenDeciding) and (LDominant.L > 0) then
        Result := LDominant;
    end;
  end
  else
    if HasEnoughPopulation(LDominant) then
      Result := LDominant
    else
    begin
      Result := Default(TACLMaterialColorPaletteSwatch);
      Result.L := IfThen(Background.IsLight, 0, 1);
    end;
end;

procedure TACLMediaBasedColorTheme.EnsureContrast;

  function ContrastLum(Lum1, Lum2: Double): Double;
  begin
    Lum1 := Lum1 + 0.05;
    Lum2 := Lum2 + 0.05;
    Result := Max(Lum1, Lum2) / Min(Lum1, Lum2);
  end;

var
  LDark: Boolean;
  LBackgroundLum: Double;
  LForeground: TACLMaterialColorPaletteSwatch;
  LForegroundLum: Double;
  LLow, LHigh: Integer;
  LTryCount: Integer;
begin
  // Accent
  if Accent.Population > 0 then
  begin
    Accent.S := Max(Accent.S, 25); // 0.1
    Accent.L := EnsureRange(Accent.L, 25, 229); // 0.1..0.9
  end;

  // Foreground
  if Foreground.Population > 0 then
  begin
    LBackgroundLum := Background.Luminance;
    LForegroundLum := Foreground.Luminance;
    if ContrastLum(LForegroundLum, LBackgroundLum) < MinForegroundContrast then
    begin
      // Может оказаться так, что делать foreground темнее/светлее уже некуда,
      // например, при цветах:  background = FF181038, foreground = FF101030
      if LBackgroundLum < LForegroundLum then
        LDark := ContrastLum(1{Luminance(White)}, LBackgroundLum) > MinForegroundContrast
      else
        LDark := ContrastLum(0{Luminance(Black)}, LBackgroundLum) < MinForegroundContrast;

      LForeground := Foreground;
      LLow  := IfThen(LDark, LForeground.L, 0);
      LHigh := IfThen(LDark, 255, LForeground.L);
      LTryCount := 15;
      while (LTryCount > 0) and (LLow <> LHigh) do
      begin
        LForeground.L := (LLow + LHigh) div 2;
        if (ContrastLum(LForeground.Luminance, LBackgroundLum) > MinForegroundContrast) = LDark then
          LHigh := LForeground.L
        else if LLow < LForeground.L then
          LLow := LForeground.L
        else
          Break;
        Dec(LTryCount);
      end;
      Foreground := LForeground;
    end;
  end;
end;

function TACLMediaBasedColorTheme.IsBlackOrWhite(const H, S, L: Byte): Boolean;
begin
  Result := not InRange(L, BlackMaxLightness, WhiteMinLightness);
end;

function TACLMediaBasedColorTheme.IsColorful(const ASwatch: TACLMaterialColorPaletteSwatch): Boolean;
begin
  Result :=
    (ASwatch.Population > 0) and not IsBlackOrWhite(ASwatch.H, ASwatch.S, ASwatch.L) and
    (ASwatch.Coloration > 0);
end;

function TACLMediaBasedColorTheme.IsContrastWithBackground(const H, S, L: Byte): Boolean;
var
  dH, dL: Integer;
begin
  dH := Abs(Integer(H) - Integer(Background.H));
  dL := Abs(Integer(L) - Integer(Background.L));
  Result :=
       (dH > 7)   // 10°/360° * 255
    or (dL > 76); // 30% from 255
end;

function TACLMediaBasedColorTheme.HasEnoughPopulation(
  const ASwatch: TACLMaterialColorPaletteSwatch): Boolean;
begin
  Result := ASwatch.Population / TACLMediaBasedColorTheme.BufferSize > MinImageFraction;
end;

function TACLMediaBasedColorTheme.SelectMutedCandidate(
  const S1, S2: TACLMaterialColorPaletteSwatch): TACLMaterialColorPaletteSwatch;
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

function TACLMediaBasedColorTheme.SelectVibrantCandidate(
  const S1, S2: TACLMaterialColorPaletteSwatch): TACLMaterialColorPaletteSwatch;
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

end.

