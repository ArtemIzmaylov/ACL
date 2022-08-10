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

unit ACL.UI.Controls.CheckComboBox;

{$I ACL.Config.inc}

interface

uses
  System.Classes,
  System.Types,
  // VCL
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Forms,
  ACL.UI.Insight,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type
  TACLCheckComboBox = class;

  { TACLCheckComboBoxItem }

  TACLCheckComboBoxItem = class(TACLCollectionItem)
  strict private
    FChecked: Boolean;
    FTag: NativeInt;
    FText: UnicodeString;

    procedure SetChecked(AChecked: Boolean);
    procedure SetText(const Value: UnicodeString);
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Checked: Boolean read FChecked write SetChecked default False;
    property Tag: NativeInt read FTag write FTag default 0;
    property Text: UnicodeString read FText write SetText;
  end;

  { TACLCheckComboBoxItems }

  TACLCheckComboBoxItemsEnumProc = reference to procedure (const Item: TACLCheckComboBoxItem);

  TACLCheckComboBoxItems = class(TACLCollection)
  strict private
    FCombo: TACLCheckComboBox;

    function GetItem(Index: Integer): TACLCheckComboBoxItem;
    function GetState: TCheckBoxState;
    procedure SetState(const Value: TCheckBoxState);
  protected
    function GetOwner: TPersistent; override;
    procedure UpdateCore(Item: TCollectionItem); override;
  public
    constructor Create(ACombo: TACLCheckComboBox);
    function Add(const AText: UnicodeString; AChecked: Boolean): TACLCheckComboBoxItem;
    procedure EnumChecked(AProc: TACLCheckComboBoxItemsEnumProc);
    function FindByTag(const ATag: NativeInt; out AItem: TACLCheckComboBoxItem): Boolean;
    function FindByText(const AText: UnicodeString; out AItem: TACLCheckComboBoxItem): Boolean;
    //
    property Items[Index: Integer]: TACLCheckComboBoxItem read GetItem; default;
    property State: TCheckBoxState read GetState write SetState;
  end;

  { TACLCheckComboBoxDropDownForm }

  TACLCheckComboBoxDropDownForm = class(TACLCustomComboBoxDropDownForm)
  strict private
    function GetDisplayItemName(AItem: TACLCheckComboBoxItem): UnicodeString;
    function GetOwnerEx: TACLCheckComboBox;
    procedure GetGroupNameHandler(Sender: TObject; ANode: TACLTreeListNode; var AGroupName: string);
    procedure ItemCheckHandler(Sender: TObject; AItem: TACLTreeListNode);
    procedure UpdateStateHandler(Sender: TObject);
  protected
    procedure ClickAtObject(AHitTest: TACLTreeListSubClassHitTest); override;
    procedure PopulateList(AList: TACLTreeList); override;
  public
    constructor Create(AOwner: TComponent); override;
    // Properties
    property Owner: TACLCheckComboBox read GetOwnerEx;
  end;

  { TACLCheckComboBox }

  TACLCheckComboBoxGetDisplayTextEvent = procedure (Sender: TObject; var AText: string) of object;
  TACLCheckComboBoxGetItemDisplayTextEvent = procedure (Sender: TObject; AItem: TACLCheckComboBoxItem; var AText: string) of object;

  TACLCheckComboBox = class(TACLCustomComboBox)
  strict private
    FItems: TACLCheckComboBoxItems;
    FSeparator: WideChar;

    FOnGetDisplayItemGroupName: TACLCheckComboBoxGetItemDisplayTextEvent;
    FOnGetDisplayItemName: TACLCheckComboBoxGetItemDisplayTextEvent;
    FOnGetDisplayText: TACLCheckComboBoxGetDisplayTextEvent;

    function GetCount: Integer;
    function IsSeparatorStored: Boolean;
    procedure SetItems(AValue: TACLCheckComboBoxItems);
    procedure SetSeparator(AValue: WideChar);
  protected
    procedure DoGetDisplayText(AItem: TACLCheckComboBoxItem; var AText: string); virtual;
    procedure DoGetGroupName(AItem: TACLCheckComboBoxItem; var AText: string); virtual;
    function GetDropDownFormClass: TACLCustomPopupFormClass; override;
    procedure SetTextCore(const AText: string); override;
    procedure UpdateText;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //
    property Count: Integer read GetCount;
  published
    property Borders;
    property Items: TACLCheckComboBoxItems read FItems write SetItems;
    property Separator: WideChar read FSeparator write SetSeparator stored IsSeparatorStored;
    property ResourceCollection;
    property Style;
    property StyleButton;
    property StyleDropDownList;
    property StyleDropDownListScrollBox;
    property Text;

    property OnChange;
    property OnGetDisplayItemGroupName: TACLCheckComboBoxGetItemDisplayTextEvent read FOnGetDisplayItemGroupName write FOnGetDisplayItemGroupName;
    property OnGetDisplayItemName: TACLCheckComboBoxGetItemDisplayTextEvent read FOnGetDisplayItemName write FOnGetDisplayItemName;
    property OnGetDisplayText: TACLCheckComboBoxGetDisplayTextEvent read FOnGetDisplayText write FOnGetDisplayText;
  end;

  { TACLCheckComboBoxUIInsightAdapter }

  TACLCheckComboBoxUIInsightAdapter = class(TACLBasicComboBoxUIInsightAdapter)
  public
    class procedure GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder); override;
  end;

