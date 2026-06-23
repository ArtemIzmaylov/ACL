////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   General Dialogs implementation for Gtk3
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Dialogs.Impl.Gtk3;

{$I ACL.Config.inc}

interface

uses
  Math,
  Types,
  SysUtils,
  System.UITypes,
  // Gtk3
  LazGObject2,
  LazGLib2,
  LazGdk3,
  LazGtk3,
  LCLIntf,
  LCLType,
  Gtk3Int,
  Gtk3Widgets,
  // LCL
  Controls,
  Forms,
  // ACL
  ACL.Graphics,
  ACL.UI.Core.Impl.Gtk3,
  ACL.UI.Dialogs,
  ACL.Utils.Common,
  ACL.Utils.Logger,
  ACL.Utils.Strings;

type

  { TACLFileDialogImpl }

  TACLFileDialogImpl = class(TGtk3Widget)
  strict private
    FModalResult: TACLBoolean;
    class function OnDestroy(Widget: PGtkFileChooser;
      Dlg: TACLFileDialogImpl): GBoolean; cdecl; static;
    class procedure OnNotify(Widget: PGtkFileChooser; Spec: PGParamSpec;
      Dlg: TACLFileDialogImpl); cdecl; static;
    class function OnResponse(Widget: PGtkFileChooser;
      Response: TGtkResponseType; Dlg: TACLFileDialogImpl): GBoolean; cdecl; static;
  protected
    FDialog: TACLFileDialog;
    FSaveDialog: Boolean;
  public
    function CreateWidget(const Params: TCreateParams): PGtkWidget; override;
    procedure FetchSelection;
    procedure InitializeWidget; override;
  public
    constructor Create(ADialog: TACLFileDialog; ASaveDialog: Boolean);
    function Execute(AOwnerWnd: TWndHandle): Boolean; virtual;
  end;

function LoadDialogIcon(AOwnerWnd: TWndHandle; AType: TMsgDlgType; ASize: Integer): TACLDib;
implementation

function LoadDialogIcon(AOwnerWnd: TWndHandle; AType: TMsgDlgType; ASize: Integer): TACLDib;
const
  Map: array[TMsgDlgType] of PChar = (
    'gtk-dialog-warning', 'gtk-dialog-error',
    'gtk-dialog-info', 'gtk-dialog-question', ''
  );
begin
  Result := GtkLoadStockIcon(nil, Map[AType], ASize);
end;

{ TACLFileDialogImpl }

constructor TACLFileDialogImpl.Create(ADialog: TACLFileDialog; ASaveDialog: Boolean);
const
  ActionMap: array[Boolean] of TGtkFileChooserAction = (
    GTK_FILE_CHOOSER_ACTION_OPEN, GTK_FILE_CHOOSER_ACTION_SAVE
  );
  ButtonText: array[Boolean] of pgChar = (GTK_STOCK_OPEN, GTK_STOCK_SAVE);
var
  LDialog: PGtkFileChooser;
  LFilter: PGtkFileFilter;
  LFilterExts: TStringDynArray;
  LParts: TStringDynArray;
  I, J: Integer;
begin
  inherited Create;
  FDialog := ADialog;
  FSaveDialog := ASaveDialog;
  FOwnWidget := True;
  FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  FWidgetType := [wtWidget, wtDialog];
  FWidget := gtk_file_chooser_dialog_new(PgChar(ADialog.Title), nil, ActionMap[ASaveDialog],
    PChar(GTK_STOCK_CANCEL), [GTK_RESPONSE_CANCEL, ButtonText[ASaveDialog], GTK_RESPONSE_OK, nil]);
  LDialog := PGtkFileChooser(FWidget);

  if ASaveDialog then
    gtk_file_chooser_set_do_overwrite_confirmation(LDialog, ofOverwritePrompt in ADialog.Options);
  if ADialog.InitialDir <> '' then
    gtk_file_chooser_set_current_folder(LDialog, Pgchar(ADialog.InitialDir));
  if ASaveDialog then
    gtk_file_chooser_set_current_name(LDialog, Pgchar(ADialog.FileName));
  if (ofAllowMultiSelect in ADialog.Options) and not ASaveDialog then
    gtk_file_chooser_set_select_multiple(LDialog, True);
  if (ofForceShowHidden in ADialog.Options) then
    gtk_file_chooser_set_show_hidden(LDialog, True);
  if ADialog.Filter <> '' then
  begin
    ADialog.FilterIndex := Max(ADialog.FilterIndex, 1); // 0 is "default" (for Windows)
    acSplitString(ADialog.Filter, '|', LParts);
    for I := 0 to (Length(LParts) div 2) - 1 do
    begin
      if acSplitString(LParts[2 * I + 1], ';', LFilterExts, [ssoNonEmpty]) > 0 then
      begin
        LFilter := gtk_file_filter_new;
        gtk_file_filter_set_name(LFilter, Pgchar(LParts[2 * I]));
        gtk_file_chooser_add_filter(LDialog, LFilter);
        for J := Low(LFilterExts) to High(LFilterExts) do
          gtk_file_filter_add_pattern(LFilter, Pgchar(LFilterExts[J]));
        if I + 1 = ADialog.FilterIndex then
          gtk_file_chooser_set_filter(LDialog, LFilter);
      end;
    end;
  end;

  InitializeWidget;
