////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   ObjectInspector - Built-in property editors
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.ObjectInspector.PropertyEditors;

{$I ACL.Config.inc}

interface

uses
  {System.}Classes,
  {System.}Contnrs,
  {System.}Generics.Collections,
  {System.}SysUtils,
  {System.}TypInfo,
  {System.}Types,
  // VCL
  {Vcl.}Graphics,
  {Vcl.}Controls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Graphics,
  ACL.Geometry,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Dialogs.ColorPicker,
  ACL.UI.Dialogs.FontPicker,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.RTTI;

type
  TACLPropertyEditor = class;

  { IACLObjectInspector }

  IACLObjectInspector = interface
  ['{2C707A58-8C1D-4277-BACB-2DA06C42FF78}']
    function GetInspectedObject: TPersistent;
    function PropertyChanging(AProperty: TACLPropertyEditor; const AValue: Variant): Boolean;
    procedure PropertyChanged(AProperty: TACLPropertyEditor);
  end;

  { IACLObjectInspectorStyleSet }

  IACLObjectInspectorStyleSet = interface
  ['{91D7860B-C0CE-47D7-B7C9-896F2231E11C}']
    function GetResourceCollection: TACLCustomResourceCollection;
    function GetStyle: TACLStyleTreeList;
    function GetStyleInplaceEdit: TACLStyleEdit;
    function GetStyleHatch: TACLStyleHatch;

    property ResourceCollection: TACLCustomResourceCollection read GetResourceCollection;
    property Style: TACLStyleTreeList read GetStyle;
    property StyleHatch: TACLStyleHatch read GetStyleHatch;
    property StyleInplaceEdit: TACLStyleEdit read GetStyleInplaceEdit;
  end;

  { IACLPropertyEditorCustomDraw }

  IACLPropertyEditorCustomDraw = interface
  ['{76AF59AE-7234-4099-83D0-EBB0DB51E80A}']
    procedure Draw(ACanvas: TCanvas; const ABounds, ATextBounds: TRect);
  end;

  { IACLPropertyEditorCustomEditBox }

  IACLPropertyEditorCustomEditBox = interface
  ['{7453B704-F554-4F63-9210-0977A50609F1}']
    function CreateEditBox(const AParams: TACLInplaceInfo): TControl;
  end;

  { IACLPropertyEditorDialog }

  IACLPropertyEditorDialog = interface
  ['{8D7596A9-B4F8-4699-9D6B-F1BC0FEE5CF1}']
    procedure Edit;
  end;

  { IACLPropertyEditorSubProperties }

  TACLPropertyEditorSubPropertiesProc = reference to procedure (AEditor: TACLPropertyEditor);

  IACLPropertyEditorSubProperties = interface
  ['{0862CA49-CFB8-4905-B019-8292EB35DC79}']
    procedure GetProperties(AProc: TACLPropertyEditorSubPropertiesProc);
  end;

  { IACLPropertyEditorValueList }

  IACLPropertyEditorValueList = interface
  ['{09C17EC0-72A9-468F-AB6F-701E8DF2653A}']
    procedure GetValues(const AValues: TACLStringList);
  end;

  { TACLPropertyEditor }

  TACLPropertyEditorAttribute = (peaEditBox);
  TACLPropertyEditorAttributes =  set of TACLPropertyEditorAttribute;

  TACLPropertyEditorClass = class of TACLPropertyEditor;
  TACLPropertyEditor = class(TACLUnknownObject)
  strict private
    FDesigner: IACLObjectInspector;
    FInfo: PPropInfo;
    FOwner: TObject;
  protected
    FFullName: string;
    FStyleSet: IACLObjectInspectorStyleSet;

    function Changing(const AValue: Variant): Boolean;
    procedure Changed;
    function GetFullName: string; virtual;
    function GetName: string; virtual;
    function GetValue: string; virtual;
    procedure SetValue(const AValue: string); virtual;
  public
    constructor Create(AInfo: PPropInfo; AOwner: TObject; ADesigner: IACLObjectInspector);
    function Attributes: TACLPropertyEditorAttributes; virtual;
    function HasData: Boolean; virtual;
    function IsNonStorable: Boolean;
    function IsReadOnly: Boolean;
    //
    property Designer: IACLObjectInspector read FDesigner;
    property FullName: string read GetFullName;
    property Info: PPropInfo read FInfo;
    property Name: string read GetName;
    property Owner: TObject read FOwner;
    property Value: string read GetValue write SetValue;
  end;

  { TACLPropertyEditors }

  TACLPropertyEditors = class
  strict private type
  {$REGION 'Types'}
    PPropertyInfo = ^TPropertyInfo;
    TPropertyInfo = record
      ComponentClass: TClass;
      EditorClass: TACLPropertyEditorClass;
      PropertyName: string;
      PropertyType: PTypeInfo;
    end;
  {$ENDREGION}
  strict private
    class var FDefaultEditors: array[TTypeKind] of TACLPropertyEditorClass;
    class var FList: TACLList<TPropertyInfo>;
  public
    class destructor Destroy;
    class function GetEditorClass(PropInfo: PPropInfo; Obj: TObject): TACLPropertyEditorClass; overload;
    class function GetEditorClass(TypeInfo: PTypeInfo; Obj: TObject;
      const PropName: string): TACLPropertyEditorClass; overload;

    class procedure Hide(AClass: TClass; const APropertyNames: array of string); overload;
    class procedure Hide(AClass: TClass; const APropertyName: string); overload;

    class procedure Register(Kind: TTypeKind;  EditorClass: TACLPropertyEditorClass); overload;
    class procedure Register(PropertyType: PTypeInfo; ComponentClass: TClass;
      const PropertyName: string; EditorClass: TACLPropertyEditorClass); overload;
  end;

