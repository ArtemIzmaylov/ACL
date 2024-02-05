{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*    Standard and High-Resolution Timers    *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Timers;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
  LMessages,
  Messages,
{$ELSE}
  Winapi.Messages,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  // ACL
  ACL.Classes.Collections;

{$IFDEF FPC}
const
  WM_TIMER = LM_TIMER;
{$ENDIF}

type

  { TACLTimer }

  TACLTimer = class(TComponent)
  public const
    DefaultInterval = 1000;
  strict private
    FEnabled: Boolean;
    FHighResolution: Boolean;
    FInterval: Cardinal;

    FOnTimer: TNotifyEvent;

    procedure SetEnabled(Value: Boolean);
    procedure SetInterval(Value: Cardinal);
    procedure SetHighResolution(Value: Boolean);
    procedure SetOnTimer(Value: TNotifyEvent);
    procedure UpdateTimer;
  private
    FHighResolutionCounter: Int64;
  protected
    function CanSetTimer: Boolean; virtual;
    procedure Timer; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateEx(ATimerEvent: TNotifyEvent; AInterval: Cardinal = DefaultInterval;
      AEnabled: Boolean = False; AHighResolution: Boolean = False);
    procedure BeforeDestruction; override;
    procedure Restart;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Interval: Cardinal read FInterval write SetInterval default DefaultInterval;
    property HighResolution: Boolean read FHighResolution write SetHighResolution default False;
    property OnTimer: TNotifyEvent read FOnTimer write SetOnTimer;
  end;

  { TACLTimerList }

  TACLTimerList<T> = class(TACLTimer)
  strict private
    procedure CheckState;
  protected
    FList: TACLList<T>;

    procedure DoAdding(const AObject: T); virtual;
    procedure DoRemoving(const AObject: T); virtual;

    function CanSetTimer: Boolean; override;
    procedure Timer; override;
    procedure TimerObject(const AObject: T); virtual; abstract;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure Add(const AObject: T);
    function Contains(const AObject: T): Boolean;
    procedure Remove(const AObject: T);
  end;

function GetExactTickCount: Int64;
function TickCountToTime(const ATicks: Int64): Cardinal;
function TimeToTickCount(const ATime: Cardinal): Int64;
implementation

uses
  ACL.Classes,
  ACL.Threading,
  ACL.Utils.Common,
  ACL.Utils.Messaging;

type

  { TACLTimerManager }

  TACLTimerManager = class
  strict private
    FLock: TACLCriticalSection;
  {$IFDEF MSWINDOWS}
    FSystemTimerResolution: Integer;
  {$ENDIF}

    function AlignToSystemTimerResolution(AInterval: Cardinal): Cardinal;
    function GetSystemTimerResolution: Integer;
    procedure HandleMessage(var AMessage: TMessage);
    procedure SafeCallTimerProc(ATimer: TACLTimer); inline;
    procedure SafeUpdateHighResolutionThread;
  protected
    FHandle: HWND;
    FHighResolutionThread: TACLPauseableThread;
    FHighResolutionTimers: TACLThreadList<TACLTimer>;
    FTimers: TACLList<TACLTimer>;

    procedure SafeCallTimerProcs(AList: TList);
    property SystemTimerResolution: Integer read GetSystemTimerResolution;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterTimer(ATimer: TACLTimer);
    procedure UnregisterTimer(ATimer: TACLTimer);
  end;

  { TACLTimerManagerHighResolutionThread }

  TACLTimerManagerHighResolutionThread = class(TACLPauseableThread)
  strict private
    FOwner: TACLTimerManager;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TACLTimerManager);
  end;

var
  FTimerManager: TACLTimerManager;

{$IFDEF MSWINDOWS}
var
  FPerformanceCounterFrequency: Int64 = 0;

function NtQueryTimerResolution(out Maximum, Minimum, Actual: ULONG): ULONG32; stdcall; external 'ntdll.dll';
{$ENDIF}

function GetExactTickCount: Int64;
begin
{$IFDEF MSWINDOWS}
  //# https://docs.microsoft.com/ru-ru/windows/win32/api/profileapi/nf-profileapi-queryperformancecounter?redirectedfrom=MSDN
  //# On systems that run Windows XP or later, the function will always succeed and will thus never return zero.
  if not QueryPerformanceCounter(Result) then
    Result := GetTickCount;
{$ELSE}
  Result := GetTickCount64; // in milliseconds
{$ENDIF}
end;

function TickCountToTime(const ATicks: Int64): Cardinal;
begin
{$IFDEF MSWINDOWS}
  if FPerformanceCounterFrequency = 0 then
    QueryPerformanceFrequency(FPerformanceCounterFrequency);
  Result := (ATicks * 1000) div FPerformanceCounterFrequency;
{$ELSE}
  Result := ATicks;
{$ENDIF}
end;

