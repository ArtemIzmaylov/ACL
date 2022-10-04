{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Skinned PopupMenu             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.PopupMenu;

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
  ACL.Classes.Timer,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.TextLayout,
  ACL.Graphics.Layers,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.Math,
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
  ACL.Utils.DPIAware;

type
  TMenuItemClass = class of TMenuItem;
  TMenuItemEnumProc = reference to procedure (AMenuItem: TMenuItem);

  { IACLMenuShowHandler }

  IACLMenuShowHandler = interface
  ['{82B0E75A-647F-43C9-B05A-54E34D0EBD85}']
    procedure OnShow;
  end;

  { IACLMenuItemLink }

  TACLMenuItemLinkExpandMode = (lemExpandInplace, lemExpandInSubMenu, lemNoExpand);

  IACLMenuItemLink = interface
  ['{FA490A1C-3C9F-46AB-B388-DE7416715E2B}']
    procedure Enum(AProc: TMenuItemEnumProc);
    function GetExpandMode: TACLMenuItemLinkExpandMode;
    function HasSubItems: Boolean;
  end;

  { TACLMenuItem }

  TACLMenuItem = class(TMenuItem,
    IACLGlyph,
    IACLMenuShowHandler,
    IACLScaleFactor)
  strict private
    FGlyph: TACLGlyph;

    FOnShow: TNotifyEvent;

    procedure SetGlyph(AValue: TACLGlyph);
  protected
    function IsCheckItem: Boolean; virtual;
    // IACLGlyph
    function GetGlyph: TACLGlyph;
    // IACLMenuShowHandler
    procedure IACLMenuShowHandler.OnShow = DoShow;
    procedure DoShow; virtual;
    // IACLScaleFactor
    function GetScaleFactor: TACLScaleFactor;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Glyph: TACLGlyph read FGlyph write SetGlyph;
    //
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
  end;

  { TACLMenuItemLink }

  TACLMenuItemLink = class(TACLMenuItem, IACLMenuItemLink)
  strict private
    FExpandMode: TACLMenuItemLinkExpandMode;
    FLink: TComponent;

    procedure SetLink(AValue: TComponent);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    // IACLMenuShowHandler
    procedure DoShow; override;
    // IACLMenuItemLink
    procedure Enum(AProc: TMenuItemEnumProc); virtual;
    function GetExpandMode: TACLMenuItemLinkExpandMode; virtual;
    function HasSubItems: Boolean; virtual;
  public
    destructor Destroy; override;
  published
    property ExpandMode: TACLMenuItemLinkExpandMode read FExpandMode write FExpandMode default lemExpandInplace;
    property Link: TComponent read FLink write SetLink;
  end;

  { TACLStyleMenu }

  TACLStyleMenu = class(TACLStyle)
  strict private
    FItemHeight: Integer;

    function GetBackgroundColor(ASelected: Boolean): TColor; inline;
    function GetItemGutterWidth: Integer; inline;
    function GetItemHeight: Integer; inline;
    function GetSeparatorHeight: Integer; inline;
    function GetTextIdent: Integer; inline;
    function IsCheckItem(AItem: TMenuItem): Boolean; inline;
  protected
    function CalculateItemHeight: Integer;
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
    procedure DoDrawCheckMark(ACanvas: TCanvas; const R: TRect; AChecked, AIsRadioItem, ASelected: Boolean); virtual;
    procedure DoDrawGlyph(ACanvas: TCanvas; const R: TRect; AGlyph: TACLGlyph; AEnabled, ASelected: Boolean); virtual;
    procedure DoDrawImage(ACanvas: TCanvas; const R: TRect; AImages: TCustomImageList; AImageIndex: TImageIndex; AEnabled, ASelected: Boolean); virtual;
    procedure DoDrawText(ACanvas: TCanvas; const R: TRect; const S: UnicodeString); virtual;
    procedure DoSplitRect(const R: TRect; AGutterWidth: Integer; out AGutterRect, AContentRect: TRect);
    procedure InitializeResources; override;
  public
    procedure AfterConstruction; override;
    procedure AssignFontParams(ACanvas: TCanvas; ASelected, AIsDefault, AEnabled: Boolean); virtual;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect; ASelected: Boolean); virtual;
    procedure DrawBorder(ACanvas: TCanvas; const R: TRect); virtual;
    procedure DrawItem(ACanvas: TCanvas; R: TRect; const S: UnicodeString;
      AShortCut: TShortCut; ASelected, AIsDefault, AEnabled, AHasSubItems: Boolean); virtual;
    procedure DrawItemImage(ACanvas: TCanvas; const R: TRect; AItem: TMenuItem; ASelected: Boolean); virtual;
    procedure DrawScrollButton(ACanvas: TCanvas; const R: TRect; AUp, AEnabled: Boolean); virtual;
    procedure DrawSeparator(ACanvas: TCanvas; const R: TRect); virtual;
    function MeasureWidth(ACanvas: TCanvas; const S: UnicodeString; AShortCut: TShortCut; ADefault: Boolean): Integer;
    //
    property BackgroundColors[ASelected: Boolean]: TColor read GetBackgroundColor;
    property ItemGutterWidth: Integer read GetItemGutterWidth;
    property ItemHeight: Integer read GetItemHeight;
    property SeparatorHeight: Integer read GetSeparatorHeight;
  published
    property Borders: TACLResourceMargins index 0 read GetMargins write SetMargins stored IsMarginsStored;
    property ColorBorder1: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorBorder2: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorItem: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorItemSelected: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
    property CornerRadius: TACLResourceInteger index 0 read GetInteger write SetInteger stored IsIntegerStored;
    property Font: TACLResourceFont index 0 read GetFont write SetFont stored IsFontStored;
    property FontDisabled: TACLResourceFont index 1 read GetFont write SetFont stored IsFontStored;
    property FontSelected: TACLResourceFont index 2 read GetFont write SetFont stored IsFontStored;
    property Texture: TACLResourceTexture index 0 read GetTexture write SetTexture stored IsTextureStored;
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

  TACLPopupMenuStyle = class(TACLStyleMenu)
  strict private
    FAllowTextFormatting: Boolean;
  protected
    procedure DoAssign(Source: TPersistent); override;
    procedure DoDrawText(ACanvas: TCanvas; const R: TRect; const S: string); override;
    procedure DoReset; override;
  published
    property AllowTextFormatting: Boolean read FAllowTextFormatting write FAllowTextFormatting default False;
  end;

  { TACLPopupMenu }

  TACLPopupMenuClass = class of TACLPopupMenu;
  TACLPopupMenu = class(TPopupMenu,
    IACLMenuShowHandler,
    IACLObjectLinksSupport,
    IACLPopup,
    IACLScaleFactor)
  strict private
    FAutoScale: Boolean;
    FHint: UnicodeString;
    FOptions: TACLPopupMenuOptions;
    FPopupWindow: TObject;
    FScaleFactor: TACLScaleFactor;
    FStyle: TACLPopupMenuStyle;

    function GetIsShown: Boolean;
    function GetScaleFactor: TACLScaleFactor;
    procedure ScaleFactorChanged(Sender: TObject);
    procedure SetOptions(AValue: TACLPopupMenuOptions);
    procedure SetStyle(AValue: TACLPopupMenuStyle);
    // IACLMenuShowHandler
    procedure IACLMenuShowHandler.OnShow = DoInitialize;
  protected
    function CreateOptions: TACLPopupMenuOptions; virtual;
    function CreateStyle: TACLPopupMenuStyle; virtual;
    procedure DoInitialize; virtual;
    procedure DoScaleFactorChanged; virtual;
    procedure DoSelect(Item: TMenuItem); virtual;
    procedure DoShow(const ControlRect: TRect); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    function CreateMenuItem: TMenuItem; override;
    procedure Popup(X, Y: Integer); overload; override;
    procedure Popup(const P: TPoint); reintroduce; overload;
    // IACLPopup
    procedure PopupUnderControl(const ControlRect: TRect);
    //
    property IsShown: Boolean read GetIsShown;
    property ScaleFactor: TACLScaleFactor read GetScaleFactor;
  published
    property AutoScale: Boolean read FAutoScale write FAutoScale default True;
    property Hint: UnicodeString read FHint write FHint;
    property Options: TACLPopupMenuOptions read FOptions write SetOptions;
    property Style: TACLPopupMenuStyle read FStyle write SetStyle;
  end;

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

    property DefaultItem: TMenuItem read GetDefaultItem;
    property Menu: TMenu read GetMenu;
  end;

function acMenusHasActivePopup: Boolean;
implementation

