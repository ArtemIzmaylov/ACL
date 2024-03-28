{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*     Formatted Text with alpha channel     *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.TextLayout32;

{$I ACL.Config.inc} // FPC:OK
{$SCOPEDENUMS ON}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}Types,
  {System.}SysUtils,
  System.UITypes,
  // VCL
  {Vcl.}Graphics,
  // ACL
  ACL.Classes,
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.FontCache,
  ACL.Graphics.TextLayout,
  ACL.Math,
  ACL.Utils.Common,
  ACL.Utils.Strings;

const
  BlurRadiusFactor = 10;

type
{$REGION ' Advanced Font '}
  TACLFontShadow = class;

  { TACLFont }

  TACLFont = class(TFont)
  strict private
    FColorAlpha: Byte;
    FShadow: TACLFontShadow;

    procedure ChangeHandler(Sender: TObject);
    function GetAlphaColor: TAlphaColor;
    function GetTextExtends: TRect; inline;
    procedure SetAlphaColor(const Value: TAlphaColor);
    procedure SetColorAlpha(const AValue: Byte);
    procedure SetShadow(const AValue: TACLFontShadow);
  public
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure Assign(Source: TPersistent); override;
    function AppendTextExtends(const S: TSize): TSize;
    function MeasureSize(const S: PChar; ALength: Integer): TSize; overload;
    function MeasureSize(const S: string): TSize; overload;

    property AlphaColor: TAlphaColor read GetAlphaColor write SetAlphaColor;
    property TextExtends: TRect read GetTextExtends;
  published
    property ColorAlpha: Byte read FColorAlpha write SetColorAlpha default MaxByte;
    property Shadow: TACLFontShadow read FShadow write SetShadow;
  end;

  { TACLFontShadow }

  TACLFontShadow = class(TPersistent)
  strict private
    FBlur: Integer;
    FBlurSize: Integer;
    FColor: TAlphaColor;
    FDirection: TACLMarginPart;
    FSize: Integer;

    FOnChange: TNotifyEvent;

    function GetAssigned: Boolean;
  protected
    procedure Changed; virtual;
    function GetDrawIterations: Integer; inline;
    function GetTextExtends: TRect;
    //
    function GetBlur: Integer; virtual;
    function GetColor: TAlphaColor; virtual;
    function GetDirection: TACLMarginPart; virtual;
    function GetSize: Integer; virtual;
    procedure SetBlur(AValue: Integer); virtual;
    procedure SetColor(AValue: TAlphaColor); virtual;
    procedure SetDirection(AValue: TACLMarginPart); virtual;
    procedure SetSize(AValue: Integer); virtual;
  public
    constructor Create(AChangeEvent: TNotifyEvent);
    procedure Assign(Source: TPersistent); override;
    function Equals(Obj: TObject): Boolean; override;
    procedure Reset; virtual;
    //
    property Assigned: Boolean read GetAssigned;
    property Blur: Integer read GetBlur write SetBlur;
    property Color: TAlphaColor read GetColor write SetColor;
    property Direction: TACLMarginPart read GetDirection write SetDirection;
    property Size: Integer read GetSize write SetSize;
  end;

{$ENDREGION}

{$REGION ' TextLayout '}

  { TACLTextLayout32 }

  TACLTextLayout32 = class(TACLTextLayout)
  strict private
    function GetFont: TACLFont; inline;
  protected
    function GetPadding: TRect; override;
  public
    constructor Create(AFont: TACLFont);
    procedure Draw(ARender: TACLTextLayoutRender); override;
    //# Properties
    property Font: TACLFont read GetFont;
  end;

{$ENDREGION}

procedure DrawText32(ACanvas: TCanvas; const R: TRect; AText: string;
  AFont: TACLFont; AAlignment: TAlignment = taLeftJustify;
  AVertAlignment: TVerticalAlignment = taVerticalCenter;
  AEndEllipsis: Boolean = True); overload;
procedure DrawText32(ACanvas: TCanvas; const R: TRect;
  const AText: string; AFont: TACLFont); overload;
