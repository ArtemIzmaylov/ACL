{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*            Shell API Wrappers             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.Shell;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.ActiveX,
  Winapi.ShellApi,
  Winapi.ShlObj,
  Winapi.Windows,
  Win.ComObj,
{$ELSE}
  LCLIntf,
  LCLType,
  UTF8Process,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}SysUtils,
  // ACL
  ACL.Classes.StringList,
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

const
  acMailToPrefix = 'mailto:';

{$IFDEF FPC}
  CSIDL_DESKTOP  = 0; // G_USER_DIRECTORY_DESKTOP
  CSIDL_MYMUSIC  = 3; // G_USER_DIRECTORY_MUSIC
  CSIDL_PERSONAL = 1; // G_USER_DIRECTORY_DOCUMENTS
  //G_USER_DIRECTORY_DOWNLOAD = 2,
  //G_USER_DIRECTORY_PICTURES = 4,
  //G_USER_DIRECTORY_PUBLIC_SHARE = 5,
  //G_USER_DIRECTORY_TEMPLATES = 6,
  //G_USER_DIRECTORY_VIDEOS = 7;
{$ENDIF}

type
{$IFDEF FPC}
  IShellFolder = Pointer;
  PItemIDList = ^TItemIDList;
  TItemIDList = record
    Path: string;
    Flags: Integer;
  end;
{$ENDIF}

  TShellShutdownMode = (sdPowerOff, sdLogOff, sdHibernate, sdSleep, sdReboot);

  { TACLShellFolder }

  TACLShellFolder = class
  strict private class var
    FDesktopFolder: TACLShellFolder;
  strict private
    FFullPIDL: PItemIDList;
    FLibrarySources: TACLStringList;
    FParent: TACLShellFolder;
    FPIDL: PItemIDList;
    FShellFolder: IShellFolder;

    function GetAttributes: Cardinal;
    function GetDisplayName: string;
    function GetLibrarySources: TACLStringList;
    function GetPath: string;
    function GetPathForParsing: string;
  protected
    class destructor Destroy;
    function GetChild(ID: PItemIDList): IShellFolder;
    function ParentShellFolder: IShellFolder;
  public
    constructor Create; overload;
    constructor Create(AParent: TACLShellFolder; ID: PItemIDList); overload;
    constructor CreateSpecial(ID: PItemIDList);
    destructor Destroy; override;
    function Compare(ID1, ID2: PItemIDList): Integer;
    procedure Enum(AOwnerWnd: HWND; AShowHidden: Boolean; AProc: TProc<PItemIDLIst>);
    function GetUIObjectOf(AOwnerWnd: HWND; const IID: TGUID; out AObject): Boolean;
    function HasChildren: Boolean;
    function IsFileSystemFolder: Boolean;
    function IsFileSystemPath: Boolean;
    function IsLibrary: Boolean;
    class function Root: TACLShellFolder;
    class function ShowHidden: Boolean;
    // Properties
    property DisplayName: string read GetDisplayName;
    property Parent: TACLShellFolder read FParent;
    property Path: string read GetPath;
    property PathForParsing: string read GetPathForParsing;
    // Library
    property LibrarySources: TACLStringList read GetLibrarySources;
    // ShellObjects
    property AbsoluteID: PItemIDLIst read FFullPIDL;
    property ID: PItemIDLIst read FPIDL;
    property ShellFolder: IShellFolder read FShellFolder;
  end;

  { TACLShellSearchPaths }

  TACLShellSearchPaths = class(TACLSearchPaths)
  public
    function CreatePathList: TACLStringList; override;
  end;

  { TPIDLHelper }

  TPIDLHelper = class
  public const
    Favorites = 'shell:::{679F85CB-0220-4080-B29B-5540CC05AAB6}';
  public
    class function ConcatPIDLs(IDList1, IDList2: PItemIDList): PItemIDList;
    class function CopyPIDL(IDList: PItemIDList): PItemIDList;
    class function CreatePIDL(ASize: Integer): PItemIDList;
    class procedure DisposePIDL(var PIDL: PItemIDList);
    class function GetDesktopPIDL: PItemIDList;
    class function GetDisplayName(AParentFolder: IShellFolder; PIDL: PItemIDList; AFlags: DWORD): string;
    class function GetFolderPIDL(AOwnerWnd: HWND; APath: string): PItemIDList;
    class function GetParentPIDL(IDList: PItemIDList): PItemIDList; {nullable}
    class function GetPIDLSize(IDList: PItemIDList): Integer;

  {$IFDEF MSWINDOWS}
    class function GetNextPIDL(IDList: PItemIDList): PItemIDList;
    class function StrRetToString(PIDL: PItemIDList; AStrRet: TStrRet; AFlag: string = ''): string;

    // https://docs.microsoft.com/en-us/windows/win32/shell/clipboard#cfstr_shellidlist
    class function FilesToShellListStream(AFiles: TACLStringList; out AStream: TMemoryStream): Boolean;
    class function ShellListStreamToFiles(AStream: TCustomMemoryStream; out AFiles: TACLStringList): Boolean;
  {$ENDIF}
  end;

  { TACLRecycleBin }

  TACLRecycleBin = class
  strict private
    class var FLastError: HRESULT;
    class var FLastErrorText: string;
    class function GetLastErrorText: string; static;
  public
    class function Delete(AFilesOrFolders: TACLStringList): HRESULT; overload;
    class function Delete(const AFileOrFolder: string): HRESULT; overload;
    class function Restore(const AFileOrFolder: string): HRESULT;
    class property LastError: HRESULT read FLastError;
    class property LastErrorText: string read GetLastErrorText;
  end;

// Shell - Executing
function ShellExecute(const AFileName, AParameters: string): Boolean; overload;
function ShellExecute(const AFileName: string): Boolean; overload;
function ShellExecuteURL(const ALink: string): Boolean;
function ShellJumpToFile(const AFileName: string): Boolean;

// Shell - System Paths
function ShellPath(CLSID: Integer): string;
function ShellPathAppData: string;
function ShellPathDesktop: string;
function ShellPathMyDocuments: string;
function ShellPathMyMusic: string;
{$IFDEF MSWINDOWS}
function ShellPathSystem32: string;
{$IFDEF CPUX64}
function ShellPathSystem32WOW64: string;
{$ENDIF}{$ENDIF}