const
  CM_ENTERMENULOOP = CM_BASE + $0410;
  CM_ITEMCLICKED   = CM_BASE + $0403;
  CM_ITEMKEYED     = CM_BASE + $0404;
  CM_ITEMSELECTED  = CM_BASE + $0402;

type
  TACLMenuPopupWindow = class;

  TApplicationAccess = class(TApplication);
  TControlActionLinkAccess = class(TControlActionLink);

{$REGION 'Internal Classes'}

  { TACLMenuItemControl }

  TACLMenuItemControl = class(TGraphicControl)
  strict private
    FMouseSelected: Boolean;
    FSelected: Boolean;

    function GetIndex: Integer;
    function GetMenu: TACLMenuPopupWindow;
    function GetSeparator: Boolean;
    function GetStyle: TACLStyleMenu;
    procedure SetMenuItem(AValue: TMenuItem);
    //
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMItemSelected(var Message: TMessage); message CM_ITEMSELECTED;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
  protected
    FMenuItem: TMenuItem;
    FSubMenu: TACLMenuPopupWindow;

    procedure CheckAction(Action: TBasicAction);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure UpdateSelection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
    function HasSubItems: Boolean;
    procedure Keyed; virtual;
    function MeasureHeight(ACanvas: TCanvas): Integer;
    function MeasureWidth(ACanvas: TCanvas): Integer;
    procedure SetSelected(ASelected: Boolean; AIsMouseAction: Boolean = False);
    //
    property Caption;
    property Index: Integer read GetIndex;
    property Menu: TACLMenuPopupWindow read GetMenu;
    property MenuItem: TMenuItem read FMenuItem write SetMenuItem;
    property MouseSelected: Boolean read FMouseSelected;
    property Selected: Boolean read FSelected;
    property Separator: Boolean read GetSeparator;
    property Style: TACLStyleMenu read GetStyle;
    property SubMenu: TACLMenuPopupWindow read FSubMenu;
    //
    property OnClick;
  end;

  { TACLMenuStack }

  TACLMenuStack = class(TStack)
  strict private
    FMenu: TACLMenuPopupWindow;
  public
    constructor Create(AMenu: TACLMenuPopupWindow);
    function Peek: TACLMenuPopupWindow;
    procedure Pop;
    procedure Push(Container: TACLMenuPopupWindow);
    //
    property List;
  end;

  { TACLMenuItemControlList }

  TACLMenuItemControlList = class(TACLObjectList<TACLMenuItemControl>)
  public
    function FindDefaultItemIndex: Integer;
    procedure UpdateActionLinks;
  end;

  { TACLMenuPopupWindow }

  TACLMenuPopupEvent = procedure (Sender: TObject; Item: TACLMenuItemControl) of object;

  TACLMenuPopupWindow = class(TCustomControl)
  strict private
    FActionIdleTimer: TACLTimer;
    FAnimatePopups: Boolean;
    FDelayItem: TACLMenuItemControl;
    FItemKeyed: Boolean;
    FParentControl: TACLMenuItemControl;
    FParentMenu: TACLMenuPopupWindow;
    FRootMenu: TACLMenuPopupWindow;
    FVisibleIndex: Integer;

    FOnPopup: TACLMenuPopupEvent;

    procedure CheckAutoScrollTimer(const P: TPoint);
    procedure DoActionIdle;
    procedure DoActionIdleTimerProc(Sender: TObject);
    procedure DoMenuDelay(Sender: TObject);
    procedure DoScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure DoScrollTimer(Sender: TObject);

    function GetBorderWidths: TRect;
    function GetScaleFactor: TACLScaleFactor;
    function GetStyle: TACLStyleMenu;

    procedure SetParentMenu(const Value: TACLMenuPopupWindow);
    procedure SetVisibleIndex(AValue: Integer);

    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMEnterMenuLoop(var Message: TMessage); message CM_ENTERMENULOOP;
    procedure CMItemClicked(var Message: TMessage); message CM_ITEMCLICKED;
    procedure CMItemKeyed(var Message: TMessage); message CM_ITEMKEYED;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMKeyDown(var Message:  TWMKeyDown); message WM_KEYDOWN;
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCPaint(var Message: TWMNCPaint); message WM_NCPAINT;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMPrint(var Message: TWMPrint); message WM_PRINT;
    procedure WMPrintClient(var Message: TWMPrintClient); message WM_PRINTCLIENT;
    procedure WMSysKeyDown(var Message: TWMSysKeyDown); message WM_SYSKEYDOWN;
  protected
    FChildMenu: TACLMenuPopupWindow;
    FControlRect: TRect;
    FInMenuLoop: Boolean;
    FItemNumberInDisplayArea: Integer;
    FItems: TACLMenuItemControlList;
    FMousePos: TPoint;
    FPopupMenu: TACLPopupMenu;
    FPopupStack: TACLMenuStack;
    FPopupTimer: TACLTimer;
    FScrollBar: TACLScrollBar;
    FScrollButtonDown: TRect;
    FScrollButtonRestArea: TRect;
    FScrollButtonUp: TRect;
    FScrollTimer: TACLTimer;
    FSelectedItem: TMenuItem;

    //# Parent
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Resize; override;
    procedure WndProc(var Message: TMessage); override;
    procedure VisibleChanging; override;

    //# Navigation
    procedure EnsureNextItemVisible(var AItem: TACLMenuItemControl);
    function FindAccelItem(const Accel: Word): TACLMenuItemControl;
    function FindFirst: TACLMenuItemControl;
    function FindFirstVisibleItem: TACLMenuItemControl;
    function FindLast: TACLMenuItemControl;
    function FindLastVisibleItem: TACLMenuItemControl;
    function FindNext(AClient: TACLMenuItemControl; const Wrap: Boolean = True): TACLMenuItemControl;
    function FindNextVisibleItem(AClient: TACLMenuItemControl): TACLMenuItemControl;
    function FindPrevious(AClient: TACLMenuItemControl; const Wrap: Boolean = True): TACLMenuItemControl;
    function FindPreviousVisibleItem(AClient: TACLMenuItemControl): TACLMenuItemControl;
    function FindSelected(out AItem: TACLMenuItemControl): Boolean;

    //# Drawing
    procedure DrawScrollButton(ACanvas: TCanvas; const R: TRect; ATop, AEnabled: Boolean); virtual;
    procedure DrawScrollButtons(ACanvas: TCanvas); virtual;
    procedure NCPaint(DC: HDC);
    procedure Paint; override;

    //# Creation
    function CreatePopup(AOwner: TACLMenuPopupWindow; AItem: TACLMenuItemControl): TACLMenuPopupWindow; virtual;
    function CreateScrollBar: TACLScrollBar;

    //# Calculation
    procedure CalculateBounds(AOwner: TACLMenuPopupWindow; AParentItem: TACLMenuItemControl);
    procedure CalculateLayout;
    procedure CalculateScrollBar(var R: TRect);
    function CalculateMaxHeight: Integer;
    function CalculateMaxWidth: Integer;
    function CalculatePopupPosition(const AWorkArea: TRect; const ASize: TSize; AParentItem: TACLMenuItemControl): TPoint;
    procedure UpdateRegion;

    //# Menu Message Loop
    procedure DoneMenuLoop;
    procedure InitMenuLoop;
    procedure Idle(const Msg: TMsg);
    procedure ProcessMenuLoop; virtual;
    function ProcessMessage(var Msg: TMsg): Boolean;
    procedure ProcessMessages;

    //# Tracking
    procedure Animate(Show: Boolean = True);
    procedure ClearSubMenus;
    procedure CloseMenu;
    procedure TrackMenu;

    //# Mouse
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure ProcessMouseMessage(var Msg: TMsg); virtual;
    procedure ProcessMouseWheel(var Msg: TMsg); virtual;

    //# Actions
    function CanCloseMenuOnItemClick(AItem: TMenuItem): Boolean; virtual;
    function DoItemClicked(AItem: TACLMenuItemControl): TMenuItem; virtual;
    function DoItemKeyed(AItem: TACLMenuItemControl): TMenuItem; virtual;
    procedure DoItemSelected(AItem: TACLMenuItemControl);
    procedure DoPopup(Item: TACLMenuItemControl); virtual;
    procedure DoSelect(Item: TMenuItem); virtual;

    //# Populate
    procedure AddMenuItem(AMenuItem: TMenuItem);
    procedure Clear; virtual;
    procedure PopulateItems(AParentItem: TMenuItem);

    procedure Select(const Forward: Boolean);
    procedure SelectItem(AItem: TACLMenuItemControl);

    property BorderWidths: TRect read GetBorderWidths;
    property DelayItem: TACLMenuItemControl read FDelayItem write FDelayItem;
    property InMenuLoop: Boolean read FInMenuLoop write FInMenuLoop;
    property ParentControl: TACLMenuItemControl read FParentControl write FParentControl;
    property ParentMenu: TACLMenuPopupWindow read FParentMenu write SetParentMenu;
    property PopupMenu: TACLPopupMenu read FPopupMenu;
    property PopupStack: TACLMenuStack read FPopupStack;
    property RootMenu: TACLMenuPopupWindow read FRootMenu write FRootMenu;
    property ScaleFactor: TACLScaleFactor read GetScaleFactor;
    property ScrollBar: TACLScrollBar read FScrollBar;
    property ScrollButtonDown: TRect read FScrollButtonDown;
    property ScrollButtonUp: TRect read FScrollButtonUp;
    property ScrollTimer: TACLTimer read FScrollTimer;
    property Style: TACLStyleMenu read GetStyle;
    property VisibleIndex: Integer read FVisibleIndex write SetVisibleIndex;
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TACLMenuPopupWindow); reintroduce; overload;
    destructor Destroy; override;
    procedure Popup(X, Y: Integer);
    procedure PopupEx(AMenuItem: TMenuItem; const AControlRect: TRect);
    //
    property Caption;
    property Color;
    property Font;
    //
    property OnPopup: TACLMenuPopupEvent read FOnPopup write FOnPopup;
  end;

  { TACLMenuPopupRootWindow }

  TACLMenuPopupRootWindow = class(TACLMenuPopupWindow)
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  end;

