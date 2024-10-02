////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Http Client
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Web.Http;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.Windows,
  Winapi.WinInet,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // ACL
  ACL.Classes,
  ACL.Classes.ByteBuffer,
  ACL.Classes.Collections,
  ACL.Threading,
  ACL.Threading.Pool,
  ACL.Utils.Common,
  ACL.Web;

type

{$REGION ' Http Basics '}

  { EHttpError }

  EHttpError = class(EACLWebError)
  public
    constructor Create(const DefaultText: string = ''); overload;
  end;

  { EHttpWriteError }

  EHttpWriteError = class(EHttpError)
  public
    constructor Create; reintroduce;
  end;

  { THttpResponse }

  THttpResponse = record
    ContentLength: Int64;
    ContentRange: string;
    ContentType: string;
    RawHeaders: string;
    StatusCode: Integer;
    StatusText: string;
    procedure Init;
    function StatusIsOk: Boolean;
  end;

  { THttpConnection }

  THttpAcceptProc = reference to function (const AResponse: THttpResponse): Boolean;
  THttpDataProc = reference to function (Data: PByte; Count: Integer): Boolean;
  THttpProgressProc = reference to function (const APosition, ASize: Int64): Boolean;

  THttpConnection = class
  strict private
  {$IFNDEF FPC}
    FHandle: HINTERNET;
    FSession: HINTERNET;
  {$ENDIF}
    FURL: TACLWebURL;

    procedure RequestCore(
      AMethod, AHeaders: string;
      var AResponse: THttpResponse;
      APostData: TStream = nil;
      AOnAccept: THttpAcceptProc = nil;
      AOnProgress: THttpProgressProc = nil;
      AOnReceive: THttpDataProc = nil);
  public
    constructor Create(const URL: TACLWebURL);
    destructor Destroy; override;
    function Request(const AMethod: string;
      ARange: IACLWebRequestRange = nil;
      APostData: TStream = nil;
      AOnAccept: THttpAcceptProc = nil;
      AOnProgress: THttpProgressProc = nil;
      AOnReceive: THttpDataProc = nil): THttpResponse;
    property URL: TACLWebURL read FURL;
  end;

  { THttpHeaders }

  THttpHeaders = class
  public const
    Delimiter = ': ';
  protected
    class function Get(const AHeaders, AName: string;
      out AValue: string; out APosStart, APosFinish: Integer): Boolean; overload;
  public
    class function Contains(const AHeaders, AName: string): Boolean;
    class function Extract(var AHeaders: string; const AName: string; out AValue: string): Boolean;
    class function Get(const AHeaders, AName: string; out AValue: string): Boolean; overload;
  end;

{$ENDREGION}

{$REGION ' Http Stream '}

  { TACLHttpInputStream }

  TACLHttpInputStream = class(TStream)
  protected const
    BlockID = $66524565;
    BlockSize = 64 * SIZE_ONE_KILOBYTE; // do not change, affects to cache file structure
    WaitTimeout = 10000; // 10 seconds;
  private
    FCacheStream: TStream;
    FCacheStreamLock: TACLCriticalSection;
    FConnection: THttpConnection;
    FFatalError: Boolean;
    FFreeBlocks: TACLThreadListOf<Integer>;
    FFreeBlocksCursor: Integer;
    FFreeBlocksEvent: TACLEvent;
    FLoadOnRequest: Boolean;
    FPosition: Int64;
    FSize: Int64;
    FUpdateThread: TACLPauseableThread;
    FURL: TACLWebURL;

    procedure AllocateCacheStream(const ASize: Int64);
  protected
    function GetSize: Int64; override;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(const URL: TACLWebURL;
      const ACachedFileName: string = ''; ALoadOnRequest: Boolean = False);
    destructor Destroy; override;
    class function ValidateCacheStream(AStream: TStream): Boolean; overload;
    class procedure ValidateCacheStream(AStream: TStream; AFreeBlocks: TACLListOf<Integer>); overload;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    //# Properties
    property LoadOnRequest: Boolean read FLoadOnRequest write FLoadOnRequest;
  end;

{$ENDREGION}

