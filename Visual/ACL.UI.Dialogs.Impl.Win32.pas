////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   General Dialogs (Implementation for Windows)
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Dialogs.Impl.Win32;

{$I ACL.Config.inc}

{$IFNDEF MSWINDOWS}
  {$MESSAGE FATAL 'Windows platform is required'}
{$ENDIF}

interface

uses
  Winapi.ActiveX,
  Winapi.CommDlg,
  Winapi.Messages,
  Winapi.ShellApi,
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
  Vcl.Graphics,

  // ACL
  ACL.Classes.StringList,
  ACL.Graphics,
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
    constructor Create(AOwnedWnd: HWND; ADialog: TACLFileDialog; ASaveDialog: Boolean);
    destructor Destroy; override;
    function Execute: Boolean; override;
  end;

  { TACLFileDialogVistaImpl }

  TACLFileDialogVistaImpl = class(TACLFileDialogImpl, IFileDialogEvents)
  protected
    FExts: UnicodeString;
    FFileDialog: IFileDialog;
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
  public
    destructor Destroy; override;
    function Execute: Boolean; override;
    class function TryCreate(AOwnerWnd: TWndHandle;
      ADialog: TACLFileDialog; ASaveDialog: Boolean): TACLFileDialogImpl;
  end;

function LoadDialogIcon(AOwnerWnd: HWND; AType: TMsgDlgType; ASize: Integer): TACLDib;
implementation

type
  TACLFileDialogAccess = class(TACLFileDialog);

function LoadDialogIcon(AOwnerWnd: HWND; AType: TMsgDlgType; ASize: Integer): TACLDib;

  function ToDib(Icon: HICON): TACLDib;
  var
    LIcon: TIcon;
  begin
    LIcon := TIcon.Create;
    try
      LIcon.Handle := Icon;
      Result := TACLDib.Create(LIcon.Width, LIcon.Height);
      Result.Canvas.Draw(0, 0, LIcon);
    finally
      LIcon.Free;
    end;
  end;

const
  MapOld: array[TMsgDlgType] of PChar = (IDI_EXCLAMATION, IDI_HAND, IDI_ASTERISK, IDI_QUESTION, nil);
  MapNew: array[TMsgDlgType] of Integer = (SIID_WARNING, SIID_ERROR, SIID_INFO, SIID_INFO, 0);
var
  LIconInfo: TSHStockIconInfo;
begin
  if TOSVersion.Check(6, 2) then
  begin
    if MapNew[AType] = 0 then Exit(nil);
    LIconInfo.cbSize := SizeOf(LIconInfo);
    if Succeeded(SHGetStockIconInfo(MapNew[AType], SHGSI_ICON, LIconInfo)) then
      Exit(ToDib(LIconInfo.hIcon));
  end;
  if MapOld[AType] <> nil then
    Result := ToDib(LoadIcon(0, MapOld[AType]))
  else
    Result := nil;
end;

{ TACLFileDialogOldImpl }

constructor TACLFileDialogOldImpl.Create(
  AOwnedWnd: HWND; ADialog: TACLFileDialog; ASaveDialog: Boolean);
begin
  inherited Create(AOwnedWnd, ADialog, ASaveDialog);
  FTempInitialPath := TACLFileDialogAccess(ADialog).GetActualInitialDir;
  FTempFilter := AllocFilterStr(ADialog.Filter);
  FTempBufferSize := MAXWORD;
  FTempBuffer := AllocMem(FTempBufferSize);
  ZeroMemory(@FStruct, SizeOf(FStruct));
  FStruct.FlagsEx := 0;
  FStruct.hInstance := HINSTANCE;
  FStruct.hWndOwner := OwnerWnd;
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
  FreeMemAndNil(FTempBuffer);
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
  Result := Succeeded(FFileDialog.Show(OwnerWnd));
  if Result then
  begin
    QuerySeletectedFiles(Dialog.Files);
    if Succeeded(FFileDialog.GetFileTypeIndex(AFilterIndex)) then
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
  acSplitString(Dialog.Filter, '|', FFilter);
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

class function TACLFileDialogVistaImpl.TryCreate(
  AOwnerWnd: TWndHandle; ADialog: TACLFileDialog; ASaveDialog: Boolean): TACLFileDialogImpl;
var
  LIntf: IFileDialog;
  LResult: HRESULT;
begin
  LIntf := nil;
  if acOSCheckVersion(6, 0) then
  begin
    if ASaveDialog then
      LResult := CoCreateInstance(CLSID_FileSaveDialog, nil, CLSCTX_INPROC_SERVER, IFileSaveDialog, LIntf)
    else
      LResult := CoCreateInstance(CLSID_FileOpenDialog, nil, CLSCTX_INPROC_SERVER, IFileOpenDialog, LIntf);
  end
  else
    LResult := E_NOINTERFACE;

  if (LResult = S_OK) and (LIntf <> nil) then
  begin
    TACLFileDialogVistaImpl(Result) := Create(AOwnerWnd, ADialog, ASaveDialog);
    TACLFileDialogVistaImpl(Result).FFileDialog := LIntf;
  end
  else
    Result := nil;
end;

end.
