{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*          Compoud Control Classes          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.CompoundControl.SubClass;

{$I ACL.Config.inc}
{$R ACL.UI.Controls.CompoundControl.SubClass.res}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ActiveX,
  // System
  System.SysUtils,
  System.Types,
  System.Classes,
  System.Generics.Collections,
  System.Math,
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  Vcl.StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Graphics,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.DropSource,
  ACL.UI.DropTarget,
  ACL.UI.Forms,
  ACL.UI.HintWindow,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Desktop;

const
  // CompoundControl Changes Notifications
  cccnContent      = 0;
  cccnViewport     = 1;
  cccnLayout       = 2;
  cccnStruct       = 3;
  cccnLast = cccnStruct;

  // HitTests Flags
  cchtCheckable = 1;
  cchtExpandable = cchtCheckable + 1;
  cchtResizable = cchtExpandable + 1;
  cchtScrollBarArea = cchtResizable + 1;

  cchtLast = cchtScrollBarArea + 1;

type
  TACLCompoundControlSubClass = class;
  TACLCompoundControlSubClassDragAndDropController = class;
  TACLCompoundControlSubClassDragObject = class;
  TACLCompoundControlActionType = (ccatNone, ccatMouse, ccatGesture, ccatKeyboard);

  TACLHitTestInfo = class;

  { IACLCheckableObject }

  IACLCheckableObject = interface
  ['{E86E50AD-E78A-48B2-BD46-63AB8D6E44BF}']
    function CanCheck: Boolean;
    function GetChecked: Boolean;
    procedure SetChecked(AValue: Boolean);
    //
    property Checked: Boolean read GetChecked write SetChecked;
  end;

  { IACLClickableObject }

  IACLClickableObject = interface
  ['{DAB9B73E-7CD1-41E4-9A7C-B8B4696D826E}']
    procedure Click(const AHitTestInfo: TACLHitTestInfo);
  end;

  { IACLDraggableObject }

  IACLDraggableObject = interface
  ['{28191AE3-6829-4275-885A-5988D73732C5}']
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
  end;

  { IACLExpandableObject }

  IACLExpandableObject = interface
  ['{EEDEF796-90C3-4162-B78F-A85CE7452DF1}']
    function CanToggle: Boolean;
    function GetExpanded: Boolean;
    procedure SetExpanded(AValue: Boolean);
    //
    property Expanded: Boolean read GetExpanded write SetExpanded;
  end;

  { IACLHotTrackObject }

  IACLHotTrackObject = interface
  ['{CED931C7-5375-4A8B-A1D1-3D127F8DA46F}']
    procedure Enter;
    procedure Leave;
  end;

  { IACLPressableObject }

  IACLPressableObject = interface
  ['{CA46A988-A0D7-4DB0-982A-D0F48F7CEFC4}']
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
  end;

  { IACLSelectableObject }

  IACLSelectableObject = interface
  ['{BE88934C-23DB-4747-A804-54F883394E45}']
    function GetSelected: Boolean;
    procedure SetSelected(AValue: Boolean);
    //
    property Selected: Boolean read GetSelected write SetSelected;
  end;

  { IACLCompoundControlSubClassContainer }

  IACLCompoundControlSubClassContainer = interface(IACLControl)
  ['{3A39F1D5-E2FA-4DAC-98C7-067C97DDF79E}']
    function CanFocus: Boolean;
    function GetControl: TWinControl;
    function GetEnabled: Boolean;
    function GetFocused: Boolean;
    function GetFont: TFont;
    function GetMouseCapture: Boolean;
    procedure SetFocus;
    procedure SetMouseCapture(const AValue: Boolean);
    //
    function ClientToScreen(const P: TPoint): TPoint;
    function ScreenToClient(const P: TPoint): TPoint;
    procedure UpdateCursor;
  end;

  { TACLHitTestInfo }

  TACLHitTestInfo = class
  strict private
    FCursor: TCursor;
    FHitObject: TObject;
    FHitObjectData: TDictionary<string, TObject>;
    FHitObjectFlags: TACLList<Integer>;
    FHitPoint: TPoint;

    function GetHitObjectData(const Index: string): TObject;
    procedure SetHitObjectData(const Index: string; const Value: TObject);
  protected
    function GetHitObjectFlag(Index: Integer): Boolean;
    procedure SetHitObjectFlag(Index: Integer; const Value: Boolean);
  public
    HintData: TACLHintData;

    destructor Destroy; override;
    procedure AfterConstruction; override;
    function CreateDragObject: TACLCompoundControlSubClassDragObject; virtual;
    procedure Reset; virtual;

    property Cursor: TCursor read FCursor write FCursor;
    property HitObject: TObject read FHitObject write FHitObject;
    property HitObjectData[const Index: string]: TObject read GetHitObjectData write SetHitObjectData;
    property HitObjectFlags[Index: Integer]: Boolean read GetHitObjectFlag write SetHitObjectFlag;
    property HitPoint: TPoint read FHitPoint write FHitPoint;

    property IsCheckable: Boolean index cchtCheckable read GetHitObjectFlag write SetHitObjectFlag;
    property IsExpandable: Boolean index cchtExpandable read GetHitObjectFlag write SetHitObjectFlag;
    property IsResizable: Boolean index cchtResizable read GetHitObjectFlag write SetHitObjectFlag;
    property IsScrollBarArea: Boolean index cchtScrollBarArea read GetHitObjectFlag write SetHitObjectFlag;
  end;

  { TACLCompoundControlSubClassPersistent }

  TACLCompoundControlSubClassPersistent = class(TACLUnknownObject)
  strict private
    FSubClass: TACLCompoundControlSubClass;

    function GetScaleFactor: TACLScaleFactor;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass); virtual;
    //
    property ScaleFactor: TACLScaleFactor read GetScaleFactor;
    property SubClass: TACLCompoundControlSubClass read FSubClass;
  end;

  { TACLCompoundControlSubClassCustomViewInfo }

  TACLCompoundControlSubClassCustomViewInfo = class(TACLCompoundControlSubClassPersistent)
  protected
    FBounds: TRect;

    procedure DoCalculate(AChanges: TIntegerSet); virtual;
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); virtual;
    procedure DoDraw(ACanvas: TCanvas); virtual;
  public
    // Calculating
    procedure Calculate(const R: TRect; AChanges: TIntegerSet); virtual;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; virtual;
    // Drawing
    procedure Draw(ACanvas: TCanvas);
    procedure DrawTo(ACanvas: TCanvas; X, Y: Integer);
    procedure Invalidate;
    //
    property Bounds: TRect read FBounds;
  end;

  { TACLCompoundControlSubClassContainerViewInfo }

  TACLCompoundControlSubClassContainerViewInfo = class(TACLCompoundControlSubClassCustomViewInfo)
  strict private
    function GetChild(Index: Integer): TACLCompoundControlSubClassCustomViewInfo; inline;
    function GetChildCount: Integer; inline;
  protected
    FChildren: TACLObjectList;

    procedure AddCell(ACell: TACLCompoundControlSubClassCustomViewInfo; var AObj);
    procedure CalculateSubCells(const AChanges: TIntegerSet); virtual;
    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure DoDrawCells(ACanvas: TCanvas); virtual;
    procedure RecreateSubCells; virtual; abstract;
  public
    constructor Create(AOwner: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    //
    property ChildCount: Integer read GetChildCount;
    property Children[Index: Integer]: TACLCompoundControlSubClassCustomViewInfo read GetChild;
  end;

  { TACLCompoundControlSubClassDragWindow }

  TACLCompoundControlSubClassDragWindow = class(TACLForm)
  strict private
    FBitmap: TBitmap;
    FControl: TWinControl;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TWinControl); reintroduce;
    destructor Destroy; override;
    procedure SetBitmap(ABitmap: TBitmap; AMaskByBitmap: Boolean);
    procedure SetVisible(AValue: Boolean);
  end;

  { TACLCompoundControlSubClassDragObject }

  TACLCompoundControlSubClassDragObject = class(TACLUnknownObject)
  strict private
    FDragTargetScreenBounds: TRect;
    FDragTargetZoneWindow: TACLCompoundControlSubClassDragWindow;
    FDragWindow: TACLCompoundControlSubClassDragWindow;

    function GetCursor: TCursor;
    function GetHitTest: TACLHitTestInfo;
    function GetMouseCapturePoint: TPoint;
    function GetScaleFactor: TACLScaleFactor;
    function GetSubClass: TACLCompoundControlSubClass;
    procedure SetCursor(const Value: TCursor);
  protected
    FController: TACLCompoundControlSubClassDragAndDropController;

    procedure CreateAutoScrollTimer;
    procedure InitializeDragWindow(ASourceViewInfo: TACLCompoundControlSubClassCustomViewInfo);
    procedure StartDropSource(AActions: TACLDropSourceActions; ASource: IACLDropSourceOperation; ASourceObject: TObject); virtual;
    procedure UpdateAutoScrollDirection(ADelta: Integer); overload;
    procedure UpdateAutoScrollDirection(const P: TPoint; const AArea: TRect); overload;
    procedure UpdateDragTargetZoneWindow(const ATargetScreenBounds: TRect; AVertical: Boolean);
    procedure UpdateDropTarget(ADropTarget: TACLDropTarget);
  public
    destructor Destroy; override;
    procedure DragFinished(ACanceled: Boolean); virtual;
    procedure DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer); virtual; abstract;
    function DragStart: Boolean; virtual; abstract;
    procedure Draw(ACanvas: TCanvas); virtual;
    function TransformPoint(const P: TPoint): TPoint; virtual;
    //
    property Cursor: TCursor read GetCursor write SetCursor;
    property DragTargetScreenBounds: TRect read FDragTargetScreenBounds;
    property DragTargetZoneWindow: TACLCompoundControlSubClassDragWindow read FDragTargetZoneWindow;
    property DragWindow: TACLCompoundControlSubClassDragWindow read FDragWindow;
    property HitTest: TACLHitTestInfo read GetHitTest;
    property MouseCapturePoint: TPoint read GetMouseCapturePoint;
    property ScaleFactor: TACLScaleFactor read GetScaleFactor;
    property SubClass: TACLCompoundControlSubClass read GetSubClass;
  end;

  { TACLCompoundControlSubClassDragAndDropController }

  TACLCompoundControlSubClassDragAndDropController = class(TACLCompoundControlSubClassPersistent,
    IACLObjectLinksSupport,
    IACLDropSourceOperation)
  strict private
    FAutoScrollTimer: TACLTimer;
    FDragObject: TACLCompoundControlSubClassDragObject;
    FDropSourceConfig: TACLIniFile;
    FDropSourceObject: TObject;
    FDropSourceOperation: IACLDropSourceOperation;
    FDropTarget: TACLDropTarget;
    FIsActive: Boolean;
    FIsDropping: Boolean;
    FLastPoint: TPoint;
    FMouseCapturePoint: TPoint;
    FStarted: Boolean; // for Escape handler

    function GetHitTest: TACLHitTestInfo; inline;
    function GetIsDropSourceOperation: Boolean;
    procedure Finish(ACanceled: Boolean);
    procedure SetCursor(AValue: TCursor);
  protected
    FCursor: TCursor;

    procedure AutoScrollTimerHandler(Sender: TObject); virtual;
    procedure CreateAutoScrollTimer; virtual;
    procedure UpdateAutoScrollDirection(ADelta: Integer);

    // DropSource
    function CanStartDropSource(var AActions: TACLDropSourceActions; ASourceObject: TObject): Boolean; virtual;
    procedure StartDropSource(AActions: TACLDropSourceActions; ASource: IACLDropSourceOperation; ASourceObject: TObject);
    procedure DropSourceBegin; virtual;
    procedure DropSourceDrop(var AAllowDrop: Boolean); virtual;
    procedure DropSourceEnd(AActions: TACLDropSourceActions; AShiftState: TShiftState); virtual;

    // DropTarget
    function CreateDefaultDropTarget: TACLDropTarget; virtual;
    procedure UpdateDropTarget(ADropTarget: TACLDropTarget);

    function DragStart: Boolean;

    property AutoScrollTimer: TACLTimer read FAutoScrollTimer;
    property DropSourceConfig: TACLIniFile read FDropSourceConfig;
    property DropSourceObject: TObject read FDropSourceObject;
    property DropTarget: TACLDropTarget read FDropTarget;
    property LastPoint: TPoint read FLastPoint write FLastPoint;
    property MouseCapturePoint: TPoint read FMouseCapturePoint write FMouseCapturePoint;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    procedure Cancel; virtual;
    procedure Draw(ACanvas: TCanvas); virtual;
    procedure MouseDown(AShift: TShiftState; X, Y: Integer); virtual;
    procedure MouseMove(AShift: TShiftState; X, Y: Integer); virtual;
    procedure MouseUp(AShift: TShiftState; X, Y: Integer); virtual;
    procedure ProcessChanges(AChanges: TIntegerSet); virtual;
    //
    property Cursor: TCursor read FCursor write SetCursor;
    property DragObject: TACLCompoundControlSubClassDragObject read FDragObject;
    property HitTest: TACLHitTestInfo read GetHitTest;
    property IsActive: Boolean read FIsActive;
    property IsDropping: Boolean read FIsDropping write FIsDropping;
    property IsDropSourceOperation: Boolean read GetIsDropSourceOperation;
  end;

  { TACLCompoundControlSubClassHintController }

  TACLCompoundControlSubClassHintController = class(TACLHintController)
  strict private
    FSubClass: TACLCompoundControlSubClass;
  protected
    function CreateHintWindow: TACLHintWindow; override;
    function GetOwnerForm: TCustomForm; override;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass);
    procedure Update(AHitTest: TACLHitTestInfo);
    //
    property SubClass: TACLCompoundControlSubClass read FSubClass;
  end;

  { TACLCompoundControlSubClassHintControllerWindow }

  TACLCompoundControlSubClassHintControllerWindow = class(TACLHintWindow)
  protected
    FController: TACLCompoundControlSubClassHintController;

    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMActivateApp(var Message: TWMActivateApp); message WM_ACTIVATEAPP;
  public
    constructor Create(AController: TACLCompoundControlSubClassHintController); reintroduce;
  end;

  { TACLCompoundControlSubClass }

  TACLCompoundControlGetCursorEvent = procedure (Sender: TObject; AHitTestInfo: TACLHitTestInfo) of object;
  TACLCompoundControlDropSourceDataEvent = procedure (Sender: TObject; ASource: TACLDropSource) of object;
  TACLCompoundControlDropSourceFinishEvent = procedure (Sender: TObject; Canceled: Boolean; const ShiftState: TShiftState) of object;
  TACLCompoundControlDropSourceStartEvent = procedure (Sender: TObject; var AHandled: Boolean; var AAllowAction: TACLDropSourceActions) of object;

  TACLCompoundControlSubClass = class(TComponent,
    IACLScaleFactor,
    IACLResourceCollection,
    IACLResourceChangeListener)
  strict private
    FActionType: TACLCompoundControlActionType;
    FBounds: TRect;
    FContainer: IACLCompoundControlSubClassContainer;
    FDragAndDropController: TACLCompoundControlSubClassDragAndDropController;
    FEnabledContent: Boolean;
    FHintController: TACLCompoundControlSubClassHintController;
    FHitTest: TACLHitTestInfo;
    FLangSection: UnicodeString;
    FLockCount: Integer;
    FLongOperationCount: Integer;
    FSkipClick: Boolean;
    FViewInfo: TACLCompoundControlSubClassCustomViewInfo;

    FStyleHint: TACLStyleHint;
    FStyleScrollBox: TACLStyleScrollBox;

    FOnCalculated: TNotifyEvent;
    FOnDropSourceData: TACLCompoundControlDropSourceDataEvent;
    FOnDropSourceFinish: TACLCompoundControlDropSourceFinishEvent;
    FOnDropSourceStart: TACLCompoundControlDropSourceStartEvent;
    FOnGetCursor: TACLCompoundControlGetCursorEvent;
    FOnUpdateState: TNotifyEvent;

    function GetFont: TFont;
    function GetIsDestroying: Boolean; inline;
    function GetLangSection: UnicodeString;
    function GetMouseCapture: Boolean;
    function GetScaleFactor: TACLScaleFactor;
    procedure SetBounds(const AValue: TRect);
    procedure SetEnabledContent(AValue: Boolean);
    procedure SetHoveredObject(AValue: TObject);
    procedure SetMouseCapture(const AValue: Boolean);
    procedure SetStyleHint(AValue: TACLStyleHint);
    procedure SetStyleScrollBox(AValue: TACLStyleScrollBox);
  protected
    FChanges: TIntegerSet;
    FHoveredObject: TObject;
    FPressedObject: TObject;

    function CreateDragAndDropController: TACLCompoundControlSubClassDragAndDropController; virtual;
    function CreateHintController: TACLCompoundControlSubClassHintController; virtual;
    function CreateHitTest: TACLHitTestInfo; virtual;
    function CreateStyleScrollBox: TACLStyleScrollBox; virtual;
    function CreateViewInfo: TACLCompoundControlSubClassCustomViewInfo; virtual; abstract;
    procedure BoundsChanged; virtual;
    procedure FocusChanged; virtual;
    procedure RecreateViewSubClasses;

    // General
    procedure ProcessChanges(AChanges: TIntegerSet = []); virtual;
    procedure ToggleChecked(AObject: TObject);
    procedure ToggleExpanded(AObject: TObject);

    // Gesture
    procedure ProcessGesture(const AEventInfo: TGestureEventInfo; var AHandled: Boolean); virtual;

    // Keyboard
    procedure ProcessKeyDown(AKey: Word; AShift: TShiftState); virtual;
    procedure ProcessKeyPress(AKey: Char); virtual;
    procedure ProcessKeyUp(AKey: Word; AShift: TShiftState); virtual;

    // Mouse
    procedure ProcessContextPopup(var AHandled: Boolean); virtual;
    procedure ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState); virtual;
    procedure ProcessMouseDblClick(AButton: TMouseButton; AShift: TShiftState); virtual;
    procedure ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState); virtual;
    procedure ProcessMouseMove(AShift: TShiftState; X, Y: Integer); virtual;
    procedure ProcessMouseUp(AButton: TMouseButton; AShift: TShiftState); virtual;
    procedure ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState); virtual;
    procedure UpdateHotTrack;

    // Events
    procedure DoDragStarted; virtual;
    function DoDropSourceBegin(var AAllowAction: TACLDropSourceActions; AConfig: TACLIniFile): Boolean; virtual;
    procedure DoDropSourceFinish(Canceled: Boolean; const ShiftState: TShiftState); virtual;
    procedure DoDropSourceGetData(ASource: TACLDropSource; ADropSourceObject: TObject); virtual;
    procedure DoGetCursor(AHitTest: TACLHitTestInfo); virtual;
    procedure DoHoveredObjectChanged; virtual;

    // IACLResourceCollection
    function IACLResourceCollection.GetCollection = GetResourceCollection;
    function GetResourceCollection: TACLCustomResourceCollection;

    // IACLResourcesChangeListener
    procedure ResourceChanged(Sender: TObject; Resource: TACLResource = nil); overload;
    procedure ResourceChanged; overload; virtual;

    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; override; stdcall;
    //
    function GetFocused: Boolean; virtual;
    function GetFullRefreshChanges: TIntegerSet; virtual;
    procedure UpdateCursor;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Changed(AChanges: TIntegerSet); virtual;
    procedure ContextPopup(const P: TPoint; var AHandled: Boolean);
    procedure FullRefresh;
    function GetCursor(const P: TPoint): TCursor;
    procedure SetTargetDPI(AValue: Integer); virtual;
    procedure SetFocus; inline;

    // AutoSize
    function CalculateAutoSize(var AWidth, AHeight: Integer): Boolean; virtual;

    // Localization
    procedure Localize; overload;
    procedure Localize(const ASection: UnicodeString); overload; virtual;

    // Drawing
    procedure Draw(ACanvas: TCanvas);
    procedure Invalidate;
    procedure InvalidateRect(const R: TRect); virtual;
    procedure Update;

    // Gesture
    procedure Gesture(const AEventInfo: TGestureEventInfo; var AHandled: Boolean);

    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState);
    procedure KeyPress(var Key: Char);
    procedure KeyUp(var Key: Word; Shift: TShiftState);
    function WantSpecialKey(Key: Word; Shift: TShiftState): Boolean;

    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseLeave;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);

    // HitTest
    procedure UpdateHitTest; overload;
    procedure UpdateHitTest(const P: TPoint); overload; virtual;
    procedure UpdateHitTest(X, Y: Integer); overload;

    // HourGlass notify
    procedure BeginLongOperation;
    procedure EndLongOperation;

    // Scroll Bars
    procedure ScrollHorizontally(const AScrollCode: TScrollCode); virtual;
    procedure ScrollVertically(const AScrollCode: TScrollCode); virtual;

    // Lock/unlock
    procedure BeginUpdate;
    procedure EndUpdate;
    function IsUpdateLocked: Boolean;
    //
    function ClientToScreen(const P: TPoint): TPoint; overload;
    function ClientToScreen(const R: TRect): TRect; overload;
    function ScreenToClient(const P: TPoint): TPoint;
    //
    property ActionType: TACLCompoundControlActionType read FActionType;
    property Bounds: TRect read FBounds write SetBounds;
    property Container: IACLCompoundControlSubClassContainer read FContainer;
    property DragAndDropController: TACLCompoundControlSubClassDragAndDropController read FDragAndDropController;
    property EnabledContent: Boolean read FEnabledContent write SetEnabledContent;
    property Focused: Boolean read GetFocused;
    property Font: TFont read GetFont;
    property HintController: TACLCompoundControlSubClassHintController read FHintController;
    property HitTest: TACLHitTestInfo read FHitTest;
    property HoveredObject: TObject read FHoveredObject write SetHoveredObject;
    property LangSection: UnicodeString read GetLangSection;
    property MouseCapture: Boolean read GetMouseCapture write SetMouseCapture;
    property PressedObject: TObject read FPressedObject write FPressedObject;
    property ResourceCollection: TACLCustomResourceCollection read GetResourceCollection;
    property ScaleFactor: TACLScaleFactor read GetScaleFactor;
    property StyleHint: TACLStyleHint read FStyleHint write SetStyleHint;
    property StyleScrollBox: TACLStyleScrollBox read FStyleScrollBox write SetStyleScrollBox;
    property ViewInfo: TACLCompoundControlSubClassCustomViewInfo read FViewInfo;
    //
    property OnCalculated: TNotifyEvent read FOnCalculated write FOnCalculated;
    property OnDropSourceData: TACLCompoundControlDropSourceDataEvent read FOnDropSourceData write FOnDropSourceData;
    property OnDropSourceFinish: TACLCompoundControlDropSourceFinishEvent read FOnDropSourceFinish write FOnDropSourceFinish;
    property OnDropSourceStart: TACLCompoundControlDropSourceStartEvent read FOnDropSourceStart write FOnDropSourceStart;
    property OnGetCursor: TACLCompoundControlGetCursorEvent read FOnGetCursor write FOnGetCursor;
    property OnUpdateState: TNotifyEvent read FOnUpdateState write FOnUpdateState;
    //
    property IsDestroying: Boolean read GetIsDestroying;
  end;