{$ENDREGION}

  { TACLMenuController }

  TACLMenuController = class
  private
    class var FActiveMenu: TACLMenuPopupWindow;
    class var FHook: HHOOK;
    class var FMenus: TList;

    class function CallWindowHook(Code: Integer; wparam: WPARAM; Msg: PCWPStruct): Longint; stdcall; static;
  public
    class procedure Register(ABar: TACLMenuPopupWindow);
    class procedure Unregister(ABar: TACLMenuPopupWindow);
    //
    class property ActiveMenu: TACLMenuPopupWindow read FActiveMenu write FActiveMenu;
  end;

function acMenusHasActivePopup: Boolean;
begin
  Result := TACLMenuController.FMenus <> nil;
end;

function CanDisplayShadow: Boolean;
var
  ADisplayShadow: LongBool;
begin
  Result := CheckWin32Version(5, 1) and SystemParametersInfo(SPI_GETDROPSHADOW, 0, @ADisplayShadow, 0) and ADisplayShadow;
end;

function HasSubItems(AMenuItem: TMenuItem): Boolean;
var
  AIntf: IACLMenuItemLink;
begin
  Result := (AMenuItem.Count > 0) or Supports(AMenuItem, IACLMenuItemLink, AIntf) and (AIntf.GetExpandMode = lemExpandInSubMenu);
end;

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
  FScaleFactor := TACLScaleFactor.Create(Self, ScaleFactorChanged);
  FStyle := CreateStyle;
end;

destructor TACLPopupMenu.Destroy;
begin
  FreeAndNil(FScaleFactor);
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
var
  AIntf: IACLScaleFactor;
  I: Integer;
begin
  DoPopup(Self);
  if AutoScale then
  begin
    if TACLControlsHelper.GetScaleFactor(PopupComponent, AIntf) or TACLControlsHelper.GetScaleFactor(Owner, AIntf) then
      FScaleFactor.Assign(AIntf.GetScaleFactor)
    else
      FScaleFactor.Assign(acGetTargetDPI(PopupPoint), acDefaultDPI);
  end;
  for I := 0 to Items.Count - 1 do
    Items[I].InitiateAction;
end;

procedure TACLPopupMenu.DoScaleFactorChanged;
begin
  Style.SetTargetDPI(ScaleFactor.TargetDPI);
end;

procedure TACLPopupMenu.DoSelect(Item: TMenuItem);
begin
  PostMessage(PopupList.Window, WM_COMMAND, Item.Command, 0);
end;

procedure TACLPopupMenu.DoShow(const ControlRect: TRect);
begin
  if not IsShown then
  begin
    FPopupWindow := TACLMenuPopupRootWindow.Create(Self);
    try
      TACLMenuPopupRootWindow(FPopupWindow).PopupEx(Items, ControlRect);
    finally
      FreeAndNil(FPopupWindow);
  //Lose Focus: MyRefreshStayOnTop;
    end;
  end;
end;

function TACLPopupMenu.GetIsShown: Boolean;
begin
  Result := Assigned(FPopupWindow);
end;

function TACLPopupMenu.GetScaleFactor: TACLScaleFactor;
begin
  Result := FScaleFactor;
end;

procedure TACLPopupMenu.SetOptions(AValue: TACLPopupMenuOptions);
begin
  FOptions.Assign(AValue);
end;

procedure TACLPopupMenu.SetStyle(AValue: TACLPopupMenuStyle);
begin
  FStyle.Assign(AValue);
end;

procedure TACLPopupMenu.ScaleFactorChanged(Sender: TObject);
begin
  DoScaleFactorChanged;
end;

{ TACLPopupMenuStyle }

procedure TACLPopupMenuStyle.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);
  if Source is TACLPopupMenuStyle then
    AllowTextFormatting := TACLPopupMenuStyle(Source).AllowTextFormatting;
end;

procedure TACLPopupMenuStyle.DoDrawText(ACanvas: TCanvas; const R: TRect; const S: string);
begin
  if AllowTextFormatting then
    acDrawFormattedText(ACanvas, S, R, taLeftJustify, taVerticalCenter, False)
  else
    inherited DoDrawText(ACanvas, R, S);
end;

procedure TACLPopupMenuStyle.DoReset;
begin
  inherited DoReset;
  AllowTextFormatting := False;
end;

{ TACLMenuStack }

constructor TACLMenuStack.Create(AMenu: TACLMenuPopupWindow);
begin
  inherited Create;
  FMenu := AMenu;
end;

function TACLMenuStack.Peek: TACLMenuPopupWindow;
begin
  Result := TACLMenuPopupWindow(inherited PeekItem);
end;

procedure TACLMenuStack.Pop;
begin
  TObject(PopItem).Free;
end;

procedure TACLMenuStack.Push(Container: TACLMenuPopupWindow);
begin
  PushItem(Container);
end;

{ TACLMenuItemControlList }

function TACLMenuItemControlList.FindDefaultItemIndex: Integer;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if Items[I].MenuItem.Default then
      Exit(I);
  end;
  Result := -1;
end;

procedure TACLMenuItemControlList.UpdateActionLinks;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].InitiateAction;
end;

{ TACLMenuPopupWindow }

constructor TACLMenuPopupWindow.Create(AOwner: TComponent);
begin
  inherited Create(nil);
  ControlStyle := ControlStyle + [csClickEvents, csDoubleClicks, csSetCaption, csOpaque, csNoDesignVisible];
  Align := alNone;
  Height := 50;
  Width := 150;
  BorderWidth := 0;
  DoubleBuffered := True;
  FAnimatePopups := True;
  Font := Screen.MenuFont;
  TACLMenuController.Register(Self);
  FScrollTimer := TACLTimer.CreateEx(DoScrollTimer, 125);
  FActionIdleTimer := TACLTimer.CreateEx(DoActionIdleTimerProc);
  FItems := TACLMenuItemControlList.Create;
  Visible := False;
end;

constructor TACLMenuPopupWindow.Create(AOwner: TACLMenuPopupWindow);
begin
  Create(TComponent(AOwner));
  FPopupMenu := AOwner.FPopupMenu;
  RootMenu := AOwner.RootMenu;
  ParentMenu := AOwner;
  ParentWindow := AOwner.Handle;
  Font := AOwner.Font;
end;

destructor TACLMenuPopupWindow.Destroy;
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
  FreeAndNil(FScrollTimer);
  FreeAndNil(FScrollBar);
  FreeAndNil(FItems);
  inherited Destroy;
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

procedure TACLMenuPopupWindow.CreateParams(var Params: TCreateParams);
begin
  inherited;
  if not (Parent is TCustomForm) then
    Params.Style := Params.Style and not WS_CHILD or WS_POPUP or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or WS_OVERLAPPED;
  Params.WindowClass.Style := CS_SAVEBITS or CS_DBLCLKS or not (CS_HREDRAW or not CS_VREDRAW);
  if CanDisplayShadow then
    Params.WindowClass.Style := Params.WindowClass.Style or CS_DROPSHADOW;
  Params.ExStyle := Params.ExStyle or WS_EX_TOPMOST;
end;

