////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   TreeList Options
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.TreeList.Options;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Generics.Defaults,
  {System.}Classes,
  {System.}SysUtils,
  System.UITypes,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
  {Vcl.}ImgList,
  // ACL
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.ObjectLinks,
  ACL.Threading,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Resources,
  ACL.Utils.Common;

type

  { IACLTreeListOptionsListener }

  IACLTreeListOptionsListener = interface
  ['{FF1054E8-6B4A-4011-926C-02B5E3A2AA4F}']
    procedure BeginUpdate;
    procedure EndUpdate;

    procedure Changed(AChanges: TIntegerSet);
    procedure FullRefresh;
    procedure ReloadData;
    procedure SelectNone;
  end;

  { TACLTreeListCustomOptions }

  TACLTreeListCustomOptions = class(TACLCustomOptionsPersistent)
  strict private
    FTreeList: IACLTreeListOptionsListener;
  protected
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
  public
    constructor Create(const ATreeList: IACLTreeListOptionsListener); virtual;
    //# Properties
    property TreeList: IACLTreeListOptionsListener read FTreeList;
  end;

  { TACLTreeListCustomOptionsImage }

  TACLTreeListCustomOptionsImage = class(TACLTreeListCustomOptions,
    IACLObjectRemoveNotify)
  strict private
    FImageLink: TChangeLink;
    FImages: TCustomImageList;

    procedure ImagesChangeHandler(Sender: TObject);
    procedure SetImages(AValue: TCustomImageList);
    // IACLObjectRemoveNotify
    procedure Removing(AComponent: TObject);
  protected
    procedure DoAssign(Source: TPersistent); override;
  public
    procedure BeforeDestruction; override;
  published
    property Images: TCustomImageList read FImages write SetImages;
  end;

  { TACLTreeListOptionsBehavior }

  TACLTreeListEditingStartingMode = (esmOnDoubleClick, esmOnSingleClick);

  TACLTreeListOptionsBehavior = class(TACLTreeListCustomOptions)
  strict private
    FAllowDefocus: Boolean;
    FAutoBestFit: Boolean;
    FAutoCheckParents: Boolean;
    FAutoCheckChildren: Boolean;
    FCellHints: Boolean;
    FDeleting: Boolean;
    FDragSorting: Boolean;
    FDragSortingAllowChangeLevel: Boolean;
    FDropSource: Boolean;
    FDropTarget: Boolean;
    FDropTargetAllowCreateLevel: Boolean;
    FEditing: Boolean;
    FEditingStartingMode: TACLTreeListEditingStartingMode;
    FGroups: Boolean;
    FGroupsAllowCollapse: Boolean;
    FGroupsFocus: Boolean;
    FGroupsFocusOnClick: Boolean;
    FHotTrack: Boolean;
    FIncSearchColumnIndex: Integer;
    FIncSearchMode: TACLIncrementalSearchMode;
    FMouseWheelScrollLines: Integer;
    FSortingMode: TACLTreeListSortingMode;
    FSortingUseMultithreading: Boolean;

    procedure SetAutoBestFit(AValue: Boolean);
    procedure SetAutoCheckChildren(AValue: Boolean);
    procedure SetAutoCheckParents(const Value: Boolean);
    procedure SetDropTarget(AValue: Boolean);
    procedure SetGroups(AValue: Boolean);
    procedure SetGroupsAllowCollapse(AValue: Boolean);
    procedure SetGroupsFocus(const Value: Boolean);
    procedure SetGroupsFocusOnClick(const Value: Boolean);
    procedure SetHotTrack(AValue: Boolean);
    procedure SetIncSearchColumnIndex(AValue: Integer);
    procedure SetIncSearchMode(AValue: TACLIncrementalSearchMode);
    procedure SetSortingMode(AValue: TACLTreeListSortingMode);
  protected
    procedure DoAssign(Source: TPersistent); override;
  public
    constructor Create(const ATreeList: IACLTreeListOptionsListener); override;
  published
    property AllowDefocus: Boolean read FAllowDefocus write FAllowDefocus default True;
    property AutoBestFit: Boolean read FAutoBestFit write SetAutoBestFit default False;
    property AutoCheckChildren: Boolean read FAutoCheckChildren write SetAutoCheckChildren default False;
    property AutoCheckParents: Boolean read FAutoCheckParents write SetAutoCheckParents default False;
    property CellHints: Boolean read FCellHints write FCellHints default True;
    property Deleting: Boolean read FDeleting write FDeleting default False;
    property DragSorting: Boolean read FDragSorting write FDragSorting default False;
    property DragSortingAllowChangeLevel: Boolean read FDragSortingAllowChangeLevel write FDragSortingAllowChangeLevel default False;
    property DropSource: Boolean read FDropSource write FDropSource default False;
    property DropTarget: Boolean read FDropTarget write SetDropTarget default False;
    property DropTargetAllowCreateLevel: Boolean read FDropTargetAllowCreateLevel write FDropTargetAllowCreateLevel default False;
    property Editing: Boolean read FEditing write FEditing default False;
    property EditingStartingMode: TACLTreeListEditingStartingMode read FEditingStartingMode write FEditingStartingMode default esmOnDoubleClick;
    property Groups: Boolean read FGroups write SetGroups default False;
    property GroupsAllowCollapse: Boolean read FGroupsAllowCollapse write SetGroupsAllowCollapse default False;
    property GroupsFocus: Boolean read FGroupsFocus write SetGroupsFocus default True;
    property GroupsFocusOnClick: Boolean read FGroupsFocusOnClick write SetGroupsFocusOnClick default False;
    property HotTrack: Boolean read FHotTrack write SetHotTrack default False;
    property IncSearchColumnIndex: Integer read FIncSearchColumnIndex write SetIncSearchColumnIndex default -1;
    property IncSearchMode: TACLIncrementalSearchMode read FIncSearchMode write SetIncSearchMode default ismSearch;
    property MouseWheelScrollLines: Integer read FMouseWheelScrollLines write FMouseWheelScrollLines default 0;
    property SortingMode: TACLTreeListSortingMode read FSortingMode write SetSortingMode default tlsmMulti;
    property SortingUseMultithreading: Boolean read FSortingUseMultithreading write FSortingUseMultithreading default True;
  end;

  { TACLTreeListOptionsCustomizing }

  TACLTreeListOptionsCustomizing = class(TACLTreeListCustomOptions)
  strict private
    FColumnOrder: Boolean;
    FColumnVisibility: Boolean;
    FColumnWidth: Boolean;
  protected
    procedure DoAssign(Source: TPersistent); override;
  public
    procedure AfterConstruction; override;
  published
    property ColumnOrder: Boolean read FColumnOrder write FColumnOrder default False;
    property ColumnWidth: Boolean read FColumnWidth write FColumnWidth default True;
    property ColumnVisibility: Boolean read FColumnVisibility write FColumnVisibility default False;
  end;

  { TACLTreeListOptionsSelection }

  TACLTreeListOptionsSelection = class(TACLTreeListCustomOptions)
  strict private
    FFocusCell: Boolean;
    FMultiSelect: Boolean;

    procedure SetFocusCell(AValue: Boolean);
    procedure SetMultiSelect(AValue: Boolean);
  protected
    procedure DoAssign(Source: TPersistent); override;
  published
    property FocusCell: Boolean read FFocusCell write SetFocusCell default False;
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect default False;
  end;

  { TACLTreeListOptionsViewColumns }

  TACLTreeListOptionsViewColumns = class(TACLTreeListCustomOptionsImage)
  strict private
    FAutoWidth: Boolean;
    FHeight: Integer;
    FVisible: Boolean;

    procedure SetAutoWidth(AValue: Boolean);
    procedure SetHeight(AValue: Integer);
    procedure SetVisible(AValue: Boolean);
  protected
    procedure DoAssign(Source: TPersistent); override;
  public
    constructor Create(const ATreeList: IACLTreeListOptionsListener); override;
  published
    property AutoWidth: Boolean read FAutoWidth write SetAutoWidth default False;
    property Height: Integer read FHeight write SetHeight default tlAutoHeight;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

  { TACLTreeListOptionsViewNodes }

  TACLTreeListOptionsViewNodes = class(TACLTreeListCustomOptionsImage)
  strict private
    FGridLines: TACLTreeListGridLines;
    FHeight: Integer;
    FImageAlignment: TAlignment;

    procedure SetGridLines(AValue: TACLTreeListGridLines);
    procedure SetHeight(AValue: Integer);
    procedure SetImageAlignment(AValue: TAlignment);
  protected
    procedure DoAssign(Source: TPersistent); override;
  public
    constructor Create(const ATreeList: IACLTreeListOptionsListener); override;
  published
    property GridLines: TACLTreeListGridLines read FGridLines write SetGridLines default [tlglVertical, tlglHorzontal];
    property Height: Integer read FHeight write SetHeight default tlAutoHeight;
    property ImageAlignment: TAlignment read FImageAlignment write SetImageAlignment default taLeftJustify;
  end;

  { TACLTreeListOptionsView }

  TACLTreeListOptionsView = class(TACLTreeListCustomOptions)
  strict private
    FBorders: TACLBorders;
    FCheckBoxes: Boolean;
    FColumns: TACLTreeListOptionsViewColumns;
    FGroupHeight: Integer;
    FNodes: TACLTreeListOptionsViewNodes;

    procedure SetBorders(AValue: TACLBorders);
    procedure SetCheckBoxes(AValue: Boolean);
    procedure SetColumns(AValue: TACLTreeListOptionsViewColumns);
    procedure SetGroupHeight(const Value: Integer);
    procedure SetNodes(AValue: TACLTreeListOptionsViewNodes);
  protected
    function CreateColumns: TACLTreeListOptionsViewColumns; virtual;
    function CreateNodes: TACLTreeListOptionsViewNodes; virtual;
    procedure DoAssign(Source: TPersistent); override;
  public
    constructor Create(const ATreeList: IACLTreeListOptionsListener); override;
    destructor Destroy; override;
  published
    property Borders: TACLBorders read FBorders write SetBorders default acAllBorders;
    property Columns: TACLTreeListOptionsViewColumns read FColumns write SetColumns;
    property Nodes: TACLTreeListOptionsViewNodes read FNodes write SetNodes;
    property GroupHeight: Integer read FGroupHeight write SetGroupHeight default tlAutoHeight;
    property CheckBoxes: Boolean read FCheckBoxes write SetCheckBoxes default False; // not change order
  end;

