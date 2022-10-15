﻿{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             GroupBox Controls             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.GroupBox;

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
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

type
  TACLGroupBox = class;

  { TACLCustomGroupBox }

  TACLCustomGroupBox = class(TACLContainer, IACLButtonOwner)
  strict private
    FCaptionViewInfo: TACLCheckBoxViewInfo;
    FStyleCaption: TACLStyleCheckBox;

    function GetCaption: UnicodeString;
    function GetContentRect: TRect;
    procedure SetCaption(const S: UnicodeString);
    procedure SetStyleCaption(const Value: TACLStyleCheckBox);
    //
    procedure CheckBoxClickHandler(Sender: TObject);
    //
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    FCaptionArea: TRect;
    FCaptionContentRect: TRect;
    FFrameRect: TRect;

    procedure Calculate(const R: TRect); virtual;
    procedure CalculateCaptionRect(const R: TRect); virtual;
    procedure CalculateFrameRect(const R: TRect); virtual;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;

    procedure CreateHandle; override;
    function CreatePadding: TACLPadding; override;
    function CreateStyleCaption: TACLStyleCheckBox; virtual; abstract;

    procedure AdjustClientRect(var Rect: TRect); override;
    procedure BoundsChanged; override;
    procedure DoCheckBoxClick; virtual;
    procedure FocusChanged; override;
    function GetContentOffset: TRect; override;
    function GetCursor(const P: TPoint): TCursor; override;
    procedure ResourceChanged; override;
    procedure SetDefaultSize; override;
    procedure SetTargetDPI(AValue: Integer); override;

    // Drawing
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect);
    procedure DrawCaption(ACanvas: TCanvas; const R: TRect); virtual;
    procedure DrawContent(ACanvas: TCanvas; const R: TRect); virtual;
    procedure Paint; override;

    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;

    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    // IACLButtonOwner
    procedure IACLButtonOwner.ButtonOwnerRecalculate = FullRefresh;
    function ButtonOwnerGetFont: TFont;
    function ButtonOwnerGetImages: TCustomImageList;
    function ButtonOwnerGetScaleFactor: TACLScaleFactor;
    function ButtonOwnerGetStyle: TACLStyleButton;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //
    property CaptionViewInfo: TACLCheckBoxViewInfo read FCaptionViewInfo;
    property ContentRect: TRect read GetContentRect;
  published
    property Anchors;
    property AutoSize;
    property Borders;
    property Caption: UnicodeString read GetCaption write SetCaption;
    property DoubleBuffered default True;
    property Padding;
    property StyleCaption: TACLStyleCheckBox read FStyleCaption write SetStyleCaption;
    property Transparent;
  end;

  { TACLGroupBoxCheckBox }

  TACLGroupBoxCheckBoxAction = (cbaNone, cbaToggleChildrenEnableState, cbaToggleMinimizeState);

  TACLGroupBoxCheckBox = class(TPersistent)
  strict private
    FAction: TACLGroupBoxCheckBoxAction;
    FOwner: TACLGroupBox;

    function GetChecked: Boolean;
    function GetVisible: Boolean;
    procedure SetAction(const Value: TACLGroupBoxCheckBoxAction);
    procedure SetChecked(const Value: Boolean);
    procedure SetVisible(const Value: Boolean);
  public
    constructor Create(AOwner: TACLGroupBox);
    procedure Assign(Source: TPersistent); override;
    procedure Toggle;
  published
    property Action: TACLGroupBoxCheckBoxAction read FAction write SetAction default cbaNone;
    property Checked: Boolean read GetChecked write SetChecked default True;
    property Visible: Boolean read GetVisible write SetVisible default False;
  end;

  { TACLGroupBox }

  TACLGroupBox = class(TACLCustomGroupBox)
  strict private
    FCheckBox: TACLGroupBoxCheckBox;
    FDisabledChildren: TACLList;
    FMinimized: Boolean;
    FRestoredHeight: Integer;

    FOnCheckBoxStateChanged: TNotifyEvent;

    procedure SetCheckBox(AValue: TACLGroupBoxCheckBox);
    procedure SetMinimized(AValue: Boolean);
    // backward compatibility
    procedure ReadCheckBoxMode(Reader: TReader);
    procedure ReadCheckBoxState(Reader: TReader);
  private
    procedure DisableChildren;
    procedure EnableChildren;
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure ApplyCheckBoxState;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    function CreateStyleCaption: TACLStyleCheckBox; override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure DoCheckBoxClick; override;
    procedure DoCheckBoxStateChanged;
    function GetMinimizeStateHeight: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;

    property Minimized: Boolean read FMinimized write SetMinimized;
  published
    property CheckBox: TACLGroupBoxCheckBox read FCheckBox write SetCheckBox;
    property OnCheckBoxStateChanged: TNotifyEvent read FOnCheckBoxStateChanged write FOnCheckBoxStateChanged;
  end;

  { TACLGroupBoxCaptionStyle }

  TACLGroupBoxCaptionStyle = class(TACLStyleCheckBox)
  protected
    procedure InitializeResources; override;
  end;

