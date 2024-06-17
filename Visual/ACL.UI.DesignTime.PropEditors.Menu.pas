////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Design Time Routines
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.DesignTime.PropEditors.Menu;

{$I ACL.Config.inc}

{$IFNDEF FPC}
  {$DEFINE DESIGNER_AVAILABLE}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLProc,
  LCLType,
{$ELSE}
  Winapi.Messages,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Math,
  {System.}SysUtils,
  {System.}Variants,
  // Designer
{$IFDEF DESIGNER_AVAILABLE}
  DesignIntf,
  DesignWindows,
{$ENDIF}
  // Vcl
  {Vcl.}ActnList,
  {Vcl.}Controls,
  {Vcl.}Dialogs,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}Menus,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Graphics,
  ACL.Graphics.Images,
  ACL.Graphics.SkinImage,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.Options,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Controls.Panel,
  ACL.UI.Dialogs,
  ACL.UI.Forms,
  ACL.UI.Menus,
  ACL.UI.Resources;

type

  { TACLMenuEditorDialog }

  TACLMenuEditorDialog = class({$IFDEF DESIGNER_AVAILABLE}TDesignWindow{$ELSE}TACLForm{$ENDIF})
    acCreateItem: TAction;
    acCreateSubItem: TAction;
    acDelete: TAction;
    acMoveDown: TAction;
    acMoveUp: TAction;
    Actions: TActionList;
    btnCreateItem: TACLButton;
    btnCreateSubItem: TACLButton;
    btnDelete: TACLButton;
    btnMoveDown: TACLButton;
    btnMoveUp: TACLButton;
    lvItems: TACLTreeList;
    miCreateItem: TMenuItem;
    miCreateSubItem: TACLMenuItem;
    miDelete: TACLMenuItem;
    miLine0: TACLMenuItem;
    miLine1: TMenuItem;
    miMoveDown: TACLMenuItem;
    miMoveUp: TACLMenuItem;
    pmMenu: TACLPopupMenu;
    pnlBottom: TACLPanel;
    pnlRight: TACLPanel;

    procedure acCreateItemExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvItemsDragSortingNodeDrop(Sender: TObject; ANode: TACLTreeListNode;
      AMode: TACLTreeListDropTargetInsertMode; var AHandled: Boolean);
    procedure lvItemsFocusedNodeChanged(Sender: TObject);
    procedure lvItemsGetNodeCellDisplayText(Sender: TObject;
      ANode: TACLTreeListNode; AValueIndex: Integer; var AText: string);
    procedure acDeleteExecute(Sender: TObject);
    procedure acDeleteUpdate(Sender: TObject);
    procedure acMoveExecute(Sender: TObject);
    procedure acMoveUpdate(Sender: TObject);
  strict private
    class var FInstance: TACLMenuEditorDialog;
  strict private type
    TCommand = TPair<TMenuItemClass, string>;
  strict private
    FCommands: TList<TCommand>;
    FMenu: TACLPopupMenu;

    procedure CreateItem(AItemClass: TMenuItemClass;
      const ACaption: string = ''; ASubItem: Boolean = False);
    procedure InvokeCommand(Sender: TObject);
    procedure RegisterCommand(AItemClass: TMenuItemClass; const ATitle, ACaption: string);
    procedure PopulateTree;
  protected
    procedure Initialize(AMenu: TACLPopupMenu);
    procedure InitializeCommands;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    class procedure Execute(AMenu: TACLPopupMenu{$IFDEF DESIGNER_AVAILABLE}; ADesigner: IDesigner{$ENDIF});
  {$IFDEF DESIGNER_AVAILABLE}
    procedure ItemDeleted(const ADesigner: IDesigner; Item: TPersistent); override;
    procedure ItemInserted(const ADesigner: IDesigner; Item: TPersistent); override;
    procedure ItemsModified(const ADesigner: IDesigner); override;
    procedure SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections); override;
  {$ENDIF}
  end;

implementation

{$R *.dfm}

type
  TMenuItemAccess = class(TMenuItem);

{ TACLMenuEditorDialog }

{$IFDEF DESIGNER_AVAILABLE}
procedure TACLMenuEditorDialog.ItemDeleted(const ADesigner: IDesigner; Item: TPersistent);
begin
  inherited;
  if Item is TMenuItem then
    PopulateTree;
end;

