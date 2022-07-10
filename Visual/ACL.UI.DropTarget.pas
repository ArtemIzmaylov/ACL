{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*           DropTarget Component            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.DropTarget;

{$I ACL.Config.inc}

interface

uses
  Windows, Messages, ActiveX, Classes, Controls, ShlObj, Generics.Collections,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.UI.Controls.BaseControls,
  ACL.UI.HintWindow,
  ACL.Utils.Clipboard,
  ACL.Utils.Desktop,
  ACL.Utils.FileSystem,
  ACL.Utils.Shell,
  ACL.Utils.Strings;

type
  TACLDropTarget = class;

  TACLDropAction = (daCopy, daMove, daLink);

  TACLDropTargetDropEvent = procedure (Sender: TACLDropTarget; Shift: TShiftState; P: TPoint; Action: TACLDropAction) of object;
  TACLDropTargetOverEvent = procedure (Sender: TACLDropTarget; Shift: TShiftState; P: TPoint;
    var Hint: UnicodeString; var Allow: Boolean; var Action: TACLDropAction) of object;
  TACLDropTargetScrollEvent = procedure (Sender: TObject; P: TPoint;
    Lines: Integer; Direction: TACLMouseWheelDirection; var AHandled: Boolean) of object;

  { IACLDropTarget }

  IACLDropTarget = interface
  ['{B57F63C7-8228-45FC-80DB-065E5FFC8F3A}']
    procedure DoDrop(Shift: TShiftState; const ScreenPoint: TPoint; Action: TACLDropAction);
    procedure DoEnter;
    procedure DoLeave;
    procedure DoOver(Shift: TShiftState; const ScreenPoint: TPoint; var Hint: UnicodeString; var Allow: Boolean; var Action: TACLDropAction);
    function IsInTarget(const ScreenPoint: TPoint): Boolean;
  end;

  { IACLDropTargetHook }

  IACLDropTargetHook = interface
  ['{D0B4CD71-C793-468C-895E-0DAC648D8AD6}']
    function GetActiveTarget: IACLDropTarget;
    function GetData(AFormat: Word; out AMedium: TStgMedium): Boolean;
    function GetDataAsString(AFormat: Word; out AString: UnicodeString): Boolean;
    function HasData(AFormat: Word): Boolean;
    procedure SendConfig(const AConfig: TACLIniFile);
  end;

  { TACLDropTargetOptions }

  TACLDropTargetOptions = class(TPersistent)
  strict private
    FAllowURLsInFiles: Boolean;
    FExpandShortcuts: Boolean;
  public
    procedure AfterConstruction; override;
    procedure Assign(Source: TPersistent); override;
  published
    property AllowURLsInFiles: Boolean read FAllowURLsInFiles write FAllowURLsInFiles default True;
    property ExpandShortcuts: Boolean read FExpandShortcuts write FExpandShortcuts default True;
  end;

  { TACLDropTarget }

  TACLDropTarget = class(TComponent, IACLDropTarget)
  strict private
    FConfig: TACLIniFile;
    FHook: IACLDropTargetHook;
    FOptions: TACLDropTargetOptions;
    FTarget: TWinControl;
    FTargetIsActive: Boolean;

    FOnDrop: TACLDropTargetDropEvent;
    FOnEnter: TNotifyEvent;
    FOnLeave: TNotifyEvent;
    FOnOver: TACLDropTargetOverEvent;
    FOnScroll: TACLDropTargetScrollEvent;

    procedure ConfigChangeHandler(Sender: TObject);
    procedure SendConfig(AConfig: TACLIniFile);
    procedure SetOptions(AValue: TACLDropTargetOptions);
    procedure SetTarget(AValue: TWinControl);
    procedure ValidateFiles(AFiles: TACLStringList);
  protected
    procedure CheckContentScrolling(const AClientPoint: TPoint);
    function GetTargetClientRect: TRect; virtual;
    function ScreenToClient(const P: TPoint): TPoint; virtual;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;

    // IACLDropTarget
    procedure DoEnter; virtual;
    procedure DoLeave; virtual;
    procedure DoOver(Shift: TShiftState; const ScreenPoint: TPoint;
      var Hint: UnicodeString; var Allow: Boolean; var Action: TACLDropAction); virtual;
    procedure DoDrop(Shift: TShiftState; const ScreenPoint: TPoint; Action: TACLDropAction); virtual;
    procedure DoScroll(ALines: Integer; ADirection: TACLMouseWheelDirection; const P: TPoint); virtual;
    function IsInTarget(const AScreenPoint: TPoint): Boolean; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;

    // Source Data
    function GetConfig(out AConfig: TACLIniFile): Boolean;
    function GetData(AFormat: Word; out AMedium: TStgMedium): Boolean;
    function GetDataAsString(AFormat: Word; out AString: UnicodeString): Boolean;
    function GetFiles(out AFiles: TACLStringList): Boolean;
    function GetText(out AString: UnicodeString): Boolean;
    function HasData(AFormat: Word): Boolean;
    function HasFiles: Boolean;
    function HasText: Boolean;

    property Config: TACLIniFile read FConfig;
  published
    property Target: TWinControl read FTarget write SetTarget;
    property Options: TACLDropTargetOptions read FOptions write SetOptions;
    // Events
    property OnDrop: TACLDropTargetDropEvent read FOnDrop write FOnDrop;
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnLeave: TNotifyEvent read FOnLeave write FOnLeave;
    property OnOver: TACLDropTargetOverEvent read FOnOver write FOnOver;
    property OnScroll: TACLDropTargetScrollEvent read FOnScroll write FOnScroll;
  end;

  { TACLDropTargetHelper }

  TACLDropTargetHelper = class
  public
    class function GetVScrollSpeed(const P: TPoint; const AClientRect: TRect): Integer;
  end;

implementation

uses
  ShellAPI, ComObj, Math, SysUtils, Forms;

type

  { TACLDropTargetHook }

  TACLDropTargetHook = class(TInterfacedObject,
    IACLDropTargetHook,
    IDropTarget)
  strict private
    FActiveTarget: IACLDropTarget;
    FControl: TWinControl;
    FControlWndProc: TWndMethod;
    FDataObject: IDataObject;
    FDataSetFormat: TFormatEtc;
    FDataSetMedium: TStgMedium;
    FHintWindow: TACLHintWindow;
    FIsDropping: Boolean;
    FMouseAtTarget: Boolean;

    function CalculateHintPosition: TPoint;
    function GetActionFromEffect(AEffect: Integer): TACLDropAction;
    function GetActiveTarget: IACLDropTarget;
    function GetTarget(const AScreentPoint: TPoint): IACLDropTarget;
    procedure SetActiveTarget(AValue: IACLDropTarget);
  protected
    FTargets: TACLList<IACLDropTarget>;

    procedure HockedWndProc(var AMessage: TMessage);
    procedure RegisterTarget(ARegister: Boolean);
    // Hints
    procedure ShowHint(const AHint: UnicodeString);
    procedure HideHint;
    // IDropTarget
    function DragEnter(const ADataObj: IDataObject; AKeyState: LongInt; P: TPoint; var AEffect: LongInt): HRESULT; stdcall;
    function DragLeave: HRESULT; stdcall;
    function DragOver(AKeyState: LongInt; P: TPoint; var AEffect: LongInt): HRESULT; stdcall;
    function Drop(const ADataObj: IDataObject; AKeyState: LongInt; P: TPoint; var AEffect: LongInt): HRESULT; stdcall;
  public
    constructor Create(AControl: TWinControl); virtual;
    destructor Destroy; override;
    function GetData(AFormat: Word; out AMedium: TStgMedium): Boolean;
    function GetDataAsString(AFormat: Word; out AString: UnicodeString): Boolean;
    function HasData(AFormat: Word): Boolean;
    procedure SendConfig(const AConfig: TACLIniFile);
    //
    property ActiveTarget: IACLDropTarget read FActiveTarget write SetActiveTarget;
    property Control: TWinControl read FControl;
    property DataObject: IDataObject read FDataObject;
    property IsDropping: Boolean read FIsDropping;
    property MouseAtTarget: Boolean read FMouseAtTarget;
  end;

  { TACLDropTargetHookManager }

  TACLDropTargetHookManager = class
  private class var
    FHooks: TDictionary<TWinControl, TACLDropTargetHook>;
  protected
    class procedure DoAdd(AHook: TACLDropTargetHook);
    class procedure DoRemove(AHook: TACLDropTargetHook);
  public
    class function Register(AControl: TWinControl; AHandler: IACLDropTarget): IACLDropTargetHook;
    class procedure Unregister(AHook: IACLDropTargetHook; AHandler: IACLDropTarget);
  end;

{ TACLDropTargetHookManager }

class function TACLDropTargetHookManager.Register(AControl: TWinControl; AHandler: IACLDropTarget): IACLDropTargetHook;
var
  AHookImpl: TACLDropTargetHook;
begin
  if (FHooks = nil) or not FHooks.TryGetValue(AControl, AHookImpl) then
    AHookImpl := TACLDropTargetHook.Create(AControl);
  AHookImpl.FTargets.Add(AHandler);
  Result := AHookImpl;
end;

class procedure TACLDropTargetHookManager.Unregister(AHook: IACLDropTargetHook; AHandler: IACLDropTarget);
var
  AHookImpl: TACLDropTargetHook;
begin
  if AHook <> nil then
  begin
    AHook._AddRef;
    try
      AHookImpl := AHook as TACLDropTargetHook;
      AHookImpl.FTargets.Remove(AHandler);
      if AHookImpl.ActiveTarget = AHandler then
        AHookImpl.ActiveTarget := nil;
    finally
      AHook._Release;
    end;
  end;
end;

class procedure TACLDropTargetHookManager.DoAdd(AHook: TACLDropTargetHook);
begin
  if FHooks = nil then
    FHooks := TDictionary<TWinControl, TACLDropTargetHook>.Create;
  FHooks.Add(AHook.Control, AHook);
end;

class procedure TACLDropTargetHookManager.DoRemove(AHook: TACLDropTargetHook);
begin
  if FHooks <> nil then
  begin
    FHooks.Remove(AHook.Control);
    if FHooks.Count = 0 then
      FreeAndNil(FHooks);
  end;
end;

{ TACLDropTarget }

constructor TACLDropTarget.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOptions := TACLDropTargetOptions.Create;
  FConfig := TACLIniFile.Create;
  FConfig.OnChanged := ConfigChangeHandler;
end;

destructor TACLDropTarget.Destroy;
begin
  FreeAndNil(FOptions);
  FreeAndNil(FConfig);
  inherited Destroy;
end;

procedure TACLDropTarget.BeforeDestruction;
begin
  inherited BeforeDestruction;
  Target := nil;
end;

function TACLDropTarget.GetConfig(out AConfig: TACLIniFile): Boolean;
var
  AMedium: TStgMedium;
begin
  Result := False;
  if GetData(CF_CONFIG, AMedium) then
  try
    if AMedium.tymed = TYMED_HGLOBAL then
    begin
      AConfig := TACLIniFile.Create;
      acConfigFromHGLOBAL(AMedium.hGlobal, AConfig);
      Result := True;
    end;
  finally
    ReleaseStgMedium(AMedium);
  end
end;

function TACLDropTarget.GetData(AFormat: Word; out AMedium: TStgMedium): Boolean;
begin
  Result := (FHook <> nil) and FHook.GetData(AFormat, AMedium) and (AMedium.tymed <> TYMED_NULL);
end;

function TACLDropTarget.GetDataAsString(AFormat: Word; out AString: UnicodeString): Boolean;
begin
  Result := (FHook <> nil) and FHook.GetDataAsString(AFormat, AString);
end;

function TACLDropTarget.GetFiles(out AFiles: TACLStringList): Boolean;
var
  AMedium: TStgMedium;
  AText: UnicodeString;
  I: Integer;
begin
  Result := False;
  if GetData(CF_FILEURIS, AMedium) or GetData(CF_HDROP, AMedium) then
  try
    AFiles := TACLStringList.Create;
    Result := (AMedium.tymed = TYMED_HGLOBAL) and acFilesFromHGLOBAL(AMedium.hGlobal, AFiles);
    if Result then
      ValidateFiles(AFiles)
    else
      FreeAndNil(AFiles);
  finally
    ReleaseStgMedium(AMedium);
  end
  else

  if Options.AllowURLsInFiles and GetText(AText) and acIsUrlFileName(AText) then
  begin
    AFiles := TACLStringList.Create(AText, True);
    for I := AFiles.Count - 1 downto 0 do
    begin
      if not acIsUrlFileName(AFiles[I]) then
        AFiles.Delete(I);
    end;
    Result := True;
  end;
end;

function TACLDropTarget.GetText(out AString: UnicodeString): Boolean;
begin
  Result := GetDataAsString(CF_UNICODETEXT, AString) or GetDataAsString(CF_TEXT, AString);
end;

function TACLDropTarget.HasData(AFormat: Word): Boolean;
begin
  Result := (FHook <> nil) and FHook.HasData(AFormat);
end;

function TACLDropTarget.HasFiles: Boolean;
begin
  Result := HasData(CF_HDROP) or HasData(CF_FILEURIS) or Options.AllowURLsInFiles and HasText;
end;

function TACLDropTarget.HasText: Boolean;
begin
  Result := HasData(CF_UNICODETEXT) or HasData(CF_TEXT);
end;

procedure TACLDropTarget.CheckContentScrolling(const AClientPoint: TPoint);
var
  ASpeed: Integer;
begin
  ASpeed := TACLDropTargetHelper.GetVScrollSpeed(AClientPoint, GetTargetClientRect);
  if ASpeed <> 0 then
    DoScroll(Abs(ASpeed), TACLMouseWheel.GetDirection(ASpeed), AClientPoint);
end;

function TACLDropTarget.GetTargetClientRect: TRect;
begin
  Result := Target.ClientRect;
end;

function TACLDropTarget.ScreenToClient(const P: TPoint): TPoint;
begin
  Result := Target.ScreenToClient(P)
end;

procedure TACLDropTarget.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);
  if AOperation = opRemove then
  begin
    if Target = AComponent then
      Target := nil;
  end;
