////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Advanced Labels
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.Labels;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // Vcl
  {Vcl.}ActnList,
  {Vcl.}Controls,
  {Vcl.}Forms,
  {Vcl.}ExtCtrls,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  // ACL
  ACL.FastCode,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.TextLayout,
  ACL.Graphics.SkinImage,
  ACL.Math,
  ACL.UI.Controls.Base,
  ACL.UI.HintWindow,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Shell,
  ACL.Utils.Strings;

type

{$REGION ' Custom Label '}

  TACLLabelSubControlOptions = class(TACLSubControlOptions);
  TACLLabelVerticalAlignment = (lvaAuto, lvaTop, lvaCenter, lvaBottom);

  { TACLStyleLabel }

  TACLStyleLabel = class(TACLStyle)
  strict private
    FShowLine: Boolean;
    FWordWrap: Boolean;

    function GetTextColor(Enabled: Boolean): TColor;
    procedure SetShowLine(AValue: Boolean);
    procedure SetWordWrap(AValue: Boolean);
  protected
    procedure DoAssign(Source: TPersistent); override;
    procedure InitializeResources; override;
  public
    property TextColor[Enabled: Boolean]: TColor read GetTextColor;
  published
    property ColorContent: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorLine1: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorLine2: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorText: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
    property ColorTextDisabled: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
    property ColorTextHyperlink: TACLResourceColor index 5 read GetColor write SetColor stored IsColorStored;
    property ShowLine: Boolean read FShowLine write SetShowLine default False;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default False;
  end;

  { TACLCustomLabel }

  TACLCustomLabel = class(TACLGraphicControl)
  strict private
    class var FHintData: TACLHintData;
  strict private
    FAlignment: TAlignment;
    FAlignmentVert: TVerticalAlignment;
    FEndEllipsis: Boolean;
    FStyle: TACLStyleLabel;
    FSubControl: TACLLabelSubControlOptions;
    FTransparent: Boolean;

    FOnHyperlink: TACLHyperlinkEvent;

  {$IFDEF FPC}
    function IsWidthMatters: Boolean;
  {$ENDIF}
    procedure SetAlignment(AValue: TAlignment);
    procedure SetAlignmentVert(AValue: TVerticalAlignment);
    procedure SetStyle(AValue: TACLStyleLabel);
    procedure SetSubControl(AValue: TACLLabelSubControlOptions);
    procedure SetTransparent(AValue: Boolean);
    // Messages
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
  protected
    FTextRect: TRect;
    FTextTruncated: Boolean;

    procedure BoundsChanged; override;
    procedure Calculate(ABounds: TRect); virtual;
    function CanAutoSize(var ANewWidth, ANewHeight: Integer): Boolean; override;
    procedure Click; override;
    function CreateStyle: TACLStyleLabel; virtual;
    function CreateSubControlOptions: TACLLabelSubControlOptions; virtual;
    function GetDefaultTextColor: TColor; virtual;
    function GetHyperlinkAt(const P: TPoint; out AUrl: string): Boolean; virtual; abstract;
    procedure Loaded; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure Paint; override;
    procedure PaintText; virtual; abstract;
    procedure ResourceChanged; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateTransparency; override;

    // Properties
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property AlignmentVert: TVerticalAlignment read FAlignmentVert write SetAlignmentVert default taVerticalCenter;
    property EndEllipsis: Boolean read FEndEllipsis write FEndEllipsis default False;
    property Style: TACLStyleLabel read FStyle write SetStyle;
    property SubControl: TACLLabelSubControlOptions read FSubControl write SetSubControl;
    property Transparent: Boolean read FTransparent write SetTransparent default True;
    // Events
    property OnHyperlink: TACLHyperlinkEvent read FOnHyperlink write FOnHyperlink;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function MeasureSize(AWidth: Integer = 0): TSize; virtual; abstract;
  {$IFDEF FPC}
    procedure ShouldAutoAdjust(var AWidth, AHeight: Boolean); override;
  {$ENDIF}
  end;
{$ENDREGION}

{$REGION ' Label '}

  { TACLLabel }

  TACLLabel = class(TACLCustomLabel)
  strict private
    FUrl: string;
    procedure SetUrl(const AValue: string);
  protected
    function GetDefaultTextColor: TColor; override;
    function GetHyperlinkAt(const P: TPoint; out AUrl: string): Boolean; override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure PaintText; override;
    //# Messages
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
  public
    function MeasureSize(AWidth: Integer = 0): TSize; override;
  published
    property Align;
    property Alignment;
    property AlignmentVert;
    property Anchors;
    property AutoSize;
    property Caption;
    property Constraints;
    property Cursor;
    property Enabled;
    property EndEllipsis;
    property Font;
    property Height;
    property ParentFont;
    property ResourceCollection;
    property Style;
    property SubControl;
    property Transparent;
    property URL: string read FUrl write SetUrl;
    property Visible;
    property Width;
    //# Events
    property OnClick;
    property OnDblClick;
    property OnHyperlink;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

