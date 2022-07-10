{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*        FileSystem Change Watchers         *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.FileSystem.Watcher;

{$I ACL.Config.INC}

interface

uses
  Windows, SysUtils, Classes, Generics.Collections, SyncObjs,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.Threading,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

type
  TACLFileSystemChange = (fscFiles, fscFolders, fscAttributes, fscSize, fscLastWriteTime, fscLastAccessTime);
  TACLFileSystemChanges = set of TACLFileSystemChange;

const
  AllFileSystemChanges = [fscFiles..fscLastAccessTime];

type
  IACLFileSystemWatcherTask = interface;

  TACLFileSystemWatcherNotifyEvent = procedure (ATask: IACLFileSystemWatcherTask) of object;

  { IACLFileSystemWatcherTask }

  IACLFileSystemWatcherTask = interface
  ['{06030675-6000-49BA-9435-55FD5326ADE5}']
    procedure Changed;
    function GetChanges: TACLFileSystemChanges;
    function GetPaths: TACLSearchPaths;
    procedure LockChanges;
    procedure UnlockChanges;
  end;

  { TACLFileSystemWatcher }

  TACLFileSystemWatcher = class
  strict private
    FActiveTasks: TACLList<IACLFileSystemWatcherTask>;
    FActiveThreads: TACLObjectList<TACLThread>;
    FLock: TACLCriticalSection;
    FTasks: TACLList<IACLFileSystemWatcherTask>;

    procedure SafeStartThreads;
  protected
    procedure DoAsyncChangeNotify(ATaskIndex: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const APath: UnicodeString; AChangeEvent: TACLFileSystemWatcherNotifyEvent;
      ARecursive: Boolean = True; AChanges: TACLFileSystemChanges = AllFileSystemChanges;
      ACombineSerialChanges: Boolean = True): IACLFileSystemWatcherTask; overload;
    function Add(const APaths: TACLSearchPaths; AChangeEvent: TACLFileSystemWatcherNotifyEvent;
      AChanges: TACLFileSystemChanges = AllFileSystemChanges; ACombineSerialChanges: Boolean = True): IACLFileSystemWatcherTask; overload;
    function Add(const APaths: TACLStringList; AChangeEvent: TACLFileSystemWatcherNotifyEvent;
      ARecursive: Boolean = True; AChanges: TACLFileSystemChanges = AllFileSystemChanges;
      ACombineSerialChanges: Boolean = True): IACLFileSystemWatcherTask; overload;
    function AddFile(const AFileName: string; AChangeEvent: TACLFileSystemWatcherNotifyEvent): IACLFileSystemWatcherTask;
    procedure Remove(var ATask: IACLFileSystemWatcherTask);
  end;

  { TACLFileSystemWatcherEx }

  TACLFileSystemWatcherExFileRenameEvent = procedure (const AOldFileName, ANewFileName: UnicodeString) of object;
  TACLFileSystemWatcherExFileChangeEvent = procedure (const AFileName: UnicodeString) of object;

  TACLFileSystemWatcherEx = class(TACLThread)
  strict private
    FHandle: THandle;
    FNotifyFilter: Cardinal;
    FPath: UnicodeString;
    FWatchSubTree: Boolean;

    FOnAsyncFileAdded: TACLFileSystemWatcherExFileChangeEvent;
    FOnAsyncFileChanged: TACLFileSystemWatcherExFileChangeEvent;
    FOnAsyncFileRemoved: TACLFileSystemWatcherExFileChangeEvent;
    FOnAsyncFileRenamed: TACLFileSystemWatcherExFileRenameEvent;
  protected
    procedure DoAsyncFileAdded(const AFileName: UnicodeString);
    procedure DoAsyncFileChanged(const AFileName: UnicodeString);
    procedure DoAsyncFileRemoved(const AFileName: UnicodeString);
    procedure DoAsyncFileRenamed(const AOldFileName, ANewFileName: UnicodeString);
    procedure Execute; override;
  public
    constructor Create(const APath: UnicodeString; AChanges: TACLFileSystemChanges; AWatchSubTree: Boolean);
    destructor Destroy; override;
    //
    property OnAsyncFileAdded: TACLFileSystemWatcherExFileChangeEvent read FOnAsyncFileAdded write FOnAsyncFileAdded;
    property OnAsyncFileChanged: TACLFileSystemWatcherExFileChangeEvent read FOnAsyncFileChanged write FOnAsyncFileChanged;
    property OnAsyncFileRemoved: TACLFileSystemWatcherExFileChangeEvent read FOnAsyncFileRemoved write FOnAsyncFileRemoved;
    property OnAsyncFileRenamed: TACLFileSystemWatcherExFileRenameEvent read FOnAsyncFileRenamed write FOnAsyncFileRenamed;
  end;

function FileSystemWatcher: TACLFileSystemWatcher;
implementation

uses
  Math,
  DateUtils,
  ACL.Math,
  ACL.Utils.Common;

type
  { TFileNotifyInformation }

  PFileNotifyInformation = ^TFileNotifyInformation;
  TFileNotifyInformation = record
    NextEntryOffset: DWORD;
    Action: DWORD;
    FileNameLength: DWORD;
    FileName: array[0..0] of WideChar;

    function GetFileName: UnicodeString;
    function NextEntry: PFileNotifyInformation;
  end;

  { TACLFileSystemWatcherCustomTask }

  TACLFileSystemWatcherCustomTask = class(TInterfacedObject, IACLFileSystemWatcherTask)
  strict private
    FChanges: TACLFileSystemChanges;
    FCombineSerialChanges: Boolean;
    FDelayTimer: TACLTimer;
    FEvent: TACLFileSystemWatcherNotifyEvent;
    FLockCount: Integer;

    procedure DelayTimerHandler(Sender: TObject);
    procedure SafeChanged;
  protected
    FPaths: TACLSearchPaths;

    procedure DoChanged; virtual;
    // IACLFileSystemWatcherTask
    procedure Changed;
    function GetChanges: TACLFileSystemChanges;
    function GetPaths: TACLSearchPaths;
    procedure LockChanges;
    procedure UnlockChanges;
  public
    constructor Create(AChanges: TACLFileSystemChanges;
      AEvent: TACLFileSystemWatcherNotifyEvent; ACombineSerialChanges: Boolean = True);
    destructor Destroy; override;
  end;

  { TACLFileSystemWatcherFileTask }

  TACLFileSystemWatcherFileTask = class(TACLFileSystemWatcherCustomTask)
  strict private
    FFileLastWriteTime: TDateTime;
    FFileName: string;
    FFileSize: Int64;

    procedure FetchFileInfo(out ASize: Int64; out ALastWriteTime: TDateTime);
  protected
    procedure DoChanged; override;
  public
    constructor Create(const AFileName: string; AEvent: TACLFileSystemWatcherNotifyEvent);
  end;

  { TACLFileSystemWatcherTask }

  TACLFileSystemWatcherTask = class(TACLFileSystemWatcherCustomTask)
  public
    constructor Create(const APaths: TACLSearchPaths; AChangeEvent: TACLFileSystemWatcherNotifyEvent;
      ACombineSerialChanges: Boolean = True; AChanges: TACLFileSystemChanges = AllFileSystemChanges); overload;
    constructor Create(const APaths: TACLStringList; ARecursive, ACombineSerialChanges: Boolean;
      AChanges: TACLFileSystemChanges; AEvent: TACLFileSystemWatcherNotifyEvent); overload;
  end;

  { TACLFileSystemWatcherThread }

  TACLFileSystemWatcherThread = class(TACLThread)
  strict private
    FHandleCount: Integer;
    FHandles: array[0..MAXIMUM_WAIT_OBJECTS - 1] of THandle;
    FWatcher: TACLFileSystemWatcher;
  protected
    procedure Execute; override;
    procedure TerminatedSet; override;
  public
    constructor Create(AWatcher: TACLFileSystemWatcher; AActiveTasks: TACLList<IACLFileSystemWatcherTask>;
      ATasks: TACLList<TPair<Integer, IACLFileSystemWatcherTask>>; var AIndex: Integer);
  end;

var
  FFileSystemWatcher: TACLFileSystemWatcher;
  FFileSystemWatcherFinalized: Boolean = False;

function FileSystemWatcher: TACLFileSystemWatcher;
begin
  if (FFileSystemWatcher = nil) and not FFileSystemWatcherFinalized then
    FFileSystemWatcher := TACLFileSystemWatcher.Create;
  Result := FFileSystemWatcher;
end;

function BuildNotifyFilter(AChanges: TACLFileSystemChanges): Cardinal;
const
  Map: array[TACLFileSystemChange] of Cardinal = (
    FILE_NOTIFY_CHANGE_FILE_NAME,
    FILE_NOTIFY_CHANGE_DIR_NAME,
    FILE_NOTIFY_CHANGE_ATTRIBUTES,
    FILE_NOTIFY_CHANGE_SIZE,
    FILE_NOTIFY_CHANGE_LAST_WRITE,
    FILE_NOTIFY_CHANGE_LAST_ACCESS
  );
var
  I: TACLFileSystemChange;
begin
  Result := 0;
  for I := Low(TACLFileSystemChange) to High(TACLFileSystemChange) do
  begin
    if I in AChanges then
      Result := Result or Map[I];
  end;
end;

{ TACLFileSystemWatcher }

constructor TACLFileSystemWatcher.Create;
begin
  inherited Create;
  FActiveTasks := TACLList<IACLFileSystemWatcherTask>.Create;
  FActiveThreads := TACLObjectList<TACLThread>.Create;
  FTasks := TACLList<IACLFileSystemWatcherTask>.Create;
  FLock := TACLCriticalSection.Create(Self);
end;

destructor TACLFileSystemWatcher.Destroy;
begin
  FActiveThreads.Clear;
  FreeAndNil(FLock);
  FreeAndNil(FTasks);
  FreeAndNil(FActiveTasks);
  FreeAndNil(FActiveThreads);
  inherited Destroy;
end;

function TACLFileSystemWatcher.Add(const APath: UnicodeString; AChangeEvent: TACLFileSystemWatcherNotifyEvent;
  ARecursive: Boolean = True; AChanges: TACLFileSystemChanges = AllFileSystemChanges;
  ACombineSerialChanges: Boolean = True): IACLFileSystemWatcherTask;
var
  APaths: TACLStringList;
begin
  APaths := TACLStringList.Create(APath);
  try
    Result := Add(APaths, AChangeEvent, ARecursive, AChanges, ACombineSerialChanges);
  finally
    APaths.Free;
  end;
end;

function TACLFileSystemWatcher.Add(const APaths: TACLSearchPaths; AChangeEvent: TACLFileSystemWatcherNotifyEvent;
  AChanges: TACLFileSystemChanges = AllFileSystemChanges; ACombineSerialChanges: Boolean = True): IACLFileSystemWatcherTask;
begin
  FLock.Enter;
  try
    FActiveThreads.Clear;
    Result := TACLFileSystemWatcherTask.Create(APaths, AChangeEvent, ACombineSerialChanges, AChanges);
    FTasks.Add(Result);
    SafeStartThreads;
  finally
    FLock.Leave;
  end;
end;

function TACLFileSystemWatcher.Add(const APaths: TACLStringList; AChangeEvent: TACLFileSystemWatcherNotifyEvent;
  ARecursive: Boolean = True; AChanges: TACLFileSystemChanges = AllFileSystemChanges;
  ACombineSerialChanges: Boolean = True): IACLFileSystemWatcherTask;
begin
  FLock.Enter;
  try
    FActiveThreads.Clear;
    Result := TACLFileSystemWatcherTask.Create(APaths, ARecursive, ACombineSerialChanges, AChanges, AChangeEvent);
    FTasks.Add(Result);
    SafeStartThreads;
  finally
    FLock.Leave;
  end;
end;

function TACLFileSystemWatcher.AddFile(const AFileName: string;
  AChangeEvent: TACLFileSystemWatcherNotifyEvent): IACLFileSystemWatcherTask;
begin
  FLock.Enter;
  try
    FActiveThreads.Clear;
    Result := TACLFileSystemWatcherFileTask.Create(AFileName, AChangeEvent);
    FTasks.Add(Result);
    SafeStartThreads;
  finally
    FLock.Leave;
  end;
end;

procedure TACLFileSystemWatcher.Remove(var ATask: IACLFileSystemWatcherTask);
begin
  FLock.Enter;
  try
    if FTasks.IndexOf(ATask) >= 0 then
    begin
      FActiveThreads.Clear;
      FTasks.Remove(ATask);
      SafeStartThreads;
    end;
    ATask := nil;
  finally
    FLock.Leave;
  end;
end;

procedure TACLFileSystemWatcher.DoAsyncChangeNotify(ATaskIndex: Integer);
var
  ATask: IACLFileSystemWatcherTask;
begin
  FLock.Enter;
  try
    if (ATaskIndex >= 0) and (ATaskIndex < FActiveTasks.Count) then
      ATask := FActiveTasks.List[ATaskIndex]
    else
      ATask := nil;
  finally
    FLock.Leave;
  end;

  if ATask <> nil then
    ATask.Changed;
end;

procedure TACLFileSystemWatcher.SafeStartThreads;

  function PopulatePaths: TACLList<TPair<Integer, IACLFileSystemWatcherTask>>;
  var
    ATask: IACLFileSystemWatcherTask;
    I, J: Integer;
  begin
    Result := TACLList<TPair<Integer, IACLFileSystemWatcherTask>>.Create;
    for I := 0 to FTasks.Count - 1 do
    begin
      ATask := FTasks.List[I];
      for J := 0 to ATask.GetPaths.Count - 1 do
        Result.Add(TPair<Integer, IACLFileSystemWatcherTask>.Create(J, ATask));
    end;
  end;

var
  AIndex: Integer;
  APaths: TACLList<TPair<Integer, IACLFileSystemWatcherTask>>;
begin
  APaths := PopulatePaths;
  try
    AIndex := 0;
    FActiveTasks.Clear;
    while AIndex < APaths.Count do
    try
      FActiveThreads.Add(TACLFileSystemWatcherThread.Create(Self, FActiveTasks, APaths, AIndex));
    except
      // do nothing
    end;
  finally
    APaths.Free;
  end;
end;

{ TACLFileSystemWatcherEx }

constructor TACLFileSystemWatcherEx.Create(const APath: UnicodeString;
  AChanges: TACLFileSystemChanges; AWatchSubTree: Boolean);
begin
  FWatchSubTree := AWatchSubTree;
  FNotifyFilter := BuildNotifyFilter(AChanges);
  FPath := acIncludeTrailingPathDelimiter(APath);
  FHandle := CreateFile(PChar(FPath), FILE_LIST_DIRECTORY,
    FILE_SHARE_READ or FILE_SHARE_DELETE or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
    FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OVERLAPPED, 0);
  if FHandle = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
  inherited Create(False);
end;

destructor TACLFileSystemWatcherEx.Destroy;
begin
  CloseHandle(FHandle);
  inherited Destroy;
end;

procedure TACLFileSystemWatcherEx.DoAsyncFileAdded(const AFileName: UnicodeString);
begin
  if Assigned(OnAsyncFileAdded) then
    OnAsyncFileAdded(AFileName);
end;

procedure TACLFileSystemWatcherEx.DoAsyncFileChanged(const AFileName: UnicodeString);
begin
  if Assigned(OnAsyncFileChanged) then
    OnAsyncFileChanged(AFileName);
end;

procedure TACLFileSystemWatcherEx.DoAsyncFileRemoved(const AFileName: UnicodeString);
begin
  if Assigned(OnAsyncFileRemoved) then
    OnAsyncFileRemoved(AFileName);
end;

procedure TACLFileSystemWatcherEx.DoAsyncFileRenamed(const AOldFileName, ANewFileName: UnicodeString);
begin
  if Assigned(OnAsyncFileRenamed) then
    OnAsyncFileRenamed(AOldFileName, ANewFileName);
end;

procedure TACLFileSystemWatcherEx.Execute;
const
  BufferSize = SizeOf(TFileNotifyInformation) + MAX_LONG_PATH;
var
  ABuffer: PByte;
  AEvent: TEvent;
  AInfo: PFileNotifyInformation;
  AOverlapped: TOverlapped;
  AResult: TWaitResult;
  ASize: DWORD;
begin
  AEvent := TEvent.Create;
  ABuffer := AllocMem(BufferSize);
  try
    ZeroMemory(@AOverlapped, SizeOf(AOverlapped));
    AOverlapped.hEvent := AEvent.Handle;

    while not Terminated do
    begin
      AEvent.ResetEvent;
      if ReadDirectoryChangesW(FHandle, ABuffer, BufferSize, FWatchSubTree, FNotifyFilter, @ASize, @AOverlapped, nil) then
      repeat
        AResult := AEvent.WaitFor(1000);
        if (AResult = wrSignaled) and GetOverlappedResult(FHandle, AOverlapped, ASize, True) and (ASize > 0) then
        begin
          AInfo := PFileNotifyInformation(ABuffer);
          repeat
            case AInfo.Action of
              FILE_ACTION_ADDED:
                DoAsyncFileAdded(FPath + AInfo.GetFileName);
              FILE_ACTION_REMOVED:
                DoAsyncFileRemoved(FPath + AInfo.GetFileName);
              FILE_ACTION_MODIFIED:
                DoAsyncFileChanged(FPath + AInfo.GetFileName);
              FILE_ACTION_RENAMED_OLD_NAME:
                if AInfo.NextEntry.Action = FILE_ACTION_RENAMED_NEW_NAME then
                begin
                  DoAsyncFileRenamed(FPath + AInfo.GetFileName, FPath + AInfo.NextEntry.GetFileName);
                  AInfo := AInfo.NextEntry;
                end;
            end;
            AInfo := AInfo.NextEntry;
          until AInfo.NextEntryOffset = 0;
        end;
      until Terminated or (AResult <> wrTimeout);
    end;
  finally
    FreeMem(ABuffer, BufferSize);
    AEvent.Free;
  end;
end;

{ TFileNotifyInformation }

function TFileNotifyInformation.GetFileName: UnicodeString;
begin
  SetString(Result, PWideChar(@FileName[0]), FileNameLength div SizeOf(WideChar));
end;

function TFileNotifyInformation.NextEntry: PFileNotifyInformation;
begin
  Result := PFileNotifyInformation(NativeUInt(@Self) + NextEntryOffset);
end;

{ TACLFileSystemWatcherCustomTask }

constructor TACLFileSystemWatcherCustomTask.Create(AChanges: TACLFileSystemChanges;
  AEvent: TACLFileSystemWatcherNotifyEvent; ACombineSerialChanges: Boolean = True);
begin
  FEvent := AEvent;
  FChanges := AChanges;
  FPaths := TACLSearchPaths.Create;
  FCombineSerialChanges := ACombineSerialChanges;
end;

destructor TACLFileSystemWatcherCustomTask.Destroy;
begin
  FreeAndNil(FDelayTimer);
  FreeAndNil(FPaths);
  inherited Destroy;
end;

procedure TACLFileSystemWatcherCustomTask.DoChanged;
begin
  if Assigned(FEvent) then FEvent(Self);
end;

procedure TACLFileSystemWatcherCustomTask.Changed;
begin
  if FLockCount = 0 then
    RunInMainThread(SafeChanged);
end;

function TACLFileSystemWatcherCustomTask.GetChanges: TACLFileSystemChanges;
begin
  Result := FChanges;
end;

function TACLFileSystemWatcherCustomTask.GetPaths: TACLSearchPaths;
begin
  Result := FPaths;
end;

procedure TACLFileSystemWatcherCustomTask.LockChanges;
begin
  Inc(FLockCount);
end;

procedure TACLFileSystemWatcherCustomTask.UnlockChanges;
begin
  Dec(FLockCount);
end;

procedure TACLFileSystemWatcherCustomTask.DelayTimerHandler(Sender: TObject);
begin
  FDelayTimer.Enabled := False;
  DoChanged;
end;

procedure TACLFileSystemWatcherCustomTask.SafeChanged;
begin
  if FCombineSerialChanges then
  begin
    if FDelayTimer = nil then
      FDelayTimer := TACLTimer.CreateEx(DelayTimerHandler, 2000);
    FDelayTimer.Restart;
  end
  else
    DoChanged;
end;

{ TACLFileSystemWatcherFileTask }

constructor TACLFileSystemWatcherFileTask.Create(const AFileName: string; AEvent: TACLFileSystemWatcherNotifyEvent);
begin
  inherited Create([fscFiles, fscSize, fscLastWriteTime], AEvent);
  FFileName := AFileName;
  FetchFileInfo(FFileSize, FFileLastWriteTime);
  FPaths.Add(acExtractFilePath(FFileName), False);
end;

procedure TACLFileSystemWatcherFileTask.DoChanged;
var
  ASize: Int64;
  ATime: TDateTime;
begin
  FetchFileInfo(ASize, ATime);
  if (ASize <> FFileSize) or not SameDateTime(ATime, FFileLastWriteTime) then
  begin
    FFileSize := ASize;
    FFileLastWriteTime := ATime;
    inherited DoChanged;
  end;
end;

procedure TACLFileSystemWatcherFileTask.FetchFileInfo(out ASize: Int64; out ALastWriteTime: TDateTime);
var
  AFileData: TWin32FindData;
begin
  if TACLFileDateTimeHelper.GetFileData(FFileName, AFileData) then
  begin
    ALastWriteTime := TACLFileDateTimeHelper.DecodeTime(AFileData.ftLastWriteTime);
    ASize := MakeInt64(AFileData.nFileSizeLow, AFileData.nFileSizeHigh);
  end
  else
  begin
    ALastWriteTime := 0;
    ASize := 0;
  end;
end;

{ TACLFileSystemWatcherTask }

constructor TACLFileSystemWatcherTask.Create(const APaths: TACLSearchPaths;
  AChangeEvent: TACLFileSystemWatcherNotifyEvent; ACombineSerialChanges: Boolean = True;
  AChanges: TACLFileSystemChanges = AllFileSystemChanges);
var
  I: Integer;
begin
  Create(AChanges, AChangeEvent, ACombineSerialChanges);
  for I := 0 to APaths.Count - 1 do
    FPaths.Add(acIncludeTrailingPathDelimiter(APaths[I]), APaths.Recursive[I]);
end;

constructor TACLFileSystemWatcherTask.Create(const APaths: TACLStringList;
  ARecursive, ACombineSerialChanges: Boolean; AChanges: TACLFileSystemChanges;
  AEvent: TACLFileSystemWatcherNotifyEvent);
var
  I: Integer;
begin
  Create(AChanges, AEvent, ACombineSerialChanges);
  for I := 0 to APaths.Count - 1 do
    FPaths.Add(acIncludeTrailingPathDelimiter(APaths[I]), ARecursive);
end;

{ TACLFileSystemWatcherThread }

constructor TACLFileSystemWatcherThread.Create(
  AWatcher: TACLFileSystemWatcher; AActiveTasks: TACLList<IACLFileSystemWatcherTask>;
  ATasks: TACLList<TPair<Integer, IACLFileSystemWatcherTask>>; var AIndex: Integer);
const
  Map: array [Boolean] of TACLFileSystemChanges = ([fscFolders], []);
var
  AHandle: THandle;
  AMode: DWORD;
  APathIndex: Integer;
  ARecursive: Boolean;
  ATask: IACLFileSystemWatcherTask;
begin
  FWatcher := AWatcher;
  FreeOnTerminate := False;

  AMode := acSetThreadErrorMode(SEM_FAILCRITICALERRORS);
  try
    while (AIndex < ATasks.Count) and (FHandleCount < MAXIMUM_WAIT_OBJECTS) do
    begin
      ATask := ATasks.List[AIndex].Value;
      APathIndex := ATasks.List[AIndex].Key;
      ARecursive := ATask.GetPaths.Recursive[APathIndex];

      AHandle := FindFirstChangeNotification(PChar(ATask.GetPaths[APathIndex]), ARecursive, BuildNotifyFilter(ATask.GetChanges - Map[ARecursive]));
      if AHandle <> INVALID_HANDLE_VALUE then
      begin
        AActiveTasks.Add(ATask);
        FHandles[FHandleCount] := AHandle;
        Inc(FHandleCount);
      end;
      Inc(AIndex);
    end;
  finally
    acSetThreadErrorMode(AMode);
  end;

  if FHandleCount = 0 then
    Abort;
  inherited Create(False);
end;

procedure TACLFileSystemWatcherThread.Execute;
var
  ACode: Integer;
  AIndex: Integer;
begin
  while not Terminated do
  begin
    ACode := WaitForMultipleObjects(FHandleCount, @FHandles[0], False, INFINITE);
    case ACode of
      WAIT_OBJECT_0 .. WAIT_OBJECT_0 + MAXIMUM_WAIT_OBJECTS - 1:
        if not Terminated then
        begin
          AIndex := ACode - WAIT_OBJECT_0;
          FWatcher.DoAsyncChangeNotify(AIndex);
          FindNextChangeNotification(FHandles[AIndex]);
        end;
    end;
  end;
end;

procedure TACLFileSystemWatcherThread.TerminatedSet;
var
  I: Integer;
begin
  inherited TerminatedSet;
  for I := 0 to FHandleCount - 1 do
  begin
    FindCloseChangeNotification(FHandles[I]);
    FHandles[I] := 0;
  end;
end;

initialization

finalization
  FFileSystemWatcherFinalized := True;
  FreeAndNil(FFileSystemWatcher);
end.
