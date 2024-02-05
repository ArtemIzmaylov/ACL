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

{$I ACL.Config.inc}

interface

uses
  Winapi.CommCtrl,
  Winapi.Messages,
  Winapi.MMSystem,
  Winapi.ShellApi,
  Winapi.Windows,
  Winapi.OleAcc,
  // Vcl
  Vcl.Forms,
  Vcl.ActnList,
  Vcl.Consts,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.Menus,
  Vcl.StdCtrls,
  Vcl.Themes,
  // System
  System.Actions,
  System.Character,
  System.Classes,
  System.Contnrs,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Math,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Timers,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.TextLayout,
  ACL.Graphics.Ex,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
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
  CM_ENTERMENULOOP = CM_BASE + $0402;
  CM_ITEMCLICKED   = CM_BASE + $0403;
  CM_ITEMKEYED     = CM_BASE + $0404;
  CM_ITEMSELECTED  = CM_BASE + $0402;

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
    property ExpandMode: TACLMenuItemLinkExpandMode read FExpandMode write FExpandMode default lemExpandInplace;
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
    procedure DoDrawImage(ACanvas: TCanvas; const ARect: TRect; AImages: TCustomImageList;
      AImageIndex: TImageIndex; AEnabled, ASelected: Boolean); virtual;
    function GetTextIdent: Integer; inline;
    procedure InitializeResources; override;
  public
    procedure AfterConstruction; override;
    procedure AssignFontParams(ACanvas: TCanvas; ASelected, AIsDefault, AEnabled: Boolean); virtual;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect; ASelected: Boolean); virtual;
    procedure DrawItemImage(ACanvas: TCanvas;
      ARect: TRect; AItem: TMenuItem; ASelected: Boolean); virtual;
    function MeasureWidth(ACanvas: TCanvas; const S: UnicodeString;
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

{$REGION ' PopupMenu '}

  { TACLStylePopupMenu }

  TACLStylePopupMenu = class(TACLStyleMenu)
  strict private
    function GetItemGutterWidth: Integer; inline;
    function GetSeparatorHeight: Integer; inline;
  protected
    function CalculateItemHeight: Integer; override;
    procedure DoDrawText(ACanvas: TCanvas; ARect: TRect; const S: UnicodeString); virtual;
    procedure DoSplitRect(const R: TRect; AGutterWidth: Integer; out AGutterRect, AContentRect: TRect);
    procedure InitializeResources; override;
  public
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect; ASelected: Boolean); override;
    procedure DrawBorder(ACanvas: TCanvas; const R: TRect); virtual;
    procedure DrawCheckMark(ACanvas: TCanvas; const R: TRect;
      AChecked, AIsRadioItem, ASelected: Boolean);
    procedure DrawItem(ACanvas: TCanvas; R: TRect; const S: UnicodeString;
      AShortCut: TShortCut; ASelected, AIsDefault, AEnabled, AHasSubItems: Boolean); virtual;
    procedure DrawItemImage(ACanvas: TCanvas; ARect: TRect;
      AItem: TMenuItem; ASelected: Boolean); override;
    procedure DrawScrollButton(ACanvas: TCanvas; const R: TRect; AUp, AEnabled: Boolean); virtual;
    procedure DrawSeparator(ACanvas: TCanvas; const R: TRect); virtual;
    function MeasureWidth(ACanvas: TCanvas; const S: UnicodeString;
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
    property CloseMenuOnItemCheck: Boolean read FCloseMenuOnItemCheck write FCloseMenuOnItemCheck default True;
    property ScrollMode: TACLPopupMenuScrollMode read FScrollMode write FScrollMode default smAuto;
  end;

  { TACLPopupMenuStyle }

  TACLPopupMenuStyle = class(TACLStylePopupMenu)
  strict private
    FAllowTextFormatting: Boolean;
  protected
    procedure DoAssign(Source: TPersistent); override;
    procedure DoDrawText(ACanvas: TCanvas; R: TRect; const S: string); override;
    procedure DoReset; override;
  published
    property AllowTextFormatting: Boolean read FAllowTextFormatting write FAllowTextFormatting default False;
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
    FHint: UnicodeString;
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
    function CreateMenuItem: TMenuItem; override;
    procedure ScaleForDpi(ATargetDpi: Integer);
    procedure Popup(const P: TPoint); reintroduce; overload;
    procedure Popup(X, Y: Integer); overload; override;
    // IACLPopup
    procedure PopupUnderControl(const ControlRect: TRect);

    property CurrentDpi: Integer read GetCurrentDpi;
    property IsShown: Boolean read GetIsShown;
  published
    property AutoScale: Boolean read FAutoScale write FAutoScale default True;
    property Hint: UnicodeString read FHint write FHint;
    property Options: TACLPopupMenuOptions read FOptions write SetOptions;
    property Style: TACLPopupMenuStyle read FStyle write SetStyle;
  end;

{$ENDREGION}

{$REGION ' Internal Classes '}

  TACLMenuWindow = class;
  TACLMenuPopupWindow = class;

  { TACLMenuItemControl }

  TACLMenuItemControl = class(TGraphicControl)
  strict private
    FMenuItem: TMenuItem;
    FMouseSelected: Boolean;
    FSelected: Boolean;

    function GetIndex: Integer;
    function GetMenu: TACLMenuWindow;
    function GetStyle: TACLStylePopupMenu;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMItemSelected(var Message: TMessage); message CM_ITEMSELECTED;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
  protected
    FSubMenu: TACLMenuWindow;

    procedure CheckAction(Action: TBasicAction);
    function HasSubItems: Boolean;
    procedure Keyed; virtual;
    function MeasureSize(ACanvas: TCanvas): TSize; virtual;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure SetSelected(ASelected: Boolean; AIsMouseAction: Boolean = False);
    procedure UpdateSelection;
    //
    property Caption;
    property Index: Integer read GetIndex;
    property Menu: TACLMenuWindow read GetMenu;
    property MenuItem: TMenuItem read FMenuItem;
    property MouseSelected: Boolean read FMouseSelected;
    property Selected: Boolean read FSelected;
    property Style: TACLStylePopupMenu read GetStyle;
    property SubMenu: TACLMenuWindow read FSubMenu;
  public
    constructor Create(AOwner: TComponent; AMenuItem: TMenuItem); reintroduce;
    destructor Destroy; override;
    procedure Click; override;
  end;

  { TACLMenuWindow }

  TACLMenuWindow = class(TCustomControl)
  strict private
    FActionIdleTimer: TACLTimer;
    FAnimatePopups: Boolean;
    FDelayItem: TACLMenuItemControl;
    FInMenuLoop: Boolean;
    FItemKeyed: Boolean;
    FParentControl: TACLMenuItemControl;
    FRootMenu: TACLMenuWindow;
    FVisibleIndex: Integer;

    procedure DoActionIdle;
    procedure DoActionIdleTimerProc(Sender: TObject);
    procedure DoMenuDelay(Sender: TObject);

    function GetStyle: TACLStylePopupMenu;
    procedure SetParentMenu(AValue: TACLMenuWindow);
    procedure SetVisibleIndex(AValue: Integer);

    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMEnterMenuLoop(var Message: TMessage); message CM_ENTERMENULOOP;
    procedure CMItemClicked(var Message: TMessage); message CM_ITEMCLICKED;
    procedure CMItemKeyed(var Message: TMessage); message CM_ITEMKEYED;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMKeyDown(var Message:  TWMKeyDown); message WM_KEYDOWN;
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMPrintClient(var Message: TWMPrintClient); message WM_PRINTCLIENT;
  protected
    FChildMenu: TACLMenuWindow;
    FControlRect: TRect;
    FItemNumberInDisplayArea: Integer;
    FItems: TACLObjectList<TACLMenuItemControl>;
    FMousePos: TPoint;
    FParentMenu: TACLMenuWindow;
    FPopupMenu: TACLPopupMenu;
    FPopupStack: TObjectStack<TACLMenuWindow>;
    FPopupTimer: TACLTimer;
    FSelectedItem: TMenuItem;

    function GetCurrentDpi: Integer; virtual;
    function GetMenuDelayTime: Integer; virtual;
    function IsDesigning: Boolean; virtual;

    //# Parent
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Resize; override;
    procedure VisibleChanging; override;
    procedure WndProc(var Message: TMessage); override;

    //# Navigation
    procedure EnsureNextItemVisible(var AItem: TACLMenuItemControl);
    function FindAccelItem(const Accel: Word): TACLMenuItemControl;
    function FindFirst: TACLMenuItemControl;
    function FindFirstVisibleItem: TACLMenuItemControl;
    function FindLast: TACLMenuItemControl;
    function FindLastVisibleItem: TACLMenuItemControl;
    function FindNext(AClient: TACLMenuItemControl; AWrap: Boolean = True): TACLMenuItemControl;
    function FindNextVisibleItem(AClient: TACLMenuItemControl): TACLMenuItemControl;
    function FindPrevious(AClient: TACLMenuItemControl; AWrap: Boolean = True): TACLMenuItemControl;
    function FindPreviousVisibleItem(AClient: TACLMenuItemControl): TACLMenuItemControl;
    function FindSelected(out AItem: TACLMenuItemControl): Boolean;
    function TranslateCharCode(Code: Word): Word; virtual;

    //# Creation
    function CreateMenuItemControl(AMenuItem: TMenuItem): TACLMenuItemControl; virtual;
    function CreatePopup(AOwner: TACLMenuWindow; AItem: TACLMenuItemControl): TACLMenuPopupWindow; virtual;

    //# Calculation
    procedure CalculateBounds; virtual;
    procedure CalculateLayout; virtual; abstract;
    function CalculateMaxSize: TSize; virtual; abstract;
    function CalculatePopupBounds(ASize: TSize; AChild: TACLMenuWindow = nil): TRect; virtual; abstract;

    //# Menu Message Loop
    procedure DoneMenuLoop;
    procedure InitMenuLoop;
    procedure Idle(const Msg: TMsg);
    procedure ProcessMenuLoop; virtual;
    function ProcessMessage(var Msg: TMsg): Boolean;
    procedure ProcessMessages;
    procedure ProcessMouseMessage(var Msg: TMsg); virtual;
    procedure ProcessMouseWheel(var Msg: TMsg); virtual;

    //# Tracking
    procedure Animate(Show: Boolean = True);
    procedure ClearSubMenus;
    procedure CloseMenu;
    procedure TrackMenu;
    function TrackMenuOnSelect: Boolean; virtual;

    //# Actions
    function CanCloseMenuOnItemClick(AItem: TMenuItem): Boolean; virtual;
    function DoItemClicked(AItem: TACLMenuItemControl): TMenuItem; virtual;
    function DoItemKeyed(AItem: TACLMenuItemControl): TMenuItem; virtual;
    procedure DoItemSelected(AItem: TACLMenuItemControl);
    procedure DoSelect(Item: TMenuItem); virtual;

    //# Populate
    procedure AddMenuItem(AMenuItem: TMenuItem);
    procedure Clear; virtual;
    procedure PopulateItems(AParentItem: TMenuItem);

    procedure Select(AForward: Boolean);
    procedure SelectItem(AItem: TACLMenuItemControl);

    property InMenuLoop: Boolean read FInMenuLoop write FInMenuLoop;
    property ParentControl: TACLMenuItemControl read FParentControl write FParentControl;
    property ParentMenu: TACLMenuWindow read FParentMenu write SetParentMenu;
    property PopupMenu: TACLPopupMenu read FPopupMenu;
    property PopupStack: TObjectStack<TACLMenuWindow> read FPopupStack;
    property RootMenu: TACLMenuWindow read FRootMenu write FRootMenu;
    property Style: TACLStylePopupMenu read GetStyle;
    property VisibleIndex: Integer read FVisibleIndex write SetVisibleIndex;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Caption;
    property Color;
    property Font;
  end;

  { TACLMenuPopupWindow }

  TACLMenuPopupWindow = class(TACLMenuWindow)
  strict private
    FScrollBar: TACLScrollBar;
    FScrollButtonDown: TRect;
    FScrollButtonRestArea: TRect;
    FScrollButtonUp: TRect;
    FScrollTimer: TACLTimer;

    function GetBorderWidths: TRect;
    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCPaint(var Message: TWMNCPaint); message WM_NCPAINT;
    procedure WMPrint(var Message: TWMPrint); message WM_PRINT;
  protected
    //# Calculation
    procedure CalculateBounds; override;
    procedure CalculateLayout; override;
    function CalculateMaxSize: TSize; override;
    function CalculatePopupBounds(ASize: TSize; AChild: TACLMenuWindow = nil): TRect; override;
    procedure CalculateScrollBar(var R: TRect);
    //# Parent
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Resize; override;
    //# Mouse
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    //# Drawing
    procedure NCPaint(DC: HDC);
    procedure Paint; override;
    //# Scrolling
    function CreateScrollBar: TACLScrollBar;
    procedure CheckAutoScrollTimer(const P: TPoint);
    procedure DoScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure DoScrollTimer(Sender: TObject);
    procedure DrawScrollButton(ACanvas: TCanvas; const R: TRect; ATop, AEnabled: Boolean); virtual;
    procedure DrawScrollButtons(ACanvas: TCanvas); virtual;

    property ScrollBar: TACLScrollBar read FScrollBar;
    property ScrollButtonDown: TRect read FScrollButtonDown;
    property ScrollButtonUp: TRect read FScrollButtonUp;
    property ScrollTimer: TACLTimer read FScrollTimer;
  protected
    procedure Popup(X, Y: Integer);
    procedure PopupEx(AMenuItem: TMenuItem; const AControlRect: TRect);
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TACLMenuWindow); reintroduce; overload;
    destructor Destroy; override;
  end;