implementation

uses
  System.Math,
  System.SysUtils;

{ TACLCheckComboBoxItem }

procedure TACLCheckComboBoxItem.Assign(Source: TPersistent);
begin
  if Source is TACLCheckComboBoxItem then
  begin
    FChecked := TACLCheckComboBoxItem(Source).Checked;
    FText := TACLCheckComboBoxItem(Source).FText;
    FTag := TACLCheckComboBoxItem(Source).Tag;
    Changed(False);
  end;
end;

procedure TACLCheckComboBoxItem.SetChecked(AChecked: Boolean);
begin
  if AChecked <> FChecked then
  begin
    FChecked := AChecked;
    Changed(False);
  end;
end;

procedure TACLCheckComboBoxItem.SetText(const Value: UnicodeString);
begin
  if FText <> Value then
  begin
    FText := Value;
    Changed(False);
  end;
end;

{ TACLCheckComboBoxItems }

constructor TACLCheckComboBoxItems.Create(ACombo: TACLCheckComboBox);
begin
  FCombo := ACombo;
  inherited Create(TACLCheckComboBoxItem);
end;

function TACLCheckComboBoxItems.Add(const AText: UnicodeString; AChecked: Boolean): TACLCheckComboBoxItem;
begin
  BeginUpdate;
  try
    Result := TACLCheckComboBoxItem(inherited Add);
    Result.Text := AText;
    Result.Checked := AChecked;
  finally
    EndUpdate;
  end;
end;

procedure TACLCheckComboBoxItems.EnumChecked(AProc: TACLCheckComboBoxItemsEnumProc);
var
  AItem: TACLCheckComboBoxItem;
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    AItem := Items[I];
    if AItem.Checked then
      AProc(AItem);
  end;
end;

function TACLCheckComboBoxItems.FindByTag(const ATag: NativeInt; out AItem: TACLCheckComboBoxItem): Boolean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].Tag = ATag then
    begin
      AItem := Items[I];
      Exit(True);
    end;
  Result := False;
end;

function TACLCheckComboBoxItems.FindByText(const AText: UnicodeString; out AItem: TACLCheckComboBoxItem): Boolean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].Text = AText then
    begin
      AItem := Items[I];
      Exit(True);
    end;
  Result := False;
end;

function TACLCheckComboBoxItems.GetOwner: TPersistent;
begin
  Result := FCombo;
end;

procedure TACLCheckComboBoxItems.UpdateCore(Item: TCollectionItem);
begin
  inherited UpdateCore(Item);
  FCombo.UpdateText; // before change
  FCombo.Changed;
end;

function TACLCheckComboBoxItems.GetItem(Index: Integer): TACLCheckComboBoxItem;
begin
  Result := TACLCheckComboBoxItem(inherited Items[Index]);
end;

function TACLCheckComboBoxItems.GetState: TCheckBoxState;
var
  AHasChecked, AHasUnchecked: Boolean;
  I: Integer;
begin
  AHasChecked := False;
  AHasUnchecked := False;

  for I := 0 to Count - 1 do
  begin
    AHasChecked := AHasChecked or Items[I].Checked;
    AHasUnchecked := AHasUnchecked or not Items[I].Checked;
    if AHasUnchecked and AHasChecked then Break;
  end;

  if AHasChecked and AHasUnchecked then
    Result := cbGrayed
  else
    if AHasChecked then
      Result := cbChecked
    else
      Result := cbUnchecked;
end;

procedure TACLCheckComboBoxItems.SetState(const Value: TCheckBoxState);
var
  I: Integer;
begin
  if Value <> cbGrayed then
  begin
    BeginUpdate;
    try
      for I := 0 to Count - 1 do
        Items[I].Checked := Value = cbChecked;
    finally
      EndUpdate;
    end;
  end;
end;

{ TACLCheckComboBoxDropDownForm }

constructor TACLCheckComboBoxDropDownForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Control.OptionsView.CheckBoxes := True;
  Control.OptionsView.Columns.AutoWidth := True;
  Control.OptionsView.Columns.Visible := Control.RootNode.ChildrenCount > 1;
  Control.Columns.Add;

  // must be last
  Control.OnNodeChecked := ItemCheckHandler;
  Control.OnUpdateState := UpdateStateHandler;
end;

procedure TACLCheckComboBoxDropDownForm.ClickAtObject(AHitTest: TACLTreeListSubClassHitTest);
begin
  if AHitTest.HitAtNode and not AHitTest.IsCheckable then
    AHitTest.Node.Checked := not AHitTest.Node.Checked;
