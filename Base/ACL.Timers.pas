////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Timers
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Timers;

{$I ACL.Config.inc}

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
  {System.}Generics.Collections,
  {System.}Generics.Defaults,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Threading,
  ACL.Utils.Common,
  ACL.Utils.Messaging;

{$IFDEF FPC}
const
  WM_NULL  = LM_NULL;
  WM_TIMER = LM_TIMER;
type
  TWMTimer = TLMTimer;
{$ENDIF}

type

  { TACLTimer }

  TACLTimerClass = class of TACLTimer;
  TACLTimer = class(TComponent)
  public const
    DefaultInterval = 1000;
  private
    FCounter: Int64;
    FId: NativeUInt;
    FTicked: Boolean;
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
  protected
    function CanSetTimer: Boolean; virtual;
    procedure Timer; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateEx(AEvent: TNotifyEvent; AInterval: Cardinal = DefaultInterval);
    procedure BeforeDestruction; override;
    procedure Restart; overload;
    procedure Restart(AInterval: Cardinal); overload;
    function Start: TACLTimer;
    procedure Stop;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Interval: Cardinal read FInterval write SetInterval default DefaultInterval;
    property HighResolution: Boolean read FHighResolution write SetHighResolution default False;
    // Events
    property OnTimer: TNotifyEvent read FOnTimer write SetOnTimer;
  end;

  { TACLTimerList }

  TACLTimerListOf<T> = class(TACLTimer)
  protected
    FList: TACLListOf<T>;
    function CanAdd(const AObject: T): Boolean; virtual;
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

  { TACLTimerManager }

  TACLTimerManager = class
  strict private
    class var FHighResolutionThread: TACLPauseableThread;
    class var FLock: TACLCriticalSection;
    class var FPerformanceCounterFrequency: Int64;
    class var FTimers: TList;
    class var FTimerWnd: TWndHandle;

    class procedure TimerProc(Handle: TWndHandle;
      Message: UINT; ID: UINT_PTR; Ticks: Cardinal); stdcall; static;
    class procedure WndProc(var Message: TMessage);
  private
    class var FHandle: TWndHandle;
    class var FHighResolutionTimers: TThreadList;
    class procedure ExecuteTickedTimers(AClass: TACLTimerClass = nil);
    class function Tick(AList: TList; ATime: Int64;
      var ATicked: Boolean; AClass: TACLTimerClass = nil): Int64; static;
    class procedure Register(ATimer: TACLTimer);
    class procedure Unregister(ATimer: TACLTimer);
  public
    class constructor Create;
    class destructor Destroy;
    class function ExactTickCount: Int64; // in milliseconds
    class procedure ForceUpdate(ATimer: TACLTimer); overload;
    class procedure ForceUpdate(ATimerClass: TACLTimerClass); overload;
  end;

implementation

type

  { TACLTimerManagerHighResolutionThread }

  TACLTimerManagerHighResolutionThread = class(TACLPauseableThread)
  protected
    procedure Execute; override;
  end;

{ TACLTimer }

constructor TACLTimer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInterval := DefaultInterval;
  FEnabled := True;
end;

constructor TACLTimer.CreateEx(AEvent: TNotifyEvent; AInterval: Cardinal);
begin
  Create(nil);
  FEnabled := False;
  FInterval := AInterval;
  FOnTimer := AEvent;
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

procedure TACLTimer.Restart(AInterval: Cardinal);
begin
  Enabled := False;
  Interval := AInterval;
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
  if HighResolution <> Value then
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

function TACLTimer.Start: TACLTimer;
begin
  Enabled := True;
  Result := Self;
end;

procedure TACLTimer.Stop;
begin
  Enabled := False;
end;

procedure TACLTimer.UpdateTimer;
begin
  TACLTimerManager.Unregister(Self);
  if CanSetTimer then
    TACLTimerManager.Register(Self);
end;

{ TACLTimerList }

constructor TACLTimerListOf<T>.Create;
begin
  inherited Create(nil);
  FList := TACLListOf<T>.Create;
end;

destructor TACLTimerListOf<T>.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TACLTimerListOf<T>.Add(const AObject: T);
begin
  if FList.IndexOf(AObject) < 0 then
  begin
    if CanAdd(AObject) then
    begin
      FList.Add(AObject);
      Start;
    end;
  end;
end;

function TACLTimerListOf<T>.CanAdd(const AObject: T): Boolean;
begin
  Result := True;
end;

function TACLTimerListOf<T>.CanSetTimer: Boolean;
begin
  Result := Enabled and (Interval > 0);
end;

function TACLTimerListOf<T>.Contains(const AObject: T): Boolean;
begin
  Result := FList.Contains(AObject);
end;

