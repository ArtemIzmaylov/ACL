{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             TreeList Control              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.TreeList;

{$I ACL.Config.INC}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.UITypes,
  System.Types,
  System.Classes,
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.StdCtrls,
  // ACL
  ACL.Classes,
  ACL.FileFormats.INI,
  ACL.Graphics,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.TreeList.Options,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.HintWindow,
  ACL.UI.PopupMenu,
  ACL.UI.Resources;

type

  { TACLCustomTreeList }

  TACLCustomTreeList = class(TACLCompoundControl,
    IACLFocusableControl2)
  strict private
    function GetAbsoluteVisibleNodes: TACLTreeListNodeList; inline;
    function GetColumns: TACLTreeListColumns;
    function GetEditingController: TACLTreeListEditingController;
    function GetFocusedColumn: TACLTreeListColumn;
    function GetFocusedGroup: TACLTreeListGroup;
    function GetFocusedNode: TACLTreeListNode; inline;
    function GetFocusedNodeData: Pointer;
    function GetGroup(Index: Integer): TACLTreeListGroup;
    function GetGroupCount: Integer;
    function GetHasSelection: Boolean; inline;
    function GetHitTest: TACLTreeListHitTest;
    function GetOnCanDeleteSelected: TACLTreeListConfirmationEvent;
    function GetOnColumnClick: TACLTreeListColumnClickEvent;
    function GetOnCompare: TACLTreeListNodeCompareEvent;
    function GetOnCustomDrawColumnBar: TACLCustomDrawEvent;
    function GetOnCustomDrawNode: TACLTreeListCustomDrawNodeEvent;
    function GetOnCustomDrawNodeCell: TACLTreeListCustomDrawNodeCellEvent;
    function GetOnCustomDrawNodeCellValue: TACLTreeListCustomDrawNodeCellValueEvent;
    function GetOnDragSorting: TNotifyEvent;
    function GetOnDragSortingNodeDrop: TACLTreeListDragSortingNodeDrop;
    function GetOnDragSortingNodeOver: TACLTreeListDragSortingNodeOver;
    function GetOnDrop: TACLTreeListDropEvent;
    function GetOnDropOver: TACLTreeListDropOverEvent;
    function GetOnEditing: TACLTreeListEditingEvent;
    function GetOnEdited: TACLTreeListEditedEvent;
    function GetOnEditCreate: TACLTreeListEditCreateEvent;
    function GetOnEditInitialize: TACLTreeListEditInitializeEvent;
    function GetOnEditKeyDown: TKeyEvent;
    function GetOnFocusedColumnChanged: TNotifyEvent;
    function GetOnFocusedNodeChanged: TNotifyEvent;
    function GetOnGetNodeBackground: TACLTreeListGetNodeBackgroundEvent;
    function GetOnGetNodeCellDisplayText: TACLTreeListGetNodeCellDisplayTextEvent;
    function GetOnGetNodeCellStyle: TACLTreeListGetNodeCellStyleEvent;
    function GetOnGetNodeChildren: TACLTreeListNodeEvent;
    function GetOnGetNodeClass: TACLTreeListGetNodeClassEvent;
    function GetOnGetNodeGroup: TACLTreeListGetNodeGroupEvent;
    function GetOnGetNodeHeight: TACLTreeListGetNodeHeightEvent;
    function GetOnNodeChecked: TACLTreeListNodeEvent;
    function GetOnNodeDblClicked: TACLTreeListNodeEvent;
    function GetOnNodeDeleted: TACLTreeListNodeEvent;
    function GetOnSelectionChanged: TNotifyEvent;
    function GetOnSorted: TNotifyEvent;
    function GetOnSorting: TNotifyEvent;
    function GetOnSortReset: TNotifyEvent;
    function GetOptionsBehavior: TACLTreeListOptionsBehavior;
    function GetOptionsCustomizing: TACLTreeListOptionsCustomizing;
    function GetOptionsSelection: TACLTreeListOptionsSelection;
    function GetOptionsView: TACLTreeListOptionsView;
    function GetRootNode: TACLTreeListNode; inline;
    function GetSelected(Index: Integer): TACLTreeListNode; inline;
    function GetSelectedCheckState: TCheckBoxState;
    function GetSelectedCount: Integer; inline;
    function GetStyleInplaceEdit: TACLStyleEdit;
    function GetStyleInplaceEditButton: TACLStyleEditButton;
    function GetStyleMenu: TACLStyleMenu;
    function GetStyle: TACLStyleTreeList;
    function GetSubClass: TACLTreeListSubClass; inline;
    function GetViewportX: Integer;
    function GetViewportY: Integer;
    function GetVisibleScrolls: TACLVisibleScrollBars; inline;
    procedure SetColumns(const AValue: TACLTreeListColumns);
    procedure SetFocusedColumn(const Value: TACLTreeListColumn);
    procedure SetFocusedGroup(const Value: TACLTreeListGroup);
    procedure SetFocusedNode(const AValue: TACLTreeListNode); inline;
    procedure SetFocusedNodeData(const Value: Pointer);
    procedure SetOnCanDeleteSelected(const Value: TACLTreeListConfirmationEvent);
    procedure SetOnColumnClick(const AValue: TACLTreeListColumnClickEvent);
    procedure SetOnCompare(const AValue: TACLTreeListNodeCompareEvent);
    procedure SetOnCustomDrawColumnBar(const AValue: TACLCustomDrawEvent);
    procedure SetOnCustomDrawNode(const AValue: TACLTreeListCustomDrawNodeEvent);
    procedure SetOnCustomDrawNodeCell(const AValue: TACLTreeListCustomDrawNodeCellEvent);
    procedure SetOnCustomDrawNodeCellValue(const Value: TACLTreeListCustomDrawNodeCellValueEvent);
    procedure SetOnDragSorting(const Value: TNotifyEvent);
    procedure SetOnDragSortingNodeDrop(const Value: TACLTreeListDragSortingNodeDrop);
    procedure SetOnDragSortingNodeOver(const Value: TACLTreeListDragSortingNodeOver);
    procedure SetOnDrop(const Value: TACLTreeListDropEvent);
    procedure SetOnDropOver(const Value: TACLTreeListDropOverEvent);
    procedure SetOnEditing(const AValue: TACLTreeListEditingEvent);
    procedure SetOnEdited(const AValue: TACLTreeListEditedEvent);
    procedure SetOnEditCreate(const AValue: TACLTreeListEditCreateEvent);
    procedure SetOnEditInitialize(const AValue: TACLTreeListEditInitializeEvent);
    procedure SetOnEditKeyDown(const AValue: TKeyEvent);
    procedure SetOnFocusedColumnChanged(const Value: TNotifyEvent);
    procedure SetOnFocusedNodeChanged(const AValue: TNotifyEvent);
    procedure SetOnGetNodeBackground(const AValue: TACLTreeListGetNodeBackgroundEvent);
    procedure SetOnGetNodeCellDisplayText(const Value: TACLTreeListGetNodeCellDisplayTextEvent);
    procedure SetOnGetNodeCellStyle(const AValue: TACLTreeListGetNodeCellStyleEvent);
    procedure SetOnGetNodeChildren(const AValue: TACLTreeListNodeEvent);
    procedure SetOnGetNodeClass(const AValue: TACLTreeListGetNodeClassEvent);
    procedure SetOnGetNodeGroup(const AValue: TACLTreeListGetNodeGroupEvent);
    procedure SetOnGetNodeHeight(const AValue: TACLTreeListGetNodeHeightEvent);
    procedure SetOnNodeChecked(const AValue: TACLTreeListNodeEvent);
    procedure SetOnNodeDblClicked(const Value: TACLTreeListNodeEvent);
    procedure SetOnNodeDeleted(const Value: TACLTreeListNodeEvent);
    procedure SetOnSelectionChanged(const AValue: TNotifyEvent);
    procedure SetOnSorted(const AValue: TNotifyEvent);
    procedure SetOnSorting(const AValue: TNotifyEvent);
    procedure SetOnSortReset(const Value: TNotifyEvent);
    procedure SetOptionsBehavior(const AValue: TACLTreeListOptionsBehavior);
    procedure SetOptionsCustomizing(const AValue: TACLTreeListOptionsCustomizing);
    procedure SetOptionsSelection(const AValue: TACLTreeListOptionsSelection);
    procedure SetOptionsView(const AValue: TACLTreeListOptionsView);
    procedure SetStyleInplaceEdit(const AValue: TACLStyleEdit);
    procedure SetStyleInplaceEditButton(const Value: TACLStyleEditButton);
    procedure SetStyleMenu(const AValue: TACLStyleMenu);
    procedure SetStyle(const AValue: TACLStyleTreeList);
    procedure SetViewportX(const Value: Integer);
    procedure SetViewportY(const Value: Integer);
    //
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    function CreateSubClass: TACLCompoundControlSubClass; override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    procedure SetFocusOnClick; override;
    // IACLFocusableControl2
    procedure SetFocusOnSearchResult;
    //
    property Columns: TACLTreeListColumns read GetColumns write SetColumns;
    property OptionsBehavior: TACLTreeListOptionsBehavior read GetOptionsBehavior write SetOptionsBehavior;
    property OptionsCustomizing: TACLTreeListOptionsCustomizing read GetOptionsCustomizing write SetOptionsCustomizing;
    property OptionsSelection: TACLTreeListOptionsSelection read GetOptionsSelection write SetOptionsSelection;
    property OptionsView: TACLTreeListOptionsView read GetOptionsView write SetOptionsView;
    property StyleInplaceEdit: TACLStyleEdit read GetStyleInplaceEdit write SetStyleInplaceEdit;
    property StyleInplaceEditButton: TACLStyleEditButton read GetStyleInplaceEditButton write SetStyleInplaceEditButton;
    property StyleMenu: TACLStyleMenu read GetStyleMenu write SetStyleMenu;
    property Style: TACLStyleTreeList read GetStyle write SetStyle;
    //
    property OnCanDeleteSelected: TACLTreeListConfirmationEvent read GetOnCanDeleteSelected write SetOnCanDeleteSelected;
    property OnColumnClick: TACLTreeListColumnClickEvent read GetOnColumnClick write SetOnColumnClick;
    property OnCompare: TACLTreeListNodeCompareEvent read GetOnCompare write SetOnCompare;
    property OnCustomDrawColumnBar: TACLCustomDrawEvent read GetOnCustomDrawColumnBar write SetOnCustomDrawColumnBar;
    property OnCustomDrawNode: TACLTreeListCustomDrawNodeEvent read GetOnCustomDrawNode write SetOnCustomDrawNode;
    property OnCustomDrawNodeCell: TACLTreeListCustomDrawNodeCellEvent read GetOnCustomDrawNodeCell write SetOnCustomDrawNodeCell;
    property OnCustomDrawNodeCellValue: TACLTreeListCustomDrawNodeCellValueEvent read GetOnCustomDrawNodeCellValue write SetOnCustomDrawNodeCellValue;
    property OnDragSorting: TNotifyEvent read GetOnDragSorting write SetOnDragSorting;
    property OnDragSortingNodeDrop: TACLTreeListDragSortingNodeDrop read GetOnDragSortingNodeDrop write SetOnDragSortingNodeDrop;
    property OnDragSortingNodeOver: TACLTreeListDragSortingNodeOver read GetOnDragSortingNodeOver write SetOnDragSortingNodeOver;
    property OnDrop: TACLTreeListDropEvent read GetOnDrop write SetOnDrop;
    property OnDropOver: TACLTreeListDropOverEvent read GetOnDropOver write SetOnDropOver;
    property OnEditApply: TACLTreeListEditingEvent read GetOnEditing write SetOnEditing;
    property OnEditing: TACLTreeListEditingEvent read GetOnEditing write SetOnEditing;
    property OnEdited: TACLTreeListEditedEvent read GetOnEdited write SetOnEdited;
    property OnEditCreate: TACLTreeListEditCreateEvent read GetOnEditCreate write SetOnEditCreate;
    property OnEditInitialize: TACLTreeListEditInitializeEvent read GetOnEditInitialize write SetOnEditInitialize;
    property OnEditKeyDown: TKeyEvent read GetOnEditKeyDown write SetOnEditKeyDown;
    property OnFocusedColumnChanged: TNotifyEvent read GetOnFocusedColumnChanged write SetOnFocusedColumnChanged;
    property OnFocusedNodeChanged: TNotifyEvent read GetOnFocusedNodeChanged write SetOnFocusedNodeChanged;
    property OnGetNodeBackground: TACLTreeListGetNodeBackgroundEvent read GetOnGetNodeBackground write SetOnGetNodeBackground;
    property OnGetNodeCellDisplayText: TACLTreeListGetNodeCellDisplayTextEvent read GetOnGetNodeCellDisplayText write SetOnGetNodeCellDisplayText;
    property OnGetNodeCellStyle: TACLTreeListGetNodeCellStyleEvent read GetOnGetNodeCellStyle write SetOnGetNodeCellStyle;
    property OnGetNodeChildren: TACLTreeListNodeEvent read GetOnGetNodeChildren write SetOnGetNodeChildren;
    property OnGetNodeClass: TACLTreeListGetNodeClassEvent read GetOnGetNodeClass write SetOnGetNodeClass;
    property OnGetNodeGroup: TACLTreeListGetNodeGroupEvent read GetOnGetNodeGroup write SetOnGetNodeGroup;
    property OnGetNodeHeight: TACLTreeListGetNodeHeightEvent read GetOnGetNodeHeight write SetOnGetNodeHeight;
    property OnNodeChecked: TACLTreeListNodeEvent read GetOnNodeChecked write SetOnNodeChecked;
    property OnNodeDblClicked: TACLTreeListNodeEvent read GetOnNodeDblClicked write SetOnNodeDblClicked;
    property OnNodeDeleted: TACLTreeListNodeEvent read GetOnNodeDeleted write SetOnNodeDeleted;
    property OnSelectionChanged: TNotifyEvent read GetOnSelectionChanged write SetOnSelectionChanged;
    property OnSorted: TNotifyEvent read GetOnSorted write SetOnSorted;
    property OnSortReset: TNotifyEvent read GetOnSortReset write SetOnSortReset;
    property OnSorting: TNotifyEvent read GetOnSorting write SetOnSorting;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Clear; inline;
    procedure DeleteSelected; inline;
    function Focused: Boolean; override;
    function ObjectAtPos(const X, Y: Integer): TObject;
    procedure ReloadData; inline;
    procedure StartEditing(AColumn: TACLTreeListColumn = nil); inline;

    // Customized Settings
    procedure ConfigLoad(AConfig: TACLIniFile; const ASection, AItem: UnicodeString); inline;
    procedure ConfigSave(AConfig: TACLIniFile; const ASection, AItem: UnicodeString); inline;

    // Make Top/Visible
    procedure MakeFirstVisibleFocused;
    procedure MakeTop(ANode: TACLTreeListNode); inline;
    procedure MakeVisible(ANode: TACLTreeListNode); inline;

    // Groupping
    procedure GroupBy(AColumn: TACLTreeListColumn; AResetPrevSortingParams: Boolean = False); inline;
    procedure Regroup; inline;
    procedure ResetGrouppingParams; inline;

    // Sorting
    procedure ResetSortingParams; inline;
    procedure Resort; inline;
    procedure Sort(ACustomSortProc: TACLTreeListNodeCompareEvent); inline;
    procedure SortBy(AColumn: TACLTreeListColumn; ADirection: TACLSortDirection; AResetPrevSortingParams: Boolean = False); overload; inline;
    procedure SortBy(AColumn: TACLTreeListColumn; AResetPrevSortingParams: Boolean = False); overload; inline;

    // Paths
    function GetPath: UnicodeString; overload; inline;
    function GetPath(ANode: TACLTreeListNode): UnicodeString; overload; inline;
    procedure SetPath(const APath: UnicodeString); inline;

    // Selection
    procedure SelectAll; inline;
    procedure SelectNone; inline;

    // Data Properties
    property AbsoluteVisibleNodes: TACLTreeListNodeList read GetAbsoluteVisibleNodes;
    property EditingController: TACLTreeListEditingController read GetEditingController;
    property FocusedColumn: TACLTreeListColumn read GetFocusedColumn write SetFocusedColumn;
    property FocusedGroup: TACLTreeListGroup read GetFocusedGroup write SetFocusedGroup;
    property FocusedNode: TACLTreeListNode read GetFocusedNode write SetFocusedNode;
    property FocusedNodeData: Pointer read GetFocusedNodeData write SetFocusedNodeData;
    property Group[Index: Integer]: TACLTreeListGroup read GetGroup;
    property GroupCount: Integer read GetGroupCount;
    property HasSelection: Boolean read GetHasSelection;
    property HitTest: TACLTreeListHitTest read GetHitTest;
    property RootNode: TACLTreeListNode read GetRootNode;
    property Selected[Index: Integer]: TACLTreeListNode read GetSelected;
    property SelectedCheckState: TCheckBoxState read GetSelectedCheckState;
    property SelectedCount: Integer read GetSelectedCount;
    property SubClass: TACLTreeListSubClass read GetSubClass;
    property ViewportX: Integer read GetViewportX write SetViewportX;
    property ViewportY: Integer read GetViewportY write SetViewportY;
    property VisibleScrolls: TACLVisibleScrollBars read GetVisibleScrolls;
  end;

  { TACLTreeList }

  TACLTreeList = class(TACLCustomTreeList)
  published
    property OnGetNodeClass; // must be first!
    //
    property Columns;
    property OptionsBehavior;
    property OptionsCustomizing;
    property OptionsSelection;
    property OptionsView;
    property ResourceCollection;
    property Style;
    property StyleHint;
    property StyleInplaceEdit;
    property StyleInplaceEditButton;
    property StyleScrollBox;
    //
    property OnCustomDrawColumnBar;
    property OnCustomDrawNode;
    property OnCustomDrawNodeCell;
    property OnCustomDrawNodeCellValue;
    //
    property OnCalculated;
    property OnCanDeleteSelected;
    property OnClick;
    property OnColumnClick;
    property OnCompare;
    property OnDblClick;
    property OnDragSorting;
    property OnDragSortingNodeDrop;
    property OnDragSortingNodeOver;
    property OnDrop;
    property OnDropOver;
    property OnDropSourceData;
    property OnDropSourceFinish;
    property OnDropSourceStart;
    property OnEditApply;
    property OnEditCreate;
    property OnEdited;
    property OnEditing;
    property OnEditInitialize;
    property OnEditKeyDown;
    property OnFocusedColumnChanged;
    property OnFocusedNodeChanged;
    property OnGetCursor;
    property OnGetNodeBackground;
    property OnGetNodeCellDisplayText;
    property OnGetNodeCellStyle;
    property OnGetNodeChildren;
    property OnGetNodeGroup;
    property OnGetNodeHeight;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnNodeChecked;
    property OnNodeDblClicked;
    property OnNodeDeleted;
    property OnSelectionChanged;
    property OnSorted;
    property OnSorting;
    property OnSortReset;
    property OnUpdateState;
  end;

implementation

{ TACLCustomTreeList }

constructor TACLCustomTreeList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Touch.InteractiveGestures := [igPan];
  Touch.InteractiveGestureOptions := [igoPanSingleFingerVertical, igoPanSingleFingerHorizontal, igoPanInertia];
  FocusOnClick := True;
  TabStop := True;
end;

procedure TACLCustomTreeList.Clear;
begin
  SubClass.Clear;
end;

procedure TACLCustomTreeList.DeleteSelected;
begin
  SubClass.DeleteSelected;
end;

function TACLCustomTreeList.Focused: Boolean;
begin
  Result := Assigned(SubClass) and (inherited or EditingController.IsEditing and EditingController.EditIntf.InplaceIsFocused);
end;

function TACLCustomTreeList.ObjectAtPos(const X, Y: Integer): TObject;
begin
  SubClass.UpdateHitTest(X, Y);
  Result := SubClass.HitTest.HitObject;
end;

procedure TACLCustomTreeList.ReloadData;
begin
  SubClass.ReloadData;
end;

procedure TACLCustomTreeList.StartEditing(AColumn: TACLTreeListColumn = nil);
begin
  if FocusedNode <> nil then
    SubClass.StartEditing(FocusedNode, AColumn);
end;

procedure TACLCustomTreeList.ConfigLoad(AConfig: TACLIniFile; const ASection, AItem: UnicodeString);
begin
  SubClass.ConfigLoad(AConfig, ASection, AItem);
end;

procedure TACLCustomTreeList.ConfigSave(AConfig: TACLIniFile; const ASection, AItem: UnicodeString);
begin
  SubClass.ConfigSave(AConfig, ASection, AItem);
end;

procedure TACLCustomTreeList.MakeFirstVisibleFocused;
begin
  if RootNode.ChildrenCount > 0 then
    FocusedNode := RootNode.Children[0];
end;

procedure TACLCustomTreeList.MakeTop(ANode: TACLTreeListNode);
begin
  SubClass.MakeTop(ANode);
end;

procedure TACLCustomTreeList.MakeVisible(ANode: TACLTreeListNode);
begin
  SubClass.MakeVisible(ANode);
end;

procedure TACLCustomTreeList.GroupBy(AColumn: TACLTreeListColumn; AResetPrevSortingParams: Boolean = False);
begin
  SubClass.GroupBy(AColumn, AResetPrevSortingParams);
end;

procedure TACLCustomTreeList.Regroup;
begin
  SubClass.Regroup;
end;

procedure TACLCustomTreeList.ResetGrouppingParams;
begin
  SubClass.ResetGrouppingParams;
end;

procedure TACLCustomTreeList.ResetSortingParams;
begin
  SubClass.ResetSortingParams;
end;

procedure TACLCustomTreeList.Resort;
begin
  SubClass.Resort;
end;

procedure TACLCustomTreeList.Sort(ACustomSortProc: TACLTreeListNodeCompareEvent);
begin
  SubClass.Sort(ACustomSortProc);
end;

procedure TACLCustomTreeList.SortBy(AColumn: TACLTreeListColumn; ADirection: TACLSortDirection; AResetPrevSortingParams: Boolean);
begin
  SubClass.SortBy(AColumn, ADirection, AResetPrevSortingParams);
end;

procedure TACLCustomTreeList.SortBy(AColumn: TACLTreeListColumn; AResetPrevSortingParams: Boolean);
begin
  SubClass.SortBy(AColumn, AResetPrevSortingParams);
end;

function TACLCustomTreeList.GetPath: UnicodeString;
begin
  Result := GetPath(FocusedNode);
end;

function TACLCustomTreeList.GetPath(ANode: TACLTreeListNode): UnicodeString;
begin
  Result := SubClass.GetPath(ANode);
end;

procedure TACLCustomTreeList.SetPath(const APath: UnicodeString);
begin
  SubClass.SetPath(APath);
end;

procedure TACLCustomTreeList.SelectAll;
begin
  SubClass.SelectAll;
end;

procedure TACLCustomTreeList.SelectNone;
begin
  SubClass.SelectNone;
end;

function TACLCustomTreeList.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLTreeListSubClass.Create(Self);
end;

function TACLCustomTreeList.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if Style.BackgroundColor.HasAlpha then
    Result := cbsSemitransparent
  else
    Result := cbsOpaque;
end;

procedure TACLCustomTreeList.SetFocusOnClick;
begin
  if not IsChild(Handle, GetFocus) then
    inherited SetFocusOnClick;
end;

procedure TACLCustomTreeList.SetFocusOnSearchResult;
begin
  if AbsoluteVisibleNodes.Count > 0 then
    FocusedNode := AbsoluteVisibleNodes[0];
  SetFocus;
end;

function TACLCustomTreeList.GetSubClass: TACLTreeListSubClass;
begin
  Result := TACLTreeListSubClass(inherited SubClass);
end;

function TACLCustomTreeList.GetAbsoluteVisibleNodes: TACLTreeListNodeList;
begin
  Result := SubClass.AbsoluteVisibleNodes;
end;

function TACLCustomTreeList.GetColumns: TACLTreeListColumns;
begin
  Result := SubClass.Columns;
end;

function TACLCustomTreeList.GetEditingController: TACLTreeListEditingController;
begin
  Result := SubClass.EditingController;
end;

function TACLCustomTreeList.GetFocusedColumn: TACLTreeListColumn;
begin
  Result := SubClass.FocusedColumn;
end;

function TACLCustomTreeList.GetFocusedGroup: TACLTreeListGroup;
begin
  Result := SubClass.FocusedGroup;
end;

function TACLCustomTreeList.GetFocusedNode: TACLTreeListNode;
begin
  Result := SubClass.FocusedNode;
end;

function TACLCustomTreeList.GetFocusedNodeData: Pointer;
begin
  Result := SubClass.FocusedNodeData;
end;

function TACLCustomTreeList.GetGroup(Index: Integer): TACLTreeListGroup;
begin
  Result := SubClass.Group[Index];
end;

function TACLCustomTreeList.GetGroupCount: Integer;
begin
  Result := SubClass.GroupCount;
end;

function TACLCustomTreeList.GetHasSelection: Boolean;
begin
  Result := SubClass.HasSelection;
end;

function TACLCustomTreeList.GetHitTest: TACLTreeListHitTest;
begin
  Result := SubClass.HitTest;
end;

function TACLCustomTreeList.GetOnCanDeleteSelected: TACLTreeListConfirmationEvent;
begin
  Result := SubClass.OnCanDeleteSelected;
end;

function TACLCustomTreeList.GetOnColumnClick: TACLTreeListColumnClickEvent;
begin
  Result := SubClass.OnColumnClick;
end;

function TACLCustomTreeList.GetOnCompare: TACLTreeListNodeCompareEvent;
begin
  Result := SubClass.OnCompare;
end;

function TACLCustomTreeList.GetOnCustomDrawColumnBar: TACLCustomDrawEvent;
begin
  Result := SubClass.OnCustomDrawColumnBar;
end;

function TACLCustomTreeList.GetOnCustomDrawNode: TACLTreeListCustomDrawNodeEvent;
begin
  Result := SubClass.OnCustomDrawNode;
end;

function TACLCustomTreeList.GetOnCustomDrawNodeCell: TACLTreeListCustomDrawNodeCellEvent;
begin
  Result := SubClass.OnCustomDrawNodeCell;
end;

function TACLCustomTreeList.GetOnCustomDrawNodeCellValue: TACLTreeListCustomDrawNodeCellValueEvent;
begin
  Result := SubClass.OnCustomDrawNodeCellValue;
end;

function TACLCustomTreeList.GetOnDragSorting: TNotifyEvent;
begin
  Result := SubClass.OnDragSorting;
end;

function TACLCustomTreeList.GetOnDragSortingNodeDrop: TACLTreeListDragSortingNodeDrop;
begin
  Result := SubClass.OnDragSortingNodeDrop;
end;

function TACLCustomTreeList.GetOnDragSortingNodeOver: TACLTreeListDragSortingNodeOver;
begin
  Result := SubClass.OnDragSortingNodeOver;
end;

function TACLCustomTreeList.GetOnDrop: TACLTreeListDropEvent;
begin
  Result := SubClass.OnDrop;
end;

function TACLCustomTreeList.GetOnDropOver: TACLTreeListDropOverEvent;
begin
  Result := SubClass.OnDropOver;
end;

function TACLCustomTreeList.GetOnEditCreate: TACLTreeListEditCreateEvent;
begin
  Result := SubClass.OnEditCreate;
end;

function TACLCustomTreeList.GetOnEdited: TACLTreeListEditedEvent;
begin
  Result := SubClass.OnEdited;
end;

function TACLCustomTreeList.GetOnEditing: TACLTreeListEditingEvent;
begin
  Result := SubClass.OnEditing;
end;

function TACLCustomTreeList.GetOnEditInitialize: TACLTreeListEditInitializeEvent;
begin
  Result := SubClass.OnEditInitialize;
end;

function TACLCustomTreeList.GetOnEditKeyDown: TKeyEvent;
begin
  Result := SubClass.OnEditKeyDown;
end;

function TACLCustomTreeList.GetOnFocusedColumnChanged: TNotifyEvent;
begin
  Result := SubClass.OnFocusedColumnChanged;
end;

function TACLCustomTreeList.GetOnFocusedNodeChanged: TNotifyEvent;
begin
  Result := SubClass.OnFocusedNodeChanged;
end;

function TACLCustomTreeList.GetOnGetNodeBackground: TACLTreeListGetNodeBackgroundEvent;
begin
  Result := SubClass.OnGetNodeBackground;
end;

function TACLCustomTreeList.GetOnGetNodeCellDisplayText: TACLTreeListGetNodeCellDisplayTextEvent;
begin
  Result := SubClass.OnGetNodeCellDisplayText;
end;

function TACLCustomTreeList.GetOnGetNodeCellStyle: TACLTreeListGetNodeCellStyleEvent;
begin
  Result := SubClass.OnGetNodeCellStyle;
end;

function TACLCustomTreeList.GetOnGetNodeChildren: TACLTreeListNodeEvent;
begin
  Result := SubClass.OnGetNodeChildren;
end;

function TACLCustomTreeList.GetOnGetNodeClass: TACLTreeListGetNodeClassEvent;
begin
  Result := SubClass.OnGetNodeClass;
end;

function TACLCustomTreeList.GetOnGetNodeGroup: TACLTreeListGetNodeGroupEvent;
begin
  Result := SubClass.OnGetNodeGroup;
end;

function TACLCustomTreeList.GetOnGetNodeHeight: TACLTreeListGetNodeHeightEvent;
begin
  Result := SubClass.OnGetNodeHeight;
end;

function TACLCustomTreeList.GetOnNodeChecked: TACLTreeListNodeEvent;
begin
  Result := SubClass.OnNodeChecked;
end;

function TACLCustomTreeList.GetOnNodeDblClicked: TACLTreeListNodeEvent;
begin
  Result := SubClass.OnNodeDblClicked;
end;

function TACLCustomTreeList.GetOnNodeDeleted: TACLTreeListNodeEvent;
begin
  Result := SubClass.OnNodeDeleted;
end;

function TACLCustomTreeList.GetOnSelectionChanged: TNotifyEvent;
begin
  Result := SubClass.OnSelectionChanged;
end;

function TACLCustomTreeList.GetOnSorted: TNotifyEvent;
begin
  Result := SubClass.OnSorted;
end;

function TACLCustomTreeList.GetOnSorting: TNotifyEvent;
begin
  Result := SubClass.OnSorting;
end;

function TACLCustomTreeList.GetOnSortReset: TNotifyEvent;
begin
  Result := SubClass.OnSortReset;
end;

function TACLCustomTreeList.GetOptionsBehavior: TACLTreeListOptionsBehavior;
begin
  Result := SubClass.OptionsBehavior;
end;

function TACLCustomTreeList.GetOptionsCustomizing: TACLTreeListOptionsCustomizing;
begin
  Result := SubClass.OptionsCustomizing;
end;

function TACLCustomTreeList.GetOptionsSelection: TACLTreeListOptionsSelection;
begin
  Result := SubClass.OptionsSelection;
end;

function TACLCustomTreeList.GetOptionsView: TACLTreeListOptionsView;
begin
  Result := SubClass.OptionsView;
end;

function TACLCustomTreeList.GetRootNode: TACLTreeListNode;
begin
  Result := SubClass.RootNode;
end;

function TACLCustomTreeList.GetSelected(Index: Integer): TACLTreeListNode;
begin
  Result := SubClass.Selected[Index];
end;

function TACLCustomTreeList.GetSelectedCheckState: TCheckBoxState;
begin
  Result := SubClass.SelectedCheckState;
end;

function TACLCustomTreeList.GetSelectedCount: Integer;
begin
  Result := SubClass.SelectedCount;
end;

function TACLCustomTreeList.GetStyleInplaceEdit: TACLStyleEdit;
begin
  Result := SubClass.StyleInplaceEdit;
end;

function TACLCustomTreeList.GetStyleInplaceEditButton: TACLStyleEditButton;
begin
  Result := SubClass.StyleInplaceEditButton;
end;

function TACLCustomTreeList.GetStyleMenu: TACLStyleMenu;
begin
  Result := SubClass.StyleMenu;
end;

function TACLCustomTreeList.GetStyle: TACLStyleTreeList;
begin
  Result := SubClass.Style;
end;

function TACLCustomTreeList.GetViewportX: Integer;
begin
  Result := SubClass.ViewportX;
end;

function TACLCustomTreeList.GetViewportY: Integer;
begin
  Result := SubClass.ViewportY;
end;

function TACLCustomTreeList.GetVisibleScrolls: TACLVisibleScrollBars;
begin
  Result := SubClass.VisibleScrolls;
end;

procedure TACLCustomTreeList.SetColumns(const AValue: TACLTreeListColumns);
begin
  SubClass.Columns := AValue;
end;

procedure TACLCustomTreeList.SetFocusedColumn(const Value: TACLTreeListColumn);
begin
  SubClass.FocusedColumn := Value;
end;

procedure TACLCustomTreeList.SetFocusedGroup(const Value: TACLTreeListGroup);
begin
  SubClass.FocusedGroup := Value;
end;

procedure TACLCustomTreeList.SetFocusedNode(const AValue: TACLTreeListNode);
begin
  SubClass.FocusedNode := AValue;
end;

procedure TACLCustomTreeList.SetFocusedNodeData(const Value: Pointer);
begin
  SubClass.FocusedNodeData := Value;
end;

procedure TACLCustomTreeList.SetOnCanDeleteSelected(const Value: TACLTreeListConfirmationEvent);
begin
  SubClass.OnCanDeleteSelected := Value;
end;

procedure TACLCustomTreeList.SetOnColumnClick(const AValue: TACLTreeListColumnClickEvent);
begin
  SubClass.OnColumnClick := AValue;
end;

procedure TACLCustomTreeList.SetOnCompare(const AValue: TACLTreeListNodeCompareEvent);
begin
  SubClass.OnCompare := AValue;
end;

procedure TACLCustomTreeList.SetOnCustomDrawColumnBar(const AValue: TACLCustomDrawEvent);
begin
  SubClass.OnCustomDrawColumnBar := AValue;
end;

procedure TACLCustomTreeList.SetOnCustomDrawNode(const AValue: TACLTreeListCustomDrawNodeEvent);
begin
  SubClass.OnCustomDrawNode := AValue;
end;

procedure TACLCustomTreeList.SetOnCustomDrawNodeCell(const AValue: TACLTreeListCustomDrawNodeCellEvent);
begin
  SubClass.OnCustomDrawNodeCell := AValue;
end;

procedure TACLCustomTreeList.SetOnCustomDrawNodeCellValue(const Value: TACLTreeListCustomDrawNodeCellValueEvent);
begin
  SubClass.OnCustomDrawNodeCellValue := Value;
end;

procedure TACLCustomTreeList.SetOnDragSorting(const Value: TNotifyEvent);
begin
  SubClass.OnDragSorting := Value;
end;

procedure TACLCustomTreeList.SetOnDragSortingNodeDrop(const Value: TACLTreeListDragSortingNodeDrop);
begin
  SubClass.OnDragSortingNodeDrop := Value;
end;

procedure TACLCustomTreeList.SetOnDragSortingNodeOver(const Value: TACLTreeListDragSortingNodeOver);
begin
  SubClass.OnDragSortingNodeOver := Value;
end;

procedure TACLCustomTreeList.SetOnDrop(const Value: TACLTreeListDropEvent);
begin
  SubClass.OnDrop := Value;
end;

procedure TACLCustomTreeList.SetOnDropOver(const Value: TACLTreeListDropOverEvent);
begin
  SubClass.OnDropOver := Value;
end;

procedure TACLCustomTreeList.SetOnEditCreate(const AValue: TACLTreeListEditCreateEvent);
begin
  SubClass.OnEditCreate := AValue;
end;

procedure TACLCustomTreeList.SetOnEdited(const AValue: TACLTreeListEditedEvent);
begin
  SubClass.OnEdited := AValue;
end;

procedure TACLCustomTreeList.SetOnEditing(const AValue: TACLTreeListEditingEvent);
begin
  SubClass.OnEditing := AValue;
end;

procedure TACLCustomTreeList.SetOnEditInitialize(const AValue: TACLTreeListEditInitializeEvent);
begin
  SubClass.OnEditInitialize := AValue;
end;

procedure TACLCustomTreeList.SetOnEditKeyDown(const AValue: TKeyEvent);
begin
  SubClass.OnEditKeyDown := AValue;
end;

procedure TACLCustomTreeList.SetOnFocusedColumnChanged(const Value: TNotifyEvent);
begin
  SubClass.OnFocusedColumnChanged := Value;
end;

procedure TACLCustomTreeList.SetOnFocusedNodeChanged(const AValue: TNotifyEvent);
begin
  SubClass.OnFocusedNodeChanged := AValue;
end;

procedure TACLCustomTreeList.SetOnGetNodeBackground(const AValue: TACLTreeListGetNodeBackgroundEvent);
begin
  SubClass.OnGetNodeBackground := AValue;
end;

procedure TACLCustomTreeList.SetOnGetNodeCellDisplayText(const Value: TACLTreeListGetNodeCellDisplayTextEvent);
begin
  SubClass.OnGetNodeCellDisplayText := Value;
end;

procedure TACLCustomTreeList.SetOnGetNodeCellStyle(const AValue: TACLTreeListGetNodeCellStyleEvent);
begin
  SubClass.OnGetNodeCellStyle := AValue;
end;

procedure TACLCustomTreeList.SetOnGetNodeChildren(const AValue: TACLTreeListNodeEvent);
begin
  SubClass.OnGetNodeChildren := AValue;
end;

procedure TACLCustomTreeList.SetOnGetNodeClass(const AValue: TACLTreeListGetNodeClassEvent);
begin
  SubClass.OnGetNodeClass := AValue;
end;

procedure TACLCustomTreeList.SetOnGetNodeGroup(const AValue: TACLTreeListGetNodeGroupEvent);
begin
  SubClass.OnGetNodeGroup := AValue;
end;

procedure TACLCustomTreeList.SetOnGetNodeHeight(const AValue: TACLTreeListGetNodeHeightEvent);
begin
  SubClass.OnGetNodeHeight := AValue;
end;

procedure TACLCustomTreeList.SetOnNodeChecked(const AValue: TACLTreeListNodeEvent);
begin
  SubClass.OnNodeChecked := AValue;
end;

procedure TACLCustomTreeList.SetOnNodeDblClicked(const Value: TACLTreeListNodeEvent);
begin
  SubClass.OnNodeDblClicked := Value;
end;

procedure TACLCustomTreeList.SetOnNodeDeleted(const Value: TACLTreeListNodeEvent);
begin
  SubClass.OnNodeDeleted := Value;
end;

procedure TACLCustomTreeList.SetOnSelectionChanged(const AValue: TNotifyEvent);
begin
  SubClass.OnSelectionChanged := AValue;
end;

procedure TACLCustomTreeList.SetOnSorted(const AValue: TNotifyEvent);
begin
  SubClass.OnSorted := AValue;
end;

procedure TACLCustomTreeList.SetOnSorting(const AValue: TNotifyEvent);
begin
  SubClass.OnSorting := AValue;
end;

procedure TACLCustomTreeList.SetOnSortReset(const Value: TNotifyEvent);
begin
  SubClass.OnSortReset := Value;
end;

procedure TACLCustomTreeList.SetOptionsBehavior(const AValue: TACLTreeListOptionsBehavior);
begin
  SubClass.OptionsBehavior := AValue;
end;

procedure TACLCustomTreeList.SetOptionsCustomizing(const AValue: TACLTreeListOptionsCustomizing);
begin
  SubClass.OptionsCustomizing := AValue;
end;

procedure TACLCustomTreeList.SetOptionsSelection(const AValue: TACLTreeListOptionsSelection);
begin
  SubClass.OptionsSelection := AValue;
end;

procedure TACLCustomTreeList.SetOptionsView(const AValue: TACLTreeListOptionsView);
begin
  SubClass.OptionsView := AValue;
end;

procedure TACLCustomTreeList.SetStyleInplaceEdit(const AValue: TACLStyleEdit);
begin
  SubClass.StyleInplaceEdit := AValue;
end;

procedure TACLCustomTreeList.SetStyleInplaceEditButton(const Value: TACLStyleEditButton);
begin
  SubClass.StyleInplaceEditButton := Value;
end;

procedure TACLCustomTreeList.SetStyleMenu(const AValue: TACLStyleMenu);
begin
  SubClass.StyleMenu := AValue;
end;

procedure TACLCustomTreeList.SetStyle(const AValue: TACLStyleTreeList);
begin
  SubClass.Style := AValue;
end;

procedure TACLCustomTreeList.SetViewportX(const Value: Integer);
begin
  SubClass.ViewportX := Value;
end;

procedure TACLCustomTreeList.SetViewportY(const Value: Integer);
begin
  SubClass.ViewportY := Value;
end;

procedure TACLCustomTreeList.WMGetDlgCode(var AMessage: TWMGetDlgCode);
begin
  AMessage.Result := DLGC_WANTARROWS or DLGC_WANTCHARS;
end;

end.