implementation

uses
  ACL.UI.Insight;

type

  { TACLGroupBoxUIInsightAdapter }

  TACLGroupBoxUIInsightAdapter = class(TACLUIInsightAdapterWinControl)
  public
    class function MakeVisible(AObject: TObject): Boolean; override;
  end;

{ TACLCustomGroupBox }

constructor TACLCustomGroupBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  FStyleCaption := CreateStyleCaption;
  FCaptionViewInfo := TACLCheckBoxViewInfo.Create(Self);
  FCaptionViewInfo.Alignment := taLeftJustify;
  FCaptionViewInfo.CheckState := cbChecked;
  FCaptionViewInfo.ShowCheckMark := False;
  FCaptionViewInfo.OnClick := CheckBoxClickHandler;
  DoubleBuffered := True;
end;

destructor TACLCustomGroupBox.Destroy;
begin
  FreeAndNil(FCaptionViewInfo);
  FreeAndNil(FStyleCaption);
  inherited Destroy;
end;

procedure TACLCustomGroupBox.Calculate(const R: TRect);
begin
  TabStop := CaptionViewInfo.ShowCheckMark;
  FocusOnClick := CaptionViewInfo.ShowCheckMark;
  CalculateCaptionRect(R);
  CalculateFrameRect(R);
  CaptionViewInfo.IsEnabled := Enabled;
  CaptionViewInfo.Calculate(FCaptionContentRect);
end;

procedure TACLCustomGroupBox.CalculateCaptionRect(const R: TRect);
var
  AHeight: Integer;
  AIndent: Integer;
  AMargins: TRect;
  AWidth: Integer;
begin
  if CaptionViewInfo.Caption <> '' then
  begin
    AWidth := -1;
    AHeight := -1;
    CaptionViewInfo.CalculateAutoSize(AWidth, AHeight);

    AIndent := Trunc(ScaleFactor.ApplyF(TACLMargins.DefaultValue));
    AMargins := Padding.GetScaledMargins(ScaleFactor);
    acMarginAdd(AMargins, GetContentOffset);
    acMarginAdd(AMargins, AIndent, 0, AIndent, 0);

    FCaptionContentRect := R;
    Inc(FCaptionContentRect.Left, AMargins.Left);
    Dec(FCaptionContentRect.Right, AMargins.Right);
    FCaptionContentRect := acRectSetSize(FCaptionContentRect, Min(AWidth, FCaptionContentRect.Width), AHeight);

    FCaptionArea := acRectInflate(FCaptionContentRect, ScaleFactor.Apply(acTextIndent), 0)
  end
  else
  begin
    FCaptionArea := acRectSetHeight(R, 0);
    FCaptionContentRect := FCaptionArea;
  end;
end;

procedure TACLCustomGroupBox.CalculateFrameRect(const R: TRect);
begin
  FFrameRect := R;
  FFrameRect.Top := (FCaptionArea.Top + FCaptionArea.Bottom) div 2;
end;

