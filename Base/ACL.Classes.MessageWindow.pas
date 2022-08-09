{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*          Message Window Routines          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Classes.MessageWindow;

{$I ACL.Config.INC}

interface

uses
  Winapi.Messages,
  Winapi.Windows,
  // System
  System.Types,
  System.Classes,
  System.SysUtils,
  System.Contnrs,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Threading,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type

  { TACLCustomMessageWindow }

  TACLCustomMessageWindow = class
  strict private
    FHandle: HWND;

    procedure WndProc(var AMessage: TMessage);
  protected
    FLock: TACLCriticalSection;

    function SafeProcessMessage(var AMessage: TMessage): Boolean; virtual; abstract;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    // Messages
    procedure PostMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
    procedure SendMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
    //
    property Handle: HWND read FHandle;
  end;

  { TACLMessageWindow }

  TACLMessageWindowHandler = procedure (var AMessage: TMessage; var AHandled: Boolean) of object;

  TACLMessageWindow = class(TACLCustomMessageWindow)
  strict private
    FCustomMessages: TACLStringList;
    FHandlers: TACLList<TACLMessageWindowHandler>;
  protected
    function SafeProcessMessage(var AMessage: TMessage): Boolean; override;
  public
    constructor Create;
    destructor Destroy; override;
    // Handlers
    procedure HandlerAdd(AHandler: TACLMessageWindowHandler);
    procedure HandlerRemove(AHandler: TACLMessageWindowHandler);
    // Messages
    function RegisterMessage(const AName: UnicodeString): Cardinal;
  end;

function MessageWindow: TACLMessageWindow;
implementation

var
  FMessageWindow: TACLMessageWindow;

function MessageWindow: TACLMessageWindow;
begin
  Result := FMessageWindow;
end;

{ TACLCustomMessageWindow }

procedure TACLCustomMessageWindow.AfterConstruction;
begin
  inherited AfterConstruction;
  FLock := TACLCriticalSection.Create(Self);
  FHandle := WndCreateMsg(WndProc, ClassName);
end;

procedure TACLCustomMessageWindow.BeforeDestruction;
begin
  inherited BeforeDestruction;
  if FHandle <> 0 then
  begin
    WndFree(FHandle);
    FHandle := 0;
  end;
  FreeAndNil(FLock);
end;

procedure TACLCustomMessageWindow.PostMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
begin
  Winapi.Windows.PostMessage(Handle, AMessage, AParamW, AParamL);
end;

procedure TACLCustomMessageWindow.SendMessage(AMessage: Cardinal; AParamW: WPARAM; AParamL: LPARAM);
begin
  Winapi.Windows.SendMessage(Handle, AMessage, AParamW, AParamL);
end;

procedure TACLCustomMessageWindow.WndProc(var AMessage: TMessage);
begin
  FLock.Enter;
  try
    if not SafeProcessMessage(AMessage) then
      WndDefaultProc(Handle, AMessage);
  finally
    FLock.Leave;
  end;
end;

{ TACLMessageWindow }

constructor TACLMessageWindow.Create;
begin
  inherited Create;
  FCustomMessages := TACLStringList.Create;
  FHandlers := TACLList<TACLMessageWindowHandler>.Create;
end;

destructor TACLMessageWindow.Destroy;
begin
  FreeAndNil(FCustomMessages);
  FreeAndNil(FHandlers);
  inherited Destroy;
end;

procedure TACLMessageWindow.HandlerAdd(AHandler: TACLMessageWindowHandler);
begin
  FLock.Enter;
  try
    FHandlers.Add(AHandler);
  finally
    FLock.Leave;
  end;
end;

procedure TACLMessageWindow.HandlerRemove(AHandler: TACLMessageWindowHandler);
begin
  FLock.Enter;
  try
    FHandlers.Remove(AHandler);
  finally
    FLock.Leave;
  end;
end;

function TACLMessageWindow.SafeProcessMessage(var AMessage: TMessage): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := FHandlers.Count - 1 downto 0 do
  begin
    FHandlers[I](AMessage, Result);
    if Result then Break;
  end;
end;

function TACLMessageWindow.RegisterMessage(const AName: UnicodeString): Cardinal;
var
  AIndex: Integer;
begin
  FLock.Enter;
  try
    AIndex := FCustomMessages.IndexOf(AName);
    if AIndex < 0 then
      AIndex := FCustomMessages.Add(AName);
    Result := WM_USER + AIndex + 1;
  finally
    FLock.Leave;
  end;
end;

initialization
  FMessageWindow := TACLMessageWindow.Create;

finalization
  FreeAndNil(FMessageWindow);
end.
