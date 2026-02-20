////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Tray Icon
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.TrayIcon;

{$I ACL.Config.inc}

interface

uses
{$IFNDEF MSWINDOWS}
  LCLIntf,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}Menus,
  // ACL
  ACL.Classes,
  ACL.Graphics,
  ACL.ObjectLinks,
  ACL.Threading,
  ACL.Timers,
  ACL.UI.Controls.Base,
  ACL.UI.HintWindow,
  ACL.Utils.Common,
  ACL.Utils.Logger,
  ACL.Utils.Desktop,
  ACL.Utils.DPIAware,
  ACL.Utils.Messaging,
  ACL.Utils.Shell,
  ACL.Utils.Strings;

type
  TACLTrayBalloonIcon = (tbiNone, tbiInfo, tbiWarning, tbiError);

  TACLTrayIcon = class;
  TACLTrayIconCapability = (ticClick, ticMove, ticWheel);
  TACLTrayIconCapabilities = set of TACLTrayIconCapability;
  TACLTrayIconMouseWheelEvent = procedure (Sender: TObject; Down: Boolean) of object;

  { TACLTrayIconIntf }

  TACLTrayIconIntf = class
  public
    Owner: TACLTrayIcon;
    constructor Create(AIcon: TACLTrayIcon);
    function ActualIcon: TIcon;
    procedure BalloonHint(const ATitle, AText: string; AIcon: TACLTrayBalloonIcon); virtual; abstract;
    procedure ShowMenu; virtual;
    procedure Update; virtual; abstract;
  end;

  { TACLTrayIcon }

  TACLTrayIcon = class(TACLComponent,
    IACLCurrentDpi,
    IACLMouseTracking)
  public const
    BalloonTimeout = 3000;
  strict private
    FClickTimer: TACLTimer;
    FEnabled: Boolean;
    FHint: string;
    FIcon: TIcon;
    FIconImpl: TACLTrayIconIntf;
    FIconVisible: Boolean;
    FID: string;
    FLastMousePos: TPoint;
    FMousePressed: set of TMouseButton;
    FPopupMenu: TPopupMenu;
    FWantDoubleClicks: Boolean;

    FOnBallonHintClick: TNotifyEvent;
    FOnClick: TNotifyEvent;
    FOnDblClick: TNotifyEvent;
    FOnMidClick: TNotifyEvent;
    FOnMouseEnter: TNotifyEvent;
    FOnMouseExit: TNotifyEvent;
    FOnMouseWheel: TACLTrayIconMouseWheelEvent;

    procedure HandlerClickTimer(Sender: TObject);
    procedure SetEnabled(AValue: Boolean);
    procedure SetHint(const AValue: string);
    procedure SetIcon(AValue: TIcon);
    procedure SetIconVisible(AValue: Boolean);
    procedure SetID(const AValue: string);
    procedure SetPopupMenu(AValue: TPopupMenu);
    procedure SetVisible(AValue: Boolean);
    // IACLCurrentDpi
    function GetCurrentDpi: Integer;
    // IACLMouseTracking
    function IsMouseAtControl: Boolean;
    procedure MouseEnter;
    procedure MouseLeave;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    // Events
    procedure DoClick; dynamic;
    procedure DoDblClick; dynamic;
    procedure DoMidClick; dynamic;
    // Mouse
    procedure MouseDown(Button: TMouseButton);
    procedure MouseMove;
    procedure MouseWheel(Down: Boolean);
    procedure MouseUp(Button: TMouseButton);
    // Update
    procedure Update(Sender: TObject = nil);
    procedure UpdateVisibility;
    //# Properties
    property ClickTimer: TACLTimer read FClickTimer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BalloonHint(const ATitle, AText: string; AIconType: TACLTrayBalloonIcon);
    //# Properties
    property WantDoubleClicks: Boolean read FWantDoubleClicks write FWantDoubleClicks;
  public
    class function Capabilities: TACLTrayIconCapabilities;
    class function IsMouseAtIcon: Boolean;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default False;
    property Hint: string read FHint write SetHint;
    property Icon: TIcon read FIcon write SetIcon;
    property IconVisible: Boolean read FIconVisible write SetIconVisible default False;
    property ID: string read FID write SetID;
    // Gtk3: required (!), PopupMenu.OnPopup not supported!
    property PopupMenu: TPopupMenu read FPopupMenu write SetPopupMenu;
    // Events
    property OnBallonHintClick: TNotifyEvent read FOnBallonHintClick write FOnBallonHintClick;
    // Events - check ticClick in Capabilities
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    property OnDblClick: TNotifyEvent read FOnDblClick write FOnDblClick;
    property OnMidClick: TNotifyEvent read FOnMidClick write FOnMidClick;
    // Events - check ticMove in Capabilities
    property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseExit: TNotifyEvent read FOnMouseExit write FOnMouseExit;
    // Events - check ticWheel in Capabilities
    property OnMouseWheel: TACLTrayIconMouseWheelEvent read FOnMouseWheel write FOnMouseWheel;
  end;

