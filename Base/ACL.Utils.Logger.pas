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
  {System.}SysUtils;

type
  TLogEntryType = (Debug, Error);
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
procedure LogEntryDump(const AFileName: string;
  const ADump: string; const AHeader: string = '');

procedure LogError(const AFileName: string;
  const ATag, AExceptionClass, AExceptionMessage, AStackTrace: string;
  const APrefix: string = ''; const ALocation: string = ''); overload;
procedure LogError(const AFileName: string;
  const ATag: string; const AException: Exception;
  const APrefix: string = ''; const ALocation: string = ''); overload;
function LogErrorGetStackTrace(AError: Exception): string;

procedure LogInit(const AFileName: string; AMaxCapacity: Integer = 0);
implementation

uses
  ACL.Threading,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

{$REGION ' Core '}
var
  FLogSync: TACLCriticalSection;

procedure LogClose(AHandle: THandle);
begin
  if AHandle <> 0 then
    FileClose(AHandle);
  FLogSync.Leave;
end;

function LogOpen(out AHandle: THandle; const AFileName: string): Boolean;
begin
  Result := AFileName <> '';
  if Result then
  begin
    FLogSync.Enter;
    AHandle := acFileOpen(AFileName, fmOpenReadWriteExclusive, TACLFileStream.DefaultRights, True);
    if AHandle = THandle(INVALID_HANDLE_VALUE) then
      AHandle := 0;
    if AHandle <> 0 then
      FileSeek(AHandle, 0, soFromEnd);
  end;
end;

procedure LogWrite(AHandle: THandle; const AText: string);
var
{$IFDEF UNICODE}
  LBytes: TBytes;
{$ENDIF}
  LCount: Integer;
begin
{$IF DEFINED(FPC) AND DEFINED(LINUX)}
  System.Write(AText);
{$ENDIF}
  if AHandle = 0 then Exit;
{$IFDEF UNICODE}
  LBytes := TEncoding.UTF8.GetBytes(AText);
  LCount := Length(LBytes);
  if LCount > 0 then
    FileWrite(AHandle, LBytes[0], LCount);
{$ELSE}
  LCount := Length(AText);
  if LCount > 0 then
    FileWrite(AHandle, PAnsiChar(AText)^, LCount);
{$ENDIF}
end;

procedure LogWriteLine(AHandle: THandle; const ATag, AText: string; AType: TLogEntryType);
const
  TypeMap: array[TLogEntryType] of string = ('D/', 'E/');
begin
  LogWrite(AHandle, TACLThread.GetName(GetCurrentThreadId));
  LogWrite(AHandle, #9);
  LogWrite(AHandle, FormatDateTime('yyyy.MM.dd hh:mm:ss.zzz', Now));
  LogWrite(AHandle, #9);
  LogWrite(AHandle, TypeMap[AType]);
  LogWrite(AHandle, ATag);
  LogWrite(AHandle, ':');
  LogWrite(AHandle, #9);
  LogWrite(AHandle, AText);
  LogWrite(AHandle, sLineBreak);
end;

procedure LogWriteSeparator(AHandle: THandle);
begin
  LogWrite(AHandle, '--------------------------------------------------------------------------');
  LogWrite(AHandle, sLineBreak);
end;

{$ENDREGION}

{$REGION ' Entry points '}

procedure LogError(const AFileName: string;
  const ATag, AExceptionClass, AExceptionMessage, AStackTrace: string;
  const APrefix: string = ''; const ALocation: string = '');
var
  LLog: THandle;
  LMsg: string;
begin
  if LogOpen(LLog, AFileName) then
  try
    LMsg := Format('[%s] %s', [AExceptionClass, AExceptionMessage]);
    if APrefix <> '' then
      LMsg := APrefix + ': ' + LMsg;
    if ALocation <> '' then
      LMsg := LMsg + ' at ' + ALocation;
    LogWriteLine(LLog, ATag, LMsg, TLogEntryType.Error);
    if AStackTrace <> '' then
    begin
      LogWriteSeparator(LLog);
      LogWrite(LLog, AStackTrace);
      LogWrite(LLog, sLineBreak);
      LogWriteSeparator(LLog);
    end;
  finally
    LogClose(LLog);
  end;
end;

procedure LogError(const AFileName: string; const ATag: string;
  const AException: Exception; const APrefix, ALocation: string);
begin
  if AFileName <> '' then
  begin
    LogError(AFileName, ATag, AException.ClassName, AException.ToString,
      LogErrorGetStackTrace(AException), APrefix, ALocation);
  end;
end;

function LogErrorGetStackTrace(AError: Exception): string;
begin
  Result := '';
  if Assigned(acGetStackTraceFunc) then
    Result := acGetStackTraceFunc(AError);
{$IFNDEF FPC}
  if Result = '' then
    Result := AException.StackTrace;
{$ENDIF}
end;

procedure LogEntry(const AFileName: string;
  const ATag, AFormatLine: string; const AArguments: array of const;
  const AType: TLogEntryType = TLogEntryType.Debug); overload;
var
  LLog: THandle;
begin
  try
    if LogOpen(LLog, AFileName) then
    try
      LogWriteLine(LLog, ATag, Format(AFormatLine, AArguments), AType);
    finally
      LogClose(LLog);
    end;
  except
    // do nothing
  end;
end;

procedure LogEntry(const AFileName: string;
  const ATag, AText: string;
  const AType: TLogEntryType = TLogEntryType.Debug); overload;
var
  LLog: THandle;
begin
  if LogOpen(LLog, AFileName) then
  try
    LogWriteLine(LLog, ATag, AText, AType);
  finally
    LogClose(LLog);
  end;
end;

procedure LogEntryDump(const AFileName: string; const ADump, AHeader: string);
var
  LLog: THandle;
begin
  if LogOpen(LLog, AFileName) then
  try
    LogWriteSeparator(LLog);
    if AHeader <> '' then
    begin
      LogWrite(LLog, AHeader);
      LogWrite(LLog, sLineBreak);
    end;
    LogWrite(LLog, ADump);
    LogWrite(LLog, sLineBreak);
    LogWriteSeparator(LLog);
  finally
    LogClose(LLog);
  end;
end;

procedure LogInit(const AFileName: string; AMaxCapacity: Integer);
begin
  acGeneralLogFileName := AFileName;
  if (AMaxCapacity > 0) and (acFileSize(acGeneralLogFileName) > AMaxCapacity) then
    acDeleteFile(acGeneralLogFileName);
end;
{$ENDREGION}

initialization
  FLogSync := TACLCriticalSection.Create;

finalization
  FreeAndNil(FLogSync);
end.