{$ENDREGION}

{$REGION ' Formatted Label '}

  { TACLFormattedLabel }

  TACLFormattedLabel = class(TACLCustomLabel)
  strict private
    FText: TACLTextLayout;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    function GetHyperlinkAt(const P: TPoint; out AUrl: string): Boolean; override;
    procedure PaintText; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function MeasureSize(AWidth: Integer = 0): TSize; override;
  published
    property Align;
    property Alignment;
    property AlignmentVert;
    property Anchors;
    property AutoSize;
    property Caption;
    property Constraints;
    property Cursor;
    property Enabled;
    property Font;
    property Height;
    property ParentFont;
    property ResourceCollection;
    property Style;
    property SubControl;
    property Transparent;
    property Visible;
    property Width;
    //# Events
    property OnClick;
    property OnDblClick;
    property OnHyperlink;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

{$ENDREGION}

{$REGION ' Validation Label '}

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
    procedure Calculate(ABounds: TRect); override;
    function CreateStyle: TACLStyleLabel; override;
    function GetTextOffset: Integer;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    function MeasureSize(AWidth: Integer = 0): TSize; override;
    procedure SetCaption(const AValue: string; AIcon: TACLValidationLabelIcon);
  published
    property AutoSize default True;
    property Icon: TACLValidationLabelIcon read FIcon write SetIcon default vliWarning;
    property Style: TACLStyleValidationLabel read GetStyle write SetStyle;
  end;

{$ENDREGION}

procedure acDrawLabelLine(ACanvas: TCanvas;
  const ARect, ATextRect: TRect; AColor1, AColor2: TAlphaColor;
  const ATextAlignment: TAlignment);
implementation

{$IFNDEF FPC}
uses
  ACL.Graphics.SkinImageSet; // inlining
{$ENDIF}

procedure acDrawLabelLine(ACanvas: TCanvas;
  const ARect, ATextRect: TRect; AColor1, AColor2: TAlphaColor;
  const ATextAlignment: TAlignment);
var
  Y: Integer;
begin
  Y := ARect.CenterTo(0, 2).Top + Ord(Odd(ATextRect.Height));
  if ATextAlignment in [taLeftJustify, taCenter] then
  begin
    acFillRect(ACanvas, Rect(ATextRect.Right + 4, Y + 0, ARect.Right, Y + 1), AColor1);
    acFillRect(ACanvas, Rect(ATextRect.Right + 4, Y + 1, ARect.Right, Y + 2), AColor2);
  end;
  if ATextAlignment in [taCenter, taRightJustify] then
  begin
    acFillRect(ACanvas, Rect(ARect.Left, Y + 0, ATextRect.Left - 4, Y + 1), AColor1);
    acFillRect(ACanvas, Rect(ARect.Left, Y + 1, ATextRect.Left - 4, Y + 2), AColor2);
  end;
end;

{$REGION ' Custom Label '}

{ TACLStyleLabel }

procedure TACLStyleLabel.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);
  if Source is TACLStyleLabel then
  begin
    WordWrap := TACLStyleLabel(Source).WordWrap;
    ShowLine := TACLStyleLabel(Source).ShowLine;
  end;
end;

procedure TACLStyleLabel.InitializeResources;
begin
  ColorContent.InitailizeDefaults('Labels.Colors.Background', True);
  ColorLine1.InitailizeDefaults('Labels.Colors.Line1', True);
  ColorLine2.InitailizeDefaults('Labels.Colors.Line2', True);
  ColorText.InitailizeDefaults('Labels.Colors.Text');
  ColorTextDisabled.InitailizeDefaults('Labels.Colors.TextDisabled');
  ColorTextHyperlink.InitailizeDefaults('Labels.Colors.TextHyperlink');
end;

function TACLStyleLabel.GetTextColor(Enabled: Boolean): TColor;
begin
  if Enabled then
    Result := ColorText.AsColor
  else
    Result := ColorTextDisabled.AsColor;
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

{ TACLCustomLabel }

