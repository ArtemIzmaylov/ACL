////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   TabControl/PageControl
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.TabControl;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Graphics,
  {Vcl.}Controls,
  {Vcl.}ImgList,
  {Vcl.}Forms,
  {Vcl.}Menus,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.SkinImage,
  ACL.Math,
  ACL.MUI,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.Buttons,
  ACL.UI.Insight,
  ACL.UI.Menus,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Desktop,
  ACL.Utils.Strings;

type
  TACLCustomTabControl = class;
  TACLPageControl = class;

  { TACLStyleTabControl }

  TACLTabsStyle = (tsTab, tsHeader, tsHeaderAlt);

  TACLStyleTabControl = class(TACLStyle)
  public const
    Offset = 2;
  protected
    procedure InitializeResources; override;
  public
    procedure DrawTab(ACanvas: TCanvas; const R: TRect; AActive: Boolean; AStyle: TACLTabsStyle);
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
    FCaption: string;
    FData: Pointer;
    FVisible: Boolean;

    procedure SetCaption(const AValue: string);
    procedure SetVisible(AValue: Boolean);
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    //# Properties
    property Data: Pointer read FData write FData;
  published
    property Caption: string read FCaption write SetCaption;
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
    function Add(const ACaption: string; AData: Pointer = nil): TACLTab; overload;
    function FindByCaption(const ACaption: string; out ATab: TACLTab): Boolean;
    //# Properties
    property Items[Index: Integer]: TACLTab read GetItem; default;
  end;

  { TACLTabViewItem }

  TACLTabViewItem = class
  public
    Active: Boolean;
    Bounds: TRect;
    FocusRect: TRect;
    Hover: Boolean;
    Tab: TACLTab;
    TextRect: TRect;
    TextSize: array[Boolean] of TSize;
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
  public const
    DefaultTabIndent = 3;
    DefaultTabPosition = tpTop;
    DefaultTabShrinkFactor = 80;
  strict private
    FControl: TACLCustomTabControl;
    FStyle: TACLTabsStyle;
    FTabIndent: Integer;
    FTabPosition: TACLTabsPosition;
    FTabShrinkFactor: Integer;
    FTabWidth: Integer;

    procedure SetStyle(AValue: TACLTabsStyle);
    procedure SetTabIndent(AValue: Integer);
    procedure SetTabPosition(AValue: TACLTabsPosition);
    procedure SetTabShrinkFactor(AValue: Integer);
    procedure SetTabWidth(AValue: Integer);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure Changed;
  public
    constructor Create(AControl: TACLCustomTabControl);
  published
    property Style: TACLTabsStyle read FStyle write SetStyle default tsTab;
    property TabIndent: Integer read FTabIndent write SetTabIndent default DefaultTabIndent;
    property TabPosition: TACLTabsPosition read FTabPosition write SetTabPosition default DefaultTabPosition;
    property TabShrinkFactor: Integer read FTabShrinkFactor write SetTabShrinkFactor default DefaultTabShrinkFactor;
    property TabWidth: Integer read FTabWidth write SetTabWidth default 0;
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
    FMoreButton: TACLButtonSubClass;
    FMoreMenu: TACLPopupMenu;
    FOptionsView: TACLTabsOptionsView;
    FStyle: TACLStyleTabControl;
    FStyleButton: TACLStyleButton;
    FTabs: TACLTabsList;
    FViewItems: TACLTabViewItemList;

    FOnTabChanging: TACLTabsActiveChangeEvent;
    FOnTabChanged: TACLTabsActiveChangeEvent;

    procedure SetActiveIndex(AValue: Integer);
    procedure SetBorders(AValue: TACLBorders);
    procedure SetHoverTab(AValue: TACLTab);
    procedure SetOptionsView(AValue: TACLTabsOptionsView);
    procedure SetStyle(AValue: TACLStyleTabControl);
    procedure SetStyleButton(AValue: TACLStyleButton);
    procedure SetTabs(AValue: TACLTabsList);

    procedure HandlerMenuClick(Sender: TObject);
    procedure HandlerMoreClick(Sender: TObject);
  protected
    FFrameRect: TRect;
    FTabAreaRect: TRect;

    procedure AdjustClientRect(var Rect: TRect); override;
    procedure BoundsChanged; override;
    function CreatePadding: TACLPadding; override;
    procedure CreateWnd; override;
    function IsTabVisible(AIndex: Integer): Boolean;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateTransparency; override;
    procedure ValidateActiveTab;
    procedure ValidateFocus;

    // Calculating
    function CalculateTabPlaceIndents(AItem: TACLTabViewItem): TRect; virtual;
    function CalculateTabTextOffsets(AItem: TACLTabViewItem): TRect; virtual;
    procedure Calculate;
    procedure CalculateCore; virtual;
    procedure CalculateTabsLayout(ARect: TRect); virtual;
    procedure CalculateTabStates; virtual;
    function GetTabHeight: Integer;
    function GetTabMargins: TRect; virtual;
    procedure PopulateViewItems; virtual;

    // Drawing
    procedure DrawContentAreaBackground(ACanvas: TCanvas); virtual;
    procedure DrawItem(ACanvas: TCanvas; AViewItem: TACLTabViewItem); virtual;
    procedure DrawItems(ACanvas: TCanvas); virtual;
    procedure DrawItemText(ACanvas: TCanvas; AViewItem: TACLTabViewItem); virtual;
    procedure Paint; override;

    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    // Mouse
    function IsMouseAtControl: Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    function MouseWheel(Direction: TACLMouseWheelDirection;
      Shift: TShiftState; const MousePos: TPoint): Boolean; override;

    procedure DoActiveIndexChanged; virtual;
    procedure DoActiveIndexChanging(ANewIndex: Integer); virtual;
    procedure DoLoaded; override;
    procedure FocusChanged; override;
    // Messages
    procedure CMChildKey(var Message: TCMChildKey); message CM_CHILDKEY;
    procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    //# Properties
    property MoreButton: TACLButtonSubClass read FMoreButton;
    property Tabs: TACLTabsList read FTabs write SetTabs;
    property ViewItems: TACLTabViewItemList read FViewItems;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function HitTest(X, Y: Integer; out AViewItem: TACLTabViewItem): Boolean;
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
    property StyleButton: TACLStyleButton read FStyleButton write SetStyleButton;
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
    procedure Localize(const ASection, AName: string); override;
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
    procedure Paint; override;
    procedure SetParent(AParent: TWinControl); override;
    procedure UpdateTab;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //# Properties
    property Active: Boolean read GetActive;
    property PageControl: TACLPageControl read GetPageControl write SetPageControl;
    property Tab: TACLTab read FTab; {nullable}
  published
    property Caption;
    property Padding;
    property PageIndex: Integer read GetPageIndex write SetPageIndex stored False;
    property PageVisible: Boolean read FPageVisible write SetPageVisible default True;
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
    procedure DoFullRefresh; override;
    procedure PageAdded(APage: TACLPageControlPage);
    procedure PageRemoving(APage: TACLPageControlPage);
    procedure ResourceChanged; override;
    procedure UpdatePagesVisibility;
    procedure ValidateInsert(AComponent: TComponent); override;
  public
    function AddPage(const ACaption: string): TACLPageControlPage;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure GetTabOrderList(List: TTabOrderList); override;
    procedure ShowControl(AControl: TControl); override;
    //# Properties
    property ActivePage: TACLPageControlPage read GetActivePage write SetActivePage;
    property PageCount: Integer read GetPageCount;
    property Pages[Index: Integer]: TACLPageControlPage read GetPages;
  end;

  { TACLPageControlUIInsightAdapter }

  TACLPageControlUIInsightAdapter = class(TACLUIInsightAdapterWinControl)
  public
    class procedure GetChildren(AObject: TObject;
      ABuilder: TACLUIInsightSearchQueueBuilder); override;
  end;

  { TACLPageControlPageUIInsightAdapter }

  TACLPageControlPageUIInsightAdapter = class(TACLUIInsightAdapterWinControl)
  public
    class function MakeVisible(AObject: TObject): Boolean; override;
  end;