{$ENDREGION}

{$REGION ' MainMenu '}

  { TACLMainMenu }

  TACLMainMenu = class(TACLMenuWindow, IACLLocalizableComponent)
  strict private
    FCancelMenu: Boolean;
    FMenu: TACLPopupMenu;
    FStyle: TACLStyleMenu;

    procedure HandlerMenuChange(Sender: TObject; Source: TMenuItem; Rebuild: Boolean);
    procedure SetMenu(AValue: TACLPopupMenu);
    procedure SetStyle(AValue: TACLStyleMenu);
    procedure WMSysCommand(var Message: TWMSysCommand); message WM_SYSCOMMAND;
    procedure WMSysKeyDown(var Message: TWMSysKeyDown); message WM_SYSKEYDOWN;
    procedure WMSysKeyUp(var Message: TWMSysKeyUp); message WM_SYSKEYUP;
  protected
    function CreateMenuItemControl(AMenuItem: TMenuItem): TACLMenuItemControl; override;

    //# Calculate
    procedure CalculateLayout; override;
    function CalculateMaxSize: TSize; override;
    function CalculatePopupBounds(ASize: TSize; AChild: TACLMenuWindow = nil): TRect; override;

    //# Capabilities
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    function CanCloseMenuOnItemClick(AItem: TMenuItem): Boolean; override;

    //# Navigation
    function TranslateCharCode(Code: Word): Word; override;

    //# Tracking
    function TrackMenuOnSelect: Boolean; override;

    // IACLLocalizableComponent
    procedure Localize(const ASection: string);

    function GetCurrentDpi: Integer; override;
    function GetMenuDelayTime: Integer; override;
    
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdjustSize; override;
    procedure CheckShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure Rebuild;
  published
    property Menu: TACLPopupMenu read FMenu write SetMenu;
    property Style: TACLStyleMenu read FStyle write SetStyle;
  end;

  { TACLMainMenuItemControl }

  TACLMainMenuItemControl = class(TACLMenuItemControl)
  strict private
    function HasGlyph: Boolean;
    function Style: TACLStyleMenu; inline;
  protected
    function MeasureSize(ACanvas: TCanvas): TSize; override;
    procedure Paint; override;
  end;

{$ENDREGION}

{$REGION ' Helpers '}

  { TMenuItemHelper }

  TMenuItemHelper = class helper for TMenuItem
  strict private
    function GetDefaultItem: TMenuItem;
    function GetMenu: TMenu;
  protected
    procedure PrepareForShowing;
  public
    function AddItem(const ACaption, AHint: UnicodeString; ATag: NativeInt = 0;
      AEvent: TNotifyEvent = nil; AShortCut: TShortCut = 0): TMenuItem; overload;
    function AddItem(const ACaption: UnicodeString;
      AEvent: TNotifyEvent = nil; AShortCut: TShortCut = 0): TMenuItem; overload;
    function AddItem(const ACaption: UnicodeString; ATag: NativeInt;
      AEvent: TNotifyEvent = nil; AShortCut: TShortCut = 0): TMenuItem; overload;
    function AddLink(const AMenuItemOrMenu: TComponent): TACLMenuItemLink;
    function AddRadioItem(const ACaption, AHint: UnicodeString; ATag: NativeInt = 0;
      AEvent: TNotifyEvent = nil; AGroupIndex: Integer = 0; AShortCut: TShortCut = 0): TMenuItem; overload;
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

function acMenusHasActivePopup: Boolean;
implementation

type
  TApplicationAccess = class(TApplication);
  TControlActionLinkAccess = class(TControlActionLink);

  { TACLMenuController }

  TACLMenuController = class
  private
    class var FActiveMenu: TACLMenuWindow;
    class var FHook: HHOOK;
    class var FMenus: TList;

    class function CallWindowHook(Code: Integer; wparam: WPARAM; Msg: PCWPStruct): Longint; stdcall; static;
  protected
    class function IsValid(AMenu: TACLMenuWindow): Boolean;
  public
    class procedure Register(ABar: TACLMenuWindow);
    class procedure Unregister(ABar: TACLMenuWindow);
    class property ActiveMenu: TACLMenuWindow read FActiveMenu write FActiveMenu;
  end;

function acMenusHasActivePopup: Boolean;
begin
  Result := TACLMenuController.ActiveMenu <> nil;
end;

{$REGION ' Helpers '}

{ TMenuItemHelper }

function TMenuItemHelper.AddItem(const ACaption, AHint: UnicodeString;
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

function TMenuItemHelper.AddItem(const ACaption: UnicodeString; AEvent: TNotifyEvent = nil; AShortCut: TShortCut = 0): TMenuItem;
begin
  Result := AddItem(ACaption, 0, AEvent, AShortCut);
end;

function TMenuItemHelper.AddItem(const ACaption: UnicodeString; ATag: NativeInt; AEvent: TNotifyEvent = nil; AShortCut: TShortCut = 0): TMenuItem;
begin
  Result := AddItem(ACaption, '', ATag, AEvent, AShortCut);
end;

function TMenuItemHelper.AddLink(const AMenuItemOrMenu: TComponent): TACLMenuItemLink;
begin
  Result := TACLMenuItemLink.Create(Self);
  Result.Link := AMenuItemOrMenu;
  Add(Result);
end;

function TMenuItemHelper.AddRadioItem(const ACaption, AHint: UnicodeString;
  ATag: NativeInt; AEvent: TNotifyEvent; AGroupIndex: Integer; AShortCut: TShortCut): TMenuItem;
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
begin
  for var I := Count - 1 downto 0 do
  begin
    if Items[I].Tag = ATag then
      Exit(Items[I]);
  end;
  Result := nil;
end;

procedure TMenuItemHelper.DeleteWithTag(const ATag: NativeInt);
begin
  for var I := Count - 1 downto 0 do
  begin
    if Items[I].Tag = ATag then
      Delete(I);
  end;
end;

function TMenuItemHelper.HasVisibleSubItems: Boolean;
var
  AItem: TMenuItem;
begin
  for var I := 0 to Count - 1 do
  begin
    AItem := Items[I];
    if not AItem.IsLine and AItem.Visible then
      Exit(True);
  end;
  Result := False;
end;

function TMenuItemHelper.IsCheckable: Boolean;
var
  Intf: IACLMenuItemCheckable;
begin
  Result := Checked or AutoCheck or RadioItem or Succeeded(QueryInterface(IACLMenuItemCheckable, Intf));
end;

procedure TMenuItemHelper.PrepareForShowing;
var
  AIntf: IACLMenuShowHandler;
begin
  for var I := 0 to Count - 1 do
  begin
    if Supports(Items[I], IACLMenuShowHandler, AIntf) then
      AIntf.OnShow;
  end;
end;

function TMenuItemHelper.GetDefaultItem: TMenuItem;
begin
  for var I := 0 to Count - 1 do
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
begin
  if Enabled then
  begin
    if Link is TMenuItem then
      AProc(TMenuItem(Link))
    else
      if Link is TPopupMenu then
      begin
        TPopupMenu(Link).Items.PrepareForShowing;
        for var I := 0 to TPopupMenu(Link).Items.Count - 1 do
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
begin
  while Count > 0 do
    Delete(0);
  for var I := 0 to Items.Count - 1 do
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
  AImages: TCustomImageList; AImageIndex: TImageIndex; AEnabled, ASelected: Boolean);
begin
  acDrawImage(ACanvas, ARect, AImages, AImageIndex, AEnabled);
end;