{$REGION 'Built-in PropertyEditors'}

  { TACLAlphaColorPropertyEditor }

  TACLAlphaColorPropertyEditor = class(TACLPropertyEditor,
    IACLPropertyEditorCustomDraw,
    IACLPropertyEditorDialog)
  protected
    function GetValue: string; override;
    function GetValueAsColor: TAlphaColor; virtual;
    function HasAlphaSupport: Boolean; virtual;
    procedure SetValue(const AValue: string); override;
    procedure SetValueAsColor(const Value: TAlphaColor); virtual;
    // IACLPropertyEditorCustomDraw
    procedure Draw(ACanvas: TCanvas; const R, ATextBounds: TRect);
    // IACLPropertyEditorDialog
    procedure Edit; virtual;
  public
    function Attributes: TACLPropertyEditorAttributes; override;
    //# Properties
    property ValueAsColor: TAlphaColor read GetValueAsColor write SetValueAsColor;
  end;

  { TACLColorPropertyEditor }

  TACLColorPropertyEditor = class(TACLAlphaColorPropertyEditor)
  protected
    function GetValueAsColor: TAlphaColor; override;
    function HasAlphaSupport: Boolean; override;
    procedure SetValueAsColor(const Value: TAlphaColor); override;
  end;

  { TACLBooleanPropertyEditor }

  TACLBooleanPropertyEditor = class(TACLPropertyEditor,
    IACLPropertyEditorCustomDraw,
    IACLPropertyEditorCustomEditBox)
  strict private
    procedure InitializeStyles(ACheckBox: TACLCustomCheckBox);
  public
    // IACLPropertyEditorCustomEditBox
    function CreateEditBox(const AParams: TACLInplaceInfo): TControl;
    // IACLPropertyEditorCustomDraw
    procedure Draw(ACanvas: TCanvas; const R, ATextBounds: TRect);
  end;

  { TACLCustomFontPropertyEditor }

  TACLCustomFontPropertyEditor = class abstract(TACLPropertyEditor,
    IACLPropertyEditorCustomDraw,
    IACLPropertyEditorDialog)
  strict private
    function GetFont: TPersistent;
  protected
    procedure SetValue(const AValue: string); override;
    // IACLPropertyEditorCustomDraw
    procedure Draw(ACanvas: TCanvas; const R, ATextBounds: TRect); virtual;
    // IACLPropertyEditorDialog
    procedure Edit; virtual; abstract;
  public
    function Attributes: TACLPropertyEditorAttributes; override;
    //
    property Font: TPersistent read GetFont;
  end;

  { TACLCustomComponentPropertyEditor }

  TACLCustomComponentPropertyEditor = class abstract(TACLPropertyEditor, IACLPropertyEditorValueList)
  strict private
    FPropClass: TClass;

    function GetComponentName(AComponent: TComponent): string;
    // IACLPropertyEditorValueList
    procedure GetValues(const AValues: TACLStringList);
  protected
    // PopulateComponents
    procedure AddChildrenToList(AComponent: TComponent; AValues: TACLStringList);
    procedure AddToList(AComponent: TComponent; AValues: TACLStringList); overload; virtual;
    procedure AddToList(AComponentList: TACLComponentList; AValues: TACLStringList); overload;
    procedure PopulateComponents(AValues: TACLStringList); virtual; abstract;

    function GetValue: string; override;
    function GetValueAsComponent: TComponent;
    procedure SetValue(const AValue: string); override;
    procedure SetValueAsComponent(const Value: TComponent);
  public
    procedure AfterConstruction; override;
    //
    property ValueAsComponent: TComponent read GetValueAsComponent write SetValueAsComponent;
  end;

  { TACLComponentPropertyEditor }

  TACLComponentPropertyEditor = class(TACLCustomComponentPropertyEditor)
  protected
    procedure PopulateComponents(AValues: TACLStringList); override;
  end;

  { TACLEnumPropertyEditor }

  TACLEnumPropertyEditor = class(TACLPropertyEditor,
    IACLPropertyEditorValueList)
  protected
    // IACLPropertyEditorValueList
    procedure GetValues(const AValues: TACLStringList); virtual;
  end;

  { TACLFontPropertyEditor }

  TACLFontPropertyEditor = class(TACLCustomFontPropertyEditor)
  protected
    function GetValue: string; override;
    // IACLPropertyEditorDialog
    procedure Edit; override;
  end;

  { TACLObjectPropertyEditor }

  TACLObjectPropertyEditor = class(TACLPropertyEditor)
  protected
    function GetValue: string; override;
  public
    function Attributes: TACLPropertyEditorAttributes; override;
  end;

  { TACLSetPropertyEditor }

  TACLSetPropertyEditor = class(TACLPropertyEditor,
    IACLPropertyEditorSubProperties)
  protected
    function GetValue: string; override;
    // IACLPropertyEditorSubProperties
    procedure GetProperties(AProc: TACLPropertyEditorSubPropertiesProc);
  public
    function Attributes: TACLPropertyEditorAttributes; override;
  end;

  { TACLSetSubPropertyEditor }

  TACLSetSubPropertyEditor = class(TACLBooleanPropertyEditor)
  strict private
    FIndex: Integer;
    FName: string;
  protected
    function GetFullName: string; override;
    function GetName: string; override;
    function GetValue: string; override;
    procedure SetValue(const AValue: string); override;
  public
    constructor Create(AInfo: PPropInfo; const AName: string;
      AOwner: TObject; AIndex: Integer; ADesigner: IACLObjectInspector); reintroduce;
  end;
{$ENDREGION}