procedure TACLMenuEditorDialog.ItemInserted(const ADesigner: IDesigner; Item: TPersistent);
begin
  inherited;
  if Item is TMenuItem then
    PopulateTree;
end;

procedure TACLMenuEditorDialog.ItemsModified(const ADesigner: IDesigner);
begin
  lvItems.Invalidate;
end;

procedure TACLMenuEditorDialog.SelectionChanged(
  const ADesigner: IDesigner; const ASelection: IDesignerSelections);
begin
  if ASelection.Count > 0 then
    lvItems.FocusedNodeData := ASelection.Items[0]
  else
    lvItems.FocusedNodeData := nil;
end;
{$ENDIF}

class procedure TACLMenuEditorDialog.Execute(
  AMenu: TACLPopupMenu {$IFDEF DESIGNER_AVAILABLE}; ADesigner: IDesigner{$ENDIF});
begin
  if FInstance = nil then
    FInstance := TACLMenuEditorDialog.Create(nil);
{$IFDEF DESIGNER_AVAILABLE}
  FInstance.Designer := ADesigner;
{$ENDIF}
  FInstance.Initialize(AMenu);
  FInstance.Show;
end;

procedure TACLMenuEditorDialog.CreateItem(
  AItemClass: TMenuItemClass; const ACaption: string; ASubItem: Boolean);
var
  AItem: TMenuItem;
  AMenu: TMenuItem;
begin
  AItem := AItemClass.Create(FMenu.Owner);
  AItem.Caption := ACaption;
{$IFDEF DESIGNER_AVAILABLE}
  AItem.Name := Designer.UniqueName('N');
{$ENDIF}

  AMenu := lvItems.FocusedNodeData;
  if AMenu = nil then
    FMenu.Items.Add(AItem)
  else if ASubItem then
    AMenu.Add(AItem)
  else
    AMenu.Parent.Insert(AMenu.MenuIndex + 1, AItem);

  PopulateTree;
  lvItems.FocusedNodeData := AItem;
end;

procedure TACLMenuEditorDialog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TACLMenuEditorDialog.FormCreate(Sender: TObject);
begin
  FCommands := TList<TCommand>.Create;
  Color := pnlRight.Style.ColorContent1.AsColor;
  InitializeCommands;
  pnlBottom.TabOrder := pnlRight.ControlCount;
end;

procedure TACLMenuEditorDialog.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FCommands);
  FInstance := nil;
end;

procedure TACLMenuEditorDialog.Initialize(AMenu: TACLPopupMenu);
begin
  Caption := AMenu.Name;
  acComponentFieldSet(FMenu, Self, AMenu);
  lvItems.OptionsView.Nodes.Images := FMenu.Images;
  PopulateTree;
end;

procedure TACLMenuEditorDialog.InitializeCommands;
begin
  RegisterCommand(TMenuItem, 'Separator', '-');
  RegisterCommand(TACLMenuListItem, 'List', '');
  RegisterCommand(TACLMenuItemLink, 'Link', '');
end;

procedure TACLMenuEditorDialog.InvokeCommand(Sender: TObject);
begin
  with FCommands[TComponent(Sender).Tag] do
    CreateItem(Key, Value);
end;

procedure TACLMenuEditorDialog.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;
  if (AOperation = opRemove) and (AComponent = FMenu) then
  begin
    FMenu := nil;
    Release;
  end;
end;

procedure TACLMenuEditorDialog.PopulateTree;

  procedure ProcessLevel(ANode: TACLTreeListNode; AItem: TMenuItem);
  var
    I: Integer;
  begin
    ANode.Data := AItem;
    ANode.Expanded := True;
    for I := 0 to AItem.Count - 1 do
      ProcessLevel(ANode.AddChild, AItem.Items[I]);
  end;

var
  I: Integer;
begin
  lvItems.BeginUpdate;
  try
    lvItems.Clear;
    for I := 0 to FMenu.Items.Count - 1 do
      ProcessLevel(lvItems.RootNode.AddChild, FMenu.Items[I]);
  finally
    lvItems.EndUpdate;
  end;
end;

procedure TACLMenuEditorDialog.RegisterCommand(
  AItemClass: TMenuItemClass; const ATitle, ACaption: string);
var
  LButton: TACLButton;
  LIndex: Integer;
  LMenuItem: TMenuItem;