procedure TACLStyleMenu.DrawBackground(ACanvas: TCanvas; const R: TRect; ASelected: Boolean);
begin
  if ASelected then
    acFillRect(ACanvas.Handle, R, ColorItemSelected.AsColor)
  else
    acFillRect(ACanvas.Handle, R, ColorItem.AsColor);

  Texture.Draw(ACanvas.Handle, R, Ord(ASelected));
end;

procedure TACLStyleMenu.DrawItemImage(ACanvas: TCanvas;
  ARect: TRect; AItem: TMenuItem; ASelected: Boolean);
var
  AClipRegion: HRGN;
  AGlyph: TACLGlyph;
  AImages: TCustomImageList;
  AIntf: IACLGlyph;
begin
  if not acRectVisible(ACanvas.Handle, ARect) then Exit;

  AClipRegion := acSaveClipRegion(ACanvas.Handle);
  try
    acIntersectClipRegion(ACanvas.Handle, ARect);
    // DPI aware Glyph
    if Supports(AItem, IACLGlyph, AIntf) and not AIntf.GetGlyph.Empty then
    begin
      AGlyph := AIntf.GetGlyph;
      AGlyph.TargetDPI := TargetDPI;
      ARect.Center(AGlyph.FrameSize);
      AGlyph.Draw(ACanvas.Handle, ARect, AItem.Enabled);
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
        AGlyph.Draw(ACanvas.Handle, ARect, AItem.Enabled);
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
  const S: UnicodeString; AShortCut: TShortCut; ADefault: Boolean): Integer;
begin
  AssignFontParams(ACanvas, True, ADefault, True);
  Result := 2 * GetTextIdent + acTextSize(ACanvas, S).Width;
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
            ATexture.Draw(ACanvas.Handle, GetStateRect(R, ATexture), Ord(AChecked) * 5 + Ord(ASelected));
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
        TextureGutter.Draw(ACanvas.Handle, GetStateRect(R, TextureGutter), AImageIndex);
    end;
  finally
    acRestoreClipRegion(ACanvas.Handle, AClipRegion);
  end;
end;

procedure TACLStylePopupMenu.DoDrawText(ACanvas: TCanvas; ARect: TRect; const S: UnicodeString);
begin
  acSysDrawText(ACanvas, ARect, S, DT_LEFT or DT_SINGLELINE or DT_VCENTER);
end;

procedure TACLStylePopupMenu.DoSplitRect(const R: TRect;
  AGutterWidth: Integer; out AGutterRect, AContentRect: TRect);
begin
  AGutterRect := R;
  AGutterRect.Width := AGutterWidth;
  AContentRect := R;
  AContentRect.Left := AGutterRect.Right;
end;

procedure TACLStylePopupMenu.DrawBackground(ACanvas: TCanvas; const R: TRect; ASelected: Boolean);
var
  AContentRect: TRect;
  AGutterRect: TRect;
begin
  inherited;
  DoSplitRect(R, ItemGutterWidth, AGutterRect, AContentRect);
  TextureGutter.Draw(ACanvas.Handle, AGutterRect, Ord(ASelected));
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

procedure TACLStylePopupMenu.DrawScrollButton(ACanvas: TCanvas; const R: TRect; AUp, AEnabled: Boolean);
const
  ScrollButtonMap: array[Boolean] of TACLArrowKind = (makBottom, makTop);
begin
  AssignFontParams(ACanvas, False, False, AEnabled);
  acDrawArrow(ACanvas.Handle, R, ACanvas.Font.Color, ScrollButtonMap[AUp], TargetDPI);
end;

procedure TACLStylePopupMenu.DrawSeparator(ACanvas: TCanvas; const R: TRect);
var
  ADstC, ADstG: TRect;
  ALayer: TACLBitmapLayer;
  ASrcC, ASrcG: TRect;
begin
  if TextureSeparator.ImageDpi <> acDefaultDpi then
  begin
    ALayer := TACLBitmapLayer.Create(TextureGutter.Image.Width + TextureSeparator.Image.Width, TextureSeparator.Image.Height);
    try
      acFillRect(ALayer.Handle, R, ColorItem.AsColor);
      TextureSeparator.Draw(ALayer.Handle, ALayer.ClientRect);
      DoSplitRect(ALayer.ClientRect, TextureGutter.Image.Width, ASrcG, ASrcC);
      DoSplitRect(R, ItemGutterWidth, ADstG, ADstC);
      acStretchBlt(ACanvas.Handle, ALayer.Handle, ADstG, ASrcG);
      acStretchBlt(ACanvas.Handle, ALayer.Handle, ADstC, ASrcC);
    finally
      ALayer.Free;
    end;
  end
  else
  begin
    acFillRect(ACanvas.Handle, R, ColorItem.AsColor);
    TextureSeparator.Draw(ACanvas.Handle, R, 0);
  end;
end;

procedure TACLStylePopupMenu.DrawItem(
  ACanvas: TCanvas; R: TRect; const S: UnicodeString;
  AShortCut: TShortCut; ASelected, AIsDefault, AEnabled, AHasSubItems: Boolean);
begin
  Inc(R.Left, ItemGutterWidth);
  R.Inflate(-GetTextIdent, 0);
  AssignFontParams(ACanvas, ASelected, AIsDefault, AEnabled);
  DoDrawText(ACanvas, R, S);
  if AHasSubItems then
    acDrawArrow(ACanvas.Handle, R.Split(srRight, R.Height), ACanvas.Font.Color, makRight, TargetDPI)
  else
    if AShortCut <> scNone then
      acTextDraw(ACanvas, ShortCutToText(AShortCut), R, taRightJustify, taVerticalCenter);
end;

procedure TACLStylePopupMenu.DrawItemImage(ACanvas: TCanvas; ARect: TRect; AItem: TMenuItem; ASelected: Boolean);
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
  const S: UnicodeString; AShortCut: TShortCut; ADefault: Boolean): Integer;
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
    SetPopupPoint(Point(ControlRect.Left, ControlRect.Bottom));
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
begin
  DoPopup(Self);
  if AutoScale then
    ScaleForDpi(CalculateTargetDpi);
  for var I := 0 to Items.Count - 1 do
    Items[I].InitiateAction;
end;

procedure TACLPopupMenu.DoDpiChanged;
begin
  Style.SetTargetDPI(CurrentDpi);
end;

procedure TACLPopupMenu.DoSelect(Item: TMenuItem);
begin
  PostMessage(PopupList.Window, WM_COMMAND, Item.Command, 0);
end;

procedure TACLPopupMenu.DoShow(const ControlRect: TRect);
begin
  if not IsShown then
  try
    FPopupWindow := TACLMenuPopupWindow.Create(Self);
    try
      TACLMenuPopupWindow(FPopupWindow).FPopupMenu := Self;
      TACLMenuPopupWindow(FPopupWindow).PopupEx(Items, ControlRect);
    finally
      FreeAndNil(FPopupWindow);
  //Lose Focus: MyRefreshStayOnTop;
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

{ TACLPopupMenuStyle }

procedure TACLPopupMenuStyle.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);
  if Source is TACLPopupMenuStyle then
    AllowTextFormatting := TACLPopupMenuStyle(Source).AllowTextFormatting;
end;

procedure TACLPopupMenuStyle.DoDrawText(ACanvas: TCanvas; R: TRect; const S: string);
begin
  if AllowTextFormatting then
    acDrawFormattedText(ACanvas, StripHotkey(S), R, taLeftJustify, taVerticalCenter, False)
  else
    inherited DoDrawText(ACanvas, R, S);
end;

procedure TACLPopupMenuStyle.DoReset;
begin
  inherited DoReset;
  AllowTextFormatting := False;
end;

{$ENDREGION}

{$REGION ' Internal Classes '}

{ TACLMenuWindow }

constructor TACLMenuWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csClickEvents, csDoubleClicks, csSetCaption, csOpaque];
  Align := alNone;
  Height := 50;
  Width := 150;
  BorderWidth := 0;
  DoubleBuffered := True;
  FAnimatePopups := True;
  Font := Screen.MenuFont;
  TACLMenuController.Register(Self);
  FActionIdleTimer := TACLTimer.CreateEx(DoActionIdleTimerProc);
  FItems := TACLObjectList<TACLMenuItemControl>.Create;
end;

destructor TACLMenuWindow.Destroy;
begin
  ClearSubMenus;
  FChildMenu := nil;
  Visible := False;
  TACLMenuController.Unregister(Self);
  if FParentControl <> nil then
    FParentControl.FSubMenu := nil;
  if FParentMenu <> nil then
    FParentMenu.FChildMenu := nil;
  FreeAndNil(FActionIdleTimer);
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TACLMenuWindow.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if Operation = opRemove then
  begin
    if AComponent = FSelectedItem then
      FSelectedItem := nil;
  end;
end;

procedure TACLMenuWindow.Resize;
begin
  inherited Resize;
  CalculateLayout;
end;

procedure TACLMenuWindow.VisibleChanging;

  procedure UpdateSeparatorsVisibility;
  var
    AItem: TACLMenuItemControl;
  begin
    AItem := FindFirstVisibleItem;
    if (AItem <> nil) and AItem.MenuItem.IsLine then
      AItem.Visible := False;

    AItem := FindLastVisibleItem;
    if (AItem <> nil) and AItem.MenuItem.IsLine then
      AItem.Visible := False;
  end;

begin
  inherited VisibleChanging;

  if csDesigning in ComponentState then
    Exit;

  if not Visible then
  begin
    UpdateSeparatorsVisibility;

    for var I := 0 to FItems.Count - 1 do
      FItems[I].MenuItem.InitiateAction;

    DisableAlign;
    try
      CalculateBounds;
      VisibleIndex := 0;
      for var I := 0 to FItems.Count - 1 do
      begin
        if FItems[I].MenuItem.Default then
        begin
          VisibleIndex := I;
          Break;
        end;
      end;
    finally
      EnableAlign;
      Resize;
    end;

    if ParentMenu <> nil then
      Animate(True);

    if RootMenu <> nil then
    begin
      sndPlaySound(nil, SND_NODEFAULT);
      sndPlaySound('MenuPopup', SND_NOSTOP or SND_ASYNC or SND_NODEFAULT);
    end;
  end;
end;

procedure TACLMenuWindow.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_NCHITTEST:
      Message.Result := HTCLIENT;
    WM_ERASEBKGND:
      if FDoubleBuffered and (TMessage(Message).wParam <> WPARAM(TMessage(Message).lParam)) then
      begin
        Message.Result := 1;
        Exit;
      end;
  end;
  inherited WndProc(Message);
end;

procedure TACLMenuWindow.EnsureNextItemVisible(var AItem: TACLMenuItemControl);
var
  AControlIndex: Integer;
