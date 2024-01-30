{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*               Web Services                *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.WEB;

{$I ACL.Config.INC}

interface

uses
  Winapi.Windows,
  // System
  System.Classes,
  System.SysUtils,
  System.Types,
  System.Math,
  // ACL
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.FileFormats.XML;

type
  TACLWebConnectionMode = (ncmDirect, ncmSystemDefaults, ncmUserDefined);

const
  acWebDefaultConnectionMode = ncmSystemDefaults;
  acWebTimeOutDefault = 5000;
  acWebTimeOutMax = 30000;
  acWebTimeOutMin = 1000;
  acWebUserAgent = 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.0)';

  acWebErrorUnknown     = -1;
  acWebErrorCanceled    = -2;
  acWebErrorNotAccepted = -3;

  acProtocolDelimiter = '://';
  acPortDelimiter = ':';

type

  { TACLWebErrorInfo }

  TACLWebErrorInfo = packed record
    ErrorCode: Integer;
    ErrorMessage: UnicodeString;

    procedure Initialize(AErrorCode: Integer; const AErrorMessage: UnicodeString);
    procedure Reset;
    function ToString: UnicodeString;
  end;

  { EACLWebError }

  EACLWebError = class(Exception)
  strict private
    FInfo: TACLWebErrorInfo;
  public
    constructor Create(const AInfo: TACLWebErrorInfo); overload;
    //
    property Info: TACLWebErrorInfo read FInfo;
  end;

  { TACLWebProxyInfo }

  TACLWebProxyInfo = packed record
    Server: UnicodeString;
    ServerPort: UnicodeString;
    UserName: UnicodeString;
    UserPass: UnicodeString;

    class function Create(const Server, ServerPort, UserName, UserPass: UnicodeString): TACLWebProxyInfo; static;
    procedure Reset;
  end;

  { TACLWebURL }

  TACLWebURL = record
    CustomHeaders: UnicodeString;
    Host: UnicodeString;
    Path: UnicodeString;
    Port: Integer;
    PortIsDefault: Boolean;
    Protocol: UnicodeString;
    Secured: Boolean;

    class function Parse(S: UnicodeString; const AProtocol: UnicodeString): TACLWebURL; static;
    class function ParseHttp(S: UnicodeString): TACLWebURL; static;
    function ToString: UnicodeString;
  end;

  { IACLWebRequestRange }

  IACLWebRequestRange = interface
  ['{34C20AC7-68CF-4EFB-8D4F-96D392F74498}']
    function GetOffset: Int64;
    function GetSize: Int64;
  end;

  { TACLWebRequestRange }

  TACLWebRequestRange = class(TInterfacedObject, IACLWebRequestRange)
  strict private
    FOffset, FSize: Int64;
  public
    constructor Create(const AOffset: Int64 = -1; const ASize: Int64 = -1);
    // IACLWebRequestRange
    function GetOffset: Int64;
    function GetSize: Int64;
  end;

  { TACLWebParams }

  TACLWebParams = class(TACLStringList)
  public
    function Add(const AName, AValue: string): TACLWebParams; reintroduce; overload;
    function Add(const AName: string; const AValue: Integer): TACLWebParams; reintroduce; overload;
    function Add(const AName: string; const AValue: TBytes): TACLWebParams; reintroduce; overload;
    function AddIfNonEmpty(const AName, AValue: string): TACLWebParams; reintroduce;
    class function New: TACLWebParams;
    function ToString: string; override;
  end;

  { TACLWebSettings }

  TACLWebSettings = class
  strict private
    class var FConnectionMode: TACLWebConnectionMode;
    class var FConnectionTimeOut: Integer;
    class var FProxyInfo: TACLWebProxyInfo;
    class var FUserAgent: UnicodeString;

    class procedure SetConnectionTimeOut(AValue: Integer); static;
  public
    class constructor Create;
    class procedure ConfigLoad(AConfig: TACLIniFile);
    class procedure ConfigSave(AConfig: TACLIniFile);
    //
    class property ConnectionMode: TACLWebConnectionMode read FConnectionMode write FConnectionMode;
    class property ConnectionTimeOut: Integer read FConnectionTimeOut write SetConnectionTimeOut;
    class property Proxy: TACLWebProxyInfo read FProxyInfo write FProxyInfo;
    class property UserAgent: UnicodeString read FUserAgent write FUserAgent;
  end;

  TACLDateTimeFormat = (RFC822, ISO8601);

function acDecodeDateTime(const Value: UnicodeString; AFormat: TACLDateTimeFormat): TDateTime;

function acURLDecode(const S: UnicodeString): UnicodeString;
function acURLEncode(const B: TArray<Byte>): UnicodeString;
function acURLEscape(const S: UnicodeString): UnicodeString;
implementation

