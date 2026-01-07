////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Wrappers for Gnome IO Library
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Utils.FileSystem.GIO;

{$I ACL.Config.inc}

interface

uses
  GLib2, Contnrs, Types;

const
  libGio2 = 'libgio-2.0.so.0';

type
  PGIcon = Pointer;
  PGFile = Pointer;
  PGFileInfo = Pointer;
  PGFileEnumerator = Pointer;
  PGFileMonitor = Pointer;
  PGCancellable = Pointer;
  PGDBusConnection = Pointer;
  PGDBusMethodInvocation = Pointer;
  PGDBusInterfaceInfo = Pointer;
  PGDBusProxy = Pointer;
  PGVariant = Pointer;
  PGVariantBuilder = Pointer;
  PGVariantType = Pointer;
  PGUnixMountMonitor = Pointer;
  PGUnixMountPoint = Pointer;
  PGUnixMountEntry = Pointer;

type
  TGBusNameOwnerFlagsIdx = (
    G_BUS_NAME_OWNER_FLAGS_ALLOW_REPLACEMENT = 0,
    G_BUS_NAME_OWNER_FLAGS_REPLACE = 1,
    G_BUS_NAME_OWNER_FLAGS_DO_NOT_QUEUE = 2,
    TGBusNameOwnerFlagsIdxMaxValue = 31
  );
  TGBusNameOwnerFlags = Set of TGBusNameOwnerFlagsIdx;

  TGDBusInterfaceMethodCallFunc = procedure(connection: PGDBusConnection;
    sender, object_path, interface_name, method_name: Pgchar;
    parameters: PGVariant; invocation: PGDBusMethodInvocation; user_data: gpointer); cdecl;
  TGDBusInterfaceGetPropertyFunc = function(connection: PGDBusConnection;
    sender, object_path, interface_name, property_name: Pgchar;
    error: PPGError; user_data: gpointer): PGVariant; cdecl;
  TGDBusInterfaceSetPropertyFunc = function(connection: PGDBusConnection;
    sender, object_path, interface_name, property_name: Pgchar;
    value: PGVariant; error: PPGError; user_data: gpointer): gboolean; cdecl;

  PPGDBusInterfaceInfo = ^PGDBusInterfaceInfo;
  PPGVariant = ^PGVariant;

  PGDBusInterfaceVTable = ^TGDBusInterfaceVTable;
  TGDBusInterfaceVTable = record
    method_call: TGDBusInterfaceMethodCallFunc;
    get_property: TGDBusInterfaceGetPropertyFunc;
    set_property: TGDBusInterfaceSetPropertyFunc;
    padding: array [0..7] of gpointer;
  end;

  PGDBusNodeInfo = ^TGDBusNodeInfo;
  TGDBusNodeInfo = object
    ref_count: gint;
    path: Pgchar;
    interfaces: PPGDBusInterfaceInfo;
    //nodes: PPGDBusNodeInfo;
    //annotations: PPGDBusAnnotationInfo;
  end;

const
  G_BUS_NAME_OWNER_FLAGS_NONE = []; {0 = $00000000}

{$IFNDEF LCLGtk3}
type
  TGtkIconLookupFlag = (
    GTK_ICON_LOOKUP_NO_SVG = 0,
    GTK_ICON_LOOKUP_FORCE_SVG = 1,
    GTK_ICON_LOOKUP_USE_BUILTIN = 2,
    GTK_ICON_LOOKUP_GENERIC_FALLBACK = 3,
    GTK_ICON_LOOKUP_FORCE_SIZE = 4,
    GTK_ICON_LOOKUP_FORCE_REGULAR = 5,
    GTK_ICON_LOOKUP_FORCE_SYMBOLIC = 6,
    GTK_ICON_LOOKUP_DIR_LTR = 7,
    GTK_ICON_LOOKUP_DIR_RTL = 8,
    TGtkIconLookupFlagsIdxMaxValue = 31
  );
  TGtkIconLookupFlags = set of TGtkIconLookupFlag;

const
  G_CONNECT_DEFAULT = 0;
{$ENDIF}

