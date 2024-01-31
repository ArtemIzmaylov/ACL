{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*             Messaging Routines            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.Messaging;

{$I ACL.Config.inc} // FPC:OK

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
  {System.}Classes;

type
{$IFDEF FPC}
  TWndMethod = TLCLWndMethod;
{$ENDIF}

  { TACLMessaging }

  TACLMessageHandler = procedure (var AMessage: TMessage; var AHandled: Boolean) of object;

  TACLMessaging = class sealed
  strict private
    class var FCustomMessages: TObject;
    class var FHandle: HWND;
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
    class property Handle: HWND read FHandle;
  end;

{$IFNDEF FPC}

  { TMessagesHelper }

  TMessagesHelper = class
  public
    class function IsInQueue(AWndHandle: HWND; AMessage: Cardinal): Boolean;
    class procedure Process(AFromMessage, AToMessage: Cardinal; AWndHandle: HWND = 0); overload;
    class procedure Process(AMessage: Cardinal; AWndHandle: HWND = 0); overload;
    class procedure Remove(AMessage: Cardinal; AWndHandle: HWND = 0);
  end;

{$ENDIF}

function WndCreate(Method: TWndMethod; const ClassName: string;
  IsMessageOnly: Boolean = False; const Name: string = ''): HWND;
procedure WndDefaultProc(W: HWND; var Message: TMessage);
procedure WndFree(W: HWND);
implementation

uses
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // ACL
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Threading;

{$IFDEF FPC}

function WndCreate(Method: TWndMethod; const ClassName: string;
  IsMessageOnly: Boolean; const Name: string): HWND;
begin
  if not IsMainThread then
    raise EInvalidOperation.Create('Cannot create window in non-main thread');
  Result := AllocateHWnd(Method);
  if Result = 0 then
    raise ENotImplemented.Create('AllocateHWnd is not implemented for this platform');
end;

procedure WndDefaultProc(W: HWND; var Message: TMessage);
begin
  // do nothing
end;

procedure WndFree(W: HWND);
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
  IsMessageOnly: Boolean = False; const Name: string = ''): HWND;
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

procedure WndDefaultProc(W: HWND; var Message: TMessage);
begin
  Message.Result := DefWindowProc(W, Message.Msg, Message.WParam, Message.LParam);
end;

procedure WndFree(W: HWND);
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

{ TMessagesHelper }

class function TMessagesHelper.IsInQueue(AWndHandle: HWND; AMessage: Cardinal): Boolean;
var
  AMsg: TMSG;
begin
  Result := PeekMessage(AMsg, AWndHandle, AMessage, AMessage, PM_NOREMOVE) and (AMsg.hwnd = AWndHandle);
end;

class procedure TMessagesHelper.Process(AFromMessage, AToMessage: Cardinal; AWndHandle: HWND = 0);
var
  AMsg: TMsg;
begin
  while PeekMessage(AMsg, AWndHandle, AFromMessage, AToMessage, PM_REMOVE) do
  begin
    TranslateMessage(AMsg);
    DispatchMessage(AMsg);
  end;
end;

class procedure TMessagesHelper.Process(AMessage: Cardinal; AWndHandle: HWND = 0);
begin
  Process(AMessage, AMessage, AWndHandle);
end;

class procedure TMessagesHelper.Remove(AMessage: Cardinal; AWndHandle: HWND = 0);
var
  AMsg: TMsg;
begin
  while PeekMessage(AMsg, AWndHandle, AMessage, AMessage, PM_REMOVE) do ;
end;

{$ENDIF}

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
{$IFDEF FPC}
  LCLIntf.PostMessage(FHandle, AMessage, AParamW, AParamL);
{$ELSE}
  {Winapi.}Windows.PostMessage(FHandle, AMessage, AParamW, AParamL);
{$ENDIF}
end;

class procedure TACLMessaging.SendMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
begin
{$IFDEF FPC}
  TThread.Synchronize(nil,
    procedure
    begin
      LCLIntf.SendMessage(FHandle, AMessage, AParamW, AParamL);
    end);
{$ELSE}
  {Winapi.}Windows.SendMessage(FHandle, AMessage, AParamW, AParamL);
{$ENDIF}
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
