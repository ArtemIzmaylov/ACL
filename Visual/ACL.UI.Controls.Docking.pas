{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*           Docking Layout Manager          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2023-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Docking;

{$I ACL.Config.inc}
{$R ACL.UI.Controls.Docking.res} // TODO: move to Styles
{$SCOPEDENUMS ON}

{$DEFINE ACL_DOCKING_ANIMATE_SIDEBAR}
{$DEFINE ACL_DOCKING_PIN_TABBED_GROUP}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Classes,
  System.Math,
  System.SysUtils,
  System.UITypes,
  System.TypInfo,
  System.Types,
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  // ACL
  ACl.Classes,
  ACl.Classes.Collections,
  ACL.FileFormats.XML,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.SkinImage,
  ACL.Math,
  ACL.Timers,
  ACL.UI.Animation,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Category,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

const
  CM_DOCKING_BASE       = CM_BASE + 100;
  CM_DOCKING_PACK       = CM_DOCKING_BASE + 1;
  CM_DOCKING_UPDATELIST = CM_DOCKING_BASE + 2;
  CM_DOCKING_UPDATETEXT = CM_DOCKING_BASE + 3;
  CM_DOCKING_VISIBILITY = CM_DOCKING_BASE + 4;

type
  TACLDockControl = class;
  TACLDockGroup = class;
  TACLDockSite = class;
  TACLDockSiteSideBar = class;

  TACLDockGroupLayout = (Horizontal, Vertical, Tabbed);

{$REGION ' Styles '}

  { TACLStyleDocking }

  TACLStyleDocking = class(TACLStyleCategory)
  protected const
    OuterPadding = 3; // TACLMargins.All
    TabControlOffset = 2;
    TabIndent = 3; // TACLTabsOptionsView.TabIndent
  protected
    procedure InitializeResources; override;
    function GetTabMargins: TRect;
    function MeasureTabHeight: Integer;
    function MeasureTabWidth(const ACaption: string): Integer;
  published
    property HeaderButton: TACLResourceTexture index 0 read GetTexture write SetTexture stored IsTextureStored;
    property HeaderButtonGlyphs: TACLResourceTexture index 1 read GetTexture write SetTexture stored IsTextureStored;
    property HeaderTextAlignment default taLeftJustify;
    property TabArea: TACLResourceColor index 10 read GetColor write SetColor stored IsColorStored;
    property TabFont: TACLResourceFont index 1 read GetFont write SetFont stored IsFontStored;
    property TabFontActive: TACLResourceFont index 2 read GetFont write SetFont stored IsFontStored;
  end;

  { TACLStyleDockSite }

  TACLStyleDockSite = class(TACLStyleDocking)
  protected
    procedure InitializeResources; override;
  public
    function MeasureSideBarTabHeight: Integer;
    function MeasureSideBarTabWidth(const ACaption: string): Integer;
  published
    property SideBar: TACLResourceColor index 11 read GetColor write SetColor stored IsColorStored;
    property SideBarTab: TACLResourceTexture index 2 read GetTexture write SetTexture stored IsTextureStored;
    property SideBarTabFont: TACLResourceFont index 3 read GetFont write SetFont stored IsFontStored;
    property SideBarTabFontActive: TACLResourceFont index 4 read GetFont write SetFont stored IsFontStored;
  end;

{$ENDREGION}

{$REGION ' DockZones '}

  { TACLDockZone }

  TACLDockZone = class(TCustomControl)
  strict private
    FActive: Boolean;
    FSkin: TACLSkinImage;

    function GetParent: TACLDockControl;
    function GetSkinSize: TSize;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure SetActive(AValue: Boolean);
  protected
    function CalculateBounds: TRect; virtual;
    function CreateDockGroupForReplacement(AControl: TACLDockControl): TACLDockGroup;
    procedure CreateParams(var Params: TCreateParams); override;
    property Skin: TACLSkinImage read FSkin;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    function AllowDock(ASource: TACLDockControl): Boolean; virtual;
    procedure CalculateSelection(ASource: TACLDockControl; var ABounds: TRect); virtual; abstract;
    procedure CreateLayout(ASource: TACLDockControl); virtual; abstract;
    procedure Show;
    procedure Update; override;
    property Active: Boolean read FActive write SetActive;
    property Parent: TACLDockControl read GetParent;
  end;

  { TACLDockZones }

  TACLDockZones = class(TACLObjectList<TACLDockZone>)
  public
    procedure DeleteByOwner(AOwner: TComponent);
    procedure Show;
    procedure UpdateState(ASource: TACLDockControl);
  end;

  { TACLDockZoneSide }

  TACLDockZoneSide = class(TACLDockZone)
  strict private const
    SelectionSize = 100;
  strict private
    FSide: TACLBorder;
  protected
    function CalculateBounds: TRect; override;
    function GetLayoutDirection: TACLDockGroupLayout;
    property Side: TACLBorder read FSide;
  public
    constructor Create(AOwner: TComponent; ASide: TACLBorder); reintroduce;
    function AllowDock(ASource: TACLDockControl): Boolean; override;
    procedure CalculateSelection(ASource: TACLDockControl; var ABounds: TRect); override;
    procedure CreateLayout(ASource: TACLDockControl); override;
  end;

  { TACLDockZoneClient }

  TACLDockZoneClient = class(TACLDockZone)
  strict private
    function GetParentClientRect: TRect;
  protected
    function CalculateBounds: TRect; override;
  public
    constructor Create(AOwner: TComponent); override;
    function AllowDock(ASource: TACLDockControl): Boolean; override;
    procedure CalculateSelection(ASource: TACLDockControl; var ABounds: TRect); override;
    procedure CreateLayout(ASource: TACLDockControl); override;
  end;

  { TACLDockZoneClientSide }

  TACLDockZoneClientSide = class(TACLDockZoneSide)
  strict private
    FClient: TACLDockZoneClient;
  protected
    function CalculateBounds: TRect; override;
  public
    constructor Create(AClient: TACLDockZoneClient; ASide: TACLBorder); reintroduce;
    function AllowDock(ASource: TACLDockControl): Boolean; override;
    procedure CreateLayout(ASource: TACLDockControl); override;
  end;

{$ENDREGION}

{$REGION ' DockEngine '}

  { TACLDragSelection }

  TACLDragSelection = class(TForm)
  strict private
    procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Show;
  end;

  { TACLDockEngine }

  TACLDockEngine = class
  strict private
    FDockZones: TACLDockZones;
    FDragSelection: TACLDragSelection;
    FDragTarget: TACLDockControl;
    FDragTargetSite: TACLDockControl;
    FDragTargetZone: TACLDockZone;
    FExecutor: TACLDockControl;
    FInitialPos: TPoint;
    FNonClientExtends: TRect;

    procedure CreateFloatLayout;
  public
    constructor Create(AExecutor: TACLDockControl);
    destructor Destroy; override;
    procedure CreateLayout;
    procedure UpdateDragTarget(AScreenPos: TPoint); overload;
    procedure UpdateDragTarget(AScreenPos: TPoint; ATarget: TControl); overload;
  end;

{$ENDREGION}

{$REGION ' DockControls '}

  { TACLDockControl }

  TACLDockControlClass = class of TACLDockControl;
  TACLDockControl = class(TACLCustomControl, IACLCursorProvider)
  protected const
    CursorMap: array[TACLBorder] of TCursor = (crHSplit, crVSplit, crHSplit, crVSplit);
  protected type
    TDragState = (None, Drag, Resize);
  strict private
    FDockEngine: TACLDockEngine;
    FDragCapture: TPoint;
    FDragState: TDragState;
    FSideBar: TACLDockSiteSideBar;
    FSizingBorder: TACLBorder;
    FStyle: TACLStyleDocking;

    function GetSize(Side: TACLBorder): Integer;
    procedure SetCustomHeight(AValue: Integer);
    procedure SetCustomWidth(AValue: Integer);
    procedure SetSideBar(AValue: TACLDockSiteSideBar);
    procedure SetSize(Side: TACLBorder; AValue: Integer);
    procedure SetStyle(AValue: TACLStyleDocking);
    //# Messages
    procedure CMCancelMode(var Message: TWMCancelMode); message CM_CANCELMODE;
    procedure CMControlListChange(var Message: TMessage); message CM_CONTROLLISTCHANGE;
    procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
  protected
    FCustomSize: TSize;
    FNeighbours: array[TACLBorder] of TACLDockControl;
    FSizing: Boolean;

    procedure Aligned; virtual;
    procedure Aligning; virtual;
    procedure ControlsAligning; virtual;
    function CreateStyle: TACLStyleDocking; virtual;
    procedure DefineProperties(Filer: TFiler); override;
    //# IACLCursorProvider
    function GetCursor(const P: TPoint): TCursor; virtual;
    //# Dragging
    procedure GetDockZones(ASource: TACLDockControl; AList: TACLDockZones); virtual;
    procedure StartDrag(const P: TPoint);
    procedure StartResize(const P: TPoint; ABorder: TACLBorder);
    //# Drawing
    procedure Paint; override;
    //# Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    //# Mouse
    function HitOnSizeBox(const P: TPoint;
      out AResizeHandler: TACLDockControl;
      out ASide: TACLBorder): Boolean; virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    //# Scaling
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    procedure SetTargetDPI(AValue: Integer); override;
    //# Storing
    function IsBoundsStored: Boolean; virtual;
    procedure LayoutLoad(ANode: TACLXMLNode); virtual;
    procedure LayoutSave(ANode: TACLXMLNode); virtual;
    procedure StoreCustomSize;
    //# States
    function IsPinnedToSideBar: Boolean; virtual;

    function GetMinHeight: Integer; inline;
    function GetOuterPadding: TRect; virtual;

    property DragState: TDragState read FDragState;
    property SideBar: TACLDockSiteSideBar read FSideBar write SetSideBar;
    property Size[Side: TACLBorder]: Integer read GetSize write SetSize;
    property Style: TACLStyleDocking read FStyle write SetStyle;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    property DoubleBuffered default True;
    property CustomHeight: Integer read FCustomSize.cy write SetCustomHeight default 100;
    property CustomWidth: Integer read FCustomSize.cx write SetCustomWidth default 100;
    property Left stored IsBoundsStored;
    property Top stored IsBoundsStored;
    property Height stored IsBoundsStored;
    property Width stored IsBoundsStored;
  end;

  { TACLDockGroup }

  TACLDockGroup = class(TACLDockControl)
  protected const
    AlignFirst = [alLeft, alTop];
    AlignClient = [alNone, alClient];
    AlignLast = [alRight, alBottom];
    MinChildWidth = 120;
    TabAreaBorders = [mLeft, mBottom, mRight];
  strict private type
  {$REGION ' Internal Types '}
    TTab = record
      Control: TACLDockControl;
      Bounds: TRect;
    end;
  {$ENDREGION}
  strict private
    FActiveControlIndex: Integer;
    FContentRect: TRect;
    FLayout: TACLDockGroupLayout;
    FTabActiveIndex: Integer;
    FTabCapture: TTab;
    FTabs: array of TTab;
    FTabsArea: TRect;

    procedure AlignHorizontally(ABounds: TACLDeferPlacementUpdate; var ARect: TRect);
    procedure AlignTabbed(ABounds: TACLDeferPlacementUpdate; var ARect: TRect);
    procedure AlignVertically(ABounds: TACLDeferPlacementUpdate; var ARect: TRect);
    procedure CalculateTabs(ARect: TRect);
    procedure DrawTabs(ACanvas: TCanvas);
    procedure DrawTabText(ACanvas: TCanvas; const ATab: TTab);
    function GetActiveControl: TACLDockControl;
    procedure GetChildrenInDisplayOrder(AList: TList);
    function GetControl(Index: Integer): TACLDockControl; inline;
    function GetTabAtPos(const P: TPoint; out ATab: TTab): Boolean;
    function GetVisibleControlCount: Integer;
    procedure SetActiveControlIndex(AValue: Integer);
    procedure SetLayout(AValue: TACLDockGroupLayout);
  protected
    FReferences: Integer;
    FRestSpace: TRect;

    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    procedure ControlsAligned; override;
    procedure ControlsAligning; override;
    function HasTabs: Boolean; inline;
    function ResizeChild(AChild: TACLDockControl; ASide: TACLBorder; ADelta: Integer): Integer;
    procedure ValidateInsert(AComponent: TComponent); override;
    // IACLCursorProvider
    function GetCursor(const P: TPoint): TCursor; override;
    //# Drawing
    procedure Paint; override;
    //# Storing
    procedure LayoutLoad(ANode: TACLXMLNode); override;
    procedure LayoutSave(ANode: TACLXMLNode); override;
    //# Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    //# Messages
    procedure CMCancelMode(var Message: TWMCancelMode); message CM_CANCELMODE;
    procedure CMControlListChange(var Message: TMessage); message CM_CONTROLLISTCHANGE;
    procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure CMDockingPack(var Message: TMessage); message CM_DOCKING_PACK;
    procedure CMDockingUpdateList(var Message: TMessage); message CM_DOCKING_UPDATELIST;
    procedure CMDockingUpdateText(var Message: TMessage); message CM_DOCKING_UPDATETEXT;
    procedure CMDockingVisibility(var Message: TMessage); message CM_DOCKING_VISIBILITY;
    //# Properties
    property ContentRect: TRect read FContentRect;
  public
    constructor Create(AOwner: TComponent); override;
    procedure GetTabOrderList(List: TList); override;
    function ToString: string; override;

    property ActiveControl: TACLDockControl read GetActiveControl;
    property Controls[Index: Integer]: TACLDockControl read GetControl;
    property VisibleControlCount: Integer read GetVisibleControlCount;
  published
    property ActiveControlIndex: Integer read FActiveControlIndex write SetActiveControlIndex default -1;
    property DoubleBuffered default False;
    property Layout: TACLDockGroupLayout read FLayout write SetLayout;
  end;

  { TACLDockPanel }

  TACLDockPanel = class(TACLDockControl)
  strict private type
    TCaptionButton = (Close, Maximize{not implemented}, Pin);
  strict private
    FCaptionButtonActiveIndex: Integer;
    FCaptionButtonPressedIndex: Integer;
    FCaptionButtons: array[TCaptionButton] of TRect;
    FCaptionRect: TRect;
    FCaptionTextRect: TRect;
    FShowCaption: Boolean;

    procedure CalculateCaptionButtons;
    procedure CaptionButtonClick(AButton: TCaptionButton);
    function GetCaptionButtonState(AButton: TCaptionButton): Integer;
    function HasBorders: Boolean;
    function HitOnCaptionButton(const P: TPoint): Integer;
    procedure SetCaptionButtonActiveIndex(AValue: Integer);
    procedure SetCaptionButtonPressedIndex(AValue: Integer);
    procedure SetShowCaption(AValue: Boolean);
  protected
    procedure Aligned; override;
    function AllowPin: Boolean; virtual;
    function CanStartDrag: Boolean; virtual;
    function CreatePadding: TACLPadding; override;
    function GetContentOffset: TRect; override;
    function GetOuterPadding: TRect; override;
  {$IFDEF ACL_DOCKING_PIN_TABBED_GROUP}
    function IsPinnedToSideBar: Boolean; override;
  {$ENDIF}
    procedure SetParent(AParent: TWinControl); override;
    procedure ValidateInsert(AComponent: TComponent); override;
    // IACLCursorProvider
    function GetCursor(const P: TPoint): TCursor; override;
    //# storing
    procedure LayoutLoad(ANode: TACLXMLNode); override;
    procedure LayoutSave(ANode: TACLXMLNode); override;
    //# Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    //# Drawing
    procedure Paint; override;
    //# Messages
    procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    function ToString: string; override;
  published
    property Caption;
    property ShowCaption: Boolean read FShowCaption write SetShowCaption default True;
    property Style;
  end;

{$ENDREGION}

{$REGION ' FloatDockForm '}

  { TACLFloatDockForm }

  TACLFloatDockForm = class(TACLForm)
  strict private
    FDockGroup: TACLDockGroup;
    FMainSite: TACLDockSite;

    procedure CMControlListChange(var Message: TMessage); message CM_CONTROLLISTCHANGE;
    procedure CMDockingPack(var Message: TMessage); message CM_DOCKING_PACK;
    procedure CMDockingUpdateText(var Message: TMessage); message CM_DOCKING_UPDATETEXT;
    procedure CMDockingVisibility(var Message: TMessage); message CM_DOCKING_VISIBILITY;
    procedure WMEnterSizeMove(var Message: TMessage); message WM_ENTERSIZEMOVE;
    procedure WMExitSizeMove(var Message: TMessage); message WM_EXITSIZEMOVE;
    procedure WMNCLButtonDown(var Message: TWMNCLButtonDown); message WM_NCLBUTTONDOWN;
  protected
    procedure CreateHandle; override;
    procedure DoClose(var Action: TCloseAction); override;
    function GetNonClientExtends: TRect;
    procedure LayoutLoad(ANode: TACLXMLNode);
    procedure LayoutSave(ANode: TACLXMLNode);
  public
    constructor Create(AOwner: TACLDockSite); reintroduce;
    destructor Destroy; override;
    property DockGroup: TACLDockGroup read FDockGroup;
    property MainSite: TACLDockSite read FMainSite;
  end;

{$ENDREGION}

{$REGION ' SideBars '}

  TACLDockSiteSideBars = class;

  { TACLDockSiteSideBarTab }

  TACLDockSiteSideBarTab = class(TComponent)
  strict private
    FBounds: TRect;
    FControl: TACLDockControl;
    FPrevAlign: TAlign;
    FPrevIndex: Integer;
    FPrevParent: TACLDockGroup;

    procedure SetPrevParent(AValue: TACLDockGroup);
  protected
    procedure LayoutLoad(ANode: TACLXMLNode; AOwner: TComponent);
    procedure LayoutSave(ANode: TACLXMLNode);
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;

    property PrevAlign: TAlign read FPrevAlign;
    property PrevIndex: Integer read FPrevIndex;
    property PrevParent: TACLDockGroup read FPrevParent;
  public
    constructor Create(AControl: TACLDockControl); reintroduce;
    destructor Destroy; override;
    property Bounds: TRect read FBounds write FBounds;
    property Control: TACLDockControl read FControl;
  end;

  { TACLDockSiteSideBar }

  TACLDockSiteSideBar = class(TComponent)
  strict private
    FBounds: TRect;
    FOwner: TACLDockSiteSideBars;
    FSide: TACLBorder;
    FStyle: TACLStyleDockSite;

    function GetMainSite: TACLDockSite; inline;
  protected
    FTabs: TACLList<TACLDockSiteSideBarTab>;

    procedure Calculate;
    procedure Changed;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure RestorePosition(ATab: TACLDockSiteSideBarTab);
    //# Storing
    procedure LayoutLoad(ANode: TACLXMLNode);
    procedure LayoutSave(ANode: TACLXMLNode);
  public
    constructor Create(AOwner: TACLDockSiteSideBars; ASide: TACLBorder); reintroduce;
    destructor Destroy; override;
    function CalculatePopupBounds(AChild: TACLDockControl): TRect;
    procedure Draw(ACanvas: TCanvas);
    function FindTab(AControl: TACLDockControl): TACLDockSiteSideBarTab;
    function HitTest(const P: TPoint): TACLDockSiteSideBarTab;
    procedure Register(AControl: TACLDockControl);
    procedure Unregister(AControl: TACLDockControl);

    property Bounds: TRect read FBounds write FBounds;
    property MainSite: TACLDockSite read GetMainSite;
    property Owner: TACLDockSiteSideBars read FOwner;
    property Style: TACLStyleDockSite read FStyle;
    property Side: TACLBorder read FSide;
  end;

  { TACLDockSiteSideBars }

  TACLDockSiteSideBars = class(TACLUnknownObject, IACLAnimateControl)
  strict private const
    AutoHideDelayTime = 500;
    AutoShowDelayTime = 300;
    ShowAnimationTime = 200;
  strict private
    FActiveTab: TACLDockSiteSideBarTab;
    FAutoHideTimer: TACLTimer;
    FAutoShowTimer: TACLTimer;
    FBars: array [TACLBorder] of TACLDockSiteSideBar;
    FCursorPos: TPoint;
    FSite: TACLDockSite;
  {$IFDEF ACL_DOCKING_ANIMATE_SIDEBAR}
    FShowAnimation: TACLAnimation;
  {$ENDIF}

    procedure AutoHideProc(Sender: TObject);
    procedure AutoShowProc(Sender: TObject);
    function HitTest(const P: TPoint): TACLDockSiteSideBar;
    function IsValid(ATab: TACLDockSiteSideBarTab): Boolean;
  protected
    procedure ActivateTab(ATab: TACLDockSiteSideBarTab; AAnimate: Boolean = True);
    procedure Calculate(var ABounds: TRect);
    procedure CalculateLayout;
    procedure Changed(ASender: TACLDockSiteSideBar);
    // IACLAnimateControl
    procedure Animate;
    //# Drawing
    procedure Draw(ACanvas: TCanvas);
    procedure Invalidate;
    //# Storing
    procedure LayoutLoad(ANode: TACLXMLNode);
    procedure LayoutSave(ANode: TACLXMLNode);
    //# Mouse
    procedure MouseDown(const P: TPoint; AChild: TACLDockControl);
    procedure MouseMove(const P: TPoint);
    //# Properties
    property Site: TACLDockSite read FSite;
  {$IFDEF ACL_DOCKING_ANIMATE_SIDEBAR}
    property ShowAnimation: TACLAnimation read FShowAnimation;
  {$ENDIF}
  public
    constructor Create(ASite: TACLDockSite);
    destructor Destroy; override;
    function OptimalFor(AControl: TACLDockControl): TACLDockSiteSideBar;
    property ActiveTab: TACLDockSiteSideBarTab read FActiveTab;
  end;

{$ENDREGION}

  { TACLDockSite }

  TACLDockSite = class(TACLDockGroup)
  strict private
    FFloatForms: TACLObjectList<TACLFloatDockForm>;
    FSideBars: TACLDockSiteSideBars;

    function GetStyle: TACLStyleDockSite;
    procedure ResetLayoutAndHidePanels;
    procedure SetStyle(AValue: TACLStyleDockSite);
  protected
    //# Aligning
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    //# Misc
    function CreateStyle: TACLStyleDocking; override;
    procedure GetDockZones(ASource: TACLDockControl; AList: TACLDockZones); override;
    function IsBoundsStored: Boolean; override;
    procedure Paint; override;
    //# Mouse
    function HitOnSizeBox(const P: TPoint; out X: TACLDockControl; out Y: TACLBorder): Boolean; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    //# Messages
    procedure CMDockingUpdateText(var Message: TMessage); message CM_DOCKING_UPDATETEXT;
    procedure CMDockingVisibility(var Message: TMessage); message CM_DOCKING_VISIBILITY;
    //# Properties
    property FloatForms: TACLObjectList<TACLFloatDockForm> read FFloatForms;
    property SideBars: TACLDockSiteSideBars read FSideBars;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LayoutLoad(const ADocument: TACLXMLDocument); reintroduce; overload;
    procedure LayoutLoad(const AFileName: string); reintroduce; overload;
    procedure LayoutSave(const ADocument: TACLXMLDocument); reintroduce; overload;
    procedure LayoutSave(const AFileName: string); reintroduce; overload;
  published
    property Align default alClient;
    property Style: TACLStyleDockSite read GetStyle write SetStyle;
  end;

implementation

type

  { TACLDockingSchema }

  TACLDockingSchema = class
  public const
    AttrAlign = 'align';
    AttrHeight = 'h';
    AttrIdent = 'id';
    AttrIndex = 'idx';
    AttrLayout = 'layout';
    AttrName = 'name';
    AttrPosition = 'pos';
    AttrVisible = 'visible';
    AttrWidth = 'w';
    NodeEmbedded = 'embedded';
    NodeFloat = 'float';
    NodeItem = 'item';
    NodePos = 'pos';
    NodeRoot = 'docking';
    NodeSideBar = 'sideBar';
  end;

function GetNearestDockControl(ATarget: TControl; AClass: TACLDockControlClass): Pointer{class of TACLDockControl};
begin
  while (ATarget <> nil) and not ATarget.InheritsFrom(AClass) do
    ATarget := ATarget.Parent;
  Result := ATarget;
end;

function IndexOfControl(AControl: TControl): Integer;
begin
  if AControl.Parent <> nil then
    for var I := 0 to AControl.Parent.ControlCount - 1 do
    begin
      if AControl.Parent.Controls[I] = AControl then
        Exit(I);
    end;
  Result := -1;
end;

{$REGION ' Styles '}

{ TACLStyleDocking }

function TACLStyleDocking.GetTabMargins: TRect;
begin
  Result := dpiApply(Rect(4, 4, 4, 4), TargetDPI);
end;

procedure TACLStyleDocking.InitializeResources;
begin
  ColorBorder1.InitailizeDefaults('Docking.Colors.Border1', True);
  ColorBorder2.InitailizeDefaults('Docking.Colors.Border2', True);
  ColorContent1.InitailizeDefaults('Docking.Colors.Background1', True);
  ColorContent2.InitailizeDefaults('Docking.Colors.Background2', True);
  HeaderButton.InitailizeDefaults('Docking.Textures.HeaderButton');
  HeaderButtonGlyphs.InitailizeDefaults('Docking.Textures.HeaderButtonGlyphs');
  HeaderColorContent1.InitailizeDefaults('Docking.Colors.Header1', True);
  HeaderColorContent2.InitailizeDefaults('Docking.Colors.Header2', True);
  HeaderTextAlignment := taLeftJustify;
  HeaderTextFont.InitailizeDefaults('Docking.Fonts.Header');
  TabArea.InitailizeDefaults('Docking.Colors.TabsArea', clNone);
  TabFont.InitailizeDefaults('Docking.Fonts.Tab');
  TabFontActive.InitailizeDefaults('Docking.Fonts.TabActive');
end;

function TACLStyleDocking.MeasureTabHeight: Integer;
begin
  MeasureCanvas.Font.Assign(TabFontActive);
  Result := MeasureCanvas.TextHeight('Wg') + GetTabMargins.MarginsHeight + dpiApply(TabControlOffset, TargetDPI);
end;

function TACLStyleDocking.MeasureTabWidth(const ACaption: string): Integer;
begin
  Result := 0;
  MeasureCanvas.Font.Assign(TabFont);
  Result := Max(Result, acTextSize(MeasureCanvas, ACaption).cx);
  MeasureCanvas.Font.Assign(TabFontActive);
  Result := Max(Result, acTextSize(MeasureCanvas, ACaption).cx);
  Inc(Result, GetTabMargins.MarginsWidth);
end;

{ TACLStyleDockSite }

procedure TACLStyleDockSite.InitializeResources;
begin
  inherited;
  SideBar.InitailizeDefaults('Docking.Colors.SideBar');
  SideBarTab.InitailizeDefaults('Docking.Textures.SideBar');
  SideBarTabFont.InitailizeDefaults('Docking.Fonts.SideBar');
  SideBarTabFontActive.InitailizeDefaults('Docking.Fonts.SideBar');
end;

function TACLStyleDockSite.MeasureSideBarTabHeight: Integer;
begin
  MeasureCanvas.Font.Assign(SideBarTabFontActive);
  Result := MeasureCanvas.TextHeight('Wg') + GetTabMargins.MarginsHeight + dpiApply(TabControlOffset, TargetDPI);
end;

function TACLStyleDockSite.MeasureSideBarTabWidth(const ACaption: string): Integer;
begin
  Result := 0;
  MeasureCanvas.Font.Assign(SideBarTabFont);
  Result := Max(Result, acTextSize(MeasureCanvas, ACaption).cx);
  MeasureCanvas.Font.Assign(SideBarTabFontActive);
  Result := Max(Result, acTextSize(MeasureCanvas, ACaption).cx);
  Inc(Result, GetTabMargins.MarginsWidth);
end;

{$ENDREGION}

{$REGION ' DockZones '}

{ TACLDockZone }

constructor TACLDockZone.Create(AOwner: TComponent);
begin
  inherited;
  FSkin := TACLSkinImage.Create;
end;

destructor TACLDockZone.Destroy;
begin
  FreeAndNil(FSkin);
  inherited;
end;

procedure TACLDockZone.AfterConstruction;
begin
  inherited;
  Skin.Layout := ilVertical;
  Skin.FrameCount := 2;
end;

function TACLDockZone.AllowDock(ASource: TACLDockControl): Boolean;
begin
  Result := False;
end;

function TACLDockZone.CalculateBounds: TRect;
const
  Padding = 5;
begin
  Result := TRect.Create(GetSkinSize);
  Inc(Result.Bottom, 2 * dpiApply(Padding, FCurrentPPI));
  Inc(Result.Right, 2 * dpiApply(Padding, FCurrentPPI));
end;

procedure TACLDockZone.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.ExStyle := WS_EX_TOPMOST or WS_EX_LAYERED or WS_EX_TOOLWINDOW;
  Params.Style := WS_POPUP;
end;

function TACLDockZone.CreateDockGroupForReplacement(AControl: TACLDockControl): TACLDockGroup;
var
  ADockSite: TACLDockControl;
begin
  Result := TACLDockGroup.Create(AControl.Owner);
  Result.Align := AControl.Align;
  Result.Parent := AControl.Parent;
  Result.FCustomSize := AControl.FCustomSize;
  TACLDockGroup(Result.Parent).SetChildOrder(Result, IndexOfControl(AControl));

  ADockSite := GetNearestDockControl(AControl, TACLDockSite);
  if ADockSite <> nil then
    Result.Style := ADockSite.Style;
end;

procedure TACLDockZone.CMEnabledChanged(var Message: TMessage);
begin
  Update;
end;

function TACLDockZone.GetParent: TACLDockControl;
begin
  Result := Owner as TACLDockControl;
end;

function TACLDockZone.GetSkinSize: TSize;
begin
  Result := dpiApply(Skin.FrameSize, FCurrentPPI);
end;

procedure TACLDockZone.SetActive(AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    FActive := AValue;
    Update;
  end;
end;

procedure TACLDockZone.Show;
begin
  with CalculateBounds do
    SetWindowPos(Handle, HWND_TOPMOST, Left, Top, Width, Height,
      SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_SHOWWINDOW);
  Update;
end;

procedure TACLDockZone.Update;
var
  ALayer: TACLDib;
begin
  if (Width = 0) or (Height = 0) then Exit;
  ALayer := TACLDib.Create(Width, Height);
  try
    acFillRect(ALayer.Canvas, ALayer.ClientRect, TAlphaColor($FFFAFAFA));
    acDrawFrame(ALayer.Canvas, ALayer.ClientRect, TAlphaColor($FFA5A5A5));
    Skin.Draw(ALayer.Canvas, ALayer.ClientRect.CenterTo(GetSkinSize), Ord(Active and Enabled), Enabled);
    acUpdateLayeredWindow(Handle, ALayer.Handle, BoundsRect);
  finally
    ALayer.Free;
  end;
end;

{ TACLDockZones }

procedure TACLDockZones.DeleteByOwner(AOwner: TComponent);
begin
  for var I := Count - 1 downto 0 do
  begin
    if List[I].Owner = AOwner then
      Delete(I);
  end;
end;

procedure TACLDockZones.Show;
begin
  for var I := 0 to Count - 1 do
    List[I].Show;
end;

procedure TACLDockZones.UpdateState(ASource: TACLDockControl);
begin
  for var I := 0 to Count - 1 do
    List[I].Enabled := List[I].AllowDock(ASource);
end;

{ TACLDockZoneSide }

constructor TACLDockZoneSide.Create(AOwner: TComponent; ASide: TACLBorder);
const
  NameMap: array[TACLBorder] of string = ('LEFT', 'TOP', 'RIGHT', 'BOTTOM');
begin
  FSide := ASide;
  inherited Create(AOwner);
  Skin.LoadFromResource(HInstance, 'ACLDOCKING_' + NameMap[ASide], RT_BITMAP);
end;

function TACLDockZoneSide.AllowDock(ASource: TACLDockControl): Boolean;
begin
  Result := True;
end;

function TACLDockZoneSide.CalculateBounds: TRect;
var
  ABounds: TRect;
begin
  ABounds := Parent.ClientToScreen(Parent.ClientRect);
  Result := inherited;
  case Side of
    TACLBorder.mLeft:
      Result.Offset(ABounds.Left, ABounds.CenterPoint.Y - Result.Height div 2);
    TACLBorder.mRight:
      Result.Offset(ABounds.Right - Result.Right, ABounds.CenterPoint.Y - Result.Height div 2);
    TACLBorder.mBottom:
      Result.Offset(ABounds.CenterPoint.X - Result.Width div 2, ABounds.Bottom - Result.Height);
    TACLBorder.mTop:
      Result.Offset(ABounds.CenterPoint.X - Result.Width div 2, ABounds.Top);
  end;
end;

procedure TACLDockZoneSide.CalculateSelection(ASource: TACLDockControl; var ABounds: TRect);
begin
  ABounds := Parent.ClientToScreen(Parent.ClientRect);
  case Side of
    TACLBorder.mLeft:
      ABounds.Width := Max(ASource.CustomWidth, SelectionSize);
    TACLBorder.mRight:
      ABounds.Left := ABounds.Right - Max(ASource.CustomWidth, SelectionSize);
    TACLBorder.mBottom:
      ABounds.Top := ABounds.Bottom - Max(ASource.CustomHeight, SelectionSize);
    TACLBorder.mTop:
      ABounds.Height := Max(ASource.CustomHeight, SelectionSize);
  end;
end;

procedure TACLDockZoneSide.CreateLayout(ASource: TACLDockControl);
var
  ADockGroup: TACLDockGroup;
  ASourceDockGroup: TWinControl;
  ATargetDockGroup: TACLDockGroup;
begin
  ASourceDockGroup := ASource.Parent;
  ATargetDockGroup := Parent as TACLDockGroup;
  ATargetDockGroup.DisableAlign;
  try
    if ATargetDockGroup.Layout <> GetLayoutDirection then
    begin
      ADockGroup := TACLDockGroup.Create(ATargetDockGroup.Owner);
      ADockGroup.Align := alClient;
      ADockGroup.Layout := ATargetDockGroup.Layout;
      ADockGroup.DisableAlign;
      try
        while ATargetDockGroup.ControlCount > 0 do
          ATargetDockGroup.Controls[0].Parent := ADockGroup;
        ADockGroup.ActiveControlIndex := ATargetDockGroup.ActiveControlIndex;
      finally
        ADockGroup.EnableAlign;
      end;
      ADockGroup.Parent := ATargetDockGroup;
      ATargetDockGroup.Layout := GetLayoutDirection;
    end;

    ASource.Parent := ATargetDockGroup;
    if Side in [mRight, mBottom] then      
    begin
      ATargetDockGroup.SetChildOrder(ASource, ATargetDockGroup.ControlCount);
      ASource.Align := alRight;
    end
    else
    begin
      ATargetDockGroup.SetChildOrder(ASource, 0);
      ASource.Align := alLeft;
    end;
    ASourceDockGroup.Perform(CM_DOCKING_PACK, 0, 0);
    ATargetDockGroup.Realign;
  finally
    ATargetDockGroup.EnableAlign;
  end;
end;

function TACLDockZoneSide.GetLayoutDirection: TACLDockGroupLayout;
begin
  if Side in [mLeft, mRight] then
    Result := TACLDockGroupLayout.Horizontal
  else
    Result := TACLDockGroupLayout.Vertical;
end;

{ TACLDockZoneClient }

constructor TACLDockZoneClient.Create(AOwner: TComponent);
begin
  inherited;
  Skin.LoadFromResource(HInstance, 'ACLDOCKING_CLIENT', RT_BITMAP);
end;

function TACLDockZoneClient.AllowDock(ASource: TACLDockControl): Boolean;
begin
  // Оно и для док-сайтов будет работать, но выглядит уродливо
  Result := ASource is TACLDockPanel;
end;

function TACLDockZoneClient.CalculateBounds: TRect;
begin
  Result := inherited;
  Result.Offset(Parent.ClientToScreen(GetParentClientRect.CenterPoint));
  Result.Offset(-Result.Width div 2, -Result.Height div 2);
end;

procedure TACLDockZoneClient.CalculateSelection(ASource: TACLDockControl; var ABounds: TRect);
begin
  ABounds := Parent.ClientToScreen(GetParentClientRect);
  ABounds.Inflate(-dpiApply(16, FCurrentPPI));
end;

procedure TACLDockZoneClient.CreateLayout(ASource: TACLDockControl);
var
  ADockGroup: TACLDockGroup;
  ASourceParent: TWinControl;
  ATarget: TACLDockControl;
  ATargetDockGroup: TACLDockGroup;
begin
  ATarget := Parent;
  ASourceParent := ASource.Parent;
  if ATarget is TACLDockPanel then
  begin
    ATargetDockGroup := ATarget.Parent as TACLDockGroup;
    if ATargetDockGroup.Layout = TACLDockGroupLayout.Tabbed then
    begin
      ATargetDockGroup.DisableAlign;
      try
        ASource.Parent := ATargetDockGroup;
        ASource.Align := alClient;
        ATargetDockGroup.ActiveControlIndex := IndexOfControl(ASource);
      finally
        ATargetDockGroup.EnableAlign;
      end;
    end
    else
    begin
      ADockGroup := CreateDockGroupForReplacement(ATarget);
      ADockGroup.Layout := TACLDockGroupLayout.Tabbed;
      ADockGroup.DisableAlign;
      try
        ATarget.Parent := ADockGroup;
        ASource.Parent := ADockGroup;
        ASource.Align := alClient;
        ATarget.Align := alClient;
        ADockGroup.ActiveControlIndex := 1;
      finally
        ADockGroup.EnableAlign;
      end;
    end;
  end
  else
    if ATarget is TACLDockGroup then
    begin
      ATarget.DisableAlign;
      try
        ASource.Parent := ATarget;
        ASource.Align := alClient;
      finally
        ATarget.EnableAlign;
      end;
    end;

  ASourceParent.Perform(CM_DOCKING_PACK, 0, 0);
end;

function TACLDockZoneClient.GetParentClientRect: TRect;
begin
  Result := NullRect;
  if Parent is TACLDockGroup then
    Result := TACLDockGroup(Parent).FRestSpace;
  if Result.IsEmpty then
    Result := Parent.ClientRect;  
end;

{ TACLDockZoneClientSide }

constructor TACLDockZoneClientSide.Create(AClient: TACLDockZoneClient; ASide: TACLBorder);
begin
  FClient := AClient;
  inherited Create(AClient.Owner, ASide);
end;

function TACLDockZoneClientSide.AllowDock(ASource: TACLDockControl): Boolean;
var
  ADockGroup: TACLDockGroup;
begin
  Result := False;
  if Parent is TACLDockPanel then
  begin
    ADockGroup := Parent.Parent as TACLDockGroup;
    if ADockGroup.Layout <> TACLDockGroupLayout.Tabbed then
    begin
      Result := 
        (ADockGroup.Layout <> GetLayoutDirection) or
        (ASource.Parent <> ADockGroup) or (ASource.Align <> alClient) or
        (IndexOfControl(ASource) <> IndexOfControl(Parent) + Signs[Side in [mRight, mBottom]]);
    end;
  end;
end;

function TACLDockZoneClientSide.CalculateBounds: TRect;
const
  BordersMerging = 2;
var
  AClientBounds: TRect;
begin
  Result := inherited;
  Result.Offset(-Result.Left, -Result.Top);

  AClientBounds := FClient.CalculateBounds;
  case Side of
    TACLBorder.mLeft, TACLBorder.mRight:
      Result.Offset(0, (AClientBounds.Top + AClientBounds.Bottom - Result.Height) div 2);
    TACLBorder.mTop, TACLBorder.mBottom:
      Result.Offset((AClientBounds.Left + AClientBounds.Right - Result.Width) div 2, 0);
  end;

  case Side of
    TACLBorder.mLeft:
      Result.Offset(AClientBounds.Left - Result.Width + BordersMerging, 0);
    TACLBorder.mRight:
      Result.Offset(AClientBounds.Right - BordersMerging, 0);
    TACLBorder.mBottom:
      Result.Offset(0, AClientBounds.Bottom - BordersMerging);
    TACLBorder.mTop:
      Result.Offset(0, AClientBounds.Top - Result.Height + BordersMerging);
  end;
end;

procedure TACLDockZoneClientSide.CreateLayout(ASource: TACLDockControl);
var
  ADockGroup: TACLDockGroup;
  ASourceParent: TWinControl;
  ATarget: TACLDockControl;
  ATargetDockGroup: TACLDockGroup;
  ATargetIndex: Integer;
begin
  ATarget := Parent;
  if ATarget is TACLDockPanel then
  begin
    ASourceParent := ASource.Parent;
    ATargetIndex := IndexOfControl(ATarget);
    ATargetDockGroup := ATarget.Parent as TACLDockGroup;
    ATargetDockGroup.DisableAlign;
    try
      if (ASourceParent = ATargetDockGroup) and (ATargetDockGroup.ControlCount = 2) then
        ATargetDockGroup.Layout := GetLayoutDirection;
      if ATargetDockGroup.Layout = GetLayoutDirection then
      begin
        if Side in [mRight, mBottom] then
          Inc(ATargetIndex);
        if (ASourceParent = ATargetDockGroup) and (IndexOfControl(ASource) < ATargetIndex) then
          Dec(ATargetIndex);
        ASource.Parent := ATargetDockGroup;
        ASource.Align := ATarget.Align;
        ATargetDockGroup.SetChildOrder(ASource, ATargetIndex);
      end
      else
      begin
        ADockGroup := CreateDockGroupForReplacement(ATarget);
        ADockGroup.Layout := GetLayoutDirection;
        ADockGroup.DisableAlign;
        try
          if Side in [mRight, mBottom] then
          begin
            ATarget.Parent := ADockGroup;
            ASource.Parent := ADockGroup;
          end
          else
          begin
            ASource.Parent := ADockGroup;
            ATarget.Parent := ADockGroup;
          end;
          ASource.Align := alClient;
          ATarget.Align := alClient;
        finally
          ADockGroup.EnableAlign;
        end;
      end;
      ATargetDockGroup.Realign;
      ASourceParent.Perform(CM_DOCKING_PACK, 0, 0);
    finally
      ATargetDockGroup.EnableAlign;
      ATargetDockGroup.Perform(CM_DOCKING_PACK, 0, 0);
    end;
  end
  else
    inherited;
end;

{$ENDREGION}

{$REGION ' DockEngine '}

{ TACLDragSelection }

constructor TACLDragSelection.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Color := acDragImageColor;
  Cursor := crSizeAll;
  Position := poDesigned;
  BorderStyle := bsNone;
  AlphaBlend := True;
  AlphaBlendValue := acDragImageAlpha;
end;

procedure TACLDragSelection.Show;
begin
  ShowWindow(Handle, SW_SHOWNA);
end;

procedure TACLDragSelection.CMDesignHitTest(var Message: TCMDesignHitTest);
begin
  Message.Result := 1;
end;

procedure TACLDragSelection.WMNCHitTest(var Message: TWMNCHitTest);
begin
  Message.Result := HTTRANSPARENT;
end;

{ TACLDockEngine }

constructor TACLDockEngine.Create(AExecutor: TACLDockControl);
begin
  FExecutor := AExecutor;
  FDockZones := TACLDockZones.Create;
  FDragSelection := TACLDragSelection.Create(nil);
  FInitialPos := Mouse.CursorPos;
  if FExecutor.Parent is TACLFloatDockForm then
  begin
    FNonClientExtends := TACLFloatDockForm(AExecutor.Parent).GetNonClientExtends;
    if FExecutor.ControlCount = 1 then
      FExecutor := FExecutor.Controls[0] as TACLDockControl;
  end;
end;

destructor TACLDockEngine.Destroy;
begin
  FreeAndNil(FDragSelection);
  FreeAndNil(FDockZones);
  inherited;
end;

procedure TACLDockEngine.CreateFloatLayout;
var
  AIndents: TRect;
  AExtends: TRect;
  AFloatForm: TACLFloatDockForm;
  AFloatFormBounds: TRect;
  ADockSite: TACLDockSite;
  ASourceDockGroup: TACLDockGroup;
begin
  if Safe.Cast(FExecutor.Parent, TACLDockGroup, ASourceDockGroup) then
  begin
    ADockSite := GetNearestDockControl(FExecutor, TACLDockSite);
    if ADockSite = nil then
    begin
      if Safe.Cast(GetParentForm(FExecutor, False), TACLFloatDockForm, AFloatForm) then
        ADockSite := AFloatForm.MainSite;
    end;
    if ADockSite <> nil then
    begin
      AFloatFormBounds := FDragSelection.BoundsRect;

      AFloatForm := TACLFloatDockForm.Create(ADockSite);
      AFloatForm.Position := poDesigned;
      AFloatForm.BoundsRect := AFloatFormBounds;
      AFloatForm.ScaleForCurrentDPI;
      AFloatForm.HandleNeeded; // для 96-dpi

      // Чтобы невилировать отступы контента при выключении HasBorders
      AIndents := NullRect;
      FExecutor.AdjustClientRect(AIndents);
      if AFloatForm.FCurrentPPI <> FExecutor.FCurrentPPI then
      begin
        AIndents := dpiRevert(AIndents, FExecutor.FCurrentPPI);
        AIndents := dpiApply(AIndents, AFloatForm.FCurrentPPI);
        FNonClientExtends := dpiRevert(FNonClientExtends, FExecutor.FCurrentPPI);
        FNonClientExtends := dpiApply(FNonClientExtends, AFloatForm.FCurrentPPI);
      end;
      AExtends := AFloatForm.GetNonClientExtends;
      AExtends.MarginsAdd(
        -AIndents.Left, -AIndents.Top, AIndents.Right, AIndents.Bottom);
      AExtends.MarginsAdd(
        -FNonClientExtends.Left, -FNonClientExtends.Top,
        -FNonClientExtends.Right, -FNonClientExtends.Bottom);
      AFloatFormBounds := FDragSelection.BoundsRect;
      AFloatFormBounds.Inflate(AExtends);

      AFloatForm.BoundsRect := AFloatFormBounds;
      FExecutor.Parent := AFloatForm.DockGroup;
      FExecutor.Align := alClient;
      AFloatForm.Show;

      ASourceDockGroup.Perform(CM_DOCKING_PACK, 0, 0);
    end;
  end
  else
    if FExecutor.Parent is TACLFloatDockForm then
      TACLFloatDockForm(FExecutor.Parent).BoundsRect := FDragSelection.BoundsRect;
end;

procedure TACLDockEngine.CreateLayout;
begin
  if FDragTargetZone <> nil then
  begin
    if FDragTargetZone.AllowDock(FExecutor) then
      FDragTargetZone.CreateLayout(FExecutor);
  end
  else
    if not (csDesigning in FExecutor.ComponentState) then
      CreateFloatLayout;

  PostMessage(FExecutor.Handle, CM_DOCKING_PACK, 0, 0);
end;

procedure TACLDockEngine.UpdateDragTarget(AScreenPos: TPoint);
begin
  UpdateDragTarget(AScreenPos, FindDragTarget(AScreenPos, True));
end;

procedure TACLDockEngine.UpdateDragTarget(AScreenPos: TPoint; ATarget: TControl);

  function UpdateDockControl(var AField: TACLDockControl; AValue: TACLDockControl): Boolean;
  begin
    Result := AField <> AValue;
    if Result then
    begin
      if AField <> nil then
      begin
        FDockZones.DeleteByOwner(AField);
        AField := nil;
      end;
      if acIsChild(FExecutor, AValue) then
        Exit;
      if AValue <> nil then
      begin
        AField := AValue;
        if FExecutor <> AField then
          AField.GetDockZones(FExecutor, FDockZones);
      end;
    end;
  end;

var
  LSelectionBounds: TRect;
  LSize: TSize;
  LTargetDpi: Integer;
  LUpdateZones: Boolean;
  LZone: TACLDockZone;
begin
  LZone := nil;
  if ATarget is TACLDockZone then
  begin
    LZone := TACLDockZone(ATarget);
    ATarget := LZone.Parent;
  end;

  LUpdateZones := False;
  if UpdateDockControl(FDragTargetSite, GetNearestDockControl(ATarget, TACLDockSite)) then
    LUpdateZones := True;
  if UpdateDockControl(FDragTarget, GetNearestDockControl(ATarget, TACLDockControl)) then
    LUpdateZones := True;
  if LUpdateZones then
  begin
    FDockZones.UpdateState(FExecutor);
    FDockZones.Show;
  end;

  if LZone <> FDragTargetZone then
  begin
    if FDragTargetZone <> nil then
    begin
      if FDockZones.Contains(FDragTargetZone) then
        FDragTargetZone.Active := False;
      FDragTargetZone := nil;
    end;
    if FDockZones.Contains(LZone) then
    begin
      FDragTargetZone := LZone;
      FDragTargetZone.Active := True;
    end;
  end;

  LSelectionBounds := FExecutor.ClientToScreen(FExecutor.ClientRect);
  LSelectionBounds.Inflate(FNonClientExtends);
  LSelectionBounds.Offset(AScreenPos.X - FInitialPos.X, AScreenPos.Y - FInitialPos.Y);
  LTargetDpi := acGetTargetDPI(LSelectionBounds.CenterPoint);
  if LTargetDpi <> FExecutor.FCurrentPPI then
  begin
    LSize := dpiApply(dpiRevert(LSelectionBounds.Size, FExecutor.FCurrentPPI), LTargetDpi);
    LSelectionBounds.Bottom := AScreenPos.Y +
      MulDiv(LSize.cy, LSelectionBounds.Bottom - AScreenPos.Y, LSelectionBounds.Height);
    LSelectionBounds.Left := AScreenPos.X -
      MulDiv(LSize.cx, AScreenPos.X - LSelectionBounds.Left, LSelectionBounds.Width);
    LSelectionBounds.Right := AScreenPos.X +
      MulDiv(LSize.cx, LSelectionBounds.Right - AScreenPos.X, LSelectionBounds.Width);
    LSelectionBounds.Top := AScreenPos.Y -
      MulDiv(LSize.cy, AScreenPos.Y - LSelectionBounds.Top, LSelectionBounds.Height);
  end;
  if (FDragTargetZone <> nil) and FDragTargetZone.Enabled then
    FDragTargetZone.CalculateSelection(FExecutor, LSelectionBounds);
  FDragSelection.BoundsRect := LSelectionBounds;
  FDragSelection.Show;
end;

{$ENDREGION}

{$REGION ' DockControls '}

{ TACLDockControl }

constructor TACLDockControl.Create(AOwner: TComponent);
begin
  inherited;
  Align := alClient;
  ControlStyle := ControlStyle + [csAcceptsControls] - [csDoubleClicks, csCaptureMouse];
  FStyle := CreateStyle;
  FCustomSize := TSize.Create(100, 100);
  FDragCapture := InvalidPoint;
  DoubleBuffered := True;
end;

destructor TACLDockControl.Destroy;
begin
  SideBar := nil;
  FreeAndNil(FStyle);
  inherited;
end;

procedure TACLDockControl.Aligned;
begin
  ControlState := ControlState - [csAligning];
end;

procedure TACLDockControl.Aligning;
begin
  ControlState := ControlState + [csAligning];
  for var ASide := Low(TACLBorder) to High(TACLBorder) do
    FNeighbours[ASide] := nil;
end;

procedure TACLDockControl.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;
  FCustomSize.Scale(M, D);
end;

procedure TACLDockControl.ControlsAligning;
begin
  // do nothing
end;

function TACLDockControl.CreateStyle: TACLStyleDocking;
begin
  Result := TACLStyleDocking.Create(Self);
end;

procedure TACLDockControl.DefineProperties(Filer: TFiler);
begin
  // suppress Explicit // inherited;
end;

function TACLDockControl.GetCursor(const P: TPoint): TCursor;
var
  ACtrl: TACLDockControl;
  ASide: TACLBorder;
begin
  if FDragState = TDragState.Resize then
    Exit(CursorMap[FSizingBorder]);
  if FDragState = TDragState.Drag then
    Exit(crSizeAll);
  if HitOnSizeBox(P, ACtrl, ASide) then
    Exit(CursorMap[ASide]);
  Result := crDefault;
end;

procedure TACLDockControl.GetDockZones(ASource: TACLDockControl; AList: TACLDockZones);
var
  AClient: TACLDockZoneClient;
begin
  AClient := TACLDockZoneClient.Create(Self);
  for var ASide := Low(TACLBorder) to High(TACLBorder) do
    AList.Add(TACLDockZoneClientSide.Create(AClient, ASide));
  AList.Add(AClient);
end;

function TACLDockControl.GetMinHeight: Integer;
begin
  Result := Style.MeasureHeaderHeight + GetOuterPadding.MarginsHeight;
end;

function TACLDockControl.GetOuterPadding: TRect;
begin
  Result := TRect.CreateMargins(dpiApply(TACLStyleDocking.OuterPadding, FCurrentPPI));
end;

function TACLDockControl.GetSize(Side: TACLBorder): Integer;
begin
  if Side in [mLeft, mRight] then
    Result := Width
  else
    Result := Height;
end;

function TACLDockControl.HitOnSizeBox(const P: TPoint;
  out AResizeHandler: TACLDockControl; out ASide: TACLBorder): Boolean;

  function CheckAllowResize(ASide: TACLBorder): Boolean;
  const
    AllowedAlignments: array[TACLBorder] of TAlignSet = (
      TACLDockGroup.AlignLast, TACLDockGroup.AlignLast,
      TACLDockGroup.AlignFirst, TACLDockGroup.AlignFirst
    );
    OppositeBorders: array[TACLBorder] of TACLBorder = (
      mRight, mBottom, mLeft, mTop
    );
  begin
    Result := False;
    if FNeighbours[ASide] <> nil then
      Exit(True);
    if SideBar <> nil then
      Exit(SideBar.Side = OppositeBorders[ASide]);
    if Align in AllowedAlignments[ASide] then
      case TACLDockGroup(Parent).Layout of
        TACLDockGroupLayout.Horizontal:
          Exit(ASide in [mLeft, mRight]);
        TACLDockGroupLayout.Vertical:
          Exit(ASide in [mTop, mBottom]);
      end;
  end;

var
  AClientRect: TRect;
  AGroup: TACLDockGroup;
begin
  Result := False;
  AResizeHandler := Self;
  AClientRect := ClientRect;
  if PtInRect(AClientRect, P) then
  begin
    AClientRect.Content(GetOuterPadding);
    if not PtInRect(AClientRect, P) then
    begin
      Result := True;
      if (P.X <= AClientRect.Left) and CheckAllowResize(mLeft) then
        ASide := mLeft
      else if (P.X >= AClientRect.Right) and CheckAllowResize(mRight) then
        ASide := mRight
      else if (P.Y <= AClientRect.Top) and CheckAllowResize(mTop) then
        ASide := mTop
      else if (P.Y >= AClientRect.Bottom) and CheckAllowResize(mBottom) then
        ASide := mBottom
      else if Safe.Cast(Parent, TACLDockGroup, AGroup) then
        Result := AGroup.HitOnSizeBox(P + Point(Left, Top), AResizeHandler, ASide)
      else
        Result := False;
    end;
  end;
end;

function TACLDockControl.IsBoundsStored: Boolean;
begin
  Result := False;
end;

function TACLDockControl.IsPinnedToSideBar: Boolean;
begin
  Result := SideBar <> nil;
end;

procedure TACLDockControl.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (FDragState <> TDragState.None) and (Key = VK_ESCAPE) then
    SendCancelMode(Self);
end;

procedure TACLDockControl.LayoutLoad(ANode: TACLXMLNode);
begin
  FCustomSize.cx := dpiApply(ANode.Attributes.GetValueAsInteger(TACLDockingSchema.AttrWidth), FCurrentPPI);
  FCustomSize.cy := dpiApply(ANode.Attributes.GetValueAsInteger(TACLDockingSchema.AttrHeight), FCurrentPPI);
  Align := TAlign(GetEnumValue(TypeInfo(TAlign), ANode.Attributes.GetValue(TACLDockingSchema.AttrAlign)));
end;

procedure TACLDockControl.LayoutSave(ANode: TACLXMLNode);
begin
  ANode.Attributes.Add(TACLDockingSchema.AttrAlign, GetEnumName(TypeInfo(TAlign), Ord(Align)));
  if CustomHeight > 0 then
    ANode.Attributes.Add(TACLDockingSchema.AttrHeight, dpiRevert(CustomHeight, FCurrentPPI));
  if CustomWidth > 0 then
    ANode.Attributes.Add(TACLDockingSchema.AttrWidth, dpiRevert(CustomWidth, FCurrentPPI));
end;

procedure TACLDockControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ASite: TACLDockSite;
begin
  inherited;
  ASite := GetNearestDockControl(Self, TACLDockSite);
  if ASite <> nil then
    ASite.SideBars.MouseDown(Point(X, Y), Self);
end;

procedure TACLDockControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  AGroup: TACLDockGroup;
begin
  case FDragState of
    TDragState.Drag:
      if FDockEngine <> nil then
        FDockEngine.UpdateDragTarget(ClientToScreen(Point(X, Y)))
      else if acCanStartDragging(FDragCapture, Point(X, Y), FCurrentPPI) then
        FDockEngine := TACLDockEngine.Create(Self);

    TDragState.Resize:
      if Safe.Cast(Parent, TACLDockGroup, AGroup) then
      begin
        // Используем экранные координаты (Mouse.CursorPos) вместо локальных,
        // т.к. ресайзимый контрол может перемещаться в ходе операции
        if FSizingBorder in [TACLBorder.mLeft, TACLBorder.mRight] then
          Inc(FDragCapture.X, AGroup.ResizeChild(Self, FSizingBorder, Mouse.CursorPos.X - FDragCapture.X))
        else
          Inc(FDragCapture.Y, AGroup.ResizeChild(Self, FSizingBorder, Mouse.CursorPos.Y - FDragCapture.Y));
      end;
  end;

  inherited;
end;

procedure TACLDockControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FDragState := TDragState.None;
    if FDockEngine <> nil then
      FDockEngine.CreateLayout;
    FreeAndNil(FDockEngine);
    MouseCapture := False;
  end;
  inherited;
end;

procedure TACLDockControl.Paint;
begin
  Style.DrawContent(Canvas, ClientRect);
end;

procedure TACLDockControl.StartDrag(const P: TPoint);
begin
  MouseCapture := True;
  FDragCapture := P;
  FDragState := TDragState.Drag;
  UpdateCursor;
end;

procedure TACLDockControl.StartResize(const P: TPoint; ABorder: TACLBorder);
begin
  MouseCapture := True;
  FDragCapture := ClientToScreen(P);
  FDragState := TDragState.Resize;
  FSizingBorder := ABorder;
end;

procedure TACLDockControl.StoreCustomSize;
var
  AMinSize: Integer;
begin
  AMinSize := GetMinHeight;
  FCustomSize.cx := Max(Width, AMinSize);
  FCustomSize.cy := Max(Height, AMinSize);
end;

procedure TACLDockControl.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if FSizing or (csAligning in ControlState) then
  begin
    inherited SetBounds(ALeft, ATop, AWidth, AHeight);
    if FSizing then
      StoreCustomSize;
  end;
end;

procedure TACLDockControl.SetCustomHeight(AValue: Integer);
var
  ASite: TACLDockGroup;
begin
  if csLoading in ComponentState then
    FCustomSize.cy := AValue
  else
    if Safe.Cast(Parent, TACLDockGroup, ASite) then
    begin
      ASite.DisableAlign;
      try
        ASite.ResizeChild(Self, mBottom, AValue - CustomHeight);
      finally
        ASite.EnableAlign;
      end;
    end;
end;

procedure TACLDockControl.SetCustomWidth(AValue: Integer);
var
  ASite: TACLDockGroup;
begin
  if csLoading in ComponentState then
    FCustomSize.cx := AValue
  else
    if Safe.Cast(Parent, TACLDockGroup, ASite) then
    begin
      ASite.DisableAlign;
      try
        ASite.ResizeChild(Self, mRight, AValue - CustomWidth);
      finally
        ASite.EnableAlign;
      end;
    end;
end;

procedure TACLDockControl.SetSideBar(AValue: TACLDockSiteSideBar);
var
  APrevValue: TACLDockSiteSideBar;
begin
  if AValue <> FSideBar then
  begin
    if FSideBar <> nil then
    begin
      APrevValue := FSideBar;
      FSideBar := nil; // before unregister
      APrevValue.Unregister(Self);
    end;
    if AValue <> nil then
    try
      FSideBar := AValue;
      FSideBar.Register(Self);
    except
      FSideBar := nil;
      raise;
    end;
  end;
end;

procedure TACLDockControl.SetSize(Side: TACLBorder; AValue: Integer);
begin
  if Side in [mLeft, mRight] then
    Width := AValue
  else
    Height := AValue;
end;

procedure TACLDockControl.SetStyle(AValue: TACLStyleDocking);
begin
  Style.Assign(AValue);
end;

procedure TACLDockControl.SetTargetDPI(AValue: Integer);
begin
  inherited;
  Style.TargetDPI := AValue;
end;

procedure TACLDockControl.CMCancelMode(var Message: TWMCancelMode);
begin
  FDragState := TDragState.None;
  FreeAndNil(FDockEngine);
  inherited;
  UpdateCursor;
end;

procedure TACLDockControl.CMControlListChange(var Message: TMessage);
begin
  inherited;
  if HandleAllocated then
    PostMessage(Handle, CM_DOCKING_UPDATELIST, 0, 0);
end;

procedure TACLDockControl.CMDesignHitTest(var Message: TCMDesignHitTest);
begin
  if FDragState <> TDragState.None then
    Message.Result := 1
  else
    inherited;
end;

procedure TACLDockControl.CMVisibleChanged(var Message: TMessage);
begin
  if Parent <> nil then
    Parent.Perform(CM_DOCKING_VISIBILITY, Message.WParam, LPARAM(Self));
  inherited;
  if (csDesigning in ComponentState) and HandleAllocated then
    RedrawWindow(Parent.Handle, nil, 0, RDW_ALLCHILDREN or RDW_INVALIDATE);
end;

{ TACLDockGroup }

constructor TACLDockGroup.Create(AOwner: TComponent);
begin
  inherited;
  FActiveControlIndex := -1;
  Name := CreateUniqueName(Self, 'TACL', '');
  DoubleBuffered := False;
end;

procedure TACLDockGroup.DrawTabs(ACanvas: TCanvas);
var
  AClipRgn: HRGN;
  ARect: TRect;
  ATab: TTab;
begin
  ARect := FContentRect;
  ARect.Top := FTabsArea.Top;
  acFillRect(ACanvas, ARect, Style.ColorContent1.AsColor);

  AClipRgn := acSaveClipRegion(ACanvas.Handle);
  try
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Assign(Style.TabFontActive);
    if InRange(FTabActiveIndex, Low(FTabs), High(FTabs)) then
    begin
      ATab := FTabs[FTabActiveIndex];
      if not Style.TabArea.IsEmpty then
        acFillRect(ACanvas, ATab.Bounds, Style.ColorContent1.AsColor);
      Style.DrawBorder(ACanvas, ATab.Bounds, [mLeft, mRight, mBottom]);
      DrawTabText(ACanvas, ATab);
      acExcludeFromClipRegion(ACanvas.Handle, ATab.Bounds);
    end;

    ARect.Content(GetOuterPadding, TabAreaBorders);
    if not Style.TabArea.IsEmpty then
      acFillRect(ACanvas, ARect, Style.TabArea.Value);
    Style.DrawBorder(ACanvas, ARect, acAllBorders);

    ACanvas.Font.Assign(Style.TabFont);
    for var I := Low(FTabs) to High(FTabs) do
    begin
      if I <> FTabActiveIndex then
        DrawTabText(ACanvas, FTabs[I]);
    end;
  finally
    acRestoreClipRegion(ACanvas.Handle, AClipRgn);
  end;
end;

procedure TACLDockGroup.DrawTabText(ACanvas: TCanvas; const ATab: TTab);
begin
  acTextDraw(ACanvas, ATab.Control.ToString, 
    ATab.Bounds.Split(Style.GetTabMargins),
    taCenter, taVerticalCenter, True, True);
end;

procedure TACLDockGroup.AlignControls(AControl: TControl; var ARect: TRect);
var
  ABounds: TACLDeferPlacementUpdate;
  AChildren: TList;
begin
  ControlsAligning;
  try
    FContentRect := ARect;

    if Layout <> TACLDockGroupLayout.Tabbed then
    begin
      AChildren := TList.Create;
      try
        GetChildrenInDisplayOrder(AChildren);
        for var I := 0 to AChildren.Count - 1 do
          SetChildOrder(AChildren.List[I], I);
      finally
        AChildren.Free;
      end;
    end;

    ABounds := TACLDeferPlacementUpdate.Create;
    try
      case Layout of
        TACLDockGroupLayout.Tabbed:
          AlignTabbed(ABounds, ARect);
        TACLDockGroupLayout.Horizontal:
          AlignHorizontally(ABounds, ARect);
        TACLDockGroupLayout.Vertical:
          AlignVertically(ABounds, ARect);
      end;
      ABounds.Apply;
    finally
      ABounds.Free;
    end;

    FRestSpace := ARect;
  finally
    ControlsAligned;
  end;
end;

{$REGION ' Layouts '}
procedure TACLDockGroup.AlignHorizontally(ABounds: TACLDeferPlacementUpdate; var ARect: TRect);
var
  AChild: TACLDockControl;
  AChildNext: TACLDockControl;
  AChildPrev: TACLDockControl;
  AChildSize: Integer;
  AClientCount: Integer;
  AClientSize: Integer;
  AFixedSize: Integer;
  ALeftSize: Integer;
  AZoom: Integer;
begin
  // Measure
  AFixedSize := 0;
  AClientSize := 0;
  AClientCount := 0;
  for var I := 0 to ControlCount - 1 do
  begin
    AChild := Controls[I];
    if (csDesigning in ComponentState) or AChild.Visible then
    begin
      if AChild.Align in AlignFirst + AlignLast then
        Inc(AFixedSize, AChild.CustomWidth);
      if AChild.Align in AlignClient then
      begin
        Inc(AClientSize, AChild.CustomWidth);
        Inc(AClientCount);
      end;
    end;
  end;
  AClientSize := Max(AClientSize, 1);

  // Calculate Zoom
  AZoom := 100;
  if AFixedSize > 0 then
    AZoom := Min(AZoom, MulDiv(100, ARect.Width - AClientCount * MinChildWidth, AFixedSize));

  // Left
  AChildPrev := nil;
  for var I := 0 to ControlCount - 1 do
  begin
    AChild := Controls[I];
    if ((csDesigning in ComponentState) or AChild.Visible) and (AChild.Align in AlignFirst) then
    begin
      AChild.FNeighbours[mLeft] := AChildPrev;
      if AChildPrev <> nil then
        AChildPrev.FNeighbours[mRight] := AChild;
      AChildSize := MulDiv(AChild.CustomWidth, AZoom, 100);
      ABounds.Add(AChild, ARect.Split(srLeft, AChildSize));
      AChildPrev := AChild;
      Inc(ARect.Left, AChildSize);
    end;
  end;

  // Right
  AChildNext := nil;
  for var I := ControlCount - 1 downto 0 do
  begin
    AChild := Controls[I];
    if ((csDesigning in ComponentState) or AChild.Visible) and (AChild.Align in AlignLast) then
    begin
      AChild.FNeighbours[mRight] := AChildNext;
      if AChildNext <> nil then
        AChildNext.FNeighbours[mLeft] := AChild;
      AChildSize := MulDiv(AChild.CustomWidth, AZoom, 100);
      ABounds.Add(AChild, ARect.Split(srRight, AChildSize));
      AChildNext := AChild;
      Dec(ARect.Right, AChildSize);
    end;
  end;

  // Client
  ALeftSize := Max(ARect.Width, 0);
  for var I := 0 to ControlCount - 1 do
  begin
    AChild := Controls[I];
    if ((csDesigning in ComponentState) or AChild.Visible) and (AChild.Align in AlignClient) then
    begin
      AChild.FNeighbours[mRight] := AChildNext;
      AChild.FNeighbours[mLeft] := AChildPrev;
      if AChildPrev <> nil then
        AChildPrev.FNeighbours[mRight] := AChild;
      if AChildNext <> nil then
        AChildNext.FNeighbours[mLeft] := AChild;
      AChildSize := MulDiv(AChild.CustomWidth, ALeftSize, AClientSize);
      ABounds.Add(AChild, ARect.Split(srLeft, AChildSize));
      AChildPrev := AChild;
      Inc(ARect.Left, AChildSize);
    end;
  end;
end;

procedure TACLDockGroup.AlignTabbed(ABounds: TACLDeferPlacementUpdate; var ARect: TRect);
var
  AInvisibleRect: TRect;
  AOuterPadding: TRect;
begin
  ActiveControlIndex := Max(ActiveControlIndex, 0);

  if (ActiveControlIndex >= 0) and (VisibleControlCount > 1) { and not IsMinimized} then
  begin
    AOuterPadding := GetOuterPadding;
    FTabsArea := Rect(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom - 2{visual borders});
    FTabsArea.Content(AOuterPadding, TabAreaBorders); // from client to borders
    FTabsArea.Content(AOuterPadding, TabAreaBorders); // from borders to tabs
    FTabsArea.Top := FTabsArea.Bottom - Style.MeasureTabHeight;
    CalculateTabs(FTabsArea);
    ARect.Bottom := FTabsArea.Top;
  end
  else
    FTabsArea := NullRect;

  AInvisibleRect := ARect;
  AInvisibleRect.SetLocation(ARect.Left, -MaxShort);
  for var I := 0 to ControlCount - 1 do
  begin
    if I <> ActiveControlIndex then
      ABounds.Add(Controls[I], AInvisibleRect);
  end;

  if ActiveControlIndex >= 0 then
  begin
    ABounds.Add(ActiveControl, ARect);
    ARect := NullRect;
  end;
end;

procedure TACLDockGroup.AlignVertically(ABounds: TACLDeferPlacementUpdate; var ARect: TRect);
var
  AChild: TACLDockControl;
  AChildNext: TACLDockControl;
  AChildPrev: TACLDockControl;
  AChildSize: Integer;
  AClientCount: Integer;
  AClientSize: Integer;
  AFixedSize: Integer;
  ALeftSize: Integer;
  AZoom: Integer;
begin
  // Measure
  AFixedSize := 0;
  AClientSize := 1;
  AClientCount := 0;
  for var I := 0 to ControlCount - 1 do
  begin
    AChild := Controls[I];
    if (csDesigning in ComponentState) or AChild.Visible then
    begin
      if AChild.Align in AlignFirst + AlignLast then
        Inc(AFixedSize, AChild.CustomHeight);
      if AChild.Align in AlignClient then
      begin
        Inc(AClientSize, AChild.CustomHeight);
        Inc(AClientCount);
      end;
    end;
  end;
  AClientSize := Max(AClientSize, 1);

  // Calculate Zoom
  AZoom := 100;
  if AFixedSize > 0 then
    AZoom := Min(AZoom, MulDiv(100, ARect.Height - AClientCount * GetMinHeight, AFixedSize));

  // Top
  AChildPrev := nil;
  for var I := 0 to ControlCount - 1 do
  begin
    AChild := Controls[I];
    if ((csDesigning in ComponentState) or AChild.Visible) and (AChild.Align in AlignFirst) then
    begin
      AChild.FNeighbours[mTop] := AChildPrev;
      if AChildPrev <> nil then
        AChildPrev.FNeighbours[mBottom] := AChild;
      AChildSize := MulDiv(AChild.CustomHeight, AZoom, 100);
      ABounds.Add(AChild, ARect.Split(srTop, AChildSize));
      AChildPrev := AChild;
      Inc(ARect.Top, AChildSize);
    end;
  end;

  // Bottom
  AChildNext := nil;
  for var I := ControlCount - 1 downto 0 do
  begin
    AChild := Controls[I];
    if ((csDesigning in ComponentState) or AChild.Visible) and (AChild.Align in AlignLast) then
    begin
      AChild.FNeighbours[mBottom] := AChildNext;
      if AChildNext <> nil then
        AChildNext.FNeighbours[mTop] := AChild;
      AChildSize := MulDiv(AChild.CustomHeight, AZoom, 100);
      ABounds.Add(AChild, ARect.Split(srBottom, AChildSize));
      AChildNext := AChild;
      Dec(ARect.Bottom, AChildSize);
    end;
  end;

  // Client
  ALeftSize := Max(ARect.Height, 0);
  for var I := 0 to ControlCount - 1 do
  begin
    AChild := Controls[I];
    if ((csDesigning in ComponentState) or AChild.Visible) and (AChild.Align in AlignClient) then
    begin
      AChild.FNeighbours[mBottom] := AChildNext;
      AChild.FNeighbours[mTop] := AChildPrev;
      if AChildPrev <> nil then
        AChildPrev.FNeighbours[mBottom] := AChild;
      if AChildNext <> nil then
        AChildNext.FNeighbours[mTop] := AChild;
      AChildSize := MulDiv(AChild.CustomHeight, ALeftSize, AClientSize);
      ABounds.Add(AChild, ARect.Split(srTop, AChildSize));
      AChildPrev := AChild;
      Inc(ARect.Top, AChildSize);
    end;
  end;
end;

procedure TACLDockGroup.CalculateTabs(ARect: TRect);

  function GetTabPlaceIndents(AActive: Boolean): TRect;
  begin
    if AActive then    
    begin
      Result := Rect(
        -dpiApply(TACLStyleDocking.TabIndent, FCurrentPPI) - 1, -2,
        -dpiApply(TACLStyleDocking.TabIndent, FCurrentPPI) - 1, 0);
    end
    else
      Result := Rect(0, 0, 0, dpiApply(TACLStyleDocking.TabControlOffset, FCurrentPPI));
  end;

var
  ACalculator: TACLAutoSizeCalculator;
  AChild: TACLDockControl;
  ATab: TTab;
  ATabIndent: Integer;
  ATabIndex: Integer;
  ATabWidth: Integer;
begin
  ATabIndent := dpiApply(TACLStyleDocking.TabIndent, FCurrentPPI);
  
  ACalculator := TACLAutoSizeCalculator.Create;
  try
    ACalculator.Capacity := ControlCount;
    ACalculator.AvailableSize := ARect.Width - 2 * (ATabIndent + 1);
    for var I := 0 to ControlCount - 1 do
    begin
      AChild := Controls[I];
      if (csDesigning in ComponentState) or AChild.Visible then
      begin
        ATabWidth := Style.MeasureTabWidth(AChild.ToString) + ATabIndent;
        ACalculator.Add(ATabWidth, 4, ATabWidth, True);
      end
    end;
    ACalculator.Calculate;

    ATabIndex := 0;
    FTabActiveIndex := -1;
    Inc(ARect.Left, ATabIndent + 1);
    SetLength(FTabs, ACalculator.Count);
    for var I := 0 to ControlCount - 1 do
    begin
      AChild := Controls[I];
      if (csDesigning in ComponentState) or AChild.Visible then
      begin
        ATab.Control := AChild;
        ATab.Bounds := ARect.Split(srLeft, ACalculator[ATabIndex].Size);
        ARect.Left := ATab.Bounds.Right;
        if ATabIndex + 1 < ACalculator.Count then
          Dec(ATab.Bounds.Right, ATabIndent);
        ATab.Bounds.Content(GetTabPlaceIndents(I = ActiveControlIndex));
        if I = ActiveControlIndex then
          FTabActiveIndex := ATabIndex;
        FTabs[ATabIndex] := ATab;
        Inc(ATabIndex);
      end;
    end;
  finally
    ACalculator.Free;
  end;
  InvalidateRect(FTabsArea);
end;

procedure TACLDockGroup.ControlsAligned;
begin
  inherited;
  for var I := 0 to ControlCount - 1 do
    Controls[I].Aligned;
end;

procedure TACLDockGroup.ControlsAligning;
begin
  inherited;
  for var I := 0 to ControlCount - 1 do
    Controls[I].Aligning;
end;

procedure TACLDockGroup.CMCancelMode(var Message: TWMCancelMode);
begin
  ZeroMemory(@FTabCapture, SizeOf(FTabCapture));
  inherited;
end;

procedure TACLDockGroup.CMControlListChange(var Message: TMessage);
begin
  inherited;
  if Message.LParam = 0 then
    Perform(CM_DOCKING_VISIBILITY, 0, Message.WParam);
  if HandleAllocated then
    PostMessage(Handle, CM_DOCKING_UPDATETEXT, 0, 0);
end;

procedure TACLDockGroup.CMDesignHitTest(var Message: TCMDesignHitTest);
begin
  if PtInRect(FTabsArea, Message.Pos) then
    Message.Result := 1
  else
    inherited;
end;

procedure TACLDockGroup.CMDockingPack(var Message: TMessage);
var
  AChild: TACLDockControl;
begin
  if SideBar <> nil then
    Exit;
  if Parent is TACLDockGroup then
  begin
    if FReferences > 0 then
      Exit;

    if ControlCount = 1 then
    begin
      AChild := Controls[0];
      AChild.Align := Align;
      AChild.Parent := Parent;
      TACLDockGroup(Parent).SetChildOrder(AChild, IndexOfControl(Self));
    end;

    if ControlCount > 0 then
    begin
      if Message.WParam = 0 then
        Parent.Perform(CM_DOCKING_PACK, 0, 0);
    end
    else
      Free;
  end
  else
    if ControlCount = 1 then
    begin
      DisableAlign;
      try
        AChild := Controls[0];
        if Layout = TACLDockGroupLayout.Tabbed then
          Layout := TACLDockGroupLayout.Horizontal;
        if AChild is TACLDockGroup then
        try
          AChild.DisableAlign;
          while AChild.ControlCount > 0 do
            AChild.Controls[0].Parent := Self;
          // keep the order
          Layout := TACLDockGroup(AChild).Layout;
          ActiveControlIndex := TACLDockGroup(AChild).ActiveControlIndex;
        finally
          AChild.Free;
        end;
      finally
        EnableAlign;
      end;
    end;
end;

procedure TACLDockGroup.CMDockingUpdateList(var Message: TMessage);
begin
  inherited;
  SetActiveControlIndex(ActiveControlIndex);
end;

procedure TACLDockGroup.CMDockingUpdateText(var Message: TMessage);
begin
  inherited;
  if Layout = TACLDockGroupLayout.Tabbed then
    Realign;
  if Parent <> nil then
    Parent.Perform(CM_DOCKING_UPDATETEXT, 0, LPARAM(Self));
end;

procedure TACLDockGroup.CMDockingVisibility(var Message: TMessage);
begin
  if (Message.WParam = 0) and (Message.LParam = LPARAM(ActiveControl)) then
  begin
    if Layout <> TACLDockGroupLayout.Tabbed then
      ActiveControlIndex := -1;
  end;
  Visible := VisibleControlCount > 0;
end;

function TACLDockGroup.GetActiveControl: TACLDockControl;
begin
  if InRange(ActiveControlIndex, 0, ControlCount - 1) then
    Result := Controls[ActiveControlIndex]
  else
    Result := nil;
end;

procedure TACLDockGroup.GetChildrenInDisplayOrder(AList: TList);

  procedure Enum(AAllowAligns: TAlignSet);
  var
    AChild: TACLDockControl;
  begin
    if (AAllowAligns = []) or (AList.Count = ControlCount) then
      Exit;
    for var I := 0 to ControlCount - 1 do
    begin
      AChild := Controls[I];
      if AChild.Align in AAllowAligns then
        AList.Add(AChild);
    end;
  end;

begin
  AList.EnsureCapacity(ControlCount);
  Enum(AlignFirst);
  Enum(AlignClient);
  Enum(AlignLast);
  Enum([Low(TAlign)..High(TAlign)] - AlignLast - AlignClient - AlignFirst); // all other
end;
{$ENDREGION}

function TACLDockGroup.GetControl(Index: Integer): TACLDockControl;
begin
  Result := inherited Controls[Index] as TACLDockControl;
end;

function TACLDockGroup.GetCursor(const P: TPoint): TCursor;
var
  ATab: TTab;
begin
  if (Layout = TACLDockGroupLayout.Tabbed) and (DragState = TDragState.None) then
  begin
    if FTabCapture.Control <> nil then
      Exit(crDefault); //crDrag
    if GetTabAtPos(P, ATab) and (ActiveControl <> ATab.Control) then
      Exit(crHandPoint);
  end;
  Result := inherited;
end;

function TACLDockGroup.GetTabAtPos(const P: TPoint; out ATab: TTab): Boolean;
begin
  if PtInRect(FTabsArea, P) then
    for var I := Low(FTabs) to High(FTabs) do
    begin
      if PtInRect(FTabs[I].Bounds, P) then
      begin
        ATab := FTabs[I];
        Exit(True);
      end;
    end;
  Result := False;
end;

procedure TACLDockGroup.GetTabOrderList(List: TList);
begin
  GetChildrenInDisplayOrder(List);
end;

function TACLDockGroup.GetVisibleControlCount: Integer;
var
  LControl: TACLDockControl;
begin
  Result := 0;
  for var I := 0 to ControlCount - 1 do
  begin
    LControl := Controls[I];
    if LControl.Visible and (LControl.Align <> alCustom) then
      Inc(Result);
  end;
end;

function TACLDockGroup.HasTabs: Boolean;
begin
  Result := (Layout = TACLDockGroupLayout.Tabbed) and not FTabsArea.IsEmpty;
end;

procedure TACLDockGroup.LayoutLoad(ANode: TACLXMLNode);
var
  LChild: TACLXMLNode;
  LGroup: TACLDockGroup;
  LName: string;
  LPanel: TACLDockPanel;
begin
  DisableAlign;
  try
    inherited LayoutLoad(ANode);

    Layout := TACLDockGroupLayout(GetEnumValue(TypeInfo(TACLDockGroupLayout),
      ANode.Attributes.GetValue(TACLDockingSchema.AttrLayout)));

    for var I := 0 to ANode.Count - 1 do
    begin
      LChild := ANode[I];
      if LChild.Attributes.GetValue(TACLDockingSchema.AttrName, LName) then
      begin
        if Safe.Cast(Owner.FindComponent(LName), TACLDockPanel, LPanel) then
        begin
          LPanel.Parent := Self;
          LPanel.LayoutLoad(LChild);
          SetChildOrder(LPanel, I);
        end;
      end
      else
      begin
        LGroup := TACLDockGroup.Create(Owner);
        try
          LGroup.Name := LChild.Attributes.GetValueDef(TACLDockingSchema.AttrIdent, LGroup.Name);
        except end;
        LGroup.Parent := Self;
        LGroup.Style := Style;
        LGroup.LayoutLoad(LChild);
        SetChildOrder(LGroup, I);
      end;
    end;

    ActiveControlIndex := ANode.Attributes.GetValueAsInteger(TACLDockingSchema.AttrIndex, -1);
    Perform(CM_DOCKING_VISIBILITY, 0, 0);
  finally
    EnableAlign;
  end;
end;

procedure TACLDockGroup.LayoutSave(ANode: TACLXMLNode);
begin
  ANode.Attributes.Add(TACLDockingSchema.AttrLayout,
    GetEnumName(TypeInfo(TACLDockGroupLayout), Ord(Layout)));
  inherited;
  ANode.Attributes.Add(TACLDockingSchema.AttrIdent, Name);
  if ActiveControlIndex >= 0 then
    ANode.Attributes.Add(TACLDockingSchema.AttrIndex, ActiveControlIndex);
  for var I := 0 to ControlCount - 1 do
    Controls[I].LayoutSave(ANode.Add(TACLDockingSchema.NodeItem));
end;

procedure TACLDockGroup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ATab: TTab;
begin
  inherited;
  if Layout = TACLDockGroupLayout.Tabbed then
  begin
    if GetTabAtPos(Point(X, Y), ATab)  then
    begin
      ActiveControlIndex := IndexOfControl(ATab.Control);
      FTabCapture := ATab;
      UpdateCursor;
    end;
  end
end;

procedure TACLDockGroup.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LIndexSource: Integer;
  LIndexTarget: Integer;
  LTab: TTab;
begin
  if (ssLeft in Shift) and (FTabCapture.Control <> nil) then
  begin
    if GetTabAtPos(Point(X, Y), LTab) and (LTab.Control <> FTabCapture.Control) then
    begin
      LIndexTarget := IndexOfControl(LTab.Control);
      LIndexSource := IndexOfControl(FTabCapture.Control);
      if (LIndexSource < LIndexTarget) and (X >= LTab.Bounds.CenterPoint.X) or
         (LIndexSource > LIndexTarget) and (X <= LTab.Bounds.CenterPoint.X) then
      begin
        SetChildOrder(FTabCapture.Control, LIndexTarget);
        Realign;
        // актуализируем после реордеринга
        ActiveControlIndex := IndexOfControl(FTabCapture.Control);
      end;
    end;
  end
  else
    inherited;
end;

procedure TACLDockGroup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ZeroMemory(@FTabCapture, SizeOf(FTabCapture));
  inherited;
end;

procedure TACLDockGroup.Paint;
begin
  if not FRestSpace.IsEmpty then
    Style.DrawContent(Canvas, FRestSpace);
  if Layout = TACLDockGroupLayout.Tabbed then
  begin
    if not FTabsArea.IsEmpty then
      DrawTabs(Canvas);
  end;
end;

function TACLDockGroup.ToString: string;
var
  B: TACLStringBuilder;
begin
  B := TACLStringBuilder.Get;
  try
    for var I := 0 to ControlCount - 1 do
      if Controls[I].Visible then
      begin        
        if B.Length > 0 then
          B.Append(' / ');
        B.Append(Controls[I].ToString);        
      end;
    Result := B.ToString;
  finally
    B.Release;
  end;
end;

procedure TACLDockGroup.ValidateInsert(AComponent: TComponent);
begin
  if not (AComponent is TACLDockControl) and
     not (AComponent is TACLDockZone) and
     not (AComponent is TACLDockSiteSideBar)
  then
    raise EInvalidInsert.Create('Only DockPanel and DockGroup are allowed here');

  inherited;
end;

procedure TACLDockGroup.SetActiveControlIndex(AValue: Integer);
begin
  AValue := EnsureRange(AValue, -1, ControlCount - 1);

  if not (csDesigning in ComponentState) then
  begin
    if (AValue >= 0) and (AValue < ControlCount) and not Controls[AValue].Visible then
    begin
      while (AValue < ControlCount) and not Controls[AValue].Visible do
        Inc(AValue);
      if AValue >= ControlCount then
        AValue := ControlCount - 1;
      while (AValue >= 0) and not Controls[AValue].Visible do
        Dec(AValue);
    end;
  end;

  if FActiveControlIndex <> AValue then
  begin
    FActiveControlIndex := AValue;
    Realign;
    Changed;
  end;
end;

function TACLDockGroup.ResizeChild(AChild: TACLDockControl; ASide: TACLBorder; ADelta: Integer): Integer;

  procedure SetChildSize(AControl: TACLDockControl; ADelta: Integer);
  begin
    AControl.FSizing := True;
    AControl.Size[ASide] := AControl.Size[ASide] + ADelta;
    AControl.FSizing := False;
    AControl.Aligned;
    AControl.Update;
  end;

const
  SignMods: array[TACLBorder] of Integer = (-1, -1, 1, 1);
var
  AMinuend: TACLDockControl;
begin
  Result := 0;
  if (ActiveControlIndex < 0) and (ADelta <> 0) then
  begin
    DisableAlign;
    try
      if AChild.FNeighbours[ASide] <> nil then
      begin
        if SignMods[ASide] * ADelta > 0 then
          AMinuend := AChild.FNeighbours[ASide]
        else
          AMinuend := AChild;
        
        Result := Sign(ADelta) * Min(Abs(ADelta), Max(0, AMinuend.Size[ASide] - 3 * AMinuend.GetMinHeight));
        SetChildSize(AChild, SignMods[ASide] * Result);
        SetChildSize(AChild.FNeighbours[ASide], -SignMods[ASide] * Result);
      end
      else
      begin
        ADelta := SignMods[ASide] * ADelta;
        ADelta := MaxMin(AChild.Size[ASide] + ADelta, 3 * AChild.GetMinHeight, Size[ASide]) - AChild.Size[ASide];
        Result := SignMods[ASide] * ADelta;
        SetChildSize(AChild, ADelta);
      end;
    
      for var I := 0 to ControlCount - 1 do
        Controls[I].StoreCustomSize;
    finally
      EnableAlign;
    end;
  end;
end;

procedure TACLDockGroup.SetLayout(AValue: TACLDockGroupLayout);
begin
  if FLayout <> AValue then
  begin
    FActiveControlIndex := -1;
    FLayout := AValue;
    SetLength(FTabs, 0);
    Realign;
  end;
end;

{ TACLDockPanel }

constructor TACLDockPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csSetCaption, csCaptureMouse];
  FCaptionButtonActiveIndex := -1;
  FCaptionButtonPressedIndex := -1;
  FShowCaption := True;
  FocusOnClick := True;
end;

procedure TACLDockPanel.Aligned;
var
  APrevCaptionBottom: Integer;
begin
  inherited;
  APrevCaptionBottom := FCaptionRect.Bottom;

  if HasBorders and ShowCaption then
  begin
    FCaptionRect := ClientRect;
    FCaptionRect.Content(GetOuterPadding);
    FCaptionRect.Height := Style.MeasureHeaderHeight;
    FCaptionTextRect := FCaptionRect;
    CalculateCaptionButtons;
  end
  else
    FCaptionRect := NullRect;

  if FCaptionRect.Bottom <> APrevCaptionBottom then
    Realign;
end;

//function TACLDockPanel.AllowMaximize: Boolean;
//var
//  ASite: TACLDockGroup;
//begin
//  Result := (SideBar = nil) and
//    (Safe.Cast(Parent, TACLDockGroup, ASite)) and
//    (ASite.Layout <> TACLDockGroupLayout.Tabbed) and
//    (ASite.VisibleControlCount > 1) or IsMinimized;
//end;

function TACLDockPanel.AllowPin: Boolean;
var
  ADockSite: TACLDockSite;
begin
  if SideBar <> nil then
    Exit(True);

  ADockSite := GetNearestDockControl(Self, TACLDockSite);
  if ADockSite = nil then
    Exit(False);

{$IFDEF ACL_DOCKING_PIN_TABBED_GROUP}
  Result := (ADockSite <> Parent) or (ADockSite.Layout <> TACLDockGroupLayout.Tabbed);
{$ELSE}
  Result := True;
{$ENDIF}
end;

procedure TACLDockPanel.CalculateCaptionButtons;
var
  ARect: TRect;
begin
  ARect := FCaptionRect;
  ARect.Inflate(-dpiApply(3, FCurrentPPI));
  FCaptionButtons[TCaptionButton.Close] := ARect.Split(srRight, ARect.Height);
  Dec(ARect.Right, ARect.Height + dpiApply(acTextIndent, FCurrentPPI));

//  if AllowMaximize then
//  begin
//    FCaptionButtons[TCaptionButton.Maximize] := ARect.Split(srRight, ARect.Height);
//    Dec(ARect.Right, ARect.Height + dpiApply(acTextIndent, FCurrentPPI));
//  end
//  else
    FCaptionButtons[TCaptionButton.Maximize] := NullRect;

  if AllowPin then
  begin
    FCaptionButtons[TCaptionButton.Pin] := ARect.Split(srRight, ARect.Height);
    Dec(ARect.Right, ARect.Height + dpiApply(acTextIndent, FCurrentPPI));
  end
  else
    FCaptionButtons[TCaptionButton.Pin] := NullRect;

  FCaptionTextRect.Right := ARect.Right;
  if Style.HeaderTextAlignment = taCenter then
    FCaptionTextRect.Left := FCaptionRect.Left + (FCaptionRect.Right - ARect.Right)
  else
    FCaptionTextRect.Left := ARect.Left;
end;

function TACLDockPanel.CanStartDrag: Boolean;
begin
  Result := not IsPinnedToSideBar;
end;

procedure TACLDockPanel.CaptionButtonClick(AButton: TCaptionButton);
var
  ACtrl: TACLDockControl;
  ADockGroup: TACLDockGroup;
  AMainSite: TACLDockSite;
begin
  ADockGroup := Parent as TACLDockGroup;
  case AButton of
    TCaptionButton.Close:
      Visible := False;

//    TCaptionButton.Maximize:
//      begin
//        AOffset := Mouse.CursorPos - ClientToScreen(FCaptionButtons[AButton].TopLeft);
//        ACtrlIndex := IndexOfControl(Self);
//        if ADockGroup.ActiveControlIndex <> ACtrlIndex then
//          ADockGroup.ActiveControlIndex := ACtrlIndex
//        else
//          ADockGroup.ActiveControlIndex := -1;
//        Mouse.CursorPos := ClientToScreen(FCaptionButtons[AButton].TopLeft) + AOffset;
//      end;

    TCaptionButton.Pin:
      begin
        ACtrl := Self;
      {$IFDEF ACL_DOCKING_PIN_TABBED_GROUP}
        if ADockGroup.Layout = TACLDockGroupLayout.Tabbed then
          ACtrl := ADockGroup;
      {$ENDIF}
        if ACtrl.SideBar = nil then
        begin
          AMainSite := GetNearestDockControl(Self, TACLDockSite);
          if AMainSite <> nil then
          begin
            ACtrl.StoreCustomSize;
            ACtrl.SideBar := AMainSite.SideBars.OptimalFor(Self);
          end;
        end
        else
          ACtrl.SideBar := nil;
      end;
  end;
end;

procedure TACLDockPanel.CMDesignHitTest(var Message: TCMDesignHitTest);
begin
  if PtInRect(FCaptionRect, Message.Pos) then
    Message.Result := 1
  else
    inherited;
end;

function TACLDockPanel.CreatePadding: TACLPadding;
begin
  Result := TACLPadding.Create(0);
end;

function TACLDockPanel.GetCaptionButtonState(AButton: TCaptionButton): Integer;
begin
  Result := 0;
  if Ord(AButton) = FCaptionButtonActiveIndex then
    Inc(Result, 1 + Ord(Ord(AButton) = FCaptionButtonPressedIndex));
  if (AButton = TCaptionButton.Pin) and IsPinnedToSideBar then
    Inc(Result, 3);
end;

function TACLDockPanel.GetContentOffset: TRect;
begin
  if HasBorders then
  begin
    Result := GetOuterPadding;
    Result.MarginsAdd(2{visual borders});
    if ShowCaption then
      Result.Top := FCaptionRect.Bottom + 1;
  end
  else
    Result := NullRect;
end;

function TACLDockPanel.GetCursor(const P: TPoint): TCursor;
begin
  if DragState = TDragState.None then
  begin
    if HitOnCaptionButton(P) >= 0 then
      Exit(crHandPoint);
  end;
  Result := inherited;
end;

function TACLDockPanel.GetOuterPadding: TRect;
var
  AGroup: TACLDockGroup;
begin
  Result := inherited;
  if (SideBar = nil) and Safe.Cast(Parent, TACLDockGroup, AGroup) then
  begin
    if AGroup.HasTabs then
      Result.Bottom := -2; // hide outer visual border
  end;
end;

function TACLDockPanel.HasBorders: Boolean;
var
  ADockGroup: TACLDockGroup;
begin
  if Safe.Cast(Parent, TACLDockGroup, ADockGroup) then
  begin
    Result := not (
      (not ADockGroup.HasTabs) and
      (ADockGroup.Parent is TACLFloatDockForm) and
      (ADockGroup.VisibleControlCount = 1));
  end
  else
    Result := True;
end;

function TACLDockPanel.HitOnCaptionButton(const P: TPoint): Integer;
begin
  for var I := Low(FCaptionButtons) to High(FCaptionButtons) do
  begin
    if PtInRect(FCaptionButtons[I], P) then
      Exit(Ord(I));
  end;
  Result := -1;
end;

{$IFDEF ACL_DOCKING_PIN_TABBED_GROUP}
function TACLDockPanel.IsPinnedToSideBar: Boolean;
var
  AGroup: TACLDockGroup;
begin
  Result := inherited or Safe.Cast(Parent, TACLDockGroup, AGroup) and
    (AGroup.Layout = TACLDockGroupLayout.Tabbed) and (AGroup.SideBar <> nil);
end;
{$ENDIF}

procedure TACLDockPanel.LayoutLoad(ANode: TACLXMLNode);
begin
  inherited;
  Visible := ANode.Attributes.GetValueAsBoolean(TACLDockingSchema.AttrVisible, True);
end;

procedure TACLDockPanel.LayoutSave(ANode: TACLXMLNode);
begin
  if Name = '' then
    raise EInvalidOperation.Create(ClassName + '.Name must be set!');
  ANode.Attributes.Add(TACLDockingSchema.AttrName, Name);
  inherited;
  if not Visible then
    ANode.Attributes.SetValueAsBoolean(TACLDockingSchema.AttrVisible, False);
end;

procedure TACLDockPanel.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  AHandler: TACLDockControl;
  APoint: TPoint;
  ASide: TACLBorder;
begin
  APoint := Point(X, Y);
  SetCaptionButtonActiveIndex(HitOnCaptionButton(APoint));

  if Button = mbLeft then
  begin
    if FCaptionButtonActiveIndex >= 0 then
      SetCaptionButtonPressedIndex(FCaptionButtonActiveIndex)
    else if PtInRect(FCaptionRect, APoint) and CanStartDrag then
      StartDrag(APoint)
    else if HitOnSizeBox(APoint, AHandler, ASide) then
      AHandler.StartResize(acMapPoint(Handle, AHandler.Handle, APoint), ASide);
  end;

  inherited;
end;

procedure TACLDockPanel.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if DragState = TDragState.None then
    SetCaptionButtonActiveIndex(HitOnCaptionButton(Point(X, Y)));
  inherited;
end;

procedure TACLDockPanel.MouseLeave;
begin
  SetCaptionButtonActiveIndex(-1);
  inherited;
end;

procedure TACLDockPanel.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  AHitButtonIndex: Integer;
begin
  if Button = mbLeft then
  begin
    AHitButtonIndex := HitOnCaptionButton(Point(X, Y));
    if (FCaptionButtonPressedIndex = AHitButtonIndex) and (FCaptionButtonPressedIndex >= 0) then
      CaptionButtonClick(TCaptionButton(FCaptionButtonPressedIndex));
    SetCaptionButtonActiveIndex(AHitButtonIndex);
    SetCaptionButtonPressedIndex(-1);
  end;
  inherited;
end;

procedure TACLDockPanel.Paint;
var
  AClipRgn: HRGN;
begin
  if HasBorders then
  begin
    Style.DrawBorder(Canvas, ClientRect.Split(GetOuterPadding), acAllBorders);
    Style.DrawHeader(Canvas, FCaptionRect);
    Style.DrawHeaderText(Canvas, FCaptionTextRect, Caption);
    AClipRgn := acSaveClipRegion(Canvas.Handle);
    try
      acIntersectClipRegion(Canvas.Handle, FCaptionRect);
      for var I := Low(FCaptionButtons) to High(FCaptionButtons) do
      begin
        Style.HeaderButton.Draw(Canvas, FCaptionButtons[I], GetCaptionButtonState(I));
        Style.HeaderButtonGlyphs.Draw(Canvas, FCaptionButtons[I].InflateTo(-4), Ord(I));
      end;
    finally
      acRestoreClipRegion(Canvas.Handle, AClipRgn);
    end;
  end;
  if (csDesigning in ComponentState) and not Visible then
    acFillRect(Canvas, ClientRect.Split(GetOuterPadding), TAlphaColor.FromColor(clBlack, 30));
end;

procedure TACLDockPanel.SetParent(AParent: TWinControl);
begin
  if (AParent <> nil) and not (AParent is TACLDockGroup) then
    raise EInvalidInsert.Create('DockPanel can be hosted on DockGroup only');
  inherited;
end;

procedure TACLDockPanel.SetShowCaption(AValue: Boolean);
begin
  if FShowCaption <> AValue then
  begin
    Aligning;
    try
      FShowCaption := AValue;
    finally
      Aligned;
    end;
    Invalidate;
  end;
end;

function TACLDockPanel.ToString: string;
begin
  Result := Caption;
end;

procedure TACLDockPanel.SetCaptionButtonActiveIndex(AValue: Integer);
begin
  if AValue <> FCaptionButtonActiveIndex then
  begin
    FCaptionButtonActiveIndex := AValue;
    InvalidateRect(FCaptionRect);
  end;
end;

procedure TACLDockPanel.SetCaptionButtonPressedIndex(AValue: Integer);
begin
  if AValue <> FCaptionButtonPressedIndex then
  begin
    FCaptionButtonPressedIndex := AValue;
    InvalidateRect(FCaptionRect);
  end;
end;

procedure TACLDockPanel.ValidateInsert(AComponent: TComponent);
begin
  if AComponent is TACLDockControl then
    raise EInvalidInsert.Create('DockControls are not allowed here');
  inherited;
end;

procedure TACLDockPanel.CMTextChanged(var Message: TMessage);
begin
  inherited;
  if Parent <> nil then
    Parent.Perform(CM_DOCKING_UPDATETEXT, 0, LPARAM(Self));
  Invalidate;
end;

{$ENDREGION}

{$REGION ' FloatDockForm '}

{ TACLFloatDockForm }

constructor TACLFloatDockForm.Create(AOwner: TACLDockSite);
begin
  CreateDialog(GetParentForm(AOwner).Handle, True);
  BorderStyle := bsSizeToolWin;
  DefaultMonitor := dmDesktop;
  Position := poDesigned;
  FMainSite := AOwner;
  FMainSite.FloatForms.Add(Self);
  FDockGroup := TACLDockGroup.Create(AOwner.Owner);
  FDockGroup.Align := alClient;
  FDockGroup.Parent := Self;
end;

destructor TACLFloatDockForm.Destroy;
begin
  if MainSite.FloatForms <> nil then
    MainSite.FloatForms.Extract(Self);
  inherited;
end;

procedure TACLFloatDockForm.CreateHandle;
begin
  inherited;
  Perform(CM_DOCKING_UPDATETEXT, 0, 0);
end;

procedure TACLFloatDockForm.DoClose(var Action: TCloseAction);
begin
  for var I := 0 to DockGroup.ControlCount - 1 do
    DockGroup.Controls[I].Visible := False;
  Action := TCloseAction.caNone;
end;

function TACLFloatDockForm.GetNonClientExtends: TRect;
var
  AWindowInfo: TWindowInfo;
begin
  AWindowInfo.cbSize := SizeOf(AWindowInfo);
  if HandleAllocated and GetWindowInfo(Handle, AWindowInfo) then
    Result := TRect.CreateMargins(AWindowInfo.rcWindow, AWindowInfo.rcClient)
  else
    Result := NullRect;
end;

procedure TACLFloatDockForm.LayoutLoad(ANode: TACLXMLNode);
var
  ABounds: TRect;
begin
  ABounds := ANode.Attributes.GetValueAsRect(TACLDockingSchema.AttrPosition);
  ScaleForPPI(acGetTargetDPI(ABounds.CenterPoint));
  BoundsRect := dpiApply(ABounds, FCurrentPPI);
  DockGroup.LayoutLoad(ANode);
  DockGroup.Align := alClient;
  DockGroup.Visible := True;
  Visible := ANode.Attributes.GetValueAsBoolean(TACLDockingSchema.AttrVisible);
end;

procedure TACLFloatDockForm.LayoutSave(ANode: TACLXMLNode);
begin
  DockGroup.LayoutSave(ANode);
  ANode.Attributes.SetValueAsRect(TACLDockingSchema.AttrPosition, dpiRevert(BoundsRect, FCurrentPPI));
  ANode.Attributes.SetValueAsBoolean(TACLDockingSchema.AttrVisible, Visible);
end;

procedure TACLFloatDockForm.CMControlListChange(var Message: TMessage);
begin
  inherited;
  if HandleAllocated then
  begin
    PostMessage(Handle, CM_DOCKING_UPDATETEXT, 0, 0);
    PostMessage(Handle, CM_DOCKING_PACK, 0, 0);
  end;
end;

procedure TACLFloatDockForm.CMDockingPack(var Message: TMessage);
begin
  if (DockGroup.Parent <> Self) or (DockGroup.ControlCount = 0) then
    Release;
end;

procedure TACLFloatDockForm.CMDockingUpdateText(var Message: TMessage);
begin
  inherited;
  Caption := DockGroup.ToString;
end;

procedure TACLFloatDockForm.CMDockingVisibility(var Message: TMessage);
begin
  Visible := DockGroup.Visible;
end;

procedure TACLFloatDockForm.WMEnterSizeMove(var Message: TMessage);
begin
  inherited;
  DockGroup.FSizing := True;
end;

procedure TACLFloatDockForm.WMExitSizeMove(var Message: TMessage);
begin
  inherited;
  DockGroup.FSizing := False;
end;

procedure TACLFloatDockForm.WMNCLButtonDown(var Message: TWMNCLButtonDown);
begin
  if (Message.HitTest = HTCAPTION) and not IsIconic(Handle) then
  begin
    SendMessage(DockGroup.Handle, WM_MOUSEACTIVATE, 0, 0);
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOZORDER or SWP_NOMOVE or SWP_NOSIZE);
    SendMessage(Handle, WM_NCLBUTTONUP, TMessage(Message).WParam, TMessage(Message).LParam);
    DockGroup.StartDrag(DockGroup.ScreenToClient(Point(Message.XCursor, Message.YCursor)));
  end
  else
    inherited;
