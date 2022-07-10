{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*              Common Classes               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Classes;

{$I ACL.Config.INC}

interface

uses
  Types, TypInfo, Windows, Classes, SysUtils, Messages, Contnrs, Generics.Collections,
  // ACL
  ACL.ObjectLinks,
  ACL.Threading,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type
  TACLSortDirection = (sdDefault, sdAscending, sdDescending);

  { IACLUpdateLock }

  IACLUpdateLock = interface
  ['{7D4A7E68-7D1A-4D48-915D-287DC1D0EE9C}']
    procedure BeginUpdate;
    procedure EndUpdate;
  end;

  { TACLInterfacedObject }

  TACLInterfacedObject = class(TObject, IUnknown)
  strict private
    FRefCount: Integer;
  protected
    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; virtual; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    class function NewInstance: TObject; override;
    property RefCount: Integer read FRefCount;
  end;

  { TACLUnknownObject }

  TACLUnknownObject = class(TObject, IUnknown)
  protected
    // IUnknown
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; virtual; stdcall;
  end;

  { TACLUnknownPersistent }

  TACLUnknownPersistent = class(TPersistent, IUnknown)
  strict private
    FIsDestroying: Boolean;
  protected
    // IUnknown
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; virtual; stdcall;
    //
    property IsDestroying: Boolean read FIsDestroying;
  public
    procedure BeforeDestruction; override;
  end;

  { TACLCollectionItem }

  TACLCollectionItem = class(TCollectionItem, IACLObjectLinksSupport, IUnknown)
  strict private
    FIsDestroying: Boolean;
  protected
    // IUnknown
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
    //
    property IsDestroying: Boolean read FIsDestroying;
  public
    procedure BeforeDestruction; override;
  end;

  { TACLCollection }

  TACLCollection = class(TCollection,
    IACLUpdateLock,
    IUnknown)
  strict private
    FHasChanges: Boolean;
    FUpdateCount: Integer;

    // IUnknown
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
  protected
    procedure Update(Item: TCollectionItem); override; final;
    procedure UpdateCore(Item: TCollectionItem); virtual;
  public
    procedure BeginUpdate; override;
    procedure CancelUpdate;
    procedure EndUpdate; override;
  end;

  { TACLLockablePersistent }

  TACLPersistentChange = (apcStruct, apcLayout, apcContent);
  TACLPersistentChanges = set of TACLPersistentChange;

  TACLPersistentChangeEvent = procedure (Sender: TObject; AChanges: TACLPersistentChanges) of object;

  TACLLockablePersistent = class(TACLUnknownPersistent, IACLUpdateLock)
  strict private
    FChanges: TACLPersistentChanges;
    FLockCount: Integer;

    function GetIsLocked: Boolean;
  protected
    procedure DoAssign(Source: TPersistent); virtual;
    procedure DoChanged(AChanges: TACLPersistentChanges); virtual; abstract;
    procedure Changed(AChanges: TACLPersistentChanges = [apcStruct]);
    //
    property IsLocked: Boolean read GetIsLocked;
  public
    procedure Assign(Source: TPersistent); override;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    procedure CancelUpdate; virtual;
  end;

  { TACLReadWriteSyncPersistent }

  TACLReadWriteSyncPersistent = class(TACLLockablePersistent)
  strict private
    FReadWriteLock: IReadWriteSync;
    FUpdateLock: TACLCriticalSection;
  public
    destructor Destroy; override;
    procedure AfterConstruction; override;
    // Locks
    procedure BeginRead;
    procedure BeginUpdate; override;
    procedure BeginWrite;
    procedure CancelUpdate; override;
    procedure EndRead;
    procedure EndUpdate; override;
    procedure EndWrite;
  end;

  { TACLComponent }

  TACLComponent = class(TComponent, IACLObjectLinksSupport)
  public
    procedure BeforeDestruction; override;
    function IsDestroying: Boolean; inline;
  end;

  { TACLComponentFreeNotifier }

  TACLComponentFreeNotifyEvent = procedure (Sender: TObject; AComponent: TComponent) of object;
  TACLComponentFreeNotifier = class(TComponent)
  strict private
    FOnFreeNotify: TACLComponentFreeNotifyEvent;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    property OnFreeNotify: TACLComponentFreeNotifyEvent read FOnFreeNotify write FOnFreeNotify;
  end;

  { TACLProgressCalculator }

  TACLProgressEvent = procedure (Sender: TObject; AProgress: Single) of object;

  TACLProgressCalculator = class
  strict private const
    sErrorCannotModify = 'Cannot modify stages while process is active';
    sErrorProcessAlreadyStarted = 'Process is already started';
    sErrorProcessNotStarted = 'Process was not started';
    sErrorStagesNotDefined = 'Stages were not defined';
  strict private type
  {$REGION 'Private Type'}
    TStage = class
      Progress: Single;
      Weight: Single;
    end;
  {$ENDREGION}
  strict private
    FCurrentStage: TStage;
    FProgress: Single;
    FStages: TObjectList;
    FStarted: Boolean;

    FOnProgress: TACLProgressEvent;

    procedure CheckStarted;
    function GetStageProgress: Single;
    procedure SetProgress(AValue: Single; AForceUpdate: Boolean = False);
    procedure UpdateProgress;
  protected
    procedure ProgressChanged; virtual;
  public
    constructor Create; overload;
    constructor Create(AEvent: TACLProgressEvent); overload;
    destructor Destroy; override;
    procedure AddStage(AWeight: Single = 1.0);
    procedure NextStage;
    procedure SetStageProgress(const AIndex, AMaxIndex: Double); overload;
    procedure SetStageProgress(const AIndex, AMaxIndex: Int64); overload;
    procedure SetStageProgress(const AProgress: Single); overload;
    procedure SetStageProgress(Sender: TObject; AProgress: Single); overload;
    procedure Start;
    procedure Stop;
    //
    property Progress: Single read FProgress;
    property StageProgress: Single read GetStageProgress;
    //
    property OnProgress: TACLProgressEvent read FOnProgress write FOnProgress;
  end;

// Notify Helpers
procedure CallNotifyEvent(ASender: TObject; AEvent: TNotifyEvent); inline;
procedure CallProcedure(AProc: TProcedureRef); inline;
procedure CallProgressEvent(AEvent: TACLProgressEvent; const APosition, ATotal: Int64; ASender: TObject = nil); inline;

function acComponentFieldSet(var AField; AOwner, ANewValue: TComponent): Boolean;
function acFindComponent(AComponent: TComponent; const AName: TComponentName; ARecursive: Boolean = True): TComponent;
function acFindOwnerThatSupportTheInterface(APersistent: TPersistent; const IID: TGUID; out AIntf): TPersistent;
function acIsDelphiObject(AData: Pointer): Boolean;
function acIsValidIdent(const S: UnicodeString; AAllowUnicodeIdents: Boolean = True; AAllowDots: Boolean = False): Boolean;

function CreateUniqueName(AComponent: TComponent; const APrefixName, ASuffixName: string): string;
implementation

uses
  Math,
  SysConst,
  ACL.FastCode,
  ACL.Math,
  ACL.Threading.Sorting,
  ACL.Utils.FileSystem,
  ACL.Utils.Stream;

type
  TPersistentAccess = class(TPersistent);

procedure CallNotifyEvent(ASender: TObject; AEvent: TNotifyEvent);
begin
  if Assigned(AEvent) then AEvent(ASender);
end;

procedure CallProcedure(AProc: TProcedureRef);
begin
  if Assigned(AProc) then
    AProc();
end;

procedure CallProgressEvent(AEvent: TACLProgressEvent; const APosition, ATotal: Int64; ASender: TObject = nil);
begin
  if Assigned(AEvent) then
    AEvent(ASender, 100 * (APosition / ATotal));
end;

function acComponentFieldSet(var AField; AOwner, ANewValue: TComponent): Boolean;
begin
  Result := TComponent(AField) <> ANewValue;
  if Result then
  begin
    if TComponent(AField) <> nil then
    begin
      TComponent(AField).RemoveFreeNotification(AOwner);
      TComponent(AField) := nil;
    end;
    if ANewValue <> nil then
    begin
      TComponent(AField) := ANewValue;
      TComponent(AField).FreeNotification(AOwner);
    end;
  end;
end;

function acFindComponent(AComponent: TComponent; const AName: TComponentName; ARecursive: Boolean = True): TComponent;
var
  I: Integer;
begin
  Result := AComponent.FindComponent(AName);
  if ARecursive and (Result = nil) then
    for I := 0 to AComponent.ComponentCount - 1 do
    begin
      Result := acFindComponent(AComponent.Components[I], AName);
      if Result <> nil then
        Break;
    end;
end;

function acFindOwnerThatSupportTheInterface(APersistent: TPersistent; const IID: TGUID; out AIntf): TPersistent;
begin
  Result := APersistent;
  if Result <> nil then
  repeat
    if Supports(Result, IID, AIntf) then
      Exit;
    Result := TPersistentAccess(Result).GetOwner;
  until Result = nil;
end;

function acIsDelphiObject(AData: Pointer): Boolean;
var
  P: Pointer;
  SelfPtr: Pointer;
begin
  Result := False;

  P := Pointer(AData);
  if IsBadReadPtr(P, SizeOf(Pointer)) then Exit;

  P := PPointer(P)^;
  if IsBadReadPtr(P, SizeOf(Pointer)) then Exit;

  SelfPtr := Pointer(NativeInt(P) + vmtSelfPtr);
  if IsBadReadPtr(SelfPtr, SizeOf(Pointer)) then Exit;
  SelfPtr := PPointer(SelfPtr)^;

  Result := P = SelfPtr;
end;

function acIsValidIdent(const S: UnicodeString; AAllowUnicodeIdents: Boolean = True; AAllowDots: Boolean = False): Boolean;
var
  I: Integer;
begin
  Result := S.Length > 0;
  if Result and not AAllowUnicodeIdents then
  begin
    for I := Low(S) to High(S) do
      Result := Result and CharInSet(S[I], ['A'..'Z', 'a'..'z', '_', '0'..'9', '.']);
  end;
  Result := Result and IsValidIdent(S, AAllowDots);
end;

function CreateUniqueName(AComponent: TComponent; const APrefixName, ASuffixName: string): string;

  procedure CheckName(var AName: string);
  var
    I: Integer;
  begin
    I := 1;
    while I <= Length(AName) do
      if CharInSet(AName[I], ['A'..'Z','a'..'z','_','0'..'9']) then
        Inc(I)
      else
        if CharInSet(AName[I], LeadBytes) then
          Delete(AName, I, 2)
        else
          Delete(AName, I, 1);
  end;

  function GenerateComponentName(const AClassName: string; ANumber: Integer): string;
  var
    S: string;
  begin
    S := ASuffixName;
    CheckName(S);
    if ((S = '') or CharInSet(S[1], ['0'..'9'])) and (AClassName <> '') then
    begin
      if (APrefixName <> '') and acBeginsWith(AClassName, APrefixName) then
        S := Copy(AClassName, Length(APrefixName) + 1, Length(AClassName)) + S
      else
      begin
        S := AClassName + S;
        if S[1] = 'T' then
          Delete(S, 1, 1);
      end;
    end;

    if ANumber > 0 then
      Result := S + IntToStr(ANumber)
    else
      Result := S;
  end;

  function GetMainOwner(AComponent: TComponent): TComponent;
  begin
    Result := AComponent;
    while Result.Owner <> nil do
      Result := Result.Owner;
  end;

  function IsUnique(AComponent: TComponent; const AName: string): Boolean;
  var
    I: Integer;
  begin
    Result := True;
    with AComponent do
      for I := 0 to ComponentCount - 1 do
      begin
        if (Components[I] <> AComponent) and (acSameText(Components[I].Name, AName) or not IsUnique(Components[I], AName)) then
          Exit(False);
      end;
  end;

var
  I, J: Integer;
  AMainOwner: TComponent;
begin
  J := Ord(ASuffixName = '');
  AMainOwner := GetMainOwner(AComponent);
  for I := J to MaxInt do
  begin
    Result := GenerateComponentName(AComponent.ClassName, I);
    if IsUnique(AMainOwner, Result) then
      Break;
  end;
end;

{ TACLInterfacedObject }

procedure TACLInterfacedObject.AfterConstruction;
begin
  // Release the constructor's implicit refcount
  AtomicDecrement(FRefCount);
end;

procedure TACLInterfacedObject.BeforeDestruction;
begin
  if RefCount <> 0 then
    raise Exception.Create('Invalid Pointer');
  inherited BeforeDestruction;
end;

// Set an implicit refcount so that refcounting
// during construction won't destroy the object.
class function TACLInterfacedObject.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TACLInterfacedObject(Result).FRefCount := 1;
end;

function TACLInterfacedObject.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TACLInterfacedObject._AddRef: Integer;
begin
  Result := AtomicIncrement(FRefCount);
end;

function TACLInterfacedObject._Release: Integer;
begin
  Result := AtomicDecrement(FRefCount);
  if Result = 0 then
    Destroy;
end;

{ TACLUnknownObject }

function TACLUnknownObject._AddRef: Integer; stdcall;
begin
  Result := -1;
end;

function TACLUnknownObject._Release: Integer; stdcall;
begin
  Result := -1;
end;

function TACLUnknownObject.QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

{ TACLUnknownPersistent }

procedure TACLUnknownPersistent.BeforeDestruction;
begin
  FIsDestroying := True;
  inherited BeforeDestruction;
end;

function TACLUnknownPersistent._AddRef: Integer; stdcall;
begin
  Result := -1;
end;

function TACLUnknownPersistent._Release: Integer; stdcall;
begin
  Result := -1;
end;

function TACLUnknownPersistent.QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

{ TACLCollectionItem }

function TACLCollectionItem._AddRef: Integer;
begin
  Result := -1;
end;

function TACLCollectionItem._Release: Integer;
begin
  Result := -1;
end;

function TACLCollectionItem.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

procedure TACLCollectionItem.BeforeDestruction;
begin
  FIsDestroying := True;
  inherited BeforeDestruction;
  TACLObjectLinks.Release(Self);
end;

{ TACLCollection }

procedure TACLCollection.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TACLCollection.CancelUpdate;
begin
  FHasChanges := False;
  EndUpdate;
end;

procedure TACLCollection.EndUpdate;
begin
  Dec(FUpdateCount);
  if (FUpdateCount = 0) and FHasChanges then
    Update(nil);
end;

procedure TACLCollection.Update(Item: TCollectionItem);
begin
  FHasChanges := True;
  if FUpdateCount = 0 then
  begin
    FHasChanges := False;
    UpdateCore(Item);
  end;
end;

procedure TACLCollection.UpdateCore(Item: TCollectionItem);
begin
  // do nothing
end;

function TACLCollection._AddRef: Integer;
begin
  Result := -1;
end;

function TACLCollection._Release: Integer;
begin
  Result := -1;
end;

function TACLCollection.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

{ TACLLockablePersistent }

procedure TACLLockablePersistent.Assign(Source: TPersistent);
begin
  if Self <> Source then
  begin
    BeginUpdate;
    try
      DoAssign(Source);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TACLLockablePersistent.BeginUpdate;
begin
  Inc(FLockCount);
end;

procedure TACLLockablePersistent.Changed(AChanges: TACLPersistentChanges);
begin
  FChanges := FChanges + AChanges;
  if FLockCount = 0 then
  begin
    AChanges := FChanges;
    FChanges := [];
    DoChanged(AChanges);
  end;
end;

procedure TACLLockablePersistent.DoAssign(Source: TPersistent);
begin
  if Source <> nil then
    TPersistentAccess(Source).AssignTo(Self);
end;

procedure TACLLockablePersistent.EndUpdate;
begin
  Dec(FLockCount);
  if (FLockCount = 0) and (FChanges <> []) then
    Changed(FChanges);
end;

procedure TACLLockablePersistent.CancelUpdate;
begin
  FChanges := [];
  EndUpdate;
end;

function TACLLockablePersistent.GetIsLocked: Boolean;
begin
  Result := FLockCount > 0;
end;

{ TACLReadWriteSyncPersistent }

procedure TACLReadWriteSyncPersistent.AfterConstruction;
begin
  inherited;
  FUpdateLock := TACLCriticalSection.Create;
  FReadWriteLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TACLReadWriteSyncPersistent.Destroy;
begin
  FreeAndNil(FUpdateLock);
  inherited;
end;

procedure TACLReadWriteSyncPersistent.BeginRead;
begin
  FReadWriteLock.BeginRead;
end;

procedure TACLReadWriteSyncPersistent.BeginUpdate;
begin
  FUpdateLock.Enter;
  try
    inherited BeginUpdate;
  finally
    FUpdateLock.Leave;
  end;
end;

procedure TACLReadWriteSyncPersistent.BeginWrite;
begin
  FReadWriteLock.BeginWrite;
  BeginUpdate;
end;

procedure TACLReadWriteSyncPersistent.CancelUpdate;
begin
  FUpdateLock.Enter;
  try
    inherited CancelUpdate;
  finally
    FUpdateLock.Leave;
  end;
end;

procedure TACLReadWriteSyncPersistent.EndRead;
begin
  FReadWriteLock.EndRead;
end;

procedure TACLReadWriteSyncPersistent.EndUpdate;
begin
  FUpdateLock.Enter;
  try
    inherited EndUpdate;
  finally
    FUpdateLock.Leave;
  end;
end;

procedure TACLReadWriteSyncPersistent.EndWrite;
begin
  EndUpdate;
  FReadWriteLock.EndWrite;
end;

{ TACLComponent }

procedure TACLComponent.BeforeDestruction;
begin
  inherited BeforeDestruction;
  RemoveFreeNotifications;
  TACLObjectLinks.Release(Self);
end;

function TACLComponent.IsDestroying: Boolean;
begin
  Result := csDestroying in ComponentState;
end;

{ TACLComponentFreeNotifier }

procedure TACLComponentFreeNotifier.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if Assigned(OnFreeNotify) then
      OnFreeNotify(Self, AComponent);
  end;
end;

{ TACLProgressCalculator }

constructor TACLProgressCalculator.Create;
begin
  FStages := TObjectList.Create;
end;

constructor TACLProgressCalculator.Create(AEvent: TACLProgressEvent);
begin
  Create;
  OnProgress := AEvent;
end;

destructor TACLProgressCalculator.Destroy;
begin
  FreeAndNil(FStages);
  inherited;
end;

procedure TACLProgressCalculator.AddStage(AWeight: Single);
var
  AStage: TStage;
begin
  if FStarted then
    raise EInvalidOperation.Create(sErrorCannotModify);
  if (AWeight < 0) or IsZero(AWeight) then
    raise EInvalidArgument.Create('W <= 0');

  AStage := TStage.Create;
  AStage.Progress := 0;
  AStage.Weight := AWeight;
  FStages.Add(AStage)
end;

function TACLProgressCalculator.GetStageProgress: Single;
begin
  if FCurrentStage <> nil then
    Result := FCurrentStage.Progress
  else
    Result := 0;
end;

procedure TACLProgressCalculator.NextStage;
begin
  CheckStarted;
  FCurrentStage.Progress := 100;
  FCurrentStage := TStage(FStages[FStages.IndexOf(FCurrentStage) + 1]);
  UpdateProgress;
end;

procedure TACLProgressCalculator.SetStageProgress(Sender: TObject; AProgress: Single);
begin
  SetStageProgress(AProgress);
end;

procedure TACLProgressCalculator.SetStageProgress(const AIndex, AMaxIndex: Double);
begin
  if AMaxIndex > 0 then
    SetStageProgress(100 * AIndex / AMaxIndex);
end;

procedure TACLProgressCalculator.SetStageProgress(const AProgress: Single);
begin
  CheckStarted;
  FCurrentStage.Progress := AProgress;
  UpdateProgress;
end;

procedure TACLProgressCalculator.SetStageProgress(const AIndex, AMaxIndex: Int64);
begin
  if AMaxIndex > 0 then
    SetStageProgress(MulDiv64(100, AIndex, AMaxIndex));
end;

procedure TACLProgressCalculator.Start;
var
  AStage: TStage;
  AWeightSummary: Single;
  I: Integer;
begin
  if FStarted then
    raise EInvalidOperation.Create(sErrorProcessAlreadyStarted);
  if FStages.Count = 0 then
    raise EInvalidArgument.Create(sErrorStagesNotDefined);

  AWeightSummary := 0;
  for I := 0 to FStages.Count - 1 do
    AWeightSummary := AWeightSummary + TStage(FStages.List[I]).Weight;
  for I := 0 to FStages.Count - 1 do
  begin
    AStage := TStage(FStages.List[I]);
    AStage.Progress := 0;
    AStage.Weight := AStage.Weight / AWeightSummary;
  end;

  FCurrentStage := TStage(FStages.First);
  FProgress := 0;
  FStarted := True;
end;

procedure TACLProgressCalculator.Stop;
begin
  CheckStarted;
  SetProgress(100, True);
  FStarted := False;
end;

procedure TACLProgressCalculator.ProgressChanged;
begin
  if Assigned(OnProgress) then
    OnProgress(Self, FProgress);
end;

procedure TACLProgressCalculator.CheckStarted;
begin
  if not FStarted then
    raise EInvalidOperation.Create(sErrorProcessNotStarted);
end;

procedure TACLProgressCalculator.SetProgress(AValue: Single; AForceUpdate: Boolean = False);
begin
  if AForceUpdate or not SameValue(FProgress, AValue, 0.01) then
  begin
    FProgress := AValue;
    ProgressChanged;
  end;
end;

procedure TACLProgressCalculator.UpdateProgress;
var
  AProgress: Single;
  AStage: TStage;
  I: Integer;
begin
  AProgress := 0;
  for I := 0 to FStages.Count - 1 do
  begin
    AStage := TStage(FStages.List[I]);
    AProgress := AProgress + AStage.Weight * AStage.Progress;
  end;
  SetProgress(AProgress);
end;

end.