procedure TACLMenuPopupWindow.CreateWnd;
begin
  inherited;
  FormSetCorners(Handle, afcRectangular);
end;

procedure TACLMenuPopupWindow.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if Operation = opRemove then
  begin
    if AComponent = FSelectedItem then
      FSelectedItem := nil;
  end;
end;

procedure TACLMenuPopupWindow.Resize;
begin
  inherited Resize;
  CalculateLayout;
  UpdateRegion;
end;

procedure TACLMenuPopupWindow.VisibleChanging;

  procedure UpdateSeparatorsVisibility;
  var
    AItem: TACLMenuItemControl;
  begin
    AItem := FindFirstVisibleItem;
    if (AItem <> nil) and AItem.Separator then
      AItem.Visible := False;

    AItem := FindLastVisibleItem;
    if (AItem <> nil) and AItem.Separator then
      AItem.Visible := False;
  end;

begin
  inherited VisibleChanging;

  if not Visible then
  begin
    UpdateSeparatorsVisibility;
    FItems.UpdateActionLinks;

    DisableAlign;
    try
      CalculateBounds(ParentMenu, ParentControl);
      VisibleIndex := FItems.FindDefaultItemIndex;
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

  if (RootMenu = Self) and HandleAllocated then
  begin
    if Visible then // its currect state, not target
      NotifyWinEvent(EVENT_SYSTEM_MENUPOPUPEND, Handle, OBJID_MENU, CHILDID_SELF)
    else
      NotifyWinEvent(EVENT_SYSTEM_MENUPOPUPSTART, Handle, OBJID_MENU, CHILDID_SELF);
  end;
end;

procedure TACLMenuPopupWindow.WndProc(var Message: TMessage);
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

procedure TACLMenuPopupWindow.EnsureNextItemVisible(var AItem: TACLMenuItemControl);
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

function TACLMenuPopupWindow.FindAccelItem(const Accel: Word): TACLMenuItemControl;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
  begin
    Result := FItems[I];
    if Result.Parent.Showing and Result.Visible and IsAccel(Accel, Result.Caption) then
      Exit;
  end;
  Result := nil;
end;

function TACLMenuPopupWindow.FindFirst: TACLMenuItemControl;
begin
  if FItems.Count > 0 then
    Result := FItems[0]
  else
    Result := nil;
end;

function TACLMenuPopupWindow.FindFirstVisibleItem: TACLMenuItemControl;
begin
  Result := FindFirst;
  while Assigned(Result) and not Result.Visible do
    Result := FindNext(Result, False);
end;

function TACLMenuPopupWindow.FindLast: TACLMenuItemControl;
begin
  if FItems.Count > 0 then
    Result := FItems.Last
  else
    Result := nil;
end;

function TACLMenuPopupWindow.FindLastVisibleItem: TACLMenuItemControl;
begin
  Result := FindLast;
  while Assigned(Result) and not Result.Visible do
    Result := FindPrevious(Result, False);
end;

function TACLMenuPopupWindow.FindNext(AClient: TACLMenuItemControl; const Wrap: Boolean = True): TACLMenuItemControl;
begin
  Result := nil;
  if Assigned(AClient) then
  begin
    if AClient.Index < FItems.Count - 1 then
      Result := FItems[AClient.Index + 1]
    else
      if Wrap and (FItems.Count > 1) then
        Result := FItems[0];
  end
  else
    if Wrap then
      Result := FindFirst;
end;

function TACLMenuPopupWindow.FindNextVisibleitem(AClient: TACLMenuItemControl): TACLMenuItemControl;
begin
  Result := FindNext(AClient, False);
  while Assigned(Result) and not Result.Visible do
    Result := FindNext(Result, False);
end;

function TACLMenuPopupWindow.FindPrevious(AClient: TACLMenuItemControl; const Wrap: Boolean = True): TACLMenuItemControl;
begin
  Result := nil;
  if Assigned(AClient) then
  begin
    if AClient.Index > 0 then
      Result := FItems[AClient.Index - 1]
    else
      if Wrap and (FItems.Count > 1) then
        Result := FItems.Last;
  end
  else
    if Wrap then
      Result := FindLast;
end;

function TACLMenuPopupWindow.FindPreviousVisibleItem(AClient: TACLMenuItemControl): TACLMenuItemControl;
begin
  Result := FindPrevious(AClient, False);
  while Assigned(Result) and not Result.Visible do
    Result := FindPrevious(Result, False);
end;

function TACLMenuPopupWindow.FindSelected(out AItem: TACLMenuItemControl): Boolean;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
  begin
    AItem := FItems[I];
    if (AItem <> nil) and AItem.Selected then
      Exit(True);
  end;
  Result := False;
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
  if not acRectIsEmpty(FScrollButtonRestArea) then
    Style.DrawBackground(ACanvas, FScrollButtonRestArea, False);
  if not acRectIsEmpty(FScrollButtonDown) then
    DrawScrollButton(ACanvas, FScrollButtonDown, True, VisibleIndex > 0);
  if not acRectIsEmpty(FScrollButtonUp) then
    DrawScrollButton(ACanvas, FScrollButtonUp, False, VisibleIndex + FItemNumberInDisplayArea < FItems.Count);
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
    acExcludeFromClipRegion(DC, acRectContent(ARect, BorderWidths));

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

procedure TACLMenuPopupWindow.Paint;
begin
  inherited Paint;
  DrawScrollButtons(Canvas);
end;

function TACLMenuPopupWindow.CreatePopup(AOwner: TACLMenuPopupWindow; AItem: TACLMenuItemControl): TACLMenuPopupWindow;
begin
  DelayItem := nil;
  if not InMenuLoop or (AOwner = nil) or (AItem = nil) then
    Exit(nil);
  if (FPopupStack.Count = 0) or (FPopupStack.Peek.ParentControl = AItem) then
    Exit(nil);
  if not AItem.HasSubItems then
    Exit(nil);

  AItem.MenuItem.Click;

  Result := TACLMenuPopupWindow.Create(Self);
  Result.DisableAlign;
  Result.FInMenuLoop := True;
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
    Result.Style.TargetDPI := ScaleFactor.TargetDPI;
  finally
    Result.Style.EndUpdate;
  end;
end;

procedure TACLMenuPopupWindow.CalculateBounds(AOwner: TACLMenuPopupWindow; AParentItem: TACLMenuItemControl);

  function GetPopupPoint: TPoint;
  begin
    if AParentItem <> nil then
      Result := AParentItem.ClientOrigin
    else
      Result := BoundsRect.TopLeft;
  end;

var
  APosition: TPoint;
  AWindowSize: TSize;
  AWorkArea: TRect;
  AHasScrollBar: Boolean;
begin
  repeat
    AHasScrollBar := ScrollBar <> nil;
    AWindowSize.cx := CalculateMaxWidth;
    AWindowSize.cy := CalculateMaxHeight;
    AWorkArea := MonitorGetBounds(GetPopupPoint);
    APosition := CalculatePopupPosition(AWorkArea, AWindowSize, AParentItem);
    APosition.X := Max(APosition.X, AWorkArea.Left);
    APosition.Y := Max(APosition.Y, AWorkArea.Top);
    AWindowSize.cy := Min(AWindowSize.cy, AWorkArea.Bottom - APosition.Y);
    BoundsRect := Bounds(APosition.X, APosition.Y, AWindowSize.cx, AWindowSize.cy);
    CalculateLayout;
  until AHasScrollBar = (ScrollBar <> nil);
end;

procedure TACLMenuPopupWindow.CalculateLayout;
var
  AAlignRect: TRect;
  AControl: TACLMenuItemControl;
  AControlHeight: Integer;
  I: Integer;
begin
  AAlignRect := ClientRect;
  CalculateScrollBar(AAlignRect);

  for I := 0 to FItems.Count - 1 do
    FItems[I].SetBounds(0, 0, 0, 0); // hide all controls

  FItemNumberInDisplayArea := 0;
  for I := VisibleIndex to FItems.Count - 1 do
  begin
    AControl := FItems[I];
    if AControl.Visible then
    begin
      AControlHeight := AControl.MeasureHeight(Canvas);
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

  if acRectIsEmpty(AAlignRect) then
    FScrollButtonRestArea := NullRect
  else
    FScrollButtonRestArea := acRectSetHeight(AAlignRect, Style.ItemHeight);
end;

procedure TACLMenuPopupWindow.CalculateScrollBar(var R: TRect);
var
  AUseScrollButtons: Boolean;
