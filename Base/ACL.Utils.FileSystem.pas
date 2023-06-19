{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*           FileSystem Utilities            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.FileSystem;

{$I ACL.Config.inc}
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ELSE}
  System.IOUtils,
{$ENDIF}
  // System
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils,
  System.Types,
  // ACL
  ACL.Classes,
  ACL.Classes.ByteBuffer,
  ACL.Classes.StringList,
  ACL.Parsers,
  ACL.Utils.Common,
  ACL.Utils.Stream;

const
  sFileExtDelims = ' .\/:';
  sFilePathDelims = ':\/';
  sLongFileNamePrefix = '\\?\';
  sLongFileNamePrefixUNC = sLongFileNamePrefix + 'UNC\';
  sUncPrefix = '\\';
  sUnixPathDelim = '/';
  sWindowPathDelim = '\';

{$IFNDEF MSWINDOWS}
  INVALID_FILE_ATTRIBUTES = DWORD($FFFFFFFF);
{$ENDIF}

  MAX_LONG_PATH = Word.MaxValue;

type
  TFileLongPath = array [0..MAX_LONG_PATH - 1] of WideChar;
  TFilePath = array[0..MAX_PATH] of WideChar;

  { TACLFindFileInfo }

  TACLFindFileObject = (ffoFile, ffoFolder);
  TACLFindFileObjects = set of TACLFindFileObject;

  TACLFindFileInfo = class
  private
    FFileName: UnicodeString;
    FFileObject: TACLFindFileObject;
    FFilePath: UnicodeString;
  {$IFDEF MSWINDOWS}
    FFindData: WIN32_FIND_DATAW;
    FFindHandle: THandle;
  {$ELSE}
    FFindData: TSearchRec;
  {$ENDIF}
    FFindExts: UnicodeString;
    FFindObjects: TACLFindFileObjects;

    function Check: Boolean;
    function GetFileSize: Int64;
    function GetFullFileName: UnicodeString;
    function IsInternal: Boolean; inline;
  public
    destructor Destroy; override;
    //
    property FileName: UnicodeString read FFileName;
    property FileObject: TACLFindFileObject read FFileObject;
    property FileSize: Int64 read GetFileSize;
    property FullFileName: UnicodeString read GetFullFileName;
  {$IFDEF MSWINDOWS}
    property FileAttrs: Cardinal read FFindData.dwFileAttributes;
    property FileCreationTime: TFileTime read FFindData.ftCreationTime;
    property FileLastAccessTime: TFileTime read FFindData.ftLastAccessTime;
    property FileLastWriteTime: TFileTime read FFindData.ftLastWriteTime;
  {$ELSE}
    property FileAttrs: Integer read FFindData.Attr;
  {$ENDIF}
  end;

  TACLEnumFileProc = reference to procedure (const Info: TACLFindFileInfo);

  { TACLSearch }

  TACLSearchDirFilter = procedure (Sender: TObject; const ADirName: UnicodeString; var ACanProcess: Boolean) of object;

  TACLSearch = class
  strict private
    FActive: Boolean;
    FDest: IStringReceiver;
    FExts: UnicodeString;
    FOnDir: TACLSearchDirFilter;
    FPath: UnicodeString;
    FRecurse: Boolean;

    procedure SetPath(const AValue: UnicodeString);
  protected
    function CanScanDirectory(const Dir: UnicodeString): Boolean;
    procedure ScanDirectory(const Dir: UnicodeString);
    //
    property Dest: IStringReceiver read FDest;
  public
    constructor Create(const AReceiver: IStringReceiver); virtual;
    destructor Destroy; override;
    procedure Start(ARecurse: Boolean = True);
    procedure Stop;
    // Properties
    property Active: Boolean read FActive;
    property Exts: UnicodeString read FExts write FExts;
    property OnDir: TACLSearchDirFilter read FOnDir write FOnDir;
    property Path: UnicodeString read FPath write SetPath;
  end;

  { TACLSearchPaths }

  TACLSearchPaths = class(TACLLockablePersistent)
  strict private
    FList: TACLStringList;

    FOnChange: TNotifyEvent;

    function GetCount: Integer;
    function GetPath(Index: Integer): UnicodeString;
    function GetRecursive(Index: Integer): Boolean;
    procedure SetPath(Index: Integer; const Value: UnicodeString);
    procedure SetRecursive(AIndex: Integer; AValue: Boolean);
  protected
    procedure DoAssign(ASource: TPersistent); override;
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
    function ContainsPathPart(const APath: UnicodeString): Boolean;
  public
    constructor Create; overload; virtual;
    constructor Create(AChangeEvent: TNotifyEvent); overload;
    destructor Destroy; override;
    procedure Add(const APath: UnicodeString; ARecursive: Boolean);
    procedure Assign(const ASource: string); reintroduce; overload; virtual;
    procedure Clear; virtual;
    function Contains(APath: string): Boolean;
    function CreatePathList: TACLStringList; virtual;
    procedure Delete(Index: Integer);
    function ToString: string; override;
    //
    property Count: Integer read GetCount;
    property Paths[Index: Integer]: UnicodeString read GetPath write SetPath; default;
    property Recursive[Index: Integer]: Boolean read GetRecursive write SetRecursive;
  end;

  { TACLFileStream }

  TACLFileStream = class(THandleStream)
  strict private
    FFileName: string;
  protected
  {$IFDEF MSWINDOWS}
    function GetSize: Int64; override;
  {$ENDIF}
  public
    constructor Create(const AHandle: THandle); overload;
    constructor Create(const AFileName: string; Mode: Word); overload;
    constructor Create(const AFileName: string; Mode: Word; Rights: Cardinal); overload;
    destructor Destroy; override;
    class function GetFileName(AStream: TStream; out AFileName: string): Boolean;
    //
    property FileName: string read FFileName;
  end;

  { TACLBufferedFileStream }

  TACLBufferedFileStream = class(TACLBufferedStream)
  public
    constructor Create(const AFileName: string; AMode: Word;
      ABufferSize: Integer = TACLBufferedStream.DefaultBufferSize); reintroduce;
  end;

  { TACLClippedFileStream }

  TACLClippedFileStream = class(TACLSubStream)
  public
    constructor Create(const AFileName: UnicodeString; const AOffset, ASize: Int64); reintroduce;
  end;

  { TACLTemporaryFileStream }

  TACLTemporaryFileStream = class(TACLFileStream)
  public
    constructor Create(const APrefix: UnicodeString); reintroduce;
    destructor Destroy; override;
  end;

{$IFDEF MSWINDOWS}

  { TACLFileDateTimeHelper }

  TACLFileDateTimeHelper = class
  public
    class function DecodeTime(const ATime: TFileTime): TDateTime;
    class function GetCreationTime(const AFileName: UnicodeString): TDateTime;
    class function GetFileData(const AFileName: UnicodeString; out AData: TWin32FindDataW): Boolean;
    class function GetLastAccessTime(const AFileName: UnicodeString): TDateTime;
    class function GetLastEditingTime(const AFileName: UnicodeString): TDateTime;
  end;

{$ENDIF}

