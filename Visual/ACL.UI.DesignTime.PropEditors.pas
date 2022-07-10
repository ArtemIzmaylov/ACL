{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*              Styles Support               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.DesignTime.PropEditors;

{$I ACL.Config.inc}

interface

uses
  Windows, UITypes, Types, TypInfo, Classes, Graphics, Dialogs, ImgList, Math,
  // PropertyEditors
  DesignEditors, DesignIntf, VCLEditors, ColnEdit,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Gdiplus,
  ACL.UI.Dialogs,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.DropDown,
  ACL.UI.Controls.TabControl,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.DesignTime.PropEditors.ImageList,
  ACL.UI.DesignTime.PropEditors.Texture,
  ACL.UI.Dialogs.ColorPicker,
  ACL.UI.Dialogs.FontPicker,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type

  { TAlphaColorPropertyEditor }

  TAlphaColorPropertyEditor = class(TOrdinalProperty,
    ICustomPropertyDrawing,
    ICustomPropertyDrawing80)
  protected
    function IsAlphaSupported: Boolean; virtual;
    // ICustomPropertyDrawing
    procedure PropDrawName(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
    procedure PropDrawValue(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
    // ICustomPropertyDrawing80
    function PropDrawNameRect(const ARect: TRect): TRect;
    function PropDrawValueRect(const ARect: TRect): TRect;
  public
    class procedure DrawPreview(ACanvas: TCanvas; R: TRect; AColor: TAlphaColor);
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
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

  { TACLResourceProperty }

  TACLResourceProperty = class abstract(TClassProperty,
    ICustomPropertyDrawing,
    ICustomPropertyDrawing80)
  strict private
    function GetResource: TACLResource;
  protected
    // ICustomPropertyDrawing
    procedure PropDrawName(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
    procedure PropDrawValue(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean); virtual;
    // ICustomPropertyDrawing80
    function PropDrawNameRect(const ARect: TRect): TRect;
    function PropDrawValueRect(const ARect: TRect): TRect; virtual;
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    //
    property Resource: TACLResource read GetResource;
  end;

  { TACLResourceColorProperty }

  TACLResourceColorProperty = class(TACLResourceProperty)
  strict private
    function GetResource: TACLResourceColor;
  protected
    procedure PropDrawValue(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean); override;
    function PropDrawValueRect(const ARect: TRect): TRect; override;
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    //
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
    function GetName: string; override;
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
    //
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
  protected
    procedure PropDrawValue(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean); override;
    function PropDrawValueRect(const ARect: TRect): TRect; override;
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    //
    property Resource: TACLResourceFont read GetResource;
  end;

  { TACLResourceFontColorIDProperty }

  TACLResourceFontColorIDProperty = class(TACLResourceIDProperty)
  public
    function GetResource: TACLResource; override;
  end;

  { TACLImageListEditor }

  TACLImageListEditor = class(TComponentEditor)
  public
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

  { TACLImageIndexProperty }

  TACLImageIndexProperty = class(TIntegerProperty, ICustomPropertyListDrawing)
  protected
    function GetImages: TCustomImageList; virtual;
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
    // ICustomPropertyListDrawing
    procedure ListDrawValue(const Value: string; ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
    procedure ListMeasureHeight(const Value: string; ACanvas: TCanvas; var AHeight: Integer);
    procedure ListMeasureWidth(const Value: string; ACanvas: TCanvas; var AWidth: Integer);
    //
    property Images: TCustomImageList read GetImages;
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

  { TACLCollectionEditor }

  TACLCollectionEditor = class(TClassProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

  { TACLMultiLineStringEditor }

  TACLMultiLineStringEditor = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  { TACLEditButtonImageIndexProperty }

  TACLEditButtonImageIndexProperty = class(TACLImageIndexProperty)
  protected
    function GetImages: TCustomImageList; override;
  end;

  { TACLDropDownImageIndexProperty }

  TACLDropDownImageIndexProperty = class(TACLImageIndexProperty)
  protected
    function GetImages: TCustomImageList; override;
  end;
  
  { TACLBindingDiagramSelectionEditor }

  TACLBindingDiagramSelectionEditor = class(TSelectionEditor)
  public
    procedure RequiresUnits(Proc: TGetStrProc); override;
  end;

  { TACLTreeListSelectionEditor }

  TACLTreeListSelectionEditor = class(TSelectionEditor)
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

implementation

uses
  SysUtils,
  // ACL
  ACL.UI.Controls.ColorPicker,
  ACL.UI.Controls.Images;

const
  sNewResourceCollection = 'new resource collection';
  sResourceID = 'Resource ID';
  sResourceIDPrompt = 'Enter Resource ID';

type
  TACLResourceAccess = class(TACLResource);
  TACLResourceFontAccess = class(TACLResourceFont);
  TACLResourceTextureAccess = class(TACLResourceTexture);
  TPersistentAccess = class(TPersistent);

{ TAlphaColorPropertyEditor }

class procedure TAlphaColorPropertyEditor.DrawPreview(ACanvas: TCanvas; R: TRect; AColor: TAlphaColor);
begin
  R.Right := R.Left + R.Height;
  acDrawColorPreview(ACanvas, R, AColor);
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
  Result := not (GetComponent(0) is TACLResourceColor) or TACLResourceColor(GetComponent(0)).IsAlphaSupported;
end;

procedure TAlphaColorPropertyEditor.PropDrawName(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
begin
  DefaultPropertyDrawName(Self, ACanvas, ARect);
end;

function TAlphaColorPropertyEditor.PropDrawNameRect(const ARect: TRect): TRect;
begin
  Result := ARect;
end;

procedure TAlphaColorPropertyEditor.PropDrawValue(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
begin
  if AllEqual then
    DrawPreview(ACanvas, ARect, GetOrdValue);
end;

function TAlphaColorPropertyEditor.PropDrawValueRect(const ARect: TRect): TRect;
begin
  Result := acRectSetWidth(ARect, acRectHeight(ARect));
end;

procedure TAlphaColorPropertyEditor.SetValue(const Value: string);
begin
  SetOrdValue(TAlphaColor.FromString(Value));
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

{ TACLResourceProperty }

function TACLResourceProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paReadOnly];
end;

function TACLResourceProperty.GetValue: string;
begin
  Result := Resource.ToString;
end;

procedure TACLResourceProperty.PropDrawName(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
begin
  DefaultPropertyDrawName(Self, ACanvas, ARect);
end;

function TACLResourceProperty.PropDrawNameRect(const ARect: TRect): TRect;
begin
  Result := ARect;
end;

procedure TACLResourceProperty.PropDrawValue(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
begin
  DefaultPropertyDrawValue(Self, ACanvas, ARect);
end;

function TACLResourceProperty.PropDrawValueRect(const ARect: TRect): TRect;
begin
  Result := ARect;
end;

function TACLResourceProperty.GetResource: TACLResource;
begin
  Result := TACLResource(GetOrdValue);
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

procedure TACLResourceColorProperty.PropDrawValue(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
begin
  if AllEqual then
    TAlphaColorPropertyEditor.DrawPreview(ACanvas, ARect, Resource.Value);
end;

function TACLResourceColorProperty.PropDrawValueRect(const ARect: TRect): TRect;
begin
  Result := acRectSetWidth(ARect, acRectHeight(ARect));
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

procedure TACLResourceFontProperty.PropDrawValue(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
begin
  if AllEqual then
  begin
    TAlphaColorPropertyEditor.DrawPreview(ACanvas, ARect, Resource.Color);
    ACanvas.Font.Style := Resource.Style;
  end;
end;

function TACLResourceFontProperty.PropDrawValueRect(const ARect: TRect): TRect;
begin
  Result := acRectSetWidth(ARect, acRectHeight(ARect));
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

function TACLResourceTextureDataProperty.GetName: string;
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
      FTempResourceCollections.Add(sNewResourceCollection);
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
        raise EInvalidOperation.CreateFmt('The %s collection was not found', [ACollectionName]);
    end
    else
    begin
      ACollection := Designer.GetComponent(ACollectionName) as TACLCustomResourceCollection;
      if ACollection = nil then
        ACollection := Designer.CreateComponent(TACLCustomResourceCollection, Designer.Root, 0, 0, 0, 0) as TACLCustomResourceCollection;
      if Supports(GetCollectionOwner(Resource), IACLResourceCollectionSetter, ACollectionSetter) then
        ACollectionSetter.SetCollection(ACollection);
    end;

    Designer.SelectComponent(ACollection.Items.AddResource(Resource, AResourceID).Owner);
    Resource.ID := AResourceID;
  end;
end;

procedure TACLResourceIDProperty.PopulateCommands(AResource: TACLResource; AList: TACLStringList);
var
  AResourceCollections: TACLStringList;
  I: Integer;
begin
  AResourceCollections := GetResourceCollectionsToOverride;
  try
    for I := 0 to AResourceCollections.Count - 1 do
      AList.Insert(I, Format(CmdOverride, [AResourceCollections[I]]));
    if not AResource.IsDefault then
      AList.Insert(0, CmdReset);
  finally
    AResourceCollections.Free;
  end;
end;

procedure TACLResourceIDProperty.PopulateResources(AResource: TACLResource; AList: TACLStringList);

  procedure EnumResources(AList: TACLStringList; AResource: TACLResource; ASource: TACLCustomResourceCollection);
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

{ TACLBindingDiagramSelectionEditor }

procedure TACLBindingDiagramSelectionEditor.RequiresUnits(Proc: TGetStrProc);
begin
  Proc('ACL.Classes.Collections');
  Proc('ACL.UI.Controls.BindingDiagram.SubClass');
  Proc('ACL.UI.Controls.BindingDiagram.Types');
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
  Result := ((GetComponent(0) as TACLTreeListColumn).Columns.Owner as TACLTreeListSubClass).OptionsView.Columns.Images;
end;

{ TACLImageListEditor }

procedure TACLImageListEditor.ExecuteVerb(Index: Integer);
begin
  case Index of
    0: TfrmImageListEditor.Execute(GetActiveWindow, GetComponent as TCustomImageList);
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

procedure TACLImageIndexProperty.ListDrawValue(const Value: string; ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
var
  AImageWidth: Integer;
begin
  if Images <> nil then
  begin
    ACanvas.FillRect(ARect);
    if ASelected then
      ACanvas.DrawFocusRect(ARect);
    Images.Draw(ACanvas, ARect.Left + 2, acRectCenterVertically(ARect, Images.Height).Top, StrToInt(Value));
    AImageWidth := Images.Width + 2 * 2;
  end
  else
    AImageWidth := 0;

  ACanvas.TextOut(ARect.Left + AImageWidth + 2, acRectCenterVertically(ARect, ACanvas.TextHeight(Value)).Top, Value);
end;

procedure TACLImageIndexProperty.ListMeasureHeight(const Value: string; ACanvas: TCanvas; var AHeight: Integer);
begin
  AHeight := ACanvas.TextHeight(Value);
  if Images <> nil then
    AHeight := Max(AHeight, Images.Height + 2 * 2);
end;

procedure TACLImageIndexProperty.ListMeasureWidth(const Value: string; ACanvas: TCanvas; var AWidth: Integer);
begin
  AWidth := ACanvas.TextWidth(Value) + 2 * 2;
  if Images <> nil then
    Inc(AWidth, Images.Width + 2 * 2);
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
  AText: string;
begin
  AText := Value;
  if TACLMemoQueryDialog.Execute(GetName, AText) then
    Value := AText;
end;

function TACLMultiLineStringEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
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

{ TACLPageControlEditor }

procedure TACLPageControlEditor.AddPage;
var
  APageControl: TACLPageControl;
begin
  if Component is TACLPageControl then
    APageControl := TACLPageControl(Component)
  else if Component is TACLPageControlPage then
    APageControl := TACLPageControlPage(Component).PageControl
  else
    APageControl := nil;

  if APageControl <> nil then
    APageControl.AddPage('New Page');
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

{ TACLCollectionEditor }

procedure TACLCollectionEditor.Edit;
var
  ACollection: TACLCollection;
  APersistent: TPersistent;
  APropInfo: PPropInfo;
begin
  APropInfo := GetPropInfo;
  APersistent := GetComponent(0);
  ACollection := GetObjectProp(APersistent, APropInfo) as TACLCollection;
  while (APersistent <> nil) and not (APersistent is TComponent) do
    APersistent := TPersistentAccess(APersistent).GetOwner;
  if APersistent <> nil then
    ShowCollectionEditor(Designer, APersistent as TComponent, ACollection, GetPropName(APropInfo));
end;

function TACLCollectionEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog];
end;

{ TACLDropDownImageIndexProperty }

function TACLDropDownImageIndexProperty.GetImages: TCustomImageList;
begin
  Result := TACLDropDown(GetComponent(0)).Images;
end;

end.
