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

{$I ACL.Config.inc} // FPC:NotImplemented

interface

{$IFDEF MSWINDOWS}
uses
  Winapi.ActiveX,
  Winapi.ShellApi,
  Winapi.ShlObj,
  Winapi.Windows,
  // System
  System.Classes,
  System.Contnrs,
  System.Generics.Collections,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Geometry,
  ACL.Utils.Common,
  ACL.Utils.FileSystem;
{$ENDIF}

const
  acMailToPrefix = 'mailto:';

{$IFDEF MSWINDOWS}
type
  TShellOperationFlag = (sofCanUndo, sofNoDialog, sofNoConfirmation);
  TShellOperationFlags = set of TShellOperationFlag;

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
    function GetDisplayName: UnicodeString;
    function GetLibrarySources: TACLStringList;
    function GetPath: UnicodeString;
    function GetPathForParsing: UnicodeString;
  protected
    class destructor Destroy;
    function GetChild(ID: PItemIDList): IShellFolder;
    function ParentShellFolder: IShellFolder;
  public
    constructor Create(AParent: TACLShellFolder; ID: PItemIDList);
    constructor CreateSpecial(ID: PItemIDList);
    destructor Destroy; override;
    function Compare(AFolder: TACLShellFolder): Integer;
    function GetUIObjectOf(AOwner: HWND; const IID: TGUID; out AObject): Boolean;
    function HasChildren: Boolean;
    function IsFileSystemPath: Boolean;
    function IsFolder: Boolean;
    function IsLibrary: Boolean;
    class function Root: TACLShellFolder;
    // Properties
    property DisplayName: UnicodeString read GetDisplayName;
    property Parent: TACLShellFolder read FParent;
    property Path: UnicodeString read GetPath;
    property PathForParsing: UnicodeString read GetPathForParsing;
    // Library
    property LibrarySources: TACLStringList read GetLibrarySources;
    // ShellObjects
    property AbsoluteID: PItemIDLIst read FFullPIDL;
    property ID: PItemIDLIst read FPIDL;
    property FullPIDL: PItemIDList read FFullPIDL;
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
    QuickAccessPath = 'shell:::{679F85CB-0220-4080-B29B-5540CC05AAB6}';
  public
    class function CreatePIDLList(ID: PItemIDList): TList;
    class function GetDisplayName(AParentFolder: IShellFolder; PIDL: PItemIDList; AFlags: DWORD): UnicodeString;
    class function GetHasChildren(AParentfolder: IShellFolder; PIDL: PItemIDList): Boolean;
    class function StrRetToString(PIDL: PItemIDList; AStrRet: TStrRet; AFlag: UnicodeString = ''): UnicodeString;

    // https://docs.microsoft.com/en-us/windows/win32/shell/clipboard#cfstr_shellidlist
    class function FilesToShellListStream(AFiles: TACLStringList; out AStream: TMemoryStream): Boolean;
    class function ShellListStreamToFiles(AStream: TCustomMemoryStream; out AFiles: TACLStringList): Boolean;

    class function ConcatPIDLs(IDList1, IDList2: PItemIDList): PItemIDList;
    class function CopyPIDL(IDList: PItemIDList): PItemIDList;
    class function CreatePIDL(ASize: Integer): PItemIDList;
    class procedure DestroyPIDLList(var List: TList);
    class procedure DisposePIDL(var PIDL: PItemIDList);
    class function GetDesktopPIDL: PItemIDList;
    class function GetFolderPIDL(Handle: HWND; const APath: UnicodeString): PItemIDList;
    class function GetNextPIDL(IDList: PItemIDList): PItemIDList;
    class function GetPIDLSize(IDList: PItemIDList): Integer;
    class procedure StripLastID(IDList: PItemIDList);
  end;

// Shell - Deleting
function ShellDelete(AFilesOrFolders: TACLStringList;
  AOptions: TShellOperationFlags = [sofCanUndo]): Boolean; overload;
function ShellDelete(const AFileOrFolder: string;
  AOptions: TShellOperationFlags = [sofCanUndo, sofNoDialog, sofNoConfirmation]): Boolean; overload;
function ShellUndelete(const AOriginalFileOrFolder: UnicodeString): HRESULT;

