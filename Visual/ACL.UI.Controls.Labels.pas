﻿{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*              Label Controls               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Labels;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // Vcl
  Vcl.Controls,
  Vcl.ImgList,
  Vcl.Graphics,
  Vcl.ActnList,
  Vcl.ExtCtrls,
  // ACL
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.SkinImage,
  ACL.Math,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Shell;

type

  { TACLLabelSubControlOptions }

  TACLLabelSubControlOptions = class(TACLSubControlOptions);

  { TACLStyleLabel }

  TACLLabelEffect = (sleNone, sleContour, sleShadow);
  TACLStyleLabel = class(TACLStyle)
  strict private
    FEffect: TACLLabelEffect;
    FEffectSize: Integer;
    FShowLine: Boolean;
    FWordWrap: Boolean;

    function GetTextColor(Enabled: Boolean): TColor;
    procedure SetEffect(AValue: TACLLabelEffect);
    procedure SetEffectSize(AValue: Integer);
    procedure SetShowLine(AValue: Boolean);
    procedure SetWordWrap(AValue: Boolean);
  protected
    procedure DoAssign(Source: TPersistent); override;
    procedure InitializeResources; override;
  public
    property TextColor[Enabled: Boolean]: TColor read GetTextColor;
  published
    property ColorContent: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorTextHyperlink: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorLine1: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorLine2: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
    property ColorShadow: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
    property ColorText: TACLResourceColor index 5 read GetColor write SetColor stored IsColorStored;
    property ColorTextDisabled: TACLResourceColor index 6 read GetColor write SetColor stored IsColorStored;

    property Effect: TACLLabelEffect read FEffect write SetEffect default sleNone;
    property EffectSize: Integer read FEffectSize write SetEffectSize default 1;
    property ShowLine: Boolean read FShowLine write SetShowLine default False;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default False;
  end;

  { TACLLabel }

  TACLLabelVerticalAlignment = (lvaAuto, lvaTop, lvaCenter, lvaBottom);

  TACLLabel = class(TACLGraphicControl)
  strict private
    FAlignment: TAlignment;
    FAlignmentVert: TVerticalAlignment;
    FLineRect: TRect;
    FStyle: TACLStyleLabel;
    FSubControl: TACLLabelSubControlOptions;
    FTextRect: TRect;
    FTransparent: Boolean;
    FURL: UnicodeString;

    function GetIsURLMode: Boolean;
    function GetTextColor: TColor;
    procedure SetAlignment(AValue: TAlignment);
    procedure SetAlignmentVert(AValue: TVerticalAlignment);
    procedure SetStyle(AValue: TACLStyleLabel);
    procedure SetSubControl(AValue: TACLLabelSubControlOptions);
    procedure SetTransparent(AValue: Boolean);
    procedure SetUrl(const AValue: UnicodeString);
    //
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    function CanAutoSize(var ANewWidth, ANewHeight: Integer): Boolean; override;
    function CreateStyle: TACLStyleLabel; virtual;
    function CreateSubControlOptions: TACLLabelSubControlOptions; virtual;
    function GetCursor(const P: TPoint): TCursor; override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    function MeasureSize(AWidth: Integer = 0): TSize; virtual;
    //
    procedure Calculate(const R: TRect); overload; virtual;
    procedure Calculate; overload;
    procedure Click; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure Resize; override;
    procedure SetDefaultSize; override;
    procedure SetTargetDPI(AValue: Integer); override;
    //
    procedure DrawBackground(ACanvas: TCanvas); virtual;
    procedure DrawLabelLine(ACanvas: TCanvas); virtual;
    procedure DrawText(ACanvas: TCanvas; const R: TRect; AColor: TColor); virtual;
    procedure DrawTextEffects(ACanvas: TCanvas; var R: TRect); virtual;
    procedure Paint; override;
    //
    property IsURLMode: Boolean read GetIsURLMode;
    property TextColor: TColor read GetTextColor;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property AlignmentVert: TVerticalAlignment read FAlignmentVert write SetAlignmentVert default taVerticalCenter;
    property ResourceCollection;
    property Style: TACLStyleLabel read FStyle write SetStyle;
    property SubControl: TACLLabelSubControlOptions read FSubControl write SetSubControl;
    property Transparent: Boolean read FTransparent write SetTransparent default True;
    property URL: UnicodeString read FURL write SetUrl; // before Font and Cursor
    //
    property Align;
    property Anchors;
    property AutoSize;
    property Caption;
    property Cursor;
    property Enabled;
    property Font;
    property Height;
    property ParentFont;
    property Visible;
    property Width;
    //
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

  { TACLStyleValidationLabel }

  TACLStyleValidationLabel = class(TACLStyleLabel)
  protected
    procedure InitializeResources; override;
  published
    property Icons: TACLResourceTexture index 0 read GetTexture write SetTexture;
  end;

  { TACLValidationLabel }

  TACLValidationLabelIcon = (vliSuccess, vliWarning, vliError, vliCriticalWarning, vliInformation);

  TACLValidationLabel = class(TACLLabel)
  strict private
    FIcon: TACLValidationLabelIcon;

    function GetStyle: TACLStyleValidationLabel;
    procedure SetIcon(AValue: TACLValidationLabelIcon);
    procedure SetStyle(AValue: TACLStyleValidationLabel);
  protected
    procedure Calculate(const R: TRect); override;
    function CreateStyle: TACLStyleLabel; override;
    procedure DrawBackground(ACanvas: TCanvas); override;
    function GetTextOffset: Integer;
    function MeasureSize(AWidth: Integer = 0): TSize; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property AutoSize default True;
    property Icon: TACLValidationLabelIcon read FIcon write SetIcon default vliWarning;
    property Style: TACLStyleValidationLabel read GetStyle write SetStyle;
  end;

procedure acDrawLabelLine(ACanvas: TCanvas; const ALineRect, ATextRect: TRect; AColor1, AColor2: TAlphaColor);
implementation

uses
  System.Math;

procedure acDrawLabelLine(ACanvas: TCanvas; const ALineRect, ATextRect: TRect; AColor1, AColor2: TAlphaColor);
var
  ASaveIndex: Integer;
begin
  ASaveIndex := SaveDC(ACanvas.Handle);
  try
    acExcludeFromClipRegion(ACanvas.Handle, acRectInflate(ATextRect, 4, 0));
    acDrawComplexFrame(ACanvas.Handle, ALineRect, AColor1, AColor2, [mTop]);
  finally
    RestoreDC(ACanvas.Handle, ASaveIndex);
  end;
end;

{ TACLStyleLabel }

procedure TACLStyleLabel.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);

  if Source is TACLStyleLabel then
  begin
    Effect := TACLStyleLabel(Source).Effect;
    EffectSize := TACLStyleLabel(Source).EffectSize;
    WordWrap := TACLStyleLabel(Source).WordWrap;
    ShowLine := TACLStyleLabel(Source).ShowLine;
  end;