end;

procedure TACLDropTarget.DoDrop(Shift: TShiftState; const ScreenPoint: TPoint; Action: TACLDropAction);
begin
  if Assigned(OnDrop) then
    OnDrop(Self, Shift, ScreenToClient(ScreenPoint), Action);
end;

procedure TACLDropTarget.DoEnter;
begin
  FTargetIsActive := True;
  CallNotifyEvent(Self, OnEnter);
  SendConfig(Config);
end;

procedure TACLDropTarget.DoLeave;
begin
  FTargetIsActive := False;
  SendConfig(nil);
  CallNotifyEvent(Self, OnLeave);
end;

procedure TACLDropTarget.DoOver(Shift: TShiftState; const ScreenPoint: TPoint;
  var Hint: UnicodeString; var Allow: Boolean; var Action: TACLDropAction);
begin
  CheckContentScrolling(ScreenToClient(ScreenPoint));
  if Assigned(OnOver) then
    OnOver(Self, Shift, ScreenToClient(ScreenPoint), Hint, Allow, Action);
end;

procedure TACLDropTarget.DoScroll(ALines: Integer; ADirection: TACLMouseWheelDirection; const P: TPoint);
var
  AHandled: Boolean;
begin
  AHandled := False;
  if Assigned(OnScroll) then
    OnScroll(Self, P, ALines, ADirection, AHandled);
  if not AHandled then
  begin
    while ALines > 0 do
    begin
      Target.Perform(WM_VSCROLL, TACLMouseWheel.DirectionToScrollCodeI[ADirection], 0);
      Dec(ALines);
    end;
  end;
