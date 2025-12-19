////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   CompoundControl Classes
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.CompoundControl.SubClass;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Windows,
{$ENDIF}
  Messages,
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
  {Vcl.}StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.Math,
  ACL.MUI,
  ACL.Threading,
  ACL.Timers,
  ACL.UI.Animation,
  ACL.UI.Controls.Base,
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
    FBounds: TRect;
    FCalcHintData: Boolean;
    FCursor: TCursor;
    FData: TACLDictionary<string, Pointer>;
    FFlags: TACLListOfInteger;
    FHitObject: TObject;
    FPoint: TPoint;

    function GetData(const Index: string): Pointer;
    procedure SetData(const Index: string; const Value: Pointer);
  protected
    function GetFlag(Index: Integer): Boolean;
    procedure SetFlag(Index: Integer; const Value: Boolean);
  public
    HintData: TACLHintData;

    destructor Destroy; override;
    procedure AfterConstruction; override;
    function CreateDragObject: TACLCompoundControlDragObject; virtual;
    procedure Reset; virtual;

    property Bounds: TRect read FBounds write FBounds;
    property CalcHintData: Boolean read FCalcHintData write FCalcHintData;
    property Cursor: TCursor read FCursor write FCursor;
    property Data[const Index: string]: Pointer read GetData write SetData;
    property HitObject: TObject read FHitObject write FHitObject;
    property Point: TPoint read FPoint write FPoint;
    // Flags
    property Flags[Index: Integer]: Boolean read GetFlag write SetFlag;
    property IsCheckable: Boolean index cchtCheckable read GetFlag write SetFlag;
    property IsExpandable: Boolean index cchtExpandable read GetFlag write SetFlag;
    property IsNonClient: Boolean index cchtNonClient read GetFlag write SetFlag;
    property IsResizable: Boolean index cchtResizable read GetFlag write SetFlag;
  end;

