{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*          Stream based XML Parser          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.FileFormats.XML.Reader;

{$I ACL.Config.inc}
{$SCOPEDENUMS ON}

// Ported from .NET platform:
// https://github.com/microsoft/referencesource/tree/master/System.Xml/System/Xml/Core

{.$DEFINE ACL_XML_DUPLICATES_CHECK} // Throws an exception if a node has duplicate attributes

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
  // System
  System.Classes,
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  // ACL
  ACL.Classes,
  ACL.FastCode,
  ACL.FileFormats.XML.Types,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type
  TACLXMLReadState = (
    Initial,     //# The Read method has not been called yet.
    Interactive, //# Reading is in progress.
    Error,       //# An error occurred that prevents the XmlReader from continuing.
    EndOfFile,   //# The end of the stream has been reached successfully.
    Closed       //# The Close method has been called and the XmlReader is closed.
  );

  TACLXMLNodeType = (
    None,
    Element,
    Attribute,
    Text,
    CDATA,
    EntityReference,
    Entity,
    ProcessingInstruction,
    Comment,
    Document,
    DocumentType,
    DocumentFragment,
    Notation,
    Whitespace,
    SignificantWhitespace,
    EndElement,
    EndEntity,
    XmlDeclaration
  );

{$REGION 'Internal'}

  { TACLXMLNameTable }

  TACLXMLNameTable = class
  strict private const
    TableSize = 257;
  strict private type
  {$REGION 'Sub-types'}
    PItem = ^TItem;
    TItem = record
      Hash: Cardinal;
      Value: string;
      Next: PItem;
    end;
    TTable = array[0..TableSize] of PItem;
  {$ENDREGION}
  strict private
    FTable: TTable;

    function Hash(P: PChar; L: Integer): Cardinal; inline;
    function NewItem(const S: string; AHash: Cardinal): PItem; overload; inline;
    function NewItem(const AKey: TCharArray; AStart, ALength: Integer; AHash: Cardinal): PItem; overload; inline;
  public
    destructor Destroy; override;
    function Add(const AKey: string): string; overload;
    function Add(const AKey: TCharArray; AStart, ALength: Integer): string; overload;
    function Get(const AValue: string): string; overload;
  end;

  { TACLXMLLineInfo }

  TACLXMLLineInfo = record
  strict private
    FLineNo: Integer;
    FLinePos: Integer;
  public
    procedure Init(ALineNo: Integer; ALinePos: Integer); inline;
    property LineNo: Integer read FLineNo;
    property LinePos: Integer read FLinePos;
  end;

  { TACLXMLNodeData }

  TACLXMLNodeData = class
  strict private type
    TValueLocation = (CharsBuffer, ValueString);
  strict private
    FChars: TCharArray;
    FDepth: Integer;
    FIsEmptyOrDefault: Boolean;
    FLineInfo: TACLXMLLineInfo;
    FLineInfo2: TACLXMLLineInfo;
    FLocalName: string;
    FNamespace: string;
    FNameWPrefix: string;
    FPrefix: string;
    FQuoteChar: Char;
    FType: TACLXMLNodeType;
    FValue: string;
    FValueLength: Integer;
    FValueLocation: TValueLocation; //# probably replace with special ValueStartPos value
    FValueStartPos: Integer;
    FXmlContextPushed: Boolean;

    function GetIsDefaultAttribute: Boolean; inline;
    function GetIsEmptyElement: Boolean; inline;
    function GetStringValue: string; inline;
    procedure SetIsDefaultAttribute(AValue: Boolean); inline;
    procedure SetIsEmptyElement(AValue: Boolean); inline;
  private // visible for unit only
    constructor Create;
    procedure OnBufferInvalidated; inline;

    procedure CopyTo(AValueOffset: Integer; ASb: TACLStringBuilder);
    function GetNameWPrefix(ANameTable: TACLXMLNameTable): string; inline;
    procedure SetNamedNode(AType: TACLXMLNodeType; const ALocalName, APrefix, ANameWPrefix: string); inline;
    procedure SetValue(const AChars: TCharArray; AStartPos, ALength: Integer); overload;
    procedure SetValue(const AValue: string); overload;
    procedure SetValueNode(AType: TACLXMLNodeType; const AChars: TCharArray; AStartPos, ALength: Integer); overload;
    procedure SetValueNode(AType: TACLXMLNodeType; const AValue: string); overload;

    property Depth: Integer read FDepth write FDepth;
    property LineInfo: TACLXMLLineInfo read FLineInfo;
    property LineInfo2: TACLXMLLineInfo read FLineInfo2;
    property LocalName: string read FLocalName;
    property Namespace: string read FNamespace write FNamespace;
    property Prefix: string read FPrefix;
    property QuoteChar: Char read FQuoteChar write FQuoteChar;
    property &Type: TACLXMLNodeType read FType write FType;
    property XmlContextPushed: Boolean read FXmlContextPushed write FXmlContextPushed;

    property IsDefaultAttribute: Boolean read GetIsDefaultAttribute write SetIsDefaultAttribute;
    property IsEmptyElement: Boolean read GetIsEmptyElement write SetIsEmptyElement;
    property StringValue: string read GetStringValue;
  end;

{$ENDREGION}

{$REGION 'XML-Reader'}

  { TACLXMLReader }

  TACLXMLReader = class
  private const
    DefaultBufferSize = 8192;
  strict private
    function GetDepth: Integer; inline;
    function GetLocalName: string; inline;
    function GetName: string; inline;
    function GetNamespaceURI: string; inline;
    function GetNodeType: TACLXMLNodeType; inline;
    function GetPrefix: string; inline;
    function GetValue: string; inline;
  private // visible for unit only
    FCurrentNode: TACLXMLNodeData;
    FNameTable: TACLXMLNameTable;
    FReadState: TACLXMLReadState;
  protected
    function GetText: string; virtual; abstract;
  public
    function GetAttribute(const APrefix, ALocalName, ANamespaceURI: string): string; overload; inline;
    function GetAttribute(const AAttribute, ANamespaceURI: string): string; overload; virtual; abstract;
    function GetAttribute(const AAttribute: AnsiString): string; overload; inline;
    function GetAttribute(const AAttribute: string): string; overload; inline;
    function GetAttributeAsBoolean(const AAttribute: AnsiString; const ADefaultValue: Boolean = False): Boolean; overload; inline;
    function GetAttributeAsBoolean(const AAttribute: string; const ADefaultValue: Boolean = False): Boolean; overload; inline;
    function GetAttributeAsInt64(const AAttribute: string; const ADefaultValue: Int64 = 0): Int64; overload; inline;
    function GetAttributeAsInteger(const AAttribute: string; ADefaultValue: Integer = 0): Integer; overload; inline;
    function GetAttributeAsSingle(const AAttribute: string; ADefaultValue: Single = 0): Single; overload; inline;
    function IsEmptyElement: Boolean; inline;
    function LookupNamespace(const ANameSpace: string): string; overload; virtual; abstract;
    function MoveToElement: Boolean; virtual; abstract;
    function MoveToNextAttribute: Boolean; virtual; abstract;
    function Read: Boolean; virtual; abstract;
    function SafeRead: Boolean; inline; // suppresses all exceptions
    procedure Skip; virtual;
    function TryGetAttribute(const AAttribute: string; out AValue: string): Boolean; overload; virtual; abstract;
    function TryGetAttribute(const APrefix, ALocalName, ANamespaceURI: string; out AValue: string): Boolean; overload; virtual; abstract;

    property Depth: Integer read GetDepth;
    property LocalName: string read GetLocalName;
    property Name: string read GetName;
    property NamespaceURI: string read GetNamespaceURI;
    property NodeType: TACLXMLNodeType read GetNodeType;
    property Prefix: string read GetPrefix;
    property ReadState: TACLXMLReadState read FReadState;
    property Text: string read GetText;
    property Value: string read GetValue;
  end;

  { TACLXMLReaderSettings }

  TACLXMLReaderSettings = record
  public
    CheckCharacters: Boolean;
    ConformanceLevel: TACLXMLConformanceLevel;
    DefaultEncoding: TEncoding;
    IgnoreComments: Boolean;
    IgnoreProcessingInstructions: Boolean;
    IgnoreWhitespace: Boolean;
    LineNumberOffset: Integer;
    LinePositionOffset: Integer;
    MaxCharactersInDocument: Int64;
    SupportNamespaces: Boolean;

    function CreateReader(AInput: TStream): TACLXMLReader;
    class function Default: TACLXMLReaderSettings; static;
  end;

{$ENDREGION}

{$REGION 'XML-Loaders'}

  { TACLXMLNodeLoader }

  TACLXMLNodeLoaders = class;

  TACLXMLNodeLoaderClass = class of TACLXMLNodeLoader;
  TACLXMLNodeLoader = class
  strict private
    FLoaders: TACLXMLNodeLoaders;

    function GetLoaders: TACLXMLNodeLoaders; inline;
  protected
    function GetLoader(AReader: TACLXMLReader): TACLXMLNodeLoader; virtual;
    function GetLoaderFilteredByAttribute(AReader: TACLXMLReader): TACLXMLNodeLoader; virtual;

    property Loaders: TACLXMLNodeLoaders read GetLoaders;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure OnBegin(var AContext: TObject); virtual;
    procedure OnAttributes(AContext: TObject; AReader: TACLXMLReader); virtual;
    procedure OnText(AContext: TObject; AReader: TACLXMLReader); virtual;
    procedure OnEnd(AContext: TObject); virtual;
  end;

  { TACLXMLNodeLoaders }

  TACLXMLTextLoader = procedure (AContext: TObject; const AText: string) of object;
  TACLXMLNodeLoaders = class
  strict private type
  {$REGION 'private types'}
    THolder = class
    strict private
      FClass: TACLXMLNodeLoaderClass;
      FInstance: TACLXMLNodeLoader;
    public
      constructor Create(AClass: TACLXMLNodeLoaderClass); overload;
      constructor Create(AInstance: TACLXMLNodeLoader); overload;
      destructor Destroy; override;
      function Instance: TACLXMLNodeLoader;
    end;
  {$ENDREGION}
  strict private
    FData: TDictionary<string, THolder>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const ANamespace, ANodeName: string; ALoader: TACLXMLNodeLoaderClass); overload;
    procedure Add(const ANamespace, ANodeName: string; AProc: TACLXMLTextLoader); overload;
    procedure Add(const ANodeName: string; ALoader: TACLXMLNodeLoader); overload;
    procedure Add(const ANodeName: string; ALoader: TACLXMLNodeLoaderClass); overload;
    procedure Add(const ANodeName: string; AProc: TACLXMLTextLoader); overload;
    function GetLoader(AReader: TACLXMLReader): TACLXMLNodeLoader; overload;
    function GetLoader(AReader: TACLXMLReader; const AName: string): TACLXMLNodeLoader; overload;
  end;

  { TACLXMLAttributeFilteredNodeLoader }

  TACLXMLAttributeFilteredNodeLoader = class(TACLXMLNodeLoader)
  protected
    FAttributeName: string;

    function GetLoader(AReader: TACLXMLReader): TACLXMLNodeLoader; override;
    function GetLoaderFilteredByAttribute(AReader: TACLXMLReader): TACLXMLNodeLoader; override;
  public
    procedure AfterConstruction; override;
  end;

  { TACLXMLDocumentLoader }

  TACLXMLDocumentLoader = class
  public
    Loaders: TACLXMLNodeLoaders;
    SkipRootNode: Boolean;
    Settings: TACLXMLReaderSettings;

    constructor Create;
    destructor Destroy; override;
    procedure Run(AContext: TObject; AStream: TStream);
  end;

{$ENDREGION}

implementation

uses
  System.Math,
  System.StrUtils;

{$REGION 'Error Messages'}
const
  SXmlBadAttributeChar = '''%s'', hexadecimal value %s, is an invalid attribute character.';
  SXmlBadDecimalEntity = 'Invalid syntax for a decimal numeric entity reference.';
  SXmlBadDTDLocation = 'Unexpected DTD declaration.';
  SXmlBadHexEntity = 'Invalid syntax for a hexadecimal numeric entity reference.';
  SXmlBadNameChar = 'The ''%s'' character, hexadecimal value %s, cannot be included in a name.';
  SXmlBadNamespaceDecl = 'Invalid namespace declaration.';
  SXmlBadStartNameChar = 'Name cannot begin with the ''%s'' character, hexadecimal value %s.';
  SXmlCDATAEndInText = ''']]&gt;'' is not allowed in character data.';
  SXmlCharEntityOverflow = 'Invalid value of a character entity reference.';
  SXmlDupAttributeName = '%s is a duplicate attribute name';
  SXmlEncodingSwitchAfterResetState = '''%s'' is an invalid value for the ''encoding'' attribute. ' +
    'The encoding cannot be switched after a call to ResetState';
  SXmlEntityReferencesNotImplemented = 'Entity references are not implemented';
  SXmlExpectExternalOrClose = 'Expecting external ID, ''['' or ''&gt;''.';
  SXmlExpectSubOrClose = 'Expecting an internal subset or the end of the DOCTYPE declaration.';
  SXmlExpectingWhiteSpace = '''%s'' is an unexpected token. Expecting white space.';
  SXmlInternalError = 'An internal error has occurred.';
  SXmlInvalidCharacter = '''%s'', hexadecimal value %s, is an invalid character.';
  SXmlInvalidCharInThisEncoding = 'Invalid character in the given encoding.';
  SXmlInvalidCommentChars = 'An XML comment cannot contain ''--'', and ''-'' cannot be the last character.';
  SXmlInvalidNodeType = '''%s'' is an invalid XmlNodeType.';
  SXmlInvalidOperation = 'Operation is not valid due to the current state of the object.';
  SXmlInvalidPIName = '''%s'' is an invalid name for processing instructions.';
  SXmlInvalidRootData = 'Data at the root level is invalid.';
  SXmlInvalidTextDecl = 'Invalid text declaration.';
  SXmlInvalidVersionNumber = 'Version number ''%s'' is invalid.';
  SXmlInvalidXmlDecl = 'Syntax for an XML declaration is invalid.';
  SXmlInvalidXmlSpace = '''%s'' is an invalid xml:space value.';
  SXmlLimitExceeded = 'The input document has exceeded a limit set by %s.';
  SXmlMissingRoot = 'Root element is missing.';
  SXmlMultipleRoots = 'There are multiple root elements.';
  SXmlNamespaceDeclXmlXmlns = 'Prefix ''&s'' cannot be mapped to namespace name reserved for ''xml'' or ''xmlns''.';
  SXmlReadOnlyProperty = 'The ''%s'' property is read only and cannot be set.';
  SXmlTagMismatchEx = 'The ''%s'' start tag on line ''%s'' position ''%s'' does not match the end tag of ''%s''.';
  SXmlUnclosedQuote = 'There is an unclosed literal string.';
  SXmlUnexpectedEndTag = 'Unexpected end tag.';
  SXmlUnexpectedEOF = 'Unexpected end of file while parsing %s has occurred.';
  SXmlUnexpectedEOF1 = 'Unexpected end of file has occurred.';
  SXmlUnexpectedEOFInElementContent = 'Unexpected end of file has occurred. The following elements are not closed: %s';
  SXmlUnexpectedTokenEx = '''%s'' is an unexpected token. The expected token is ''%s''.';
  SXmlUnexpectedTokens2 = '''%s'' is an unexpected token. The expected token is ''%s'' or ''%s''.';
  SXmlUnknownNs = '''%s'' is an undeclared namespace.';
  SXmlXmlDeclNotFirst = 'Unexpected XML declaration. The XML declaration must be the first node in the document, ' +
    'and no white space characters are allowed to appear before it.';
  SXmlXmlnsPrefix = 'Prefix ''xmlns'' is reserved for use by XML.';
  SXmlXmlPrefix = 'Prefix ''xml'' is reserved for use by XML and can be mapped only to namespace name ' +
    '''http://www.w3.org/XML/1998/namespace''.';
{$ENDREGION}

type
  TACLXMLWhitespaceHandling = (
     All,         //# Return all Whitespace and SignificantWhitespace nodes. This is the default.
     Significant, //# Return just SignificantWhitespace, i.e. whitespace nodes that are in scope of xml:space="preserve"
     None         //# Do not return any Whitespace or SignificantWhitespace nodes.
  );

  { TEncodingHelper }

  TEncodingHelper = class helper for TEncoding
  public
    procedure Convert(
      const ABytes: TBytes; AByteIndex, AByteCount: Integer;
      const AChars: TCharArray; ACharIndex, ACharCount: Integer;
      out ABytesUsed, ACharsUsed: Integer); overload;
  end;

  { TACLXMLNamespaceManager }

  TACLXMLNamespaceManager = class
  protected const
    MinDeclsCountForHashTable = 16;
  protected type
  {$REGION 'private sub-types'}
    TNamespaceDeclaration = record
      Prefix: string;
      Uri: string;
      ScopeId: Integer;
      PreviousNsIndex: Integer;
      procedure &Set(const APrefix, AUri: string; AScopeId, APreviousNsIndex: Integer);
    end;
  {$ENDREGION}
  strict private
    FHashTable: TDictionary<string, Integer>;
    FLastDecl: Integer;
    FNameTable: TACLXMLNameTable;
    FNsdecls: TArray<TNamespaceDeclaration>;
    FScopeId: Integer;
    FUseHashTable: Boolean;
    FXml: string;
    FXmlNs: string;
  public
    constructor Create(ANameTable: TACLXMLNameTable);
    destructor Destroy; override;
    procedure AddNamespace(APrefix, AUri: string);
    function GetNamespaceDeclaration(AIdx: Integer; out APrefix: string; out AUri: string): Boolean;
    function HasNamespace(const APrefix: string): Boolean;
    function LookupNamespace(const APrefix: string): string;
    function LookupNamespaceDecl(const APrefix: string): Integer;
    function LookupPrefix(const AUri: string): string;
    function PopScope: Boolean;
    procedure PushScope; inline;
    procedure RemoveNamespace(const APrefix: string; const AUri: string);
  end;

  { TACLXMLNodeTextLoader }

  TACLXMLNodeTextLoader = class(TACLXMLNodeLoader)
  strict private
    FProc: TACLXMLTextLoader;
  public
    constructor Create(AProc: TACLXMLTextLoader); reintroduce;
    procedure OnText(AContext: TObject; AReader: TACLXMLReader); override;
  end;

{$REGION 'XML-Reader'}

  { TACLXMLTextReader }

  TACLXMLTextReader = class(TACLXMLReader)
  private const
    ApproxXmlDeclLength = 80;
    MaxAttrDuplWalkCount = 250;
    MaxByteSequenceLen = 6;
    MaxBytesToMove = 128;
    MaxUTF8EncodedCharByteCount = 6;
    MinWhitespaceLookahedCount = 4096;
    NodesInitialSize = 8;
    XmlDeclarationBeginning = '<?xml';
  private type
  {$REGION 'private sub-types'}
    TParsingFunction = (
      ElementContent,
      NoData,
      SwitchToInteractive,
      SwitchToInteractiveXmlDecl,
      DocumentContent,
      MoveToElementContent,
      PopElementContext,
      PopEmptyElementContext,
      ResetAttributesRootLevel,
      Error,
      Eof,
      ReaderClosed,
      EntityReference,
      InIncrementalRead,
      FragmentAttribute,
      ReportEndEntity,
      AfterResolveEntityInContent,
      AfterResolveEmptyEntityInContent,
      XmlDeclarationFragment,
      GoToEof,
      PartialTextValue,

      //# these two states must be last; see InAttributeValueIterator property
      InReadAttributeValue,
      InReadValueChunk,
      InReadContentAsBinary,
      InReadElementContentAsBinary
    );

    TParsingMode = (
      Full,
      SkipNode,
      SkipContent
    );

    TEntityType = (
      CharacterDec,
      CharacterHex,
      CharacterNamed,
      Expanded,
      Skipped,
      FakeExpanded,
      Unexpanded,
      ExpandedInAttribute
    );

    TEntityExpandType = (
      All,
      OnlyGeneral,
      OnlyCharacter
    );

    TXmlContext = class
    public
      XmlSpace: TACLXMLSpace;
      XmlLang: string;
      DefaultNamespace: string;
      PreviousContext: TXmlContext;
      constructor Create(APreviousContext: TXmlContext); overload;
    end;

    TParsingState = record
    public
      Chars: TCharArray;
      CharPos: Integer;
      CharsUsed: Integer;
      Encoding: TEncoding;
      AppendMode: Boolean;
      Stream: TStream;
      Decoder: TEncoding;
      Bytes: TBytes;
      BytePos: Integer;
      BytesUsed: Integer;
      LineNo: Integer;
      LineStartPos: Integer;
      IsEof: Boolean;
      IsStreamEof: Boolean;
      EolNormalized: Boolean;

      procedure Clear;
      function LinePos: Integer; inline;
    end;

  {$ENDREGION}
  private
    FXML: string;
    FXmlNs: string;

    //# parsing function = what to do in the next Read() (3-items-long stack, usually used just 2 level)
    FParsingFunction: TParsingFunction;
    FParsingState: TParsingState;

    FAttributeCount: Integer;
    FAttributeDuplicateWalkCount: Integer;
    FAttributeHashTable: Integer;
    FAttributeNeedNamespaceLookup: Boolean;
    FCurrentAttributeIndex: Integer;
    FFullAttributeCleanup: Boolean;
    FIndex: Integer;
    FNextParsingFunction: TParsingFunction;
    FNodes: TArray<TACLXMLNodeData>;

    //# settings
    FCheckCharacters: Boolean;
    FIgnoreComments: Boolean;
    FIgnoreProcessingInstructions: Boolean;
    FLineNumberOffset: Integer;
    FLinePositionOffset: Integer;
    FNormalize: Boolean;
    FSupportNamespaces: Boolean;
    FWhitespaceHandling: TACLXMLWhitespaceHandling;

    FAfterResetState: Boolean;
    FCharactersFromEntities: Int64;
    FCharactersInDocument: Int64;
    FDocumentStartBytePos: Integer;
    FFragment: Boolean;
    FFragmentType: TACLXMLNodeType;
    FLastPrefix: string;
    FMaxCharactersInDocument: Int64;
    FNamespaceManager: TACLXMLNamespaceManager;
    FParsingMode: TParsingMode;
    FReadValueOffset: Integer;
    FRootElementParsed: Boolean;
    FStandalone: Boolean;
    FStringBuilder: TACLStringBuilder;
    FXmlContext: TXmlContext;

    function DetectEncoding: TEncoding;

    function GetAttributeWithNamespace(const AName, ANamespaceURI: string): TACLXMLNodeData;
    function GetAttributeWithPrefix(const ALocalName, APrefix: string): TACLXMLNodeData; overload;
    function GetAttributeWithPrefix(const AName: string): TACLXMLNodeData; overload;
    function GetChars(AMaxCharsCount: Integer): Integer;
    function GetWhitespaceType: TACLXMLNodeType; inline;

    procedure InitStreamInput(AStream: TStream; const ABytes: TBytes; AByteCount: Integer; AEncoding: TEncoding);
    procedure InvalidCharRecovery(var ABytesCount: Integer; out ACharsCount: Integer);

    function AddAttribute(AEndNamePos, AColonPos: Integer): TACLXMLNodeData; overload;
    function AddAttribute(const ALocalName, APrefix: string; const ANameWPrefix: string): TACLXMLNodeData; overload;
    function AddAttributeNoChecks(const AName: string; AAttrDepth: Integer): TACLXMLNodeData;
    procedure AddNamespace(const APrefix, AUri: string; AAttribute: TACLXMLNodeData);
    function AddNode(ANodeIndex, ANodeDepth: Integer): TACLXMLNodeData;
    procedure AttributeDuplCheck;
    procedure AttributeNamespaceLookup;
    procedure ElementNamespaceLookup;

    procedure OnEof;
    procedure OnDefaultNamespaceDecl(AAttribute: TACLXMLNodeData);
    procedure OnNamespaceDecl(AAttribute: TACLXMLNodeData);
    procedure OnNewLine(APosition: Integer); inline;
    procedure OnXmlReservedAttribute(AAttribute: TACLXMLNodeData);

    procedure PopElementContext; inline;
    procedure PopXmlContext; inline;
    procedure PushXmlContext; inline;

    procedure ParseAttributeValueSlow(ACurPosition: Integer; AQuoteChar: Char; AAttribute: TACLXMLNodeData);
    function ParseCDataOrComment(AType: TACLXMLNodeType; out AOutStartPosition, AOutEndPosition: Integer): Boolean; overload;
    function ParseCharRefInline(AStartPosition: Integer; out ACharCount: Integer; out AEntityType: TEntityType): Integer;
    function ParseComment: Boolean;
    function ParseDocTypeDeclaraion: Boolean;
    function ParseDocumentContent: Boolean;
    function ParseElementContent: Boolean;
    function ParseName: Integer; inline;
    function ParseNamedCharRef(AExpand: Boolean; AInternalSubsetBuilder: TACLStringBuilder): Integer;
    function ParseNamedCharRefInline(AStartPosition: Integer; AExpand: Boolean; AInternalSubsetBuilder: TACLStringBuilder): Integer;
    function ParseNumericCharRef(AExpand: Boolean; AInternalSubsetBuilder: TACLStringBuilder; out AEntityType: TEntityType): Integer;
    function ParseNumericCharRefInline(AStartPosition: Integer; AExpand: Boolean; AInternalSubsetBuilder: TACLStringBuilder;
      out ACharCount: Integer; out AEntityType: TEntityType): Integer;
    function ParsePI(APiInDtdStringBuilder: TACLStringBuilder = nil): Boolean;
    function ParsePIValue(out AOutStartPosition, AOutEndPosition: Integer): Boolean;
    function ParseQName(AIsQName: Boolean; AStartOffset: Integer; out AColonPosition: Integer): Integer; overload;
    function ParseQName(out AColonPosition: Integer): Integer; overload;
    function ParseRootLevelWhitespace: Boolean;
    function ParseText: Boolean; overload;
    function ParseText(out AStartPosition, AEndPosition: Integer; var AOutOrChars: Integer): Boolean; overload;
    function ParseUnexpectedToken: string; overload;
    function ParseUnexpectedToken(APosition: Integer): string; overload;
    function ParseXmlDeclaration(AIsTextDecl: Boolean): Boolean;
    function ReadDataInName(var APosition: Integer): Boolean;
    procedure ParseAttributes;
    procedure ParseCData;
    procedure ParseCDataOrComment(AType: TACLXMLNodeType); overload;
    procedure ParseElement;
    procedure ParseEndElement;
    procedure ParseXmlDeclarationFragment;
    procedure SkipDtd;
    procedure SkipPartialTextValue;
    procedure SkipPublicOrSystemIdLiteral;
    procedure SkipUntil(AStopChar: Char; ARecognizeLiterals: Boolean);

    function HandleEntityReference(AIsInAttributeValue: Boolean;
      AExpandType: TEntityExpandType; out ACharRefEndPos: Integer): TEntityType;
    procedure ResetAttributes;
    procedure FullAttributeCleanup; inline;
    procedure FinishPartialValue;

    function ReadData: Integer;
    procedure RegisterConsumedCharacters(ACharacters: Int64);
    procedure SetupEncoding(AEncoding: TEncoding);
    procedure SwitchEncoding(ANewEncoding: TEncoding);
    procedure SwitchEncodingAfterResetState;
    procedure SwitchEncodingToUTF8;

    procedure ReThrow(E: Exception; ALineNo, ALinePos: Integer);
    procedure SetErrorState;
    procedure Throw(E: Exception); overload;
    procedure Throw(const ARes: string); overload;
    procedure Throw(const ARes, AArg: string); overload;
    procedure Throw(const ARes: string; const AArgs: array of const); overload;
    procedure Throw(const ARes: string; ALineNo, ALinePos: Integer); overload;
    procedure Throw(const ARes, AArg: string; ALineNo, ALinePos: Integer); overload;
    procedure Throw(APosition: Integer; const ARes, AArg: string); overload;
    procedure Throw(APosition: Integer; const ARes: string; const AArgs: array of const); overload;
    procedure Throw(APosition: Integer; const ARes: string; const AArgs: TArray<string>); overload;
    procedure ThrowExpectingWhitespace(APosition: Integer);
    procedure ThrowInvalidChar(const AData: TCharArray; ALength, AInvCharPos: Integer);
    procedure ThrowTagMismatch(AStartTag: TACLXMLNodeData);
    procedure ThrowUnexpectedToken(APosition: Integer; const AExpectedToken1: string; const AExpectedToken2: string = ''); overload;
    procedure ThrowUnexpectedToken(const AExpectedToken1: string; const AExpectedToken2: string = ''); overload;
    procedure ThrowUnclosedElements;
    procedure ThrowWithoutLineInfo(const ARes, AArg: string);

    function EatWhitespaces(ASb: TACLStringBuilder): Integer;
    procedure ShiftBuffer(ASourcePosition, ADestPosition, ACount: Integer); inline;
    procedure UnDecodeChars;
  protected
    function GetText: string; override;
  public
    constructor Create; overload;
    constructor Create(AStream: TStream; const ABytes: TBytes;
      AByteCount: Integer; const ASettings: TACLXMLReaderSettings); overload;
    constructor Create(const ASettings: TACLXMLReaderSettings); overload;
    destructor Destroy; override;
    function GetAttribute(const AAttribute, ANamespaceURI: string): string; overload; override;
    function TryGetAttribute(const AAttribute: string; out AValue: string): Boolean; override;
    function TryGetAttribute(const APrefix, ALocalName, ANamespaceURI: string; out AValue: string): Boolean; override;
    function LookupNamespace(const ANode: TACLXMLNodeData): string; overload;
    function LookupNamespace(const APrefix: string): string; overload; override;
    function MoveToElement: Boolean; override;
    function MoveToNextAttribute: Boolean; override;
    function Read: Boolean; override;
    //
    property XML: string read FXML;
    property XmlNs: string read FXmlNs;
  end;