end;

{$ENDREGION}

{$REGION ' SideBars '}

{ TACLDockSiteSideBarTab }

constructor TACLDockSiteSideBarTab.Create(AControl: TACLDockControl);
begin
  inherited Create(nil);
  FControl := AControl;
  FPrevAlign := AControl.Align;
  FPrevIndex := IndexOfControl(AControl);
  SetPrevParent(AControl.Parent as TACLDockGroup);
end;

destructor TACLDockSiteSideBarTab.Destroy;
begin
  SetPrevParent(nil);
  inherited;
end;

procedure TACLDockSiteSideBarTab.LayoutLoad(ANode: TACLXMLNode; AOwner: TComponent);
var
  LGroup: TComponent;
begin
  FPrevAlign := TAlign(GetEnumValue(TypeInfo(TAlign), ANode.Attributes.GetValue(TACLDockingSchema.AttrAlign)));
  FPrevIndex := ANode.Attributes.GetValueAsInteger(TACLDockingSchema.AttrIndex);

  if AOwner <> nil then
    LGroup := AOwner.FindComponent(ANode.Attributes.GetValue(TACLDockingSchema.AttrIdent))
  else
    LGroup := nil;

  if LGroup is TACLDockGroup then
    SetPrevParent(TACLDockGroup(LGroup))
  else
    SetPrevParent(nil);
