{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*         TabControl & PageControl          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
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
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.Math,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Forms,
  ACL.UI.Insight,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Desktop,
  ACL.Utils.FileSystem;

type
  TACLCustomTabControl = class;
  TACLPageControl = class;

  { TACLStyleTabControl }

  TACLTabsStyle = (tsTab, tsHeader);

  TACLStyleTabControl = class(TACLStyle)
  protected
    procedure InitializeResources; override;
  public
    procedure Draw(ACanvas: TCanvas; const R: TRect; AActive: Boolean; AStyle: TACLTabsStyle);
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
    //
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
    //
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

    property Items[Index: Integer]: TACLTabViewItem read GetItem; default;
  end;

  { TACLTabsOptionsView }

  TACLTabsOptionsView = class(TPersistent)
  strict private
    FControl: TACLCustomTabControl;
    FStyle: TACLTabsStyle;
    FTabIndent: Integer;
    FTabWidth: Integer;

    function GetActualTabIndent: Integer;
    procedure SetStyle(AValue: TACLTabsStyle);
    procedure SetTabIndent(AValue: Integer);
    procedure SetTabWidth(AValue: Integer);
  protected
    procedure Changed;
    //
    property ActualTabIndent: Integer read GetActualTabIndent;
  public
    constructor Create(AControl: TACLCustomTabControl);
    procedure Assign(Source: TPersistent); override;
  published
    property Style: TACLTabsStyle read FStyle write SetStyle default tsTab;
    property TabIndent: Integer read FTabIndent write SetTabIndent default 3;
    property TabWidth: Integer read FTabWidth write SetTabWidth default -1;
  end;

  { TACLCustomTabControl }

  TACLTabsActiveChangeEvent = procedure (Sender: TObject; AActiveIndex: Integer) of object;

  TACLCustomTabControl = class(TACLCustomControl)
  strict private
    FActiveIndex: Integer;
    FFrameRect: TRect;
    FHoverTab: TACLTab;
    FIsUserAction: Boolean;
    FLoadedActiveIndex: Integer;
    FOptionsView: TACLTabsOptionsView;
    FStyle: TACLStyleTabControl;
    FTabAreaRect: TRect;
    FTabs: TACLTabsList;
    FViewItems: TACLTabViewItemList;

    FOnTabChanging: TACLTabsActiveChangeEvent;
    FOnTabChanged: TACLTabsActiveChangeEvent;

    function GetTabHeight: Integer;
    procedure SetActiveIndex(AValue: Integer);
    procedure SetHoverTab(AValue: TACLTab);
    procedure SetOptionsView(AValue: TACLTabsOptionsView);
    procedure SetStyle(AValue: TACLStyleTabControl);
    procedure SetTabs(AValue: TACLTabsList);
  protected
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
    function CalculateTabArea: TRect; virtual;
    function CalculateTabPlaceIndents(AItem: TACLTabViewItem): TRect; virtual;
    function CalculateTabTextOffsets(AItem: TACLTabViewItem): TRect; virtual;
    function CalculateTabWidth(AItem: TACLTabViewItem): Integer; virtual;
    function CalculateTextSize(const ACaption: UnicodeString): TSize; virtual;
    procedure Calculate; virtual;
    procedure CalculateTabPlaces(const R: TRect); virtual;
    procedure CalculateTabStates; virtual;
    function GetTabMargins: TRect; virtual;
    procedure PopulateViewItems; virtual;

    // Drawing
    procedure DrawContentAreaBackground(ACanvas: TCanvas); virtual;
    procedure DrawItem(ACanvas: TCanvas; AViewItem: TACLTabViewItem); virtual;
    procedure DrawItems(ACanvas: TCanvas); virtual;
    procedure DrawItemText(ACanvas: TCanvas; AViewItem: TACLTabViewItem); virtual;
    procedure DrawTransparentBackground(DC: HDC; const R: TRect); override;
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
    //
    property FrameRect: TRect read FFrameRect;
    property HoverTab: TACLTab read FHoverTab write SetHoverTab;
    property TabAreaRect: TRect read FTabAreaRect;
    property Tabs: TACLTabsList read FTabs write SetTabs;
    property ViewItems: TACLTabViewItemList read FViewItems;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure JumpToNextPage(AForward: Boolean);
    //
    property IsUserAction: Boolean read FIsUserAction;
  published
    property ActiveIndex: Integer read FActiveIndex write SetActiveIndex default 0;
    property Align;
    property Anchors;
    property Font;
    property Padding;
    property OptionsView: TACLTabsOptionsView read FOptionsView write SetOptionsView;
    property ResourceCollection;
    property Style: TACLStyleTabControl read FStyle write SetStyle;
    property Visible;
    //
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
    //
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
    //
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    FTab: TACLTab;

    procedure DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect); override;
    procedure SetParent(AParent: TWinControl); override;
    procedure UpdateTab;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //
    property Active: Boolean read GetActive;
    property PageControl: TACLPageControl read GetPageControl write SetPageControl;
  published
    property Caption;
    property Padding;
    property PageIndex: Integer read GetPageIndex write SetPageIndex stored False;
    property PageVisible: Boolean read FPageVisible write SetPageVisible default True;
    //
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
    //
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
  TabControlOffset = 2;

  sErrorWrongChild = 'Only %s can be placed on %s';
  sErrorWrongParent = '%s should be placed on %s';

