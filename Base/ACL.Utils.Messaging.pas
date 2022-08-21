{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*             Messaging Routines            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.Messaging;

{$I ACL.Config.INC}

interface

uses
  Winapi.Messages,
  Winapi.Windows,
  // System
  System.Classes;

type

  { TMessagesHelper }

  TMessagesHelper = class
  public
    class function IsInQueue(AWndHandle: HWND; AMessage: Cardinal): Boolean;
    class procedure Process(AFromMessage, AToMessage: Cardinal; AWndHandle: HWND = 0); overload;
    class procedure Process(AMessage: Cardinal; AWndHandle: HWND = 0); overload;
    class procedure Remove(AMessage: Cardinal; AWndHandle: HWND = 0);
  end;

  { TACLMessageWindow }

  TACLMessageWindow = class
  protected
    FHandle: HWND;

    procedure HandleMessage(var AMessage: TMessage); dynamic;
  public
    constructor Create(const AClassName, AName: string);
    constructor CreateMsg(const AClassName: string);
    destructor Destroy; override;
    procedure PostMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
    procedure SendMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
  end;

  { TACLMessaging }

  TACLMessageHandler = procedure (var AMessage: TMessage; var AHandled: Boolean) of object;

  TACLMessaging = class sealed
  strict private
    class var FCustomMessages: TObject;
    class var FHandle: HWND;
    class var FHandlers: TObject;

    class procedure WndProc(var AMessage: TMessage);
  public
    class constructor Create;
    class destructor Destroy;
    // Handlers
    class procedure HandlerAdd(AHandler: TACLMessageHandler);
    class procedure HandlerRemove(AHandler: TACLMessageHandler);
    // Messages
    class function RegisterMessage(const AName: UnicodeString): Cardinal;
    class procedure PostMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
    class procedure SendMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
    // Properties
    class property Handle: HWND read FHandle;
  end;

function WndCreate(Method: TWndMethod; const ClassName: string; const Name: string = ''): HWND;
function WndCreateMsg(Method: TWndMethod; const ClassName: string): HWND;
procedure WndDefaultProc(W: HWND; var Message: TMessage);
procedure WndFree(W: HWND);
implementation

uses
  System.Math,
  System.SysUtils,
  System.Types,
  // ACL
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Threading;

var
  UtilWindowClass: TWndClass = (Style: 0; lpfnWndProc: @DefWindowProc;
    cbClsExtra: 0; cbWndExtra: 0; hInstance: 0; hIcon: 0; hCursor: 0;
    hbrBackground: 0; lpszMenuName: nil; lpszClassName: 'TPUtilWindow');
  UtilWindowClassName: string;

function acWndCreate(Method: TWndMethod; const ClassName, Name: string; IsMessageWindow: Boolean): HWND;
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
      Winapi.Windows.UnregisterClass(UtilWindowClass.lpszClassName, HInstance);
    Winapi.Windows.RegisterClass(UtilWindowClass);
  end;
  Result := CreateWindowEx(WS_EX_TOOLWINDOW, UtilWindowClass.lpszClassName, PChar(Name),
    WS_POPUP {!0}, 0, 0, 0, 0, IfThen(IsMessageWindow, HWND_MESSAGE), 0, HInstance, nil);
  if Assigned(Method) then
    SetWindowLong(Result, GWL_WNDPROC, NativeUInt(System.Classes.MakeObjectInstance(Method)));
end;

function WndCreate(Method: TWndMethod; const ClassName, Name: string): HWND;
begin
  Result := acWndCreate(Method, ClassName, Name, False);
end;

function WndCreateMsg(Method: TWndMethod; const ClassName: string): HWND;
begin
  Result := acWndCreate(Method, ClassName, '', True)
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

{ TACLMessageWindow }

constructor TACLMessageWindow.Create(const AClassName, AName: string);
begin
  FHandle := acWndCreate(HandleMessage, AClassName, AName, False);
end;

constructor TACLMessageWindow.CreateMsg(const AClassName: string);
begin
  FHandle := acWndCreate(HandleMessage, AClassName, EmptyStr, True);
end;

destructor TACLMessageWindow.Destroy;
begin
  WndFree(FHandle);
  inherited;
end;

procedure TACLMessageWindow.HandleMessage(var AMessage: TMessage);
begin
  AMessage.Result := DefWindowProc(FHandle, AMessage.Msg, AMessage.WParam, AMessage.LParam);
end;

procedure TACLMessageWindow.PostMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
begin
  Winapi.Windows.PostMessage(FHandle, AMessage, AParamW, AParamL);
end;

procedure TACLMessageWindow.SendMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
begin
  Winapi.Windows.SendMessage(FHandle, AMessage, AParamW, AParamL);
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

{ TACLMessaging }

class constructor TACLMessaging.Create;
begin
  FCustomMessages := TACLStringList.Create;
  FHandlers := TACLList<TACLMessageHandler>.Create;
  FHandle := WndCreateMsg(WndProc, ClassName);
end;

class destructor TACLMessaging.Destroy;
begin
  WndFree(FHandle);
  FreeAndNil(FCustomMessages);
  FreeAndNil(FHandlers);
end;

class procedure TACLMessaging.HandlerAdd(AHandler: TACLMessageHandler);
begin
  TMonitor.Enter(FHandlers);
  try
    TACLList<TACLMessageHandler>(FHandlers).Add(AHandler);
  finally
    TMonitor.Exit(FHandlers);
  end;
end;

class procedure TACLMessaging.HandlerRemove(AHandler: TACLMessageHandler);
begin
  TMonitor.Enter(FHandlers);
  try
    TACLList<TACLMessageHandler>(FHandlers).Remove(AHandler);
  finally
    TMonitor.Exit(FHandlers);
  end;
end;

class procedure TACLMessaging.PostMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
begin
  Winapi.Windows.PostMessage(FHandle, AMessage, AParamW, AParamL);
end;

class procedure TACLMessaging.SendMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
begin
  Winapi.Windows.SendMessage(FHandle, AMessage, AParamW, AParamL);
end;

class function TACLMessaging.RegisterMessage(const AName: UnicodeString): Cardinal;
var
  AIndex: Integer;
begin
  TMonitor.Enter(FHandlers);
  try
    AIndex := TACLStringList(FCustomMessages).IndexOf(AName);
    if AIndex < 0 then
      AIndex := TACLStringList(FCustomMessages).Add(AName);
    Result := WM_USER + AIndex + 1;
  finally
    TMonitor.Exit(FHandlers);
  end;
end;

class procedure TACLMessaging.WndProc(var AMessage: TMessage);
var
  AHandled: Boolean;
  AHandlers: TACLList<TACLMessageHandler>;
  I: Integer;
begin
  TMonitor.Enter(FHandlers);
  try
    AHandlers := TACLList<TACLMessageHandler>(FHandlers);
    for I := AHandlers.Count - 1 downto 0 do
    begin
      AHandled := False;
      AHandlers[I](AMessage, AHandled);
      if AHandled then Exit;
    end;
    WndDefaultProc(FHandle, AMessage);
  finally
    TMonitor.Exit(FHandlers);
  end;
end;

end.
