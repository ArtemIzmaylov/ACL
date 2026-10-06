////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Simple Inter-Process Communication
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.SimpleIPC;

{$I ACL.Config.inc}

interface

uses
  Messages,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}Generics.Collections,
  {System.}SysUtils,
  // ACL
  ACL.Classes.Collections,
  ACL.Hashes,
  ACL.Threading,
  ACL.Utils.Common,
  ACL.Utils.Logger,
  ACL.Utils.FileSystem,
  ACL.Utils.Messaging,
  ACL.Utils.Strings,
  ACL.Utils.Stream;

{$IFDEF FPC}
const
  WM_COPYDATA = $004A; // stub, not used
{$ENDIF}

type
  TACLIPCResult = (irAbandoned, irFailed, irSucceeded);

  { IACLIPCClient }

  IACLIPCClient = interface
  ['{1E225ABC-7B42-4631-95BD-7078CFD1583C}']
    function Send(ACmd: Cardinal; const AData: string; ATimeOut: LongWord): TACLIPCResult;
  end;

  { TACLAppAtom }

  TACLAppAtom = class
  strict private
    FHandle: THandle;
    FSysPath: string;
  public
    constructor Create(const AppId: string);
    destructor Destroy; override;
    property Handle: THandle read FHandle;
  end;

  { TACLIPCHub }

  TACLIPCHub = class
  public const
    CmdIdParams = 753; // don't change, for backward compatibility
    DefaultTimeOut = 3000;
  public type
    TReceiver = procedure (ACmd: Cardinal; const AData: string) of object;
  private
    class var FClients: TACLThreadListOf<IACLIPCClient>;
    class var FReceivers: TACLThreadListOf<TReceiver>;
    class var FServer: TObject;
    class procedure Receive(ACmd: Cardinal; const AData: string);
  public
    class constructor Create;
    class destructor Destroy;
    class procedure Initialize(const AAppId: string; const ACompanionAppIds: array of string);
    // Registry
    class procedure Register(AReceiver: TReceiver);
    class function RegisterCmd(const AName: string): Cardinal;
    class procedure Unregister(AReceiver: TReceiver);
    // Send
    class procedure Send(ACmd: Cardinal; const AData: string = '');
    class procedure SendLocal(ACmd: Cardinal; const AData: string = '');
    // Specially for backward compatibility (Windows Only!)
    class procedure ProcessCopyMessage(var Msg: TMessage);
  end;

function SendDataToApplication(const AAppFileName, AIpcServerName: string;
  ACmd: Cardinal; const AData: string = ''): Boolean;
function SendDataToIPC(const AIpcServerName: string;
  ACmd: Cardinal; const AData: string = ''; ATimeOut: Integer = 0): Boolean;
implementation

{$IF DEFINED(MSWINDOWS)}
  {$I ACL.SimpleIPC.Impl.Win32.inc}
{$ELSEIF DEFINED(LINUX)}
  {$I ACL.SimpleIPC.Impl.Unix.inc}
{$ENDIF}

function SendDataToApplication(
  const AAppFileName, AIpcServerName: string; ACmd: Cardinal;
  const AData: string): Boolean;
begin
  if SendDataToIPC(AIpcServerName, ACmd, AData) then
    Exit(True);
  if TACLProcess.Execute(AAppFileName) then
    Result := SendDataToIPC(AIpcServerName, ACmd, AData, TACLIPCHub.DefaultTimeOut)
  else
    Result := False;
end;

function SendDataToIPC(const AIpcServerName: string;
  ACmd: Cardinal; const AData: string; ATimeOut: Integer): Boolean;
var
  LClient: IACLIPCClient;
  LTimestamp: TACLTimestamp;
begin
  Result := False;
  try
    LTimestamp := TACLThread.Timestamp;
    repeat
      LClient := TIPCServer.TryConnect(AIpcServerName);
      if LClient <> nil then
      begin
        Dec(ATimeOut, Integer(TACLThread.Timestamp - LTimestamp));
        Exit(LClient.Send(ACmd, AData, Max(ATimeOut, 0)) = irSucceeded);
      end;
      if (ATimeOut = 0) or TACLThread.IsTimeout(LTimestamp, ATimeOut) then
        Exit(False);
      Sleep(50);
    until False;
  finally
    LogEntry(acGeneralLogFileName, 'IPC', 'SendData(%s, %d, %s) = %s',
      [AIpcServerName, ACmd, AData, BoolToStr(Result)]);
  end;
end;

{ TACLIPCHub }

class constructor TACLIPCHub.Create;
begin
  FClients := TACLThreadListOf<IACLIPCClient>.CreateMultiReadExclusiveWrite;
  FReceivers := TACLThreadListOf<TReceiver>.Create;
end;

class destructor TACLIPCHub.Destroy;
begin
  // Keep the order
  FreeAndNil(FServer);
  FreeAndNil(FClients);
  FreeAndNil(FReceivers);
end;

class procedure TACLIPCHub.Initialize(
  const AAppId: string; const ACompanionAppIds: array of string);
begin
  CheckIsMainThread;
  if FServer = nil then
    FServer := TIPCServer.Create(AAppId, ACompanionAppIds);
end;

class procedure TACLIPCHub.ProcessCopyMessage(var Msg: TMessage);
begin
{$IFDEF MSWINDOWS}
  if FServer = nil then
    raise EInvalidOp.Create(ClassName + ' was not initialized');
  TIPCServer(FServer).WndProc(Msg);
{$ENDIF}
end;

class procedure TACLIPCHub.Receive(ACmd: Cardinal; const AData: string);
var
  I: Integer;
  LList: TACLListOf<TReceiver>;
begin
  LogEntry(acGeneralLogFileName, 'IPC', 'Receive(%d, %s)', [ACmd, AData]);
  if (ACmd <> 0) or (AData <> '') then
  begin
    LList := FReceivers.LockList;
    try
      for I := 0 to LList.Count - 1 do
        LList.List[I](ACmd, AData);
    finally
      FReceivers.UnlockList;
    end;
  end;
end;

class procedure TACLIPCHub.Register(AReceiver: TReceiver);
begin
  FReceivers.Add(AReceiver);
end;

class function TACLIPCHub.RegisterCmd(const AName: string): Cardinal;
begin
//{$IFDEF MSWINDOWS}
//  Result := RegisterWindowMessage(PChar(AName));
//{$ELSE}
  Result := ElfHash(AName);
//{$ENDIF}
end;

class procedure TACLIPCHub.Send(ACmd: Cardinal; const AData: string);
var
  LClient: IACLIPCClient;
  LIndex: Integer;
begin
  LogEntry(acGeneralLogFileName, 'IPC', 'Send(%d, %s)', [ACmd, AData]);

  SendLocal(ACmd, AData);
  if FServer = nil then
    raise EInvalidOp.Create(ClassName + ' was not initialized');
  LIndex := FClients.Count - 1;
  while LIndex >= 0 do
  begin
    if FClients.Read(LIndex, LClient) then
    begin
      if LClient.Send(ACmd, AData, DefaultTimeOut) = irAbandoned then
        FClients.Remove(LClient);
    end;
    Dec(LIndex);
  end;
end;

class procedure TACLIPCHub.SendLocal(ACmd: Cardinal; const AData: string);
begin
  if IsMainThread then
    Receive(ACmd, AData)
  else
    TACLMainThread.Run(
      procedure
      begin
        Receive(ACmd, AData);
      end, True);
end;

class procedure TACLIPCHub.Unregister(AReceiver: TReceiver);
begin
  if FReceivers <> nil then
    FReceivers.Remove(AReceiver);
end;

end.