procedure DrawText32Duplicated(ACanvas: TCanvas; const R: TRect;
  const AText: string; const ATextOffset: TPoint; ADuplicateOffset: Integer; AFont: TACLFont);
implementation

{$REGION ' Painters '}

const
  MapTextOffsets: array[TACLMarginPart] of TPoint =
  (
    (X: -1; Y: -1),
    (X: -1; Y:  0),
    (X: -1; Y:  1),
    (X:  0; Y: -1),
    (X:  0; Y:  1),
    (X:  1; Y:  0),
    (X:  1; Y: -1),
    (X:  1; Y:  1),
    (X:  0; Y:  0)
  );

type

  { TACLTextLayout32Painter }

  TACLTextLayout32Painter = class(TACLTextLayoutPainter)
  strict private
    FCanvas: TCanvas;
    FDrawBackground: Boolean;
    FDrawContent: Boolean;
    procedure FillBackground(ABlock: TACLTextLayoutBlock); inline;
  protected
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  public
    constructor Create(AOwner: TACLTextLayout;
      ACanvas: TACLTextLayoutCanvasRender;
      ADrawBackground, ADrawContent: Boolean); reintroduce;
    property Canvas: TCanvas read FCanvas;
  end;

  { TACLTextLayout32PainterShadow }

  TACLTextLayout32PainterShadow = class(TACLTextLayoutPainter)
  strict private
    FBuffer: TACLDib;
    FBufferOrigin: TPoint;
    FBufferRender: TACLTextLayoutCanvasRender;
    FShadow: TACLFontShadow;
    FShadowDirection: TPoint;
    FShadowSize: Integer;
    FTargetCanvas: TCanvas;
  protected
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  public
    constructor Create(AOwner: TACLTextLayout32;
      ACanvas: TACLTextLayoutCanvasRender); reintroduce;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
  end;

{$ENDREGION}

var
  FGammaTable: array[Byte] of Byte;
  FGammaTableInitialized: Boolean;
  FTextBlur: TACLBlurFilter;
  FTextBuffer: TACLDib;

function CanDraw(ACanvas: TCanvas; const R: TRect; AFont: TACLFont): Boolean; overload; inline;
begin
  Result := acRectVisible(ACanvas, R) and
    ((AFont.ColorAlpha > 0) and (AFont.Color <> clNone) or AFont.Shadow.Assigned);
end;

procedure Text32ApplyBlur(ALayer: TACLDib; AShadow: TACLFontShadow);
begin
  if AShadow.Blur > 0 then
  begin
    if FTextBlur = nil then
      FTextBlur := TACLBlurFilter.Create;
    FTextBlur.Radius := Round(AShadow.Blur / BlurRadiusFactor);
    FTextBlur.Apply(ALayer);
  end;
end;

procedure Text32RecoverAlpha(ALayer: TACLDib; const ATextColor: TACLPixel32);
const
  K = 700; // [1..5000]
var
  AAlpha: Integer;
  P: PACLPixel32;
  I: Integer;
begin
  if not FGammaTableInitialized then
  begin
    for I := 0 to MaxByte do
      FGammaTable[I] := FastTrunc(MaxByte * Power(I / MaxByte, 1000 / K));
    FGammaTableInitialized := True;
  end;

  P := PACLPixel32(ALayer.Colors);
  for I := 1 to ALayer.ColorCount do
  begin
    if PDWORD(P)^ and TACLPixel32.EssenceMask <> 0 then
    begin
      AAlpha := 128 + FGammaTable[P^.R] * 77 + FGammaTable[P^.G] * 151 + FGammaTable[P^.B] * 28;
      AAlpha := AAlpha * ATextColor.A shr 16;
      P^.B := TACLColors.PremultiplyTable[ATextColor.B, AAlpha];
      P^.G := TACLColors.PremultiplyTable[ATextColor.G, AAlpha];
      P^.R := TACLColors.PremultiplyTable[ATextColor.R, AAlpha];
      P^.A := AAlpha;
    end
    else
      P^.A := 0;

    Inc(P);
  end;
end;

