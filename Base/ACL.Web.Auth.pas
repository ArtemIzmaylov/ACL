////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Web Authorization Utilities
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Web.Auth;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  fphttpserver,
{$ELSE}
  Windows,
  Winsock2,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}Variants,
  {System.}SysUtils,
  {System.}Types,
  System.JSON,
  // ACL
  ACL.Crypto,
  ACL.Utils.Common,
  ACL.Utils.Strings,
  ACL.Web,
  ACL.Web.Http;

const
  acDefaultAuthRedirectURL = 'http://localhost:8090/';

type
  EAuthorizationError = class(EInvalidOperation);

  { TAuthToken }

  PAuthToken = ^TAuthToken;
  TAuthToken = record
    AccessToken: string;
    ExpiresIn: Integer; // seconds
    RefreshToken: string;
    Secret: string;

    class function Create(const AAccessToken, ARefreshToken, ASecret: string): TAuthToken; static;
    class function CreateFromString(const AStr: string): TAuthToken; static;
    function ToString: string;
    procedure Reset;
  end;

  { TAuthServer }

  TAuthServer = class(TThread)
  public type
    THandler = procedure (const UnparsedParams: string) of object;
  strict private
    FCallback: THandler;
    FHomeUrl: string;
  {$IFDEF MSWINDOWS}
    FPort: Integer;
    FSocket: TSocket;
    FWsaData: TWsaData;
    procedure CheckResult(ACode: Integer);
  {$ELSE}
    FHandler: TFPHttpServer;
    procedure DoRequest(Sender: TObject;
      var ARequest: TFPHTTPConnectionRequest;
      var AResponse : TFPHTTPConnectionResponse);
  {$ENDIF}
    function GetResponce(const UnparsedParams: string): string;
  protected
    procedure Execute; override;
  public
    constructor Create(APort: Integer;
      const ACallback: THandler;
      const AHomeUrl: string = '');
    destructor Destroy; override;
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

  { JSON }

  TJSONValueClass = class of TJSONValue;

  JSON = class
  public
    class function GetString(Obj: TJSONValue;
      const Name: string): string;
    class procedure GetValue(Obj: TJSONValue;
      const Name: string; ValueClass: TJSONValueClass; out Value);
    class function TryGetString(Obj: TJSONValue;
      const Name: string; out Value: string): Boolean;
    class function TryGetValue(Obj: TJSONValue;
      const Name: string; ValueClass: TJSONValueClass; out Value): Boolean;
    class function TryLoad(AStream: TStream): TJSONValue;
  end;

implementation

{ TAuthToken }

class function TAuthToken.Create(const AAccessToken, ARefreshToken, ASecret: string): TAuthToken;
begin
  Result.AccessToken := AAccessToken;
  Result.RefreshToken := ARefreshToken;
  Result.Secret := ASecret;
  Result.ExpiresIn := 0;
end;

class function TAuthToken.CreateFromString(const AStr: string): TAuthToken;
var
  LData: UnicodeString;
  LParts: TStringDynArray;