{$ENDREGION}

function NotImplemented: Pointer;
begin
  raise ENotImplemented.Create('Not implemented');
end;

function IfThen(AValue: Boolean; const ATrue: Boolean; const AFalse: Boolean = False): Boolean; overload; inline;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

function GetRemainingUTF8EncodedCharacterByteCount(ABuffer: PByte; ABytesInBuffer: Integer): Integer;
begin
  if ABytesInBuffer = 0 then
    Exit(0);

  Inc(ABuffer, ABytesInBuffer - 1);

  if ABuffer^ and $80 = $00 then //# last byte is 0.......
    Exit(0);

  if ABytesInBuffer > 1 then
  begin
    if ABuffer^ and $E0 = $C0 then //# 110..... -> double char
      Exit(1);
    if ABuffer^ and $F0 = $E0 then //# 1110.... -> triple char
      Exit(2);
    if ABuffer^ and $F8 = $F0 then //# 11110... -> 4 char
      Exit(3);
    if ABuffer^ and $FC = $F8 then //# 111110.. -> 5 char
      Exit(4);
    if ABuffer^ and $FE = $FC then //# 1111110. -> 6 char
      Exit(5);
  end;
  if ABytesInBuffer > 2 then
  begin
    Dec(ABuffer);
    if ABuffer^ and $F0 = $E0 then //# 1110.... -> triple char
      Exit(1);
    if ABuffer^ and $F8 = $F0 then //# 11110... -> 4 char
      Exit(2);
    if ABuffer^ and $FC = $F8 then //# 111110.. -> 5 char
      Exit(3);
    if ABuffer^ and $FE = $FC then //# 1111110. -> 6 char
      Exit(4);
  end;
  if ABytesInBuffer > 3 then
  begin
    Dec(ABuffer);
    if ABuffer^ and $F8 = $F0 then //# 11110... -> 4 char
      Exit(1);
    if ABuffer^ and $FC = $F8 then //# 111110.. -> 5 char
      Exit(2);
    if ABuffer^ and $FE = $FC then //# 1111110. -> 6 char
      Exit(3);
  end;
  if ABytesInBuffer > 4 then
  begin
    Dec(ABuffer);
    if ABuffer^ and $FC = $F8 then //# 111110.. -> 5 char
      Exit(1);
    if ABuffer^ and $FE = $FC then //# 1111110. -> 6 char
      Exit(2);
  end;
  if ABytesInBuffer > 5 then
  begin
    Dec(ABuffer);
    if ABuffer^ and $FE = $FC then //# 1111110. -> 6 char
      Exit(1);
  end;
  Result := 0; //# ERROR ?
end;

function StrEqual(const AChars: TCharArray; AStrPos1, AStrLen1: Integer; const AStr2: string): Boolean; inline;
begin
  Result := (AStrLen1 = Length(AStr2)) and CompareMem(@AChars[AStrPos1], PChar(AStr2), AStrLen1 * SizeOf(Char));
end;

{ TEncodingHelper }

procedure TEncodingHelper.Convert(const ABytes: TBytes; AByteIndex, AByteCount: Integer;
  const AChars: TCharArray; ACharIndex, ACharCount: Integer; out ABytesUsed, ACharsUsed: Integer);
var
  ACharArray: TCharArray;
begin
  AByteCount := Min(AByteCount, GetMaxByteCount(ACharCount));
  if Self = UTF8 then //# special case
  begin
    while (AByteCount > 0) and (GetRemainingUTF8EncodedCharacterByteCount(@ABytes[AByteIndex], AByteCount) <> 0) do
      Dec(AByteCount);
  end
  else

    if Self is TMBCSEncoding then
    begin
      while (AByteCount > 0) and (UnicodeFromLocaleChars(TMBCSEncoding(Self).CodePage,
        MB_ERR_INVALID_CHARS, PAnsiChar(@ABytes[AByteIndex]), AByteCount, nil, 0) = 0)
      do
        Dec(AByteCount);
    end;

  ACharArray := GetChars(ABytes, AByteIndex, AByteCount);
  ACharsUsed := Min(Length(ACharArray), ACharCount);
  FastMove(ACharArray[0], AChars[ACharIndex], ACharsUsed * SizeOf(Char));
  ABytesUsed := GetByteCount(ACharArray, 0, ACharsUsed);
end;

{ TACLXMLReader }

function TACLXMLReader.GetAttribute(const AAttribute: AnsiString): string;
begin
  Result := GetAttribute(string(AAttribute));
end;

function TACLXMLReader.GetAttribute(const AAttribute: string): string;
begin
  if not TryGetAttribute(AAttribute, Result) then
    Result := acEmptyStr;
end;

function TACLXMLReader.GetAttributeAsBoolean(const AAttribute: AnsiString; const ADefaultValue: Boolean = False): Boolean;
begin
  Result := GetAttributeAsBoolean(string(AAttribute), ADefaultValue);
end;

function TACLXMLReader.GetAttribute(const APrefix, ALocalName, ANamespaceURI: string): string;
begin
  if not TryGetAttribute(APrefix, ALocalName, ANamespaceURI, Result) then
    Result := acEmptyStr;
end;

function TACLXMLReader.GetAttributeAsBoolean(const AAttribute: string; const ADefaultValue: Boolean = False): Boolean;
var
  AValue: string;
begin
  if TryGetAttribute(AAttribute, AValue) then
    Result := TACLXMLConvert.DecodeBoolean(AValue)
  else
    Result := ADefaultValue;
end;

function TACLXMLReader.GetAttributeAsInt64(const AAttribute: string; const ADefaultValue: Int64 = 0): Int64;
begin
  Result := StrToInt64Def(GetAttribute(AAttribute), ADefaultValue);
end;

function TACLXMLReader.GetAttributeAsInteger(const AAttribute: string; ADefaultValue: Integer = 0): Integer;
begin
  Result := StrToIntDef(GetAttribute(AAttribute), ADefaultValue);
end;

function TACLXMLReader.GetAttributeAsSingle(const AAttribute: string; ADefaultValue: Single = 0): Single;
begin
  Result := StrToFloatDef(GetAttribute(AAttribute), ADefaultValue, TFormatSettings.Invariant);
end;

function TACLXMLReader.GetDepth: Integer;
begin
  Result := FCurrentNode.Depth;
end;

function TACLXMLReader.IsEmptyElement: Boolean;
begin
  Result := FCurrentNode.IsEmptyElement;
end;

function TACLXMLReader.GetLocalName: string;
begin
  Result := FCurrentNode.LocalName;
end;

function TACLXMLReader.GetName: string;
begin
  Result := FCurrentNode.GetNameWPrefix(FNameTable);
end;

function TACLXMLReader.GetNamespaceURI: string;
begin
  Result := FCurrentNode.Namespace;
end;

function TACLXMLReader.GetNodeType: TACLXMLNodeType;
begin
  Result := FCurrentNode.&Type;
end;

function TACLXMLReader.GetPrefix: string;
begin
  Result := FCurrentNode.Prefix;
end;

function TACLXMLReader.GetValue: string;
begin
  Result := FCurrentNode.StringValue;
end;

function TACLXMLReader.SafeRead: Boolean;
begin
  try
    Result := Read;
  except
    Result := False;
  end;
end;

procedure TACLXMLReader.Skip;
var
  ADepth: Integer;
begin
  if ReadState <> TACLXMLReadState.Interactive then
    Exit;
  MoveToElement;
  if (NodeType = TACLXMLNodeType.Element) and not IsEmptyElement then
  begin
    ADepth := Depth;

    while Read and (ADepth < Depth) do
    begin
      //# Nothing, just read on
    end;
    //# consume end tag
    if NodeType = TACLXMLNodeType.EndElement then
      Read;
  end
  else
    Read;
end;

{ TACLXMLLineInfo }

procedure TACLXMLLineInfo.Init(ALineNo: Integer; ALinePos: Integer);
begin
  FLineNo := ALineNo;
  FLinePos := ALinePos;
end;

{ TACLXMLNodeData }

constructor TACLXMLNodeData.Create;
begin
  FValueLocation := TValueLocation.CharsBuffer;
  SetValueNode(TACLXMLNodeType.None, '');
  FXmlContextPushed := False;
end;

function TACLXMLNodeData.GetIsEmptyElement: Boolean;
begin
  Result := (FType = TACLXMLNodeType.Element) and FIsEmptyOrDefault;
end;

procedure TACLXMLNodeData.SetIsEmptyElement(AValue: Boolean);
begin
  Assert(FType = TACLXMLNodeType.Element);
  FIsEmptyOrDefault := AValue;
end;

function TACLXMLNodeData.GetIsDefaultAttribute: Boolean;
begin
  Result := (FType = TACLXMLNodeType.Attribute) and FIsEmptyOrDefault;
end;

procedure TACLXMLNodeData.SetIsDefaultAttribute(AValue: Boolean);
begin
  Assert(FType = TACLXMLNodeType.Attribute);
  FIsEmptyOrDefault := AValue;
end;

function TACLXMLNodeData.GetStringValue: string;
begin
  OnBufferInvalidated;
  Result := FValue;
end;

procedure TACLXMLNodeData.SetValueNode(AType: TACLXMLNodeType; const AValue: string);
begin
  FType := AType;
  FLocalName := '';
  FPrefix := '';
  FNamespace := '';
  FNameWPrefix := '';
  FValue := AValue;
  FValueLocation := TValueLocation.ValueString;
  FValueStartPos := -1;
end;

procedure TACLXMLNodeData.SetValueNode(AType: TACLXMLNodeType; const AChars: TCharArray; AStartPos, ALength: Integer);
begin
  FType := AType;
  FLocalName := '';
  FPrefix := '';
  FNamespace := '';
  FNameWPrefix := '';
  FValue := '';

  FChars := AChars;
  FValueLocation := TValueLocation.CharsBuffer;
  FValueStartPos := AStartPos;
  FValueLength := ALength;
end;

procedure TACLXMLNodeData.SetNamedNode(AType: TACLXMLNodeType; const ALocalName, APrefix, ANameWPrefix: string);
begin
  Assert(ALocalName <> '');

  FType := AType;
  FLocalName := ALocalName;
  FPrefix := APrefix;
  FNameWPrefix := ANameWPrefix;
  FNamespace := '';
  FValue := '';
  FValueLocation := TValueLocation.ValueString;
  FValueStartPos := -1;
end;

procedure TACLXMLNodeData.SetValue(const AValue: string);
begin
  FValueStartPos := -1;
  FValue := AValue;
  FValueLocation := TValueLocation.ValueString;
end;

procedure TACLXMLNodeData.SetValue(const AChars: TCharArray; AStartPos: Integer; ALength: Integer);
begin
  FValue := '';
  FValueLocation := TValueLocation.CharsBuffer;
  FChars := AChars;
  FValueStartPos := AStartPos;
  FValueLength := ALength;
end;

procedure TACLXMLNodeData.OnBufferInvalidated;
begin
  if FValueLocation = TValueLocation.CharsBuffer then
  begin
    Assert(FChars <> nil);
    SetString(FValue, PChar(@FChars[FValueStartPos]), FValueLength);
    FValueLocation := TValueLocation.ValueString;
  end;
  FValueStartPos := -1;
end;

function TACLXMLNodeData.GetNameWPrefix(ANameTable: TACLXMLNameTable): string;
begin
  if FNameWPrefix = '' then
  begin
    if FPrefix <> '' then
      FNameWPrefix := ANameTable.Add(FPrefix + ':' + FLocalName)
    else
      FNameWPrefix := FLocalName;
  end;
  Result := FNameWPrefix;
end;

procedure TACLXMLNodeData.CopyTo(AValueOffset: Integer; ASb: TACLStringBuilder);
begin
  if FValue = '' then
  begin
    Assert(FValueStartPos <> -1);
    Assert(FChars <> nil);
    ASb.Append(FChars, FValueStartPos + AValueOffset, FValueLength - AValueOffset);
  end
  else
    if AValueOffset > 0 then
      ASb.Append(FValue, AValueOffset, Length(FValue) - AValueOffset)
    else
      ASb.Append(FValue);
end;

{$REGION 'XML-Reader'}

{ TACLXMLReaderSettings }

class function TACLXMLReaderSettings.Default: TACLXMLReaderSettings;
begin
  Result.CheckCharacters := True;
  Result.ConformanceLevel := TACLXMLConformanceLevel.Document;
  Result.DefaultEncoding := nil;
  Result.IgnoreComments := False;
  Result.IgnoreProcessingInstructions := False;
  Result.IgnoreWhitespace := False;
  Result.LineNumberOffset := 0;
  Result.LinePositionOffset := 0;
  Result.MaxCharactersInDocument := 0;
  Result.SupportNamespaces := True;
end;

function TACLXMLReaderSettings.CreateReader(AInput: TStream): TACLXMLReader;
begin
  if AInput = nil then
    raise EACLXMLArgumentNullException.Create('input');
  Result := TACLXMLTextReader.Create(AInput, nil, 0, Self);
end;

{ TACLXMLNamespaceManager }

constructor TACLXMLNamespaceManager.Create(ANameTable: TACLXMLNameTable);
var
  AEmptyStr: string;
begin
  FLastDecl := 0;
  FNameTable := ANameTable;
  FXml := ANameTable.Add('xml');
  FXmlNs := ANameTable.Add('xmlns');

  SetLength(FNsdecls, 8);
  AEmptyStr := ANameTable.Add('');
  FNsdecls[0].&Set(AEmptyStr, AEmptyStr, -1, -1);
  FNsdecls[1].&Set(FXmlNs, ANameTable.Add(TACLXMLReservedNamespaces.XmlNs), -1, -1);
  FNsdecls[2].&Set(FXml, ANameTable.Add(TACLXMLReservedNamespaces.Xml), 0, -1);
  FLastDecl := 2;
  FScopeId := 1;
end;

destructor TACLXMLNamespaceManager.Destroy;
begin
  FHashTable.Free;
  inherited Destroy;
end;

procedure TACLXMLNamespaceManager.PushScope;
begin
  Inc(FScopeId);
end;

function TACLXMLNamespaceManager.PopScope: Boolean;
var
  ADecl: Integer;
begin
  ADecl := FLastDecl;
  if FScopeId = 1 then
    Exit(False);
  while FNsdecls[ADecl].ScopeId = FScopeId do
  begin
    if FUseHashTable then
      FHashTable[FNsdecls[ADecl].Prefix] := FNsdecls[ADecl].PreviousNsIndex;
    Dec(ADecl);
    Assert(ADecl >= 2);
  end;
  FLastDecl := ADecl;
  Dec(FScopeId);
  Result := True;
end;

procedure TACLXMLNamespaceManager.AddNamespace(APrefix, AUri: string);
var
  ADeclIndex, APreviousDeclIndex, I: Integer;
begin
  //# atomize prefix and URI
  APrefix := FNameTable.Add(APrefix);
  AUri := FNameTable.Add(AUri);
  if (Pointer(FXml) = Pointer(APrefix)) and (AUri <> TACLXMLReservedNamespaces.Xml) then
    raise EACLXMLArgumentException.Create(SXmlXmlPrefix);
  if Pointer(FXmlNs) = Pointer(APrefix) then
    raise EACLXMLArgumentException.Create(SXmlXmlnsPrefix);

  ADeclIndex := LookupNamespaceDecl(APrefix);
  APreviousDeclIndex := -1;
  if ADeclIndex <> -1 then
  begin
    if FNsdecls[ADeclIndex].ScopeId = FScopeId then
    begin
      //# redefine if in the same scope
      FNsdecls[ADeclIndex].Uri := AUri;
      Exit;
    end
    else
      //# otherwise link
      APreviousDeclIndex := ADeclIndex;
  end;
  //# set new namespace declaration
  if FLastDecl = Length(FNsdecls) - 1 then
    SetLength(FNsdecls, Length(FNsdecls) * 2);

  Inc(FLastDecl);
  FNsdecls[FLastDecl].&Set(APrefix, AUri, FScopeId, APreviousDeclIndex);
  //# add to HashTable
  if FUseHashTable then
    FHashTable.AddOrSetValue(APrefix, FLastDecl)
  else
    //# or create a new HashTable if the threshold has been reached
    if FLastDecl >= MinDeclsCountForHashTable then
    begin
      //# add all to hash table
      Assert(FHashTable = nil);
      FHashTable := TDictionary<string, Integer>.Create(FLastDecl);
      for I := 0 to FLastDecl do
        FHashTable.AddOrSetValue(FNsdecls[I].Prefix, I);
      FUseHashTable := True;
    end;
end;

procedure TACLXMLNamespaceManager.RemoveNamespace(const APrefix: string; const AUri: string);
var
  ADeclIndex: Integer;
begin
  if AUri = '' then
    raise EACLXMLArgumentException.Create('uri');
  if APrefix = '' then
    raise EACLXMLArgumentException.Create('prefix');

  ADeclIndex := LookupNamespaceDecl(APrefix);
  while ADeclIndex <> -1 do
  begin
    if (FNsdecls[ADeclIndex].ScopeId = FScopeId) and (FNsdecls[ADeclIndex].Uri = AUri) then
      FNsdecls[ADeclIndex].Uri := '';
    ADeclIndex := FNsdecls[ADeclIndex].PreviousNsIndex;
  end;
end;

function TACLXMLNamespaceManager.LookupNamespace(const APrefix: string): string;
var
  ADeclIndex: Integer;
begin
  ADeclIndex := LookupNamespaceDecl(APrefix);
  if (ADeclIndex = -1) then
    Result := ''
  else
    Result := FNsdecls[ADeclIndex].Uri;
end;

function TACLXMLNamespaceManager.LookupNamespaceDecl(const APrefix: string): Integer;
var
  ADeclIndex, AThisDecl: Integer;
begin
  if FUseHashTable then
  begin
    if FHashTable.TryGetValue(APrefix, ADeclIndex) then
    begin
      while (ADeclIndex <> -1) and (FNsdecls[ADeclIndex].Uri = '') do
        ADeclIndex := FNsdecls[ADeclIndex].PreviousNsIndex;
      Exit(ADeclIndex);
    end;
  end
  else
  begin
    //# First assume that prefix is atomized
    AThisDecl := FLastDecl;
    while AThisDecl >= 0 do
    begin
      if (Pointer(FNsdecls[AThisDecl].Prefix) = Pointer(APrefix)) and (FNsdecls[AThisDecl].Uri <> '') then
        Exit(AThisDecl);
      Dec(AThisDecl);
    end;
    //# Non-atomized lookup
    AThisDecl := FLastDecl;
    while AThisDecl >= 0 do
    begin
      if (FNsdecls[AThisDecl].Uri <> '') and (FNsdecls[AThisDecl].Prefix = APrefix) then
        Exit(AThisDecl);
      Dec(AThisDecl);
    end;
  end;
  Result := -1;
end;

function TACLXMLNamespaceManager.LookupPrefix(const AUri: string): string;
var
  AThisDecl: Integer;
begin
  //# Don't assume that prefix is atomized
  AThisDecl := FLastDecl;
  while AThisDecl >= 0 do
  begin
    if FNsdecls[AThisDecl].Uri = AUri then
    begin
      Result := FNsdecls[AThisDecl].Prefix;
      if LookupNamespace(Result) = AUri then
        Exit;
    end;
    Dec(AThisDecl);
  end;
  Result := '';
end;

function TACLXMLNamespaceManager.HasNamespace(const APrefix: string): Boolean;
var
  AThisDecl: Integer;
begin
  //# Don't assume that prefix is atomized
  AThisDecl := FLastDecl;
  while FNsdecls[AThisDecl].ScopeId = FScopeId do
  begin
    if (FNsdecls[AThisDecl].Uri <> '') and (FNsdecls[AThisDecl].Prefix = APrefix) then
    begin
      if (APrefix <> '') or (FNsdecls[AThisDecl].Uri <> '') then
        Exit(True)
      else
        Exit(False);
    end;
    Dec(AThisDecl);
  end;
  Result := False;
end;

function TACLXMLNamespaceManager.GetNamespaceDeclaration(AIdx: Integer; out APrefix: string; out AUri: string): Boolean;
begin
  AIdx := FLastDecl - AIdx;
  if AIdx < 0 then
  begin
    APrefix := '';
    AUri := '';
    Exit(False);
  end;

  APrefix := FNsdecls[AIdx].Prefix;
  AUri := FNsdecls[AIdx].Uri;

  Result := True;