uses
  Winapi.WinInet,
  // ACL
  ACL.Crypto,
  ACL.Math,
  ACL.Parsers,
  ACL.Utils.Common,
  ACL.Utils.Date,
  ACL.Utils.Registry,
  ACL.Utils.Stream,
  ACL.Utils.Strings;

const
  PROXY_SETTINGS_ID = $00505258; // PRX

  sWebConfigSection = 'Connection';

function acURLEscape(const S: UnicodeString): UnicodeString;
const
  ReservedChars: array[0..23] of WideChar = (
    '%', ' ', '<', '>', '#', '{', '}', '|', '\', '^', '~', #13,
    '[', ']', '`', ';', '/', '?', ':', '@', '=', '&', '$', #10
  );
var
  I: Integer;
begin
  Result := S;
  for I := 0 to Length(ReservedChars) - 1 do
    Result := StringReplace(Result, ReservedChars[I], '%' + IntToHex(Byte(ReservedChars[I]), 2), [rfReplaceAll]);
end;

function RFC822ToDateTime(const Value: UnicodeString): TDateTime;
//Thu, 14 Jan 2016 15:58:12 +0300

  procedure Check(R: Boolean);
  begin
    if not R then
      Abort;
  end;

var
  AHasTimeZoneOffset: Boolean;
  AParser: TACLParser;
  AToken: TACLParserToken;
  D, M, Y, H, N, S: Word;
  T: Integer;
begin
  AParser := TACLParser.Create;
  try
    AParser.SkipSpaces := True;
    AParser.SkipDelimiters := False;
    AParser.Initialize(Value);

    // skip the day of week
    Check(AParser.GetToken(AToken) and AParser.GetToken(AToken) and AToken.Compare(','));

    // Day
    Check(AParser.GetToken(AToken));
    D := acPWideCharToIntDef(AToken.Data, AToken.DataLength, 0);
    // Month
    Check(AParser.GetToken(AToken));
    for M := 1 to 12 do
    begin
      if AToken.Compare(InvariantFormatSettings.ShortMonthNames[M]) or
         AToken.Compare(InvariantFormatSettings.LongMonthNames[M])
      then
        Break;
    end;
    // Year
    Check(AParser.GetToken(AToken));
    Y := acPWideCharToIntDef(AToken.Data, AToken.DataLength, 0);

    // Hour
    Check(AParser.GetToken(AToken));
    H := acPWideCharToIntDef(AToken.Data, AToken.DataLength, 0);
    Check(AParser.GetToken(AToken) and AToken.Compare(':'));
    // Minutes
    Check(AParser.GetToken(AToken));
    N := acPWideCharToIntDef(AToken.Data, AToken.DataLength, 0);
    Check(AParser.GetToken(AToken) and AToken.Compare(':'));
    // Seconds
    Check(AParser.GetToken(AToken));
    S := acPWideCharToIntDef(AToken.Data, AToken.DataLength, 0);

    // TimeZone
    T := 0;
    AHasTimeZoneOffset := AParser.GetToken(AToken);
    if AHasTimeZoneOffset then
    begin
      if AToken.Compare('PDT') or AToken.Compare('PST') then
        T := -700
      else
        if CharInSet(AToken.Data^, ['+', '-']) then
        begin
          T := Signs[AToken.Compare('+')];
          Check(AParser.GetToken(AToken));
          T := T * acPWideCharToIntDef(AToken.Data, AToken.DataLength, 0);
        end;
    end;
  finally
    AParser.Free;
  end;

  Result := EncodeDate(Y, M, D) + EncodeTime(H, N, S, 0);
  if AHasTimeZoneOffset then
  begin
    Result := Result - Sign(T) * EncodeTime(Abs(T) div 100, (Abs(T) mod 100) div MinsPerHour, 0, 0);
    Result := UTCToLocalDateTime(Result);
  end;
end;

function acDecodeDateTime(const Value: UnicodeString; AFormat: TACLDateTimeFormat): TDateTime;
begin
  Result := 0;
  if Value <> '' then
  try
    if AFormat = RFC822 then
      Result := RFC822ToDateTime(Value)
    else
      Result := TACLXMLDateTime.Create(Value).ToDateTime;
  except
    Result := 0;
  end;
end;

function acURLEncode(const B: TArray<Byte>): UnicodeString;
var
  S: TACLStringBuilder;
begin
  S := TACLStringBuilder.Get(Length(B) * 3);
  try
    for var I := Low(B) to High(B) do
      S.Append('%').Append(IntToHex(B[I], 2));
    Result := S.ToString;
  finally
    S.Release;
  end;
end;

function acURLDecode(const S: UnicodeString): UnicodeString;
var
  ACharCode: Byte;
  ADest: PWideChar;
  ADestCount: Integer;
  ALength: Integer;
  ASrc: PWideChar;
