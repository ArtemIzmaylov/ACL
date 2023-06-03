{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             TreeList Control              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.TreeList.SubClass.DragAndDrop;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.ActiveX,
  // System
  System.Generics.Collections,
  System.Types,
  System.Classes,
  // Vcl
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.Geometry,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.DropSource,
  ACL.UI.DropTarget,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

type

  { TACLTreeListDropTarget }

  TACLTreeListDropTargetClass = class of TACLTreeListDropTarget;
  TACLTreeListDropTarget = class(TACLDropTarget)
  strict private
    FAutoExpandTimer: TACLTimer;
    FSubClass: TACLTreeListSubClass;

    procedure AutoExpandTimerHandler(Sender: TObject);
    function GetContentViewInfo: TACLTreeListContentViewInfo;
    function GetDragAndDropController: TACLTreeListDragAndDropController;
    function GetHitTest: TACLTreeListHitTest;
    function GetNodeViewInfo: TACLTreeListNodeViewInfo;
  protected
    function CalculateDropTarget(var AObject: TObject; var AMode: TACLTreeListDropTargetInsertMode): Boolean; virtual;
    function CalculateInsertMode(ANode: TACLTreeListNode): TACLTreeListDropTargetInsertMode;
    function CanChangeNodeLevel: Boolean; virtual;
    function GetTargetClientRect: TRect; override;
    function ScreenToClient(const P: TPoint): TPoint; override;
    // Events
    procedure DoDrop(Shift: TShiftState; const ScreenPoint: TPoint; Action: TACLDropAction); override; final;
    procedure DoDropCore(Action: TACLDropAction); virtual;
    procedure DoEnter; override;
    procedure DoLeave; override;
    procedure DoOver(Shift: TShiftState; const ScreenPoint: TPoint;
      var Hint: UnicodeString; var Allow: Boolean; var Action: TACLDropAction); override;
    procedure DoScroll(ALines: Integer; ADirection: TACLMouseWheelDirection; const P: TPoint); override;
  public
    constructor Create(ASubClass: TACLTreeListSubClass); reintroduce; virtual;
    destructor Destroy; override;
    //
    property AutoExpandTimer: TACLTimer read FAutoExpandTimer;
    property ContentViewInfo: TACLTreeListContentViewInfo read GetContentViewInfo;
    property DragAndDropController: TACLTreeListDragAndDropController read GetDragAndDropController;
    property HitTest: TACLTreeListHitTest read GetHitTest;
    property NodeViewInfo: TACLTreeListNodeViewInfo read GetNodeViewInfo;
    property SubClass: TACLTreeListSubClass read FSubClass;
  end;

  { TACLTreeListCustomDragSortingDropTarget }

  TACLTreeListCustomDragSortingDropTarget = class(TACLTreeListDropTarget)
  protected
    procedure DoDropObjects; overload; virtual; abstract;
    procedure DoDropCore(Action: TACLDropAction); override;
  end;

  { TACLTreeListGroupDragSortingDropTarget }

  TACLTreeListGroupDragSortingDropTarget = class(TACLTreeListCustomDragSortingDropTarget)
  strict private
    FSelection: TACLList<TACLTreeListGroup>;

    procedure PopulateSelection;
  protected
    function CalculateDropTarget(var AObject: TObject; var AMode: TACLTreeListDropTargetInsertMode): Boolean; override;
    procedure DoDropObjects; override;
  public
    constructor Create(ASubClass: TACLTreeListSubClass); override;
    destructor Destroy; override;
    //
    property Selection: TACLList<TACLTreeListGroup> read FSelection;
  end;

  { TACLTreeListNodeDragSortingDropTarget }

  TACLTreeListNodeDragSortingDropTarget = class(TACLTreeListCustomDragSortingDropTarget)
  strict private
    FSelectedGroup: TACLTreeListGroup;
    FSelectedLevel: TACLTreeListNode;
    FSelection: TACLTreeListNodeList;

    procedure PopulateSelection;
  protected
    function CalculateDropTarget(var AObject: TObject; var AMode: TACLTreeListDropTargetInsertMode): Boolean; override;
    function CanChangeNodeLevel: Boolean; override;
    function DoDragSortingDrop(ANode: TACLTreeListNode; AMode: TACLTreeListDropTargetInsertMode): Boolean;
    procedure DoDropObjects; override;
  public
    constructor Create(ASubClass: TACLTreeListSubClass); override;
    destructor Destroy; override;
    //
    property SelectedGroup: TACLTreeListGroup read FSelectedGroup write FSelectedGroup;
    property SelectedLevel: TACLTreeListNode read FSelectedLevel write FSelectedLevel;
    property Selection: TACLTreeListNodeList read FSelection;
  end;

  { TACLTreeListCustomDragSortingObject }

  TACLTreeListCustomDragSortingObject = class(TACLCompoundControlDragObject,
    IACLDropSourceOperation)
  strict private
    function GetHitTest: TACLTreeListHitTest;
    function GetSubClass: TACLTreeListSubClass;
  protected
    function GetDropTargetClass: TACLTreeListDropTargetClass; virtual;
    // IACLDropSourceOperation
    procedure DropSourceBegin;
    procedure DropSourceDrop(var AllowDrop: Boolean);
    procedure DropSourceEnd(AActions: TACLDropSourceActions; AShiftState: TShiftState);
  public
    procedure DragFinished(ACanceled: Boolean); override;
    procedure DragMove(const P: TPoint; var ADeltaX: Integer; var ADeltaY: Integer); override;
    function DragStart: Boolean; override;
    //
    property HitTest: TACLTreeListHitTest read GetHitTest;
    property SubClass: TACLTreeListSubClass read GetSubClass;
  end;

  { TACLTreeListColumnCustomDragObject }

  TACLTreeListColumnCustomDragObject = class(TACLCompoundControlDragObject)
  strict private
    FColumnViewInfo: TACLTreeListColumnViewInfo;

    function GetColumn: TACLTreeListColumn;
    function GetColumnBarViewInfo: TACLTreeListColumnBarViewInfo;
    function GetSubClass: TACLTreeListSubClass;
  public
    constructor Create(AColumnViewInfo: TACLTreeListColumnViewInfo); virtual;
    //
    property Column: TACLTreeListColumn read GetColumn;
    property ColumnBarViewInfo: TACLTreeListColumnBarViewInfo read GetColumnBarViewInfo;
    property ColumnViewInfo: TACLTreeListColumnViewInfo read FColumnViewInfo;
    property SubClass: TACLTreeListSubClass read GetSubClass;
  end;

  { TACLTreeListColumnDragMoveObject }

  TACLTreeListColumnDragMoveObject = class(TACLTreeListColumnCustomDragObject)
  strict private
    FAutoScrollTimer: TACLTimer;

    procedure AutoScrollTimerHandler(Sender: TObject);
    function CalculateAutoScrollingDelta(const P: TPoint): Integer;
    procedure CheckAutoScrolling(ADelta: Integer);
    function GetHitTest: TACLTreeListHitTest;
  public
    procedure DragFinished(ACanceled: Boolean); override;
    procedure DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer); override;
    function DragStart: Boolean; override;
    //
    property HitTest: TACLTreeListHitTest read GetHitTest;
  end;

  { TACLTreeListColumnDragResizeObject }

  TACLTreeListColumnDragResizeObject = class(TACLTreeListColumnCustomDragObject)
  strict private
    procedure DragMoveAutoWidthColumns(const P: TPoint; var ADeltaX, ADeltaY: Integer);
  public
    procedure DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer); override;
    function DragStart: Boolean; override;
  end;

  { TACLTreeListGroupDragObject }

  TACLTreeListGroupDragObject = class(TACLTreeListCustomDragSortingObject)
  strict private
    FGroup: TACLTreeListGroup;
  protected
    procedure CheckSelection; virtual;
    function GetDropTargetClass: TACLTreeListDropTargetClass; override;
    procedure StartDropSource(AActions: TACLDropSourceActions; ASource: IACLDropSourceOperation; ASourceObject: TObject); override;
  public
    constructor Create(AGroup: TACLTreeListGroup); virtual;
    //
    property Group: TACLTreeListGroup read FGroup;
  end;

  { TACLTreeListSelectionRectDragObject }

  TACLTreeListSelectionRectDragObject = class(TACLTreeListCustomDragSortingObject)
  strict private
    FCapturePoint: TPoint;
    FLastHitNode: TACLTreeListNode;
    FSelectionMode: Boolean;
    FStartNode: TACLTreeListNode;
    FStartNodeNearest: TACLTreeListNode;

    function GetContentViewInfo: TACLTreeListContentViewInfo; inline;
    function GetHitNode: TACLTreeListNode;
    function GetSelection: TACLTreeListNodeList;
  protected
    function CanStartSelectionMode: Boolean; virtual;
    function GetAbsoluteHitPoint: TPoint;
    procedure UpdateStartNodeNearest;
  public
    constructor Create(ANode: TACLTreeListNode);
    procedure DragFinished(ACanceled: Boolean); override;
    procedure DragMove(const P: TPoint; var ADeltaX: Integer; var ADeltaY: Integer); override;
    function DragStart: Boolean; override;
    //
    property ContentViewInfo: TACLTreeListContentViewInfo read GetContentViewInfo;
    property Selection: TACLTreeListNodeList read GetSelection;
    property StartNode: TACLTreeListNode read FStartNode;
    property StartNodeNearest: TACLTreeListNode read FStartNodeNearest;
  end;

  { TACLTreeListNodeDragObject }

  TACLTreeListNodeDragObject = class(TACLTreeListSelectionRectDragObject)
  protected
    function CanStartSelectionMode: Boolean; override;
  end;