end;

function TACLFileDialogImpl.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  Result := nil;
  raise EInvalidOp.Create('Dialog must be created via constructor');
end;

procedure TACLFileDialogImpl.FetchSelection;
var
  LFile: PGSList;
  LFileName: Pgchar;
  LFiles: PGSList;
begin
  FDialog.FileName := '';
  if (ofAllowMultiSelect in FDialog.Options) and not FSaveDialog then
  begin
    LFiles := gtk_file_chooser_get_filenames(PGtkFileChooser(Widget));
    if LFiles <> nil then
    try
      LFile := LFiles;
      while LFile <> nil do
      begin
        LFileName := Pgchar(LFile^.data);
        if (LFileName <> nil) and (LFileName^ <> #0) then
          FDialog.Files.AddIfAbsent(LFileName);
        LFile := LFile^.next;
      end;
    finally
      g_slist_free(LFiles);
    end;
  end
  else
  begin
    LFileName := gtk_file_chooser_get_filename(PGtkFileChooser(Widget));
    if (LFileName <> nil) and (LFileName^ <> #0) then
      FDialog.Files.Add(LFileName);
  end;
end;

function TACLFileDialogImpl.Execute(AOwnerWnd: TWndHandle): Boolean;
var
  LDialog: PGtkDialog;
begin
  Result := False;
  FModalResult := TACLBoolean.Default;
  LDialog := PGtkDialog(FWidget);
  LDialog^.set_position(GTK_WIN_POS_CENTER);
  LDialog^.set_application(GTK3WidgetSet.Gtk3Application);
  LDialog^.set_modal(True);
  LDialog^.show_all;
  LDialog^.present;
  while FModalResult = TACLBoolean.Default do
    Application.HandleMessage;
  if FModalResult = TACLBoolean.True then
  begin
    FetchSelection;
    Result := FDialog.Files.Count > 0;
  end;
end;

procedure TACLFileDialogImpl.InitializeWidget;
begin
  g_object_set_data(FWidget, 'lclwidget', Self);
  g_signal_connect_data(FWidget, 'destroy', TGCallback(@OnDestroy), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(FWidget, 'response', TGCallback(@OnResponse), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(FWidget, 'notify', TGCallback(@OnNotify), Self, nil, G_CONNECT_DEFAULT);
end;

class function TACLFileDialogImpl.OnDestroy(
  Widget: PGtkFileChooser; Dlg: TACLFileDialogImpl): GBoolean; cdecl;
begin
  if Dlg <> nil then
  begin
    LogEntry(acGeneralLogFileName, 'Dialog', 'OnDestroy');
    Dlg.FModalResult := TACLBoolean.False;
  end;
  Result := True;
end;

class procedure TACLFileDialogImpl.OnNotify(
  Widget: PGtkFileChooser; Spec: PGParamSpec; Dlg: TACLFileDialogImpl); cdecl;
var
  LDialog: TACLFileDialog;
  LFilter: PGtkFileFilter;
  LFilterList: PGSList;
begin
  if Spec^.name = 'filter' then
  begin // filter changed
    LDialog := Dlg.FDialog;
    LFilterList := gtk_file_chooser_list_filters(Widget);
    try
      LFilter := gtk_file_chooser_get_filter(Widget);
      if (LFilter = nil) and (LDialog.Filter <> '') then
      begin
        // Either we don't have filter or gtk reset it.
        // Gtk resets filter if we set both filename and filter but filename
        // does not fit into filter. Gtk comparision has bug - it compares only by
        // mime-type, not by pattern. LCL set all filters by pattern.
        LFilter := g_slist_nth_data(LFilterList, LDialog.FilterIndex - 1);
        gtk_file_chooser_set_filter(Widget, LFilter);
      end
      else
        LDialog.FilterIndex := g_slist_index(LFilterList, Pgpointer(LFilter)) + 1;
    finally
      g_slist_free(LFilterList);
    end;
  end;
end;

class function TACLFileDialogImpl.OnResponse(Widget: PGtkFileChooser;
  Response: TGtkResponseType; Dlg: TACLFileDialogImpl): GBoolean; cdecl;
begin
  if Dlg <> nil then
  begin
    LogEntry(acGeneralLogFileName, 'Dialog', 'OnResponce(%d)', [Ord(Response)]);
    case Response of
      GTK_RESPONSE_YES, GTK_RESPONSE_OK:
        Dlg.FModalResult := TACLBoolean.True;
    else
      Dlg.FModalResult := TACLBoolean.False;
    end;
  end;
  Result := False;
end;

end.
