{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*               Skinable Menus              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Menus;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLProc,
  LCLType,
  LMessages,
  Messages,
{$ELSE}
  Winapi.CommCtrl,
  Winapi.Messages,
  Winapi.MMSystem,
  Winapi.OleAcc,
  Winapi.ShellApi,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Generics.Defaults,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // Vcl
  {Vcl.}Forms,
  {Vcl.}ActnList,
  {Vcl.}Controls,
  {Vcl.}Dialogs,
  {Vcl.}ExtCtrls,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}Menus,
  {Vcl.}StdCtrls,
  {Vcl.}Themes,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Timers,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.TextLayout,
  ACL.Graphics.Ex,
  ACL.Graphics.SkinImage,
  ACL.Math,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Threading,
  ACL.UI.Application,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Forms,
  ACL.UI.ImageList,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Desktop,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

const
  CM_MENUCLICKED  = CM_BASE + $0401;
  CM_MENUSELECTED = CM_BASE + $0402;
  CM_MENUTRACKING = CM_BASE + $0403;

type
{$REGION ' General '}
  TMenuItemClass = class of TMenuItem;
  TMenuItemEnumProc = reference to procedure (AMenuItem: TMenuItem);

  { IACLMenuItemCheckable }

  IACLMenuItemCheckable = interface
  ['{2766C127-C0D6-462E-B632-D41D7186FA87}']
  end;

  { IACLMenuShowHandler }

  IACLMenuShowHandler = interface
  ['{82B0E75A-647F-43C9-B05A-54E34D0EBD85}']
    procedure OnShow;
  end;

  { TACLMenuItem }

  TACLMenuItem = class(TMenuItem,
    IACLGlyph,
    IACLCurrentDpi,
    IACLMenuShowHandler)
  strict private
    FGlyph: TACLGlyph;
    FOnShow: TNotifyEvent;

    function IsGlyphStored: Boolean;
    procedure SetGlyph(AValue: TACLGlyph);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    // IACLGlyph
    function GetGlyph: TACLGlyph;
    // IACLMenuShowHandler
    procedure IACLMenuShowHandler.OnShow = DoShow;
    procedure DoShow; virtual;
    // IACLCurrentDpi
    function GetCurrentDpi: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function HasSubItems: Boolean; virtual;
    function ToString: string; override;
  published
    property Glyph: TACLGlyph read FGlyph write SetGlyph stored IsGlyphStored;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
  end;

  { TACLMenuContainerItem }

  TACLMenuItemLinkExpandMode = (lemExpandInplace, lemExpandInSubMenu, lemNoExpand);

  TACLMenuContainerItem = class(TACLMenuItem)
  strict private
    FExpandMode: TACLMenuItemLinkExpandMode;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure Expand(AProc: TMenuItemEnumProc); virtual; abstract;
  published
    property ExpandMode: TACLMenuItemLinkExpandMode
      read FExpandMode write FExpandMode default lemExpandInplace;
  end;

  { TACLMenuItemLink }

  TACLMenuItemLink = class(TACLMenuContainerItem)
  strict private
    FLink: TComponent;
    procedure SetLink(AValue: TComponent);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    // TACLMenuContainerItem
    procedure Expand(AProc: TMenuItemEnumProc); override;
    // IACLMenuShowHandler
    procedure DoShow; override;
  public
    destructor Destroy; override;
    function HasSubItems: Boolean; override;
    function ToString: string; override;
  published
    property Link: TComponent read FLink write SetLink;
  end;

  { TACLMenuListItem }

  TACLMenuListItem = class(TACLMenuContainerItem)
  strict private
    FAutoCheck: Boolean;
    FItemIndex: Integer;
    FItems: TStrings;

    procedure HandlerItemClick(Sender: TObject);
    procedure SetItems(AValue: TStrings);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    // TACLMenuContainerItem
    procedure Expand(AProc: TMenuItemEnumProc); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
    function HasSubItems: Boolean; override;
    function ToString: string; override;
  published
    property AutoCheck: Boolean read FAutoCheck write FAutoCheck default False;
    property Items: TStrings read FItems write SetItems;
    property ItemIndex: Integer read FItemIndex write FItemIndex default -1;
  end;

  { TACLStyleMenu }

  TACLStyleMenu = class(TACLStyle)
  protected const
    GlyphSize = 16;
  strict private
    FItemHeight: Integer;
    function GetItemHeight: Integer; inline;
  protected
    function CalculateItemHeight: Integer; virtual;
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
    procedure DoDrawImage(ACanvas: TCanvas; const ARect: TRect;
      AImages: TCustomImageList; AImageIndex: Integer;
      AEnabled, ASelected: Boolean); virtual;
    function GetTextIdent: Integer; inline;
    procedure InitializeResources; override;
  public
    procedure AfterConstruction; override;
    procedure AssignFontParams(ACanvas: TCanvas;
      ASelected, AIsDefault, AEnabled: Boolean); virtual;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect; ASelected: Boolean); virtual;
    procedure DrawItemImage(ACanvas: TCanvas;
      ARect: TRect; AItem: TMenuItem; ASelected: Boolean); virtual;
    procedure DrawText(ACanvas: TCanvas; ARect: TRect; const AText: string); virtual;
    function MeasureWidth(ACanvas: TCanvas; const S: string;
      AShortCut: TShortCut = scNone; ADefault: Boolean = False): Integer; virtual;
    property ItemHeight: Integer read GetItemHeight;
  published
    property ColorItem: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorItemSelected: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property Font: TACLResourceFont index 0 read GetFont write SetFont stored IsFontStored;
    property FontDisabled: TACLResourceFont index 1 read GetFont write SetFont stored IsFontStored;
    property FontSelected: TACLResourceFont index 2 read GetFont write SetFont stored IsFontStored;
    property Texture: TACLResourceTexture index 0 read GetTexture write SetTexture stored IsTextureStored;
  end;

{$ENDREGION}

{$REGION ' Helpers '}

  { TMenuItemHelper }

  TMenuItemHelper = class helper for TMenuItem
  strict private
    function GetDefaultItem: TMenuItem;
    function GetMenu: TMenu;
  protected
    procedure InitiateActions;
    procedure PrepareForShowing;
  public
    function AddItem(const ACaption, AHint: string; ATag: NativeInt = 0;
      AEvent: TNotifyEvent = nil; AShortCut: TShortCut = 0): TMenuItem; overload;
    function AddItem(const ACaption: string;
      AEvent: TNotifyEvent = nil; AShortCut: TShortCut = 0): TMenuItem; overload;
    function AddItem(const ACaption: string; ATag: NativeInt;
      AEvent: TNotifyEvent = nil; AShortCut: TShortCut = 0): TMenuItem; overload;
    function AddLink(const AMenuItemOrMenu: TComponent): TACLMenuItemLink;
    function AddRadioItem(const ACaption, AHint: string; ATag: NativeInt = 0;
      AEvent: TNotifyEvent = nil; AGroupIndex: Integer = 0;
      AShortCut: TShortCut = 0): TMenuItem; overload;
    function AddSeparator: TMenuItem;
    function CanBeParent(AParent: TMenuItem): Boolean;
    function FindByTag(const ATag: NativeInt): TMenuItem;
    procedure DeleteWithTag(const ATag: NativeInt);
    function HasVisibleSubItems: Boolean;
    function IsCheckable: Boolean;

    property DefaultItem: TMenuItem read GetDefaultItem;
    property Menu: TMenu read GetMenu;
  end;

{$ENDREGION}

{$REGION ' PopupMenu '}

  { TACLStylePopupMenu }

  TACLStylePopupMenu = class(TACLStyleMenu)
  strict private
    function GetItemGutterWidth: Integer; inline;
    function GetSeparatorHeight: Integer; inline;
  protected
    function CalculateItemHeight: Integer; override;
    procedure DoSplitRect(const R: TRect; AGutterWidth: Integer; out AGutterRect, AContentRect: TRect);
    procedure InitializeResources; override;
  public
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect; ASelected: Boolean); override;
    procedure DrawBorder(ACanvas: TCanvas; const R: TRect); virtual;
    procedure DrawCheckMark(ACanvas: TCanvas; const R: TRect;
      AChecked, AIsRadioItem, ASelected: Boolean);
    procedure DrawItem(ACanvas: TCanvas; R: TRect; const S: string;
      AShortCut: TShortCut; ASelected, AIsDefault, AEnabled, AHasSubItems: Boolean); virtual;
    procedure DrawItemImage(ACanvas: TCanvas; ARect: TRect;
      AItem: TMenuItem; ASelected: Boolean); override;
    procedure DrawScrollButton(ACanvas: TCanvas;
      const R: TRect; AUp, AEnabled: Boolean); virtual;
    procedure DrawSeparator(ACanvas: TCanvas; const R: TRect); virtual;
    function MeasureWidth(ACanvas: TCanvas; const S: string;
      AShortCut: TShortCut = scNone; ADefault: Boolean = False): Integer; override;

    property ItemGutterWidth: Integer read GetItemGutterWidth;
    property SeparatorHeight: Integer read GetSeparatorHeight;
  published
    property Borders: TACLResourceMargins index 0 read GetMargins write SetMargins stored IsMarginsStored;
    property ColorBorder1: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorBorder2: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
    property CornerRadius: TACLResourceInteger index 0 read GetInteger write SetInteger stored IsIntegerStored;
    property TextureGutter: TACLResourceTexture index 1 read GetTexture write SetTexture stored IsTextureStored;
    property TextureScrollBar: TACLResourceTexture index 2 read GetTexture write SetTexture stored IsTextureStored;
    property TextureScrollBarButtons: TACLResourceTexture index 3 read GetTexture write SetTexture stored IsTextureStored;
    property TextureScrollBarThumb: TACLResourceTexture index 4 read GetTexture write SetTexture stored IsTextureStored;
    property TextureSeparator: TACLResourceTexture index 5 read GetTexture write SetTexture stored IsTextureStored;
  end;

  { TACLPopupMenuOptions }

  TACLPopupMenuScrollMode = (smAuto, smScrollButtons, smScrollBars);

  TACLPopupMenuOptions = class(TPersistent)
  strict private
    FCloseMenuOnItemCheck: Boolean;
    FScrollMode: TACLPopupMenuScrollMode;
  public
    procedure AfterConstruction; override;
    procedure Assign(Source: TPersistent); override;
  published
    property CloseMenuOnItemCheck: Boolean
      read FCloseMenuOnItemCheck write FCloseMenuOnItemCheck default True;
    property ScrollMode: TACLPopupMenuScrollMode
      read FScrollMode write FScrollMode default smAuto;
  end;

  { TACLPopupMenuStyle }

  TACLPopupMenuStyle = class(TACLStylePopupMenu)
  strict private
    FAllowTextFormatting: Boolean;
  protected
    procedure DoAssign(Source: TPersistent); override;
    procedure DoReset; override;
  public
    procedure DrawText(ACanvas: TCanvas; ARect: TRect; const AText: string); override;
  published
    property AllowTextFormatting: Boolean read
      FAllowTextFormatting write FAllowTextFormatting default False;
  end;

  { TACLPopupMenu }

  TACLPopupMenuClass = class of TACLPopupMenu;
  TACLPopupMenu = class(TPopupMenu,
    IACLCurrentDPI,
    IACLMenuShowHandler,
    IACLObjectLinksSupport,
    IACLPopup)
  strict private
    FAutoScale: Boolean;
    FCurrentDpi: Integer;
    FHint: string;
    FOptions: TACLPopupMenuOptions;
    FPopupWindow: TObject;
    FStyle: TACLPopupMenuStyle;

    function GetIsShown: Boolean;
    procedure SetOptions(AValue: TACLPopupMenuOptions);
    procedure SetStyle(AValue: TACLPopupMenuStyle);
    // IACLCurrentDPI
    function GetCurrentDpi: Integer;
    // IACLMenuShowHandler
    procedure IACLMenuShowHandler.OnShow = DoInitialize;
  protected
    function CalculateTargetDpi: Integer; virtual;
    function CreateOptions: TACLPopupMenuOptions; virtual;
    function CreateStyle: TACLPopupMenuStyle; virtual;
    procedure DoInitialize; virtual;
    procedure DoDpiChanged; virtual;
    procedure DoSelect(Item: TMenuItem); virtual;
    procedure DoShow(const ControlRect: TRect); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    function CreateMenuItem: TMenuItem; {$IFNDEF FPC}override;{$ENDIF}
    procedure ScaleForDpi(ATargetDpi: Integer);
    procedure Popup(const P: TPoint); reintroduce; overload;
    procedure Popup(X, Y: Integer); overload; override;
    // IACLPopup
    procedure PopupUnderControl(const ControlRect: TRect);

    property CurrentDpi: Integer read GetCurrentDpi;
    property IsShown: Boolean read GetIsShown;
  published
    property AutoScale: Boolean read FAutoScale write FAutoScale default True;
    property Hint: string read FHint write FHint;
    property Options: TACLPopupMenuOptions read FOptions write SetOptions;
    property Style: TACLPopupMenuStyle read FStyle write SetStyle;
  end;