const
  G_BUS_TYPE_SESSION = 2;
  G_DBUS_CALL_FLAGS_NONE = 0;
  G_DBUS_PROXY_FLAGS_NONE = 0;
  G_DBUS_ERROR_NOT_SUPPORTED = 7;

  G_FILE_COPY_NONE = 0;
  G_FILE_COPY_OVERWRITE = 1;
  G_FILE_COPY_BACKUP = 2;
  G_FILE_COPY_NOFOLLOW_SYMLINKS = 4;
  G_FILE_COPY_ALL_METADATA = 6;
  G_FILE_COPY_NO_FALLBACK_FOR_MOVE = 8;
  G_FILE_COPY_TARGET_DEFAULT_PERMS = 16;

  // TGFileMonitorFlags
  G_FILE_MONITOR_WATCH_MOUNTS = 1;
  G_FILE_MONITOR_SEND_MOVED   = 2;
  G_FILE_MONITOR_WATCH_HARD_LINKS = 4;
  G_FILE_MONITOR_WATCH_MOVES  = 8;

type
  TGBusNameCallback = procedure(connection: PGDBusConnection; name: Pgchar; user_data: gpointer); cdecl;

  PPGFileProgressCallback = ^PGFileProgressCallback;
  PGFileProgressCallback = ^TGFileProgressCallback;
  TGFileProgressCallback = procedure(current_num_bytes, total_num_bytes: gint64; user_data: gpointer); cdecl;
  TGFileMonitorFlags = LongWord;
  TGFileQueryInfoFlags = LongWord;

  TGFileMonitorEvent = (
    TGFileMonitorEventMinValue = -$7FFFFFFF,
    G_FILE_MONITOR_EVENT_CHANGED = 0,
    G_FILE_MONITOR_EVENT_CHANGES_DONE_HINT = 1,
    G_FILE_MONITOR_EVENT_DELETED = 2,
    G_FILE_MONITOR_EVENT_CREATED = 3,
    G_FILE_MONITOR_EVENT_ATTRIBUTE_CHANGED = 4,
    G_FILE_MONITOR_EVENT_PRE_UNMOUNT = 5,
    G_FILE_MONITOR_EVENT_UNMOUNTED = 6,
    G_FILE_MONITOR_EVENT_MOVED = 7,
    G_FILE_MONITOR_EVENT_RENAMED = 8,
    G_FILE_MONITOR_EVENT_MOVED_IN = 9,
    G_FILE_MONITOR_EVENT_MOVED_OUT = 10,
    TGFileMonitorEventMaxValue = $7FFFFFFF
  );

  TGFileType = (
    TGFileTypeMinValue = -$7FFFFFFF,
    G_FILE_TYPE_UNKNOWN = 0,
    G_FILE_TYPE_REGULAR = 1,
    G_FILE_TYPE_DIRECTORY = 2,
    G_FILE_TYPE_SYMBOLIC_LINK = 3,
    G_FILE_TYPE_SPECIAL = 4,
    G_FILE_TYPE_SHORTCUT = 5,
    G_FILE_TYPE_MOUNTABLE = 6,
    TGFileTypeMaxValue = $7FFFFFFF
  );

  { TGioFileMonitor }

  // https://docs.gtk.org/gio/enum.FileMonitorEvent.html
  // https://docs.gtk.org/gio/signal.FileMonitor.changed.html
  // https://github.com/frida/glib/blob/main/gio/tests/testfilemonitor.c
  TGioFileMonitor = class
  strict private const
    Flags =
      G_FILE_MONITOR_WATCH_HARD_LINKS or
      G_FILE_MONITOR_WATCH_MOUNTS;
      //G_FILE_MONITOR_WATCH_MOVES; // since 2.46
  public type
    TCallback = procedure (File1, File2: PGFile; Event: TGFileMonitorEvent) of object;
  strict private
    FCallback: TCallback;
    FCancelable: PGCancellable;
    FChildren: TObjectList;
    FFileOrDir: PGFile;
    FHandle: PGFileMonitor;
    FSubTreeDepth: Integer;

    // https://docs.gtk.org/gio/signal.FileMonitor.changed.html
    class procedure Notify(AHandle: PGFileMonitor; AFile, AOtherFile: PGFile;
      AEvent: TGFileMonitorEvent; AMonitor: TGioFileMonitor); cdecl; static;
    procedure Watch(AFile: PGFile);
    procedure Unwatch(AFile: PGFile);
  public
    constructor Create(ACancelable: PGCancellable;
      AFileOrDir: PGFile; ACallback: TCallback; ASubTreeDepth: Integer);
    destructor Destroy; override;
  end;

