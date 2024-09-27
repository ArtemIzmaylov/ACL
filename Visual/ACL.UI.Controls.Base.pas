////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Base classes for controls
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.Base;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
  LMessages,
  LResources,
{$ELSE}
  Winapi.DwmApi,
  Winapi.Windows,
  Winapi.UxTheme,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Generics.Defaults,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  {System.}TypInfo,
  System.UITypes,
  // Vcl
  {Vcl.}ActnList,
  {Vcl.}Controls,
  {Vcl.}ExtCtrls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Timers,
  ACL.UI.Animation,
  ACL.UI.Application,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.FileSystem;

const
  CM_SCALECHANGING = $BF00;
  CM_SCALECHANGED  = $BF01;

{$IFDEF FPC}
  GetCaretBlinkTime = 500;

  CS_DROPSHADOW  = 0;
  CM_CANCELMODE  = LMessages.{%H-}CM_CANCELMODE;
  WM_ACTIVATEAPP = $001C;
  WM_CONTEXTMENU = LM_CONTEXTMENU;
  WM_MOUSEWHEEL  = LM_MOUSEWHEEL;
  WM_MOUSEHWHEEL = LM_MOUSEHWHEEL;
  WM_MOVE        = LM_MOVE;
  WM_NCCALCSIZE  = LM_NCCALCSIZE;
  WM_MOUSEFIRST  = LM_MOUSEFIRST;
  WM_MOUSELAST   = LM_MOUSELAST;
  WM_DESTROY     = LM_DESTROY;

  csAligning     = csCreating; // просто потому, что оно в LCL не используется

type
  TGestureEventInfo = record
    {stub}
  end;
  TWMContextMenu = TLMContextMenu;
  TWMMouseWheel = TCMMouseWheel;
{$ENDIF}

const
  acIndentBetweenElements = 5;
  acResizeHitTestAreaSize = 6;

const
  acAnchorTop = [akLeft, akTop, akRight];
  acAnchorClient = [akLeft, akTop, akRight, akBottom];
  acAnchorBottomLeft = [akLeft, akBottom];
  acAnchorBottomRight = [akRight, akBottom];

type
{$REGION ' General Types '}

  TTabOrderList = {$IFDEF FPC}TFPList{$ELSE}TList{$ENDIF};
  TWideKeyEvent = procedure(var Key: WideChar) of object;

  TACLOrientation = (oHorizontal, oVertical);
  TACLControlActionType = (ccatNone, ccatMouse, ccatGesture, ccatKeyboard);
  TACLSelectionMode = (smUnselect, smSelect, smInvert);

  TACLCustomDrawEvent = procedure (Sender: TObject;
    ACanvas: TCanvas; const R: TRect; var AHandled: Boolean) of object;
  TACLKeyPreviewEvent = procedure (AKey: Word;
    AShift: TShiftState; var AAccept: Boolean) of object;
  TACLGetHintEvent = procedure (Sender: TObject; X, Y: Integer; var AHint: string) of object;

  { IACLControl }

  IACLControl = interface(IACLCurrentDPI)
  ['{D41EBD0F-D2EE-4517-AD7E-EEE8FC0ACFD4}']
    function GetEnabled: Boolean;
    procedure InvalidateRect(const R: TRect);
    procedure Update;

    function ClientToScreen(const P: TPoint): TPoint;
    function ScreenToClient(const P: TPoint): TPoint;
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

  { IACLPopup }

  IACLPopup = interface
  ['{EDDF3E8C-C4DA-4AE7-9CED-78F068DDB8AE}']
    procedure PopupUnderControl(const ControlRect: TRect);
  end;

{$ENDREGION}

{$REGION ' In-placing '}

  { IACLInnerControl }

  IACLInnerControl = interface
  ['{8F98096E-7A0D-4D77-82AB-B9724B3C6596}']
    function GetInnerContainer: TWinControl;
  end;

  { IACLInplaceControl }

  IACLInplaceControl = interface
  ['{494D7949-6E70-6C61-6365-436F6E74726F}']
    function InplaceGetValue: string;
    function InplaceIsFocused: Boolean;
    procedure InplaceSetFocus;
    procedure InplaceSetValue(const AValue: string);
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

{$ENDREGION}

{$REGION ' Positioning '}

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
  public
    constructor Create(ADefaultValue: Integer);
    procedure Assign(Source: TPersistent); override;
    function GetScaledMargins(ATargetDpi: Integer): TRect;
    // Properties
    property Margins: TRect read GetMargins write SetMargins;
    // Events
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
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
    procedure UpdateVisibility; virtual;
    //# Properties
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

  { TACLDeferPlacementUpdate }

  TACLDeferPlacementUpdate = class
  strict private
    FBounds: TACLDictionary<TControl, TRect>;
    function GetBounds(AControl: TControl): TRect;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(AControl: TControl; ALeft, ATop, AWidth, AHeight: Integer); overload;
    procedure Add(AControl: TControl; const ABounds: TRect); overload;
    procedure Apply;
    property Bounds[AControl: TControl]: TRect read GetBounds;
  end;

  { TACLOrderedAlign }

  TACLOrderedAlign = class
  strict private const
    AlignWeightMap: array[TAlign] of Integer = (
      5{alNone}, 0{alTop}, 1{alBottom}, 2{alLeft}, 3{alRight}, 4{alClient}, 6{alCustom}
    );
  strict private
    class var FWorkInfo: TAlignInfo;
    class var FWorkList: TTabOrderList;
    class function Compare(const L, R: TControl): Integer; static;
  public
    class destructor Destroy;
    class procedure Apply(AParent: TWinControl; var ARect: TRect);
    class procedure List(AParent: TWinControl; AAlignSet: TAlignSet; AList: TTabOrderList);
    class function GetOrder(AControl: TControl): Integer; static; inline;
    class procedure SetOrder(AControl: TControl; AOrder: Integer); static; inline;
  end;

{$ENDREGION}

{$REGION ' Styles '}

  { TACLStyleBackground }

  TACLStyleBackground = class(TACLStyle)
  protected
    procedure InitializeResources; override;
  public
    procedure Draw(ACanvas: TCanvas; const R: TRect; ATransparent: Boolean; ABorders: TACLBorders);
    procedure DrawBorder(ACanvas: TCanvas; const R: TRect; ABorders: TACLBorders);
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

{$ENDREGION}

{$REGION ' Mouse Tracker '}

  { IACLMouseTracking }

  IACLMouseTracking = interface
  ['{38A56452-B7C5-4B72-B872-84BAC2163EC7}']
    function IsMouseAtControl: Boolean;
    procedure MouseEnter;
    procedure MouseLeave;
  end;

  { TACLMouseTracker }

  TACLMouseTracker = class(TACLTimerList<IACLMouseTracking>)
  strict private
    class var FInstance: TACLMouseTracker;
    class function Get: TACLMouseTracker;
  protected
    procedure DoAdding(const AObject: IACLMouseTracking); override;
    procedure TimerObject(const AObject: IACLMouseTracking); override;
  public
    class destructor Destroy;
    class procedure Release(const AIntf: IACLMouseTracking); overload;
    class procedure Release(const AObj: TObject); overload;
    class procedure Start(const AIntf: IACLMouseTracking);
  end;

  { TACLMouseWheelDirection }

  TACLMouseWheelDirection =
  (
    mwdDown, // Scroll the mouse wheel down (to yourself),
             // the list must be scrolled to next item. equals to LB_LINEDOWN.
    mwdUp    // Scroll the mouse wheel up (from yourself),
             // the list must be scrolled to previous item. equals to LB_LINEUP.
  );

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

{$ENDREGION}

