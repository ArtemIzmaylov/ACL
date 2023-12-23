{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{* Formatted Text with alpha channel support *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.TextLayout32;

{$I ACL.Config.inc}
{$SCOPEDENUMS ON}

interface

uses
  Winapi.Windows,
  // System
  System.UITypes,
  System.Types,
  System.Classes,
  // VCL
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.Ex.Gdip,
  ACL.Graphics.FontCache,
  ACL.Graphics.TextLayout,
  ACL.Math,
  ACL.Utils.Common,
  ACL.Utils.Strings;

const
  BlurRadiusFactor = 10;

type
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
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function AppendTextExtends(const S: TSize): TSize;
    function MeasureSize(const S: PWideChar; ALength: Integer): TSize; overload;
    function MeasureSize(const S: UnicodeString; AStartIndex: Integer = 1; ALength: Integer = MaxInt): TSize; overload;

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

  { TACLTextLayout32 }

  TACLTextLayout32 = class(TACLTextLayout)
  strict private
    function GetFont: TACLFont; inline;
  protected
    procedure CalculateCore(AMaxWidth, AMaxHeight: Integer); override;
    procedure DrawCore(ACanvas: TCanvas); override;
  public
    constructor Create(AFont: TACLFont);
    function MeasureSize: TSize; override;
    //
    property Font: TACLFont read GetFont;
  end;

  { TACLTextLayoutBaseRender32 }

  TACLTextLayoutBaseRender32 = class(TACLTextLayoutRender)
  strict private
    procedure FontChanged(Sender: TObject);
  protected
    FFont: TACLFont;
    FOrigin: TPoint;
  public
    constructor Create(AOwner: TACLTextLayout; ACanvas: TCanvas);
    destructor Destroy; override;
  end;

  { TACLTextLayoutRender32 }

  TACLTextLayoutRender32 = class(TACLTextLayoutBaseRender32)
  strict private
    FDrawBackground: Boolean;
    FDrawContent: Boolean;
  protected
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
    procedure FillBackground(ABlock: TACLTextLayoutBlock); inline;
  public
    constructor Create(AOwner: TACLTextLayout; ACanvas: TCanvas; ADrawBackground, ADrawContent: Boolean);
    destructor Destroy; override;
  end;

  { TACLTextLayoutShadowRender32 }

  TACLTextLayoutShadowRender32 = class(TACLTextLayoutBaseRender32)
  strict private
    FBuffer: TACLBitmapLayer;
    FBufferOrigin: TPoint;
    FShadow: TACLFontShadow;
    FTargetCanvas: TCanvas;
  protected
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  public
    constructor Create(AOwner: TACLTextLayout32; ACanvas: TCanvas);
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    //
    property Shadow: TACLFontShadow read FShadow;
  end;

  { TACLSimpleTextLayout32 }

  TACLSimpleTextLayout32 = class
  strict private
    FFont: TACLFont;
    FText: string;
    FTextViewInfo: TACLTextViewInfo;

    procedure FontChangeHandler(Sender: TObject);
    function GetSize: TSize;
    procedure SetText(const Value: string);
  protected
    procedure CheckCalculated;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Draw(DC: HDC; const R: TRect; AColor: TAlphaColor = TAlphaColor.Default);
    function ReduceWidth(AMaxWidth: Integer): Boolean;
    //
    property Font: TACLFont read FFont;
    property Size: TSize read GetSize;
    property Text: string read FText write SetText;
  end;

procedure DrawText32(DC: HDC; const R: TRect; AText: UnicodeString; AFont: TACLFont;
  AAlignment: TAlignment = taLeftJustify; AVertAlignment: TVerticalAlignment = taVerticalCenter; AEndEllipsis: Boolean = True);
procedure DrawText32Duplicated(DC: HDC; const R: TRect; const AText: UnicodeString;
  const ATextOffset: TPoint; ADuplicateOffset: Integer; AFont: TACLFont);
procedure DrawText32Prepared(DC: HDC; const R: TRect; const AText: UnicodeString; AFont: TACLFont); overload;
procedure DrawText32Prepared(DC: HDC; const R: TRect; const AText: PWideChar; ALength: Integer; AFont: TACLFont); overload;
procedure DrawText32Prepared(DC: HDC; const R: TRect; const ATextViewInfo: TACLTextViewInfo;
  AFont: TACLFont; AMaxLength: Integer = MaxInt; AColor: TAlphaColor = TAlphaColor.Default); overload;
implementation

uses
  System.Math,
  System.SysUtils;

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

var
  FGammaTable: array[Byte] of Byte;
  FGammaTableInitialized: Boolean;
  FTextBlur: TACLBlurFilter;
  FTextBuffer: TACLBitmapLayer;

function CheckCanDraw(DC: HDC; const R: TRect; AFont: TACLFont): Boolean; overload; inline;
begin
  Result := acRectVisible(DC, R) and
    ((AFont.ColorAlpha > 0) and (AFont.Color <> clNone) or AFont.Shadow.Assigned);
end;

function CheckCanDraw(DC: HDC; const R: TRect; const AText: UnicodeString; AFont: TACLFont): Boolean; overload; inline;
begin
  Result := (AText <> '') and CheckCanDraw(DC, R, AFont);
end;

function CheckCanDraw(DC: HDC; const R: TRect; const AText: TACLTextViewInfo; AFont: TACLFont): Boolean; overload; inline;
begin
  Result := (AText.Size.cx > 0) and CheckCanDraw(DC, R, AFont);
end;

procedure Text32ApplyBlur(ALayer: TACLBitmapLayer; AShadow: TACLFontShadow);
begin
  if AShadow.Blur > 0 then
  begin
    if FTextBlur = nil then
      FTextBlur := TACLBlurFilter.Create;
    FTextBlur.Radius := Round(AShadow.Blur / BlurRadiusFactor);
    FTextBlur.Apply(ALayer);
  end;
end;

procedure Text32RecoverAlpha(ALayer: TACLBitmapLayer; const ATextColor: TRGBQuad);
const
  K = 700; // [1..5000]
var
  AAlpha: Integer;
  Q: PRGBQuad;
begin
  if not FGammaTableInitialized then
  begin
    for var I := 0 to MaxByte do
      FGammaTable[I] := FastTrunc(MaxByte * Power(I / MaxByte, 1000 / K));
    FGammaTableInitialized := True;
  end;

  Q := PRGBQuad(ALayer.Colors);
  for var I := 1 to ALayer.ColorCount do
  begin
    if PDWORD(Q)^ and $00FFFFFF <> 0 then
    begin
      AAlpha := 128 +
        FGammaTable[Q^.rgbRed] * 77 +
        FGammaTable[Q^.rgbGreen] * 151 +
        FGammaTable[Q^.rgbBlue] * 28;
      AAlpha := AAlpha * ATextColor.rgbReserved shr 16;
      Q^.rgbBlue := TACLColors.PremultiplyTable[ATextColor.rgbBlue, AAlpha];
      Q^.rgbGreen := TACLColors.PremultiplyTable[ATextColor.rgbGreen, AAlpha];
      Q^.rgbRed := TACLColors.PremultiplyTable[ATextColor.rgbRed, AAlpha];
      Q^.rgbReserved := AAlpha;
    end
    else
      Q^.rgbReserved := 0;

    Inc(Q);
  end;
end;

procedure DrawText32Core(DC: HDC; const AText: PWideChar; ALength: Integer;
  ATextViewInfo: TACLTextViewInfo; AFont: TACLFont; const R: TRect; const ATextOffset: TPoint;
  ATextDuplicateIndent: Integer; ATextColor: TAlphaColor = TAlphaColor.Default);

  procedure Text32Output(DC: HDC; const Offset: TPoint);
  begin
    if ATextViewInfo <> nil then
    begin
      ATextViewInfo.DrawCore(DC, Offset.X, Offset.Y, ALength);
      if ATextDuplicateIndent > 0 then
        ATextViewInfo.DrawCore(DC, Offset.X + ATextDuplicateIndent, Offset.Y, ALength);
    end
    else
    begin
      ExtTextOutW(DC, Offset.X, Offset.Y, 0, nil, AText, ALength, nil);
      if ATextDuplicateIndent > 0 then
        ExtTextOutW(DC, Offset.X + ATextDuplicateIndent, Offset.Y, 0, nil, AText, ALength, nil);
    end;
  end;

var
  APoint: TPoint;
  I, J, W, H: Integer;
begin
  W := R.Width;
  H := R.Height;
  if (W <= 0) or (H <= 0) then
    Exit;

  if (ATextViewInfo = nil) and (AFont.Shadow.GetDrawIterations > 2) then
  begin
    ATextViewInfo := TACLTextViewInfo.Create(DC, AFont, AText, ALength);
    try
      DrawText32Core(DC, AText, ALength, ATextViewInfo, AFont, R, ATextOffset, ATextDuplicateIndent, ATextColor);
    finally
      ATextViewInfo.Free;
    end;
    Exit;
  end;

  if (FTextBuffer = nil) or (FTextBuffer.Width <> W) or (FTextBuffer.Height <> H) then
  begin
    FreeAndNil(FTextBuffer);
    FTextBuffer := TACLBitmapLayer.Create(W, H);
  end;

  SelectObject(FTextBuffer.Handle, AFont.Handle);
  SetTextColor(FTextBuffer.Handle, clWhite);
  SetBkColor(FTextBuffer.Handle, clBlack);
  SetBkMode(FTextBuffer.Handle, TRANSPARENT);

  if AFont.Shadow.Assigned then
  begin
    FTextBuffer.Reset;

    if AFont.Shadow.Direction = mzClient then
    begin
      for I := -AFont.Shadow.Size to AFont.Shadow.Size do
      for J := -AFont.Shadow.Size to AFont.Shadow.Size do
        if I <> J then
          Text32Output(FTextBuffer.Handle, ATextOffset + Point(I, J));
    end
    else
    begin
      APoint := ATextOffset;
      for I := 1 to AFont.Shadow.Size do
      begin
        APoint := APoint + MapTextOffsets[AFont.Shadow.Direction];
        Text32Output(FTextBuffer.Handle, APoint);
      end;
    end;
    Text32ApplyBlur(FTextBuffer, AFont.Shadow);
    Text32RecoverAlpha(FTextBuffer, TACLColors.ToQuad(AFont.Shadow.Color));
    acAlphaBlend(DC, FTextBuffer.Handle, R, FTextBuffer.ClientRect);
  end;

  if ATextColor = TAlphaColor.Default then
    ATextColor := TAlphaColor.FromColor(acGetActualColor(AFont.Color, clBlack), AFont.ColorAlpha);

  if ATextColor.IsValid then
  begin
    FTextBuffer.Reset;
    Text32Output(FTextBuffer.Handle, ATextOffset);
    Text32RecoverAlpha(FTextBuffer, TACLColors.ToQuad(ATextColor));
    acAlphaBlend(DC, FTextBuffer.Handle, R, FTextBuffer.ClientRect);
  end;
end;

procedure DrawText32(DC: HDC; const R: TRect; AText: UnicodeString; AFont: TACLFont;
  AAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AEndEllipsis: Boolean);
var
  LTextExtends: TRect;
  LTextOffset: TPoint;
  LTextSize: TSize;
begin
  if CheckCanDraw(DC, R, AText, AFont) then
  begin
    MeasureCanvas.Font := AFont;
    LTextExtends := AFont.TextExtends;
    LTextSize := acTextSize(MeasureCanvas, AText);
    if AEndEllipsis then
      acTextEllipsize(MeasureCanvas, AText, LTextSize, R.Width - LTextExtends.MarginsWidth);
    Inc(LTextSize.cy, LTextExtends.MarginsHeight);
    Inc(LTextSize.cx, LTextExtends.MarginsWidth);
    LTextOffset := acTextAlign(R, LTextSize, AAlignment, AVertAlignment);
    DrawText32Core(DC, PWideChar(AText), Length(AText), nil, AFont,
      TRect.Create(LTextOffset, LTextSize), LTextExtends.TopLeft, 0);
  end;
end;

procedure DrawText32Duplicated(DC: HDC; const R: TRect; const AText: UnicodeString;
  const ATextOffset: TPoint; ADuplicateOffset: Integer; AFont: TACLFont);
begin
  if CheckCanDraw(DC, R, AText, AFont) then
  begin
    DrawText32Core(DC, PWideChar(AText), Length(AText), nil, AFont, R,
      ATextOffset + AFont.TextExtends.TopLeft, ADuplicateOffset);
  end;
end;

procedure DrawText32Prepared(DC: HDC; const R: TRect; const AText: UnicodeString; AFont: TACLFont);
begin
  if CheckCanDraw(DC, R, AText, AFont) then
    DrawText32Core(DC, PWideChar(AText), Length(AText), nil, AFont, R, AFont.TextExtends.TopLeft, 0);
end;

procedure DrawText32Prepared(DC: HDC; const R: TRect;
  const ATextViewInfo: TACLTextViewInfo; AFont: TACLFont; AMaxLength: Integer; AColor: TAlphaColor);
begin
  if CheckCanDraw(DC, R, ATextViewInfo, AFont) then
    DrawText32Core(DC, nil, AMaxLength, ATextViewInfo, AFont, R, AFont.TextExtends.TopLeft, 0, AColor);
end;

procedure DrawText32Prepared(DC: HDC; const R: TRect; const AText: PWideChar; ALength: Integer; AFont: TACLFont);
begin
  if CheckCanDraw(DC, R, AText, AFont) then
    DrawText32Core(DC, AText, ALength, nil, AFont, R, AFont.TextExtends.TopLeft, 0);
end;

{ TACLFont }

constructor TACLFont.Create;
begin
  inherited Create;
  FColorAlpha := MaxByte;
  FShadow := TACLFontShadow.Create(ChangeHandler);
end;

destructor TACLFont.Destroy;
begin
  FreeAndNil(FShadow);
  inherited Destroy;
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

function TACLFont.MeasureSize(const S: PWideChar; ALength: Integer): TSize;
begin
  Result := AppendTextExtends(acTextSize(Self, S, ALength));
end;

function TACLFont.MeasureSize(const S: UnicodeString; AStartIndex: Integer = 1; ALength: Integer = MaxInt): TSize;
begin
  Result := AppendTextExtends(acTextSize(Self, S, AStartIndex, ALength));
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

{ TACLTextLayout32 }

constructor TACLTextLayout32.Create(AFont: TACLFont);
begin
  inherited Create(AFont);
end;

function TACLTextLayout32.MeasureSize: TSize;
begin
  Result := Font.AppendTextExtends(inherited);
end;

procedure TACLTextLayout32.CalculateCore(AMaxWidth, AMaxHeight: Integer);
var
  AExtends: TRect;
begin
  AExtends := Font.TextExtends;
  Dec(AMaxHeight, AExtends.MarginsHeight);
  Dec(AMaxWidth, AExtends.MarginsWidth);
  inherited;
end;

procedure TACLTextLayout32.DrawCore(ACanvas: TCanvas);
begin
  if Font.Shadow.Assigned then
  begin
    FLayout.Export(TACLTextLayoutRender32.Create(Self, ACanvas, True, False), True);
    FLayout.Export(TACLTextLayoutShadowRender32.Create(Self, ACanvas), True);
    FLayout.Export(TACLTextLayoutRender32.Create(Self, ACanvas, False, True), True);
  end
  else
    FLayout.Export(TACLTextLayoutRender32.Create(Self, ACanvas, True, True), True);
end;

function TACLTextLayout32.GetFont: TACLFont;
begin
  Result := TACLFont(inherited Font);
end;

{ TACLTextLayoutBaseRender32 }

constructor TACLTextLayoutBaseRender32.Create(AOwner: TACLTextLayout; ACanvas: TCanvas);
begin
  inherited Create(AOwner, ACanvas);
  FFont := TACLFont.Create;
  FFont.OnChange := FontChanged;
  FFont.Assign(AOwner.Font);
  FOrigin := FFont.TextExtends.TopLeft;
  Font := FFont;
end;

destructor TACLTextLayoutBaseRender32.Destroy;
begin
  FreeAndNil(FFont);
  inherited;
end;

procedure TACLTextLayoutBaseRender32.FontChanged(Sender: TObject);
begin
  Canvas.Font.Assign(FFont);
end;

{ TACLTextLayoutRender32 }

constructor TACLTextLayoutRender32.Create(AOwner: TACLTextLayout; ACanvas: TCanvas; ADrawBackground, ADrawContent: Boolean);
begin
  inherited Create(AOwner, ACanvas);
  FFont.Shadow.Reset;
  FDrawBackground := ADrawBackground;
  FDrawContent := ADrawContent;
  acMoveWindowOrg(Canvas.Handle, FOrigin.X, FOrigin.Y);
end;

destructor TACLTextLayoutRender32.Destroy;
begin
  acMoveWindowOrg(Canvas.Handle, -FOrigin.X, -FOrigin.Y);
  inherited;
end;

function TACLTextLayoutRender32.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  FillBackground(ABlock);
  if FDrawContent and (fsUnderline in Canvas.Font.Style) then
    DrawText32Prepared(Canvas.Handle, ABlock.Bounds, ' ', 1, FFont);
  Result := True;
end;

function TACLTextLayoutRender32.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  FillBackground(ABlock);
  if FDrawContent then
    DrawText32Prepared(Canvas.Handle, ABlock.Bounds, ABlock.Text, ABlock.TextLength, FFont);
  Result := True;
end;

procedure TACLTextLayoutRender32.FillBackground(ABlock: TACLTextLayoutBlock);
begin
  if FDrawBackground and HasBackground then
    acFillRect(Canvas.Handle, ABlock.Bounds, TAlphaColor.FromColor(Canvas.Brush.Color));
end;

{ TACLTextLayoutShadowRender32 }

constructor TACLTextLayoutShadowRender32.Create(AOwner: TACLTextLayout32; ACanvas: TCanvas);
var
  AClipBox: TRect;
  ALayoutBox: TRect;
  ARect: TRect;
begin
  ALayoutBox := AOwner.FLayout.BoundingRect;
  Inc(ALayoutBox.Bottom, AOwner.Font.TextExtends.MarginsHeight);
  Inc(ALayoutBox.Right, AOwner.Font.TextExtends.MarginsWidth);
  if GetClipBox(ACanvas.Handle, AClipBox) <> NULLREGION then
    IntersectRect(ARect, ALayoutBox, AClipBox);

  FTargetCanvas := ACanvas;
  FBuffer := TACLBitmapLayer.Create(Max(ARect.Width, 1), Max(ARect.Height, 1));
  FBufferOrigin := ARect.TopLeft;
  inherited Create(AOwner, FBuffer.Canvas);
  FShadow := FFont.Shadow;
  FOrigin := FOrigin - FBufferOrigin;
end;

destructor TACLTextLayoutShadowRender32.Destroy;
begin
  FreeAndNil(FBuffer);
  inherited;
end;

procedure TACLTextLayoutShadowRender32.BeforeDestruction;
begin
  inherited;
  Text32ApplyBlur(FBuffer, Shadow);
  Text32RecoverAlpha(FBuffer, TACLColors.ToQuad(Shadow.Color));
  FBuffer.DrawBlend(FTargetCanvas.Handle, FBufferOrigin);
end;

function TACLTextLayoutShadowRender32.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  Result := True;
end;

function TACLTextLayoutShadowRender32.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
var
  APoint: TPoint;
  AWindowOrg: TPoint;
begin
  if ABlock.TextWidth > 0 then
  begin
    SetBkColor(Canvas.Handle, clBlack);
    SetBkMode(Canvas.Handle, TRANSPARENT);
    SetTextColor(Canvas.Handle, clWhite);

    GetWindowOrgEx(Canvas.Handle, AWindowOrg);
    try
      APoint := AWindowOrg - FOrigin;
      if Shadow.Direction = mzClient then
      begin
        for var I := -Shadow.Size to Shadow.Size do
        for var J := -Shadow.Size to Shadow.Size do
          if I <> J then
          begin
            SetWindowOrgEx(Canvas.Handle, APoint.X - I, APoint.Y - J, nil);
            inherited;
          end;
      end
      else
        for var I := 1 to Shadow.Size do
        begin
          APoint := APoint - MapTextOffsets[Shadow.Direction];
          SetWindowOrgEx(Canvas.Handle, APoint.X, APoint.Y, nil);
          inherited;
        end;
    finally
      SetWindowOrgEx(Canvas.Handle, AWindowOrg.X, AWindowOrg.Y, nil);
    end;
  end;
  Result := True;
end;

{ TACLSimpleTextLayout32 }

constructor TACLSimpleTextLayout32.Create;
begin
  inherited Create;
  FFont := TACLFont.Create;
  FFont.OnChange := FontChangeHandler;
end;

destructor TACLSimpleTextLayout32.Destroy;
begin
  FreeAndNil(FTextViewInfo);
  FreeAndNil(FFont);
  inherited;
end;

procedure TACLSimpleTextLayout32.Draw(DC: HDC; const R: TRect; AColor: TAlphaColor = TAlphaColor.Default);
begin
  CheckCalculated;
  DrawText32Prepared(DC, R, FTextViewInfo, FFont, MaxInt, AColor);
end;

function TACLSimpleTextLayout32.ReduceWidth(AMaxWidth: Integer): Boolean;
var
  AReducedCharacters: Integer;
  AReducedWidth: Integer;
begin
  Result := Size.cx > AMaxWidth;
  if Result then
  begin
    Dec(AMaxWidth, Font.TextExtends.MarginsWidth);
    Dec(AMaxWidth, Font.MeasureSize(acEndEllipsis).cx);
    FTextViewInfo.AdjustToWidth(AMaxWidth, AReducedCharacters, AReducedWidth);
    FreeAndNil(FTextViewInfo);
    FText := Copy(FText, 1, Length(FText) - AReducedCharacters) + acEndEllipsis;
  end;
end;

procedure TACLSimpleTextLayout32.CheckCalculated;
begin
  if FTextViewInfo = nil then
    FTextViewInfo := TACLTextViewInfo.Create(MeasureCanvas.Handle, Font, FText);
end;

function TACLSimpleTextLayout32.GetSize: TSize;
begin
  CheckCalculated;
  Result := Font.AppendTextExtends(FTextViewInfo.Size);
end;

procedure TACLSimpleTextLayout32.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    FreeAndNil(FTextViewInfo);
  end;
end;

procedure TACLSimpleTextLayout32.FontChangeHandler(Sender: TObject);
begin
  FreeAndNil(FTextViewInfo);
end;

initialization

finalization
  FreeAndNil(FTextBuffer);
  FreeAndNil(FTextBlur);
end.