function TACLCustomGroupBox.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  Result := inherited CanAutoSize(NewWidth, NewHeight);
  if not FCaptionArea.IsEmpty then
  begin
    NewHeight := Max(NewHeight, FCaptionArea.Height);
    NewWidth := Max(NewWidth, FCaptionArea.Width);
  end;
end;

procedure TACLCustomGroupBox.CreateHandle;
begin
  inherited CreateHandle;
  FullRefresh;
end;

function TACLCustomGroupBox.CreatePadding: TACLPadding;
begin
  Result := TACLPadding.Create(5);
end;

procedure TACLCustomGroupBox.AdjustClientRect(var Rect: TRect);
begin
  inherited;
  if not FCaptionArea.IsEmpty then
    Rect.Top := Max(Rect.Top, FCaptionArea.Bottom - 1);
end;

procedure TACLCustomGroupBox.BoundsChanged;
begin
  inherited;
  Calculate(ClientRect);
end;

procedure TACLCustomGroupBox.DoCheckBoxClick;
begin
  // do nothing
end;

procedure TACLCustomGroupBox.FocusChanged;
begin
  inherited FocusChanged;
  CaptionViewInfo.IsFocused := Focused;
  Invalidate;
end;

function TACLCustomGroupBox.GetContentOffset: TRect;
begin
  Result := acBorderOffsets;
  if not FCaptionArea.IsEmpty then
    Result.Top := FFrameRect.Top;
end;

function TACLCustomGroupBox.GetCursor(const P: TPoint): TCursor;
begin
  if CaptionViewInfo.ShowCheckMark and PtInRect(CaptionViewInfo.Bounds, P) then
    Result := crHandPoint
  else
    Result := inherited GetCursor(P);
end;

procedure TACLCustomGroupBox.ResourceChanged;
begin
  if not IsDestroying then
    FullRefresh;
  inherited;
end;

procedure TACLCustomGroupBox.SetDefaultSize;
begin
  SetBounds(Left, Top, 200, 150);
end;

procedure TACLCustomGroupBox.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  StyleCaption.TargetDPI := AValue;
end;

procedure TACLCustomGroupBox.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  if not Transparent then
    Style.DrawContent(ACanvas, R);
end;

procedure TACLCustomGroupBox.DrawCaption(ACanvas: TCanvas; const R: TRect);
begin
  CaptionViewInfo.Draw(ACanvas);
end;

procedure TACLCustomGroupBox.DrawContent(ACanvas: TCanvas; const R: TRect);
begin
  // do nothing
end;

procedure TACLCustomGroupBox.Paint;
var
  ASaveIndex: Integer;
begin
  Canvas.Font := Font;
  Canvas.Brush.Style := bsClear;
  ASaveIndex := acSaveDC(Canvas);
  try
    DrawBackground(Canvas, ClientRect);
    DrawCaption(Canvas, FCaptionArea);
    acExcludeFromClipRegion(Canvas.Handle, FCaptionArea);
    DrawContent(Canvas, ContentRect);
    Style.DrawBorder(Canvas, FFrameRect, Borders);
  finally
    acRestoreDC(Canvas, ASaveIndex);
  end;
end;

procedure TACLCustomGroupBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  CaptionViewInfo.KeyDown(Key, Shift);
end;

procedure TACLCustomGroupBox.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  CaptionViewInfo.KeyUp(Key, Shift);
end;

procedure TACLCustomGroupBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  CaptionViewInfo.MouseDown(Button, Point(X, Y));
end;

procedure TACLCustomGroupBox.MouseLeave;
begin
  inherited MouseLeave;
  CaptionViewInfo.MouseMove(InvalidPoint);
end;

procedure TACLCustomGroupBox.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  CaptionViewInfo.MouseMove(Point(X, Y));
end;

procedure TACLCustomGroupBox.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  CaptionViewInfo.MouseUp(mbLeft, Point(X, Y));
end;

function TACLCustomGroupBox.ButtonOwnerGetFont: TFont;
begin
  Result := Font;
end;

function TACLCustomGroupBox.ButtonOwnerGetImages: TCustomImageList;
begin
  Result := nil;
