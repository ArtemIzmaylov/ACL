{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*         TabControl & PageControl          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.TabControl;

{$I ACL.Config.INC}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Classes,
  System.Math,
  System.SysUtils,
  System.Types,
  // Vcl
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.Math,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Forms,
  ACL.UI.Insight,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Desktop,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

type
  TACLCustomTabControl = class;
  TACLPageControl = class;

  { TACLStyleTabControl }

  TACLTabsStyle = (tsTab, tsHeader);

  TACLStyleTabControl = class(TACLStyle)
  public const
    Offset = 2;
  protected
    procedure InitializeResources; override;
  public
    procedure DrawTab(ACanvas: TCanvas; const R: TRect; AActive, AFocused: Boolean; AStyle: TACLTabsStyle);
  published
    property ColorBorder1: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorBorder2: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorContent: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property HeaderFont: TACLResourceFont index 0 read GetFont write SetFont stored IsFontStored;
    property HeaderFontActive: TACLResourceFont index 1 read GetFont write SetFont stored IsFontStored;
    property HeaderTexture: TACLResourceTexture index 0 read GetTexture write SetTexture stored IsTextureStored;
  end;

  { TACLTab }

  TACLTab = class(TCollectionItem)
  strict private
    FCaption: UnicodeString;
    FData: Pointer;
    FVisible: Boolean;

    procedure SetCaption(const AValue: UnicodeString);
    procedure SetVisible(AValue: Boolean);
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    //# Properties
    property Data: Pointer read FData write FData;
  published
    property Caption: UnicodeString read FCaption write SetCaption;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

  { TACLTabsList }

  TACLTabsList = class(TCollection)
  strict private
    FControl: TACLCustomTabControl;

    function GetItem(Index: Integer): TACLTab;
  protected
    function GetOwner: TPersistent; override;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AControl: TACLCustomTabControl); virtual;
    function Add: TACLTab; overload;
    function Add(const ACaption: UnicodeString; AData: Pointer = nil): TACLTab; overload;
    function FindByCaption(const ACaption: UnicodeString; out ATab: TACLTab): Boolean;
    //# Properties
    property Items[Index: Integer]: TACLTab read GetItem; default;
  end;

  { TACLTabViewItem }

  TACLTabViewItem = class
  public
    Active: Boolean;
    Hover: Boolean;
    Bounds: TRect;
    Tab: TACLTab;
    TextRect: TRect;
    TextTruncated: Boolean;

    constructor Create(ATab: TACLTab);
  end;

  { TACLTabViewItemList }

  TACLTabViewItemList = class(TACLObjectList)
  strict private
    function GetItem(Index: Integer): TACLTabViewItem;
  public
    function FindByTab(ATab: TACLTab; out AItem: TACLTabViewItem): Boolean;
    //# Properties
    property Items[Index: Integer]: TACLTabViewItem read GetItem; default;
  end;

  { TACLTabsOptionsView }

  TACLTabsPosition = (tpTop, tpBottom);

  TACLTabsOptionsView = class(TPersistent)
  strict private
    FControl: TACLCustomTabControl;
    FStyle: TACLTabsStyle;
    FTabIndent: Integer;
    FTabPosition: TACLTabsPosition;
    FTabWidth: Integer;

    procedure SetStyle(AValue: TACLTabsStyle);
    procedure SetTabIndent(AValue: Integer);
    procedure SetTabPosition(AValue: TACLTabsPosition);
    procedure SetTabWidth(AValue: Integer);
  protected
    procedure Changed;
  public
    constructor Create(AControl: TACLCustomTabControl);
    procedure Assign(Source: TPersistent); override;
  published
    property Style: TACLTabsStyle read FStyle write SetStyle default tsTab;
    property TabPosition: TACLTabsPosition read FTabPosition write SetTabPosition default tpTop;
    property TabIndent: Integer read FTabIndent write SetTabIndent default 3;
    property TabWidth: Integer read FTabWidth write SetTabWidth default -1;
  end;

  { TACLCustomTabControl }

  TACLTabsActiveChangeEvent = procedure (Sender: TObject; AActiveIndex: Integer) of object;

  TACLCustomTabControl = class(TACLCustomControl)
  strict private
    FActiveIndex: Integer;
    FBorders: TACLBorders;
    FHoverTab: TACLTab;
    FIsUserAction: Boolean;
    FLoadedActiveIndex: Integer;
    FOptionsView: TACLTabsOptionsView;
    FStyle: TACLStyleTabControl;
    FTabs: TACLTabsList;
    FViewItems: TACLTabViewItemList;

    FOnTabChanging: TACLTabsActiveChangeEvent;
    FOnTabChanged: TACLTabsActiveChangeEvent;

    procedure SetActiveIndex(AValue: Integer);
    procedure SetBorders(AValue: TACLBorders);
    procedure SetHoverTab(AValue: TACLTab);
    procedure SetOptionsView(AValue: TACLTabsOptionsView);
    procedure SetStyle(AValue: TACLStyleTabControl);
    procedure SetTabs(AValue: TACLTabsList);
  protected
    FFrameRect: TRect;
    FTabAreaRect: TRect;

    function CreatePadding: TACLPadding; override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    function HitTest(X, Y: Integer; var AViewItem: TACLTabViewItem): Boolean;
    function IsTabVisible(AIndex: Integer): Boolean;
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure BoundsChanged; override;
    procedure SetDefaultSize; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure CreateWnd; override;
    procedure ValidateActiveTab;
    procedure ValidateFocus; virtual;

    // Calculating
    function CalculateTabPlaceIndents(AItem: TACLTabViewItem): TRect; virtual;
    function CalculateTabTextOffsets(AItem: TACLTabViewItem): TRect; virtual;
    function CalculateTabWidth(AItem: TACLTabViewItem): Integer; virtual;
    function CalculateTextSize(const ACaption: UnicodeString): TSize; virtual;
    procedure Calculate;
    procedure CalculateCore; virtual;
    procedure CalculateTabPlaces(const R: TRect); virtual;
    procedure CalculateTabStates; virtual;
    function GetTabHeight: Integer;
    function GetTabMargins: TRect; virtual;
    procedure PopulateViewItems; virtual;

    // Drawing
    procedure DrawContentAreaBackground(ACanvas: TCanvas); virtual;
    procedure DrawItem(ACanvas: TCanvas; AViewItem: TACLTabViewItem); virtual;
    procedure DrawItems(ACanvas: TCanvas); virtual;
    procedure DrawItemText(ACanvas: TCanvas; AViewItem: TACLTabViewItem); virtual;
    procedure DrawTransparentBackground(ACanvas: TCanvas; const R: TRect); override;
    procedure Paint; override;

    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    // Mouse
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    function IsMouseAtControl: Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;

    procedure DoActiveIndexChanged; virtual;
    procedure DoActiveIndexChanging(ANewIndex: Integer); virtual;
    procedure DoLoaded; override;
    procedure FocusChanged; override;
    // Messages
    procedure CMChildKey(var Message: TCMChildKey); message CM_CHILDKEY;
    procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    //# Properties
    property Tabs: TACLTabsList read FTabs write SetTabs;
    property ViewItems: TACLTabViewItemList read FViewItems;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure JumpToNextPage(AForward: Boolean);
    //# Properties
    property HoverTab: TACLTab read FHoverTab;
    property IsUserAction: Boolean read FIsUserAction;
  published
    property ActiveIndex: Integer read FActiveIndex write SetActiveIndex default 0;
    property Align;
    property Anchors;
    property Borders: TACLBorders read FBorders write SetBorders default acAllBorders;
    property Font;
    property Padding;
    property OptionsView: TACLTabsOptionsView read FOptionsView write SetOptionsView;
    property ResourceCollection;
    property Style: TACLStyleTabControl read FStyle write SetStyle;
    property Visible;
    //# Events
    property OnTabChanging: TACLTabsActiveChangeEvent read FOnTabChanging write FOnTabChanging;
    property OnTabChanged: TACLTabsActiveChangeEvent read FOnTabChanged write FOnTabChanged;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;
  end;

  { TACLTabControl }

  TACLTabControl = class(TACLCustomTabControl)
  strict private
    function GetActiveTab: TACLTab;
  public
    procedure Localize(const ASection: string); override;
    //# Properties
    property ActiveTab: TACLTab read GetActiveTab;
  published
    property Tabs;
  end;

  { TACLPageControlPage }

  TACLPageControlPage = class(TACLCustomControl)
  strict private
    FPageVisible: Boolean;

    function GetActive: Boolean;
    function GetPageControl: TACLPageControl;
    function GetPageIndex: Integer;
    procedure SetPageControl(AValue: TACLPageControl);
    procedure SetPageIndex(AValue: Integer);
    procedure SetPageVisible(AValue: Boolean);
    //# Messages
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    FTab: TACLTab;

    procedure DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect); override;
    procedure SetParent(AParent: TWinControl); override;
    procedure UpdateTab;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //# Properties
    property Active: Boolean read GetActive;
    property PageControl: TACLPageControl read GetPageControl write SetPageControl;
  published
    property Caption;
    property Padding;
    property PageIndex: Integer read GetPageIndex write SetPageIndex stored False;
    property PageVisible: Boolean read FPageVisible write SetPageVisible default True;
    //# Useless
    property Height stored False;
    property Left stored False;
    property Top stored False;
    property Width stored False;
  end;

  { TACLPageControl }

  TACLPageControl = class(TACLCustomTabControl)
  strict private
    function GetActivePage: TACLPageControlPage;
    function GetPageCount: Integer;
    function GetPages(Index: Integer): TACLPageControlPage;
    procedure SetActivePage(AValue: TACLPageControlPage);
  protected
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    procedure DoActiveIndexChanged; override;
    procedure PageAdded(APage: TACLPageControlPage);
    procedure PageRemoving(APage: TACLPageControlPage);
    procedure ResourceChanged; override;
    procedure UpdatePagesVisibility;
    procedure ValidateFocus; override;
    procedure ValidateInsert(AComponent: TComponent); override;
  public
    function AddPage(const ACaption: UnicodeString): TACLPageControlPage;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure GetTabOrderList(List: TList); override;
    procedure ShowControl(AControl: TControl); override;
    //# Properties
    property ActivePage: TACLPageControlPage read GetActivePage write SetActivePage;
    property PageCount: Integer read GetPageCount;
    property Pages[Index: Integer]: TACLPageControlPage read GetPages;
  end;

  { TACLPageControlUIInsightAdapter }

  TACLPageControlUIInsightAdapter = class(TACLUIInsightAdapterWinControl)
  public
    class procedure GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder); override;
  end;

  { TACLPageControlPageUIInsightAdapter }

  TACLPageControlPageUIInsightAdapter = class(TACLUIInsightAdapterWinControl)
  public
    class function MakeVisible(AObject: TObject): Boolean; override;
  end;

