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
unit ACL.UI.DesignTime.Reg;

{$I ACL.Config.inc}
{$R ACL.UI.DesignTime.Reg.res}

interface

uses
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}Menus,
  // System
  {System.}Classes,
  {System.}TypInfo,
  {System.}SysUtils,
  // Designer
{$IFDEF FPC}
  ComponentEditors,
  LazIDEIntf,
  PropEdits,
{$ELSE}
  DesignEditors,
  DesignIntf,
  FiltEdit,
  TreeIntf,
  VCLEditors,
  VCLSprigs,
{$ENDIF}
  // ACL
  ACL.UI.DesignTime.PropEditors;

const
  sACLComponentsPage = 'ACL';

procedure Register;
implementation

uses
  System.UITypes,
  // ACL
  ACL.Timers,
  ACL.UI.Application,
  ACL.UI.Controls.ActivityIndicator,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Bevel,
  ACL.UI.Controls.BindingDiagram,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.Calendar,
  ACL.UI.Controls.Category,
  ACL.UI.Controls.ColorPalette,
  ACL.UI.Controls.ColorPicker,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.CheckComboBox,
  ACL.UI.Controls.DateTimeEdit,
  ACL.UI.Controls.Docking,
  ACL.UI.Controls.DropDown,
  ACL.UI.Controls.FormattedLabel,
  ACL.UI.Controls.HexView,
  ACL.UI.Controls.ImageComboBox,
  ACL.UI.Controls.Images,
  ACL.UI.Controls.GroupBox,
  ACL.UI.Controls.Labels,
  ACL.UI.Controls.MagnifierGlass,
  ACL.UI.Controls.Memo,
  ACL.UI.Controls.ObjectInspector,
  ACL.UI.Controls.Panel,
  ACL.UI.Controls.ProgressBar,
  ACL.UI.Controls.ProgressBox,
  ACL.UI.Controls.Scene2D,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Controls.ScrollBox,
  ACL.UI.Controls.SearchBox,
  ACL.UI.Controls.Slider,
  ACL.UI.Controls.ShellTreeView,
  ACL.UI.Controls.Splitter,
  ACL.UI.Controls.SpinEdit,
  ACL.UI.Controls.TabControl,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Controls.TimeEdit,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Dialogs,
  ACL.UI.DropTarget,
  ACL.UI.Forms,
  ACL.UI.ImageList,
  ACL.UI.Insight,
  ACL.UI.Menus,
  ACL.UI.Resources,
  ACL.UI.TrayIcon,
  ACL.Utils.Common;

{$IFNDEF FPC}
type
  TACLDockGroupSprig = class(TWinControlSprig)
  public
    function Ghosted: Boolean; override;
    function UniqueName: string; override;
  end;

function TACLDockGroupSprig.Ghosted: Boolean;
begin
  Result := True;
end;

function TACLDockGroupSprig.UniqueName: string;
begin
  Result := '(Group)';
end;
{$ENDIF}

procedure HideProperties(AClass: TClass; const PropertyNames: array of string);
var
  APropInfo: PPropInfo;
  I: Integer;
begin
  for I := 0 to Length(PropertyNames) - 1 do
  begin
    APropInfo := GetPropInfo(AClass, PropertyNames[I]);
    if APropInfo <> nil then
      RegisterPropertyEditor(APropInfo.PropType{$IFNDEF FPC}^{$ENDIF}, AClass, PropertyNames[I], nil);
  end;
end;

