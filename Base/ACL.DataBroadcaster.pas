////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   data exchange between applications
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       NotImplemented
//
unit ACL.DataBroadcaster;

{$I ACL.Config.inc}

// FPC: для передачи данных между приложениями WM_COPYDATA
// уже не прокатит, нужно нативное решение

interface

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ELSE}
  LCLIntf,
  LCLType,
{$ENDIF}
  Messages,
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  // ACL
  ACL.Classes.Collections,
  ACL.Threading,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Messaging,
  ACL.Utils.Strings,
  ACL.Utils.Stream;

type
{$IFDEF FPC}
  PCopyDataStruct = Pointer; // stub
{$ENDIF}

  { IACLDataBroadcasterClient }

  IACLDataBroadcasterClient = interface
  ['{C6098A78-4334-4911-89A4-236CBAA601F5}']
    procedure Receive(ID: Cardinal; const AData: string);
  end;

  { TACLDataBroadcaster }

  TACLDataBroadcaster = class
  strict private
    FClients: TACLThreadList<HWND>;
    FHandle: HWND;
    FHelloMessage: Cardinal;
    FListeners: TInterfaceList;

    procedure CreateHandle;
  protected
    procedure Receive(ID: Cardinal; const AData: string);
    procedure WndProc(var AMessage: TMessage);
  public
    constructor Create;
    destructor Destroy; override;
    function RegisterID(const AName: string): Cardinal;
    // Send
    procedure Send(ID: Cardinal; const AData: string = '');
    procedure SendLocal(ID: Cardinal; const AData: string = '');
    // Listeners
    procedure ListenerRegister(const AListener: IACLDataBroadcasterClient);
    procedure ListenerUnregister(const AListener: IACLDataBroadcasterClient);
  end;

function DataBroadcaster: TACLDataBroadcaster;
function SendDataGetData(const AMessage: TMessage): string; overload;
function SendDataGetData(const AStruct: PCopyDataStruct): string; overload;
function SendDataToApplication(const AApplicationFileName, AWindowClass, AData: string): Boolean;
function SendDataToHandle(AHandle: HWND; const AData: string): Boolean; overload;
function SendDataToHandle(AHandle: HWND; const AData: string; ID: Cardinal): Boolean; overload;
implementation

uses
  SysUtils;

const
  SendDataID = 753;

var
  FDataBroadcaster: TACLDataBroadcaster;

function DataBroadcaster: TACLDataBroadcaster;
begin
  if FDataBroadcaster = nil then
    FDataBroadcaster := TACLDataBroadcaster.Create;
  Result := FDataBroadcaster;
end;

function SendDataGetTempFileName(ID: Integer): string;
begin
  Result := acTempPath + IntToHex(ID, 8) + '.tmp';
end;

function SendDataGetData(const AMessage: TMessage): string;
var
  M: PCopyDataStruct;
begin
  Result := '';
{$IFDEF MSWINDOWS}
  if AMessage.Msg = WM_COPYDATA then
  begin
    M := PCopyDataStruct(AMessage.LParam);
    if Assigned(M) and (M^.dwData = SendDataID) then
      Result := SendDataGetData(M);
  end;
{$ENDIF}
end;

function SendDataGetData(const AStruct: PCopyDataStruct): string;
begin
  Result := '';
  if AStruct <> nil then
  try
  {$IFDEF MSWINDOWS}
    if (AStruct^.lpData = nil) and (AStruct^.cbData <> 0) then
      Result := acLoadString(SendDataGetTempFileName(AStruct^.cbData))
    else
      if not IsBadReadPtr(AStruct^.lpData, AStruct^.cbData) then
        Result := acMakeString(PWideChar(AStruct^.lpData), AStruct^.cbData div SizeOf(WideChar));
  {$ENDIF}
  except
    Result := '';
  end;
end;

function SendDataToApplication(const AApplicationFileName, AWindowClass, AData: string): Boolean;
var
  AHandle: HWND;
  AWaitCount: Integer;
begin
  AHandle := acFindWindow(AWindowClass);
  if AHandle = 0 then
  begin
    Result := TACLProcess.Execute(AApplicationFileName);
    if Result then
    begin
      AWaitCount := 10;
      while AWaitCount > 0 do
      begin
        AHandle := acFindWindow(AWindowClass);
        if AHandle <> 0 then Break;
        Dec(AWaitCount);
        Sleep(300);
      end;
    end;
  end;
  Result := SendDataToHandle(AHandle, AData);
end;

function SendDataToHandle(AHandle: HWND; const AData: string): Boolean;
begin
  Result := SendDataToHandle(AHandle, AData, SendDataID);
end;