implementation

uses
  Math;

{ TACLTreeListCustomOptions }

constructor TACLTreeListCustomOptions.Create(const ATreeList: IACLTreeListOptionsListener);
begin
  inherited Create;
  FTreeList := ATreeList;
end;

procedure TACLTreeListCustomOptions.DoChanged(AChanges: TACLPersistentChanges);
const
  Map: array[TACLPersistentChange] of Byte = (cccnStruct, cccnLayout, cccnContent);
var
  AIndex: TACLPersistentChange;
  ATreeListChanges: TIntegerSet;
begin
  ATreeListChanges := [];
  for AIndex := Low(AIndex) to High(AIndex) do
  begin
    if AIndex in AChanges then
      Include(ATreeListChanges, Map[AIndex]);
  end;
  TreeList.Changed(ATreeListChanges);
end;

{ TACLTreeListCustomOptionsImage }

procedure TACLTreeListCustomOptionsImage.BeforeDestruction;
begin
  inherited BeforeDestruction;
  Images := nil;
end;

procedure TACLTreeListCustomOptionsImage.DoAssign(Source: TPersistent);
begin
  if Source is TACLTreeListCustomOptionsImage then
    Images := TACLTreeListCustomOptionsImage(Source).Images;
end;

procedure TACLTreeListCustomOptionsImage.ImagesChangeHandler(Sender: TObject);
begin
  Changed([apcContent, apcLayout]);
