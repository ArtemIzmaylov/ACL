{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Editors Controls              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.DropDown;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // VCL
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.ImgList,
  // System
  System.Classes,
  System.Math,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.MUI,
  ACL.Threading,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type
  TACLCustomDropDownEditButtonViewInfo = class;

  { TACLCustomDropDownEdit }

  TACLCustomDropDownEdit = class(TACLCustomTextEdit)
  strict private
    FDropDownAlignment: TAlignment;
    FDropDownClosedAt: Cardinal;
    FDropDownButton: TACLCustomDropDownEditButtonViewInfo;
    FDropDownWindow: TACLPopupWindow;

    FOnDropDown: TNotifyEvent;

    procedure HandlerButtonClick(Sender: TObject);
    procedure HandlerDropDownClose(Sender: TObject);
    //# Properties
    function GetDroppedDown: Boolean;
    procedure SetDroppedDown(AValue: Boolean);
    //# Messages
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    function CanDropDown(X, Y: Integer): Boolean; virtual;
    function CanOpenEditor: Boolean; override;
    procedure CalculateButtons(var R: TRect); override;
    procedure DrawContent(ACanvas: TCanvas); override;
    function GetCursor(const P: TPoint): TCursor; override;
    procedure SetDefaultSize; override;

    //# DropDown
    function CreateDropDownButton: TACLCustomDropDownEditButtonViewInfo; virtual;
    function CreateDropDownWindow: TACLPopupWindow; virtual;
    procedure FreeDropDownWindow; virtual;
    procedure ShowDropDownWindow; virtual;
    procedure DoDropDown; virtual;

    //# Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    //# Properties
    property DropDownAlignment: TAlignment read FDropDownAlignment write FDropDownAlignment default taLeftJustify;
    property DropDownButton: TACLCustomDropDownEditButtonViewInfo read FDropDownButton;
    property DropDownWindow: TACLPopupWindow read FDropDownWindow;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Focused: Boolean; override;
    property DroppedDown: Boolean read GetDroppedDown write SetDroppedDown;
  published
    property DoubleBuffered default True;
    // Events
    property OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;
  end;

  { TACLCustomDropDownEditButtonViewInfo }

  TACLCustomDropDownEditButtonViewInfo = class(TACLButtonViewInfo)
  protected
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); override;
  end;

  { TACLCustomDropDown }

  TACLCustomDropDown = class(TACLCustomDropDownEdit, IACLGlyph)
  strict private
    FGlyph: TACLGlyph;

    function GetCaption: UnicodeString;
    function GetImageIndex: TImageIndex;
    function GetImages: TCustomImageList;
    function GetStyle: TACLStyleButton;
    function IsGlyphStored: Boolean;
    procedure SetCaption(const AValue: UnicodeString);
    procedure SetGlyph(const Value: TACLGlyph);
    procedure SetImageIndex(AIndex: TImageIndex);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetStyle(const Value: TACLStyleButton);
    // Messages
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
  protected
    procedure Calculate(R: TRect); override;
    procedure FocusChanged; override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    procedure SetDefaultSize; override;
    // keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    // drawing
    procedure Paint; override;
    // button
    function CreateDropDownButton: TACLCustomDropDownEditButtonViewInfo; override;
    function CreateStyleButton: TACLStyleButton; override;
    function GetGlyph: TACLGlyph;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Caption: UnicodeString read GetCaption write SetCaption;
    property Cursor default crHandPoint;
    property FocusOnClick default True;
    property Glyph: TACLGlyph read FGlyph write SetGlyph stored IsGlyphStored;
    property ImageIndex: TImageIndex read GetImageIndex write SetImageIndex default -1;
    property Images: TCustomImageList read GetImages write SetImages;
    property ResourceCollection;
    property Style: TACLStyleButton read GetStyle write SetStyle;
  end;

  { TACLDropDown }

  TACLDropDown = class(TACLCustomDropDown)
  strict private
    FControl: TControl;

    procedure SetControl(AValue: TControl);
  protected
    function CreateDropDownWindow: TACLPopupWindow; override;
    procedure FreeDropDownWindow; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  published
    property Control: TControl read FControl write SetControl;
    property DropDownAlignment;
  end;

  { TACLDropDownButtonViewInfo }

  TACLDropDownButtonViewInfo = class(TACLCustomDropDownEditButtonViewInfo)
  protected
    function CanClickOnDialogChar(Char: Word): Boolean; override;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); override;
  end;