constructor TACLCustomLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStyle := CreateStyle;
  FDefaultSize := TSize.Create(75, 15);
  FSubControl := CreateSubControlOptions;
  FAlignmentVert := taVerticalCenter;
  FTransparent := True;
end;

destructor TACLCustomLabel.Destroy;
begin
  FreeAndNil(FSubControl);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLCustomLabel.BoundsChanged;
begin
  inherited;
  Calculate(ClientRect);
end;

procedure TACLCustomLabel.Calculate(ABounds: TRect);
var
  LTextSize: TSize;
begin
  SubControl.AlignControl(ABounds);

  FTextRect := ABounds;
  LTextSize := MeasureSize(FTextRect.Width);
  FTextTruncated := (LTextSize.cx > FTextRect.Width) or (LTextSize.cy > FTextRect.Height);
  if FTextTruncated then
  begin
    LTextSize.cx := Min(LTextSize.cx, FTextRect.Width);
    LTextSize.cy := Min(LTextSize.cy, FTextRect.Height);
  end;

  case AlignmentVert of
    taAlignTop:
      FTextRect.Height := LTextSize.Height;
    taAlignBottom:
      FTextRect.Top := FTextRect.Bottom - LTextSize.Height;
  else
    FTextRect.CenterVert(LTextSize.Height);
  end;

  case Alignment of
    taLeftJustify:
      FTextRect.Right := FTextRect.Left + LTextSize.Width;
    taRightJustify:
      FTextRect.Left := FTextRect.Right - LTextSize.Width;
    taCenter:
      FTextRect.CenterHorz(LTextSize.Width);
  end;
end;

function TACLCustomLabel.CanAutoSize(var ANewWidth, ANewHeight: Integer): Boolean;
var
  LSize: TSize;
begin
  Result := True;
  if not (csReading in ComponentState) then
  begin
    SubControl.BeforeAutoSize(ANewWidth, ANewHeight);

    if Style.ShowLine then
      LSize := TSize.Create(ANewWidth, MeasureSize.cy)
    else if Style.WordWrap then
      LSize := MeasureSize(ANewWidth)
    else
      LSize := MeasureSize;

    ANewWidth := LSize.cx;
    ANewHeight := LSize.cy;
    SubControl.AfterAutoSize(ANewWidth, ANewHeight);
  end;
end;

procedure TACLCustomLabel.Click;
var
  LUrl: string;
begin
  if (Action <> nil) or Assigned(OnClick) then
    inherited Click
  else if GetHyperlinkAt(CalcCursorPos, LUrl) then
    CallHyperlink(Self, OnHyperlink, LUrl)
  else if not SubControl.TrySetFocus then
    inherited Click;
end;

procedure TACLCustomLabel.CMHintShow(var Message: TCMHintShow);
begin
  inherited;
  if FTextTruncated and (Message.HintInfo^.HintStr = '') then
  begin
    FHintData.Area := ClientRect;
    FHintData.Font := acFontToString(Font);
    FHintData.Text := Text;
    FHintData.TextRect := FTextRect;
    Message.HintInfo^.HintPos := ClientToScreen(FTextRect.TopLeft);
    Message.HintInfo^.HintStr := Text;
    Message.HintInfo^.HintData := @FHintData;
    Message.HintInfo^.HintWindowClass := TACLHintWindow;
  end;
end;

procedure TACLCustomLabel.CMTextChanged(var Message: TMessage);
begin
  inherited;
  ResourceChanged;
end;

procedure TACLCustomLabel.CMVisibleChanged(var Message: TMessage);
begin
  SubControl.UpdateVisibility;
  inherited;
end;

function TACLCustomLabel.CreateStyle: TACLStyleLabel;
begin
  Result := TACLStyleLabel.Create(Self);
end;

function TACLCustomLabel.CreateSubControlOptions: TACLLabelSubControlOptions;
begin
  Result := TACLLabelSubControlOptions.Create(Self);
end;

function TACLCustomLabel.GetDefaultTextColor: TColor;
begin
  Result := Font.Color;
  if (Result = clWindowText) or (Result = clDefault) then
    Result := Style.TextColor[Enabled];
end;

procedure TACLCustomLabel.Loaded;
begin
  inherited;
  Perform(CM_TEXTCHANGED, 0, 0);
end;

procedure TACLCustomLabel.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LUrl: string;
begin
  inherited;
  if not (csDesigning in ComponentState) then
  begin
    if GetHyperlinkAt(Point(X, Y), LUrl) then
      Cursor := crHandPoint
    else
      Cursor := crDefault;
  end;
end;

