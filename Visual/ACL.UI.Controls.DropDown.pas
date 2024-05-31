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

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // VCL
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}Forms,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // ACL
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
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
  TACLCustomDropDownEditButtonSubClass = class;

  { TACLCustomDropDownEdit }

  TACLCustomDropDownEdit = class(TACLCustomTextEdit)
  strict private
    FDropDownAlignment: TAlignment;
    FDropDownButton: TACLCustomDropDownEditButtonSubClass;
    FDropDownButtonVisible: Boolean;
    FDropDownClosedAt: Cardinal;
    FDropDownWindow: TACLPopupWindow;

    FOnDropDown: TNotifyEvent;

    procedure HandlerButtonClick(Sender: TObject);
    procedure HandlerDropDownClose(Sender: TObject);
    //# Properties
    function GetDroppedDown: Boolean;
    procedure SetDropDownButtonVisible(AValue: Boolean);
    procedure SetDroppedDown(AValue: Boolean);
    //# Messages
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    function CanDropDown(X, Y: Integer): Boolean; virtual;
    function CanOpenEditor: Boolean; override;
    procedure CalculateButtons(var R: TRect); override;
    procedure DrawContent(ACanvas: TCanvas); override;
    function GetCursor(const P: TPoint): TCursor; override;

    //# DropDown
    function CreateDropDownButton: TACLCustomDropDownEditButtonSubClass; virtual;
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
    property DropDownButton: TACLCustomDropDownEditButtonSubClass read FDropDownButton;
    property DropDownButtonVisible: Boolean read FDropDownButtonVisible write SetDropDownButtonVisible;
    property DropDownWindow: TACLPopupWindow read FDropDownWindow;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Focused: Boolean; override;
    property DroppedDown: Boolean read GetDroppedDown write SetDroppedDown;
  published
    property DoubleBuffered default True;
    property FocusOnClick default True;
    // Events
    property OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;
  end;

  { TACLCustomDropDownEditButtonSubClass }

  TACLCustomDropDownEditButtonSubClass = class(TACLButtonSubClass)
  protected
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); override;
  end;

  { TACLCustomDropDown }

  TACLCustomDropDown = class(TACLCustomDropDownEdit, IACLGlyph)
  strict private
    FGlyph: TACLGlyph;

    function GetCaption: string;
    function GetImageIndex: TImageIndex;
    function GetImages: TCustomImageList;
    function GetStyle: TACLStyleButton;
    function IsGlyphStored: Boolean;
    procedure SetCaption(const AValue: string);
    procedure SetGlyph(const Value: TACLGlyph);
    procedure SetImageIndex(AIndex: TImageIndex);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetStyle(const Value: TACLStyleButton);
  protected
    procedure Calculate(R: TRect); override;
    procedure FocusChanged; override;
    // Accelerators
    function DialogChar(var Message: TWMKey): Boolean; override;
    // keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    // drawing
    procedure Paint; override;
    procedure UpdateTransparency; override;
    // button
    function CreateDropDownButton: TACLCustomDropDownEditButtonSubClass; override;
    function CreateStyleButton: TACLStyleButton; override;
    function GetGlyph: TACLGlyph;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Caption: string read GetCaption write SetCaption;
    property Cursor default crHandPoint;
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

  { TACLDropDownButtonSubClass }

  TACLDropDownButtonSubClass = class(TACLCustomDropDownEditButtonSubClass)
  protected
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); override;
  end;

implementation

uses
{$IFNDEF FPC}
  ACL.Graphics.SkinImageSet, // inlining
{$ENDIF}
  ACL.UI.Insight;

type

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
  FDefaultSize := TSize.Create(320, 240);
  FDropDownButtonVisible := True;
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
  DropDownButton.IsEnabled := Enabled and DropDownButtonVisible;
  DropDownButton.IsDown := DropDownWindow <> nil;
  if DropDownButtonVisible then
  begin
    DropDownButton.Calculate(LRect.Split(srRight, LRect.Height));
    R.Right := DropDownButton.Bounds.Left;
  end
  else
    DropDownButton.Calculate(NullRect);
end;

function TACLCustomDropDownEdit.CanDropDown(X, Y: Integer): Boolean;
begin
  Result := PtInRect(TextRect, Point(X, Y));
