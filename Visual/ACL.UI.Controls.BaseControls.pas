{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*           Base Control Classes            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.BaseControls;

{$I ACL.Config.Inc}

interface

uses
  Winapi.Messages,
  Winapi.UxTheme,
  Winapi.Windows,
  // System
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // Vcl
  Vcl.ActnList,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.Ex.Gdip,
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.UI.Animation,
  ACL.UI.Application,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.FileSystem;

const
  acIndentBetweenElements = 5;
  acResizeHitTestAreaSize = 6;
  crRemove = TCursor(-25);
  crDragLink = TCursor(-26);

const
  AnchorTop = [akLeft, akTop, akRight];
  AnchorClient = [akLeft, akTop, akRight, akBottom];
  AnchorBottomLeft = [akLeft, akBottom];
  AnchorBottomRight = [akRight, akBottom];

type
  TACLMouseWheelDirection = (
    mwdDown, // Scroll the mouse wheel down (to yourself), the list must be scrolled to next item. equals to LB_LINEDOWN.
    mwdUp    // Scroll the mouse wheel up (from yourself), the list must be scrolled to previous item. equals to LB_LINEUP.
  );

  TACLOrientation = (oHorizontal, oVertical);
  TACLSelectionMode = (smUnselect, smSelect, smInvert);
  TACLControlBackgroundStyle = (cbsOpaque, cbsTransparent, cbsSemitransparent);

  TACLCustomDrawEvent = procedure (Sender: TObject; ACanvas: TCanvas; const R: TRect; var AHandled: Boolean) of object;
  TACLKeyPreviewEvent = procedure (AKey: Word; AShift: TShiftState; var AAccept: Boolean) of object;
  TACLGetHintEvent = procedure (Sender: TObject; X, Y: Integer; var AHint: string) of object;

  { IACLControl }

  IACLControl = interface(IACLScaleFactor)
  ['{D41EBD0F-D2EE-4517-AD7E-EEE8FC0ACFD4}']
    procedure InvalidateRect(const R: TRect);
    procedure Update;
  end;

  { IACLFocusableControl }

  IACLFocusableControl = interface
  ['{789F1399-A5A1-4096-9DEE-8A788489F75E}']
    function CanFocus: Boolean;
    procedure SetFocus;
  end;

  { IACLFocusableControl2 }

  IACLFocusableControl2 = interface
  ['{AB5AF65A-6996-48AF-A881-F3A3CC1CB662}']
    procedure SetFocusOnSearchResult;
  end;

  { IACLCursorProvider }

  IACLCursorProvider = interface
  ['{2FCA84BF-1DFE-40AC-88C8-893791B1AB8F}']
    function GetCursor(const P: TPoint): TCursor;
  end;

  { IACLInnerControl }

  IACLInnerControl = interface
  ['{8F98096E-7A0D-4D77-82AB-B9724B3C6596}']
    function GetInnerContainer: TWinControl;
  end;

  { IACLInplaceControl }

  IACLInplaceControl = interface
  ['{494D7949-6E70-6C61-6365-436F6E74726F}']
    function InplaceGetValue: UnicodeString;
    function InplaceIsFocused: Boolean;
    procedure InplaceSetFocus;
    procedure InplaceSetValue(const AValue: UnicodeString);
  end;

  { IACLMouseTracking }

  IACLMouseTracking = interface
  ['{38A56452-B7C5-4B72-B872-84BAC2163EC7}']
    function IsMouseAtControl: Boolean;
    procedure MouseEnter;
    procedure MouseLeave;
  end;

  { IACLPopup }

  IACLPopup = interface
  ['{EDDF3E8C-C4DA-4AE7-9CED-78F068DDB8AE}']
    procedure PopupUnderControl(const ControlRect: TRect);
  end;

  { TACLInplaceInfo }

  TACLInplaceInfo = packed record
    Bounds: TRect;
    ColumnIndex: Integer;
    Parent: TWinControl;
    RowIndex: Integer;
    TextBounds: TRect;

    OnApply: TNotifyEvent;
    OnCancel: TNotifyEvent;
    OnKeyDown: TKeyEvent;

    procedure Reset;
  end;

  { TACLPadding }

  TACLPadding = class(TPersistent)
  strict private
    FData: array[0..3] of Integer;
    FDefaultValue: Integer;
    FScalable: Boolean;

    FOnChanged: TNotifyEvent;

    function GetAll: Integer;
    function GetMargins: TRect;
    function GetValue(const Index: Integer): Integer;
    function IsAllAssigned: Boolean;
    function IsAllStored: Boolean;
    function IsValueStored(const Index: Integer): Boolean;
    procedure SetAll(const Value: Integer);
    procedure SetMargins(const Value: TRect);
    procedure SetScalable(const Value: Boolean);
    procedure SetValue(const Index, Value: Integer);
  protected
    procedure Changed; virtual;
    function IsStored: Boolean; virtual;
    //
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  public
    constructor Create(ADefaultValue: Integer);
    procedure Assign(Source: TPersistent); override;
    function GetScaledMargins(const AScaleFactor: TACLScaleFactor): TRect;
    //
    property Margins: TRect read GetMargins write SetMargins;
  published
    property All: Integer read GetAll write SetAll stored IsAllStored;
    property Bottom: Integer index 0 read GetValue write SetValue stored IsValueStored;
    property Left: Integer index 1 read GetValue write SetValue stored IsValueStored;
    property Right: Integer index 2 read GetValue write SetValue stored IsValueStored;
    property Top: Integer index 3 read GetValue write SetValue stored IsValueStored;
    property Scalable: Boolean read FScalable write SetScalable default True;
  end;

  { TACLMargins }

  TACLMargins = class(TACLPadding)
  public const
    DefaultValue = 3;
  end;

  { TACLCheckBoxStateHelper }

  TACLCheckBoxStateHelper = record helper for TCheckBoxState
  public
    class function Create(AChecked: Boolean): TCheckBoxState; overload; static;
    class function Create(AHasChecked, AHasUnchecked: Boolean): TCheckBoxState; overload; static;
    class function Create(AValue: TACLBoolean): TCheckBoxState; overload; static;
    function ToBool: TACLBoolean;
  end;

  { TACLCustomOptionsPersistent }

  TACLCustomOptionsPersistent = class(TACLLockablePersistent)
  protected
    procedure SetBooleanFieldValue(var AFieldValue: Boolean;
      AValue: Boolean; AChanges: TACLPersistentChanges = [apcStruct]);
    procedure SetIntegerFieldValue(var AFieldValue: Integer;
      AValue: Integer; AChanges: TACLPersistentChanges = [apcStruct]);
    procedure SetSingleFieldValue(var AFieldValue: Single;
      AValue: Single; AChanges: TACLPersistentChanges = [apcStruct]);
  end;

  { TACLStyleBackground }

  TACLStyleBackground = class(TACLStyle)
  protected
    procedure InitializeResources; override;
  public
    procedure DrawBorder(ACanvas: TCanvas; const R: TRect; const ABorders: TACLBorders);
    procedure DrawContent(ACanvas: TCanvas; const R: TRect);
    function IsTransparentBackground: Boolean;
  published
    property ColorBorder1: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorBorder2: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorContent1: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorContent2: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLStyleContent }

  TACLStyleContent = class(TACLStyleBackground)
  strict private
    function GetTextColor(Enabled: Boolean): TColor;
  protected
    procedure InitializeResources; override;
  public
    property TextColors[Enabled: Boolean]: TColor read GetTextColor;
  published
    property ColorText: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
    property ColorTextDisabled: TACLResourceColor index 5 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLStyleHatch }

  TACLStyleHatch = class(TACLStyle)
  public const
    DefaultSize = acHatchDefaultSize;
  protected
    procedure InitializeResources; override;
  public
    procedure Draw(ACanvas: TCanvas; const R: TRect; ASize: Integer = DefaultSize); overload;
    procedure Draw(ACanvas: TCanvas; const R: TRect; ABorders: TACLBorders; ASize: Integer = DefaultSize); overload;
    procedure DrawColorPreview(ACanvas: TCanvas; const R: TRect; AColor: TAlphaColor);
  published
    property ColorBorder: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorContent1: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorContent2: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLGraphicControl }

  TACLGraphicControl = class(TGraphicControl,
    IACLColorSchema,
    IACLControl,
    IACLCursorProvider,
    IACLMouseTracking,
    IACLObjectLinksSupport,
    IACLResourceChangeListener,
    IACLScaleFactor,
    IACLResourceCollection)
  strict private
    FMargins: TACLMargins;
    FMouseInControl: Boolean;
    FResourceCollection: TACLCustomResourceCollection;
    FScaleFactor: TACLScaleFactor;

    FOnBoundsChanged: TNotifyEvent;
    FOnGetHint: TACLGetHintEvent;
    FOnMouseEnter: TNotifyEvent;
    FOnMouseLeave: TNotifyEvent;

    function GetIsDesigning: Boolean;
    function GetIsDestroying: Boolean;
    function GetIsLoading: Boolean;
    function IsMarginsStored: Boolean;
    procedure MarginsChangeHandler(Sender: TObject);
    procedure SetMargins(const Value: TACLMargins);
    procedure SetResourceCollection(AValue: TACLCustomResourceCollection);
  protected
    procedure AdjustSize; override;
    procedure DoGetHint(const P: TPoint; var AHint: string); virtual;
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; virtual;
    procedure SetParent(AParent: TWinControl); override;
    procedure SetDefaultSize; virtual;
    procedure SetTargetDPI(AValue: Integer); virtual;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure UpdateTransparency;

    // IACLResourcesChangeListener
    procedure ResourceChanged(Sender: TObject; Resource: TACLResource = nil); overload;
    procedure ResourceChanged; overload; virtual;
    procedure ResourceCollectionChanged; virtual;
    // IACLResourceCollection
    function GetCollection: TACLCustomResourceCollection;
    // IACLScaleFactor
    function GetScaleFactor: TACLScaleFactor;
    // IACLMouseTracking
    function IsMouseAtControl: Boolean; virtual;
    procedure MouseEnter; virtual;
    procedure MouseLeave; virtual;
    // IACLCursorProvider
    function GetCursor(const P: TPoint): TCursor; virtual;
    procedure UpdateCursor;

    // Mouse
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    // Messages
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    //
    property MouseInControl: Boolean read FMouseInControl;
    property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseLeave: TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
    //
    property IsDesigning: Boolean read GetIsDesigning;
    property IsDestroying: Boolean read GetIsDestroying;
    property IsLoading: Boolean read GetIsLoading;
    property ResourceCollection: TACLCustomResourceCollection read FResourceCollection write SetResourceCollection;
    property ScaleFactor: TACLScaleFactor read FScaleFactor;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    // IACLColorSchema
    procedure ApplyColorSchema(const ASchema: TACLColorSchema); virtual;
    // IACLControl
    procedure InvalidateRect(const R: TRect); virtual;
    //
    property Canvas;
  published
    property Align;
    property Anchors;
    property Enabled;
    property Hint;
    property Margins: TACLMargins read FMargins write SetMargins stored IsMarginsStored;
    property Visible;
    //
    property OnBoundsChanged: TNotifyEvent read FOnBoundsChanged write FOnBoundsChanged;
    property OnGetHint: TACLGetHintEvent read FOnGetHint write FOnGetHint;
  end;

  { TACLCustomControl }

  TACLCustomControlClass = class of TACLCustomControl;
  TACLCustomControl = class(TCustomControl,
    IACLColorSchema,
    IACLControl,
    IACLCursorProvider,
    IACLFocusableControl,
    IACLLocalizableComponent,
    IACLMouseTracking,
    IACLObjectLinksSupport,
    IACLResourceChangeListener,
    IACLScaleFactor,
    IACLResourceCollection)
  strict private
    FFocusOnClick: Boolean;
    FIsHovered: Boolean;
    FLangSection: UnicodeString;
    FMargins: TACLMargins;
    FPadding: TACLPadding;
    FResourceCollection: TACLCustomResourceCollection;
    FScaleChangeCount: Integer;
    FScaleChangeState: TObject;
    FScaleFactor: TACLScaleFactor;
    FTransparent: Boolean;

    FOnGetHint: TACLGetHintEvent;

    function GetIsDesigning: Boolean;
    function GetIsDestroying: Boolean;
    function GetIsLoading: Boolean;
    function GetLangSection: UnicodeString;
    function GetScaleFactor: TACLScaleFactor;
    procedure DrawBackground(DC: HDC; const R: TRect);
    function IsMarginsStored: Boolean;
    function IsPaddingStored: Boolean;
    procedure SetMargins(const Value: TACLMargins);
    procedure SetPadding(const Value: TACLPadding);
    procedure SetResourceCollection(AValue: TACLCustomResourceCollection);
    procedure SetTransparent(AValue: Boolean);
    //
    procedure MarginsChangeHandler(Sender: TObject);
    procedure PaddingChangeHandler(Sender: TObject);
    // Messages
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMScaleChanged(var Message: TMessage); message CM_SCALECHANGED;
    procedure CMScaleChanging(var Message: TMessage); message CM_SCALECHANGING;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMMouseMove(var Message: TWMMouseMove); message WM_MOUSEMOVE;
    procedure WMMouseWheelHorz(var Message: TWMMouseWheel); message WM_MOUSEHWHEEL;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  protected
    procedure AdjustClientRect(var ARect: TRect); override;
    procedure AdjustSize; override;
    function AllowCompositionPainting: Boolean; virtual;
    procedure BoundsChanged; virtual;
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    function CreatePadding: TACLPadding; virtual;
    function GetClientRect: TRect; override;
    function GetContentOffset: TRect; virtual;
    function GetBackgroundStyle: TACLControlBackgroundStyle; virtual;
    procedure DoFullRefresh; virtual;
    procedure DoGetHint(const P: TPoint; var AHint: string); virtual;
    procedure DoLoaded; virtual;
    procedure DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect); virtual;
    procedure DrawTransparentBackground(DC: HDC; const R: TRect); virtual;
    procedure FocusChanged; virtual;
    procedure Loaded; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure PaintWindow(DC: HDC); override;
    procedure Resize; override;
    procedure SetDefaultSize; virtual;
    procedure SetFocusOnClick; virtual;
    procedure SetParent(AParent: TWinControl); override;
    procedure SetTargetDPI(AValue: Integer); virtual;
    procedure UpdateCursor;
    procedure UpdateTransparency;
    procedure WndProc(var Message: TMessage); override;

    // IACLMouseTracking
    function IsMouseAtControl: Boolean; virtual;
    procedure MouseEnter; virtual;
    procedure MouseLeave; virtual;

    // IACLResourceCollection
    function GetCollection: TACLCustomResourceCollection;

    // IACLResourcesChangeListener
    procedure ResourceChanged(Sender: TObject; Resource: TACLResource = nil); overload;
    procedure ResourceChanged; overload; virtual;
    procedure ResourceCollectionChanged; virtual;

    // IACLCursorProvider
    function GetCursor(const P: TPoint): TCursor; virtual;

    // Properties
    property FocusOnClick: Boolean read FFocusOnClick write FFocusOnClick default False;
    property IsHovered: Boolean read FIsHovered;
    property LangSection: UnicodeString read GetLangSection;
    property Padding: TACLPadding read FPadding write SetPadding stored IsPaddingStored;
    property ResourceCollection: TACLCustomResourceCollection read FResourceCollection write SetResourceCollection;
    property ScaleFactor: TACLScaleFactor read FScaleFactor;
    property Transparent: Boolean read FTransparent write SetTransparent default False;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure FullRefresh;
    procedure Invalidate; override;
    // IACLControl
    procedure InvalidateRect(const R: TRect); virtual;
    // IACLColorSchema
    procedure ApplyColorSchema(const ASchema: TACLColorSchema); virtual;
    // IACLLocalizableComponent
    procedure Localize; overload;
    procedure Localize(const ASection: UnicodeString); overload; virtual;
    procedure ScaleForPPI(NewPPI: Integer); override;
    property IsDesigning: Boolean read GetIsDesigning;
    property IsDestroying: Boolean read GetIsDestroying;
    property IsLoading: Boolean read GetIsLoading;
  published
    property Align;
    property Anchors;
    property Constraints;
    property Ctl3D;
    property DoubleBuffered default False;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property Margins: TACLMargins read FMargins write SetMargins stored IsMarginsStored;
    property ParentBiDiMode;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property Visible;

    property OnClick;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetHint: TACLGetHintEvent read FOnGetHint write FOnGetHint;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

  { TACLSubControlOptions }

  TACLSubControlOptions = class(TPersistent)
  strict private
    FAlign: TACLBoolean;
    FControl: TControl;
    FOwner: TControl;
    FPosition: TACLBorder;
    FPrevWndProc: TWndMethod;

    function GetActualIndentBetweenElements: Integer;
    function Validate: Boolean;
    procedure SetAlign(AValue: TACLBoolean);
    procedure SetControl(AValue: TControl);
    procedure SetPosition(AValue: TACLBorder);
  protected
    procedure Changed; virtual;
    procedure WindowProc(var Message: TMessage); virtual;
    // Called from the Owner
    procedure AfterAutoSize(var AWidth, AHeight: Integer); virtual;
    procedure AlignControl(var AClientRect: TRect); virtual;
    procedure BeforeAutoSize(var AWidth, AHeight: Integer); virtual;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); virtual;
    function TrySetFocus: Boolean;
    //
    property Owner: TControl read FOwner;
  public
    constructor Create(AOwner: TControl);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property Align: TACLBoolean read FAlign write SetAlign default TACLBoolean.Default;
    property Position: TACLBorder read FPosition write SetPosition default mRight;
    property Control: TControl read FControl write SetControl; // last
  end;

  { TACLContainer }

  TACLContainer = class(TACLCustomControl)
  strict private
    FBorders: TACLBorders;
    FStyle: TACLStyleBackground;

    procedure SetBorders(AValue: TACLBorders);
    procedure SetStyle(const Value: TACLStyleBackground);
  protected
    function CreateStyle: TACLStyleBackground; virtual;
    procedure DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect); override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    function GetContentOffset: TRect; override;
    procedure Paint; override;
    procedure SetTargetDPI(AValue: Integer); override;
    //
    property Borders: TACLBorders read FBorders write SetBorders default acAllBorders;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ResourceCollection;
    property Style: TACLStyleBackground read FStyle write SetStyle;
  end;

  { TACLControlsHelper }

  TACLControlsHelper = class
  strict private
    class var TouchControl: TControl;
  protected
    class procedure WMGesture(ACaller: TWinControl; var Message: TMessage);
    class procedure WMGestureNotify(ACaller: TWinControl; var Message: TWMGestureNotify);
    class function WMSetCursor(ACaller: TWinControl; var AMessage: TWMSetCursor): Boolean;
  public
    class function GetScaleFactor(AOwner: TComponent; out AIntf: IACLScaleFactor): Boolean; static;
    class function IsChildOrSelf(AParent, AControl: TControl): Boolean;
    class function ProcessMessage(ACaller: TWinControl; var Message: TMessage): Boolean;

    // Scaling
    class function CanSetParent(AControl, ANewParent: TControl): Boolean;
    class procedure ScaleChanging(AControl: TWinControl; var AState: TObject);
    class procedure ScaleChanged(AControl: TWinControl; var AState: TObject);
    class procedure UpdateScaleFactorOnParentChange(AControl: TControl);
  end;

  { TACLMouseTracking }

  TACLMouseTracking = class(TACLTimerList<IACLMouseTracking>)
  protected
    procedure DoAdding(const AObject: IACLMouseTracking); override;
    procedure TimerObject(const AObject: IACLMouseTracking); override;
  public
    procedure AfterConstruction; override;
    procedure RemoveOwner(AOwnerObject: TObject);
  end;

  { TACLMouseWheel }

  TACLMouseWheel = class
  public const
    DefaultScrollLines = 1;
    DefaultScrollLinesAlt = 2;
    DefaultScrollLinesCtrl = 4;
  public
    class var ScrollLines: Integer;
    class var ScrollLinesAlt: Integer;
    class var ScrollLinesCtrl: Integer;
  public const
    DirectionToInteger: array[TACLMouseWheelDirection] of Integer = (-1, 1);
    DirectionToScrollCode: array[TACLMouseWheelDirection] of TScrollCode = (scLineDown, scLineUp);
    DirectionToScrollCodeI: array[TACLMouseWheelDirection] of Integer = (SB_LINEDOWN, SB_LINEUP);
  public
    class constructor Create;
    class function GetDirection(AValue: Integer): TACLMouseWheelDirection;
    class function GetScrollLines(AState: TShiftState): Integer;
    class function HWheelToVWheel(const AMessage: TWMMouseWheel): TWMMouseWheel;
  end;

  { TACLDeferPlacementUpdate }

  TACLDeferPlacementUpdate = class
  strict private
    FDictionary: TACLDictionary<TWinControl, TRect>;
  private
    function GetBounds(AControl: TWinControl): TRect;
  public
    procedure Add(AControl: TWinControl; ALeft, ATop, AWidth, AHeight: Integer); overload;
    procedure Add(AControl: TWinControl; const ABounds: TRect); overload;
    procedure BeginUpdate;
    procedure EndUpdate;
    //
    property Bounds[AControl: TWinControl]: TRect read GetBounds;
  end;

  { TACLScrollToMode }

  {$SCOPEDENUMS ON}
  TACLScrollToMode = (MakeVisible, MakeTop, MakeCenter);
  {$SCOPEDENUMS OFF}