end;

{ TACLXMLNamespaceManager.TNamespaceDeclaration }

procedure TACLXMLNamespaceManager.TNamespaceDeclaration.&Set(const APrefix, AUri: string; AScopeId, APreviousNsIndex: Integer);
begin
  Prefix := APrefix;
  Uri := AUri;
  ScopeId := AScopeId;
  PreviousNsIndex := APreviousNsIndex;
end;

{ TACLXMLTextReader }

constructor TACLXMLTextReader.Create;
begin
  inherited Create;
  FCurrentAttributeIndex := -1;
  FSupportNamespaces := True;
  FFragmentType := TACLXMLNodeType.Document;
end;

constructor TACLXMLTextReader.Create(AStream: TStream;
  const ABytes: TBytes; AByteCount: Integer;
  const ASettings: TACLXMLReaderSettings);
begin
  Create(ASettings);
  InitStreamInput(AStream, ABytes, AByteCount, ASettings.DefaultEncoding);
end;

constructor TACLXMLTextReader.Create(const ASettings: TACLXMLReaderSettings);
begin
  Create;
  FXmlContext := TXmlContext.Create;
  FStringBuilder := TACLStringBuilder.Create;

  FNameTable := TACLXMLNameTable.Create;
  FNamespaceManager := TACLXMLNamespaceManager.Create(FNameTable);
  FNameTable.Add('');
  FXml := FNameTable.Add('xml');
  FXmlNs := FNameTable.Add('xmlns');

  Assert(FIndex = 0);

  SetLength(FNodes, NodesInitialSize);
  FNodes[0] := TACLXMLNodeData.Create;
  FCurrentNode := FNodes[0];

  if ASettings.IgnoreWhitespace then
    FWhitespaceHandling := TACLXMLWhitespaceHandling.Significant
  else
    FWhitespaceHandling := TACLXMLWhitespaceHandling.All;

  FNormalize := True;
  FIgnoreProcessingInstructions := ASettings.IgnoreProcessingInstructions;
  FIgnoreComments := ASettings.IgnoreComments;
  FCheckCharacters := ASettings.CheckCharacters;
  FLineNumberOffset := ASettings.LineNumberOffset;
  FLinePositionOffset := ASettings.LinePositionOffset;
  FParsingState.LineNo := FLineNumberOffset + 1;
  FParsingState.LineStartPos := -FLinePositionOffset - 1;
  FCurrentNode.LineInfo.Init(FParsingState.LineNo - 1, FParsingState.LinePos - 1);
  FMaxCharactersInDocument := ASettings.MaxCharactersInDocument;
  FSupportNamespaces := ASettings.SupportNamespaces;

  FCharactersInDocument := 0;
  FCharactersFromEntities := 0;

  FParsingFunction := TParsingFunction.SwitchToInteractiveXmlDecl;
  FNextParsingFunction := TParsingFunction.DocumentContent;

  case ASettings.ConformanceLevel of
    TACLXMLConformanceLevel.Auto:
      begin
        FFragmentType := TACLXMLNodeType.None;
        FFragment := True;
      end;
    TACLXMLConformanceLevel.Fragment:
      begin
        FFragmentType := TACLXMLNodeType.Element;
        FFragment := True;
      end;
    TACLXMLConformanceLevel.Document:
      FFragmentType := TACLXMLNodeType.Document;
    else
    begin
      Assert(False);
      FFragmentType := TACLXMLNodeType.Document; //# goto case TACLXMLConformanceLevel.Document;
    end;
  end;
end;

destructor TACLXMLTextReader.Destroy;
var
  AXmlContext: TXmlContext;
begin
  while FXmlContext <> nil do
  begin
    AXmlContext := FXmlContext.PreviousContext;
    FXmlContext.Free;
    FXmlContext := AXmlContext;
  end;
  for var I := 0 to Length(FNodes) - 1 do
    FNodes[I].Free;
  FreeAndNil(FStringBuilder);
  FreeAndNil(FNamespaceManager);
  FreeAndNil(FNameTable);
  inherited Destroy;
end;

function TACLXMLTextReader.DetectEncoding: TEncoding;
var
  AFirst2Bytes, ANext2Bytes: Integer;
begin
  Assert(FParsingState.Bytes <> nil);
  Assert(FParsingState.BytePos = 0);

  if FParsingState.BytesUsed < 2 then
    Exit(nil);
  AFirst2Bytes := (FParsingState.Bytes[0] shl 8) or (FParsingState.Bytes[1]);
  if (FParsingState.BytesUsed >= 4) then
    ANext2Bytes := ((FParsingState.Bytes[2] shl 8) or (FParsingState.Bytes[3]))
  else
    ANext2Bytes := 0;

  case AFirst2Bytes of
    $0000:
      case ANext2Bytes of
        $FEFF, $003C, $FFFE, $3C00:
          Exit(NotImplemented);
//#        $FEFF:
//#          Exit(Ucs4Encoding.UCS4_BigEndian);
//#        $003C:
//#          Exit(Ucs4Encoding.UCS4_BigEndian);
//#        $FFFE:
//#          Exit(Ucs4Encoding.UCS4_2143);
//#        $3C00:
//#          Exit(Ucs4Encoding.UCS4_2143);
      end;
    $FEFF:
      if ANext2Bytes = $0000 then
        Exit(NotImplemented)  //#(Ucs4Encoding.UCS4_3412);
      else
        Exit(NotImplemented); //#(TEncoding.BigEndianUnicode);
    $FFFE:
      if ANext2Bytes = $0000 then
        Exit(NotImplemented) //#(Ucs4Encoding.UCS4_LittleEndian);
      else
        Exit(TEncoding.Unicode);
    $3C00:
      if ANext2Bytes = $0000 then
        Exit(NotImplemented) //#(Ucs4Encoding.UCS4_LittleEndian);
      else
        Exit(TEncoding.Unicode);
    $003C:
      if ANext2Bytes = $0000 then
        Exit(NotImplemented) //#(Ucs4Encoding.UCS4_3412);
      else
        Exit(TEncoding.BigEndianUnicode);
    $4C6F:
      if ANext2Bytes = $A794 then
        Throw('UnknownEncoding: ebcdic');
    $EFBB:
      if (ANext2Bytes and $FF00) = $BF00 then
        Exit(TEncoding.UTF8);
  end;
  Result := nil;
end;

//# When in ParsingState.PartialTextValue, this method parses and caches the rest of the value and stores it in curNode.
procedure TACLXMLTextReader.FinishPartialValue;
var
  AStartPos, AEndPos, AOrChars: Integer;
begin
  Assert(FStringBuilder.Length = 0);
  Assert(FParsingFunction = TParsingFunction.PartialTextValue);

  FCurrentNode.CopyTo(FReadValueOffset, FStringBuilder);

  AOrChars := 0;
  while not ParseText(AStartPos, AEndPos, AOrChars) do
    FStringBuilder.Append(FParsingState.Chars, AStartPos, AEndPos - AStartPos);
  FStringBuilder.Append(FParsingState.Chars, AStartPos, AEndPos - AStartPos);

  Assert(FStringBuilder.Length > 0);
  FCurrentNode.SetValue(FStringBuilder.ToString);
  FStringBuilder.Length := 0;
end;

procedure TACLXMLTextReader.FullAttributeCleanup;
var
  I: Integer;
begin
  for I := FIndex + 1 to FIndex + FAttributeCount do
    FNodes[I].IsDefaultAttribute := False;
  FFullAttributeCleanup := False;
end;

function TACLXMLTextReader.GetAttribute(const AAttribute, ANamespaceURI: string): string;
var
  ALocalName: string;
  ANamespace: string;
  ANode: TACLXMLNodeData;
  I: Integer;
begin
  ANamespace := FNameTable.Get(ANamespaceURI);
  ALocalName := FNameTable.Get(AAttribute);
  for I := FIndex + 1 to FIndex + FAttributeCount do
  begin
    ANode := FNodes[I];
    if (Pointer(ANode.LocalName) = Pointer(ALocalName)) and
       (Pointer(ANode.Namespace) = Pointer(ANamespace))
    then
      Exit(ANode.StringValue);
  end;
  Result := '';
end;

function TACLXMLTextReader.TryGetAttribute(const AAttribute: string; out AValue: string): Boolean;
var
  AAttrData: TACLXMLNodeData;
begin
  if acPos(':', AAttribute) > 0 then
    AAttrData := GetAttributeWithPrefix(AAttribute)
  else
    AAttrData := GetAttributeWithPrefix(AAttribute, '');

  Result := AAttrData <> nil;
  if Result then
    AValue := AAttrData.StringValue;
end;

function TACLXMLTextReader.TryGetAttribute(const APrefix, ALocalName, ANamespaceURI: string; out AValue: string): Boolean;
var
  AAttrData: TACLXMLNodeData;
begin
  if ANamespaceURI <> '' then
    AAttrData := GetAttributeWithNamespace(ALocalName, ANamespaceURI)
  else
    AAttrData := GetAttributeWithPrefix(ALocalName, APrefix);

  Result := AAttrData <> nil;
  if Result then
    AValue := AAttrData.StringValue;
end;

//# Stream input only: read bytes from stream and decodes them according to the current encoding
function TACLXMLTextReader.GetChars(AMaxCharsCount: Integer): Integer;
var
  ABytesCount, ACharsCount: Integer;
begin
  Assert((FParsingState.Stream <> nil) and (FParsingState.Decoder <> nil) and (FParsingState.Bytes <> nil));
  Assert(AMaxCharsCount <= Length(FParsingState.Chars) - FParsingState.CharsUsed - 1);

//# determine the maximum number of Bytes we can pass to the Decoder
  ABytesCount := FParsingState.BytesUsed - FParsingState.BytePos;
  if ABytesCount = 0 then
    Exit(0);
  try
    FParsingState.Decoder.Convert(FParsingState.Bytes, FParsingState.BytePos, ABytesCount,
      FParsingState.Chars, FParsingState.CharsUsed, AMaxCharsCount,
      ABytesCount, ACharsCount);
  except
//#catch ( ArgumentException ) {
    InvalidCharRecovery(ABytesCount, ACharsCount);
  end;
//# move pointers and return
  Inc(FParsingState.BytePos, ABytesCount);
  Inc(FParsingState.CharsUsed, ACharsCount);
  Assert(AMaxCharsCount >= ACharsCount);
  Result := ACharsCount;
end;

function TACLXMLTextReader.GetAttributeWithNamespace(const AName, ANamespaceURI: string): TACLXMLNodeData;
var
  ALocalName: string;
  ANamespace: string;
  ANode: TACLXMLNodeData;
begin
  ANamespace := FNameTable.Get(ANamespaceURI);
  ALocalName := FNameTable.Get(AName);
  for var I := FIndex + 1 to FIndex + FAttributeCount do
  begin
    ANode := FNodes[I];
    if (Pointer(ANode.LocalName) = Pointer(ALocalName)) and
       (Pointer(ANode.Namespace) = Pointer(ANamespace))
    then
      Exit(ANode);
  end;
  Result := nil;
end;

function TACLXMLTextReader.GetAttributeWithPrefix(const AName: string): TACLXMLNodeData;
var
  ANameValue: string;
  ANode: TACLXMLNodeData;
begin
  ANameValue := FNameTable.Add(AName);
  if ANameValue = '' then
    Exit(nil);
  for var I := FIndex + 1 to FIndex + FAttributeCount do
  begin
    ANode := FNodes[I];
    if (ANode.GetNameWPrefix(FNameTable) = ANameValue) then
      Exit(ANode);
  end;
  Result := nil;
end;

function TACLXMLTextReader.GetAttributeWithPrefix(const ALocalName, APrefix: string): TACLXMLNodeData;
var
  ANameValue: string;
  ANode: TACLXMLNodeData;
  APrefixValue: string;
begin
  ANameValue := FNameTable.Add(ALocalName);
  if ANameValue = '' then
    Exit(nil);
  APrefixValue := FNameTable.Add(APrefix);
  for var I := FIndex + 1 to FIndex + FAttributeCount do
  begin
    ANode := FNodes[I];
    if (Pointer(ANode.LocalName) = Pointer(ANameValue)) and
       (Pointer(ANode.Prefix) = Pointer(APrefixValue))
    then
      Exit(ANode);
  end;
  Result := nil;
end;

procedure TACLXMLTextReader.InitStreamInput(AStream: TStream;
  const ABytes: TBytes; AByteCount: Integer; AEncoding: TEncoding);
var
  ABufferSize, ARead, APreambleLen, I: Integer;
  APreamble: TBytes;
begin
//#  Debug.Assert(((FPs.CharPos = 0) and (FPs.CharsUsed = 0)) and (FPs.textReader = nil));
//#  Debug.Assert(ABaseUriStr <> nil);
//#  Debug.Assert((ABaseUri = nil) or ((ABaseUri.ToString.Equals(ABaseUriStr))));
//#
  FParsingState.Stream := AStream;
//#  take over the byte buffer allocated in XmlReader.Create, if available
  if ABytes <> nil then
  begin
    FParsingState.Bytes := ABytes;
    FParsingState.BytesUsed := AByteCount;
    ABufferSize := Length(FParsingState.Bytes);
  end
  else
  begin
    ABufferSize := DefaultBufferSize;
    if (FParsingState.Bytes = nil) or (Length(FParsingState.Bytes) < ABufferSize) then
      SetLength(FParsingState.Bytes, ABufferSize);
  end;

  if (FParsingState.Chars = nil) or (Length(FParsingState.Chars) < ABufferSize + 1) then
    SetLength(FParsingState.Chars, ABufferSize + 1);

  FParsingState.BytePos := 0;
  while (FParsingState.BytesUsed < 4) and (Length(FParsingState.Bytes) > FParsingState.BytesUsed) do
  begin
    ARead := AStream.Read(FParsingState.Bytes[FParsingState.BytesUsed], Length(FParsingState.Bytes) - FParsingState.BytesUsed);
    if ARead = 0 then
    begin
      FParsingState.IsStreamEof := True;
      Break;
    end;
    FParsingState.BytesUsed := FParsingState.BytesUsed + ARead;
  end;
  //# detect & setup encoding
  if AEncoding = nil then
    AEncoding := DetectEncoding;
  SetupEncoding(AEncoding);
  //# eat preamble
  APreamble := FParsingState.Encoding.GetPreamble;
  APreambleLen := Length(APreamble);
  I := 0;
  while (I < APreambleLen) and (I < FParsingState.BytesUsed) do
  begin
    if FParsingState.Bytes[I] <> APreamble[I] then
      Break;
    Inc(I);
  end;
  if I = APreambleLen then
    FParsingState.BytePos := APreambleLen;

  FDocumentStartBytePos := FParsingState.BytePos;

  FParsingState.EolNormalized := not FNormalize;

  FParsingState.AppendMode := True;
  ReadData;
end;

procedure TACLXMLTextReader.InvalidCharRecovery(var ABytesCount: Integer; out ACharsCount: Integer);
var
  ACharsDecoded, ABytesDecoded, AChDec, ABDec: Integer;
begin
  ACharsDecoded := 0;
  ABytesDecoded := 0;
  try
    while ABytesDecoded < ABytesCount do
    begin
    //#ps.decoder.Convert( ps.bytes, ps.bytePos + bytesDecoded, 1, ps.chars, ps.charsUsed + charsDecoded, 1, false, out bDec, out chDec, out completed );
      FParsingState.Decoder.Convert(FParsingState.Bytes, FParsingState.BytePos + ABytesDecoded, 1,
        FParsingState.Chars, FParsingState.CharsUsed + ACharsDecoded, 1, ABDec, AChDec);
      Inc(ACharsDecoded, AChDec);
      Inc(ABytesDecoded, ABDec);
    end;
    Assert(False, 'We should get an exception again.');
  except
  end;

  if ACharsDecoded = 0 then
    Throw(FParsingState.CharsUsed, SXmlInvalidCharInThisEncoding, '');
  ACharsCount := ACharsDecoded;
  ABytesCount := ABytesDecoded;
end;

function TACLXMLTextReader.LookupNamespace(const APrefix: string): string;
begin
  if FSupportNamespaces then
    Result := FNamespaceManager.LookupNamespace(APrefix)
  else
    Result := '';
end;

function TACLXMLTextReader.MoveToElement: Boolean;
begin
  if FCurrentNode.&Type <> TACLXMLNodeType.Attribute then
    Exit(False);
  FCurrentAttributeIndex := -1;
  FCurrentNode := FNodes[FIndex];

  Result := True;
end;

function TACLXMLTextReader.MoveToNextAttribute: Boolean;
begin
  if FCurrentAttributeIndex + 1 < FAttributeCount then
  begin
    Inc(FCurrentAttributeIndex);
    FCurrentNode := FNodes[FIndex + 1 + FCurrentAttributeIndex];
    Result := True;
  end
  else
    Result := False;
end;

procedure TACLXMLTextReader.OnEof;
begin
  Assert(FParsingState.IsEof);
  FCurrentNode := FNodes[0];
  FCurrentNode.SetValueNode(TACLXMLNodeType.None, acEmptyStr);
  FCurrentNode.LineInfo.Init(FParsingState.LineNo, FParsingState.LinePos);

  FParsingFunction := TParsingFunction.Eof;
  FReadState := TACLXMLReadState.EndOfFile;
end;

procedure TACLXMLTextReader.ParseCData;
begin
  ParseCDataOrComment(TACLXMLNodeType.CDATA);
end;

//# Parses CDATA section or comment
procedure TACLXMLTextReader.ParseCDataOrComment(AType: TACLXMLNodeType);
var
  AStartPos, AEndPos: Integer;
begin
  if FParsingMode = TParsingMode.Full then
  begin
    FCurrentNode.LineInfo.Init(FParsingState.LineNo, FParsingState.LinePos);
    Assert(FStringBuilder.Length = 0);
    if ParseCDataOrComment(AType, AStartPos, AEndPos) then
      FCurrentNode.SetValueNode(AType, FParsingState.Chars, AStartPos, AEndPos - AStartPos)
    else
    begin
      repeat
        FStringBuilder.Append(FParsingState.Chars, AStartPos, AEndPos - AStartPos);
      until ParseCDataOrComment(AType, AStartPos, AEndPos);
      FStringBuilder.Append(FParsingState.Chars, AStartPos, AEndPos - AStartPos);
      FCurrentNode.SetValueNode(AType, FStringBuilder.ToString);
      FStringBuilder.Length := 0;
    end;
  end
  else
    while not ParseCDataOrComment(AType, AStartPos, AEndPos) do ;
end;

//# Parses a chunk of CDATA section or comment. Returns true when the end of CDATA or comment was reached.
function TACLXMLTextReader.ParseCDataOrComment(AType: TACLXMLNodeType; out AOutStartPosition, AOutEndPosition: Integer): Boolean;
label
  ReturnPartial;
var
  APosition, ARcount, ARpos: Integer;
  AChars: TCharArray;
  AStopChar, ACh: Char;
begin
  if FParsingState.CharsUsed - FParsingState.CharPos < 3 then
  begin
    //# read new characters into the buffer
    if ReadData = 0 then
      Throw(SXmlUnexpectedEOF, IfThen(AType = TACLXMLNodeType.Comment, 'Comment', 'CDATA'));
  end;

  APosition := FParsingState.CharPos;
  AChars := FParsingState.Chars;
  ARcount := 0;
  ARpos := -1;
  if AType = TACLXMLNodeType.Comment then
    AStopChar := '-'
  else
    AStopChar := ']';

  while True do
  begin
    //# C# unsafe section
    ACh := AChars[APosition];
    while (ACh <> AStopChar) and ((TACLXMLCharType.CharProperties[ACh] and TACLXMLCharType.Text) <> 0) do
    begin
      Inc(APosition);
      ACh := AChars[APosition];
    end;

    if AChars[APosition] = AStopChar then
    begin
      //# possibly end of comment or cdata section
      if AChars[APosition + 1] = AStopChar then
      begin
        if AChars[APosition + 2] = '>' then
        begin
          if ARcount > 0 then
          begin
            Assert(not FParsingState.EolNormalized);
            ShiftBuffer(ARpos + ARcount, ARpos, APosition - ARpos - ARcount);
            AOutEndPosition := APosition - ARcount;
          end
          else
            AOutEndPosition := APosition;
          AOutStartPosition := FParsingState.CharPos;
          FParsingState.CharPos := APosition + 3;
          Exit(True);
        end
        else
          if APosition + 2 = FParsingState.CharsUsed then
            goto ReturnPartial
          else
            if AType = TACLXMLNodeType.Comment then
              Throw(APosition, SXmlInvalidCommentChars, '');
      end
      else
        if APosition + 1 = FParsingState.CharsUsed then
          goto ReturnPartial;
      Inc(APosition);
      Continue;
    end
    else
    begin
      case AChars[APosition] of
        #$000A:
          begin
            Inc(APosition);
            OnNewLine(APosition);
            Continue;
          end;
        #$000D:
          begin
            if AChars[APosition + 1] = #$000A then
            begin
              //# EOL normalization of 0xD 0xA - shift the buffer
              if not FParsingState.EolNormalized and (FParsingMode = TParsingMode.Full) then
              begin
                if APosition - FParsingState.CharPos > 0 then
                begin
                  if ARcount = 0 then
                  begin
                    ARcount := 1;
                    ARpos := APosition;
                  end
                  else
                  begin
                    ShiftBuffer(ARpos + ARcount, ARpos, APosition - ARpos - ARcount);
                    ARpos := APosition - ARcount;
                    Inc(ARcount);
                  end;
                end
                else
                  Inc(FParsingState.CharPos);
              end;
              Inc(APosition, 2);
            end
            else
              if (APosition + 1 < FParsingState.CharsUsed) or FParsingState.IsEof then
              begin
                if not FParsingState.EolNormalized then
                  AChars[APosition] := #$000A; //# EOL normalization of 0xD
                Inc(APosition);
              end
              else
                goto ReturnPartial;
            OnNewLine(APosition);
            Continue;
          end;
        '<', '&', ']', #$0009:
          begin
            Inc(APosition);
            Continue;
          end
        else
        begin
          //# end of buffer
          if APosition = FParsingState.CharsUsed then
            goto ReturnPartial;
          //# surrogate characters
          ACh := AChars[APosition];
          if TACLXMLCharType.IsHighSurrogate(ACh) then
          begin
            if APosition + 1 = FParsingState.CharsUsed then
              goto ReturnPartial;
            Inc(APosition);
            if TACLXMLCharType.IsLowSurrogate(AChars[APosition]) then
            begin
              Inc(APosition);
              Continue;
            end;
          end;
          if FCheckCharacters then
            ThrowInvalidChar(AChars, FParsingState.CharsUsed, APosition)
          else
          begin
            Inc(APosition);
            Continue;
          end;
        end;
      end;
    end;

ReturnPartial:
    if ARcount > 0 then
    begin
      ShiftBuffer(ARpos + ARcount, ARpos, APosition - ARpos - ARcount);
      AOutEndPosition := APosition - ARcount;
    end
    else
      AOutEndPosition := APosition;

    AOutStartPosition := FParsingState.CharPos;
    FParsingState.CharPos := APosition;
    Exit(False); //# false == parsing of comment or CData section is not finished yet, must be called again
  end;
end;

function TACLXMLTextReader.ParseComment: Boolean;
var
  AOldParsingMode: TParsingMode;
begin
  if FIgnoreComments then
  begin
    AOldParsingMode := FParsingMode;
    FParsingMode := TParsingMode.SkipNode;
    ParseCDataOrComment(TACLXMLNodeType.Comment);
    FParsingMode := AOldParsingMode;
    Result := False;
  end
  else
  begin
    ParseCDataOrComment(TACLXMLNodeType.Comment);
    Result := True;
  end;
end;

function TACLXMLTextReader.ParseDoctypeDeclaraion: Boolean;
begin
  while FParsingState.CharsUsed - FParsingState.CharPos < 8 do
  begin
    if ReadData = 0 then
      Throw(SXmlUnexpectedEOF, 'DOCTYPE');
  end;

  if not StrEqual(FParsingState.Chars, FParsingState.CharPos, 7, 'DOCTYPE') then
    ThrowUnexpectedToken(IfThen(FRootElementParsed, '<!--', 'DOCTYPE'));

  if not TACLXMLCharType.IsWhiteSpace(FParsingState.Chars[FParsingState.CharPos + 7]) then
    ThrowExpectingWhitespace(FParsingState.CharPos + 7);

  if FRootElementParsed then
    Throw(FParsingState.CharPos - 2, SXmlBadDTDLocation, '');

  Inc(FParsingState.CharPos, 8);
  EatWhitespaces(nil);
  //if (dtdProcessing == DtdProcessing.Parse) {
  //} else
  SkipDtd;
  Result := False;
end;

function TACLXMLTextReader.ParseDocumentContent: Boolean;
label
  LblReadData;
var
  AChars: TCharArray;
  AMangoQuirks, ANeedMoreChars: Boolean;
  APosition: Integer;
