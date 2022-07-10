{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*     Formatted Text with alpha channel     *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.TextLayout32;

{$I ACL.Config.inc}
{$SCOPEDENUMS ON}

interface

uses
  Windows,
  UITypes,
  Types,
  Classes,
  Graphics,
  // ACL
  ACL.Classes,
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.FontCache,
  ACL.Graphics.Gdiplus,
  ACL.Graphics.Layers,
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
  protected
    FFont: TACLFont;
    FOrigin: TPoint;

    procedure AssignCanvasParameters; override;
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
    procedure AddSpace(ABlock: TACLTextLayoutBlockSpace); override;
    procedure AddText(ABlock: TACLTextLayoutBlockText); override;
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
    procedure AddSpace(ABlock: TACLTextLayoutBlockSpace); override;
    procedure AddText(ABlock: TACLTextLayoutBlockText); override;
    procedure AssignCanvasParameters; override;
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

procedure DrawText32(DC: HDC; const R: TRect; const AText: UnicodeString; AFont: TACLFont;
  AAlignment: TAlignment = taLeftJustify; AVertAlignment: TVerticalAlignment = taVerticalCenter; AEndEllipsis: Boolean = True);
procedure DrawText32Duplicated(DC: HDC; const R: TRect; const AText: UnicodeString;
  const ATextOffset: TPoint; ADuplicateOffset: Integer; AFont: TACLFont);
procedure DrawText32Prepared(DC: HDC; const R: TRect; const AText: UnicodeString; AFont: TACLFont); overload;
procedure DrawText32Prepared(DC: HDC; const R: TRect; const AText: PWideChar; ALength: Integer; AFont: TACLFont); overload;
procedure DrawText32Prepared(DC: HDC; const R: TRect; const ATextViewInfo: TACLTextViewInfo;
  AFont: TACLFont; AMaxLength: Integer = MaxInt; AColor: TAlphaColor = TAlphaColor.Default); overload;
implementation

uses
  Math, SysUtils;

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

  { TACLTextBuffer}

  TACLTextBuffer = class
  strict private
    FBmpInfo: TBitmapInfo;
    FClientRect: TRect;
    FHandle: HBITMAP;
    FHeight: Integer;
    FPixels: PRGBQuad;
    FPixelsCount: Integer;
    FWidth: Integer;
  public
    constructor Create(AWidth, AHeight: Integer);
    destructor Destroy; override;
    function Compare(AWidth, AHeight: Integer): Boolean; inline;
    //
    property ClientRect: TRect read FClientRect;
    property Handle: HBITMAP read FHandle;
    property Height: Integer read FHeight;
    property Pixels: PRGBQuad read FPixels;
    property PixelsCount: Integer read FPixelsCount;
    property Width: Integer read FWidth;
  end;

  { TACLTextRenderer }

  TACLText32Renderer = class
  strict private
    class var FInstance: TACLText32Renderer;
  strict private
    FBuffer: TACLTextBuffer;
    FGammaTable: array[Byte] of Byte;
    FGammaTableInitialized: Boolean;

    procedure BuildGammaTable;
  protected
    FBlur: TACLBlurFilter;

    procedure DoDraw(DC, ATextDC: HDC; const AText: PWideChar; ALength: Integer;
      ATextViewInfo: TACLTextViewInfo; AFont: TACLFont; const R: TRect; const ATextOffset: TPoint;
      ATextDuplicateIndent: Integer; ATextColor: TAlphaColor = TAlphaColor.Default);
    procedure RecoverAlphaChannel(Q: PRGBQuad; ACount: Integer; const ATextColor: TRGBQuad);
    class procedure Finalize;
  public
    constructor Create;
    destructor Destroy; override;
    class procedure Draw(DC: HDC; const R: TRect; AText: UnicodeString; AFont: TACLFont;
      AAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AEndEllipsis: Boolean);
    class procedure DrawDuplicated(DC: HDC; const R: TRect; const AText: UnicodeString;
      const ATextOffset: TPoint; ADuplicateOffset: Integer; AFont: TACLFont);
    class function Instance: TACLText32Renderer;
  end;

function CheckCanDraw(DC: HDC; const R: TRect; AFont: TACLFont): Boolean; overload; inline;
begin
  Result := not acRectIsEmpty(R) and RectVisible(DC, R) and
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

procedure DrawText32(DC: HDC; const R: TRect; const AText: UnicodeString; AFont: TACLFont;
  AAlignment: TAlignment = taLeftJustify; AVertAlignment: TVerticalAlignment = taVerticalCenter; AEndEllipsis: Boolean = True);
begin
  if CheckCanDraw(DC, R, AText, AFont) then
    TACLText32Renderer.Draw(DC, R, AText, AFont, AAlignment, AVertAlignment, AEndEllipsis);
end;

procedure DrawText32Duplicated(DC: HDC; const R: TRect; const AText: UnicodeString;
  const ATextOffset: TPoint; ADuplicateOffset: Integer; AFont: TACLFont);
begin
  if CheckCanDraw(DC, R, AText, AFont) then
    TACLText32Renderer.DrawDuplicated(DC, R, AText, ATextOffset, ADuplicateOffset, AFont);
end;

procedure DrawText32Prepared(DC: HDC; const R: TRect; const AText: UnicodeString; AFont: TACLFont);
var
  ATextDC: HDC;
begin
  if CheckCanDraw(DC, R, AText, AFont) then
  begin
    ATextDC := CreateCompatibleDC(0);
    try
      TACLText32Renderer.Instance.DoDraw(DC, ATextDC, PChar(AText), Length(AText), nil, AFont, R, AFont.TextExtends.TopLeft, 0);
    finally
      DeleteDC(ATextDC);
    end;
  end;
end;

procedure DrawText32Prepared(DC: HDC; const R: TRect;
  const ATextViewInfo: TACLTextViewInfo; AFont: TACLFont; AMaxLength: Integer; AColor: TAlphaColor);
var
  ATextDC: HDC;
begin
  if CheckCanDraw(DC, R, ATextViewInfo, AFont) then
  begin
    ATextDC := CreateCompatibleDC(0);
    try
      TACLText32Renderer.Instance.DoDraw(DC, ATextDC, nil, AMaxLength,
        ATextViewInfo, AFont, R, AFont.TextExtends.TopLeft, 0, AColor);
    finally
      DeleteDC(ATextDC);
    end;
  end;
end;

procedure DrawText32Prepared(DC: HDC; const R: TRect; const AText: PWideChar; ALength: Integer; AFont: TACLFont);
var
  ATextDC: HDC;
begin
  if CheckCanDraw(DC, R, AText, AFont) then
  begin
    ATextDC := CreateCompatibleDC(0);
    try
      TACLText32Renderer.Instance.DoDraw(DC, ATextDC, AText, ALength, nil, AFont, R, AFont.TextExtends.TopLeft, 0);
    finally
      DeleteDC(ATextDC);
    end;
  end;
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
  if not acSizeIsEmpty(Result) then
  begin
    AExtends := TextExtends;
    Inc(Result.cx, acMarginWidth(AExtends));
    Inc(Result.cy, acMarginHeight(AExtends));
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

{ TACLTextBuffer }

constructor TACLTextBuffer.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  FWidth := AWidth;
  FHeight := AHeight;
  FPixelsCount := AWidth * AHeight;
  FClientRect := Rect(0, 0, Width, Height);
  acFillBitmapInfoHeader(FBmpInfo.bmiHeader, Width, Height);
  FHandle := CreateDIBSection(0, FBmpInfo, DIB_RGB_COLORS, Pointer(FPixels), 0, 0);
end;

destructor TACLTextBuffer.Destroy;
begin
  DeleteObject(FHandle);
  inherited Destroy;
end;

function TACLTextBuffer.Compare(AWidth, AHeight: Integer): Boolean;
begin
  Result := (AWidth = FWidth) and (AHeight = FHeight);
end;

{ TACLTextRenderer }

constructor TACLText32Renderer.Create;
begin
  inherited Create;
  FBlur := TACLBlurFilter.Create;
  BuildGammaTable;
end;

destructor TACLText32Renderer.Destroy;
begin
  FreeAndNil(FBuffer);
  FreeAndNil(FBlur);
  inherited Destroy;
end;

class procedure TACLText32Renderer.Draw(DC: HDC; const R: TRect; AText: UnicodeString; AFont: TACLFont;
  AAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AEndEllipsis: Boolean);
var
  ATextDC: HDC;
  ATextExtends: TRect;
  ATextOffset: TPoint;
  ATextSize: TSize;
begin
  ATextDC := CreateCompatibleDC(0);
  try
    SelectObject(ATextDC, AFont.Handle);
    ATextExtends := AFont.TextExtends;
    acTextPrepare(ATextDC, R, AEndEllipsis, AAlignment, AVertAlignment, AText, ATextSize, ATextOffset, ATextExtends);
    Instance.DoDraw(DC, ATextDC, PChar(AText), Length(AText), nil, AFont,
      Bounds(ATextOffset.X, ATextOffset.Y, ATextSize.cx, ATextSize.cy),
      ATextExtends.TopLeft, 0);
  finally
    DeleteDC(ATextDC);
  end;
end;

class procedure TACLText32Renderer.DrawDuplicated(DC: HDC; const R: TRect; const AText: UnicodeString;
  const ATextOffset: TPoint; ADuplicateOffset: Integer; AFont: TACLFont);
var
  ATextDC: HDC;
begin
  ATextDC := CreateCompatibleDC(0);
  try
    Instance.DoDraw(DC, ATextDC, PChar(AText), Length(AText), nil,
      AFont, R, acPointOffset(ATextOffset, AFont.TextExtends.TopLeft), ADuplicateOffset);
  finally
    DeleteDC(ATextDC);
  end;
end;

class procedure TACLText32Renderer.Finalize;
begin
  FreeAndNil(FInstance);
end;

class function TACLText32Renderer.Instance: TACLText32Renderer;
begin
  if FInstance = nil then
    FInstance := TACLText32Renderer.Create;
  Result := FInstance;
end;

procedure TACLText32Renderer.DoDraw(DC, ATextDC: HDC; const AText: PWideChar; ALength: Integer;
  ATextViewInfo: TACLTextViewInfo; AFont: TACLFont; const R: TRect; const ATextOffset: TPoint;
  ATextDuplicateIndent: Integer; ATextColor: TAlphaColor = TAlphaColor.Default);

  procedure DoTextOutput(const Offset: TPoint);
  begin
    if ATextViewInfo <> nil then
    begin
      ATextViewInfo.DrawCore(ATextDC, Offset.X, Offset.Y, ALength);
      if ATextDuplicateIndent > 0 then
        ATextViewInfo.DrawCore(ATextDC, Offset.X + ATextDuplicateIndent, Offset.Y, ALength);
    end
    else
    begin
      ExtTextOutW(ATextDC, Offset.X, Offset.Y, DT_NOPREFIX, nil, AText, ALength, nil);
      if ATextDuplicateIndent > 0 then
        ExtTextOutW(ATextDC, Offset.X + ATextDuplicateIndent, Offset.Y, DT_NOPREFIX, nil, AText, ALength, nil);
    end;
  end;

var
  AHandleOld: HBITMAP;
  APoint: TPoint;
  I, J, W, H: Integer;
begin
  W := acRectWidth(R);
  H := acRectHeight(R);
  if (W <= 0) or (H <= 0) then
    Exit;

  if (FBuffer = nil) or not FBuffer.Compare(W, H) then
  begin
    FreeAndNil(FBuffer);
    FBuffer := TACLTextBuffer.Create(W, H);
  end;

  AHandleOld := SelectObject(ATextDC, FBuffer.Handle);
  try
    SelectObject(ATextDC, AFont.Handle);
    SetTextColor(ATextDC, clWhite);
    SetBkColor(ATextDC, clBlack);
    SetBkMode(ATextDC, TRANSPARENT);

    if AFont.Shadow.Assigned then
    begin
      acResetRect(ATextDC, FBuffer.ClientRect);

      if AFont.Shadow.Direction = mzClient then
      begin
        for I := -AFont.Shadow.Size to AFont.Shadow.Size do
        for J := -AFont.Shadow.Size to AFont.Shadow.Size do
          if I <> J then
            DoTextOutput(acPointOffset(ATextOffset, I, J));
      end
      else
      begin
        APoint := ATextOffset;
        for I := 1 to AFont.Shadow.Size do
        begin
          APoint := acPointOffset(APoint, MapTextOffsets[AFont.Shadow.Direction]);
          DoTextOutput(APoint);
        end;
      end;
      if AFont.Shadow.Blur > 0 then
      begin
        FBlur.Radius := Round(AFont.Shadow.Blur / BlurRadiusFactor);
        FBlur.Apply(ATextDC, FBuffer.Pixels, FBuffer.Width, FBuffer.Height);
      end;
      RecoverAlphaChannel(FBuffer.Pixels, FBuffer.PixelsCount, TACLColors.ToQuad(AFont.Shadow.Color));
      acAlphaBlend(DC, ATextDC, R, FBuffer.ClientRect);
    end;

    if ATextColor = TAlphaColor.Default then
      ATextColor := TAlphaColor.FromColor(acGetActualColor(AFont.Color, clBlack), AFont.ColorAlpha);
    
    if ATextColor.IsValid then
    begin
      acResetRect(ATextDC, FBuffer.ClientRect);
      DoTextOutput(ATextOffset);
      RecoverAlphaChannel(FBuffer.Pixels, FBuffer.PixelsCount, TACLColors.ToQuad(ATextColor));
      acAlphaBlend(DC, ATextDC, R, FBuffer.ClientRect);
    end;
  finally
    SelectObject(ATextDC, AHandleOld);
  end;
end;

procedure TACLText32Renderer.BuildGammaTable;
const
  K = 700; // [1..5000]
var
  I: Integer;
begin
  if not FGammaTableInitialized then
  begin
    for I := 0 to MaxByte do
      FGammaTable[I] := FastTrunc(MaxByte * Power(I / MaxByte, 1000 / K));
    FGammaTableInitialized := True;
  end;
end;

procedure TACLText32Renderer.RecoverAlphaChannel(Q: PRGBQuad; ACount: Integer; const ATextColor: TRGBQuad);
var
  AAlpha: Integer;
  I: Integer;
begin
  for I := 1 to ACount do
  begin
    if (Q^.rgbBlue <> 0) or (Q^.rgbGreen <> 0) or (Q^.rgbRed <> 0) then
    begin
      AAlpha := (FGammaTable[Q^.rgbRed] * 77 + FGammaTable[Q^.rgbGreen] * 151 + FGammaTable[Q^.rgbBlue] * 28 + 128) * ATextColor.rgbReserved shr 16;
      Q^.rgbBlue := TACLColors.PremultiplyTable[ATextColor.rgbBlue, AAlpha];
      Q^.rgbGreen := TACLColors.PremultiplyTable[ATextColor.rgbGreen, AAlpha];
      Q^.rgbRed := TACLColors.PremultiplyTable[ATextColor.rgbRed, AAlpha];
      Q^.rgbReserved := AAlpha;
    end;
    Inc(Q);
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
  Dec(AMaxHeight, acMarginHeight(AExtends));
  Dec(AMaxWidth, acMarginWidth(AExtends));
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
  FFont.Assign(AOwner.Font);
  FOrigin := FFont.TextExtends.TopLeft;
end;

destructor TACLTextLayoutBaseRender32.Destroy;
begin
  FreeAndNil(FFont);
  inherited;
end;

procedure TACLTextLayoutBaseRender32.AssignCanvasParameters;
begin
  inherited;
  FFont.Assign(FCanvas.Font);
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

procedure TACLTextLayoutRender32.AddSpace(ABlock: TACLTextLayoutBlockSpace);
begin
  FillBackground(ABlock);
  if FDrawContent and (fsUnderline in Canvas.Font.Style) then
    DrawText32Prepared(Canvas.Handle, ABlock.Bounds, ' ', 1, FFont);
end;

procedure TACLTextLayoutRender32.AddText(ABlock: TACLTextLayoutBlockText);
begin
  FillBackground(ABlock);
  if FDrawContent then
  {$IFDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
    DrawText32Prepared(Canvas.Handle, ABlock.Bounds, ABlock.TextViewInfo, FFont);
  {$ELSE}
    DrawText32Prepared(Canvas.Handle, ABlock.Bounds, ABlock.Text, ABlock.TextLength, FFont);
  {$ENDIF}
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
  Inc(ALayoutBox.Bottom, acMarginHeight(AOwner.Font.TextExtends));
  Inc(ALayoutBox.Right, acMarginWidth(AOwner.Font.TextExtends));
  if GetClipBox(ACanvas.Handle, AClipBox) <> NULLREGION then
    IntersectRect(ARect, ALayoutBox, AClipBox);

  FTargetCanvas := ACanvas;
  FBuffer := TACLBitmapLayer.Create(Max(ARect.Width, 1), Max(ARect.Height, 1));
  FBufferOrigin := ARect.TopLeft;
  inherited Create(AOwner, FBuffer.Canvas);
  FShadow := FFont.Shadow;
  FOrigin := acPointOffsetNegative(FOrigin, FBufferOrigin);
end;

destructor TACLTextLayoutShadowRender32.Destroy;
begin
  FreeAndNil(FBuffer);
  inherited;
end;

procedure TACLTextLayoutShadowRender32.BeforeDestruction;
begin
  inherited;

  if Shadow.Blur > 0 then
  begin
    TACLText32Renderer.Instance.FBlur.Radius := Round(Shadow.Blur / BlurRadiusFactor);
    TACLText32Renderer.Instance.FBlur.Apply(FBuffer);
  end;

  TACLText32Renderer.Instance.RecoverAlphaChannel(
    PRGBQuad(FBuffer.Colors), FBuffer.ColorCount, TACLColors.ToQuad(Shadow.Color));

  FBuffer.DrawBlend(FTargetCanvas.Handle, FBufferOrigin);
end;

procedure TACLTextLayoutShadowRender32.AddSpace(ABlock: TACLTextLayoutBlockSpace);
begin
  // do nothing
end;

procedure TACLTextLayoutShadowRender32.AddText(ABlock: TACLTextLayoutBlockText);
var
  APoint: TPoint;
  AWindowOrg: TPoint;
  I, J: Integer;
begin
  if ABlock.VisibleLength > 0 then
  begin
    GetWindowOrgEx(Canvas.Handle, AWindowOrg);
    try
      APoint := acPointOffsetNegative(AWindowOrg, FOrigin);
      if Shadow.Direction = mzClient then
      begin
        for I := -Shadow.Size to Shadow.Size do
        for J := -Shadow.Size to Shadow.Size do
          if I <> J then
          begin
            SetWindowOrgEx(Canvas.Handle, APoint.X - I, APoint.Y - J, nil);
            inherited;
          end;
      end
      else
        for I := 1 to Shadow.Size do
        begin
          APoint := acPointOffsetNegative(APoint, MapTextOffsets[Shadow.Direction]);
          SetWindowOrgEx(Canvas.Handle, APoint.X, APoint.Y, nil);
          inherited;
        end;
    finally
      SetWindowOrgEx(Canvas.Handle, AWindowOrg.X, AWindowOrg.Y, nil);
    end;
  end;
end;

procedure TACLTextLayoutShadowRender32.AssignCanvasParameters;
begin
  inherited;
  SetBkColor(Canvas.Handle, clBlack);
  SetBkMode(Canvas.Handle, TRANSPARENT);
  SetTextColor(Canvas.Handle, clWhite);
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
    Dec(AMaxWidth, acMarginWidth(Font.TextExtends));
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
  TACLText32Renderer.Finalize;
end.