var
  acUIMouseWheelSwitchesTabs: Boolean = True;

implementation

{$IFNDEF FPC}
uses
  ACL.Graphics.SkinImageSet;
{$ENDIF}

const
  sErrorWrongChild = 'Only %s can be placed on %s';
  sErrorWrongParent = '%s should be placed on %s';

{ TACLStyleTabControl }

procedure TACLStyleTabControl.DrawTab(ACanvas: TCanvas;
  const R: TRect; AActive: Boolean; AStyle: TACLTabsStyle);
var
  LIndex: Integer;
begin
  case AStyle of
    tsHeader:
      LIndex := IfThen(AActive, 3, 2);
    tsHeaderAlt:
      LIndex := IfThen(AActive, 1, 2);
  else
    LIndex := Ord(AActive);
  end;
  HeaderTexture.Draw(ACanvas, R, LIndex);
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

procedure TACLTab.SetCaption(const AValue: string);
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

function TACLTabsList.Add(const ACaption: string; AData: Pointer = nil): TACLTab;
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

function TACLTabsList.FindByCaption(const ACaption: string; out ATab: TACLTab): Boolean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
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
  if Item <> nil then
  begin
    FControl.Calculate;
    FControl.Invalidate;
  end
  else
    FControl.FullRefresh;
end;

