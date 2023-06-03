{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Object Inspector              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.ObjectInspector;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Types,
  System.TypInfo,
  System.Variants,
  System.Classes,
  System.Generics.Collections,
  // VCL
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.ImgList,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Expressions.Math,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Graphics,
  ACL.MUI,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.ObjectInspector.PropertyEditors,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Controls.SearchBox,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.Options,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.RTTI,
  ACL.Utils.Strings;

const
  obhtButton = tlhtLast + 1;

type
  TACLObjectInspectorNode = class;
  TACLObjectInspectorSubClass = class;

  TACLObjectInspectorPropertyAddEvent = procedure (Sender: TObject;
    AObject: TObject; APropInfo: PPropInfo; var AAllow: Boolean) of object;
  TACLObjectInspectorPropertyChangedEvent = procedure (Sender: TObject;
    AObject: TObject; APropInfo: PPropInfo; AProperty: TACLPropertyEditor) of object;
  TACLObjectInspectorPropertyChangingEvent = procedure (Sender: TObject; AObject: TObject;
    APropInfo: PPropInfo; AProperty: TACLPropertyEditor; const AValue: Variant; var AAllow: Boolean) of object;
  TACLObjectInspectorPropertyGetGroupNameEvent = procedure (
    Sender: TObject; Node: TACLObjectInspectorNode; var GroupName: string) of object;

  { TACLObjectInspectorExpandedNodes }

  TACLObjectInspectorExpandedNodes = class
  strict private
    FMap: TObjectDictionary<TClass, TACLStringList>;
    FTreeList: TACLObjectInspectorSubClass;
  public
    constructor Create(ATreeList: TACLObjectInspectorSubClass);
    destructor Destroy; override;
    function IsExpanded(ANode: TACLTreeListNode): Boolean;
    procedure Store;
  end;

  { TACLObjectInspectorNode }

  TACLObjectInspectorNode = class(TACLTreeListStringNode)
  protected
    FPropertyEditor: TACLPropertyEditor;

    function GetValue(Index: Integer): string; override;
    function GetValuesCount: Integer; override;
    procedure SetValue(Index: Integer; const S: string); override;
  public
    destructor Destroy; override;
    procedure Edit;
    //
    property PropertyEditor: TACLPropertyEditor read FPropertyEditor;
  end;

  { TACLObjectInspectorOptionsBehavior }

  TACLObjectInspectorOptionsBehavior = class(TACLTreeListCustomOptions)
  strict private
    FAllowExpressions: Boolean;
  protected
    procedure DoAssign(Source: TPersistent); override;
  published
    property AllowExpressions: Boolean read FAllowExpressions write FAllowExpressions default False;
  end;

  { TACLObjectInspectorOptionsView }

  TACLObjectInspectorOptionsView = class(TACLTreeListCustomOptions)
  strict private
    FHighlightNonStorableProperties: Boolean;

    procedure SetHighlightNonStorableProperties(const Value: Boolean);
  protected
    procedure DoAssign(Source: TPersistent); override;
  public
    procedure AfterConstruction; override;
  published
    property HighlightNonStorableProperties: Boolean read FHighlightNonStorableProperties write SetHighlightNonStorableProperties default True;
  end;

  { TACLObjectInspectorSubClass }

  TACLObjectInspectorSubClass = class(TACLTreeListSubClass,
    IACLObjectInspector,
    IACLObjectInspectorStyleSet)
  strict private
    FExpandedNodes: TACLObjectInspectorExpandedNodes;
    FInspectedObject: TComponent;
    FOptionsBehavior: TACLObjectInspectorOptionsBehavior;
    FOptionsView: TACLObjectInspectorOptionsView;
    FSearchString: string;
    FStyleHatch: TACLStyleHatch;

    FOnPopulated: TNotifyEvent;
    FOnPropertyAdd: TACLObjectInspectorPropertyAddEvent;
    FOnPropertyChanged: TACLObjectInspectorPropertyChangedEvent;
    FOnPropertyChanging: TACLObjectInspectorPropertyChangingEvent;
    FOnPropertyGetGroupName: TACLObjectInspectorPropertyGetGroupNameEvent;

    function AddProperty(AParent: TACLTreeListNode; AEditor: TACLPropertyEditor): TACLObjectInspectorNode;
    procedure ApplyFilter(const S: string);
    procedure LoadObject(AObject: TObject; AParentNode: TACLTreeListNode);
    procedure LoadObjectProperty(APropInfo: PPropInfo; AObject: TObject; AParentNode: TACLTreeListNode);
    procedure HandlerGetGroupName(Sender: TObject; ANode: TACLTreeListNode; var AGroupName: string);
    function GetFocusedNode: TACLObjectInspectorNode;
    procedure SetFocusedNode(const Value: TACLObjectInspectorNode);
    procedure SetInspectedObject(const Value: TComponent);
    procedure SetSearchString(const Value: string);
  protected
    function CanAddProperty(AObject: TObject; APropInfo: PPropInfo): Boolean;
    function CreateEditingController: TACLTreeListEditingController; override;
    function CreateNode: TACLTreeListNode; override;
    function CreateViewInfo: TACLCompoundControlCustomViewInfo; override;

    function CanStartEditingByMouse(AButton: TMouseButton): Boolean;
    procedure ProcessKeyDown(AKey: Word; AShift: TShiftState); override;
    procedure ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseClickAtNodeButton(ANode: TACLTreeListNode);
    procedure ProcessMouseDblClick(AButton: TMouseButton; AShift: TShiftState); override;

    // IACLObjectInspector
    function GetInspectedObject: TPersistent;
    function PropertyChanging(AEditor: TACLPropertyEditor; const AValue: Variant): Boolean;
    procedure PropertyChanged(AEditor: TACLPropertyEditor);

    // IACLObjectInspectorStyleSet
    function GetStyle: TACLStyleTreeList;
    function GetStyleInplaceEdit: TACLStyleEdit;
    function GetStyleHatch: TACLStyleHatch;

    function DoEditCreate(const AParams: TACLInplaceInfo): TComponent; overload; override;
    function DoEditCreate(const AParams: TACLInplaceInfo; AEditor: TACLPropertyEditor): TComponent; reintroduce; overload;
    procedure ShowExternalDialogHandler(Sender: TObject);

    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function FindItem(const AProperyName: UnicodeString): TACLObjectInspectorNode;
    procedure ExecutePropertyEditor(const AProperyName: UnicodeString);
    procedure Regroup;
    procedure ReloadProperties;
    //
    property FocusedNode: TACLObjectInspectorNode read GetFocusedNode write SetFocusedNode;
    property InspectedObject: TComponent read FInspectedObject write SetInspectedObject;
    property OptionsBehavior: TACLObjectInspectorOptionsBehavior read FOptionsBehavior;
    property OptionsView: TACLObjectInspectorOptionsView read FOptionsView;
    property SearchString: string read FSearchString write SetSearchString;
    //
    property StyleHatch: TACLStyleHatch read FStyleHatch;
    //
    property OnPopulated: TNotifyEvent read FOnPopulated write FOnPopulated;
    property OnPropertyAdd: TACLObjectInspectorPropertyAddEvent read FOnPropertyAdd write FOnPropertyAdd;
    property OnPropertyChanging: TACLObjectInspectorPropertyChangingEvent read FOnPropertyChanging write FOnPropertyChanging;
    property OnPropertyChanged: TACLObjectInspectorPropertyChangedEvent read FOnPropertyChanged write FOnPropertyChanged;
    property OnPropertyGetGroupName: TACLObjectInspectorPropertyGetGroupNameEvent read FOnPropertyGetGroupName write FOnPropertyGetGroupName;
  end;

  { TACLObjectInspectorEditingController }

  TACLObjectInspectorEditingController = class(TACLTreeListEditingController)
  strict private
    FIsKeyboardAction: Boolean;
  protected
    procedure EditApplyHandler(Sender: TObject); override;
    procedure EditKeyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState); override;
  end;

  { TACLObjectInspectorContentViewInfo }

  TACLObjectInspectorContentViewInfo = class(TACLTreeListContentViewInfo)
  protected
    function CreateNodeViewInfo: TACLTreeListNodeViewInfo; override;
  end;

  { TACLObjectInspectorNodeViewInfo }

  TACLObjectInspectorNodeViewInfo = class(TACLTreeListNodeViewInfo)
  strict private
    FButtonRect: TRect;
    FLastCellTextExtends: TRect;

    function GetNode: TACLObjectInspectorNode;
    function GetOptionsView: TACLObjectInspectorOptionsView;
  protected
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure DoDrawCellContent(ACanvas: TCanvas; const R: TRect; AColumnViewInfo: TACLTreeListColumnViewInfo); override;
    procedure DoGetHitTest(const P: TPoint; const AOrigin: TPoint; AInfo: TACLHitTestInfo); override;
    function GetCellTextExtends(AColumn: TACLTreeListColumnViewInfo): TRect; override;
    function HasButton: Boolean; virtual;
  public
    procedure Calculate(AWidth: Integer; AHeight: Integer); override;
    //
    property ButtonRect: TRect read FButtonRect;
    property Node: TACLObjectInspectorNode read GetNode;
    property OptionsView: TACLObjectInspectorOptionsView read GetOptionsView;
  end;

  { TACLObjectInspectorViewInfo }

  TACLObjectInspectorViewInfo = class(TACLTreeListViewInfo)
  protected
    function CreateContent: TACLTreeListContentViewInfo; override;
  end;

  { TACLObjectInspectorControl }

  TACLObjectInspectorControl = class(TACLCustomTreeList)
  strict private
    function GetSubClass: TACLObjectInspectorSubClass;
  protected
    function CreateSubClass: TACLCompoundControlSubClass; override;
  public
    property SubClass: TACLObjectInspectorSubClass read GetSubClass;
  end;

  { TACLObjectInspectorExpressionEdit }

  TACLObjectInspectorExpressionEdit = class(TACLEdit)
  strict private
    function Evaluate(const AText: string): Variant;
    function IsExpressionMode: Boolean;
  protected
    procedure EditorUpdateParamsCore; override;
    function TextToValue(const AText: string): Variant; override;
    function ValueToText(const AValue: Variant): string; override;
  end;

  { TACLObjectInspector }

  TACLObjectInspector = class(TACLContainer)
  strict private
    FInnerControl: TACLObjectInspectorControl;
    FSearchEdit: TACLSearchEdit;

    FOnKeyDown: TKeyEvent;

    function GetFocusedNode: TACLObjectInspectorNode;
    function GetInspectedObject: TComponent;
    function GetOnKeyPress: TKeyPressEvent;
    function GetOnKeyUp: TKeyEvent;
    function GetOnMouseDown: TMouseEvent;
    function GetOnMouseMove: TMouseMoveEvent;
    function GetOnMouseUp: TMouseEvent;
    function GetOnPopulated: TNotifyEvent;
    function GetOnPropertyAdd: TACLObjectInspectorPropertyAddEvent;
    function GetOnPropertyChanged: TACLObjectInspectorPropertyChangedEvent;
    function GetOnPropertyChanging: TACLObjectInspectorPropertyChangingEvent;
    function GetOnPropertyGetGroupName: TACLObjectInspectorPropertyGetGroupNameEvent;
    function GetOptionsBehavior: TACLObjectInspectorOptionsBehavior;
    function GetOptionsView: TACLObjectInspectorOptionsView;
    function GetSearchBox: Boolean;
    function GetSearchBoxTextHint: string;
    function GetSearchString: string;
    function GetStyleInplaceEdit: TACLStyleEdit;
    function GetStyleInplaceEditButton: TACLStyleEditButton;
    function GetStyleHatch: TACLStyleHatch;
    function GetStyleScrollBox: TACLStyleScrollBox;
    function GetStyleSearchEdit: TACLStyleEdit;
    function GetStyleSearchEditButton: TACLStyleButton;
    function GetStyle: TACLStyleTreeList;
    function GetSubClass: TACLObjectInspectorSubClass;
    procedure SetFocusedNode(const Value: TACLObjectInspectorNode);
    procedure SetInspectedObject(const Value: TComponent);
    procedure SetOnKeyPress(const Value: TKeyPressEvent);
    procedure SetOnKeyUp(const Value: TKeyEvent);
    procedure SetOnMouseDown(const Value: TMouseEvent);
    procedure SetOnMouseMove(const Value: TMouseMoveEvent);
    procedure SetOnMouseUp(const Value: TMouseEvent);
    procedure SetOnPopulated(const Value: TNotifyEvent);
    procedure SetOnPropertyAdd(const Value: TACLObjectInspectorPropertyAddEvent);
    procedure SetOnPropertyChanged(const Value: TACLObjectInspectorPropertyChangedEvent);
    procedure SetOnPropertyChanging(const Value: TACLObjectInspectorPropertyChangingEvent);
    procedure SetOnPropertyGetGroupName(const Value: TACLObjectInspectorPropertyGetGroupNameEvent);
    procedure SetOptionsBehavior(const Value: TACLObjectInspectorOptionsBehavior);
    procedure SetOptionsView(const Value: TACLObjectInspectorOptionsView);
    procedure SetSearchBox(const Value: Boolean);
    procedure SetSearchBoxTextHint(const Value: string);
    procedure SetSearchString(const Value: string);
    procedure SetStyleInplaceEdit(const Value: TACLStyleEdit);
    procedure SetStyleInplaceEditButton(const Value: TACLStyleEditButton);
    procedure SetStyleHatch(const Value: TACLStyleHatch);
    procedure SetStyleScrollBox(const Value: TACLStyleScrollBox);
    procedure SetStyleSearchEdit(const Value: TACLStyleEdit);
    procedure SetStyleSearchEditButton(const Value: TACLStyleButton);
    procedure SetStyle(const Value: TACLStyleTreeList);
    //
    procedure InnerControlKeyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SearchBoxChangeHandler(Sender: TObject);
  protected
    procedure ResourceCollectionChanged; override;
    procedure SetDefaultSize; override;
    procedure CMChildKey(var Message: TCMChildKey); message CM_CHILDKEY;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ConfigLoad(AConfig: TACLIniFile; const ASection, AItem: UnicodeString); inline;
    procedure ConfigSave(AConfig: TACLIniFile; const ASection, AItem: UnicodeString); inline;
    procedure ExecutePropertyEditor(const AProperyName: UnicodeString);
    function FindItem(const AProperyName: UnicodeString): TACLObjectInspectorNode;
    procedure Localize(const ASection: string); override;
    procedure ReloadData;
    //
    property FocusedNode: TACLObjectInspectorNode read GetFocusedNode write SetFocusedNode;
    property InnerControl: TACLObjectInspectorControl read FInnerControl;
    property SearchString: string read GetSearchString write SetSearchString;
    property SubClass: TACLObjectInspectorSubClass read GetSubClass;
  published
    property Borders default [];
    property InspectedObject: TComponent read GetInspectedObject write SetInspectedObject;
    property OptionsBehavior: TACLObjectInspectorOptionsBehavior read GetOptionsBehavior write SetOptionsBehavior;
    property OptionsView: TACLObjectInspectorOptionsView read GetOptionsView write SetOptionsView;
    property SearchBox: Boolean read GetSearchBox write SetSearchBox default False;
    property SearchBoxTextHint: string read GetSearchBoxTextHint write SetSearchBoxTextHint;
    //
    property Style: TACLStyleTreeList read GetStyle write SetStyle;
    property StyleHatch: TACLStyleHatch read GetStyleHatch write SetStyleHatch;
    property StyleInplaceEdit: TACLStyleEdit read GetStyleInplaceEdit write SetStyleInplaceEdit;
    property StyleInplaceEditButton: TACLStyleEditButton read GetStyleInplaceEditButton write SetStyleInplaceEditButton;
    property StyleScrollBox: TACLStyleScrollBox read GetStyleScrollBox write SetStyleScrollBox;
    property StyleSearchEdit: TACLStyleEdit read GetStyleSearchEdit write SetStyleSearchEdit;
    property StyleSearchEditButton: TACLStyleButton read GetStyleSearchEditButton write SetStyleSearchEditButton;
    //
    property OnPopulated: TNotifyEvent read GetOnPopulated write SetOnPopulated;
    property OnPropertyAdd: TACLObjectInspectorPropertyAddEvent read GetOnPropertyAdd write SetOnPropertyAdd;
    property OnPropertyChanged: TACLObjectInspectorPropertyChangedEvent read GetOnPropertyChanged write SetOnPropertyChanged;
    property OnPropertyChanging: TACLObjectInspectorPropertyChangingEvent read GetOnPropertyChanging write SetOnPropertyChanging;
    property OnPropertyGetGroupName: TACLObjectInspectorPropertyGetGroupNameEvent read GetOnPropertyGetGroupName write SetOnPropertyGetGroupName;
    property OnKeyDown: TKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnKeyPress: TKeyPressEvent read GetOnKeyPress write SetOnKeyPress;
    property OnKeyUp: TKeyEvent read GetOnKeyUp write SetOnKeyUp;
    property OnMouseDown: TMouseEvent read GetOnMouseDown write SetOnMouseDown;
    property OnMouseMove: TMouseMoveEvent read GetOnMouseMove write SetOnMouseMove;
    property OnMouseUp: TMouseEvent read GetOnMouseUp write SetOnMouseUp;
  end;