implementation

uses
  System.Math,
  System.SysUtils;

type
  TACLTreeListNodeAccess = class(TACLTreeListNode);
  TACLTreeListAccess = class(TACLTreeListSubClass);

{ TACLTreeListDropTarget }

constructor TACLTreeListDropTarget.Create(ASubClass: TACLTreeListSubClass);
begin
  inherited Create(nil);
  FSubClass := ASubClass;
  Target := ASubClass.Container.GetControl;
end;

destructor TACLTreeListDropTarget.Destroy;
begin
  FreeAndNil(FAutoExpandTimer);
  inherited;
end;

procedure TACLTreeListDropTarget.DoDrop(Shift: TShiftState; const ScreenPoint: TPoint; Action: TACLDropAction);
begin
  DragAndDropController.IsDropping := True;
  try
    DoDropCore(Action);
  finally
    DragAndDropController.IsDropping := False;
  end;
end;

procedure TACLTreeListDropTarget.DoDropCore(Action: TACLDropAction);
begin
  TACLTreeListAccess(SubClass).DoDrop(Self, Action,
    DragAndDropController.DropTargetObject as TACLTreeListNode,
    DragAndDropController.DropTargetObjectInsertMode);
end;

procedure TACLTreeListDropTarget.DoEnter;
begin
  FAutoExpandTimer := TACLTimer.CreateEx(AutoExpandTimerHandler);