{ TACLCustomTabControl }

constructor TACLCustomTabControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActiveIndex := -1;
  FBorders := acAllBorders;
  FTabs := TACLTabsList.Create(Self);
  FDefaultSize := TSize.Create(400, 300);
  FStyle := TACLStyleTabControl.Create(Self);
  FStyleButton := TACLStyleButton.Create(Self);
  FViewItems := TACLTabViewItemList.Create;
  FOptionsView := TACLTabsOptionsView.Create(Self);
  RegisterSubClass(FMoreButton, TACLButtonSubClass.Create(Self, StyleButton));
  FMoreButton.OnClick := HandlerMoreClick;
  FMoreButton.HasArrow := True;
  ControlStyle := ControlStyle + [csAcceptsControls];
  TabStop := True;
end;

destructor TACLCustomTabControl.Destroy;
begin
  FreeAndNil(FStyle);
  FreeAndNil(FStyleButton);
  FreeAndNil(FMoreMenu);
  FreeAndNil(FOptionsView);
  FreeAndNil(FViewItems);
  FreeAndNil(FTabs);
  inherited Destroy;
end;

procedure TACLCustomTabControl.AdjustClientRect(var Rect: TRect);
begin
  Rect := FFrameRect;
  Rect.Content(1, Borders);
  Rect.Content(Padding.GetScaledMargins(FCurrentPPI));
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
  Result := TACLPadding.Create(8);
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
    CalculateTabsLayout(FTabAreaRect);
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
    TACLMath.Exchange<Integer>(Result.Top, Result.Bottom);
end;

procedure TACLCustomTabControl.CalculateTabsLayout(ARect: TRect);
var
  I: Integer;
  LAutoWidth: Boolean;
  LButtonRect: TRect;
  LCalculator: TACLAutoSizeCalculator;
  LContentRect: TRect;
  LFixedWidth: Integer;
  LIndentBetweenTabs: Integer;
  LItem: TACLTabViewItem;
  LTabOffset: Integer;
  LTabMaxWidth: Integer;
  LTabs: Boolean;
  LTabWidth: Integer;
  LVisibleRange: TACLRange;