end;

procedure TACLStyleLabel.InitializeResources;
begin
  ColorContent.InitailizeDefaults('Labels.Colors.Background', True);
  ColorTextHyperlink.InitailizeDefaults('Labels.Colors.TextHyperlink');
  ColorLine1.InitailizeDefaults('Labels.Colors.Line1', True);
  ColorLine2.InitailizeDefaults('Labels.Colors.Line2', True);
  ColorShadow.InitailizeDefaults('Labels.Colors.TextShadow');
  ColorText.InitailizeDefaults('Labels.Colors.Text');
  ColorTextDisabled.InitailizeDefaults('Labels.Colors.TextDisabled');
  FEffectSize := 1;
end;

procedure TACLStyleLabel.SetEffect(AValue: TACLLabelEffect);
begin
  if AValue <> FEffect then
  begin
    FEffect := AValue;
    Changed;
  end;
end;

function TACLStyleLabel.GetTextColor(Enabled: Boolean): TColor;
begin
  if Enabled then
    Result := ColorText.AsColor
  else
    Result := ColorTextDisabled.AsColor;
end;

procedure TACLStyleLabel.SetEffectSize(AValue: Integer);
begin
  AValue := MinMax(AValue, -10, 10);
  if AValue <> FEffectSize then
  begin
    FEffectSize := AValue;
    Changed;
  end;
end;

