uses
  baseunix,
  simpleipc,
  // ACL
  ACL.Timers;

type

  { TIPCClient }

  TIPCClient = class(TInterfacedObject, IACLIPCClient)
  strict private
    FCore: TSimpleIPCClient;
  public
    constructor Create(const AServerName: string);
    destructor Destroy; override;
    function IsServerRunning: Boolean;
    function Send(ACmd: Cardinal; const AData: string): TACLIPCResult;
  end;

  { TIPCServer }

  TIPCServer = class
  strict private const
    HelloCmd = 1;
    Prefix = 'taclipc_';
  strict private
    FCore: TSimpleIPCServer;
    FIdle: TACLTimer;
    procedure HandlerMessage(Sender: TObject);
    procedure HandlerPoolMessage(Sender: TObject);
  public
    constructor Create(const AAppId: string);
    destructor Destroy; override;
    class function TryConnect(const AServerName: string): IACLIPCClient;
  end;

{ TIPCClient }

constructor TIPCClient.Create(const AServerName: string);
begin
  FCore := TSimpleIPCClient.Create(nil);
  FCore.ServerID := AServerName;
  FCore.Connect;
end;

destructor TIPCClient.Destroy;
begin
  FreeAndNil(FCore);
  inherited Destroy;
end;

function TIPCClient.IsServerRunning: Boolean;
begin
  Result := FCore.ServerRunning;
end;

function TIPCClient.Send(ACmd: Cardinal; const AData: string): TACLIPCResult;
begin
  try
    FCore.SendStringMessage(TMessageType(ACmd), AData);
    Result := irSucceeded;
  except
    Result := irAbandoned;
  end;
end;

{ TIPCServer }

constructor TIPCServer.Create(const AAppId: string);
var
  LClient: IACLIPCClient;
  LInfo: TACLFindFileInfo;
  LName: string;
  LTemp: string;
begin
  LName := Prefix + AAppId;
  LTemp := acIncludeTrailingPathDelimiter(GetTempDir(True));

  FCore := TSimpleIPCServer.Create(nil);
  FCore.Global := True;
  FCore.OnMessage := HandlerMessage;
  FCore.ServerID := LTemp + LName;
  FCore.StartServer;

  if acFindFileFirst(LTemp, [ffoFile], LInfo) then
  try
    repeat
      if LInfo.FileName.StartsWith(Prefix) and (LInfo.FileName <> LName) then
      begin
        LClient := TIPCClient.Create(LInfo.FileName);
        LClient.Send(HelloCmd, LName);
        TACLIPCHub.FClients.Add(LClient);
      end;
    until not acFindFileNext(LInfo);
  finally
    acFindFileClose(LInfo);
  end;

  FIdle := TACLTimer.Create(nil);
  FIdle.OnTimer := HandlerPoolMessage;
  FIdle.Enabled := True;
end;

destructor TIPCServer.Destroy;
begin
  FreeAndNil(FIdle);
  try
    FCore.StopServer;
  except
    // do nothing
  end;
  FreeAndNil(FCore);
  inherited Destroy;
end;

procedure TIPCServer.HandlerMessage(Sender: TObject);
var
  LCmd: Cardinal;
  LMsg: string;
begin
  LCmd := Cardinal(FCore.Message.MsgType);
  LMsg := FCore.Message.StringMessage;
  if LCmd = HelloCmd then
    TACLIPCHub.FClients.Add(TIPCClient.Create(LMsg))
  else
    TACLIPCHub.Receive(LCmd, LMsg);
end;

procedure TIPCServer.HandlerPoolMessage(Sender: TObject);
begin
  FCore.PeekMessage(1, True);
end;

class function TIPCServer.TryConnect(const AServerName: string): IACLIPCClient;
var
  LClient: TIPCClient;
begin
  LClient := TIPCClient.Create(Prefix + AServerName);
  if LClient.IsServerRunning then
    Result := LClient
  else
    LClient.Free;
end;

{ TACLAppAtom }

constructor TACLAppAtom.Create(const AppId: string);
var
  LFileDesc: cint;
begin
  FSysPath := GetTempDir(True) + acLowerCase(acValidateFileName(AppId, '-')) + '.atom';
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
  if fpmkFifo(FSysPath, 438) = 0 then // create the named pipe
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
