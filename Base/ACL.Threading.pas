﻿{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*         Multi Threading Routines          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Threading;

{$I ACL.Config.inc}

{.$DEFINE ACL_USE_MONITOR_LOCKS}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
  Winapi.Messages,
{$ENDIF}
  // System
  System.Classes,
  System.Generics.Defaults,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils,
  System.Types,
  // ACL
  ACL.Utils.Common;

type
  TACLThreadMethodCallMode = (tmcmAsync, tmcmSync, tmcmSyncPostponed);

{$IFNDEF MSWINDOWS}
  TThreadStartRoutine = function(lpThreadParameter: Pointer): Integer stdcall;
{$ENDIF}

  { TACLCriticalSection }

  TACLCriticalSection = class
  strict private
  {$IFNDEF ACL_USE_MONITOR_LOCKS}
    FLocked: Byte;
    FOwningThreadID: Cardinal;
    FRecursionCount: Integer;
  {$ENDIF}
  public
    constructor Create(AOwner: TObject = nil; const AName: string = '');
    procedure Enter; inline;
    procedure Leave; inline;
    function TryEnter(AMaxTryCount: Integer = 15{~15 msec}): Boolean; inline;
  end;

  { TACLEvent }

  TACLEvent = class
  strict protected
  {$IFDEF MSWINDOWS}
    FHandle: THandle;
  {$ELSE}
    FSyncObj: TEvent;
  {$ENDIF}
  public
    constructor Create; overload;
    constructor Create(AManualReset, AInitialState: LongBool); overload;
    destructor Destroy; override;
    function WaitFor(ATimeOut: Cardinal = INFINITE): LongBool;
    function WaitForNoSynchronize(ATimeOut: Cardinal = INFINITE): LongBool;
    procedure Reset; inline;
    procedure Signal; inline;
  {$IFDEF MSWINDOWS}
    property Handle: THandle read FHandle;
  {$ENDIF}
  end;

  { TACLReadWriteSync }

  TACLReadWriteSync = class
  strict private
    FLockCounter: TACLCriticalSection;
    FLockWriter: TACLCriticalSection;
    FNoReadersEvent: TACLEvent;
    FReaderCounter: Integer;
    FWaitingWriter: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeginRead; inline;
    procedure BeginWrite; inline;
    procedure EndRead; inline;
    procedure EndWrite; inline;
    function TryBeginWrite: Boolean; inline;
  end;

  { TACLThreadObject }

  TACLThreadObject<T: class> = class
  strict private
    FLock: TACLCriticalSection;
    FObject: T;
  public
    constructor Create(const AObject: T);
    destructor Destroy; override;
    function Lock: T;
    procedure Unlock;
  end;

  { TACLThread }

  TACLThread = class(TThread, IUnknown)
  strict private
    // IUnknown
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
  public
    procedure BeforeDestruction; override;
    procedure Terminate; virtual;
    procedure TerminateForce;
    /// <summary>
    ///    Returns True if after AStartTime the specified ATimeout is passed.
    ///    If ATimeout = 0 or ATimeout = INFINITY - function always returns False.
    /// </summary>
    class function IsTimeout(AStartTime: Cardinal; ATimeOut: Cardinal): Boolean; static;
  end;

  { TACLPauseableThread }

  TACLPauseableThread = class(TACLThread)
  strict private
    FPauseEvent: TACLEvent;
  protected
    function CheckForPause(ATimeOut: Cardinal = INFINITE): Boolean;
    function WaitForUnpause(ATimeOut: Cardinal = INFINITE): Boolean;
  public
    constructor Create(ASuspended: Boolean);
    destructor Destroy; override;
    procedure SetPaused(AValue: Boolean); virtual;
  end;

  { TACLMultithreadedOperation }

  TACLMultithreadedOperation = class sealed
  public type
    TFilterProc = procedure (Chunk: Pointer);
  strict private
    class var FFilterProc: TFilterProc;
    class var FLock: TACLCriticalSection;
    class var FLockEvent: TACLEvent;
    class var FNumberOfActiveThreads: Integer;
  protected
    class procedure CheckDone;
    class function ThreadProc(AChunk: Pointer): Integer; static; stdcall;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure Run(AChunks: PPointer; AChunkCount: Integer; AFilterProc: TFilterProc);
  end;

  { TACLMainThread }

  TACLMainThread = class
  strict private type
  {$REGION 'Internal types'}
    PSynchronizeRecord = ^TSynchronizeRecord;
    TSynchronizeRecord = record
      Method: TThreadMethod;
      Proc: TProc;
      Receiver: Pointer;
    end;
  {$ENDREGION}
  strict private
  {$IFDEF MSWINDOWS}
    class var FHandle: HWND;
  {$ENDIF}
    class var FQueue: TThreadList<PSynchronizeRecord>;

    class function Allocate(AReceiver: Pointer; AProc: TThreadMethod): PSynchronizeRecord; overload;
    class function Allocate(AReceiver: Pointer; AProc: TProc): PSynchronizeRecord; overload;
    class procedure Execute; overload;
    class procedure Execute(ARecord: PSynchronizeRecord); overload;
    class procedure Run(ARecord: PSynchronizeRecord; AWaitFor: Boolean); overload;
  {$IFDEF MSWINDOWS}
    class procedure WndProc(var Message: TMessage);
  {$ENDIF}
  public
    class constructor Create;
    class destructor Destroy;
    class procedure CheckSynchronize;
    class procedure Run(AProc: TProc; AWaitFor: Boolean; AReceiver: Pointer = nil); overload;
    class procedure Run(AProc: TThreadMethod; AWaitFor: Boolean; AReceiver: Pointer = nil); overload;
    class procedure RunImmediately(AProc: TProc); overload;
    class procedure RunImmediately(AProc: TThreadMethod); overload;
    class procedure RunPostponed(AProc: TProc; AReceiver: Pointer = nil); overload;
    class procedure RunPostponed(AProc: TThreadMethod; AReceiver: Pointer = nil); overload;
    class procedure Unsubscribe(AProc: TThreadMethod); overload;
    class procedure Unsubscribe(AReceiver: Pointer); overload;
  end;

procedure CheckIsMainThread;
function IsMainThread: Boolean; inline;
{$IFDEF MSWINDOWS}
function WaitForSyncObject(AHandle: THandle; ATimeOut: Cardinal): TWaitResult;
{$ENDIF}

function LockCompareExchange(const ACompareValue, ANewValue: Byte; AReturnAddress: PByte): Byte; // to be inlined

procedure CallThreadMethod(AMethod: TThreadMethod; ACallInMainThread: Boolean); overload;
procedure CallThreadMethod(AMethod: TThreadMethod; AMode: TACLThreadMethodCallMode); overload;

procedure RunInMainThread(AProc: TProc; AWaitFor: Boolean = True); overload; inline;
procedure RunInMainThread(AProc: TThreadMethod; AWaitFor: Boolean = True); overload; inline;
procedure RunInThread(Func: TThreadStartRoutine; Context: Pointer);
implementation

uses
{$IFDEF POSIX}
  Posix.Pthread,
{$ENDIF}
  // System
  System.Math,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
{$IFDEF MSWINDOWS}
  ACL.Utils.Messaging,
{$ENDIF}
  ACL.Utils.Stream;

procedure CheckIsMainThread;
begin
  if not IsMainThread then
    raise Exception.Create('Must be called from main thread only');
end;

function IsMainThread: Boolean; inline;
begin
  Result := GetCurrentThreadId = MainThreadID;
end;

function LockCompareExchange(const ACompareValue, ANewValue: Byte; AReturnAddress: PByte): Byte;
{$IFDEF MSWINDOWS}
asm
{$IFDEF CPUX64}
  // cl = CompareVal
  // dl = NewVal
  // r8 = AAddress
  .noframe
  mov rax, rcx
  lock cmpxchg [r8], dl
{$ELSE}
  // al = ACompareValue,
  // dl = ANewValue,
  // ecx = AReturnAddress
  lock cmpxchg [ecx], dl
{$ENDIF}
end;
{$ELSE}
begin
  Result := AtomicCmpExchange(AReturnAddress^, ANewValue, ACompareValue);
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
function WaitForSyncObject(AHandle: THandle; ATimeOut: Cardinal): TWaitResult;
const
  MaxWaitTime = 100;
var
  AHandles: array[0..1] of THandle;
  AMsg: TMsg;
  AStartWaitTime: Cardinal;
  AWaitResult: Cardinal;
begin
  Result := wrError;
  if IsMainThread then
  begin
    AHandles[0] := AHandle;
    AHandles[1] := SyncEvent;
    AStartWaitTime := TACLThread.GetTickCount;
    while ATimeOut > 0 do
    begin
      AWaitResult := MsgWaitForMultipleObjects(2, AHandles, False, Min(MaxWaitTime, ATimeOut), QS_SENDMESSAGE);
      case AWaitResult of
        WAIT_FAILED:
          Exit(wrError);
        WAIT_OBJECT_0:
          Exit(wrSignaled);
        WAIT_ABANDONED:
          Exit(wrAbandoned);
        WAIT_OBJECT_0 + 1:
          TACLMainThread.CheckSynchronize;
        WAIT_OBJECT_0 + 2:
          PeekMessage(AMsg, 0, 0, 0, PM_NOREMOVE);
      end;
      if TACLThread.IsTimeout(AStartWaitTime, ATimeOut) then
        Exit(wrTimeout);
    end;
  end
  else
    case WaitForSingleObject(AHandle, ATimeOut) of
      WAIT_OBJECT_0:
        Result := wrSignaled;
      WAIT_ABANDONED:
        Result := wrAbandoned;
      WAIT_TIMEOUT:
        Result := wrTimeout;
    end;
end;
{$ENDIF}

procedure CallThreadMethod(AMethod: TThreadMethod; ACallInMainThread: Boolean);
const
  Map: array[Boolean] of TACLThreadMethodCallMode = (tmcmAsync, tmcmSync);
begin
  CallThreadMethod(AMethod, Map[ACallInMainThread]);
end;

procedure CallThreadMethod(AMethod: TThreadMethod; AMode: TACLThreadMethodCallMode);
begin
  if Assigned(AMethod) then
  begin
    if AMode = tmcmAsync then
      AMethod
    else
      RunInMainThread(AMethod, AMode = tmcmSync);
  end;
end;

procedure RunInMainThread(AProc: TProc; AWaitFor: Boolean = True);
begin
  TACLMainThread.Run(AProc, AWaitFor);
end;

procedure RunInMainThread(AProc: TThreadMethod; AWaitFor: Boolean = True);
begin
  TACLMainThread.Run(AProc, AWaitFor);
end;

procedure RunInThread(Func: TThreadStartRoutine; Context: Pointer);
begin
{$IFDEF MSWINDOWS}
  if not QueueUserWorkItem(Func, Context, WT_EXECUTELONGFUNCTION) then
    RaiseLastOSError;
{$ELSE}
  TThread.CreateAnonymousThread(
    procedure
    begin
      Func(Context);
    end).Start;
{$ENDIF}
end;

{ TACLCriticalSection }

constructor TACLCriticalSection.Create(AOwner: TObject = nil; const AName: string = '');
begin
  // do nothing
end;

procedure TACLCriticalSection.Enter;
{$IFDEF ACL_USE_MONITOR_LOCKS}
begin
  System.TMonitor.Enter(Self);
end;
{$ELSE}
var
  AThreadId: Cardinal;
begin
  AThreadId := GetCurrentThreadId;
  if FOwningThreadId <> AThreadId then
  begin
    while LockCompareExchange(0, 1, @FLocked) <> 0 do
    begin
      Sleep(0);
      if LockCompareExchange(0, 1, @FLocked) = 0 then
        Break;
      Sleep(1);
    end;
    FOwningThreadId := AThreadId;
  end;
  Inc(FRecursionCount);
end;
{$ENDIF}

procedure TACLCriticalSection.Leave;
begin
{$IFDEF ACL_USE_MONITOR_LOCKS}
  System.TMonitor.Exit(Self);
{$ELSE}
  if FOwningThreadId <> GetCurrentThreadId then
    raise EInvalidOperation.Create('Section is not owned');

  Dec(FRecursionCount);
  if FRecursionCount < 0 then
    raise EInvalidOperation.Create('RecursionCount < 0');

  if FRecursionCount = 0 then
  begin
    FOwningThreadId := 0;
    FLocked := 0;
  end;
{$ENDIF}
end;

function TACLCriticalSection.TryEnter(AMaxTryCount: Integer = 15): Boolean;
{$IFDEF ACL_USE_MONITOR_LOCKS}
begin
  repeat
    Result := System.TMonitor.TryEnter(Self);
    Dec(AMaxTryCount);
  until Result or (AMaxTryCount <= 0);
end;
{$ELSE}
var
  AThreadId: Cardinal;
begin
  AThreadId := GetCurrentThreadId;
  if FOwningThreadId <> AThreadId then
    while LockCompareExchange(0, 1, @FLocked) <> 0 do
    begin
      if AMaxTryCount = 0 then
        Exit(False);
      Dec(AMaxTryCount);
      Sleep(1);
    end;

  FOwningThreadId := AThreadId;
  Inc(FRecursionCount);
  Result := True;
end;
{$ENDIF}

{ TACLEvent }

constructor TACLEvent.Create;
begin
  Create(True, False);
end;

constructor TACLEvent.Create(AManualReset, AInitialState: LongBool);
begin
  inherited Create;
{$IFDEF MSWINDOWS}
  FHandle := CreateEvent(nil, AManualReset, AInitialState, nil);
{$ELSE}
  FSyncObj := TEvent.Create(nil, AManualReset, AInitialState, '');
{$ENDIF}
end;

destructor TACLEvent.Destroy;
begin
{$IFDEF MSWINDOWS}
  CloseHandle(FHandle);
  FHandle := 0;
{$ELSE}
  FreeAndNil(FSyncObj);
{$ENDIF}
  inherited Destroy;
end;

function TACLEvent.WaitFor(ATimeOut: Cardinal = INFINITE): LongBool;
{$IFDEF MSWINDOWS}
begin
  Result := WaitForSyncObject(FHandle, ATimeOut) = wrSignaled;
end;
{$ELSE}
const
  MaxWaitTime = 100;
var
  AStartWaitTime: Cardinal;
begin
  if IsMainThread then
  begin
    AStartWaitTime := TACLThread.GetTickCount;
    while True do
    begin
      case FSyncObj.WaitFor(Min(MaxWaitTime, ATimeOut)) of
        wrTimeOut:
          TACLMainThread.CheckSynchronize;
        wrSignaled:
          Exit(True);
      end;
      if TACLThread.IsTimeout(AStartWaitTime, ATimeOut) then
        Exit(False);
    end;
  end
  else
    Result := FSyncObj.WaitFor(ATimeOut) = wrSignaled;
end;
{$ENDIF}

function TACLEvent.WaitForNoSynchronize(ATimeOut: Cardinal = INFINITE): LongBool;
begin
{$IFDEF MSWINDOWS}
  Result := WaitForSingleObject(FHandle, ATimeOut) = WAIT_OBJECT_0;
{$ELSE}
  Result := FSyncObj.WaitFor(ATimeOut) = wrSignaled;
{$ENDIF}
end;

procedure TACLEvent.Reset;
begin
{$IFDEF MSWINDOWS}
  ResetEvent(FHandle);
{$ELSE}
  FSyncObj.ResetEvent;
{$ENDIF}
end;

procedure TACLEvent.Signal;
begin
{$IFDEF MSWINDOWS}
  SetEvent(FHandle);
{$ELSE}
  FSyncObj.SetEvent;
{$ENDIF}
end;

{ TACLReadWriteSync }

constructor TACLReadWriteSync.Create;
begin
  FNoReadersEvent := TACLEvent.Create(True, True);
  FLockWriter := TACLCriticalSection.Create;
  FLockCounter := TACLCriticalSection.Create;
end;

destructor TACLReadWriteSync.Destroy;
begin
  FreeAndNil(FLockCounter);
  FreeAndNil(FLockWriter);
  FreeAndNil(FNoReadersEvent);
  inherited;
end;

procedure TACLReadWriteSync.BeginRead;
begin
  FLockWriter.Enter;
  try
    FLockCounter.Enter;
    try
      Inc(FReaderCounter);
    finally
      FLockCounter.Leave;
    end;
  finally
    FLockWriter.Leave;
  end;
end;

procedure TACLReadWriteSync.BeginWrite;
begin
  FLockWriter.Enter;
  if FReaderCounter > 0 then
  begin
    FLockCounter.Enter;
    try
      if FReaderCounter > 0 then
      begin
        FWaitingWriter := True;
        FNoReadersEvent.Reset;
      end;
    finally
      FLockCounter.Leave;
    end;
    FNoReadersEvent.WaitFor;
    FWaitingWriter := False;
  end;
end;

procedure TACLReadWriteSync.EndRead;
begin
  FLockCounter.Enter;
  try
    Dec(FReaderCounter);
    if (FReaderCounter = 0) and FWaitingWriter then
      FNoReadersEvent.Signal;
  finally
    FLockCounter.Leave;
  end;
end;

procedure TACLReadWriteSync.EndWrite;
begin
  FLockWriter.Leave;
end;

function TACLReadWriteSync.TryBeginWrite: Boolean;
begin
  Result := True;
  FLockWriter.Enter;
  if FReaderCounter > 0 then
  begin
    FLockCounter.Enter;
    try
      if FReaderCounter > 0 then
      begin
        FWaitingWriter := True;
        FNoReadersEvent.Reset;
      end;
    finally
      FLockCounter.Leave;
    end;
    Result := FNoReadersEvent.WaitFor(30);
    FWaitingWriter := False;
  end;
  if not Result then
    FLockWriter.Leave;
end;

{ TACLThread }

procedure TACLThread.BeforeDestruction;
begin
  inherited BeforeDestruction;
  Terminate;
end;

class function TACLThread.IsTimeout(AStartTime, ATimeOut: Cardinal): Boolean;
var
  ANow: Cardinal;
begin
  if (ATimeOut = 0) or (ATimeOut = INFINITE) then
    Exit(False);

  ANow := GetTickCount;
  if ANow < AStartTime then
    Result := High(Cardinal) - AStartTime + ANow >= ATimeOut
  else
    Result := ANow - AStartTime >= Cardinal(ATimeOut);
end;

procedure TACLThread.Terminate;
begin
  if not Terminated then
  begin
    Suspended := False;
    inherited Terminate;
  end;
end;

procedure TACLThread.TerminateForce;
begin
{$IFDEF MSWINDOWS}
  TerminateThread(Handle, ReturnValue);
  DoTerminate;
{$ELSE}
  Terminate;
{$ENDIF}
end;

function TACLThread._AddRef: Integer; stdcall;
begin
  Result := -1;
end;

function TACLThread._Release: Integer; stdcall;
begin
  Result := -1;
end;

function TACLThread.QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

{ TACLPauseableThread }

constructor TACLPauseableThread.Create(ASuspended: Boolean);
begin
  inherited Create(ASuspended);
  FPauseEvent := TACLEvent.Create(True, True);
end;

destructor TACLPauseableThread.Destroy;
begin
  SetPaused(False);
  inherited Destroy;
  FreeAndNil(FPauseEvent);
end;

function TACLPauseableThread.CheckForPause(ATimeOut: Cardinal = INFINITE): Boolean;
begin
  if not Terminated then
    SetPaused(True);
  Result := WaitForUnpause(ATimeOut);
end;

function TACLPauseableThread.WaitForUnpause(ATimeOut: Cardinal = INFINITE): Boolean;
begin
  Result := not Terminated and FPauseEvent.WaitFor(ATimeOut);
end;

procedure TACLPauseableThread.SetPaused(AValue: Boolean);
begin
  if AValue then
    FPauseEvent.Reset
  else
    FPauseEvent.Signal;
end;

{ TACLMultithreadedOperation }

class constructor TACLMultithreadedOperation.Create;
begin
  FLock := TACLCriticalSection.Create;
  FLockEvent := TACLEvent.Create;
end;

class destructor TACLMultithreadedOperation.Destroy;
begin
  FreeAndNil(FLockEvent);
  FreeAndNil(FLock);
end;

class procedure TACLMultithreadedOperation.Run(AChunks: PPointer; AChunkCount: Integer; AFilterProc: TFilterProc);
begin
  if AChunkCount > 0 then
  begin
    FLock.Enter;
    try
      FFilterProc := AFilterProc;
      FNumberOfActiveThreads := AChunkCount;
      if AChunkCount > 1 then
      begin
        FLockEvent.Reset;
        while AChunkCount > 0 do
        begin
          RunInThread(@ThreadProc, AChunks^);
          Dec(AChunkCount);
          Inc(AChunks);
        end;
        FLockEvent.WaitForNoSynchronize;
      end
      else
        ThreadProc(AChunks^);
    finally
      FLock.Leave;
    end;
  end;
end;

class procedure TACLMultithreadedOperation.CheckDone;
begin
  if AtomicDecrement(FNumberOfActiveThreads) = 0 then
    FLockEvent.Signal;
end;

class function TACLMultithreadedOperation.ThreadProc(AChunk: Pointer): Integer;
begin
  Result := 0;
  try
    try
      FFilterProc(AChunk);
    except
      // do nothing
    end;
  finally
    CheckDone;
  end;
end;

{ TACLMainThread }

class constructor TACLMainThread.Create;
begin
{$IFDEF MSWINDOWS}
  FHandle := WndCreate(WndProc, ClassName, True);
{$ENDIF}
  FQueue := TThreadList<PSynchronizeRecord>.Create;
end;

class destructor TACLMainThread.Destroy;
begin
{$IFDEF MSWINDOWS}
  WndFree(FHandle);
{$ELSE}
  TACLThread.RemoveQueuedEvents(Execute);
{$ENDIF}
  with FQueue.LockList do
  try
    if Count > 0 then
      raise EInvalidOperation.Create(ClassName);
  finally
    FQueue.UnlockList;
  end;
  FreeAndNil(FQueue);
end;

class procedure TACLMainThread.CheckSynchronize;
begin
  if not IsMainThread then
    raise EInvalidArgument.Create(ClassName);
  System.Classes.CheckSynchronize;
  Execute;
end;

class procedure TACLMainThread.Run(AProc: TProc; AWaitFor: Boolean; AReceiver: Pointer);
begin
  Run(Allocate(AReceiver, AProc), AWaitFor);
end;

class procedure TACLMainThread.Run(AProc: TThreadMethod; AWaitFor: Boolean; AReceiver: Pointer);
begin
  Run(Allocate(AReceiver, AProc), AWaitFor);
end;

class procedure TACLMainThread.RunImmediately(AProc: TThreadMethod);
begin
  Run(AProc, True);
end;

class procedure TACLMainThread.RunImmediately(AProc: TProc);
begin
  Run(AProc, True);
end;

class procedure TACLMainThread.RunPostponed(AProc: TThreadMethod; AReceiver: Pointer);
begin
  Run(AProc, False, AReceiver);
end;

class procedure TACLMainThread.RunPostponed(AProc: TProc; AReceiver: Pointer);
begin
  Run(AProc, False, AReceiver);
end;

class procedure TACLMainThread.Unsubscribe(AProc: TThreadMethod);
var
  I: Integer;
begin
  with FQueue.LockList do
  try
    for I := Count - 1 downto 0 do
      if @List[I].Method = @AProc then
      begin
        Dispose(List[I]);
        Delete(I);
      end;
  finally
    FQueue.UnlockList;
  end;
end;

class procedure TACLMainThread.Unsubscribe(AReceiver: Pointer);
var
  I: Integer;
begin
  with FQueue.LockList do
  try
    for I := Count - 1 downto 0 do
      if List[I].Receiver = AReceiver then
      begin
        Dispose(List[I]);
        Delete(I);
      end;
  finally
    FQueue.UnlockList;
  end;
end;

class function TACLMainThread.Allocate(AReceiver: Pointer; AProc: TThreadMethod): PSynchronizeRecord;
begin
  New(Result);
  Result^.Proc := nil;
  Result^.Method := AProc;
  Result^.Receiver := AReceiver;
end;

class function TACLMainThread.Allocate(AReceiver: Pointer; AProc: TProc): PSynchronizeRecord;
begin
  New(Result);
  Result^.Method := nil;
  Result^.Proc := AProc;
  Result^.Receiver := AReceiver;
end;

class procedure TACLMainThread.Execute;
var
  ASync: PSynchronizeRecord;
begin
  repeat
    with FQueue.LockList do
    try
      if Count = 0 then
        Exit;
      ASync := First;
      Delete(0);
    finally
      FQueue.UnlockList;
    end;
    Execute(ASync);
  until False;
end;

class procedure TACLMainThread.Execute(ARecord: PSynchronizeRecord);
begin
  try
    if Assigned(ARecord^.Method) then
      ARecord^.Method();
    if Assigned(ARecord^.Proc) then
      ARecord^.Proc();
  finally
    Dispose(ARecord);
  end;
end;

class procedure TACLMainThread.Run(ARecord: PSynchronizeRecord; AWaitFor: Boolean);
begin
  if AWaitFor then
  begin
    if IsMainThread then
      Execute(ARecord)
    else
    {$IFDEF MSWINDOWS}
      SendMessage(FHandle, WM_USER, 0, LPARAM(ARecord));
    {$ELSE}
      TACLThread.Synchronize(nil,
        procedure
        begin
          Execute(ARecord);
        end);
    {$ENDIF}
  end
  else
  begin
    FQueue.Add(ARecord);
  {$IFDEF MSWINDOWS}
    PostMessage(FHandle, WM_USER, 0, 0);
  {$ELSE}
    TACLThread.Queue(nil, Execute);
  {$ENDIF}
  end;
end;

{$IFDEF MSWINDOWS}
class procedure TACLMainThread.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_USER then
  begin
    if Message.LParam <> 0 then
      Execute(PSynchronizeRecord(Message.LParam))
    else
      Execute;
  end;
  WndDefaultProc(FHandle, Message);
end;
{$ENDIF}

{ TACLThreadObject<T> }

constructor TACLThreadObject<T>.Create(const AObject: T);
begin
  FObject := AObject;
  FLock := TACLCriticalSection.Create;
end;

destructor TACLThreadObject<T>.Destroy;
begin
  FreeAndNil(FLock);
  FreeAndNil(FObject);
  inherited;
end;

function TACLThreadObject<T>.Lock: T;
begin
  FLock.Enter;
  Result := FObject;
end;

procedure TACLThreadObject<T>.Unlock;
begin
  FLock.Leave;
end;

initialization
  IsMultiThread := True;
{$IFDEF DEBUG}
  TThread.NameThreadForDebugging('Main');
{$ENDIF}
end.