end;

function TACLDropTarget.IsInTarget(const AScreenPoint: TPoint): Boolean;
begin
  Result := PtInRect(GetTargetClientRect, ScreenToClient(AScreenPoint));
end;

procedure TACLDropTarget.ConfigChangeHandler(Sender: TObject);
begin
  if FTargetIsActive then
    SendConfig(Config);
end;

procedure TACLDropTarget.SendConfig(AConfig: TACLIniFile);
begin
  if FHook <> nil then
    FHook.SendConfig(AConfig);
end;

procedure TACLDropTarget.SetOptions(AValue: TACLDropTargetOptions);
begin
  FOptions.Assign(AValue);
end;

procedure TACLDropTarget.SetTarget(AValue: TWinControl);
begin
  if AValue <> FTarget then
  begin
    if Target <> nil then
    begin
      TACLDropTargetHookManager.Unregister(FHook, Self);
      FTarget.RemoveFreeNotification(Self);
      FTarget := nil;
      FHook := nil;
    end;
    if AValue <> nil then
    begin
      FTarget := AValue;
      FTarget.FreeNotification(Self);
      FHook := TACLDropTargetHookManager.Register(Target, Self);
    end;
  end;
end;

procedure TACLDropTarget.ValidateFiles(AFiles: TACLStringList);
var
  AFileName: UnicodeString;
  I: Integer;