function SendDataToHandle(AHandle: HWND; const AData: string; ID: Cardinal): Boolean;
{$IFDEF MSWINDOWS}
var
  ACopyData: TCopyDataStruct;
  ATempFileName: string;
  ATempFileNameUsed: Boolean;
begin
  Result := AHandle <> 0;
  if Result then
  begin
    ZeroMemory(@ACopyData, SizeOf(ACopyData));
    ACopyData.dwData := ID;
    ATempFileNameUsed := TACLProcess.IsWow64 <> TACLProcess.IsWow64Window(AHandle);
    if ATempFileNameUsed then
    begin
      ACopyData.cbData := NativeInt(DWORD(AHandle));
      ATempFileName := SendDataGetTempFileName(ACopyData.cbData);
      acSaveString(ATempFileName, AData);
    end
    else
    begin
      ACopyData.cbData := Length(AData) * SizeOf(WideChar);
      ACopyData.lpData := PWideChar(AData);
    end;
    SendMessageW(AHandle, WM_COPYDATA, 0, LPARAM(@ACopyData));
    if ATempFileNameUsed then
      acDeleteFile(ATempFileName);
  end;
{$ELSE}
begin
  Result := False;
{$ENDIF}
end;

{ TACLDataBroadcaster }

constructor TACLDataBroadcaster.Create;
begin
  inherited Create;
  FClients := TACLThreadList<HWND>.CreateMultiReadExclusiveWrite;
  FListeners := TInterfaceList.Create;
  FHelloMessage := RegisterID(ClassName + ':Hello');
  RunInMainThread(CreateHandle);
end;

destructor TACLDataBroadcaster.Destroy;
begin
  WndFree(FHandle);
  FreeAndNil(FListeners);
  FreeAndNil(FClients);
  inherited Destroy;
end;

procedure TACLDataBroadcaster.ListenerRegister(const AListener: IACLDataBroadcasterClient);
begin
  FListeners.Add(AListener);
end;

procedure TACLDataBroadcaster.ListenerUnregister(const AListener: IACLDataBroadcasterClient);
begin
  FListeners.Remove(AListener);
end;

procedure TACLDataBroadcaster.Receive(ID: Cardinal; const AData: string);
var
  I: Integer;
begin
  if (ID <> 0) or (AData <> '') then
  begin
    FListeners.Lock;
    try
      for I := 0 to FListeners.Count - 1 do
        (FListeners[I] as IACLDataBroadcasterClient).Receive(ID, AData);
    finally
      FListeners.Unlock;
    end;
  end;
end;

function TACLDataBroadcaster.RegisterID(const AName: string): Cardinal;
begin
{$IFDEF MSWINDOWS}
  Result := RegisterWindowMessageW(PWideChar(AName));
{$ELSE}
  Result := 0;
{$ENDIF}
end;

procedure TACLDataBroadcaster.Send(ID: Cardinal; const AData: string);
var
  AHandle: HWND;
  AIndex: Integer;
begin
  SendLocal(ID, AData);
  AIndex := FClients.Count - 1;
  while AIndex >= 0 do
  begin
    if FClients.Read(AIndex, AHandle) then
    begin
      if IsWindow(AHandle) then
        SendDataToHandle(AHandle, AData, ID)
      else
        FClients.Remove(AHandle);
    end;
    Dec(AIndex);
  end;
end;

procedure TACLDataBroadcaster.SendLocal(ID: Cardinal; const AData: string);
begin
  if IsMainThread then
    Receive(ID, AData)
  else
    SendDataToHandle(FHandle, AData, ID);
end;

procedure TACLDataBroadcaster.WndProc(var AMessage: TMessage);
var
  AStruct: PCopyDataStruct;
begin
  if AMessage.Msg = FHelloMessage then
    FClients.Add(AMessage.LParam)
  else
  {$IFDEF MSWINDOWS}
    if AMessage.Msg = WM_COPYDATA then
    begin
      AStruct := PCopyDataStruct(AMessage.LParam);
      if AStruct <> nil then
        Receive(AStruct^.dwData, SendDataGetData(AStruct));
    end
    else
  {$ENDIF}
      WndDefaultProc(FHandle, AMessage);
end;

procedure TACLDataBroadcaster.CreateHandle;
var
  AClientHandle: HWND;
begin
  FHandle := WndCreate(WndProc, ClassName);
{$IFDEF MSWINDOWS}
  AClientHandle := 0;
  repeat
    AClientHandle := FindWindowExW(0, AClientHandle, PWideChar(ClassName), nil);
    if (AClientHandle <> 0) and (FHandle <> AClientHandle) then
    begin
      FClients.Add(AClientHandle);
      PostMessage(AClientHandle, FHelloMessage, 0, FHandle);
    end;
  until AClientHandle = 0;
{$ENDIF}
end;

initialization

finalization
  FreeAndNil(FDataBroadcaster);
end.