end;

function TACLCustomGroupBox.ButtonOwnerGetScaleFactor: TACLScaleFactor;
begin
  Result := ScaleFactor;
end;

function TACLCustomGroupBox.ButtonOwnerGetStyle: TACLStyleButton;
begin
  Result := StyleCaption;
end;

function TACLCustomGroupBox.GetCaption: UnicodeString;
begin
  Result := CaptionViewInfo.Caption;
end;

function TACLCustomGroupBox.GetContentRect: TRect;
begin
  Result := ClientRect;
  AdjustClientRect(Result);
end;

procedure TACLCustomGroupBox.SetCaption(const S: UnicodeString);
begin
  if Caption <> S then
  begin
    CaptionViewInfo.Caption := S;
    FullRefresh;
    Realign;
  end;
end;

procedure TACLCustomGroupBox.SetStyleCaption(const Value: TACLStyleCheckBox);
begin
  FStyleCaption.Assign(Value);
end;

procedure TACLCustomGroupBox.CheckBoxClickHandler(Sender: TObject);
begin
  DoCheckBoxClick;
end;

procedure TACLCustomGroupBox.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  FullRefresh;
end;

{ TACLGroupBoxCheckBox }

constructor TACLGroupBoxCheckBox.Create(AOwner: TACLGroupBox);
begin
  FOwner := AOwner;
end;

procedure TACLGroupBoxCheckBox.Assign(Source: TPersistent);
begin
  if Source is TACLGroupBoxCheckBox then
  begin
    Action := TACLGroupBoxCheckBox(Source).Action;
    Checked := TACLGroupBoxCheckBox(Source).Checked;
    Visible := TACLGroupBoxCheckBox(Source).Visible;
  end;
end;

procedure TACLGroupBoxCheckBox.Toggle;
begin
  Checked := not Checked;
end;

function TACLGroupBoxCheckBox.GetChecked: Boolean;
begin
  Result := FOwner.CaptionViewInfo.CheckState = cbChecked;
end;

function TACLGroupBoxCheckBox.GetVisible: Boolean;
begin
  Result := FOwner.CaptionViewInfo.ShowCheckMark;
end;

procedure TACLGroupBoxCheckBox.SetAction(const Value: TACLGroupBoxCheckBoxAction);
begin
  if Value <> FAction then
  begin
    FAction := Value;
    FOwner.EnableChildren;
    FOwner.Minimized := False;
    FOwner.ApplyCheckBoxState;
  end;
end;

procedure TACLGroupBoxCheckBox.SetChecked(const Value: Boolean);
begin
  if Checked <> Value then
  begin
    if Value then
      FOwner.CaptionViewInfo.CheckState := cbChecked
    else
      FOwner.CaptionViewInfo.CheckState := cbUnchecked;

    FOwner.ApplyCheckBoxState;
  end;
end;

procedure TACLGroupBoxCheckBox.SetVisible(const Value: Boolean);
begin
  if Visible <> Value then
  begin
    FOwner.CaptionViewInfo.ShowCheckMark := Value;
    FOwner.ApplyCheckBoxState;
  end;
end;

{ TACLGroupBox }

constructor TACLGroupBox.Create(AOwner: TComponent);
begin
  inherited;
  FCheckBox := TACLGroupBoxCheckBox.Create(Self);
end;

destructor TACLGroupBox.Destroy;
begin
  FreeAndNil(FDisabledChildren);
  FreeAndNil(FCheckBox);
  inherited Destroy;
end;

procedure TACLGroupBox.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if Minimized then
    AHeight := GetMinimizeStateHeight;
  inherited;
end;

procedure TACLGroupBox.AdjustClientRect(var Rect: TRect);
begin
  if Minimized then
  begin
    Rect.Top := GetMinimizeStateHeight;
    Rect.Bottom := MaxWord;
  end
  else
    inherited;
end;

