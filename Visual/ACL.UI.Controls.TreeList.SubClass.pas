{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             TreeList Control              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.TreeList.SubClass;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}ActiveX,
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Generics.Defaults,
  {System.}Generics.Collections,
  {System.}Math,
  {System.}Types,
  {System.}SysUtils,
  System.UITypes,
  // Vcl
  {Vcl.}ImgList,
  {Vcl.}Controls,
  {Vcl.}StdCtrls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
  {Vcl.}Menus,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.Math,
  ACL.Threading,
  ACL.Threading.Sorting,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Controls.TreeList.Options,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.DropTarget,
  ACL.UI.HintWindow,
  ACL.UI.ImageList,
  ACL.UI.Menus,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

const
  // HitTest codes
  tlhtImage = cchtLast + 1;
  tlhtText = tlhtImage + 1;

  tlhtLast = tlhtText + 1;

type
  TACLTreeListSubClass = class;
  TACLTreeListColumnBarViewInfo = class;
  TACLTreeListColumnViewInfo = class;
  TACLTreeListContentCell = class;
  TACLTreeListContentCellViewInfo = class;
  TACLTreeListContentViewInfo = class;
  TACLTreeListDragAndDropController = class;
  TACLTreeListNodeViewInfo = class;

  TACLTreeListDropTargetInsertMode = (dtimBefore, dtimAfter, dtimInto, dtimOver);

  { TACLStyleTreeList }

  TACLStyleTreeList = class(TACLStyle)
  public const
    IndexColumnHeaderFont = 0;
    IndexGroupHeaderFont = 1;
  strict private
    function GetRowColor(Odd: Boolean): TAlphaColor;
    function GetRowColorSelected(Focused: Boolean): TAlphaColor;
    function GetRowColorSelectedText(Focused: Boolean): TColor;
    function GetRowColorText(Enabled: Boolean): TColor;
  protected
    procedure InitializeResources; override;
  public
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect; AEnabled: Boolean; ABorders: TACLBorders);
    procedure DrawCheckMark(ACanvas: TCanvas; const R: TRect; AState: TACLButtonState; ACheckBoxState: TCheckBoxState);
    procedure DrawGridline(ACanvas: TCanvas; const R: TRect; ASide: TACLBorder);
    procedure DrawGroupExpandButton(ACanvas: TCanvas; const R: TRect; AExpanded: Boolean);
    procedure DrawGroupHeader(ACanvas: TCanvas; const R: TRect; ABorders: TACLBorders = [mTop, mBottom]);
    procedure DrawHeader(ACanvas: TCanvas; const R: TRect; ABorders: TACLBorders);
    procedure DrawHeaderSortingArrow(ACanvas: TCanvas; const R: TRect; ADirection, AEnabled: Boolean);
    procedure DrawRowExpandButton(ACanvas: TCanvas; const R: TRect; AExpanded, ASelected: Boolean);
    //
    property RowColors[Odd: Boolean]: TAlphaColor read GetRowColor;
    property RowColorsSelected[Focused: Boolean]: TAlphaColor read GetRowColorSelected;
    property RowColorsSelectedText[Focused: Boolean]: TColor read GetRowColorSelectedText;
    property RowColorsText[Enabled: Boolean]: TColor read GetRowColorText;
  published
    property CheckMark: TACLResourceTexture index 0 read GetTexture write SetTexture stored IsTextureStored;
    property BorderColor: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property BackgroundColor: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property BackgroundColorDisabled: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property FocusRectColor: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
    property GridColor: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
    property IncSearchColor: TACLResourceColor index 5 read GetColor write SetColor stored IsColorStored;
    property IncSearchColorText: TACLResourceColor index 6 read GetColor write SetColor stored IsColorStored;
    property SelectionRectColor: TACLResourceColor index 7 read GetColor write SetColor stored IsColorStored;

    property ColumnHeader: TACLResourceTexture index 1 read GetTexture write SetTexture stored IsTextureStored;
    property ColumnHeaderFont: TACLResourceFont index IndexColumnHeaderFont read GetFont write SetFont stored IsFontStored;
    property ColumnHeaderSortingArrow: TACLResourceTexture index 2 read GetTexture write SetTexture stored IsTextureStored;

    property GroupHeaderColor: TACLResourceColor index 8 read GetColor write SetColor stored IsColorStored;
    property GroupHeaderColorBorder: TACLResourceColor index 9 read GetColor write SetColor stored IsColorStored;
    property GroupHeaderContentOffsets: TACLResourceMargins index 0 read GetMargins write SetMargins stored IsMarginsStored;
    property GroupHeaderExpandButton: TACLResourceTexture index 3 read GetTexture write SetTexture stored IsTextureStored;
    property GroupHeaderFont: TACLResourceFont index IndexGroupHeaderFont read GetFont write SetFont stored IsFontStored;

    property RowColor1: TACLResourceColor index 10 read GetColor write SetColor stored IsColorStored;
    property RowColor2: TACLResourceColor index 11 read GetColor write SetColor stored IsColorStored;
    property RowColorFocused: TACLResourceColor index 12 read GetColor write SetColor stored IsColorStored;
    property RowColorFocusedText: TACLResourceColor index 13 read GetColor write SetColor stored IsColorStored;
    property RowColorHovered: TACLResourceColor index 14 read GetColor write SetColor stored IsColorStored;
    property RowColorHoveredText: TACLResourceColor index 15 read GetColor write SetColor stored IsColorStored;
    property RowColorSelected: TACLResourceColor index 16 read GetColor write SetColor stored IsColorStored;
    property RowColorSelectedInactive: TACLResourceColor index 17 read GetColor write SetColor stored IsColorStored;
    property RowColorSelectedText: TACLResourceColor index 18 read GetColor write SetColor stored IsColorStored;
    property RowColorSelectedTextInactive: TACLResourceColor index 19 read GetColor write SetColor stored IsColorStored;
    property RowColorDisabledText: TACLResourceColor index 20 read GetColor write SetColor stored IsColorStored;
    property RowColorText: TACLResourceColor index 21 read GetColor write SetColor stored IsColorStored;
    property RowContentOffsets: TACLResourceMargins index 1 read GetMargins write SetMargins stored IsMarginsStored;
    property RowExpandButton: TACLResourceTexture index 4 read GetTexture write SetTexture stored IsTextureStored;
  end;

  { TACLTreeListCustomViewInfo }

  TACLTreeListCustomViewInfo = class(TACLCompoundControlCustomViewInfo)
  strict private
    function GetSubClass: TACLTreeListSubClass; inline;
  public
    property SubClass: TACLTreeListSubClass read GetSubClass;
  end;

  { TACLTreeListColumnViewInfo }

  TACLTreeListColumnViewInfo = class(TACLTreeListCustomViewInfo,
    IACLHotTrackObject,
    IACLDraggableObject)
  strict private
    FActualWidth: Integer;
    FCheckState: TCheckBoxState;
    FSortArrowIndexSize: TSize;

    function CanResize: Boolean;
    function GetCheckBoxState: TACLButtonState;
    function GetColumnBarViewInfo: TACLTreeListColumnBarViewInfo; inline;
    function GetIsFirst: Boolean;
    function GetIsLast: Boolean;
    function GetIsMultiColumnSorting: Boolean;
    function GetNodeViewInfo: TACLTreeListNodeViewInfo; inline;
    function GetOptionsColumns: TACLTreeListOptionsViewColumns; inline;
    function GetSortArrowIndexSize: TSize;
    procedure SetSortByIndex(AValue: Integer);
  protected
    FAbsoluteIndex: Integer;
    FBorders: TACLBorders;
    FBounds: TRect;
    FCheckBoxRect: TRect;
    FColumn: TACLTreeListColumn;
    FImageRect: TRect;
    FSortArrowIndexRect: TRect;
    FSortArrowRect: TRect;
    FSortByIndex: Integer;
    FTextRect: TRect;
    FVisibleIndex: Integer;

    procedure CalculateContentRects(R: TRect); virtual;
    procedure CalculateCheckBox(var R: TRect); virtual;
    procedure CalculateImageRect(var R: TRect; AHasText: Boolean); virtual;
    procedure CalculateSortArea(var R: TRect); virtual;
    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure DoDrawSortMark(ACanvas: TCanvas); virtual;
    procedure InitializeActualWidth; virtual;
    // IACLHotTrackObject
    procedure OnHotTrack(Action: TACLHotTrackAction);
    //
    property ColumnBarViewInfo: TACLTreeListColumnBarViewInfo read GetColumnBarViewInfo;
    property NodeViewInfo: TACLTreeListNodeViewInfo read GetNodeViewInfo;
    property OptionsColumns: TACLTreeListOptionsViewColumns read GetOptionsColumns;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass; AColumn: TACLTreeListColumn); reintroduce; virtual;
    function CalculateAutoWidth: Integer; virtual;
    function CalculateBestFit: Integer; virtual;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; override;
    // IACLDraggableObject
    function CreateDragObject(const AHitTest: TACLHitTestInfo): TACLCompoundControlDragObject;
    //
    property AbsoluteIndex: Integer read FAbsoluteIndex;
    property ActualWidth: Integer read FActualWidth write FActualWidth;
    property Borders: TACLBorders read FBorders;
    property CheckBoxRect: TRect read FCheckBoxRect;
    property CheckBoxState: TACLButtonState read GetCheckBoxState;
    property CheckState: TCheckBoxState read FCheckState;
    property Column: TACLTreeListColumn read FColumn;
    property ImageRect: TRect read FImageRect;
    property SortArrowIndexRect: TRect read FSortArrowIndexRect;
    property SortArrowIndexSize: TSize read GetSortArrowIndexSize;
    property SortArrowRect: TRect read FSortArrowRect;
    property SortByIndex: Integer read FSortByIndex write SetSortByIndex;
    property TextRect: TRect read FTextRect;
    property VisibleIndex: Integer read FVisibleIndex;
    //
    property IsFirst: Boolean read GetIsFirst;
    property IsLast: Boolean read GetIsLast;
    property IsMultiColumnSorting: Boolean read GetIsMultiColumnSorting;
  end;

  { TACLTreeListColumnBarViewInfo }

  TACLTreeListColumnBarViewInfo = class(TACLCompoundControlContainerViewInfo)
  strict private
    function GetChild(Index: Integer): TACLTreeListColumnViewInfo; inline;
    function GetFreeSpaceArea: TRect;
    function GetResizableColumnsList: TList;
    function GetSubClass: TACLTreeListSubClass; inline;
  protected
    function AddColumnCell(AColumn: TACLTreeListColumn): TACLTreeListColumnViewInfo;
    function CreateColumnViewInfo(AColumn: TACLTreeListColumn): TACLTreeListColumnViewInfo; virtual;
    //
    function CalculateAutoHeight: Integer; virtual;
    procedure CalculateAutoWidth(const R: TRect); virtual;
    procedure CalculateChildren(R: TRect; const AChanges: TIntegerSet); virtual;
    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure RecreateSubCells; override;
    //
    property FreeSpaceArea: TRect read GetFreeSpaceArea;
  public
    function GetColumnViewInfo(AColumn: TACLTreeListColumn; out AViewInfo: TACLTreeListColumnViewInfo): Boolean;
    function MeasureHeight: Integer; virtual;
    function MeasureWidth: Integer; virtual;
    //
    property Children[Index: Integer]: TACLTreeListColumnViewInfo read GetChild;
    property SubClass: TACLTreeListSubClass read GetSubClass;
  end;

  { TACLTreeListContentCell }

  TACLTreeListContentCell = class(TACLCompoundControlBaseContentCell, IACLHotTrackObject)
  protected
    // IACLHotTrackObject
    procedure OnHotTrack(Action: TACLHotTrackAction);
  end;

  { TACLTreeListContentCellViewInfo }

  TACLTreeListContentCellViewInfo = class(TACLCompoundControlBaseCheckableContentCellViewInfo)
  strict private
    FOwner: TACLTreeListContentViewInfo;
    FSubClass: TACLTreeListSubClass;
  protected
    function GetFocusRectColor: TColor; override;
  public
    constructor Create(AOwner: TACLTreeListContentViewInfo);
    function IsFocused: Boolean;
    //
    property Owner: TACLTreeListContentViewInfo read FOwner;
    property SubClass: TACLTreeListSubClass read FSubClass;
  end;

  { TACLTreeListGroupViewInfo }

  TACLTreeListGroupViewInfo = class(TACLTreeListContentCellViewInfo, IACLDraggableObject)
  strict private
    function GetCheckBoxState: TACLButtonState;
    function GetGroup: TACLTreeListGroup; inline;
  protected
    FBackgroundBounds: TRect;
    FTextRect: TRect;

    procedure CalculateCheckBox(var R: TRect); virtual;
    procedure CalculateExpandButton(var R: TRect); virtual;
    procedure DoDraw(ACanvas: TCanvas); override;
    function GetContentOffsets: TRect; virtual;
    function GetFocusRect: TRect; override;
    function HasFocusRect: Boolean; override;

    // IACLDraggableObject
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
  public
    procedure Calculate(AWidth, AHeight: Integer); override;
    function CalculateAutoHeight: Integer; virtual;
    procedure Initialize(AData: TObject); override;
    //
    property BackgroundBounds: TRect read FBackgroundBounds;
    property CheckBoxState: TACLButtonState read GetCheckBoxState;
    property Group: TACLTreeListGroup read GetGroup;
    property TextRect: TRect read FTextRect;
  end;

  { TACLTreeListNodeViewInfo }

  TACLTreeListNodeViewInfo = class(TACLTreeListContentCellViewInfo, IACLDraggableObject)
  strict private
    function GetAbsoluteNodeIndex: Integer;
    function GetCellColumnViewInfo(Index: Integer): TACLTreeListColumnViewInfo;
    function GetCellCount: Integer;
    function GetCellRect(AIndex: Integer): TRect; overload;
    function GetCellRect(AViewInfo: TACLTreeListColumnViewInfo): TRect; overload;
    function GetCheckBoxState: TACLButtonState;
    function GetColumnBarViewInfo: TACLTreeListColumnBarViewInfo; inline;
    function GetColumnForViewInfo(AColumnViewInfo: TACLTreeListColumnViewInfo): TACLTreeListColumn; inline;
    function GetNode: TACLTreeListNode; inline;
    function GetOptionsNodes: TACLTreeListOptionsViewNodes; inline;

    function IsFirstColumn(AColumnViewInfo: TACLTreeListColumnViewInfo): Boolean; inline;
    function PlaceLeftAlignedElement(ASize: TSize; AVisible: Boolean): TRect;
    procedure SetLevel(AValue: Integer);
  protected
    FAbsoluteNodeIndex: Integer;
    FHasHorzSeparators: Boolean;
    FHasVertSeparators: Boolean;
    FImageRect: TRect;
    FLevel: Integer;
    FTextExtends: array[Boolean] of TRect;

    procedure CalculateCheckBoxRect; virtual;
    procedure CalculateExpandButtonRect; virtual;
    procedure CalculateImageRect; virtual;
    procedure DoGetHitTest(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo); override;
    procedure DoGetHitTestSubPart(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo; ACellTextWidth: Integer;
      const ACellRect, ACellTextRect: TRect; AColumnViewInfo: TACLTreeListColumnViewInfo); virtual;
    function GetBottomSeparatorRect: TRect; inline;
    function GetCellTextExtends(AColumn: TACLTreeListColumnViewInfo): TRect; virtual;
    function GetColumnAbsoluteIndex(AColumnViewInfo: TACLTreeListColumnViewInfo): Integer; inline;
    function GetContentOffsets: TRect; virtual;
    function GetFocusRect: TRect; override;
    function HasFocusRect: Boolean; override;
    function IsCheckBoxEnabled: Boolean; override;

    function DoCustomDraw(ACanvas: TCanvas): Boolean;
    function DoCustomDrawCell(ACanvas: TCanvas; const R: TRect; AColumn: TACLTreeListColumn): Boolean;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure DoDrawCell(ACanvas: TCanvas; const R: TRect; AColumnViewInfo: TACLTreeListColumnViewInfo);
    procedure DoDrawCellContent(ACanvas: TCanvas; const R: TRect; AColumnViewInfo: TACLTreeListColumnViewInfo); virtual;
    procedure DoDrawCellImage(ACanvas: TCanvas; const ABounds: TRect); virtual;
    procedure DoDrawCellValue(ACanvas: TCanvas; const ABounds: TRect;
      const AValue: string; AValueIndex: Integer; AAlignment: TAlignment); virtual;

    // IACLDraggableObject
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject;

    property AbsoluteNodeIndex: Integer read GetAbsoluteNodeIndex;
    property CheckBoxState: TACLButtonState read GetCheckBoxState;
    property ColumnBarViewInfo: TACLTreeListColumnBarViewInfo read GetColumnBarViewInfo;
    property Level: Integer read FLevel write SetLevel;
    property Node: TACLTreeListNode read GetNode;
  public
    procedure Calculate(AWidth, AHeight: Integer); override;
    function CalculateAutoHeight: Integer; virtual;
    function CalculateCellAutoWidth(ACanvas: TCanvas; ANode: TACLTreeListNode;
      AColumnIndex: Integer; AColumnViewInfo: TACLTreeListColumnViewInfo = nil): Integer; overload; virtual;
    function CalculateCellAutoWidth(ANode: TACLTreeListNode; AColumn: TACLTreeListColumn): Integer; overload;
    function CalculateCellAutoWidth(ANodes: TACLTreeListNodeList; AColumn: TACLTreeListColumn): Integer; overload;
    function CalculateCellAutoWidth(ANodes: TACLTreeListNodeList; AColumnIndex: Integer;
      AColumnViewInfo: TACLTreeListColumnViewInfo = nil): Integer; overload;
    function GetCellIndexAtPoint(const P: TPoint; out ACellIndex: Integer): Boolean;
    procedure Initialize(AData: TObject); override;
    procedure Initialize(AData: TObject; AHeight: Integer); override;
    function MeasureHeight: Integer; override;
    //
    property CellColumnViewInfo[Index: Integer]: TACLTreeListColumnViewInfo read GetCellColumnViewInfo;
    property CellCount: Integer read GetCellCount;
    property CellRect[Index: Integer]: TRect read GetCellRect;
    property CellTextExtends[AColumn: TACLTreeListColumnViewInfo]: TRect read GetCellTextExtends;
    property HasHorzSeparators: Boolean read FHasHorzSeparators;
    property HasVertSeparators: Boolean read FHasVertSeparators;
    property ImageRect: TRect read FImageRect;
    property OptionsNodes: TACLTreeListOptionsViewNodes read GetOptionsNodes;
  end;

  { TACLTreeListDropTargetViewInfo }

  TACLTreeListDropTargetViewInfo = class
  strict private
    FOwner: TACLTreeListContentViewInfo;

    function GetDragAndDropController: TACLTreeListDragAndDropController;
    function GetDropTargetObject: TObject;
  protected
    FBounds: TRect;
    FInsertMode: TACLTreeListDropTargetInsertMode;

    function CalculateActualTargetObject: TObject;
    procedure CalculateBounds(const ACellBounds: TRect); virtual;
    function MeasureHeight: Integer; virtual;
  public
    constructor Create(AOwner: TACLTreeListContentViewInfo);
    procedure Calculate; virtual;
    procedure Draw(ACanvas: TCanvas); virtual;
    procedure Invalidate;
    //
    property Bounds: TRect read FBounds;
    property DragAndDropController: TACLTreeListDragAndDropController read GetDragAndDropController;
    property DropTargetObject: TObject read GetDropTargetObject;
    property Owner: TACLTreeListContentViewInfo read FOwner;
  end;

  { TACLTreeListContentViewInfo }

  TACLTreeListContentViewInfo = class(TACLCompoundControlScrollContainerViewInfo,
    IACLDraggableObject,
    IACLCompoundControlSubClassContent)
  strict private
    FAbsoluteVisibleNodes: TACLTreeListNodeList;
    FColumnBarViewInfo: TACLTreeListColumnBarViewInfo;
    FDropTargetViewInfo: TACLTreeListDropTargetViewInfo;
    FGroupViewInfo: TACLTreeListGroupViewInfo;
    FLockViewItemsPlacement: Integer;
    FMeasuredGroupHeight: Integer;
    FMeasuredNodeHeight: Integer;
    FNodeViewInfo: TACLTreeListNodeViewInfo;
    FSelectionRect: TRect;
    FViewItems: TACLCompoundControlContentCellList;

    function GetFirstVisibleNode: TACLTreeListNode;
    function GetLastVisibleNode: TACLTreeListNode;
    function GetOptionsBehavior: TACLTreeListOptionsBehavior;
    function GetOptionsView: TACLTreeListOptionsView; inline;
    function GetSubClass: TACLTreeListSubClass; inline;
    procedure SetSelectionRect(const AValue: TRect);
  protected
    FHasSubLevels: Boolean;

    // Calculation
    procedure CalculateContentCellViewInfo; virtual;
    procedure CalculateContentLayout; override;
    function CalculateHasSubLevels: Boolean; virtual;
    procedure CalculateSubCells(const AChanges: TIntegerSet); override;
    procedure CalculateViewItemsPlace; virtual;
    procedure DoCalculate(AChanges: TIntegerSet); override;
    function GetColumnBarBounds: TRect; virtual;
    function GetLevelIndent: Integer;
    function MeasureContentWidth: Integer; virtual;

    // SubCells ViewInfos
    function CreateColumnBarViewInfo: TACLTreeListColumnBarViewInfo; virtual;
    function CreateDropTargetViewInfo: TACLTreeListDropTargetViewInfo; virtual;
    function CreateGroupViewInfo: TACLTreeListGroupViewInfo; virtual;
    function CreateNodeViewInfo: TACLTreeListNodeViewInfo; virtual;
    function CreateViewItems: TACLCompoundControlContentCellList; virtual;

    function GetLineDownOffset: Integer; virtual;
    function GetLineUpOffset: Integer; virtual;
    function GetScrollInfo(AKind: TScrollBarKind; out AInfo: TACLScrollInfo): Boolean; override;
    procedure PopulateViewItems(ANode: TACLTreeListNode); virtual;
    procedure RecreateSubCells; override;

    // IACLDraggableObject
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject; virtual;

    // IACLTreeListSubClassContent
    function GetContentWidth: Integer;
    function GetViewItemsArea: TRect;
    function GetViewItemsOrigin: TPoint;

    // Drawing
    procedure DoDrawCells(ACanvas: TCanvas); override;
    procedure DoDrawFreeSpaceBackground(ACanvas: TCanvas); virtual;
    procedure DoDrawSelectionRect(ACanvas: TCanvas; const R: TRect); virtual;
  public
    constructor Create(AOwner: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; override;
    function CalculateScrollDelta(AObject: TObject; AMode: TACLScrollToMode;
      out ADelta: TPoint; AColumn: TACLTreeListColumn = nil): Boolean;
    function CalculateScrollDeltaCore(ACell: TACLCompoundControlBaseContentCell;
      AMode: TACLScrollToMode; const AArea: TRect; AColumn: TACLTreeListColumnViewInfo = nil): TPoint; virtual;
    function FindNearestNode(const P: TPoint; ADirection: Integer): TACLTreeListNode;
    function IsObjectVisible(AObject: TObject; AColumn: TACLTreeListColumn = nil): Boolean;
    procedure ScrollByLines(ALines: Integer; ADirection: TACLMouseWheelDirection);
    // Actual Heights
    function GetActualColumnBarHeight: Integer; virtual;
    function GetActualGroupHeight: Integer; virtual;
    function GetActualNodeHeight: Integer; virtual;
    //
    procedure LockViewItemsPlacement;
    procedure UnlockViewItemsPlacement;
    //
    property ColumnBarViewInfo: TACLTreeListColumnBarViewInfo read FColumnBarViewInfo;
    property DropTargetViewInfo: TACLTreeListDropTargetViewInfo read FDropTargetViewInfo;
    property GroupViewInfo: TACLTreeListGroupViewInfo read FGroupViewInfo;
    property NodeViewInfo: TACLTreeListNodeViewInfo read FNodeViewInfo;
    //
    property AbsoluteVisibleNodes: TACLTreeListNodeList read FAbsoluteVisibleNodes;
    property FirstVisibleNode: TACLTreeListNode read GetFirstVisibleNode;
    property HasSubLevels: Boolean read FHasSubLevels;
    property LastVisibleNode: TACLTreeListNode read GetLastVisibleNode;
    property SelectionRect: TRect read FSelectionRect write SetSelectionRect;
    property ViewItems: TACLCompoundControlContentCellList read FViewItems;
    property ViewItemsArea: TRect read GetViewItemsArea;
    property ViewItemsOrigin: TPoint read GetViewItemsOrigin;
    //
    property OptionsBehavior: TACLTreeListOptionsBehavior read GetOptionsBehavior;
    property OptionsView: TACLTreeListOptionsView read GetOptionsView;
    property SubClass: TACLTreeListSubClass read GetSubClass;
  end;

  { TACLTreeListViewInfo }

  TACLTreeListViewInfo = class(TACLTreeListCustomViewInfo)
  strict private
    FContent: TACLTreeListContentViewInfo;

    function GetBorders: TACLBorders;
    function GetBorderWidths: TRect;
  protected
    function CreateContent: TACLTreeListContentViewInfo; virtual;
    function GetContentBounds: TRect; virtual;
    //
    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoDraw(ACanvas: TCanvas); override;
  public
    constructor Create(AOwner: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; override;
    //
    property Borders: TACLBorders read GetBorders;
    property BorderWidths: TRect read GetBorderWidths;
    property Content: TACLTreeListContentViewInfo read FContent;
  end;

  { TACLTreeListHitTest }

  TACLTreeListHitTest = class(TACLHitTestInfo)
  strict private
    function GetColumn: TACLTreeListColumn;
    function GetColumnViewInfo: TACLTreeListColumnViewInfo;
    function GetGroup: TACLTreeListGroup;
    function GetHitAtColumn: Boolean;
    function GetHitAtColumnBar: Boolean;
    function GetHitAtContentArea: Boolean;
    function GetHitAtGroup: Boolean;
    function GetHitAtNode: Boolean;
    function GetNode: TACLTreeListNode;
    procedure SetColumn(const Value: TACLTreeListColumn);
    procedure SetColumnViewInfo(AViewInfo: TACLTreeListColumnViewInfo);
  public
    function HasAction: Boolean; virtual;

    property HitAtColumn: Boolean read GetHitAtColumn;
    property HitAtColumnBar: Boolean read GetHitAtColumnBar;
    property HitAtContentArea: Boolean read GetHitAtContentArea;
    property HitAtGroup: Boolean read GetHitAtGroup;
    property HitAtNode: Boolean read GetHitAtNode;

    property Column: TACLTreeListColumn read GetColumn write SetColumn;
    property ColumnViewInfo: TACLTreeListColumnViewInfo read GetColumnViewInfo write SetColumnViewInfo;
    property Group: TACLTreeListGroup read GetGroup;
    property Node: TACLTreeListNode read GetNode;

    property IsImage: Boolean index tlhtImage read GetHitObjectFlag write SetHitObjectFlag;
    property IsText: Boolean index tlhtText read GetHitObjectFlag write SetHitObjectFlag;
  end;

  { TACLTreeListEditingController }

  TACLTreeListEditingController = class(TACLCompoundControlPersistent)
  strict private
    FEdit: TComponent;
    FEditIntf: IACLInplaceControl;
    FLockCount: Integer;
    FParams: TACLInplaceInfo;

    procedure InitializeParams(ANode: TACLTreeListNode; AColumn: TACLTreeListColumn = nil);
    function GetContentViewInfo: TACLTreeListContentViewInfo; inline;
    function GetSubClass: TACLTreeListSubClass; inline;
    function GetValue: string;
    procedure SetValue(const AValue: string);
  protected
    procedure Close(AChanges: TIntegerSet = []; AAccepted: Boolean = False);
    procedure EditApplyHandler(Sender: TObject); virtual;
    procedure EditCancelHandler(Sender: TObject); virtual;
    procedure EditKeyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState); virtual;
    //# Properties
    property ContentViewInfo: TACLTreeListContentViewInfo read GetContentViewInfo;
    property Value: string read GetValue write SetValue;
  public
    destructor Destroy; override;
    //# States
    function IsEditing: Boolean; overload;
    function IsEditing(AItemIndex, AColumnIndex: Integer): Boolean; overload;
    function IsEditing(ANode: TACLTreeListNode; AColumn: TACLTreeListColumn = nil): Boolean; overload;
    function IsLocked: Boolean;
    function IsModified: Boolean;
    //# Actions
    procedure Apply;
    procedure Cancel;
    procedure StartEditing(ANode: TACLTreeListNode; AColumn: TACLTreeListColumn = nil);
    //# Properties
    property ColumnIndex: Integer read FParams.ColumnIndex;
    property Edit: TComponent read FEdit;
    property EditIntf: IACLInplaceControl read FEditIntf;
    property RowIndex: Integer read FParams.RowIndex;
    property SubClass: TACLTreeListSubClass read GetSubClass;
  end;

  { TACLTreeListDragAndDropController }

  TACLTreeListDragAndDropController = class(TACLCompoundControlDragAndDropController)
  strict private
    FDropTarget: TACLDropTarget;
    FDropTargetObject: TObject;
    FDropTargetObjectInsertMode: TACLTreeListDropTargetInsertMode;

    function GetDropTargetViewInfo: TACLTreeListDropTargetViewInfo;
    function GetSubClass: TACLTreeListSubClass;
  protected
    function CreateDefaultDropTarget: TACLDropTarget; override;
  public
    destructor Destroy; override;
    procedure ProcessChanges(AChanges: TIntegerSet); override;
    function UpdateDropInfo(AObject: TObject; AMode: TACLTreeListDropTargetInsertMode): Boolean;

    property DropTargetObject: TObject read FDropTargetObject;
    property DropTargetObjectInsertMode: TACLTreeListDropTargetInsertMode read FDropTargetObjectInsertMode;
    property DropTargetViewInfo: TACLTreeListDropTargetViewInfo read GetDropTargetViewInfo;
    property SubClass: TACLTreeListSubClass read GetSubClass;
  end;

  { TACLTreeListHintController }

  TACLTreeListHintController = class(TACLCompoundControlHintController)
  protected
    function CanShowHint(AHintOwner: TObject; const AHintData: TACLHintData): Boolean; override;
  end;

  { TACLTreeListSortByList }

  TACLTreeListSortByList = class(TACLTreeListColumnList)
  protected
    procedure Notify(const Item: TACLTreeListColumn; Action: TCollectionNotification); override;
  end;

  { TACLTreeListSorter }

  TACLTreeListSorter = class(TACLUnknownObject)
  strict private
    FGroupBy: TACLTreeListColumnList;
    FSortBy: TACLTreeListSortByList;
    FSubClass: TACLTreeListSubClass;

    function GetGroups: TACLTreeListGroups; inline;
    function GetRootNode: TACLTreeListNode; inline;
  protected
    // Groupping
    function GetGroupName(ANode: TACLTreeListNode): string;
    function IsCustomGroupping: Boolean;
    function IsGroupMode: Boolean;
    procedure ReorderNodesByGroupsPosition;
    procedure UpdateGroups;
    procedure UpdateGroupsLinksOrder;

    // Sorting
    function AreSortingParametersDefined: Boolean; virtual;
    function Compare(const ALeft, ARight: TACLTreeListNode): Integer; virtual;
    function IsCustomSorting: Boolean;
    procedure SortNodes(ANodeList: TACLTreeListNodeList);

    property Groups: TACLTreeListGroups read GetGroups;
    property RootNode: TACLTreeListNode read GetRootNode;
    property SubClass: TACLTreeListSubClass read FSubClass;
  public
    constructor Create(ASubClass: TACLTreeListSubClass);
    destructor Destroy; override;
    function IsGroupedByColumn(AColumnIndex: Integer): Boolean; virtual;
    function IsSortedByColumn(AColumnIndex: Integer): Boolean; virtual;
    procedure Sort(ARegroup: Boolean);

    class function CompareByColumn(const ALeft, ARight: TACLTreeListNode; AColumn: TACLTreeListColumn): Integer; overload; virtual;
    class function CompareByColumn(const ALeft, ARight: TACLTreeListNode; AColumnIndex: Integer;
      ACompareMode: TACLTreeListCompareMode; ASortDirection: TACLSortDirection): Integer; overload; virtual;
    class function CompareByGroup(const ALeft, ARight: TACLTreeListNode): Integer; virtual;

    property GroupBy: TACLTreeListColumnList read FGroupBy;
    property SortBy: TACLTreeListSortByList read FSortBy;
  end;

  { TACLTreeListSubClass }

  TACLTreeListDragSortingNodeDrop = procedure (Sender: TObject;
    ANode: TACLTreeListNode; AMode: TACLTreeListDropTargetInsertMode; var AHandled: Boolean) of object;
  TACLTreeListDragSortingNodeOver = procedure (Sender: TObject;
    ANode: TACLTreeListNode; AMode: TACLTreeListDropTargetInsertMode; var AAllowed: Boolean) of object;

  TACLTreeListDropEvent = procedure (Sender: TObject; Data: TACLDropTarget;
    Action: TACLDropAction; Target: TACLTreeListNode; Mode: TACLTreeListDropTargetInsertMode) of object;
  TACLTreeListDropOverEvent = procedure (Sender: TObject; Data: TACLDropTarget; var Action: TACLDropAction;
    var Target: TObject; var Mode: TACLTreeListDropTargetInsertMode; var Allow: Boolean) of object;

  TACLTreeListColumnClickEvent = procedure (Sender: TObject; AIndex: Integer; var AHandled: Boolean) of object;
  TACLTreeListCustomDrawNodeEvent = procedure (Sender: TObject; ACanvas: TCanvas; const R: TRect;
    ANode: TACLTreeListNode; var AHandled: Boolean) of object;
  TACLTreeListCustomDrawNodeCellEvent = procedure (Sender: TObject; ACanvas: TCanvas; const R: TRect;
    ANode: TACLTreeListNode; AColumn: TACLTreeListColumn; var AHandled: Boolean) of object;
  TACLTreeListCustomDrawNodeCellValueEvent = procedure (Sender: TObject; ACanvas: TCanvas; const R: TRect;
    ANode: TACLTreeListNode; const ADisplayValue: string; AValueIndex: Integer; AValueAlignment: TAlignment; var AHandled: Boolean) of object;

  TACLTreeListEditCreateEvent = function (Sender: TObject; const AParams: TACLInplaceInfo; var AHandled: Boolean): TComponent of object;
  TACLTreeListEditedEvent = procedure (Sender: TObject; AColumnIndex, ARowIndex: Integer) of object;
  TACLTreeListEditingEvent = procedure (Sender: TObject; AColumnIndex, ARowIndex: Integer; var AValue: string) of object;
  TACLTreeListEditInitializeEvent = procedure (Sender: TObject; const AParams: TACLInplaceInfo; AEdit: TComponent) of object;

  TACLTreeListConfirmationEvent = procedure (Sender: TObject; var AAllow: Boolean) of object;
  TACLTreeListGetNodeBackgroundEvent = procedure (Sender: TObject; ANode: TACLTreeListNode; var AColor: TAlphaColor) of object;
  TACLTreeListGetNodeCellDisplayTextEvent = procedure (Sender: TObject; ANode: TACLTreeListNode; AValueIndex: Integer; var AText: string) of object;
  TACLTreeListGetNodeCellStyleEvent = procedure (Sender: TObject; ANode: TACLTreeListNode;
    AColumn: TACLTreeListColumn; var AFontStyles: TFontStyles; var ATextAlignment: TAlignment) of object;
  TACLTreeListGetNodeClassEvent = procedure (Sender: TObject; var AClass: TACLTreeListNodeClass) of object;
  TACLTreeListGetNodeGroupEvent = procedure (Sender: TObject; ANode: TACLTreeListNode; var AGroupName: string) of object;
  TACLTreeListGetNodeHeightEvent = procedure (Sender: TObject; ANode: TACLTreeListNode; var AHeight: Integer) of object;
  TACLTreeListNodeCompareEvent = procedure (Sender: TObject; ALeft, ARight: TACLTreeListNode; var AResult: Integer) of object;
  TACLTreeListNodeEvent = procedure (Sender: TObject; ANode: TACLTreeListNode) of object;

  TACLTreeListSubClass = class(TACLCompoundControlSubClass,
    IACLTreeList,
    IACLTreeListOptionsListener)
  strict private
    FColumns: TACLTreeListColumns;
    FColumnsCustomizationMenu: TACLPopupMenu;
    FEditingController: TACLTreeListEditingController;
    FFocusedColumn: TACLTreeListColumn;
    FFocusedObject: TObject;
    FFocusing: Boolean;
    FGroups: TACLTreeListGroups;
    FIncSearch: TACLIncrementalSearch;
    FIncSearchColumnIndex: Integer;
    FOptionsBehavior: TACLTreeListOptionsBehavior;
    FOptionsCustomizing: TACLTreeListOptionsCustomizing;
    FOptionsSelection: TACLTreeListOptionsSelection;
    FOptionsView: TACLTreeListOptionsView;
    FRootNode: TACLTreeListNode;
    FSelection: TACLTreeListNodeList;
    FSorter: TACLTreeListSorter;
    FStyleInplaceEdit: TACLStyleEdit;
    FStyleInplaceEditButton: TACLStyleEditButton;
    FStyleMenu: TACLStylePopupMenu;
    FStyleTreeList: TACLStyleTreeList;

    FOnCanDeleteSelected: TACLTreeListConfirmationEvent;
    FOnColumnClick: TACLTreeListColumnClickEvent;
    FOnCompare: TACLTreeListNodeCompareEvent;
    FOnCustomDrawColumnBar: TACLCustomDrawEvent;
    FOnCustomDrawNode: TACLTreeListCustomDrawNodeEvent;
    FOnCustomDrawNodeCell: TACLTreeListCustomDrawNodeCellEvent;
    FOnCustomDrawNodeCellValue: TACLTreeListCustomDrawNodeCellValueEvent;
    FOnDragSorting: TNotifyEvent;
    FOnDragSortingNodeDrop: TACLTreeListDragSortingNodeDrop;
    FOnDragSortingNodeOver: TACLTreeListDragSortingNodeOver;
    FOnDrop: TACLTreeListDropEvent;
    FOnDropOver: TACLTreeListDropOverEvent;
    FOnEditCreate: TACLTreeListEditCreateEvent;
    FOnEdited: TACLTreeListEditedEvent;
    FOnEditing: TACLTreeListEditingEvent;
    FOnEditInitialize: TACLTreeListEditInitializeEvent;
    FOnEditKeyDown: TKeyEvent;
    FOnFocusedColumnChanged: TNotifyEvent;
    FOnFocusedNodeChanged: TNotifyEvent;
    FOnGetNodeBackground: TACLTreeListGetNodeBackgroundEvent;
    FOnGetNodeCellDisplayText: TACLTreeListGetNodeCellDisplayTextEvent;
    FOnGetNodeCellStyle: TACLTreeListGetNodeCellStyleEvent;
    FOnGetNodeChildren: TACLTreeListNodeEvent;
    FOnGetNodeClass: TACLTreeListGetNodeClassEvent;
    FOnGetNodeGroup: TACLTreeListGetNodeGroupEvent;
    FOnGetNodeHeight: TACLTreeListGetNodeHeightEvent;
    FOnNodeChecked: TACLTreeListNodeEvent;
    FOnNodeDblClicked: TACLTreeListNodeEvent;
    FOnNodeDeleted: TACLTreeListNodeEvent;
    FOnSelectionChanged: TNotifyEvent;
    FOnSorted: TNotifyEvent;
    FOnSorting: TNotifyEvent;
    FOnSortReset: TNotifyEvent;

    function GetContentViewInfo: TACLTreeListContentViewInfo; inline;
    function GetDragAndDropController: TACLTreeListDragAndDropController;
    function GetFocusedGroup: TACLTreeListGroup;
    function GetFocusedNode: TACLTreeListNode;
    function GetFocusedNodeData: Pointer;
    function GetGroup(Index: Integer): TACLTreeListGroup;
    function GetGroupCount: Integer;
    function GetHasSelection: Boolean;
    function GetHitTest: TACLTreeListHitTest;
    function GetSelected(Index: Integer): TACLTreeListNode;
    function GetSelectedCheckState: TCheckBoxState;
    function GetSelectedCount: Integer;
    function GetSorter: TACLTreeListSorter;
    function GetViewInfo: TACLTreeListViewInfo;
    function GetViewportX: Integer;
    function GetViewportY: Integer;
    function GetVisibleScrolls: TACLVisibleScrollBars;
    procedure SetColumns(AValue: TACLTreeListColumns);
    procedure SetFocusedColumn(AValue: TACLTreeListColumn);
    procedure SetFocusedGroup(AValue: TACLTreeListGroup);
    procedure SetFocusedNode(AValue: TACLTreeListNode);
    procedure SetFocusedNodeData(const Value: Pointer);
    procedure SetFocusedObject(AValue: TObject); overload;
    procedure SetOnGetNodeClass(const Value: TACLTreeListGetNodeClassEvent);
    procedure SetOptionsBehavior(AValue: TACLTreeListOptionsBehavior);
    procedure SetOptionsCustomizing(AValue: TACLTreeListOptionsCustomizing);
    procedure SetOptionsSelection(AValue: TACLTreeListOptionsSelection);
    procedure SetOptionsView(AValue: TACLTreeListOptionsView);
    procedure SetStyleInplaceEdit(AValue: TACLStyleEdit);
    procedure SetStyleInplaceEditButton(AValue: TACLStyleEditButton);
    procedure SetStyleMenu(AValue: TACLStylePopupMenu);
    procedure SetStyle(AValue: TACLStyleTreeList);
    procedure SetViewportX(const Value: Integer);
    procedure SetViewportY(const Value: Integer);
  protected
    FNodeClass: TACLTreeListNodeClass;
    FStartObject: TObject;
    FTapLocation: TPoint;
    FWasSelected: Boolean;

    function CreateDragAndDropController: TACLCompoundControlDragAndDropController; override;
    function CreateHintController: TACLCompoundControlHintController; override;
    function CreateHitTest: TACLHitTestInfo; override;
    function CreateColumns: TACLTreeListColumns; virtual;
    function CreateEditingController: TACLTreeListEditingController; virtual;
    function CreateGroups: TACLTreeListGroups; virtual;
    function CreateInplaceEdit(const AParams: TACLInplaceInfo; out AEdit: TComponent): Boolean; virtual;
    function CreateNode: TACLTreeListNode; virtual;
    function CreateOptionsBehavior: TACLTreeListOptionsBehavior; virtual;
    function CreateOptionsCustomizing: TACLTreeListOptionsCustomizing; virtual;
    function CreateOptionsSelection: TACLTreeListOptionsSelection; virtual;
    function CreateOptionsView: TACLTreeListOptionsView; virtual;
    function CreateSorter: TACLTreeListSorter; virtual;
    function CreateStyle: TACLStyleTreeList; virtual;
    function CreateViewInfo: TACLCompoundControlCustomViewInfo; override;

    function GetCaptionForPath(ANode: TACLTreeListNode): string; virtual;

    // Events
    function DoCanDeleteSelected: Boolean; virtual;
    function DoColumnClick(AColumn: TACLTreeListColumn): Boolean; virtual;
    procedure DoDeleteSelected; virtual;
    procedure DoDragSorting; virtual;
    function DoDragSortingDrop(ANode: TACLTreeListNode; AMode: TACLTreeListDropTargetInsertMode): Boolean; virtual;
    function DoDragSortingOver(ANode: TACLTreeListNode; AMode: TACLTreeListDropTargetInsertMode): Boolean; virtual;
    procedure DoDrop(Data: TACLDropTarget; Action: TACLDropAction; Target: TACLTreeListNode; Mode: TACLTreeListDropTargetInsertMode); virtual;
    procedure DoDropOver(Data: TACLDropTarget; var Action: TACLDropAction;
      var Target: TObject; var Mode: TACLTreeListDropTargetInsertMode; var Allow: Boolean); virtual;
    procedure DoFocusedColumnChanged; virtual;
    procedure DoFocusedNodeChanged; virtual;
    procedure DoGetNodeCellDisplayText(ANode: TACLTreeListNode; AValueIndex: Integer; var AText: string); virtual;
    procedure DoGetNodeCellStyle(AFont: TFont; ANode: TACLTreeListNode; AColumn: TACLTreeListColumn; out ATextAlignment: TAlignment); virtual;
    procedure DoGetNodeChildren(ANode: TACLTreeListNode); virtual;
    procedure DoGetNodeClass(var ANodeClass: TACLTreeListNodeClass); virtual;
    procedure DoGetNodeHeight(ANode: TACLTreeListNode; var AHeight: Integer); virtual;
    procedure DoNodeChecked(ANode: TACLTreeListNode); virtual;
    function DoNodeDblClicked(ANode: TACLTreeListNode): Boolean; virtual;
    procedure DoSelectionChanged; virtual;
    procedure DoSorting; virtual;
    procedure DoSorted; virtual;
    procedure DoSortReset; virtual;

    // CustomDraw Events
    function DoCustomDrawColumnBar(ACanvas: TCanvas; const R: TRect): Boolean; virtual;
    function DoCustomDrawNode(ACanvas: TCanvas; const R: TRect; ANode: TACLTreeListNode): Boolean; virtual;
    function DoCustomDrawNodeCell(ACanvas: TCanvas; const R: TRect; ANode: TACLTreeListNode; AColumn: TACLTreeListColumn): Boolean; virtual;
    function DoCustomDrawNodeCellValue(ACanvas: TCanvas; const R: TRect; ANode: TACLTreeListNode;
      const AText: string; AValueIndex: Integer; ATextAlignment: TAlignment): Boolean; virtual;

    // InplaceEdit Events
    function DoEditCreate(const AParams: TACLInplaceInfo): TComponent; virtual;
    procedure DoEdited(ARow, AColumn: Integer); virtual;
    procedure DoEditing(ARow, AColumn: Integer; var AValue: string); virtual;
    procedure DoEditInitialize(const AParams: TACLInplaceInfo; AEdit: TComponent); virtual;
    procedure DoEditKeyDown(var AKey: Word; AShiftState: TShiftState); virtual;

    // ColumnCustomizationMenu
    procedure ColumnCustomizationMenuShow(const P: TPoint); virtual;
    procedure ColumnSetVisibilityHandler(Sender: TObject);
    function GetColumnCustomizationMenu: TACLPopupMenu; virtual;

    // Changes
    procedure ProcessChanges(AChanges: TIntegerSet = []); override;

    // Focus
    function CheckFocusedObject: BOolean;
    procedure FocusChanged; override;
    procedure SetFocusedObject(AObject: TObject; ADropSelection: Boolean; AMakeVisible: Boolean = True); overload;
    procedure ValidateFocusedObject;

    // Incremental Search
    function CheckIncSearchColumn: Boolean;
    function GetHighlightBounds(const AText: string;
      AAbsoluteColumnIndex: Integer; out AHighlightStart, AHighlightFinish: Integer): Boolean;
    procedure IncSearchChanged(Sender: TObject);
    function IncSearchContains(ANode: TACLTreeListNode): Boolean;
    procedure IncSearchFindCore(Sender: TObject; var AFound: Boolean);

    // Gestures
    procedure ProcessGesture(const AEventInfo: TGestureEventInfo; var AHandled: Boolean); override;

    // Keyboard
    function GetNextColumn(out AColumn: TACLTreeListColumn): Boolean;
    function GetNextObject(AObject: TObject; AKey: Word): TObject; virtual;
    function GetPrevColumn(out AColumn: TACLTreeListColumn): Boolean;
    function IsMultiSelectOperation(AShift: TShiftState): Boolean;
    procedure NavigateTo(AObject: TObject; AShift: TShiftState);
    procedure ProcessKeyDown(var AKey: Word; AShift: TShiftState); override;
    procedure ProcessKeyPress(var AKey: WideChar); override;
    procedure ProcessKeyUp(var AKey: Word; AShift: TShiftState); override;

    // Mouse
    procedure ProcessContextPopup(var AHandled: Boolean); override;
    procedure ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseClickAtColumn(AButton: TMouseButton; AShift: TShiftState; AColumn: TACLTreeListColumn); virtual;
    procedure ProcessMouseClickAtGroup(AButton: TMouseButton; AShift: TShiftState; AGroup: TACLTreeListGroup); virtual;
    procedure ProcessMouseDblClick(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseUp(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState); override;

    // General
    function GetObjectChild(AObject: TObject): TObject;
    function GetObjectParent(AObject: TObject): TObject;
    function IsSelected(AObject: TObject): Boolean;
    procedure ToggleCheckboxes;
    procedure ToggleGroupExpanded(AGroup: TACLTreeListGroup; AShift: TShiftState);

    // IACLTreeList
    procedure IACLTreeList.NodeChecked = DoNodeChecked;
    procedure IACLTreeList.NodePopulateChildren = DoGetNodeChildren;
    function CalculateBestFit(AColumn: TACLTreeListColumn): Integer;
    function ColumnsCanCustomizeOrder: Boolean;
    function ColumnsCanCustomizeVisibility: Boolean;
    function GetAbsoluteVisibleNodes: TACLTreeListNodeList;
    function GetAutoCheckParents: Boolean;
    function GetAutoCheckChildren: Boolean;
    function GetGroupByList: TACLTreeListColumnList;
    function GetObject: TPersistent;
    function GetRootNode: TACLTreeListNode;
    function GetSortByList: TACLTreeListColumnList;
    procedure GroupRemoving(AGroup: TACLTreeListGroup); virtual;
    procedure NodeRemoving(ANode: TACLTreeListNode); virtual;
    procedure NodeSetSelected(ANode: TACLTreeListNode; var AValue: Boolean);
    procedure NodeValuesChanged(AColumnIndex: Integer = -1);
    function QueryChildInterface(AChild: TObject; const IID: TGUID; var Obj): HRESULT;

    property Groups: TACLTreeListGroups read FGroups;
    property Selection: TACLTreeListNodeList read FSelection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    procedure Clear; virtual;
    procedure DeleteSelected; virtual;
    procedure ReloadData; virtual;
    procedure SetTargetDPI(AValue: Integer); override;
    function WantSpecialKey(Key: Word; Shift: TShiftState): Boolean; override;

    // MUI
    procedure Localize(const ASection: string); override;

    // Customized Settings
    procedure ConfigLoad(AConfig: TACLIniFile; const ASection, AItem: string); virtual;
    procedure ConfigSave(AConfig: TACLIniFile; const ASection, AItem: string); virtual;

    // Editing
    procedure StartEditing(ANode: TACLTreeListNode; AColumn: TACLTreeListColumn = nil);
    procedure StopEditing;

    // Scrolling
    procedure ExpandTo(AObject: TObject);
    procedure MakeTop(AObject: TObject);
    procedure MakeVisible(AObject: TObject);
    procedure ScrollBy(ADeltaX, ADeltaY: Integer);
    procedure ScrollByLines(ALines: Integer; ADirection: TACLMouseWheelDirection);
    procedure ScrollTo(AObject: TObject; AMode: TACLScrollToMode; AColumn: TACLTreeListColumn = nil);
    procedure ScrollHorizontally(const AScrollCode: TScrollCode); override;
    procedure ScrollVertically(const AScrollCode: TScrollCode); override;

    // Groupping
    procedure GroupBy(AColumn: TACLTreeListColumn; AResetPrevSortingParams: Boolean = False);
    procedure Regroup;
    procedure ResetGrouppingParams;

    // Sorting
    procedure ResetSortingParams;
    procedure Resort;
    procedure Sort(ACustomSortProc: TACLTreeListNodeCompareEvent);
    procedure SortBy(AColumn: TACLTreeListColumn; ADirection: TACLSortDirection;
      AResetPrevSortingParams: Boolean = False); overload;
    procedure SortBy(AColumn: TACLTreeListColumn;
      AResetPrevSortingParams: Boolean = False); overload;

    // Paths
    function FindByPath(APath: string; AIgnoreCase: Boolean = True; AExactMatch: Boolean = False): TACLTreeListNode;
    function GetPath(ANode: TACLTreeListNode): string;
    procedure SetPath(const APath: string); virtual;

    // Selection
    procedure SelectAll; virtual;
    procedure SelectInvert; virtual;
    procedure SelectNone; virtual;
    procedure SelectObject(AObject: TObject; AMode: TACLSelectionMode; AIsMedium: Boolean); virtual;
    procedure SelectOnMouseDown(AButton: TMouseButton; AShift: TShiftState); virtual;
    procedure SelectRange(AFirstObject, ALastObject, AObjectToFocus: TObject; AMakeVisible, ADropSelection: Boolean; AMode: TACLSelectionMode); overload;
    procedure SelectRange(AFirstObject, ALastObject: TObject; AMakeVisible, ADropSelection: Boolean; AMode: TACLSelectionMode); overload;
    procedure SelectRange(AFirstObject, ALastObject: TObject; AShift: TShiftState); overload;

    // Styles
    function StyleGetNodeBackgroundColor(AOdd: Boolean; ANode: TACLTreeListNode = nil): TAlphaColor; virtual;
    function StyleGetNodeTextColor(ANode: TACLTreeListNode = nil): TColor; virtual;
    procedure StylePrepareFont(ACanvas: TCanvas; AFontIndex: Integer = -1; ASuperscript: Boolean = False); virtual;

    // Data Properties
    property AbsoluteVisibleNodes: TACLTreeListNodeList read GetAbsoluteVisibleNodes;
    property Columns: TACLTreeListColumns read FColumns write SetColumns;
    property DragAndDropController: TACLTreeListDragAndDropController read GetDragAndDropController;
    property EditingController: TACLTreeListEditingController read FEditingController;
    property FocusedColumn: TACLTreeListColumn read FFocusedColumn write SetFocusedColumn;
    property FocusedGroup: TACLTreeListGroup read GetFocusedGroup write SetFocusedGroup;
    property FocusedNode: TACLTreeListNode read GetFocusedNode write SetFocusedNode;
    property FocusedNodeData: Pointer read GetFocusedNodeData write SetFocusedNodeData;
    property FocusedObject: TObject read FFocusedObject write SetFocusedObject;
    property Group[Index: Integer]: TACLTreeListGroup read GetGroup;
    property GroupCount: Integer read GetGroupCount;

    property HasSelection: Boolean read GetHasSelection;
    property IncSearch: TACLIncrementalSearch read FIncSearch;
    property IncSearchColumnIndex: Integer read FIncSearchColumnIndex;

    property ContentViewInfo: TACLTreeListContentViewInfo read GetContentViewInfo;
    property HitTest: TACLTreeListHitTest read GetHitTest;
    property RootNode: TACLTreeListNode read GetRootNode;
    property Selected[Index: Integer]: TACLTreeListNode read GetSelected;
    property SelectedCheckState: TCheckBoxState read GetSelectedCheckState;
    property SelectedCount: Integer read GetSelectedCount;
    property Sorter: TACLTreeListSorter read GetSorter;
    property ViewInfo: TACLTreeListViewInfo read GetViewInfo;
    property ViewportX: Integer read GetViewportX write SetViewportX;
    property ViewportY: Integer read GetViewportY write SetViewportY;
    property VisibleScrolls: TACLVisibleScrollBars read GetVisibleScrolls;

    // Options Properties
    property OptionsBehavior: TACLTreeListOptionsBehavior read FOptionsBehavior write SetOptionsBehavior;
    property OptionsCustomizing: TACLTreeListOptionsCustomizing read FOptionsCustomizing write SetOptionsCustomizing;
    property OptionsSelection: TACLTreeListOptionsSelection read FOptionsSelection write SetOptionsSelection;
    property OptionsView: TACLTreeListOptionsView read FOptionsView write SetOptionsView;
    property StyleInplaceEdit: TACLStyleEdit read FStyleInplaceEdit write SetStyleInplaceEdit;
    property StyleInplaceEditButton: TACLStyleEditButton read FStyleInplaceEditButton write SetStyleInplaceEditButton;
    property StyleMenu: TACLStylePopupMenu read FStyleMenu write SetStyleMenu;
    property Style: TACLStyleTreeList read FStyleTreeList write SetStyle;

    // Events
    property OnCanDeleteSelected: TACLTreeListConfirmationEvent read FOnCanDeleteSelected write FOnCanDeleteSelected;
    property OnColumnClick: TACLTreeListColumnClickEvent read FOnColumnClick write FOnColumnClick;
    property OnCompare: TACLTreeListNodeCompareEvent read FOnCompare write FOnCompare;
    property OnCustomDrawColumnBar: TACLCustomDrawEvent read FOnCustomDrawColumnBar write FOnCustomDrawColumnBar;
    property OnCustomDrawNode: TACLTreeListCustomDrawNodeEvent read FOnCustomDrawNode write FOnCustomDrawNode;
    property OnCustomDrawNodeCell: TACLTreeListCustomDrawNodeCellEvent read FOnCustomDrawNodeCell write FOnCustomDrawNodeCell;
    property OnCustomDrawNodeCellValue: TACLTreeListCustomDrawNodeCellValueEvent read FOnCustomDrawNodeCellValue write FOnCustomDrawNodeCellValue;
    property OnDragSorting: TNotifyEvent read FOnDragSorting write FOnDragSorting;
    property OnDragSortingNodeDrop: TACLTreeListDragSortingNodeDrop read FOnDragSortingNodeDrop write FOnDragSortingNodeDrop;
    property OnDragSortingNodeOver: TACLTreeListDragSortingNodeOver read FOnDragSortingNodeOver write FOnDragSortingNodeOver;
    property OnDrop: TACLTreeListDropEvent read FOnDrop write FOnDrop;
    property OnDropOver: TACLTreeListDropOverEvent read FOnDropOver write FOnDropOver;
    property OnEditCreate: TACLTreeListEditCreateEvent read FOnEditCreate write FOnEditCreate;
    property OnEdited: TACLTreeListEditedEvent read FOnEdited write FOnEdited;
    property OnEditing: TACLTreeListEditingEvent read FOnEditing write FOnEditing;
    property OnEditInitialize: TACLTreeListEditInitializeEvent read FOnEditInitialize write FOnEditInitialize;
    property OnEditKeyDown: TKeyEvent read FOnEditKeyDown write FOnEditKeyDown;
    property OnFocusedColumnChanged: TNotifyEvent read FOnFocusedColumnChanged write FOnFocusedColumnChanged;
    property OnFocusedNodeChanged: TNotifyEvent read FOnFocusedNodeChanged write FOnFocusedNodeChanged;
    property OnGetNodeBackground: TACLTreeListGetNodeBackgroundEvent read FOnGetNodeBackground write FOnGetNodeBackground;
    property OnGetNodeCellDisplayText: TACLTreeListGetNodeCellDisplayTextEvent read FOnGetNodeCellDisplayText write FOnGetNodeCellDisplayText;
    property OnGetNodeCellStyle: TACLTreeListGetNodeCellStyleEvent read FOnGetNodeCellStyle write FOnGetNodeCellStyle;
    property OnGetNodeChildren: TACLTreeListNodeEvent read FOnGetNodeChildren write FOnGetNodeChildren;
    property OnGetNodeClass: TACLTreeListGetNodeClassEvent read FOnGetNodeClass write SetOnGetNodeClass;
    property OnGetNodeGroup: TACLTreeListGetNodeGroupEvent read FOnGetNodeGroup write FOnGetNodeGroup;
    property OnGetNodeHeight: TACLTreeListGetNodeHeightEvent read FOnGetNodeHeight write FOnGetNodeHeight;
    property OnNodeChecked: TACLTreeListNodeEvent read FOnNodeChecked write FOnNodeChecked;
    property OnNodeDblClicked: TACLTreeListNodeEvent read FOnNodeDblClicked write FOnNodeDblClicked;
    property OnNodeDeleted: TACLTreeListNodeEvent read FOnNodeDeleted write FOnNodeDeleted;
    property OnSelectionChanged: TNotifyEvent read FOnSelectionChanged write FOnSelectionChanged;
    property OnSorted: TNotifyEvent read FOnSorted write FOnSorted;
    property OnSorting: TNotifyEvent read FOnSorting write FOnSorting;
    property OnSortReset: TNotifyEvent read FOnSortReset write FOnSortReset;
  end;

implementation

uses
{$IFNDEF FPC}
  ACL.Graphics.SkinImageSet,
{$ENDIF}
  ACL.UI.Controls.TreeList.SubClass.DragAndDrop,
  ACL.Utils.FileSystem,
  ACL.Utils.Messaging,
  ACL.Utils.Strings;

const
  sErrorCannotChangeNodeClass = 'Cannot change class of nodes if nodes are already created';
  sErrorCannotEditHiddenCell = 'Cannot edit a hidden cell';

type
  TACLTreeListColumnAccess = class(TACLTreeListColumn);
  TACLTreeListNodeAccess = class(TACLTreeListNode);

{ TACLStyleTreeList }

procedure TACLStyleTreeList.DrawBackground(ACanvas: TCanvas;
  const R: TRect; AEnabled: Boolean; ABorders: TACLBorders);
var
  AColor: TAlphaColor;
begin
  if AEnabled then
    AColor := BackgroundColor.Value
  else
    AColor := BackgroundColorDisabled.Value;

  acFillRect(ACanvas, R, AColor);
  acDrawFrameEx(ACanvas, R, BorderColor.Value, ABorders);
end;

procedure TACLStyleTreeList.DrawCheckMark(ACanvas: TCanvas;
  const R: TRect; AState: TACLButtonState; ACheckBoxState: TCheckBoxState);
begin
  if not R.IsEmpty then
    CheckMark.Draw(ACanvas, R, Ord(ACheckBoxState) * 5 + Ord(AState));
end;

procedure TACLStyleTreeList.DrawGridline(
  ACanvas: TCanvas; const R: TRect; ASide: TACLBorder);
begin
  acDrawFrameEx(ACanvas, R, GridColor.Value, [ASide]);
end;

procedure TACLStyleTreeList.DrawGroupExpandButton(
  ACanvas: TCanvas; const R: TRect; AExpanded: Boolean);
begin
  GroupHeaderExpandButton.Draw(ACanvas, R, Ord(AExpanded));
end;

procedure TACLStyleTreeList.DrawGroupHeader(ACanvas: TCanvas; const R: TRect; ABorders: TACLBorders);
begin
  acFillRect(ACanvas, R, GroupHeaderColor.Value);
  acDrawFrameEx(ACanvas, R, GroupHeaderColorBorder.Value, ABorders);
end;

procedure TACLStyleTreeList.DrawHeader(ACanvas: TCanvas; const R: TRect; ABorders: TACLBorders);
begin
  ColumnHeader.Draw(ACanvas, R, 0, ABorders);
end;

procedure TACLStyleTreeList.DrawHeaderSortingArrow(
  ACanvas: TCanvas; const R: TRect; ADirection, AEnabled: Boolean);
begin
  ColumnHeaderSortingArrow.Draw(ACanvas, R, Ord(ADirection) * 2 + Ord(AEnabled));
end;

procedure TACLStyleTreeList.DrawRowExpandButton(
  ACanvas: TCanvas; const R: TRect; AExpanded, ASelected: Boolean);
var
  AIndex: Integer;
begin
  AIndex := Ord(AExpanded);
  if RowExpandButton.FrameCount >= 4 then
    Inc(AIndex, 2 * Ord(ASelected));
  RowExpandButton.Draw(ACanvas, R, AIndex);
end;

procedure TACLStyleTreeList.InitializeResources;
begin
  BorderColor.InitailizeDefaults('EditBox.Colors.Border', True);
  BackgroundColor.InitailizeDefaults('EditBox.Colors.Content', True);
  BackgroundColorDisabled.InitailizeDefaults('EditBox.Colors.ContentDisabled', True);

  GridColor.InitailizeDefaults('TreeList.Colors.Grid', True);
  IncSearchColor.InitailizeDefaults('TreeList.Colors.IncSearch');
  IncSearchColorText.InitailizeDefaults('TreeList.Colors.IncSearchText');
  SelectionRectColor.InitailizeDefaults('TreeList.Colors.SelectionRect', True);

  ColumnHeader.InitailizeDefaults('TreeList.Textures.ColumnHeader');
  ColumnHeaderFont.InitailizeDefaults('TreeList.Fonts.ColumnHeader');
  ColumnHeaderSortingArrow.InitailizeDefaults('TreeList.Textures.ColumnHeaderSortingArrow');

  GroupHeaderColor.InitailizeDefaults('TreeList.Colors.GroupHeader', True);
  GroupHeaderColorBorder.InitailizeDefaults('TreeList.Colors.GroupHeaderBorder', True);

  GroupHeaderContentOffsets.InitailizeDefaults('TreeList.Margins.GroupHeaderContentOffsets', Rect(4, 4, 4, 4));
  GroupHeaderExpandButton.InitailizeDefaults('TreeList.Textures.GroupHeaderExpandButton');
  GroupHeaderFont.InitailizeDefaults('TreeList.Fonts.GroupHeader');

  RowColor1.InitailizeDefaults('TreeList.Colors.Row1', True);
  RowColor2.InitailizeDefaults('TreeList.Colors.Row2', True);
  RowColorText.InitailizeDefaults('EditBox.Colors.Text');
  RowColorDisabledText.InitailizeDefaults('EditBox.Colors.TextDisabled');
  RowColorFocused.InitailizeDefaults('TreeList.Colors.RowFocused', True);
  RowColorFocusedText.InitailizeDefaults('TreeList.Colors.RowFocusedText');
  RowColorHovered.InitailizeDefaults('TreeList.Colors.RowHovered', True);
  RowColorHoveredText.InitailizeDefaults('TreeList.Colors.RowHoveredText');
  RowColorSelected.InitailizeDefaults('TreeList.Colors.RowSelected', True);
  RowColorSelectedInactive.InitailizeDefaults('TreeList.Colors.RowSelectedInactive', True);
  RowColorSelectedText.InitailizeDefaults('TreeList.Colors.RowSelectedText');
  RowColorSelectedTextInactive.InitailizeDefaults('TreeList.Colors.RowSelectedTextInactive');
  RowContentOffsets.InitailizeDefaults('TreeList.Margins.RowContentOffsets', Rect(4, 4, 4, 4));
  RowExpandButton.InitailizeDefaults('TreeList.Textures.RowExpandButton');

  FocusRectColor.InitailizeDefaults('', clDefault);
  CheckMark.InitailizeDefaults('Buttons.Textures.CheckBox');
end;

function TACLStyleTreeList.GetRowColor(Odd: Boolean): TAlphaColor;
begin
  if Odd then
    Result := RowColor2.Value
  else
    Result := RowColor1.Value;
end;

function TACLStyleTreeList.GetRowColorSelected(Focused: Boolean): TAlphaColor;
begin
  if Focused then
    Result := TAlphaColor.Default
  else
    Result := RowColorSelectedInactive.Value;

  if Result = TAlphaColor.Default then
    Result := RowColorSelected.Value;
end;

function TACLStyleTreeList.GetRowColorSelectedText(Focused: Boolean): TColor;
begin
  if Focused then
    Result := clDefault
  else
    Result := RowColorSelectedTextInactive.AsColor;

  if Result = clDefault then
    Result := RowColorSelectedText.AsColor;
end;

function TACLStyleTreeList.GetRowColorText(Enabled: Boolean): TColor;
begin
  if Enabled then
    Result := RowColorText.AsColor
  else
    Result := RowColorDisabledText.AsColor;
end;

{ TACLTreeListCustomViewInfo }

function TACLTreeListCustomViewInfo.GetSubClass: TACLTreeListSubClass;
begin
  Result := inherited SubClass as TACLTreeListSubClass;
end;

{ TACLTreeListColumnViewInfo }

constructor TACLTreeListColumnViewInfo.Create(ASubClass: TACLCompoundControlSubClass; AColumn: TACLTreeListColumn);
begin
  inherited Create(ASubClass);
  FColumn := AColumn;
end;

function TACLTreeListColumnViewInfo.CalculateAutoWidth: Integer;
begin
  Result := Bounds.Width - TextRect.Width;
  if Column.TextVisible then
  begin
    SubClass.StylePrepareFont(MeasureCanvas, TACLStyleTreeList.IndexColumnHeaderFont);
    Inc(Result, acTextSize(MeasureCanvas, Column.Caption).cx);
  end
end;

function TACLTreeListColumnViewInfo.CalculateBestFit: Integer;
begin
  Result := Max(CalculateAutoWidth, NodeViewInfo.CalculateCellAutoWidth(SubClass.AbsoluteVisibleNodes, Column));
end;

function TACLTreeListColumnViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  Result := inherited CalculateHitTest(AInfo);
  if Result then
  begin
    if (Column <> nil) and not Column.TextVisible then
    begin
      AInfo.HintData.Text := Column.Caption;
      AInfo.HintData.ScreenBounds := SubClass.ClientToScreen(Bounds);
    end
    else
      if CalculateAutoWidth > Bounds.Width then
      begin
        AInfo.HintData.Text := Column.Caption;
        AInfo.HintData.ScreenBounds := SubClass.ClientToScreen(TextRect);
      end;

    if PtInRect(CheckBoxRect, AInfo.HitPoint) then
    begin
      AInfo.Cursor := crHandPoint;
      AInfo.IsCheckable := True;
      AInfo.HitObjectData[cchdSubPart] := TObject(cchtCheckable);
    end
    else

    if SubClass.OptionsCustomizing.ColumnWidth then
      if CanResize and (Bounds.Right - AInfo.HitPoint.X <= dpiApply(acResizeHitTestAreaSize, CurrentDpi)) then
      begin
        AInfo.Cursor := crHSplit;
        AInfo.IsResizable := True;
      end;
  end;
end;

function TACLTreeListColumnViewInfo.CreateDragObject(const AHitTest: TACLHitTestInfo): TACLCompoundControlDragObject;
begin
  if AHitTest.IsResizable then
    Result := TACLTreeListColumnDragResizeObject.Create(Self)
  else
    Result := TACLTreeListColumnDragMoveObject.Create(Self);
end;

procedure TACLTreeListColumnViewInfo.CalculateSortArea(var R: TRect);
var
  ASortArrowSize: TSize;
begin
  SortByIndex := Column.SortByIndex;

  ASortArrowSize := SortArrowIndexSize;
  FSortArrowIndexRect := R.Split(srRight, ASortArrowSize.cx);
  FSortArrowIndexRect.Height := ASortArrowSize.cy;
  R.Right := SortArrowIndexRect.Left;

  if SortByIndex >= 0 then
    ASortArrowSize := SubClass.Style.ColumnHeaderSortingArrow.FrameSize
  else
    ASortArrowSize := NullSize;

  FSortArrowRect := R.Split(srRight, ASortArrowSize.cx);
  FSortArrowRect.CenterVert(ASortArrowSize.cy);
  R.Right := SortArrowRect.Left;

  FSortArrowIndexRect.SetLocation(FSortArrowIndexRect.Left, SortArrowRect.Top + 4);
end;

procedure TACLTreeListColumnViewInfo.CalculateImageRect(var R: TRect; AHasText: Boolean);
var
  LImageSize: TSize;
begin
  if Column.ImageIndex >= 0 then
    LImageSize := acGetImageListSize(OptionsColumns.Images, CurrentDpi)
  else
    LImageSize := NullSize;

  FImageRect := R;
  if AHasText then
  begin
    FImageRect.CenterVert(LImageSize.cY);
    FImageRect.Width := LImageSize.cx;
    Inc(R.Left, GetElementWidthIncludeOffset(ImageRect, SubClass.CurrentDpi));
  end
  else
  begin
    FImageRect.Center(LImageSize);
    R.Left := R.Right;
  end;
end;

procedure TACLTreeListColumnViewInfo.CalculateCheckBox(var R: TRect);
begin
  if IsFirst and SubClass.OptionsView.CheckBoxes then
  begin
    NodeViewInfo.Initialize(nil);
    Dec(R.Left, NodeViewInfo.FTextExtends[False].Left);
    FCheckBoxRect := R;
    FCheckBoxRect.CenterVert(NodeViewInfo.CheckBoxRect.Height);
    FCheckBoxRect.Left := R.Left + NodeViewInfo.CheckBoxRect.Left;
    FCheckBoxRect.Right := R.Left + NodeViewInfo.CheckBoxRect.Right;
    R.Left := CheckBoxRect.Right + dpiApply(acIndentBetweenElements, CurrentDpi);
  end
  else
    FCheckBoxRect := NullRect;
end;

procedure TACLTreeListColumnViewInfo.CalculateContentRects(R: TRect);
begin
  R.Content(SubClass.Style.ColumnHeader.ContentOffsets);
  CalculateCheckBox(R);
  CalculateSortArea(R);
  R.Right := SortArrowRect.Left - IfThen(SortArrowRect.Width > 0, dpiApply(acIndentBetweenElements, CurrentDpi));
  CalculateImageRect(R, (Column = nil) or Column.TextVisible);
  FTextRect := R;
end;

procedure TACLTreeListColumnViewInfo.DoCalculate(AChanges: TIntegerSet);
begin
  inherited DoCalculate(AChanges);
  if [cccnStruct] * AChanges <> [] then
    FSortArrowIndexSize := InvalidSize;
  if [cccnLayout, cccnStruct] * AChanges <> [] then
  begin
    FBorders := [mRight, mBottom];
    if OptionsColumns.AutoWidth and IsLast then
      Exclude(FBorders, mRight);
    if not (mTop in SubClass.OptionsView.Borders) then
      Include(FBorders, mTop);
  end;
  if [cccnViewport, cccnLayout, cccnStruct] * AChanges <> [] then
    CalculateContentRects(Bounds);
  if ([tlcnCheckState, cccnStruct] * AChanges <> []) and IsFirst then
    FCheckState := SubClass.RootNode.ChildrenCheckState;
end;

procedure TACLTreeListColumnViewInfo.DoDraw(ACanvas: TCanvas);
var
  ASavedClipRegion: HRGN;
begin
  ASavedClipRegion := acSaveClipRegion(ACanvas.Handle);
  try
    if acIntersectClipRegion(ACanvas.Handle, Bounds) then
    begin
      SubClass.StylePrepareFont(ACanvas, TACLStyleTreeList.IndexColumnHeaderFont);
      SubClass.Style.DrawHeader(ACanvas, Bounds, Borders);
      SubClass.Style.DrawCheckMark(ACanvas, CheckBoxRect, CheckBoxState, CheckState);
      acDrawImage(ACanvas, ImageRect, OptionsColumns.Images, Column.ImageIndex);
      acTextDraw(ACanvas, Column.Caption, TextRect, Column.TextAlign, taVerticalCenter, True);
      DoDrawSortMark(ACanvas);
    end;
  finally
    acRestoreClipRegion(ACanvas.Handle, ASavedClipRegion);
  end;
end;

procedure TACLTreeListColumnViewInfo.DoDrawSortMark(ACanvas: TCanvas);
begin
  if SortByIndex >= 0 then
  begin
    SubClass.StylePrepareFont(ACanvas, TACLStyleTreeList.IndexColumnHeaderFont, True);
    SubClass.Style.DrawHeaderSortingArrow(ACanvas, SortArrowRect, Column.SortDirection <> sdDescending, True);
    if not SortArrowIndexRect.IsEmpty then
      acTextOut(ACanvas, SortArrowIndexRect.Left, SortArrowIndexRect.Top, IntToStr(SortByIndex + 1));
  end;
end;

procedure TACLTreeListColumnViewInfo.InitializeActualWidth;
begin
  ActualWidth := dpiApply(Column.Width, CurrentDpi);
end;

procedure TACLTreeListColumnViewInfo.OnHotTrack(Action: TACLHotTrackAction);
begin
  Invalidate;
end;

procedure TACLTreeListColumnViewInfo.SetSortByIndex(AValue: Integer);
begin
  if FSortByIndex <> AValue then
  begin
    FSortByIndex := AValue;
    FSortArrowIndexSize := InvalidSize;
  end;
end;

function TACLTreeListColumnViewInfo.CanResize: Boolean;
begin
  Result := Column.CanResize and (not OptionsColumns.AutoWidth or (SubClass.Columns.Count > 1));
end;

function TACLTreeListColumnViewInfo.GetCheckBoxState: TACLButtonState;
begin
  Result := SubClass.CalculateState(Self, cchtCheckable)
end;

function TACLTreeListColumnViewInfo.GetColumnBarViewInfo: TACLTreeListColumnBarViewInfo;
begin
  Result := SubClass.ViewInfo.Content.ColumnBarViewInfo;
end;

function TACLTreeListColumnViewInfo.GetOptionsColumns: TACLTreeListOptionsViewColumns;
begin
  Result := SubClass.OptionsView.Columns;
end;

function TACLTreeListColumnViewInfo.GetSortArrowIndexSize: TSize;
begin
  if FSortArrowIndexSize.cx < 0 then
  begin
    if (SortByIndex >= 0) and IsMultiColumnSorting then
    begin
      SubClass.StylePrepareFont(MeasureCanvas, TACLStyleTreeList.IndexColumnHeaderFont, True);
      FSortArrowIndexSize := acTextSize(MeasureCanvas, IntToStr(SortByIndex + 1));
    end
    else
      FSortArrowIndexSize := NullSize;
  end;
  Result := FSortArrowIndexSize;
end;

function TACLTreeListColumnViewInfo.GetIsFirst: Boolean;
begin
  Result := VisibleIndex = 0;
end;

function TACLTreeListColumnViewInfo.GetIsLast: Boolean;
begin
  Result := VisibleIndex + 1 = ColumnBarViewInfo.ChildCount;
end;

function TACLTreeListColumnViewInfo.GetIsMultiColumnSorting: Boolean;
begin
  Result := SubClass.GetSortByList.Count > 1;
end;

function TACLTreeListColumnViewInfo.GetNodeViewInfo: TACLTreeListNodeViewInfo;
begin
  Result := SubClass.ViewInfo.Content.NodeViewInfo;
end;

{ TACLTreeListColumnBarViewInfo }

function TACLTreeListColumnBarViewInfo.GetColumnViewInfo(
  AColumn: TACLTreeListColumn; out AViewInfo: TACLTreeListColumnViewInfo): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to ChildCount - 1 do
    if Children[I].Column = AColumn then
    begin
      AViewInfo := Children[I];
      Exit(True);
    end;
end;

function TACLTreeListColumnBarViewInfo.MeasureHeight: Integer;
begin
  Result := SubClass.OptionsView.Columns.Height;
  if Result = tlAutoHeight then
    Result := CalculateAutoHeight
  else
    Result := dpiApply(Result, CurrentDpi);
end;

function TACLTreeListColumnBarViewInfo.MeasureWidth: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to ChildCount - 1 do
    Inc(Result, Children[I].ActualWidth);
end;

function TACLTreeListColumnBarViewInfo.AddColumnCell(AColumn: TACLTreeListColumn): TACLTreeListColumnViewInfo;
begin
  Result := CreateColumnViewInfo(AColumn);
  Result.FAbsoluteIndex := AColumn.Index;
  Result.FVisibleIndex := ChildCount;
  FChildren.Add(Result);
end;

function TACLTreeListColumnBarViewInfo.CreateColumnViewInfo(AColumn: TACLTreeListColumn): TACLTreeListColumnViewInfo;
begin
  Result := TACLTreeListColumnViewInfo.Create(SubClass, AColumn);
end;

function TACLTreeListColumnBarViewInfo.CalculateAutoHeight: Integer;
begin
  SubClass.StylePrepareFont(MeasureCanvas, TACLStyleTreeList.IndexColumnHeaderFont);
  Result := SubClass.Style.ColumnHeader.ContentOffsets.MarginsHeight +
    Max(SubClass.Style.CheckMark.FrameHeight, acFontHeight(MeasureCanvas));
end;

procedure TACLTreeListColumnBarViewInfo.CalculateAutoWidth(const R: TRect);
var
  ADelta: Integer;
  AList: TList;
  AOverlap: Integer;
  AOverlapPrev: Integer;
  APrevWidth: Integer;
  AViewInfo: TACLTreeListColumnViewInfo;
  I: Integer;
begin
  AList := GetResizableColumnsList;
  try
    if AList.Count > 0 then
    begin
      AOverlap := 0;
      repeat
        AOverlapPrev := AOverlap;
        AOverlap := R.Width - MeasureWidth;
        ADelta := AOverlap div AList.Count;
        if ADelta = 0 then
          ADelta := Sign(AOverlap);
        for I := 0 to AList.Count - 1 do
        begin
          if AOverlap = 0 then Break;
          AViewInfo := TACLTreeListColumnViewInfo(AList[I]);
          APrevWidth := AViewInfo.ActualWidth;
          AViewInfo.ActualWidth := Max(tlColumnMinWidth, AViewInfo.ActualWidth + ADelta);
          Dec(AOverlap, AViewInfo.ActualWidth - APrevWidth);
        end;
      until AOverlap = AOverlapPrev;
    end;
  finally
    AList.Free;
  end;
end;

procedure TACLTreeListColumnBarViewInfo.CalculateChildren(R: TRect; const AChanges: TIntegerSet);
var
  I: Integer;
  LRect: TRect;
  LViewInfo: TACLTreeListColumnViewInfo;
begin
  for I := 0 to ChildCount - 1 do
    Children[I].InitializeActualWidth;

  if SubClass.OptionsView.Columns.AutoWidth then
  begin
    if sbVertical in SubClass.ViewInfo.Content.VisibleScrollBars then
      R.Right := SubClass.ViewInfo.Content.ScrollBarVert.Bounds.Left;
    CalculateAutoWidth(R);
  end;

  for I := 0 to ChildCount - 1 do
  begin
    LRect := R;
    LViewInfo := Children[I];
    LRect.Width := LViewInfo.ActualWidth;
    LViewInfo.Calculate(LRect, AChanges);
    R.Left := LViewInfo.Bounds.Right;
  end;
end;

procedure TACLTreeListColumnBarViewInfo.DoCalculate(AChanges: TIntegerSet);
begin
  inherited DoCalculate(AChanges);
  CalculateChildren(Bounds, AChanges);
end;

procedure TACLTreeListColumnBarViewInfo.DoDraw(ACanvas: TCanvas);
const
  BordersMap: array[Boolean] of TACLBorders = ([mTop, mBottom], [mBottom]);
begin
  if not SubClass.DoCustomDrawColumnBar(ACanvas, Bounds) then
  begin
    inherited DoDraw(ACanvas);
    SubClass.Style.DrawHeader(ACanvas, GetFreeSpaceArea, BordersMap[mTop in SubClass.OptionsView.Borders]);
  end;
end;

procedure TACLTreeListColumnBarViewInfo.RecreateSubCells;
var
  AColumn: TACLTreeListColumn;
  I: Integer;
begin
  for I := 0 to SubClass.Columns.Count - 1 do
  begin
    AColumn := SubClass.Columns.ItemsByDrawingIndex[I];
    if AColumn.Visible then
      AddColumnCell(AColumn);
  end;
end;

function TACLTreeListColumnBarViewInfo.GetChild(Index: Integer): TACLTreeListColumnViewInfo;
begin
  Result := TACLTreeListColumnViewInfo(inherited Children[Index]);
end;

function TACLTreeListColumnBarViewInfo.GetFreeSpaceArea: TRect;
begin
  Result := Bounds;
  if ChildCount > 0 then
    Result.Left := Children[ChildCount - 1].Bounds.Right;
end;

function TACLTreeListColumnBarViewInfo.GetResizableColumnsList: TList;
var
  ACell: TACLTreeListColumnViewInfo;
  I: Integer;
begin
  Result := TList.Create;
  Result.Capacity := ChildCount;
  for I := 0 to ChildCount - 1 do
  begin
    ACell := Children[I];
    if ACell.Column.CanResize then
      Result.Add(ACell);
  end;
end;

function TACLTreeListColumnBarViewInfo.GetSubClass: TACLTreeListSubClass;
begin
  Result := inherited SubClass as TACLTreeListSubClass;
end;

{ TACLTreeListContentCell }

procedure TACLTreeListContentCell.OnHotTrack(Action: TACLHotTrackAction);
var
  ASubClass: TACLTreeListSubClass;
begin
  ASubClass := TACLTreeListContentCellViewInfo(ViewInfo).SubClass;
  if ASubClass.OptionsBehavior.HotTrack or (Action = htaSwitchPart) then
    ASubClass.InvalidateRect(Bounds);
end;

{ TACLTreeListContentCellViewInfo }

constructor TACLTreeListContentCellViewInfo.Create(AOwner: TACLTreeListContentViewInfo);
begin
  inherited Create(AOwner);
  FOwner := AOwner;
  FSubClass := AOwner.SubClass;
end;

function TACLTreeListContentCellViewInfo.IsFocused: Boolean;
begin
  Result := (FData <> nil) and (FData = SubClass.FocusedObject) and SubClass.Focused;
end;

function TACLTreeListContentCellViewInfo.GetFocusRectColor: TColor;
begin
  Result := SubClass.Style.FocusRectColor.AsColor;
end;

{ TACLTreeListGroupViewInfo }

procedure TACLTreeListGroupViewInfo.Calculate(AWidth, AHeight: Integer);
begin
  inherited Calculate(AWidth, AHeight);
  FExpandButtonVisible := SubClass.OptionsBehavior.GroupsAllowCollapse;
  FTextRect := Bounds;
  FTextRect.Content(GetContentOffsets);
  CalculateExpandButton(FTextRect);
  CalculateCheckBox(FTextRect);
  FBackgroundBounds := Bounds;
//  if tlglHorzontal in Owner.OptionsView.Nodes.GridLines then
    Dec(FBackgroundBounds.Top);
end;

function TACLTreeListGroupViewInfo.CalculateAutoHeight: Integer;
begin
  SubClass.StylePrepareFont(MeasureCanvas, TACLStyleTreeList.IndexGroupHeaderFont);
  Result := acFontHeight(MeasureCanvas) + GetContentOffsets.MarginsHeight;
end;

procedure TACLTreeListGroupViewInfo.Initialize(AData: TObject);
var
  AWidth: Integer;
begin
  inherited Initialize(AData);
  //#AI: to display the ExpandButton in visible area always
  if (AData <> nil) and ExpandButtonVisible then
  begin
    AWidth := Owner.ClientBounds.Width + Owner.ViewportX;
    if AWidth <> Bounds.Width then
      Calculate(AWidth, Bounds.Height);
  end;
end;

procedure TACLTreeListGroupViewInfo.CalculateCheckBox(var R: TRect);
begin
  FCheckBoxRect := Owner.NodeViewInfo.CheckBoxRect;
  FCheckBoxRect.SetLocation(FCheckBoxRect.Left, (R.Top + R.Bottom - CheckBoxRect.Height) div 2);
  R.Left := CheckBoxRect.Left + GetElementWidthIncludeOffset(CheckBoxRect, SubClass.CurrentDpi);
end;

procedure TACLTreeListGroupViewInfo.CalculateExpandButton(var R: TRect);
var
  LSize: TSize;
begin
  if ExpandButtonVisible then
  begin
    LSize := SubClass.Style.GroupHeaderExpandButton.FrameSize;
    FExpandButtonRect := R.Split(srRight, LSize.cx);
    FExpandButtonRect.CenterVert(LSize.cy);
    R.Right := ExpandButtonRect.Right - GetElementWidthIncludeOffset(ExpandButtonRect, SubClass.CurrentDpi);
  end;
end;

procedure TACLTreeListGroupViewInfo.DoDraw(ACanvas: TCanvas);
begin
  SubClass.StylePrepareFont(ACanvas, TACLStyleTreeList.IndexGroupHeaderFont);
  SubClass.Style.DrawGroupHeader(ACanvas, BackgroundBounds);
  SubClass.Style.DrawCheckMark(ACanvas, CheckBoxRect, CheckBoxState, Group.CheckBoxState);
  if ExpandButtonVisible then
    SubClass.Style.DrawGroupExpandButton(ACanvas, ExpandButtonRect, Group.Expanded);
  acTextDraw(ACanvas, Group.Caption, TextRect, taLeftJustify, taVerticalCenter, True);
end;

function TACLTreeListGroupViewInfo.GetCheckBoxState: TACLButtonState;
begin
  Result := SubClass.CalculateState(Group, cchtCheckable)
end;

function TACLTreeListGroupViewInfo.GetContentOffsets: TRect;
begin
  Result := dpiApply(SubClass.Style.GroupHeaderContentOffsets.Value, SubClass.CurrentDpi);
end;

function TACLTreeListGroupViewInfo.GetFocusRect: TRect;
begin
  Result := inherited GetFocusRect;
  Dec(Result.Bottom);
end;

function TACLTreeListGroupViewInfo.HasFocusRect: Boolean;
begin
  Result := IsFocused and SubClass.Focused;
end;

function TACLTreeListGroupViewInfo.CreateDragObject(
  const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
begin
  Result := TACLTreeListGroupDragObject.Create(TACLTreeListHitTest(AHitTestInfo).Group);
end;

function TACLTreeListGroupViewInfo.GetGroup: TACLTreeListGroup;
begin
  Result := TACLTreeListGroup(FData);
end;

{ TACLTreeListNodeViewInfo }

procedure TACLTreeListNodeViewInfo.Calculate(AWidth, AHeight: Integer);
var
  AHasGridlineColor: Boolean;
begin
  AHasGridlineColor := SubClass.Style.GridColor.Value.IsValid;
  FHasHorzSeparators := (tlglHorzontal in OptionsNodes.GridLines) and AHasGridlineColor;
  FHasVertSeparators := (tlglVertical in OptionsNodes.GridLines) and AHasGridlineColor;

  inherited Calculate(AWidth, AHeight);

  FTextExtends[True] := GetContentOffsets;
  FTextExtends[False] := FTextExtends[True];

  CalculateExpandButtonRect;
  CalculateCheckBoxRect;
  CalculateImageRect;
end;

function TACLTreeListNodeViewInfo.CalculateAutoHeight: Integer;
begin
  SubClass.StylePrepareFont(MeasureCanvas);
  Result := acFontHeight(MeasureCanvas) + GetContentOffsets.MarginsHeight;
end;

function TACLTreeListNodeViewInfo.CalculateCellAutoWidth(
  ACanvas: TCanvas; ANode: TACLTreeListNode; AColumnIndex: Integer;
  AColumnViewInfo: TACLTreeListColumnViewInfo = nil): Integer;
var
  AText: string;
  ATextAlign: TAlignment;
begin
  Initialize(ANode);
  AText := ANode[AColumnIndex];
  SubClass.StylePrepareFont(ACanvas);
  SubClass.DoGetNodeCellDisplayText(ANode, AColumnIndex, AText);
  SubClass.DoGetNodeCellStyle(ACanvas.Font, ANode, GetColumnForViewInfo(AColumnViewInfo), ATextAlign);
  Result := acTextSize(ACanvas, AText).cx + CellTextExtends[AColumnViewInfo].MarginsWidth;
end;

function TACLTreeListNodeViewInfo.CalculateCellAutoWidth(
  ANode: TACLTreeListNode; AColumn: TACLTreeListColumn): Integer;
var
  AList: TACLTreeListNodeList;
begin
  AList := TACLTreeListNodeList.Create;
  try
    AList.Capacity := 1;
    AList.Add(ANode);
    Result := CalculateCellAutoWidth(AList, AColumn);
  finally
    AList.Free;
  end;
end;

function TACLTreeListNodeViewInfo.CalculateCellAutoWidth(
  ANodes: TACLTreeListNodeList; AColumn: TACLTreeListColumn): Integer;
var
  AColumnViewInfo: TACLTreeListColumnViewInfo;
begin
  if ColumnBarViewInfo.GetColumnViewInfo(AColumn, AColumnViewInfo) then
    Result := CalculateCellAutoWidth(ANodes, AColumn.Index, AColumnViewInfo)
  else
    Result := 0;
end;

function TACLTreeListNodeViewInfo.CalculateCellAutoWidth(
  ANodes: TACLTreeListNodeList; AColumnIndex: Integer; AColumnViewInfo: TACLTreeListColumnViewInfo = nil): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to ANodes.Count - 1 do
    Result := Max(Result, CalculateCellAutoWidth(MeasureCanvas, ANodes[I], AColumnIndex, AColumnViewInfo));
end;

function TACLTreeListNodeViewInfo.GetCellIndexAtPoint(const P: TPoint; out ACellIndex: Integer): Boolean;
var
  I: Integer;
begin
  for I := 0 to CellCount - 1 do
    if PtInRect(CellRect[I], P) then
    begin
      ACellIndex := I;
      Exit(True);
    end;
  Result := False;
end;

procedure TACLTreeListNodeViewInfo.CalculateCheckBoxRect;
begin
  FCheckBoxRect := PlaceLeftAlignedElement(SubClass.Style.CheckMark.FrameSize, SubClass.OptionsView.CheckBoxes);
end;

procedure TACLTreeListNodeViewInfo.CalculateExpandButtonRect;
begin
  if Owner.HasSubLevels then
    Inc(FTextExtends[True].Left, Owner.GetLevelIndent * Level);
  FExpandButtonRect := PlaceLeftAlignedElement(SubClass.Style.RowExpandButton.FrameSize, Owner.HasSubLevels);
end;

procedure TACLTreeListNodeViewInfo.CalculateImageRect;
var
  LCellRect: TRect;
  LSize: TSize;
begin
  LSize := acGetImageListSize(OptionsNodes.Images, SubClass.CurrentDpi);
  LCellRect := CellRect[0];
  LCellRect.CenterVert(LSize.cy);

  case OptionsNodes.ImageAlignment of
    taCenter:
      begin
        FImageRect := LCellRect;
        FImageRect.Content(CellTextExtends[nil]);
        FImageRect.CenterHorz(LSize.cx);
      end;

    taLeftJustify:
      begin
        FImageRect := LCellRect.Split(srLeft, FTextExtends[True].Left, LSize.cx);
        Inc(FTextExtends[True].Left, GetElementWidthIncludeOffset(ImageRect, SubClass.CurrentDpi));
      end;

    taRightJustify:
      begin
        FImageRect := LCellRect.Split(srRight, LCellRect.Right - FTextExtends[True].Right, LSize.cx);
        Inc(FTextExtends[True].Right, GetElementWidthIncludeOffset(ImageRect, SubClass.CurrentDpi));
      end;
  end;
end;

procedure TACLTreeListNodeViewInfo.DoGetHitTest(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo);
var
  ACellAutoWidth: Integer;
  ACellIndex: Integer;
  ACellRect: TRect;
  ACellTextRect: TRect;
  AColumnViewInfo: TACLTreeListColumnViewInfo;
  AHitTest: TACLTreeListHitTest;
begin
  if GetCellIndexAtPoint(P, ACellIndex) then
  begin
    AHitTest := TACLTreeListHitTest(AInfo);

    AColumnViewInfo := CellColumnViewInfo[ACellIndex];
    ACellRect := GetCellRect(AColumnViewInfo);
    ACellAutoWidth := CalculateCellAutoWidth(MeasureCanvas,
      Node, GetColumnAbsoluteIndex(AColumnViewInfo), AColumnViewInfo);
    ACellTextRect := ACellRect.Split(CellTextExtends[AColumnViewInfo]);
    AHitTest.ColumnViewInfo := AColumnViewInfo;

    if ACellAutoWidth > ACellRect.Width then
    begin
      AHitTest.HintData.Text := Node[GetColumnAbsoluteIndex(AColumnViewInfo)];
      AHitTest.HintData.ScreenBounds := SubClass.ClientToScreen(ACellTextRect + AOrigin);
    end;

    if PtInRect(ACellTextRect, P) then
      AHitTest.IsText := True
    else
      if ACellIndex = 0 then
      begin
        if PtInRect(ImageRect, P) then
          AHitTest.IsImage := True
        else
          inherited DoGetHitTest(P - ACellRect.TopLeft, AOrigin, AHitTest);
      end;

    DoGetHitTestSubPart(P, AOrigin, AHitTest,
      ACellAutoWidth - CellTextExtends[AColumnViewInfo].MarginsWidth,
      ACellRect, ACellTextRect, AColumnViewInfo);
  end;
end;

procedure TACLTreeListNodeViewInfo.DoGetHitTestSubPart(
  const P, AOrigin: TPoint; AInfo: TACLHitTestInfo; ACellTextWidth: Integer;
  const ACellRect, ACellTextRect: TRect; AColumnViewInfo: TACLTreeListColumnViewInfo);
begin
  // do nothing
end;

function TACLTreeListNodeViewInfo.GetCellTextExtends(AColumn: TACLTreeListColumnViewInfo): TRect;
begin
  Result := FTextExtends[IsFirstColumn(AColumn)];
end;

function TACLTreeListNodeViewInfo.GetCheckBoxState: TACLButtonState;
begin
  if Node.CheckMarkEnabled then
    Result := SubClass.CalculateState(Node, cchtCheckable)
  else
    Result := absDisabled;
end;

function TACLTreeListNodeViewInfo.GetColumnAbsoluteIndex(AColumnViewInfo: TACLTreeListColumnViewInfo): Integer;
begin
  if AColumnViewInfo <> nil then
    Result := AColumnViewInfo.AbsoluteIndex
  else
    Result := 0;
end;

function TACLTreeListNodeViewInfo.GetFocusRect: TRect;
var
  AViewInfo: TACLTreeListColumnViewInfo;
begin
  if ColumnBarViewInfo.GetColumnViewInfo(SubClass.FocusedColumn, AViewInfo) then
    Result := GetCellRect(AViewInfo)
  else
    Result := inherited GetFocusRect;
end;

function TACLTreeListNodeViewInfo.HasFocusRect: Boolean;
begin
  Result := IsFocused and not Node.Selected;
end;

function TACLTreeListNodeViewInfo.IsCheckBoxEnabled: Boolean;
begin
  Result := Node.CheckMarkEnabled;
end;

function TACLTreeListNodeViewInfo.DoCustomDraw(ACanvas: TCanvas): Boolean;
begin
  Result := (Node <> nil) and SubClass.DoCustomDrawNode(ACanvas, Bounds, Node);
end;

function TACLTreeListNodeViewInfo.DoCustomDrawCell(
  ACanvas: TCanvas; const R: TRect; AColumn: TACLTreeListColumn): Boolean;
begin
  Result := (Node <> nil) and SubClass.DoCustomDrawNodeCell(ACanvas, R, Node, AColumn);
end;

procedure TACLTreeListNodeViewInfo.DoDraw(ACanvas: TCanvas);
var
  I: Integer;
begin
  acFillRect(ACanvas, Bounds, SubClass.StyleGetNodeBackgroundColor(Odd(AbsoluteNodeIndex), Node));
  if IsFocused and (SubClass.FocusedColumn <> nil) and SubClass.Focused then
    acFillRect(ACanvas, GetFocusRect, SubClass.Style.RowColorFocused.Value);
  if HasHorzSeparators then
    SubClass.Style.DrawGridline(ACanvas, GetBottomSeparatorRect, mBottom);

  SubClass.StylePrepareFont(ACanvas);
  ACanvas.Font.Color := SubClass.StyleGetNodeTextColor(Node);

  if not DoCustomDraw(ACanvas) then
  begin
    for I := 0 to CellCount - 1 do
      DoDrawCell(ACanvas, CellRect[I], CellColumnViewInfo[I]);
  end;
end;

procedure TACLTreeListNodeViewInfo.DoDrawCell(
  ACanvas: TCanvas; const R: TRect; AColumnViewInfo: TACLTreeListColumnViewInfo);
var
  ASaveIndex: HRGN;
begin
  if acRectVisible(ACanvas, R) then
  begin
    if Node <> nil then
    begin
      ASaveIndex := acSaveClipRegion(ACanvas.Handle);
      try
        if acIntersectClipRegion(ACanvas.Handle, R) then
          DoDrawCellContent(ACanvas, R, AColumnViewInfo);
      finally
        acRestoreClipRegion(ACanvas.Handle, ASaveIndex);
      end;
    end;
    if HasVertSeparators and (AColumnViewInfo <> nil) and (mRight in AColumnViewInfo.Borders) then
      SubClass.Style.DrawGridline(ACanvas, R, mRight);
  end;
end;

procedure TACLTreeListNodeViewInfo.DoDrawCellContent(
  ACanvas: TCanvas; const R: TRect; AColumnViewInfo: TACLTreeListColumnViewInfo);
var
  AAlignment: TAlignment;
  AValue: string;
  AValueIndex: Integer;
begin
  if not DoCustomDrawCell(ACanvas, R, GetColumnForViewInfo(AColumnViewInfo)) then
  begin
    if IsFirstColumn(AColumnViewInfo) then
    begin
      if ExpandButtonVisible then
        SubClass.Style.DrawRowExpandButton(ACanvas, ExpandButtonRect, Node.Expanded, Node.Selected);
      if not CheckBoxRect.IsEmpty then
        SubClass.Style.DrawCheckMark(ACanvas, CheckBoxRect, CheckBoxState, Node.CheckState);
      if not ImageRect.IsEmpty then
        DoDrawCellImage(ACanvas, ImageRect);
    end;
    AValueIndex := GetColumnAbsoluteIndex(AColumnViewInfo);
    AValue := Node.Values[AValueIndex];
    SubClass.DoGetNodeCellDisplayText(Node, AValueIndex, AValue);
    SubClass.DoGetNodeCellStyle(ACanvas.Font, Node, GetColumnForViewInfo(AColumnViewInfo), AAlignment);
    DoDrawCellValue(ACanvas, R.Split(CellTextExtends[AColumnViewInfo]), AValue, AValueIndex, AAlignment);
  end;
end;

procedure TACLTreeListNodeViewInfo.DoDrawCellImage(ACanvas: TCanvas; const ABounds: TRect);
begin
  acDrawImage(ACanvas, ABounds, OptionsNodes.Images, Node.ImageIndex);
end;

procedure TACLTreeListNodeViewInfo.DoDrawCellValue(ACanvas: TCanvas;
  const ABounds: TRect; const AValue: string; AValueIndex: Integer; AAlignment: TAlignment);
var
  AHighlightStart, AHighlightFinish: Integer;
begin
  if not SubClass.DoCustomDrawNodeCellValue(ACanvas, ABounds, Node, AValue, AValueIndex, AAlignment) then
  begin
    if IsFocused and SubClass.GetHighlightBounds(AValue, AValueIndex, AHighlightStart, AHighlightFinish) then
      acTextDrawHighlight(ACanvas, AValue, ABounds, AAlignment,
        taVerticalCenter, True, AHighlightStart, AHighlightFinish,
        SubClass.Style.IncSearchColor.AsColor, SubClass.Style.IncSearchColorText.AsColor)
    else
      acTextDraw(ACanvas, AValue, ABounds, AAlignment, taVerticalCenter, True);
  end;
end;

function TACLTreeListNodeViewInfo.CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
begin
  Result := TACLTreeListNodeDragObject.Create(TACLTreeListHitTest(AHitTestInfo).Node);
end;

function TACLTreeListNodeViewInfo.GetAbsoluteNodeIndex: Integer;
begin
  if FAbsoluteNodeIndex < 0 then
    FAbsoluteNodeIndex := Node.AbsoluteVisibleIndex;
  Result := FAbsoluteNodeIndex;
end;

function TACLTreeListNodeViewInfo.GetBottomSeparatorRect: TRect;
begin
  Result := Bounds;
  Result.Top := Result.Bottom;
  Result.Height := 1;
end;

function TACLTreeListNodeViewInfo.GetCellColumnViewInfo(Index: Integer): TACLTreeListColumnViewInfo;
begin
  if ColumnBarViewInfo.ChildCount > 0 then
    Result := ColumnBarViewInfo.Children[Index]
  else
    Result := nil;
end;

function TACLTreeListNodeViewInfo.GetCellCount: Integer;
begin
  Result := Max(1, ColumnBarViewInfo.ChildCount);
end;

function TACLTreeListNodeViewInfo.GetCellRect(AIndex: Integer): TRect;
begin
  Result := GetCellRect(CellColumnViewInfo[AIndex]);
end;

function TACLTreeListNodeViewInfo.GetCellRect(AViewInfo: TACLTreeListColumnViewInfo): TRect;
begin
  Result := Bounds;
  if AViewInfo <> nil then
  begin
    Result.Left := AViewInfo.Bounds.Left - ColumnBarViewInfo.Bounds.Left;
    Result.Width := AViewInfo.Bounds.Width;
  end;
end;

function TACLTreeListNodeViewInfo.GetColumnBarViewInfo: TACLTreeListColumnBarViewInfo;
begin
  Result := Owner.ColumnBarViewInfo;
end;

function TACLTreeListNodeViewInfo.GetColumnForViewInfo(AColumnViewInfo: TACLTreeListColumnViewInfo): TACLTreeListColumn;
begin
  if AColumnViewInfo <> nil then
    Result := AColumnViewInfo.Column
  else
    Result := nil;
end;

function TACLTreeListNodeViewInfo.GetContentOffsets: TRect;
begin
  Result := dpiApply(SubClass.Style.RowContentOffsets.Value, SubClass.CurrentDpi);
end;

function TACLTreeListNodeViewInfo.GetNode: TACLTreeListNode;
begin
  Result := TACLTreeListNode(FData)
end;

function TACLTreeListNodeViewInfo.GetOptionsNodes: TACLTreeListOptionsViewNodes;
begin
  Result := SubClass.OptionsView.Nodes;
end;

function TACLTreeListNodeViewInfo.IsFirstColumn(AColumnViewInfo: TACLTreeListColumnViewInfo): Boolean;
begin
  Result := (AColumnViewInfo = nil) or AColumnViewInfo.IsFirst;
end;

function TACLTreeListNodeViewInfo.MeasureHeight: Integer;
begin
  Result := FHeight;
  if Node <> nil then
    SubClass.DoGetNodeHeight(Node, Result);
  if HasHorzSeparators then
    Inc(Result);
end;

procedure TACLTreeListNodeViewInfo.Initialize(AData: TObject);
begin
  inherited Initialize(AData);

  if Node <> nil then
  begin
    FAbsoluteNodeIndex := -1;
    FExpandButtonVisible := Node.HasChildren;
    Level := Node.Level;
  end
  else
    Level := 0;
end;

procedure TACLTreeListNodeViewInfo.Initialize(AData: TObject; AHeight: Integer);
begin
  inherited Initialize(AData, AHeight - Ord(HasHorzSeparators));
end;

function TACLTreeListNodeViewInfo.PlaceLeftAlignedElement(ASize: TSize; AVisible: Boolean): TRect;
begin
  if not AVisible then
    ASize := NullSize;
  Result := Bounds;
  Result.CenterVert(ASize.cy);
  Result := Result.Split(srLeft, FTextExtends[True].Left, ASize.cx);
  Inc(FTextExtends[True].Left, GetElementWidthIncludeOffset(Result, SubClass.CurrentDpi));
end;

procedure TACLTreeListNodeViewInfo.SetLevel(AValue: Integer);
begin
  AValue := Max(AValue, 0);
  if FLevel <> AValue then
  begin
    FLevel := AValue;
    Calculate;
  end;
end;

{ TACLTreeListDropTargetViewInfo }

constructor TACLTreeListDropTargetViewInfo.Create(AOwner: TACLTreeListContentViewInfo);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TACLTreeListDropTargetViewInfo.Calculate;
var
  ACell: TACLCompoundControlBaseContentCell;
  AObject: TObject;
begin
  FBounds := NullRect;

  AObject := CalculateActualTargetObject;
  if (AObject <> nil) and Owner.ViewItems.Find(AObject, ACell) then
  begin
    FBounds := ACell.Bounds;
    if Owner.ViewItems.Find(DropTargetObject, ACell) then
    begin
      FBounds.Left := ACell.Bounds.Left;
      FBounds.Right := ACell.Bounds.Right;
      if ACell.ViewInfo = Owner.NodeViewInfo then
      begin
        Owner.NodeViewInfo.Initialize(ACell.Data);
        FBounds.Left := Owner.NodeViewInfo.CheckBoxRect.Left;
      end;
    end;
    CalculateBounds(FBounds);
  end;
end;

procedure TACLTreeListDropTargetViewInfo.Draw(ACanvas: TCanvas);
var
  AColor: TAlphaColor;
begin
  if not Bounds.IsEmpty then
  begin
    AColor := Owner.SubClass.Style.RowColorText.Value;
    if FInsertMode = dtimOver then
      acDrawFrame(ACanvas, Bounds, AColor, MeasureHeight)
    else
      acFillRect(ACanvas, Bounds, AColor);
  end;
end;

procedure TACLTreeListDropTargetViewInfo.Invalidate;
begin
  Owner.SubClass.InvalidateRect(Bounds);
end;

function TACLTreeListDropTargetViewInfo.MeasureHeight: Integer;
begin
  Result := dpiApply(3, Owner.CurrentDpi);
end;

function TACLTreeListDropTargetViewInfo.CalculateActualTargetObject: TObject;
var
  AExpandable: IACLExpandableObject;
begin
  Result := DropTargetObject;
  if DragAndDropController.DropTargetObjectInsertMode = dtimAfter then
  begin
    while Supports(Result, IACLExpandableObject, AExpandable) and AExpandable.Expanded do
    begin
      if Result is TACLTreeListGroup then
        Result := TACLTreeListGroup(Result).Links.Last
      else
        if Result is TACLTreeListNode then
        begin
          if TACLTreeListNode(Result).ChildrenCount > 0 then
            Result := TACLTreeListNode(Result).Children[TACLTreeListNode(Result).ChildrenCount - 1]
          else
            Break;
        end;
    end;
  end;
end;

procedure TACLTreeListDropTargetViewInfo.CalculateBounds(const ACellBounds: TRect);
begin
  FBounds := ACellBounds;
  FInsertMode := DragAndDropController.DropTargetObjectInsertMode;
  case FInsertMode of
    dtimBefore:
      FBounds.Height := 0;
    dtimAfter:
      FBounds := FBounds.Split(srBottom, 0);
    dtimInto:
      FBounds := Rect(FBounds.Left + 4 * Owner.GetLevelIndent, FBounds.Bottom, FBounds.Right, FBounds.Bottom);
    dtimOver:
      Exit;
  end;
  FBounds.CenterVert(MeasureHeight);
end;

function TACLTreeListDropTargetViewInfo.GetDragAndDropController: TACLTreeListDragAndDropController;
begin
  Result := FOwner.SubClass.DragAndDropController;
end;

function TACLTreeListDropTargetViewInfo.GetDropTargetObject: TObject;
begin
  Result := DragAndDropController.DropTargetObject;
end;

{ TACLTreeListContentViewInfo }

constructor TACLTreeListContentViewInfo.Create(AOwner: TACLCompoundControlSubClass);
begin
  inherited Create(AOwner);
  FMeasuredGroupHeight := -1;
  FMeasuredNodeHeight := -1;
  FAbsoluteVisibleNodes := TACLTreeListNodeList.Create;
  FDropTargetViewInfo := CreateDropTargetViewInfo;
  FColumnBarViewInfo := CreateColumnBarViewInfo;
  FGroupViewInfo := CreateGroupViewInfo;
  FNodeViewInfo := CreateNodeViewInfo;
  FViewItems := CreateViewItems;
end;

destructor TACLTreeListContentViewInfo.Destroy;
begin
  FreeAndNil(FDropTargetViewInfo);
  FreeAndNil(FAbsoluteVisibleNodes);
  FreeAndNil(FColumnBarViewInfo);
  FreeAndNil(FGroupViewInfo);
  FreeAndNil(FNodeViewInfo);
  FreeAndNil(FViewItems);
  inherited Destroy;
end;

function TACLTreeListContentViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  Result := inherited CalculateHitTest(AInfo);
  if Result and (AInfo.HitObject = Self) then
  begin
    if not ColumnBarViewInfo.CalculateHitTest(AInfo) then
      ViewItems.CalculateHitTest(AInfo);
  end;
end;

function TACLTreeListContentViewInfo.CalculateScrollDelta(AObject: TObject;
  AMode: TACLScrollToMode; out ADelta: TPoint; AColumn: TACLTreeListColumn = nil): Boolean;
var
  ACell: TACLCompoundControlBaseContentCell;
  AColumnViewInfo: TACLTreeListColumnViewInfo;
begin
  Result := ViewItems.Find(AObject, ACell);
  if Result then
  begin
    if (AColumn = nil) or not ColumnBarViewInfo.GetColumnViewInfo(AColumn, AColumnViewInfo) then
      AColumnViewInfo := nil;
    ADelta := CalculateScrollDeltaCore(ACell, AMode, ViewItemsArea, AColumnViewInfo);
  end
  else
    ADelta := NullPoint;
end;

function TACLTreeListContentViewInfo.CalculateScrollDeltaCore(
  ACell: TACLCompoundControlBaseContentCell; AMode: TACLScrollToMode;
  const AArea: TRect; AColumn: TACLTreeListColumnViewInfo = nil): TPoint;
begin
  Result.Y := acCalculateScrollToDelta(ACell.Bounds.Top, ACell.Bounds.Bottom, AArea.Top, AArea.Bottom, AMode);
  if AColumn <> nil then
    Result.X := acCalculateScrollToDelta(AColumn.Bounds.Left, AColumn.Bounds.Right, AArea.Left, AArea.Right, TACLScrollToMode.MakeVisible)
  else
    Result.X := 0;
end;

function TACLTreeListContentViewInfo.FindNearestNode(const P: TPoint; ADirection: Integer): TACLTreeListNode;
var
  ACell: TACLCompoundControlBaseContentCell;
  ADistance: Integer;
  AIndex: Integer;
  AMinDistance: Integer;
begin
  Result := nil;
  AMinDistance := MaxInt;
  for AIndex := 0 to ViewItems.Count - 1 do
  begin
    ACell := ViewItems.List[AIndex];
    if ADirection < 0 then
    begin
      if ACell.Top > P.Y then
        Continue;
      ADistance := P.Y - ACell.Top;
    end
    else
    begin
      if ACell.Top + ACell.Height < P.Y then
        Continue;
      ADistance := ACell.Top + ACell.Height - P.Y;
    end;

    if (ADistance < AMinDistance) and (ACell.Data is TACLTreeListNode) then
    begin
      AMinDistance := ADistance;
      Result := TACLTreeListNode(ACell.Data);
    end;
  end;
end;

function TACLTreeListContentViewInfo.IsObjectVisible(AObject: TObject; AColumn: TACLTreeListColumn = nil): Boolean;
var
  ADelta: TPoint;
begin
  Result := CalculateScrollDelta(AObject, TACLScrollToMode.MakeVisible, ADelta, AColumn) and (ADelta = NullPoint);
end;

procedure TACLTreeListContentViewInfo.ScrollByLines(ALines: Integer; ADirection: TACLMouseWheelDirection);
var
  AOffset: Integer;
begin
  while ALines > 0 do
  begin
    if ADirection = mwdDown then
      AOffset :=  GetLineDownOffset
    else
      AOffset := -GetLineUpOffset;

    ViewportY := ViewportY + AOffset;
    ViewItems.UpdateVisibleBounds;
    Dec(ALines);
  end;
end;

function TACLTreeListContentViewInfo.GetActualColumnBarHeight: Integer;
begin
  if OptionsView.Columns.Visible then
    Result := ColumnBarViewInfo.MeasureHeight
  else
    Result := 0;
end;

function TACLTreeListContentViewInfo.GetActualGroupHeight: Integer;
begin
  Result := OptionsView.GroupHeight;
  if Result = tlAutoHeight then
  begin
    if FMeasuredGroupHeight = -1 then
      FMeasuredGroupHeight := GroupViewInfo.CalculateAutoHeight;
    Result := FMeasuredGroupHeight;
  end
  else
    Result := dpiApply(Result, CurrentDpi);
end;

function TACLTreeListContentViewInfo.GetActualNodeHeight: Integer;
begin
  Result := OptionsView.Nodes.Height;
  if Result = tlAutoHeight then
  begin
    if FMeasuredNodeHeight = -1 then
      FMeasuredNodeHeight := NodeViewInfo.CalculateAutoHeight;
    Result := FMeasuredNodeHeight;
  end
  else
    Result := dpiApply(Result, CurrentDpi);
end;

procedure TACLTreeListContentViewInfo.LockViewItemsPlacement;
begin
  Inc(FLockViewItemsPlacement);
end;

procedure TACLTreeListContentViewInfo.UnlockViewItemsPlacement;
begin
  Dec(FLockViewItemsPlacement);
end;

procedure TACLTreeListContentViewInfo.CalculateContentCellViewInfo;
begin
  NodeViewInfo.Initialize(nil);
  NodeViewInfo.Calculate(FContentSize.cx, GetActualNodeHeight); //#first

  GroupViewInfo.Initialize(nil);
  GroupViewInfo.Calculate(FContentSize.cx, GetActualGroupHeight);
end;

procedure TACLTreeListContentViewInfo.CalculateContentLayout;
begin
  FContentSize.cx := Max(MeasureContentWidth, ViewItemsArea.Width);
  CalculateContentCellViewInfo;
  if FLockViewItemsPlacement = 0 then
    CalculateViewItemsPlace;
  FContentSize.cy := ViewItems.GetContentSize;
  ColumnBarViewInfo.Calculate(GetColumnBarBounds, [cccnLayout]);
  DropTargetViewInfo.Calculate;
end;

function TACLTreeListContentViewInfo.CalculateHasSubLevels: Boolean;
var
  I: Integer;
begin
  for I := 0 to SubClass.RootNode.ChildrenCount - 1 do
  begin
    if SubClass.RootNode.Children[I].ChildrenCount > 0 then
      Exit(True);
  end;
  Result := False;
end;

procedure TACLTreeListContentViewInfo.CalculateSubCells(const AChanges: TIntegerSet);
var
  R: TRect;
begin
  inherited CalculateSubCells(AChanges);

  ColumnBarViewInfo.Calculate(GetColumnBarBounds, AChanges);
  FClientBounds.Top := ColumnBarViewInfo.Bounds.Bottom;

  R := Bounds;
  R.Top := ClientBounds.Top;
  CalculateScrollBarsPosition(R);
end;

procedure TACLTreeListContentViewInfo.DoCalculate(AChanges: TIntegerSet);
begin
  inherited DoCalculate(AChanges);
  if cccnLayout in AChanges then
  begin
    FMeasuredGroupHeight := -1;
    FMeasuredNodeHeight := -1;
  end;
  if cccnViewport in AChanges then
    ViewItems.UpdateVisibleBounds;
end;

procedure TACLTreeListContentViewInfo.CalculateViewItemsPlace;
var
  AItem: TACLTreeListContentCell;
  ATopOffset, I: Integer;
begin
  ATopOffset := 0;
  for I := 0 to ViewItems.Count - 1 do
  begin
    AItem := TACLTreeListContentCell(ViewItems.List[I]);
    AItem.FTop := ATopOffset;
    AItem.FHeight := AItem.MeasureHeight;
    Inc(ATopOffset, AItem.Height);
  end;
  ViewItems.UpdateVisibleBounds;
end;

function TACLTreeListContentViewInfo.GetColumnBarBounds: TRect;
begin
  Result := Bounds;
  Result.Height := GetActualColumnBarHeight;
  if not OptionsView.Columns.AutoWidth then
  begin
    Result := Result.Split(srLeft, Result.Left - ViewportX, ContentSize.cx);
    Result.Right := Max(Result.Right, Bounds.Right);
  end;
end;

function TACLTreeListContentViewInfo.MeasureContentWidth: Integer;
begin
  if (ColumnBarViewInfo.ChildCount > 0) or not OptionsBehavior.AutoBestFit then
    Result := ColumnBarViewInfo.MeasureWidth
  else
    Result := NodeViewInfo.CalculateCellAutoWidth(SubClass.AbsoluteVisibleNodes, 0);
end;

function TACLTreeListContentViewInfo.CreateColumnBarViewInfo: TACLTreeListColumnBarViewInfo;
begin
  Result := TACLTreeListColumnBarViewInfo.Create(SubClass);
end;

function TACLTreeListContentViewInfo.CreateDropTargetViewInfo: TACLTreeListDropTargetViewInfo;
begin
  Result := TACLTreeListDropTargetViewInfo.Create(Self);
end;

function TACLTreeListContentViewInfo.CreateGroupViewInfo: TACLTreeListGroupViewInfo;
begin
  Result := TACLTreeListGroupViewInfo.Create(Self);
end;

function TACLTreeListContentViewInfo.CreateNodeViewInfo: TACLTreeListNodeViewInfo;
begin
  Result := TACLTreeListNodeViewInfo.Create(Self);
end;

function TACLTreeListContentViewInfo.CreateViewItems: TACLCompoundControlContentCellList;
begin
  Result := TACLCompoundControlContentCellList.Create(Self, TACLTreeListContentCell);
end;

function TACLTreeListContentViewInfo.GetLineDownOffset: Integer;
var
  ACell: TACLCompoundControlBaseContentCell;
begin
  if ViewItems.GetCell(ViewItems.FirstVisible, ACell) then
    Result := Max(0, ACell.Bounds.Bottom - ViewItemsArea.Top)
  else
    Result := 0;
end;

function TACLTreeListContentViewInfo.GetLineUpOffset: Integer;
var
  ACell: TACLCompoundControlBaseContentCell;
begin
  Result := 0;
  if ViewItems.GetCell(ViewItems.FirstVisible, ACell) then
    Result := Max(0, ViewItemsArea.Top - ACell.Bounds.Top);
  if (Result = 0) and ViewItems.GetCell(ViewItems.FirstVisible - 1, ACell) then
    Result := Max(0, ViewItemsArea.Top - ACell.Bounds.Top);
end;

function TACLTreeListContentViewInfo.GetScrollInfo(AKind: TScrollBarKind; out AInfo: TACLScrollInfo): Boolean;
begin
  Result := inherited GetScrollInfo(AKind, AInfo);
  if AKind = sbVertical then
    AInfo.LineSize := NodeViewInfo.MeasureHeight;
end;

procedure TACLTreeListContentViewInfo.PopulateViewItems(ANode: TACLTreeListNode);
var
  AChildNode: TACLTreeListNode;
  AFilterProc: TACLTreeListNodeFilterFunc;
  AGroup: TACLTreeListGroup;
  AGroupsAllowCollapse: Boolean;
  I: Integer;
begin
  AGroup := nil;
  AGroupsAllowCollapse := SubClass.OptionsBehavior.GroupsAllowCollapse;

  if (SubClass.OptionsBehavior.IncSearchMode = ismFilter) and SubClass.IncSearch.Active then
    AFilterProc := SubClass.IncSearchContains
  else
    AFilterProc := nil;

  for I := 0 to ANode.ChildrenCount - 1 do
  begin
    AChildNode := ANode.Children[I];
    if Assigned(AFilterProc) and not AFilterProc(AChildNode) then
      Continue;
    if AGroup <> AChildNode.Group then
    begin
      ViewItems.Add(AChildNode.Group, GroupViewInfo);
      AGroup := AChildNode.Group;
    end;
    if (AGroup = nil) or AGroup.Expanded or not AGroupsAllowCollapse then
    begin
      AbsoluteVisibleNodes.Add(AChildNode);
      ViewItems.Add(AChildNode, NodeViewInfo);
      if AChildNode.Expanded then
        PopulateViewItems(AChildNode);
    end;
  end;
end;

procedure TACLTreeListContentViewInfo.RecreateSubCells;
begin
  ViewItems.Clear;
  ViewItems.Capacity := 10240;
  AbsoluteVisibleNodes.Clear;
  AbsoluteVisibleNodes.Capacity := 10240;
  PopulateViewItems(SubClass.RootNode);
  FHasSubLevels := CalculateHasSubLevels;
end;

function TACLTreeListContentViewInfo.CreateDragObject(
  const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
begin
  if ViewItems.Count > 0 then
    Result := TACLTreeListSelectionRectDragObject.Create(nil)
  else
    Result := nil;
end;

function TACLTreeListContentViewInfo.GetContentWidth: Integer;
begin
  Result := FContentSize.cx;
end;

function TACLTreeListContentViewInfo.GetViewItemsArea: TRect;
begin
  Result := FClientBounds;
end;

function TACLTreeListContentViewInfo.GetViewItemsOrigin: TPoint;
begin
  Result := Point(ViewItemsArea.Left - ViewportX, ViewItemsArea.Top - ViewportY);
end;

procedure TACLTreeListContentViewInfo.DoDrawCells(ACanvas: TCanvas);
begin
  ColumnBarViewInfo.Draw(ACanvas);
  if acIntersectClipRegion(ACanvas.Handle, ViewItemsArea) then
  begin
    ViewItems.Draw(ACanvas);
    DoDrawFreeSpaceBackground(ACanvas);
    DoDrawSelectionRect(ACanvas, SelectionRect + ViewItemsOrigin);
    DropTargetViewInfo.Draw(ACanvas);
  end;
end;

procedure TACLTreeListContentViewInfo.DoDrawFreeSpaceBackground(ACanvas: TCanvas);
var
  ARect: TRect;
begin
  ARect := TRect.Create(ViewItemsOrigin, ContentSize);
  if ViewItems.Count > 0 then
    ARect.Top := ViewItems.Last.Bounds.Bottom;

  NodeViewInfo.Initialize(nil);
  NodeViewInfo.FAbsoluteNodeIndex := AbsoluteVisibleNodes.Count;
  ARect.Height := NodeViewInfo.MeasureHeight;
  while ARect.Top < Bounds.Bottom do
  begin
    NodeViewInfo.Draw(ACanvas, nil, ARect);
    ARect.Offset(0, ARect.Height);
    Inc(NodeViewInfo.FAbsoluteNodeIndex);
  end;
end;

procedure TACLTreeListContentViewInfo.DoDrawSelectionRect(ACanvas: TCanvas; const R: TRect);
begin
  acDrawSelectionRect(ACanvas, R, SubClass.Style.SelectionRectColor.Value);
end;

function TACLTreeListContentViewInfo.GetFirstVisibleNode: TACLTreeListNode;
var
  ACell: TACLCompoundControlBaseContentCell;
begin
  if ViewItems.FindFirstVisible(ViewItems.FirstVisible, 1, TACLTreeListNode, ACell) then
    Result := TACLTreeListNode(ACell.Data)
  else
    Result := nil;
end;

function TACLTreeListContentViewInfo.GetLastVisibleNode: TACLTreeListNode;
var
  ACell: TACLCompoundControlBaseContentCell;
begin
  if ViewItems.FindFirstVisible(ViewItems.LastVisible, -1, TACLTreeListNode, ACell) then
    Result := TACLTreeListNode(ACell.Data)
  else
    Result := nil;
end;

function TACLTreeListContentViewInfo.GetLevelIndent: Integer;
begin
  Result := SubClass.Style.RowExpandButton.FrameWidth + dpiApply(acIndentBetweenElements, SubClass.CurrentDpi);
end;

function TACLTreeListContentViewInfo.GetOptionsBehavior: TACLTreeListOptionsBehavior;
begin
  Result := SubClass.OptionsBehavior;
end;

function TACLTreeListContentViewInfo.GetOptionsView: TACLTreeListOptionsView;
begin
  Result := SubClass.OptionsView;
end;

function TACLTreeListContentViewInfo.GetSubClass: TACLTreeListSubClass;
begin
  Result := TACLTreeListSubClass(inherited SubClass);
end;

procedure TACLTreeListContentViewInfo.SetSelectionRect(const AValue: TRect);
begin
  if AValue <> FSelectionRect then
  begin
    FSelectionRect := AValue;
    SubClass.Changed([cccnContent]);
  end;
end;

{ TACLTreeListViewInfo }

constructor TACLTreeListViewInfo.Create(AOwner: TACLCompoundControlSubClass);
begin
  inherited Create(AOwner);
  FContent := CreateContent;
end;

destructor TACLTreeListViewInfo.Destroy;
begin
  FreeAndNil(FContent);
  inherited Destroy;
end;

function TACLTreeListViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  Result := inherited CalculateHitTest(AInfo) and Content.CalculateHitTest(AInfo);
end;

function TACLTreeListViewInfo.CreateContent: TACLTreeListContentViewInfo;
begin
  Result := TACLTreeListContentViewInfo.Create(SubClass);
end;

function TACLTreeListViewInfo.GetContentBounds: TRect;
begin
  Result := Bounds;
  Result.Content(BorderWidths, Borders);
end;

procedure TACLTreeListViewInfo.DoCalculate(AChanges: TIntegerSet);
begin
  Content.Calculate(GetContentBounds, AChanges);
end;

procedure TACLTreeListViewInfo.DoDraw(ACanvas: TCanvas);
begin
  SubClass.Style.DrawBackground(ACanvas, Bounds, SubClass.EnabledContent, Borders);
  Content.Draw(ACanvas);
end;

function TACLTreeListViewInfo.GetBorders: TACLBorders;
begin
  Result := SubClass.OptionsView.Borders;
end;

function TACLTreeListViewInfo.GetBorderWidths: TRect;
begin
  Result := acBorderOffsets;
end;

{ TACLTreeListHitTest }

function TACLTreeListHitTest.HasAction: Boolean;
begin
  Result := IsCheckable or IsExpandable or IsResizable;
end;

function TACLTreeListHitTest.GetColumn: TACLTreeListColumn;
var
  AViewInfo: TACLTreeListColumnViewInfo;
begin
  Result := HitObjectData['Column'] as TACLTreeListColumn;
  if Result = nil then
  begin
    AViewInfo := GetColumnViewInfo;
    if AViewInfo <> nil then
      Result := AViewInfo.Column;
  end;
end;

function TACLTreeListHitTest.GetColumnViewInfo: TACLTreeListColumnViewInfo;
begin
  if HitAtNode then
    Result := HitObjectData['ColumnViewInfo'] as TACLTreeListColumnViewInfo
  else
    Result := HitObject as TACLTreeListColumnViewInfo;
end;

function TACLTreeListHitTest.GetHitAtColumn: Boolean;
begin
  Result := HitObject is TACLTreeListColumnViewInfo;
end;

function TACLTreeListHitTest.GetHitAtColumnBar: Boolean;
begin
  Result := HitObject is TACLTreeListColumnBarViewInfo;
end;

function TACLTreeListHitTest.GetHitAtContentArea: Boolean;
begin
  Result := HitObject is TACLTreeListContentViewInfo;
end;

function TACLTreeListHitTest.GetHitAtGroup: Boolean;
begin
  Result := HitObject is TACLTreeListGroup;
end;

function TACLTreeListHitTest.GetHitAtNode: Boolean;
begin
  Result := HitObject is TACLTreeListNode;
end;

function TACLTreeListHitTest.GetGroup: TACLTreeListGroup;
begin
  Result := TACLTreeListGroup(HitObject);
end;

function TACLTreeListHitTest.GetNode: TACLTreeListNode;
begin
  Result := TACLTreeListNode(HitObject);
end;

procedure TACLTreeListHitTest.SetColumn(const Value: TACLTreeListColumn);
begin
  HitObjectData['Column'] := Value;
end;

procedure TACLTreeListHitTest.SetColumnViewInfo(AViewInfo: TACLTreeListColumnViewInfo);
begin
  if HitAtNode then
    HitObjectData['ColumnViewInfo'] := AViewInfo
  else
    raise EInvalidOperation.Create(ClassName);
end;

{ TACLTreeListEditingController }

destructor TACLTreeListEditingController.Destroy;
begin
  Close;
  TACLMainThread.Unsubscribe(Self);
  inherited Destroy;
end;

function TACLTreeListEditingController.IsEditing: Boolean;
begin
  Result := Edit <> nil;
end;

function TACLTreeListEditingController.IsEditing(AItemIndex, AColumnIndex: Integer): Boolean;
begin
  Result := IsEditing and (FParams.ColumnIndex = AColumnIndex) and (FParams.RowIndex = AItemIndex);
end;

function TACLTreeListEditingController.IsEditing(ANode: TACLTreeListNode; AColumn: TACLTreeListColumn = nil): Boolean;
begin
  Result := IsEditing and (ANode.AbsoluteVisibleIndex = FParams.RowIndex) and ((AColumn = nil) or (AColumn.Index = FParams.ColumnIndex));
end;

function TACLTreeListEditingController.IsLocked: Boolean;
begin
  Result := FLockCount > 0;
end;

function TACLTreeListEditingController.IsModified: Boolean;
begin
  Result := IsEditing and (Value <> EditIntf.InplaceGetValue);
end;

procedure TACLTreeListEditingController.Apply;
begin
  if IsEditing then
    EditApplyHandler(Edit);
end;

procedure TACLTreeListEditingController.Cancel;
begin
  if IsEditing then
    Close;
end;

procedure TACLTreeListEditingController.StartEditing(ANode: TACLTreeListNode; AColumn: TACLTreeListColumn = nil);
begin
  Cancel;
  if SubClass.OptionsBehavior.Editing then
  begin
    Inc(FLockCount);
    try
      SubClass.FocusedColumn := AColumn;
      SubClass.HintController.Cancel;
      InitializeParams(ANode, AColumn);
      if SubClass.CreateInplaceEdit(FParams, FEdit) then
      begin
        if Supports(FEdit, IACLInplaceControl, FEditIntf) then
        begin
          EditIntf.InplaceSetValue(Value);
          EditIntf.InplaceSetFocus;
        end
        else
          Cancel;
      end;
    finally
      Dec(FLockCount);
    end;
  end;
end;

procedure TACLTreeListEditingController.Close(AChanges: TIntegerSet = []; AAccepted: Boolean = False);
begin
  if IsEditing and not IsLocked then
  begin
    FEditIntf := nil;
    if csDestroying in SubClass.ComponentState then
    begin
      FreeAndNil(FEdit);
      Exit;
    end;
    TACLMainThread.RunPostponed(FEdit.Free, Self);
    FEdit := nil;

    if AAccepted then // Sent notification after closing the editor to re-sort and re-group the list
      SubClass.NodeValuesChanged(FParams.ColumnIndex);
    if not (cccnViewport in AChanges) then
      SubClass.MakeVisible(SubClass.FocusedNode);
    if SubClass.Focused then
      SubClass.SetFocus;
  end;
end;

procedure TACLTreeListEditingController.InitializeParams(
  ANode: TACLTreeListNode; AColumn: TACLTreeListColumn = nil);

  procedure CalculateCellRect(var AParams: TACLInplaceInfo);
  var
    AColumnViewInfo: TACLTreeListColumnViewInfo;
    AColumnVisibleIndex: Integer;
    AContentCell: TACLCompoundControlBaseContentCell;
  begin
    if not ContentViewInfo.ViewItems.Find(ANode, AContentCell) then
      raise EACLTreeListException.Create(sErrorCannotEditHiddenCell);

    AColumnViewInfo := nil;
    AColumnVisibleIndex := 0;
    if AColumn <> nil then
    begin
      if ContentViewInfo.ColumnBarViewInfo.GetColumnViewInfo(AColumn, AColumnViewInfo) then
        AColumnVisibleIndex := AColumnViewInfo.VisibleIndex
      else
        raise EACLTreeListException.Create(sErrorCannotEditHiddenCell);
    end;

    ContentViewInfo.NodeViewInfo.Initialize(ANode);
    AParams.Bounds := ContentViewInfo.NodeViewInfo.CellRect[AColumnVisibleIndex];
    AParams.Bounds.Offset(AContentCell.Bounds.TopLeft);
    if ContentViewInfo.NodeViewInfo.HasVertSeparators then
      Dec(AParams.Bounds.Right);
    AParams.Bounds.Inflate(0, -1);
    AParams.TextBounds := AParams.Bounds;
    AParams.TextBounds.Content(ContentViewInfo.NodeViewInfo.CellTextExtends[AColumnViewInfo]);
  end;

begin
  FParams.Reset;
  if AColumn <> nil then
    FParams.ColumnIndex := AColumn.Index;
  FParams.RowIndex := ANode.AbsoluteVisibleIndex;
  FParams.OnApply := EditApplyHandler;
  FParams.OnKeyDown := EditKeyDownHandler;
  FParams.OnCancel := EditCancelHandler;
  FParams.Parent := SubClass.Container.GetControl;
  CalculateCellRect(FParams);
end;

function TACLTreeListEditingController.GetContentViewInfo: TACLTreeListContentViewInfo;
begin
  Result := SubClass.ViewInfo.Content;
end;

function TACLTreeListEditingController.GetSubClass: TACLTreeListSubClass;
begin
  Result := TACLTreeListSubClass(inherited SubClass);
end;

function TACLTreeListEditingController.GetValue: string;
begin
  Result := SubClass.AbsoluteVisibleNodes[FParams.RowIndex].Values[FParams.ColumnIndex];
end;

procedure TACLTreeListEditingController.SetValue(const AValue: string);
begin
  SubClass.AbsoluteVisibleNodes[FParams.RowIndex].Values[FParams.ColumnIndex] := AValue;
end;

procedure TACLTreeListEditingController.EditApplyHandler(Sender: TObject);
var
  ATempValue: string;
begin
  if not IsLocked and (Sender = Edit) then
  try
    Inc(FLockCount);
    try
      ATempValue := EditIntf.InplaceGetValue;
      SubClass.DoEditing(FParams.RowIndex, FParams.ColumnIndex, ATempValue);
      Value := ATempValue;
      SubClass.DoEdited(FParams.RowIndex, FParams.ColumnIndex);
    finally
      Dec(FLockCount);
    end;
  finally
    Close([], True);
  end;
end;

procedure TACLTreeListEditingController.EditKeyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Sender = Edit then
  begin
    SubClass.DoEditKeyDown(Key, Shift);
    case Key of
      VK_ESCAPE:
        EditCancelHandler(Sender);
      VK_RETURN:
        EditApplyHandler(Sender);
      VK_UP, VK_DOWN:
        if not ((Edit is TControl) and (TControl(Edit).Perform(WM_GETDLGCODE, 0, 0) and DLGC_WANTARROWS <> 0)) then
        begin
          EditApplyHandler(Sender);
          SubClass.KeyDown(Key, Shift);
          SubClass.KeyUp(Key, Shift);
        end;
    end;
  end;
end;

procedure TACLTreeListEditingController.EditCancelHandler(Sender: TObject);
begin
  if Sender = Edit then
    Close;
end;

{ TACLTreeListDragAndDropController }

destructor TACLTreeListDragAndDropController.Destroy;
begin
  FreeAndNil(FDropTarget);
  inherited Destroy;
end;

procedure TACLTreeListDragAndDropController.ProcessChanges(AChanges: TIntegerSet);
begin
  inherited ProcessChanges(AChanges);
  if tlcnSettingsDropTarget in AChanges then
  begin
    if not IsActive then
      UpdateDropTarget(nil);
  end;
end;

function TACLTreeListDragAndDropController.UpdateDropInfo(AObject: TObject; AMode: TACLTreeListDropTargetInsertMode): Boolean;
begin
  Result := (AObject <> FDropTargetObject) or (AMode <> FDropTargetObjectInsertMode);
  if Result then
  begin
    DropTargetViewInfo.Invalidate;
    FDropTargetObjectInsertMode := AMode;
    FDropTargetObject := AObject;
    DropTargetViewInfo.Calculate;
    DropTargetViewInfo.Invalidate;
  end;
end;

function TACLTreeListDragAndDropController.CreateDefaultDropTarget: TACLDropTarget;
begin
  if SubClass.OptionsBehavior.DropTarget then
    Result := TACLTreeListDropTarget.Create(SubClass)
  else
    Result := nil;
end;

function TACLTreeListDragAndDropController.GetDropTargetViewInfo: TACLTreeListDropTargetViewInfo;
begin
  Result := SubClass.ViewInfo.Content.DropTargetViewInfo;
end;

function TACLTreeListDragAndDropController.GetSubClass: TACLTreeListSubClass;
begin
  Result := TACLTreeListSubClass(inherited SubClass);
end;

{ TACLTreeListHintController }

function TACLTreeListHintController.CanShowHint(AHintOwner: TObject; const AHintData: TACLHintData): Boolean;
begin
  Result := inherited CanShowHint(AHintOwner, AHintData);
  if Result then
  begin
    if AHintOwner is TACLTreeListNode then
      Result := TACLTreeListSubClass(SubClass).OptionsBehavior.CellHints;
  end;
end;

{ TACLTreeListSortByList }

procedure TACLTreeListSortByList.Notify(const Item: TACLTreeListColumn; Action: TCollectionNotification);
begin
  if Action = cnRemoved then
    TACLTreeListColumnAccess(Item).FSortDirection := sdAscending;
end;

{ TACLTreeListSorter }

constructor TACLTreeListSorter.Create(ASubClass: TACLTreeListSubClass);
begin
  inherited Create;
  FSubClass := ASubClass;
  FSortBy := TACLTreeListSortByList.Create(False);
  FGroupBy := TACLTreeListColumnList.Create(False);
end;

destructor TACLTreeListSorter.Destroy;
begin
  FreeAndNil(FGroupBy);
  FreeAndNil(FSortBy);
  inherited Destroy;
end;

function TACLTreeListSorter.IsGroupedByColumn(AColumnIndex: Integer): Boolean;
begin
  Result := IsCustomGroupping or (GroupBy.Count > 0) and ((AColumnIndex = -1) or
    SubClass.Columns.IsValid(AColumnIndex) and (SubClass.Columns[AColumnIndex].GroupByIndex >= 0));
end;

function TACLTreeListSorter.IsSortedByColumn(AColumnIndex: Integer): Boolean;
begin
  Result := IsCustomSorting or (SortBy.Count > 0) and ((AColumnIndex = -1) or
    SubClass.Columns.IsValid(AColumnIndex) and (SubClass.Columns[AColumnIndex].SortByIndex >= 0));
end;

procedure TACLTreeListSorter.Sort(ARegroup: Boolean);
begin
  if RootNode.HasChildren and RootNode.ChildrenLoaded and not SubClass.EditingController.IsEditing then
  begin
    if ARegroup and (IsGroupMode or (Groups.Count > 0)) or AreSortingParametersDefined then
    begin
      SubClass.DoSorting;
      try
        SubClass.BeginUpdate;
        try
          RootNode.ChildrenNeeded;

          if ARegroup then
            UpdateGroups;

          SortNodes(TACLTreeListNodeAccess(RootNode).FSubNodes);

          if IsGroupMode then
          begin
            // do not change the order
            UpdateGroupsLinksOrder;
            Groups.SortByNodeIndex;
            ReorderNodesByGroupsPosition;
          end;

          SubClass.Changed([cccnStruct]);
        finally
          SubClass.EndUpdate;
        end;
      finally
        SubClass.DoSorted;
      end;
    end;
  end;
end;

class function TACLTreeListSorter.CompareByColumn(
  const ALeft, ARight: TACLTreeListNode; AColumn: TACLTreeListColumn): Integer;
begin
  Result := CompareByColumn(ALeft, ARight, AColumn.Index, AColumn.CompareMode, AColumn.SortDirection);
end;

class function TACLTreeListSorter.CompareByColumn(const ALeft, ARight: TACLTreeListNode;
  AColumnIndex: Integer; ACompareMode: TACLTreeListCompareMode; ASortDirection: TACLSortDirection): Integer;
var
  ATmp1, ATmp2: Integer;
begin
  case ACompareMode of
    tlcmSmart:
      Result := acLogicalCompare(ALeft.Values[AColumnIndex], ARight.Values[AColumnIndex]);

    tlcmInteger:
      begin
        Val(ALeft.Values[AColumnIndex], ATmp1, Result);
        Val(ARight.Values[AColumnIndex], ATmp2, Result);
        Result := ATmp1 - ATmp2;
      end;

  else
    Result := acCompareStrings(ALeft.Values[AColumnIndex], ARight.Values[AColumnIndex], False);
  end;
  if ASortDirection = sdDescending then
    Result := -Result;
end;

class function TACLTreeListSorter.CompareByGroup(const ALeft, ARight: TACLTreeListNode): Integer;
begin
  if ALeft.Group = ARight.Group then
    Exit(0);
  if ALeft.Group = nil then
    Exit(-1);
  if ARight.Group = nil then
    Exit(1);
  Result := acCompareStrings(ALeft.Group.Caption, ARight.Group.Caption, False)
end;

function TACLTreeListSorter.GetGroupName(ANode: TACLTreeListNode): string;
var
  ABuilder: TACLStringBuilder;
  I: Integer;
begin
  if IsCustomGroupping then
  begin
    Result := EmptyStr;
    SubClass.OnGetNodeGroup(SubClass, ANode, Result);
    Exit;
  end;

  if GroupBy.Count = 0 then
    Exit('');
  if GroupBy.Count = 1 then
    Exit(ANode.Values[GroupBy.List[0].Index]);

  ABuilder := TACLStringBuilder.Get;
  try
    for I := 0 to GroupBy.Count - 1 do
    begin
      if I > 0 then
        ABuilder.Append(' / ');
      ABuilder.Append(ANode.Values[GroupBy.List[I].Index]);
    end;
    Result := ABuilder.ToString;
  finally
    ABuilder.Release;
  end;
end;

function TACLTreeListSorter.IsCustomGroupping: Boolean;
begin
  Result := Assigned(SubClass.OnGetNodeGroup)
end;

function TACLTreeListSorter.IsGroupMode: Boolean;
begin
  Result := SubClass.OptionsBehavior.Groups and (IsCustomGroupping or (GroupBy.Count > 0));
end;

procedure TACLTreeListSorter.ReorderNodesByGroupsPosition;
var
  AGroup: TACLTreeListGroup;
  AList: TACLTreeListNodeList;
  I, J: Integer;
begin
  AList := TACLTreeListNodeAccess(SubClass.RootNode).FSubNodes;
  if (AList <> nil) and IsGroupMode then
  begin
    AList.Count := 0;
    for I := 0 to Groups.Count - 1 do
    begin
      AGroup := Groups.List[I];
      for J := 0 to AGroup.Links.Count - 1 do
        AList.Add(AGroup.Links.List[J]);
    end;
  end;
end;

procedure TACLTreeListSorter.UpdateGroups;
var
  AChildNode: TACLTreeListNodeAccess;
  AChildNodeGroupName: string;
  AChildren: TACLTreeListNodeList;
  AGroups: TACLTreeListGroups;
  I: Integer;
begin
  AChildren := TACLTreeListNodeAccess(RootNode).FSubNodes;
  if AChildren = nil then
    Exit;

  if IsGroupMode then
  begin
    AGroups := SubClass.Groups;
    for I := 0 to AChildren.Count - 1 do
    begin
      AChildNode := TACLTreeListNodeAccess(AChildren.List[I]);
      AChildNodeGroupName := GetGroupName(AChildNode);
      if (AChildNode.Group = nil) or (AChildNodeGroupName <> AChildNode.Group.Caption) then
        AChildNode.SetGroup(AGroups.Add(AChildNodeGroupName));
    end;
  end
  else
  begin
    Groups.ClearLinks; // just for performance reasons
    for I := 0 to AChildren.Count - 1 do
      TACLTreeListNodeAccess(AChildren.List[I]).SetGroup(nil);
  end;
end;

procedure TACLTreeListSorter.UpdateGroupsLinksOrder;
var
  AChildNode: TACLTreeListNodeAccess;
  AChildren: TACLTreeListNodeList;
  AGroup: TACLTreeListGroup;
  I: Integer;
begin
  Groups.ClearLinks; // just for performance reasons
  AChildren := TACLTreeListNodeAccess(RootNode).FSubNodes;
  if AChildren <> nil then
    for I := 0 to AChildren.Count - 1 do
    begin
      AChildNode := TACLTreeListNodeAccess(AChildren.List[I]);
      AGroup := AChildNode.Group;
      AChildNode.SetGroup(nil);
      AChildNode.SetGroup(AGroup);
    end;
end;

function TACLTreeListSorter.Compare(const ALeft, ARight: TACLTreeListNode): Integer;
var
  I: Integer;
begin
  Result := 0;
  if IsCustomSorting then
    SubClass.OnCompare(SubClass, ALeft, ARight, Result)
  else
    for I := 0 to SortBy.Count - 1 do
    begin
      Result := CompareByColumn(ALeft, ARight, SortBy[I]);
      if Result <> 0 then
        Break;
    end;

  if Result = 0 then
    Result := TACLTreeListNodeAccess(ALeft).FSortData - TACLTreeListNodeAccess(ARight).FSortData;
end;

function TACLTreeListSorter.IsCustomSorting: Boolean;
begin
  Result := Assigned(SubClass.OnCompare);
end;

function TACLTreeListSorter.AreSortingParametersDefined: Boolean;
begin
  Result := IsCustomSorting or (SortBy.Count > 0);
end;

procedure TACLTreeListSorter.SortNodes(ANodeList: TACLTreeListNodeList);
var
  I: Integer;
begin
  if (ANodeList <> nil) and AreSortingParametersDefined then
  begin
    ANodeList.InitSortData;

    TACLMultithreadedListSorter.Sort(ANodeList,
      function (const Item1, Item2: Pointer): Integer
      begin
        Result := Compare(TACLTreeListNode(Item1), TACLTreeListNode(Item2));
      end,
      SubClass.OptionsBehavior.SortingUseMultithreading);

    for I := 0 to ANodeList.Count - 1 do
      SortNodes(TACLTreeListNodeAccess(ANodeList.List[I]).FSubNodes);
  end;
end;

function TACLTreeListSorter.GetGroups: TACLTreeListGroups;
begin
  Result := SubClass.Groups;
end;

function TACLTreeListSorter.GetRootNode: TACLTreeListNode;
begin
  Result := SubClass.RootNode;
end;

{ TACLTreeListSubClass }

constructor TACLTreeListSubClass.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColumns := CreateColumns;
  FEditingController := CreateEditingController;
  FOptionsBehavior := CreateOptionsBehavior;
  FOptionsCustomizing := CreateOptionsCustomizing;
  FOptionsSelection := CreateOptionsSelection;
  FOptionsView := CreateOptionsView;
  FGroups := CreateGroups;
  FIncSearch := TACLIncrementalSearch.Create;
  FIncSearch.OnChange := IncSearchChanged;
  FIncSearch.OnLookup := IncSearchFindCore;
  FSelection := TACLTreeListNodeList.Create;
  FStyleInplaceEdit := TACLStyleEdit.Create(Self);
  FStyleInplaceEditButton := TACLStyleEditButton.Create(Self);
  FStyleTreeList := CreateStyle;
  FStyleMenu := TACLStylePopupMenu.Create(Self);
end;

destructor TACLTreeListSubClass.Destroy;
begin
  FreeAndNil(FColumns); // first
  FreeAndNil(FGroups);
  FreeAndNil(FRootNode);
  FreeAndNil(FSorter);
  FreeAndNil(FStyleInplaceEdit);
  FreeAndNil(FStyleInplaceEditButton);
  FreeAndNil(FStyleMenu);
  FreeAndNil(FStyleTreeList);
  FreeAndNil(FOptionsView);
  FreeAndNil(FOptionsBehavior);
  FreeAndNil(FOptionsCustomizing);
  FreeAndNil(FOptionsSelection);
  FreeAndNil(FEditingController);
  FreeAndNil(FColumnsCustomizationMenu);
  FreeAndNil(FIncSearch);
  FreeAndNil(FSelection);
  inherited Destroy;
end;

procedure TACLTreeListSubClass.BeforeDestruction;
begin
  inherited BeforeDestruction;
  EditingController.Cancel;
  Clear;
end;

procedure TACLTreeListSubClass.DeleteSelected;
begin
  if HasSelection and DoCanDeleteSelected then
  begin
    BeginLongOperation;
    BeginUpdate;
    try
      DoDeleteSelected;
    finally
      EndUpdate;
      EndLongOperation;
    end;
  end;
end;

procedure TACLTreeListSubClass.ReloadData;
var
  AStoredPath: string;
begin
  BeginUpdate;
  try
    AStoredPath := GetPath(FocusedNode);
    try
      Clear;
      RootNode.HasChildren := True;
      RootNode.ChildrenNeeded;
    finally
      SetPath(AStoredPath);
    end;
  finally
    EndUpdate;
  end;
end;

function TACLTreeListSubClass.WantSpecialKey(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := (Key = VK_ESCAPE) and (EditingController.IsEditing or IncSearch.Active);
end;

procedure TACLTreeListSubClass.SetTargetDPI(AValue: Integer);
begin
  FStyleInplaceEdit.TargetDPI := AValue;
  FStyleInplaceEditButton.TargetDPI := AValue;
  FStyleMenu.TargetDPI := AValue;
  FStyleTreeList.TargetDPI := AValue;
  inherited SetTargetDPI(AValue);
end;

procedure TACLTreeListSubClass.Localize(const ASection: string);
begin
  inherited Localize(ASection);
  Columns.Localize(ASection);
end;

procedure TACLTreeListSubClass.Clear;
begin
  BeginLongOperation;
  BeginUpdate;
  try
  {$REGION 'Improving Performance'}
    FocusedNode := nil;
    Groups.ClearLinks;
    if Selection.Count > 0 then
    begin
      Selection.Clear;
      Changed([tlcnSelection]);
    end;
  {$ENDREGION}
    AbsoluteVisibleNodes.Clear;
    RootNode.Clear;
  finally
    EndUpdate;
    EndLongOperation;
  end;
end;

procedure TACLTreeListSubClass.ConfigLoad(AConfig: TACLIniFile; const ASection, AItem: string);
begin
  Columns.ConfigLoad(AConfig, ASection, AItem + '.ColumnsData');
  if OptionsBehavior.SortingMode = tlsmDisabled then
    ResetSortingParams;
end;

procedure TACLTreeListSubClass.ConfigSave(AConfig: TACLIniFile; const ASection, AItem: string);
begin
  Columns.ConfigSave(AConfig, ASection, AItem + '.ColumnsData');
end;

procedure TACLTreeListSubClass.StartEditing(ANode: TACLTreeListNode; AColumn: TACLTreeListColumn = nil);
begin
  EditingController.StartEditing(ANode, AColumn);
end;

procedure TACLTreeListSubClass.StopEditing;
begin
  EditingController.Cancel;
end;

procedure TACLTreeListSubClass.ExpandTo(AObject: TObject);
var
  AExpandable: IACLExpandableObject;
begin
  BeginUpdate;
  try
    repeat
      AObject := GetObjectParent(AObject);
      if Supports(AObject, IACLExpandableObject, AExpandable) then
        AExpandable.Expanded := True;
    until AObject = nil;
  finally
    EndUpdate;
  end;
end;

procedure TACLTreeListSubClass.MakeTop(AObject: TObject);
begin
  ScrollTo(AObject, TACLScrollToMode.MakeTop);
end;

procedure TACLTreeListSubClass.MakeVisible(AObject: TObject);
begin
  ScrollTo(AObject, TACLScrollToMode.MakeVisible);
end;

procedure TACLTreeListSubClass.ScrollBy(ADeltaX, ADeltaY: Integer);
begin
  ContentViewInfo.ViewportX := ContentViewInfo.ViewportX + ADeltaX;
  ContentViewInfo.ViewportY := ContentViewInfo.ViewportY + ADeltaY;
end;

procedure TACLTreeListSubClass.ScrollByLines(ALines: Integer; ADirection: TACLMouseWheelDirection);
begin
  ContentViewInfo.ScrollByLines(ALines, ADirection);
end;

procedure TACLTreeListSubClass.ScrollTo(AObject: TObject; AMode: TACLScrollToMode; AColumn: TACLTreeListColumn = nil);
var
  ADelta: TPoint;
begin
  ExpandTo(AObject);
  if ContentViewInfo.CalculateScrollDelta(AObject, AMode, ADelta, AColumn) then
    ScrollBy(ADelta.X, ADelta.Y);
end;

procedure TACLTreeListSubClass.ScrollHorizontally(const AScrollCode: TScrollCode);
begin
  ContentViewInfo.ScrollHorizontally(AScrollCode);
end;

procedure TACLTreeListSubClass.ScrollVertically(const AScrollCode: TScrollCode);
begin
  ContentViewInfo.ScrollVertically(AScrollCode);
end;

procedure TACLTreeListSubClass.GroupBy(AColumn: TACLTreeListColumn; AResetPrevSortingParams: Boolean = False);
begin
  if AColumn <> nil then
  begin
    BeginUpdate;
    try
      if AResetPrevSortingParams then
        ResetGrouppingParams;
      GetGroupByList.Add(AColumn);
      Changed([tlcnGrouping, tlcnMakeVisible]);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TACLTreeListSubClass.Regroup;
begin
  ProcessChanges([tlcnGrouping, tlcnMakeVisible]);
end;

procedure TACLTreeListSubClass.ResetGrouppingParams;
begin
  if GetGroupByList.Count > 0 then
  begin
    GetGroupByList.Clear;
    Changed([tlcnGrouping, tlcnMakeVisible]);
  end;
end;

procedure TACLTreeListSubClass.ResetSortingParams;
begin
  GetSortByList.Clear;
end;

procedure TACLTreeListSubClass.Resort;
begin
  BeginLongOperation;
  try
    ProcessChanges([tlcnSorting, tlcnMakeVisible] + [tlcnGrouping] * FChanges);
  finally
    EndLongOperation;
  end;
end;

procedure TACLTreeListSubClass.SortBy(AColumn: TACLTreeListColumn; AResetPrevSortingParams: Boolean);
const
  RotationMap: array[TACLSortDirection] of TACLSortDirection = (sdAscending, sdDescending, sdDefault);
var
  ADirection: TACLSortDirection;
begin
  if AColumn.SortByIndex < 0 then
    ADirection := sdAscending
  else
    ADirection := RotationMap[AColumn.SortDirection];

  SortBy(AColumn, ADirection, AResetPrevSortingParams);
end;

procedure TACLTreeListSubClass.Sort(ACustomSortProc: TACLTreeListNodeCompareEvent);
begin
  ResetSortingParams;
  OnCompare := ACustomSortProc;
  Resort;
  OnCompare := nil;
end;

procedure TACLTreeListSubClass.SortBy(AColumn: TACLTreeListColumn; ADirection: TACLSortDirection; AResetPrevSortingParams: Boolean);
var
  ASortByList: TACLTreeListColumnList;
begin
  if (AColumn <> nil) and (AColumn.Columns <> Columns) then
    raise EInvalidArgument.Create('Column that you specified not owned by this TreeList.');
  if AColumn <> nil then
  begin
    BeginUpdate;
    try
      ASortByList := GetSortByList;
      if AResetPrevSortingParams or (OptionsBehavior.SortingMode <> tlsmMulti) then
        ResetSortingParams;

      if ADirection = sdDefault then
      begin
        ASortByList.Remove(AColumn);
        if ASortByList.Count = 0 then
          DoSortReset;
      end
      else
        if AColumn.SortByIndex < 0 then
          ASortByList.Add(AColumn);

      TACLTreeListColumnAccess(AColumn).FSortDirection := ADirection;
      Resort;
    finally
      EndUpdate;
    end;
  end;
end;

function TACLTreeListSubClass.FindByPath(APath: string;
  AIgnoreCase: Boolean = True; AExactMatch: Boolean = False): TACLTreeListNode;

  function TryFindSubPath(var ANode: TACLTreeListNode; var APath: string): Boolean;
  var
    ACaption: string;
    ACaptionLength: Integer;
    AChildNode: TACLTreeListNode;
    APathLength: Integer;
    I: Integer;
  begin
    ANode.ChildrenNeeded;
    APathLength := Length(APath);
    for I := 0 to ANode.ChildrenCount - 1 do
    begin
      AChildNode := ANode.Children[I];
      ACaption := GetCaptionForPath(AChildNode);
      ACaptionLength := Length(ACaption);
      if (APathLength > ACaptionLength) and CharInSet(APath[ACaptionLength + 1], ['\', '/']) and
        (acCompareStrings(PChar(APath), PChar(ACaption), ACaptionLength, ACaptionLength, AIgnoreCase) = 0) then
      begin
        ANode := AChildNode;
        APath := Copy(APath, ACaptionLength + 2, MaxInt);
        Exit(True);
      end;
    end;
    Result := False;
  end;

var
  ALast: TACLTreeListNode;
begin
  ALast := RootNode;
  APath := acIncludeTrailingPathDelimiter(APath);
  while APath <> '' do
  begin
    if not TryFindSubPath(ALast, APath) then
      Break;
  end;
  if AExactMatch and (APath <> '') then
    Result := nil
  else if ALast <> RootNode then
    Result := ALast
  else
    Result := nil;
end;

function TACLTreeListSubClass.GetPath(ANode: TACLTreeListNode): string;
begin
  if (ANode <> RootNode) and (ANode <> nil) then
    Result := GetPath(ANode.Parent) + GetCaptionForPath(ANode) + PathDelim
  else
    Result := '';
end;

procedure TACLTreeListSubClass.SetPath(const APath: string);
begin
  FocusedNode := FindByPath(APath);
end;

procedure TACLTreeListSubClass.SelectAll;
var
  AObjectToFocus: TObject;
begin
  if AbsoluteVisibleNodes.Count > 0 then
  begin
    AObjectToFocus := FocusedObject;
    if AObjectToFocus = nil then
      AObjectToFocus := AbsoluteVisibleNodes.First;
    SelectRange(AbsoluteVisibleNodes.First, AbsoluteVisibleNodes.Last, AObjectToFocus, True, False, smSelect);
  end;
end;

procedure TACLTreeListSubClass.SelectInvert;
begin
  if (AbsoluteVisibleNodes.Count > 0) and OptionsSelection.MultiSelect then
  begin
    BeginUpdate;
    try
      SelectRange(AbsoluteVisibleNodes.First, AbsoluteVisibleNodes.Last, nil, False, False, smInvert);
      if Selection.Count > 0 then
        SetFocusedObject(Selection.First, False);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TACLTreeListSubClass.SelectNone;
begin
  BeginUpdate;
  try
    while Selection.Count > 0 do
      Selection.Last.Selected := False;
    FocusedNode := nil;
  finally
    EndUpdate;
  end;
end;

procedure TACLTreeListSubClass.SelectObject(AObject: TObject; AMode: TACLSelectionMode; AIsMedium: Boolean);
var
  ASelectable: IACLSelectableObject;
begin
  if (AObject is TACLTreeListGroup) and AIsMedium then
    Exit;
  if Supports(AObject, IACLSelectableObject, ASelectable) then
    case AMode of
      smSelect:
        ASelectable.Selected := True;
      smUnselect:
        ASelectable.Selected := False;
      smInvert:
        ASelectable.Selected := not ASelectable.Selected;
    end;
end;

procedure TACLTreeListSubClass.SelectOnMouseDown(AButton: TMouseButton; AShift: TShiftState);

  procedure SetFocusCore(ASelected: Boolean; ADropSelection: Boolean = True; AMakeVisible: Boolean = True);
  var
    AObjectToFocus: TObject;
  begin
    BeginUpdate;
    try
      if HitTest.HitAtGroup then
      begin
        if OptionsBehavior.GroupsFocusOnClick or not HitTest.Group.Expanded then
          AObjectToFocus := HitTest.Group
        else
          AObjectToFocus := HitTest.Group.Links.First;
      end
      else
        AObjectToFocus := HitTest.HitObject;

      SetFocusedObject(AObjectToFocus, ADropSelection, AMakeVisible);
      SelectObject(HitTest.HitObject, TACLSelectionMode(Ord(ASelected)), False);
    finally
      EndUpdate;
    end;
  end;

begin
  FWasSelected := IsSelected(HitTest.HitObject);
  case AButton of
    mbRight, mbMiddle:
      if not FWasSelected then
        SetFocusCore(True);

    mbLeft:
      if OptionsSelection.MultiSelect and (IsMultiSelectOperation(AShift) or FWasSelected) then
      begin
        if ssShift in AShift then
          SelectRange(FStartObject, HitTest.HitObject, AShift)
        else
          if ssCtrl in AShift then
            SetFocusCore(not FWasSelected, False, False)
          else
            SetFocusCore(True, False, False);
      end
      else
        SetFocusCore(True);
  else;
  end;
end;

procedure TACLTreeListSubClass.SelectRange(AFirstObject, ALastObject: TObject; AShift: TShiftState);
begin
  SelectRange(AFirstObject, ALastObject, True, [ssCtrl] * AShift = [],
    TACLSelectionMode(([ssCtrl] * AShift = []) or IsSelected(AFirstObject)));
end;

procedure TACLTreeListSubClass.SelectRange(AFirstObject, ALastObject: TObject;
  AMakeVisible, ADropSelection: Boolean; AMode: TACLSelectionMode);
begin
  SelectRange(AFirstObject, ALastObject, ALastObject, AMakeVisible, ADropSelection, AMode);
end;

procedure TACLTreeListSubClass.SelectRange(AFirstObject, ALastObject, AObjectToFocus: TObject;
  AMakeVisible, ADropSelection: Boolean; AMode: TACLSelectionMode);
var
  AFirstCell: TACLCompoundControlBaseContentCell;
  AIndex1, AIndex2: Integer;
  ALastCell: TACLCompoundControlBaseContentCell;
  I: Integer;
begin
  if ContentViewInfo.ViewItems.Find(AFirstObject, AFirstCell) and ContentViewInfo.ViewItems.Find(ALastObject, ALastCell) then
  begin
    AIndex1 := ContentViewInfo.ViewItems.IndexOf(AFirstCell);
    AIndex2 := ContentViewInfo.ViewItems.IndexOf(ALastCell);

    BeginUpdate;
    try
      if ADropSelection then
        SelectNone;
      for I := Min(AIndex1, AIndex2) to Max(AIndex1, AIndex2) do
        SelectObject(ContentViewInfo.ViewItems[I].Data, AMode, (I <> AIndex1) and (I <> AIndex2));
      SetFocusedObject(AObjectToFocus, False, AMakeVisible);
    finally
      EndUpdate;
    end;
  end;
end;

function TACLTreeListSubClass.StyleGetNodeBackgroundColor(AOdd: Boolean; ANode: TACLTreeListNode = nil): TAlphaColor;
begin
  Result := Style.RowColors[AOdd];
  if ANode <> nil then
  begin
    if ANode.Selected then
    begin
      if Focused and (ANode = FocusedObject) and (not OptionsSelection.FocusCell or (FocusedColumn = nil)) then
        Result := Style.RowColorFocused.Value
      else
        Result := acGetActualColor(Style.RowColorsSelected[Focused], Result);
    end;
    if OptionsBehavior.HotTrack and (ANode = HoveredObject) then
    begin
      if Style.RowColorHovered.Value.IsValid then
        Result := Style.RowColorHovered.Value;
    end;
    if Assigned(OnGetNodeBackground) then
      OnGetNodeBackground(Self, ANode, Result);
  end;
end;

function TACLTreeListSubClass.StyleGetNodeTextColor(ANode: TACLTreeListNode = nil): TColor;
begin
  if EnabledContent and Container.GetEnabled then
    Result := Style.RowColorText.AsColor
  else
    Result := Style.RowColorDisabledText.AsColor;

  if ANode <> nil then
  begin
    if ANode.Selected and Focused then
      Result := acGetActualColor(Style.RowColorSelectedText.AsColor, Result);
    if OptionsBehavior.HotTrack and (ANode = HoveredObject) then
    begin
      if Style.RowColorHoveredText.Value.IsValid then
        Result := Style.RowColorHoveredText.AsColor;
    end;
    if ANode.Selected then
    begin
      if ANode = FocusedObject then
        Result := acGetActualColor(Style.RowColorFocusedText.AsColor, Result);
      if not Focused then
        Result := acGetActualColor(Style.RowColorSelectedTextInactive.AsColor, Result);
    end;
  end;
end;

procedure TACLTreeListSubClass.StylePrepareFont(
  ACanvas: TCanvas; AFontIndex: Integer; ASuperscript: Boolean);
begin
  ACanvas.Refresh;
  ACanvas.Brush.Style := bsSolid;

  if AFontIndex < 0 then
    ACanvas.SetScaledFont(Font)
  else
    ACanvas.Font.Assign(Style.GetFont(AFontIndex));

  if ASuperscript then
    ACanvas.Font.Height := MulDiv(ACanvas.Font.Height, 2, 3);

  ACanvas.Brush.Style := bsClear;
end;

function TACLTreeListSubClass.CreateDragAndDropController: TACLCompoundControlDragAndDropController;
begin
  Result := TACLTreeListDragAndDropController.Create(Self);
end;

function TACLTreeListSubClass.CreateHintController: TACLCompoundControlHintController;
begin
  Result := TACLTreeListHintController.Create(Self);
end;

function TACLTreeListSubClass.CreateHitTest: TACLHitTestInfo;
begin
  Result := TACLTreeListHitTest.Create;
end;

function TACLTreeListSubClass.CreateColumns: TACLTreeListColumns;
begin
  Result := TACLTreeListColumns.Create(Self);
end;

function TACLTreeListSubClass.CreateEditingController: TACLTreeListEditingController;
begin
  Result := TACLTreeListEditingController.Create(Self);
end;

function TACLTreeListSubClass.CreateGroups: TACLTreeListGroups;
begin
  Result := TACLTreeListGroups.Create(Self);
end;

function TACLTreeListSubClass.CreateInplaceEdit(const AParams: TACLInplaceInfo; out AEdit: TComponent): Boolean;
begin
  AEdit := DoEditCreate(AParams);
  if AEdit <> nil then
    DoEditInitialize(AParams, AEdit);
  Result := Assigned(AEdit);
end;

function TACLTreeListSubClass.CreateNode: TACLTreeListNode;
begin
  if FNodeClass = nil then
  begin
    FNodeClass := TACLTreeListStringNode;
    DoGetNodeClass(FNodeClass);
  end;
  Result := FNodeClass.Create(Self);
end;

function TACLTreeListSubClass.CreateOptionsBehavior: TACLTreeListOptionsBehavior;
begin
  Result := TACLTreeListOptionsBehavior.Create(Self);
end;

function TACLTreeListSubClass.CreateOptionsCustomizing: TACLTreeListOptionsCustomizing;
begin
  Result := TACLTreeListOptionsCustomizing.Create(Self);
end;

function TACLTreeListSubClass.CreateOptionsSelection: TACLTreeListOptionsSelection;
begin
  Result := TACLTreeListOptionsSelection.Create(Self);
end;

function TACLTreeListSubClass.CreateOptionsView: TACLTreeListOptionsView;
begin
  Result := TACLTreeListOptionsView.Create(Self);
end;

function TACLTreeListSubClass.CreateSorter: TACLTreeListSorter;
begin
  Result := TACLTreeListSorter.Create(Self);
end;

function TACLTreeListSubClass.CreateStyle: TACLStyleTreeList;
begin
  Result := TACLStyleTreeList.Create(Self);
end;

function TACLTreeListSubClass.CreateViewInfo: TACLCompoundControlCustomViewInfo;
begin
  Result := TACLTreeListViewInfo.Create(Self);
end;

function TACLTreeListSubClass.GetCaptionForPath(ANode: TACLTreeListNode): string;
begin
  Result := ANode.Caption;
end;

function TACLTreeListSubClass.DoCanDeleteSelected: Boolean;
begin
  Result := True;
  if Assigned(OnCanDeleteSelected) then
    OnCanDeleteSelected(Self, Result);
end;

function TACLTreeListSubClass.DoColumnClick(AColumn: TACLTreeListColumn): Boolean;
begin
  Result := False;
  if Assigned(OnColumnClick) then
    OnColumnClick(Self, AColumn.Index, Result);
end;

procedure TACLTreeListSubClass.DoDeleteSelected;
var
  AList: TACLTreeListNodeList;
  ANode: TACLTreeListNode;
  I: Integer;
begin
  AList := TACLTreeListNodeList.Create;
  try
    AList.Capacity := Selection.Count;
    for I := 0 to Selection.Count - 1 do
    begin
      ANode := Selection[I];
      if ANode.IsTopLevel or not ANode.Parent.Selected then
        AList.Add(ANode)
    end;
    Selection.Clear;
    for I := AList.Count - 1 downto 0 do
      AList[I].Free;
    Changed([tlcnSelection]);
  finally
    AList.Free;
  end;
end;

procedure TACLTreeListSubClass.DoDragSorting;
begin
  CallNotifyEvent(Self, OnDragSorting);
end;

function TACLTreeListSubClass.DoDragSortingDrop(ANode: TACLTreeListNode; AMode: TACLTreeListDropTargetInsertMode): Boolean;
begin
  Result := False;
  if Assigned(OnDragSortingNodeDrop) then
    OnDragSortingNodeDrop(Self, ANode, AMode, Result);
end;

function TACLTreeListSubClass.DoDragSortingOver(ANode: TACLTreeListNode; AMode: TACLTreeListDropTargetInsertMode): Boolean;
begin
  Result := True;
  if Assigned(OnDragSortingNodeOver) then
    OnDragSortingNodeOver(Self, ANode, AMode, Result);
end;

procedure TACLTreeListSubClass.DoDrop(Data: TACLDropTarget; Action: TACLDropAction;
  Target: TACLTreeListNode; Mode: TACLTreeListDropTargetInsertMode);
begin
  if Assigned(OnDrop) then
    OnDrop(Self, Data, Action, Target, Mode);
end;

procedure TACLTreeListSubClass.DoDropOver(Data: TACLDropTarget; var Action: TACLDropAction;
  var Target: TObject; var Mode: TACLTreeListDropTargetInsertMode; var Allow: Boolean);
begin
  if Assigned(OnDropOver) then
    OnDropOver(Self, Data, Action, Target, Mode, Allow);
end;

procedure TACLTreeListSubClass.DoFocusedColumnChanged;
begin
  CallNotifyEvent(Self, OnFocusedColumnChanged);
end;

procedure TACLTreeListSubClass.DoFocusedNodeChanged;
begin
  CallNotifyEvent(Self, OnFocusedNodeChanged);
end;

procedure TACLTreeListSubClass.DoGetNodeClass(var ANodeClass: TACLTreeListNodeClass);
begin
  if Assigned(OnGetNodeClass) then
    OnGetNodeClass(Self, ANodeClass);
end;

procedure TACLTreeListSubClass.DoGetNodeHeight(ANode: TACLTreeListNode; var AHeight: Integer);
begin
  if Assigned(OnGetNodeHeight) then
    OnGetNodeHeight(Self, ANode, AHeight);
end;

procedure TACLTreeListSubClass.DoGetNodeCellDisplayText(
  ANode: TACLTreeListNode; AValueIndex: Integer; var AText: string);
begin
  if Assigned(OnGetNodeCellDisplayText) then
    OnGetNodeCellDisplayText(Self, ANode, AValueIndex, AText);
end;

procedure TACLTreeListSubClass.DoGetNodeCellStyle(AFont: TFont;
  ANode: TACLTreeListNode; AColumn: TACLTreeListColumn; out ATextAlignment: TAlignment);
var
  AFontStyles: TFontStyles;
begin
  if AColumn <> nil then
    ATextAlignment := AColumn.TextAlign
  else
    ATextAlignment := taLeftJustify;

  if Assigned(OnGetNodeCellStyle) then
  begin
    AFontStyles := AFont.Style;
    OnGetNodeCellStyle(Self, ANode, AColumn, AFontStyles, ATextAlignment);
    AFont.Style := AFontStyles;
  end;
end;

procedure TACLTreeListSubClass.DoGetNodeChildren(ANode: TACLTreeListNode);
begin
  if Assigned(OnGetNodeChildren) then
    OnGetNodeChildren(Self, ANode);
end;

procedure TACLTreeListSubClass.DoNodeChecked(ANode: TACLTreeListNode);
begin
  if Assigned(OnNodeChecked) then
    OnNodeChecked(Self, ANode);
end;

function TACLTreeListSubClass.DoNodeDblClicked(ANode: TACLTreeListNode): Boolean;
begin
  Result := Assigned(OnNodeDblClicked);
  if Result then
    OnNodeDblClicked(Self, ANode);
end;

procedure TACLTreeListSubClass.DoSelectionChanged;
begin
  CallNotifyEvent(Self, OnSelectionChanged);
end;

procedure TACLTreeListSubClass.DoSorting;
begin
  CallNotifyEvent(Self, OnSorting);
end;

procedure TACLTreeListSubClass.DoSorted;
begin
  CallNotifyEvent(Self, OnSorted);
end;

procedure TACLTreeListSubClass.DoSortReset;
begin
  CallNotifyEvent(Self, OnSortReset);
end;

function TACLTreeListSubClass.DoCustomDrawColumnBar(ACanvas: TCanvas; const R: TRect): Boolean;
begin
  Result := False;
  if Assigned(OnCustomDrawColumnBar) then
    OnCustomDrawColumnBar(Self, ACanvas, R, Result);
end;

function TACLTreeListSubClass.DoCustomDrawNode(
  ACanvas: TCanvas; const R: TRect; ANode: TACLTreeListNode): Boolean;
begin
  Result := False;
  if Assigned(OnCustomDrawNode) then
    OnCustomDrawNode(Self, ACanvas, R, ANode, Result);
end;

function TACLTreeListSubClass.DoCustomDrawNodeCell(ACanvas: TCanvas;
  const R: TRect; ANode: TACLTreeListNode; AColumn: TACLTreeListColumn): Boolean;
begin
  Result := False;
  if Assigned(OnCustomDrawNodeCell) then
    OnCustomDrawNodeCell(Self, ACanvas, R, ANode, AColumn, Result);
end;

function TACLTreeListSubClass.DoCustomDrawNodeCellValue(ACanvas: TCanvas; const R: TRect;
  ANode: TACLTreeListNode; const AText: string; AValueIndex: Integer; ATextAlignment: TAlignment): Boolean;
begin
  Result := False;
  if Assigned(OnCustomDrawNodeCellValue) then
    OnCustomDrawNodeCellValue(Self, ACanvas, R, ANode, AText, AValueIndex, ATextAlignment, Result);
end;

procedure TACLTreeListSubClass.DoEditKeyDown(var AKey: Word; AShiftState: TShiftState);
begin
  if Assigned(OnEditKeyDown) then
    OnEditKeyDown(Self, AKey, AShiftState);
end;

procedure TACLTreeListSubClass.DoEdited(ARow, AColumn: Integer);
begin
  if Assigned(OnEdited) then
    OnEdited(Self, AColumn, ARow);
end;

procedure TACLTreeListSubClass.DoEditing(ARow, AColumn: Integer; var AValue: string);
begin
  if Assigned(OnEditing) then
    OnEditing(Self, AColumn, ARow, AValue);
end;

function TACLTreeListSubClass.DoEditCreate(const AParams: TACLInplaceInfo): TComponent;
var
  AHandled: Boolean;
begin
  AHandled := False;
  if Assigned(OnEditCreate) then
    Result := OnEditCreate(Self, AParams, AHandled)
  else
    Result := nil;

  if not AHandled and (Result = nil) then
    Result := TACLEdit.CreateInplace(AParams);
end;

procedure TACLTreeListSubClass.DoEditInitialize(const AParams: TACLInplaceInfo; AEdit: TComponent);
begin
  if Assigned(OnEditInitialize) then
    OnEditInitialize(Self, AParams, AEdit);
end;

function TACLTreeListSubClass.CheckFocusedObject: BOolean;
begin
  Result := FocusedObject <> nil;
  if not Result and (ContentViewInfo.ViewItems.Count > 0) then
    SetFocusedObject(ContentViewInfo.ViewItems.First.Data);
end;

procedure TACLTreeListSubClass.FocusChanged;
begin
  inherited;
  if not Focused then
    EditingController.Apply;
end;

procedure TACLTreeListSubClass.SetFocusedObject(
  AObject: TObject; ADropSelection: Boolean; AMakeVisible: Boolean = True);
var
  APrevFocusedColumn: TObject;
  APrevFocusedObject: TObject;
begin
  if AObject = RootNode then
    Exit;
  if not EnabledContent then
    AObject := nil;
  if not FFocusing then
  begin
    FFocusing := True;
    BeginUpdate;
    try
      APrevFocusedObject := FFocusedObject;
      APrevFocusedColumn := FFocusedColumn;

      if IncSearch.Mode <> ismFilter then
        IncSearch.Cancel;
      if ADropSelection then
      begin
        if (Selection.Count > 1) or (AObject <> FFocusedObject) then // Гасим лишние нотификации
          SelectNone;
      end;
      ExpandTo(AObject);
      SelectObject(AObject, smSelect, False);
      FFocusedColumn := nil;
      FFocusedObject := AObject; // после SelectObject

      Changed([cccnContent]);
      if APrevFocusedObject <> FFocusedObject then
        Changed([tlcnFocusedNode]);
      if APrevFocusedColumn <> FFocusedColumn then
        Changed([tlcnFocusedColumn]);
      if AMakeVisible and (FFocusedObject <> nil) then
        Changed([tlcnMakeVisible]);
    finally
      EndUpdate;
      FFocusing := False;
    end;
  end;
end;

procedure TACLTreeListSubClass.ValidateFocusedObject;
var
  ACell: TACLCompoundControlBaseContentCell;
  ANewFocusedObject: TObject;
begin
  ANewFocusedObject := FocusedObject;
  while (ANewFocusedObject <> nil) and not ContentViewInfo.ViewItems.Find(ANewFocusedObject, ACell) do
    ANewFocusedObject := GetObjectParent(ANewFocusedObject);
  if ANewFocusedObject <> FocusedObject then
    SetFocusedObject(ANewFocusedObject, False, False);
  if not (Columns.IsValid(FocusedColumn) and FocusedColumn.Visible) then
    FocusedColumn := nil;
end;

procedure TACLTreeListSubClass.ColumnSetVisibilityHandler(Sender: TObject);
var
  AIndex: Integer;
begin
  AIndex := (Sender as TComponent).Tag;
  if Columns.IsValid(AIndex) then
    Columns[AIndex].Visible := (Sender as TMenuItem).Checked;
end;

procedure TACLTreeListSubClass.ColumnCustomizationMenuShow(const P: TPoint);
begin
  GetColumnCustomizationMenu.Popup(ClientToScreen(P));
end;

function TACLTreeListSubClass.GetColumnCustomizationMenu: TACLPopupMenu;
var
  AColumn: TACLTreeListColumn;
  AMenuItem: TMenuItem;
  I: Integer;
begin
  if FColumnsCustomizationMenu = nil then
    FColumnsCustomizationMenu := TACLPopupMenu.Create(Self);
  Result := FColumnsCustomizationMenu;
  Result.Options.CloseMenuOnItemCheck := False;
  Result.Style.Assign(StyleMenu);
  Result.Style.Collection := StyleMenu.Collection;
  Result.Items.Clear;
  for I := 0 to Columns.Count - 1 do
  begin
    AColumn := Columns.ItemsByDrawingIndex[I];
    AMenuItem := Result.Items.AddItem(AColumn.Caption, AColumn.Index, ColumnSetVisibilityHandler);
    AMenuItem.Checked := AColumn.Visible;
    AMenuItem.AutoCheck := True;
  end;
end;

procedure TACLTreeListSubClass.ProcessChanges(AChanges: TIntegerSet);
begin
  if AChanges - [cccnContent] <> [] then
    EditingController.Close(AChanges);

  if (cccnContent in AChanges) and not EnabledContent then
  begin
    if SelectedCount > 0 then
      SelectNone;
  end;

  if cccnStruct in AChanges then
    Groups.Validate;

  if [tlcnNodeIndex, tlcnGroupIndex] * AChanges <> [] then
  begin
    Sorter.SortBy.Clear;
    Include(AChanges, cccnStruct);
    if tlcnGroupIndex in AChanges then
      Sorter.ReorderNodesByGroupsPosition
    else
      Include(AChanges, tlcnGrouping);
  end;

  if [tlcnSorting, tlcnGrouping] * AChanges <> [] then
  begin
    Sorter.Sort(tlcnGrouping in AChanges);
    Include(AChanges, cccnStruct);
  end;

  if tlcnSettingsFocus in AChanges then
    SetFocusedObject(nil);

  if tlcnSettingsIncSearch in AChanges then
  begin
    IncSearch.Cancel;
    IncSearch.Mode := OptionsBehavior.IncSearchMode;
  end;

  inherited ProcessChanges(AChanges);

  if cccnStruct in AChanges then
    ValidateFocusedObject;

  if tlcnMakeVisible in AChanges then
    ScrollTo(FocusedObject, TACLScrollToMode.MakeVisible, FocusedColumn);

  if [cccnStruct, cccnLayout, tlcnData] * AChanges <> [] then
  begin
    if OptionsBehavior.AutoBestFit then
      Columns.ApplyBestFit(True);
  end;

  if tlcnSelection in AChanges then
    DoSelectionChanged;
  if tlcnFocusedNode in AChanges then
    DoFocusedNodeChanged;
  if tlcnFocusedColumn in AChanges then
    DoFocusedColumnChanged;
  if tlcnSettingsSorting in AChanges then
  begin
    Sorter.SortBy.Clear;
    Resort;
  end;
end;

function TACLTreeListSubClass.CheckIncSearchColumn: Boolean;
var
  AIndex: Integer;
begin
  AIndex := OptionsBehavior.IncSearchColumnIndex;
  if InRange(AIndex, 0, ContentViewInfo.ColumnBarViewInfo.ChildCount - 1) then
    FIncSearchColumnIndex := ContentViewInfo.ColumnBarViewInfo.Children[AIndex].AbsoluteIndex
  else
    FIncSearchColumnIndex := IfThen(AIndex < 0, -1);

  Result := IncSearchColumnIndex >= 0;
end;

function TACLTreeListSubClass.GetHighlightBounds(const AText: string;
  AAbsoluteColumnIndex: Integer; out AHighlightStart, AHighlightFinish: Integer): Boolean;
begin
  Result := (AAbsoluteColumnIndex = IncSearchColumnIndex) and
    IncSearch.GetHighlightBounds(AText, AHighlightStart, AHighlightFinish);
end;

procedure TACLTreeListSubClass.IncSearchChanged(Sender: TObject);
begin
  if OptionsBehavior.IncSearchMode = ismFilter then
  begin
    Changed([cccnStruct]);
    if AbsoluteVisibleNodes.Count > 0 then
      SetFocusedObject(AbsoluteVisibleNodes.First);
  end;
  Changed([cccnContent]);
end;

function TACLTreeListSubClass.IncSearchContains(ANode: TACLTreeListNode): Boolean;
var
  I: Integer;
begin
  Result := IncSearch.Contains(ANode.Values[IncSearchColumnIndex]);

  if not Result and ANode.HasChildren then
  begin
    for I := 0 to ANode.ChildrenCount - 1 do
      if IncSearchContains(ANode.Children[I]) then
        Exit(True);
  end;
end;

procedure TACLTreeListSubClass.ProcessGesture(const AEventInfo: TGestureEventInfo; var AHandled: Boolean);
begin
{$IFNDEF FPC}
  if AEventInfo.GestureID = igiPan then
  begin
    if gfBegin in AEventInfo.Flags then
      FTapLocation := AEventInfo.Location;
    ScrollBy(FTapLocation.X - AEventInfo.Location.X, FTapLocation.Y - AEventInfo.Location.Y);
    FTapLocation := AEventInfo.Location;
    AHandled := True;
  end;
{$ENDIF}
end;

procedure TACLTreeListSubClass.IncSearchFindCore(Sender: TObject; var AFound: Boolean);

  function FindNode(AStartIndex, AFinishIndex: Integer): TACLTreeListNode; overload;
  var
    I: Integer;
  begin
    for I := AStartIndex to AFinishIndex do
    begin
      if IncSearch.Contains(AbsoluteVisibleNodes[I].Values[IncSearchColumnIndex]) then
        Exit(AbsoluteVisibleNodes[I]);
    end;
    Result := nil;
  end;

  function FindNode(out ANode: TACLTreeListNode): Boolean; overload;
  var
    AIndex: Integer;
  begin
    AIndex := Max(0, AbsoluteVisibleNodes.IndexOf(FocusedObject));
    ANode := FindNode(AIndex, AbsoluteVisibleNodes.Count - 1);
    if ANode = nil then
      ANode := FindNode(0, AIndex - 1);
    Result := ANode <> nil;
  end;

var
  ANode: TACLTreeListNode;
begin
  AFound := CheckIncSearchColumn and FindNode(ANode);
  if AFound then
    SetFocusedObject(ANode);
end;

function TACLTreeListSubClass.GetObjectChild(AObject: TObject): TObject;
var
  ATreeNodeLink: IACLTreeNodeLink;
begin
  if Supports(AObject, IACLTreeNodeLink, ATreeNodeLink) then
    Result := ATreeNodeLink.GetChild
  else
    Result := nil;
end;

function TACLTreeListSubClass.GetObjectParent(AObject: TObject): TObject;
var
  ATreeNodeLink: IACLTreeNodeLink;
begin
  if Supports(AObject, IACLTreeNodeLink, ATreeNodeLink) then
    Result := ATreeNodeLink.GetParent
  else
    Result := nil;
end;

function TACLTreeListSubClass.GetNextColumn(out AColumn: TACLTreeListColumn): Boolean;
begin
  if FocusedColumn <> nil then
    AColumn := FocusedColumn
  else if Columns.Count > 0 then
    AColumn := Columns.First
  else
    AColumn := nil;

  if AColumn <> nil then
  repeat
    AColumn := AColumn.NextSibling;
  until (AColumn = nil) or AColumn.Visible;

  Result := AColumn <> nil;
end;

function TACLTreeListSubClass.GetNextObject(AObject: TObject; AKey: Word): TObject;

  function CanFocus(AData: TObject): Boolean;
  begin
    if AData is TACLTreeListGroup then
      Result := OptionsBehavior.GroupsFocus and not ((AKey = VK_HOME) and TACLTreeListGroup(AData).Expanded)
    else
      Result := True;
  end;

  function GetNextCellIndex(var ACellIndex: Integer; AKey: Word): Boolean;
  var
    APrevCellIndex: Integer;
  begin
    APrevCellIndex := ACellIndex;
    case AKey of
      VK_UP:
        Dec(ACellIndex);
      VK_DOWN:
        Inc(ACellIndex);
      VK_NEXT:
        Inc(ACellIndex, ContentViewInfo.ViewItems.LastVisible - ContentViewInfo.ViewItems.FirstVisible);
      VK_PRIOR:
        Dec(ACellIndex, ContentViewInfo.ViewItems.LastVisible - ContentViewInfo.ViewItems.FirstVisible);
      VK_HOME:
        ACellIndex := 0;
      VK_END:
        ACellIndex := ContentViewInfo.ViewItems.Count - 1;
    end;
    ACellIndex := MinMax(ACellIndex, 0, ContentViewInfo.ViewItems.Count - 1);
    Result := ACellIndex <> APrevCellIndex;
  end;

var
  ACell: TACLCompoundControlBaseContentCell;
  ACellIndex: Integer;
begin
  Result := nil;
  if ContentViewInfo.ViewItems.Find(AObject, ACell) then
  begin
    ACellIndex := ContentViewInfo.ViewItems.IndexOf(ACell);
    GetNextCellIndex(ACellIndex, AKey);

    while not CanFocus(ContentViewInfo.ViewItems[ACellIndex].Data) do
    begin
      case AKey of
        VK_HOME, VK_DOWN, VK_NEXT:
          AKey := VK_DOWN;
        VK_END, VK_UP, VK_PRIOR:
          AKey := VK_UP;
      end;
      if not GetNextCellIndex(ACellIndex, AKey) then
      begin
        ACellIndex := -1;
        Break;
      end;
    end;

    if InRange(ACellIndex, 0, ContentViewInfo.ViewItems.Count - 1) then
      Result := ContentViewInfo.ViewItems[ACellIndex].Data
    else
      Result := AObject;

    if not CanFocus(Result) then
      Result := nil;
  end;
end;

function TACLTreeListSubClass.GetPrevColumn(out AColumn: TACLTreeListColumn): Boolean;
begin
  AColumn := FocusedColumn;
  if AColumn <> nil then
  repeat
    AColumn := AColumn.PrevSibling;
  until (AColumn = nil) or AColumn.Visible;
  Result := AColumn <> nil;
end;

function TACLTreeListSubClass.IsMultiSelectOperation(AShift: TShiftState): Boolean;
begin
  Result := OptionsSelection.MultiSelect and ([ssShift, ssCtrl] * AShift <> []);
end;

function TACLTreeListSubClass.IsSelected(AObject: TObject): Boolean;
var
  ASelectable: IACLSelectableObject;
begin
  Result := Supports(AObject, IACLSelectableObject, ASelectable) and ASelectable.Selected;
end;

procedure TACLTreeListSubClass.ToggleCheckboxes;
var
  ACheckable: IACLCheckableObject;
begin
  BeginUpdate;
  try
    if Supports(FocusedObject, IACLCheckableObject, ACheckable) then
    try
      if ACheckable.CanCheck then
        ACheckable.Checked := not ACheckable.Checked;
      Selection.CheckState := TCheckBoxState.Create(ACheckable.Checked);
    finally
      ACheckable := nil;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLTreeListSubClass.ToggleGroupExpanded(AGroup: TACLTreeListGroup; AShift: TShiftState);
var
  AState: Boolean;
  I: Integer;
begin
  if ssAlt in AShift then
  begin
    BeginLongOperation;
    BeginUpdate;
    try
      AState := AGroup.Expanded;
      for I := 0 to Groups.Count - 1 do
        Groups[I].Expanded := AState;
    finally
      EndUpdate;
      EndLongOperation;
    end;
  end
  else
    AGroup.Expanded := not AGroup.Expanded;
end;

procedure TACLTreeListSubClass.NavigateTo(AObject: TObject; AShift: TShiftState);
begin
  if (AObject <> nil) and (AObject <> RootNode) then
  begin
    if IsMultiSelectOperation(AShift) then
      SelectRange(FStartObject, AObject, AShift)
    else
      SetFocusedObject(AObject);
  end;
end;

procedure TACLTreeListSubClass.ProcessKeyDown(var AKey: Word; AShift: TShiftState);
var
  AColumn: TACLTreeListColumn;
  AExpandable: IACLExpandableObject;
begin
  case AKey of
    65: // A
      if [ssAlt, ssShift, ssCtrl] * AShift = [ssCtrl] then
        SelectAll;

    106: // Num *
      SelectInvert;

    107: // Num +
      if ssCtrl in AShift then
        Columns.ApplyBestFit;

    VK_SHIFT:
      if FStartObject = nil then
        FStartObject := FocusedObject;

    VK_SPACE:
      if not IncSearch.ProcessKey(AKey, AShift) then
        ToggleCheckboxes;

    VK_DELETE:
      if OptionsBehavior.Deleting then
        DeleteSelected;

    VK_RETURN:
      if OptionsBehavior.Editing then
      begin
        if FocusedObject is TACLTreeListNode then
          StartEditing(TACLTreeListNode(FocusedObject), FocusedColumn);
      end;

    VK_UP, VK_DOWN, VK_NEXT, VK_PRIOR, VK_HOME, VK_END:
      if CheckFocusedObject then
      begin
        BeginUpdate;
        try
          AColumn := FocusedColumn;
          NavigateTo(GetNextObject(FocusedObject, AKey), AShift);
          FocusedColumn := AColumn;
        finally
          EndUpdate;
        end;
        UpdateHotTrack;
        AKey := 0;
      end;

    VK_LEFT:
      if CheckFocusedObject then
      begin
        if OptionsSelection.FocusCell and GetPrevColumn(AColumn) then
          FocusedColumn := AColumn
        else
          if Supports(FocusedObject, IACLExpandableObject, AExpandable) and
            AExpandable.CanToggle and AExpandable.Expanded
          then
            AExpandable.Expanded := False
          else
            NavigateTo(GetObjectParent(FocusedObject), AShift);
        AKey := 0;
      end;

    VK_RIGHT:
      if CheckFocusedObject then
      begin
        if OptionsSelection.FocusCell and GetNextColumn(AColumn) then
          FocusedColumn := AColumn
        else
          if Supports(FocusedObject, IACLExpandableObject, AExpandable) and
            AExpandable.CanToggle and not AExpandable.Expanded
          then
            AExpandable.Expanded := True
          else
            NavigateTo(GetObjectChild(FocusedObject), AShift);
        AKey := 0;
      end;
  else
    IncSearch.ProcessKey(AKey, AShift);
  end;
  inherited ProcessKeyDown(AKey, AShift);
end;

procedure TACLTreeListSubClass.ProcessKeyPress(var AKey: WideChar);
begin
  if OptionsBehavior.IncSearchColumnIndex >= 0 then
    IncSearch.ProcessKey(AKey);
  inherited ProcessKeyPress(AKey);
end;

procedure TACLTreeListSubClass.ProcessKeyUp(var AKey: Word; AShift: TShiftState);
begin
  case AKey of
    VK_SHIFT:
      FStartObject := nil;
  end;
  inherited ProcessKeyUp(AKey, AShift);
end;

procedure TACLTreeListSubClass.ProcessContextPopup(var AHandled: Boolean);
begin
  inherited ProcessContextPopup(AHandled);
  if not AHandled and (OptionsCustomizing.ColumnVisibility and (HitTest.HitAtColumn or HitTest.HitAtColumnBar)) then
  begin
    ColumnCustomizationMenuShow(HitTest.HitPoint);
    AHandled := True;
  end;
end;

procedure TACLTreeListSubClass.ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState);
begin
  if HitTest.HitAtColumn then
    ProcessMouseClickAtColumn(AButton, AShift, HitTest.Column)
  else if HitTest.HitAtGroup then
    ProcessMouseClickAtGroup(AButton, AShift, HitTest.Group)
  else if HitTest.HitAtNode and HitTest.IsExpandable and (ssAlt in AShift) and (AButton = mbLeft) then
    RootNode.ExpandCollapseChildren(not HitTest.Node.Expanded, False)
  else
    inherited ProcessMouseClick(AButton, AShift);
end;

procedure TACLTreeListSubClass.ProcessMouseClickAtColumn(
  AButton: TMouseButton; AShift: TShiftState; AColumn: TACLTreeListColumn);
begin
  if AButton <> mbLeft then
    Exit;
  if HitTest.IsCheckable then
    RootNode.ChildrenCheckState := TCheckBoxState.Create(RootNode.ChildrenCheckState <> cbChecked)
  else
    if not HitTest.IsResizable and not DoColumnClick(AColumn) then
    begin
      if OptionsBehavior.SortingMode <> tlsmDisabled then
        SortBy(AColumn, not (ssCtrl in AShift));
    end;
end;

procedure TACLTreeListSubClass.ProcessMouseClickAtGroup(
  AButton: TMouseButton; AShift: TShiftState; AGroup: TACLTreeListGroup);
begin
  if AButton <> mbLeft then
    Exit;

  if HitTest.IsCheckable then
    ToggleChecked(AGroup)
  else
    if HitTest.IsExpandable then
    begin
      if ssAlt in AShift then
        Groups.SetExpanded(not AGroup.Expanded)
      else
        ToggleExpanded(AGroup);
    end;
end;

procedure TACLTreeListSubClass.ProcessMouseDblClick(AButton: TMouseButton; AShift: TShiftState);
var
  AGroup: TACLTreeListGroup;
begin
  if AButton <> mbLeft then
  begin
    inherited ProcessMouseDblClick(AButton, AShift);
    Exit;
  end;

  if HitTest.HitAtColumn then
  begin
    if HitTest.IsResizable then
      HitTest.Column.ApplyBestFit
    else
      ProcessMouseClickAtColumn(AButton, AShift, HitTest.Column);
  end
  else

  if HitTest.HitAtGroup then
  begin
    AGroup := HitTest.Group;
    if HitTest.HasAction then
      ProcessMouseClickAtGroup(AButton, AShift, AGroup)
    else
    begin
      ToggleGroupExpanded(AGroup, AShift);
      if not OptionsBehavior.GroupsFocusOnClick and AGroup.Expanded then
        SetFocusedObject(AGroup.Links.First);
    end;
  end
  else

  if HitTest.HitAtNode and not HitTest.HasAction then
  begin
    if OptionsBehavior.EditingStartingMode = esmOnDoubleClick then
      EditingController.StartEditing(HitTest.Node, HitTest.Column);
    if not EditingController.IsEditing then
    begin
      if not DoNodeDblClicked(HitTest.Node) then
        ToggleExpanded(HitTest.HitObject);
    end;
  end
  else
    inherited ProcessMouseDblClick(AButton, AShift);
end;

procedure TACLTreeListSubClass.ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState);
begin
  inherited ProcessMouseDown(AButton, AShift);
  FWasSelected := False;
  if not HitTest.HasAction then
  begin
    if Supports(HitTest.HitObject, IACLSelectableObject) then
      SelectOnMouseDown(AButton, AShift)
    else
      if HitTest.HitAtContentArea and (AButton = mbLeft) then
        SelectNone;
  end;
end;

procedure TACLTreeListSubClass.ProcessMouseUp(AButton: TMouseButton; AShift: TShiftState);
begin
  if (AButton = mbLeft) and (HitTest.HitObject = PressedObject) then
  begin
    if FWasSelected then
    begin
      if not IsMultiSelectOperation(AShift) then
      begin
        if not (HitTest.HitAtNode and EditingController.IsEditing(HitTest.Node)) then
          SetFocusedObject(HitTest.HitObject, True, not HitTest.HasAction);
      end;
    end;
    if OptionsBehavior.EditingStartingMode = esmOnSingleClick then
    begin
      if HitTest.HitAtNode and not HitTest.HasAction then
        StartEditing(HitTest.Node, HitTest.Column);
    end;
  end;
  FWasSelected := False;
  inherited ProcessMouseUp(AButton, AShift);
end;

procedure TACLTreeListSubClass.ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);
var
  ACount: Integer;
begin
  ACount := TACLMouseWheel.GetScrollLines(AShift);
  if ssShift in AShift then
  begin
    while ACount > 0 do
    begin
      ScrollHorizontally(TACLMouseWheel.DirectionToScrollCode[ADirection]);
      Dec(ACount);
    end
  end
  else
  begin
    if OptionsBehavior.MouseWheelScrollLines > 0 then
      ACount := OptionsBehavior.MouseWheelScrollLines;
    ScrollByLines(ACount, ADirection);
  end;
end;

function TACLTreeListSubClass.CalculateBestFit(AColumn: TACLTreeListColumn): Integer;
var
  AViewInfo: TACLTreeListColumnViewInfo;
begin
  if ViewInfo.Content.ColumnBarViewInfo.GetColumnViewInfo(AColumn, AViewInfo) then
  begin
    BeginLongOperation;
    try
      Result := dpiRevert(AViewInfo.CalculateBestFit, CurrentDpi);
    finally
      EndLongOperation;
    end;
  end
  else
    Result := AColumn.Width;
end;

function TACLTreeListSubClass.ColumnsCanCustomizeOrder: Boolean;
begin
  Result := OptionsCustomizing.ColumnOrder;
end;

function TACLTreeListSubClass.ColumnsCanCustomizeVisibility: Boolean;
begin
  Result := OptionsCustomizing.ColumnVisibility;
end;

function TACLTreeListSubClass.GetAbsoluteVisibleNodes: TACLTreeListNodeList;
begin
  Result := ViewInfo.Content.AbsoluteVisibleNodes;
end;

function TACLTreeListSubClass.GetAutoCheckParents: Boolean;
begin
  Result := OptionsBehavior.AutoCheckParents;
end;

function TACLTreeListSubClass.GetAutoCheckChildren: Boolean;
begin
  Result := OptionsBehavior.AutoCheckChildren;
end;

function TACLTreeListSubClass.GetGroupByList: TACLTreeListColumnList;
begin
  Result := Sorter.GroupBy;
end;

function TACLTreeListSubClass.GetObject: TPersistent;
begin
  Result := Self;
end;

function TACLTreeListSubClass.GetRootNode: TACLTreeListNode;
begin
  if FRootNode = nil then
  begin
    FRootNode := CreateNode;
    FRootNode.HasChildren := True;
    TACLTreeListNodeAccess(FRootNode).FExpanded := True;
  end;
  Result := FRootNode;
end;

function TACLTreeListSubClass.GetSortByList: TACLTreeListColumnList;
begin
  Result := Sorter.SortBy;
end;

procedure TACLTreeListSubClass.GroupRemoving(AGroup: TACLTreeListGroup);
begin
  if AGroup = HoveredObject then
    SetHoveredObject(nil);
  if AGroup = FocusedObject then
    FocusedObject := nil;
end;

procedure TACLTreeListSubClass.NodeRemoving(ANode: TACLTreeListNode);
var
  ANewFocusedObject: TObject;
begin
  if not DragAndDropController.IsDropping then
    DragAndDropController.Cancel;
  if Selection.RemoveItem(ANode, FromEnd) >= 0 then
    Changed([tlcnSelection]);
  if ANode = HoveredObject then
    SetHoveredObject(nil);

  if not IsDestroying then
  begin
    if ANode = FocusedObject then
    begin
      ANewFocusedObject := ANode.NextSibling;
      if ANewFocusedObject = nil then
        ANewFocusedObject := ANode.PrevSibling;
      if ANewFocusedObject = nil then
        ANewFocusedObject := GetObjectParent(ANode);
      if ANewFocusedObject = RootNode then
        ANewFocusedObject := nil;
      SetFocusedObject(ANewFocusedObject);
    end;
  end;

  ANode.Parent := nil;
  TACLTreeListNodeAccess(ANode).SetGroup(nil);

  if Assigned(OnNodeDeleted) then
    OnNodeDeleted(Self, ANode);
end;

procedure TACLTreeListSubClass.NodeSetSelected(ANode: TACLTreeListNode; var AValue: Boolean);
begin
  BeginUpdate;
  try
    AValue := AValue and EnabledContent;
    if AValue then
    begin
      if not OptionsSelection.MultiSelect then
        SelectNone;
      Selection.Add(ANode);
    end
    else
      Selection.RemoveItem(ANode, FromEnd);

    Changed([cccnContent, tlcnSelection]);
  finally
    EndUpdate;
  end;
end;

procedure TACLTreeListSubClass.NodeValuesChanged(AColumnIndex: Integer = -1);
var
  AChanges: TIntegerSet;
begin
  AChanges := [cccnContent, tlcnData];
  if Sorter.IsGroupedByColumn(AColumnIndex) then
    Include(AChanges, tlcnGrouping);
  if Sorter.IsSortedByColumn(AColumnIndex) then
    Include(AChanges, tlcnSorting);
  Changed(AChanges);
end;

function TACLTreeListSubClass.QueryChildInterface(AChild: TObject; const IID: TGUID; var Obj): HRESULT;
var
  ACell: TACLCompoundControlBaseContentCell;
begin
  if ContentViewInfo.ViewItems.Find(AChild, ACell) and Supports(ACell, IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TACLTreeListSubClass.GetContentViewInfo: TACLTreeListContentViewInfo;
begin
  Result := ViewInfo.Content;
end;

function TACLTreeListSubClass.GetDragAndDropController: TACLTreeListDragAndDropController;
begin
  Result := inherited DragAndDropController as TACLTreeListDragAndDropController;
end;

function TACLTreeListSubClass.GetFocusedGroup: TACLTreeListGroup;
begin
  if FocusedObject is TACLTreeListGroup then
    Result := TACLTreeListGroup(FocusedObject)
  else
    Result := nil;
end;

function TACLTreeListSubClass.GetFocusedNode: TACLTreeListNode;
begin
  if FocusedObject is TACLTreeListNode then
    Result := TACLTreeListNode(FocusedObject)
  else if FocusedObject is TACLTreeListGroup then
    Result := TACLTreeListGroup(FocusedObject).Links.First
  else if SelectedCount > 0 then
    Result := Selected[0]
  else
    Result := nil;
end;

function TACLTreeListSubClass.GetFocusedNodeData: Pointer;
begin
  if FocusedNode <> nil then
    Result := FocusedNode.Data
  else
    Result := nil;
end;

function TACLTreeListSubClass.GetGroup(Index: Integer): TACLTreeListGroup;
begin
  Result := Groups[Index];
end;

function TACLTreeListSubClass.GetGroupCount: Integer;
begin
  Result := Groups.Count;
end;

function TACLTreeListSubClass.GetHasSelection: Boolean;
begin
  Result := (SelectedCount > 0) and (FocusedNode <> nil);
end;

function TACLTreeListSubClass.GetHitTest: TACLTreeListHitTest;
begin
  Result := TACLTreeListHitTest(inherited HitTest);
end;

function TACLTreeListSubClass.GetSelected(Index: Integer): TACLTreeListNode;
begin
  Result := Selection.List[Index];
end;

function TACLTreeListSubClass.GetSelectedCheckState: TCheckBoxState;
begin
  Result := Selection.CheckState;
end;

function TACLTreeListSubClass.GetSelectedCount: Integer;
begin
  Result := Selection.Count;
end;

function TACLTreeListSubClass.GetSorter: TACLTreeListSorter;
begin
  if FSorter = nil then
    FSorter := CreateSorter;
  Result := FSorter;
end;

function TACLTreeListSubClass.GetViewInfo: TACLTreeListViewInfo;
begin
  Result := inherited ViewInfo as TACLTreeListViewInfo
end;

function TACLTreeListSubClass.GetViewportX: Integer;
begin
  Result := ViewInfo.Content.ViewportX;
end;

function TACLTreeListSubClass.GetViewportY: Integer;
begin
  Result := ViewInfo.Content.ViewportY;
end;

function TACLTreeListSubClass.GetVisibleScrolls: TACLVisibleScrollBars;
begin
  Result := ViewInfo.Content.VisibleScrollBars;
end;

procedure TACLTreeListSubClass.SetColumns(AValue: TACLTreeListColumns);
begin
  FColumns.Assign(AValue);
end;

procedure TACLTreeListSubClass.SetFocusedColumn(AValue: TACLTreeListColumn);
begin
  if not EnabledContent then
    AValue := nil;
  if (AValue <> nil) and not AValue.Visible then
    AValue := nil;
  if FFocusedColumn <> AValue then
  begin
    BeginUpdate;
    try
      FFocusedColumn := AValue;
      Changed([cccnContent, tlcnFocusedColumn]);
      if FocusedColumn <> nil then
        Changed([tlcnMakeVisible]);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TACLTreeListSubClass.SetFocusedGroup(AValue: TACLTreeListGroup);
begin
  SetFocusedObject(AValue);
end;

procedure TACLTreeListSubClass.SetFocusedNode(AValue: TACLTreeListNode);
begin
  SetFocusedObject(AValue);
end;

procedure TACLTreeListSubClass.SetFocusedNodeData(const Value: Pointer);
begin
  FocusedNode := RootNode.Find(Value);
end;

procedure TACLTreeListSubClass.SetFocusedObject(AValue: TObject);
begin
  SetFocusedObject(AValue, True);
end;

procedure TACLTreeListSubClass.SetOnGetNodeClass(const Value: TACLTreeListGetNodeClassEvent);
begin
  if @FOnGetNodeClass <> @Value then
  begin
    if Assigned(Value) then
    begin
      if (FRootNode <> nil) and FRootNode.ChildrenLoaded and (FRootNode.ChildrenCount > 0) then
        raise EInvalidOperation.Create(sErrorCannotChangeNodeClass);
    end;
    FOnGetNodeClass := Value;
    FreeAndNil(FRootNode);
    FNodeClass := nil;
    Changed([cccnStruct]);
  end;
end;

procedure TACLTreeListSubClass.SetOptionsBehavior(AValue: TACLTreeListOptionsBehavior);
begin
  FOptionsBehavior.Assign(AValue);
end;

procedure TACLTreeListSubClass.SetOptionsCustomizing(AValue: TACLTreeListOptionsCustomizing);
begin
  FOptionsCustomizing.Assign(AValue);
end;

procedure TACLTreeListSubClass.SetOptionsSelection(AValue: TACLTreeListOptionsSelection);
begin
  FOptionsSelection.Assign(AValue);
end;

procedure TACLTreeListSubClass.SetOptionsView(AValue: TACLTreeListOptionsView);
begin
  FOptionsView.Assign(AValue);
end;

procedure TACLTreeListSubClass.SetStyleInplaceEdit(AValue: TACLStyleEdit);
begin
  FStyleInplaceEdit.Assign(AValue);
end;

procedure TACLTreeListSubClass.SetStyleInplaceEditButton(AValue: TACLStyleEditButton);
begin
  FStyleInplaceEditButton.Assign(AValue);
end;

procedure TACLTreeListSubClass.SetStyleMenu(AValue: TACLStylePopupMenu);
begin
  FStyleMenu.Assign(AValue);
end;

procedure TACLTreeListSubClass.SetStyle(AValue: TACLStyleTreeList);
begin
  FStyleTreeList.Assign(AValue);
end;

procedure TACLTreeListSubClass.SetViewportX(const Value: Integer);
begin
  ViewInfo.Content.ViewportX := Value;
end;

procedure TACLTreeListSubClass.SetViewportY(const Value: Integer);
begin
  ViewInfo.Content.ViewportY := Value;
end;

end.
