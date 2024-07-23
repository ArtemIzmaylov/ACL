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
unit ACL.UI.DesignTime.PropEditors;

{$I ACL.Config.inc}

{$IFNDEF FPC}
  {$DEFINE DESIGNER_CAN_CREATECOMPONENT}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}Types,
  {System.}TypInfo,
  {System.}SysUtils,
  System.UITypes,
  // Vcl
  {Vcl.}Dialogs,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}Menus,
  {Vcl.}Forms,
  // IDE
{$IFDEF FPC}
  ComponentEditors,
  LazIDEIntf,
  PropEdits,
{$ELSE}
  ColnEdit,
  DesignEditors,
  DesignIntf,
  VCLEditors,
{$ENDIF}
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.DropDown,
  ACL.UI.Controls.Images,
  ACL.UI.Controls.ImageComboBox,
  ACL.UI.Controls.TabControl,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Dialogs,
  ACL.UI.Dialogs.ColorPicker,
  ACL.UI.Dialogs.FontPicker,
  ACL.UI.Menus,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type
{$REGION ' FPC Base '}

{$IFNDEF FPC}
  TPropEditDrawState = Boolean;
{$ENDIF}

{$IFDEF FPC}
  IDesigner = TPropertyEditorHook;
  IDesignerSelections = TPersistentSelectionList;

  { TDesignWindow }

  TDesignWindow = class(TForm)
  strict private
    FDesigner: TPropertyEditorHook;
    procedure DoCompAdded(APersistent: TPersistent; Select: boolean);
    procedure DoCompDeleting(APersistent: TPersistent);
    procedure DoCompSelection(const ASelection: TPersistentSelectionList);
    procedure DoModified(Sender: TObject);
    procedure SetDesigner(AValue: TPropertyEditorHook);
  public
    procedure BeforeDestruction; override;
    procedure ItemDeleted(const ADesigner: IDesigner; Item: TPersistent); virtual;
    procedure ItemInserted(const ADesigner: IDesigner; Item: TPersistent); virtual;
    procedure ItemsModified(const ADesigner: IDesigner); virtual;
    procedure SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections); virtual;
    //# Properties
    property Designer: TPropertyEditorHook read FDesigner write SetDesigner;
  end;

  { TPropertyEditorHelper }

  TPropertyEditorHelper = class helper for TPropertyEditor
  public
    function Designer: TPropertyEditorHook;
  end;
{$ENDIF}

{$ENDREGION}

{$REGION ' General Properties '}

  { TAlphaColorPropertyEditor }

  TAlphaColorPropertyEditor = class(TOrdinalProperty
  {$IFNDEF FPC}
    , ICustomPropertyDrawing
    , ICustomPropertyDrawing80
  {$ENDIF})
  protected
    function IsAlphaSupported: Boolean; virtual;
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;

    class procedure DrawPreview(ACanvas: TCanvas; var ARect: TRect; AColor: TAlphaColor);
    // ICustomPropertyDrawing
    procedure PropDrawName(ACanvas: TCanvas;
      const ARect: TRect; ASelected: TPropEditDrawState); {$IFDEF FPC}override;{$ENDIF}
    procedure PropDrawValue(ACanvas: TCanvas;
      const ARect: TRect; ASelected: TPropEditDrawState); {$IFDEF FPC}override;{$ENDIF}
    // ICustomPropertyDrawing80
    function PropDrawNameRect(const ARect: TRect): TRect;
    function PropDrawValueRect(const ARect: TRect): TRect;
  end;

  { TACLImageIndexProperty }

  TACLImageIndexProperty = class(TIntegerProperty
  {$IFNDEF FPC}, ICustomPropertyListDrawing{$ENDIF})
  protected
    function GetImages: TCustomImageList; virtual;
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
    // ICustomPropertyListDrawing
  {$IFDEF FPC}
    procedure ListDrawValue(const AValue: ansistring; Index: Integer;
      ACanvas: TCanvas; const ARect: TRect; AState: TPropEditDrawState); override;
    procedure ListMeasureHeight(const AValue: ansistring; Index: Integer;
      ACanvas: TCanvas; var AHeight: Integer); override;
    procedure ListMeasureWidth(const AValue: ansistring; Index: Integer;
      ACanvas: TCanvas; var AWidth: Integer); override;
  {$ELSE}
    procedure ListDrawValue(const AValue: string;
      ACanvas: TCanvas; const ARect: TRect; AState: TPropEditDrawState);
    procedure ListMeasureHeight(const AValue: string;
      ACanvas: TCanvas; var AHeight: Integer);
    procedure ListMeasureWidth(const AValue: string;
      ACanvas: TCanvas; var AWidth: Integer);
  {$ENDIF}
    //# Properties
    property Images: TCustomImageList read GetImages;
  end;

  { TACLMultiLineStringEditor }

  TACLMultiLineStringEditor = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  { TACLSelectionEditor }

  TACLSelectionEditor = class(TSelectionEditor)
  public
  {$IFDEF FPC}
    procedure RequiresUnits(Proc: TGetStrProc); virtual;
  {$ENDIF}
  end;

{$ENDREGION}