end;

procedure TACLDockSiteSideBarTab.LayoutSave(ANode: TACLXMLNode);
begin
  if (FPrevParent <> nil) and (FPrevParent.Name <> '') then
    ANode.Attributes.Add(TACLDockingSchema.AttrIdent, FPrevParent.Name);
  ANode.Attributes.Add(TACLDockingSchema.AttrIndex, FPrevIndex);
  ANode.Attributes.Add(TACLDockingSchema.AttrAlign, GetEnumName(TypeInfo(TAlign), Ord(FPrevAlign)));
end;

procedure TACLDockSiteSideBarTab.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;
  if (AOperation = opRemove) and (AComponent = FPrevParent) then
    SetPrevParent(nil);
end;

procedure TACLDockSiteSideBarTab.SetPrevParent(AValue: TACLDockGroup);
begin
  if AValue <> FPrevParent then
  begin
    if FPrevParent <> nil then
    begin
      Dec(FPrevParent.FReferences);
      FPrevParent.RemoveFreeNotification(Self);
      FPrevParent := nil;
    end;
    if AValue <> nil then
    begin
      FPrevParent := AValue;
      FPrevParent.FreeNotification(Self);
      Inc(FPrevParent.FReferences);
    end;
  end;
end;

{ TACLDockSiteSideBar }

