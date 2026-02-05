{%MainUnit ACL.Web.Http.pas}

uses
  FPHttpClient,
  OpenSSLSockets,
  URIParser;

type

  { THttpConnectionImpl }

  THttpConnectionImpl = class(THttpConnection)
  strict private type
  {$REGION ' Types '}
    TStreamAdapter = class(TStream)
    strict private
      FOnData: THttpDataProc;
    public
      constructor Create(AOnData: THttpDataProc);
      function Write(const Buffer; Count: Longint): Longint; override;
    end;
  {$ENDREGION}
  strict private
    FClient: TFPHTTPClient;
    FOnAccept: TConsumerC<THttpResponse>;
    FOnProgress: THttpProgressProc;
    procedure DoHeaders(Sender: TObject);
    procedure DoProgress(Sender : TObject; const Size, Pos: Int64);
    function DoReadResponse: THttpResponse;
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

  { THttpConnectionImpl }

  constructor THttpConnectionImpl.Create(const URL: TACLWebURL);
  begin
    FURL := URL;
    FClient := TFPHTTPClient.Create(nil);
    FClient.AllowRedirect := True;
    FClient.ConnectTimeout := TACLWebSettings.ConnectionTimeOut;
    FClient.IOTimeout := TACLWebSettings.ConnectionTimeOut;

    if TACLWebSettings.ActualConnectionMode = ncmUserDefined then
    begin
      FClient.Proxy.Host := TACLWebSettings.Proxy.Server;
      FClient.Proxy.Port := StrToIntDef(TACLWebSettings.Proxy.ServerPort, 80);
      FClient.Proxy.UserName := TACLWebSettings.Proxy.UserName;
      FClient.Proxy.Password := TACLWebSettings.Proxy.UserPass;
    end;
    FClient.OnHeaders := DoHeaders;
    FClient.OnDataSent := DoProgress;
    FClient.OnDataReceived := DoProgress;
  end;

  destructor THttpConnectionImpl.Destroy;
  begin
    FreeAndNil(FClient);
    inherited;
  end;

  procedure THttpConnectionImpl.DoProgress(Sender : TObject; const Size, Pos: Int64);
  begin
    if Assigned(FOnProgress) and not FOnProgress(Pos, Size) then
      raise EHttpCancel.Create;
  end;

  procedure THttpConnectionImpl.DoHeaders(Sender: TObject);
  begin
    if Assigned(FOnAccept) and not FClient.IsRedirect(FClient.ResponseStatusCode) then
      FOnAccept(DoReadResponse);
  end;

  function THttpConnectionImpl.DoReadResponse: THttpResponse;

    function GetHeader(const AKey: string): string;
    begin
      Result := TFPHTTPClient.GetHeader(FClient.ResponseHeaders, AKey);
    end;

  begin
    Result.Init;
    Result.ContentLength := StrToIntDef(GetHeader(THttpHeaders.IdentContentLength), -1);
    Result.ContentRange := GetHeader(THttpHeaders.IdentContentRange);
    Result.ContentType := GetHeader(THttpHeaders.IdentContentType);
    Result.RawHeaders := FClient.ResponseHeaders.Text;
    Result.StatusCode := FClient.ResponseStatusCode;
    Result.StatusText := FClient.ResponseStatusText;
  end;

  function THttpConnectionImpl.RequestCore(const AMethod: string;
    AHeaders: TACLStringList; APostData: TStream;
    AIgnoreCertificateIssues: Boolean;
    AOnAccept: TConsumerC<THttpResponse>;
    AOnProgress: THttpProgressProc;
    AOnReceive: THttpDataProc): THttpResponse;
  var
    I: Integer;
    LStream: TStream;
    LUrl: TACLWebURL;
  begin
    FOnAccept := AOnAccept;
    FOnProgress := AOnProgress;

    FClient.Cookies.Clear;
    for I := AHeaders.Count - 1 downto 0 do
      if AHeaders.Names[I] = THttpHeaders.IdentCookie then
      begin
        FClient.Cookies.Add(AHeaders.ValueFromIndex[I]);
        AHeaders.Delete(I);
      end;

    try
      LStream := TStreamAdapter.Create(AOnReceive);
      try
        LUrl := URL;
        LUrl.CustomHeaders := '';
        FClient.RequestHeaders.Assign(AHeaders);
        FClient.RequestBody := APostData;
        FClient.VerifySSLCertificate := not AIgnoreCertificateIssues;
        FClient.HttpMethod(AMethod, LUrl.ToString, LStream, []);
      finally
        LStream.Free;
      end;
    finally
      Result := DoReadResponse;
    end;
  end;

  { THttpConnectionImpl.TStreamAdapter }

  constructor THttpConnectionImpl.TStreamAdapter.Create(AOnData: THttpDataProc);
  begin
    FOnData := AOnData;
  end;

  function THttpConnectionImpl.TStreamAdapter.Write(const Buffer; Count: Longint): Longint;
  begin
    if FOnData(@Buffer, Count) then
      Result := Count
    else
      Result := -1;
  end;