{$REGION ' Controls '}

  { TACLGraphicControl }

  TACLGraphicControl = class(TGraphicControl,
    IACLColorSchema,
    IACLControl,
    IACLCurrentDpi,
    IACLMouseTracking,
    IACLObjectLinksSupport,
    IACLResourceChangeListener,
    IACLResourceCollection)
  strict private
    FAlignOrder: Integer;
    FMargins: TACLMargins;
    FMouseInControl: Boolean;
    FResourceCollection: TACLCustomResourceCollection;

    FOnBoundsChanged: TNotifyEvent;
    FOnGetHint: TACLGetHintEvent;
    FOnMouseEnter: TNotifyEvent;
    FOnMouseLeave: TNotifyEvent;

    function IsMarginsStored: Boolean;
    procedure MarginsChangeHandler(Sender: TObject);
    procedure SetAlignOrder(AValue: Integer);
    procedure SetMargins(const Value: TACLMargins);
    procedure SetResourceCollection(AValue: TACLCustomResourceCollection);
  {$IFDEF FPC}
  strict private
    FAlignWithMargins: Boolean;
    procedure SetAlignWithMargins(AValue: Boolean);
  {$ENDIF}
  protected
    FDefaultSize: TSize;
  {$IFDEF FPC}
    FCurrentPPI: Integer;

    procedure CalculatePreferredSize(var W, H: Integer; X: Boolean); override;
    procedure DoAutoAdjustLayout(const AMode: TLayoutAdjustmentPolicy; const X, Y: Double); override;
  {$ELSE}
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override; final;
  {$ENDIF}
    procedure DoGetHint(const P: TPoint; var AHint: string); virtual;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure SetTargetDPI(AValue: Integer); virtual;
    procedure UpdateTransparency; virtual;

    // IACLCurrentDpi
    function GetCurrentDpi: Integer;
    // IACLMouseTracking
    function IsMouseAtControl: Boolean; virtual;
    procedure MouseEnter; reintroduce; virtual;
    procedure MouseLeave; reintroduce; virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    // IACLResourcesChangeListener
    procedure ResourceChanged(Sender: TObject; Resource: TACLResource = nil); overload;
    procedure ResourceChanged; overload; virtual;
    procedure ResourceCollectionChanged; virtual;
    // IACLResourceCollection
    function GetCollection: TACLCustomResourceCollection;

    // Messages
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    // Mouse
    property MouseInControl: Boolean read FMouseInControl;
    property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseLeave: TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
    //# Resources
    property ResourceCollection: TACLCustomResourceCollection
      read FResourceCollection write SetResourceCollection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdjustSize; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure SetParent(NewParent: TWinControl); override;
    // IACLColorSchema
    procedure ApplyColorSchema(const ASchema: TACLColorSchema); virtual;
    // IACLControl
    procedure InvalidateRect(const R: TRect); virtual;
    // Properties
    property Canvas;
  published
    property Align;
    property AlignOrder: Integer read FAlignOrder write SetAlignOrder default 0;
  {$IFDEF FPC}
    property AlignWithMargins: Boolean read FAlignWithMargins write SetAlignWithMargins default False;
  {$ENDIF}
    property Anchors;
    property Enabled;
    property Hint;
    property Margins: TACLMargins read FMargins write SetMargins stored IsMarginsStored;
    property Visible;
    // Events
    property OnBoundsChanged: TNotifyEvent read FOnBoundsChanged write FOnBoundsChanged;
    property OnGetHint: TACLGetHintEvent read FOnGetHint write FOnGetHint;
  end;

  { TCustomScalableControl }

  TCustomScalableControl = class(TCustomControl, IACLCurrentDpi)
  protected
    // IACLCurrentDpi
    function GetCurrentDpi: Integer;
    // TControl
    procedure SetParent(NewParent: TWinControl); override;
  {$IFDEF FPC}
  protected
    FCurrentPPI: Integer;
    procedure ChangeScale(M, D: Integer); overload; override; final;
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); overload; virtual;
    procedure DoAutoAdjustLayout(const AMode: TLayoutAdjustmentPolicy; const X, Y: Double); override;
  public
    constructor Create(AOwner: TComponent); override;
  {$ENDIF}
  public
    procedure ScaleForPPI(NewPPI: Integer); {$IFNDEF FPC}override;{$ENDIF}
    class procedure ScaleOnSetParent(ACaller: TControl);
  end;

  { TACLCustomControl }

  TACLCustomControlClass = class of TACLCustomControl;
  TACLCustomControl = class(TCustomScalableControl,
    IACLColorSchema,
    IACLControl,
    IACLFocusableControl,
    IACLLocalizableComponent,
    IACLMouseTracking,
    IACLObjectLinksSupport,
    IACLResourceChangeListener,
    IACLResourceCollection)
  strict private
    FAlignOrder: Integer;
    FFocusOnClick: Boolean;
    FLangSection: string;
    FMargins: TACLMargins;
    FMouseInClient: Boolean;
    FPadding: TACLPadding;
    FResourceCollection: TACLCustomResourceCollection;
    FScaleChangeCount: Integer;
    FScaleChangeState: TObject;
    FTransparent: Boolean;

    FOnGetHint: TACLGetHintEvent;

    function GetLangSection: string;
    function IsMarginsStored: Boolean;
    function IsPaddingStored: Boolean;
    procedure SetAlignOrder(AValue: Integer);
    procedure SetMargins(const Value: TACLMargins);
    procedure SetPadding(const Value: TACLPadding);
    procedure SetResourceCollection(AValue: TACLCustomResourceCollection);
    procedure SetTransparent(AValue: Boolean);
    //# Handlers
    procedure MarginsChangeHandler(Sender: TObject);
    procedure PaddingChangeHandler(Sender: TObject);
    //# Messages
    procedure CMDialogChar(var Message: TCMDialogChar); message {%H-}CM_DIALOGCHAR;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMScaleChanged(var Message: TMessage); message CM_SCALECHANGED;
    procedure CMScaleChanging(var Message: TMessage); message CM_SCALECHANGING;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMLButtonDown(var Message: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMMouseMove(var Message: TWMMouseMove); message WM_MOUSEMOVE;
    procedure WMMouseWheelHorz(var Message: TWMMouseWheel); message WM_MOUSEHWHEEL;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  {$IFDEF FPC}
  strict private
    FAlignWithMargins: Boolean;
    procedure SetAlignWithMargins(AValue: Boolean);
  {$ENDIF}
  protected
    FDefaultSize: TSize;
    FRedrawOnResize: Boolean;

    procedure AdjustClientRect(var ARect: TRect); override;
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure BoundsChanged; {$IFDEF FPC}override;{$ELSE}virtual;{$ENDIF}
  {$IFDEF FPC}
    procedure CalculatePreferredSize(var W, H: Integer; X: Boolean); override; final;
    function DoAlignChildControls(AAlign: TAlign; AControl: TControl;
      AList: TTabOrderList; var ARect: TRect): Boolean; override;
    procedure InitializeWnd; override;
  {$ENDIF}
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    function CreatePadding: TACLPadding; virtual;
    function DialogChar(var Message: TWMKey): Boolean; {$IFDEF FPC}override;{$ELSE}virtual;{$ENDIF}
    function IsInScaling: Boolean;
    function GetClientRect: TRect; override;
    function GetContentOffset: TRect; virtual;
    procedure DoFullRefresh; virtual;
    procedure DoGetHint(const P: TPoint; var AHint: string); virtual;
    procedure DoLoaded; virtual;
    procedure FocusChanged; virtual;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure PaintWindow(DC: HDC); override;
    procedure Resize; override; final;
    procedure SetFocusOnClick; virtual;
    procedure SetTargetDPI(AValue: Integer); virtual;
    procedure UpdateCursor;
    procedure UpdateTransparency; virtual;
    procedure WndProc(var Message: TMessage); override;

    // IACLMouseTracking
    function IsMouseAtControl: Boolean; virtual;
    procedure MouseEnter; reintroduce; virtual;
    procedure MouseLeave; reintroduce; virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer); override;

    // IACLResourceCollection
    function GetCollection: TACLCustomResourceCollection;

    // IACLResourcesChangeListener
    procedure ResourceChanged(Sender: TObject; Resource: TACLResource = nil); overload;
    procedure ResourceChanged; overload; virtual;
    procedure ResourceCollectionChanged; virtual;

    // Properties
    property FocusOnClick: Boolean read FFocusOnClick write FFocusOnClick default False;
    property LangSection: string read GetLangSection;
    property MouseInClient: Boolean read FMouseInClient;
    property Padding: TACLPadding read FPadding write SetPadding stored IsPaddingStored;
    property ResourceCollection: TACLCustomResourceCollection read FResourceCollection write SetResourceCollection;
    property Transparent: Boolean read FTransparent write SetTransparent default False;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdjustSize; override;
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
    procedure Localize(const ASection: string); overload; virtual;
  published
    property Align;
    property AlignOrder: Integer read FAlignOrder write SetAlignOrder default 0;
  {$IFDEF FPC}
    property AlignWithMargins: Boolean read FAlignWithMargins write SetAlignWithMargins default False;
  {$ENDIF}
    property Anchors;
    property Constraints;
    property DoubleBuffered default False;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property Margins: TACLMargins read FMargins write SetMargins stored IsMarginsStored;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property Visible;
    //# Events
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

  { TACLContainer }

  TAlignControlsEvent = procedure (Sender: TObject; var Rect: TRect) of object;

  TACLContainer = class(TACLCustomControl)
  strict private
    FBorders: TACLBorders;
    FStyle: TACLStyleBackground;
    // Events
    FOnAlignControls: TAlignControlsEvent;

    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure SetBorders(AValue: TACLBorders);
    procedure SetStyle(AValue: TACLStyleBackground);
  protected
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    function CreateStyle: TACLStyleBackground; virtual;
    function GetContentOffset: TRect; override;
    procedure Paint; override;
    procedure SetAutoSize(Value: Boolean); override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateTransparency; override;
    //# Properties
    property Borders: TACLBorders read FBorders write SetBorders default acAllBorders;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ResourceCollection;
    property Style: TACLStyleBackground read FStyle write SetStyle;
    //# Events
    property OnAlignControls: TAlignControlsEvent read FOnAlignControls write FOnAlignControls;
  end;

{$ENDREGION}

