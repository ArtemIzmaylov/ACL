////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Threading Utilities and Types
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Threading;

{$I ACL.Config.inc}

interface

uses
{$IFDEF LINUX}
  dl,
{$ENDIF}
{$IF DEFINED(LCLGtk3)}
  LazGlib2,
{$ELSEIF DEFINED(LCLGtk2)}
  Glib2,
{$ENDIF}
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Generics.Defaults,
  {System.}Generics.Collections,
  {System.}Math,
  {System.}SyncObjs,
  {System.}SysUtils,
  // ACL
  ACL.Utils.Common,
  ACL.Utils.Messaging;

type
  TACLThreadMethodCallMode = (tmcmAsync, tmcmSync, tmcmSyncPostponed);
{$IFNDEF MSWINDOWS}
  TThreadStartRoutine = function(lpThreadParameter: Pointer): Integer stdcall;
{$ENDIF}

  { EACLDeadlockException }

  EACLDeadlockException = class(Exception)
  public
    constructor Create(AThreadId1, AThreadId2: TThreadId);
  end;

  { TACLCriticalSection }

  TACLCriticalSection = class
  strict private
  {$IF DEFINED(FPC)}
    FHandle: TRTLCriticalSection;
  {$ELSE}
    FLocked: Integer;
    FOwningThreadID: TThreadId;
    FRecursionCount: Integer;
  {$IFEND}
  public
    constructor Create({%H-}AOwner: TObject = nil; const {%H-}AName: string = '');
    destructor Destroy; override;
    procedure Enter; inline;
    procedure Leave; inline;
    function TryEnter: Boolean; overload; inline;
    function TryEnter(ACancelFunc: TFunc<Boolean>): Boolean; overload; inline;
    function TryEnter(ACancelToken: PBoolean): Boolean; overload; inline;
  end;

  { TACLEvent }

  TACLEvent = class
  strict protected
  {$IFDEF MSWINDOWS}
    FHandle: TObjHandle;
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
    property Handle: TObjHandle read FHandle;
  {$ENDIF}
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
  protected
    procedure Synchronize(AProc: TProc); overload;
    procedure Synchronize(AProc: TThreadMethod); overload;
    // IUnknown
    function _AddRef: Integer; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
    function _Release: Integer; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
    function QueryInterface({$IFDEF FPC}constref{$ELSE}const{$ENDIF}
      IID: TGUID; out Obj): HRESULT; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  public
    procedure BeforeDestruction; override;
    procedure Terminate; virtual;
    procedure TerminateForce;
  {$IF DEFINED(ACL_THREADING_DEBUG_DEADLOCKS)}
    function WaitFor: LongWord;
  {$ENDIF}
  {$IF DEFINED(ACL_THREADING_DEBUG) AND DEFINED(MSWINDOWS)}
    class procedure NameThreadForDebugging(const AName: string);
  {$ENDIF}
    class function GetName(AThreadId: TThreadId): string;
    /// <summary>
    ///    Returns True if after AStartTime the specified ATimeout is passed.
    ///    If ATimeout = 0 or ATimeout = INFINITY - function always returns False.
    /// </summary>
    class function IsTimeout(AStartTime, ATimeOut: Cardinal): Boolean; static;
    /// <summary>
    ///    Returns True if after ATimestamp the specified ATimeout is passed.
    ///    If ATimeout = 0 or ATimeout = INFINITY - function always returns False.
    ///    If ATimeout is passed the ATimestamp will be updated to current timestamp
    /// </summary>
    class function IsTimeoutEx(var ATimestamp: Cardinal; ATimeOut: Cardinal): Boolean; static;
    class function Timestamp: Cardinal;
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
    procedure Terminate; override;
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
  {$REGION ' Internal types '}
    PSynchronizeRecord = ^TSynchronizeRecord;
    TSynchronizeRecord = record
      Method: TThreadMethod;
      Proc: TProc;
      Receiver: Pointer;
    end;
  {$ENDREGION}
  strict private
    class var FWnd: TWndHandle;
    class var FWndMessage: Cardinal;
    class var FQueue: TThreadList<PSynchronizeRecord>;
  {$IFDEF ACL_THREADING_DEBUG_DEADLOCKS}
    class var FSynchronizingThreads: TThreadList<Cardinal>;
  {$ENDIF}
    class function Allocate(AReceiver: Pointer; AProc: TThreadMethod): PSynchronizeRecord; overload;
    class function Allocate(AReceiver: Pointer; AProc: TProc): PSynchronizeRecord; overload;
    class procedure Execute; overload;
    class procedure Execute(ARecord: PSynchronizeRecord); overload;
    class procedure Run(ARecord: PSynchronizeRecord; AWaitFor: Boolean); overload;
    class procedure WndProc(var AMessage: TMessage);
  public
    class constructor Create;
    class destructor Destroy;
    class procedure CheckForDeadlock(AWaitedThreadId: TThreadId);
    class procedure CheckSynchronize;
    class procedure Run(AProc: TProc; AWaitFor: Boolean; AReceiver: Pointer = nil); overload;
    class procedure Run(AProc: TThreadMethod; AWaitFor: Boolean; AReceiver: Pointer = nil); overload;
    class procedure RunImmediately(AProc: TProc); overload;
    class procedure RunImmediately(AProc: TThreadMethod); overload;
    class procedure RunPostponed(AProc: TProc; AReceiver: Pointer = nil); overload;
    class procedure RunPostponed(AProc: TThreadMethod; AReceiver: Pointer = nil); overload;
    class procedure Unsubscribe(AProc: TThreadMethod); overload;
    class procedure Unsubscribe(AReceiver: Pointer); overload;
    class procedure Wake;
  end;