// Shell - Libraries
procedure ShellExpandPath(const APath: string; AReceiver: IStringReceiver);
function ShellIsLibraryPath(const APath: string): Boolean;

// Shell - Links
{$IFDEF MSWINDOWS}
function ShellCreateLink(const ALinkFileName, AFileName: string): Boolean;
function ShellParseLink(const ALink: string; out AFileName: string): Boolean;
{$ENDIF}

function ShellGetFreeSpace(const AFileName: string): Int64;
function ShellShutdown(AMode: TShellShutdownMode): Boolean;
procedure ShellFlushCache;
implementation

uses
{$IFDEF MSWINDOWS}
  ACL.Utils.Registry,
  ACL.Utils.Stream,
{$ELSE}
  ACL.Utils.FileSystem.GIO,
  ACL.Web,
{$ENDIF}
  ACL.Utils.Strings;

{$IFNDEF MSWINDOWS}
const
  SHGDN_INFOLDER        = 0;

  SFGAO_STREAM          = 1;
  SFGAO_FILESYSTEM      = 2;
  SFGAO_FILESYSANCESTOR = 4;
  SFGAO_FOLDER          = 8;

  PIDL_BOOKMARK = 1;
  PIDL_SPECIAL  = 2;
  PIDL_SPECIAL2 = 4;
  PIDL_VIRTUAL  = 8;

const
  libGLib2 = 'libgobject-2.0.so.0';

function g_get_user_special_dir(directory: DWORD): PChar; cdecl; external libGLib2;
{$ENDIF}

//------------------------------------------------------------------------------
// Shell - General
//------------------------------------------------------------------------------

{$REGION ' General '}

{$IFDEF MSWINDOWS}
type
  TShellOperation = (soMove, soCopy, soDelete, soRename);
  TShellOperationFlag = (sofCanUndo, sofNoDialog, sofNoConfirmation);
  TShellOperationFlags = set of TShellOperationFlag;

function ShellEncodePaths(const APaths: TACLStringList): string;
var
  LBuilder: TACLStringBuilder;
  I: Integer;
begin
  LBuilder := TACLStringBuilder.Create;
  try
    for I := 0 to APaths.Count - 1 do
      LBuilder.Append(acExcludeTrailingPathDelimiter(APaths[I])).Append(#0);
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function ShellOperation(const ASourceList, ADestList: string;
  const AOperation: TShellOperation; const AFlags: TShellOperationFlags): HRESULT;
const
  OperationMap: array[TShellOperation] of Integer = (FO_MOVE, FO_COPY, FO_DELETE, FO_RENAME);
var
  AErrorCode: Integer;
  AStruct: TSHFileOpStructW;
begin
  ZeroMemory(@AStruct, SizeOf(AStruct));
  AStruct.wFunc := OperationMap[AOperation];
  if sofCanUndo in AFlags then
    AStruct.fFlags := AStruct.fFlags or FOF_ALLOWUNDO;
  if sofNoDialog in AFlags then
    AStruct.fFlags := AStruct.fFlags or FOF_SILENT or FOF_NOERRORUI;
  if sofNoConfirmation in AFlags then
    AStruct.fFlags := AStruct.fFlags or FOF_NOCONFIRMATION;
  if ASourceList <> '' then
    AStruct.pFrom := PWideChar(ASourceList);
  if ADestList <> '' then
    AStruct.pTo := PWideChar(ADestList);

  AErrorCode := SHFileOperationW(AStruct);
  if AErrorCode <> 0 then
    Result := HResultFromWin32(AErrorCode)
  else if AStruct.fAnyOperationsAborted then
    Result := E_ABORT
  else
    REsult := S_OK;
end;
{$ENDIF}

function ShellShutdown(AMode: TShellShutdownMode): Boolean;
{$IFDEF MSWINDOWS}

  function GetPrivileges: Boolean;
  var
    ALength: Cardinal;
    ALuID: TLargeInteger;
    ANewPriv, APrevPriv: TTokenPrivileges;
    AToken: THandle;
  begin
    Result := False;
    if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, AToken) then
    begin
      if not GetTokenInformation(AToken, TokenPrivileges, nil, 0, ALength) then
      begin
        if (GetLastError = 122) and LookupPrivilegeValue(nil, 'SeShutdownPrivilege', ALuID) then
        begin
          ANewPriv.PrivilegeCount := 1;
          ANewPriv.Privileges[0].Luid := ALuID;
          ANewPriv.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
          Result := AdjustTokenPrivileges(AToken, False, ANewPriv, SizeOf(TTokenPrivileges), APrevPriv, ALength);
        end;
      end;
    end;
  end;

var
  Version: TOSVersionInfo;
begin
  Result := False;
  Version.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  GetVersionEx(version);
  if Version.dwPlatformId = VER_PLATFORM_WIN32_NT then
  begin
    if not GetPrivileges then
      Exit;
  end;
  case AMode of
    sdPowerOff:
      Result := ExitWindowsEx(EWX_FORCEIFHUNG or EWX_POWEROFF, MaxInt);
    sdLogOff:
      Result := ExitWindowsEx(EWX_FORCEIFHUNG or EWX_LOGOFF, MaxInt);
    sdReboot:
      Result := ExitWindowsEx(EWX_FORCEIFHUNG or EWX_REBOOT, MaxInt);
    sdHibernate, sdSleep:
      Result := SetSystemPowerState(AMode = sdSleep, False);
  end;
{$ELSE}
const
  // https://www.computerhope.com/unix/ushutdow.htm
  CmdMap: array[TShellShutdownMode] of string = (
    '/sbin/shutdown -h now',
    '/sbin/shutdown -h now',
    'systemctl hibernate',
    'systemctl suspend',
    '/sbin/shutdown -r now'
  );
begin
  with TProcessUTF8.Create(nil) do
  try
    InheritHandles := False;
    CommandLine := CmdMap[AMode];
    try
      Execute;
      Result := True;
    except
      Result := False;
    end;
  finally
    Free;
  end;
{$ENDIF}
end;