procedure DrawText32Core(ACanvas: TCanvas;
  const AText: PChar; ALength: Integer; AFont: TACLFont;
  const ABounds: TRect; const ATextOffset: TPoint;
  ATextDuplicateIndent: Integer = 0;
  ATextColor: TAlphaColor = TAlphaColor.Default);

  procedure Text32Output(ACanvas: TCanvas; const AOffset: TPoint);
  begin
    acTextOut(ACanvas, AOffset.X, AOffset.Y, AText, ALength, nil);
    if ATextDuplicateIndent > 0 then
      acTextOut(ACanvas, AOffset.X + ATextDuplicateIndent, AOffset.Y, AText, ALength, nil);
  end;

var
  APoint: TPoint;
  I, J, W, H: Integer;
begin
  W := ABounds.Width;
  H := ABounds.Height;
  if (W <= 0) or (H <= 0) then
    Exit;

  if (FTextBuffer = nil) or (FTextBuffer.Width <> W) or (FTextBuffer.Height <> H) then
  begin
    FreeAndNil(FTextBuffer);
    FTextBuffer := TACLDib.Create(W, H);
  end;

  FTextBuffer.Canvas.SetScaledFont(AFont);
  FTextBuffer.Canvas.Font.Color := clWhite;
  FTextBuffer.Canvas.Brush.Style := bsClear;

  if AFont.Shadow.Assigned then
  begin
    FTextBuffer.Reset;

    if AFont.Shadow.Direction = mzClient then
    begin
      for I := -AFont.Shadow.Size to AFont.Shadow.Size do
      for J := -AFont.Shadow.Size to AFont.Shadow.Size do
        if I <> J then
          Text32Output(FTextBuffer.Canvas, ATextOffset + Point(I, J));
    end
    else
    begin
      APoint := ATextOffset;
      for I := 1 to AFont.Shadow.Size do
      begin
        APoint := APoint + MapTextOffsets[AFont.Shadow.Direction];
        Text32Output(FTextBuffer.Canvas, APoint);
      end;
    end;
    Text32ApplyBlur(FTextBuffer, AFont.Shadow);
    Text32RecoverAlpha(FTextBuffer, TACLPixel32.Create(AFont.Shadow.Color));
    FTextBuffer.DrawBlend(ACanvas, ABounds.TopLeft);
  end;

  if ATextColor = TAlphaColor.Default then
    ATextColor := TAlphaColor.FromColor(acGetActualColor(AFont.Color, clBlack), AFont.ColorAlpha);

  if ATextColor.IsValid then
  begin
    FTextBuffer.Reset;
    Text32Output(FTextBuffer.Canvas, ATextOffset);
    Text32RecoverAlpha(FTextBuffer, TACLPixel32.Create(ATextColor));
    FTextBuffer.DrawBlend(ACanvas, ABounds.TopLeft);
  end;
end;

procedure DrawText32(ACanvas: TCanvas;
  const R: TRect; const AText: string; AFont: TACLFont);
begin
  if (AText <> '') and CanDraw(ACanvas, R, AFont) then
    DrawText32Core(ACanvas, PChar(AText), Length(AText), AFont, R, AFont.TextExtends.TopLeft, 0);
end;

procedure DrawText32(ACanvas: TCanvas; const R: TRect; AText: string; AFont: TACLFont;
  AAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AEndEllipsis: Boolean);
var
  LTextExtends: TRect;
  LTextOffset: TPoint;
  LTextSize: TSize;
begin
  if (AText <> '') and CanDraw(ACanvas, R, AFont) then
  begin
    MeasureCanvas.SetScaledFont(AFont);
    LTextExtends := AFont.TextExtends;
    LTextSize := acTextSize(MeasureCanvas, AText);
    if AEndEllipsis then
      acTextEllipsize(MeasureCanvas, AText, LTextSize, R.Width - LTextExtends.MarginsWidth);
    Inc(LTextSize.cy, LTextExtends.MarginsHeight);
    Inc(LTextSize.cx, LTextExtends.MarginsWidth);
    LTextOffset := acTextAlign(R, LTextSize, AAlignment, AVertAlignment);
    DrawText32Core(ACanvas, PChar(AText), Length(AText), AFont,
      TRect.Create(LTextOffset, LTextSize), LTextExtends.TopLeft, 0);
  end;