{$REGION ' Helpers '}

  { TACLCheckBoxStateHelper }

  TACLCheckBoxStateHelper = record helper for TCheckBoxState
  public
    class function Create(AChecked: Boolean): TCheckBoxState; overload; static;
    class function Create(AHasChecked, AHasUnchecked: Boolean): TCheckBoxState; overload; static;
    class function Create(AValue: TACLBoolean): TCheckBoxState; overload; static;
    function ToBool: TACLBoolean;
  end;

  { TACLControlHelper }

  TACLControlHelper = class helper for TControl
  public
    function BroadcastRecursive(Msg: Cardinal; ParamW: WPARAM; ParamL: LPARAM): LRESULT;
    function CalcCursorPos: TPoint;
  {$IFDEF FPC}
    function ExplicitHeight: Integer;
    function ExplicitWidth: Integer;
    procedure SendCancelMode(Sender: TControl);
  {$ENDIF}
  end;

  { TACLControls }

  TACLControls = class
  strict private
    class procedure UpdateCursor(ACaller: TWinControl; var Message: TWMSetCursor);
  public
    class procedure AlignControl(AControl: TControl; const ABounds: TRect);
    class procedure BufferedPaint(ACaller: TWinControl);
    // Scaling
    class procedure ScaleChanging(AControl: TWinControl; var AState: TObject);
    class procedure ScaleChanged(AControl: TWinControl; var AState: TObject);
    // Margins
    class procedure UpdateMargins(AControl: TControl;
      AUseMargins: Boolean; AMargins: TACLPadding; ACurrentDpi: Integer); overload;
    class procedure UpdateMargins(AControl: TControl; const AMargins: TRect); overload;
    // Messages
    class function WndProc(ACaller: TWinControl; var Message: TMessage): Boolean; inline;
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

{$ENDREGION}

  { TACLScrollToMode }

  {$SCOPEDENUMS ON}
  TACLScrollToMode = (MakeVisible, MakeTop, MakeCenter);
  {$SCOPEDENUMS OFF}

const
  acDefaultUIFadingEnabled = True;

var
  acUIFadingEnabled: Boolean = acDefaultUIFadingEnabled;
  acUIFadingTime: Integer = 200;

function CallCustomDrawEvent(Sender: TObject;
  AEvent: TACLCustomDrawEvent; ACanvas: TCanvas; const R: TRect): Boolean;
function CreateControl(AClass: TControlClass; AParent: TWinControl;
  const R: TRect; AAlign: TAlign = alNone; AAnchors: TAnchors = [akLeft, akTop]): TControl; overload;
procedure CreateControl(out Obj; AClass: TControlClass; AParent: TWinControl;
  const R: TRect; AAlign: TAlign = alNone; AAnchors: TAnchors = [akLeft, akTop]); overload;
function GetElementWidthIncludeOffset(const R: TRect; ATargetDpi: Integer): Integer;

function acCalculateScrollToDelta(
  const AObjectBounds, AAreaBounds: TRect; AScrollToMode: TACLScrollToMode): TPoint; overload;
function acCalculateScrollToDelta(AObjectTopValue, AObjectBottomValue: Integer;
  AAreaTopValue, AAreaBottomValue: Integer; AScrollToMode: TACLScrollToMode): Integer; overload;

procedure acDrawTransparentControlBackground(AControl: TWinControl;
  DC: HDC; R: TRect; APaintWithChildren: Boolean = True);
procedure acInvalidateRect(AControl: TWinControl; const ARect: TRect; AErase: Boolean = True);

function acCanStartDragging(AControl: TWinControl; X, Y: Integer): Boolean; overload;
function acCanStartDragging(const ADeltaX, ADeltaY, ATargetDpi: Integer): Boolean; overload;
function acCanStartDragging(const P0, P1: TPoint; ATargetDpi: Integer): Boolean; overload;
procedure acDesignerSetModified(AInvoker: TPersistent);
function acGetContainer(AControl: TControl): TControl;
function acIsChildOrSelf(AControl, AChildToTest: TControl): Boolean;
function acIsSemitransparentFill(AContentColor1, AContentColor2: TACLResourceColor): Boolean;
function acOpacityToAlphaBlendValue(AOpacity: Integer): Byte;

function acSaveDC(ACanvas: TCanvas): Integer;
procedure acRestoreDC(ACanvas: TCanvas; ASaveIndex: Integer);

function acGetFocus: TWndHandle;
function acRestoreFocus(ASavedFocus: TWndHandle): Boolean;
function acSafeSetFocus(AControl: TWinControl): Boolean;
function acSaveFocus: TWndHandle;
procedure acSetFocus(AWnd: TWndHandle);

// Keyboard
function acGetShiftState: TShiftState;
function acIsAltKeyPressed: Boolean;
function acIsCtrlKeyPressed: Boolean;
function acIsDropDownCommand(Key: Word; Shift: TShiftState): Boolean;
function acIsShiftPressed(ATest, AState: TShiftState): Boolean;
function acShiftStateToKeys(AShift: TShiftState): Word;

{$IFDEF FPC}
function PointToLParam(const P: TPoint): LPARAM;
procedure ProcessUtf8KeyPress(var Key: TUTF8Char; AEvent: TWideKeyEvent);
{$ENDIF}
implementation

uses
{$IF DEFINED(LCLGtk2)}
  ACL.UI.Core.Impl.Gtk2,
{$ELSEIF DEFINED(MSWINDOWS)}
  ACL.UI.Core.Impl.Win32,
{$ENDIF}
  ACL.Threading,
  ACL.UI.HintWindow;

type
  TPersistentAccess = class(TPersistent);
  TControlAccess = class(TControl);
  TWinControlAccess = class(TWinControl);

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

function acShiftStateToKeys(AShift: TShiftState): Word;
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

procedure acDrawTransparentControlBackground(AControl: TWinControl;
  DC: HDC; R: TRect; APaintWithChildren: Boolean = True);

  procedure DrawControl(DC: HDC; AControl: TWinControl);
  begin
    if IsWindowVisible(AControl.Handle) then
    begin
      AControl.ControlState := AControl.ControlState + [csPaintCopy];
      try
        AControl.Perform(WM_ERASEBKGND, DC, DC);
        AControl.Perform(WM_PAINT, DC, 0);
      finally
        AControl.ControlState := AControl.ControlState - [csPaintCopy];
      end;
    end;
  end;

  procedure PaintControlTo(ADrawControl: TWinControl; AOffsetX, AOffsetY: Integer; R: TRect);
  var
    AChildControl: TControl;
    I: Integer;
  begin
    MoveWindowOrg(DC, AOffsetX, AOffsetY);
    try
      if not RectVisible(DC, R) then
        Exit;

      DrawControl(DC, ADrawControl);
      if APaintWithChildren then
      begin
        for I := 0 to ADrawControl.ControlCount - 1 do
        begin
          AChildControl := ADrawControl.Controls[I];
          if (AChildControl = AControl) and AControl.Visible then
            Break;
          if (AChildControl is TWinControl) and AChildControl.Visible then
          begin
            R := AChildControl.BoundsRect;
            R.Offset(-R.Left, -R.Top);
            PaintControlTo(TWinControl(AChildControl),
              AChildControl.Left, AChildControl.Top, R);
          end;
        end;
      end;
    finally
      MoveWindowOrg(DC, -AOffsetX, -AOffsetY);
    end;
  end;

var
  AParentControl: TWinControl;
  ASaveIndex: Integer;
begin
  AParentControl := AControl.Parent;
  if (AParentControl = nil) and (AControl.ParentWindow <> 0) then
  begin
    AParentControl := FindControl(AControl.ParentWindow);
    APaintWithChildren := False;
  end;
  if Assigned(AParentControl) then
  begin
    ASaveIndex := SaveDC(DC);
    try
      acIntersectClipRegion(DC, R);
      R.Offset(AControl.Left, AControl.Top);
      PaintControlTo(AParentControl, -R.Left, -R.Top, R);
    finally
      RestoreDC(DC, ASaveIndex);
    end;
  end;
end;

procedure acInvalidateRect(AControl: TWinControl; const ARect: TRect; AErase: Boolean);
begin
  if AControl.HandleAllocated then
    InvalidateRect(AControl.Handle, {$IFDEF FPC}@{$ENDIF}ARect, AErase);
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
{$IFDEF FPC}
  LDesigner: TIDesigner;
{$ELSE}
  LDesigner: IDesignerNotify;
{$ENDIF}
begin
  if CanSetModified(AInvoker) then
  begin
    LDesigner := FindRootDesigner(AInvoker);
    if LDesigner <> nil then
      LDesigner.Modified;
  end;
end;

function acCalculateScrollToDelta(const AObjectBounds, AAreaBounds: TRect; AScrollToMode: TACLScrollToMode): TPoint;
begin
  Result.X := acCalculateScrollToDelta(AObjectBounds.Left,
    AObjectBounds.Right, AAreaBounds.Left, AAreaBounds.Right, AScrollToMode);
  Result.Y := acCalculateScrollToDelta(AObjectBounds.Top,
    AObjectBounds.Bottom, AAreaBounds.Top, AAreaBounds.Bottom, AScrollToMode);
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

