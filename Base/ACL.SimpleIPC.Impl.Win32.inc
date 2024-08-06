uses
  Windows;

type

  { TIPCClient }

  TIPCClient = class(TInterfacedObject, IACLIPCClient)
  strict private
    FWndHandle: TWndHandle;
  public
    constructor Create(AWndHandle: TWndHandle);
    function Send(ACmd: Cardinal; const AData: string): TACLIPCResult;
  end;

  { TIPCServer }

  TIPCServer = class
  strict private
    FHelloMessage: Cardinal;
    FWndHandle: TWndHandle;
  public
    constructor Create(const AAppId: string);
    destructor Destroy; override;
    procedure WndProc(var AMessage: TMessage);
    class function TryConnect(const AServerName: string): IACLIPCClient;
  end;

function SendDataGetTempFileName(ID: Integer): string;
begin
  Result := acTempPath + IntToHex(ID, 8) + '.tmp';
end;

function SendDataGetData(const AStruct: PCopyDataStruct): string;
begin
  try
    if (AStruct^.lpData = nil) and (AStruct^.cbData <> 0) then
      Exit(acLoadString(SendDataGetTempFileName(AStruct^.cbData)));
    if IsBadReadPtr(AStruct^.lpData, AStruct^.cbData) then
      Exit('');
    Result := acMakeString(PWideChar(AStruct^.lpData), AStruct^.cbData div SizeOf(WideChar));
  except
    Result := '';
  end;
end;

{ TIPCClient }

constructor TIPCClient.Create(AWndHandle: TWndHandle);
begin
  FWndHandle := AWndHandle;
end;

function TIPCClient.Send(ACmd: Cardinal; const AData: string): TACLIPCResult;
var
  LCopyData: TCopyDataStruct;
  LTempFileName: string;
  LTempFileNameUsed: Boolean;
begin
  if not IsWindow(FWndHandle) then
    Exit(irAbandoned);

  ZeroMemory(@LCopyData, SizeOf(LCopyData));
  LCopyData.dwData := ACmd;
  LTempFileNameUsed := TACLProcess.IsWow64 <> TACLProcess.IsWow64Window(FWndHandle);
  if LTempFileNameUsed then
  begin
    LCopyData.cbData := NativeInt(DWORD(FWndHandle));
    LTempFileName := SendDataGetTempFileName(LCopyData.cbData);
    acSaveString(LTempFileName, AData);
  end
  else
  begin
    LCopyData.cbData := Length(AData) * SizeOf(WideChar);
    LCopyData.lpData := PWideChar(AData);
  end;
  SendMessageW(FWndHandle, WM_COPYDATA, 0, LPARAM(@LCopyData));
  if LTempFileNameUsed then
    acDeleteFile(LTempFileName);
  Result := irSucceeded;
end;

{ TIPCServer }

constructor TIPCServer.Create(const AAppId: string);
var
  LClientHandle: HWND;
begin
  FHelloMessage := RegisterWindowMessage('ACL.IPC:Hello');
  FWndHandle := WndCreate(WndProc, ClassName, False, AAppId);
  LClientHandle := 0;
  repeat
    LClientHandle := FindWindowExW(0, LClientHandle, PWideChar(ClassName), nil);
    if (LClientHandle <> 0) and (FWndHandle <> LClientHandle) then
    begin
      TACLIPCHub.FClients.Add(TIPCClient.Create(LClientHandle));
      PostMessage(LClientHandle, FHelloMessage, 0, FWndHandle);
    end;
  until LClientHandle = 0;
end;

destructor TIPCServer.Destroy;
begin
  WndFree(FWndHandle);
  inherited;
end;

class function TIPCServer.TryConnect(const AServerName: string): IACLIPCClient;
var
  LWnd: TWndHandle;
begin
  LWnd := FindWindow(PChar(TIPCServer.ClassName), PChar(AServerName));
  if LWnd <> 0 then
    Exit(TIPCClient.Create(LWnd));
  Result := nil;
end;

procedure TIPCServer.WndProc(var AMessage: TMessage);
var
  LStruct: PCopyDataStruct;
begin
  if AMessage.Msg = FHelloMessage then
    TACLIPCHub.FClients.Add(TIPCClient.Create(AMessage.LParam))
  else
    if AMessage.Msg = WM_COPYDATA then
    begin
      LStruct := PCopyDataStruct(AMessage.LParam);
      if LStruct <> nil then
        TACLIPCHub.Receive(LStruct^.dwData, SendDataGetData(LStruct));
    end
    else
      WndDefaultProc(FWndHandle, AMessage);
end;

{ TACLAppAtom }

constructor TACLAppAtom.Create(const AppId: string);
begin
  FSysPath := acUpperCase(AppId);
  FHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, 1, PChar(FSysPath));
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    CloseHandle(FHandle);
    FHandle := 0;
  end;
end;

destructor TACLAppAtom.Destroy;
begin
  if FHandle <> 0 then
    CloseHandle(FHandle);
  inherited;
end;