end;

procedure DrawText32Duplicated(ACanvas: TCanvas; const R: TRect;
  const AText: string; const ATextOffset: TPoint; ADuplicateOffset: Integer;
  AFont: TACLFont);
begin
  if (AText <> '') and CanDraw(ACanvas, R, AFont) then
  begin
    DrawText32Core(ACanvas, PChar(AText), Length(AText), AFont, R,
      ATextOffset + AFont.TextExtends.TopLeft, ADuplicateOffset);
  end;
end;

{$REGION ' Advanced Font '}

{ TACLFont }

destructor TACLFont.Destroy;
begin
  FreeAndNil(FShadow);
  inherited Destroy;
end;

procedure TACLFont.AfterConstruction;
begin
  inherited;
  FColorAlpha := MaxByte;
  FShadow := TACLFontShadow.Create(ChangeHandler);
end;

procedure TACLFont.Assign(Source: TPersistent);
begin
  inherited Assign(Source);

  if Source is TACLFont then
  begin
    ColorAlpha := TACLFont(Source).ColorAlpha;
    Shadow := TACLFont(Source).Shadow;
  end;
end;

function TACLFont.AppendTextExtends(const S: TSize): TSize;
var
  AExtends: TRect;
begin
  Result := S;
  if not Result.IsEmpty then
  begin
    AExtends := TextExtends;
    Inc(Result.cx, AExtends.MarginsWidth);
    Inc(Result.cy, AExtends.MarginsHeight);
  end;
end;

function TACLFont.MeasureSize(const S: PChar; ALength: Integer): TSize;
begin
  Result := AppendTextExtends(acTextSize(Self, S, ALength));
end;

function TACLFont.MeasureSize(const S: string): TSize;
begin
  Result := AppendTextExtends(acTextSize(Self, S));
end;

procedure TACLFont.ChangeHandler(Sender: TObject);
begin
  Changed;
end;

function TACLFont.GetAlphaColor: TAlphaColor;
begin
  Result := TAlphaColor.FromColor(Color, ColorAlpha);
end;

function TACLFont.GetTextExtends: TRect;
begin
  Result := Shadow.GetTextExtends;
end;

procedure TACLFont.SetAlphaColor(const Value: TAlphaColor);
begin
  Color := Value.ToColor;
  ColorAlpha := Value.A;
end;

procedure TACLFont.SetColorAlpha(const AValue: Byte);
begin
  if FColorAlpha <> AValue then
  begin
    FColorAlpha := AValue;
    Changed;
  end;
end;

procedure TACLFont.SetShadow(const AValue: TACLFontShadow);
begin
  FShadow.Assign(AValue);
end;

{ TACLFontShadow }

constructor TACLFontShadow.Create(AChangeEvent: TNotifyEvent);
begin
  inherited Create;
  Reset;
  FOnChange := AChangeEvent;
end;

procedure TACLFontShadow.Assign(Source: TPersistent);
begin
  if Source is TACLFontShadow then
  begin
    Color := TACLFontShadow(Source).Color;
    Direction := TACLFontShadow(Source).Direction;
    Size := TACLFontShadow(Source).Size;
    Blur := TACLFontShadow(Source).Blur;
  end;
end;

function TACLFontShadow.Equals(Obj: TObject): Boolean;
begin
  Result := (ClassType = Obj.ClassType) and
    (TACLFontShadow(Obj).Blur = Blur) and
    (TACLFontShadow(Obj).Color = Color) and
    (TACLFontShadow(Obj).Size = Size) and
    (TACLFontShadow(Obj).Direction = Direction);
end;

function TACLFontShadow.GetTextExtends: TRect;
var
  AIndent: Integer;
