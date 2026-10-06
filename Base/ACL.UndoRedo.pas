////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Undo/Redo Engine
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UndoRedo;

{$I ACL.Config.inc}

interface

uses
  Math,
  Classes,
  SysUtils,
  // ACL
  ACL.Classes.Collections,
  ACL.Math,
  ACL.Threading;

type

  { TACLHistoryCommand }

  TACLHistoryCommandAction = (hcaExec, hcaRedo, hcaUndo);
  TACLHistoryCommand = class abstract
  protected
    FName: string;
    procedure DoIt(AAction: TACLHistoryCommandAction); virtual; abstract;
    function MergeWith(ACommand: TACLHistoryCommand): Boolean; virtual;
    procedure RaiseUnsupported(AAction: TACLHistoryCommandAction);
  public
    property Name: string read FName;
  end;

  { TACLHistoryStreamBasedCommand }

  TACLHistoryStreamBasedCommand = class(TACLHistoryCommand)
  protected
    FData: TMemoryStream;
    procedure DoIt(AAction: TACLHistoryCommandAction); override;
    procedure Restore(AData: TMemoryStream); virtual;
    procedure Store(AData: TMemoryStream); virtual;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  { TACLHistoryAction }

  TACLHistoryAction = class
  private
    FTimestamp: TACLTimestamp;
  protected
    FCommands: TACLObjectListOf<TACLHistoryCommand>;
    FName: string;

    function MergeWith(ACommand: TACLHistoryCommand): Boolean;
    procedure Redo;
    procedure Undo;
  public
    constructor Create;
    destructor Destroy; override;
    //# Properties
    property Commands: TACLObjectListOf<TACLHistoryCommand> read FCommands; // read only
    property Name: string read FName;
  end;

  { TACLHistoryActions }

  TACLHistoryActions = class(TACLObjectListOf<TACLHistoryAction>);

  { TACLCustomHistoryManager }

  TACLCustomHistoryManager = class
  strict private
    FActionCount: Integer;
    FCapacity: Integer;
    FCurrentAction: TACLHistoryAction;
    FInProcess: Boolean;
    FRedoActions: TACLHistoryActions;
    FUndoActions: TACLHistoryActions;

    function GetRedoAction(Index: Integer): TACLHistoryAction;
    function GetRedoActionCount: Integer;
    function GetUndoAction(Index: Integer): TACLHistoryAction;
    function GetUndoActionCount: Integer;
    procedure SetCapacity(AValue: Integer);
  protected
    procedure DoAfterRun; virtual;
    procedure DoAfterUndoRedo; virtual;
    procedure DoBeforeRun; virtual;
    procedure DoBeforeUndoRedo; virtual;
    procedure DoChanged; virtual;
  public
    constructor Create(ACapacity: Integer = MaxInt);
    destructor Destroy; override;
    procedure BeginAction; overload;
    procedure BeginAction(AAction: TACLHistoryAction); overload;
    procedure EndAction(ACanceled: Boolean = False);

    function CanRun: Boolean;
    function CanRedo: Boolean;
    function CanUndo: Boolean;
    procedure Clear;
    procedure Run(ACommand: TACLHistoryCommand);
    procedure Redo(ARedoCount: Integer = 1);
    procedure Undo(AUndoCount: Integer = 1);

    property Capacity: Integer read FCapacity write SetCapacity;
    property CurrentAction: TACLHistoryAction read FCurrentAction;
    property InProcess: Boolean read FInProcess;
    property RedoActions[Index: Integer]: TACLHistoryAction read GetRedoAction;
    property RedoActionCount: Integer read GetRedoActionCount;
    property UndoActions[Index: Integer]: TACLHistoryAction read GetUndoAction;
    property UndoActionCount: Integer read GetUndoActionCount;
  end;

  { IACLHistoryListener }

  IACLHistoryListener = interface
  ['{085895D0-36FB-49CE-AEA4-831B90A86D03}']
    procedure Changed;
  end;

  { IACLHistoryRunListener }

  IACLHistoryRunListener = interface
  ['{DF74E1D0-6E6A-4E0E-8B67-AF820D56EB54}']
    procedure AfterRun;
    procedure BeforeRun;
  end;

  { IACLHistoryUndoRedoListener }

  IACLHistoryUndoRedoListener = interface
  ['{3AA9A213-6F0B-46B9-96A3-2605E650FF93}']
    procedure AfterUndoRedo;
    procedure BeforeUndoRedo;
  end;

  { TACLHistoryManager }

  TACLHistoryManager = class(TACLCustomHistoryManager)
  strict private
    FListeners: TACLListenerList;
  protected
    procedure DoAfterRun; override;
    procedure DoAfterUndoRedo; override;
    procedure DoBeforeRun; override;
    procedure DoBeforeUndoRedo; override;
    procedure DoChanged; override;
  public
    destructor Destroy; override;
    procedure AfterConstruction; override;
    property Listeners: TACLListenerList read FListeners;
  end;

implementation

uses
  ACL.Classes,
  ACL.Utils.Common,
  ACL.Utils.Strings;