begin
{$REGION ' Metrics '}
  LTabs := OptionsView.Style = tsTab;
  LTabOffset := IfThen(LTabs, dpiApply(OptionsView.TabIndent, FCurrentPPI) + 1);
  LIndentBetweenTabs := dpiApply(OptionsView.TabIndent, FCurrentPPI);

  LAutoWidth := OptionsView.TabWidth <= 0;
  if LAutoWidth then
    LFixedWidth := GetTabMargins.MarginsWidth
  else
    LFixedWidth := dpiApply(OptionsView.TabWidth, FCurrentPPI);

  if not LTabs then
  begin
    if OptionsView.TabPosition = tpTop then
      Dec(ARect.Bottom, LIndentBetweenTabs)
    else
      Inc(ARect.Top, LIndentBetweenTabs);
  end;
{$ENDREGION}

  LCalculator := TACLAutoSizeCalculator.Create(ViewItems.Count);
  try
    LCalculator.AvailableSize := ARect.Width - 2 * LTabOffset - LIndentBetweenTabs * (ViewItems.Count - 1);

  {$REGION ' Measuring '}
    LTabMaxWidth := 0;
    for I := 0 to ViewItems.Count - 1 do
    begin
      LItem := ViewItems.List[I];
      LItem.TextSize[False] := Style.HeaderFont.MeasureSize(LItem.Tab.Caption);
      LItem.TextSize[True] := Style.HeaderFontActive.MeasureSize(LItem.Tab.Caption);
      LTabWidth := LFixedWidth;
      if LAutoWidth then
      begin
        Inc(LTabWidth, Max(LItem.TextSize[False].cx, LItem.TextSize[True].cx));
        LTabMaxWidth := Max(LTabMaxWidth, LTabWidth);
      end;
      LCalculator.Add(LTabWidth,
        MulDiv(LTabWidth, OptionsView.TabShrinkFactor, 100),
        IfThen(LTabs, LTabWidth), True);
    end;
    if LAutoWidth and not LTabs then
    begin
      if LTabMaxWidth * LCalculator.Count <= LCalculator.AvailableSize then
      begin
         for I := 0 to LCalculator.Count - 1 do
           LCalculator.Items[I].Size := LTabMaxWidth;
      end;
    end;
    LCalculator.Calculate;
  {$ENDREGION}

  {$REGION ' Overloading '}
    LVisibleRange := TACLRange.Create(0, LCalculator.Count - 1);
    if LCalculator.UsedSize > LCalculator.AvailableSize then
    begin
      LButtonRect := ARect.SplitRect(srRight, dpiApply(16, FCurrentPPI));
      if LTabs then
        LButtonRect.Inflate(0, -LIndentBetweenTabs);
      MoreButton.Calculate(LButtonRect);
      repeat
        LCalculator.AvailableSize := ARect.Width - 2 * LTabOffset -
          LIndentBetweenTabs * LVisibleRange.Length -
          LIndentBetweenTabs - MoreButton.Bounds.Width;
        if LVisibleRange.Length = 0 then
          Break;
        if LVisibleRange.Finish > ActiveIndex then
        begin
          LCalculator.Items[LVisibleRange.Finish].MinSize := 0;
          LCalculator.Items[LVisibleRange.Finish].MaxSize := 0;
          LCalculator.Items[LVisibleRange.Finish].Size := 0;
          Dec(LVisibleRange.Finish);
        end
        else
        begin
          LCalculator.Items[LVisibleRange.Start].MinSize := 0;
          LCalculator.Items[LVisibleRange.Start].MaxSize := 0;
          LCalculator.Items[LVisibleRange.Start].Size := 0;
          Inc(LVisibleRange.Start);
        end;
      until LCalculator.UsedSize <= LCalculator.AvailableSize;
      if LVisibleRange.Length = 0 then
        LCalculator.Items[LVisibleRange.Start].MinSize := 0;
      LCalculator.Calculate;
    end
    else
      MoreButton.Calculate(NullRect);
  {$ENDREGION}

  {$REGION ' Positioning '}
    Inc(LTabOffset, ARect.Left);
    for I := 0 to ViewItems.Count - 1 do
    begin
      LItem := ViewItems.List[I];
      LItem.Bounds := Bounds(LTabOffset, ARect.Top, LCalculator.Items[I].Size, ARect.Height);
      if not LItem.Bounds.IsEmpty then
      begin
        LTabOffset := LItem.Bounds.Right + LIndentBetweenTabs;
        if LTabs then
          LItem.Bounds.Content(CalculateTabPlaceIndents(LItem));
        if LItem.Tab.Caption <> '' then
        begin
          LContentRect := LItem.Bounds;
          LContentRect.Content(CalculateTabTextOffsets(LItem));
          LItem.TextRect := LContentRect;
          LItem.TextRect.Center(LItem.TextSize[LItem.Active]);
          LItem.TextTruncated := LItem.TextRect.Width > LContentRect.Width;
          LItem.TextRect.Intersect(LContentRect);
        end;
        if LItem.Active then
        begin
          LItem.FocusRect := LItem.Bounds.Split(Style.HeaderTexture.ContentOffsets);
          if OptionsView.Style = tsHeaderAlt then
          begin
            Inc(LItem.FocusRect.Bottom, LIndentBetweenTabs);
            Inc(LItem.Bounds.Bottom, LIndentBetweenTabs + 2);
          end;
        end;
      end;
    end;
  {$ENDREGION}
  finally
    LCalculator.Free;
  end;