begin
  AControlIndex := AItem.Index;
  while (AControlIndex < VisibleIndex) or (AControlIndex >= VisibleIndex + FItemNumberInDisplayArea) do
  begin
    if AControlIndex < VisibleIndex then
      VisibleIndex := AControlIndex
    else
      VisibleIndex := AControlIndex - FItemNumberInDisplayArea + 1;
  end;
end;

function TACLMenuWindow.FindAccelItem(const Accel: Word): TACLMenuItemControl;
begin
  for var I := 0 to FItems.Count - 1 do
  begin
    Result := FItems[I];
    if Result.Parent.Showing and Result.Visible and IsAccel(Accel, Result.Caption) then
      Exit;
  end;
  Result := nil;
end;

function TACLMenuWindow.FindFirst: TACLMenuItemControl;
begin
  if FItems.Count > 0 then
    Result := FItems[0]
  else
    Result := nil;
end;

function TACLMenuWindow.FindFirstVisibleItem: TACLMenuItemControl;
begin
  Result := FindFirst;
  while Assigned(Result) and not Result.Visible do
    Result := FindNext(Result, False);
end;

function TACLMenuWindow.FindLast: TACLMenuItemControl;
begin
  if FItems.Count > 0 then
    Result := FItems.Last
  else
    Result := nil;
end;

function TACLMenuWindow.FindLastVisibleItem: TACLMenuItemControl;
begin
  Result := FindLast;
  while Assigned(Result) and not Result.Visible do
    Result := FindPrevious(Result, False);
end;

function TACLMenuWindow.FindNext(AClient: TACLMenuItemControl; AWrap: Boolean = True): TACLMenuItemControl;
begin
  Result := nil;
  if Assigned(AClient) then
  begin
    if AClient.Index < FItems.Count - 1 then
      Result := FItems[AClient.Index + 1]
    else
      if AWrap and (FItems.Count > 1) then
        Result := FItems[0];
  end
  else
    if AWrap then
      Result := FindFirst;
end;

function TACLMenuWindow.FindNextVisibleitem(AClient: TACLMenuItemControl): TACLMenuItemControl;
begin
  Result := FindNext(AClient, False);
  while Assigned(Result) and not Result.Visible do
    Result := FindNext(Result, False);
end;

function TACLMenuWindow.FindPrevious(AClient: TACLMenuItemControl; AWrap: Boolean = True): TACLMenuItemControl;
begin
  Result := nil;
  if Assigned(AClient) then
  begin
    if AClient.Index > 0 then
      Result := FItems[AClient.Index - 1]
    else
      if AWrap and (FItems.Count > 1) then
        Result := FItems.Last;
  end
  else
    if AWrap then
      Result := FindLast;
end;

function TACLMenuWindow.FindPreviousVisibleItem(AClient: TACLMenuItemControl): TACLMenuItemControl;
begin
  Result := FindPrevious(AClient, False);
  while Assigned(Result) and not Result.Visible do
    Result := FindPrevious(Result, False);
end;

function TACLMenuWindow.FindSelected(out AItem: TACLMenuItemControl): Boolean;
begin
  for var I := 0 to FItems.Count - 1 do
  begin
    AItem := FItems[I];
    if (AItem <> nil) and AItem.Selected then
      Exit(True);
  end;
  Result := False;
end;

function TACLMenuWindow.CreateMenuItemControl(AMenuItem: TMenuItem): TACLMenuItemControl;
begin
  Result := TACLMenuItemControl.Create(Self, AMenuItem);
end;

function TACLMenuWindow.CreatePopup(AOwner: TACLMenuWindow; AItem: TACLMenuItemControl): TACLMenuPopupWindow;
begin
  FDelayItem := nil;
  if not InMenuLoop or (AOwner = nil) or (AItem = nil) then
    Exit(nil);
  if (FPopupStack.Count = 0) or (FPopupStack.Peek.ParentControl = AItem) then
    Exit(nil);
  if not AItem.HasSubItems then
    Exit(nil);

  AItem.MenuItem.Click;

  Result := TACLMenuPopupWindow.Create(AOwner);
  Result.DisableAlign;
  Result.InMenuLoop := True;
  Result.ParentControl := AItem;
  Result.PopulateItems(AItem.MenuItem);
  if Result.FItems.Count = 0 then
  begin
    FreeAndNil(Result);
    Exit;
  end;

  AItem.FSubMenu := Result;
  FPopupStack.Push(Result);
  Result.EnableAlign;
  Result.Show;
end;

procedure TACLMenuWindow.DoneMenuLoop;
begin
  ClearSubMenus;
  TACLMenuController.ActiveMenu := nil;
  FAnimatePopups := True;
  ShowCaret(0);
  FPopupStack.OwnsObjects := False;
  FreeAndNil(FPopupTimer);
  FreeAndNil(FPopupStack);
end;

procedure TACLMenuWindow.InitMenuLoop;
begin
  FMousePos := Mouse.CursorPos;
  // Need to use FSelectedItem because it's possible for the item to be
  // destroyed in designmode before TrackMenu gets an opportunity to execute
  // the associated action
  FSelectedItem := nil;
  FDelayItem := nil;
  acSafeSetFocus(GetParentForm(Self));
  FPopupTimer := TACLTimer.CreateEx(DoMenuDelay, GetMenuDelayTime);
  FPopupStack := TObjectStack<TACLMenuWindow>.Create;
  FPopupStack.Push(Self);
  FInMenuLoop := True;
  HideCaret(0);
  TACLMenuController.ActiveMenu := Self;
end;

procedure TACLMenuWindow.Idle(const Msg: TMsg);
var
  ADone: Boolean;
  AHintInfo: THintInfo;
  ASelected: TACLMenuItemControl;
begin
  if FindSelected(ASelected) then
  begin
    ZeroMemory(@AHintInfo, SizeOf(AHintInfo));
    ASelected.Perform(CM_HINTSHOW, 0, LPARAM(@AHintInfo));
    Application.Hint := GetLongHint(AHintInfo.HintStr);
  end
  else
    Application.CancelHint;

  ADone := True;
  try
    if Assigned(Application.OnIdle) then
      Application.OnIdle(Self, ADone);

    if ADone then
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
    ADone := False;
  if ADone then
    WaitMessage;
end;

procedure TACLMenuWindow.ProcessMenuLoop;
var
  Msg: TMsg;
begin
  if FInMenuLoop then
    Exit;

  InitMenuLoop;
  try
    repeat
      if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
      begin
        // Prevent multiple right click menus from appearing in form designer
        if (Msg.message = WM_CONTEXTMENU) and (RootMenu is TACLMenuWindow) then
          Continue;

        case Msg.message of
          CM_ITEMSELECTED:
            DoItemSelected(TACLMenuItemControl(Msg.lParam));
          CM_ITEMKEYED:
            FSelectedItem := DoItemKeyed(TACLMenuItemControl(Msg.lParam));
          CM_ITEMCLICKED:
            FSelectedItem := DoItemClicked(TACLMenuItemControl(Msg.lParam));

          WM_QUIT:
            begin
              FInMenuLoop := False;
              PostQuitMessage(Msg.wParam);
            end;

          WM_NCLBUTTONDOWN:
            begin
              CloseMenu;
              RootMenu.ProcessMessages;
              DispatchMessage(Msg);
            end;

          WM_NCMBUTTONDOWN, WM_NCRBUTTONDOWN, CM_RELEASE, WM_CLOSE:
            begin
              CloseMenu;
              RootMenu.ProcessMessages;
              DispatchMessage(Msg);
            end;

          WM_KEYFIRST..WM_KEYLAST:
            if (Msg.message = WM_SYSKEYDOWN) and (Msg.wParam = VK_MENU) then
            begin
              CloseMenu;
              TranslateMessage(Msg);
              DispatchMessage(Msg);
            end
            else
              if (Msg.wParam <> VK_F1) or (KeyboardStateToShiftState = [ssCtrl]) then
                FPopupStack.Peek.Dispatch(Msg.message);

          WM_MOUSEFIRST..WM_MOUSELAST:
            begin
              if Msg.Message = WM_MOUSEWHEEL then
              begin
                ProcessMouseWheel(Msg);
                Continue;
              end;
              if Msg.Message = WM_MOUSEMOVE then
              begin
                if PointsEqual(FMousePos, Mouse.CursorPos) then
                  Continue;
              end;
              ProcessMouseMessage(Msg);
            end;
        else
          TranslateMessage(Msg);
          DispatchMessage(Msg);
        end;
        if Assigned(FPopupStack) and not FPopupStack.Peek.FInMenuLoop then
          FPopupStack.Peek.CloseMenu;
      end
      else
        Idle(Msg);
    until not FInMenuLoop;
  finally
    DoneMenuLoop;
  end;
end;

function TACLMenuWindow.ProcessMessage(var Msg: TMsg): Boolean;
var
  App: TApplicationAccess;
begin
  App := TApplicationAccess(Application);
  Result := False;
  if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
  begin
    Result := True;
    if Msg.Message <> WM_QUIT then
      if not App.IsHintMsg(Msg) and not App.IsMDIMsg(Msg) then
      begin
        if (Msg.message >= WM_KEYFIRST) and (Msg.message <= WM_KEYLAST) then
          Exit(False);
        TranslateMessage(Msg);
        DispatchMessage(Msg);
      end;
  end;
end;

procedure TACLMenuWindow.ProcessMessages;
var
  Msg: TMsg;
begin
  while ProcessMessage(Msg) do;
end;

procedure TACLMenuWindow.Animate(Show: Boolean = True);
const
  AnimateDuration = 150;
  UnfoldAnimationStyle: array[Boolean] of Integer = (
    AW_VER_POSITIVE or AW_HOR_POSITIVE or AW_SLIDE,
    AW_VER_NEGATIVE or AW_HOR_POSITIVE or AW_SLIDE);
  HideShow: array[Boolean] of Integer = (AW_HIDE, 0);
var
  LMenuAnimate: LongBool;
  LMenuPoint: TPoint;
begin
  if not RootMenu.FItemKeyed and Assigned(AnimateWindowProc) then
  begin
    SystemParametersInfo(SPI_GETMENUANIMATION, 0, @LMenuAnimate, 0);
    if (FParentMenu.FAnimatePopups or not Show) and LMenuAnimate and
      (IsWin10OrLater or (Style.CornerRadius.Value = 0)) // на старых ОС меню фликает при анимации, если задана маска
    then
    begin
      SystemParametersInfo(SPI_GETMENUFADE, 0, @LMenuAnimate, 0);
      if LMenuAnimate then
        AnimateWindowProc(Handle, AnimateDuration, AW_BLEND or HideShow[Show])
      else
      begin
        LMenuPoint := ParentControl.Parent.ClientToScreen(ParentControl.BoundsRect.TopLeft);
        AnimateWindowProc(Handle, AnimateDuration, UnfoldAnimationStyle[Top < LMenuPoint.Y - 5] or HideShow[Show]);
      end;
    end;
  end;
