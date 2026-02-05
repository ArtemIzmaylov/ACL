////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   XML Document-Object-Model
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.FileFormats.XML;

{$I ACL.Config.inc}

interface

uses
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}SysUtils,
  {System.}Variants,
  {System.}Types,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.FastCode,
  ACL.FileFormats.INI,
  // FPC: must be defined in Interface section!
  ACL.FileFormats.XML.Types,
  ACL.FileFormats.XML.Reader,
  ACL.FileFormats.XML.Writer,
  ACL.Parsers,
  ACL.Utils.Common,
  ACL.Utils.Date,
  ACL.Utils.FileSystem,
  ACL.Utils.Stream,
  ACL.Utils.Strings;

type
  TACLXMLNode = class;
  TACLXMLDocument = class;

  { EACLXMLDocument }

  EACLXMLDocument = class(Exception);

  { EACLXMLUnexpectedToken }

  EACLXMLUnexpectedToken = class(EACLXMLDocument)
  public
    constructor Create(const AToken, AStringForParsing: string);
  end;

  { TACLXMLDateTime }

  // ISO 8601
  // http://www.w3.org/TR/xmlschema-2/#dateTime

  TACLXMLDateTime = record
  strict private
    function ToDateTimeCore: TDateTime;
  public
    Day: Word;
    Hour: Word;
    Millisecond: Word;
    Minute: Word;
    Month: Word;
    Second: Word;
    Year: Word;
    IsUTC: Boolean;

    constructor Create(const ASource: TDateTime; AIsUTC: Boolean = False); overload;
    constructor Create(const ASource: string); overload;
    procedure Clear;
    function ToDateTime: TDateTime;
    function ToString: string;
  end;

  { TACLXMLAttribute }

  TACLXMLAttribute = class
  private
    FName: string;
    FValue: string;
  public
    procedure Assign(ASource: TACLXMLAttribute);
    function GetValueAsInteger(ADefaultValue: Integer = 0): Integer;
    // Properties
    property Name: string read FName;
    property Value: string read FValue write FValue;
  end;

  { TACLXMLAttributes }

  TACLXMLAttributes = class(TACLObjectList)
  strict private const
    sVariantTypeSuffix = 'Type';
    sVariantTypeBoolean = 'Bool';
    sVariantTypeDate = 'Date';
    sVariantTypeFloat = 'Float';
    sVariantTypeInt32 = 'Int32';
    sVariantTypeInt64 = 'Int64';
    sVariantTypeString = 'String';
  strict private
    function GetItem(Index: Integer): TACLXMLAttribute; inline;
  public
    function Add: TACLXMLAttribute; overload;
    function Add(const AName: string; const AValue: Boolean): TACLXMLAttribute; overload;
    function Add(const AName: string; const AValue: Integer): TACLXMLAttribute; overload;
    function Add(const AName: string; const AValue: string): TACLXMLAttribute; overload;
    procedure Assign(ASource: TACLXMLAttributes);
    function Equals(Obj: TObject): Boolean; override;
    function Contains(const AName: string): Boolean;
    function Find(const AName: string; out AAttr: TACLXMLAttribute): Boolean;
    function Last: TACLXMLAttribute;
    procedure MergeWith(ASource: TACLXMLAttributes);
    function Remove(const AAttr: TACLXMLAttribute): Boolean; overload;
    function Remove(const AName: string): Boolean; overload;
    function Rename(const AOldName, ANewName: string): Boolean;
    // Get
    function Get(const AName: string; const ADefault: string = ''): string;
    function GetAsBool(const AName: string; ADefault: Boolean = False): Boolean;
    function GetAsBoolEx(const AName: string): TACLBoolean;
    function GetAsDateTime(const AName: string; ADefault: TDateTime = 0): TDateTime;
    function GetAsDouble(const AName: string; ADefault: Double = 0): Double;
    function GetAsEnum<T>(const AKey: string; ADefault: T): T;
    function GetAsInt32(const AName: string; ADefault: Integer = 0): Integer;
    function GetAsInt64(const AName: string; ADefault: Int64 = 0): Int64;
    function GetAsRect(const AName: string): TRect;
    function GetAsSize(const AName: string): TSize;
    function GetAsVariant(const AName: string): Variant;
    // Set
    procedure SetAs(const AName: string; const AValue: string);
    procedure SetAsBool(const AName: string; AValue: Boolean);
    procedure SetAsBoolEx(const AName: string; AValue: TACLBoolean);
    procedure SetAsDateTime(const AName: string; AValue: TDateTime);
    procedure SetAsDouble(const AName: string; const AValue: Double);
    procedure SetAsEnum<T>(const AKey: string; const AValue: T);
    procedure SetAsInt32(const AName: string; const AValue: Integer);
    procedure SetAsInt64(const AName: string; const AValue: Int64);
    procedure SetAsRect(const AName: string; const AValue: TRect);
    procedure SetAsSize(const AName: string; const AValue: TSize);
    procedure SetAsVariant(const AName: string; const AValue: Variant);
    // Properties
    property Items[Index: Integer]: TACLXMLAttribute read GetItem; default;
  end;

  { TACLXMLNode }

  TACLXMLNodeFindProc = reference to function (ANode: TACLXMLNode): Boolean;
  TACLXMLNodeEnumProc = reference to procedure (ANode: TACLXMLNode);

  TACLXMLNode = class
  private
    FSubNodes: TACLObjectList;
  strict private
    FAttributes: TACLXMLAttributes;
    FNodeName: string;
    FNodeValue: string;
    FParent: TACLXMLNode;

    function GetCount: Integer;
    function GetEmpty: Boolean;
    function GetIndex: Integer;
    function GetNode(AIndex: Integer): TACLXMLNode; inline;
    function GetNodeValueAsInteger: Integer;
    procedure SetIndex(AValue: Integer);
    procedure SetNodeValueAsInteger(const Value: Integer);
    procedure SetParent(AValue: TACLXMLNode);
  protected
    function CanSetParent(ANode: TACLXMLNode): Boolean;
    function IsChild(ANode: TACLXMLNode): Boolean;
    procedure SubNodesNeeded;
  public
    constructor Create(AParent: TACLXMLNode);
    destructor Destroy; override;
    function Add(const AName: string): TACLXMLNode; virtual;
    procedure Assign(ASource: TACLXMLNode); overload;
    procedure Assign(ASource: TACLIniFileSection); overload;
    procedure AssignTo(ATarget: TACLIniFileSection);
    procedure Clear; virtual;
    procedure Enum(AProc: TACLXMLNodeEnumProc; ARecursive: Boolean = False); overload;
    procedure Enum(const ANodesNames: array of string; AProc: TACLXMLNodeEnumProc); overload;
    function Equals(Obj: TObject): Boolean; override;
    function FindNode(const ANodeName: string): TACLXMLNode; overload;
    function FindNode(const ANodeName: string;
      out ANode: TACLXMLNode): Boolean; overload;
    function FindNode(const ANodesNames: array of string;
      ACanCreate: Boolean = False): TACLXMLNode; overload;
    function FindNode(const ANodesNames: array of string;
      out ANode: TACLXMLNode; ACanCreate: Boolean = False): Boolean; overload;
    function FindNode(out ANode: TACLXMLNode; AFindProc: TACLXMLNodeFindProc;
      ARecursive: Boolean = True): Boolean; overload;
    function NodeValueByName(const ANodeName: string): string; overload;
    function NodeValueByName(const ANodesNames: array of string): string; overload;
    function NodeValueByNameAsInteger(const ANodeName: string): Integer;
    function NextSibling: TACLXMLNode;
    function PrevSibling: TACLXMLNode;
    procedure Sort(ASortProc: TListSortCompare);
    //# Properties
    property Attrs: TACLXMLAttributes read FAttributes;
    property Count: Integer read GetCount;
    property Empty: Boolean read GetEmpty;
    property Index: Integer read GetIndex write SetIndex;
    property NodeName: string read FNodeName write FNodeName;
    property Nodes[Index: Integer]: TACLXMLNode read GetNode; default;
    property NodeValue: string read FNodeValue write FNodeValue;
    property NodeValueAsInteger: Integer read GetNodeValueAsInteger write SetNodeValueAsInteger;
    property Parent: TACLXMLNode read FParent write SetParent;
  end;

  { TACLXMLDocumentFormatSettings }

  TACLXMLDocumentFormatSettings = record
  private
    AutoIndents: Boolean;
    NewLineOnAttributes: Boolean;
    NewLineOnNode: Boolean;
    TextMode: Boolean;
  public
    class function Binary: TACLXMLDocumentFormatSettings; static;
    class function Default: TACLXMLDocumentFormatSettings; static;
    class function Text(
      AutoIndents: Boolean = True;
      NewLineOnNode: Boolean = True;
      NewLineOnAttributes: Boolean = False): TACLXMLDocumentFormatSettings; static;
  end;

  { TACLXMLDocument }

  TACLXMLDocument = class(TACLXMLNode)
  protected
    FAllowMultipleRoots: Boolean; // for legacy skins
  public
    constructor Create; reintroduce; virtual;
    constructor CreateEx(const AFileName: string); overload;
    constructor CreateEx(const AStream: TStream); overload;
    destructor Destroy; override;
    function Add(const AName: string): TACLXMLNode; override;
    // Load
    procedure LoadFromFile(const AFileName: string; AEncoding: TEncoding = nil);
    procedure LoadFromResource(AInst: HMODULE; const AName, AType: string);
    procedure LoadFromStream(AStream: TStream); overload; // TACLStreamProc, b.c.
    procedure LoadFromStream(const AStream: TStream; AEncoding: TEncoding); overload; virtual;
    procedure LoadFromString(const AString: AnsiString);
    // Save
    procedure SaveToFile(const AFileName: string); overload;
    procedure SaveToFile(const AFileName: string; const ASettings: TACLXMLDocumentFormatSettings); overload;
    procedure SaveToStream(AStream: TStream); overload;
    procedure SaveToStream(AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings); overload; virtual;
  end;