implementation

uses
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

{ TACLHitTestInfo }

destructor TACLHitTestInfo.Destroy;
begin
  FreeAndNil(FHitObjectFlags);
  FreeAndNil(FHitObjectData);
  inherited Destroy;
end;

procedure TACLHitTestInfo.AfterConstruction;
begin
  inherited AfterConstruction;
  FHitObjectData := TDictionary<string, TObject>.Create;
  FHitObjectFlags := TACLList<Integer>.Create;
end;

function TACLHitTestInfo.CreateDragObject: TACLCompoundControlSubClassDragObject;
var
  AObject: IACLDraggableObject;
begin
  if Supports(HitObject, IACLDraggableObject, AObject) or
     Supports(HitObjectData['ViewInfo'], IACLDraggableObject, AObject)
  then
    Result := AObject.CreateDragObject(Self)
  else
    Result := nil;
end;

procedure TACLHitTestInfo.Reset;
begin
  Cursor := crDefault;
  FHitObjectData.Clear;
  FHitObjectFlags.Clear;
  HintData.Reset;
  HitObject := nil;
end;

function TACLHitTestInfo.GetHitObjectFlag(Index: Integer): Boolean;
begin
  Result := FHitObjectFlags.IndexOf(Index) >= 0;
end;

procedure TACLHitTestInfo.SetHitObjectFlag(Index: Integer; const Value: Boolean);
begin
  FHitObjectFlags.Remove(Index);
  if Value then
    FHitObjectFlags.Add(Index);