end;

procedure TACLTreeListDropTarget.DoLeave;
begin
  FreeAndNil(FAutoExpandTimer);
  DragAndDropController.UpdateDropInfo(nil, dtimInto);
end;

procedure TACLTreeListDropTarget.DoOver(Shift: TShiftState;
  const ScreenPoint: TPoint; var Hint: UnicodeString; var Allow: Boolean; var Action: TACLDropAction);
var
  AMode: TACLTreeListDropTargetInsertMode;
  AObject: TObject;
begin
  Allow := False;
  if SubClass.OptionsBehavior.DragSorting or not DragAndDropController.IsActive then
  begin
    CheckContentScrolling(ScreenToClient(ScreenPoint));
    AObject := nil;
    AMode := dtimInto;
    SubClass.UpdateHitTest;
    Allow := CalculateDropTarget(AObject, AMode);

    if Allow and not DragAndDropController.IsActive then
      TACLTreeListAccess(SubClass).DoDropOver(Self, Action, AObject, AMode, Allow);
    if DragAndDropController.UpdateDropInfo(AObject, AMode) then
      AutoExpandTimer.Restart;
  end;
end;

procedure TACLTreeListDropTarget.DoScroll(ALines: Integer; ADirection: TACLMouseWheelDirection; const P: TPoint);
begin
  ContentViewInfo.ScrollByLines(ALines, ADirection);
end;

function TACLTreeListDropTarget.CalculateDropTarget(
  var AObject: TObject; var AMode: TACLTreeListDropTargetInsertMode): Boolean;
begin
  Result := HitTest.HitAtNode;
  if Result then
  begin
    AObject := HitTest.HitObject;
    AMode := CalculateInsertMode(HitTest.Node);
  end
  else

  if HitTest.HitAtContentArea then
  begin
    AMode := dtimAfter;
    AObject := nil;
    Result := True;
  end;
end;

function TACLTreeListDropTarget.CalculateInsertMode(ANode: TACLTreeListNode): TACLTreeListDropTargetInsertMode;
var
  ACell: TACLCompoundControlBaseContentCell;
begin
  Result := dtimAfter;
  if ContentViewInfo.ViewItems.Find(ANode, ACell) then
  begin
    if CanChangeNodeLevel then
    begin
      NodeViewInfo.Initialize(ANode);
      if HitTest.HitPoint.X > ACell.Bounds.Left + NodeViewInfo.CellTextExtends[nil].Left then
        Exit(dtimInto);
    end;

    if HitTest.HitPoint.Y > acRectCenterVertically(ACell.Bounds, 0).Top then
      Result := dtimAfter
    else
      Result := dtimBefore;
  end;
end;

function TACLTreeListDropTarget.CanChangeNodeLevel: Boolean;
begin
  Result := SubClass.OptionsBehavior.DropTargetAllowCreateLevel;
end;

function TACLTreeListDropTarget.GetTargetClientRect: TRect;
begin
  Result := acRectOffset(ContentViewInfo.ClientBounds, 0, 0);
end;

function TACLTreeListDropTarget.ScreenToClient(const P: TPoint): TPoint;
begin
  Result := SubClass.ScreenToClient(P);