begin
  Result.Reset;
  LData := TACLMimecode.DecodeString(AStr);
  acCryptStringXOR(LData, 'TAuthToken');
  acSplitString(acString(LData), #9, LParts);
  if Length(LParts) > 3 then
  begin
    Result.AccessToken := LParts[0];
    Result.RefreshToken := LParts[1];
    Result.Secret := LParts[2];
    Result.ExpiresIn := StrToIntDef(LParts[3], 0);
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
  Result := TACLMimecode.EncodeString(LEncrypted);
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

class function TOAuth2.ExtractAuthorizationCode(
  const AAnswerURL: string; const AParamName: string = 'code'): string;
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
var
  LErrorText: string;
  LObject: TJSONObject;
begin
//{$IFDEF DEBUG}
//  AData.SaveToFile('B:\OAuth2.log');
//{$ENDIF}
  LObject := TJSONObject.Create;
  try
    LObject.Parse(AData.Bytes, 0);
    Result.AccessToken := JSON.GetString(LObject, 'access_token');
    Result.RefreshToken := JSON.GetString(LObject, 'refresh_token');
    Result.ExpiresIn := StrToIntDef(JSON.GetString(LObject, 'expires_in'), 0);
    if JSON.TryGetString(LObject, 'error', LErrorText) and (LErrorText <> '') then
      raise EAuthorizationError.Create(LErrorText);
  finally
    LObject.Free;
  end;
end;

{ JSON }

class function JSON.GetString(Obj: TJSONValue; const Name: string): string;
begin
  if not TryGetString(Obj, Name, Result) then
    Result := '';
end;

class procedure JSON.GetValue(Obj: TJSONValue;
  const Name: string; ValueClass: TJSONValueClass; out Value);
begin
  if not TryGetValue(Obj, Name, ValueClass, Value) then
    TObject(Value) := nil;
end;

class function JSON.TryGetString(Obj: TJSONValue;
  const Name: string; out Value: string): Boolean;
var
  LValue: TJSONValue;
begin
  Result := TryGetValue(Obj, Name, TJSONValue, LValue);
  if Result then
    Value := acString(LValue.Value);
end;

class function JSON.TryGetValue(Obj: TJSONValue; const Name: string;
  ValueClass: TJSONValueClass; out Value): Boolean;
var
  LValue: TJSONValue;
begin
  if Obj is TJSONObject then
    LValue := TJSONObject(Obj).GetValue(acUString(Name))
  else if Obj <> nil then
    LValue := Obj.FindValue(acUString(Name))
  else
    LValue := nil;

  Result := (LValue <> nil) and LValue.InheritsFrom(ValueClass);
  if Result then
    TObject(Value) := LValue;
end;

class function JSON.TryLoad(AStream: TStream): TJSONValue;
var
  LData: TBytes;
begin
  if AStream is TBytesStream then
    Result := TJSONObject.ParseJSONValue(TBytesStream(AStream).Bytes, 0, AStream.Size)
  else
  begin
    SetLength(LData, AStream.Size);
    AStream.Position := 0;
    AStream.ReadBuffer(LData, Length(LData));
    Result := TJSONObject.ParseJSONValue(LData, 0, Length(LData));
  end;
end;

{$IFDEF MSWINDOWS}
function bind(s: TSocket; name: PSockAddr; namelen: Integer): Integer; stdcall; external 'ws2_32.dll' name 'bind';

{ TAuthServer }

constructor TAuthServer.Create(APort: Integer;
  const ACallback: THandler;
  const AHomeUrl: string = '');
begin
  inherited Create(False);
  FCallback := ACallback;
  FHomeUrl := AHomeUrl;
  FPort := APort;

  CheckResult(WSAStartup(MakeWord(2, 2), FWsaData));
  FSocket := socket(AF_INET, SOCK_STREAM, 0);
  if FSocket = INVALID_SOCKET then
    raise EInvalidOperation.Create('Unable to create socket');
end;

destructor TAuthServer.Destroy;
begin
  closesocket(FSocket);
  inherited;
  WSACleanup;
end;

procedure TAuthServer.Execute;
const
  AnswerHeader = 'HTTP/1.1 200 OK'#13#10'Content-Type: text/html'#13#10#13#10;
  BufferLength = 4096;
  NumberOfConnections = 1;
var
  LAddress: TSockAddrIn;
  LBytes: TBytes;
  LBytesReceived: Integer;
  LData: string;
  LRequest: TSocket;
  LResponce: TBytes;
begin
  SetLength(LBytes, BufferLength);

  ZeroMemory(@LAddress, SizeOf(LAddress));
  LAddress.sin_addr.S_addr := INADDR_ANY;
  LAddress.sin_family := AF_INET;
  LAddress.sin_port := htons(FPort);
  CheckResult(bind(FSocket, @LAddress, SizeOf(LAddress)));

  CheckResult(listen(FSocket, NumberOfConnections));

  while not Terminated do
  begin
    LRequest := accept(FSocket, nil, nil);
    if LRequest <> INVALID_SOCKET then
    try
      LBytesReceived := recv(LRequest, LBytes[0], Length(LBytes), 0);
      if LBytesReceived > 0 then
      begin
        LData := TEncoding.UTF8.GetString(LBytes, 0, LBytesReceived);
        LData := Copy(LData, 1, Pos(' HTTP/', LData) - 1);
        LData := AnswerHeader + GetResponce(LData);
        LResponce := TEncoding.UTF8.GetBytes(LData);
        send(LRequest, LResponce[0], Length(LResponce), 0);
      end;
    finally
      closesocket(LRequest);
    end;
  end;
end;

procedure TAuthServer.CheckResult(ACode: Integer);
begin
  if ACode = SOCKET_ERROR then
    RaiseLastOSError;
end;

{$ELSE}

type
  TFPHttpServer2 = class(TFPHttpServer);

{ TAuthServer }

constructor TAuthServer.Create(APort: Integer;
  const ACallback: THandler; const AHomeUrl: string = '');
begin
  inherited Create(False);
  FCallback := ACallback;
  FHomeUrl := AHomeUrl;
  FHandler := TFPHttpServer2.Create(nil);
  FHandler.OnRequest := DoRequest;
  FHandler.Port := APort;
end;

destructor TAuthServer.Destroy;
begin
  TFPHttpServer2(FHandler).Active := False;
  TFPHttpServer2(FHandler).FreeServerSocket;
  inherited Destroy;
  FreeAndNil(FHandler);
end;

procedure TAuthServer.DoRequest(Sender: TObject;
  var ARequest: TFPHTTPConnectionRequest;
  var AResponse: TFPHTTPConnectionResponse);
begin
  AResponse.Content := GetResponce(ARequest.Query);
end;

procedure TAuthServer.Execute;
begin
  FHandler.Active := True;
end;
{$ENDIF}

function TAuthServer.GetResponce(const UnparsedParams: string): string;
var
  LError: string;
begin
  try
    FCallback(UnparsedParams);
    LError := '';
  except
    on E: Exception do
      LError := E.Message;
  end;

  if FHomeUrl <> '' then
    Result := '<head><meta http-equiv="refresh" content="3;url=' + FHomeUrl + '"></head>'
  else
    Result := '';

  if LError <> '' then
    LError := '<font color="red">' + LError + '</font><br/><br/>';

  Result := '<html>' + Result + '<body>' + LError + 'Please return to the app</body></html>';
end;

end.
