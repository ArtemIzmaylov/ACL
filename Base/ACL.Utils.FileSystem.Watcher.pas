////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   FileSystem Changes Watcher
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Utils.FileSystem.Watcher;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  glib2,
{$ELSE}
  Winapi.Messages,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}DateUtils,
  {System.}Generics.Collections,
  {System.}Math,
  {System.}SysUtils,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
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

{$REGION ' Drive Manager '}

  TACLDriveType = (dtUnknown, dtFixed, dtRemovable, dtOther);
  TACLDriveTypes = set of TACLDriveType;

  { TACLDriveInfo }

  PACLDriveInfo = ^TACLDriveInfo;
  TACLDriveInfo = record
  private
    FSerial: Cardinal;
    FTitle: string;
    FType: TACLDriveType;
    function FetchDriveType: TACLDriveType;
    function FetchTitle: string;
  public
    Path: string;
    procedure Flush;
    function GetSerial: Cardinal;
    function GetTitle(const ADefault: string = ''): string;
    function GetType: TACLDriveType;
  end;

  { TACLDriveManager }

  TACLDriveManager = class
  public type
    TCallback = procedure (const Drive: TACLDriveInfo; Mounted: Boolean) of object;
    TEnumProc = reference to procedure (const Drive: TACLDriveInfo);
  strict private
    class var FList: TACLList<TACLDriveInfo>;
    class var FListeners: TACLList<TCallback>;
    class var FLock: TACLCriticalSection;
    class var FMonitor: TObject;
    class function SafeFind(const ADrive: string; out AIndex: Integer): Boolean;
  protected
    class procedure Changed(const ADrive: string;
      AMounted: Boolean; AInfo: PACLDriveInfo = nil);
    class function CheckDrivePath(const ADrive: string): string;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure EnsureReady;
    class procedure Enum(AProc: TEnumProc);
    class function GetInfo(const ADrive: string): TACLDriveInfo;
    class procedure ListenerAdd(AListener: TCallback);
    class procedure ListenerRemove(AListener: TCallback);
  end;

{$ENDREGION}

implementation

uses
{$IFDEF FPC}
  ACL.Utils.FileSystem.GIO,
{$ELSE}
  ACL.FileFormats.INI,
{$ENDIF}
  System.IOUtils;

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

{$IFDEF FPC}

  TACLFileSystemWatcherMonitor = class
  strict private
    FCancelable: PGCancellable;
    FMonitor: TGioFileMonitor;
    FTask: IACLFileSystemWatcherTask;
    procedure ChangeNotify(AFile, AOtherFile: PGFile; AEvent: TGFileMonitorEvent);
  public
    constructor Create(
      AActiveTasks: TACLList<IACLFileSystemWatcherTask>;
      ATasks: TTaskIndexedPairList; var AIndex: Integer);
    destructor Destroy; override;
  end;

{$ELSE}

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
{$ENDIF}

{$IFDEF FPC}

{ TACLFileSystemWatcherMonitor }

constructor TACLFileSystemWatcherMonitor.Create(
  AActiveTasks: TACLList<IACLFileSystemWatcherTask>;
  ATasks: TTaskIndexedPairList; var AIndex: Integer);
var
  LPathIndex: Integer;
begin
  FTask := ATasks.List[AIndex].Value;
  LPathIndex := ATasks.List[AIndex].Key;
  FCancelable := g_cancellable_new();

  FMonitor := TGioFileMonitor.Create(FCancelable,
    g_file_new_for_path(PChar(FTask.GetPaths.Paths[LPathIndex])),
    ChangeNotify, IfThen(FTask.GetPaths.Recursive[LPathIndex], MaxInt));
  Inc(AIndex);
end;

destructor TACLFileSystemWatcherMonitor.Destroy;
begin
  if FCancelable <> nil then
  begin
    g_cancellable_cancel(FCancelable);
    g_object_unref(FCancelable);
  end;
  FreeAndNil(FMonitor);
  inherited Destroy;