end;

procedure TACLTreeListCustomOptionsImage.SetImages(AValue: TCustomImageList);
begin
  if Images <> AValue then
  begin
    if Images <> nil then
    begin
      TACLObjectLinks.UnregisterRemoveListener(Self, Images);
      Images.UnRegisterChanges(FImageLink);
      FreeAndNil(FImageLink);
      FImages := nil;
    end;
    if AValue <> nil then
    begin
      FImages := AValue;
      FImageLink := TChangeLink.Create;
      FImageLink.OnChange := ImagesChangeHandler;
      TACLObjectLinks.RegisterRemoveListener(Images, Self);
      Images.RegisterChanges(FImageLink);
    end;
    ImagesChangeHandler(nil);
  end;
end;

procedure TACLTreeListCustomOptionsImage.Removing(AComponent: TObject);
begin
  if Images = AComponent then
    Images := nil;
end;

{ TACLTreeListOptionsBehavior }

constructor TACLTreeListOptionsBehavior.Create(const ATreeList: IACLTreeListOptionsListener);
begin
  inherited Create(ATreeList);
  FAllowDefocus := True;
  FIncSearchColumnIndex := -1;
  FSortingMode := tlsmMulti;
  FSortingUseMultithreading := True;
  FGroupsFocus := True;
  FCellHints := True;
