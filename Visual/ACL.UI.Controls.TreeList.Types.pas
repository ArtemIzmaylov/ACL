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

unit ACL.UI.Controls.TreeList.Types;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // Vcl
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.ImgList,
  Vcl.StdCtrls,
  // System
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.ObjectLinks,
  ACL.UI.Resources,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.CompoundControl.SubClass;

const
  tlAutoHeight = 0;
  tlColumnMinWidth = 2;

  // Changes Notifications
  tlcnCheckState = cccnLast + 1;
  tlcnData = tlcnCheckState + 1;
  tlcnSorting = tlcnData + 1;
  tlcnGrouping = tlcnSorting + 1;
  tlcnSelection = tlcnGrouping + 1;
  tlcnFocusedNode = tlcnSelection + 1;
  tlcnFocusedColumn = tlcnFocusedNode + 1;
  tlcnMakeVisible = tlcnFocusedColumn + 1;
  tlcnGroupIndex = tlcnMakeVisible + 1;
  tlcnNodeIndex = tlcnGroupIndex + 1;
  tlcnSettingsIncSearch = tlcnNodeIndex + 1;
  tlcnSettingsDropTarget = tlcnSettingsIncSearch + 1;
  tlcnSettingsFocus = tlcnSettingsDropTarget + 1;
  tlcnSettingsSorting = tlcnSettingsFocus + 1;
  tlcnLast = tlcnSettingsSorting;