{ TACLHistoryCommand }

function TACLHistoryCommand.MergeWith(ACommand: TACLHistoryCommand): Boolean;
begin
  Result := False;
end;

procedure TACLHistoryCommand.RaiseUnsupported(AAction: TACLHistoryCommandAction);
const
  Names: array[TACLHistoryCommandAction] of string = ('Exec', 'Redo', 'Undo');
begin
  raise ENotSupportedException.Create(ClassName + ': ' + Names[AAction] + ' is not yet supported');
end;

{ TACLHistoryAction }

constructor TACLHistoryAction.Create;
begin
  inherited;
  FTimestamp := TACLThread.Timestamp;
  FCommands := TACLObjectListOf<TACLHistoryCommand>.Create;
end;

destructor TACLHistoryAction.Destroy;
begin
  FreeAndNil(FCommands);
  inherited;
end;

function TACLHistoryAction.MergeWith(ACommand: TACLHistoryCommand): Boolean;
begin
  Result := (FCommands.Count > 0) and FCommands.Last.MergeWith(ACommand);
  if Result then
  try
    FCommands.Last.FName := ACommand.Name;
  finally
    ACommand.Free;
  end
end;

procedure TACLHistoryAction.Redo;
var
  I: Integer;
begin
  for I := 0 to FCommands.Count - 1 do
    FCommands.List[I].DoIt(hcaRedo);
end;

procedure TACLHistoryAction.Undo;
var
  I: Integer;
begin
  for I := FCommands.Count - 1 downto 0 do
    FCommands.List[I].DoIt(hcaUndo);
end;

{ TACLHistoryStreamBasedCommand }

constructor TACLHistoryStreamBasedCommand.Create;
begin
  inherited;
  FData := TMemoryStream.Create;
end;

destructor TACLHistoryStreamBasedCommand.Destroy;
begin
  FreeAndNil(FData);
  inherited;
end;

procedure TACLHistoryStreamBasedCommand.DoIt(AAction: TACLHistoryCommandAction);
var
  LData: TMemoryStream;
begin
  LData := TMemoryStream.Create;
  try
    Store(LData);
    FData.Position := 0;
    Restore(FData);
    TACLMath.ExchangePtr(FData, LData);
  finally
    LData.Free;
  end;
end;

procedure TACLHistoryStreamBasedCommand.Restore(AData: TMemoryStream);
begin
  // do nothing
end;

procedure TACLHistoryStreamBasedCommand.Store(AData: TMemoryStream);
begin
  // do nothing
end;

{ TACLCustomHistoryManager }

constructor TACLCustomHistoryManager.Create(ACapacity: Integer = MaxInt);
begin
  inherited Create;
  FCapacity := ACapacity;
  FRedoActions := TACLHistoryActions.Create;
  FUndoActions := TACLHistoryActions.Create;
end;

destructor TACLCustomHistoryManager.Destroy;
begin
  FreeAndNil(FRedoActions);
  FreeAndNil(FUndoActions);
  inherited;
end;

procedure TACLCustomHistoryManager.BeginAction;
begin
  BeginAction(TACLHistoryAction.Create);
end;

procedure TACLCustomHistoryManager.BeginAction(AAction: TACLHistoryAction);
begin
  Inc(FActionCount);
  if FActionCount = 1 then
    FCurrentAction := AAction
  else
    AAction.Free;
end;

procedure TACLCustomHistoryManager.EndAction(ACanceled: Boolean);
begin
  Dec(FActionCount);
  if (FActionCount = 0) and (FCurrentAction <> nil) then
  begin
    if ACanceled or (FCurrentAction.FCommands.Count = 0) then
    begin
      FCurrentAction.Undo;
      FreeAndNil(FCurrentAction);
    end
    else
    begin
      FRedoActions.Clear;
      FUndoActions.Add(FCurrentAction);
      FCurrentAction := nil;
      while FUndoActions.Count > Capacity do
        FUndoActions.Delete(0);
      DoChanged;
    end;
  end;
end;

function TACLCustomHistoryManager.CanRedo: Boolean;
begin
  Result := FRedoActions.Count > 0;
end;

function TACLCustomHistoryManager.CanRun: Boolean;
begin
  Result := not InProcess;
end;

function TACLCustomHistoryManager.CanUndo: Boolean;
begin
  Result := FUndoActions.Count > 0;
end;

procedure TACLCustomHistoryManager.Clear;
begin
  if not InProcess then
  begin
    FRedoActions.Clear;
    FUndoActions.Clear;
    DoChanged;
  end;
end;

procedure TACLCustomHistoryManager.Run(ACommand: TACLHistoryCommand);
var
  LAction: TACLHistoryAction;
  LTimestamp: TACLTimestamp;