end;

procedure TACLTreeListDropTarget.AutoExpandTimerHandler(Sender: TObject);
var
  AExpandable: IACLExpandableObject;
begin
  AutoExpandTimer.Enabled := False;
  if Supports(DragAndDropController.DropTargetObject, IACLExpandableObject, AExpandable) then
    AExpandable.Expanded := True;
end;

function TACLTreeListDropTarget.GetContentViewInfo: TACLTreeListContentViewInfo;
begin
  Result := SubClass.ViewInfo.Content;
end;

function TACLTreeListDropTarget.GetDragAndDropController: TACLTreeListDragAndDropController;
begin
  Result := SubClass.DragAndDropController;
end;

function TACLTreeListDropTarget.GetHitTest: TACLTreeListHitTest;
begin
  Result := SubClass.HitTest;
end;

function TACLTreeListDropTarget.GetNodeViewInfo: TACLTreeListNodeViewInfo;
begin
  Result := ContentViewInfo.NodeViewInfo;
end;

{ TACLTreeListCustomDragSortingDropTarget }

procedure TACLTreeListCustomDragSortingDropTarget.DoDropCore(Action: TACLDropAction);
begin
  SubClass.BeginLongOperation;
  SubClass.BeginUpdate;
  try
    DoDropObjects;
    TACLTreeListAccess(SubClass).DoDragSorting;
  finally
    SubClass.EndUpdate;
    SubClass.EndLongOperation;
  end;
end;

{ TACLTreeListGroupDragSortingDropTarget }

constructor TACLTreeListGroupDragSortingDropTarget.Create(ASubClass: TACLTreeListSubClass);
begin
  inherited Create(ASubClass);
  FSelection := TACLList<TACLTreeListGroup>.Create;
  PopulateSelection;
end;

destructor TACLTreeListGroupDragSortingDropTarget.Destroy;
begin
  FreeAndNil(FSelection);
  inherited Destroy;
end;

function TACLTreeListGroupDragSortingDropTarget.CalculateDropTarget(
  var AObject: TObject; var AMode: TACLTreeListDropTargetInsertMode): Boolean;
var
  ACell: TACLCompoundControlBaseContentCell;
  AGroup: TACLTreeListGroup;
begin
  Result := False;

  AGroup := nil;
  if HitTest.HitAtNode then
    AGroup := HitTest.Node.TopLevel.Group;
  if HitTest.HitAtGroup then
    AGroup := HitTest.Group;

  if (AGroup <> nil) and (Selection.IndexOf(AGroup) < 0) and ContentViewInfo.ViewItems.Find(AGroup, ACell) then
  begin
    AObject := AGroup;
    AMode := dtimBefore;

    if HitTest.HitPoint.Y > ACell.Bounds.Bottom then
    begin
      if AGroup.Expanded then
      begin
        AObject := AGroup.NextSibling;
        if AObject = nil then
        begin
          AObject := AGroup.Links.Last;
          AMode := dtimAfter;
        end;
      end
      else
        AMode := dtimAfter;
    end;

    if AObject is TACLTreeListGroup then
    begin
      Result := Selection.IndexOf(TACLTreeListGroup(AObject)) < 0;
      if AMode = dtimBefore then
        Result := Result and (Selection.IndexOf(TACLTreeListGroup(AObject).PrevSibling) < 0)
      else
        Result := Result and (Selection.IndexOf(TACLTreeListGroup(AObject).NextSibling) < 0);
    end
    else
      Result := True;
  end;
end;

procedure TACLTreeListGroupDragSortingDropTarget.DoDropObjects;
var
  AGroup: TACLTreeListGroup;
begin
  if Selection.Count = 0 then
    Exit;

  if DragAndDropController.DropTargetObject is TACLTreeListGroup then
    AGroup := TACLTreeListGroup(DragAndDropController.DropTargetObject)
  else if DragAndDropController.DropTargetObject is TACLTreeListNode then
    AGroup := TACLTreeListNode(DragAndDropController.DropTargetObject).Group
  else
    AGroup := nil;

  if AGroup <> nil then
  begin
    TACLTreeListAccess(SubClass).Groups.Move(AGroup.Index +
      Ord(DragAndDropController.DropTargetObjectInsertMode = dtimAfter), Selection);
  end;
end;

procedure TACLTreeListGroupDragSortingDropTarget.PopulateSelection;
var
  I: Integer;
begin
  if HitTest.HitAtGroup then
  begin
    if not HitTest.Group.Selected then
      Selection.Add(HitTest.Group)
    else
      for I := 0 to SubClass.GroupCount - 1 do
      begin
        if SubClass.Group[I].Selected then
          Selection.Add(SubClass.Group[I]);
      end;
  end;
end;