type
  TACLTreeListColumn = class;
  TACLTreeListColumnList = class;
  TACLTreeListColumns = class;
  TACLTreeListGroup = class;
  TACLTreeListGroups = class;
  TACLTreeListNode = class;
  TACLTreeListNodeList = class;

  TACLTreeListCompareMode = (tlcmUndefined, tlcmString, tlcmInteger, tlcmSmart);
  TACLTreeListGridLine = (tlglVertical, tlglHorzontal);
  TACLTreeListGridLines = set of TACLTreeListGridLine;
  TACLTreeListSortingMode = (tlsmDisabled, tlsmSingle, tlsmMulti);

  EACLTreeListException = class(Exception);

  { IACLTreeList }

  IACLTreeList = interface
  ['{DB422536-BE6F-4F23-A26A-5A832AEB3881}']
    procedure BeginLongOperation;
    procedure EndLongOperation;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure Changed(AChanges: TIntegerSet);
    //
    function ColumnsCanCustomizeOrder: Boolean;
    function ColumnsCanCustomizeVisibility: Boolean;
    //
    function CalculateBestFit(AColumn: TACLTreeListColumn): Integer;
    function CreateNode: TACLTreeListNode;
    function GetAbsoluteVisibleNodes: TACLTreeListNodeList;
    function GetAutoCheckParents: Boolean;
    function GetAutoCheckChildren: Boolean;
    function GetGroupByList: TACLTreeListColumnList;
    function GetObject: TPersistent;
    function GetRootNode: TACLTreeListNode;
    function GetSortByList: TACLTreeListColumnList;
    function QueryChildInterface(AChild: TObject; const IID: TGUID; var Obj): HRESULT;
    //
    procedure GroupRemoving(AGroup: TACLTreeListGroup);
    procedure NodeChecked(ANode: TACLTreeListNode);
    procedure NodePopulateChildren(ANode: TACLTreeListNode);
    procedure NodeRemoving(ANode: TACLTreeListNode);
    procedure NodeSetSelected(ANode: TACLTreeListNode; var AValue: Boolean);
    procedure NodeValuesChanged(AColumnIndex: Integer = -1);
    //
    property AbsoluteVisibleNodes: TACLTreeListNodeList read GetAbsoluteVisibleNodes;
    property AutoCheckParents: Boolean read GetAutoCheckParents;
    property AutoCheckChildren: Boolean read GetAutoCheckChildren;
    property RootNode: TACLTreeListNode read GetRootNode;
  end;

  { IACLTreeNodeLink }

  IACLTreeNodeLink = interface
  ['{3835D639-CD13-4B14-981B-28C485350BBF}']
    function GetChild: TObject;
    function GetParent: TObject;
  end;

  { TACLTreeListColumn }

  TACLTreeListColumnClass = class of TACLTreeListColumn;
  TACLTreeListColumn = class(TACLCollectionItem)
  strict private const
    DefaultCanResize = True;
    DefaultWidth = 100;
  strict private
    FAutoBestFit: Boolean;
    FCanResize: Boolean;
    FCaption: UnicodeString;
    FCompareMode: TACLTreeListCompareMode;
    FImageIndex: TImageIndex;
    FTag: NativeInt;
    FTextAlign: TAlignment;
    FTextVisible: Boolean;
    FVisible: Boolean;
    FWidth: Integer;

    function GetColumns: TACLTreeListColumns;
    function GetDrawIndex: Integer;
    function GetGroupByIndex: Integer;
    function GetNextSibling: TACLTreeListColumn;
    function GetPrevSibling: TACLTreeListColumn;
    function GetSortByIndex: Integer;
    function IsCanResizeStored: Boolean;
    function IsDrawIndexStored: Boolean;
    function IsWidthStored: Boolean;
    procedure SetAutoBestFit(AValue: Boolean);
    procedure SetCanResize(AValue: Boolean);
    procedure SetCaption(const AValue: UnicodeString);
    procedure SetCompareMode(AValue: TACLTreeListCompareMode);
    procedure SetDrawIndex(AValue: Integer);
    procedure SetImageIndex(AValue: TImageIndex);
    procedure SetTextAlign(AAlign: TAlignment);
    procedure SetTextVisible(AValue: Boolean);
    procedure SetVisible(AValue: Boolean);
    procedure SetWidth(AValue: Integer);
    procedure SetWidthCore(AValue: Integer);
  protected
    FSortDirection: TACLSortDirection;

    procedure Changed(AChanges: TIntegerSet); reintroduce;
    procedure InitializeFields; virtual;
    procedure Localize(const ASection: UnicodeString); virtual;
    procedure VisibleChanged; virtual;
  public
    constructor Create(Collection: TCollection); override;
    procedure ApplyBestFit;
    procedure Assign(Source: TPersistent); override;
    //
    property Columns: TACLTreeListColumns read GetColumns;
    property GroupByIndex: Integer read GetGroupByIndex;
    property NextSibling: TACLTreeListColumn read GetNextSibling;
    property PrevSibling: TACLTreeListColumn read GetPrevSibling;
    property SortByIndex: Integer read GetSortByIndex;
    property SortDirection: TACLSortDirection read FSortDirection;
  published
    property AutoBestFit: Boolean read FAutoBestFit write SetAutoBestFit default False;
    property CanResize: Boolean read FCanResize write SetCanResize stored IsCanResizeStored;
    property Caption: UnicodeString read FCaption write SetCaption;
    property CompareMode: TACLTreeListCompareMode read FCompareMode write SetCompareMode default tlcmSmart;
    property DrawIndex: Integer read GetDrawIndex write SetDrawIndex stored IsDrawIndexStored;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property Index stored False;
    property Tag: NativeInt read FTag write FTag default 0;
    property TextAlign: TAlignment read FTextAlign write SetTextAlign default taLeftJustify;
    property TextVisible: Boolean read FTextVisible write SetTextVisible default True;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Width: Integer read FWidth write SetWidth stored IsWidthStored;
  end;

  { TACLTreeListColumns }

  TACLTreeListColumns = class(TCollection)
  strict private
    FTreeList: IACLTreeList;

    function GetDrawingItem(Index: Integer): TACLTreeListColumn;
    function GetGroupByList: TACLTreeListColumnList;
    function GetItem(Index: Integer): TACLTreeListColumn;
    function GetSortByList: TACLTreeListColumnList;
    function GetVisibleCount: Integer;
    procedure SetItem(Index: Integer; Value: TACLTreeListColumn);
  protected
    FDrawingItems: TACLTreeListColumnList;

    function GetColumnClass: TACLTreeListColumnClass; virtual;
    function GetOwner: TPersistent; override;
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
    procedure Update(Item: TCollectionItem); override;

    // Properties
    property GroupByList: TACLTreeListColumnList read GetGroupByList;
    property SortByList: TACLTreeListColumnList read GetSortByList;
    property TreeList: IACLTreeList read FTreeList;
  public
    constructor Create(AOwner: IACLTreeList); virtual;
    destructor Destroy; override;
    function Add(const AText: UnicodeString = ''): TACLTreeListColumn;
    procedure ApplyBestFit(AAuto: Boolean = False);
    function FindByCaption(const ACaption: UnicodeString): TACLTreeListColumn;
    function IsValid(AColumn: TACLTreeListColumn): Boolean; overload; inline;
    function IsValid(AIndex: Integer): Boolean; overload; inline;
    procedure Localize(const ASection: UnicodeString);

    function First: TACLTreeListColumn; inline;
    function Last: TACLTreeListColumn; inline;

    // Lock/Unlock
    procedure BeginUpdate; override;
    procedure EndUpdate; override;

    // Customized Settings
    procedure ConfigLoad(AConfig: TACLIniFile; const ASection, AItem: UnicodeString); overload;
    procedure ConfigLoad(AStream: TStream); overload;
    procedure ConfigSave(AConfig: TACLIniFile; const ASection, AItem: UnicodeString); overload;
    procedure ConfigSave(AStream: TStream); overload;

    // Properties
    property Items[Index: Integer]: TACLTreeListColumn read GetItem write SetItem; default;
    property ItemsByDrawingIndex[Index: Integer]: TACLTreeListColumn read GetDrawingItem;
    property VisibleCount: Integer read GetVisibleCount;
  end;

  { TACLTreeListColumnList }

  TACLTreeListColumnList = class(TACLObjectList<TACLTreeListColumn>)
  public
    function IsValidIndex(Index: Integer): Boolean; inline;
  end;

  { TACLTreeListGroup }

  TACLTreeListGroup = class(TACLUnknownPersistent,
    IACLObjectLinksSupport,
    IACLCheckableObject,
    IACLExpandableObject,
    IACLSelectableObject,
    IACLTreeNodeLink)
  strict private
    FCaption: UnicodeString;
    FLinks: TACLTreeListNodeList;
    FOwner: TACLTreeListGroups;

    function GetCheckBoxState: TCheckBoxState;
    function GetIndex: Integer;
    function GetNextSibling: TACLTreeListGroup;
    function GetPrevSibling: TACLTreeListGroup;
    function GetSelected: Boolean;
    function GetTreeList: IACLTreeList; inline;
    procedure SetCheckBoxState(AValue: TCheckBoxState);
    procedure SetSelected(AValue: Boolean);
  protected
    FExpanded: Boolean;
    FSortData: Integer;

    // IACLCheckableObject
    function CanCheck: Boolean;
    function GetChecked: Boolean;
    procedure SetChecked(AValue: Boolean);

    // IACLExpandableObject
    function CanToggle: Boolean;
    function GetExpanded: Boolean;
    procedure SetExpanded(AValue: Boolean);

    // IACLTreeNodeLink
    function GetChild: TObject;
    function GetParent: TObject;

    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; override;

    property Owner: TACLTreeListGroups read FOwner;
    property TreeList: IACLTreeList read GetTreeList;
  public
    constructor Create(const ACaption: UnicodeString; AOwner: TACLTreeListGroups); virtual;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    //
    property Links: TACLTreeListNodeList read FLinks;
    //
    property NextSibling: TACLTreeListGroup read GetNextSibling;
    property PrevSibling: TACLTreeListGroup read GetPrevSibling;
  published
    property Caption: UnicodeString read FCaption;
    property CheckBoxState: TCheckBoxState read GetCheckBoxState write SetCheckBoxState;
    property Expanded: Boolean read GetExpanded write SetExpanded;
    property Index: Integer read GetIndex;
    property Selected: Boolean read GetSelected write SetSelected;
  end;

  { TACLTreeListGroupSortDataComparer }

  TACLTreeListGroupSortDataComparer = class(TComparer<TACLTreeListGroup>)
  public
    function Compare(const Left, Right: TACLTreeListGroup): Integer; override;
  end;

  { TACLTreeListGroups }

  TACLTreeListGroups = class(TACLObjectList<TACLTreeListGroup>)
  strict private
    FIndex: TDictionary<string, TACLTreeListGroup>;
    FIndexLockCount: Integer;
    FTreeList: IACLTreeList;
  protected
    function CreateGroup(const ACaption: UnicodeString): TACLTreeListGroup; virtual;
    procedure Notify(const Item: TACLTreeListGroup; Action: TCollectionNotification); override;
  public
    constructor Create(ATreeList: IACLTreeList);
    destructor Destroy; override;
    function Add(const ACaption: UnicodeString): TACLTreeListGroup;
    procedure ClearLinks;
    function Find(const ACaption: UnicodeString): TACLTreeListGroup;
    procedure Move(ATargetIndex: Integer; AGroupsToMove: TACLList<TACLTreeListGroup>);
    procedure SetExpanded(AValue: Boolean);
    procedure Sort(AIntf: IComparer<TACLTreeListGroup>); reintroduce;
    procedure SortByNodeIndex;
    procedure Validate;
    //
    property TreeList: IACLTreeList read FTreeList;
  end;

  { TACLTreeListNode }

  TACLTreeListNodeFilterFunc = reference to function (ANode: TACLTreeListNode): Boolean;
  TACLTreeListNodeForEachFunc = reference to procedure (ANode: TACLTreeListNode);

  TACLTreeListNodeClass = class of TACLTreeListNode;
  TACLTreeListNode = class(TACLUnknownObject,
    IACLCheckableObject,
    IACLExpandableObject,
    IACLObjectLinksSupport,
    IACLSelectableObject,
    IACLTreeNodeLink)
  strict private
    FCheckMarkEnabled: Boolean;
    FData: Pointer;
    FGroup: TACLTreeListGroup;
    FHasChildren: Boolean;
    FImageIndex: TImageIndex;
    FParent: TACLTreeListNode;
    FSelected: Boolean;
    FTag: NativeInt;
    FTreeList: IACLTreeList;

    function GetAbsoluteVisibleIndex: Integer;
    function GetActualVisible: Boolean;
    function GetCheckState: TCheckBoxState;
    function GetChildren(Index: Integer): TACLTreeListNode;
    function GetChildrenCheckState: TCheckBoxState;
    function GetChildrenCount: Integer;
    function GetChildrenLoaded: Boolean;
    function GetIndex: Integer;
    function GetIsTopLevel: Boolean; inline;
    function GetLevel: Integer;
    function GetNextSibling: TACLTreeListNode;
    function GetPrevSibling: TACLTreeListNode;
    function GetTopLevel: TACLTreeListNode;
    procedure SetCheckMarkEnabled(const Value: Boolean);
    procedure SetChildrenCheckState(AValue: TCheckBoxState);
    procedure SetImageIndex(AValue: TImageIndex);
    procedure SetIndex(AValue: Integer);
    procedure SetParent(AValue: TACLTreeListNode);
  protected
    FChecked: Boolean;
    FExpanded: Boolean;
    FSortData: Integer;
    FSubNodes: TACLTreeListNodeList;

    procedure DoAssign(ANode: TACLTreeListNode); virtual;
    procedure SetGroup(AValue: TACLTreeListGroup);
    procedure StructChanged(ARegroupNeeded: Boolean = True);
    procedure ValuesChanged(AColumnIndex: Integer = -1);

    // Children
    function GetHasChildren: Boolean; virtual;
    procedure SetChildrenCapacity(AValue: Integer);

    // Values
    function GetValue(Index: Integer): UnicodeString; virtual; abstract;
    function GetValuesCapacity: Integer; virtual;
    function GetValuesCount: Integer; virtual; abstract;
    procedure SetValuesCapacity(AValue: Integer); virtual;
    procedure SetValue(Index: Integer; const S: UnicodeString); virtual;

    // IACLCheckableObject
    function CanCheck: Boolean;
    function GetChecked: Boolean;
    procedure SetChecked(AValue: Boolean);

    // IACLExpandableObject
    function CanToggle: Boolean;
    function GetExpanded: Boolean;
    procedure SetExpanded(AValue: Boolean);

    // IACLSelectableObject
    function GetSelected: Boolean;
    procedure SetSelected(AValue: Boolean);

    // IACLTreeNodeLink
    function GetChild: TObject;
    function GetParent: TObject;

    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; override; stdcall;

    property ActualVisible: Boolean read GetActualVisible;
  public
    constructor Create(ATreeList: IACLTreeList); virtual;
    destructor Destroy; override;
    procedure Assign(ANode: TACLTreeListNode);
    procedure BeforeDestruction; override;
    //
    function AddChild(const AValues: array of UnicodeString): TACLTreeListNode; overload;
    function AddChild: TACLTreeListNode; overload;
    function AddValue(const S: UnicodeString): Integer; virtual;
    function AddValues(const S: array of UnicodeString): Integer;
    procedure ChildrenNeeded;
    procedure Clear; virtual;
    procedure DeleteChildren; virtual;
    procedure DeleteValues; virtual;
    procedure ExpandCollapseChildren(AExpanded, ARecursive: Boolean);
    function EnumChildrenData<T: class>: IACLEnumerable<T>;
    function IsChild(ANode: TACLTreeListNode): Boolean;
    // Search
    function Find(const AData: Pointer; ARecursive: Boolean = True): TACLTreeListNode; overload;
    function Find(const AValue: UnicodeString; AColumnIndex: Integer = 0; ARecursive: Boolean = True): TACLTreeListNode; overload;
    function Find(out ANode: TACLTreeListNode; const AData: Pointer; ARecursive: Boolean = True): Boolean; overload;
    function Find(out ANode: TACLTreeListNode; const AFunc: TACLTreeListNodeFilterFunc; ARecursive: Boolean = True): Boolean; overload;
    function Find(out ANode: TACLTreeListNode; const ATag: NativeInt; ARecursive: Boolean = True): Boolean; overload;
    function Find(out ANode: TACLTreeListNode; const AValue: UnicodeString; AColumnIndex: Integer = 0; ARecursive: Boolean = True): Boolean; overload;
    // ForEach
    procedure ForEach(const AFunc: TACLTreeListNodeForEachFunc; ARecursive: Boolean = True);
    // Children
    property Children[Index: Integer]: TACLTreeListNode read GetChildren;
    property ChildrenCheckState: TCheckBoxState read GetChildrenCheckState write SetChildrenCheckState;
    property ChildrenCount: Integer read GetChildrenCount;
    property ChildrenLoaded: Boolean read GetChildrenLoaded;
    property HasChildren: Boolean read GetHasChildren write FHasChildren;
    // Values
    property Caption: UnicodeString index 0 read GetValue write SetValue;
    property Values[Index: Integer]: UnicodeString read GetValue write SetValue; default;
    property ValuesCapacity: Integer read GetValuesCapacity write SetValuesCapacity;
    property ValuesCount: Integer read GetValuesCount;
    //
    property AbsoluteVisibleIndex: Integer read GetAbsoluteVisibleIndex;
    property Checked: Boolean read GetChecked write SetChecked;
    property CheckMarkEnabled: Boolean read FCheckMarkEnabled write SetCheckMarkEnabled;
    property CheckState: TCheckBoxState read GetCheckState;
    property Data: Pointer read FData write FData;
    property Expanded: Boolean read GetExpanded write SetExpanded;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex;
    property Index: Integer read GetIndex write SetIndex;
    property IsTopLevel: Boolean read GetIsTopLevel;
    property Level: Integer read GetLevel;
    property Selected: Boolean read GetSelected write SetSelected;
    property Tag: NativeInt read FTag write FTag;
    //
    property Group: TACLTreeListGroup read FGroup;
    property NextSibling: TACLTreeListNode read GetNextSibling;
    property Parent: TACLTreeListNode read FParent write SetParent;
    property PrevSibling: TACLTreeListNode read GetPrevSibling;
    property TopLevel: TACLTreeListNode read GetTopLevel;
    //
    property TreeList: IACLTreeList read FTreeList;
  end;

  { TACLTreeListStringNode }

  TACLTreeListStringNode = class(TACLTreeListNode)
  protected
    FValues: TACLList<UnicodeString>;

    function GetValue(Index: Integer): UnicodeString; override;
    function GetValuesCapacity: Integer; override;
    function GetValuesCount: Integer; override;
    procedure SetValuesCapacity(AValue: Integer); override;
    procedure SetValue(Index: Integer; const S: UnicodeString); override;
  public
    destructor Destroy; override;
    procedure DeleteValues; override;
  end;

  { TACLTreeListNodeList }

  TACLTreeListNodeList = class(TACLList)
  strict private
    function GetCheckState: TCheckBoxState;
    function GetItem(Index: Integer): TACLTreeListNode;
    procedure SetCheckState(AValue: TCheckBoxState);
  public
    procedure GetCheckUncheckInfo(out ACheckedCount, AUncheckedCount: Integer); overload;
    procedure GetCheckUncheckInfo(out AHasChecked, AHasUnchecked: Boolean); overload;
    function First: TACLTreeListNode;
    function Last: TACLTreeListNode;
    function IsChild(ANode: TACLTreeListNode): Boolean;
    function IsValid(AIndex: Integer): Boolean; inline;
    //
    property CheckState: TCheckBoxState read GetCheckState write SetCheckState;
    property Items[Index: Integer]: TACLTreeListNode read GetItem; default;
  end;

  { TACLTreeListNodesDataEnumerator }

  TACLTreeListNodesDataEnumerator<T: class> = class(TInterfacedObject,
    IACLEnumerable<T>,
    IACLEnumerator<T>)
  strict private
    FIndex: Integer;
    FList: TACLTreeListNodeList;

    // IACLEnumerable<T>
    function GetEnumerator: IACLEnumerator<T>;
    // IACLEnumerator<T>
    function GetCurrent: T;
    function MoveNext: Boolean;
  public
    constructor Create(AList: TACLTreeListNodeList);
  end;