const
  acDefaultUIFadingEnabled = True;

var
  acUIFadingEnabled: Boolean = acDefaultUIFadingEnabled;
  acUIFadingTime: Integer = 200;

function CallCustomDrawEvent(Sender: TObject; AEvent: TACLCustomDrawEvent; ACanvas: TCanvas; const R: TRect): Boolean;
function CreateControl(AClass: TControlClass; AParent: TWinControl;
  const R: TRect; AAlign: TAlign = alNone; AAnchors: TAnchors = [akLeft, akTop]): TControl; overload;
procedure CreateControl(var Obj; AClass: TControlClass; AParent: TWinControl;
  const R: TRect; AAlign: TAlign = alNone; AAnchors: TAnchors = [akLeft, akTop]); overload;
function GetElementWidthIncludeOffset(const R: TRect; AScaleFactor: TACLScaleFactor): Integer;

function acCalculateScrollToDelta(
  const AObjectBounds, AAreaBounds: TRect; AScrollToMode: TACLScrollToMode): TPoint; overload;
function acCalculateScrollToDelta(AObjectTopValue, AObjectBottomValue: Integer;
  AAreaTopValue, AAreaBottomValue: Integer; AScrollToMode: TACLScrollToMode): Integer; overload;

function acCanStartDragging(const ADeltaX, ADeltaY: Integer; AScaleFactor: TACLScaleFactor): Boolean; overload;
function acCanStartDragging(const P0, P1: TPoint; AScaleFactor: TACLScaleFactor): Boolean; overload;
procedure acDesignerSetModified(AInvoker: TPersistent);
function acGetContainer(AControl: TControl): TControl;
function acGetTargetDPI(const AControl: TWinControl): Integer; overload;
function acGetTargetDPI(const APoint: TPoint): Integer; overload;
function acIsChild(AControl, AChildToTest: TControl): Boolean;
function acIsDropDownCommand(Key: Word; Shift: TShiftState): Boolean;
function acIsSemitransparentFill(AContentColor1, AContentColor2: TACLResourceColor): Boolean;
function acIsShiftPressed(ATest, AState: TShiftState): Boolean;
function acOpacityToAlphaBlendValue(AOpacity: Integer): Byte;
function acShiftStateToKeys(AShift: TShiftState): WORD;

