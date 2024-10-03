////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Web Utilities
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Web;

{$I ACL.Config.inc}

interface

uses
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
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

  acWebErrorUnknown     = -1;
  acWebErrorCanceled    = -2;
  acWebErrorNotAccepted = -3;

  acProtocolDelimiter = '://';
  acPortDelimiter = ':';

type

  { TACLWebErrorInfo }

  TACLWebErrorInfo = packed record
    ErrorCode: Integer;
    ErrorMessage: string;
    procedure Initialize(AErrorCode: Integer; const AErrorMessage: string);
    procedure Reset;
    function Succeeded: Boolean;
    function ToString: string;
  end;

  { EACLWebError }

  EACLWebError = class(Exception)
  protected
    FInfo: TACLWebErrorInfo;
  public
    constructor Create(const AInfo: TACLWebErrorInfo); overload;
    constructor Create(const AText: string; ACode: Integer); overload;
    //# Properties
    property Info: TACLWebErrorInfo read FInfo;
  end;

  { TACLWebProxyInfo }

  TACLWebProxyInfo = packed record
    Server: string;
    ServerPort: string;
    UserName: string;
    UserPass: string;

    class function Create(const Server, ServerPort, UserName, UserPass: string): TACLWebProxyInfo; static;
    procedure Reset;
  end;

  { TACLWebURL }

  TACLWebURL = record
    CustomHeaders: string;
    Host: string;
    Path: string;
    Port: Integer;
    PortIsDefault: Boolean;
    Protocol: string;
    Secured: Boolean;

    class function Parse(S: string; const AProtocol: string): TACLWebURL; static;
    class function ParseHttp(S: string): TACLWebURL; static;
    function ToString: string;
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
    function Add(const AName: string; const AValue: Integer): TACLWebParams; reintroduce; overload;
    function Add(const AName: string; const AValue: string): TACLWebParams; reintroduce; overload;
    function AddIfNonEmpty(const AName, AValue: string): TACLWebParams; reintroduce;
    function AddPlain(const AName: string; const AValue: string): TACLWebParams; reintroduce; overload;
    class function New: TACLWebParams;
    function ToString: string; override;
  end;

  { TACLWebSettings }

  TACLWebSettings = class
  strict private
    class var FAppVersion: string;
    class var FConnectionMode: TACLWebConnectionMode;
    class var FConnectionTimeOut: Integer;
    class var FProxyInfo: TACLWebProxyInfo;
    class var FUserAgent: string;
    class var FUserAgentCacheOfNative: string;

    class function BuildUserAgent: string;
    class function GetUserAgent: string; static;
    class procedure SetConnectionTimeOut(AValue: Integer); static;
    class procedure SetUserAgent(const AValue: string); static;
  public
    class constructor Create;
    class procedure ConfigLoad(AConfig: TACLIniFile);
    class procedure ConfigSave(AConfig: TACLIniFile);
    //# Properties
    class property AppVersion: string read FAppVersion write FAppVersion;
    class property ConnectionMode: TACLWebConnectionMode read FConnectionMode write FConnectionMode;
    class property ConnectionTimeOut: Integer read FConnectionTimeOut write SetConnectionTimeOut;
    class property Proxy: TACLWebProxyInfo read FProxyInfo write FProxyInfo;
    class property UserAgent: string read GetUserAgent write SetUserAgent;
  end;

  TACLDateTimeFormat = (RFC822, ISO8601);

function acDecodeDateTime(const Value: string; AFormat: TACLDateTimeFormat): TDateTime;

function acURLDecode(const S: string): string;
function acURLEncode(const S: string): string;
function acURLEscape(const S: string): string;
implementation

uses
  ACL.Crypto,
  ACL.Math,
  ACL.Parsers,
  ACL.Utils.Common,
  ACL.Utils.Date,
  ACL.Utils.Stream,
  ACL.Utils.Strings;

const
  PROXY_SETTINGS_ID = $00505258; // PRX
  sWebConfigSection = 'Connection';

function RFC822ToDateTime(const Value: string): TDateTime;
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
    D := acPCharToIntDef(AToken.Data, AToken.DataLength, 0);
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
    Y := acPCharToIntDef(AToken.Data, AToken.DataLength, 0);

    // Hour
    Check(AParser.GetToken(AToken));
    H := acPCharToIntDef(AToken.Data, AToken.DataLength, 0);
    Check(AParser.GetToken(AToken) and AToken.Compare(':'));
    // Minutes
    Check(AParser.GetToken(AToken));
    N := acPCharToIntDef(AToken.Data, AToken.DataLength, 0);
    Check(AParser.GetToken(AToken) and AToken.Compare(':'));
    // Seconds
    Check(AParser.GetToken(AToken));
    S := acPCharToIntDef(AToken.Data, AToken.DataLength, 0);

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
          T := T * acPCharToIntDef(AToken.Data, AToken.DataLength, 0);
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