implementation

uses
  ACL.UI.Insight;

type
  TControlAccess = class(TControl);

  { TACLDropDownUIInsightAdapter }

  TACLDropDownUIInsightAdapter = class(TACLUIInsightAdapterWinControl)
  public
    class procedure GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder); override;
    class function MakeVisible(AObject: TObject): Boolean; override;
  end;

{ TACLCustomDropDownEdit }

constructor TACLCustomDropDownEdit.Create(AOwner: TComponent);
begin
  FBorders := True;
  inherited Create(AOwner);
  FDropDownButton := CreateDropDownButton;
  FDropDownButton.OnClick := HandlerButtonClick;
  DoubleBuffered := True;
  FocusOnClick := True;
end;

destructor TACLCustomDropDownEdit.Destroy;
begin
  FreeDropDownWindow;
  TACLMainThread.Unsubscribe(Self);
  FreeAndNil(FDropDownButton);
  inherited Destroy;
end;

procedure TACLCustomDropDownEdit.CalculateButtons(var R: TRect);
var
  LRect: TRect;
begin
  inherited CalculateButtons(R);
  LRect := R;
  LRect.Inflate(-dpiApply(ButtonsIndent, FCurrentPPI));
  DropDownButton.IsEnabled := Enabled;
  DropDownButton.IsDown := DropDownWindow <> nil;
  DropDownButton.Calculate(LRect.Split(srRight, LRect.Height));
  R.Right := DropDownButton.Bounds.Left;
end;

function TACLCustomDropDownEdit.CanDropDown(X, Y: Integer): Boolean;
begin
  Result := PtInRect(TextRect, Point(X, Y));
end;

function TACLCustomDropDownEdit.CanOpenEditor: Boolean;
begin
  Result := False;
end;

function TACLCustomDropDownEdit.CreateDropDownButton: TACLCustomDropDownEditButtonViewInfo;
begin
  Result := TACLCustomDropDownEditButtonViewInfo.Create(Self);
end;

procedure TACLCustomDropDownEdit.DoDropDown;
begin
  CallNotifyEvent(Self, OnDropDown);
end;

procedure TACLCustomDropDownEdit.HandlerDropDownClose(Sender: TObject);
begin
  FDropDownClosedAt := GetTickCount;
  TACLMainThread.RunPostponed(FreeDropDownWindow, Self);
end;

function TACLCustomDropDownEdit.Focused: Boolean;
begin
  Result := inherited or (DropDownWindow <> nil) and IsChild(DropDownWindow.Handle, GetFocus);
end;

function TACLCustomDropDownEdit.GetCursor(const P: TPoint): TCursor;
begin
  if PtInRect(DropDownButton.Bounds, P) then
    Result := crHandPoint
  else
    Result := inherited GetCursor(P);
end;

function TACLCustomDropDownEdit.GetDroppedDown: Boolean;
begin
  Result := DropDownWindow <> nil;
end;

procedure TACLCustomDropDownEdit.DrawContent(ACanvas: TCanvas);
begin
  ACanvas.Font := Font;
  ACanvas.Font.Color := Style.ColorsText[Enabled];
  DropDownButton.Draw(ACanvas);
end;

