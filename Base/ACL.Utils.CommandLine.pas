////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   High-level command line switch processor
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Utils.CommandLine;

{$I ACL.Config.inc}

interface

uses
  {System.}Generics.Collections,
  {System.}Math,
  {System.}SysUtils,
  // ACL
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Parsers,
  ACL.Utils.Common,
{$IFDEF ACL_LOG_CMDLINE}
  ACL.Utils.Logger,
{$ENDIF}
  ACL.Utils.Strings;

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
    TCommandMultipleParamsProc = reference to procedure (const AParams: TACLStringList);
    TCommandSingleParamProc = reference to procedure (const AParam: string);
  protected type
  {$REGION 'InternalTypes'}
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

    TCommands = class(TACLObjectList<TCommand>)
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
    class procedure Parse(ATarget: TCommands; const AParams: string);
    class function ParseParams(const AParams: string): TCommands;
  public
    class constructor Create;
    class destructor Destroy;

    class procedure Execute(const AParams: string);
    class procedure ExecuteFromCommandLine;

    class function HasPendingCommand(const ACommand: string): Boolean; overload;
    class function HasPendingCommand(const AFlags: Cardinal): Boolean; overload;

    class procedure BeginUpdate;
    class procedure EndUpdate;

    class procedure Register(const ACommand: string; AProc: TCommandMultipleParamsProc; AFlags: Cardinal = 0); overload;
    class procedure Register(const ACommand: string; AProc: TCommandSingleParamProc; AFlags: Cardinal = 0); overload;
    class procedure Register(const ACommand: string; AProc: TProc; AFlags: Cardinal = 0); overload;
    class procedure Unregister(const ACommand: string);
  end;

  { TACLCommandLineParser }

  TACLCommandLineParser = class(TACLParser)
  strict private type
    TState = (sNone, sWaitingForCommand, sWaitingForCommandName, sWaitingForParamSeparator, sSeparatedParams);
    TTokenHandler = procedure (const AToken: TACLParserToken) of object;
  protected
    FCommand: TACLCommandLineProcessor.TCommand;
    FHandlers: array[TState] of TTokenHandler;
    FParamBuffer: TACLStringBuilder;
    FPrevToken: TACLParserToken;
    FState: TState;
    FTarget: TACLCommandLineProcessor.TCommands;

    procedure HandlerNone(const AToken: TACLParserToken);
    procedure HandlerSeparatedParams(const AToken: TACLParserToken);
    procedure HandlerWaitingForCommand(const AToken: TACLParserToken);
    procedure HandlerWaitingForCommandName(const AToken: TACLParserToken);
    procedure HandlerWaitingForParamSeparator(const AToken: TACLParserToken);
    //
    procedure PutParam(AParam: string); overload;
    procedure PutParam(AParamBuffer: TACLStringBuilder); overload;
  public
    constructor Create; reintroduce;
    procedure Parse(ATarget: TACLCommandLineProcessor.TCommands);
  end;

function FindSwitch(const ACmdLine, ASwitch: string): Boolean; overload;
function FindSwitch(const ACmdLine, ASwitch: string; out ASwitchParam: string): Boolean; overload;
function GetCommandLine: string;
function GetCommandLineParams: string;
implementation

{$IFDEF MSWINDOWS}
uses
  Windows;
{$ENDIF}

{$IFNDEF MSWINDOWS}
function CombineParams(ASkipAppName: Boolean): string;
var
  I: Integer;
  S: TACLStringBuilder;
begin
  S := TACLStringBuilder.Create;
  try
    for I := Ord(ASkipAppName) to ParamCount do
    begin
      if S.Length > 0 then
        S.Append(' ');
      S.Append(ParamStr(I));
    end;
    Result := S.ToString;
  finally
    S.Free;
  end;
end;
{$ENDIF}

function FindSwitch(const ACmdLine, ASwitch: string): Boolean;
var
  X: string;
begin
  Result := FindSwitch(ACmdLine, ASwitch, X);
end;

function FindSwitch(const ACmdLine, ASwitch: string; out ASwitchParam: string): Boolean;
var
  ACommands: TACLCommandLineProcessor.TCommands;
  I: Integer;
