////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Web Authorization Utilities
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Web.Auth;

{$I ACL.Config.inc}

interface

uses
  {System.}Classes,
  {System.}Math,
  {System.}Variants,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Forms,
  // ACL
  ACL.Crypto,
  ACL.Graphics,
  ACL.Geometry,
  ACL.Threading,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Forms,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Shell,
  ACL.Utils.Strings,
  ACL.Web,
  ACL.Web.Http;

const
  sDefaultAuthRedirectURL = 'http://localhost:8090/';

type
  EAuthorizationError = class(EInvalidOperation);

  { TAuthToken }

  TAuthToken = record
    AccessToken: string;
    ExpiresIn: Integer; // seconds
    RefreshToken: string;
    Secret: string;

    constructor Create(const AAccessToken, ARefreshToken: string); overload;
    constructor Create(const AAccessToken, ARefreshToken, ASecret: string); overload;
    constructor CreateFromString(const AStr: string);
    function ToString: string;
    procedure Reset;
  end;

  { IAuthDialog }

  IAuthDialog = interface
  ['{1F04DDCD-C0E9-4503-9E8D-F578C214808D}']
    function Execute(AOwnerWnd: TWndHandle; out AToken: TAuthToken): Boolean;
  end;

  { IAuthDialogController }

  IAuthDialogController = interface
  ['{14F6244B-0C65-4BEB-BFDF-1F50CE520141}']
    function AuthGetHomeURL: string;
    function AuthGetRedirectURL: string;
    function AuthGetRequestURL: string;
    function AuthProcessAnswer(const AAnswer: string; out AToken: TAuthToken): Boolean;
  end;

  { TAuthDialog }

  TAuthDialog = class(TACLForm)
  strict private const
    DefaultCaption = 'Authorization Master';
    DefaultMessageText =
      'Waiting for authorization...' + acCRLF +
      'Please complete authorization request in your browser.' + acCRLF + acCRLF +
      'To cancel the operation just close the window.';
    ContentIndent = 12;
  strict private
    FController: IAuthDialogController;
    FHomeURL: string;
    FMessageText: string;
    FRedirectURL: string;
    FServer: TObject;
    FToken: TAuthToken;
    FUrl: TACLEdit;

    function HandlerGet(const UnparsedParams: string): string;
    procedure SendAuthRequest;
  protected
    procedure DblClick; override;
    procedure DoShow; override;
    procedure Paint; override;
  public
    constructor Create(AOwnerWnd: TWndHandle; AController: IAuthDialogController); reintroduce;
    destructor Destroy; override;
    class function Execute(AOwnerWnd: TWndHandle;
      const AController: IAuthDialogController; out AToken: TAuthToken;
      const ACaption: string = ''; const AMessageText: string = ''): Boolean;
  end;

  { TOAuth2 }

  TOAuth2 = class
  public type
    TGrandType = (gtAccessCode, gtRefreshToken);
    TParams = TACLWebParams;
  strict private
    class function Fetch(const AServiceURL: string; AParams: TParams): TBytesStream;
  public
    class procedure CheckForError(const AAnswerURL: string);
    class function ExtractAuthorizationCode(
      const AAnswerURL: string; const AParamName: string = 'code'): string;
    class function ExtractParam(const URL, AParam: string): string;
    class function FetchToken(const AServiceURL: string; AGrantType: TGrandType;
      const AGrantValue, AAppId, AAppSecret: string; AParams: TParams = nil): TAuthToken;
    class function ParseToken(AData: TBytesStream): TAuthToken;
  end;

implementation

uses
{$IFDEF FPC}
  fphttpserver,
  fpjson,
  jsonreader,
  jsonscanner,
  jsonparser;
{$ELSE}
  Windows,
  Winsock2,
  System.Json;
{$ENDIF}

type
  THandleProc = function (const AData: string): string of object;

  { TSimpleServer }

  TSimpleServer = class(TThread)
  strict private
  {$IFDEF MSWINDOWS}
    FPort: Integer;
    FSocket: TSocket;
    FWsaData: TWsaData;

    procedure CheckResult(ACode: Integer);
  {$ELSE}
  strict private
    FHandler: TFPHttpServer;
    procedure DoRequest(Sender: TObject;
      var ARequest: TFPHTTPConnectionRequest;
      var AResponse : TFPHTTPConnectionResponse);
  {$ENDIF}
  protected
    FProc: THandleProc;
    procedure Execute; override;
  public
    constructor Create(APort: Integer; AProc: THandleProc);
    destructor Destroy; override;
  end;