begin
  AMangoQuirks := False;
  while True do
  begin
    ANeedMoreChars := False;
    APosition := FParsingState.CharPos;
    AChars := FParsingState.Chars;

    if AChars[APosition] = '<' then
    begin
      ANeedMoreChars := True;
      if FParsingState.CharsUsed - APosition < 4 then
        goto LblReadData;
      Inc(APosition);
      case AChars[APosition] of
        '?':
          begin
            FParsingState.CharPos := APosition + 1;
            if ParsePI then
              Exit(True);
            Continue;
          end;
        '!':
          begin
            Inc(APosition);
            if FParsingState.CharsUsed - APosition < 2 then
              goto LblReadData;

            if AChars[APosition] = '-' then
            begin
              if AChars[APosition + 1] = '-' then
              begin
                FParsingState.CharPos := APosition + 2;
                if ParseComment then
                  Exit(True);
                Continue;
              end
              else
                ThrowUnexpectedToken(APosition + 1, '-');
            end
            else
              if AChars[APosition] = '[' then
              begin
                if FFragmentType <> TACLXMLNodeType.Document then
                begin
                  Inc(APosition);
                  if FParsingState.CharsUsed - APosition < 6 then
                    goto LblReadData;
                  if StrEqual(AChars, APosition, 6, 'CDATA[') then
                  begin
                    FParsingState.CharPos := APosition + 6;
                    ParseCData;
                    if FFragmentType = TACLXMLNodeType.None then
                      FFragmentType := TACLXMLNodeType.Element;
                    Exit(True);
                  end
                  else
                    ThrowUnexpectedToken(APosition, 'CDATA[');
                end
                else
                  Throw(FParsingState.CharPos, 'InvalidRootData', '');
              end
              else
              begin
                FParsingState.CharPos := APosition;
                if ParseDocTypeDeclaraion then
                  Exit(True);
                Continue;
              end;
          end;

        '/':
          Throw(APosition + 1, SXmlUnexpectedEndTag, '');
        else
          begin
          //# document element start tag
            if FRootElementParsed then
            begin
              if FFragmentType = TACLXMLNodeType.Document then
                Throw(APosition, SXmlMultipleRoots, '');
              if FFragmentType = TACLXMLNodeType.None then
                FFragmentType := TACLXMLNodeType.Element;
            end;
            FParsingState.CharPos := APosition;
            FRootElementParsed := True;
            ParseElement;
            Exit(True);
          end;
      end;
    end
    else

      if AChars[APosition] = '&' then
      begin
//        if FFragmentType = TACLXMLNodeType.Document then
          Throw(SXmlInvalidRootData)