implementation

uses
  {System.}Math,
  {System.}StrUtils;

type

  { TACLBinaryXML }

  TACLBinaryXML = class
  public const
    HeaderID = $4C4D5853;
    FlagsHasAttributes = $1;
    FlagsHasChildren = $2;
    FlagsHasValue = $4;
    ValueContinueFlag = $80;
    ValueMask = $7F;
  end;

  { TACLBinaryXMLParser }

  TACLBinaryXMLParser = class
  strict private
    class procedure ReadNode(AStream: TStream; ANode: TACLXMLNode; const AStringTable: TStringDynArray);
    class procedure ReadSubNodes(AStream: TStream; AParent: TACLXMLNode; const AStringTable: TStringDynArray);
    class procedure ReadStringTable(AStream: TStream; out AStringTable: TStringDynArray);
    class function ReadValue(AStream: TStream): Cardinal;
  public
    class procedure Parse(ADocument: TACLXMLDocument; AStream: TStream);
  end;

  { TACLLegacyBinaryXMLParser }

  TACLLegacyBinaryXMLParser = class
  strict private
    class procedure ReadNode(AStream: TStream; ANode: TACLXMLNode);
    class procedure ReadSubNodes(AStream: TStream; AParent: TACLXMLNode);
  public
    class procedure Parse(ADocument: TACLXMLDocument; AStream: TStream);
  end;

  { TACLXMLBuilder }

  TACLXMLBuilderClass = class of TACLXMLBuilder;
  TACLXMLBuilder = class
  public
    constructor Create(AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings); virtual;
    procedure Build(ADocument: TACLXMLDocument); virtual; abstract;
  end;

  { TACLBinaryXMLBuilder }

  TACLBinaryXMLBuilder = class(TACLXMLBuilder)
  strict private
    FStream: TStream;
    FStringTable: TACLStringIndexes;

    function Share(const A: string): Integer;
    procedure WriteNode(ANode: TACLXMLNode);
    procedure WriteString(const S: string);
    procedure WriteStringTable;
    procedure WriteSubNodes(ANode: TACLXMLNode);
    procedure WriteValue(AValue: Cardinal);
  protected
    property Stream: TStream read FStream;
  public
    constructor Create(AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings); override;
    destructor Destroy; override;
    procedure Build(ADocument: TACLXMLDocument); override;
  end;

  { TACLTextXMLBuilder }

  TACLTextXMLBuilder = class(TACLXMLBuilder)
  strict private
    FWriter: TACLXMLWriter;

    procedure WriteNode(ANode: TACLXMLNode);
  public
    constructor Create(AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings); override;
    destructor Destroy; override;
    procedure Build(ADocument: TACLXMLDocument); override;
  end;

{ EACLXMLUnexpectedToken }