end;

function TACLHitTestInfo.GetHitObjectData(const Index: string): TObject;
begin
  if not FHitObjectData.TryGetValue(acLowerCase(Index), Result) then
    Result := nil;
end;

procedure TACLHitTestInfo.SetHitObjectData(const Index: string; const Value: TObject);
begin
  FHitObjectData.AddOrSetValue(acLowerCase(Index), Value);
end;

{ TACLCompoundControlSubClassPersistent }

constructor TACLCompoundControlSubClassPersistent.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited Create;
  FSubClass := ASubClass;
end;

function TACLCompoundControlSubClassPersistent.GetScaleFactor: TACLScaleFactor;
begin
  Result := SubClass.Container.GetScaleFactor;
end;

{ TACLCompoundControlSubClassCustomViewInfo }

procedure TACLCompoundControlSubClassCustomViewInfo.Calculate(const R: TRect; AChanges: TIntegerSet);
begin
  FBounds := R;
  DoCalculate(AChanges);
end;

function TACLCompoundControlSubClassCustomViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  Result := acPointInRect(Bounds, AInfo.HitPoint);
  if Result then
    DoCalculateHitTest(AInfo);
end;

procedure TACLCompoundControlSubClassCustomViewInfo.Draw(ACanvas: TCanvas);
begin
  if not acRectIsEmpty(Bounds) and RectVisible(ACanvas.Handle, Bounds) then
    DoDraw(ACanvas);