function acCanStartDragging(AControl: TWinControl; X, Y: Integer): Boolean;
begin
  Result := CheckStartDragImpl(AControl, X, Y,
    dpiApply(Mouse.DragThreshold, acGetCurrentDpi(AControl)));
end;

function acCanStartDragging(const ADeltaX, ADeltaY, ATargetDpi: Integer): Boolean;
begin
  Result := Max(Abs(ADeltaX), Abs(ADeltaY)) >= dpiApply(Mouse.DragThreshold, ATargetDpi);
end;

function acCanStartDragging(const P0, P1: TPoint; ATargetDpi: Integer): Boolean;
begin
  Result := acCanStartDragging(P1.X - P0.X, P1.Y - P0.Y, ATargetDpi);
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

function ImageListSize(AImages: TCustomImageList): TSize;
begin
  if AImages <> nil then
    Result := TSize.Create(AImages.Width, AImages.Height)
  else
    Result := NullSize;
end;

function GetElementWidthIncludeOffset(const R: TRect; ATargetDpi: Integer): Integer;
begin
  Result := R.Width;
  if Result > 0 then
    Inc(Result, dpiApply(acIndentBetweenElements, ATargetDpi));
end;

function acIsChildOrSelf(AControl, AChildToTest: TControl): Boolean;
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

function acGetFocus: TWndHandle;
begin
  Result := GetFocus;
end;

function acRestoreFocus(ASavedFocus: TWndHandle): Boolean;
begin
  Result := (ASavedFocus <> 0) and IsWindow(ASavedFocus);
  if Result then
  begin
  {$IFDEF MSWINDOWS}
    var AProcessId: Cardinal;
    GetWindowThreadProcessId(ASavedFocus, @AProcessId);
    if AProcessId <> GetCurrentProcessId then
      SetForegroundWindow(ASavedFocus)
    else
  {$ENDIF}
      SetFocus(ASavedFocus);
  end;
end;

function acSaveDC(ACanvas: TCanvas): Integer;
begin
  Result := SaveDC(ACanvas.Handle);
end;

function acSaveFocus: TWndHandle;
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
    Result := (AControl <> nil) and AControl.CanFocus;
    if Result then
      AControl.SetFocus;
  except
    Result := False;
  end;
end;

procedure acSetFocus(AWnd: TWndHandle);
begin
  SetFocus(AWnd);
end;

function CallCustomDrawEvent(Sender: TObject; AEvent: TACLCustomDrawEvent;
  ACanvas: TCanvas; const R: TRect): Boolean;
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

procedure CreateControl(out Obj; AClass: TControlClass; AParent: TWinControl;
  const R: TRect; AAlign: TAlign = alNone; AAnchors: TAnchors = [akLeft, akTop]);
begin
  TControl(Obj) := CreateControl(AClass, AParent, R, AAlign, AAnchors);
end;

{$IFDEF FPC}
function PointToLParam(const P: TPoint): LPARAM;
begin
  Result := LPARAM((P.X and $0000ffff) or (P.Y shl 16));
end;

procedure ProcessUtf8KeyPress(var Key: TUTF8Char; AEvent: TWideKeyEvent);
var
  LKey: WideChar;
  LStr: UnicodeString;
begin
  LStr := UTF8ToString(Key);
  if Length(LStr) = 1 then
  begin
    LKey := LStr[1];
    AEvent(LKey);
    if LKey <> LStr[1] then
      Key := UTF8Encode(LKey);
  end;
end;
{$ENDIF}

{$REGION ' Positioning '}

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
  {$IFNDEF FPC}
    if Source is TMargins then
    begin
      Left := TMargins(Source).Left;
      Top := TMargins(Source).Top;
      Right := TMargins(Source).Right;
      Bottom := TMargins(Source).Bottom;
    end;
  {$ENDIF}
end;

function TACLPadding.GetScaledMargins(ATargetDpi: Integer): TRect;
var
  AValue: Single;
begin
  if Scalable and (ATargetDpi <> acDefaultDpi) then
  begin
    //#AI:
    //  not using rounding up, because size of
    //  content will be too large and scroll bars will appeared
    AValue := ATargetDpi / acDefaultDpi;
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
const
  SWP_POS_CHANGE = SWP_NOMOVE or SWP_NOSIZE;
var
  AWindowPos: PWindowPos;
begin
  if Message.Msg = WM_WINDOWPOSCHANGED then
  begin
    AWindowPos := TWMWindowPosChanged(Message).WindowPos;
    if (AWindowPos = nil) or (AWindowPos^.flags and SWP_POS_CHANGE <> SWP_POS_CHANGE) then
    begin
      if not (csAligning in Control.ControlState) then
    {$IFDEF FPC}
      if not Control.Parent.AutoSizeDelayed then
    {$ENDIF}
        TACLMainThread.RunPostponed(Changed, Self);
    end;
  end;
  FPrevWndProc(Message);
end;

procedure TACLSubControlOptions.AlignControl(var AClientRect: TRect);
var
  LBounds: TRect;
begin
  if Validate then
  begin
    LBounds := AClientRect;
    LBounds.Offset(FOwner.Left, FOwner.Top);
    case Position of
      mLeft:
        begin
          LBounds.Width := Control.ExplicitWidth;
          if Align <> acTrue then
            LBounds.CenterVert(Control.ExplicitHeight);
          Inc(AClientRect.Left, GetActualIndentBetweenElements);
          Inc(AClientRect.Left, Control.ExplicitWidth);
        end;

      mRight:
        begin
          LBounds := LBounds.Split(srRight, Control.ExplicitWidth);
          if Align <> acTrue then
            LBounds.CenterVert(Control.ExplicitHeight);
          Dec(AClientRect.Right, GetActualIndentBetweenElements);
          Dec(AClientRect.Right, Control.ExplicitWidth);
        end;

      mTop:
        begin
          LBounds.Height := Control.ExplicitHeight;
          if Align = acFalse then
            LBounds.Width := Control.ExplicitWidth;
          Inc(AClientRect.Top, GetActualIndentBetweenElements);
          Inc(AClientRect.Top, Control.ExplicitHeight);
        end;

      mBottom:
        begin
          LBounds := LBounds.Split(srBottom, Control.ExplicitHeight);
          if Align = acFalse then
            LBounds.Width := Control.ExplicitWidth;
          Dec(AClientRect.Bottom, GetActualIndentBetweenElements);
          Dec(AClientRect.Bottom, Control.ExplicitHeight);
        end;
    end;
    TACLControls.AlignControl(Control, LBounds);
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

procedure TACLSubControlOptions.UpdateVisibility;
begin
  if Control <> nil then
    Control.Visible := Owner.Visible;
end;

function TACLSubControlOptions.GetActualIndentBetweenElements: Integer;
begin
  if Position in [mRight, mLeft] then
    Result := dpiApply(acIndentBetweenElements, acGetCurrentDpi(FOwner))
  else
    Result := dpiApply(2, acGetCurrentDpi(FOwner));
end;

function TACLSubControlOptions.Validate: Boolean;
begin
  if (Control <> nil) and (Control.Parent <> FOwner.Parent) then
    Control := nil;
  if (Control <> nil) and (Control.Align <> alNone) then
    Control.Align := alNone; // alCustom disables auto-size feature
{$IFNDEF FPC}
  if (Control <> nil) and (Control.AlignWithMargins) then
    Control.AlignWithMargins := False;
{$ENDIF}
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
    if acIsChildOrSelf(AValue, FOwner) then
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
        UpdateVisibility;
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

{ TACLDeferPlacementUpdate }

constructor TACLDeferPlacementUpdate.Create;
begin
  FBounds := TACLDictionary<TControl, TRect>.Create;
end;

destructor TACLDeferPlacementUpdate.Destroy;
begin
  FreeAndNil(FBounds);
  inherited;
end;

procedure TACLDeferPlacementUpdate.Add(AControl: TControl; const ABounds: TRect);
begin
  FBounds.AddOrSetValue(AControl, ABounds);
end;

procedure TACLDeferPlacementUpdate.Add(AControl: TControl; ALeft, ATop, AWidth, AHeight: Integer);
begin
  Add(AControl, Rect(ALeft, ATop, ALeft + AWidth, ATop + AHeight));
end;

procedure TACLDeferPlacementUpdate.Apply;
{$IFDEF FPC}
begin
  FBounds.Enum(
    procedure (const AControl: TControl; const R: TRect)
    begin
      TACLControls.AlignControl(AControl, R);
    end);
  FBounds.Enum(
    procedure (const AControl: TControl; const R: TRect)
    begin
      AControl.Invalidate;
    end);
{$ELSE}
var
  ABounds: TRect;
  AHandle: THandle;
  AVclControls: TList;
  AWinControls: TList;
  I: Integer;
