////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   General Dialogs implementation for Windows
//
//  Author:    Artem Izmaylov
//             © 2006-2026
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
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Graphics,
  ACL.UI.Dialogs,
  ACL.UI.Forms,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

type

  { TACLFileDialogImpl }

  TACLFileDialogImpl = class(TACLUnknownObject)
  strict private
    FDefaultExts: string;
  protected
    FDialog: TACLFileDialog;
    FSaveDialog: Boolean;

    function GetDefaultExts(out APtr: PWideChar): Boolean;
  public
    class function Create(ADialog: TACLFileDialog; ASaveDialog: Boolean): TACLFileDialogImpl; static;
    function Execute(AOwnerWnd: TWndHandle): Boolean; virtual; abstract;
  end;

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
    constructor Create(ADialog: TACLFileDialog; ASaveDialog: Boolean);
    destructor Destroy; override;
    function Execute(AOwnerWnd: TWndHandle): Boolean; override;
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
    constructor Create(ADialog: TACLFileDialog; ADialogIntf: IFileDialog; ASaveDialog: Boolean);
    destructor Destroy; override;
    function Execute(AOwnerWnd: TWndHandle): Boolean; override;
    class function TryCreate(ADialog: TACLFileDialog; ASaveDialog: Boolean): TACLFileDialogImpl;
  end;

function LoadDialogIcon(AOwnerWnd: HWND; AType: TMsgDlgType; ASize: Integer): TACLDib;
implementation

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

{ TACLFileDialogImpl }

class function TACLFileDialogImpl.Create(
  ADialog: TACLFileDialog; ASaveDialog: Boolean): TACLFileDialogImpl;
begin
  Result := TACLFileDialogVistaImpl.TryCreate(ADialog, ASaveDialog);
  if Result = nil then
    Result := TACLFileDialogOldImpl.Create(ADialog, ASaveDialog);
end;

function TACLFileDialogImpl.GetDefaultExts(out APtr: PWideChar): Boolean;
var
  LParts: TStringDynArray;
begin
  FDefaultExts := '';
  if FSaveDialog then
  begin
    acSplitString(FDialog.Filter, '|', LParts);
    for var I := 0 to Length(LParts) div 2 - 1 do
    begin
      if (FDefaultExts.Length > 0) and (FDefaultExts[FDefaultExts.Length] <> ';') then
        FDefaultExts := FDefaultExts + ';';
      FDefaultExts := FDefaultExts + StringReplace(LParts[2 * I + 1], '*.', '', [rfReplaceAll]);
    end;
    if (FDefaultExts.Length > 0) and (FDefaultExts[FDefaultExts.Length] = ';') then
      Delete(FDefaultExts, Length(FDefaultExts), 1);
    APtr := PWideChar(FDefaultExts);
  end;
  Result := FDefaultExts <> '';
end;

{ TACLFileDialogOldImpl }

constructor TACLFileDialogOldImpl.Create(ADialog: TACLFileDialog; ASaveDialog: Boolean);
var
  LDefaultExt: PWideChar;
begin
  FDialog := ADialog;
  FSaveDialog := ASaveDialog;
  FTempInitialPath := ADialog.GetActualInitialDir;
  FTempFilter := AllocFilterStr(ADialog.Filter);
  FTempBufferSize := MAXWORD;
  FTempBuffer := AllocMem(FTempBufferSize);
  ZeroMemory(@FStruct, SizeOf(FStruct));
  FStruct.FlagsEx := 0;
  FStruct.hInstance := HINSTANCE;
  FStruct.lpfnHook := DialogHook;
  FStruct.lpstrFilter := PWideChar(FTempFilter);
  FStruct.lpstrInitialDir := PWideChar(FTempInitialPath);
  FStruct.lpstrTitle := PWideChar(ADialog.Title);
  FStruct.lStructSize := SizeOf(TOpenFilenameW);
  FStruct.nFilterIndex := ADialog.FilterIndex;
  if GetDefaultExts(LDefaultExt) then
    FStruct.lpstrDefExt := LDefaultExt;
  PrepareFlags(FStruct);
  PrepareConst(FStruct);