{ TACLStyleTabControl }

procedure TACLStyleTabControl.Draw(ACanvas: TCanvas; const R: TRect; AActive: Boolean; AStyle: TACLTabsStyle);
begin
  HeaderTexture.Draw(ACanvas.Handle, R, Ord(AStyle) * 2 + Ord(AActive));
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
  inherited Create(Collection);
  FVisible := True;
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
  Rect := acRectInflate(FFrameRect, -1);
  Rect := acRectContent(Rect, Padding.GetScaledMargins(ScaleFactor));
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
    FTabAreaRect := CalculateTabArea;
    FFrameRect := ClientRect;
    FFrameRect.Top := FTabAreaRect.Bottom;
    CalculateTabStates;
    CalculateTabPlaces(TabAreaRect);
  end;
end;

function TACLCustomTabControl.CalculateTabArea: TRect;
begin
  Result := acRectSetHeight(ClientRect, GetTabHeight);
end;

function TACLCustomTabControl.CalculateTabPlaceIndents(AItem: TACLTabViewItem): TRect;
begin
  if AItem.Active then
  begin
    Result := Rect(
      -ScaleFactor.Apply(OptionsView.ActualTabIndent) - 1, 0,
      -ScaleFactor.Apply(OptionsView.ActualTabIndent) - 1, -2);
  end
  else
    Result := Rect(0, ScaleFactor.Apply(TabControlOffset), 0, 0);
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
  I: Integer;
begin
  ATabOffset := IfThen(OptionsView.Style = tsTab, ScaleFactor.Apply(OptionsView.ActualTabIndent) + 1);
  AIndentBetweenTabs := OptionsView.ActualTabIndent;

  ACalculator := TACLAutoSizeCalculator.Create;
  try
    ACalculator.Capacity := ViewItems.Count;
    ACalculator.AvailableSize := acRectWidth(R) - 2 * ATabOffset;
    for I := 0 to ViewItems.Count - 1 do
    begin
      if OptionsView.Style = tsTab then
        AWidth := CalculateTabWidth(ViewItems[I]) + IfThen(I + 1 < ViewItems.Count, AIndentBetweenTabs)
      else
        AWidth := 0;

      ACalculator.Add(AWidth, 1, AWidth, True);
    end;
    ACalculator.Calculate;

    Inc(ATabOffset, R.Left);
    for I := 0 to ViewItems.Count - 1 do
    begin
      AItem := ViewItems[I];
      AItem.Bounds := Bounds(ATabOffset, R.Top, ACalculator[I].Size, acRectHeight(R));
      if I + 1 < ViewItems.Count then
        Dec(AItem.Bounds.Right, AIndentBetweenTabs);
      ATabOffset := AItem.Bounds.Right + AIndentBetweenTabs;

      if OptionsView.Style = tsTab then
        AItem.Bounds := acRectContent(AItem.Bounds, CalculateTabPlaceIndents(AItem))
      else
        Dec(AItem.Bounds.Bottom, AIndentBetweenTabs);

      if AItem.Tab.Caption <> '' then
      begin
        if AItem.Active then
          MeasureCanvas.Font.Assign(Style.HeaderFontActive)
        else
          MeasureCanvas.Font.Assign(Style.HeaderFont);

        ATextSize := acTextSize(MeasureCanvas.Handle, AItem.Tab.Caption);
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
    Result := ScaleFactor.Apply(OptionsView.TabWidth)
  else
    Result := acMarginWidth(GetTabMargins) + CalculateTextSize(AItem.Tab.Caption).cx;
end;

procedure TACLCustomTabControl.CalculateTabStates;
var
  AViewItem: TACLTabViewItem;
  I: Integer;