{ TACLTreeListNodeDragSortingDropTarget }

constructor TACLTreeListNodeDragSortingDropTarget.Create(ASubClass: TACLTreeListSubClass);
begin
  inherited Create(ASubClass);
  FSelection := TACLTreeListNodeList.Create;
  PopulateSelection;
end;

destructor TACLTreeListNodeDragSortingDropTarget.Destroy;
begin
  FreeAndNil(FSelection);
  inherited Destroy;
end;

function TACLTreeListNodeDragSortingDropTarget.CalculateDropTarget(
  var AObject: TObject; var AMode: TACLTreeListDropTargetInsertMode): Boolean;
var
  ANode: TACLTreeListNode;
begin
  Result := False;

  // Node
  if HitTest.HitAtNode then
  begin
    ANode := HitTest.Node;
    Result := (ANode.TopLevel.Group = SelectedGroup) and (Selection.IndexOf(ANode) < 0) and not Selection.IsChild(ANode);
    if not CanChangeNodeLevel then
      Result := Result and (ANode.Parent = SelectedLevel);
    if Result then
    begin
      AObject := ANode;
      AMode := CalculateInsertMode(ANode);
    end;
  end
  else

  // Group
  if HitTest.HitAtGroup then
  begin
    Result := HitTest.HitObject = SelectedGroup;
    if Result then
    begin
      AObject := SelectedGroup.Links.First;
      AMode := dtimBefore;
    end;
  end;

  if Result then
  begin
    Result := Selection.IndexOf(AObject) < 0;
    case AMode of
      dtimBefore:
        Result := Result and (Selection.IndexOf(TACLTreeListNode(AObject).PrevSibling) < 0);
      dtimAfter:
        Result := Result and (Selection.IndexOf(TACLTreeListNode(AObject).NextSibling) < 0);
    end;
  end;

  Result := Result and TACLTreeListAccess(SubClass).DoDragSortingOver(AObject as TACLTreeListNode, AMode);
end;

function TACLTreeListNodeDragSortingDropTarget.CanChangeNodeLevel: Boolean;
begin
  Result := SubClass.OptionsBehavior.DragSortingAllowChangeLevel;
end;

function TACLTreeListNodeDragSortingDropTarget.DoDragSortingDrop(
  ANode: TACLTreeListNode; AMode: TACLTreeListDropTargetInsertMode): Boolean;
begin
  Result := TACLTreeListAccess(SubClass).DoDragSortingDrop(ANode, AMode);
end;

procedure TACLTreeListNodeDragSortingDropTarget.DoDropObjects;
var
  AInsertIndex: Integer;
  AList: TACLTreeListNodeList;
  AParentNode: TACLTreeListNode;
  I: Integer;
begin
  if DragAndDropController.DropTargetObject is TACLTreeListNode then
  begin
    AParentNode := TACLTreeListNode(DragAndDropController.DropTargetObject);

    if not DoDragSortingDrop(AParentNode, DragAndDropController.DropTargetObjectInsertMode) then
    begin
      AInsertIndex := AParentNode.ChildrenCount;
      case DragAndDropController.DropTargetObjectInsertMode of
        dtimBefore:
          begin
            AInsertIndex := AParentNode.Index;
            AParentNode := AParentNode.Parent;
          end;

        dtimAfter:
          begin
            AInsertIndex := AParentNode.Index + 1;
            AParentNode := AParentNode.Parent;
          end;
      end;

      for I := 0 to Selection.Count - 1 do
        Selection[I].Parent := AParentNode;

      AList := TACLTreeListNodeAccess(AParentNode).FSubNodes;
      for I := 0 to AList.Count - 1 do
      begin
        if AList[I].Selected then
          AList.List[I] := nil;
      end;
      for I := 0 to Selection.Count - 1 do
        AList.Insert(AInsertIndex + I, Selection[I]);
      AList.Pack;

      AParentNode.Expanded := True;
    end;
    SubClass.Changed([tlcnNodeIndex]);
  end;
end;

procedure TACLTreeListNodeDragSortingDropTarget.PopulateSelection;

  function ValidateSelection: Boolean;
  var
    ANode: TACLTreeListNode;
    I: Integer;
  begin
    Result := True;
    for I := 0 to Selection.Count - 1 do
    begin
      ANode := Selection[I];
      if ANode.TopLevel.Group <> SelectedGroup then
        Exit(False);
      if not CanChangeNodeLevel and (ANode.Parent <> SelectedLevel) then
        Exit(False);
    end;
  end;

begin
  if SubClass.SelectedCount > 0 then
  begin
    SelectedLevel := SubClass.Selected[0].Parent;
    SelectedGroup := SubClass.Selected[0].TopLevel.Group;
    Selection.Assign(TACLTreeListAccess(SubClass).Selection);
    if not ValidateSelection then
    begin
      SelectedGroup := nil;
      SelectedLevel := nil;
      Selection.Clear;
    end;
  end;