procedure acRestoreDC(ACanvas: TCanvas; ASaveIndex: Integer);
procedure acRestoreFocus(ASavedFocus: HWND);
function acSaveDC(ACanvas: TCanvas): Integer;
function acSaveFocus: HWND;
function acSafeSetFocus(AControl: TWinControl): Boolean;

procedure acLockRedraw(AControl: TWinControl);
procedure acFullRedraw(AControl: TWinControl);
procedure acUnlockRedraw(AControl: TWinControl; ARedraw: Boolean);

// Keyboard
function acGetShiftState: TShiftState;
function acIsAltKeyPressed: Boolean;
function acIsCtrlKeyPressed: Boolean;

function MouseTracker: TACLMouseTracking;
implementation

uses
  Winapi.DwmApi,
  // System
  System.Math,
  // Vcl
  Vcl.Forms,
  // ACL
  ACL.Threading,
  ACL.UI.HintWindow,
  ACL.Utils.Desktop;

type
  TPersistentAccess = class(TPersistent);
  TControlAccess = class(TControl);
  TWinControlAccess = class(TWinControl);

var
  FMouseTracker: TACLMouseTracking;

function MouseTracker: TACLMouseTracking;
begin
  if FMouseTracker = nil then
    FMouseTracker := TACLMouseTracking.Create;
  Result := FMouseTracker;
end;

function acGetShiftState: TShiftState;
begin
  //#AI: We must ask use the GetKeyState instead of the GetKeyboardState,
  // because second doesn't return real information after next actions:
  // 1. Focus main form of application
  // 2. Alt+Click on window of another application
  // 3. Click on taskbar button of our application, click again
  // 4. Try to get GetKeyboardState in the SC_MINIMIZE handler
  Result := [];
  if GetKeyState(VK_SHIFT) < 0 then
    Include(Result, ssShift);
  if GetKeyState(VK_CONTROL) < 0 then
    Include(Result, ssCtrl);
  if GetKeyState(VK_MENU) < 0 then
    Include(Result, ssAlt);
  if GetKeyState(VK_LBUTTON) < 0 then
    Include(Result, ssLeft);
  if GetKeyState(VK_MBUTTON) < 0 then
    Include(Result, ssMiddle);
  if GetKeyState(VK_RBUTTON) < 0 then
    Include(Result, ssRight);
end;

function acIsAltKeyPressed: Boolean;
begin
  Result := GetKeyState(VK_MENU) < 0;
end;

function acIsCtrlKeyPressed: Boolean;
begin
  Result := GetKeyState(VK_CONTROL) < 0;
end;

function acShiftStateToKeys(AShift: TShiftState): WORD;
begin
  Result := 0;
  if ssShift in AShift then Inc(Result, MK_SHIFT);
  if ssCtrl in AShift then Inc(Result, MK_CONTROL);
  if ssLeft in AShift then Inc(Result, MK_LBUTTON);
  if ssRight in AShift then Inc(Result, MK_RBUTTON);
  if ssMiddle in AShift then Inc(Result, MK_MBUTTON);
end;

function acOpacityToAlphaBlendValue(AOpacity: Integer): Byte;
begin
  Result := 15 + MulDiv(240, AOpacity, 100)
end;

procedure acDesignerSetModified(AInvoker: TPersistent);

  function IsValidComponentState(AComponent: TComponent): Boolean;
  begin
    Result := AComponent.ComponentState * [csLoading, csWriting, csDestroying] = [];
  end;

  function CanSetModified(AObject: TPersistent): Boolean;
  begin
    if AObject is TComponent then
      Result := IsValidComponentState(TComponent(AObject))
    else
      Result := True;

    if AObject <> nil then
      Result := Result and CanSetModified(TPersistentAccess(AObject).GetOwner);
  end;

var
  ADesigner: IDesignerNotify;
begin
  if CanSetModified(AInvoker) then
  begin
    ADesigner := FindRootDesigner(AInvoker);
    if ADesigner <> nil then
      ADesigner.Modified;
  end;
end;

function acCalculateScrollToDelta(const AObjectBounds, AAreaBounds: TRect; AScrollToMode: TACLScrollToMode): TPoint;
begin
  Result.X := acCalculateScrollToDelta(AObjectBounds.Left, AObjectBounds.Right, AAreaBounds.Left, AAreaBounds.Right, AScrollToMode);
  Result.Y := acCalculateScrollToDelta(AObjectBounds.Top, AObjectBounds.Bottom, AAreaBounds.Top, AAreaBounds.Bottom, AScrollToMode);
end;

function acCalculateScrollToDelta(AObjectTopValue, AObjectBottomValue: Integer;
  AAreaTopValue, AAreaBottomValue: Integer; AScrollToMode: TACLScrollToMode): Integer;
begin
  case AScrollToMode of
    TACLScrollToMode.MakeTop:
      Result := AObjectTopValue - AAreaTopValue;

    TACLScrollToMode.MakeCenter:
      if AAreaBottomValue - AAreaTopValue > AObjectBottomValue - AObjectTopValue then
        Result := (AObjectBottomValue + AObjectTopValue) div 2 - (AAreaTopValue + AAreaBottomValue) div 2
      else
        Result := AObjectTopValue - AAreaTopValue;

  else // MakeVisible
    if AObjectTopValue < AAreaTopValue then
      Result := AObjectTopValue - AAreaTopValue
    else if AObjectBottomValue > AAreaBottomValue then
      Result := Min(AObjectBottomValue - AAreaBottomValue, AObjectTopValue - AAreaTopValue)
    else
      Result := 0;
  end;
end;

function acCanStartDragging(const ADeltaX, ADeltaY: Integer; AScaleFactor: TACLScaleFactor): Boolean;
begin
  Result := Max(Abs(ADeltaX), Abs(ADeltaY)) >= AScaleFactor.Apply(Mouse.DragThreshold);
end;

function acCanStartDragging(const P0, P1: TPoint; AScaleFactor: TACLScaleFactor): Boolean;
begin
  Result := acCanStartDragging(P1.X - P0.X, P1.Y - P0.Y, AScaleFactor);
end;

function acGetContainer(AControl: TControl): TControl;
var
  AIntf: IACLInnerControl;
begin
  if Supports(AControl, IACLInnerControl, AIntf) then
    Result := AIntf.GetInnerContainer
  else
    Result := AControl;
end;

function acGetTargetDPI(const APoint: TPoint): Integer;
begin
  if IsWin8OrLater then
    Result := MonitorGet(APoint).PixelsPerInch
  else
    Result := acSystemScaleFactor.TargetDPI;
end;

function acGetTargetDPI(const AControl: TWinControl): Integer;
var
  APlacement: TWindowPlacement;
  APosition: TPoint;
begin
  APlacement.length := SizeOf(TWindowPlacement);
  if GetWindowPlacement(AControl.Handle, APlacement) then
    APosition := acRectCenter(APlacement.rcNormalPosition)
  else
    APosition := AControl.ClientToScreen(acRectCenter(AControl.ClientRect));

  Result := acGetTargetDPI(APosition);
end;

function ImageListSize(AImages: TCustomImageList): TSize;
begin
  if AImages <> nil then
    Result := acSize(AImages.Width, AImages.Height)
  else
    Result := NullSize;
end;

function GetElementWidthIncludeOffset(const R: TRect; AScaleFactor: TACLScaleFactor): Integer;
begin
  Result := acRectWidth(R);
  if Result > 0 then
    Inc(Result, AScaleFactor.Apply(acIndentBetweenElements));
end;

function acIsChild(AControl, AChildToTest: TControl): Boolean;
begin
  Result := False;
  while AChildToTest <> nil do
  begin
    if AChildToTest = AControl then
      Exit(True);
    AChildToTest := AChildToTest.Parent;
  end;
end;

function acIsDropDownCommand(Key: Word; Shift: TShiftState): Boolean;
const
  Modificators = [ssAlt, ssShift, ssCtrl];
begin
  Result :=
    (Key = VK_F4) and (Modificators * Shift = []) or
    (Key = VK_DOWN) and (Modificators * Shift = [ssAlt]);
end;

function acIsShiftPressed(ATest, AState: TShiftState): Boolean;
begin
  Result := ([ssAlt, ssShift, ssCtrl] * (AState - ATest) = []) and (AState * ATest = ATest);
end;

function acIsSemitransparentFill(AContentColor1, AContentColor2: TACLResourceColor): Boolean;
var
  AValue1: TAlphaColor;
  AValue2: TAlphaColor;
begin
  AValue1 := AContentColor1.Value;
  AValue2 := AContentColor2.Value;
  Result :=
    AValue1.IsValid and (AValue1.A < MaxByte) or
    AValue2.IsValid and (AValue1.A < MaxByte);
end;

procedure acRestoreDC(ACanvas: TCanvas; ASaveIndex: Integer);
begin
  RestoreDC(ACanvas.Handle, ASaveIndex);
  ACanvas.Refresh; // to reset ACanvas.State
end;

procedure acRestoreFocus(ASavedFocus: HWND);
var
  AProcessId: Cardinal;
begin
  if ASavedFocus <> 0 then
  begin
    GetWindowThreadProcessId(ASavedFocus, @AProcessId);
    if AProcessId <> GetCurrentProcessId then
      SetForegroundWindow(ASavedFocus)
    else
      SetFocus(ASavedFocus)
  end;
end;

function acSaveDC(ACanvas: TCanvas): Integer;
begin
  Result := SaveDC(ACanvas.Handle);
end;

function acSaveFocus: HWND;
var
  AIntf: IACLInnerControl;
begin
  Result := GetFocus;
  if Result = 0 then
    Result := GetForegroundWindow;
  if Supports(FindControl(Result), IACLInnerControl, AIntf) then
    Result := AIntf.GetInnerContainer.Handle;
end;

function acSafeSetFocus(AControl: TWinControl): Boolean;
begin
  try
    Result := AControl <> nil;
    if Result then
      AControl.SetFocus;
  except
    Result := False;
  end;
end;

procedure acLockRedraw(AControl: TWinControl);
begin
  SendMessage(AControl.Handle, WM_SETREDRAW, 0, 0);
end;