procedure CheckIsMainThread;
function IsMainThread: Boolean;

{$IFDEF MSWINDOWS}
function WaitForSyncObject(AHandle: TObjHandle; ATimeOut: Cardinal): TWaitResult;
{$ENDIF}

procedure CallThreadMethod(AMethod: TThreadMethod; ACallInMainThread: Boolean); overload;
procedure CallThreadMethod(AMethod: TThreadMethod; AMode: TACLThreadMethodCallMode); overload;

procedure RunInMainThread(AProc: TProc; AWaitFor: Boolean = True); overload; inline;
procedure RunInMainThread(AProc: TThreadMethod; AWaitFor: Boolean = True); overload; inline;
procedure RunInThread(Func: TThreadStartRoutine; Context: Pointer);
implementation

// FPC:
//   Do not specify uses here
//   It may lead to 20231102 internal error because of generics
{$IFNDEF FPC}
uses
  ACL.Utils.Logger;
{$ENDIF}

{$IFDEF MSWINDOWS}
const
  THREAD_SET_LIMITED_INFORMATION   = $0400;
  THREAD_QUERY_LIMITED_INFORMATION = $0800;
type
  TGetThreadDescription = function (AThread: THandle; out ADescription: LPWSTR): HRESULT; stdcall;
  TSetThreadDescription = function (AThread: THandle; ADescription: LPWSTR): HRESULT; stdcall;
var
  FGetThreadDescription: TGetThreadDescription = nil; // Since Windows 10, 1607
  FSetThreadDescription: TSetThreadDescription = nil; // Since Windows 10, 1607
  function OpenThread(DesiredAccess: DWORD; InheritHandle: BOOL; ThreadId: TThreadId): THandle; stdcall; external kernel32;
{$ENDIF}

{$IFDEF LINUX}
var
  pthread: Pointer = nil;
  pthread_getname_np: function (thread: pointer; buf: PAnsiChar; len: size_t): Integer;cdecl;
{$ENDIF}

procedure CheckIsMainThread;
begin
  if GetCurrentThreadId <> MainThreadID then
    raise Exception.Create('Must be called from main thread only');
end;

function IsMainThread: Boolean;
begin
  Result := GetCurrentThreadId = MainThreadID;
end;

{$IFDEF MSWINDOWS}
function WaitForSyncObject(AHandle: TObjHandle; ATimeOut: Cardinal): TWaitResult;
const
  MaxWaitTime = 100;
var
  AHandles: array[0..1] of TObjHandle;
  AMsg: TMsg;
  AStartWaitTime: Cardinal;
  AWaitResult: Cardinal;
