////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Shell Drop Target
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.DropTarget;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLType,
{$ELSE}
  {Winapi.}ActiveX,
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Clipbrd,
  {Vcl.}Forms,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.Threading,
  ACL.UI.Controls.Base,
  ACL.UI.HintWindow,
  ACL.Utils.Clipboard,
  ACL.Utils.Common,
  ACL.Utils.Desktop,
  ACL.Utils.DPIAware,
  ACL.Utils.FileSystem,
  ACL.Utils.Shell,
  ACL.Utils.Stream,
  ACL.Utils.Strings;

type
  TACLDropTarget = class;

  TACLDropAction = (daCopy, daMove, daLink);

  TACLDropTargetDropEvent = procedure (Sender: TACLDropTarget;
    Shift: TShiftState; P: TPoint; Action: TACLDropAction) of object;
  TACLDropTargetOverEvent = procedure (Sender: TACLDropTarget;
    Shift: TShiftState; P: TPoint; var Hint: string; var Allow: Boolean;
    var Action: TACLDropAction) of object;
  TACLDropTargetScrollEvent = procedure (Sender: TObject; P: TPoint;
    Lines: Integer; Direction: TACLMouseWheelDirection; var AHandled: Boolean) of object;

  { IACLDropTarget }

  IACLDropTarget = interface
  ['{B57F63C7-8228-45FC-80DB-065E5FFC8F3A}']
    procedure DoDrop(Shift: TShiftState; const ScreenPoint: TPoint; Action: TACLDropAction);
    procedure DoEnter;
    procedure DoLeave;
    procedure DoOver(Shift: TShiftState; const ScreenPoint: TPoint;
      var Hint: string; var Allow: Boolean; var Action: TACLDropAction);
    function IsInTarget(const ScreenPoint: TPoint): Boolean;
    function GetMimeTypes: TStrings;
  end;

  { IACLDropTargetHook }

  IACLDropTargetHook = interface
  ['{D0B4CD71-C793-468C-895E-0DAC648D8AD6}']
    function GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean;
    function HasData(AFormat: TClipboardFormat): Boolean;
    procedure UpdateMimeTypes;
  end;

  { TACLDropTargetOptions }

  TACLDropTargetOptions = class(TPersistent)
  strict private
    FAllowURLsInFiles: Boolean;
    FExpandShortcuts: Boolean;
    FMimeTypes: TStrings;
    procedure SetMimeTypes(AValue: TStrings);
  public
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure Assign(Source: TPersistent); override;
  published
    property AllowURLsInFiles: Boolean read FAllowURLsInFiles write FAllowURLsInFiles default True;
    property ExpandShortcuts: Boolean read FExpandShortcuts write FExpandShortcuts default True;
    property MimeTypes: TStrings read FMimeTypes write SetMimeTypes; // for Linux only
  end;

  { TACLDropTarget }

  TACLDropTarget = class(TComponent, IACLDropTarget)
  strict private
    FHook: IACLDropTargetHook;
    FOptions: TACLDropTargetOptions;
    FScrollTimestamp: Cardinal;
    FTarget: TWinControl;
    FTargetIsActive: Boolean;

    FOnDrop: TACLDropTargetDropEvent;
    FOnEnter: TNotifyEvent;
    FOnLeave: TNotifyEvent;
    FOnOver: TACLDropTargetOverEvent;
    FOnScroll: TACLDropTargetScrollEvent;

    procedure SetOptions(AValue: TACLDropTargetOptions);
    procedure SetTarget(AValue: TWinControl);
    procedure ValidateFiles(AFiles: TACLStringList);
  protected
    procedure CheckContentScrolling(const P: TPoint);
    function GetTargetClientRect: TRect; virtual;
    function ScreenToClient(const P: TPoint): TPoint; virtual;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;

    // IACLDropTarget
    procedure DoEnter; virtual;
    procedure DoLeave; virtual;
    procedure DoOver(Shift: TShiftState; const ScreenPoint: TPoint;
      var Hint: string; var Allow: Boolean; var Action: TACLDropAction); virtual;
    procedure DoDrop(Shift: TShiftState; const ScreenPoint: TPoint; Action: TACLDropAction); virtual;
    procedure DoScroll(ALines: Integer; ADirection: TACLMouseWheelDirection; const P: TPoint); virtual;
    function IsInTarget(const AScreenPoint: TPoint): Boolean; virtual;
    function GetMimeTypes: TStrings;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    // Data
    function GetConfig(out AConfig: TACLIniFile): Boolean;
    function GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean;
    function GetDataAsString(AFormat: TClipboardFormat; out AString: string): Boolean;
    function GetFiles(out AFiles: TACLStringList): Boolean;
    function GetText(out AString: string): Boolean;
    function HasData(AFormat: TClipboardFormat): Boolean;
    function HasFiles: Boolean;
    function HasText: Boolean;
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

  { TACLDropTargetHook }

  TACLDropTargetHook = class(TInterfacedObject, IACLDropTargetHook)
  strict private
    FActiveTarget: IACLDropTarget;
    FControl: TWinControl;
    FControlWndProc: TWndMethod;
    FHintWindow: TACLHintWindow;
    FRegistered: Boolean;

    function GetTarget(const AScreentPoint: TPoint): IACLDropTarget;
    procedure SetActiveTarget(AValue: IACLDropTarget);
    procedure SetRegistered(AValue: Boolean);
  protected
    FTargets: TACLListOf<IACLDropTarget>;

    procedure HockedWndProc(var AMessage: TMessage); virtual;
    // Actions
    procedure DoDragOver(const AScreenPoint: TPoint; AShift: TShiftState;
      var AAllow: Boolean; var AAction: TACLDropAction);
    // Hints
    procedure ShowHint(const AHint: string);
    procedure HideHint;
    // IACLDropTargetHook
    function GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean; virtual; abstract;
    function HasData(AFormat: TClipboardFormat): Boolean; virtual; abstract;
    procedure UpdateMimeTypes; virtual;
    procedure UpdateRegistration(AHandle: TWndHandle; ARegister: Boolean); virtual; abstract;
  public
    constructor Create(AControl: TWinControl);
    destructor Destroy; override;
    // Properties
    property ActiveTarget: IACLDropTarget read FActiveTarget write SetActiveTarget;
    property Control: TWinControl read FControl;
    property Registered: Boolean read FRegistered write SetRegistered;
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

