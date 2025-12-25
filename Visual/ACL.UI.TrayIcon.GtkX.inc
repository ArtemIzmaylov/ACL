{%MainUnit ACL.UI.TrayIcon.pas}
{.$DEFINE ACL_TRAYICON_DEBUGLOG}

uses
  GLib2,
{$IF DEFINED(LCLGtk3)}
  Gtk3Objects,
  Gtk3Widgets,
  LazGtk3,
  LazGdk3,
  LazGdkPixbuf2,
{$ELSEIF DEFINED(LCLGtk2)}
  Gtk2,
  Gdk2,
  Gtk2Int,
  Gtk2Def,
  Gtk2Ext,
  Gdk2Pixbuf,
{$ENDIF}
  // ACL
  ACL.Utils.FileSystem.GIO;

{$IFDEF LCLGtk3}
const Available_GtkStatusIcon_2_10 = True;
function gtk_status_icon_new: PGtkStatusIcon; cdecl; external LazGtk3_library;
procedure gtk_status_icon_set_from_pixbuf(status_icon: PGtkStatusIcon; pixbuf: PGdkPixbuf); cdecl; external LazGtk3_library;
procedure gtk_status_icon_set_tooltip_text(status_icon: PGtkStatusIcon; text: Pgchar); cdecl; external LazGtk3_library;
procedure gtk_status_icon_set_visible(status_icon: PGtkStatusIcon; visible: gboolean); cdecl; external LazGtk3_library;
{$ENDIF}

{$REGION ' Notifications '}
type

  { TACLLibNotify }

  TACLLibNotify = class
  public type
    PNotify = Pointer;
  strict private type
    TFreeFunc = procedure (data : gpointer); cdecl;
    TNotifyActionCallback = procedure (
      notification: PNotify; action: PChar; user_data: gpointer); cdecl;
    notify_notification_add_action_t = procedure (handle: PNotify;
      action, label_: PChar; callback: TNotifyActionCallback;
      user_data: gpointer; free_funch: TFreeFunc); cdecl;
    notify_notification_close_t = function (handle: PNotify; error: PPGError): gboolean; cdecl;
    notify_notification_new_t = function (summary, body, icon: PChar) : PNotify; cdecl;
    notify_notification_set_timeout_t = procedure (handle: PNotify; timeout: gint); cdecl;
    notify_notification_show_t = function(handle: PNotify; error: PPGError): gboolean; cdecl;
    notify_init_t = function (app_name: PChar): gboolean; cdecl;
    notify_uninit_t = procedure; cdecl;
  strict private
    class var FLibInit: Integer;
    class var FLibHandle: TLibHandle;
    class var FNotifyAddAction: notify_notification_add_action_t;
    class var FNotifyClose: notify_notification_close_t;
    class var FNotifyNew: notify_notification_new_t;
    class var FNotifySetTimeOut: notify_notification_set_timeout_t;
    class var FNotifyShow: notify_notification_show_t;
    class var FNotifyInit: notify_init_t;
    class var FNotifyUninit: notify_uninit_t;
    class function Init: Boolean;
    class procedure NotifyClickHandler(Handle: PNotify;
      Action: PChar; Impl: TACLTrayIconIntf); cdecl; static;
  public
    class destructor Destroy;
    class function CheckInit: Boolean;
    class procedure Free(var AHandle: PNotify);
    class function Show(const ATitle, ABody: string;
      AType: TACLTrayBalloonIcon; AHandler: TACLTrayIconIntf): PNotify;
  end;

  { TACLLibNotify }

  class function TACLLibNotify.Init: Boolean;
  var
    LAppName: string;
  begin
    Result := True;
    // Bind the library
    FLibHandle := acLoadLibrary('libnotify.so');
    FNotifyAddAction := acGetProcAddress(FLibHandle, 'notify_notification_add_action', Result);
    FNotifyClose := acGetProcAddress(FLibHandle, 'notify_notification_close', Result);
    FNotifyInit := acGetProcAddress(FLibHandle, 'notify_init', Result);
    FNotifyNew := acGetProcAddress(FLibHandle, 'notify_notification_new', Result);
    FNotifySetTimeOut := acGetProcAddress(FLibHandle, 'notify_notification_set_timeout', Result);
    FNotifyShow := acGetProcAddress(FLibHandle, 'notify_notification_show', Result);
    FNotifyUninit := acGetProcAddress(FLibHandle, 'notify_uninit', Result);

    // Init the library
    if Result then
    begin
      LAppName := ApplicationName;
      Result := FNotifyInit(PChar(LAppName));
      LogEntry(acGeneralLogFileName, 'App', 'NotifyInit(%s,%d)', [LAppName, Ord(Result)]);
    end;
  end;

  class destructor TACLLibNotify.Destroy;
  begin
    if FLibInit > 0 then
      FNotifyUninit();
  end;

  class function TACLLibNotify.CheckInit: Boolean;
  begin
    if FLibInit = 0 then
    try
      FLibInit := IfThen(Init, 1, -1);
    except
      FLibInit := -1;
    end;
    Result := FLibInit > 0;
  end;

  class procedure TACLLibNotify.Free(var AHandle: PNotify);
  var
    LError: PGError;
  begin
    if AHandle <> nil then
    try
      LError := nil;
      FNotifyClose(AHandle, @LError);
      g_clear_error(@LError);
      g_object_unref(AHandle);
    finally
      AHandle := nil;
    end;
  end;

  class procedure TACLLibNotify.NotifyClickHandler(
    Handle: PNotify; Action: PChar; Impl: TACLTrayIconIntf); cdecl;
  begin
    CallNotifyEvent(Impl.Owner, Impl.Owner.OnBallonHintClick);
  end;

  class function TACLLibNotify.Show(const ATitle, ABody: string;
    AType: TACLTrayBalloonIcon; AHandler: TACLTrayIconIntf): PNotify;
  const
    Icons: array[TACLTrayBalloonIcon] of PChar = (
      nil, 'dialog-information', 'dialog-warning', 'dialog-error'
    );
  var
    LError: PGError;
  begin
    Result := FNotifyNew(PChar(ATitle), PChar(ABody), Icons[AType]);
    if Result = nil then Exit;
    FNotifyAddAction(Result, 'default', ' ', @NotifyClickHandler, AHandler, nil);
    FNotifySetTimeOut(Result, TACLTrayIcon.BalloonTimeout);

    LError := nil;
    if not FNotifyShow(Result, @LError) then
    begin
      LogEntry(acGeneralLogFileName, 'App', 'NotifyShow(failed: %s)', [gioErrorToString(LError)]);
      g_clear_error(@LError);
      g_object_unref(Result);
      Result := nil;
    end;
  end;