var
  acUIMouseWheelSwitchesTabs: Boolean = True;

implementation

uses
  ACL.MUI;

const
  sErrorWrongChild = 'Only %s can be placed on %s';
  sErrorWrongParent = '%s should be placed on %s';

{ TACLStyleTabControl }

procedure TACLStyleTabControl.DrawTab(ACanvas: TCanvas;
  const R: TRect; AActive, AFocused: Boolean; AStyle: TACLTabsStyle);
begin
  HeaderTexture.Draw(ACanvas.Handle, R, Ord(AStyle) * 2 + Ord(AActive));
  if AActive and AFocused then
    acDrawFocusRect(ACanvas, acRectContent(R, HeaderTexture.ContentOffsets));
end;

procedure TACLStyleTabControl.InitializeResources;
begin
  ColorBorder1.InitailizeDefaults('Tabs.Colors.Border1');
  ColorBorder2.InitailizeDefaults('Tabs.Colors.Border2');
  ColorContent.InitailizeDefaults('Tabs.Colors.Content');
  HeaderTexture.InitailizeDefaults('Tabs.Textures.Header');
  HeaderFontActive.InitailizeDefaults('Tabs.Fonts.HeaderActive');
  HeaderFont.InitailizeDefaults('Tabs.Fonts.Header');
