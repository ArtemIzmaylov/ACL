{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*             Logging Routines              *}
{*                                           *}
{*           (c) Artem Izmaylov              *}
{*               2006-2022                   *}
{*              www.aimp.ru                  *}
{*                                           *}
{*********************************************}

unit ACL.Utils.Logger;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.Classes,
  System.SysUtils,
  // ACL
  ACL.Threading,
  ACL.Utils.FileSystem,
  ACL.Utils.Shell,
  ACL.Utils.Strings,
  ACL.Utils.Stream;

type
  TACLLogOption = (loWriteTimestamp, loWriteThreadId);
  TACLLogOptions = set of TACLLogOption;

  { TACLLog }

  TACLLog = class
  public const
    DefaultOptions = [loWriteTimestamp, loWriteThreadId];
  strict private
    FLock: TACLCriticalSection;
    FOptions: TACLLogOptions;
  protected
    FEncoding: TEncoding;

    procedure WriteCore(const Buffer; Count: Integer); virtual; abstract;
    procedure WriteThreadId;
    procedure WriteTimestamp;
  public
    constructor Create;
    destructor Destroy; override;
    // high-level
    procedure Add(const ATag: string; const E: Exception); overload;
    procedure Add(const ATag, AFormatLine: string; const AArgs: array of const); overload;
    procedure Add(const ATag, AText: string); overload;
    // low-level
    procedure Write(const ABuffer: TBytes); overload;
    procedure Write(const ABuffer; ACount: Integer); overload;
    procedure Write(const AText: string); overload;
    procedure WriteHeader(const S: string);
    procedure WriteLine; overload;
    procedure WriteSeparator;
    // Lock
    property Encoding: TEncoding read FEncoding;
    property Lock: TACLCriticalSection read FLock;
    property Options: TACLLogOptions read FOptions write FOptions;
  end;

  { TACLLogStream }

  TACLLogStream = class(TACLLog)
  strict private
    FStream: TStream;
    FStreamOwnership: TStreamOwnership;
  protected
    procedure WriteCore(const Buffer; Count: Integer); override;
    //
    property Stream: TStream read FStream;
  public
    constructor Create(AStream: TStream; AOwnership: TStreamOwnership = soOwned);
    destructor Destroy; override;
    function IsEmpty: Boolean;
    function ToString: string; override;
  end;

  { TACLLogFile }

  TACLLogFile = class(TACLLogStream)
  strict private
    FFileName: string;
  public
    constructor Create(const AFileName: string; AAppendIfExists: Boolean = True);
    //
    property FileName: string read FFileName;
  end;

  { TACLMemoryLog }

  TACLMemoryLog = class(TACLLogStream)
  public
    constructor Create;
    procedure SaveToFile(const AFileName: string);
  end;

// Custom log
procedure AddToLog(const AFileName: string; const ATag: string; const AException: Exception); overload;
procedure AddToLog(const AFileName: string; const ATag, AFormatLine: string; const AArguments: array of const); overload;
procedure AddToLog(const AFileName: string; const ATag, AText: string); overload;

// Debug Log
procedure AddToDebugLog(const ATag: string; const AException: Exception); overload;
procedure AddToDebugLog(const ATag, AFormatLine: string; const AArguments: array of const); overload;
procedure AddToDebugLog(const ATag, AText: string); overload;
function GetDebugLogFileName: string;
implementation

uses
  System.StrUtils;

var
  FGeneralLog: TACLCriticalSection;
  FGeneralLogFileName: string;

procedure AddToLog(const AFileName: string; const AProc: TProc<TACLLog>); overload;
var
  ALog: TACLLog;
begin
  if AFileName <> '' then
  try
    FGeneralLog.Enter;
    try
      ALog := TACLLogFile.Create(AFileName, True);
      try
        AProc(ALog);
      finally
        ALog.Free;
      end;
    finally
      FGeneralLog.Leave;
    end;
  except
    // do nothing
  end;
end;

procedure AddToLog(const AFileName: string; const ATag: string; const AException: Exception); overload;
begin
  AddToLog(AFileName,
    procedure (ALog: TACLLog)
    begin
      ALog.Add(ATag, AException);
    end);
end;

procedure AddToLog(const AFileName: string; const ATag, AText: string);
begin
  AddToLog(AFileName,
    procedure (ALog: TACLLog)
    begin
      ALog.Add(ATag, AText);
    end);
end;

procedure AddToLog(const AFileName: string; const ATag, AFormatLine: string; const AArguments: array of const);
begin
  AddToLog(AFileName, ATag, Format(AFormatLine, AArguments));
end;

procedure AddToDebugLog(const ATag: string; const AException: Exception); overload;
begin
  AddToLog(GetDebugLogFileName, ATag, AException);
end;

procedure AddToDebugLog(const ATag, AText: string); overload;
begin
  AddToLog(GetDebugLogFileName, ATag, AText);
end;

procedure AddToDebugLog(const ATag, AFormatLine: string; const AArguments: array of const); overload;
begin
  AddToLog(GetDebugLogFileName, ATag, AFormatLine, AArguments);
end;

