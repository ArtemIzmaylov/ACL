{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*             Gnome IO Library              *}
{*                                           *}
{*           (c) Artem Izmaylov              *}
{*               2024-2024                   *}
{*              www.aimp.ru                  *}
{*                                           *}
{*********************************************}

unit ACL.Utils.FileSystem.GIO;

{$I ACL.Config.inc} //FPC:OK

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
  PGCancellable = Pointer;

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

function g_file_new_for_path(path: Pgchar): PGFile; cdecl; external libGio2 name 'g_file_new_for_path';
function g_file_info_get_icon(info: PGFileInfo): PGIcon; cdecl; external libGio2 name 'g_file_info_get_icon';
function g_file_query_info(file_: PGFile; attributes: Pgchar; flags: LongWord;
  cancellable: PGCancellable; error: PPGError): PGFileInfo; cdecl; external libGio2 name 'g_file_query_info';
function g_file_trash(file_: PGFile; cancellable: PGCancellable;
  error: PPGError): gboolean; cdecl; external libGio2 name 'g_file_trash';

function gioGetIconFileNameForUri(const Uri: string; Size: Integer): string;
implementation

function gtk_icon_theme_lookup_by_gicon(icon_theme: PGtkIconTheme; icon: PGIcon;
  size: gint; flags: TGtkIconLookupFlags): PGtkIconInfo; cdecl; external libGtk2;

function gioGetIconFileNameForUri(const Uri: string; Size: Integer): string;
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
    LFile := g_file_new_for_path(PChar(Uri));
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

end.