{$REGION ' Http Client '}

  { IACLHttpRequest }

  IACLHttpRequest = interface
    // Setup
    function OnAccept(AMaxSize: Int64): IACLHttpRequest; overload;
    function OnAccept(AProc: THttpAcceptProc;
      ACallInMainThread: Boolean = False): IACLHttpRequest; overload;
    function OnComplete(AProc: TProc<TACLWebErrorInfo>;
      ACallInMainThread: Boolean = False): IACLHttpRequest;
    function OnData(AContainer: IACLDataContainer): IACLHttpRequest; overload;
    function OnData(AProc: THttpDataProc): IACLHttpRequest; overload;
    function OnData(AStream: TStream): IACLHttpRequest; overload;
    function OnPost(AStream: TStream;
      AOwnership: TStreamOwnership = soReference): IACLHttpRequest; overload;
    function OnPost(const AStr: AnsiString): IACLHttpRequest; overload;
    function OnProgress(AProc: THttpProgressProc;
      ACallInMainThread: Boolean = False): IACLHttpRequest;
    function SetRange(ARange: IACLWebRequestRange): IACLHttpRequest;
    function SetPriority(APriority: TACLTaskPriority): IACLHttpRequest;
    // Run
    function Run: TObjHandle;
    function RunNoThread: TACLWebErrorInfo; overload;
    function RunNoThread(ACheckCanceled: TACLTaskCancelCallback): TACLWebErrorInfo; overload;
  end;

  { TACLHttp }

  TACLHttp = class(TInterfacedObject, IACLHttpRequest)
  protected
    FMethod: string;
    FOnAccept: THttpAcceptProc;
    FOnAcceptSync: Boolean;
    FOnCheckCanceled: TACLTaskCancelCallback;
    FOnComplete: TProc<TACLWebErrorInfo>;
    FOnCompleteSync: Boolean;
    FOnData: THttpDataProc;
    FOnProgress: THttpProgressProc;
    FOnProgressSync: Boolean;
    FPostData: TStream;
    FPostDataOwnership: TStreamOwnership;
    FPriority: TACLTaskPriority;
    FRange: IACLWebRequestRange;
    FResult: TACLWebErrorInfo;
    FUrl: TACLWebURL;

    // IACLHttpRequest
    function OnAccept(AMaxSize: Int64): IACLHttpRequest; overload;
    function OnAccept(AProc: THttpAcceptProc;
      ACallInMainThread: Boolean = False): IACLHttpRequest; overload;
    function OnCheckCanceled(
      ACheckCanceled: TACLTaskCancelCallback): IACLHttpRequest;
    function OnComplete(AProc: TProc<TACLWebErrorInfo>;
      ACallInMainThread: Boolean = False): IACLHttpRequest;
    function OnData(AContainer: IACLDataContainer): IACLHttpRequest; overload;
    function OnData(AProc: THttpDataProc): IACLHttpRequest; overload;
    function OnData(AStream: TStream): IACLHttpRequest; overload;
    function OnPost(AStream: TStream;
      AOwnership: TStreamOwnership = soReference): IACLHttpRequest; overload;
    function OnPost(const AStr: AnsiString): IACLHttpRequest; overload;
    function OnProgress(AProc: THttpProgressProc;
      ACallInMainThread: Boolean = False): IACLHttpRequest;
    function SetRange(ARange: IACLWebRequestRange): IACLHttpRequest; overload;
    function SetPriority(APriority: TACLTaskPriority): IACLHttpRequest;
    // Run
    function Run: TObjHandle;
    function RunNoThread: TACLWebErrorInfo; overload;
    function RunNoThread(ACheckCanceled: TACLTaskCancelCallback): TACLWebErrorInfo; overload;
  public
    destructor Destroy; override;
    class function Get(const AUrl: string): IACLHttpRequest;
    class function Head(const AUrl: string): IACLHttpRequest;
    class function Post(const AUrl: string): IACLHttpRequest;
    class function Request(const AMethod: string; const AUrl: string): IACLHttpRequest;
    //# Utils
    class procedure RaiseOnError(const AInfo: TACLWebErrorInfo);
  end;

{$ENDREGION}

implementation

uses
{$IFDEF FPC}
  FPHttpClient,
  OpenSSLSockets,
  URIParser,
{$ENDIF}
  ACL.Classes.StringList,
  ACL.FastCode,
  ACL.Math,
  ACL.Parsers,
  ACL.Utils.FileSystem,
  ACL.Utils.Stream,
  ACL.Utils.Strings;

const
  sErrorCancel = 'The operation has been canceled by user.';
  sErrorContentType = 'Content type is not accepted';
  sErrorInternal = 'Internal connection error (%s)';
  sErrorRange = 'Range is not supported by Server';
  sErrorWrite = 'Cannot write data to the stream.';
{$IFNDEF FPC}
  sErrorWriteToServer = 'Cannot post data to the server.';
{$ENDIF}

  IdentConnection = 'Connection';
  IdentContentLength = 'Content-Length';
  IdentContentRange = 'Content-Range';
  IdentContentType = 'Content-Type';
  IdentCookie = 'Cookie';
  IdentKeepAlive = 'Keep-Alive';
  IdentRange = 'Range';
  IdentUserAgent = 'User-Agent';

{$REGION ' Http Basics '}
{$IFDEF FPC}

type

  { TLazHttpClient }

  TLazHttpClient = class(TFPHTTPClient)
  protected type
    TStreamAdapter = class(TStream)
    strict private
      FOnData: THttpDataProc;
    public
      constructor Create(AOnData: THttpDataProc);
      function Write(const Buffer; Count: Longint): Longint; override;
    end;
  protected
    FOnAccept: THttpAcceptProc;
    FOnProgress: THttpProgressProc;
    procedure DoHeaders(Sender: TObject);
    procedure DoReadResponse(var AResponse: THttpResponse);
    procedure DoProgress(Sender : TObject; const Size, Pos: Int64);
  public
    constructor Create(AOwner: TComponent); override;
  end;

constructor TLazHttpClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AllowRedirect := True;
  ConnectTimeout := TACLWebSettings.ConnectionTimeOut;
  IOTimeout := TACLWebSettings.ConnectionTimeOut;
  if TACLWebSettings.ConnectionMode = ncmUserDefined then
  begin
    Proxy.Host := TACLWebSettings.Proxy.Server;
    Proxy.Port := StrToIntDef(TACLWebSettings.Proxy.ServerPort, 8080);
    Proxy.UserName := TACLWebSettings.Proxy.UserName;
    Proxy.Password := TACLWebSettings.Proxy.UserPass;
  end;
  OnHeaders := DoHeaders;
  OnDataSent := DoProgress;
  OnDataReceived := DoProgress;
end;

procedure TLazHttpClient.DoProgress(Sender : TObject; const Size, Pos: Int64);
begin
  if Assigned(FOnProgress) and not FOnProgress(Pos, Size) then Abort;
end;

procedure TLazHttpClient.DoHeaders(Sender: TObject);
var
  LResponse: THttpResponse;
begin
  if Assigned(FOnAccept) and not IsRedirect(ResponseStatusCode) then
  begin
    LResponse.Init;
    DoReadResponse(LResponse);
    FOnAccept(LResponse);
  end;
end;

procedure TLazHttpClient.DoReadResponse(var AResponse: THttpResponse);
begin
  AResponse.ContentLength := StrToIntDef(GetHeader(ResponseHeaders, IdentContentLength), -1);
  AResponse.ContentRange := GetHeader(ResponseHeaders, IdentContentRange);
  AResponse.ContentType := GetHeader(ResponseHeaders, IdentContentType);
  AResponse.RawHeaders := ResponseHeaders.Text;
  AResponse.StatusCode := ResponseStatusCode;
  AResponse.StatusText := ResponseStatusText;
