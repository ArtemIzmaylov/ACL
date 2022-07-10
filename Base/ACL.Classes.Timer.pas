{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*    Standard and High-Resolution Timers    *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Classes.Timer;

{$I ACL.Config.inc}

interface

uses
  Windows, Classes, Messages, ACL.Classes.Collections;

type

  { TACLTimer }

  TACLTimer = class(TComponent)
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
    constructor CreateEx(ATimerEvent: TNotifyEvent; AInterval: Cardinal = 1000;
      AEnabled: Boolean = False; AHighResolution: Boolean = False);
    procedure BeforeDestruction; override;
    procedure Restart;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Interval: Cardinal read FInterval write SetInterval default 1000;
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

implementation

uses
  Math, SysUtils,
  // ACL
  ACL.Classes,
  ACL.Classes.MessageWindow,
  ACL.Classes.StringList,
  ACL.Math,
  ACL.Threading,
  ACL.Utils.Common;

type
  NTSTATUS = type ULONG32;

  TACLTimerManagerHighResolutionThread = class;

  { TACLTimerManager }

  TACLTimerManager = class(TACLCustomMessageWindow)
  strict private
    FSystemTimerResolution: Integer;

    function AlignToSystemTimerResolution(AInterval: Cardinal): Cardinal;
    function GetSystemTimerResolution: Integer;
    procedure SafeCallTimerProc(ATimer: TACLTimer); inline;
    procedure SafeUpdateHighResolutionThread;
  protected
    FHighResolutionThread: TACLTimerManagerHighResolutionThread;
    FHighResolutionTimers: TACLThreadList<TACLTimer>;
    FTimers: TACLList<TACLTimer>;

    function SafeProcessMessage(var AMessage: TMessage): Boolean; override;
    //
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

function NtQueryTimerResolution(out MaximumResolution, MinimumResolution, ActualResolution: ULONG): NTSTATUS; stdcall; external 'ntdll.dll';

{ TACLTimer }

constructor TACLTimer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEnabled := True;
  FInterval := 1000;
end;

constructor TACLTimer.CreateEx(ATimerEvent: TNotifyEvent; AInterval: Cardinal = 1000;
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
  inherited Create;
  FTimers := TACLList<TACLTimer>.Create;
  FHighResolutionTimers := TACLThreadList<TACLTimer>.Create;
end;

destructor TACLTimerManager.Destroy;
begin
  FreeAndNil(FHighResolutionThread);
  FreeAndNil(FHighResolutionTimers);
  FreeAndNil(FTimers);
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
      SetTimer(Handle, NativeUInt(ATimer), AlignToSystemTimerResolution(ATimer.Interval), nil);
  finally
    FLock.Leave;
  end;
end;

procedure TACLTimerManager.UnregisterTimer(ATimer: TACLTimer);
begin
  FLock.Enter;
  try
    if FTimers.Remove(ATimer) >= 0 then
      KillTimer(Handle, NativeUInt(ATimer));

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

function TACLTimerManager.SafeProcessMessage(var AMessage: TMessage): Boolean;
var
  AList: TACLList;
  I: Integer;
begin
  case AMessage.Msg of
    WM_TIMER:
      begin
        SafeCallTimerProc(TACLTimer(AMessage.WParam));
        Exit(True);
      end;

    WM_USER:
      begin
        AList := TACLList(AMessage.LParam);
        for I := 0 to AList.Count - 1 do
          SafeCallTimerProc(AList.List[I]);
        Exit(True);
      end;
  end;
  Result := False;
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
var
  AActualResolution: ULONG;
  AMaximumResolution: ULONG;
  AMinimumResolution: ULONG;
begin
  if FSystemTimerResolution = 0 then
  begin
    if NtQueryTimerResolution(AMaximumResolution, AMinimumResolution, AActualResolution) = 0 then
      FSystemTimerResolution := Round(AActualResolution / 1000);
    FSystemTimerResolution := Max(FSystemTimerResolution, 1);
  end;
  Result := FSystemTimerResolution;
end;

procedure TACLTimerManager.SafeCallTimerProc(ATimer: TACLTimer);
begin
//  FLock.Enter;
//  try
  if FTimers.Contains(ATimer) then
    ATimer.Timer;
//  finally
//    FLock.Leave;
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
  ATicked: TACLList;
  ATicks: Int64;
  ATimer: TACLTimer;
  I: Integer;
begin
  NameThreadForDebugging('HighResolutionTimer');

  ATicked := TACLList.Create;
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
        FOwner.SendMessage(WM_USER, 0, LPARAM(ATicked));
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