procedure acFullRedraw(AControl: TWinControl);
begin
  RedrawWindow(AControl.Handle, nil, 0, RDW_INVALIDATE or RDW_ALLCHILDREN or RDW_ERASE);
end;

procedure acUnlockRedraw(AControl: TWinControl; ARedraw: Boolean);
begin
  SendMessage(AControl.Handle, WM_SETREDRAW, 1, 1);
  if ARedraw then
    acFullRedraw(AControl);
end;

function CallCustomDrawEvent(Sender: TObject; AEvent: TACLCustomDrawEvent; ACanvas: TCanvas; const R: TRect): Boolean;
begin
  Result := False;
  if Assigned(AEvent) then
    AEvent(Sender, ACanvas, R, Result);
end;

function CreateControl(AClass: TControlClass; AParent: TWinControl;
  const R: TRect; AAlign: TAlign = alNone; AAnchors: TAnchors = [akLeft, akTop]): TControl;
begin
  Result := AClass.Create(AParent);
  Result.Parent := AParent;
  Result.BoundsRect := R;
  Result.Align := AAlign;
  Result.Anchors := AAnchors;
end;

procedure CreateControl(var Obj; AClass: TControlClass; AParent: TWinControl;
  const R: TRect; AAlign: TAlign = alNone; AAnchors: TAnchors = [akLeft, akTop]);
begin
  TControl(Obj) := CreateControl(AClass, AParent, R, AAlign, AAnchors);
end;

{ TACLMouseTracking }

procedure TACLMouseTracking.AfterConstruction;
begin
  inherited AfterConstruction;
  Interval := 50;
end;

procedure TACLMouseTracking.RemoveOwner(AOwnerObject: TObject);
var
  ATracker: IACLMouseTracking;
begin
  if Supports(AOwnerObject, IACLMouseTracking, ATracker) then
    Remove(ATracker);
end;

procedure TACLMouseTracking.DoAdding(const AObject: IACLMouseTracking);
begin
  AObject.MouseEnter;
end;

procedure TACLMouseTracking.TimerObject(const AObject: IACLMouseTracking);
begin
  if not AObject.IsMouseAtControl then
  begin
    Remove(AObject);
    AObject.MouseLeave;
  end;
end;

{ TACLInplaceInfo }

procedure TACLInplaceInfo.Reset;
begin
  ZeroMemory(@Self, SizeOf(Self));
end;

{ TACLPadding }

constructor TACLPadding.Create(ADefaultValue: Integer);
var
  I: Integer;
begin
  inherited Create;
  FScalable := True;
  FDefaultValue := ADefaultValue;
  for I := 0 to Length(FData) - 1 do
    FData[I] := FDefaultValue;
end;

procedure TACLPadding.Assign(Source: TPersistent);
var
  I: Integer;
begin
  if Source is TACLPadding then
  begin
    for I := 0 to Length(FData) - 1 do
      FData[I] := TACLPadding(Source).FData[I];
    Changed;
  end
  else
    if Source is TMargins then
    begin
      Left := TMargins(Source).Left;
      Top := TMargins(Source).Top;
      Right := TMargins(Source).Right;
      Bottom := TMargins(Source).Bottom;
    end;
end;

function TACLPadding.GetScaledMargins(const AScaleFactor: TACLScaleFactor): TRect;
var
  AValue: Single;
begin
  if Scalable and AScaleFactor.Assigned then
  begin
    //#AI:
    //  not using rounding up, because size of
    //  content will be too large and scroll bars will appeared
    AValue := AScaleFactor.Numerator / AScaleFactor.Denominator;
    Result.Bottom := Trunc(Margins.Bottom * AValue);
    Result.Left := Trunc(Margins.Left * AValue);
    Result.Right := Trunc(Margins.Right * AValue);
    Result.Top := Trunc(Margins.Top * AValue);
  end
  else
    Result := Margins;
end;

procedure TACLPadding.Changed;
begin
  CallNotifyEvent(Self, OnChanged);
end;

function TACLPadding.IsStored: Boolean;
var
  I: Integer;
begin
  Result := IsAllStored or not Scalable;
  for I := 0 to 3 do
    Result := Result or IsValueStored(I);
end;

function TACLPadding.GetAll: Integer;
begin
  if IsAllAssigned then
    Result := Left
  else
    Result := 0;
end;

function TACLPadding.GetMargins: TRect;
begin
  Result := Rect(Left, Top, Right, Bottom);
end;

function TACLPadding.GetValue(const Index: Integer): Integer;
begin
  Result := FData[Index];
end;

function TACLPadding.IsAllAssigned: Boolean;
begin
  Result := (FData[0] = FData[1]) and (FData[2] = FData[3]) and (FData[1] = FData[2]);
end;

function TACLPadding.IsAllStored: Boolean;
begin
  Result := IsAllAssigned and (Left <> FDefaultValue)
end;

function TACLPadding.IsValueStored(const Index: Integer): Boolean;
begin
  Result := (GetValue(Index) <> FDefaultValue) and not IsAllAssigned;
end;

procedure TACLPadding.SetAll(const Value: Integer);
var
  I: Integer;
begin
  if not IsAllAssigned or (Value <> All) then
  begin
    for I := 0 to Length(FData) - 1 do
      FData[I] := Value;
    Changed;
  end;
end;

procedure TACLPadding.SetMargins(const Value: TRect);
begin
  Bottom := Value.Bottom;
  Left := Value.Left;
  Right := Value.Right;
  Top := Value.Top;
end;

procedure TACLPadding.SetScalable(const Value: Boolean);
begin
  if FScalable <> Value then
  begin
    FScalable := Value;
    Changed;
  end;
end;

procedure TACLPadding.SetValue(const Index, Value: Integer);
begin
  if GetValue(Index) <> Value then
  begin
    FData[Index] := Value;
    Changed;
  end;
end;

{ TACLControlsHelper }

class function TACLControlsHelper.CanSetParent(AControl, ANewParent: TControl): Boolean;
begin
  Result := (AControl.Parent <> ANewParent) or (csReading in AControl.ComponentState);
end;

class function TACLControlsHelper.GetScaleFactor(AOwner: TComponent; out AIntf: IACLScaleFactor): Boolean;
begin
  while AOwner <> nil do
  begin
    if Supports(AOwner, IACLScaleFactor, AIntf) then
      Exit(True);
    AOwner := AOwner.Owner;
  end;
  Result := False;
end;

class function TACLControlsHelper.IsChildOrSelf(AParent, AControl: TControl): Boolean;
begin
  Result := False;
  while AControl <> nil do
  begin
    if AControl = AParent then
      Exit(True);
    AControl := AControl.Parent;
  end;
end;

class function TACLControlsHelper.ProcessMessage(ACaller: TWinControl; var Message: TMessage): Boolean;
begin
  Result := True;
  case Message.Msg of
    WM_GESTURE:
      WMGesture(ACaller, Message);
    WM_GESTURENOTIFY:
      WMGestureNotify(ACaller, TWMGestureNotify(Message));
    WM_SETCURSOR:
      Result := WMSetCursor(ACaller, TWMSetCursor(Message));
    else
      Result := False;
  end;
end;

class procedure TACLControlsHelper.ScaleChanging(AControl: TWinControl; var AState: TObject);
var
  AChildControl: TControlAccess;
  I: Integer;
begin
  AControl.DisableAlign;
  AState := TObject(TWinControlAccess(AControl).AutoSize);
  for I := 0 to AControl.ControlCount - 1 do
  begin
    AChildControl := TControlAccess(AControl.Controls[I]);
    AChildControl.FAnchorMove := True;
  end;
  TWinControlAccess(AControl).AutoSize := False;
end;

class procedure TACLControlsHelper.ScaleChanged(AControl: TWinControl; var AState: TObject);
var
  AChildControl: TControlAccess;
  I: Integer;
begin
  for I := 0 to AControl.ControlCount - 1 do
  begin
    AChildControl := TControlAccess(AControl.Controls[I]);
    AChildControl.FAnchorMove := False;
    AChildControl.UpdateBoundsRect(AChildControl.BoundsRect); // to invoke UpdateAnchorRules
  end;
  TWinControlAccess(AControl).AutoSize := Boolean(AState);
  TWinControlAccess(AControl).EnableAlign;
end;

class procedure TACLControlsHelper.UpdateScaleFactorOnParentChange(AControl: TControl);
var
  AParent: IACLScaleFactor;
  ASource: IACLScaleFactor;
  M, D: Integer;
begin
  if Supports(AControl, IACLScaleFactor, ASource) and Supports(AControl.Parent, IACLScaleFactor, AParent) then
  begin
    M := AParent.Value.Numerator * ASource.Value.Denominator;
    D := AParent.Value.Denominator * ASource.Value.Numerator;
    acReduceFraction(M, D);
    if M <> D then
    begin
      if csLoading in AControl.ComponentState then
      begin
        TControlAccess(AControl).FCurrentPPI := AParent.Value.TargetDPI;
        ASource.Value.Assign(M, D);
      end
      else
        TControlAccess(AControl).ScaleForPPI(AParent.Value.TargetDPI);
    end;
  end;
end;

class procedure TACLControlsHelper.WMGesture(ACaller: TWinControl; var Message: TMessage);
const
  GestureMap: array[0..4] of TInteractiveGesture = (
    igZoom, igPan, igRotate, igTwoFingerTap, igPressAndTap
  );
var
  AControl: TControl;
  AEventInfo: TGestureEventInfo;
  AGestureInfo: GestureInfo;
  APoint: TPoint;
begin
  if TouchControl = nil then
  begin
    Message.Result := DefWindowProc(ACaller.Handle, Message.Msg, Message.WParam, Message.LParam);
    Exit;
  end;

  ZeroMemory(@AGestureInfo, SizeOf(AGestureInfo));
  AGestureInfo.cbSize := Sizeof(AGestureInfo);
  if GetGestureInfo(Message.LParam, AGestureInfo) then
  try
    ZeroMemory(@AEventInfo, SizeOf(AEventInfo));
    AEventInfo.GestureID := AGestureInfo.dwID + igiFirst;

    AControl := TouchControl;
    while (AControl.Parent <> nil) and
      (igoParentPassthrough in AControl.Touch.InteractiveGestureOptions) and not
      (GestureMap[AEventInfo.GestureID - igiZoom] in AControl.Touch.InteractiveGestures)
    do
      AControl := AControl.Parent;

    APoint := SmallPointToPoint(AGestureInfo.ptsLocation);
    if not IsWin8OrLater then
      PhysicalToLogicalPoint(ACaller.Handle, APoint);
    AEventInfo.Location := AControl.ScreenToClient(APoint);
    AEventInfo.Flags := [];

    if AGestureInfo.dwFlags and GF_BEGIN = GF_BEGIN then
      Include(AEventInfo.Flags, gfBegin);
    if AGestureInfo.dwFlags and GF_INERTIA = GF_INERTIA then
      Include(AEventInfo.Flags, gfInertia);
    if AGestureInfo.dwFlags and GF_END = GF_END then
      Include(AEventInfo.Flags, gfEnd);

    case AEventInfo.GestureID of
      igiRotate:
        AEventInfo.Angle := RotateAngleFromArgument(AGestureInfo.ullArguments);

      igiZoom, igiTwoFingerTap:
        AEventInfo.Distance := Cardinal(AGestureInfo.ullArguments);

      igiPan:
        begin
          AEventInfo.Distance := Cardinal(AGestureInfo.ullArguments);
          AEventInfo.InertiaVector := InertiaVectorFromArgument(AGestureInfo.ullArguments);
        end;

      igiPressAndTap:
        begin
          APoint := SmallPointToPoint(TSmallPoint(Cardinal(AGestureInfo.ullArguments)));
          Inc(APoint.X, AGestureInfo.ptsLocation.X);
          Inc(APoint.Y, AGestureInfo.ptsLocation.Y);

          if AControl is TWinControl then
            PhysicalToLogicalPoint(TWinControl(AControl).Handle, APoint)
          else
            PhysicalToLogicalPoint(AControl.Parent.Handle, APoint);

          AEventInfo.TapLocation := PointToSmallPoint(AControl.ScreenToClient(APoint));
        end;
    end;

    // Send the event to the control, if not handled pass to Windows
    Message.Result := AControl.Perform(CM_GESTURE, 0, @AEventInfo);
    if Message.Result <> 1 then
      Message.Result := DefWindowProc(ACaller.Handle, Message.Msg, Message.WParam, Message.LParam);
  finally
    CloseGestureInfoHandle(Message.LParam);
    if AEventInfo.GestureID = igiEnd then
      TouchControl := nil;
  end;