begin
  if CalculateMaxHeight > Height then
  begin
    AUseScrollButtons :=
      (PopupMenu.Options.ScrollMode = smScrollButtons) or
      (PopupMenu.Options.ScrollMode = smAuto) and PopupMenu.Style.TextureScrollBar.Empty;

    if AUseScrollButtons then
    begin
      FreeAndNil(FScrollBar);
      FScrollButtonDown := acRectSetHeight(R, Style.ItemHeight);
      FScrollButtonUp := acRectSetTop(R, Style.ItemHeight);
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
      ScrollBar.BoundsRect := acRectSetRight(R, R.Right, FScrollBar.Width);
      ScrollBar.SetScrollParams(0, FItems.Count - 1, VisibleIndex, FItemNumberInDisplayArea);
      Dec(R.Right, ScrollBar.Width);
    end;
  end
  else
    FreeAndNil(FScrollBar);
end;

function TACLMenuPopupWindow.CalculateMaxWidth: Integer;
var
  AItem: TACLMenuItemControl;
  I: Integer;
begin
  Result := 0;
  for I := 0 to FItems.Count - 1 do
  begin
    AItem := FItems[I];
    if AItem.Visible then
      Result := Max(Result, AItem.MeasureWidth(MeasureCanvas));
  end;
  if ScrollBar <> nil then
    Inc(Result, ScrollBar.Width);
  Inc(Result, acMarginWidth(BorderWidths));
end;

function TACLMenuPopupWindow.CalculateMaxHeight: Integer;
var
  AItem: TACLMenuItemControl;
  I: Integer;
begin
  Result := 0;
  for I := 0 to FItems.Count - 1 do
  begin
    AItem := FItems[I];
    if AItem.Visible then
      Inc(Result, AItem.MeasureHeight(MeasureCanvas));
  end;
  Inc(Result, acMarginHeight(BorderWidths));
end;

function TACLMenuPopupWindow.CalculatePopupPosition(const AWorkArea: TRect; const ASize: TSize; AParentItem: TACLMenuItemControl): TPoint;
var
  AParentRect: TRect;
begin
  Result := BoundsRect.TopLeft;
  if Result.Y + ASize.cy > AWorkArea.Bottom then
    Result.Y := FControlRect.Top - ASize.cy - 4;
  if AParentItem <> nil then
  begin
    AParentRect := acRectOffset(AParentItem.BoundsRect, AParentItem.Parent.ClientOrigin);
    AParentRect := acRectOffset(AParentRect, 0, -BorderWidths.Top);
    Result := Point(AParentRect.Right, AParentRect.Top);
    if Result.X + ASize.cx > AWorkArea.Right then
      Result.X := AParentRect.Left - ASize.cx;
    if Result.Y + ASize.cy > AWorkArea.Bottom then
      Result.Y := AParentRect.Bottom - ASize.cy;
  end
  else
  begin
    if Result.X + ASize.cx > AWorkArea.Right then
      Result.X := AWorkArea.Right - ASize.cx;
    if Result.Y + ASize.cy > AWorkArea.Bottom then
      Result.Y := AWorkArea.Bottom - ASize.cy;
  end;
end;

procedure TACLMenuPopupWindow.UpdateRegion;
var
  ARadius: Integer;
begin
  ARadius := Style.CornerRadius.Value;
  if ARadius > 0 then
    SetWindowRgn(Handle, CreateRoundRectRgn(0, 0, Width + 1, Height + 1, 2 * ARadius - 1, 2 * ARadius - 1), True)
  else
    SetWindowRgn(Handle, 0, True);
end;

procedure TACLMenuPopupWindow.DoneMenuLoop;
begin
  ClearSubMenus;
  TACLMenuController.ActiveMenu := nil;
  FAnimatePopups := True;
  ShowCaret(0);
  FreeAndNil(FPopupTimer);
  FreeAndNil(FPopupStack);
  NotifyWinEvent(EVENT_SYSTEM_MENUEND, Handle, OBJID_MENU, CHILDID_SELF);
end;

procedure TACLMenuPopupWindow.InitMenuLoop;
var
  DelayTime: Integer;
begin
  FMousePos := Mouse.CursorPos;
  // Need to use FSelectedItem because it's possible for the item to be
  // destroyed in designmode before TrackMenu gets an opportunity to execute
  // the associated action
  FSelectedItem := nil;
  DelayItem := nil;
  SystemParametersInfo(SPI_GETMENUSHOWDELAY, 0, @DelayTime, 0);
  if DelayTime = 0 then
    Inc(Delaytime);
  acSafeSetFocus(GetParentForm(Self));
  FPopupTimer := TACLTimer.CreateEx(DoMenuDelay, DelayTime);
  FPopupStack := TACLMenuStack.Create(Self);
  FPopupStack.Push(Self);
  FInMenuLoop := True;
  HideCaret(0);
  TACLMenuController.ActiveMenu := Self;
  NotifyWinEvent(EVENT_SYSTEM_MENUSTART, Handle, OBJID_MENU, CHILDID_SELF);
end;

procedure TACLMenuPopupWindow.Idle(const Msg: TMsg);
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

procedure TACLMenuPopupWindow.ProcessMenuLoop;
var
  Msg: TMsg;
  Temp: PMessage;
begin
  if FInMenuLoop then
    Exit;

  InitMenuLoop;
  try
    repeat
      if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
      begin
        // Prevent multiple right click menus from appearing in form designer
        if (Msg.message = WM_CONTEXTMENU) and (RootMenu is TACLMenuPopupWindow) then
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
              begin
                Temp := PMessage(@Msg.message);
                FPopupStack.Peek.Dispatch(Temp^);
              end;

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

function TACLMenuPopupWindow.ProcessMessage(var Msg: TMsg): Boolean;
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

procedure TACLMenuPopupWindow.ProcessMessages;
var
  Msg: TMsg;
begin
  while ProcessMessage(Msg) do;
end;

procedure TACLMenuPopupWindow.Animate(Show: Boolean = True);
const
  AnimateDuration = 150;
  UnfoldAnimationStyle: array[Boolean] of Integer = (
    AW_VER_POSITIVE or AW_HOR_POSITIVE or AW_SLIDE,
    AW_VER_NEGATIVE or AW_HOR_POSITIVE or AW_SLIDE);
  HideShow: array[Boolean] of Integer = (AW_HIDE, 0);
var
  AMenuAnimate: LongBool;
  AMenuPoint: TPoint;
begin
  if not RootMenu.FItemKeyed then
  begin
    SystemParametersInfo(SPI_GETMENUANIMATION, 0, @AMenuAnimate, 0);
    if Assigned(AnimateWindowProc) and (FParentMenu.FAnimatePopups or not Show) and AMenuAnimate then
    begin
      SystemParametersInfo(SPI_GETMENUFADE, 0, @AMenuAnimate, 0);
      if AMenuAnimate then
        AnimateWindowProc(Handle, AnimateDuration, AW_BLEND or HideShow[Show])
      else
      begin
        AMenuPoint := ParentControl.Parent.ClientToScreen(ParentControl.BoundsRect.TopLeft);
        AnimateWindowProc(Handle, AnimateDuration, UnfoldAnimationStyle[Top < AMenuPoint.Y - 5] or HideShow[Show]);
      end;
    end;
  end;
end;

procedure TACLMenuPopupWindow.ClearSubMenus;
begin
  if Assigned(FPopupStack) then
  begin
    while FPopupStack.Count > 1 do
      FPopupStack.Peek.CloseMenu;   // CloseMenu pops the top menu off the stack
  end;
end;

procedure TACLMenuPopupWindow.CloseMenu;
var
  ASelected: TACLMenuItemControl;
begin
  if FChildMenu <> nil then
    FChildMenu.CloseMenu;

  Visible := False;
  if RootMenu <> nil then
  begin
    RootMenu.FMousePos := Mouse.CursorPos;
    RootMenu.DelayItem := nil;
  end;

  if ParentMenu <> nil then
    ParentMenu.FAnimatePopups := False;

  InMenuLoop := False;

  if (RootMenu <> nil) and (RootMenu.PopupStack <> nil) then
  begin
    if RootMenu.PopupStack.Peek = RootMenu then
    begin
      InMenuLoop := False;
      if FindSelected(ASelected) then
        ASelected.SetSelected(False, False);
    end
    else
      RootMenu.PopupStack.Pop;
  end;
end;

procedure TACLMenuPopupWindow.TrackMenu;
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