{$ENDREGION}

  { IACLCheckableObject }

  IACLCheckableObject = interface
  ['{E86E50AD-E78A-48B2-BD46-63AB8D6E44BF}']
    function CanCheck: Boolean;
    function GetChecked: Boolean;
    procedure SetChecked(AValue: Boolean);
    // Properties
    property Checked: Boolean read GetChecked write SetChecked;
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
    // Properties
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
    procedure MouseDown(AButton: TMouseButton;
      AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
    procedure MouseUp(AButton: TMouseButton;
      AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
  end;

  { IACLSelectableObject }

  IACLSelectableObject = interface
  ['{BE88934C-23DB-4747-A804-54F883394E45}']
    function GetSelected: Boolean;
    procedure SetSelected(AValue: Boolean);
    //# Selection
    property Selected: Boolean read GetSelected write SetSelected;
  end;

  { IACLCompoundControlSubClassContainer }

  IACLCompoundControlSubClassContainer = interface(IACLControl)
  ['{3A39F1D5-E2FA-4DAC-98C7-067C97DDF79E}']
    function GetControl: TWinControl;
    function GetFocused: Boolean;
    procedure SetFocus;
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
    //# Properties
    property Bounds: TRect read FBounds;
  end;

  { TACLCompoundControlContainerViewInfo }

  TACLCompoundControlContainerViewInfo = class(TACLCompoundControlCustomViewInfo)
  strict private
    function GetChild(Index: Integer): TACLCompoundControlCustomViewInfo; inline;
    function GetChildCount: Integer; inline;
  protected
    FChildren: TACLObjectList;

    procedure AddCell(ACell: TACLCompoundControlCustomViewInfo; out AObj);
    procedure CalculateSubCells(const AChanges: TIntegerSet); virtual;
    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure DoDrawCells(ACanvas: TCanvas); virtual;
    procedure RecreateSubCells; virtual;
  public
    constructor Create(AOwner: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    //# Properties
    property ChildCount: Integer read GetChildCount;
    property Children[Index: Integer]: TACLCompoundControlCustomViewInfo read GetChild;
  end;

  { TACLCompoundControlDragObject }

  TACLCompoundControlDragObject = class(TACLUnknownObject)
  strict private
    FPreview: TACLBitmap;

    function GetCurrentDpi: Integer;
    function GetHitTest: TACLHitTestInfo;
    function GetMouseCapturePoint: TPoint;
    function GetSubClass: TACLCompoundControlSubClass;
  protected
    FController: TACLCompoundControlDragAndDropController;

    procedure DoAutoScroll(ADirection: TAlign); virtual;
    procedure InitializePreview(ASourceViewInfo: TACLCompoundControlCustomViewInfo);
    procedure StartDropSource(AActions: TACLDropSourceActions;
      ASource: IACLDropSourceOperation; ASourceObject: TObject); virtual;
    procedure UpdateAutoScrollDirection(const P: TPoint; const AArea: TRect);
    procedure UpdateCursor(ACursor: TCursor);
    procedure UpdateDropTarget(ADropTarget: TACLDropTarget);
  public
    destructor Destroy; override;
    procedure DragFinished(ACanceled: Boolean); virtual;
    procedure DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer); virtual; abstract;
    function DragStart: Boolean; virtual; abstract;
    procedure Draw(ACanvas: TCanvas); virtual;
    function TransformPoint(const P: TPoint): TPoint; virtual;
    //# Properties
    property CurrentDpi: Integer read GetCurrentDpi;
    property Preview: TACLBitmap read FPreview;
    property HitTest: TACLHitTestInfo read GetHitTest;
    property MouseCapturePoint: TPoint read GetMouseCapturePoint;
    property SubClass: TACLCompoundControlSubClass read GetSubClass;
  end;

  { TACLCompoundControlDragAndDropController }

  TACLCompoundControlDragAndDropController = class(TACLCompoundControlPersistent,
    IACLDropSourceOperation)
  strict private
    FAutoScrollDirection: TAlign;
    FAutoScrollTimer: TACLTimer;
    FCursor: TCursor;
    FDragObject: TACLCompoundControlDragObject;
    FDragWindow: TDragImageList;
    FDropSource: TACLDropSource;
    FDropSourceConfig: TACLIniFile;
    FDropSourceObject: TObject;
    FDropSourceOperation: IACLDropSourceOperation;
    FDropTarget: TACLDropTarget;
    FIsActive: Boolean;
    FIsDropping: Boolean;
    FIsPressed: Boolean;
    FIsStarted: Boolean;
    FLastPoint: TPoint;
    FMouseCapturePoint: TPoint;
    FShiftState: TShiftState;

    procedure AutoScrollTimerHandler(Sender: TObject);
    function GetHitTest: TACLHitTestInfo; inline;
    function GetIsDropSourceOperation: Boolean;
    procedure Finish(ACanceled: Boolean);
  protected
    // General
    function DragStart: Boolean;
    procedure DoBeforeDragStarted; virtual;
    procedure UpdateCursor(AValue: TCursor);

    // AutoScrollTimer
    procedure UpdateAutoScrollDirection(ADirection: TAlign; AInterval: Integer);

    // DropSource
    function CanStartDropSource(var AActions: TACLDropSourceActions;
      ASourceObject: TObject): Boolean; virtual;
    procedure StartDropSource(AActions: TACLDropSourceActions;
      ASource: IACLDropSourceOperation; ASourceObject: TObject);
    procedure DropSourceBegin; virtual;
    procedure DropSourceEnd(AActions: TACLDropSourceActions; AShiftState: TShiftState); virtual;

    // DropTarget
    function CreateDefaultDropTarget: TACLDropTarget; virtual;
    procedure UpdateDropTarget(ADropTarget: TACLDropTarget);

    // Messages
    procedure CMCancelMode(var Message: TMessage); message CM_CANCELMODE;

    property AutoScrollTimer: TACLTimer read FAutoScrollTimer;
    property DragWindow: TDragImageList{nullable} read FDragWindow;
    property DropSourceConfig: TACLIniFile read FDropSourceConfig;
    property DropSourceObject: TObject read FDropSourceObject;
    property LastPoint: TPoint read FLastPoint write FLastPoint;
    property IsStarted: Boolean read FIsStarted;
    property MouseCapturePoint: TPoint read FMouseCapturePoint write FMouseCapturePoint;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    procedure Cancel;
    procedure Draw(ACanvas: TCanvas); virtual;
    procedure MouseDown(AShift: TShiftState; const APoint: TPoint);
    procedure MouseMove(AShift: TShiftState; const APoint: TPoint);
    procedure MouseUp;
    procedure ProcessChanges(AChanges: TIntegerSet); virtual;
    //# Properties
    property Cursor: TCursor read FCursor;
    property DragObject: TACLCompoundControlDragObject read FDragObject;
    property DropTarget: TACLDropTarget read FDropTarget;
    property HitTest: TACLHitTestInfo read GetHitTest;
    property IsActive: Boolean read FIsActive;
    property IsDropping: Boolean read FIsDropping write FIsDropping;
    property IsDropSourceOperation: Boolean read GetIsDropSourceOperation;
    property IsPressed: Boolean read FIsPressed;
    property ShiftState: TShiftState read FShiftState;
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
    FFlags: Word;
    FHeight: SmallInt;
    FTop: Integer;
    FViewInfo: TACLCompoundControlBaseContentCellViewInfo;

    function GetClientBounds: TRect; virtual;
  public
    constructor Create(AData: TObject;
      AViewInfo: TACLCompoundControlBaseContentCellViewInfo);
    procedure CalculateHitTest(AInfo: TACLHitTestInfo);
    procedure Draw(ACanvas: TCanvas);
    function MeasureHeight: Integer;
    //# Properties
    property AbsBounds: TRect read GetClientBounds;
    property Bounds: TRect read GetBounds;
    property Data: TObject read FData;
    property Flags: Word read FFlags write FFlags;
    property Height: SmallInt read FHeight;
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

    procedure CalculateHitTest(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo); virtual;
    procedure DoDraw(ACanvas: TCanvas); virtual; abstract;
    function GetFocusRect: TRect; virtual;
    function GetFocusRectColor: TColor; virtual;
    function HasFocusRect: Boolean; virtual;
  public
    constructor Create(AOwner: IACLCompoundControlSubClassContent);
    procedure Calculate; overload;
    procedure Calculate(AWidth, AHeight: Integer); overload; virtual;
    procedure Draw(ACanvas: TCanvas; const ABounds: TRect; AData: TObject; AFlags: Word);
    procedure Initialize(AData: TObject); overload; virtual;
    procedure Initialize(AData: TObject; AHeight, AFlags: Integer); overload; virtual;
    function MeasureHeight: Integer; virtual;
    //# Properties
    property Bounds: TRect read GetBounds;
    property Owner: IACLCompoundControlSubClassContent read FOwner;
  end;

  { TACLCompoundControlBaseCheckableContentCellViewInfo }

  TACLCompoundControlBaseCheckableContentCellViewInfo = class(TACLCompoundControlBaseContentCellViewInfo)
  protected
    FCheckBoxRect: TRect;
    FExpandButtonRect: TRect;
    FExpandButtonVisible: Boolean;

    procedure CalculateHitTest(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo); override;
    function IsCheckBoxEnabled: Boolean; virtual;
  public
    property CheckBoxRect: TRect read FCheckBoxRect;
    property ExpandButtonRect: TRect read FExpandButtonRect;
    property ExpandButtonVisible: Boolean read FExpandButtonVisible;
  end;

  { TACLCompoundControlContentCellList }

  TACLCompoundControlContentCellList<T: TACLCompoundControlBaseContentCell> = class(TACLObjectListOf<T>)
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
    function FindFirstVisible(AStartFromIndex: Integer;
      ADirection: Integer; ADataClass: TClass; out ACell: T): Boolean;
    function GetCell(Index: Integer;
      out ACell: TACLCompoundControlBaseContentCell): Boolean;
    function GetContentSize: Integer;
    procedure UpdateVisibleBounds;
    //# Properties
    property FirstVisible: Integer read FFirstVisible;
    property LastVisible: Integer read FLastVisible;
  end;

  { TACLCompoundControlContentCellList }

  TACLCompoundControlContentCellList = class(
    TACLCompoundControlContentCellList<TACLCompoundControlBaseContentCell>)
  public
    constructor Create(AOwner: IACLCompoundControlSubClassContent;
      ACellClass: TACLCompoundControlBaseContentCellClass);
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
    //# Properties
    property HitTest: TACLHitTestInfo read GetHitTest;
    property ThumbnailViewInfo: TACLCompoundControlScrollBarThumbnailViewInfo read GetThumbnailViewInfo;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass; AKind: TScrollBarKind); reintroduce; virtual;
    destructor Destroy; override;
    function IsThumbResizable: Boolean; virtual;
    function MeasureSize: Integer;
    procedure SetParams(const AScrollInfo: TACLScrollInfo);
    //# Properties
    property Kind: TScrollBarKind read FKind;
    property ScrollInfo: TACLScrollInfo read FScrollInfo;
    property Style: TACLStyleScrollBox read GetStyle;
    property ThumbExtends: TRect read FThumbExtends;
    property TrackArea: TRect read FTrackArea;
    property Visible: Boolean read FVisible;
    //# Events
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
    procedure DoDrawTo(ADib: TACLDib);
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
    //# Properties
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
    procedure MouseDown(AButton: TMouseButton;
      AShift: TShiftState; AHitTestInfo: TACLHitTestInfo); override;
    procedure MouseUp(AButton: TMouseButton;
      AShift: TShiftState; AHitTestInfo: TACLHitTestInfo); override;
  public
    destructor Destroy; override;
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
    //# Properties
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
    // Handlers
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
    //# Properties
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

  TACLCompoundControlGetCursorEvent = procedure (
    Sender: TObject; AHitTestInfo: TACLHitTestInfo) of object;
  TACLCompoundControlDropSourceDataEvent = procedure (
    Sender: TObject; ASource: TACLDropSource) of object;
  TACLCompoundControlDropSourceFinishEvent = procedure (
    Sender: TObject; Canceled: Boolean; const ShiftState: TShiftState) of object;
  TACLCompoundControlDropSourceStartEvent = procedure (
    Sender: TObject; var AHandled: Boolean; var AAllowAction: TACLDropSourceActions) of object;

  TACLCompoundControlSubClass = class(TACLControlSubClass,
    IACLCurrentDpi,
    IACLResourceCollection,
    IACLResourceChangeListener)
  strict private
    FActionType: TACLControlActionType;
    FContainer: IACLCompoundControlSubClassContainer;
    FDragAndDropController: TACLCompoundControlDragAndDropController;
    FEnabledContent: Boolean;
    FHitTest: TACLHitTestInfo;
    FHoveredObject: TObject;
    FHoveredObjectPart: NativeInt;
    FLastClickCount: Integer;
    FLastClickPoint: TPoint;
    FLastClickTimestamp: Cardinal;
    FLockCount: Integer;
    FLongOperationCount: Integer;
    FPressedObject: TObject;
    FViewInfo: TACLCompoundControlCustomViewInfo;

    FStyleScrollBox: TACLStyleScrollBox;

    FOnCalculated: TNotifyEvent;
    FOnDropSourceData: TACLCompoundControlDropSourceDataEvent;
    FOnDropSourceFinish: TACLCompoundControlDropSourceFinishEvent;
    FOnDropSourceStart: TACLCompoundControlDropSourceStartEvent;
    FOnGetCursor: TACLCompoundControlGetCursorEvent;
    FOnUpdateState: TNotifyEvent;

    function GetCurrentDpi: Integer;
    function GetFocused: Boolean;
    function GetFont: TFont;
    function GetIsDestroying: Boolean; inline;
    procedure SetEnabledContent(AValue: Boolean);
    procedure SetStyleScrollBox(AValue: TACLStyleScrollBox);
  protected
    FChanges: TIntegerSet;

    function CreateDragAndDropController: TACLCompoundControlDragAndDropController; virtual;
    function CreateHitTest: TACLHitTestInfo; virtual;
    function CreateStyleScrollBox: TACLStyleScrollBox; virtual;
    function CreateViewInfo: TACLCompoundControlCustomViewInfo; virtual; abstract;
    procedure BoundsChanged; virtual;
    procedure FocusChanged; virtual;
    procedure RecreateViewSubClasses;

    // General
    function CanInteract: Boolean;
    function GetFullRefreshChanges: TIntegerSet; virtual;
    procedure ProcessChanges(AChanges: TIntegerSet = []); virtual;
    procedure ToggleChecked(AObject: TObject);
    procedure ToggleExpanded(AObject: TObject);

    // Gesture
    procedure ProcessGesture(const AEventInfo: TGestureEventInfo; var AHandled: Boolean); virtual;

    // Keyboard
    procedure ProcessKeyDown(var AKey: Word; AShift: TShiftState); virtual;
    procedure ProcessKeyPress(var AKey: WideChar); virtual;
    procedure ProcessKeyUp(var AKey: Word; AShift: TShiftState); virtual;

    // Mouse
    procedure ProcessContextPopup(var AHandled: Boolean); virtual;
    procedure ProcessMouseClick(AShift: TShiftState); virtual;
    procedure ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState); virtual;
    procedure ProcessMouseLeave; virtual;
    procedure ProcessMouseMove(AShift: TShiftState; X, Y: Integer); virtual;
    procedure ProcessMouseUp(AButton: TMouseButton; AShift: TShiftState); virtual;
    procedure ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState); virtual;
    procedure SetHoveredObject(AObject: TObject; APart: NativeInt = 0);
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
    function QueryInterface({$IFDEF FPC}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HRESULT; override;

    // Messages
    procedure CMCancelMode(var Message: TMessage); message CM_CANCELMODE;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    // Properties
    property LastClickCount: Integer read FLastClickCount;
  public
    constructor Create(AOwner: IACLCompoundControlSubClassContainer);
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Calculate(ABounds: TRect); override;
    procedure Changed(AChanges: TIntegerSet); virtual;
    procedure ContextPopup(const P: TPoint; var AHandled: Boolean);
    procedure FullRefresh;
    procedure SetFocus; inline;
    procedure SetTargetDPI(AValue: Integer); virtual;

    // AutoSize
    function CalculateAutoSize(var AWidth, AHeight: Integer): Boolean; virtual;

    // Localization
    procedure Localize(const ASection: string); virtual;

    // Drawing
    procedure Draw(ACanvas: TCanvas); override; final;
    procedure Invalidate;
    procedure InvalidateRect(const R: TRect); virtual;
    procedure Update;

    // Gesture
    procedure Gesture(const AEventInfo: TGestureEventInfo; var AHandled: Boolean);

    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override; final;
    procedure KeyChar(var Key: WideChar); override; final;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override; final;
    function WantSpecialKey(Key: Word; Shift: TShiftState): Boolean; virtual;

    // Cursor
    function GetCursor(const P: TPoint): TCursor;
    procedure UpdateCursor;

    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; const P: TPoint); override; final;
    procedure MouseLeave; override; final;
    procedure MouseMove(Shift: TShiftState; const P: TPoint); override; final;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; const P: TPoint); override; final;
    procedure MouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);

    // HitTest
    function CalculateState(AObject: TObject; ASubPart: NativeInt = 0): TACLButtonState;
    procedure UpdateHitTest; overload;
    procedure UpdateHitTest(const P: TPoint; ACalcHint: Boolean = False); overload; virtual;

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

    // Coords Transform
    function ClientToScreen(const P: TPoint): TPoint; overload;
    function ClientToScreen(const R: TRect): TRect; overload;
    function ScreenToClient(const P: TPoint): TPoint;

    // Properties
    property ActionType: TACLControlActionType read FActionType;
    property Container: IACLCompoundControlSubClassContainer read FContainer;
    property CurrentDpi: Integer read GetCurrentDpi;
    property DragAndDropController: TACLCompoundControlDragAndDropController read FDragAndDropController;
    property EnabledContent: Boolean read FEnabledContent write SetEnabledContent;
    property Focused: Boolean read GetFocused;
    property Font: TFont read GetFont;
    property HitTest: TACLHitTestInfo read FHitTest;
    property HoveredObject: TObject read FHoveredObject;
    property HoveredObjectPart: NativeInt read FHoveredObjectPart;
    property PressedObject: TObject read FPressedObject write FPressedObject;
    property ResourceCollection: TACLCustomResourceCollection read GetResourceCollection;
    property StyleScrollBox: TACLStyleScrollBox read FStyleScrollBox write SetStyleScrollBox;
    property ViewInfo: TACLCompoundControlCustomViewInfo read FViewInfo;
    //# Events
    property OnCalculated: TNotifyEvent read FOnCalculated write FOnCalculated;
    property OnDropSourceData: TACLCompoundControlDropSourceDataEvent read FOnDropSourceData write FOnDropSourceData;
    property OnDropSourceFinish: TACLCompoundControlDropSourceFinishEvent read FOnDropSourceFinish write FOnDropSourceFinish;
    property OnDropSourceStart: TACLCompoundControlDropSourceStartEvent read FOnDropSourceStart write FOnDropSourceStart;
    property OnGetCursor: TACLCompoundControlGetCursorEvent read FOnGetCursor write FOnGetCursor;
    property OnUpdateState: TNotifyEvent read FOnUpdateState write FOnUpdateState;
    //# Flags
    property IsDestroying: Boolean read GetIsDestroying;
  end;

