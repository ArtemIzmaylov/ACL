{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*          Compoud Control Classes          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.CompoundControl.SubClass;

{$I ACL.Config.inc}

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
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.Math,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Timers,
  ACL.UI.Animation,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.DropSource,
  ACL.UI.DropTarget,
  ACL.UI.Forms,
  ACL.UI.HintWindow,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Desktop,
  ACL.Utils.DPIAware;

const
  // CompoundControl Changes Notifications
  cccnContent      = 0;
  cccnViewport     = 1;
  cccnLayout       = 2;
  cccnStruct       = 3;
  cccnLast = cccnStruct;

  // HitTest Flags
  cchtCheckable = 1;
  cchtExpandable = cchtCheckable + 1;
  cchtResizable = cchtExpandable + 1;
  cchtNonClient = cchtResizable + 1;
  cchtLast = cchtNonClient + 1;

  // HitTest Data
  cchdSubPart = 'SubPart';
  cchdViewInfo = 'ViewInfo';

type
  TACLCompoundControlSubClass = class;
  TACLCompoundControlDragAndDropController = class;
  TACLCompoundControlDragObject = class;

{$REGION ' Hit-Test '}

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
    function CreateDragObject: TACLCompoundControlDragObject; virtual;
    procedure Reset; virtual;

    property Cursor: TCursor read FCursor write FCursor;
    property HitObject: TObject read FHitObject write FHitObject;
    property HitObjectData[const Index: string]: TObject read GetHitObjectData write SetHitObjectData;
    property HitObjectFlags[Index: Integer]: Boolean read GetHitObjectFlag write SetHitObjectFlag;
    property HitPoint: TPoint read FHitPoint write FHitPoint;

    property IsCheckable: Boolean index cchtCheckable read GetHitObjectFlag write SetHitObjectFlag;
    property IsExpandable: Boolean index cchtExpandable read GetHitObjectFlag write SetHitObjectFlag;
    property IsNonClient: Boolean index cchtNonClient read GetHitObjectFlag write SetHitObjectFlag;
    property IsResizable: Boolean index cchtResizable read GetHitObjectFlag write SetHitObjectFlag;
  end;

{$ENDREGION}

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
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
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

  TACLHotTrackAction = (htaEnter, htaLeave, htaSwitchPart);
  IACLHotTrackObject = interface
  ['{CED931C7-5375-4A8B-A1D1-3D127F8DA46F}']
    procedure OnHotTrack(Action: TACLHotTrackAction);
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

{$REGION ' General '}

  { TACLCompoundControlPersistent }

  TACLCompoundControlPersistent = class(TACLUnknownObject)
  strict private
    FSubClass: TACLCompoundControlSubClass;
    function GetCurrentDpi: Integer; inline;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass); virtual;
    property CurrentDpi: Integer read GetCurrentDpi;
    property SubClass: TACLCompoundControlSubClass read FSubClass;
  end;

  { TACLCompoundControlCustomViewInfo }

  TACLCompoundControlCustomViewInfo = class(TACLCompoundControlPersistent)
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

  { TACLCompoundControlContainerViewInfo }

  TACLCompoundControlContainerViewInfo = class(TACLCompoundControlCustomViewInfo)
  strict private
    function GetChild(Index: Integer): TACLCompoundControlCustomViewInfo; inline;
    function GetChildCount: Integer; inline;
  protected
    FChildren: TACLObjectList;

    procedure AddCell(ACell: TACLCompoundControlCustomViewInfo; var AObj);
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
    property Children[Index: Integer]: TACLCompoundControlCustomViewInfo read GetChild;
  end;

  { TACLCompoundControlDragWindow }

  TACLCompoundControlDragWindow = class(TACLForm)
  strict private
    FBitmap: TACLDib;
    FControl: TWinControl;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TWinControl); reintroduce;
    destructor Destroy; override;
    procedure SetBitmap(ABitmap: TACLDib; AMaskByBitmap: Boolean);
    procedure SetVisible(AValue: Boolean);
  end;

  { TACLCompoundControlDragObject }

  TACLCompoundControlDragObject = class(TACLUnknownObject)
  strict private
    FDragTargetScreenBounds: TRect;
    FDragTargetZoneWindow: TACLCompoundControlDragWindow;
    FDragWindow: TACLCompoundControlDragWindow;

    function GetCurrentDpi: Integer;
    function GetCursor: TCursor;
    function GetHitTest: TACLHitTestInfo;
    function GetMouseCapturePoint: TPoint;
    function GetSubClass: TACLCompoundControlSubClass;
    procedure SetCursor(AValue: TCursor);
  protected
    FController: TACLCompoundControlDragAndDropController;

    procedure CreateAutoScrollTimer;
    procedure InitializeDragWindow(ASourceViewInfo: TACLCompoundControlCustomViewInfo);
    procedure StartDropSource(AActions: TACLDropSourceActions;
      ASource: IACLDropSourceOperation; ASourceObject: TObject); virtual;
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
    property CurrentDpi: Integer read GetCurrentDpi;
    property Cursor: TCursor read GetCursor write SetCursor;
    property DragTargetScreenBounds: TRect read FDragTargetScreenBounds;
    property DragTargetZoneWindow: TACLCompoundControlDragWindow read FDragTargetZoneWindow;
    property DragWindow: TACLCompoundControlDragWindow read FDragWindow;
    property HitTest: TACLHitTestInfo read GetHitTest;
    property MouseCapturePoint: TPoint read GetMouseCapturePoint;
    property SubClass: TACLCompoundControlSubClass read GetSubClass;
  end;

  { TACLCompoundControlDragAndDropController }

  TACLCompoundControlDragAndDropController = class(TACLCompoundControlPersistent,
    IACLObjectLinksSupport,
    IACLDropSourceOperation)
  strict private
    FAutoScrollTimer: TACLTimer;
    FDragObject: TACLCompoundControlDragObject;
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
    property DragObject: TACLCompoundControlDragObject read FDragObject;
    property HitTest: TACLHitTestInfo read GetHitTest;
    property IsActive: Boolean read FIsActive;
    property IsDropping: Boolean read FIsDropping write FIsDropping;
    property IsDropSourceOperation: Boolean read GetIsDropSourceOperation;
  end;

  { TACLCompoundControlHintController }

  TACLCompoundControlHintController = class(TACLHintController)
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

  { TACLCompoundControlHintControllerWindow }

  TACLCompoundControlHintControllerWindow = class(TACLHintWindow)
  protected
    FController: TACLCompoundControlHintController;

    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMActivateApp(var Message: TWMActivateApp); message WM_ACTIVATEAPP;
  public
    constructor Create(AController: TACLCompoundControlHintController); reintroduce;
  end;

{$ENDREGION}

{$REGION ' Content Cells '}

  TACLCompoundControlBaseContentCellViewInfo = class;

  { IACLCompoundControlSubClassContent }

  IACLCompoundControlSubClassContent = interface
  ['{EE51759E-3F6D-4449-A331-B16EB4FBB9A2}']
    function GetContentWidth: Integer;
    function GetViewItemsArea: TRect;
    function GetViewItemsOrigin: TPoint;
  end;

  { TACLCompoundControlBaseContentCell }

  TACLCompoundControlBaseContentCellClass = class of TACLCompoundControlBaseContentCell;
  TACLCompoundControlBaseContentCell = class(TACLUnknownObject)
  strict private
    FData: TObject;

    function GetBounds: TRect; inline;
  protected
    FHeight: Integer;
    FTop: Integer;
    FViewInfo: TACLCompoundControlBaseContentCellViewInfo;

    function GetClientBounds: TRect; virtual;
  public
    constructor Create(AData: TObject; AViewInfo: TACLCompoundControlBaseContentCellViewInfo);
    procedure CalculateHitTest(AInfo: TACLHitTestInfo);
    procedure Draw(ACanvas: TCanvas);
    function MeasureHeight: Integer;
    //
    property Bounds: TRect read GetBounds;
    property Data: TObject read FData;
    property Height: Integer read FHeight;
    property Top: Integer read FTop;
    property ViewInfo: TACLCompoundControlBaseContentCellViewInfo read FViewInfo;
  end;

  { TACLCompoundControlBaseContentCellViewInfo }

  TACLCompoundControlBaseContentCellViewInfo = class(TACLUnknownObject)
  strict private
    FOwner: IACLCompoundControlSubClassContent;

    function GetBounds: TRect;
  protected
    FData: TObject;
    FHeight: Integer;
    FWidth: Integer;

    procedure DoDraw(ACanvas: TCanvas); virtual; abstract;
    procedure DoGetHitTest(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo); virtual;
    function GetFocusRect: TRect; virtual;
    function GetFocusRectColor: TColor; virtual;
    function HasFocusRect: Boolean; virtual;
  public
    constructor Create(AOwner: IACLCompoundControlSubClassContent);
    procedure Calculate; overload;
    procedure Calculate(AWidth, AHeight: Integer); overload; virtual;
    procedure CalculateHitTest(AData: TObject; const ABounds: TRect; AInfo: TACLHitTestInfo);
    procedure Draw(ACanvas: TCanvas; AData: TObject; const ABounds: TRect);
    procedure Initialize(AData: TObject); overload; virtual;
    procedure Initialize(AData: TObject; AHeight: Integer); overload; virtual;
    function MeasureHeight: Integer; virtual;
    //
    property Bounds: TRect read GetBounds;
    property Owner: IACLCompoundControlSubClassContent read FOwner;
  end;

  { TACLCompoundControlBaseCheckableContentCellViewInfo }

  TACLCompoundControlBaseCheckableContentCellViewInfo = class(TACLCompoundControlBaseContentCellViewInfo)
  protected
    FCheckBoxRect: TRect;
    FExpandButtonRect: TRect;
    FExpandButtonVisible: Boolean;

    procedure DoGetHitTest(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo); override;
    function IsCheckBoxEnabled: Boolean; virtual;
  public
    property CheckBoxRect: TRect read FCheckBoxRect;
    property ExpandButtonRect: TRect read FExpandButtonRect;
    property ExpandButtonVisible: Boolean read FExpandButtonVisible;
  end;

  { TACLCompoundControlContentCellList }

  TACLCompoundControlContentCellList<T: TACLCompoundControlBaseContentCell> = class(TACLObjectList<T>)
  strict private
    FFirstVisible: Integer;
    FLastVisible: Integer;
    FOwner: IACLCompoundControlSubClassContent;
  protected
    FCellClass: TACLCompoundControlBaseContentCellClass;

    function GetClipRect: TRect; virtual;
  public
    constructor Create(AOwner: IACLCompoundControlSubClassContent);
    function Add(AData: TObject; AViewInfo: TACLCompoundControlBaseContentCellViewInfo): T;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
    procedure Clear;
    procedure Draw(ACanvas: TCanvas);
    function Find(AData: TObject; out ACell: T): Boolean;
    function FindFirstVisible(AStartFromIndex: Integer; ADirection: Integer; ADataClass: TClass; out ACell: T): Boolean;
    function GetCell(Index: Integer; out ACell: TACLCompoundControlBaseContentCell): Boolean;
    function GetContentSize: Integer;
    procedure UpdateVisibleBounds;
    //
    property FirstVisible: Integer read FFirstVisible;
    property LastVisible: Integer read FLastVisible;
  end;

  { TACLCompoundControlContentCellList }

  TACLCompoundControlContentCellList = class(TACLCompoundControlContentCellList<TACLCompoundControlBaseContentCell>)
  public
    constructor Create(AOwner: IACLCompoundControlSubClassContent; ACellClass: TACLCompoundControlBaseContentCellClass);
  end;