implementation

type
  TACLInplaceCheckBoxAccess = class(TACLInplaceCheckBox);
  TPersistentAccess = class(TPersistent);

{ TACLPropertyEditor }

constructor TACLPropertyEditor.Create(AInfo: PPropInfo; AOwner: TObject; ADesigner: IACLObjectInspector);
begin
  inherited Create;
  FDesigner := ADesigner;
  FStyleSet := ADesigner as IACLObjectInspectorStyleSet;
  FOwner := AOwner;
  FInfo := AInfo;
end;

function TACLPropertyEditor.Attributes: TACLPropertyEditorAttributes;
begin
  Result := [peaEditBox];
end;

function TACLPropertyEditor.Changing(const AValue: Variant): Boolean;
begin
  Result := (FDesigner = nil) or FDesigner.PropertyChanging(Self, AValue);
end;

procedure TACLPropertyEditor.Changed;
begin
  if FDesigner <> nil then
    FDesigner.PropertyChanged(Self);
end;

function TACLPropertyEditor.GetFullName: string;
begin
  Result := FFullName;
end;

function TACLPropertyEditor.GetName: string;
begin
  Result := string(FInfo.Name);
end;

function TACLPropertyEditor.GetValue: string;
begin
  if not TRTTI.GetPropValue(Owner, Info, Result) then
    Result := '';