begin
  Result := wrError;
  if IsMainThread then
  begin
    // Exit immediatelly if event is already signaled, don't process queue messages!
    // It may lead to premature WM_COPYDATA message processing.
    if WaitForSingleObject(AHandle, 0) = WAIT_OBJECT_0 then
      Exit(wrSignaled);

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
  {$MESSAGE WARN 'OptimizeMe - emulate system thread-pool'}
  TThread.CreateAnonymousThread(procedure begin Func(Context); end).Start;
{$ENDIF}
end;

{ EACLDeadlockException }

constructor EACLDeadlockException.Create(AThreadId1, AThreadId2: TThreadId);
begin
  inherited CreateFmt('Deadlock between "%s" and "%s" was detected. Please send the report to the developers',
    [TACLThread.GetName(AThreadId1), TACLThread.GetName(AThreadId2)]);
end;

{ TACLCriticalSection }

constructor TACLCriticalSection.Create(AOwner: TObject = nil; const AName: string = '');
begin
{$IFDEF FPC}
  InitCriticalSection(FHandle{%H-});
{$ENDIF}
end;

destructor TACLCriticalSection.Destroy;
begin
{$IFDEF FPC}
  DoneCriticalSection(FHandle);
{$ELSE}
  if FOwningThreadId <> 0 then
    raise EInvalidOperation.CreateFmt('Attempt to destroy locked section (%d)', [FOwningThreadId]);
{$ENDIF}
  inherited Destroy;
end;

procedure TACLCriticalSection.Enter;
{$IF DEFINED(FPC)}
begin
  EnterCriticalSection(FHandle);
end;
{$ELSE}
var
  LThreadId: TThreadId;
begin
  LThreadId := GetCurrentThreadId;
  if FOwningThreadId <> LThreadId then
  begin
    while AtomicCmpExchange(FLocked, 1, 0) <> 0 do
    begin
      Sleep(0);
      if AtomicCmpExchange(FLocked, 1, 0) = 0 then
        Break;
      Sleep(1);
    end;
    if FOwningThreadId <> 0 then
      raise EInvalidOperation.CreateFmt('Section is locked by %d', [FOwningThreadId]);
    FOwningThreadId := LThreadId;
  end;
  Inc(FRecursionCount);
end;
{$ENDIF}

procedure TACLCriticalSection.Leave;
begin
{$IF DEFINED(FPC)}
  LeaveCriticalSection(FHandle);
{$ELSE}
  if FOwningThreadId <> GetCurrentThreadId then
    raise EInvalidOperation.CreateFmt('Section is not owned (%d)', [FOwningThreadId]);

  Dec(FRecursionCount);
  if FRecursionCount < 0 then
    raise EInvalidOperation.Create('Section.RecursionCount < 0');

  if FRecursionCount = 0 then
  begin
    FOwningThreadId := 0;
    FLocked := 0;
  end;
{$ENDIF}
end;

function TACLCriticalSection.TryEnter: Boolean;
{$IF DEFINED(FPC)}
begin
  Result := TryEnterCriticalSection(FHandle) <> 0;
end;
{$ELSE}
var
  LThreadId: TThreadId;
  LTryCount: Integer;
begin
  LThreadId := GetCurrentThreadId;
  if FOwningThreadId <> LThreadId then
  begin
    LTryCount := 5;
    while AtomicCmpExchange(FLocked, 1, 0) <> 0 do
    begin
      if LTryCount = 0 then
        Exit(False);
      Dec(LTryCount);
      Sleep(1);
    end;
    if FOwningThreadId <> 0 then
      raise EInvalidOperation.CreateFmt('Section is locked by %d', [FOwningThreadId]);
    FOwningThreadId := LThreadId;
  end;
  Inc(FRecursionCount);
  Result := True;
end;
{$ENDIF}

function TACLCriticalSection.TryEnter(ACancelFunc: TFunc<Boolean>): Boolean;
begin
  while True do
  begin
    if TryEnter then
      Exit(True);
    if ACancelFunc then
      Exit(False);
  end;
end;

function TACLCriticalSection.TryEnter(ACancelToken: PBoolean): Boolean;
begin
  while True do
  begin
    if TryEnter then
      Exit(True);
    if ACancelToken^ then
      Exit(False);
  end;
end;

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
  LStartWaitTime: Cardinal;