begin
  ALength := Length(S);

  SetLength(Result, ALength);
  ASrc := PWideChar(S);
  ADest := PWideChar(Result);
  ADestCount := 0;

  while ALength > 0 do
  begin
    if (ASrc^ = '%') and (ALength > 2) and TACLHexcode.Decode((ASrc + 1)^, (ASrc + 2)^, ACharCode) then
    begin
      Inc(ASrc, 2);
      Dec(ALength, 2);
      if ACharCode >= $7F then
        Word(ADest^) := Word(acStringFromAnsiString(AnsiChar(ACharCode)))
      else
        Word(ADest^) := Word(ACharCode);
    end
    else
      Word(ADest^) := Word(ASrc^);

    Dec(ALength);
    Inc(ADestCount);
    Inc(ADest);
    Inc(ASrc);
  end;
  if ADestCount <> ALength then
    SetLength(Result, ADestCount);
end;

{ TACLWebURL }

class function TACLWebURL.Parse(S: UnicodeString; const AProtocol: UnicodeString): TACLWebURL;
var
  ADelimPos: Integer;
begin
  ADelimPos := acPos(acCRLF, S);
  if ADelimPos > 0 then
  begin
    Result.CustomHeaders := Copy(S, ADelimPos + Length(acCRLF), MaxInt);
    S := Copy(S, 1, ADelimPos - 1);
  end
  else
    Result.CustomHeaders := '';

  // Protocol
  ADelimPos := acPos(acProtocolDelimiter, S);
  if ADelimPos > 0 then
  begin
    Result.Protocol := Copy(S, 1, ADelimPos - 1);
    Result.Secured := SameText(Result.Protocol, AProtocol + 's');
    Delete(S, 1, ADelimPos + 2);
  end
  else
  begin
    Result.Protocol := AProtocol;
    Result.Secured := False;
  end;

  // Host & Path
  ADelimPos := acPos('/', S);
  if ADelimPos > 0 then
  begin
    Result.Host := Copy(S, 1, ADelimPos - 1);
    Result.Path := Copy(S, ADelimPos, MaxInt);
  end
  else
  begin
    Result.Host := S;
    Result.Path := '';
  end;

  // Port
  ADelimPos := acPos(acPortDelimiter, S);
  if (ADelimPos > 0) and (ADelimPos < acPos('/', S)) then
  begin
    Result.Port := StrToIntDef(Copy(Result.Host, ADelimPos + 1, MaxInt), -1);
    Result.PortIsDefault := False;
    Delete(Result.Host, ADelimPos, MaxInt);
  end
  else
  begin
    Result.Port := -1;
    Result.PortIsDefault := True;
  end;
end;

class function TACLWebURL.ParseHttp(S: UnicodeString): TACLWebURL;
begin
  Result := Parse(S, 'http');
  if Result.Port <= 0 then
    Result.Port := IfThen(Result.Secured, INTERNET_DEFAULT_HTTPS_PORT, INTERNET_DEFAULT_HTTP_PORT);
end;

function TACLWebURL.ToString: UnicodeString;
var
  B: TACLStringBuilder;
begin
  if Host = '' then
    Exit('');

  B := TACLStringBuilder.Get;
  try
    if Protocol <> '' then
      B.Append(Protocol).Append(acProtocolDelimiter);
    B.Append(Host);
    if not PortIsDefault then
      B.Append(acPortDelimiter).Append(Port);
    if Path <> '' then
      B.Append(Path);
    if CustomHeaders <> '' then
      B.AppendLine.Append(CustomHeaders);
    Result := B.ToString;
  finally
    B.Release;
  end;
end;

{ TACLWebRequestRange }

constructor TACLWebRequestRange.Create(const AOffset, ASize: Int64);
begin
  FOffset := AOffset;
  FSize := ASize;
end;

function TACLWebRequestRange.GetOffset: Int64;
begin
  Result := FOffset;
end;

function TACLWebRequestRange.GetSize: Int64;
begin
  Result := FSize;
end;

{ TACLWebParams }

function TACLWebParams.Add(const AName: string; const AValue: TBytes): TACLWebParams;
begin
  if Self <> nil then
    Result := Self
  else
    Result := TACLWebParams.New;

  Result.AddEx(AName + '=' + acURLEncode(AValue));
end;

function TACLWebParams.Add(const AName, AValue: string): TACLWebParams;
begin
  if Self <> nil then
    Result := Self
  else
    Result := TACLWebParams.New;

  Result.AddEx(AName + '=' + acURLEscape(AValue));
end;

function TACLWebParams.Add(const AName: string; const AValue: Integer): TACLWebParams;
begin
  Result := Add(AName, IntToStr(AValue));
end;

