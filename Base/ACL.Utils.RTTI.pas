////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   RTTI Utilities
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Utils.RTTI;

{$I ACL.Config.inc}

interface

uses
  {System.}Classes,
  {System.}SysUtils,
  {System.}Variants,
  {System.}TypInfo,
  {System.}Rtti;

type
  TMemberVisibilities = set of TMemberVisibility;

  TRttiEnumProc<T> = reference to procedure (const AValue: T);

  { ERttiError }

  ERttiError = class(EPropertyError)
  public
    constructor CreateNoProp(const AClassName, AFieldName: string);
    constructor CreatePropError(AObject: TObject; APropInfo: PPropInfo; const AErrorText: string);
    constructor CreateUnsupportedPropType(APropInfo: PPropInfo);
    class procedure EnsureWritable(AObject: TObject; APropInfo: PPropInfo);
  end;

  { TRTTI }

  TRTTI = class
  strict private
    class var FContext: TRttiContext;
    class function GetPropertiesCore(AClassInfo: Pointer;
      out AList: PPropList; out ACount: Integer): Boolean;
  public
    class constructor Create;
    class destructor Destroy;

    class procedure EnumClassProperties<T: class>(
      AObject: TObject; AEnumProc: TRttiEnumProc<T>;
      ARecursive: Boolean = True; AVisibility: TMemberVisibilities = [mvPublished]);

    class function FindPropertyByName(AProperties: TArray<TRttiProperty>;
      const AName: string; out AProperty: TRttiProperty): Boolean; overload;
    class function FindPropertyByName(AType: TRttiType;
      const AName: string; out AProperty: TRttiProperty): Boolean; overload;

    class function GetProperties(AClass: TClass;
      out AList: PPropList; out ACount: Integer): Boolean; overload;
    class function GetProperties(AObject: TObject;
      out AList: PPropList; out ACount: Integer): Boolean; overload;
    class function GetPropInfo(AObject: TObject;
      const AName: string; AVisibility: TMemberVisibilities = [mvPublished]): PPropInfo;
    class function GetType(AObject: TObject): TRttiType; static;

    class function IsBoolean(APropInfo: PPropInfo): Boolean;
    class function IsFloat(APropInfo: PPropInfo): Boolean; inline;
    class function IsSameType(APropInfo: PPropInfo; const ATypeInfo: Pointer): Boolean;
    class function IsStored(AObject: TObject; APropInfo: PPropInfo): Boolean;
    class function IsString(APropInfo: PPropInfo): Boolean; inline;
    class function IsUnsignedInt(APropInfo: PPropInfo): Boolean;

    class function GetPropAttribute(AObject: TObject; APropInfo: PPropInfo;
      AClass: TCustomAttributeClass; ACheckParents: Boolean = True): TCustomAttribute; overload;

    class function GetPropValue(AObject: TObject;
      const APropInfo: PPropInfo): string; overload;
    class function GetPropValue(AObject: TObject;
      const APropInfo: PPropInfo; out AValue: string): Boolean; overload;
    class function GetPropValue(AObject: TObject;
      const AName: string): string; overload;
    class function GetPropValueAsVariant(AObject: TObject;
      const APropInfo: PPropInfo; PreferStrings: Boolean = False): Variant; overload;
    class function GetPropValueAsVariant(AObject: TObject;
      const AName: string; PreferStrings: Boolean = False): Variant; overload;

    class procedure SetEnumPropValue(AObject: TObject;
      const APropInfo: PPropInfo; const AValue: string);
    class procedure SetPropValue(AObject: TObject;
      const APropInfo: PPropInfo; const AValue: string); overload;
    class procedure SetPropValue(AObject: TObject;
      const AName, AValue: string); overload;
    class procedure SetPropValueAsVariant(AObject: TObject;
      const APropInfo: PPropInfo; const AValue: Variant); overload;
    class procedure SetPropValueAsVariant(AObject: TObject;
      const AName: string; const AValue: Variant); overload;

    class function ResolvePropInfo(var AObject: TObject;
      ANamePath: string; AVisibility: TMemberVisibilities = [mvPublished]): PPropInfo;

    // Returns nil, if property does not exists or object is not inherited from the AMinClass
    class function TryGetPropObject<T: class>(
      AObject: TObject; const AName: string): T; overload; inline;
    class function TryGetPropObject(AObject: TObject;
      const AName: string; AMinClass: TClass): TObject; overload;

    class property Context: TRttiContext read FContext;
  end;

  { HiddenAttribute }

  HiddenAttribute = class(TCustomAttribute)
{$IFDEF FPC}
  public
    constructor Create;
{$ENDIF}
  end;

  { TValueHelper }

  TValueHelper = record helper for TValue
  public
    class function FromOrdinal(AType: TRttiType; const AValue: Int64): TValue; overload; static;
  end;