implementation

uses
  System.SysUtils,
  // VCL
  Vcl.Forms;

type
  TACLPropertyEditorAccess = class(TACLPropertyEditor);
  TACLCustomTextEditAccess = class(TACLCustomTextEdit);

function ExtractPropertyName(const S: UnicodeString): UnicodeString;
begin
  Result := Copy(S, acLastDelimiter('.', S) + 1, MaxInt);
end;

{ TACLObjectInspectorExpandedNodes }

constructor TACLObjectInspectorExpandedNodes.Create(ATreeList: TACLObjectInspectorSubClass);
begin
  inherited Create;
  FMap := TObjectDictionary<TClass, TACLStringList>.Create([doOwnsValues]);
  FTreeList := ATreeList;
end;

destructor TACLObjectInspectorExpandedNodes.Destroy;
begin
  FreeAndNil(FMap);
  inherited Destroy;
end;

function TACLObjectInspectorExpandedNodes.IsExpanded(ANode: TACLTreeListNode): Boolean;
var
  AValue: TACLStringList;
begin
  if FMap.TryGetValue(FTreeList.InspectedObject.ClassType, AValue) then
    Result := AValue.IndexOf(FTreeList.GetPath(ANode)) >= 0
  else
    Result := False;
end;

procedure TACLObjectInspectorExpandedNodes.Store;

  procedure Store(AValues: TACLStringList; ANode: TACLTreeListNode);
  var
    APath: UnicodeString;
    I: Integer;
  begin
    if ANode.Expanded then
    begin
      APath := FTreeList.GetPath(ANode);
      if AValues.IndexOf(APath) < 0 then
        AValues.Add(APath);
      for I := 0 to ANode.ChildrenCount - 1 do
        Store(AValues, ANode.Children[I]);
    end;
  end;