implementation

{$IF DEFINED(MSWINDOWS)}
  {$I ACL.UI.DropTarget.Win32.inc}
{$ELSEIF DEFINED(LCLGtk3)}
  {$I ACL.UI.DropTarget.Gtk3.inc}
{$ELSEIF DEFINED(LCLGtk2)}
  {$I ACL.UI.DropTarget.Gtk2.inc}
{$ENDIF}

{ TACLDropTarget }

constructor TACLDropTarget.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOptions := TACLDropTargetOptions.Create;
end;

destructor TACLDropTarget.Destroy;
begin
  FreeAndNil(FOptions);
  inherited Destroy;
end;

procedure TACLDropTarget.BeforeDestruction;
begin
  inherited BeforeDestruction;
  Target := nil;
end;

procedure TACLDropTarget.CheckContentScrolling(const P: TPoint);
var
  LDirection: TAlign;
  LInterval: Integer;
begin
  LDirection := acCalculateAutoScroll(P, GetTargetClientRect, acGetCurrentDpi(Target), LInterval);
  if not (LDirection in [alTop, alBottom]) then
    Exit;
  if TACLThread.IsTimeoutEx(FScrollTimestamp, LInterval) then
  begin
    if LDirection = alTop then
      DoScroll(1, mwdUp, P)
    else
      DoScroll(1, mwdDown, P);
  end;
end;

function TACLDropTarget.GetConfig(out AConfig: TACLIniFile): Boolean;
var
  LMedium: TStgMedium;
  LStream: TCustomMemoryStream;
begin
  Result := False;
  if GetData(CF_CONFIG, LMedium) then
  try
    if MediumGetStream(LMedium, LStream) then
    try
      AConfig := TACLIniFile.Create;
      AConfig.LoadFromStream(LStream);
      Result := True;
    finally
      LStream.Free;
    end;
  finally
    ReleaseStgMedium(LMedium);
  end
end;

function TACLDropTarget.GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean;
begin
  Result := (FHook <> nil) and FHook.GetData(AFormat, AMedium);
end;

function TACLDropTarget.GetDataAsString(AFormat: TClipboardFormat; out AString: string): Boolean;
var
  LMedium: TStgMedium;
begin
  Result := GetData(AFormat, LMedium);
  if Result then
  try
    AString := MediumGetString(LMedium, AFormat);
  finally
    ReleaseStgMedium(LMedium);
  end;
end;