begin
  if FBounds.Count > 0 then
  begin
    AVclControls := TList.Create;
    AWinControls := TList.Create;
    try
      AVclControls.Capacity := FBounds.Count;
      AWinControls.Capacity := FBounds.Count;

      FBounds.Enum(
        procedure (const AControl: TControl; const R: TRect)
        begin
          if AControl.BoundsRect <> R then
          begin
            if (AControl is TWinControl) and TWinControl(AControl).HandleAllocated then
              AWinControls.Add(AControl)
            else
              AVclControls.Add(AControl);
          end;
        end);

      if AWinControls.Count > 0 then
      begin
        AHandle := BeginDeferWindowPos(AWinControls.Count);
        try
          for I := 0 to AWinControls.Count - 1 do
          begin
            ABounds := Bounds[AWinControls.List[I]];
            DeferWindowPos(AHandle, TWinControl(AWinControls.List[I]).Handle, 0,
              ABounds.Left, ABounds.Top, ABounds.Width, ABounds.Height,
              SWP_NOZORDER{ or SWP_NOREDRAW});
          end;
        finally
          EndDeferWindowPos(AHandle);
        end;
      end;

      for I := 0 to AVclControls.Count - 1 do
        TControl(AVclControls.List[I]).BoundsRect := Bounds[AVclControls.List[I]];
    finally
      AWinControls.Free;
      AVclControls.Free;
    end;
  end;
{$ENDIF}
end;

function TACLDeferPlacementUpdate.GetBounds(AControl: TControl): TRect;
begin
  Result := FBounds[AControl];
end;

{ TACLOrderedAlign }

class destructor TACLOrderedAlign.Destroy;
begin
  FreeAndNil(FWorkList);
end;

class procedure TACLOrderedAlign.Apply(AParent: TWinControl; var ARect: TRect);
{$IFDEF FPC}
begin
  // В Lazarus, это решается посредством DoAlignChildControls + TACLOrderedAlign.List:
  // Мы просто подменяем заполняем список контролов в правильном порядке, а позиционирует он сам.
  raise ENotSupportedException.Create('TACLOrderedAlign.Apply');
{$ELSE}

  function GetParentClientSize(ACalcType: TOriginalParentCalcType): TPoint; {inline;}
  begin
    if AParent.HandleAllocated and ((ACalcType = ctWinApi) or not (csDesigning in AParent.ComponentState)) then
      Result := AParent.ClientRect.BottomRight
    else
      Result := Point(AParent.Width, AParent.Height);

    Dec(Result.X, AParent.Padding.Left + AParent.Padding.Right);
    Dec(Result.Y, AParent.Padding.Top + AParent.Padding.Bottom);
  end;

var
  I: Integer;
  LCtrl: TControlAccess;
  LList: TTabOrderList;
  LSizes: array[TOriginalParentCalcType] of TPoint;
  LParent: TWinControlAccess absolute AParent;
begin
  LList := nil;
  try
    acExchangePointers(FWorkList, LList);
    if LList = nil then
      LList := TTabOrderList.Create;

    List(AParent, [Low(TAlign)..High(TAlign)], LList);

    if LList.Count > 0 then
    begin
      TWinControlAccess(AParent).AdjustClientRect(ARect);
      LSizes[ctNative] := GetParentClientSize(ctNative);
      LSizes[ctWinApi] := GetParentClientSize(ctWinApi);
      for I := 0 to LList.Count - 1 do
      begin
        LCtrl := LList.List[I];
        if LCtrl.Align = alClient then
          LCtrl.Margins.SetControlBounds(ARect, True)
        else
          LParent.ArrangeControl(LCtrl,
            LSizes[LCtrl.FOriginalParentCalcType], LCtrl.Align, FWorkInfo, ARect);
      end;
    end;
  finally
    acExchangePointers(FWorkList, LList);
    LList.Free;
  end;
  LParent.ControlsAligned;
  if LParent.Showing then
    LParent.AdjustSize;
{$ENDIF}
end;

class function TACLOrderedAlign.Compare(const L, R: TControl): Integer;
begin
  Result := AlignWeightMap[L.Align] - AlignWeightMap[R.Align];
  if Result = 0 then
    Result := GetOrder(L) - GetOrder(R);
  if Result = 0 then
    case L.Align of
      alLeft:
        Result := L.Left - R.Left;
      alRight:
        Result := R.Left - L.Left;
      alTop:
        Result := L.Top - R.Top;
      alBottom:
        Result := R.Top - L.Top;
    end;
end;

class function TACLOrderedAlign.GetOrder(AControl: TControl): Integer;
var
  LOrderProp: PPropInfo;
begin
  LOrderProp := GetPropInfo(AControl.ClassType, 'AlignOrder');
  if LOrderProp <> nil then
    Result := GetOrdProp(AControl, LOrderProp)
  else
    Result := 0;
end;

class procedure TACLOrderedAlign.List(
  AParent: TWinControl; AAlignSet: TAlignSet; AList: TTabOrderList);
var
  I: Integer;
  LControl: TControl;
begin
  AList.Count := 0;
  for I := 0 to AParent.ControlCount - 1 do
  begin
    LControl := AParent.Controls[I];
    if LControl.Visible and (LControl.Align in AAlignSet) then
      AList.Add(LControl);
  end;
  if AList.Count > 1 then
    AList.Sort(@Compare);
end;

class procedure TACLOrderedAlign.SetOrder(AControl: TControl; AOrder: Integer);
var
  LOrderProp: PPropInfo;
begin
  LOrderProp := GetPropInfo(AControl.ClassType, 'AlignOrder');
  if LOrderProp <> nil then
    SetOrdProp(AControl, LOrderProp, AOrder);
end;

{$ENDREGION}

{$REGION ' In-placing '}

{ TACLInplaceInfo }

procedure TACLInplaceInfo.Reset;
begin
  FillChar(Self, SizeOf(Self), 0);
end;

{$ENDREGION}

{$REGION ' Styles '}

{ TACLStyleBackground }

procedure TACLStyleBackground.Draw(ACanvas: TCanvas;
  const R: TRect; ATransparent: Boolean; ABorders: TACLBorders);
begin
  if not ATransparent then
    DrawContent(ACanvas, R);
  DrawBorder(ACanvas, R, ABorders);
end;

procedure TACLStyleBackground.DrawBorder(
  ACanvas: TCanvas; const R: TRect; ABorders: TACLBorders);
begin
  acDrawComplexFrame(ACanvas, R, ColorBorder1.AsColor, ColorBorder2.AsColor, ABorders);
end;

procedure TACLStyleBackground.DrawContent(ACanvas: TCanvas; const R: TRect);
begin
  acDrawGradient(ACanvas, R, ColorContent1.Value, ColorContent2.Value);
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

procedure TACLStyleHatch.Draw(ACanvas: TCanvas; const R: TRect;
  ABorders: TACLBorders; ASize: Integer = DefaultSize);
begin
  acDrawHatch(ACanvas.Handle, R, ColorContent1.AsColor, ColorContent2.AsColor, ASize);
  acDrawFrameEx(ACanvas, R, ColorBorder.AsColor, ABorders);
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

{$ENDREGION}

{$REGION ' Mouse Tracker '}

{ TACLMouseTracker }

class destructor TACLMouseTracker.Destroy;
begin
  FreeAndNil(FInstance);
end;

class procedure TACLMouseTracker.Release(const AIntf: IACLMouseTracking);
begin
  if FInstance <> nil then
    FInstance.Remove(AIntf);
end;

class procedure TACLMouseTracker.Release(const AObj: TObject);
var
  ATracker: IACLMouseTracking;
begin
  if Supports(AObj, IACLMouseTracking, ATracker) then
    Release(ATracker);
end;

class procedure TACLMouseTracker.Start(const AIntf: IACLMouseTracking);
begin
  Get.Add(AIntf);
end;

procedure TACLMouseTracker.DoAdding(const AObject: IACLMouseTracking);
begin
  AObject.MouseEnter;
end;

class function TACLMouseTracker.Get: TACLMouseTracker;
begin
  if FInstance = nil then
  begin
    FInstance := TACLMouseTracker.Create;
    FInstance.Interval := 50;
  end;
  Result := FInstance;
end;

procedure TACLMouseTracker.TimerObject(const AObject: IACLMouseTracking);
begin
  if not AObject.IsMouseAtControl then
  begin
    Remove(AObject);
    AObject.MouseLeave;
  end;
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
{$IFDEF FPC}
  Include(Result.ShiftState, ssShift);
{$ELSE}
  Result.Keys := Result.Keys or MK_SHIFT;
{$ENDIF}
  Result.WheelDelta := -Result.WheelDelta;
end;

{$ENDREGION}

{$REGION ' Controls '}

{ TACLGraphicControl }

constructor TACLGraphicControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IFDEF FPC}
  FCurrentPPI := acDefaultDpi;
{$ENDIF}
  ControlStyle := ControlStyle + [csCaptureMouse];
  FDefaultSize := TSize.Create(200, 30);
  FMargins := TACLMargins.Create(TACLMargins.DefaultValue);
  FMargins.OnChanged := MarginsChangeHandler;
end;

destructor TACLGraphicControl.Destroy;
begin
  FreeAndNil(FMargins);
  inherited Destroy;
end;

procedure TACLGraphicControl.AfterConstruction;
begin
  inherited;
  if (Width = 0) or (Height = 0) then
    SetBounds(Left, Top, FDefaultSize.cx, FDefaultSize.cy);
  MarginsChangeHandler(nil);
  UpdateTransparency;