{$IFDEF FPC}
function GetObjectPropClass(PropInfo: PPropInfo): TClass;
function GetPropName(PropInfo: PPropInfo): string;
{$ENDIF}
function GetPropType(PropInfo: PPropInfo): PTypeInfo; inline;

procedure SetBoolProp(Instance: TObject; PropInfo: PPropInfo; Value: Boolean);
implementation

uses
  {System.}Math,
  {System.}RTLConsts,
  // ACL
  ACL.FastCode,
  ACL.Utils.Common,
  ACL.Utils.Strings;

{$IFDEF FPC}
function GetObjectPropClass(PropInfo: PPropInfo): TClass;
var
  TypeData: PTypeData;
begin
  TypeData := GetTypeData(PropInfo^.PropType);
  if TypeData = nil then
    raise EPropertyError.CreateRes(@SInvalidPropertyValue);
  Result := TypeData^.ClassType;
end;

function GetPropName(PropInfo: PPropInfo): string;
begin
  Result := PropInfo^.Name;
end;
{$ENDIF}

function GetPropType(PropInfo: PPropInfo): PTypeInfo; inline;
begin
  Result := PropInfo^.PropType{$IFNDEF FPC}^{$ENDIF};
end;

procedure SetBoolProp(Instance: TObject; PropInfo: PPropInfo; Value: Boolean);
begin
  SetOrdProp(Instance, PropInfo, IfThen(Value, 1, 0));
end;

{ ERttiError }

constructor ERttiError.CreateNoProp(const AClassName, AFieldName: string);
begin
  CreateFmt('The %s.%s property was not found', [AClassName, AFieldName]);
end;

constructor ERttiError.CreatePropError(
  AObject: TObject; APropInfo: PPropInfo; const AErrorText: string);
begin
  CreateFmt('%s.%s - %s', [AObject.ClassName, GetPropName(APropInfo), AErrorText]);
end;

constructor ERttiError.CreateUnsupportedPropType(APropInfo: PPropInfo);
begin
  CreateFmt('The %s property has unsupported type (%d)',
    [GetPropName(APropInfo), Ord(GetPropType(APropInfo)^.Kind)]);
end;

class procedure ERttiError.EnsureWritable(AObject: TObject; APropInfo: PPropInfo);
begin
  if AObject = nil then
    raise ERttiError.Create('Object cannot be nil');
  if APropInfo = nil then
    raise ERttiError.CreateFmt('%s: property is not specified', [AObject.ClassName]);
  if APropInfo.SetProc = nil then
    raise ERttiError.CreateFmt('The %s.%s is read only', [AObject.ClassName, GetPropName(APropInfo)]);
end;

{ TRTTI }

class constructor TRTTI.Create;
begin
  FContext := TRttiContext.Create;
end;

class destructor TRTTI.Destroy;
begin
  FContext.Free;
end;

class procedure TRTTI.EnumClassProperties<T>(AObject: TObject;
  AEnumProc: TRttiEnumProc<T>; ARecursive: Boolean; AVisibility: TMemberVisibilities);
var
  LProperties: TArray<TRttiProperty>;
  LProperty: TRttiProperty;
  LPropertyValue: TObject;
  I: Integer;
begin
  LProperties := GetType(AObject).GetProperties;
  for I := 0 to Length(LProperties) - 1 do
  begin
    LProperty := LProperties[I];
    if (LProperty.PropertyType.TypeKind = tkClass) and (LProperty.Visibility in AVisibility) then
    begin
      LPropertyValue := LProperty.GetValue(AObject).AsObject;
      if (LPropertyValue = nil) or (LPropertyValue is TComponent) then
        Continue;
      if LPropertyValue.InheritsFrom(T) then
        AEnumProc(T(LPropertyValue))
      else
        if ARecursive then
          EnumClassProperties<T>(LPropertyValue, AEnumProc, ARecursive, AVisibility);
    end;
  end;