end;

function TACLPropertyEditor.HasData: Boolean;
begin
  Result := True;
end;

function TACLPropertyEditor.IsNonStorable: Boolean;
begin
  if ({%H-}UIntPtr(Info^.StoredProc) and (not NativeUInt($FF))) = 0 then // is constant
    Result := {%H-}UIntPtr(Info^.StoredProc) and $FF = 0
  else
    Result := False;
end;

function TACLPropertyEditor.IsReadOnly: Boolean;
begin
  Result := (Info.SetProc = nil) and (Info.PropType^.Kind <> tkClass);
end;

procedure TACLPropertyEditor.SetValue(const AValue: string);
begin
  if not IsReadOnly and Changing(AValue) then
  begin
    TRTTI.SetPropValue(Owner, Info, AValue);
    Changed;
  end;
end;

{ TACLPropertyEditors }

class destructor TACLPropertyEditors.Destroy;
begin
  FreeAndNil(FList);
end;

class function TACLPropertyEditors.GetEditorClass(
  PropInfo: PPropInfo; Obj: TObject): TACLPropertyEditorClass;
begin
  Result := GetEditorClass(GetPropType(PropInfo), Obj, GetPropName(PropInfo));
end;

class function TACLPropertyEditors.GetEditorClass(
  TypeInfo: PTypeInfo; Obj: TObject; const PropName: string): TACLPropertyEditorClass;

  function InterfaceInheritsFrom(Child, Parent: PTypeData): Boolean;
  begin
    while (Child <> nil) and (Child <> Parent) and (Child^.IntfParent <> nil) do
      Child := GetTypeData(Child^.IntfParent{$IFNDEF FPC}^{$ENDIF});
    Result := (Child <> nil) and (Child = Parent);
  end;

  function IsClassInherited(S, T: PTypeInfo): Boolean;
  begin
    Result := (S^.Kind = tkClass) and (T^.Kind = tkClass) and
      GetTypeData(S)^.ClassType.InheritsFrom(GetTypeData(T)^.ClassType);
  end;

  function IsInterfaceInherited(S, T: PTypeInfo): Boolean;
  begin
    Result := (S^.Kind = tkInterface) and (T^.Kind = tkInterface) and
      InterfaceInheritsFrom(GetTypeData(S), GetTypeData(T));
  end;

  function IsBetter(ANew, ACur: PPropertyInfo; T: PTypeInfo): Boolean;
  begin
    Result :=
      (ACur^.ComponentClass = nil) and (ANew^.ComponentClass <> nil) or
      (ACur^.PropertyName = '') and (ANew^.PropertyName <> '');
    // ANew's proptype match is exact, but ACur's isn't
    Result := Result or (ACur^.PropertyType <> T) and (ANew^.PropertyType = T);
    // ANew's proptype is more specific than ACur's proptype
    Result := Result or (ANew^.PropertyType <> ACur^.PropertyType) and
      (IsClassInherited(ANew.PropertyType, ACur.PropertyType) or
       IsInterfaceInherited(ANew.PropertyType, ACur.PropertyType));
    // ANew's component class is more specific than ACur's component class
    Result := Result or (ANew^.ComponentClass <> nil) and (ACur^.ComponentClass <> nil) and
      (ANew^.ComponentClass <> ACur^.ComponentClass) and
      (ANew^.ComponentClass.InheritsFrom(ACur^.ComponentClass));
  end;

  function IsSituable(P: PPropertyInfo): Boolean;
  begin
    Result := ((P^.ComponentClass = nil) or (Obj <> nil) and (Obj.InheritsFrom(P^.ComponentClass))) and
      ((P^.PropertyName = '') or (CompareText(PropName, P^.PropertyName) = 0));
  end;

var
  I: Integer;
  P, C: PPropertyInfo;
  T: PTypeInfo;
begin
  T := TypeInfo;
  I := 0;
  C := nil;
  while (FList <> nil) and (I < FList.Count) do
  begin
    P := @FList.List[I];
    if (T = P^.PropertyType) or IsClassInherited(T, P^.PropertyType) or IsInterfaceInherited(T, P^.PropertyType) then
    begin
      if IsSituable(P) and ((C = nil) or IsBetter(P, C, T)) then
        C := P;
    end;
    Inc(I);
  end;

  if C <> nil then
    Result := C^.EditorClass
  else
    Result := FDefaultEditors[T.Kind];
