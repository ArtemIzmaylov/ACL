{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             TrayIcon Classes              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.TrayIcon;

{$I ACL.Config.inc}

interface

uses
  Types, Windows, Messages, SysUtils, Classes, Graphics, Controls,
  Forms, Menus, ShellApi, ExtCtrls, Generics.Collections,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.Geometry,
  ACL.Graphics,
  ACL.ObjectLinks,
  ACL.Hashes,
  ACL.UI.Controls.BaseControls,
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

type
  TACLTrayBalloonIcon = (bitNone, bitInfo, bitWarning, bitError);

  { TACLTrayIcon }

  TACLTrayIcon = class(TACLComponent,
    IACLScaleFactor,
    IACLMouseTracking)
  strict private
    FClickTimer: TACLTimer;
    FEnabled: Boolean;
    FHandle: HWND;
    FHint: UnicodeString;
    FIcon: TIcon;
    FIconData: TNotifyIconData;
    FIconVisible: Boolean;
    FID: UnicodeString;
    FLastMousePos: TPoint;
    FPopupMenu: TPopupMenu;
    FVisible: Boolean;
    FWantDoubleClicks: Boolean;

    FOnBallonHintClick: TNotifyEvent;
    FOnClick: TNotifyEvent;
    FOnDblClick: TNotifyEvent;
    FOnMouseDown: TMouseEvent;
    FOnMouseEnter: TNotifyEvent;
    FOnMouseExit: TNotifyEvent;
    FOnMouseMove: TMouseMoveEvent;
    FOnMouseUp: TMouseEvent;

    procedure BuildIconData;
    function IsClickTimerRequired: Boolean;
    procedure SetEnabled(AValue: Boolean);
    procedure SetHint(const AValue: UnicodeString);
    procedure SetIcon(AValue: TIcon);
    procedure SetIconVisible(AValue: Boolean);
    procedure SetID(const AValue: UnicodeString);
    procedure SetVisible(AValue: Boolean);
    //
    procedure HandlerClickTimer(Sender: TObject);
    procedure HandlerIconChanged(Sender: TObject);
  protected
    // Events
    procedure DoClick; dynamic;
    procedure DoDblClick; dynamic;
    procedure DoMouseDown(Button: TMouseButton; Shift: TShiftState; const P: TPoint); dynamic;
    procedure DoMouseMove(Shift: TShiftState; const P: TPoint); dynamic;
    procedure DoMouseUp(Button: TMouseButton; Shift: TShiftState; const P: TPoint); dynamic;
    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; const P: TPoint);
    procedure MouseMove(Shift: TShiftState; const P: TPoint);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; const P: TPoint);
    // IACLScaleFactor
    function GetScaleFactor: TACLScaleFactor;
    // IACLMouseTracking
    function IsMouseAtControl: Boolean;
    procedure MouseEnter;
    procedure MouseLeave;
    //
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure WndProc(var Message: TMessage);
    //
    procedure Update;
    procedure UpdateIconState(ACommand: Integer);
    procedure UpdateVisibility;
    //
    property ClickTimer: TACLTimer read FClickTimer;
    property Visible: Boolean read FVisible write SetVisible;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BalloonHint(const ATitle, AText: UnicodeString; AIconType: TACLTrayBalloonIcon);
    procedure PopupAtCursor;
    //
    property WantDoubleClicks: Boolean read FWantDoubleClicks write FWantDoubleClicks;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default False;
    property Hint: UnicodeString read FHint write SetHint;
    property Icon: TIcon read FIcon write SetIcon;
    property IconVisible: Boolean read FIconVisible write SetIconVisible default False;
    property ID: UnicodeString read FID write SetID;
    property PopupMenu: TPopupMenu read FPopupMenu write FPopupMenu;
    // Events
    property OnBallonHintClick: TNotifyEvent read FOnBallonHintClick write FOnBallonHintClick;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    property OnDblClick: TNotifyEvent read FOnDblClick write FOnDblClick;
    property OnMouseDown: TMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseExit: TNotifyEvent read FOnMouseExit write FOnMouseExit;
    property OnMouseMove: TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnMouseUp: TMouseEvent read FOnMouseUp write FOnMouseUp;
  end;