implementation

uses
  ACL.Graphics.SkinImageSet, // inlining
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

{$REGION ' Hit-Test '}

{ TACLHitTestInfo }

destructor TACLHitTestInfo.Destroy;
begin
  FreeAndNil(FFlags);
  FreeAndNil(FData);
  inherited Destroy;
end;

procedure TACLHitTestInfo.AfterConstruction;
begin
  inherited AfterConstruction;
  FData := TACLDictionary<string, Pointer>.Create;
  FFlags := TACLListOfInteger.Create;
end;

function TACLHitTestInfo.CreateDragObject: TACLCompoundControlDragObject;
var
  AObject: IACLDraggableObject;
begin
  if Supports(HitObject, IACLDraggableObject, AObject) or
     Supports(TObject(Data[cchdViewInfo]), IACLDraggableObject, AObject)
  then
    Result := AObject.CreateDragObject(Self)
  else
    Result := nil;
end;

procedure TACLHitTestInfo.Reset;
begin
  FBounds := NullRect;
  FCursor := crDefault;
  FCalcHintData := False;
  FData.Clear(True);
  FFlags.Clear;
  HintData.Reset;
  HitObject := nil;
end;

function TACLHitTestInfo.GetFlag(Index: Integer): Boolean;
begin
  Result := FFlags.IndexOf(Index) >= 0;