function GetDebugLogFileName: string;
begin
  if FGeneralLogFileName = '' then
  begin
    FGeneralLog.Enter;
    try
      if FGeneralLogFileName = '' then
        FGeneralLogFileName := ShellGetMyDocuments + acExtractFileNameWithoutExt(acSelfExeName) + '.debug.log';
    finally
      FGeneralLog.Leave;
    end;
  end;
  Result := FGeneralLogFileName;
end;

{ TACLLog }

constructor TACLLog.Create;
begin
  FLock := TACLCriticalSection.Create;
  FOptions := DefaultOptions;
  FEncoding := TEncoding.UTF8;
end;

destructor TACLLog.Destroy;
begin
  FreeAndNil(FLock);
  inherited;
end;

procedure TACLLog.Add(const ATag: string; const E: Exception);
var
  AStackTrace: string;
begin
  Lock.Enter;
  try
    Add(ATag, Format('Error: %s - %s', [E.ClassName, E.ToString]));

    AStackTrace := E.StackTrace;
    if AStackTrace <> '' then
    begin
      WriteSeparator;
      Write(AStackTrace);
      WriteLine;
      WriteSeparator;
    end;
  finally
    Lock.Leave;
  end;
end;

procedure TACLLog.Add(const ATag, AText: string);
begin
  Lock.Enter;
  try
    if loWriteTimestamp in Options then
      WriteTimestamp;
    if loWriteThreadId in Options then
      WriteThreadId;
    if ATag <> '' then
    begin
      Write(ATag);
      Write(':');
      Write(#9);
    end;
    Write(AText);
    WriteLine;
  finally
    Lock.Leave;
  end;
end;

procedure TACLLog.Add(const ATag, AFormatLine: string; const AArgs: array of const);
begin
  Add(ATag, Format(AFormatLine, AArgs));
end;

procedure TACLLog.Write(const ABuffer; ACount: Integer);
begin
  Lock.Enter;
  try
    WriteCore(ABuffer, ACount);
  finally
    Lock.Leave;
  end;
end;

procedure TACLLog.Write(const ABuffer: TBytes);
var
  ACount: Integer;
begin
  ACount := Length(ABuffer);
  if ACount > 0 then
    Write(ABuffer[0], ACount);
end;

procedure TACLLog.Write(const AText: string);
begin
  Write(Encoding.GetBytes(AText));
end;

procedure TACLLog.WriteHeader(const S: string);
begin
  Lock.Enter;
  try
    WriteSeparator;
    Write(S);
    WriteLine;
    WriteSeparator;
  finally
    Lock.Leave;
  end;
end;

procedure TACLLog.WriteLine;
begin
  Write(acCRLF);
end;

procedure TACLLog.WriteSeparator;
begin
  Lock.Enter;
  try
    Write(DupeString('-', 120));
    WriteLine;
  finally
    Lock.Leave;
  end;
end;

procedure TACLLog.WriteThreadId;
begin
  Lock.Enter;
  try
    Write('[Thread: ');
    if GetCurrentThreadId = MainThreadID then
      Write('Main')
    else
      Write(Format('%4d', [GetCurrentThreadId]));

    Write(']');
    Write(#9);
  finally
    Lock.Leave;
  end;
end;

procedure TACLLog.WriteTimestamp;
begin
  Lock.Enter;
  try
    Write(FormatDateTime('[yyyy.MM.dd hh:mm:ss:zzz]', Now));
    Write(#9);
  finally
    Lock.Leave;
  end;
end;

{ TACLLogStream }

constructor TACLLogStream.Create(AStream: TStream; AOwnership: TStreamOwnership = soOwned);
begin
  inherited Create;
  FStreamOwnership := AOwnership;
  FStream := AStream;
end;

destructor TACLLogStream.Destroy;
begin
  if FStreamOwnership = soOwned then
    FreeAndNil(FStream);
  inherited Destroy;
end;

function TACLLogStream.IsEmpty: Boolean;
begin
  Result := Stream.Size = 0;
end;

function TACLLogStream.ToString: string;
begin
  Lock.Enter;
  try
    Stream.Seek(0, soBeginning);
    Result := acLoadString(Stream, Encoding);
    Stream.Seek(0, soEnd);
  finally
    Lock.Leave;
  end;
end;

procedure TACLLogStream.WriteCore(const Buffer; Count: Integer);
begin
  Stream.Write(Buffer, Count);
end;

{ TACLLogFile }

constructor TACLLogFile.Create(const AFileName: string; AAppendIfExists: Boolean);
const
  ModeMap: array[Boolean] of Word = (fmCreate, fmOpenReadWrite);
begin
  FFileName := AFileName;
  inherited Create(TACLFileStream.Create(FileName, ModeMap[AAppendIfExists and FileExists(AFileName)]));
  if AAppendIfExists then
    Stream.Position := Stream.Size;
  if IsEmpty then
    Write(Encoding.GetPreamble);
end;

{ TACLMemoryLog }

constructor TACLMemoryLog.Create;
begin
  inherited Create(TMemoryStream.Create);
end;

procedure TACLMemoryLog.SaveToFile(const AFileName: string);
begin
  TMemoryStream(Stream).SaveToFile(AFileName);
end;

initialization
  FGeneralLog := TACLCriticalSection.Create;

finalization
  FreeAndNil(FGeneralLog);
end.