procedure TACLMenuPopupWindow.MouseMove(Shift: TShiftState; X: Integer; Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  CheckAutoScrollTimer(Point(X, Y));
end;

procedure TACLMenuPopupWindow.ProcessMouseMessage(var Msg: TMsg);
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

procedure TACLMenuPopupWindow.ProcessMouseWheel(var Msg: TMsg);
var
  AMenu: TACLMenuPopupWindow;
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

function TACLMenuPopupWindow.CanCloseMenuOnItemClick(AItem: TMenuItem): Boolean;
begin
  if PopupMenu.Options.CloseMenuOnItemCheck then
    Result := True
  else
    Result := not AItem.AutoCheck;
end;

function TACLMenuPopupWindow.DoItemClicked(AItem: TACLMenuItemControl): TMenuItem;

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
    DelayItem := nil;
  if AItem.HasSubItems then
  begin
    if Assigned(DelayItem) then
    begin
      while FPopupStack.Peek <> DelayItem.Parent do
        RootMenu.PopupStack.Pop;
      DelayItem := nil;
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

function TACLMenuPopupWindow.DoItemKeyed(AItem: TACLMenuItemControl): TMenuItem;
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

procedure TACLMenuPopupWindow.DoItemSelected(AItem: TACLMenuItemControl);
begin
  if AItem is TACLMenuItemControl then
    RootMenu.DelayItem := AItem
  else
    DelayItem := nil;

  RootMenu.FPopupTimer.Enabled := True;
end;

procedure TACLMenuPopupWindow.DoPopup(Item: TACLMenuItemControl);
begin
  if Assigned(FOnPopup) then
    FOnPopup(Self, Item);
end;

procedure TACLMenuPopupWindow.DoSelect(Item: TMenuItem);
begin
  PopupMenu.DoSelect(Item);
end;

procedure TACLMenuPopupWindow.AddMenuItem(AMenuItem: TMenuItem);
var
  AControl: TACLMenuItemControl;
  ALink: IACLMenuItemLink;
begin
  if not AMenuItem.Visible then
    Exit;
  if AMenuItem.IsLine and ((FItems.Count = 0) or FItems.Last.Separator) then
    Exit;

  acGetInterface(AMenuItem, IACLMenuItemLink, ALink);
  if (ALink <> nil) and not ALink.HasSubItems then
    Exit;

  if (ALink <> nil) and (ALink.GetExpandMode = lemExpandInplace) then
  begin
    ALink.Enum(AddMenuItem);
    Exit;
  end;

  AControl := TACLMenuItemControl.Create(Self);
  AControl.MenuItem := AMenuItem;
  AControl.Parent := Self;
  FItems.Add(AControl);
end;

procedure TACLMenuPopupWindow.Clear;
begin
  DisableAlign;
  try
    FItems.Clear;
  finally
    EnableAlign;
  end;
end;

procedure TACLMenuPopupWindow.PopulateItems(AParentItem: TMenuItem);
var
  ALink: IACLMenuItemLink;
  I: Integer;
begin
  if AParentItem.Enabled then
  begin
    AParentItem.PrepareForShowing;
    if Supports(AParentItem, IACLMenuItemLink, ALink) and (ALink.GetExpandMode = lemExpandInSubMenu) then
      ALink.Enum(AddMenuItem)
    else
      for I := 0 to AParentItem.Count - 1 do
        AddMenuItem(AParentItem.Items[I]);

    if (FItems.Count > 0) and FItems.Last.Separator then
      FItems.Delete(FItems.Count - 1);
  end;
end;

procedure TACLMenuPopupWindow.CMEnabledchanged(var Message: TMessage);
begin
  inherited;
  Broadcast(Message);
end;

function TACLMenuPopupWindow.GetStyle: TACLStyleMenu;
begin
  if ParentMenu <> nil then
    Result := ParentMenu.Style
  else
    Result := PopupMenu.Style;
end;

function TACLMenuPopupWindow.GetScaleFactor: TACLScaleFactor;
begin
  if ParentMenu <> nil then
    Result := ParentMenu.ScaleFactor
  else
    Result := PopupMenu.ScaleFactor;
end;

procedure TACLMenuPopupWindow.WMPaint(var Message: TWMPaint);
begin
  if not (csCustomPaint in ControlState) then
  begin
    ControlState := ControlState + [csCustomPaint];
    inherited;
    ControlState := ControlState - [csCustomPaint];
  end;
end;

procedure TACLMenuPopupWindow.CMItemClicked(var Message: TMessage);
begin
  if FInMenuLoop then Exit;
  PostMessage(Handle, Message.Msg, 0, Message.LParam);
  TrackMenu;
end;

procedure TACLMenuPopupWindow.CMEnterMenuLoop(var Message: TMessage);
begin
  TrackMenu;
end;

procedure TACLMenuPopupWindow.CMItemKeyed(var Message: TMessage);
begin
  if FInMenuLoop then Exit;
  PostMessage(Handle, Message.Msg, 0, Message.LParam);
  TrackMenu;
end;

procedure TACLMenuPopupWindow.CMMouseLeave(var Message: TMessage);
var
  ASelected: TACLMenuItemControl;
begin
  inherited;
  if FindSelected(ASelected) and (ASelected.SubMenu = nil) then
    ASelected.SetSelected(False);
end;

procedure TACLMenuPopupWindow.DoMenuDelay(Sender: TObject);
var
  P: TPoint;
begin
  FPopupTimer.Enabled := False;
  if (DelayItem = nil) or (DelayItem.Parent = nil) or Assigned(DelayItem.SubMenu) then
    Exit;

  while (RootMenu.PopupStack.Count > 1) and (RootMenu.PopupStack.Peek <> DelayItem.Parent) do
    RootMenu.PopupStack.Pop;

  GetCursorPos(P);
  if PtInRect(DelayItem.BoundsRect, FPopupStack.Peek.ScreenToClient(P)) then
    CreatePopup(FPopupStack.Peek, DelayItem);
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

procedure TACLMenuPopupWindow.Select(const Forward: Boolean);

  function SkipItems(const Forward: Boolean; out ANextItem: TACLMenuItemControl): Boolean;
  var
    ALoop: Boolean;
  begin
    ALoop := True;
    if not FindSelected(ANextItem) then
      ANextItem := nil;
    while ALoop do
    begin
      if Forward then
        ANextItem := FindNext(ANextItem)
      else
        ANextItem := FindPrevious(ANextItem);

      if Assigned(ANextItem) then
      begin
        if not ANextItem.Separator and ANextItem.Visible then
          Break;
      end;
      ALoop := Assigned(ANextItem);
    end;
    Result := Assigned(ANextItem);
  end;

var
  NextItem: TACLMenuItemControl;
begin
  if SkipItems(Forward, NextItem) then
  begin
    if (RootMenu.PopupStack.Peek = Self) then
    begin
      EnsureNextItemVisible(NextItem);
      SelectItem(NextItem);
    end
    else
      if (NextItem.Parent = Self) and Assigned(NextItem.Action) then
      begin
        RootMenu.PopupStack.Peek.FInMenuLoop := False;
        RootMenu.DelayItem := nil;
        EnsureNextItemVisible(NextItem);
        SelectItem(NextItem);
      end
      else
        NextItem.Keyed;
  end;
end;

procedure TACLMenuPopupWindow.SelectItem(AItem: TACLMenuItemControl);
begin
  if AItem <> nil then
    AItem.SetSelected(True);
end;

procedure TACLMenuPopupWindow.SetParentMenu(const Value: TACLMenuPopupWindow);
begin
  if FParentMenu <> Value then
  begin
    FParentMenu := Value;
    if FParentMenu <> nil then
      FParentMenu.FChildMenu := Self;
  end;
end;

procedure TACLMenuPopupWindow.WMKeyDown(var Message: TWMKeyDown);
var
  ACharCode: Integer;
  AItem: TACLMenuItemControl;
begin
  case Message.CharCode of
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

  case Message.CharCode of
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

procedure TACLMenuPopupWindow.WMMouseActivate(var Message: TWMMouseActivate);
begin
  inherited;
  if FInMenuLoop then
    Message.Result := MA_NOACTIVATE;
end;

procedure TACLMenuPopupWindow.WMNCCalcSize(var Message: TWMNCCalcSize);
begin
  Message.CalcSize_Params^.rgrc0 := acRectContent(Message.CalcSize_Params^.rgrc0, BorderWidths);
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

procedure TACLMenuPopupWindow.WMPrintClient(var Message: TWMPrintClient);
begin
  inherited;
  PaintTo(Message.DC, 0, 0);
end;

procedure TACLMenuPopupWindow.WMSysKeyDown(var Message: TWMSysKeyDown);
var
  ANextItem: TACLMenuItemControl;
  ASelected: TACLMenuItemControl;
begin
  inherited;
  if not FInMenuLoop then
    Exit;

  WMKeyDown(Message);
  case Message.CharCode of
    VK_RIGHT:
      if FindSelected(ASelected) then
      begin
        if ASelected.HasSubItems and (ASelected.SubMenu = nil) and ASelected.Enabled then
          ASelected.Keyed
        else
        begin
          if not RootMenu.FindSelected(ASelected) then
            ASelected := nil;
          ANextItem := RootMenu.FindNextVisibleItem(ASelected);
          if ANextItem = nil then
            ANextItem := RootMenu.FindFirstVisibleItem;
          if ANextItem <> nil then
            ANextItem.Keyed;
        end;
      end;

    VK_LEFT:
      begin
        if not RootMenu.FindSelected(ASelected) then
          ASelected := nil;
        ANextItem := RootMenu.FindPreviousVisibleItem(ASelected);
        if ANextItem = nil then
          ANextItem := RootMenu.FindLastVisibleItem;
        if ANextItem <> nil then
          ANextItem.Keyed;
      end;

    VK_MENU:
      RootMenu.CloseMenu;
  end;
end;

procedure TACLMenuPopupWindow.DoActionIdle;
var
  AForm: TCustomForm;
  I: Integer;
begin
  for I := 0 to Screen.CustomFormCount - 1 do
  begin
    AForm := Screen.CustomForms[I];
    if AForm.HandleAllocated and IsWindowVisible(AForm.Handle) and IsWindowEnabled(AForm.Handle) then
      AForm.Perform(CM_UPDATEACTIONS, 0, 0);
  end;
end;

procedure TACLMenuPopupWindow.DoActionIdleTimerProc(Sender: TObject);
begin
  try
    FActionIdleTimer.Enabled := False;
    DoActionIdle;
  except
    Application.HandleException(Application);
  end;
end;

function TACLMenuPopupWindow.GetBorderWidths: TRect;
begin
  Result := ScaleFactor.Apply(Style.Borders.Value);
end;

procedure TACLMenuPopupWindow.SetVisibleIndex(AValue: Integer);
begin
  AValue := MinMax(AValue, 0, FItems.Count - FItemNumberInDisplayArea);
  if FVisibleIndex <> AValue then
  begin
    FVisibleIndex := AValue;
    CalculateLayout;
    Invalidate;
  end;
end;

{ TACLMenuPopupRootWindow }

constructor TACLMenuPopupRootWindow.Create(AOwner: TComponent);
begin
  inherited;
  FPopupMenu := AOwner as TACLPopupMenu;
end;

procedure TACLMenuPopupRootWindow.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var
  NewWidth: Integer;
begin
  if not AlignDisabled then
  begin
    if (Align in [alTop, alBottom]) or (Floating and (Align = alNone)) then
      AHeight := Height;
    if (Align in [alLeft, alRight]) or (Floating and (Align = alNone)) then
      NewWidth := Width
    else
      NewWidth := AWidth;
    if not Floating and (NewWidth <> Width) then
      AWidth := NewWidth;
  end;
  inherited;
end;

{ TACLMenuItemControl }

constructor TACLMenuItemControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csActionClient] - [csCaptureMouse];
  Height := 22;
  Width := 22;
  ParentShowHint := True;
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
    begin
      NotifyWinEvent(EVENT_OBJECT_FOCUS, Parent.Handle, OBJID_CLIENT, Index + 1);
      Menu.DoItemSelected(Self);
    end;

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