constructor TACLDockSiteSideBar.Create(AOwner: TACLDockSiteSideBars; ASide: TACLBorder);
begin
  inherited Create(nil);
  FOwner := AOwner;
  FSide := ASide;
  FTabs := TACLObjectList<TACLDockSiteSideBarTab>.Create;
  FStyle := AOwner.Site.Style;
end;

destructor TACLDockSiteSideBar.Destroy;
begin
  FreeAndNil(FTabs);
  inherited;
end;

procedure TACLDockSiteSideBar.Calculate;
var
  ACalc: TACLAutoSizeCalculator;
  ARect: TRect;
  ASize: Integer;
begin
  ACalc := TACLAutoSizeCalculator.Create;
  try
    for var I := 0 to FTabs.Count - 1 do
    begin
      ASize := Style.MeasureSideBarTabWidth(FTabs.List[I].Control.ToString);
      ACalc.Add(ASize, 4, ASize, True);
    end;
    ARect := Bounds;
    if Side in [mTop, mBottom] then
    begin
      ARect.Inflate(-Bounds.Height, 0);
      ACalc.AvailableSize := ARect.Width;
      ACalc.Calculate;
      for var I := 0 to FTabs.Count - 1 do
      begin
        ARect.Width := ACalc[I].Size;
        FTabs.List[I].Bounds := ARect;
        ARect.Left := ARect.Right - 1; // 1 - merge borders
      end;
    end
    else
    begin
      ARect.Inflate(0, -Bounds.Width);
      ACalc.AvailableSize := ARect.Height;
      ACalc.Calculate;
      for var I := 0 to FTabs.Count - 1 do
      begin
        ARect.Height := ACalc[I].Size;
        FTabs.List[I].Bounds := ARect;
        ARect.Top := ARect.Bottom - 1; // 1 - merge borders
      end;
    end;
  finally
    ACalc.Free;
  end;