{$ENDREGION}

{$REGION ' Scrollable Contaner '}

  TACLCompoundControlScrollBarThumbnailViewInfo = class;

  TACLScrollEvent = procedure (Sender: TObject; Position: Integer) of object;
  TACLVisibleScrollBars = set of TScrollBarKind;

  { TACLScrollInfo }

  TACLScrollInfo = record
    Min: Integer;
    Max: Integer;
    LineSize: Integer;
    Page: Integer;
    Position: Integer;

    function InvisibleArea: Integer;
    function Range: Integer;
    procedure Reset;
  end;

  { TACLCompoundControlScrollBarViewInfo }

  TACLCompoundControlScrollBarViewInfo = class(TACLCompoundControlContainerViewInfo, IACLPressableObject)
  strict private
    FKind: TScrollBarKind;
    FPageSizeInPixels: Integer;
    FScrollInfo: TACLScrollInfo;
    FScrollTimer: TACLTimer;
    FThumbExtends: TRect;
    FTrackArea: TRect;
    FVisible: Boolean;

    FOnScroll: TACLScrollEvent;

    function GetHitTest: TACLHitTestInfo; inline;
    function GetStyle: TACLStyleScrollBox; inline;
    function GetThumbnailViewInfo: TACLCompoundControlScrollBarThumbnailViewInfo;
    procedure ScrollTimerHandler(Sender: TObject);
  protected
    function CalculateScrollDelta(const P: TPoint): Integer;
    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure RecreateSubCells; override;

    procedure Scroll(APosition: Integer);
    procedure ScrollTo(const P: TPoint);
    procedure ScrollToMouseCursor(const AInitialDelta: Integer);
    // IACLPressableObject
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
    //
    property HitTest: TACLHitTestInfo read GetHitTest;
    property ThumbnailViewInfo: TACLCompoundControlScrollBarThumbnailViewInfo read GetThumbnailViewInfo;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass; AKind: TScrollBarKind); reintroduce; virtual;
    destructor Destroy; override;
    function IsThumbResizable: Boolean; virtual;
    function MeasureSize: Integer;
    procedure SetParams(const AScrollInfo: TACLScrollInfo);
    //
    property Kind: TScrollBarKind read FKind;
    property ScrollInfo: TACLScrollInfo read FScrollInfo;
    property Style: TACLStyleScrollBox read GetStyle;
    property ThumbExtends: TRect read FThumbExtends;
    property TrackArea: TRect read FTrackArea;
    property Visible: Boolean read FVisible;
    //
    property OnScroll: TACLScrollEvent read FOnScroll write FOnScroll;
  end;

  { TACLCompoundControlScrollBarPartViewInfo }

  TACLCompoundControlScrollBarPartViewInfo = class(TACLCompoundControlCustomViewInfo,
    IACLAnimateControl,
    IACLPressableObject,
    IACLHotTrackObject)
  strict private
    FOwner: TACLCompoundControlScrollBarViewInfo;
    FPart: TACLScrollBarPart;
    FState: TACLButtonState;

    function GetActualState: TACLButtonState;
    function GetKind: TScrollBarKind;
    function GetStyle: TACLStyleScrollBox;
    procedure SetState(AValue: TACLButtonState);
  protected
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure UpdateState;
    // IACLAnimateControl
    procedure IACLAnimateControl.Animate = Invalidate;
    // IACLHotTrackObject
    procedure OnHotTrack(Action: TACLHotTrackAction);
    // IACLPressableObject
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo); virtual;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo); virtual;
    //
    property ActualState: TACLButtonState read GetActualState;
  public
    constructor Create(AOwner: TACLCompoundControlScrollBarViewInfo; APart: TACLScrollBarPart); reintroduce; virtual;
    destructor Destroy; override;
    procedure Scroll(APosition: Integer);
    //
    property Kind: TScrollBarKind read GetKind;
    property Owner: TACLCompoundControlScrollBarViewInfo read FOwner;
    property Part: TACLScrollBarPart read FPart;
    property State: TACLButtonState read FState write SetState;
    property Style: TACLStyleScrollBox read GetStyle;
  end;

  { TACLCompoundControlScrollBarButtonViewInfo }

  TACLCompoundControlScrollBarButtonViewInfo = class(TACLCompoundControlScrollBarPartViewInfo)
  strict private
    FTimer: TACLTimer;

    procedure TimerHandler(Sender: TObject);
  protected
    procedure Click;
    // IACLPressableObject
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo); override;
  end;

  { TACLCompoundControlScrollBarThumbnailDragObject }

  TACLCompoundControlScrollBarThumbnailDragObject = class(TACLCompoundControlDragObject)
  strict private
    FOwner: TACLCompoundControlScrollBarPartViewInfo;
    FSavedBounds: TRect;
    FSavedPosition: Integer;

    function GetTrackArea: TRect;
  public
    constructor Create(AOwner: TACLCompoundControlScrollBarPartViewInfo);
    function DragStart: Boolean; override;
    procedure DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer); override;
    procedure DragFinished(ACanceled: Boolean); override;
    //
    property Owner: TACLCompoundControlScrollBarPartViewInfo read FOwner;
    property TrackArea: TRect read GetTrackArea;
  end;

  { TACLCompoundControlScrollBarThumbnailViewInfo }

  TACLCompoundControlScrollBarThumbnailViewInfo = class(TACLCompoundControlScrollBarPartViewInfo,
    IACLDraggableObject)
  protected
    // IACLDraggableObject
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
  end;

  { TACLCompoundControlScrollContainerViewInfo }

  TACLCompoundControlScrollContainerViewInfo = class(TACLCompoundControlContainerViewInfo)
  strict private
    FScrollBarHorz: TACLCompoundControlScrollBarViewInfo;
    FScrollBarVert: TACLCompoundControlScrollBarViewInfo;
    FSizeGripArea: TRect;
    FViewportX: Integer;
    FViewportY: Integer;

    function GetViewport: TPoint;
    function GetVisibleScrollBars: TACLVisibleScrollBars;
    procedure SetViewport(const AValue: TPoint);
    procedure SetViewportX(AValue: Integer);
    procedure SetViewportY(AValue: Integer);
    //
    procedure ScrollHorzHandler(Sender: TObject; ScrollPos: Integer);
    procedure ScrollVertHandler(Sender: TObject; ScrollPos: Integer);
  protected
    FClientBounds: TRect;
    FContentSize: TSize;

    function CreateScrollBar(AKind: TScrollBarKind): TACLCompoundControlScrollBarViewInfo; virtual;
    function GetScrollInfo(AKind: TScrollBarKind; out AInfo: TACLScrollInfo): Boolean; virtual;
    function ScrollViewport(AKind: TScrollBarKind; AScrollCode: TScrollCode): Integer;
    //
    procedure CalculateContentLayout; virtual; abstract;
    procedure CalculateScrollBar(AScrollBar: TACLCompoundControlScrollBarViewInfo); virtual;
    procedure CalculateScrollBarsPosition(var R: TRect);
    procedure CalculateSubCells(const AChanges: TIntegerSet); override;
    procedure ContentScrolled(ADeltaX, ADeltaY: Integer); virtual;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure UpdateScrollBars; virtual;
  public
    constructor Create(AOwner: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    procedure Calculate(const R: TRect; AChanges: TIntegerSet); override;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; override;
    procedure ScrollByMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);
    procedure ScrollHorizontally(const AScrollCode: TScrollCode);
    procedure ScrollVertically(const AScrollCode: TScrollCode);
    //
    property ClientBounds: TRect read FClientBounds;
    property ContentSize: TSize read FContentSize;
    property ScrollBarHorz: TACLCompoundControlScrollBarViewInfo read FScrollBarHorz;
    property ScrollBarVert: TACLCompoundControlScrollBarViewInfo read FScrollBarVert;
    property SizeGripArea: TRect read FSizeGripArea;
    property Viewport: TPoint read GetViewport write SetViewport;
    property ViewportX: Integer read FViewportX write SetViewportX;
    property ViewportY: Integer read FViewportY write SetViewportY;
    property VisibleScrollBars: TACLVisibleScrollBars read GetVisibleScrollBars;
  end;