end;

{ TACLTab }

constructor TACLTab.Create(Collection: TCollection);
begin
  FCaption := 'Tab';
  FVisible := True;
  inherited Create(Collection);
end;

procedure TACLTab.Assign(Source: TPersistent);
begin
  if Source is TACLTab then
  begin
    FCaption := TACLTab(Source).Caption;
    FVisible := TACLTab(Source).Visible;
    Changed(True);
  end;
end;

procedure TACLTab.SetCaption(const AValue: UnicodeString);
begin
  if AValue <> FCaption then
  begin
    FCaption := AValue;
    Changed(False);
  end;
end;

procedure TACLTab.SetVisible(AValue: Boolean);
begin
  if AValue <> FVisible then
  begin
    FVisible := AValue;
    Changed(True);
  end;
end;

{ TACLTabsList }

constructor TACLTabsList.Create(AControl: TACLCustomTabControl);
begin
  inherited Create(TACLTab);
  FControl := AControl;
end;

function TACLTabsList.Add: TACLTab;
begin
  Result := TACLTab(inherited Add);
end;

function TACLTabsList.Add(const ACaption: UnicodeString; AData: Pointer = nil): TACLTab;
begin
  BeginUpdate;
  try
    Result := Add;
    Result.Data := AData;
    Result.Caption := ACaption;
  finally
    EndUpdate;
  end;
end;

function TACLTabsList.FindByCaption(const ACaption: UnicodeString; out ATab: TACLTab): Boolean;
begin
  for var I := 0 to Count - 1 do
    if acSameText(Items[I].Caption, ACaption) then
    begin
      ATab := Items[I];
      Exit(True);
    end;
  Result := False;
end;

function TACLTabsList.GetItem(Index: Integer): TACLTab;
begin
  Result := TACLTab(inherited Items[Index]);
end;

function TACLTabsList.GetOwner: TPersistent;
begin
  Result := FControl;
end;

procedure TACLTabsList.Update(Item: TCollectionItem);
begin
  FControl.FullRefresh;
end;

{ TACLCustomTabControl }

constructor TACLCustomTabControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActiveIndex := -1;
  FBorders := acAllBorders;
  TabStop := True;
  ControlStyle := ControlStyle + [csAcceptsControls];
  FStyle := TACLStyleTabControl.Create(Self);
  FTabs := TACLTabsList.Create(Self);
  FViewItems := TACLTabViewItemList.Create;
  FOptionsView := TACLTabsOptionsView.Create(Self);
end;

destructor TACLCustomTabControl.Destroy;
begin
  FreeAndNil(FStyle);
  FreeAndNil(FOptionsView);
  FreeAndNil(FViewItems);
  FreeAndNil(FTabs);
  inherited Destroy;
end;

procedure TACLCustomTabControl.AdjustClientRect(var Rect: TRect);
begin
  Rect := acRectContent(FFrameRect, 1, Borders);
  Rect := acRectContent(Rect, Padding.GetScaledMargins(FCurrentPPI));
end;

procedure TACLCustomTabControl.BoundsChanged;
begin
  inherited;
  ValidateActiveTab;
  if HandleAllocated then
  begin
    Calculate;
    Realign;
    Invalidate;
  end;
end;

function TACLCustomTabControl.CreatePadding: TACLPadding;
begin
  Result := TACLPadding.Create(5);
end;

procedure TACLCustomTabControl.CreateWnd;
begin
  inherited CreateWnd;
  FullRefresh;
end;

procedure TACLCustomTabControl.Calculate;
begin
  if HandleAllocated then
  begin
    PopulateViewItems;
    CalculateCore;
    CalculateTabStates;
    CalculateTabPlaces(FTabAreaRect);
  end;
end;