end;

function TACLDockSiteSideBar.CalculatePopupBounds(AChild: TACLDockControl): TRect;

  function GetActualValue(AValue, AMaxValue: Integer): Integer;
  begin
    AValue := Min(AValue, MulDiv(80, AMaxValue, 100));
  {$IFDEF ACL_DOCKING_ANIMATE_SIDEBAR}
    if Owner.ShowAnimation <> nil then
      Result := Round(AValue * Owner.ShowAnimation.Progress)
    else
  {$ENDIF}
      Result := AValue;
  end;

begin
  Result := MainSite.ContentRect;
  case Side of
    mRight:
      Result.Left := Result.Right - GetActualValue(AChild.CustomWidth, Result.Width);
    mBottom:
      Result.Top := Result.Bottom - GetActualValue(AChild.CustomHeight, Result.Height);
    mTop:
      Result.Height := GetActualValue(AChild.CustomHeight, Result.Height);
    mLeft:
      Result.Width := GetActualValue(AChild.CustomWidth, Result.Width);
  end;
end;

procedure TACLDockSiteSideBar.Changed;
begin
  Owner.Changed(Self);
end;

procedure TACLDockSiteSideBar.Draw(ACanvas: TCanvas);
const
  Borders: array[TACLBorder] of TACLBorders = (
    [mTop, mRight, mBottom], [mLeft, mRight, mBottom],
    [mLeft, mTop, mBottom], [mLeft, mTop, mRight]
  );