{$ENDREGION}

  { TACLCompoundControlSubClass }

  TACLCompoundControlActionType = (ccatNone, ccatMouse, ccatGesture, ccatKeyboard);
  TACLCompoundControlGetCursorEvent = procedure (Sender: TObject; AHitTestInfo: TACLHitTestInfo) of object;
  TACLCompoundControlDropSourceDataEvent = procedure (Sender: TObject; ASource: TACLDropSource) of object;
  TACLCompoundControlDropSourceFinishEvent = procedure (Sender: TObject; Canceled: Boolean; const ShiftState: TShiftState) of object;
  TACLCompoundControlDropSourceStartEvent = procedure (Sender: TObject; var AHandled: Boolean; var AAllowAction: TACLDropSourceActions) of object;

  TACLCompoundControlSubClass = class(TComponent,
    IACLCurrentDpi,
    IACLResourceCollection,
    IACLResourceChangeListener)
  strict private
    FActionType: TACLCompoundControlActionType;
    FBounds: TRect;
    FContainer: IACLCompoundControlSubClassContainer;
    FDragAndDropController: TACLCompoundControlDragAndDropController;
    FEnabledContent: Boolean;
    FHintController: TACLCompoundControlHintController;
    FHitTest: TACLHitTestInfo;
    FHoveredObject: TObject;
    FHoveredObjectSubPart: NativeInt;
    FLangSection: UnicodeString;
    FLockCount: Integer;
    FLongOperationCount: Integer;
    FPressedObject: TObject;
    FSkipClick: Boolean;
    FViewInfo: TACLCompoundControlCustomViewInfo;

    FStyleHint: TACLStyleHint;
    FStyleScrollBox: TACLStyleScrollBox;

    FOnCalculated: TNotifyEvent;
    FOnDropSourceData: TACLCompoundControlDropSourceDataEvent;
    FOnDropSourceFinish: TACLCompoundControlDropSourceFinishEvent;
    FOnDropSourceStart: TACLCompoundControlDropSourceStartEvent;
    FOnGetCursor: TACLCompoundControlGetCursorEvent;
    FOnUpdateState: TNotifyEvent;

    function GetCurrentDpi: Integer;
    function GetFont: TFont;
    function GetIsDestroying: Boolean; inline;
    function GetLangSection: UnicodeString;
    function GetMouseCapture: Boolean;
    procedure SetBounds(const AValue: TRect);
    procedure SetEnabledContent(AValue: Boolean);
    procedure SetMouseCapture(const AValue: Boolean);
    procedure SetStyleHint(AValue: TACLStyleHint);
    procedure SetStyleScrollBox(AValue: TACLStyleScrollBox);
  protected
    FChanges: TIntegerSet;

    function CreateDragAndDropController: TACLCompoundControlDragAndDropController; virtual;
    function CreateHintController: TACLCompoundControlHintController; virtual;
    function CreateHitTest: TACLHitTestInfo; virtual;
    function CreateStyleScrollBox: TACLStyleScrollBox; virtual;
    function CreateViewInfo: TACLCompoundControlCustomViewInfo; virtual; abstract;
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
    procedure SetHoveredObject(AObject: TObject; ASubPart: NativeInt = 0);
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

    function GetFocused: Boolean; virtual;
    function GetFullRefreshChanges: TIntegerSet; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Changed(AChanges: TIntegerSet); virtual;
    procedure ContextPopup(const P: TPoint; var AHandled: Boolean);
    procedure FullRefresh;
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
    function WantSpecialKey(Key: Word; Shift: TShiftState): Boolean; virtual;

    // Cursor
    function GetCursor(const P: TPoint): TCursor;
    procedure UpdateCursor;

    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseLeave;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);

    // HitTest
    function CalculateState(AObject: TObject; ASubPart: NativeInt = 0): TACLButtonState;
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
    property CurrentDpi: Integer read GetCurrentDpi;
    property DragAndDropController: TACLCompoundControlDragAndDropController read FDragAndDropController;
    property EnabledContent: Boolean read FEnabledContent write SetEnabledContent;
    property Focused: Boolean read GetFocused;
    property Font: TFont read GetFont;
    property HintController: TACLCompoundControlHintController read FHintController;
    property HitTest: TACLHitTestInfo read FHitTest;
    property HoveredObject: TObject read FHoveredObject;
    property HoveredObjectSubPart: NativeInt read FHoveredObjectSubPart;
    property LangSection: UnicodeString read GetLangSection;
    property MouseCapture: Boolean read GetMouseCapture write SetMouseCapture;
    property PressedObject: TObject read FPressedObject write FPressedObject;
    property ResourceCollection: TACLCustomResourceCollection read GetResourceCollection;
    property StyleHint: TACLStyleHint read FStyleHint write SetStyleHint;
    property StyleScrollBox: TACLStyleScrollBox read FStyleScrollBox write SetStyleScrollBox;
    property ViewInfo: TACLCompoundControlCustomViewInfo read FViewInfo;
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

{$REGION ' Hit-Test '}

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

function TACLHitTestInfo.CreateDragObject: TACLCompoundControlDragObject;
var
  AObject: IACLDraggableObject;
begin
  if Supports(HitObject, IACLDraggableObject, AObject) or
     Supports(HitObjectData[cchdViewInfo], IACLDraggableObject, AObject)
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

{$ENDREGION}

{$REGION ' General '}

{ TACLCompoundControlPersistent }

constructor TACLCompoundControlPersistent.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited Create;
  FSubClass := ASubClass;
end;

function TACLCompoundControlPersistent.GetCurrentDpi: Integer;
begin
  Result := SubClass.Container.GetCurrentDpi;
end;

{ TACLCompoundControlCustomViewInfo }

procedure TACLCompoundControlCustomViewInfo.Calculate(const R: TRect; AChanges: TIntegerSet);
begin
  FBounds := R;
  DoCalculate(AChanges);
end;

function TACLCompoundControlCustomViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  Result := PtInRect(Bounds, AInfo.HitPoint);
  if Result then
    DoCalculateHitTest(AInfo);
end;

procedure TACLCompoundControlCustomViewInfo.Draw(ACanvas: TCanvas);
begin
  if acRectVisible(ACanvas.Handle, Bounds) then
    DoDraw(ACanvas);
end;

procedure TACLCompoundControlCustomViewInfo.DrawTo(ACanvas: TCanvas; X, Y: Integer);
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

procedure TACLCompoundControlCustomViewInfo.Invalidate;
begin
  SubClass.InvalidateRect(Bounds);
end;

procedure TACLCompoundControlCustomViewInfo.DoCalculate(AChanges: TIntegerSet);
begin
  // do nothing
end;

procedure TACLCompoundControlCustomViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
begin
  AInfo.HitObject := Self;
end;

procedure TACLCompoundControlCustomViewInfo.DoDraw(ACanvas: TCanvas);
begin
  // do nothing
end;

{ TACLCompoundControlContainerViewInfo }

constructor TACLCompoundControlContainerViewInfo.Create(AOwner: TACLCompoundControlSubClass);
begin
  inherited Create(AOwner);
  FChildren := TACLObjectList.Create;
end;

destructor TACLCompoundControlContainerViewInfo.Destroy;
begin
  FreeAndNil(FChildren);
  inherited Destroy;
end;

procedure TACLCompoundControlContainerViewInfo.AddCell(ACell: TACLCompoundControlCustomViewInfo; var AObj);
begin
  TObject(AObj) := ACell;
  FChildren.Add(ACell);
end;

procedure TACLCompoundControlContainerViewInfo.CalculateSubCells(const AChanges: TIntegerSet);
begin
  // do nothing
end;

procedure TACLCompoundControlContainerViewInfo.DoCalculate(AChanges: TIntegerSet);
begin
  inherited DoCalculate(AChanges);
  if cccnStruct in AChanges then
  begin
    FChildren.Clear;
    RecreateSubCells;
  end;
  CalculateSubCells(AChanges);
end;

procedure TACLCompoundControlContainerViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
var
  I: Integer;
begin
  inherited;
  for I := ChildCount - 1 downto 0 do
  begin
    if TACLCompoundControlCustomViewInfo(FChildren.List[I]).CalculateHitTest(AInfo) then
      Break;
  end;
end;

procedure TACLCompoundControlContainerViewInfo.DoDraw(ACanvas: TCanvas);
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

procedure TACLCompoundControlContainerViewInfo.DoDrawCells(ACanvas: TCanvas);
var
  I: Integer;
begin
  for I := 0 to ChildCount - 1 do
    Children[I].Draw(ACanvas);
end;

function TACLCompoundControlContainerViewInfo.GetChildCount: Integer;
begin
  Result := FChildren.Count;
end;

function TACLCompoundControlContainerViewInfo.GetChild(Index: Integer): TACLCompoundControlCustomViewInfo;
begin
  Result := TACLCompoundControlCustomViewInfo(FChildren.List[Index]);
end;

{ TACLCompoundControlDragWindow }

constructor TACLCompoundControlDragWindow.Create(AOwner: TWinControl);
begin
  CreateNew(AOwner);
  FControl := AOwner;
  FBitmap := TACLDib.Create(0, 0);
  AlphaBlend := True;
  AlphaBlendValue := 200;
  BorderStyle := bsNone;
  Visible := False;
end;

destructor TACLCompoundControlDragWindow.Destroy;
begin
  FreeAndNil(FBitmap);
  inherited Destroy;
end;

procedure TACLCompoundControlDragWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WndParent := FControl.Handle;
  Params.ExStyle := WS_EX_NOACTIVATE;
  Params.Style := WS_POPUP;
end;

procedure TACLCompoundControlDragWindow.Paint;
begin
  FBitmap.DrawCopy(Canvas.Handle, NullPoint);
end;

procedure TACLCompoundControlDragWindow.SetBitmap(ABitmap: TACLDib; AMaskByBitmap: Boolean);
begin
  FBitmap.Assign(ABitmap);
  SetBounds(Left, Top, FBitmap.Width, FBitmap.Height);
  if AMaskByBitmap then
    SetWindowRgn(Handle, acRegionFromBitmap(FBitmap), False);