end;

procedure TACLFileSystemWatcherMonitor.ChangeNotify(
  AFile, AOtherFile: PGFile; AEvent: TGFileMonitorEvent);
var
  LChanges: TACLFileSystemChanges;
begin
  LChanges := [];
  case AEvent of // https://docs.gtk.org/gio/enum.FileMonitorEvent.html
    G_FILE_MONITOR_EVENT_ATTRIBUTE_CHANGED:
      LChanges := [fscAttributes];
    G_FILE_MONITOR_EVENT_CHANGED:
      LChanges := [fscContent];
    G_FILE_MONITOR_EVENT_MOVED,
    G_FILE_MONITOR_EVENT_MOVED_IN,
    G_FILE_MONITOR_EVENT_MOVED_OUT,
    G_FILE_MONITOR_EVENT_RENAMED,
    G_FILE_MONITOR_EVENT_CREATED,
    G_FILE_MONITOR_EVENT_DELETED,
    G_FILE_MONITOR_EVENT_UNMOUNTED:
      LChanges := [fscSubElements];
  else
    LChanges := [];
  end;
  if LChanges * FTask.GetChanges <> [] then
    FTask.Changed;
end;

{$ELSE}

{ TACLFileSystemWatcherMonitor }

constructor TACLFileSystemWatcherMonitor.Create(
  AActiveTasks: TACLList<IACLFileSystemWatcherTask>;
  ATasks: TTaskIndexedPairList; var AIndex: Integer);
var
  AFlags: Cardinal;
  AHandle: THandle;
  AMode: DWORD;
  APathIndex: Integer;
  ARecursive: Boolean;
  ATask: IACLFileSystemWatcherTask;
begin
  FreeOnTerminate := False;

  AMode := acSetThreadErrorMode(SEM_FAILCRITICALERRORS);
  try
    while (AIndex < ATasks.Count) and (FHandleCount < MAXIMUM_WAIT_OBJECTS) do
    begin
      ATask := ATasks.List[AIndex].Value;
      APathIndex := ATasks.List[AIndex].Key;
      ARecursive := ATask.GetPaths.Recursive[APathIndex];

      AFlags := 0;
      if fscContent in ATask.GetChanges then
        AFlags := AFlags or FILE_NOTIFY_CHANGE_SIZE or FILE_NOTIFY_CHANGE_LAST_WRITE;
      if fscAttributes in ATask.GetChanges then
        AFlags := AFlags or FILE_NOTIFY_CHANGE_ATTRIBUTES;
      if fscSubElements in ATask.GetChanges then
        AFlags := AFlags or FILE_NOTIFY_CHANGE_FILE_NAME or FILE_NOTIFY_CHANGE_DIR_NAME;
      if not ARecursive then
      begin
        AFlags := AFlags and not FILE_NOTIFY_CHANGE_DIR_NAME;
        AFlags := AFlags and not FILE_NOTIFY_CHANGE_LAST_WRITE;
      end;

      AHandle := FindFirstChangeNotification(PChar(ATask.GetPaths[APathIndex]), ARecursive, AFlags);
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
{$ENDIF}

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

{$REGION ' Drive Manager '}
type
{$IFDEF FPC}

  { TACLDriveMonitor }

  TACLDriveMonitor = class
  strict private
    FCurrent: TACLStringList;
    FMonitor: PGUnixMountMonitor;
    procedure Changed;
    class procedure Notify(Monitor: PGUnixMountMonitor; Data: TACLDriveMonitor); cdecl; static;
  public
    constructor Create;
    destructor Destroy; override;
    procedure WaitFor;
  end;

{$ELSE}

  TACLDriveMonitor = class(TACLTaskGroup)
  strict private type
  {$REGION ' Internals '}
    TCheckTask = class(TACLTask)
    strict private
      FDrive: string;
    protected
      procedure Execute; override;
    public
      constructor Create(const ADrive: string);
    end;
  {$ENDREGION}
  strict private
    FWndHandle: TWndHandle;
    procedure WndProc(var Message: TMessage);
  public
    constructor Create;
    destructor Destroy; override;
  end;