end;

procedure TACLHitTestInfo.SetFlag(Index: Integer; const Value: Boolean);
begin
  FFlags.Remove(Index);
  if Value then
    FFlags.Add(Index);
end;

function TACLHitTestInfo.GetData(const Index: string): Pointer;
begin
  if not FData.TryGetValue(acLowerCase(Index), Result) then
    Result := nil;
end;

procedure TACLHitTestInfo.SetData(const Index: string; const Value: Pointer);
begin
  FData.AddOrSetValue(acLowerCase(Index), Value);
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
  Result := SubClass.CurrentDpi;
end;

{ TACLCompoundControlCustomViewInfo }

procedure TACLCompoundControlCustomViewInfo.Calculate(const R: TRect; AChanges: TIntegerSet);
begin
  FBounds := R;
  DoCalculate(AChanges);
end;

function TACLCompoundControlCustomViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  Result := PtInRect(Bounds, AInfo.Point);
  if Result then
    DoCalculateHitTest(AInfo);
end;

procedure TACLCompoundControlCustomViewInfo.Draw(ACanvas: TCanvas);
begin
  if acRectVisible(ACanvas, Bounds) then
    DoDraw(ACanvas);
end;

procedure TACLCompoundControlCustomViewInfo.DrawTo(ACanvas: TCanvas; X, Y: Integer);
begin
  Dec(X, Bounds.Left);
  Dec(Y, Bounds.Top);
  MoveWindowOrg(ACanvas.Handle,  X,  Y);
  Draw(ACanvas);
  MoveWindowOrg(ACanvas.Handle, -X, -Y);
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

procedure TACLCompoundControlContainerViewInfo.AddCell(
  ACell: TACLCompoundControlCustomViewInfo; out AObj);
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
    RecreateSubCells;
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
  LRgn: TRegionHandle;
begin
  if acStartClippedDraw(ACanvas, Bounds, LRgn) then
  try
    DoDrawCells(ACanvas);
  finally
    acEndClippedDraw(ACanvas, LRgn);
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

procedure TACLCompoundControlContainerViewInfo.RecreateSubCells;
begin
  FChildren.Clear;
end;

{ TACLCompoundControlDragObject }

destructor TACLCompoundControlDragObject.Destroy;
begin
  FreeAndNil(FPreview);
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

procedure TACLCompoundControlDragObject.DoAutoScroll(ADirection: TAlign);
begin
  case ADirection of
    alLeft:
      SubClass.ScrollHorizontally(scLineUp);
    alRight:
      SubClass.ScrollHorizontally(scLineDown);
    alBottom:
      SubClass.ScrollVertically(scLineDown);
    alTop:
      SubClass.ScrollVertically(scLineUp);
  end;
end;

procedure TACLCompoundControlDragObject.InitializePreview(
  ASourceViewInfo: TACLCompoundControlCustomViewInfo);
var
  LStyle: TACLStyleHint;
begin
  FreeAndNil(FPreview);
  FPreview := TACLBitmap.CreateEx(ASourceViewInfo.Bounds);
  LStyle := TACLStyleHint.Create(nil);
  try
    LStyle.Collection := SubClass.ResourceCollection;
    LStyle.Draw(Preview.Canvas, Preview.ClientRect);
  finally
    LStyle.Free;
  end;
  ASourceViewInfo.DrawTo(Preview.Canvas, 0, 0);
end;

procedure TACLCompoundControlDragObject.StartDropSource(
  AActions: TACLDropSourceActions; ASource: IACLDropSourceOperation; ASourceObject: TObject);
begin
  FController.StartDropSource(AActions, ASource, ASourceObject);
end;

function TACLCompoundControlDragObject.TransformPoint(const P: TPoint): TPoint;
begin
  Result := P;
end;

procedure TACLCompoundControlDragObject.UpdateAutoScrollDirection(
  const P: TPoint; const AArea: TRect);
var
  LDirection: TAlign;
  LInterval: Integer;
begin
  LDirection := acCalculateAutoScroll(P, AArea, CurrentDpi, LInterval);
  FController.UpdateAutoScrollDirection(LDirection, LInterval);
end;

procedure TACLCompoundControlDragObject.UpdateDropTarget(ADropTarget: TACLDropTarget);
begin
  FController.UpdateDropTarget(ADropTarget);
end;

function TACLCompoundControlDragObject.GetCurrentDpi: Integer;
begin
  Result := SubClass.CurrentDpi;
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

procedure TACLCompoundControlDragObject.UpdateCursor(ACursor: TCursor);
begin
  FController.UpdateCursor(ACursor);
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
  FreeAndNil(FDropTarget);
  FreeAndNil(FDropSourceConfig);
  inherited Destroy;
