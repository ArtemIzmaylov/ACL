{%MainUnit ACL.Web.Http.pas}

uses
  libcurl, unixtype;

const
  CURL_WRITEFUNC_ERROR = UInt32($FFFFFFFF);

type

  { THttpRequestData }

  THttpRequestData = class
  strict private const
    HttpHello = 'HTTP/';
  strict private
    FHeaders: TACLStringList;
    FHeadersProcessed: Boolean;
    FLastError: TACLWebErrorInfo;
    FPosition: Int64;
    FPostData: TStream;
    FResponce: THttpResponse;

    FOnAccept: TConsumerC<THttpResponse>;
    FOnProgress: THttpProgressProc;
    FOnReceive: THttpDataProc;

    procedure Progress(APosition, ATotal: Int64);
    procedure ProcessHeaders;
    procedure SetUserError(AError: Exception);
  protected
    class function OnHeader(buffer: PAnsiChar; size: size_t;
      nitems: size_t; data: THttpRequestData): size_t; cdecl; static;
    class function OnRead(buffer: PAnsiChar; size: size_t;
      nitems: size_t; data: THttpRequestData): size_t; cdecl; static;
    class function OnWrite(buffer: PAnsiChar; size: size_t;
      nitems: size_t; data: THttpRequestData): size_t; cdecl; static;
  public
    constructor Create(
      APostData: TStream = nil;
      AOnAccept: TConsumerC<THttpResponse> = nil;
      AOnProgress: THttpProgressProc = nil;
      AOnReceive: THttpDataProc = nil);
    destructor Destroy; override;
    property LastError: TACLWebErrorInfo read FLastError;
    property Responce: THttpResponse read FResponce;
  end;

  { THttpConnectionImpl }

  THttpConnectionImpl = class(THttpConnection)
  strict private
    FErrorBuffer: PAnsiChar;
    FHandle: PCURL;
    procedure CheckCURL(ACode: CURLcode);
    procedure SetOpt(AKey: CURLoption; AValue: Pointer);
  protected
    function RequestCore(const AMethod: string;
      AHeaders: TACLStringList;
      APostData: TStream = nil;
      AIgnoreCertificateIssues: Boolean = False;
      AOnAccept: TConsumerC<THttpResponse> = nil;
      AOnProgress: THttpProgressProc = nil;
      AOnReceive: THttpDataProc = nil): THttpResponse; override;
  public
    constructor Create(const URL: TACLWebURL);
    destructor Destroy; override;
  end;

  { THttpRequestData }

  constructor THttpRequestData.Create(
    APostData: TStream; AOnAccept: TConsumerC<THttpResponse>;
    AOnProgress: THttpProgressProc; AOnReceive: THttpDataProc);
  begin
    FOnReceive := AOnReceive;
    FOnAccept := AOnAccept;
    FOnProgress := AOnProgress;
    FPostData := APostData;
    FHeaders := THttpHeaders.Create;
    FResponce.Init;
  end;

  destructor THttpRequestData.Destroy;
  begin
    FreeAndNil(FHeaders);
    inherited Destroy;
  end;

  class function THttpRequestData.OnHeader(buffer: PAnsiChar;
    size, nitems: size_t; data: THttpRequestData): size_t; cdecl;
  var
    LLine: string;
  begin
    Result := size * nitems;
    LLine := acTrim(acMakeString(buffer, Result));
    // Тут мы можем получить хидеры от прокси, посему оставляем только от сайта (последние)
    if acBeginsWith(LLine, HttpHello, False) then
      data.FHeaders.Clear;
    data.FHeaders.Add(LLine);
  end;

  class function THttpRequestData.OnRead(buffer: PAnsiChar;
    size, nitems: size_t; data: THttpRequestData): size_t; cdecl;
  begin
    try
      Result := data.FPostData.Read(buffer^, size * nitems);
      data.Progress(data.FPostData.Position, data.FPostData.Size);
    except
      on E: Exception do
      begin
        data.SetUserError(E);
        Result := CURL_READFUNC_ABORT;
      end;
    end;
  end;

  class function THttpRequestData.OnWrite(buffer: PAnsiChar;
    size, nitems: size_t; data: THttpRequestData): size_t; cdecl;
  begin
    Result := size * nitems;
    try
      if not data.FHeadersProcessed then
      begin
        data.FHeadersProcessed := True;
        data.ProcessHeaders;
      end;
      Inc(data.FPosition, Result);
      if not data.FOnReceive(PByte(buffer), Result) then
        raise EHttpWriteError.Create;
      data.Progress(data.FPosition, data.FResponce.ContentLength);
    except
      on E: Exception do
      begin
        data.SetUserError(E);
        Result := CURL_WRITEFUNC_ERROR;
      end;
    end;
  end;

  procedure THttpRequestData.Progress(APosition, ATotal: Int64);
  begin
    if Assigned(FOnProgress) and not FOnProgress(APosition, ATotal) then
      raise EHttpCancel.Create;
  end;

  procedure THttpRequestData.ProcessHeaders;
  var
    LParts: TStringDynArray;
  begin
    FResponce.Init;
    FResponce.RawHeaders := THttpHeaders.Build(FHeaders);
    FResponce.ContentLength := StrToInt64Def(FHeaders.ValueFromName[THttpHeaders.IdentContentLength], -1);
    FResponce.ContentRange := FHeaders.ValueFromName[THttpHeaders.IdentContentRange];
    FResponce.ContentType := FHeaders.ValueFromName[THttpHeaders.IdentContentType];
    if (FHeaders.Count > 0) and (acSplitString(FHeaders.First, ' ', LParts) >= 2) then
    begin
      if acBeginsWith(LParts[0], HttpHello, False) then
      begin
        FResponce.StatusCode := StrToIntDef(LParts[1], 0);
        if Length(LParts) > 2 then
          FResponce.StatusText := LParts[2];
      end;
    end;
    if Assigned(FOnAccept) then
      FOnAccept(FResponce);
  end;

  procedure THttpRequestData.SetUserError(AError: Exception);
  begin
    if AError is EHttpError then
      FLastError := EHttpError(AError).Info;
  end;

  { THttpConnectionImpl }

  constructor THttpConnectionImpl.Create(const URL: TACLWebURL);
  begin
    FURL := URL;
    FHandle := curl_easy_init();
    FErrorBuffer := AllocMem(CURL_ERROR_SIZE + 1);
  end;

  destructor THttpConnectionImpl.Destroy;
  begin
    curl_easy_cleanup(FHandle);
    FreeMem(FErrorBuffer);
    inherited;
  end;

  procedure THttpConnectionImpl.CheckCURL(ACode: CURLcode);
  begin
    if ACode <> CURLE_OK then
      raise EHttpError.Create(acString(FErrorBuffer), Ord(ACode));
  end;

  procedure THttpConnectionImpl.SetOpt(AKey: CURLoption; AValue: Pointer);
  begin
    CheckCURL(curl_easy_setopt(FHandle, AKey, AValue));
  end;

  function THttpConnectionImpl.RequestCore(const AMethod: string;
    AHeaders: TACLStringList; APostData: TStream;
    AIgnoreCertificateIssues: Boolean;
    AOnAccept: TConsumerC<THttpResponse>;
    AOnProgress: THttpProgressProc;
    AOnReceive: THttpDataProc): THttpResponse;

    function BuildHeaders: Pcurl_slist;
    var
      I: Integer;
      LCurr: Pcurl_slist;
    begin
      LCurr := nil;
      Result := nil;
      for I := 0 to AHeaders.Count - 1 do
      begin
        LCurr := curl_slist_append(LCurr, PAnsiChar(AHeaders[I]));
        if Result = nil then
          Result := LCurr;
      end;
    end;

  var
    I: Integer;
    LHeaders: Pcurl_slist;
    LProxy: string;
    LResult: CURLcode;
    LRequest: THttpRequestData;
    LStream: TStream;
    LUrl: TACLWebURL;
  begin
    curl_easy_reset(FHandle);
    SetOpt(CURLOPT_ERRORBUFFER, FErrorBuffer);
    SetOpt(CURLOPT_FOLLOWLOCATION, Pointer(1));
    SetOpt(CURLOPT_IPRESOLVE, Pointer(CURL_IPRESOLVE_V4));

    // Multiplier because host resolving is too slow on Linux
    SetOpt(CURLOPT_CONNECTTIMEOUT_MS, Pointer(5 * TACLWebSettings.ConnectionTimeOut));

    if AIgnoreCertificateIssues then
    begin
      SetOpt(CURLOPT_SSL_VERIFYPEER, nil);
      SetOpt(CURLOPT_SSL_VERIFYHOST, nil);
    end;

    if TACLWebSettings.ActualConnectionMode = ncmUserDefined then
    begin
      LProxy := TACLWebSettings.Proxy.Server;
      if TACLWebSettings.Proxy.ServerPort <> '' then
        LProxy := LProxy + ':' + TACLWebSettings.Proxy.ServerPort;
      if LProxy <> '' then
      begin
        SetOpt(CURLOPT_PROXY, PChar(LProxy));
        SetOpt(CURLOPT_PROXYUSERNAME, PChar(TACLWebSettings.Proxy.UserName));
        SetOpt(CURLOPT_PROXYPASSWORD, PChar(TACLWebSettings.Proxy.UserPass));
      end;
    end;

    LUrl := URL;
    LUrl.CustomHeaders := '';
    SetOpt(CURLOPT_URL, PChar(LUrl.ToString));
    SetOpt(CURLOPT_CUSTOMREQUEST, PChar(AMethod));

    LRequest := THttpRequestData.Create(APostData, AOnAccept, AOnProgress, AOnReceive);
    try
      if APostData <> nil then
      begin
        SetOpt(CURLOPT_UPLOAD, Pointer(1));
        SetOpt(CURLOPT_READDATA, Pointer(LRequest));
        SetOpt(CURLOPT_READFUNCTION, @LRequest.OnRead);
        SetOpt(CURLOPT_INFILESIZE_LARGE, Pointer(curl_off_t(APostData.Size)));
      end;

      SetOpt(CURLOPT_HEADERDATA, LRequest);
      SetOpt(CURLOPT_HEADERFUNCTION, @LRequest.OnHeader);

      SetOpt(CURLOPT_WRITEDATA, LRequest);
      SetOpt(CURLOPT_WRITEFUNCTION, @LRequest.OnWrite);

      LHeaders := BuildHeaders;
      try
        if LHeaders <> nil then
          SetOpt(CURLOPT_HTTPHEADER, LHeaders);
        LResult := curl_easy_perform(FHandle);
      finally
        if LHeaders <> nil then
          curl_slist_free_all(LHeaders);
      end;

      if LResult <> CURLE_OK then
      begin
        if not LRequest.LastError.Succeeded then
          raise EHttpError.Create(LRequest.LastError);
        CheckCURL(LResult);
      end;

      Result := LRequest.Responce;
    finally
      LRequest.Free;
    end;
  end;