end;

{ TACLTreeListCustomDragSortingObject }

procedure TACLTreeListCustomDragSortingObject.DragFinished(ACanceled: Boolean);
begin
  // do nothing
end;

procedure TACLTreeListCustomDragSortingObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);
begin
  // do nothing
end;

function TACLTreeListCustomDragSortingObject.DragStart: Boolean;
begin
  Result := SubClass.OptionsBehavior.DropSource or SubClass.OptionsBehavior.DragSorting;
  if Result then
    StartDropSource([dsaCopy], Self, nil);
end;

function TACLTreeListCustomDragSortingObject.GetDropTargetClass: TACLTreeListDropTargetClass;
begin
  Result := TACLTreeListNodeDragSortingDropTarget;
end;

procedure TACLTreeListCustomDragSortingObject.DropSourceBegin;
begin
  if SubClass.OptionsBehavior.DragSorting then
    UpdateDropTarget(GetDropTargetClass.Create(SubClass));
end;

procedure TACLTreeListCustomDragSortingObject.DropSourceDrop(var AllowDrop: Boolean);
begin
  // do nothing
end;

procedure TACLTreeListCustomDragSortingObject.DropSourceEnd(AActions: TACLDropSourceActions; AShiftState: TShiftState);
begin
  UpdateDropTarget(nil);
end;

function TACLTreeListCustomDragSortingObject.GetSubClass: TACLTreeListSubClass;
begin
  Result := inherited SubClass as TACLTreeListSubClass;
end;

function TACLTreeListCustomDragSortingObject.GetHitTest: TACLTreeListHitTest;
begin
  Result := SubClass.HitTest;
end;

{ TACLTreeListColumnCustomDragObject }

constructor TACLTreeListColumnCustomDragObject.Create(AColumnViewInfo: TACLTreeListColumnViewInfo);
begin
  inherited Create;
  FColumnViewInfo := AColumnViewInfo;
end;

function TACLTreeListColumnCustomDragObject.GetColumn: TACLTreeListColumn;
begin
  Result := ColumnViewInfo.Column;
end;

function TACLTreeListColumnCustomDragObject.GetColumnBarViewInfo: TACLTreeListColumnBarViewInfo;
begin
  Result := SubClass.ViewInfo.Content.ColumnBarViewInfo;
end;

function TACLTreeListColumnCustomDragObject.GetSubClass: TACLTreeListSubClass;
begin
  Result := ColumnViewInfo.SubClass;
end;

{ TACLTreeListColumnDragMoveObject }

procedure TACLTreeListColumnDragMoveObject.DragFinished(ACanceled: Boolean);
begin
  if not ACanceled then
  begin
    if HitTest.HitAtColumn then
      ColumnViewInfo.Column.DrawIndex := HitTest.Column.DrawIndex
    else
      if SubClass.OptionsCustomizing.ColumnVisibility then
        ColumnViewInfo.Column.Visible := False;
  end;
  FreeAndNil(FAutoScrollTimer);
end;

procedure TACLTreeListColumnDragMoveObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);
var
  AColumnViewInfo: TACLTreeListColumnViewInfo;
  ADropTargetBounds: TRect;
begin
  DragWindow.SetVisible(True);
  DragWindow.SetBounds(DragWindow.Left + ADeltaX, DragWindow.Top + ADeltaY, DragWindow.Width, DragWindow.Height);

  CheckAutoScrolling(CalculateAutoScrollingDelta(P));
  if HitTest.HitAtColumn then
  begin
    AColumnViewInfo := HitTest.ColumnViewInfo;
    if AColumnViewInfo.Column.DrawIndex > ColumnViewInfo.Column.DrawIndex then
      ADropTargetBounds := acRectSetRight(AColumnViewInfo.Bounds, AColumnViewInfo.Bounds.Right, 1)
    else
      ADropTargetBounds := acRectSetLeft(AColumnViewInfo.Bounds, AColumnViewInfo.Bounds.Left, 1);

    UpdateDragTargetZoneWindow(SubClass.ClientToScreen(ADropTargetBounds), True);
    Cursor := crDefault;
  end
  else
  begin
    UpdateDragTargetZoneWindow(NullRect, True);
    if SubClass.OptionsCustomizing.ColumnVisibility then
      Cursor := crRemove;
  end;
end;

function TACLTreeListColumnDragMoveObject.DragStart: Boolean;
begin
  Result := SubClass.OptionsCustomizing.ColumnOrder;
  if Result then
    InitializeDragWindow(ColumnViewInfo);
end;