procedure TACLCustomTabControl.CalculateCore;
begin
  FFrameRect := ClientRect;
  if OptionsView.TabPosition = tpBottom then
  begin
    FTabAreaRect := FFrameRect;
    FTabAreaRect.Top := FTabAreaRect.Bottom - GetTabHeight;
    FFrameRect.Bottom := FTabAreaRect.Top;
  end
  else
  begin
    FTabAreaRect := FFrameRect;
    FTabAreaRect.Bottom := FTabAreaRect.Top + GetTabHeight;
    FFrameRect.Top := FTabAreaRect.Bottom;
  end;
end;

function TACLCustomTabControl.CalculateTabPlaceIndents(AItem: TACLTabViewItem): TRect;
begin
  Result := NullRect;
  if AItem.Active then
  begin
    Result.Left := -dpiApply(OptionsView.TabIndent, FCurrentPPI) - 1;
    Result.Right := Result.Left;
    Result.Bottom := -2;
  end
  else
    Result.Top := dpiApply(TACLStyleTabControl.Offset, FCurrentPPI);

  if OptionsView.TabPosition = tpBottom then
    acExchangeIntegers(Result.Top, Result.Bottom);
end;

procedure TACLCustomTabControl.CalculateTabPlaces(const R: TRect);
var
  ACalculator: TACLAutoSizeCalculator;
  AContentRect: TRect;
  AIndentBetweenTabs: Integer;
  AItem: TACLTabViewItem;
  ATabOffset: Integer;
  ATextSize: TSize;
  AWidth: Integer;
begin
  AIndentBetweenTabs := dpiApply(OptionsView.TabIndent, FCurrentPPI);
  if OptionsView.Style = tsTab then
    ATabOffset := dpiApply(OptionsView.TabIndent, FCurrentPPI) + 1
  else
    ATabOffset := 0;

  ACalculator := TACLAutoSizeCalculator.Create;
  try
    ACalculator.Capacity := ViewItems.Count;
    ACalculator.AvailableSize := acRectWidth(R) - 2 * ATabOffset;
    for var I := 0 to ViewItems.Count - 1 do
    begin
      if OptionsView.Style = tsTab then
        AWidth := CalculateTabWidth(ViewItems[I]) + IfThen(I + 1 < ViewItems.Count, AIndentBetweenTabs)
      else
        AWidth := 0;

      ACalculator.Add(AWidth, 1, AWidth, True);
    end;
    ACalculator.Calculate;

    Inc(ATabOffset, R.Left);
    for var I := 0 to ViewItems.Count - 1 do
    begin
      AItem := ViewItems[I];
      AItem.Bounds := Bounds(ATabOffset, R.Top, ACalculator[I].Size, acRectHeight(R));
      if I + 1 < ViewItems.Count then
        Dec(AItem.Bounds.Right, AIndentBetweenTabs);
      ATabOffset := AItem.Bounds.Right + AIndentBetweenTabs;

      if OptionsView.Style = tsTab then
        AItem.Bounds := acRectContent(AItem.Bounds, CalculateTabPlaceIndents(AItem))
      else if OptionsView.TabPosition = tpTop then
        Dec(AItem.Bounds.Bottom, AIndentBetweenTabs)
      else
        Inc(AItem.Bounds.Top, AIndentBetweenTabs);

      if AItem.Tab.Caption <> '' then
      begin
        if AItem.Active then
          MeasureCanvas.Font.Assign(Style.HeaderFontActive)
        else
          MeasureCanvas.Font.Assign(Style.HeaderFont);

        ATextSize := acTextSize(MeasureCanvas, AItem.Tab.Caption);
        AContentRect := acRectContent(AItem.Bounds, CalculateTabTextOffsets(AItem));
        AItem.TextRect := acRectCenter(AContentRect, ATextSize);
        AItem.TextTruncated := ATextSize.cx > AContentRect.Width;
        IntersectRect(AItem.TextRect, AItem.TextRect, AContentRect);
      end;
    end;
  finally
    ACalculator.Free;
  end;
end;

function TACLCustomTabControl.CalculateTabWidth(AItem: TACLTabViewItem): Integer;
begin
  if OptionsView.TabWidth > 0 then
    Result := dpiApply(OptionsView.TabWidth, FCurrentPPI)
  else
    Result := acMarginWidth(GetTabMargins) + CalculateTextSize(AItem.Tab.Caption).cx;
end;

procedure TACLCustomTabControl.CalculateTabStates;
var
  AViewItem: TACLTabViewItem;
begin
  for var I := 0 to ViewItems.Count - 1 do
  begin
    AViewItem := ViewItems[I];
    AViewItem.Active := ActiveIndex = AViewItem.Tab.Index;
    AViewItem.Hover := HoverTab = AViewItem.Tab;
  end;
end;

function TACLCustomTabControl.CalculateTabTextOffsets(AItem: TACLTabViewItem): TRect;
begin
  Result := GetTabMargins;
end;

function TACLCustomTabControl.CalculateTextSize(const ACaption: UnicodeString): TSize;
begin
  Result := NullSize;
  Canvas.Font.Assign(Style.HeaderFont);
  Result := acSizeMax(Result, acTextSize(Canvas, ACaption));
  Canvas.Font.Assign(Style.HeaderFontActive);
  Result := acSizeMax(Result, acTextSize(Canvas, ACaption));
end;