procedure TACLCustomLabel.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;
  if SubControl <> nil then
    SubControl.Notification(AComponent, AOperation);
end;

procedure TACLCustomLabel.Paint;
begin
  inherited;
  if not Transparent then
    acFillRect(Canvas, ClientRect, Style.ColorContent.Value);
  if Style.ShowLine then
  begin
    acDrawLabelLine(Canvas,
      ClientRect, FTextRect,
      Style.ColorLine1.Value,
      Style.ColorLine2.Value, Alignment);
  end;
  if not FTextRect.IsEmpty then
  begin
    Canvas.Font := Font;
    Canvas.Font.Color := GetDefaultTextColor;
    Canvas.Brush.Style := bsClear;
    if Canvas.Font.Color <> clNone then
      PaintText;
  end;
end;

procedure TACLCustomLabel.ResourceChanged;
begin
  if csDestroying in ComponentState then
    Exit;
  if AutoSize then
    AdjustSize;
  BoundsChanged;
  UpdateTransparency;
  Invalidate;
end;

procedure TACLCustomLabel.SetAlignment(AValue: TAlignment);
begin
  if AValue <> FAlignment then
  begin
    FAlignment := AValue;
    BoundsChanged;
    Invalidate;
  end;
end;

procedure TACLCustomLabel.SetAlignmentVert(AValue: TVerticalAlignment);
begin
  if AValue <> FAlignmentVert then
  begin
    FAlignmentVert := AValue;
    BoundsChanged;
    Invalidate;
  end;
end;

procedure TACLCustomLabel.SetStyle(AValue: TACLStyleLabel);
begin
  FStyle.Assign(AValue);
end;

procedure TACLCustomLabel.SetSubControl(AValue: TACLLabelSubControlOptions);
begin
  SubControl.Assign(AValue);
end;

procedure TACLCustomLabel.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Style.SetTargetDPI(AValue);
end;

procedure TACLCustomLabel.SetTransparent(AValue: Boolean);
begin
  if FTransparent <> AValue then
  begin
    FTransparent := AValue;
    UpdateTransparency;
    Invalidate;
  end;
end;

{$IFDEF FPC}
function TACLCustomLabel.IsWidthMatters: Boolean;
begin
  Result := (Align in [alTop, alBottom, alClient]) or Style.WordWrap or Style.ShowLine;
end;

procedure TACLCustomLabel.ShouldAutoAdjust(var AWidth, AHeight: Boolean);
begin
  AWidth  := not AutoSize or IsWidthMatters;
  AHeight := not AutoSize;
end;
{$ENDIF}

procedure TACLCustomLabel.UpdateTransparency;
begin
  if Transparent or Style.ColorContent.HasAlpha then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque];
end;
{$ENDREGION}

{$REGION ' Label '}

{ TACLLabel }

procedure TACLLabel.CMHitTest(var Message: TCMHitTest);
begin
  if Url <> '' then
    Message.Result := Ord(PtInRect(FTextRect, SmallPointToPoint(Message.Pos)))
  else
    inherited;
end;

function TACLLabel.MeasureSize(AWidth: Integer = 0): TSize;
var
  LText: string;
begin
  LText := Caption;
  MeasureCanvas.SetScaledFont(Font);
  if LText = '' then
    Result := TSize.Create(0, acFontHeight(MeasureCanvas))
  else if Style.WordWrap then
    Result := acTextSizeMultiline(MeasureCanvas, LText, AWidth)
  else
    Result := acTextSize(MeasureCanvas, LText);
end;

procedure TACLLabel.MouseEnter;
begin
  inherited;
  if URL <> '' then Invalidate;
end;

procedure TACLLabel.MouseLeave;
begin
  inherited;
  if URL <> '' then Invalidate;
end;

procedure TACLLabel.PaintText;
begin
  if Url <> '' then
    Canvas.Font.Style := [fsUnderline];
  acTextDraw(Canvas, Caption, FTextRect, taLeftJustify, taAlignTop,
    EndEllipsis and FTextTruncated, False, Style.WordWrap);
end;

function TACLLabel.GetDefaultTextColor: TColor;
begin
  if MouseInControl and (Url <> '') and not (csDesigning in ComponentState) then
    Result := Style.ColorTextHyperlink.AsColor
  else
    Result := inherited;
end;

function TACLLabel.GetHyperlinkAt(const P: TPoint; out AUrl: string): Boolean;
begin
  AUrl := FUrl;
  Result := AUrl <> '';
end;

procedure TACLLabel.SetUrl(const AValue: string);
begin
  if AValue <> FUrl then
  begin
    FUrl := AValue;
    BoundsChanged;
    Invalidate;
  end;