implementation

uses
  Math,
  RTLConsts,
  // ACL
  ACL.Math,
  ACL.MUI,
  ACL.Hashes,
  ACL.Utils.Common,
  ACL.Utils.Stream,
  ACL.Utils.Strings,
  ACL.Utils.Strings.Transcode;

const
  sErrorInvalidParent = 'Invalid Parent';

type

  { TACLTreeListColumnInfo }

  TACLTreeListColumnInfo = packed record
    Position: Byte;
    SortDirection: Byte;
    SortByIndex: SmallInt;
    Visible: Boolean;
    Width: Word;
  end;

{ TACLTreeListColumn }

constructor TACLTreeListColumn.Create(Collection: TCollection);
begin
  inherited Create(nil);
  InitializeFields;
  SetCollection(Collection);
end;

procedure TACLTreeListColumn.ApplyBestFit;
begin
  if CanResize or AutoBestFit then
    SetWidthCore(Columns.TreeList.CalculateBestFit(Self));
end;

procedure TACLTreeListColumn.Assign(Source: TPersistent);
begin
  if Source is TACLTreeListColumn then
  begin
    FAutoBestFit := TACLTreeListColumn(Source).AutoBestFit;
    FCanResize := TACLTreeListColumn(Source).CanResize;
    FCaption := TACLTreeListColumn(Source).Caption;
    FImageIndex := TACLTreeListColumn(Source).ImageIndex;
    FCompareMode := TACLTreeListColumn(Source).CompareMode;
    FTextAlign := TACLTreeListColumn(Source).TextAlign;
    FTextVisible := TACLTreeListColumn(Source).TextVisible;
    FVisible := TACLTreeListColumn(Source).Visible;
    FWidth := TACLTreeListColumn(Source).Width;
    Changed([cccnStruct]);
  end;
end;

procedure TACLTreeListColumn.Changed(AChanges: TIntegerSet);
begin
  Columns.TreeList.Changed(AChanges);
end;

procedure TACLTreeListColumn.InitializeFields;
begin
  FAutoBestFit := False;
  FCanResize := DefaultCanResize;
  FImageIndex := -1;
  FCompareMode := tlcmSmart;
  FTextVisible := True;
  FVisible := True;
  FWidth := DefaultWidth;
end;

procedure TACLTreeListColumn.Localize(const ASection: UnicodeString);
begin
  Caption := LangGet(ASection, 'c[' + IntToStr(Index) + ']', Caption);