var
  AValues: TACLStringList;
begin
  if FTreeList.InspectedObject <> nil then
  begin
    AValues := TACLStringList.Create;
    FMap.AddOrSetValue(FTreeList.InspectedObject.ClassType, AValues);
    Store(AValues, FTreeList.RootNode);
  end;
end;

{ TACLObjectInspectorNode }

destructor TACLObjectInspectorNode.Destroy;
begin
  FreeAndNil(FPropertyEditor);
  inherited Destroy;
end;

procedure TACLObjectInspectorNode.Edit;
var
  AIntf: IACLPropertyEditorDialog;
begin
  if Supports(PropertyEditor, IACLPropertyEditorDialog, AIntf) then
    AIntf.Edit;
end;

function TACLObjectInspectorNode.GetValue(Index: Integer): string;
begin
  if PropertyEditor = nil then
    Result := inherited GetValue(Index)
  else
    if Index = 0 then
      Result := ExtractPropertyName(PropertyEditor.Name)
    else
      Result := PropertyEditor.Value;
end;

function TACLObjectInspectorNode.GetValuesCount: Integer;
begin
  if PropertyEditor <> nil then
    Result := 2
  else
    Result := inherited GetValuesCount;
end;

procedure TACLObjectInspectorNode.SetValue(Index: Integer; const S: string);
begin
  if PropertyEditor = nil then
    inherited SetValue(Index, S)
  else
    if Index = 1 then
      PropertyEditor.Value := S;