begin
  if FInProcess then
  begin
    FreeAndNil(ACommand);
    Exit;
  end;

  if FCurrentAction <> nil then
  begin
    DoBeforeRun;
    try
      if FCurrentAction.Name = '' then
        FCurrentAction.FName := ACommand.Name;
      if not FCurrentAction.MergeWith(ACommand) then
      begin
        try
          ACommand.DoIt(hcaExec);
        except
          FreeAndNil(ACommand);
          raise;
        end;
        FCurrentAction.FCommands.Add(ACommand);
      end;
    finally
      DoAfterRun;
    end;
    Exit;
  end;

  if FUndoActions.Count > 0 then
  begin
    LAction := FUndoActions.Last;
    LTimestamp := TACLThread.Timestamp;
    if LTimestamp - LAction.FTimestamp < 1000 then
    begin
      DoBeforeRun;
      try
        if LAction.MergeWith(ACommand) then
        begin
          LAction.FTimestamp := LTimestamp;
          Exit;
        end;
      finally
        DoAfterRun;
      end;
    end;
  end;

  BeginAction;
  try
    Run(ACommand);
  finally
    EndAction;
  end;
end;

procedure TACLCustomHistoryManager.SetCapacity(AValue: Integer);
begin
  AValue := Max(AValue, 0);
  if FCapacity <> AValue then
  begin
    FCapacity := AValue;
    Clear;
  end;
end;

procedure TACLCustomHistoryManager.Redo(ARedoCount: Integer);
var
  ACurrentAction: TACLHistoryAction;
begin
  FInProcess := True;
  try
    DoBeforeUndoRedo;
    try
      while (ARedoCount > 0) and (RedoActionCount > 0) do
      begin
        ACurrentAction := FRedoActions.Extract(FRedoActions.Last);
        ACurrentAction.Redo;
        FUndoActions.Add(ACurrentAction);
        Dec(ARedoCount);
      end;
      DoChanged;
    finally
      DoAfterUndoRedo;
    end;
  finally
    FInProcess := False;
  end;
end;

procedure TACLCustomHistoryManager.Undo(AUndoCount: Integer);
var
  ACurrentAction: TACLHistoryAction;
begin
  FInProcess := True;
  try
    DoBeforeUndoRedo;
    try
      while (AUndoCount > 0) and (UndoActionCount > 0) do
      begin
        ACurrentAction := FUndoActions.Extract(FUndoActions.Last);
        ACurrentAction.Undo;
        FRedoActions.Add(ACurrentAction);
        Dec(AUndoCount);
      end;
      DoChanged;
    finally
      DoAfterUndoRedo;
    end;
  finally
    FInProcess := False;
  end;
end;

procedure TACLCustomHistoryManager.DoAfterRun;
begin
  // do nothing
end;

procedure TACLCustomHistoryManager.DoAfterUndoRedo;
begin
  // do nothing
end;

procedure TACLCustomHistoryManager.DoBeforeRun;
begin
  // do nothing
end;

procedure TACLCustomHistoryManager.DoBeforeUndoRedo;
begin
  // do nothing
end;

procedure TACLCustomHistoryManager.DoChanged;
begin
  // do nothing
end;

function TACLCustomHistoryManager.GetRedoAction(Index: Integer): TACLHistoryAction;
begin
  Result := FRedoActions.List[Index];
end;

function TACLCustomHistoryManager.GetRedoActionCount: Integer;
begin
  Result := FRedoActions.Count;
end;

function TACLCustomHistoryManager.GetUndoAction(Index: Integer): TACLHistoryAction;
begin
  Result := FUndoActions.List[Index];
end;

function TACLCustomHistoryManager.GetUndoActionCount: Integer;
begin
  Result := FUndoActions.Count;
end;

{ TACLHistoryManager }

procedure TACLHistoryManager.AfterConstruction;
begin
  inherited;
  FListeners := TACLListenerList.Create;
end;

destructor TACLHistoryManager.Destroy;
begin
  FreeAndNil(FListeners);
  inherited;
end;

procedure TACLHistoryManager.DoAfterRun;
var
  LIntf: IACLHistoryRunListener;
begin
  for LIntf in FListeners.Enumerate<IACLHistoryRunListener> do
    LIntf.AfterRun;
end;

procedure TACLHistoryManager.DoAfterUndoRedo;
var
  LIntf: IACLHistoryUndoRedoListener;
begin
  for LIntf in FListeners.Enumerate<IACLHistoryUndoRedoListener> do
    LIntf.AfterUndoRedo;
end;

procedure TACLHistoryManager.DoBeforeRun;
var
  LIntf: IACLHistoryRunListener;
begin
  for LIntf in FListeners.Enumerate<IACLHistoryRunListener> do
    LIntf.BeforeRun;
end;

procedure TACLHistoryManager.DoBeforeUndoRedo;
var
  LIntf: IACLHistoryUndoRedoListener;
begin
  for LIntf in FListeners.Enumerate<IACLHistoryUndoRedoListener> do
    LIntf.BeforeUndoRedo;
end;

procedure TACLHistoryManager.DoChanged;
var
  LIntf: IACLHistoryListener;
begin
  for LIntf in FListeners.Enumerate<IACLHistoryListener> do
    LIntf.Changed;
end;

end.