end;

class function TRTTI.GetProperties(
  AClass: TClass; out AList: PPropList; out ACount: Integer): Boolean;
begin
  Result := (AClass <> nil) and GetPropertiesCore(AClass.ClassInfo, AList, ACount);
end;

class function TRTTI.GetProperties(
  AObject: TObject; out AList: PPropList; out ACount: Integer): Boolean;
begin
  Result := (AObject <> nil) and GetPropertiesCore(AObject.ClassInfo, AList, ACount);
end;

class function TRTTI.GetPropertiesCore(
  AClassInfo: Pointer; out AList: PPropList; out ACount: Integer): Boolean;
begin
  ACount := GetTypeData(AClassInfo)^.PropCount;
  Result := ACount > 0;
  if Result then
  begin
    AList := AllocMem(ACount * SizeOf(Pointer));
    GetPropInfos(AClassInfo, AList);
  end;
end;

class function TRTTI.FindPropertyByName(AType: TRttiType;
  const AName: string; out AProperty: TRttiProperty): Boolean;
begin
  Result := FindPropertyByName(AType.GetProperties, AName, AProperty);
end;

class function TRTTI.FindPropertyByName(AProperties: TArray<TRttiProperty>;
  const AName: string; out AProperty: TRttiProperty): Boolean;
var
  I: Integer;
begin
  for I := 0 to Length(AProperties) - 1 do
    if AProperties[I].Name = AName then
    begin
      AProperty := AProperties[I];
      Exit(True);
    end;

  Result := False;
end;

class function TRTTI.GetPropInfo(AObject: TObject;
  const AName: string; AVisibility: TMemberVisibilities): PPropInfo;
var
  AProperty: TRttiProperty;
begin
  if mvPublished in AVisibility then
    Result := {System.}TypInfo.GetPropInfo(AObject, AName)
  else
    Result := nil;

  if (Result = nil) and (AVisibility - [mvPublished] <> []) then
  begin
    if FindPropertyByName(GetType(AObject), AName, AProperty) and (AProperty.Visibility in AVisibility) then
    begin
    {$IFDEF FPC}
      Result := AProperty.Handle;
    {$ELSE}
      if AProperty is TRttiInstanceProperty then
        Result := TRttiInstanceProperty(AProperty).PropInfo;
    {$ENDIF}
    end;
  end;
end;

class function TRTTI.GetType(AObject: TObject): TRttiType;
begin
  Result := Context.GetType(AObject.ClassInfo);
  if Result = nil then
    raise ERttiError.CreateFmt('%s clas has no RTTI info', [AObject.ClassName]);
end;

class function TRTTI.ResolvePropInfo(var AObject: TObject;
  ANamePath: string; AVisibility: TMemberVisibilities): PPropInfo;

  function RequirePropInfo(const AName: string): PPropInfo;
  begin
    Result := GetPropInfo(AObject, AName, AVisibility);
    if Result = nil then
      raise EPropertyError.CreateFmt('Unknown property %s.%s', [AObject.ClassName, AName]);
  end;

var
  LPos: Integer;
begin
  repeat
    LPos := acPos('.', ANamePath);
    if LPos = 0 then
      Exit(RequirePropInfo(ANamePath));

    Result := RequirePropInfo(Copy(ANamePath, 1, LPos - 1));
    if Result.PropType^.Kind <> tkClass then
      raise EPropertyError.CreateFmt('Invalid property type: %s.%s', [AObject.ClassName, GetPropName(Result)]);

    AObject := GetObjectProp(AObject, Result);
    ANamePath := Copy(ANamePath, LPos + 1);
  until False;
end;

class function TRTTI.IsBoolean(APropInfo: PPropInfo): Boolean;
begin
  Result := IsSameType(APropInfo, TypeInfo(Boolean));
end;

class function TRTTI.IsFloat(APropInfo: PPropInfo): Boolean;
begin
  Result := APropInfo.PropType^.Kind = tkFloat;
end;

