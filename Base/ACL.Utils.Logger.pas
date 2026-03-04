////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Debug Logger
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Utils.Logger;

{$I ACL.Config.inc}

{$SCOPEDENUMS ON}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
  {System.}Classes,
  {System.}SysUtils,
  // ACL
  ACL.Threading,
  ACL.Utils.Common;

type
  TLogEntryType = (Debug, Error);

  { TACLLogFile }

  TACLLogFile = class
  strict private
    FHandle: THandle;
    FLock: TACLCriticalSection;
  public
    procedure Write(const AText: string);
    procedure WriteHeader(const S: string);
    procedure WriteLine; overload;
    procedure WriteLine(const ATag, AText: string; AType: TLogEntryType); overload;
    procedure WriteSeparator;
    procedure WriteThreadId;
    procedure WriteTimestamp;
  public
    constructor Create(const AFileName: string; ALock: TACLCriticalSection = nil);
    destructor Destroy; override;
    class function Open(const AFileName: string;
      out AInstance: TACLLogFile; ALock: TACLCriticalSection = nil): Boolean;
  end;

type
  TGetStackTraceFunc = function (AException: Exception): string of object;

var
  acGeneralLogFileName: string = '';
  acGetStackTraceFunc: TGetStackTraceFunc = nil;

procedure LogEntry(const AFileName: string;
  const ATag, AFormatLine: string; const AArguments: array of const;
  const AType: TLogEntryType = TLogEntryType.Debug); overload;
procedure LogEntry(const AFileName: string;
  const ATag, AText: string;
  const AType: TLogEntryType = TLogEntryType.Debug); overload;

procedure LogError(const AFileName: string;
  const ATag, AExceptionClass, AExceptionMessage, AStackTrace: string;
  const APrefix: string = ''; const ALocation: string = ''); overload;
procedure LogError(const AFileName: string;
  const ATag: string; const AException: Exception;
  const APrefix: string = ''; const ALocation: string = ''); overload;

procedure LogEntryDump(const AFileName: string; const ADump: string; const AHeader: string = '');
procedure LogInit(const AFileName: string; AMaxCapacity: Integer = 0);
implementation

uses
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

var
  FLogSync: TACLCriticalSection;

procedure LogError(const AFileName: string;
  const ATag, AExceptionClass, AExceptionMessage, AStackTrace: string;
  const APrefix: string = ''; const ALocation: string = '');
var
  LLog: TACLLogFile;
  LMsg: string;
begin
  if TACLLogFile.Open(AFileName, LLog, FLogSync) then
  try
    LMsg := Format('[%s] %s', [AExceptionClass, AExceptionMessage]);
    if APrefix <> '' then
      LMsg := APrefix + ': ' + LMsg;
    if ALocation <> '' then
      LMsg := LMsg + ' at ' + ALocation;
    LLog.WriteLine(ATag, LMsg, TLogEntryType.Error);
    if AStackTrace <> '' then
    begin
      LLog.WriteSeparator;
      LLog.Write(AStackTrace);
      LLog.WriteLine;
      LLog.WriteSeparator;
    end;
  finally
    LLog.Free;
  end;
end;

procedure LogError(const AFileName: string; const ATag: string;
  const AException: Exception; const APrefix, ALocation: string);
var
  LStackTrace: string;
begin
  if AFileName <> '' then
  begin
    LStackTrace := '';
    if Assigned(acGetStackTraceFunc) then
      LStackTrace := acGetStackTraceFunc(AException);
  {$IFNDEF FPC}
    if LStackTrace = '' then
      LStackTrace := AException.StackTrace;
  {$ENDIF}
    LogError(AFileName, ATag, AException.ClassName,
      AException.ToString, LStackTrace, APrefix, ALocation);
  end;
end;

procedure LogEntry(const AFileName: string;
  const ATag, AFormatLine: string; const AArguments: array of const;
  const AType: TLogEntryType = TLogEntryType.Debug); overload;
var
  LLog: TACLLogFile;
begin
  try
    if TACLLogFile.Open(AFileName, LLog, FLogSync) then
    try
      LLog.WriteLine(ATag, Format(AFormatLine, AArguments), AType);
    finally
      LLog.Free;
    end;
  except
    // do nothing
  end;
end;