{$IFDEF MSWINDOWS}
function bind(s: TSocket; name: PSockAddr; namelen: Integer): Integer; stdcall; external 'ws2_32.dll' name 'bind';

{ TSimpleServer }

constructor TSimpleServer.Create(APort: Integer; AProc: THandleProc);
begin
  inherited Create(False);
  FPort := APort;
  FProc := AProc;
  CheckResult(WSAStartup(MakeWord(2, 2), FWsaData));
  FSocket := socket(AF_INET, SOCK_STREAM, 0);
  if FSocket = INVALID_SOCKET then
    raise EInvalidOperation.Create('Unable to create socket');
end;

destructor TSimpleServer.Destroy;
begin
  closesocket(FSocket);
  inherited;
  WSACleanup;
end;

procedure TSimpleServer.Execute;
const
  AnswerHeader = 'HTTP/1.1 200 OK'#13#10'Content-Type: text/html'#13#10#13#10;
  BufferLength = 4096;
  NumberOfConnections = 1;
var
  AAddress: TSockAddrIn;
  ABytes: TBytes;
  ABytesReceived: Integer;
  AData: string;
  ARequest: TSocket;
  AResponce: TBytes;
begin
  SetLength(ABytes, BufferLength);

  ZeroMemory(@AAddress, SizeOf(AAddress));
  AAddress.sin_addr.S_addr := INADDR_ANY;
  AAddress.sin_family := AF_INET;
  AAddress.sin_port := htons(FPort);
  CheckResult(bind(FSocket, @AAddress, SizeOf(AAddress)));

  CheckResult(listen(FSocket, NumberOfConnections));

  while not Terminated do
  begin
    ARequest := accept(FSocket, nil, nil);
    if ARequest <> INVALID_SOCKET then
    try
      ABytesReceived := recv(ARequest, ABytes[0], Length(ABytes), 0);
      if ABytesReceived > 0 then
      begin
        AData := TEncoding.UTF8.GetString(ABytes, 0, ABytesReceived);
        AData := Copy(AData, 1, Pos(' HTTP/', AData) - 1);
        AData := AnswerHeader + FProc(AData);
        AResponce := TEncoding.UTF8.GetBytes(AData);
        send(ARequest, AResponce[0], Length(AResponce), 0);
      end;
    finally
      closesocket(ARequest);
    end;
  end;
end;

procedure TSimpleServer.CheckResult(ACode: Integer);
begin
  if ACode = SOCKET_ERROR then
    RaiseLastOSError;
end;

{$ELSE}

type
  TFPHttpServer2 = class(TFPHttpServer);

{ TSimpleServer }

constructor TSimpleServer.Create(APort: Integer; AProc: THandleProc);
begin
  inherited Create(False);
  FProc := AProc;
  FHandler := TFPHttpServer.Create(nil);
  FHandler.OnRequest := DoRequest;
  FHandler.Port := APort;
end;

destructor TSimpleServer.Destroy;
begin
  TFPHttpServer2(FHandler).Active := False;
  TFPHttpServer2(FHandler).FreeServerSocket;
  inherited Destroy;
  FreeAndNil(FHandler);
end;

procedure TSimpleServer.DoRequest(Sender: TObject;
  var ARequest: TFPHTTPConnectionRequest;
  var AResponse: TFPHTTPConnectionResponse);
begin
  AResponse.Content := FProc(ARequest.Content);
end;

procedure TSimpleServer.Execute;
begin
  FHandler.Active := True;
end;
{$ENDIF}

{ TAuthToken }

constructor TAuthToken.Create(const AAccessToken, ARefreshToken: string);
begin
  Create(AAccessToken, ARefreshToken, '');
end;

constructor TAuthToken.Create(const AAccessToken, ARefreshToken, ASecret: string);
begin
  Reset;
  AccessToken := AAccessToken;
  RefreshToken := ARefreshToken;
  Secret := ASecret;