end;

procedure TACLCompoundControlSubClassCustomViewInfo.DrawTo(ACanvas: TCanvas; X, Y: Integer);
var
  ASaveIndex: Integer;
begin
  ASaveIndex := acSaveDC(ACanvas);
  try
    MoveWindowOrg(ACanvas.Handle, -Bounds.Left + X, -Bounds.Top + Y);
    Draw(ACanvas);
  finally
    acRestoreDC(ACanvas, ASaveIndex);
  end;
end;

procedure TACLCompoundControlSubClassCustomViewInfo.Invalidate;
begin
  SubClass.InvalidateRect(Bounds);
end;

procedure TACLCompoundControlSubClassCustomViewInfo.DoCalculate(AChanges: TIntegerSet);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClassCustomViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
begin
  AInfo.HitObject := Self;
end;

procedure TACLCompoundControlSubClassCustomViewInfo.DoDraw(ACanvas: TCanvas);
begin
  // do nothing
end;

{ TACLCompoundControlSubClassContainerViewInfo }

constructor TACLCompoundControlSubClassContainerViewInfo.Create(AOwner: TACLCompoundControlSubClass);
begin
  inherited Create(AOwner);
  FChildren := TACLObjectList.Create;
end;

destructor TACLCompoundControlSubClassContainerViewInfo.Destroy;
begin
  FreeAndNil(FChildren);
  inherited Destroy;
end;

procedure TACLCompoundControlSubClassContainerViewInfo.AddCell(ACell: TACLCompoundControlSubClassCustomViewInfo; var AObj);
begin
  TObject(AObj) := ACell;
  FChildren.Add(ACell);
end;

procedure TACLCompoundControlSubClassContainerViewInfo.CalculateSubCells(const AChanges: TIntegerSet);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClassContainerViewInfo.DoCalculate(AChanges: TIntegerSet);
begin
  inherited DoCalculate(AChanges);
  if cccnStruct in AChanges then
  begin
    FChildren.Clear;
    RecreateSubCells;
  end;
  CalculateSubCells(AChanges);
end;

procedure TACLCompoundControlSubClassContainerViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
var
  I: Integer;
begin
  inherited;
  for I := ChildCount - 1 downto 0 do
  begin
    if TACLCompoundControlSubClassCustomViewInfo(FChildren.List[I]).CalculateHitTest(AInfo) then
      Break;
  end;
end;

procedure TACLCompoundControlSubClassContainerViewInfo.DoDraw(ACanvas: TCanvas);
var
  ASaveIndex: Integer;
begin
  ASaveIndex := acSaveDC(ACanvas);
  try
    if acIntersectClipRegion(ACanvas.Handle, Bounds) then
      DoDrawCells(ACanvas);
  finally
    acRestoreDC(ACanvas, ASaveIndex);
  end;
end;

procedure TACLCompoundControlSubClassContainerViewInfo.DoDrawCells(ACanvas: TCanvas);
var
  I: Integer;
begin
  for I := 0 to ChildCount - 1 do
    Children[I].Draw(ACanvas);
end;

function TACLCompoundControlSubClassContainerViewInfo.GetChildCount: Integer;
begin
  Result := FChildren.Count;
end;

function TACLCompoundControlSubClassContainerViewInfo.GetChild(Index: Integer): TACLCompoundControlSubClassCustomViewInfo;
begin
  Result := TACLCompoundControlSubClassCustomViewInfo(FChildren.List[Index]);
end;

{ TACLCompoundControlSubClassDragWindow }

constructor TACLCompoundControlSubClassDragWindow.Create(AOwner: TWinControl);
begin
  CreateNew(AOwner);
  FControl := AOwner;
  FBitmap := TBitmap.Create;
  AlphaBlend := True;
  AlphaBlendValue := 200;
  BorderStyle := bsNone;
  Visible := False;
end;

destructor TACLCompoundControlSubClassDragWindow.Destroy;
begin
  FreeAndNil(FBitmap);
  inherited Destroy;
end;

procedure TACLCompoundControlSubClassDragWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WndParent := FControl.Handle;
  Params.ExStyle := WS_EX_NOACTIVATE;
  Params.Style := WS_POPUP;
end;

procedure TACLCompoundControlSubClassDragWindow.Paint;
begin
  Canvas.Draw(0, 0, FBitmap);
end;

procedure TACLCompoundControlSubClassDragWindow.SetBitmap(ABitmap: TBitmap; AMaskByBitmap: Boolean);
begin
  FBitmap.Assign(ABitmap);
  SetBounds(Left, Top, FBitmap.Width, FBitmap.Height);
  if AMaskByBitmap then
    SetWindowRgn(Handle, acRegionFromBitmap(FBitmap), False);
end;

procedure TACLCompoundControlSubClassDragWindow.SetVisible(AValue: Boolean);
const
  ShowFlags: array[Boolean] of Integer = (SWP_HIDEWINDOW, SWP_SHOWWINDOW);
begin
  SetWindowPos(Handle, 0, 0, 0, 0, 0, ShowFlags[AValue] or SWP_NOSIZE or SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE);
end;

procedure TACLCompoundControlSubClassDragWindow.WndProc(var Message: TMessage);
begin
  inherited WndProc(Message);
  case Message.Msg of
    WM_ACTIVATE:
      with TWMActivate(Message) do
      begin
        if Active <> WA_INACTIVE then
          SendMessage(ActiveWindow, WM_NCACTIVATE, WPARAM(True), 0);
      end;

    WM_NCHITTEST:
      Message.Result := HTTRANSPARENT;
  end;
end;

{ TACLCompoundControlSubClassDragObject }

destructor TACLCompoundControlSubClassDragObject.Destroy;
begin
  FreeAndNil(FDragTargetZoneWindow);
  FreeAndNil(FDragWindow);
  inherited Destroy;
end;

procedure TACLCompoundControlSubClassDragObject.DragFinished(ACanceled: Boolean);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClassDragObject.Draw(ACanvas: TCanvas);
begin
  // do nothing
end;

function TACLCompoundControlSubClassDragObject.TransformPoint(const P: TPoint): TPoint;
begin
  Result := P;
end;

procedure TACLCompoundControlSubClassDragObject.CreateAutoScrollTimer;
begin
  FController.CreateAutoScrollTimer;
end;

procedure TACLCompoundControlSubClassDragObject.InitializeDragWindow(ASourceViewInfo: TACLCompoundControlSubClassCustomViewInfo);
var
  ABitmap: TACLBitmap;
begin
  if DragWindow = nil then
    FDragWindow := TACLCompoundControlSubClassDragWindow.Create(SubClass.Container.GetControl);

  ABitmap := TACLBitmap.CreateEx(ASourceViewInfo.Bounds, pf24bit);
  try
    ASourceViewInfo.DrawTo(ABitmap.Canvas, 0, 0);
    DragWindow.SetBitmap(ABitmap, True);
    DragWindow.BoundsRect := SubClass.ClientToScreen(ASourceViewInfo.Bounds);
    DragWindow.SetVisible(True);
  finally
    ABitmap.Free;
  end;