procedure TACLStyleLabel.SetShowLine(AValue: Boolean);
begin
  if AValue <> FShowLine then
  begin
    if AValue then
      FWordWrap := False;
    FShowLine := AValue;
    Changed;
  end;
end;

procedure TACLStyleLabel.SetWordWrap(AValue: Boolean);
begin
  if AValue <> FWordWrap then
  begin
    if AValue then
      FShowLine := False;
    FWordWrap := AValue;
    Changed;
  end;
end;

{ TACLLabel }

constructor TACLLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTransparent := True;
  FStyle := CreateStyle;
  FSubControl := CreateSubControlOptions;
  FAlignmentVert := taVerticalCenter;
end;

destructor TACLLabel.Destroy;
begin
  FreeAndNil(FSubControl);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

function TACLLabel.CanAutoSize(var ANewWidth, ANewHeight: Integer): Boolean;
var
  ASize: TSize;
begin
  Result := True;
  if not (csReading in ComponentState) then
  begin
    SubControl.BeforeAutoSize(ANewWidth, ANewHeight);

    if Style.ShowLine then
      ASize := acSize(ANewWidth, MeasureSize.cy)
    else if Style.WordWrap then
      ASize := MeasureSize(ANewWidth)
    else
      ASize := MeasureSize;

    SubControl.AfterAutoSize(ASize.cx, ASize.cy);

    ANewWidth := ASize.cx;
    ANewHeight := ASize.cy;
  end;
end;

procedure TACLLabel.Calculate;
var
  R: TRect;
begin
  R := ClientRect;
  SubControl.AlignControl(R);
  Calculate(R);
end;

procedure TACLLabel.Calculate(const R: TRect);
var
  ATextSize: TSize;
begin
  FTextRect := R;
  MeasureCanvas.Font := Font;
  if Style.WordWrap then
    ATextSize := acTextSizeMultiline(MeasureCanvas, Caption, FTextRect.Width)
  else
    ATextSize := acTextSize(MeasureCanvas, Caption);

  if Style.Effect <> sleNone then
  begin
    Inc(ATextSize.cx, 2 * Abs(Style.EffectSize));
    Inc(ATextSize.cy, 2 * Abs(Style.EffectSize));
  end;

  case AlignmentVert of
    taAlignTop:
      FTextRect := acRectSetHeight(R, ATextSize.cy);
    taAlignBottom:
      FTextRect := acRectSetBottom(R, R.Bottom, ATextSize.cy);
  else
    FTextRect := acRectCenterVertically(R, ATextSize.cy);
  end;

  case Alignment of
    taLeftJustify:
      FTextRect.Right := FTextRect.Left + ATextSize.cx;
    taRightJustify:
      FTextRect.Left := FTextRect.Right - ATextSize.cx;
    taCenter:
      begin
        FTextRect.Left := (FTextRect.Left + FTextRect.Right - ATextSize.cx) div 2;
        FTextRect.Right := FTextRect.Left + ATextSize.cx;
      end;
  end;

  IntersectRect(FTextRect, FTextRect, ClientRect);
  FLineRect := FTextRect;
  if Odd(FLineRect.Height) then
    Inc(FLineRect.Bottom);
  FLineRect := acRectCenterVertically(FLineRect, 2);
  FLineRect.Left := R.Left;
  FLineRect.Right := R.Right;
end;

procedure TACLLabel.SetDefaultSize;
begin
  SetBounds(Left, Top, 75, 15);
end;

procedure TACLLabel.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Style.SetTargetDPI(AValue);
end;

procedure TACLLabel.Click;
begin
  if (Action <> nil) or Assigned(OnClick) then
    inherited Click
  else
    if IsURLMode then
      ShellExecute(URL)
    else
      if not SubControl.TrySetFocus then
        inherited Click;
end;

function TACLLabel.CreateStyle: TACLStyleLabel;
begin
  Result := TACLStyleLabel.Create(Self);
end;

function TACLLabel.CreateSubControlOptions: TACLLabelSubControlOptions;
begin
  Result := TACLLabelSubControlOptions.Create(Self);
end;

function TACLLabel.GetCursor(const P: TPoint): TCursor;
begin
  Result := inherited GetCursor(P);
  if (Result = crDefault) and IsURLMode then
    Result := crHandPoint;
end;