begin
  if IsMainThread then
  begin
    Result := False;
    LStartWaitTime := TACLThread.Timestamp;
    repeat
      case FSyncObj.WaitFor(Min(MaxWaitTime, ATimeOut)) of
        wrTimeOut:
          TACLMainThread.CheckSynchronize;
        wrSignaled:
          Exit(True);
      else;
      end;
    until TACLThread.IsTimeout(LStartWaitTime, ATimeOut);
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

{ TACLThread }

procedure TACLThread.BeforeDestruction;
begin
  inherited BeforeDestruction;
  Terminate;
end;

class function TACLThread.GetName(AThreadId: TThreadId): string;
{$IF DEFINED(MSWINDOWS)}
var
  LHandle: THandle;
  LName: LPWSTR;
{$ELSEIF DEFINED(FPC) AND DEFINED(LINUX)}
var
  LBuffer: array[0..31] of AnsiChar;
{$ENDIF}
begin
  if AThreadId = MainThreadID then
    Exit('Main');

{$IF DEFINED(MSWINDOWS)}
  if Assigned(FGetThreadDescription) then
  begin
    LHandle := OpenThread(THREAD_QUERY_LIMITED_INFORMATION, False, AThreadId);
    if LHandle <> 0 then
    try
      if Succeeded(FGetThreadDescription(LHandle, PChar(LName))) then
      try
        Exit(LName + ' (' + IntToStr(AThreadId) + ')');
      finally
        LocalFree(LName);
      end;
    finally
      CloseHandle(LHandle);
    end;
  end;
{$ENDIF}

{$IF DEFINED(FPC) AND DEFINED(LINUX)}
  if pthread = nil then
  begin
    pthread := dlopen('libc.so', RTLD_LAZY);
    pthread_getname_np := dlsym(pthread, 'pthread_getname_np');
    pthread := Pointer(-1);
  end;
  if Assigned(pthread_getname_np) then
  begin
    if pthread_getname_np(Pointer(AThreadId), @LBuffer[0], SizeOf(LBuffer)) = 0 then
      Exit(StrPas(LBuffer));
  end;
{$ENDIF}

  Result := IntToStr(AThreadId);
end;

class function TACLThread.IsTimeout(AStartTime, ATimeOut: Cardinal): Boolean;
begin
  Result := IsTimeoutEx(AStartTime, ATimeOut);
end;

class function TACLThread.IsTimeoutEx(var ATimestamp: Cardinal; ATimeOut: Cardinal): Boolean;
var
  LNow: Cardinal;
begin
  if (ATimeOut = 0) or (ATimeOut = INFINITE) then
    Exit(False);

  LNow := Timestamp;
  if LNow < ATimestamp then
    Result := High(Cardinal) - ATimestamp + LNow >= ATimeOut
  else
    Result := LNow - ATimestamp >= Cardinal(ATimeOut);

  if Result then
    ATimestamp := LNow;
end;

{$IF DEFINED(ACL_THREADING_DEBUG) AND DEFINED(MSWINDOWS)}
class procedure TACLThread.NameThreadForDebugging(const AName: string);
var
  LHandle: THandle;
begin
  if Assigned(FSetThreadDescription) then
  begin
    LHandle := OpenThread(THREAD_SET_LIMITED_INFORMATION, False, GetCurrentThreadId);
    if LHandle <> 0 then
    try
      FSetThreadDescription(LHandle, PChar(AName));
    finally
      CloseHandle(LHandle);
    end;
  end;
  TThread.NameThreadForDebugging(AName);
end;
{$ENDIF}

procedure TACLThread.Synchronize(AProc: TThreadMethod);
begin
  RunInMainThread(AProc);
end;

procedure TACLThread.Synchronize(AProc: TProc);
begin
  RunInMainThread(AProc);
end;

class function TACLThread.Timestamp: Cardinal;
begin
  Result := GetTickCount{%H-};
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
  KillThread(Handle);
  DoTerminate;
{$ENDIF}
end;

{$IFDEF ACL_THREADING_DEBUG_DEADLOCKS}
function TACLThread.WaitFor: LongWord;
begin
  TACLMainThread.CheckForDeadlock(Handle);
  Result := inherited WaitFor;
end;
{$ENDIF}

function TACLThread._AddRef: Integer;
begin
  Result := -1;