end;

{ TACLObjectInspectorOptionsBehavior }

procedure TACLObjectInspectorOptionsBehavior.DoAssign(Source: TPersistent);
begin
  inherited;
  if Source is TACLObjectInspectorOptionsBehavior then
    AllowExpressions := TACLObjectInspectorOptionsBehavior(Source).AllowExpressions;
end;

{ TACLObjectInspectorOptionsView }

procedure TACLObjectInspectorOptionsView.AfterConstruction;
begin
  inherited;
  FHighlightNonStorableProperties := True;
end;

procedure TACLObjectInspectorOptionsView.DoAssign(Source: TPersistent);
begin
  inherited;
  if Source is TACLObjectInspectorOptionsView then
    HighlightNonStorableProperties := TACLObjectInspectorOptionsView(Source).HighlightNonStorableProperties;
end;

procedure TACLObjectInspectorOptionsView.SetHighlightNonStorableProperties(const Value: Boolean);
begin
  SetBooleanFieldValue(FHighlightNonStorableProperties, Value, [apcContent]);
end;

{ TACLObjectInspectorSubClass }

constructor TACLObjectInspectorSubClass.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStyleHatch := TACLStyleHatch.Create(Self);
  FOptionsBehavior := TACLObjectInspectorOptionsBehavior.Create(Self);
  FOptionsView := TACLObjectInspectorOptionsView.Create(Self);
  FExpandedNodes := TACLObjectInspectorExpandedNodes.Create(Self);

  inherited OptionsBehavior.CellHints := True;
  inherited OptionsBehavior.Editing := True;
  inherited OptionsView.Columns.AutoWidth := True;

  OnGetNodeGroup := HandlerGetGroupName;

  Columns.Add;
  Columns.Add;

  SortBy(Columns[0], sdAscending);
end;

destructor TACLObjectInspectorSubClass.Destroy;
begin
  InspectedObject := nil;
  FreeAndNil(FStyleHatch);
  FreeAndNil(FExpandedNodes);
  FreeAndNil(FOptionsBehavior);
  FreeAndNil(FOptionsView);
  inherited Destroy;
end;

function TACLObjectInspectorSubClass.FindItem(const AProperyName: UnicodeString): TACLObjectInspectorNode;
var
  AArr: TStringDynArray;
  ALast: TACLTreeListNode;
  I: Integer;
begin
  acExplodeString(AProperyName, '.', AArr);
  if Length(AArr) = 0 then
    Exit(nil);

  ALast := RootNode;
  for I := 0 to Length(AArr) - 1 do
  begin
    ALast.ChildrenNeeded;
    if not ALast.Find(ALast, AArr[I], 0, False) then
      Exit(nil);
  end;
  Result := TACLObjectInspectorNode(ALast);
end;

procedure TACLObjectInspectorSubClass.ExecutePropertyEditor(const AProperyName: UnicodeString);
var
  AItem: TACLObjectInspectorNode;
begin
  AItem := FindItem(AProperyName);
  if AItem <> nil then
    AItem.Edit;
end;

procedure TACLObjectInspectorSubClass.Regroup;
begin
  BeginUpdate;
  try
    inherited OptionsBehavior.Groups := True;
    inherited Regroup;
    Groups.Validate;
    inherited OptionsBehavior.Groups := Groups.Count > 1;
  finally
    EndUpdate;
  end;
end;

procedure TACLObjectInspectorSubClass.ReloadProperties;
begin
  BeginUpdate;
  try
    Clear;
    if InspectedObject <> nil then
    begin
      LoadObject(InspectedObject, RootNode);
      if SearchString <> '' then
        ApplyFilter(SearchString);
      Regroup;
    end;
  finally
    EndUpdate;
  end;
  if not IsDestroying then
    CallNotifyEvent(Self, OnPopulated);
end;

function TACLObjectInspectorSubClass.CanAddProperty(AObject: TObject; APropInfo: PPropInfo): Boolean;
begin
  Result := True;
  if Assigned(OnPropertyAdd) then
    OnPropertyAdd(Self, AObject, APropInfo, Result);
end;

function TACLObjectInspectorSubClass.CreateEditingController: TACLTreeListEditingController;
begin
  Result := TACLObjectInspectorEditingController.Create(Self);
end;

function TACLObjectInspectorSubClass.CreateNode: TACLTreeListNode;
begin
  Result := TACLObjectInspectorNode.Create(Self);
end;

function TACLObjectInspectorSubClass.CreateViewInfo: TACLCompoundControlCustomViewInfo;
begin
  Result := TACLObjectInspectorViewInfo.Create(Self);
end;

function TACLObjectInspectorSubClass.GetStyle: TACLStyleTreeList;
begin
  Result := Style;
end;

function TACLObjectInspectorSubClass.GetStyleInplaceEdit: TACLStyleEdit;
begin
  Result := StyleInplaceEdit;
end;

function TACLObjectInspectorSubClass.GetStyleHatch: TACLStyleHatch;
begin
  Result := FStyleHatch;
end;

function TACLObjectInspectorSubClass.DoEditCreate(const AParams: TACLInplaceInfo): TComponent;
begin
  if (AParams.ColumnIndex = 1) and (FocusedNode <> nil) and (FocusedNode.PropertyEditor <> nil) then
    Result := DoEditCreate(AParams, FocusedNode.PropertyEditor)
  else
    Result := nil;
end;

function TACLObjectInspectorSubClass.DoEditCreate(const AParams: TACLInplaceInfo; AEditor: TACLPropertyEditor): TComponent;

  function CreateEdit(AMask: TACLEditInputMask): TACLEdit;
  begin
    if OptionsBehavior.AllowExpressions then
      Result := TACLObjectInspectorExpressionEdit.CreateInplace(AParams)
    else
      Result := TACLEdit.CreateInplace(AParams);

    Result.ResourceCollection := ResourceCollection;
    Result.ReadOnly := AEditor.IsReadOnly;
    Result.Style := StyleInplaceEdit;
    Result.StyleButton := StyleInplaceEditButton;
    Result.InputMask := AMask;
    Result.Value := AEditor.Value;
  end;

var
  ADialogIntf: IACLPropertyEditorDialog;
  AEditBoxIntf: IACLPropertyEditorCustomEditBox;
  AValueList: IACLPropertyEditorValueList;
  AValues: TACLStringList;