procedure TACLCustomTabControl.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Style.SetTargetDPI(AValue);
end;

procedure TACLCustomTabControl.DoActiveIndexChanging(ANewIndex: Integer);
begin
  if [csDesigning, csDestroying] * ComponentState = [] then
  begin
    if Assigned(OnTabChanging) then
      OnTabChanging(Self, ANewIndex);
  end;
end;

procedure TACLCustomTabControl.DoActiveIndexChanged;
begin
  if csDesigning in ComponentState then
  begin
    acDesignerSetModified(Self);
    Exit;
  end;

  if [csDestroying] * ComponentState = [] then
  begin
    if Assigned(OnTabChanged) then
      OnTabChanged(Self, ActiveIndex);
    ValidateFocus;
  end;
end;

procedure TACLCustomTabControl.DrawContentAreaBackground(ACanvas: TCanvas);
begin
  acFillRect(ACanvas.Handle, FFrameRect, Style.ColorContent.AsColor);
  acDrawComplexFrame(ACanvas.Handle, FFrameRect,
    Style.ColorBorder1.AsColor, Style.ColorBorder2.AsColor, Borders);
end;

procedure TACLCustomTabControl.DrawItem(ACanvas: TCanvas; AViewItem: TACLTabViewItem);
var
  ATemp: TACLBitmapLayer;
begin
  if not AViewItem.Bounds.IsEmpty then
  begin
    if (OptionsView.Style = tsTab) and (OptionsView.TabPosition = tpBottom) then
    begin
      ATemp := TACLBitmapLayer.Create(AViewItem.Bounds);
      try
        acBitBlt(ATemp.Handle, ACanvas.Handle, ATemp.ClientRect, AViewItem.Bounds.TopLeft);
        Style.DrawTab(ATemp.Canvas, ATemp.ClientRect, AViewItem.Active, Focused, OptionsView.Style);
        ATemp.Flip(False, True);
        ATemp.DrawCopy(ACanvas.Handle, AViewItem.Bounds.TopLeft);
      finally
        ATemp.Free;
      end;
    end
    else
      Style.DrawTab(ACanvas, AViewItem.Bounds, AViewItem.Active, Focused, OptionsView.Style);

    DrawItemText(ACanvas, AViewItem);
  end;
end;

procedure TACLCustomTabControl.DrawItems(ACanvas: TCanvas);
var
  AActiveViewItem: TACLTabViewItem;
  AViewItem: TACLTabViewItem;
begin
  AActiveViewItem := nil;
  for var I := 0 to ViewItems.Count - 1 do
  begin
    AViewItem := ViewItems.List[I];
    if AViewItem.Active then
      AActiveViewItem := AViewItem
    else
      DrawItem(ACanvas, AViewItem);
  end;
  if AActiveViewItem <> nil then
    DrawItem(ACanvas, AActiveViewItem);
end;

procedure TACLCustomTabControl.DrawItemText(ACanvas: TCanvas; AViewItem: TACLTabViewItem);
begin
  if not AViewItem.TextRect.IsEmpty then
  begin
    if AViewItem.Active then
      ACanvas.Font.Assign(Style.HeaderFontActive)
    else
      ACanvas.Font.Assign(Style.HeaderFont);

    ACanvas.Brush.Style := bsClear;
    acTextDraw(ACanvas, AViewItem.Tab.Caption,
      AViewItem.TextRect, taLeftJustify, taAlignTop, AViewItem.TextTruncated);
  end;
end;

procedure TACLCustomTabControl.DrawTransparentBackground(ACanvas: TCanvas; const R: TRect);
var
  LPrevRgn: HRGN;
begin
  LPrevRgn := acSaveClipRegion(ACanvas.Handle);
  try
    if acIntersectClipRegion(ACanvas.Handle, FTabAreaRect) then
      inherited;
  finally
    acRestoreClipRegion(ACanvas.Handle, LPrevRgn);
  end;
end;

procedure TACLCustomTabControl.JumpToNextPage(AForward: Boolean);
var
  AIndex: Integer;
  AStartIndex: Integer;
begin
  AIndex := ActiveIndex;
  if ActiveIndex < 0 then
    AStartIndex := IfThen(AForward, Tabs.Count - 1, 0)
  else
    AStartIndex := ActiveIndex;

  if Tabs.Count > 0 then
  repeat
    AIndex := (AIndex + Tabs.Count + Signs[AForward]) mod Tabs.Count;
  until (AIndex = AStartIndex) or IsTabVisible(AIndex);

  if IsTabVisible(AIndex) then
    ActiveIndex := AIndex
  else
    ActiveIndex := -1;
end;

function TACLCustomTabControl.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  Result := cbsTransparent;
end;

function TACLCustomTabControl.HitTest(X, Y: Integer; var AViewItem: TACLTabViewItem): Boolean;
begin
  for var I := 0 to ViewItems.Count - 1 do
    if PtInRect(ViewItems[I].Bounds, Point(X, Y)) then
    begin
      AViewItem := ViewItems[I];
      Exit(True);
    end;

  Result := False;
end;

function TACLCustomTabControl.IsTabVisible(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Tabs.Count) and Tabs[AIndex].Visible;
end;

procedure TACLCustomTabControl.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);

  case Key of
    VK_LEFT, VK_RIGHT:
      begin
        FIsUserAction := True;
        try
          ActiveIndex := ActiveIndex + Signs[Key = VK_RIGHT];
        finally
          FIsUserAction := False;
        end;
      end;
  end;