end;

class procedure TACLPropertyEditors.Hide(AClass: TClass; const APropertyNames: array of string);
var
  I: Integer;
begin
  for I := 0 to Length(APropertyNames) - 1 do
    Hide(AClass, APropertyNames[I]);
end;

class procedure TACLPropertyEditors.Hide(AClass: TClass; const APropertyName: string);
var
  AInfo: PPropInfo;
begin
  AInfo := GetPropInfo(AClass, APropertyName);
  if AInfo <> nil then
    Register(GetPropType(AInfo), AClass, APropertyName, nil);
end;

class procedure TACLPropertyEditors.Register(Kind: TTypeKind; EditorClass: TACLPropertyEditorClass);
begin
  FDefaultEditors[Kind] := EditorClass;
end;

class procedure TACLPropertyEditors.Register(PropertyType: PTypeInfo;
  ComponentClass: TClass; const PropertyName: string; EditorClass: TACLPropertyEditorClass);
var
  P: TPropertyInfo;
begin
  P.EditorClass := EditorClass;
  P.PropertyType := PropertyType;
  P.ComponentClass := ComponentClass;
  P.PropertyName := '';
  if ComponentClass <> nil then
    P.PropertyName := PropertyName;
  if FList = nil then
    FList := TACLList<TPropertyInfo>.Create;
  FList.Insert(0, P);
end;

{$REGION 'Built-in PropertyEditors'}
{ TACLAlphaColorPropertyEditor }

function TACLAlphaColorPropertyEditor.Attributes: TACLPropertyEditorAttributes;
begin
  Result := [];
end;

function TACLAlphaColorPropertyEditor.GetValue: string;
begin
  Result := ValueAsColor.ToString;
end;

function TACLAlphaColorPropertyEditor.GetValueAsColor: TAlphaColor;
begin
  Result := GetOrdProp(Owner, Info);
end;

function TACLAlphaColorPropertyEditor.HasAlphaSupport: Boolean;
begin
  Result := True;
end;

procedure TACLAlphaColorPropertyEditor.SetValue(const AValue: string);
begin
  ValueAsColor := TAlphaColor.FromString(AValue);
end;

procedure TACLAlphaColorPropertyEditor.SetValueAsColor(const Value: TAlphaColor);
begin
  if Changing(Value) then
  begin
    SetOrdProp(Owner, Info, Value);
    Changed;
  end;
end;

procedure TACLAlphaColorPropertyEditor.Draw(ACanvas: TCanvas; const R, ATextBounds: TRect);
var
  R1: TRect;
begin
  R1 := R;
  R1.Right := R1.Left + R1.Height;
  ACanvas.Brush.Style := bsClear;
  acTextDraw(ACanvas, Value,
    Rect(R1.Right + acTextIndent, R.Top, R.Right, R.Bottom),
    taLeftJustify, taVerticalCenter);
  R1.Inflate(-acTextIndent);
  FStyleSet.StyleHatch.DrawColorPreview(ACanvas, R1, ValueAsColor);
end;

procedure TACLAlphaColorPropertyEditor.Edit;
var
  AColor: TAlphaColor;
begin
  AColor := ValueAsColor;
  if TACLColorPickerDialog.Execute(AColor, HasAlphaSupport) then
    ValueAsColor := AColor;
end;

{ TACLColorPropertyEditor }

function TACLColorPropertyEditor.GetValueAsColor: TAlphaColor;
begin
  Result := TAlphaColor.FromColor(GetOrdProp(Owner, Info));
end;

function TACLColorPropertyEditor.HasAlphaSupport: Boolean;
begin
  Result := False;
end;

procedure TACLColorPropertyEditor.SetValueAsColor(const Value: TAlphaColor);
begin
  if (ValueAsColor <> Value) and Changing(Value.ToColor) then
  begin
    SetOrdProp(Owner, Info, Value.ToColor);
    Changed;
  end;
end;

{ TACLBooleanPropertyEditor }