{$ENDREGION}

{$REGION ' Internal Classes '}

  TACLMenuPopupWindow = class;

  TACLMenuWindow = class(TCustomControl, IACLMouseTracking)
  {$REGION ' Internal Types '}
  protected const
    HitTestNoWhere  = -1;
    HitTestScroller = -2;
  protected type
    TItemInfo = class
    public
      Item: TMenuItem;
      Rect: TRect;
      Size: TSize;
    end;
  {$ENDREGION}
  strict private
    FItems: TACLObjectList<TItemInfo>;
    FPrevMousePos: TPoint;
    FSelectedItemIndex: Integer;
    FTopIndex: Integer;

    function GetSelectedItemInfo: TItemInfo;
    procedure SetTopIndex(AValue: Integer);
  protected
    FPadding: TRect;
    FVisibleItemCount: Integer;

    function CalculateAutoSize: TSize; virtual; abstract;
    procedure CalculateLayout; virtual; abstract;
    procedure CalculateMetrics; virtual;
    function CalculatePopupBounds(ASize: TSize;
      AChild: TACLMenuPopupWindow = nil): TRect; virtual; abstract;
    function CalculateSize(ACanvas: TCanvas; AItem: TMenuItem): TSize; virtual; abstract;

    // Keyboard
    procedure KeyChar(var Key: Word);
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function TranslateKey(Key: Word; Shift: TShiftState): Word; virtual;

    // Mouse
    function DoMouseWheel(Shift: TShiftState; Delta: Integer; P: TPoint): Boolean; override;
    function HitTest(const P: TPoint): Integer;
    function IsMouseAtControl: Boolean;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; reintroduce; virtual;
    procedure MouseLeave; reintroduce; virtual;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure UpdateMouseMove;

    // Navigation
    procedure ClickOnSelection(AActionType: TACLControlActionType); virtual;
    procedure EnsureItemVisible(AItemIndex: Integer);
    procedure SelectItem(AItemIndex: Integer; AActionType: TACLControlActionType);
    procedure SelectItemOnMouseMove(AItemIndex: Integer); virtual;
    procedure SelectNextItem(AGoForward: Boolean);

    // Data
    procedure AddMenuItem(AMenuItem: TMenuItem);
    function GetCurrentDpi: Integer; virtual;
    function HasSelection: Boolean;
    function HasSubItems(AItem: TMenuItem): Boolean;
    procedure Init(ASource: TMenuItem);

    property Items: TACLObjectList<TItemInfo> read FItems;
    property SelectedItemIndex: Integer read FSelectedItemIndex;
    property SelectedItemInfo: TItemInfo read GetSelectedItemInfo;
    property TopIndex: Integer read FTopIndex write SetTopIndex;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { TACLMenuPopupLooper }

  TACLMenuPopupLooper = class
  strict private
    FDelayTimer: TACLTimer;
    FDelayWnd: TACLMenuPopupWindow;
    FDelayWndIndex: Integer;
    FForm: TCustomForm;
    FInGrabbing: Boolean;
    FInLoop: Boolean;
    FPopups: TObjectStack<TACLMenuPopupWindow>;
    FPostponedClosure: TACLMenuPopupWindow;
    FPostponedSelection: TMenuItem;
    FWnd: TACLMenuPopupWindow;

    procedure DoGrabInput;
    procedure DoShowPopupDelayed(Sender: TObject);
    function DoShowPopup(AWnd: TACLMenuPopupWindow): Boolean;
    function GetMenuHint(AItem: TMenuItem): string;
    function IsInStack(const AInfo: TACLMenuWindow.TItemInfo): Boolean;
    procedure UpdateSelection(AWnd: TACLMenuPopupWindow);
  strict protected
    procedure DoCloseMenu(AWnd: TACLMenuPopupWindow = nil);
    procedure DoIdle; virtual;
    function IsInLoop: Boolean;
  protected
    procedure CloseMenu(AWnd: TACLMenuPopupWindow = nil);
    procedure CloseMenuOnSelect(AItem: TMenuItem);
    function PopupWindowAtCursor: TACLMenuPopupWindow;
    function WndProc(AWnd: TACLMenuPopupWindow; var AMsg: TMessage): Boolean; virtual;
  public
    constructor Create(AOwner: TACLMenuPopupWindow); virtual;
    destructor Destroy; override;
    procedure Run; virtual; abstract;
    //# Properties
    property Popups: TObjectStack<TACLMenuPopupWindow> read FPopups;
    property Wnd: TACLMenuPopupWindow read FWnd;
  end;

  { TACLMenuPopupWindow }

  TACLMenuPopupWindow = class(TACLMenuWindow, IACLScrollBar)
  strict private
    FControlRect: TRect;
    FLooper: TACLMenuPopupLooper;
    FMainMenu: TACLMenuWindow;
    FParent: TACLMenuPopupWindow;
    FSource: TACLPopupMenu;
    FSourceItem: TACLMenuWindow.TItemInfo;
    // Scrollers
    FScrollBar: TACLScrollBarSubClass;
    FScrollBarStyle: TACLStyleScrollBox;
    FScrollButtonDown: TRect;
    FScrollButtonRestArea: TRect;
    FScrollButtonUp: TRect;
    FScrollTimer: TACLTimer;

    function AllowFading: Boolean;
    function CanCloseMenuOnItemClick(AItem: TMenuItem): Boolean;
    function GetStyle: TACLPopupMenuStyle;
    function GetTargetMenuWnd(out AWnd: TACLMenuWindow; var X, Y: Integer): Boolean;
    //# Scrollers
    procedure CheckScrollTimer(const P: TPoint);
    function HasScrollers: Boolean;
    procedure Scroll(ACode: TScrollCode; var APosition: Integer);
    procedure ScrollTimer(Sender: TObject);
  protected
  {$IFDEF FPC}
    class procedure WSRegisterClass; override;
  {$ENDIF}
  protected
    function CalculateAutoSize: TSize; override;
    procedure CalculateBounds;
    procedure CalculateLayout; override;
    procedure CalculateMetrics; override;
    procedure CalculateScrollers(var R: TRect);
    function CalculatePopupBounds(ASize: TSize;
      AChild: TACLMenuPopupWindow = nil): TRect; override;
    function CalculateSize(ACanvas: TCanvas; AItem: TMenuItem): TSize; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    function GetCurrentDpi: Integer; override;
    procedure Resize; override;

    //# Popup
    procedure Paint; override;
    procedure PaintScroller;

    // Navigation
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure SelectItemOnMouseMove(AItemIndex: Integer); override;

    // # Messages
    procedure CMMenuClicked(var Message: TMessage); message CM_MENUCLICKED;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AMainMenu: TACLMenuWindow; ASource: TACLPopupMenu;
      AItem: TACLMenuWindow.TItemInfo); reintroduce; overload;
    constructor Create(AParent: TACLMenuPopupWindow;
      AItem: TACLMenuWindow.TItemInfo); reintroduce; overload;
    constructor Create(ASource: TACLPopupMenu); reintroduce; overload;
    destructor Destroy; override;
    procedure InvalidateRect(const R: TRect);
    procedure Popup(const AControlRect: TRect);
    //# Properties
    property Looper: TACLMenuPopupLooper read FLooper;
    property Parent: TACLMenuPopupWindow read FParent;
    property MainMenu: TACLMenuWindow read FMainMenu;
    property Source: TACLPopupMenu read FSource;
    property SourceItem: TACLMenuWindow.TItemInfo read FSourceItem;
    property Style: TACLPopupMenuStyle read GetStyle;
  end;

{$ENDREGION}

{$REGION ' Main Menu '}

  { TACLMainMenu }

  TACLMainMenu = class(TACLMenuWindow, IACLLocalizableComponent)
  strict private
    FMenu: TACLPopupMenu;
    FPopupOnSelect: Boolean;
    FPopupWnd: TACLMenuPopupWindow;
    FStyle: TACLStyleMenu;

    procedure DoMenuChange(Sender: TObject; Source: TMenuItem; Rebuild: Boolean);
    function HasGlyph(AItem: TMenuItem): Boolean;
    function IsInPopupMode: Boolean;
    procedure SetMenu(AValue: TACLPopupMenu);
    procedure SetStyle(AValue: TACLStyleMenu);
  protected
    //# Calculate
    function CalculateAutoSize: TSize; override;
    procedure CalculateLayout; override;
    function CalculatePopupBounds(ASize: TSize;
      AChild: TACLMenuPopupWindow = nil): TRect; override;
    function CalculateSize(ACanvas: TCanvas; AItem: TMenuItem): TSize; override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;

    //# Navigation
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure SelectItemOnMouseMove(AItemIndex: Integer); override;
    function TranslateKey(Key: Word; Shift: TShiftState): Word; override;

    //# General
    procedure ChangeScale(M, D: Integer{$IFNDEF FPC}; isDpiChange: Boolean{$ENDIF}); override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure Paint; override;
    procedure PaintItem(AItem: TACLMenuWindow.TItemInfo; ASelected: Boolean);

    //# Messages
    procedure CMExit(var Message: TMessage); message CM_EXIT;
    procedure CMMenuClicked(var Message: TMessage); message CM_MENUCLICKED;
    procedure CMMenuSelected(var Message: TMessage); message CM_MENUSELECTED;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  {$IFNDEF FPC}
    procedure WMSysCommand(var Message: TWMSysCommand); message WM_SYSCOMMAND;
  {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdjustSize; override;
    procedure CheckShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure Rebuild;
    // IACLLocalizableComponent
    procedure Localize(const ASection: string);
  published
    property Menu: TACLPopupMenu read FMenu write SetMenu;
    property Style: TACLStyleMenu read FStyle write SetStyle;
  end;

{$ENDREGION}

function acMenuEscapeHotkeys(const ACaption: string): string;
function acMenusHasActivePopup: Boolean;
implementation

uses
{$IFDEF LCLGtk2}
  ACL.UI.Application.Gtk2,
  Gdk2,
{$ENDIF}
{$IFDEF FPC}
  WSLCLClasses;
{$ELSE}
  ACL.Graphics.SkinImageSet; // inlining
{$ENDIF}

type
{$IFDEF MSWINDOWS}

  TACLMenuPopupLooperImpl = class(TACLMenuPopupLooper)
  strict private
    FActionIdleTimer: TACLTimer;
  strict protected
    procedure DoActionIdle;
    procedure DoActionIdleTimerProc(Sender: TObject);
    procedure DoIdle; override;
  public
    constructor Create(AOwner: TACLMenuPopupWindow); override;
    destructor Destroy; override;
    procedure Run; override;
  end;

{$ELSE IFDEF(LCLGtk2)}

  { TACLMenuPopupLooperImpl }

  TACLMenuPopupLooperImpl = class(TACLMenuPopupLooper)
  strict protected
    procedure DoEvent(AEvent: PGdkEvent; var AHandled: Boolean);
    procedure DoIdle; override;
  protected
    function WndProc(AWnd: TACLMenuPopupWindow; var AMsg: TMessage): Boolean; override;
  public
    procedure Run; override;
  end;

{$ENDIF}

var
  FMenuLoopCount: Integer;

function acMenuEscapeHotkeys(const ACaption: string): string;
begin
  Result := acStringReplace(ACaption, cHotkeyPrefix, cHotkeyPrefix + cHotkeyPrefix);
end;

function acMenusHasActivePopup: Boolean;
begin
  Result := FMenuLoopCount > 0;
end;

{$REGION ' Helpers '}

{ TMenuItemHelper }

function TMenuItemHelper.AddItem(const ACaption, AHint: string;
  ATag: NativeInt; AEvent: TNotifyEvent; AShortCut: TShortCut): TMenuItem;
begin
  Result := TMenuItem.Create(Self);
  Result.ShortCut := AShortCut;
  Result.Caption := ACaption;
  Result.OnClick := AEvent;
  Result.Tag := ATag;
  Result.Hint := AHint;
  Add(Result);
end;

function TMenuItemHelper.AddItem(const ACaption: string;
  AEvent: TNotifyEvent = nil; AShortCut: TShortCut = 0): TMenuItem;
begin
  Result := AddItem(ACaption, 0, AEvent, AShortCut);
end;

function TMenuItemHelper.AddItem(const ACaption: string;
  ATag: NativeInt; AEvent: TNotifyEvent = nil; AShortCut: TShortCut = 0): TMenuItem;
begin
  Result := AddItem(ACaption, '', ATag, AEvent, AShortCut);
end;

function TMenuItemHelper.AddLink(const AMenuItemOrMenu: TComponent): TACLMenuItemLink;
begin
  Result := TACLMenuItemLink.Create(Self);
  Result.Link := AMenuItemOrMenu;
  Add(Result);
end;

function TMenuItemHelper.AddRadioItem(const ACaption, AHint: string;
  ATag: NativeInt; AEvent: TNotifyEvent; AGroupIndex: Integer;
  AShortCut: TShortCut): TMenuItem;
begin
  Result := AddItem(ACaption, AHint, Atag, AEvent, AShortCut);
  Result.RadioItem := True;
  Result.GroupIndex := AGroupIndex;
end;

function TMenuItemHelper.AddSeparator: TMenuItem;
begin
  Result := TMenuItem.Create(Self);
  Result.Caption := '-';
  Add(Result);
end;

function TMenuItemHelper.CanBeParent(AParent: TMenuItem): Boolean;
begin
  Result := True;
  while AParent <> nil do
  begin
    if AParent = Self then
      Exit(False);
    AParent := AParent.Parent;
  end;
end;

function TMenuItemHelper.FindByTag(const ATag: NativeInt): TMenuItem;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
  begin
    if Items[I].Tag = ATag then
      Exit(Items[I]);
  end;
  Result := nil;
end;

procedure TMenuItemHelper.DeleteWithTag(const ATag: NativeInt);
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
  begin
    if Items[I].Tag = ATag then
      Delete(I);
  end;
end;

function TMenuItemHelper.HasVisibleSubItems: Boolean;
var
  AItem: TMenuItem;
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    AItem := Items[I];
    if not AItem.IsLine and AItem.Visible then
      Exit(True);
  end;
  Result := False;
end;

procedure TMenuItemHelper.InitiateActions;
var
  I: Integer;
begin
  InitiateAction;
  for I := 0 to Count - 1 do
    Items[I].InitiateAction;
end;

function TMenuItemHelper.IsCheckable: Boolean;
var
  Intf: IACLMenuItemCheckable;
begin
  Result := Checked or AutoCheck or RadioItem or
    (QueryInterface(IACLMenuItemCheckable, Intf) = 0);
end;

procedure TMenuItemHelper.PrepareForShowing;
var
  AIntf: IACLMenuShowHandler;
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if Supports(Items[I], IACLMenuShowHandler, AIntf) then
      AIntf.OnShow;
  end;
end;

function TMenuItemHelper.GetDefaultItem: TMenuItem;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if Items[I].Default then
      Exit(Items[I]);
  end;
  Result := nil;
end;

function TMenuItemHelper.GetMenu: TMenu;
var
  AItem: TMenuItem;
begin
  AItem := Self;
  while AItem.Parent <> nil do
    AItem := AItem.Parent;

  if AItem.Owner is TMenu then
    Result := TMenu(AItem.Owner)
  else
    Result := nil;
end;

{$ENDREGION}

{$REGION ' General '}

{ TACLMenuItem }

constructor TACLMenuItem.Create(AOwner: TComponent);
begin
  inherited;
  FGlyph := TACLGlyph.Create(Self);
end;

destructor TACLMenuItem.Destroy;
begin
  FreeAndNil(FGlyph);
  inherited Destroy;
end;

procedure TACLMenuItem.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TACLMenuItem then
    TACLMenuItem(Dest).Glyph := Glyph;
end;

procedure TACLMenuItem.DoShow;
begin
  CallNotifyEvent(Self, OnShow);
end;

function TACLMenuItem.GetCurrentDpi: Integer;
begin
  Result := acGetCurrentDpi(Menu);
end;

function TACLMenuItem.GetGlyph: TACLGlyph;
begin
  Result := FGlyph;
end;

function TACLMenuItem.HasSubItems: Boolean;
begin
  Result := Count > 0;
end;

function TACLMenuItem.IsGlyphStored: Boolean;
begin
  Result := not Glyph.Empty;
end;

procedure TACLMenuItem.SetGlyph(AValue: TACLGlyph);
begin
  FGlyph.Assign(AValue);
end;

function TACLMenuItem.ToString: string;
begin
  Result := Caption;
end;

{ TACLMenuContainerItem }

procedure TACLMenuContainerItem.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TACLMenuContainerItem then
    TACLMenuContainerItem(Dest).ExpandMode := ExpandMode;
end;

{ TACLMenuItemLink }

procedure TACLMenuItemLink.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TACLMenuItemLink then
    TACLMenuItemLink(Dest).Link := Link;
end;

destructor TACLMenuItemLink.Destroy;
begin
  Link := nil;
  inherited Destroy;
end;

procedure TACLMenuItemLink.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = Link) then
    Link := nil;
