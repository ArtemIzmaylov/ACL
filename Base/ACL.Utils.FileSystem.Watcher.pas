{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*        FileSystem Change Watchers         *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.FileSystem.Watcher;

{$I ACL.Config.inc}

interface

uses
  Winapi.Messages,
  Winapi.Windows,
  // System
  System.Classes,
  System.DateUtils,
  System.Generics.Collections,
  System.Math,
  System.IOUtils,
  System.SyncObjs,
  System.SysUtils,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.Timers,
  ACL.Threading,
  ACL.Threading.Pool,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Messaging,
  ACL.Utils.Strings;

type
  TACLFileSystemChange = (fscFiles, fscFolders, fscAttributes, fscSize, fscLastWriteTime, fscLastAccessTime);
  TACLFileSystemChanges = set of TACLFileSystemChange;

const
  AllFileSystemChanges = [fscFiles..fscLastAccessTime];

type

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

  TACLFileSystemWatcherNotifyEvent = procedure (ATask: IACLFileSystemWatcherTask) of object;
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
    function Add(const APath: UnicodeString;
      AChangeEvent: TACLFileSystemWatcherNotifyEvent; ARecursive: Boolean = True;
      AChanges: TACLFileSystemChanges = AllFileSystemChanges): IACLFileSystemWatcherTask; overload;
    function Add(const APaths: TACLSearchPaths;
      AChangeEvent: TACLFileSystemWatcherNotifyEvent;
      AChanges: TACLFileSystemChanges = AllFileSystemChanges): IACLFileSystemWatcherTask; overload;
    function Add(const APaths: TACLStringList;
      AChangeEvent: TACLFileSystemWatcherNotifyEvent; ARecursive: Boolean = True;
      AChanges: TACLFileSystemChanges = AllFileSystemChanges): IACLFileSystemWatcherTask; overload;
    function AddFile(const AFileName: string;
      AChangeEvent: TACLFileSystemWatcherNotifyEvent): IACLFileSystemWatcherTask;

    procedure Remove(var ATask: IACLFileSystemWatcherTask);
  end;

function FileSystemWatcher: TACLFileSystemWatcher;
implementation

uses
  ACL.Math;

type

  { TACLFileSystemWatcherCustomTask }

  TACLFileSystemWatcherCustomTask = class(TInterfacedObject, IACLFileSystemWatcherTask)
  strict private
    FChanges: TACLFileSystemChanges;
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
    constructor Create(AChanges: TACLFileSystemChanges; AEvent: TACLFileSystemWatcherNotifyEvent);
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
    constructor Create(const APaths: TACLSearchPaths;
      AChangeEvent: TACLFileSystemWatcherNotifyEvent;
      AChanges: TACLFileSystemChanges); overload;
    constructor Create(const APaths: TACLStringList; ARecursive: Boolean;
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

function TACLFileSystemWatcher.Add(const APath: UnicodeString;
  AChangeEvent: TACLFileSystemWatcherNotifyEvent; ARecursive: Boolean;
  AChanges: TACLFileSystemChanges): IACLFileSystemWatcherTask;
var
  APaths: TACLStringList;
begin
  APaths := TACLStringList.Create(APath);
  try
    Result := Add(APaths, AChangeEvent, ARecursive, AChanges);
  finally
    APaths.Free;
  end;
end;

function TACLFileSystemWatcher.Add(const APaths: TACLSearchPaths;
  AChangeEvent: TACLFileSystemWatcherNotifyEvent;
  AChanges: TACLFileSystemChanges): IACLFileSystemWatcherTask;
begin
  FLock.Enter;
  try
    FActiveThreads.Clear;
    Result := TACLFileSystemWatcherTask.Create(APaths, AChangeEvent, AChanges);
    FTasks.Add(Result);
    SafeStartThreads;
  finally
    FLock.Leave;
  end;
end;

function TACLFileSystemWatcher.Add(const APaths: TACLStringList;
  AChangeEvent: TACLFileSystemWatcherNotifyEvent; ARecursive: Boolean;
  AChanges: TACLFileSystemChanges): IACLFileSystemWatcherTask;
begin
  FLock.Enter;
  try
    FActiveThreads.Clear;
    Result := TACLFileSystemWatcherTask.Create(APaths, ARecursive, AChanges, AChangeEvent);
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

{ TACLFileSystemWatcherCustomTask }

constructor TACLFileSystemWatcherCustomTask.Create(
  AChanges: TACLFileSystemChanges; AEvent: TACLFileSystemWatcherNotifyEvent);
begin
  FEvent := AEvent;
  FChanges := AChanges;
  FPaths := TACLSearchPaths.Create;
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
  if FDelayTimer = nil then
    FDelayTimer := TACLTimer.CreateEx(DelayTimerHandler, 2000);
  FDelayTimer.Restart;
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
  LStat: TACLFileStat;
begin
  if LStat.Init(FFileName) then
  begin
    ALastWriteTime := LStat.LastWriteTime;
    ASize := LStat.Size;
  end
  else
  begin
    ALastWriteTime := 0;
    ASize := 0;
  end;
end;

{ TACLFileSystemWatcherTask }

constructor TACLFileSystemWatcherTask.Create(const APaths: TACLSearchPaths;
  AChangeEvent: TACLFileSystemWatcherNotifyEvent; AChanges: TACLFileSystemChanges);
var
  I: Integer;
begin
  Create(AChanges, AChangeEvent);
  for I := 0 to APaths.Count - 1 do
    FPaths.Add(acIncludeTrailingPathDelimiter(APaths[I]), APaths.Recursive[I]);
end;

constructor TACLFileSystemWatcherTask.Create(
  const APaths: TACLStringList; ARecursive: Boolean;
  AChanges: TACLFileSystemChanges; AEvent: TACLFileSystemWatcherNotifyEvent);
var
  I: Integer;
begin
  Create(AChanges, AEvent);
  for I := 0 to APaths.Count - 1 do
    FPaths.Add(acIncludeTrailingPathDelimiter(APaths[I]), ARecursive);
end;

{ TACLFileSystemWatcherThread }

constructor TACLFileSystemWatcherThread.Create(
  AWatcher: TACLFileSystemWatcher; AActiveTasks: TACLList<IACLFileSystemWatcherTask>;
  ATasks: TACLList<TPair<Integer, IACLFileSystemWatcherTask>>; var AIndex: Integer);
var
  AChanges: TACLFileSystemChanges;
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

      AChanges := ATask.GetChanges;
      if not ARecursive then
      begin
        Exclude(AChanges, fscFolders);
        Exclude(AChanges, fscLastWriteTime);
      end;

      AHandle := FindFirstChangeNotification(PChar(ATask.GetPaths[APathIndex]), ARecursive, BuildNotifyFilter(AChanges));
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
