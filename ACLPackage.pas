{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit ACLPackage;

{$warn 5023 off : no warning about unused units}
interface

uses
  ACL.Classes, ACL.Classes.ByteBuffer, ACL.Classes.Collections, 
  ACL.Classes.StringList, ACL.Crypto, ACL.Expressions, 
  ACL.Expressions.FormatString, ACL.Expressions.Math, ACL.FastCode, 
  ACL.FileFormats.CSV, ACL.FileFormats.INI, ACL.FileFormats.XML, 
  ACL.FileFormats.XML.Reader, ACL.FileFormats.XML.Types, 
  ACL.FileFormats.XML.Writer, ACL.Geometry, ACL.Geometry.Utils, ACL.Graphics, 
  ACL.Graphics.Ex, ACL.Graphics.Ex.Cairo, ACL.Graphics.FontCache, 
  ACL.Graphics.Images, ACL.Graphics.Palette, ACL.Graphics.SkinImage, 
  ACL.Graphics.SkinImageSet, ACL.Graphics.TextLayout, 
  ACL.Graphics.TextLayout32, ACL.Hashes, ACL.MUI, ACL.Math, ACL.Math.Complex, 
  ACL.ObjectLinks, ACL.Parsers, ACL.Parsers.Ripper, ACL.SimpleIPC, 
  ACL.Threading, ACL.Threading.Pool, ACL.Threading.Sorting, ACL.Timers, 
  ACL.Utils.Clipboard, ACL.Utils.Common, ACL.Utils.DPIAware, ACL.Utils.Date, 
  ACL.Utils.Desktop, ACL.Utils.FileSystem, ACL.Utils.FileSystem.GIO, 
  ACL.Utils.Logger, ACL.Utils.Messaging, ACL.Utils.RTTI, ACL.Utils.Shell, 
  ACL.Utils.Stream, ACL.Utils.Strings, ACL.UI.AeroPeek, ACL.UI.Animation, 
  ACL.UI.Application, ACL.UI.Controls.ActivityIndicator, ACL.UI.Controls.Base, 
  ACL.UI.Controls.BaseEditors, ACL.UI.Controls.Bevel, 
  ACL.UI.Controls.BindingDiagram, ACL.UI.Controls.BindingDiagram.SubClass, 
  ACL.UI.Controls.BindingDiagram.Types, ACL.UI.Controls.Buttons, 
  ACL.UI.Controls.Calendar, ACL.UI.Controls.Category, 
  ACL.UI.Controls.CheckComboBox, ACL.UI.Controls.ColorPalette, 
  ACL.UI.Controls.ColorPicker, ACL.UI.Controls.ComboBox, 
  ACL.UI.Controls.CompoundControl, ACL.UI.Controls.CompoundControl.SubClass, 
  ACL.UI.Controls.DateTimeEdit, ACL.UI.Controls.Docking, 
  ACL.UI.Controls.DropDown, ACL.UI.Controls.FormattedLabel, 
  ACL.UI.Controls.GroupBox, ACL.UI.Controls.HexView, 
  ACL.UI.Controls.ImageComboBox, ACL.UI.Controls.Images, 
  ACL.UI.Controls.Labels, ACL.UI.Controls.MagnifierGlass, 
  ACL.UI.Controls.Memo, ACL.UI.Controls.ObjectInspector, 
  ACL.UI.Controls.ObjectInspector.PropertyEditors, ACL.UI.Controls.Panel, 
  ACL.UI.Controls.ProgressBar, ACL.UI.Controls.ProgressBox, 
  ACL.UI.Controls.Scene2D, ACL.UI.Controls.ScrollBar, 
  ACL.UI.Controls.ScrollBox, ACL.UI.Controls.SearchBox, 
  ACL.UI.Controls.ShellTreeView, ACL.UI.Controls.Slider, 
  ACL.UI.Controls.SpinEdit, ACL.UI.Controls.Splitter, 
  ACL.UI.Controls.TabControl, ACL.UI.Controls.TextEdit, 
  ACL.UI.Controls.TimeEdit, ACL.UI.Controls.TreeList, 
  ACL.UI.Controls.TreeList.Options, ACL.UI.Controls.TreeList.SubClass, 
  ACL.UI.Controls.TreeList.SubClass.DragAndDrop, 
  ACL.UI.Controls.TreeList.Types, ACL.UI.DesignTime.PropEditors, 
  ACL.UI.DesignTime.PropEditors.ImageList, ACL.UI.DesignTime.PropEditors.Menu, 
  ACL.UI.DesignTime.Reg, ACL.UI.Dialogs, ACL.UI.Dialogs.ColorPicker, 
  ACL.UI.Dialogs.FontPicker, ACL.UI.DropSource, ACL.UI.DropTarget, 
  ACL.UI.Forms, ACL.UI.HintWindow, ACL.UI.ImageList, ACL.UI.Insight, 
  ACL.UI.Menus, ACL.UI.Resources, ACL.UI.TrayIcon, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('ACL.UI.DesignTime.Reg', @ACL.UI.DesignTime.Reg.Register);
end;

initialization
  RegisterPackage('ACLPackage', @Register);
end.