procedure TACLTimerListOf<T>.Remove(const AObject: T);
var
  LIndex: Integer;
begin
  LIndex := FList.IndexOf(AObject);
  if LIndex >= 0 then
  begin
    FList.Delete(LIndex);
    if FList.Count = 0 then Stop;
  end;
end;

procedure TACLTimerListOf<T>.Timer;
var
  I: Integer;
begin
  for I := FList.Count - 1 downto 0 do
    TimerObject(FList.List[I]);
end;

{ TACLTimerManager }

class constructor TACLTimerManager.Create;
begin
  FTimers := TList.Create;
  FLock := TACLCriticalSection.Create;
  FHighResolutionTimers := TThreadList.Create;
  FHandle := acWndAlloc(WndProc, ClassName, True);
  FPerformanceCounterFrequency := 0;
  // #AI: 11.12.2025
  // Windows плохо себя чувствует при работе с глобальными таймерами из потоков.
  // Запуск таймера из потока приводит к тому, что TimerProc просто не вызывается
  // У нас это вылезало на WASAPI в TASOPlayer.DeviceArrival.
  FTimerWnd := {$IFDEF MSWINDOWS}FHandle{$ELSE}0{$ENDIF};
end;

class destructor TACLTimerManager.Destroy;
begin
  acWndFree(FHandle);
  FreeAndNil(FHighResolutionThread);
  FreeAndNil(FHighResolutionTimers);
  FreeAndNil(FTimers);
  FreeAndNil(FLock);
end;

class function TACLTimerManager.ExactTickCount: Int64;
begin
{$IFDEF MSWINDOWS}
  if FPerformanceCounterFrequency = 0 then
  begin
    if not QueryPerformanceFrequency(FPerformanceCounterFrequency) then
      FPerformanceCounterFrequency := -1;
  end;
  //# https://docs.microsoft.com/ru-ru/windows/win32/api/profileapi/nf-profileapi-queryperformancecounter?redirectedfrom=MSDN
  //# On systems that run Windows XP or later, the function will always succeed and will thus never return zero.
  if (FPerformanceCounterFrequency > 0) and QueryPerformanceCounter(Result) then
    Result := (Result * 1000) div FPerformanceCounterFrequency
  else
    Result := GetTickCount;
{$ELSE}
  Result := GetTickCount64; // in milliseconds
{$ENDIF}
end;

class procedure TACLTimerManager.ForceUpdate(ATimer: TACLTimer);
begin
  TimerProc(0, 0, ATimer.FId, TACLThread.Timestamp);
end;

class procedure TACLTimerManager.ForceUpdate(ATimerClass: TACLTimerClass);
var
  LTicked: Boolean;
begin
  FLock.Enter;
  try
    LTicked := False;
    Tick(FTimers, ExactTickCount, LTicked, ATimerClass);
    if LTicked then
      ExecuteTickedTimers(ATimerClass);
  finally
    FLock.Leave;
  end;
end;

class procedure TACLTimerManager.ExecuteTickedTimers(AClass: TACLTimerClass);
var
  I: Integer;
  LTimer: TACLTimer;
begin
  if FTimers = nil then Exit;
  FLock.Enter;
  try
    for I := 0 to FTimers.Count - 1 do
    begin
      LTimer := FTimers.List[I];
      if LTimer.FTicked and ((AClass = nil) or LTimer.InheritsFrom(AClass)) then
      begin
        LTimer.FTicked := False;
        LTimer.Timer;
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

class function TACLTimerManager.Tick(AList: TList;
  ATime: Int64; var ATicked: Boolean; AClass: TACLTimerClass = nil): Int64;
var
  I: Integer;
  LTimer: TACLTimer;
begin
  Result := ATime + TACLTimer.DefaultInterval;
  for I := 0 to AList.Count - 1 do
  begin
    LTimer := AList.List[I];
    if (AClass = nil) or LTimer.InheritsFrom(AClass) then
    begin
      if LTimer.FCounter <= ATime then
      begin
        ATicked := ATicked or not LTimer.FTicked;
        LTimer.FCounter := ATime + LTimer.Interval;
        LTimer.FTicked := True;
      end;
      Result := Min(Result, LTimer.FCounter);
    end;
  end;
end;

class procedure TACLTimerManager.TimerProc(
  Handle: TWndHandle; Message: UINT; ID: UINT_PTR; Ticks: Cardinal); stdcall;
var
  LTimer: TACLTimer;
  I: Integer;
begin
  if FTimers = nil then Exit;
  FLock.Enter;
  try
    for I := FTimers.Count - 1 downto 0 do
    begin
      LTimer := FTimers.List[I];
      if LTimer.fId = ID then
      begin
        LTimer.FCounter := Ticks + LTimer.Interval;
        LTimer.FTicked := False;
        LTimer.Timer;
        Exit;
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