end;

procedure TACLCompoundControlDragAndDropController.AutoScrollTimerHandler(Sender: TObject);
begin
  if DragObject <> nil then
  begin
    SubClass.BeginUpdate;
    try
      DragObject.DoAutoScroll(FAutoScrollDirection);
    finally
      SubClass.EndUpdate; // prevent from update;
    end;
    SubClass.UpdateHotTrack;
  end;
end;

procedure TACLCompoundControlDragAndDropController.DoBeforeDragStarted;
begin
  // do nothing
end;

procedure TACLCompoundControlDragAndDropController.Cancel;
begin
  if IsActive then
  begin
    if FDropSource <> nil then
      FDropSource.Cancel;
    if IsDropSourceOperation then
      DropSourceEnd([], [])
    else
      Finish(True);
  end;
  FIsPressed := False;
end;

procedure TACLCompoundControlDragAndDropController.Draw(ACanvas: TCanvas);
begin
  if DragObject <> nil then
    DragObject.Draw(ACanvas);
end;

procedure TACLCompoundControlDragAndDropController.MouseDown(
  AShift: TShiftState; const APoint: TPoint);
begin
  FIsPressed := True;
  FIsStarted := False;
  MouseCapturePoint := APoint;
  LastPoint := MouseCapturePoint;
  FShiftState := AShift;
end;

procedure TACLCompoundControlDragAndDropController.MouseMove(
  AShift: TShiftState; const APoint: TPoint);
var
  LDelta: TPoint;
  LPoint: TPoint;
begin
  if FIsPressed and not (IsActive or IsStarted) and
     ([ssLeft, ssRight, ssMiddle] * AShift = [ssLeft]) then
  begin
    LDelta := APoint - MouseCapturePoint;
    if acCanStartDragging(LDelta.X, LDelta.Y, CurrentDpi) then
    begin
      FIsStarted := True;
      DoBeforeDragStarted;
      SubClass.UpdateHitTest(LastPoint);
      FShiftState := AShift;
      if (SubClass.PressedObject = HitTest.HitObject) and DragStart then
      begin
        FIsActive := True; // first
        SubClass.DoDragStarted;
        LastPoint := DragObject.TransformPoint(LastPoint);
        SubClass.UpdateHitTest(APoint);
        UpdateCursor(HitTest.Cursor);
      end
      else
        Cancel;
    end;
  end;

  if IsActive and not IsDropSourceOperation then
  begin
    LPoint := DragObject.TransformPoint(APoint);
    LDelta := LPoint - LastPoint;
    DragObject.DragMove(LPoint, LDelta.X, LDelta.Y);
    LastPoint := LastPoint + LDelta;
    if DragWindow <> nil then
    begin
      with MouseCursorPos do
        DragWindow.DragMove(X, Y);
    end;
  end;
end;

procedure TACLCompoundControlDragAndDropController.MouseUp;
begin
  if not IsDropSourceOperation then
    Finish(False);
  FIsPressed := False;
end;

procedure TACLCompoundControlDragAndDropController.ProcessChanges(AChanges: TIntegerSet);
begin
  // do nothing
end;

procedure TACLCompoundControlDragAndDropController.UpdateAutoScrollDirection(
  ADirection: TAlign; AInterval: Integer);
begin
  if AutoScrollTimer = nil then
    FAutoScrollTimer := TACLTimer.CreateEx(AutoScrollTimerHandler);
  FAutoScrollDirection := ADirection;
  FAutoScrollTimer.Interval := AInterval;
  FAutoScrollTimer.Enabled := ADirection in [alLeft, alTop, alRight, alBottom];
end;

function TACLCompoundControlDragAndDropController.CanStartDropSource(
  var AActions: TACLDropSourceActions; ASourceObject: TObject): Boolean;
begin
  Result := not SubClass.DoDropSourceBegin(AActions, DropSourceConfig);
end;

procedure TACLCompoundControlDragAndDropController.CMCancelMode(var Message: TMessage);
begin
  FIsPressed := False;
  if not IsDropSourceOperation then Cancel;
end;

procedure TACLCompoundControlDragAndDropController.StartDropSource(
  AActions: TACLDropSourceActions; ASource: IACLDropSourceOperation; ASourceObject: TObject);
begin
  DropSourceConfig.Clear;
  if CanStartDropSource(AActions, ASourceObject) and (AActions <> []) then
  begin
    FIsPressed := False;
    FDropSourceObject := ASourceObject;
    FDropSourceOperation := ASource;
    FDropSource := TACLDropSource.Create(Self, SubClass.Container.GetControl);
    FDropSource.AllowedActions := AActions;
    if not DropSourceConfig.IsEmpty then
      FDropSource.DataProviders.Add(TACLDragDropDataProviderConfig.Create(DropSourceConfig));
    SubClass.DoDropSourceGetData(FDropSource, FDropSourceObject);
    FDropSource.ExecuteInThread;
  end;
end;

procedure TACLCompoundControlDragAndDropController.DropSourceBegin;
begin
  SubClass.UpdateHitTest(LastPoint);
  FDropSourceOperation.DropSourceBegin;
end;

procedure TACLCompoundControlDragAndDropController.DropSourceEnd(
  AActions: TACLDropSourceActions; AShiftState: TShiftState);
begin
  FDropSourceOperation.DropSourceEnd(AActions, AShiftState);
  FDropSourceOperation := nil;
  FDropSourceObject := nil;
  FDropSource := nil;
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
      FreeAndNil(FDragObject)
    else
      if FDragObject.Preview <> nil then
      begin
        FDragWindow := TDragImageList.Create(nil);
        FDragWindow.DragCursor := FDragObject.HitTest.Cursor;
        FDragWindow.Height := FDragObject.Preview.Height;
        FDragWindow.Width := FDragObject.Preview.Width;
        FDragWindow.Add(FDragObject.Preview, nil);
        with MouseCursorPos do
          DragWindow.BeginDrag(GetDesktopWindow, X, Y);
        FDragWindow.ShowDragImageEx;
      end;
  end;
end;

procedure TACLCompoundControlDragAndDropController.Finish(ACanceled: Boolean);
begin
  if IsActive then
  try
    FIsActive := False;
    FreeAndNil(FAutoScrollTimer);
    DragObject.DragFinished(ACanceled);
    if DragWindow <> nil then
    try
      DragWindow.EndDrag;
    finally
      FreeAndNil(FDragWindow);
    end;
  finally
    FreeAndNil(FDragObject);
    UpdateCursor(crDefault);
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

procedure TACLCompoundControlDragAndDropController.UpdateCursor(AValue: TCursor);
begin
  if FCursor <> AValue then
  begin
    FCursor := AValue;
    if DragWindow <> nil then
      DragWindow.DragCursor := FCursor
    else
      SubClass.UpdateCursor;
  end;