end;

destructor TACLFileDialogOldImpl.Destroy;
begin
  FreeMemAndNil(FTempBuffer);
  inherited Destroy;
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

function TACLFileDialogOldImpl.Execute(AOwnerWnd: TWndHandle): Boolean;
begin
  FStruct.hWndOwner := AOwnerWnd;

  if FSaveDialog then
    Result := GetSaveFileNameW(FStruct)
  else
    Result := GetOpenFileNameW(FStruct);

  if Result then
  begin
    GetFileNames(FDialog.Files);
    FDialog.FilterIndex := FStruct.nFilterIndex;
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
  acStrLCopy(FTempBuffer, FDialog.FileName, Length(FDialog.Filename));
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
    if Option in FDialog.Options then
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
  if FSaveDialog or not (ofAllowMultiSelect in FDialog.Options) then
    AFileList.Add(FTempBuffer)
  else
    ExtractFileNames(FTempBuffer);
end;

class function TACLFileDialogOldImpl.DialogHook(Wnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): UINT_PTR;

  procedure CenterWindow(Wnd: HWnd);
  var
    LForm: TForm;
    LMonitor: TMonitor;
    LWndRect: TRect;
  begin
    LForm := acActiveFormOrMain;
    if LForm <> nil then
      LMonitor := LForm.Monitor
    else if Screen.MonitorCount > 0 then
      LMonitor := Screen.Monitors[0]
    else
      LMonitor := nil;

    if LMonitor <> nil then
    begin
      GetWindowRect(Wnd, LWndRect);
      SetWindowPos(Wnd, HWND_TOP,
        LMonitor.Left + ((LMonitor.Width - LWndRect.Width) div 2),
        LMonitor.Top + ((LMonitor.Height - LWndRect.Height) div 3), 0, 0, SWP_NOSIZE);
    end;
  end;

var
  LParent: HWND;
begin
  if Msg = WM_INITDIALOG then
    CenterWindow(Wnd)
  else
    if (Msg = WM_NOTIFY) and (POFNotify(LParam)^.hdr.code = CDN_INITDONE) then
    begin
      LParent := GetWindowLong(Wnd, GWL_HWNDPARENT);
      CenterWindow(LParent);
      SetForegroundWindow(LParent);
    end;

  Result := DefWindowProc(Wnd, Msg, WParam, LParam);
end;

{ TACLFileDialogVistaImpl }

constructor TACLFileDialogVistaImpl.Create(
  ADialog: TACLFileDialog; ADialogIntf: IFileDialog; ASaveDialog: Boolean);
begin
  FDialog := ADialog;
  FFileDialog := ADialogIntf;
  FSaveDialog := ASaveDialog;
end;

destructor TACLFileDialogVistaImpl.Destroy;
begin
  FFileDialog := nil;
  CoFreeUnusedLibraries;
  inherited;
end;

function TACLFileDialogVistaImpl.Execute(AOwnerWnd: TWndHandle): Boolean;
var
  LFilterIndex: Cardinal;
begin
  Initialize;
  InitializeFilter;
  Result := Succeeded(FFileDialog.Show(AOwnerWnd));
  if Result then
  begin
    QuerySeletectedFiles(FDialog.Files);
    if Succeeded(FFileDialog.GetFileTypeIndex(LFilterIndex)) then
      FDialog.FilterIndex := LFilterIndex;
  end;
end;

procedure TACLFileDialogVistaImpl.Initialize;
const
  DialogOptions: array[TACLFileDialogOption] of DWORD = (
    FOS_OVERWRITEPROMPT, 0, FOS_ALLOWMULTISELECT, FOS_PATHMUSTEXIST,
    FOS_FILEMUSTEXIST, 0, FOS_FORCESHOWHIDDEN, 0
  );
