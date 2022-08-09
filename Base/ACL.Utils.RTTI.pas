{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*           RTTI Helpers Routines           *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.RTTI;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Classes,
  System.Variants,
  System.TypInfo,
  System.Rtti;

type
  TMemberVisibilities = set of TMemberVisibility;

  TRttiEnumProc<T> = reference to procedure (const AValue: T);

  { TRTTI }

  TRTTI = class
  strict private
    class var FContext: TRttiContext;
    class function GetPropertiesCore(AClassInfo: Pointer; out AList: PPropList; out ACount: Integer): Boolean;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure EnumClassProperties<T: class>(AObject: TObject; AEnumProc: TRttiEnumProc<T>;
      ARecursive: Boolean = True; AVisibility: TMemberVisibilities = [mvPublished]);
    class function FindPropertyByName(AProperties: TArray<TRttiProperty>; const AName: string; out AProperty: TRttiProperty): Boolean; overload;
    class function FindPropertyByName(AType: TRttiType; const AName: string; out AProperty: TRttiProperty): Boolean; overload;
    class function GetProperties(AClass: TClass; out AList: PPropList; out ACount: Integer): Boolean; overload;
    class function GetProperties(AObject: TObject; out AList: PPropList; out ACount: Integer): Boolean; overload;
    class function GetPropInfo(AObject: TObject; const AName: UnicodeString; AVisibility: TMemberVisibilities = [mvPublished]): PPropInfo;
    class function GetType(AObject: TObject): TRttiType; static;
    class procedure ResolvePath(var AObject: TObject; var ANamePath: string; AVisibility: TMemberVisibilities = [mvPublished]);

    class function IsBoolean(APropInfo: PPropInfo): Boolean;
    class function IsFloat(APropInfo: PPropInfo): Boolean; inline;
    class function IsSameType(APropInfo: PPropInfo; const ATypeInfo: Pointer): Boolean;
    class function IsStored(AObject: TObject; APropInfo: PPropInfo): Boolean;
    class function IsString(APropInfo: PPropInfo): Boolean; inline;
    class function IsUnsignedInt(APropInfo: PPropInfo): Boolean;

    class function GetPropValue(AObject: TObject; APropInfo: PPropInfo): UnicodeString; overload;
    class function GetPropValue(AObject: TObject; APropInfo: PPropInfo; out AValue: UnicodeString): Boolean; overload;
    class function GetPropValue(AObject: TObject; const AName: UnicodeString): UnicodeString; overload;
    class function GetPropValueAsVariant(AObject: TObject; APropInfo: PPropInfo; PreferStrings: Boolean = False): Variant; overload;
    class function GetPropValueAsVariant(AObject: TObject; const AName: UnicodeString; PreferStrings: Boolean = False): Variant; overload;
    class procedure SetEnumPropValue(AObject: TObject; APropInfo: PPropInfo; const AValue: UnicodeString);
    class procedure SetPropValue(AObject: TObject; APropInfo: PPropInfo; const AValue: UnicodeString); overload;
    class procedure SetPropValue(AObject: TObject; const AName, AValue: UnicodeString); overload;
    class procedure SetPropValueAsVariant(AObject: TObject; APropInfo: PPropInfo; const AValue: Variant); overload;
    class procedure SetPropValueAsVariant(AObject: TObject; const AName: UnicodeString; const AValue: Variant); overload;

    class property Context: TRttiContext read FContext;
  end;

  { TValueHelper }

  TValueHelper = record helper for TValue
  public
    class function FromOrdinal(AType: TRttiType; const AValue: Int64): TValue; overload; static;
  end;

implementation

uses
  System.Types,
  System.SysUtils,
  System.Math,
  System.RTLConsts,
  // ACL
  ACL.FastCode,
  ACL.Utils.Common,
  ACL.Utils.Strings;

const
  sErrorReadOnly = 'The %s is read only';
  sErrorNoRttiInfo = 'The %s has no RTTI info';
  sErrorSetEnumPropValue = 'Can''t set "%s" to "%s"';
  sErrorValueOutOfRange = 'Value is out of range';

{ TRTTI }

class constructor TRTTI.Create;
begin
  FContext := TRttiContext.Create;
end;

class destructor TRTTI.Destroy;
begin
  FContext.Free;
end;

class procedure TRTTI.EnumClassProperties<T>(AObject: TObject; AEnumProc: TRttiEnumProc<T>;
  ARecursive: Boolean = True; AVisibility: TMemberVisibilities = [mvPublished]);
var
  AProperties: TArray<TRttiProperty>;
  AProperty: TRttiProperty;
  APropertyValue: TObject;
  I: Integer;
begin
  AProperties := GetType(AObject).GetProperties;
  for I := 0 to Length(AProperties) - 1 do
  begin
    AProperty := AProperties[I];
    if (AProperty.PropertyType.TypeKind = tkClass) and (AProperty.Visibility in AVisibility) then
    begin
      APropertyValue := AProperty.GetValue(AObject).AsObject;
      if (APropertyValue = nil) or (APropertyValue is TComponent) then
        Continue;
      if APropertyValue.InheritsFrom(T) then
        AEnumProc(T(APropertyValue))
      else
        if ARecursive then
          EnumClassProperties(APropertyValue, AEnumProc, ARecursive, AVisibility);
    end;
  end;
end;

class function TRTTI.GetProperties(AClass: TClass; out AList: PPropList; out ACount: Integer): Boolean;
begin
  Result := (AClass <> nil) and GetPropertiesCore(AClass.ClassInfo, AList, ACount);
end;

class function TRTTI.GetProperties(AObject: TObject; out AList: PPropList; out ACount: Integer): Boolean;
begin
  Result := (AObject <> nil) and GetPropertiesCore(AObject.ClassInfo, AList, ACount);
end;

class function TRTTI.GetPropertiesCore(AClassInfo: Pointer; out AList: PPropList; out ACount: Integer): Boolean;
begin
  ACount := GetTypeData(AClassInfo)^.PropCount;
  Result := ACount > 0;
  if Result then
  begin
    AList := AllocMem(ACount * SizeOf(Pointer));
    GetPropInfos(AClassInfo, AList);
  end;
end;

class function TRTTI.FindPropertyByName(AType: TRttiType; const AName: string; out AProperty: TRttiProperty): Boolean;
begin
  Result := FindPropertyByName(AType.GetProperties, AName, AProperty);
end;

class function TRTTI.FindPropertyByName(AProperties: TArray<TRttiProperty>; const AName: string; out AProperty: TRttiProperty): Boolean;
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

class function TRTTI.GetPropInfo(AObject: TObject; const AName: UnicodeString; AVisibility: TMemberVisibilities): PPropInfo;
var
  AProperty: TRttiProperty;
begin
  if mvPublished in AVisibility then
    Result := System.TypInfo.GetPropInfo(AObject, AName)
  else
    Result := nil;

  if (Result = nil) and (AVisibility - [mvPublished] <> []) then
  begin
    if FindPropertyByName(GetType(AObject), AName, AProperty) and (AProperty.Visibility in AVisibility) then
    begin
      if AProperty is TRttiInstanceProperty then
        Result := TRttiInstanceProperty(AProperty).PropInfo;
    end;
  end;
end;

class function TRTTI.GetType(AObject: TObject): TRttiType;
begin
  Result := Context.GetType(AObject.ClassInfo);
  if Result = nil then
    raise EInvalidOperation.CreateFmt(sErrorNoRttiInfo, [AObject.ClassName]);
end;

class procedure TRTTI.ResolvePath(var AObject: TObject; var ANamePath: string; AVisibility: TMemberVisibilities = [mvPublished]);
var
  APos: Integer;
  APropInfo: PPropInfo;
begin
  repeat
    APos := acPos('.', ANamePath);
    if APos > 0 then
    begin
      APropInfo := GetPropInfo(AObject, Copy(ANamePath, 1, APos - 1), AVisibility);
      if (APropInfo = nil) or (APropInfo.PropType^.Kind <> tkClass) then
        raise EPropertyError.CreateResFmt(@SInvalidPropertyType, [Copy(ANamePath, 1, APos - 1)]);
      AObject := GetObjectProp(AObject, APropInfo, TObject);
      ANamePath := Copy(ANamePath, APos + 1, MaxInt);
    end;
  until APos = 0;
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
  Result := IsStoredProp(AObject, APropInfo) and (APropInfo^.PropType^.Kind <> tkMethod) and not IsDefaultPropertyValue(AObject, APropInfo, nil);
end;

class function TRTTI.IsString(APropInfo: PPropInfo): Boolean;
begin
  Result := APropInfo.PropType^.Kind in [tkString, tkLString, tkWString, tkUString];
end;

class function TRTTI.IsUnsignedInt(APropInfo: PPropInfo): Boolean;
var
  ATypeData: PTypeData;
begin
  Result := False;
  if APropInfo^.PropType^.Kind = tkInteger then
  begin
    ATypeData := GetTypeData(APropInfo^.PropType^);
    Result := ATypeData.MinValue >= ATypeData.MaxValue;
  end;
end;
class function TRTTI.IsSameType(APropInfo: PPropInfo; const ATypeInfo: Pointer): Boolean;
begin
  Result := (APropInfo <> nil) and (APropInfo^.PropType^ = ATypeInfo);
end;

class function TRTTI.GetPropValue(AObject: TObject; APropInfo: PPropInfo): UnicodeString;
begin
  if not GetPropValue(AObject, APropInfo, Result) then
    Result := '';
end;

class function TRTTI.GetPropValue(AObject: TObject; APropInfo: PPropInfo; out AValue: UnicodeString): Boolean;
var
  APrevFormatSettings: TFormatSettings;
begin
  Result := APropInfo <> nil;
  if Result then
  begin
    APrevFormatSettings := FormatSettings;
    try
      FormatSettings := InvariantFormatSettings;
      AValue := GetPropValueAsVariant(AObject, APropInfo, True);
    finally
      FormatSettings := APrevFormatSettings;
    end;
  end;
end;

class function TRTTI.GetPropValue(AObject: TObject; const AName: UnicodeString): UnicodeString;
begin
  if AObject <> nil then
    Result := GetPropValue(AObject, GetPropInfo(AObject, AName))
  else
    Result := '';
end;

class function TRTTI.GetPropValueAsVariant(AObject: TObject; APropInfo: PPropInfo; PreferStrings: Boolean): Variant;
begin
  if AObject <> nil then
  begin
    Result := System.TypInfo.GetPropValue(AObject, APropInfo, PreferStrings);
    if IsUnsignedInt(APropInfo) then
      Result := LongWord(Int64(Result));
  end
  else
    Result := Null;
end;

class function TRTTI.GetPropValueAsVariant(AObject: TObject; const AName: UnicodeString; PreferStrings: Boolean): Variant;
begin
  if AObject <> nil then
    Result := GetPropValueAsVariant(AObject, GetPropInfo(AObject, AName), PreferStrings)
  else
    Result := Null;
end;

class procedure TRTTI.SetEnumPropValue(AObject: TObject; APropInfo: PPropInfo; const AValue: UnicodeString);
var
  AData: Integer;
  ATypeData: PTypeData;
  AValueOrd: Integer;
begin
  AData := GetEnumValue(APropInfo^.PropType^, AValue);
  if AData < 0 then
  begin
    ATypeData := GetTypeData(APropInfo^.PropType^);
    AValueOrd := StrToIntDef(AValue, ATypeData^.MinValue - 1);
    if (AValueOrd >= ATypeData^.MinValue) and (AValueOrd <= ATypeData^.MaxValue) then
      AData := AValueOrd;
  end;
  if AData >= 0 then
    SetOrdProp(AObject, APropInfo, AData)
  else
    raise EPropertyConvertError.CreateFmt(sErrorSetEnumPropValue, [AValue, APropInfo^.Name]);
end;

class procedure TRTTI.SetPropValue(AObject: TObject; APropInfo: PPropInfo; const AValue: UnicodeString);
var
  APrevFormatSettings: TFormatSettings;
begin
  if APropInfo = nil then
    Exit;
  if APropInfo.SetProc = nil then
    raise EPropReadOnly.CreateFmt(sErrorReadOnly, [APropInfo.Name]);

  APrevFormatSettings := FormatSettings;
  try
    FormatSettings := InvariantFormatSettings;
    if APropInfo^.PropType^.Kind = tkEnumeration then
      SetEnumPropValue(AObject, APropInfo, AValue)
    else
      System.TypInfo.SetPropValue(AObject, APropInfo, AValue);
  finally
    FormatSettings := APrevFormatSettings;
  end;
end;

class procedure TRTTI.SetPropValue(AObject: TObject; const AName, AValue: UnicodeString);
begin
  SetPropValue(AObject, GetPropInfo(AObject, AName), AValue);
end;

class procedure TRTTI.SetPropValueAsVariant(AObject: TObject; APropInfo: PPropInfo; const AValue: Variant);
begin
  if APropInfo.SetProc = nil then
    raise EPropReadOnly.CreateFmt(sErrorReadOnly, [APropInfo.Name]);
  if IsBoolean(APropInfo) and VarIsNumeric(AValue) then
    SetOrdProp(AObject, APropInfo, Ord(FastTrunc(AValue) <> 0))
  else
    System.TypInfo.SetPropValue(AObject, APropInfo, AValue);
end;

class procedure TRTTI.SetPropValueAsVariant(AObject: TObject; const AName: UnicodeString; const AValue: Variant);
begin
  SetPropValueAsVariant(AObject, GetPropInfo(AObject, AName), AValue);
end;

{ TValueHelper }

class function TValueHelper.FromOrdinal(AType: TRttiType; const AValue: Int64): TValue;
begin
  if AType is TRttiOrdinalType then
  begin
    if not InRange(AValue, TRttiOrdinalType(AType).MinValue, TRttiOrdinalType(AType).MaxValue) then
      raise EPropertyError.Create(sErrorValueOutOfRange);
  end
  else
    if AType is TRttiInt64Type then
    begin
      if not InRange(AValue, TRttiInt64Type(AType).MinValue, TRttiInt64Type(AType).MaxValue) then
        raise EPropertyError.Create(sErrorValueOutOfRange);
    end;

  Result := FromOrdinal(AType.Handle, AValue);
end;

end.
