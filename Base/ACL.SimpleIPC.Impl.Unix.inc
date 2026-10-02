uses
  BaseUnix, ACL.Timers;

type

  { TIPCClient }

  TIPCClient = class(TInterfacedObject, IACLIPCClient)
  strict private
    FFileName: string;
    FFileStream: TFileStream;
  public
    constructor Create(const AAppId: string);
    destructor Destroy; override;
    function Connect: Boolean;
    function Send(ACmd: Cardinal; const AData: string; ATimeOut: LongWord): TACLIPCResult;
  end;

  { TIPCServer }

  TIPCServer = class
  strict private const
    HelloCmd = 1;
  strict private
    FFileName: string;
    FFileStream: TFileStream;
    FIdle: TACLTimer;

    procedure HandlerPollMessage(Sender: TObject);
  public
    constructor Create(const AAppId: string; const ACompanionAppIds: array of string);
    destructor Destroy; override;
    class function GetServerFileName(const AAppId: string): string;
    class function TryConnect(const AAppId: string): IACLIPCClient;
  end;

{ TIPCClient }

constructor TIPCClient.Create(const AAppId: string);
begin
  FFileName := TIPCServer.GetServerFileName(AAppId);
end;

destructor TIPCClient.Destroy;
begin
  FreeAndNil(FFileStream);
  inherited Destroy;
end;

function TIPCClient.Connect: Boolean;
var
  fd: Integer;
begin
  Result := FileExists(FFileName);
  // it's possible to have a stale file that is not open for reading which will
  // cause fpOpen to hang/block later when .Active is set to true while it
  // waits for the pipe to be opened on the other end
  if Result then
  begin
    // O_WRONLY | O_NONBLOCK causes fpOpen to return -1 if the file is not open for reading
    // so in fact the 'server' is not running
    fd := FpOpen(FFileName, O_WRONLY or O_NONBLOCK);
    if fd = -1 then
    begin
      Result := False;
      // delete the named pipe since it's orphaned
      FpUnlink(FFileName);
    end
    else
      FpClose(fd);
  end;

  if Result and (FFileStream = nil) then
    FFileStream := TFileStream.Create(FFileName, fmOpenWrite or fmShareDenyNone);
end;

function TIPCClient.Send(ACmd: Cardinal; const AData: string; ATimeOut: LongWord): TACLIPCResult;
begin
  Result := irAbandoned;
  if Connect then
  try
    FFileStream.WriteInt32(ACmd);
    FFileStream.WriteInt32(Length(AData));
    FFileStream.WriteStringA(AData);
    Result := irSucceeded;
  except
    Result := irFailed;
  end;
end;

{ TIPCServer }

constructor TIPCServer.Create(const AAppId: string; const ACompanionAppIds: array of string);
var
  LClient: IACLIPCClient;
  LError: Integer;
  LInfo: TACLFindFileInfo;
  I: Integer;
begin
  FFileName := GetServerFileName(AAppId);

  // Start the server
  if not FileExists(FFileName) then
  begin
    LError := FpMkfifo(FFileName, &666);
    if LError <> 0 then
      raise Exception.CreateFmt('Cannot create named pipe "%s" (%d)', [FFileName, LError]);
  end;
  fpChmod(FFileName, &600);
  FFileStream := TFileStream.Create(FFileName, fmOpenReadWrite or fmShareDenyNone);

  // Connect to already running companion servers
  for I := Low(ACompanionAppIds) to High(ACompanionAppIds) do
  begin
    if ACompanionAppIds[I] <> AAppId then
    begin
      LClient := TIPCClient.Create(ACompanionAppIds[I]);
      if LClient.Send(HelloCmd, AAppId, 0) = irSucceeded then
        TACLIPCHub.FClients.Add(LClient);
    end;
  end;

  // Start the processor
  FIdle := TACLTimer.CreateEx(HandlerPollMessage, 100).Start;
end;

destructor TIPCServer.Destroy;
begin
  FreeAndNil(FIdle);
  FreeAndNil(FFileStream);
  if not DeleteFile(FFileName) then
    LogEntry(acGeneralLogFileName, 'IPC', 'failed to remove pipe %s', [FFileName]);
  inherited Destroy;
end;

class function TIPCServer.GetServerFileName(const AAppId: string): string;
begin
  Result := GetTempDir(False) + 'ipc_' + acValidateFileName(AAppId, '-');
end;

procedure TIPCServer.HandlerPollMessage(Sender: TObject);
// Timeout values:
//   >  0  -- Number of milliseconds to wait
//   =  0  -- return immediately
//   = -1  -- wait infinitely
const
  TimeOut = 1;
var
  FDS: TFDSet;
  LCommand: Integer;
  LMessage: string;
begin
  fpfd_zero(FDS);
  fpfd_set(FFileStream.Handle, FDS);
  if fpSelect(FFileStream.Handle + 1, @FDS, nil, nil, TimeOut) > 0 then
  try
    LCommand := FFileStream.ReadInt32;
    LMessage := FFileStream.ReadStringA(FFileStream.ReadInt32);
    if LCommand = HelloCmd then
      TACLIPCHub.FClients.Add(TIPCClient.Create(LMessage))
    else
      TACLIPCHub.Receive(LCommand, LMessage);
  except
    // do nothing
  end;
end;

class function TIPCServer.TryConnect(const AAppId: string): IACLIPCClient;
var
  LClient: TIPCClient;
begin
  Result := nil;
  try
    LClient := TIPCClient.Create(AAppId);
    if LClient.Connect then
      Result := LClient
    else
      LClient.Free;
  except
    // do nothing
  end;
end;

{ TACLAppAtom }

constructor TACLAppAtom.Create(const AppId: string);
var
  LFileDesc: cint;
begin
  FSysPath := GetTempDir(False) + acLowerCase(acValidateFileName(AppId, '-')) + '.atom';
  // it's possible to have a stale file that is not open for reading which will
  // cause fpOpen to hang/block later when .Active is set to true while it
  // wait's for the pipe to be opened on the other end
  if FileExists(FSysPath) then
  begin
    // O_WRONLY | O_NONBLOCK causes fpOpen to return -1
    // if the file is not open for reading.
    // So, in fact the 'server' is not running
    LFileDesc := FpOpen(PChar(FSysPath), O_WRONLY or O_NONBLOCK);
    if LFileDesc <> -1 then
    begin
      FpClose(LFileDesc);
      Exit; // ok, atom is already used
    end;
    // delete the named pipe since it's abandoned
    FpUnlink(PChar(FSysPath));
  end;
  if fpmkFifo(FSysPath, &666) = 0 then // create the named pipe
    FHandle := FileOpen(FSysPath, fmOpenReadWrite or fmShareDenyNone);
end;

destructor TACLAppAtom.Destroy;
begin
  if FHandle <> 0 then
  begin
    FpClose(cInt(FHandle));
    FpUnlink(PChar(FSysPath));
    FHandle := 0;
  end;
  inherited Destroy;
end;
