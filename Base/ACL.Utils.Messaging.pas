////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Messaging routines
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Utils.Messaging;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  InterfaceBase,
  LCLIntf,
  LCLType,
  LMessages,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  // ACL
  ACL.Utils.Common;

const
{$IFDEF FPC}
  WM_USER = LMessages.LM_USER;
{$ELSE}
  WM_USER = Messages.WM_USER;
{$ENDIF}

type
{$IFDEF FPC}
  TWndMethod = TLCLWndMethod;

  LPARAM = LCLType.LPARAM;
  WPARAM = LCLType.WPARAM;
{$ELSE}
  LPARAM = Windows.LPARAM;
  WPARAM = Windows.WPARAM;
{$ENDIF}

  { TACLMessaging }

  TACLMessageHandler = procedure (var AMessage: TMessage; var AHandled: Boolean) of object;

  TACLMessaging = class sealed
  strict private
    class var FCustomMessages: TObject;
    class var FHandle: TWndHandle;
    class var FHandlers: TObject;

    class procedure EnsureInitialized;
    class procedure WndProc(var AMessage: TMessage);
  public
    class constructor Create;
    class destructor Destroy;
    // Handlers
    class procedure HandlerAdd(AHandler: TACLMessageHandler);
    class procedure HandlerRemove(AHandler: TACLMessageHandler);
    // Messages
    class function RegisterMessage(const AName: string): Cardinal;
    class procedure PostMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
    class procedure SendMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
    // Properties
    class property Handle: TWndHandle read FHandle;
  end;

  { TMessagesHelper }

  TMessagesHelper = class
  public
    class function IsInQueue(AWndHandle: TWndHandle; AMessage: Cardinal): Boolean;
  {$IFDEF MSWINDOWS}
    class procedure Process(AFromMessage, AToMessage: Cardinal; AWndHandle: TWndHandle = 0); overload;
    class procedure Process(AMessage: Cardinal; AWndHandle: TWndHandle = 0); overload;
  {$ENDIF}
    class procedure Remove(AMessage: Cardinal; AWndHandle: TWndHandle = 0);
  end;

function WndCreate(Method: TWndMethod; const ClassName: string;
  IsMessageOnly: Boolean = False; const Name: string = ''): TWndHandle;
procedure WndDefaultProc(W: TWndHandle; var Message: TMessage);
procedure WndFree(W: TWndHandle);

function acSendMessage(AWnd: TWndHandle; AMsg: Cardinal; WParam: WPARAM; LParam: LPARAM): LRESULT;
function acPostMessage(AWnd: TWndHandle; AMsg: Cardinal; WParam: WPARAM; LParam: LPARAM): Boolean;
implementation

uses
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // ACL
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Threading;

function acSendMessage(AWnd: TWndHandle; AMsg: Cardinal; WParam: WPARAM; LParam: LPARAM): LRESULT;
{$IFDEF FPC}
var
  LInnerResult: LRESULT;
{$ENDIF}
begin
{$IFDEF FPC}
  if not IsMainThread then
  begin
    LInnerResult := 0;
    TThread.Synchronize(nil, procedure begin
      LInnerResult := LCLIntf.SendMessage(AWnd, AMsg, WParam, LParam);
    end);
    Exit(LInnerResult);
  end;
{$ENDIF}
  Result := SendMessage(AWnd, AMsg, WParam, LParam);
end;

function acPostMessage(AWnd: TWndHandle; AMsg: Cardinal; WParam: WPARAM; LParam: LPARAM): Boolean;
begin
  Result := PostMessage(AWnd, AMsg, WParam, LParam);
end;

{$IFDEF FPC}
function WndCreate(Method: TWndMethod; const ClassName: string;
  IsMessageOnly: Boolean; const Name: string): TWndHandle;
begin
  if not IsMainThread then
    raise EInvalidOperation.Create('Cannot create window in non-main thread');
  Result := AllocateHWnd(Method);
  if Result = 0 then
    raise ENotImplemented.Create('AllocateHWnd is not implemented for this platform');
end;

procedure WndDefaultProc(W: TWndHandle; var Message: TMessage);
begin
  // do nothing
end;

procedure WndFree(W: TWndHandle);
begin
  DeallocateHWnd(W);
end;

{$ELSE}

var
  UtilWindowClass: TWndClass = (Style: 0; lpfnWndProc: @DefWindowProc;
    cbClsExtra: 0; cbWndExtra: 0; hInstance: 0; hIcon: 0; hCursor: 0;
    hbrBackground: 0; lpszMenuName: nil; lpszClassName: 'TPUtilWindow');
  UtilWindowClassName: string;

function WndCreate(Method: TWndMethod; const ClassName: string;
  IsMessageOnly: Boolean = False; const Name: string = ''): TWndHandle;
var
  ClassRegistered: Boolean;
  TempClass: TWndClass;