end;

{ TLazHttpClient.TStreamAdapter }

constructor TLazHttpClient.TStreamAdapter.Create(AOnData: THttpDataProc);
begin
  FOnData := AOnData;
end;

function TLazHttpClient.TStreamAdapter.Write(const Buffer; Count: Longint): Longint;
begin
  if FOnData(@Buffer, Count) then
    Result := Count
  else
    Result := -1;
end;

{$ELSE}

function HttpQueryDWORD(AService: HINTERNET; ID: DWORD): DWORD;
var
  ABufferLength: DWORD;
  AReserved: DWORD;
begin
  AReserved := 0;
  ABufferLength := SizeOf(Result);
  if not HttpQueryInfo(AService, ID or HTTP_QUERY_FLAG_NUMBER, @Result, ABufferLength, AReserved) then
    Result := 0;
end;

function HttpQueryString(AService: HINTERNET; ID: DWORD): UnicodeString;
var
  ABufferLength: DWORD;
  AReserved: DWORD;
begin
  AReserved := 0;
  ABufferLength := 0;
  HttpQueryInfoW(AService, ID, nil, ABufferLength, AReserved);
  if GetLastError = ERROR_INSUFFICIENT_BUFFER then
  begin
    AReserved := 0;
    SetLength(Result, ABufferLength div SizeOf(WideChar));
    HttpQueryInfoW(AService, ID, @Result[1], ABufferLength, AReserved);
    SetLength(Result, ABufferLength div SizeOf(WideChar));
  end
  else
    Result := EmptyStr;
end;

procedure HttpReleaseHandle(var AHandle: HINTERNET);
begin
  if AHandle <> nil then
  begin
    InternetCloseHandle(AHandle);
    AHandle := nil;
  end;
end;

{$ENDIF}

{ EHttpError }

constructor EHttpError.Create(const DefaultText: string = '');
{$IFDEF MSWINDOWS}
var
  ABuffer: array[Byte] of WideChar;
  ABufferLength: DWORD;
  AError: DWORD;
begin
  ABufferLength := Length(ABuffer);
  if InternetGetLastResponseInfoW(AError, @ABuffer[0], ABufferLength) and (AError > 0) then
    inherited Create(acMakeString(PWideChar(@ABuffer[0]), ABufferLength), AError)
  else
  begin
    AError := GetLastError;
    if AError <> 0 then
      inherited Create(SysErrorMessage(AError), AError)
    else
      inherited Create(Format(sErrorInternal, [DefaultText]), acWebErrorUnknown);
  end;
{$ELSE}
begin
  Create(Format(sErrorInternal, [DefaultText]), acWebErrorUnknown);
{$ENDIF}
end;

{ EHttpWriteError }

constructor EHttpWriteError.Create;
begin
  inherited Create(sErrorWrite, acWebErrorUnknown);
end;

{ THttpResponse }

procedure THttpResponse.Init;
begin
  ContentLength := 0;
  ContentRange := '';
  ContentType := '';
  RawHeaders := '';
  StatusText := '';
  StatusCode := 0;
end;

function THttpResponse.StatusIsOk: Boolean;
begin
  // https://developer.mozilla.org/ru/docs/Web/HTTP/Status
  Result := InRange(StatusCode, 200, 299);
end;

{ THttpConnection }

constructor THttpConnection.Create(const URL: TACLWebURL);
{$IFNDEF FPC}

  procedure SetOption(Handle: HINTERNET; Option: Cardinal; const Value: string); overload;
  begin
    InternetSetOptionW(Handle, Option, PWideChar(Value), Length(Value));
  end;

  procedure SetOption(Handle: HINTERNET; Option, Value: Cardinal); overload;
  begin
    InternetSetOption(Handle, Option, @Value, SizeOf(Value));
  end;