procedure TACLMenuItemControl.SetMenuItem(AValue: TMenuItem);
begin
  if FMenuItem <> AValue then
  begin
    FMenuItem := AValue;
    if MenuItem <> nil then
    begin
      Action := MenuItem.Action;
      Caption := MenuItem.Caption;
    end
    else
      Action := nil;
  end;
end;

procedure TACLMenuItemControl.Keyed;
begin
  SetSelected(True, False);
  CheckAction(Action);
  if Parent <> nil then
    PostMessage(Parent.Handle, CM_ITEMKEYED, 0, LPARAM(Self));
end;

function TACLMenuItemControl.MeasureHeight(ACanvas: TCanvas): Integer;
begin
  if Separator then
    Result := Style.SeparatorHeight
  else
    Result := Style.ItemHeight;
end;

function TACLMenuItemControl.MeasureWidth(ACanvas: TCanvas): Integer;
begin
  Result := Style.MeasureWidth(ACanvas, MenuItem.Caption, MenuItem.ShortCut, MenuItem.Default);
end;

procedure TACLMenuItemControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;

  if (SubMenu = nil) and MenuItem.Enabled then
  begin
    CheckAction(Action);
    if not Separator then
      PostMessage(Parent.Handle, CM_ITEMCLICKED, 0, LPARAM(Self));
  end;
end;

procedure TACLMenuItemControl.Paint;
var
  R: TRect;
begin
  R := ClientRect;
  if Separator then
    Style.DrawSeparator(Canvas, R)
  else
  begin
    Style.DrawBackground(Canvas, R, Selected);
    Style.DrawItem(Canvas, R, Caption, MenuItem.ShortCut, Selected, MenuItem.Default, MenuItem.Enabled, HasSubItems);
    Style.DrawItemImage(Canvas, acRectSetWidth(R, Style.ItemGutterWidth), MenuItem, Selected);
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

function TACLMenuItemControl.GetSeparator: Boolean;
begin
  Result := MenuItem.IsLine;
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

function TACLMenuItemControl.GetMenu: TACLMenuPopupWindow;
begin
  Result := Parent as TACLMenuPopupWindow;
end;

function TACLMenuItemControl.GetIndex: Integer;
begin
  Result := Menu.FItems.IndexOf(Self);
end;

function TACLMenuItemControl.GetStyle: TACLStyleMenu;
begin
  Result := Menu.Style;
end;

function TACLMenuItemControl.HasSubItems: Boolean;
begin
  Result := ACL.UI.PopupMenu.HasSubItems(MenuItem);
end;

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

procedure TACLMenuItem.DoShow;
begin
  CallNotifyEvent(Self, OnShow);
end;

function TACLMenuItem.GetScaleFactor: TACLScaleFactor;
begin
  Result := acGetScaleFactor(Menu);
end;

function TACLMenuItem.IsCheckItem: Boolean;
begin
  Result := Checked or AutoCheck or RadioItem;
end;

function TACLMenuItem.GetGlyph: TACLGlyph;
begin
  Result := FGlyph;
end;

procedure TACLMenuItem.SetGlyph(AValue: TACLGlyph);
begin
  FGlyph.Assign(AValue);
end;

{ TACLMenuItemLink }

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

procedure TACLMenuItemLink.Enum(AProc: TMenuItemEnumProc);
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

function TACLMenuItemLink.GetExpandMode: TACLMenuItemLinkExpandMode;
begin
  Result := FExpandMode;
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

procedure TACLStyleMenu.DrawBackground(ACanvas: TCanvas; const R: TRect; ASelected: Boolean);
var
  AContentRect: TRect;
  AGutterRect: TRect;
begin
  acFillRect(ACanvas.Handle, R, BackgroundColors[ASelected]);
  Texture.Draw(ACanvas.Handle, R, Ord(ASelected));
  DoSplitRect(R, ItemGutterWidth, AGutterRect, AContentRect);
  TextureGutter.Draw(ACanvas.Handle, AGutterRect, Ord(ASelected));
end;

procedure TACLStyleMenu.DrawBorder(ACanvas: TCanvas; const R: TRect);
var
  ACornerRadius: Integer;
begin
  if ColorBorder2.IsEmpty then
  begin
    ACanvas.Pen.Style := psClear;
    ACanvas.Brush.Color := ColorBorder1.AsColor;
  end
  else
  begin
    ACanvas.Pen.Color := ColorBorder1.AsColor;
    ACanvas.Brush.Color := ColorBorder2.AsColor;
  end;

  ACornerRadius := 2 * CornerRadius.Value;
  if ACornerRadius > 0 then
    ACanvas.RoundRect(R, ACornerRadius, ACornerRadius)
  else
    ACanvas.Rectangle(R);
end;

procedure TACLStyleMenu.DrawScrollButton(ACanvas: TCanvas; const R: TRect; AUp, AEnabled: Boolean);
const
  ScrollButtonMap: array[Boolean] of TACLArrowKind = (makBottom, makTop);
begin
  AssignFontParams(ACanvas, False, False, AEnabled);
  acDrawArrow(ACanvas.Handle, R, ACanvas.Font.Color, ScrollButtonMap[AUp], TargetDPI);
end;

procedure TACLStyleMenu.DrawSeparator(ACanvas: TCanvas; const R: TRect);
var
  ADstC, ADstG: TRect;
  ALayer: TACLBitmapLayer;
  ASrcC, ASrcG: TRect;
begin
  if TextureSeparator.ImageScaleFactor.Assigned then
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