end;

constructor TAuthToken.CreateFromString(const AStr: string);
var
  LData: UnicodeString;
  LParts: TStringDynArray;
begin
  Reset;
  LData := TEncoding.UTF8.GetString(TACLMimecode.DecodeBytes(AStr));
  acCryptStringXOR(LData, 'TAuthToken');
  acExplodeString(acString(LData), #9, LParts);
  if Length(LParts) > 3 then
  begin
    AccessToken := LParts[0];
    RefreshToken := LParts[1];
    Secret := LParts[2];
    ExpiresIn := StrToIntDef(LParts[3], 0);
  end;
end;

procedure TAuthToken.Reset;
begin
  Secret := '';
  AccessToken := '';
  ExpiresIn := 0;
  RefreshToken := '';
end;

function TAuthToken.ToString: string;
var
  LEncrypted: UnicodeString;
begin
  Result := AccessToken + #9 + RefreshToken + #9 + Secret + #9 + IntToStr(ExpiresIn);
  LEncrypted := acUString(Result);
  acCryptStringXOR(LEncrypted, 'TAuthToken');
  Result := TACLMimecode.EncodeBytes(TEncoding.UTF8.GetBytes(LEncrypted));
end;

{ TOAuth2 }

class procedure TOAuth2.CheckForError(const AAnswerURL: string);
var
  AError: string;
begin
  AError := ExtractParam(AAnswerURL, 'error');
  if AError <> '' then
    raise EInvalidOperation.Create(AError + acCRLF + ExtractParam(AAnswerURL, 'error_description'));
end;

class function TOAuth2.ExtractAuthorizationCode(const AAnswerURL: string; const AParamName: string = 'code'): string;
begin
  CheckForError(AAnswerURL);
  Result := ExtractParam(AAnswerURL, AParamName);
  if Result = '' then
    raise EInvalidArgument.Create(AAnswerURL);
end;

class function TOAuth2.ExtractParam(const URL, AParam: string): string;
var
  APos, APosEnd: Integer;
begin
  APos := acPos(AParam + '=', URL);
  if APos > 0 then
  begin
    APos := APos + Length(AParam) + 1;
    APosEnd := acPos('&', URL, False, APos + 1);
    if APosEnd = 0 then
      APosEnd := Length(URL) + 1;
    Result := acURLDecode(Copy(URL, APos, APosEnd - APos));
  end
  else
    Result := '';
end;

class function TOAuth2.FetchToken(const AServiceURL: string; AGrantType: TGrandType;
  const AGrantValue, AAppId, AAppSecret: string; AParams: TParams = nil): TAuthToken;
const
  TypeMap: array[TGrandType] of string = ('authorization_code', 'refresh_token');
  ValueMap: array[TGrandType] of string = ('code', 'refresh_token');
var
  AData: TBytesStream;
begin
  AParams := AParams.Add('grant_type', TypeMap[AGrantType]);
  AParams := AParams.Add(ValueMap[AGrantType], AGrantValue);
  AParams := AParams.Add('client_id', AAppId);
  AParams := AParams.Add('client_secret', AAppSecret);

  AData := Fetch(AServiceURL, AParams);
  try
    Result := ParseToken(AData);
  finally
    AData.Free;
  end;
end;

class function TOAuth2.Fetch(const AServiceURL: string; AParams: TParams): TBytesStream;
begin
  Result := TBytesStream.Create;
  try
    try
      TACLHttp.RaiseOnError(
        TACLHttp.Post(AServiceURL).
          OnPost(acStringToUtf8(AParams.ToString)).
          OnData(Result).RunNoThread);
      Result.Position := 0;
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    AParams.Free;
  end;
end;

class function TOAuth2.ParseToken(AData: TBytesStream): TAuthToken;

  function CreateJSONObject(AData: TBytesStream): TJSONObject;
  begin
  {$IFDEF FPC}
    with TJSONParser.Create(AData, [joUTF8]) do
    try
      Result := Parse as TJSONObject;
    finally
      Free;
    end;
  {$ELSE}
    Result := TJSONObject.Create;
    Result.Parse(AData.Bytes, 0);
  {$ENDIF}
  end;

  function TryGetValue(Json: TJSONObject; const Name: string): string;
  begin
  {$IFDEF FPC}
    Result := VarToStr(Json.Get(Name));
  {$ELSE}
    Result := Json.GetValue<string>(Name, '');
  {$ENDIF}
  end;

var
  LErrorText: string;
  LObject: TJSONObject;
begin
//{$IFDEF DEBUG}
//  AData.SaveToFile('B:\OAuth2.log');
//{$ENDIF}
  LObject := CreateJSONObject(AData);
  try
    Result.AccessToken := TryGetValue(LObject, 'access_token');
    Result.RefreshToken := TryGetValue(LObject, 'refresh_token');
    Result.ExpiresIn := StrToIntDef(TryGetValue(LObject, 'expires_in'), 0);
    LErrorText := TryGetValue(LObject, 'error');
    if LErrorText <> '' then
      raise EAuthorizationError.Create(LErrorText);
  finally
    LObject.Free;
  end;
end;

{ TAuthDialog }

constructor TAuthDialog.Create(AOwnerWnd: TWndHandle; AController: IAuthDialogController);
begin
  CreateDialog(AOwnerWnd, True);
  BorderStyle := bsDialog;
  Position := poMainFormCenter;
  SetBounds(Left, Top, 512, 160);

  FController := AController;
  FRedirectURL := FController.AuthGetRedirectURL;
  FHomeURL := FController.AuthGetHomeURL;

  FUrl := TACLEdit.Create(Self);
  FUrl.AlignWithMargins := True;
  FUrl.Align := alBottom;
  FUrl.Margins.All := ContentIndent;
  FUrl.ReadOnly := True;
  FUrl.Parent := Self;
  FUrl.Visible := False;

  FServer := TSimpleServer.Create(TACLWebURL.ParseHttp(FRedirectURL).Port, HandlerGet);
end;

destructor TAuthDialog.Destroy;
begin
  TACLMainThread.Unsubscribe(Self);
  FreeAndNil(FServer);
  inherited;
end;

procedure TAuthDialog.DblClick;
begin
  inherited;
  FUrl.Visible := True;
end;

procedure TAuthDialog.DoShow;
begin
  inherited;
  TACLMainThread.RunPostponed(SendAuthRequest, Self);
end;

procedure TAuthDialog.Paint;
begin
  inherited Paint;
  Canvas.Font := Font;
  Canvas.Font.Color := Style.ColorText.AsColor;
  acTextDraw(Canvas, FMessageText,
    ClientRect.InflateTo(-dpiApply(ContentIndent, FCurrentPPI)),
    taLeftJustify, taVerticalCenter, False, False, True);
end;

class function TAuthDialog.Execute(AOwnerWnd: TWndHandle;
  const AController: IAuthDialogController; out AToken: TAuthToken;
  const ACaption: string = ''; const AMessageText: string = ''): Boolean;
var
  ADialog: TAuthDialog;
begin
  ADialog := TAuthDialog.Create(AOwnerWnd, AController);
  try
    ADialog.Caption := IfThenW(ACaption, DefaultCaption);
    ADialog.FMessageText := IfThenW(AMessageText, DefaultMessageText);
    Result := ADialog.ShowModal = mrOk;
    if Result then
      AToken := ADialog.FToken;
  finally
    ADialog.Free;
  end;
end;

function TAuthDialog.HandlerGet(const UnparsedParams: string): string;
begin
  if ModalResult = mrNone then
  try
    if FController.AuthProcessAnswer(UnparsedParams, FToken) then
      ModalResult := mrOk;
  except
    // do nothing
  end;

  Result :=
    '<html>' +
    '  <head>' +
    '    <meta http-equiv="refresh" content="3;url=' + FHomeURL + '">' +
    '  </head>' +
    '  <body>' +
    '     Please return to the app.' +
    '  </body>' +
    '</html>';
end;

procedure TAuthDialog.SendAuthRequest;
var
  LUrl: string;
begin
  LUrl := FController.AuthGetRequestURL;
  FUrl.Text := LUrl;
  ShellExecuteURL(LUrl);
end;

end.