end;

procedure TACLCustomTabControl.CalculateTabStates;
var
  LItem: TACLTabViewItem;
  I: Integer;
begin
  for I := 0 to ViewItems.Count - 1 do
  begin
    LItem := ViewItems.List[I];
    LItem.Active := ActiveIndex = LItem.Tab.Index;
    LItem.Hover := HoverTab = LItem.Tab;
  end;
end;

function TACLCustomTabControl.CalculateTabTextOffsets(AItem: TACLTabViewItem): TRect;
begin
  Result := GetTabMargins;
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
  acFillRect(ACanvas, FFrameRect, Style.ColorContent.AsColor);
  acDrawComplexFrame(ACanvas, FFrameRect,
    Style.ColorBorder1.AsColor, Style.ColorBorder2.AsColor, Borders);
end;

procedure TACLCustomTabControl.DrawItem(ACanvas: TCanvas; AViewItem: TACLTabViewItem);
var
  LDib: TACLDib;
begin
  if not AViewItem.Bounds.IsEmpty then
  begin
    if (OptionsView.Style = tsTab) and (OptionsView.TabPosition = tpBottom) then
    begin
      LDib := TACLDib.Create(AViewItem.Bounds);
      try
        acBitBlt(LDib.Handle, ACanvas.Handle, LDib.ClientRect, AViewItem.Bounds.TopLeft);
        Style.DrawTab(LDib.Canvas, LDib.ClientRect, AViewItem.Active, OptionsView.Style);
        LDib.Flip(False, True);
        LDib.DrawCopy(ACanvas, AViewItem.Bounds.TopLeft);
      finally
        LDib.Free;
      end;
    end
    else
      Style.DrawTab(ACanvas, AViewItem.Bounds, AViewItem.Active, OptionsView.Style);

    DrawItemText(ACanvas, AViewItem);
    if AViewItem.Active and Focused then
      acDrawFocusRect(ACanvas, AViewItem.FocusRect);
  end;
end;

procedure TACLCustomTabControl.DrawItems(ACanvas: TCanvas);
var
  I: Integer;
  LItem: TACLTabViewItem;
  LItemActive: TACLTabViewItem;
begin
  LItemActive := nil;
  for I := 0 to ViewItems.Count - 1 do
  begin
    LItem := ViewItems.List[I];
    if LItem.Active then
      LItemActive := LItem
    else
      DrawItem(ACanvas, LItem);
  end;
  if LItemActive <> nil then
    DrawItem(ACanvas, LItemActive);
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

procedure TACLCustomTabControl.HandlerMenuClick(Sender: TObject);
begin
  ActiveIndex := TMenuItem(Sender).Tag;
end;

procedure TACLCustomTabControl.HandlerMoreClick(Sender: TObject);
var
  LItem: TMenuItem;
  I: Integer;