var
  AActiveTab: TACLDockSiteSideBarTab;
  ATab: TACLDockSiteSideBarTab;
begin
  AActiveTab := Owner.ActiveTab;

  acFillRect(ACanvas, Bounds, Style.SideBar.AsColor);

  for var I := 0 to FTabs.Count - 1 do
  begin
    ATab := FTabs.List[I];
    Style.SideBarTab.Draw(ACanvas, ATab.Bounds, 2 + Ord(AActiveTab = ATab), Borders[Side]);

    if AActiveTab = ATab then
      ACanvas.Font.Assign(Style.SideBarTabFontActive)
    else
      ACanvas.Font.Assign(Style.SideBarTabFont);

    ACanvas.Brush.Style := bsClear;
    if Side in [mTop, mBottom] then
      acTextDraw(ACanvas, ATab.Control.ToString, ATab.Bounds, taCenter, taVerticalCenter, True, True)
    else
      acTextDrawVertical(ACanvas, ATab.Control.ToString, ATab.Bounds, taCenter, taVerticalCenter, True);
  end;
end;

function TACLDockSiteSideBar.FindTab(AControl: TACLDockControl): TACLDockSiteSideBarTab;
begin
  for var I := FTabs.Count - 1 downto 0 do
  begin
    if FTabs.List[I].Control = AControl then
      Exit(FTabs.List[I]);
  end;
  Result := nil;
