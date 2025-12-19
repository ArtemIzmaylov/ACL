////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   SearchBox
//
//  Author:    Artem Izmaylov
//             © 2006-2025
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
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.TextEdit,
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

  TACLSearchEdit = class(TACLBasicComboBox)
  strict private
    FDelayTimer: TACLTimer;
    FFocusControl: TWinControl;

    function CanSelectFocusControl: Boolean;
    function GetChangeDelay: Integer;
    procedure SetChangeDelay(AValue: Integer);
    procedure SetFocusControl(const Value: TWinControl);
    // Handlers
    procedure HandlerCancel(Sender: TObject);
    procedure HandlerDelayTimer(Sender: TObject);
    //# Messages
    procedure CMWantSpecialKey(var Message: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
  protected
    function CreateStyleButton: TACLStyleButton; override;
    procedure DoPrepareDropDownList(AList: TACLBasicDropDownList); override;
    procedure DoSearch; virtual;
    function GetCount: Integer; override;
    function IsDropDownKey(Key: WideChar): Boolean; override;
    function IsDropDownKey(Key: Word; Shift: TShiftState): Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MoveFocusToFirstSearchResult;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure TextChanged; override;
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
// lookup is not yet implemented
//    property StyleDropDownList;
//    property StyleDropDownListScrollBox;
    property Text;
    property TextHint;
//    //# Events
//    property OnPrepareDropDownList;
  end;

implementation

{ TACLSearchEdit }

constructor TACLSearchEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDelayTimer := TACLTimer.CreateEx(HandlerDelayTimer, acSearchDelay);
  DropDownButton.Part := abpButton;
  DropDownButton.OnClick := HandlerCancel;
  DropDownButtonVisible := False;
  EditBox.Iteract := True;
end;

destructor TACLSearchEdit.Destroy;
begin
  FreeAndNil(FDelayTimer);
  inherited Destroy;
end;

procedure TACLSearchEdit.CancelSearch;
begin
  if Text <> '' then
  begin
    Text := '';
    HandlerDelayTimer(nil);
  end;
end;

function TACLSearchEdit.CanSelectFocusControl: Boolean;
begin
  Result := Focused and (FocusControl <> nil) and FocusControl.CanFocus;
end;

procedure TACLSearchEdit.CMWantSpecialKey(var Message: TCMWantSpecialKey);
begin
  if Message.CharCode = vkEscape then
  begin
    if (Text <> '') or CanSelectFocusControl then
      Message.Result := 1;
  end;
  if Message.Result = 0 then
    inherited;
end;

function TACLSearchEdit.CreateStyleButton: TACLStyleButton;
begin
  Result := TACLSearchEditStyleButton.Create(Self);
end;

procedure TACLSearchEdit.DoPrepareDropDownList(AList: TACLBasicDropDownList);
begin
  AList.IncSearch.Mode := ismFilter;
  inherited;
end;

procedure TACLSearchEdit.DoSearch;
begin
  inherited TextChanged;
end;

function TACLSearchEdit.IsDropDownKey(Key: WideChar): Boolean;
begin
  Result := Ord(Key) in [{vkUp, vkDown, }vkEscape, vkReturn];
end;

function TACLSearchEdit.IsDropDownKey(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := Key in [vkUp, vkDown, vkEscape, vkReturn];
end;

procedure TACLSearchEdit.KeyDown(var Key: Word; Shift: TShiftState);
var
  LDropDownList: TACLBasicDropDownList;
begin
  if GetDropDownList(LDropDownList) and IsDropDownKey(Key, Shift) then
  begin
    LDropDownList.KeyDown(Key, Shift);
    Exit;
  end;

  case Key of
    vkDown:
      MoveFocusToFirstSearchResult;

    vkReturn:
      if FDelayTimer.Enabled then
        HandlerDelayTimer(nil)
      else if CanSelectFocusControl then
        MoveFocusToFirstSearchResult
      else
        inherited;

    vkEscape:
      if Text <> '' then
        CancelSearch
      else if CanSelectFocusControl then
        FocusControl.SetFocus
      else
        inherited;

  else
    inherited;
    Exit;
  end;
  Key := 0;
end;

procedure TACLSearchEdit.MoveFocusToFirstSearchResult;
var
  LIntf: IACLFocusableControl2;
begin
  if CanSelectFocusControl then
  begin
    if Supports(FocusControl, IACLFocusableControl2, LIntf) then
      LIntf.SetFocusOnSearchResult
    else
      FocusControl.SetFocus;
  end;
end;

procedure TACLSearchEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FocusControl) then
    FocusControl := nil;
end;

function TACLSearchEdit.GetChangeDelay: Integer;
begin
  Result := FDelayTimer.Interval;
end;

function TACLSearchEdit.GetCount: Integer;
begin
  Result := 0;
end;

procedure TACLSearchEdit.HandlerCancel(Sender: TObject);
begin
  CancelSearch;
end;

procedure TACLSearchEdit.HandlerDelayTimer(Sender: TObject);
begin
  FDelayTimer.Enabled := False;
  DoSearch;
end;

procedure TACLSearchEdit.SetChangeDelay(AValue: Integer);
begin
  FDelayTimer.Interval := EnsureRange(AValue, 0, 5000);
end;

procedure TACLSearchEdit.SetFocusControl(const Value: TWinControl);
begin
  acComponentFieldSet(FFocusControl, Self, Value);
end;

procedure TACLSearchEdit.TextChanged;
begin
  DropDownButtonVisible := Text <> '';
  if not (csLoading in ComponentState) then
    FDelayTimer.Restart;
end;

{ TACLSearchEditStyleButton }

procedure TACLSearchEditStyleButton.InitializeTextures;
begin
  Texture.InitailizeDefaults('EditBox.Textures.Cancel');
end;

end.
