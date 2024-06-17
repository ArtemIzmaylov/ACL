////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Wrappers for Gnome IO Library
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Utils.FileSystem.GIO;

{$I ACL.Config.inc}

interface

uses
  glib2,
  gtk2,
  gtk2Def;

const
  libGio2 = 'libgio-2.0.so.0';
  libGtk2 = gtklib;

type
  PGIcon = Pointer;
  PGFile = Pointer;
  PGFileInfo = Pointer;
  PGFileEnumerator = Pointer;
  PGFileMonitor = Pointer;
  PGCancellable = Pointer;
  PGUnixMountMonitor = Pointer;
  PGUnixMountPoint = Pointer;
  PGUnixMountEntry = Pointer;

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
  PPGFileProgressCallback = ^PGFileProgressCallback;
  PGFileProgressCallback = ^TGFileProgressCallback;
  TGFileProgressCallback = procedure(current_num_bytes, total_num_bytes: gint64; user_data: gpointer); cdecl;
  TGFileMonitorFlags = LongWord;

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

//g_file_monitor_file
function g_file_new_for_path(path: Pgchar): PGFile; cdecl; external libGio2;
function g_file_new_for_commandline_arg(arg: Pgchar): PGFile; cdecl; external libGio2;
function g_file_new_for_uri(uri: Pgchar): PGFile; cdecl; external libGio2;

function g_file_info_get_name(info: PGFileInfo): Pgchar; cdecl; external libGio2;
function g_file_info_get_icon(info: PGFileInfo): PGIcon; cdecl; external libGio2;
function g_file_info_get_attribute_as_string(info: PGFileInfo; attribute: Pgchar): Pgchar; cdecl; external libGio2;

function g_file_query_info(file_: PGFile; attributes: Pgchar; flags: LongWord;
  cancellable: PGCancellable; error: PPGError): PGFileInfo; cdecl; external libGio2;
function g_file_enumerate_children(file_: PGFile; attributes: Pgchar;
  flags: LongWord; cancellable: PGCancellable;
  error: PPGError): PGFileEnumerator; cdecl; external libGio2;
function g_file_enumerator_close(enumerator: PGFileEnumerator;
  cancellable: PGCancellable; error: PPGError): gboolean; cdecl; external libGio2;
function g_file_enumerator_next_file(enumerator: PGFileEnumerator;
  cancellable: PGCancellable; error: PPGError): PGFileInfo; cdecl; external libGio2;

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
function gioGetIconFileNameForUri(const FileOrFolder: string; Size: Integer): string;
function gioTrash(const FileOrFolder: string; out ErrorText: string): HRESULT;
function gioUntrash(const FileOrFolder: string; out ErrorText: string): HRESULT;
implementation

uses
  SysUtils,
  // ACL
  ACL.Utils.Common,
  ACL.Utils.Strings;

function gtk_icon_theme_lookup_by_gicon(icon_theme: PGtkIconTheme; icon: PGIcon;
  size: gint; flags: TGtkIconLookupFlags): PGtkIconInfo; cdecl; external libGtk2;

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

function gioErrorToString(Error: PGError): string;
begin
  if Error = nil then
    Exit('Unspecified error');
  if Error^.message <> nil then
    Result := Error^.message + ' (' + IntToStr(Error^.code) + ')'
  else
    Result := 'Error ' + IntToStr(Error^.code);
end;

function gioGetIconFileNameForUri(const FileOrFolder: string; Size: Integer): string;
var
  LError: PGError;
  LFile: PGFile;
  LFileName: Pgchar;
  LFlags: TGtkIconLookupFlags;
  LInfo: PGFileInfo;
  LIcon: PGIcon;
  LIconInfo: PGtkIconInfo;
begin
  Result := '';
  try
    LFile := g_file_new_for_path(PChar(FileOrFolder));
    if LFile <> nil then
    try
      LError := nil;
      LInfo := g_file_query_info(LFile, 'standard::icon', 0, nil, @LError);
      if LError <> nil then
        g_error_free(LError);
      if LInfo <> nil then
      try
        LIcon := g_file_info_get_icon(LInfo);
        if LIcon <> nil then
        begin
          LFlags := [GTK_ICON_LOOKUP_USE_BUILTIN, GTK_ICON_LOOKUP_FORCE_SIZE];
          LIconInfo := gtk_icon_theme_lookup_by_gicon(
             gtk_icon_theme_get_default, LIcon, Size, LFlags);
          if LIconInfo <> nil then
          try
            LFileName := gtk_icon_info_get_filename(LIconInfo);
            if LFileName <> nil then
              Result := LFileName;
          finally
            gtk_icon_info_free(LIconInfo);
          end;
        end;
      finally
        g_object_unref(LInfo);
      end;
    finally
      g_object_unref(LFile);
    end;
  except
    // do nothing
  end;
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

end.