function TACLWebParams.AddIfNonEmpty(const AName, AValue: string): TACLWebParams;
begin
  if AValue <> '' then
    Result := Add(AName, AValue)
  else
    Result := Self;
end;

class function TACLWebParams.New: TACLWebParams;
begin
  Result := TACLWebParams.Create;
end;

function TACLWebParams.ToString: string;
begin
  Result := GetDelimitedText('&', False);
end;

{ TACLWebSettings }

class constructor TACLWebSettings.Create;
begin
  ConnectionMode := acWebDefaultConnectionMode;
  ConnectionTimeOut := acWebTimeOutDefault;
  UserAgent := acWebUserAgent;
end;

class procedure TACLWebSettings.ConfigLoad(AConfig: TACLIniFile);

  function ReadString(AStream: TStream; ID: Integer): UnicodeString;
  begin
    Result := AStream.ReadStringWithLength;
    if ID = PROXY_SETTINGS_ID then
      acCryptStringXOR(Result, 'ProxySettings');
  end;

  procedure ReadProxyData;
  var
    AStream: TStream;
    ID: Integer;
  begin
    AStream := TMemoryStream.Create;
    try
      if AConfig.ReadStream(sWebConfigSection, 'Proxy', AStream) then
      begin
        AStream.Read(ID, SizeOf(ID));
        if ID <> PROXY_SETTINGS_ID then
          AStream.Position := 0;
        FProxyInfo.Server := ReadString(AStream, ID);
        FProxyInfo.ServerPort := ReadString(AStream, ID);
        FProxyInfo.UserName := ReadString(AStream, ID);
        FProxyInfo.UserPass := ReadString(AStream, ID);
      end;
    finally
      AStream.Free;
    end;
  end;

begin
  ReadProxyData;
  ConnectionMode := AConfig.ReadEnum(sWebConfigSection, 'Mode', acWebDefaultConnectionMode);
  ConnectionTimeOut := AConfig.ReadInteger(sWebConfigSection, 'TimeOut', acWebTimeOutDefault);
end;

class procedure TACLWebSettings.ConfigSave(AConfig: TACLIniFile);

  procedure WriteString(AStream: TStream; S: UnicodeString);
  begin
    acCryptStringXOR(S, 'ProxySettings');
    AStream.WriteStringWithLength(S);
  end;

  procedure WriteProxyData;
  var
    AStream: TStream;
    ID: Integer;
  begin
    AStream := TMemoryStream.Create;
    try
      ID := PROXY_SETTINGS_ID;
      AStream.WriteBuffer(ID, SizeOf(ID));
      WriteString(AStream, FProxyInfo.Server);
      WriteString(AStream, FProxyInfo.ServerPort);
      WriteString(AStream, FProxyInfo.UserName);
      WriteString(AStream, FProxyInfo.UserPass);
      AStream.Position := 0;
      AConfig.WriteStream(sWebConfigSection, 'Proxy', AStream);
    finally
      AStream.Free;
    end;
  end;

begin
  WriteProxyData;
  AConfig.WriteEnum(sWebConfigSection, 'Mode', ConnectionMode, acWebDefaultConnectionMode);
  AConfig.WriteInteger(sWebConfigSection, 'TimeOut', ConnectionTimeOut, acWebTimeOutDefault);
end;

class procedure TACLWebSettings.SetConnectionTimeOut(AValue: Integer);
begin
  FConnectionTimeOut := MinMax(AValue, acWebTimeOutMin, acWebTimeOutMax);
end;

{ TACLWebErrorInfo }

procedure TACLWebErrorInfo.Initialize(AErrorCode: Integer; const AErrorMessage: UnicodeString);
begin
  ErrorCode := AErrorCode;
  ErrorMessage := AErrorMessage;
end;

procedure TACLWebErrorInfo.Reset;
begin
  Initialize(0, '');
end;

function TACLWebErrorInfo.ToString: UnicodeString;
begin
  Result := Format('Error: %d %s%s', [ErrorCode, IFThenW(ErrorMessage <> '', acCRLF), ErrorMessage]);
end;

{ EACLWebError }

constructor EACLWebError.Create(const AInfo: TACLWebErrorInfo);
begin
  FInfo := AInfo;
  Create(AInfo.ToString);
end;

{ TACLWebProxyInfo }

class function TACLWebProxyInfo.Create(const Server, ServerPort, UserName, UserPass: UnicodeString): TACLWebProxyInfo;
begin
  Result.Server := Server;
  Result.ServerPort := ServerPort;
  Result.UserName := UserName;
  Result.UserPass := UserPass;
end;

procedure TACLWebProxyInfo.Reset;
begin
  Server := EmptyStr;
  ServerPort := EmptyStr;
  UserName := EmptyStr;
  UserPass := EmptyStr;
end;

end.