end;

function TACLDockSiteSideBar.GetMainSite: TACLDockSite;
begin
  Result := Owner.Site;
end;

function TACLDockSiteSideBar.HitTest(const P: TPoint): TACLDockSiteSideBarTab;
begin
  if PtInRect(Bounds, P) then
    for var I := 0 to FTabs.Count - 1 do
    begin
      if PtInRect(FTabs.List[I].Bounds, P) then
        Exit(FTabs.List[I]);
    end;

  Result := nil;
end;

procedure TACLDockSiteSideBar.LayoutLoad(ANode: TACLXMLNode);
begin
  ANode.Enum(
    procedure (ANode: TACLXMLNode)
    var
      ACtrlIndex: Integer;
    begin
      ACtrlIndex := ANode.Attributes.GetValueAsInteger(TACLDockingSchema.AttrIndex, -1);
      if (ACtrlIndex >= 0) and (ACtrlIndex < MainSite.ControlCount) then
      begin
        MainSite.Controls[ACtrlIndex].SideBar := Self;
        FTabs.Last.LayoutLoad(ANode.Nodes[0], Owner.Site.Owner);
      end;
    end);
end;

procedure TACLDockSiteSideBar.LayoutSave(ANode: TACLXMLNode);
var
  LNode: TACLXMLNode;
  LTab: TACLDockSiteSideBarTab;
begin
  for var I := 0 to FTabs.Count - 1 do
  begin
    LTab := FTabs.List[I];
    LNode := ANode.Add(TACLDockingSchema.NodeItem);
    LNode.Attributes.Add(TACLDockingSchema.AttrIndex, IndexOfControl(LTab.Control));
    LTab.LayoutSave(LNode.Add(TACLDockingSchema.NodePos));
  end;
end;

procedure TACLDockSiteSideBar.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;
  if (AOperation = opRemove) and (AComponent is TACLDockControl) then
    Unregister(TACLDockControl(AComponent));
end;

procedure TACLDockSiteSideBar.Register(AControl: TACLDockControl);
begin
  if AControl is TACLDockSite then
    raise EInvalidArgument.Create('Unable to pin DockSite to side bar');
  if FindTab(AControl) <> nil then
    raise EInvalidArgument.Create('The controls is already pinned');

  MainSite.DisableAlign;
  try
    // Keep the order
    FTabs.Add(TACLDockSiteSideBarTab.Create(AControl));
    AControl.Parent := MainSite;
    AControl.Align := alCustom;
    AControl.Visible := False;
    Changed;
  finally
    MainSite.EnableAlign;
  end;
end;

procedure TACLDockSiteSideBar.RestorePosition(ATab: TACLDockSiteSideBarTab);
var
  LGroup: TACLDockGroup;