function TACLBooleanPropertyEditor.CreateEditBox(const AParams: TACLInplaceInfo): TControl;
var
  ACheckBox: TACLInplaceCheckBox;
begin
  ACheckBox := TACLInplaceCheckBox.CreateInplace(AParams);
  InitializeStyles(ACheckBox);
  Result := ACheckBox;
end;

procedure TACLBooleanPropertyEditor.Draw(ACanvas: TCanvas; const R, ATextBounds: TRect);
var
  ACheckBox: TACLInplaceCheckBoxAccess;
begin
  ACheckBox := TACLInplaceCheckBoxAccess.Create(nil);
  try
    ACheckBox.ParentFont := False;
    ACheckBox.InplaceSetValue(Value);
    ACheckBox.SubClass.IsEnabled := True;
    InitializeStyles(ACheckBox);
    ACheckBox.Font := ACanvas.Font;
    ACheckBox.SubClass.Calculate(Rect(ATextBounds.Left, R.Top, R.Right, R.Bottom));
    ACheckBox.SubClass.Draw(ACanvas);
  finally
    ACheckBox.Free;
  end;
end;

procedure TACLBooleanPropertyEditor.InitializeStyles(ACheckBox: TACLCustomCheckBox);
begin
  ACheckBox.ScaleForPPI(FStyleSet.Style.TargetDPI);
  ACheckBox.ResourceCollection := FStyleSet.ResourceCollection;
  ACheckBox.Style.Collection := FStyleSet.Style.Collection;
  ACheckBox.Style.Texture := FStyleSet.Style.CheckMark;
  ACheckBox.Style.ColorText := FStyleSet.StyleInplaceEdit.ColorText;
  ACheckBox.Style.ColorTextHover := FStyleSet.StyleInplaceEdit.ColorText;
  ACheckBox.Style.ColorTextPressed := FStyleSet.StyleInplaceEdit.ColorText;
  ACheckBox.Style.ColorTextDisabled := FStyleSet.StyleInplaceEdit.ColorTextDisabled;
end;

{ TACLCustomFontPropertyEditor }

function TACLCustomFontPropertyEditor.Attributes: TACLPropertyEditorAttributes;
begin
  Result := [];
end;

procedure TACLCustomFontPropertyEditor.Draw(ACanvas: TCanvas; const R, ATextBounds: TRect);
var
  ATempFont: TFont;
  R1: TRect;
begin
  ATempFont := TFont.Create;
  try
    ATempFont.Assign(Font);

    R1 := R;
    R1.Right := R1.Left + R1.Height;
    ACanvas.Font.Name := ATempFont.Name;
    acTextDraw(ACanvas, Value,
      Rect(R1.Right + acTextIndent, R.Top, R.Right, R.Bottom),
      taLeftJustify, taVerticalCenter);

    R1.Inflate(-acTextIndent);
    FStyleSet.StyleHatch.DrawColorPreview(
      ACanvas, R1, TAlphaColor.FromColor(ATempFont.Color));
  finally
    ATempFont.Free;
  end;
end;

function TACLCustomFontPropertyEditor.GetFont: TPersistent;
begin
  Result := TPersistent(GetObjectProp(Owner, Info, TPersistent));
end;

procedure TACLCustomFontPropertyEditor.SetValue(const AValue: string);
begin
  // do nothing
end;

{ TACLCustomComponentPropertyEditor }

procedure TACLCustomComponentPropertyEditor.AfterConstruction;
begin
  inherited AfterConstruction;
  FPropClass := GetObjectPropClass(Info);
end;

procedure TACLCustomComponentPropertyEditor.AddChildrenToList(
  AComponent: TComponent; AValues: TACLStringList);
var
  I: Integer;
begin
  for I := 0 to AComponent.ComponentCount - 1 do
    AddToList(AComponent.Components[I], AValues);
end;

procedure TACLCustomComponentPropertyEditor.AddToList(
  AComponent: TComponent; AValues: TACLStringList);
begin
  if (AComponent.Name <> '') and AComponent.InheritsFrom(FPropClass) then
    AValues.Add(GetComponentName(AComponent), AComponent);
end;

procedure TACLCustomComponentPropertyEditor.AddToList(
  AComponentList: TACLComponentList; AValues: TACLStringList);