end;

function TACLCustomTabControl.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := acUIMouseWheelSwitchesTabs and PtInRect(FTabAreaRect, ScreenToClient(MousePos));
  if Result then
    ActiveIndex := ActiveIndex + Signs[WheelDelta < 0];
end;

function TACLCustomTabControl.IsMouseAtControl: Boolean;
begin
  Result := HandleAllocated and (WindowFromPoint(MouseCursorPos) = Handle);
end;

procedure TACLCustomTabControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  AViewItem: TACLTabViewItem;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if HitTest(X, Y, AViewItem) then
  begin
    FIsUserAction := True;
    try
      ActiveIndex := AViewItem.Tab.Index;
      SetFocus;
    finally
      FIsUserAction := False;
    end;
  end;
end;

procedure TACLCustomTabControl.MouseLeave;
begin
  SetHoverTab(nil);
  inherited MouseLeave;
end;

procedure TACLCustomTabControl.MouseMove(Shift: TShiftState; X, Y: Integer);
const
  CursorsMap: array[Boolean] of TCursor = (crDefault, crHandPoint);
var
  AViewItem: TACLTabViewItem;
begin
  inherited MouseMove(Shift, X, Y);

  if HitTest(X, Y, AViewItem) then
    SetHoverTab(AViewItem.Tab)
  else
    SetHoverTab(nil);

  Cursor := CursorsMap[(HoverTab <> nil) and (HoverTab.Index <> ActiveIndex)];
end;

procedure TACLCustomTabControl.Paint;
begin
  DrawContentAreaBackground(Canvas);
  DrawItems(Canvas);
end;

procedure TACLCustomTabControl.FocusChanged;
begin
  inherited FocusChanged;
  Invalidate;
end;

procedure TACLCustomTabControl.DoLoaded;
begin
  inherited;
  ActiveIndex := FLoadedActiveIndex;
end;

procedure TACLCustomTabControl.ValidateActiveTab;
begin
  if not IsTabVisible(ActiveIndex) then
    JumpToNextPage(True);
end;

procedure TACLCustomTabControl.ValidateFocus;
var
  AControl: TWinControl;
  AForm: TCustomForm;
begin
  if IsUserAction then
    Exit;

  AForm := GetParentForm(Self);
  if AForm <> nil then
  begin
    AControl := FindNextControl(nil, True, True, False);
    if AControl = nil then
      AControl := FindNextControl(nil, True, False, False);
    if AControl = nil then
      AControl := Self;
    if AControl.CanFocus then
      AForm.ActiveControl := AControl;
  end;
end;

procedure TACLCustomTabControl.CMChildKey(var Message: TCMChildKey);
var
  AShiftState: TShiftState;
begin
  case Message.CharCode of
    VK_PRIOR, VK_NEXT:
      if [ssCtrl, ssAlt, ssShift] * acGetShiftState = [ssCtrl] then
      begin
        JumpToNextPage(Message.CharCode = VK_NEXT);
        Message.Result := 1;
      end;

    VK_TAB:
      begin
        AShiftState := acGetShiftState;
        if [ssCtrl, ssAlt] * AShiftState = [ssCtrl] then
        begin
          JumpToNextPage(not (ssShift in AShiftState));
          Message.Result := 1;
        end;
      end;
  end;
  if Message.Result = 0 then
    inherited;
end;

procedure TACLCustomTabControl.CMDesignHitTest(var Message: TCMDesignHitTest);
var
  X: TACLTabViewItem;
begin
  if HitTest(Message.XPos, Message.YPos, X) then
    Message.Result := 1
  else
    inherited;
end;

procedure TACLCustomTabControl.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS;
end;

function TACLCustomTabControl.GetTabHeight: Integer;
begin
  Result := 0;
  if ViewItems.Count > 0 then
  begin
    Result := CalculateTextSize('Wg').cy + acMarginHeight(GetTabMargins);
    if OptionsView.Style = tsHeader then
      Inc(Result, dpiApply(OptionsView.TabIndent, FCurrentPPI))
    else
      Inc(Result, dpiApply(TACLStyleTabControl.Offset, FCurrentPPI));
  end;
end;

function TACLCustomTabControl.GetTabMargins: TRect;
begin
  if OptionsView.Style = tsHeader then
    Result := Rect(6, 6, 6, 6)
  else
    Result := Rect(4, 4, 4, 4);

  Result := dpiApply(Result, FCurrentPPI);
end;

procedure TACLCustomTabControl.PopulateViewItems;
begin
  ViewItems.Clear;
  for var I := 0 to Tabs.Count - 1 do
  begin
    if Tabs[I].Visible then
      ViewItems.Add(TACLTabViewItem.Create(Tabs[I]));
  end;
end;

procedure TACLCustomTabControl.SetActiveIndex(AValue: Integer);
begin
  if csLoading in ComponentState then
  begin
    FLoadedActiveIndex := AValue;
    Exit;
  end;

  AValue := MinMax(AValue, -1, Tabs.Count - 1);
  if AValue <> FActiveIndex then
  try
    DoActiveIndexChanging(AValue);
    FActiveIndex := AValue;
    DoActiveIndexChanged;
    FullRefresh;
  except
    // do nothing
  end;
end;