end;

{$ENDREGION}

{$REGION ' Formatted Label '}
type

  { TACLLabelFormattedText }

  TACLLabelFormattedText = class(TACLTextLayout)
  strict private
    FLabel: TACLCustomLabel;
  protected
    function GetDefaultHyperLinkColor: TColor; override;
    function GetDefaultTextColor: TColor; override;
  public
    constructor Create(ALabel: TACLCustomLabel);
  end;

{ TACLLabelFormattedText }

constructor TACLLabelFormattedText.Create(ALabel: TACLCustomLabel);
begin
  FLabel := ALabel;
  inherited Create(ALabel.Font);
end;

function TACLLabelFormattedText.GetDefaultHyperLinkColor: TColor;
begin
  Result := FLabel.Style.ColorTextHyperlink.AsColor;
end;

function TACLLabelFormattedText.GetDefaultTextColor: TColor;
begin
  Result := FLabel.GetDefaultTextColor;
end;

{ TACLFormattedLabel }

constructor TACLFormattedLabel.Create(AOwner: TComponent);
begin
  inherited;
  FText := TACLLabelFormattedText.Create(Self);
end;

destructor TACLFormattedLabel.Destroy;
begin
  FreeAndNil(FText);
  inherited;
end;

procedure TACLFormattedLabel.CMTextChanged(var Message: TMessage);
begin
  if FText <> nil then
    FText.SetText(Caption, TACLTextFormatSettings.Formatted);
  inherited;
end;

function TACLFormattedLabel.GetHyperlinkAt(const P: TPoint; out AUrl: string): Boolean;
var
  LHitTest: TACLTextLayoutHitTest;
begin
  LHitTest := TACLTextLayoutHitTest.Create(FText);
  try
    LHitTest.Calculate(P);
    Result := LHitTest.Hyperlink <> nil;
    if Result then
      AUrl := LHitTest.Hyperlink.Hyperlink;
  finally
    LHitTest.Free;
  end;
end;

function TACLFormattedLabel.MeasureSize(AWidth: Integer): TSize;
begin
  MeasureCanvas.SetScaledFont(Font);
  if FText.Text <> '' then
  begin
    FText.SetOption(atoEndEllipsis, EndEllipsis and not AutoSize);
    FText.SetOption(atoWordWrap, Style.WordWrap);
    FText.Bounds := Bounds(0, 0, IfThen(AWidth > 0, AWidth, MaxWord), MaxWord);
    FText.Calculate(MeasureCanvas);
    Result := FText.MeasureSize
  end
  else
    Result := TSize.Create(0, acFontHeight(MeasureCanvas));
end;

procedure TACLFormattedLabel.PaintText;
begin
  FText.Bounds := FTextRect;
  FText.Draw(Canvas, FTextRect);
end;

{$ENDREGION}

{$REGION ' Validation Label '}

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

procedure TACLValidationLabel.Calculate(ABounds: TRect);
begin
  inherited;
  Inc(FTextRect.Left, GetTextOffset);
end;

function TACLValidationLabel.CreateStyle: TACLStyleLabel;
begin
  Result := TACLStyleValidationLabel.Create(Self);
end;

function TACLValidationLabel.GetStyle: TACLStyleValidationLabel;
begin
  Result := TACLStyleValidationLabel(inherited Style);
end;

function TACLValidationLabel.GetTextOffset: Integer;
begin
  Result := Style.Icons.FrameWidth + dpiApply(acIndentBetweenElements, FCurrentPPI);
end;

function TACLValidationLabel.MeasureSize(AWidth: Integer = 0): TSize;
begin
  if AWidth > 0 then
    Dec(AWidth, GetTextOffset);
  Result := inherited MeasureSize(AWidth);
  Result.cx := Result.cx + GetTextOffset;
  Result.cy := Max(Result.cy, Style.Icons.FrameHeight);
end;

procedure TACLValidationLabel.Paint;
var
  LGlyphRect: TRect;
begin
  inherited;
  LGlyphRect := ClientRect;
  LGlyphRect.CenterVert(Style.Icons.FrameHeight);
  LGlyphRect.Width := Style.Icons.FrameWidth;
  Style.Icons.Draw(Canvas, LGlyphRect, Ord(Icon));
end;

procedure TACLValidationLabel.SetCaption(
  const AValue: string; AIcon: TACLValidationLabelIcon);
begin
  Caption := AValue;
  Icon := AIcon;
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

{$ENDREGION}
end.