// Shell - Executing
function ShellExecute(const AFileName, AParameters: UnicodeString): Boolean; overload;
function ShellExecute(const AFileName: UnicodeString): Boolean; overload;
function ShellExecuteURL(const ALink: UnicodeString): Boolean;
function ShellJumpToFile(const AFileName: UnicodeString): Boolean;

// Shell - System Paths
function ShellPathAppData: UnicodeString;
function ShellPathDesktop: UnicodeString;
function ShellPathMyDocuments: UnicodeString;
function ShellPathMyMusic: UnicodeString;
function ShellPathSystem32: UnicodeString;
{$IFDEF CPUX64}
function ShellPathSystem32WOW64: UnicodeString;
{$ENDIF}
function ShellPath(CLSID: Integer): UnicodeString;

// Shell - Libraries
procedure ShellExpandPath(const APath: UnicodeString; AReceiver: IStringReceiver);
function ShellIsLibraryPath(const APath: UnicodeString): Boolean;

// Shell - Links
function ShellCreateLink(const ALinkFileName, AFileName: UnicodeString): Boolean;
function ShellParseLink(const ALink: UnicodeString; out AFileName: UnicodeString): Boolean;

function ShellGetFreeSpace(const AFileName: string): Int64;
function ShellLastErrorCode: Integer;
function ShellShowHiddenByDefault: Boolean;
function ShellShutdown(AMode: TShellShutdownMode): Boolean;

procedure UpdateShellCache;
{$ELSE}
function ShellExecute(const AFileName: string): Boolean;
function ShellExecuteURL(const AFileName: string): Boolean;
{$ENDIF}
implementation
{$IFDEF MSWINDOWS}
uses
  System.SysUtils,
  System.Math,
  System.Win.ComObj,
  // ACL
  ACL.Utils.Strings,
  ACL.Utils.Stream,
  ACL.Utils.Registry;

var
  FShellLastErrorCode: Integer;

//------------------------------------------------------------------------------
// Shell - General
//------------------------------------------------------------------------------

{$REGION ' General '}
type
  TShellOperation = (soMove, soCopy, soDelete, soRename);

function ShellEncodePaths(const APaths: TACLStringList): string;
var
  LBuilder: TACLStringBuilder;