end;

procedure TACLGraphicControl.BeforeDestruction;
begin
  inherited BeforeDestruction;
  RemoveFreeNotifications;
  ResourceCollection := nil;
  TACLMouseTracker.Release(Self);
  TACLObjectLinks.Release(Self);
  AnimationManager.RemoveOwner(Self);
end;

procedure TACLGraphicControl.SetAlignOrder(AValue: Integer);
begin
  AValue := Max(AValue, 0);
  if AValue <> FAlignOrder then
  begin
    FAlignOrder := AValue;
    RequestAlign;
  end;
end;

procedure TACLGraphicControl.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  CallNotifyEvent(Self, OnBoundsChanged);
end;

procedure TACLGraphicControl.SetParent(NewParent: TWinControl);
begin
  inherited SetParent(NewParent);
  TCustomScalableControl.ScaleOnSetParent(Self);
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
{$IFNDEF FPC}
  if AutoSize then
    RequestAlign;
{$ENDIF}
end;

{$IFDEF FPC}
procedure TACLGraphicControl.CalculatePreferredSize(var W, H: Integer; X: Boolean);
begin
  H := Height;
  W := Width;
  CanAutoSize(W, H);
end;

procedure TACLGraphicControl.DoAutoAdjustLayout(
  const AMode: TLayoutAdjustmentPolicy; const X, Y: Double);
begin
  inherited;
  if AMode = lapAutoAdjustForDPI then
  begin
    FCurrentPPI := Round(Y * FCurrentPPI);
    SetTargetDPI(FCurrentPPI);
    MarginsChangeHandler(nil);
  end;
end;
{$ELSE}
procedure TACLGraphicControl.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;
  SetTargetDPI(FCurrentPPI);
  MarginsChangeHandler(nil);
end;
{$ENDIF}

procedure TACLGraphicControl.DoGetHint(const P: TPoint; var AHint: string);
begin
  if Assigned(OnGetHint) then
    OnGetHint(Self, P.X, P.Y, AHint);
end;

procedure TACLGraphicControl.InvalidateRect(const R: TRect);
begin
  if Parent <> nil then
    acInvalidateRect(Parent, R.OffsetTo(Left, Top));
end;

function TACLGraphicControl.GetCurrentDpi: Integer;
begin
  Result := FCurrentPPI;
end;

function TACLGraphicControl.GetCollection: TACLCustomResourceCollection;
begin
  Result := ResourceCollection;
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

procedure TACLGraphicControl.SetResourceCollection(AValue: TACLCustomResourceCollection);
begin
  if acResourceCollectionFieldSet(FResourceCollection, Self, Self, AValue) then
    ResourceChanged(ResourceCollection);
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

