////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   DropDown
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.DropDown;

{$I ACL.Config.inc}

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
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type

  { TACLAbstractDropDownEdit }

  TACLAbstractDropDownEdit = class(TACLCustomTextEdit)
  strict private
    FDropDownAlignment: TAlignment;
    FDropDownButton: TACLButtonSubClass;
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
    procedure WMChar(var Message: TWMChar); message WM_CHAR;
  protected
    procedure HandlerImageChange(Sender: TObject); override;

    //# DropDown
    function CreateDropDownButton: TACLButtonSubClass; virtual;
    function CreateDropDownWindow: TACLPopupWindow; virtual;
    procedure DoDropDown; virtual;
    procedure HideDropDownWindow; virtual;
    procedure HideDropDownWindowPostponed;
    procedure ShowDropDownWindow; virtual;

    //# Properties
    property DropDownAlignment: TAlignment read FDropDownAlignment write FDropDownAlignment default taLeftJustify;
    property DropDownButton: TACLButtonSubClass read FDropDownButton;
    property DropDownButtonVisible: Boolean read FDropDownButtonVisible write SetDropDownButtonVisible;
    property DropDownWindow: TACLPopupWindow read FDropDownWindow;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Focused: Boolean; override;
    property DroppedDown: Boolean read GetDroppedDown write SetDroppedDown;
  published
    property OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;
  end;

  { TACLCustomDropDown }

  TACLCustomDropDown = class(TACLAbstractDropDownEdit, IACLGlyph)
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
    function CreateStyleButton: TACLStyleButton; override;
    procedure FocusChanged; override;
    function DialogChar(var Message: TWMKey): Boolean; override;
    procedure Paint; override;
    procedure UpdateTransparency; override;
    // IACLGlyph
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
    procedure HideDropDownWindow; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  published
    property Control: TControl read FControl write SetControl;
    property DropDownAlignment;
  end;

implementation

uses
{$IFNDEF FPC}
  ACL.Graphics.SkinImageSet, // inlining
{$ENDIF}
  ACL.UI.Insight.Core;

type

  { TACLDropDownUIInsightAdapter }

  TACLDropDownUIInsightAdapter = class(TACLUIInsightAdapterWinControl)
  public
    class procedure GetChildren(AObject: TObject;
      ABuilder: TACLUIInsightSearchQueueBuilder); override;
    class function MakeVisible(AObject: TObject): Boolean; override;
  end;

{ TACLAbstractDropDownEdit }

constructor TACLAbstractDropDownEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  RegisterSubClass(FDropDownButton, CreateDropDownButton);
  FDropDownButton.OnClick := HandlerButtonClick;
  FDropDownButtonVisible := True;
  FEditBox.Iteract := False;
end;

destructor TACLAbstractDropDownEdit.Destroy;
begin
  FreeAndNil(FDropDownWindow);
  TACLMainThread.Unsubscribe(Self);
  inherited Destroy;
end;

procedure TACLAbstractDropDownEdit.CMEnabledChanged(var Message: TMessage);
begin
  HideDropDownWindow;
  inherited;
end;

procedure TACLAbstractDropDownEdit.WMChar(var Message: TWMChar);
begin
  if not DroppedDown or (Message.CharCode <> VK_ESCAPE) then // Escape will be processed inside message loop
    inherited;
end;

function TACLAbstractDropDownEdit.CreateDropDownButton: TACLButtonSubClass;
begin
  Result := TACLButtonSubClass.Create(Self, StyleButton);
end;

function TACLAbstractDropDownEdit.CreateDropDownWindow: TACLPopupWindow;
begin
  Result := TACLPopupWindow.Create(Self);
end;

procedure TACLAbstractDropDownEdit.DoDropDown;
begin
  CallNotifyEvent(Self, OnDropDown);
end;

function TACLAbstractDropDownEdit.Focused: Boolean;
begin
  Result := inherited or (DropDownWindow <> nil) and
    acIsChildOrSelf(DropDownWindow, FindControl(GetFocus));
end;

procedure TACLAbstractDropDownEdit.HandlerButtonClick(Sender: TObject);
begin
  if DropDownButtonVisible then
    DroppedDown := True;
end;

procedure TACLAbstractDropDownEdit.HandlerDropDownClose(Sender: TObject);
begin
  FDropDownClosedAt := TACLThread.Timestamp;
  HideDropDownWindowPostponed;
end;

procedure TACLAbstractDropDownEdit.HandlerImageChange(Sender: TObject);
begin
  DropDownButton.ImageList := ButtonsImages;
  inherited;
end;

procedure TACLAbstractDropDownEdit.HideDropDownWindow;
begin
  FreeAndNil(FDropDownWindow);
  if not (csDestroying in ComponentState) then
  begin
    DropDownButton.IsDown := False;
    InvalidateBorders;
  end;
end;

procedure TACLAbstractDropDownEdit.HideDropDownWindowPostponed;
begin
  TACLMainThread.RunPostponed(HideDropDownWindow, Self);
end;

function TACLAbstractDropDownEdit.GetDroppedDown: Boolean;
begin
  Result := DropDownWindow <> nil;
end;

procedure TACLAbstractDropDownEdit.ShowDropDownWindow;
begin
  DropDownWindow.PopupUnderControl(ClientToScreen(ClientRect), DropDownAlignment);
end;

procedure TACLAbstractDropDownEdit.SetDropDownButtonVisible(AValue: Boolean);
begin
  if DropDownButtonVisible <> AValue then
  begin
    FDropDownButtonVisible := AValue;
    FullRefresh;
  end;
end;

procedure TACLAbstractDropDownEdit.SetDroppedDown(AValue: Boolean);
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
          DropDownButton.IsDown := True;
          ShowDropDownWindow;
        end;
      end;
    end
    else
      HideDropDownWindow;
  end;
end;

{ TACLCustomDropDown }

constructor TACLCustomDropDown.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDefaultSize := TSize.Create(DefaultButtonWidth, DefaultButtonHeight);
  FGlyph := TACLGlyph.Create(Self);
  Cursor := crHandPoint;
  DropDownButton.HasArrow := True;
  AutoSize := False;
end;

destructor TACLCustomDropDown.Destroy;
begin
  FreeAndNil(FGlyph);
  inherited;
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

procedure TACLCustomDropDown.Paint;
begin
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

procedure TACLDropDown.HideDropDownWindow;
begin
  if (Control <> nil) and ([csDestroying, csDesigning] * ComponentState = []) then
  begin
    Control.Align := alNone;
    Control.Parent := Self;
    Control.Hide;
  end;
  inherited;
end;

procedure TACLDropDown.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (Control = AComponent) then
    Control := nil;
  inherited Notification(AComponent, Operation);
end;

procedure TACLDropDown.SetControl(AValue: TControl);
begin
  if acIsChildOrSelf(Self, AValue) then
    raise EInvalidArgument.CreateFmt('The %s cannot be used as child', [AValue.Name]);
  acComponentFieldSet(FControl, Self, AValue);
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