procedure TACLCustomDropDownEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  DropDownButton.MouseDown(Button, Point(X, Y));
  if (Button = mbLeft) and CanDropDown(X, Y) then
  begin
    DroppedDown := True;
    if DroppedDown then
      Exit;
  end;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TACLCustomDropDownEdit.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  DropDownButton.MouseUp(Button, Point(X, Y));
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TACLCustomDropDownEdit.SetDefaultSize;
begin
  if not Inplace then
    SetBounds(Left, Top, 121, 21);
end;

procedure TACLCustomDropDownEdit.SetDroppedDown(AValue: Boolean);
begin
  if AValue <> DroppedDown then
  begin
    if AValue and (DropDownWindow = nil) and Enabled then
    begin
      DoDropDown;
      if Enabled and (GetTickCount - FDropDownClosedAt > 200) then
      begin
        FDropDownWindow := CreateDropDownWindow;
        if DropDownWindow <> nil then
        begin
          DropDownWindow.OnClosePopup := HandlerDropDownClose;
          ShowDropDownWindow;
          Recalculate;
        end;
      end;
    end
    else
      FreeDropDownWindow;
  end;
end;

function TACLCustomDropDownEdit.CreateDropDownWindow: TACLPopupWindow;
begin
  Result := TACLPopupWindow.Create(Self);
end;

procedure TACLCustomDropDownEdit.FreeDropDownWindow;
begin
  if DropDownWindow <> nil then
  begin
    FreeAndNil(FDropDownWindow);
    Recalculate;
  end;
end;

procedure TACLCustomDropDownEdit.ShowDropDownWindow;
begin
  DropDownWindow.PopupUnderControl(ClientToScreen(ClientRect), DropDownAlignment);
end;

procedure TACLCustomDropDownEdit.MouseLeave;
begin
  inherited MouseLeave;
  DropDownButton.MouseMove(InvalidPoint);
end;

procedure TACLCustomDropDownEdit.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  DropDownButton.MouseMove(Point(X, Y));
end;

procedure TACLCustomDropDownEdit.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  FreeDropDownWindow;
  Recalculate;
end;

procedure TACLCustomDropDownEdit.HandlerButtonClick(Sender: TObject);
begin
  DroppedDown := True;
end;

{ TACLCustomDropDownEditButtonViewInfo }

procedure TACLCustomDropDownEditButtonViewInfo.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Texture.Draw(ACanvas.Handle, R, 5 + Ord(State));
end;

{ TACLCustomDropDown }

constructor TACLCustomDropDown.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FGlyph := TACLGlyph.Create(Self);
  Cursor := crHandPoint;
  AutoHeight := False;
  FocusOnClick := True;
end;

destructor TACLCustomDropDown.Destroy;
begin
  FreeAndNil(FGlyph);
  inherited;
end;

function TACLCustomDropDown.CreateDropDownButton: TACLCustomDropDownEditButtonViewInfo;
begin
  Result := TACLDropDownButtonViewInfo.Create(Self);
  Result.HasArrow := True;
end;

function TACLCustomDropDown.GetGlyph: TACLGlyph;
begin
  if not FGlyph.Empty then
    Result := FGlyph
  else
    Result := nil;
end;

procedure TACLCustomDropDown.Calculate(R: TRect);
begin
  DropDownButton.IsEnabled := Enabled;
  DropDownButton.IsDown := DropDownWindow <> nil;
  DropDownButton.Calculate(R);
end;

function TACLCustomDropDown.CreateStyleButton: TACLStyleButton;
begin
  Result := TACLStyleButton.Create(Self);
end;

procedure TACLCustomDropDown.FocusChanged;
begin
  inherited FocusChanged;
  DropDownButton.IsFocused := Focused;
end;

procedure TACLCustomDropDown.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  DropDownButton.KeyDown(Key, Shift);
end;

procedure TACLCustomDropDown.KeyUp(var Key: Word; Shift: TShiftState);
begin
  DropDownButton.KeyUp(Key, Shift);
  inherited KeyUp(Key, Shift);
end;

function TACLCustomDropDown.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if DropDownButton.Transparent then
    Result := cbsTransparent
  else
    Result := cbsOpaque;