procedure LogEntry(const AFileName: string;
  const ATag, AText: string;
  const AType: TLogEntryType = TLogEntryType.Debug); overload;
var
  LLog: TACLLogFile;
begin
  if TACLLogFile.Open(AFileName, LLog, FLogSync) then
  try
    LLog.WriteLine(ATag, AText, AType);
  finally
    LLog.Free;
  end;
end;

procedure LogEntryDump(const AFileName: string; const ADump, AHeader: string);
var
  LLog: TACLLogFile;
begin
  if TACLLogFile.Open(AFileName, LLog, FLogSync) then
  try
    LLog.WriteSeparator;
    if AHeader <> '' then
    begin
      LLog.Write(AHeader);
      LLog.WriteLine;
    end;
    LLog.Write(ADump);
    LLog.WriteLine;
    LLog.WriteSeparator;
  finally
    LLog.Free;
  end;
end;

procedure LogInit(const AFileName: string; AMaxCapacity: Integer);
begin
  acGeneralLogFileName := AFileName;
  if (AMaxCapacity > 0) and (acFileSize(acGeneralLogFileName) > AMaxCapacity) then
    acDeleteFile(acGeneralLogFileName);
end;

{ TACLLogFile }

constructor TACLLogFile.Create(const AFileName: string; ALock: TACLCriticalSection = nil);
begin
  FLock := ALock;
  if FLock <> nil then
    FLock.Enter;
  FHandle := acFileOpen(AFileName, fmOpenReadWriteExclusive, TACLFileStream.DefaultRights, True);
  if FHandle = THandle(INVALID_HANDLE_VALUE) then
    FHandle := 0;
  if FHandle <> 0 then
    FileSeek(FHandle, 0, soFromEnd);
end;

destructor TACLLogFile.Destroy;
begin
  if FHandle <> 0 then
    FileClose(FHandle);
  if FLock <> nil then
    FLock.Leave;
  inherited;
end;

class function TACLLogFile.Open(const AFileName: string;
  out AInstance: TACLLogFile; ALock: TACLCriticalSection): Boolean;
begin
  Result := AFileName <> '';
  if Result then
    AInstance := TACLLogFile.Create(AFileName, ALock);
end;

procedure TACLLogFile.Write(const AText: string);
var
{$IFDEF UNICODE}
  LBytes: TBytes;
{$ENDIF}
  LCount: Integer;
begin
{$IF DEFINED(FPC) AND DEFINED(LINUX)}
  System.Write(AText);
{$ENDIF}
  if FHandle = 0 then Exit;
{$IFDEF UNICODE}
  LBytes := TEncoding.UTF8.GetBytes(AText);
  LCount := Length(LBytes);
  if LCount > 0 then
    FileWrite(FHandle, LBytes[0], LCount);
{$ELSE}
  LCount := Length(AText);
  if LCount > 0 then
    FileWrite(FHandle, PAnsiChar(AText)^, LCount);
{$ENDIF}
end;

procedure TACLLogFile.WriteHeader(const S: string);
begin
  WriteSeparator;
  Write(S);
  WriteLine;
  WriteSeparator;
end;

procedure TACLLogFile.WriteLine(const ATag, AText: string; AType: TLogEntryType);
const
  TypeMap: array[TLogEntryType] of string = ('D/', 'E/');
begin
  WriteThreadId;
  WriteTimestamp;
  Write(TypeMap[AType]);
  Write(ATag);
  Write(':');
  Write(#9);
  Write(AText);
  WriteLine;
end;

procedure TACLLogFile.WriteLine;
begin
  Write(sLineBreak);
end;

procedure TACLLogFile.WriteSeparator;
begin
  Write('--------------------------------------------------------------------------');
  WriteLine;
end;

procedure TACLLogFile.WriteThreadId;
begin
  if GetCurrentThreadId = MainThreadID then
    Write('Main')
  else
    Write('thread-' + Format('%4d', [GetCurrentThreadId]));

  Write(#9);
end;

procedure TACLLogFile.WriteTimestamp;
begin
  Write(FormatDateTime('yyyy.MM.dd hh:mm:ss.zzz', Now));
  Write(#9);
end;

initialization
  FLogSync := TACLCriticalSection.Create;

finalization
  FreeAndNil(FLogSync);
end.