{$ENDREGION}

type

  { TACLTrayIconImplBase }

  TACLTrayIconImplBase = class(TACLTrayIconIntf)
  strict private
    FBalloonHandle: Pointer;
  public
    destructor Destroy; override;
    procedure BalloonHint(const ATitle, AText: string; AIconType: TACLTrayBalloonIcon); override;
  end;

  { TACLStatusIconImpl }

  TACLStatusIconImpl = class(TACLTrayIconImplBase)
  strict private
    FHandle: PGtkStatusIcon;
  strict private
    class function HandlerButtonPress(Icon: PGtkStatusIcon;
      Event: PGdkEventButton; Self: TACLStatusIconImpl): gboolean; cdecl; static;
    class function HandlerButtonRelease(Icon: PGtkStatusIcon;
      Event: PGdkEventButton; Self: TACLStatusIconImpl): gboolean; cdecl; static;
    class function HandlerScroll(Icon: PGtkStatusIcon;
      Event: PGdkEventScroll; Self: TACLStatusIconImpl): gboolean; cdecl; static;
    class function HandlerQueryTooltip({%H-}status_icon: PGtkStatusIcon; x, y: guint;
      {%H-}keyboard_mode: gboolean; {%H-}tooltip: gpointer; self: TACLStatusIconImpl): gboolean; cdecl; static;
  public
    constructor Create(AIcon: TACLTrayIcon);
    destructor Destroy; override;
    procedure Update; override;
  end;

  { TACLTrayIconImpl }

  TACLTrayIconImpl = class(TACLStatusIconImpl);

  function GetPixbuf(AIcon: TIcon): PGdkPixbuf;
  begin
    if (AIcon = nil) or AIcon.Empty then
      Result := nil
    else
    {$IF DEFINED(LCLGtk3)}
      Result := TGtk3Image(AIcon.Handle).Handle;
    {$ELSEIF DEFINED(LCLGtk2)}
      Result := PGdkPixbuf(AIcon.Handle);
    {$ENDIF}
  end;

  { TACLTrayIconImplBase }

  destructor TACLTrayIconImplBase.Destroy;
  begin
    TACLLibNotify.Free(FBalloonHandle);
    inherited Destroy;
  end;

  procedure TACLTrayIconImplBase.BalloonHint(
    const ATitle, AText: string; AIconType: TACLTrayBalloonIcon);
  begin
    if TACLLibNotify.CheckInit then
    begin
      TACLLibNotify.Free(FBalloonHandle);
      FBalloonHandle := TACLLibNotify.Show(ATitle, AText, AIconType, Self);
    end;
  end;

  { TACLStatusIconImpl }

  constructor TACLStatusIconImpl.Create(AIcon: TACLTrayIcon);
  begin
    inherited;
    Update;
  end;

  destructor TACLStatusIconImpl.Destroy;
  begin
    if FHandle <> nil then
    try
      gtk_status_icon_set_visible(FHandle, False);
      g_object_unref(FHandle);
    finally
      FHandle := nil;
    end;
    inherited;
  end;

  class function TACLStatusIconImpl.HandlerButtonPress(Icon: PGtkStatusIcon;
    Event: PGdkEventButton; Self: TACLStatusIconImpl): gboolean; cdecl;
  begin
  {$IFDEF ACL_TRAYICON_DEBUGLOG}
    // x, y are local coordinates
    WriteLn('Tray:ButtonDown ', Event^.button, ' ',
      Round(Event.x), ' ', Round(Event.y), ' ',
      Round(Event.x_root), ' ', Round(Event.y_root));
  {$ENDIF}

    case Event^.button of
      1: Self.Owner.MouseDown(mbLeft);
      2: Self.Owner.MouseDown(mbMiddle);
      3: Self.Owner.MouseDown(mbRight);
    end;

    // Events order:
    // + buttonpress
    // + buttonpress2
    // + buttonrelease
    // So, generate 2nd button release to be consistent
  {$IFDEF LCLGtk3}
    if Event^.type_ = GDK_2BUTTON_PRESS then
  {$ELSE}
    if Event^._type = GDK_2BUTTON_PRESS then
  {$ENDIF}
      HandlerButtonRelease(Icon, Event, Self);

    Result := gTRUE;
  end;

  class function TACLStatusIconImpl.HandlerButtonRelease(Icon: PGtkStatusIcon;
    Event: PGdkEventButton; Self: TACLStatusIconImpl): gboolean; cdecl;
  var
    LPoint: TPoint;
  begin
    Result := gTRUE;

  {$IFDEF ACL_TRAYICON_DEBUGLOG}
    WriteLn('Tray:ButtonUp ', Event^.button, ' ',
      Round(Event.x), ' ', Round(Event.y), ' ',
      Round(Event.x_root), ' ', Round(Event.y_root));
  {$ENDIF}

    LPoint.X := Round(Event.x_root + Event.x);
    LPoint.Y := Round(Event.y_root + Event.y);
    case Event^.button of
      1: Self.Owner.MouseUp(mbLeft, LPoint);
      2: Self.Owner.MouseUp(mbMiddle, LPoint);
      3: Self.Owner.MouseUp(mbRight, LPoint);
    end;
  end;

  class function TACLStatusIconImpl.HandlerScroll(Icon: PGtkStatusIcon;
    Event: PGdkEventScroll; Self: TACLStatusIconImpl): gboolean; cdecl;
  begin
  {$IFDEF ACL_TRAYICON_DEBUGLOG}
    WriteLn('Tray:Scroll: ', Integer(Event^.direction));
  {$ENDIF}
    Self.Owner.MouseWheel(Event^.direction in [GDK_SCROLL_UP, GDK_SCROLL_LEFT]);
    Result := gTRUE;
  end;

  class function TACLStatusIconImpl.HandlerQueryTooltip(
    status_icon: PGtkStatusIcon; x, y: guint; keyboard_mode: gboolean;
    tooltip: gpointer; self: TACLStatusIconImpl): gboolean; cdecl;
  begin
  {$IFDEF ACL_TRAYICON_DEBUGLOG}
    WriteLn('Tray:Query ', x, ' ', y);
  {$ENDIF}
    // На Gnome query-tooltip приходит при клике на иконку, дабы не
    // генерировать ложных событий - форсированно отключаем это дело
    if ticMove in TACLTrayIcon.Capabilities then
      Self.Owner.MouseMove;
    Result := gFALSE;
  end;

  procedure TACLStatusIconImpl.Update;
  begin
    if (FHandle = nil) and Available_GtkStatusIcon_2_10 then
    begin
      FHandle := gtk_status_icon_new();
      g_signal_connect(FHandle, 'query-tooltip', TGCallback(@HandlerQueryTooltip), Self);
      g_signal_connect(FHandle, 'button-press-event', TGCallback(@HandlerButtonPress), Self);
      g_signal_connect(FHandle, 'button-release-event', TGCallback(@HandlerButtonRelease), Self);
      g_signal_connect(FHandle, 'scroll_event', TGCallback(@HandlerScroll), Self);
      //size-changed, activate, popup-menu
    end;
    if FHandle <> nil then
    begin
      gtk_status_icon_set_from_pixbuf(FHandle, GetPixbuf(ActualIcon));
      gtk_status_icon_set_tooltip_text(FHandle, PChar(Owner.Hint));
      g_object_set(PGObject(FHandle), 'has-tooltip', gTRUE, nil);
      gtk_status_icon_set_visible(FHandle, True);
    end;
  end;

  { TACLTrayIcon }

  class function TACLTrayIcon.Capabilities: TACLTrayIconCapabilities;
  begin
    // TACLStatusIconImpl:
    // Проверил Cinnamon, Fly, Mate, XFCE, KDE, Gnome и выяснилось:
    // 1) query-tooltip не работает на Gnome и KDE
    // 2) scroll_event не работает на Gnome
    case ShellDesktopEnv of
      sdeGnome:
        Result := [ticClick];
      sdeKDE:
        Result := [ticClick, ticWheel];
    else
        Result := [ticClick, ticWheel, ticMove];
    end;
  end;
