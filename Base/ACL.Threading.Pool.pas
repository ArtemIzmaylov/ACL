////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Thread Pool
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Threading.Pool;

{$I ACL.Config.inc}

interface

uses
{$IFDEF MSWINDOWS}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Generics.Defaults,
  {System.}Math,
  {System.}SyncObjs,
  {System.}SysUtils,
  {System.}Types,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Timers,
  ACL.Threading,
  ACL.Utils.Common,
  ACL.Utils.Logger,
  ACL.Utils.Strings;

type
  TACLTaskCancelCallback = function: Boolean of object;
  TACLTaskProc = reference to procedure (CheckCanceled: TACLTaskCancelCallback);

  TACLTaskDispatcher = class;

  { IACLTaskEvent }

  IACLTaskEvent = interface
  ['{3CAF68AD-4959-429F-A6BB-19DC671BD3BB}']
    function Signal: Boolean;
    function WaitFor(ATimeOut: Cardinal; AThreadId: TThreadId): TWaitResult;
  end;

  { TACLTask }

  TACLTaskPriority = (atpLow, atpNormal, atpHigh);

  TACLTask = class(TACLUnknownObject)
  private
    FCanceled: Integer;
    FEvent: IACLTaskEvent;
    FKeepOnTerminate: Boolean;
    FOwner: TACLTaskDispatcher;
    FOwnerTask: TACLTask;
    FThreadId: TThreadId;

    FOnComplete: TThreadMethod;
    FOnCompleteMode: TACLThreadMethodCallMode;

    procedure FreeIfNecessary;
    function GetHandle: TObjHandle;
    function GetFreeOnTerminate: Boolean;
    procedure SetFreeOnTerminate(AValue: Boolean);
  protected
    procedure Complete; virtual;
    procedure Execute; virtual; abstract;
    function GetCaption: string; virtual;
    function GetPriority: TACLTaskPriority; virtual;
  public
    procedure Cancel;
    function IsCanceled: Boolean;
    procedure RunInCurrentThread;
    //# Properties
    property Caption: string read GetCaption;
    property Handle: TObjHandle read GetHandle;
    property FreeOnTerminate: Boolean read GetFreeOnTerminate write SetFreeOnTerminate;
    //# Events
    property OnComplete: TThreadMethod read FOnComplete write FOnComplete;
    property OnCompleteMode: TACLThreadMethodCallMode read FOnCompleteMode write FOnCompleteMode;
  end;

  { TACLTaskList }

  TACLTaskList = class(TACLList)
  protected
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  end;

  { TACLTaskGroup }

  TACLTaskGroup = class
  strict private
    FActiveTasks: Integer;
    FCanceled: Boolean;
    FEvent: TACLEvent;
    FPendingTasks: TACLTaskList;
    FTasks: TACLListOf<TObjHandle>;

    FOnAsyncFinished: TNotifyEvent;

    procedure AsyncFinished;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(ATask: TACLTask);
    procedure Cancel(AWaitFor: Boolean = True);
    procedure Initialize;
    function IsActive: Boolean;
    function IsCanceled: Boolean;
    procedure Run(AWaitFor: Boolean);
    procedure WaitFor;
    //# Properties
    property OnAsyncFinished: TNotifyEvent read FOnAsyncFinished write FOnAsyncFinished;
  end;

  { TACLTaskQueue }

  TACLTaskQueue = class(TACLTask)
  strict private
    FAutoStart: Boolean;
    FCurrentTask: TACLTask;
    FLock: TACLCriticalSection;
    FPendingTasks: TACLTaskList;
  protected
    procedure Execute; override;
  public
    constructor Create(AAutoStart: Boolean = True);
    destructor Destroy; override;
    procedure Add(ATask: TACLTask);
    function IsActive: Boolean;
  end;

  { TACLTaskDispatcher }

  TACLTaskDispatcher = class
  strict private const
    CpuMaxThreads = 8;
    CpuUsageTooHigh = 95; //# Reduce number of active tasks if CPU usage gets this high
    CpuUsageLow = 80; //# Increase number of active tasks if CPU usage is below this
    CpuUsageMonitorLogSize = 10;
    CpuUsageMonitorUpdateInterval = 1000;
    SuccessfulWaitResults = [wrSignaled, wrAbandoned];
  strict private
    FActiveTasks: TList;
    FActualMaxActiveTasks: Integer;
    FCpuUsageLog: array [0..CpuUsageMonitorLogSize - 1] of Integer;
    FCpuUsageMonitor: TObject;
    FCpuUsageMonitorCounter: Integer;
    FLock: TACLCriticalSection;
    FMaxActiveTasks: Integer;
    FPrevSystemTimes: TThread.TSystemTimes;
    FTasks: TACLTaskList;

    procedure AsyncRun(ATask: TACLTask);
    procedure CheckActiveTasks;
    procedure HandlerCpuUsageMonitor(Sender: TObject);
    function GetUseCpuUsageMonitor: Boolean;
    procedure SetMaxActiveTasks(AValue: Integer);
    procedure SetUseCpuUsageMonitor(AValue: Boolean);
  protected
    function Contains(ATask: TACLTask): Boolean;
    procedure Start(ATask: TACLTask);
    class function TaskCompare(ALeft, ARight: TACLTask): Integer; static;
    class function ThreadProc(ATask: TACLTask): Integer; stdcall; static;

    // Properties
    property ActualMaxActiveTasks: Integer read FActualMaxActiveTasks;
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    class function CurrentTask: TACLTask;

    function Run(AProc: TACLTaskProc): TObjHandle; overload;
    function Run(AProc: TThreadMethod; ACompleteEvent: TThreadMethod;
      ACompleteEventCallMode: TACLThreadMethodCallMode): TObjHandle; overload;
    function Run(AProc: TACLTaskProc; ACompleteEvent: TThreadMethod;
      ACompleteEventCallMode: TACLThreadMethodCallMode): TObjHandle; overload;
    function Run(ATask: TACLTask): TObjHandle; overload;
    function Run(ATask: TACLTask; ACompleteEvent: TThreadMethod;
      ACompleteEventCallMode: TACLThreadMethodCallMode): TObjHandle; overload;

    function Cancel(ATaskHandle: TObjHandle; AWaitFor: Boolean = False): Boolean; overload;
    function Cancel(ATaskHandle: TObjHandle; AWaitTimeOut: Cardinal): TWaitResult; overload;
    procedure CancelAll(AWaitFor: Boolean);
    function ToString: string; override;

    function WaitFor(ATaskHandle: TObjHandle): Boolean; overload;
    function WaitFor(ATaskHandle: TObjHandle; AWaitTimeOut: Cardinal): TWaitResult; overload;

    // Properties
    property MaxActiveTasks: Integer read FMaxActiveTasks write SetMaxActiveTasks;
    property UseCpuUsageMonitor: Boolean read GetUseCpuUsageMonitor write SetUseCpuUsageMonitor;
  end;