function TACLLabel.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if Transparent then
    Result := cbsTransparent
  else
    if Style.ColorContent.HasAlpha then
      Result := cbsSemitransparent
    else
      Result := cbsOpaque;
end;

function TACLLabel.MeasureSize(AWidth: Integer = 0): TSize;
begin
  MeasureCanvas.Font := Font;
  if Style.WordWrap then
    Result := acTextSizeMultiline(MeasureCanvas, Caption, AWidth)
  else
    Result := acTextSize(MeasureCanvas, Caption);

  if Style.Effect <> sleNone then
  begin
    Inc(Result.cx, 2 * Abs(Style.EffectSize));
    Inc(Result.cy, 2 * Abs(Style.EffectSize));
  end;
end;

procedure TACLLabel.Loaded;
begin
  inherited Loaded;
  if AutoSize then
    AdjustSize;
end;

procedure TACLLabel.MouseEnter;
begin
  inherited MouseEnter;
  if IsURLMode then
  begin
    UpdateCursor;
    Invalidate;
  end;
end;

procedure TACLLabel.MouseLeave;
begin
  inherited MouseLeave;
  if IsURLMode then
  begin
    UpdateCursor;
    Invalidate;
  end;
end;

procedure TACLLabel.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;
  if SubControl <> nil then
    SubControl.Notification(AComponent, AOperation);
end;

procedure TACLLabel.Resize;
begin
  inherited Resize;
  Calculate;
end;

procedure TACLLabel.DrawBackground(ACanvas: TCanvas);
begin
  if not Transparent then
    acFillRect(ACanvas.Handle, ClientRect, Style.ColorContent.Value);
end;

procedure TACLLabel.DrawLabelLine(ACanvas: TCanvas);
begin
  acDrawLabelLine(ACanvas, FLineRect, FTextRect, Style.ColorLine1.Value, Style.ColorLine2.Value);
end;

procedure TACLLabel.DrawText(ACanvas: TCanvas; const R: TRect; AColor: TColor);
begin
  if AColor <> clNone then
  begin
    ACanvas.Font := Font;
    ACanvas.Font.Color := AColor;
    ACanvas.Brush.Style := bsClear;
    if Style.WordWrap then
      acTextDraw(ACanvas, Caption, R, taLeftJustify, taAlignTop, False, False, True)
    else
      acTextDraw(ACanvas, Caption, R, taLeftJustify, taVerticalCenter, True, True);
  end;
end;

procedure TACLLabel.DrawTextEffects(ACanvas: TCanvas; var R: TRect);

  procedure AdjustTextRect(var R: TRect);
  begin
    case Style.Effect of
      sleContour:
        R := acRectInflate(R, -FastAbs(Style.EffectSize));
      sleShadow:
        if Style.EffectSize < 0 then
        begin
          Inc(R.Left, -Style.EffectSize);
          Inc(R.Top, -Style.EffectSize);
        end
        else
        begin
          Dec(R.Right, Style.EffectSize);
          Dec(R.Bottom, Style.EffectSize);
        end;
    end;
  end;

  procedure DrawLabelText(dX, dY: Integer);
  begin
    DrawText(ACanvas, acRectOffset(R, dX, dY), Style.ColorShadow.AsColor);
  end;

var
  I: Integer;
begin
  if Style.EffectSize <> 0 then
  begin
    AdjustTextRect(R);
    case Style.Effect of
      sleShadow:
        DrawLabelText(Style.EffectSize, Style.EffectSize);

      sleContour:
        for I := 1 to Abs(Style.EffectSize) do
        begin
          DrawLabelText( I,  I);
          DrawLabelText( I, -I);
          DrawLabelText(-I,  I);
          DrawLabelText(-I, -I);
        end;
    end;
  end;
end;

procedure TACLLabel.Paint;
var
  R: TRect;
begin
  DrawBackground(Canvas);

  R := FTextRect;
  DrawTextEffects(Canvas, R);
  DrawText(Canvas, R, TextColor);

  if Style.ShowLine then
    DrawLabelLine(Canvas);
end;

function TACLLabel.GetIsURLMode: Boolean;
begin
  Result := (URL <> '') and not IsDesigning;
end;