implementation

{$IF DEFINED(MSWINDOWS)}
  {$I ACL.UI.TrayIcon.Win32.inc}
{$ELSEIF DEFINED(LCLGtkX)}
  {$I ACL.UI.TrayIcon.GtkX.inc}
{$ENDIF}
var
  FTrayIconIsMouseAtIcon: Integer;

{ TACLTrayIconIntf }

constructor TACLTrayIconIntf.Create(AIcon: TACLTrayIcon);
begin
  Owner := AIcon;
end;

function TACLTrayIconIntf.ActualIcon: TIcon;
var
  LForm: TForm;
begin
  Result := Owner.Icon;
  if Result.Empty and Safe.Cast(Owner.Owner, TForm, LForm) then
    Result := LForm.Icon;
  if Result.Empty and (Application.MainForm <> nil) then
    Result := Application.MainForm.Icon;
  if Result.Empty then
    Result := Application.Icon;
end;

procedure TACLTrayIconIntf.ShowMenu;
var
  LPoint: TPoint;
begin
  if Owner.PopupMenu <> nil then
  begin
    LPoint := MouseCursorPos;
    Owner.PopupMenu.PopupComponent := Owner;
    Owner.PopupMenu.Popup(LPoint.X, LPoint.Y);
  end;
end;

{ TACLTrayIcon }

constructor TACLTrayIcon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClickTimer := TACLTimer.CreateEx(HandlerClickTimer, GetDoubleClickTime);
  FIcon := TIcon.Create;
  FIcon.OnChange := Update;
  FWantDoubleClicks := True;
end;

destructor TACLTrayIcon.Destroy;
begin
  UpdateVisibility;
  ClickTimer.Enabled := False;
  TACLMouseTracker.Release(Self);
  FreeAndNil(FClickTimer);
  FreeAndNil(FIcon);
  inherited Destroy;
end;

procedure TACLTrayIcon.BalloonHint(
  const ATitle, AText: string; AIconType: TACLTrayBalloonIcon);
begin
  if FIconImpl <> nil then
    FIconImpl.BalloonHint(ATitle, AText, AIconType);
end;

procedure TACLTrayIcon.DoClick;
begin
  CallNotifyEvent(Self, OnClick);
end;

procedure TACLTrayIcon.DoDblClick;
begin
  if WantDoubleClicks then
    CallNotifyEvent(Self, OnDblClick);
end;

procedure TACLTrayIcon.DoMidClick;
begin
  CallNotifyEvent(Self, OnMidClick);
end;

procedure TACLTrayIcon.HandlerClickTimer(Sender: TObject);
begin
  ClickTimer.Enabled := False;
  if ClickTimer.Tag = 1 then
    DoClick;
  if ClickTimer.Tag > 1 then
    DoDblClick;
end;

function TACLTrayIcon.GetCurrentDpi: Integer;
begin
  Result := acGetSystemDpi;
end;

function TACLTrayIcon.IsMouseAtControl: Boolean;
begin
  Result := FLastMousePos = MouseCursorPos;
end;

procedure TACLTrayIcon.MouseDown(Button: TMouseButton);
begin
  Include(FMousePressed, Button);