begin
  Result := nil;
  if peaEditBox in AEditor.Attributes then
  begin
    if Supports(AEditor, IACLPropertyEditorCustomEditBox, AEditBoxIntf) then
      Result := AEditBoxIntf.CreateEditBox(AParams)
    else

    if Supports(AEditor, IACLPropertyEditorValueList, AValueList) then
    begin
      Result := TACLComboBox.CreateInplace(AParams);
      TACLComboBox(Result).ReadOnly := AEditor.IsReadOnly;
      TACLComboBox(Result).Style := StyleInplaceEdit;
      TACLComboBox(Result).StyleButton := StyleInplaceEditButton;
      TACLComboBox(Result).StyleDropDownList := Style;
      TACLComboBox(Result).StyleDropDownListScrollBox := StyleScrollBox;

      AValues := TACLStringList.Create;
      try
        AValueList.GetValues(AValues);
        TACLComboBox(Result).Items.Assign(AValues);
        TACLComboBox(Result).ItemIndex := AValues.IndexOf(AEditor.Value);
      finally
        AValues.Free;
      end;
    end
    else

    case AEditor.Info.PropType^^.Kind of
      tkString, tkUString, tkWString, tkLString, tkVariant:
        Result := CreateEdit(eimText);
      tkInteger, tkInt64:
        Result := CreateEdit(eimInteger);
      tkFloat:
        Result := CreateEdit(eimFloat);
    end;

    if Supports(AEditor, IACLPropertyEditorDialog, ADialogIntf) and (Result is TACLCustomTextEdit) then
      TACLCustomTextEditAccess(Result).Buttons.Add(acEndEllipsis).OnClick := ShowExternalDialogHandler;
  end;
end;

procedure TACLObjectInspectorSubClass.PropertyChanged(AEditor: TACLPropertyEditor);
begin
  if Assigned(OnPropertyChanged) then
    OnPropertyChanged(Self, AEditor.Owner, AEditor.Info, AEditor);
  Invalidate;
end;

function TACLObjectInspectorSubClass.GetInspectedObject: TPersistent;
begin
  Result := InspectedObject;
end;

function TACLObjectInspectorSubClass.PropertyChanging(AEditor: TACLPropertyEditor; const AValue: Variant): Boolean;
begin
  Result := True;
  if Assigned(OnPropertyChanging) then
    OnPropertyChanging(Self, AEditor.Owner, AEditor.Info, AEditor, AValue, Result);
end;

procedure TACLObjectInspectorSubClass.ShowExternalDialogHandler(Sender: TObject);
begin
  FocusedNode.Edit;
  EditingController.Cancel;
end;

procedure TACLObjectInspectorSubClass.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);

  if AOperation = opRemove then
  begin
    if AComponent = InspectedObject then
      InspectedObject := nil;
  end;
end;

function TACLObjectInspectorSubClass.AddProperty(AParent: TACLTreeListNode; AEditor: TACLPropertyEditor): TACLObjectInspectorNode;

  function FullName(ANode: TACLTreeListNode): string;
  begin
    Result := '';
    while ANode.Parent <> nil do
    begin
      Result := ANode.Caption + IfThenW(Result <> '', '.') + Result;
      ANode := ANode.Parent;
    end;
  end;

begin
  Result := TACLObjectInspectorNode(AParent.AddChild);
  Result.FPropertyEditor := AEditor;
  TACLPropertyEditorAccess(Result.FPropertyEditor).FFullName := FullName(Result);
  Result.Expanded := FExpandedNodes.IsExpanded(Result);
end;

procedure TACLObjectInspectorSubClass.ApplyFilter(const S: string);

  function Check(ANode: TACLTreeListNode; ASearchString: TACLSearchString): Boolean;
  begin
    Result :=
      ASearchString.Compare(ANode.Values[0]) or
      ASearchString.Compare(ANode.Values[1]);
  end;

  procedure ProcessLevel(AParentNode: TACLTreeListNode; ASearchString: TACLSearchString);
  var
    ANode: TACLTreeListNode;
    I: Integer;
  begin
    for I := AParentNode.ChildrenCount - 1 downto 0 do
    begin
      ANode := AParentNode.Children[I];
      if not Check(ANode, ASearchString) then
      begin
        ProcessLevel(ANode, ASearchString);
        ANode.Expanded := True;
        if ANode.ChildrenCount = 0 then
          ANode.Free;
      end;
    end;
  end;

var
  ASearchString: TACLSearchString;
begin
  ASearchString := TACLSearchString.Create(S);
  try
    ProcessLevel(RootNode, ASearchString);
  finally
    ASearchString.Free;
  end;
end;

procedure TACLObjectInspectorSubClass.LoadObject(AObject: TObject; AParentNode: TACLTreeListNode);
var
  ACount: Integer;
  AList: PPropList;
  I: Integer;
begin
  if TRTTI.GetProperties(AObject, AList, ACount) then
  try
    for I := 0 to ACount - 1 do
      LoadObjectProperty(AList[I], AObject, AParentNode);
  finally
    FreeMemAndNil(Pointer(AList));
  end;
end;

procedure TACLObjectInspectorSubClass.LoadObjectProperty(
  APropInfo: PPropInfo; AObject: TObject; AParentNode: TACLTreeListNode);
var
  AEditorClass: TACLPropertyEditorClass;
  AIntf: IACLPropertyEditorSubProperties;
  ANode: TACLObjectInspectorNode;
begin
  AEditorClass := TACLPropertyEditors.GetEditorClass(APropInfo, AObject);
  if (AEditorClass <> nil) and CanAddProperty(AObject, APropInfo) then
  begin
    ANode := AddProperty(AParentNode, AEditorClass.Create(APropInfo, AObject, Self));
    if Supports(ANode.PropertyEditor, IACLPropertyEditorSubProperties, AIntf) then
    begin
      AIntf.GetProperties(
        procedure (AEditor: TACLPropertyEditor)
        begin
          AddProperty(ANode, AEditor);
        end);
    end
    else
      if APropInfo.PropType^^.Kind = tkClass then
      begin
        AObject := GetObjectProp(AObject, APropInfo);
        if (AObject <> nil) and not (AObject is TComponent) then
          LoadObject(AObject, ANode);
      end;
  end;
end;

procedure TACLObjectInspectorSubClass.HandlerGetGroupName(
  Sender: TObject; ANode: TACLTreeListNode; var AGroupName: string);
begin
  if Assigned(OnPropertyGetGroupName) then
    OnPropertyGetGroupName(Sender, TACLObjectInspectorNode(ANode), AGroupName);
end;

function TACLObjectInspectorSubClass.GetFocusedNode: TACLObjectInspectorNode;
begin
  Result := TACLObjectInspectorNode(inherited FocusedNode)
end;

procedure TACLObjectInspectorSubClass.SetFocusedNode(const Value: TACLObjectInspectorNode);
begin
  inherited FocusedNode := Value;
end;