procedure TACLTreeListColumnDragMoveObject.AutoScrollTimerHandler(Sender: TObject);
begin
  SubClass.ScrollBy(10 * FAutoScrollTimer.Tag, 0);
end;

function TACLTreeListColumnDragMoveObject.CalculateAutoScrollingDelta(const P: TPoint): Integer;
var
  R: TRect;
begin
  Result := 0;
  if IntersectRect(R, ColumnBarViewInfo.Bounds, SubClass.Bounds) then
  begin
    if P.X > R.Right - 50 then
      Result := 1;
    if P.X < R.Left + 50 then
      Result := -1;
  end;
end;

procedure TACLTreeListColumnDragMoveObject.CheckAutoScrolling(ADelta: Integer);
begin
  if FAutoScrollTimer = nil then
    FAutoScrollTimer := TACLTimer.CreateEx(AutoScrollTimerHandler, 1);
  FAutoScrollTimer.Tag := ADelta;
  FAutoScrollTimer.Enabled := ADelta <> 0;
end;

function TACLTreeListColumnDragMoveObject.GetHitTest: TACLTreeListHitTest;
begin
  Result := SubClass.HitTest;
end;

{ TACLTreeListColumnDragResizeObject }

procedure TACLTreeListColumnDragResizeObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);
var
  APrevWidth: Integer;
begin
  SubClass.ViewInfo.Content.LockViewItemsPlacement;
  try
    if SubClass.OptionsView.Columns.AutoWidth then
      DragMoveAutoWidthColumns(P, ADeltaX, ADeltaY)
    else
    begin
      APrevWidth := dpiApply(Column.Width, CurrentDpi);
      Column.Width := dpiRevert(APrevWidth + ADeltaX, CurrentDpi);
      ADeltaX := dpiApply(Column.Width, CurrentDpi) - APrevWidth;
    end;
  finally
    SubClass.ViewInfo.Content.UnlockViewItemsPlacement;
  end;
end;

function TACLTreeListColumnDragResizeObject.DragStart: Boolean;
begin
  Result := Column.CanResize;
end;

procedure TACLTreeListColumnDragResizeObject.DragMoveAutoWidthColumns(const P: TPoint; var ADeltaX, ADeltaY: Integer);
var
  AColumnViewInfo: TACLTreeListColumnViewInfo;
  ANextSibling: TACLTreeListColumn;
  APrevWidth: Integer;
begin
  SubClass.BeginUpdate;
  try
    for var I := 0 to ColumnBarViewInfo.ChildCount - 1 do
    begin
      AColumnViewInfo := ColumnBarViewInfo.Children[I];
      AColumnViewInfo.Column.Width := dpiRevert(AColumnViewInfo.ActualWidth, CurrentDpi);
    end;
    ANextSibling := Column.NextSibling;
    if ANextSibling <> nil then
    begin
      if ADeltaX > 0 then
      begin
        APrevWidth := dpiApply(ANextSibling.Width, CurrentDpi);
        ANextSibling.Width := dpiRevert(APrevWidth - ADeltaX, CurrentDpi);
        ADeltaX := APrevWidth - dpiApply(ANextSibling.Width, CurrentDpi);
        Column.Width := dpiRevert(dpiApply(Column.Width, CurrentDpi) + ADeltaX, CurrentDpi);
      end
      else
      begin
        APrevWidth := dpiApply(Column.Width, CurrentDpi);
        Column.Width := dpiRevert(APrevWidth + ADeltaX, CurrentDpi);
        ADeltaX := dpiApply(Column.Width, CurrentDpi) - APrevWidth;
        ANextSibling.Width := dpiRevert(dpiApply(ANextSibling.Width, CurrentDpi) - ADeltaX, CurrentDpi);
      end;
    end;
  finally
    SubClass.EndUpdate;
  end;
end;

{ TACLTreeListGroupDragObject }

constructor TACLTreeListGroupDragObject.Create(AGroup: TACLTreeListGroup);
begin
  inherited Create;
  FGroup := AGroup;
end;

procedure TACLTreeListGroupDragObject.CheckSelection;
begin
  if not Group.Selected then
  begin
    SubClass.BeginUpdate;
    try
      SubClass.SelectNone;
      Group.Selected := True;
    finally
      SubClass.EndUpdate;
    end;
  end;
end;

function TACLTreeListGroupDragObject.GetDropTargetClass: TACLTreeListDropTargetClass;
begin
  Result := TACLTreeListGroupDragSortingDropTarget;
end;

procedure TACLTreeListGroupDragObject.StartDropSource(
  AActions: TACLDropSourceActions; ASource: IACLDropSourceOperation; ASourceObject: TObject);
begin
  CheckSelection;
  inherited StartDropSource(AActions, ASource, ASourceObject);
end;

{ TACLTreeListSelectionRectDragObject }

