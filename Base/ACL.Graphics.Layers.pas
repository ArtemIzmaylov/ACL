{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*               Bitmap Layers               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.Layers;

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

  { IACLBlurFilterCore }

  IACLBlurFilterCore = interface
  ['{89DD6E84-C6CB-4367-90EC-3943D5593372}']
    procedure Apply(ALayerDC: HDC; AColors: PRGBQuad; AWidth, AHeight: Integer);
    function GetSize: Integer;
    procedure Setup(ARadius: Integer);
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

  // ABackgroundLayer is a target layer
  TACLBlendFunction = procedure (ABackgroundLayer, AForegroundLayer: TACLBitmapLayer; AAlpha: Byte) of object;
  TACLCreateBlurFilterCoreFunction = function: IACLBlurFilterCore;

var
  FBlendFunctions: array[TACLBlendMode] of TACLBlendFunction;
  FCreateBlurFilterCore: TACLCreateBlurFilterCoreFunction;

procedure acFlipColors(AColors: PRGBQuadArray; AWidth, AHeight: Integer; AHorizontally, AVertically: Boolean);
implementation

uses
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics.Gdiplus,
  ACL.Graphics.Layers.Software,
  ACL.Math,
  ACL.Threading;

procedure acFlipColors(AColors: PRGBQuadArray; AWidth, AHeight: Integer; AHorizontally, AVertically: Boolean);
var
  I: Integer;
  Q1, Q2, Q3: PRGBQuad;
  Q4: TRGBQuad;
  RS: Integer;
begin
  if AVertically then
  begin
    Q1 := @AColors^[0];
    Q2 := @AColors^[(AHeight - 1) * AWidth];
    RS := AWidth * SizeOf(TRGBQuad);
    Q3 := AllocMem(RS);
    try
      while NativeUInt(Q1) < NativeUInt(Q2) do
      begin
        FastMove(Q2^, Q3^, RS);
        FastMove(Q1^, Q2^, RS);
        FastMove(Q3^, Q1^, RS);
        Inc(Q1, AWidth);
        Dec(Q2, AWidth);
      end;
    finally
      FreeMem(Q3, RS);
    end;
  end;

  if AHorizontally then
    for I := 0 to AHeight - 1 do
    begin
      Q1 := @AColors^[I * AWidth];
      Q2 := @AColors^[I * AWidth + AWidth - 1];
      while NativeUInt(Q1) < NativeUInt(Q2) do
      begin
        Q4  := Q2^;
        Q2^ := Q1^;
        Q1^ := Q4;
        Inc(Q1);
        Dec(Q2);
      end;
    end;
end;

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
  acFlipColors(Colors, Width, Height, AHorizontally, AVertically);
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
      FCore := FCreateBlurFilterCore;
      FCore.Setup(AValue);
      FShare.Add(AValue, FCore);
    end;
  {$ELSE}
    FCore.Setup(AValue);
  {$ENDIF}
    FSize := FCore.GetSize;
  end;
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

end.