end;

procedure TACLMenuWindow.ClearSubMenus;
begin
  if Assigned(FPopupStack) then
  begin
    while FPopupStack.Count > 1 do
      FPopupStack.Peek.CloseMenu;   // CloseMenu pops the top menu off the stack
  end;
end;

procedure TACLMenuWindow.CloseMenu;
var
  ASelected: TACLMenuItemControl;
begin
  if FChildMenu <> nil then
    FChildMenu.CloseMenu;

  if Self is TACLMenuPopupWindow then // TODO-срань
    Visible := False;
  if RootMenu <> nil then
  begin
    RootMenu.FMousePos := Mouse.CursorPos;
    RootMenu.FDelayItem := nil;
  end;

  if ParentMenu <> nil then
    ParentMenu.FAnimatePopups := False;

  InMenuLoop := False;

  if (RootMenu <> nil) and (RootMenu.PopupStack <> nil) then
  begin
    if RootMenu.PopupStack.Peek = RootMenu then
    begin
      InMenuLoop := False;
      if FindSelected(ASelected) and (ASelected <> ControlAtPos(CalcCursorPos, True)) then
        ASelected.SetSelected(False, False);
    end
    else
      RootMenu.PopupStack.Pop;
  end;
end;

procedure TACLMenuWindow.TrackMenu;
begin
  if not InMenuLoop then
  begin
    RootMenu := Self;
    ProcessMenuLoop;
    if FSelectedItem <> nil then
    begin
      Update;
      if CanCloseMenuOnItemClick(FSelectedItem) then
        DoSelect(FSelectedItem);
    end;
  end;
end;

function TACLMenuWindow.TrackMenuOnSelect: Boolean;
begin
  Result := False;
end;

function TACLMenuWindow.TranslateCharCode(Code: Word): Word;
begin
  Result := Code;
end;

procedure TACLMenuWindow.ProcessMouseMessage(var Msg: TMsg);
var
  AControl: TControl;
begin
  case Msg.message of
    WM_MBUTTONDOWN, WM_RBUTTONDOWN, WM_RBUTTONDBLCLK, WM_LBUTTONDOWN, WM_LBUTTONDBLCLK:
      begin
        AControl := FindDragTarget(Msg.pt, True);
        while (AControl <> nil) and (AControl.Parent <> nil) do
          AControl := AControl.Parent;
        while (PopupStack.Count > 1) and (PopupStack.Peek <> AControl) do
          PopupStack.Pop;
        if PopupStack.Peek <> AControl then
          CloseMenu;
      end;
  end;
  DispatchMessage(Msg);
end;

procedure TACLMenuWindow.ProcessMouseWheel(var Msg: TMsg);
var
  AMenu: TACLMenuWindow;
  AMessage: TWMMouseWheel;
begin
  AMenu := PopupStack.Peek;
  if AMenu <> nil then
  begin
    TMessage(AMessage).WParam := Msg.wParam;
    TMessage(AMessage).LParam := Msg.lParam;
    AMenu.VisibleIndex := AMenu.VisibleIndex + Signs[AMessage.WheelDelta < 0];
  end;
end;

procedure TACLMenuWindow.CalculateBounds;
begin
  if ParentMenu <> nil then
    BoundsRect := ParentMenu.CalculatePopupBounds(CalculateMaxSize, Self)
  else
    BoundsRect := CalculatePopupBounds(CalculateMaxSize, nil);
  CalculateLayout;
end;

function TACLMenuWindow.CanCloseMenuOnItemClick(AItem: TMenuItem): Boolean;
begin
  if PopupMenu.Options.CloseMenuOnItemCheck then
    Result := True
  else
    Result := not AItem.AutoCheck;
end;

function TACLMenuWindow.DoItemClicked(AItem: TACLMenuItemControl): TMenuItem;

  function GetSelectedItem: TACLMenuItemControl;
  begin
    if not FindSelected(Result) then
      Result := nil;
  end;

var
  ASelectedItem: TACLMenuItemControl;
begin
  Result := nil;
  if AItem.Owner = Self then
    FDelayItem := nil;
  if AItem.HasSubItems then
  begin
    if FDelayItem <> nil then
    try
      while FPopupStack.Peek <> FDelayItem.Parent do
        RootMenu.PopupStack.Pop;
    finally
      FDelayItem := nil;
    end;
    ASelectedItem := GetSelectedItem;
    RootMenu.ProcessMessages;
    if GetSelectedItem <> ASelectedItem then
      Exit;
    if FPopupStack = nil then
      Exit;
    if AItem.Parent = RootMenu then
      ClearSubMenus;
    CreatePopup(FPopupStack.Peek, AItem);
    FAnimatePopups := False;
  end
  else
  begin
    Result := AItem.MenuItem;
    if CanCloseMenuOnItemClick(Result) then
    begin
      ClearSubMenus;
      CloseMenu;
    end
    else
    begin
      DoSelect(Result);
      AItem.Parent.Invalidate;
    end;
  end;
end;

function TACLMenuWindow.DoItemKeyed(AItem: TACLMenuItemControl): TMenuItem;
begin
  FItemKeyed := True;
  try
    Result := DoItemClicked(AItem);
    if Result = nil then
    begin
      // if the keyboard was used to display the popup then automatically
      // select the first item if the mouse was used no item is selected
      SelectItem(FPopupStack.Peek.FindFirstVisibleItem);
    end;
  finally
    FItemKeyed := False;
  end;
end;

procedure TACLMenuWindow.DoItemSelected(AItem: TACLMenuItemControl);
begin
  if AItem <> nil then
    RootMenu.FDelayItem := AItem
  else
    FDelayItem := nil;

  if RootMenu.FPopupTimer <> nil then
    RootMenu.FPopupTimer.Enabled := True;
end;

procedure TACLMenuWindow.DoSelect(Item: TMenuItem);
begin
  PopupMenu.DoSelect(Item);
end;

procedure TACLMenuWindow.AddMenuItem(AMenuItem: TMenuItem);
var
  AControl: TACLMenuItemControl;
  AContainer: TACLMenuContainerItem;
begin
  if not AMenuItem.Visible then
    Exit;
  if AMenuItem.IsLine and ((FItems.Count = 0) or FItems.Last.MenuItem.IsLine) then
    Exit;

  if not IsDesigning and Safe.Cast(AMenuItem, TACLMenuContainerItem, AContainer) then
  begin
    if not AContainer.HasSubItems then
      Exit;
    if AContainer.ExpandMode = lemExpandInplace then
    begin
      if AContainer.Enabled then
        AContainer.Expand(AddMenuItem);
      Exit;
    end;
  end;

  AControl := CreateMenuItemControl(AMenuItem);
  AControl.Parent := Self;
  FItems.Add(AControl);
end;

procedure TACLMenuWindow.Clear;
begin
  DisableAlign;
  try
    FItems.Clear;
  finally
    EnableAlign;
  end;
end;

procedure TACLMenuWindow.PopulateItems(AParentItem: TMenuItem);
var
  AContainer: TACLMenuContainerItem;
begin
  if AParentItem.Enabled then
  begin
    AParentItem.PrepareForShowing;
    if Safe.Cast(AParentItem, TACLMenuContainerItem, AContainer) and (AContainer.ExpandMode = lemExpandInSubMenu) then
      AContainer.Expand(AddMenuItem)
    else
      for var I := 0 to AParentItem.Count - 1 do
        AddMenuItem(AParentItem.Items[I]);

    if (FItems.Count > 0) and FItems.Last.MenuItem.IsLine then
      FItems.Delete(FItems.Count - 1);
  end;
end;

procedure TACLMenuWindow.CMEnabledchanged(var Message: TMessage);
begin
  inherited;
  Broadcast(Message);
end;

procedure TACLMenuWindow.CMEnterMenuLoop(var Message: TMessage);
begin
  TrackMenu;
end;

procedure TACLMenuWindow.WMPaint(var Message: TWMPaint);
begin
  if not (csCustomPaint in ControlState) then
  begin
    ControlState := ControlState + [csCustomPaint];
    inherited;
    ControlState := ControlState - [csCustomPaint];
  end;
end;

procedure TACLMenuWindow.CMItemClicked(var Message: TMessage);
var
  ASelected: TACLMenuItemControl;
begin
  if FInMenuLoop then
    Exit;
  ASelected := TACLMenuItemControl(Message.LParam);
  if (ASelected <> nil) and ASelected.Selected then
  begin
    PostMessage(Handle, Message.Msg, 0, Message.LParam);
    TrackMenu;
  end;
end;

procedure TACLMenuWindow.CMItemKeyed(var Message: TMessage);
begin
  CMItemClicked(Message);
end;

procedure TACLMenuWindow.CMMouseLeave(var Message: TMessage);
var
  ASelected: TACLMenuItemControl;
begin
  inherited;
  if FindSelected(ASelected) and (ASelected.SubMenu = nil) then
    ASelected.SetSelected(False);
end;

procedure TACLMenuWindow.DoMenuDelay(Sender: TObject);
var
  P: TPoint;
begin
  FPopupTimer.Enabled := False;
  if (FDelayItem = nil) or (FDelayItem.Parent = nil) or (FDelayItem.SubMenu <> nil) then
    Exit;

  while (RootMenu.PopupStack.Count > 1) and (RootMenu.PopupStack.Peek <> FDelayItem.Parent) do
    RootMenu.PopupStack.Pop;

  GetCursorPos(P);
  if PtInRect(FDelayItem.BoundsRect, FPopupStack.Peek.ScreenToClient(P)) then
    CreatePopup(FPopupStack.Peek, FDelayItem);
end;

procedure TACLMenuWindow.Select(AForward: Boolean);

  function SkipItems(AForward: Boolean; out ANextItem: TACLMenuItemControl): Boolean;
  var
    ALoop: Boolean;
  begin
    ALoop := True;
    if not FindSelected(ANextItem) then
      ANextItem := nil;
    while ALoop do
    begin
      if AForward then
        ANextItem := FindNext(ANextItem)
      else
        ANextItem := FindPrevious(ANextItem);

      if Assigned(ANextItem) then
      begin
        if not ANextItem.MenuItem.IsLine and ANextItem.Visible then
          Break;
      end;
      ALoop := Assigned(ANextItem);
    end;
    Result := Assigned(ANextItem);
  end;

var
  ANextItem: TACLMenuItemControl;
