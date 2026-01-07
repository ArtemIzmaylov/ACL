{%MainUnit ACL.UI.Application.pas}

// Useful information:
//   https://deepwiki.com/linuxdeepin/xdg-desktop-portal-dde/3.6-settings-portal
//   https://github.com/mozilla/gecko-dev/blob/2d520652e0275ccc4d86a1a82fd05a9178c70b42/widget/gtk/nsLookAndFeel.cpp

uses
{$IF DEFINED(LCLGtk3)}
  LazGio2,
  LazGLib2,
  LazGObject2,
{$ELSEIF DEFINED(LCLGtk2)}
  Glib2,
{$ENDIF}
  // ACL
  ACL.Utils.FileSystem.GIO,
  ACL.Utils.Logger;

type

  { TGlobalSettings }

  TGlobalSettings = class
  strict private
    class procedure ChangeCallback(Proxy: PGDBusProxy;
      Sender, Signal: PChar; Params: PGVariant; Self: TGlobalSettings); cdecl; static;
  strict private
    FHandle: PGDBusProxy;
    FOnChange: TThreadMethod;
    function FetchValue(AName: Pgchar): PGVariant;
  public
    constructor Create(AChangeEvent: TThreadMethod);
    destructor Destroy; override;
    function GetColorAccent: TAlphaColor;
    procedure GetDarkMode(out ADarkModeForApps, ADarkModeForSystem: Boolean);
  end;

{$IFDEF LCLGtk3}
  procedure g_signal_handlers_disconnect_by_func(instance, func, data: gpointer);
  begin
    g_signal_handlers_disconnect_matched(instance,
      [G_SIGNAL_MATCH_FUNC, G_SIGNAL_MATCH_DATA], 0, 0, nil, func, data);
  end;
{$ENDIF}

  { TGlobalSettings }

  constructor TGlobalSettings.Create(AChangeEvent: TThreadMethod);
  var
    LError: PGError;
  begin
    FOnChange := AChangeEvent;
    LError := nil;
    FHandle := g_dbus_proxy_new_for_bus_sync(
      G_BUS_TYPE_SESSION, G_DBUS_PROXY_FLAGS_NONE, nil,
      'org.freedesktop.portal.Desktop', '/org/freedesktop/portal/desktop',
      'org.freedesktop.portal.Settings', nil, @LError);
    if LError <> nil then
      g_error_free(LError);
    if FHandle <> nil then
      g_signal_connect_data(FHandle, 'g-signal', TGCallback(@ChangeCallback), Self, nil, G_CONNECT_DEFAULT)
    else
      LogEntry(acGeneralLogFileName, 'App', ClassName + ' failed to initialize');
  end;

  destructor TGlobalSettings.Destroy;
  begin
    if FHandle <> nil then
    begin
      g_signal_handlers_disconnect_by_func(FHandle, Pointer(@ChangeCallback), Pointer(Self));
      g_object_unref(FHandle);
      FHandle := nil;
    end;
    inherited;
  end;

  class procedure TGlobalSettings.ChangeCallback(Proxy: PGDBusProxy;
    Sender, Signal: PChar; Params: PGVariant; Self: TGlobalSettings); cdecl;
  begin
    Self.FOnChange();
  end;

  function TGlobalSettings.FetchValue(AName: Pgchar): PGVariant;
  var
    LError: PGError;
  begin
    LError := nil;
    Result := g_dbus_proxy_call_sync(FHandle, 'Read',
      g_variant_new('(ss)', ['org.freedesktop.appearance', AName]),
      G_DBUS_CALL_FLAGS_NONE, 100, nil, @LError);
    if LError <> nil then
      g_error_free(LError);
    if Result <> nil then
      g_variant_replace(Result, g_variant_get_child_value(Result, 0));
    while (Result <> nil) and (g_variant_get_type_string(Result) = 'v') do
      g_variant_replace(Result, g_variant_get_variant(Result));
  end;

  function TGlobalSettings.GetColorAccent: TAlphaColor;
  var
    R,G,B: Double;
    LChild: PGVariant;
    LValue: PGVariant;
  begin
    Result := TAlphaColor.Default;
    LValue := FetchValue('accent-color');
    if (LValue <> nil) and (g_variant_get_type_string(LValue) = '(ddd)') then
    begin
      LChild := g_variant_get_child_value(LValue, 0);
      R := g_variant_get_double(LChild);
      g_variant_replace(LChild, g_variant_get_child_value(LValue, 1));
      G := g_variant_get_double(LChild);
      g_variant_replace(LChild, g_variant_get_child_value(LValue, 2));
      B := g_variant_get_double(LChild);
      g_variant_replace(LChild, nil);
      Result := TAlphaColor.FromARGB(255, Trunc(255 * R), Trunc(255 * G), Trunc(255 * B));
    end;
    g_variant_replace(LValue, nil);
  end;

  procedure TGlobalSettings.GetDarkMode(out ADarkModeForApps, ADarkModeForSystem: Boolean);
  var
    LValue: PGVariant;
  begin
    LValue := FetchValue('color-scheme');
    ADarkModeForSystem := (LValue <> nil) and
      (g_variant_get_type_string(LValue) = 'u') and
      (g_variant_get_uint32(LValue) = 1);
    ADarkModeForApps := ADarkModeForSystem;
    g_variant_replace(LValue, nil);
  end;

