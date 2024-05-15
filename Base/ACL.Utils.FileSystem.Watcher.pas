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

{$REGION ' FileSystem Watcher '}
type
  TACLFileSystemChange = (
    fscContent,    // content, size or last-write-date
    fscAttributes, // attributes
    fscSubElements // sub-files/folders (creating, renaming, removing)
  );
  TACLFileSystemChanges = set of TACLFileSystemChange;

const
  AllFileSystemChanges = [Low(TACLFileSystemChange)..High(TACLFileSystemChange)];

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
    class var FActiveMonitors: TACLObjectList;
    class var FActiveTasks: TACLList<IACLFileSystemWatcherTask>;
    class var FLock: TACLCriticalSection;
    class var FTasks: TACLList<IACLFileSystemWatcherTask>;
    class procedure SafeStartMonitors;
    class procedure SafeStopMonitors;
  protected
    class procedure DoAsyncChangeNotify(ATaskIndex: Integer);
  public
    class constructor Create;
    class destructor Destroy;
    class function Add(const APath: string;
      AChangeEvent: TACLFileSystemWatcherNotifyEvent; ARecursive: Boolean = True;
      AChanges: TACLFileSystemChanges = AllFileSystemChanges): IACLFileSystemWatcherTask; overload;
    class function Add(const APaths: TACLSearchPaths;
      AChangeEvent: TACLFileSystemWatcherNotifyEvent;
      AChanges: TACLFileSystemChanges = AllFileSystemChanges): IACLFileSystemWatcherTask; overload;
    class function Add(const APaths: TACLStringList;
      AChangeEvent: TACLFileSystemWatcherNotifyEvent; ARecursive: Boolean = True;
      AChanges: TACLFileSystemChanges = AllFileSystemChanges): IACLFileSystemWatcherTask; overload;
    class function AddFile(const AFileName: string;
      AChangeEvent: TACLFileSystemWatcherNotifyEvent): IACLFileSystemWatcherTask;
    class procedure Remove(var ATask: IACLFileSystemWatcherTask);
  end;

{$ENDREGION}

implementation

uses
  ACL.Math;

{$REGION ' FileSystem Watcher '}

type
  TTaskIndexedPair = TPair<Integer, IACLFileSystemWatcherTask>;
  TTaskIndexedPairList = TACLList<TTaskIndexedPair>;

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

  { TACLFileSystemWatcherMonitor }

  TACLFileSystemWatcherMonitor = class(TACLThread)
  strict private
    FHandleCount: Integer;
    FHandles: array[0..MAXIMUM_WAIT_OBJECTS - 1] of THandle;
  protected
    procedure Execute; override;
    procedure TerminatedSet; override;
  public
    constructor Create(
      AActiveTasks: TACLList<IACLFileSystemWatcherTask>;
      ATasks: TTaskIndexedPairList; var AIndex: Integer);
  end;
  
{ TACLFileSystemWatcherMonitor }

constructor TACLFileSystemWatcherMonitor.Create(
  AActiveTasks: TACLList<IACLFileSystemWatcherTask>;
  ATasks: TTaskIndexedPairList; var AIndex: Integer);
var
  AFlags: Cardinal;
  AHandle: THandle;
  AMode: DWORD;
  APathFlags: Cardinal;
  APathIndex: Integer;
  ARecursive: Boolean;
  ATask: IACLFileSystemWatcherTask;
begin
  FreeOnTerminate := False;

  AFlags := 0;
  if fscContent in ATask.GetChanges then
    AFlags := AFlags or FILE_NOTIFY_CHANGE_SIZE or FILE_NOTIFY_CHANGE_LAST_WRITE;
  if fscAttributes in ATask.GetChanges then
    AFlags := AFlags or FILE_NOTIFY_CHANGE_ATTRIBUTES;
  if fscSubElements in ATask.GetChanges then
    AFlags := AFlags or FILE_NOTIFY_CHANGE_FILE_NAME or FILE_NOTIFY_CHANGE_DIR_NAME;

  AMode := acSetThreadErrorMode(SEM_FAILCRITICALERRORS);
  try
    while (AIndex < ATasks.Count) and (FHandleCount < MAXIMUM_WAIT_OBJECTS) do
    begin
      ATask := ATasks.List[AIndex].Value;
      APathIndex := ATasks.List[AIndex].Key;
      ARecursive := ATask.GetPaths.Recursive[APathIndex];

      APathFlags := AFlags;
      if not ARecursive then
      begin
        APathFlags := APathFlags and not FILE_NOTIFY_CHANGE_DIR_NAME;
        APathFlags := APathFlags and not FILE_NOTIFY_CHANGE_LAST_WRITE;
      end;

      AHandle := FindFirstChangeNotification(PChar(ATask.GetPaths[APathIndex]), ARecursive, APathFlags);
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