end;

function TACLCustomDropDownEdit.CanOpenEditor: Boolean;
begin
  Result := False;
end;

function TACLCustomDropDownEdit.CreateDropDownButton: TACLCustomDropDownEditButtonSubClass;
begin
  Result := TACLCustomDropDownEditButtonSubClass.Create(Self);
end;

procedure TACLCustomDropDownEdit.DoDropDown;
begin
  CallNotifyEvent(Self, OnDropDown);
end;

procedure TACLCustomDropDownEdit.HandlerDropDownClose(Sender: TObject);
begin
  FDropDownClosedAt := TACLThread.Timestamp;
  TACLMainThread.RunPostponed(FreeDropDownWindow, Self);
end;

function TACLCustomDropDownEdit.Focused: Boolean;
begin
  Result := inherited or (DropDownWindow <> nil) and
    acIsChild(DropDownWindow, FindControl(GetFocus));
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

procedure TACLCustomDropDownEdit.SetDropDownButtonVisible(AValue: Boolean);
begin
  if DropDownButtonVisible <> AValue then
  begin
    FDropDownButtonVisible := AValue;
    FullRefresh;
  end;
end;

procedure TACLCustomDropDownEdit.SetDroppedDown(AValue: Boolean);
begin
  if AValue <> DroppedDown then
  begin
    if AValue and (DropDownWindow = nil) and Enabled then
    begin
      DoDropDown;
      if Enabled and TACLThread.IsTimeout(FDropDownClosedAt, 200) then
      begin
        FDropDownWindow := CreateDropDownWindow;
        if DropDownWindow <> nil then
        begin
          DropDownWindow.OnClosePopup := HandlerDropDownClose;
          ShowDropDownWindow;
          BoundsChanged;
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
    BoundsChanged;
  end;
end;

procedure TACLCustomDropDownEdit.ShowDropDownWindow;
begin
  DropDownWindow.PopupUnderControl(ClientToScreen(ClientRect), DropDownAlignment);
end;

procedure TACLCustomDropDownEdit.MouseLeave;
begin
  inherited MouseLeave;
  DropDownButton.MouseMove([], InvalidPoint);
end;

procedure TACLCustomDropDownEdit.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  DropDownButton.MouseMove(Shift, Point(X, Y));
end;

procedure TACLCustomDropDownEdit.CMEnabledChanged(var Message: TMessage);
begin
  FreeDropDownWindow;
  inherited;
end;

procedure TACLCustomDropDownEdit.HandlerButtonClick(Sender: TObject);
begin
  DroppedDown := True;
end;

{ TACLCustomDropDownEditButtonSubClass }

procedure TACLCustomDropDownEditButtonSubClass.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Texture.Draw(ACanvas, R, 5 + Ord(State));
end;

{ TACLCustomDropDown }

constructor TACLCustomDropDown.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDefaultSize := TSize.Create(DefaultButtonHeight, DefaultButtonHeight);
  FGlyph := TACLGlyph.Create(Self);
  Cursor := crHandPoint;
  AutoSize := False;
end;

destructor TACLCustomDropDown.Destroy;
begin
  FreeAndNil(FGlyph);
  inherited;
end;

function TACLCustomDropDown.CreateDropDownButton: TACLCustomDropDownEditButtonSubClass;
begin
  Result := TACLDropDownButtonSubClass.Create(Self);
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

function TACLCustomDropDown.DialogChar(var Message: TWMKey): Boolean;
begin
  Result := (Message.CharCode = VK_RETURN) and Focused or
    (IsAccel(Message.CharCode, Caption) and CanFocus);
  if Result then
  begin
    SetFocusOnClick;
    DropDownButton.PerformClick;
  end
  else
    Result := inherited;
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

procedure TACLCustomDropDown.Paint;
begin
  AssignTextDrawParams(Canvas);
  DropDownButton.Draw(Canvas);
end;

function TACLCustomDropDown.GetCaption: string;
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

procedure TACLCustomDropDown.SetCaption(const AValue: string);
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

procedure TACLCustomDropDown.UpdateTransparency;
begin
  if DropDownButton.Transparent then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque];
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

{ TACLDropDownButtonSubClass }

procedure TACLDropDownButtonSubClass.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Draw(ACanvas, R, State);
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