end;

procedure TACLTreeListOptionsBehavior.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);
  if Source is TACLTreeListOptionsBehavior then
  begin
    AllowDefocus := TACLTreeListOptionsBehavior(Source).AllowDefocus;
    AutoBestFit := TACLTreeListOptionsBehavior(Source).AutoBestFit;
    AutoCheckParents := TACLTreeListOptionsBehavior(Source).AutoCheckParents;
    AutoCheckChildren := TACLTreeListOptionsBehavior(Source).AutoCheckChildren;
    CellHints := TACLTreeListOptionsBehavior(Source).CellHints;
    Deleting := TACLTreeListOptionsBehavior(Source).Deleting;
    DragSorting := TACLTreeListOptionsBehavior(Source).DragSorting;
    DragSortingAllowChangeLevel := TACLTreeListOptionsBehavior(Source).DragSortingAllowChangeLevel;
    DropSource := TACLTreeListOptionsBehavior(Source).DropSource;
    DropTarget := TACLTreeListOptionsBehavior(Source).DropTarget;
    DropTargetAllowCreateLevel := TACLTreeListOptionsBehavior(Source).DropTargetAllowCreateLevel;
    Groups := TACLTreeListOptionsBehavior(Source).Groups;
    GroupsAllowCollapse := TACLTreeListOptionsBehavior(Source).GroupsAllowCollapse;
    GroupsFocus := TACLTreeListOptionsBehavior(Source).GroupsFocus;
    GroupsFocusOnClick := TACLTreeListOptionsBehavior(Source).GroupsFocusOnClick;
    HotTrack := TACLTreeListOptionsBehavior(Source).HotTrack;
    IncSearchColumnIndex := TACLTreeListOptionsBehavior(Source).IncSearchColumnIndex;
    IncSearchMode := TACLTreeListOptionsBehavior(Source).IncSearchMode;
    Editing := TACLTreeListOptionsBehavior(Source).Editing;
    EditingStartingMode := TACLTreeListOptionsBehavior(Source).EditingStartingMode;
    SortingMode := TACLTreeListOptionsBehavior(Source).SortingMode;
    SortingUseMultithreading := TACLTreeListOptionsBehavior(Source).SortingUseMultithreading;
    MouseWheelScrollLines := TACLTreeListOptionsBehavior(Source).MouseWheelScrollLines;
  end;
end;

procedure TACLTreeListOptionsBehavior.SetAutoBestFit(AValue: Boolean);
begin
  if FAutoBestFit <> AValue then
  begin
    FAutoBestFit := AValue;
    TreeList.Changed([cccnLayout]);
  end;
end;

procedure TACLTreeListOptionsBehavior.SetAutoCheckParents(const Value: Boolean);
begin
  if FAutoCheckParents <> Value then
  begin
    FAutoCheckParents := Value;
    TreeList.Changed([cccnContent]);
  end;
end;

procedure TACLTreeListOptionsBehavior.SetAutoCheckChildren(AValue: Boolean);
begin
  if FAutoCheckChildren <> AValue then
  begin
    FAutoCheckChildren := AValue;
    TreeList.Changed([cccnContent]);
  end;
end;

procedure TACLTreeListOptionsBehavior.SetDropTarget(AValue: Boolean);
begin
  if FDropTarget <> AValue then
  begin
    FDropTarget := AValue;
    TreeList.Changed([tlcnSettingsDropTarget]);
  end;
end;

procedure TACLTreeListOptionsBehavior.SetGroups(AValue: Boolean);
begin
  if Groups <> AValue then
  begin
    FGroups := AValue;
    TreeList.Changed([tlcnGrouping]);
  end;
end;