procedure ShellFlushCache;
begin
{$IFDEF MSWINDOWS}
  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST or SHCNF_FLUSH, nil, nil);
  Sleep(1000);
{$ENDIF}
end;

{$ENDREGION}

//------------------------------------------------------------------------------
// Shell - Executing
//------------------------------------------------------------------------------

{$REGION ' Executing '}

function ShellOpen(const AFileName, AParameters: string): Boolean;
begin
{$IFDEF FPC}
  if AParameters <> '' then
  try
    RunCmdFromPath(AFileName, AParameters);
    Result := True;
  except
    Result := False;
  end
  else
    Result := OpenDocument(AFileName);
{$ELSE}
  Result := ShellExecuteW(0, nil, PWideChar(AFileName),
    PWideChar(AParameters), '', SW_SHOW) > HINSTANCE_ERROR;
{$ENDIF}
end;

function ShellOpenUrl(const Url: string): Boolean;
begin
{$IFDEF FPC}
  Result := OpenURL(Url);
{$ELSE}
  if IsWine then
    Result := ShellOpen('winebrowser', Url)
  else
    Result := ShellOpen(Url, '');
{$ENDIF}
end;

function ShellExecute(const AFileName: string): Boolean;
begin
  Result := ShellExecute(AFileName, '');
end;

function ShellExecute(const AFileName, AParameters: string): Boolean; overload;
begin
  if AFileName = '' then
    Exit(False);
  if acIsUrlFileName(AFileName) or acBeginsWith(AFileName, acMailToPrefix) then
    Result := ShellOpenUrl(AFileName)
  else
    Result := ShellOpen(AFileName, AParameters);
end;

function ShellExecuteURL(const ALink: string): Boolean;
begin
  if ALink = '' then
    Result := False
  else
    if (Pos('//', ALink) = 0) and not acDirectoryExists(ALink) then
      Result := ShellOpenUrl('https://' + ALink)
    else
      Result := ShellOpenUrl(ALink);
end;

function ShellJumpToFile(const AFileName: string): Boolean;
begin
  Result := False;
  if AFileName <> '' then
  begin
    if acIsUrlFileName(AFileName) then
      Result := ShellOpenUrl(AFileName)
    else
    begin
    {$IFDEF MSWINDOWS}
      var IL := ILCreateFromPathW(PWideChar(AFileName));
      if IL <> nil then
      try
        SHOpenFolderAndSelectItems(IL, 0, nil, 0);
        Result := True;
      finally
        ILFree(IL);
      end;
    {$ELSE}
      Result := ShellExecute(acExtractFileDir(AFileName));
    {$ENDIF}
    end;
  end;
end;
{$ENDREGION}

//------------------------------------------------------------------------------
// Shell - System Paths
//------------------------------------------------------------------------------

{$REGION ' System Paths '}

function ShellPath(CLSID: Integer): string;
{$IF DEFINED(MSWINDOWS)}
var
  ABuf: TFilePath;
begin
  if SHGetSpecialFolderPathW(0, @ABuf[0], CLSID, False) then
    Result := acIncludeTrailingPathDelimiter(ABuf)
  else
    Result := acTempPath;
end;
{$ELSE}
begin
  Result := g_get_user_special_dir(CLSID);
end;
{$ENDIF}

function ShellPathAppData: string;
begin
{$IFDEF MSWINDOWS}
  Result := ShellPath(CSIDL_APPDATA);
{$ELSE}
  Result := acIncludeTrailingPathDelimiter(GetUserDir) + '/.config/';
{$ENDIF}
end;

function ShellPathDesktop: string;
begin
  Result := ShellPath(CSIDL_DESKTOP);
end;

function ShellPathMyDocuments: string;
begin
  Result := ShellPath(CSIDL_PERSONAL);
end;

function ShellPathMyMusic: string;
begin
  Result := ShellPath(CSIDL_MYMUSIC);
end;

{$IFDEF MSWINDOWS}
function ShellPathSystem32: string;
var
  ABuf: TFilePath;
begin
  acClearFilePath(ABuf);
  GetSystemDirectoryW(@ABuf[0], Length(ABuf));
  Result := acIncludeTrailingPathDelimiter(ABuf);
end;

{$IFDEF CPUX64}
function ShellPathSystem32WOW64: string;
type
  TGetSystemWow64Directory = function (lpBuffer: LPWSTR; uSize: UINT): UINT; stdcall;
var
  ABuffer: TFilePath;
  AGetFunc: TGetSystemWow64Directory;
begin
  AGetFunc := GetProcAddress(GetModuleHandle(kernel32), 'GetSystemWow64DirectoryW');
  if Assigned(AGetFunc) then
  begin
    acClearFilePath(ABuffer);
    AGetFunc(@ABuffer[0], Length(ABuffer));
    Result := acIncludeTrailingPathDelimiter(ABuffer);
  end
  else
    raise EInvalidOperation.Create('The GetSystemWow64Directory function is unavailable');
end;
{$ENDIF}{$ENDIF}

{$ENDREGION}

//------------------------------------------------------------------------------
// Shell - Libraries
//------------------------------------------------------------------------------

{$REGION ' Libraries '}

function ShellIsLibraryPath(const APath: string): Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := APath.Contains('::');
{$ELSE}
  Result := False;
{$ENDIF}
end;

function ShellReadLibrary(const APathForParsing: string; AReceiver: IStringReceiver): Boolean;
{$IFDEF MSWINDOWS}
var
  ACount: Cardinal;
  ALibrary: IShellLibrary;
  APath: PWideChar;
  AShellItem: IShellItem;
  AShellItems: IShellItemArray;
  I: Integer;
begin
  Result :=
    Succeeded(SHCreateLibrary(IID_IShellLibrary, Pointer(ALibrary))) and
    Succeeded(SHCreateItemFromParsingName(PWideChar(APathForParsing), nil, IID_IShellItem, AShellItem)) and
    Succeeded(ALibrary.LoadLibraryFromItem(AShellItem, STGM_READ)) and
    Succeeded(ALibrary.GetFolders(LFF_FORCEFILESYSTEM, IID_IShellItemArray, AShellItems)) and
    Succeeded(AShellItems.GetCount(ACount));

  if Result then
    for I := 0 to ACount - 1 do
      if Succeeded(AShellItems.GetItemAt(I, AShellItem)) then
      begin
        if Succeeded(AShellItem.GetDisplayName(SIGDN_FILESYSPATH, APath)) then
        try
          AReceiver.Add(acIncludeTrailingPathDelimiter(APath));
        finally
          CoTaskMemFree(APath);
        end;
      end;
{$ELSE}
begin
  Result := False;
{$ENDIF}
end;

