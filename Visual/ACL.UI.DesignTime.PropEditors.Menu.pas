{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*           Menus Property Editor           *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.DesignTime.PropEditors.Menu;

{$I ACL.Config.inc}

{$DEFINE DESIGNER_AVAILABLE}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Classes,
  System.ImageList,
  System.Math,
  System.SysUtils,
  System.Types,
  System.Variants,
  // Vcl
{$IFDEF DESIGNER_AVAILABLE}
  DesignIntf,
  DesignWindows,
{$ENDIF}
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.Menus,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Images,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.Options,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Dialogs,
  ACL.UI.DropSource,
  ACL.UI.DropTarget,
  ACL.UI.Forms,
  ACL.UI.ImageList,
  ACL.UI.Menus,
  ACL.UI.Resources;


type
  { TACLMenuEditorDialog }


  TACLMenuEditorDialog = class({$IFDEF DESIGNER_AVAILABLE}TDesignWindow{$ELSE}TACLForm{$ENDIF})
    lvItems: TACLTreeList;
    miCreateItem: TMenuItem;
    miCreateLink: TMenuItem;
    miCreateList: TMenuItem;
    miCreateSeparator: TMenuItem;
    miDelete: TACLMenuItem;
    miLine1: TMenuItem;
    pmMenu: TACLPopupMenu;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lvItemsCustomDrawNodeCell(Sender: TObject; ACanvas: TCanvas; const R: TRect;
      ANode: TACLTreeListNode; AColumn: TACLTreeListColumn; var AHandled: Boolean);
    procedure lvItemsDragSortingNodeDrop(Sender: TObject; ANode: TACLTreeListNode;
      AMode: TACLTreeListDropTargetInsertMode; var AHandled: Boolean);
    procedure lvItemsFocusedNodeChanged(Sender: TObject);
    procedure miCreateItemClick(Sender: TObject);
    procedure miCreateLinkClick(Sender: TObject);
    procedure miCreateListClick(Sender: TObject);
    procedure miCreateSeparatorClick(Sender: TObject);
    procedure miDeleteClick(Sender: TObject);
  strict private
    class var FInstance: TACLMenuEditorDialog;
  strict private
    FMenu: TACLPopupMenu;

    procedure CreateItem(AItemClass: TMenuItemClass; const ACaption: string = '');
    procedure PopulateTree;
  protected
    procedure Initialize(AMenu: TACLPopupMenu);
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    class procedure Execute(AMenu: TACLPopupMenu{$IFDEF DESIGNER_AVAILABLE}; ADesigner: IDesigner{$ENDIF});
  {$IFDEF DESIGNER_AVAILABLE}
    procedure ItemsModified(const ADesigner: IDesigner); override;
    procedure SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections); override;
  {$ENDIF}
  end;

implementation

uses
  ACL.Classes;

{$R *.dfm}

{ TACLMenuEditorDialog }

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

procedure TACLMenuEditorDialog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  FInstance := nil;
end;

procedure TACLMenuEditorDialog.CreateItem(AItemClass: TMenuItemClass; const ACaption: string);
var
  AItem: TMenuItem;
  AMenu: TMenuItem;
begin
  AMenu := lvItems.FocusedNodeData;
  AItem := AItemClass.Create(FMenu.Owner);
  AItem.Caption := ACaption;
{$IFDEF DESIGNER_AVAILABLE}
  AItem.Name := Designer.UniqueName('N');
{$ENDIF}
  AMenu.Parent.Insert(AMenu.MenuIndex + 1, AItem);
  PopulateTree;
  lvItems.FocusedNodeData := AItem;
end;

procedure TACLMenuEditorDialog.Initialize(AMenu: TACLPopupMenu);
begin
  Caption := AMenu.Name;
  acComponentFieldSet(FMenu, Self, AMenu);
  lvItems.OptionsView.Nodes.Images := FMenu.Images;
  PopulateTree;
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
  begin
    ANode.Data := AItem;
    for var I := 0 to AItem.Count - 1 do
      ProcessLevel(ANode.AddChild, AItem.Items[I]);
  end;

begin
  lvItems.BeginUpdate;
  try
    lvItems.Clear;
    for var I := 0 to FMenu.Items.Count - 1 do
      ProcessLevel(lvItems.RootNode.AddChild, FMenu.Items[I]);
  finally
    lvItems.EndUpdate;
  end;
end;

{$IFDEF DESIGNER_AVAILABLE}
procedure TACLMenuEditorDialog.ItemsModified(const ADesigner: IDesigner);
begin
  lvItems.Invalidate;
end;

procedure TACLMenuEditorDialog.SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections);
begin
  if ASelection.Count > 0 then
    lvItems.FocusedNodeData := ASelection.Items[0]
  else
    lvItems.FocusedNodeData := nil;
end;
{$ENDIF}

procedure TACLMenuEditorDialog.lvItemsCustomDrawNodeCell(Sender: TObject; ACanvas: TCanvas;
  const R: TRect; ANode: TACLTreeListNode; AColumn: TACLTreeListColumn; var AHandled: Boolean);
var
  AItem: TMenuItem;
begin
  AItem := ANode.Data;
  ANode.ImageIndex := AItem.ImageIndex;
  if AItem is TACLMenuItem then
    ANode.Caption := AItem.ToString
  else
    ANode.Caption := AItem.Caption;
end;

procedure TACLMenuEditorDialog.lvItemsDragSortingNodeDrop(Sender: TObject;
  ANode: TACLTreeListNode; AMode: TACLTreeListDropTargetInsertMode; var AHandled: Boolean);
var
  AIndex: Integer;
  ASourceMenu: TMenuItem;
  ATargetMenu: TMenuItem;
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
end;

procedure TACLMenuEditorDialog.lvItemsFocusedNodeChanged(Sender: TObject);
begin
{$IFDEF DESIGNER_AVAILABLE}
  if lvItems.FocusedNodeData <> nil then
    Designer.SelectComponent(lvItems.FocusedNodeData);
{$ENDIF}
end;

procedure TACLMenuEditorDialog.miCreateItemClick(Sender: TObject);
begin
  CreateItem(TACLMenuItem);
end;

procedure TACLMenuEditorDialog.miCreateLinkClick(Sender: TObject);
begin
  CreateItem(TACLMenuItemLink);
end;

procedure TACLMenuEditorDialog.miCreateListClick(Sender: TObject);
begin
  CreateItem(TACLMenuListItem);
end;

procedure TACLMenuEditorDialog.miCreateSeparatorClick(Sender: TObject);
begin
  CreateItem(TMenuItem, '-');
end;

procedure TACLMenuEditorDialog.miDeleteClick(Sender: TObject);
begin
  TObject(lvItems.FocusedNodeData).Free;
  lvItems.DeleteSelected;
end;

end.