end;

procedure TACLTreeListColumn.VisibleChanged;
begin
  if Columns.SortByList.Remove(Self) >= 0 then
    Changed([tlcnSorting]);
  Changed([cccnStruct]);
end;

function TACLTreeListColumn.GetColumns: TACLTreeListColumns;
begin
  Result := Collection as TACLTreeListColumns;
end;

function TACLTreeListColumn.GetDrawIndex: Integer;
begin
  Result := Columns.FDrawingItems.IndexOf(Self);
end;

function TACLTreeListColumn.GetGroupByIndex: Integer;
begin
  Result := Columns.GroupByList.IndexOf(Self);
end;

function TACLTreeListColumn.GetNextSibling: TACLTreeListColumn;
var
  AIndex: Integer;
begin
  AIndex := DrawIndex;
  if (AIndex >= 0) and (AIndex < Columns.FDrawingItems.Count - 1) then
    Result := Columns.FDrawingItems[AIndex + 1]
  else
    Result := nil;
end;

function TACLTreeListColumn.GetPrevSibling: TACLTreeListColumn;
var
  AIndex: Integer;
begin
  AIndex := DrawIndex;
  if AIndex >= 1 then
    Result := Columns.FDrawingItems[AIndex - 1]
  else
    Result := nil;
end;

function TACLTreeListColumn.GetSortByIndex: Integer;
begin
  Result := Columns.SortByList.IndexOf(Self);
end;

function TACLTreeListColumn.IsCanResizeStored: Boolean;
begin
  Result := (CanResize <> DefaultCanResize) and not AutoBestFit;
end;

function TACLTreeListColumn.IsDrawIndexStored: Boolean;
begin
  Result := Index <> DrawIndex;
end;

function TACLTreeListColumn.IsWidthStored: Boolean;
begin
  Result := (Width <> DefaultWidth) and not AutoBestFit;
end;

procedure TACLTreeListColumn.SetAutoBestFit(AValue: Boolean);
begin
  if FAutoBestFit <> AValue then
  begin
    FAutoBestFit := AValue;
    if AutoBestFit then
    begin
      FCanResize := False;
      Changed([cccnLayout]);
    end;
  end;
end;

procedure TACLTreeListColumn.SetCanResize(AValue: Boolean);
begin
  if FCanResize <> AValue then
  begin
    FCanResize := AValue;
    FAutoBestFit := False;
    Changed([cccnLayout]);
  end;
end;

procedure TACLTreeListColumn.SetCaption(const AValue: UnicodeString);
begin
  if AValue <> FCaption then
  begin
    FCaption := AValue;
    Changed([cccnContent]);
  end;
end;

procedure TACLTreeListColumn.SetDrawIndex(AValue: Integer);
begin
  AValue := MinMax(AValue, 0, Columns.Count - 1);
  if DrawIndex <> AValue then
  begin
    Columns.FDrawingItems.Move(DrawIndex, AValue);
    Changed([cccnStruct]);
  end;
end;

procedure TACLTreeListColumn.SetImageIndex(AValue: TImageIndex);
begin
  if AValue <> FImageIndex then
  begin
    FImageIndex := AValue;
    Changed([cccnContent]);
  end;
end;

procedure TACLTreeListColumn.SetCompareMode(AValue: TACLTreeListCompareMode);
begin
  if AValue <> FCompareMode then
  begin
    FCompareMode := AValue;
    Changed([tlcnSorting]);
  end;
end;

procedure TACLTreeListColumn.SetTextAlign(AAlign: TAlignment);
begin
  if AAlign <> FTextAlign then
  begin
    FTextAlign := AAlign;
    Changed([cccnContent]);
  end;
end;

procedure TACLTreeListColumn.SetTextVisible(AValue: Boolean);
begin
  if AValue <> TextVisible then
  begin
    FTextVisible := AValue;
    Changed([cccnContent]);
  end;
end;

procedure TACLTreeListColumn.SetVisible(AValue: Boolean);
begin
  if AValue <> Visible then
  begin
    Columns.BeginUpdate;
    try
      FVisible := AValue;
      VisibleChanged;
    finally
      Columns.EndUpdate;
    end;
  end;
end;

procedure TACLTreeListColumn.SetWidth(AValue: Integer);
begin
  if AValue <> FWidth then
  begin
    FAutoBestFit := False;
    SetWidthCore(AValue);
  end;
end;

procedure TACLTreeListColumn.SetWidthCore(AValue: Integer);
begin
  AValue := Max(AValue, tlColumnMinWidth);
  if AValue <> FWidth then
  begin
    FWidth := AValue;
    Changed([cccnLayout]);
  end;
end;

{ TACLTreeListColumns }

constructor TACLTreeListColumns.Create(AOwner: IACLTreeList);
begin
  inherited Create(GetColumnClass);
  FTreeList := AOwner;
  FDrawingItems := TACLTreeListColumnList.Create(False);
end;

destructor TACLTreeListColumns.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FDrawingItems);
end;

function TACLTreeListColumns.Add(const AText: UnicodeString = ''): TACLTreeListColumn;
begin
  BeginUpdate;
  try
    Result := TACLTreeListColumn(inherited Add);
    Result.Caption := AText;
  finally
    EndUpdate;
  end;
end;

procedure TACLTreeListColumns.ApplyBestFit(AAuto: Boolean = False);
var
  AItem: TACLTreeListColumn;
  I: Integer;
begin
  BeginUpdate;
  try
    for I := 0 to Count - 1 do
    begin
      AItem := Items[I];
      if not AAuto or AItem.AutoBestFit then
        AItem.ApplyBestFit;
    end;
  finally
    EndUpdate;
  end;
end;

function TACLTreeListColumns.FindByCaption(const ACaption: UnicodeString): TACLTreeListColumn;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if acSameText(Items[I].Caption, ACaption) then
      Exit(Items[I]);
  end;
  Result := nil;
end;

function TACLTreeListColumns.First: TACLTreeListColumn;
begin
  Result := Items[0];
end;

function TACLTreeListColumns.Last: TACLTreeListColumn;
begin
  Result := Items[Count - 1];
end;

function TACLTreeListColumns.IsValid(AColumn: TACLTreeListColumn): Boolean;
begin
  Result := FDrawingItems.IndexOf(AColumn) >= 0;
end;

function TACLTreeListColumns.IsValid(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Count);
end;

procedure TACLTreeListColumns.Localize(const ASection: UnicodeString);
var
  I: Integer;
begin
  BeginUpdate;
  try
    for I := 0 to Count - 1 do
      Items[I].Localize(ASection);
  finally
    EndUpdate;
  end;
end;

procedure TACLTreeListColumns.BeginUpdate;
begin
  TreeList.BeginUpdate;
end;

procedure TACLTreeListColumns.EndUpdate;
begin
  TreeList.EndUpdate;
end;

procedure TACLTreeListColumns.ConfigLoad(AStream: TStream);
var
  AColumn: TACLTreeListColumn;
  ADrawingIndexes: array of Integer;
  AInfo: TACLTreeListColumnInfo;
  ASortingIndexes: array of Integer;
  I: Integer;
begin
  BeginUpdate;
  try
    SortByList.Clear;

    SetLength(ADrawingIndexes, Count);
    SetLength(ASortingIndexes, Count);
    for I := 0 to Count - 1 do
    begin
      ADrawingIndexes[I] := -1;
      ASortingIndexes[I] := -1;
    end;

    for I := 0 to Count - 1 do
      if AStream.Read(AInfo, SizeOf(AInfo)) = SizeOf(AInfo) then
      begin
        AColumn := Items[I];
        if TreeList.ColumnsCanCustomizeVisibility then
          AColumn.Visible := AInfo.Visible;
        if AColumn.CanResize then
          AColumn.Width := AInfo.Width;
        if InRange(AInfo.Position, 0, Count - 1) then
          ADrawingIndexes[AInfo.Position] := I;
        if InRange(AInfo.SortByIndex, 0, Count - 1) then
        begin
          ASortingIndexes[AInfo.SortByIndex] := I;
          AColumn.FSortDirection := TACLSortDirection(AInfo.SortDirection + 1);
        end;
      end
      else
        Break;

    if TreeList.ColumnsCanCustomizeOrder then
      for I := 0 to Length(ADrawingIndexes) - 1 do
      begin
        if ADrawingIndexes[I] <> -1 then
          Items[ADrawingIndexes[I]].DrawIndex := I
        else
          Break;
      end;

    for I := 0 to Length(ASortingIndexes) - 1 do
    begin
      if ASortingIndexes[I] <> -1 then
        SortByList.Add(Items[ASortingIndexes[I]])
      else
        Break;
    end;
    TreeList.Changed([tlcnSorting]);
  finally
    EndUpdate;
  end;