procedure ShellExpandPath(const APath: string; AReceiver: IStringReceiver);
begin
  if APath <> '' then
  begin
    if ShellIsLibraryPath(APath) then
      ShellReadLibrary(APath, AReceiver)
    else
      AReceiver.Add(APath);
  end;
end;

{$ENDREGION}

//------------------------------------------------------------------------------
// Shell - Link
//------------------------------------------------------------------------------

{$REGION ' Links '}

{$IFDEF MSWINDOWS}
function ShellCreateLinkObject(out AObject: IShellLinkW): Boolean;
begin
  CoInitialize(nil);
  Result := Succeeded(CoCreateInstance(CLSID_ShellLink, nil,
    CLSCTX_INPROC_SERVER or CLSCTX_LOCAL_SERVER, IShellLinkW, AObject));
end;

function ShellCreateLink(const ALinkFileName, AFileName: string): Boolean;
var
  ALink: IShellLinkW;
  ALinkFile: IPersistFile;
  ATempFileName: string;
begin
  Result := False;
  if acFileExists(AFileName) then
  try
    if ShellCreateLinkObject(ALink) then
    try
      ATempFileName := AFileName; // Note: AV on 64x OS
      ALink.SetPath(PWideChar(ATempFileName));
      if Supports(ALink, IPersistFile, ALinkFile) then
      try
        Result := Succeeded(ALinkFile.Save(PWideChar(ALinkFileName), True));
      finally
        ALinkFile := nil;
      end;
    finally
      ALink := nil;
    end;
  except
    Result := False;
  end;
end;

function ShellParseLink(const ALink: string; out AFileName: string): Boolean;
type
  TFileFindData = _WIN32_FIND_DATAW;
var
  ABuffer: TFileLongPath;
  AData: TFileFindData;
  ALinkFile: IPersistFile;
  AObject: IShellLinkW;
begin
  Result := False;
  try
    if ShellCreateLinkObject(AObject) then
    try
      if Supports(AObject, IPersistFile, ALinkFile) then
      try
        Result := Succeeded(ALinkFile.Load(PWideChar(sLongFileNamePrefix + ALink), OF_READ));
        if Result then
        begin
          acClearFileLongPath(ABuffer);
          Result := Succeeded(AObject.GetPath(@ABuffer[0], Length(ABuffer), AData, 0));
          if Result then
            AFileName := ABuffer;
        end;
      finally
        ALinkFile := nil;
      end;
    finally
      AObject := nil;
    end;
  except
    Result := False;
  end;
end;
{$ENDIF}
{$ENDREGION}

//------------------------------------------------------------------------------
// Shell - Drives
//------------------------------------------------------------------------------

{$REGION ' Drives '}

function ShellGetFreeSpace(const AFileName: string): Int64;
{$IFDEF MSWINDOWS}
var
  LDrive: string;
  LErrorMode: Integer;
  LTemp: Int64;
begin
  LErrorMode := SetErrorMode(SEM_FailCriticalErrors);
  try
    LDrive := Copy(AFileName, 1, 2);
    if not GetDiskFreeSpaceEx(PChar(LDrive), Result, LTemp, nil) then
      Result := -1;
  finally
    SetErrorMode(LErrorMode);
  end;
{$ELSE}
begin
  Result := SysUtils.DiskFree(SysUtils.AddDisk(acExtractFileDir(AFileName)));
{$ENDIF}
end;

{$ENDREGION}

{ TACLShellFolder }

constructor TACLShellFolder.Create;
begin
  FPIDL := TPIDLHelper.GetDesktopPIDL;
  FFullPIDL := TPIDLHelper.CopyPIDL(FPIDL);
{$IFDEF MSWINDOWS}
  OleCheck(SHGetDesktopFolder(FShellFolder));
{$ENDIF}
end;

constructor TACLShellFolder.Create(AParent: TACLShellFolder; ID: PItemIDList);
begin
  FParent := AParent;
  FPIDL := TPIDLHelper.CopyPIDL(ID);
  FFullPIDL := TPIDLHelper.ConcatPIDLs(AParent.AbsoluteID, ID);
  FShellFolder := AParent.GetChild(ID);
end;

constructor TACLShellFolder.CreateSpecial(ID: PItemIDList);
begin
  FPIDL := TPIDLHelper.CopyPIDL(ID);
  FFullPIDL := TPIDLHelper.CopyPIDL(ID);
{$IFDEF MSWINDOWS}
  OleCheck(Root.ShellFolder.BindToObject(FPIDL, nil, IID_IShellFolder, FShellFolder));
{$ELSE}
  FPIDL^.Flags := PIDL_SPECIAL;
{$ENDIF}
end;

class destructor TACLShellFolder.Destroy;
begin
  FreeAndNil(FDesktopFolder);
end;

destructor TACLShellFolder.Destroy;
begin
  TPIDLHelper.DisposePIDL(FPIDL);
  TPIDLHelper.DisposePIDL(FFullPIDL);
  FreeAndNil(FLibrarySources);
  inherited Destroy;
end;

function TACLShellFolder.Compare(ID1, ID2: PItemIDList): Integer;
begin
{$IFDEF MSWINDOWS}
  Result := SmallInt(ParentShellFolder.CompareIDs(0, ID1, ID2));
{$ELSE}
  Result := acCompareStrings(ID1^.Path, ID2^.Path);
{$ENDIF}
end;

procedure TACLShellFolder.Enum(AOwnerWnd: HWND; AShowHidden: Boolean; AProc: TProc<PItemIDLIst>);
{$IFDEF MSWINDOWS}
var
  LFlags: LongWord;
  LEnumList: IEnumIDList;
  LItemID: PItemIDList;
  LNumIDs: LongWord;