begin
  Result := NullRect;
  if Assigned then
  begin
    AIndent := Size + FBlurSize + IfThen(FBlurSize > 0, Size);
    if Direction in [mzLeftTop, mzTop, mzRightTop, mzClient] then
      Result.Top := AIndent
    else
      Result.Top := FBlurSize;

    if Direction in [mzLeftTop, mzLeft, mzLeftBottom, mzClient] then
      Result.Left := AIndent
    else
      Result.Left := FBlurSize;

    if Direction in [mzLeftBottom, mzBottom, mzRightBottom, mzClient] then
      Result.Bottom := AIndent
    else
      Result.Bottom := FBlurSize;

    if Direction in [mzRightTop, mzRight, mzRightBottom, mzClient] then
      Result.Right := AIndent
    else
      Result.Right := FBlurSize;
  end;
end;

procedure TACLFontShadow.Reset;
begin
  FColor := TAlphaColor.None;
  FDirection := mzRightBottom;
  FBlur := 0;
  FBlurSize := 0;
  FSize := 1;
  Changed;
end;

procedure TACLFontShadow.Changed;
begin
  CallNotifyEvent(Self, FOnChange);
end;

function TACLFontShadow.GetAssigned: Boolean;
begin
  Result := (Size > 0) and Color.IsValid;
end;

function TACLFontShadow.GetBlur: Integer;
begin
  Result := FBlur;
end;

function TACLFontShadow.GetColor: TAlphaColor;
begin
  Result := FColor;
end;

function TACLFontShadow.GetDirection: TACLMarginPart;
begin
  Result := FDirection;
end;

function TACLFontShadow.GetDrawIterations: Integer;
begin
  if not Assigned then
    Result := 0
  else
    if Direction = mzClient then
      Result := Size * 2
    else
      Result := Size;
end;

function TACLFontShadow.GetSize: Integer;
begin
  Result := FSize;
end;

procedure TACLFontShadow.SetBlur(AValue: Integer);
begin
  AValue := MaxMin(AValue, 0, 5 * BlurRadiusFactor);
  if FBlur <> AValue then
  begin
    FBlur := AValue;
    FBlurSize := (Blur div BlurRadiusFactor) + Ord(Blur mod BlurRadiusFactor <> 0);
    Changed;
  end;
end;