function TACLDropTarget.GetFiles(out AFiles: TACLStringList): Boolean;
var
  LMedium: TStgMedium;
  LStream: TCustomMemoryStream;
  LText: string;
  I: Integer;
begin
  Result := False;
  if GetData(CF_FILEURIS, LMedium) or GetData(CF_HDROP, LMedium) then
  try
    Result := MediumGetFiles(LMedium, AFiles);
    if Result then
      ValidateFiles(AFiles);
  finally
    ReleaseStgMedium(LMedium);
  end
  else

{$IFDEF MSWINDOWS}
  if GetData(CF_SHELLIDList, LMedium) then
  try
    if MediumGetStream(LMedium, LStream) then
    try
      Result := TPIDLHelper.ShellListStreamToFiles(LStream, AFiles);
      if Result then
        ValidateFiles(AFiles);
    finally
      LStream.Free;
    end;
  finally
    ReleaseStgMedium(LMedium)
  end
  else
{$ENDIF}

  if Options.AllowURLsInFiles and GetText(LText) and acIsUrlFileName(LText) then
  begin
    AFiles := TACLStringList.Create(LText, True);
    for I := AFiles.Count - 1 downto 0 do
    begin
      if not acIsUrlFileName(AFiles[I]) then
        AFiles.Delete(I);
    end;
    Result := True;
  end;
end;

function TACLDropTarget.GetText(out AString: string): Boolean;
begin
  Result :=
  {$IFDEF MSWINDOWS}
    GetDataAsString(CF_UNICODETEXT, AString) or
  {$ENDIF}
    GetDataAsString(CF_TEXT, AString);
end;

function TACLDropTarget.GetTargetClientRect: TRect;
begin
  Result := Target.ClientRect;
end;

function TACLDropTarget.HasData(AFormat: TClipboardFormat): Boolean;
begin
  Result := (FHook <> nil) and FHook.HasData(AFormat);
end;

function TACLDropTarget.HasFiles: Boolean;
begin
  Result := HasData(CF_HDROP) or HasData(CF_FILEURIS) or
    Options.AllowURLsInFiles and HasText;
end;

function TACLDropTarget.HasText: Boolean;
begin
  Result :=
  {$IFDEF MSWINDOWS}
    HasData(CF_UNICODETEXT) or
  {$ENDIF}
    HasData(CF_TEXT);
end;

procedure TACLDropTarget.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);
  if (AOperation = opRemove) and (Target = AComponent) then
    Target := nil;
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
end;

procedure TACLDropTarget.DoLeave;
begin
  FTargetIsActive := False;
  CallNotifyEvent(Self, OnLeave);
end;

procedure TACLDropTarget.DoOver(Shift: TShiftState; const ScreenPoint: TPoint;
  var Hint: string; var Allow: Boolean; var Action: TACLDropAction);
begin
  CheckContentScrolling(ScreenToClient(ScreenPoint));
  if Assigned(OnOver) then
    OnOver(Self, Shift, ScreenToClient(ScreenPoint), Hint, Allow, Action);
end;

procedure TACLDropTarget.DoScroll(ALines: Integer; ADirection: TACLMouseWheelDirection; const P: TPoint);
var
  LHandled: Boolean;
begin
  LHandled := False;
  if Assigned(OnScroll) then
    OnScroll(Self, P, ALines, ADirection, LHandled);
  if not LHandled then
    while ALines > 0 do
    begin
      Target.Perform(WM_VSCROLL, TACLMouseWheel.DirectionToScrollCodeI[ADirection], 0);
      Dec(ALines);
    end;
end;

function TACLDropTarget.IsInTarget(const AScreenPoint: TPoint): Boolean;
begin
  Result := GetTargetClientRect.Contains(ScreenToClient(AScreenPoint));
end;

function TACLDropTarget.GetMimeTypes: TStrings;
begin
  Result := Options.MimeTypes;
end;

function TACLDropTarget.ScreenToClient(const P: TPoint): TPoint;
begin
  Result := Target.ScreenToClient(P)
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
  LFileName: string;
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
        if ShellShortcutResolve(AFiles[I], LFileName) then
          AFiles[I] := LFileName;
      end
      else
        AFiles[I] := acExpandFileName(AFiles[I]);
  end;
end;

{ TACLDropTargetOptions }

destructor TACLDropTargetOptions.Destroy;
begin
  FreeAndNil(FMimeTypes);
  inherited Destroy;
end;

procedure TACLDropTargetOptions.AfterConstruction;
begin
  inherited;
  FMimeTypes := TStringList.Create;
  FAllowURLsInFiles := True;
  FExpandShortcuts := True;