end;

procedure TACLCompoundControlDragWindow.SetVisible(AValue: Boolean);
const
  ShowFlags: array[Boolean] of Integer = (SWP_HIDEWINDOW, SWP_SHOWWINDOW);
begin
  SetWindowPos(Handle, 0, 0, 0, 0, 0, ShowFlags[AValue] or SWP_NOSIZE or SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE);
end;

procedure TACLCompoundControlDragWindow.WndProc(var Message: TMessage);
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

{ TACLCompoundControlDragObject }

destructor TACLCompoundControlDragObject.Destroy;
begin
  FreeAndNil(FDragTargetZoneWindow);
  FreeAndNil(FDragWindow);
  inherited Destroy;
end;

procedure TACLCompoundControlDragObject.DragFinished(ACanceled: Boolean);
begin
  // do nothing
end;

procedure TACLCompoundControlDragObject.Draw(ACanvas: TCanvas);
begin
  // do nothing
end;

function TACLCompoundControlDragObject.TransformPoint(const P: TPoint): TPoint;
begin
  Result := P;
end;

procedure TACLCompoundControlDragObject.CreateAutoScrollTimer;
begin
  FController.CreateAutoScrollTimer;
end;

procedure TACLCompoundControlDragObject.InitializeDragWindow(ASourceViewInfo: TACLCompoundControlCustomViewInfo);
var
  ABitmap: TACLDib;
begin
  if DragWindow = nil then
    FDragWindow := TACLCompoundControlDragWindow.Create(SubClass.Container.GetControl);

  ABitmap := TACLDib.Create(ASourceViewInfo.Bounds);
  try
    SubClass.StyleHint.Draw(ABitmap.Canvas, ABitmap.ClientRect);
    ASourceViewInfo.DrawTo(ABitmap.Canvas, 0, 0);
    DragWindow.SetBitmap(ABitmap, True);
    DragWindow.BoundsRect := SubClass.ClientToScreen(ASourceViewInfo.Bounds);
    DragWindow.SetVisible(True);
  finally
    ABitmap.Free;
  end;
end;

procedure TACLCompoundControlDragObject.StartDropSource(
  AActions: TACLDropSourceActions; ASource: IACLDropSourceOperation; ASourceObject: TObject);
begin
  FController.StartDropSource(AActions, ASource, ASourceObject);
end;

procedure TACLCompoundControlDragObject.UpdateAutoScrollDirection(ADelta: Integer);
begin
  FController.UpdateAutoScrollDirection(ADelta);
end;

procedure TACLCompoundControlDragObject.UpdateAutoScrollDirection(const P: TPoint; const AArea: TRect);
begin
  if P.Y < AArea.Top then
    UpdateAutoScrollDirection(1)
  else if P.Y > AArea.Bottom then
    UpdateAutoScrollDirection(-1)
  else
    UpdateAutoScrollDirection(0);
end;

procedure TACLCompoundControlDragObject.UpdateDragTargetZoneWindow(
  const ATargetScreenBounds: TRect; AVertical: Boolean);

  function PrepareDragWindowBitmap: TACLDib;
  var
    LRect: TRect;
    LSize: TSize;
  begin
    if AVertical then
    begin
      LSize := acGetArrowSize(makBottom, 288);
      Result := TACLDib.Create(LSize.cx, 2 * LSize.cy + ATargetScreenBounds.Height);
      Result.Canvas.Brush.Color := clFuchsia;
      Result.Canvas.FillRect(Result.ClientRect);
      // Top
      LRect := TRect.Create(LSize);
      LRect.Offset(0, -1);
      acDrawArrow(Result.Canvas.Handle, LRect, clWhite, makBottom, 288);
      LRect.Inflate(-1);
      acDrawArrow(Result.Canvas.Handle, LRect, clBlack, makBottom, 192);
      // Bottom
      LRect := TRect.Create(LSize);
      LRect.Offset(0, Result.Height - LSize.cy);
      acDrawArrow(Result.Canvas.Handle, LRect, clWhite, makTop, 288);
      LRect.Inflate(-1);
      acDrawArrow(Result.Canvas.Handle, LRect, clBlack, makTop, 192);
    end
    else
    begin
      LSize := acGetArrowSize(makRight, 288);
      Result := TACLDib.Create(2 * LSize.cx + ATargetScreenBounds.Width, LSize.cy);
      Result.Canvas.Brush.Color := clFuchsia;
      Result.Canvas.FillRect(Result.ClientRect);
      // Left
      LRect := TRect.Create(LSize);
      LRect.Offset(-1, 0);
      acDrawArrow(Result.Canvas.Handle, LRect, clWhite, makRight, 288);
      LRect.Inflate(-1);
      acDrawArrow(Result.Canvas.Handle, LRect, clBlack, makRight, 192);
      // Bottom
      LRect := TRect.Create(LSize);
      LRect.Offset(Result.Width - LSize.cx, 0);
      acDrawArrow(Result.Canvas.Handle, LRect, clWhite, makLeft, 288);
      LRect.Inflate(-1);
      acDrawArrow(Result.Canvas.Handle, LRect, clBlack, makLeft, 192);
    end;
  end;

var
  ABitmap: TACLDib;
  AIsTargetAssigned: Boolean;
begin
  if (DragTargetScreenBounds <> ATargetScreenBounds) or (DragTargetZoneWindow = nil) then
  begin
    AIsTargetAssigned := not ATargetScreenBounds.IsEmpty;
    if DragTargetZoneWindow = nil then
      FDragTargetZoneWindow := TACLCompoundControlDragWindow.Create(SubClass.Container.GetControl);

    if AIsTargetAssigned then
    begin
      ABitmap := PrepareDragWindowBitmap;
      try
        DragTargetZoneWindow.SetBitmap(ABitmap, True);
        DragTargetZoneWindow.BoundsRect := ATargetScreenBounds.CenterTo(
          DragTargetZoneWindow.Width, DragTargetZoneWindow.Height);
      finally
        ABitmap.Free;
      end;
    end;
    DragTargetZoneWindow.SetVisible(AIsTargetAssigned);
    FDragTargetScreenBounds := ATargetScreenBounds;
  end;
end;

procedure TACLCompoundControlDragObject.UpdateDropTarget(ADropTarget: TACLDropTarget);
begin
  FController.UpdateDropTarget(ADropTarget);
end;

function TACLCompoundControlDragObject.GetCurrentDpi: Integer;
begin
  Result := SubClass.CurrentDpi;
end;

function TACLCompoundControlDragObject.GetCursor: TCursor;
begin
  Result := FController.Cursor;
end;

function TACLCompoundControlDragObject.GetHitTest: TACLHitTestInfo;
begin
  Result := FController.HitTest;
end;

function TACLCompoundControlDragObject.GetMouseCapturePoint: TPoint;
begin
  Result := FController.MouseCapturePoint;
end;

function TACLCompoundControlDragObject.GetSubClass: TACLCompoundControlSubClass;
begin
  Result := FController.SubClass;
end;

procedure TACLCompoundControlDragObject.SetCursor(AValue: TCursor);
begin
  FController.Cursor := AValue;
end;

{ TACLCompoundControlDragAndDropController }

constructor TACLCompoundControlDragAndDropController.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited Create(ASubClass);
  FDropSourceConfig := TACLIniFile.Create;
end;

destructor TACLCompoundControlDragAndDropController.Destroy;
begin
  Cancel;
  TACLObjectLinks.Release(Self);
  FreeAndNil(FDropTarget);
  FreeAndNil(FDropSourceConfig);
  inherited Destroy;
end;

procedure TACLCompoundControlDragAndDropController.Cancel;
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

procedure TACLCompoundControlDragAndDropController.Draw(ACanvas: TCanvas);
begin
  if DragObject <> nil then
    DragObject.Draw(ACanvas);
end;

procedure TACLCompoundControlDragAndDropController.MouseDown(AShift: TShiftState; X, Y: Integer);
begin
  FStarted := False;
  MouseCapturePoint := Point(X, Y);
  LastPoint := MouseCapturePoint;
end;

procedure TACLCompoundControlDragAndDropController.MouseMove(AShift: TShiftState; X, Y: Integer);
var
  ADeltaX, ADeltaY: Integer;
  APoint: TPoint;
begin
  if SubClass.MouseCapture and not IsActive and not FStarted and ([ssLeft, ssRight, ssMiddle] * AShift = [ssLeft]) then
  begin
    ADeltaX := X - MouseCapturePoint.X;
    ADeltaY := Y - MouseCapturePoint.Y;
    if acCanStartDragging(ADeltaX, ADeltaY, CurrentDpi) then
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

procedure TACLCompoundControlDragAndDropController.MouseUp(AShift: TShiftState; X, Y: Integer);
begin
  if not IsDropSourceOperation then
    Finish(False);
end;

procedure TACLCompoundControlDragAndDropController.ProcessChanges(AChanges: TIntegerSet);
begin
  // do nothing
end;

procedure TACLCompoundControlDragAndDropController.AutoScrollTimerHandler(Sender: TObject);
begin
  for var I := 0 to Abs(FAutoScrollTimer.Tag) - 1 do
  begin
    if FAutoScrollTimer.Tag < 0 then
      SubClass.MouseWheel(mwdDown, [])
    else
      SubClass.MouseWheel(mwdUp, []);
  end;
end;

procedure TACLCompoundControlDragAndDropController.CreateAutoScrollTimer;
begin
  if AutoScrollTimer = nil then
    FAutoScrollTimer := TACLTimer.CreateEx(AutoScrollTimerHandler, 100);
end;

procedure TACLCompoundControlDragAndDropController.UpdateAutoScrollDirection(ADelta: Integer);
begin
  if AutoScrollTimer <> nil then
  begin
    AutoScrollTimer.Tag := ADelta;
    AutoScrollTimer.Enabled := FAutoScrollTimer.Tag <> 0;
  end;
end;

