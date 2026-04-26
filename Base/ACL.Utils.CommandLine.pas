////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   High-level command line switch processor
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Utils.CommandLine;

{$I ACL.Config.inc}

interface

uses
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Math,
  {System.}SysUtils,
  // ACL
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Utils.Common,
  ACL.Utils.Logger,
  ACL.Utils.Strings;

const
  sSwitchSkipUAC = 'skipuac';

type

  { TACLCommandLineProcessor }

(*
    Supported:
      my.exe -switch "param1"
      my.exe /switch "param1"
      my.exe /switch "param1" "param2"
      my.exe /switch="param1"
      my.exe /switch="param1";"param 2"
*)

  TACLCommandLineProcessor = class
  public type
    TCommandMultipleParamsMethod = procedure (const AParams: TACLStringList) of object;
    TCommandMultipleParamsProc = reference to procedure (const AParams: TACLStringList);
    TCommandSingleParamMethod = procedure (const AParam: string) of object;
    TCommandSingleParamProc = reference to procedure (const AParam: string);
  protected type
  {$REGION ' InternalTypes '}
    TCommandHandler = record
      Flags: Cardinal;
      Proc0: TProc;
      Proc1: TCommandSingleParamProc;
      Proc2: TCommandMultipleParamsProc;

      constructor Create(
        AProc0: TProc; AProc1: TCommandSingleParamProc;
        AProc2: TCommandMultipleParamsProc; AFlags: Cardinal);
      procedure Execute(AParams: TACLStringList);
    end;

    TCommand = class(TACLStringList)
    public
      Name: string;
    end;

    TCommands = class(TACLObjectListOf<TCommand>)
    public
      function ToString: string; override;
    end;
  {$ENDREGION}
  strict private
    class var FCommands: TDictionary<string, TCommandHandler>;
    class var FLockCount: Integer;
    class var FPendingToExecute: TCommands;
  protected
    class procedure ExecuteCore;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure BeginUpdate;
    class procedure EndUpdate;
    class procedure Execute(const AParams: string);
    class procedure ExecuteFromCommandLine;

    class function HasCommands: Boolean;
    class function HasPendingCommand(const ACommand: string): Boolean; overload;
    class function HasPendingCommand(const AFlags: Cardinal): Boolean; overload;
    class procedure ParseParams(ATarget: TCommands; const AParams: string); // for internal use only

    class procedure Register(const ACommand: string;
      AProc: TCommandMultipleParamsProc; AFlags: Cardinal = 0); overload;
    class procedure Register(const ACommand: string;
      AProc: TCommandSingleParamProc; AFlags: Cardinal = 0); overload;
    class procedure Register(const ACommand: string;
      AProc: TProc; AFlags: Cardinal = 0); overload;
    class procedure Register(const ACommand: string;
      AProc: TCommandMultipleParamsMethod; AFlags: Cardinal = 0); overload;
    class procedure Register(const ACommand: string;
      AProc: TCommandSingleParamMethod; AFlags: Cardinal = 0); overload;
    class procedure Register(const ACommand: string;
      AProc: TThreadMethod; AFlags: Cardinal = 0); overload;
    class procedure Unregister(const ACommand: string);
  end;

function BuildSwitch(const AName: string; AData: TACLStringList): string;
function FindSwitch(const ACmdLine, ASwitch: string): Boolean; overload;
function FindSwitch(const ACmdLine, ASwitch: string; out AValues: string): Boolean; overload;
function GetCommandLine: string;
function GetCommandLineParams: string;
implementation

{$IFDEF MSWINDOWS}
uses
  Windows;
{$ENDIF}

function BuildSwitch(const AName: string; AData: TACLStringList): string;
var
  LDelim: string;
  LPrefix: string;
begin
  if AName = '' then
    Exit('');

  if CharInSet(AName[1], ['-', '/']) then
    LPrefix := ''
  else
    LPrefix := '/';

  if acEndsWith(Result, '=', False) then
    LDelim := ';'
  else
    LDelim := ' ';

  Result := LPrefix + AName + '"' + AData.GetDelimitedText(LDelim, False) + '"';