var
  LCookie: DWORD;
  LDefaultExts: PWideChar;
  LFlags: DWORD;
  LSelectedPath: UnicodeString;
  LShellItem: IShellItem;
begin
  LSelectedPath := FDialog.GetActualInitialDir;
  if FDialog.Title <> '' then
    FFileDialog.SetTitle(PWideChar(FDialog.Title));
  if GetDefaultExts(LDefaultExts) then
    FFileDialog.SetDefaultExtension(LDefaultExts);
  if FDialog.FileName <> '' then
  begin
    FFileDialog.SetFileName(PWideChar(acExtractFileName(FDialog.FileName)));
    if LSelectedPath = '' then
      LSelectedPath := acExtractFilePath(FDialog.FileName);
  end;
  if LSelectedPath <> '' then
  begin
    if Succeeded(SHCreateItemFromParsingName(PWideChar(LSelectedPath),
      nil, StringToGUID(SID_IShellItem), LShellItem))
    then
      FFileDialog.SetFolder(LShellItem);
  end;

  LFlags := 0;
  for var LOption := Low(TACLFileDialogOption) to High(TACLFileDialogOption) do
  begin
    if LOption in FDialog.Options then
      LFlags := LFlags or DialogOptions[LOption];
  end;
  FFileDialog.SetOptions(LFlags);

  FFileDialog.Advise(Self, LCookie);
end;

procedure TACLFileDialogVistaImpl.InitializeFilter;
var
  LParts: TComdlgFilterSpecArray;
begin
  acSplitString(FDialog.Filter, '|', FFilter);
  SetLength(LParts, Length(FFilter) div 2);
  if Length(LParts) > 0 then
  begin
    for var I := 0 to Length(LParts) - 1 do
    begin
      LParts[I].pszName := PWideChar(FFilter[2 * I]);
      LParts[I].pszSpec := PWideChar(FFilter[2 * I + 1]);
    end;
    FFileDialog.SetFileTypes(Length(LParts), LParts);
    FFileDialog.SetFileTypeIndex(FDialog.FilterIndex);
  end;
end;

procedure TACLFileDialogVistaImpl.QuerySeletectedFiles(AFileList: TACLStringList);

  procedure OpenDialogPopulateSelectedFiles(AFileList: TACLStringList);
  var
    LCount: Integer;
    LEnumerator: IEnumShellItems;
    LItems: IShellItemArray;
    LResult: HRESULT;
    LShellItem: IShellItem;
  begin
    if Succeeded((FFileDialog as IFileOpenDialog).GetResults(LItems)) then
    begin
      if Succeeded(LItems.EnumItems(LEnumerator)) then
      begin
        LResult := LEnumerator.Next(1, LShellItem, @LCount);
        while Succeeded(LResult) and (LCount <> 0) do
        begin
          AFileList.Add(GetItemName(LShellItem));
          LResult := LEnumerator.Next(1, LShellItem, @LCount);
        end;
      end;
    end;
  end;

  procedure SaveDialogPopulateSelectedFileName(AFileList: TACLStringList);
  var
    LItems: IShellItem;
  begin
    if Succeeded((FFileDialog as IFileSaveDialog).GetResult(LItems)) then
      AFileList.Add(GetItemName(LItems));
  end;

begin
  AFileList.Clear;
  if FSaveDialog then
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
  LError: HRESULT;
  LName: PWideChar;
begin
  Result := '';
  LError := AItem.GetDisplayName(SIGDN_FILESYSPATH, LName);
  if Failed(LError) then
    LError := AItem.GetDisplayName(SIGDN_NORMALDISPLAY, LName);
  if Succeeded(LError) then
  try
    Result := acSimplifyLongFileName(LName);
  finally
    CoTaskMemFree(LName);
  end;
end;

class function TACLFileDialogVistaImpl.TryCreate(
  ADialog: TACLFileDialog; ASaveDialog: Boolean): TACLFileDialogImpl;
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
    Result := Create(ADialog, LIntf, ASaveDialog)
  else
    Result := nil;
end;

end.