function g_file_new_for_path(path: Pgchar): PGFile; cdecl; external libGio2;
function g_file_new_for_commandline_arg(arg: Pgchar): PGFile; cdecl; external libGio2;
function g_file_new_for_uri(uri: Pgchar): PGFile; cdecl; external libGio2;
function g_file_get_path(file_: PGFile): Pgchar; cdecl; external libGio2;

function g_file_info_get_name(info: PGFileInfo): Pgchar; cdecl; external libGio2;
function g_file_info_get_icon(info: PGFileInfo): PGIcon; cdecl; external libGio2;
function g_file_info_get_attribute_as_string(info: PGFileInfo; attribute: Pgchar): Pgchar; cdecl; external libGio2;
function g_file_info_get_file_type(info: PGFileInfo): TGFileType; cdecl; external libGio2;

function g_file_query_file_type(File_: PGFile; flags: TGFileQueryInfoFlags;
  cancellable: PGCancellable): TGFileType; cdecl; external libGio2;
function g_file_query_info(file_: PGFile; attributes: Pgchar; flags: LongWord;
  cancellable: PGCancellable; error: PPGError): PGFileInfo; cdecl; external libGio2;
function g_file_enumerate_children(file_: PGFile; attributes: Pgchar;
  flags: LongWord; cancellable: PGCancellable;
  error: PPGError): PGFileEnumerator; cdecl; external libGio2;
function g_file_enumerator_close(enumerator: PGFileEnumerator;
  cancellable: PGCancellable; error: PPGError): gboolean; cdecl; external libGio2;
function g_file_enumerator_next_file(enumerator: PGFileEnumerator;
  cancellable: PGCancellable; error: PPGError): PGFileInfo; cdecl; external libGio2;

function g_file_equal(a, b: PGFile): gboolean; cdecl; external libGio2;
function g_file_is_dir(file_: PGFile; cancelable: PGCancellable = nil): Boolean;
function g_file_get_child(file_: PGFile; name: Pgchar): PGFile; cdecl; external libGio2;
function g_file_get_parent(file_: PGFile): PGFile; cdecl; external libGio2;
function g_file_make_directory_with_parents(file_: PGFile;
  cancellable: PGCancellable; error: PPGError): gboolean; cdecl; external libGio2;
function g_file_move(source: PGFile; destination: PGFile; flags: LongWord;
  cancellable: PGCancellable; progress_callback: TGFileProgressCallback;
  progress_callback_data: gpointer; error: PPGError): gboolean; cdecl; external libGio2;
function g_file_trash(file_: PGFile; cancellable: PGCancellable;
  error: PPGError): gboolean; cdecl; external libGio2;

function g_file_monitor(file_: PGFile; flags: TGFileMonitorFlags;
  cancellable: PGCancellable; error: PPGError): PGFileMonitor; cdecl; external libGio2;
function g_file_monitor_directory(file_: PGFile; flags: TGFileMonitorFlags;
  cancellable: PGCancellable; error: PPGError): PGFileMonitor; cdecl; external libGio2;
function g_file_monitor_file(file_: PGFile; flags: TGFileMonitorFlags;
  cancellable: PGCancellable; error: PPGError): PGFileMonitor; cdecl; external libGio2;
function g_file_monitor_cancel(monitor: PGFileMonitor): gboolean; cdecl; external libGio2;

procedure g_cancellable_cancel(cancellable: PGCancellable); cdecl; external libGio2;
function g_cancellable_is_cancelled(cancellable: PGCancellable): gboolean; cdecl; external libGio2;
function g_cancellable_new: PGCancellable; cdecl; external libGio2;