end;

{$IFNDEF MSWINDOWS}
function CombineParams(ASkipAppName: Boolean): string;
var
  I: Integer;
  P: string;
  S: TACLStringBuilder;
begin
  S := TACLStringBuilder.Create;
  try
    for I := Ord(ASkipAppName) to ParamCount do
    begin
      if S.Length > 0 then
        S.Append(' ');
      P := ParamStr(I);
      if acContains(' ', P) then
        S.Append('"').Append(P).Append('"')
      else
        S.Append(P);
    end;
    Result := S.ToString;
  finally
    S.Free;
  end;
end;
{$ENDIF}

function FindSwitch(const ACmdLine, ASwitch: string): Boolean;
var
  LUnused: string;
begin
  Result := FindSwitch(ACmdLine, ASwitch, LUnused);
end;

function FindSwitch(const ACmdLine, ASwitch: string; out AValues: string): Boolean;
var
  LCommands: TACLCommandLineProcessor.TCommands;
  I: Integer;
begin
  Result := False;
  LCommands := TACLCommandLineProcessor.TCommands.Create;
  try
    TACLCommandLineProcessor.ParseParams(LCommands, ACmdLine);
    for I := 0 to LCommands.Count - 1 do
      if acSameText(LCommands[I].Name, ASwitch) then
      begin
        AValues := LCommands[I].GetDelimitedText(';', False);
        Exit(True);
      end;
  finally
    LCommands.Free;
  end;
end;

function GetCommandLine: string;
begin
{$IFDEF MSWINDOWS}
  Result := Windows.GetCommandLineW;
{$ELSE}
  Result := CombineParams(False);
{$ENDIF}
end;

function GetCommandLineParams: string;
{$IFDEF MSWINDOWS}
var
  LCmdLine: PWideChar;
  LScanFor: WideChar;
begin
  LCmdLine := GetCommandLineW;
  while LCmdLine^ <= ' ' do
    Inc(LCmdLine);

  if LCmdLine^ = '"' then
    LScanFor := '"'
  else if LCmdLine^ = #39 then
    LScanFor := #39
  else
    LScanFor := ' ';

  LCmdLine := acStrScan(LCmdLine + 1, LScanFor);
  if LCmdLine <> nil then
    Result := acTrim(LCmdLine + 1)
  else
    Result := acEmptyStr;
{$ELSE}
begin
  Result := CombineParams(True);
{$ENDIF}
end;

{ TACLCommandLineProcessor }

class constructor TACLCommandLineProcessor.Create;
begin
  FCommands := TDictionary<string, TCommandHandler>.Create(TACLStringComparer.Create);
  FPendingToExecute := TCommands.Create;
end;

class destructor TACLCommandLineProcessor.Destroy;
begin
  FreeAndNil(FPendingToExecute);
  FreeAndNil(FCommands);
end;

class procedure TACLCommandLineProcessor.BeginUpdate;
begin
  Inc(FLockCount);
end;

class procedure TACLCommandLineProcessor.EndUpdate;
begin
  Dec(FLockCount);
  if FLockCount = 0 then
    ExecuteCore;
end;

class procedure TACLCommandLineProcessor.Execute(const AParams: string);
begin
  LogEntry(acGeneralLogFileName, 'CmdLine', 'Execute: "%s"', [AParams]);
  ParseParams(FPendingToExecute, AParams);
  if FLockCount = 0 then
    ExecuteCore;
end;

class procedure TACLCommandLineProcessor.ExecuteFromCommandLine;
begin
  Execute(GetCommandLineParams);
end;

class procedure TACLCommandLineProcessor.ExecuteCore;
var
  LCommand: TCommandHandler;
  LParams: TCommand;