begin
  if SkipItems(AForward, ANextItem) then
  begin
    if FChildMenu <> nil then
      FChildMenu.CloseMenu;
    if RootMenu.PopupStack.Peek = Self then
    begin
      EnsureNextItemVisible(ANextItem);
      if TrackMenuOnSelect then
        ANextItem.Keyed
      else
        SelectItem(ANextItem);
    end
    else
      if (ANextItem.Parent = Self) and Assigned(ANextItem.Action) then
      begin
        RootMenu.PopupStack.Peek.FInMenuLoop := False;
        RootMenu.FDelayItem := nil;
        EnsureNextItemVisible(ANextItem);
        SelectItem(ANextItem);
      end
      else
        ANextItem.Keyed;
  end;
end;

procedure TACLMenuWindow.SelectItem(AItem: TACLMenuItemControl);
begin
  if AItem <> nil then
    AItem.SetSelected(True);
end;

function TACLMenuWindow.GetStyle: TACLStylePopupMenu;
begin
  Result := PopupMenu.Style;
end;

procedure TACLMenuWindow.SetParentMenu(AValue: TACLMenuWindow);
begin
  if FParentMenu <> AValue then
  begin
    FParentMenu := AValue;
    if FParentMenu <> nil then
      FParentMenu.FChildMenu := Self;
  end;
end;

procedure TACLMenuWindow.WMKeyDown(var Message: TWMKeyDown);
var
  ACharCode: Integer;
  AItem: TACLMenuItemControl;
begin
  case TranslateCharCode(Message.CharCode) of
    VK_LEFT:
      if Assigned(FChildMenu) then
      begin
        FChildMenu.FInMenuLoop := False;
        FChildMenu := nil;
        Message.Result := 0;
      end
      else
        if ParentMenu <> nil then
          ParentMenu.Dispatch(Message);

    VK_RIGHT:
      if FindSelected(AItem) then
      begin
        if AItem.HasSubItems and (AItem.SubMenu = nil) and AItem.Enabled then
          AItem.Keyed
        else
          if FPopupStack = nil then
            RootMenu.Dispatch(Message);
      end
      else
        if RootMenu <> Self then
          RootMenu.Dispatch(Message);
  end;

  if not TACLMenuController.IsValid(Self) then
    Exit;

  inherited;

  if not FInMenuLoop then
    Exit;

  if (RootMenu <> nil) and (Message.CharCode in [Ord('0')..Ord('9'), Ord('A')..Ord('Z'), VK_NUMPAD0..VK_NUMPAD9]) then
  begin
    if not (ssCtrl in KeyboardStateToShiftState) then
    begin
      ACharCode := Message.CharCode;
      if Message.CharCode in [VK_NUMPAD0..VK_NUMPAD9] then
        ACharCode := Ord('0') + Message.CharCode - VK_NUMPAD0;
      AItem := RootMenu.PopupStack.Peek.FindAccelItem(ACharCode);
      if AItem <> nil then
        AItem.Keyed;
    end;
  end;

  case TranslateCharCode(Message.CharCode) of
    VK_UP:
      Select(False);
    VK_DOWN:
      Select(True);
    VK_ESCAPE:
      CloseMenu;

    VK_RETURN:
      if FindSelected(AItem) then
        AItem.Keyed;

    VK_HOME, VK_END:
      begin
        if Message.CharCode = VK_HOME then
          AItem := FindFirstVisibleItem
        else
          AItem := FindLastVisibleItem;

        EnsureNextItemVisible(AItem);
        SelectItem(AItem);
      end;
  end;
end;

procedure TACLMenuWindow.WMMouseActivate(var Message: TWMMouseActivate);
begin
  inherited;
  if FInMenuLoop then
    Message.Result := MA_NOACTIVATE;
end;

procedure TACLMenuWindow.WMPrintClient(var Message: TWMPrintClient);
begin
  inherited;
  PaintTo(Message.DC, 0, 0);
end;

procedure TACLMenuWindow.DoActionIdle;
var
  AForm: TCustomForm;
begin
  for var I := 0 to Screen.CustomFormCount - 1 do
  begin
    AForm := Screen.CustomForms[I];
    if AForm.HandleAllocated and IsWindowVisible(AForm.Handle) and IsWindowEnabled(AForm.Handle) then
      AForm.Perform(CM_UPDATEACTIONS, 0, 0);
  end;
end;

procedure TACLMenuWindow.DoActionIdleTimerProc(Sender: TObject);
begin
  try
    FActionIdleTimer.Enabled := False;
    DoActionIdle;
  except
    Application.HandleException(Application);
  end;
end;

function TACLMenuWindow.GetCurrentDpi: Integer;
begin
  if ParentMenu <> nil then
    Result := ParentMenu.GetCurrentDpi
  else
    Result := PopupMenu.CurrentDpi;
end;

function TACLMenuWindow.GetMenuDelayTime: Integer;
begin
  SystemParametersInfo(SPI_GETMENUSHOWDELAY, 0, @Result, 0);
  if Result = 0 then
    Result := 1;
end;

function TACLMenuWindow.IsDesigning: Boolean;
begin
  Result := csDesigning in ComponentState;
end;

procedure TACLMenuWindow.SetVisibleIndex(AValue: Integer);
begin
  AValue := MinMax(AValue, 0, FItems.Count - FItemNumberInDisplayArea);
  if FVisibleIndex <> AValue then
  begin
    FVisibleIndex := AValue;
    CalculateLayout;
    Invalidate;
  end;
end;

{ TACLMenuPopupWindow }

constructor TACLMenuPopupWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FScrollTimer := TACLTimer.CreateEx(DoScrollTimer, 125);
  Visible := False;
end;

constructor TACLMenuPopupWindow.Create(AOwner: TACLMenuWindow);
begin
  Create(TComponent(AOwner));
  FPopupMenu := AOwner.FPopupMenu;
  RootMenu := AOwner.RootMenu;
  ParentWindow := AOwner.Handle;
  ParentMenu := AOwner;
  Font := AOwner.Font;
end;

destructor TACLMenuPopupWindow.Destroy;
begin
  FreeAndNil(FScrollTimer);
  FreeAndNil(FScrollBar);
  inherited;
end;

procedure TACLMenuPopupWindow.CalculateBounds;
var
  AHasScrollBar: Boolean;
begin
  repeat
    AHasScrollBar := ScrollBar <> nil;
    inherited;
  until AHasScrollBar = (ScrollBar <> nil);
end;

procedure TACLMenuPopupWindow.CalculateLayout;
var
  AAlignRect: TRect;
  AControl: TACLMenuItemControl;
  AControlHeight: Integer;
begin
  AAlignRect := ClientRect;
  CalculateScrollBar(AAlignRect);

  for var I := 0 to FItems.Count - 1 do
    FItems[I].SetBounds(0, 0, 0, 0); // hide all controls

  FItemNumberInDisplayArea := 0;
  for var I := VisibleIndex to FItems.Count - 1 do
  begin
    AControl := FItems[I];
    if AControl.Visible then
    begin
      AControlHeight := AControl.MeasureSize(MeasureCanvas).Height;
      AControl.SetBounds(AAlignRect.Left, AAlignRect.Top, AAlignRect.Width, AControlHeight);
      Inc(AAlignRect.Top, AControlHeight);
      if AAlignRect.Top > AAlignRect.Bottom then
      begin
        Dec(AAlignRect.Top, AControlHeight);
        Break;
      end;
      Inc(FItemNumberInDisplayArea);
    end;
  end;

  if AAlignRect.IsEmpty then
    FScrollButtonRestArea := NullRect
  else
  begin
    FScrollButtonRestArea := AAlignRect;
    FScrollButtonRestArea.Height := Style.ItemHeight;
  end;
end;

function TACLMenuPopupWindow.CalculateMaxSize: TSize;
var
  ABorders: TRect;
  AItem: TACLMenuItemControl;
  AItemSize: TSize;
begin
  Result := NullSize;
  for var I := 0 to FItems.Count - 1 do
  begin
    AItem := FItems[I];
    if AItem.Visible then
    begin
      AItemSize := AItem.MeasureSize(MeasureCanvas);
      Result.cx := Max(Result.cx, AItemSize.cx);
      Inc(Result.cy, AItemSize.cy);
    end;
  end;
  if ScrollBar <> nil then
    Inc(Result.cx, ScrollBar.Width);
  ABorders := GetBorderWidths;
  Inc(Result.cx, ABorders.MarginsWidth);
  Inc(Result.cy, ABorders.MarginsHeight);
end;

procedure TACLMenuPopupWindow.CalculateScrollBar(var R: TRect);
var
  AUseScrollButtons: Boolean;
begin
  if CalculateMaxSize.Height > Height then
  begin
    AUseScrollButtons :=
      (PopupMenu.Options.ScrollMode = smScrollButtons) or
      (PopupMenu.Options.ScrollMode = smAuto) and PopupMenu.Style.TextureScrollBar.Empty;

    if AUseScrollButtons then
    begin
      FreeAndNil(FScrollBar);
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
        FScrollBar := CreateScrollBar;
        FScrollBar.Parent := Self;
        FScrollBar.OnScroll := DoScroll;
      end;
      ScrollBar.BoundsRect := R.Split(srRight, FScrollBar.Width);
      ScrollBar.SetScrollParams(0, FItems.Count - 1, VisibleIndex, FItemNumberInDisplayArea);
      Dec(R.Right, ScrollBar.Width);
    end;
  end
  else
    FreeAndNil(FScrollBar);
end;

function TACLMenuPopupWindow.CalculatePopupBounds(ASize: TSize; AChild: TACLMenuWindow): TRect;
const
  ShadowOffset = 4;
var
  AParentRect: TRect;
  AWorkArea: TRect;
begin
  AWorkArea := MonitorGetWorkArea(ClientOrigin);
  if AChild <> nil then
  begin
    AParentRect := AChild.ParentControl.BoundsRect + ClientOrigin;
    AParentRect.Offset(0, -GetBorderWidths.Top);
    Result.Left := AParentRect.Right;
    Result.Top := AParentRect.Top;
    if Result.Left + ASize.Width > AWorkArea.Right then
      Result.Left := AParentRect.Left - ASize.Width;
    if Result.Top + ASize.Height > AWorkArea.Bottom then
      Result.Top := AParentRect.Bottom - ASize.Height;
  end
  else
  begin
    Result := acGetWindowRect(Handle);
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

procedure TACLMenuPopupWindow.CheckAutoScrollTimer(const P: TPoint);
begin
  if PtInRect(ScrollButtonUp, P) then
    FScrollTimer.Tag := 1
  else if PtInRect(ScrollButtonDown, P) then
    FScrollTimer.Tag := -1
  else
    FScrollTimer.Tag := 0;

  FScrollTimer.Enabled := FScrollTimer.Tag <> 0;
end;

procedure TACLMenuPopupWindow.CreateParams(var Params: TCreateParams);
var
  ADisplayShadow: LongBool;