procedure TACLTreeListOptionsBehavior.SetGroupsAllowCollapse(AValue: Boolean);
begin
  if GroupsAllowCollapse <> AValue then
  begin
    FGroupsAllowCollapse := AValue;
    TreeList.FullRefresh;
  end;
end;

procedure TACLTreeListOptionsBehavior.SetGroupsFocus(const Value: Boolean);
begin
  if FGroupsFocus <> Value then
  begin
    FGroupsFocus := Value;
    TreeList.Changed([tlcnSettingsFocus]);
  end;
end;

procedure TACLTreeListOptionsBehavior.SetGroupsFocusOnClick(const Value: Boolean);
begin
  if FGroupsFocusOnClick <> Value then
  begin
    FGroupsFocusOnClick := Value;
    TreeList.Changed([tlcnSettingsFocus]);
  end;
end;

procedure TACLTreeListOptionsBehavior.SetHotTrack(AValue: Boolean);
begin
  if FHotTrack <> AValue then
  begin
    FHotTrack := AValue;
    TreeList.Changed([cccnContent]);
  end;
end;

procedure TACLTreeListOptionsBehavior.SetIncSearchColumnIndex(AValue: Integer);
begin
  AValue := Max(-1, AValue);
  if FIncSearchColumnIndex <> AValue then
  begin
    FIncSearchColumnIndex := AValue;
    TreeList.Changed([tlcnSettingsIncSearch]);
  end;
end;

procedure TACLTreeListOptionsBehavior.SetIncSearchMode(AValue: TACLIncrementalSearchMode);
begin
  if FIncSearchMode <> AValue then
  begin
    FIncSearchMode := AValue;
    TreeList.Changed([tlcnSettingsIncSearch]);
  end;
end;

procedure TACLTreeListOptionsBehavior.SetSortingMode(AValue: TACLTreeListSortingMode);
begin
  if FSortingMode <> AValue then
  begin
    FSortingMode := AValue;
    TreeList.Changed([tlcnSettingsSorting]);
  end;
end;

{ TACLTreeListOptionsCustomizing }

procedure TACLTreeListOptionsCustomizing.AfterConstruction;
begin
  inherited;
  ColumnWidth := True;
end;

procedure TACLTreeListOptionsCustomizing.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);
  if Source is TACLTreeListOptionsCustomizing then
  begin
    ColumnWidth := TACLTreeListOptionsCustomizing(Source).ColumnWidth;
    ColumnOrder := TACLTreeListOptionsCustomizing(Source).ColumnOrder;
    ColumnVisibility := TACLTreeListOptionsCustomizing(Source).ColumnVisibility;
  end;
end;

{ TACLTreeListOptionsSelection }

procedure TACLTreeListOptionsSelection.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);
  if Source is TACLTreeListOptionsSelection then
  begin
    FocusCell := TACLTreeListOptionsSelection(Source).FocusCell;
    MultiSelect := TACLTreeListOptionsSelection(Source).MultiSelect;
  end;
end;

procedure TACLTreeListOptionsSelection.SetFocusCell(AValue: Boolean);
begin
  if FocusCell <> AValue then
  begin
    FFocusCell := AValue;
    Changed([apcStruct]);
  end;
end;

procedure TACLTreeListOptionsSelection.SetMultiSelect(AValue: Boolean);
begin
  if FMultiSelect <> AValue then
  begin
    FMultiSelect := AValue;
    TreeList.SelectNone;
  end;
end;

{ TACLTreeListOptionsViewColumns }

constructor TACLTreeListOptionsViewColumns.Create(const ATreeList: IACLTreeListOptionsListener);
begin
  inherited Create(ATreeList);
  FHeight := tlAutoHeight;
  FVisible := True;
end;

procedure TACLTreeListOptionsViewColumns.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);
  if Source is TACLTreeListOptionsViewColumns then
  begin
    AutoWidth := TACLTreeListOptionsViewColumns(Source).AutoWidth;
    Height := TACLTreeListOptionsViewColumns(Source).Height;
    Visible := TACLTreeListOptionsViewColumns(Source).Visible;
  end;
end;

procedure TACLTreeListOptionsViewColumns.SetAutoWidth(AValue: Boolean);
begin
  if FAutoWidth <> AValue then
  begin
    FAutoWidth := AValue;
    Changed([apcLayout]);
  end;
end;

