////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   CheckComboBox
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.CheckComboBox;

{$I ACL.Config.inc}

interface

uses
  {System.}Classes,
  {System.}SysUtils,
  {System.}Types,
  // VCL
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.ImageComboBox,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type
  TACLCheckComboBox = class;

  { TACLCheckComboBoxItem }

  TACLCheckComboBoxItem = class(TACLImageComboBoxItem)
  strict private
    FChecked: Boolean;
    procedure SetChecked(AChecked: Boolean);
  protected
    procedure AssignCore(Source: TPersistent); override;
  published
    property Checked: Boolean read FChecked write SetChecked default False;
  end;

  { TACLCheckComboBoxItems }

  TACLCheckComboBoxItems = class(TACLImageComboBoxItems)
  strict private
    function GetItem(Index: Integer): TACLCheckComboBoxItem;
    function GetState: TCheckBoxState;
    procedure SetState(const Value: TCheckBoxState);
  protected
    function GetClass: TACLImageComboBoxItemClass; override;
    procedure UpdateCore(Item: TCollectionItem); override;
  public
    function Add(const AText: string; AChecked: Boolean): TACLCheckComboBoxItem;
    procedure EnumChecked(AProc: TConsumerC<TACLCheckComboBoxItem>);
    //# Properties
    property Items[Index: Integer]: TACLCheckComboBoxItem read GetItem; default;
    property State: TCheckBoxState read GetState write SetState;
  end;

  { TACLCheckComboBoxDropDown }

  TACLCheckComboBoxDropDown = class(TACLBasicComboBoxDropDown)
  strict private
    procedure HandlerItemCheck(Sender: TObject; AItem: TACLTreeListNode);
    procedure HandlerUpdateState(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

  { TACLCheckComboBox }

  TACLCheckComboBox = class(TACLBasicImageComboBox)
  strict private
    FSeparator: Char;

    function GetItems: TACLCheckComboBoxItems;
    function IsSeparatorStored: Boolean;
    procedure SetItems(AValue: TACLCheckComboBoxItems);
    procedure SetSeparator(AValue: Char);
  protected
    function CreateDropDownWindow: TACLPopupWindow; override;
    procedure DoPrepareDropDownList(AList: TACLBasicDropDownList); override;
    procedure SetTextCore(const AText: string); override;
    procedure UpdateText;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Items: TACLCheckComboBoxItems read GetItems write SetItems;
    property Separator: Char read FSeparator write SetSeparator stored IsSeparatorStored;
    property Text; // last
  end;

implementation

{ TACLCheckComboBoxItem }

procedure TACLCheckComboBoxItem.AssignCore(Source: TPersistent);
begin
  inherited;
  FChecked := TACLCheckComboBoxItem(Source).Checked;
end;

procedure TACLCheckComboBoxItem.SetChecked(AChecked: Boolean);
begin
  if AChecked <> FChecked then
  begin
    FChecked := AChecked;
    Changed(False);
  end;
end;

{ TACLCheckComboBoxItems }

function TACLCheckComboBoxItems.Add(const AText: string; AChecked: Boolean): TACLCheckComboBoxItem;
begin
  BeginUpdate;
  try
    Result := TACLCheckComboBoxItem(inherited Add(AText, -1));
    Result.Text := AText;
    Result.Checked := AChecked;
  finally
    EndUpdate;
  end;
end;

procedure TACLCheckComboBoxItems.EnumChecked(AProc: TConsumerC<TACLCheckComboBoxItem>);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if Items[I].Checked then
      AProc(Items[I]);
  end;
end;

function TACLCheckComboBoxItems.GetClass: TACLImageComboBoxItemClass;
begin
  Result := TACLCheckComboBoxItem;
end;

function TACLCheckComboBoxItems.GetItem(Index: Integer): TACLCheckComboBoxItem;
begin
  Result := TACLCheckComboBoxItem(inherited Items[Index]);
end;

function TACLCheckComboBoxItems.GetState: TCheckBoxState;
var
  LHasChecked, LHasUnchecked: Boolean;
  I: Integer;
begin
  LHasChecked := False;
  LHasUnchecked := False;
  for I := 0 to Count - 1 do
  begin
    if Items[I].Checked then
      LHasChecked := True
    else
      LHasUnchecked := True;
    if LHasUnchecked and LHasChecked then Break;
  end;
  Result := TCheckBoxState.Create(LHasChecked, LHasUnchecked);
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

procedure TACLCheckComboBoxItems.UpdateCore(Item: TCollectionItem);
begin
  TACLCheckComboBox(ComboBox).UpdateText; // before change
  inherited;
end;

{ TACLCheckComboBoxDropDown }

constructor TACLCheckComboBoxDropDown.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Outside of the begin/endupdate
  List.OnNodeChecked := HandlerItemCheck;
  List.OnUpdateState := HandlerUpdateState;
end;

procedure TACLCheckComboBoxDropDown.HandlerItemCheck(Sender: TObject; AItem: TACLTreeListNode);
begin
  TACLCheckComboBoxItem(AItem.Data).Checked := AItem.Checked;
end;

procedure TACLCheckComboBoxDropDown.HandlerUpdateState(Sender: TObject);
begin
  if List.IsUpdateLocked then
    TACLCheckComboBox(Owner).Items.BeginUpdate
  else
    TACLCheckComboBox(Owner).Items.EndUpdate;
end;

{ TACLCustomCombo }

constructor TACLCheckComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TACLCheckComboBoxItems.Create(Self);
  FSeparator := ';';
end;

destructor TACLCheckComboBox.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

function TACLCheckComboBox.CreateDropDownWindow: TACLPopupWindow;
begin
  Result := TACLCheckComboBoxDropDown.Create(Self);
end;

procedure TACLCheckComboBox.DoPrepareDropDownList(AList: TACLBasicDropDownList);
var
  LIndex: Integer;
  LItem: TACLCheckComboBoxItem;
  LNode: TACLTreeListNode;
begin
  AList.OptionsView.CheckBoxes := True;
  AList.OptionsView.Nodes.Images := Images;
  for LIndex := 0 to Count - 1 do
  begin
    LItem := Items.Items[LIndex];
    LNode := AList.Add(DoGetItemDisplayName(LIndex, LItem.Text));
    LNode.ImageIndex := LItem.ImageIndex;
    LNode.Checked := LItem.Checked;
    LNode.Data := LItem;
  end;
  if AList.RootNode.ChildrenCount > 1 then
  begin
    AList.OptionsView.Columns.AutoWidth := True;
    AList.OptionsView.Columns.Visible := True;
    AList.Columns.Add;
  end;
  if Assigned(OnPrepareDropDownList) then
    OnPrepareDropDownList(Self, AList);
end;

function TACLCheckComboBox.GetItems: TACLCheckComboBoxItems;
begin
  Result := TACLCheckComboBoxItems(FItems);
end;

procedure TACLCheckComboBox.SetTextCore(const AText: string);
var
  LItem: TACLCheckComboBoxItem;
  LStrings: TStringDynArray;
  I: Integer;
begin
  Items.BeginUpdate;
  try
    Items.State := cbUnchecked;
    acSplitString(AText, Separator, LStrings);
    for I := 0 to Length(LStrings) - 1 do
    begin
      if Items.FindByText(LStrings[I], LItem) then
        LItem.Checked := True;
    end;
    UpdateText;
  finally
    Items.EndUpdate;
  end;
end;

function TACLCheckComboBox.IsSeparatorStored: Boolean;
begin
  Result := FSeparator <> ';';
end;

procedure TACLCheckComboBox.SetItems(AValue: TACLCheckComboBoxItems);
begin
  Items.Assign(AValue);
end;

procedure TACLCheckComboBox.SetSeparator(AValue: Char);
begin
  if FSeparator <> AValue then
  begin
    FSeparator := AValue;
    UpdateText;
  end;
end;

procedure TACLCheckComboBox.UpdateText;
var
  LBuilder: TACLStringBuilder;
begin
  LBuilder := TACLStringBuilder.Get;
  try
    Items.EnumChecked(
      procedure (const Item: TACLCheckComboBoxItem)
      begin
        LBuilder.Append(Item.Text).Append(Separator);
      end);
    FEditBox.Text := LBuilder.ToString;
  finally
    LBuilder.Release;
  end;
  Invalidate;
end;

end.