var
  I: Integer;
begin
  for I := 0 to AComponentList.Count - 1 do
    AddToList(AComponentList[I], AValues);
end;

function TACLCustomComponentPropertyEditor.GetValue: string;
begin
  Result := GetComponentName(ValueAsComponent);
end;

function TACLCustomComponentPropertyEditor.GetValueAsComponent: TComponent;
begin
  Result := TComponent(GetObjectProp(Owner, Info, TComponent));
end;

function TACLCustomComponentPropertyEditor.GetComponentName(AComponent: TComponent): string;
begin
  if AComponent <> nil then
  begin
    Result := AComponent.Name;
    if Result = '' then
      Result := Format('<Components[%d]>', [AComponent.ComponentIndex]);
  end
  else
    Result := '';
end;

procedure TACLCustomComponentPropertyEditor.GetValues(const AValues: TACLStringList);
begin
  AValues.BeginUpdate;
  try
    PopulateComponents(AValues);
    AValues.SortLogical;
    AValues.Insert(0, '');
    if AValues.IndexOf(Value) < 0 then
      AValues.Insert(1, Value);
  finally
    AValues.EndUpdate;
  end;
end;

procedure TACLCustomComponentPropertyEditor.SetValue(const AValue: string);
var
  AIndex: Integer;
  ATempItems: TACLStringList;
begin
  if AValue <> '' then
  begin
    ATempItems := TACLStringList.Create;
    try
      GetValues(ATempItems);
      AIndex := ATempItems.IndexOf(AValue);
      if AIndex >= 0 then
        ValueAsComponent := ATempItems.Objects[AIndex] as TComponent
    finally
      ATempItems.Free;
    end;
  end
  else
    ValueAsComponent := nil;
end;

procedure TACLCustomComponentPropertyEditor.SetValueAsComponent(const Value: TComponent);
begin
  if Changing(NativeUInt(Value)) then
  begin
    if (Value = nil) or (Value is GetObjectPropClass(Info)) then
      SetObjectProp(Owner, Info, Value);
    Changed;
  end;
end;

{ TACLComponentPropertyEditor }

procedure TACLComponentPropertyEditor.PopulateComponents(AValues: TACLStringList);
var
  AOwner: TPersistent;
begin
  if Owner is TPersistent then
  begin
    AOwner := Designer.GetInspectedObject;
    repeat
      AOwner := TPersistentAccess(AOwner).GetOwner;
      if AOwner is TComponent then
      begin
        AddChildrenToList(TComponent(AOwner), AValues);
        Break;
      end;
    until AOwner = nil;
  end;
end;

{ TACLEnumPropertyEditor }

procedure TACLEnumPropertyEditor.GetValues(const AValues: TACLStringList);
var
  LTypeData: PTypeData;
  LTypeInfo: PTypeInfo;
  I: Integer;
begin
  LTypeInfo := GetPropType(Info);
  LTypeData := GetTypeData(LTypeInfo);
  for I := LTypeData^.MinValue to LTypeData^.MaxValue do
    AValues.Add(GetEnumName(LTypeInfo, I), TObject(I));
end;

{ TACLFontPropertyEditor }

function TACLFontPropertyEditor.GetValue: string;
begin
  with TFont(Font) do
    Result := Format('%s, %dpt', [Name, Abs(Size)]);
end;

procedure TACLFontPropertyEditor.Edit;
var
  AFont: TFont;
begin
  AFont := TFont.Create;
  try
    AFont.Assign(Font);
    if TACLFontPickerDialog.Execute(AFont) then
    begin
      if Changing(NativeUInt(AFont)) then
      begin
        Font.Assign(AFont);
        Changed;
      end;
    end;
  finally
    AFont.Free;
  end;
end;

{ TACLObjectPropertyEditor }

function TACLObjectPropertyEditor.Attributes: TACLPropertyEditorAttributes;
begin
  Result := [];
end;

function TACLObjectPropertyEditor.GetValue: string;
var
  AObject: TObject;
begin
  AObject := GetObjectProp(Owner, Info);
  if AObject <> nil then
    Result := AObject.ToString;
  if Result = '' then
    Result := GetObjectPropClass(Info).ClassName;
  Result := '(' + Result + ')';