{$ENDIF}

{ TACLDriveInfo }

function TACLDriveInfo.FetchDriveType: TACLDriveType;
begin
  Result := dtUnknown;
{$IFDEF MSWINDOWS}
  case GetDriveType(PChar(Path)) of
    DRIVE_FIXED:
      Result := dtFixed;
    DRIVE_REMOVABLE:
      Result := dtRemovable;
    DRIVE_REMOTE, DRIVE_CDROM, DRIVE_RAMDISK:
      Result := dtOther;
  end;
{$ENDIF}
end;

function TACLDriveInfo.FetchTitle: string;
{$IFDEF MSWINDOWS}
var
  LBuff: array[Byte] of WideChar;
  LTemp: Cardinal;
{$ENDIF}
begin
  Result := acEmptyStr;
{$IFDEF MSWINDOWS}
  if GetVolumeInformation(PChar(Path), @LBuff[0], High(LBuff), @FSerial, LTemp, LTemp, nil, 0) then
  begin
    Result := LBuff;
    if Result = '' then
      with TACLIniFile.Create(Path + 'autorun.inf', False) do
      try
        Result := ReadString('Autorun', 'Label');
      finally
        Free;
      end;
  end;
{$ENDIF}
end;

procedure TACLDriveInfo.Flush;
begin
  FSerial := DWORD(-1);
  FTitle := '';
  FType := dtUnknown;
end;

function TACLDriveInfo.GetSerial: Cardinal;
begin
  if FSerial = DWORD(-1) then
    FetchTitle; //
  Result := FSerial;
end;

function TACLDriveInfo.GetTitle(const ADefault: string): string;
begin
  if FTitle = '' then
  begin
    FTitle := FetchTitle;
    if FTitle = '' then
      FTitle := ADefault;
    if FTitle = '' then
      FTitle := 'Drive';
    FTitle := Format('%s (%s)', [FTitle, Path]);
  end;
  Result := FTitle;
end;

function TACLDriveInfo.GetType: TACLDriveType;
begin
  if FType = dtUnknown then
    FType := FetchDriveType;
  Result := FType;
end;

{ TACLDriveMonitor }

{$IFDEF FPC}

constructor TACLDriveMonitor.Create;
begin
  FCurrent := TACLStringList.Create;
  FMonitor := g_unix_mount_monitor_get();
  g_signal_connect(FMonitor, 'mounts-changed', @Notify, Self);
  Changed;
end;

destructor TACLDriveMonitor.Destroy;
begin
  g_object_unref(FMonitor);
  FreeAndNil(FCurrent);
  inherited Destroy;
end;

procedure TACLDriveMonitor.Changed;
var
  LDrive: TACLDriveInfo;
  LPrevState: TACLStringList;
  LItem: PGList;
  LList: PGList;
  I: Integer;
begin
  LList := g_unix_mounts_get(nil);
  if LList <> nil then
  try
    LPrevState := FCurrent.Clone;
    try
      FCurrent.Clear;
      LItem := LList;
      while LItem <> nil do
      begin
        if not g_unix_mount_is_system_internal(LItem.data) then
        begin
          LDrive.Flush;
          LDrive.Path := g_unix_mount_get_mount_path(LItem.data);
          LDrive.Path := TACLDriveManager.CheckDrivePath(LDrive.Path);
          if LPrevState.Remove(LDrive.Path) < 0 then
          begin
            LDrive.FTitle := g_unix_mount_guess_name(LItem.data);