begin
  for I := AFiles.Count - 1 downto 0 do
  begin
    if acIsUrlFileName(AFiles[I]) then
    begin
      if not Options.AllowURLsInFiles then
        AFiles.Delete(I);
    end
    else
      if Options.ExpandShortcuts then
      begin
        if acIsLnkFileName(AFiles[I]) and ShellParseLink(AFiles[I], AFileName) then
          AFiles[I] := AFileName;
      end
      else
        AFiles[I] := acExpandFileName(AFiles[I]);
  end;
end;

{ TACLDropTargetHook }

constructor TACLDropTargetHook.Create(AControl: TWinControl);
begin
  inherited Create;
  FControl := AControl;
  FControlWndProc := FControl.WindowProc;
  FControl.WindowProc := HockedWndProc;
  FTargets := TACLList<IACLDropTarget>.Create;
  TACLDropTargetHookManager.DoAdd(Self);
  RegisterTarget(True);
end;

destructor TACLDropTargetHook.Destroy;
begin
  RegisterTarget(False);
  TACLDropTargetHookManager.DoRemove(Self);
  FControl.WindowProc := FControlWndProc;
  FControl := nil;
  FreeAndNil(FHintWindow);
  FreeAndNil(FTargets);
  inherited Destroy;
end;

function TACLDropTargetHook.GetData(AFormat: Word; out AMedium: TStgMedium): Boolean;
begin
  ZeroMemory(@AMedium, SizeOf(AMedium));
  Result := Succeeded(DataObject.GetData(MakeFormat(AFormat), AMedium));