function TACLCompoundControlDragAndDropController.CanStartDropSource(
  var AActions: TACLDropSourceActions; ASourceObject: TObject): Boolean;
begin
  Result := not SubClass.DoDropSourceBegin(AActions, DropSourceConfig);
end;

procedure TACLCompoundControlDragAndDropController.StartDropSource(
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

procedure TACLCompoundControlDragAndDropController.DropSourceBegin;
begin
  SubClass.UpdateHitTest(LastPoint);
  FDropSourceOperation.DropSourceBegin;
end;

procedure TACLCompoundControlDragAndDropController.DropSourceDrop(var AAllowDrop: Boolean);
begin
  FDropSourceOperation.DropSourceDrop(AAllowDrop);
end;

procedure TACLCompoundControlDragAndDropController.DropSourceEnd(AActions: TACLDropSourceActions; AShiftState: TShiftState);
begin
  FDropSourceOperation.DropSourceEnd(AActions, AShiftState);
  FDropSourceOperation := nil;
  FDropSourceObject := nil;
  Finish(AActions = []);
  SubClass.DoDropSourceFinish(AActions = [], AShiftState);
end;

function TACLCompoundControlDragAndDropController.CreateDefaultDropTarget: TACLDropTarget;
begin
  Result := nil;
end;

procedure TACLCompoundControlDragAndDropController.UpdateDropTarget(ADropTarget: TACLDropTarget);
begin
  if ADropTarget = nil then
    ADropTarget := CreateDefaultDropTarget;
  FreeAndNil(FDropTarget);
  FDropTarget := ADropTarget;
end;

function TACLCompoundControlDragAndDropController.DragStart: Boolean;
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

procedure TACLCompoundControlDragAndDropController.Finish(ACanceled: Boolean);
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

function TACLCompoundControlDragAndDropController.GetHitTest: TACLHitTestInfo;
begin
  Result := SubClass.HitTest;
end;

function TACLCompoundControlDragAndDropController.GetIsDropSourceOperation: Boolean;
begin
  Result := FDropSourceOperation <> nil;
end;

procedure TACLCompoundControlDragAndDropController.SetCursor(AValue: TCursor);
begin
  if FCursor <> AValue then
  begin
    FCursor := AValue;
    SubClass.UpdateCursor;
  end;
end;

{ TACLCompoundControlHintController }

constructor TACLCompoundControlHintController.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited Create;
  FSubClass := ASubClass;
end;

function TACLCompoundControlHintController.CreateHintWindow: TACLHintWindow;
begin
  Result := TACLCompoundControlHintControllerWindow.Create(Self);
end;

function TACLCompoundControlHintController.GetOwnerForm: TCustomForm;
var
  AControl: TWinControl;
begin
  AControl := SubClass.Container.GetControl;
  if AControl <> nil then
    Result := GetParentForm(AControl)
  else
    Result := nil;
end;

procedure TACLCompoundControlHintController.Update(AHitTest: TACLHitTestInfo);
begin
  inherited Update(AHitTest.HitObject, SubClass.ClientToScreen(AHitTest.HitPoint), AHitTest.HintData);
end;

{ TACLCompoundControlHintControllerWindow }

constructor TACLCompoundControlHintControllerWindow.Create(AController: TACLCompoundControlHintController);
begin
  inherited Create(nil);
  FController := AController;
  Font := FController.SubClass.Font;
  Style := FController.SubClass.StyleHint;
end;

procedure TACLCompoundControlHintControllerWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WndParent := FController.SubClass.Container.GetControl.Handle;
end;

procedure TACLCompoundControlHintControllerWindow.WMActivateApp(var Message: TWMActivateApp);
begin
  inherited;
  if not Message.Active then
    FController.Cancel;
end;

{$ENDREGION}

{$REGION ' Content Cells '}

{ TACLCompoundControlBaseContentCell }

constructor TACLCompoundControlBaseContentCell.Create(AData: TObject; AViewInfo: TACLCompoundControlBaseContentCellViewInfo);
begin
  inherited Create;
  FData := AData;
  FViewInfo := AViewInfo;
end;

procedure TACLCompoundControlBaseContentCell.CalculateHitTest(AInfo: TACLHitTestInfo);
begin
  ViewInfo.CalculateHitTest(Data, Bounds, AInfo);
end;

procedure TACLCompoundControlBaseContentCell.Draw(ACanvas: TCanvas);
begin
  ViewInfo.Draw(ACanvas, Data, Bounds);
end;

function TACLCompoundControlBaseContentCell.MeasureHeight: Integer;
begin
  ViewInfo.Initialize(Data);
  Result := ViewInfo.MeasureHeight;
end;

function TACLCompoundControlBaseContentCell.GetClientBounds: TRect;
begin
  Result := System.Types.Bounds(0, Top, ViewInfo.Owner.GetContentWidth, Height);
end;

function TACLCompoundControlBaseContentCell.GetBounds: TRect;
begin
  Result := GetClientBounds + ViewInfo.Owner.GetViewItemsOrigin;
end;

{ TACLCompoundControlBaseContentCellViewInfo }

constructor TACLCompoundControlBaseContentCellViewInfo.Create(AOwner: IACLCompoundControlSubClassContent);
begin
  FOwner := AOwner;
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Calculate;
begin
  Calculate(FWidth, FHeight);
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Calculate(AWidth, AHeight: Integer);
begin
  FWidth := AWidth;
  FHeight := AHeight;
end;

procedure TACLCompoundControlBaseContentCellViewInfo.CalculateHitTest(
  AData: TObject; const ABounds: TRect; AInfo: TACLHitTestInfo);
begin
  Initialize(AData, ABounds.Height);
  AInfo.HitObject := AData;
  AInfo.HitObjectData[cchdViewInfo] := Self;
  DoGetHitTest(AInfo.HitPoint - ABounds.TopLeft, ABounds.TopLeft, AInfo);
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Draw(
  ACanvas: TCanvas; AData: TObject; const ABounds: TRect);
begin
  MoveWindowOrg(ACanvas.Handle, ABounds.Left, ABounds.Top);
  try
    Initialize(AData, ABounds.Height);
    DoDraw(ACanvas);
    if HasFocusRect then
      acDrawFocusRect(ACanvas, GetFocusRect, GetFocusRectColor);
  finally
    MoveWindowOrg(ACanvas.Handle, -ABounds.Left, -ABounds.Top);
  end;
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Initialize(AData: TObject);
begin
  FData := AData;
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Initialize(AData: TObject; AHeight: Integer);
begin
  FHeight := AHeight;
  Initialize(AData);
end;

function TACLCompoundControlBaseContentCellViewInfo.MeasureHeight: Integer;
begin
  Result := Bounds.Height;
end;

procedure TACLCompoundControlBaseContentCellViewInfo.DoGetHitTest(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo);
begin
  // do nothing
end;

function TACLCompoundControlBaseContentCellViewInfo.GetFocusRect: TRect;
begin
  Result := Bounds;
end;

function TACLCompoundControlBaseContentCellViewInfo.GetFocusRectColor: TColor;
begin
  Result := clDefault;
end;

function TACLCompoundControlBaseContentCellViewInfo.HasFocusRect: Boolean;
begin
  Result := False;
end;

function TACLCompoundControlBaseContentCellViewInfo.GetBounds: TRect;
begin
  Result := Rect(0, 0, FWidth, FHeight);
end;

{ TACLCompoundControlBaseCheckableContentCellViewInfo }

procedure TACLCompoundControlBaseCheckableContentCellViewInfo.DoGetHitTest(
  const P, AOrigin: TPoint; AInfo: TACLHitTestInfo);
begin
  if PtInRect(CheckBoxRect, P) and IsCheckBoxEnabled then
  begin
    AInfo.Cursor := crHandPoint;
    AInfo.IsCheckable := True;
    AInfo.HitObjectData[cchdSubPart] := TObject(cchtCheckable);
  end
  else
    if ExpandButtonVisible and PtInRect(ExpandButtonRect, P) then
    begin
      AInfo.Cursor := crHandPoint;
      AInfo.IsExpandable := True;
    end;
end;

function TACLCompoundControlBaseCheckableContentCellViewInfo.IsCheckBoxEnabled: Boolean;
begin
  Result := True;
end;

{ TACLCompoundControlContentCellList }

constructor TACLCompoundControlContentCellList<T>.Create(AOwner: IACLCompoundControlSubClassContent);
begin
  inherited Create;
  FLastVisible := -1;
  FOwner := AOwner;
  FCellClass := TACLCompoundControlBaseContentCellClass(T);
end;

function TACLCompoundControlContentCellList<T>.Add(
  AData: TObject; AViewInfo: TACLCompoundControlBaseContentCellViewInfo): T;
begin
  Result := T(FCellClass.Create(AData, AViewInfo));
  inherited Add(Result);
end;

function TACLCompoundControlContentCellList<T>.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
var
  I: Integer;
begin
  for I := FirstVisible to LastVisible do
    if PtInRect(List[I].Bounds, AInfo.HitPoint) then
    begin
      List[I].CalculateHitTest(AInfo);
      Exit(True);
    end;
  Result := False;
end;

procedure TACLCompoundControlContentCellList<T>.Clear;
begin
  inherited Clear;
  UpdateVisibleBounds;
end;

procedure TACLCompoundControlContentCellList<T>.Draw(ACanvas: TCanvas);
var
  ASaveIndex: HRGN;
  I: Integer;
begin
  ASaveIndex := acSaveClipRegion(ACanvas.Handle);
  try
    if acIntersectClipRegion(ACanvas.Handle, GetClipRect) then
    begin
      for I := FirstVisible to LastVisible do
        List[I].Draw(ACanvas);
    end;
  finally
    acRestoreClipRegion(ACanvas.Handle, ASaveIndex);
  end;
end;

function TACLCompoundControlContentCellList<T>.Find(AData: TObject; out ACell: T): Boolean;
var
  I: Integer;
begin
  if AData <> nil then
    for I := 0 to Count - 1 do
      if List[I].Data = AData then
      begin
        ACell := List[I];
        Exit(True);
      end;
  Result := False;
end;

function TACLCompoundControlContentCellList<T>.FindFirstVisible(
  AStartFromIndex: Integer; ADirection: Integer; ADataClass: TClass; out ACell: T): Boolean;
var
  AIndex: Integer;
begin
  ACell := nil;
  AIndex := AStartFromIndex;
  while (AIndex <> -1) and (AIndex >= FirstVisible) and (AIndex <= LastVisible) do
  begin
    if Items[AIndex].Data is ADataClass then
    begin
      ACell := Items[AIndex];
      Break;
    end;
    Inc(AIndex, ADirection);
  end;
  Result := ACell <> nil;
end;

function TACLCompoundControlContentCellList<T>.GetCell(
  Index: Integer; out ACell: TACLCompoundControlBaseContentCell): Boolean;
begin
  Result := (Index >= 0) and (Index < Count);
  if Result then
    ACell := Items[Index];
end;

function TACLCompoundControlContentCellList<T>.GetClipRect: TRect;
begin
  Result := FOwner.GetViewItemsArea;
end;

function TACLCompoundControlContentCellList<T>.GetContentSize: Integer;
begin
  if Count > 0 then
    Result := Last.Bounds.Bottom - First.Bounds.Top
  else
    Result := 0;
end;

procedure TACLCompoundControlContentCellList<T>.UpdateVisibleBounds;
var
  ACell: TACLCompoundControlBaseContentCell;
  I: Integer;
  R: TRect;
begin
  R := FOwner.GetViewItemsArea;
  R.Offset(0, -FOwner.GetViewItemsOrigin.Y);

  FFirstVisible := Count;
  for I := 0 to Count - 1 do
  begin
    ACell := List[I];
    if ACell.Top + ACell.Height > R.Top then
    begin
      FFirstVisible := I;
      Break;
    end;
  end;

  FLastVisible := Count - 1;
  for I := Count - 1 downto FFirstVisible do
    if List[I].Top < R.Bottom then
    begin
      FLastVisible := I;
      Break;
    end;
end;

{ TACLCompoundControlContentCellList }

constructor TACLCompoundControlContentCellList.Create(
  AOwner: IACLCompoundControlSubClassContent; ACellClass: TACLCompoundControlBaseContentCellClass);
begin
  inherited Create(AOwner);
  FCellClass := ACellClass;
end;

{$ENDREGION}

{$REGION ' Scrollable Contaner '}

{ TACLScrollInfo }

function TACLScrollInfo.InvisibleArea: Integer;
begin
  Result := Range - Page;
end;

function TACLScrollInfo.Range: Integer;
begin
  Result := Max - Min + 1;
end;

procedure TACLScrollInfo.Reset;
begin
  ZeroMemory(@Self, SizeOf(Self));
end;

{ TACLCompoundControlScrollBarViewInfo }

constructor TACLCompoundControlScrollBarViewInfo.Create(ASubClass: TACLCompoundControlSubClass; AKind: TScrollBarKind);
begin
  inherited Create(ASubClass);
  FKind := AKind;
end;

destructor TACLCompoundControlScrollBarViewInfo.Destroy;
begin
  FreeAndNil(FScrollTimer);
  inherited Destroy;
end;

function TACLCompoundControlScrollBarViewInfo.IsThumbResizable: Boolean;
begin
  Result := Style.IsThumbResizable(Kind);
end;

function TACLCompoundControlScrollBarViewInfo.MeasureSize: Integer;
begin
  if not Visible then
    Result := 0
  else
    if Kind = sbVertical then
      Result := Style.TextureBackgroundVert.FrameWidth
    else
      Result := Style.TextureBackgroundHorz.FrameHeight;
end;

procedure TACLCompoundControlScrollBarViewInfo.SetParams(const AScrollInfo: TACLScrollInfo);
begin
  FScrollInfo := AScrollInfo;
  if not IsThumbResizable then
  begin
    Dec(FScrollInfo.Max, FScrollInfo.Page);
    FScrollInfo.Page := 0;
  end;
  FVisible := FScrollInfo.Page + 1 < FScrollInfo.Range;
  Calculate(Bounds, [cccnLayout]);
end;

function TACLCompoundControlScrollBarViewInfo.CalculateScrollDelta(const P: TPoint): Integer;
var
  ADelta: TPoint;
begin
  ADelta := P - ThumbnailViewInfo.Bounds.CenterPoint;
  if Kind = sbHorizontal then
    Result := Sign(ADelta.X) * Min(Abs(ADelta.X), FPageSizeInPixels)
  else
    Result := Sign(ADelta.Y) * Min(Abs(ADelta.Y), FPageSizeInPixels);
end;

procedure TACLCompoundControlScrollBarViewInfo.DoCalculate(AChanges: TIntegerSet);
var
  ASize: Integer;
  R1: TRect;
  R2: TRect;
begin
  inherited DoCalculate(AChanges);
  if ChildCount = 0 then
    RecreateSubCells;
  if Visible and ([cccnLayout, cccnStruct] * AChanges <> []) and (ChildCount = 3) then
  begin
    if Kind = sbVertical then
    begin
      FThumbExtends := Style.TextureThumbVert.ContentOffsets;
      FThumbExtends.Right := 0;
      FThumbExtends.Left := 0;

      R2 := Bounds;
      R1 := R2.Split(srBottom, Style.TextureButtonsVert.FrameHeight);
      Children[0].Calculate(R1, [cccnLayout]);
      R2.Bottom := R1.Top;

      R1 := R2;
      R1.Height := Style.TextureButtonsVert.FrameHeight;
      Children[1].Calculate(R1, [cccnLayout]);
      R2.Top := R1.Bottom;

      FPageSizeInPixels := Max(MulDiv(ScrollInfo.Page, R2.Height, ScrollInfo.Range), 1);
      ASize := MaxMin(R2.Height, FPageSizeInPixels, Style.TextureThumbVert.FrameHeight - FThumbExtends.MarginsHeight);
      Dec(R2.Bottom, ASize);
      FTrackArea := R2;
      R1 := R2;
      R1.Height := ASize;
      ASize := ScrollInfo.InvisibleArea;
      R1.Offset(0, MulDiv(R2.Height, Min(ScrollInfo.Position - ScrollInfo.Min, ASize), ASize));
    end
    else
    begin
      FThumbExtends := Style.TextureThumbHorz.ContentOffsets;
      FThumbExtends.Bottom := 0;
      FThumbExtends.Top := 0;

      R2 := Bounds;
      R1 := R2.Split(srRight, Style.TextureButtonsHorz.FrameWidth);
      Children[0].Calculate(R1, [cccnLayout]);
      R2.Right := R1.Left;

      R1 := R2;
      R1.Width := Style.TextureButtonsHorz.FrameWidth;
      Children[1].Calculate(R1, [cccnLayout]);
      R2.Left := R1.Right;

      FPageSizeInPixels := Max(MulDiv(ScrollInfo.Page, R2.Width, ScrollInfo.Range), 1);
      ASize := MaxMin(R2.Width, FPageSizeInPixels, Style.TextureThumbHorz.FrameWidth - FThumbExtends.MarginsWidth);
      Dec(R2.Right, ASize);
      FTrackArea := R2;
      R1 := R2;
      R1.Width := ASize;
      ASize := ScrollInfo.InvisibleArea;
      R1.Offset(MulDiv(R2.Width, Min(ScrollInfo.Position - ScrollInfo.Min, ASize), ASize), 0);
    end;
    R1.Inflate(FThumbExtends);
    Children[2].Calculate(R1, [cccnLayout]);
  end;
end;

procedure TACLCompoundControlScrollBarViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
begin
  inherited;
  AInfo.IsNonClient := True;
end;

procedure TACLCompoundControlScrollBarViewInfo.DoDraw(ACanvas: TCanvas);
begin
  Style.DrawBackground(ACanvas, Bounds, Kind);
  inherited DoDraw(ACanvas);
end;

procedure TACLCompoundControlScrollBarViewInfo.RecreateSubCells;
begin
  FChildren.Add(TACLCompoundControlScrollBarButtonViewInfo.Create(Self, sbpLineDown));
  FChildren.Add(TACLCompoundControlScrollBarButtonViewInfo.Create(Self, sbpLineUp));
  FChildren.Add(TACLCompoundControlScrollBarThumbnailViewInfo.Create(Self, sbpThumbnail));
end;

procedure TACLCompoundControlScrollBarViewInfo.Scroll(APosition: Integer);
begin
  if Assigned(OnScroll) then
    OnScroll(Self, APosition);
end;

procedure TACLCompoundControlScrollBarViewInfo.ScrollTo(const P: TPoint);
var
  ADelta: TPoint;
  ADragObject: TACLCompoundControlDragObject;
begin
  ADelta := P - ThumbnailViewInfo.Bounds.CenterPoint;
  if ADelta = NullPoint then
    Exit;

  ADragObject := ThumbnailViewInfo.CreateDragObject(nil);
  try
    if ADragObject.DragStart then
    begin
      ADragObject.DragMove(P, ADelta.X, ADelta.Y);
      ADragObject.DragFinished(False);
    end;
  finally
    ADragObject.Free;
  end;
end;

procedure TACLCompoundControlScrollBarViewInfo.ScrollToMouseCursor(const AInitialDelta: Integer);
var
  ACenter: TPoint;
  ADelta: Integer;
begin
  if HitTest.HitObject <> Self then
    Exit;

  ADelta := CalculateScrollDelta(HitTest.HitPoint);
  if Sign(ADelta) <> Sign(AInitialDelta) then
    Exit;

  ACenter := ThumbnailViewInfo.Bounds.CenterPoint;
  if Kind = sbHorizontal then
    Inc(ACenter.X, ADelta)
  else
    Inc(ACenter.Y, ADelta);

  ScrollTo(ACenter);
end;

procedure TACLCompoundControlScrollBarViewInfo.MouseDown(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
var
  ADelta: Integer;
begin
  if (AButton = mbLeft) and (ssShift in AShift) or (AButton = mbMiddle) then
    ScrollTo(AHitTestInfo.HitPoint)
  else
    if AButton = mbLeft then
    begin
      FreeAndNil(FScrollTimer);
      ADelta := CalculateScrollDelta(AHitTestInfo.HitPoint);
      if ADelta <> 0 then
      begin
        FScrollTimer := TACLTimer.CreateEx(ScrollTimerHandler, acScrollBarTimerInitialDelay, True);
        FScrollTimer.Tag := ADelta;
        ScrollTimerHandler(nil);
      end;
    end;
end;

procedure TACLCompoundControlScrollBarViewInfo.MouseUp(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
begin
  FreeAndNil(FScrollTimer);
end;

procedure TACLCompoundControlScrollBarViewInfo.ScrollTimerHandler(Sender: TObject);
begin
  if ssLeft in KeyboardStateToShiftState then
  begin
    FScrollTimer.Interval := acScrollBarTimerScrollInterval;
    ScrollToMouseCursor(FScrollTimer.Tag);
  end
  else
    FreeAndNil(FScrollTimer);
end;

function TACLCompoundControlScrollBarViewInfo.GetHitTest: TACLHitTestInfo;
begin
  Result := SubClass.HitTest;
end;

function TACLCompoundControlScrollBarViewInfo.GetStyle: TACLStyleScrollBox;
begin
  Result := SubClass.StyleScrollBox;
end;

function TACLCompoundControlScrollBarViewInfo.GetThumbnailViewInfo: TACLCompoundControlScrollBarThumbnailViewInfo;
begin
  Result := Children[2] as TACLCompoundControlScrollBarThumbnailViewInfo;
end;

{ TACLCompoundControlScrollBarPartViewInfo }

constructor TACLCompoundControlScrollBarPartViewInfo.Create(
  AOwner: TACLCompoundControlScrollBarViewInfo; APart: TACLScrollBarPart);
begin
  inherited Create(AOwner.SubClass);
  FOwner := AOwner;
  FPart := APart;
end;

destructor TACLCompoundControlScrollBarPartViewInfo.Destroy;
begin
  AnimationManager.RemoveOwner(Self);
  inherited Destroy;
end;

procedure TACLCompoundControlScrollBarPartViewInfo.Scroll(APosition: Integer);
begin
  Owner.Scroll(APosition);
end;

procedure TACLCompoundControlScrollBarPartViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
begin
  inherited;
  AInfo.IsNonClient := True;
end;

procedure TACLCompoundControlScrollBarPartViewInfo.DoDraw(ACanvas: TCanvas);
begin
  if not AnimationManager.Draw(Self, ACanvas, Bounds) then
    Style.DrawPart(ACanvas, Bounds, Part, ActualState, Kind);
end;

procedure TACLCompoundControlScrollBarPartViewInfo.UpdateState;
begin
  if SubClass.PressedObject = Self then
    State := absPressed
  else if SubClass.HoveredObject = Self then
    State := absHover
  else
    State := absNormal;
end;

procedure TACLCompoundControlScrollBarPartViewInfo.MouseDown(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
begin
  UpdateState;
end;

procedure TACLCompoundControlScrollBarPartViewInfo.MouseUp(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
begin
  UpdateState;
end;

procedure TACLCompoundControlScrollBarPartViewInfo.OnHotTrack(Action: TACLHotTrackAction);
begin
  UpdateState;
end;

function TACLCompoundControlScrollBarPartViewInfo.GetActualState: TACLButtonState;
begin
  if SubClass.EnabledContent then
    Result := State
  else
    Result := absDisabled;
end;

function TACLCompoundControlScrollBarPartViewInfo.GetKind: TScrollBarKind;
begin
  Result := Owner.Kind;
end;

function TACLCompoundControlScrollBarPartViewInfo.GetStyle: TACLStyleScrollBox;
begin
  Result := Owner.Style;
end;

procedure TACLCompoundControlScrollBarPartViewInfo.SetState(AValue: TACLButtonState);
var
  AAnimator: TACLBitmapFadingAnimation;
begin
  if AValue <> FState then
  begin
    AnimationManager.RemoveOwner(Self);

    if acUIFadingEnabled and (AValue = absNormal) and (FState = absHover) then
    begin
      AAnimator := TACLBitmapFadingAnimation.Create(Self, acUIFadingTime);
      DrawTo(AAnimator.AllocateFrame1(Bounds).Canvas, 0, 0);
      FState := AValue;
      DrawTo(AAnimator.AllocateFrame2(Bounds).Canvas, 0, 0);
      AAnimator.Run;
    end
    else
      FState := AValue;

    Invalidate;
  end;
end;

{ TACLCompoundControlScrollBarButtonViewInfo }

procedure TACLCompoundControlScrollBarButtonViewInfo.Click;
begin
  case Part of
    sbpLineDown:
      Scroll(Owner.ScrollInfo.Position + Owner.ScrollInfo.LineSize);
    sbpLineUp:
      Scroll(Owner.ScrollInfo.Position - Owner.ScrollInfo.LineSize);
  end;
end;

procedure TACLCompoundControlScrollBarButtonViewInfo.MouseDown(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
begin
  if AButton = mbLeft then
  begin
    Click;
    FTimer := TACLTimer.CreateEx(TimerHandler, acScrollBarTimerInitialDelay, True);
  end;
  inherited MouseDown(AButton, AShift, AHitTestInfo);
end;

procedure TACLCompoundControlScrollBarButtonViewInfo.MouseUp(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
begin
  FreeAndNil(FTimer);
  inherited MouseUp(AButton, AShift, AHitTestInfo);
end;

procedure TACLCompoundControlScrollBarButtonViewInfo.TimerHandler(Sender: TObject);
begin
  FTimer.Interval := acScrollBarTimerScrollInterval;
  Click;
end;

{ TACLCompoundControlScrollBarThumbnailDragObject }

constructor TACLCompoundControlScrollBarThumbnailDragObject.Create(
  AOwner: TACLCompoundControlScrollBarPartViewInfo);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TACLCompoundControlScrollBarThumbnailDragObject.DragStart: Boolean;
begin
  FSavedBounds := Owner.Bounds;
  FSavedPosition := Owner.Owner.ScrollInfo.Position;
  Result := True;
end;

procedure TACLCompoundControlScrollBarThumbnailDragObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);

  procedure CheckDeltas(var ADeltaX, ADeltaY: Integer; APosition, ALeftBound, ARightBound: Integer);
  begin
    ADeltaY := 0;
    if ADeltaX + APosition < ALeftBound then
      ADeltaX := ALeftBound - APosition;
    if ADeltaX + APosition > ARightBound then
      ADeltaX := ARightBound - APosition;
  end;

  function CalculatePosition(APosition, ALeftBound, ARightBound: Integer): Integer;
  begin
    Result := Owner.Owner.ScrollInfo.Min + MulDiv(Owner.Owner.ScrollInfo.InvisibleArea,
      APosition - ALeftBound, ARightBound - ALeftBound);
  end;

var
  R: TRect;
begin
  R := Owner.Bounds;
  R.Content(Owner.Owner.ThumbExtends);
  if Owner.Kind = sbHorizontal then
    CheckDeltas(ADeltaX, ADeltaY, R.Left, TrackArea.Left, TrackArea.Right)
  else
    CheckDeltas(ADeltaY, ADeltaX, R.Top, TrackArea.Top, TrackArea.Bottom);

  if PtInRect(Owner.Owner.Bounds.InflateTo(acScrollBarHitArea), P) then
  begin
    R.Offset(ADeltaX, ADeltaY);

    if Owner.Kind = sbHorizontal then
      Owner.Scroll(CalculatePosition(R.Left, TrackArea.Left, TrackArea.Right))
    else
      Owner.Scroll(CalculatePosition(R.Top, TrackArea.Top, TrackArea.Bottom));

    R.Inflate(Owner.Owner.ThumbExtends);
    Owner.Calculate(R, [cccnLayout]);
  end
  else
  begin
    ADeltaX := FSavedBounds.Left - Owner.Bounds.Left;
    ADeltaY := FSavedBounds.Top - Owner.Bounds.Top;

    Owner.Scroll(FSavedPosition);
    Owner.Calculate(FSavedBounds, [cccnLayout]);
  end;
  Owner.Owner.Invalidate;
end;

procedure TACLCompoundControlScrollBarThumbnailDragObject.DragFinished(ACanceled: Boolean);
begin
  if ACanceled then
    Owner.Scroll(FSavedPosition);
  Owner.UpdateState;
end;

function TACLCompoundControlScrollBarThumbnailDragObject.GetTrackArea: TRect;
begin
  Result := Owner.Owner.TrackArea;
end;

{ TACLCompoundControlScrollBarThumbnailViewInfo }

function TACLCompoundControlScrollBarThumbnailViewInfo.CreateDragObject(
  const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
begin
  Result := TACLCompoundControlScrollBarThumbnailDragObject.Create(Self);
end;

{ TACLCompoundControlViewInfo }

constructor TACLCompoundControlScrollContainerViewInfo.Create(AOwner: TACLCompoundControlSubClass);
begin
  inherited Create(AOwner);
  FScrollBarHorz := CreateScrollBar(sbHorizontal);
  FScrollBarHorz.OnScroll := ScrollHorzHandler;
  FScrollBarVert := CreateScrollBar(sbVertical);
  FScrollBarVert.OnScroll := ScrollVertHandler;
end;

destructor TACLCompoundControlScrollContainerViewInfo.Destroy;
begin
  FreeAndNil(FScrollBarHorz);
  FreeAndNil(FScrollBarVert);
  inherited Destroy;
end;

procedure TACLCompoundControlScrollContainerViewInfo.Calculate(const R: TRect; AChanges: TIntegerSet);
begin
  inherited Calculate(R, AChanges);
  if [cccnLayout, cccnStruct] * AChanges <> [] then
    CalculateContentLayout;
  if [cccnViewport, cccnLayout, cccnStruct] * AChanges <> [] then
    UpdateScrollBars;
end;

function TACLCompoundControlScrollContainerViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  Result := ScrollBarHorz.CalculateHitTest(AInfo) or ScrollBarVert.CalculateHitTest(AInfo) or inherited CalculateHitTest(AInfo);
end;

procedure TACLCompoundControlScrollContainerViewInfo.ScrollByMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);
var
  ACount: Integer;
begin
  ACount := TACLMouseWheel.GetScrollLines(AShift);
  while ACount > 0 do
  begin
    if ssShift in AShift then
      ScrollHorizontally(TACLMouseWheel.DirectionToScrollCode[ADirection])
    else
      ScrollVertically(TACLMouseWheel.DirectionToScrollCode[ADirection]);

    Dec(ACount);
  end
end;

procedure TACLCompoundControlScrollContainerViewInfo.ScrollHorizontally(const AScrollCode: TScrollCode);
begin
  ViewportX := ScrollViewport(sbHorizontal, AScrollCode);
end;

procedure TACLCompoundControlScrollContainerViewInfo.ScrollVertically(const AScrollCode: TScrollCode);
begin
  ViewportY := ScrollViewport(sbVertical, AScrollCode);
end;

function TACLCompoundControlScrollContainerViewInfo.CreateScrollBar(
  AKind: TScrollBarKind): TACLCompoundControlScrollBarViewInfo;
begin
  Result := TACLCompoundControlScrollBarViewInfo.Create(SubClass, AKind);
end;

function TACLCompoundControlScrollContainerViewInfo.GetScrollInfo(
  AKind: TScrollBarKind; out AInfo: TACLScrollInfo): Boolean;
begin
  AInfo.Reset;
  AInfo.LineSize := 5;
  case AKind of
    sbVertical:
      begin
        AInfo.Position := ViewportY;
        AInfo.Max := ContentSize.cy - 1;
        AInfo.Page := ClientBounds.Height;
      end;

    sbHorizontal:
      begin
        AInfo.Page := ClientBounds.Width;
        AInfo.Max := ContentSize.cx - 1;
        AInfo.Position := ViewportX;
      end;
  end;
  Result := (AInfo.Max >= AInfo.Page) and (AInfo.Max > AInfo.Min);
end;

function TACLCompoundControlScrollContainerViewInfo.ScrollViewport(
  AKind: TScrollBarKind; AScrollCode: TScrollCode): Integer;
var
  AInfo: TACLScrollInfo;
begin
  Result := 0;
  if GetScrollInfo(AKind, AInfo) then
    case AScrollCode of
      scLineUp:
        Result := AInfo.Position - AInfo.LineSize;
      scLineDown:
        Result := AInfo.Position + AInfo.LineSize;
      scPageUp:
        Result := AInfo.Position - Integer(AInfo.Page);
      scPageDown:
        Result := AInfo.Position + Integer(AInfo.Page);
      scTop:
        Result := AInfo.Min;
      scBottom:
        Result := AInfo.Max;
    end;
end;

procedure TACLCompoundControlScrollContainerViewInfo.CalculateScrollBar(
  AScrollBar: TACLCompoundControlScrollBarViewInfo);
var
  AScrollInfo: TACLScrollInfo;
begin
  if not GetScrollInfo(AScrollBar.Kind, AScrollInfo) then
    AScrollInfo.Reset;
  AScrollBar.SetParams(AScrollInfo);
end;

procedure TACLCompoundControlScrollContainerViewInfo.CalculateScrollBarsPosition(var R: TRect);
var
  R1: TRect;
begin
  R1 := R;
  R1.Top := R1.Bottom - ScrollBarHorz.MeasureSize;
  Dec(R1.Right, ScrollBarVert.MeasureSize);
  ScrollBarHorz.Calculate(R1, [cccnLayout]);

  R1 := R;
  R1.Left := R1.Right - ScrollBarVert.MeasureSize;
  Dec(R1.Bottom, ScrollBarHorz.MeasureSize);
  ScrollBarVert.Calculate(R1, [cccnLayout]);

  FSizeGripArea := ScrollBarVert.Bounds;
  FSizeGripArea.Bottom := ScrollBarHorz.Bounds.Bottom;
  FSizeGripArea.Top := ScrollBarHorz.Bounds.Top;

  Dec(R.Bottom, ScrollBarHorz.Bounds.Height);
  Dec(R.Right, ScrollBarVert.Bounds.Width);
end;

procedure TACLCompoundControlScrollContainerViewInfo.CalculateSubCells(const AChanges: TIntegerSet);
begin
  FClientBounds := Bounds;
  CalculateScrollBarsPosition(FClientBounds);
end;

procedure TACLCompoundControlScrollContainerViewInfo.ContentScrolled(ADeltaX, ADeltaY: Integer);
begin
  SubClass.Changed([cccnViewport]);
  SubClass.Update;
end;

procedure TACLCompoundControlScrollContainerViewInfo.DoDraw(ACanvas: TCanvas);
begin
  inherited DoDraw(ACanvas);
  SubClass.StyleScrollBox.DrawSizeGripArea(ACanvas, SizeGripArea);
  ScrollBarHorz.Draw(ACanvas);
  ScrollBarVert.Draw(ACanvas);
end;

procedure TACLCompoundControlScrollContainerViewInfo.UpdateScrollBars;
var
  AVisibleScrollBars: TACLVisibleScrollBars;
begin
  AVisibleScrollBars := VisibleScrollBars;
  try
    CalculateScrollBar(ScrollBarHorz);
    CalculateScrollBar(ScrollBarVert);
    SetViewportX(FViewportX);
    SetViewportY(FViewportY);
  finally
    if AVisibleScrollBars <> VisibleScrollBars then
      Calculate(Bounds, [cccnLayout]);
  end;
end;

function TACLCompoundControlScrollContainerViewInfo.GetViewport: TPoint;
begin
  Result := Point(ViewportX, ViewportY);
end;

function TACLCompoundControlScrollContainerViewInfo.GetVisibleScrollBars: TACLVisibleScrollBars;
begin
  Result := [];
  if ScrollBarHorz.Visible then
    Include(Result, sbHorizontal);
  if ScrollBarVert.Visible then
    Include(Result, sbVertical);
end;

procedure TACLCompoundControlScrollContainerViewInfo.SetViewport(const AValue: TPoint);
begin
  ViewportX := AValue.X;
  ViewportY := AValue.Y;
end;

procedure TACLCompoundControlScrollContainerViewInfo.SetViewportX(AValue: Integer);
var
  ADelta: Integer;
begin
  AValue := MaxMin(AValue, 0, ContentSize.cx - ClientBounds.Width);
  if AValue <> FViewportX then
  begin
    ADelta := FViewportX - AValue;
    FViewportX := AValue;
    ContentScrolled(ADelta, 0);
  end;
end;

procedure TACLCompoundControlScrollContainerViewInfo.SetViewportY(AValue: Integer);
var
  ADelta: Integer;
begin
  AValue := MaxMin(AValue, 0, ContentSize.cy - ClientBounds.Height);
  if AValue <> FViewportY then
  begin
    ADelta := FViewportY - AValue;
    FViewportY := AValue;
    ContentScrolled(0, ADelta);
  end;
end;

procedure TACLCompoundControlScrollContainerViewInfo.ScrollHorzHandler(Sender: TObject; ScrollPos: Integer);
begin
  ViewportX := ScrollPos;
end;

procedure TACLCompoundControlScrollContainerViewInfo.ScrollVertHandler(Sender: TObject; ScrollPos: Integer);
begin
  ViewportY := ScrollPos;
end;

{$ENDREGION}

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
    if HitTest.IsNonClient then
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

function TACLCompoundControlSubClass.GetCurrentDpi: Integer;
begin
  Result := Container.GetCurrentDpi;
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
    SetHoveredObject(nil);
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

function TACLCompoundControlSubClass.CreateDragAndDropController: TACLCompoundControlDragAndDropController;
begin
  Result := TACLCompoundControlDragAndDropController.Create(Self);
end;

function TACLCompoundControlSubClass.CreateHintController: TACLCompoundControlHintController;
begin
  Result := TACLCompoundControlHintController.Create(Self);
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

function TACLCompoundControlSubClass.CalculateState(AObject: TObject; ASubPart: NativeInt = 0): TACLButtonState;
begin
  if not EnabledContent then
    Exit(absDisabled);
  if (ASubPart = 0) or (HoveredObjectSubPart = ASubPart) then
  begin
    if PressedObject = AObject then
      Exit(absPressed);
    if HoveredObject = AObject then
      Exit(absHover);
  end;
  Result := absNormal;
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
    SetHoveredObject(HitTest.HitObject, NativeInt(HitTest.HitObjectData[cchdSubPart]));
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
  SetHoveredObject(nil);
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

procedure TACLCompoundControlSubClass.SetHoveredObject(AObject: TObject; ASubPart: NativeInt = 0);
var
  AHotTrack: IACLHotTrackObject;
  APrevObject: TObject;
begin
  if FHoveredObject <> AObject then
  begin
    APrevObject := HoveredObject;
    FHoveredObject := AObject;
    FHoveredObjectSubPart := ASubPart;
    if Supports(APrevObject, IACLHotTrackObject, AHotTrack) then
      AHotTrack.OnHotTrack(htaLeave);
    if Supports(HoveredObject, IACLHotTrackObject, AHotTrack) then
      AHotTrack.OnHotTrack(htaEnter);
    DoHoveredObjectChanged;
  end
  else
    if FHoveredObjectSubPart <> ASubPart then
    begin
      FHoveredObjectSubPart := ASubPart;
      if Supports(HoveredObject, IACLHotTrackObject, AHotTrack) then
        AHotTrack.OnHotTrack(htaSwitchPart);
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