begin
  try
    LFlags := SHCONTF_FOLDERS;
    if AShowHidden then
      LFlags := LFlags or SHCONTF_INCLUDEHIDDEN;
    if ShellFolder.EnumObjects(AOwnerWnd, LFlags, LEnumList) = 0 then
      while LEnumList.Next(1, LItemID, LNumIDs) = S_OK do
      begin
        if LItemID <> nil then
          AProc(LItemID);
      end;
  except
    // do nothing
  end;
{$ELSE}
var
  LBookmarks: TACLStringList;
  LHomeDir: string;
  LInfo: TACLFindFileInfo;
  LItem: TItemIDList;
  I: Integer;
begin
  if ID^.Flags and PIDL_BOOKMARK <> 0 then
    Exit;

  ZeroMemory(@LItem, SizeOf(LItem));
  if ID^.Flags and PIDL_SPECIAL <> 0 then
    LItem.Flags := PIDL_SPECIAL2;
  if ID^.Path = TPIDLHelper.Favorites then
  begin
    LHomeDir := acExcludeTrailingPathDelimiter(GetUserDir);
    LItem.Flags := PIDL_BOOKMARK;
    LItem.Path := LHomeDir;
    AProc(@LItem);

    LBookmarks := TACLStringList.Create;
    try
      if not LBookmarks.LoadFromFile(LHomeDir + '/.config/gtk-3.0/bookmarks') then // get_bookmarks_file
        LBookmarks.LoadFromFile(LHomeDir + '/.gtk-bookmarks'); // get_legacy_bookmarks_file
      for I := 0 to LBookmarks.Count - 1 do
      begin
        LHomeDir := LBookmarks[I];
        if LHomeDir.StartsWith('file://', True) then
        begin
          LItem.Path := acURLDecode(Copy(LHomeDir, 8));
          AProc(@LItem);
        end;
      end;
    finally
      LBookmarks.Free;
    end;
  end
  else
    if ID^.Flags and PIDL_VIRTUAL = 0 then
    begin
      if acFindFileFirst(acIncludeTrailingPathDelimiter(Path), [ffoFolder], LInfo) then
      try
        repeat
          if AShowHidden or not LInfo.FileName.StartsWith('.') then
          begin
            LItem.Path := LInfo.FullFileName;
            AProc(@LItem);
          end;
        until not acFindFileNext(LInfo);
      finally
        acFindFileClose(LInfo);
      end;
    end;
{$ENDIF}
end;

function TACLShellFolder.GetUIObjectOf(AOwnerWnd: HWND; const IID: TGUID; out AObject): Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := Succeeded(ShellFolder.GetUIObjectOf(AOwnerWnd, 1, FPIDL, IID, nil, AObject));
{$ELSE}
  Result := False;
{$ENDIF}
end;

function TACLShellFolder.HasChildren: Boolean;
{$IFDEF MSWINDOWS}
var
  LFlags: LongWord;
begin
  LFlags := SFGAO_CONTENTSMASK;
  Result := Succeeded(ParentShellFolder.GetAttributesOf(1, FPIDL, LFlags)) and
    (LFlags and SFGAO_HASSUBFOLDER <> 0);
{$ELSE}
begin
  Result := ID^.Flags and PIDL_BOOKMARK = 0;
{$ENDIF}
end;

function TACLShellFolder.IsFileSystemFolder: Boolean;
var
  LAttrs: Cardinal;
begin
  LAttrs := GetAttributes;
  Result :=
    (LAttrs and (SFGAO_FILESYSANCESTOR or SFGAO_FILESYSTEM) <> 0) and
    (LAttrs and (SFGAO_STREAM or SFGAO_FOLDER) <> (SFGAO_STREAM or SFGAO_FOLDER));
end;

function TACLShellFolder.IsFileSystemPath: Boolean;
begin
  Result := GetAttributes and (SFGAO_FILESYSANCESTOR or SFGAO_FILESYSTEM) <> 0;
end;

function TACLShellFolder.IsLibrary: Boolean;
begin
  Result := LibrarySources.Count > 0;
end;

//function TACLShellFolder.Rename(const NewName: string): boolean;
//var
//  ANewPIDL: PItemIDList;
//begin
//  Result := False;
//  if GetCapabilities and SFGAO_CANRENAME <> 0 then
//  begin
//    Result := ParentShellFolder.SetNameOf(0, FPIDL, PWideChar(NewName), SHGDN_NORMAL, ANewPIDL) = S_OK;
//    if Result then
//    begin
//      FPIDL := ANewPIDL;
//      TPIDLHelper.DisposePIDL(FPIDL);
//      TPIDLHelper.DisposePIDL(FFullPIDL);
//      if FParent = nil then
//        FFullPIDL := TPIDLHelper.CopyPIDL(ANewPIDL)
//      else
//        FFullPIDL := TPIDLHelper.ConcatPIDLs(FParent.FPIDL, ANewPIDL);
//    end
//  end;
//end;

class function TACLShellFolder.Root: TACLShellFolder;
begin
  if FDesktopFolder = nil then
    FDesktopFolder := TACLShellFolder.Create;
  Result := FDesktopFolder;
end;

class function TACLShellFolder.ShowHidden: Boolean;
{$IFDEF MSWINDOWS}
var
  AKey: THandle;