end;

procedure TACLCheckComboBoxDropDownForm.PopulateList(AList: TACLTreeList);
var
  AItem: TACLCheckComboBoxItem;
  ATreeListNode: TACLTreeListNode;
  I: Integer;
begin
  if Assigned(Owner.OnGetDisplayItemGroupName) then
  begin
    AList.OnGetNodeGroup := GetGroupNameHandler;
    AList.OptionsBehavior.Groups := True;
  end;
  for I := 0 to Owner.Count - 1 do
  begin
    AItem := Owner.Items.Items[I];
    ATreeListNode := AList.RootNode.AddChild;
    ATreeListNode.Data := AItem;
    ATreeListNode.Checked := AItem.Checked;
    ATreeListNode.Caption := GetDisplayItemName(AItem);
  end;
end;

function TACLCheckComboBoxDropDownForm.GetDisplayItemName(AItem: TACLCheckComboBoxItem): UnicodeString;
begin
  Result := AItem.Text;
  Owner.DoGetDisplayText(AItem, Result);
end;

function TACLCheckComboBoxDropDownForm.GetOwnerEx: TACLCheckComboBox;
begin
  Result := TACLCheckComboBox(inherited Owner);
end;

procedure TACLCheckComboBoxDropDownForm.GetGroupNameHandler(Sender: TObject; ANode: TACLTreeListNode; var AGroupName: string);
begin
  Owner.DoGetGroupName(ANode.Data, AGroupName);
end;

procedure TACLCheckComboBoxDropDownForm.ItemCheckHandler(Sender: TObject; AItem: TACLTreeListNode);
begin
  TACLCheckComboBoxItem(AItem.Data).Checked := AItem.Checked;
end;

procedure TACLCheckComboBoxDropDownForm.UpdateStateHandler(Sender: TObject);
begin
  if Control.IsUpdateLocked then
    Owner.Items.BeginUpdate
  else
    Owner.Items.EndUpdate;
end;

{ TACLCustomCombo }

constructor TACLCheckComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSeparator := ';';
  FItems := TACLCheckComboBoxItems.Create(Self);
end;

destructor TACLCheckComboBox.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TACLCheckComboBox.SetTextCore(const AText: string);
var
  AItem: TACLCheckComboBoxItem;
  AStrings: TStringDynArray;
  I: Integer;
begin
  Items.BeginUpdate;
  try
    Items.State := cbUnchecked;
    acExplodeString(AText, Separator, AStrings);
    for I := 0 to Length(AStrings) - 1 do
    begin
      if Items.FindByText(AStrings[I], AItem) then
        AItem.Checked := True;
    end;
    UpdateText;
  finally
    Items.EndUpdate;
  end;
end;

procedure TACLCheckComboBox.UpdateText;
var
  AText: TStringBuilder;
begin
  AText := TStringBuilder.Create;
  try
    Items.EnumChecked(
      procedure (const Item: TACLCheckComboBoxItem)
      begin
        AText.Append(Item.Text);
        AText.Append(Separator);
      end);

    FText := AText.ToString;
    if Assigned(OnGetDisplayText) then
      OnGetDisplayText(Self, FText);
  finally
    AText.Free;
  end;
  Invalidate;
end;

function TACLCheckComboBox.GetCount: Integer;
begin
  Result := Items.Count;
end;

procedure TACLCheckComboBox.DoGetDisplayText(AItem: TACLCheckComboBoxItem; var AText: string);
begin
  if Assigned(OnGetDisplayItemName) then
    OnGetDisplayItemName(Self, AItem, AText);
end;

procedure TACLCheckComboBox.DoGetGroupName(AItem: TACLCheckComboBoxItem; var AText: string);
begin
  if Assigned(OnGetDisplayItemGroupName) then
    OnGetDisplayItemGroupName(Self, AItem, AText);
end;

function TACLCheckComboBox.GetDropDownFormClass: TACLCustomPopupFormClass;
begin
  Result := TACLCheckComboBoxDropDownForm;
end;

function TACLCheckComboBox.IsSeparatorStored: Boolean;
begin
  Result := FSeparator <> ';';
end;

procedure TACLCheckComboBox.SetItems(AValue: TACLCheckComboBoxItems);
begin
  Items.Assign(AValue);
end;

procedure TACLCheckComboBox.SetSeparator(AValue: WideChar);
begin
  if FSeparator <> AValue then
  begin
    FSeparator := AValue;
    UpdateText;
  end;
end;

{ TACLCheckComboBoxUIInsightAdapter }

class procedure TACLCheckComboBoxUIInsightAdapter.GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
var
  ACheckComboBox: TACLCheckComboBox absolute AObject;
  I: Integer;
begin
  for I := 0 to ACheckComboBox.Count - 1 do
    ABuilder.AddCandidate(ACheckComboBox, ACheckComboBox.Items[I].Text);
end;

initialization
  TACLUIInsight.Register(TACLCheckComboBox, TACLCheckComboBoxUIInsightAdapter);
end.