function acTrayIconGetIsMouseAtIcon: Boolean;
implementation

uses
  Math,
  ACL.Classes.MessageWindow,
  ACL.Utils.Desktop,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

const
  NIF_INFO             = $00000010;
  NIIF_NONE            = $00000000;
  NIIF_INFO            = $00000001;
  NIIF_WARNING         = $00000002;
  NIIF_ERROR           = $00000003;

const
  WM_TRAYNOTIFY = WM_USER + 1024;

var
  FTrayIconIsMouseAtIcon: Integer;
  WM_TASKBARCREATED: DWORD = 0;

function acTrayIconGetIsMouseAtIcon: Boolean;
begin
  Result := FTrayIconIsMouseAtIcon > 0;
end;

{ TACLTrayIcon }

constructor TACLTrayIcon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIcon := TIcon.Create;
  FIcon.OnChange := HandlerIconChanged;
  FClickTimer := TACLTimer.CreateEx(HandlerClickTimer, GetDoubleClickTime);
  FHandle := WndCreate(WndProc, ClassName);
  WantDoubleClicks := True;
end;

destructor TACLTrayIcon.Destroy;
begin
  Enabled := False;
  ClickTimer.Enabled := False;
  MouseTracker.Remove(Self);
  FreeAndNil(FClickTimer);
  FreeAndNil(FIcon);
  WndFree(FHandle);
  inherited Destroy;
end;

procedure TACLTrayIcon.BalloonHint(const ATitle, AText: UnicodeString; AIconType: TACLTrayBalloonIcon);
const
  BalloonIconTypes: array[TACLTrayBalloonIcon] of Integer = (NIIF_NONE, NIIF_INFO, NIIF_WARNING, NIIF_ERROR);
begin
  if Visible and not (csDesigning in ComponentState) then
  begin
    BuildIconData;
    FIconData.uFlags := FIconData.uFlags or NIF_INFO;
    acStrLCopy(FIconData.szInfo, AText, Length(FIconData.szInfo) - 1);
    acStrLCopy(FIconData.szInfoTitle, ATitle, Length(FIconData.szInfoTitle) - 1);
    FIconData.dwInfoFlags := BalloonIconTypes[AIconType];
    Shell_NotifyIconW(NIM_MODIFY, @FIconData);
  end;
end;

procedure TACLTrayIcon.BuildIconData;
var
  AState: Pointer;
begin
  ZeroMemory(@FIconData, SizeOf(FIconData));
  FIconData.cbSize := TNotifyIconData.SizeOf;
  FIconData.hIcon := Icon.Handle;
  FIconData.Wnd := FHandle;
  FIconData.uCallbackMessage := WM_TRAYNOTIFY;
  FIconData.uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
  FIconData.uVersion := IfThen(IsWinVistaOrLater, NOTIFYICON_VERSION_4, NOTIFYICON_VERSION);

  if ID <> '' then
  begin
    if IsWinSevenOrLater then
    begin
      TACLHashMD5.Initialize(AState);
      TACLHashMD5.Update(AState, ID);
      TACLHashMD5.Finalize(AState, TMD5Byte16(FIconData.guidItem));
      FIconData.uFlags := FIconData.uFlags or NIF_GUID;
    end
    else
      FIconData.uID := TACLHashCRC32.Calculate(ID);
  end;

  if IsWin11OrLater then
    acStrLCopy(FIconData.szTip, Hint, Length(FIconData.szTip) - 1)
  else
    acStrLCopy(FIconData.szTip, acStringReplace(Hint, '&', '&&&'), Length(FIconData.szTip) - 1);
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

procedure TACLTrayIcon.DoMouseDown(Button: TMouseButton; Shift: TShiftState; const P: TPoint);
begin
  if Assigned(OnMouseDown) then OnMouseDown(Self, Button, Shift, P.X, P.Y);
end;

procedure TACLTrayIcon.DoMouseUp(Button: TMouseButton; Shift: TShiftState; const P: TPoint);
begin
  if Assigned(OnMouseUp) then OnMouseUp(Self, Button, Shift, P.X, P.Y);
end;

procedure TACLTrayIcon.DoMouseMove(Shift: TShiftState; const P: TPoint);
begin
  if Assigned(OnMouseMove) then OnMouseMove(Self, Shift, P.X, P.Y);