procedure TACLObjectInspectorSubClass.SetInspectedObject(const Value: TComponent);
begin
  if Value <> FInspectedObject then
  begin
    FExpandedNodes.Store;
    if acComponentFieldSet(FInspectedObject, Self, Value) then
      ReloadProperties;
  end;
end;

procedure TACLObjectInspectorSubClass.SetSearchString(const Value: string);
begin
  if FSearchString <> Value then
  begin
    FSearchString := Value;
    ReloadProperties;
  end;
end;

function TACLObjectInspectorSubClass.CanStartEditingByMouse(AButton: TMouseButton): Boolean;
begin
  Result := (AButton = mbLeft) and HitTest.HitAtNode and not HitTest.HasAction;
end;

procedure TACLObjectInspectorSubClass.ProcessKeyDown(AKey: Word; AShift: TShiftState);
const
  Modifiers = [ssAlt, ssCtrl, ssShift];
begin
  inherited ProcessKeyDown(AKey, AShift);
  if FocusedNode <> nil then
    case AKey of
      VK_RETURN:
        begin
          StartEditing(FocusedNode, Columns[1]);
          if not EditingController.IsEditing then
            TACLObjectInspectorNode(FocusedNode).Edit;
        end;
    end;
end;

procedure TACLObjectInspectorSubClass.ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState);
var
  AInplaceControl: TWinControl;
  AInplaceControlPoint: TPoint;
begin
  if HitTest.HitObjectFlags[obhtButton] then
    ProcessMouseClickAtNodeButton(HitTest.Node)
  else
    if CanStartEditingByMouse(AButton) then
    begin
      EditingController.StartEditing(HitTest.Node, Columns[1]);
      if EditingController.Edit is TWinControl then
      begin
        AInplaceControl := TWinControl(EditingController.Edit);
        AInplaceControlPoint := AInplaceControl.ScreenToClient(Mouse.CursorPos);
        if PtInRect(AInplaceControl.ClientRect, AInplaceControlPoint) then
        begin
          PostMessage(AInplaceControl.Handle, WM_LBUTTONDOWN, acShiftStateToKeys(AShift), PointToLParam(AInplaceControlPoint));
          PostMessage(AInplaceControl.Handle, WM_LBUTTONUP, acShiftStateToKeys(AShift), PointToLParam(AInplaceControlPoint));
        end;
      end;
    end
    else
      inherited ProcessMouseClick(AButton, AShift);
end;

procedure TACLObjectInspectorSubClass.ProcessMouseClickAtNodeButton(ANode: TACLTreeListNode);
begin
  TACLObjectInspectorNode(ANode).Edit;
end;

procedure TACLObjectInspectorSubClass.ProcessMouseDblClick(AButton: TMouseButton; AShift: TShiftState);
begin
  inherited ProcessMouseDblClick(AButton, AShift);
  if CanStartEditingByMouse(AButton) and not EditingController.IsEditing and (HitTest.Node.ChildrenCount = 0) then
    ProcessMouseClickAtNodeButton(HitTest.Node)
end;

{ TACLObjectInspectorEditingController }

procedure TACLObjectInspectorEditingController.EditApplyHandler(Sender: TObject);
begin
  if not IsLocked and (Sender = Edit) then
  begin
    Value := EditIntf.InplaceGetValue;
    if IsEditing then
    begin
      EditIntf.InplaceSetValue(Value);
      if FIsKeyboardAction or not SubClass.Focused then
        Close;
    end;
  end;
end;