begin
  if csDestroying in ComponentState then
    Exit;
  if csDestroying in ATab.Control.ComponentState then
    Exit;

  LGroup := ATab.PrevParent;
  if LGroup = nil then
    LGroup := MainSite;

  LGroup.DisableAlign;
  try
    // Keep the order
    ATab.Control.Parent := LGroup;
    ATab.Control.Align := ATab.PrevAlign;
    LGroup.SetChildOrder(ATab.Control, ATab.PrevIndex);
    ATab.Control.Visible := True;
  finally
    LGroup.EnableAlign;
  end;
end;

procedure TACLDockSiteSideBar.Unregister(AControl: TACLDockControl);
var
  LTab: TACLDockSiteSideBarTab;
begin
  if csDestroying in ComponentState then
    Exit;
  LTab := FindTab(AControl);
  if LTab <> nil then
  begin
    RestorePosition(LTab);
    FTabs.Remove(LTab);
    Changed;
  end;
end;

{ TACLDockSiteSideBars }

constructor TACLDockSiteSideBars.Create(ASite: TACLDockSite);
begin
  FSite := ASite;
  FAutoHideTimer := TACLTimer.CreateEx(AutoHideProc, AutoHideDelayTime);
  FAutoShowTimer := TACLTimer.CreateEx(AutoShowProc, AutoShowDelayTime);
  for var I := Low(TACLBorder) to High(TACLBorder) do
    FBars[I] := TACLDockSiteSideBar.Create(Self, I);
end;

destructor TACLDockSiteSideBars.Destroy;
begin
{$IFDEF ACL_DOCKING_ANIMATE_SIDEBAR}
  FreeAndNil(FShowAnimation);
{$ENDIF}
  FreeAndNil(FAutoShowTimer);
  FreeAndNil(FAutoHideTimer);
  for var I := Low(TACLBorder) to High(TACLBorder) do
    FreeAndNil(FBars[I]);
  inherited;
end;

procedure TACLDockSiteSideBars.Animate;
var
  ADockGroup: TWinControl;
begin
{$IFDEF ACL_DOCKING_ANIMATE_SIDEBAR}
  if ShowAnimation.Finished or (ActiveTab = nil) then
  begin
    FreeAndNil(FShowAnimation);
    FAutoHideTimer.Enabled := True;
  end;
{$ENDIF}
  if ActiveTab <> nil then
  begin
    ADockGroup := ActiveTab.Control.Parent;
    ADockGroup.Realign;
    ADockGroup.Update;
  end;
end;

procedure TACLDockSiteSideBars.AutoHideProc(Sender: TObject);
var
  ACursorPos: TPoint;
  ADockControl: TACLDockControl;
begin
  if ActiveTab = nil then
    Exit;
  if GetCapture <> 0 then
    Exit;

  ACursorPos := Mouse.CursorPos;
  if HitTest(FSite.ScreenToClient(ACursorPos)) <> nil then
    Exit;

  ADockControl := GetNearestDockControl(FindVCLWindow(ACursorPos), TACLDockControl);
  if (ADockControl <> nil) and acIsChild(ActiveTab.Control, ADockControl) then
    Exit;

  ADockControl := GetNearestDockControl(FindControl(GetFocus), TACLDockControl);
  if (ADockControl <> nil) and acIsChild(ActiveTab.Control, ADockControl) then
    Exit;

  ActivateTab(nil);
end;

procedure TACLDockSiteSideBars.AutoShowProc(Sender: TObject);
var
  ABar: TACLDockSiteSideBar;
  ATab: TACLDockSiteSideBarTab;
begin
  FAutoShowTimer.Enabled := False;
  if FCursorPos = Site.CalcCursorPos then
  begin
    ABar := HitTest(FCursorPos);
    if ABar <> nil then
    begin
      ATab := ABar.HitTest(FCursorPos);
      if ATab <> nil then
        ActivateTab(ATab);
    end;
  end;
end;

procedure TACLDockSiteSideBars.ActivateTab(ATab: TACLDockSiteSideBarTab; AAnimate: Boolean);
begin
  if ATab <> FActiveTab then
  begin
    if FActiveTab <> nil then
    begin
    {$IFDEF ACL_DOCKING_ANIMATE_SIDEBAR}
      FreeAndNil(FShowAnimation);
    {$ENDIF}
      FAutoHideTimer.Enabled := False;
      FActiveTab.Control.Hide;
      FActiveTab := nil;
      Site.Update;
    end;
    if ATab <> nil then
    begin
      FActiveTab := ATab;
      FActiveTab.Control.BringToFront;
    {$IFDEF ACL_DOCKING_ANIMATE_SIDEBAR}
      if AAnimate then
      begin
        FShowAnimation := TACLAnimation.Create(Self, ShowAnimationTime);
        FShowAnimation.FreeOnTerminate := False;
        FShowAnimation.Run;
        FActiveTab.Control.Show;
      end
      else
    {$ENDIF}
      begin
        FActiveTab.Control.Show;
        FAutoHideTimer.Enabled := True;
      end;
    end;
    Invalidate;
  end;
end;

procedure TACLDockSiteSideBars.Calculate(var ABounds: TRect);
var
  ASideBarSize: Integer;
begin
  ASideBarSize := FSite.Style.MeasureTabHeight;

  FBars[mBottom].Bounds := ABounds.Split(srBottom,
    IfThen(FBars[mBottom].FTabs.Count > 0, ASideBarSize));
  FBars[mLeft].Bounds := ABounds.Split(srLeft,
    IfThen(FBars[mLeft].FTabs.Count > 0, ASideBarSize));
  FBars[mRight].Bounds := ABounds.Split(srRight,
    IfThen(FBars[mRight].FTabs.Count > 0, ASideBarSize));
  FBars[mTop].Bounds := ABounds.Split(srTop,
    IfThen(FBars[mTop].FTabs.Count > 0, ASideBarSize));

  ABounds.Bottom := FBars[mBottom].Bounds.Top;
  ABounds.Right := FBars[mRight].Bounds.Left;
  ABounds.Left := FBars[mLeft].Bounds.Right;
  ABounds.Top := FBars[mTop].Bounds.Bottom;

  CalculateLayout;
end;

procedure TACLDockSiteSideBars.CalculateLayout;
begin
  for var I := Low(TACLBorder) to High(TACLBorder) do
    FBars[I].Calculate;
end;

procedure TACLDockSiteSideBars.Changed(ASender: TACLDockSiteSideBar);
begin
  if not IsValid(FActiveTab) then
    FActiveTab := nil;
  Site.Realign;
  Site.Invalidate;
end;

procedure TACLDockSiteSideBars.Draw(ACanvas: TCanvas);
begin
  for var I := Low(TACLBorder) to High(TACLBorder) do
    FBars[I].Draw(ACanvas);
end;

function TACLDockSiteSideBars.HitTest(const P: TPoint): TACLDockSiteSideBar;
begin
  for var I := Low(TACLBorder) to High(TACLBorder) do
  begin
    if PtInRect(FBars[I].Bounds, P) then
      Exit(FBars[I]);
  end;
  Result := nil;
end;

procedure TACLDockSiteSideBars.Invalidate;
begin
  for var I := Low(TACLBorder) to High(TACLBorder) do
    FSite.InvalidateRect(FBars[I].Bounds);
end;

function TACLDockSiteSideBars.IsValid(ATab: TACLDockSiteSideBarTab): Boolean;
begin
  for var I := Low(TACLBorder) to High(TACLBorder) do
  begin
    if FBars[I].FTabs.IndexOf(ATab) >= 0 then
      Exit(True);
  end;
  Result := False;
end;

procedure TACLDockSiteSideBars.LayoutLoad(ANode: TACLXMLNode);
begin
  for var I := Low(TACLBorder) to High(TACLBorder) do
  begin
    if Ord(I) >= ANode.Count then
      Break;
    FBars[I].LayoutLoad(ANode[Ord(I)]);
  end;
end;

procedure TACLDockSiteSideBars.LayoutSave(ANode: TACLXMLNode);
begin
  for var I := Low(TACLBorder) to High(TACLBorder) do
    FBars[I].LayoutSave(ANode.Add(TACLDockingSchema.NodeItem));
end;

procedure TACLDockSiteSideBars.MouseDown(const P: TPoint; AChild: TACLDockControl);
var
  ABar: TACLDockSiteSideBar;
  ATab: TACLDockSiteSideBarTab;
begin
  FAutoShowTimer.Enabled := False;

  ABar := HitTest(P);
  if ABar <> nil then
  begin
    ATab := ABar.HitTest(P);
    if ATab <> nil then
    begin
      ActivateTab(ATab);
      Exit;
    end;
  end;

  if (ActiveTab <> nil) and not acIsChild(ActiveTab.Control, AChild) then
    ActivateTab(nil);
end;

procedure TACLDockSiteSideBars.MouseMove(const P: TPoint);
begin
  if FCursorPos <> P then
  begin
    FCursorPos := P;
    FAutoShowTimer.Restart;
  end;
end;

function TACLDockSiteSideBars.OptimalFor(AControl: TACLDockControl): TACLDockSiteSideBar;
var
  AGroup: TACLDockGroup;
  ASide: TACLBorder;
begin
  ASide := mBottom;
  if Safe.Cast(AControl.Parent, TACLDockGroup, AGroup) then
  begin
    if AControl.Align in TACLDockGroup.AlignFirst then
    begin
      if AGroup.Layout = TACLDockGroupLayout.Horizontal then
        ASide := mLeft
      else
        ASide := mTop;
    end;
    if AControl.Align in TACLDockGroup.AlignLast then
    begin
      if AGroup.Layout = TACLDockGroupLayout.Horizontal then
        ASide := mRight
      else
        ASide := mBottom;
    end;
  end
  else
    case AControl.Align of
      alTop:
        ASide := mTop;
      alLeft:
        ASide := mLeft;
      alRight:
        ASide := mRight;
    end;

  Result := FBars[ASide];
end;

{$ENDREGION}

{ TACLDockSite }

constructor TACLDockSite.Create(AOwner: TComponent);
begin
  inherited;
  FSideBars := TACLDockSiteSideBars.Create(Self);
  FFloatForms := TACLObjectList<TACLFloatDockForm>.Create;
end;

destructor TACLDockSite.Destroy;
begin
  FreeAndNil(FFloatForms);
  FreeAndNil(FSideBars);
  inherited;
end;

procedure TACLDockSite.AlignControls(AControl: TControl; var ARect: TRect);
var
  AChild: TACLDockControl;
begin
  SideBars.Calculate(ARect);
  inherited;
  if SideBars.ActiveTab <> nil then
  begin
    AChild := SideBars.ActiveTab.Control;
    if AChild.SideBar <> nil then // occurs while unpinning
    begin
      AChild.Aligning;
      AChild.BoundsRect := AChild.SideBar.CalculatePopupBounds(AChild);
      AChild.Aligned;
    end;
  end;
end;

procedure TACLDockSite.CMDockingUpdateText(var Message: TMessage);
begin
  SideBars.CalculateLayout;
  SideBars.Invalidate;
end;

procedure TACLDockSite.CMDockingVisibility(var Message: TMessage);
var
  AControl: TACLDockControl;
begin
  AControl := TACLDockControl(Message.LParam);
  if (AControl <> nil) and (AControl.SideBar <> nil) then
  begin
    if Message.WParam <> 0 then
    begin
      SideBars.ActivateTab(AControl.SideBar.FindTab(AControl), False);
      acSafeSetFocus(AControl);
    end
    else
      if (SideBars.ActiveTab <> nil) and (AControl = SideBars.ActiveTab.Control) then
        SideBars.ActivateTab(nil);
  end;
end;

function TACLDockSite.CreateStyle: TACLStyleDocking;
begin
  Result := TACLStyleDockSite.Create(Self);
end;

procedure TACLDockSite.GetDockZones(ASource: TACLDockControl; AList: TACLDockZones);
var
  AControl: TControl;
begin
  for var ASide := Low(TACLBorder) to High(TACLBorder) do
    AList.Add(TACLDockZoneSide.Create(Self, ASide));

  for var I := 0 to ControlCount - 1 do
  begin
    AControl := Controls[I];
    if AControl.Visible and (AControl.Align = alClient) then
      Exit;
  end;
  AList.Add(TACLDockZoneClient.Create(Self));
end;

function TACLDockSite.GetStyle: TACLStyleDockSite;
begin
  Result := inherited Style as TACLStyleDockSite;
end;

function TACLDockSite.HitOnSizeBox(const P: TPoint; out X: TACLDockControl; out Y: TACLBorder): Boolean;
begin
  Result := False;
end;

function TACLDockSite.IsBoundsStored: Boolean;
begin
  Result := True;
end;

procedure TACLDockSite.LayoutLoad(const AFileName: string);
var
  LLayout: TACLXMLDocument;
begin
  LLayout := TACLXMLDocument.CreateEx(AFileName);
  try
    LayoutLoad(LLayout);
  finally
    LLayout.Free;
  end;
end;

procedure TACLDockSite.LayoutLoad(const ADocument: TACLXMLDocument);
var
  AFloatForm: TACLFloatDockForm;
  ANode: TACLXMLNode;
  ARoot: TACLXMLNode;
begin
  if ADocument.FindNode(TACLDockingSchema.NodeRoot, ARoot) then
  begin
    DisableAlign;
    try
      ResetLayoutAndHidePanels;
      if ARoot.FindNode(TACLDockingSchema.NodeEmbedded, ANode) then
        inherited LayoutLoad(ANode);
      if ARoot.FindNode(TACLDockingSchema.NodeFloat, ANode) then
      begin
        for var I := 0 to ANode.Count - 1 do
        begin
          AFloatForm := TACLFloatDockForm.Create(Self);
          AFloatForm.LayoutLoad(ANode[I]);
          AFloatForm.Perform(CM_DOCKING_PACK, 0, 0);
        end;
      end;
      if ARoot.FindNode(TACLDockingSchema.NodeSideBar, ANode) then
        SideBars.LayoutLoad(ANode);
      Perform(CM_DOCKING_PACK, 0, 0);
    finally
      EnableAlign;
    end;
  end;
end;

procedure TACLDockSite.LayoutSave(const ADocument: TACLXMLDocument);
var
  ANode: TACLXMLNode;
  ARoot: TACLXMLNode;
begin
  ADocument.Clear;
  ARoot := ADocument.Add(TACLDockingSchema.NodeRoot);
  inherited LayoutSave(ARoot.Add(TACLDockingSchema.NodeEmbedded));

  if FloatForms.Count > 0 then
  begin
    ANode := ARoot.Add(TACLDockingSchema.NodeFloat);
    for var I := 0 to FloatForms.Count - 1 do
      FloatForms.List[I].LayoutSave(ANode.Add(TACLDockingSchema.NodeItem));
  end;
  SideBars.LayoutSave(ARoot.Add(TACLDockingSchema.NodeSideBar));
end;

procedure TACLDockSite.LayoutSave(const AFileName: string);
var
  ALayout: TACLXMLDocument;
begin
  ALayout := TACLXMLDocument.Create;
  try
    LayoutSave(ALayout);
    ALayout.SaveToFile(AFileName);
  finally
    ALayout.Free;
  end;
end;

procedure TACLDockSite.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  SideBars.MouseMove(Point(X, Y));
end;

procedure TACLDockSite.Paint;
begin
  inherited;
  SideBars.Draw(Canvas);
end;

procedure TACLDockSite.ResetLayoutAndHidePanels;

  procedure Populate(AList: TList; AControl: TACLDockControl);
  begin
    if AControl is TACLDockPanel then
      AList.Add(AControl);
    if AControl is TACLDockGroup then
    begin
      for var I := 0 to TACLDockGroup(AControl).ControlCount - 1 do
        Populate(AList, TACLDockGroup(AControl).Controls[I]);
    end;
  end;

var
  AList: TList;
begin
  AList := TList.Create;
  try
    Populate(AList, Self);
    for var I := 0 to FloatForms.Count - 1 do
      Populate(AList, FloatForms.List[I].DockGroup);

    for var I := 0 to AList.Count - 1 do
    begin
      TControl(AList.List[I]).Parent := Self;
      TControl(AList.List[I]).Visible := False;
    end;

    for var I := ControlCount - 1 downto 0 do
    begin
      if Controls[I] is TACLDockGroup then
        Controls[I].Free;
    end;
    FloatForms.Clear;
  finally
    AList.Free;
  end;
end;

procedure TACLDockSite.SetStyle(AValue: TACLStyleDockSite);
begin
  Style.Assign(AValue);
end;

{$ENDREGION}

initialization
  RegisterClass(TACLDockGroup);
end.
