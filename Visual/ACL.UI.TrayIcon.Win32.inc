uses
  Winapi.Messages,
  Winapi.ShellApi,
  Winapi.Windows,
  // ACL
  ACL.Hashes;

type

  { TACLTrayIconImpl }

  TACLTrayIconImpl = class(TACLTrayIconIntf)
  strict private const
    WM_TRAYNOTIFY = WM_USER + 1024;
  strict private
    class var WM_TASKBARCREATED: DWORD;
  strict private
    FHandle: HWND;
    FIconData: TNotifyIconData;
    FTimestamp: Cardinal;
    function Build: PNotifyIconDataW;
    procedure WndProc(var Message: TMessage);
  public
    class constructor Create;
    constructor Create(AIcon: TACLTrayIcon);
    destructor Destroy; override;
    procedure BalloonHint(const ATitle, AText: string; AIconType: TACLTrayBalloonIcon); override;
    procedure Update; override;
  end;

  { TACLTrayIconImpl }

  class constructor TACLTrayIconImpl.Create;
  begin
    WM_TASKBARCREATED := RegisterWindowMessage('TaskbarCreated');
  end;

  constructor TACLTrayIconImpl.Create(AIcon: TACLTrayIcon);
  begin
    inherited;
    FTimestamp := TACLThread.Timestamp;
    FHandle := acWndAlloc(WndProc, TACLTrayIcon.ClassName);
    Shell_NotifyIconW(NIM_ADD, Build);
  end;

  destructor TACLTrayIconImpl.Destroy;
  begin
    Shell_NotifyIconW(NIM_DELETE, Build);
    acWndFree(FHandle);
    inherited;
  end;

  procedure TACLTrayIconImpl.BalloonHint(
    const ATitle, AText: string; AIconType: TACLTrayBalloonIcon);
  const
    Flags: array[TACLTrayBalloonIcon] of Integer = (
      NIIF_NONE, NIIF_INFO, NIIF_WARNING, NIIF_ERROR
    );
  begin
    Build;
    FIconData.uFlags := FIconData.uFlags or NIF_INFO;
    acStrLCopy(FIconData.szInfo, AText, Length(FIconData.szInfo) - 1);
    acStrLCopy(FIconData.szInfoTitle, ATitle, Length(FIconData.szInfoTitle) - 1);
    FIconData.dwInfoFlags := Flags[AIconType];
    Shell_NotifyIconW(NIM_MODIFY, @FIconData);
  end;

  function TACLTrayIconImpl.Build: PNotifyIconDataW;
  var
    LHint: string;
    LState: Pointer;
  begin
    ZeroMemory(@FIconData, SizeOf(FIconData));
    FIconData.cbSize := TNotifyIconData.SizeOf;
    FIconData.hIcon := ActualIcon.Handle;
    FIconData.Wnd := FHandle;
    FIconData.uCallbackMessage := WM_TRAYNOTIFY;
    FIconData.uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
    if acOSCheckVersion(6, 0) then
      FIconData.uVersion := NOTIFYICON_VERSION_4
    else
      FIconData.uVersion := NOTIFYICON_VERSION;

    if Owner.ID <> '' then
    begin
      if acOSCheckVersion(6, 1) then
      begin
        TACLHashMD5.Initialize(LState);
        TACLHashMD5.Update(LState, Owner.ID);
        TACLHashMD5.Finalize(LState, TMD5Byte16(FIconData.guidItem));
        FIconData.uFlags := FIconData.uFlags or NIF_GUID;
      end
      else
        FIconData.uID := TACLHashCRC32.Calculate(Owner.ID);
    end;

    LHint := Owner.Hint;
    if not acOSCheckVersion(10, 0, 22000) then
      LHint := acStringReplace(LHint, '&', '&&&');
    acStrLCopy(FIconData.szTip, LHint, Length(FIconData.szTip) - 1);
    Result := @FIconData;
  end;

  procedure TACLTrayIconImpl.Update;
  begin
    Shell_NotifyIconW(NIM_MODIFY, Build);
  end;

  procedure TACLTrayIconImpl.WndProc(var Message: TMessage);
  begin
    try
      if Message.Msg = WM_QUERYENDSESSION then
        Message.Result := 1;
      if Message.Msg = WM_TASKBARCREATED then
      begin
        if Owner.Visible then
        begin
          FTimestamp := TACLThread.Timestamp;
          Shell_NotifyIconW(NIM_ADD, Build);
        end;
      end;
      if Message.Msg = WM_TRAYNOTIFY then
      begin
        case Message.lParam of
          NIN_BALLOONUSERCLICK:
            CallNotifyEvent(Owner, Owner.OnBallonHintClick);
          WM_LBUTTONDOWN, WM_LBUTTONDBLCLK:
            Owner.MouseDown(mbLeft);
          WM_RBUTTONDOWN, WM_RBUTTONDBLCLK:
            Owner.MouseDown(mbRight);
          WM_MBUTTONDOWN, WM_MBUTTONDBLCLK:
            Owner.MouseDown(mbMiddle);
          WM_LBUTTONUP:
            Owner.MouseUp(mbLeft, MouseCursorPos);
          WM_RBUTTONUP:
            Owner.MouseUp(mbRight, MouseCursorPos);
          WM_MBUTTONUP:
            Owner.MouseUp(mbMiddle, MouseCursorPos);
          WM_MOUSEMOVE:
            // При запуске приложения приходит сообщение, что пользователь навел
            // указатель мыши на иконку в трее, хотя это не так. Похоже на баг винды.
            if TACLThread.IsTimeout(FTimestamp, 2000) then
              Owner.MouseMove
            else
              FTimestamp := 0;
        end;
      end;
      acWndDefaultProc(FHandle, Message);
    except
      if Assigned(ApplicationHandleException) then
        ApplicationHandleException(Self);
    end;
  end;

  { TACLTrayIcon }

  class function TACLTrayIcon.Capabilities: TACLTrayIconCapabilities;
  begin
    Result := [ticClick, ticMove];
  end;