end;

procedure TACLDropTargetOptions.Assign(Source: TPersistent);
begin
  if Source is TACLDropTargetOptions then
  begin
    AllowURLsInFiles := TACLDropTargetOptions(Source).AllowURLsInFiles;
    ExpandShortcuts := TACLDropTargetOptions(Source).ExpandShortcuts;
    MimeTypes := TACLDropTargetOptions(Source).MimeTypes;
  end;
end;

procedure TACLDropTargetOptions.SetMimeTypes(AValue: TStrings);
begin
  FMimeTypes.Assign(AValue);
end;

{ TACLDropTargetHook }

constructor TACLDropTargetHook.Create(AControl: TWinControl);
begin
  FControl := AControl;
  FControlWndProc := FControl.WindowProc;
  FControl.WindowProc := HockedWndProc;
  FTargets := TACLListOf<IACLDropTarget>.Create;
  TACLDropTargetHookManager.DoAdd(Self);
end;

destructor TACLDropTargetHook.Destroy;
begin
  Registered := False;
  TACLDropTargetHookManager.DoRemove(Self);
  FControl.WindowProc := FControlWndProc;
  FControl := nil;
  FreeAndNil(FHintWindow);
  FreeAndNil(FTargets);
  inherited Destroy;
end;

procedure TACLDropTargetHook.DoDragOver(const AScreenPoint: TPoint;
  AShift: TShiftState; var AAllow: Boolean; var AAction: TACLDropAction);
var
  LHint: string;
begin
  LHint := '';
  ActiveTarget := GetTarget(AScreenPoint);
  if ActiveTarget <> nil then
    ActiveTarget.DoOver(AShift, AScreenPoint, LHint, AAllow, AAction);
  if not AAllow or (ActiveTarget = nil) then
  begin
    AAllow := False;
    LHint := '';
  end;
  ShowHint(LHint);
end;

procedure TACLDropTargetHook.HockedWndProc(var AMessage: TMessage);
begin
  FControlWndProc(AMessage);
  case AMessage.Msg of
    WM_DESTROY:
      Registered := False;
    WM_CREATE:
    begin
      Registered := False;
      Registered := True;
    end;
  end;
end;

procedure TACLDropTargetHook.HideHint;
begin
  FreeAndNil(FHintWindow);
end;

procedure TACLDropTargetHook.ShowHint(const AHint: string);
var
  LPos: TPoint;
begin
  if AHint <> '' then
  begin
    if FHintWindow = nil then
      FHintWindow := TACLHintWindow.Create(nil);

    LPos := MouseCursorPos;
    Inc(LPos.X, MouseCursorSize.cx);
    Inc(LPos.Y, MouseCursorSize.cy);
    FHintWindow.ShowFloatHint(AHint, LPos);
  end
  else
    HideHint;
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

procedure TACLDropTargetHook.SetRegistered(AValue: Boolean);
begin
  if FRegistered <> AValue then
  begin
    if (Control <> nil) and Control.HandleAllocated then
    begin
      FRegistered := AValue; // first
      UpdateRegistration(FControl.Handle, AValue);
    end
    else
      FRegistered := False;
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

procedure TACLDropTargetHook.UpdateMimeTypes;
begin
  // do nothing
end;

{ TACLDropTargetHookManager }

class function TACLDropTargetHookManager.Register(
  AControl: TWinControl; AHandler: IACLDropTarget): IACLDropTargetHook;
var
  LImpl: TACLDropTargetHook;
begin
  if (FHooks = nil) or not FHooks.TryGetValue(AControl, LImpl) then
    LImpl := TACLDropTargetHookImpl.Create(AControl);
  LImpl.FTargets.Add(AHandler);
  LImpl.Registered := True;
  Result := LImpl;
end;

class procedure TACLDropTargetHookManager.Unregister(
  AHook: IACLDropTargetHook; AHandler: IACLDropTarget);
var
  LImpl: TACLDropTargetHook;
begin
  if AHook <> nil then
  begin
    AHook._AddRef;
    try
      LImpl := AHook as TACLDropTargetHook;
      LImpl.FTargets.Remove(AHandler);
      if LImpl.ActiveTarget = AHandler then
        LImpl.ActiveTarget := nil;
//TODO: unsafe for WndProc hooks
//      if LImpl.FTargets.Count = 0 then
//        LImpl.Registered := False;
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

end.