end;

class procedure TACLControlsHelper.WMGestureNotify(ACaller: TWinControl; var Message: TWMGestureNotify);
const
  // All pan gesture options
  CPanOoptions: TInteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter];
  // Gestures
  CPan: array[Boolean] of Cardinal = (0, GC_PAN);
  CZoom: array[Boolean] of Cardinal = (0, GC_ZOOM);
  CRotate: array[Boolean] of Cardinal = (0, GC_ROTATE);
  CPressAndTap: array[Boolean] of Cardinal = (0, GC_PRESSANDTAP);
  CTwoFingerTap: array[Boolean] of Cardinal = (0, GC_TWOFINGERTAP);
  // Options
  CPanSingleFingerVertical: array[Boolean] of Cardinal = (0, GC_PAN_WITH_SINGLE_FINGER_VERTICALLY);
  CPanSingleFingerHorizontal: array[Boolean] of Cardinal = (0, GC_PAN_WITH_SINGLE_FINGER_HORIZONTALLY);
  CPanWithGutter: array[Boolean] of Cardinal = (0, GC_PAN_WITH_GUTTER);
  CPanWithInertia: array[Boolean] of Cardinal = (0, GC_PAN_WITH_INERTIA);
var
  AConfigs: array of TGestureConfig;
  AControl: TControl;
  AGestureOptions, AControlGestureOptions: TInteractiveGestureOptions;
  AGestures, AControlGestures: TInteractiveGestures;
  APoint: TPoint;
begin
  // Convert incoming point to logical client coordinates
  APoint := SmallPointToPoint(Message.NotifyStruct^.ptsLocation);
  PhysicalToLogicalPoint(ACaller.Handle, APoint);
  APoint := ACaller.ScreenToClient(APoint);

  AGestures := [];
  if PtInRect(ACaller.ClientRect, APoint) then
  begin
    // Find control to gesture will be sent to
    TouchControl := ACaller.ControlAtPos(APoint, True);
    if TouchControl = nil then
      TouchControl := ACaller;

    // Build complete list of gestures
    AControl := TouchControl;
    TControlAccess(AControl).DoGetGestureOptions(AGestures, AGestureOptions);
    while (AControl.Parent <> nil) and (igoParentPassthrough in AControl.Touch.InteractiveGestureOptions) do
    begin
      AControl := AControl.Parent;
      TControlAccess(AControl).DoGetGestureOptions(AControlGestures, AControlGestureOptions);
      // Include Pan options if igPan isn't in LGestures
      if (igPan in AGestures) then
        AGestureOptions := AGestureOptions + (AControlGestureOptions - CPanOoptions)
      else
        AGestureOptions := AGestureOptions + AControlGestureOptions;
      AGestures := AGestures + AControlGestures;
    end;
  end;

  // Call SetGestureConfig with the gestures the control wants
  if AGestures = [] then
  begin
    SetLength(AConfigs, 1);
    AConfigs[0].dwID := 0;
    AConfigs[0].dwWant := 0;
    AConfigs[0].dwBlock := GC_ALLGESTURES;
  end
  else
  begin
    SetLength(AConfigs, 5);
    ZeroMemory(@AConfigs[0], SizeOf(GestureConfig) * 5);

    // Pan gesture & options
    AConfigs[0].dwID := GID_PAN;
    AConfigs[0].dwWant := CPan[igPan in AGestures] or
      CPanSingleFingerVertical[igoPanSingleFingerVertical in AGestureOptions] or
      CPanSingleFingerHorizontal[igoPanSingleFingerHorizontal in AGestureOptions] or
      CPanWithGutter[igoPanGutter in AGestureOptions] or
      CPanWithInertia[igoPanInertia in AGestureOptions];
    AConfigs[0].dwBlock := CPan[not (igPan in AGestures)] or
      CPanSingleFingerVertical[not (igoPanSingleFingerVertical in AGestureOptions)] or
      CPanSingleFingerHorizontal[not (igoPanSingleFingerHorizontal in AGestureOptions)] or
      CPanWithGutter[not (igoPanGutter in AGestureOptions)] or
      CPanWithInertia[not (igoPanInertia in AGestureOptions)];

    // Zoom gesture
    AConfigs[1].dwID := GID_ZOOM;
    AConfigs[1].dwWant := CZoom[igZoom in AGestures];
    AConfigs[1].dwBlock := CZoom[not (igZoom in AGestures)];

    // Rotate gesture
    AConfigs[2].dwID := GID_ROTATE;
    AConfigs[2].dwWant := CRotate[igRotate in AGestures];
    AConfigs[2].dwBlock := CRotate[not (igRotate in AGestures)];

    // TwoFingerTap gesture
    AConfigs[3].dwID := GID_TWOFINGERTAP;
    AConfigs[3].dwWant := CTwoFingerTap[igTwoFingerTap in AGestures];
    AConfigs[3].dwBlock := CTwoFingerTap[not (igTwoFingerTap in AGestures)];

    // PressAnTap gesture
    AConfigs[4].dwID := GID_PRESSANDTAP;
    AConfigs[4].dwWant := CPressAndTap[igPressAndTap in AGestures];
    AConfigs[4].dwBlock := CPressAndTap[not (igPressAndTap in AGestures)];
  end;

  SetGestureConfig(ACaller.Handle, 0, Length(AConfigs), @AConfigs[0], SizeOf(TGestureConfig));
  TWinControlAccess(ACaller).UpdateTIPStatus;
  Message.Result := 1;
end;

class function TACLControlsHelper.WMSetCursor(ACaller: TWinControl; var AMessage: TWMSetCursor): Boolean;

  function GetCursor(AControl: TControl; const P: TPoint): TCursor;
  var
    ACursorProvider: IACLCursorProvider;
  begin
    if csDesigning in AControl.ComponentState then
      Result := crArrow
    else
      if Supports(AControl, IACLCursorProvider, ACursorProvider) then
        Result := ACursorProvider.GetCursor(P)
      else
        Result := AControl.Cursor;
  end;

var
  ACursor: TCursor;
  AControl: TControl;
  APoint: TPoint;
begin
  Result := False;
  if (AMessage.CursorWnd = ACaller.Handle) and (AMessage.HitTest = HTCLIENT) then
  begin
    ACursor := Screen.Cursor;
    if ACursor = crDefault then
    begin
      APoint := ACaller.ScreenToClient(Mouse.CursorPos);
      AControl := ACaller.ControlAtPos(APoint, False);
      if AControl <> nil then
        ACursor := GetCursor(AControl, acPointOffset(APoint, AControl.Left, AControl.Top));
      if ACursor = crDefault then
        ACursor := GetCursor(ACaller, APoint);
    end;
    if ACursor <> crDefault then
    begin
      Winapi.Windows.SetCursor(Screen.Cursors[ACursor]);
      AMessage.Result := 1;
      Result := True;
    end;
  end;
end;

{ TACLCheckBoxStateHelper }

class function TACLCheckBoxStateHelper.Create(AChecked: Boolean): TCheckBoxState;
begin
  if AChecked then
    Result := cbChecked
  else
    Result := cbUnchecked;
end;

class function TACLCheckBoxStateHelper.Create(AValue: TACLBoolean): TCheckBoxState;
const
  Map: array[TACLBoolean] of TCheckBoxState = (cbGrayed, cbUnchecked, cbChecked);
begin
  Result := Map[AValue];
end;

class function TACLCheckBoxStateHelper.Create(AHasChecked, AHasUnchecked: Boolean): TCheckBoxState;
begin
  if AHasChecked and AHasUnchecked then
    Result := cbGrayed
  else if AHasChecked then
    Result := cbChecked
  else
    Result := cbUnchecked;
end;

function TACLCheckBoxStateHelper.ToBool: TACLBoolean;
const
  Map: array[TCheckBoxState] of TACLBoolean = (acFalse, acTrue, acDefault);
begin
  Result := Map[Self];
end;

{ TACLCustomOptionsPersistent }

procedure TACLCustomOptionsPersistent.SetBooleanFieldValue(
  var AFieldValue: Boolean; AValue: Boolean; AChanges: TACLPersistentChanges);
begin
  if AFieldValue <> AValue then
  begin
    AFieldValue := AValue;
    Changed(AChanges);
  end;
end;

procedure TACLCustomOptionsPersistent.SetIntegerFieldValue(
  var AFieldValue: Integer; AValue: Integer; AChanges: TACLPersistentChanges);
begin
  if AFieldValue <> AValue then
  begin
    AFieldValue := AValue;
    Changed(AChanges);
  end;
end;

procedure TACLCustomOptionsPersistent.SetSingleFieldValue(
  var AFieldValue: Single; AValue: Single; AChanges: TACLPersistentChanges);
begin
  if AFieldValue <> AValue then
  begin
    AFieldValue := AValue;
    Changed(AChanges);
  end;
end;

{ TACLStyleBackground }

procedure TACLStyleBackground.DrawBorder(ACanvas: TCanvas; const R: TRect; const ABorders: TACLBorders);
begin
  acDrawComplexFrame(ACanvas.Handle, R, ColorBorder1.Value, ColorBorder2.Value, ABorders);
end;

procedure TACLStyleBackground.DrawContent(ACanvas: TCanvas; const R: TRect);
begin
  acDrawGradient(ACanvas.Handle, R, ColorContent1.Value, ColorContent2.Value);
end;

function TACLStyleBackground.IsTransparentBackground: Boolean;
begin
  Result := acIsSemitransparentFill(ColorContent1, ColorContent2);
end;

procedure TACLStyleBackground.InitializeResources;
begin
  ColorBorder1.InitailizeDefaults('Common.Colors.Border1', True);
  ColorBorder2.InitailizeDefaults('Common.Colors.Border2', True);
  ColorContent1.InitailizeDefaults('Common.Colors.Background1', True);
  ColorContent2.InitailizeDefaults('Common.Colors.Background2', True);
end;

{ TACLStyleContent }

function TACLStyleContent.GetTextColor(Enabled: Boolean): TColor;
begin
  if Enabled then
    Result := ColorText.AsColor
  else
    Result := ColorTextDisabled.AsColor;
end;