begin
  if FMoreMenu = nil then
    FMoreMenu := TACLPopupMenu.Create(nil);
  FMoreMenu.Items.Clear;
  for I := 0 to Tabs.Count - 1 do
  begin
    LItem := FMoreMenu.Items.AddItem(Tabs[I].Caption, I, HandlerMenuClick);
    LItem.RadioItem := True;
    LItem.Default := I = ActiveIndex;
    LItem.Checked := I = ActiveIndex;
  end;
  FMoreMenu.PopupUnderControl(MoreButton.Bounds + ClientOrigin);
end;

function TACLCustomTabControl.HitTest(X, Y: Integer; out AViewItem: TACLTabViewItem): Boolean;
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

function TACLCustomTabControl.MouseWheel(Direction: TACLMouseWheelDirection;
  Shift: TShiftState; const MousePos: TPoint): Boolean;
begin
  Result := acUIMouseWheelSwitchesTabs and
    FTabAreaRect.Contains({$IFNDEF FPC}ScreenToClient{$ENDIF}(MousePos));
  if Result then
    ActiveIndex := ActiveIndex - TACLMouseWheel.DirectionToInteger[Direction];
end;

function TACLCustomTabControl.IsMouseAtControl: Boolean;
begin
  Result := HandleAllocated and (WindowFromPoint(MouseCursorPos) = Handle);
end;