procedure TACLObjectInspectorEditingController.EditKeyDownHandler(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  FIsKeyboardAction := True;
  inherited;
  FIsKeyboardAction := False;
end;

{ TACLObjectInspectorContentViewInfo }

function TACLObjectInspectorContentViewInfo.CreateNodeViewInfo: TACLTreeListNodeViewInfo;
begin
  Result := TACLObjectInspectorNodeViewInfo.Create(Self);
end;

{ TACLObjectInspectorNodeViewInfo }

procedure TACLObjectInspectorNodeViewInfo.Calculate(AWidth, AHeight: Integer);
begin
  inherited Calculate(AWidth, AHeight);

  FButtonRect := acRectInflate(CellRect[CellCount - 1], -1);
  FButtonRect.Left := FButtonRect.Right - FButtonRect.Height;

  FLastCellTextExtends := FTextExtends[False];
  Inc(FLastCellTextExtends.Right, FButtonRect.Width);
end;

procedure TACLObjectInspectorNodeViewInfo.DoDraw(ACanvas: TCanvas);
begin
  inherited DoDraw(ACanvas);

  if HasButton then
  begin
    SubClass.StylePrepareFont(ACanvas);
    ACanvas.Font.Color := SubClass.StyleGetNodeTextColor(Node);
    SubClass.StyleInplaceEditButton.Draw(ACanvas.Handle, ButtonRect, absNormal);
    acTextDraw(ACanvas, acEndEllipsis, ButtonRect, taCenter, taVerticalCenter);
  end;
end;

procedure TACLObjectInspectorNodeViewInfo.DoDrawCellContent(
  ACanvas: TCanvas; const R: TRect; AColumnViewInfo: TACLTreeListColumnViewInfo);
var
  AIntf: IACLPropertyEditorCustomDraw;
begin
  if AColumnViewInfo.AbsoluteIndex = 1 then
  begin
    if SubClass.EditingController.IsEditing(Node) then
      Exit;
    if Supports(Node.PropertyEditor, IACLPropertyEditorCustomDraw, AIntf) then
    begin
      AIntf.Draw(ACanvas, R, acRectContent(R, CellTextExtends[AColumnViewInfo]));
      Exit;
    end;
    if not Node.PropertyEditor.HasData then
      ACanvas.Font.Color := SubClass.Style.RowColorDisabledText.AsColor;
  end;

  if Node.PropertyEditor.IsReadOnly or Node.PropertyEditor.IsNonStorable and OptionsView.HighlightNonStorableProperties then
    ACanvas.Font.Color := SubClass.Style.RowColorDisabledText.AsColor;

  inherited DoDrawCellContent(ACanvas, R, AColumnViewInfo);
end;

procedure TACLObjectInspectorNodeViewInfo.DoGetHitTest(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo);
begin
  inherited DoGetHitTest(P, AOrigin, AInfo);
  if HasButton and PtInRect(ButtonRect, P) then
  begin
    AInfo.HitObjectFlags[obhtButton] := True;
    AInfo.Cursor := crHandPoint;
  end;
end;

function TACLObjectInspectorNodeViewInfo.GetCellTextExtends(AColumn: TACLTreeListColumnViewInfo): TRect;
begin
  if ((AColumn = nil) or AColumn.IsLast) and HasButton then
    Result := FLastCellTextExtends
  else
    Result := inherited GetCellTextExtends(AColumn);
end;

function TACLObjectInspectorNodeViewInfo.HasButton: Boolean;
begin
  Result := (Node <> nil) and Node.Selected and Supports(Node.PropertyEditor, IACLPropertyEditorDialog);
end;

function TACLObjectInspectorNodeViewInfo.GetNode: TACLObjectInspectorNode;
begin
  Result := TACLObjectInspectorNode(inherited Node);
end;

function TACLObjectInspectorNodeViewInfo.GetOptionsView: TACLObjectInspectorOptionsView;
begin
  Result := TACLObjectInspectorSubClass(SubClass).OptionsView;
end;

{ TACLObjectInspectorViewInfo }

function TACLObjectInspectorViewInfo.CreateContent: TACLTreeListContentViewInfo;
begin
  Result := TACLObjectInspectorContentViewInfo.Create(SubClass);
end;

{ TACLObjectInspectorControl }

function TACLObjectInspectorControl.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLObjectInspectorSubClass.Create(Self);
end;

function TACLObjectInspectorControl.GetSubClass: TACLObjectInspectorSubClass;
begin
  Result := TACLObjectInspectorSubClass(inherited SubClass);
end;

{ TACLObjectInspectorExpressionEdit }

procedure TACLObjectInspectorExpressionEdit.EditorUpdateParamsCore;
begin
  Inc(FTextChangeLockCount);
  try
    inherited;
    if IsExpressionMode then
      InnerEdit.InputMask := eimText;
  finally
    Dec(FTextChangeLockCount);
  end;
end;

function TACLObjectInspectorExpressionEdit.Evaluate(const AText: string): Variant;
begin
  if AText <> '' then
    Result := TACLMathExpressionFactory.Instance.Evaluate(AText, nil)
  else
    Result := 0;
end;

function TACLObjectInspectorExpressionEdit.IsExpressionMode: Boolean;
begin
  Result := InputMask in [eimInteger, eimFloat];
end;

function TACLObjectInspectorExpressionEdit.TextToValue(const AText: string): Variant;
begin
  case InputMask of
    eimInteger:
      VarCast(Result, Evaluate(AText), varInteger);
    eimFloat:
      VarCast(Result, Evaluate(AText), varDouble);
  else
    Result := inherited;
  end;
end;

function TACLObjectInspectorExpressionEdit.ValueToText(const AValue: Variant): string;
begin
  if VarIsFloat(AValue) then
    Result := FloatToStr(AValue, InvariantFormatSettings)
  else
    Result := inherited;
end;

{ TACLObjectInspector }

constructor TACLObjectInspector.Create(AOwner: TComponent);
begin
  inherited;
  FInnerControl := TACLObjectInspectorControl.Create(Self);
  FInnerControl.Align := alClient;
  FInnerControl.Parent := Self;
  FInnerControl.OptionsBehavior.IncSearchColumnIndex := 0;
  FInnerControl.OnKeyDown := InnerControlKeyDownHandler;

  FSearchEdit := TACLSearchEdit.Create(Self);
  FSearchEdit.ControlStyle := FSearchEdit.ControlStyle + [csNoDesignVisible];
  FSearchEdit.Align := alTop;
  FSearchEdit.AlignWithMargins := True;
  FSearchEdit.Margins.All := 0;
  FSearchEdit.Margins.Bottom := 6;
  FSearchEdit.Parent := Self;
  FSearchEdit.FocusControl := FInnerControl;
  FSearchEdit.TabOrder := 0;
  FSearchEdit.OnChange := SearchBoxChangeHandler;
  FSearchEdit.Visible := False;

  Borders := [];
end;

procedure TACLObjectInspector.ResourceCollectionChanged;
begin
  FInnerControl.ResourceCollection := ResourceCollection;
  FSearchEdit.ResourceCollection := ResourceCollection;
  inherited;
end;

procedure TACLObjectInspector.SetDefaultSize;
begin
  SetBounds(0, 0, 200, 400);
end;

procedure TACLObjectInspector.CMChildKey(var Message: TCMChildKey);
begin
  if Message.CharCode = VK_F3 then
  begin
    InnerControlKeyDownHandler(Self, Message.CharCode, []);
    Message.Result := 1;
  end;
end;

procedure TACLObjectInspector.ConfigLoad(AConfig: TACLIniFile; const ASection, AItem: UnicodeString);
begin
  FInnerControl.ConfigLoad(AConfig, ASection, AItem);
end;

procedure TACLObjectInspector.ConfigSave(AConfig: TACLIniFile; const ASection, AItem: UnicodeString);
begin
  FInnerControl.ConfigSave(AConfig, ASection, AItem);
end;

function TACLObjectInspector.FindItem(const AProperyName: UnicodeString): TACLObjectInspectorNode;
begin
  Result := SubClass.FindItem(AProperyName);
end;

procedure TACLObjectInspector.Localize(const ASection: string);
begin
  inherited Localize(ASection);
  SearchBoxTextHint := LangGet(ASection, 'th');
end;

procedure TACLObjectInspector.ExecutePropertyEditor(const AProperyName: UnicodeString);
begin
  SubClass.ExecutePropertyEditor(AProperyName);
end;

procedure TACLObjectInspector.ReloadData;
begin
  SubClass.ReloadProperties;
end;

function TACLObjectInspector.GetFocusedNode: TACLObjectInspectorNode;
begin
  Result := SubClass.FocusedNode;
end;

function TACLObjectInspector.GetInspectedObject: TComponent;
begin
  Result := SubClass.InspectedObject;
end;

function TACLObjectInspector.GetOnPropertyGetGroupName: TACLObjectInspectorPropertyGetGroupNameEvent;
begin
  Result := SubClass.OnPropertyGetGroupName;
end;

function TACLObjectInspector.GetOptionsBehavior: TACLObjectInspectorOptionsBehavior;
begin
  Result := SubClass.OptionsBehavior;
end;

function TACLObjectInspector.GetOptionsView: TACLObjectInspectorOptionsView;
begin
  Result := SubClass.OptionsView;
end;

function TACLObjectInspector.GetSearchBox: Boolean;
begin
  Result := FSearchEdit.Visible;
end;

function TACLObjectInspector.GetSearchBoxTextHint: string;
begin
  Result := FSearchEdit.TextHint;
end;

function TACLObjectInspector.GetSearchString: string;
begin
  Result := FSearchEdit.Text;
end;

function TACLObjectInspector.GetStyleInplaceEdit: TACLStyleEdit;
begin
  Result := SubClass.StyleInplaceEdit;
end;

function TACLObjectInspector.GetStyleInplaceEditButton: TACLStyleEditButton;
begin
  Result := SubClass.StyleInplaceEditButton;
end;

function TACLObjectInspector.GetStyleHatch: TACLStyleHatch;
begin
  Result := SubClass.StyleHatch;
end;

function TACLObjectInspector.GetStyleScrollBox: TACLStyleScrollBox;
begin
  Result := SubClass.StyleScrollBox;
end;

function TACLObjectInspector.GetStyleSearchEdit: TACLStyleEdit;
begin
  Result := FSearchEdit.Style;
end;

function TACLObjectInspector.GetStyleSearchEditButton: TACLStyleButton;
begin
  Result := FSearchEdit.StyleButton;
end;

function TACLObjectInspector.GetStyle: TACLStyleTreeList;
begin
  Result := SubClass.Style;
end;

function TACLObjectInspector.GetSubClass: TACLObjectInspectorSubClass;
begin
  Result := FInnerControl.SubClass;
end;

function TACLObjectInspector.GetOnKeyPress: TKeyPressEvent;
begin
  Result := FInnerControl.OnKeyPress;
end;

function TACLObjectInspector.GetOnKeyUp: TKeyEvent;
begin
  Result := FInnerControl.OnKeyUp;
end;

function TACLObjectInspector.GetOnMouseDown: TMouseEvent;
begin
  Result := FInnerControl.OnMouseDown;
end;

function TACLObjectInspector.GetOnMouseMove: TMouseMoveEvent;
begin
  Result := FInnerControl.OnMouseMove;
end;

function TACLObjectInspector.GetOnMouseUp: TMouseEvent;
begin
  Result := FInnerControl.OnMouseUp;
end;

function TACLObjectInspector.GetOnPopulated: TNotifyEvent;
begin
  Result := SubClass.OnPopulated;
end;

function TACLObjectInspector.GetOnPropertyAdd: TACLObjectInspectorPropertyAddEvent;
begin
  Result := SubClass.OnPropertyAdd;
end;

function TACLObjectInspector.GetOnPropertyChanged: TACLObjectInspectorPropertyChangedEvent;
begin
  Result := SubClass.OnPropertyChanged;
end;

function TACLObjectInspector.GetOnPropertyChanging: TACLObjectInspectorPropertyChangingEvent;
begin
  Result := SubClass.OnPropertyChanging
end;

procedure TACLObjectInspector.SetFocusedNode(const Value: TACLObjectInspectorNode);
begin
  SubClass.FocusedNode := Value;
end;

procedure TACLObjectInspector.SetInspectedObject(const Value: TComponent);
begin
  SubClass.InspectedObject := Value;
end;

procedure TACLObjectInspector.SetOnKeyPress(const Value: TKeyPressEvent);
begin
  FInnerControl.OnKeyPress := Value;
end;

procedure TACLObjectInspector.SetOnKeyUp(const Value: TKeyEvent);
begin
  FInnerControl.OnKeyUp := Value;
end;

procedure TACLObjectInspector.SetOnMouseDown(const Value: TMouseEvent);
begin
  FInnerControl.OnMouseDown := Value;
end;

procedure TACLObjectInspector.SetOnMouseMove(const Value: TMouseMoveEvent);
begin
  FInnerControl.OnMouseMove := Value;
end;

procedure TACLObjectInspector.SetOnMouseUp(const Value: TMouseEvent);
begin
  FInnerControl.OnMouseUp := Value;
end;

procedure TACLObjectInspector.SetOnPopulated(const Value: TNotifyEvent);
begin
  SubClass.OnPopulated := Value;
end;

procedure TACLObjectInspector.SetOnPropertyAdd(const Value: TACLObjectInspectorPropertyAddEvent);
begin
  SubClass.OnPropertyAdd := Value;
end;

procedure TACLObjectInspector.SetOnPropertyChanged(const Value: TACLObjectInspectorPropertyChangedEvent);
begin
  SubClass.OnPropertyChanged := Value;
end;

procedure TACLObjectInspector.SetOnPropertyChanging(const Value: TACLObjectInspectorPropertyChangingEvent);
begin
  SubClass.OnPropertyChanging := Value;
end;

procedure TACLObjectInspector.SetOnPropertyGetGroupName(const Value: TACLObjectInspectorPropertyGetGroupNameEvent);
begin
  SubClass.OnPropertyGetGroupName := Value;
end;

procedure TACLObjectInspector.SetOptionsBehavior(const Value: TACLObjectInspectorOptionsBehavior);
begin
  SubClass.OptionsBehavior.Assign(Value);
end;

procedure TACLObjectInspector.SetOptionsView(const Value: TACLObjectInspectorOptionsView);
begin
  SubClass.OptionsView.Assign(Value);
end;

procedure TACLObjectInspector.SetSearchBox(const Value: Boolean);
begin
  if SearchBox <> Value then
  begin
    SearchString := '';
    if IsDesigning then
    begin
      if Value then
        FSearchEdit.ControlStyle := FSearchEdit.ControlStyle - [csNoDesignVisible]
      else
        FSearchEdit.ControlStyle := FSearchEdit.ControlStyle + [csNoDesignVisible];
    end;
    FSearchEdit.Visible := Value;
  end;
end;

procedure TACLObjectInspector.SetSearchBoxTextHint(const Value: string);
begin
  FSearchEdit.TextHint := Value;
end;

procedure TACLObjectInspector.SetSearchString(const Value: string);
begin
  if SearchString <> Value then
  begin
    FSearchEdit.Text := Value;
    SubClass.SearchString := Value;
  end;
end;

procedure TACLObjectInspector.SetStyle(const Value: TACLStyleTreeList);
begin
  SubClass.Style.Assign(Value);
end;

procedure TACLObjectInspector.SetStyleInplaceEdit(const Value: TACLStyleEdit);
begin
  SubClass.StyleInplaceEdit.Assign(Value);
end;

procedure TACLObjectInspector.SetStyleInplaceEditButton(const Value: TACLStyleEditButton);
begin
  SubClass.StyleInplaceEditButton.Assign(Value);
end;

procedure TACLObjectInspector.SetStyleHatch(const Value: TACLStyleHatch);
begin
  SubClass.StyleHatch.Assign(Value);
end;

procedure TACLObjectInspector.SetStyleScrollBox(const Value: TACLStyleScrollBox);
begin
  SubClass.StyleScrollBox.Assign(Value);
end;

procedure TACLObjectInspector.SetStyleSearchEdit(const Value: TACLStyleEdit);
begin
  FSearchEdit.Style := Value;
end;

procedure TACLObjectInspector.SetStyleSearchEditButton(const Value: TACLStyleButton);
begin
  FSearchEdit.StyleButton := Value;
end;

procedure TACLObjectInspector.InnerControlKeyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_F3) and SearchBox then
    FSearchEdit.SetFocus;
  if Assigned(OnKeyDown) then
    OnKeyDown(Sender, Key, Shift);
end;

procedure TACLObjectInspector.SearchBoxChangeHandler(Sender: TObject);
begin
  SubClass.SearchString := SearchString;
end;

end.