procedure TACLCustomTabControl.SetBorders(AValue: TACLBorders);
begin
  if FBorders <> AValue then
  begin
    FBorders := AValue;
    FullRefresh;
  end;
end;

procedure TACLCustomTabControl.SetDefaultSize;
begin
  SetBounds(Left, Top, 400, 300);
end;

procedure TACLCustomTabControl.SetHoverTab(AValue: TACLTab);
var
  AItem: TACLTabViewItem;
begin
  if HoverTab <> AValue then
  begin
    FHoverTab := AValue;
    if not (csDesigning in ComponentState) then
    begin
      Application.CancelHint;
      if ViewItems.FindByTab(HoverTab, AItem) and AItem.TextTruncated then
        Hint := AItem.Tab.Caption
      else
        Hint := '';
    end;
    CalculateTabStates;
    Invalidate;
  end;
end;

procedure TACLCustomTabControl.SetOptionsView(AValue: TACLTabsOptionsView);
begin
  FOptionsView.Assign(AValue);
end;

procedure TACLCustomTabControl.SetStyle(AValue: TACLStyleTabControl);
begin
  FStyle.Assign(AValue);
end;

procedure TACLCustomTabControl.SetTabs(AValue: TACLTabsList);
begin
  FTabs.Assign(AValue);
end;

{ TACLTabViewItem }

constructor TACLTabViewItem.Create(ATab: TACLTab);
begin
  inherited Create;
  Tab := ATab;
end;

{ TACLTabViewItemList }

function TACLTabViewItemList.FindByTab(ATab: TACLTab; out AItem: TACLTabViewItem): Boolean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].Tab = ATab then
    begin
      AItem := Items[I];
      Exit(True);
    end;

  Result := False;
end;

function TACLTabViewItemList.GetItem(Index: Integer): TACLTabViewItem;
begin
  Result := TACLTabViewItem(inherited Items[Index]);
end;

{ TACLTabsOptionsView }

constructor TACLTabsOptionsView.Create(AControl: TACLCustomTabControl);
begin
  inherited Create;
  FControl := AControl;
  FTabPosition := tpTop;
  FTabWidth := -1;
  FTabIndent := 3;
end;

procedure TACLTabsOptionsView.Assign(Source: TPersistent);
begin
  if Source is TACLTabsOptionsView then
  begin
    FStyle := TACLTabsOptionsView(Source).Style;
    FTabPosition := TACLTabsOptionsView(Source).TabPosition;
    FTabWidth := TACLTabsOptionsView(Source).TabWidth;
    FTabIndent := TACLTabsOptionsView(Source).TabIndent;
    Changed;
  end;
end;

procedure TACLTabsOptionsView.Changed;
begin
  FControl.FullRefresh;
end;

procedure TACLTabsOptionsView.SetStyle(AValue: TACLTabsStyle);
begin
  if AValue <> FStyle then
  begin
    FStyle := AValue;
    Changed;
  end;
end;

procedure TACLTabsOptionsView.SetTabIndent(AValue: Integer);
begin
  FTabIndent := Max(FTabIndent, 0);
  if AValue <> FTabIndent then
  begin
    FTabIndent := AValue;
    Changed;
  end;
end;

procedure TACLTabsOptionsView.SetTabPosition(AValue: TACLTabsPosition);
begin
  if FTabPosition <> AValue then
  begin
    FTabPosition := AValue;
    Changed;
  end;
end;

procedure TACLTabsOptionsView.SetTabWidth(AValue: Integer);
begin
  if AValue <> FTabWidth then
  begin
    FTabWidth := AValue;
    Changed;
  end;
end;

{ TACLTabControl }

procedure TACLTabControl.Localize(const ASection: string);
var
  I: Integer;
begin
  inherited;
  for I := 0 to Tabs.Count - 1 do
    Tabs[I].Caption := LangGet(ASection, 'i[' + IntToStr(I) + ']', Tabs[I].Caption);
end;

function TACLTabControl.GetActiveTab: TACLTab;
begin
  if (ActiveIndex < 0) or (ActiveIndex >= Tabs.Count) then
    Result := nil
  else
    Result := Tabs.Items[ActiveIndex];
end;

{ TACLPageControlPage }

constructor TACLPageControlPage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  FPageVisible := True;
end;

destructor TACLPageControlPage.Destroy;
begin
  PageControl := nil;
  inherited Destroy;
end;

procedure TACLPageControlPage.DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect);
begin
  if PageControl <> nil then
    acFillRect(ACanvas.Handle, R, PageControl.Style.ColorContent.AsColor)
  else
    inherited DrawOpaqueBackground(ACanvas, R);
end;

procedure TACLPageControlPage.SetParent(AParent: TWinControl);
begin
  if (AParent <> nil) and not (AParent is TACLPageControl) then
    raise Exception.CreateFmt(sErrorWrongParent, [ClassName, TACLPageControl.ClassName]);

  if AParent <> Parent then
  begin
    if PageControl <> nil then
      PageControl.PageRemoving(Self);
    inherited SetParent(AParent);
    if PageControl <> nil then
      PageControl.PageAdded(Self);
    UpdateTab;
  end;
end;

procedure TACLPageControlPage.UpdateTab;
begin
  if FTab <> nil then
  begin
    FTab.Caption := Caption;
    FTab.Visible := PageVisible;
  end;
end;