function g_variant_builder_new(type_: PGVariantType): PGVariantBuilder; cdecl; external gobjectlib;
procedure g_variant_builder_add(builder: PGVariantBuilder; format_string: Pgchar; args: array of const); cdecl; external gobjectlib;
procedure g_variant_builder_add_pair(builder: PGVariantBuilder; const key: string; value: PGVariant); overload;
function g_variant_builder_end(builder: PGVariantBuilder): PGVariant; cdecl; external gobjectlib;
procedure g_variant_builder_unref(builder: PGVariantBuilder); cdecl; external gobjectlib;
function g_variant_equal(one, two: PGVariant): gboolean; cdecl; external gobjectlib;
function g_variant_new(fmt: Pgchar; args: array of const): PGVariant; cdecl; external gobjectlib;
function g_variant_new_boolean(value: gboolean): PGVariant; cdecl; external gobjectlib;
function g_variant_new_double(value: gdouble): PGVariant; cdecl; external gobjectlib;
function g_variant_new_int32(value: gint32): PGVariant; cdecl; external gobjectlib;
function g_variant_new_int64(value: gint64): PGVariant; cdecl; external gobjectlib;
function g_variant_new_string(string_: Pgchar): PGVariant; cdecl; external gobjectlib;
function g_variant_new_string_(const string_: string): PGVariant; cdecl;
function g_variant_new_string_array(const strings: TStringDynArray): PGVariant;
function g_variant_new_strv(strv: PPgchar; length: gssize): PGVariant; cdecl; external gobjectlib;
function g_variant_new_tuple(children: PPGVariant; n_children: gsize): PGVariant; cdecl; external gobjectlib;
procedure g_variant_get(value: PGVariant; format_string: Pgchar; args: array of const); cdecl; external gobjectlib;
function g_variant_get_boolean(value: PGVariant): gboolean; cdecl; external gobjectlib;
function g_variant_get_child_value(value: PGVariant; index_: gsize): PGVariant; cdecl; external gobjectlib;
function g_variant_get_double(value: PGVariant): gdouble; cdecl; external gobjectlib;
function g_variant_get_type_string(value: PGVariant): Pgchar; cdecl; external gobjectlib;
function g_variant_get_int32(value: PGVariant): guint32; cdecl; external gobjectlib;
function g_variant_get_int64(value: PGVariant): guint32; cdecl; external gobjectlib;
function g_variant_get_uint32(value: PGVariant): guint32; cdecl; external gobjectlib;
function g_variant_get_uint64(value: PGVariant): guint32; cdecl; external gobjectlib;
function g_variant_get_variant(value: PGVariant): PGVariant; cdecl; external gobjectlib;
function g_variant_type_new(type_string: Pgchar): PGVariantType; cdecl; external gobjectlib;
procedure g_variant_type_free(type_: PGVariantType); cdecl; external gobjectlib;
procedure g_variant_replace(var ATarget: PGVariant; ANewValue: PGVariant);
procedure g_variant_unref(value: PGVariant); cdecl; external gobjectlib;

function g_bus_own_name(bus_type: gint32; name: Pgchar;
  flags: TGBusNameOwnerFlags; bus_acquired_handler: TGBusNameCallback;
  name_acquired_handler: TGBusNameCallback; name_lost_handler: TGBusNameCallback;
  user_data: gpointer; user_data_free_func: TGDestroyNotify): guint; cdecl; external libGio2;
procedure g_bus_unown_name(owner_id: guint); cdecl; external libGio2;
function g_dbus_connection_emit_signal(connection: PGDBusConnection;
  destination_bus_name, object_path, interface_name, signal_name: Pgchar;
  parameters: PGVariant; error: PPGError): gboolean; cdecl; external libGio2;
function g_dbus_connection_register_object(connection: PGDBusConnection;
  object_path: Pgchar; interface_info: PGDBusInterfaceInfo; vtable: PGDBusInterfaceVTable;
  user_data: gpointer; user_data_free_func: TGDestroyNotify; error: PPGError): guint; cdecl; external libGio2;
function g_dbus_error_quark: TGQuark; cdecl; external libGio2;
procedure g_dbus_method_invocation_return_error(
  invocation: PGDBusMethodInvocation; domain: TGQuark; code: gint; format: Pgchar; args: array of const); cdecl; external libGio2;
procedure g_dbus_method_invocation_return_value(
  invocation: PGDBusMethodInvocation; parameters: PGVariant); cdecl; external libGio2;
procedure g_dbus_node_info_unref(info: PGDBusNodeInfo); cdecl; external libGio2;
function g_dbus_node_info_new_for_xml(
  xml_data: Pgchar; error: PPGError): PGDBusNodeInfo; cdecl; external libGio2;