end;

procedure TACLCompoundControlSubClassDragObject.StartDropSource(
  AActions: TACLDropSourceActions; ASource: IACLDropSourceOperation; ASourceObject: TObject);
begin
  FController.StartDropSource(AActions, ASource, ASourceObject);
end;

procedure TACLCompoundControlSubClassDragObject.UpdateAutoScrollDirection(ADelta: Integer);
begin
  FController.UpdateAutoScrollDirection(ADelta);
end;

procedure TACLCompoundControlSubClassDragObject.UpdateAutoScrollDirection(const P: TPoint; const AArea: TRect);
begin
  if P.Y < AArea.Top then
    UpdateAutoScrollDirection(1)
  else if P.Y > AArea.Bottom then
    UpdateAutoScrollDirection(-1)
  else
    UpdateAutoScrollDirection(0);
end;

procedure TACLCompoundControlSubClassDragObject.UpdateDragTargetZoneWindow(const ATargetScreenBounds: TRect; AVertical: Boolean);

  function LoadArrowBitmap(const AName: UnicodeString): TACLBitmap;
  begin
    Result := TACLBitmap.Create;
    Result.LoadFromResourceName(HInstance, AName);
  end;

  function PrepareDragWindowBitmap: TACLBitmap;
  var
    AArrow1, AArrow2: TACLBitmap;
  begin
    AArrow1 := LoadArrowBitmap('CCDW_DOWN');
    try
      AArrow2 := LoadArrowBitmap('CCDW_UP');
      try
        Result := TACLBitmap.CreateEx(Max(AArrow1.Width, AArrow2.Width), AArrow1.Height + AArrow2.Height +
          IfThen(AVertical, acRectHeight(ATargetScreenBounds), acRectWidth(ATargetScreenBounds)), pf24bit);
        acFillRect(Result.Canvas.Handle, Result.ClientRect, clFuchsia);
        Result.Canvas.Draw(0, 0, AArrow1);
        Result.Canvas.Draw(0, Result.Height - AArrow2.Height, AArrow2);
        if not AVertical then
          Result.Rotate(br270);
      finally
        AArrow2.Free;
      end;
    finally
      AArrow1.Free;
    end;
  end;

var
  ABitmap: TACLBitmap;
  AIsTargetAssigned: Boolean;
begin
  if (DragTargetScreenBounds <> ATargetScreenBounds) or (DragTargetZoneWindow = nil) then
  begin
    AIsTargetAssigned := not acRectIsEmpty(ATargetScreenBounds);
    if DragTargetZoneWindow = nil then
      FDragTargetZoneWindow := TACLCompoundControlSubClassDragWindow.Create(SubClass.Container.GetControl);

    if AIsTargetAssigned then
    begin
      ABitmap := PrepareDragWindowBitmap;
      try
        DragTargetZoneWindow.SetBitmap(ABitmap, True);
        DragTargetZoneWindow.BoundsRect := acRectCenter(ATargetScreenBounds, DragTargetZoneWindow.Width, DragTargetZoneWindow.Height);
      finally
        ABitmap.Free;
      end;
    end;
    DragTargetZoneWindow.SetVisible(AIsTargetAssigned);
    FDragTargetScreenBounds := ATargetScreenBounds;
  end;
end;

procedure TACLCompoundControlSubClassDragObject.UpdateDropTarget(ADropTarget: TACLDropTarget);
begin
  FController.UpdateDropTarget(ADropTarget);
end;

function TACLCompoundControlSubClassDragObject.GetCursor: TCursor;
begin
  Result := FController.Cursor;
end;

function TACLCompoundControlSubClassDragObject.GetHitTest: TACLHitTestInfo;
begin
  Result := FController.HitTest;
end;

function TACLCompoundControlSubClassDragObject.GetMouseCapturePoint: TPoint;
begin
  Result := FController.MouseCapturePoint;
end;

function TACLCompoundControlSubClassDragObject.GetScaleFactor: TACLScaleFactor;
begin
  Result := SubClass.ScaleFactor;
end;

function TACLCompoundControlSubClassDragObject.GetSubClass: TACLCompoundControlSubClass;
begin
  Result := FController.SubClass;
end;

procedure TACLCompoundControlSubClassDragObject.SetCursor(const Value: TCursor);
begin
  FController.Cursor := Value;
end;

{ TACLCompoundControlSubClassDragAndDropController }

constructor TACLCompoundControlSubClassDragAndDropController.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited Create(ASubClass);
  FDropSourceConfig := TACLIniFile.Create;
end;

destructor TACLCompoundControlSubClassDragAndDropController.Destroy;
begin
  Cancel;
  TACLObjectLinks.Release(Self);
  FreeAndNil(FDropTarget);
  FreeAndNil(FDropSourceConfig);
  inherited Destroy;
end;

procedure TACLCompoundControlSubClassDragAndDropController.Cancel;
begin
  if IsActive then
  begin
    TACLObjectLinks.Release(Self);
    if IsDropSourceOperation then
      DropSourceEnd([], [])
    else
      Finish(True);
  end;
end;

procedure TACLCompoundControlSubClassDragAndDropController.Draw(ACanvas: TCanvas);
begin
  if DragObject <> nil then
    DragObject.Draw(ACanvas);
end;

procedure TACLCompoundControlSubClassDragAndDropController.MouseDown(AShift: TShiftState; X, Y: Integer);
begin
  FStarted := False;
  MouseCapturePoint := Point(X, Y);
  LastPoint := MouseCapturePoint;
end;

procedure TACLCompoundControlSubClassDragAndDropController.MouseMove(AShift: TShiftState; X, Y: Integer);
var
  ADeltaX, ADeltaY: Integer;
  APoint: TPoint;
begin
  if SubClass.MouseCapture and not IsActive and not FStarted and ([ssLeft, ssRight, ssMiddle] * AShift = [ssLeft]) then
  begin
    ADeltaX := X - MouseCapturePoint.X;
    ADeltaY := Y - MouseCapturePoint.Y;
    if acCanStartDragging(ADeltaX, ADeltaY, ScaleFactor) then
    begin
      FStarted := True;
      SubClass.UpdateHitTest(LastPoint);
      if (SubClass.PressedObject = HitTest.HitObject) and DragStart then
      begin
        FIsActive := True; // first
        SubClass.DoDragStarted;
        LastPoint := DragObject.TransformPoint(LastPoint);
        Cursor := HitTest.Cursor;
      end
      else
        Cancel;
    end;
  end;

  if IsActive and not IsDropSourceOperation then
  begin
    APoint := DragObject.TransformPoint(Point(X, Y));
    ADeltaX := APoint.X - FLastPoint.X;
    ADeltaY := APoint.Y - FLastPoint.Y;
    DragObject.DragMove(APoint, ADeltaX, ADeltaY);
    LastPoint := Point(LastPoint.X + ADeltaX, LastPoint.Y + ADeltaY);
  end;
end;

procedure TACLCompoundControlSubClassDragAndDropController.MouseUp(AShift: TShiftState; X, Y: Integer);
begin
  if not IsDropSourceOperation then
    Finish(False);
end;

