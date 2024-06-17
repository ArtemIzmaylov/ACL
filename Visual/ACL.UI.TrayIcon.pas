////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   tray icon
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       Partial
//
unit ACL.UI.TrayIcon;

{$I ACL.Config.inc}

{
  FPC:ToDo:
    OnBallonHintClick does not work

  If tray-icon does not work on your Linux, try following:
    UnityWSCtrls.GlobalUseAppInd := UseAppIndNo;
}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Messages,
  Winapi.ShellApi,
  Winapi.Windows,
{$ELSE}
  LCLIntf,
  LCLType,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}ExtCtrls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}Menus,
  // ACL
  ACL.Classes,
  ACL.Timers,
  ACL.Graphics,
  ACL.ObjectLinks,
  ACL.UI.Controls.BaseControls,
  ACL.UI.HintWindow,
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

type
  TACLTrayIcon = class;
  TACLTrayIconCommand = (ticAdd, ticUpdate, ticRemove);
  TACLTrayBalloonIcon = (bitNone, bitInfo, bitWarning, bitError);

  { IACLTrayIconImpl }

  TACLTrayIconImpl = class
  strict private
    FIcon: TACLTrayIcon;
  public
    constructor Create(AIcon: TACLTrayIcon); virtual;
    procedure BalloonHint(const ATitle, AText: string; AIconType: TACLTrayBalloonIcon); virtual; abstract;
    procedure Update(ACommand: TACLTrayIconCommand); virtual; abstract;
    property Icon: TACLTrayIcon read FIcon;
  end;

  { TACLTrayIcon }

  TACLTrayIcon = class(TACLComponent,
    IACLCurrentDpi,
    IACLMouseTracking)
  strict private
    FClickTimer: TACLTimer;
    FEnabled: Boolean;
    FHint: string;
    FIcon: TIcon;
    FIconImpl: TACLTrayIconImpl;
    FIconVisible: Boolean;
    FID: string;
    FLastMousePos: TPoint;
    FMousePressed: set of TMouseButton;
    FPopupMenu: TPopupMenu;
    FVisible: Boolean;
    FWantDoubleClicks: Boolean;

    FOnBallonHintClick: TNotifyEvent;
    FOnClick: TNotifyEvent;
    FOnDblClick: TNotifyEvent;
    FOnMidClick: TNotifyEvent;
    FOnMouseEnter: TNotifyEvent;
    FOnMouseExit: TNotifyEvent;

    function IsClickTimerRequired: Boolean;
    procedure SetEnabled(AValue: Boolean);
    procedure SetHint(const AValue: string);
    procedure SetIcon(AValue: TIcon);
    procedure SetIconVisible(AValue: Boolean);
    procedure SetID(const AValue: string);
    procedure SetVisible(AValue: Boolean);
    // Handlers
    procedure HandlerClickTimer(Sender: TObject);
    procedure HandlerIconChanged(Sender: TObject);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    // Events
    procedure DoClick; dynamic;
    procedure DoDblClick; dynamic;
    procedure DoMidClick; dynamic;
    // Mouse
    procedure MouseDown(Nop: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseMove(Nop: TObject; Shift: TShiftState; X, Y: Integer);
    procedure MouseUp(Nop: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    // IACLCurrentDpi
    function GetCurrentDpi: Integer;
    // IACLMouseTracking
    function IsMouseAtControl: Boolean;
    procedure MouseEnter;
    procedure MouseLeave;
    // Update
    procedure Update;
    procedure UpdateVisibility;
    //# Properties
    property ClickTimer: TACLTimer read FClickTimer;
    property Visible: Boolean read FVisible write SetVisible;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BalloonHint(const ATitle, AText: string; AIconType: TACLTrayBalloonIcon);
    procedure PopupAtCursor;
    //# Properties
    property WantDoubleClicks: Boolean read FWantDoubleClicks write FWantDoubleClicks;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default False;
    property Hint: string read FHint write SetHint;
    property Icon: TIcon read FIcon write SetIcon;
    property IconVisible: Boolean read FIconVisible write SetIconVisible default False;
    property ID: string read FID write SetID;
    property PopupMenu: TPopupMenu read FPopupMenu write FPopupMenu;
    // Events
    property OnBallonHintClick: TNotifyEvent read FOnBallonHintClick write FOnBallonHintClick;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    property OnDblClick: TNotifyEvent read FOnDblClick write FOnDblClick;
    property OnMidClick: TNotifyEvent read FOnMidClick write FOnMidClick;
    property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseExit: TNotifyEvent read FOnMouseExit write FOnMouseExit;
  end;

function acTrayIconGetIsMouseAtIcon: Boolean;
implementation

uses
{$IFDEF MSWINDOWS}
  ACL.Hashes,
{$ENDIF}
  ACL.Utils.Messaging,
  ACL.Utils.Desktop,
  ACL.Utils.Strings;

type
{$IFDEF MSWINDOWS}

  { TWinTrayIconImpl }

  TWinTrayIconImpl = class(TACLTrayIconImpl)
  strict private const
    WM_TRAYNOTIFY = WM_USER + 1024;
  strict private
    class var WM_TASKBARCREATED: DWORD;
  strict private
    FHandle: HWND;
    FIconData: TNotifyIconData;
    procedure BuildIconData;
    procedure WndProc(var Message: TMessage);
  public
    class constructor Create;
    constructor Create(AIcon: TACLTrayIcon); override;
    destructor Destroy; override;
    procedure BalloonHint(const ATitle, AText: string; AIconType: TACLTrayBalloonIcon); override;
    procedure Update(ACommand: TACLTrayIconCommand); override;
  end;

{$ELSE}

  { TLCLTrayIconImpl }

  TLCLTrayIconImpl = class(TACLTrayIconImpl)
  strict private
    FBalloon: TACLHintWindow;
    FBalloonTimer: TACLTimer;
    FTrayIcon: TTrayIcon;
    procedure HandlerBalloonClick(Sender: TObject);
    procedure HandlerBalloonTimeOut(Sender: TObject);
  public
    constructor Create(AIcon: TACLTrayIcon); override;
    destructor Destroy; override;
    procedure BalloonHint(const ATitle, AText: string; AIconType: TACLTrayBalloonIcon); override;
    procedure Update(ACommand: TACLTrayIconCommand); override;
  end;

{$ENDIF}

var
  FTrayIconIsMouseAtIcon: Integer;

function acTrayIconGetIsMouseAtIcon: Boolean;
begin
  Result := FTrayIconIsMouseAtIcon > 0;
end;

{ TACLTrayIconImpl }

constructor TACLTrayIconImpl.Create(AIcon: TACLTrayIcon);
begin
  FIcon := AIcon;
end;

{ TACLTrayIcon }

constructor TACLTrayIcon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIcon := TIcon.Create;
  FIcon.OnChange := HandlerIconChanged;
  FClickTimer := TACLTimer.CreateEx(HandlerClickTimer, GetDoubleClickTime);
  FWantDoubleClicks := True;
  if not (csDesigning in ComponentState) then
  {$IFDEF MSWINDOWS}
    FIconImpl := TWinTrayIconImpl.Create(Self);
  {$ELSE}
    FIconImpl := TLCLTrayIconImpl.Create(Self);
  {$ENDIF}
end;

destructor TACLTrayIcon.Destroy;
begin
  Enabled := False;
  ClickTimer.Enabled := False;
  MouseTracker.Remove(Self);
  FreeAndNil(FIconImpl);
  FreeAndNil(FClickTimer);
  FreeAndNil(FIcon);
  inherited Destroy;
end;

procedure TACLTrayIcon.BalloonHint(const ATitle, AText: string; AIconType: TACLTrayBalloonIcon);
begin
  if Visible and (FIconImpl <> nil) then
    FIconImpl.BalloonHint(ATitle, AText, AIconType);
end;

function TACLTrayIcon.IsClickTimerRequired: Boolean;
begin
  Result := Assigned(OnDblClick) and WantDoubleClicks;
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

function TACLTrayIcon.GetCurrentDpi: Integer;
begin
  Result := acGetSystemDpi;
end;

function TACLTrayIcon.IsMouseAtControl: Boolean;
begin
  Result := FLastMousePos = MouseCursorPos;
end;

procedure TACLTrayIcon.MouseDown(Nop: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Include(FMousePressed, Button);
end;

procedure TACLTrayIcon.MouseEnter;
begin
  Inc(FTrayIconIsMouseAtIcon);
  CallNotifyEvent(Self, OnMouseEnter);
end;

procedure TACLTrayIcon.MouseMove(Nop: TObject; Shift: TShiftState; X, Y: Integer);
begin
  MouseTracker.Add(Self);
  FLastMousePos := Point(X, Y);
end;

procedure TACLTrayIcon.MouseUp(Nop: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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
      if IsClickTimerRequired then
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
      PopupAtCursor;

    mbMiddle:
      DoMidClick;
  else;
  end;
end;

procedure TACLTrayIcon.MouseLeave;
begin
  Dec(FTrayIconIsMouseAtIcon);
  CallNotifyEvent(Self, OnMouseExit);
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

procedure TACLTrayIcon.PopupAtCursor;
var
  APoint: TPoint;
begin
  if Assigned(PopupMenu) and GetCursorPos(APoint{%H-}) then
  begin
    SetForegroundWindow(Application.{%H-}Handle);
    Application.ProcessMessages;
    FPopupMenu.AutoPopup := False;
    FPopupMenu.PopupComponent := Self;
    FPopupMenu.Popup(APoint.x, APoint.y);
  end;
end;

procedure TACLTrayIcon.Update;
begin
  if Visible and (FIconImpl <> nil) then
    FIconImpl.Update(ticUpdate);
end;

procedure TACLTrayIcon.UpdateVisibility;
begin
  Visible := IconVisible and Enabled;
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
  FIcon.Assign(AValue);
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

procedure TACLTrayIcon.SetVisible(AValue: Boolean);
const
  CommandMap: array[Boolean] of TACLTrayIconCommand = (ticRemove, ticAdd);
begin
  if Visible <> AValue then
  begin
    FVisible := AValue;
    if FIconImpl <> nil then
      FIconImpl.Update(CommandMap[Visible]);
  end;
end;

procedure TACLTrayIcon.HandlerIconChanged(Sender: TObject);
begin
  Update;
end;

procedure TACLTrayIcon.HandlerClickTimer(Sender: TObject);
begin
  ClickTimer.Enabled := False;
  if ClickTimer.Tag = 1 then
    DoClick;
  if ClickTimer.Tag > 1 then
    DoDblClick;
end;

{$IFDEF MSWINDOWS}

{ TWinTrayIconImpl }

class constructor TWinTrayIconImpl.Create;
begin
  WM_TASKBARCREATED := RegisterWindowMessage('TaskbarCreated');
end;

constructor TWinTrayIconImpl.Create(AIcon: TACLTrayIcon);
begin
  inherited;
  FHandle := WndCreate(WndProc, TACLTrayIcon.ClassName);
end;

destructor TWinTrayIconImpl.Destroy;
begin
  WndFree(FHandle);
  inherited;
end;

procedure TWinTrayIconImpl.BalloonHint(const ATitle, AText: string; AIconType: TACLTrayBalloonIcon);
const
  BalloonIconTypes: array[TACLTrayBalloonIcon] of Integer = (NIIF_NONE, NIIF_INFO, NIIF_WARNING, NIIF_ERROR);
begin
  BuildIconData;
  FIconData.uFlags := FIconData.uFlags or NIF_INFO;
  acStrLCopy(FIconData.szInfo, AText, Length(FIconData.szInfo) - 1);
  acStrLCopy(FIconData.szInfoTitle, ATitle, Length(FIconData.szInfoTitle) - 1);
  FIconData.dwInfoFlags := BalloonIconTypes[AIconType];
  Shell_NotifyIconW(NIM_MODIFY, @FIconData);
end;

procedure TWinTrayIconImpl.BuildIconData;
var
  AState: Pointer;
begin
  ZeroMemory(@FIconData, SizeOf(FIconData));
  FIconData.cbSize := TNotifyIconData.SizeOf;
  FIconData.hIcon := Icon.Icon.Handle;
  FIconData.Wnd := FHandle;
  FIconData.uCallbackMessage := WM_TRAYNOTIFY;
  FIconData.uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
  if IsWinVistaOrLater then
    FIconData.uVersion := NOTIFYICON_VERSION_4
  else
    FIconData.uVersion := NOTIFYICON_VERSION;

  if Icon.ID <> '' then
  begin
    if IsWinSevenOrLater then
    begin
      TACLHashMD5.Initialize(AState);
      TACLHashMD5.Update(AState, Icon.ID);
      TACLHashMD5.Finalize(AState, TMD5Byte16(FIconData.guidItem));
      FIconData.uFlags := FIconData.uFlags or NIF_GUID;
    end
    else
      FIconData.uID := TACLHashCRC32.Calculate(Icon.ID);
  end;

  if IsWin11OrLater then
    acStrLCopy(FIconData.szTip, Icon.Hint, Length(FIconData.szTip) - 1)
  else
    acStrLCopy(FIconData.szTip, acStringReplace(Icon.Hint, '&', '&&&'), Length(FIconData.szTip) - 1);
end;

procedure TWinTrayIconImpl.Update(ACommand: TACLTrayIconCommand);
const
  Map: array[TACLTrayIconCommand] of Cardinal = (NIM_ADD, NIM_MODIFY, NIM_DELETE);
begin
  BuildIconData;
  Shell_NotifyIconW(Map[ACommand], @FIconData);
end;

procedure TWinTrayIconImpl.WndProc(var Message: TMessage);
var
  LCurPos: TPoint;
begin
  if Message.Msg = WM_TASKBARCREATED then
  begin
    if Icon.Visible then
      Update(ticAdd);
  end;
  if Message.Msg = WM_TRAYNOTIFY then
  begin
    LCurPos := MouseCursorPos;
    case Message.lParam of
      WM_LBUTTONDOWN, WM_LBUTTONDBLCLK:
        Icon.MouseDown(nil, mbLeft, [], LCurPos.X, LCurPos.Y);
      WM_RBUTTONDOWN, WM_RBUTTONDBLCLK:
        Icon.MouseDown(nil, mbRight, [], LCurPos.X, LCurPos.Y);
      WM_MBUTTONDOWN, WM_MBUTTONDBLCLK:
        Icon.MouseDown(nil, mbMiddle, [], LCurPos.X, LCurPos.Y);
      WM_MOUSEMOVE:
        Icon.MouseMove(nil, [], LCurPos.X, LCurPos.Y);
      WM_LBUTTONUP:
        Icon.MouseUp(nil, mbLeft, [], LCurPos.X, LCurPos.Y);
      WM_RBUTTONUP:
        Icon.MouseUp(nil, mbRight, [], LCurPos.X, LCurPos.Y);
      WM_MBUTTONUP:
        Icon.MouseUp(nil, mbMiddle, [], LCurPos.X, LCurPos.Y);
      NIN_BALLOONUSERCLICK:
        CallNotifyEvent(Icon, Icon.OnBallonHintClick);
    end;
  end;
  WndDefaultProc(FHandle, Message);
end;

{$ELSE}

{ TLCLTrayIconImpl }

constructor TLCLTrayIconImpl.Create(AIcon: TACLTrayIcon);
begin
  inherited Create(AIcon);
  FTrayIcon := TTrayIcon.Create(nil);
  FTrayIcon.OnMouseDown := Icon.MouseDown;
  FTrayIcon.OnMouseMove := Icon.MouseMove;
  FTrayIcon.OnMouseUp := Icon.MouseUp;
  FBalloonTimer := TACLTimer.CreateEx(HandlerBalloonTimeOut, FTrayIcon.BalloonTimeout);
end;

destructor TLCLTrayIconImpl.Destroy;
begin
  FreeAndNil(FBalloonTimer);
  FreeAndNil(FBalloon);
  FreeAndNil(FTrayIcon);
  inherited Destroy;
end;

procedure TLCLTrayIconImpl.BalloonHint(
  const ATitle, AText: string; AIconType: TACLTrayBalloonIcon);
var
  LIconPos: TPoint;
  LScreenRect: TRect;
  LHorzAlignment: TACLHintWindowHorzAlignment;
  LVertAlignment: TACLHintWindowVertAlignment;
begin
  if FBalloon = nil then
  begin
    FBalloon := TACLHintWindow.Create(nil);
    FBalloon.OnClick := HandlerBalloonClick;
    FBalloon.Clickable := True;
  end;

  LIconPos := FTrayIcon.GetPosition;
  LScreenRect := MonitorGetBounds(LIconPos);

  if LIconPos.X = LScreenRect.Left then
    LHorzAlignment := hwhaLeft
  else if LIconPos.X = LScreenRect.Right then
    LHorzAlignment := hwhaRight
  else
    LHorzAlignment := hwhaCenter;

  if LIconPos.Y < LScreenRect.CenterPoint.Y then
    LVertAlignment := hwvaBelow
  else
    LVertAlignment := hwvaAbove;

  FBalloon.ShowFloatHint(
    Format('[big][b]%1:s[/b][/b]%0:s%0:s%2:s', [sLineBreak, ATitle, AText]),
    TRect.Create(LIconPos, 0, 0), LHorzAlignment, LVertAlignment);
  FBalloonTimer.Restart;
end;

procedure TLCLTrayIconImpl.HandlerBalloonClick(Sender: TObject);
begin
  HandlerBalloonTimeOut(Sender);
  CallNotifyEvent(Icon, Icon.OnBallonHintClick);
end;

procedure TLCLTrayIconImpl.HandlerBalloonTimeOut(Sender: TObject);
begin
  FBalloonTimer.Enabled := False;
  FBalloon.Hide;
end;

procedure TLCLTrayIconImpl.Update(ACommand: TACLTrayIconCommand);
begin
  FTrayIcon.Icon := Icon.Icon;
  FTrayIcon.Hint := Icon.Hint;
  case ACommand of
    ticAdd:
      FTrayIcon.Show;
    ticRemove:
      FTrayIcon.Hide;
  else
    FTrayIcon.InternalUpdate;
  end;
end;
{$ENDIF}
end.