constructor TACLTreeListSelectionRectDragObject.Create(ANode: TACLTreeListNode);
begin
  inherited Create;
  FStartNode := ANode;
end;

procedure TACLTreeListSelectionRectDragObject.DragFinished(ACanceled: Boolean);
begin
  inherited DragFinished(ACanceled);
  ContentViewInfo.SelectionRect := NullRect;
end;

procedure TACLTreeListSelectionRectDragObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);

  procedure UpdateSelectionRect(const P1, P2: TPoint);
  begin
    ContentViewInfo.SelectionRect := Rect(Min(P1.X, P2.X), Min(P1.Y, P2.Y), Max(P1.X, P2.X), Max(P1.Y, P2.Y));
  end;

var
  AHitNode: TACLTreeListNode;
begin
  if FSelectionMode then
  begin
    UpdateAutoScrollDirection(HitTest.HitPoint, ContentViewInfo.ViewItemsArea);
    UpdateSelectionRect(FCapturePoint, GetAbsoluteHitPoint);
    UpdateStartNodeNearest;

    AHitNode := GetHitNode;
    if FLastHitNode <> AHitNode then
    begin
      FLastHitNode := AHitNode;
      if (AHitNode <> nil) and (StartNode <> nil) then
        SubClass.SelectRange(StartNode, AHitNode, False, True, smSelect)
      else if (AHitNode <> nil) and (StartNodeNearest <> nil) then
        SubClass.SelectRange(StartNodeNearest, AHitNode, False, True, smSelect)
      else
        SubClass.SelectNone;
    end;
  end;
end;

function TACLTreeListSelectionRectDragObject.DragStart: Boolean;
begin
  Result := CanStartSelectionMode;
  if Result then
  begin
    FCapturePoint := GetAbsoluteHitPoint;
    FLastHitNode := StartNode;
    CreateAutoScrollTimer;
    FSelectionMode := True;
  end
  else
    Result := SubClass.HasSelection and inherited DragStart;
end;

function TACLTreeListSelectionRectDragObject.CanStartSelectionMode: Boolean;
begin
  Result := SubClass.OptionsSelection.MultiSelect;
end;

function TACLTreeListSelectionRectDragObject.GetAbsoluteHitPoint: TPoint;
begin
  Result := acPointOffsetNegative(HitTest.HitPoint, ContentViewInfo.ViewItemsOrigin);
end;

procedure TACLTreeListSelectionRectDragObject.UpdateStartNodeNearest;
begin
  FStartNodeNearest := ContentViewInfo.FindNearestNode(FCapturePoint, GetAbsoluteHitPoint.Y - FCapturePoint.Y);
end;

function TACLTreeListSelectionRectDragObject.GetContentViewInfo: TACLTreeListContentViewInfo;
begin
  Result := SubClass.ViewInfo.Content;
end;

function TACLTreeListSelectionRectDragObject.GetHitNode: TACLTreeListNode;
var
  ADirection: Integer;
  APrevHitPoint: TPoint;
begin
  if HitTest.HitAtNode then
    Exit(HitTest.Node);

  APrevHitPoint := HitTest.HitPoint;
  try
    HitTest.HitPoint := Point(FCapturePoint.X, APrevHitPoint.Y);
    if ContentViewInfo.CalculateHitTest(HitTest) and HitTest.HitAtNode then
      Exit(HitTest.Node);
  finally
    HitTest.HitPoint := APrevHitPoint;
  end;

  ADirection := FCapturePoint.Y - GetAbsoluteHitPoint.Y;
  Result := ContentViewInfo.FindNearestNode(GetAbsoluteHitPoint, ADirection);
  if Result <> StartNode then
    Result := ContentViewInfo.FindNearestNode(GetAbsoluteHitPoint, ADirection);


//  if (StartNodeNearest <> nil) and (Result <> nil) and
//    (StartNodeNearest <> Result) and (Sign(ADirection) = Sign(Result.Index - StartNodeNearest.Index))
//  then
//    Result := nil;
end;

function TACLTreeListSelectionRectDragObject.GetSelection: TACLTreeListNodeList;
begin
  Result := TACLTreeListAccess(SubClass).Selection;
end;

{ TACLTreeListNodeDragObject }

function TACLTreeListNodeDragObject.CanStartSelectionMode: Boolean;
var
  AViewInfo: TACLTreeListColumnViewInfo;
begin
  Result := False;
  if inherited CanStartSelectionMode and HitTest.HitAtNode then
  begin
    AViewInfo := HitTest.ColumnViewInfo;
    if AViewInfo <> nil then
      Result := HitTest.HitPoint.X > AViewInfo.Bounds.Left + MulDiv(AViewInfo.Bounds.Width, 3, 4)
    else
      Result := SubClass.Columns.Count > 0;
  end;
end;

end.