procedure TACLFontShadow.SetColor(AValue: TAlphaColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    Changed;
  end;
end;

procedure TACLFontShadow.SetDirection(AValue: TACLMarginPart);
begin
  if Direction <> AValue then
  begin
    FDirection := AValue;
    Changed;
  end;
end;

procedure TACLFontShadow.SetSize(AValue: Integer);
begin
  AValue := MinMax(AValue, 1, 3);
  if AValue <> Size then
  begin
    FSize := AValue;
    Changed;
  end;
end;

{$ENDREGION}

{$REGION ' TextLayout '}

{ TACLTextLayout32 }

constructor TACLTextLayout32.Create(AFont: TACLFont);
begin
  inherited Create(AFont);
end;

procedure TACLTextLayout32.Draw(ARender: TACLTextLayoutRender);
var
  LRender: TACLTextLayoutCanvasRender absolute ARender;
begin
  if not (ARender is TACLTextLayoutCanvasRender) then
    raise EInvalidArgument.Create(ClassName + ' - only ' + TACLTextLayoutCanvasRender.ClassName + ' supported');

  Calculate(ARender);
  if Font.Shadow.Assigned then
  begin
    FLayout.Export(TACLTextLayout32Painter.Create(Self, LRender, True, False), True);
    FLayout.Export(TACLTextLayout32PainterShadow.Create(Self, LRender), True);
    FLayout.Export(TACLTextLayout32Painter.Create(Self, LRender, False, True), True);
  end
  else
    FLayout.Export(TACLTextLayout32Painter.Create(Self, LRender, True, True), True);
end;

function TACLTextLayout32.GetFont: TACLFont;
begin
  Result := TACLFont(inherited Font);
end;

function TACLTextLayout32.GetPadding: TRect;
begin
  Result := Font.TextExtends;
end;

{$REGION ' Painters '}

{ TACLTextLayout32Painter }

constructor TACLTextLayout32Painter.Create(AOwner: TACLTextLayout;
  ACanvas: TACLTextLayoutCanvasRender; ADrawBackground, ADrawContent: Boolean);
begin
  inherited Create(AOwner, ACanvas);
  FCanvas := ACanvas.Canvas;
  TACLFont(Font).Shadow.Reset;
  FDrawBackground := ADrawBackground;
  FDrawContent := ADrawContent;
end;

procedure TACLTextLayout32Painter.FillBackground(ABlock: TACLTextLayoutBlock);
begin
  if Canvas.Brush.Style = bsSolid then
    acFillRect(Canvas, ABlock.Bounds, TAlphaColor.FromColor(Canvas.Brush.Color));
end;

function TACLTextLayout32Painter.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  if FDrawBackground then
    FillBackground(ABlock);
  Result := True;
end;

function TACLTextLayout32Painter.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  if FDrawBackground then
    FillBackground(ABlock);
  if FDrawContent then
    DrawText32Core(Canvas, ABlock.Text, ABlock.TextLength,
      TACLFont(Font), ABlock.Bounds, TACLFont(Font).TextExtends.TopLeft);
  Result := True;
end;

{ TACLTextLayout32PainterShadow }

constructor TACLTextLayout32PainterShadow.Create(
  AOwner: TACLTextLayout32; ACanvas: TACLTextLayoutCanvasRender);
var
  LClipBox: TRect;
  LLayoutBox: TRect;
  LPadding: TRect;
  LRect: TRect;
begin
  LPadding := AOwner.GetPadding;
  LLayoutBox := AOwner.FLayout.BoundingRect;
  LLayoutBox.Inflate(LPadding);
  FTargetCanvas := ACanvas.Canvas;

  LRect := LLayoutBox;
  if GetClipBox(FTargetCanvas.Handle, {$IFDEF FPC}@{$ENDIF}LClipBox) <> NULLREGION then
    IntersectRect(LRect, LLayoutBox, LClipBox);

  FBufferOrigin := LRect.TopLeft;
  FBuffer := TACLDib.Create(Max(LRect.Width, 1), Max(LRect.Height, 1));
  FBuffer.Reset;
  FBufferRender := DefaultTextLayoutCanvasRender.Create(FBuffer.Canvas);
  inherited Create(AOwner, FBufferRender);
  FShadow := AOwner.Font.Shadow;
  FShadowDirection := MapTextOffsets[FShadow.Direction];
  FShadowSize := FShadow.Size;
end;

destructor TACLTextLayout32PainterShadow.Destroy;
begin
  FreeAndNil(FBufferRender);
  FreeAndNil(FBuffer);
  inherited;
end;

procedure TACLTextLayout32PainterShadow.BeforeDestruction;
begin
  inherited;
  Text32ApplyBlur(FBuffer, FShadow);
  Text32RecoverAlpha(FBuffer, TACLPixel32.Create(FShadow.Color));
  FBuffer.DrawBlend(FTargetCanvas, FBufferOrigin);
end;

function TACLTextLayout32PainterShadow.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
var
  I, J: Integer;
begin
  if ABlock.TextWidth > 0 then
  begin
    Render.SetFill(clNone);
    Font.Color := clWhite;
    if FShadowDirection = NullPoint then
    begin
      for I := -FShadowSize to FShadowSize do
      for J := -FShadowSize to FShadowSize do
        if I <> J then
          Render.TextOut(ABlock,
            ABlock.Position.X + I - FBufferOrigin.X,
            ABlock.Position.Y + J - FBufferOrigin.Y);
    end
    else
      for I := 1 to FShadowSize do
      begin
        Render.TextOut(ABlock,
          ABlock.Position.X + I * FShadowDirection.X - FBufferOrigin.X,
          ABlock.Position.Y + I * FShadowDirection.Y - FBufferOrigin.Y);
      end;
  end;
  Result := True;
end;
{$ENDREGION}

initialization

finalization
  FreeAndNil(FTextBuffer);
  FreeAndNil(FTextBlur);
end.