begin
  for I := 0 to ViewItems.Count - 1 do
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
  Result := acSizeMax(Result, acTextSize(Canvas.Handle, ACaption));
  Canvas.Font.Assign(Style.HeaderFontActive);
  Result := acSizeMax(Result, acTextSize(Canvas.Handle, ACaption));
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
  acFillRect(ACanvas.Handle, FrameRect, Style.ColorContent.AsColor);
  acDrawComplexFrame(ACanvas.Handle, FrameRect, Style.ColorBorder1.AsColor, Style.ColorBorder2.AsColor);
end;

procedure TACLCustomTabControl.DrawItem(ACanvas: TCanvas; AViewItem: TACLTabViewItem);
begin
  Style.Draw(ACanvas, AViewItem.Bounds, AViewItem.Active, OptionsView.Style);
  if AViewItem.Active and Focused then
    acDrawFocusRect(ACanvas, acRectContent(AViewItem.Bounds, Style.HeaderTexture.ContentOffsets));
  DrawItemText(ACanvas, AViewItem);
end;

procedure TACLCustomTabControl.DrawItems(ACanvas: TCanvas);
var
  I: Integer;
begin
  for I := 0 to ViewItems.Count - 1 do
  begin
    if not ViewItems[I].Active then
      DrawItem(ACanvas, ViewItems[I]);
  end;
  for I := 0 to ViewItems.Count - 1 do
    if ViewItems[I].Active then
    begin
      DrawItem(ACanvas, ViewItems[I]);
      Break;
    end;
end;

procedure TACLCustomTabControl.DrawItemText(ACanvas: TCanvas; AViewItem: TACLTabViewItem);
begin
  if not acRectIsEmpty(AViewItem.TextRect) then
  begin
    if AViewItem.Active then
      ACanvas.Font.Assign(Style.HeaderFontActive)
    else
      ACanvas.Font.Assign(Style.HeaderFont);

    ACanvas.Brush.Style := bsClear;
    acTextDraw(ACanvas.Handle, AViewItem.Tab.Caption, AViewItem.TextRect, taLeftJustify, taAlignTop, True);
  end;
end;

procedure TACLCustomTabControl.DrawTransparentBackground(DC: HDC; const R: TRect);
var
  ASaveIndex: Integer;
begin
  ASaveIndex := SaveDC(DC);
  try
    if acIntersectClipRegion(DC, TabAreaRect) then
      inherited;
  finally
    RestoreDC(DC, ASaveIndex)
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
var
  I: Integer;
begin
  for I := 0 to ViewItems.Count - 1 do
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
  Result := acUIMouseWheelSwitchesTabs and PtInRect(TabAreaRect, ScreenToClient(MousePos));
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
  HoverTab := nil;
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
    HoverTab := AViewItem.Tab
  else
    HoverTab := nil;

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
      Inc(Result, OptionsView.ActualTabIndent)
    else
      Inc(Result, ScaleFactor.Apply(TabControlOffset));
  end;
end;

function TACLCustomTabControl.GetTabMargins: TRect;
begin
  if OptionsView.Style = tsHeader then
    Result := Rect(6, 6, 6, 6)
  else
    Result := Rect(4, 4, 4, 4);

  Result := ScaleFactor.Apply(Result);
end;

procedure TACLCustomTabControl.PopulateViewItems;
var
  I: Integer;
begin
  ViewItems.Clear;
  for I := 0 to Tabs.Count - 1 do
  begin
    if Tabs[I].Visible then
      ViewItems.Add(TACLTabViewItem.Create(Tabs[I]));
  end;
end;

procedure TACLCustomTabControl.SetActiveIndex(AValue: Integer);
begin
  if IsLoading then
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
    if not IsDesigning then
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
  FTabWidth := -1;
  FTabIndent := 3;
end;

procedure TACLTabsOptionsView.Assign(Source: TPersistent);
begin
  if Source is TACLTabsOptionsView then
  begin
    FStyle := TACLTabsOptionsView(Source).Style;
    FTabWidth := TACLTabsOptionsView(Source).TabWidth;
    FTabIndent := TACLTabsOptionsView(Source).TabIndent;
    Changed;
  end;
end;

procedure TACLTabsOptionsView.Changed;
begin
  FControl.FullRefresh;
end;

function TACLTabsOptionsView.GetActualTabIndent: Integer;
begin
  Result := FControl.ScaleFactor.Apply(TabIndent);
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
  if AValue <> FTabIndent then
  begin
    FTabIndent := AValue;
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
  if AValue <> nil then
    ActiveIndex := AValue.PageIndex
  else
    ActiveIndex := -1;
end;

{ TACLPageControlUIInsightAdapter }

class procedure TACLPageControlUIInsightAdapter.GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
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