class function TRTTI.IsStored(AObject: TObject; APropInfo: PPropInfo): Boolean;
begin
  Result := IsStoredProp(AObject, APropInfo) and (APropInfo^.PropType^.Kind <> tkMethod)
    {$IFNDEF FPC}and not IsDefaultPropertyValue(AObject, APropInfo, nil){$ENDIF};
end;

class function TRTTI.IsString(APropInfo: PPropInfo): Boolean;
begin
  Result := APropInfo.PropType^.Kind in [tkString, tkLString,
    tkWString, tkUString{$IFDEF FPC}, tkAString{$ENDIF} ];
end;

class function TRTTI.IsUnsignedInt(APropInfo: PPropInfo): Boolean;
var
  ATypeData: PTypeData;
begin
  Result := False;
  if APropInfo^.PropType^.Kind = tkInteger then
  begin
    ATypeData := GetTypeData(GetPropType(APropInfo));
    Result := ATypeData.MinValue >= ATypeData.MaxValue;
  end;
end;

class function TRTTI.GetPropAttribute(AObject: TObject; APropInfo: PPropInfo;
  AClass: TCustomAttributeClass; ACheckParents: Boolean): TCustomAttribute;
var
  LAttr: TCustomAttribute;
  LName: string;
  LProp: TRttiProperty;
  LType: TRttiType;
begin
  Result := nil;
{$IFNDEF FPC}
  if not HasCustomAttribute(AObject, APropInfo) then Exit;
{$ENDIF}
  LName := GetPropName(APropInfo);
  LType := Context.GetType(AObject.ClassInfo);
  while LType <> nil do
  begin
    LProp := LType.GetProperty(LName);
    if LProp <> nil then
    begin
      for LAttr in LProp.GetAttributes do
      begin
        if LAttr.InheritsFrom(AClass) then
          Exit(LAttr);
      end;
      if not ACheckParents then Exit;
    end;
    LType := LType.BaseType;
  end;
end;

class function TRTTI.IsSameType(APropInfo: PPropInfo; const ATypeInfo: Pointer): Boolean;
begin
  Result := (APropInfo <> nil) and (GetPropType(APropInfo) = ATypeInfo);
end;

class function TRTTI.GetPropValue(AObject: TObject; const APropInfo: PPropInfo): string;
begin
  if not GetPropValue(AObject, APropInfo, Result) then
    Result := '';
end;

class function TRTTI.GetPropValue(AObject: TObject;
  const APropInfo: PPropInfo; out AValue: string): Boolean;
var
  LValue: Variant;
begin
  Result := APropInfo <> nil;
  if Result then
  begin
    LValue := GetPropValueAsVariant(AObject, APropInfo, True);
    if VarIsFloat(LValue) then
      AValue := FloatToStr(Double(LValue), InvariantFormatSettings)
    else
      AValue := VarToStr(LValue);
  end;
end;

class function TRTTI.GetPropValue(AObject: TObject; const AName: string): string;
begin
  if AObject <> nil then
    Result := GetPropValue(AObject, GetPropInfo(AObject, AName))
  else
    Result := '';
end;

class function TRTTI.GetPropValueAsVariant(
  AObject: TObject; const APropInfo: PPropInfo; PreferStrings: Boolean): Variant;
begin
  if AObject = nil then
    Exit(Null);

  Result := TypInfo.GetPropValue(AObject, APropInfo, PreferStrings);
{$IFDEF FPC}
  if IsBoolean(APropInfo) then
  begin
    if PreferStrings then
      Result := BoolToStr(Result <> 0, True)
    else
      Result := Result <> 0;
  end
  else
{$ENDIF}
    if IsUnsignedInt(APropInfo) then
      Result := LongWord(Int64(Result));
end;

class function TRTTI.GetPropValueAsVariant(
  AObject: TObject; const AName: string; PreferStrings: Boolean): Variant;
begin
  if AObject <> nil then
    Result := GetPropValueAsVariant(AObject, GetPropInfo(AObject, AName), PreferStrings)
  else
    Result := Null;
end;

class procedure TRTTI.SetEnumPropValue(
  AObject: TObject; const APropInfo: PPropInfo; const AValue: string);
var
  LData: Integer;
  LTypeData: PTypeData;
  LValueOrd: Integer;
