{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*           Thread Pool Routines            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Threading.Pool;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SyncObjs,
  System.SysUtils,
  System.Types,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.Timer,
  ACL.Threading,
  ACL.Utils.Strings;

type
  TACLTaskCancelCallback = function: Boolean of object;
  TACLTaskProc = reference to procedure (CheckCanceled: TACLTaskCancelCallback);

  TACLTaskDispatcher = class;

  { IACLTaskEvent }

  IACLTaskEvent = interface
  ['{3CAF68AD-4959-429F-A6BB-19DC671BD3BB}']
    function Signal: Boolean;
    function WaitFor(ATimeOut: Cardinal): TWaitResult;
  end;

  { TACLTask }

  TACLTaskPriority = (atpLow, atpNormal, atpHigh);

  TACLTask = class(TACLUnknownObject)
  private
    FCanceled: Integer;
    FEvent: IACLTaskEvent;
    FOwner: TACLTaskDispatcher;
    FThreadID: Cardinal;

    FOnComplete: TThreadMethod;
    FOnCompleteMode: TACLThreadMethodCallMode;

    function GetHandle: THandle;
  protected
    procedure Complete; virtual;
    procedure Execute; virtual; abstract;
    function GetCaption: string; virtual;
    function GetPriority: TACLTaskPriority; virtual;
  public
    procedure Cancel;
    function IsCanceled: Boolean; virtual;
    //# Properties
    property Caption: string read GetCaption;
    property Handle: THandle read GetHandle;
  end;

  { TACLTaskGroup }

  TACLTaskGroup = class
  strict private
    FActiveTasks: Integer;
    FEvent: TACLEvent;
    FTasks: TACLList<THandle>;

    FOnAsyncFinished: TNotifyEvent;

    procedure AsyncFinished;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(ATask: TACLTask);
    procedure Cancel;
    procedure Initialize;
    function IsActive: Boolean;
    procedure Run(AWaitFor: Boolean);
    procedure WaitFor;
    //# Properties
    property OnAsyncFinished: TNotifyEvent read FOnAsyncFinished write FOnAsyncFinished;
  end;

  { TACLTaskQueue }

  TACLTaskQueue = class
  strict private
    FCurrentTask: TACLTask;
    FLock: TACLCriticalSection;
    FPendingTasks: TACLObjectList;
    FTaskHandle: THandle;

    FOnAsyncFinished: TNotifyEvent;

    procedure AsyncFinished;
    procedure AsyncRun;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(ATask: TACLTask);
    procedure BeforeDestruction; override;
    procedure Cancel;
    function IsActive: Boolean;
    //# Properties
    property OnAsyncFinished: TNotifyEvent read FOnAsyncFinished write FOnAsyncFinished;
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
    FActiveTasks: TACLList<TACLTask>;
    FActualMaxActiveTasks: Integer;
    FCpuUsageLog: array [0..CpuUsageMonitorLogSize - 1] of Integer;
    FCpuUsageMonitor: TObject;
    FCpuUsageMonitorCounter: Integer;
    FLock: TACLCriticalSection;
    FMaxActiveTasks: Integer;
    FPrevSystemTimes: TThread.TSystemTimes;
    FTasks: TACLObjectList<TACLTask>;

    procedure AsyncRun(ATask: TACLTask);
    procedure CheckActiveTasks;
    procedure HandlerCpuUsageMonitor(Sender: TObject);
    function GetUseCpuUsageMonitor: Boolean;
    procedure SetMaxActiveTasks(AValue: Integer);
    procedure SetUseCpuUsageMonitor(AValue: Boolean);
  protected
    class function ThreadProc(ATask: TACLTask): Integer; stdcall; static;
    procedure Start(ATask: TACLTask);
    //
    property ActualMaxActiveTasks: Integer read FActualMaxActiveTasks;
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeforeDestruction; override;

    function Run(AProc: TACLTaskProc): THandle; overload;
    function Run(AProc: TThreadMethod; ACompleteEvent: TThreadMethod;
      ACompleteEventCallMode: TACLThreadMethodCallMode): THandle; overload;
    function Run(AProc: TACLTaskProc; ACompleteEvent: TThreadMethod;
      ACompleteEventCallMode: TACLThreadMethodCallMode): THandle; overload;
    function Run(ATask: TACLTask): THandle; overload;
    function Run(ATask: TACLTask; ACompleteEvent: TThreadMethod;
      ACompleteEventCallMode: TACLThreadMethodCallMode): THandle; overload;
    function RunInCurrentThread(ATask: TACLTask): THandle;

    function Cancel(ATaskHandle: THandle; AWaitFor: Boolean = False): Boolean; overload;
    function Cancel(ATaskHandle: THandle; AWaitTimeOut: Cardinal): TWaitResult; overload;
    procedure CancelAll(AWaitFor: Boolean);
    function CurrentTask: TACLTask;
    function ToString: string; override;

    function WaitFor(ATaskHandle: THandle): Boolean; overload;
    function WaitFor(ATaskHandle: THandle; AWaitTimeOut: Cardinal): TWaitResult; overload;

    property MaxActiveTasks: Integer read FMaxActiveTasks write SetMaxActiveTasks;
    property UseCpuUsageMonitor: Boolean read GetUseCpuUsageMonitor write SetUseCpuUsageMonitor;
  end;

function TaskDispatcher: TACLTaskDispatcher;
implementation

uses
  System.Math;

type

  { TACLTaskComparer }

  TACLTaskComparer = class(TComparer<TACLTask>)
  protected
    function Compare(const Left, Right: TACLTask): Integer; override;
  end;

  { TACLTaskEvent }

  TACLTaskEvent = class(TInterfacedObject, IACLTaskEvent)
  strict private
    FHandle: THandle;
  public
    constructor Create;
    destructor Destroy; override;
    function Signal: Boolean;
    function WaitFor(ATimeOut: Cardinal): TWaitResult;
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

function TACLTask.GetPriority: TACLTaskPriority;
begin
  Result := atpNormal;
end;

function TACLTask.GetCaption: string;
begin
  Result := '';
end;

function TACLTask.GetHandle: THandle;
begin
  Result := THandle(Self);
end;

function TACLTask.IsCanceled: Boolean;
begin
  Result := FCanceled <> 0;
end;

{ TACLTaskGroup }

constructor TACLTaskGroup.Create;
begin
  FEvent := TACLEvent.Create(True, True);
  FTasks := TACLList<THandle>.Create;
end;

destructor TACLTaskGroup.Destroy;
begin
  Cancel;
  FreeAndNil(FTasks);
  FreeAndNil(FEvent);
  inherited;
end;

procedure TACLTaskGroup.Add(ATask: TACLTask);
begin
  InterlockedIncrement(FActiveTasks); // first
  FTasks.Add(TaskDispatcher.Run(ATask, AsyncFinished, tmcmAsync));
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

procedure TACLTaskGroup.Cancel;
begin
  for var I := FTasks.Count - 1 downto 0 do
    TaskDispatcher.Cancel(FTasks.List[I], False);
  FEvent.WaitFor;
end;

procedure TACLTaskGroup.Initialize;
begin
  Cancel;
  FEvent.Reset;
  FTasks.Clear;
  FActiveTasks := 1; // to prevent from OnAsyncFinished fired before call the Run
end;

function TACLTaskGroup.IsActive: Boolean;
begin
  Result := FActiveTasks > 0;
end;

procedure TACLTaskGroup.Run(AWaitFor: Boolean);
begin
  AsyncFinished;
  if AWaitFor then WaitFor;
end;

procedure TACLTaskGroup.WaitFor;
begin
  FEvent.WaitFor;
end;

{ TACLTaskQueue }

constructor TACLTaskQueue.Create;
begin
  FLock := TACLCriticalSection.Create;
  FPendingTasks := TACLObjectList.Create;
end;

destructor TACLTaskQueue.Destroy;
begin
  FreeAndNil(FPendingTasks);
  FreeAndNil(FLock);
  inherited;
end;

procedure TACLTaskQueue.Add(ATask: TACLTask);
begin
  FLock.Enter;
  try
    FPendingTasks.Add(ATask);
    if FTaskHandle = 0 then
      FTaskHandle := TaskDispatcher.Run(AsyncRun, AsyncFinished, tmcmAsync);
  finally
    FLock.Leave;
  end;
end;

procedure TACLTaskQueue.BeforeDestruction;
begin
  inherited;
  Cancel;
end;

procedure TACLTaskQueue.Cancel;
begin
  FLock.Enter;
  try
    FPendingTasks.Clear;
    if FCurrentTask <> nil then
      FCurrentTask.Cancel;
  finally
    FLock.Leave;
  end;
  TaskDispatcher.Cancel(FTaskHandle, True);
end;

function TACLTaskQueue.IsActive: Boolean;
begin
  Result := FTaskHandle <> 0;
end;

procedure TACLTaskQueue.AsyncFinished;
begin
  FLock.Enter;
  try
    FTaskHandle := 0;
  finally
    FLock.Leave;
  end;
  CallNotifyEvent(Self, OnAsyncFinished);
end;

procedure TACLTaskQueue.AsyncRun;
begin
  while True do
  begin
    FLock.Enter;
    try
      if FPendingTasks.Count > 0 then
        FCurrentTask := FPendingTasks.Extract(FPendingTasks.First) as TACLTask
      else
        FCurrentTask := nil;
    finally
      FLock.Leave;
    end;

    if FCurrentTask <> nil then
      TaskDispatcher.RunInCurrentThread(FCurrentTask)
    else
      Break;
  end;
end;

{ TACLTaskComparer }

function TACLTaskComparer.Compare(const Left, Right: TACLTask): Integer;
begin
  Result := Ord(Right.GetPriority) - Ord(Left.GetPriority);
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
  FHandle := CreateEvent(nil, True, False, nil);
end;

destructor TACLTaskEvent.Destroy;
begin
  CloseHandle(FHandle);
  inherited Destroy;
end;

function TACLTaskEvent.Signal: Boolean;
begin
  Result := SetEvent(FHandle);
end;

function TACLTaskEvent.WaitFor(ATimeOut: Cardinal): TWaitResult;
begin
  Result := WaitForSyncObject(FHandle, ATimeOut);
end;

{ TACLTaskDispatcher }

constructor TACLTaskDispatcher.Create;
begin
  inherited Create;
  IsMultiThread := True;
  FTasks := TACLObjectList<TACLTask>.Create;
  FActiveTasks := TACLList<TACLTask>.Create;
  FLock := TACLCriticalSection.Create(Self, 'TaskLock');
  FCpuUsageMonitor := TACLTimer.CreateEx(HandlerCpuUsageMonitor, CpuUsageMonitorUpdateInterval, True);
  MaxActiveTasks := 4 * CPUCount;
end;

destructor TACLTaskDispatcher.Destroy;
begin
  FreeAndNil(FCpuUsageMonitor);
  FreeAndNil(FActiveTasks);
  FreeAndNil(FTasks);
  FreeAndNil(FLock);
  inherited Destroy;
end;

function TACLTaskDispatcher.Run(AProc: TACLTaskProc): THandle;
begin
  Result := Run(TACLSimpleTask.Create(AProc));
end;

function TACLTaskDispatcher.Run(AProc: TACLTaskProc;
  ACompleteEvent: TThreadMethod; ACompleteEventCallMode: TACLThreadMethodCallMode): THandle;
begin
  Result := Run(TACLSimpleTask.Create(AProc), ACompleteEvent, ACompleteEventCallMode);
end;

function TACLTaskDispatcher.Run(ATask: TACLTask): THandle;
begin
  Result := Run(ATask, TThreadMethod(nil), tmcmAsync);
end;

function TACLTaskDispatcher.Run(ATask: TACLTask;
  ACompleteEvent: TThreadMethod; ACompleteEventCallMode: TACLThreadMethodCallMode): THandle;
var
  AComparer: IComparer<TACLTask>;
begin
  FLock.Enter;
  try
    ATask.FOnComplete := ACompleteEvent;
    ATask.FOnCompleteMode := ACompleteEventCallMode;
    Result := ATask.Handle;
    FTasks.Add(ATask);
    AComparer := TACLTaskComparer.Create;
    try
      FTasks.Sort(AComparer);
    finally
      AComparer := nil;
    end;
  finally
    FLock.Leave;
  end;
  CheckActiveTasks;
end;

function TACLTaskDispatcher.Run(AProc, ACompleteEvent: TThreadMethod; ACompleteEventCallMode: TACLThreadMethodCallMode): THandle;
begin
  Result := Run(TACLSimpleTask.Create(AProc), ACompleteEvent, ACompleteEventCallMode);
end;

function TACLTaskDispatcher.RunInCurrentThread(ATask: TACLTask): THandle;
begin
  Result := 0;
  try
    try
      ATask.Execute;
    finally
      ATask.Complete;
    end;
  finally
    ATask.Free;
  end;
end;

procedure TACLTaskDispatcher.BeforeDestruction;
begin
  inherited BeforeDestruction;
  UseCpuUsageMonitor := False;
  FActualMaxActiveTasks := 0;
  FMaxActiveTasks := 0;
  CancelAll(True);
end;

function TACLTaskDispatcher.Cancel(ATaskHandle: THandle; AWaitFor: Boolean = False): Boolean;
begin
  Result := Cancel(ATaskHandle, IfThen(AWaitFor, INFINITE)) <> wrError;
end;

function TACLTaskDispatcher.Cancel(ATaskHandle: THandle; AWaitTimeOut: Cardinal): TWaitResult;
var
  AIndex: Integer;
  ATask: TACLTask;
  AWaitEvent: IACLTaskEvent;
begin
  AWaitEvent := nil;
  if ATaskHandle <> 0 then
  begin
    // Cancel pending item
    FLock.Enter;
    try
      AIndex := FTasks.IndexOf(TACLTask(ATaskHandle));
      if AIndex >= 0 then
      begin
        TACLTask(ATaskHandle).FCanceled := 1;
        TACLTask(ATaskHandle).Complete;
        FTasks.Delete(AIndex);
        Exit(wrSignaled);
      end;

      // Cancel active item
      for AIndex := 0 to FActiveTasks.Count - 1 do
      begin
        ATask := FActiveTasks.List[AIndex];
        if ATaskHandle = ATask.Handle then
        begin
          ATask.Cancel;
          AWaitEvent := ATask.FEvent;
          Break;
        end;
      end;
    finally
      FLock.Leave;
    end;
  end;

  if AWaitEvent <> nil then
    Result := AWaitEvent.WaitFor(AWaitTimeOut)
  else
    Result := wrAbandoned;

  if IsMainThread then
    CheckSynchronize;
end;

function TACLTaskDispatcher.CurrentTask: TACLTask;
var
  AThreadId: Cardinal;
  AIndex: Integer;
begin
  FLock.Enter;
  try
    AThreadId := GetCurrentThreadId;
    for AIndex := 0 to FActiveTasks.Count - 1 do
    begin
      Result := FActiveTasks.List[AIndex];
      if Result.FThreadID = AThreadId then
        Exit;
    end;
    Result := nil;
  finally
    FLock.Leave;
  end;
end;

function TACLTaskDispatcher.WaitFor(ATaskHandle: THandle): Boolean;
begin
  Result := WaitFor(ATaskHandle, INFINITE) in SuccessfulWaitResults;
end;

function TACLTaskDispatcher.WaitFor(ATaskHandle: THandle; AWaitTimeOut: Cardinal): TWaitResult;
var
  AIndex: Integer;
  AWaitEvent: IACLTaskEvent;
  ATask: TACLTask;
begin
  AWaitEvent := nil;

  FLock.Enter;
  try
    // if task is pending - activate it now
    AIndex := FTasks.IndexOf(TACLTask(ATaskHandle));
    if AIndex >= 0 then
      Start(FTasks[AIndex]);

    // find task in active work item list
    for AIndex := 0 to FActiveTasks.Count - 1 do
    begin
      ATask := FActiveTasks.List[AIndex];
      if ATaskHandle = ATask.Handle then
      begin
        AWaitEvent := ATask.FEvent;
        Break;
      end;
    end;
  finally
    FLock.Leave;
  end;

  if AWaitEvent <> nil then
    Result := AWaitEvent.WaitFor(AWaitTimeOut)
  else
    Result := wrAbandoned;
end;

class function TACLTaskDispatcher.ThreadProc(ATask: TACLTask): Integer;
begin
{$IFDEF DEBUG}
  TThread.NameThreadForDebugging('ThreadPool - ' + ATask.ClassName);
{$ENDIF}
  ATask.FOwner.AsyncRun(ATask);
{$IFDEF DEBUG}
  TThread.NameThreadForDebugging('ThreadPool - Idle');
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
    ATask.FEvent := TACLTaskEvent.Create;
    FActiveTasks.Add(FTasks.Extract(ATask));
    RunInThread(@ThreadProc, ATask);
  finally
    FLock.Leave;
  end;
end;

procedure TACLTaskDispatcher.AsyncRun(ATask: TACLTask);
const
  PriorityMap: array[TACLTaskPriority] of Integer = (
    THREAD_PRIORITY_IDLE, THREAD_PRIORITY_NORMAL, THREAD_PRIORITY_HIGHEST
  );
begin
  try
    ATask.FThreadID := GetCurrentThreadId;
    SetThreadPriority(GetCurrentThread, PriorityMap[ATask.GetPriority]);
    try
      try
        ATask.Execute;
      finally
        ATask.Complete;
      end;
    except
  //    FException := ExceptObject;
  //    RunInMainThread(SyncHandleException);
    end;

    FLock.Enter;
    try
      FActiveTasks.Remove(ATask);
      CheckActiveTasks;
    finally
      FLock.Leave;
    end;

    ATask.FEvent.Signal;
  finally
    ATask.Free;
  end;
end;

procedure TACLTaskDispatcher.CancelAll(AWaitFor: Boolean);
var
  ATaskHandle: THandle;
begin
  // Mark all as canceled
  FLock.Enter;
  try
    for var I := FTasks.Count - 1 downto 0 do
      Cancel(FTasks[I].Handle, False);
    for var I := FActiveTasks.Count - 1 downto 0 do
      Cancel(FActiveTasks[I].Handle, False);
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
          ATaskHandle := FActiveTasks.First.Handle
        else
          ATaskHandle := 0;
      finally
        FLock.Leave;
      end;
      Cancel(ATaskHandle, True);
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
  Result := TACLTimer(FCpuUsageMonitor).Enabled;
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
    raise EInvalidArgument.Create('');

  TACLTimer(FCpuUsageMonitor).Enabled := AValue;
end;

initialization

finalization
  FreeAndNil(FTaskDispatcher);
end.
