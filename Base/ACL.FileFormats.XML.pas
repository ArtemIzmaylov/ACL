{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*            Simple XML Document            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.FileFormats.XML;

{$I ACL.Config.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.Variants,
  System.Types,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FastCode,
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
    constructor Create(const AToken, AStringForParsing: UnicodeString);
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
    constructor Create(const ASource: UnicodeString); overload;
    procedure Clear;
    function ToDateTime: TDateTime;
    function ToString: UnicodeString;
  end;

  { TACLXMLAttribute }

  TACLXMLAttribute = class
  private
    FName: UnicodeString;
    FValue: UnicodeString;
  public
    procedure Assign(ASource: TACLXMLAttribute);
    function GetValueAsInteger(ADefaultValue: Integer = 0): Integer;
    //
    property Name: UnicodeString read FName;
    property Value: UnicodeString read FValue write FValue;
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
    function Add(const AName: UnicodeString; const AValue: Integer): TACLXMLAttribute; overload;
    function Add(const AName: UnicodeString; const AValue: UnicodeString): TACLXMLAttribute; overload;
    procedure Assign(ASource: TACLXMLAttributes);
    function Equals(Obj: TObject): Boolean; override;
    function Contains(const AName: UnicodeString): Boolean;
    function Find(const AName: UnicodeString; out AAttr: TACLXMLAttribute): Boolean;
    function Last: TACLXMLAttribute;
    procedure MergeWith(ASource: TACLXMLAttributes);
    function Remove(const AAttr: TACLXMLAttribute): Boolean; overload;
    function Remove(const AName: UnicodeString): Boolean; overload;
    function Rename(const AOldName, ANewName: UnicodeString): Boolean;
    // Get
    function GetValue(const AName: UnicodeString): UnicodeString; overload;
    function GetValue(const AName: UnicodeString; out AValue: UnicodeString): Boolean; overload;
    function GetValueDef(const AName: UnicodeString; const ADefault: UnicodeString): UnicodeString; overload;
    function GetValueAsBoolean(const AName: UnicodeString; ADefault: Boolean = False): Boolean;
    function GetValueAsBooleanEx(const AName: UnicodeString): TACLBoolean;
    function GetValueAsDateTime(const AName: UnicodeString; const ADefault: TDateTime = 0): TDateTime;
    function GetValueAsDouble(const AName: UnicodeString; const ADefault: Double = 0): Double;
    function GetValueAsInt64(const AName: UnicodeString; const ADefault: Int64 = 0): Int64;
    function GetValueAsInteger(const AName: UnicodeString; const ADefault: Integer = 0): Integer;
    function GetValueAsRect(const AName: UnicodeString): TRect;
    function GetValueAsSize(const AName: UnicodeString): TSize;
    function GetValueAsVariant(const AName: UnicodeString): Variant;
    // Set
    procedure SetValue(const AName: UnicodeString; const AValue: UnicodeString);
    procedure SetValueAsBoolean(const AName: UnicodeString; AValue: Boolean);
    procedure SetValueAsBooleanEx(const AName: UnicodeString; AValue: TACLBoolean);
    procedure SetValueAsDateTime(const AName: UnicodeString; AValue: TDateTime);
    procedure SetValueAsDouble(const AName: UnicodeString; const AValue: Double);
    procedure SetValueAsInt64(const AName: UnicodeString; const AValue: Int64);
    procedure SetValueAsInteger(const AName: UnicodeString; const AValue: Integer);
    procedure SetValueAsRect(const AName: UnicodeString; const AValue: TRect);
    procedure SetValueAsSize(const AName: UnicodeString; const AValue: TSize);
    procedure SetValueAsVariant(const AName: UnicodeString; const AValue: Variant);
    //
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
    FNodeName: UnicodeString;
    FNodeValue: UnicodeString;
    FParent: TACLXMLNode;

    function GetCount: Integer;
    function GetEmpty: Boolean;
    function GetIndex: Integer;
    function GetNode(AIndex: Integer): TACLXMLNode;
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
    function Add(const AName: UnicodeString): TACLXMLNode; virtual;
    procedure Enum(AProc: TACLXMLNodeEnumProc; ARecursive: Boolean = False); overload;
    procedure Enum(const ANodesNames: array of UnicodeString; AProc: TACLXMLNodeEnumProc); overload;
    function Equals(Obj: TObject): Boolean; override;
    function FindNode(const ANodeName: UnicodeString): TACLXMLNode; overload;
    function FindNode(const ANodeName: UnicodeString; out ANode: TACLXMLNode): Boolean; overload;
    function FindNode(const ANodesNames: array of UnicodeString; ACanCreate: Boolean = False): TACLXMLNode; overload;
    function FindNode(const ANodesNames: array of UnicodeString; out ANode: TACLXMLNode; ACanCreate: Boolean = False): Boolean; overload;
    function FindNode(out ANode: TACLXMLNode; AFindProc: TACLXMLNodeFindProc; ARecursive: Boolean = True): Boolean; overload;
    function NodeValueByName(const ANodeName: UnicodeString): UnicodeString; overload;
    function NodeValueByName(const ANodesNames: array of UnicodeString): UnicodeString; overload;
    function NodeValueByNameAsInteger(const ANodeName: UnicodeString): Integer;

    procedure Assign(ANode: TACLXMLNode); virtual;
    procedure Clear; virtual;
    procedure Sort(ASortProc: TListSortCompare);
    //
    property Attributes: TACLXMLAttributes read FAttributes;
    property Count: Integer read GetCount;
    property Empty: Boolean read GetEmpty;
    property Index: Integer read GetIndex write SetIndex;
    property NodeName: UnicodeString read FNodeName write FNodeName;
    property Nodes[Index: Integer]: TACLXMLNode read GetNode; default;
    property NodeValue: UnicodeString read FNodeValue write FNodeValue;
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
    constructor CreateEx(const AFileName: UnicodeString); overload;
    constructor CreateEx(const AStream: TStream); overload;
    destructor Destroy; override;
    function Add(const AName: UnicodeString): TACLXMLNode; override;
    // Load
    procedure LoadFromFile(const AFileName: UnicodeString);
    procedure LoadFromResource(AInst: HINST; const AName, AType: UnicodeString);
    procedure LoadFromStream(AStream: TStream); virtual;
    procedure LoadFromString(const AString: AnsiString);
    // Save
    procedure SaveToFile(const AFileName: UnicodeString); overload;
    procedure SaveToFile(const AFileName: UnicodeString; const ASettings: TACLXMLDocumentFormatSettings); overload;
    procedure SaveToStream(AStream: TStream); overload;
    procedure SaveToStream(AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings); overload; virtual;
  end;

implementation

uses
  System.Math,
  System.StrUtils,
  // ACL
  ACL.FileFormats.XML.Types,
  ACL.FileFormats.XML.Reader,
  ACL.FileFormats.XML.Writer;

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
    FStringTable: TACLDictionary<UnicodeString, Integer>;

    function Share(const A: UnicodeString): Integer;
    procedure WriteNode(ANode: TACLXMLNode);
    procedure WriteString(const S: UnicodeString);
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

constructor EACLXMLUnexpectedToken.Create(const AToken, AStringForParsing: UnicodeString);
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

constructor TACLXMLDateTime.Create(const ASource: UnicodeString);

  function GetNextPart(out ADelimiter: Char; var AIndex: Integer): UnicodeString;
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

  function GetNextPartAndCheckDelimiter(const AExpectedDelimiter: Char; var AIndex: Integer): UnicodeString;
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
  AValue: UnicodeString;
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

function TACLXMLDateTime.ToString: UnicodeString;
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

function TACLXMLAttributes.Add(const AName: UnicodeString; const AValue: Integer): TACLXMLAttribute;
begin
  Result := Add(AName, IntToStr(AValue));
end;

function TACLXMLAttributes.Add(const AName: UnicodeString; const AValue: UnicodeString): TACLXMLAttribute;
begin
  Result := Add;
  Result.FName := AName;
  Result.Value := AValue;
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

function TACLXMLAttributes.Contains(const AName: UnicodeString): Boolean;
var
  AAttr: TACLXMLAttribute;
begin
  Result := Find(AName, AAttr);
end;

function TACLXMLAttributes.Find(const AName: UnicodeString; out AAttr: TACLXMLAttribute): Boolean;
begin
  for var I := 0 to Count - 1 do
    if acCompareTokens(TACLXMLAttribute(List[I]).Name, AName) then
    begin
      AAttr := Items[I];
      Exit(True);
    end;
  Result := False;
end;

function TACLXMLAttributes.Last: TACLXMLAttribute;
begin
  Result := TACLXMLAttribute(inherited Last);
end;

procedure TACLXMLAttributes.MergeWith(ASource: TACLXMLAttributes);
begin
  for var I := 0 to ASource.Count - 1 do
  begin
    if not Contains(ASource[I].Name) then
      SetValue(ASource[I].Name, ASource[I].Value);
  end;
end;

function TACLXMLAttributes.Remove(const AName: UnicodeString): Boolean;
var
  AAttr: TACLXMLAttribute;
begin
  Result := Find(AName, AAttr) and Remove(AAttr);
end;

function TACLXMLAttributes.Remove(const AAttr: TACLXMLAttribute): Boolean;
begin
  Result := inherited Remove(AAttr) >= 0;
end;

function TACLXMLAttributes.Rename(const AOldName, ANewName: UnicodeString): Boolean;
var
  AAttr: TACLXMLAttribute;
begin
  if Find(ANewName, AAttr) then
    Exit(False);

  Result := Find(AOldName, AAttr);
  if Result then
    AAttr.FName := ANewName;
end;

function TACLXMLAttributes.GetValue(const AName: UnicodeString): UnicodeString;
begin
  if not GetValue(AName, Result) then
    Result := acEmptyStr;
end;

function TACLXMLAttributes.GetValue(const AName: UnicodeString; out AValue: UnicodeString): Boolean;
var
  AAttr: TACLXMLAttribute;
begin
  Result := Find(AName, AAttr);
  if Result then
    AValue := AAttr.Value;
end;

function TACLXMLAttributes.GetValueDef(const AName: UnicodeString; const ADefault: UnicodeString): UnicodeString;
begin
  if not GetValue(AName, Result) then
    Result := ADefault;
end;

function TACLXMLAttributes.GetValueAsDouble(const AName: UnicodeString; const ADefault: Double = 0): Double;
var
  AValue: UnicodeString;
begin
  if GetValue(AName, AValue) then
    Result := StrToFloat(AValue, InvariantFormatSettings)
  else
    Result := ADefault;
end;

function TACLXMLAttributes.GetValueAsBoolean(const AName: UnicodeString; ADefault: Boolean = False): Boolean;
var
  AValue: UnicodeString;
begin
  if GetValue(AName, AValue) then
    Result := TACLXMLConvert.DecodeBoolean(AValue)
  else
    Result := ADefault;
end;

function TACLXMLAttributes.GetValueAsBooleanEx(const AName: UnicodeString): TACLBoolean;
var
  AValue: UnicodeString;
begin
  if GetValue(AName, AValue) then
    Result := TACLBoolean.From(TACLXMLConvert.DecodeBoolean(AValue))
  else
    Result := TACLBoolean.Default;
end;

function TACLXMLAttributes.GetValueAsDateTime(const AName: UnicodeString; const ADefault: TDateTime = 0): TDateTime;
var
  AValue: UnicodeString;
begin
  if GetValue(AName, AValue) then
    Result := TACLXMLDateTime.Create(AValue).ToDateTime
  else
    Result := ADefault;
end;

function TACLXMLAttributes.GetValueAsInt64(const AName: UnicodeString; const ADefault: Int64 = 0): Int64;
begin
  Result := StrToInt64Def(GetValue(AName), ADefault);
end;

function TACLXMLAttributes.GetValueAsInteger(const AName: UnicodeString; const ADefault: Integer = 0): Integer;
begin
  Result := StrToIntDef(GetValue(AName), ADefault);
end;

function TACLXMLAttributes.GetValueAsRect(const AName: UnicodeString): TRect;
begin
  Result := acStringToRect(GetValue(AName));
end;

function TACLXMLAttributes.GetValueAsSize(const AName: UnicodeString): TSize;
begin
  Result := acStringToSize(GetValue(AName));
end;

function TACLXMLAttributes.GetValueAsVariant(const AName: UnicodeString): Variant;
var
  AType: UnicodeString;
begin
  AType := GetValue(AName + sVariantTypeSuffix);
  if AType = sVariantTypeInt32 then
    Result := GetValueAsInteger(AName)
  else if AType = sVariantTypeFloat then
    Result := GetValueAsDouble(AName)
  else if AType = sVariantTypeString then
    Result := GetValue(AName)
  else if AType = sVariantTypeInt64 then
    Result := GetValueAsInt64(AName)
  else if AType = sVariantTypeBoolean then
    Result := GetValueAsBoolean(AName)
  else if AType = sVariantTypeDate then
    Result := GetValueAsDateTime(AName)
  else if AType = 'Int34' then // for backward compatibility
    Result := GetValueAsInt64(AName)
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

procedure TACLXMLAttributes.SetValue(const AName: UnicodeString; const AValue: UnicodeString);
var
  AAttr: TACLXMLAttribute;
begin
  if Find(AName, AAttr) then
    AAttr.Value := AValue
  else
    Add(AName, AValue);
end;

procedure TACLXMLAttributes.SetValueAsBoolean(const AName: UnicodeString; AValue: Boolean);
begin
  SetValueAsInteger(AName, Ord(AValue));
end;

procedure TACLXMLAttributes.SetValueAsBooleanEx(const AName: UnicodeString; AValue: TACLBoolean);
begin
  if AValue = TACLBoolean.Default then
    Remove(AName)
  else
    SetValueAsBoolean(AName, AValue = TACLBoolean.True);
end;

procedure TACLXMLAttributes.SetValueAsDateTime(const AName: UnicodeString; AValue: TDateTime);
begin
  AValue := LocalDateTimeToUTC(AValue);
  if AValue > 0 then
    SetValue(AName, TACLXMLDateTime.Create(AValue, True).ToString)
  else
    Remove(AName);
end;

procedure TACLXMLAttributes.SetValueAsDouble(const AName: UnicodeString; const AValue: Double);
begin
  SetValue(AName, FloatToStr(AValue, InvariantFormatSettings));
end;

procedure TACLXMLAttributes.SetValueAsInt64(const AName: UnicodeString; const AValue: Int64);
begin
  SetValue(AName, IntToStr(AValue));
end;

procedure TACLXMLAttributes.SetValueAsInteger(const AName: UnicodeString; const AValue: Integer);
begin
  SetValue(AName, IntToStr(AValue));
end;

procedure TACLXMLAttributes.SetValueAsRect(const AName: UnicodeString; const AValue: TRect);
begin
  SetValue(AName, acRectToString(AValue));
end;

procedure TACLXMLAttributes.SetValueAsSize(const AName: UnicodeString; const AValue: TSize);
begin
  SetValue(AName, acSizeToString(AValue));
end;

procedure TACLXMLAttributes.SetValueAsVariant(const AName: UnicodeString; const AValue: Variant);
begin
  case VarType(AValue) and varTypeMask of
    varOleStr, varString, varUString:
      begin
        SetValue(AName, AValue);
        SetValue(AName + sVariantTypeSuffix, sVariantTypeString);
      end;

    varDate:
      begin
        SetValueAsDateTime(AName, AValue);
        SetValue(AName + sVariantTypeSuffix, sVariantTypeDate);
      end;

    varEmpty, varNull:
      begin
        Remove(AName);
        Remove(AName + sVariantTypeSuffix);
      end;

    varByte, varShortInt, varWord, varSmallInt, varInteger:
      begin
        SetValueAsInteger(AName, AValue);
        SetValue(AName + sVariantTypeSuffix, sVariantTypeInt32);
      end;

    varSingle, varDouble, varCurrency:
      begin
        SetValueAsDouble(AName, AValue);
        SetValue(AName + sVariantTypeSuffix, sVariantTypeFloat);
      end;

    varBoolean:
      begin
        SetValueAsBoolean(AName, AValue);
        SetValue(AName + sVariantTypeSuffix, sVariantTypeBoolean);
      end;

    varLongWord, varInt64:
      begin
        SetValueAsInt64(AName, AValue);
        SetValue(AName + sVariantTypeSuffix, sVariantTypeInt64);
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

function TACLXMLNode.Add(const AName: UnicodeString): TACLXMLNode;
begin
  SubNodesNeeded;
  Result := TACLXMLNode.Create(Self);
  Result.FNodeName := AName;
  FSubNodes.Add(Result);
end;

procedure TACLXMLNode.Assign(ANode: TACLXMLNode);
begin
  Clear;
  Attributes.Assign(ANode.Attributes);
  for var I := 0 to ANode.Count - 1 do
    Add(acEmptyStr).Assign(ANode[I]);
  FNodeName := ANode.FNodeName;
  FNodeValue := ANode.FNodeValue;
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
begin
  try
    for var I := 0 to Count - 1 do
      AProc(Nodes[I]);
    if ARecursive then
    begin
      for var I := 0 to Count - 1 do
        Nodes[I].Enum(AProc, True);
    end;
  except
    on E: EAbort do
      {nothing}
    else
      raise;
  end;
end;

procedure TACLXMLNode.Enum(const ANodesNames: array of UnicodeString; AProc: TACLXMLNodeEnumProc);
var
  ANode: TACLXMLNode;
begin
  if FindNode(ANodesNames, ANode) then
    ANode.Enum(AProc);
end;

function TACLXMLNode.Equals(Obj: TObject): Boolean;
begin
  Result := (ClassType = Obj.ClassType) and Attributes.Equals(TACLXMLNode(Obj).Attributes) and
    (NodeName = TACLXMLNode(Obj).NodeName) and (NodeValue = TACLXMLNode(Obj).NodeValue) and
    (Count = TACLXMLNode(Obj).Count);
  if Result then
    for var I := 0 to Count - 1 do
    begin
      Result := Nodes[I].Equals(TACLXMLNode(Obj).Nodes[I]);
      if not Result then
        Break;
    end;
end;

function TACLXMLNode.FindNode(const ANodeName: UnicodeString): TACLXMLNode;
begin
  if not FindNode(ANodeName, Result) then
    Result := nil;
end;

function TACLXMLNode.FindNode(const ANodeName: UnicodeString; out ANode: TACLXMLNode): Boolean;
begin
  Result := False;
  for var I := 0 to Count - 1 do
  begin
    Result := acCompareTokens(Nodes[I].NodeName, ANodeName);
    if Result then
    begin
      ANode := Nodes[I];
      Break;
    end;
  end;
end;

function TACLXMLNode.FindNode(const ANodesNames: array of UnicodeString; ACanCreate: Boolean = False): TACLXMLNode;
begin
  if not FindNode(ANodesNames, Result, ACanCreate) then
    Result := nil;
end;

function TACLXMLNode.FindNode(const ANodesNames: array of UnicodeString; out ANode: TACLXMLNode; ACanCreate: Boolean = False): Boolean;
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

function TACLXMLNode.FindNode(out ANode: TACLXMLNode; AFindProc: TACLXMLNodeFindProc; ARecursive: Boolean = True): Boolean;
begin
  Result := False;

  for var I := 0 to Count - 1 do
  begin
    if AFindProc(Nodes[I]) then
    begin
      ANode := Nodes[I];
      Exit(True);
    end;
  end;

  if ARecursive then
    for var I := 0 to Count - 1 do
    begin
      if Nodes[I].FindNode(ANode, AFindProc, True) then
        Exit(True);
    end;
end;

function TACLXMLNode.NodeValueByName(const ANodeName: UnicodeString): UnicodeString;
var
  ANode: TACLXMLNode;
begin
  ANode := FindNode(ANodeName);
  if ANode <> nil then
    Result := ANode.NodeValue
  else
    Result := acEmptyStr;
end;

function TACLXMLNode.NodeValueByName(const ANodesNames: array of UnicodeString): UnicodeString;
var
  ANode: TACLXMLNode;
begin
  if FindNode(ANodesNames, ANode) then
    Result := ANode.NodeValue
  else
    Result := acEmptyStr;
end;

function TACLXMLNode.NodeValueByNameAsInteger(const ANodeName: UnicodeString): Integer;
var
  ANode: TACLXMLNode;
begin
  ANode := FindNode(ANodeName);
  if ANode <> nil then
    Result := ANode.NodeValueAsInteger
  else
    Result := 0
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
begin
  Result := (FSubNodes <> nil) and (FSubNodes.IndexOf(ANode) >= 0);
  if not Result then
    for var I := 0 to Count - 1 do
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
  Result := (Attributes.Count = 0) and (Count = 0) and (NodeValue = acEmptyStr);
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
  if (FSubNodes = nil) or (AIndex < 0) or (AIndex >= FSubNodes.Count) then
    Result := nil
  else
    Result := TACLXMLNode(FSubNodes.Items[AIndex]);
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

constructor TACLXMLDocument.CreateEx(const AFileName: UnicodeString);
begin
  Create;
  LoadFromFile(AFileName);
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

function TACLXMLDocument.Add(const AName: UnicodeString): TACLXMLNode;
begin
  if (Count > 0) and not FAllowMultipleRoots then
    raise EACLXMLDocument.Create('Only one Root available');
  Result := inherited Add(AName);
end;

procedure TACLXMLDocument.LoadFromFile(const AFileName: UnicodeString);
var
  AStream: TStream;
begin
  if StreamCreateReader(AFileName, AStream) then
  try
    LoadFromStream(AStream);
  finally
    AStream.Free;
  end
  else
    Clear;
end;

procedure TACLXMLDocument.LoadFromResource(AInst: HINST; const AName, AType: UnicodeString);
var
  AStream: TStream;
begin
  AStream := TResourceStream.Create(AInst, AName, PWideChar(AType));
  try
    LoadFromStream(AStream);
  finally
    AStream.Free;
  end;
end;

procedure TACLXMLDocument.LoadFromStream(AStream: TStream);
var
  ACurrentNode: TACLXMLNode;
  AHeader: Cardinal;
  AIsEmptyElement: Boolean;
  AReader: TACLXMLReader;
  AReaderSettings: TACLXMLReaderSettings;
begin
  Clear;
  AHeader := AStream.ReadInt32;
  if AHeader = TACLBinaryXML.HeaderID then
    TACLBinaryXMLParser.Parse(Self, AStream)
  else if AHeader = $4C4D5842 then
    TACLLegacyBinaryXMLParser.Parse(Self, AStream)
  else
  begin
    AStream.Seek(-SizeOf(Integer), soCurrent);

    AReaderSettings := TACLXMLReaderSettings.Default;
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
                ACurrentNode.Attributes.Add(AReader.Name, AReader.Value);
              if AIsEmptyElement then
                ACurrentNode := ACurrentNode.Parent;
            end;

          TACLXMLNodeType.CDATA,
          TACLXMLNodeType.Text,
          TACLXMLNodeType.SignificantWhitespace:
            if ACurrentNode <> nil then
              ACurrentNode.NodeValue := AReader.Text;
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

procedure TACLXMLDocument.SaveToFile(const AFileName: UnicodeString);
begin
  SaveToFile(AFileName, TACLXMLDocumentFormatSettings.Default);
end;

procedure TACLXMLDocument.SaveToFile(const AFileName: UnicodeString; const ASettings: TACLXMLDocumentFormatSettings);
var
  AStream: TStream;
begin
  AStream := StreamCreateWriter(AFileName);
  try
    SaveToStream(AStream, ASettings);
  finally
    AStream.Free;
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
    ANode.NodeValue := AStream.ReadString(ReadValue(AStream));

  if AFlags and TACLBinaryXML.FlagsHasAttributes <> 0 then
  begin
    ACount := ReadValue(AStream);
    ANode.Attributes.Capacity := ACount;
    while ACount > 0 do
    begin
      AAttr := ANode.Attributes.Add;
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

class procedure TACLBinaryXMLParser.ReadStringTable(AStream: TStream; out AStringTable: TStringDynArray);
var
  ACount: Integer;
  AIndex: Integer;
begin
  ACount := ReadValue(AStream);
  SetLength(AStringTable, ACount);
  for AIndex := 0 to ACount - 1 do
    AStringTable[AIndex] := acStringFromAnsiString(AStream.ReadStringA(ReadValue(AStream)));
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

  function ReadLargeString(AStream: TStream): UnicodeString;
  var
    ALength: Integer;
  begin
    ALength := AStream.ReadInt32;
    if ALength > 0 then
    begin
      SetLength(Result, ALength);
      AStream.ReadBuffer(Result[1], 2 * ALength);
    end;
  end;

var
  AAttr: TACLXMLAttribute;
  ACount: Integer;
  AFlags: Byte;
begin
  AFlags := AStream.ReadByte;
  if AFlags and TACLBinaryXML.FlagsHasValue <> 0 then
    ANode.NodeValue := ReadLargeString(AStream);

  if AFlags and TACLBinaryXML.FlagsHasAttributes <> 0 then
  begin
    ACount := AStream.ReadInt32;
    ANode.Attributes.Capacity := ACount;
    while ACount > 0 do
    begin
      AAttr := ANode.Attributes.Add;
      AAttr.FName := acStringFromAnsiString(AStream.ReadStringWithLengthA);
      AAttr.Value := AStream.ReadStringWithLength;
      Dec(ACount);
    end;
  end;

  if AFlags and TACLBinaryXML.FlagsHasChildren <> 0 then
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
      ReadNode(AStream, AParent.Add(acStringFromAnsiString(AStream.ReadStringWithLengthA)));
      Dec(ACount);
    end;
  end;
end;

{ TACLXMLBuilder }

constructor TACLXMLBuilder.Create(AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings);
begin
  // just to be a virtual;
end;

{ TACLBinaryXMLBuilder }

constructor TACLBinaryXMLBuilder.Create(AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings);
begin
  inherited;
  FStream := AStream;
  FStringTable := TACLDictionary<UnicodeString, Integer>.Create;
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

function TACLBinaryXMLBuilder.Share(const A: UnicodeString): Integer;
begin
  if not FStringTable.TryGetValue(A, Result) then
  begin
    Result := FStringTable.Count;
    FStringTable.AddOrSetValue(A, Result);
  end;
end;

procedure TACLBinaryXMLBuilder.WriteNode(ANode: TACLXMLNode);
var
  AAttr: TACLXMLAttribute;
  AFlags: Byte;
begin
  WriteValue(Share(ANode.NodeName));

  AFlags := 0;
  if ANode.Count > 0 then
    AFlags := AFlags or TACLBinaryXML.FlagsHasChildren;
  if ANode.Attributes.Count > 0 then
    AFlags := AFlags or TACLBinaryXML.FlagsHasAttributes;
  if ANode.NodeValue <> acEmptyStr then
    AFlags := AFlags or TACLBinaryXML.FlagsHasValue;

  Stream.WriteByte(AFlags);
  if AFlags and TACLBinaryXML.FlagsHasValue <> 0 then
    WriteString(ANode.NodeValue);

  if AFlags and TACLBinaryXML.FlagsHasAttributes <> 0 then
  begin
    WriteValue(ANode.Attributes.Count);
    for var I := 0 to ANode.Attributes.Count - 1 do
    begin
      AAttr := ANode.Attributes[I];
      WriteValue(Share(AAttr.Name));
      WriteString(AAttr.Value);
    end;
  end;

  if AFlags and TACLBinaryXML.FlagsHasChildren <> 0 then
    WriteSubNodes(ANode);
end;

procedure TACLBinaryXMLBuilder.WriteString(const S: UnicodeString);
var
  ALength: Cardinal;
begin
  ALength := Length(S);
  WriteValue(ALength);
  if ALength > 0 then
    Stream.WriteString(S);
end;

procedure TACLBinaryXMLBuilder.WriteStringTable;
var
  L: Integer;
  S: AnsiString;
begin
  WriteValue(FStringTable.Count);
  for var P in FStringTable do
  begin
    S := AnsiString(P.Key);
    L := Length(S);
    WriteValue(L);
    if L > 0 then
      Stream.WriteStringA(S);
  end;
end;

procedure TACLBinaryXMLBuilder.WriteSubNodes(ANode: TACLXMLNode);
begin
  WriteValue(ANode.Count);
  for var I := 0 to ANode.Count - 1 do
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

constructor TACLTextXMLBuilder.Create(AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings);
var
  AWriterSettings: TACLXMLWriterSettings;
begin
  inherited;
  AWriterSettings := TACLXMLWriterSettings.Default;
  AWriterSettings.CheckWellformed := False; // у нас имя ноды уже идет с префиксом (prefix:name), валидация не пройдет.
  AWriterSettings.NewLineOnAttributes := ASettings.NewLineOnAttributes;
  AWriterSettings.NewLineOnNode := ASettings.NewLineOnNode;
  FWriter := TACLXMLWriter.Create(AStream, AWriterSettings);
end;

destructor TACLTextXMLBuilder.Destroy;
begin
  FreeAndNil(FWriter);
  inherited;
end;

procedure TACLTextXMLBuilder.Build(ADocument: TACLXMLDocument);
begin
  FWriter.WriteStartDocument;
  if ADocument.Count > 0 then
    WriteNode(ADocument[0]);
  FWriter.WriteEndDocument;
end;

procedure TACLTextXMLBuilder.WriteNode(ANode: TACLXMLNode);
begin
  FWriter.WriteStartElement(ANode.NodeName);
  for var I := 0 to ANode.Attributes.Count - 1 do
    FWriter.WriteAttributeString(ANode.Attributes[I].Name, ANode.Attributes[I].Value);
  if ANode.NodeValue <> acEmptyStr then
    FWriter.WriteString(ANode.NodeValue);
  for var I := 0 to ANode.Count - 1 do
    WriteNode(ANode[I]);
  FWriter.WriteEndElement;
end;

end.
