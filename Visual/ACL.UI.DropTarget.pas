////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Shell drop target
//
//  Author:    Artem Izmaylov
//             © 2006-2024
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
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.UI.Controls.Base,
  ACL.UI.HintWindow,
  ACL.Utils.Clipboard,
  ACL.Utils.Common,
  ACL.Utils.Desktop,
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
    procedure CheckContentScrolling(const AClientPoint: TPoint);
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
    // Utils
    class function GetVScrollSpeed(const P: TPoint; const AClientRect: TRect): Integer;
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

implementation

uses
{$IFDEF LCLGtk2}
  glib2,
  Gdk2,
  Gtk2,
  Gtk2Def,
  Gtk2Int,
  Gtk2Proc,
{$ENDIF}
  {Vcl.}Forms;

type

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
    FTargets: TACLList<IACLDropTarget>;

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

{$IFDEF LCLGtk2}

  { TACLDropTargetHookGtk2 }

  // https://www.manpagez.com/html/gdk2/gdk2-2.24.29/gdk2-Drag-and-Drop.php
  // https://www.manpagez.com/html/gtk2/gtk2-2.24.28/gtk2-Drag-and-Drop.php#gtk-drag-get-data
  // https://gitlab.gnome.org/GNOME/gtk/-/issues/5518
  TACLDropTargetHookGtk2 = class(TACLDropTargetHook)
  strict private
    FContext: PGdkDragContext;
    FData: PGtkSelectionData;
    FWidget: PGtkWidget;
  protected
    FRecursion: Integer;

    function GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean; override;
    function HasData(AFormat: TClipboardFormat): Boolean; override;
    procedure UpdateContext(AWidget: PGtkWidget; AContext: PGdkDragContext; AData: PGtkSelectionData);
    procedure UpdateMimeTypes; override;
    procedure UpdateRegistration(AHandle: TWndHandle; ARegister: Boolean); override;
  end;

{$ENDIF}

{$IFDEF MSWINDOWS}

  { TACLDropTargetHookWin32 }

  TACLDropTargetHookWin32 = class(TACLDropTargetHook, IDropTarget)
  strict private
    FDataObject: IDataObject;
    function GetActionFromEffect(AEffect: Integer): TACLDropAction;
  protected
    // IDropTarget
    function DragEnter(const ADataObj: IDataObject; AKeyState: LongInt;
      P: TPoint; var AEffect: LongInt): HRESULT; stdcall;
    function DragLeave: HRESULT; stdcall;
    function DragOver(AKeyState: LongInt; P: TPoint; var AEffect: LongInt): HRESULT; stdcall;
    function Drop(const ADataObj: IDataObject; AKeyState: LongInt;
      P: TPoint; var AEffect: LongInt): HRESULT; stdcall;
    // IACLDropTargetHook
    function GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean; override;
    function HasData(AFormat: TClipboardFormat): Boolean; override;
    // General
    procedure UpdateRegistration(AHandle: TWndHandle; ARegister: Boolean); override;
    // Properties
    property DataObject: IDataObject read FDataObject;
  end;

{$ENDIF}

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

{ TACLDropTargetHook }

constructor TACLDropTargetHook.Create(AControl: TWinControl);
begin
  FControl := AControl;
  FControlWndProc := FControl.WindowProc;
  FControl.WindowProc := HockedWndProc;
  FTargets := TACLList<IACLDropTarget>.Create;
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
    WM_CREATE:
      Registered := True;
    WM_DESTROY:
      Registered := False;
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

{$IFDEF LCLGtk2}

{ TACLDropTargetHookGtk2 }

function doGtkGetAction(context: PGdkDragContext): TACLDropAction;
begin
  case context^.action of
    GDK_ACTION_LINK:
      Result := daLink;
    GDK_ACTION_MOVE:
      Result := daMove;
  else
    Result := daCopy;
  end;
end;

procedure doGtkDragOver(w: PGtkWidget; context: PGdkDragContext;
  x, y, time: guint; impl: TACLDropTargetHookGtk2); cdecl;
const
  Map: array[TACLDropAction] of TGdkDragAction = (
    GDK_ACTION_COPY, GDK_ACTION_MOVE, GDK_ACTION_LINK
  );
var
  LAllow: Boolean;
  LAction: TACLDropAction;
begin
  Inc(impl.FRecursion);
  try
    LAllow := True;
    LAction := doGtkGetAction(context);
    impl.UpdateContext(w, context, nil);
    impl.DoDragOver(MouseCursorPos, KeyboardStateToShiftState, LAllow, LAction);
    if LAllow then
      gdk_drag_status(context, Map[LAction], time)
    else
      gdk_drag_status(context, 0, time);
  finally
    Dec(impl.FRecursion);
  end;