end;

{ TACLSetPropertyEditor }

function TACLSetPropertyEditor.Attributes: TACLPropertyEditorAttributes;
begin
  Result := [];
end;

function TACLSetPropertyEditor.GetValue: string;
begin
  Result := '[' + inherited GetValue + ']';
end;

procedure TACLSetPropertyEditor.GetProperties(AProc: TACLPropertyEditorSubPropertiesProc);
var
  ATypeData: PTypeData;
  ATypeInfo: PTypeInfo;
  I: Integer;
begin
  ATypeInfo := GetPropType(Info);
  ATypeInfo := GetTypeData(ATypeInfo)^.CompType{$IFNDEF FPC}^{$ENDIF};
  ATypeData := GetTypeData(ATypeInfo);
  for I := ATypeData^.MinValue to ATypeData^.MaxValue do
    AProc(TACLSetSubPropertyEditor.Create(Info, GetEnumName(ATypeInfo, I), Owner, I, Designer))
end;

{ TACLSetSubPropertyEditor }

constructor TACLSetSubPropertyEditor.Create(AInfo: PPropInfo;
  const AName: string; AOwner: TObject; AIndex: Integer; ADesigner: IACLObjectInspector);
begin
  inherited Create(AInfo, AOwner, ADesigner);
  FIndex := AIndex;
  FName := AName;
end;

function TACLSetSubPropertyEditor.GetFullName: string;
begin
  Result := inherited;
  Result := Copy(Result, 1, LastDelimiter('.', Result) - 1);
end;

function TACLSetSubPropertyEditor.GetName: string;
begin
  Result := FName;
end;

function TACLSetSubPropertyEditor.GetValue: string;
var
  ASet: TIntegerSet;
begin
  Integer(ASet) := GetOrdProp(Owner, Info);
  Result := BoolToStr(FIndex in ASet, True)
end;

procedure TACLSetSubPropertyEditor.SetValue(const AValue: string);
var
  ASet: TIntegerSet;
begin
  Integer(ASet) := GetOrdProp(Owner, Info);

  if AValue = BoolToStr(True, True) then
    ASet := ASet + [FIndex]
  else
    ASet := ASet - [FIndex];

  if GetOrdProp(Owner, Info) <> Integer(ASet) then
  begin
    if Changing(Integer(ASet)) then
    begin
      SetOrdProp(Owner, Info, Integer(ASet));
      Changed;
    end;
  end;
end;

initialization
  TACLPropertyEditors.Register(tkClass, TACLObjectPropertyEditor);
  TACLPropertyEditors.Register(tkEnumeration, TACLEnumPropertyEditor);
  TACLPropertyEditors.Register(tkFloat, TACLPropertyEditor);
  TACLPropertyEditors.Register(tkInt64, TACLPropertyEditor);
  TACLPropertyEditors.Register(tkInteger, TACLPropertyEditor);
  TACLPropertyEditors.Register(tkLString, TACLPropertyEditor);
  TACLPropertyEditors.Register(tkSet, TACLSetPropertyEditor);
  TACLPropertyEditors.Register(tkString, TACLPropertyEditor);
  TACLPropertyEditors.Register(tkUString, TACLPropertyEditor);
  TACLPropertyEditors.Register(tkWString, TACLPropertyEditor);
  TACLPropertyEditors.Register(tkVariant, TACLPropertyEditor);
{$IFDEF FPC}
  TACLPropertyEditors.Register(tkAString, TACLPropertyEditor);
  TACLPropertyEditors.Register(tkBool, TACLEnumPropertyEditor);
{$ENDIF}

  TACLPropertyEditors.Register(TypeInfo(TComponent), TPersistent, '', TACLComponentPropertyEditor);
  TACLPropertyEditors.Register(TypeInfo(TAlphaColor), nil, '', TACLAlphaColorPropertyEditor);
  TACLPropertyEditors.Register(TypeInfo(TColor), nil, '', TACLColorPropertyEditor);
  TACLPropertyEditors.Register(TypeInfo(Boolean), nil, '', TACLBooleanPropertyEditor);
  TACLPropertyEditors.Register(TypeInfo(TFont), nil, '', TACLFontPropertyEditor);
{$ENDREGION}
end.