begin
  AKey := acRegOpenRead(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced');
  Result := acRegReadInt(AKey, 'Hidden') = 1;
  acRegClose(AKey);
{$ELSE}
begin
  Result := False;
{$ENDIF}
end;

function TACLShellFolder.GetChild(ID: PItemIDList): IShellFolder;
{$IFDEF MSWINDOWS}
var
  HR: HRESULT;
begin
  HR := ShellFolder.BindToObject(ID, nil, IID_IShellFolder, Pointer(Result));
  if HR <> S_OK then
    ShellFolder.GetUIObjectOf(0, 1, ID, IID_IShellFolder, nil, Pointer(Result));
  if HR <> S_OK then
    ShellFolder.CreateViewObject(0, IID_IShellFolder, Pointer(Result));
  if Result = nil then
    Root.ShellFolder.BindToObject(ID, nil, IID_IShellFolder, Pointer(Result));
{$ELSE}
begin
  Result := nil;
{$ENDIF}
end;

function TACLShellFolder.ParentShellFolder: IShellFolder;
begin
  if FParent <> nil then
    Result := FParent.ShellFolder
  else
    Result := Root.ShellFolder;
end;

function TACLShellFolder.GetAttributes: Cardinal;
begin
{$IFDEF MSWINDOWS}
  Result := SFGAO_STORAGECAPMASK;
  if Failed(ParentShellFolder.GetAttributesOf(1, FPIDL, Result)) then
    Result := 0;
{$ELSE}
  Result := SFGAO_FILESYSANCESTOR;
  if ID^.Flags and PIDL_VIRTUAL = 0 then
    Result := Result or SFGAO_FILESYSTEM or SFGAO_FOLDER;
{$ENDIF}
end;

function TACLShellFolder.GetDisplayName: string;
begin
  Result := TPIDLHelper.GetDisplayName(ParentShellFolder, ID, SHGDN_INFOLDER);
end;

function TACLShellFolder.GetLibrarySources: TACLStringList;
begin
  if FLibrarySources = nil then
  begin
    FLibrarySources := TACLStringList.Create;
  {$IFDEF MSWINDOWS}
    if Parent <> nil then
    begin
      if GetAttributes and (SFGAO_FILESYSANCESTOR or SFGAO_FILESYSTEM) = SFGAO_FILESYSANCESTOR then
        ShellReadLibrary(PathForParsing, FLibrarySources);
    end;
  {$ENDIF}
  end;
  Result := FLibrarySources;
end;

function TACLShellFolder.GetPath: string;
begin
  if GetAttributes and SFGAO_FILESYSTEM <> 0 then
    Result := PathForParsing
  else
    Result := EmptyStr;
end;

function TACLShellFolder.GetPathForParsing: string;
begin
{$IFDEF MSWINDOWS}
  Result := TPIDLHelper.GetDisplayName(Root.ShellFolder, AbsoluteID, SHGDN_FORPARSING);
{$ELSE}
  Result := acIncludeTrailingPathDelimiter(ID^.Path);
{$ENDIF}
end;

{ TACLShellSearchPaths }

function TACLShellSearchPaths.CreatePathList: TACLStringList;
var
  I: Integer;
begin
  Result := TACLStringList.Create;
  Result.Capacity := Count;
  for I := 0 to Count - 1 do
    ShellExpandPath(Paths[I], Result);
end;

{ TPIDLHelper }

class function TPIDLHelper.GetDisplayName(
  AParentFolder: IShellFolder; PIDL: PItemIDList; AFlags: DWORD): string;
{$IFDEF MSWINDOWS}
var
  AStrRet: TStrRet;
begin
  FillChar(AStrRet, SizeOf(AStrRet), 0);
  AParentFolder.GetDisplayNameOf(PIDL, AFlags, AStrRet);
  Result := StrRetToString(PIDL, AStrRet);
{$ELSE}
begin
  if PIDL^.Path = Favorites then
    Exit('Favorites');
  if PIDL^.Path = PathDelim then
    Exit('File System');

  Result := acExtractFileName(PIDL^.Path);
  if (Result <> '') and (Result[1] = '.') then
    Result := Copy(Result, 2);
{$ENDIF}
end;

class function TPIDLHelper.ConcatPIDLs(IDList1, IDList2: PItemIDList): PItemIDList;
{$IFDEF MSWINDOWS}
var
  cb1, cb2: Integer;
begin
  cb1 := 0;
  if Assigned(IDList1) then
    cb1 := GetPIDLSize(IDList1) - SizeOf(IDList1^.mkid.cb);
  cb2 := GetPIDLSize(IDList2);
  Result := CreatePIDL(cb1 + cb2);
  if Assigned(Result) then
  begin
    if Assigned(IDList1) then
      CopyMemory(Result, IDList1, cb1);
    CopyMemory(PByte(Result) + cb1, IDList2, cb2);
  end;
{$ELSE}
begin
  Result := CopyPIDL(IDList2);
{$ENDIF}
end;

class function TPIDLHelper.CopyPIDL(IDList: PItemIDList): PItemIDList;
var
  Size: Integer;
begin
  Size := GetPIDLSize(IDList);
  Result := CreatePIDL(Size);
  if Result <> nil then
  begin
  {$IFDEF MSWINDOWS}
    CopyMemory(Result, IDList, Size);
  {$ELSE}
    Result^ := IDList^;
  {$ENDIF}
  end;
end;

class function TPIDLHelper.CreatePIDL(ASize: Integer): PItemIDList;
begin
{$IFDEF MSWINDOWS}
  var Malloc: IMalloc;
  OleCheck(SHGetMalloc(Malloc));
  Result := Malloc.Alloc(ASize);
{$ELSE}
  New(Result);
{$ENDIF}
  if Result <> nil then
    FillChar(Result^, ASize, 0);
end;

class procedure TPIDLHelper.DisposePIDL(var PIDL: PItemIDList);
begin
  if PIDL <> nil then
  begin
  {$IFDEF MSWINDOWS}
    CoTaskMemFree(PIDL);
  {$ELSE}
    Dispose(PIDL);
  {$ENDIF}
    PIDL := nil;
  end;
end;

class function TPIDLHelper.GetDesktopPIDL: PItemIDList;
begin
{$IFDEF MSWINDOWS}
  OleCheck(SHGetSpecialFolderLocation(0, CSIDL_DESKTOP, Result));
{$ELSE}
  Result := GetFolderPIDL(0, PathDelim);
{$ENDIF}
end;

class function TPIDLHelper.GetFolderPIDL(AOwnerWnd: HWND; APath: string): PItemIDList;
{$IFDEF MSWINDOWS}
var
  AEaten, AAttr: DWORD;
begin
  if not ShellIsLibraryPath(APath) then
    APath := acIncludeTrailingPathDelimiter(APath);

  if Failed(TACLShellFolder.Root.ShellFolder.ParseDisplayName(
    AOwnerWnd, nil, PWideChar(APath), AEaten, Result, AAttr))
  then
    Result := nil;
{$ELSE}
begin
  New(Result);
  Result^.Flags := 0;
  if not APath.StartsWith(PathDelim) then
    Result^.Flags := PIDL_VIRTUAL;
  if APath <> PathDelim then
    Result^.Path := acExcludeTrailingPathDelimiter(APath)
  else
    Result^.Path := APath;
{$ENDIF}
end;

class function TPIDLHelper.GetParentPIDL(IDList: PItemIDList): PItemIDList;
{$IFDEF MSWINDOWS}

  procedure StripLastID(IDList: PItemIDList);
  var
    MarkerID: PItemIDList;
  begin
    MarkerID := IDList;
    if Assigned(IDList) then
    begin
      while IDList.mkid.cb <> 0 do
      begin
        MarkerID := IDList;
        IDList := GetNextPIDL(IDList);
      end;
      MarkerID.mkid.cb := 0;
    end;
  end;

begin
  if (IDList <> nil) and (IDList.mkid.cb > 0) then
  begin
    Result := CopyPIDL(IDList);
    StripLastID(Result);
  end
  else
    Result := nil;
{$ELSE}
begin
  if (IDList^.Flags = 0) and (IDList^.Path <> PathDelim) then
    Result := GetFolderPIDL(0, acExtractFileDir(IDList^.Path))
  else
    Result := nil;
{$ENDIF}
end;

class function TPIDLHelper.GetPIDLSize(IDList: PItemIDList): Integer;
begin
  Result := 0;
  if IDList <> nil then
  begin
  {$IFDEF MSWINDOWS}
    Result := SizeOf(IDList^.mkid.cb);
    while IDList^.mkid.cb <> 0 do
    begin
      Result := Result + IDList^.mkid.cb;
      IDList := GetNextPIDL(IDList);
    end;
  {$ELSE}
    Result := SizeOf(TItemIDList);
  {$ENDIF}
  end;
end;

{$IFDEF MSWINDOWS}
class function TPIDLHelper.GetNextPIDL(IDList: PItemIDList): PItemIDList;
begin
  Result := IDList;
  Inc(PByte(Result), IDList^.mkid.cb);
end;

class function TPIDLHelper.StrRetToString(PIDL: PItemIDList; AStrRet: TStrRet; AFlag: string = ''): string;
var
  P: PAnsiChar;
begin
  Result := '';
  case AStrRet.uType of
    STRRET_CSTR:
      SetString(Result, AStrRet.cStr, lStrLenA(AStrRet.cStr));
    STRRET_OFFSET:
      begin
        P := @PIDL.mkid.abID[AStrRet.uOffset - SizeOf(PIDL.mkid.cb)];
        SetString(Result, P, PIDL.mkid.cb - AStrRet.uOffset);
      end;
    STRRET_WSTR:
      if Assigned(AStrRet.pOleStr) then
        Result := AStrRet.pOleStr;
  end;
  { This is a hack bug fix to get around Windows Shell Controls returning spurious "?"s in date/time detail fields }
  if (Length(Result) > 1) and (Result[1] = '?') and CharInSet(Result[2], ['0'..'9']) then
    Result := acStringReplace(Result, '?', '');
end;

class function TPIDLHelper.FilesToShellListStream(AFiles: TACLStringList; out AStream: TMemoryStream): Boolean;

  function GetCommonFilePath(AFiles: TACLStringList): string;
  begin
    Result := acExtractFilePath(AFiles[0]);
    for var I := 1 to AFiles.Count - 1 do
    begin
      if not acGetMinimalCommonPath(Result, AFiles[I]) then
        Exit(EmptyStr);
    end;
  end;

  function GetRootFolderPIDL(const ACommonPath: string): PItemIDList;
  begin
    if ACommonPath <> '' then
      Result := GetFolderPIDL(0, ACommonPath)
    else
      Result := GetDesktopPIDL;
  end;

var
  AOffsets: array of UInt;
  APIDL: PItemIDList;
  APIDLSize: Integer;
  ARootPIDL: PItemIDList;
  ARootPIDLSize: Integer;
  I: Integer;
begin
  Result := False;
  if AFiles.Count = 0 then
    Exit;

  ARootPIDL := GetRootFolderPIDL(GetCommonFilePath(AFiles));
  if ARootPIDL <> nil then
  try
    AStream := TMemoryStream.Create;

    // write the CIDA structure
    SetLength(AOffsets, AFiles.Count + 1);
    AStream.WriteInt32(AFiles.Count);
    AStream.WriteBuffer(AOffsets[0], SizeOf(AOffsets[0]) * Length(AOffsets));

    // Root
    AOffsets[0] := AStream.Position;
    ARootPIDLSize := GetPIDLSize(ARootPIDL);
    AStream.WriteBuffer(ARootPIDL^, ARootPIDLSize);
    Dec(ARootPIDLSize, SizeOf(Word));

    // Files
    for I := 0 to AFiles.Count - 1 do
    begin
      APIDL := GetFolderPIDL(0, AFiles[I]);
      try
        if APIDL = nil then
        begin
          FreeAndNil(AStream);
          Exit(False);
        end;

        AOffsets[I + 1] := AStream.Position;
        APIDLSize := GetPIDLSize(APIDL);
        if not ((APIDLSize >= ARootPIDLSize) and CompareMem(APIDL, ARootPIDL, ARootPIDLSize)) then
        begin
          FreeAndNil(AStream);
          Exit(False);
        end;

        AStream.WriteBuffer((PByte(APIDL) + ARootPIDLSize)^, APIDLSize - ARootPIDLSize);
      finally
        DisposePIDL(APIDL);
      end;
    end;

    AStream.Position := SizeOf(UInt);
    AStream.WriteBuffer(AOffsets[0], SizeOf(AOffsets[0]) * Length(AOffsets));
    AStream.Position := AStream.Size;
  finally
    DisposePIDL(ARootPIDL);
  end;
end;

class function TPIDLHelper.ShellListStreamToFiles(AStream: TCustomMemoryStream; out AFiles: TACLStringList): Boolean;
var
  ACount: Integer;
  AFileName: string;
  AOffsets: array of UInt;
  ARootPath: IShellFolder;
  ARootPIDL: PItemIDList;
  I: Integer;
begin
  ACount := AStream.ReadInt32;
  if ACount <= 0 then Exit(False);

  SetLength(AOffsets, ACount + 1);
  AStream.ReadBuffer(AOffsets[0], SizeOf(AOffsets[0]) * Length(AOffsets));

  ARootPIDL := PItemIDList(PByte(AStream.Memory) + AOffsets[0]);
  ARootPath := TACLShellFolder.Root.GetChild(ARootPIDL);
  if ARootPath = nil then
    Exit(False);

  AFiles := nil;
  for I := 1 to ACount do
  begin
    AFileName := GetDisplayName(ARootPath, PItemIDList(PByte(AStream.Memory) + AOffsets[I]), SHGDN_FORPARSING);
    if AFileName <> '' then
    begin
      if AFiles = nil then
      begin
        AFiles := TACLStringList.Create;
        AFiles.EnsureCapacity(ACount - I);
      end;
      AFiles.Add(acSimplifyLongFileName(AFileName));
    end;
  end;

  Result := AFiles <> nil;
end;
{$ENDIF}

{ TACLRecycleBin }

class function TACLRecycleBin.Delete(AFilesOrFolders: TACLStringList): HRESULT;
{$IFDEF MSWINDOWS}
begin
  Result := ShellOperation(ShellEncodePaths(AFilesOrFolders),
    acEmptyStr, soDelete, [sofCanUndo, sofNoConfirmation, sofNoDialog]);
{$ELSE}
var
  LResult: HRESULT;
  I: Integer;
begin
  Result := S_OK;
  for I := 0 to AFilesOrFolders.Count - 1 do
  begin
    LResult := Delete(AFilesOrFolders[I]);
    if LResult <> S_OK then
      Result := LResult;
  end;
{$ENDIF}
  FLastError := Result;
end;

class function TACLRecycleBin.Delete(const AFileOrFolder: string): HRESULT;
{$IFDEF MSWINDOWS}
var
  LList: TACLStringList;
begin
  LList := TACLStringList.Create(AFileOrFolder);
  try
    Result := Delete(LList);
  finally
    LList.Free;
  end;
{$ELSE}
begin
  Result := gioTrash(AFileOrFolder, FLastErrorText);
  FLastError := Result;
{$ENDIF}
end;

class function TACLRecycleBin.GetLastErrorText: string;
begin
{$IFDEF MSWINDOWS}
  FLastErrorText := '';
  if HResultFacility(LastError) = FACILITY_WIN32 then
    FLastErrorText := SysErrorMessage(HResultCode(LastError));
{$ENDIF}
  if FLastErrorText <> '' then
    Result := FLastErrorText
  else
    Result := IntToHex(LastError);
end;

class function TACLRecycleBin.Restore(const AFileOrFolder: string): HRESULT;
{$IFDEF MSWINDOWS}
var
  LRecycleBin: IShellFolder2;
  LRecycleBinPIDL: PItemIDList;

  function GetOriginalFileName(AItem: PItemIDList): string;
  var
    ADetails: TShellDetails;
    AFileName: string;
  begin
    Result := acEmptyStr;
    ZeroMemory(@ADetails, SizeOf(ADetails));
    if Succeeded(LRecycleBin.GetDetailsOf(AItem, 0, ADetails)) then
    begin
      AFileName := TPIDLHelper.StrRetToString(AItem, ADetails.str);
      if acExtractFileExt(AFileName) = '' then // когда отображение расширений отключено в Проводнике
        AFileName := AFileName + acExtractFileExt(TPIDLHelper.GetDisplayName(LRecycleBin, AItem, SIGDN_FILESYSPATH));
      if Succeeded(LRecycleBin.GetDetailsOf(AItem, 1, ADetails)) then
        Result := IncludeTrailingPathDelimiter(TPIDLHelper.StrRetToString(AItem, ADetails.str)) + AFileName;
    end;
  end;

  function Undelete(AItem: PItemIDList): HRESULT; overload;
  var
    ACommandInfo: TCMInvokeCommandInfo;
    AContextMenu: IContextMenu;
  begin
    Result := LRecycleBin.GetUIObjectOf(0, 1, AItem, IContextMenu, nil, AContextMenu);
    if Succeeded(Result) then
    begin
      ZeroMemory(@ACommandInfo, SizeOf(ACommandInfo));
      ACommandInfo.cbSize := SizeOf(ACommandInfo);
      ACommandInfo.lpVerb := 'undelete';
      ACommandInfo.nShow := SW_SHOWNORMAL;
      Result := AContextMenu.InvokeCommand(ACommandInfo);
    end;
  end;

  function Undelete: HRESULT; overload;
  const
    SHCONTF_FLAGS = SHCONTF_FOLDERS or SHCONTF_NONFOLDERS or SHCONTF_INCLUDEHIDDEN;
  var
    ADesktop: IShellFolder;
    AFetched: Cardinal;
    AItem: PItemIDList;
    AItems: IEnumIDList;
  begin
    Result := E_NOINTERFACE;
    if Succeeded(SHGetSpecialFolderLocation(0, CSIDL_BITBUCKET, LRecycleBinPIDL)) then
    try
      if Failed(SHGetDesktopFolder(ADesktop)) then
        Exit(E_NOINTERFACE);
      if Failed(ADesktop.BindToObject(LRecycleBinPIDL, nil, IShellFolder2, LRecycleBin)) then
        Exit(E_NOINTERFACE);
      if Succeeded(LRecycleBin.EnumObjects(0, SHCONTF_FLAGS, AItems)) then
      begin
        AFetched := 0;
        while Succeeded(AItems.Next(1, AItem, AFetched)) and (AFetched = 1) do
        begin
          if acSameText(AFileOrFolder, GetOriginalFileName(AItem)) then
            Exit(Undelete(AItem));
        end;
      end;
      Result := E_INVALIDARG;
    finally
      TPIDLHelper.DisposePIDL(LRecycleBinPIDL);
    end;
  end;

begin
  Result := Undelete;
{$ELSE}
begin
  Result := gioUntrash(acExcludeTrailingPathDelimiter(AFileOrFolder), FLastErrorText);
{$ENDIF}
  FLastError := Result;
end;

end.