var
  LProxyServer: string;
{$ENDIF}
begin
  FURL := URL;
{$IFNDEF FPC}
  case TACLWebSettings.ConnectionMode of
    ncmDirect:
      FSession := InternetOpenW(nil, INTERNET_OPEN_TYPE_DIRECT, nil, nil, 0);
    ncmUserDefined:
      begin
        LProxyServer := TACLWebSettings.Proxy.Server + ':' + TACLWebSettings.Proxy.ServerPort;
        FSession := InternetOpenW(nil, INTERNET_OPEN_TYPE_PROXY, PWideChar(LProxyServer), nil, 0);
      end;
  else
    FSession := InternetOpenW(nil, INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  end;
  if FSession = nil then
    raise EHttpError.Create('InternetOpen failed');

  SetOption(FSession, INTERNET_OPTION_DATA_SEND_TIMEOUT, TACLWebSettings.ConnectionTimeOut);
  SetOption(FSession, INTERNET_OPTION_DATA_RECEIVE_TIMEOUT, TACLWebSettings.ConnectionTimeOut);
  SetOption(FSession, INTERNET_OPTION_CONNECT_TIMEOUT, TACLWebSettings.ConnectionTimeOut);

  FHandle := InternetConnectW(FSession, PWideChar(URL.Host), URL.Port, nil, nil, INTERNET_SERVICE_HTTP, 0, 0);
  if FHandle = nil then
    raise EHttpError.Create('InternetConnectW failed');

  if (TACLWebSettings.ConnectionMode = ncmUserDefined) and (TACLWebSettings.Proxy.UserName <> '') then
  begin
    SetOption(FHandle, INTERNET_OPTION_PROXY_USERNAME, TACLWebSettings.Proxy.UserName);
    SetOption(FHandle, INTERNET_OPTION_PROXY_PASSWORD, TACLWebSettings.Proxy.UserPass);
  end;
{$ENDIF}
end;

destructor THttpConnection.Destroy;
begin
{$IFNDEF FPC}
  HTTPReleaseHandle(FHandle);
  HTTPReleaseHandle(FSession);
{$ENDIF}
  inherited;
end;

function THttpConnection.Request(const AMethod: string;
  ARange: IACLWebRequestRange = nil;
  APostData: TStream = nil;
  AOnAccept: THttpAcceptProc = nil;
  AOnProgress: THttpProgressProc = nil;
  AOnReceive: THttpDataProc = nil): THttpResponse;
var
  LCustomHeaders: string;

  procedure AddHeaderValue(AHeaders: TACLStringList; const AName, ADefaultValue: string);
  var
    AValue: string;
  begin
    if not THttpHeaders.Extract(LCustomHeaders, AName, AValue) then
      AValue := ADefaultValue;
    if AValue <> '' then
      AHeaders.Add(AName + THttpHeaders.Delimiter + AValue);
  end;

  function BuildRange: string;
  begin
    Result := 'bytes=' + IntToStr(ARange.GetOffset) + '-';
    if ARange.GetSize >= 0 then
      Result := Result + IntToStr(ARange.GetOffset + ARange.GetSize - 1);
  end;

  function BuildHeaders: string;
  var
    AHeaders: TACLStringList;
  begin
    AHeaders := TACLStringList.Create;
    try
    {$IFNDEF FPC}
      AHeaders.Add('Host: ' + FUrl.Host);
    {$ENDIF}
      AddHeaderValue(AHeaders, IdentUserAgent, TACLWebSettings.UserAgent);
      AddHeaderValue(AHeaders, IdentConnection, 'keep-alive');
      AddHeaderValue(AHeaders, IdentKeepAlive, '300');
      if acSameText(AMethod, 'POST') then
        AddHeaderValue(AHeaders, IdentContentType, 'application/x-www-form-urlencoded');
      if (ARange <> nil) and ((ARange.GetOffset > 0) or (ARange.GetSize > 0)) then
        AddHeaderValue(AHeaders, IdentRange, BuildRange);
      if LCustomHeaders <> '' then
        AHeaders.Add(LCustomHeaders);
      Result := Trim(AHeaders.Text);
    finally
      AHeaders.Free;
    end;
  end;

var
  LAcceptProc: THttpAcceptProc;
begin
  LCustomHeaders := FUrl.CustomHeaders;
  LAcceptProc :=
    function (const AResponse: THttpResponse): Boolean
    begin
      if (ARange <> nil) and (ARange.GetOffset > 0) then
      begin
        if AResponse.StatusCode <> 206{HTTP_STATUS_PARTIAL_CONTENT} then
          raise EHttpError.Create(sErrorRange, acWebErrorNotAccepted);
        if AResponse.ContentRange = '' then
          raise EHttpError.Create(sErrorRange, acWebErrorNotAccepted);
        if AResponse.ContentLength = 0 then
          raise EHttpError.Create(sErrorRange, acWebErrorNotAccepted);
      end;
      if not AResponse.StatusIsOk then
        raise EHttpError.Create(AResponse.StatusText, AResponse.StatusCode);
      if Assigned(AOnAccept) and not AOnAccept(AResponse) then
        raise EHttpError.Create(sErrorContentType, acWebErrorNotAccepted);
      Result := True;
    end;

  Result.Init;
  RequestCore(AMethod, BuildHeaders, Result, APostData, LAcceptProc, AOnProgress, AOnReceive);
end;

procedure THttpConnection.RequestCore(
  AMethod, AHeaders: string;
  var AResponse: THttpResponse;
  APostData: TStream = nil;
  AOnAccept: THttpAcceptProc = nil;
  AOnProgress: THttpProgressProc = nil;
  AOnReceive: THttpDataProc = nil);
{$IFDEF FPC}
var
  LClient: TLazHttpClient;
  LCookieValue: string;
  LStream: TStream;
begin
  LClient := TLazHttpClient.Create(nil);
  try
    if TACLWebSettings.ConnectionMode = ncmUserDefined then
    begin
      LClient.Proxy.Host := TACLWebSettings.Proxy.Server;
      LClient.Proxy.Port := StrToIntDef(TACLWebSettings.Proxy.ServerPort, 80);
      LClient.Proxy.UserName := TACLWebSettings.Proxy.UserName;
      LClient.Proxy.Password := TACLWebSettings.Proxy.UserPass;
    end;
    LClient.FOnAccept := AOnAccept;
    LClient.FOnProgress := LClient.FOnProgress;
    while THttpHeaders.Extract(AHeaders, IdentCookie, LCookieValue) do
      LClient.Cookies.Add(LCookieValue);
    try
      LStream := LClient.TStreamAdapter.Create(AOnReceive);
      try
        LClient.RequestHeaders.Text := AHeaders;
        LClient.RequestBody := APostData;
        LClient.HttpMethod(AMethod, URL.ToString, LStream, []);
      finally
        LStream.Free;
      end;
    finally
      LClient.DoReadResponse(AResponse);
    end;
  finally
    LClient.Free;
  end;
end;
{$ELSE}
const
  BufferSize = 256 * SIZE_ONE_KILOBYTE;

  function SendRequest(ARequest: HINTERNET): Boolean;
  var
    ABuffer: TInternetBuffersW;
    AContentPosition: Int64;
    AContentSize: Int64;
    AData: PByte;
    ADataUsed: Integer;
    ADataWritten: Cardinal;
  begin
    Result := False;
    if APostData <> nil then
    begin
      ZeroMemory(@ABuffer, SizeOf(ABuffer));
      ABuffer.dwStructSize := SizeOf(ABuffer);
      ABuffer.lpcszHeader := PWideChar(AHeaders);
      ABuffer.dwHeadersLength := Length(AHeaders);
      ABuffer.dwHeadersTotal := Length(AHeaders);
      ABuffer.dwBufferTotal := APostData.Size;

      if HttpSendRequestEx(ARequest, @ABuffer, nil, HSR_INITIATE, 0) then
      begin
        AContentPosition := 0;
        AContentSize := APostData.Size;
        APostData.Position := 0;

        AData := AllocMem(BufferSize);
        try
          repeat
            ADataUsed := APostData.Read(AData^, BufferSize);
            if ADataUsed > 0 then
            begin
              if not InternetWriteFile(ARequest, AData, ADataUsed, ADataWritten) then
                raise EHttpError.Create(sErrorWriteToServer, acWebErrorUnknown);
            end;

            if Assigned(AOnProgress) then
            begin
              Inc(AContentPosition, ADataWritten);
              if not AOnProgress(AContentPosition, AContentSize) then
                raise EHttpError.Create(sErrorCancel, acWebErrorCanceled);
            end;
          until ADataUsed = 0;
        finally
          FreeMem(AData);
        end;
        Result := HttpEndRequest(ARequest, nil, 0, 0);
      end;
    end
    else
      Result := HttpSendRequest(ARequest, PWideChar(AHeaders), Length(AHeaders), nil, 0);
  end;

  procedure ReceiveData(ARequest: HINTERNET);
  var
    ABuffer: PByte;
    ABytesRead: Cardinal;
    AContentPosition: Int64;
    AContentSize: Int64;
    ARemaining: Cardinal;
  begin
    ABuffer := AllocMem(BufferSize);
    try
      AContentPosition := 0;
      AContentSize := AResponse.ContentLength;
      while InternetQueryDataAvailable(ARequest, ARemaining, 0, 0) and (ARemaining > 0) do
      begin
        if not InternetReadFile(ARequest, ABuffer, BufferSize, ABytesRead) then
          raise EHttpError.Create('InternetReadFile failed');
        if ABytesRead = 0 then
          Break;
        if not AOnReceive(ABuffer, ABytesRead) then
          raise EHttpWriteError.Create;
        if Assigned(AOnProgress) then
        begin
          Inc(AContentPosition, ABytesRead);
          if not AOnProgress(AContentPosition, AContentSize) then
            raise EHttpError.Create(sErrorCancel, acWebErrorCanceled);
        end;
      end;
    finally
      FreeMem(ABuffer);
    end;
  end;

var
  LCookieURL: string;
  LCookieValue: string;
  LFlags: Cardinal;
  LRequest: HINTERNET;
begin
  LCookieURL := 'http' + IfThenW(URL.Secured, 's') + '://' + URL.Host;
  while THttpHeaders.Extract(AHeaders, IdentCookie, LCookieValue) do
    InternetSetCookie(PChar(LCookieURL), nil, PChar(LCookieValue));

  LFlags := INTERNET_FLAG_RELOAD or INTERNET_SERVICE_HTTP;
  if URL.Secured then
    LFlags := LFlags or INTERNET_FLAG_SECURE or INTERNET_FLAG_KEEP_CONNECTION;

  LRequest := HTTPOpenRequestW(FHandle, PWideChar(AMethod), PWideChar(FUrl.Path), nil, nil, nil, LFlags, 0);
  try
    if LRequest = nil then
      raise EHttpError.Create('HttpOpenRequest failed');

    if not SendRequest(LRequest) then
      raise EHttpError.Create('HttpSendRequest failed');

    AResponse.ContentRange := HTTPQueryString(LRequest, HTTP_QUERY_CONTENT_RANGE);
    AResponse.ContentLength := HttpQueryDWORD(LRequest, HTTP_QUERY_CONTENT_LENGTH);
    AResponse.ContentType := HTTPQueryString(LRequest, HTTP_QUERY_CONTENT_TYPE);
    AResponse.StatusCode := HttpQueryDWORD(LRequest, HTTP_QUERY_STATUS_CODE);
    AResponse.StatusText := HttpQueryString(LRequest, HTTP_QUERY_STATUS_TEXT);
    AResponse.RawHeaders := HttpQueryString(LRequest, HTTP_QUERY_RAW_HEADERS);

    if not Assigned(AOnAccept) or AOnAccept(AResponse) then
    begin
      if Assigned(AOnReceive) then
        ReceiveData(LRequest);
    end;
  finally
    HttpReleaseHandle(LRequest);
  end;
end;
{$ENDIF}

{ THttpHeader }

class function THttpHeaders.Contains(const AHeaders, AName: string): Boolean;
var
  AValue: string;
begin
  Result := Get(AHeaders, AName, AValue);
end;

class function THttpHeaders.Extract(var AHeaders: string;
  const AName: string; out AValue: string): Boolean;
var
  APosFinish: Integer;
  APosStart: Integer;
begin
  Result := Get(AHeaders, AName, AValue, APosStart, APosFinish);
  if Result then
    Delete(AHeaders, APosStart, APosFinish - APosStart + Length(acCRLF))
end;

class function THttpHeaders.Get(const AHeaders, AName: string; out AValue: string): Boolean;
var
  APosFinish: Integer;
  APosStart: Integer;
begin
  Result := Get(AHeaders, AName, AValue, APosStart, APosFinish);
end;

class function THttpHeaders.Get(const AHeaders, AName: string;
  out AValue: string; out APosStart, APosFinish: Integer): Boolean;
begin
  AValue := acExtractString(AHeaders + acCRLF, AName + Delimiter, acCRLF, APosStart, APosFinish);
  Result := APosStart > 0;
end;

{$ENDREGION}

{$REGION ' Http Stream '}
type

  { TACLHttpInputStreamUpdateThread }

  TACLHttpInputStreamUpdateThread = class(TACLPauseableThread)
  strict private
    FBlockBuffer: TACLByteBuffer;
    FStream: TACLHttpInputStream;
    function GetNextBlockIndex(out ABlockIndex: Integer): Boolean;
    procedure WriteBuffer(ABlockIndex: Integer);
  protected
    procedure Execute; override;
  public
    constructor Create(AStream: TACLHttpInputStream);
    destructor Destroy; override;
  end;

{ TACLHttpInputStream }

constructor TACLHttpInputStream.Create(const URL: TACLWebURL;
  const ACachedFileName: string = ''; ALoadOnRequest: Boolean = False);
var
  AList: TACLListOf<Integer>;
begin
  inherited Create;
  FURL := URL;
  FLoadOnRequest := ALoadOnRequest;
  FFreeBlocks := TACLThreadListOf<Integer>.Create;
  FFreeBlocksEvent := TACLEvent.Create;
  FCacheStreamLock := TACLCriticalSection.Create(Self, 'Lock');

  if acFileExists(ACachedFileName) then
  begin
    FCacheStream := TACLFileStream.Create(ACachedFileName, fmOpenReadWriteExclusive);
    AList := FFreeBlocks.LockList;
    try
      ValidateCacheStream(FCacheStream, AList);
    finally
      FFreeBlocks.UnlockList;
    end;
    FSize := FCacheStream.Size;
  end;

  if (FCacheStream = nil) or (FFreeBlocks.Count > 0) then
  begin
    FConnection := THttpConnection.Create(URL);
    FSize := FConnection.Request('HEAD').ContentLength;

    // Was cached stream deprecated?
    if (FCacheStream <> nil) and (FCacheStream.Size <> FSize) then
      FreeAndNil(FCacheStream);

    // Allocate Cache Stream
    if FCacheStream = nil then
    begin
      if ACachedFileName <> '' then
      try
        FCacheStream := TACLFileStream.Create(ACachedFileName, fmCreate or fmShareDenyNone)
      except
        FCacheStream := TMemoryStream.Create;
      end
      else
        FCacheStream := TMemoryStream.Create;

      AllocateCacheStream(FSize);
    end;

    // Start the download thread
    FUpdateThread := TACLHttpInputStreamUpdateThread.Create(Self);
  end;
end;

destructor TACLHttpInputStream.Destroy;
begin
  // keep the order
  FFatalError := True;
  FFreeBlocksEvent.Signal;
  FreeAndNil(FUpdateThread);
  FreeAndNil(FCacheStreamLock);
  FreeAndNil(FCacheStream);
  FreeAndNil(FFreeBlocksEvent);
  FreeAndNil(FFreeBlocks);
  FreeAndNil(FConnection);
  inherited Destroy;
end;

class function TACLHttpInputStream.ValidateCacheStream(AStream: TStream): Boolean;
var
  AFreeBlocks: TACLListOf<Integer>;
begin
  AFreeBlocks := TACLListOf<Integer>.Create;
  try
    ValidateCacheStream(AStream, AFreeBlocks);
    Result := AFreeBlocks.Count = 0;
  finally
    AFreeBlocks.Free;
  end;
end;

class procedure TACLHttpInputStream.ValidateCacheStream(AStream: TStream; AFreeBlocks: TACLListOf<Integer>);
var
  ABlockIndex: Integer;
  APosition: Int64;
  ASize: Int64;
begin
  AFreeBlocks.Clear;
  ABlockIndex := 0;
  APosition := 0;
  ASize := AStream.Size;
  while APosition + SizeOf(Integer) <= ASize do
  begin
    AStream.Position := APosition;
    if AStream.ReadInt32 = BlockID then
      AFreeBlocks.Add(ABlockIndex);
    Inc(APosition, BlockSize);
    Inc(ABlockIndex);
  end;
end;

function TACLHttpInputStream.Read(var Buffer; Count: Integer): Longint;
var
  ABlockIndex: Integer;
  ABuffer: PByte;
  AChunkSize: Integer;
  AOffset: Integer;
begin
  if FFatalError then
    Exit(0);

  Result := 0;
  ABuffer := @Buffer;
  while Count > 0 do
  begin
    ABlockIndex := Position div BlockSize;
    AOffset := Position - ABlockIndex * BlockSize;
    AChunkSize := Min(Count, BlockSize - AOffset);

    // Was block downloaded?
    while FFreeBlocks.Contains(ABlockIndex) do
    begin
      // move required block to queue beginning
      with FFreeBlocks.LockList do
      try
        FFreeBlocksCursor := Max(IndexOf(ABlockIndex), 0);
        FFreeBlocksEvent.Reset;
        FUpdateThread.SetPaused(False);
      finally
        FFreeBlocks.UnlockList;
      end;

      // wait while block will be downloaded
      if not FFreeBlocksEvent.WaitFor(WaitTimeout) then
        Exit(0); // Download thread failed
      if FFatalError then
        Exit(0); // Failed
    end;

    // Read data from cache
    FCacheStreamLock.Enter;
    try
      FCacheStream.Position := Position;
      AChunkSize := FCacheStream.Read(ABuffer^, AChunkSize);
      if AChunkSize = 0 then
        Break;
    finally
      FCacheStreamLock.Leave;
    end;

    Inc(FPosition, AChunkSize);
    Inc(ABuffer, AChunkSize);
    Inc(Result, AChunkSize);
    Dec(Count, AChunkSize);
  end;
end;

function TACLHttpInputStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  case Origin of
    soBeginning:
      Result := Offset;
    soCurrent:
      Result := FPosition + Offset;
    soEnd:
      Result := Size + Offset
  else
    Result := FPosition;
  end;
  Result := MinMax(Result, 0, Size);
  FPosition := Result;
end;

function TACLHttpInputStream.Write(const Buffer; Count: Integer): Longint;
begin
{$IFDEF FPC}
  Result := -1;
{$ENDIF}
  raise EInvalidOperation.Create(ClassName);
end;

function TACLHttpInputStream.GetSize: Int64;
begin
  Result := FSize;
end;

procedure TACLHttpInputStream.SetSize(const NewSize: Int64);
begin
  raise EInvalidOperation.Create(ClassName);
end;

procedure TACLHttpInputStream.AllocateCacheStream(const ASize: Int64);
var
  ABlockIndex: Integer;
  APosition: Int64;
begin
  FCacheStreamLock.Enter;
  try
    APosition := 0;
    ABlockIndex := 0;
    FFreeBlocks.Clear;
    FCacheStream.Size := ASize;
    while APosition + SizeOf(Integer) <= ASize do
    begin
      FFreeBlocks.Add(ABlockIndex);
      FCacheStream.Position := APosition;
      FCacheStream.WriteInt32(BlockID);
      Inc(APosition, BlockSize);
      Inc(ABlockIndex);
    end;
  finally
    FCacheStreamLock.Leave;
  end;
end;

{ TACLHttpInputStreamUpdateThread }

constructor TACLHttpInputStreamUpdateThread.Create(AStream: TACLHttpInputStream);
begin
  inherited Create(False);
  FStream := AStream;
  FBlockBuffer := TACLByteBuffer.Create(TACLHttpInputStream.BlockSize);
end;

destructor TACLHttpInputStreamUpdateThread.Destroy;
begin
  inherited;
  FreeAndNil(FBlockBuffer);
end;

procedure TACLHttpInputStreamUpdateThread.Execute;
var
  ABlockIndex: Integer;
begin
  while not Terminated do
  begin
    if FStream.LoadOnRequest then
      CheckForPause;
    if GetNextBlockIndex(ABlockIndex) then
    try
      FBlockBuffer.Used := 0;
      FStream.FConnection.Request('GET',
        TACLWebRequestRange.Create(ABlockIndex * TACLHttpInputStream.BlockSize),
        {post-data}nil, {onAccept}nil, {onProgress}nil,
        function (Data: PByte; Count: Integer): Boolean
        var
          ABytesToWrite: Integer;
          ANextBlockIndex: Integer;
        begin
          while Count > 0 do
          begin
            ABytesToWrite := Min(Count, FBlockBuffer.Unused);
            FastMove(Data^, FBlockBuffer.DataArr^[FBlockBuffer.Used], ABytesToWrite);
            FBlockBuffer.Used := FBlockBuffer.Used + ABytesToWrite;
            Dec(Count, ABytesToWrite);
            Inc(Data, ABytesToWrite);
            if Terminated then
              Exit(False);
            if FBlockBuffer.Unused = 0 then
            begin
              WriteBuffer(ABlockIndex);
              if not GetNextBlockIndex(ANextBlockIndex) or (ANextBlockIndex <> ABlockIndex + 1) then
                Exit(False);
              ABlockIndex := ANextBlockIndex;
            end;
          end;
          Result := True;
        end);

      WriteBuffer(ABlockIndex);
    except
      on E: EHttpWriteError do
      begin
        // Эта ошибка возникает, если следующий блок отсутсвует или идет не по порядку.
        // Ошибка не является фатальной и лишь сигнализирует о том, что надо сдвинуться к следующему блоку.
        Continue;
      end;
      on E: EHttpError do
      begin
        FStream.FFatalError := True;
        FStream.FFreeBlocksEvent.Signal;
        Terminate;
      end;
    end
    else
      Sleep(100);
  end;
end;

function TACLHttpInputStreamUpdateThread.GetNextBlockIndex(out ABlockIndex: Integer): Boolean;
begin
  with FStream.FFreeBlocks.LockList do
  try
    if Count > 0 then
    begin
      FStream.FFreeBlocksCursor := Min(FStream.FFreeBlocksCursor, Count - 1);
      ABlockIndex := List[FStream.FFreeBlocksCursor];
    end
    else
      ABlockIndex := -1;
  finally
    FStream.FFreeBlocks.UnlockList;
  end;
  Result := ABlockIndex >= 0;
end;

procedure TACLHttpInputStreamUpdateThread.WriteBuffer(ABlockIndex: Integer);
begin
  if FBlockBuffer.Used > 0 then
  try
    FStream.FCacheStreamLock.Enter;
    try
      FStream.FCacheStream.Position := ABlockIndex * TACLHttpInputStream.BlockSize;
      FStream.FCacheStream.WriteBuffer(FBlockBuffer.Data^, FBlockBuffer.Used);
    finally
      FStream.FCacheStreamLock.Leave;
    end;

    with FStream.FFreeBlocks.LockList do
    try
      Remove(ABlockIndex);
      FStream.FFreeBlocksEvent.Signal;
    finally
      FStream.FFreeBlocks.UnlockList;
    end;
  finally
    FBlockBuffer.Used := 0;
  end;
end;

{$ENDREGION}

{$REGION ' Http Client '}
type

  { TACLHttpRequestTask }

  TACLHttpRequestTask = class(TACLTask)
  strict private
    FRequest: TACLHttp;
    FRequestIntf: IACLHttpRequest;
    procedure CallEvent(AProc: TProc; ASync: Boolean);
    function DoAccept(const AResponse: THttpResponse): Boolean;
    function DoCanContinue: Boolean;
    function DoProgess(const APosition, ASize: Int64): Boolean;
  protected
    procedure Complete; override;
    procedure Execute; override;
    function GetPriority: TACLTaskPriority; override;
  public
    constructor Create(ARequest: TACLHttp);
  end;

{ TACLHttp }

destructor TACLHttp.Destroy;
begin
  if FPostDataOwnership = soOwned then
    FreeAndNil(FPostData);
  inherited;
end;

class function TACLHttp.Get(const AUrl: string): IACLHttpRequest;
begin
  Result := Request('GET', AUrl);
end;

class function TACLHttp.Head(const AUrl: string): IACLHttpRequest;
begin
  Result := Request('HEAD', AUrl);
end;

class procedure TACLHttp.RaiseOnError(const AInfo: TACLWebErrorInfo);
begin
  if not AInfo.Succeeded then
    raise EACLWebError.Create(AInfo);
end;

class function TACLHttp.Post(const AUrl: string): IACLHttpRequest;
begin
  Result := Request('POST', AUrl);
end;

class function TACLHttp.Request(const AMethod, AUrl: string): IACLHttpRequest;
var
  LInst: TACLHttp;
begin
  LInst := TACLHttp.Create;
  LInst.FMethod := AMethod;
  LInst.FUrl := TACLWebURL.ParseHttp(AUrl);
  Result := LInst;
end;

function TACLHttp.OnAccept(AProc: THttpAcceptProc;
  ACallInMainThread: Boolean = False): IACLHttpRequest;
begin
  FOnAccept := AProc;
  FOnAcceptSync := ACallInMainThread;
  Result := Self;
end;

function TACLHttp.OnAccept(AMaxSize: Int64): IACLHttpRequest;
begin
  Result := Self;
  if AMaxSize > 0 then
    FOnAccept :=
      function (const AResponse: THttpResponse): Boolean
      begin
        Result := AResponse.ContentLength <= AMaxSize;
      end;
end;

function TACLHttp.OnCheckCanceled(
  ACheckCanceled: TACLTaskCancelCallback): IACLHttpRequest;
begin
  FOnCheckCanceled := FOnCheckCanceled;
  Result := Self;
end;

function TACLHttp.OnComplete(AProc: TProc<TACLWebErrorInfo>;
  ACallInMainThread: Boolean = False): IACLHttpRequest;
begin
  FOnComplete := AProc;
  FOnCompleteSync := ACallInMainThread;
  Result := Self;
end;

function TACLHttp.OnData(AProc: THttpDataProc): IACLHttpRequest;
begin
  FOnData := AProc;
  Result := Self;
end;

function TACLHttp.OnData(AContainer: IACLDataContainer): IACLHttpRequest;
begin
  Result := OnData(
    function (Data: PByte; Count: Integer): Boolean
    var
      LStream: TStream;
    begin
      LStream := AContainer.LockData;
      try
        Result := LStream.Write(Data^, Count) = Count;
      finally
        AContainer.UnlockData;
      end;
    end);
end;

function TACLHttp.OnData(AStream: TStream): IACLHttpRequest;
begin
  Result := OnData(
    function (Data: PByte; Count: Integer): Boolean
    begin
      Result := AStream.Write(Data^, Count) = Count;
    end);
end;

function TACLHttp.OnPost(const AStr: AnsiString): IACLHttpRequest;
begin
  Result := OnPost(TACLAnsiStringStream.Create(AStr), soOwned);
end;

function TACLHttp.OnProgress(AProc: THttpProgressProc;
  ACallInMainThread: Boolean = False): IACLHttpRequest;
begin
  FOnProgress := AProc;
  FOnProgressSync := ACallInMainThread;
  Result := Self;
end;

function TACLHttp.OnPost(AStream: TStream; AOwnership: TStreamOwnership): IACLHttpRequest;
begin
  FPostData := AStream;
  FPostDataOwnership := AOwnership;
  Result := Self;
end;

function TACLHttp.Run: TObjHandle;
begin
  Result := TaskDispatcher.Run(TACLHttpRequestTask.Create(Self));
end;

function TACLHttp.RunNoThread(ACheckCanceled: TACLTaskCancelCallback): TACLWebErrorInfo;
begin
  FOnCheckCanceled := ACheckCanceled;
  Result := RunNoThread;
end;

function TACLHttp.RunNoThread: TACLWebErrorInfo;
begin
  TaskDispatcher.RunInCurrentThread(TACLHttpRequestTask.Create(Self));
  Result := FResult;
end;

function TACLHttp.SetPriority(APriority: TACLTaskPriority): IACLHttpRequest;
begin
  FPriority := APriority;
  Result := Self;
end;

function TACLHttp.SetRange(ARange: IACLWebRequestRange): IACLHttpRequest;
begin
  FRange := ARange;
  Result := Self;
end;

{ TACLHttpRequestTask }

constructor TACLHttpRequestTask.Create(ARequest: TACLHttp);
begin
  inherited Create;
  FRequest := ARequest;
  FRequestIntf := ARequest;
end;

procedure TACLHttpRequestTask.CallEvent(AProc: TProc; ASync: Boolean);
begin
  if ASync then
    RunInMainThread(AProc)
  else
    AProc();
end;

procedure TACLHttpRequestTask.Complete;
begin
  inherited;
  if IsCanceled then
    FRequest.FResult.Initialize(acWebErrorCanceled, sErrorCancel);
  if Assigned(FRequest.FOnComplete) then
  begin
    CallEvent(
      procedure
      begin
        FRequest.FOnComplete(FRequest.FResult)
      end, FRequest.FOnCompleteSync);
  end;
end;

function TACLHttpRequestTask.DoAccept(const AResponse: THttpResponse): Boolean;
var
  LResult: Boolean;
begin
  LResult := DoCanContinue;
  if LResult and Assigned(FRequest.FOnAccept) then
  begin
    CallEvent(
      procedure
      begin
        LResult := FRequest.FOnAccept(AResponse);
      end, FRequest.FOnAcceptSync);
  end;
  Result := LResult;
end;

function TACLHttpRequestTask.DoCanContinue: Boolean;
begin
  Result := not (Assigned(FRequest.FOnCheckCanceled) and FRequest.FOnCheckCanceled);
end;

function TACLHttpRequestTask.DoProgess(const APosition, ASize: Int64): Boolean;
var
  LResult: Boolean;
begin
  LResult := DoCanContinue;
  if LResult and Assigned(FRequest.FOnProgress) then
  begin
    CallEvent(
      procedure
      begin
        LResult := FRequest.FOnProgress(APosition, ASize);
      end, FRequest.FOnProgressSync);
  end;
  Result := LResult;
end;

procedure TACLHttpRequestTask.Execute;
var
  LConnection: THttpConnection;
begin
  try
    LConnection := THttpConnection.Create(FRequest.FUrl);
    try
      if not IsCanceled then
        LConnection.Request(FRequest.FMethod,
          FRequest.FRange, FRequest.FPostData,
          DoAccept, DoProgess, FRequest.FOnData);
    finally
      LConnection.Free;
    end;
  except
    on E: EHttpError do
      FRequest.FResult := E.Info;
  end;
end;

function TACLHttpRequestTask.GetPriority: TACLTaskPriority;
begin
  Result := FRequest.FPriority;
end;
{$ENDREGION}

end.