begin
  inherited;
  if not (Parent is TCustomForm) then
    Params.Style := Params.Style and not WS_CHILD or WS_POPUP or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or WS_OVERLAPPED;
  Params.WindowClass.Style := CS_SAVEBITS or CS_DBLCLKS or not (CS_HREDRAW or not CS_VREDRAW);
  if CheckWin32Version(5, 1) and SystemParametersInfo(SPI_GETDROPSHADOW, 0, @ADisplayShadow, 0) and ADisplayShadow then
    Params.WindowClass.Style := Params.WindowClass.Style or CS_DROPSHADOW;
  Params.ExStyle := Params.ExStyle or WS_EX_TOPMOST;
end;

function TACLMenuPopupWindow.CreateScrollBar: TACLScrollBar;
begin
  Result := TACLScrollBar.Create(nil);
  Result.Kind := sbVertical;
  Result.Style.BeginUpdate;
  try
    Result.Style.Collection := PopupMenu.Style.Collection;
    Result.Style.TextureBackgroundVert := PopupMenu.Style.TextureScrollBar;
    Result.Style.TextureButtonsVert := PopupMenu.Style.TextureScrollBarButtons;
    Result.Style.TextureThumbVert := PopupMenu.Style.TextureScrollBarThumb;
    Result.Style.TargetDPI := GetCurrentDpi;
  finally
    Result.Style.EndUpdate;
  end;
end;

procedure TACLMenuPopupWindow.CreateWnd;
begin
  inherited;
  FormSetCorners(Handle, afcRectangular);
end;

procedure TACLMenuPopupWindow.DoScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  VisibleIndex := ScrollPos;
  ScrollPos := VisibleIndex;
end;

procedure TACLMenuPopupWindow.DoScrollTimer(Sender: TObject);
begin
  CheckAutoScrollTimer(CalcCursorPos);
  if FScrollTimer.Enabled then
    VisibleIndex := VisibleIndex + ScrollTimer.Tag;
end;

procedure TACLMenuPopupWindow.MouseMove(Shift: TShiftState; X: Integer; Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  CheckAutoScrollTimer(Point(X, Y));
end;

function TACLMenuPopupWindow.GetBorderWidths: TRect;
begin
  Result := dpiApply(Style.Borders.Value, GetCurrentDpi);
end;

procedure TACLMenuPopupWindow.NCPaint(DC: HDC);
var
  ACanvas: TCanvas;
  ARect: TRect;
  ASaveIndex: Integer;
begin
  ASaveIndex := SaveDC(DC);
  try
    ARect := Bounds(0, 0, Width, Height);
    acExcludeFromClipRegion(DC, ARect.Split(GetBorderWidths));

    ACanvas := TCanvas.Create;
    try
      ACanvas.Lock;
      try
        ACanvas.Handle := DC;
        Style.DrawBorder(ACanvas, ARect);
        ACanvas.Handle := 0;
      finally
        ACanvas.Unlock;
      end;
    finally
      ACanvas.Free;
    end;
  finally
    RestoreDC(DC, ASaveIndex);
  end;
end;

procedure TACLMenuPopupWindow.Popup(X, Y: Integer);
begin
  if FItems.Count > 0 then
  begin
    ParentWindow := TACLApplication.GetHandle;
    RootMenu := Self;
    SetBounds(X, Y, Width, Height);
    Visible := True;
    TrackMenu;
  end;
end;

procedure TACLMenuPopupWindow.PopupEx(AMenuItem: TMenuItem; const AControlRect: TRect);
begin
  Clear;
  FControlRect := MonitorAlignPopupWindow(AControlRect);
  PopulateItems(AMenuItem);
  Popup(FControlRect.Left, FControlRect.Bottom + 1);
end;

procedure TACLMenuPopupWindow.Resize;
var
  LBitmap: TACLBitmapLayer;
  LRadius: Integer;
  LRegion: HRGN;
begin
  inherited;

  LRegion := 0;
  LRadius := 2 * Style.CornerRadius.Value;
  if LRadius > 0 then
  begin
    LBitmap := TACLBitmapLayer.Create(BoundsRect);
    try
      LBitmap.Canvas.Brush.Color := clFuchsia;
      LBitmap.Canvas.FillRect(LBitmap.ClientRect);
      LBitmap.Canvas.Pen.Color := clWhite;
      LBitmap.Canvas.Brush.Color := clWhite;
      LBitmap.Canvas.RoundRect(LBitmap.ClientRect, LRadius, LRadius);
      LRegion := acRegionFromBitmap(@LBitmap.Colors[0], LBitmap.Width, LBitmap.Height, clFuchsia);
    finally
      LBitmap.Free;
    end;
  end;
  SetWindowRgn(Handle, LRegion, True);
end;

procedure TACLMenuPopupWindow.DrawScrollButton(ACanvas: TCanvas; const R: TRect; ATop, AEnabled: Boolean);
begin
  Style.DrawBackground(ACanvas, R, False);
  Style.DrawScrollButton(ACanvas, R, ATop, AEnabled);
end;

procedure TACLMenuPopupWindow.DrawScrollButtons(ACanvas: TCanvas);
begin
  if FScrollBar <> nil then
    Style.DrawBackground(ACanvas, FScrollBar.BoundsRect, False);
  if not FScrollButtonRestArea.IsEmpty then
    Style.DrawBackground(ACanvas, FScrollButtonRestArea, False);
  if not FScrollButtonDown.IsEmpty then
    DrawScrollButton(ACanvas, FScrollButtonDown, True, VisibleIndex > 0);
  if not FScrollButtonUp.IsEmpty then
    DrawScrollButton(ACanvas, FScrollButtonUp, False, VisibleIndex + FItemNumberInDisplayArea < FItems.Count);
end;

procedure TACLMenuPopupWindow.Paint;
begin
  inherited Paint;
  DrawScrollButtons(Canvas);
end;

procedure TACLMenuPopupWindow.WMNCCalcSize(var Message: TWMNCCalcSize);
begin
  Message.CalcSize_Params^.rgrc0.Content(GetBorderWidths);
end;

procedure TACLMenuPopupWindow.WMNCPaint(var Message: TWMNCPaint);
var
  DC: HDC;
begin
  DC := GetWindowDC(Handle);
  try
    NCPaint(DC);
  finally
    ReleaseDC(Handle, DC);
  end;
end;

procedure TACLMenuPopupWindow.WMPrint(var Message: TWMPrint);
begin
  inherited;
  NCPaint(Message.DC);
end;

{ TACLMenuItemControl }

constructor TACLMenuItemControl.Create;
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csActionClient] - [csCaptureMouse];
  SetBounds(0, 0, 22, 22);
  ParentShowHint := True;

  FMenuItem := AMenuItem;
  Action := AMenuItem.Action;
  Caption := AMenuItem.Caption;
end;

destructor TACLMenuItemControl.Destroy;
begin
  if SubMenu <> nil then
    SubMenu.CloseMenu;
  inherited Destroy;
end;

procedure TACLMenuItemControl.Click;
begin
  acSafeSetFocus(GetParentForm(Menu.RootMenu));
end;

procedure TACLMenuItemControl.SetSelected(ASelected, AIsMouseAction: Boolean);
begin
  FMouseSelected := ASelected and AIsMouseAction;
  if Selected <> ASelected then
  begin
    FSelected := ASelected;
    if Selected then
    begin
//      if Menu.ParentMenu <> nil then
//      begin
//        AParentItem := TACLMenuItemControl(Client.ParentItem);
//        AParentItem.Control.Selected := True;
//      end;
      UpdateSelection;
    end;

    if Selected then
    begin
      if Action <> nil then
        Application.Hint := GetLongHint(TCustomAction(Action).Hint)
      else
        Application.CancelHint;
    end;

    if Selected then
      Menu.DoItemSelected(Self);

    Invalidate;
  end;
end;

procedure TACLMenuItemControl.UpdateSelection;
var
  AMessage: TMessage;
begin
  // MenuItems can be selected but they don't have to be enabled
  if Parent <> nil then
  begin
    AMessage.Msg := CM_ITEMSELECTED;
    AMessage.WParam := 0;
    AMessage.LParam := LPARAM(Self);
    AMessage.Result := 0;
    Parent.Broadcast(AMessage);
  end;
end;

procedure TACLMenuItemControl.CMItemSelected(var Message: TMessage);
begin
  SetSelected(Message.LParam = NativeInt(Self));
end;

procedure TACLMenuItemControl.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  SetSelected(True, True);
end;

procedure TACLMenuItemControl.Keyed;
begin
  SetSelected(True, False);
  CheckAction(Action);
  if Parent <> nil then
    PostMessage(Parent.Handle, CM_ITEMKEYED, 0, LPARAM(Self));
end;

function TACLMenuItemControl.MeasureSize(ACanvas: TCanvas): TSize;
begin
  if MenuItem.IsLine then
  begin
    Result.cx := 0;
    Result.cy := Style.SeparatorHeight;
  end
  else
  begin
    Result.cx := Style.MeasureWidth(ACanvas, MenuItem.Caption, MenuItem.ShortCut, MenuItem.Default);
    Result.cy := Style.ItemHeight;
  end;
end;

procedure TACLMenuItemControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;

  if (SubMenu = nil) and MenuItem.Enabled then
  begin
    CheckAction(Action);
    if not MenuItem.IsLine then
      PostMessage(Parent.Handle, CM_ITEMCLICKED, 0, LPARAM(Self));
  end;
end;

procedure TACLMenuItemControl.Paint;
var
  R: TRect;
begin
  R := ClientRect;
  if MenuItem.IsLine then
    Style.DrawSeparator(Canvas, R)
  else
  begin
    Style.DrawBackground(Canvas, R, Selected);
    Style.DrawItem(Canvas, R, Caption, MenuItem.ShortCut,
      Selected, MenuItem.Default, MenuItem.Enabled, HasSubItems);
    R.Width := Style.ItemGutterWidth;
    Style.DrawItemImage(Canvas, R, MenuItem, Selected);
  end;
end;

procedure TACLMenuItemControl.CMHintShow(var Message: TCMHintShow);
var
  AHintInfo: PHintInfo;
begin
  AHintInfo := Message.HintInfo;
  if ActionLink <> nil then
  begin
    if not TControlActionLinkAccess(ActionLink).DoShowHint(AHintInfo.HintStr) then
      Message.Result := 1;
  end
  else
  begin
    AHintInfo.HintStr := MenuItem.Hint;
    if Application.HintShortCuts and (MenuItem.ShortCut <> scNone) then
      AHintInfo.HintStr := Format('%s (%s)', [AHintInfo.HintStr, ShortCutToText(MenuItem.ShortCut)]);
  end;