procedure TACLFileSystemWatcherMonitor.Execute;
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
          TACLFileSystemWatcher.DoAsyncChangeNotify(AIndex);
          FindNextChangeNotification(FHandles[AIndex]);
        end;
    end;
  end;
end;

procedure TACLFileSystemWatcherMonitor.TerminatedSet;
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

{ TACLFileSystemWatcher }

class constructor TACLFileSystemWatcher.Create;
begin
  FActiveMonitors := TACLObjectList.Create;
  FActiveTasks := TACLList<IACLFileSystemWatcherTask>.Create;
  FTasks := TACLList<IACLFileSystemWatcherTask>.Create;
  FLock := TACLCriticalSection.Create(nil, 'FileSystemWatcher');
end;

class destructor TACLFileSystemWatcher.Destroy;
begin
  SafeStopMonitors;
  FreeAndNil(FLock);
  FreeAndNil(FTasks);
  FreeAndNil(FActiveTasks);
  FreeAndNil(FActiveMonitors);
end;

class function TACLFileSystemWatcher.Add(const APath: string;
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

class function TACLFileSystemWatcher.Add(const APaths: TACLSearchPaths;
  AChangeEvent: TACLFileSystemWatcherNotifyEvent;
  AChanges: TACLFileSystemChanges): IACLFileSystemWatcherTask;
begin
  FLock.Enter;
  try
    SafeStopMonitors;
    Result := TACLFileSystemWatcherTask.Create(APaths, AChangeEvent, AChanges);
    FTasks.Add(Result);
    SafeStartMonitors;
  finally
    FLock.Leave;
  end;
end;

class function TACLFileSystemWatcher.Add(const APaths: TACLStringList;
  AChangeEvent: TACLFileSystemWatcherNotifyEvent; ARecursive: Boolean;
  AChanges: TACLFileSystemChanges): IACLFileSystemWatcherTask;
begin
  FLock.Enter;
  try
    SafeStopMonitors;
    Result := TACLFileSystemWatcherTask.Create(APaths, ARecursive, AChanges, AChangeEvent);
    FTasks.Add(Result);
    SafeStartMonitors;
  finally
    FLock.Leave;
  end;
end;

class function TACLFileSystemWatcher.AddFile(const AFileName: string;
  AChangeEvent: TACLFileSystemWatcherNotifyEvent): IACLFileSystemWatcherTask;
begin
  FLock.Enter;
  try
    SafeStopMonitors;
    Result := TACLFileSystemWatcherFileTask.Create(AFileName, AChangeEvent);
    FTasks.Add(Result);
    SafeStartMonitors;
  finally
    FLock.Leave;
  end;
end;

class procedure TACLFileSystemWatcher.Remove(var ATask: IACLFileSystemWatcherTask);
begin
  if FLock <> nil then
  begin
    FLock.Enter;
    try
      if FTasks.IndexOf(ATask) >= 0 then
      begin
        SafeStopMonitors;
        FTasks.Remove(ATask);
        SafeStartMonitors;
      end;
      ATask := nil;
    finally
      FLock.Leave;
    end;
  end;
  ATask := nil;
end;

class procedure TACLFileSystemWatcher.DoAsyncChangeNotify(ATaskIndex: Integer);
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

class procedure TACLFileSystemWatcher.SafeStartMonitors;

  function PopulatePaths: TTaskIndexedPairList;
  var
    ATask: IACLFileSystemWatcherTask;
    I, J: Integer;
  begin
    Result := TTaskIndexedPairList.Create;
    for I := 0 to FTasks.Count - 1 do
    begin
      ATask := FTasks.List[I];
      for J := 0 to ATask.GetPaths.Count - 1 do
        Result.Add(TTaskIndexedPair.Create(J, ATask));
    end;
  end;

var
  AIndex: Integer;
  APaths: TTaskIndexedPairList;
begin
  APaths := PopulatePaths;
  try
    AIndex := 0;
    FActiveTasks.Clear;
    while AIndex < APaths.Count do
    try
      FActiveMonitors.Add(TACLFileSystemWatcherMonitor.Create(FActiveTasks, APaths, AIndex));
    except
      // do nothing
    end;
  finally
    APaths.Free;
  end;
end;

class procedure TACLFileSystemWatcher.SafeStopMonitors;
begin
  FActiveMonitors.Clear;
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

constructor TACLFileSystemWatcherFileTask.Create(
  const AFileName: string; AEvent: TACLFileSystemWatcherNotifyEvent);
begin
  inherited Create([fscContent, fscSubElements], AEvent);
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

{$ENDREGION}

end.