end;

procedure TACLTreeListColumns.ConfigLoad(AConfig: TACLIniFile; const ASection, AItem: UnicodeString);
var
  AStream: TMemoryStream;
begin
  if AConfig.ExistsKey(ASection, AItem) then
  begin
    AStream := TMemoryStream.Create;
    try
      AConfig.ReadStream(ASection, AItem, AStream);
      ConfigLoad(AStream);
    finally
      AStream.Free;
    end;
  end;
end;

procedure TACLTreeListColumns.ConfigSave(AStream: TStream);
var
  AColumn: TACLTreeListColumn;
  AInfo: TACLTreeListColumnInfo;
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    AColumn := Items[I];
    AInfo.Position := AColumn.DrawIndex;
    AInfo.SortDirection := Ord(AColumn.FSortDirection) - 1;
    AInfo.SortByIndex := AColumn.SortByIndex;
    AInfo.Visible := AColumn.Visible;
    AInfo.Width := AColumn.Width;
    AStream.WriteBuffer(AInfo, SizeOf(AInfo));
  end;
end;

procedure TACLTreeListColumns.ConfigSave(AConfig: TACLIniFile; const ASection, AItem: UnicodeString);
var
 AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    ConfigSave(AStream);
    AStream.Position := 0;
    AConfig.WriteStream(ASection, AItem, AStream);
  finally
    AStream.Free;
  end;
end;

function TACLTreeListColumns.GetColumnClass: TACLTreeListColumnClass;
begin
  Result := TACLTreeListColumn;
end;

function TACLTreeListColumns.GetDrawingItem(Index: Integer): TACLTreeListColumn;
begin
  Result := FDrawingItems[Index];
end;

function TACLTreeListColumns.GetOwner: TPersistent;
begin
  if TreeList <> nil then  
    Result := TreeList.GetObject
  else
    Result := nil;
end;

procedure TACLTreeListColumns.Notify(Item: TCollectionItem; Action: TCollectionNotification);
begin
  if Action = cnAdded then
    FDrawingItems.Add(TACLTreeListColumn(Item))
  else
  begin
    FDrawingItems.Remove(TACLTreeListColumn(Item));
    GroupByList.Remove(TACLTreeListColumn(Item));
    SortByList.Remove(TACLTreeListColumn(Item));
  end;
  inherited Notify(Item, Action);
end;

procedure TACLTreeListColumns.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Item = nil then
    TreeList.Changed([cccnStruct])
  else
    TreeList.Changed([cccnLayout]);
end;

function TACLTreeListColumns.GetGroupByList: TACLTreeListColumnList;
begin
  Result := TreeList.GetGroupByList;
end;

function TACLTreeListColumns.GetItem(Index: Integer): TACLTreeListColumn;
begin
  Result := TACLTreeListColumn(inherited Items[Index]);
end;

function TACLTreeListColumns.GetSortByList: TACLTreeListColumnList;
begin
  Result := TreeList.GetSortByList;
end;

function TACLTreeListColumns.GetVisibleCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Count - 1 do
  begin
    if Items[I].Visible then
      Inc(Result);
  end;
end;

procedure TACLTreeListColumns.SetItem(Index: Integer; Value: TACLTreeListColumn);
begin
  inherited Items[Index] := Value;
end;

{ TACLTreeListColumnList }

function TACLTreeListColumnList.IsValidIndex(Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index < Count);
end;

{ TACLTreeListGroup }

constructor TACLTreeListGroup.Create(const ACaption: UnicodeString; AOwner: TACLTreeListGroups);
begin
  inherited Create;
  FOwner := AOwner;
  FLinks := TACLTreeListNodeList.Create;
  FCaption := ACaption;
  FExpanded := True;
end;

destructor TACLTreeListGroup.Destroy;
begin
  FreeAndNil(FLinks);
  inherited Destroy;
end;

procedure TACLTreeListGroup.BeforeDestruction;
begin
  inherited BeforeDestruction;
  TreeList.GroupRemoving(Self);
  TACLObjectLinks.Release(Self);
end;

function TACLTreeListGroup.CanCheck: Boolean;
begin
  Result := True;
end;

function TACLTreeListGroup.GetChecked: Boolean;
begin
  Result := CheckBoxState = cbChecked;
end;

procedure TACLTreeListGroup.SetChecked(AValue: Boolean);
begin
  CheckBoxState := TCheckBoxState(AValue);
end;

function TACLTreeListGroup.CanToggle: Boolean;
begin
  Result := True;
end;

function TACLTreeListGroup.GetExpanded: Boolean;
begin
  Result := FExpanded;
end;

procedure TACLTreeListGroup.SetExpanded(AValue: Boolean);
begin
  if AValue <> FExpanded then
  begin
    FExpanded := AValue;
    TreeList.Changed([cccnStruct]);
  end;
end;

function TACLTreeListGroup.GetChild: TObject;
begin
  Result := Links.First;
end;

function TACLTreeListGroup.GetParent: TObject;
begin
  Result := nil;
end;

function TACLTreeListGroup.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  Result := inherited QueryInterface(IID, Obj);
  if Result = E_NOINTERFACE then
    Result := TreeList.QueryChildInterface(Self, IID, Obj);
end;

function TACLTreeListGroup.GetCheckBoxState: TCheckBoxState;
begin
  Result := Links.CheckState;
end;

function TACLTreeListGroup.GetIndex: Integer;
begin
  Result := FOwner.IndexOf(Self);
end;

function TACLTreeListGroup.GetNextSibling: TACLTreeListGroup;
var
  AIndex: Integer;
begin
  AIndex := Index + 1;
  if AIndex < FOwner.Count then
    Result := FOwner.List[AIndex]
  else
    Result := nil;
end;

function TACLTreeListGroup.GetPrevSibling: TACLTreeListGroup;
var
  AIndex: Integer;
begin
  AIndex := Index - 1;
  if AIndex >= 0 then
    Result := FOwner.List[AIndex]
  else
    Result := nil;
end;

function TACLTreeListGroup.GetSelected: Boolean;

  function IsSelected(ANode: TACLTreeListNode): Boolean;
  var
    I: Integer;
  begin
    Result := ANode.Selected;
    if Result and ANode.Expanded then
    begin
      for I := 0 to ANode.ChildrenCount - 1 do
        Result := Result and IsSelected(ANode.Children[I]);
    end;
  end;

var
  I: Integer;
begin
  Result := True;
  for I := Links.Count - 1 downto 0 do
  begin
    Result := Result and IsSelected(Links[I]);
    if not Result then Break;
  end;
end;

function TACLTreeListGroup.GetTreeList: IACLTreeList;
begin
  Result := Owner.TreeList;
end;

procedure TACLTreeListGroup.SetCheckBoxState(AValue: TCheckBoxState);
begin
  Links.CheckState := AValue;
end;

procedure TACLTreeListGroup.SetSelected(AValue: Boolean);

  procedure DoSetSelected(ANode: TACLTreeListNode; AValue: Boolean);
  var
    I: Integer;
  begin
    ANode.Selected := AValue;
    if ANode.Expanded then
    begin
      for I := 0 to ANode.ChildrenCount - 1 do
        DoSetSelected(ANode.Children[I], AValue);
    end;
  end;

var
  I: Integer;
begin
  TreeList.BeginUpdate;
  try
    for I := 0 to Links.Count - 1 do
      DoSetSelected(Links[I], AValue);
  finally
    TreeList.EndUpdate;
  end;
end;

{ TACLTreeListGroupSortDataComparer }

function TACLTreeListGroupSortDataComparer.Compare(const Left, Right: TACLTreeListGroup): Integer;
begin
  Result := Left.FSortData - Right.FSortData;