end;

procedure TACLMenuItemLink.DoShow;
var
  AHandler: IACLMenuShowHandler;
begin
  if Supports(Link, IACLMenuShowHandler, AHandler) then
  begin
    if (Link is TPopupMenu) and (Menu is TPopupMenu) then
    begin
      TPopupMenu(Link).PopupComponent := TPopupMenu(Menu).PopupComponent;
      try
        AHandler.OnShow;
      finally
        TPopupMenu(Link).PopupComponent := nil;
      end;
    end
    else
      AHandler.OnShow;
  end;
  inherited DoShow;
end;

procedure TACLMenuItemLink.Expand(AProc: TMenuItemEnumProc);
var
  I: Integer;
begin
  if Enabled then
  begin
    if Link is TMenuItem then
      AProc(TMenuItem(Link))
    else
      if Link is TPopupMenu then
      begin
        TPopupMenu(Link).Items.PrepareForShowing;
        for I := 0 to TPopupMenu(Link).Items.Count - 1 do
          AProc(TPopupMenu(Link).Items[I]);
      end;
  end;
end;

function TACLMenuItemLink.HasSubItems: Boolean;
begin
  if Link is TMenuItem then
    Result := TMenuItem(Link).Visible
  else if Link is TPopupMenu then
    Result := TPopupMenu(Link).Items.HasVisibleSubItems
  else
    Result := False;
end;

procedure TACLMenuItemLink.SetLink(AValue: TComponent);
begin
  acComponentFieldSet(FLink, Self, AValue);
end;

function TACLMenuItemLink.ToString: string;
begin
  if Link <> nil then
    Result := '[' + Link.Name + ']'
  else
    Result := '[unassigned]';
end;

{ TACLMenuListItem }

constructor TACLMenuListItem.Create(AOwner: TComponent);
begin
  inherited;
  FItems := TStringList.Create;
  FItemIndex := -1;
end;

destructor TACLMenuListItem.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

procedure TACLMenuListItem.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TACLMenuListItem then
  begin
    TACLMenuListItem(Dest).AutoCheck := AutoCheck;
    TACLMenuListItem(Dest).Items := Items;
    TACLMenuListItem(Dest).ItemIndex := ItemIndex;
  end;
end;

procedure TACLMenuListItem.Click;
begin
  // do nothing
end;

procedure TACLMenuListItem.Expand(AProc: TMenuItemEnumProc);
var
  AItem: TMenuItem;
  I: Integer;
begin
  while Count > 0 do
    Delete(0);
  for I := 0 to Items.Count - 1 do
  begin
    AItem := AddItem(Items[I], I, HandlerItemClick);
    if AutoCheck then
    begin
      AItem.Checked := I = ItemIndex;
      AItem.RadioItem := True;
    end;
    AProc(AItem);
  end;
end;

procedure TACLMenuListItem.HandlerItemClick(Sender: TObject);
begin
  ItemIndex := TMenuItem(Sender).Tag;
  inherited Click;
end;

function TACLMenuListItem.HasSubItems: Boolean;
begin
  Result := Items.Count > 0;
end;

procedure TACLMenuListItem.SetItems(AValue: TStrings);
begin
  FItems.Assign(AValue);
end;

function TACLMenuListItem.ToString: string;
begin
  Result := '(' + IfThenW(Caption, 'list') + ')';
end;

{ TACLStyleMenu }

procedure TACLStyleMenu.AfterConstruction;
begin
  inherited;
  FItemHeight := -1;
end;

procedure TACLStyleMenu.AssignFontParams(ACanvas: TCanvas; ASelected, AIsDefault, AEnabled: Boolean);
begin
  if not AEnabled then
    ACanvas.Font.Assign(FontDisabled)
  else if ASelected then
    ACanvas.Font.Assign(FontSelected)
  else
    ACanvas.Font.Assign(Font);

  if AIsDefault then
    ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
  ACanvas.Brush.Style := bsClear;
end;

function TACLStyleMenu.CalculateItemHeight: Integer;
begin
  AssignFontParams(MeasureCanvas, False, True, True);
  Result := 2 * GetTextIdent + acFontHeight(MeasureCanvas);
  Result := Max(Result, Scale(GlyphSize) + acTextIndent); // глифы
  if Odd(Result) then
    Inc(Result);
end;

procedure TACLStyleMenu.DoChanged(AChanges: TACLPersistentChanges);
begin
  FItemHeight := -1;
  inherited;
end;

procedure TACLStyleMenu.DoDrawImage(ACanvas: TCanvas; const ARect: TRect;
  AImages: TCustomImageList; AImageIndex: Integer; AEnabled, ASelected: Boolean);
begin
  acDrawImage(ACanvas, ARect, AImages, AImageIndex, AEnabled);
end;

procedure TACLStyleMenu.DrawBackground(ACanvas: TCanvas; const R: TRect; ASelected: Boolean);
begin
  if ASelected then
    acFillRect(ACanvas, R, ColorItemSelected.AsColor)
  else
    acFillRect(ACanvas, R, ColorItem.AsColor);

  Texture.Draw(ACanvas, R, Ord(ASelected));
end;

procedure TACLStyleMenu.DrawItemImage(ACanvas: TCanvas;
  ARect: TRect; AItem: TMenuItem; ASelected: Boolean);
var
  AClipRegion: HRGN;
  AGlyph: TACLGlyph;
  AImages: TCustomImageList;
  AIntf: IACLGlyph;
begin
  if not acRectVisible(ACanvas, ARect) then Exit;

  AClipRegion := acSaveClipRegion(ACanvas.Handle);
  try
    acIntersectClipRegion(ACanvas.Handle, ARect);
    // DPI aware Glyph
    if Supports(AItem, IACLGlyph, AIntf) and not AIntf.GetGlyph.Empty then
    begin
      AGlyph := AIntf.GetGlyph;
      AGlyph.TargetDPI := TargetDPI;
      ARect.Center(AGlyph.FrameSize);
      AGlyph.Draw(ACanvas, ARect, AItem.Enabled);
    end
    else

    // VCL Glyph
    if not AItem.Bitmap.Empty then
    begin
      AGlyph := TACLGlyph.Create(nil);
      try
        AGlyph.ImportFromImage(AItem.Bitmap, acDefaultDPI);
        AGlyph.TargetDPI := TargetDPI;
        ARect.Center(AGlyph.FrameSize);
        AGlyph.Draw(ACanvas, ARect, AItem.Enabled);
      finally
        AGlyph.Free;
      end;
    end
    else

    // ImageList
    begin
      AImages := AItem.GetImageList;
      if (AImages <> nil) and (AItem.ImageIndex >= 0) then
      begin
        ARect.Center(acGetImageListSize(AImages, TargetDPI));
        DoDrawImage(ACanvas, ARect, AImages, AItem.ImageIndex, AItem.Enabled, ASelected);
      end;
    end;
  finally
    acRestoreClipRegion(ACanvas.Handle, AClipRegion);
  end;
end;

procedure TACLStyleMenu.DrawText(ACanvas: TCanvas; ARect: TRect; const AText: string);
begin
  acSysDrawText(ACanvas, ARect, AText, DT_SINGLELINE or DT_VCENTER);
end;

function TACLStyleMenu.GetItemHeight: Integer;
begin
  if FItemHeight < 0 then
    FItemHeight := CalculateItemHeight;
  Result := FItemHeight;
end;

function TACLStyleMenu.GetTextIdent: Integer;
begin
  Result := 2 * Scale(acTextIndent);
end;

procedure TACLStyleMenu.InitializeResources;
begin
  ColorItem.InitailizeDefaults('Popup.Colors.Item', TAlphaColor.None);
  ColorItemSelected.InitailizeDefaults('Popup.Colors.ItemSelected', TAlphaColor.None);
  Font.InitailizeDefaults('Popup.Fonts.Default');
  FontDisabled.InitailizeDefaults('Popup.Fonts.Disabled');
  FontSelected.InitailizeDefaults('Popup.Fonts.Selected');
  Texture.InitailizeDefaults('Popup.Textures.General');
end;

