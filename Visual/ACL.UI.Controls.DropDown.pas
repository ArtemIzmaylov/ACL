{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Editors Controls              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.DropDown;

{$I ACL.Config.inc}

interface

uses
  Windows, Classes, Controls, Graphics, Types, ImgList, UITypes, Messages,
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
    FButtonViewInfo: TACLCustomDropDownEditButtonViewInfo;
    FDropDownAlignment: TAlignment;
    FDropDownJustClosed: Boolean;

    FOnDropDown: TNotifyEvent;

    procedure HandlerButtonClick(Sender: TObject);
    procedure HandlerDropDownClose(Sender: TObject);
  protected
    FDropDown: TACLCustomPopupForm;

    function CanDropDown(X, Y: Integer): Boolean; virtual;
    function CanOpenEditor: Boolean; override;
    function CreateButtonViewInfo: TACLCustomDropDownEditButtonViewInfo; virtual;
    procedure DoDropDown; virtual;
    function GetCursor(const P: TPoint): TCursor; override;
    procedure CalculateButtons(var R: TRect); override;
    procedure DrawContent(ACanvas: TCanvas); override;
    procedure SetDefaultSize; override;
    // Dropdown
    procedure CreateDropDownWindow; virtual;
    procedure FreeDropDownWindow; virtual;
    function GetDropDownFormClass: TACLCustomPopupFormClass; virtual;
    procedure ShowDropDownWindow; virtual;
    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    // Messages
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure WndProc(var Message: TMessage); override;
    // Properties
    property DropDownAlignment: TAlignment read FDropDownAlignment write FDropDownAlignment default taLeftJustify;
    property ButtonViewInfo: TACLCustomDropDownEditButtonViewInfo read FButtonViewInfo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CloseDropDown;
    function DropDown: Boolean; virtual;
    function Focused: Boolean; override;
  published
    property DoubleBuffered default True;
    //
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
    function CreateButtonViewInfo: TACLCustomDropDownEditButtonViewInfo; override;
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
    procedure CreateDropDownWindow; override;
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
  SysUtils, Math,
  // ACL
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
  FButtonViewInfo := CreateButtonViewInfo;
  FButtonViewInfo.OnClick := HandlerButtonClick;
  DoubleBuffered := True;
end;

destructor TACLCustomDropDownEdit.Destroy;
begin
  FreeDropDownWindow;
  TACLMainThread.Unsubscribe(Self);
  FreeAndNil(FButtonViewInfo);
  inherited Destroy;
end;

procedure TACLCustomDropDownEdit.CalculateButtons(var R: TRect);
var
  ARect: TRect;
begin
  inherited CalculateButtons(R);
  ARect := acRectInflate(R, -ScaleFactor.Apply(ButtonsIndent));
  ButtonViewInfo.IsEnabled := Enabled;
  ButtonViewInfo.IsDown := FDropDown <> nil;
  ButtonViewInfo.Calculate(acRectSetLeft(ARect, ARect.Height));
  R.Right := ButtonViewInfo.Bounds.Left;
end;

function TACLCustomDropDownEdit.CanDropDown(X, Y: Integer): Boolean;
begin
  Result := PtInRect(TextRect, Point(X, Y));
end;

function TACLCustomDropDownEdit.CanOpenEditor: Boolean;
begin
  Result := False;
end;

function TACLCustomDropDownEdit.CreateButtonViewInfo: TACLCustomDropDownEditButtonViewInfo;
begin
  Result := TACLCustomDropDownEditButtonViewInfo.Create(Self);
end;

procedure TACLCustomDropDownEdit.DoDropDown;
begin
  CallNotifyEvent(Self, OnDropDown);
end;

procedure TACLCustomDropDownEdit.HandlerDropDownClose(Sender: TObject);
begin
  TACLMainThread.RunPostponed(FreeDropDownWindow, Self);
end;

function TACLCustomDropDownEdit.Focused: Boolean;
begin
  Result := inherited or (FDropDown <> nil) and IsChild(FDropDown.Handle, GetFocus);
end;

function TACLCustomDropDownEdit.GetCursor(const P: TPoint): TCursor;
begin
  if PtInRect(ButtonViewInfo.Bounds, P) then
    Result := crHandPoint
  else
    Result := inherited GetCursor(P);
end;

procedure TACLCustomDropDownEdit.DrawContent(ACanvas: TCanvas);
begin
  ACanvas.Font := Font;
  ACanvas.Font.Color := Style.ColorsText[Enabled];
  FButtonViewInfo.Draw(ACanvas);
end;

procedure TACLCustomDropDownEdit.CloseDropDown;
begin
  FreeDropDownWindow;
end;

function TACLCustomDropDownEdit.DropDown: Boolean;
begin
  Result := False;
  if (FDropDown = nil) and Enabled then
  begin
    DoDropDown;
    if Enabled then
    begin
      Result := True;
      CreateDropDownWindow;
      if FDropDown <> nil then
      begin
        ShowDropDownWindow;
        Recalculate;
      end;
    end;
  end;
end;

procedure TACLCustomDropDownEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if not FDropDownJustClosed then
  begin
    ButtonViewInfo.MouseDown(Button, Point(X, Y));
    if (Button = mbLeft) and CanDropDown(X, Y) and DropDown then
      Exit;
  end;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TACLCustomDropDownEdit.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ButtonViewInfo.MouseUp(Button, Point(X, Y));
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TACLCustomDropDownEdit.SetDefaultSize;
begin
  if not Inplace then
    SetBounds(Left, Top, 121, 21);
end;

procedure TACLCustomDropDownEdit.CreateDropDownWindow;
begin
  FDropDown := GetDropDownFormClass.Create(Self);
  acAssignFont(FDropDown.Font, Font, FDropDown.ScaleFactor, ScaleFactor);
  FDropDown.OnClosePopup := HandlerDropDownClose;
end;

procedure TACLCustomDropDownEdit.FreeDropDownWindow;
begin
  if FDropDown <> nil then
  begin
    FreeAndNil(FDropDown);
    Recalculate;
  end;
end;

function TACLCustomDropDownEdit.GetDropDownFormClass: TACLCustomPopupFormClass;
begin
  Result := TACLCustomPopupForm;
end;

procedure TACLCustomDropDownEdit.ShowDropDownWindow;
begin
  FDropDown.PopupUnderControl(Self, DropDownAlignment);
end;

procedure TACLCustomDropDownEdit.MouseLeave;
begin
  inherited MouseLeave;
  ButtonViewInfo.MouseMove(InvalidPoint);
end;

procedure TACLCustomDropDownEdit.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  ButtonViewInfo.MouseMove(Point(X, Y));
end;

procedure TACLCustomDropDownEdit.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  FreeDropDownWindow;
  Recalculate;
end;

procedure TACLCustomDropDownEdit.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_MOUSEACTIVATE:
      FDropDownJustClosed := Assigned(FDropDown);
    WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN:
      if not Focused then
        Windows.SetFocus(Handle);
  end;

  inherited WndProc(Message);

  case Message.Msg of
    WM_MOUSEFIRST..WM_MOUSELAST:
      FDropDownJustClosed := False;
  end;
end;

procedure TACLCustomDropDownEdit.HandlerButtonClick(Sender: TObject);
begin
  DropDown;
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

function TACLCustomDropDown.CreateButtonViewInfo: TACLCustomDropDownEditButtonViewInfo;
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
  ButtonViewInfo.IsEnabled := Enabled;
  ButtonViewInfo.IsDown := FDropDown <> nil;
  ButtonViewInfo.Calculate(R);
end;

function TACLCustomDropDown.CreateStyleButton: TACLStyleButton;
begin
  Result := TACLStyleButton.Create(Self);
end;

procedure TACLCustomDropDown.FocusChanged;
begin
  inherited FocusChanged;
  ButtonViewInfo.IsFocused := Focused;
end;

procedure TACLCustomDropDown.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  ButtonViewInfo.KeyDown(Key, Shift);
end;

procedure TACLCustomDropDown.KeyUp(var Key: Word; Shift: TShiftState);
begin
  ButtonViewInfo.KeyUp(Key, Shift);
  inherited KeyUp(Key, Shift);
end;

function TACLCustomDropDown.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if ButtonViewInfo.Transparent then
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
  ButtonViewInfo.Draw(Canvas);
end;

function TACLCustomDropDown.GetCaption: UnicodeString;
begin
  if ButtonViewInfo <> nil then
    Result := ButtonViewInfo.Caption
  else
    Result := EmptyStr;
end;

function TACLCustomDropDown.GetImageIndex: TImageIndex;
begin
  Result := ButtonViewInfo.ImageIndex;
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
  ButtonViewInfo.Caption := AValue;
end;

procedure TACLCustomDropDown.SetGlyph(const Value: TACLGlyph);
begin
  FGlyph.Assign(Value);
end;

procedure TACLCustomDropDown.SetImageIndex(AIndex: TImageIndex);
begin
  ButtonViewInfo.ImageIndex := AIndex;
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
  if ButtonViewInfo.DialogChar(Message.CharCode) then
    Message.Result := 1
  else
    inherited;
end;

{ TACLDropDown }

procedure TACLDropDown.CreateDropDownWindow;
begin
  if IsDesigning or (Control = nil) then Exit;

  inherited CreateDropDownWindow;

  if Assigned(FControl) then
  begin
    FDropDown.AutoSize := True;
    FControl.Parent := FDropDown;
    FControl.Show;
  end;
end;

procedure TACLDropDown.FreeDropDownWindow;
begin
  if Assigned(FControl) and not (IsDestroying or IsDesigning) then
  begin
    FControl.Align := alNone;
    FControl.Parent := Self;
    FControl.Hide;
  end;
  inherited FreeDropDownWindow;
end;

procedure TACLDropDown.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (Control = AComponent) then
    Control := nil;
end;

procedure TACLDropDown.SetControl(AValue: TControl);
begin
  if TACLControlsHelper.IsChildOrSelf(Self, AValue) then
    raise EInvalidArgument.CreateFmt('The %s cannot be used as child', [AValue.Name]);

  if FControl <> AValue then
  begin
    if FControl <> nil then
    begin
      FControl.RemoveFreeNotification(Self);
      FControl := nil;
    end;
    if AValue <> nil then
    begin
      FControl := AValue;
      FControl.FreeNotification(Self);
    end;
  end;
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

class procedure TACLDropDownUIInsightAdapter.GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
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