end;

{ TACLTreeListGroups }

constructor TACLTreeListGroups.Create(ATreeList: IACLTreeList);
begin
  inherited Create;
  FTreeList := ATreeList;
  FIndex := TDictionary<string, TACLTreeListGroup>.Create;
end;

destructor TACLTreeListGroups.Destroy;
begin
  FreeAndNil(FIndex);
  inherited;
end;

function TACLTreeListGroups.Add(const ACaption: UnicodeString): TACLTreeListGroup;
begin
  if not FIndex.TryGetValue(ACaption, Result) then
  begin
    Result := CreateGroup(ACaption);
    inherited Add(Result);
  end;
end;

procedure TACLTreeListGroups.ClearLinks;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
    List[I].Links.Count := 0;
end;

function TACLTreeListGroups.Find(const ACaption: UnicodeString): TACLTreeListGroup;
begin
  if not FIndex.TryGetValue(ACaption, Result) then
    Result := nil;
end;

procedure TACLTreeListGroups.Move(ATargetIndex: Integer; AGroupsToMove: TACLList<TACLTreeListGroup>);
var
  AIndex: Integer;
begin
  for AIndex := 0 to AGroupsToMove.Count - 1 do
  begin
    if not Contains(AGroupsToMove.List[AIndex]) then
      raise EInvalidArgument.Create('The group has different owner');
  end;

  Inc(FIndexLockCount);
  try
    for AIndex := 0 to Count - 1 do
    begin
      if AGroupsToMove.IndexOf(List[AIndex]) >= 0 then
        List[AIndex] := nil;
    end;
    for AIndex := 0 to AGroupsToMove.Count - 1 do
      Insert(ATargetIndex + AIndex, AGroupsToMove[AIndex]);
    Pack;
  finally
    Dec(FIndexLockCount);
  end;

  TreeList.Changed([tlcnGroupIndex]);
end;

procedure TACLTreeListGroups.SetExpanded(AValue: Boolean);
var
  I: Integer;
begin
  TreeList.BeginUpdate;
  try
    for I := Count - 1 downto 0 do
      List[I].Expanded := AValue;
  finally
    TreeList.EndUpdate;
  end;
end;

procedure TACLTreeListGroups.Sort(AIntf: IComparer<TACLTreeListGroup>);
begin
  inherited Sort(AIntf); // prevent memory leak
end;

procedure TACLTreeListGroups.SortByNodeIndex;
var
  AGroup: TACLTreeListGroup;
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    AGroup := List[I];
    if AGroup.Links.Count > 0 then
      AGroup.FSortData := AGroup.Links.First.Index
    else
      AGroup.FSortData := MaxInt;
  end;
  Sort(TACLTreeListGroupSortDataComparer.Create);
end;

procedure TACLTreeListGroups.Validate;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
  begin
    if List[I].Links.Count = 0 then
      Delete(I)
  end;
end;

function TACLTreeListGroups.CreateGroup(const ACaption: UnicodeString): TACLTreeListGroup;
begin
  Result := TACLTreeListGroup.Create(ACaption, Self);
end;

procedure TACLTreeListGroups.Notify;
begin
  if (FIndex <> nil) and (FIndexLockCount = 0) then
    case Action of
      cnRemoved,
      cnExtracted:
        FIndex.Remove(Item.Caption);
      cnAdded:
        FIndex.Add(Item.Caption, Item);
    end;
  inherited;
end;

{ TACLTreeListNode }

constructor TACLTreeListNode.Create(ATreeList: IACLTreeList);
begin
  inherited Create;
  FTreeList := ATreeList;
  FCheckMarkEnabled := True;
  FImageIndex := -1;
  FSortData := -1;
end;

destructor TACLTreeListNode.Destroy;
begin
  FreeAndNil(FSubNodes);
  inherited Destroy;
end;

procedure TACLTreeListNode.Assign(ANode: TACLTreeListNode);
begin
  TreeList.BeginUpdate;
  try
    Clear;
    if ANode <> nil then
      DoAssign(ANode);
  finally
    TreeList.EndUpdate;
  end;
end;

procedure TACLTreeListNode.BeforeDestruction;
begin
  inherited BeforeDestruction;
  TreeList.NodeRemoving(Self);
  TACLObjectLinks.Release(Self);
  Clear;
end;

function TACLTreeListNode.AddChild(const AValues: array of UnicodeString): TACLTreeListNode;
begin
  TreeList.BeginUpdate;
  try
    Result := AddChild;
    Result.AddValues(AValues);
  finally
    TreeList.EndUpdate;
  end;
end;

function TACLTreeListNode.AddChild: TACLTreeListNode;
begin
  TreeList.BeginUpdate;
  try
    Result := TreeList.CreateNode;
    Result.Parent := Self;
    StructChanged;
  finally
    TreeList.EndUpdate;
  end;
end;

function TACLTreeListNode.AddValue(const S: UnicodeString): Integer;
begin
  Result := ValuesCount;
  Values[Result] := S;
end;

function TACLTreeListNode.AddValues(const S: array of UnicodeString): Integer;
var
  I: Integer;
begin
  TreeList.BeginUpdate;
  try
    Result := -1;
    for I := 0 to Length(S) - 1 do
      Result := AddValue(S[I]);
  finally
    TreeList.EndUpdate;
  end;
end;

procedure TACLTreeListNode.ChildrenNeeded;
begin
  if FHasChildren and (FSubNodes = nil) then
  begin
    TreeList.BeginLongOperation;
    TreeList.BeginUpdate;
    try
      FHasChildren := False;
      TreeList.NodePopulateChildren(Self);
      FHasChildren := ChildrenLoaded;
    finally
      TreeList.EndUpdate;
      TreeList.EndLongOperation;
    end;
  end;
end;

procedure TACLTreeListNode.Clear;
begin
  TreeList.BeginUpdate;
  try
    DeleteChildren;
    DeleteValues;
  finally
    TreeList.EndUpdate;
  end;
end;

procedure TACLTreeListNode.DeleteChildren;
var
  ASubNodes: TACLTreeListNodeList;
  I: Integer;
begin
  if FSubNodes <> nil then
  begin
    TreeList.BeginUpdate;
    try
      ASubNodes := FSubNodes;
      FSubNodes := nil;
      for I := ASubNodes.Count - 1 downto 0 do
        ASubNodes[I].Free;
      FreeAndNil(ASubNodes);
      StructChanged(False);
    finally
      TreeList.EndUpdate;
    end;
  end;
end;

procedure TACLTreeListNode.DeleteValues;
begin
  // do nothing
end;

procedure TACLTreeListNode.ExpandCollapseChildren(AExpanded, ARecursive: Boolean);
begin
  ForEach(
    procedure (ANode: TACLTreeListNode)
    begin
      ANode.Expanded := AExpanded;
    end,
    ARecursive);
end;

function TACLTreeListNode.EnumChildrenData<T>: IACLEnumerable<T>;
begin
  ChildrenNeeded;
  Result := TACLTreeListNodesDataEnumerator<T>.Create(FSubNodes);
end;

function TACLTreeListNode.IsChild(ANode: TACLTreeListNode): Boolean;
var
  I: Integer;
begin
  Result := False;
  if FSubNodes <> nil then
  begin
    Result := FSubNodes.IndexOf(ANode) >= 0;
    if not Result then
    begin
      for I := 0 to ChildrenCount - 1 do
      begin
        Result := Children[I].IsChild(ANode);
        if Result then Break;
      end;
    end;
  end;
end;

function TACLTreeListNode.Find(out ANode: TACLTreeListNode;
  const AValue: UnicodeString; AColumnIndex: Integer = 0; ARecursive: Boolean = True): Boolean;
begin
  Result := Find(ANode,
    function (ANode: TACLTreeListNode): Boolean
    begin
      Result := acSameText(AValue, ANode.Values[AColumnIndex]);
    end,
    ARecursive);
end;

function TACLTreeListNode.Find(const AData: Pointer; ARecursive: Boolean = True): TACLTreeListNode;
begin
  if not Find(Result, AData, ARecursive) then
    Result := nil;
end;