procedure TACLGraphicControl.MouseDown(
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
{$IFDEF FPC}
  if Button = mbLeft then
    SendCancelMode(Self);
{$ENDIF}
  inherited;
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
  TACLMouseTracker.Start(Self);
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
  TACLControls.UpdateMargins(Self, AlignWithMargins, Margins, FCurrentPPI);
end;

{$IFDEF FPC}
procedure TACLGraphicControl.SetAlignWithMargins(AValue: Boolean);
begin
  if FAlignWithMargins <> AValue then
  begin
    FAlignWithMargins := AValue;
    MarginsChangeHandler(nil);
  end;
end;
{$ENDIF}

procedure TACLGraphicControl.SetMargins(const Value: TACLMargins);
begin
  FMargins.Assign(Value);
end;

procedure TACLGraphicControl.ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
begin
  if Sender = ResourceCollection then
    ResourceCollectionChanged;
  ResourceChanged;
end;

procedure TACLGraphicControl.ResourceChanged;
begin
  if not (csDestroying in ComponentState) then
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

procedure TACLGraphicControl.UpdateTransparency;
begin
  // do nothing
end;

{ TCustomScalableControl }

{$IFDEF FPC}
constructor TCustomScalableControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCurrentPPI := acDefaultDpi;
end;

procedure TCustomScalableControl.ChangeScale(M, D: Integer);
begin
  ChangeScale(M, D, False);
end;

procedure TCustomScalableControl.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  if isDpiChange then
    FCurrentPPI := M
  else
    inherited ChangeScale(M, D);
end;

procedure TCustomScalableControl.DoAutoAdjustLayout(
  const AMode: TLayoutAdjustmentPolicy; const X, Y: Double);
begin
  if AMode = lapAutoAdjustForDPI then
  begin
    Perform(CM_SCALECHANGING, 0, 0);
    try
      inherited;
      ChangeScale(Round(X * FCurrentPPI), FCurrentPPI, True);
    finally
      Perform(CM_SCALECHANGED, 0, 0);
    end;
  end
  else
    inherited;
end;
{$ENDIF}

function TCustomScalableControl.GetCurrentDpi: Integer;
begin
  Result := FCurrentPPI;
end;

procedure TCustomScalableControl.ScaleForPPI(NewPPI: Integer);
begin
{$IFDEF FPC}
  AutoAdjustLayout(lapAutoAdjustForDPI, FCurrentPPI, NewPPI, 0, 0);
{$ELSE}
  Perform(CM_SCALECHANGING, 0, 0);
  try
    inherited ScaleForPPI(NewPPI);
  finally
    Perform(CM_SCALECHANGED, 0, 0);
  end;
{$ENDIF}
end;

procedure TCustomScalableControl.SetParent(NewParent: TWinControl);
begin
  inherited SetParent(NewParent);
  ScaleOnSetParent(Self);
end;

class procedure TCustomScalableControl.ScaleOnSetParent(ACaller: TControl);
{$IFDEF FPC}
var
  ASrcDpi, ADstDpi: Integer;
{$ENDIF}
begin
  if csDestroying in ACaller.ComponentState then
    Exit;
  if ACaller.Parent = nil then
    Exit;
{$IF DEFINED(FPC)}
  ASrcDpi := acGetCurrentDpi(ACaller);
  ADstDpi := acGetCurrentDpi(ACaller.Parent);
  if ASrcDpi <> ADstDpi then
    ACaller.AutoAdjustLayout(lapAutoAdjustForDPI, ASrcDpi, ADstDpi, 0, 0);
{$ELSEIF NOT DEFINED(DELPHI110ALEXANDRIA)}
  // AI, 14.06.2023 (Delphi 10.4)
  // csFreeNotification:
  //   VCL не скейлит контрол, если у него есть этот флаг, делаем сами
  // csDesigning:
  //   Если вызывать GetParentCurrentDpi, то мы доберемся до главной
  //   формы IDE и возьмем ее DPI, а не DPI дизайнера (они отличаются)
  // Оба бага пофикшены в Delphi 11.0
  if csDesigning in ACaller.Parent.ComponentState then
    ACaller.ScaleForPPI(TControlAccess(ACaller.Parent).FCurrentPPI)
  else if csFreeNotification in ACaller.ComponentState then
    ACaller.ScaleForPPI(TControlAccess(ACaller).GetParentCurrentDpi);
{$IFEND}
end;

{ TACLCustomControl }

constructor TACLCustomControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMargins := TACLMargins.Create(TACLMargins.DefaultValue);
  FMargins.OnChanged := MarginsChangeHandler;
  FPadding := CreatePadding;
  FPadding.OnChanged := PaddingChangeHandler;
  FDefaultSize := TSize.Create(200, 150);
end;

destructor TACLCustomControl.Destroy;
begin
  FreeAndNil(FPadding);
  FreeAndNil(FMargins);
  inherited Destroy;
end;

procedure TACLCustomControl.AfterConstruction;
begin
  inherited AfterConstruction;
  if (Width = 0) or (Height = 0) then
    SetBounds(Left, Top, FDefaultSize.cx, FDefaultSize.cy);
  MarginsChangeHandler(nil);
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
  TACLMouseTracker.Release(Self);
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
  if not (csDestroying in ComponentState) then
    acInvalidateRect(Self, R);
end;

procedure TACLCustomControl.ApplyColorSchema(const ASchema: TACLColorSchema);
begin
  acApplyColorSchemaForPublishedProperties(Self, ASchema);
end;

procedure TACLCustomControl.Localize;
begin
  LangApplyTo(Copy(LangSection, 1, acLastDelimiter('.', LangSection)), Self);
end;

procedure TACLCustomControl.Localize(const ASection: string);
begin
  FLangSection := ASection;
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
  FMouseInClient := True;
  UpdateCursor;
end;

procedure TACLCustomControl.MouseLeave;
begin
  FMouseInClient := False;
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

procedure TACLCustomControl.MouseDown(
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FocusOnClick then
    SetFocusOnClick;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TACLCustomControl.Paint;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
end;

procedure TACLCustomControl.PaintWindow(DC: HDC);
begin
  if not (csOpaque in ControlStyle) then
    acDrawTransparentControlBackground(Self, DC, ClientRect, False);
  inherited PaintWindow(DC);
end;

procedure TACLCustomControl.Resize;
begin
  inherited Resize;
{$IFNDEF FPC}
  if not (csDestroying in ComponentState) then
    BoundsChanged;
{$ENDIF}
end;

procedure TACLCustomControl.SetAlignOrder(AValue: Integer);
begin
  AValue := Max(AValue, 0);
  if AValue <> FAlignOrder then
  begin
    FAlignOrder := AValue;
    RequestAlign;
  end;
end;

procedure TACLCustomControl.SetFocusOnClick;
begin
  if not Focused then SetFocus;
end;

procedure TACLCustomControl.SetMargins(const Value: TACLMargins);
begin
  Margins.Assign(Value);
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
  if not (csDestroying in ComponentState) and (FScaleChangeCount = 0) then
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
  if MouseInClient and HandleAllocated and not (csDestroying in ComponentState) then
    Perform(WM_SETCURSOR, Handle, HTCLIENT);
end;

procedure TACLCustomControl.UpdateTransparency;
begin
  if Transparent then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque];
end;

procedure TACLCustomControl.WndProc(var Message: TMessage);
begin
  if not TACLControls.WndProc(Self, Message) then
    inherited WndProc(Message);
end;

procedure TACLCustomControl.CMDialogChar(var Message: TCMDialogChar);
begin
  if DialogChar(Message) then
    Message.Result := 1
  else
    inherited;
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
begin
  if (Message.DC <> 0) or not DoubleBuffered then
    PaintHandler(Message)
  else
    TACLControls.BufferedPaint(Self);
end;

procedure TACLCustomControl.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  FocusChanged;
end;

procedure TACLCustomControl.WMSize(var Message: TWMSize);
begin
{$IFNDEF FPC}
  // Для корректной работы anchor-ов при смене dpi в Delphi
  if not (csDestroying in ComponentState) then
  begin
    UpdateBounds;
    BoundsChanged;
  end;
{$ENDIF}

  inherited;

  if Parent <> nil then
  begin
    if TWinControlAccess(Parent).AutoSize then
      TWinControlAccess(Parent).AdjustSize;
  end;
end;

{$IFDEF FPC}
procedure TACLCustomControl.SetAlignWithMargins(AValue: Boolean);
begin
  if FAlignWithMargins <> AValue then
  begin
    FAlignWithMargins := AValue;
    MarginsChangeHandler(nil);
  end;
end;
{$ENDIF}

procedure TACLCustomControl.CMScaleChanging(var Message: TMessage);
begin
  Inc(FScaleChangeCount);
  if FScaleChangeCount = 1 then
    TACLControls.ScaleChanging(Self, FScaleChangeState);
end;

procedure TACLCustomControl.CMScaleChanged(var Message: TMessage);
begin
  Dec(FScaleChangeCount);
  if FScaleChangeCount = 0 then
  begin
    ResourceChanged;
    TACLControls.ScaleChanged(Self, FScaleChangeState);
  end;
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

procedure TACLCustomControl.WMLButtonDown(var Message: TWMLButtonDown);
begin
{$IFDEF FPC}
  SendCancelMode(Self);
{$ENDIF}
  inherited;
end;

procedure TACLCustomControl.WMMouseMove(var Message: TWMMouseMove);
begin
  if IsMouseAtControl then
    TACLMouseTracker.Start(Self);
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
  ARect.Content(GetContentOffset);
  ARect.Content(Padding.GetScaledMargins(FCurrentPPI));
end;

procedure TACLCustomControl.AdjustSize;
begin
  if csAligning in ControlState then Exit;
{$IFDEF FPC}
  SetBoundsKeepBase(Left, Top, Width, Height);
{$ELSE}
  SetBounds(Left, Top, Width, Height);
{$ENDIF}
  inherited AdjustSize;
end;

procedure TACLCustomControl.AlignControls(AControl: TControl; var Rect: TRect);
begin
{$IFDEF FPC}
  inherited;
{$ELSE}
  TACLOrderedAlign.Apply(Self, Rect);
{$ENDIF}
end;

procedure TACLCustomControl.BoundsChanged;
begin
{$IFDEF FPC}
  inherited;
  if AutoSize then
    InvalidatePreferredSize;
  if FRedrawOnResize and (Parent <> nil) then
  begin
    if wcfAligningControls in TWinControlAccess(Parent).FWinControlFlags then
      Invalidate;
  end;
{$ENDIF}
end;

{$IFDEF FPC}
procedure TACLCustomControl.CalculatePreferredSize(var W, H: Integer; X: Boolean);
begin
  H := Height;
  W := Width;
  // inherited должен быть вызван для паналей (иначе будет зависать на сложных макетах),
  // но при этом не должен вызываться для инплейс-редакторов
  if csAcceptsControls in ControlStyle then
    inherited;
  CanAutoSize(W, H);
end;

function TACLCustomControl.DoAlignChildControls(AAlign: TAlign;
  AControl: TControl; AList: TTabOrderList; var ARect: TRect): Boolean;
begin
  TACLOrderedAlign.List(Self, [AAlign], AList);
  Result := False;
end;

procedure TACLCustomControl.InitializeWnd;
begin
  inherited InitializeWnd;
  Perform(WM_CREATE, 0, 0); // especially for TACLDropTarget
end;
{$ENDIF}

procedure TACLCustomControl.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  Perform(CM_SCALECHANGING, 0, 0);
  try
    inherited;
    SetTargetDPI(FCurrentPPI);
    MarginsChangeHandler(nil);
  finally
    Perform(CM_SCALECHANGED, 0, 0);
  end;
end;

function TACLCustomControl.CreatePadding: TACLPadding;
begin
  Result := TACLPadding.Create(0);
end;

function TACLCustomControl.DialogChar(var Message: TWMKey): Boolean;
begin
{$IFDEF FPC}
  Result := inherited;
{$ELSE}
  Result := False;
{$ENDIF}
end;

function TACLCustomControl.IsInScaling: Boolean;
begin
  Result := (FScaleChangeCount > 0){$IFNDEF FPC} or FIScaling{$ENDIF};
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

function TACLCustomControl.GetLangSection: string;
begin
  if FLangSection = '' then
    FLangSection := LangGetComponentPath(Self);
  Result := FLangSection;
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
    TACLControls.UpdateMargins(Self, AlignWithMargins, Margins, FCurrentPPI);
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
  FStyle := CreateStyle;
  Borders := acAllBorders;
end;

destructor TACLContainer.Destroy;
begin
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLContainer.AlignControls(AControl: TControl; var Rect: TRect);
begin
  if Assigned(OnAlignControls) then
  begin
  {$IFDEF FPC}
    if wcfAligningControls in FWinControlFlags then exit;
    Include(FWinControlFlags, wcfAligningControls);
    try
  {$ENDIF}
      AdjustClientRect(Rect);
      OnAlignControls(Self, Rect);
      ControlsAligned;
  {$IFDEF FPC}
    finally
      Exclude(FWinControlFlags, wcfAligningControls);
    end;
  {$ELSE}
    if Showing then AdjustSize;
  {$ENDIF}
  end
  else
    inherited;
end;

procedure TACLContainer.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  // Для корректной отработки AutoSize при первом показе контейнера с контролами
  if Showing then
    FullRefresh;
end;

function TACLContainer.CreateStyle: TACLStyleBackground;
begin
  Result := TACLStyleBackground.Create(Self);
end;

function TACLContainer.GetContentOffset: TRect;
begin
  Result := acBorderOffsets * Borders;
end;

procedure TACLContainer.Paint;
begin
  Style.Draw(Canvas, ClientRect, Transparent, Borders);
end;

procedure TACLContainer.SetAutoSize(Value: Boolean);
begin
  if Value <> AutoSize then
  begin
    inherited SetAutoSize(Value);
  {$IFDEF FPC}
    // Сохраняем поведение как в Delphi: дельфя корректирует положение
    // анчорид-контролов только при включении автосайза, а не всегда.
    if Value then
      ControlStyle := ControlStyle + [csAutoSizeKeepChildLeft, csAutoSizeKeepChildTop]
    else
      ControlStyle := ControlStyle - [csAutoSizeKeepChildLeft, csAutoSizeKeepChildTop];
  {$ENDIF}
  end;
end;

procedure TACLContainer.SetBorders(AValue: TACLBorders);
begin
  if AValue <> FBorders then
  begin
    FBorders := AValue;
    FRedrawOnResize := AValue <> [];
    if HandleAllocated then
    begin
      AdjustSize;
      Realign;
      Invalidate;
    end;
  end;
end;

procedure TACLContainer.SetStyle(AValue: TACLStyleBackground);
begin
  FStyle.Assign(AValue);
end;

procedure TACLContainer.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Style.SetTargetDPI(AValue);
end;

procedure TACLContainer.UpdateTransparency;
begin
  if Transparent or Style.IsTransparentBackground then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque];
end;

{$ENDREGION}

{$REGION ' Helpers '}

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

{ TACLControls }