end;

procedure doGtkDragLeave(w: PGtkWidget; context: PGdkDragContext;
  time: guint; impl: TACLDropTargetHookGtk2); cdecl;
begin
  impl.ActiveTarget := nil;
  impl.UpdateContext(nil, nil, nil);
  impl.HideHint;
end;

procedure doGtkDragDrop(w: PGtkWidget; context: PGdkDragContext; x, y:gint;
  data: PGtkSelectionData; info, time: guint; impl: TACLDropTargetHookGtk2); cdecl;
var
  LAllow: Boolean;
  LAction: TACLDropAction;
  LCursor: TPoint;
  LState: TShiftState;
begin
  impl.UpdateContext(w, context, data);
  // The "data-received" может придти во время обработки "drag-motion"
  if impl.FRecursion = 0 then
  try
    LAllow := True;
    LCursor := MouseCursorPos;
    LAction := doGtkGetAction(context);
    LState := KeyboardStateToShiftState;
    impl.DoDragOver(LCursor, LState, LAllow, LAction);
    impl.HideHint; // before drop, but after over
    if (impl.ActiveTarget <> nil) and LAllow then
      impl.ActiveTarget.DoDrop(LState, LCursor, LAction);
  finally
    doGtkDragLeave(w, context, time, impl);
    gtk_drag_finish(context, LAllow, LAction = daMove, time);
  end;
end;

function TACLDropTargetHookGtk2.GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean;
begin
  Result := (FData <> nil) and (FData^.target = AFormat) and (FData^.length >= 0);
  if Result then
  begin
    AMedium.Data := FData^.data;
    AMedium.Size := FData.length;
    AMedium.Owned := False;
  end;
end;

function TACLDropTargetHookGtk2.HasData(AFormat: TClipboardFormat): Boolean;
begin
  // Запрос во время drag-motion не работает...
  //if (FData = nil) and (FWidget <> nil) and (FContext <> nil) then
  //  gtk_drag_get_data(FWidget, FContext, AFormat, GDK_CURRENT_TIME);
  if FRecursion > 0{drag-motion?} then
    Exit(True); // на дропе разберемся...
  Result := (FData <> nil) and (FData^.target = AFormat);
end;

procedure TACLDropTargetHookGtk2.UpdateContext(
  AWidget: PGtkWidget; AContext: PGdkDragContext; AData: PGtkSelectionData);
begin
  FData := AData;
  FContext := AContext;
  FWidget := AWidget;
end;

procedure TACLDropTargetHookGtk2.UpdateMimeTypes;
begin
  Registered := False;
  Registered := True;
end;

procedure TACLDropTargetHookGtk2.UpdateRegistration(AHandle: TWndHandle; ARegister: Boolean);
var
  I: Integer;
  LFormats: array of TGtkTargetEntry;
  LMimeTypes: TACLStringList;
  LWidget: PGtkWidget;
begin
  LWidget := PGtkWidget(AHandle);
  if ARegister then
  begin
    LMimeTypes := TACLStringList.Create;
    try
      LMimeTypes.Add(acMimeConfig);
      LMimeTypes.Add(acMimeInternalFileList);
      LMimeTypes.Add(acMimeLinuxFileList);
      for I := 0 to FTargets.Count - 1 do
        LMimeTypes.Append(FTargets.List[I].GetMimeTypes);
      LMimeTypes.RemoveDuplicates;

      SetLength(LFormats{%H-}, LMimeTypes.Count);
      for I := 0 to LMimeTypes.Count - 1 do
      begin
        LFormats[I].target := PChar(LMimeTypes.Strings[I]);
        LFormats[I].flags := 0;
        LFormats[I].info := 0;
      end;

      gtk_drag_dest_set(LWidget, GTK_DEST_DEFAULT_ALL,
        @LFormats[0], Length(LFormats), GDK_ACTION_COPY or GDK_ACTION_MOVE);
      gtk_drag_dest_add_text_targets(LWidget);

      ConnectSignal(PGtkObject(LWidget), 'drag_data_received', @doGtkDragDrop, Self);
      ConnectSignal(PGtkObject(LWidget), 'drag_motion', @doGtkDragOver, Self);
      ConnectSignal(PGtkObject(LWidget), 'drag_leave', @doGtkDragLeave, Self);
    finally
      LMimeTypes.Free;
    end;
  end
  else
    gtk_drag_dest_unset(LWidget);