procedure TACLCompoundControlSubClassDragAndDropController.ProcessChanges(AChanges: TIntegerSet);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClassDragAndDropController.AutoScrollTimerHandler(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to Abs(FAutoScrollTimer.Tag) - 1 do
  begin
    if FAutoScrollTimer.Tag < 0 then
      SubClass.MouseWheel(mwdDown, [])
    else
      SubClass.MouseWheel(mwdUp, []);
  end;
end;

procedure TACLCompoundControlSubClassDragAndDropController.CreateAutoScrollTimer;
begin
  if AutoScrollTimer = nil then
    FAutoScrollTimer := TACLTimer.CreateEx(AutoScrollTimerHandler, 100);
end;

procedure TACLCompoundControlSubClassDragAndDropController.UpdateAutoScrollDirection(ADelta: Integer);
begin
  if AutoScrollTimer <> nil then
  begin
    AutoScrollTimer.Tag := ADelta;
    AutoScrollTimer.Enabled := FAutoScrollTimer.Tag <> 0;
  end;
end;

function TACLCompoundControlSubClassDragAndDropController.CanStartDropSource(
  var AActions: TACLDropSourceActions; ASourceObject: TObject): Boolean;
begin
  Result := not SubClass.DoDropSourceBegin(AActions, DropSourceConfig);
end;

procedure TACLCompoundControlSubClassDragAndDropController.StartDropSource(
  AActions: TACLDropSourceActions; ASource: IACLDropSourceOperation; ASourceObject: TObject);
var
  ADropSource: TACLDropSource;
begin
  DropSourceConfig.Clear;
  if CanStartDropSource(AActions, ASourceObject) and (AActions <> []) then
  begin
    FDropSourceObject := ASourceObject;
    FDropSourceOperation := ASource;

    ADropSource := TACLDropSource.Create(TACLDropSourceOwnerProxy.Create(Self));
    ADropSource.AllowedActions := AActions;
    ADropSource.DataProviders.Add(TACLDragDropDataProviderConfig.Create(DropSourceConfig));
    SubClass.DoDropSourceGetData(ADropSource, DropSourceConfig);
    ADropSource.ExecuteInThread;
  end;
end;

procedure TACLCompoundControlSubClassDragAndDropController.DropSourceBegin;
begin
  SubClass.UpdateHitTest(LastPoint);
  FDropSourceOperation.DropSourceBegin;
end;

procedure TACLCompoundControlSubClassDragAndDropController.DropSourceDrop(var AAllowDrop: Boolean);
begin
  FDropSourceOperation.DropSourceDrop(AAllowDrop);
end;

procedure TACLCompoundControlSubClassDragAndDropController.DropSourceEnd(AActions: TACLDropSourceActions; AShiftState: TShiftState);
begin
  FDropSourceOperation.DropSourceEnd(AActions, AShiftState);
  FDropSourceOperation := nil;
  FDropSourceObject := nil;
  Finish(AActions = []);
  SubClass.DoDropSourceFinish(AActions = [], AShiftState);
end;

function TACLCompoundControlSubClassDragAndDropController.CreateDefaultDropTarget: TACLDropTarget;
begin
  Result := nil;
end;

procedure TACLCompoundControlSubClassDragAndDropController.UpdateDropTarget(ADropTarget: TACLDropTarget);
begin
  if ADropTarget = nil then
    ADropTarget := CreateDefaultDropTarget;
  FreeAndNil(FDropTarget);
  FDropTarget := ADropTarget;
end;

function TACLCompoundControlSubClassDragAndDropController.DragStart: Boolean;
begin
  Result := False;
  FDragObject := HitTest.CreateDragObject;
  if DragObject <> nil then
  begin
    FDragObject.FController := Self;
    Result := FDragObject.DragStart;
    if not Result then
      FreeAndNil(FDragObject);
  end;
end;

procedure TACLCompoundControlSubClassDragAndDropController.Finish(ACanceled: Boolean);
begin
  if IsActive then
  try
    FIsActive := False;
    FreeAndNil(FAutoScrollTimer);
    DragObject.DragFinished(ACanceled);
    Cursor := crDefault;
  finally
    FreeAndNil(FDragObject);
  end;
end;

function TACLCompoundControlSubClassDragAndDropController.GetHitTest: TACLHitTestInfo;
begin
  Result := SubClass.HitTest;
end;

function TACLCompoundControlSubClassDragAndDropController.GetIsDropSourceOperation: Boolean;
begin
  Result := FDropSourceOperation <> nil;
end;

procedure TACLCompoundControlSubClassDragAndDropController.SetCursor(AValue: TCursor);
begin
  if FCursor <> AValue then
  begin
    FCursor := AValue;
    SubClass.UpdateCursor;
  end;
end;

{ TACLCompoundControlSubClassHintController }

constructor TACLCompoundControlSubClassHintController.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited Create;
  FSubClass := ASubClass;
end;

function TACLCompoundControlSubClassHintController.CreateHintWindow: TACLHintWindow;
begin
  Result := TACLCompoundControlSubClassHintControllerWindow.Create(Self);
end;

function TACLCompoundControlSubClassHintController.GetOwnerForm: TCustomForm;
var
  AControl: TWinControl;
begin
  AControl := SubClass.Container.GetControl;
  if AControl <> nil then
    Result := GetParentForm(AControl)
  else
    Result := nil;
end;

procedure TACLCompoundControlSubClassHintController.Update(AHitTest: TACLHitTestInfo);
begin
  inherited Update(AHitTest.HitObject, SubClass.ClientToScreen(AHitTest.HitPoint), AHitTest.HintData);
end;

{ TACLCompoundControlSubClassHintControllerWindow }

constructor TACLCompoundControlSubClassHintControllerWindow.Create(AController: TACLCompoundControlSubClassHintController);
begin
  inherited Create(nil);
  FController := AController;
  Font := FController.SubClass.Font;
  Style := FController.SubClass.StyleHint;
end;

procedure TACLCompoundControlSubClassHintControllerWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WndParent := FController.SubClass.Container.GetControl.Handle;
end;

procedure TACLCompoundControlSubClassHintControllerWindow.WMActivateApp(var Message: TWMActivateApp);
begin
  inherited;
  if not Message.Active then
    FController.Cancel;
end;

{ TACLCompoundControlSubClass }

constructor TACLCompoundControlSubClass.Create(AOwner: TComponent);
begin
  if not Supports(AOwner, IACLCompoundControlSubClassContainer, FContainer) then
    raise Exception.Create('IACLCompoundControlSubClassContainer is not supported by specified owner');

  inherited Create(AOwner);
  BeginUpdate;
  FEnabledContent := True;
  FViewInfo := CreateViewInfo;
  FHitTest := CreateHitTest;
  FDragAndDropController := CreateDragAndDropController;
  FHintController := CreateHintController;
  FStyleHint := TACLStyleHint.Create(Self);
  FStyleScrollBox := CreateStyleScrollBox;
end;

destructor TACLCompoundControlSubClass.Destroy;
begin
  FreeAndNil(FDragAndDropController);
  FreeAndNil(FHintController);
  FreeAndNil(FHitTest);
  FreeAndNil(FStyleHint);
  FreeAndNil(FStyleScrollBox);
  FreeAndNil(FViewInfo);
  inherited Destroy;
end;

procedure TACLCompoundControlSubClass.AfterConstruction;
begin
  inherited AfterConstruction;
  EndUpdate;
end;

procedure TACLCompoundControlSubClass.BeforeDestruction;
begin
  inherited BeforeDestruction;
  OnUpdateState := nil;
end;

procedure TACLCompoundControlSubClass.Changed(AChanges: TIntegerSet);
begin
  if not IsDestroying then
  begin
    FChanges := FChanges + AChanges;
    if not IsUpdateLocked and (FChanges <> []) then
    begin
      BeginUpdate;
      try
        AChanges := FChanges;
        FChanges := [];
        ProcessChanges(AChanges);
      finally
        EndUpdate;
      end;
      if (FChanges = []) and ([cccnStruct, cccnLayout] * AChanges <> []) then
        if Assigned(OnCalculated) then
        begin
          if not (csReading in Container.GetControl.ComponentState) then
            OnCalculated(Self);
        end;
    end;
  end;
end;

procedure TACLCompoundControlSubClass.ContextPopup(const P: TPoint; var AHandled: Boolean);
begin
  if EnabledContent then
  begin
    UpdateHitTest(P);
    if HitTest.IsScrollBarArea then
      AHandled := True
    else
    begin
      MouseCapture := False;
      PressedObject := nil;
      ProcessContextPopup(AHandled);
    end;
  end
end;

procedure TACLCompoundControlSubClass.FullRefresh;
begin
  Changed(GetFullRefreshChanges);
end;

function TACLCompoundControlSubClass.GetCursor(const P: TPoint): TCursor;
begin
  if FLongOperationCount > 0 then
    Result := crHourGlass
  else
    if DragAndDropController.IsActive then
      Result := DragAndDropController.Cursor
    else
      if EnabledContent and not IsUpdateLocked then
      begin
        UpdateHitTest(P);
        DoGetCursor(HitTest);
        Result := HitTest.Cursor;
      end
      else
        Result := crDefault;
end;

procedure TACLCompoundControlSubClass.SetTargetDPI(AValue: Integer);
begin
  StyleScrollBox.TargetDPI := AValue;
  StyleHint.TargetDPI := AValue;
  FullRefresh;
end;

procedure TACLCompoundControlSubClass.SetFocus;
begin
  if Container.CanFocus then
  try
    Container.SetFocus;
  except
    // do nothing
  end;
end;

function TACLCompoundControlSubClass.CalculateAutoSize(var AWidth, AHeight: Integer): Boolean;
begin
  Result := False;
end;

procedure TACLCompoundControlSubClass.Localize;
begin
  LangApplyTo(Copy(LangSection, 1, acLastDelimiter('.', LangSection)), Self);
end;

procedure TACLCompoundControlSubClass.Localize(const ASection: UnicodeString);
begin
  FLangSection := ASection;
end;

procedure TACLCompoundControlSubClass.Draw(ACanvas: TCanvas);
begin
  Exclude(FChanges, cccnContent);
  if FChanges <> [] then
    Changed([]);
  if FChanges = [] then
  begin
    ViewInfo.Draw(ACanvas);
    DragAndDropController.Draw(ACanvas);
  end;
end;

procedure TACLCompoundControlSubClass.Invalidate;
begin
  InvalidateRect(Bounds);
end;

procedure TACLCompoundControlSubClass.InvalidateRect(const R: TRect);
begin
  Container.InvalidateRect(R);
end;

procedure TACLCompoundControlSubClass.Update;
begin
  if not IsUpdateLocked then
    Container.Update;
end;

procedure TACLCompoundControlSubClass.Gesture(const AEventInfo: TGestureEventInfo; var AHandled: Boolean);
begin
  if EnabledContent then
  begin
    FActionType := ccatGesture;
    try
      ProcessGesture(AEventInfo, AHandled);
    finally
      FActionType := ccatNone;
    end;
  end;
end;

procedure TACLCompoundControlSubClass.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if EnabledContent then
  begin
    FActionType := ccatKeyboard;
    try
      if Key = VK_ESCAPE then
        DragAndDropController.Cancel;
      ProcessKeyDown(Key, Shift);
    finally
      FActionType := ccatNone;
    end;
  end;
end;

procedure TACLCompoundControlSubClass.KeyPress(var Key: Char);
begin
  if EnabledContent then
  begin
    FActionType := ccatKeyboard;
    try
      ProcessKeyPress(Key);
    finally
      FActionType := ccatNone;
    end;
  end;
end;

procedure TACLCompoundControlSubClass.KeyUp(var Key: Word; Shift: TShiftState);
begin
  if EnabledContent then
  begin
    FActionType := ccatKeyboard;
    try
      ProcessKeyUp(Key, Shift);
    finally
      FActionType := ccatNone;
    end;
  end;
end;

function TACLCompoundControlSubClass.WantSpecialKey(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := False;
end;

procedure TACLCompoundControlSubClass.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if EnabledContent then
  begin
    FActionType := ccatMouse;
    try
      FSkipClick := False;
      DragAndDropController.Cancel;
      HintController.Cancel;
      UpdateHitTest(X, Y);
      PressedObject := HitTest.HitObject;
      if ssDouble in Shift then
      begin
        ProcessMouseDblClick(Button, Shift - [ssDouble]);
        FSkipClick := True;
      end
      else
      begin
        MouseCapture := True;
        ProcessMouseDown(Button, Shift);
      end;
    finally
      FActionType := ccatNone;
    end;
  end;
end;

procedure TACLCompoundControlSubClass.MouseLeave;
begin
  if EnabledContent then
  begin
    HitTest.Reset;
    HintController.Cancel;
    HoveredObject := nil;
  end;
end;

procedure TACLCompoundControlSubClass.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if EnabledContent then
  begin
    FActionType := ccatMouse;
    try
      UpdateHitTest(X, Y);
      DragAndDropController.MouseMove(Shift, X, Y);
      if not DragAndDropController.IsActive then
      begin
        ProcessMouseMove(Shift, X, Y);
        if not MouseCapture then
          HintController.Update(HitTest);
      end;
    finally
      FActionType := ccatNone;
    end;
  end;
end;

procedure TACLCompoundControlSubClass.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ADragAndDropIsActive: Boolean;
begin
  if EnabledContent then
  begin
    FActionType := ccatMouse;
    try
      UpdateHitTest(X, Y);
      ADragAndDropIsActive := DragAndDropController.IsActive;
      DragAndDropController.MouseUp(Shift, X, Y);
      if not (ADragAndDropIsActive or FSkipClick) then
      begin
        if PressedObject = HitTest.HitObject then
          ProcessMouseClick(Button, Shift);
      end;
      ProcessMouseUp(Button, Shift);
      MouseCapture := False;
      PressedObject := nil;
    finally
      FActionType := ccatNone;
    end;
  end;
end;

procedure TACLCompoundControlSubClass.MouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);
begin
  FActionType := ccatMouse;
  try
    BeginUpdate;
    try
      ProcessMouseWheel(ADirection, AShift);
    finally
      EndUpdate;
    end;
    UpdateHotTrack;
  finally
    FActionType := ccatNone;
  end;
end;

procedure TACLCompoundControlSubClass.UpdateHitTest(X, Y: Integer);
begin
  UpdateHitTest(Point(X, Y));
end;

procedure TACLCompoundControlSubClass.UpdateHitTest;
begin
  UpdateHitTest(ScreenToClient(MouseCursorPos));
end;

procedure TACLCompoundControlSubClass.UpdateHitTest(const P: TPoint);
begin
  HitTest.Reset;
  HitTest.HitPoint := P;
  ViewInfo.CalculateHitTest(HitTest);
end;

procedure TACLCompoundControlSubClass.BeginLongOperation;
begin
  Inc(FLongOperationCount);
  if FLongOperationCount = 1 then
    UpdateCursor;
end;

procedure TACLCompoundControlSubClass.EndLongOperation;
begin
  Dec(FLongOperationCount);
  if FLongOperationCount = 0 then
    UpdateCursor;
end;

procedure TACLCompoundControlSubClass.ScrollHorizontally(const AScrollCode: TScrollCode);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.ScrollVertically(const AScrollCode: TScrollCode);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.BeginUpdate;
begin
  Inc(FLockCount);
  if FLockCount = 1 then
    CallNotifyEvent(Self, OnUpdateState);
end;

procedure TACLCompoundControlSubClass.EndUpdate;
begin
  Dec(FLockCount);
  if FLockCount = 0 then
  begin
    Changed(FChanges);
    CallNotifyEvent(Self, OnUpdateState);
  end;
end;

function TACLCompoundControlSubClass.IsUpdateLocked: Boolean;
begin
  Result := FLockCount > 0;
end;

function TACLCompoundControlSubClass.ClientToScreen(const R: TRect): TRect;
begin
  Result.BottomRight := ClientToScreen(R.BottomRight);
  Result.TopLeft := ClientToScreen(R.TopLeft);
end;

function TACLCompoundControlSubClass.ClientToScreen(const P: TPoint): TPoint;
begin
  Result := Container.ClientToScreen(P)
end;

function TACLCompoundControlSubClass.ScreenToClient(const P: TPoint): TPoint;
begin
  Result := Container.ScreenToClient(P)
end;

function TACLCompoundControlSubClass.CreateDragAndDropController: TACLCompoundControlSubClassDragAndDropController;
begin
  Result := TACLCompoundControlSubClassDragAndDropController.Create(Self);
end;

function TACLCompoundControlSubClass.CreateHintController: TACLCompoundControlSubClassHintController;
begin
  Result := TACLCompoundControlSubClassHintController.Create(Self);
end;

function TACLCompoundControlSubClass.CreateHitTest: TACLHitTestInfo;
begin
  Result := TACLHitTestInfo.Create;
end;

function TACLCompoundControlSubClass.CreateStyleScrollBox: TACLStyleScrollBox;
begin
  Result := TACLStyleScrollBox.Create(Self);
end;

procedure TACLCompoundControlSubClass.BoundsChanged;
begin
  Changed([cccnLayout]);
end;

procedure TACLCompoundControlSubClass.FocusChanged;
begin
  Changed([cccnContent]);
end;

procedure TACLCompoundControlSubClass.RecreateViewSubClasses;
begin
  FreeAndNil(FViewInfo);
  FViewInfo := CreateViewInfo;
  FullRefresh;
end;

procedure TACLCompoundControlSubClass.ProcessKeyDown(AKey: Word; AShift: TShiftState);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.ProcessGesture(const AEventInfo: TGestureEventInfo; var AHandled: Boolean);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.ProcessKeyPress(AKey: Char);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.ProcessKeyUp(AKey: Word; AShift: TShiftState);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.ProcessContextPopup(var AHandled: Boolean);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState);
var
  AClickable: IACLClickableObject;
