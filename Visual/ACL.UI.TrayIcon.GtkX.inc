{%MainUnit ACL.UI.TrayIcon.pas}
{.$DEFINE ACL_TRAYICON_DEBUGLOG}

{$IFDEF LCLGtk3}
  {$DEFINE ACL_TRAYICON_ALLOW_APP_INDICATOR}
{$ENDIF}

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
  ACL.UI.Menus,
  ACL.Utils.FileSystem.GIO;

{$IFDEF LCLGtk3}
const Available_GtkStatusIcon_2_10 = True;
function gtk_status_icon_new: PGtkStatusIcon; cdecl; external LazGtk3_library;
procedure gtk_status_icon_set_from_file(status_icon:PGtkStatusIcon; filename:Pgchar); cdecl; external LazGtk3_library;
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
    notify_notification_new_t = function (summary, body, icon: PChar): PNotify; cdecl;
    notify_notification_set_image_from_pixbuf_t = procedure (handle: PNotify; image: PGdkPixbuf); cdecl;
    notify_notification_set_timeout_t = procedure (handle: PNotify; timeout: gint); cdecl;
    notify_notification_show_t = function(handle: PNotify; error: PPGError): gboolean; cdecl;
    notify_notification_update_t = function (handle: PNotify; summary, body, icon: PChar): gboolean; cdecl;
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
    //FNotifySetImage := acGetProcAddress(FLibHandle, 'notify_notification_set_image_from_pixbuf', Result);
    FNotifySetTimeOut := acGetProcAddress(FLibHandle, 'notify_notification_set_timeout', Result);
    FNotifyShow := acGetProcAddress(FLibHandle, 'notify_notification_show', Result);
    FNotifyUninit := acGetProcAddress(FLibHandle, 'notify_uninit', Result);
    //FNotifyUpdate := acGetProcAddress(FLibHandle, 'notify_notification_update', Result);

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
    FIconFileName: string;
    FIconId: string;
  protected
    procedure Log(const AMessage: string);
    // Properties
    property IconFileName: string read FIconFileName;
    property IconId: string read FIconId;
  public
    constructor Create(AIcon: TACLTrayIcon);
    destructor Destroy; override;
    procedure BalloonHint(const ATitle, AText: string; AIconType: TACLTrayBalloonIcon); override;
    procedure Update; override;
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
    destructor Destroy; override;
    procedure Update; override;
  end;

  { TACLAppIndicatorImpl }

  // https://lazka.github.io/pgi-docs/AyatanaAppIndicator3-0.1/classes/Indicator.html
  TACLAppIndicatorImpl = class(TACLTrayIconImplBase)
  strict private const
    libAppIndicator = 'libappindicator3.so.1';                // Unity or Canonical
    libAppIndicatorAyatana = 'libayatana-appindicator3.so.1'; // Ayatana
  strict private type
    PAppIndicator = Pointer;
    TAppIndicatorCategory = (
      APP_INDICATOR_CATEGORY_APPLICATION_STATUS,
      APP_INDICATOR_CATEGORY_COMMUNICATIONS,
      APP_INDICATOR_CATEGORY_SYSTEM_SERVICES,
      APP_INDICATOR_CATEGORY_HARDWARE,
      APP_INDICATOR_CATEGORY_OTHER
    );
    TAppIndicatorStatus = (
      APP_INDICATOR_STATUS_PASSIVE,
      APP_INDICATOR_STATUS_ACTIVE,
      APP_INDICATOR_STATUS_ATTENTION
    );
  strict private
    class var app_indicator_new: function(id, icon_name: PGChar; category: TAppIndicatorCategory): PAppIndicator; cdecl;
    class var app_indicator_set_label: procedure(self: PAppIndicator; lbl, guide: PGChar); cdecl;
    class var app_indicator_set_title: procedure(self: PAppIndicator; title: PGChar); cdecl;
    class var app_indicator_set_icon: procedure(self: PAppIndicator; icon_name: PGChar); cdecl;
    class var app_indicator_set_menu: procedure(self: PAppIndicator; menu: PGtkMenu); cdecl;
    class var app_indicator_set_secondary_activate_target: procedure(self: PAppIndicator; menuItem: PGtkWidget); cdecl;
    class var app_indicator_set_status: procedure (self: PAppIndicator; status: TAppIndicatorStatus); cdecl;
    class var app_indicator_state: Integer;
  strict private
    FHandle: PAppIndicator;
    FMenu: TPopupMenu;
    FMenuAutoGenerated: Boolean;
  public
    class function CheckInit: Boolean;
    destructor Destroy; override;
    procedure Update; override;
  end;

  { TACLTrayIconImpl }

  TACLTrayIconImpl = class
  public
    class function Create(AIcon: TACLTrayIcon): TACLTrayIconIntf;
  end;

  function GetWidget(AHandle: TObjHandle): Pointer;
  begin
  {$IF DEFINED(LCLGtk2)}
    Result := PGtkWidget(AHandle);
  {$ELSEIF DEFINED(LCLGtk3)}
    Result := TGtk3Widget(AHandle).Widget;
  {$ELSE}
    Result := nil;
  {$ENDIF}
  end;

  { TACLTrayIconImplBase }

  constructor TACLTrayIconImplBase.Create(AIcon: TACLTrayIcon);
  begin
    inherited;
    FIconId := 'appin-' + IfThenW(Owner.ID, IntToHex(NativeUInt(Owner)));
    Update;
  end;

  destructor TACLTrayIconImplBase.Destroy;
  begin
    TACLLibNotify.Free(FBalloonHandle);
    if FIconFileName <> '' then
      DeleteFile(FIconFileName);
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

  procedure TACLTrayIconImplBase.Log(const AMessage: string);
  begin
    LogEntry(acGeneralLogFileName, 'Tray', AMessage + ' (' + IconId + ')');
  end;

  procedure TACLTrayIconImplBase.Update;
  var
    LIcon: TIcon;
    LIconIndex: Integer;
    LIconSize: Integer;
    LPng: TFPImageBitmap;
  begin
    LIcon := ActualIcon;
    if LIcon.Empty then
    begin
      Log('[!] WARNING: an empty icon was specified');
      Exit;
    end;

    if FIconFileName <> '' then
      DeleteFile(FIconFileName);
    // Главное, чтобы имя файла отличалось от предыдущего, иначе
    // API будет думать, что мы пытаемся назначить туже самую иконку.
    FIconFileName := GetTempDir + FIconId + '-' + IntToStr(TACLThread.Timestamp) + '.png';

    LIconIndex := 0;
    if ShellDesktopEnv = sdeXFCE then
      LIconIndex := LIcon.GetBestIndexForSize(TSize.Create(48, 48));
    LPng := LIcon.ExportImage(LIconIndex, TPortableNetworkGraphic);
    try
      LPng.SaveToFile(FIconFileName);
    finally
      LPng.Free;
    end;
  end;

  { TACLStatusIconImpl }

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
    inherited;
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
      gtk_status_icon_set_from_file(FHandle, Pgchar(IconFileName));
      gtk_status_icon_set_tooltip_text(FHandle, PChar(Owner.Hint));
      g_object_set(PGObject(FHandle), 'has-tooltip', gTRUE, nil);
      gtk_status_icon_set_visible(FHandle, True);
    end;
  end;

  { TACLAppIndicatorImpl }

  destructor TACLAppIndicatorImpl.Destroy;
  begin
    if FHandle <> nil then
    try
      app_indicator_set_status(FHandle, APP_INDICATOR_STATUS_PASSIVE);
      g_object_unref(FHandle);
    finally
      FHandle := nil;
    end;
    if FMenuAutoGenerated then
      FreeAndNil(FMenu);
    inherited;
  end;

  class function TACLAppIndicatorImpl.CheckInit: Boolean;
  var
    LLibHandle: HModule;
  begin
    if app_indicator_state = 0 then
    begin
      LLibHandle := 0;
      // Unlike AppIndicator, StatusIcon is more flexible and powerful.
      // So, using AppIndicator only on systems where StatusIcon is not available
      if ShellDesktopEnv = sdeGnome then
      begin
        LLibHandle := acLoadLibrary(libAppIndicator);
        if LLibHandle = 0 then
          LLibHandle := acLoadLibrary(libAppIndicatorAyatana);
      end;
      Result := LLibHandle <> 0;
      app_indicator_new := acGetProcAddress(LLibHandle, 'app_indicator_new', Result);
      app_indicator_set_icon := acGetProcAddress(LLibHandle, 'app_indicator_set_icon', Result);
      app_indicator_set_menu := acGetProcAddress(LLibHandle, 'app_indicator_set_menu', Result);
      app_indicator_set_label := acGetProcAddress(LLibHandle, 'app_indicator_set_label', Result);
      app_indicator_set_title := acGetProcAddress(LLibHandle, 'app_indicator_set_title', Result);
      app_indicator_set_status := acGetProcAddress(LLibHandle, 'app_indicator_set_status', Result);
      app_indicator_set_secondary_activate_target := acGetProcAddress(
        LLibHandle, 'app_indicator_set_secondary_activate_target', Result);
      app_indicator_state := IfThen(Result, 1, -1);
    end;
    Result := app_indicator_state > 0;
  end;

  procedure TACLAppIndicatorImpl.Update;
  var
    LDefaultItem: TMenuItem;
  begin
    inherited;

    if (FHandle = nil) and CheckInit then
    begin
      // 1) AppIndicator will not be displayed if menu is empty or not set.
      // 2) It seems, we can set the menu only at once for the AppIndicator.
      FMenu := Owner.PopupMenu;
      if (FMenu = nil) or (FMenu.Items.FirstVisible = nil) then
      begin
        FMenu := TACLPopupMenu.Create(nil);
        FMenu.Items.AddItem(Owner.Hint, Owner.OnClick).Default := True;
        FMenuAutoGenerated := True;
      end;
      if Assigned(FMenu.OnPopup) then
        Log('[!] WARNING: AppIndicator does not support for dynamic menus');
      FHandle := app_indicator_new(PChar(IconId), PChar(IconFileName), APP_INDICATOR_CATEGORY_APPLICATION_STATUS);
      app_indicator_set_menu(FHandle, GetWidget(FMenu.Handle));
    end;

    if FHandle <> nil then
    begin
      LDefaultItem := FMenu.Items.DefaultItem;
      if LDefaultItem = nil then
        LDefaultItem := FMenu.Items.FirstVisible;
      if LDefaultItem <> nil then // вообще такого быть не должно
      begin
        if FMenuAutoGenerated then
          LDefaultItem.Caption := Owner.Hint;
        app_indicator_set_secondary_activate_target(FHandle, GetWidget(LDefaultItem.Handle));
      end;
      app_indicator_set_icon(FHandle, PChar(IconFileName));
      //app_indicator_set_label(FHandle, PChar(Owner.Hint), 'XXXX');
      app_indicator_set_title(FHandle, PChar(Owner.Hint));
      app_indicator_set_status(FHandle, APP_INDICATOR_STATUS_ACTIVE);
    end;
  end;

  { TACLTrayIcon }

  class function TACLTrayIcon.Capabilities: TACLTrayIconCapabilities;
  begin
  {$IFDEF ACL_TRAYICON_ALLOW_APP_INDICATOR}
    if TACLAppIndicatorImpl.CheckInit then
      Exit([]); // app-indicator умеет только встроенное меню показывать ...
  {$ENDIF}

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

  { TACLTrayIconImpl }

  class function TACLTrayIconImpl.Create(AIcon: TACLTrayIcon): TACLTrayIconIntf;
  begin
  {$IFDEF ACL_TRAYICON_ALLOW_APP_INDICATOR}
    if TACLAppIndicatorImpl.CheckInit then
      Result := TACLAppIndicatorImpl.Create(AIcon)
    else
  {$ENDIF}
      Result := TACLStatusIconImpl.Create(AIcon);
  end;