procedure TACLStyleContent.InitializeResources;
begin
  inherited;
  ColorText.InitailizeDefaults('Common.Colors.Text');
  ColorTextDisabled.InitailizeDefaults('Common.Colors.TextDisabled');
end;

{ TACLStyleHatch }

procedure TACLStyleHatch.Draw(ACanvas: TCanvas; const R: TRect; ASize: Integer = DefaultSize);
begin
  Draw(ACanvas, R, [], ASize);
end;

procedure TACLStyleHatch.Draw(ACanvas: TCanvas; const R: TRect; ABorders: TACLBorders; ASize: Integer = DefaultSize);
begin
  acDrawHatch(ACanvas.Handle, R, ColorContent1.AsColor, ColorContent2.AsColor, ASize);
  acDrawFrameEx(ACanvas.Handle, R, ColorBorder.AsColor, ABorders);
end;

procedure TACLStyleHatch.DrawColorPreview(ACanvas: TCanvas; const R: TRect; AColor: TAlphaColor);
begin
  acDrawColorPreview(ACanvas, R, AColor, ColorBorder.AsColor, ColorContent1.AsColor, ColorContent2.AsColor);
end;

procedure TACLStyleHatch.InitializeResources;
begin
  ColorBorder.InitailizeDefaults('Common.Colors.Border1');
  ColorContent1.InitailizeDefaults('Common.Colors.Hatch1', acHatchDefaultColor1);
  ColorContent2.InitailizeDefaults('Common.Colors.Hatch2', acHatchDefaultColor2);
end;

{ TACLGraphicControl }

constructor TACLGraphicControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMargins := TACLMargins.Create(TACLMargins.DefaultValue);
  FMargins.OnChanged := MarginsChangeHandler;
  FScaleFactor := TACLScaleFactor.Create;
  ControlStyle := ControlStyle + [csCaptureMouse];
end;

destructor TACLGraphicControl.Destroy;
begin
  FreeAndNil(FScaleFactor);
  FreeAndNil(FMargins);
  inherited Destroy;
end;

procedure TACLGraphicControl.AfterConstruction;
begin
  inherited;
  SetDefaultSize;
  UpdateTransparency;
end;

procedure TACLGraphicControl.BeforeDestruction;
begin
  inherited BeforeDestruction;
  RemoveFreeNotifications;
  ResourceCollection := nil;
  MouseTracker.Remove(Self);
  TACLObjectLinks.Release(Self);
  AnimationManager.RemoveOwner(Self);
end;

procedure TACLGraphicControl.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  CallNotifyEvent(Self, OnBoundsChanged);
end;

procedure TACLGraphicControl.ApplyColorSchema(const ASchema: TACLColorSchema);
begin
  acApplyColorSchemaForPublishedProperties(Self, ASchema);
end;

procedure TACLGraphicControl.AdjustSize;
begin
  //#AI:
  //# Set the Visible to True will not call the RequestRealign method if adjusted size of a control is equal to current
  //#
  //#  procedure TControl.SetVisible(Value: Boolean);
  //#  ...
  //#    if Value and AutoSize then
  //#      AdjustSize
  //#    else
  //#      RequestAlign;
  //#
  inherited;
  if AutoSize then
    RequestAlign;
end;

procedure TACLGraphicControl.DoGetHint(const P: TPoint; var AHint: string);
begin
  if Assigned(OnGetHint) then
    OnGetHint(Self, P.X, P.Y, AHint);
end;

procedure TACLGraphicControl.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  ScaleFactor.Change(M, D);
  inherited ChangeScale(M, D, isDpiChange);
  SetTargetDPI(ScaleFactor.TargetDPI);
  MarginsChangeHandler(nil);
end;

function TACLGraphicControl.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  Result := cbsOpaque;
end;

procedure TACLGraphicControl.InvalidateRect(const R: TRect);
begin
  if (Parent <> nil) and Parent.HandleAllocated then
    Winapi.Windows.InvalidateRect(Parent.Handle, acRectOffset(R, Left, Top), True);
end;

function TACLGraphicControl.GetCursor(const P: TPoint): TCursor;
begin
  Result := Cursor;
end;

function TACLGraphicControl.GetCollection: TACLCustomResourceCollection;
begin
  Result := ResourceCollection;
end;

function TACLGraphicControl.GetScaleFactor: TACLScaleFactor;
begin
  Result := FScaleFactor;
end;

function TACLGraphicControl.IsMarginsStored: Boolean;
begin
  Result := FMargins.IsStored;
end;

function TACLGraphicControl.IsMouseAtControl: Boolean;
begin
  Result := Assigned(Parent) and Parent.HandleAllocated and ((GetCaptureControl = Self) or
    PtInRect(ClientRect, CalcCursorPos) and (Perform(CM_HITTEST, 0, PointToLParam(CalcCursorPos)) <> 0));
end;

procedure TACLGraphicControl.SetParent(AParent: TWinControl);
begin
  if TACLControlsHelper.CanSetParent(Self, AParent) then
  begin
    inherited SetParent(AParent);
    TACLControlsHelper.UpdateScaleFactorOnParentChange(Self);
  end;
end;

procedure TACLGraphicControl.SetResourceCollection(AValue: TACLCustomResourceCollection);
begin
  if acResourceCollectionFieldSet(FResourceCollection, Self, Self, AValue) then
    ResourceChanged(ResourceCollection);
end;

procedure TACLGraphicControl.SetDefaultSize;
begin
  // do nothing
end;

procedure TACLGraphicControl.SetTargetDPI(AValue: Integer);
begin
  // do nothing
end;

procedure TACLGraphicControl.Loaded;
begin
  inherited Loaded;
  AdjustSize;
end;

procedure TACLGraphicControl.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  if Operation = opRemove then
  begin
    if AComponent = ResourceCollection then
      ResourceCollection := nil;
  end;
end;

procedure TACLGraphicControl.MouseEnter;
begin
  FMouseInControl := True;
  CallNotifyEvent(Self, OnMouseEnter);
end;

procedure TACLGraphicControl.MouseLeave;
begin
  CallNotifyEvent(Self, OnMouseLeave);
  FMouseInControl := False;
end;

procedure TACLGraphicControl.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  MouseTracker.Add(Self);
end;

procedure TACLGraphicControl.ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
begin
  if Sender = ResourceCollection then
    ResourceCollectionChanged;
  ResourceChanged;
end;

procedure TACLGraphicControl.ResourceChanged;
begin
  if not IsDestroying then
  begin
    AdjustSize;
    UpdateTransparency;
    Invalidate;
  end;
end;

procedure TACLGraphicControl.ResourceCollectionChanged;
begin
  TACLStyle.Refresh(Self);
end;

procedure TACLGraphicControl.UpdateCursor;
begin
  if (Parent <> nil) and Parent.HandleAllocated then
  begin
    if IsMouseAtControl then
      Perform(WM_SETCURSOR, Parent.Handle, HTCLIENT);
  end;
end;

procedure TACLGraphicControl.UpdateTransparency;
var
  AStyle: TACLControlBackgroundStyle;
begin
  AStyle := GetBackgroundStyle;
  if (csOpaque in ControlStyle) <> (AStyle = cbsOpaque) then
  begin
    if AStyle <> cbsOpaque then
      ControlStyle := ControlStyle - [csOpaque]
    else
      ControlStyle := ControlStyle + [csOpaque];

    Invalidate;
  end;
end;

procedure TACLGraphicControl.CMFontChanged(var Message: TMessage);
begin
  inherited;
  ResourceChanged;
end;

procedure TACLGraphicControl.CMHintShow(var Message: TCMHintShow);
begin
  inherited;
  if Message.HintInfo^.HintWindowClass = THintWindow then
    Message.HintInfo^.HintWindowClass := TACLHintWindow;
  DoGetHint(Message.HintInfo.CursorPos, Message.HintInfo.HintStr);
end;

procedure TACLGraphicControl.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TACLGraphicControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TACLGraphicControl.MarginsChangeHandler(Sender: TObject);
begin
  acRectToMargins(Margins.GetScaledMargins(ScaleFactor), inherited Margins);
end;

function TACLGraphicControl.GetIsDesigning: Boolean;
begin
  Result := csDesigning in ComponentState;
end;

function TACLGraphicControl.GetIsDestroying: Boolean;
begin
  Result := csDestroying in ComponentState;
end;

function TACLGraphicControl.GetIsLoading: Boolean;
begin
  Result := csLoading in ComponentState;
end;

procedure TACLGraphicControl.SetMargins(const Value: TACLMargins);
begin
  FMargins.Assign(Value);
end;

{ TACLCustomControl }

constructor TACLCustomControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FScaleFactor := TACLScaleFactor.Create;
  FMargins := TACLMargins.Create(TACLMargins.DefaultValue);
  FMargins.OnChanged := MarginsChangeHandler;
  FPadding := CreatePadding;
  FPadding.OnChanged := PaddingChangeHandler;
end;

destructor TACLCustomControl.Destroy;
begin
  FreeAndNil(FScaleFactor);
  FreeAndNil(FPadding);
  FreeAndNil(FMargins);
  inherited Destroy;
end;

procedure TACLCustomControl.AfterConstruction;
begin
  inherited AfterConstruction;
  SetDefaultSize;
  UpdateTransparency;
end;

procedure TACLCustomControl.BeforeDestruction;
var
  AForm: TCustomForm;
begin
  inherited BeforeDestruction;
  RemoveFreeNotifications;
  ResourceCollection := nil;
  if Parent <> nil then
  begin
    AForm := GetParentForm(Self);
    if AForm <> nil then
      AForm.DefocusControl(Self, True);
  end;
  MouseTracker.Remove(Self);
  TACLObjectLinks.Release(Self);
  AnimationManager.RemoveOwner(Self);
end;

procedure TACLCustomControl.FullRefresh;
begin
  if [csLoading, csDestroying] * ComponentState = [] then
  begin
    BoundsChanged;
    AdjustSize;
    if AutoSize then
      BoundsChanged;
    DoFullRefresh;
    Invalidate;
  end;
end;

procedure TACLCustomControl.Invalidate;
begin
  InvalidateRect(ClientRect);
end;

procedure TACLCustomControl.InvalidateRect(const R: TRect);
begin
  if HandleAllocated and not IsDestroying then
    Winapi.Windows.InvalidateRect(Handle, R, True);
end;

procedure TACLCustomControl.ApplyColorSchema(const ASchema: TACLColorSchema);
begin
  acApplyColorSchemaForPublishedProperties(Self, ASchema);
end;

procedure TACLCustomControl.Localize;
begin
  LangApplyTo(Copy(LangSection, 1, acLastDelimiter('.', LangSection)), Self);
end;

procedure TACLCustomControl.Localize(const ASection: UnicodeString);
begin
  FLangSection := ASection;
end;

procedure TACLCustomControl.DrawBackground(DC: HDC; const R: TRect);
var
  ACanvas: TCanvas;
  AStyle: TACLControlBackgroundStyle;
begin
  AStyle := GetBackgroundStyle;
  if AStyle <> cbsOpaque then
    DrawTransparentBackground(DC, R);
  if AStyle <> cbsTransparent then
  begin
    ACanvas := TCanvas.Create;
    try
      ACanvas.Lock;
      ACanvas.Handle := DC;
      DrawOpaqueBackground(ACanvas, R);
      ACanvas.Handle := 0;
      ACanvas.Unlock;
    finally
      ACanvas.Free;
    end;
  end;