begin
  LogEntry(acGeneralLogFileName, 'CmdLine', 'ExecuteCore(%d)', [FPendingToExecute.Count]);
  while FPendingToExecute.Count > 0 do
  begin
    LParams := FPendingToExecute.ExtractAt(0);
    try
      if FCommands.TryGetValue(LParams.Name, LCommand) then
        LCommand.Execute(LParams);
    finally
      LParams.Free;
    end;
  end;
end;

class function TACLCommandLineProcessor.HasPendingCommand(const ACommand: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FPendingToExecute.Count - 1 do
  begin
    if acSameText(FPendingToExecute.List[I].Name, ACommand) then
      Exit(True);
  end;
end;

class function TACLCommandLineProcessor.HasCommands: Boolean;
begin
  Result := FCommands.Count > 0;
end;

class function TACLCommandLineProcessor.HasPendingCommand(const AFlags: Cardinal): Boolean;
var
  ACommand: TCommandHandler;
  I: Integer;
begin
  Result := False;
  for I := 0 to FPendingToExecute.Count - 1 do
  begin
    if FCommands.TryGetValue(FPendingToExecute.List[I].Name, ACommand) and (ACommand.Flags and AFlags = AFlags) then
      Exit(True);
  end;
end;

class procedure TACLCommandLineProcessor.ParseParams(ATarget: TCommands; const AParams: string);
var
  LBuffer: TACLStringBuilder;
  LCommand: TCommand;
  LCommandParamsMode: Boolean;

  procedure Push(var AChar: PChar);
  var
    LCount: Integer;
  begin
    LCount := acCharLength(AChar);
    LBuffer.Append(AChar, LCount);
    Inc(AChar, LCount);
  end;

  procedure PutParam(AParam: string);
  begin
    AParam := acTrim(AParam);
    if AParam <> '' then
    begin
      if LCommand = nil then
      begin
        LCommand := TACLCommandLineProcessor.TCommand.Create;
        ATarget.Add(LCommand);
      end;
      LCommand.Add(AParam);
      LogEntry(acGeneralLogFileName, 'CmdLine', 'PutParam(%s, %s)', [LCommand.Name, AParam]);
    end;
  end;

  procedure PutParamFromBuffer;
  begin
    if LBuffer.Length > 0 then
      PutParam(LBuffer.ToString);
    LBuffer.Length := 0;
  end;

var
  LScan: PChar;
  LScanNext: PChar;
begin
  LogEntry(acGeneralLogFileName, 'CmdLine', 'Execute: "%s"', [AParams]);
  if AParams = '' then Exit;

  LScan := PChar(AParams);
  LCommandParamsMode := False;
  LCommand := nil;

  LBuffer := TACLStringBuilder.Get(Length(AParams));
  try
    while LScan^ <> #0 do
    begin
      case LScan^ of
        '-', '/':
          begin
            LScanNext := LScan + 1;
            while CharInSet(LScanNext^, ['0'..'9', 'a'..'z', 'A'..'Z', '-', '_']) do
              Inc(LScanNext);
            if CharInSet(LScanNext^, [' ', '=', #0]) then
            begin
              PutParamFromBuffer;
              LCommand := TCommand.Create;
              LCommand.Name := acMakeString(LScan + 1, LScanNext);
              LCommandParamsMode := LScanNext^ = '=';
              ATarget.Add(LCommand);
              LScan := LScanNext + Ord(LCommandParamsMode);
            end
            else
              Push(LScan);
          end;

        '"':
          begin
            PutParamFromBuffer;
            Inc(LScan);
            LScanNext := LScan;
            while (LScanNext^ <> #0) and (LScanNext^ <> '"') do
              Inc(LScanNext);
            PutParam(acMakeString(LScan, LScanNext));
            LScan := LScanNext;
            if LScan^ <> #0 then
              Inc(LScan); // skip trailing-'"'
          end;

        ';':
          if LCommandParamsMode then
          begin
            PutParamFromBuffer;
            Inc(LScan);
          end
          else
            Push(LScan);

        #13, #10, #9:
          begin
            PutParamFromBuffer;
            Inc(LScan);
          end;

        ' ':
          begin
            PutParamFromBuffer;
            if LCommandParamsMode then
            begin
              LCommandParamsMode := False;
              LCommand := nil;
            end;
            Inc(LScan);
          end;

      else
        repeat
          Push(LScan);
        until CharInSet(LScan^, [' ', '"', ';', #13, #10, #0]);
      end;
    end;
    PutParamFromBuffer;
  finally
    LBuffer.Release;
  end;
end;

class procedure TACLCommandLineProcessor.Register(
  const ACommand: string; AProc: TCommandSingleParamProc; AFlags: Cardinal);
begin
  FCommands.AddOrSetValue(ACommand, TCommandHandler.Create(nil, AProc, nil, AFlags));
end;

class procedure TACLCommandLineProcessor.Register(
  const ACommand: string; AProc: TCommandMultipleParamsProc; AFlags: Cardinal);
begin
  FCommands.AddOrSetValue(ACommand, TCommandHandler.Create(nil, nil, AProc, AFlags));
end;

class procedure TACLCommandLineProcessor.Register(
  const ACommand: string; AProc: TProc; AFlags: Cardinal);
begin
  FCommands.AddOrSetValue(ACommand, TCommandHandler.Create(AProc, nil, nil, AFlags));
end;

class procedure TACLCommandLineProcessor.Register(
  const ACommand: string; AProc: TCommandMultipleParamsMethod; AFlags: Cardinal);
begin
  Register(ACommand,
    procedure (const AParams: TACLStringList)
    begin
      AProc(AParams)
    end, AFlags);
end;

class procedure TACLCommandLineProcessor.Register(
  const ACommand: string; AProc: TCommandSingleParamMethod; AFlags: Cardinal);
begin
  Register(ACommand,
    procedure (const AParam: string)
    begin
      AProc(AParam)
    end, AFlags);
end;

class procedure TACLCommandLineProcessor.Register(
  const ACommand: string; AProc: TThreadMethod; AFlags: Cardinal);
begin
  Register(ACommand, procedure begin AProc(); end, AFlags);
end;

class procedure TACLCommandLineProcessor.Unregister(const ACommand: string);
var
  I: Integer;
begin
  for I := FPendingToExecute.Count - 1 downto 0 do
  begin
    if acSameText(FPendingToExecute.List[I].Name, ACommand) then
      FPendingToExecute.Delete(I);
  end;
  FCommands.Remove(ACommand);
end;

{ TACLCommandLineProcessor.TCommand }

constructor TACLCommandLineProcessor.TCommandHandler.Create(AProc0: TProc;
  AProc1: TCommandSingleParamProc; AProc2: TCommandMultipleParamsProc; AFlags: Cardinal);
begin
  Flags := AFlags;
  Proc0 := AProc0;
  Proc1 := AProc1;
  Proc2 := AProc2;
end;

procedure TACLCommandLineProcessor.TCommandHandler.Execute(AParams: TACLStringList);
begin
  if Assigned(Proc0) then
    Proc0()
  else

  if Assigned(Proc2) then
    Proc2(AParams)
  else

  if Assigned(Proc1) then
  begin
    if AParams.Count > 0 then
      Proc1(AParams.First)
    else
      Proc1('');
  end;
end;

function TACLCommandLineProcessor.TCommands.ToString: string;
var
  R: TACLStringBuilder;
  I, J: Integer;
begin
  R := TACLStringBuilder.Create;
  try
    for I := 0 to Count - 1 do
    begin
      if R.Length > 0 then
        R.Append(' ');
      R.Append(Items[I].Name);
      if Items[I].Count > 0 then
        R.Append('=');
      for J := 0 to Items[I].Count - 1 do
      begin
        R.Append('<');
        R.Append(Items[I][J]);
        R.Append('>');
      end;
    end;
    Result := R.ToString;
  finally
    R.Free;
  end;
end;

end.