class procedure TACLTimerManager.Register(ATimer: TACLTimer);
var
  LElapse: Integer;
  LList: TList;
begin
  FLock.Enter;
  try;
    FTimers.Add(ATimer);
    if ATimer.HighResolution and (ATimer.Interval < 1000) then
    begin
      LList := FHighResolutionTimers.LockList;
      try
        LList.Add(ATimer);
        if FHighResolutionThread = nil then
          FHighResolutionThread := TACLTimerManagerHighResolutionThread.Create(False);
        FHighResolutionThread.SetPaused(False);
      finally
        FHighResolutionTimers.UnlockList;
      end;
    end
    else
    begin
      // The resolution of the GetTickCount function is limited to the resolution of the system timer,
      // which is typically in the range of 10 milliseconds to 16 milliseconds
      //#AI: Animation works too slow (in comparing with AIMP4)
      //  LElapse := Max(1, Round(AInterval / SystemTimerResolution)) * SystemTimerResolution;
      LElapse := Max(1, Round(ATimer.Interval / 10)) * 10;
      if FTimerWnd <> 0 then
      begin
        ATimer.fId := NativeUInt(ATimer);
        SetTimer(FTimerWnd, ATimer.FId, LElapse, nil);
      end
      else
        ATimer.fId := SetTimer(0, 0, LElapse, @TimerProc);
    end;
  finally
    FLock.Leave;
  end;
end;

class procedure TACLTimerManager.Unregister(ATimer: TACLTimer);
var
  LList: TList;
begin
  FLock.Enter;
  try
    if FTimers.Remove(ATimer) >= 0 then
      KillTimer(FTimerWnd, ATimer.FId);

    LList := FHighResolutionTimers.LockList;
    try
      if (LList.Remove(ATimer) >= 0) and (LList.Count = 0) then
      begin
        if FHighResolutionThread <> nil then
          FHighResolutionThread.SetPaused(True);
      end;
    finally
      FHighResolutionTimers.UnlockList;
    end;

    ATimer.FCounter := 0;
    ATimer.FId := 0;
  finally
    FLock.Leave;
  end;
end;

class procedure TACLTimerManager.WndProc(var Message: TMessage);
begin
  try
    if Message.Msg = WM_NULL then
      ExecuteTickedTimers
    else if Message.Msg = WM_TIMER then
      TimerProc(FHandle, WM_TIMER, Message.WParam, TACLThread.Timestamp)
    else
      acWndDefaultProc(FHandle, Message);
  except
    // do nothing
  end;
end;

{ TACLTimerManagerHighResolutionThread }

procedure TACLTimerManagerHighResolutionThread.Execute;
var
  LCurrTick: Int64;
  LNextTick: Int64;
  LTicked: Boolean;
  LTimers: TList;
begin
{$IFDEF ACL_THREADING_DEBUG}
  NameThreadForDebugging('HighResolutionTimers');
{$ENDIF}

  while not Terminated do
  begin
    LTicked := False;

    LTimers := TACLTimerManager.FHighResolutionTimers.LockList;
    try
      LCurrTick := TACLTimerManager.ExactTickCount;
      LNextTick := TACLTimerManager.Tick(LTimers, LCurrTick, LTicked);
    finally
      TACLTimerManager.FHighResolutionTimers.UnlockList;
    end;

    if LTicked then
    begin
      //#AI: 08.12.2025
      // В Linux все таймеры обрабатываем исключительно на OnIdle (как в Windows),
      // Иначе на тяжелых анимациях скин-движка случается так, что вся очередь событий
      // забивается таймерами и перерисовкой UI. Простой пример:
      // Timer (interval 20) -> PaintBox.Invalidate -> PaintBox.OnPaint { sleep(50) }
      // После такого отваливаются экшены, popup и modal loop-ы, а всё потому, что
      // до idle дело просто не доходит.
    {$IFDEF LINUX}
      if not IsLibrary then
        PostMessage(TACLTimerManager.FHandle, WM_NULL, 0, 0)
      else
    {$ENDIF}
      begin
      {$IFDEF MSWINDOWS}
        SendMessage(TACLTimerManager.FHandle, WM_NULL, 0, 0);
      {$ELSE}
        Synchronize(procedure begin TACLTimerManager.ExecuteTickedTimers; end);
      {$ENDIF}
        // Переключение потоков можен занять существенное время,
        // посему после актуализируем временную метку
        LCurrTick := TACLTimerManager.ExactTickCount;
      end;
    end;

    //#AI: always call sleep to take main thread some time to process message queue
    Sleep(EnsureRange(LNextTick - LCurrTick, 1, 1000));

    WaitForUnpause;
  end;
end;

end.