begin
  LBuilder := TACLStringBuilder.Create;
  try
    for var I := 0 to APaths.Count - 1 do
      LBuilder.Append(ExcludeTrailingPathDelimiter(APaths[I])).Append(#0);
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function ShellOperation(const ASourceList, ADestList: UnicodeString;
  const AOperation: TShellOperation; const AFlags: TShellOperationFlags): Boolean;
const
  OperationMap: array[TShellOperation] of Integer = (FO_MOVE, FO_COPY, FO_DELETE, FO_RENAME);
var
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
  FShellLastErrorCode := SHFileOperationW(AStruct);
  Result := (FShellLastErrorCode = 0) and not AStruct.fAnyOperationsAborted;
end;

function ShellShutdown(AMode: TShellShutdownMode): Boolean;

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
end;

function ShellLastErrorCode: Integer;
begin
  Result := FShellLastErrorCode;
end;

function ShellShowHiddenByDefault: Boolean;
var
  AKey: THandle;
begin
  AKey := acRegOpenRead(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced');
  Result := acRegReadInt(AKey, 'Hidden') = 1;
  acRegClose(AKey);
end;

procedure UpdateShellCache;
begin
  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST or SHCNF_FLUSH, nil, nil);
  Sleep(1000);
end;

{$ENDREGION}

//------------------------------------------------------------------------------
// Shell - Deleting
//------------------------------------------------------------------------------

{$REGION ' Deleting '}

function ShellDelete(AFilesOrFolders: TACLStringList;
  AOptions: TShellOperationFlags = [sofCanUndo]): Boolean;
begin
  Result := ShellOperation(ShellEncodePaths(AFilesOrFolders), '', soDelete, AOptions);
end;

function ShellDelete(const AFileOrFolder: string;
  AOptions: TShellOperationFlags = [sofCanUndo, sofNoDialog, sofNoConfirmation]): Boolean;
var
  LList: TACLStringList;
begin
  LList := TACLStringList.Create(AFileOrFolder);
  try
    Result := ShellDelete(LList, AOptions);
  finally
    LList.Free;
  end;
end;

function ShellUndelete(const AOriginalFileOrFolder: UnicodeString): HRESULT;
var
  ARecycleBin: IShellFolder2;
  ARecycleBinPIDL: PItemIDList;

  function GetOriginalFileName(AItem: PItemIDList): string;
  var
    ADetails: TShellDetails;
    AFileName: string;
  begin
    Result := acEmptyStr;
    ZeroMemory(@ADetails, SizeOf(ADetails));
    if Succeeded(ARecycleBin.GetDetailsOf(AItem, 0, ADetails)) then
    begin
      AFileName := TPIDLHelper.StrRetToString(AItem, ADetails.str);
      if acExtractFileExt(AFileName) = '' then // когда отображение расширений отключено в Проводнике
        AFileName := AFileName + acExtractFileExt(TPIDLHelper.GetDisplayName(ARecycleBin, AItem, SIGDN_FILESYSPATH));
      if Succeeded(ARecycleBin.GetDetailsOf(AItem, 1, ADetails)) then
        Result := IncludeTrailingPathDelimiter(TPIDLHelper.StrRetToString(AItem, ADetails.str)) + AFileName;
    end;
  end;

  function Undelete(AItem: PItemIDList): HRESULT;
  var
    ACommandInfo: TCMInvokeCommandInfo;
    AContextMenu: IContextMenu;
  begin
    Result := ARecycleBin.GetUIObjectOf(0, 1, AItem, IContextMenu, nil, AContextMenu);
    if Succeeded(Result) then
    begin
      ZeroMemory(@ACommandInfo, SizeOf(ACommandInfo));
      ACommandInfo.cbSize := SizeOf(ACommandInfo);
      ACommandInfo.lpVerb := 'undelete';
      ACommandInfo.nShow := SW_SHOWNORMAL;
      Result := AContextMenu.InvokeCommand(ACommandInfo);
    end;
  end;

var
  ADesktop: IShellFolder;
  AFetched: Cardinal;
  AItem: PItemIDList;
  AItems: IEnumIDList;
begin
  if Succeeded(SHGetSpecialFolderLocation(0, CSIDL_BITBUCKET, ARecycleBinPIDL)) then
  try
    if Failed(SHGetDesktopFolder(ADesktop)) then
      Exit(E_NOINTERFACE);
    if Failed(ADesktop.BindToObject(ARecycleBinPIDL, nil, IShellFolder2, ARecycleBin)) then
      Exit(E_NOINTERFACE);
    if Succeeded(ARecycleBin.EnumObjects(0, SHCONTF_FOLDERS or SHCONTF_NONFOLDERS or SHCONTF_INCLUDEHIDDEN, AItems)) then
    begin
      AFetched := 0;
      while Succeeded(AItems.Next(1, AItem, AFetched)) and (AFetched = 1) do
      begin
        if acSameText(AOriginalFileOrFolder, GetOriginalFileName(AItem)) then
          Exit(Undelete(AItem));
      end;
    end;
  finally
    TPIDLHelper.DisposePIDL(ARecycleBinPIDL);
  end;
  Result := E_INVALIDARG;
end;

{$ENDREGION}

//------------------------------------------------------------------------------
// Shell - Executing
//------------------------------------------------------------------------------

{$REGION ' Executing '}

function ShellExecute(const AFileName: UnicodeString): Boolean;
begin
  Result := ShellExecute(AFileName, '');
end;

function ShellExecute(const AFileName, AParameters: UnicodeString): Boolean; overload;
begin
  if AFileName = '' then
    Exit(False);
  if IsWine and (acIsUrlFileName(AFileName) or acBeginsWith(AFileName, acMailToPrefix)) then
    Result := ShellExecute('winebrowser', AFileName)
  else
    Result := ShellExecuteW(0, 'open', PWideChar(AFileName), PWideChar(AParameters), '', SW_SHOW) >= 32;
end;

function ShellExecuteURL(const ALink: UnicodeString): Boolean;
begin
  if ALink = '' then
    Result := False
  else
    if (Pos(UnicodeString('//'), ALink) = 0) and not acDirectoryExists(ALink) then
      Result := ShellExecute('http://' + ALink)
    else
      Result := ShellExecute(ALink);
end;

function ShellJumpToFile(const AFileName: UnicodeString): Boolean;
var
 IL: PItemIDList;
begin
  Result := False;
  if AFileName <> '' then
  begin
    if acIsUrlFileName(AFileName) then
      Result := ShellExecute(AFileName)
    else
    begin
      IL := ILCreateFromPathW(PWideChar(AFileName));
      if IL <> nil then
      try
        SHOpenFolderAndSelectItems(IL, 0, nil, 0);
        Result := True;
      finally
        ILFree(IL);
      end;
    end;
  end;
end;

{$ENDREGION}

//------------------------------------------------------------------------------
// Shell - System Paths
//------------------------------------------------------------------------------

{$REGION ' System Paths '}

function ShellPath(CLSID: Integer): UnicodeString;
var
  ABuf: TFilePath;
begin
  if SHGetSpecialFolderPathW(0, @ABuf[0], CLSID, False) then
    Result := acIncludeTrailingPathDelimiter(ABuf)
  else
    Result := acTempPath;
end;

function ShellPathAppData: UnicodeString;
begin
  Result := ShellPath(CSIDL_APPDATA);
end;

function ShellPathDesktop: UnicodeString;
begin
  Result := ShellPath(CSIDL_DESKTOP);
end;

function ShellPathMyDocuments: UnicodeString;
begin
  Result := ShellPath(CSIDL_PERSONAL);
end;

function ShellPathMyMusic: UnicodeString;
begin
  Result := ShellPath(CSIDL_MYMUSIC);
end;

function ShellPathSystem32: UnicodeString;
var
  ABuf: TFilePath;
begin
  acClearFilePath(ABuf);
  GetSystemDirectoryW(@ABuf[0], Length(ABuf));
  Result := acIncludeTrailingPathDelimiter(ABuf);
end;

{$IFDEF CPUX64}
function ShellPathSystem32WOW64: UnicodeString;
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
{$ENDIF}

{$ENDREGION}

//------------------------------------------------------------------------------
// Shell - Libraries
//------------------------------------------------------------------------------

{$REGION ' Libraries '}

function ShellIsLibraryPath(const APath: UnicodeString): Boolean;
begin
  Result := acBeginsWith(APath, '::');
end;

function ShellReadLibrary(const APathForParsing: UnicodeString; AReceiver: IStringReceiver): Boolean;
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
end;

procedure ShellExpandPath(const APath: UnicodeString; AReceiver: IStringReceiver);
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

function ShellCreateLinkObject(out AObject: IShellLinkW): Boolean;
begin
  CoInitialize(nil);
  Result := Succeeded(CoCreateInstance(CLSID_ShellLink, nil,
    CLSCTX_INPROC_SERVER or CLSCTX_LOCAL_SERVER, IShellLinkW, AObject));
end;

function ShellCreateLink(const ALinkFileName, AFileName: UnicodeString): Boolean;
var
  ALink: IShellLinkW;
  ALinkFile: IPersistFile;
  ATempFileName: UnicodeString;
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

function ShellParseLink(const ALink: UnicodeString; out AFileName: UnicodeString): Boolean;
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

{$ENDREGION}

//------------------------------------------------------------------------------
// Shell - Drives
//------------------------------------------------------------------------------

{$REGION ' Drives '}

function ShellGetFreeSpace(const AFileName: string): Int64;
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
end;

{$ENDREGION}

{ TACLShellFolder }

constructor TACLShellFolder.Create(AParent: TACLShellFolder; ID: PItemIDList);
var
  ADesktopID: PItemIDList;
begin
  inherited Create;
  FPIDL := TPIDLHelper.CopyPIDL(ID);
  if AParent <> nil then
  begin
    FParent := AParent;
    FShellFolder := AParent.GetChild(ID);
    FFullPIDL := TPIDLHelper.ConcatPIDLs(AParent.AbsoluteID, ID);
  end
  else
  begin
    OleCheck(SHGetDesktopFolder(FShellFolder));
    ADesktopID := TPIDLHelper.GetDesktopPIDL;
    try
      FFullPIDL := TPIDLHelper.ConcatPIDLs(ADesktopID, ID);
    finally
      TPIDLHelper.DisposePIDL(ADesktopID);
    end;
  end;
end;

constructor TACLShellFolder.CreateSpecial(ID: PItemIDList);
begin
  FPIDL := TPIDLHelper.CopyPIDL(ID);
  FFullPIDL := TPIDLHelper.CopyPIDL(ID);
  OleCheck(Root.ShellFolder.BindToObject(FPIDL, nil, IID_IShellFolder, FShellFolder));
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

function TACLShellFolder.Compare(AFolder: TACLShellFolder): Integer;
begin
  Result := SmallInt(ParentShellFolder.CompareIDs(0, ID, AFolder.ID));
end;

function TACLShellFolder.GetUIObjectOf(AOwner: HWND; const IID: TGUID; out AObject): Boolean;
begin
  Result := Succeeded(ShellFolder.GetUIObjectOf(AOwner, 1, FPIDL, IID, nil, AObject));
end;

function TACLShellFolder.HasChildren: Boolean;
begin
  Result := TPIDLHelper.GetHasChildren(ParentShellFolder, ID);
end;

function TACLShellFolder.IsFileSystemPath: Boolean;
begin
  Result := GetAttributes and (SFGAO_FILESYSANCESTOR or SFGAO_FILESYSTEM) <> 0;
end;

function TACLShellFolder.IsFolder: Boolean;
var
  LAttrs: Cardinal;
begin
  LAttrs := GetAttributes;
  Result :=
    (LAttrs and (SFGAO_FILESYSANCESTOR or SFGAO_FILESYSTEM) <> 0) and
    (LAttrs and (SFGAO_STREAM or SFGAO_FOLDER) <> (SFGAO_STREAM or SFGAO_FOLDER));
end;

function TACLShellFolder.IsLibrary: Boolean;
begin
  Result := LibrarySources.Count > 0;
end;

//function TACLShellFolder.Rename(const NewName: UnicodeString): boolean;
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
var
  ADesktopPIDL: PItemIDList;
begin
  if FDesktopFolder = nil then
  begin
    ADesktopPIDL := TPIDLHelper.GetDesktopPIDL;
    if ADesktopPIDL <> nil then
    try
      FDesktopFolder := TACLShellFolder.Create(nil, ADesktopPIDL);
    finally
      TPIDLHelper.DisposePIDL(ADesktopPIDL);
    end;
  end;
  Result := FDesktopFolder;
end;

function TACLShellFolder.GetChild(ID: PItemIDList): IShellFolder;
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
end;

function TACLShellFolder.ParentShellFolder: IShellFolder;
begin
  if FParent <> nil then
    Result := FParent.ShellFolder
  else
    OLECheck(SHGetDesktopFolder(Result));
end;

function TACLShellFolder.GetAttributes: Cardinal;
begin
  Result := SFGAO_STORAGECAPMASK;
  if Failed(ParentShellFolder.GetAttributesOf(1, FPIDL, Result)) then
    Result := 0;
end;

function TACLShellFolder.GetDisplayName: UnicodeString;
begin
  Result := TPIDLHelper.GetDisplayName(ParentShellFolder, ID, SHGDN_INFOLDER);
end;

function TACLShellFolder.GetLibrarySources: TACLStringList;
begin
  if FLibrarySources = nil then
  begin
    FLibrarySources := TACLStringList.Create;
    if Parent <> nil then
    begin
      if GetAttributes and (SFGAO_FILESYSANCESTOR or SFGAO_FILESYSTEM) = SFGAO_FILESYSANCESTOR then
        ShellReadLibrary(PathForParsing, FLibrarySources);
    end;
  end;
  Result := FLibrarySources;
end;

function TACLShellFolder.GetPath: UnicodeString;
begin
  if GetAttributes and SFGAO_FILESYSTEM <> 0 then
    Result := PathForParsing
  else
    Result := EmptyStr;
end;

function TACLShellFolder.GetPathForParsing: UnicodeString;
begin
  Result := TPIDLHelper.GetDisplayName(Root.ShellFolder, AbsoluteID, SHGDN_FORPARSING);
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

class function TPIDLHelper.CreatePIDLList(ID: PItemIDList): TList;
var
  TempID: PItemIDList;
begin
  Result := TList.Create;
  TempID := ID;
  while TempID.mkid.cb <> 0 do
  begin
    TempID := TPIDLHelper.CopyPIDL(TempID);
    Result.Insert(0, TempID); //0 = lowest level PIDL.
    StripLastID(TempID);
  end;
end;

class function TPIDLHelper.GetDisplayName(AParentFolder: IShellFolder;
  PIDL: PItemIDList; AFlags: DWORD): UnicodeString;
var
  AStrRet: TStrRet;
begin
  FillChar(AStrRet, SizeOf(AStrRet), 0);
  AParentFolder.GetDisplayNameOf(PIDL, AFlags, AStrRet);
  Result := StrRetToString(PIDL, AStrRet);
end;

class function TPIDLHelper.GetHasChildren(AParentfolder: IShellFolder; PIDL: PItemIDList): Boolean;
var
  AFlags: LongWord;
begin
  AFlags := SFGAO_CONTENTSMASK;
  if Succeeded(AParentFolder.GetAttributesOf(1, PIDL, AFlags)) then
    Result := AFlags and SFGAO_HASSUBFOLDER <> 0
  else
    Result := False;
end;

class function TPIDLHelper.StrRetToString(PIDL: PItemIDList; AStrRet: TStrRet; AFlag: UnicodeString = ''): UnicodeString;
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

class function TPIDLHelper.ConcatPIDLs(IDList1, IDList2: PItemIDList): PItemIDList;
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
end;

class function TPIDLHelper.CopyPIDL(IDList: PItemIDList): PItemIDList;
var
  Size: Integer;
begin
  Size := GetPIDLSize(IDList);
  Result := CreatePIDL(Size);
  if Assigned(Result) then
    CopyMemory(Result, IDList, Size);
end;

class function TPIDLHelper.CreatePIDL(ASize: Integer): PItemIDList;
var
  Malloc: IMalloc;
begin
  OleCheck(SHGetMalloc(Malloc));
  Result := Malloc.Alloc(ASize);
  if Result <> nil then
    FillChar(Result^, ASize, 0);
end;

class procedure TPIDLHelper.DestroyPIDLList(var List: TList);
var
  I: Integer;
begin
  if Assigned(List) then
  begin
    for I := 0 to List.Count - 1 do
      DisposePIDL(PItemIDList(List.List[I]));
    FreeAndNil(List);
  end;
end;

class procedure TPIDLHelper.DisposePIDL(var PIDL: PItemIDList);
//var
//  MAlloc: IMAlloc;
begin
  if Assigned(PIDL) then
  begin
//    OLECheck(SHGetMAlloc(MAlloc));
//    MAlloc.Free(PIDL);
    CoTaskMemFree(PIDL);
    PIDL := nil;
  end;
end;

class function TPIDLHelper.GetDesktopPIDL: PItemIDList;
begin
  OleCheck(SHGetSpecialFolderLocation(0, CSIDL_DESKTOP, Result));
end;

class function TPIDLHelper.GetFolderPIDL(Handle: HWND; const APath: UnicodeString): PItemIDList;
var
  AEaten, AAttr: DWORD;
begin
  if Failed(TACLShellFolder.Root.ShellFolder.ParseDisplayName(Handle, nil, PWideChar(APath), AEaten, Result, AAttr)) then
    Result := nil;
end;

class function TPIDLHelper.GetNextPIDL(IDList: PItemIDList): PItemIDList;
begin
  Result := IDList;
  Inc(PByte(Result), IDList^.mkid.cb);
end;

class function TPIDLHelper.GetPIDLSize(IDList: PItemIDList): Integer;
begin
  Result := 0;
  if Assigned(IDList) then
  begin
    Result := SizeOf(IDList^.mkid.cb);
    while IDList^.mkid.cb <> 0 do
    begin
      Result := Result + IDList^.mkid.cb;
      IDList := GetNextPIDL(IDList);
    end;
  end;
end;

class procedure TPIDLHelper.StripLastID(IDList: PItemIDList);
var
  MarkerID: PItemIDList;
begin
  MarkerID := IDList;
  if Assigned(IDList) then
  begin
    while IDList.mkid.cb <> 0 do
    begin
      MarkerID := IDList;
      IDList := TPIDLHelper.GetNextPIDL(IDList);
    end;
    MarkerID.mkid.cb := 0;
  end;
end;
{$ELSE}
function ShellExecute(const AFileName: string): Boolean;
begin
  {$MESSAGE WARN 'Commented'}
  Result := False;
end;

function ShellExecuteURL(const AFileName: string): Boolean;
begin
  {$MESSAGE WARN 'Commented'}
  Result := False;
end;

{$ENDIF}
end.