function acDecodeDateTime(const Value: string; AFormat: TACLDateTimeFormat): TDateTime;
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

function acURLDecode(const S: string): string;
var
  LAsumeUtf8: TACLBoolean;
  LBuffer: TACLStringBuilder;
  LCode: Byte;
  LLen: Integer;
  LSrc: PChar;
begin
  LSrc := PChar(S);
  LLen := Length(S);
  LAsumeUtf8 := TACLBoolean.Default;
  LBuffer := TACLStringBuilder.Get(LLen);
  try
    while LLen > 0 do
    begin
      if (LSrc^ = '%') and (LLen > 2) and TACLHexcode.Decode((LSrc + 1)^, (LSrc + 2)^, LCode) then
      begin
        if (LCode > $7F) and (LAsumeUtf8 = TACLBoolean.Default) then
          LAsumeUtf8 := TACLBoolean.True;
        LBuffer.Append(AnsiChar(LCode));
        Dec(LLen, 3);
        Inc(LSrc, 3);
      end
      else
      begin
      {$IFDEF UNICODE}
        if Ord(LSrc^) > $FF then
          LAsumeUtf8 := TACLBoolean.False;
      {$ENDIF}
        LBuffer.Append(LSrc^);
        Dec(LLen);
        Inc(LSrc);
      end;
    end;
  {$IFDEF UNICODE}
    if LAsumeUtf8 = TACLBoolean.True then
    begin
      Result := acDecodeUtf8(acUStringToBytes(@LBuffer.Chars[0], LBuffer.Length));
      if Result <> '' then Exit;
    end;
  {$ENDIF}
    Result := LBuffer.ToString;
  finally
    LBuffer.Release;
  end;
end;

function acURLEncode(const S: string): string;
var
	A: AnsiString;
  B: TACLStringBuilder;
  C: AnsiChar;
begin
	A := acStringToUtf8(S);
	B := TACLStringBuilder.Get(Length(A) * 3);
  try
    for C in A do
    begin
      if (Ord(C) > $20) and (Ord(C) < $7F) then
        B.Append(C)
      else
        B.Append('%').Append(TACLHexcode.Encode(C));
    end;
    Result := B.ToString;
  finally
    B.Release;
  end;
end;

function acURLEscape(const S: string): string;
const
  ReservedChars = '% <>#{}|\^~'#13#10'[]`;/?:@=&$';
var
  B: TACLStringBuilder;
  C: Char;
begin
	B := TACLStringBuilder.Get(Length(S));
  try
    for C in S do
    begin
      if acContains(C, ReservedChars) then
        B.Append('%').Append(TACLHexcode.Encode(Byte(C)))
      else
        B.Append(C);
    end;
    Result := B.ToString;
  finally
    B.Release;
  end;
end;

{ TACLWebURL }

class function TACLWebURL.Parse(S: string; const AProtocol: string): TACLWebURL;
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

class function TACLWebURL.ParseHttp(S: string): TACLWebURL;
begin
  Result := Parse(S, 'http');
  if Result.Port <= 0 then
    Result.Port := IfThen(Result.Secured, 443, 80);
end;

function TACLWebURL.ToString: string;
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

function TACLWebParams.Add(const AName, AValue: string): TACLWebParams;
begin
  Result := AddPlain(AName, acURLEncode(acURLEscape(AValue)));
end;

function TACLWebParams.Add(const AName: string; const AValue: Integer): TACLWebParams;
begin
  Result := AddPlain(AName, IntToStr(AValue));
end;

function TACLWebParams.AddIfNonEmpty(const AName, AValue: string): TACLWebParams;
begin
  if AValue <> '' then
    Result := Add(AName, AValue)
  else
    Result := Self;
end;

function TACLWebParams.AddPlain(const AName, AValue: string): TACLWebParams;
begin
  if Self <> nil then
    Result := Self
  else
    Result := TACLWebParams.New;

  Result.AddPair(AName, AValue);
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
end;

class function TACLWebSettings.BuildUserAgent: string;
const
  FormatLine = 'Mozilla/5.0 (%s%s%s) AppleWebKit/537.36 (KHTML, like Gecko)';
var
  LAppDetails: string;
  LPlatform: string;
  LOSFamily: string;