function g_dbus_proxy_new_for_bus_sync(bus_type: gint32; flags: gint32;
  info: PGDBusInterfaceInfo; name: Pgchar; object_path: Pgchar;
  interface_name: Pgchar; cancellable: PGCancellable; error: PPGError): PGDBusProxy; cdecl; external libGio2;
function g_dbus_proxy_call_sync(proxy: PGDBusProxy; method_name: Pgchar;
  parameters: PGVariant; flags: gint32{TGDBusCallFlags}; timeout_msec: gint;
  cancellable: PGCancellable; error: PPGError): PGVariant; cdecl; external libGio2;

function g_unix_mount_monitor_get: PGUnixMountMonitor; cdecl; external libGio2;
function g_unix_mount_for(file_path: Pgchar; time_read: Pguint64): PGUnixMountEntry; cdecl; external libGio2;
function g_unix_mount_get_device_path(mount_entry: PGUnixMountEntry): Pgchar; cdecl; external libGio2;
function g_unix_mount_get_fs_type(mount_entry: PGUnixMountEntry): Pgchar; cdecl; external libGio2;
function g_unix_mount_get_mount_path(mount_entry: PGUnixMountEntry): Pgchar; cdecl; external libGio2;
function g_unix_mount_get_options(mount_entry: PGUnixMountEntry): Pgchar; cdecl; external libGio2;
function g_unix_mount_get_root_path(mount_entry: PGUnixMountEntry): Pgchar; cdecl; external libGio2;
function g_unix_mount_guess_can_eject(mount_entry: PGUnixMountEntry): gboolean; cdecl; external libGio2;
function g_unix_mount_guess_icon(mount_entry: PGUnixMountEntry): PGIcon; cdecl; external libGio2;
function g_unix_mount_guess_name(mount_entry: PGUnixMountEntry): Pgchar; cdecl; external libGio2;
function g_unix_mount_guess_should_display(mount_entry: PGUnixMountEntry): gboolean; cdecl; external libGio2;
function g_unix_mount_guess_symbolic_icon(mount_entry: PGUnixMountEntry): PGIcon; cdecl; external libGio2;
function g_unix_mount_is_readonly(mount_entry: PGUnixMountEntry): gboolean; cdecl; external libGio2;
function g_unix_mount_is_system_internal(mount_entry: PGUnixMountEntry): gboolean; cdecl; external libGio2;
function g_unix_mounts_changed_since(time: guint64): gboolean; cdecl; external libGio2;
function g_unix_mounts_get(time_read: Pguint64): PGList; cdecl; external libGio2;

function gioErrorToString(Error: PGError): string;
function gioTrash(const FileOrFolder: string; out ErrorText: string): HRESULT;
function gioUntrash(const FileOrFolder: string; out ErrorText: string): HRESULT;
implementation

uses
  SysUtils,
  // ACL
  ACL.Utils.Common,
  ACL.Utils.Strings;

procedure g_variant_builder_add_pair(
  builder: PGVariantBuilder; const key: string; value: PGVariant); overload;
begin
  g_variant_builder_add(builder, '{sv}', [Pgchar(key), value]);
end;

function g_variant_new_string_(const string_: string): PGVariant; cdecl;
begin
  Result := g_variant_new('s', [Pgchar(string_)]);
end;

function g_variant_new_string_array(const strings: TStringDynArray): PGVariant;
var
  LBuilder: PGVariantBuilder;
  LType: PGVariantType;
  I: Integer;
begin
  LType := g_variant_type_new('as');
  LBuilder := g_variant_builder_new(LType);
  for I := Low(strings) to High(strings) do
    g_variant_builder_add(LBuilder, 's', [pgchar(strings[I])]);
  Result := g_variant_builder_end(LBuilder);
  g_variant_builder_unref(LBuilder);
  g_variant_type_free(LType);
end;

procedure g_variant_replace(var ATarget: PGVariant; ANewValue: PGVariant);
begin
  if ATarget <> nil then
    g_variant_unref(ATarget);
  ATarget := ANewValue;
end;

function gioDecodeFileUri(Uri: Pgchar): string;
var
  B: TACLStringBuilder;