procedure Register;
begin
{$IFNDEF FPC}
  // Modules
  RegisterCustomModule(TACLForm, TCustomModule);
  RegisterCustomModule(TACLLocalizableForm, TCustomModule);
{$ENDIF}

  // General
  RegisterComponents(sACLComponentsPage, [TACLApplicationController, TACLUIInsightButton]);
  RegisterPropertyEditor(TypeInfo(Integer), TACLApplicationController, 'TargetDPI', TACLDPIPropertyEditor);
  RegisterComponents(sACLComponentsPage, [TACLTrayIcon, TACLDropTarget, TACLTimer]);

  // Core
  RegisterComponents(sACLComponentsPage, [TACLResourceCollection]);
  RegisterComponentEditor(TACLResourceCollection, TACLResourceCollectionEditor);
  RegisterPropertyEditor(TypeInfo(Boolean), TACLResourceTexture, 'Overriden', TACLResourceTextureDataProperty);
  RegisterPropertyEditor(TypeInfo(string), TACLGlyph, 'ID', nil);
  RegisterPropertyEditor(TypeInfo(string), TACLResource, 'ID', TACLResourceIDProperty);
  RegisterPropertyEditor(TypeInfo(string), TACLResourceCollectionItem, 'ResourceClassName', nil);
  RegisterPropertyEditor(TypeInfo(string), TACLResourceFont, 'ColorID', TACLResourceFontColorIDProperty);
  RegisterPropertyEditor(TypeInfo(TACLResource), TACLResourceCollectionItem, 'Resource', TACLResourceCollectionItemResourceProperty);
  RegisterPropertyEditor(TypeInfo(TACLResourceColor), nil, '', TACLResourceColorProperty);
  RegisterPropertyEditor(TypeInfo(TACLResourceFont), nil, '', TACLResourceFontProperty);
  RegisterPropertyEditor(TypeInfo(TACLResourceMargins), nil, '', TACLResourceMarginsProperty);
  RegisterPropertyEditor(TypeInfo(TACLResourceTexture), nil, '', TACLResourceTextureProperty);
  RegisterPropertyEditor(TypeInfo(TAlphaColor), nil, '', TAlphaColorPropertyEditor);
  RegisterPropertyEditor(TypeInfo(TAlphaColor), TACLResource, '', TAlphaColorPropertyEditor);

  // Dialogs
  RegisterComponents(sACLComponentsPage, [TACLFileDialog]);
  RegisterPropertyEditor(TypeInfo(string), TACLFileDialog, 'Filter',
    {$IFDEF FPC}TFileDlgFilterProperty{$ELSE}TFilterProperty{$ENDIF});

  // Statics
  RegisterComponents(sACLComponentsPage, [TACLBevel, TACLActivityIndicator]);
  RegisterComponents(sACLComponentsPage, [TACLLabel, TACLValidationLabel]);
  RegisterPropertyEditor(TypeInfo(TCaption), TACLLabel, 'Caption', TACLMultiLineStringEditor);

  // FormattedLabel
  RegisterComponents(sACLComponentsPage, [TACLFormattedLabel]);
  RegisterPropertyEditor(TypeInfo(string), TACLFormattedLabel, 'Caption', TACLMultiLineStringEditor);

  // Buttons
  RegisterPropertyEditor(TypeInfo(TImageIndex), TACLButton, 'ImageIndex', TACLImageIndexProperty);
  RegisterComponents(sACLComponentsPage, [TACLButton, TACLCheckBox, TACLRadioBox]);

  // Menus
  HideProperties(TACLPopupMenu, ['OnChange']);
  RegisterNoIcon([TACLMenuItem, TACLMenuItemLink, TACLMenuListItem]);
  RegisterComponents(sACLComponentsPage, [TACLPopupMenu, TACLMainMenu]);
  RegisterComponentEditor(TACLMainMenu, TACLMainMenuEditor);
  RegisterComponentEditor(TACLPopupMenu, TACLPopupMenuEditor);
  RegisterPropertyEditor(TypeInfo(TMenuItem), TACLPopupMenu, 'Items', TACLMenuPropertyEditor);

  // Images
  RegisterComponents(sACLComponentsPage, [TACLImageBox, TACLImageList, TACLSubImageSelector]);
  RegisterComponentEditor(TACLImageList, TACLImageListEditor);
  RegisterPropertyEditor(TypeInfo(Integer), TACLImageList, 'SourceDPI', TACLDPIPropertyEditor);
  RegisterPropertyEditor(TypeInfo(TACLImagePicture), TACLImageBox, 'Picture', TACLImagePictureProperty);
  RegisterPropertyEditor(TypeInfo(TImageIndex), TACLImagePictureImageList, 'ImageIndex', TACLImageIndexProperty);
  RegisterPropertyEditor(TypeInfo(string), TACLImageBox, 'PictureClassName', nil);

  // Scene2D
  RegisterComponents(sACLComponentsPage, [TACLPaintBox2D]);

  // Slider
  RegisterComponents(sACLComponentsPage, [TACLSlider]);

  // Splitter
  RegisterComponents(sACLComponentsPage, [TACLSplitter]);

  // ProgressBar
  RegisterComponents(sACLComponentsPage, [TACLProgressBar, TACLProgressBox]);

  // Containers
  RegisterComponents(sACLComponentsPage, [TACLPanel, TACLGroupBox, TACLCategory]);

  // ColorPickers
  RegisterComponents(sACLComponentsPage, [TACLColorPalette, TACLColorPicker]);

  // Calendar
  RegisterComponents(sACLComponentsPage, [TACLCalendar]);

  // Magnifier Glass
  RegisterComponents(sACLComponentsPage, [TACLMagnifierGlass]);

  // ScrollBar
  RegisterComponents(sACLComponentsPage, [TACLScrollBar, TACLScrollBox]);

  // HexView
  RegisterComponents(sACLComponentsPage, [TACLHexView]);

  // TreeList
  RegisterComponents(sACLComponentsPage, [TACLTreeList]);
  RegisterComponentEditor(TACLTreeList, TACLTreeListComponentEditor);
  RegisterSelectionEditor(TACLTreeList, TACLTreeListSelectionEditor);
  RegisterPropertyEditor(TypeInfo(TImageIndex),
    TACLTreeListColumn, 'ImageIndex', TACLTreeListColumnImageIndexProperty);
  HideProperties(TACLTreeList, ['OnEditApply']);

  // ObjectInspector
  RegisterComponents(sACLComponentsPage, [TACLObjectInspector]);

  // BindingDiagram
  RegisterComponents(sACLComponentsPage, [TACLBindingDiagram]);
  RegisterSelectionEditor(TACLBindingDiagram, TACLBindingDiagramSelectionEditor);

  // Editors
  HideProperties(TACLSearchEditStyleButton, [
    'ColorText', 'ColorTextDisabled', 'ColorTextHover', 'ColorTextPressed']);
  RegisterComponents(sACLComponentsPage, [TACLEdit, TACLSearchEdit, TACLSpinEdit,
    TACLTimeEdit, TACLDropDown, TACLComboBox, TACLCheckComboBox, TACLImageComboBox,
    TACLDateTimeEdit, TACLMemo]);
  RegisterPropertyEditor(TypeInfo(TImageIndex),
    TACLDropDown, 'ImageIndex', TACLDropDownImageIndexProperty);
  RegisterPropertyEditor(TypeInfo(TImageIndex),
    TACLEditButton, 'ImageIndex', TACLEditButtonImageIndexProperty);
  RegisterPropertyEditor(TypeInfo(TImageIndex),
    TACLImageComboBoxItem, 'ImageIndex', TACLImageComboBoxImageIndexProperty);

  // Tabs
  RegisterComponents(sACLComponentsPage, [TACLTabControl, TACLPageControl]);
  RegisterComponentEditor(TACLPageControl, TACLPageControlEditor);
  RegisterComponentEditor(TACLPageControlPage, TACLPageControlEditor);

  // Shell
  RegisterComponents(sACLComponentsPage, [TACLShellTreeView]);

  // Docking
  RegisterComponents('ACL', [TACLDockSite, TACLDockPanel]);
{$IFNDEF FPC}
  RegisterSprigType(TACLDockGroup, TACLDockGroupSprig);
  RegisterSprigType(TACLDockSite, TComponentSprig);
{$ENDIF}
end;

end.