begin
  if FUserAgentCacheOfNative = '' then
  begin
    LAppDetails := IfThenW(AppVersion <> '', AppVersion + '; ');
  {$IF DEFINED(MSWINDOWS)}
    LOSFamily := Format('Windows NT %d.%d', [TOSVersion.Major, TOSVersion.Minor]);
  {$ELSEIF DEFINED(LINUX)}
    LOSFamily := acTrim(TACLProcess.ExecuteToString('uname -o'));
  {$ELSE}
    LOSFamily := TOSVersion.Name;
  {$ENDIF}
  {$IF DEFINED(LINUX)}
    LPlatform := ' ' + acTrim(TACLProcess.ExecuteToString('uname -m'));
  {$ELSEIF DEFINED(MSWINDOWS) AND DEFINED(CPUX64)}
    LPlatform := '; Win64; x64';
  {$ELSE}
    LPlatform := '';
  {$ENDIF}
    FUserAgentCacheOfNative := Format(FormatLine, [LAppDetails, LOSFamily, LPlatform]);
  end;
  Result := FUserAgentCacheOfNative;
end;

class procedure TACLWebSettings.ConfigLoad(AConfig: TACLIniFile);

  function ReadString(AStream: TStream; ID: Integer): string;
  var
    U: UnicodeString;
  begin
    U := AStream.ReadStringWithLength;
    if ID = PROXY_SETTINGS_ID then
      acCryptStringXOR(U, 'ProxySettings');
    Result := acString(U);
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
        ID := AStream.ReadInt32;
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
  ConnectionMode := AConfig.ReadEnum<TACLWebConnectionMode>(sWebConfigSection, 'Mode', acWebDefaultConnectionMode);
  ConnectionTimeOut := AConfig.ReadInteger(sWebConfigSection, 'TimeOut', acWebTimeOutDefault);
end;

class procedure TACLWebSettings.ConfigSave(AConfig: TACLIniFile);

  procedure WriteString(AStream: TStream; const S: string);
  var
    U: UnicodeString;
  begin
    U := acUString(S);
    acCryptStringXOR(U, 'ProxySettings');
    AStream.WriteStringWithLength(U);
  end;

  procedure WriteProxyData;
  var
    AStream: TStream;
    ID: Integer;
  begin
    AStream := TMemoryStream.Create;
    try
      ID := PROXY_SETTINGS_ID;
      AStream.WriteInt32(ID);
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
  AConfig.WriteEnum<TACLWebConnectionMode>(
    sWebConfigSection, 'Mode', ConnectionMode, acWebDefaultConnectionMode);
  AConfig.WriteInteger(sWebConfigSection, 'TimeOut', ConnectionTimeOut, acWebTimeOutDefault);
end;

class procedure TACLWebSettings.SetConnectionTimeOut(AValue: Integer);
begin
  FConnectionTimeOut := MinMax(AValue, acWebTimeOutMin, acWebTimeOutMax);
end;

class function TACLWebSettings.GetUserAgent: string;
begin
  if FUserAgent <> '' then
    Result := FUserAgent
  else
    Result := BuildUserAgent;
end;

class procedure TACLWebSettings.SetUserAgent(const AValue: string);
begin
  if (AValue <> '') and (AValue <> BuildUserAgent) then
    FUserAgent := AValue
  else
    FUserAgent := '';
end;

{ TACLWebErrorInfo }

procedure TACLWebErrorInfo.Initialize(AErrorCode: Integer; const AErrorMessage: string);
begin
  ErrorCode := AErrorCode;
  ErrorMessage := AErrorMessage;
end;

procedure TACLWebErrorInfo.Reset;
begin
  Initialize(0, '');
end;

function TACLWebErrorInfo.Succeeded: Boolean;
begin
  Result := ErrorCode = 0;
end;

function TACLWebErrorInfo.ToString: string;
begin
  Result := Format('Error: %d %s%s', [ErrorCode, IFThenW(ErrorMessage <> '', acCRLF), ErrorMessage]);
end;

{ EACLWebError }

constructor EACLWebError.Create(const AInfo: TACLWebErrorInfo);
begin
  FInfo := AInfo;
  Create(Info.ToString);
end;

constructor EACLWebError.Create(const AText: string; ACode: Integer);
begin
  Info.Initialize(ACode, AText);
  Create(Info.ToString);
end;

{ TACLWebProxyInfo }

class function TACLWebProxyInfo.Create(const Server, ServerPort, UserName, UserPass: string): TACLWebProxyInfo;
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
