{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*        HTTP Client Implementation         *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Web.Http;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.WinInet,
  // System
  System.Classes,
  System.Types,
  // ACL
  ACL.Classes,
  ACL.Classes.ByteBuffer,
  ACL.Classes.Collections,
  ACL.FileFormats.INI,
  ACL.Threading,
  ACL.Threading.Pool,
  ACL.Utils.Common,
  ACL.WEB;

type
  TACLHttpMethod = (hmGet, hmPost, hmPut, hmDelete, hmHead);

  { IACLHttpClientHandler }

  IACLHttpClientHandler = interface(IUnknown)
  ['{004AB48B-233A-423E-BA95-E446A24F6E9E}']
    function OnAccept(const AHeaders, AContentType: UnicodeString; const AContentSize: Int64): LongBool;
    procedure OnComplete(const AErrorInfo: TACLWebErrorInfo; ACanceled: LongBool);
    function OnData(Data: PByte; Count: Integer): Boolean;
    procedure OnProgress(const AReadBytes, ATotalBytes: Int64);
  end;

  { THttpConnection }

  THttpConnection = class
  strict private
    FHandle: HINTERNET;
    FHost: string;
    FSecured: Boolean;
    FSession: HINTERNET;

    procedure CreateSession;
  protected
    property Handle: HINTERNET read FHandle;
    property Host: string read FHost;
    property Secured: Boolean read FSecured;
  public
    constructor Create(const AHost: string; APort: Word; ASecured: Boolean);
    destructor Destroy; override;
    //
    class procedure ReleaseHandle(var AHandle: HINTERNET);
    class procedure SetOption(Handle: HINTERNET; Option, Value: Cardinal); overload;
    class procedure SetOption(Handle: HINTERNET; Option: Cardinal; const Value: string); overload;
  end;

  { THttpHeaders }

  THttpHeaders = class
  public const
    Delimiter = ': ';
  protected
    class function Get(const AHeaders, AName: string; out AValue: string; out APosStart, APosFinish: Integer): Boolean; overload;
  public
    class function Contains(const AHeaders, AName: string): Boolean;
    class function Extract(var AHeaders: string; const AName: string; out AValue: string): Boolean;
    class function Get(const AHeaders, AName: string; out AValue: string): Boolean; overload;
  end;

  { THttpRequest }

  THttpRequestDataProc = reference to function (Data: PByte; Count: Integer): Boolean;
  THttpRequestProgressProc = function (const APosition, ASize: Int64): Boolean of object;

  THttpRequest = class
  strict private const
    BufferSize = 64 * SIZE_ONE_KILOBYTE;
  strict private
    FCookieURL: string;
    FHandle: HINTERNET;
    FHost: string;
    FMethod: string;
  protected
    function GetQueryValue(const ID: Integer): Integer;
    function GetQueryValueAsString(const ID: Integer): string;
    function HasData: Boolean;
    function SendCore(const AHeaders: string; ADataStream: TStream = nil; AProgressProc: THttpRequestProgressProc = nil): Boolean;
    procedure ProcessCookies(var AHeaders: string);
    //
    property Handle: HINTERNET read FHandle;
  public
    constructor Create(AConnection: THttpConnection; const Method, Path: string);
    destructor Destroy; override;
    procedure Receive(ADataProc: THttpRequestDataProc; AProgressProc: THttpRequestProgressProc = nil);
    procedure Send(ACustomHeaders: string = ''; ARange: IACLWebRequestRange = nil;
      ADataStream: TStream = nil; AProgressProc: THttpRequestProgressProc = nil);
    //
    property ContentLength: Integer index HTTP_QUERY_CONTENT_LENGTH read GetQueryValue;
    property ContentRange: string index HTTP_QUERY_CONTENT_RANGE read GetQueryValueAsString;
    property ContentType: string index HTTP_QUERY_CONTENT_TYPE read GetQueryValueAsString;
    property RawHeaders: string index HTTP_QUERY_RAW_HEADERS read GetQueryValueAsString;
    property StatusCode: Integer index HTTP_QUERY_STATUS_CODE read GetQueryValue;
    property StatusText: string index HTTP_QUERY_STATUS_TEXT read GetQueryValueAsString;
  end;

  { TACLHttpClient }

  TACLHttpClientOption = (hcoThreading, hcoSyncEventAccept, hcoSyncEventProgress, hcoSyncEventComplete, hcoFreePostData);
  TACLHttpClientOptions = set of TACLHttpClientOption;

  TACLHttpClient = class
  public const
    MethodNames: array[TACLHttpMethod] of PWideChar = ('GET', 'POST', 'PUT', 'DELETE', 'HEAD');
  public
    // General
    class function Request(AMethod: TACLHttpMethod; const ALink: UnicodeString;
      AHandler: IACLHttpClientHandler; const APostData: TStream = nil; ARange: IACLWebRequestRange = nil;
      AOptions: TACLHttpClientOptions = [hcoThreading]; AThreadPriority: TACLTaskPriority = atpNormal): THandle; overload;
    class function Request(const AMethod, ALink: UnicodeString;
      AHandler: IACLHttpClientHandler; const APostData: TStream = nil; ARange: IACLWebRequestRange = nil;
      AOptions: TACLHttpClientOptions = [hcoThreading]; AThreadPriority: TACLTaskPriority = atpNormal): THandle; overload;
    class function RequestNoThread(const AMethod, ALink: UnicodeString;
      AResponseData: TStream; out AErrorInfo: TACLWebErrorInfo; const APostData: TStream = nil;
      ARange: IACLWebRequestRange = nil; const AMaxAcceptSize: Int64 = 0): Boolean; overload;
    class function RequestNoThread(AMethod: TACLHttpMethod; const ALink: UnicodeString;
      AResponseData: TStream; out AErrorInfo: TACLWebErrorInfo; const APostData: TStream = nil;
      ARange: IACLWebRequestRange = nil; const AMaxAcceptSize: Int64 = 0): Boolean; overload;

    // Get
    class function Get(const ALink: UnicodeString; AHandler: IACLHttpClientHandler;
      ARange: IACLWebRequestRange = nil; AOptions: TACLHttpClientOptions = [hcoThreading]): THandle; overload;
    class function GetNoThread(const ALink: UnicodeString; AStream: TStream;
      out AErrorInfo: TACLWebErrorInfo; ARange: IACLWebRequestRange = nil; const AMaxAcceptSize: Int64 = 0): Boolean; overload;

    // Post
    class function PostNoThread(const ALink: UnicodeString;
      const APostData: AnsiString; AResponseData: TStream; out AErrorInfo: TACLWebErrorInfo): Boolean; overload;

    // Thread Utils
    class procedure Cancel(ATaskHandle: THandle; AWaitFor: Boolean = False);
    class function WaitFor(ATaskHandle: THandle): Boolean;
  end;

  { TACLHttpClientSyncTaskHandler }

  TACLHttpClientSyncTaskHandler = class(TACLUnknownObject, IACLHttpClientHandler)
  strict private
    FErrorInfo: TACLWebErrorInfo;
    FMaxAcceptSize: Int64;
    FStream: TStream;
  public
    constructor Create(AStream: TStream; const AMaxAcceptSize: Int64 = 0);
    // IACLHttpClientHandler
    function OnAccept(const AHeaders, AContentType: UnicodeString; const AContentSize: Int64): LongBool; virtual;
    function OnData(Data: PByte; Count: Integer): Boolean; virtual;
    procedure OnComplete(const AErrorInfo: TACLWebErrorInfo; ACanceled: LongBool); virtual;
    procedure OnProgress(const AReadBytes, ATotalBytes: Int64); virtual;
    //
    property ErrorInfo: TACLWebErrorInfo read FErrorInfo;
  end;

  { TACLHttpInputStream }

  TACLHttpInputStreamDownloadMode = (hisdmASAP, hisdmLazy);

  TACLHttpInputStream = class(TStream)
  protected const
    BlockID = $66524565;
    BlockSize = 64 * SIZE_ONE_KILOBYTE; // do not change, because of file structure
    WaitTimeout = 10000; // 10 seconds;
  private
    FCacheStream: TStream;
    FCacheStreamLock: TACLCriticalSection;
    FConnection: THttpConnection;
    FFatalError: Boolean;
    FFreeBlocks: TACLThreadList<Integer>;
    FFreeBlocksCursor: Integer;
    FFreeBlocksEvent: TACLEvent;
    FMode: TACLHttpInputStreamDownloadMode;
    FPosition: Int64;
    FSize: Int64;
    FUpdateThread: TACLPauseableThread;
    FURL: TACLWebURL;

    procedure AllocateCacheStream(const ASize: Int64);
  protected
    function GetSize: Int64; override;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(const URL: TACLWebURL; const ACachedFileName: string = ''; AMode: TACLHttpInputStreamDownloadMode = hisdmASAP);
    destructor Destroy; override;
    class function ValidateCacheStream(AStream: TStream): Boolean; overload;
    class procedure ValidateCacheStream(AStream: TStream; AFreeBlocks: TACLList<Integer>); overload;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    //
    property Mode: TACLHttpInputStreamDownloadMode read FMode write FMode;
  end;

implementation

uses
  System.StrUtils,
  System.SysUtils,
  System.Math,
  // ACL
  ACL.Classes.StringList,
  ACL.FastCode,
  ACL.Math,
  ACL.Parsers,
  ACL.Utils.FileSystem,
  ACL.Utils.Registry,
  ACL.Utils.Stream,
  ACL.Utils.Strings;

const
  sErrorCancel = 'The operation has been canceled by user.';
  sErrorContentType = 'Content type is not accepted';
  sErrorInternal = 'Internal connection error (%s)';
  sErrorRange = 'Range is not supported by Server';
  sErrorWrite = 'Cannot write data to the stream.';

  IdentConnection = 'Connection';
  IdentContentType = 'Content-Type';
  IdentCookie = 'Cookie';
  IdentKeepAlive = 'Keep-Alive';
  IdentRange = 'Range';
  IdentUserAgent = 'User-Agent';

type

  { EHttpError }

  EHttpError = class
  strict private
    FInfo: TACLWebErrorInfo;
  public
    constructor Create(const Code: Integer; const Text: string); overload;
    constructor Create(const DefaultText: string = ''); overload;
    //
    property Info: TACLWebErrorInfo read FInfo;
  end;

  { EHttpRangeError }

  EHttpRangeError = class(EHttpError)
  public
    constructor Create; reintroduce;
  end;

  { TACLHttpClientTask }

  TACLHttpClientTask = class(TACLTask)
  strict private
    FError: TACLWebErrorInfo;
    FHandler: IACLHttpClientHandler;
    FMethod: string;
    FOptions: TACLHttpClientOptions;
    FPostData: TStream;
    FPriority: TACLTaskPriority;
    FRange: IACLWebRequestRange;
    FURL: TACLWebURL;

    function CheckContentType(ARequest: THttpRequest): Boolean;
    function HandlerData(Data: PByte; Count: Integer): Boolean;
    function HandlerProgress(const APosition, ASize: Int64): Boolean;
  protected
    function DoAccept(ARequest: THttpRequest): Boolean;
    procedure DoComplete;

    procedure Complete; override;
    procedure Execute; override;
    function GetPriority: TACLTaskPriority; override;
  public
    constructor Create(AHandler: IACLHttpClientHandler;
      const AMethod, ARequest: UnicodeString; const APostData: TStream;
      const ARange: IACLWebRequestRange; APriority: TACLTaskPriority; AOptions: TACLHttpClientOptions);
    destructor Destroy; override;
    //
    property Method: string read FMethod;
    property Options: TACLHttpClientOptions read FOptions;
    property URL: TACLWebURL read FURL;
  end;

  { TACLHttpInputStreamUpdateThread }

  TACLHttpInputStreamUpdateThread = class(TACLPauseableThread)
  strict private
    FBlockBuffer: TACLByteBuffer;
    FStream: TACLHttpInputStream;

    function GetNextBlockIndex(out ABlockIndex: Integer): Boolean;
    procedure WriteBuffer(ABlockIndex: Integer);
  protected
    procedure Execute; override;
    //
    property BlockBuffer: TACLByteBuffer read FBlockBuffer;
    property Stream: TACLHttpInputStream read FStream;
  public
    constructor Create(AStream: TACLHttpInputStream);
    destructor Destroy; override;
  end;

procedure CallEvent(AProc: TProcedureRef; ASync: Boolean);
begin
  if ASync then
    RunInMainThread(AProc)
  else
    AProc();
end;

function HTTPQueryDWORD(AService: HINTERNET; ID: DWORD): DWORD;
var
  ABufferLength: DWORD;
  AReserved: DWORD;
begin
  AReserved := 0;
  ABufferLength := SizeOf(Result);
  if not HttpQueryInfo(AService, ID or HTTP_QUERY_FLAG_NUMBER, @Result, ABufferLength, AReserved) then
    Result := 0;
end;

function HTTPQueryString(AService: HINTERNET; ID: DWORD): UnicodeString;
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

{ EHttpError }

constructor EHttpError.Create(const DefaultText: string = '');
var
  ABuffer: array[Byte] of WideChar;
  ABufferLength: DWORD;
  AError: DWORD;
begin
  ABufferLength := Length(ABuffer);
  if InternetGetLastResponseInfoW(AError, @ABuffer[0], ABufferLength) and (AError > 0) then
  begin
    SetString(FInfo.ErrorMessage, PWideChar(@ABuffer[0]), ABufferLength);
    FInfo.ErrorCode := AError;
  end
  else
    if GetLastError <> 0 then
    begin
      FInfo.ErrorCode := GetLastError;
      FInfo.ErrorMessage := SysErrorMessage(FInfo.ErrorCode);
    end
    else
      Info.Initialize(acWebErrorUnknown, Format(sErrorInternal, [DefaultText]));
end;

constructor EHttpError.Create(const Code: Integer; const Text: string);
begin
  Info.Initialize(Code, Text);
end;

{ EHttpRangeError }

constructor EHttpRangeError.Create;
begin
  inherited Create(acWebErrorUnknown, sErrorRange);
end;

{ THttpConnection }

constructor THttpConnection.Create(const AHost: string; APort: Word; ASecured: Boolean);
begin
  FHost := AHost;
  FSecured := ASecured;
  CreateSession;

  FHandle := InternetConnectW(FSession, PWideChar(AHost), APort, nil, nil, INTERNET_SERVICE_HTTP, 0, 0);
  if FHandle = nil then
    raise EHttpError.Create('InternetConnectW failed');

  if (TACLWebSettings.ConnectionMode = ncmUserDefined) and (TACLWebSettings.Proxy.UserName <> '') then
  begin
    THttpConnection.SetOption(FHandle, INTERNET_OPTION_PROXY_USERNAME, TACLWebSettings.Proxy.UserName);
    THttpConnection.SetOption(FHandle, INTERNET_OPTION_PROXY_PASSWORD, TACLWebSettings.Proxy.UserPass);
  end;
end;

destructor THttpConnection.Destroy;
begin
  ReleaseHandle(FHandle);
  ReleaseHandle(FSession);
  inherited;
end;

class procedure THttpConnection.ReleaseHandle(var AHandle: HINTERNET);
begin
  if AHandle <> nil then
  begin
    InternetCloseHandle(AHandle);
    AHandle := nil;
  end;
end;

class procedure THttpConnection.SetOption(Handle: HINTERNET; Option: Cardinal; const Value: string);
begin
  InternetSetOptionW(Handle, Option, PWideChar(Value), Length(Value));
end;

class procedure THttpConnection.SetOption(Handle: HINTERNET; Option, Value: Cardinal);
begin
  InternetSetOption(Handle, Option, @Value, SizeOf(Value));
end;

procedure THttpConnection.CreateSession;
var
  AProxyServer: UnicodeString;
  AValue: DWORD;
begin
  case TACLWebSettings.ConnectionMode of
    ncmDirect:
      FSession := InternetOpenW(nil, INTERNET_OPEN_TYPE_DIRECT, nil, nil, 0);

    ncmUserDefined:
      begin
        AProxyServer := Format('http=%s:%s', [TACLWebSettings.Proxy.Server, TACLWebSettings.Proxy.ServerPort]);
        FSession := InternetOpenW(nil, INTERNET_OPEN_TYPE_PROXY, PWideChar(AProxyServer), nil, 0);
      end;

  else
    FSession := InternetOpenW(nil, INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  end;

  if FSession = nil then
    raise EHttpError.Create('InternetOpen failed');

  AValue := TACLWebSettings.ConnectionTimeOut;
  THttpConnection.SetOption(FSession, INTERNET_OPTION_DATA_SEND_TIMEOUT, AValue);
  THttpConnection.SetOption(FSession, INTERNET_OPTION_DATA_RECEIVE_TIMEOUT, AValue);
  THttpConnection.SetOption(FSession, INTERNET_OPTION_CONNECT_TIMEOUT, AValue);
end;

{ THttpHeader }

class function THttpHeaders.Contains(const AHeaders, AName: string): Boolean;
var
  AValue: string;
begin
  Result := Get(AHeaders, AName, AValue);
end;

class function THttpHeaders.Extract(var AHeaders: string; const AName: string; out AValue: string): Boolean;
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

class function THttpHeaders.Get(const AHeaders, AName: string; out AValue: string; out APosStart, APosFinish: Integer): Boolean;
begin
  AValue := acExtractString(AHeaders + acCRLF, AName + Delimiter, acCRLF, APosStart, APosFinish);
  Result := APosStart > 0;
end;

{ THttpRequest }

constructor THttpRequest.Create(AConnection: THttpConnection; const Method, Path: string);

  function BuildFlags: Cardinal;
  begin
    Result := INTERNET_FLAG_RELOAD or INTERNET_SERVICE_HTTP;
    if AConnection.Secured then
      Result := Result or INTERNET_FLAG_SECURE or INTERNET_FLAG_KEEP_CONNECTION;
  end;

begin
  FMethod := Method;
  FHost := AConnection.Host;
  FCookieURL := 'http' + IfThenW(AConnection.Secured, 's') + '://' + FHost;
  FHandle := HTTPOpenRequestW(AConnection.Handle, PWideChar(Method), PWideChar(Path), nil, nil, nil, BuildFlags, 0);
  if FHandle = nil then
    raise EHttpError.Create('HTTPOpenRequest failed');
end;

destructor THttpRequest.Destroy;
begin
  THttpConnection.ReleaseHandle(FHandle);
  inherited;
end;

procedure THttpRequest.Receive(ADataProc: THttpRequestDataProc; AProgressProc: THttpRequestProgressProc = nil);
var
  ABuffer: PByte;
  ABytesRead: Cardinal;
  AContentPosition: Int64;
  AContentSize: Int64;
begin
  ABuffer := AllocMem(BufferSize);
  try
    AContentSize := ContentLength;
    AContentPosition := 0;
    while HasData do
    begin
      if not InternetReadFile(Handle, ABuffer, BufferSize, ABytesRead) then
        raise EHttpError.Create('InternetReadFile failed');
      if ABytesRead = 0 then
        Break;
      if not ADataProc(ABuffer, ABytesRead) then
        raise EHttpError.Create(acWebErrorUnknown, sErrorWrite);
      if Assigned(AProgressProc) then
      begin
        Inc(AContentPosition, ABytesRead);
        if not AProgressProc(AContentPosition, AContentSize) then
          raise EHttpError.Create(acWebErrorCanceled, sErrorCancel);
      end;
    end;
  finally
    FreeMem(ABuffer);
  end;
end;

procedure THttpRequest.Send(ACustomHeaders: string = '';
  ARange: IACLWebRequestRange = nil; ADataStream: TStream = nil;
  AProgressProc: THttpRequestProgressProc = nil);

  procedure AddHeaderValue(AHeaders: TACLStringList; const AName, ADefaultValue: string);
  var
    AValue: string;
  begin
    if not THttpHeaders.Extract(ACustomHeaders, AName, AValue) then
      AValue := ADefaultValue;
    if AValue <> '' then
      AHeaders.Add(AName + THttpHeaders.Delimiter + AValue);
  end;

  function BuildRange: UnicodeString;
  begin
    Result := 'bytes=' + IntToStr(ARange.GetOffset) + '-';
    if ARange.GetSize >= 0 then
      Result := Result + IntToStr(ARange.GetOffset + ARange.GetSize - 1);
  end;

  function BuildHeaders: UnicodeString;
  var
    AHeaders: TACLStringList;
  begin
    AHeaders := TACLStringList.Create;
    try
      AHeaders.Add('Host: ' + FHost);
      AddHeaderValue(AHeaders, IdentUserAgent, TACLWebSettings.UserAgent);
      AddHeaderValue(AHeaders, IdentConnection, 'keep-alive');
      AddHeaderValue(AHeaders, IdentKeepAlive, '300');
      if acSameText(FMethod, TACLHttpClient.MethodNames[hmPost]) then
        AddHeaderValue(AHeaders, IdentContentType, 'application/x-www-form-urlencoded');
      if (ARange <> nil) and ((ARange.GetOffset > 0) or (ARange.GetSize > 0)) then
        AddHeaderValue(AHeaders, IdentRange, BuildRange);
      if ACustomHeaders <> '' then
        AHeaders.Add(ACustomHeaders);
      Result := Trim(AHeaders.Text);
    finally
      AHeaders.Free;
    end;
  end;

begin
  ProcessCookies(ACustomHeaders);
  if not SendCore(BuildHeaders, ADataStream, AProgressProc) then
    raise EHttpError.Create('HttpSendRequest failed');

  if (ARange <> nil) and (ARange.GetOffset > 0) then
  begin
    if StatusCode <> HTTP_STATUS_PARTIAL_CONTENT then
      raise EHttpRangeError.Create;
    if ContentRange = '' then
      raise EHttpRangeError.Create;
    if ContentLength = 0 then
      raise EHttpRangeError.Create;
  end;
end;

function THttpRequest.GetQueryValue(const ID: Integer): Integer;
begin
  Result := HTTPQueryDWORD(Handle, ID);
end;

function THttpRequest.GetQueryValueAsString(const ID: Integer): string;
begin
  Result := HTTPQueryString(Handle, ID);
end;

function THttpRequest.HasData: Boolean;
var
  X: DWORD;
begin
  Result := InternetQueryDataAvailable(Handle, X, 0, 0) and (X > 0);
end;

function THttpRequest.SendCore(const AHeaders: string;
  ADataStream: TStream = nil; AProgressProc: THttpRequestProgressProc = nil): Boolean;
var
  ABuffer: TInternetBuffersW;
  AContentPosition: Int64;
  AContentSize: Int64;
  AData: PByte;
  ADataUsed: Integer;
  ADataWritten: Cardinal;
begin
  Result := False;
  if ADataStream <> nil then
  begin
    ZeroMemory(@ABuffer, SizeOf(ABuffer));
    ABuffer.dwStructSize := SizeOf(ABuffer);
    ABuffer.lpcszHeader := PWideChar(AHeaders);
    ABuffer.dwHeadersLength := Length(AHeaders);
    ABuffer.dwHeadersTotal := Length(AHeaders);
    ABuffer.dwBufferTotal := ADataStream.Size;

    if HttpSendRequestEx(Handle, @ABuffer, nil, HSR_INITIATE, 0) then
    begin
      AContentPosition := 0;
      AContentSize := ADataStream.Size;
      ADataStream.Position := 0;

      AData := AllocMem(BufferSize);
      try
        repeat
          ADataUsed := ADataStream.Read(AData^, BufferSize);
          if ADataUsed > 0 then
          begin
            if not InternetWriteFile(Handle, AData, ADataUsed, ADataWritten) then
              Exit(False);
          end;

          if Assigned(AProgressProc) then
          begin
            Inc(AContentPosition, ADataWritten);
            if not AProgressProc(AContentPosition, AContentSize) then
              raise EHttpError.Create(acWebErrorCanceled, sErrorCancel);
          end;
        until ADataUsed = 0;
      finally
        FreeMem(AData);
      end;
      Result := HttpEndRequest(Handle, nil, 0, 0);
    end;
  end
  else
    Result := HttpSendRequest(Handle, PWideChar(AHeaders), Length(AHeaders), nil, 0);
end;

procedure THttpRequest.ProcessCookies(var AHeaders: string);
var
  AValue: string;
begin
  while THttpHeaders.Extract(AHeaders, IdentCookie, AValue) do
    InternetSetCookie(PChar(FCookieURL), nil, PChar(AValue));
end;

{ TACLHttpClient }

class function TACLHttpClient.Request(const AMethod, ALink: UnicodeString;
  AHandler: IACLHttpClientHandler; const APostData: TStream = nil; ARange: IACLWebRequestRange = nil;
  AOptions: TACLHttpClientOptions = [hcoThreading]; AThreadPriority: TACLTaskPriority = atpNormal): THandle;
var
  ATask: TACLHttpClientTask;
begin
  ATask := TACLHttpClientTask.Create(AHandler, AMethod, ALink, APostData, ARange, AThreadPriority, AOptions);
  if hcoThreading in AOptions then
    Result := TaskDispatcher.Run(ATask)
  else
    Result := TaskDispatcher.RunInCurrentThread(ATask);
end;

class function TACLHttpClient.Request(AMethod: TACLHttpMethod; const ALink: UnicodeString;
  AHandler: IACLHttpClientHandler; const APostData: TStream = nil; ARange: IACLWebRequestRange = nil;
  AOptions: TACLHttpClientOptions = [hcoThreading]; AThreadPriority: TACLTaskPriority = atpNormal): THandle;
begin
  Result := Request(MethodNames[AMethod], ALink, AHandler, APostData, ARange, AOptions, AThreadPriority);
end;

class function TACLHttpClient.RequestNoThread(
  const AMethod, ALink: UnicodeString; AResponseData: TStream; out AErrorInfo: TACLWebErrorInfo;
  const APostData: TStream = nil; ARange: IACLWebRequestRange = nil; const AMaxAcceptSize: Int64 = 0): Boolean;
var
  ATaskHandler: TACLHttpClientSyncTaskHandler;
begin
  ATaskHandler := TACLHttpClientSyncTaskHandler.Create(AResponseData, AMaxAcceptSize);
  try
    Request(AMethod, ALink, ATaskHandler, APostData, ARange, []);
    AErrorInfo := ATaskHandler.ErrorInfo;
    Result := AErrorInfo.ErrorCode = 0;
  finally
    ATaskHandler.Free;
  end;
end;

class function TACLHttpClient.RequestNoThread(AMethod: TACLHttpMethod;
  const ALink: UnicodeString; AResponseData: TStream; out AErrorInfo: TACLWebErrorInfo;
  const APostData: TStream = nil; ARange: IACLWebRequestRange = nil; const AMaxAcceptSize: Int64 = 0): Boolean;
var
  ATaskHandler: TACLHttpClientSyncTaskHandler;
begin
  ATaskHandler := TACLHttpClientSyncTaskHandler.Create(AResponseData, AMaxAcceptSize);
  try
    Request(AMethod, ALink, ATaskHandler, APostData, ARange, []);
    AErrorInfo := ATaskHandler.ErrorInfo;
    Result := AErrorInfo.ErrorCode = 0;
  finally
    ATaskHandler.Free;
  end;
end;

class function TACLHttpClient.Get(const ALink: UnicodeString; AHandler: IACLHttpClientHandler;
  ARange: IACLWebRequestRange = nil; AOptions: TACLHttpClientOptions = [hcoThreading]): THandle;
begin
  Result := Request(hmGet, ALink, AHandler, nil, ARange, AOptions);
end;

class function TACLHttpClient.GetNoThread(const ALink: UnicodeString; AStream: TStream;
  out AErrorInfo: TACLWebErrorInfo; ARange: IACLWebRequestRange = nil; const AMaxAcceptSize: Int64 = 0): Boolean;
begin
  Result := RequestNoThread(hmGet, ALink, AStream, AErrorInfo, nil, ARange, AMaxAcceptSize);
end;

class function TACLHttpClient.PostNoThread(const ALink: UnicodeString;
  const APostData: AnsiString; AResponseData: TStream; out AErrorInfo: TACLWebErrorInfo): Boolean;
var
  APostStream: TMemoryStream;
begin
  APostStream := TMemoryStream.Create;
  try
    APostStream.Size := Length(APostData);
    Move(PAnsiChar(APostData)^, APostStream.Memory^, APostStream.Size);
    Result := RequestNoThread(hmPost, ALink, AResponseData, AErrorInfo, APostStream);
  finally
    APostStream.Free;
  end;
end;

class procedure TACLHttpClient.Cancel(ATaskHandle: THandle; AWaitFor: Boolean);
begin
  TaskDispatcher.Cancel(ATaskHandle, AWaitFor);
end;

class function TACLHttpClient.WaitFor(ATaskHandle: THandle): Boolean;
begin
  Result := TaskDispatcher.WaitFor(ATaskHandle);
end;

{ TACLHttpClientTask }

constructor TACLHttpClientTask.Create(AHandler: IACLHttpClientHandler;
  const AMethod, ARequest: UnicodeString; const APostData: TStream;
  const ARange: IACLWebRequestRange; APriority: TACLTaskPriority; AOptions: TACLHttpClientOptions);
begin
  inherited Create;
  FError.Reset;
  FMethod := AMethod;
  FHandler := AHandler;
  FOptions := AOptions;
  FRange := ARange;
  FPostData := APostData;
  FPriority := APriority;
  FURL := TACLWebURL.ParseHttp(ARequest);
end;

destructor TACLHttpClientTask.Destroy;
begin
  if hcoFreePostData in FOptions then
    FreeAndNil(FPostData);
  inherited Destroy;
end;

function TACLHttpClientTask.DoAccept(ARequest: THttpRequest): Boolean;
var
  AResult: Boolean;
begin
  CallEvent(
    procedure
    begin
      AResult := FHandler.OnAccept(ARequest.RawHeaders, ARequest.ContentType, ARequest.ContentLength);
    end,
    hcoSyncEventAccept in Options);

  Result := AResult;
end;

procedure TACLHttpClientTask.DoComplete;
begin
  CallEvent(
    procedure
    begin
      FHandler.OnComplete(FError, Canceled);
    end,
    hcoSyncEventComplete in Options);
end;

procedure TACLHttpClientTask.Complete;
begin
  inherited Complete;
  if Canceled then
    FError.Initialize(acWebErrorCanceled, sErrorCancel);
  DoComplete;
end;

procedure TACLHttpClientTask.Execute;
var
  AConnection: THttpConnection;
  ARequest: THttpRequest;
begin
  try
    AConnection := THttpConnection.Create(URL.Host, URL.Port, URL.Secured);
    try
      if not Canceled then
      begin
        ARequest := THttpRequest.Create(AConnection, Method, URL.Path);
        try
          ARequest.Send(URL.CustomHeaders, FRange, FPostData, HandlerProgress);
          if CheckContentType(ARequest) and not Canceled then
            ARequest.Receive(HandlerData, HandlerProgress);
        finally
          ARequest.Free;
        end;
      end;
    finally
      AConnection.Free;
    end;
  except
    on E: EHttpError do
      FError := E.Info;
  end;
end;

function TACLHttpClientTask.GetPriority: TACLTaskPriority;
begin
  Result := FPriority;
end;

function TACLHttpClientTask.CheckContentType(ARequest: THttpRequest): Boolean;
begin
  if not InRange(ARequest.StatusCode, 200, 299) then
  begin
    FError.Initialize(ARequest.StatusCode, ARequest.StatusText);
    Result := ARequest.ContentLength > 0;
  end
  else
    if not DoAccept(ARequest) then
    begin
      FError.Initialize(acWebErrorNotAccepted, sErrorContentType);
      Result := False;
    end
    else
      Result := True;
end;

function TACLHttpClientTask.HandlerData(Data: PByte; Count: Integer): Boolean;
begin
  Result := FHandler.OnData(Data, Count);
end;

function TACLHttpClientTask.HandlerProgress(const APosition, ASize: Int64): Boolean;
begin
  Result := not Canceled;
  CallEvent(
    procedure
    begin
      FHandler.OnProgress(APosition, ASize);
    end,
    hcoSyncEventProgress in Options);
end;

{ TACLHttpClientSyncTaskHandler }

constructor TACLHttpClientSyncTaskHandler.Create(AStream: TStream; const AMaxAcceptSize: Int64 = 0);
begin
  inherited Create;
  FMaxAcceptSize := AMaxAcceptSize;
  FStream := AStream;
end;

function TACLHttpClientSyncTaskHandler.OnAccept(const AHeaders, AContentType: UnicodeString; const AContentSize: Int64): LongBool;
begin
  Result := (FMaxAcceptSize = 0) or (AContentSize <= FMaxAcceptSize);
end;

function TACLHttpClientSyncTaskHandler.OnData(Data: PByte; Count: Integer): Boolean;
begin
  Result := (FStream <> nil) and (FStream.Write(Data^, Count) = Count);
end;

procedure TACLHttpClientSyncTaskHandler.OnComplete(const AErrorInfo: TACLWebErrorInfo; ACanceled: LongBool);
begin
  FErrorInfo := AErrorInfo;
end;

procedure TACLHttpClientSyncTaskHandler.OnProgress(const AReadBytes, ATotalBytes: Int64);
begin
  // do nothing
end;

{ TACLHttpInputStream }

constructor TACLHttpInputStream.Create(const URL: TACLWebURL;
  const ACachedFileName: string = ''; AMode: TACLHttpInputStreamDownloadMode = hisdmASAP);
var
  AList: TACLList<Integer>;
begin
  inherited Create;
  FURL := URL;
  FMode := AMode;
  FFreeBlocks := TACLThreadList<Integer>.Create;
  FFreeBlocksEvent := TACLEvent.Create;
  FCacheStreamLock := TACLCriticalSection.Create(Self, 'Lock');

  if acFileExists(ACachedFileName) then
  begin
    FCacheStream := TACLFileStream.Create(ACachedFileName, fmOpenReadWrite or fmShareDenyNone);
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
    FConnection := THttpConnection.Create(URL.Host, URL.Port, URL.Secured);

    // Fetch the size
    with THttpRequest.Create(FConnection, 'GET', URL.Path) do
    try
      Send(URL.CustomHeaders);
      FSize := ContentLength;
    finally
      Free;
    end;

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

    // Start the Download Thread
    FUpdateThread := TACLHttpInputStreamUpdateThread.Create(Self);
  end;
end;

destructor TACLHttpInputStream.Destroy;
begin
  // do no change the order
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
  AFreeBlocks: TACLList<Integer>;
begin
  AFreeBlocks := TACLList<Integer>.Create;
  try
    ValidateCacheStream(AStream, AFreeBlocks);
    Result := AFreeBlocks.Count = 0;
  finally
    AFreeBlocks.Free;
  end;
end;

class procedure TACLHttpInputStream.ValidateCacheStream(AStream: TStream; AFreeBlocks: TACLList<Integer>);
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

    // Read Cached Data
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
  ARequest: THttpRequest;
begin
  while not Terminated do
  begin
    if FStream.FMode = hisdmLazy then
      CheckForPause;
    if GetNextBlockIndex(ABlockIndex) then
    try
      ARequest := THttpRequest.Create(Stream.FConnection, 'GET', Stream.FURL.Path);
      try
        BlockBuffer.Used := 0;
        ARequest.Send(Stream.FURL.CustomHeaders, TACLWebRequestRange.Create(ABlockIndex * TACLHttpInputStream.BlockSize));
        ARequest.Receive(
          function (Data: PByte; Count: Integer): Boolean
          var
            ANextBlockIndex: Integer;
          begin
            Count := Min(Count, BlockBuffer.Unused);
            FastMove(Data^, BlockBuffer.DataArr^[FBlockBuffer.Used], Count);
            BlockBuffer.Used := BlockBuffer.Used + Count;
            if Terminated then
              Exit(False);
            if BlockBuffer.Unused = 0 then
            begin
              WriteBuffer(ABlockIndex);
              if not GetNextBlockIndex(ANextBlockIndex) or (ANextBlockIndex <> ABlockIndex + 1) then
                Exit(False);
              ABlockIndex := ANextBlockIndex;
            end;
            Result := True;
          end);

        WriteBuffer(ABlockIndex);
      finally
        ARequest.Free;
      end;
    except
      on E: EHttpError do
      begin
        Stream.FFatalError := True;
        Stream.FFreeBlocksEvent.Reset;
        Terminate;
      end;
    end
    else
      Sleep(100);
  end;
end;

function TACLHttpInputStreamUpdateThread.GetNextBlockIndex(out ABlockIndex: Integer): Boolean;
begin
  with Stream.FFreeBlocks.LockList do
  try
    if Count > 0 then
    begin
      Stream.FFreeBlocksCursor := Min(Stream.FFreeBlocksCursor, Count - 1);
      ABlockIndex := List[Stream.FFreeBlocksCursor];
    end
    else
      ABlockIndex := -1;
  finally
    Stream.FFreeBlocks.UnlockList;
  end;
  Result := ABlockIndex >= 0;
end;

procedure TACLHttpInputStreamUpdateThread.WriteBuffer(ABlockIndex: Integer);
begin
  if BlockBuffer.Used > 0 then
  try
    Stream.FCacheStreamLock.Enter;
    try
      Stream.FCacheStream.Position := ABlockIndex * TACLHttpInputStream.BlockSize;
      Stream.FCacheStream.WriteBuffer(BlockBuffer.Data^, BlockBuffer.Used);
    finally
      Stream.FCacheStreamLock.Leave;
    end;

    with Stream.FFreeBlocks.LockList do
    try
      Remove(ABlockIndex);
      Stream.FFreeBlocksEvent.Signal;
    finally
      Stream.FFreeBlocks.UnlockList;
    end;
  finally
    BlockBuffer.Used := 0;
  end;
end;

end.