function TACLStyleMenu.MeasureWidth(ACanvas: TCanvas;
  const S: string; AShortCut: TShortCut; ADefault: Boolean): Integer;
begin
  AssignFontParams(ACanvas, True, ADefault, True);
  Result := 2 * GetTextIdent + acTextSize(ACanvas, StripHotkey(S)).Width;
end;

{$ENDREGION}

{$REGION ' PopupMenu '}

{ TACLStylePopupMenu }

function TACLStylePopupMenu.CalculateItemHeight: Integer;
begin
  Result := Texture.FrameHeight;
  if Result = 0 then
  begin
    AssignFontParams(MeasureCanvas, False, True, True);
    Result := Max(2 * GetTextIdent + acFontHeight(MeasureCanvas), TextureGutter.FrameHeight);
  end;
end;

procedure TACLStylePopupMenu.DrawCheckMark(
  ACanvas: TCanvas; const R: TRect; AChecked, AIsRadioItem, ASelected: Boolean);

  function GetStateRect(const R: TRect; ATexture: TACLResourceTexture): TRect;
  begin
    Result := R;
    Result.Width := ItemGutterWidth;
    Result.Center(ATexture.FrameSize);
  end;

const
  Indexes: array[Boolean, Boolean] of Integer = ((6, 2), (8, 4));
  NameMap: array[Boolean] of string = ('Buttons.Textures.CheckBox', 'Buttons.Textures.RadioBox');
var
  AClipRegion: HRGN;
  AImageIndex: Integer;
  APrevTargetDPI: Integer;
  ATexture: TACLResourceTexture;
begin
  AClipRegion := acSaveClipRegion(ACanvas.Handle);
  try
    acIntersectClipRegion(ACanvas.Handle, R);
    // for backward compatibility with skins for AIMP3.
    if TextureGutter.FrameCount = 2 then
    begin
      ATexture := TACLResourceTexture(GetResource(NameMap[AIsRadioItem], TACLResourceTexture));
      if ATexture <> nil then
      begin
        ATexture.BeginUpdate;
        try
          APrevTargetDPI := ATexture.TargetDPI;
          try
            ATexture.TargetDPI := TargetDPI;
            ATexture.Draw(ACanvas, GetStateRect(R, ATexture), Ord(AChecked) * 5 + Ord(ASelected));
          finally
            ATexture.TargetDPI := APrevTargetDPI;
          end;
        finally
          ATexture.CancelUpdate;
        end;
      end;
    end
    else
    begin
      AImageIndex := Indexes[AIsRadioItem, AChecked] + Ord(ASelected);
      if AImageIndex < TextureGutter.FrameCount then
        TextureGutter.Draw(ACanvas, GetStateRect(R, TextureGutter), AImageIndex);
    end;
  finally
    acRestoreClipRegion(ACanvas.Handle, AClipRegion);
  end;
end;

procedure TACLStylePopupMenu.DoSplitRect(const R: TRect;
  AGutterWidth: Integer; out AGutterRect, AContentRect: TRect);
begin
  AGutterRect := R;
  AGutterRect.Width := AGutterWidth;
  AContentRect := R;
  AContentRect.Left := AGutterRect.Right;
end;

procedure TACLStylePopupMenu.DrawBackground(
  ACanvas: TCanvas; const R: TRect; ASelected: Boolean);
var
  AContentRect: TRect;
  AGutterRect: TRect;
begin
  inherited;
  DoSplitRect(R, ItemGutterWidth, AGutterRect, AContentRect);
  TextureGutter.Draw(ACanvas, AGutterRect, Ord(ASelected));
end;

procedure TACLStylePopupMenu.DrawBorder(ACanvas: TCanvas; const R: TRect);
var
  LRadius: Integer;
begin
  ACanvas.Pen.Color := ColorBorder1.AsColor;
  if ColorBorder2.IsEmpty then
    ACanvas.Brush.Color := ColorBorder1.AsColor
  else
    ACanvas.Brush.Color := ColorBorder2.AsColor;

  LRadius := 2 * CornerRadius.Value;
  if LRadius > 0 then
    ACanvas.RoundRect(R, LRadius, LRadius)
  else
    ACanvas.Rectangle(R);
end;

procedure TACLStylePopupMenu.DrawScrollButton(
  ACanvas: TCanvas; const R: TRect; AUp, AEnabled: Boolean);
const
  ScrollButtonMap: array[Boolean] of TACLArrowKind = (makBottom, makTop);
begin
  AssignFontParams(ACanvas, False, False, AEnabled);
  acDrawArrow(ACanvas, R, acGetActualColor(ACanvas.Font), ScrollButtonMap[AUp], TargetDPI);
end;

procedure TACLStylePopupMenu.DrawSeparator(ACanvas: TCanvas; const R: TRect);
var
  ALayer: TACLDib;
  ADstC, ADstG: TRect;
  ASrcC, ASrcG: TRect;
begin
  if TextureSeparator.ImageDpi <> acDefaultDpi then
  begin
    ALayer := TACLDib.Create(
      TextureGutter.Image.Width + TextureSeparator.Image.Width,
      TextureSeparator.Image.Height);
    try
      acFillRect(ALayer.Canvas, ALayer.ClientRect, ColorItem.AsColor);
      TextureSeparator.Draw(ALayer.Canvas, ALayer.ClientRect);
      DoSplitRect(ALayer.ClientRect, TextureGutter.Image.Width, ASrcG, ASrcC);
      DoSplitRect(R, ItemGutterWidth, ADstG, ADstC);
      ALayer.DrawBlend(ACanvas, ADstG, ASrcG, MaxByte);
      ALayer.DrawBlend(ACanvas, ADstC, ASrcC, MaxByte);
    finally
      ALayer.Free;
    end;
  end
  else
  begin
    acFillRect(ACanvas, R, ColorItem.AsColor);
    TextureSeparator.Draw(ACanvas, R, 0);
  end;
end;

procedure TACLStylePopupMenu.DrawItem(ACanvas: TCanvas; R: TRect; const S: string;
  AShortCut: TShortCut; ASelected, AIsDefault, AEnabled, AHasSubItems: Boolean);
begin
  Inc(R.Left, ItemGutterWidth);
  R.Inflate(-GetTextIdent, 0);
  AssignFontParams(ACanvas, ASelected, AIsDefault, AEnabled);
  DrawText(ACanvas, R, S);
  if AHasSubItems then
    acDrawArrow(ACanvas, R.Split(srRight, R.Height), acGetActualColor(ACanvas.Font), makRight, TargetDPI)
  else
    if AShortCut <> scNone then
      acTextDraw(ACanvas, ShortCutToText(AShortCut), R, taRightJustify, taVerticalCenter);
end;

procedure TACLStylePopupMenu.DrawItemImage(
  ACanvas: TCanvas; ARect: TRect; AItem: TMenuItem; ASelected: Boolean);
begin
  if AItem.IsCheckable then
    DrawCheckMark(ACanvas, ARect, AItem.Checked, AItem.RadioItem, ASelected)
  else
    inherited;
end;

procedure TACLStylePopupMenu.InitializeResources;
begin
  inherited;
  Borders.InitailizeDefaults('Popup.Margins.Borders', acBorderOffsets);
  CornerRadius.InitailizeDefaults('Popup.Margins.CornerRadius', 0);
  ColorBorder1.InitailizeDefaults('Popup.Colors.Border1');
  ColorBorder2.InitailizeDefaults('Popup.Colors.Border2');
  TextureGutter.InitailizeDefaults('Popup.Textures.Gutter');
  TextureSeparator.InitailizeDefaults('Popup.Textures.Separator');
  TextureScrollBar.InitailizeDefaults('Popup.Textures.ScrollBar');
  TextureScrollBarButtons.InitailizeDefaults('Popup.Textures.ScrollBarButtons');
  TextureScrollBarThumb.InitailizeDefaults('Popup.Textures.ScrollBarThumb');
end;

function TACLStylePopupMenu.MeasureWidth(ACanvas: TCanvas;
  const S: string; AShortCut: TShortCut; ADefault: Boolean): Integer;
begin
  Result := inherited + ItemGutterWidth + ItemHeight;
  if AShortCut <> scNone then
  begin
    Inc(Result, acTextSize(ACanvas, '  ').Width);
    Inc(Result, acTextSize(ACanvas, ShortCutToText(AShortCut)).Width);
  end;
end;

function TACLStylePopupMenu.GetItemGutterWidth: Integer;
begin
  Result := TextureGutter.FrameWidth;
end;

function TACLStylePopupMenu.GetSeparatorHeight: Integer;
begin
  Result := TextureSeparator.FrameHeight;
end;

{ TACLPopupMenuOptions }

procedure TACLPopupMenuOptions.AfterConstruction;
begin
  inherited;
  FCloseMenuOnItemCheck := True;
end;

procedure TACLPopupMenuOptions.Assign(Source: TPersistent);
begin
  if Source is TACLPopupMenuOptions then
    CloseMenuOnItemCheck := TACLPopupMenuOptions(Source).CloseMenuOnItemCheck;
end;

{ TACLPopupMenuStyle }

procedure TACLPopupMenuStyle.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);
  if Source is TACLPopupMenuStyle then
    AllowTextFormatting := TACLPopupMenuStyle(Source).AllowTextFormatting;
end;

procedure TACLPopupMenuStyle.DrawText(ACanvas: TCanvas; ARect: TRect; const AText: string);
begin
  if AllowTextFormatting then
    acDrawFormattedText(ACanvas, StripHotkey(AText), ARect, taLeftJustify, taVerticalCenter, False)
  else
    inherited;
end;

procedure TACLPopupMenuStyle.DoReset;
begin
  inherited DoReset;
  AllowTextFormatting := False;
end;

{ TACLPopupMenu }

constructor TACLPopupMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoScale := True;
  FOptions := TACLPopupMenuOptions.Create;
  FStyle := CreateStyle;
end;

destructor TACLPopupMenu.Destroy;
begin
  FreeAndNil(FOptions);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLPopupMenu.BeforeDestruction;
begin
  inherited BeforeDestruction;
  TACLMainThread.Unsubscribe(Self);
  RemoveFreeNotifications; // must be before PopupComponent := nil;
  PopupComponent := nil;
  TACLObjectLinks.Release(Self);
end;

function TACLPopupMenu.CalculateTargetDpi: Integer;
begin
  Result := acTryGetCurrentDpi(PopupComponent);
  if Result = 0 then
    Result := acTryGetCurrentDpi(Owner);
  if Result = 0 then
    Result := acGetTargetDPI(PopupPoint);
end;

function TACLPopupMenu.CreateMenuItem: TMenuItem;
begin
  Result := TACLMenuItem.Create(Self);
end;

procedure TACLPopupMenu.Popup(X, Y: Integer);
begin
  PopupUnderControl(Bounds(X, Y, 0, 0));
end;

procedure TACLPopupMenu.Popup(const P: TPoint);
begin
  Popup(P.X, P.Y);
end;

procedure TACLPopupMenu.PopupUnderControl(const ControlRect: TRect);
begin
  if not IsShown then
  begin
    ReleaseCapture;
  {$MESSAGE WARN 'SetPopupPoint'}
  {$IFNDEF FPC}
    SetPopupPoint(Point(ControlRect.Left, ControlRect.Bottom));
  {$ENDIF}
    DoInitialize;
    DoShow(ControlRect);
  end;
end;

function TACLPopupMenu.CreateOptions: TACLPopupMenuOptions;
begin
  Result := TACLPopupMenuOptions.Create;
end;

function TACLPopupMenu.CreateStyle: TACLPopupMenuStyle;
begin
  Result := TACLPopupMenuStyle.Create(Self);
end;

procedure TACLPopupMenu.DoInitialize;
var
  I: Integer;
begin
  DoPopup(Self);
  if AutoScale then
    ScaleForDpi(CalculateTargetDpi);
  for I := 0 to Items.Count - 1 do
    Items[I].InitiateAction;
end;

procedure TACLPopupMenu.DoDpiChanged;
begin
  Style.SetTargetDPI(CurrentDpi);
end;

procedure TACLPopupMenu.DoSelect(Item: TMenuItem);
begin
{$IFDEF FPC}
  TACLMainThread.RunPostponed(Item.Click, Self);
{$ELSE}
  PostMessage(PopupList.Window, WM_COMMAND, Item.Command, 0);
{$ENDIF}
end;

procedure TACLPopupMenu.DoShow(const ControlRect: TRect);
begin
  if not IsShown then
  try
    FPopupWindow := TACLMenuPopupWindow.Create(Self);
    try
      TACLMenuPopupWindow(FPopupWindow).Init(Items);
      TACLMenuPopupWindow(FPopupWindow).Popup(ControlRect);
    finally
      FreeAndNil(FPopupWindow);