{$REGION ' Resources '}

  { TACLResourceProperty }

  TACLResourceProperty = class abstract(TClassProperty
  {$IFNDEF FPC}
    , ICustomPropertyDrawing
    , ICustomPropertyDrawing80
  {$ENDIF})
  strict private
    function GetResource: TACLResource;
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    // ICustomPropertyDrawing
    procedure PropDrawName(ACanvas: TCanvas; const ARect: TRect;
      ASelected: TPropEditDrawState); {$IFDEF FPC}override;{$ENDIF}
    procedure PropDrawValue(ACanvas: TCanvas; const ARect: TRect;
      ASelected: TPropEditDrawState); {$IFDEF FPC}override; final;{$ENDIF}
    procedure PropDrawValueCore(ACanvas: TCanvas; var ARect: TRect); virtual;
    // ICustomPropertyDrawing80
    function PropDrawNameRect(const ARect: TRect): TRect;
    function PropDrawValueRect(const ARect: TRect): TRect; virtual;
    //# Properties
    property Resource: TACLResource read GetResource;
  end;

  { TACLResourceColorProperty }

  TACLResourceColorProperty = class(TACLResourceProperty)
  strict private
    function GetResource: TACLResourceColor;
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    procedure PropDrawValueCore(ACanvas: TCanvas; var ARect: TRect); override;
    function PropDrawValueRect(const ARect: TRect): TRect; override;
    //# Properties
    property Resource: TACLResourceColor read GetResource;
  end;

  { TACLResourceMarginsProperty }

  TACLResourceMarginsProperty = class(TACLResourceProperty);

  { TACLResourceTextureProperty }

  TACLResourceTextureProperty = class(TACLResourceProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

  { TACLResourceTextureDataProperty }

  TACLResourceTextureDataProperty = class(TOrdinalProperty)
  strict private
    function GetData: TACLResourceTexture;
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetName: {$IFDEF FPC}shortstring{$ELSE}string{$ENDIF}; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

  { TACLResourceIDProperty }

  TACLResourceIDProperty = class(TStringProperty)
  public const
    CmdOwnerPrefix = '@';
    CmdOverridePrefix = '<Override in ';
    CmdOverride = CmdOverridePrefix + '%s>';
    CmdReset = '<Reset To Defaults>';
  strict private
    FTempResourceCollections: TACLStringList;

    function GetCollectionOwner(AResource: TACLResource): TPersistent;
    function GetResourceCollectionsToOverride: TACLStringList;
    procedure GetResourceCollectionsProc(const S: string);
    procedure OverrideValue(const ACollectionName: string);
    procedure PopulateCommands(AResource: TACLResource; AList: TACLStringList);
    procedure PopulateResources(AResource: TACLResource; AList: TACLStringList);
  protected
    function GetResource: TACLResource; virtual;
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
    //# Properties
    property Resource: TACLResource read GetResource;
  end;

  { TACLResourceCollectionItemResourceProperty }

  TACLResourceCollectionItemResourceProperty = class(TClassProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

  { TACLResourceCollectionEditor }

  TACLResourceCollectionEditor = class(TComponentEditor)
  strict private const
    FileExt = '.aclres';
    FilterString = 'ACL Resource Collection (*' + FileExt + ')|*' + FileExt + ';';
  strict private
    procedure Load;
    procedure Save;
  public
    procedure Edit; override;
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  { TACLResourceFontProperty }

  TACLResourceFontProperty = class(TACLResourceProperty)
  strict private
    function GetResource: TACLResourceFont;
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    procedure PropDrawValueCore(ACanvas: TCanvas; var ARect: TRect); override;
    function PropDrawValueRect(const ARect: TRect): TRect; override;
    //# Properties
    property Resource: TACLResourceFont read GetResource;
  end;

  { TACLResourceFontColorIDProperty }

  TACLResourceFontColorIDProperty = class(TACLResourceIDProperty)
  public
    function GetResource: TACLResource; override;
  end;

{$ENDREGION}

{$REGION ' Controls '}

  { TACLBindingDiagramSelectionEditor }

  TACLBindingDiagramSelectionEditor = class(TACLSelectionEditor)
  public
    procedure RequiresUnits(Proc: TGetStrProc); override;
  end;

  { TACLDPIPropertyEditor }

  TACLDPIPropertyEditor = class(TIntegerProperty)
  strict private const
    Default = 'Default';
  protected
    function StringToValue(const AValue: string): Integer;
    function ValueToString(const AValue: Integer): string;
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const S: string); override;
  end;

  { TACLImageListEditor }

  TACLImageListEditor = class(TComponentEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  { TACLPictureProperty }

  TACLImagePictureProperty = class(TClassProperty)
  strict private
    function HasSubProperties: Boolean;
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

  { TACLPageControlEditor }

  TACLPageControlEditor = class(TComponentEditor)
  strict private
    procedure AddPage;
    procedure DeletePage;
  public
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

  { TACLDropDownImageIndexProperty }

  TACLDropDownImageIndexProperty = class(TACLImageIndexProperty)
  protected
    function GetImages: TCustomImageList; override;
  end;

  { TACLEditButtonImageIndexProperty }

  TACLEditButtonImageIndexProperty = class(TACLImageIndexProperty)
  protected
    function GetImages: TCustomImageList; override;
  end;

  { TACLImageComboBoxImageIndexProperty }

  TACLImageComboBoxImageIndexProperty = class(TACLImageIndexProperty)
  protected
    function GetImages: TCustomImageList; override;
  end;

  { TACLTreeListSelectionEditor }

  TACLTreeListSelectionEditor = class(TACLSelectionEditor)
  public
    procedure RequiresUnits(Proc: TGetStrProc); override;
  end;

  { TACLTreeListComponentEditor }

  TACLTreeListComponentEditor = class(TComponentEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  { TACLTreeListColumnImageIndexProperty }

  TACLTreeListColumnImageIndexProperty = class(TACLImageIndexProperty)
  protected
    function GetImages: TCustomImageList; override;
  end;

{$ENDREGION}

{$REGION ' Menus '}

  { TACLMenuPropertyEditor }

  TACLMenuPropertyEditor = class(TClassProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

  { TACLPopupMenuEditor }

  TACLPopupMenuEditor = class(TComponentEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetDesigner(out ADesigner: IDesigner): Boolean; reintroduce;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  { TACLMainMenuEditor }

  TACLMainMenuEditor = class(TACLPopupMenuEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
  end;

{$ENDREGION}

function GetUniqueName(ADesigner: IDesigner; AOwner: TComponent; const AName: string): string;
procedure SelectComponent(ADesigner: IDesigner; AComponent: TPersistent);
implementation

uses
  ACL.UI.DesignTime.PropEditors.ImageList,
  ACL.UI.DesignTime.PropEditors.Texture,
  ACL.UI.DesignTime.PropEditors.Menu;

const
  sNewResourceCollection = 'new resource collection';
  sResourceID = 'Resource ID';
  sResourceIDPrompt = 'Enter Resource ID';

type
  TACLResourceFontAccess = class(TACLResourceFont);
  TPersistentAccess = class(TPersistent);

function GetUniqueName(ADesigner: IDesigner; AOwner: TComponent; const AName: string): string;
begin
{$IFDEF FPC}
  Result := CreateUniqueName(AOwner, AName, '');
{$ELSE}
  Result := ADesigner.UniqueName(AName);
{$ENDIF}
end;

function IsSelected(AValue: TPropEditDrawState): Boolean;
begin
{$IFDEF FPC}
  Result := pedsSelected in AValue;
{$ELSE}
  Result := AValue;
{$ENDIF}
end;

procedure SelectComponent(ADesigner: IDesigner; AComponent: TPersistent);
begin
  if ADesigner <> nil then
  {$IFDEF FPC}
    ADesigner.SelectOnlyThis(AComponent);
  {$ELSE}
    ADesigner.SelectComponent(AComponent);
  {$ENDIF}
end;

{$REGION ' FPC Base '}

{$IFDEF FPC}

procedure ShowCollectionEditor(ADesigner: TObject;
  AComponent: TComponent; ACollection: TCollection; const APropName: string);
begin
  EditCollection(AComponent, ACollection, APropName);
end;

{ TDesignWindow }

procedure TDesignWindow.BeforeDestruction;
begin
  inherited BeforeDestruction;
  Designer := nil;
end;

procedure TDesignWindow.ItemDeleted(const ADesigner: IDesigner; Item: TPersistent);
begin
  // do nothing
end;

procedure TDesignWindow.ItemInserted(const ADesigner: IDesigner; Item: TPersistent);
begin
  // do nothing
end;

procedure TDesignWindow.ItemsModified(const ADesigner: IDesigner);
begin
  // do nothing
end;

procedure TDesignWindow.SelectionChanged(
  const ADesigner: IDesigner; const ASelection: IDesignerSelections);
begin
  // do nothing
end;

procedure TDesignWindow.DoCompAdded(APersistent: TPersistent; Select: boolean);
begin
  ItemInserted(Designer, APersistent);
end;

procedure TDesignWindow.DoCompDeleting(APersistent: TPersistent);
begin
  ItemDeleted(Designer, APersistent);
end;

procedure TDesignWindow.DoCompSelection(
  const ASelection: TPersistentSelectionList);
begin
  SelectionChanged(Designer, ASelection);
end;

procedure TDesignWindow.DoModified(Sender: TObject);
begin
  ItemsModified(Designer);
end;

procedure TDesignWindow.SetDesigner(AValue: TPropertyEditorHook);
begin
  if FDesigner = AValue then
  begin
    if FDesigner <> nil then
    begin
      FDesigner.RemoveHandlerPersistentAdded(DoCompAdded);
      FDesigner.RemoveHandlerPersistentDeleting(DoCompDeleting);
      FDesigner.RemoveHandlerModified(DoModified);
      FDesigner.RemoveHandlerSetSelection(DoCompSelection);
      FDesigner := nil;
    end;
    if AValue <> nil then
    begin
      FDesigner := AValue;
      FDesigner.AddHandlerPersistentAdded(DoCompAdded);
      FDesigner.AddHandlerPersistentDeleting(DoCompDeleting);
      FDesigner.AddHandlerModified(DoModified);
      FDesigner.AddHandlerSetSelection(DoCompSelection);
    end;
  end;
end;

{ TPropertyEditorHelper }

function TPropertyEditorHelper.Designer: TPropertyEditorHook;
begin
  Result := Self.PropertyHook;
end;
{$ENDIF}
{$ENDREGION}

{$REGION ' General Properties '}

{ TAlphaColorPropertyEditor }

class procedure TAlphaColorPropertyEditor.DrawPreview(
  ACanvas: TCanvas; var ARect: TRect; AColor: TAlphaColor);
var
  LRect: TRect;
begin
  LRect := ARect;
  LRect.Width := LRect.Height;
  acDrawColorPreview(ACanvas, LRect, AColor);
  ARect.Left := LRect.Right + acTextIndent;
end;

procedure TAlphaColorPropertyEditor.Edit;
var
  AColor: TAlphaColor;
begin
  AColor := TAlphaColor(GetOrdValue);
  if TACLColorPickerDialog.Execute(AColor, IsAlphaSupported) then
    SetOrdValue(AColor);
end;

function TAlphaColorPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

function TAlphaColorPropertyEditor.GetValue: string;
begin
  Result := TAlphaColor(GetOrdValue).ToString;
end;

function TAlphaColorPropertyEditor.IsAlphaSupported: Boolean;
begin
  Result := not (GetComponent(0) is TACLResourceColor) or
    TACLResourceColor(GetComponent(0)).IsAlphaSupported;
end;

procedure TAlphaColorPropertyEditor.PropDrawName;
begin
{$IFDEF FPC}
  inherited;
{$ELSE}
  DefaultPropertyDrawName(Self, ACanvas, ARect);
{$ENDIF}
end;

function TAlphaColorPropertyEditor.PropDrawNameRect(const ARect: TRect): TRect;
begin
  Result := ARect;
end;

procedure TAlphaColorPropertyEditor.PropDrawValue;
var
  LRect: TRect;
begin
  LRect := ARect;
  DrawPreview(ACanvas, LRect, GetOrdValue);
{$IFDEF FPC}
  inherited PropDrawValue(ACanvas, LRect, ASelected);
{$ELSE}
  DefaultPropertyDrawName(Self, ACanvas, LRect);
{$ENDIF}
end;

function TAlphaColorPropertyEditor.PropDrawValueRect(const ARect: TRect): TRect;
begin
  Result := ARect;
  Result.Width := ARect.Height;
end;

procedure TAlphaColorPropertyEditor.SetValue(const Value: string);
begin
  SetOrdValue(TAlphaColor.FromString(Value));
end;

{ TACLImageIndexProperty }

function TACLImageIndexProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paRevertable];
end;

function TACLImageIndexProperty.GetValue: string;
begin
  Result := IntToStr(GetOrdValue);
end;

procedure TACLImageIndexProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  Proc('-1');
  if Images <> nil then
  begin
    for I := 0 to Images.Count - 1 do
      Proc(IntToStr(I));
  end;
end;

procedure TACLImageIndexProperty.SetValue(const Value: string);
begin
  SetOrdValue(StrToInt(Value));
end;

procedure TACLImageIndexProperty.ListDrawValue;
var
  LImageWidth: Integer;
  LRect: TRect;
begin
  // Image
  if Images <> nil then
  begin
    ACanvas.FillRect(ARect);
    if IsSelected(AState) then
      ACanvas.DrawFocusRect(ARect);
    LRect := ARect;
    LRect.CenterVert(Images.Height);
    Images.Draw(ACanvas, ARect.Left + acTextIndent, LRect.Top, StrToInt(AValue));
    LImageWidth := Images.Width + 2 * acTextIndent;
  end
  else
    LImageWidth := 0;

  // Text
  LRect := ARect;
  LRect.CenterVert(ACanvas.TextHeight(AValue));
  ACanvas.TextOut(ARect.Left + LImageWidth + acTextIndent, LRect.Top, AValue);
end;

procedure TACLImageIndexProperty.ListMeasureHeight;
begin
{$IFDEF FPC}
  AHeight := ACanvas.TextHeight(AValue);
{$ENDIF}
  if Images <> nil then
    AHeight := Max(AHeight, Images.Height + 2 * acTextIndent);
end;

procedure TACLImageIndexProperty.ListMeasureWidth;
begin
{$IFDEF FPC}
  AWidth := ACanvas.TextWidth(AValue) + 2 * acTextIndent;
{$ENDIF}
  if Images <> nil then
    Inc(AWidth, Images.Width + 2 * acTextIndent);
end;

function TACLImageIndexProperty.GetImages: TCustomImageList;
var
  APropInfo: PPropInfo;
begin
  APropInfo := TypInfo.GetPropInfo(GetComponent(0), 'Images', [tkClass]);
  if APropInfo <> nil then
    Result := TCustomImageList(GetObjectProp(GetComponent(0), APropInfo, TCustomImageList))
  else
    Result := nil;
end;

{ TACLMultiLineStringEditor }

procedure TACLMultiLineStringEditor.Edit;
var
  LText: string;
begin
  LText := GetValue;
  if TACLMemoQueryDialog.Execute(GetName, LText) then
    SetValue(LText);
end;

function TACLMultiLineStringEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

{ TACLSelectionEditor }

{$IFDEF FPC}
procedure TACLSelectionEditor.RequiresUnits(Proc: TGetStrProc);
begin
  // do nothing
end;
{$ENDIF}
{$ENDREGION}

{$REGION ' Resources '}

{ TACLResourceProperty }

function TACLResourceProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paReadOnly];
end;

function TACLResourceProperty.GetValue: string;
begin
  Result := Resource.ToString;
end;

procedure TACLResourceProperty.PropDrawName(ACanvas: TCanvas;
  const ARect: TRect; ASelected: TPropEditDrawState);
begin
{$IFDEF FPC}
  inherited;
{$ELSE}
  DefaultPropertyDrawName(Self, ACanvas, ARect);
{$ENDIF}
end;

function TACLResourceProperty.PropDrawNameRect(const ARect: TRect): TRect;
begin
  Result := ARect;
end;

procedure TACLResourceProperty.PropDrawValue(ACanvas: TCanvas;
  const ARect: TRect; ASelected: TPropEditDrawState);
var
  LRect: TRect;
begin
  LRect := ARect;
  PropDrawValueCore(ACanvas, LRect);
{$IFDEF FPC}
  inherited PropDrawValue(ACanvas, LRect, ASelected);
{$ELSE}
  DefaultPropertyDrawValue(Self, ACanvas, LRect);
{$ENDIF}
end;

procedure TACLResourceProperty.PropDrawValueCore(ACanvas: TCanvas; var ARect: TRect);
begin
  // do nothing
end;

function TACLResourceProperty.PropDrawValueRect(const ARect: TRect): TRect;
begin
  Result := ARect;
end;

function TACLResourceProperty.GetResource: TACLResource;
begin
{$IFDEF FPC}
  Result := TACLResource(GetObjectValue);
{$ELSE}
  Result := TACLResource(GetOrdValue);
{$ENDIF}
end;

{ TACLResourceColorProperty }

procedure TACLResourceColorProperty.Edit;
var
  AColor: TAlphaColor;
begin
  AColor := Resource.Value;
  if TACLColorPickerDialog.Execute(AColor, Resource.IsAlphaSupported) then
    Resource.Value := AColor;
end;

function TACLResourceColorProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

procedure TACLResourceColorProperty.PropDrawValueCore;
begin
  TAlphaColorPropertyEditor.DrawPreview(ACanvas, ARect, Resource.Value);
end;

function TACLResourceColorProperty.PropDrawValueRect(const ARect: TRect): TRect;
begin
  Result := ARect;
  Result.Width := ARect.Height;
end;

function TACLResourceColorProperty.GetResource: TACLResourceColor;
begin
  Result := TACLResourceColor(inherited Resource);
end;

{ TACLResourceFontProperty }

procedure TACLResourceFontProperty.Edit;
var
  AFont: TFont;
begin
  AFont := TFont.Create;
  try
    AFont.Assign(Resource);
    if TACLFontPickerDialog.Execute(AFont) then
    begin
      Resource.Assign(AFont);
      Modified;
    end;
  finally
    AFont.Free;
  end;
end;

function TACLResourceFontProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

function TACLResourceFontProperty.GetResource: TACLResourceFont;
begin
  Result := TACLResourceFont(inherited Resource);
end;

procedure TACLResourceFontProperty.PropDrawValueCore;
begin
  TAlphaColorPropertyEditor.DrawPreview(ACanvas, ARect, Resource.Color);
  ACanvas.Font.Style := Resource.Style;
end;

function TACLResourceFontProperty.PropDrawValueRect(const ARect: TRect): TRect;
begin
  Result := ARect;
  Result.Width := ARect.Height;
end;

{ TACLResourceFontColorIDProperty }

function TACLResourceFontColorIDProperty.GetResource: TACLResource;
begin
  Result := TACLResourceFontAccess(GetComponent(0)).FColor;
end;

{ TACLResourceTextureProperty }

procedure TACLResourceTextureProperty.Edit;
begin
  TACLTextureEditorDialog.Execute(TACLResourceTexture(Resource));
end;

function TACLResourceTextureProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

{ TACLResourceTextureDataProperty }

procedure TACLResourceTextureDataProperty.Edit;
begin
  TACLTextureEditorDialog.Execute(GetData);
end;

function TACLResourceTextureDataProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;

function TACLResourceTextureDataProperty.GetName;
begin
  Result := 'Data';
end;

function TACLResourceTextureDataProperty.GetValue: string;
begin
  with GetData.FrameSize do
    Result := Format('(%dx%d)', [cx, cy]);
end;

procedure TACLResourceTextureDataProperty.SetValue(const Value: string);
begin
  // do nothing
end;

function TACLResourceTextureDataProperty.GetData: TACLResourceTexture;
begin
  Result := TACLResourceTexture(GetComponent(0));
end;

{ TACLResourceIDProperty }

function TACLResourceIDProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paValueList] - [paMultiSelect];
end;

procedure TACLResourceIDProperty.GetValues(Proc: TGetStrProc);
var
  AIndex: Integer;
  AList: TACLStringList;
begin
  AList := TACLStringList.Create;
  try
    PopulateResources(Resource, AList);
    PopulateCommands(Resource, AList);
    for AIndex := 0 to AList.Count - 1 do
      Proc(AList[AIndex]);
  finally
    AList.Free;
  end;
end;

procedure TACLResourceIDProperty.SetValue(const Value: string);
begin
  if Value = CmdReset then
    Resource.Reset
  else if acBeginsWith(Value, CmdOverridePrefix) then
    OverrideValue(Copy(Value, Length(CmdOverridePrefix) + 1, Length(Value) - Length(CmdOverridePrefix) - 1))
  else
    inherited SetValue(Value);

  Modified;
end;

function TACLResourceIDProperty.GetResource: TACLResource;
begin
  Result := TACLResource(GetComponent(0));
end;

function TACLResourceIDProperty.GetCollectionOwner(AResource: TACLResource): TPersistent;
var
  AIntf: IUnknown;
begin
  Result := acFindOwnerThatSupportTheInterface(AResource.Owner, IACLResourceCollection, AIntf);
end;

function TACLResourceIDProperty.GetResourceCollectionsToOverride: TACLStringList;
var
  ACollection: IACLResourceCollection;
  ACollectionOwner: TPersistent;
begin
  FTempResourceCollections := TACLStringList.Create;
  ACollectionOwner := GetCollectionOwner(Resource);
  if Supports(ACollectionOwner, IACLResourceCollectionSetter) then
  begin
    if Supports(ACollectionOwner, IACLResourceCollection, ACollection) and (ACollection.GetCollection <> nil) then
      FTempResourceCollections.Add(CmdOwnerPrefix + ACollection.GetCollection.Name, ACollection.GetCollection)
    else
    begin
      Designer.GetComponentNames(GetTypeData(TACLCustomResourceCollection.ClassInfo), GetResourceCollectionsProc);
    {$IFDEF DESIGNER_CAN_CREATECOMPONENT}
      FTempResourceCollections.Add(sNewResourceCollection);
    {$ENDIF}
    end;
  end;
  Result := FTempResourceCollections;
end;

procedure TACLResourceIDProperty.GetResourceCollectionsProc(const S: string);
begin
  FTempResourceCollections.Add(S);
end;

procedure TACLResourceIDProperty.OverrideValue(const ACollectionName: string);
var
  ACollection: TACLCustomResourceCollection;
  ACollectionGetter: IACLResourceCollection;
  ACollectionSetter: IACLResourceCollectionSetter;
  AResourceID: string;
begin
  AResourceID := Resource.ID;
  if InputQuery(sResourceID, sResourceIDPrompt, AResourceID) and (AResourceID <> '') then
  begin
    if acBeginsWith(ACollectionName, CmdOwnerPrefix) then
    begin
      if Supports(GetCollectionOwner(Resource), IACLResourceCollection, ACollectionGetter) then
        ACollection := ACollectionGetter.GetCollection
      else
        ACollection := nil;
    end
    else
    begin
      ACollection := Designer.GetComponent(ACollectionName) as TACLCustomResourceCollection;
    {$IFDEF DESIGNER_CAN_CREATECOMPONENT}
      if ACollection = nil then
        ACollection := Designer.CreateComponent(TACLCustomResourceCollection, Designer.Root, 0, 0, 0, 0) as TACLCustomResourceCollection;
    {$ENDIF}
      if Supports(GetCollectionOwner(Resource), IACLResourceCollectionSetter, ACollectionSetter) then
        ACollectionSetter.SetCollection(ACollection);
    end;
    if ACollection = nil then
      raise EInvalidOperation.CreateFmt('The %s collection was not found', [ACollectionName]);
    SelectComponent(Designer, ACollection.Items.AddResource(Resource, AResourceID).Owner);
    Resource.ID := AResourceID;
  end;
end;

procedure TACLResourceIDProperty.PopulateCommands(AResource: TACLResource; AList: TACLStringList);
var
  LCollections: TACLStringList;
  I: Integer;
begin
  LCollections := GetResourceCollectionsToOverride;
  try
    for I := 0 to LCollections.Count - 1 do
      AList.Insert(I, Format(CmdOverride, [LCollections[I]]));
    if not AResource.IsDefault then
      AList.Insert(0, CmdReset);
  finally
    LCollections.Free;
  end;
end;

procedure TACLResourceIDProperty.PopulateResources(
  AResource: TACLResource; AList: TACLStringList);

  procedure EnumResources(AList: TACLStringList;
    AResource: TACLResource; ASource: TACLCustomResourceCollection);
  begin
    while ASource <> nil do
    begin
      ASource.Items.EnumResources(
        TACLResourceClass(AResource.ClassType),
        function (AResource: TACLResourceCollectionItem): Boolean
        begin
          AList.Add(AResource.ID);
          Result := False;
        end);

      if ASource is TACLResourceCollection then
        ASource := TACLResourceCollection(ASource).MasterCollection
      else
        ASource := nil;
    end;
  end;

var
  ACollection: IACLResourceCollection;
  APersistent: TPersistent;
begin
  if AResource.ID <> '' then
    AList.Add(AResource.ID);

  APersistent := AResource.Owner;
  while APersistent <> nil do
  begin
    if Supports(APersistent, IACLResourceCollection, ACollection) then
      EnumResources(AList, AResource, ACollection.GetCollection);
    if APersistent is TComponent then
      Break;
    APersistent := TPersistentAccess(APersistent).GetOwner;
  end;

  EnumResources(AList, AResource, TACLRootResourceCollection.GetInstance);
  AList.RemoveDuplicates;
  AList.SortLogical;
end;

{ TACLResourceCollectionItemResourceProperty }

function TACLResourceCollectionItemResourceProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes - [paReadOnly, paMultiSelect] +
    [paValueList, paSortList, paRevertable, paVolatileSubProperties];
end;

function TACLResourceCollectionItemResourceProperty.GetValue: string;
var
  AItem: TACLResourceCollectionItem;
begin
  AItem := TACLResourceCollectionItem(GetComponent(0));
  if AItem.Resource <> nil then
    Result := AItem.Resource.TypeName
  else
    Result := '';
end;

procedure TACLResourceCollectionItemResourceProperty.GetValues(Proc: TGetStrProc);
begin
  TACLResourceClassRepository.Enum(
    procedure (AClass: TACLResourceClass)
    begin
      Proc(AClass.TypeName);
    end);
end;

procedure TACLResourceCollectionItemResourceProperty.SetValue(const Value: string);
begin
  TACLResourceCollectionItem(GetComponent(0)).ResourceClassName := Value;
  Modified;
end;

{ TACLResourceCollectionEditor }

procedure TACLResourceCollectionEditor.Edit;
begin
  ShowCollectionEditor(Designer, Component, TACLCustomResourceCollection(Component).Items, 'Items');
end;

procedure TACLResourceCollectionEditor.ExecuteVerb(Index: Integer);
begin
  case Index of
    0: Edit;
    1: Load;
    2: Save;
    else
      inherited ExecuteVerb(Index - 3);
  end;
end;

function TACLResourceCollectionEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Edit...';
    1: Result := 'Load...';
    2: Result := 'Save...';
  else
    Result := inherited GetVerb(Index - 3);
  end;
end;

function TACLResourceCollectionEditor.GetVerbCount: Integer;
begin
  Result := inherited GetVerbCount + 3;
end;

procedure TACLResourceCollectionEditor.Load;
begin
  with TACLFileDialog.Create(nil) do
  try
    Filter := FilterString;
    if Execute(False) then
      TACLCustomResourceCollection(Component).LoadFromFile(FileName);
  finally
    Free;
  end;
end;

procedure TACLResourceCollectionEditor.Save;
begin
  with TACLFileDialog.Create(nil) do
  try
    Filter := FilterString;
    if Execute(True) then
      TACLCustomResourceCollection(Component).SaveToFile(FileName);
  finally
    Free;
  end;
end;

{$ENDREGION}

{$REGION ' Controls '}

{ TACLBindingDiagramSelectionEditor }

procedure TACLBindingDiagramSelectionEditor.RequiresUnits(Proc: TGetStrProc);
begin
  Proc('ACL.Classes.Collections');
  Proc('ACL.UI.Controls.BindingDiagram.SubClass');
  Proc('ACL.UI.Controls.BindingDiagram.Types');
end;

{ TACLDPIPropertyEditor }

function TACLDPIPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paValueList];
end;

function TACLDPIPropertyEditor.GetValue: string;
begin
  Result := ValueToString(GetOrdValue);
end;

procedure TACLDPIPropertyEditor.GetValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  Proc(Default);
  for I := Low(acDefaultDPIValues) to High(acDefaultDPIValues) do
    Proc(ValueToString(acDefaultDPIValues[I]));
end;

procedure TACLDPIPropertyEditor.SetValue(const S: string);
begin
  SetOrdValue(StringToValue(S));
end;

function TACLDPIPropertyEditor.StringToValue(const AValue: string): Integer;
var
  E: Integer;
begin
  if AValue = Default then
    Exit(0);

  Val(AValue, Result, E);
  while (E > 0) and (E <= Length(AValue)) do
  begin
    if AValue[E] = ' ' then
      Inc(E)
    else
    begin
      if AValue[E] = '%' then
        Result := MulDiv(acDefaultDPI, Result, 100);
      Break;
    end;
  end;
end;

function TACLDPIPropertyEditor.ValueToString(const AValue: Integer): string;
begin
  if AValue = 0 then
    Result := Default
  else
    Result := Format('%d dpi (%d %%)', [AValue, MulDiv(100, AValue, acDefaultDPI)]);
end;

{ TACLImageListEditor }

procedure TACLImageListEditor.ExecuteVerb(Index: Integer);
begin
  case Index of
    0: TfrmImageListEditor.Execute(GetComponent as TCustomImageList);
  else
    inherited ExecuteVerb(Index - 1);
  end;
end;

function TACLImageListEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Edit';
    else
      Result := inherited GetVerb(Index - 1);
  end;
end;

function TACLImageListEditor.GetVerbCount: Integer;
begin
  Result := inherited GetVerbCount + 1;
end;

{ TACLImagePictureProperty }

function TACLImagePictureProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  if not HasSubProperties then
    Exclude(Result, paSubProperties);
  Result := Result - [paReadOnly] + [paValueList, paSortList, paRevertable, paVolatileSubProperties];
end;

function TACLImagePictureProperty.GetValue: string;
begin
  if HasSubProperties then
    Result := TACLImageBox.GetDescriptionByClass(TACLImageBox(GetComponent(0)).PictureClass)
  else
    Result := '';
end;

procedure TACLImagePictureProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  for I := 0 to TACLImageBox.PictureClasses.Count - 1 do
    Proc(TACLImageBox.PictureClasses[I].GetDescription);
end;

function TACLImagePictureProperty.HasSubProperties: Boolean;
var
  I: Integer;
begin
  for I := 0 to PropCount - 1 do
  begin
    if TACLImageBox(GetComponent(I)).Picture = nil then
      Exit(False);
  end;
  Result := True;
end;

procedure TACLImagePictureProperty.SetValue(const Value: string);
var
  AClass: TACLImagePictureClass;
  I: Integer;
begin
  AClass := TACLImagePictureClass(TACLImageBox.GetClassByDescription(Value));
  for I := 0 to PropCount - 1 do
    TACLImageBox(GetComponent(I)).PictureClass := AClass;
  Modified;
end;

{ TACLDropDownImageIndexProperty }

function TACLDropDownImageIndexProperty.GetImages: TCustomImageList;
begin
  Result := TACLDropDown(GetComponent(0)).Images;
end;

{ TACLTreeListSelectionEditor }

procedure TACLTreeListSelectionEditor.RequiresUnits(Proc: TGetStrProc);
begin
  Proc('ACL.UI.DropSource');
  Proc('ACL.UI.DropTarget');
  Proc('ACL.UI.Controls.TreeList.Options');
  Proc('ACL.UI.Controls.TreeList.SubClass');
  Proc('ACL.UI.Controls.TreeList.Types');
end;

{ TACLTreeListComponentEditor }

procedure TACLTreeListComponentEditor.ExecuteVerb(Index: Integer);
begin
  if Index = 0 then
    ShowCollectionEditor(Designer, Component, TACLTreeList(Component).Columns, 'Columns')
  else
    inherited ExecuteVerb(Index);
end;

function TACLTreeListComponentEditor.GetVerb(Index: Integer): string;
begin
  if Index = 0 then
    Result := 'Columns...'
  else
    Result := inherited GetVerb(Index - 1);
end;

function TACLTreeListComponentEditor.GetVerbCount: Integer;
begin
  Result := inherited GetVerbCount + 1;
end;

{ TACLTreeListColumnImageIndexProperty }

function TACLTreeListColumnImageIndexProperty.GetImages: TCustomImageList;
begin
  Result := ((GetComponent(0) as TACLTreeListColumn).Columns.Owner as
    TACLTreeListSubClass).OptionsView.Columns.Images;
end;

{ TACLPageControlEditor }

procedure TACLPageControlEditor.AddPage;
var
  LPageControl: TACLPageControl;
begin
  if Component is TACLPageControl then
    LPageControl := TACLPageControl(Component)
  else if Component is TACLPageControlPage then
    LPageControl := TACLPageControlPage(Component).PageControl
  else
    LPageControl := nil;

  if LPageControl <> nil then
    LPageControl.AddPage('New Page');
end;

procedure TACLPageControlEditor.DeletePage;
begin
  if Component is TACLPageControl then
    TACLPageControl(Component).ActivePage.Free;
  if Component is TACLPageControlPage then
    Component.Free;
end;

procedure TACLPageControlEditor.ExecuteVerb(Index: Integer);
begin
  case Index of
    0: AddPage;
    1: DeletePage;
  else
    inherited ExecuteVerb(Index - 2);
  end;
end;

function TACLPageControlEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Add Page';
    1: Result := 'Delete Page';
    else
      Result := inherited GetVerb(Index - 2);
  end;
end;

function TACLPageControlEditor.GetVerbCount: Integer;
begin
  Result := inherited GetVerbCount + 2;
end;

{ TACLEditButtonImageIndexProperty }

function TACLEditButtonImageIndexProperty.GetImages: TCustomImageList;
begin
  Result := TACLEdit((GetComponent(0) as TACLEditButton).Collection.Owner).ButtonsImages;
end;

{ TACLImageComboBoxImageIndexProperty }

function TACLImageComboBoxImageIndexProperty.GetImages: TCustomImageList;
begin
  Result := TACLImageComboBoxItems(TACLImageComboBoxItem(GetComponent(0)).Collection).ComboBox.Images;
end;
{$ENDREGION}

{$REGION ' Menus '}

{ TACLMenuPropertyEditor }

procedure TACLMenuPropertyEditor.Edit;
begin
  TACLMenuEditorDialog.Execute(GetComponent(0) as TACLPopupMenu, Designer);
end;

function TACLMenuPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog];
end;

{ TACLMainMenuEditor }

procedure TACLMainMenuEditor.ExecuteVerb(Index: Integer);
var
  LMainMenu: TACLMainMenu;
  LDesigner: IDesigner;
begin
  if Index = 0 then
  begin
    LMainMenu := GetComponent as TACLMainMenu;
    if LMainMenu.Menu = nil then
      raise Exception.Create(LMainMenu.Name + '.Menu is not set');
    if GetDesigner(LDesigner) then
      TACLMenuEditorDialog.Execute(LMainMenu.Menu, LDesigner);
  end
  else
    inherited;
end;

{ TACLPopupMenuEditor }

procedure TACLPopupMenuEditor.ExecuteVerb(Index: Integer);
var
  LDesigner: IDesigner;
begin
  if Index = 0 then
  begin
    if GetDesigner(LDesigner) then
      TACLMenuEditorDialog.Execute(GetComponent as TACLPopupMenu, LDesigner);
  end
  else
    inherited;
end;

function TACLPopupMenuEditor.GetDesigner(out ADesigner: IDesigner): Boolean;
begin
{$IFDEF FPC}
  Result := GetHook(ADesigner);
{$ELSE}
  ADesigner := Designer;
  Result := ADesigner <> nil;
{$ENDIF}
end;

function TACLPopupMenuEditor.GetVerb(Index: Integer): string;
begin
  if Index = 0 then
    Result := 'Menu Designer...'
  else
    Result := inherited;
end;

function TACLPopupMenuEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

{$ENDREGION}
end.