end;

function TACLDropTargetHook.GetDataAsString(AFormat: Word; out AString: UnicodeString): Boolean;
var
  AMedium: TStgMedium;
begin
  Result := GetData(AFormat, AMedium);
  if Result then
  try
    case AFormat of
      CF_UNICODETEXT:
        AString := acTextFromHGLOBAL(AMedium.hGlobal, True);
      CF_HDROP:
        AString := acFilesFromHGLOBAL(AMedium.hGlobal);
    else
      AString := acTextFromHGLOBAL(AMedium.hGlobal, False);
    end;
  finally
    ReleaseStgMedium(AMedium);
  end;
end;

function TACLDropTargetHook.HasData(AFormat: Word): Boolean;
begin
  Result := Succeeded(DataObject.QueryGetData(MakeFormat(AFormat)));
end;

procedure TACLDropTargetHook.SendConfig(const AConfig: TACLIniFile);
begin
  if DataObject <> nil then
  begin
    FDataSetFormat := MakeFormat(CF_CONFIG);
    FDataSetMedium.tymed := TYMED_HGLOBAL;
    FDataSetMedium.hGlobal := acConfigToHGLOBAL(AConfig);
    DataObject.SetData(FDataSetFormat, FDataSetMedium, True);
  end;
end;

procedure TACLDropTargetHook.HockedWndProc(var AMessage: TMessage);
begin
  FControlWndProc(AMessage);
  case AMessage.Msg of
    WM_CREATE:
      RegisterTarget(True);
    WM_DESTROY:
      RegisterTarget(False);
  end;
end;

procedure TACLDropTargetHook.RegisterTarget(ARegister: Boolean);
begin
  if Assigned(FControl) and FControl.HandleAllocated then
  begin
    if ARegister then
      RegisterDragDrop(FControl.Handle, Self)
    else
      RevokeDragDrop(FControl.Handle);
  end;
end;

procedure TACLDropTargetHook.ShowHint(const AHint: UnicodeString);
begin
  if AHint <> '' then
  begin
    if FHintWindow = nil then
      FHintWindow := TACLHintWindow.Create(nil);
    FHintWindow.ShowFloatHint(AHint, CalculateHintPosition);
  end
  else
    HideHint;
end;

procedure TACLDropTargetHook.HideHint;
begin
  FreeAndNil(FHintWindow);
end;

function TACLDropTargetHook.DragEnter(const ADataObj: IDataObject; AKeyState: Integer; P: TPoint; var AEffect: Integer): HRESULT;
begin
  FDataObject := ADataObj;
  FMouseAtTarget := True;
  Result := S_OK;
end;

function TACLDropTargetHook.DragLeave: HRESULT;
begin
  HideHint;
  FMouseAtTarget := False;
  ActiveTarget := nil;
  FDataObject := nil;
  Result := S_OK;