//  Lose Focus: MyRefreshStayOnTop;
    end;
  finally
    DoClose;
  end;
end;

function TACLPopupMenu.GetCurrentDpi: Integer;
begin
  Result := FCurrentDpi;
end;

function TACLPopupMenu.GetIsShown: Boolean;
begin
  Result := Assigned(FPopupWindow);
end;

procedure TACLPopupMenu.SetOptions(AValue: TACLPopupMenuOptions);
begin
  FOptions.Assign(AValue);
end;

procedure TACLPopupMenu.SetStyle(AValue: TACLPopupMenuStyle);
begin
  FStyle.Assign(AValue);
end;

procedure TACLPopupMenu.ScaleForDpi(ATargetDpi: Integer);
begin
  if FCurrentDpi <> ATargetDpi then
  begin
    FCurrentDpi := ATargetDpi;
    DoDpiChanged;
  end;
end;

{$ENDREGION}

{$REGION ' Internal Classes '}

{ TACLMenuWindow }

constructor TACLMenuWindow.Create(AOwner: TComponent);
begin
  inherited;
  FSelectedItemIndex := -1;
  FItems := TACLObjectList<TItemInfo>.Create;
  DoubleBuffered := True;
end;

destructor TACLMenuWindow.Destroy;
begin
  MouseTracker.Remove(Self);
  FreeAndNil(FItems);
  inherited;
end;

procedure TACLMenuWindow.AddMenuItem(AMenuItem: TMenuItem);
var
  LContainer: TACLMenuContainerItem;
  LItem: TItemInfo;
begin
  if csDesigning in ComponentState then
    Exit;
  if not AMenuItem.Visible then
    Exit;
  if AMenuItem.IsLine and ((Items.Count = 0) or Items.Last.Item.IsLine) then
    Exit;
  if Safe.Cast(AMenuItem, TACLMenuContainerItem, LContainer) then
  begin
    if not LContainer.HasSubItems then
      Exit;
    if LContainer.ExpandMode = lemExpandInplace then
    begin
      if LContainer.Enabled then
        LContainer.Expand(AddMenuItem);
      Exit;
    end;
  end;
  LItem := TItemInfo.Create;
  LItem.Item := AMenuItem;
  LItem.Rect := NullRect;
  LItem.Size := NullSize;
  FItems.Add(LItem);
end;

procedure TACLMenuWindow.CalculateMetrics;
var
  I: Integer;
  LItem: TItemInfo;
begin
  MeasureCanvas.Font := Font;
  for I := 0 to Items.Count - 1 do
  begin
    LItem := Items.List[I];
    LItem.Size := CalculateSize(MeasureCanvas, LItem.Item);
  end;
end;

procedure TACLMenuWindow.ClickOnSelection(AActionType: TACLControlActionType);
var
  LAction: TCustomAction;
  LItem: TItemInfo;
begin
  LItem := SelectedItemInfo;
  if LItem = nil then
    Exit;
  if LItem.Item.IsLine then
    Exit;
  if LItem.Item.Enabled = False then
    Exit;
  if LItem.Item.Action is TCustomAction then
  begin
    LAction := TCustomAction(LItem.Item.Action);
    if (LAction.GroupIndex > 0) and not LAction.AutoCheck then
      LAction.Checked := True;
  end;
  PostMessage(Handle, CM_MENUCLICKED, Ord(AActionType), LPARAM(LItem.Item));
end;

procedure TACLMenuWindow.EnsureItemVisible(AItemIndex: Integer);
begin
  if (AItemIndex < 0) or (AItemIndex >= Items.Count) then
    Exit;
  while (AItemIndex < TopIndex) or (AItemIndex >= TopIndex + FVisibleItemCount) do
  begin
    if AItemIndex < TopIndex then
      TopIndex := AItemIndex
    else
      TopIndex := TopIndex - FVisibleItemCount + 1;
  end;
end;

procedure TACLMenuWindow.Init(ASource: TMenuItem);
var
  I: Integer;
begin
  Items.Clear;
  ASource.InitiateActions;
  if ASource.Enabled then
  begin
    ASource.PrepareForShowing;
    if (ASource is TACLMenuContainerItem) and
     (TACLMenuContainerItem(ASource).ExpandMode = lemExpandInSubMenu)
    then
      TACLMenuContainerItem(ASource).Expand(AddMenuItem)
    else
      for I := 0 to ASource.Count - 1 do
        AddMenuItem(ASource.Items[I]);

    if (Items.Count > 0) and Items.Last.Item.IsLine then
      Items.Delete(Items.Count - 1);
  end;
end;

procedure TACLMenuWindow.KeyChar(var Key: Word);
var
  I: Integer;
begin
  for I := 0 to Items.Count - 1 do
  begin
    if IsAccel(Key, Items.List[I].Item.Caption) then
    begin
      SelectItem(I, ccatKeyboard);
      if SelectedItemIndex = I then
        ClickOnSelection(ccatKeyboard);
      Key := 0;
      Break;
    end;
  end;
end;

procedure TACLMenuWindow.KeyDown(var Key: Word; Shift: TShiftState);
begin
  case TranslateKey(Key, Shift) of
    VK_HOME:
      SelectItem(0, ccatKeyboard);
    VK_END:
      SelectItem(Items.Count - 1, ccatKeyboard);
    VK_UP:
      SelectNextItem(False);
    VK_DOWN:
      SelectNextItem(True);
    VK_RETURN:
      ClickOnSelection(ccatKeyboard);
  end;
end;

function TACLMenuWindow.GetCurrentDpi: Integer;
begin
  Result := FCurrentPPI;
end;

function TACLMenuWindow.GetSelectedItemInfo: TItemInfo;
begin
  if HasSelection then
    Result := Items[SelectedItemIndex]
  else
    Result := nil;
end;

function TACLMenuWindow.HasSelection: Boolean;
begin
  Result := InRange(SelectedItemIndex, 0, Items.Count - 1);
end;

function TACLMenuWindow.HasSubItems(AItem: TMenuItem): Boolean;
var
  LContainer: TACLMenuContainerItem;
begin
  Result := (AItem.Count > 0) or
    (Safe.Cast(AItem, TACLMenuContainerItem, LContainer)) and
    (LContainer.ExpandMode = lemExpandInSubMenu);
end;

function TACLMenuWindow.IsMouseAtControl: Boolean;
begin
  Result := PtInRect(ClientRect, CalcCursorPos);
end;

function TACLMenuWindow.DoMouseWheel(Shift: TShiftState; Delta: Integer; P: TPoint): Boolean;
begin
  TopIndex := TopIndex + Signs[Delta < 0];
  UpdateMouseMove;
  Result := True;
end;

function TACLMenuWindow.HitTest(const P: TPoint): Integer;
var
  I: Integer;
begin
  for I := TopIndex to TopIndex + FVisibleItemCount - 1 do
  begin
    if Items.List[I].Rect.Contains(P) then
      Exit(I);
  end;
  Result := HitTestNoWhere;
end;

procedure TACLMenuWindow.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SelectItem(HitTest(Point(X, Y)), ccatMouse);
end;

procedure TACLMenuWindow.MouseEnter;
begin
  // do nothing
end;

procedure TACLMenuWindow.MouseLeave;
begin
  FPrevMousePos := InvalidPoint;
  SelectItemOnMouseMove(HitTestNoWhere);
end;

procedure TACLMenuWindow.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  MouseTracker.Add(Self);
  if FPrevMousePos <> Point(X, Y) then
  begin
    FPrevMousePos := Point(X, Y);
    if PtInRect(ClientRect, FPrevMousePos) then
      SelectItemOnMouseMove(HitTest(FPrevMousePos));
  end;
end;

procedure TACLMenuWindow.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if HasSelection and (HitTest(Point(X, Y)) = SelectedItemIndex) then
    ClickOnSelection(ccatMouse);
end;

procedure TACLMenuWindow.SelectItem(AItemIndex: Integer; AActionType: TACLControlActionType);
begin
  AItemIndex := EnsureRange(AItemIndex, -1, Items.Count - 1);
  if AItemIndex <> FSelectedItemIndex then
  begin
    FSelectedItemIndex := AItemIndex;
    EnsureItemVisible(SelectedItemIndex);
    if AActionType <> ccatNone then
      Perform(CM_MENUSELECTED, Ord(AActionType), SelectedItemIndex);
    Invalidate;
  end;
end;

procedure TACLMenuWindow.SelectItemOnMouseMove(AItemIndex: Integer);
begin
  SelectItem(AItemIndex, ccatMouse);
end;

procedure TACLMenuWindow.SelectNextItem(AGoForward: Boolean);
var
  LIndex: Integer;
  LLoop: Boolean;
begin
  LLoop := False;
  LIndex := SelectedItemIndex;
  repeat
    Inc(LIndex, Signs[AGoForward]);
    if not InRange(LIndex, 0, Items.Count - 1) then
    begin
      if LLoop then Break;
      LLoop := True;
      if LIndex >= Items.Count then
        LIndex := 0;
      if LIndex < 0 then
        LIndex := Items.Count - 1;
    end;
    if not Items[LIndex].Item.IsLine then
    begin
      SelectItem(LIndex, ccatKeyboard);
      Break;
    end;
  until False;
end;

procedure TACLMenuWindow.SetTopIndex(AValue: Integer);
begin
  AValue := MinMax(AValue, 0, Items.Count - FVisibleItemCount);
  if FTopIndex <> AValue then
  begin
    FTopIndex := AValue;
    CalculateLayout;
    Invalidate;
  end;
end;

function TACLMenuWindow.TranslateKey(Key: Word; Shift: TShiftState): Word;
begin
  Result := Key;
end;

procedure TACLMenuWindow.UpdateMouseMove;
begin
  FPrevMousePos := InvalidPoint;
  with CalcCursorPos do
    MouseMove([], X, Y);
end;

{ TACLMenuPopupWindow }

constructor TACLMenuPopupWindow.Create(ASource: TACLPopupMenu);
begin
  inherited Create(ASource);
  // Если у контрола нет флага csCaptureMouse - gtkMotionNotify не сгенерирует
  // событие, даже если capture была выставлена контролу вручную
  ControlStyle := []{$IFDEF FPC} + [csCaptureMouse]{$ENDIF};
  FScrollTimer := TACLTimer.CreateEx(ScrollTimer, 125);
  FSource := ASource;
  Visible := False;
  SetParent(Screen.FocusedForm);
end;

constructor TACLMenuPopupWindow.Create(
  AMainMenu: TACLMenuWindow; ASource: TACLPopupMenu;
  AItem: TACLMenuWindow.TItemInfo);
begin
  Create(ASource);
  FMainMenu := AMainMenu;
  FSourceItem := AItem;
  SetParent(MainMenu);
  Init(AItem.Item);
end;

constructor TACLMenuPopupWindow.Create(
  AParent: TACLMenuPopupWindow; AItem: TACLMenuWindow.TItemInfo);
begin
  Create(AParent.Source);
  FParent := AParent;
  FLooper := AParent.Looper;
  FSourceItem := AItem;
  SetParent(AParent);
  Init(AItem.Item);
end;

destructor TACLMenuPopupWindow.Destroy;
begin
  FreeAndNil(FScrollTimer);
  FreeAndNil(FScrollBar); // before
  FreeAndNil(FScrollBarStyle);
  inherited;
end;

function TACLMenuPopupWindow.AllowFading: Boolean;
begin
  Result := acUIFadingEnabled;
end;

function TACLMenuPopupWindow.CalculateAutoSize: TSize;
var
  I: Integer;
begin
  Result := NullSize;
  for I := 0 to Items.Count - 1 do
  begin
    with Items.List[I].Size do
    begin
      Result.cx := Max(Result.cx, cx);
      Result.cy := Result.cy + cy;
    end;
  end;
  if FScrollBar <> nil then
    Inc(Result.cx, FScrollBar.Bounds.Width);
  if not Result.IsEmpty then
  begin
    Inc(Result.cx, FPadding.MarginsWidth);
    Inc(Result.cy, FPadding.MarginsHeight);
  end;
{$IFDEF FPC}
  if Result.IsEmpty then
    Result.cy := 1; // null-size = default-size
{$ENDIF}
end;

procedure TACLMenuPopupWindow.CalculateBounds;
var
  LAutoSize: TSize;
  LHasScrollers: Boolean;
begin
  CalculateMetrics;
  repeat
    LHasScrollers := HasScrollers;
    LAutoSize := CalculateAutoSize;
    if Parent <> nil then
      BoundsRect := Parent.CalculatePopupBounds(LAutoSize, Self)
    else if MainMenu <> nil then
      BoundsRect := MainMenu.CalculatePopupBounds(LAutoSize, Self)
    else
      BoundsRect := CalculatePopupBounds(LAutoSize);
    CalculateLayout;
  until LHasScrollers = HasScrollers;