//            LDrive.FExtra :=
//              g_unix_mount_get_fs_type(LItem.data) + ';' +
//              g_unix_mount_get_device_path(LItem.data) + ';' +
//              g_unix_mount_get_options(LItem.data);

            // g_unix_mount_guess_type() is a private function =(
            if g_unix_mount_is_readonly(LItem.data) then
              LDrive.FType := dtOther // CD-ROM?
            else
              LDrive.FType := dtRemovable;

            TACLDriveManager.Changed(LDrive.Path, True, @LDrive);
          end;
          FCurrent.Add(LDrive.Path);
        end;
        LItem := LItem.next;
      end;
      for I := 0 to LPrevState.Count - 1 do
        TACLDriveManager.Changed(LPrevState.Strings[I], False, nil);
    finally
      LPrevState.Free;
    end;
  finally
    g_list_free(LList);
  end;
end;

class procedure TACLDriveMonitor.Notify(Monitor: PGUnixMountMonitor; Data: TACLDriveMonitor);
begin
  Data.Changed;
end;

procedure TACLDriveMonitor.WaitFor;
begin
  // do nothing
end;

{$ELSE}

constructor TACLDriveMonitor.Create;
var
  LDrive: string;
  LDriveInfo: TACLDriveInfo;
begin
  inherited;
  FWndHandle := WndCreate(WndProc, ClassName, False);

  Initialize;
  for LDrive in TDirectory.GetLogicalDrives do
  begin
    LDriveInfo := TACLDriveManager.GetInfo(LDrive);
    if LDriveInfo.GetType = dtFixed then
      TACLDriveManager.Changed(LDriveInfo.Path, True, @LDriveInfo)
    else
      Add(TCheckTask.Create(LDriveInfo.Path));
  end;
  Run(False);
end;

destructor TACLDriveMonitor.Destroy;
begin
  WndFree(FWndHandle);
  inherited;
end;

procedure TACLDriveMonitor.WndProc(var Message: TMessage);
const
  DBT_EVENT_DEVICEARRIVAL = $8000;
  DBT_EVENT_DEVICEREMOVED = $8004;
  DBT_FORMAT_NET   = $0002;
  DBT_TYPE_VOLUME  = $0002;
type
  PDeviceBroadcastVolume = ^TDeviceBroadcastVolume;
  TDeviceBroadcastVolume = packed record
    Size: DWORD;
    DeviceType: DWORD;
    Reserved: DWORD;
    UnitMask: DWORD;
    Flags: Word;
  end;

  function DecodeDrive(AVolume: PDeviceBroadcastVolume): string;
  var
    AIndex: Integer;
    AMask: DWORD;
  begin
    AIndex := 0;
    Result := '';
    AMask := AVolume^.UnitMask;
    while AMask > 0 do
    begin
      if AMask and 1 = 1 then
        Result := TACLDriveManager.CheckDrivePath(WideChar(AIndex + Ord('A')));
      AMask := AMask shr 1;
      Inc(AIndex);
    end;
  end;

var
  AVolume: PDeviceBroadcastVolume;
begin
  if Message.Msg = WM_DEVICECHANGE then
  begin
    case Message.WParam of
      DBT_EVENT_DEVICEARRIVAL, DBT_EVENT_DEVICEREMOVED:
        begin
          AVolume := PDeviceBroadcastVolume(Message.LParam);
          if (AVolume^.DeviceType = DBT_TYPE_VOLUME) and (AVolume^.Flags and DBT_FORMAT_NET = 0) then
            TACLDriveManager.Changed(DecodeDrive(AVolume), Message.WParam = DBT_EVENT_DEVICEARRIVAL);
        end;
    end;
  end;
  WndDefaultProc(FWndHandle, Message);
end;

{ TACLDriveMonitor.TCheckTask }

constructor TACLDriveMonitor.TCheckTask.Create(const ADrive: string);
begin
  inherited Create;
  FDrive := ADrive;
end;

procedure TACLDriveMonitor.TCheckTask.Execute;
var
  LHandle: THandle;
  LReturn: Cardinal;