function TaskDispatcher: TACLTaskDispatcher;
implementation

type

  { TACLTaskEvent }

  TACLTaskEvent = class(TInterfacedObject, IACLTaskEvent)
  strict private
  {$IFDEF FPC}
    FEvent: TACLEvent;
  {$ELSE}
    FHandle: TObjHandle;
  {$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    function Signal: Boolean;
    function WaitFor(ATimeOut: Cardinal; AThreadId: TThreadId): TWaitResult;
  end;

  { TACLSimpleTask }

  TACLSimpleTask = class(TACLTask)
  strict private
    FProc: TACLTaskProc;
    FProc2: TThreadMethod;
  protected
    procedure Execute; override;
  public
    constructor Create(AProc: TACLTaskProc); overload;
    constructor Create(AProc: TThreadMethod); overload;
  end;

threadvar
  FCurrentThreadTask: TACLTask;
var
  FTaskDispatcher: TACLTaskDispatcher = nil;

function TaskDispatcher: TACLTaskDispatcher;
begin
  if FTaskDispatcher = nil then
    FTaskDispatcher := TACLTaskDispatcher.Create;
  Result := FTaskDispatcher;
end;

{ TACLTask }

procedure TACLTask.Cancel;
begin
  InterlockedExchange(FCanceled, 1);
end;

procedure TACLTask.Complete;
begin
  CallThreadMethod(FOnComplete, FOnCompleteMode);
end;

procedure TACLTask.FreeIfNecessary;
begin
  if FreeOnTerminate then Free;
end;

function TACLTask.GetPriority: TACLTaskPriority;
begin
  Result := atpNormal;
end;

function TACLTask.GetCaption: string;
begin
  Result := '';
end;

function TACLTask.GetFreeOnTerminate: Boolean;
begin
  Result := not FKeepOnTerminate;
end;

function TACLTask.GetHandle: TObjHandle;
begin
  Result := TObjHandle(Self);
end;

function TACLTask.IsCanceled: Boolean;
begin
  Result := (FCanceled <> 0) or (FOwnerTask <> nil) and FOwnerTask.IsCanceled;
end;

procedure TACLTask.RunInCurrentThread;
begin
  try
    FOwnerTask := TACLTaskDispatcher.CurrentTask;
    try
      Execute;
    finally
      Complete;
    end;
  finally
    FreeIfNecessary;
  end;
end;

procedure TACLTask.SetFreeOnTerminate(AValue: Boolean);
begin
  // Previously the class did not have a constructor and therefore many
  // inheritors do not call inherited. So we cannot initialize the FreeOnTerminate
  // variable in the constructor by the TRUE value to keep original behavior.
  FKeepOnTerminate := not AValue;
end;

{ TACLTaskList }

procedure TACLTaskList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if (Action = lnDeleted) and (Ptr <> nil) then
    TACLTask(Ptr).FreeIfNecessary;
  inherited;
end;

{ TACLTaskGroup }

constructor TACLTaskGroup.Create;
begin
  FEvent := TACLEvent.Create(True, True);
  FTasks := TACLListOf<TObjHandle>.Create;
  FPendingTasks := TACLTaskList.Create;
end;

destructor TACLTaskGroup.Destroy;
begin
  Cancel;
  FreeAndNil(FPendingTasks);
  FreeAndNil(FTasks);
  FreeAndNil(FEvent);
  inherited;
end;

procedure TACLTaskGroup.Add(ATask: TACLTask);
begin
  FPendingTasks.Add(ATask);
end;

procedure TACLTaskGroup.AsyncFinished;
begin
  if InterlockedDecrement(FActiveTasks) = 0 then
  try
    if Assigned(OnAsyncFinished) then
      OnAsyncFinished(Self);
  finally
    FEvent.Signal;
  end;
end;

procedure TACLTaskGroup.Cancel(AWaitFor: Boolean = True);
var
  I: Integer;
begin
  FCanceled := True;
  for I := FTasks.Count - 1 downto 0 do
    TaskDispatcher.Cancel(FTasks.List[I], False);
  if AWaitFor then
    FEvent.WaitFor;
end;

procedure TACLTaskGroup.Initialize;
begin
  Cancel;
  FEvent.Reset;
  FTasks.Clear;
  FPendingTasks.Clear;
  FCanceled := False;
  FActiveTasks := 0;
end;

function TACLTaskGroup.IsActive: Boolean;
begin
  Result := FActiveTasks > 0;
end;

function TACLTaskGroup.IsCanceled: Boolean;
begin
  Result := FCanceled;
end;

procedure TACLTaskGroup.Run(AWaitFor: Boolean);
begin
  FActiveTasks := 1; // to prevent from OnAsyncFinished fired before push all tasks to a dispatcher
  while FPendingTasks.Count > 0 do
  begin
    InterlockedIncrement(FActiveTasks);
    FTasks.Add(TaskDispatcher.Run(TACLTask(FPendingTasks.ExtractAt(0)), AsyncFinished, tmcmAsync));
  end;
  AsyncFinished;
  if AWaitFor then WaitFor;
end;

procedure TACLTaskGroup.WaitFor;
begin
  FEvent.WaitFor;
end;

{ TACLTaskQueue }

constructor TACLTaskQueue.Create(AAutoStart: Boolean);
begin
  inherited Create;
  FAutoStart := AAutoStart;
  FLock := TACLCriticalSection.Create;
  FPendingTasks := TACLTaskList.Create;
  FreeOnTerminate := not FAutoStart; // to keep original behavior
end;

destructor TACLTaskQueue.Destroy;
begin
  Cancel;
  FreeAndNil(FPendingTasks);
  FreeAndNil(FLock);
  inherited;
end;

procedure TACLTaskQueue.Add(ATask: TACLTask);
begin
  FLock.Enter;
  try
    FPendingTasks.Add(ATask);
    if FAutoStart and not IsActive then
      TaskDispatcher.Run(Self);
  finally
    FLock.Leave;
  end;
end;

procedure TACLTaskQueue.Execute;
begin
  while not IsCanceled do
  begin
    FLock.Enter;
    try
      FCurrentTask := FPendingTasks.ExtractAt(0);
    finally
      FLock.Leave;
    end;

    if FCurrentTask <> nil then
      FCurrentTask.RunInCurrentThread
    else
      Break;
  end;
end;

function TACLTaskQueue.IsActive: Boolean;
begin
  Result := TaskDispatcher.Contains(Self);
end;

{ TACLSimpleTask }

constructor TACLSimpleTask.Create(AProc: TACLTaskProc);
begin
  inherited Create;
  FProc := AProc;
end;

constructor TACLSimpleTask.Create(AProc: TThreadMethod);
begin
  inherited Create;
  FProc2 := AProc;
end;

procedure TACLSimpleTask.Execute;
begin
  if Assigned(FProc) then
    FProc(IsCanceled);
  if Assigned(FProc2) then
    FProc2();
end;

{ TACLTaskEvent }

constructor TACLTaskEvent.Create;
begin
{$IFDEF FPC}
  FEvent := TACLEvent.Create(True, False);
{$ELSE}
  FHandle := CreateEvent(nil, True, False, nil);
{$ENDIF}
end;

destructor TACLTaskEvent.Destroy;
begin
{$IFDEF FPC}
  FreeAndNil(FEvent);
{$ELSE}
  CloseHandle(FHandle);
{$ENDIF}
  inherited Destroy;
end;

function TACLTaskEvent.Signal: Boolean;
begin
{$IFDEF FPC}
  FEvent.Signal;
  Result := True;
{$ELSE}
  Result := SetEvent(FHandle);
{$ENDIF}
end;

function TACLTaskEvent.WaitFor(ATimeOut: Cardinal; AThreadId: TThreadId): TWaitResult;
begin
  if (ATimeOut = INFINITE) and (AThreadId <> 0) then
    TACLMainThread.CheckForDeadlock(AThreadId);
{$IFDEF FPC}
  if FEvent.WaitFor(ATimeOut) then
    Result := wrSignaled
  else if ATimeOut <> INFINITE then
    Result := wrTimeout
  else
    Result := wrError;
{$ELSE}
  Result := WaitForSyncObject(FHandle, ATimeOut);
{$ENDIF}
end;

{ TACLTaskDispatcher }

constructor TACLTaskDispatcher.Create;
begin
  inherited Create;
  IsMultiThread := True;
  FTasks := TACLTaskList.Create;
  FActiveTasks := TList.Create;
  FLock := TACLCriticalSection.Create(Self, 'TaskLock');
  MaxActiveTasks := 4 * CPUCount;
  UseCpuUsageMonitor := True;
end;

destructor TACLTaskDispatcher.Destroy;
begin
  FreeAndNil(FCpuUsageMonitor);
  FreeAndNil(FActiveTasks);
  FreeAndNil(FTasks);
  FreeAndNil(FLock);
  inherited Destroy;
end;

function TACLTaskDispatcher.Run(AProc: TACLTaskProc): TObjHandle;
begin
  Result := Run(TACLSimpleTask.Create(AProc));
end;

function TACLTaskDispatcher.Run(AProc: TACLTaskProc;
  ACompleteEvent: TThreadMethod; ACompleteEventCallMode: TACLThreadMethodCallMode): TObjHandle;
begin
  Result := Run(TACLSimpleTask.Create(AProc), ACompleteEvent, ACompleteEventCallMode);
end;

function TACLTaskDispatcher.Run(ATask: TACLTask): TObjHandle;
begin
  FLock.Enter;
  try
    Result := ATask.Handle;
    if not Contains(ATask) then
    begin
      ATask.FCanceled := 0;
      FTasks.Add(ATask);
      FTasks.Sort(@TaskCompare);
    end;
  finally
    FLock.Leave;
  end;
  CheckActiveTasks;
end;

function TACLTaskDispatcher.Run(ATask: TACLTask;
  ACompleteEvent: TThreadMethod;
  ACompleteEventCallMode: TACLThreadMethodCallMode): TObjHandle;
begin
  ATask.OnComplete := ACompleteEvent;
  ATask.OnCompleteMode := ACompleteEventCallMode;
  Result := Run(ATask);
end;

function TACLTaskDispatcher.Run(AProc, ACompleteEvent: TThreadMethod;
  ACompleteEventCallMode: TACLThreadMethodCallMode): TObjHandle;
begin
  Result := Run(TACLSimpleTask.Create(AProc), ACompleteEvent, ACompleteEventCallMode);
end;

procedure TACLTaskDispatcher.BeforeDestruction;
begin
  inherited BeforeDestruction;
  FreeAndNil(FCpuUsageMonitor);
  FActualMaxActiveTasks := 0;
  FMaxActiveTasks := 0;
  CancelAll(True);
end;

function TACLTaskDispatcher.Cancel(ATaskHandle: TObjHandle; AWaitFor: Boolean = False): Boolean;
begin
  Result := Cancel(ATaskHandle, IfThen(AWaitFor, INFINITE)) <> wrError;
end;

function TACLTaskDispatcher.Cancel(ATaskHandle: TObjHandle; AWaitTimeOut: Cardinal): TWaitResult;
var
  LTask: TACLTask absolute ATaskHandle;
  LWaitEvent: IACLTaskEvent;
  LWaitThreadId: TThreadId;
begin
  if ATaskHandle = 0 then
    Exit(wrSignaled);

  LWaitThreadId := 0;
  LWaitEvent := nil;
  FLock.Enter;
  try
    // Cancel pending item
    if FTasks.Extract(LTask) <> nil then
    begin
      try
        LTask.Cancel;
        LTask.Complete;
      finally
        LTask.FreeIfNecessary
      end;
      Exit(wrSignaled);
    end;

    // Cancel active item
    if FActiveTasks.Contains(LTask) then
    begin
      LTask.Cancel;
      LWaitEvent := LTask.FEvent;
      LWaitThreadId := LTask.FThreadId;
    end;
  finally
    FLock.Leave;
  end;

  if LWaitEvent <> nil then
    Result := LWaitEvent.WaitFor(AWaitTimeOut, LWaitThreadId)
  else
    Result := wrAbandoned;

  if IsMainThread then
    TACLMainThread.CheckSynchronize;
end;

class function TACLTaskDispatcher.CurrentTask: TACLTask;
//var
//  LIndex: Integer;
//  LThreadId: TThreadId;
begin
  Result := FCurrentThreadTask;
//  FLock.Enter;
//  try
//    LThreadId := GetCurrentThreadId;
//    for LIndex := 0 to FActiveTasks.Count - 1 do
//    begin
//      Result := FActiveTasks.List[LIndex];
//      if Result.FThreadID = LThreadId then
//        Exit;
//    end;
//    Result := nil;
//  finally
//    FLock.Leave;
//  end;
end;

function TACLTaskDispatcher.WaitFor(ATaskHandle: TObjHandle): Boolean;
begin
  Result := WaitFor(ATaskHandle, INFINITE) in SuccessfulWaitResults;
end;

function TACLTaskDispatcher.WaitFor(ATaskHandle: TObjHandle; AWaitTimeOut: Cardinal): TWaitResult;
var
  LTask: TACLTask absolute ATaskHandle;
  LWaitEvent: IACLTaskEvent;
  LWaitThreadId: TThreadId;
begin
  LWaitEvent := nil;
  LWaitThreadId := 0;

  FLock.Enter;
  try
    // if task is pending - activate it now
    if FTasks.Contains(LTask) then
      Start(LTask);

    // find task in active work item list
    if FActiveTasks.Contains(LTask) then
    begin
      LWaitEvent := LTask.FEvent;
      LWaitThreadId := LTask.FThreadId;
    end;
  finally
    FLock.Leave;
  end;

  if LWaitEvent <> nil then
    Result := LWaitEvent.WaitFor(AWaitTimeOut, LWaitThreadId)
  else
    Result := wrAbandoned;
end;

class function TACLTaskDispatcher.TaskCompare(ALeft, ARight: TACLTask): Integer;
begin
  Result := Ord(ARight.GetPriority) - Ord(ALeft.GetPriority);
end;

class function TACLTaskDispatcher.ThreadProc(ATask: TACLTask): Integer;
begin
{$IFDEF ACL_THREADING_DEBUG}
  TACLThread.NameThreadForDebugging('ThreadPool - ' + ATask.ClassName);
{$ENDIF}
  try
    ATask.FOwner.AsyncRun(ATask);
  except
    // Мы в потоке, падать никак нельзя
    on E: Exception do
      LogError(acGeneralLogFileName, 'ThreadPool', E);
  end;
{$IFDEF ACL_THREADING_DEBUG}
  TACLThread.NameThreadForDebugging('ThreadPool - Idle');
{$ENDIF}
  Result := 0;
end;

function TACLTaskDispatcher.ToString: string;
var
  ABuffer: TACLStringBuilder;
begin
  ABuffer := TACLStringBuilder.Get(64);
  try
    ABuffer.Append('Active: ').Append(FActiveTasks.Count);
    if FTasks.Count > 0 then
      ABuffer.Append(' (Pending: ').Append(FTasks.Count).Append(')');
//    if UseCpuUsageMonitor then
//    begin
//      ABuffer.AppendLine.Append('Quota: ').Append(ActualMaxActiveTasks);
//      ABuffer.AppendLine.Append('CPU Usage: ').Append(FAverageCpuUsage).Append('%');
//    end;
    Result := ABuffer.ToString;
  finally
    ABuffer.Release;
  end;
end;

procedure TACLTaskDispatcher.Start(ATask: TACLTask);
begin
  FLock.Enter;
  try
    ATask.FOwner := Self;
    ATask.FOwnerTask := nil;
    ATask.FEvent := TACLTaskEvent.Create;
    FActiveTasks.Add(FTasks.Extract(ATask));
    RunInThread(@ThreadProc, ATask);
  finally
    FLock.Leave;
  end;
end;

procedure TACLTaskDispatcher.AsyncRun(ATask: TACLTask);
{$IFDEF MSWINDOWS}
const
  PriorityMap: array[TACLTaskPriority] of Integer = (
    THREAD_PRIORITY_IDLE, THREAD_PRIORITY_NORMAL, THREAD_PRIORITY_HIGHEST);
{$ENDIF}
begin
  try
    ATask.FThreadID := GetCurrentThreadId;
  {$IFDEF MSWINDOWS}
    SetThreadPriority(GetCurrentThread, PriorityMap[ATask.GetPriority]);
  {$ENDIF}
    FCurrentThreadTask := ATask;
    try
      try
        ATask.Execute;
      finally
        ATask.Complete;
      end;
    except
      on E: Exception do
        LogError(acGeneralLogFileName, 'ThreadPool', E);
    end;

    FLock.Enter;
    try
      FCurrentThreadTask := nil;
      FActiveTasks.Remove(ATask);
      CheckActiveTasks;
    finally
      FLock.Leave;
    end;

    ATask.FEvent.Signal;
  finally
    ATask.FreeIfNecessary;
  end;
end;

procedure TACLTaskDispatcher.CancelAll(AWaitFor: Boolean);
var
  LTaskHandle: TObjHandle;
  I: Integer;
begin
  // Mark all as canceled
  FLock.Enter;
  try
    for I := FTasks.Count - 1 downto 0 do
      Cancel(TACLTask(FTasks.List[I]).Handle, False);
    for I := FActiveTasks.Count - 1 downto 0 do
      Cancel(TACLTask(FActiveTasks.List[I]).Handle, False);
  finally
    FLock.Leave;
  end;

  // Wait while all tasks will be finished
  if AWaitFor then
    while FActiveTasks.Count > 0 do
    begin
      FLock.Enter;
      try
        if FActiveTasks.Count > 0 then
          LTaskHandle := TACLTask(FActiveTasks.First).Handle
        else
          LTaskHandle := 0;
      finally
        FLock.Leave;
      end;
      Cancel(LTaskHandle, True);
    end;
end;

procedure TACLTaskDispatcher.CheckActiveTasks;
begin
  FLock.Enter;
  try
    if FActiveTasks.Count < ActualMaxActiveTasks then
    begin
      if FTasks.Count > 0 then
        Start(FTasks.First);
    end;
  finally
    FLock.Leave;
  end;
end;

function TACLTaskDispatcher.Contains(ATask: TACLTask): Boolean;
begin
  FLock.Enter;
  try
    Result := FTasks.Contains(ATask) or FActiveTasks.Contains(ATask);
  finally
    FLock.Leave;
  end;
end;

procedure TACLTaskDispatcher.HandlerCpuUsageMonitor(Sender: TObject);
var
  AAverageCpuUsage: Int64;
  ANumberOfActiveTasks: Integer;
  ANumberOfPendingTasks: Integer;
  I: Integer;
begin
  for I := Low(FCpuUsageLog) to High(FCpuUsageLog) - 1 do
    FCpuUsageLog[I + 1] := FCpuUsageLog[I];
  FCpuUsageLog[0] := TThread.GetCPUUsage(FPrevSystemTimes);
  FCpuUsageMonitorCounter := Min(FCpuUsageMonitorCounter + 1, CpuUsageMonitorLogSize);

  if FCpuUsageMonitorCounter >= CpuUsageMonitorLogSize then
  begin
    AAverageCpuUsage := 0;
    for I := Low(FCpuUsageLog) to High(FCpuUsageLog) do
      Inc(AAverageCpuUsage, FCpuUsageLog[I]);
    AAverageCpuUsage := AAverageCpuUsage div Length(FCpuUsageLog);

    ANumberOfActiveTasks := FActiveTasks.Count;
    ANumberOfPendingTasks := FTasks.Count;
    if ANumberOfPendingTasks = 0 then
      ANumberOfActiveTasks := MaxActiveTasks
    else if AAverageCpuUsage >= CpuUsageTooHigh then
      Dec(ANumberOfActiveTasks)
    else if AAverageCpuUsage <= CpuUsageLow then
      Inc(ANumberOfActiveTasks);

    ANumberOfActiveTasks := EnsureRange(ANumberOfActiveTasks, MaxActiveTasks, CpuCount * CpuMaxThreads);
    if ANumberOfActiveTasks <> FActualMaxActiveTasks then
    begin
      FActualMaxActiveTasks := ANumberOfActiveTasks;
      FCpuUsageMonitorCounter := 0;
      CheckActiveTasks;
    end;
  end;
end;

function TACLTaskDispatcher.GetUseCpuUsageMonitor: Boolean;
begin
  Result := FCpuUsageMonitor <> nil;
end;

procedure TACLTaskDispatcher.SetMaxActiveTasks(AValue: Integer);
begin
  FMaxActiveTasks := Max(AValue, 1);
  FActualMaxActiveTasks := MaxActiveTasks;
  CheckActiveTasks;
end;

procedure TACLTaskDispatcher.SetUseCpuUsageMonitor(AValue: Boolean);
begin
  if not IsMainThread then
    raise EInvalidOperation.Create('SetUseCpuUsageMonitor must be called from MainThread');
  if UseCpuUsageMonitor <> AValue then
  begin
    if AValue then
    begin
      TACLTimer(FCpuUsageMonitor) := TACLTimer.CreateEx(HandlerCpuUsageMonitor, CpuUsageMonitorUpdateInterval);
      TACLTimer(FCpuUsageMonitor).Enabled := True;
    end
    else
      FreeAndNil(FCpuUsageMonitor);
  end;
end;

initialization

finalization
  FreeAndNil(FTaskDispatcher);
end.