end;

{$ENDREGION}

{$REGION ' Content Cells '}

{ TACLCompoundControlBaseContentCell }

constructor TACLCompoundControlBaseContentCell.Create(
  AData: TObject; AViewInfo: TACLCompoundControlBaseContentCellViewInfo);
begin
  inherited Create;
  FData := AData;
  FViewInfo := AViewInfo;
end;

procedure TACLCompoundControlBaseContentCell.CalculateHitTest(AInfo: TACLHitTestInfo);
var
  LBounds: TRect;
begin
  LBounds := Bounds;
  AInfo.HitObject := Data;
  AInfo.Data[cchdViewInfo] := ViewInfo;
  ViewInfo.Initialize(Data, LBounds.Height, FFlags);
  ViewInfo.CalculateHitTest(AInfo.Point - LBounds.TopLeft, LBounds.TopLeft, AInfo);
end;

procedure TACLCompoundControlBaseContentCell.Draw(ACanvas: TCanvas);
begin
  ViewInfo.Draw(ACanvas, Bounds, Data, Flags);
end;

function TACLCompoundControlBaseContentCell.MeasureHeight: Integer;
begin
  ViewInfo.Initialize(Data);
  Result := ViewInfo.MeasureHeight;
end;

function TACLCompoundControlBaseContentCell.GetClientBounds: TRect;
begin
  Result.Left := 0;
  Result.Top := Top;
  Result.Width := ViewInfo.Owner.GetContentWidth;
  Result.Height := Height;
end;

function TACLCompoundControlBaseContentCell.GetBounds: TRect;
begin
  Result := GetClientBounds + ViewInfo.Owner.GetViewItemsOrigin;
end;

{ TACLCompoundControlBaseContentCellViewInfo }

constructor TACLCompoundControlBaseContentCellViewInfo.Create(
  AOwner: IACLCompoundControlSubClassContent);
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
  const P, AOrigin: TPoint; AInfo: TACLHitTestInfo);
begin
  // do nothing
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Draw(
  ACanvas: TCanvas; const ABounds: TRect; AData: TObject; AFlags: Word);
var
  LOrg: TPoint;
begin
  LOrg := acMoveWindowOrg(ACanvas.Handle, ABounds.Left, ABounds.Top);
  try
    Initialize(AData, ABounds.Height, AFlags);
    DoDraw(ACanvas);
    if HasFocusRect then
      acDrawFocusRect(ACanvas, GetFocusRect, GetFocusRectColor);
  finally
    acRestoreWindowOrg(ACanvas.Handle, LOrg);
  end;
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Initialize(AData: TObject);
begin
  FData := AData;
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Initialize(
  AData: TObject; AHeight, AFlags: Integer);
begin
  FHeight := AHeight;
  Initialize(AData);
end;

function TACLCompoundControlBaseContentCellViewInfo.MeasureHeight: Integer;
begin
  Result := Bounds.Height;
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

procedure TACLCompoundControlBaseCheckableContentCellViewInfo.CalculateHitTest(
  const P, AOrigin: TPoint; AInfo: TACLHitTestInfo);
begin
  if PtInRect(CheckBoxRect, P) and IsCheckBoxEnabled then
  begin
    AInfo.Cursor := crHandPoint;
    AInfo.IsCheckable := True;
    AInfo.Data[cchdSubPart] := Pointer(cchtCheckable);
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
  FOwner := AOwner;
  FLastVisible := -1;
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
    if PtInRect(List[I].Bounds, AInfo.Point) then
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
  ASaveIndex: TRegionHandle;
  I: Integer;
begin
  if acStartClippedDraw(ACanvas, GetClipRect, ASaveIndex) then
  try
    for I := FirstVisible to LastVisible do
      List[I].Draw(ACanvas);
  finally
    acEndClippedDraw(ACanvas, ASaveIndex);
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
  AOwner: IACLCompoundControlSubClassContent;
  ACellClass: TACLCompoundControlBaseContentCellClass);
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
  FillChar(Self, SizeOf(Self), 0);
end;

{ TACLCompoundControlScrollBarViewInfo }

constructor TACLCompoundControlScrollBarViewInfo.Create(
  ASubClass: TACLCompoundControlSubClass; AKind: TScrollBarKind);
begin
  inherited Create(ASubClass);
  FKind := AKind;
end;

destructor TACLCompoundControlScrollBarViewInfo.Destroy;
begin
  FreeAndNil(FScrollTimer);
  inherited Destroy;
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
  Style.Draw(ACanvas, Bounds, Kind, sbpNone, absNormal);
  inherited DoDraw(ACanvas);
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

procedure TACLCompoundControlScrollBarViewInfo.RecreateSubCells;
begin
  inherited;
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

  ADelta := CalculateScrollDelta(HitTest.Point);
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
    ScrollTo(AHitTestInfo.Point)
  else
    if AButton = mbLeft then
    begin
      FreeAndNil(FScrollTimer);
      ADelta := CalculateScrollDelta(AHitTestInfo.Point);
      if ADelta <> 0 then
      begin
        FScrollTimer := TACLTimer.CreateEx(ScrollTimerHandler, acScrollBarTimerInitialDelay);
        FScrollTimer.Tag := ADelta;
        FScrollTimer.Start;
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
    Style.Draw(ACanvas, Bounds, Kind, Part, ActualState);
end;

procedure TACLCompoundControlScrollBarPartViewInfo.DoDrawTo(ADib: TACLDib);
begin
  Style.Draw(ADib.Canvas, ADib.ClientRect, Kind, Part, ActualState);
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
  LAnimation: TACLBitmapAnimation;
begin
  if AValue <> FState then
  begin
    AnimationManager.RemoveOwner(Self);

    if acUIAnimations and (AValue = absNormal) and (FState = absHover) then
    begin
      LAnimation := TACLBitmapAnimation.Create(Self, Bounds, TACLAnimatorFadeOut.Create);
      DoDrawTo(LAnimation.BuildFrame1);
      FState := AValue;
      DoDrawTo(LAnimation.BuildFrame2);
      LAnimation.Run;
    end
    else
      FState := AValue;

    Invalidate;
  end;
end;

{ TACLCompoundControlScrollBarButtonViewInfo }

destructor TACLCompoundControlScrollBarButtonViewInfo.Destroy;
begin
  FreeAndNil(FTimer);
  inherited;
end;

procedure TACLCompoundControlScrollBarButtonViewInfo.Click;
begin
  case Part of
    sbpLineDown:
      Scroll(Owner.ScrollInfo.Position + Owner.ScrollInfo.LineSize);
    sbpLineUp:
      Scroll(Owner.ScrollInfo.Position - Owner.ScrollInfo.LineSize);
  else;
  end;
end;