begin
  Result := False;
  ACommands := TACLCommandLineProcessor.ParseParams(ACmdLine);
  try
    for I := 0 to ACommands.Count - 1 do
      if acSameText(ACommands[I].Name, ASwitch) then
      begin
        ASwitchParam := ACommands[I].GetDelimitedText(';', False);
        Exit(True);
      end;
  finally
    ACommands.Free;
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
  AParser: TACLParser;
  AToken: TACLParserToken;
begin
  AParser := TACLParser.Create(' '#13#10, acParserDefaultQuotes, acParserDefaultSpaceChars);
  try
    AParser.SkipDelimiters := False;
    AParser.QuotedTextAsSingleToken := True;
    AParser.QuotedTextAsSingleTokenUnquot := True;
    AParser.Initialize(acTrim(GetCommandLine));

    if AParser.GetToken(AToken) then
      Result := acTrim(acMakeString(AParser.Scan, AParser.ScanCount))
    else
      Result := EmptyStr;

  {$IFDEF ACL_LOG_CMDLINE}
    AddToDebugLog('CmdLine', 'GetParams("%s")->"%s"', [GetCommandLine, Result]);
  {$ENDIF}
  finally
    AParser.Free;
  end;
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

class procedure TACLCommandLineProcessor.Execute(const AParams: string);
begin
{$IFDEF ACL_LOG_CMDLINE}
  AddToDebugLog('CmdLine', 'Execute: "%s"', [AParams]);
{$ENDIF}
  Parse(FPendingToExecute, AParams);
  if FLockCount = 0 then
    ExecuteCore;
end;

class procedure TACLCommandLineProcessor.ExecuteFromCommandLine;
begin
  Execute(GetCommandLineParams);
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

class procedure TACLCommandLineProcessor.Unregister(const ACommand: string);
var
  I: Integer;
begin
  FCommands.Remove(ACommand);
  for I := FPendingToExecute.Count - 1 downto 0 do
  begin
    if acSameText(FPendingToExecute.List[I].Name, ACommand) then
      FPendingToExecute.Delete(I);
  end;
end;

class procedure TACLCommandLineProcessor.ExecuteCore;
var
  ACommand: TCommandHandler;
begin
  while FPendingToExecute.Count > 0 do
  begin
    if FCommands.TryGetValue(FPendingToExecute.First.Name, ACommand) then
      ACommand.Execute(FPendingToExecute.First);
    if FPendingToExecute.Count > 0 then // такое может произойти, если во время
                                        // обработки команды протолкнется QuitMessage
                                        // и приложение начнет завершение
      FPendingToExecute.Delete(0);
  end;
end;

class procedure TACLCommandLineProcessor.Parse(ATarget: TCommands; const AParams: string);
var
  AParser: TACLCommandLineParser;
begin
  AParser := TACLCommandLineParser.Create;
  try
    AParser.Initialize(AParams);
    AParser.Parse(ATarget);
  finally
    AParser.Free;
  end;
end;

class function TACLCommandLineProcessor.ParseParams(const AParams: string): TCommands;
begin
  Result := TCommands.Create;
  Parse(Result, AParams);
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

{ TACLCommandLineParser }

constructor TACLCommandLineParser.Create;
begin
  inherited Create('-/=; '#13#10, '"', ' ');
  SkipSpaces := False;
  SkipDelimiters := False;
  QuotedTextAsSingleToken := True;
  QuotedTextAsSingleTokenUnquot := True;

  FHandlers[sNone] := HandlerNone;
  FHandlers[sSeparatedParams] := HandlerSeparatedParams;
  FHandlers[sWaitingForCommand] := HandlerWaitingForCommand;
  FHandlers[sWaitingForCommandName] := HandlerWaitingForCommandName;
  FHandlers[sWaitingForParamSeparator] := HandlerWaitingForParamSeparator;
end;

procedure TACLCommandLineParser.Parse(ATarget: TACLCommandLineProcessor.TCommands);
var
  AToken: TACLParserToken;
begin
  FTarget := ATarget;
  FParamBuffer := TACLStringBuilder.Create;
  try
    FCommand := nil;
    FPrevToken.Reset;
    FState := sWaitingForCommand;
    while GetToken(AToken) do
    begin
    {$IFDEF ACL_LOG_CMDLINE}
      AddToDebugLog('CmdLine', 'Parsing 1: "%s" (%d)', [AToken.ToString, Ord(FState)]);
    {$ENDIF}
      FHandlers[FState](AToken);
    {$IFDEF ACL_LOG_CMDLINE}
      AddToDebugLog('CmdLine', 'Parsing 2: -> %d', [Ord(FState)]);
    {$ENDIF}
      FPrevToken := AToken;
    end;
    PutParam(FParamBuffer);
  {$IFDEF ACL_LOG_CMDLINE}
    AddToDebugLog('CmdLine', 'Parsed: "%s"', [ATarget.ToString]);
  {$ENDIF}
  finally
    FreeAndNil(FParamBuffer);
  end;
end;

procedure TACLCommandLineParser.HandlerNone(const AToken: TACLParserToken);
var
  S: string;
begin
  case AToken.TokenType of
    acTokenSpace:
      FState := sWaitingForCommand;

    acTokenDelimiter, acTokenQuot:
      if CharInSet(AToken.Data^, [#13, #10]) then
        PutParam(FParamBuffer)
      else
        FParamBuffer.Append(AToken.ToString);

    acTokenQuotedText:
      begin
        PutParam(FParamBuffer);
        PutParam(AToken.ToString);
      end;

    acTokenIdent:
      begin
        S := AToken.ToString;
        //# FIXME - workround for some special behavior of Windows Explorer
        if ExtractFileDrive(S) <> '' then
          PutParam(FParamBuffer);
        //#
        FParamBuffer.Append(S);
      end;
  end;
end;

procedure TACLCommandLineParser.HandlerSeparatedParams(const AToken: TACLParserToken);
begin
  case AToken.TokenType of
    acTokenQuotedText, acTokenIdent:
      HandlerNone(AToken);

    acTokenSpace:
      begin
        PutParam(FParamBuffer);
        FState := sWaitingForCommand;
        FCommand := nil;
      end;

    acTokenDelimiter:
      if AToken.Compare(';') then
        PutParam(FParamBuffer)
      else
        FParamBuffer.Append(AToken.ToString);
  end;
end;

procedure TACLCommandLineParser.HandlerWaitingForCommand(const AToken: TACLParserToken);
begin
  if (AToken.TokenType = acTokenDelimiter) and (AToken.Data^ = '/') then
    FState := sWaitingForCommandName
  else
    if (AToken.TokenType = acTokenDelimiter) and (AToken.Data^ = '-') and
      ((FTarget.Count > 0) or (FParamBuffer.Length = 0))
    then
      FState := sWaitingForCommandName
    else
    begin
      FState := sNone;
      FParamBuffer.Append(FPrevToken.ToString);
      HandlerNone(AToken);
    end;
end;

procedure TACLCommandLineParser.HandlerWaitingForCommandName(const AToken: TACLParserToken);
begin
  if AToken.TokenType = acTokenIdent then
  begin
    PutParam(FParamBuffer);
    FCommand := TACLCommandLineProcessor.TCommand.Create;
    FCommand.Name := AToken.ToString;
    FTarget.Add(FCommand);
    FState := sWaitingForParamSeparator;
  end
  else
  begin
    FState := sNone;
    FParamBuffer.Append(' ');
    FParamBuffer.Append(FPrevToken.ToString);
    HandlerNone(AToken);
  end;
end;

procedure TACLCommandLineParser.HandlerWaitingForParamSeparator(const AToken: TACLParserToken);
begin
  if AToken.Compare('=', False) then
    FState := sSeparatedParams
  else
  begin
    FState := sNone;
    HandlerNone(AToken);
  end;
end;

procedure TACLCommandLineParser.PutParam(AParam: string);
begin
  AParam := acTrim(AParam);
  if AParam <> '' then
  begin
  {$IFDEF ACL_LOG_CMDLINE}
    AddToDebugLog('CmdLine', 'PutParam: "%s"', [AParam]);
  {$ENDIF}
    if FCommand = nil then
    begin
      FCommand := TACLCommandLineProcessor.TCommand.Create;
      FTarget.Add(FCommand);
    end;
    FCommand.Add(AParam);
  end;
end;

procedure TACLCommandLineParser.PutParam(AParamBuffer: TACLStringBuilder);
begin
  PutParam(AParamBuffer.ToString);
  AParamBuffer.Length := 0;
end;

end.