function TACLLabel.GetTextColor: TColor;
begin
  Result := Font.Color;
  if (Result = clWindowText) or (Result = clDefault) then
  begin
    if IsURLMode and MouseInControl then
      Result := Style.ColorTextHyperlink.AsColor
    else
      Result := Style.TextColor[Enabled];
  end;
end;

procedure TACLLabel.SetAlignment(AValue: TAlignment);
begin
  if AValue <> FAlignment then
  begin
    FAlignment := AValue;
    Calculate;
    Invalidate;
  end;
end;

procedure TACLLabel.SetAlignmentVert(AValue: TVerticalAlignment);
begin
  if AValue <> FAlignmentVert then
  begin
    FAlignmentVert := AValue;
    Calculate;
    Invalidate;
  end;
end;

procedure TACLLabel.SetStyle(AValue: TACLStyleLabel);
begin
  FStyle.Assign(AValue);
end;

procedure TACLLabel.SetSubControl(AValue: TACLLabelSubControlOptions);
begin
  SubControl.Assign(AValue);
end;

procedure TACLLabel.SetTransparent(AValue: Boolean);
begin
  if FTransparent <> AValue then
  begin
    FTransparent := AValue;
    UpdateTransparency;
  end;
end;

procedure TACLLabel.SetUrl(const AValue: UnicodeString);
begin
  if AValue <> FURL then
  begin
    FURL := AValue;

    if URL <> '' then
      Font.Style := Font.Style + [fsUnderline]
    else
      Font.Style := Font.Style - [fsUnderline];

    Calculate;
    Invalidate;
  end;
end;

procedure TACLLabel.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Calculate;
  if AutoSize then
    AdjustSize
end;

procedure TACLLabel.CMHitTest(var Message: TCMHitTest);
begin
  inherited;
  if IsURLMode then
    Message.Result := Ord(PtInRect(FTextRect, SmallPointToPoint(Message.Pos)));
end;

procedure TACLLabel.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Calculate;
  if AutoSize then
    AdjustSize
end;

{ TACLStyleValidationLabel }

procedure TACLStyleValidationLabel.InitializeResources;
begin
  inherited InitializeResources;
  Icons.InitailizeDefaults('Labels.Textures.Icons');
end;

{ TACLValidationLabel }

constructor TACLValidationLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIcon := vliWarning;
  AutoSize := True;
end;

procedure TACLValidationLabel.Calculate(const R: TRect);
var
  R1: TRect;
begin
  R1 := R;
  Inc(R1.Left, GetTextOffset);
  inherited Calculate(R1);
end;

function TACLValidationLabel.CreateStyle: TACLStyleLabel;
begin
  Result := TACLStyleValidationLabel.Create(Self);
end;

procedure TACLValidationLabel.DrawBackground(ACanvas: TCanvas);
var
  AGlyphRect: TRect;
begin
  inherited DrawBackground(ACanvas);
  AGlyphRect := acRectSetWidth(ClientRect, Style.Icons.FrameWidth);
  AGlyphRect := acRectCenterVertically(AGlyphRect, Style.Icons.FrameHeight);
  Style.Icons.Draw(ACanvas.Handle, AGlyphRect, Ord(Icon));
end;

function TACLValidationLabel.GetStyle: TACLStyleValidationLabel;
begin
  Result := TACLStyleValidationLabel(inherited Style);
end;

function TACLValidationLabel.GetTextOffset: Integer;
begin
  Result := Style.Icons.FrameWidth + ScaleFactor.Apply(acIndentBetweenElements);
end;

function TACLValidationLabel.MeasureSize(AWidth: Integer = 0): TSize;
begin
  if AWidth > 0 then
    Dec(AWidth, GetTextOffset);
  Result := inherited MeasureSize(AWidth);
  Result.cy := Max(Result.cy, Style.Icons.FrameHeight);
  Result.cx := Result.cx + GetTextOffset;
end;

procedure TACLValidationLabel.SetIcon(AValue: TACLValidationLabelIcon);
begin
  if FIcon <> AValue then
  begin
    FIcon := AValue;
    Invalidate;
  end;
end;

procedure TACLValidationLabel.SetStyle(AValue: TACLStyleValidationLabel);
begin
  Style.Assign(AValue);
end;

end.