procedure TACLCompoundControlScrollBarButtonViewInfo.MouseDown(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
begin
  if AButton = mbLeft then
  begin
    Click;
    if FTimer = nil then
      FTimer := TACLTimer.CreateEx(TimerHandler, acScrollBarTimerInitialDelay);
    FTimer.Restart;
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
  if FTimer = nil then Exit;
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
  Result :=
    ScrollBarHorz.CalculateHitTest(AInfo) or
    ScrollBarVert.CalculateHitTest(AInfo) or
    inherited CalculateHitTest(AInfo);
end;

procedure TACLCompoundControlScrollContainerViewInfo.ScrollByMouseWheel(
  ADirection: TACLMouseWheelDirection; AShift: TShiftState);
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
    else;
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

constructor TACLCompoundControlSubClass.Create(AOwner: IACLCompoundControlSubClassContainer);
begin
  FContainer := AOwner;
  inherited Create(AOwner);
  BeginUpdate;
  FEnabledContent := True;
  FViewInfo := CreateViewInfo;
  FHitTest := CreateHitTest;
  FDragAndDropController := CreateDragAndDropController;
  FStyleScrollBox := CreateStyleScrollBox;
end;

destructor TACLCompoundControlSubClass.Destroy;
begin
  FreeAndNil(FDragAndDropController);
  FreeAndNil(FHitTest);
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
  if FActionType = ccatMouse then
    raise EInvalidOperation.Create(ClassName + ' cannot be destroyed inside mouse action');
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
          if [csReading, csLoading] * Container.GetControl.ComponentState = [] then
            OnCalculated(Self);
        end;
    end;
  end;
end;

procedure TACLCompoundControlSubClass.ContextPopup(const P: TPoint; var AHandled: Boolean);
begin
  if CanInteract then
  begin
    UpdateHitTest(P);
    if HitTest.IsNonClient then
      AHandled := True
    else
    begin
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
  Result := StyleScrollBox.TargetDPI;
end;

function TACLCompoundControlSubClass.GetCursor(const P: TPoint): TCursor;
begin
  if FLongOperationCount > 0 then
    Result := crHourGlass
  else
    if DragAndDropController.IsActive then
      Result := DragAndDropController.Cursor
    else
      if CanInteract then
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
end;

procedure TACLCompoundControlSubClass.SetFocus;
begin
  try
    Container.SetFocus;
  except
    // do nothing
  end;
end;

procedure TACLCompoundControlSubClass.Calculate(ABounds: TRect);
begin
  if Bounds <> ABounds then
  begin
    inherited;
    BoundsChanged;
  end;
end;

function TACLCompoundControlSubClass.CalculateAutoSize(var AWidth, AHeight: Integer): Boolean;
begin
  Result := False;
end;

procedure TACLCompoundControlSubClass.Localize(const ASection: string);
begin
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
  if not R.IsEmpty then
    Container.InvalidateRect(R);
end;

procedure TACLCompoundControlSubClass.Update;
begin
  if not IsUpdateLocked then
    Container.Update;
end;

procedure TACLCompoundControlSubClass.Gesture(
  const AEventInfo: TGestureEventInfo; var AHandled: Boolean);
begin
  if CanInteract then
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
  if CanInteract then
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

procedure TACLCompoundControlSubClass.KeyChar(var Key: WideChar);
begin
  if CanInteract then
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
  if CanInteract then
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

procedure TACLCompoundControlSubClass.MouseDown(
  Button: TMouseButton; Shift: TShiftState; const P: TPoint);
begin
  if CanInteract then
  begin
    FActionType := ccatMouse;
    try
      DragAndDropController.Cancel;
      Application.CancelHint;
      UpdateHitTest(P);

      if Button <> mbLeft then
        FLastClickCount := 1
      else if TACLThread.IsTimeoutEx(FLastClickTimestamp, GetDoubleClickTime) then
        FLastClickCount := 1
      else if acCanStartDragging(FLastClickPoint, P, acDefaultDpi) then
        FLastClickCount := 1
      else
        Inc(FLastClickCount);

      if FLastClickCount = 1 then
        FLastClickPoint := P;
      if LastClickCount > 1 then
        Include(Shift, ssDouble);
      PressedObject := HitTest.HitObject;
      ProcessMouseDown(Button, Shift);
    finally
      FActionType := ccatNone;
    end;
  end;
end;

procedure TACLCompoundControlSubClass.MouseLeave;
begin
  if CanInteract then
  begin
    HitTest.Reset;
    Application.CancelHint;
    SetHoveredObject(nil);
    ProcessMouseLeave;
  end;
end;

procedure TACLCompoundControlSubClass.MouseMove(Shift: TShiftState; const P: TPoint);
begin
  if CanInteract then
  begin
    FActionType := ccatMouse;
    try
      UpdateHitTest(P);
      DragAndDropController.MouseMove(Shift, P);
      if DragAndDropController.IsActive then
        FLastClickCount := 0
      else
        ProcessMouseMove(Shift, P.X, P.Y);
    finally
      FActionType := ccatNone;
    end;
  end;
end;

procedure TACLCompoundControlSubClass.MouseUp(
  Button: TMouseButton; Shift: TShiftState; const P: TPoint);
begin
  if CanInteract then
  begin
    FActionType := ccatMouse;
    try
      if DragAndDropController.IsActive then
        FLastClickCount := 0;
      DragAndDropController.MouseUp;

      UpdateHitTest(P);
      if (Button = mbLeft) and (LastClickCount > 0) then
      begin
        if PressedObject = HitTest.HitObject then
          ProcessMouseClick(Shift);
      end;
      ProcessMouseUp(Button, Shift);
      PressedObject := nil;
    finally
      FActionType := ccatNone;
    end;
  end;
end;

procedure TACLCompoundControlSubClass.MouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);
begin
  if {CanInteract} not IsUpdateLocked then // разрешаем скроллить залоченный список
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
end;

procedure TACLCompoundControlSubClass.UpdateHitTest;
begin
  UpdateHitTest(ScreenToClient(MouseCursorPos));
end;

procedure TACLCompoundControlSubClass.UpdateHitTest(
  const P: TPoint; ACalcHint: Boolean = False);
begin
  HitTest.Reset;
  HitTest.Point := P;
  HitTest.CalcHintData := ACalcHint;
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

procedure TACLCompoundControlSubClass.CMCancelMode(var Message: TMessage);
begin
  DragAndDropController.Dispatch(Message);
  inherited;
end;

procedure TACLCompoundControlSubClass.CMHintShow(var Message: TCMHintShow);
begin
  UpdateHitTest(Message.HintInfo.CursorPos, True);
  if HitTest.HintData.TextRect <> NullRect then
    Message.HintInfo^.HintPos := ClientToScreen(HitTest.HintData.TextRect.TopLeft);
  Message.HintInfo^.CursorRect := HitTest.HintData.Area;
  Message.HintInfo^.HintWindowClass := TACLHintWindow;
  Message.HintInfo^.HintData := @HitTest.HintData;
  Message.HintInfo^.HintStr := HitTest.HintData.Text;
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

