{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*          Windows Dialogs Wrappes          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Dialogs.Impl.Windows;

{$I ACL.Config.inc}

{$IFNDEF MSWINDOWS}
  {$MESSAGE FATAL 'Windows platform is required'}
{$ENDIF}

interface

uses
  Winapi.ActiveX,
  Winapi.CommDlg,
  Winapi.Messages,
  Winapi.ShlObj,
  Winapi.Windows,
  // System
  System.Classes,
  System.Math,
  System.SysUtils,
  System.Types,
  // VCL
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  // ACL
  ACL.Classes.StringList,
  ACL.UI.Dialogs,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

type

  { TACLFileDialogOldImpl }

  TACLFileDialogOldImpl = class(TACLFileDialogImpl)
  strict private
    FStruct: TOpenFilenameW;
    FTempBuffer: PWideChar;
    FTempBufferSize: Cardinal;
    FTempFilter: UnicodeString;
    FTempInitialPath: string;

    class function DialogHook(Wnd: HWND; Msg: UINT;
      WParam: WPARAM; LParam: LPARAM): UINT_PTR; stdcall; static;
  protected
    function AllocFilterStr(const S: UnicodeString): UnicodeString;
    procedure GetFileNames(AFileList: TACLStringList);
    procedure PrepareConst(var AStruct: TOpenFilenameW);
    procedure PrepareFlags(var AStruct: TOpenFilenameW);
  public
    constructor Create(AParent: HWND;
      ADialog: TACLFileDialog; ASaveDialog: Boolean); override;
    destructor Destroy; override;
    function Execute: Boolean; override;
  end;

  { TACLFileDialogVistaImpl }

  TACLFileDialogVistaImpl = class(TACLFileDialogImpl, IFileDialogEvents)
  strict private
    FFileDialog: IFileDialog;
  protected
    FExts: UnicodeString;
    FFilter: TStringDynArray;

    function GetItemName(const AItem: IShellItem): UnicodeString;
    procedure Initialize; virtual;
    procedure InitializeFilter; virtual;
    procedure QuerySeletectedFiles(AFileList: TACLStringList);
    // IFileDialogEvents
    function OnFileOk(const pfd: IFileDialog): HRESULT; virtual; stdcall;
    function OnFolderChange(const pfd: IFileDialog): HRESULT; virtual; stdcall;
    function OnFolderChanging(const pfd: IFileDialog;
      const psiFolder: IShellItem): HRESULT; virtual; stdcall;
    function OnOverwrite(const pfd: IFileDialog;
      const psi: IShellItem; out pResponse: Cardinal): HRESULT; virtual; stdcall;
    function OnSelectionChange(const pfd: IFileDialog): HRESULT; virtual; stdcall;
    function OnShareViolation(const pfd: IFileDialog;
      const psi: IShellItem; out pResponse: Cardinal): HRESULT; virtual; stdcall;
    function OnTypeChange(const pfd: IFileDialog): HRESULT; virtual; stdcall;
    //# Properties
    property FileDialog: IFileDialog read FFileDialog;
  public
    constructor Create(AParent: HWND;
      ADialog: TACLFileDialog; ASaveDialog: Boolean); override;
    destructor Destroy; override;
    function Execute: Boolean; override;
  end;

  { TACLExceptionMessageDialog }

  // Provides per-monitor dpi support for Exception Messages
  TACLExceptionMessageDialog = class
  protected
    class procedure ShowException(E: Exception);
  public
    class destructor Destroy;
    class procedure Register;
  end;

  { TACLMessageTaskDialog }

  // Provides per-monitor dpi support
  TACLMessageTaskDialog = class(TTaskDialog)
  strict private const
    IconMap: array[TMsgDlgType] of TTaskDialogIcon = (
      tdiWarning, tdiError, tdiInformation, tdiInformation, tdiNone
    );
    ModalResults: array[TMsgDlgBtn] of Integer = (
      mrYes, mrNo, mrOk, mrCancel, mrAbort, mrRetry, mrIgnore,
      mrAll, mrNoToAll, mrYesToAll, -1, mrClose
    );
  strict private type
    TMsgDlgBtns = array of TMsgDlgBtn;
  strict private
    function FlagsToButtons(AFlags: Integer): TMsgDlgBtns;
    function FlagsToDefaultButton(AFlags: Integer; AButtons: TMsgDlgBtns): TMsgDlgBtn;
    function FlagsToDialogType(AFlags: Integer): TMsgDlgType;
  public
    constructor Create(const AMessage, ACaption: string; AFlags: Integer); reintroduce;
  end;

implementation

type
  TACLFileDialogAccess = class(TACLFileDialog);

{ TACLFileDialogOldImpl }

constructor TACLFileDialogOldImpl.Create(
  AParent: HWND; ADialog: TACLFileDialog; ASaveDialog: Boolean);
begin
  inherited Create(AParent, ADialog, ASaveDialog);
  FTempInitialPath := TACLFileDialogAccess(ADialog).GetActualInitialDir;
  FTempFilter := AllocFilterStr(ADialog.Filter);
  FTempBufferSize := MAXWORD;
  FTempBuffer := AllocMem(FTempBufferSize);
  ZeroMemory(@FStruct, SizeOf(FStruct));
  FStruct.FlagsEx := 0;
  FStruct.hInstance := HINSTANCE;
  FStruct.hWndOwner := ParentWnd;
  FStruct.lpfnHook := DialogHook;
  FStruct.lpstrFilter := PWideChar(FTempFilter);
  FStruct.lpstrInitialDir := PWideChar(FTempInitialPath);
  FStruct.lpstrTitle := PWideChar(ADialog.Title);
  FStruct.lStructSize := SizeOf(TOpenFilenameW);
  FStruct.nFilterIndex := ADialog.FilterIndex;
  if FDefaultExts <> '' then
    FStruct.lpstrDefExt := PWideChar(FDefaultExts);
  PrepareFlags(FStruct);
  PrepareConst(FStruct);
end;

destructor TACLFileDialogOldImpl.Destroy;
begin
  FreeMemAndNil(Pointer(FTempBuffer));
  inherited Destroy;
end;

function TACLFileDialogOldImpl.Execute: Boolean;
begin
  if SaveDialog then
    Result := GetSaveFileNameW(FStruct)
  else
    Result := GetOpenFileNameW(FStruct);

  if Result then
  begin
    GetFileNames(Dialog.Files);
    Dialog.FilterIndex := FStruct.nFilterIndex;
  end;
end;

function TACLFileDialogOldImpl.AllocFilterStr(const S: string): string;
var
  P: PWideChar;
begin
  Result := '';
  if S <> '' then
  begin
    Result := S + #0;  // double null terminators
    P := acStrScan(PWideChar(Result), '|');
    while P <> nil do
    begin
      P^ := #0;
      Inc(P);
      P := acStrScan(P, '|');
    end;
  end;
end;

procedure TACLFileDialogOldImpl.PrepareConst(var AStruct: TOpenFilenameW);
const
  MultiSelectBufferSize = High(Word) - 16;
begin
//  if WindowsVersion in [wvWinME, wvWin2K] then
//    Dec(AStruct.lStructSize, SizeOf(DWORD) shl 1 + SizeOf(Pointer));
  AStruct.nMaxFile := FTempBufferSize - 2; // two zeros in end
  ZeroMemory(FTempBuffer, FTempBufferSize);
  AStruct.lpstrFile := FTempBuffer;
  acStrLCopy(FTempBuffer, Dialog.FileName, Length(Dialog.Filename));
end;

procedure TACLFileDialogOldImpl.PrepareFlags(var AStruct: TOpenFilenameW);
const
  OpenOptions: array [TACLFileDialogOption] of DWORD = (
    OFN_OVERWRITEPROMPT, OFN_HIDEREADONLY, OFN_ALLOWMULTISELECT,
    OFN_PATHMUSTEXIST, OFN_FILEMUSTEXIST, OFN_ENABLESIZING,
    OFN_FORCESHOWHIDDEN, 0
  );
var
  Option: TACLFileDialogOption;
begin
  AStruct.Flags := OFN_ENABLEHOOK;
  for Option := Low(TACLFileDialogOption) to High(TACLFileDialogOption) do
  begin
    if Option in Dialog.Options then
      AStruct.Flags := AStruct.Flags or OpenOptions[Option];
  end;
  AStruct.Flags := AStruct.Flags xor OFN_EXPLORER;
end;

procedure TACLFileDialogOldImpl.GetFileNames(AFileList: TACLStringList);

  function ExtractFileName(P: PWideChar; var S: string): PWideChar;
  begin
    Result := acStrScan(P, #0);
    if Result = nil then
    begin
      S := P;
      Result := StrEnd(P);
    end
    else
    begin
      SetString(S, P, Result - P);
      Inc(Result);
    end;
  end;

  procedure ExtractFileNames(P: PWideChar);
  var
    ADirName, AFileName: string;
  begin
    P := ExtractFileName(P, ADirName);
    P := ExtractFileName(P, AFileName);
    if AFileName = '' then
      AFileList.Add(ADirName, nil)
    else
    begin
      ADirName := acIncludeTrailingPathDelimiter(ADirName);
      repeat
        if (AFileName[1] <> '\') and ((Length(AFileName) <= 3) or
           (AFileName[2] <> ':') or  (AFileName[3] <> '\'))
        then
          AFileName := ADirName + AFileName;
        AFileList.Add(AFileName, nil);
        P := ExtractFileName(P, AFileName);
      until AFileName = '';
    end;
  end;

begin
  if not (ofAllowMultiSelect in Dialog.Options) or SaveDialog then
    AFileList.Add(FTempBuffer)
  else
    ExtractFileNames(FTempBuffer);
end;

class function TACLFileDialogOldImpl.DialogHook(Wnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): UINT_PTR;

  procedure CenterWindow(Wnd: HWnd);
  var
    Monitor: TMonitor;
    Rect: TRect;
  begin
    GetWindowRect(Wnd, Rect);
    if Application.MainForm = nil then
      Monitor := Screen.Monitors[0]
    else
      if Assigned(Screen.ActiveForm) then
        Monitor := Screen.ActiveForm.Monitor
      else
        Monitor := Application.MainForm.Monitor;

    SetWindowPos(Wnd, HWND_TOP,
      Monitor.Left + ((Monitor.Width - Rect.Right + Rect.Left) div 2),
      Monitor.Top + ((Monitor.Height - Rect.Bottom + Rect.Top) div 3),
      0, 0, SWP_NOSIZE);
  end;

var
  AParent: HWND;
begin
  if Msg = WM_INITDIALOG then
    CenterWindow(Wnd)
  else
    if (Msg = WM_NOTIFY) and (POFNotify(LParam)^.hdr.code = CDN_INITDONE) then
    begin
      AParent := GetWindowLong(Wnd, GWL_HWNDPARENT);
      CenterWindow(AParent);
      SetForegroundWindow(AParent);
    end;

  Result := DefWindowProc(Wnd, Msg, WParam, LParam);
end;

{ TACLFileDialogVistaImpl }

constructor TACLFileDialogVistaImpl.Create(AParent: HWND; ADialog: TACLFileDialog; ASaveDialog: Boolean);
begin
  inherited Create(AParent, ADialog, ASaveDialog);
  if ASaveDialog then
    CoCreateInstance(CLSID_FileSaveDialog, nil, CLSCTX_INPROC_SERVER, IFileSaveDialog, FFileDialog)
  else
    CoCreateInstance(CLSID_FileOpenDialog, nil, CLSCTX_INPROC_SERVER, IFileOpenDialog, FFileDialog);
end;

destructor TACLFileDialogVistaImpl.Destroy;
begin
  FFileDialog := nil;
  CoFreeUnusedLibraries;
  inherited;
end;

function TACLFileDialogVistaImpl.Execute: Boolean;
var
  AFilterIndex: Cardinal;
begin
  Initialize;
  InitializeFilter;
  Result := Succeeded(FileDialog.Show(ParentWnd));
  if Result then
  begin
    QuerySeletectedFiles(Dialog.Files);
    if Succeeded(FileDialog.GetFileTypeIndex(AFilterIndex)) then
      Dialog.FilterIndex := AFilterIndex;
  end;
end;

procedure TACLFileDialogVistaImpl.Initialize;
const
  DialogOptions: array[TACLFileDialogOption] of DWORD = (
    FOS_OVERWRITEPROMPT, 0, FOS_ALLOWMULTISELECT, FOS_PATHMUSTEXIST,
    FOS_FILEMUSTEXIST, 0, FOS_FORCESHOWHIDDEN, 0
  );
var
  ACookie: DWORD;
  AFlags: DWORD;
  AOption: TACLFileDialogOption;
  ASelectedPath: UnicodeString;
  AShellItem: IShellItem;
begin
  ASelectedPath := TACLFileDialogAccess(Dialog).GetActualInitialDir;
  if Dialog.Title <> '' then
    FFileDialog.SetTitle(PWideChar(Dialog.Title));
  if FDefaultExts <> '' then
    FFileDialog.SetDefaultExtension(PWideChar(FDefaultExts));
  if Dialog.FileName <> '' then
  begin
    FFileDialog.SetFileName(PWideChar(acExtractFileName(Dialog.FileName)));
    if ASelectedPath = '' then
      ASelectedPath := acExtractFilePath(Dialog.FileName);
  end;
  if ASelectedPath <> '' then
  begin
    if Succeeded(SHCreateItemFromParsingName(PWideChar(ASelectedPath),
      nil, StringToGUID(SID_IShellItem), AShellItem))
    then
      FFileDialog.SetFolder(AShellItem);
  end;

  AFlags := 0;
  for AOption := Low(TACLFileDialogOption) to High(TACLFileDialogOption) do
  begin
    if AOption in Dialog.Options then
      AFlags := AFlags or DialogOptions[AOption];
  end;
  FFileDialog.SetOptions(AFlags);

  FFileDialog.Advise(Self, ACookie);
end;

procedure TACLFileDialogVistaImpl.InitializeFilter;
var
  AFilterStr: TComdlgFilterSpecArray;
  I: Integer;
begin
  acExplodeString(Dialog.Filter, '|', FFilter);
  SetLength(AFilterStr, Length(FFilter) div 2);
  if Length(AFilterStr) > 0 then
  begin
    for I := 0 to Length(AFilterStr) - 1 do
    begin
      AFilterStr[I].pszName := PWideChar(FFilter[2 * I]);
      AFilterStr[I].pszSpec := PWideChar(FFilter[2 * I + 1]);
    end;
    FFileDialog.SetFileTypes(Length(AFilterStr), AFilterStr);
    FFileDialog.SetFileTypeIndex(Dialog.FilterIndex);
  end;
end;

procedure TACLFileDialogVistaImpl.QuerySeletectedFiles(AFileList: TACLStringList);

  procedure OpenDialogPopulateSelectedFiles(AFileList: TACLStringList);
  var
    ACount: Integer;
    AEnumerator: IEnumShellItems;
    AItems: IShellItemArray;
    AResult: HRESULT;
    AShellItem: IShellItem;
  begin
    if Succeeded((FFileDialog as IFileOpenDialog).GetResults(AItems)) then
    begin
      if Succeeded(AItems.EnumItems(AEnumerator)) then
      begin
        AResult := AEnumerator.Next(1, AShellItem, @ACount);
        while Succeeded(AResult) and (ACount <> 0) do
        begin
          AFileList.Add(GetItemName(AShellItem));
          AResult := AEnumerator.Next(1, AShellItem, @ACount);
        end;
      end;
    end;
  end;

  procedure SaveDialogPopulateSelectedFileName(AFileList: TACLStringList);
  var
    AItem: IShellItem;
  begin
    if Succeeded((FFileDialog as IFileSaveDialog).GetResult(AItem)) then
      AFileList.Add(GetItemName(AItem));
  end;

begin
  AFileList.Clear;
  if SaveDialog then
    SaveDialogPopulateSelectedFileName(AFileList)
  else
    OpenDialogPopulateSelectedFiles(AFileList);
end;

function TACLFileDialogVistaImpl.OnFileOk(const pfd: IFileDialog): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaImpl.OnFolderChange(const pfd: IFileDialog): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaImpl.OnFolderChanging(
  const pfd: IFileDialog; const psiFolder: IShellItem): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaImpl.OnOverwrite(
  const pfd: IFileDialog; const psi: IShellItem; out pResponse: Cardinal): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaImpl.OnSelectionChange(const pfd: IFileDialog): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaImpl.OnShareViolation(
  const pfd: IFileDialog; const psi: IShellItem; out pResponse: Cardinal): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaImpl.OnTypeChange(const pfd: IFileDialog): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaImpl.GetItemName(const AItem: IShellItem): UnicodeString;
var
  AError: HRESULT;
  AName: PWideChar;
begin
  Result := '';
  AError := AItem.GetDisplayName(SIGDN_FILESYSPATH, AName);
  if Failed(AError) then
    AError := AItem.GetDisplayName(SIGDN_NORMALDISPLAY, AName);
  if Succeeded(AError) then
  try
    Result := acSimplifyLongFileName(AName);
  finally
    CoTaskMemFree(AName);
  end;
end;

{ TACLExceptionMessageDialog }

class procedure TACLExceptionMessageDialog.Register;
begin
  ApplicationShowException := ShowException;
end;

class destructor TACLExceptionMessageDialog.Destroy;
begin
  ApplicationShowException := nil;
end;

class procedure TACLExceptionMessageDialog.ShowException(E: Exception);
var
  AMessage: string;
  ASubException: Exception;
  AWndHandle: THandle;
begin
  AMessage := E.Message;
  while True do
  begin
    ASubException := E.GetBaseException;
    if ASubException <> E then
    begin
      E := ASubException;
      if E.Message <> '' then
        AMessage := E.Message;
    end
    else
      Break;
  end;
  AWndHandle := Application.ActiveFormHandle;
  if AWndHandle = 0 then
    AWndHandle := Application.MainFormHandle;
  acMessageBox(AWndHandle, AMessage, Application.Title, MB_OK or MB_ICONSTOP);
end;

{ TACLMessageTaskDialog }

constructor TACLMessageTaskDialog.Create(const AMessage, ACaption: string; AFlags: Integer);
var
  AButton: TTaskDialogBaseButtonItem;
  AButtons: TMsgDlgBtns;
  ADefaultButton: TMsgDlgBtn;
  ADialogType: TMsgDlgType;
  I: Integer;
begin
  inherited Create(nil);

  CommonButtons := [];
  ADialogType := FlagsToDialogType(AFlags);
  MainIcon := IconMap[ADialogType];
  Caption := IfThenW(ACaption, TACLDialogsStrs.MsgDlgCaptions[ADialogType]);
  Text := AMessage;

  AButtons := FlagsToButtons(AFlags);
  ADefaultButton := FlagsToDefaultButton(AFlags, AButtons);
  for I := Low(AButtons) to High(AButtons) do
  begin
    AButton := Buttons.Add;
    AButton.Caption := TACLDialogsStrs.MsgDlgButtons[AButtons[I]];
    AButton.Default := AButtons[I] = ADefaultButton;
    AButton.ModalResult := ModalResults[AButtons[I]];
  end;
end;

function TACLMessageTaskDialog.FlagsToButtons(AFlags: Integer): TMsgDlgBtns;
begin
  if AFlags and MB_RETRYCANCEL = MB_RETRYCANCEL then
    Result := [mbRetry, mbCancel]
  else if AFlags and MB_YESNO = MB_YESNO then
    Result := [mbYes, mbNo]
  else if AFlags and MB_YESNOCANCEL = MB_YESNOCANCEL then
    Result := [mbYes, mbNo, mbCancel]
  else if AFlags and MB_ABORTRETRYIGNORE = MB_ABORTRETRYIGNORE then
    Result := [mbAbort, mbRetry, mbIgnore]
  else if AFlags and MB_OKCANCEL = MB_OKCANCEL then
    Result := [mbOK, mbCancel]
  else
    Result := [mbOK];
end;

function TACLMessageTaskDialog.FlagsToDefaultButton(AFlags: Integer; AButtons: TMsgDlgBtns): TMsgDlgBtn;
const
  Masks: array[0..3] of Integer = (MB_DEFBUTTON1, MB_DEFBUTTON2, MB_DEFBUTTON3, MB_DEFBUTTON4);
var
  I: Integer;
begin
  for I := Min(High(Masks), High(AButtons)) downto 0 do
  begin
    if AFlags and Masks[I] <> 0 then
      Exit(AButtons[I]);
  end;
  Result := AButtons[0];
end;

function TACLMessageTaskDialog.FlagsToDialogType(AFlags: Integer): TMsgDlgType;
const
  Map: array[TMsgDlgType] of Integer = (MB_ICONWARNING, MB_ICONERROR, MB_ICONINFORMATION, MB_ICONQUESTION, 0);
var
  AIndex: TMsgDlgType;
begin
  for AIndex := Low(AIndex) to High(AIndex) do
  begin
    if AFlags and Map[AIndex] = Map[AIndex] then
      Exit(AIndex);
  end;
  Result := mtCustom;
end;

{$IFDEF MSWINDOWS}
initialization
  if IsWinSevenOrLater then
    TACLExceptionMessageDialog.Register;
{$ENDIF}
end.