end;

procedure TACLMenuPopupWindow.CalculateLayout;
var
  LItem: TItemInfo;
  LRect: TRect;
  I: Integer;
begin
  LRect := ClientRect;
  LRect.Content(FPadding);
  CalculateScrollers(LRect);
  for I := 0 to TopIndex - 1 do
    Items.List[I].Rect := NullRect;

  FVisibleItemCount := 0;
  for I := TopIndex to Items.Count - 1 do
  begin
    LItem := Items.List[I];
    LItem.Rect := LRect;
    LItem.Rect.Height := LItem.Size.cy;
    LRect.Top := LItem.Rect.Bottom;
    if LRect.Top > LRect.Bottom then
    begin
      Dec(LRect.Top, LItem.Size.cy);
      Break;
    end;
    Inc(FVisibleItemCount);
  end;

  if LRect.IsEmpty then
    FScrollButtonRestArea := NullRect
  else
  begin
    FScrollButtonRestArea := LRect;
    FScrollButtonRestArea.Height := Style.ItemHeight;
  end;
end;

procedure TACLMenuPopupWindow.CalculateMetrics;
begin
  FPadding := dpiApply(Style.Borders.Value, GetCurrentDpi);
  inherited;
end;

function TACLMenuPopupWindow.CalculatePopupBounds(
  ASize: TSize; AChild: TACLMenuPopupWindow): TRect;
const
  ShadowOffset = 4;
var
  AParentRect: TRect;
  AWorkArea: TRect;
begin
  AWorkArea := MonitorGetWorkArea(ClientOrigin);
  if AChild <> nil then
  begin
    AParentRect := AChild.SourceItem.Rect + ClientOrigin;
    AParentRect.Offset(0, -FPadding.Top);
    Result.Left := AParentRect.Right;
    Result.Top := AParentRect.Top;
    if Result.Left + ASize.Width > AWorkArea.Right then
      Result.Left := AParentRect.Left - ASize.Width;
    if Result.Top + ASize.Height > AWorkArea.Bottom then
      Result.Top := AParentRect.Bottom - ASize.Height;
  end
  else
  begin
    Result := BoundsRect;
    if Result.Left + ASize.Width > AWorkArea.Right then
      Result.Left := AWorkArea.Right - ASize.Width;
    if Result.Top + ASize.Height > AWorkArea.Bottom then
    begin
      if FControlRect.IsEmpty then
        Result.Top := AWorkArea.Bottom - ASize.Height
      else if ((FControlRect.Top - AWorkArea.Top) > ASize.Height) then
        Result.Top := FControlRect.Top - ASize.Height - ShadowOffset
      else if ((FControlRect.Top - AWorkArea.Top) > (AWorkArea.Bottom - Result.Top)) or (Result.Top < FControlRect.Top) then
      begin
        Result.Top := AWorkArea.Top;
        ASize.cy := FControlRect.Top - AWorkArea.Top - ShadowOffset;
      end;
    end;
  end;
  Result.Top := Max(AWorkArea.Top, Result.Top);
  Result.Bottom := Min(Result.Top + ASize.Height, AWorkArea.Bottom);
  Result.Right := Result.Left + ASize.Width;
end;

procedure TACLMenuPopupWindow.CalculateScrollers(var R: TRect);
var
  AUseScrollButtons: Boolean;
begin
  if CalculateAutoSize.Height > Height then
  begin
    AUseScrollButtons :=
      (Source.Options.ScrollMode = smScrollButtons) or
      (Source.Options.ScrollMode = smAuto) and Style.TextureScrollBar.Empty;

    if AUseScrollButtons then
    begin
      FreeAndNil(FScrollBar);
      FreeAndNil(FScrollBarStyle);
      FScrollButtonDown := R;
      FScrollButtonDown.Height := Style.ItemHeight;
      FScrollButtonUp := R;
      FScrollButtonUp.Top := FScrollButtonUp.Bottom - Style.ItemHeight;
      R.Top := FScrollButtonDown.Bottom;
      R.Bottom := FScrollButtonUp.Top;
    end
    else
    begin
      if FScrollBar = nil then
      begin
        FScrollBarStyle := TACLStyleScrollBox.Create(Self);
        FScrollBarStyle.BeginUpdate;
        try
          FScrollBarStyle.Collection := Style.Collection;
          FScrollBarStyle.TextureBackgroundVert := Style.TextureScrollBar;
          FScrollBarStyle.TextureButtonsVert := Style.TextureScrollBarButtons;
          FScrollBarStyle.TextureThumbVert := Style.TextureScrollBarThumb;
          FScrollBarStyle.TargetDPI := GetCurrentDpi;
        finally
          FScrollBarStyle.EndUpdate;
        end;
        FScrollBar := TACLScrollBarSubClass.Create(Self, FScrollBarStyle, sbVertical);
      end;
      FScrollBar.Calculate(R.Split(srRight, FScrollBarStyle.GetScrollBarSize(sbVertical)));
      FScrollBar.SetScrollParams(0, Items.Count - 1, TopIndex, FVisibleItemCount);
      R.Right := FScrollBar.Bounds.Left;
    end;
  end
  else
    FreeAndNil(FScrollBar);
end;

function TACLMenuPopupWindow.CalculateSize(ACanvas: TCanvas; AItem: TMenuItem): TSize;
begin
  if AItem.IsLine then
    Result := TSize.Create(0, Style.SeparatorHeight)
  else
  begin
    Result.cx := Style.MeasureWidth(ACanvas, AItem.Caption, AItem.ShortCut, AItem.Default);
    Result.cy := Style.ItemHeight;
  end;
end;

function TACLMenuPopupWindow.CanCloseMenuOnItemClick(AItem: TMenuItem): Boolean;
begin
  Result := Source.Options.CloseMenuOnItemCheck or not AItem.AutoCheck;
end;

procedure TACLMenuPopupWindow.CheckScrollTimer(const P: TPoint);
begin
  if PtInRect(FScrollButtonUp, P) then
    FScrollTimer.Tag := 1
  else if PtInRect(FScrollButtonDown, P) then
    FScrollTimer.Tag := -1
  else
    FScrollTimer.Tag := 0;

  FScrollTimer.Enabled := FScrollTimer.Tag <> 0;
end;

procedure TACLMenuPopupWindow.CMMenuClicked(var Message: TMessage);
var
  LItem: TMenuItem;
begin
  LItem := TMenuItem(Message.LParam);
  if CanCloseMenuOnItemClick(LItem) then
    Looper.CloseMenuOnSelect(LItem)
  else
  begin
    Source.DoSelect(LItem);
    Invalidate;
  end;
end;

procedure TACLMenuPopupWindow.CreateParams(var Params: TCreateParams);
var
  LDropShadow: LongBool;
begin
  inherited;
  Params.Style := WS_POPUP;
  Params.ExStyle := Params.ExStyle or WS_EX_TOPMOST;
  if SystemParametersInfo(SPI_GETDROPSHADOW, 0, @LDropShadow, 0) and LDropShadow then
    Params.WindowClass.Style := Params.WindowClass.Style or CS_DROPSHADOW;
end;

procedure TACLMenuPopupWindow.CreateWnd;
begin
  inherited;
  FormSetCorners(Handle, afcRectangular);
end;

function TACLMenuPopupWindow.GetCurrentDpi: Integer;
begin
  if Parent <> nil then
    Result := Parent.GetCurrentDpi
  else
    Result := inherited;
end;

{$IFDEF FPC}
class procedure TACLMenuPopupWindow.WSRegisterClass;
begin
{$IFDEF LCLGtk2}
  RegisterWSComponent(Self, TGtk2PopupControl);
{$ELSE}
  inherited;
{$ENDIF}
end;
{$ENDIF}

function TACLMenuPopupWindow.GetTargetMenuWnd(
  out AWnd: TACLMenuWindow; var X, Y: Integer): Boolean;
var
  LPoint: TPoint;
begin
  AWnd := Looper.PopupWindowAtCursor;
  if (AWnd = nil) and (MainMenu <> nil) and MainMenu.IsMouseAtControl then
    AWnd := MainMenu;
  if (AWnd = Self) then
    AWnd := nil;
  Result := AWnd <> nil;
  if Result then
  begin
    LPoint := ClientToScreen(Point(X, Y));
    LPoint := AWnd.ScreenToClient(LPoint);
    X := LPoint.X;
    Y := LPoint.Y;
  end;
end;

function TACLMenuPopupWindow.GetStyle: TACLPopupMenuStyle;
begin
  Result := Source.Style;
end;

function TACLMenuPopupWindow.HasScrollers: Boolean;
begin
  Result := FScrollBar <> nil;
end;

procedure TACLMenuPopupWindow.InvalidateRect(const R: TRect);
begin
{$IFDEF FPC}
  LCLIntf.InvalidateRect(Handle, @R, True);
{$ELSE}
  Winapi.Windows.InvalidateRect(Handle, R, True);
{$ENDIF}
end;

procedure TACLMenuPopupWindow.KeyDown(var Key: Word; Shift: TShiftState);
var
  LItem: TItemInfo;
begin
  case TranslateKey(Key, Shift) of
    VK_MENU, VK_LMENU, VK_RMENU:
      Looper.CloseMenu;

    VK_ESCAPE:
      Looper.CloseMenu(Self);

    VK_LEFT:
      if Parent <> nil then
        Looper.CloseMenu(Self)
      else
        if MainMenu <> nil then
          MainMenu.KeyDown(Key, Shift);

    VK_RIGHT:
      begin
        LItem := SelectedItemInfo;
        if (LItem <> nil) and HasSubItems(LItem.Item) and LItem.Item.Enabled then
          ClickOnSelection(ccatKeyboard)
        else
          if MainMenu <> nil then
            MainMenu.KeyDown(Key, Shift);
      end;
  else
    inherited;
  end;
end;

procedure TACLMenuPopupWindow.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LWnd: TACLMenuWindow;
begin
  if FScrollBar <> nil then
    FScrollBar.MouseDown(Button, Shift, X, Y);
  if (FScrollBar = nil) or (FScrollBar.PressedPart = sbpNone) then
  begin
    if GetTargetMenuWnd(LWnd, X, Y) then
      LWnd.MouseDown(Button, Shift, X, Y)
    else
      inherited;
  end;
end;

procedure TACLMenuPopupWindow.MouseLeave;
begin
  if FScrollBar <> nil then
    FScrollBar.MouseLeave;
  inherited;
end;

procedure TACLMenuPopupWindow.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LWnd: TACLMenuWindow;
begin
  if FScrollBar <> nil then
    FScrollBar.MouseMove(X, Y);
  if (FScrollBar = nil) or (FScrollBar.PressedPart = sbpNone) then
  begin
    if GetTargetMenuWnd(LWnd, X, Y) then
      LWnd.MouseMove(Shift, X, Y)
    else
    begin
      inherited;
      CheckScrollTimer(Point(X, Y));
    end;
  end;
end;

procedure TACLMenuPopupWindow.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LWnd: TACLMenuWindow;
begin
  if (FScrollBar <> nil) and (FScrollBar.PressedPart <> sbpNone) then
    FScrollBar.MouseUp(Button, X, Y)
  else
    if GetTargetMenuWnd(LWnd, X, Y) then
      LWnd.MouseUp(Button, Shift, X, Y)
    else
      if not ClientRect.Contains(Point(X, Y)) then
        Looper.CloseMenu
      else
        inherited;
end;

procedure TACLMenuPopupWindow.Paint;
var
  LItem: TItemInfo;
  LRect: TRect;
  I: Integer;
begin
  LRect := ClientRect;
  Style.DrawBorder(Canvas, LRect);
  LRect.Content(FPadding);
  acIntersectClipRegion(Canvas.Handle, LRect);
  for I := TopIndex to TopIndex + FVisibleItemCount - 1 do
  begin
    LItem := Items.List[I];
    if LItem.Item.IsLine then
      Style.DrawSeparator(Canvas, LItem.Rect)
    else
    begin
      Style.DrawBackground(Canvas, LItem.Rect, I = SelectedItemIndex);
      Style.DrawItem(Canvas, LItem.Rect,
        LItem.Item.Caption, LItem.Item.ShortCut, I = SelectedItemIndex,
        LItem.Item.Default, LItem.Item.Enabled, HasSubItems(LItem.Item));
      Style.DrawItemImage(Canvas,
        LItem.Rect.Split(srLeft, Style.ItemGutterWidth),
        LItem.Item, I = SelectedItemIndex);
    end;
  end;
  PaintScroller;
end;