procedure TACLCompoundControlSubClass.ProcessKeyDown(var AKey: Word; AShift: TShiftState);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.ProcessGesture(const AEventInfo: TGestureEventInfo; var AHandled: Boolean);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.ProcessKeyPress(var AKey: WideChar);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.ProcessKeyUp(var AKey: Word; AShift: TShiftState);
begin
  // do nothing
end;

function TACLCompoundControlSubClass.CalculateState(AObject: TObject; ASubPart: NativeInt = 0): TACLButtonState;
begin
  if not EnabledContent then
    Exit(absDisabled);
  if (ASubPart = 0) or (HoveredObjectPart = ASubPart) then
  begin
    if PressedObject = AObject then
      Exit(absPressed);
    if HoveredObject = AObject then
      Exit(absHover);
  end;
  Result := absNormal;
end;

function TACLCompoundControlSubClass.CanInteract: Boolean;
begin
  // IsUpdateLocked:
  // Пока мы получаем айтемы, шелы проталкивают WM_MOUSEMOVE, а у нас контрол не посчитан
  //  + TACLCompoundControlSubClass.ToggleExpanded
  //  + TACLShellTreeViewSubClass.DoGetPathChildren
  //  + TACLShellFolder.Enum
  //  + TACLCustomControl.WMMouseMove
  Result := EnabledContent and not IsUpdateLocked;
end;

procedure TACLCompoundControlSubClass.ProcessContextPopup(var AHandled: Boolean);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.ProcessMouseClick(AShift: TShiftState);
begin
  if HitTest.IsCheckable then
    ToggleChecked(HitTest.HitObject)
  else if HitTest.IsExpandable then
    ToggleExpanded(HitTest.HitObject)
end;

procedure TACLCompoundControlSubClass.ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState);
var
  LHandler: IACLPressableObject;
begin
  if Supports(PressedObject, IACLPressableObject, LHandler) then
    LHandler.MouseDown(AButton, AShift, HitTest);
  if (AButton = mbLeft) and (FLastClickCount = 1) then
    DragAndDropController.MouseDown(AShift, HitTest.Point);
end;

procedure TACLCompoundControlSubClass.ProcessMouseLeave;
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.ProcessMouseMove(AShift: TShiftState; X, Y: Integer);
begin
  if not DragAndDropController.IsActive then
    SetHoveredObject(HitTest.HitObject, NativeInt(HitTest.Data[cchdSubPart]));
end;

procedure TACLCompoundControlSubClass.ProcessMouseUp(AButton: TMouseButton; AShift: TShiftState);
var
  LHandler: IACLPressableObject;
begin
  if Supports(PressedObject, IACLPressableObject, LHandler) then
  begin
    PressedObject := nil;
    LHandler.MouseUp(AButton, AShift, HitTest);
  end;
end;

procedure TACLCompoundControlSubClass.ProcessMouseWheel(
  ADirection: TACLMouseWheelDirection; AShift: TShiftState);
begin
  // do nothing
end;

procedure TACLCompoundControlSubClass.UpdateHotTrack;
begin
  MouseMove(KeyboardStateToShiftState, ScreenToClient(MouseCursorPos));
end;

procedure TACLCompoundControlSubClass.DoDragStarted;
begin
  SetHoveredObject(nil);
end;

function TACLCompoundControlSubClass.DoDropSourceBegin(
  var AAllowAction: TACLDropSourceActions; AConfig: TACLIniFile): Boolean;
begin
  Result := False;
  if Assigned(OnDropSourceStart) then
    OnDropSourceStart(Self, Result, AAllowAction);
end;

procedure TACLCompoundControlSubClass.DoDropSourceFinish(
  Canceled: Boolean; const ShiftState: TShiftState);
begin
  if Assigned(OnDropSourceFinish) then
    OnDropSourceFinish(Self, Canceled, ShiftState);
end;

procedure TACLCompoundControlSubClass.DoDropSourceGetData(
  ASource: TACLDropSource; ADropSourceObject: TObject);
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

function TACLCompoundControlSubClass.QueryInterface;
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
  if AChanges <> [] then
    Invalidate;
end;

procedure TACLCompoundControlSubClass.ToggleChecked(AObject: TObject);
var
  LCheckable: IACLCheckableObject;
begin
  BeginUpdate;
  try
    if Supports(AObject, IACLCheckableObject, LCheckable) then
    try
      if LCheckable.CanCheck then
        LCheckable.Checked := not LCheckable.Checked;
    finally
      LCheckable := nil;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLCompoundControlSubClass.ToggleExpanded(AObject: TObject);
var
  LExpandable: IACLExpandableObject;
begin
  BeginUpdate;
  try
    if Supports(AObject, IACLExpandableObject, LExpandable) then
    try
      LExpandable.Expanded := not LExpandable.Expanded;
    finally
      LExpandable := nil;
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

function TACLCompoundControlSubClass.GetResourceCollection: TACLCustomResourceCollection;
var
  AIntf: IACLResourceCollection;
begin
  if Supports(Container, IACLResourceCollection, AIntf) then
    Result := AIntf.GetCollection
  else
    Result := nil;
end;

procedure TACLCompoundControlSubClass.SetEnabledContent(AValue: Boolean);
begin
  if AValue <> EnabledContent then
  begin
    FEnabledContent := AValue;
    Changed([cccnContent]);
  end;
end;

procedure TACLCompoundControlSubClass.SetHoveredObject(AObject: TObject; APart: NativeInt = 0);
var
  LIntf: IACLHotTrackObject;
  LPrevObject: TObject;
  LPrevObjectPart: Integer;
begin
  if FHoveredObject <> AObject then
  begin
    LPrevObject := HoveredObject;
    LPrevObjectPart := FHoveredObjectPart;
    FHoveredObject := AObject;
    FHoveredObjectPart := APart;
    if Supports(LPrevObject, IACLHotTrackObject, LIntf) then
    begin
      if LPrevObjectPart <> 0 then
        LIntf.OnHotTrack(htaSwitchPart);
      LIntf.OnHotTrack(htaLeave);
    end;
    if Supports(HoveredObject, IACLHotTrackObject, LIntf) then
    begin
      LIntf.OnHotTrack(htaEnter);
      if FHoveredObjectPart <> 0 then
        LIntf.OnHotTrack(htaSwitchPart);
    end;
    DoHoveredObjectChanged;
  end
  else
    if FHoveredObjectPart <> APart then
    begin
      FHoveredObjectPart := APart;
      if Supports(HoveredObject, IACLHotTrackObject, LIntf) then
        LIntf.OnHotTrack(htaSwitchPart);
      DoHoveredObjectChanged;
    end;
end;

procedure TACLCompoundControlSubClass.SetStyleScrollBox(AValue: TACLStyleScrollBox);
begin
  FStyleScrollBox.Assign(AValue);
end;

end.