procedure TACLCustomTabControl.MouseDown(
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LItem: TACLTabViewItem;
begin
  inherited;
  if HitTest(X, Y, LItem) then
  begin
    FIsUserAction := True;
    try
      ActiveIndex := LItem.Tab.Index;
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
var
  LItem: TACLTabViewItem;
begin
  inherited MouseMove(Shift, X, Y);

  if HitTest(X, Y, LItem) then
    SetHoverTab(LItem.Tab)
  else
    SetHoverTab(nil);

  if MoreButton.IsHovered or (HoverTab <> nil) and (HoverTab.Index <> ActiveIndex) then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
end;

procedure TACLCustomTabControl.Paint;
begin
  DrawContentAreaBackground(Canvas);
  DrawItems(Canvas);
  SubClasses.Draw(Canvas);
end;

procedure TACLCustomTabControl.FocusChanged;
begin
  inherited FocusChanged;
  InvalidateRect(FTabAreaRect);
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
  if (AForm <> nil) and acIsChildOrSelf(Self, AForm.ActiveControl) then
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

procedure TACLCustomTabControl.UpdateTransparency;
begin
  ControlStyle := ControlStyle - [csOpaque];
end;

function TACLCustomTabControl.GetTabHeight: Integer;
begin
  Result := 0;
  if ViewItems.Count > 0 then
  begin
    Result := GetTabMargins.MarginsHeight + Max(
      Style.HeaderFont.MeasureSize(acMeasureTextPattern).Height,
      Style.HeaderFontActive.MeasureSize(acMeasureTextPattern).Height);
    if OptionsView.Style = tsTab then
      Inc(Result, dpiApply(TACLStyleTabControl.Offset, FCurrentPPI))
    else
      Inc(Result, dpiApply(OptionsView.TabIndent, FCurrentPPI));
  end;
end;

function TACLCustomTabControl.GetTabMargins: TRect;
begin
  if OptionsView.Style = tsTab then
    Result := Rect(4, 4, 4, 4)
  else
    Result := Rect(6, 6, 6, 6);

  Result := dpiApply(Result, FCurrentPPI);
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
  if csLoading in ComponentState then
  begin
    FLoadedActiveIndex := AValue;
    Exit;
  end;

  AValue := MinMax(AValue, 0, Tabs.Count - 1);
  if AValue <> FActiveIndex then
  try
    DoActiveIndexChanging(AValue);
    FActiveIndex := AValue;
    FullRefresh; // first
    DoActiveIndexChanged;
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
    InvalidateRect(FTabAreaRect);
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

procedure TACLCustomTabControl.SetStyleButton(AValue: TACLStyleButton);
begin
  FStyleButton.Assign(AValue);
end;

procedure TACLCustomTabControl.SetTabs(AValue: TACLTabsList);
begin
  FTabs.Assign(AValue);
end;

procedure TACLCustomTabControl.CMChildKey(var Message: TCMChildKey);
var
  LShift: TShiftState;
begin
  case Message.CharCode of
    VK_PRIOR, VK_NEXT:
      if acIsShiftPressed([ssCtrl]) then
      begin
        FIsUserAction := True;
        try
          JumpToNextPage(Message.CharCode = VK_NEXT);
        finally
          FIsUserAction := False;
        end;
        Message.Result := 1;
      end;

    VK_TAB:
      begin
        LShift := acGetShiftState;
        if [ssCtrl, ssAlt] * LShift = [ssCtrl] then
        begin
          FIsUserAction := True;
          try
            JumpToNextPage(not (ssShift in LShift));
          finally
            FIsUserAction := False;
          end;
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
  FTabIndent := DefaultTabIndent;
  FTabPosition := DefaultTabPosition;
  FTabShrinkFactor := DefaultTabShrinkFactor;
end;

procedure TACLTabsOptionsView.AssignTo(Dest: TPersistent);
begin
  if Dest is TACLTabsOptionsView then
  begin
    TACLTabsOptionsView(Dest).FStyle := FStyle;
    TACLTabsOptionsView(Dest).FTabIndent := FTabIndent;
    TACLTabsOptionsView(Dest).FTabPosition := FTabPosition;
    TACLTabsOptionsView(Dest).FTabShrinkFactor := FTabShrinkFactor;
    TACLTabsOptionsView(Dest).FTabWidth := FTabWidth;
    TACLTabsOptionsView(Dest).Changed;
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

procedure TACLTabsOptionsView.SetTabShrinkFactor(AValue: Integer);
begin
  AValue := EnsureRange(AValue, 0, 100);
  if AValue <> FTabShrinkFactor then
  begin
    FTabShrinkFactor := AValue;
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

procedure TACLTabControl.Localize(const ASection, AName: string);
var
  LSection: string;
  I: Integer;
begin
  inherited;
  LSection := LangSubSection(ASection, AName);
  for I := 0 to Tabs.Count - 1 do
    Tabs[I].Caption := LangGet(LSection, 'i[' + IntToStr(I) + ']', Tabs[I].Caption);
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

procedure TACLPageControlPage.Paint;
begin
  if PageControl <> nil then
    acFillRect(Canvas, ClientRect, PageControl.Style.ColorContent.AsColor);
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

function TACLPageControl.AddPage(const ACaption: string): TACLPageControlPage;
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

procedure TACLPageControl.DoFullRefresh;
begin
  inherited;
  UpdatePagesVisibility;
end;

procedure TACLPageControl.PageAdded(APage: TACLPageControlPage);
begin
  APage.FTab := Tabs.Add('', APage);
  FullRefresh;
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

procedure TACLPageControl.ValidateInsert(AComponent: TComponent);
begin
  if (AComponent is TControl) and not (AComponent is TACLPageControlPage) then
    raise Exception.CreateFmt(sErrorWrongChild, [TACLPageControlPage.ClassName, ClassName]);
  inherited;
end;

procedure TACLPageControl.UpdatePagesVisibility;
var
  LActivePage: TACLPageControlPage;
  I: Integer;
begin
  if csDesigning in ComponentState then
  begin
    LActivePage := ActivePage;
    if LActivePage <> nil then
      LActivePage.BringToFront;
  end
  else
    if HandleAllocated then
    begin
      DisableAlign;
      try
        LActivePage := ActivePage;
        if LActivePage <> nil then
        begin
          LActivePage.Visible := False;
          LActivePage.BringToFront;
          LActivePage.Visible := True;
        end;
        for I := 0 to PageCount - 1 do
        begin
          if I <> ActiveIndex then
            Pages[I].Visible := False;
        end;
      finally
        EnableAlign;
      end;
    end;
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

procedure TACLPageControl.GetTabOrderList(List: TTabOrderList);
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