procedure TACLMenuPopupWindow.PaintScroller;
begin
  if FScrollBar <> nil then
  begin
    Style.DrawBackground(Canvas, FScrollBar.Bounds, False);
    FScrollBar.Draw(Canvas);
  end;
  if not FScrollButtonRestArea.IsEmpty then
    Style.DrawBackground(Canvas, FScrollButtonRestArea, False);
  if not FScrollButtonDown.IsEmpty then
  begin
    Style.DrawBackground(Canvas, FScrollButtonDown, False);
    Style.DrawScrollButton(Canvas, FScrollButtonDown, True, TopIndex > 0);
  end;
  if not FScrollButtonUp.IsEmpty then
  begin
    Style.DrawBackground(Canvas, FScrollButtonUp, False);
    Style.DrawScrollButton(Canvas, FScrollButtonUp, False, TopIndex + FVisibleItemCount < Items.Count);
  end;
end;

procedure TACLMenuPopupWindow.Popup(const AControlRect: TRect);
begin
  if AControlRect <> NullRect then
    FControlRect := MonitorAlignPopupWindow(AControlRect);
  BoundsRect := AControlRect;
  CalculateBounds;
  Visible := True;
  ShowWindow(Handle, SW_SHOWNOACTIVATE);

  if Looper = nil then
  begin
    FLooper := TACLMenuPopupLooperImpl.Create(Self);
    try
      Looper.Run;
    finally
      FreeAndNil(FLooper);
    end;
  end;
end;

procedure TACLMenuPopupWindow.Resize;
var
  LBitmap: TACLDib;
  LRadius: Integer;
  LRegion: HRGN;
begin
  inherited;

  LRegion := 0;
  LRadius := 2 * Style.CornerRadius.Value;
  if (LRadius > 0) and (Width > 0) and (Height > 0) then
  begin
    LBitmap := TACLDib.Create(BoundsRect);
    try
      LBitmap.Canvas.Brush.Color := clFuchsia;
      LBitmap.Canvas.FillRect(LBitmap.ClientRect);
      LBitmap.Canvas.Pen.Color := clWhite;
      LBitmap.Canvas.Brush.Color := clWhite;
      LBitmap.Canvas.RoundRect(LBitmap.ClientRect, LRadius, LRadius);
      LRegion := acRegionFromBitmap(LBitmap);
    finally
      LBitmap.Free;
    end;
  end;
  SetWindowRgn(Handle, LRegion, True);
end;

procedure TACLMenuPopupWindow.Scroll(ACode: TScrollCode; var APosition: Integer);
begin
  TopIndex := APosition;
  APosition := TopIndex;
end;

procedure TACLMenuPopupWindow.ScrollTimer(Sender: TObject);
begin
  CheckScrollTimer(CalcCursorPos);
  if FScrollTimer.Enabled then
    TopIndex := TopIndex + FScrollTimer.Tag;
end;

procedure TACLMenuPopupWindow.SelectItemOnMouseMove(AItemIndex: Integer);
begin
  if (AItemIndex >= 0) or (Looper = nil) or (Looper.Popups.Peek = Self) then
    inherited;
end;

procedure TACLMenuPopupWindow.WndProc(var Message: TMessage);
begin
{$IFDEF MSWINDOWS}
  if Message.Msg = WM_MOUSEACTIVATE then
  begin
    Message.Result := MA_NOACTIVATE;
    Exit;
  end;
{$ENDIF}
  if (Looper = nil) or not Looper.WndProc(Self, Message) then
    inherited;
end;

{ TACLMenuPopupLooper }

constructor TACLMenuPopupLooper.Create(AOwner: TACLMenuPopupWindow);

  function GetMenuDelayTime: Integer;
  begin
    SystemParametersInfo(SPI_GETMENUSHOWDELAY, 0, @Result, 0);
    if Result = 0 then
      Result := 1;
  end;

begin
  FWnd := AOwner;
  Inc(FMenuLoopCount);
  FDelayTimer := TACLTimer.CreateEx(DoShowPopupDelayed, GetMenuDelayTime);
  FPopups := TObjectStack<TACLMenuPopupWindow>.Create;
  FPopups.Push(Wnd);
  FForm := Safe.CastOrNil<TCustomForm>(AOwner.Source.Owner);
  if FForm = nil then
    FForm := Screen.ActiveCustomForm;
  if FForm <> nil then
    SendMessage(FForm.Handle, WM_ENTERMENULOOP, 0, 0);
  FInLoop := True;
  DoGrabInput;
end;

destructor TACLMenuPopupLooper.Destroy;
begin
  FInLoop := False;
  // Stop all postponed events
  FreeAndNil(FDelayTimer);
  TACLMainThread.Unsubscribe(Self);
  // Close self-created childs
  while FPopups.Count > 1 do
    FPopups.Pop;
  // Notifications
  Dec(FMenuLoopCount); // first
  if FForm <> nil then
    SendMessage(FForm.Handle, WM_EXITMENULOOP, 0, 0);
  if FPostponedSelection <> nil then
    Wnd.Source.DoSelect(FPostponedSelection);
  // Destroying
  FPopups.OwnsObjects := False;
  FreeAndNil(FPopups);
  inherited;
end;

procedure TACLMenuPopupLooper.CloseMenu(AWnd: TACLMenuPopupWindow);
begin
  if AWnd <> nil then
  begin
    FPostponedClosure := AWnd;
    TACLMainThread.RunPostponed(
      procedure
      var
        LMenu: TACLMenuPopupWindow;
      begin
        LMenu := FPostponedClosure;
        FPostponedClosure := nil;
        DoCloseMenu(LMenu);
      end);
  end
  else
    FInLoop := False;
end;

procedure TACLMenuPopupLooper.CloseMenuOnSelect(AItem: TMenuItem);
begin
  FPostponedSelection := AItem;
  CloseMenu;
end;

procedure TACLMenuPopupLooper.DoCloseMenu(AWnd: TACLMenuPopupWindow);
begin
  while (FPopups.Count > 1) and (FPopups.Peek <> AWnd) do
    FPopups.Pop;
  if FPopups.Count > 1 then
    FPopups.Pop
  else
    FInLoop := False;
  DoGrabInput;
end;

procedure TACLMenuPopupLooper.DoGrabInput;
var
  LWnd: TACLMenuWindow;
begin
  FInGrabbing := True;
  try
    LWnd := FPopups.Peek;
    if LWnd <> nil then
      LWnd.MouseCapture := True;
  {$IFDEF FPC}
    TGtk2App.SetInputRedirection(LWnd);
  {$ENDIF}
  finally
    FInGrabbing := False;
  end;
end;

procedure TACLMenuPopupLooper.DoIdle;
var
  LWnd: TACLMenuPopupWindow;
begin
  LWnd := FPopups.Peek;
  if LWnd.HasSelection then
    Application.Hint := GetMenuHint(LWnd.SelectedItemInfo.Item)
  else
    Application.CancelHint;
end;

function TACLMenuPopupLooper.DoShowPopup(AWnd: TACLMenuPopupWindow): Boolean;
var
  LItem: TACLMenuWindow.TItemInfo;
  LWnd: TACLMenuPopupWindow;
begin
  // Всегда и первым!
  FDelayTimer.Enabled := False;
  FDelayWnd := nil;

  // До того, как начнем схлопывать меню из стэка
  if AWnd.HasSelection and IsInStack(AWnd.SelectedItemInfo) then
    Exit(True);

  // Дальше все стандартно
  while (FPopups.Count > 1) and (FPopups.Peek <> AWnd) do
    FPopups.Pop;

  Result := False;
  LItem := AWnd.SelectedItemInfo;
  if (LItem <> nil) and (LItem.Item <> nil) and AWnd.HasSubItems(LItem.Item) then
  begin
    LItem.Item.Click;
    LWnd := TACLMenuPopupWindow.Create(AWnd, LItem);
    if LWnd.Items.Count > 0 then
    begin
      FPopups.Push(LWnd);
      LWnd.Popup(NullRect);
      Result := True;
    end
    else
      LWnd.Free;
  end;
  DoGrabInput;
end;

procedure TACLMenuPopupLooper.DoShowPopupDelayed(Sender: TObject);
begin
  FDelayTimer.Enabled := False;
  if (FDelayWnd <> nil) and FDelayWnd.HasSelection and
     (FDelayWndIndex = FDelayWnd.SelectedItemIndex) and
     (FDelayWnd.IsMouseAtControl)
  then
    DoShowPopup(FDelayWnd);
  FDelayWnd := nil;
end;

function TACLMenuPopupLooper.GetMenuHint(AItem: TMenuItem): string;
begin
  Result := GetLongHint(AItem.Hint);
  if Application.HintShortCuts and (AItem.ShortCut <> scNone) then
    Result := Format('%s (%s)', [Result, ShortCutToText(AItem.ShortCut)]);
end;

function TACLMenuPopupLooper.IsInLoop: Boolean;
begin
  Result := FInLoop and Wnd.Visible and not Application.Terminated;
end;

function TACLMenuPopupLooper.IsInStack(const AInfo: TACLMenuWindow.TItemInfo): Boolean;
var
  LWnd: TACLMenuPopupWindow;
begin
  LWnd := Popups.Peek;
  while LWnd <> nil do
  begin
    if LWnd.SourceItem = AInfo then
      Exit(True);
    LWnd := LWnd.Parent;
  end;
  Result := False;
end;

function TACLMenuPopupLooper.PopupWindowAtCursor: TACLMenuPopupWindow;
var
  LWnd: TACLMenuPopupWindow;
begin
  //LControl := FindControl(MouseCurrentWindow);
  //Result := (LControl is TACLMenuPopupWindow) and
  //  (TACLMenuPopupWindow(LControl).Looper = Self);
  for LWnd in Popups do
  begin
    if LWnd.IsMouseAtControl then
      Exit(LWnd);
  end;
  Result := nil;
end;

function TACLMenuPopupLooper.WndProc(AWnd: TACLMenuPopupWindow; var AMsg: TMessage): Boolean;
begin
  Result := False;
  case AMsg.Msg of
    CM_MENUTRACKING:
      DoGrabInput;

    CM_MENUCLICKED:
      Result := DoShowPopup(AWnd);

    CM_MENUSELECTED:
      begin
        UpdateSelection(AWnd); // first
        FDelayTimer.Enabled := False;
        FDelayWnd := AWnd;
        FDelayWndIndex := AWnd.SelectedItemIndex;
        FDelayTimer.Enabled := True;
      end;

    WM_CAPTURECHANGED:
      if not FInGrabbing then
        CloseMenu(Wnd);
  end;
end;

procedure TACLMenuPopupLooper.UpdateSelection(AWnd: TACLMenuPopupWindow);
var
  LIndex: Integer;
begin
  while (AWnd.Parent <> nil) and (AWnd.SourceItem <> nil) do
  begin
    LIndex := AWnd.Parent.Items.IndexOf(AWnd.SourceItem);
    if LIndex < 0 then Break;
    AWnd.Parent.SelectItem(LIndex, ccatNone);
    AWnd := AWnd.Parent;
  end;
end;

{$ENDREGION}

{$REGION ' Main Menu '}

{ TACLMainMenu }

constructor TACLMainMenu.Create(AOwner: TComponent);
begin
  inherited;
  Align := alTop;
  ControlStyle := ControlStyle + [csMenuEvents];
  FStyle := TACLStyleMenu.Create(Self);
  AutoSize := True;
end;

destructor TACLMainMenu.Destroy;
begin
  TACLMainThread.Unsubscribe(Self);
  FreeAndNil(FPopupWnd);
  FreeAndNil(FStyle);
  inherited;
end;

procedure TACLMainMenu.AdjustSize;
begin
  if HandleAllocated then
  begin
    Height := CalculateAutoSize.Height;
    CalculateLayout;
  end;
end;

function TACLMainMenu.CalculateAutoSize: TSize;
begin
  Result := TSize.Create(1, Style.ItemHeight);
end;

procedure TACLMainMenu.CalculateLayout;
var
  LItem: TItemInfo;
  LRect: TRect;
  I: Integer;
begin
  CalculateMetrics;
  LRect := ClientRect;
  LRect.Content(FPadding);
  FVisibleItemCount := 0;
  for I := 0 to Items.Count - 1 do
  begin
    LItem := Items.List[I];
    LItem.Rect := LRect;
    LItem.Rect.Width := LItem.Size.cx;
    LRect.Left := LItem.Rect.Right;
    Inc(FVisibleItemCount);
  end;
end;

function TACLMainMenu.CalculatePopupBounds(ASize: TSize; AChild: TACLMenuPopupWindow): TRect;
var
  LWorkArea: TRect;