procedure TACLTreeListOptionsViewColumns.SetHeight(AValue: Integer);
begin
  AValue := Max(AValue, 5);
  if AValue <> Height then
  begin
    FHeight := AValue;
    Changed([apcLayout]);
  end;
end;

procedure TACLTreeListOptionsViewColumns.SetVisible(AValue: Boolean);
begin
  if AValue <> FVisible then
  begin
    FVisible := AValue;
    Changed([apcStruct]);
  end;
end;

{ TACLTreeListOptionsViewNodes }

constructor TACLTreeListOptionsViewNodes.Create(const ATreeList: IACLTreeListOptionsListener);
begin
  inherited Create(ATreeList);
  FGridLines := [tlglVertical, tlglHorzontal];
  FHeight := tlAutoHeight;
end;

procedure TACLTreeListOptionsViewNodes.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);
  if Source is TACLTreeListOptionsViewNodes then
  begin
    ImageAlignment := TACLTreeListOptionsViewNodes(Source).ImageAlignment;
    GridLines := TACLTreeListOptionsViewNodes(Source).GridLines;
    Height := TACLTreeListOptionsViewNodes(Source).Height;
  end;
end;

procedure TACLTreeListOptionsViewNodes.SetGridLines(AValue: TACLTreeListGridLines);
begin
  if FGridLines <> AValue then
  begin
    FGridLines := AValue;
    Changed([apcLayout]);
  end;
end;

procedure TACLTreeListOptionsViewNodes.SetHeight(AValue: Integer);
begin
  AValue := Max(AValue, 0);
  if Height <> AValue then
  begin
    FHeight := AValue;
    Changed([apcLayout]);
  end;
end;

procedure TACLTreeListOptionsViewNodes.SetImageAlignment(AValue: TAlignment);
begin
  if FImageAlignment <> AValue then
  begin
    FImageAlignment := AValue;
    Changed([apcLayout]);
  end;
end;

{ TACLTreeListOptionsView }

constructor TACLTreeListOptionsView.Create(const ATreeList: IACLTreeListOptionsListener);
begin
  inherited Create(ATreeList);
  FGroupHeight := tlAutoHeight;
  FBorders := acAllBorders;
  FColumns := CreateColumns;
  FNodes := CreateNodes;
end;

destructor TACLTreeListOptionsView.Destroy;
begin
  FreeAndNil(FColumns);
  FreeAndNil(FNodes);
  inherited Destroy;
end;

function TACLTreeListOptionsView.CreateColumns: TACLTreeListOptionsViewColumns;
begin
  Result := TACLTreeListOptionsViewColumns.Create(TreeList);
end;

function TACLTreeListOptionsView.CreateNodes: TACLTreeListOptionsViewNodes;
begin
  Result := TACLTreeListOptionsViewNodes.Create(TreeList);
end;

procedure TACLTreeListOptionsView.DoAssign(Source: TPersistent);
begin
  if Source is TACLTreeListOptionsView then
  begin
    Borders := TACLTreeListOptionsView(Source).Borders;
    Columns := TACLTreeListOptionsView(Source).Columns;
    Nodes := TACLTreeListOptionsView(Source).Nodes;
    GroupHeight := TACLTreeListOptionsView(Source).GroupHeight;
    CheckBoxes := TACLTreeListOptionsView(Source).CheckBoxes;
  end;
end;

procedure TACLTreeListOptionsView.SetBorders(AValue: TACLBorders);
begin
  if AValue <> FBorders then
  begin
    FBorders := AValue;
    Changed([apcLayout]);
  end;
end;

procedure TACLTreeListOptionsView.SetCheckBoxes(AValue: Boolean);
begin
  if FCheckBoxes <> AValue then
  begin
    FCheckBoxes := AValue;
    Changed([apcLayout]);
  end;
end;

procedure TACLTreeListOptionsView.SetColumns(AValue: TACLTreeListOptionsViewColumns);
begin
  FColumns.Assign(AValue);
end;

procedure TACLTreeListOptionsView.SetGroupHeight(const Value: Integer);
begin
  FGroupHeight := Value;
end;

procedure TACLTreeListOptionsView.SetNodes(AValue: TACLTreeListOptionsViewNodes);
begin
  FNodes.Assign(AValue);
end;

end.