end;

procedure TACLCustomDropDown.SetDefaultSize;
begin
  SetBounds(Left, Top, DefaultButtonWidth, DefaultButtonHeight);
end;

procedure TACLCustomDropDown.Paint;
begin
  AssignTextDrawParams(Canvas);
  DropDownButton.Draw(Canvas);
end;

function TACLCustomDropDown.GetCaption: UnicodeString;
begin
  if DropDownButton <> nil then
    Result := DropDownButton.Caption
  else
    Result := EmptyStr;
end;

function TACLCustomDropDown.GetImageIndex: TImageIndex;
begin
  Result := DropDownButton.ImageIndex;
end;

function TACLCustomDropDown.GetImages: TCustomImageList;
begin
  Result := ButtonsImages;
end;

function TACLCustomDropDown.GetStyle: TACLStyleButton;
begin
  Result := StyleButton;
end;

function TACLCustomDropDown.IsGlyphStored: Boolean;
begin
  Result := not FGlyph.Empty;
end;

procedure TACLCustomDropDown.SetCaption(const AValue: UnicodeString);
begin
  DropDownButton.Caption := AValue;
end;

procedure TACLCustomDropDown.SetGlyph(const Value: TACLGlyph);
begin
  FGlyph.Assign(Value);
end;

procedure TACLCustomDropDown.SetImageIndex(AIndex: TImageIndex);
begin
  DropDownButton.ImageIndex := AIndex;
end;

procedure TACLCustomDropDown.SetImages(const Value: TCustomImageList);
begin
  ButtonsImages := Value;
end;

procedure TACLCustomDropDown.SetStyle(const Value: TACLStyleButton);
begin
  StyleButton := Value;
end;

procedure TACLCustomDropDown.CMDialogChar(var Message: TCMDialogChar);
begin
  if DropDownButton.DialogChar(Message.CharCode) then
    Message.Result := 1
  else
    inherited;
end;

{ TACLDropDown }

function TACLDropDown.CreateDropDownWindow: TACLPopupWindow;
begin
  if (csDesigning in ComponentState) or (Control = nil) then
    Exit(nil);

  Result := inherited CreateDropDownWindow;
  if Control <> nil then
  begin
    Result.AutoSize := True;
    Control.Parent := Result;
    Control.Show;
  end;
end;

procedure TACLDropDown.FreeDropDownWindow;
begin
  if (Control <> nil) and ([csDestroying, csDesigning] * ComponentState = []) then
  begin
    Control.Align := alNone;
    Control.Parent := Self;
    Control.Hide;
  end;
  inherited FreeDropDownWindow;
end;

procedure TACLDropDown.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (Control = AComponent) then
    Control := nil;
  inherited Notification(AComponent, Operation);
end;

procedure TACLDropDown.SetControl(AValue: TControl);
begin
  if acIsChild(Self, AValue) then
    raise EInvalidArgument.CreateFmt('The %s cannot be used as child', [AValue.Name]);
  acComponentFieldSet(FControl, Self, AValue);
end;

{ TACLDropDownButtonViewInfo }

function TACLDropDownButtonViewInfo.CanClickOnDialogChar(Char: Word): Boolean;
begin
  Result := inherited CanClickOnDialogChar(Char) or (Char = VK_RETURN) and IsFocused;
end;

procedure TACLDropDownButtonViewInfo.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Draw(ACanvas.Handle, R, State);
end;

{ TACLDropDownUIInsightAdapter }

class procedure TACLDropDownUIInsightAdapter.GetChildren(
  AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
begin
  ABuilder.AddChildren(TACLDropDown(AObject).Control);
end;

class function TACLDropDownUIInsightAdapter.MakeVisible(AObject: TObject): Boolean;
begin
  Result := False;
end;

initialization
  TACLUIInsight.Register(TACLDropDown, TACLDropDownUIInsightAdapter);
end.