end;

{$ENDIF}

{$IFDEF MSWINDOWS}
{ TACLDropTargetHookWin32 }

function TACLDropTargetHookWin32.DragEnter(const ADataObj: IDataObject;
  AKeyState: Integer; P: TPoint; var AEffect: Integer): HRESULT;
begin
  FDataObject := ADataObj;
  Result := S_OK;
end;

function TACLDropTargetHookWin32.DragLeave: HRESULT;
begin
  HideHint;
  ActiveTarget := nil;
  FDataObject := nil;
  Result := S_OK;
end;

function TACLDropTargetHookWin32.DragOver(AKeyState: Integer; P: TPoint; var AEffect: Integer): HRESULT;
const
  Map: array[TACLDropAction] of Integer = (DROPEFFECT_COPY, DROPEFFECT_MOVE, DROPEFFECT_LINK);
var
  LAction: TACLDropAction;
  LAllow: Boolean;
begin
  LAllow := AEffect <> DROPEFFECT_NONE;
  LAction := GetActionFromEffect(AEffect);
  DoDragOver(P, KeysToShiftState(AKeyState), LAllow, LAction);
  AEffect := IfThen(LAllow, Map[LAction], DROPEFFECT_NONE);
  Result := S_OK;
end;

function TACLDropTargetHookWin32.Drop(const ADataObj: IDataObject;
  AKeyState: Integer; P: TPoint; var AEffect: Integer): HRESULT;
begin
  Result := S_OK;
  try
    if (DataObject <> nil) and (AEffect <> DROPEFFECT_NONE) then
    begin
      HideHint;
      if ActiveTarget <> nil then
        ActiveTarget.DoDrop(KeysToShiftState(AKeyState), P, GetActionFromEffect(AEffect));
    end;
  finally
    DragLeave;
  end;
end;

function TACLDropTargetHookWin32.GetActionFromEffect(AEffect: Integer): TACLDropAction;
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

function TACLDropTargetHookWin32.GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean;
begin
  ZeroMemory(@AMedium, SizeOf(AMedium));
  Result := (DataObject <> nil) and
    Succeeded(DataObject.GetData(MakeFormat(AFormat), AMedium)) and
    (AMedium.tymed <> TYMED_NULL);
end;

function TACLDropTargetHookWin32.HasData(AFormat: TClipboardFormat): Boolean;
begin
  Result := Succeeded(DataObject.QueryGetData(MakeFormat(AFormat)));
end;

procedure TACLDropTargetHookWin32.UpdateRegistration(AHandle: TWndHandle; ARegister: Boolean);
begin
  if ARegister then
    RegisterDragDrop(AHandle, Self)
  else
    RevokeDragDrop(AHandle);
end;
{$ENDIF}

{ TACLDropTargetHookManager }

class function TACLDropTargetHookManager.Register(
  AControl: TWinControl; AHandler: IACLDropTarget): IACLDropTargetHook;
var
  LImpl: TACLDropTargetHook;
begin
  if (FHooks = nil) or not FHooks.TryGetValue(AControl, LImpl) then
  {$IFDEF LCLGtk2}
    LImpl := TACLDropTargetHookGtk2.Create(AControl);
  {$ELSE}
    LImpl := TACLDropTargetHookWin32.Create(AControl);
  {$ENDIF}
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

procedure TACLDropTarget.CheckContentScrolling(const AClientPoint: TPoint);
var
  ASpeed: Integer;
begin
  ASpeed := GetVScrollSpeed(AClientPoint, GetTargetClientRect);
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
  Result := GetTargetClientRect.Contains(ScreenToClient(AScreenPoint));
end;

function TACLDropTarget.GetMimeTypes: TStrings;
begin
  Result := Options.MimeTypes;
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
        if acIsLnkFileName(AFiles[I]) and ShellParseLink(AFiles[I], LFileName) then
          AFiles[I] := LFileName;
      end
      else
        AFiles[I] := acExpandFileName(AFiles[I]);
  end;
end;

class function TACLDropTarget.GetVScrollSpeed(const P: TPoint; const AClientRect: TRect): Integer;
const
  ScrollIndent = 16;
  SpeedMap: array[Boolean] of Integer = (1, 4);
begin
  if P.Y < AClientRect.Top + ScrollIndent then
    Exit(-SpeedMap[P.Y < AClientRect.Top + ScrollIndent div 2]);
  if P.Y > AClientRect.Bottom - ScrollIndent then
    Exit(SpeedMap[P.Y > AClientRect.Bottom - ScrollIndent div 2]);
  Result := 0;
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

end.