function TimeToTickCount(const ATime: Cardinal): Int64;
begin
{$IFDEF MSWINDOWS}
  if FPerformanceCounterFrequency = 0 then
    QueryPerformanceFrequency(FPerformanceCounterFrequency);
  Result := (Int64(ATime) * FPerformanceCounterFrequency) div 1000;
{$ELSE}
  Result := ATime;
{$ENDIF}
end;

{ TACLTimer }

constructor TACLTimer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInterval := DefaultInterval;
  FEnabled := True;
end;

constructor TACLTimer.CreateEx(ATimerEvent: TNotifyEvent;
  AInterval: Cardinal = DefaultInterval;
  AEnabled: Boolean = False; AHighResolution: Boolean = False);
begin
  Create(nil);
  HighResolution := AHighResolution;
  Interval := AInterval;
  Enabled := AEnabled;
  OnTimer := ATimerEvent;
end;

procedure TACLTimer.BeforeDestruction;
begin
  inherited BeforeDestruction;
  Enabled := False;
end;

procedure TACLTimer.Restart;
begin
  Enabled := False;
  Enabled := True;
end;

function TACLTimer.CanSetTimer: Boolean;
begin
  Result := (Interval > 0) and Enabled and Assigned(OnTimer);
end;

procedure TACLTimer.Timer;
begin
  CallNotifyEvent(Self, OnTimer);
end;

procedure TACLTimer.SetEnabled(Value: Boolean);
begin
  if Value <> FEnabled then
  begin
    FEnabled := Value;
    UpdateTimer;
  end;
end;

procedure TACLTimer.SetInterval(Value: Cardinal);
begin
  Value := Max(Value, 1);
  if Value <> FInterval then
  begin
    FInterval := Value;
    UpdateTimer;
  end;
end;

procedure TACLTimer.SetHighResolution(Value: Boolean);
begin
  if FHighResolution <> Value then
  begin
    FHighResolution := Value;
    UpdateTimer;
  end;
end;

procedure TACLTimer.SetOnTimer(Value: TNotifyEvent);
begin
  FOnTimer := Value;
  UpdateTimer;
end;

procedure TACLTimer.UpdateTimer;
begin
  if FTimerManager <> nil then
  begin
    FTimerManager.UnregisterTimer(Self);
    if CanSetTimer then
      FTimerManager.RegisterTimer(Self);
  end;
end;

{ TACLTimerList }

constructor TACLTimerList<T>.Create;
begin
  inherited Create(nil);
  FList := TACLList<T>.Create;
end;

destructor TACLTimerList<T>.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TACLTimerList<T>.Add(const AObject: T);
begin
  if FList.IndexOf(AObject) < 0 then
  begin
    DoAdding(AObject);
    FList.Add(AObject);
    CheckState;
  end;
end;

function TACLTimerList<T>.Contains(const AObject: T): Boolean;
begin
  Result := FList.Contains(AObject);
end;

procedure TACLTimerList<T>.Remove(const AObject: T);
var
  AIndex: Integer;
begin
  AIndex := FList.IndexOf(AObject);
  if AIndex >= 0 then
  begin
    DoRemoving(AObject);
    FList.Delete(AIndex);
    CheckState;
  end;
end;

procedure TACLTimerList<T>.DoAdding(const AObject: T);
begin
  // do nothing
end;

procedure TACLTimerList<T>.DoRemoving(const AObject: T);
begin
  // do nothing
end;

function TACLTimerList<T>.CanSetTimer: Boolean;
begin
  Result := Enabled and (Interval > 0);
end;

procedure TACLTimerList<T>.Timer;
var
  I: Integer;
begin
  for I := FList.Count - 1 downto 0 do
    TimerObject(FList.List[I]);
end;

procedure TACLTimerList<T>.CheckState;
begin
  Enabled := FList.Count > 0;
end;

{ TACLTimerManager }

constructor TACLTimerManager.Create;
begin
  FLock := TACLCriticalSection.Create;
  FTimers := TACLList<TACLTimer>.Create;
  FHandle := WndCreate(HandleMessage, ClassName, True);
  FHighResolutionTimers := TACLThreadList<TACLTimer>.Create;
end;

destructor TACLTimerManager.Destroy;
begin
  WndFree(FHandle);
  FreeAndNil(FHighResolutionThread);
  FreeAndNil(FHighResolutionTimers);
  FreeAndNil(FTimers);
  FreeAndNil(FLock);
  inherited Destroy;
end;

procedure TACLTimerManager.RegisterTimer(ATimer: TACLTimer);
begin
  FLock.Enter;
  try;
    FTimers.Add(ATimer);
    if ATimer.HighResolution and (ATimer.Interval < 1000) then
    begin
      FHighResolutionTimers.Add(ATimer);
      SafeUpdateHighResolutionThread;
    end
    else
      SetTimer(FHandle, NativeUInt(ATimer), AlignToSystemTimerResolution(ATimer.Interval), nil);
  finally
    FLock.Leave;
  end;
end;