end;

function TACLMenuItemControl.GetStyle: TACLStylePopupMenu;
begin
  Result := Menu.PopupMenu.Style;
end;

procedure TACLMenuItemControl.CheckAction(Action: TBasicAction);
var
  AAction: TCustomAction;
begin
  if Action is TCustomAction then
  begin
    AAction := TCustomAction(Action);
    if (AAction.GroupIndex > 0) and not AAction.AutoCheck then
      AAction.Checked := True;
  end;
end;

function TACLMenuItemControl.GetMenu: TACLMenuWindow;
begin
  Result := Parent as TACLMenuWindow;
end;

function TACLMenuItemControl.GetIndex: Integer;
begin
  Result := Menu.FItems.IndexOf(Self)
end;

function TACLMenuItemControl.HasSubItems: Boolean;
var
  AContainer: TACLMenuContainerItem;
begin
  Result := (MenuItem.Count > 0) or
    (Safe.Cast(MenuItem, TACLMenuContainerItem, AContainer)) and
    (AContainer.ExpandMode = lemExpandInSubMenu);
end;

{ TACLMenuController }

class function TACLMenuController.IsValid(AMenu: TACLMenuWindow): Boolean;
begin
  Result := (FMenus <> nil) and (FMenus.IndexOf(AMenu) >= 0);
end;

class procedure TACLMenuController.Register(ABar: TACLMenuWindow);
begin
  if FMenus = nil then
  begin
    FMenus := TList.Create;
    FHook := SetWindowsHookEx(WH_CALLWNDPROC, @CallWindowHook, 0, GetCurrentThreadID);
  end;
  FMenus.Add(ABar);
end;

class procedure TACLMenuController.Unregister(ABar: TACLMenuWindow);
begin
  if FMenus <> nil then
  begin
    FMenus.Remove(ABar);
    if FMenus.Count = 0 then
    begin
      UnHookWindowsHookEx(FHook);
      FHook := 0;
      FreeAndNil(FMenus);
    end;
  end;
end;

class function TACLMenuController.CallWindowHook(Code: Integer; wparam: WPARAM; Msg: PCWPStruct): Longint; stdcall;
begin
  if Code = HC_ACTION then
  begin
    if Msg.message = WM_ACTIVATE then
    begin
      if ActiveMenu <> nil then
        ActiveMenu.CloseMenu;
    end;
  end;
  Result := CallNextHookEx(FHook, Code, WParam, NativeInt(Msg));
end;

{$ENDREGION}

{$REGION ' MainMenu '}

{ TACLMainMenu }

constructor TACLMainMenu.Create(AOwner: TComponent);
begin
  inherited;
  Align := alTop;
  ControlStyle := ControlStyle + [csMenuEvents];
  FStyle := TACLStyleMenu.Create(Self);
  RootMenu := Self;
  AutoSize := True;
end;

destructor TACLMainMenu.Destroy;
begin
  TACLMainThread.Unsubscribe(Self);
  FreeAndNil(FStyle);
  inherited;
end;

procedure TACLMainMenu.AdjustSize;
begin
  if HandleAllocated then
  begin
    Height := CalculateMaxSize.Height;
    CalculateLayout;
  end;
end;

procedure TACLMainMenu.CalculateLayout;
var
  AAlignRect: TRect;
  AControl: TACLMenuItemControl;
  AControlWidth: Integer;
begin
  AAlignRect := ClientRect;
  FItemNumberInDisplayArea := 0;
  for var I := 0 to FItems.Count - 1 do
  begin
    AControl := FItems[I];
    if AControl.Visible then
    begin
      AControlWidth := AControl.MeasureSize(MeasureCanvas).Width;
      AControl.SetBounds(AAlignRect.Left, AAlignRect.Top, AControlWidth, AAlignRect.Height);
      Inc(AAlignRect.Left, AControlWidth);
      Inc(FItemNumberInDisplayArea);
    end
    else
      AControl.SetBounds(0, 0, 0, 0);
  end;
end;

function TACLMainMenu.CalculateMaxSize: TSize;
begin
  Result := TSize.Create(1, Style.ItemHeight);
end;

function TACLMainMenu.CalculatePopupBounds(ASize: TSize; AChild: TACLMenuWindow): TRect;
begin
  Result.TopLeft := ClientToScreen(Point(0, Height));
  if AChild <> nil then
    Result.Left := AChild.ParentControl.ClientOrigin.X;
  Result.Size := ASize;
end;

function TACLMainMenu.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  NewHeight := CalculateMaxSize.Height;
  Result := True;
end;

function TACLMainMenu.CanCloseMenuOnItemClick(AItem: TMenuItem): Boolean;
begin
  Result := AItem.Parent <> Menu.Items;
end;

procedure TACLMainMenu.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;
  if Menu <> nil then
    Menu.ScaleForDpi(FCurrentPPI);
  Style.SetTargetDPI(FCurrentPPI);
  AdjustSize;
end;

procedure TACLMainMenu.CheckShortCut(var Msg: TWMKey; var Handled: Boolean);
begin
  if (Menu <> nil) and Menu.IsShortCut(Msg) then
    Handled := True;
end;

function TACLMainMenu.CreateMenuItemControl(AMenuItem: TMenuItem): TACLMenuItemControl;
begin
  Result := TACLMainMenuItemControl.Create(Self, AMenuItem);
end;

function TACLMainMenu.GetCurrentDpi: Integer;
begin
  Result := FCurrentPPI;
end;

function TACLMainMenu.GetMenuDelayTime: Integer;
begin
  Result := 1;
end;

procedure TACLMainMenu.HandlerMenuChange(Sender: TObject; Source: TMenuItem; Rebuild: Boolean);
begin
  Self.Rebuild;
end;

procedure TACLMainMenu.Localize(const ASection: string);
begin
  if Menu <> nil then
    TACLMainThread.RunPostponed(Rebuild, Self);
end;

procedure TACLMainMenu.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;
  if (AComponent = Menu) and (AOperation = opRemove) then
    Menu := nil;
end;

procedure TACLMainMenu.Rebuild;
begin
  DisableAlign;
  try
    Clear;
    if not (csDestroying in ComponentState) and (Menu <> nil) then
    begin
      Menu.ScaleForDpi(GetCurrentDpi);
      for var I := 0 to Menu.Items.Count - 1 do
        AddMenuItem(Menu.Items[I]);
    end;
    AdjustSize;
  finally
    EnableAlign;
  end;
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
      FMenu.OnChange := HandlerMenuChange;
    end;
    FPopupMenu := Menu;
    Rebuild;
  end;
end;

procedure TACLMainMenu.SetStyle(AValue: TACLStyleMenu);
begin
  FStyle.Assign(AValue);
end;

function TACLMainMenu.TrackMenuOnSelect: Boolean;
begin
  Result := True;
end;

function TACLMainMenu.TranslateCharCode(Code: Word): Word;
begin
  case Code of
    VK_LEFT:
      Result := VK_UP;
    VK_RIGHT:
      Result := VK_DOWN;
    VK_DOWN:
      Result := VK_RIGHT;
    VK_UP:
      Result := VK_LEFT;
  else
    Result := Code;
  end;
end;

procedure TACLMainMenu.WMSysCommand(var Message: TWMSysCommand);
var
  AItem: TACLMenuItemControl;
begin
  if (GetParentForm(Self) <> Screen.FocusedForm) and (Application.ModalLevel <> 0) then
    Exit;

  if not InMenuLoop and Enabled and Showing then
  begin
    if (Message.CmdType and $FFF0 = SC_KEYMENU) and
      (Message.Key <> VK_SPACE) and
      (Message.Key <> Word('-')) and
      (GetCapture = 0) then
    begin
      if Message.Key <> 0 then
      begin
        AItem := FindAccelItem(Message.Key);
        if AItem <> nil then
        begin
          AItem.Keyed;
          Message.Result := 1;
        end;
      end
      else
        if not FCancelMenu then
        begin
          AItem := FindFirstVisibleItem;
          if AItem <> nil then
            AItem.SetSelected(True);
          PostMessage(Handle, CM_ENTERMENULOOP, 0, 0);
        end;

      FCancelMenu := False;
      Message.Result := 1;
    end;
  end;
end;

procedure TACLMainMenu.WMSysKeyDown(var Message: TWMSysKeyDown);
begin
  FCancelMenu := Message.CharCode = VK_MENU;
  inherited;
end;

procedure TACLMainMenu.WMSysKeyUp(var Message: TWMSysKeyUp);
begin
  FCancelMenu := Message.CharCode = VK_MENU;
  inherited;
end;

{ TACLMainMenuItemControl }

function TACLMainMenuItemControl.HasGlyph: Boolean;
var
  AIntf: IACLGlyph;
begin
  Result := (MenuItem.ImageIndex >= 0) or not MenuItem.Bitmap.Empty or
    Supports(MenuItem, IACLGlyph, AIntf) and not AIntf.GetGlyph.Empty;
end;

function TACLMainMenuItemControl.MeasureSize(ACanvas: TCanvas): TSize;
begin
  Result.cx := Style.MeasureWidth(ACanvas, Caption);
  Result.cy := Style.ItemHeight;
  if HasGlyph then
  begin
    Inc(Result.cx, dpiApply(TACLStyleMenu.GlyphSize, FCurrentPPI));
    if Caption <> '' then
      Inc(Result.cx, dpiApply(acTextIndent, FCurrentPPI));
  end;
end;

procedure TACLMainMenuItemControl.Paint;
var
  LImageRect: TRect;
  LRect: TRect;
begin
  LRect := ClientRect;
  Style.DrawBackground(Canvas, LRect, Selected);
  LRect.Inflate(-Style.GetTextIdent, 0);
  if Caption <> '' then
  begin
    if HasGlyph then
    begin
      LImageRect := LRect;
      LImageRect.Width := dpiApply(TACLStyleMenu.GlyphSize, FCurrentPPI);
      Style.DrawItemImage(Canvas, LImageRect, MenuItem, Selected);
      LRect.Left := LImageRect.Right + dpiApply(acTextIndent, FCurrentPPI);
    end;
    Style.AssignFontParams(Canvas, Selected, MenuItem.Default, MenuItem.Enabled);
    acTextDraw(Canvas, Caption, LRect, taLeftJustify, taVerticalCenter, True);
  end
  else
    Style.DrawItemImage(Canvas, LRect, MenuItem, Selected);
end;

function TACLMainMenuItemControl.Style: TACLStyleMenu;
begin
  Result := TACLMainMenu(Owner).Style;
end;

{$ENDREGION}

initialization
  RegisterClasses([TACLMenuItem, TACLMenuItemLink, TACLMenuListItem]);
end.