end;

function TACLDropTargetHook.DragOver(AKeyState: Integer; P: TPoint; var AEffect: Integer): HRESULT;
const
  Map: array[TACLDropAction] of Integer = (DROPEFFECT_COPY, DROPEFFECT_MOVE, DROPEFFECT_LINK);
var
  AAction: TACLDropAction;
  AAllow: Boolean;
  AHint: UnicodeString;
begin
  AHint := '';
  Result := S_OK;
  AAllow := AEffect <> DROPEFFECT_NONE;
  if DataObject <> nil then
  begin
    AAction := GetActionFromEffect(AEffect);
    ActiveTarget := GetTarget(P);
    if ActiveTarget <> nil then
      ActiveTarget.DoOver(KeysToShiftState(AKeyState), P, AHint, AAllow, AAction);
  end;

  AEffect := Map[AAction];
  if not AAllow or (ActiveTarget = nil) then
  begin
    AEffect := DROPEFFECT_NONE;
    AHint := '';
  end;
  ShowHint(AHint);
end;

function TACLDropTargetHook.Drop(const ADataObj: IDataObject; AKeyState: Integer; P: TPoint; var AEffect: Integer): HRESULT;
begin
  Result := S_OK;
  try
    if (DataObject <> nil) and (AEffect <> DROPEFFECT_NONE) then
    begin
      HideHint;
      FIsDropping := True;
      try
        if ActiveTarget <> nil then
          ActiveTarget.DoDrop(KeysToShiftState(AKeyState), P, GetActionFromEffect(AEffect));
      finally
        FIsDropping := False;
      end;
    end;
  finally
    DragLeave;
  end;
end;

function TACLDropTargetHook.CalculateHintPosition: TPoint;
begin
  Result := MouseCursorPos;
  Inc(Result.X, MouseCursorSize.cx);
  Inc(Result.Y, MouseCursorSize.cy);
end;

function TACLDropTargetHook.GetActiveTarget: IACLDropTarget;
begin
  Result := FActiveTarget;
end;

function TACLDropTargetHook.GetActionFromEffect(AEffect: Integer): TACLDropAction;
begin
  case LoWord(AEffect) of
    DROPEFFECT_MOVE:
      Result := daMove;
    DROPEFFECT_LINK:
      Result := daLink;
  else
    Result := daCopy;
  end;
end;

function TACLDropTargetHook.GetTarget(const AScreentPoint: TPoint): IACLDropTarget;
var
  I: Integer;
begin
  for I := FTargets.Count - 1 downto 0 do
  begin
    if FTargets[I].IsInTarget(AScreentPoint) then
      Exit(FTargets[I]);
  end;
  Result := nil;
end;

procedure TACLDropTargetHook.SetActiveTarget(AValue: IACLDropTarget);
begin
  if FActiveTarget <> AValue then
  begin
    if ActiveTarget <> nil then
    begin
      FActiveTarget.DoLeave;
      FActiveTarget := nil;
    end;
    if AValue <> nil then
    begin
      FActiveTarget := AValue;
      FActiveTarget.DoEnter;
    end;
  end;
end;

{ TACLDropTargetHelper }

class function TACLDropTargetHelper.GetVScrollSpeed(const P: TPoint; const AClientRect: TRect): Integer;
const
  ScrollIndent = 16;
  SpeedMap: array[Boolean] of Integer = (1, 4);
begin
  if P.Y < AClientRect.Top + ScrollIndent then
    Result := -SpeedMap[P.Y < AClientRect.Top + ScrollIndent div 2]
  else
    if P.Y > AClientRect.Bottom - ScrollIndent then
      Result := SpeedMap[P.Y > AClientRect.Bottom - ScrollIndent div 2]
    else
      Result := 0;
end;

{ TACLDropTargetOptions }

procedure TACLDropTargetOptions.AfterConstruction;
begin
  inherited;
  FExpandShortcuts := True;
  FAllowURLsInFiles := True;
end;

procedure TACLDropTargetOptions.Assign(Source: TPersistent);
begin
  if Source is TACLDropTargetOptions then
  begin
    ExpandShortcuts := TACLDropTargetOptions(Source).ExpandShortcuts;
    AllowURLsInFiles := TACLDropTargetOptions(Source).AllowURLsInFiles;
  end;
end;

end.