function TACLStyleMenu.MeasureWidth(ACanvas: TCanvas; const S: UnicodeString; AShortCut: TShortCut; ADefault: Boolean): Integer;
begin
  AssignFontParams(ACanvas, True, ADefault, True);

  Result := 2 * GetTextIdent + ItemGutterWidth + ItemHeight;
  if AShortCut <> scNone then
  begin
    Inc(Result, acTextSize(ACanvas, '  ').cx);
    Inc(Result, acTextSize(ACanvas, ShortCutToText(AShortCut)).cx);
  end;
  Inc(Result, acTextSize(ACanvas, S).cx);
end;

procedure TACLStyleMenu.DrawItem(ACanvas: TCanvas; R: TRect; const S: UnicodeString;
  AShortCut: TShortCut; ASelected, AIsDefault, AEnabled, AHasSubItems: Boolean);
begin
  Inc(R.Left, ItemGutterWidth);
  R := acRectInflate(R, -GetTextIdent, 0);
  AssignFontParams(ACanvas, ASelected, AIsDefault, AEnabled);
  DoDrawText(ACanvas, R, S);
  if AHasSubItems then
    acDrawArrow(ACanvas.Handle, acRectSetLeft(R, acRectHeight(R)), ACanvas.Font.Color, makRight, TargetDPI)
  else
    if AShortCut <> scNone then
      acTextDraw(ACanvas, ShortCutToText(AShortCut), R, taRightJustify, taVerticalCenter);
end;

procedure TACLStyleMenu.DrawItemImage(ACanvas: TCanvas; const R: TRect; AItem: TMenuItem; ASelected: Boolean);
var
  AClipRegion: HRGN;
  AGlyph: TACLGlyph;
  AIntf: IACLGlyph;
begin
  if not RectVisible(ACanvas.Handle, R) then Exit;

  AClipRegion := acSaveClipRegion(ACanvas.Handle);
  try
    acIntersectClipRegion(ACanvas.Handle, R);
    if IsCheckItem(AItem) then
      DoDrawCheckMark(ACanvas, R, AItem.Checked, AItem.RadioItem, ASelected)
    else

    // DPI aware Glyph
    if Supports(AItem, IACLGlyph, AIntf) and not AIntf.GetGlyph.Empty then
      DoDrawGlyph(ACanvas, R, AIntf.GetGlyph, AItem.Enabled, ASelected)
    else

    // VCL Glyph
    if not AItem.Bitmap.Empty then
    begin
      AGlyph := TACLGlyph.Create(nil);
      try
        AGlyph.ImportFromImage(AItem.Bitmap, acDefaultDPI);
        DoDrawGlyph(ACanvas, R, AGlyph, AItem.Enabled, ASelected);
      finally
        AGlyph.Free;
      end;
    end
    else
      DoDrawImage(ACanvas, R, AItem.GetImageList, AItem.ImageIndex, AItem.Enabled, ASelected);
  finally
    acRestoreClipRegion(ACanvas.Handle, AClipRegion);
  end;
end;

function TACLStyleMenu.CalculateItemHeight: Integer;
begin
  Result := Texture.FrameHeight;
  if Result = 0 then
  begin
    AssignFontParams(MeasureCanvas, False, True, True);
    Result := Max(2 * GetTextIdent + acFontHeight(MeasureCanvas), TextureGutter.FrameHeight);
  end;
end;

procedure TACLStyleMenu.DoDrawCheckMark(ACanvas: TCanvas; const R: TRect; AChecked, AIsRadioItem, ASelected: Boolean);

  function GetStateRect(const R: TRect; ATexture: TACLResourceTexture): TRect;
  begin
    Result := acRectSetWidth(R, ItemGutterWidth);
    Result := acRectCenter(Result, ATexture.FrameSize);
  end;

const
  Indexes: array[Boolean, Boolean] of Integer = ((6, 2), (8, 4));
  NameMap: array[Boolean] of string = ('Buttons.Textures.CheckBox', 'Buttons.Textures.RadioBox');
var
  AImageIndex: Integer;
  APrevTargetDPI: Integer;
  ATexture: TACLResourceTexture;
begin
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
end;

procedure TACLStyleMenu.DoDrawGlyph(ACanvas: TCanvas; const R: TRect; AGlyph: TACLGlyph; AEnabled, ASelected: Boolean);
begin
  AGlyph.TargetDPI := TargetDPI;
  AGlyph.Draw(ACanvas.Handle, acRectCenter(R, AGlyph.FrameSize), AEnabled);
end;

procedure TACLStyleMenu.DoDrawImage(ACanvas: TCanvas; const R: TRect;
  AImages: TCustomImageList; AImageIndex: TImageIndex; AEnabled, ASelected: Boolean);
begin
  if (AImages <> nil) and (AImageIndex >= 0) then
    acDrawImage(ACanvas, acRectCenter(R, acGetImageListSize(AImages, TargetDPI)), AImages, AImageIndex, AEnabled);
end;

procedure TACLStyleMenu.DoDrawText(ACanvas: TCanvas; const R: TRect; const S: UnicodeString);
begin
  acTextDraw(ACanvas, S, R, taLeftJustify, taVerticalCenter, True);
end;

procedure TACLStyleMenu.DoSplitRect(const R: TRect; AGutterWidth: Integer; out AGutterRect, AContentRect: TRect);
begin
  AGutterRect := acRectSetWidth(R, AGutterWidth);
  AContentRect := R;
  AContentRect.Left := AGutterRect.Right;
end;

procedure TACLStyleMenu.DoChanged(AChanges: TACLPersistentChanges);
begin
  FItemHeight := -1;
  inherited;
end;

procedure TACLStyleMenu.InitializeResources;
begin
  Borders.InitailizeDefaults('Popup.Margins.Borders', acBorderOffsets);
  CornerRadius.InitailizeDefaults('Popup.Margins.CornerRadius', 0);
  ColorBorder1.InitailizeDefaults('Popup.Colors.Border1');
  ColorBorder2.InitailizeDefaults('Popup.Colors.Border2');
  ColorItem.InitailizeDefaults('Popup.Colors.Item', TAlphaColor.None);
  ColorItemSelected.InitailizeDefaults('Popup.Colors.ItemSelected', TAlphaColor.None);
  Font.InitailizeDefaults('Popup.Fonts.Default');
  FontDisabled.InitailizeDefaults('Popup.Fonts.Disabled');
  FontSelected.InitailizeDefaults('Popup.Fonts.Selected');
  Texture.InitailizeDefaults('Popup.Textures.General');
  TextureGutter.InitailizeDefaults('Popup.Textures.Gutter');
  TextureSeparator.InitailizeDefaults('Popup.Textures.Separator');
  TextureScrollBar.InitailizeDefaults('Popup.Textures.ScrollBar');
  TextureScrollBarButtons.InitailizeDefaults('Popup.Textures.ScrollBarButtons');
  TextureScrollBarThumb.InitailizeDefaults('Popup.Textures.ScrollBarThumb');
end;

function TACLStyleMenu.GetBackgroundColor(ASelected: Boolean): TColor;
begin
  if ASelected then
    Result := ColorItemSelected.AsColor
  else
    Result := ColorItem.AsColor;
end;

function TACLStyleMenu.GetItemGutterWidth: Integer;
begin
  Result := TextureGutter.FrameWidth;
end;

function TACLStyleMenu.GetItemHeight: Integer;
begin
  if FItemHeight < 0 then
    FItemHeight := CalculateItemHeight;
  Result := FItemHeight;
end;

function TACLStyleMenu.GetSeparatorHeight: Integer;
begin
  Result := TextureSeparator.FrameHeight;
end;

function TACLStyleMenu.GetTextIdent: Integer;
begin
  Result := 2 * Scale(acTextIndent);
end;

function TACLStyleMenu.IsCheckItem(AItem: TMenuItem): Boolean;
begin
  if AItem is TACLMenuItem then
    Result := TACLMenuItem(AItem).IsCheckItem
  else
    Result := AItem.Checked or AItem.AutoCheck or AItem.RadioItem;
end;

{ TACLMenuController }

class procedure TACLMenuController.Register(ABar: TACLMenuPopupWindow);
begin
  if FMenus = nil then
  begin
    FMenus := TList.Create;
    FHook := SetWindowsHookEx(WH_CALLWNDPROC, @CallWindowHook, 0, GetCurrentThreadID);
  end;
  FMenus.Add(ABar);
end;

class procedure TACLMenuController.Unregister(ABar: TACLMenuPopupWindow);
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

initialization
  RegisterClasses([TACLMenuItem, TACLMenuItemLink]);
end.
