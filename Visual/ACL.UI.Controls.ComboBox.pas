{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Editors Controls              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.ComboBox;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.SysUtils,
  System.Classes,
  System.Types,
  // VCL
  Vcl.Controls,
  Vcl.Graphics,
  // ACL
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.CompoundControl.SubClass.ContentCells,
  ACL.UI.Controls.DropDown,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Forms,
  ACL.UI.Insight,
  ACL.UI.Resources,
  ACL.Utils.Common;

type
  TACLComboBox = class;

  { TACLCustomComboBox }

  TACLCustomComboBox = class(TACLCustomDropDownEdit)
  strict private
    FDropDownListSize: Integer;
    FStyleDropDownList: TACLStyleTreeList;
    FStyleDropDownListScrollBox: TACLStyleScrollBox;

    procedure SetDropDownListSize(AValue: Integer);
    procedure SetStyleDropDownList(const Value: TACLStyleTreeList);
    procedure SetStyleDropDownListScrollBox(const Value: TACLStyleScrollBox);
  protected
    function CreateButtonViewInfo: TACLCustomDropDownEditButtonViewInfo; override;
    function CreateStyleButton: TACLStyleButton; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure SetTargetDPI(AValue: Integer); override;
    //
    property DropDownListSize: Integer read FDropDownListSize write SetDropDownListSize default 8;
    property StyleDropDownList: TACLStyleTreeList read FStyleDropDownList write SetStyleDropDownList;
    property StyleDropDownListScrollBox: TACLStyleScrollBox read FStyleDropDownListScrollBox write SetStyleDropDownListScrollBox;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { TACLCustomComboBoxDropDownForm }

  TACLCustomComboBoxDropDownForm = class(TACLCustomPopupForm)
  strict private
    FCapturedObject: TObject;
    FControl: TACLTreeList;
    FOwner: TACLCustomComboBox;

    function CalculateHeight: Integer;
    procedure MouseDownHandler(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseUpHandler(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  protected
    procedure AdjustSize; override;
    procedure ClickAtObject(AHitTest: TACLTreeListSubClassHitTest); virtual;
    procedure Initialize; override;
    procedure PopulateList(AList: TACLTreeList); virtual; abstract;
    procedure ResourceChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    //
    property Owner: TACLCustomComboBox read FOwner;
    property Control: TACLTreeList read FControl;
  end;

  { TACLCustomComboBoxButtonViewInfo }

  TACLCustomComboBoxButtonViewInfo = class(TACLCustomDropDownEditButtonViewInfo);

  { TACLBasicComboBox }

  TACLComboBoxCustomDrawItemEvent = procedure (Sender: TObject;
    Canvas: TCanvas; const R: TRect; Index: Integer; var Handled: Boolean) of object;
  TACLComboBoxDeleteItemObjectEvent = procedure (Sender: TObject; ItemObject: TObject) of object;
  TACLComboBoxGetDisplayTextEvent = procedure (Sender: TObject; Index: Integer; var Text: string) of object;
  TACLComboBoxPrepareDropDownListEvent = procedure (Sender: TObject; List: TACLTreeList) of object;

  TACLBasicComboBox = class(TACLCustomComboBox)
  strict private
    FLoadedItemIndex: Integer;

    FOnCustomDrawItem: TACLComboBoxCustomDrawItemEvent;
    FOnDeleteItemObject: TACLComboBoxDeleteItemObjectEvent;
    FOnGetDisplayItemGroupName: TACLComboBoxGetDisplayTextEvent;
    FOnGetDisplayItemName: TACLComboBoxGetDisplayTextEvent;
    FOnPrepareDropDownList: TACLComboBoxPrepareDropDownListEvent;
    FOnSelect: TNotifyEvent;

    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    FChangeLockCount: Integer;
    FItemIndex: Integer;

    function GetCount: Integer; virtual; abstract;
    procedure ItemIndexChanged; virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Loaded; override;
    procedure SetItemIndex(AValue: Integer); virtual;
    function TextToDisplayText(const AText: string): string; override;
    function ValidateItemIndex(AValue: Integer): Integer;

    // Events
    procedure DoBeforeRemoveItem(AObject: TObject); virtual;
    procedure DoCustomDrawItem(ACanvas: TCanvas; const R: TRect; AIndex: Integer; var AHandled: Boolean); virtual;
    procedure DoGetDisplayText(AIndex: Integer; var AText: string); virtual;
    procedure DoGetGroupName(AIndex: Integer; var AText: string); virtual;
    procedure DoPrepareDropDown(AList: TACLTreeList); virtual;
    procedure DoSelect; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateInplace(const AParams: TACLInplaceInfo); override;
    procedure ChangeItemIndex(AValue: Integer); virtual;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure LockChanges(ALock: Boolean);
    // Properties
    property Count: Integer read GetCount;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;
    // Events
    property OnCustomDrawItem: TACLComboBoxCustomDrawItemEvent read FOnCustomDrawItem write FOnCustomDrawItem;
    property OnDeleteItemObject: TACLComboBoxDeleteItemObjectEvent read FOnDeleteItemObject write FOnDeleteItemObject;
    property OnGetDisplayItemGroupName: TACLComboBoxGetDisplayTextEvent read FOnGetDisplayItemGroupName write FOnGetDisplayItemGroupName;
    property OnGetDisplayItemName: TACLComboBoxGetDisplayTextEvent read FOnGetDisplayItemName write FOnGetDisplayItemName;
    property OnPrepareDropDownList: TACLComboBoxPrepareDropDownListEvent read FOnPrepareDropDownList write FOnPrepareDropDownList;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
  end;

  { TACLBasicComboBoxDropDownForm }

  TACLBasicComboBoxDropDownForm = class(TACLCustomComboBoxDropDownForm)
  strict private
    function GetOwnerEx: TACLBasicComboBox;
  protected
    procedure ClickAtObject(AHitTest: TACLTreeListSubClassHitTest); override;
    procedure DoCustomDraw(Sender: TObject; ACanvas: TCanvas; const R: TRect; ANode: TACLTreeListNode; var AHandled: Boolean);
    procedure DoGetGroupName(Sender: TObject; ANode: TACLTreeListNode; var AGroupName: string);
    procedure DoKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DoSelectItem;
    procedure DoShow; override;

    function AddItem(AList: TACLTreeList; ACaption: string): TACLTreeListNode;
    procedure Initialize; override;
    procedure PopulateList(AList: TACLTreeList); override; final;
    procedure PopulateListCore(AList: TACLTreeList); virtual; abstract;
    procedure SyncItemIndex;
  public
    constructor Create(AOwner: TComponent); override;
    procedure AfterConstruction; override;
    //
    property Owner: TACLBasicComboBox read GetOwnerEx;
  end;

  { TACLBasicComboBoxUIInsightAdapter }

  TACLBasicComboBoxUIInsightAdapter = class(TACLUIInsightAdapterWinControl)
  public
    class function GetCaption(AObject: TObject; out AValue: string): Boolean; override;
  end;

  { TACLComboBox }

  TACLComboBoxMode = (cbmEdit, cbmList);
  TACLComboBox = class(TACLBasicComboBox)
  strict private
    FAutoComplete: Boolean;
    FAutoCompletionLastKey: Word;
    FItems: TStrings;
    FMode: TACLComboBoxMode;

    function GetHasSelection: Boolean;
    function GetSelectedObject: TObject;
    procedure SetItems(AItems: TStrings);
    procedure SetMode(AValue: TACLComboBoxMode);
  protected
    function CalculateEditorPosition: TRect; override;
    function CanAutoComplete: Boolean;
    function CanDropDown(X: Integer; Y: Integer): Boolean; override;
    function CanOpenEditor: Boolean; override;
    function CreateEditor: TWinControl; override;

    function GetCount: Integer; override;
    function GetDropDownFormClass: TACLCustomPopupFormClass; override;

    procedure ItemIndexChanged; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure SetItemIndex(AValue: Integer); override;
    procedure SetTextCore(const AValue: UnicodeString); override;
    procedure SynchronizeText;

    // Events
    procedure DoStringChanged; virtual;
    procedure DoTextFromEditorChanged(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateInplace(const AParams: TACLInplaceInfo); override;
    destructor Destroy; override;
    procedure AddItem(const S: UnicodeString; AObject: TObject = nil);
    function IndexOf(const S: string): Integer;
    function IndexOfObject(AObject: TObject): Integer;
    procedure Localize(const ASection: UnicodeString); override;
    //
    property HasSelection: Boolean read GetHasSelection;
    property SelectedObject: TObject read GetSelectedObject;
    property Value;
  published
    property AutoComplete: Boolean read FAutoComplete write FAutoComplete default True;
    property AutoHeight;
    property Borders;
    property Buttons;
    property ButtonsImages;
    property DropDownListSize;
    property InputMask;
    property Items: TStrings read FItems write SetItems;
    property ItemIndex; // after Items
    property MaxLength;
    property Mode: TACLComboBoxMode read FMode write SetMode default cbmEdit;
    property ReadOnly;
    property ResourceCollection;
    property Style;
    property StyleButton;
    property StyleDropDownList;
    property StyleDropDownListScrollBox;
    property Text;
    //
    property OnChange;
    property OnCustomDraw;
    property OnCustomDrawItem;
    property OnDeleteItemObject;
    property OnDropDown;
    property OnGetDisplayItemGroupName;
    property OnGetDisplayItemName;
    property OnPrepareDropDownList;
    property OnSelect;
  end;

  { TACLComboBoxDropDownForm }

  TACLComboBoxDropDownForm = class(TACLBasicComboBoxDropDownForm)
  protected
    procedure PopulateListCore(AList: TACLTreeList); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  { TACLComboBoxUIInsightAdapter }

  TACLComboBoxUIInsightAdapter = class(TACLBasicComboBoxUIInsightAdapter)
  public
    class procedure GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder); override;
  end;

implementation

uses
  Math,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Math,
  ACL.Utils.Strings;

type

  { TACLComboBoxStrings }

  TACLComboBoxStrings = class(TStringList)
  strict private
    FOwner: TACLComboBox;
  protected
    procedure BeforeRemoveItem(AObject: TObject);
    procedure Changed; override;
  public
    constructor Create(AOwner: TACLComboBox);
    function FindItemBeginsWith(const AText: UnicodeString): Integer;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
  end;

procedure InitializeTreeList(ATreeList: TACLTreeList; AEditor: TACLCustomComboBox);
begin
  ATreeList.BeginUpdate;
  try
    ATreeList.OptionsView.Columns.Visible := False;
    ATreeList.OptionsView.Nodes.GridLines := [];
    ATreeList.OptionsBehavior.HotTrack := True;
    ATreeList.OptionsBehavior.IncSearchColumnIndex := 0;
    ATreeList.OptionsBehavior.SortingMode := tlsmDisabled;
    ATreeList.Style := AEditor.StyleDropDownList;
    ATreeList.StyleInplaceEdit := AEditor.Style;
    ATreeList.StyleScrollBox := AEditor.StyleDropDownListScrollBox;
  finally
    ATreeList.EndUpdate;
  end;
end;

{ TACLCustomComboBox }

constructor TACLCustomComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDropDownListSize := 8;
  FStyleDropDownList := TACLStyleTreeList.Create(Self);
  FStyleDropDownListScrollBox := TACLStyleScrollBox.Create(Self);
end;

destructor TACLCustomComboBox.Destroy;
begin
  FreeAndNil(FStyleDropDownListScrollBox);
  FreeAndNil(FStyleDropDownList);
  inherited Destroy;
end;

function TACLCustomComboBox.CreateButtonViewInfo: TACLCustomDropDownEditButtonViewInfo;
begin
  Result := TACLCustomComboBoxButtonViewInfo.Create(Self);
end;

function TACLCustomComboBox.CreateStyleButton: TACLStyleButton;
begin
  Result := TACLStyleEditButton.Create(Self);
end;

procedure TACLCustomComboBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if acIsDropDownCommand(Key, Shift) then
    DropDown;
end;

procedure TACLCustomComboBox.SetTargetDPI(AValue: Integer);
begin
  inherited;
  StyleDropDownList.TargetDPI := AValue;
  StyleDropDownListScrollBox.TargetDPI := AValue;
end;

procedure TACLCustomComboBox.SetDropDownListSize(AValue: Integer);
begin
  FDropDownListSize := MinMax(AValue, 1, 25);
end;

procedure TACLCustomComboBox.SetStyleDropDownListScrollBox(const Value: TACLStyleScrollBox);
begin
  FStyleDropDownListScrollBox.Assign(Value);
end;

procedure TACLCustomComboBox.SetStyleDropDownList(const Value: TACLStyleTreeList);
begin
  FStyleDropDownList.Assign(Value);
end;

{ TACLCustomComboBoxDropDownForm }

constructor TACLCustomComboBoxDropDownForm.Create(AOwner: TComponent);
begin
  FOwner := AOwner as TACLCustomComboBox;
  inherited Create(FOwner);
  DoubleBuffered := True;
  Control.OnMouseDown := MouseDownHandler;
  Control.OnMouseUp := MouseUpHandler;
  PopulateList(Control);
  InitializeTreeList(Control, Owner);
end;

function TACLCustomComboBoxDropDownForm.CalculateHeight: Integer;
var
  AController: TACLTreeListSubClassNavigationController;
  AFirstNode: TACLTreeListNode;
  AFirstNodeCell: TACLCompoundControlSubClassBaseContentCell;
  ALastNode: TACLTreeListNode;
  ALastNodeCell: TACLCompoundControlSubClassBaseContentCell;
begin
  Result := 0;
  if Control.RootNode.ChildrenCount > 0 then
  begin
    AFirstNode := Control.RootNode.Children[0];
    ALastNode := Control.RootNode.Children[Min(Control.RootNode.ChildrenCount, Owner.DropDownListSize) - 1];
    AController := Control.SubClass.Controller.NavigationController;
    if AController.GetContentCellForObject(AFirstNode, AFirstNodeCell) and
       AController.GetContentCellForObject(ALastNode, ALastNodeCell)
    then
      Result := ALastNodeCell.Bounds.Bottom - AFirstNodeCell.Bounds.Top +
        Control.SubClass.ViewInfo.Bounds.Height -
        Control.SubClass.ViewInfo.Content.ViewItemsArea.Height;
  end;
end;

procedure TACLCustomComboBoxDropDownForm.AdjustSize;
begin
  Height := CalculateHeight;
end;

procedure TACLCustomComboBoxDropDownForm.ClickAtObject(AHitTest: TACLTreeListSubClassHitTest);
begin
  // do nothing
end;

procedure TACLCustomComboBoxDropDownForm.MouseDownHandler(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FCapturedObject := Control.ObjectAtPos(X, Y);
end;

procedure TACLCustomComboBoxDropDownForm.MouseUpHandler(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FCapturedObject = Control.ObjectAtPos(X, Y) then
    ClickAtObject(Control.SubClass.Controller.HitTest);
end;

procedure TACLCustomComboBoxDropDownForm.Initialize;
begin
  inherited;
  FControl := TACLTreeList.Create(Self);
  FControl.Parent := Self;
  FControl.Align := alClient;
end;

procedure TACLCustomComboBoxDropDownForm.ResourceChanged;
begin
  inherited;
  AdjustSize
end;

{ TACLComboBoxDropDownForm }

constructor TACLComboBoxDropDownForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Control.OptionsBehavior.IncSearchColumnIndex := IfThen(TACLComboBox(Owner).AutoComplete, 0, -1);
end;

procedure TACLComboBoxDropDownForm.PopulateListCore(AList: TACLTreeList);
var
  I: Integer;
begin
  for I := 0 to TACLComboBox(Owner).Items.Count - 1 do
    AddItem(AList, TACLComboBox(Owner).Items[I]);
end;

{ TACLComboBox }

constructor TACLComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoComplete := True;
  FItems := TACLComboBoxStrings.Create(Self);
end;

constructor TACLComboBox.CreateInplace(const AParams: TACLInplaceInfo);
begin
  inherited CreateInplace(AParams);
  Mode := cbmList;
end;

destructor TACLComboBox.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TACLComboBox.AddItem(const S: UnicodeString; AObject: TObject = nil);
begin
  Items.AddObject(S, AObject)
end;

procedure TACLComboBox.Localize(const ASection: UnicodeString);
var
  ASavedItemIndex: Integer;
begin
  LockChanges(True);
  try
    inherited Localize(ASection);

    ASavedItemIndex := FItemIndex;
    try
      LangApplyToItems(ASection, Items);
    finally
      ItemIndex := ASavedItemIndex;
    end;
  finally
    LockChanges(False);
  end;
end;

function TACLComboBox.CalculateEditorPosition: TRect;
begin
  Result := FTextRect;
end;

function TACLComboBox.CanAutoComplete: Boolean;
begin
  Result := AutoComplete and
    (FAutoCompletionLastKey <> 0) and
    (FAutoCompletionLastKey <> VK_DELETE) and
    (FAutoCompletionLastKey <> VK_BACK);
end;

function TACLComboBox.CanDropDown(X, Y: Integer): Boolean;
begin
  Result := (Mode = cbmList) and inherited CanDropDown(X, Y);
end;

procedure TACLComboBox.DoStringChanged;
begin
  ItemIndex := Items.IndexOf(Text);
end;

procedure TACLComboBox.DoTextFromEditorChanged(Sender: TObject);
var
  ASavedText: UnicodeString;
begin
  if FTextChangeLockCount = 0 then
  begin
    if (Mode = cbmEdit) and CanAutoComplete then
    begin
      Inc(FTextChangeLockCount);
      try
        ASavedText := InnerEdit.Text;
        FItemIndex := TACLComboBoxStrings(FItems).FindItemBeginsWith(ASavedText);
        if ItemIndex >= 0 then
        begin
          InnerEdit.Text := Items.Strings[ItemIndex];
          InnerEdit.SelStart := Length(ASavedText);
          InnerEdit.SelLength := Length(InnerEdit.Text) - Length(ASavedText);
        end;
      finally
        Dec(FTextChangeLockCount);
      end;
    end;
    RetriveValueFromInnerEdit;
  end;
end;

function TACLComboBox.IndexOf(const S: string): Integer;
begin
  Result := Items.IndexOf(S);
end;

function TACLComboBox.IndexOfObject(AObject: TObject): Integer;
begin
  Result := Items.IndexOfObject(AObject);
end;

procedure TACLComboBox.ItemIndexChanged;
begin
  SynchronizeText;
  inherited ItemIndexChanged;
end;

procedure TACLComboBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  FAutoCompletionLastKey := IfThen([ssCtrl, ssAlt] * Shift = [], Key);
  inherited KeyDown(Key, Shift);
end;

procedure TACLComboBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if not (CanDropDown(X, Y) and DropDown) then
    inherited MouseDown(Button, Shift, X, Y);
end;

function TACLComboBox.CanOpenEditor: Boolean;
begin
  Result := (Mode = cbmEdit) and not IsDesigning;
end;

function TACLComboBox.CreateEditor: TWinControl;
var
  AEdit: TACLInnerEdit;
begin
  AEdit := TACLInnerEdit.Create(nil);
  AEdit.Text := Text; // Must be before assigning OnChange event
  AEdit.OnChange := DoTextFromEditorChanged;
  Result := AEdit;
end;

function TACLComboBox.GetCount: Integer;
begin
  Result := Items.Count;
end;

function TACLComboBox.GetDropDownFormClass: TACLCustomPopupFormClass;
begin
  Result := TACLComboBoxDropDownForm;
end;

procedure TACLComboBox.SetItems(AItems: TStrings);
begin
  FItems.Assign(AItems);
end;

procedure TACLComboBox.SetMode(AValue: TACLComboBoxMode);
begin
  if AValue <> FMode then
  begin
    FMode := AValue;
    if AValue = cbmEdit then
      EditorOpen
    else
      EditorClose;
  end;
end;

procedure TACLComboBox.SetItemIndex(AValue: Integer);
begin
  AValue := ValidateItemIndex(AValue);
  if AValue <> FItemIndex then
    ChangeItemIndex(AValue)
  else
    if Items.Updating then
    begin
      LockChanges(True);
      try
        SynchronizeText;
      finally
        LockChanges(False);
      end;
    end;
end;

procedure TACLComboBox.SetTextCore(const AValue: UnicodeString);
begin
  FText := '';
  if not HasSelection or (Items[ItemIndex] <> AValue) then
    FItemIndex := Items.IndexOf(AValue);
  if not ((Mode = cbmList) and (ItemIndex < 0)) then
  begin
    FText := AValue;
    if InnerEdit <> nil then
    begin
      Inc(FTextChangeLockCount);
      InnerEdit.Text := AValue;
      Dec(FTextChangeLockCount);
    end;
  end;
end;

procedure TACLComboBox.SynchronizeText;
begin
  if ItemIndex >= 0 then
    Text := Items.Strings[ItemIndex]
  else
    Text := '';
end;

function TACLComboBox.GetHasSelection: Boolean;
begin
  Result := (ItemIndex >= 0) and (ItemIndex < Items.Count);
end;

function TACLComboBox.GetSelectedObject: TObject;
begin
  if HasSelection then
    Result := Items.Objects[ItemIndex]
  else
    Result := nil;
end;

{ TACLBasicComboBox }

constructor TACLBasicComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLoadedItemIndex := -1;
  FItemIndex := -1;
end;

constructor TACLBasicComboBox.CreateInplace(const AParams: TACLInplaceInfo);
begin
  inherited CreateInplace(AParams);
  OnSelect := AParams.OnApply;
end;

procedure TACLBasicComboBox.ChangeItemIndex(AValue: Integer);
begin
  if IsLoading then
  begin
    FLoadedItemIndex := AValue;
    Exit;
  end;

  FItemIndex := ValidateItemIndex(AValue);
  ItemIndexChanged;
  Invalidate;
end;

procedure TACLBasicComboBox.LockChanges(ALock: Boolean);
begin
  if ALock then
    Inc(FChangeLockCount)
  else
    Dec(FChangeLockCount);
end;

function TACLBasicComboBox.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if not Result then
  begin
    ItemIndex := Max(0, ItemIndex - Signs[WheelDelta > 0]);
    Result := True;
  end;
end;

procedure TACLBasicComboBox.DoPrepareDropDown(AList: TACLTreeList);
begin
  if Assigned(OnPrepareDropDownList) then
    OnPrepareDropDownList(Self, AList);
end;

procedure TACLBasicComboBox.DoBeforeRemoveItem(AObject: TObject);
begin
  if Assigned(OnDeleteItemObject) then
    OnDeleteItemObject(Self, AObject);
end;

procedure TACLBasicComboBox.DoCustomDrawItem(ACanvas: TCanvas; const R: TRect; AIndex: Integer; var AHandled: Boolean);
begin
  if Assigned(OnCustomDrawItem) then
    OnCustomDrawItem(Self, ACanvas, R, AIndex, AHandled);
end;

procedure TACLBasicComboBox.DoGetDisplayText(AIndex: Integer; var AText: string);
begin
  if Assigned(OnGetDisplayItemName) then
    OnGetDisplayItemName(Self, AIndex, AText);
end;

procedure TACLBasicComboBox.DoGetGroupName(AIndex: Integer; var AText: string);
begin
  if Assigned(OnGetDisplayItemGroupName) then
    OnGetDisplayItemGroupName(Self, AIndex, AText);
end;

procedure TACLBasicComboBox.DoSelect;
begin
  CallNotifyEvent(Self, OnSelect);
end;

procedure TACLBasicComboBox.ItemIndexChanged;
begin
  if FDropDown is TACLBasicComboBoxDropDownForm then
    TACLBasicComboBoxDropDownForm(FDropDown).SyncItemIndex;
  if (FChangeLockCount = 0) and not IsLoading then
    DoSelect;
end;

procedure TACLBasicComboBox.KeyDown(var Key: Word; Shift: TShiftState);
var
  AItemIndex: Integer;
begin
  inherited KeyDown(Key, Shift);

  if [ssShift, ssAlt, ssCtrl] * Shift = [] then
  begin
    case Key of
      VK_UP:
        AItemIndex := Max(0, ItemIndex - 1);
      VK_DOWN:
        AItemIndex := Min(Count - 1, ItemIndex + 1);
    else
      Exit;
    end;

    if AItemIndex <> ItemIndex then
    begin
      ItemIndex := AItemIndex;
      if InnerEdit <> nil then
        InnerEdit.SelectAll;
    end;
    Key := 0;
  end;
end;

procedure TACLBasicComboBox.Loaded;
begin
  inherited;
  ItemIndex := FLoadedItemIndex;
end;

procedure TACLBasicComboBox.SetItemIndex(AValue: Integer);
begin
  AValue := ValidateItemIndex(AValue);
  if AValue <> FItemIndex then
    ChangeItemIndex(AValue);
end;

function TACLBasicComboBox.TextToDisplayText(const AText: string): string;
begin
  Result := inherited;
  if Assigned(OnGetDisplayItemName) and (ItemIndex >= 0) then
    OnGetDisplayItemName(Self, ItemIndex, Result);
end;

function TACLBasicComboBox.ValidateItemIndex(AValue: Integer): Integer;
begin
  Result := MinMax(AValue, -1, Count - 1);
end;

procedure TACLBasicComboBox.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

{ TACLBasicComboBoxDropDownForm }

constructor TACLBasicComboBoxDropDownForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Control.OptionsBehavior.GroupsFocus := False;
  Control.OptionsBehavior.IncSearchMode := ismFilter;
  Control.OnCustomDrawNode := DoCustomDraw;
  Control.OnKeyUp := DoKeyUp;
end;

procedure TACLBasicComboBoxDropDownForm.AfterConstruction;
begin
  inherited AfterConstruction;
  SyncItemIndex;
end;

procedure TACLBasicComboBoxDropDownForm.ClickAtObject(AHitTest: TACLTreeListSubClassHitTest);
begin
  if AHitTest.HitAtNode then
    DoSelectItem;
end;

procedure TACLBasicComboBoxDropDownForm.DoCustomDraw(Sender: TObject;
  ACanvas: TCanvas; const R: TRect; ANode: TACLTreeListNode; var AHandled: Boolean);
begin
  Owner.DoCustomDrawItem(ACanvas, R, ANode.Tag, AHandled);
end;

procedure TACLBasicComboBoxDropDownForm.DoGetGroupName(Sender: TObject; ANode: TACLTreeListNode; var AGroupName: string);
begin
  Owner.DoGetGroupName(ANode.Tag, AGroupName);
end;

procedure TACLBasicComboBoxDropDownForm.DoKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
    DoSelectItem;
end;

procedure TACLBasicComboBoxDropDownForm.DoSelectItem;
var
  AReference: TObject;
begin
  TACLObjectLinks.RegisterWeakReference(Self, @AReference);
  try
    if Control.HasSelection then
      Owner.ItemIndex := Control.FocusedNode.Tag;
  finally
    if AReference <> nil then
      DoClosePopup;
    TACLObjectLinks.UnregisterWeakReference(@AReference);
  end;
end;

procedure TACLBasicComboBoxDropDownForm.DoShow;
begin
  inherited;
  Control.MakeVisible(Control.FocusedNode);
end;

procedure TACLBasicComboBoxDropDownForm.SyncItemIndex;
var
  AItem: TACLTreeListNode;
begin
  if Control.RootNode.Find(AItem, Owner.ItemIndex) then
    Control.FocusedNode := AItem;
end;

function TACLBasicComboBoxDropDownForm.AddItem(AList: TACLTreeList; ACaption: string): TACLTreeListNode;
var
  AIndex: Integer;
begin
  AIndex := AList.RootNode.ChildrenCount;
  Owner.DoGetDisplayText(AIndex, ACaption);
  Result := AList.RootNode.AddChild;
  Result.Caption := ACaption;
  Result.Tag := AIndex;
end;

procedure TACLBasicComboBoxDropDownForm.PopulateList(AList: TACLTreeList);
begin
  AList.BeginUpdate;
  try
    AList.Clear;
    if Assigned(Owner.OnGetDisplayItemGroupName) then
    begin
      AList.OnGetNodeGroup := DoGetGroupName;
      AList.OptionsBehavior.Groups := True;
    end;
    PopulateListCore(AList);
  finally
    AList.EndUpdate;
  end;
end;

function TACLBasicComboBoxDropDownForm.GetOwnerEx: TACLBasicComboBox;
begin
  Result := TACLBasicComboBox(inherited Owner);
end;

procedure TACLBasicComboBoxDropDownForm.Initialize;
begin
  inherited;
  Owner.DoPrepareDropDown(Control);
end;

{ TACLBasicComboBoxUIInsightAdapter }

class function TACLBasicComboBoxUIInsightAdapter.GetCaption(AObject: TObject; out AValue: string): Boolean;
var
  AComboBox: TACLBasicComboBox absolute AObject;
begin
  Result := AComboBox.ItemIndex = -1;
  if Result then
    AValue := AComboBox.Text;
end;

{ TACLComboBoxStrings }

constructor TACLComboBoxStrings.Create(AOwner: TACLComboBox);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TACLComboBoxStrings.BeforeRemoveItem(AObject: TObject);
begin
  if Assigned(AObject) and Assigned(FOwner) then
    FOwner.DoBeforeRemoveItem(AObject);
end;

procedure TACLComboBoxStrings.Clear;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
    BeforeRemoveItem(Objects[I]);
  inherited Clear;
end;

procedure TACLComboBoxStrings.Delete(Index: Integer);
begin
  BeforeRemoveItem(Objects[Index]);
  inherited Delete(Index);
end;

function TACLComboBoxStrings.FindItemBeginsWith(const AText: UnicodeString): Integer;
var
  I: Integer;
begin
  Result := -1;
  if Length(AText) > 0 then
    for I := 0 to Count - 1 do
    begin
      if Copy(Strings[I], 1, Length(AText)) = AText then
        Exit(I);
    end;
end;

procedure TACLComboBoxStrings.Changed;
begin
  if UpdateCount = 0 then
  begin
    if Assigned(FOwner) then
      FOwner.DoStringChanged;
    inherited Changed;
  end;
end;

{ TACLComboBoxUIInsightAdapter }

class procedure TACLComboBoxUIInsightAdapter.GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
var
  AComboBox: TACLComboBox absolute AObject;
  I: Integer;
begin
  for I := 0 to AComboBox.Count - 1 do
    ABuilder.AddCandidate(AComboBox, AComboBox.Items[I]);
end;

initialization
  TACLUIInsight.Register(TACLBasicComboBox, TACLBasicComboBoxUIInsightAdapter);
  TACLUIInsight.Register(TACLComboBox, TACLComboBoxUIInsightAdapter);
end.