begin
  ERttiError.EnsureWritable(AObject, APropInfo);

  LData := GetEnumValue(GetPropType(APropInfo), AValue);
  if LData < 0 then
  begin
    LTypeData := GetTypeData(GetPropType(APropInfo));
    LValueOrd := StrToIntDef(AValue, LTypeData^.MinValue - 1);
    if (LValueOrd >= LTypeData^.MinValue) and (LValueOrd <= LTypeData^.MaxValue) then
      LData := LValueOrd;
  end;
  if LData >= 0 then
    SetOrdProp(AObject, APropInfo, LData)
  else
    raise ERttiError.CreateFmt('Can''t set "%s" to "%s.%s"',
      [AValue, AObject.ClassName, GetPropName(APropInfo)]);
end;

class procedure TRTTI.SetPropValue(AObject: TObject; const AName, AValue: string);
begin
  SetPropValue(AObject, GetPropInfo(AObject, AName), AValue);
end;

class procedure TRTTI.SetPropValue(AObject: TObject; const APropInfo: PPropInfo; const AValue: string);
begin
  ERttiError.EnsureWritable(AObject, APropInfo);
  try
    case APropInfo^.PropType^.Kind of
      tkEnumeration:
        SetEnumPropValue(AObject, APropInfo, AValue);
      tkFloat:
        SetFloatProp(AObject, APropInfo, StrToFloat(AValue, InvariantFormatSettings));
    else
      TypInfo.SetPropValue(AObject, APropInfo, AValue);
    end;
  except
    on E: Exception do
      raise ERttiError.CreatePropError(AObject, APropInfo, E.Message);
  end;
end;

class procedure TRTTI.SetPropValueAsVariant(
  AObject: TObject; const APropInfo: PPropInfo; const AValue: Variant);
begin
  ERttiError.EnsureWritable(AObject, APropInfo);
  try
    if IsBoolean(APropInfo) and VarIsNumeric(AValue) then
      SetBoolProp(AObject, APropInfo, FastTrunc(AValue) <> 0)
    else if VarIsStr(AValue) then
      SetPropValue(AObject, APropInfo, VarToStr(AValue))
    else
      TypInfo.SetPropValue(AObject, APropInfo, AValue);
  except
    on E: Exception do
      raise ERttiError.CreatePropError(AObject, APropInfo, E.Message);
  end;
end;

class procedure TRTTI.SetPropValueAsVariant(
  AObject: TObject; const AName: string; const AValue: Variant);
begin
  SetPropValueAsVariant(AObject, GetPropInfo(AObject, AName), AValue);
end;

class function TRTTI.TryGetPropObject<T>(AObject: TObject; const AName: string): T;
begin
  Result := T(TryGetPropObject(AObject, AName, T));
end;

class function TRTTI.TryGetPropObject(AObject: TObject; const AName: string; AMinClass: TClass): TObject;
var
  LPropInfo: PPropInfo;
begin
  Result := nil;
  if AObject <> nil then
  begin
    LPropInfo := TypInfo.GetPropInfo(AObject, AName, [tkClass]);
    if LPropInfo <> nil then
      Result := GetObjectProp(AObject, LPropInfo, AMinClass);
  end;
end;

{ HiddenAttribute }

{$IFDEF FPC}
constructor HiddenAttribute.Create;
begin
end;
{$ENDIF}

{ TValueHelper }

class function TValueHelper.FromOrdinal(AType: TRttiType; const AValue: Int64): TValue;
const
  sErrorValueOutOfRange = 'Value %d is out of range [%d..%d]';
begin
  if AType is TRttiOrdinalType then
  begin
    if not InRange(AValue, TRttiOrdinalType(AType).MinValue, TRttiOrdinalType(AType).MaxValue) then
      raise EPropertyError.CreateFmt(sErrorValueOutOfRange, [AValue,
        TRttiOrdinalType(AType).MinValue, TRttiOrdinalType(AType).MaxValue]);
  end
  else
    if AType is TRttiInt64Type then
    begin
      if not InRange(AValue, TRttiInt64Type(AType).MinValue, TRttiInt64Type(AType).MaxValue) then
        raise EPropertyError.CreateFmt(sErrorValueOutOfRange, [AValue,
          TRttiInt64Type(AType).MinValue, TRttiInt64Type(AType).MaxValue]);
    end;

  Result := FromOrdinal(AType.Handle, AValue);
end;

end.