begin
  if AChild <> nil then
    Result.TopLeft := Point(AChild.SourceItem.Rect.Left, Height)
  else
    Result.TopLeft := Point(0, Height);

  LWorkArea := MonitorGetWorkArea(ClientOrigin);
  Result.TopLeft := ClientToScreen(Result.TopLeft);
  Result.Bottom := Min(Result.Top + ASize.Height, LWorkArea.Bottom);
  Result.Width := ASize.Width;
  if Result.Right > LWorkArea.Right then
    Result.Offset(LWorkArea.Right - Result.Right, 0);
end;

function TACLMainMenu.CalculateSize(ACanvas: TCanvas; AItem: TMenuItem): TSize;
begin
  Result.cx := Style.MeasureWidth(ACanvas, AItem.Caption);
  Result.cy := Style.ItemHeight;
  if HasGlyph(AItem) then
  begin
    Inc(Result.cx, dpiApply(TACLStyleMenu.GlyphSize, FCurrentPPI));
    if AItem.Caption <> '' then
      Inc(Result.cx, dpiApply(acTextIndent, FCurrentPPI));
  end;
end;

function TACLMainMenu.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  NewHeight := CalculateAutoSize.Height;
  Result := True;
end;

procedure TACLMainMenu.ChangeScale(M, D: Integer{$IFNDEF FPC}; isDpiChange: Boolean{$ENDIF});
begin
  inherited;
  if Menu <> nil then
    Menu.ScaleForDpi(FCurrentPPI);
  Style.SetTargetDPI(FCurrentPPI);
  AdjustSize;
end;

procedure TACLMainMenu.CheckShortCut(var Msg: TWMKey; var Handled: Boolean);
begin
  if (Msg.CharCode = VK_F10) and (KeyDataToShiftState(Msg.KeyData) = []) then
  begin
    Handled := True;
    if FPopupWnd <> nil then
      FPopupWnd.Looper.CloseMenu
    else
      SelectItem(0, ccatKeyboard);
  end
  else
    if (Menu <> nil) and Menu.IsShortCut(Msg) then
      Handled := True;
end;

procedure TACLMainMenu.CMExit(var Message: TMessage);
begin
  if FPopupWnd = nil then
  begin
    SelectItem(-1, ccatKeyboard);
    FPopupOnSelect := False;
  end;
end;

procedure TACLMainMenu.CMMenuClicked(var Message: TMessage);
var
  LSelected: TItemInfo;
  LUpdateSelection: Boolean;
begin
  LSelected := SelectedItemInfo;
  if FPopupWnd <> nil then
  begin
    if FPopupWnd.SourceItem = LSelected then
      Exit;
    FPopupOnSelect := True;
    FPopupWnd.Looper.CloseMenu;
    Exit;
  end;

  if LSelected = nil then
  begin
    FPopupOnSelect := False;
    Exit;
  end;

  if FPopupOnSelect or HasSubItems(LSelected.Item) then
  begin
    FPopupWnd := TACLMenuPopupWindow.Create(Self, Menu, LSelected);
    try
      FPopupWnd.Popup(NullRect);
      LUpdateSelection := FPopupWnd.SourceItem = SelectedItemInfo;
    finally
      FreeAndNil(FPopupWnd);
    end;
    if LUpdateSelection then
    begin
      FPopupOnSelect := False;
      UpdateMouseMove;
    end;
    if FPopupOnSelect then
      PostMessage(Handle, Message.Msg, Message.WParam, Message.LParam);
  end
  else
    Menu.DoSelect(LSelected.Item);
end;

procedure TACLMainMenu.CMMenuSelected(var Message: TMessage);
begin
  inherited;
  if IsInPopupMode or (TACLControlActionType(Message.WParam) = ccatKeyboard) then
    PostMessage(Handle, CM_MENUCLICKED, Message.WParam, Message.LParam);
end;

procedure TACLMainMenu.DoMenuChange(Sender: TObject; Source: TMenuItem; Rebuild: Boolean);
begin
  Self.Rebuild;
end;

function TACLMainMenu.HasGlyph(AItem: TMenuItem): Boolean;
var
  AIntf: IACLGlyph;
begin
  Result := (AItem.ImageIndex >= 0) or not AItem.Bitmap.Empty or
    Supports(AItem, IACLGlyph, AIntf) and not AIntf.GetGlyph.Empty;
end;

function TACLMainMenu.IsInPopupMode: Boolean;
begin
  Result := FPopupOnSelect or (FPopupWnd <> nil);
end;

procedure TACLMainMenu.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    SelectFirst
  else
    inherited;
end;

procedure TACLMainMenu.Localize(const ASection: string);
begin
  if Menu <> nil then
    TACLMainThread.RunPostponed(Rebuild, Self);
end;

procedure TACLMainMenu.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  SetFocus;
end;

procedure TACLMainMenu.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;
  if (AComponent = Menu) and (AOperation = opRemove) then
    Menu := nil;
end;

procedure TACLMainMenu.Paint;
var
  I: Integer;
begin
  Style.DrawBackground(Canvas, ClientRect, False);
  for I := 0 to Items.Count - 1 do
    PaintItem(Items.List[I], I = SelectedItemIndex);
end;

procedure TACLMainMenu.PaintItem(AItem: TACLMenuWindow.TItemInfo; ASelected: Boolean);
var
  LImageRect: TRect;
  LRect: TRect;
begin
  LRect := AItem.Rect;
  Style.DrawBackground(Canvas, LRect, ASelected);
  LRect.Inflate(-Style.GetTextIdent, 0);

  if AItem.Item.Caption <> '' then
  begin
    if HasGlyph(AItem.Item) then
    begin
      LImageRect := LRect;
      LImageRect.Width := dpiApply(TACLStyleMenu.GlyphSize, FCurrentPPI);
      Style.DrawItemImage(Canvas, LImageRect, AItem.Item, ASelected);
      LRect.Left := LImageRect.Right + dpiApply(acTextIndent, FCurrentPPI);
    end;
    Style.AssignFontParams(Canvas, ASelected, AItem.Item.Default, AItem.Item.Enabled);
    Style.DrawText(Canvas, LRect, AItem.Item.Caption);
  end
  else
    Style.DrawItemImage(Canvas, LRect, AItem.Item, ASelected);
end;

procedure TACLMainMenu.Rebuild;
var
  I: Integer;
begin
  Items.Clear;
  if not (csDestroying in ComponentState) and (Menu <> nil) then
  begin
    Menu.ScaleForDpi(GetCurrentDpi);
    for I := 0 to Menu.Items.Count - 1 do
      AddMenuItem(Menu.Items[I]);
  end;
  AdjustSize;
end;

procedure TACLMainMenu.SelectItemOnMouseMove(AItemIndex: Integer);
begin
  if (AItemIndex >= 0) or not IsInPopupMode then
    inherited;
end;

procedure TACLMainMenu.SetMenu(AValue: TACLPopupMenu);
begin
  if FMenu <> AValue then
  begin
    if FMenu <> nil then
    begin
      FMenu.RemoveFreeNotification(Self);
      FMenu.OnChange := nil;
      FMenu := nil;
    end;
    if AValue <> nil then
    begin
      FMenu := AValue;
      FMenu.FreeNotification(Self);
      FMenu.OnChange := DoMenuChange;
    end;
    Rebuild;
  end;
end;

procedure TACLMainMenu.SetStyle(AValue: TACLStyleMenu);
begin
  FStyle.Assign(AValue);
end;

function TACLMainMenu.TranslateKey(Key: Word; Shift: TShiftState): Word;
begin
  case Key of
    VK_LEFT:
      Result := VK_UP;
    VK_RIGHT:
      Result := VK_DOWN;
    VK_DOWN:
      Result := VK_RIGHT;
    VK_UP:
      Result := VK_LEFT;
  else
    Result := Key;
  end;
end;

procedure TACLMainMenu.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS or DLGC_WANTALLKEYS;
end;

{$IFNDEF FPC}
procedure TACLMainMenu.WMSysCommand(var Message: TWMSysCommand);
begin
  if (GetParentForm(Self) = Screen.FocusedForm) and
     (Application.ModalLevel = 0) and Enabled and Showing then
  begin
    if (TWMSysCommand(Message).CmdType and $FFF0 = SC_KEYMENU) and
       (TWMSysCommand(Message).Key <> VK_SPACE) and
       (TWMSysCommand(Message).Key <> Word('-')) and
       (GetCapture = 0) then
    begin
      if TWMSysCommand(Message).Key <> 0 then
        KeyChar(TWMSysCommand(Message).Key)
      else
        SelectItem(0, ccatKeyboard);

      Message.Result := 1;
      Exit;
    end;
  end;
  inherited;
end;
{$ENDIF}

{$ENDREGION}

{$REGION ' Looper Implementation '}

{$IFDEF MSWINDOWS}

constructor TACLMenuPopupLooperImpl.Create(AOwner: TACLMenuPopupWindow);
begin
  inherited;
  FActionIdleTimer := TACLTimer.CreateEx(DoActionIdleTimerProc);
end;

destructor TACLMenuPopupLooperImpl.Destroy;
begin
  FreeAndNil(FActionIdleTimer);
  inherited;
end;

procedure TACLMenuPopupLooperImpl.DoActionIdle;
var
  LForm: TCustomForm;
  I: Integer;
begin
  for I := 0 to Screen.CustomFormCount - 1 do
  begin
    LForm := Screen.CustomForms[I];
    if LForm.HandleAllocated and IsWindowVisible(LForm.Handle) and IsWindowEnabled(LForm.Handle) then
      LForm.Perform(CM_UPDATEACTIONS, 0, 0);
  end;
end;

procedure TACLMenuPopupLooperImpl.DoActionIdleTimerProc(Sender: TObject);
begin
  try
    FActionIdleTimer.Enabled := False;
    DoActionIdle;
  except
    Application.HandleException(Application);
  end;
end;

procedure TACLMenuPopupLooperImpl.DoIdle;
var
  LDone: Boolean;
begin
  inherited;

  LDone := True;
  try
    if Assigned(Application.OnIdle) then
      Application.OnIdle(Self, LDone);

    if LDone then
    begin
      if Application.ActionUpdateDelay <= 0 then
        DoActionIdle
      else
        if not FActionIdleTimer.Enabled then
        begin
          FActionIdleTimer.Interval := Application.ActionUpdateDelay;
          FActionIdleTimer.Enabled := True;
        end;
    end;
  except
    Application.HandleException(Self);
  end;

  if IsMainThread and CheckSynchronize then
    LDone := False;
  if LDone then
    WaitMessage;
end;

procedure TACLMenuPopupLooperImpl.Run;
var
  Msg: TMsg;
begin
  repeat
    if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
    begin
      case Msg.message of
        CM_RELEASE, WM_CLOSE, WM_QUIT:
          DoCloseMenu;
        WM_KEYFIRST..WM_KEYLAST:
          begin
            Popups.Peek.Dispatch(Msg.Message);
            Continue;
          end;
      end;
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end
    else
      DoIdle;
  until not IsInLoop;
end;

{$ELSE IFDEF(LCLGtk2)}

procedure TACLMenuPopupLooperImpl.DoEvent(AEvent: PGdkEvent; var AHandled: Boolean);
begin
  // AI, ref.to:
  // https://api.gtkd.org/gdk.c.types.GdkEventType.html
  // https://docs.gtk.org/gdk3/struct.EventButton.html
  case AEvent._type of
    GDK_DELETE, GDK_DESTROY:
      DoCloseMenu;
    GDK_BUTTON_PRESS:
      if PopupWindowAtCursor = nil then
      begin
        DoCloseMenu;
        AHandled := True;
      end;
  end;
end;

procedure TACLMenuPopupLooperImpl.DoIdle;
begin
  inherited;
  Application.Idle(True);
end;

procedure TACLMenuPopupLooperImpl.Run;
begin
  TGtk2App.BeginPopup(Wnd, DoEvent);
  try
    repeat
      try
        TGtk2App.ProcessMessages;
      except
        Application.HandleException(Self);
      end;
      DoIdle;
    until not IsInLoop;
  finally
    TGtk2App.EndPopup;
  end;
end;

function TACLMenuPopupLooperImpl.WndProc(
  AWnd: TACLMenuPopupWindow; var AMsg: TMessage): Boolean;
begin
  case AMsg.Msg of
    LM_LBUTTONUP, LM_XBUTTONUP, LM_MBUTTONUP, LM_RBUTTONUP:
      // AI: LCL-Gtk2 безусловно релизит кэпчу на button-up (см.gtkMouseBtnRelease)
      PostMessage(Wnd.Handle, CM_MENUTRACKING, 0, 0);
  end;
  Result := inherited WndProc(AWnd, AMsg);
end;
{$ENDIF}

{$ENDREGION}

initialization
  RegisterClasses([TACLMenuItem, TACLMenuItemLink, TACLMenuListItem]);
end.