end;

procedure TACLTrayIcon.MouseEnter;
begin
  Inc(FTrayIconIsMouseAtIcon);
  CallNotifyEvent(Self, OnMouseEnter);
end;

procedure TACLTrayIcon.MouseMove;
begin
  TACLMouseTracker.Start(Self);
  FLastMousePos := MouseCursorPos;
end;

procedure TACLTrayIcon.MouseLeave;
begin
  Dec(FTrayIconIsMouseAtIcon);
  CallNotifyEvent(Self, OnMouseExit);
end;

procedure TACLTrayIcon.Loaded;
begin
  inherited Loaded;
  UpdateVisibility;
end;

procedure TACLTrayIcon.MouseWheel(Down: Boolean);
begin
  if Assigned(OnMouseWheel) then OnMouseWheel(Self, Down);
end;

procedure TACLTrayIcon.MouseUp(Button: TMouseButton);
begin
  // #AI: 20.05.2024, Special for ExplorerPatcher
  // Если в момент Down изменится лейаут области уведомлений, то Up запросто
  // может придти другому приложению. Поэтому реагируем на Up только в случае
  // согласованного состояния.
  if not (Button in FMousePressed) then
    Exit;

  Exclude(FMousePressed, Button);
  case Button of
    mbLeft:
      if Assigned(OnDblClick) and WantDoubleClicks then
      begin
        if not ClickTimer.Enabled then
        begin
          ClickTimer.Enabled := True;
          ClickTimer.Tag := 0;
        end;
        ClickTimer.Tag := ClickTimer.Tag + 1;
        if ClickTimer.Tag > 1 then
          HandlerClickTimer(nil);
      end
      else
        DoClick;

    mbRight:
      if FIconImpl <> nil then
        FIconImpl.ShowMenu;

    mbMiddle:
      DoMidClick;
  else;
  end;
end;

procedure TACLTrayIcon.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = PopupMenu then
      PopupMenu := nil;
  end;
end;

class function TACLTrayIcon.IsMouseAtIcon: Boolean;
begin
  Result := FTrayIconIsMouseAtIcon > 0;
end;

procedure TACLTrayIcon.SetEnabled(AValue: Boolean);
begin
  if Enabled <> AValue then
  begin
    FEnabled := AValue;
    UpdateVisibility;
  end;
end;

procedure TACLTrayIcon.SetHint(const AValue: string);
begin
  if FHint <> AValue then
  begin
    FHint := AValue;
    Update;
  end;
end;

procedure TACLTrayIcon.SetIcon(AValue: TIcon);
begin
  Icon.Assign(AValue);
end;

procedure TACLTrayIcon.SetIconVisible(AValue: Boolean);
begin
  if IconVisible <> AValue then
  begin
    FIconVisible := AValue;
    UpdateVisibility;
  end;
end;

procedure TACLTrayIcon.SetID(const AValue: string);
begin
  if FID <> AValue then
  begin
    FID := AValue;
    Update;
  end;
end;

procedure TACLTrayIcon.SetPopupMenu(AValue: TPopupMenu);
var
  LWasVisible: Boolean;
begin
  if AValue <> FPopupMenu then
  begin
    LWasVisible := FIconImpl <> nil;
    SetVisible(False);
    acComponentFieldSet(FPopupMenu, Self, AValue);
    SetVisible(LWasVisible);
  end;
end;

procedure TACLTrayIcon.SetVisible(AValue: Boolean);
begin
  AValue := AValue and ([csDesigning, csDestroying, csLoading, csReading] * ComponentState = []);
  if (FIconImpl <> nil) <> AValue then
  begin
    if AValue then
      FIconImpl := TACLTrayIconImpl.Create(Self)
    else
      FreeAndNil(FIconImpl);
  end;
end;

procedure TACLTrayIcon.Update(Sender: TObject);
begin
  if FIconImpl <> nil then
    FIconImpl.Update;
end;

procedure TACLTrayIcon.UpdateVisibility;
begin
  SetVisible(IconVisible and Enabled);
end;

end.