procedure TACLTimerManager.UnregisterTimer(ATimer: TACLTimer);
begin
  FLock.Enter;
  try
    if FTimers.Remove(ATimer) >= 0 then
      KillTimer(FHandle, NativeUInt(ATimer));

    with FHighResolutionTimers.LockList do
    try
      if Remove(ATimer) >= 0 then
        SafeUpdateHighResolutionThread;
    finally
      FHighResolutionTimers.UnlockList;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TACLTimerManager.HandleMessage(var AMessage: TMessage);
begin
  if AMessage.Msg = WM_TIMER then
    SafeCallTimerProc(TACLTimer(AMessage.WParam))
  else if AMessage.Msg = WM_USER then
    SafeCallTimerProcs(TList(AMessage.LParam))
  else
    WndDefaultProc(FHandle, AMessage);
end;

function TACLTimerManager.AlignToSystemTimerResolution(AInterval: Cardinal): Cardinal;
begin
  // The resolution of the GetTickCount function is limited to the resolution of the system timer,
  // which is typically in the range of 10 milliseconds to 16 milliseconds
  Result := Max(1, Round(AInterval / 10)) * 10;

//#AI: Animation works too slow (in comparing with AIMP4)
//  Result := Max(1, Round(AInterval / SystemTimerResolution)) * SystemTimerResolution;
end;

function TACLTimerManager.GetSystemTimerResolution: Integer;
{$IFDEF MSWINDOWS}
var
  LActual, LMax, LMin: ULONG;
begin
  if FSystemTimerResolution = 0 then
  begin
    if NtQueryTimerResolution(LMax, LMin, LActual) = 0 then
      FSystemTimerResolution := Round(LActual / 1000);
    FSystemTimerResolution := Max(FSystemTimerResolution, 1);
  end;
  Result := FSystemTimerResolution;
end;
{$ELSE}
begin
  Result := 1; // todo - check it
end;
{$ENDIF}

procedure TACLTimerManager.SafeCallTimerProc(ATimer: TACLTimer);
begin
//  TMonitor.Enter(Self);
//  try
  if FTimers.Contains(ATimer) then
    ATimer.Timer;
//  finally
//    TMonitor.Exit(Self);
//  end;
end;

procedure TACLTimerManager.SafeUpdateHighResolutionThread;
var
  AList: TACLList<TACLTimer>;
begin
  AList := FHighResolutionTimers.LockList;
  try
    if AList.Count = 0 then
    begin
      if FHighResolutionThread <> nil then
        FHighResolutionThread.SetPaused(True);
    end
    else
    begin
      if FHighResolutionThread = nil then
        FHighResolutionThread := TACLTimerManagerHighResolutionThread.Create(Self);
      FHighResolutionThread.SetPaused(False);
    end;
  finally
    FHighResolutionTimers.UnlockList;
  end;
end;

procedure TACLTimerManager.SafeCallTimerProcs(AList: TList);
var
  I: Integer;
begin
  for I := 0 to AList.Count - 1 do
    SafeCallTimerProc(AList.List[I]);
end;

{ TACLTimerManagerHighResolutionThread }

constructor TACLTimerManagerHighResolutionThread.Create(AOwner: TACLTimerManager);
begin
  inherited Create(False);
  FOwner := AOwner;
end;

procedure TACLTimerManagerHighResolutionThread.Execute;
var
  AList: TACLList<TACLTimer>;
  ANextTick: Int64;
  ASleepTime: Integer;
  ATicked: TList;
  ATicks: Int64;
  ATimer: TACLTimer;
  I: Integer;
begin
  NameThreadForDebugging('HighResolutionTimer');

  ATicked := TList.Create;
  try
    while not Terminated do
    begin
      ATicked.Count := 0;
      ATicks := GetExactTickCount;

      AList := FOwner.FHighResolutionTimers.LockList;
      try
        ANextTick := ATicks + TimeToTickCount(1000);
        for I := 0 to AList.Count - 1 do
        begin
          ATimer := AList.List[I];
          if ATimer.FHighResolutionCounter <= ATicks then
          begin
            ATimer.FHighResolutionCounter := ATicks + TimeToTickCount(ATimer.Interval);
            ATicked.Add(ATimer);
          end;
          ANextTick := Min(ANextTick, ATimer.FHighResolutionCounter);
        end;
      finally
        FOwner.FHighResolutionTimers.UnlockList;
      end;

      if ATicked.Count > 0 then
      begin
      {$IFDEF FPC}
        Synchronize(procedure begin FOwner.SafeCallTimerProcs(ATicked); end);
      {$ELSE}
        SendMessage(FOwner.FHandle, WM_USER, 0, LPARAM(ATicked));
      {$ENDIF}
        ATicks := GetExactTickCount;
      end;

      ASleepTime := TickCountToTime(ANextTick - ATicks);
      ASleepTime := Max(ASleepTime, 1); //#AI: always call sleep to take main thread some time to process message queue
      if ASleepTime > 0 then
        Sleep(ASleepTime);
      WaitForUnpause;
    end;
  finally
    ATicked.Free;
  end;
end;

initialization
  FTimerManager := TACLTimerManager.Create;

finalization
  FreeAndNil(FTimerManager);
end.