constructor EACLXMLUnexpectedToken.Create(const AToken, AStringForParsing: string);
begin
  inherited CreateFmt('Unexpected token was found ("%s" in "%s")', [IfThen(AToken <> #0, AToken, '#0'), AStringForParsing]);
end;

{ TACLXMLDateTime }

constructor TACLXMLDateTime.Create(const ASource: TDateTime; AIsUTC: Boolean = False);
begin
  DecodeDate(ASource, Year, Month, Day);
  DecodeTime(ASource, Hour, Minute, Second, Millisecond);
  IsUTC := AIsUTC;
end;

constructor TACLXMLDateTime.Create(const ASource: string);

  function GetNextPart(out ADelimiter: Char; var AIndex: Integer): string;
  var
    I: Integer;
  begin
    for I := AIndex to Length(ASource) do
    begin
      ADelimiter := ASource[I];
      if not CharInSet(ADelimiter, ['0'..'9']) then
      begin
        Result := Copy(ASource, AIndex, I - AIndex);
        AIndex := I + 1;
        Exit;
      end;
    end;
    Result := Copy(ASource, AIndex, MaxInt);
    AIndex := Length(ASource) + 1;
    ADelimiter := #0;
  end;

  function GetNextPartAndCheckDelimiter(const AExpectedDelimiter: Char; var AIndex: Integer): string;
  var
    C: Char;
  begin
    Result := GetNextPart(C, AIndex);
    if C <> AExpectedDelimiter then
      raise EACLXMLUnexpectedToken.Create(C, ASource);
  end;

var
  ADelim: Char;
  AIndex: Integer;
  AOffsetHour: Word;
  AOffsetMinutes: Word;
  ASign: Integer;
  AValue: string;
begin
  Clear;
  AIndex := 1;
  Year := StrToIntDef(GetNextPartAndCheckDelimiter('-', AIndex), 0);
  Month := StrToIntDef(GetNextPartAndCheckDelimiter('-', AIndex), 0);
  Day := StrToIntDef(GetNextPart(ADelim, AIndex), 0);

  if ADelim = 'T' then
  begin
    Hour := StrToIntDef(GetNextPartAndCheckDelimiter(':', AIndex), 0);
    Minute := StrToIntDef(GetNextPartAndCheckDelimiter(':', AIndex), 0);
    Second := StrToIntDef(GetNextPart(ADelim, AIndex), 0);

    if ADelim = '.' then
    begin
      AValue := GetNextPart(ADelim, AIndex);
      Millisecond := Round(1000 * StrToIntDef(AValue, 0) / IntPower(10, Length(AValue)));
    end;
  end;

  case ADelim of
    'Z':
      begin
        GetNextPart(ADelim, AIndex);
        IsUTC := True;
      end;

    '+', '-':
      begin
        ASign := IfThen(ADelim = '-', -1, 1);
        AOffsetHour := StrToIntDef(GetNextPart(ADelim, AIndex), 0);
        if ADelim = ':' then
          AOffsetMinutes := StrToIntDef(GetNextPart(ADelim, AIndex), 0)
        else
          AOffsetMinutes := 0;

        Self := TACLXMLDateTime.Create(ToDateTime - ASign * EncodeTime(AOffsetHour, AOffsetMinutes, 0, 0), True);
      end;
  end;

  if ADelim <> #0 then
    raise EACLXMLUnexpectedToken.Create(ADelim, ASource);
end;

procedure TACLXMLDateTime.Clear;
begin
  Year := 0;
  Month := 0;
  Day := 0;
  Hour := 0;
  Minute := 0;
  Second := 0;
  Millisecond := 0;
  IsUTC := False;
end;

function TACLXMLDateTime.ToDateTime: TDateTime;
begin
  Result := ToDateTimeCore;
  if IsUTC then
    Result := UTCToLocalDateTime(Result);
end;

function TACLXMLDateTime.ToDateTimeCore: TDateTime;
begin
  Result := EncodeDate(Year, Month, Day) + EncodeTime(Hour, Minute, Second, Millisecond);
end;

function TACLXMLDateTime.ToString: string;
begin
  Result := FormatDateTime('yyyy-mm-dd''T''hh:mm:ss.zzz', ToDateTimeCore, InvariantFormatSettings) + IfThen(IsUTC, 'Z');
end;

{ TACLXMLAttribute }

procedure TACLXMLAttribute.Assign(ASource: TACLXMLAttribute);
begin
  FName := ASource.FName;
  FValue := ASource.Value;
end;

function TACLXMLAttribute.GetValueAsInteger(ADefaultValue: Integer): Integer;
begin
  Result := StrToIntDef(Value, ADefaultValue);
end;

{ TACLXMLAttributes }

function TACLXMLAttributes.Add: TACLXMLAttribute;
begin
  Result := TACLXMLAttribute.Create;
  inherited Add(Result);
end;

function TACLXMLAttributes.Add(const AName: string; const AValue: Integer): TACLXMLAttribute;
begin
  Result := Add(AName, IntToStr(AValue));
end;

function TACLXMLAttributes.Add(const AName: string; const AValue: string): TACLXMLAttribute;
begin
  Result := Add;
  Result.FName := AName;
  Result.Value := AValue;
end;

function TACLXMLAttributes.Add(const AName: string; const AValue: Boolean): TACLXMLAttribute;
begin
  Result := Add(AName, Ord(AValue));
end;

procedure TACLXMLAttributes.Assign(ASource: TACLXMLAttributes);
var
  I: Integer;
begin
  Clear;
  for I := 0 to ASource.Count - 1 do
    Add.Assign(ASource[I]);
end;

function TACLXMLAttributes.Equals(Obj: TObject): Boolean;
var
  AAttr: TACLXMLAttribute;
  I: Integer;
begin
  Result := (Obj is TACLXMLAttributes) and (Count = TACLXMLAttributes(Obj).Count);
  if Result then
    for I := 0 to Count - 1 do
    begin
      Result := TACLXMLAttributes(Obj).Find(Items[I].Name, AAttr) and (Items[I].Value = AAttr.Value);
      if not Result then
        Break;
    end;
end;

function TACLXMLAttributes.Contains(const AName: string): Boolean;
var
  AAttr: TACLXMLAttribute;
begin
  Result := Find(AName, AAttr);
end;

function TACLXMLAttributes.Find(const AName: string; out AAttr: TACLXMLAttribute): Boolean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if acCompareTokens(TACLXMLAttribute(List[I]).Name, AName) then
    begin
      AAttr := Items[I];
      Exit(True);
    end;
  Result := False;
end;

function TACLXMLAttributes.Get(const AName, ADefault: string): string;
var
  LAttr: TACLXMLAttribute;
begin
  if Find(AName, LAttr) then
    Result := LAttr.Value
  else
    Result := ADefault;
end;

function TACLXMLAttributes.GetAsDouble(const AName: string; ADefault: Double = 0): Double;
var
  LAttr: TACLXMLAttribute;
begin
  if Find(AName, LAttr) then
    Result := StrToFloat(LAttr.Value, InvariantFormatSettings)
  else
    Result := ADefault;
end;

function TACLXMLAttributes.GetAsEnum<T>(const AKey: string; ADefault: T): T;
var
  LAttr: TACLXMLAttribute;
  LValue: Integer;
begin
  if Find(AKey, LAttr) and TryStrToInt(LAttr.Value, LValue) then
    Result := TACLEnumHelper.SetValue<T>(LValue)
  else
    Result := ADefault;
end;

function TACLXMLAttributes.GetAsBool(const AName: string; ADefault: Boolean = False): Boolean;
var
  LAttr: TACLXMLAttribute;
begin
  if Find(AName, LAttr) then
    Result := TACLXMLConvert.DecodeBoolean(LAttr.Value)
  else
    Result := ADefault;
end;

function TACLXMLAttributes.GetAsBoolEx(const AName: string): TACLBoolean;
var
  LAttr: TACLXMLAttribute;
begin
  if Find(AName, LAttr) then
    Result := TACLBoolean.From(TACLXMLConvert.DecodeBoolean(LAttr.Value))
  else
    Result := TACLBoolean.Default;
end;

function TACLXMLAttributes.GetAsDateTime(const AName: string; ADefault: TDateTime = 0): TDateTime;
var
  LAttr: TACLXMLAttribute;
begin
  if Find(AName, LAttr) then
    Result := TACLXMLDateTime.Create(LAttr.Value).ToDateTime
  else
    Result := ADefault;
end;

function TACLXMLAttributes.GetAsInt32(const AName: string; ADefault: Integer = 0): Integer;
begin
  Result := StrToIntDef(Get(AName), ADefault);
end;

function TACLXMLAttributes.GetAsInt64(const AName: string; ADefault: Int64 = 0): Int64;
begin
  Result := StrToInt64Def(Get(AName), ADefault);
end;

function TACLXMLAttributes.GetAsRect(const AName: string): TRect;
begin
  Result := acStringToRect(Get(AName));
end;

function TACLXMLAttributes.GetAsSize(const AName: string): TSize;
begin
  Result := acStringToSize(Get(AName));
end;

function TACLXMLAttributes.GetAsVariant(const AName: string): Variant;
var
  AType: string;
begin
  AType := Get(AName + sVariantTypeSuffix);
  if AType = sVariantTypeInt32 then
    Result := GetAsInt32(AName)
  else if AType = sVariantTypeFloat then
    Result := GetAsDouble(AName)
  else if AType = sVariantTypeString then
    Result := Get(AName)
  else if AType = sVariantTypeInt64 then
    Result := GetAsInt64(AName)
  else if AType = sVariantTypeBoolean then
    Result := GetAsBool(AName)
  else if AType = sVariantTypeDate then
    Result := GetAsDateTime(AName)
  else if AType = 'Int34' then // for backward compatibility
    Result := GetAsInt64(AName)
  else
    Result := Null;
end;

function TACLXMLAttributes.GetItem(Index: Integer): TACLXMLAttribute;
begin
  if IsValid(Index) then
    Result := TACLXMLAttribute(List[Index])
  else
    Result := nil;
end;

function TACLXMLAttributes.Last: TACLXMLAttribute;
begin
  Result := TACLXMLAttribute(inherited Last);
end;

procedure TACLXMLAttributes.MergeWith(ASource: TACLXMLAttributes);
var
  I: Integer;
begin
  for I := 0 to ASource.Count - 1 do
  begin
    if not Contains(ASource[I].Name) then
      SetAs(ASource[I].Name, ASource[I].Value);
  end;
end;

function TACLXMLAttributes.Remove(const AName: string): Boolean;
var
  AAttr: TACLXMLAttribute;
begin
  Result := Find(AName, AAttr) and Remove(AAttr);
end;

function TACLXMLAttributes.Remove(const AAttr: TACLXMLAttribute): Boolean;
begin
  Result := inherited Remove(AAttr) >= 0;
end;

function TACLXMLAttributes.Rename(const AOldName, ANewName: string): Boolean;
var
  AAttr: TACLXMLAttribute;
begin
  if Find(ANewName, AAttr) then
    Exit(False);

  Result := Find(AOldName, AAttr);
  if Result then
    AAttr.FName := ANewName;
end;

procedure TACLXMLAttributes.SetAsBool(const AName: string; AValue: Boolean);
begin
  SetAsInt32(AName, Ord(AValue));
end;

procedure TACLXMLAttributes.SetAsBoolEx(const AName: string; AValue: TACLBoolean);
begin
  if AValue = TACLBoolean.Default then
    Remove(AName)
  else
    SetAsBool(AName, AValue = TACLBoolean.True);
end;

procedure TACLXMLAttributes.SetAsDateTime(const AName: string; AValue: TDateTime);
var
  LValue: TACLXMLDateTime;
begin
  if AValue > 0 then
  begin
    try
      LValue := TACLXMLDateTime.Create(LocalDateTimeToUTC(AValue), True);
    except
      // Может возникать, если AValue находится на рубеже перехода на летнее время
      // The given "30/03/2025 02:00:00" local time is invalid (situated within the missing period prior to DST).
      LValue := TACLXMLDateTime.Create(AValue, False);
    end;
    SetAs(AName, LValue.ToString)
  end
  else
    Remove(AName);
end;

procedure TACLXMLAttributes.SetAsDouble(const AName: string; const AValue: Double);
begin
  SetAs(AName, FloatToStr(AValue, InvariantFormatSettings));
end;

procedure TACLXMLAttributes.SetAsEnum<T>(const AKey: string; const AValue: T);
begin
  SetAs(AKey, IntToStr(TACLEnumHelper.GetValue<T>(AValue)));
end;

procedure TACLXMLAttributes.SetAsInt64(const AName: string; const AValue: Int64);
begin
  SetAs(AName, IntToStr(AValue));
end;

procedure TACLXMLAttributes.SetAsInt32(const AName: string; const AValue: Integer);
begin
  SetAs(AName, IntToStr(AValue));
end;

procedure TACLXMLAttributes.SetAsRect(const AName: string; const AValue: TRect);
begin
  SetAs(AName, acRectToString(AValue));
end;

procedure TACLXMLAttributes.SetAsSize(const AName: string; const AValue: TSize);
begin
  SetAs(AName, acSizeToString(AValue));
end;

procedure TACLXMLAttributes.SetAs(const AName: string; const AValue: string);
var
  LAttr: TACLXMLAttribute;
begin
  if Find(AName, LAttr) then
    LAttr.Value := AValue
  else
    Add(AName, AValue);
end;

procedure TACLXMLAttributes.SetAsVariant(const AName: string; const AValue: Variant);
begin
  case VarType(AValue) and varTypeMask of
    varOleStr, varString, varUString:
      begin
        SetAs(AName, AValue);
        SetAs(AName + sVariantTypeSuffix, sVariantTypeString);
      end;

    varDate:
      begin
        SetAsDateTime(AName, AValue);
        SetAs(AName + sVariantTypeSuffix, sVariantTypeDate);
      end;

    varEmpty, varNull:
      begin
        Remove(AName);
        Remove(AName + sVariantTypeSuffix);
      end;

    varByte, varShortInt, varWord, varSmallInt, varInteger:
      begin
        SetAsInt32(AName, AValue);
        SetAs(AName + sVariantTypeSuffix, sVariantTypeInt32);
      end;

    varSingle, varDouble, varCurrency:
      begin
        SetAsDouble(AName, AValue);
        SetAs(AName + sVariantTypeSuffix, sVariantTypeFloat);
      end;

    varBoolean:
      begin
        SetAsBool(AName, AValue);
        SetAs(AName + sVariantTypeSuffix, sVariantTypeBoolean);
      end;

    varLongWord, varInt64:
      begin
        SetAsInt64(AName, AValue);
        SetAs(AName + sVariantTypeSuffix, sVariantTypeInt64);
      end;

  else
    raise EACLXMLArgumentException.CreateFmt('Unsupported Variant Type (%d)', [VarType(AValue)]);
  end;
end;

{ TACLXMLNode }

constructor TACLXMLNode.Create(AParent: TACLXMLNode);
begin
  inherited Create;
  FParent := AParent;
  FAttributes := TACLXMLAttributes.Create;
end;

destructor TACLXMLNode.Destroy;
begin
  Parent := nil;
  FreeAndNil(FAttributes);
  FreeAndNil(FSubNodes);
  inherited Destroy;
end;

function TACLXMLNode.Add(const AName: string): TACLXMLNode;
begin
  SubNodesNeeded;
  Result := TACLXMLNode.Create(Self);
  Result.FNodeName := AName;
  FSubNodes.Add(Result);
end;

procedure TACLXMLNode.Assign(ASource: TACLXMLNode);
var
  I: Integer;
begin
  Clear;
  Attrs.Assign(ASource.Attrs);
  for I := 0 to ASource.Count - 1 do
    Add(acEmptyStr).Assign(ASource[I]);
  FNodeName := ASource.FNodeName;
  FNodeValue := ASource.FNodeValue;
end;

procedure TACLXMLNode.Assign(ASource: TACLIniFileSection);
var
  I: Integer;
begin
  Clear;
  if ASource <> nil then
  begin
    Attrs.EnsureCapacity(ASource.Count);
    for I := 0 to ASource.Count - 1 do
      Attrs.Add(ASource.Names[I], ASource.ValueFromIndex[I]);
  end;
end;

procedure TACLXMLNode.AssignTo(ATarget: TACLIniFileSection);
var
  I: Integer;
begin
  ATarget.Clear;
  ATarget.EnsureCapacity(Attrs.Count);
  for I := 0 to Attrs.Count - 1 do
    ATarget.AddPair(Attrs.Items[I].Name, Attrs.Items[I].Value);
end;

procedure TACLXMLNode.Clear;
begin
  if Assigned(FSubNodes) then
  begin
    FSubNodes.Clear;
    FreeAndNil(FSubNodes);
  end;
end;

procedure TACLXMLNode.Enum(AProc: TACLXMLNodeEnumProc; ARecursive: Boolean = False);
var
  I: Integer;
begin
  try
    for I := 0 to Count - 1 do
      AProc(FSubNodes.List[I]);
    if ARecursive then
    begin
      for I := 0 to Count - 1 do
        Nodes[I].Enum(AProc, True);
    end;
  except
    on E: EAbort do
      {nothing}
    else
      raise;
  end;
end;

procedure TACLXMLNode.Enum(const ANodesNames: array of string; AProc: TACLXMLNodeEnumProc);
var
  I: Integer;
  LNode: TACLXMLNode;
begin
  if FindNode(ANodesNames, LNode) then
  try
    for I := 0 to LNode.Count - 1 do
      AProc(LNode.FSubNodes.List[I]);
  except
    on E: EAbort do
      {nothing}
    else
      raise;
  end;
end;

function TACLXMLNode.Equals(Obj: TObject): Boolean;
var
  I: Integer;
begin
  Result := (ClassType = Obj.ClassType) and Attrs.Equals(TACLXMLNode(Obj).Attrs) and
    (NodeName = TACLXMLNode(Obj).NodeName) and (NodeValue = TACLXMLNode(Obj).NodeValue) and
    (Count = TACLXMLNode(Obj).Count);
  if Result then
    for I := 0 to Count - 1 do
    begin
      Result := Nodes[I].Equals(TACLXMLNode(Obj).Nodes[I]);
      if not Result then
        Break;
    end;
end;

function TACLXMLNode.FindNode(const ANodeName: string): TACLXMLNode;
begin
  if not FindNode(ANodeName, Result) then
    Result := nil;
end;

function TACLXMLNode.FindNode(const ANodeName: string; out ANode: TACLXMLNode): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
  begin
    Result := acCompareTokens(Nodes[I].NodeName, ANodeName);
    if Result then
    begin
      ANode := Nodes[I];
      Break;
    end;
  end;
end;

function TACLXMLNode.FindNode(const ANodesNames: array of string; ACanCreate: Boolean = False): TACLXMLNode;
begin
  if not FindNode(ANodesNames, Result, ACanCreate) then
    Result := nil;
end;

function TACLXMLNode.FindNode(const ANodesNames: array of string;
  out ANode: TACLXMLNode; ACanCreate: Boolean = False): Boolean;
var
  AIndex: Integer;
  ATempNode: TACLXMLNode;
begin
  ANode := nil;
  if Length(ANodesNames) > 0 then
  begin
    AIndex := 0;
    ANode := Self;
    while (ANode <> nil) and (AIndex < Length(ANodesNames)) do
    begin
      ATempNode := ANode.FindNode(ANodesNames[AIndex]);
      if (ATempNode = nil) and ACanCreate then
        ATempNode := ANode.Add(ANodesNames[AIndex]);
      ANode := ATempNode;
      Inc(AIndex);
    end;
  end;
  Result := ANode <> nil;
end;

function TACLXMLNode.FindNode(out ANode: TACLXMLNode;
  AFindProc: TACLXMLNodeFindProc; ARecursive: Boolean = True): Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := 0 to Count - 1 do
  begin
    if AFindProc(Nodes[I]) then
    begin
      ANode := Nodes[I];
      Exit(True);
    end;
  end;

  if ARecursive then
    for I := 0 to Count - 1 do
    begin
      if Nodes[I].FindNode(ANode, AFindProc, True) then
        Exit(True);
    end;
end;

function TACLXMLNode.NodeValueByName(const ANodeName: string): string;
var
  ANode: TACLXMLNode;
begin
  ANode := FindNode(ANodeName);
  if ANode <> nil then
    Result := ANode.NodeValue
  else
    Result := acEmptyStr;
end;

function TACLXMLNode.NextSibling: TACLXMLNode;
begin
  if Parent <> nil then
    Result := Parent.Nodes[Index + 1]
  else
    Result := nil;
end;

function TACLXMLNode.NodeValueByName(const ANodesNames: array of string): string;
var
  ANode: TACLXMLNode;
begin
  if FindNode(ANodesNames, ANode) then
    Result := ANode.NodeValue
  else
    Result := acEmptyStr;
end;

function TACLXMLNode.NodeValueByNameAsInteger(const ANodeName: string): Integer;
var
  ANode: TACLXMLNode;
begin
  ANode := FindNode(ANodeName);
  if ANode <> nil then
    Result := ANode.NodeValueAsInteger
  else
    Result := 0
end;

function TACLXMLNode.PrevSibling: TACLXMLNode;
begin
  if Parent <> nil then
    Result := Parent.Nodes[Index - 1]
  else
    Result := nil;
end;

procedure TACLXMLNode.Sort(ASortProc: TListSortCompare);
begin
  if Assigned(FSubNodes) then
    FSubNodes.Sort(ASortProc);
end;

function TACLXMLNode.CanSetParent(ANode: TACLXMLNode): Boolean;
begin
  Result := (ANode = nil) or (ANode <> Self) and (ANode <> Parent) and not IsChild(ANode);
end;

function TACLXMLNode.IsChild(ANode: TACLXMLNode): Boolean;
var
  I: Integer;
begin
  Result := (FSubNodes <> nil) and (FSubNodes.IndexOf(ANode) >= 0);
  if not Result then
    for I := 0 to Count - 1 do
    begin
      Result := Nodes[I].IsChild(ANode);
      if Result then Break;
    end;
end;

procedure TACLXMLNode.SubNodesNeeded;
begin
  if FSubNodes = nil then
    FSubNodes := TACLObjectList.Create;
end;

function TACLXMLNode.GetCount: Integer;
begin
  if FSubNodes <> nil then
    Result := FSubNodes.Count
  else
    Result := 0;
end;

function TACLXMLNode.GetEmpty: Boolean;
begin
  Result := (Attrs.Count = 0) and (Count = 0) and (NodeValue = acEmptyStr);
end;

function TACLXMLNode.GetIndex: Integer;
begin
  if Parent <> nil then
    Result := Parent.FSubNodes.IndexOf(Self)
  else
    Result := -1;
end;

function TACLXMLNode.GetNode(AIndex: Integer): TACLXMLNode;
begin
  if (FSubNodes <> nil) and (AIndex >= 0) and (AIndex < FSubNodes.Count) then
    Result := FSubNodes.List[AIndex]
  else
    Result := nil
end;

function TACLXMLNode.GetNodeValueAsInteger: Integer;
begin
  Result := StrToIntDef(NodeValue, 0);
end;

procedure TACLXMLNode.SetIndex(AValue: Integer);
begin
  if Parent <> nil then
    Parent.FSubNodes.ChangePlace(Index, AValue);
end;

procedure TACLXMLNode.SetNodeValueAsInteger(const Value: Integer);
begin
  NodeValue := IntToStr(Value)
end;

procedure TACLXMLNode.SetParent(AValue: TACLXMLNode);
begin
  if CanSetParent(AValue) then
  begin
    if Parent <> nil then
    begin
      if Parent.FSubNodes <> nil then
        Parent.FSubNodes.Extract(Self);
      FParent := nil;
    end;
    if AValue <> nil then
    begin
      FParent := AValue;
      Parent.SubNodesNeeded;
      Parent.FSubNodes.Add(Self);
    end;
  end;
end;

{ TACLXMLDocumentFormatSettings }

class function TACLXMLDocumentFormatSettings.Binary: TACLXMLDocumentFormatSettings;
begin
  FastZeroMem(@Result, SizeOf(Result));
  Result.TextMode := False;
end;

class function TACLXMLDocumentFormatSettings.Default: TACLXMLDocumentFormatSettings;
begin
  Result := Text;
end;

class function TACLXMLDocumentFormatSettings.Text(
  AutoIndents, NewLineOnNode, NewLineOnAttributes: Boolean): TACLXMLDocumentFormatSettings;
begin
  Result.TextMode := True;
  Result.AutoIndents := AutoIndents;
  Result.NewLineOnAttributes := NewLineOnAttributes;
  Result.NewLineOnNode := NewLineOnNode;
end;

{ TACLXMLDocument }

constructor TACLXMLDocument.Create;
begin
  inherited Create(nil);
end;

constructor TACLXMLDocument.CreateEx(const AFileName: string);
begin
  Create;
  try
    LoadFromFile(AFileName);
  except
    Clear;
  end;
end;

constructor TACLXMLDocument.CreateEx(const AStream: TStream);
begin
  Create;
  LoadFromStream(AStream);
end;

destructor TACLXMLDocument.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TACLXMLDocument.Add(const AName: string): TACLXMLNode;
begin
  if (Count > 0) and not FAllowMultipleRoots then
    raise EACLXMLDocument.Create('Only one Root available');
  Result := inherited Add(AName);
end;

procedure TACLXMLDocument.LoadFromFile(const AFileName: string; AEncoding: TEncoding = nil);
var
  LStream: TStream;
begin
  if TACLBufferedFileStream.TryCreate(AFileName, fmOpenReadOnly, LStream) then
  try
    LoadFromStream(LStream, AEncoding);
  finally
    LStream.Free;
  end
  else
    Clear;
end;

procedure TACLXMLDocument.LoadFromResource(AInst: HMODULE; const AName, AType: string);
var
  LStream: TStream;
begin
  LStream := TResourceStream.Create(AInst, AName, PChar(AType));
  try
    LoadFromStream(LStream);
  finally
    LStream.Free;
  end;
end;

procedure TACLXMLDocument.LoadFromStream(AStream: TStream);
begin
  LoadFromStream(AStream, nil);
end;

procedure TACLXMLDocument.LoadFromStream(const AStream: TStream; AEncoding: TEncoding);
var
  ACurrentNode: TACLXMLNode;
  AHeader: Cardinal;
  AIsEmptyElement: Boolean;
  AReader: TACLXMLReader;
  AReaderSettings: TACLXMLReaderSettings;
begin
  Clear;
  if AStream.Available < SizeOf(Integer) then Exit;
  AHeader := AStream.ReadInt32;
  if AHeader = TACLBinaryXML.HeaderID then
    TACLBinaryXMLParser.Parse(Self, AStream)
  else if AHeader = $4C4D5842 then
    TACLLegacyBinaryXMLParser.Parse(Self, AStream)
  else
  begin
    AStream.Seek(-SizeOf(Integer), soCurrent);

    AReaderSettings := TACLXMLReaderSettings.Default;
    AReaderSettings.CheckCharacters := False;
    AReaderSettings.DefaultEncoding := AEncoding;
    AReaderSettings.IgnoreComments := True;
    AReaderSettings.IgnoreWhitespace := True;
    AReaderSettings.SupportNamespaces := False;
    if FAllowMultipleRoots then
      AReaderSettings.ConformanceLevel := TACLXMLConformanceLevel.Fragment;

    AReader := AReaderSettings.CreateReader(AStream);
    try
      ACurrentNode := Self;
      while AReader.SafeRead do
      begin
        case AReader.NodeType of
          TACLXMLNodeType.EndElement:
            if ACurrentNode <> nil then
              ACurrentNode := ACurrentNode.Parent;

          TACLXMLNodeType.Element:
            if ACurrentNode <> nil then
            begin
              AIsEmptyElement := AReader.IsEmptyElement;
              ACurrentNode := ACurrentNode.Add(AReader.Name);
              while AReader.MoveToNextAttribute do
                ACurrentNode.Attrs.Add(AReader.Name, AReader.Value);
              if AIsEmptyElement then
                ACurrentNode := ACurrentNode.Parent;
            end;

          TACLXMLNodeType.CDATA,
          TACLXMLNodeType.Text,
          TACLXMLNodeType.SignificantWhitespace:
            if ACurrentNode <> nil then
              ACurrentNode.NodeValue := AReader.Text;
        else;
        end;
      end;
    finally
      AReader.Free;
    end;
  end;
end;

procedure TACLXMLDocument.LoadFromString(const AString: AnsiString);
var
  AStream: TStream;
begin
  AStream := TACLAnsiStringStream.Create(AString);
  try
    LoadFromStream(AStream);
  finally
    AStream.Free;
  end;
end;

procedure TACLXMLDocument.SaveToFile(const AFileName: string);
begin
  SaveToFile(AFileName, TACLXMLDocumentFormatSettings.Default);
end;

procedure TACLXMLDocument.SaveToFile(const AFileName: string; const ASettings: TACLXMLDocumentFormatSettings);
var
  LStream: TStream;
begin
  LStream := TACLBufferedFileStream.Create(AFileName, fmCreateShared);
  try
    SaveToStream(LStream, ASettings);
  finally
    LStream.Free;
  end;
end;

procedure TACLXMLDocument.SaveToStream(AStream: TStream);
begin
  SaveToStream(AStream, TACLXMLDocumentFormatSettings.Default);
end;

procedure TACLXMLDocument.SaveToStream(AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings);
const
  ClassMap: array[Boolean] of TACLXMLBuilderClass = (TACLBinaryXMLBuilder, TACLTextXMLBuilder);
begin
  with ClassMap[ASettings.TextMode].Create(AStream, ASettings) do
  try
    Build(Self);
  finally
    Free;
  end;
end;

{ TACLBinaryXMLParser }

class procedure TACLBinaryXMLParser.Parse(ADocument: TACLXMLDocument; AStream: TStream);
var
  APosition: Int64;
  ASize: Int64;
  ATable: TStringDynArray;
begin
  ASize := AStream.ReadInt64;
  APosition := AStream.Position;
  AStream.Position := APosition + ASize;
  ReadStringTable(AStream, ATable);
  AStream.Position := APosition;
  ReadSubNodes(AStream, ADocument, ATable);
end;

class procedure TACLBinaryXMLParser.ReadNode(AStream: TStream; ANode: TACLXMLNode; const AStringTable: TStringDynArray);
var
  AAttr: TACLXMLAttribute;
  ACount: Integer;
  AFlags: Byte;
begin
  AFlags := AStream.ReadByte;
  if AFlags and TACLBinaryXML.FlagsHasValue <> 0 then
    ANode.NodeValue := acString(AStream.ReadString(ReadValue(AStream)));

  if AFlags and TACLBinaryXML.FlagsHasAttributes <> 0 then
  begin
    ACount := ReadValue(AStream);
    ANode.Attrs.Capacity := ACount;
    while ACount > 0 do
    begin
      AAttr := ANode.Attrs.Add;
      AAttr.FName := AStringTable[ReadValue(AStream)];
      AAttr.Value := AStream.ReadString(ReadValue(AStream));
      Dec(ACount);
    end;
  end;

  if AFlags and TACLBinaryXML.FlagsHasChildren <> 0 then
    ReadSubNodes(AStream, ANode, AStringTable);
end;

class procedure TACLBinaryXMLParser.ReadSubNodes(
  AStream: TStream; AParent: TACLXMLNode; const AStringTable: TStringDynArray);
var
  ACount: Integer;
begin
  ACount := ReadValue(AStream);
  if ACount > 0 then
  begin
    AParent.SubNodesNeeded;
    AParent.FSubNodes.Capacity := ACount;
    while ACount > 0 do
    begin
      ReadNode(AStream, AParent.Add(AStringTable[ReadValue(AStream)]), AStringTable);
      Dec(ACount);
    end;
  end;
end;

class procedure TACLBinaryXMLParser.ReadStringTable(
  AStream: TStream; out AStringTable: TStringDynArray);
var
  ACount: Integer;
  AIndex: Integer;
begin
  ACount := ReadValue(AStream);
  SetLength(AStringTable{%H-}, ACount);
  for AIndex := 0 to ACount - 1 do
    AStringTable[AIndex] := acString(AStream.ReadStringA(ReadValue(AStream)));
end;

class function TACLBinaryXMLParser.ReadValue(AStream: TStream): Cardinal;
var
  AByte: Byte;
  AOffset: Byte;
begin
  Result := 0;
  AOffset := 0;
  repeat
    AByte := AStream.ReadByte;
    Result := Result or (AByte and TACLBinaryXML.ValueMask) shl AOffset;
    Inc(AOffset, 7);
  until AByte and TACLBinaryXML.ValueContinueFlag = 0;
end;

{ TACLLegacyBinaryXMLParser }

class procedure TACLLegacyBinaryXMLParser.Parse(ADocument: TACLXMLDocument; AStream: TStream);
begin
  ReadSubNodes(AStream, ADocument);
end;

class procedure TACLLegacyBinaryXMLParser.ReadNode(AStream: TStream; ANode: TACLXMLNode);
var
  LAttr: TACLXMLAttribute;
  LSize: Integer;
  LFlags: Byte;
begin
  LFlags := AStream.ReadByte;
  if LFlags and TACLBinaryXML.FlagsHasValue <> 0 then
    ANode.NodeValue := acString(AStream.ReadStringU(AStream.ReadInt32));

  if LFlags and TACLBinaryXML.FlagsHasAttributes <> 0 then
  begin
    LSize := AStream.ReadInt32;
    ANode.Attrs.Capacity := LSize;
    while LSize > 0 do
    begin
      LAttr := ANode.Attrs.Add;
      LAttr.FName := acString(AStream.ReadStringWithLengthA);
      LAttr.Value := acString(AStream.ReadStringWithLength);
      Dec(LSize);
    end;
  end;

  if LFlags and TACLBinaryXML.FlagsHasChildren <> 0 then
    ReadSubNodes(AStream, ANode);
end;

class procedure TACLLegacyBinaryXMLParser.ReadSubNodes(AStream: TStream; AParent: TACLXMLNode);
var
  ACount: Integer;
begin
  ACount := AStream.ReadInt32;
  if ACount > 0 then
  begin
    AParent.SubNodesNeeded;
    AParent.FSubNodes.Capacity := ACount;
    while ACount > 0 do
    begin
      ReadNode(AStream, AParent.Add(acString(AStream.ReadStringWithLengthA)));
      Dec(ACount);
    end;
  end;
end;

{ TACLXMLBuilder }

constructor TACLXMLBuilder.Create(AStream: TStream;
  const ASettings: TACLXMLDocumentFormatSettings);
begin
  // just to be a virtual;
end;

{ TACLBinaryXMLBuilder }

constructor TACLBinaryXMLBuilder.Create(
  AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings);
begin
  inherited;
  FStream := AStream;
  FStringTable := TACLStringIndexes.Create;
end;

destructor TACLBinaryXMLBuilder.Destroy;
begin
  FreeAndNil(FStringTable);
  inherited;
end;

procedure TACLBinaryXMLBuilder.Build(ADocument: TACLXMLDocument);
var
  ATablePosition: Int64;
  AValuePosition: Int64;
begin
  Stream.WriteInt32(TACLBinaryXML.HeaderID);
  AValuePosition := Stream.Position;
  Stream.WriteInt64(0);
  WriteSubNodes(ADocument);
  ATablePosition := Stream.Position;
  Stream.Position := AValuePosition;
  Stream.WriteInt64(ATablePosition - AValuePosition - SizeOf(Int64));
  Stream.Position := ATablePosition;
  WriteStringTable;
end;

function TACLBinaryXMLBuilder.Share(const A: string): Integer;
begin
  if not FStringTable.TryGetValue(A, Result) then
  begin
    Result := FStringTable.Count;
    FStringTable.AddOrSetValue(A, Result);
  end;
end;

procedure TACLBinaryXMLBuilder.WriteNode(ANode: TACLXMLNode);
var
  LAttr: TACLXMLAttribute;
  LFlags: Byte;
  I: Integer;
begin
  WriteValue(Share(ANode.NodeName));

  LFlags := 0;
  if ANode.Count > 0 then
    LFlags := LFlags or TACLBinaryXML.FlagsHasChildren;
  if ANode.Attrs.Count > 0 then
    LFlags := LFlags or TACLBinaryXML.FlagsHasAttributes;
  if ANode.NodeValue <> acEmptyStr then
    LFlags := LFlags or TACLBinaryXML.FlagsHasValue;

  Stream.WriteByte(LFlags);
  if LFlags and TACLBinaryXML.FlagsHasValue <> 0 then
    WriteString(ANode.NodeValue);

  if LFlags and TACLBinaryXML.FlagsHasAttributes <> 0 then
  begin
    WriteValue(ANode.Attrs.Count);
    for I := 0 to ANode.Attrs.Count - 1 do
    begin
      LAttr := ANode.Attrs[I];
      WriteValue(Share(LAttr.Name));
      WriteString(LAttr.Value);
    end;
  end;

  if LFlags and TACLBinaryXML.FlagsHasChildren <> 0 then
    WriteSubNodes(ANode);
end;

procedure TACLBinaryXMLBuilder.WriteString(const S: string);
var
  LData: UnicodeString;
  LDataLength: Cardinal;
begin
  LData := acUString(S);
  LDataLength := Length(LData);
  WriteValue(LDataLength);
  if LDataLength > 0 then
    Stream.WriteString(LData);
end;

procedure TACLBinaryXMLBuilder.WriteStringTable;
var
  I: Integer;
  L: Integer;
  S: array of AnsiString;
  P: TPair<string, Integer>;
begin
  WriteValue(FStringTable.Count);
  SetLength(S{%H-}, FStringTable.Count);
  for P in FStringTable do
    S[P.Value] := AnsiString(P.Key);
  for I := Low(S) to High(S) do
  begin
    L := Length(S[I]);
    WriteValue(L);
    if L > 0 then
      Stream.WriteStringA(S[I]);
  end;
end;

procedure TACLBinaryXMLBuilder.WriteSubNodes(ANode: TACLXMLNode);
var
  I: Integer;
begin
  WriteValue(ANode.Count);
  for I := 0 to ANode.Count - 1 do
    WriteNode(ANode.Nodes[I]);
end;

procedure TACLBinaryXMLBuilder.WriteValue(AValue: Cardinal);
var
  AByte: Byte;
begin
  repeat
    AByte := AValue and TACLBinaryXML.ValueMask;
    AValue := AValue shr 7;
    if AValue > 0 then
      AByte := AByte or TACLBinaryXML.ValueContinueFlag;
    Stream.WriteByte(AByte);
  until AValue = 0;
end;

{ TACLTextXMLBuilder }

constructor TACLTextXMLBuilder.Create(
  AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings);
var
  LSettings: TACLXMLWriterSettings;
begin
  inherited;
  LSettings := TACLXMLWriterSettings.Default;
  LSettings.CheckCharacters := False;
  LSettings.CheckWellformed := False; // у нас имя ноды уже идет с префиксом (prefix:name), валидация не пройдет.
  LSettings.NewLineOnAttributes := ASettings.NewLineOnAttributes;
  LSettings.NewLineOnNode := ASettings.NewLineOnNode;
  FWriter := TACLXMLWriter.Create(AStream, LSettings);
end;

destructor TACLTextXMLBuilder.Destroy;
begin
  FreeAndNil(FWriter);
  inherited;
end;

procedure TACLTextXMLBuilder.Build(ADocument: TACLXMLDocument);
var
  I: Integer;
begin
  FWriter.WriteStartDocument;
  for I := 0 to ADocument.Count - 1 do
    WriteNode(ADocument[I]);
  FWriter.WriteEndDocument;
end;

procedure TACLTextXMLBuilder.WriteNode(ANode: TACLXMLNode);
var
  I: Integer;
begin
  FWriter.WriteStartElement(ANode.NodeName);
  for I := 0 to ANode.Attrs.Count - 1 do
    FWriter.WriteAttributeString(ANode.Attrs[I].Name, ANode.Attrs[I].Value);
  if ANode.NodeValue <> acEmptyStr then
    FWriter.WriteString(ANode.NodeValue);
  for I := 0 to ANode.Count - 1 do
    WriteNode(ANode[I]);
  FWriter.WriteEndElement;
end;

end.