function TACLTreeListNode.Find(const AValue: UnicodeString;
  AColumnIndex: Integer = 0; ARecursive: Boolean = True): TACLTreeListNode;
begin
  if not Find(Result, AValue, AColumnIndex, ARecursive) then
    Result := nil;
end;

function TACLTreeListNode.Find(out ANode: TACLTreeListNode;
  const AFunc: TACLTreeListNodeFilterFunc; ARecursive: Boolean = True): Boolean;
var
  I: Integer;
begin
  Result := False;
  if ChildrenLoaded then
  begin
    for I := 0 to ChildrenCount - 1 do
      if AFunc(Children[I]) then
      begin
        ANode := Children[I];
        Exit(True);
      end;

    if ARecursive then
      for I := 0 to ChildrenCount - 1 do
      begin
        if Children[I].Find(ANode, AFunc) then
          Exit(True);
      end;
  end;
end;

function TACLTreeListNode.Find(out ANode: TACLTreeListNode; const ATag: NativeInt; ARecursive: Boolean = True): Boolean;
begin
  Result := Find(ANode,
    function (ANode: TACLTreeListNode): Boolean
    begin
      Result := ATag = ANode.Tag;
    end,
    ARecursive);
end;

function TACLTreeListNode.Find(out ANode: TACLTreeListNode; const AData: Pointer; ARecursive: Boolean = True): Boolean;
begin
  Result := Find(ANode,
    function (ANode: TACLTreeListNode): Boolean
    begin
      Result := AData = ANode.Data;
    end,
    ARecursive);
end;

procedure TACLTreeListNode.ForEach(const AFunc: TACLTreeListNodeForEachFunc; ARecursive: Boolean = True);
var
  I: Integer;
begin
  if ChildrenLoaded then
  begin
    for I := 0 to ChildrenCount - 1 do
      AFunc(Children[I]);
    if ARecursive then
    begin
      for I := 0 to ChildrenCount - 1 do
        Children[I].ForEach(AFunc, ARecursive);
    end;
  end;
end;

function TACLTreeListNode.GetNextSibling: TACLTreeListNode;
var
  AIndex: Integer;
begin
  AIndex := Index;
  if (Parent <> nil) and (AIndex >= 0) and (AIndex + 1 < Parent.ChildrenCount) then
    Result := Parent.Children[AIndex + 1]
  else
    Result := nil;
end;

function TACLTreeListNode.GetPrevSibling: TACLTreeListNode;
var
  AIndex: Integer;
begin
  AIndex := Index;
  if AIndex > 0 then
    Result := Parent.Children[AIndex - 1]
  else
    Result := nil;
end;

procedure TACLTreeListNode.StructChanged(ARegroupNeeded: Boolean = True);
var
  AChanges: TIntegerSet;
begin
  AChanges := [cccnStruct];
  if ARegroupNeeded then
  begin
    Include(AChanges, tlcnGrouping);
    Include(AChanges, tlcnSorting);
  end;
  TreeList.Changed(AChanges);
end;

procedure TACLTreeListNode.ValuesChanged(AColumnIndex: Integer = -1);
begin
  TreeList.NodeValuesChanged(AColumnIndex);
end;

procedure TACLTreeListNode.DoAssign(ANode: TACLTreeListNode);
var
  I: Integer;
begin
  Tag := ANode.Tag;
  Checked := ANode.Checked;
  Expanded := ANode.Expanded;
  Data := ANode.Data;
  ImageIndex := ANode.ImageIndex;
  ValuesCapacity := ANode.ValuesCount;
  for I := 0 to ANode.ValuesCount - 1 do
    AddValue(ANode.Values[I]);
  for I := 0 to ANode.ChildrenCount - 1 do
    AddChild.Assign(ANode.Children[I]);
end;

procedure TACLTreeListNode.SetGroup(AValue: TACLTreeListGroup);
begin
  if AValue <> FGroup then
  begin
    if AValue <> nil then
      AValue.Links.Add(Self);
    if FGroup <> nil then
      FGroup.Links.RemoveItem(Self, FromEnd);
    FGroup := AValue;
  end;
end;

function TACLTreeListNode.CanCheck: Boolean;
begin
  Result := CheckMarkEnabled;
end;

function TACLTreeListNode.GetChecked: Boolean;
begin
  Result := CheckState = cbChecked;
end;

procedure TACLTreeListNode.SetChecked(AValue: Boolean);
var
  I: Integer;
begin
  if AValue <> Checked then
  begin
    TreeList.BeginUpdate;
    try
      FChecked := AValue;
      if TreeList.AutoCheckChildren and ChildrenLoaded then
      begin
        for I := 0 to ChildrenCount - 1 do
          Children[I].Checked := FChecked;
      end;
      TreeList.NodeChecked(Self);
      TreeList.Changed([tlcnCheckState]);
    finally
      TreeList.EndUpdate;
    end;
  end;
end;

function TACLTreeListNode.CanToggle: Boolean;
begin
  Result := HasChildren;
end;

function TACLTreeListNode.GetExpanded: Boolean;
begin
  Result := FExpanded;
end;

procedure TACLTreeListNode.SetExpanded(AValue: Boolean);
begin
  if Expanded <> AValue then
  begin
    FExpanded := AValue;
    if Expanded then
      ChildrenNeeded;
    if ActualVisible then
      StructChanged(False);
  end;
end;

function TACLTreeListNode.GetSelected: Boolean;
begin
  Result := FSelected;
end;

function TACLTreeListNode.GetTopLevel: TACLTreeListNode;
begin
  Result := Self;
  while (Result <> nil) and not Result.IsTopLevel do
    Result := Result.Parent;
end;

procedure TACLTreeListNode.SetSelected(AValue: Boolean);
begin
  if AValue <> Selected then
  begin
    TreeList.BeginUpdate;
    try
      TreeList.NodeSetSelected(Self, AValue);
      FSelected := AValue;
    finally
      TreeList.EndUpdate;
    end;
  end;
end;

function TACLTreeListNode.GetChild: TObject;
begin
  if ChildrenCount > 0 then
    Result := Children[0]
  else
    Result := nil;
end;

function TACLTreeListNode.GetParent: TObject;
begin
  Result := Group;
  if Result = nil then
    Result := Parent;
end;

function TACLTreeListNode.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  Result := inherited QueryInterface(IID, Obj);
  if Result = E_NOINTERFACE then
    Result := TreeList.QueryChildInterface(Self, IID, Obj);
end;

function TACLTreeListNode.GetAbsoluteVisibleIndex: Integer;
begin
  Result := TreeList.AbsoluteVisibleNodes.IndexOf(Self);
end;

function TACLTreeListNode.GetCheckState: TCheckBoxState;
begin
  if TreeList.AutoCheckParents and ChildrenLoaded then
    Result := ChildrenCheckState
  else
    if FChecked then
      Result := cbChecked
    else
      Result := cbUnchecked;
end;

function TACLTreeListNode.GetChildren(Index: Integer): TACLTreeListNode;
begin
  if FSubNodes = nil then
    ChildrenNeeded;
  Result := FSubNodes[Index];
end;

function TACLTreeListNode.GetChildrenCheckState: TCheckBoxState;
begin
  if FSubNodes = nil then
    ChildrenNeeded;
  if FSubNodes <> nil then
    Result := FSubNodes.CheckState
  else
    Result := cbUnchecked;
end;

function TACLTreeListNode.GetChildrenCount: Integer;
begin
  if FSubNodes = nil then
    ChildrenNeeded;
  if FSubNodes <> nil then
    Result := FSubNodes.Count
  else
    Result := 0;
end;

function TACLTreeListNode.GetChildrenLoaded: Boolean;
begin
  Result := HasChildren and (FSubNodes <> nil);
end;

function TACLTreeListNode.GetHasChildren: Boolean;
begin
  Result := FHasChildren or (FSubNodes <> nil) and (FSubNodes.Count > 0);
end;

procedure TACLTreeListNode.SetChildrenCapacity(AValue: Integer);
begin
  if FSubNodes <> nil then
    FSubNodes.Capacity := AValue;
end;

function TACLTreeListNode.GetValuesCapacity: Integer;
begin
  Result := 0;
end;

procedure TACLTreeListNode.SetValue(Index: Integer; const S: UnicodeString);
begin
  raise ENotSupportedException.Create(ClassName + '.SetValue');