end;

function TACLThread._Release: Integer;
begin
  Result := -1;
end;

function TACLThread.QueryInterface;
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
  inherited;
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

procedure TACLPauseableThread.Terminate;
begin
  SetPaused(False);
  inherited;
end;

{ TACLMultithreadedOperation }

class constructor TACLMultithreadedOperation.Create;
begin
  FLock := TACLCriticalSection.Create;
end;

class destructor TACLMultithreadedOperation.Destroy;
begin
  FreeAndNil(FLockEvent);
  FreeAndNil(FLock);
end;

class procedure TACLMultithreadedOperation.Run(
  AChunks: PPointer; AChunkCount: Integer; AFilterProc: TFilterProc);
begin
  if AChunkCount > 0 then
  begin
    FLock.Enter;
    try
      if FLockEvent = nil then
        FLockEvent := TACLEvent.Create;

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
{$IFDEF LINUX}
  // Messaging works only in main app, not plugins.
  if not IsLibrary then
{$ENDIF}
  begin
    FWnd := acWndAlloc(WndProc, ClassName, True);
  {$IFDEF MSWINDOWS}
    FWndMessage := RegisterWindowMessage(PChar(ClassName));
  {$ELSE}
    FWndMessage := WM_USER;
  {$ENDIF}
  end;
  FQueue := TThreadList<PSynchronizeRecord>.Create;
{$IFDEF ACL_THREADING_DEBUG_DEADLOCKS}
  FSynchronizingThreads := TThreadList<Cardinal>.Create;
{$ENDIF}
end;

class destructor TACLMainThread.Destroy;
begin
  acWndFree(FWnd);
  TACLThread.RemoveQueuedEvents(Execute);
  with FQueue.LockList do
  try
  {$IFDEF DEBUG}
    if Count > 0 then
      raise EInvalidOperation.Create(ClassName);
  {$ENDIF}
    while Count > 0 do
    begin
      Dispose(List[0]);
      Delete(0);
    end;
  finally
    FQueue.UnlockList;
  end;
{$IFDEF ACL_THREADING_DEBUG_DEADLOCKS}
  FreeAndNil(FSynchronizingThreads);
{$ENDIF}
  FreeAndNil(FQueue);
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

class procedure TACLMainThread.CheckForDeadlock(AWaitedThreadId: TThreadId);
begin
{$IFDEF ACL_THREADING_DEBUG_DEADLOCKS}
  if not IsMainThread then
    Exit; // not yet supported
  with FSynchronizingThreads.LockList do
  try
    if Contains(MainThreadId) and Contains(AWaitedThreadId) then
      raise EACLDeadlockException.Create(MainThreadID, AWaitedThreadId);
  finally
    FSynchronizingThreads.UnlockList;
  end;
{$ENDIF}
end;

class procedure TACLMainThread.CheckSynchronize;
begin
  if not IsMainThread then
    raise EInvalidArgument.Create(ClassName);
  Classes.CheckSynchronize;
  Execute;
end;

class procedure TACLMainThread.Execute;
var
  LRec: PSynchronizeRecord;
begin
  repeat
    with FQueue.LockList do
    try
      if Count > 0 then
        LRec := ExtractAt(0)
      else
        Exit;
    finally
      FQueue.UnlockList;
    end;
    Execute(LRec);
  until False;
end;

class procedure TACLMainThread.Execute(ARecord: PSynchronizeRecord);
begin
  try
    if ARecord <> nil then
    try
      if Assigned(ARecord^.Method) then
        ARecord^.Method();
      if Assigned(ARecord^.Proc) then
        ARecord^.Proc();
    finally
      Dispose(ARecord);
    end;
  except
    on E: EACLDeadlockException do
      raise;
    on E: Exception do
    {$IFNDEF FPC}
      LogError(acGeneralLogFileName, 'App', E, ClassName);
    {$ENDIF}
  end;
end;

class procedure TACLMainThread.Run(AProc: TProc; AWaitFor: Boolean; AReceiver: Pointer);
begin
  Run(Allocate(AReceiver, AProc), AWaitFor);
end;

class procedure TACLMainThread.Run(AProc: TThreadMethod; AWaitFor: Boolean; AReceiver: Pointer);
begin
  Run(Allocate(AReceiver, AProc), AWaitFor);