procedure TACLGroupBox.ApplyCheckBoxState;
begin
  if IsDesigning or not CheckBox.Visible then
    Exit;
  if CheckBox.Action in [cbaToggleChildrenEnableState, cbaToggleMinimizeState] then
  begin
    if CheckBox.Checked then
      EnableChildren
    else
      DisableChildren;
  end;
  if CheckBox.Action = cbaToggleMinimizeState then
    Minimized := not CheckBox.Checked;
  DoCheckBoxStateChanged;
end;

function TACLGroupBox.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  Result := inherited;
  if Minimized then
    NewHeight := GetMinimizeStateHeight;
end;

function TACLGroupBox.CreateStyleCaption: TACLStyleCheckBox;
begin
  Result := TACLGroupBoxCaptionStyle.Create(Self);
end;

procedure TACLGroupBox.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('CheckBoxMode', ReadCheckBoxMode, nil, False);
  Filer.DefineProperty('CheckBoxState', ReadCheckBoxState, nil, False);
end;

procedure TACLGroupBox.DoCheckBoxClick;
begin
  CheckBox.Toggle;
end;

procedure TACLGroupBox.DoCheckBoxStateChanged;
begin
  CallNotifyEvent(Self, OnCheckBoxStateChanged);
end;

function TACLGroupBox.GetMinimizeStateHeight: Integer;
begin
  Result := FCaptionArea.Bottom + acBorderOffsets.Bottom;
end;

procedure TACLGroupBox.DisableChildren;
var
  AControl: TControl;
begin
  if FDisabledChildren = nil then
  begin
    FDisabledChildren := TACLList.Create;
    for var I := 0 to ControlCount - 1 do
    begin
      AControl := Controls[I];
      if AControl.Enabled then
      begin
        FDisabledChildren.Add(AControl);
        AControl.Enabled := False;
      end;
    end;
  end;
end;

procedure TACLGroupBox.EnableChildren;
var
  AControl: TControl;
  I: Integer;
begin
  if FDisabledChildren <> nil then
  try
    for I := 0 to ControlCount - 1 do
    begin
      AControl := Controls[I];
      if FDisabledChildren.Remove(AControl) >= 0 then
        AControl.Enabled := True;
    end;
  finally
    FreeAndNil(FDisabledChildren);
  end;
end;

procedure TACLGroupBox.SetCheckBox(AValue: TACLGroupBoxCheckBox);
begin
  FCheckBox.Assign(AValue);
end;

procedure TACLGroupBox.SetMinimized(AValue: Boolean);
begin
  if FMinimized <> AValue then
  begin
    FMinimized := AValue;
    if Minimized then
      FRestoredHeight := Height
    else
      Height := FRestoredHeight;
    AdjustSize;
  end;
end;

procedure TACLGroupBox.ReadCheckBoxMode(Reader: TReader);
var
  AIdent: string;
begin
  AIdent := Reader.ReadIdent;
  CheckBox.Visible := AIdent <> 'msgcbNone';
  if AIdent = 'msgcbToggleEnableState' then
    CheckBox.Action := cbaToggleChildrenEnableState
  else
    CheckBox.Action := cbaNone;
end;

procedure TACLGroupBox.ReadCheckBoxState(Reader: TReader);
begin
  CheckBox.Checked := Reader.ReadBoolean;
end;

{ TACLGroupBoxCaptionStyle }

procedure TACLGroupBoxCaptionStyle.InitializeResources;
begin
  ColorText.InitailizeDefaults('Groups.Colors.HeaderText');
  ColorTextHover.InitailizeDefaults('Groups.Colors.HeaderText');
  ColorTextPressed.InitailizeDefaults('Groups.Colors.HeaderText');
  ColorTextDisabled.InitailizeDefaults('Groups.Colors.HeaderText');
  InitializeTextures;
end;

{ TACLGroupBoxUIInsightAdapter }

class function TACLGroupBoxUIInsightAdapter.MakeVisible(AObject: TObject): Boolean;
begin
  Result := not TACLGroupBox(AObject).Minimized;
end;

initialization
  TACLUIInsight.Register(TACLGroupBox, TACLGroupBoxUIInsightAdapter);
end.