//function GetUpdateRegion(AControl: TWinControl): TRegionHandle;
//begin
//  Result := 0;
//{$IFDEF MSWINDOWS}
//  if DwmCompositionEnabled then
//  begin
//    Result := CreateRectRgn(0, 0, 0, 0);
//    if GetUpdateRgn(AControl.Handle, Result, False) <> COMPLEXREGION then
//    begin
//      DeleteObject(Result);
//      Result := 0;
//    end;
//  end;
//{$ENDIF}
//end;

class procedure TACLControls.AlignControl(AControl: TControl; const ABounds: TRect);
begin
  AControl.ControlState := AControl.ControlState + [csAligning];
  try
    AControl.BoundsRect := ABounds;
  finally
    AControl.ControlState := AControl.ControlState - [csAligning];
  end;
end;

class procedure TACLControls.BufferedPaint(ACaller: TWinControl);
var
  LMemBmp: HBITMAP;
  LMemDC: HDC;
  LPaintStruct: TPaintStruct;
begin
  BeginPaint(ACaller.Handle, LPaintStruct);
  try
    if not LPaintStruct.rcPaint.IsEmpty then
    begin
    {$IFDEF MSWINDOWS}
      if (csGlassPaint in ACaller.ControlState) and DwmCompositionEnabled then
      begin
        var LPaintBuffer := BeginBufferedPaint(LPaintStruct.hdc, LPaintStruct.rcPaint, BPBF_COMPOSITED, nil, LMemDC);
        if LPaintBuffer <> 0 then
        try
          ACaller.Perform(WM_ERASEBKGND, LMemDC, LMemDC);
          ACaller.Perform(WM_PRINTCLIENT, LMemDC, PRF_CLIENT);
          if not (csPaintBlackOpaqueOnGlass in ACaller.ControlStyle) then
            BufferedPaintMakeOpaque(LPaintBuffer, LPaintStruct.rcPaint);
        finally
          EndBufferedPaint(LPaintBuffer, True);
        end;
      end
      else
    {$ENDIF}
      begin
        LMemDC := CreateCompatibleDC(LPaintStruct.hdc);
        LMemBmp := CreateCompatibleBitmap(LPaintStruct.hdc, LPaintStruct.rcPaint.Width, LPaintStruct.rcPaint.Height);
        try
          DeleteObject(SelectObject(LMemDC, LMemBmp));
          SetWindowOrgEx(LMemDC, LPaintStruct.rcPaint.Left, LPaintStruct.rcPaint.Top, nil);
          //acBitBlt(LMemDC, LPaintStruct.hdc, LPaintStruct.rcPaint, LPaintStruct.rcPaint.TopLeft);
          ACaller.Perform(WM_ERASEBKGND, LMemDC, LMemDC);
          ACaller.Perform(WM_PAINT, LMemDC, 0);
          acBitBlt(LPaintStruct.hdc, LMemDC, LPaintStruct.rcPaint, LPaintStruct.rcPaint.TopLeft);
        finally
          DeleteDC(LMemDC);
          DeleteObject(LMemBmp);
        end;
      end;
    end;
  finally
    EndPaint(ACaller.Handle, LPaintStruct);
  end;
end;

class procedure TACLControls.ScaleChanging(AControl: TWinControl; var AState: TObject);
{$IFNDEF FPC}
var
  AChildControl: TControlAccess;
  I: Integer;
{$ENDIF}
begin
  AControl.DisableAlign;
  AState := TObject(TWinControlAccess(AControl).AutoSize);
{$IFNDEF FPC}
  for I := 0 to AControl.ControlCount - 1 do
  begin
    AChildControl := TControlAccess(AControl.Controls[I]);
    AChildControl.FAnchorMove := True;
  end;
{$ENDIF}
  TWinControlAccess(AControl).AutoSize := False;
end;

class procedure TACLControls.ScaleChanged(AControl: TWinControl; var AState: TObject);
{$IFNDEF FPC}
var
  AChildControl: TControlAccess;
  I: Integer;
{$ENDIF}
begin
{$IFNDEF FPC}
  for I := 0 to AControl.ControlCount - 1 do
  begin
    AChildControl := TControlAccess(AControl.Controls[I]);
    AChildControl.FAnchorMove := False;
    AChildControl.UpdateBoundsRect(AChildControl.BoundsRect); // to invoke UpdateAnchorRules
  end;
{$ENDIF}
  TWinControlAccess(AControl).AutoSize := Boolean(AState);
  TWinControlAccess(AControl).EnableAlign;
end;

class function TACLControls.WndProc(ACaller: TWinControl; var Message: TMessage): Boolean;
begin
  Result := False;
{$IFDEF FPC}
  if (Message.Msg >= LM_MOUSEFIRST) and (Message.Msg <= LM_MOUSELAST) then
  begin
    if not Mouse.IsDragging then
    begin
      if ACaller.Perform(WM_SETCURSOR, ACaller.Handle, MakeLong(HTCLIENT, Message.Msg)) = 0 then
        SetCursor(crDefault);
    end;
  end;
{$ENDIF}
  if Message.Msg = WM_SETCURSOR then
  begin
    UpdateCursor(ACaller, TWMSetCursor(Message));
    Result := Message.Result = 1;
  end;
end;

class procedure TACLControls.UpdateMargins(AControl: TControl;
  AUseMargins: Boolean; AMargins: TACLPadding; ACurrentDpi: Integer);
begin
{$IFDEF FPC}
  if not AUseMargins then
    UpdateMargins(AControl, NullRect)
  else
{$ENDIF}
    UpdateMargins(AControl, AMargins.GetScaledMargins(ACurrentDpi));
end;

class procedure TACLControls.UpdateMargins(AControl: TControl; const AMargins: TRect);
begin
{$IFDEF FPC}
  with TControlAccess(AControl).BorderSpacing do
{$ELSE}
  with TControlAccess(AControl).Margins do
{$ENDIF}
  begin
    Left := AMargins.Left;
    Top := AMargins.Top;
    Right := AMargins.Right;
    Bottom := AMargins.Bottom;
  end;
end;

class procedure TACLControls.UpdateCursor(ACaller: TWinControl; var Message: TWMSetCursor);

  function GetCursor(AControl: TControl): TCursor;
  var
    ACursorProvider: IACLCursorProvider;
  begin
    if Supports(AControl, IACLCursorProvider, ACursorProvider) then
      Result := ACursorProvider.GetCursor(AControl.CalcCursorPos)
    else
      Result := AControl.Cursor;
  end;

var
  AControl: TControl;
  ACursor: TCursor;
begin
  if csDesigning in ACaller.ComponentState then
    Exit;
  if Message.HitTest <> HTCLIENT then
    Exit;
  if ACaller.HandleAllocated and (Message.CursorWnd = ACaller.Handle) then
  begin
    ACursor := Screen.Cursor;
    if ACursor = crDefault then
    begin
      AControl := GetCaptureControl;
      if AControl = nil then
        AControl := ACaller.ControlAtPos(ACaller.CalcCursorPos, False);
      if AControl <> nil then
        ACursor := GetCursor(AControl);
      if ACursor = crDefault then
        ACursor := GetCursor(ACaller);
    end;
    SetCursor(Screen.Cursors[ACursor]);
    Message.Result := 1;
  end;
end;

{ TACLControlHelper }

function TACLControlHelper.BroadcastRecursive(
  Msg: Cardinal; ParamW: WPARAM; ParamL: LPARAM): LRESULT;
var
  I: Integer;
begin
  Result := Perform(Msg, ParamW, ParamL);
  if (Result = 0) and (Self is TWinControl) then
  begin
    for I := 0 to TWinControl(Self).ControlCount - 1 do
    begin
      Result := TWinControl(Self).Controls[I].BroadcastRecursive(Msg, ParamW, ParamL);
      if Result <> 0 then Exit;
    end;
  end;
end;

function TACLControlHelper.CalcCursorPos: TPoint;
begin
  Result := ScreenToClient(Mouse.CursorPos);
end;

{$IFDEF FPC}
function TACLControlHelper.ExplicitHeight: Integer;
begin
  Result := BorderSpacing.ControlHeight;
end;

function TACLControlHelper.ExplicitWidth: Integer;
begin
  Result := BorderSpacing.ControlWidth;
end;

procedure TACLControlHelper.SendCancelMode(Sender: TControl);
var
  LControl: TControl;
begin
  LControl := Self;
  while LControl <> nil do
  begin
    if (LControl is TCustomForm) and TCustomForm(LControl).Active then
    begin
      if TCustomForm(LControl).ActiveControl <> nil then
        TCustomForm(LControl).ActiveControl.Perform(CM_CANCELMODE, 0, LPARAM(Sender));
      if TCustomForm(LControl).ActiveDefaultControl <> nil then
        TCustomForm(LControl).ActiveDefaultControl.Perform(CM_CANCELMODE, 0, LPARAM(Sender));
    end;
    LControl := LControl.Parent;
  end;
end;
{$ENDIF}

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

{$ENDREGION}

initialization
{$IFDEF FPC}
  RegisterPropertyToSkip(TControl, 'Margins', '', '');
  RegisterPropertyToSkip(TControl, 'Padding', '', '');
  RegisterPropertyToSkip(TDataModule, 'PixelsPerInch', '', '');
{$ENDIF}
end.