begin
  if Uri = nil then Exit('');

  B := TACLStringBuilder.Get(256);
  try
    while Uri^ <> #0 do
    begin
      if Uri^ = '\' then
      begin
        Inc(Uri);
        if Uri^ = 'x' then
        begin
          B.Append(Char(TACLHexcode.Decode((Uri + 1)^, (Uri + 2)^)));
          Inc(Uri, 3);
          Continue;
        end;
        B.Append('\');
      end;
      B.Append(Uri^);
      Inc(Uri);
    end;
    Result := B.ToString;
  finally
    B.Release;
  end;
end;

function g_file_is_dir(file_: PGFile; cancelable: PGCancellable): Boolean;
begin
  Result := g_file_query_file_type(file_, 0, cancelable) = G_FILE_TYPE_DIRECTORY;
end;

function gioErrorToString(Error: PGError): string;
begin
  if Error = nil then
    Exit('Unspecified error');
  if Error^.message <> nil then
    Result := Error^.message + ' (' + IntToStr(Error^.code) + ')'
  else
    Result := 'Error ' + IntToStr(Error^.code);
end;

function gioTrash(const FileOrFolder: string; out ErrorText: string): HRESULT;
var
  LFile: PGFile;
  LError: PGError;
begin
  Result := E_INVALIDARG;
  try
    ErrorText := '';
    LError := nil;
    LFile := g_file_new_for_path(PChar(FileOrFolder));
    if LFile <> nil then
    try
      if g_file_trash(LFile, nil, @LError) then
        Result := S_OK
      else
      begin
        ErrorText := gioErrorToString(LError);
        Result := E_FAIL;
      end;
    finally
      g_clear_error(@LError);
      g_object_unref(LFile);
    end;
  except
    Result := E_UNEXPECTED;
  end;
end;

function gioUntrash(const FileOrFolder: string; out ErrorText: string): HRESULT;
var
  LFile: PGFile;
  LFileInfo: PGFileInfo;
  LFileOriginal: PGFile;
  LFileOriginalPath: string;
  LFileOriginalParent: PGFile;
  LEnumerator: PGFileEnumerator;
  LError: PGError;
  LTrash: PGFile;
  LPath: Pgchar;
begin
  ErrorText := '';
  Result := E_NOTIMPL;
  try
    LError := nil;
    LTrash := g_file_new_for_uri('trash:');
    if LTrash <> nil then
    try
      LEnumerator := g_file_enumerate_children(LTrash,
        'standard::name,trash::orig-path', 0, nil, @LError);
      if LEnumerator <> nil then
      try
        Result := E_INVALIDARG;
        repeat
          LFileInfo := g_file_enumerator_next_file(LEnumerator, nil, @LError);
          if LFileInfo <> nil then
          try
            LPath := g_file_info_get_attribute_as_string(LFileInfo, 'trash::orig-path');
            if LPath = nil then Continue;
            LFileOriginalPath := gioDecodeFileUri(LPath);
            g_free(LPath);

            if acSameText(LFileOriginalPath, FileOrFolder) then
            begin
              LFileOriginal := g_file_new_for_commandline_arg(PChar(LFileOriginalPath));
              try
                LFileOriginalParent := g_file_get_parent(LFileOriginal);
                if LFileOriginalParent <> nil then
                begin
                  g_file_make_directory_with_parents(LFileOriginalParent, nil, @LError);
                  g_object_unref(LFileOriginalParent);
                  g_clear_error(@LError);
                end;
                LFile := g_file_get_child(LTrash, g_file_info_get_name(LFileInfo));
                try
                  if g_file_move(LFile, LFileOriginal, G_FILE_COPY_OVERWRITE, nil, nil, nil, @LError) then
                    Result := S_OK
                  else
                    Result := E_FAIL;
                finally
                  g_object_unref(LFile);
                end;
              finally
                g_object_unref(LFileOriginal);
              end;
              Break;
            end;
          finally
            g_object_unref(LFileInfo);
          end;
        until False;
      finally
        g_file_enumerator_close(LEnumerator, nil, @LError);
      end;
    finally
      ErrorText := gioErrorToString(LError);
      g_clear_error(@LError);
      g_object_unref(LTrash);
    end;
  except
    Result := E_UNEXPECTED;
  end;
end;

{ TGioFileMonitor }

constructor TGioFileMonitor.Create(ACancelable: PGCancellable;
  AFileOrDir: PGFile; ACallback: TCallback; ASubTreeDepth: Integer);
var
  LError: PGError;
  LEnumerator: PGFileEnumerator;
  LInfo: PGFileInfo;
begin
  FCallback := ACallback;
  FFileOrDir := AFileOrDir;
  FCancelable := ACancelable;
  FSubTreeDepth := ASubTreeDepth;

  FHandle := g_file_monitor(FFileOrDir, Flags, ACancelable, nil);
  if FHandle <> nil then
  begin
    g_signal_connect(FHandle, 'changed', @Notify, Self);
    if (FSubTreeDepth > 0) and g_file_is_dir(FFileOrDir, FCancelable) then
    begin
      LError := nil;
      LEnumerator := g_file_enumerate_children(FFileOrDir, 'standard::name,', 0, FCancelable, @LError);
      if LEnumerator <> nil then
      try
        while True do
        begin
          LInfo := g_file_enumerator_next_file(LEnumerator, FCancelable, @LError);
          if LInfo = nil then
            Break;
          if g_file_info_get_file_type(LInfo) = G_FILE_TYPE_DIRECTORY then
            Watch(g_file_get_child(FFileOrDir, g_file_info_get_name(LInfo)));
        end;
      finally
        g_file_enumerator_close(LEnumerator, FCancelable, @LError);
        g_clear_error(@LError);
      end;
    end;
  end;
end;

destructor TGioFileMonitor.Destroy;
begin
  FreeAndNil(FChildren);
  if FHandle <> nil then
    g_file_monitor_cancel(FHandle);
  g_object_unref(FHandle);
  g_object_unref(FFileOrDir);
  inherited Destroy;
end;

class procedure TGioFileMonitor.Notify(
  AHandle: PGFileMonitor; AFile, AOtherFile: PGFile;
  AEvent: TGFileMonitorEvent; AMonitor: TGioFileMonitor); cdecl;

  procedure AddChildDir(AFileOrDir: PGFile);
  begin
    if (AMonitor.FSubTreeDepth > 0) and g_file_is_dir(AFileOrDir) then
      AMonitor.Watch(g_object_ref(AFileOrDir));
  end;

begin
  case AEvent of // https://docs.gtk.org/gio/enum.FileMonitorEvent.html
    G_FILE_MONITOR_EVENT_CREATED,
    G_FILE_MONITOR_EVENT_MOVED_IN: // req. G_FILE_MONITOR_WATCH_MOVES
      AddChildDir(AFile);
    G_FILE_MONITOR_EVENT_DELETED,
    G_FILE_MONITOR_EVENT_MOVED_OUT,// req. G_FILE_MONITOR_WATCH_MOVES
    G_FILE_MONITOR_EVENT_UNMOUNTED:
      AMonitor.Unwatch(AFile);
    //G_FILE_MONITOR_EVENT_MOVED, // req. G_FILE_MONITOR_SEND_MOVED (deprecated)
    G_FILE_MONITOR_EVENT_RENAMED:  // req. G_FILE_MONITOR_WATCH_MOVES
      begin
        AMonitor.Unwatch(AFile);
        AddChildDir(AOtherFile);
      end;
  else;
  end;
  if Assigned(AMonitor.FCallback) then
    AMonitor.FCallback(AFile, AOtherFile, AEvent);
end;

procedure TGioFileMonitor.Watch(AFile: PGFile);
begin
  if FChildren = nil then
  begin
    FChildren := TObjectList.Create(True);
    FChildren.Capacity := 4;
  end;
  FChildren.Add(TGioFileMonitor.Create(FCancelable, AFile, FCallback, FSubTreeDepth - 1));
end;

procedure TGioFileMonitor.Unwatch(AFile: PGFile);
var
  LMon: TGioFileMonitor;
  I: Integer;
begin
  if FChildren <> nil then
    for I := FChildren.Count - 1 downto 0 do
    begin
      LMon := FChildren.List[I];
      if g_file_equal(AFile, LMon.FFileOrDir) then
        FChildren.Delete(I);
    end;
end;

end.