end;

procedure TACLTrayIcon.Update;
begin
  if Visible then
    UpdateIconState(NIM_MODIFY);
end;

function TACLTrayIcon.GetScaleFactor: TACLScaleFactor;
begin
  Result := acSystemScaleFactor;
end;

function TACLTrayIcon.IsMouseAtControl: Boolean;
begin
  Result := acPointIsEqual(FLastMousePos, MouseCursorPos);
end;

procedure TACLTrayIcon.MouseEnter;
begin
  Inc(FTrayIconIsMouseAtIcon);
  CallNotifyEvent(Self, OnMouseEnter);
end;

procedure TACLTrayIcon.MouseDown(Button: TMouseButton; Shift: TShiftState; const P: TPoint);
begin
  DoMouseDown(Button, Shift, P);
end;

procedure TACLTrayIcon.MouseMove(Shift: TShiftState; const P: TPoint);
begin
  FLastMousePos := P;
  MouseTracker.Add(Self);
  DoMouseMove(Shift, P);
end;

procedure TACLTrayIcon.MouseUp(Button: TMouseButton; Shift: TShiftState; const P: TPoint);
var
  ALink: TObject;
begin
  TACLObjectLinks.RegisterWeakReference(Self, @ALink);
  try
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
        end
        else
          DoClick;

      mbRight:
        PopupAtCursor;
    end;
    if ALink <> nil then
      DoMouseUp(Button, Shift, P);
  finally
    TACLObjectLinks.UnregisterWeakReference(@ALink);
  end;
end;

procedure TACLTrayIcon.MouseLeave;
begin
  Dec(FTrayIconIsMouseAtIcon);
  CallNotifyEvent(Self, OnMouseExit);
end;

procedure TACLTrayIcon.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_TASKBARCREATED then
  begin
    FVisible := False;
    UpdateVisibility;
  end;
  if Message.Msg = WM_TRAYNOTIFY then
  begin
    case Message.lParam of
      WM_MOUSEMOVE:
        MouseMove(acGetShiftState, MouseCursorPos);
      WM_LBUTTONDOWN:
        MouseDown(mbLeft, acGetShiftState, MouseCursorPos);
      WM_RBUTTONDOWN:
        MouseDown(mbRight, acGetShiftState, MouseCursorPos);
      WM_MBUTTONDOWN:
        MouseDown(mbMiddle, acGetShiftState, MouseCursorPos);
      WM_LBUTTONUP:
        MouseUp(mbLeft, acGetShiftState, MouseCursorPos);
      WM_RBUTTONUP:
        MouseUp(mbRight, acGetShiftState, MouseCursorPos);
      WM_MBUTTONUP:
        MouseUp(mbMiddle, acGetShiftState, MouseCursorPos);
      NIN_BALLOONUSERCLICK:
        CallNotifyEvent(Self, OnBallonHintClick);
    end;
  end;
  WndDefaultProc(FHandle, Message);
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
  if Assigned(PopupMenu) and GetCursorPos(APoint) then
  begin
    SetForegroundWindow(Application.Handle);
    Application.ProcessMessages;
    FPopupMenu.AutoPopup := False;
    FPopupMenu.PopupComponent := Self;
    FPopupMenu.Popup(APoint.x, APoint.y);
  end;
end;

procedure TACLTrayIcon.UpdateIconState(ACommand: Integer);
begin
  if not (csDesigning in ComponentState) then
  begin
    BuildIconData;
    Shell_NotifyIconW(ACommand, @FIconData);
  end;
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

procedure TACLTrayIcon.SetHint(const AValue: UnicodeString);
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

procedure TACLTrayIcon.SetID(const AValue: UnicodeString);
begin
  if FID <> AValue then
  begin
    FID := AValue;
    Update;
  end;
end;

procedure TACLTrayIcon.SetVisible(AValue: Boolean);
const
  CommandMap: array[Boolean] of Integer = (NIM_DELETE, NIM_ADD);
begin
  if Visible <> AValue then
  begin
    FVisible := AValue;
    UpdateIconState(CommandMap[Visible]);
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

initialization
  WM_TASKBARCREATED := RegisterWindowMessage('TaskbarCreated');
end.
