﻿{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*        Register Components Helper         *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.DesignTime.Reg;

{$I ACL.Config.inc}
{$R ACL.UI.DesignTime.Reg.res}

interface

uses
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.Menus,
  // System
  System.Classes,
  System.Types,
  System.TypInfo,
  System.UITypes,
  // Designer
  DesignEditors,
  DesignIntf,
  FiltEdit,
  TreeIntf,
  VCLEditors,
  // ACL
  ACL.UI.DesignTime.PropEditors;

const
  sACLComponentsPage = 'ACL';

procedure Register;
implementation

uses
  System.Math,
  System.SysUtils,
  // Vcl
  Vcl.Controls,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.Geometry,
  ACL.Graphics.Ex.Gdip,
  ACL.UI.Application,
  ACL.UI.Controls.ActivityIndicator,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Bevel,
  ACL.UI.Controls.BindingDiagram,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.Calendar,
  ACL.UI.Controls.Category,
  ACL.UI.Controls.CheckComboBox,
  ACL.UI.Controls.ColorPalette,
  ACL.UI.Controls.ColorPicker,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.DateTimeEdit,
  ACL.UI.Controls.Docking,
  ACL.UI.Controls.DropDown,
  ACL.UI.Controls.FormattedLabel,
  ACL.UI.Controls.GroupBox,
  ACL.UI.Controls.HexView,
  ACL.UI.Controls.ImageComboBox,
  ACL.UI.Controls.Images,
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
  ACL.UI.Controls.ShellTreeView,
  ACL.UI.Controls.Slider,
  ACL.UI.Controls.SpinEdit,
  ACL.UI.Controls.Splitter,
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
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

type
  TACLDockGroupSprig = class(TComponentSprig)
  public
    function Ghosted: Boolean; override;
    function UniqueName: string; override;
  end;

{ TACLDockGroupSprig }

function TACLDockGroupSprig.Ghosted: Boolean;
begin
  Result := True;
end;

function TACLDockGroupSprig.UniqueName: string;
begin
  Result := '(Group)';
end;

procedure HideProperties(AClass: TClass; const PropertyNames: array of string);
var
  APropInfo: PPropInfo;
begin
  for var I := 0 to Length(PropertyNames) - 1 do
  begin
    APropInfo := GetPropInfo(AClass, PropertyNames[I]);
    if APropInfo = nil then
      raise Exception.CreateFmt('The %s.%s was not found', [AClass.ClassName, PropertyNames[I]]);
    RegisterPropertyEditor(APropInfo.PropType^, AClass, PropertyNames[I], nil);
  end;
end;

procedure Register;
begin
  // Forms
  RegisterComponents(sACLComponentsPage, [TACLApplicationController]);
  RegisterPropertyEditor(TypeInfo(Integer), TACLApplicationController, 'TargetDPI', TACLDPIPropertyEditor);
  RegisterCustomModule(TACLForm, TCustomModule);
  RegisterCustomModule(TACLLocalizableForm, TCustomModule);

  // Common
  RegisterComponents(sACLComponentsPage, [TACLTrayIcon, TACLDropTarget, TACLTimer]);
  RegisterPropertyEditor(TypeInfo(Integer), TACLImageList, 'SourceDPI', TACLDPIPropertyEditor);

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

  // FormattedLabel
  RegisterComponents(sACLComponentsPage, [TACLFormattedLabel]);
  RegisterPropertyEditor(TypeInfo(UnicodeString), TACLFormattedLabel, 'Caption', TACLMultiLineStringEditor);

  // Dialogs
  RegisterComponents(sACLComponentsPage, [TACLFileDialog]);
  RegisterPropertyEditor(TypeInfo(String), TACLFileDialog, 'Filter', TFilterProperty);

  // ActivityIndicator
  RegisterComponents(sACLComponentsPage, [TACLActivityIndicator]);

  // Statics
  RegisterComponents(sACLComponentsPage, [TACLBevel, TACLLabel, TACLValidationLabel]);
  RegisterPropertyEditor(TypeInfo(TCaption), TACLLabel, 'Caption', TACLMultiLineStringEditor);

  // Buttons
  RegisterPropertyEditor(TypeInfo(TImageIndex), TACLButton, 'ImageIndex', TACLImageIndexProperty);
  RegisterComponents(sACLComponentsPage, [TACLButton, TACLCheckBox, TACLRadioBox, TACLUIInsightButton]);

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
  RegisterPropertyEditor(TypeInfo(TACLImagePicture), TACLImageBox, 'Picture', TACLImagePictureProperty);
  RegisterPropertyEditor(TypeInfo(TImageIndex), TACLImagePictureImageList, 'ImageIndex', TACLImageIndexProperty);
  RegisterPropertyEditor(TypeInfo(string), TACLImageBox, 'PictureClassName', nil);

  // Slider
  RegisterComponents(sACLComponentsPage, [TACLSlider]);

  // Splitter
  RegisterComponents(sACLComponentsPage, [TACLSplitter]);

  // ProgressBar
  RegisterComponents(sACLComponentsPage, [TACLProgressBar, TACLProgressBox]);

  // Groups
  RegisterComponents(sACLComponentsPage, [TACLPanel, TACLGroupBox, TACLCategory]);

  // ScrollBar
  RegisterComponents(sACLComponentsPage, [TACLScrollBar, TACLScrollBox]);

  // ObjectInspector
  RegisterComponents(sACLComponentsPage, [TACLObjectInspector]);

  // Magnifier Glass
  RegisterComponents(sACLComponentsPage, [TACLMagnifierGlass]);

  // BindingDiagram
  RegisterComponents(sACLComponentsPage, [TACLBindingDiagram]);
  RegisterSelectionEditor(TACLBindingDiagram, TACLBindingDiagramSelectionEditor);

  // Editors
  HideProperties(TACLSearchEditStyleButton, ['ColorText', 'ColorTextDisabled', 'ColorTextHover', 'ColorTextPressed']);
  RegisterPropertyEditor(TypeInfo(TImageIndex), TACLEditButton, 'ImageIndex', TACLEditButtonImageIndexProperty);
  RegisterComponents(sACLComponentsPage, [TACLSearchEdit, TACLEdit, TACLSpinEdit, TACLMemo, TACLTimeEdit, TACLDateTimeEdit,
    TACLDropDown, TACLComboBox, TACLCheckComboBox, TACLImageComboBox, TACLColorPicker, TACLColorPalette, TACLCalendar]);
  RegisterPropertyEditor(TypeInfo(TImageIndex), TACLDropDown, 'ImageIndex', TACLDropDownImageIndexProperty);

  // HexView
  RegisterComponents(sACLComponentsPage, [TACLHexView]);

  // Shell
  RegisterComponents(sACLComponentsPage, [TACLShellTreeView]);

  // Tabs
  RegisterComponents(sACLComponentsPage, [TACLTabControl, TACLPageControl]);
  RegisterComponentEditor(TACLPageControl, TACLPageControlEditor);
  RegisterComponentEditor(TACLPageControlPage, TACLPageControlEditor);

  // TreeList
  RegisterComponents(sACLComponentsPage, [TACLTreeList]);
  RegisterComponentEditor(TACLTreeList, TACLTreeListComponentEditor);
  RegisterSelectionEditor(TACLTreeList, TACLTreeListSelectionEditor);
  RegisterPropertyEditor(TypeInfo(TImageIndex), TACLTreeListColumn, 'ImageIndex', TACLTreeListColumnImageIndexProperty);
  HideProperties(TACLTreeList, ['OnEditApply']);

  // Scene2D
  RegisterComponents(sACLComponentsPage, [TACLPaintBox2D]);

  // Docking
  RegisterComponents('ACL', [TACLDockPanel, TACLDockSite]);
  RegisterSprigType(TACLDockGroup, TACLDockGroupSprig);
  RegisterSprigType(TACLDockSite, TComponentSprig);
end;

end.