procedure TACLPageControlPage.CMTextChanged(var Message: TMessage);
begin
  inherited;
  UpdateTab;
end;

function TACLPageControlPage.GetActive: Boolean;
begin
  Result := (PageControl <> nil) and (PageControl.ActivePage = Self)
end;

function TACLPageControlPage.GetPageControl: TACLPageControl;
begin
  Result := Parent as TACLPageControl;
end;

function TACLPageControlPage.GetPageIndex: Integer;
begin
  if FTab <> nil then
    Result := FTab.Index
  else
    Result := -1;
end;

procedure TACLPageControlPage.SetPageControl(AValue: TACLPageControl);
begin
  Parent := AValue;
end;

procedure TACLPageControlPage.SetPageIndex(AValue: Integer);
begin
  if FTab <> nil then
    FTab.Index := AValue;
end;

procedure TACLPageControlPage.SetPageVisible(AValue: Boolean);
begin
  FPageVisible := AValue;
  UpdateTab;
end;

{ TACLPageControl }

function TACLPageControl.AddPage(const ACaption: UnicodeString): TACLPageControlPage;
begin
  Result := TACLPageControlPage.Create(Owner);
  Result.Name := CreateUniqueName(Result, '', '');
  Result.Caption := ACaption;
  Result.PageControl := Self;
end;

procedure TACLPageControl.AlignControls(AControl: TControl; var ARect: TRect);
var
  I: Integer;
begin
  AdjustClientRect(ARect);
  for I := 0 to PageCount - 1 do
    Pages[I].BoundsRect := ARect;
end;

procedure TACLPageControl.DoActiveIndexChanged;
begin
  UpdatePagesVisibility;
  inherited DoActiveIndexChanged;
end;

procedure TACLPageControl.PageAdded(APage: TACLPageControlPage);
begin
  APage.FTab := Tabs.Add('', APage);
  FullRefresh;
  UpdatePagesVisibility;
end;

procedure TACLPageControl.PageRemoving(APage: TACLPageControlPage);
begin
  if Tabs <> nil then
    Tabs[APage.PageIndex].Free;
  APage.FTab := nil;
end;

procedure TACLPageControl.ResourceChanged;
begin
  inherited;
  if ActivePage <> nil then
    ActivePage.Invalidate;
end;

procedure TACLPageControl.ValidateFocus;
begin
  UpdatePagesVisibility;
  inherited ValidateFocus;
end;

procedure TACLPageControl.ValidateInsert(AComponent: TComponent);
begin
  inherited ValidateInsert(AComponent);
  if not (AComponent is TACLPageControlPage) then
    raise Exception.CreateFmt(sErrorWrongChild, [TACLPageControlPage.ClassName, ClassName]);
end;

procedure TACLPageControl.UpdatePagesVisibility;
var
  I: Integer;
begin
  if not (csDesigning in ComponentState) then
  begin
    for I := 0 to PageCount - 1 do
      Pages[I].Visible := IsTabVisible(I);
  end;
  if ActivePage <> nil then
    ActivePage.BringToFront;
end;

function TACLPageControl.GetActivePage: TACLPageControlPage;
begin
  if (ActiveIndex >= 0) and (ActiveIndex < PageCount) then
    Result := Pages[ActiveIndex]
  else
    Result := nil;
end;

procedure TACLPageControl.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I: Integer;
begin
  for I := 0 to PageCount - 1 do
    Proc(Pages[I]);
end;

procedure TACLPageControl.GetTabOrderList(List: TList);
begin
  if ActivePage <> nil then
    ActivePage.GetTabOrderList(List);
end;

procedure TACLPageControl.ShowControl(AControl: TControl);
begin
  if AControl is TACLPageControlPage then
    ActivePage := TACLPageControlPage(AControl);
  inherited;
end;

function TACLPageControl.GetPageCount: Integer;
begin
  Result := Tabs.Count;
end;

function TACLPageControl.GetPages(Index: Integer): TACLPageControlPage;
begin
  Result := TACLPageControlPage(Tabs[Index].Data);
end;

procedure TACLPageControl.SetActivePage(AValue: TACLPageControlPage);
begin
  if (AValue = nil) or (AValue.PageControl = Self) then
  begin
    if AValue <> nil then
      ActiveIndex := AValue.PageIndex
    else
      ActiveIndex := -1;
  end;
end;

{ TACLPageControlUIInsightAdapter }

class procedure TACLPageControlUIInsightAdapter.GetChildren(
  AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
var
  APage: TACLPageControlPage;
  APageControl: TACLPageControl absolute AObject;
  I: Integer;
begin
  for I := 0 to APageControl.PageCount - 1 do
  begin
    APage := APageControl.Pages[I];
    if APage.PageVisible then
      ABuilder.Add(APage);
  end;
end;

{ TACLPageControlPageUIInsightAdapter }

class function TACLPageControlPageUIInsightAdapter.MakeVisible(AObject: TObject): Boolean;
var
  APage: TACLPageControlPage absolute AObject;
begin
  APage.PageControl.ActivePage := APage;
  Result := APage.Active;
end;

initialization
  RegisterClass(TACLPageControlPage);
  TACLUIInsight.Register(TACLPageControl, TACLPageControlUIInsightAdapter);
  TACLUIInsight.Register(TACLPageControlPage, TACLPageControlPageUIInsightAdapter);
end.