// Paths
function acChangeFileExt(const FileName, Extension: UnicodeString; ADoubleExt: Boolean = False): UnicodeString;
function acCompareFileNames(const AFileName1, AFileName2: UnicodeString): Integer;
{$IFDEF MSWINDOWS}
function acExpandEnvironmentStrings(const AFileName: UnicodeString): UnicodeString;
{$ENDIF}
function acExpandFileName(const AFileName: UnicodeString): UnicodeString;
function acExtractDirName(const APath: UnicodeString; ADepth: Integer = 1): UnicodeString;
function acExtractFileDir(const FileName: UnicodeString): UnicodeString;
function acExtractFileDirName(const FileName: UnicodeString): UnicodeString;
function acExtractFileDrive(const FileName: UnicodeString): UnicodeString;
function acExtractFileExt(const FileName: UnicodeString; ADoubleExt: Boolean = False): UnicodeString;
function acExtractFileFormat(const FileName: UnicodeString): UnicodeString;
function acExtractFileName(const FileName: UnicodeString): UnicodeString;
function acExtractFileNameWithoutExt(const FileName: UnicodeString): UnicodeString;
function acExtractFilePath(const FileName: UnicodeString): UnicodeString;
function acExtractFileScheme(const AFileName: UnicodeString): UnicodeString;
function acGetCurrentDir: UnicodeString;
function acGetFreeFileName(const AFileName: UnicodeString): UnicodeString;
function acGetMinimalCommonPath(var ACommonPath: UnicodeString; const AFilePath: UnicodeString): Boolean;
function acGetShortFileName(const APath: UnicodeString): UnicodeString;
function acIncludeTrailingPathDelimiter(const Path: UnicodeString): UnicodeString;
function acIsDoubleExtFile(const AFileName: UnicodeString): Boolean;
function acIsLnkFileName(const AFileName: UnicodeString): Boolean;
function acIsLocalUnixPath(const AFileName: UnicodeString): Boolean;
function acIsOurFile(const AExtsList, AFileName: UnicodeString; ADoubleExt: Boolean = False): Boolean; inline;
function acIsOurFileEx(const AExtsList, ATestExt: UnicodeString): Boolean;
function acIsRelativeFileName(const AFileName: UnicodeString): Boolean;
function acIsUncFileName(const AFileName: UnicodeString): Boolean;
function acIsUrlFileName(const AFileName: UnicodeString): Boolean;
function acLastDelimiter(const Delimiters, Str: UnicodeString): Integer; overload;
function acLastDelimiter(Delimiters, Str: PWideChar; DelimitersLength, StrLength: Integer): Integer; overload;
function acRelativeFileName(const AFileName: UnicodeString; ARootPath: UnicodeString): UnicodeString;
function acSetCurrentDir(const ADir: UnicodeString): Boolean;
function acSimplifyLongFileName(const AFileName: UnicodeString): UnicodeString;
function acTempFileName(const APrefix: UnicodeString): UnicodeString; overload;
function acTempPath: UnicodeString;
function acValidateFileName(const Name: UnicodeString; ReplacementForInvalidChars: Char = #0): UnicodeString;
function acValidateFilePath(const Name: UnicodeString): UnicodeString;
function acValidateSubPath(const Path: UnicodeString): UnicodeString;
function acUnixPathToWindows(const Path: UnicodeString): UnicodeString;
function acWindowsPathToUnix(const Path: UnicodeString): UnicodeString;

// FindFile
function acFindFile(const AFileName: UnicodeString; AFullFileName: PUnicodeString; ASize: PInt64): Boolean;
function acFindFileFirst(const APath: UnicodeString; AObjects: TACLFindFileObjects; out AInfo: TACLFindFileInfo): Boolean; overload;
function acFindFileFirst(const APath: UnicodeString; const AExts: UnicodeString; AObjects: TACLFindFileObjects; out AInfo: TACLFindFileInfo): Boolean; overload;
function acFindFileFirstMasked(const APath, AExts, AMask: UnicodeString; AObjects: TACLFindFileObjects; out AInfo: TACLFindFileInfo): Boolean; overload;
function acFindFileNext(var AInfo: TACLFindFileInfo): Boolean; overload;
procedure acFindFileClose(var AInfo: TACLFindFileInfo);
procedure acEnumFiles(const APath: UnicodeString; AObjects: TACLFindFileObjects; AProc: TACLEnumFileProc; ARecursive: Boolean = True); overload;
procedure acEnumFiles(const APath, AExts, AMask: UnicodeString; AObjects: TACLFindFileObjects; AProc: TACLEnumFileProc; ARecursive: Boolean = True); overload;
procedure acEnumFiles(const APath, AExts: UnicodeString; AList: IStringReceiver); overload;
procedure acEnumFiles(const APath, AExts: UnicodeString; AObjects: TACLFindFileObjects; AProc: TACLEnumFileProc; ARecursive: Boolean = True); overload;

// File Attributes
function acDirectoryExists(const APath: UnicodeString): Boolean;
function acFileCreate(const AFileName: UnicodeString; AMode, ARights: LongWord): THandle;
function acFileExists(const FileName: UnicodeString): Boolean;
function acFileGetAttr(const FileName: UnicodeString): Cardinal; overload;
function acFileGetAttr(const FileName: UnicodeString; out AAttrs: Cardinal): Boolean; overload;
{$IFDEF MSWINDOWS}
function acFileGetLastWriteTime(const FileName: UnicodeString): Cardinal;
{$ENDIF}
function acFileSetAttr(const FileName: UnicodeString; AAttr: Cardinal): Boolean;
function acFileSize(const FileName: UnicodeString): Int64;
{$IFDEF MSWINDOWS}
function acVolumeGetSerial(const ADrive: WideChar; out ASerialNumber: Cardinal): Boolean;
function acVolumeGetTitle(const ADrive, ADefaultTitle: UnicodeString): UnicodeString; overload;
function acVolumeGetTitle(const ADrive: UnicodeString): UnicodeString; overload;
function acVolumeGetType(const ADrive: WideChar): Cardinal;
{$ENDIF}

// Removing, Copying, Renaming
function acCopyDirectory(const ASourcePath, ATargetPath: UnicodeString; const AExts: UnicodeString = ''; ARecursive: Boolean = True): Boolean;
function acCopyDirectoryContent(ASourcePath, ATargetPath: UnicodeString; const AExts: UnicodeString = ''; ARecursive: Boolean = True): Boolean;
function acCopyFile(const ASourceFileName, ATargetFileName: UnicodeString; AFailIfExists: Boolean = True): Boolean;
function acDeleteDirectory(const APath: UnicodeString): Boolean;
function acDeleteDirectoryFull(APath: UnicodeString; ARecursive: Boolean = True): Boolean;
function acDeleteFile(const AFileName: UnicodeString): Boolean;
function acMakePath(const APath: UnicodeString): Boolean;
function acMakePathForFileName(const AFileName: UnicodeString): Boolean;
function acMoveFile(const ASourceFileName, ATargetFileName: UnicodeString): Boolean;
function acReplaceFile(const ASourceFileName, ATargetFileName: UnicodeString): Boolean; overload;
function acReplaceFile(const ASourceFileName, ATargetFileName, ABackupFileName: UnicodeString): Boolean; overload;

// Work with command line
function acSelfExeName: UnicodeString;
function acSelfPath: UnicodeString;

procedure acClearFilePath(out W: TFilePath);
procedure acClearFileLongPath(out W: TFileLongPath);
implementation

uses
{$IFDEF POSIX}
  Posix.Unistd,
{$ENDIF}
  // System
  System.Character,
  System.Math,
  System.RTLConsts,
  // ACL
  ACL.FastCode,
  ACL.FileFormats.INI,
  ACL.Math,
  ACL.Utils.Strings;

{$IFDEF MSWINDOWS}
function GetFileAttributesExW(AFileName: PChar;
  AInfoLevelId: TGetFileExInfoLevels; AFileInformation: Pointer): BOOL; stdcall; external kernel32;
{$ENDIF}

procedure acClearFilePath(out W: TFilePath);
begin
  FastZeroMem(@W[0], SizeOf(WideChar) * Length(W));
end;

procedure acClearFileLongPath(out W: TFileLongPath);
begin
  FastZeroMem(@W[0], SizeOf(WideChar) * Length(W));
end;

function MakeInt64(ALow, AHigh: Cardinal): Int64; inline;
begin
  Result := ALow;
  if AHigh > 0 then
    Result := (Int64(AHigh) shl 32) or Result;
end;

// ---------------------------------------------------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------------------------------------------------

function acIsLnkFileName(const AFileName: UnicodeString): Boolean;
begin
  Result := acSameText(acExtractFileExt(AFileName), '.lnk');
end;

function acIsLocalUnixPath(const AFileName: UnicodeString): Boolean;
begin
  Result := (acPos(sUnixPathDelim, AFileName) > 0) and not acIsUrlFileName(AFileName);
end;

function acIsPathSeparator(const C: Char): Boolean; inline;
begin
  Result := (Ord(C) = Ord(sUnixPathDelim)) or (Ord(C) = Ord(sWindowPathDelim));
end;

function acIsUncFileName(const AFileName: UnicodeString): Boolean;
begin
  Result := acBeginsWith(AFileName, sUncPrefix, False);
end;

function acIsUrlFileName(const AFileName: UnicodeString): Boolean;
var
  P: PWideChar;
begin
  P := WStrScan(PWideChar(AFileName), ':');
  Result := (P <> nil) and ((P + 1)^ = '/') and ((P + 1)^ = (P + 2)^);
//  Result := acExtractFileScheme(AFileName) <> '';
end;

function acPrepareFileName(const AFileName: UnicodeString): UnicodeString; inline;
begin
{$IFDEF MSWINDOWS}
  //#AI: https://docs.microsoft.com/en-us/windows/desktop/fileio/naming-a-file
  if Length(AFileName) >= MAX_PATH then
  begin
    if acBeginsWith(AFileName, sLongFileNamePrefix) then
      Exit(AFileName);
    if acIsUncFileName(AFileName) then
      Result := sLongFileNamePrefixUNC + Copy(AFileName, 3, MaxInt)
    else
      Result := sLongFileNamePrefix + AFileName;
  end
  else
{$ENDIF}
    Result := AFileName;
end;

function acSimplifyLongFileName(const AFileName: UnicodeString): UnicodeString;
begin
  if acBeginsWith(AFileName, sLongFileNamePrefixUNC) then
    Result := Copy(AFileName, Length(sLongFileNamePrefixUNC) + 1)
  else if acBeginsWith(AFileName, sLongFileNamePrefix) then
    Result := Copy(AFileName, Length(sLongFileNamePrefix) + 1)
  else
    Result := AFileName;
end;

function acCompareFileNames(const AFileName1, AFileName2: UnicodeString): Integer;
var
  ADelim1: Integer;
  ADelim2: Integer;
begin
  ADelim1 := acLastDelimiter(sFilePathDelims, AFileName1);
  ADelim2 := acLastDelimiter(sFilePathDelims, AFileName2);
  Result := acLogicalCompare(PWideChar(AFileName1), PWideChar(AFileName2), ADelim1, ADelim2);
  if Result = 0 then
  begin
    Result := acLogicalCompare(
      PWideChar(AFileName1) + ADelim1,
      PWideChar(AFileName2) + ADelim2,
      Length(AFileName1) - ADelim1,
      Length(AFileName2) - ADelim2);
  end;
//  Result := acLogicalCompare(acExtractFilePath(AFileName1), acExtractFilePath(AFileName2));
//  if Result = 0 then
//    Result := acLogicalCompare(acExtractFileName(AFileName1), acExtractFileName(AFileName2));
end;

{$IFDEF MSWINDOWS}
function acExpandEnvironmentStrings(const AFileName: UnicodeString): UnicodeString;
var
  L: Integer;
  W: TFileLongPath;
begin
  if AFileName <> '' then
    L := ExpandEnvironmentStringsW(PWideChar(AFileName), @W[0], Length(W))
  else
    L := 0;

  if L > 0 then
    SetString(Result, PWideChar(@W[0]), L - 1)
  else
    Result := AFileName;
end;
{$ENDIF}

function acExpandFileName(const AFileName: UnicodeString): UnicodeString;
{$IFDEF MSWINDOWS}
var
  AName: UnicodeString;
  L: Integer;
  N: PWideChar;
  W: TFileLongPath;
begin
  Result := AFileName;
  if acContains('.\', Result) then
  begin
    L := GetFullPathNameW(PWideChar(AFileName), Length(W), @W[0], N);
    if L > 0 then
      SetString(Result, W, L)
  end;
  if acContains('~', Result) then
  begin
    L := GetLongPathNameW(PWideChar(AFileName), @W[0], Length(W));
    if L > 0 then
      SetString(Result, W, L)
    else
      if acFileExists(Result) and acFindFile(Result, @AName, nil) then
        Result := AName;
  end;
end;
{$ELSE}
begin
  Result := System.SysUtils.ExpandFileName(AFileName);
end;
{$ENDIF}

function acValidateFileName(const Name: UnicodeString; ReplacementForInvalidChars: Char = #0): UnicodeString;
const
  InvalidChars = '\"<>*:?|/';
  MaxNameLength = MAX_PATH;
var
  ABuffer: TACLStringBuilder;
  AChar: Char;
  AIndex: Integer;
  ALength: Integer;
begin
  ALength := Length(Name);
  if ALength = 0 then
    Exit(acEmptyStr);

  ABuffer := TACLStringBuilder.Get(ALength);
  try
    for AIndex := 1 to ALength do
    begin
      AChar := Name[AIndex];
      if AChar = '"' then
        ABuffer.Append(#39)
      else
        if acContains(AChar, InvalidChars) then
        begin
          if ReplacementForInvalidChars <> #0 then
            ABuffer.Append(ReplacementForInvalidChars);
        end
        else
          if AChar >= ' ' then
            ABuffer.Append(AChar);
    end;

    AIndex := 0;
    ALength := ABuffer.Length - 1;
    while (AIndex <= ALength) and CharInSet(ABuffer.Chars[AIndex], [' ']) do
      Inc(AIndex);
    while (ALength >= 1) and CharInSet(ABuffer.Chars[ALength], [' ', '.']) do
      Dec(ALength);
    if ALength - AIndex + 1 >= MaxNameLength then
      ALength := AIndex + MaxNameLength - 1;
    Result := ABuffer.ToString(AIndex, ALength - AIndex + 1);
  finally
    ABuffer.Release;
  end;
end;

function acValidateFilePath(const Name: UnicodeString): UnicodeString;
var
  ADrive: UnicodeString;
begin
  ADrive := acExtractFileDrive(Name);
  if ADrive <> '' then
    Result := ADrive + PathDelim + acValidateSubPath(Copy(Name, Length(ADrive) + 1, MaxInt))
  else
    Result := acValidateSubPath(Name);
end;

function acValidateSubPath(const Path: UnicodeString): UnicodeString;
var
  AArr: TStringDynArray;
  ABuilder: TACLStringBuilder;
  AHasPathDelimeter: Boolean;
begin
  Result := '';
  if Path <> '' then
  begin
    AHasPathDelimeter := Path[Length(Path)] = PathDelim;
    acExplodeString(Path, PathDelim, AArr);
    for var I := 0 to Length(AArr) - 1 do
      AArr[I] := acValidateFileName(AArr[I]);

    ABuilder := TACLStringBuilder.Get(Length(Path));
    try
      for var I := 0 to Length(AArr) - 1 do
      begin
        if AArr[I] <> '' then
          ABuilder.Append(AArr[I]).Append(PathDelim);
      end;
      if not AHasPathDelimeter then
        ABuilder.Length := ABuilder.Length - 1;
      Result := ABuilder.ToString;
    finally
      ABuilder.Release;
    end;
  end;
end;

function acUnixPathToWindows(const Path: UnicodeString): UnicodeString;
begin
  Result := acReplaceChar(Path, sUnixPathDelim, sWindowPathDelim);
end;

function acWindowsPathToUnix(const Path: UnicodeString): UnicodeString;
begin
  Result := acReplaceChar(Path, sWindowPathDelim, sUnixPathDelim);
end;

function acGetFileExtBounds(const FileName: UnicodeString; out AStart, AFinish: Integer; ADoubleExt: Boolean): Boolean;
var
  AExtDelimPos: Integer;
  ALength: Integer;
  AUrlParamPos: Integer;
begin
  ALength := Length(FileName);
  if acIsUrlFileName(FileName) then
  begin
    AUrlParamPos := acLastDelimiter('?', PChar(FileName), 1, ALength);
    if AUrlParamPos > 0 then
      ALength := AUrlParamPos - 1;
  end;

  AExtDelimPos := acLastDelimiter(PChar(sFileExtDelims), PChar(FileName), Length(sFileExtDelims), ALength);
  if (AExtDelimPos > 0) and (FileName[AExtDelimPos] = '.') then
  begin
    AStart := AExtDelimPos;
    AFinish := ALength;
    if ADoubleExt then
    begin
      AExtDelimPos := acLastDelimiter(PChar(sFileExtDelims), PChar(FileName), Length(sFileExtDelims), AStart - 1);
      if (AExtDelimPos > 0) and (FileName[AExtDelimPos] = '.') then
        AStart := AExtDelimPos;
    end;
    Result := True;
  end
  else
    Result := False;
end;

function acChangeFileExt(const FileName, Extension: UnicodeString; ADoubleExt: Boolean = False): UnicodeString;
var
  AStart, AFinish: Integer;
begin
  if acGetFileExtBounds(FileName, AStart, AFinish, ADoubleExt) then
    Result := Copy(FileName, 1, AStart - 1) + Extension + Copy(FileName, AFinish + 1, MaxInt)
  else
    Result := FileName + Extension;
end;

function acExtractDirName(const APath: UnicodeString; ADepth: Integer = 1): UnicodeString;
var
  AEndIndex: Integer;
  AStartIndex: Integer;
begin
  AEndIndex := Length(APath);
  if AEndIndex = 0 then
    Exit(EmptyStr);

  AStartIndex := AEndIndex;
  while (ADepth > 0) and (AStartIndex > 0) do
  begin
    if acIsPathSeparator(APath[AStartIndex]) then
      Dec(AStartIndex);
    AStartIndex := acLastDelimiter(PChar(sFilePathDelims), PChar(APath), Length(sFilePathDelims), AStartIndex);
    Dec(ADepth);
  end;
  Inc(AStartIndex);

  while (AStartIndex <  AEndIndex) and acIsPathSeparator(APath[AEndIndex]) do
    Dec(AEndIndex);
  while (AStartIndex <= AEndIndex) and acIsPathSeparator(APath[AStartIndex]) do
    Inc(AStartIndex);

  Result := Copy(APath, AStartIndex, AEndIndex - AStartIndex + 1);
end;

function acExtractFileDir(const FileName: UnicodeString): UnicodeString;
var
  I: Integer;
begin
  I := acLastDelimiter(sFilePathDelims, Filename);
  if (I > 1) and (FileName[I] = PathDelim) and
    not CharInSet(FileName[I - 1], [PathDelim{$IFDEF MSWINDOWS}, DriveDelim{$ENDIF}])
  then
    Dec(I);
  Result := Copy(FileName, 1, I);
end;

function acExtractFileDirName(const FileName: UnicodeString): UnicodeString;
begin
  Result := acExtractDirName(acExtractFileDir(FileName));
end;

function acExtractFileDrive(const FileName: UnicodeString): UnicodeString;
var
  J: Integer;
begin
  if acBeginsWith(FileName, sLongFileNamePrefix) then
    Result := acExtractFileDrive(Copy(FileName, Length(sLongFileNamePrefix) + 1, MaxInt))
  else
    if (Length(FileName) >= 2) and (FileName[2] = DriveDelim) then
      Result := Copy(FileName, 1, 2)
    else
      if acIsUncFileName(FileName) then
      begin
        J := acPos(PathDelim, FileName, False, Length(sUncPrefix) + 1);
        if J > 0 then
          Result := Copy(FileName, 1, J - 1)
        else
          Result := FileName;
      end
      else
        Result := '';
end;

function acExtractFileExt(const FileName: UnicodeString; ADoubleExt: Boolean = False): UnicodeString;
var
  S, F: Integer;
begin
  if acGetFileExtBounds(FileName, S, F, ADoubleExt) then
    Result := Copy(FileName, S, F - S + 1)
  else
    Result := '';
end;

function acExtractFileFormat(const FileName: UnicodeString): UnicodeString;
var
  S, F: Integer;
begin
  if acGetFileExtBounds(FileName, S, F, False) then
    Result := acUpperCase(Copy(FileName, S + 1, F - S))
  else
    Result := '';
end;

function acExtractFileName(const FileName: UnicodeString): UnicodeString;
begin
  Result := Copy(FileName, acLastDelimiter(sFilePathDelims, FileName) + 1, MaxInt);
end;

function acExtractFileNameWithoutExt(const FileName: UnicodeString): UnicodeString;
begin
  Result := acChangeFileExt(acExtractFileName(FileName), '');
end;

function acExtractFilePath(const FileName: UnicodeString): UnicodeString;
begin
  Result := Copy(FileName, 1, acLastDelimiter(sFilePathDelims, FileName));
end;

function acExtractFileScheme(const AFileName: UnicodeString): UnicodeString;
var
  C, P: PWideChar;
begin
  P := PWideChar(AFileName);
  C := P;
  while CharInSet(P^, ['A'..'Z', 'a'..'z', '0'..'9']) do
    Inc(P);
  if (P^ = ':') and CharInSet((P + 1)^, ['\', '/']) and ((P + 1)^ = (P + 2)^) then
    Result := acExtractString(C, P)
  else
    Result := '';
end;

function acIsRelativeFileName(const AFileName: UnicodeString): Boolean;
begin
  Result := (Length(AFileName) >= 2) and (AFileName[2] <> DriveDelim) and not
    (acIsUncFileName(AFileName) or acIsUrlFileName(AFileName));
end;

function acRelativeFileName(const AFileName: UnicodeString; ARootPath: UnicodeString): UnicodeString;
var
  ACommonPath: UnicodeString;
  ALevel: Integer;
begin
  ARootPath := acIncludeTrailingPathDelimiter(ARootPath);
  ACommonPath := ARootPath;
  if acGetMinimalCommonPath(ACommonPath, acExtractFilePath(AFileName)) then
  begin
    ALevel := acGetCharacterCount(Copy(ARootPath, Length(ACommonPath) + 1, MaxInt), PathDelim);
    if (ALevel > 2) and acSameText(acIncludeTrailingPathDelimiter(acExtractFileDrive(AFileName)), ACommonPath) then
      Result := Copy(AFileName, 3, MaxInt)
    else
      Result := acDupeString('..' + PathDelim, ALevel) + Copy(AFileName, Length(ACommonPath) + 1, MaxInt);
  end
  else
    Result := AFileName;
end;

function acGetCurrentDir: UnicodeString;
{$IFDEF MSWINDOWS}
var
  W: TFileLongPath;
begin
  SetString(Result, W, GetCurrentDirectoryW(Length(W), W));
  Result := acIncludeTrailingPathDelimiter(Result);
end;
{$ELSE}
begin
  Result := acIncludeTrailingPathDelimiter(GetCurrentDir);
end;
{$ENDIF}

function acGetFreeFileName(const AFileName: UnicodeString): UnicodeString;
var
  AIndex: Integer;
begin
  AIndex := 2;
  Result := AFileName;
  while acFileExists(Result) do
  begin
    Result := acChangeFileExt(AFileName, ' (' + IntToStr(AIndex) + ')' + acExtractFileExt(AFileName));
    Inc(AIndex);
  end;
end;

function acGetMinimalCommonPath(var ACommonPath: UnicodeString; const AFilePath: UnicodeString): Boolean;
var
  ATemp: UnicodeString;
begin
  Result := ACommonPath <> '';
  if Result and not acBeginsWith(AFilePath, ACommonPath) then
  begin
    ATemp := ACommonPath;
    ACommonPath := acExtractFilePath(ExcludeTrailingPathDelimiter(ACommonPath));
    Result := (Length(ATemp) > Length(ACommonPath)) and acGetMinimalCommonPath(ACommonPath, AFilePath);
  end;
end;

function acGetShortFileName(const APath: UnicodeString): UnicodeString;
{$IFDEF MSWINDOWS}
var
  ALength, ASkipCount: Integer;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  ALength := GetShortPathNameW(PWideChar(acPrepareFileName(APath)), nil, 0);
  if ALength > 0 then
  begin
    SetLength(Result, ALength);
    ALength := GetShortPathNameW(PWideChar(acPrepareFileName(APath)), PWideChar(Result), ALength);

    if acBeginsWith(Result, sLongFileNamePrefix) then
      ASkipCount := Length(sLongFileNamePrefix)
    else
      ASkipCount := 0;

    Result := Copy(Result, 1 + ASkipCount, ALength - ASkipCount);
  end
  else
{$ENDIF}
    Result := APath;
end;

function acIncludeTrailingPathDelimiter(const Path: UnicodeString): UnicodeString;
begin
  if Path <> '' then
    Result := IncludeTrailingPathDelimiter(Path)
  else
    Result := '';
end;

function acIsDoubleExtFile(const AFileName: UnicodeString): Boolean;
begin
  Result := acExtractFileExt(AFileName, False) <> acExtractFileExt(AFileName, True);
end;

function acIsOurFile(const AExtsList, AFileName: UnicodeString; ADoubleExt: Boolean = False): Boolean;
begin
  Result := acIsOurFileEx(AExtsList, acExtractFileExt(AFilename, ADoubleExt));
end;

function acIsOurFileEx(const AExtsList, ATestExt: UnicodeString): Boolean;
var
  T, S: PWideChar;
  TL, SL: Integer;
begin
  Result := False;
  SL := Length(AExtsList);
  TL := Length(ATestExt);
  if (SL > 2) and (TL > 0) then
  begin
    T := @ATestExt[1];
    S := @AExtsList[1];
    while SL > TL do
    begin
      if (S^ = '*') and (PWideChar(S + TL + 1)^ = ';') then
      begin
        Result := acCompareStrings(PWideChar(S + 1), T, TL, TL) = 0;
        if Result then Break;
      end;
      Dec(SL);
      Inc(S);
    end;
  end;
end;

function acLastDelimiter(const Delimiters, Str: UnicodeString): Integer;
begin
  Result := acLastDelimiter(PChar(Delimiters), PChar(Str), Length(Delimiters), Length(Str));
end;

function acLastDelimiter(Delimiters, Str: PWideChar; DelimitersLength, StrLength: Integer): Integer;
begin
  Result := StrLength;
  Inc(Str, StrLength - 1);
  while Result > 0 do
  begin
    if WStrScan(Delimiters, DelimitersLength, Str^) <> nil then
      Exit;
    Dec(Result);
    Dec(Str);
  end;
end;

function acTempPath: UnicodeString;
{$IFDEF MSWINDOWS}
var
  W: TFilePath;
begin
  if GetTempPathW(Length(W), W) > 0 then
    Result := acIncludeTrailingPathDelimiter(W)
  else
    RaiseLastOSError;
end;
{$ELSE}
begin
  Result := acIncludeTrailingPathDelimiter(TPath.GetTempPath);
end;
{$ENDIF}

function acTempFileName(const APrefix: UnicodeString): UnicodeString;
{$IFDEF MSWINDOWS}
var
  W: TFilePath;
begin
  if GetTempFileNameW(PWideChar(acTempPath), PWideChar(APrefix), 0, @W[0]) > 0 then
    Result := W
  else
    RaiseLastOSError;
end;
{$ELSE}
begin
  Result := acGetFreeFileName(acTempPath + IfThenW(APrefix, 'file') + '.tmp');
end;
{$ENDIF}

function acSetCurrentDir(const ADir: UnicodeString): Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := SetCurrentDirectoryW(PWideChar(ADir));
{$ELSE}
  Result := SetCurrentDir(ADir);
{$ENDIF}
end;

//==============================================================================
// Files Attributes
//==============================================================================

function acFileCreate(const AFileName: UnicodeString; AMode, ARights: LongWord): THandle;
{$IFDEF MSWINDOWS}
const
  AccessMode: array[0..2] of LongWord = (
    GENERIC_READ, GENERIC_WRITE, GENERIC_READ or GENERIC_WRITE
  );
  ShareMode: array[0..4] of LongWord = (
    0, 0, FILE_SHARE_READ, FILE_SHARE_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE
  );
var
  AAccess: Cardinal;
  AAction: Cardinal;
  AErrorMode: Integer;
  AShareMode: Cardinal;
begin
  if AMode and fmCreate = fmCreate then
  begin
    AAction := CREATE_ALWAYS;
    AAccess := GENERIC_READ or GENERIC_WRITE;
    AShareMode := 0;
  end
  else
  begin
    AAction := OPEN_EXISTING;
    AAccess := AccessMode[AMode and 3];
    AShareMode := ShareMode[(AMode and $F0) shr 4];
  end;

  //#AI: to avoid to display "Disk is not inserted to the drive" dialog box for removable devices
  AErrorMode := SetErrorMode(SEM_FailCriticalErrors);
  try
    Result := CreateFileW(PWideChar(acPrepareFileName(AFileName)), AAccess, AShareMode, nil, AAction, FILE_ATTRIBUTE_NORMAL or ARights, 0);
  finally
    SetErrorMode(AErrorMode);
  end;
end;
{$ELSE}
begin
  if AMode and fmCreate = fmCreate then
    Result := System.SysUtils.FileCreate(AFileName, ARights)
  else
    Result := System.SysUtils.FileOpen(AFileName, AMode);
end;
{$ENDIF}

function acFileExists(const FileName: UnicodeString): Boolean;
var
  AAttr: Cardinal;
begin
  Result := acFileGetAttr(FileName, AAttr) and (AAttr and faDirectory = 0);
end;

function acDirectoryExists(const APath: UnicodeString): Boolean;
var
  AAttr: Cardinal;
begin
  Result := acFileGetAttr(APath, AAttr) and (AAttr and faDirectory <> 0);
end;

function acFileGetAttr(const FileName: UnicodeString): Cardinal;
var
{$IFDEF MSWINDOWS}
  AErrorMode: Cardinal;
{$ELSE}
  AFileInfo: TACLFindFileInfo;
{$ENDIF}
begin
  Result := INVALID_FILE_ATTRIBUTES;
  if FileName <> '' then
  begin
  {$IFDEF MSWINDOWS}
    AErrorMode := SetErrorMode(SEM_FailCriticalErrors);
    try
      Result := GetFileAttributesW(PWideChar(acPrepareFileName(FileName)));
    finally
      SetErrorMode(AErrorMode);
    end;
  {$ELSE}
    if acFindFileFirst(FileName, [ffoFile, ffoFolder], AFileInfo) then
    try
      Result := AFileInfo.FileAttrs;
    finally
      acFindFileClose(AFileInfo);
    end;
  {$ENDIF}
  end;
end;

function acFileGetAttr(const FileName: UnicodeString; out AAttrs: Cardinal): Boolean;
begin
  AAttrs := acFileGetAttr(FileName);
  Result := AAttrs <> INVALID_FILE_ATTRIBUTES;
end;

{$IFDEF MSWINDOWS}
function acFileGetLastWriteTime(const FileName: UnicodeString): Cardinal;
begin
  Result := DateTimeToFileDate(TACLFileDateTimeHelper.GetLastEditingTime(FileName));
end;
{$ENDIF}

function acFileSetAttr(const FileName: UnicodeString; AAttr: Cardinal): Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := SetFileAttributesW(PWideChar(acPrepareFileName(FileName)), AAttr)
{$ELSE}
  Result := False;
{$ENDIF}
end;

function acFileSize(const FileName: UnicodeString): Int64;
{$IFDEF MSWINDOWS}
var
  AData: WIN32_FILE_ATTRIBUTE_DATA;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  //#AI: GetFileAttributesExW works fine with locked files too
  if GetFileAttributesExW(PWideChar(acPrepareFileName(FileName)), GetFileExInfoStandard, @AData) then
    Exit(MakeInt64(AData.nFileSizeLow, AData.nFileSizeHigh));
{$ENDIF}
  if not acFindFile(FileName, nil, @Result) then
    Result := 0;
end;

{$IFDEF MSWINDOWS}
function acVolumeGetSerial(const ADrive: WideChar; out ASerialNumber: Cardinal): Boolean;
var
  X: Cardinal;
begin
  Result := GetVolumeInformationW(PWideChar(ADrive + ':\'), nil, 0, @ASerialNumber, X, X, nil, 0);
end;

function acVolumeGetTitle(const ADrive: UnicodeString): UnicodeString;
begin
  Result := acVolumeGetTitle(ADrive, ADrive);
end;

function acVolumeGetTitle(const ADrive, ADefaultTitle: UnicodeString): UnicodeString;
const
  sAutoRunFile = ':\autorun.inf';
var
  B: array[Byte] of WideChar;
  X: Cardinal;
begin
  Result := '';
  if ADrive <> '' then
    if GetVolumeInformationW(PWideChar(ADrive[1] + ':\'), @B[0], High(B), nil, X, X, nil, 0) then
    begin
      Result := B;
      if (Result = '') and acFileExists(ADrive[1] + sAutoRunFile) then
        with TACLIniFile.Create(ADrive[1] + sAutoRunFile, False) do
        try
          Result := ReadString('Autorun', 'Label');
        finally
          Free;
        end;
    end;

  Result := Format('%s (%s)', [IfThenW(Result, ADefaultTitle), ADrive]);
end;

function acVolumeGetType(const ADrive: WideChar): Cardinal;
begin
  Result := GetDriveTypeW(PWideChar(ADrive + ':'));
end;
{$ENDIF}

//==============================================================================
// Removing, Copying, Renaming
//==============================================================================

function acCopyDirectory(const ASourcePath, ATargetPath: UnicodeString;
  const AExts: UnicodeString = ''; ARecursive: Boolean = True): Boolean;
begin
  Result := acCopyDirectoryContent(ASourcePath,
    acIncludeTrailingPathDelimiter(ATargetPath) + acExtractDirName(ASourcePath), AExts, ARecursive);
end;

function acCopyDirectoryContent(ASourcePath, ATargetPath: UnicodeString;
  const AExts: UnicodeString = ''; ARecursive: Boolean = True): Boolean;
var
  AInfo: TACLFindFileInfo;
begin
  Result := acDirectoryExists(ASourcePath);
  ASourcePath := acIncludeTrailingPathDelimiter(ASourcePath);
  ATargetPath := acIncludeTrailingPathDelimiter(ATargetPath);
  if acFindFileFirst(ASourcePath, AExts, [ffoFile, ffoFolder], AInfo) then
  try
    repeat
      Result := acMakePath(ATargetPath);
      if Result then
      begin
        if AInfo.FileObject = ffoFile then
          Result := acCopyFile(AInfo.FullFileName, ATargetPath + AInfo.FileName, False)
        else
          if ARecursive then
            Result := acCopyDirectory(AInfo.FullFileName, ATargetPath, AExts, ARecursive);
      end;
    until not (Result and acFindFileNext(AInfo));
  finally
    acFindFileClose(AInfo);
  end;
end;

function acCopyFile(const ASourceFileName, ATargetFileName: UnicodeString; AFailIfExists: Boolean = True): Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := CopyFileW(
    PWideChar(acPrepareFileName(ASourceFileName)),
    PWideChar(acPrepareFileName(ATargetFileName)), AFailIfExists);
{$ELSE}
  try
    TFile.Copy(ASourceFilename, ATargetFileName, not AFailIfExists);
    Result := True;
  except
    Result := False;
  end;
{$ENDIF}
end;

function acDeleteFile(const AFileName: UnicodeString): Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := DeleteFileW(PWideChar(acPrepareFileName(AFileName)));
{$ELSE}
  Result := System.SysUtils.DeleteFile(AFileName);
{$ENDIF}
end;

function acDeleteDirectory(const APath: UnicodeString): Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := RemoveDirectoryW(PWideChar(acPrepareFileName(APath)));
{$ELSE}
  Result := System.SysUtils.RemoveDir(APath);
{$ENDIF}
end;

function acDeleteDirectoryFull(APath: UnicodeString; ARecursive: Boolean = True): Boolean;
var
  AInfo: TACLFindFileInfo;
begin
  Result := APath <> '';
  if Result then
  begin
    APath := acIncludeTrailingPathDelimiter(APath);
    if acFindFileFirst(APath, [ffoFile, ffoFolder], AInfo) then
    try
      repeat
        if AInfo.FileObject = ffoFile then
          Result := acDeleteFile(AInfo.FullFileName)
        else
          if ARecursive then
            Result := acDeleteDirectoryFull(AInfo.FullFileName + PathDelim)
          else
            Result := True;
      until not (Result and acFindFileNext(AInfo));
    finally
      acFindFileClose(AInfo);
    end;
    Result := acDeleteDirectory(APath);
  end;
end;

function acMakePath(const APath: UnicodeString): Boolean;
begin
  try
    Result := (APath <> '') and ForceDirectories(APath);
  except
    Result := False;
  end;
end;

function acMakePathForFileName(const AFileName: UnicodeString): Boolean;
begin
  Result := acMakePath(acExtractFilePath(AFileName));
end;

function acMoveFile(const ASourceFileName, ATargetFileName: UnicodeString): Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := MoveFileW(
    PWideChar(acPrepareFileName(ASourceFileName)),
    PWideChar(acPrepareFileName(ATargetFileName)));
{$ELSE}
  try
    TFile.Move(ASourceFileName, ATargetFileName);
    Result := True;
  except
    Result := False;
  end;
{$ENDIF}
end;

function acReplaceFile(const ASourceFileName, ATargetFileName: UnicodeString): Boolean;
begin
  Result := acReplaceFile(ASourceFileName, ATargetFileName, '');
end;

function acReplaceFile(const ASourceFileName, ATargetFileName, ABackupFileName: UnicodeString): Boolean;
begin
  if acFileExists(ATargetFileName) then
  begin
  {$IFDEF MSWINDOWS}
    if ABackupFileName <> '' then
      Result := ReplaceFileW(
        PWideChar(acPrepareFileName(ATargetFileName)),
        PWideChar(acPrepareFileName(ASourceFileName)),
        PWideChar(acPrepareFileName(ABackupFileName)),
        0, nil, nil)
    else
      Result := ReplaceFileW(
        PWideChar(acPrepareFileName(ATargetFileName)),
        PWideChar(acPrepareFileName(ASourceFileName)),
        nil, 0, nil, nil);
  {$ELSE}
    try
      TFile.Replace(ASourceFileName, ATargetFileName, ABackupFileName);
      Result := True;
    except
      Result := False;
    end;
  {$ENDIF}
  end
  else
    Result := acMoveFile(ASourceFileName, ATargetFileName);
end;

//==============================================================================
// CommandLine Helpers
//==============================================================================

function acSelfExeName: UnicodeString;
begin
  Result := acModuleFileName(0);
end;

function acSelfPath: UnicodeString;
begin
  Result := acExtractFilePath(acSelfExeName);
end;

//==============================================================================
// Find File
//==============================================================================

procedure acEnumFiles(const APath: UnicodeString;
  AObjects: TACLFindFileObjects; AProc: TACLEnumFileProc; ARecursive: Boolean);
begin
  acEnumFiles(APath, '', AObjects, AProc, ARecursive);
end;

procedure acEnumFiles(const APath, AExts: UnicodeString;
  AObjects: TACLFindFileObjects; AProc: TACLEnumFileProc; ARecursive: Boolean);
begin
  acEnumFiles(APath, AExts, '*', AObjects, AProc, ARecursive);
end;

procedure acEnumFiles(const APath, AExts, AMask: UnicodeString;
  AObjects: TACLFindFileObjects; AProc: TACLEnumFileProc; ARecursive: Boolean);
var
  AInfo: TACLFindFileInfo;
begin
  if ARecursive then
  begin
    if acFindFileFirst(acIncludeTrailingPathDelimiter(APath), [ffoFolder], AInfo) then
    try
      repeat
        acEnumFiles(AInfo.FullFileName, AExts, AMask, AObjects, AProc, True);
      until not acFindFileNext(AInfo);
    finally
      acFindFileClose(AInfo)
    end;
  end;

  if acFindFileFirstMasked(acIncludeTrailingPathDelimiter(APath), AExts, AMask, AObjects, AInfo) then
  try
    repeat
      AProc(AInfo);
    until not acFindFileNext(AInfo);
  finally
    acFindFileClose(AInfo)
  end;
end;

procedure acEnumFiles(const APath, AExts: UnicodeString; AList: IStringReceiver);
begin
  acEnumFiles(APath, AExts, [ffoFile],
    procedure (const Info: TACLFindFileInfo)
    begin
      AList.Add(Info.FullFileName);
    end, False);
end;

function acFindFile(const AFileName: UnicodeString; AFullFileName: PUnicodeString; ASize: PInt64): Boolean;
var
  AInfo: TACLFindFileInfo;
begin
  Result := acFindFileFirstMasked(acExtractFilePath(AFileName), '', acExtractFileName(AFileName), [ffoFile], AInfo);
  if Result then
  try
    if AFullFileName <> nil then
      AFullFileName^ := AInfo.FullFileName;
    if ASize <> nil then
      ASize^ := AInfo.FileSize;
  finally
    acFindFileClose(AInfo);
  end;
end;

function acFindFileFirst(const APath: UnicodeString;
  AObjects: TACLFindFileObjects; out AInfo: TACLFindFileInfo): Boolean;
begin
  Result := acFindFileFirst(APath, '', AObjects, AInfo);
end;

function acFindFileFirst(const APath, AExts: UnicodeString;
  AObjects: TACLFindFileObjects; out AInfo: TACLFindFileInfo): Boolean;
begin
  Result := acFindFileFirstMasked(APath, AExts, '*', AObjects, AInfo);
end;

function acFindFileFirstMasked(const APath, AExts, AMask: UnicodeString;
  AObjects: TACLFindFileObjects; out AInfo: TACLFindFileInfo): Boolean;
begin
  AInfo := nil;
  if AObjects <> [] then
  begin
    AInfo := TACLFindFileInfo.Create;
    AInfo.FFindExts := AExts;
    AInfo.FFilePath := APath;
    AInfo.FFindObjects := AObjects;
  {$IFDEF MSWINDOWS}
    AInfo.FFindHandle := FindFirstFileW(PWideChar(acPrepareFileName(APath + AMask)), AInfo.FFindData);
    if AInfo.FFindHandle = INVALID_HANDLE_VALUE then
  {$ELSE}
    var AAttrs := 0;
    if ffoFile in AObjects then
      AAttrs := AAttrs or faAnyFile;
    if ffoFolder in AObjects then
      AAttrs := AAttrs or faDirectory;
    if FindFirst(APath + AMask, AAttrs, AInfo.FFindData) <> 0 then
  {$ENDIF}
      acFindFileClose(AInfo)
    else
      if not AInfo.Check then
        acFindFileNext(AInfo);
  end;
  Result := AInfo <> nil;
end;

function acFindFileNext(var AInfo: TACLFindFileInfo): Boolean;
begin
  if AInfo <> nil then
  begin
  {$IFDEF MSWINDOWS}
    while FindNextFileW(AInfo.FFindHandle, AInfo.FFindData) do
  {$ELSE}
    while FindNext(AInfo.FFindData) = 0 do
  {$ENDIF}
      if AInfo.Check then
        Exit(True);
  end;
  acFindFileClose(AInfo);
  Result := False;
end;

procedure acFindFileClose(var AInfo: TACLFindFileInfo);
begin
  FreeAndNil(AInfo);
end;

{ TACLFindFileInfo }

destructor TACLFindFileInfo.Destroy;
begin
{$IFDEF MSWINDOWS}
  if FFindHandle <> INVALID_HANDLE_VALUE then
  begin
    Winapi.Windows.FindClose(FFindHandle);
    FFindHandle := INVALID_HANDLE_VALUE;
  end;
{$ELSE}
  FindClose(FFindData);
{$ENDIF}
  inherited Destroy;
end;

function TACLFindFileInfo.Check: Boolean;
const
  Map: array[Boolean] of TACLFindFileObject = (ffoFile, ffoFolder);
begin
{$IFDEF MSWINDOWS}
  FFileName := FFindData.cFileName;
{$ELSE}
  FFileName := FFindData.Name;
{$ENDIF}
  FFileObject := Map[FileAttrs and faDirectory <> 0];
  if not IsInternal and (FileObject in FFindObjects) then
  begin
    if FileObject = ffoFile then
      Result := (FFindExts = '') or acIsOurFile(FFindExts, FileName)
    else
      Result := True;
  end
  else
    Result := False;
end;

function TACLFindFileInfo.GetFileSize: Int64;
begin
{$IFDEF MSWINDOWS}
  Result := MakeInt64(FFindData.nFileSizeLow, FFindData.nFileSizeHigh);
{$ELSE}
  Result := FFindData.Size;
{$ENDIF}
end;

function TACLFindFileInfo.GetFullFileName: UnicodeString;
begin
  Result := FFilePath + FFileName;
end;

function TACLFindFileInfo.IsInternal: Boolean;
begin
  Result := (FileName = '.') or (FileName = '..')
  {$IFDEF MSWINDOWS}
    or (FileAttrs and faSysFile = faSysFile)
  {$ENDIF}
end;

{ TACLSearchPaths }

constructor TACLSearchPaths.Create;
begin
  inherited Create;
  FList := TACLStringList.Create;
end;

constructor TACLSearchPaths.Create(AChangeEvent: TNotifyEvent);
begin
  Create;
  FOnChange := AChangeEvent;
end;

destructor TACLSearchPaths.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TACLSearchPaths.Add(const APath: UnicodeString; ARecursive: Boolean);
begin
  FList.Add(acIncludeTrailingPathDelimiter(APath), Ord(ARecursive));
  Changed;
end;

procedure TACLSearchPaths.Assign(const ASource: string);
var
  APath: string;
  APaths: TStringDynArray;
  I: Integer;
begin
  BeginUpdate;
  try
    Clear;
    acExplodeString(ASource, ';', APaths);
    for I := 0 to Length(APaths) - 1 do
    begin
      APath := APaths[I];
      if APath <> '' then
        Add(Copy(APath, 2, MaxInt), APath[1] <> '0');
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLSearchPaths.Clear;
begin
  FList.Clear;
  Changed;
end;

procedure TACLSearchPaths.Delete(Index: Integer);
begin
  FList.Delete(Index);
  Changed;
end;

function TACLSearchPaths.Contains(APath: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  APath := acIncludeTrailingPathDelimiter(APath);
  for I := 0 to Count - 1 do
  begin
    if Recursive[I] then
      Result := acBeginsWith(APath, Paths[I])
    else
      Result := acSameText(APath, Paths[I]);

    if Result then
      Break;
  end;
end;

function TACLSearchPaths.CreatePathList: TACLStringList;
var
  I: Integer;
begin
  Result := TACLStringList.Create;
  Result.Capacity := Count;
  for I := 0 to Count - 1 do
    Result.Add(Paths[I]);
end;

procedure TACLSearchPaths.DoAssign(ASource: TPersistent);
begin
  if ASource is TACLSearchPaths then
  begin
    FList.Assign(TACLSearchPaths(ASource).FList);
    Changed;
  end;
end;

procedure TACLSearchPaths.DoChanged;
begin
  CallNotifyEvent(Self, FOnChange);
end;

function TACLSearchPaths.ContainsPathPart(const APath: UnicodeString): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
  begin
    Result := acBeginsWith(APath, Paths[I]) or acBeginsWith(Paths[I], APath);
    if Result then Break;
  end;
end;

function TACLSearchPaths.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TACLSearchPaths.GetPath(Index: Integer): UnicodeString;
begin
  Result := FList[Index];
end;

function TACLSearchPaths.GetRecursive(Index: Integer): Boolean;
begin
  Result := FList.Objects[Index] <> nil;
end;

procedure TACLSearchPaths.SetPath(Index: Integer; const Value: UnicodeString);
begin
  FList[Index] := acIncludeTrailingPathDelimiter(Value);
  Changed;
end;

procedure TACLSearchPaths.SetRecursive(AIndex: Integer; AValue: Boolean);
begin
  if Recursive[AIndex] <> AValue then
  begin
    FList.Objects[AIndex] := TObject(AValue);
    Changed;
  end;
end;

function TACLSearchPaths.ToString: string;
var
  B: TACLStringBuilder;
begin
  B := TACLStringBuilder.Get(Count * 32);
  try
    for var I := 0 to Count - 1 do
    begin
      if I > 0 then
        B.Append(';');
      B.Append(IfThenW(Recursive[I], '1', '0'));
      B.Append(Paths[I]);
    end;
    Result := B.ToString;
  finally
    B.Release;
  end;
end;

{ TACLFileStream }

constructor TACLFileStream.Create(const AHandle: THandle);
begin
  inherited Create(AHandle);
  if Handle = INVALID_HANDLE_VALUE then
    raise EFOpenError.CreateResFmt(@SFOpenErrorEx, [FileName, SysErrorMessage(GetLastError)]);
end;

constructor TACLFileStream.Create(const AFileName: string; Mode: Word);
begin
  Create(AFileName, Mode, 0);
end;

constructor TACLFileStream.Create(const AFileName: string; Mode: Word; Rights: Cardinal);
begin
  FFileName := AFileName;
  Create(acFileCreate(AFileName, Mode, Rights));
end;

destructor TACLFileStream.Destroy;
begin
  FileClose(Handle);
  inherited Destroy;
end;

class function TACLFileStream.GetFileName(AStream: TStream; out AFileName: string): Boolean;
begin
  Result := True;
  AStream := TACLStreamWrapper.Unwrap(AStream);
  if AStream is TFileStream then
    AFileName := TFileStream(AStream).FileName
  else if AStream is TACLFileStream then
    AFileName := TACLFileStream(AStream).FileName
  else
    Result := False;
end;

{$IFDEF MSWINDOWS}
function TACLFileStream.GetSize: Int64;
var
  ASizeHigh: Cardinal;
begin
  Result := GetFileSize(Handle, @ASizeHigh);
  Result := MakeInt64(Result, ASizeHigh);
end;
{$ENDIF}

{ TACLBufferedFileStream }

constructor TACLBufferedFileStream.Create(const AFileName: string; AMode: Word; ABufferSize: Integer);
begin
  inherited Create(TACLFileStream.Create(AFileName, AMode), soOwned, ABufferSize);
end;

{ TACLClippedFileStream }

constructor TACLClippedFileStream.Create(const AFileName: UnicodeString; const AOffset, ASize: Int64);
begin
  inherited Create(TACLFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone), AOffset, ASize, soOwned);
end;

{ TACLSearch }

constructor TACLSearch.Create(const AReceiver: IStringReceiver);
begin
  inherited Create;
  FDest := AReceiver;
end;

destructor TACLSearch.Destroy;
begin
  FDest := nil;
  inherited Destroy;
end;

procedure TACLSearch.Start(ARecurse: Boolean = True);
begin
  FActive := True;
  FRecurse := ARecurse;
  ScanDirectory(FPath);
end;

function TACLSearch.CanScanDirectory(const Dir: UnicodeString): Boolean;
begin
  Result := True;
  if Assigned(OnDir) then
    OnDir(Self, Dir, Result);
end;

procedure TACLSearch.ScanDirectory(const Dir: UnicodeString);
var
  AInfo: TACLFindFileInfo;
  ASubDirs: TACLStringList;
  I: Integer;
begin
  if Active and CanScanDirectory(Dir) then
  try
    ASubDirs := TACLStringList.Create;
    try
      if acFindFileFirst(Dir, Exts, [ffoFile, ffoFolder], AInfo) then
      try
        repeat
          if AInfo.FileObject = ffoFolder then
          begin
            if FRecurse then
              ASubDirs.Add(AInfo.FullFileName + PathDelim);
          end
          else
            Dest.Add(AInfo.FullFileName);
        until not (Active and acFindFileNext(AInfo));
      finally
        acFindFileClose(AInfo);
      end;

      if Active and FRecurse then
      begin
        ASubDirs.SortLogical;
        for I := 0 to ASubDirs.Count - 1 do
          ScanDirectory(ASubDirs[I]);
      end;
    finally
      ASubDirs.Free;
    end;
  except
    on E: EAbort do
      Stop
    else
      raise;
  end;
end;

procedure TACLSearch.Stop;
begin
  FActive := False;
end;

procedure TACLSearch.SetPath(const AValue: UnicodeString);
begin
  FPath := acIncludeTrailingPathDelimiter(AValue);
end;

{ TACLTemporaryFileStream }

constructor TACLTemporaryFileStream.Create(const APrefix: UnicodeString);
begin
  inherited Create(acTempFileName(APrefix), fmCreate);
end;

destructor TACLTemporaryFileStream.Destroy;
begin
  inherited Destroy;
  acDeleteFile(FileName);
end;

{$IFDEF MSWINDOWS}

{ TACLFileDateTimeHelper }

class function TACLFileDateTimeHelper.DecodeTime(const ATime: TFileTime): TDateTime;
var
  L: TFileTime;
  W1, W2: Word;
begin
  FileTimeToLocalFileTime(ATime, L);
  if FileTimeToDosDateTime(L, W2, W1) then
    Result := FileDateToDateTime(MakeLong(W1, W2))
  else
    Result := 0;
end;

class function TACLFileDateTimeHelper.GetCreationTime(const AFileName: UnicodeString): TDateTime;
var
  AData: TWin32FindDataW;
begin
  if GetFileData(AFileName, AData) then
    Result := DecodeTime(AData.ftCreationTime)
  else
    Result := 0;
end;

class function TACLFileDateTimeHelper.GetFileData(const AFileName: UnicodeString; out AData: TWin32FindDataW): Boolean;
var
  AHandle: THandle;
begin
  //#AI: W7x64, 13.05.2014: FindFirstFileW faster than GetFileAttributesExW
  Result := False;
  AHandle := FindFirstFileW(PWideChar(acPrepareFileName(AFileName)), AData);
  if AHandle <> INVALID_HANDLE_VALUE then
  try
    Result := AData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0;
  finally
    Winapi.Windows.FindClose(AHandle);
  end;
end;

class function TACLFileDateTimeHelper.GetLastAccessTime(const AFileName: UnicodeString): TDateTime;
var
  AData: TWin32FindDataW;
begin
  if GetFileData(AFileName, AData) then
    Result := DecodeTime(AData.ftLastAccessTime)
  else
    Result := 0;
end;

class function TACLFileDateTimeHelper.GetLastEditingTime(const AFileName: UnicodeString): TDateTime;
var
  AData: TWin32FindDataW;
begin
  if GetFileData(AFileName, AData) then
    Result := DecodeTime(AData.ftLastWriteTime)
  else
    Result := 0;
end;

{$ENDIF}
end.