end;

procedure TACLCustomControl.DoFullRefresh;
begin
  // do nothing
end;

procedure TACLCustomControl.DoGetHint(const P: TPoint; var AHint: string);
begin
  if Assigned(OnGetHint) then
    OnGetHint(Self, P.X, P.Y, AHint);
end;

procedure TACLCustomControl.DoLoaded;
begin
  // do nothing
end;

procedure TACLCustomControl.DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect);
begin
  acFillRect(ACanvas.Handle, R, Color);
end;

procedure TACLCustomControl.DrawTransparentBackground(DC: HDC; const R: TRect);
begin
  acDrawTransparentControlBackground(Self, DC, ClientRect, False)
end;

procedure TACLCustomControl.FocusChanged;
begin
  // do nothing
end;

function TACLCustomControl.IsMarginsStored: Boolean;
begin
  Result := Margins.IsStored;
end;

function TACLCustomControl.IsMouseAtControl: Boolean;
var
  P: TPoint;
begin
  if HandleAllocated and IsWindowVisible(Handle) then
  begin
    P := CalcCursorPos;
    Result := PtInRect(ClientRect, P) and (Perform(CM_HITTEST, 0, PointToLParam(P)) <> 0);
  end
  else
    Result := False;
end;

procedure TACLCustomControl.Loaded;
begin
  inherited Loaded;
  DoLoaded;
  FullRefresh;
end;

procedure TACLCustomControl.MouseEnter;
begin
  FIsHovered := True;
  UpdateCursor;
end;

procedure TACLCustomControl.MouseLeave;
begin
  FIsHovered := False;
end;

procedure TACLCustomControl.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  if Operation = opRemove then
  begin
    if AComponent = ResourceCollection then
      ResourceCollection := nil;
  end;
end;

procedure TACLCustomControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
begin
  if FocusOnClick then
    SetFocusOnClick;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TACLCustomControl.PaintWindow(DC: HDC);
begin
  DrawBackground(DC, ClientRect);
  inherited PaintWindow(DC);
end;

procedure TACLCustomControl.Resize;
begin
  inherited Resize;
  if not IsDestroying then
    BoundsChanged;
end;

procedure TACLCustomControl.SetDefaultSize;
begin
  // do nothing
end;

procedure TACLCustomControl.SetFocusOnClick;
begin
  SetFocus;
end;

procedure TACLCustomControl.SetMargins(const Value: TACLMargins);
begin
  Margins.Assign(Value);
end;

procedure TACLCustomControl.SetParent(AParent: TWinControl);
begin
  if TACLControlsHelper.CanSetParent(Self, AParent) then
  begin
    inherited SetParent(AParent);
    TACLControlsHelper.UpdateScaleFactorOnParentChange(Self);
  end;
end;

procedure TACLCustomControl.SetTargetDPI(AValue: Integer);
begin
  // do nothing
end;

function TACLCustomControl.GetCollection: TACLCustomResourceCollection;
begin
  Result := ResourceCollection;
end;

procedure TACLCustomControl.ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
begin
  if Sender = ResourceCollection then
    ResourceCollectionChanged;
  ResourceChanged;
end;

procedure TACLCustomControl.ResourceChanged;
begin
  if not IsDestroying then
  begin
    UpdateTransparency;
    FullRefresh;
    Realign;
  end;
end;

procedure TACLCustomControl.ResourceCollectionChanged;
begin
  TACLStyle.Refresh(Self);
end;

procedure TACLCustomControl.UpdateCursor;
begin
  if IsHovered then
    Perform(WM_SETCURSOR, Handle, HTCLIENT);
end;

procedure TACLCustomControl.UpdateTransparency;
begin
  if GetBackgroundStyle = cbsOpaque then
    ControlStyle := ControlStyle + [csOpaque]
  else
    ControlStyle := ControlStyle - [csOpaque];

  if HandleAllocated then
    Invalidate;
end;

procedure TACLCustomControl.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
  UpdateCursor;
end;

procedure TACLCustomControl.CMFontChanged(var Message: TMessage);
begin
  inherited;
  ResourceChanged;
end;

procedure TACLCustomControl.CMHintShow(var Message: TCMHintShow);
begin
  inherited;
  if Message.HintInfo^.HintWindowClass = THintWindow then
    Message.HintInfo^.HintWindowClass := TACLHintWindow;
  DoGetHint(Message.HintInfo.CursorPos, Message.HintInfo.HintStr);
end;

procedure TACLCustomControl.WMPaint(var Message: TWMPaint);
var
  AClipRgn: HRGN;
  AMemBmp: HBITMAP;
  AMemDC: HDC;
  APaintStruct: TPaintStruct;
  APaintBuffer: HPAINTBUFFER;
begin
  if (Message.DC <> 0) or not DoubleBuffered then
    PaintHandler(Message)
  else
    if DwmCompositionEnabled and AllowCompositionPainting then
    begin
      BeginPaint(Handle, APaintStruct);
      try
        APaintBuffer := BeginBufferedPaint(APaintStruct.hdc, APaintStruct.rcPaint, BPBF_COMPOSITED, nil, AMemDC);
        if APaintBuffer <> 0 then
        try
          Perform(WM_ERASEBKGND, AMemDC, AMemDC);
          Perform(WM_PRINTCLIENT, AMemDC, PRF_CLIENT);
          if not (csPaintBlackOpaqueOnGlass in ControlStyle) then
            BufferedPaintMakeOpaque(APaintBuffer, APaintStruct.rcPaint);
        finally
          EndBufferedPaint(APaintBuffer, True);
        end;
      finally
        EndPaint(Handle, APaintStruct);
      end;
    end
    else
    begin
      BeginPaint(Handle, APaintStruct);
      try
        AMemDC := acCreateMemDC(APaintStruct.hdc, APaintStruct.rcPaint, AMemBmp, AClipRgn);
        try
          acBitBlt(AMemDC, APaintStruct.hdc, APaintStruct.rcPaint, APaintStruct.rcPaint.TopLeft);
          Message.DC := AMemDC;
          Perform(WM_PAINT, Message.DC, 0);
          Message.DC := 0;
          acBitBlt(APaintStruct.hdc, AMemDC, APaintStruct.rcPaint, APaintStruct.rcPaint.TopLeft);
        finally
          acDeleteMemDC(AMemDC, AMemBmp, AClipRgn);
        end;
      finally
        EndPaint(Handle, APaintStruct);
      end;
    end;
end;

procedure TACLCustomControl.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  FocusChanged;
end;

procedure TACLCustomControl.WMSize(var Message: TWMSize);
begin
  // для корректной работы anchor-ов при смене dpi
  if not IsDestroying then
  begin
    UpdateBounds;
    BoundsChanged;
  end;

  inherited;

  if Parent <> nil then
  begin
    if TWinControlAccess(Parent).AutoSize then
      TWinControlAccess(Parent).AdjustSize;
  end;
end;

procedure TACLCustomControl.WndProc(var Message: TMessage);
begin
  if not TACLControlsHelper.ProcessMessage(Self, Message) then
    inherited WndProc(Message);
end;

procedure TACLCustomControl.CMScaleChanging(var Message: TMessage);
begin
  Inc(FScaleChangeCount);
  if FScaleChangeCount = 1 then
    TACLControlsHelper.ScaleChanging(Self, FScaleChangeState);
end;

procedure TACLCustomControl.CMScaleChanged(var Message: TMessage);
begin
  Dec(FScaleChangeCount);
  if FScaleChangeCount = 0 then
    TACLControlsHelper.ScaleChanged(Self, FScaleChangeState);
{$IFDEF DEBUG}
  if FScaleChangeCount < 0 then
    raise EInvalidOperation.Create(ClassName);
{$ENDIF}
end;

procedure TACLCustomControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TACLCustomControl.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  FocusChanged;
end;

procedure TACLCustomControl.WMMouseMove(var Message: TWMMouseMove);
begin
  MouseTracker.Add(Self);
  inherited;
end;

procedure TACLCustomControl.WMMouseWheelHorz(var Message: TWMMouseWheel);
begin
  with TMessage(TACLMouseWheel.HWheelToVWheel(Message)) do
    Message.Result := Perform(WM_MOUSEWHEEL, WParam, LParam);
end;

procedure TACLCustomControl.AdjustClientRect(var ARect: TRect);
begin
  inherited AdjustClientRect(ARect);
  ARect := acRectContent(ARect, GetContentOffset);
  ARect := acRectContent(ARect, Padding.GetScaledMargins(ScaleFactor));
end;

procedure TACLCustomControl.AdjustSize;
begin
  SetBounds(Left, Top, Width, Height);
  inherited AdjustSize;
end;

function TACLCustomControl.AllowCompositionPainting: Boolean;
begin
  Result := True;
end;

procedure TACLCustomControl.BoundsChanged;
begin
  // do nothing
end;

procedure TACLCustomControl.ScaleForPPI(NewPPI: Integer);
begin
  Perform(CM_SCALECHANGING, 0, 0);
  try
    inherited ScaleForPPI(NewPPI);
  finally
    Perform(CM_SCALECHANGED, 0, 0);
  end;
end;

procedure TACLCustomControl.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  Perform(CM_SCALECHANGING, 0, 0);
  try
    ScaleFactor.Change(M, D);
    inherited ChangeScale(M, D, isDpiChange);
    SetTargetDPI(ScaleFactor.TargetDPI);
    MarginsChangeHandler(nil);
  finally
    Perform(CM_SCALECHANGED, 0, 0);
  end;
end;

function TACLCustomControl.CreatePadding: TACLPadding;
begin
  Result := TACLPadding.Create(0);
end;

function TACLCustomControl.GetClientRect: TRect;
begin
  if HandleAllocated then
    Result := inherited GetClientRect
  else
    Result := Bounds(0, 0, Width, Height);
end;

function TACLCustomControl.GetContentOffset: TRect;
begin
  Result := NullRect;
end;

function TACLCustomControl.GetCursor(const P: TPoint): TCursor;
begin
  Result := Cursor;
end;

function TACLCustomControl.GetIsDesigning: Boolean;
begin
  Result := csDesigning in ComponentState;
end;

function TACLCustomControl.GetIsDestroying: Boolean;
begin
  Result := csDestroying in ComponentState;
end;

function TACLCustomControl.GetIsLoading: Boolean;
begin
  Result := csLoading in ComponentState;
end;

function TACLCustomControl.GetLangSection: UnicodeString;
begin
  if FLangSection = '' then
    FLangSection := LangGetComponentPath(Self);
  Result := FLangSection;
end;

function TACLCustomControl.GetScaleFactor: TACLScaleFactor;
begin
  Result := ScaleFactor;
end;

function TACLCustomControl.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if Transparent then
    Result := cbsTransparent
  else
    Result := cbsOpaque;
end;

function TACLCustomControl.IsPaddingStored: Boolean;
begin
  Result := Padding.IsStored;
end;

procedure TACLCustomControl.SetPadding(const Value: TACLPadding);
begin
  Padding.Assign(Value);
end;

procedure TACLCustomControl.SetResourceCollection(AValue: TACLCustomResourceCollection);
begin
  if acResourceCollectionFieldSet(FResourceCollection, Self, Self, AValue) then
    ResourceChanged(ResourceCollection);
end;

procedure TACLCustomControl.SetTransparent(AValue: Boolean);
begin
  if AValue <> FTransparent then
  begin
    FTransparent := AValue;
    UpdateTransparency;
  end;