//        else
//        begin
//          if FFragmentType = TACLXMLNodeType.None then
//            FFragmentType := TACLXMLNodeType.Element;
//          case HandleEntityReference(False, TEntityExpandType.OnlyGeneral, ACharRefPos) of
//            TEntityType.Unexpanded:
//              Throw(SXmlEntityReferencesNotImplemented);
//            TEntityType.CharacterDec, TEntityType.CharacterHex, TEntityType.CharacterNamed:
//              if ParseText then
//                Exit(True);
//          else
//            Inc(FParsingState.CharPos); // +1 т.к. EntityReferencesNotImplemented
//          end;
//          Continue;
//        end;
      end
      else

        if (APosition = FParsingState.CharsUsed) or (AMangoQuirks and (AChars[APosition] = #0)) then
          goto LblReadData
        else
        //# something else -> root level whitespaces
        begin
          if FFragmentType = TACLXMLNodeType.Document then
          begin
            if ParseRootLevelWhitespace then
              Exit(True);
          end
          else
          begin
            if ParseText then
            begin
              if (FFragmentType = TACLXMLNodeType.None) and (FCurrentNode.&Type = TACLXMLNodeType.Text) then
                FFragmentType := TACLXMLNodeType.Element;
              Exit(True);
            end;
          end;
          Continue;
        end;

    Assert((APosition = FParsingState.CharsUsed) and not FParsingState.IsEof);

LblReadData:
    //# read new characters into the buffer
    if ReadData = 0 then
    begin
      if ANeedMoreChars then
        Throw(SXmlInvalidRootData);

      Assert(FIndex = 0);

      if not FRootElementParsed and (FFragmentType = TACLXMLNodeType.Document) then
        ThrowWithoutLineInfo(SXmlMissingRoot, '');

      if FFragmentType = TACLXMLNodeType.None then
        if FRootElementParsed then
          FFragmentType := TACLXMLNodeType.Document
        else
          FFragmentType := TACLXMLNodeType.Element;

      OnEof;
      Exit(False);
    end;
  end;
end;

function TACLXMLTextReader.AddNode(ANodeIndex, ANodeDepth: Integer): TACLXMLNodeData;
begin
  Assert(ANodeIndex < Length(FNodes));
  Assert(FNodes[Length(FNodes) - 1] = nil);

  Result := FNodes[ANodeIndex];
  if Result = nil then
  begin
    if ANodeIndex + 1 >= Length(FNodes) then
      SetLength(FNodes, Length(FNodes) * 2);
    Result := TACLXMLNodeData.Create;
    FNodes[ANodeIndex] := Result;
  end;
  Result.Depth := ANodeDepth;
end;

procedure TACLXMLTextReader.AttributeDuplCheck;
var
  AAttr1: TACLXMLNodeData;
  AAttr2: TACLXMLNodeData;
begin
  for var I := FIndex + 1 to FIndex + FAttributeCount do
  begin
    AAttr1 := FNodes[I];
    for var J := I + 1 to FIndex + FAttributeCount do
    begin
      AAttr2 := FNodes[J];
      if (Pointer(AAttr1.LocalName) = Pointer(AAttr2.LocalName)) and
         (Pointer(AAttr1.Namespace) = Pointer(AAttr2.Namespace))
      then
        Throw(SXmlDupAttributeName, AAttr2.GetNameWPrefix(FNameTable), AAttr2.LineInfo.LineNo, AAttr2.LineInfo.LinePos);
    end;
  end;
end;

procedure TACLXMLTextReader.AttributeNamespaceLookup;
var
  AAt: TACLXMLNodeData;
begin
  for var I := FIndex + 1 to FIndex + FAttributeCount do
  begin
    AAt := FNodes[I];
    if (AAt.&Type = TACLXMLNodeType.Attribute) and (AAt.Prefix <> '') then
      AAt.Namespace := LookupNamespace(AAt);
  end;
end;

function TACLXMLTextReader.AddAttribute(const ALocalName, APrefix: string; const ANameWPrefix: string): TACLXMLNodeData;
{$IFDEF ACL_XML_DUPLICATES_CHECK}
var
  AAttr: TACLXMLNodeData;
  AAttrHash: Integer;
{$ENDIF}
begin
  Result := AddNode(FIndex + FAttributeCount + 1, FIndex + 1);
  Result.SetNamedNode(TACLXMLNodeType.Attribute, ALocalName, APrefix, ANameWPrefix);
{$IFDEF ACL_XML_DUPLICATES_CHECK}
  //# pre-check attribute for duplicate: hash by first local name char
  AAttrHash := 1 shl (Ord(PChar(ALocalName)^) and $001F);
  if (FAttributeHashTable and AAttrHash) = 0 then
    FAttributeHashTable := FAttributeHashTable or AAttrHash
  else
  begin
    //# there are probably 2 attributes beginning with the same letter -> check all previous attributes
    if FAttributeDuplicateWalkCount < MaxAttrDuplWalkCount then
    begin
      Inc(FAttributeDuplicateWalkCount);
      for var I := FIndex + 1 to FIndex + FAttributeCount do
      begin
        AAttr := FNodes[I];
        Assert(AAttr.&Type = TACLXMLNodeType.Attribute);
        if Pointer(AAttr.LocalName) = Pointer(Result.LocalName) then
        begin
          FAttributeDuplicateWalkCount := MaxAttrDuplWalkCount;
          Break;
        end;
      end;
    end;
  end;
{$ENDIF}
  Inc(FAttributeCount);
end;

function TACLXMLTextReader.AddAttribute(AEndNamePos, AColonPos: Integer): TACLXMLNodeData;
var
  AAttrName: string;
  APrefixLen: Integer;
  AStartPos: Integer;
begin
  //# setup attribute name
  if (AColonPos = -1) or not FSupportNamespaces then
  begin
    AAttrName := FNameTable.Add(FParsingState.Chars, FParsingState.CharPos, AEndNamePos - FParsingState.CharPos);
    Result := AddAttribute(AAttrName, '', AAttrName);
  end
  else
  begin
    FAttributeNeedNamespaceLookup := True;
    AStartPos := FParsingState.CharPos;
    APrefixLen := AColonPos - AStartPos;
    if StrEqual(FParsingState.Chars, AStartPos, APrefixLen, FLastPrefix) then
      Result := AddAttribute(FNameTable.Add(FParsingState.Chars, AColonPos + 1, AEndNamePos - AColonPos - 1), FLastPrefix, '')
    else
    begin
      FLastPrefix := FNameTable.Add(FParsingState.Chars, AStartPos, APrefixLen);
      Result := AddAttribute(FNameTable.Add(FParsingState.Chars, AColonPos + 1, AEndNamePos - AColonPos - 1), FLastPrefix, '');
    end;
  end;
end;

function TACLXMLTextReader.AddAttributeNoChecks(const AName: string; AAttrDepth: Integer): TACLXMLNodeData;
var
  AAttrName: string;
begin
  AAttrName := FNameTable.Add(AName);
  Result := AddNode(FIndex + FAttributeCount + 1, AAttrDepth);
  Result.SetNamedNode(TACLXMLNodeType.Attribute, AAttrName, acEmptyStr, AAttrName);
  Inc(FAttributeCount);
end;

function TACLXMLTextReader.LookupNamespace(const ANode: TACLXMLNodeData): string;
begin
  Result := FNamespaceManager.LookupNamespace(ANode.Prefix);
  if Result = '' then
  // Немного кривой XML, согласен, но разве повод прерывать загрузку?
  // Throw оставляю для дебага, чтобы отловить ошибки записи.
  {$IFDEF DEBUG}
    Throw(SXmlUnknownNs, ANode.Prefix, ANode.LineInfo.LineNo, ANode.LineInfo.LinePos);
  {$ELSE}
    Result := ANode.Prefix;
  {$ENDIF}
end;

procedure TACLXMLTextReader.ElementNamespaceLookup;
begin
  Assert(FCurrentNode.&type = TACLXMLNodeType.Element);
  if FCurrentNode.Prefix = '' then
    FCurrentNode.Namespace := FXmlContext.DefaultNamespace
  else
    FCurrentNode.Namespace := LookupNamespace(FCurrentNode);
end;

procedure TACLXMLTextReader.ParseAttributeValueSlow(ACurPosition: Integer; AQuoteChar: Char; AAttribute: TACLXMLNodeData);
label
  LblReadData;
var
  APosition: Integer;
  AChars: TCharArray;
  AValueChunkLineInfo, AEntityLineInfo: TACLXMLLineInfo;
  ACh: Char;
begin
  APosition := ACurPosition;
  AChars := FParsingState.Chars;

  AValueChunkLineInfo.Init(FParsingState.LineNo, FParsingState.LinePos);

  Assert(FStringBuilder.Length = 0);

  while True do
  begin
    //# parse the rest of the attribute value
    //# C# unsafe section
    while (TACLXMLCharType.CharProperties[AChars[APosition]] and TACLXMLCharType.AttrValue) <> 0 do
      Inc(APosition);

    if APosition - FParsingState.CharPos > 0 then
    begin
      FStringBuilder.Append(AChars, FParsingState.CharPos, APosition - FParsingState.CharPos);
      FParsingState.CharPos := APosition;
    end;

    if AChars[APosition] = AQuoteChar then
      Break;

    case AChars[APosition] of
      #$000A: //# eol
        begin
          Inc(APosition);
          OnNewLine(APosition);
          if FNormalize then
          begin
            FStringBuilder.Append(#$0020);
            Inc(FParsingState.CharPos);
          end;
          Continue;
        end;
      #$000D:
        begin
          if AChars[APosition + 1] = #$000A then
          begin
            Inc(APosition, 2);
            if FNormalize then
            begin
              //# CDATA normalization of 0xD 0xA
              if FParsingState.EolNormalized then
                FStringBuilder.Append('  ')
              else
                FStringBuilder.Append(#$0020);
              FParsingState.CharPos := APosition;
            end;
          end
          else
            if (APosition + 1 < FParsingState.CharsUsed) or FParsingState.IsEof then
            begin
              Inc(APosition);
              if FNormalize then
              begin
                FStringBuilder.Append(#$0020);
                FParsingState.CharPos := APosition;
              end;
            end
            else
              goto LblReadData;
          OnNewLine(APosition);
          Continue;
        end;
      #$0009:
        begin
          Inc(APosition);
          if FNormalize then
          begin
            FStringBuilder.Append(#$0020);
            Inc(FParsingState.CharPos);
          end;
          Continue;
        end;
      '"', #$00027, '>':
        begin
          Inc(APosition);
          Continue;
        end;
      '<': //# attribute values cannot contain '<'
        Throw(APosition, SXmlBadAttributeChar, EACLXMLException.BuildCharExceptionArgs('<', #0));
      '&': //# entity reference
        begin
          if APosition - FParsingState.CharPos > 0 then
            FStringBuilder.Append(AChars, FParsingState.CharPos, APosition - FParsingState.CharPos);
          FParsingState.CharPos := APosition;

          AEntityLineInfo.Init(FParsingState.LineNo, FParsingState.LinePos + 1);
          case HandleEntityReference(True, TEntityExpandType.All, APosition) of
            TEntityType.CharacterDec, TEntityType.CharacterHex, TEntityType.CharacterNamed:
              { do nothing};
          else
            APosition := FParsingState.CharPos + 1; // +1 т.к. EntityReferencesNotImplemented
          end;
          AChars := FParsingState.Chars;
          Continue;
        end;
      else
      begin
        if APosition = FParsingState.CharsUsed then
          goto LblReadData
        else
        begin
          ACh := AChars[APosition];
          if TACLXMLCharType.IsHighSurrogate(ACh) then
          begin
            if APosition + 1 = FParsingState.CharsUsed then
              goto LblReadData;
            Inc(APosition);
            if TACLXMLCharType.IsLowSurrogate(AChars[APosition]) then
            begin
              Inc(APosition);
              Continue;
            end;
          end;
          ThrowInvalidChar(AChars, FParsingState.CharsUsed, APosition);
          Break;
        end;
      end;
    end;

  LblReadData:
    if ReadData = 0 then
    begin
      if FParsingState.CharsUsed - FParsingState.CharPos > 0 then
      begin
        if FParsingState.Chars[FParsingState.CharPos] <> #$000D then
        begin
          Assert(False, 'We should never get to this point.');
          Throw(SXmlUnexpectedEOF1);
        end;
        Assert(FParsingState.IsEof);
      end
      else
        Throw(SXmlEntityReferencesNotImplemented);
    end;

    APosition := FParsingState.CharPos;
    AChars := FParsingState.Chars;
  end;

  FParsingState.CharPos := APosition + 1;

  AAttribute.SetValue(FStringBuilder.ToString);
  FStringBuilder.Length := 0;
end;

procedure TACLXMLTextReader.PushXmlContext;
begin
  FXmlContext := TXmlContext.Create(FXmlContext);
  FCurrentNode.XmlContextPushed := True;
end;

procedure TACLXMLTextReader.PopElementContext;
begin
  FNamespaceManager.PopScope;
  if FCurrentNode.XmlContextPushed then
    PopXmlContext;
end;

procedure TACLXMLTextReader.PopXmlContext;
var
  ACurrentXmlContext: TXmlContext;
begin
  Assert(FCurrentNode.XmlContextPushed);
  ACurrentXmlContext := FXmlContext;
  FXmlContext := FXmlContext.PreviousContext;
  FCurrentNode.XmlContextPushed := False;
  ACurrentXmlContext.Free;
end;

procedure TACLXMLTextReader.AddNamespace(const APrefix, AUri: string; AAttribute: TACLXMLNodeData);
begin
  if AUri = TACLXMLReservedNamespaces.XmlNs then
  begin
    if APrefix = XmlNs then
      Throw(SXmlXmlnsPrefix, AAttribute.LineInfo2.LineNo, AAttribute.LineInfo2.LinePos)
    else
      Throw(SXmlNamespaceDeclXmlXmlns, APrefix, AAttribute.LineInfo2.LineNo, AAttribute.LineInfo2.LinePos);
  end
  else
    if AUri = TACLXMLReservedNamespaces.Xml then
    begin
      if APrefix <> Xml then
        Throw(SXmlNamespaceDeclXmlXmlns, APrefix, AAttribute.LineInfo2.LineNo, AAttribute.LineInfo2.LinePos);
    end;
  if (AUri = '') and (APrefix <> '') then
    Throw(SXmlBadNamespaceDecl, AAttribute.LineInfo.LineNo, AAttribute.LineInfo.LinePos);

  try
    FNamespaceManager.AddNamespace(APrefix, AUri);
  except
    on E: Exception do
      ReThrow(E, AAttribute.LineInfo.LineNo, AAttribute.LineInfo.LinePos);
  end;
end;

procedure TACLXMLTextReader.OnDefaultNamespaceDecl(AAttribute: TACLXMLNodeData);
var
  ANamespace: string;
begin
  if not FSupportNamespaces then
    Exit;

  ANamespace := FNameTable.Add(AAttribute.StringValue);
  AAttribute.Namespace := FNameTable.Add(TACLXMLReservedNamespaces.XmlNs);

  if not FCurrentNode.XmlContextPushed then
    PushXmlContext;

  FXmlContext.DefaultNamespace := ANamespace;
  AddNamespace('', ANamespace, AAttribute);
end;

procedure TACLXMLTextReader.OnNamespaceDecl(AAttribute: TACLXMLNodeData);
var
  ANamespace: string;
begin
  if FSupportNamespaces then
  begin
    ANamespace := FNameTable.Add(AAttribute.StringValue);
    if ANamespace = '' then
      Throw(SXmlBadNamespaceDecl, AAttribute.LineInfo2.LineNo, AAttribute.LineInfo2.LinePos - 1);
    AddNamespace(AAttribute.LocalName, ANamespace, AAttribute);
  end;
end;

procedure TACLXMLTextReader.OnXmlReservedAttribute(AAttribute: TACLXMLNodeData);
var
  AValue: string;
begin
  if AAttribute.LocalName = 'space' then
  begin
    if not FCurrentNode.XmlContextPushed then
      PushXmlContext;

    AValue := acTrim(AAttribute.StringValue);
    if AValue = 'preserve' then
      FXmlContext.XmlSpace := TACLXMLSpace.Preserve
    else if AValue = 'default' then
      FXmlContext.XmlSpace := TACLXMLSpace.Default
    else
      Throw(SXmlInvalidXmlSpace, AAttribute.StringValue, AAttribute.LineInfo.LineNo, AAttribute.LineInfo.LinePos);
  end
  else
    if AAttribute.LocalName = 'lang' then
    begin
      if not FCurrentNode.XmlContextPushed then
        PushXmlContext;
      FXmlContext.XmlLang := AAttribute.StringValue;
    end;
end;

procedure TACLXMLTextReader.ParseAttributes;
label
  lbContinueParseName, LblReadData, lbEnd;
var
  APosition, ALineNoDelta, AStartNameCharSize, AAttrNameLinePos, AColonPos: Integer;
  AChars: TCharArray;
  AAttr: TACLXMLNodeData;
  ATmpCh0, ATmpCh1, ATmpCh2, AQuoteChar, ATmpCh3: Char;
begin
  APosition := FParsingState.CharPos;
  AChars := FParsingState.Chars;
//#  AAttr := nil;

  Assert(FAttributeCount = 0);

  while True do
  begin
    //# eat whitespaces
    ALineNoDelta := 0;

    ATmpCh0 := AChars[APosition];
    while (TACLXMLCharType.CharProperties[ATmpCh0] and TACLXMLCharType.Whitespace) <> 0 do
    begin
      if ATmpCh0 = #$000A then
      begin
        OnNewLine(APosition + 1);
        Inc(ALineNoDelta);
      end
      else
        if ATmpCh0 = #$000D then
        begin
          if AChars[APosition + 1] = #$000A then
          begin
            OnNewLine(APosition + 2);
            Inc(ALineNoDelta);
            Inc(APosition);
          end
          else
            if APosition + 1 <> FParsingState.CharsUsed then
            begin
              OnNewLine(APosition + 1);
              Inc(ALineNoDelta);
            end
            else
            begin
              FParsingState.CharPos := APosition;
              goto LblReadData;
            end;
        end;
      Inc(APosition);
      ATmpCh0 := AChars[APosition];
    end;

    AStartNameCharSize := 0;
    ATmpCh1 := AChars[APosition];
    if (TACLXMLCharType.CharProperties[ATmpCh1] and TACLXMLCharType.NCStartNameSC) <> 0 then
      AStartNameCharSize := 1;

    if AStartNameCharSize = 0 then
    begin
      //# element end
      if ATmpCh1 = '>' then
      begin
        Assert(FCurrentNode.&type = TACLXMLNodeType.Element);
        FParsingState.CharPos := APosition + 1;
        FParsingFunction := TParsingFunction.MoveToElementContent;
        goto lbEnd;
      end
      //# empty element end
      else
        if ATmpCh1 = '/' then
        begin
          Assert(FCurrentNode.&type = TACLXMLNodeType.Element);
          if APosition + 1 = FParsingState.CharsUsed then
            goto LblReadData;

          if AChars[APosition + 1] = '>' then
          begin
            FParsingState.CharPos := APosition + 2;
            FCurrentNode.IsEmptyElement := True;
            FNextParsingFunction := FParsingFunction;
            FParsingFunction := TParsingFunction.PopEmptyElementContext;
            goto lbEnd;
          end
          else
            ThrowUnexpectedToken(APosition + 1, '>');
        end
        else
          if APosition = FParsingState.CharsUsed then
            goto LblReadData
          else
            if (ATmpCh1 <> ':') or FSupportNamespaces then
              Throw(APosition, SXmlBadStartNameChar, EACLXMLException.BuildCharExceptionArgs(AChars, FParsingState.CharsUsed, APosition));
    end;

    if APosition = FParsingState.CharPos then
      ThrowExpectingWhitespace(APosition);
    FParsingState.CharPos := APosition;

    AAttrNameLinePos := FParsingState.LinePos;
    //# parse attribute name
    AColonPos := -1;

    //# PERF: we intentionally don't call ParseQName here to parse the element name unless a special
    //# case occurs (like end of buffer, invalid name char)
    Inc(APosition, AStartNameCharSize);

  //# parse attribute name
lbContinueParseName:
    //# C# unsafe section
    repeat
      ATmpCh2 := AChars[APosition];
      if (TACLXMLCharType.CharProperties[ATmpCh2] and TACLXMLCharType.NCNameSC) <> 0 then
        Inc(APosition)
      else
        Break;
    until False;
    //# colon -> save prefix end position and check next char if it's name start char
    if ATmpCh2 = ':' then
    begin
      if AColonPos <> -1 then
      begin
        if FSupportNamespaces then
          Throw(APosition, SXmlBadNameChar, EACLXMLException.BuildCharExceptionArgs(':', #0))
        else
        begin
          Inc(APosition);
          goto lbContinueParseName;
        end;
      end
      else
      begin
        AColonPos := APosition;
        Inc(APosition);

        if (TACLXMLCharType.CharProperties[AChars[APosition]] and TACLXMLCharType.NCStartNameSC) <> 0 then
        begin
          Inc(APosition);
          goto lbContinueParseName;
        end;
        //# else fallback to full name parsing routine
        APosition := ParseQName(AColonPos);
        AChars := FParsingState.Chars;
      end;
    end
    else
      if APosition + 1 >= FParsingState.CharsUsed then
      begin
        APosition := ParseQName(AColonPos);
        AChars := FParsingState.Chars;
      end;

    AAttr := AddAttribute(APosition, AColonPos);
    AAttr.LineInfo.Init(FParsingState.LineNo, AAttrNameLinePos);
    //# parse equals and quote char;
    if AChars[APosition] <> '=' then
    begin
      FParsingState.CharPos := APosition;
      EatWhitespaces(nil);
      APosition := FParsingState.CharPos;
      if AChars[APosition] <> '=' then
        ThrowUnexpectedToken('=');
    end;
    Inc(APosition);
    AQuoteChar := AChars[APosition];
    if (AQuoteChar <> '"') and (AQuoteChar <> #$27) then
    begin
      FParsingState.CharPos := APosition;
      EatWhitespaces(nil);
      APosition := FParsingState.CharPos;
      AQuoteChar := AChars[APosition];
      if (AQuoteChar <> '"') and (AQuoteChar <> #$27) then
        ThrowUnexpectedToken('"', #$27);
    end;
    Inc(APosition);
    FParsingState.CharPos := APosition;

    AAttr.QuoteChar := AQuoteChar;
    AAttr.LineInfo2.Init(FParsingState.LineNo, FParsingState.LinePos);

    //# parse attribute value
    //# C# unsafe section
    repeat
      ATmpCh3 := AChars[APosition];
      if (TACLXMLCharType.CharProperties[ATmpCh3] and TACLXMLCharType.AttrValue) = 0 then
        Break;
      Inc(APosition);
    until False;

    if ATmpCh3 = AQuoteChar then
    begin
      AAttr.SetValue(AChars, FParsingState.CharPos, APosition - FParsingState.CharPos);
      Inc(APosition);
      FParsingState.CharPos := APosition;
    end
    else
    begin
      ParseAttributeValueSlow(APosition, AQuoteChar, AAttr);
      APosition := FParsingState.CharPos;
      AChars := FParsingState.Chars;
    end;
    //# handle special attributes:
    if AAttr.Prefix = '' then
    begin
      //# default namespace declaration
      if AAttr.LocalName = XmlNs then
        OnDefaultNamespaceDecl(AAttr);
    end
    else
    begin
      //# prefixed namespace declaration
      if AAttr.Prefix = XmlNs then
        OnNamespaceDecl(AAttr)
      //# xml: attribute
      else
        if AAttr.Prefix = Xml then
          OnXmlReservedAttribute(AAttr);
    end;
    Continue;

LblReadData:
    Dec(FParsingState.LineNo, ALineNoDelta);
    if ReadData <> 0 then
    begin
      APosition := FParsingState.CharPos;
      AChars := FParsingState.Chars;
    end
    else
      ThrowUnclosedElements;
  end;

lbEnd:
  //# lookup namespaces: element
  ElementNamespaceLookup;
  //# lookup namespaces: attributes
  if FAttributeNeedNamespaceLookup then
  begin
    AttributeNamespaceLookup;
    FAttributeNeedNamespaceLookup := False;
  end;
  //# check duplicate attributes
  if FAttributeDuplicateWalkCount >= MaxAttrDuplWalkCount then
    AttributeDuplCheck;
end;

//# Parses the element start tag
procedure TACLXMLTextReader.ParseElement;
label
  ContinueStartName, ContinueName, ParseQNameSlow, SetElement;
var
  ACh: Char;
  AChars: TCharArray;
  AColonPos: Integer;
  AIsWs: Boolean;
  ANodeName: string;
  APosition: Integer;
  APrefixLen: Integer;
  AStartPos: Integer;
begin
  APosition := FParsingState.CharPos;
  AChars := FParsingState.Chars;
  AColonPos := -1;

  FCurrentNode.LineInfo.Init(FParsingState.LineNo, FParsingState.LinePos);

//# PERF: we intentionally don't call ParseQName here to parse the element name unless a special
//# case occurs (like end of buffer, invalid name char)
ContinueStartName:
  //# check element name start char
  //# C# unsafe section
  if (TACLXMLCharType.CharProperties[AChars[APosition]] and TACLXMLCharType.NCStartNameSC) <> 0 then
    Inc(APosition)
  else
    goto ParseQNameSlow;

ContinueName:
  //# C# unsafe section
  //# parse element name
  while (TACLXMLCharType.CharProperties[AChars[APosition]] and TACLXMLCharType.NCNameSC) <> 0 do
    Inc(APosition);
  //# colon -> save prefix end position and check next char if it's name start char
  if AChars[APosition] = ':' then
  begin
    if AColonPos <> -1 then
    begin
      if FSupportNamespaces then
        Throw(APosition, SXmlBadNameChar, EACLXMLException.BuildCharExceptionArgs(':', #0))
      else
      begin
        Inc(APosition);
        goto ContinueName;
      end;
    end
    else
    begin
      AColonPos := APosition;
      Inc(APosition);
      goto ContinueStartName;
    end;
  end
  else
    if APosition + 1 < FParsingState.CharsUsed then
      goto SetElement;

ParseQNameSlow:
  APosition := ParseQName(AColonPos);
  AChars := FParsingState.Chars;

SetElement:
  //# push namespace context
  FNamespaceManager.PushScope;

  //# init the NodeData class
  if (AColonPos = -1) or not FSupportNamespaces then
  begin
    ANodeName := FNameTable.Add(AChars, FParsingState.CharPos, APosition - FParsingState.CharPos);
    FCurrentNode.SetNamedNode(TACLXMLNodeType.Element, ANodeName, acEmptyStr, ANodeName);
  end
  else
  begin
    AStartPos := FParsingState.CharPos;
    APrefixLen := AColonPos - AStartPos;
    if StrEqual(AChars, AStartPos, APrefixLen, FLastPrefix) then
    begin
      FCurrentNode.SetNamedNode(TACLXMLNodeType.Element,
        FNameTable.Add(AChars, AColonPos + 1, APosition - AColonPos - 1), FLastPrefix, '')
    end
    else
    begin
      FCurrentNode.SetNamedNode(TACLXMLNodeType.Element,
        FNameTable.Add(AChars, AColonPos + 1, APosition - AColonPos - 1),
        FNameTable.Add(AChars, FParsingState.CharPos, APrefixLen), '');
      FLastPrefix := FCurrentNode.Prefix;
    end;
  end;

  ACh := AChars[APosition];
  //# white space after element name -> there are probably some attributes

  //# C# unsafe section
  AIsWs := (TACLXMLCharType.CharProperties[ACh] and TACLXMLCharType.Whitespace) <> 0;

  if AIsWs then
  begin
    FParsingState.CharPos := APosition;
    ParseAttributes;
    Exit;
  end
  else
  //# no attributes
  begin
    //# non-empty element
    if ACh = '>' then
    begin
      FParsingState.CharPos := APosition + 1;
      FParsingFunction := TParsingFunction.MoveToElementContent;
    end
    //# empty element
    else
      if ACh = '/' then
      begin
        if APosition + 1 = FParsingState.CharsUsed then
        begin
          FParsingState.CharPos := APosition;
          if ReadData = 0 then
            Throw(APosition, SXmlUnexpectedEOF, '>');

          APosition := FParsingState.CharPos;
          AChars := FParsingState.Chars;
        end;
        if AChars[APosition + 1] = '>' then
        begin
          FCurrentNode.IsEmptyElement := True;
          FNextParsingFunction := FParsingFunction;
          FParsingFunction := TParsingFunction.PopEmptyElementContext;
          FParsingState.CharPos := APosition + 2;
        end
        else
          ThrowUnexpectedToken(APosition, '>');
      end
      else
        Throw(APosition, SXmlBadNameChar, EACLXMLException.BuildCharExceptionArgs(AChars, FParsingState.CharsUsed, APosition));

    ElementNamespaceLookup;
  end;
end;

function TACLXMLTextReader.ParseElementContent: Boolean;
label
  LReadData;
var
  APosition: Integer;
  AChars: TCharArray;
begin
  while True do
  begin
    APosition := FParsingState.CharPos;
    AChars := FParsingState.Chars;

    case AChars[APosition] of
      '<':
        case AChars[APosition + 1] of
          '?':
            begin
              FParsingState.CharPos := APosition + 2;
              if ParsePI then
                Exit(True);
              Continue;
            end;
          '!':
            begin
              Inc(APosition, 2);
              if FParsingState.CharsUsed - APosition < 2 then
                goto LReadData;

              if AChars[APosition] = '-' then
              begin
                if AChars[APosition + 1] = '-' then
                begin
                  FParsingState.CharPos := APosition + 2;
                  if ParseComment then
                    Exit(True);
                  Continue;
                end
                else
                  ThrowUnexpectedToken(APosition + 1, '-');
              end
              else
                if AChars[APosition] = '[' then
                begin
                  Inc(APosition);
                  if FParsingState.CharsUsed - APosition < 6 then
                    goto LReadData;
                  if StrEqual(AChars, APosition, 6, 'CDATA[') then
                  begin
                    FParsingState.CharPos := APosition + 6;
                    ParseCData;
                    Exit(True);
                  end
                  else
                    ThrowUnexpectedToken(APosition, 'CDATA[');
                end
                else
                begin
                  if ParseUnexpectedToken(APosition) = 'DOCTYPE' then
                    Throw(SXMLBadDTDLocation)
                  else
                    ThrowUnexpectedToken(APosition, '<!--', '<[CDATA[');
                end;
            end;
          '/':
            begin
              FParsingState.CharPos := APosition + 2;
              ParseEndElement;
              Exit(True);
            end;
          else
            //# end of buffer
            if APosition + 1 = FParsingState.CharsUsed then
              goto LReadData
            else
            begin
              //# element start tag
              FParsingState.CharPos := APosition + 1;
              ParseElement;
              Exit(True);
            end;
        end;
      '&':
        begin
          if ParseText then
            Exit(True);
          Continue;
        end
      else
        //#end of buffer
        if APosition = FParsingState.CharsUsed then
          goto LReadData
        else
        begin
          //#text node, whitespace or entity reference
          if ParseText then
            Exit(True);
          Continue;
        end;
    end;


  LReadData:
    if ReadData = 0 then
    begin
      if FParsingState.CharsUsed - FParsingState.CharPos <> 0 then
        ThrowUnclosedElements;
      if (FIndex = 0) and (FFragmentType <> TACLXMLNodeType.Document) then
      begin
        OnEof;
        Exit(False);
      end;
      ThrowUnclosedElements;
    end;
  end;
end;

procedure TACLXMLTextReader.ParseEndElement;
label
  LblReadData;
var
  AStartTagNode: TACLXMLNodeData;
  APrefLen, ALocLen, ANameLen, AColonPos, APosition: Integer;
  AChars: TCharArray;
  AEndTagLineInfo: TACLXMLLineInfo;
  ATmpCh: Char;
begin
  AStartTagNode := FNodes[FIndex - 1];

  APrefLen := Length(AStartTagNode.Prefix);
  ALocLen := Length(AStartTagNode.LocalName);

  while FParsingState.CharsUsed - FParsingState.CharPos < APrefLen + ALocLen + 1 do
  begin
    if ReadData = 0 then
      Break;
  end;

  AChars := FParsingState.Chars;
  if AStartTagNode.Prefix = '' then
  begin
    if not StrEqual(AChars, FParsingState.CharPos, ALocLen, AStartTagNode.LocalName) then
      ThrowTagMismatch(AStartTagNode);
    ANameLen := ALocLen;
  end
  else
  begin
    AColonPos := FParsingState.CharPos + APrefLen;
    if (not StrEqual(AChars, FParsingState.CharPos, APrefLen, AStartTagNode.Prefix)) or (AChars[AColonPos] <> ':') or
       (not StrEqual(AChars, AColonPos + 1, ALocLen, AStartTagNode.LocalName)) then
      ThrowTagMismatch(AStartTagNode);
    ANameLen := ALocLen + APrefLen + 1;
  end;

  AEndTagLineInfo.Init(FParsingState.LineNo, FParsingState.LinePos);

  repeat
    APosition := FParsingState.CharPos + ANameLen;
    AChars := FParsingState.Chars;

    if APosition = FParsingState.CharsUsed then
      goto LblReadData;

    //# Optimization due to the lack of inlining when a method uses byte*
    if (((TACLXMLCharType.CharProperties[AChars[APosition]] and TACLXMLCharType.NCNameSC) <> 0) or (AChars[APosition] = ':')) then
      ThrowTagMismatch(AStartTagNode);

    if AChars[APosition] <> '>' then
    repeat
      ATmpCh := AChars[APosition];
      if not TACLXMLCharType.IsWhiteSpace(ATmpCh) then
        Break;
      Inc(APosition);
      case ATmpCh of
        #$000A:
          begin
            OnNewLine(APosition);
            Continue;
          end;
        #$000D:
          begin
            if AChars[APosition] = #$000A then
              Inc(APosition)
            else
              if (APosition = FParsingState.CharsUsed) and not FParsingState.IsEof then
                Break;
            OnNewLine(APosition);
            Continue;
          end;
      end;
    until False;

    if AChars[APosition] = '>' then
      Break
    else
      if APosition = FParsingState.CharsUsed then
        goto LblReadData
      else
        ThrowUnexpectedToken(APosition, '>');

    Assert(False, 'We should never get to this point.');

LblReadData:
    if ReadData = 0 then
      Throw('UnclosedElements');
  until False;

  Assert(FIndex > 0);
  Dec(FIndex);
  FCurrentNode := FNodes[FIndex];

  Assert(FCurrentNode = AStartTagNode);
  AStartTagNode.LineInfo.Init(AEndTagLineInfo.LineNo, AEndTagLineInfo.LinePos);
  AStartTagNode.&Type := TACLXMLNodeType.EndElement;
  FParsingState.CharPos := APosition + 1;

  if (FIndex > 0) then
    FNextParsingFunction := FParsingFunction
  else
    FNextParsingFunction := TParsingFunction.DocumentContent;
  FParsingFunction := TParsingFunction.PopElementContext;
end;

function TACLXMLTextReader.ParseName: Integer;
var
  AColonPos: Integer;
begin
  Result := ParseQName(False, 0, AColonPos);
end;

procedure TACLXMLTextReader.OnNewLine(APosition: Integer);
begin
  Inc(FParsingState.LineNo);
  FParsingState.LineStartPos := APosition - 1;
end;

function TACLXMLTextReader.EatWhitespaces(ASb: TACLStringBuilder): Integer;
var
  APosition, AWsCount, ATmp1, ATmp2, ATmp3: Integer;
  AChars: TCharArray;
begin
  APosition := FParsingState.CharPos;
  AWsCount := 0;
  AChars := FParsingState.Chars;

  while True do
  begin
    while True do
    begin
      case AChars[APosition] of
        #$000A:
          begin
            Inc(APosition);
            OnNewLine(APosition);
          end;
        #$000D:
          begin
            if AChars[APosition + 1] = #$000A then
            begin
              ATmp1 := APosition - FParsingState.CharPos;
              if (ASb <> nil) and not FParsingState.EolNormalized then
              begin
                if ATmp1 > 0 then
                begin
                  ASb.Append(AChars, FParsingState.CharPos, ATmp1);
                  Inc(AWsCount, ATmp1);
                end;
                FParsingState.CharPos := APosition + 1;
              end;
              Inc(APosition, 2);
            end
            else
              if (APosition + 1 < FParsingState.CharsUsed) or (FParsingState.IsEof) then
              begin
                if not FParsingState.EolNormalized then
                  AChars[APosition] := #$000A;
                Inc(APosition);
              end
              else
                Break;
            OnNewLine(APosition);
          end;
        #$0009, ' ':
          Inc(APosition);
        else
        begin
          if APosition = FParsingState.CharsUsed then
            Break
          else
          begin
            ATmp2 := APosition - FParsingState.CharPos;
            if ATmp2 > 0 then
            begin
              if ASb <> nil then
                ASb.Append(FParsingState.Chars, FParsingState.CharPos, ATmp2);
              FParsingState.CharPos := APosition;
              Inc(AWsCount, ATmp2);
            end;
            Exit(AWsCount);
          end;
        end;
      end;
    end;

    //# here was the label ReadData:

    ATmp3 := APosition - FParsingState.CharPos;
    if ATmp3 > 0 then
    begin
      if ASb <> nil then
        ASb.Append(FParsingState.Chars, FParsingState.CharPos, ATmp3);
      FParsingState.CharPos := APosition;
      Inc(AWsCount, ATmp3);
    end;

    if ReadData = 0 then
    begin
      if FParsingState.CharsUsed - FParsingState.CharPos = 0 then
        Exit(AWsCount);

      if FParsingState.Chars[FParsingState.CharPos] <> #$000D then
      begin
        Assert(False, 'We should never get to this point.');
        Throw(SXmlUnexpectedEOF1);
      end;
      Assert(FParsingState.IsEof);
    end;
    APosition := FParsingState.CharPos;
    AChars := FParsingState.Chars;
  end;
end;

procedure TACLXMLTextReader.ShiftBuffer(ASourcePosition, ADestPosition, ACount: Integer);
begin
  FastMove(FParsingState.Chars[ASourcePosition], FParsingState.Chars[ADestPosition], ACount * SizeOf(Char));
end;

function TACLXMLTextReader.ParsePIValue(out AOutStartPosition, AOutEndPosition: Integer): Boolean;
var
  APosition, ARcount, ARpos: Integer;
  AChars: TCharArray;
  ATmpCh, ACh: Char;
begin
  //# read new characters into the buffer
  if FParsingState.CharsUsed - FParsingState.CharPos < 2 then
    if ReadData = 0 then
      Throw(FParsingState.CharsUsed, SXmlUnexpectedEOF, 'PI');

  APosition := FParsingState.CharPos;
  AChars := FParsingState.Chars;
  ARcount := 0;
  ARpos := -1;

  while True do
  begin
    //# C# unsafe section
    while True do
    begin
      ATmpCh := AChars[APosition];
      if not ((ATmpCh <> '?') and (TACLXMLCharType.CharProperties[ATmpCh] and TACLXMLCharType.Text <> 0)) then
        Break;
      Inc(APosition);
    end;

    case AChars[APosition] of
      '?':
        begin
          if AChars[APosition + 1] = '>' then
          begin
            if ARcount > 0 then
            begin
              Assert(not FParsingState.EolNormalized);
              ShiftBuffer(ARpos + ARcount, ARpos, APosition - ARpos - ARcount);
              AOutEndPosition := APosition - ARcount;
            end
            else
              AOutEndPosition := APosition;
            AOutStartPosition := FParsingState.CharPos;
            FParsingState.CharPos := APosition + 2;
            Exit(True);
          end
          else
            if APosition + 1 = FParsingState.CharsUsed then
              Break
            else
              Inc(APosition);
        end;
      #$000A:
        begin
          Inc(APosition);
          OnNewLine(APosition);
        end;
      #$000D:
        begin
          if AChars[APosition + 1] = #$000A then
          begin
            if not FParsingState.EolNormalized and (FParsingMode = TParsingMode.Full) then
            begin

              if APosition - FParsingState.CharPos > 0 then
              begin
                if ARcount = 0 then
                begin
                  ARcount := 1;
                  ARpos := APosition;
                end
                else
                begin
                  ShiftBuffer(ARpos + ARcount, ARpos, APosition - ARpos - ARcount);
                  ARpos := APosition - ARcount;
                  Inc(ARcount);
                end;
              end
              else
                Inc(FParsingState.CharPos);
            end;
            Inc(APosition, 2);
          end
          else
            if (APosition + 1 < FParsingState.CharsUsed) or FParsingState.IsEof then
            begin
              if not FParsingState.EolNormalized then
                AChars[APosition] := #$000A;
              Inc(APosition);
            end
            else
              Break;
          OnNewLine(APosition);
        end;
      '<', '&', ']', #$0009:
        Inc(APosition);
      else
      begin
        //# end of buffer
        if APosition = FParsingState.CharsUsed then
          Break
        else
        //# surrogate characters
        begin
          ACh := AChars[APosition];
          if TACLXMLCharType.IsHighSurrogate(ACh) then
          begin
            if APosition + 1 = FParsingState.CharsUsed then
              Break;
            Inc(APosition);
            if TACLXMLCharType.IsLowSurrogate(AChars[APosition]) then
            begin
              Inc(APosition);
              Continue;
            end;
          end;
          ThrowInvalidChar(AChars, FParsingState.CharsUsed, APosition);
          Break;
        end;
      end;
    end;
  end;

  if ARcount > 0 then
  begin
    ShiftBuffer(ARpos + ARcount, ARpos, APosition - ARpos - ARcount);
    AOutEndPosition := APosition - ARcount;
  end
  else
    AOutEndPosition := APosition;

  AOutStartPosition := FParsingState.CharPos;
  FParsingState.CharPos := APosition;
  Result := False;
end;

//# Parses processing instruction; if piInDtdStringBuilder != null, the processing instruction is in DTD and
//# it will be saved in the passed string builder (target, whitespace & value).
function TACLXMLTextReader.ParsePI(APiInDtdStringBuilder: TACLStringBuilder): Boolean;
var
  ANameEndPos, AStartPos, AEndPos: Integer;
  ATarget: string;
  ACh: Char;
  ASb: TACLStringBuilder;
begin
  if FParsingMode = TParsingMode.Full then
    FCurrentNode.LineInfo.Init(FParsingState.LineNo, FParsingState.LinePos);

  Assert(FStringBuilder.Length = 0);
  //# parse target name
  ANameEndPos := ParseName;
  ATarget := FNameTable.Add(FParsingState.Chars, FParsingState.CharPos, ANameEndPos - FParsingState.CharPos);

  if SameText(ATarget, 'xml') then
    Throw(IfThen(ATarget = 'xml', SXMLXmlDeclNotFirst, SXmlInvalidPIName), ATarget);

  FParsingState.CharPos := ANameEndPos;

  if APiInDtdStringBuilder = nil then
  begin
    if not FIgnoreProcessingInstructions and (FParsingMode = TParsingMode.Full) then
      FCurrentNode.SetNamedNode(TACLXMLNodeType.ProcessingInstruction, ATarget, acEmptyStr, ATarget);
  end
  else
    APiInDtdStringBuilder.Append(ATarget);

  //# check mandatory whitespace
  ACh := FParsingState.Chars[FParsingState.CharPos];
  Assert(FParsingState.CharPos < FParsingState.CharsUsed);

  if EatWhitespaces(APiInDtdStringBuilder) = 0 then
  begin
    if FParsingState.CharsUsed - FParsingState.CharPos < 2 then
      ReadData;
    if (ACh <> '?') or (FParsingState.Chars[FParsingState.CharPos + 1] <> '>') then
      Throw(FParsingState.CharPos, SXmlBadNameChar, EACLXMLException.BuildCharExceptionArgs(
        FParsingState.Chars, FParsingState.CharsUsed, FParsingState.CharPos));
  end;

  if ParsePIValue(AStartPos, AEndPos) then
  begin
    if APiInDtdStringBuilder = nil then
    begin
      if FIgnoreProcessingInstructions then
        Exit(False);
      if FParsingMode = TParsingMode.Full then
        FCurrentNode.SetValue(FParsingState.Chars, AStartPos, AEndPos - AStartPos);
    end
    else
      APiInDtdStringBuilder.Append(FParsingState.Chars, AStartPos, AEndPos - AStartPos);
  end
  else
  begin
    if APiInDtdStringBuilder = nil then
    begin
      if FIgnoreProcessingInstructions or (FParsingMode <> TParsingMode.Full) then
      begin
        while not ParsePIValue(AStartPos, AEndPos) do;
        Exit(False);
      end;
      ASb := FStringBuilder;
      Assert(FStringBuilder.Length = 0);
    end
    else
      ASb := APiInDtdStringBuilder;

    repeat
      ASb.Append(FParsingState.Chars, AStartPos, AEndPos - AStartPos);
    until ParsePIValue(AStartPos, AEndPos);
    ASb.Append(FParsingState.Chars, AStartPos, AEndPos - AStartPos);

    if APiInDtdStringBuilder = nil then
    begin
      FCurrentNode.SetValue(FStringBuilder.ToString);
      FStringBuilder.Length := 0;
    end;
  end;
  Result := True;
end;

function TACLXMLTextReader.ParseQName(out AColonPosition: Integer): Integer;
begin
  Result := ParseQName(True, 0, AColonPosition);
end;

function TACLXMLTextReader.ReadDataInName(var APosition: Integer): Boolean;
var
  AOffset: Integer;
begin
  AOffset := APosition - FParsingState.CharPos;
  Result := ReadData <> 0;
  APosition := FParsingState.CharPos + AOffset;
end;

function TACLXMLTextReader.ParseQName(AIsQName: Boolean; AStartOffset: Integer; out AColonPosition: Integer): Integer;
label
  ContinueStartName, ContinueName;
var
  AColonOffset, APosition: Integer;
  AChars: TCharArray;
begin
  AColonOffset := -1;
  APosition := FParsingState.CharPos + AStartOffset;

ContinueStartName:
  AChars := FParsingState.Chars;
  if TACLXMLCharType.CharProperties[AChars[APosition]] and TACLXMLCharType.NCStartNameSC <> 0 then
    Inc(APosition)
  else
  begin
    if APosition + 1 >= FParsingState.CharsUsed then
    begin
      if ReadDataInName(APosition) then
        goto ContinueStartName;

      Throw(APosition, SXmlUnexpectedEOF, 'Name');
    end;
    if (AChars[APosition] <> ':') or FSupportNamespaces then
      Throw(APosition, SXmlBadStartNameChar, EACLXMLException.BuildCharExceptionArgs(AChars,
        FParsingState.CharsUsed, APosition));
  end;

ContinueName:
  while TACLXMLCharType.CharProperties[AChars[APosition]] and TACLXMLCharType.NCNameSC <> 0 do
    Inc(APosition);

  if AChars[APosition] = ':' then
  begin
    if FSupportNamespaces then
    begin
      if (AColonOffset <> -1) or not AIsQName then
        Throw(APosition, SXmlBadNameChar, EACLXMLException.BuildCharExceptionArgs(':', #0));

      AColonOffset := APosition - FParsingState.CharPos;
      Inc(APosition);
      goto ContinueStartName;
    end
    else
    begin
      AColonOffset := APosition - FParsingState.CharPos;
      Inc(APosition);
      goto ContinueName;
    end;
  end
  else
    if APosition = FParsingState.CharsUsed then
    begin
      if ReadDataInName(APosition) then
      begin
        AChars := FParsingState.Chars;
        goto ContinueName;
      end;
      Throw(APosition, SXmlUnexpectedEOF, 'Name');
    end;

  if AColonOffset = -1 then
    AColonPosition := -1
  else
    AColonPosition := FParsingState.CharPos + AColonOffset;
  Result := APosition;
end;

function TACLXMLTextReader.ParseRootLevelWhitespace: Boolean;
var
  ANodeType: TACLXMLNodeType;
begin
  Assert(FStringBuilder.Length = 0);

  ANodeType := GetWhitespaceType;

  if ANodeType = TACLXMLNodeType.None then
  begin
    EatWhitespaces(nil);
    if (FParsingState.Chars[FParsingState.CharPos] = '<') or (FParsingState.CharsUsed = FParsingState.CharPos) then
      Exit(False);
  end
  else
  begin
    FCurrentNode.LineInfo.Init(FParsingState.LineNo, FParsingState.LinePos);
    EatWhitespaces(FStringBuilder);
    if (FParsingState.Chars[FParsingState.CharPos] = '<') or (FParsingState.CharsUsed = FParsingState.CharPos) then
    begin
      if FStringBuilder.Length > 0 then
      begin
        FCurrentNode.SetValueNode(ANodeType, FStringBuilder.ToString);
        FStringBuilder.Length := 0;
        Exit(True);
      end;
      Exit(False);
    end;
  end;

  if TACLXMLCharType.IsCharData(FParsingState.Chars[FParsingState.CharPos]) then
    Throw(SXmlInvalidRootData)
  else
    ThrowInvalidChar(FParsingState.Chars, FParsingState.CharsUsed, FParsingState.CharPos);
  Result := False;
end;

function TACLXMLTextReader.GetWhitespaceType: TACLXMLNodeType;
begin
  if FWhitespaceHandling <> TACLXMLWhitespaceHandling.None then
  begin
    if FXmlContext.XmlSpace = TACLXMLSpace.Preserve then
      Exit(TACLXMLNodeType.SignificantWhitespace);
    if FWhitespaceHandling = TACLXMLWhitespaceHandling.All then
      Exit(TACLXMLNodeType.Whitespace);
  end;
  Result := TACLXMLNodeType.None;
end;

function TACLXMLTextReader.GetText: string;
begin
  if FParsingFunction = TParsingFunction.PartialTextValue then
  begin
    FinishPartialValue;
    FParsingFunction := FNextParsingFunction;
  end;
  Result := FCurrentNode.StringValue;
  if FXmlContext.XmlSpace <> TACLXMLSpace.Preserve then
    //Result := acTrim(acReplaceChars(Value, #9#13#10, ' '))
    Result := acTrim(Result);
end;

//# Parses text or white space node.
//# Returns true if a node has been parsed and its data set to curNode.
//# Returns false when a white space has been parsed and ignored (according to current whitespace handling) or when parsing mode is not Full.
//# Also returns false if there is no text to be parsed.
function TACLXMLTextReader.ParseText: Boolean;
var
  AStartPos, AEndPos, AOrChars: Integer;
  ANodeType: TACLXMLNodeType;
  AFullValue: Boolean;
begin
  AOrChars := 0;

  if FParsingMode <> TParsingMode.Full then
  begin
    while not ParseText(AStartPos, AEndPos, AOrChars) do ;
    Exit(False);
  end;

  FCurrentNode.LineInfo.Init(FParsingState.LineNo, FParsingState.LinePos);
  Assert(FStringBuilder.Length = 0);

  //# the whole value is in buffer
  if ParseText(AStartPos, AEndPos, AOrChars) then
  begin
    if AEndPos - AStartPos = 0 then
      Exit(False);

    if AOrChars > $20 then
      ANodeType := TACLXMLNodeType.Text
    else
      ANodeType := GetWhitespaceType;

    if ANodeType = TACLXMLNodeType.None then
      Exit(False);

    Assert(AEndPos - AStartPos > 0);
    FCurrentNode.SetValueNode(ANodeType, FParsingState.Chars, AStartPos, AEndPos - AStartPos);
  end
  //# only piece of the value was returned
  else
  begin
    //# if it's a partial text value, not a whitespace -> return
    if AOrChars > $20 then
    begin
      Assert(AEndPos - AStartPos > 0);
      FCurrentNode.SetValueNode(TACLXMLNodeType.Text, FParsingState.Chars, AStartPos, AEndPos - AStartPos);
      FNextParsingFunction := FParsingFunction;
      FParsingFunction := TParsingFunction.PartialTextValue;
      Exit(True);
    end;
    //# partial whitespace -> read more data (up to 4kB) to decide if it is a whitespace or a text node
    if AEndPos - AStartPos > 0 then
      FStringBuilder.Append(FParsingState.Chars, AStartPos, AEndPos - AStartPos);

    repeat
      AFullValue := ParseText(AStartPos, AEndPos, AOrChars);
      if AEndPos - AStartPos > 0 then
        FStringBuilder.Append(FParsingState.Chars, AStartPos, AEndPos - AStartPos);
    until not (not AFullValue and (AOrChars <= $20) and (FStringBuilder.Length < MinWhitespaceLookahedCount));

    //# determine the value node type
    if FStringBuilder.Length < MinWhitespaceLookahedCount then
    begin
      if AOrChars > $20 then
        ANodeType := TACLXMLNodeType.Text
      else
        ANodeType := GetWhitespaceType;
    end
    else
      ANodeType := TACLXMLNodeType.Text;

    if ANodeType = TACLXMLNodeType.None then
    begin
      //# ignored whitespace -> skip over the rest of the value unless we already read it all
      FStringBuilder.Length := 0;
      if not AFullValue then
        while not ParseText(AStartPos, AEndPos, AOrChars) do ;
      Exit(False);
    end;
    //# set value to curNode
    FCurrentNode.SetValueNode(ANodeType, FStringBuilder.ToString);
    FStringBuilder.Length := 0;
    //# change parsing state if the full value was not parsed
    if not AFullValue then
    begin
      FNextParsingFunction := FParsingFunction;
      FParsingFunction := TParsingFunction.PartialTextValue;
    end;
  end;

  Result := True;
end;

//# Parses numeric character entity reference (e.g. &#32; &#x20;).
//# Returns -2 if more data is needed in the buffer
//# Otherwise
//#      - replaces the last one or two character of the entity reference (';' and the character before) with the referenced
//#        character or surrogates pair (if expand == true)
//#      - returns position of the end of the character reference, that is of the character next to the original ';'
function TACLXMLTextReader.ParseNumericCharRefInline(AStartPosition: Integer; AExpand: Boolean;
  AInternalSubsetBuilder: TACLStringBuilder; out ACharCount: Integer; out AEntityType: TEntityType): Integer;
label
  Return;
var
  ABadDigitExceptionString: string;
  ACh, ALow, AHigh: Char;
  AChars: TCharArray;
  AChByte: Byte;
  AVal, APosition, ADigitPos: Integer;
begin
  Assert((FParsingState.Chars[AStartPosition] = '&') and (FParsingState.Chars[AStartPosition + 1] = '#'));

  AVal := 0;
  ABadDigitExceptionString := '';
  AChars := FParsingState.Chars;
  APosition := AStartPosition + 2;
  ACharCount := 0;
  ADigitPos := 0;

  try
    if AChars[APosition] = 'x' then
    begin
      Inc(APosition);
      ADigitPos := APosition;
      ABadDigitExceptionString := SXmlBadHexEntity;
      while TACLHexcode.Decode(AChars[APosition], AChByte) do
      begin
        AVal := AVal * 16 + AChByte;
        Inc(APosition);
      end;
      AEntityType := TEntityType.CharacterHex;
    end
    else
      if APosition < FParsingState.CharsUsed then
      begin
        ADigitPos := APosition;
        ABadDigitExceptionString := SXmlBadDecimalEntity;
        while (AChars[APosition] >= '0') and (AChars[APosition] <= '9') do
        begin
          {$Q+}
          AVal := AVal * 10 + Ord(AChars[APosition]) - Ord('0');
          {$Q-}
          Inc(APosition);
        end;
        AEntityType := TEntityType.CharacterDec;
      end
      else
      begin
        //# need more data in the buffer
        AEntityType := TEntityType.Skipped;
        Exit(-2);
      end;
  except
    on EOverflow do
      begin
        FParsingState.CharPos := APosition;
        AEntityType := TEntityType.Skipped;
        Throw(SXmlCharEntityOverflow, '');  //#Throw(Res.Xml_CharEntityOverflow, (string)null, e);
      end;
  end;

  if (AChars[APosition] <> ';') or (ADigitPos = APosition) then
    if APosition = FParsingState.CharsUsed then
      //# need more data in the buffer
      Exit(-2)
    else
      Throw(APosition, ABadDigitExceptionString, '');

  if AVal <= Ord(High(Char)) then
  begin
    ACh := Char(AVal);
    if not TACLXMLCharType.IsCharData(ACh) and FCheckCharacters then
      Throw(IfThen(FParsingState.Chars[AStartPosition + 2] = 'x', AStartPosition + 3, AStartPosition + 2), SXmlInvalidCharacter,
        EACLXMLException.BuildCharExceptionArgs(ACh, #0));

    if AExpand then
    begin
      if AInternalSubsetBuilder <> nil then
        AInternalSubsetBuilder.Append(FParsingState.Chars, FParsingState.CharPos, APosition - FParsingState.CharPos + 1);
      AChars[APosition] := ACh;
    end;
    ACharCount := 1;
  end
  else
  begin
    TACLXMLCharType.SplitSurrogateChar(AVal, ALow, AHigh);

    if FNormalize then
    begin
      if TACLXMLCharType.IsHighSurrogate(AHigh) then
        if TACLXMLCharType.IsLowSurrogate(ALow) then
          goto Return;
      Throw(IfThen(FParsingState.Chars[AStartPosition + 2] = 'x', AStartPosition + 3, AStartPosition + 2), SXmlInvalidCharacter,
        EACLXMLException.BuildCharExceptionArgs(AHigh, ALow));
    end;

Return:
    Assert(APosition > 0);
    if AExpand then
    begin
      if AInternalSubsetBuilder <> nil then
        AInternalSubsetBuilder.Append(FParsingState.Chars, FParsingState.CharPos, APosition - FParsingState.CharPos + 1);
      AChars[APosition - 1] := AHigh;
      AChars[APosition] := ALow;
    end;
    ACharCount := 2;
  end;
  Result := APosition + 1;
end;

//# Parses named character entity reference (&amp; &apos; &lt; &gt; &quot;).
//# Returns -1 if the reference is not a character entity reference.
//# Returns -2 if more data is needed in the buffer
//# Otherwise
//#      - replaces the last character of the entity reference (';') with the referenced character (if expand == true)
//#      - returns position of the end of the character reference, that is of the character next to the original ';'
function TACLXMLTextReader.ParseNamedCharRefInline(AStartPosition: Integer; AExpand: Boolean;
  AInternalSubsetBuilder: TACLStringBuilder): Integer;
label
  FoundCharRef;
var
  APosition: Integer;
  AChars: TCharArray;
  ACh: Char;
begin
  Assert(AStartPosition < FParsingState.CharsUsed);
  Assert(FParsingState.Chars[AStartPosition] = '&');
  Assert(FParsingState.Chars[AStartPosition + 1] <> '#');

  APosition := AStartPosition + 1;
  AChars := FParsingState.Chars;

  case AChars[APosition] of
    'a': //# &amp;
      begin
        Inc(APosition);

        if AChars[APosition] = 'm' then
        begin
          if FParsingState.CharsUsed - APosition >= 3 then
          begin
            if (AChars[APosition + 1] = 'p') and (AChars[APosition + 2] = ';') then
            begin
              Inc(APosition, 3);
              ACh := '&';
              goto FoundCharRef;
            end
            else
              Exit(-1);
          end;
        end
        else //# &apos;
          if AChars[APosition] = 'p' then
          begin
            if FParsingState.CharsUsed - APosition >= 4 then
            begin
              if (AChars[APosition + 1] = 'o') and (AChars[APosition + 2] = 's') and (AChars[APosition + 3] = ';') then
              begin
                Inc(APosition, 4);
                ACh := #$27;
                goto FoundCharRef;
              end
              else
                Exit(-1);
            end;
          end
          else
            if APosition < FParsingState.CharsUsed then
              Exit(-1);
      end;
    'q': //# &guot;
      if FParsingState.CharsUsed - APosition >= 5 then
      begin
        if (AChars[APosition + 1] = 'u') and (AChars[APosition + 2] = 'o') and (AChars[APosition + 3] = 't') and (AChars[APosition + 4] = ';') then
        begin
          Inc(APosition, 5);
          ACh := '"';
          goto FoundCharRef;
        end
        else
          Exit(-1);
      end;
    'l': //# &lt;
      if FParsingState.CharsUsed - APosition >= 3 then
      begin
        if (AChars[APosition + 1] = 't') and (AChars[APosition + 2] = ';') then
        begin
          Inc(APosition, 3);
          ACh := '<';
          goto FoundCharRef;
        end
        else
          Exit(-1);
      end;
    'g': //# &gt;
      if FParsingState.CharsUsed - APosition >= 3 then
      begin
        if (AChars[APosition + 1] = 't') and (AChars[APosition + 2] = ';') then
        begin
          Inc(APosition, 3);
          ACh := '>';
          goto FoundCharRef;
        end
        else
          Exit(-1);
      end;
    else
      Exit(-1);
  end;
  //# need more data in the buffer
  Exit(-2);

FoundCharRef:
  Assert(APosition > 0);
  if AExpand then
  begin
    if AInternalSubsetBuilder <> nil then
      AInternalSubsetBuilder.Append(FParsingState.Chars, FParsingState.CharPos, APosition - FParsingState.CharPos);
    FParsingState.Chars[APosition - 1] := ACh;
  end;
  Result := APosition;
end;

function TACLXMLTextReader.ParseCharRefInline(AStartPosition: Integer; out ACharCount: Integer;
  out AEntityType: TEntityType): Integer;
begin
  Assert(FParsingState.Chars[AStartPosition] = '&');
  if FParsingState.Chars[AStartPosition + 1] = '#' then
    Result := ParseNumericCharRefInline(AStartPosition, True, nil, ACharCount, AEntityType)
  else
  begin
    ACharCount := 1;
    AEntityType := TEntityType.CharacterNamed;
    Result := ParseNamedCharRefInline(AStartPosition, True, nil);
  end;
end;

//# Parses numeric character entity reference (e.g. &#32; &#x20;).
//#      - replaces the last one or two character of the entity reference (';' and the character before) with the referenced
//#        character or surrogates pair (if expand == true)
//#      - returns position of the end of the character reference, that is of the character next to the original ';'
//#      - if (expand == true) then ps.CharPos is changed to point to the replaced character
function TACLXMLTextReader.ParseNumericCharRef(AExpand: Boolean; AInternalSubsetBuilder: TACLStringBuilder;
  out AEntityType: TEntityType): Integer;
var
  ANewPos, ACharCount: Integer;
begin
  while True do
  begin
    ANewPos := ParseNumericCharRefInline(FParsingState.CharPos, AExpand, AInternalSubsetBuilder, ACharCount, AEntityType);
    case ANewPos of
      -2:
        begin
          //# read new characters in the buffer
          if ReadData = 0 then
            Throw(SXmlUnexpectedEOF);
          Assert(FParsingState.Chars[FParsingState.CharPos] = '&');
        end;
      else
      begin
        if AExpand then
          FParsingState.CharPos := ANewPos - ACharCount;
        Exit(ANewPos);
      end;
    end;
  end;
end;

//# Parses named character entity reference (&amp; &apos; &lt; &gt; &quot;).
//# Returns -1 if the reference is not a character entity reference.
//# Otherwise
//#      - replaces the last character of the entity reference (';') with the referenced character (if expand == true)
//#      - returns position of the end of the character reference, that is of the character next to the original ';'
//#      - if (expand == true) then ps.CharPos is changed to point to the replaced character
function TACLXMLTextReader.ParseNamedCharRef(AExpand: Boolean; AInternalSubsetBuilder: TACLStringBuilder): Integer;
var
  ANewPos: Integer;
begin
  while True do
  begin
    ANewPos := ParseNamedCharRefInline(FParsingState.CharPos, AExpand, AInternalSubsetBuilder);
    case ANewPos of
      -1:
        Exit(-1);
      -2:
        begin
          //# read new characters in the buffer
          if ReadData = 0 then
            Exit(-1);
          Assert(FParsingState.Chars[FParsingState.CharPos] = '&');
          Continue;
        end;
      else
      begin
        if AExpand then
          FParsingState.CharPos := ANewPos - 1;
        Exit(ANewPos);
      end;
    end;
  end;
end;

function TACLXMLTextReader.HandleEntityReference(
  AIsInAttributeValue: Boolean; AExpandType: TEntityExpandType; out ACharRefEndPos: Integer): TEntityType;
var
  AEntityType: TEntityType;
begin
  Assert(FParsingState.Chars[FParsingState.CharPos] = '&');

  if FParsingState.CharPos + 1 = FParsingState.CharsUsed then
  begin
    if ReadData = 0 then
      Throw(SXmlUnexpectedEOF1);
  end;
  //# numeric characters reference
  if FParsingState.Chars[FParsingState.CharPos + 1] = '#' then
  begin
    ACharRefEndPos := ParseNumericCharRef(AExpandType <> TEntityExpandType.OnlyGeneral, nil, AEntityType);
    Assert((AEntityType = TEntityType.CharacterDec) or (AEntityType = TEntityType.CharacterHex));
    Result := AEntityType;
  end
  //# named reference
  else
  begin
    //# named character reference
    ACharRefEndPos := ParseNamedCharRef(AExpandType <> TEntityExpandType.OnlyGeneral, nil);
    if ACharRefEndPos >= 0 then
      Exit(TEntityType.CharacterNamed);

    //# we does not supports for EntityReferences now
    //# so, just skip the character
    // Throw(SXmlEntityReferencesNotImplemented);

    Result := TEntityType.Skipped;
  end;
end;

//# Parses a chunk of text starting at ps.CharPos.
//#   startPos .... start position of the text chunk that has been parsed (can differ from ps.CharPos before the call)
//#   endPos ...... end position of the text chunk that has been parsed (can differ from ps.CharPos after the call)
//#   ourOrChars .. all parsed character bigger or equal to 0x20 or-ed (|) into a single int. It can be used for whitespace detection
//#                 (the text has a non-whitespace character if outOrChars > 0x20).
//# Returns true when the whole value has been parsed. Return false when it needs to be called again to get a next chunk of value.
function TACLXMLTextReader.ParseText(out AStartPosition, AEndPosition: Integer; var AOutOrChars: Integer): Boolean;
label
  NoValue, LblReadData, ReturnPartialValue;
var
  AChars: TCharArray;
  APosition, ARcount, ARpos, AOrChars, ACharRefEndPos, ACharCount, AOffset: Integer;
  AEntityType: TEntityType;
  C, ACh: Char;
begin
  AChars := FParsingState.Chars;
  APosition := FParsingState.CharPos;
  ARcount := 0;
  ARpos := -1;
  AOrChars := AOutOrChars;

  while True do
  begin
    //# parse text content

    //# C# unsafe section
    repeat
      C := AChars[APosition];
      if TACLXMLCharType.CharProperties[C] and TACLXMLCharType.Text = 0 then
        Break;
      AOrChars := AOrChars or Ord(C);
      Inc(APosition);
    until False;

    case C of
      #$0009:
        begin
          Inc(APosition);
          Continue;
        end;
      #$000A: //# eol
        begin
          Inc(APosition);
          OnNewLine(APosition);
          Continue;
        end;
      #$000D:
        begin
          if AChars[APosition + 1] = #$000A then
          begin
            if not FParsingState.EolNormalized and (FParsingMode = TParsingMode.Full) then
            begin
              if APosition - FParsingState.CharPos > 0 then
              begin
                if ARcount = 0 then
                begin
                  ARcount := 1;
                  ARpos := APosition;
                end
                else
                begin
                  ShiftBuffer(ARpos + ARcount, ARpos, APosition - ARpos - ARcount);
                  ARpos := APosition - ARcount;
                  Inc(ARcount);
                end;
              end
              else
                Inc(FParsingState.CharPos);
            end;
            Inc(APosition, 2);
          end
          else
            if (APosition + 1 < FParsingState.CharsUsed) or (FParsingState.IsEof) then
            begin
              if not FParsingState.EolNormalized then
                AChars[APosition] := #$000A;
              Inc(APosition);
            end
            else
              goto LblReadData;
          OnNewLine(APosition);
          Continue;
        end;
      '<': //# some tag
        goto ReturnPartialValue;
      '&': //# entity reference
        begin
          //# try to parse char entity inline
          ACharRefEndPos := ParseCharRefInline(APosition, ACharCount, AEntityType);
          if ACharRefEndPos > 0 then
          begin
            if ARcount > 0 then
              ShiftBuffer(ARpos + ARcount, ARpos, APosition - ARpos - ARcount);

            ARpos := APosition - ARcount;
            Inc(ARcount, ACharRefEndPos - APosition - ACharCount);
            APosition := ACharRefEndPos;

            if not TACLXMLCharType.IsWhiteSpace(AChars[ACharRefEndPos - ACharCount]) then
              AOrChars := AOrChars or $FF;
          end
          else
          begin
            if APosition > FParsingState.CharPos then
              goto ReturnPartialValue;

            case HandleEntityReference(False, TEntityExpandType.All, APosition) of
              //# Needed only for XmlTextReader (reporting of entities)
              TEntityType.CharacterDec,
              TEntityType.CharacterHex,
              TEntityType.CharacterNamed:
                if not TACLXMLCharType.IsWhiteSpace(FParsingState.Chars[APosition - 1]) then
                  AOrChars := AOrChars or $FF;
              TEntityType.Unexpanded:
                begin
                  // make sure we will report EntityReference after the text node
                  FNextParsingFunction := FParsingFunction;
                  FParsingFunction := TParsingFunction.EntityReference;
                  // end the value (returns nothing)
                  goto NoValue;
                end;
            else
              APosition := FParsingState.CharPos + 1; // +1 т.к. EntityReferencesNotImplemented
            end;
            AChars := FParsingState.Chars;
          end;
          Continue;
        end;

      ']':
        begin
          if (FParsingState.CharsUsed - APosition < 3) and not FParsingState.IsEof then
            goto LblReadData;

          if (AChars[APosition + 1] = ']') and (AChars[APosition + 2] = '>') then
            Throw(APosition, SXmlCDATAEndInText, '');
          AOrChars := AOrChars or Ord(']');
          Inc(APosition);
          Continue;
        end;
      else
      //# end of buffer
      begin
        if APosition = FParsingState.CharsUsed then
          goto LblReadData
        else
        begin
          ACh := AChars[APosition];
          if TACLXMLCharType.IsHighSurrogate(ACh) then
          begin
            if APosition + 1 = FParsingState.CharsUsed then
              goto LblReadData;
            Inc(APosition);
            if TACLXMLCharType.IsLowSurrogate(AChars[APosition]) then
            begin
              Inc(APosition);
              AOrChars := AOrChars or Ord(ACh);
              Continue;
            end;
          end;
          AOffset := APosition - FParsingState.CharPos;
          ThrowInvalidChar(FParsingState.Chars, FParsingState.CharsUsed, FParsingState.CharPos + AOffset);
          Break;
        end;
      end;
    end;

LblReadData:
    if APosition > FParsingState.CharPos then
      goto ReturnPartialValue;

    if ReadData = 0 then
    begin
      if FParsingState.CharsUsed - FParsingState.CharPos > 0 then
      begin
        if (FParsingState.Chars[FParsingState.CharPos] <> Char($D)) and (FParsingState.Chars[FParsingState.CharPos] <> ']') then
          Throw(SXmlUnexpectedEOF1);
        Assert(FParsingState.IsEof);
      end
      else
      begin
        Break;
      end;
    end;
    APosition := FParsingState.CharPos;
    AChars := FParsingState.Chars;
  end;

NoValue:
  //# returns nothing
  AStartPosition := APosition;
  AEndPosition := APosition;
  Exit(True);

ReturnPartialValue:
  if (FParsingMode = TParsingMode.Full) and (ARcount > 0) then
    ShiftBuffer(ARpos + ARcount, ARpos, APosition - ARpos - ARcount);

  AStartPosition := FParsingState.CharPos;
  AEndPosition := APosition - ARcount;
  FParsingState.CharPos := APosition;
  AOutOrChars := AOrChars;
  Result := C = '<';
end;

function TACLXMLTextReader.ParseUnexpectedToken(APosition: Integer): string;
begin
  FParsingState.CharPos := APosition;
  Result := ParseUnexpectedToken;
end;

function TACLXMLTextReader.ParseUnexpectedToken: string;
var
  APosition: Integer;
begin
  if FParsingState.CharPos = FParsingState.CharsUsed then
    Exit('');
  if TACLXMLCharType.IsNCNameSingleChar(FParsingState.Chars[FParsingState.CharPos]) then
  begin
    APosition := FParsingState.CharPos + 1;
    while TACLXMLCharType.IsNCNameSingleChar(FParsingState.Chars[APosition]) do
      Inc(APosition);
    SetString(Result, PChar(@FParsingState.Chars[FParsingState.CharPos]), APosition - FParsingState.CharPos);
  end
  else
  begin
    Assert(FParsingState.CharPos < FParsingState.CharsUsed);
    SetString(Result, PChar(@FParsingState.Chars[FParsingState.CharPos]), 1);
  end;
end;

{ TACLXMLTextReader }

function TACLXMLTextReader.ParseXmlDeclaration(AIsTextDecl: Boolean): Boolean;

  procedure ThrowTextDecl;
  begin
    Throw(IfThen(AIsTextDecl, SXmlInvalidTextDecl, SXmlInvalidXmlDecl));
  end;

label
  NoXmlDecl, LblReadData, LblContinue;
var
  ASb: TACLStringBuilder;
  AXmlDeclState, AOriginalSbLen, AWsCount, ANameEndPos, APosition: Integer;
  AEncoding: TEncoding;
  AEncodingName: string;
  ABadVersion: string;
  AAttr: TACLXMLNodeData;
  AQuoteChar: Char;
  AChars: TCharArray;
begin
  while FParsingState.CharsUsed - FParsingState.CharPos < 6 do
    if ReadData = 0 then
      goto NoXmlDecl;

  if (not StrEqual(FParsingState.Chars, FParsingState.CharPos, 5, XmlDeclarationBeginning)) or
    (TACLXMLCharType.IsNameSingleChar(FParsingState.Chars[FParsingState.CharPos + 5])) then
    goto NoXmlDecl;

  if not AIsTextDecl then
  begin
    FCurrentNode.LineInfo.Init(FParsingState.LineNo, FParsingState.LinePos + 2);
    FCurrentNode.SetNamedNode(TACLXMLNodeType.XmlDeclaration, Xml, acEmptyStr, Xml);
  end;
  Inc(FParsingState.CharPos, 5);

  Assert((FStringBuilder.Length = 0) or AIsTextDecl);
  if AIsTextDecl then
    ASb := TACLStringBuilder.Create
  else
    ASb := FStringBuilder;

  AXmlDeclState := 0;
  AEncoding := nil;

  while True do
  begin
    AOriginalSbLen := ASb.Length;
    if AXmlDeclState = 0 then
      AWsCount := EatWhitespaces(nil)
    else
      AWsCount := EatWhitespaces(ASb);

    if FParsingState.Chars[FParsingState.CharPos] = '?' then
    begin
      ASb.Length := AOriginalSbLen;

      if FParsingState.Chars[FParsingState.CharPos + 1] = '>' then
      begin
        if AXmlDeclState = 0 then
          ThrowTextDecl;

        Inc(FParsingState.CharPos, 2);
        if not AIsTextDecl then
        begin
          FCurrentNode.SetValue(ASb.ToString);
          ASb.Length := 0;

          FNextParsingFunction := FParsingFunction;
          FParsingFunction := TParsingFunction.ResetAttributesRootLevel;
        end;

        if AEncoding = nil then
        begin
          if AIsTextDecl then
            Throw(SXmlInvalidTextDecl);
          SwitchEncodingAfterResetState;
        end
        else
          SwitchEncoding(AEncoding);
        FParsingState.AppendMode := False;
        Exit(True);
      end
      else
        if FParsingState.CharPos + 1 = FParsingState.CharsUsed then
          goto LblReadData
        else
          ThrowUnexpectedToken(#$27'>'#$27);
    end;

    if (AWsCount = 0) and (AXmlDeclState <> 0) then
      ThrowUnexpectedToken('?>');

    ANameEndPos := ParseName;

    AAttr := nil;
    case FParsingState.Chars[FParsingState.CharPos] of
      'v':
        begin
          if StrEqual(FParsingState.Chars, FParsingState.CharPos, ANameEndPos - FParsingState.CharPos, 'version') and (AXmlDeclState = 0) then
          begin
            if not AIsTextDecl then
              AAttr := AddAttributeNoChecks('version', 1);
          end
          else
            ThrowTextDecl;
        end;
      'e':
        begin
          if StrEqual(FParsingState.Chars, FParsingState.CharPos, ANameEndPos - FParsingState.CharPos, 'encoding') and ((AXmlDeclState = 1) or ((AIsTextDecl and (AXmlDeclState = 0)))) then
          begin
            if not AIsTextDecl then
              AAttr := AddAttributeNoChecks('encoding', 1);
            AXmlDeclState := 1;
          end
          else
            ThrowTextDecl;
        end;
      's':
        begin
          if StrEqual(FParsingState.Chars, FParsingState.CharPos, ANameEndPos - FParsingState.CharPos, 'standalone') and ((AXmlDeclState = 1) or (AXmlDeclState = 2)) and not AIsTextDecl then
          begin
            if not AIsTextDecl then
              AAttr := AddAttributeNoChecks('standalone', 1);
            AXmlDeclState := 2;
          end
          else
            ThrowTextDecl;
        end;
      else
        ThrowTextDecl;
    end;
    if not AIsTextDecl then
      AAttr.LineInfo.Init(FParsingState.LineNo, FParsingState.LinePos);
    ASb.Append(FParsingState.Chars, FParsingState.CharPos, ANameEndPos - FParsingState.CharPos);
    FParsingState.CharPos := ANameEndPos;

    if FParsingState.Chars[FParsingState.CharPos] <> '=' then
    begin
      EatWhitespaces(ASb);
      if FParsingState.Chars[FParsingState.CharPos] <> '=' then
        ThrowUnexpectedToken('=');
    end;
    ASb.Append('=');
    Inc(FParsingState.CharPos);

    AQuoteChar := FParsingState.Chars[FParsingState.CharPos];
    if (AQuoteChar <> '"') and (AQuoteChar <> #$27) then
    begin
      EatWhitespaces(ASb);
      AQuoteChar := FParsingState.Chars[FParsingState.CharPos];
      if (AQuoteChar <> '"') and (AQuoteChar <> #$27) then
        ThrowUnexpectedToken('"', #$27);
    end;
    ASb.Append(AQuoteChar);
    Inc(FParsingState.CharPos);
    if not AIsTextDecl then
    begin
      AAttr.QuoteChar := AQuoteChar;
      AAttr.LineInfo2.Init(FParsingState.LineNo, FParsingState.LinePos);
    end;
    APosition := FParsingState.CharPos;

LblContinue:
    AChars := FParsingState.Chars;

    //# C# unsafe section
    while ((TACLXMLCharType.CharProperties[AChars[APosition]] and TACLXMLCharType.AttrValue) <> 0) do
      Inc(APosition);

    if FParsingState.Chars[APosition] = AQuoteChar then
    begin
      case AXmlDeclState of
        //# version
        0:
          //# VersionNum  ::=  '1.0'        (XML Fourth Edition and earlier)
          if StrEqual(FParsingState.Chars, FParsingState.CharPos, APosition - FParsingState.CharPos, '1.0') then
          begin
            if not AIsTextDecl then
              AAttr.SetValue(FParsingState.Chars, FParsingState.CharPos, APosition - FParsingState.CharPos);
            AXmlDeclState := 1;
          end
          else
          begin
            SetString(ABadVersion, PChar(@FParsingState.Chars[FParsingState.CharPos]), APosition - FParsingState.CharPos);
            Throw(SXmlInvalidVersionNumber, ABadVersion);
          end;
        1:
          begin
            SetString(AEncodingName, PChar(@FParsingState.Chars[FParsingState.CharPos]), APosition - FParsingState.CharPos);
            AEncoding := TACLEncodings.Get(AEncodingName);
            if not AIsTextDecl then
              AAttr.SetValue(AEncodingName);
            AXmlDeclState := 2;
          end;
        2:
          begin
            if StrEqual(FParsingState.Chars, FParsingState.CharPos, APosition - FParsingState.CharPos, 'yes') then
              FStandalone := True
            else
              if StrEqual(FParsingState.Chars, FParsingState.CharPos, APosition - FParsingState.CharPos, 'no') then
                FStandalone := False
              else
              begin
                Assert(not AIsTextDecl);
                Throw(SXmlInvalidXmlDecl, FParsingState.LineNo, FParsingState.LinePos - 1);
              end;
            if not AIsTextDecl then
              AAttr.SetValue(FParsingState.Chars, FParsingState.CharPos, APosition - FParsingState.CharPos);
            AXmlDeclState := 3;
          end;
        else
          Assert(False);
      end;
      ASb.Append(AChars, FParsingState.CharPos, APosition - FParsingState.CharPos);
      ASb.Append(AQuoteChar);
      FParsingState.CharPos := APosition + 1;
      Continue;
    end
    else
      if APosition = FParsingState.CharsUsed then
      begin
        if ReadData <> 0 then
          goto LblContinue
        else
          Throw(SXmlUnclosedQuote);
      end
      else
        ThrowTextDecl;

LblReadData:
    if (FParsingState.IsEof) or (ReadData = 0) then
      Throw(SXmlUnexpectedEOF1);
  end;

NoXmlDecl:
  if not AIsTextDecl then
    FParsingFunction := FNextParsingFunction;
  SwitchEncodingAfterResetState;
  FParsingState.AppendMode := False;
  Result := False;
end;

procedure TACLXMLTextReader.ParseXmlDeclarationFragment;
begin
  try
    ParseXmlDeclaration(False);
  except
    on E: EACLXMLException do
      //# 6 == strlen( "<?xml " );
      ReThrow(E, E.LineNumber, E.LinePosition - 6);
  end;
end;

procedure TACLXMLTextReader.SkipDtd;
var
  AColonPos: Integer;
begin
  // parse dtd name
  FParsingState.CharPos := ParseQName(AColonPos);
  // check whitespace
  EatWhitespaces(nil);

  // PUBLIC Id
  if FParsingState.Chars[FParsingState.CharPos] = 'P' then
  begin
    // make sure we have enough characters
    while FParsingState.charsUsed - FParsingState.charPos < 6 do
    begin
      if ReadData = 0 then
        Throw(SXmlUnexpectedEOF1)
    end;
    // check 'PUBLIC'
    if not StrEqual(FParsingState.Chars, FParsingState.CharPos, 6, 'PUBLIC') then
      ThrowUnexpectedToken('PUBLIC');
    Inc(FParsingState.CharPos, 6);

    // check whitespace
    if EatWhitespaces(nil) = 0 then
      ThrowExpectingWhitespace(FParsingState.CharPos);

    // parse PUBLIC value
    SkipPublicOrSystemIdLiteral;

    // check whitespace
    if EatWhitespaces(nil) = 0 then
      ThrowExpectingWhitespace(FParsingState.CharPos);

    // parse SYSTEM value
    SkipPublicOrSystemIdLiteral;

    EatWhitespaces(nil);
  end
  else
    // SYSTEM Value
    if FParsingState.Chars[FParsingState.CharPos] = 'S' then
    begin
      // make sure we have enough characters
      while FParsingState.charsUsed - FParsingState.charPos < 6 do
      begin
        if ReadData = 0 then
          Throw(SXmlUnexpectedEOF1);
      end;

      // check 'SYSTEM'
      if not StrEqual(FParsingState.Chars, FParsingState.CharPos, 6, 'SYSTEM') then
        ThrowUnexpectedToken('SYSTEM');
      Inc(FParsingState.CharPos, 6);

      // check whitespace
      if EatWhitespaces(nil) = 0 then
        ThrowExpectingWhitespace(FParsingState.CharPos);

      // parse SYSTEM value
      SkipPublicOrSystemIdLiteral;

      EatWhitespaces(nil);
    end
    else
      if (FParsingState.Chars[FParsingState.CharPos] <> '[') and
         (FParsingState.Chars[FParsingState.CharPos] <> '>')
      then
        Throw(SXmlExpectExternalOrClose);

  // internal DTD
  if FParsingState.Chars[FParsingState.CharPos] = '[' then
  begin
    Inc(FParsingState.CharPos);
    SkipUntil(']', True);
    EatWhitespaces(nil);
    if FParsingState.Chars[FParsingState.CharPos] <> '>' then
      ThrowUnexpectedToken('>');
  end
  else
    // just close the entry
    if FParsingState.Chars[FParsingState.CharPos] = '>' then
      FCurrentNode.SetValue(acEmptyStr)
    else
      Throw(SXmlExpectSubOrClose);

  Inc(FParsingState.CharPos);
end;

procedure TACLXMLTextReader.SkipPartialTextValue;
var
  AStartPos, AEndPos, AOrChars: Integer;
begin
  Assert(FParsingFunction in [
    TParsingFunction.PartialTextValue,
    TParsingFunction.InReadValueChunk,
    TParsingFunction.InReadContentAsBinary,
    TParsingFunction.InReadElementContentAsBinary]);

  AOrChars := 0;
  FParsingFunction := FNextParsingFunction;
  while not ParseText(AStartPos, AEndPos, AOrChars) do ;
end;

procedure TACLXMLTextReader.SkipPublicOrSystemIdLiteral;
var
  AQuoteChar: Char;
begin
  // check quote char
  AQuoteChar := FParsingState.Chars[FParsingState.CharPos];
  if (AQuoteChar <> '"') and (AQuoteChar <> #39) then
    ThrowUnexpectedToken('", '#39);
  Inc(FParsingState.CharPos);
  SkipUntil(AQuoteChar, False);
end;

procedure TACLXMLTextReader.SkipUntil(AStopChar: Char; ARecognizeLiterals: Boolean);
label
  LblReadData;
var
  AChar: Char;
  AChars: TCharArray;
  AInComment: Boolean;
  AInPI: Boolean;
  AInLiteral: Boolean;
  ALiteralQuote: Char;
  APosition: Integer;
begin
  AInPI := False;
  AInLiteral := False;
  AInComment := False;
  ALiteralQuote := '"';

  AChars := FParsingState.Chars;
  APosition := FParsingState.CharPos;

  repeat

    // fast forward on non-special characters
    repeat
      AChar := AChars[APosition];
      if not TACLXMLCharType.IsAttributeValueChar(AChar) then
        Break;
      if AChar = AStopChar then
        Break;
      if AChar = '-' then
        Break;
      if AChar = '?' then
        Break;
      Inc(APosition);
    until False;

    // Closing stopChar outside of literal and ignore/include sections -> save value & return
    if (Ord(AChar) = Ord(AStopChar)) and not AInLiteral then
    begin
      FParsingState.CharPos := APosition + 1;
      Exit;
    end;

    // handle the special character
    FParsingState.CharPos := APosition;
    case AChar of
      #$A:
        begin
          Inc(APosition);
          OnNewLine(APosition);
          Continue;
        end;

      #$D:
        begin
          if AChars[APosition + 1] = #$A then
            Inc(APosition, 2)
          else
            if (APosition + 1 < FParsingState.CharsUsed) or FParsingState.IsEof then
              Inc(APosition)
            else
              goto LblReadData;

          OnNewLine(APosition);
          Continue;
        end;

      // comment, instruction
      '<':
        begin
          // processing instruction
          if AChars[APosition + 1] = '?' then
          begin
            if ARecognizeLiterals and not AInLiteral and not AInComment then
            begin
              AInPI := True;
              Inc(APosition, 2);
              Continue;
            end;
          end
          else
            // comment
            if AChars[APosition + 1] = '!' then
            begin
              if (APosition + 3 >= FParsingState.CharsUsed) and not FParsingState.IsEof then
                goto LblReadData;
              if (AChars[APosition + 2] = '-') and (AChars[APosition + 3] = '-') then
              begin
                if ARecognizeLiterals and not AInLiteral and AInPI then
                begin
                  AInComment := True;
                  Inc(APosition, 4);
                  Continue;
                end;
              end;
            end
            else // need more data
              if (APosition + 1 >= FParsingState.CharsUsed) and not FParsingState.IsEof then
                goto LblReadData;

          Inc(APosition);
          Continue;
        end;

      '-':
        begin
          // end of comment
          if AInComment then
          begin
            if (APosition + 2 >= FParsingState.CharsUsed) and not FParsingState.IsEof then
              goto LblReadData;
            if (AChars[APosition + 1] = '-') and (AChars[APosition + 2] = '>') then
            begin
              AInComment := False;
              Inc(APosition, 2);
              Continue;
            end;
          end;
          Inc(APosition);
          Continue;
        end;

      '?':
        begin
          // end of processing instruction
          if AInPI then
          begin
            if (APosition + 1 >= FParsingState.CharsUsed) and not FParsingState.IsEof then
              goto LblReadData;
            if (AChars[APosition + 1] = '>') then
            begin
              AInPI := False;
              Inc(APosition);
              Continue;
            end;
          end;
          Inc(APosition);
          Continue;
        end;

      #9, '>', ']', '&':
        begin
          Inc(APosition);
          Continue;
        end;

      '"', '''':
        begin
          if AInLiteral then
          begin
            if Ord(ALiteralQuote) = Ord(AChar) then
              AInLiteral := False;
          end
          else
            if ARecognizeLiterals and not (AInComment or AInPI) then
            begin
              AInLiteral := True;
              ALiteralQuote := AChar;
            end;

          Inc(APosition);
          Continue;
        end;

    else // default handler
      if APosition = FParsingState.CharsUsed then
        goto LblReadData
      else // surrogate chars
      begin
        if TACLXMLCharType.IsHighSurrogate(AChars[APosition]) then
        begin
          if APosition + 1 = FParsingState.CharsUsed then
            goto LblReadData;
          Inc(APosition);
          if TACLXMLCharType.IsLowSurrogate(AChars[APosition]) then
          begin
            Inc(APosition);
            Continue;
          end;
        end;
        ThrowInvalidChar(AChars, FParsingState.CharsUsed, APosition);
        Break;
      end;
    end;

LblReadData:
    // read new characters into the buffer
    if ReadData = 0 then
    begin
      if FParsingState.CharsUsed > FParsingState.CharPos then
      begin
        if Ord(FParsingState.Chars[FParsingState.CharPos]) <> $D then
          Throw(SXmlUnexpectedEOF1);
      end
      else
        Throw(SXmlUnexpectedEOF1);
    end;
    APosition := FParsingState.CharPos;
    AChars := FParsingState.Chars;
  until False;
end;

procedure TACLXMLTextReader.ReThrow(E: Exception; ALineNo, ALinePos: Integer);
begin
  Throw(EACLXMLException.Create(E.Message, nil, ALineNo, ALinePos, ''));
end;

function TACLXMLTextReader.Read: Boolean;
begin
  while True do
  begin
    case FParsingFunction of
      TParsingFunction.ElementContent:
        Exit(ParseElementContent);
      TParsingFunction.DocumentContent:
        Exit(ParseDocumentContent);
      //#remove OpenUrl
      TParsingFunction.SwitchToInteractive:
        begin
          Assert(not FParsingState.AppendMode);
          FReadState := TACLXMLReadState.Interactive;
          FParsingFunction := FNextParsingFunction;
          Continue;
        end;
      TParsingFunction.SwitchToInteractiveXmlDecl:
        begin
          FReadState := TACLXMLReadState.Interactive;
          FParsingFunction := FNextParsingFunction;
          if ParseXmlDeclaration(False) then
            Exit(True);
          Continue;
        end;
      TParsingFunction.ResetAttributesRootLevel:
        begin
          ResetAttributes;
          FCurrentNode := FNodes[FIndex];
          if (FIndex = 0) then
            FParsingFunction := TParsingFunction.DocumentContent
          else
            FParsingFunction := TParsingFunction.ElementContent;
          Continue;
        end;
      TParsingFunction.MoveToElementContent:
        begin
          ResetAttributes;
          Inc(FIndex);
          FCurrentNode := AddNode(FIndex, FIndex);
          FParsingFunction := TParsingFunction.ElementContent;
          Continue;
        end;
      TParsingFunction.PopElementContext:
        begin
          PopElementContext;
          FParsingFunction := FNextParsingFunction;
          Assert(FParsingFunction in [TParsingFunction.ElementContent, TParsingFunction.DocumentContent]);
          Continue;
        end;
      TParsingFunction.PopEmptyElementContext:
        begin
          FCurrentNode := FNodes[FIndex];
          Assert(FCurrentNode.&Type = TACLXMLNodeType.Element);
          FCurrentNode.IsEmptyElement := False;
          ResetAttributes;
          PopElementContext;
          FParsingFunction := FNextParsingFunction;
          Continue;
        end;
      TParsingFunction.XmlDeclarationFragment:
        begin
          ParseXmlDeclarationFragment;
          FParsingFunction := TParsingFunction.GoToEof;
          Exit(True);
        end;
      TParsingFunction.GoToEof:
        begin
          OnEof;
          Exit(False);
        end;
      TParsingFunction.Error,
      TParsingFunction.Eof,
      TParsingFunction.ReaderClosed:
        Exit(False);
      TParsingFunction.NoData:
        begin
          ThrowWithoutLineInfo(SXmlMissingRoot, '');
          Exit(False);
        end;
      TParsingFunction.PartialTextValue:
        begin
          SkipPartialTextValue;
          Continue;
        end;
      else
        Assert(False);
    end;
  end;
end;

//# Reads more data to the character buffer, discarding already parsed chars / decoded bytes.
function TACLXMLTextReader.ReadData: Integer;
var
  ACharsRead, I, ACopyCharsCount, ABytesLeft, ARead, AOriginalBytePos, ACharsLen: Integer;
  ABytesRead: Integer;
begin
  //# Append Mode:  Append new bytes and characters to the buffers, do not rewrite them. Allocate new buffers
  //#               if the current ones are full
  //# Rewrite Mode: Reuse the buffers. If there is less than half of the char buffer left for new data, move
  //#               the characters that has not been parsed yet to the front of the buffer. Same for bytes.
  if FParsingState.IsEof then
    Exit(0);

  if FParsingState.AppendMode then
  begin
    //# the character buffer is full -> allocate a new one
    if FParsingState.CharsUsed = Length(FParsingState.Chars) - 1 then
    begin
      //# invalidate node values kept in buffer - applies to attribute values only
      for I := 0 to FAttributeCount - 1 do
        FNodes[FIndex + I + 1].OnBufferInvalidated;
      SetLength(FParsingState.Chars, Length(FParsingState.Chars) * 2);
    end;

    if FParsingState.Stream <> nil then
      //# the byte buffer is full -> allocate a new one
      if FParsingState.BytesUsed - FParsingState.BytePos < MaxByteSequenceLen then
        if Length(FParsingState.Bytes) - FParsingState.BytesUsed < MaxByteSequenceLen then
          SetLength(FParsingState.Bytes, Length(FParsingState.Bytes) * 2);

    ACharsRead := Length(FParsingState.Chars) - FParsingState.CharsUsed - 1;
    if ACharsRead > ApproxXmlDeclLength then
      ACharsRead := ApproxXmlDeclLength;
  end
  else
  begin
    ACharsLen := Length(FParsingState.Chars);
    if ACharsLen - FParsingState.CharsUsed <= ACharsLen div 2 then
    begin
      //# invalidate node values kept in buffer - applies to attribute values only
      for I := 0 to FAttributeCount - 1 do
        FNodes[FIndex + I + 1].OnBufferInvalidated;
      //# move unparsed characters to front, unless the whole buffer contains unparsed characters
      ACopyCharsCount := FParsingState.CharsUsed - FParsingState.CharPos;
      if ACopyCharsCount < ACharsLen - 1 then
      begin
        FParsingState.LineStartPos := FParsingState.LineStartPos - FParsingState.CharPos;
        if ACopyCharsCount > 0 then
          FastMove(FParsingState.Chars[FParsingState.CharPos], FParsingState.Chars[0], ACopyCharsCount * SizeOf(Char));
        FParsingState.CharPos := 0;
        FParsingState.CharsUsed := ACopyCharsCount;
      end
      else
        SetLength(FParsingState.Chars, Length(FParsingState.Chars) * 2);
    end;

    if FParsingState.Stream <> nil then
    begin
      //# move undecoded bytes to the front to make some space in the byte buffer
      ABytesLeft := FParsingState.BytesUsed - FParsingState.BytePos;
      if ABytesLeft <= MaxBytesToMove then
      begin
        if ABytesLeft = 0 then
          FParsingState.BytesUsed := 0
        else
        begin
          FastMove(FParsingState.Bytes[FParsingState.BytePos], FParsingState.Bytes[0], ABytesLeft);
          FParsingState.BytesUsed := ABytesLeft;
        end;
        FParsingState.BytePos := 0;
      end;
    end;
    ACharsRead := Length(FParsingState.Chars) - FParsingState.CharsUsed - 1;
  end;

  if FParsingState.Stream <> nil then
  begin
    if not FParsingState.IsStreamEof then
    begin
      ABytesRead := Length(FParsingState.Bytes) - FParsingState.BytesUsed;
//#      if {(FParsingState.BytePos = FParsingState.BytesUsed) and} (ABytesRead > 0) then
      if ABytesRead > 0 then
      begin
//#        if FParsingState.Decoder.ClassType = TUTF8Encoding then
//#        begin
//#          //# Ensure that we don't split encoded character on reading
//#          Assert(ABytesRead >= MaxUTF8EncodedCharByteCount);
//#          Dec(ABytesRead, MaxUTF8EncodedCharByteCount - 1);
//#          ARead := FParsingState.Stream.Read(FParsingState.Bytes[FParsingState.BytesUsed], ABytesRead);
//#          if ARead > 0 then
//#          begin
//#            ABytesRead := GetRemainingUTF8EncodedCharacterByteCount(@FParsingState.Bytes[FParsingState.BytesUsed], ARead);
//#            if ABytesRead > 0 then
//#            begin
//#              Inc(FParsingState.BytesUsed, ARead);
//#              ARead := FParsingState.Stream.Read(FParsingState.Bytes[FParsingState.BytesUsed], ABytesRead);
//#            end;
//#          end;
//#        end
//#        else
        ARead := FParsingState.Stream.Read(FParsingState.Bytes[FParsingState.BytesUsed], ABytesRead);

        if ARead = 0 then
          FParsingState.IsStreamEof := True;
        Inc(FParsingState.BytesUsed, ARead);
      end;
    end;

    AOriginalBytePos := FParsingState.BytePos;

    ACharsRead := GetChars(ACharsRead);
    if (ACharsRead = 0) and (FParsingState.BytePos <> AOriginalBytePos) then
      Exit(ReadData);
  end
  else
    ACharsRead := 0;

  RegisterConsumedCharacters(ACharsRead);

  if ACharsRead = 0 then
  begin
    Assert(FParsingState.CharsUsed < Length(FParsingState.Chars));
    FParsingState.IsEof := True;
  end;
  FParsingState.Chars[FParsingState.CharsUsed] := #$0000;
  Result := ACharsRead;
end;

procedure TACLXMLTextReader.RegisterConsumedCharacters(ACharacters: Int64);
var
  ANewCharactersInDocument: Int64;
begin
  Assert(ACharacters >= 0);
  if FMaxCharactersInDocument > 0 then
  begin
    ANewCharactersInDocument := FCharactersInDocument + ACharacters;
    if ANewCharactersInDocument < FCharactersInDocument then
      ThrowWithoutLineInfo(SXmlLimitExceeded, 'MaxCharactersInDocument')
    else
      FCharactersInDocument := ANewCharactersInDocument;
    if FCharactersInDocument > FMaxCharactersInDocument then
      ThrowWithoutLineInfo(SXmlLimitExceeded, 'MaxCharactersInDocument');
  end;
end;

procedure TACLXMLTextReader.ResetAttributes;
begin
  if FFullAttributeCleanup then
    FullAttributeCleanup;
  FCurrentAttributeIndex := -1;
  FAttributeCount := 0;
  FAttributeHashTable := 0;
  FAttributeDuplicateWalkCount := 0;
end;

procedure TACLXMLTextReader.SetErrorState;
begin
  FParsingFunction := TParsingFunction.Error;
  FReadState := TACLXMLReadState.Error;
end;

procedure TACLXMLTextReader.SetupEncoding(AEncoding: TEncoding);
begin
  if AEncoding = nil then
  begin
    Assert(FParsingState.CharPos = 0);
    FParsingState.Encoding := TEncoding.UTF8;
    FParsingState.Decoder := TEncoding.ASCII;
  end
  else
  begin
    FParsingState.Encoding := AEncoding;
    if ContainsStr(TACLEncodings.WebName(AEncoding), 'utf-16') then
      FParsingState.Decoder := TEncoding.Unicode
    else
      FParsingState.Decoder := AEncoding;
  end;
end;

procedure TACLXMLTextReader.SwitchEncoding(ANewEncoding: TEncoding);
begin
  if (FParsingState.Decoder = TEncoding.ASCII) and not FAfterResetState or
    (TACLEncodings.WebName(ANewEncoding) <> TACLEncodings.WebName(FParsingState.Encoding)) then
  begin
    Assert(FParsingState.Stream <> nil);
    UnDecodeChars;
    FParsingState.AppendMode := False;
    SetupEncoding(ANewEncoding);
    ReadData;
  end;
end;

procedure TACLXMLTextReader.SwitchEncodingAfterResetState;
var
  AEncodingName: string;
begin
  if FAfterResetState then
  begin
    AEncodingName := TACLEncodings.WebName(FParsingState.Encoding);
    if (AEncodingName <> 'utf-8') and (AEncodingName <> 'utf-16') and (AEncodingName <> 'utf-16be') and
      not (FParsingState.Encoding is TMBCSEncoding)
    then
      Throw(SXmlEncodingSwitchAfterResetState, IfThen(FParsingState.Encoding.GetByteCount('A') = 1, 'UTF-8', 'UTF-16'));
  end;
  if FParsingState.Decoder = TEncoding.ASCII then
    SwitchEncodingToUTF8;
end;

procedure TACLXMLTextReader.SwitchEncodingToUTF8;
begin
  SwitchEncoding(TEncoding.UTF8);
end;

procedure TACLXMLTextReader.Throw(const ARes: string);
begin
  Throw(ARes, '');
end;

procedure TACLXMLTextReader.Throw(const ARes: string; ALineNo, ALinePos: Integer);
begin
  Throw(EACLXMLException.Create(ARes, '', ALineNo, ALinePos, ''));
end;

procedure TACLXMLTextReader.Throw(const ARes, AArg: string);
begin
  Throw(EACLXMLException.Create(ARes, AArg, FParsingState.LineNo, FParsingState.LinePos, ''));
end;

procedure TACLXMLTextReader.ThrowUnclosedElements;
var
  I: Integer;
  AElement: TACLXMLNodeData;
begin
  if (FIndex = 0) and (FCurrentNode.&Type <> TACLXMLNodeType.Element) then
    Throw(FParsingState.CharsUsed, SXmlUnexpectedEOF1, '')
  else
  begin
    if (FParsingFunction = TParsingFunction.InIncrementalRead) then
      I := FIndex
    else
      I := FIndex - 1;
    FStringBuilder.Length := 0;
    while I >= 0 do
    begin
      AElement := FNodes[I];
      if AElement.&Type <> TACLXMLNodeType.Element then
        Continue;
      FStringBuilder.Append(AElement.GetNameWPrefix(FNameTable));
      if I > 0 then
        FStringBuilder.Append(', ')
      else
        FStringBuilder.Append('.');
      Dec(I);
    end;
    Throw(FParsingState.CharsUsed, SXmlUnexpectedEOFInElementContent, FStringBuilder.ToString);
  end;
end;

procedure TACLXMLTextReader.ThrowUnexpectedToken(APosition: Integer; const AExpectedToken1, AExpectedToken2: string);
begin
  FParsingState.CharPos := APosition;
  ThrowUnexpectedToken(AExpectedToken1, AExpectedToken2);
end;

procedure TACLXMLTextReader.ThrowUnexpectedToken(const AExpectedToken1, AExpectedToken2: string);
var
  AUnexpectedToken: string;
begin
  AUnexpectedToken := ParseUnexpectedToken;
  if AUnexpectedToken = '' then
    Throw(SXmlUnexpectedEOF1);
  if AExpectedToken2 <> '' then
    Throw(SXmlUnexpectedTokens2, [AUnexpectedToken, AExpectedToken1, AExpectedToken2])
  else
    Throw(SXmlUnexpectedTokenEx, [AUnexpectedToken, AExpectedToken1]);
end;

procedure TACLXMLTextReader.ThrowWithoutLineInfo(const ARes, AArg: string);
begin
  Throw(EACLXMLException.Create(ARes, AArg, ''));
end;

procedure TACLXMLTextReader.UnDecodeChars;
begin
  Assert(((FParsingState.Stream <> nil) and (FParsingState.Decoder <> nil)) and (FParsingState.Bytes <> nil));
  Assert(FParsingState.AppendMode, 'UnDecodeChars cannot be called after ps.appendMode has been changed to false');

  Assert(FParsingState.CharsUsed >= FParsingState.CharPos, 'The current position must be in the valid character range.');
  if FMaxCharactersInDocument > 0 then
  begin
//# We're returning back in the input (potentially) so we need to fixup
//#   the character counters to avoid counting some of them twice.
//# The following code effectively rolls-back all decoded characters
//#   after the ps.CharPos (which typically points to the first character
//#   after the XML decl).
    Assert(FCharactersInDocument >= FParsingState.CharsUsed - FParsingState.CharPos,
      'We didn'#$27't correctly count some of the decoded characters against the MaxCharactersInDocument.');
    FCharactersInDocument := FCharactersInDocument - FParsingState.CharsUsed - FParsingState.CharPos;
  end;
//# byte position after preamble
  FParsingState.BytePos := FDocumentStartBytePos;
  if FParsingState.CharPos > 0 then
    Inc(FParsingState.BytePos, FParsingState.Encoding.GetByteCount(FParsingState.Chars, 0, FParsingState.CharPos));
  FParsingState.CharsUsed := FParsingState.CharPos;
  FParsingState.IsEof := False;
end;

{ TACLXMLTextReader.TXmlContext }

constructor TACLXMLTextReader.TXmlContext.Create(APreviousContext: TXmlContext);
begin
  inherited Create;
  XmlSpace := APreviousContext.XmlSpace;
  XmlLang := APreviousContext.XmlLang;
  DefaultNamespace := APreviousContext.DefaultNamespace;
  PreviousContext := APreviousContext;
end;

procedure TACLXMLTextReader.Throw(APosition: Integer; const ARes, AArg: string);
begin
  FParsingState.CharPos := APosition;
  Throw(ARes, AArg);
end;

procedure TACLXMLTextReader.Throw(E: Exception);
var
  AXmlEx: EACLXMLException;
begin
  SetErrorState;
  AXmlEx := E as EACLXMLException;
  if AXmlEx <> nil then
    FCurrentNode.LineInfo.Init(AXmlEx.LineNumber, AXmlEx.LinePosition);
  raise E;
end;

procedure TACLXMLTextReader.ThrowExpectingWhitespace(APosition: Integer);
var
  AUnexpectedToken: string;
begin
  AUnexpectedToken := ParseUnexpectedToken(APosition);
  if AUnexpectedToken = '' then
    Throw(APosition, SXmlUnexpectedEOF1, '')
  else
    Throw(APosition, SXmlExpectingWhiteSpace, AUnexpectedToken);
end;

procedure TACLXMLTextReader.ThrowInvalidChar(const AData: TCharArray; ALength, AInvCharPos: Integer);
begin
  Throw(AInvCharPos, SXmlInvalidCharacter, EACLXMLException.BuildCharExceptionArgs(AData, ALength, AInvCharPos));
end;

procedure TACLXMLTextReader.Throw(const ARes: string; const AArgs: array of const);
begin
  Throw(EACLXMLException.Create(ARes, AArgs, FParsingState.LineNo, FParsingState.LinePos, ''));
end;

procedure TACLXMLTextReader.ThrowTagMismatch(AStartTag: TACLXMLNodeData);
var
  AColonPos, AEndPos: Integer;
  AArg0, AArg1, AArg2, AArg3: string;
begin
  if AStartTag.&Type = TACLXMLNodeType.Element then
  begin
    //# parse the bad name
    AEndPos := ParseQName(AColonPos);
    AArg0 := AStartTag.GetNameWPrefix(FNameTable);
    AArg1 := IntToStr(AStartTag.LineInfo.LineNo);
    AArg2 := IntToStr(AStartTag.LineInfo.LinePos);
    SetString(AArg3, PChar(@FParsingState.Chars[FParsingState.CharPos]), AEndPos - FParsingState.CharPos);
    Throw(SXmlTagMismatchEx, [AArg0, AArg1, AArg2, AArg3]);
  end
  else
  begin
    Assert(AStartTag.&Type = TACLXMLNodeType.EntityReference);
    Throw(SXmlUnexpectedEndTag);
  end;
end;

procedure TACLXMLTextReader.Throw(const ARes, AArg: string; ALineNo, ALinePos: Integer);
begin
  Throw(EACLXMLException.Create(ARes, AArg, ALineNo, ALinePos, ''));
end;

procedure TACLXMLTextReader.Throw(APosition: Integer; const ARes: string; const AArgs: array of const);
begin
  FParsingState.CharPos := APosition;
  Throw(ARes, AArgs);
end;

procedure TACLXMLTextReader.Throw(APosition: Integer; const ARes: string; const AArgs: TArray<string>);
var
  AArguments: TArray<TVarRec>;
begin
  SetLength(AArguments, Length(AArgs));
  for var I := Low(AArgs) to High(AArgs) do
  begin
    UnicodeString(AArguments[I].VUnicodeString) := UnicodeString(AArgs[I]);
    AArguments[I].VType := vtUnicodeString;
  end;
  Throw(APosition, ARes, AArguments);
end;

{ TACLXMLNameTable }

destructor TACLXMLNameTable.Destroy;
var
  AItem, ATemp: PItem;
  I: Integer;
begin
  for I := Low(FTable) to High(FTable) do
  begin
    AItem := FTable[I];
    while AItem <> nil do
    begin
      ATemp := AItem;
      AItem := AItem.Next;
      Dispose(ATemp);
    end;
    FTable[I] := nil;
  end;
  inherited Destroy;
end;

function TACLXMLNameTable.Add(const AKey: string): string;
var
  AIndex, AHash: Cardinal;
  AEntry, ATemp: PItem;
begin
  AHash := Hash(PChar(AKey), Length(AKey));
  AIndex := AHash mod TableSize;
  AEntry := FTable[AIndex];
  if AEntry = nil then
  begin
    AEntry := NewItem(AKey, AHash);
    FTable[AIndex] := AEntry;
    Exit(AEntry.Value);
  end
  else
    repeat
      if (AHash = AEntry.Hash) and (AKey = AEntry.Value) then
        Exit(AEntry.Value);

      ATemp := AEntry.Next;
      if ATemp = nil then
      begin
        ATemp := NewItem(AKey, AHash);
        AEntry.Next := ATemp;
        Exit(ATemp.Value);
      end;
      AEntry := ATemp;
    until False;
end;

function TACLXMLNameTable.Add(const AKey: TCharArray; AStart, ALength: Integer): string;
var
  AIndex, AHash: Cardinal;
  AEntry, ATemp: PItem;
begin
  AHash := Hash(@AKey[AStart], ALength);
  AIndex := AHash mod TableSize;
  AEntry := FTable[AIndex];
  if AEntry = nil then
  begin
    AEntry := NewItem(AKey, AStart, ALength, AHash);
    FTable[AIndex] := AEntry;
    Exit(AEntry.Value);
  end
  else
    repeat
      if (AHash = AEntry.Hash) and StrEqual(AKey, AStart, ALength, AEntry.Value) then
        Exit(AEntry.Value);

      ATemp := AEntry.Next;
      if ATemp = nil then
      begin
        ATemp := NewItem(AKey, AStart, ALength, AHash);
        AEntry.Next := ATemp;
        Exit(ATemp.Value);
      end;
      AEntry := ATemp;
    until False;
end;

function TACLXMLNameTable.Get(const AValue: string): string;
var
  AHash: Cardinal;
  AEntry, ATemp: PItem;
begin
  AHash := Hash(PChar(AValue), Length(AValue));
  AEntry := FTable[AHash mod TableSize];
  if AEntry = nil then
    Exit(acEmptyStr);

  repeat
    if (AHash = AEntry.Hash) and (AValue = AEntry.Value) then
      Exit(AEntry.Value);

    ATemp := AEntry.Next;
    if ATemp = nil then
      Exit(acEmptyStr);

    AEntry := ATemp;
  until False;

  Result := acEmptyStr;
end;

function TACLXMLNameTable.Hash(P: PChar; L: Integer): Cardinal;
begin
  Result := 0;
  while L > 0 do
  begin
    Result := ((Result shl 2) or (Result shr (SizeOf(Result) * 8 - 2))) xor Ord(P^);
    Inc(P);
    Dec(L);
  end;
end;

function TACLXMLNameTable.NewItem(const AKey: TCharArray; AStart, ALength: Integer; AHash: Cardinal): PItem;
begin
  Result := NewItem(acMakeString(PChar(@AKey[AStart]), ALength), AHash);
end;

function TACLXMLNameTable.NewItem(const S: string; AHash: Cardinal): PItem;
begin
  New(Result);
  Result.Value := S;
  Result.Hash := AHash;
  Result.Next := nil;
end;

{ TACLXMLTextReader.TParsingState }

procedure TACLXMLTextReader.TParsingState.Clear;
begin
  Chars := nil;
  CharPos := 0;
  CharsUsed := 0;
  Encoding := nil;
  Stream := nil;
  Decoder := nil;
  Bytes := nil;
  BytePos := 0;
  BytesUsed := 0;
  LineNo := 1;
  LineStartPos := -1;
  IsEof := False;
  IsStreamEof := False;
  EolNormalized := True;
end;

function TACLXMLTextReader.TParsingState.LinePos: Integer;
begin
  Result := CharPos - LineStartPos;
end;

{$ENDREGION}

{$REGION 'XML-Loaders'}

{ TACLXMLNodeLoader }

constructor TACLXMLNodeLoader.Create;
begin
  // just became a virtual
end;

destructor TACLXMLNodeLoader.Destroy;
begin
  FreeAndNil(FLoaders);
  inherited;
end;

function TACLXMLNodeLoader.GetLoader(AReader: TACLXMLReader): TACLXMLNodeLoader;
begin
  if FLoaders <> nil then
    Result := FLoaders.GetLoader(AReader)
  else
    Result := nil;
end;

function TACLXMLNodeLoader.GetLoaderFilteredByAttribute(AReader: TACLXMLReader): TACLXMLNodeLoader;
begin
  Result := Self;
end;

function TACLXMLNodeLoader.GetLoaders: TACLXMLNodeLoaders;
begin
  if FLoaders = nil then
    FLoaders := TACLXMLNodeLoaders.Create;
  Result := FLoaders;
end;

procedure TACLXMLNodeLoader.OnAttributes(AContext: TObject; AReader: TACLXMLReader);
begin
  // to nothing
end;

procedure TACLXMLNodeLoader.OnBegin(var AContext: TObject);
begin
  // to nothing
end;

procedure TACLXMLNodeLoader.OnEnd(AContext: TObject);
begin
  // to nothing
end;

procedure TACLXMLNodeLoader.OnText(AContext: TObject; AReader: TACLXMLReader);
begin
  // to nothing
end;

{ TACLXMLNodeLoaders }

constructor TACLXMLNodeLoaders.Create;
begin
  FData := TObjectDictionary<string, THolder>.Create([doOwnsValues]);
end;

destructor TACLXMLNodeLoaders.Destroy;
begin
  FreeAndNil(FData);
  inherited;
end;

procedure TACLXMLNodeLoaders.Add(const ANodeName: string; ALoader: TACLXMLNodeLoader);
begin
  FData.AddOrSetValue(ANodeName, THolder.Create(ALoader));
end;

procedure TACLXMLNodeLoaders.Add(const ANodeName: string; ALoader: TACLXMLNodeLoaderClass);
begin
  FData.AddOrSetValue(ANodeName, THolder.Create(ALoader));
end;

procedure TACLXMLNodeLoaders.Add(const ANodeName: string; AProc: TACLXMLTextLoader);
begin
  Add(ANodeName, TACLXMLNodeTextLoader.Create(AProc));
end;

procedure TACLXMLNodeLoaders.Add(const ANamespace, ANodeName: string; ALoader: TACLXMLNodeLoaderClass);
begin
  Add(ANamespace + ':' + ANodeName, ALoader);
end;

procedure TACLXMLNodeLoaders.Add(const ANamespace, ANodeName: string; AProc: TACLXMLTextLoader);
begin
  Add(ANamespace + ':' + ANodeName, AProc);
end;

function TACLXMLNodeLoaders.GetLoader(AReader: TACLXMLReader): TACLXMLNodeLoader;
begin
  Result := GetLoader(AReader, AReader.Name);
  if Result = nil then
    Result := GetLoader(AReader, acEmptyStr);
end;

function TACLXMLNodeLoaders.GetLoader(AReader: TACLXMLReader; const AName: string): TACLXMLNodeLoader;
var
  AHolder: THolder;
begin
  if FData.TryGetValue(AName, AHolder) then
    Result := AHolder.Instance.GetLoaderFilteredByAttribute(AReader)
  else
    Result := nil;
end;

{ TACLXMLAttributeFilteredNodeLoader }

procedure TACLXMLAttributeFilteredNodeLoader.AfterConstruction;
begin
  inherited;
  if FAttributeName = '' then
    raise EInvalidOperation.Create(ClassName + ': AttributeName is not specified');
end;

function TACLXMLAttributeFilteredNodeLoader.GetLoader(AReader: TACLXMLReader): TACLXMLNodeLoader;
begin
  Result := nil;
end;

function TACLXMLAttributeFilteredNodeLoader.GetLoaderFilteredByAttribute(AReader: TACLXMLReader): TACLXMLNodeLoader;
begin
  Result := Loaders.GetLoader(AReader, AReader.GetAttribute(FAttributeName));
end;

{ TACLXMLNodeLoaders.THolder }

constructor TACLXMLNodeLoaders.THolder.Create(AClass: TACLXMLNodeLoaderClass);
begin
  FClass := AClass;
end;

constructor TACLXMLNodeLoaders.THolder.Create(AInstance: TACLXMLNodeLoader);
begin
  FInstance := AInstance;
end;

destructor TACLXMLNodeLoaders.THolder.Destroy;
begin
  FreeAndNil(FInstance);
  inherited;
end;

function TACLXMLNodeLoaders.THolder.Instance: TACLXMLNodeLoader;
var
  AInstance: TACLXMLNodeLoader;
begin
  if FInstance = nil then
  begin
    AInstance := FClass.Create;
    if AtomicCmpExchange(Pointer(FInstance), Pointer(AInstance), nil) <> nil then
      AInstance.Free
  end;
  Result := FInstance;
end;

{ TACLXMLDocumentLoader }

constructor TACLXMLDocumentLoader.Create;
begin
  Settings := TACLXMLReaderSettings.Default;
  Settings.IgnoreComments := True;
  Settings.IgnoreWhitespace := True;
  Loaders := TACLXMLNodeLoaders.Create;
end;

destructor TACLXMLDocumentLoader.Destroy;
begin
  FreeAndNil(Loaders);
  inherited;
end;

procedure TACLXMLDocumentLoader.Run(AContext: TObject; AStream: TStream);
var
  AContextStack: TStack<TObject>;
  ALoader: TACLXMLNodeLoader;
  ALoaderStack: TStack<TACLXMLNodeLoader>;
  AReader: TACLXMLReader;

  procedure DoEndElement;
  var
    ALoader: TACLXMLNodeLoader;
  begin
    ALoader := ALoaderStack.Peek;
    if ALoader <> nil then
      ALoader.OnEnd(AContext);
    ALoaderStack.Pop;
    AContext := AContextStack.Pop;
  end;

var
  AIsEmptyElement: Boolean;
begin
  if AStream.Position < AStream.Size then
  begin
    AContextStack := TStack<TObject>.Create;
    ALoaderStack := TStack<TACLXMLNodeLoader>.Create;
    try
      AReader := Settings.CreateReader(AStream);
      try
        AContextStack.Push(AContext);
        while AReader.SafeRead do
          case AReader.NodeType of
            TACLXMLNodeType.EndElement:
              if AReader.Depth >= Ord(SkipRootNode) then
                DoEndElement;

            TACLXMLNodeType.Element:
              if AReader.Depth >= Ord(SkipRootNode) then
              begin
                AIsEmptyElement := AReader.IsEmptyElement;

                if ALoaderStack.Count > 0 then
                begin
                  ALoader := ALoaderStack.Peek;
                  if ALoader <> nil then
                    ALoader := ALoader.GetLoader(AReader);
                end
                else
                  ALoader := Loaders.GetLoader(AReader);

                ALoaderStack.Push(ALoader);
                AContextStack.Push(AContext);
                if ALoader <> nil then
                begin
                  ALoader.OnBegin(AContext);
                  ALoader.OnAttributes(AContext, AReader);
                end;
                if AIsEmptyElement then
                  DoEndElement;
              end;

            TACLXMLNodeType.CDATA,
            TACLXMLNodeType.Text,
            TACLXMLNodeType.SignificantWhitespace:
              if ALoaderStack.Count > 0 then
              begin
                ALoader := ALoaderStack.Peek;
                if ALoader <> nil then
                  ALoader.OnText(AContext, AReader);
              end;
          end;
      finally
        AReader.Free;
      end;
    finally
      AContextStack.Free;
      ALoaderStack.Free;
    end;
  end;
end;

{ TACLXMLNodeTextLoader }

constructor TACLXMLNodeTextLoader.Create(AProc: TACLXMLTextLoader);
begin
  inherited Create;
  FProc := AProc;
end;

procedure TACLXMLNodeTextLoader.OnText(AContext: TObject; AReader: TACLXMLReader);
begin
  FProc(AContext, AReader.Text);
end;

{$ENDREGION}
end.
