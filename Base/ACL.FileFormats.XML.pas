{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*            Simple XML Document            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.FileFormats.XML;

{$I ACL.Config.inc}

interface

uses
  Windows, Classes, SysUtils, AnsiStrings, Variants,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Hashes,
  ACL.Utils.Common,
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

  { TACLXMLEncoding }

  TACLXMLEncodingType = (mxeNone, mxeUTF8, mxeWindows);
  TACLXMLEncoding = packed record
    CodePage: Integer;
    Encoding: TACLXMLEncodingType;
    constructor Create(AEncoding: TACLXMLEncodingType; ACodePage: Integer = 0);
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
    function ToString: string;
  end;

  { TACLXMLAttribute }

  TACLXMLAttribute = class
  private
    FName: AnsiString;
    FValue: UnicodeString;
  public
    procedure Assign(ASource: TACLXMLAttribute);
    function GetValueAsInteger(ADefaultValue: Integer = 0): Integer;
    //
    property Name: AnsiString read FName;
    property Value: UnicodeString read FValue write FValue;
  end;

  { TACLXMLAttributes }

  TACLXMLAttributes = class(TACLObjectList)
  strict private
    function GetItem(Index: Integer): TACLXMLAttribute;
  public
    function Add: TACLXMLAttribute; overload;
    function Add(const AName: AnsiString; const AValue: Integer): TACLXMLAttribute; overload;
    function Add(const AName: AnsiString; const AValue: UnicodeString): TACLXMLAttribute; overload;
    procedure Assign(ASource: TACLXMLAttributes);
    function Equals(Obj: TObject): Boolean; override;
    function Contains(const AName: AnsiString): Boolean;
    function Find(const AName: AnsiString; out AAttr: TACLXMLAttribute): Boolean;
    function Last: TACLXMLAttribute;
    procedure MergeWith(ASource: TACLXMLAttributes);
    function Remove(const AAttr: TACLXMLAttribute): Boolean; overload;
    function Remove(const AName: AnsiString): Boolean; overload;
    function Rename(const AOldName, ANewName: AnsiString): Boolean;
    // Get
    function GetValue(const AName: AnsiString): UnicodeString; overload;
    function GetValue(const AName: AnsiString; out AValue: UnicodeString): Boolean; overload;
    function GetValueDef(const AName: AnsiString; const ADefault: UnicodeString): UnicodeString; overload;
    function GetValueAsBoolean(const AName: AnsiString; ADefault: Boolean = False): Boolean;
    function GetValueAsBooleanEx(const AName: AnsiString): TACLBoolean;
    function GetValueAsDateTime(const AName: AnsiString; const ADefault: TDateTime = 0): TDateTime;
    function GetValueAsDouble(const AName: AnsiString; const ADefault: Double = 0): Double;
    function GetValueAsInt64(const AName: AnsiString; const ADefault: Int64 = 0): Int64;
    function GetValueAsInteger(const AName: AnsiString; const ADefault: Integer = 0): Integer;
    function GetValueAsRect(const AName: AnsiString): TRect;
    function GetValueAsSize(const AName: AnsiString): TSize;
    function GetValueAsVariant(const AName: AnsiString): Variant;
    // Set
    procedure SetValue(const AName: AnsiString; const AValue: UnicodeString);
    procedure SetValueAsBoolean(const AName: AnsiString; AValue: Boolean);
    procedure SetValueAsBooleanEx(const AName: AnsiString; AValue: TACLBoolean);
    procedure SetValueAsDateTime(const AName: AnsiString; AValue: TDateTime);
    procedure SetValueAsDouble(const AName: AnsiString; const AValue: Double);
    procedure SetValueAsInt64(const AName: AnsiString; const AValue: Int64);
    procedure SetValueAsInteger(const AName: AnsiString; const AValue: Integer);
    procedure SetValueAsRect(const AName: AnsiString; const AValue: TRect);
    procedure SetValueAsSize(const AName: AnsiString; const AValue: TSize);
    procedure SetValueAsVariant(const AName: AnsiString; const AValue: Variant);
    //
    property Items[Index: Integer]: TACLXMLAttribute read GetItem; default;
  end;

  { TACLXMLNode }

  TACLXMLNodeFindProc = reference to function (ANode: TACLXMLNode): Boolean;
  TACLXMLNodeEnumProc = reference to procedure (ANode: TACLXMLNode);

  TACLXMLNodeClass = class of TACLXMLNode;
  TACLXMLNode = class
  private
    FSubNodes: TACLObjectList;
  strict private
    FAttributes: TACLXMLAttributes;
    FNodeName: AnsiString;
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
    constructor Create(AParent: TACLXMLNode); virtual;
    destructor Destroy; override;
    function Add(const AName: AnsiString): TACLXMLNode; virtual;
    procedure Enum(AProc: TACLXMLNodeEnumProc; ARecursive: Boolean = False); overload;
    procedure Enum(const ANodesNames: array of AnsiString; AProc: TACLXMLNodeEnumProc); overload;
    function Equals(Obj: TObject): Boolean; override;
    function FindNode(const ANodeName: AnsiString): TACLXMLNode; overload;
    function FindNode(const ANodeName: AnsiString; out ANode: TACLXMLNode): Boolean; overload;
    function FindNode(const ANodesNames: array of AnsiString; ACanCreate: Boolean = False): TACLXMLNode; overload;
    function FindNode(const ANodesNames: array of AnsiString; out ANode: TACLXMLNode; ACanCreate: Boolean = False): Boolean; overload;
    function FindNode(out ANode: TACLXMLNode; AFindProc: TACLXMLNodeFindProc; ARecursive: Boolean = True): Boolean; overload;
    function NodeValueByName(const ANodeName: AnsiString): UnicodeString; overload;
    function NodeValueByName(const ANodesNames: array of AnsiString): UnicodeString; overload;
    function NodeValueByNameAsInteger(const ANodeName: AnsiString): Integer;

    procedure Assign(ANode: TACLXMLNode); virtual;
    procedure Clear; virtual;
    procedure Sort(ASortProc: TListSortCompare);
    //
    property Attributes: TACLXMLAttributes read FAttributes;
    property Count: Integer read GetCount;
    property Empty: Boolean read GetEmpty;
    property Index: Integer read GetIndex write SetIndex;
    property NodeName: AnsiString read FNodeName write FNodeName;
    property Nodes[Index: Integer]: TACLXMLNode read GetNode; default;
    property NodeValue: UnicodeString read FNodeValue write FNodeValue;
    property NodeValueAsInteger: Integer read GetNodeValueAsInteger write SetNodeValueAsInteger;
    property Parent: TACLXMLNode read FParent write SetParent;
  end;

  { TACLXMLDocumentFormatSettings }

  TACLXMLDocumentFormatSettings = record
  private
    TextMode: Boolean;
    // TextMode only:
    AttributeOnNewLine: Boolean;
    AutoIndents: Boolean;
    NodeOnNewLine: Boolean;
  public
    class function Binary: TACLXMLDocumentFormatSettings; static;
    class function Default: TACLXMLDocumentFormatSettings; static;
    class function Text(AutoIndents: Boolean = True; NodeOnNewLine: Boolean = True;AttributeOnNewLine: Boolean = False): TACLXMLDocumentFormatSettings; static;
  end;

  { TACLXMLDocument }

  TACLXMLDocument = class(TACLXMLNode)
  protected
    FValidation: Boolean; // for legacy schemes
  public
    constructor Create; reintroduce; virtual;
    constructor CreateEx(AStream: TStream); overload;
    constructor CreateEx(const AFileName: UnicodeString); overload;
    destructor Destroy; override;
    function Add(const AName: AnsiString): TACLXMLNode; override;
    // Load
    procedure LoadFromFile(const AFileName: UnicodeString); overload;
    procedure LoadFromFile(const AFileName: UnicodeString; const ADefaultEncoding: TACLXMLEncoding); overload;
    procedure LoadFromResource(AInst: HINST; const AName, AType: UnicodeString);
    procedure LoadFromStream(AStream: TStream); overload;
    procedure LoadFromStream(AStream: TStream; const ADefaultEncoding: TACLXMLEncoding); overload; virtual;
    procedure LoadFromString(const AString: AnsiString); virtual;
    // Save
    procedure SaveToFile(const AFileName: UnicodeString); overload;
    procedure SaveToFile(const AFileName: UnicodeString; const ASettings: TACLXMLDocumentFormatSettings); overload;
    procedure SaveToStream(AStream: TStream); overload;
    procedure SaveToStream(AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings); overload; virtual;
  end;

  { TACLXMLConfig }

  TACLXMLConfig = class
  strict private
    class function FindOption(AOptionSet: TACLXMLNode; const AName: string; out AOption: TACLXMLNode; ACanCreate: Boolean = False): Boolean;
  public const
    Name = 'name';
    Option = 'option';
    Options = 'options';
    Value = 'value';
  public
    class function GetBoolean(AOptionSet: TACLXMLNode; const AName: string; ADefault: Boolean = False): Boolean;
    class function GetDateTime(AOptionSet: TACLXMLNode; const AName: string; const ADefault: TDateTime = 0): TDateTime;
    class function GetDouble(AOptionSet: TACLXMLNode; const AName: string; const ADefault: Double = 0): Double;
    class function GetInt64(AOptionSet: TACLXMLNode; const AName: string; const ADefault: Int64 = 0): Int64;
    class function GetInteger(AOptionSet: TACLXMLNode; const AName: string; ADefault: Integer = 0): Integer;
    class function GetString(AOptionSet: TACLXMLNode; const AName: string; const ADefault: string = ''): string;
    class procedure SetBoolean(AOptionSet: TACLXMLNode; const AName: string; AValue: Boolean);
    class procedure SetDateTime(AOptionSet: TACLXMLNode; const AName: string; const AValue: TDateTime);
    class procedure SetDouble(AOptionSet: TACLXMLNode; const AName: string; const AValue: Double);
    class procedure SetInt64(AOptionSet: TACLXMLNode; const AName: string; const AValue: Int64);
    class procedure SetInteger(AOptionSet: TACLXMLNode; const AName: string; const AValue: Integer);
    class procedure SetString(AOptionSet: TACLXMLNode; const AName: string; const AValue: string);
  end;

  { TACLXMLHelper }

  TACLXMLHelper = class
  strict private
    class var FMap: TACLStringsMap;

    class function GetReplacement(const S: UnicodeString): UnicodeString;
  public
    class constructor Create;
    class destructor Destroy;
    class function DecodeBoolean(const S: string): Boolean; static;
    class function DecodeString(const S: UnicodeString): UnicodeString;
    class function EncodeString(const S: UnicodeString): UnicodeString;
    class function IsHTMLCode(var P: PWideChar; var L: Integer): Boolean;
    class function IsPreserveSpacesModeNeeded(const S: UnicodeString): Boolean;
    //
    class property Map: TACLStringsMap read FMap;
  end;

implementation

uses
  Types, Math, StrUtils, ACL.Parsers;

const
  sXMLSpaceModeAttr = 'xml:space';
  sXMLSpaceModePreserve = 'preserve';

  sXMLBoolValues: array[Boolean] of AnsiString = ('false', 'true');

  sVariantTypeSuffix = 'Type';
  sVariantTypeBoolean = 'Bool';
  sVariantTypeDate = 'Date';
  sVariantTypeFloat = 'Float';
  sVariantTypeInt32 = 'Int32';
  sVariantTypeInt64 = 'Int64';
  sVariantTypeString = 'String';

type
  TACLXMLTokenType = (ttUnknown, ttEqual, ttTagHeaderBegin, ttTagHeaderEnd, ttTagEnd, ttTagFooter, ttComment, ttCDATA);

  TACLXMLToken = packed record
    Buffer: PAnsiChar;
    BufferLengthInChars: Integer;
    TokenType: TACLXMLTokenType;

    function ToString: AnsiString;
  end;

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
    class procedure ReadNode(AStream: TStream; ANode: TACLXMLNode; const AStringTable: TAnsiStringDynArray);
    class procedure ReadSubNodes(AStream: TStream; AParent: TACLXMLNode; const AStringTable: TAnsiStringDynArray);
    class procedure ReadStringTable(AStream: TStream; out AStringTable: TAnsiStringDynArray);
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

  { TACLTextXMLParser }

  TACLTextXMLParser = class
  strict private const
    CDataBegin = AnsiString('<![CDATA[');
    CDataEnd = AnsiString(']]>');
    CommentBegin = AnsiString('<!--');
    CommentEnd = AnsiString('-->');
    TagEncoding = 'encoding';
  strict private
    FData: PAnsiChar;
    FDataLength: Integer;
    FDocument: TACLXMLDocument;
    FEncoding: TACLXMLEncoding;

    function DecodeValue(const S: AnsiString): UnicodeString;
    function NextToken(out AToken: TACLXMLToken): Boolean; overload;
    function NextToken(var P: PAnsiChar; var C: Integer; out AToken: TACLXMLToken): Boolean; overload;
  protected
    procedure ParseEncoding;
    function ParseNodeHeader(ANode: TACLXMLNode): TACLXMLNode;
    procedure ParseNodeValue(ANode: TACLXMLNode; ATagHeaderEndCursor, ACursor: PAnsiChar; AIsPreserveSpacesMode: Boolean);
    procedure SkipTag;
  public
    constructor Create(ADocument: TACLXMLDocument); overload;
    constructor Create(ADocument: TACLXMLDocument; const AEncoding: TACLXMLEncoding); overload;
    procedure Parse(AScan: PAnsiChar; ACount: Integer);
    //
    property Document: TACLXMLDocument read FDocument;
    property Encoding: TACLXMLEncoding read FEncoding;
  end;

  { TACLXMLBuilder }

  TACLXMLBuilderClass = class of TACLXMLBuilder;
  TACLXMLBuilder = class
  strict private
    FDocument: TACLXMLDocument;
    FSettings: TACLXMLDocumentFormatSettings;
    FStream: TStream;
  public
    constructor Create(AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings; ADocument: TACLXMLDocument);
    procedure Build; virtual; abstract;
    //
    property Document: TACLXMLDocument read FDocument;
    property Settings: TACLXMLDocumentFormatSettings read FSettings;
    property Stream: TStream read FStream;
  end;

  { TACLBinaryXMLBuilder }

  TACLBinaryXMLBuilder = class(TACLXMLBuilder)
  strict private
    FStringTable: TACLDictionary<AnsiString, Integer>;

    function Share(const A: AnsiString): Integer;
  protected
    procedure WriteNode(ANode: TACLXMLNode);
    procedure WriteString(const S: AnsiString); overload;
    procedure WriteString(const S: UnicodeString); overload;
    procedure WriteStringTable;
    procedure WriteSubNodes(ANode: TACLXMLNode);
    procedure WriteValue(AValue: Cardinal);
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Build; override;
  end;

  { TACLTextXMLBuilder }

  TACLTextXMLBuilder = class(TACLXMLBuilder)
  strict private
    function EncodeValue(const S: UnicodeString): AnsiString;
    procedure WriteNode(ANode: TACLXMLNode; ALevel: Integer; AIsPreserveSpacesMode: Boolean);
    procedure WriteNodeAttribute(ALevel: Integer; const AName: AnsiString; const AValue: string);
    procedure WriteNodeAttributes(ANode: TACLXMLNode; ALevel: Integer);
    procedure WriteString(const S: AnsiString); overload;
    procedure WriteString(const S: AnsiString; ADupeCount: Integer); overload;
    procedure WriteSubNodes(ANode: TACLXMLNode; ALevel: Integer; AIsPreserveSpacesMode: Boolean);
  public
    procedure Build; override;
  end;

{ TACLXMLEncoding }

constructor TACLXMLEncoding.Create(AEncoding: TACLXMLEncodingType; ACodePage: Integer);
begin
  CodePage := ACodePage;
  Encoding := AEncoding;
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

constructor TACLXMLDateTime.Create(const ASource: UnicodeString);

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

function TACLXMLAttributes.Add(const AName: AnsiString; const AValue: Integer): TACLXMLAttribute;
begin
  Result := Add(AName, IntToStr(AValue));
end;

function TACLXMLAttributes.Add(const AName: AnsiString; const AValue: UnicodeString): TACLXMLAttribute;
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

function TACLXMLAttributes.Contains(const AName: AnsiString): Boolean;
var
  AAttr: TACLXMLAttribute;
begin
  Result := Find(AName, AAttr);
end;

function TACLXMLAttributes.Find(const AName: AnsiString; out AAttr: TACLXMLAttribute): Boolean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if AnsiStrings.SameText(TACLXMLAttribute(List[I]).Name, AName) then
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
var
  I: Integer;
begin
  for I := 0 to ASource.Count - 1 do
  begin
    if not Contains(ASource[I].Name) then
      SetValue(ASource[I].Name, ASource[I].Value);
  end;
end;

function TACLXMLAttributes.Remove(const AName: AnsiString): Boolean;
var
  AAttr: TACLXMLAttribute;
begin
  Result := Find(AName, AAttr) and Remove(AAttr);
end;

function TACLXMLAttributes.Remove(const AAttr: TACLXMLAttribute): Boolean;
begin
  Result := inherited Remove(AAttr) >= 0;
end;

function TACLXMLAttributes.Rename(const AOldName, ANewName: AnsiString): Boolean;
var
  AAttr: TACLXMLAttribute;
begin
  if Find(ANewName, AAttr) then
    Exit(False);

  Result := Find(AOldName, AAttr);
  if Result then
    AAttr.FName := ANewName;
end;

function TACLXMLAttributes.GetValue(const AName: AnsiString): UnicodeString;
begin
  if not GetValue(AName, Result) then
    Result := '';
end;

function TACLXMLAttributes.GetValue(const AName: AnsiString; out AValue: UnicodeString): Boolean;
var
  AAttr: TACLXMLAttribute;
begin
  Result := Find(AName, AAttr);
  if Result then
    AValue := AAttr.Value;
end;

function TACLXMLAttributes.GetValueDef(const AName: AnsiString; const ADefault: UnicodeString): UnicodeString;
begin
  if not GetValue(AName, Result) then
    Result := ADefault;
end;

function TACLXMLAttributes.GetValueAsDouble(const AName: AnsiString; const ADefault: Double = 0): Double;
var
  AValue: UnicodeString;
begin
  if GetValue(AName, AValue) then
    Result := StrToFloat(AValue, InvariantFormatSettings)
  else
    Result := ADefault;
end;

function TACLXMLAttributes.GetValueAsBoolean(const AName: AnsiString; ADefault: Boolean = False): Boolean;
var
  AValue: string;
begin
  if GetValue(AName, AValue) then
    Result := TACLXMLHelper.DecodeBoolean(AValue)
  else
    Result := ADefault;
end;

function TACLXMLAttributes.GetValueAsBooleanEx(const AName: AnsiString): TACLBoolean;
var
  AValue: string;
begin
  if GetValue(AName, AValue) then
    Result := TACLBoolean.From(TACLXMLHelper.DecodeBoolean(AValue))
  else
    Result := TACLBoolean.Default;
end;

function TACLXMLAttributes.GetValueAsDateTime(const AName: AnsiString; const ADefault: TDateTime = 0): TDateTime;
var
  AValue: UnicodeString;
begin
  if GetValue(AName, AValue) then
    Result := TACLXMLDateTime.Create(AValue).ToDateTime
  else
    Result := ADefault;
end;

function TACLXMLAttributes.GetValueAsInt64(const AName: AnsiString; const ADefault: Int64 = 0): Int64;
begin
  Result := StrToInt64Def(GetValue(AName), ADefault);
end;

function TACLXMLAttributes.GetValueAsInteger(const AName: AnsiString; const ADefault: Integer = 0): Integer;
begin
  Result := StrToIntDef(GetValue(AName), ADefault);
end;

function TACLXMLAttributes.GetValueAsRect(const AName: AnsiString): TRect;
begin
  Result := acStringToRect(GetValue(AName));
end;

function TACLXMLAttributes.GetValueAsSize(const AName: AnsiString): TSize;
begin
  Result := acStringToSize(GetValue(AName));
end;

function TACLXMLAttributes.GetValueAsVariant(const AName: AnsiString): Variant;
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

procedure TACLXMLAttributes.SetValue(const AName: AnsiString; const AValue: UnicodeString);
var
  AAttr: TACLXMLAttribute;
begin
  if Find(AName, AAttr) then
    AAttr.Value := AValue
  else
    Add(AName, AValue);
end;

procedure TACLXMLAttributes.SetValueAsBoolean(const AName: AnsiString; AValue: Boolean);
begin
  SetValueAsInteger(AName, Ord(AValue));
end;

procedure TACLXMLAttributes.SetValueAsBooleanEx(const AName: AnsiString; AValue: TACLBoolean);
begin
  if AValue = TACLBoolean.Default then
    Remove(AName)
  else
    SetValueAsBoolean(AName, AValue = TACLBoolean.True);
end;

procedure TACLXMLAttributes.SetValueAsDateTime(const AName: AnsiString; AValue: TDateTime);
begin
  AValue := LocalDateTimeToUTC(AValue);
  if AValue > 0 then
    SetValue(AName, TACLXMLDateTime.Create(AValue, True).ToString)
  else
    Remove(AName);
end;

procedure TACLXMLAttributes.SetValueAsDouble(const AName: AnsiString; const AValue: Double);
begin
  SetValue(AName, FloatToStr(AValue, InvariantFormatSettings));
end;

procedure TACLXMLAttributes.SetValueAsInt64(const AName: AnsiString; const AValue: Int64);
begin
  SetValue(AName, IntToStr(AValue));
end;

procedure TACLXMLAttributes.SetValueAsInteger(const AName: AnsiString; const AValue: Integer);
begin
  SetValue(AName, IntToStr(AValue));
end;

procedure TACLXMLAttributes.SetValueAsRect(const AName: AnsiString; const AValue: TRect);
begin
  SetValue(AName, acRectToString(AValue));
end;

procedure TACLXMLAttributes.SetValueAsSize(const AName: AnsiString; const AValue: TSize);
begin
  SetValue(AName, acSizeToString(AValue));
end;

procedure TACLXMLAttributes.SetValueAsVariant(const AName: AnsiString; const AValue: Variant);
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
    raise EInvalidOperation.Create(ClassName);
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

function TACLXMLNode.Add(const AName: AnsiString): TACLXMLNode;
begin
  SubNodesNeeded;
  Result := TACLXMLNodeClass(ClassType).Create(Self);
  Result.FNodeName := AName;
  FSubNodes.Add(Result);
end;

procedure TACLXMLNode.Assign(ANode: TACLXMLNode);
var
  I: Integer;
begin
  Clear;
  Attributes.Assign(ANode.Attributes);
  for I := 0 to ANode.Count - 1 do
    Add('').Assign(ANode[I]);
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
var
  I: Integer;
begin
  try
    for I := 0 to Count - 1 do
      AProc(Nodes[I]);
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

procedure TACLXMLNode.Enum(const ANodesNames: array of AnsiString; AProc: TACLXMLNodeEnumProc);
var
  ANode: TACLXMLNode;
begin
  if FindNode(ANodesNames, ANode) then
    ANode.Enum(AProc);
end;

function TACLXMLNode.Equals(Obj: TObject): Boolean;
var
  I: Integer;
begin
  Result := (ClassType = Obj.ClassType) and Attributes.Equals(TACLXMLNode(Obj).Attributes) and
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

function TACLXMLNode.FindNode(const ANodeName: AnsiString): TACLXMLNode;
begin
  if not FindNode(ANodeName, Result) then
    Result := nil;
end;

function TACLXMLNode.FindNode(const ANodeName: AnsiString; out ANode: TACLXMLNode): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
  begin
    Result := SameText(Nodes[I].NodeName, ANodeName);
    if Result then
    begin
      ANode := Nodes[I];
      Break;
    end;
  end;
end;

function TACLXMLNode.FindNode(const ANodesNames: array of AnsiString; ACanCreate: Boolean = False): TACLXMLNode;
begin
  if not FindNode(ANodesNames, Result, ACanCreate) then
    Result := nil;
end;

function TACLXMLNode.FindNode(const ANodesNames: array of AnsiString; out ANode: TACLXMLNode; ACanCreate: Boolean = False): Boolean;
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

function TACLXMLNode.NodeValueByName(const ANodeName: AnsiString): UnicodeString;
var
  ANode: TACLXMLNode;
begin
  ANode := FindNode(ANodeName);
  if ANode <> nil then
    Result := ANode.NodeValue
  else
    Result := '';
end;

function TACLXMLNode.NodeValueByName(const ANodesNames: array of AnsiString): UnicodeString;
var
  ANode: TACLXMLNode;
begin
  if FindNode(ANodesNames, ANode) then
    Result := ANode.NodeValue
  else
    Result := '';
end;

function TACLXMLNode.NodeValueByNameAsInteger(const ANodeName: AnsiString): Integer;
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
  Result := (Attributes.Count = 0) and (Count = 0) and (NodeValue = '');
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
  ZeroMemory(@Result, SizeOf(Result));
  Result.TextMode := False;
end;

class function TACLXMLDocumentFormatSettings.Default: TACLXMLDocumentFormatSettings;
begin
  Result := Text;
end;

class function TACLXMLDocumentFormatSettings.Text(AutoIndents, NodeOnNewLine, AttributeOnNewLine: Boolean): TACLXMLDocumentFormatSettings;
begin
  Result.TextMode := True;
  Result.AutoIndents := AutoIndents;
  Result.AttributeOnNewLine := AttributeOnNewLine;
  Result.NodeOnNewLine := NodeOnNewLine;
end;

{ TACLXMLDocument }

constructor TACLXMLDocument.Create;
begin
  inherited Create(nil);
  FValidation := True;
end;

constructor TACLXMLDocument.CreateEx(AStream: TStream);
begin
  Create;
  LoadFromStream(AStream);
end;

constructor TACLXMLDocument.CreateEx(const AFileName: UnicodeString);
begin
  Create;
  LoadFromFile(AFileName);
end;

destructor TACLXMLDocument.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TACLXMLDocument.Add(const AName: AnsiString): TACLXMLNode;
begin
  if (Count > 0) and FValidation then
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

procedure TACLXMLDocument.LoadFromFile(const AFileName: UnicodeString; const ADefaultEncoding: TACLXMLEncoding);
var
  AStream: TStream;
begin
  if StreamCreateReader(AFileName, AStream) then
  try
    LoadFromStream(AStream, ADefaultEncoding);
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
begin
  LoadFromStream(AStream, TACLXMLEncoding.Create(mxeNone));
end;

procedure TACLXMLDocument.LoadFromStream(AStream: TStream; const ADefaultEncoding: TACLXMLEncoding);
var
  ABuffer: PByte;
  ABufferSize: Int64;
  AHeader: Cardinal;
begin
  Clear;
  ABufferSize := AStream.Size - AStream.Position;
  if ABufferSize > SizeOf(Integer) then
  begin
    AHeader := AStream.ReadInt32;
    if AHeader = TACLBinaryXML.HeaderID then
      TACLBinaryXMLParser.Parse(Self, AStream)
    else if AHeader = $4C4D5842 then
      TACLLegacyBinaryXMLParser.Parse(Self, AStream)
    else
    begin
      AStream.Seek(-SizeOf(Integer), soCurrent);
      ABuffer := AllocMem(ABufferSize);
      try
        AStream.ReadBuffer(ABuffer^, ABufferSize);
        with TACLTextXMLParser.Create(Self, ADefaultEncoding) do
        try
          Parse(PAnsiChar(ABuffer), ABufferSize);
        finally
          Free;
        end;
      finally
        FreeMem(ABuffer);
      end;
    end;
  end;
end;

procedure TACLXMLDocument.LoadFromString(const AString: AnsiString);
begin
  with TACLTextXMLParser.Create(Self) do
  try
    Parse(PAnsiChar(AString), Length(AString));
  finally
    Free;
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
var
  ABuilder: TACLXMLBuilder;
begin
  ABuilder := ClassMap[ASettings.TextMode].Create(AStream, ASettings, Self);
  try
    ABuilder.Build;
  finally
    ABuilder.Free;
  end;
end;

{ TACLBinaryXMLParser }

class procedure TACLBinaryXMLParser.Parse(ADocument: TACLXMLDocument; AStream: TStream);
var
  APosition: Int64;
  ASize: Int64;
  ATable: TAnsiStringDynArray;
begin
  ASize := AStream.ReadInt64;
  APosition := AStream.Position;
  AStream.Position := APosition + ASize;
  ReadStringTable(AStream, ATable);
  AStream.Position := APosition;
  ReadSubNodes(AStream, ADocument, ATable);
end;

class procedure TACLBinaryXMLParser.ReadNode(AStream: TStream; ANode: TACLXMLNode; const AStringTable: TAnsiStringDynArray);

  function ReadString(AStream: TStream): UnicodeString;
  begin
    Result := AStream.ReadString(ReadValue(AStream));
  end;

var
  AAttr: TACLXMLAttribute;
  ACount: Integer;
  AFlags: Byte;
begin
  AFlags := AStream.ReadByte;
  if AFlags and TACLBinaryXML.FlagsHasValue <> 0 then
    ANode.NodeValue := ReadString(AStream);

  if AFlags and TACLBinaryXML.FlagsHasAttributes <> 0 then
  begin
    ACount := ReadValue(AStream);
    ANode.Attributes.Capacity := ACount;
    while ACount > 0 do
    begin
      AAttr := ANode.Attributes.Add;
      AAttr.FName := AStringTable[ReadValue(AStream)];
      AAttr.Value := ReadString(AStream);
      Dec(ACount);
    end;
  end;

  if AFlags and TACLBinaryXML.FlagsHasChildren <> 0 then
    ReadSubNodes(AStream, ANode, AStringTable);
end;

class procedure TACLBinaryXMLParser.ReadSubNodes(
  AStream: TStream; AParent: TACLXMLNode; const AStringTable: TAnsiStringDynArray);
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

class procedure TACLBinaryXMLParser.ReadStringTable(AStream: TStream; out AStringTable: TAnsiStringDynArray);
var
  ACount: Integer;
  AIndex: Integer;
begin
  ACount := ReadValue(AStream);
  SetLength(AStringTable, ACount);
  for AIndex := 0 to ACount - 1 do
    AStringTable[AIndex] := AStream.ReadStringA(ReadValue(AStream));
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
      AAttr.FName := AStream.ReadStringWithLengthA;
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
      ReadNode(AStream, AParent.Add(AStream.ReadStringWithLengthA));
      Dec(ACount);
    end;
  end;
end;

{ TACLTextXMLParser }

constructor TACLTextXMLParser.Create(ADocument: TACLXMLDocument);
begin
  Create(ADocument, TACLXMLEncoding.Create(mxeUTF8));
end;

constructor TACLTextXMLParser.Create(ADocument: TACLXMLDocument; const AEncoding: TACLXMLEncoding);
begin
  inherited Create;
  FDocument := ADocument;
  FEncoding := AEncoding;
end;

procedure TACLTextXMLParser.ParseEncoding;

  function DecodeEncoding(const AData: UnicodeString): TACLXMLEncoding;
  const
    sUTF8 = 'utf-8';
    sWindows = 'Windows-';
  begin
    if acSameText(AData, sUTF8) then
      Result := TACLXMLEncoding.Create(mxeUTF8)
    else
      if acBeginsWith(AData, sWindows) then
        Result := TACLXMLEncoding.Create(mxeWindows, StrToIntDef(Copy(AData, Length(sWindows) + 1, MaxInt), 0))
      else
        Result := TACLXMLEncoding.Create(mxeNone);
  end;

var
  AAttr: TACLXMLAttribute;
  ANode: TACLXMLNode;
begin
  ANode := TACLXMLNode.Create(nil);
  try
    ParseNodeHeader(ANode);
    if ANode.Attributes.Find(TagEncoding, AAttr) then
      FEncoding := DecodeEncoding(AAttr.Value)
  finally
    ANode.Free;
  end;
end;

procedure TACLTextXMLParser.ParseNodeValue(ANode: TACLXMLNode;
  ATagHeaderEndCursor, ACursor: PAnsiChar; AIsPreserveSpacesMode: Boolean);
var
  ALength: Integer;
  S1, S2: PAnsiChar;
begin
  if ATagHeaderEndCursor <> nil then
  begin
    S2 := ACursor - 1;
    S1 := ATagHeaderEndCursor;
    ALength := NativeUInt(S2) - NativeUInt(S1) + 1;
    if not AIsPreserveSpacesMode then
    begin
      while (ALength > 0) and (Ord(S1^) <= Ord(' ')) do
      begin
        Dec(ALength);
        Inc(S1);
      end;
      while (ALength > 0) and (Ord(S2^) <= Ord(' ')) do
      begin
        Dec(ALength);
        Dec(S2);
      end;
    end;
    if ALength > 0 then
      ANode.NodeValue := DecodeValue(acMakeString(S1, ALength));
  end;
end;

procedure TACLTextXMLParser.SkipTag;
var
  ANode: TACLXMLNode;
begin
  ANode := TACLXMLNode.Create(nil);
  try
    ParseNodeHeader(ANode);
  finally
    ANode.Free;
  end;
end;

function TACLTextXMLParser.ParseNodeHeader(ANode: TACLXMLNode): TACLXMLNode;
var
  AToken: TACLXMLToken;
  ATokenIndex: Integer;
begin
  ATokenIndex := 0;
  Result := ANode.Parent;
  while NextToken(AToken) do
  begin
    case AToken.TokenType of
      ttTagEnd:
        Break;
      ttTagHeaderBegin, ttComment, ttCDATA:
        Exit(nil);
      ttTagHeaderEnd:
        Exit(ANode);
    else
      begin
        if (ATokenIndex > 3) then
          ATokenIndex := 1;
        if (ATokenIndex = 0) then
          ANode.NodeName := AToken.ToString;
        if (ATokenIndex = 2) and (AToken.TokenType <> ttEqual) then
          ATokenIndex := 1;
        if (ATokenIndex = 1) then
          ANode.Attributes.Add(AToken.ToString, '');
        if (ATokenIndex = 3) then
          ANode.Attributes.Last.Value := DecodeValue(AToken.ToString);
      end;
    end;
    Inc(ATokenIndex);
  end;
end;

function TACLTextXMLParser.DecodeValue(const S: AnsiString): UnicodeString;
begin
  case Encoding.Encoding of
    mxeUTF8:
      Result := DecodeUTF8(S);
    mxeWindows:
      Result := acStringFromAnsi(S, Encoding.CodePage);
  else
    Result := acStringFromAnsi(S);
  end;
  Result := TACLXMLHelper.DecodeString(Result);
end;

function TACLTextXMLParser.NextToken(out AToken: TACLXMLToken): Boolean;
begin
  Result := NextToken(FData, FDataLength, AToken);
end;

function TACLTextXMLParser.NextToken(var P: PAnsiChar; var C: Integer; out AToken: TACLXMLToken): Boolean;

  function IsSpace(const A: AnsiChar): LongBool; inline;
  begin
    Result := (A = ' ') or (A = #9) or (A = #13) or (A = #10);
  end;

  function IsQuot(const A: AnsiChar): LongBool; inline;
  begin
    Result := (A = '"') or (A = #39);
  end;

  function IsTagDelimiter(const A: AnsiChar): LongBool; inline;
  begin
    Result := (A = '<') or (A = '>');
  end;

  function IsDelimiter(const A: AnsiChar): LongBool; inline;
  begin
    Result := (A = '=') or (A = '/') or IsTagDelimiter(A){ or IsQuot(A)} or IsSpace(A);
  end;

  procedure MoveToNextSymbol;
  begin
    if C > 0 then
    begin
      Inc(P);
      Dec(C);
    end;
  end;

  procedure MoveUntilQuotOrTag(AQuot: AnsiChar);
  begin
    while (C > 0) and (P^ <> AQuot) and not IsTagDelimiter(P^) do
    begin
      Inc(P);
      Dec(C);
    end;
  end;

  procedure MoveUntilDelimiter;
  begin
    while (C > 0) and not IsDelimiter(P^) do
    begin
      Inc(P);
      Dec(C);
    end;
  end;

  procedure SkipSpaces;
  begin
    while (C > 0) and IsSpace(P^) do
    begin
      Inc(P);
      Dec(C);
    end;
  end;

  procedure PutSpecialToken(AType: TACLXMLTokenType; ALength: Integer; AOffsetFromStart: Integer = 0; AOffsetFromFinish: Integer = 0);
  begin
    AToken.Buffer := P + AOffsetFromStart;
    AToken.BufferLengthInChars := ALength - AOffsetFromStart - AOffsetFromFinish;
    AToken.TokenType := AType;
    Dec(C, ALength);
    Inc(P, ALength);
  end;

  function CheckBounds(const AStartID, AFinishID: AnsiString; out ALength: Integer): Boolean;
  var
    LS, LF: Integer;
  begin
    Result := False;
    LS := Length(AStartID);
    LF := Length(AFinishID);
    if (C > LS + LF) and CompareMem(P, @AStartID[1], LS) then
    begin
      Result := acFindStringInMemoryA(AFinishID, PByte(P), C, LS, ALength);
      if Result then
        Inc(ALength, LF);
    end;
  end;

  function CheckForSpecialToken: Boolean;
  var
    ALength: Integer;
  begin
    case P^ of
      '<':
        if (C > 1) and (PAnsiChar(P + 1)^ = '/') then
          PutSpecialToken(ttTagFooter, 2)
        else
          if (C > 1) and (PAnsiChar(P + 1)^ = '!') then
          begin
            if CheckBounds(CommentBegin, CommentEnd, ALength) then
              PutSpecialToken(ttComment, ALength, Length(CommentBegin), Length(CommentEnd))
            else if CheckBounds(CDataBegin, CDataEnd, ALength) then
              PutSpecialToken(ttCDATA, ALength, Length(CDataBegin), Length(CDataEnd))
            else
              PutSpecialToken(ttTagHeaderBegin, 1);
          end
          else
            PutSpecialToken(ttTagHeaderBegin, 1);

      '/', '?':
        if (C > 1) and (PAnsiChar(P + 1)^ = '>') then
          PutSpecialToken(ttTagEnd, 2);
      '=':
        PutSpecialToken(ttEqual, 1);
      '>':
        PutSpecialToken(ttTagHeaderEnd, 1);
    end;
    Result := AToken.TokenType <> ttUnknown;
  end;

var
  AQuot: AnsiChar;
begin
  SkipSpaces;
  AToken.TokenType := ttUnknown;
  AToken.BufferLengthInChars := 0;
  Result := C > 0;
  if Result then
  begin
    if IsQuot(P^) then
    begin
      AQuot := P^;
      MoveToNextSymbol;
      AToken.Buffer := P;
      MoveUntilQuotOrTag(AQuot);
      AToken.BufferLengthInChars := NativeUInt(P) - NativeUInt(AToken.Buffer);
      if P^ = AQuot then
        MoveToNextSymbol;
    end
    else
      if not CheckForSpecialToken then
      begin
        if IsDelimiter(P^) then
        begin
          AToken.Buffer := P;
          AToken.BufferLengthInChars := 1;
          MoveToNextSymbol;
        end
        else
        begin
          AToken.Buffer := P;
          MoveUntilDelimiter;
          AToken.BufferLengthInChars := NativeUInt(P) - NativeUInt(AToken.Buffer);
        end;
      end;
  end;
end;

procedure TACLTextXMLParser.Parse(AScan: PAnsiChar; ACount: Integer);
var
  AAttr: TACLXMLAttribute;
  AIsPreserveSpacesMode: Boolean;
  ANextNode: TACLXMLNode;
  ANode: TACLXMLNode;
  ATagHeaderEndCursor: PAnsiChar;
  AToken: TACLXMLToken;
begin
  FData := AScan;
  FDataLength := ACount;

  ANode := Document;
  ANode.Clear;
  AIsPreserveSpacesMode := False;

  ATagHeaderEndCursor := nil;
  while NextToken(AToken) do
    case AToken.TokenType of
      ttComment:
        ATagHeaderEndCursor := nil;

      ttCDATA:
        begin
          ANode.NodeValue := DecodeValue(AToken.ToString);
          ATagHeaderEndCursor := nil;
        end;

      ttTagHeaderBegin:
        if (FDataLength > 0) and (FData^ = '?') then
          ParseEncoding
        else
          if (FDataLength > 0) and (FData^ = '!') then
            SkipTag
          else
          begin
            ParseNodeValue(ANode, ATagHeaderEndCursor, FData - AToken.BufferLengthInChars, AIsPreserveSpacesMode);
            ANextNode := ANode.Add(EmptyAnsiStr);
            ANode := ParseNodeHeader(ANextNode);
            if ANextNode.Attributes.Find(sXMLSpaceModeAttr, AAttr) then
            try
              AIsPreserveSpacesMode := acSameText(AAttr.Value, sXMLSpaceModePreserve);
            finally
              ANextNode.Attributes.Remove(sXMLSpaceModeAttr);
            end;
            if ANode <> ANextNode then
              AIsPreserveSpacesMode := False;
            if ANode = nil then Break;
            ATagHeaderEndCursor := FData;
          end;

      ttTagFooter:
        begin
          if ANode.Count = 0 then
            ParseNodeValue(ANode, ATagHeaderEndCursor, FData - AToken.BufferLengthInChars, AIsPreserveSpacesMode);
          AIsPreserveSpacesMode := False;
          ANode := ANode.Parent;
          if ANode = nil then Break;
          ATagHeaderEndCursor := nil;
        end;
    end;
end;

{ TACLXMLBuilder }

constructor TACLXMLBuilder.Create(AStream: TStream; const ASettings: TACLXMLDocumentFormatSettings; ADocument: TACLXMLDocument);
begin
  inherited Create;
  FStream := AStream;
  FSettings := ASettings;
  FDocument := ADocument;
end;

{ TACLTextXMLBuilder }

procedure TACLTextXMLBuilder.Build;
begin
  WriteString('<?xml version="1.0" encoding="utf-8"?>');
  WriteString(acCRLF);
  WriteSubNodes(Document, 0, False);
end;

procedure TACLTextXMLBuilder.WriteNode(ANode: TACLXMLNode; ALevel: Integer; AIsPreserveSpacesMode: Boolean);
const
  NodeEndMap: array[Boolean] of AnsiString = ('/>', '>');
var
  AHasContent: Boolean;
begin
  if Settings.AutoIndents and not AIsPreserveSpacesMode then
    WriteString(#9, ALevel);
  WriteString('<' + ANode.NodeName);

  AHasContent := (ANode.NodeValue <> '') or (ANode.Count > 0);
  AIsPreserveSpacesMode := AHasContent and TACLXMLHelper.IsPreserveSpacesModeNeeded(ANode.NodeValue);
  if (ANode.Attributes.Count > 0) or AIsPreserveSpacesMode then
  begin
    WriteNodeAttributes(ANode, ALevel);
    if AIsPreserveSpacesMode then
      WriteNodeAttribute(ALevel, sXMLSpaceModeAttr, sXMLSpaceModePreserve);
    if Settings.AutoIndents and Settings.AttributeOnNewLine then
    begin
      WriteString(acCRLF);
      WriteString(#9, ALevel);
    end;
  end;

  WriteString(NodeEndMap[AHasContent]);

  if AHasContent then
  begin
    WriteString(EncodeValue(ANode.NodeValue));
    if ANode.Count > 0 then
    begin
      if Settings.NodeOnNewLine and not AIsPreserveSpacesMode then
        WriteString(acCRLF);
      WriteSubNodes(ANode, ALevel + 1, AIsPreserveSpacesMode);
      if Settings.AutoIndents then
        WriteString(#9, ALevel);
    end;
    WriteString('</' + ANode.NodeName + '>');
  end;

  if Settings.NodeOnNewLine then
    WriteString(acCRLF);
end;

procedure TACLTextXMLBuilder.WriteNodeAttribute(ALevel: Integer; const AName: AnsiString; const AValue: string);
begin
  if AName <> '' then
  begin
    if Settings.AttributeOnNewLine then
    begin
      WriteString(acCRLF);
      WriteString(#9, ALevel + 1);
    end
    else
      WriteString(' ');

    WriteString(AName);
    WriteString('=');
    WriteString('"');
    WriteString(EncodeValue(AValue));
    WriteString('"');
  end;
end;

procedure TACLTextXMLBuilder.WriteNodeAttributes(ANode: TACLXMLNode; ALevel: Integer);
var
  AAttr: TACLXMLAttribute;
  I: Integer;
begin
  for I := 0 to ANode.Attributes.Count - 1 do
  begin
    AAttr := ANode.Attributes[I];
    WriteNodeAttribute(ALevel, AAttr.Name, AAttr.Value);
  end;
end;

procedure TACLTextXMLBuilder.WriteString(const S: AnsiString);
begin
  Stream.WriteStringA(S);
end;

procedure TACLTextXMLBuilder.WriteString(const S: AnsiString; ADupeCount: Integer);
begin
  while ADupeCount > 0 do
  begin
    Stream.WriteStringA(S);
    Dec(ADupeCount);
  end;
end;

procedure TACLTextXMLBuilder.WriteSubNodes(ANode: TACLXMLNode; ALevel: Integer; AIsPreserveSpacesMode: Boolean);
var
  I: Integer;
begin
  for I := 0 to ANode.Count - 1 do
    WriteNode(ANode.Nodes[I], ALevel, AIsPreserveSpacesMode);
end;

function TACLTextXMLBuilder.EncodeValue(const S: UnicodeString): AnsiString;
begin
  Result := EncodeUTF8(TACLXMLHelper.EncodeString(S));
end;

{ TACLBinaryXMLBuilder }

procedure TACLBinaryXMLBuilder.AfterConstruction;
begin
  inherited;
  FStringTable := TACLDictionary<AnsiString, Integer>.Create;
end;

procedure TACLBinaryXMLBuilder.BeforeDestruction;
begin
  inherited;
  FreeAndNil(FStringTable);
end;

procedure TACLBinaryXMLBuilder.Build;
var
  ATablePosition: Int64;
  AValuePosition: Int64;
begin
  Stream.WriteInt32(TACLBinaryXML.HeaderID);
  AValuePosition := Stream.Position;
  Stream.WriteInt64(0);
  WriteSubNodes(Document);
  ATablePosition := Stream.Position;
  Stream.Position := AValuePosition;
  Stream.WriteInt64(ATablePosition - AValuePosition - SizeOf(Int64));
  Stream.Position := ATablePosition;
  WriteStringTable;
end;

function TACLBinaryXMLBuilder.Share(const A: AnsiString): Integer;
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
  I: Integer;
begin
  WriteString(ANode.NodeName);

  AFlags := 0;
  if ANode.Count > 0 then
    AFlags := AFlags or TACLBinaryXML.FlagsHasChildren;
  if ANode.Attributes.Count > 0 then
    AFlags := AFlags or TACLBinaryXML.FlagsHasAttributes;
  if ANode.NodeValue <> '' then
    AFlags := AFlags or TACLBinaryXML.FlagsHasValue;

  Stream.WriteByte(AFlags);
  if AFlags and TACLBinaryXML.FlagsHasValue <> 0 then
    WriteString(ANode.NodeValue);

  if AFlags and TACLBinaryXML.FlagsHasAttributes <> 0 then
  begin
    WriteValue(ANode.Attributes.Count);
    for I := 0 to ANode.Attributes.Count - 1 do
    begin
      AAttr := ANode.Attributes[I];
      WriteString(AAttr.Name);
      WriteString(AAttr.Value);
    end;
  end;

  if AFlags and TACLBinaryXML.FlagsHasChildren <> 0 then
    WriteSubNodes(ANode);
end;

procedure TACLBinaryXMLBuilder.WriteString(const S: AnsiString);
begin
  WriteValue(Share(S));
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
  AList: TAnsiStringDynArray;
  I: Integer;
  L: Integer;
  S: AnsiString;
begin
  SetLength(AList, FStringTable.Count);
  FStringTable.Enum(
    procedure (const A: AnsiString; const R: Integer)
    begin
      AList[R] := A;
    end);

  L := Length(AList);
  WriteValue(L);
  for I := 0 to L - 1 do
  begin
    S := AList[I];
    L := Length(S);
    WriteValue(L);
    if L > 0 then
      Stream.WriteStringA(S);
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

{ TACLXMLConfig }

class function TACLXMLConfig.GetBoolean(AOptionSet: TACLXMLNode; const AName: string; ADefault: Boolean): Boolean;
var
  ANode: TACLXMLNode;
begin
  if FindOption(AOptionSet, AName, ANode) then
    Result := ANode.Attributes.GetValueAsBoolean(Value, ADefault)
  else
    Result := ADefault;
end;

class function TACLXMLConfig.GetDateTime(AOptionSet: TACLXMLNode; const AName: string; const ADefault: TDateTime): TDateTime;
var
  ANode: TACLXMLNode;
begin
  if FindOption(AOptionSet, AName, ANode) then
    Result := ANode.Attributes.GetValueAsDateTime(Value, ADefault)
  else
    Result := ADefault;
end;

class function TACLXMLConfig.GetDouble(AOptionSet: TACLXMLNode; const AName: string; const ADefault: Double): Double;
var
  ANode: TACLXMLNode;
begin
  if FindOption(AOptionSet, AName, ANode) then
    Result := ANode.Attributes.GetValueAsDouble(Value, ADefault)
  else
    Result := ADefault;
end;

class function TACLXMLConfig.GetInt64(AOptionSet: TACLXMLNode; const AName: string; const ADefault: Int64): Int64;
var
  ANode: TACLXMLNode;
begin
  if FindOption(AOptionSet, AName, ANode) then
    Result := ANode.Attributes.GetValueAsInt64(Value, ADefault)
  else
    Result := ADefault;
end;

class function TACLXMLConfig.GetInteger(AOptionSet: TACLXMLNode; const AName: string; ADefault: Integer): Integer;
var
  ANode: TACLXMLNode;
begin
  if FindOption(AOptionSet, AName, ANode) then
    Result := ANode.Attributes.GetValueAsInteger(Value, ADefault)
  else
    Result := ADefault;
end;

class function TACLXMLConfig.GetString(AOptionSet: TACLXMLNode; const AName: string; const ADefault: string): string;
var
  ANode: TACLXMLNode;
begin
  if FindOption(AOptionSet, AName, ANode) then
    Result := ANode.Attributes.GetValueDef(Value, ADefault)
  else
    Result := ADefault;
end;

class procedure TACLXMLConfig.SetBoolean(AOptionSet: TACLXMLNode; const AName: string; AValue: Boolean);
var
  ANode: TACLXMLNode;
begin
  if FindOption(AOptionSet, AName, ANode, True) then
    ANode.Attributes.SetValueAsBoolean(Value, AValue);
end;

class procedure TACLXMLConfig.SetDateTime(AOptionSet: TACLXMLNode; const AName: string; const AValue: TDateTime);
var
  ANode: TACLXMLNode;
begin
  if FindOption(AOptionSet, AName, ANode, True) then
    ANode.Attributes.SetValueAsDateTime(Value, AValue);
end;

class procedure TACLXMLConfig.SetDouble(AOptionSet: TACLXMLNode; const AName: string; const AValue: Double);
var
  ANode: TACLXMLNode;
begin
  if FindOption(AOptionSet, AName, ANode, True) then
    ANode.Attributes.SetValueAsDouble(Value, AValue);
end;

class procedure TACLXMLConfig.SetInt64(AOptionSet: TACLXMLNode; const AName: string; const AValue: Int64);
var
  ANode: TACLXMLNode;
begin
  if FindOption(AOptionSet, AName, ANode, True) then
    ANode.Attributes.SetValueAsInt64(Value, AValue);
end;

class procedure TACLXMLConfig.SetInteger(AOptionSet: TACLXMLNode; const AName: string; const AValue: Integer);
var
  ANode: TACLXMLNode;
begin
  if FindOption(AOptionSet, AName, ANode, True) then
    ANode.Attributes.SetValueAsInteger(Value, AValue);
end;

class procedure TACLXMLConfig.SetString(AOptionSet: TACLXMLNode; const AName: string; const AValue: string);
var
  ANode: TACLXMLNode;
begin
  if FindOption(AOptionSet, AName, ANode, True) then
    ANode.Attributes.SetValue(Value, AValue);
end;

class function TACLXMLConfig.FindOption(AOptionSet: TACLXMLNode; const AName: string; out AOption: TACLXMLNode; ACanCreate: Boolean): Boolean;
var
  I: Integer;
begin
  for I := 0 to AOptionSet.Count - 1 do
  begin
    if AOptionSet[I].Attributes.GetValue(Name) = AName then
    begin
      AOption := AOptionSet[I];
      Exit(True);
    end;
  end;

  Result := ACanCreate;
  if Result then
  begin
    AOption := AOptionSet.Add(Option);
    AOption.Attributes.Add(Name, AName);
  end;
end;

{ TACLXMLHelper }

class constructor TACLXMLHelper.Create;
begin
  FMap := TACLStringsMap.Create;
  FMap.Add('&', 'amp');
  FMap.Add('>', 'gt');
  FMap.Add('<', 'lt');
  FMap.Add('"', 'quot');
  FMap.Add(#39, 'apos');
end;

class destructor TACLXMLHelper.Destroy;
begin
  FreeAndNil(FMap);
end;

class function TACLXMLHelper.DecodeBoolean(const S: string): Boolean;
var
  AValue: Integer;
begin
  if TryStrToInt(S, AValue) then
    Result := AValue <> 0
  else
    Result := SameText(S, string(sXMLBoolValues[True]));
end;

class function TACLXMLHelper.DecodeString(const S: UnicodeString): UnicodeString;
var
  B: TStringBuilder;
  L, LS: Integer;
  P, PS: PWideChar;
  V: UnicodeString;
begin
  P := PWideChar(S);
  L := Length(S);
  B := TACLStringBuilderManager.Get(L);
  try
    while L > 0 do
    begin
      if (P^ = '\') and (L > 0) and Map.TryGetValue((P + 1)^, V) then
      begin
        // Skip backslash and add next symbol to the queue
        Inc(P);
        Dec(L);
      end
      else
        if P^ = '&' then
        begin
          PS := P + 1;
          LS := L - 1;
          if IsHTMLCode(PS, LS) then
          begin
            B.Append(GetReplacement(acExtractString(P + 1, PS)));
            P := PS + 1;
            L := LS - 1;
            Continue;
          end;
        end;

      B.Append(P^);
      Dec(L);
      Inc(P);
    end;
    Result := B.ToString;
  finally
    TACLStringBuilderManager.Release(B);
  end;
end;

class function TACLXMLHelper.EncodeString(const S: UnicodeString): UnicodeString;
var
  B: TStringBuilder;
  L, LS: Integer;
  P, PS: PWideChar;
  V: UnicodeString;
begin
  P := PWideChar(S);
  L := Length(S);
  B := TACLStringBuilderManager.Get(L);
  try
    while L > 0 do
    begin
      if P^ = '&' then
      begin
        PS := P + 1;
        LS := L - 1;
        if IsHTMLCode(PS, LS) then
        begin
          B.Append(acExtractString(P, PS + 1));
          P := PS + 1;
          L := LS - 1;
          Continue;
        end;
      end;

      if Map.TryGetValue(P^, V) then
      begin
        B.Append('&');
        B.Append(V);
        B.Append(';');
      end
      else
        B.Append(P^);

      Dec(L);
      Inc(P);
    end;
    Result := B.ToString;
  finally
    TACLStringBuilderManager.Release(B);
  end;
end;

class function TACLXMLHelper.IsHTMLCode(var P: PWideChar; var L: Integer): Boolean;
begin
  while (L > 0) and CharInSet(P^, ['0'..'9', '#', 'A'..'Z', 'a'..'z']) do
  begin
    Inc(P);
    Dec(L);
  end;
  Result := P^ = ';';
end;

class function TACLXMLHelper.IsPreserveSpacesModeNeeded(const S: UnicodeString): Boolean;
var
  I, L: Integer;
begin
  Result := False;
  L := Length(S);
  if L > 0 then
  begin
    Result := CharInSet(S[1], [#9, #10, #13, ' ']) or CharInSet(S[L], [#9, #10, #13, ' ']);
    if not Result then
      for I := 1 to Length(S) do
      begin
        if CharInSet(S[I], [#13, #10]) then
          Exit(True);
      end;
  end;
end;

class function TACLXMLHelper.GetReplacement(const S: UnicodeString): UnicodeString;
begin
  if not Map.TryGetKey(S, Result) then
  begin
    if (S <> '') and (S[1] = '#') then
      Result := Char(StrToIntDef(Copy(S, 2, MaxInt), 0))
    else
      Result := S;
  end;
end;

{ TACLXMLToken }

function TACLXMLToken.ToString: AnsiString;
begin
  SetString(Result, Buffer, BufferLengthInChars);
end;

end.