begin
  if AButton = mbLeft then
  begin
    if HitTest.IsCheckable then
      ToggleChecked(HitTest.HitObject)
    else

    if HitTest.IsExpandable then
      ToggleExpanded(HitTest.HitObject)
    else

    if Supports(HitTest.HitObject, IACLClickableObject, AClickable) then
      AClickable.Click(HitTest);
  end;
end;

procedure TACLCompoundControlSubClass.ProcessMouseDblClick(AButton: TMouseButton; AShift: TShiftState);
var
  APressable: IACLPressableObject;
begin
  if Supports(PressedObject, IACLPressableObject, APressable) then
  begin
    APressable.MouseDown(AButton, AShift, HitTest);
    APressable.MouseUp(AButton, AShift, HitTest);
  end;
  if AButton = mbLeft then
  begin
    if HitTest.IsExpandable then
      ToggleExpanded(HitTest.HitObject);
    if HitTest.IsCheckable then
      ToggleChecked(HitTest.HitObject);
  end;
end;

procedure TACLCompoundControlSubClass.ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState);
var
  APressable: IACLPressableObject;
begin
  if Supports(PressedObject, IACLPressableObject, APressable) then
    APressable.MouseDown(AButton, AShift, HitTest);
  if AButton = mbLeft then
    DragAndDropController.MouseDown(AShift, HitTest.HitPoint.X, HitTest.HitPoint.Y);
