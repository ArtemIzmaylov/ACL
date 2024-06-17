////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   SearchBox
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.SearchBox;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
  LMessages,
{$ELSE}
  {Winapi.}Messages,
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Generics.Defaults,
  {System.}Math,
  {System.}SysUtils,
  {System.}TypInfo,
  System.UITypes,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Graphics,
  ACL.Timers,
  ACL.Threading,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Strings;

const
  acSearchDelay = 750;

type

  { TACLSearchEditStyleButton }

  TACLSearchEditStyleButton = class(TACLStyleEditButton)
  protected
    procedure InitializeTextures; override;
  end;

  { TACLSearchEdit }

  TACLSearchEdit = class(TACLCustomTextEdit)
  strict private
    FFocusControl: TWinControl;
    FWaitTimer: TACLTimer;

    function CanSelectFocusControl: Boolean;
    function GetChangeDelay: Integer;
    procedure SetChangeDelay(AValue: Integer);
    procedure SetFocusControl(const Value: TWinControl);
    // Handlers
    procedure CancelButtonHandler(Sender: TObject);
    procedure WaitTimerHandler(Sender: TObject);
  protected
    function CreateStyleButton: TACLStyleButton; override;
    procedure Changed; override;
    procedure DoChange; override;
    procedure DoMoveFocusToFirstSearchResult;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    //# Messages
    procedure CMWantSpecialKey(var Message: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CancelSearch;
  published
    property AutoSize;
    property Borders;
    property ChangeDelay: Integer read GetChangeDelay write SetChangeDelay default acSearchDelay;
    property FocusControl: TWinControl read FFocusControl write SetFocusControl;
    property MaxLength;
    property ResourceCollection;
    property Style;
    property StyleButton;
    property Text;
    property TextHint;
  end;

implementation

{ TACLSearchEdit }

constructor TACLSearchEdit.Create(AOwner: TComponent);
var
  AButton: TACLEditButton;
begin
  inherited Create(AOwner);
  FWaitTimer := TACLTimer.CreateEx(WaitTimerHandler, acSearchDelay);

  AButton := Buttons.Add;
  AButton.OnClick := CancelButtonHandler;
  AButton.Visible := False;
end;

destructor TACLSearchEdit.Destroy;
begin
  FreeAndNil(FWaitTimer);
  inherited Destroy;
end;

procedure TACLSearchEdit.CancelSearch;
begin
  if Text <> '' then
  begin
    Text := '';
    DoChange;
  end;
end;

procedure TACLSearchEdit.Changed;
begin
  Buttons[0].Visible := Text <> '';
  if not (csLoading in ComponentState) then
    FWaitTimer.Restart;
  Invalidate;
end;

function TACLSearchEdit.CreateStyleButton: TACLStyleButton;
begin
  Result := TACLSearchEditStyleButton.Create(Self);
end;

procedure TACLSearchEdit.DoChange;
begin
  FWaitTimer.Enabled := False;
  inherited DoChange;
end;

procedure TACLSearchEdit.DoMoveFocusToFirstSearchResult;
var
  AIntf: IACLFocusableControl2;
begin
  if CanSelectFocusControl then
  begin
    if Supports(FocusControl, IACLFocusableControl2, AIntf) then
      AIntf.SetFocusOnSearchResult
    else
      FocusControl.SetFocus;
  end;
end;

procedure TACLSearchEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_DOWN:
      DoMoveFocusToFirstSearchResult;

    VK_RETURN:
      begin
        if FWaitTimer.Enabled then
          DoChange
        else
          if CanSelectFocusControl then
            DoMoveFocusToFirstSearchResult
          else
            inherited KeyDown(Key, Shift);

        Key := 0;
      end;

    VK_ESCAPE:
      begin
        if Text <> '' then
          CancelSearch
        else
          if CanSelectFocusControl then
            FocusControl.SetFocus
          else
            inherited;

        Key := 0;
      end;
  end;

  if Key <> 0 then
    inherited KeyDown(Key, Shift);
end;

procedure TACLSearchEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FocusControl) then
    FocusControl := nil;
end;

procedure TACLSearchEdit.CMWantSpecialKey(var Message: TCMWantSpecialKey);
begin
  if Message.CharCode = VK_ESCAPE then
  begin
    if (Text <> '') or CanSelectFocusControl then
      Message.Result := 1;
  end;
  if Message.Result = 0 then
    inherited;
end;

function TACLSearchEdit.CanSelectFocusControl: Boolean;
begin
  Result := Focused and (FocusControl <> nil) and FocusControl.CanFocus;
end;

function TACLSearchEdit.GetChangeDelay: Integer;
begin
  Result := FWaitTimer.Interval;
end;

procedure TACLSearchEdit.SetChangeDelay(AValue: Integer);
begin
  FWaitTimer.Interval := EnsureRange(AValue, 0, 5000);
end;

procedure TACLSearchEdit.SetFocusControl(const Value: TWinControl);
begin
  acComponentFieldSet(FFocusControl, Self, Value);
end;

procedure TACLSearchEdit.CancelButtonHandler(Sender: TObject);
begin
  CancelSearch;
end;

procedure TACLSearchEdit.WaitTimerHandler(Sender: TObject);
begin
  DoChange;
end;

{ TACLSearchEditStyleButton }

procedure TACLSearchEditStyleButton.InitializeTextures;
begin
  Texture.InitailizeDefaults('EditBox.Textures.Cancel');
end;

end.