end;

procedure TACLCustomControl.MarginsChangeHandler(Sender: TObject);
begin
  DisableAlign;
  try
    acRectToMargins(Margins.GetScaledMargins(ScaleFactor), inherited Margins);
  finally
    EnableAlign;
  end;
end;

procedure TACLCustomControl.PaddingChangeHandler(Sender: TObject);
begin
  ResourceChanged;
end;

{ TACLContainer }

constructor TACLContainer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBorders := acAllBorders;
  FStyle := CreateStyle;
end;

destructor TACLContainer.Destroy;
begin
  FreeAndNil(FStyle);
  inherited Destroy;
end;

function TACLContainer.CreateStyle: TACLStyleBackground;
begin
  Result := TACLStyleBackground.Create(Self);
end;

procedure TACLContainer.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Style.SetTargetDPI(AValue);
end;

function TACLContainer.GetContentOffset: TRect;
begin
  Result := acMarginGetReal(acBorderOffsets, Borders);
end;

function TACLContainer.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if Transparent then
    Result := cbsTransparent
  else if Style.IsTransparentBackground then
    Result := cbsSemitransparent
  else
    Result := cbsOpaque;
end;

procedure TACLContainer.DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.DrawContent(ACanvas, R);
end;

procedure TACLContainer.Paint;
begin
  Style.DrawBorder(Canvas, ClientRect, Borders);
end;

procedure TACLContainer.SetBorders(AValue: TACLBorders);
begin
  if AValue <> FBorders then
  begin
    FBorders := AValue;
    AdjustSize;
    Realign;
    Invalidate;
  end;
end;

procedure TACLContainer.SetStyle(const Value: TACLStyleBackground);
begin
  FStyle.Assign(Value);
end;

{ TACLMouseWheel }

class constructor TACLMouseWheel.Create;
begin
  ScrollLines := DefaultScrollLines;
  ScrollLinesAlt := DefaultScrollLinesAlt;
  ScrollLinesCtrl := DefaultScrollLinesCtrl;
end;

class function TACLMouseWheel.GetDirection(AValue: Integer): TACLMouseWheelDirection;
begin
  if AValue < 0 then
    Result := mwdUp
  else
    Result := mwdDown;
end;

class function TACLMouseWheel.GetScrollLines(AState: TShiftState): Integer;
begin
  if ssCtrl in AState then
    Result := ScrollLinesCtrl
  else if ssAlt in AState then
    Result := ScrollLinesAlt
  else
    Result := ScrollLines;

  if Result <= 0 then
    Result := Mouse.WheelScrollLines;
end;

class function TACLMouseWheel.HWheelToVWheel(const AMessage: TWMMouseWheel): TWMMouseWheel;
begin
  Result := AMessage;
  Result.Keys := Result.Keys or MK_SHIFT;
  Result.WheelDelta := -Result.WheelDelta;
end;

{ TACLDeferPlacementUpdate }

procedure TACLDeferPlacementUpdate.Add(AControl: TWinControl; const ABounds: TRect);
begin
  FDictionary.AddOrSetValue(AControl, ABounds);
end;

procedure TACLDeferPlacementUpdate.Add(AControl: TWinControl; ALeft, ATop, AWidth, AHeight: Integer);
begin
  Add(AControl, System.Classes.Bounds(ALeft, ATop, AWidth, AHeight));
end;

procedure TACLDeferPlacementUpdate.BeginUpdate;
begin
  FDictionary := TACLDictionary<TWinControl, TRect>.Create;
end;

procedure TACLDeferPlacementUpdate.EndUpdate;
var
  AHandle: THandle;
begin
  if FDictionary.Count > 0 then
  begin
    AHandle := BeginDeferWindowPos(FDictionary.Count);
    try
      FDictionary.Enum(
        procedure (const AControl: TWinControl; const R: TRect)
        begin
          DeferWindowPos(AHandle, AControl.Handle, 0, R.Left, R.Top, R.Width, R.Height, SWP_NOZORDER);
        end);
    finally
      EndDeferWindowPos(AHandle)
    end;
  end;
  FreeAndNil(FDictionary);
end;

function TACLDeferPlacementUpdate.GetBounds(AControl: TWinControl): TRect;
begin
  Result := FDictionary[AControl];
end;

{ TACLSubControlOptions }

constructor TACLSubControlOptions.Create(AOwner: TControl);
begin
  FOwner := AOwner;
  FPosition := mRight;
end;

destructor TACLSubControlOptions.Destroy;
begin
  Control := nil;
  TACLMainThread.Unsubscribe(Self);
  inherited;
end;

procedure TACLSubControlOptions.Assign(Source: TPersistent);
begin
  if Source is TACLSubControlOptions then
  begin
    Control := TACLSubControlOptions(Source).Control;
    Position := TACLSubControlOptions(Source).Position;
    Align := TACLSubControlOptions(Source).Align;
  end;
end;

procedure TACLSubControlOptions.Changed;
begin
  if not (csDestroying in FOwner.ComponentState) then
  begin
    TControlAccess(FOwner).AdjustSize;
    TControlAccess(FOwner).Resize;
    TControlAccess(FOwner).Invalidate;
  end;
end;

procedure TACLSubControlOptions.WindowProc(var Message: TMessage);
var
  AWindowPos: PWindowPos;
begin
  if Message.Msg = WM_WINDOWPOSCHANGED then
  begin
    AWindowPos := TWMWindowPosMsg(Message).WindowPos;
    if (AWindowPos = nil) or (AWindowPos^.flags and (SWP_NOMOVE or SWP_NOSIZE) <> (SWP_NOMOVE or SWP_NOSIZE)) then
    begin
      if not (csAligning in Control.ControlState) then
        TACLMainThread.RunPostponed(Changed, Self);
    end;
  end;
  FPrevWndProc(Message);
end;

procedure TACLSubControlOptions.AlignControl(var AClientRect: TRect);
var
  ABounds: TRect;
begin
  if Validate then
  begin
    ABounds := acRectOffset(AClientRect, FOwner.Left, FOwner.Top);
    case Position of
      mLeft:
        begin
          ABounds := acRectSetWidth(ABounds, Control.ExplicitWidth);
          if Align <> acTrue then
            ABounds := acRectCenterVertically(ABounds, Control.ExplicitHeight);
          Inc(AClientRect.Left, GetActualIndentBetweenElements);
          Inc(AClientRect.Left, Control.ExplicitWidth);
        end;

      mRight:
        begin
          ABounds := acRectSetRight(ABounds, ABounds.Right, Control.ExplicitWidth);
          if Align <> acTrue then
            ABounds := acRectCenterVertically(ABounds, Control.ExplicitHeight);
          Dec(AClientRect.Right, GetActualIndentBetweenElements);
          Dec(AClientRect.Right, Control.ExplicitWidth);
        end;

      mTop:
        begin
          ABounds := acRectSetHeight(ABounds, Control.ExplicitHeight);
          if Align = acFalse then
            ABounds := acRectSetWidth(ABounds, Control.ExplicitWidth);
          Inc(AClientRect.Top, GetActualIndentBetweenElements);
          Inc(AClientRect.Top, Control.ExplicitHeight);
        end;

      mBottom:
        begin
          ABounds := acRectSetBottom(ABounds, ABounds.Bottom, Control.ExplicitHeight);
          if Align = acFalse then
            ABounds := acRectSetWidth(ABounds, Control.ExplicitWidth);
          Dec(AClientRect.Bottom, GetActualIndentBetweenElements);
          Dec(AClientRect.Bottom, Control.ExplicitHeight);
        end;
    end;

    Control.ControlState := Control.ControlState + [csAligning];
    try
      Control.BoundsRect := ABounds;
    finally
      Control.ControlState := Control.ControlState - [csAligning];
    end;
  end;
end;

procedure TACLSubControlOptions.AfterAutoSize(var AWidth, AHeight: Integer);
begin
  if Validate then
  begin
    if Position in [mRight, mLeft] then
    begin
      AHeight := Max(AHeight, Control.ExplicitHeight);
      Inc(AWidth, GetActualIndentBetweenElements);
      Inc(AWidth, Control.ExplicitWidth);
    end
    else
    begin
      AWidth := Max(AWidth, Control.ExplicitWidth);
      Inc(AHeight, GetActualIndentBetweenElements);
      Inc(AHeight, Control.ExplicitHeight);
    end;
  end;
end;

procedure TACLSubControlOptions.BeforeAutoSize(var AWidth, AHeight: Integer);
begin
  if Validate then
  begin
    if Position in [mRight, mLeft] then
    begin
      Dec(AWidth, GetActualIndentBetweenElements);
      Dec(AWidth, Control.ExplicitWidth);
    end
    else
    begin
      Dec(AHeight, GetActualIndentBetweenElements);
      Dec(AHeight, Control.ExplicitHeight);
    end;
  end;
end;

procedure TACLSubControlOptions.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  if AComponent = Control then
    Control := nil;
end;

function TACLSubControlOptions.TrySetFocus: Boolean;
begin
  Result := (Control is TWinControl) and TWinControlAccess(Control).CanFocus;
  if Result then
    TWinControlAccess(Control).SetFocus;  
end;

function TACLSubControlOptions.GetActualIndentBetweenElements: Integer;
begin
  if Position in [mRight, mLeft] then
    Result := acGetScaleFactor(FOwner).Apply(acIndentBetweenElements)
  else
    Result := acGetScaleFactor(FOwner).Apply(2);
end;

function TACLSubControlOptions.Validate: Boolean;
begin
  if (Control <> nil) and (Control.Parent <> FOwner.Parent) then
    Control := nil;
  if (Control <> nil) and (Control.Align <> alNone) then
    Control.Align := alNone; // alCustom disables auto-size feature
  if (Control <> nil) and (Control.AlignWithMargins) then
    Control.AlignWithMargins := False;
  Result := Control <> nil;
end;

procedure TACLSubControlOptions.SetAlign(AValue: TACLBoolean);
begin
  if Align <> AValue then
  begin
    FAlign := AValue;
    if Control <> nil then
      Changed;
  end;
end;

procedure TACLSubControlOptions.SetControl(AValue: TControl);
const
  sErrorUnsupportedControl = 'The control cannot be set as sub-control';
begin
  if FControl <> AValue then
  try
    if acIsChild(AValue, FOwner) then
      raise EInvalidArgument.Create(sErrorUnsupportedControl);
    if FControl <> nil then
    begin
      FControl.RemoveFreeNotification(FOwner);
      FControl.WindowProc := FPrevWndProc;
      FControl := nil;
    end;
    if AValue <> nil then
    begin
      FControl := AValue;
      FPrevWndProc := FControl.WindowProc;
      FControl.Parent := FOwner.Parent;
      if Validate then
      begin
        FControl.WindowProc := WindowProc;
        FControl.FreeNotification(FOwner);
        FControl.BringToFront;
      end
      else
        raise EInvalidArgument.Create(sErrorUnsupportedControl);
    end;
    Changed;
  except
    Control := nil;
    raise;
  end;
end;

procedure TACLSubControlOptions.SetPosition(AValue: TACLBorder);
begin
  if FPosition <> AValue then
  begin
    FPosition := AValue;
    if Control <> nil then
      Changed;
  end;
end;

initialization

finalization
  FreeAndNil(FMouseTracker);
end.