begin
  LIndex := FCommands.Add(TCommand.Create(AItemClass, ACaption));
  LMenuItem := pmMenu.Items.AddItem('Create ' + ATitle, LIndex, InvokeCommand);
  LMenuItem.MenuIndex := miCreateSubItem.MenuIndex + FCommands.Count;
  LButton := TACLButton.Create(Self);
  LButton.Margins.Assign(btnCreateItem.Margins);
  LButton.AlignWithMargins := True;
  LButton.Align := btnCreateItem.Align;
  LButton.Parent := pnlRight;
  LButton.Caption := LMenuItem.Caption;
  LButton.Tag := LIndex;
  LButton.OnClick := InvokeCommand;
  LButton.Top := MaxWord;
end;

procedure TACLMenuEditorDialog.acCreateItemExecute(Sender: TObject);
begin
  CreateItem(TACLMenuItem, 'MenuItem', TComponent(Sender).Tag <> 0);
end;

procedure TACLMenuEditorDialog.acDeleteExecute(Sender: TObject);
var
  LData: TObject;
begin
  if lvItems.HasSelection then
  begin
    LData := lvItems.FocusedNodeData;
    lvItems.DeleteSelected;
    LData.Free;
  end;
end;

procedure TACLMenuEditorDialog.acDeleteUpdate(Sender: TObject);
begin
  acDelete.Enabled := lvItems.HasSelection;
end;

procedure TACLMenuEditorDialog.acMoveUpdate(Sender: TObject);
var
  LItem: TMenuItem;
begin
  LItem := lvItems.FocusedNodeData;
  TAction(Sender).Enabled := (LItem <> nil) and
    InRange(LItem.MenuIndex + TComponent(Sender).Tag, 0, LItem.Parent.Count - 1);
end;

procedure TACLMenuEditorDialog.acMoveExecute(Sender: TObject);
var
  LItem: TMenuItem;
begin
  if lvItems.HasSelection then
  begin
    LItem := lvItems.FocusedNodeData;
    LItem.MenuIndex := EnsureRange(LItem.MenuIndex + TComponent(Sender).Tag, 0, LItem.Parent.Count - 1);
    PopulateTree;
    lvItems.FocusedNodeData := LItem;
    acDesignerSetModified(FMenu);
  end;
end;

procedure TACLMenuEditorDialog.lvItemsDragSortingNodeDrop(Sender: TObject;
  ANode: TACLTreeListNode; AMode: TACLTreeListDropTargetInsertMode; var AHandled: Boolean);
var
  AIndex: Integer;
  ASourceMenu: TMenuItemAccess;
  ATargetMenu: TMenuItemAccess;
begin
  ATargetMenu := ANode.Data;
  ASourceMenu := lvItems.FocusedNodeData;
  case AMode of
    dtimInto:
      ASourceMenu.SetParentComponent(ATargetMenu);
    dtimAfter, dtimBefore:
      begin
        AIndex := ATargetMenu.MenuIndex;
        ASourceMenu.SetParentComponent(ATargetMenu.Parent);
        ASourceMenu.MenuIndex := AIndex + IfThen(AMode = dtimAfter, 1);
      end;
  else
    AHandled := True;
  end;
  acDesignerSetModified(FMenu);
end;

procedure TACLMenuEditorDialog.lvItemsFocusedNodeChanged(Sender: TObject);
begin
{$IFDEF DESIGNER_AVAILABLE}
  if lvItems.FocusedNodeData <> nil then
    Designer.SelectComponent(lvItems.FocusedNodeData);
{$ENDIF}
end;

procedure TACLMenuEditorDialog.lvItemsGetNodeCellDisplayText(
  Sender: TObject; ANode: TACLTreeListNode; AValueIndex: Integer; var AText: string);
var
  LItem: TMenuItem;
begin
  LItem := ANode.Data;
  if AValueIndex = 0 then
  begin
    if LItem is TACLMenuItem then
      AText := LItem.ToString
    else
      AText := LItem.Caption;

    if AText = '' then
      AText := LItem.Name;

    AText := StripHotkey(AText);
    ANode.ImageIndex := LItem.ImageIndex;
  end;
  if AValueIndex = 1 then
  begin
    if LItem.ShortCut <> scNone then
      AText := ShortCutToText(LItem.ShortCut)
    else
      AText := '';
  end;
end;

end.
