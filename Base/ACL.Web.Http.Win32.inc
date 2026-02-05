{%MainUnit ACL.Web.Http.pas}

uses
  Winapi.Windows,
  Winapi.WinInet;

const
  sErrorWriteToServer = 'Cannot post data to the server.';

type

  { EHttpWin32Error }

  EHttpWin32Error = class(EHttpError)
  public
    constructor Create(const DefaultText: string = ''); overload;
  end;

  { THttpConnectionImpl }

  THttpConnectionImpl = class(THttpConnection)
  strict private
    FHandle: HINTERNET;
    FSession: HINTERNET;
  protected
    function RequestCore(const AMethod: string;
      AHeaders: TACLStringList; APostData: TStream = nil;
      AIgnoreCertificateIssues: Boolean = False;
      AOnAccept: TConsumerC<THttpResponse> = nil;
      AOnProgress: THttpProgressProc = nil;
      AOnReceive: THttpDataProc = nil): THttpResponse; override;
  public
    constructor Create(const URL: TACLWebURL);
    destructor Destroy; override;
  end;

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

  procedure SetOption(Handle: HINTERNET; Option: Cardinal; const Value: string); overload;
  begin
    InternetSetOptionW(Handle, Option, PWideChar(Value), Length(Value));
  end;

  procedure SetOption(Handle: HINTERNET; Option, Value: Cardinal); overload;
  begin
    InternetSetOption(Handle, Option, @Value, SizeOf(Value));
  end;

  { THttpConnectionImpl }

  constructor THttpConnectionImpl.Create(const URL: TACLWebURL);
  var
    LProxyServer: string;
  begin
    FURL := URL;
    case TACLWebSettings.ActualConnectionMode of
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
      raise EHttpWin32Error.Create('InternetOpen failed');

    SetOption(FSession, INTERNET_OPTION_DATA_SEND_TIMEOUT, TACLWebSettings.ConnectionTimeOut);
    SetOption(FSession, INTERNET_OPTION_DATA_RECEIVE_TIMEOUT, TACLWebSettings.ConnectionTimeOut);
    SetOption(FSession, INTERNET_OPTION_CONNECT_TIMEOUT, TACLWebSettings.ConnectionTimeOut);

    FHandle := InternetConnectW(FSession, PWideChar(URL.Host), URL.Port, nil, nil, INTERNET_SERVICE_HTTP, 0, 0);
    if FHandle = nil then
      raise EHttpWin32Error.Create('InternetConnectW failed');

    if (TACLWebSettings.ActualConnectionMode = ncmUserDefined) and (TACLWebSettings.Proxy.UserName <> '') then
    begin
      SetOption(FHandle, INTERNET_OPTION_PROXY_USERNAME, TACLWebSettings.Proxy.UserName);
      SetOption(FHandle, INTERNET_OPTION_PROXY_PASSWORD, TACLWebSettings.Proxy.UserPass);
    end;
  end;

  destructor THttpConnectionImpl.Destroy;
  begin
    if FHandle <> nil then
      InternetCloseHandle(FHandle);
    if FSession <> nil then
      InternetCloseHandle(FSession);
    inherited;
  end;

  function THttpConnectionImpl.RequestCore(const AMethod: string;
    AHeaders: TACLStringList; APostData: TStream = nil;
    AIgnoreCertificateIssues: Boolean = False;
    AOnAccept: TConsumerC<THttpResponse> = nil;
    AOnProgress: THttpProgressProc = nil;
    AOnReceive: THttpDataProc = nil): THttpResponse;
  const
    BufferSize = 256 * SIZE_ONE_KILOBYTE;

    function SendRequest(ARequest: HINTERNET): Boolean;
    var
      LBuffer: TInternetBuffersW;
      LContentPosition: Int64;
      LContentSize: Int64;
      LData: PByte;
      LDataUsed: Integer;
      LDataWritten: Cardinal;
      LHeaders: string;
    begin
      Result := False;
      LHeaders := THttpHeaders.Build(AHeaders);
      if APostData <> nil then
      begin
        ZeroMemory(@LBuffer, SizeOf(LBuffer));
        LBuffer.dwStructSize := SizeOf(LBuffer);
        LBuffer.lpcszHeader := PWideChar(LHeaders);
        LBuffer.dwHeadersLength := Length(LHeaders);
        LBuffer.dwHeadersTotal := Length(LHeaders);
        LBuffer.dwBufferTotal := APostData.Size;

        if HttpSendRequestEx(ARequest, @LBuffer, nil, HSR_INITIATE, 0) then
        begin
          LContentPosition := 0;
          LContentSize := APostData.Size;
          APostData.Position := 0;

          LData := AllocMem(BufferSize);
          try
            repeat
              LDataUsed := APostData.Read(LData^, BufferSize);
              if LDataUsed > 0 then
              begin
                if not InternetWriteFile(ARequest, LData, LDataUsed, LDataWritten) then
                  raise EHttpWin32Error.Create(sErrorWriteToServer, acWebErrorUnknown);
              end;

              if Assigned(AOnProgress) then
              begin
                Inc(LContentPosition, LDataWritten);
                if not AOnProgress(LContentPosition, LContentSize) then
                  raise EHttpCancel.Create;
              end;
            until LDataUsed = 0;
          finally
            FreeMem(LData);
          end;
          Result := HttpEndRequest(ARequest, nil, 0, 0);
        end;
      end
      else
        Result := HttpSendRequest(ARequest, PWideChar(LHeaders), Length(LHeaders), nil, 0);
    end;

    procedure ReceiveData(ARequest: HINTERNET; const AResponse: THttpResponse);
    var
      LBuffer: PByte;
      LBytesRead: Cardinal;
      LContentPosition: Int64;
      LContentSize: Int64;
      LRemaining: Cardinal;
    begin
      LBuffer := AllocMem(BufferSize);
      try
        LContentPosition := 0;
        LContentSize := AResponse.ContentLength;
        while InternetQueryDataAvailable(ARequest, LRemaining, 0, 0) and (LRemaining > 0) do
        begin
          if not InternetReadFile(ARequest, LBuffer, BufferSize, LBytesRead) then
            raise EHttpWin32Error.Create('InternetReadFile failed');
          if LBytesRead = 0 then
            Break;
          if not AOnReceive(LBuffer, LBytesRead) then
            raise EHttpWriteError.Create;
          if Assigned(AOnProgress) then
          begin
            Inc(LContentPosition, LBytesRead);
            if not AOnProgress(LContentPosition, LContentSize) then
              raise EHttpCancel.Create;
          end;
        end;
      finally
        FreeMem(LBuffer);
      end;
    end;

  var
    LCookieURL: string;
    LFlags: Cardinal;
    LLength: Cardinal;
    LRequest: HINTERNET;
  begin
    LCookieURL := 'http' + IfThenW(URL.Secured, 's') + '://' + URL.Host;
    for var I := AHeaders.Count - 1 downto 0 do
    begin
      if AHeaders.Names[I] = THttpHeaders.IdentCookie then
      begin
        InternetSetCookie(PChar(LCookieURL), nil, PChar(AHeaders.ValueFromIndex[I]));
        AHeaders.Delete(I);
      end;
    end;
    AHeaders.Insert(0, 'Host: ' + Url.Host);

    LFlags := INTERNET_FLAG_RELOAD or INTERNET_SERVICE_HTTP;
    if URL.Secured then
      LFlags := LFlags or INTERNET_FLAG_SECURE or INTERNET_FLAG_KEEP_CONNECTION;

    LRequest := HTTPOpenRequestW(FHandle, PWideChar(AMethod), PWideChar(FUrl.Path), nil, nil, nil, LFlags, 0);
    try
      if LRequest = nil then
        raise EHttpWin32Error.Create('HttpOpenRequest failed');

      if AIgnoreCertificateIssues then
      begin
        LLength := SizeOf(LFlags);
        InternetQueryOptionW(LRequest, INTERNET_OPTION_SECURITY_FLAGS, @LFlags, LLength);
        LFlags := LFlags or
          SECURITY_FLAG_IGNORE_UNKNOWN_CA or
          SECURITY_FLAG_IGNORE_CERT_CN_INVALID or
          SECURITY_FLAG_IGNORE_CERT_DATE_INVALID;
        InternetSetOptionW(LRequest, INTERNET_OPTION_SECURITY_FLAGS, @LFlags, LLength);
      end;

      if not SendRequest(LRequest) then
        raise EHttpWin32Error.Create(
          'HttpSendRequest failed.' + sLineBreak +
          'Maybe a certificate issue. Ensure that TLS 1.2/1.3 are switched on');

      Result.Init;
      Result.ContentRange := HTTPQueryString(LRequest, HTTP_QUERY_CONTENT_RANGE);
      Result.ContentLength := HttpQueryDWORD(LRequest, HTTP_QUERY_CONTENT_LENGTH);
      Result.ContentType := HTTPQueryString(LRequest, HTTP_QUERY_CONTENT_TYPE);
      Result.StatusCode := HttpQueryDWORD(LRequest, HTTP_QUERY_STATUS_CODE);
      Result.StatusText := HttpQueryString(LRequest, HTTP_QUERY_STATUS_TEXT);
      Result.RawHeaders := HttpQueryString(LRequest, HTTP_QUERY_RAW_HEADERS);

      if Assigned(AOnAccept) then
        AOnAccept(Result);
      if Assigned(AOnReceive) then
        ReceiveData(LRequest, Result);
    finally
      InternetCloseHandle(LRequest);
    end;
  end;

  { EHttpWin32Error }

  constructor EHttpWin32Error.Create(const DefaultText: string = '');
  var
    LBuffer: array[Byte] of WideChar;
    LBufferLength: DWORD;
    LError: DWORD;
    LErrorCode: DWORD;
  begin
    LErrorCode := 0;
    LError := GetLastError; // first!
    LBufferLength := Length(LBuffer);
    if InternetGetLastResponseInfoW(LErrorCode, @LBuffer[0], LBufferLength) and (LErrorCode > 0) then
      Create(acMakeString(PWideChar(@LBuffer[0]), LBufferLength), LErrorCode)
    else if LError <> 0 then
      Create(IfThenW(SysErrorMessage(LError), DefaultText), LError)
    else
      inherited Create(DefaultText);
  end;