end;

procedure TACLTreeListNode.SetValuesCapacity(AValue: Integer);
begin
  // do nothing
end;

function TACLTreeListNode.GetIndex: Integer;
begin
  if (Parent <> nil) and (Parent.FSubNodes <> nil) then
    Result := Parent.FSubNodes.IndexOf(Self)
  else
    Result := 0;
end;

function TACLTreeListNode.GetIsTopLevel: Boolean;
begin
  Result := (Parent = nil) or (Parent.Parent = nil); // it faster
//  Result := Parent = TreeList.RootNode;
end;

function TACLTreeListNode.GetLevel: Integer;
begin
  if IsTopLevel then
    Result := 0
  else
    Result := Parent.Level + 1;
end;

function TACLTreeListNode.GetActualVisible: Boolean;
var
  ANode: TACLTreeListNode;
  ARootNode: TACLTreeListNode;
begin
  Result := True;
  ANode := Parent;
  ARootNode := TreeList.RootNode;
  while Result and (ANode <> ARootNode) do
  begin
    Result := Result and ANode.Expanded;
    ANode := ANode.Parent;
  end;
end;

procedure TACLTreeListNode.SetCheckMarkEnabled(const Value: Boolean);
begin
  if FCheckMarkEnabled <> Value then
  begin
    FCheckMarkEnabled := Value;
    TreeList.Changed([cccnContent]);
  end;
end;

procedure TACLTreeListNode.SetChildrenCheckState(AValue: TCheckBoxState);
begin
  if FSubNodes = nil then
    ChildrenNeeded;
  if FSubNodes <> nil then
    FSubNodes.CheckState := AValue;
end;

procedure TACLTreeListNode.SetImageIndex(AValue: TImageIndex);
begin
  if AValue <> FImageIndex then
  begin
    FImageIndex := AValue;
    TreeList.Changed([cccnContent]);
  end;
end;

procedure TACLTreeListNode.SetIndex(AValue: Integer);
begin
  if Parent <> nil then
  begin
    if not Parent.FSubNodes.ChangePlace(Index, AValue) then
      raise EACLTreeListException.CreateFmt(sArgumentOutOfRange_Index, [AValue, Parent.ChildrenCount - 1]);
    StructChanged;
  end;
end;

procedure TACLTreeListNode.SetParent(AValue: TACLTreeListNode);
begin
  if (AValue <> nil) and ((AValue = Self) or IsChild(AValue)) then
    raise EACLTreeListException.Create(sErrorInvalidParent);

  if Parent <> AValue then
  begin
    SetGroup(nil);
    if Parent <> nil then
    begin
      if Parent.FSubNodes <> nil then
        Parent.FSubNodes.Extract(Self);
    end;
    if AValue <> nil then
    begin
      FParent := AValue;
      if TreeList.AutoCheckChildren then
        FChecked := Parent.Checked;
      if Parent.FSubNodes = nil then
        Parent.FSubNodes := TACLTreeListNodeList.Create;
      Parent.FSubNodes.Add(Self);
    end;
    StructChanged;
  end;
end;

{ TACLTreeListStringNode }

destructor TACLTreeListStringNode.Destroy;
begin
  FreeAndNil(FValues);
  inherited Destroy;
end;

procedure TACLTreeListStringNode.DeleteValues;
begin
  if FValues <> nil then
  begin
    FreeAndNil(FValues);
    ValuesChanged;
  end;
end;

function TACLTreeListStringNode.GetValue(Index: Integer): UnicodeString;
begin
  if (FValues <> nil) and (Index >= 0) and (Index < FValues.Count) then
    Result := FValues.List[Index]
  else
    Result := EmptyStr;
end;

function TACLTreeListStringNode.GetValuesCapacity: Integer;
begin
  if FValues <> nil then
    Result := FValues.Capacity
  else
    Result := 0;
end;

function TACLTreeListStringNode.GetValuesCount: Integer;
begin
  if FValues <> nil then
    Result := FValues.Count
  else
    Result := 0;
end;

procedure TACLTreeListStringNode.SetValue(Index: Integer; const S: UnicodeString);
var
  I: Integer;
begin
  if Index < 0 then
    Exit;
  if (FValues = nil) or (Index >= FValues.Count) or (FValues.List[Index] <> S) then
  begin
    if FValues = nil then
      FValues := TACLList<UnicodeString>.Create;
    for I := FValues.Count to Index do
      FValues.Add(EmptyStr);
    FValues.Items[Index] := S;
    ValuesChanged(Index);
  end;
end;

procedure TACLTreeListStringNode.SetValuesCapacity(AValue: Integer);
begin
  if AValue <> ValuesCapacity then
  begin
    if FValues = nil then
      FValues := TACLList<UnicodeString>.Create;
    FValues.Capacity := AValue;
  end;
end;

{ TACLTreeListNodeList }

procedure TACLTreeListNodeList.GetCheckUncheckInfo(out ACheckedCount, AUncheckedCount: Integer);
var
  I: Integer;
begin
  ACheckedCount := 0;
  AUncheckedCount := 0;
  for I := 0 to Count - 1 do
  begin
    if TACLTreeListNode(List[I]).Checked then
      Inc(ACheckedCount)
    else
      Inc(AUncheckedCount);
  end;
end;

procedure TACLTreeListNodeList.GetCheckUncheckInfo(out AHasChecked, AHasUnchecked: Boolean);
var
  ANode: TACLTreeListNode;
  I: Integer;
begin
  AHasChecked := False;
  AHasUnchecked := False;
  for I := 0 to Count - 1 do
  begin
    ANode := TACLTreeListNode(List[I]);
    AHasChecked := AHasChecked or ANode.Checked;
    AHasUnchecked := AHasUnchecked or not ANode.Checked;
    if AHasUnchecked and AHasChecked then Break;
  end;
end;

function TACLTreeListNodeList.First: TACLTreeListNode;
begin
  Result := TACLTreeListNode(inherited First);
end;

function TACLTreeListNodeList.Last: TACLTreeListNode;
begin
  Result := TACLTreeListNode(inherited Last);
end;

function TACLTreeListNodeList.IsChild(ANode: TACLTreeListNode): Boolean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if TACLTreeListNode(List[I]).IsChild(ANode) then
      Exit(True);
  end;
  Result := False;
end;

function TACLTreeListNodeList.IsValid(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Count);
end;

function TACLTreeListNodeList.GetCheckState: TCheckBoxState;
var
  AHasChecked, AHasUnchecked: Boolean;
begin
  GetCheckUncheckInfo(AHasChecked, AHasUnchecked);
  if AHasChecked and AHasUnchecked then
    Result := cbGrayed
  else
    if AHasChecked then
      Result := cbChecked
    else
      Result := cbUnchecked;
end;

function TACLTreeListNodeList.GetItem(Index: Integer): TACLTreeListNode;
begin
  Result := TACLTreeListNode(inherited Items[Index]);
end;

procedure TACLTreeListNodeList.SetCheckState(AValue: TCheckBoxState);
var
  AItem: TACLTreeListNode;
  AOwner: IACLTreeList;
  I: Integer;
begin
  if (AValue <> cbGrayed) and (Count > 0) then
  begin
    AOwner := First.TreeList;
    AOwner.BeginUpdate;
    try
      for I := Count - 1 downto 0 do
      begin
        AItem := Items[I];
        if AItem.CanCheck then
          AItem.Checked := AValue = cbChecked;
      end;
    finally
      AOwner.EndUpdate;
    end;
  end;
end;

{ TACLTreeListNodesDataEnumerator<T> }

constructor TACLTreeListNodesDataEnumerator<T>.Create(AList: TACLTreeListNodeList);
begin
  FList := AList;
  FIndex := -1;
end;

function TACLTreeListNodesDataEnumerator<T>.GetCurrent: T;
begin
  Result := FList[FIndex].Data;
end;

function TACLTreeListNodesDataEnumerator<T>.GetEnumerator: IACLEnumerator<T>;
begin
  Result := Self;
end;

function TACLTreeListNodesDataEnumerator<T>.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := (FList <> nil) and InRange(FIndex, 0, FList.Count - 1);
end;

end.