end;

class procedure TACLMainThread.Run(ARecord: PSynchronizeRecord; AWaitFor: Boolean);
var
  LCurrentThreadId: TThreadId;
begin
  if ARecord = nil then
    Exit;
  if AWaitFor then
  begin
    LCurrentThreadId := GetCurrentThreadId;
    if LCurrentThreadId = MainThreadID then
      Execute(ARecord)
    else
    {$IFDEF MSWINDOWS} // Only Windows switches the context to the main thread when sending a message.
      if FWnd <> 0 then
        acSendMessage(FWnd, FWndMessage, 0, {%H-}LPARAM(ARecord))
      else
    {$ENDIF}
      begin
      {$IFDEF ACL_THREADING_DEBUG_DEADLOCKS}
        FSynchronizingThreads.Add(LCurrentThreadId);
        try
      {$ENDIF}
          TACLThread.Synchronize(nil,
            procedure
            begin
              Execute(ARecord);
            end);
      {$IFDEF ACL_THREADING_DEBUG_DEADLOCKS}
        finally
          FSynchronizingThreads.Remove(LCurrentThreadId);
        end;
      {$ENDIF}
      end;
  end
  else
  begin
    FQueue.Add(ARecord);
    // Unlike the WaitFor condition, here we prefer for system's postpone mechanism. 
    // This way, we can avoid deadlocks between postponed methods and UI synchronization from other threads
    if FWnd <> 0 then    
      acPostMessage(FWnd, FWndMessage, 0, 0)
    else
    {$IFDEF ACL_THREADING_DEBUG_DEADLOCKS}
      TACLThread.ForceQueue(nil, procedure
      begin
        FSynchronizingThreads.Add(MainThreadID);
        try
          Execute;
        finally
          FSynchronizingThreads.Remove(MainThreadID);
        end;
      end);
    {$ELSE}
      TACLThread.ForceQueue(nil, Execute);
    {$ENDIF}
  end;
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
  LRec: PSynchronizeRecord;
  I: Integer;
begin
  with FQueue.LockList do
  try
    for I := Count - 1 downto 0 do
    begin
      LRec := {$IFDEF FPC}Items{$ELSE}List{$ENDIF}[I];
      if @LRec.Method = @AProc then
      begin
        Dispose(LRec);
        Delete(I);
      end;
    end;
  finally
    FQueue.UnlockList;
  end;
end;

class procedure TACLMainThread.Unsubscribe(AReceiver: Pointer);
var
  LRec: PSynchronizeRecord;
  I: Integer;
begin
  with FQueue.LockList do
  try
    for I := Count - 1 downto 0 do
    begin
      LRec := {$IFDEF FPC}Items{$ELSE}List{$ENDIF}[I];
      if LRec.Receiver = AReceiver then
      begin
        Dispose(LRec);
        Delete(I);
      end;
    end;
  finally
    FQueue.UnlockList;
  end;
end;

class procedure TACLMainThread.Wake;
begin
  // Wake main message loop
{$IF DEFINED(LCLGtkX)}
  g_main_context_wakeup(g_main_context_default);
{$ENDIF}
  // Wake main thread
  if Assigned(WakeMainThread) then
    WakeMainThread(nil);
end;

class procedure TACLMainThread.WndProc(var AMessage: TMessage);
begin
  if AMessage.Msg = FWndMessage then
  try
    if AMessage.LParam <> 0 then
      Execute({%H-}PSynchronizeRecord(AMessage.LParam))
    else
      Execute;
  except
    //if Assigned(ApplicationHandleException) then
    //  ApplicationHandleException(nil);
  end
  else
    acWndDefaultProc(FWnd, AMessage);
end;

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
  // Linux: main thread name will be displayed in the Top utility output
{$IF DEFINED(MSWINDOWS) AND DEFINED(ACL_THREADING_DEBUG)}
  TACLThread.NameThreadForDebugging('Main');
  FGetThreadDescription := GetProcAddress(GetModuleHandle(kernel32), 'GetThreadDescription');
  FSetThreadDescription := GetProcAddress(GetModuleHandle(kernel32), 'SetThreadDescription');
{$ENDIF}
end.