begin
  if not IsMainThread then
    raise EInvalidOperation.Create('Cannot create window in non-main thread');
  UtilWindowClassName := ClassName;
  UtilWindowClass.hInstance := HInstance;
  UtilWindowClass.lpszClassName := PChar(UtilWindowClassName);
  ClassRegistered := GetClassInfo(HInstance, UtilWindowClass.lpszClassName, TempClass);
  if not ClassRegistered or (TempClass.lpfnWndProc <> @DefWindowProc) then
  begin
    if ClassRegistered then
      {Winapi.}Windows.UnregisterClass(UtilWindowClass.lpszClassName, HInstance);
    {Winapi.}Windows.RegisterClass(UtilWindowClass);
  end;
  Result := CreateWindowEx(WS_EX_TOOLWINDOW, UtilWindowClass.lpszClassName, PChar(Name),
    WS_POPUP {!0}, 0, 0, 0, 0, IfThen(IsMessageOnly, HWND_MESSAGE), 0, HInstance, nil);
  if Assigned(Method) then
    SetWindowLong(Result, GWL_WNDPROC, NativeUInt(System.Classes.MakeObjectInstance(Method)));
end;

procedure WndDefaultProc(W: TWndHandle; var Message: TMessage);
begin
  Message.Result := DefWindowProc(W, Message.Msg, Message.WParam, Message.LParam);
end;

procedure WndFree(W: TWndHandle);
var
  AInstance: Pointer;
begin
  if W <> 0 then
  begin
    AInstance := Pointer(GetWindowLong(W, GWL_WNDPROC));
    DestroyWindow(W);
    if AInstance <> @DefWindowProc then
      System.Classes.FreeObjectInstance(AInstance);
  end;
end;

{$ENDIF}

{ TMessagesHelper }

class function TMessagesHelper.IsInQueue(AWndHandle: TWndHandle; AMessage: Cardinal): Boolean;
var
  AMsg: TMSG;
begin
  Result := PeekMessage(AMsg{%H-}, AWndHandle, AMessage, AMessage, PM_NOREMOVE) and (AMsg.hwnd = AWndHandle);
end;

{$IFDEF MSWINDOWS}
class procedure TMessagesHelper.Process(AFromMessage, AToMessage: Cardinal; AWndHandle: TWndHandle = 0);
var
  AMsg: TMsg;
begin
  while PeekMessage(AMsg{%H-}, AWndHandle, AFromMessage, AToMessage, PM_REMOVE) do
  begin
    TranslateMessage(AMsg);
    DispatchMessage(AMsg);
  end;
end;

class procedure TMessagesHelper.Process(AMessage: Cardinal; AWndHandle: TWndHandle = 0);
begin
  Process(AMessage, AMessage, AWndHandle);
end;
{$ENDIF}

class procedure TMessagesHelper.Remove(AMessage: Cardinal; AWndHandle: TWndHandle = 0);
var
  AMsg: TMsg;
begin
  while PeekMessage(AMsg{%H-}, AWndHandle, AMessage, AMessage, PM_REMOVE) do ;
end;

{ TACLMessaging }

class constructor TACLMessaging.Create;
begin
  EnsureInitialized;
end;

class destructor TACLMessaging.Destroy;
begin
  WndFree(FHandle);
  FreeAndNil(FCustomMessages);
  FreeAndNil(FHandlers);
end;

class procedure TACLMessaging.HandlerAdd(AHandler: TACLMessageHandler);
begin
  TACLThreadList<TACLMessageHandler>(FHandlers).Add(AHandler);
end;

class procedure TACLMessaging.HandlerRemove(AHandler: TACLMessageHandler);
begin
  if FHandlers <> nil then
    TACLThreadList<TACLMessageHandler>(FHandlers).Remove(AHandler);
end;

class procedure TACLMessaging.PostMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
begin
  acPostMessage(FHandle, AMessage, AParamW, AParamL);
end;

class procedure TACLMessaging.SendMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
begin
  acSendMessage(FHandle, AMessage, AParamW, AParamL);
end;

class function TACLMessaging.RegisterMessage(const AName: string): Cardinal;
var
  AIndex: Integer;
begin
  EnsureInitialized;
  TACLThreadList<TACLMessageHandler>(FHandlers).LockList;
  try
    AIndex := TACLStringList(FCustomMessages).IndexOf(AName);
    if AIndex < 0 then
      AIndex := TACLStringList(FCustomMessages).Add(AName);
    Result := WM_USER + AIndex + 1;
  finally
    TACLThreadList<TACLMessageHandler>(FHandlers).UnlockList;
  end;
end;

class procedure TACLMessaging.EnsureInitialized;
begin
  if FCustomMessages = nil then
  begin
    FCustomMessages := TACLStringList.Create;
    FHandlers := TACLThreadList<TACLMessageHandler>.Create;
    FHandle := WndCreate(WndProc, ClassName, True);
  end;
end;

class procedure TACLMessaging.WndProc(var AMessage: TMessage);
var
  AHandled: Boolean;
  AHandlers: TACLList<TACLMessageHandler>;
  I: Integer;
begin
  AHandlers := TACLThreadList<TACLMessageHandler>(FHandlers).LockList;
  try
    for I := AHandlers.Count - 1 downto 0 do
    begin
      AHandled := False;
      AHandlers[I](AMessage, AHandled);
      if AHandled then Exit;
    end;
    WndDefaultProc(FHandle, AMessage);
  finally
    TACLThreadList<TACLMessageHandler>(FHandlers).UnlockList;
  end;
end;

end.