begin
  LHandle := CreateFile(PChar('\\.\' + FDrive[1] + ':'), 0, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  if LHandle <> INVALID_HANDLE_VALUE then
  try
    LReturn := 0;
    if DeviceIoControl(LHandle, IOCTL_STORAGE_CHECK_VERIFY2, nil, 0, nil, 0, LReturn, nil) then
    begin
      TACLMainThread.RunImmediately(
        procedure
        begin
          TACLDriveManager.Changed(FDrive, True);
        end);
    end;
  finally
    CloseHandle(LHandle);
  end;
end;
{$ENDIF}

{ TACLDriveManager }

class constructor TACLDriveManager.Create;
begin
  FLock := TACLCriticalSection.Create;
  FList := TACLList<TACLDriveInfo>.Create;
  FListeners := TACLList<TCallback>.Create;
  FMonitor := TACLDriveMonitor.Create;
end;

class destructor TACLDriveManager.Destroy;
begin
  FreeAndNil(FMonitor);
  FreeAndNil(FListeners);
  FreeAndNil(FList);
  FreeAndNil(FLock);
end;

class procedure TACLDriveManager.Changed(const ADrive: string;
  AMounted: Boolean; AInfo: PACLDriveInfo = nil);
var
  LIndex: Integer;
  LInfo: TACLDriveInfo;
begin
  FLock.Enter;
  try
    if AInfo <> nil then
      LInfo := AInfo^
    else
      LInfo := GetInfo(ADrive);

    if SafeFind(ADrive, LIndex) then
      FList.Delete(LIndex);
    if AMounted then
    begin
      FList.Add(LInfo);
      FList.Sort(
        function (const Item1, Item2: TACLDriveInfo): Integer
        begin
          Result := acCompareStrings(Item1.Path, Item2.Path);
        end);
    end;

    for LIndex := FListeners.Count - 1 downto 0 do
      FListeners.List[LIndex](LInfo, AMounted);
  finally
    FLock.Leave;
  end;
end;

class function TACLDriveManager.CheckDrivePath(const ADrive: string): string;
{$IFDEF MSWINDOWS}
var
  LLength: Integer;
begin
  LLength := Length(ADrive);
  if LLength = 1 then
    Result := ADrive + ':\'
  else if LLength = 2 then
    Result := ADrive + '\'
  else if LLength > 3 then
    Result := Copy(ADrive, 1, 3)
  else
    Result := ADrive;
{$ELSE}
begin
  Result := acIncludeTrailingPathDelimiter(ADrive);
{$ENDIF}
end;

class procedure TACLDriveManager.EnsureReady;
begin
  TACLDriveMonitor(FMonitor).WaitFor;
end;

class procedure TACLDriveManager.Enum(AProc: TEnumProc);
var
  I: Integer;
begin
  FLock.Enter;
  try
    for I := 0 to FList.Count - 1 do
      AProc(FList.List[I]);
  finally
    FLock.Leave;
  end;
end;

class function TACLDriveManager.GetInfo(const ADrive: string): TACLDriveInfo;
var
  LIndex: Integer;
begin
  FLock.Enter;
  try
    Result.Flush;
    Result.Path := CheckDrivePath(ADrive);
    if SafeFind(Result.Path, LIndex) then
      Result := FList.List[LIndex];
  finally
    FLock.Leave;
  end;
end;

class procedure TACLDriveManager.ListenerAdd(AListener: TCallback);
begin
  FLock.Enter;
  try
    FListeners.Add(AListener);
  finally
    FLock.Leave;
  end;
end;

class procedure TACLDriveManager.ListenerRemove(AListener: TCallback);
begin
  FLock.Enter;
  try
    FListeners.Remove(AListener);
  finally
    FLock.Leave;
  end;
end;

class function TACLDriveManager.SafeFind(
  const ADrive: string; out AIndex: Integer): Boolean;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
  begin
    if acSameText(FList.List[I].Path, ADrive) then
    begin
      AIndex := I;
      Exit(True);
    end;
  end;
  Result := False;
end;

{$ENDREGION}
end.