end;

procedure TACLCompoundControlSubClass.ProcessMouseMove(AShift: TShiftState; X, Y: Integer);
begin
  if not DragAndDropController.IsActive then
    HoveredObject := HitTest.HitObject;
end;

procedure TACLCompoundControlSubClass.ProcessMouseUp(AButton: TMouseButton; AShift: TShiftState);
var
  APressable: IACLPressableObject;
begin
  if Supports(PressedObject, IACLPressableObject, APressable) then
  begin
    PressedObject := nil;
    APressable.MouseUp(AButton, AShift, HitTest);
  end;
end;

procedure TACLCompoundControlSubClass.ProcessMouseWheel(
  ADirection: TACLMouseWheelDirection; AShift: TShiftState);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.UpdateHotTrack;
begin
  with ScreenToClient(MouseCursorPos) do
    MouseMove(KeyboardStateToShiftState, X, Y);
end;

procedure TACLCompoundControlSubClass.DoDragStarted;
begin
  HoveredObject := nil;
end;

function TACLCompoundControlSubClass.DoDropSourceBegin(var AAllowAction: TACLDropSourceActions; AConfig: TACLIniFile): Boolean;
begin
  Result := False;
  if Assigned(OnDropSourceStart) then
    OnDropSourceStart(Self, Result, AAllowAction);
end;

procedure TACLCompoundControlSubClass.DoDropSourceFinish(Canceled: Boolean; const ShiftState: TShiftState);
begin
  if Assigned(OnDropSourceFinish) then
    OnDropSourceFinish(Self, Canceled, ShiftState);
end;

procedure TACLCompoundControlSubClass.DoDropSourceGetData(ASource: TACLDropSource; ADropSourceObject: TObject);
begin
  if Assigned(OnDropSourceData) then
    OnDropSourceData(Self, ASource);
end;

procedure TACLCompoundControlSubClass.DoGetCursor(AHitTest: TACLHitTestInfo);
begin
  if Assigned(OnGetCursor) then
    OnGetCursor(Self, AHitTest);
end;

procedure TACLCompoundControlSubClass.DoHoveredObjectChanged;
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.ResourceChanged;
begin
  FullRefresh;
end;

procedure TACLCompoundControlSubClass.ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
begin
  ResourceChanged;
end;

function TACLCompoundControlSubClass.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  Result := inherited QueryInterface(IID, Obj);
  if Result = E_NOINTERFACE then
  begin
    if Supports(Owner, IID, Obj) then
      Result := S_OK;
  end;
end;

function TACLCompoundControlSubClass.GetFocused: Boolean;
begin
  Result := Container.GetFocused;
end;

function TACLCompoundControlSubClass.GetFullRefreshChanges: TIntegerSet;
begin
  Result := [cccnContent, cccnViewport, cccnLayout, cccnStruct];
end;

procedure TACLCompoundControlSubClass.ProcessChanges(AChanges: TIntegerSet);
begin
  if cccnStruct in AChanges then
  begin
    FPressedObject := nil;
    FHoveredObject := nil;
  end;
  if AChanges - [cccnContent] <> [] then
  begin
    DragAndDropController.ProcessChanges(AChanges);
    ViewInfo.Calculate(Bounds, AChanges);
    UpdateHitTest;
  end;
  Invalidate;
end;

procedure TACLCompoundControlSubClass.ToggleChecked(AObject: TObject);
var
  ACheckable: IACLCheckableObject;
begin
  BeginUpdate;
  try
    if Supports(AObject, IACLCheckableObject, ACheckable) then
    try
      if ACheckable.CanCheck then
        ACheckable.Checked := not ACheckable.Checked;
    finally
      ACheckable := nil;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLCompoundControlSubClass.ToggleExpanded(AObject: TObject);
var
  AExpandable: IACLExpandableObject;
begin
  BeginUpdate;
  try
    if Supports(AObject, IACLExpandableObject, AExpandable) then
    try
      AExpandable.Expanded := not AExpandable.Expanded;
    finally
      AExpandable := nil;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLCompoundControlSubClass.UpdateCursor;
begin
  Container.UpdateCursor;
end;

function TACLCompoundControlSubClass.GetFont: TFont;
begin
  Result := Container.GetFont;
end;

function TACLCompoundControlSubClass.GetIsDestroying: Boolean;
begin
  Result := csDestroying in ComponentState;
end;

function TACLCompoundControlSubClass.GetLangSection: UnicodeString;
begin
  if FLangSection = '' then
    FLangSection := LangGetComponentPath(Self);
  Result := FLangSection;
end;

function TACLCompoundControlSubClass.GetMouseCapture: Boolean;
begin
  Result := Container.GetMouseCapture;
end;

function TACLCompoundControlSubClass.GetResourceCollection: TACLCustomResourceCollection;
var
  AIntf: IACLResourceCollection;
begin
  if Supports(Container, IACLResourceCollection, AIntf) then
    Result := AIntf.GetCollection
  else
    Result := nil;
end;

function TACLCompoundControlSubClass.GetScaleFactor: TACLScaleFactor;
begin
  Result := Container.GetScaleFactor;
end;

procedure TACLCompoundControlSubClass.SetBounds(const AValue: TRect);
begin
  if FBounds <> AValue then
  begin
    FBounds := AValue;
    BoundsChanged;
  end;
end;

procedure TACLCompoundControlSubClass.SetEnabledContent(AValue: Boolean);
begin
  if AValue <> EnabledContent then
  begin
    FEnabledContent := AValue;
    Changed([cccnContent]);
  end;
end;

procedure TACLCompoundControlSubClass.SetHoveredObject(AValue: TObject);
var
  AHotTrack: IACLHotTrackObject;
  APrevObject: TObject;
begin
  if FHoveredObject <> AValue then
  begin
    APrevObject := HoveredObject;
    FHoveredObject := AValue;
    if Supports(APrevObject, IACLHotTrackObject, AHotTrack) then
      AHotTrack.Leave;
    if Supports(HoveredObject, IACLHotTrackObject, AHotTrack) then
      AHotTrack.Enter;
    DoHoveredObjectChanged;
  end;
end;

procedure TACLCompoundControlSubClass.SetMouseCapture(const AValue: Boolean);
begin
  Container.SetMouseCapture(AValue);
end;

procedure TACLCompoundControlSubClass.SetStyleHint(AValue: TACLStyleHint);
begin
  FStyleHint.Assign(AValue);
end;

procedure TACLCompoundControlSubClass.SetStyleScrollBox(AValue: TACLStyleScrollBox);
begin
  FStyleScrollBox.Assign(AValue);
end;

end.
