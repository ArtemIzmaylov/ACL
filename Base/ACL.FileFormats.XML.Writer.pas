{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*         Stream based XML Writer           *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.FileFormats.XML.Writer;

{$I ACL.Config.inc}
{$SCOPEDENUMS ON}

// Ported from .NET platform:
// https://github.com/microsoft/referencesource/tree/master/System.Xml/System/Xml/Core

interface

uses
  System.Rtti,
  System.Types,
  System.Classes,
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  // ACL
  ACL.Classes,
  ACL.FileFormats.XML.Types;

type
  //# NewLineHandling specifies what will XmlWriter do with new line characters. The options are:
  //# Following table shows what will happen with new line characters in detail:
  //#
  //#                                   |    In text node value   |   In attribute value        |
  //# input to XmlWriter.WriteString()  | \r\n		\n		\r		\t	|	\r\n		\n		\r		\t      |
  //# ------------------------------------------------------------------------------------------|
  //# NewLineHandling.Replace (default)	| \r\n		\r\n	\r\n	\t	|	&#D;&#A;	&#A;	&#D;	&#9;  |
  //# NewLineHandling.Entitize			    | &#D;		\n		&#D;	\t	|	&#D;&#A;	&#A;	&#D;	&#9;  |
  //# NewLineHandling.None				      | \r\n		\n		\r		\t	|	\r\n		\n		\r		\t      |
  //# ------------------------------------------------------------------------------------------|
  //# Specifies how end of line is handled in XmlWriter.

  TACLXMLNewLineHandling = (
    Replace,  //# Replaces all new line characters with XmlWriterSettings.NewLineChars so all new lines are the same; by default NewLineChars are "\r\n"
    Entitize, //# Replaces all new line characters that would be normalized away by a normalizing XmlReader with character entities
    None      //# Does not change the new line characters in input
  );

  TACLXMLStandalone = (Omit, Yes, No); //# Do not change the constants - XmlBinaryWriter depends in it

  TACLXMLNamespaceHandling = (Default, OmitDuplicates);

  TACLXMLWriteState = (
    Start,     //# Nothing has been written yet.
    Prolog,    //# Writing the prolog.
    Element,   //# Writing a the start tag for an element.
    Attribute, //# Writing an attribute value.
    Content,   //# Writing element content.
    Closed,    //# XmlWriter is closed; Close has been called.
    Error      //# Writer is in error state.
  );

  { TACLXMLWriterSettings }

  TACLXMLWriterSettings = class
  strict private
    FAutoXmlDeclaration: Boolean;
    FCheckCharacters: Boolean;
    FConformanceLevel: TACLXMLConformanceLevel;
    FEncodeInvalidXmlCharAsUCS2: Boolean;
    FIndent: Boolean;
    FIndentChars: string;
    FMergeCDataSections: Boolean;
    FNamespaceHandling: TACLXMLNamespaceHandling;
    FNewLineChars: string;
    FNewLineHandling: TACLXMLNewLineHandling;
    FNewLineOnAttributes: Boolean;
    FNewLineOnNode: Boolean;
    FOmitXmlDeclaration: Boolean;
    FStandalone: TACLXMLStandalone;
    FWriteEndDocumentOnClose: Boolean;
  public
    constructor Create;
    procedure Reset;

    property AutoXmlDeclaration: Boolean read FAutoXmlDeclaration write FAutoXmlDeclaration;
    property CheckCharacters: Boolean read FCheckCharacters write FCheckCharacters;
    property ConformanceLevel: TACLXMLConformanceLevel read FConformanceLevel write FConformanceLevel;
    property EncodeInvalidXmlCharAsUCS2: Boolean read FEncodeInvalidXmlCharAsUCS2 write FEncodeInvalidXmlCharAsUCS2;
    property Indent: Boolean read FIndent write FIndent;
    property IndentChars: string read FIndentChars write FIndentChars;
    property MergeCDataSections: Boolean read FMergeCDataSections write FMergeCDataSections;
    property NamespaceHandling: TACLXMLNamespaceHandling read FNamespaceHandling write FNamespaceHandling;
    property NewLineChars: string read FNewLineChars write FNewLineChars;
    property NewLineHandling: TACLXMLNewLineHandling read FNewLineHandling write FNewLineHandling;
    property NewLineOnAttributes: Boolean read FNewLineOnAttributes write FNewLineOnAttributes;
    property NewLineOnNode: Boolean read FNewLineOnNode write FNewLineOnNode;
    property OmitXmlDeclaration: Boolean read FOmitXmlDeclaration write FOmitXmlDeclaration;
    property Standalone: TACLXMLStandalone read FStandalone write FStandalone;
    property WriteEndDocumentOnClose: Boolean read FWriteEndDocumentOnClose write FWriteEndDocumentOnClose;
  end;

  { TACLXMLWriter }

  TACLXMLWriter = class abstract
  strict private
    FAttrEndPos: Integer;
    FContentPosition: Integer;
    FEncoding: TEncoding;
    FStream: TStream;
  protected
    constructor CreateCore(AStream: TStream);
    function GetWriteState: TACLXMLWriteState; virtual; abstract;
    function GetSettings: TACLXMLWriterSettings; virtual;
    function GetXmlSpace: TACLXMLSpace; virtual;
    function GetXmlLang: string; virtual;
    procedure Write(const ABuffer: string); overload; virtual;
    procedure Write(const ABuffer: TCharArray; AIndex, ALength: Integer); overload; virtual;

    property AttrEndPos: Integer read FAttrEndPos write FAttrEndPos;
    property ContentPosition: Integer read FContentPosition write FContentPosition;
    property Stream: TStream read FStream;
  public
    class function Create(AStream: TStream; ASettings: TACLXMLWriterSettings): TACLXMLWriter; static;
    procedure WriteStartDocument; overload; virtual; abstract;
    procedure WriteStartDocument(AStandalone: Boolean); overload; virtual; abstract;
    procedure WriteEndDocument; virtual; abstract;
    procedure WriteStartElement(const ALocalName, ANs: string); overload;
    procedure WriteStartElement(APrefix: string; const ALocalName: string; ANs: string); overload; virtual;
    procedure WriteStartElement(const ALocalName: string); overload;
    procedure WriteEndElement; overload; virtual; abstract;
    procedure WriteFullEndElement; overload; virtual; abstract;
    procedure WriteAttributeBoolean(const ALocalName: string; AValue: Boolean); overload;
    procedure WriteAttributeBoolean(const APrefix, ALocalName, ANs: string; AValue: Boolean); overload;
    procedure WriteAttributeFloat(const ALocalName: string; AValue: Single); overload;
    procedure WriteAttributeFloat(const APrefix, ALocalName, ANs: string; AValue: Single); overload;
    procedure WriteAttributeInteger(const ALocalName: string; AValue: Integer); overload;
    procedure WriteAttributeInteger(const APrefix, ALocalName, ANs: string; AValue: Integer); overload;
    procedure WriteAttributeInt64(const ALocalName: string; const AValue: Int64); overload;
    procedure WriteAttributeInt64(const APrefix, ALocalName, ANs: string; const AValue: Int64); overload;
    procedure WriteAttributeString(const ALocalName, ANs, AValue: string); overload;
    procedure WriteAttributeString(const ALocalName, AValue: string); overload;
    procedure WriteAttributeString(const APrefix, ALocalName, ANs, AValue: string); overload;
    procedure WriteAttributeString(const APrefix, ALocalName, ANs: string; const AValue: AnsiString); overload;
    procedure WriteAttributeString(const ALocalName: string; const AValue: AnsiString); overload;
    procedure WriteStartAttribute(const ALocalName, ANs: string); overload;
    procedure WriteStartAttribute(APrefix: string; ALocalName: string; ANs: string); overload; virtual; abstract;
    procedure WriteStartAttribute(const ALocalName: string); overload;
    procedure WriteEndAttribute; virtual;
    procedure WriteCData(const AText: string); virtual; abstract;
    procedure WriteComment(const AText: string); virtual; abstract;
    procedure WriteProcessingInstruction(const AName, AText: string); virtual; abstract;
    procedure WriteEntityRef(const AName: string); virtual; abstract;
    procedure WriteCharEntity(ACh: Char); virtual; abstract;
    procedure WriteWhitespace(const AWs: string); virtual; abstract;
    procedure WriteString(const AText: string); overload; virtual;
    procedure WriteString(const AText: AnsiString); overload; virtual;
    procedure WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char); virtual; abstract;
    procedure WriteChars(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer); virtual; abstract;
    procedure WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer); overload; virtual; abstract;
    procedure WriteRaw(const AData: string); overload; virtual; abstract;
    procedure WriteBinHex(const ABuffer: TBytes; AIndex: Integer; ACount: Integer); virtual;
    procedure Close; virtual;
    procedure Flush; virtual;
    function LookupPrefix(const ANs: string): string; virtual; abstract;
    procedure WriteQualifiedName(const ALocalName, ANs: string); overload; virtual;
    procedure WriteValue(const AValue: string); overload; virtual;
    procedure WriteElementString(const ALocalName, AValue: string); overload;
    procedure WriteElementString(const ALocalName, ANs, AValue: string); overload;
    procedure WriteElementString(const APrefix, ALocalName, ANs, AValue: string); overload;
    procedure WriteElementString(const ALocalName: string; const AValue: AnsiString); overload;

    property Encoding: TEncoding read FEncoding;
    property Settings: TACLXMLWriterSettings read GetSettings;
    property WriteState: TACLXMLWriteState read GetWriteState;
    property XmlSpace: TACLXMLSpace read GetXmlSpace;
    property XmlLang: string read GetXmlLang;
  end;

implementation

uses
  System.Character;

const
  SXmlInvalidSurrogatePair =
    'The surrogate pair (%s, %s) is invalid. A high surrogate character (0xD800 - 0xDBFF) must ' +
    'always be paired with a low surrogate character (0xDC00 - 0xDFFF).';
  SXmlCanNotBindToReservedNamespace = 'Cannot bind to the reserved namespace.';
  SXmlCannotStartDocumentOnFragment = 'WriteStartDocument cannot be called on writers created with ConformanceLevel.Fragment.';
  SXmlCannotWriteXmlDecl = 'Cannot write XML declaration. XML declaration can be only at the beginning of the document.';
  SXmlClosedOrError = 'The Writer is closed or in error state.';
  SXmlConformanceLevelFragment = 'Make sure that the ConformanceLevel setting is set to ConformanceLevel.Fragment or ' +
    'ConformanceLevel.Auto if you want to write an XML fragment.';
  SXmlDupXmlDecl = 'Cannot write XML declaration. WriteStartDocument method has already written it.';
  SXmlDupAttributeName = '"%s" is a duplicate attribute name.';
  SXmlEmptyLocalName = 'The empty string is not a valid local name.';
  SXmlEmptyName = 'The empty string is not a valid name.';
  SXmlIndentCharsNotWhitespace = 'XmlWriterSettings.%s can contain only valid XML white space characters when ' +
    'XmlWriterSettings.CheckCharacters and XmlWriterSettings.NewLineOnAttributes are true.';
  SXmlInvalidCharacter = '%s, hexadecimal value %s, is an invalid character.';
  SXmlInvalidNameCharsDetail = 'Invalid name character in "%s". The %d character, hexadecimal value %s, cannot be included in a name.';
  SXmlInvalidCharsInIndent = 'WriterSettings.%s can contain only valid XML text content characters when XmlWriterSettings.CheckCharacters is true. %s';
  SXmlInvalidHighSurrogateChar = 'Invalid high surrogate character (%s). A high surrogate character must have a value from range (0xD800 - 0xDBFF).';
  SXmlInvalidOperation = 'Operation is not valid due to the current state of the object.';
  SXmlInvalidSurrogateMissingLowChar = 'The surrogate pair is invalid. Missing a low surrogate character.';
  SXmlInvalidXmlSpace = '"%s" is an invalid xml:space value.';
  SXmlNamespaceDeclXmlXmlns = 'Prefix "%s" cannot be mapped to namespace name reserved for "xml" or "xmlns".';
  SXmlNonWhitespace = 'Only white space characters should be used.';
  SXmlNoRoot = 'Document does not have a root element.';
  SXmlNoStartTag = 'There was no XML start tag open.';
  SXmlNotImplemented = 'Not implemented.';
  SXmlNotSupported = 'Not supported.';
  SXmlPrefixForEmptyNs = 'Cannot use a prefix with an empty namespace.';
  SXmlRedefinePrefix = 'The prefix "%s" cannot be redefined from "%s" to "%s" within the same start element tag.';
  SXmlUndefNamespace = 'The "%s" namespace is not defined.';
  SXmlWrongToken = 'Token ord=%d in state ord=%d would result in an invalid XML document.';
  SXmlXmlnsPrefix = 'Prefix "xmlns" is reserved for use by XML.';
  SXmlXmlPrefix = 'Prefix "xml" is reserved for use by XML and can be mapped only to namespace name "http://www.w3.org/XML/1998/namespace&quot"';

type
  TACLXMLRawWriter = class;

  { EACLXMLInvalidSurrogatePairException }

  EACLXMLInvalidSurrogatePairException = class(EACLXMLArgumentException)
  public
    constructor Create(const ALowChar, AHighChar: Char);
  end;

  { TACLFastHex }

  TACLFastHex = class
  strict private const
    ByteToHexMap: array[Byte] of string = (
      '00','01','02','03','04','05','06','07','08','09','0a','0b','0c','0d','0e','0f',
      '10','11','12','13','14','15','16','17','18','19','1a','1b','1c','1d','1e','1f',
      '20','21','22','23','24','25','26','27','28','29','2a','2b','2c','2d','2e','2f',
      '30','31','32','33','34','35','36','37','38','39','3a','3b','3c','3d','3e','3f',
      '40','41','42','43','44','45','46','47','48','49','4a','4b','4c','4d','4e','4f',
      '50','51','52','53','54','55','56','57','58','59','5a','5b','5c','5d','5e','5f',
      '60','61','62','63','64','65','66','67','68','69','6a','6b','6c','6d','6e','6f',
      '70','71','72','73','74','75','76','77','78','79','7a','7b','7c','7d','7e','7f',
      '80','81','82','83','84','85','86','87','88','89','8a','8b','8c','8d','8e','8f',
      '90','91','92','93','94','95','96','97','98','99','9a','9b','9c','9d','9e','9f',
      'a0','a1','a2','a3','a4','a5','a6','a7','a8','a9','aa','ab','ac','ad','ae','af',
      'b0','b1','b2','b3','b4','b5','b6','b7','b8','b9','ba','bb','bc','bd','be','bf',
      'c0','c1','c2','c3','c4','c5','c6','c7','c8','c9','ca','cb','cc','cd','ce','cf',
      'd0','d1','d2','d3','d4','d5','d6','d7','d8','d9','da','db','dc','dd','de','df',
      'e0','e1','e2','e3','e4','e5','e6','e7','e8','e9','ea','eb','ec','ed','ee','ef',
      'f0','f1','f2','f3','f4','f5','f6','f7','f8','f9','fa','fb','fc','fd','fe','ff'
    );
  public
    class function Encode(B: Byte): string; overload; static;
    class function Encode(C: Char): string; overload; static;
    class function Encode(C: Char; P: PChar): PChar; overload; static;
    class function Encode(const ASource: TBytes; AOffset, ACount: Integer; var ADest: TCharArray): Integer; overload; static;
  end;

  { TACLXMLRawWriter }

  TACLXMLRawWriter = class abstract (TACLXMLWriter)
  strict private
    FResolver: IGSXMLNamespaceResolver;

    function MakeString(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer): string;
  strict protected
    function GetNamespaceResolver: IGSXMLNamespaceResolver; virtual;
    function GetSupportsNamespaceDeclarationInChunks: Boolean; virtual;
    function GetWriteState: TACLXMLWriteState; override;
    function GetXmlLang: string; override;
    function GetXmlSpace: TACLXMLSpace; override;
    procedure SetNamespaceResolver(const AValue: IGSXMLNamespaceResolver); virtual;
  public
    function LookupPrefix(const ANs: string): string; override;
    procedure OnRootElement(AConformanceLevel: TACLXMLConformanceLevel); virtual;
    procedure StartElementContent; virtual;
    procedure WriteCData(const AText: string); override;
    procedure WriteCharEntity(ACh: Char); override;
    procedure WriteChars(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer); override;
    procedure WriteEndDocument; override;
    procedure WriteEndElement(const APrefix, ALocalName, ANs: string); overload; virtual;
    procedure WriteEndElement; overload; override;
    procedure WriteEndNamespaceDeclaration; virtual;
    procedure WriteFullEndElement(const APrefix, ALocalName, ANs: string); overload; virtual;
    procedure WriteFullEndElement; overload; override;
    procedure WriteNamespaceDeclaration(const APrefix, ANs: string); virtual; abstract;
    procedure WriteQualifiedName(const ALocalName, ANs: string); overload; override;
    procedure WriteQualifiedName(const APrefix, ALocalName, ANs: string); overload; virtual;
    procedure WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer); override;
    procedure WriteRaw(const AData: string); override;
    procedure WriteStartDocument(AStandalone: Boolean); override;
    procedure WriteStartDocument; override;
    procedure WriteStartNamespaceDeclaration(const APrefix: string); virtual;
    procedure WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char); override;
    procedure WriteValue(const AValue: string); override;
    procedure WriteWhitespace(const AWs: string); override;
    procedure WriteXmlDeclaration(AStandalone: TACLXMLStandalone); overload; virtual;
    procedure WriteXmlDeclaration(const AXmldecl: string); overload; virtual;

    property NamespaceResolver: IGSXMLNamespaceResolver read GetNamespaceResolver write SetNamespaceResolver;
    property SupportsNamespaceDeclarationInChunks: Boolean read GetSupportsNamespaceDeclarationInChunks;
  end;

  { TACLXMLEncodedRawTextWriter }

  TACLXMLEncodedRawTextWriter = class(TACLXMLRawWriter)
  public const
    BufferSize  = 1024 * 64; //# Should be greater than default FileStream size (4096), otherwise the FileStream will try to cache the data
    BufferOverflowSize = 32; //# Allow overflow in order to reduce checks when writing out constant size markup
  strict private
    FAttrEndPos: Integer; //# end of the last attribute
    FBufChars: TCharArray;
    FBufLen: Integer;
    FBufPos: Integer;
    FCdataPos: Integer;   //# cdata end position
    FContentPos: Integer; //# element content end position
    FHadDoubleBracket: Boolean;
    FInAttributeValue: Boolean;
    FNestingLevel: Integer;
    FTextPos: Integer;
    FWriteToNull: Boolean;

    //# writer settings
    FAutoXmlDeclaration: Boolean;
    FCheckCharacters: Boolean;
    FEncodeInvalidXmlCharAsUCS2: Boolean;
    FMergeCDataSections: Boolean;
    FNewLineChars: string;
    FNewLineHandling: TACLXMLNewLineHandling;
    FNewLineOnAttributes: Boolean;
    FNewLineOnNode: Boolean;
    FOmitXmlDeclaration: Boolean;
    FStandalone: TACLXMLStandalone;
  protected
    function GetSupportsNamespaceDeclarationInChunks: Boolean; override;
    procedure FlushBuffer; virtual;
    procedure WriteAttributeTextBlock(ASrc: PChar; ASrcEnd: PChar);
    procedure WriteElementTextBlock(ASrc: PChar; ASrcEnd: PChar);
    procedure WriteNewLineAndAlignment(ANestingLevelCorrection: Integer = 0);
    procedure RawText(const S: string); overload;
    procedure RawText(ASrcBegin: PChar; ASrcEnd: PChar); overload;
    procedure WriteRawWithCharChecking(APSrcBegin: PChar; APSrcEnd: PChar);
    procedure WriteCommentOrPi(const AText: string; AStopChar: Char);
    procedure WriteCDataSection(const AText: string);
    class function EncodeSurrogate(ASrc: PChar; ASrcEnd: PChar; ADst: PChar): PChar; static;
    function InvalidXmlChar(ACh: Char; ADst: PChar; AEntitize: Boolean): PChar;
    procedure EncodeChar(var ASrc: PChar; APSrcEnd: PChar; var ADst: PChar);
    function WriteNewLine(ADst: PChar): PChar;
    class function LtEntity(ADst: PChar): PChar; static;
    class function GtEntity(ADst: PChar): PChar; static;
    class function AmpEntity(ADst: PChar): PChar; static;
    class function QuoteEntity(ADst: PChar): PChar; static;
    class function TabEntity(ADst: PChar): PChar; static;
    class function LineFeedEntity(ADst: PChar): PChar; static;
    class function CarriageReturnEntity(ADst: PChar): PChar; static;
    class function CharEntity(ADst: PChar; ACh: Char): PChar; static;
    class function UCS2Entity(ADst: PChar; ACh: Char): PChar; static;
    class function RawStartCData(ADst: PChar): PChar; static;
    class function RawEndCData(ADst: PChar): PChar; static;
    procedure ValidateContentChars(const AChars: string; const APropertyName: string; AAllowOnlyWhitespace: Boolean);
  public
    constructor CreateEx(AStream: TStream; ASettings: TACLXMLWriterSettings); overload;

    procedure WriteXmlDeclaration(AStandalone: TACLXMLStandalone); override;
    procedure WriteXmlDeclaration(const AXmldecl: string); override;
    procedure WriteStartElement(APrefix: string; const ALocalName: string; ANs: string); override;
    procedure StartElementContent; override;
    procedure WriteEndElement(const APrefix, ALocalName, ANs: string); override;
    procedure WriteFullEndElement(const APrefix, ALocalName, ANs: string); override;
    procedure WriteStartAttribute(APrefix: string; ALocalName: string; ANs: string); override;
    procedure WriteEndAttribute; override;
    procedure WriteNamespaceDeclaration(const APrefix, ANamespaceName: string); override;
    procedure WriteStartNamespaceDeclaration(const APrefix: string); override;
    procedure WriteEndNamespaceDeclaration; override;
    procedure WriteCData(const AText: string); override;
    procedure WriteComment(const AText: string); override;
    procedure WriteProcessingInstruction(const AName, AText: string); override;
    procedure WriteEntityRef(const AName: string); override;
    procedure WriteCharEntity(C: Char); override;
    procedure WriteWhitespace(const AWhitespace: string); override;
    procedure WriteString(const AText: string); override;
    procedure WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char); override;
    procedure WriteChars(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer); override;
    procedure WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer); overload; override;
    procedure WriteRaw(const AData: string); overload; override;
    procedure Close; override;
    procedure Flush; override;
  end;

  { TACLXMLWellFormedWriter }

  TACLXMLWellFormedWriter = class(TACLXMLWriter)
  protected const
    AttributeArrayInitialSize = 8;
    ElementStackInitialSize = 8;
    MaxAttrDuplWalkCount = 14;
    MaxNamespacesWalkCount = 16;
    NamespaceStackInitialSize = 8;
  protected type
  {$REGION 'Sub-Types'}
    TState = Byte;
    TStates = class sealed
    public const
      Start = 0;
      TopLevel = 1;
      Document = 2;
      Element = 3;
      Content = 4;
      B64Content = 5;
      B64Attribute = 6;
      AfterRootEle = 7;
      Attribute = 8;
      SpecialAttr = 9;
      EndDocument = 10;
      RootLevelAttr = 11;
      RootLevelSpecAttr = 12;
      RootLevelB64Attr = 13;
      AfterRootLevelAttr = 14;
      Closed = 15;
      Error = 16;

      StartContent = 101;
      StartContentEle = 102;
      StartContentB64 = 103;
      StartDoc = 104;
      StartDocEle = 106;
      EndAttrSEle = 107;
      EndAttrEEle = 108;
      EndAttrSCont = 109;
      EndAttrSAttr = 111;
      PostB64Cont = 112;
      PostB64Attr = 113;
      PostB64RootAttr = 114;
      StartFragEle = 115;
      StartFragCont = 116;
      StartFragB64 = 117;
      StartRootLevelAttr = 118;
    end;

    TToken = (
      StartDocument,
      EndDocument,
      PI,
      Comment,
      Dtd,
      StartElement,
      EndElement,
      StartAttribute,
      EndAttribute,
      Text,
      CData,
      AtomicValue,
      Base64,
      RawData,
      Whitespace
    );

    TSpecialAttribute = (
      No,
      DefaultXmlns,
      PrefixedXmlns,
      XmlSpace,
      XmlLang
    );

    TNamespaceKind = (
      Written,
      NeedToWrite,
      Implied,
      Special
    );

    TElementScope = record
    strict private
      FLocalName: string;
      FNamespaceUri: string;
      FPrefix: string;
      FPrevNSTop: Integer;
      FXmlLang: string;
      FXmlSpace: TACLXMLSpace;
    public
      procedure &Set(const APrefix, ALocalName, ANamespaceUri: string; APrevNSTop: Integer);
      procedure WriteEndElement(ARawWriter: TACLXMLRawWriter);
      procedure WriteFullEndElement(ARawWriter: TACLXMLRawWriter);

      property PrevNSTop: Integer read FPrevNSTop;
      property XmlSpace: TACLXMLSpace read FXmlSpace write FXmlSpace;
      property XmlLang: string read FXmlLang write FXmlLang;
    end;

    TNamespace = record
    strict private
      FKind: TNamespaceKind;
      FNamespaceUri: string;
      FPrefix: string;
      FPrevNsIndex: Integer;
    public
      procedure &Set(const APrefix, ANamespaceUri: string; AKind: TNamespaceKind);
      procedure WriteDecl(AWriter: TACLXMLWriter; ARawWriter: TACLXMLRawWriter);

      property NamespaceUri: string read FNamespaceUri;
      property Kind: TNamespaceKind read FKind write FKind;
      property Prefix: string read FPrefix;
      property PrevNsIndex: Integer read FPrevNsIndex write FPrevNsIndex;
    end;

    TAttrName = record
    strict private
      FLocalName: string;
      FNamespaceUri: string;
      FPrefix: string;
      FPrev: Integer;
    public
      procedure &Set(const APrefix, ALocalName, ANamespaceUri: string);
      function IsDuplicate(const APrefix, ALocalName, ANamespaceUri: string): Boolean;

      property LocalName: string read FLocalName;
      property NamespaceUri: string read FNamespaceUri;
      property Prefix: string read FPrefix;
      property Prev: Integer read FPrev write FPrev;
    end;

    TAttributeValueCache = class
    strict private type
    {$REGION 'Sub-Types'}
      TItemType = (
        EntityRef,
        CharEntity,
        SurrogateCharEntity,
        Whitespace,
        &String,
        StringChars,
        Raw,
        RawChars,
        ValueString
      );

      TItem = class
      strict private
        FType: TItemType;
        FData: TValue;
      public
        procedure &Set(AType: TItemType; const AData: TValue);

        property Data: TValue read FData write FData;
        property &Type: TItemType read FType;
      end;

      TBufferChunk = record
        Buffer: TCharArray;
        Index: Integer;
        Count: Integer;
        constructor Create(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
      end;
    {$ENDREGION}
    strict private
      FFirstItem: Integer;
      FItems: TArray<TItem>;
      FLastItem: Integer;
      FSingleStringValue: string;
      FStringValue: TStringBuilder;

      function GetStringValue: string;
    public
      constructor Create;
      destructor Destroy; override;
      procedure WriteEntityRef(const AName: string);
      procedure WriteCharEntity(ACh: Char);
      procedure WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char);
      procedure WriteWhitespace(const AWs: string);
      procedure WriteString(const AText: string);
      procedure WriteChars(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
      procedure WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer); overload;
      procedure WriteRaw(const AData: string); overload;
      procedure WriteValue(const AValue: string);
      procedure Replay(AWriter: TACLXMLWriter);
      procedure Trim;
      procedure Clear;
      procedure StartComplexValue;
      procedure AddItem(AType: TItemType; AData: TValue);

      property StringValue: string read GetStringValue;
    end;

    TNamespaceResolverProxy = class(TInterfacedObject, IGSXMLNamespaceResolver)
    strict private
      FWfWriter: TACLXMLWellFormedWriter;

      function LookupNamespace(const APrefix: string): string;
      function LookupPrefix(const ANamespaceName: string): string;
    public
      constructor Create(AWfWriter: TACLXMLWellFormedWriter);
    end;
  {$ENDREGION}
  strict private
    class var FStateTableDocument: TArray<TState>;
    class var FStateTableAuto: TArray<TState>;
    class var FStateToWriteState: TArray<TACLXMLWriteState>;
  strict private
    FAttrCount: Integer;
    FAttrHashTable: TDictionary<string, Integer>;
    FAttrStack: TArray<TAttrName>;
    FAttrValueCache: TAttributeValueCache;
    FCheckCharacters: Boolean;
    FConformanceLevel: TACLXMLConformanceLevel;
    FCurDeclPrefix: string;
    FCurrentState: TState;
    FElemScopeStack: TArray<TElementScope>;
    FElemTop: Integer;
    FNsHashTable: TDictionary<string, Integer>;
    FNsStack: TArray<TNamespace>;
    FNsTop: Integer;
    FOmitDuplNamespaces: Boolean;
    FPredefinedNamespaces: IGSXMLNamespaceResolver;
    FSpecAttr: TSpecialAttribute;
    FStateTable: TArray<TState>;
    FUseNsHashTable: Boolean;
    FWriteEndDocumentOnClose: Boolean;
    FWriter: TACLXMLRawWriter;
    FXmlDeclFollows: Boolean;

    class constructor Initialize;
  strict private
    function GetSaveAttrValue: Boolean;
    function GetInBase64: Boolean;
    function GetIsClosedOrErrorState: Boolean;
  protected
    function GetWriteState: TACLXMLWriteState; override;
    function GetSettings: TACLXMLWriterSettings; override;
    function GetXmlSpace: TACLXMLSpace; override;
    function GetXmlLang: string; override;
    procedure ThrowInvalidStateTransition(AToken: TToken; ACurrentState: TState);
  public
    constructor Create(AWriter: TACLXMLRawWriter; ASettings: TACLXMLWriterSettings);
    destructor Destroy; override;
    class function DupAttrException(const APrefix, ALocalName: string): EACLXMLException; static;
    class function InvalidCharsException(const AName: string; ABadCharIndex: Integer): EACLXMLException; static;

    procedure AddAttribute(const APrefix, ALocalName, ANamespaceName: string);
    procedure AddNamespace(const APrefix, ANs: string; AKind: TNamespaceKind);
    procedure AddToAttrHashTable(AAttributeIndex: Integer);
    procedure AddToNamespaceHashtable(ANamespaceIndex: Integer);
    procedure AdvanceState(AToken: TToken);
    procedure CheckNCName(const ANcname: string);
    procedure Close; override;
    procedure Flush; override;
    function GeneratePrefix: string;
    function LookupLocalNamespace(const APrefix: string): string;
    function LookupNamespace(const APrefix: string): string;
    function LookupNamespaceIndex(const APrefix: string): Integer;
    function LookupPrefix(const ANs: string): string; override;
    procedure PopNamespaces(AIndexFrom: Integer; AIndexTo: Integer);
    function PushNamespaceExplicit(const APrefix, ANs: string): Boolean;
    procedure PushNamespaceImplicit(const APrefix, ANs: string);
    procedure SetSpecialAttribute(ASpecial: TSpecialAttribute);
    procedure StartElementContent;
    procedure StartFragment;
    procedure WriteBinHex(const ABuffer: TBytes; AIndex: Integer; ACount: Integer); override;
    procedure WriteCData(const AText: string); override;
    procedure WriteCharEntity(ACh: Char); override;
    procedure WriteChars(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer); override;
    procedure WriteComment(const AText: string); override;
    procedure WriteEndAttribute; override;
    procedure WriteEndDocument; override;
    procedure WriteEndElement; override;
    procedure WriteEntityRef(const AName: string); override;
    procedure WriteFullEndElement; override;
    procedure WriteProcessingInstruction(const AName, AText: string); override;
    procedure WriteQualifiedName(const ALocalName, ANs: string); override;
    procedure WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer); override;
    procedure WriteRaw(const AData: string); override;
    procedure WriteStartAttribute(APrefix: string; ALocalName: string; ANamespaceName: string); override;
    procedure WriteStartDocument(AStandalone: Boolean); override;
    procedure WriteStartDocument; override;
    procedure WriteStartDocumentImpl(AStandalone: TACLXMLStandalone);
    procedure WriteStartElement(APrefix: string; const ALocalName: string; ANs: string); override;
    procedure WriteString(const AText: string); override;
    procedure WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char); override;
    procedure WriteValue(const AValue: string); override;
    procedure WriteWhitespace(const AWs: string); override;

    property InnerWriter: TACLXMLRawWriter read FWriter;
    property SaveAttrValue: Boolean read GetSaveAttrValue;
    property InBase64: Boolean read GetInBase64;
    property IsClosedOrErrorState: Boolean read GetIsClosedOrErrorState;
  end;

{ EACLXMLInvalidSurrogatePairException }

constructor EACLXMLInvalidSurrogatePairException.Create(const ALowChar, AHighChar: Char);
begin
  CreateFmt(SXmlInvalidSurrogatePair, [TACLFastHex.Encode(ALowChar), TACLFastHex.Encode(AHighChar)]);
end;

{ TACLXMLWriterSettings }

constructor TACLXMLWriterSettings.Create;
begin
  inherited Create;
  Reset;
end;

procedure TACLXMLWriterSettings.Reset;
begin
  FOmitXmlDeclaration := False;
  FNewLineHandling := TACLXMLNewLineHandling.Replace;
  FNewLineChars := sLineBreak;
  FIndent := True;
  FIndentChars := '  ';
  FNewLineOnNode := False;
  FNewLineOnAttributes := False;
  FNamespaceHandling := TACLXMLNamespaceHandling.Default;
  FConformanceLevel := TACLXMLConformanceLevel.Document;
  FCheckCharacters := True;
  FWriteEndDocumentOnClose := True;
  FMergeCDataSections := False;
  FStandalone := TACLXMLStandalone.Omit;
end;

{ TACLXMLWriter }

constructor TACLXMLWriter.CreateCore(AStream: TStream);
begin
  inherited Create;
  FStream := AStream;
  FEncoding := TEncoding.UTF8;
end;

class function TACLXMLWriter.Create(AStream: TStream; ASettings: TACLXMLWriterSettings): TACLXMLWriter;
begin
  Result := TACLXMLWellFormedWriter.Create(TACLXMLEncodedRawTextWriter.CreateEx(AStream, ASettings), ASettings);
end;

procedure TACLXMLWriter.Flush;
begin
  //# do nothing
end;

function TACLXMLWriter.GetSettings: TACLXMLWriterSettings;
begin
  Result := nil;
end;

procedure TACLXMLWriter.WriteStartElement(const ALocalName, ANs: string);
begin
  WriteStartElement('', ALocalName, ANs);
end;

procedure TACLXMLWriter.WriteStartElement(const ALocalName: string);
begin
  WriteStartElement('', ALocalName, '');
end;

procedure TACLXMLWriter.WriteString(const AText: string);
begin
  Write(AText);
end;

procedure TACLXMLWriter.WriteString(const AText: AnsiString);
begin
  WriteString(string(AText));
end;

procedure TACLXMLWriter.WriteAttributeBoolean(const ALocalName: string; AValue: Boolean);
begin
  WriteAttributeString(ALocalName, sGSXMLBoolValues[AValue]);
end;

procedure TACLXMLWriter.WriteAttributeBoolean(const APrefix, ALocalName, ANs: string; AValue: Boolean);
begin
  WriteAttributeString(APrefix, ALocalName, ANs, sGSXMLBoolValues[AValue]);
end;

procedure TACLXMLWriter.WriteAttributeFloat(const APrefix, ALocalName, ANs: string; AValue: Single);
begin
  WriteAttributeString(APrefix, ALocalName, ANs, FloatToStr(AValue, TFormatSettings.Invariant));
end;

procedure TACLXMLWriter.WriteAttributeFloat(const ALocalName: string; AValue: Single);
begin
  WriteAttributeString(ALocalName, FloatToStr(AValue, TFormatSettings.Invariant));
end;

procedure TACLXMLWriter.WriteAttributeInteger(const ALocalName: string; AValue: Integer);
begin
  WriteAttributeString(ALocalName, IntToStr(AValue));
end;

procedure TACLXMLWriter.WriteAttributeInteger(const APrefix, ALocalName, ANs: string; AValue: Integer);
begin
  WriteAttributeString(APrefix, ALocalName, ANs, IntToStr(AValue));
end;

procedure TACLXMLWriter.WriteAttributeInt64(const ALocalName: string; const AValue: Int64);
begin
  WriteAttributeString(ALocalName, IntToStr(AValue));
end;

procedure TACLXMLWriter.WriteAttributeInt64(const APrefix, ALocalName, ANs: string; const AValue: Int64);
begin
  WriteAttributeString(APrefix, ALocalName, ANs, IntToStr(AValue));
end;

procedure TACLXMLWriter.WriteAttributeString(const ALocalName, ANs, AValue: string);
begin
  WriteStartAttribute('', ALocalName, ANs);
  WriteString(AValue);
  WriteEndAttribute;
end;

procedure TACLXMLWriter.WriteAttributeString(const ALocalName, AValue: string);
begin
  WriteStartAttribute('', ALocalName, '');
  WriteString(AValue);
  WriteEndAttribute;
end;

procedure TACLXMLWriter.WriteAttributeString(const APrefix, ALocalName, ANs, AValue: string);
begin
  WriteStartAttribute(APrefix, ALocalName, ANs);
  WriteString(AValue);
  WriteEndAttribute;
end;

procedure TACLXMLWriter.WriteAttributeString(const APrefix, ALocalName, ANs: string; const AValue: AnsiString);
begin
  WriteStartAttribute(APrefix, ALocalName, ANs);
  WriteString(AValue);
  WriteEndAttribute;
end;

procedure TACLXMLWriter.WriteAttributeString(const ALocalName: string; const AValue: AnsiString);
begin
  WriteStartAttribute(ALocalName);
  WriteString(AValue);
  WriteEndAttribute;
end;

procedure TACLXMLWriter.WriteStartAttribute(const ALocalName, ANs: string);
begin
  WriteStartAttribute('', ALocalName, ANs);
end;

procedure TACLXMLWriter.WriteStartAttribute(const ALocalName: string);
begin
  WriteStartAttribute('', ALocalName, '');
end;

procedure TACLXMLWriter.WriteStartElement(APrefix: string; const ALocalName: string; ANs: string);
begin
  if APrefix <> '' then
    Write('<' + APrefix + ':' + ALocalName)
  else
    Write('<' + ALocalName);
  FAttrEndPos := Stream.Position;
end;

procedure TACLXMLWriter.WriteBinHex(const ABuffer: TBytes; AIndex: Integer; ACount: Integer);
const
  CharsChunkSize = 128;
var
  AChars: TCharArray;
  AEndIndex, AChunkSize, ACharCount: Integer;
begin
  if ACount * 2 < CharsChunkSize then
    ACharCount := ACount * 2
  else
    ACharCount := CharsChunkSize;
  SetLength(AChars,  ACharCount);

  AEndIndex := AIndex + ACount;
  while AIndex < AEndIndex do
  begin
    if ACount < CharsChunkSize shr 1 then
      AChunkSize := ACount
    else
      AChunkSize := CharsChunkSize shr 1;
    ACharCount := TACLFastHex.Encode(ABuffer, AIndex, AChunkSize, AChars);
    WriteRaw(AChars, 0, ACharCount);
    Inc(AIndex, AChunkSize);
    Dec(ACount, AChunkSize);
  end;
end;

procedure TACLXMLWriter.Close;
begin
  //# do nothing
end;

function TACLXMLWriter.GetXmlSpace: TACLXMLSpace;
begin
  Result := TACLXMLSpace.Default;
end;

function TACLXMLWriter.GetXmlLang: string;
begin
  Result := '';
end;

procedure TACLXMLWriter.WriteQualifiedName(const ALocalName, ANs: string);
var
  APrefix: string;
begin
  if ANs <> '' then
  begin
    APrefix := LookupPrefix(ANs);
    if APrefix = '' then
      raise EACLXMLArgumentException.CreateFmt(SXmlUndefNamespace, [ANs]);
    WriteString(APrefix);
    WriteString(':');
  end;
  WriteString(ALocalName);
end;

procedure TACLXMLWriter.WriteValue(const AValue: string);
begin
  if AValue <> '' then
    WriteString(AValue);
end;

procedure TACLXMLWriter.WriteElementString(const ALocalName, AValue: string);
begin
  WriteElementString(ALocalName, '', AValue);
end;

procedure TACLXMLWriter.WriteElementString(const ALocalName, ANs, AValue: string);
begin
  WriteStartElement(ALocalName, ANs);
  if AValue <> '' then
    WriteString(AValue);
  WriteEndElement;
end;

procedure TACLXMLWriter.WriteElementString(const APrefix, ALocalName, ANs, AValue: string);
begin
  WriteStartElement(APrefix, ALocalName, ANs);
  if AValue <> '' then
    WriteString(AValue);
  WriteEndElement;
end;

procedure TACLXMLWriter.WriteElementString(const ALocalName: string; const AValue: AnsiString);
begin
  WriteStartElement(ALocalName);
  if AValue <> '' then
    WriteString(AValue);
  WriteEndElement;
end;

procedure TACLXMLWriter.WriteEndAttribute;
begin
  Write('"');
  FAttrEndPos := Stream.Position;
end;

procedure TACLXMLWriter.Write(const ABuffer: string);
var
  ABytes: TBytes;
  ALength: Integer;
begin
  ABytes := Encoding.GetBytes(ABuffer);
  ALength := Length(ABytes);
  if ALength > 0 then
    Stream.WriteBuffer(ABytes[0], Length(ABytes));
end;

procedure TACLXMLWriter.Write(const ABuffer: TCharArray; AIndex, ALength: Integer);
var
  ABytes: TBytes;
begin
  ABytes := Encoding.GetBytes(ABuffer, AIndex, ALength);
  ALength := Length(ABytes);
  if ALength > 0 then
    Stream.WriteBuffer(ABytes[0], ALength);
end;

{ TACLFastHex }

class function TACLFastHex.Encode(B: Byte): string;
begin
  Result := ByteToHexMap[B];
end;

class function TACLFastHex.Encode(C: Char): string;
var
  ABuffer: array[0..1] of Cardinal;
begin
  Assert(SizeOf(Char) = 2);
  //# optimized version
  ABuffer[1] := PCardinal(ByteToHexMap[Byte(Ord(C))])^;
  ABuffer[0] := PCardinal(ByteToHexMap[Ord(C) shr 8])^;
  SetString(Result, PChar(@ABuffer), 4);
end;

class function TACLFastHex.Encode(C: Char; P: PChar): PChar;
var
  ABuffer: PCardinal absolute P;
begin
  //# optimized version
  ABuffer^ := PCardinal(ByteToHexMap[Ord(C) shr 8])^;
  Inc(ABuffer);
  ABuffer^ := PCardinal(ByteToHexMap[Byte(Ord(C))])^;
  Inc(ABuffer);
  Result := P;
end;

class function TACLFastHex.Encode(const ASource: TBytes; AOffset, ACount: Integer; var ADest: TCharArray): Integer;
var
  AHex: PCardinal;
  P: PByte;
begin
  Assert(ASource <> nil);
  Assert(AOffset >= 0);
  Assert(ACount >= 0);
  Assert(ACount <= Length(ASource) - AOffset);
  Assert(Length(ADest) >= ACount * 2);
  //# optimized
  Result := ACount shl 1;
  AHex := Pointer(ADest);
  P := Pointer(ASource);
  Inc(P, AOffset);
  repeat
    AHex^ := PCardinal(ByteToHexMap[P^])^;
    Inc(AHex);
    Inc(P);
    Dec(ACount);
  until ACount = 0;
end;

{ TACLXMLRawWriter }

procedure TACLXMLRawWriter.WriteStartDocument;
begin
  raise EACLXMLInvalidOperationException.Create(SXmlInvalidOperation);
end;

procedure TACLXMLRawWriter.WriteStartDocument(AStandalone: Boolean);
begin
  raise EACLXMLInvalidOperationException.Create(SXmlInvalidOperation);
end;

procedure TACLXMLRawWriter.WriteEndDocument;
begin
  raise EACLXMLInvalidOperationException.Create(SXmlInvalidOperation);
end;

procedure TACLXMLRawWriter.WriteEndElement(const APrefix, ALocalName, ANs: string);
begin
  if ContentPosition <> Stream.Position then
  begin
    if APrefix <> '' then
      Write('</' + APrefix + ':' + ALocalName + '>')
    else
      Write('</' + ALocalName + '>')
  end
  else
  begin
    Stream.Position := Stream.Position -1;
    Write(' />');
  end;
end;

procedure TACLXMLRawWriter.WriteEndElement;
begin
  raise EACLXMLInvalidOperationException.Create(SXmlInvalidOperation);
end;

procedure TACLXMLRawWriter.WriteFullEndElement;
begin
  raise EACLXMLInvalidOperationException.Create(SXmlInvalidOperation);
end;

function TACLXMLRawWriter.LookupPrefix(const ANs: string): string;
begin
  raise EACLXMLInvalidOperationException.Create(SXmlInvalidOperation);
end;

function TACLXMLRawWriter.MakeString(const ABuffer: TCharArray; AIndex, ACount: Integer): string;
begin
  SetString(Result, PChar(@ABuffer[AIndex]), ACount);
end;

function TACLXMLRawWriter.GetWriteState: TACLXMLWriteState;
begin
  raise EACLXMLInvalidOperationException.Create(SXmlInvalidOperation);
end;

function TACLXMLRawWriter.GetXmlSpace: TACLXMLSpace;
begin
  raise EACLXMLInvalidOperationException.Create(SXmlInvalidOperation);
end;

function TACLXMLRawWriter.GetXmlLang: string;
begin
  raise EACLXMLInvalidOperationException.Create(SXmlInvalidOperation);
end;

procedure TACLXMLRawWriter.WriteQualifiedName(const ALocalName, ANs: string);
begin
  raise EACLXMLInvalidOperationException.Create(SXmlInvalidOperation);
end;

procedure TACLXMLRawWriter.WriteCData(const AText: string);
begin
  WriteString(AText);
end;

procedure TACLXMLRawWriter.WriteCharEntity(ACh: Char);
begin
  WriteString(ACh);
end;

procedure TACLXMLRawWriter.WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char);
begin
  WriteString(ALowChar + AHighChar);
end;

procedure TACLXMLRawWriter.WriteWhitespace(const AWs: string);
begin
  WriteString(AWs);
end;

procedure TACLXMLRawWriter.WriteChars(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
begin
  WriteString(MakeString(ABuffer, AIndex, ACount));
end;

procedure TACLXMLRawWriter.WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
begin
  WriteString(MakeString(ABuffer, AIndex, ACount));
end;

procedure TACLXMLRawWriter.WriteRaw(const AData: string);
begin
  WriteString(AData);
end;

procedure TACLXMLRawWriter.WriteValue(const AValue: string);
begin
  WriteString(AValue);
end;

function TACLXMLRawWriter.GetNamespaceResolver: IGSXMLNamespaceResolver;
begin
  Result := FResolver;
end;

procedure TACLXMLRawWriter.SetNamespaceResolver(const AValue: IGSXMLNamespaceResolver);
begin
  FResolver := AValue;
end;

procedure TACLXMLRawWriter.StartElementContent;
begin
  Write('>');
  ContentPosition := Stream.Position;
end;

procedure TACLXMLRawWriter.WriteXmlDeclaration(AStandalone: TACLXMLStandalone);
begin
  //# do nothing
  Write('<?xml version="1.0" encoding="utf-8"?>');
end;

procedure TACLXMLRawWriter.WriteXmlDeclaration(const AXmldecl: string);
begin
  //# do nothing
end;

procedure TACLXMLRawWriter.OnRootElement(AConformanceLevel: TACLXMLConformanceLevel);
begin
  //# do nothing
end;

procedure TACLXMLRawWriter.WriteFullEndElement(const APrefix, ALocalName, ANs: string);
begin
  WriteEndElement(APrefix, ALocalName, ANs);
end;

procedure TACLXMLRawWriter.WriteQualifiedName(const APrefix, ALocalName, ANs: string);
begin
  if APrefix <> '' then
  begin
    WriteString(APrefix);
    WriteString(':');
  end;
  WriteString(ALocalName);
end;

function TACLXMLRawWriter.GetSupportsNamespaceDeclarationInChunks: Boolean;
begin
  Result := False;
end;

procedure TACLXMLRawWriter.WriteStartNamespaceDeclaration(const APrefix: string);
begin
  raise EACLXMLException.Create(SXmlNotSupported);
end;

procedure TACLXMLRawWriter.WriteEndNamespaceDeclaration;
begin
  raise EACLXMLException.Create(SXmlNotSupported);
end;

{ TACLXMLEncodedRawTextWriter }

//# Construct an instance of this class that outputs text to the TextWriter interface.
constructor TACLXMLEncodedRawTextWriter.CreateEx(AStream: TStream; ASettings: TACLXMLWriterSettings);
begin
  CreateCore(AStream);
  FBufPos := 1;        //# buffer position starts at 1, because we need to be able to safely step back -1 in case we need to
                       //# close an empty element or in CDATA section detection of double ]; _BUFFER[0] will always be 0
  FTextPos := 1;       //# text end position; don't indent first element, pi, or comment
  FBufLen := BufferSize;

  FNewLineHandling := ASettings.NewLineHandling;
  FOmitXmlDeclaration := ASettings.OmitXmlDeclaration;
  FNewLineChars := ASettings.NewLineChars;
  FCheckCharacters := ASettings.CheckCharacters;
  FEncodeInvalidXmlCharAsUCS2 := ASettings.EncodeInvalidXmlCharAsUCS2;
  FStandalone := ASettings.Standalone;
  FMergeCDataSections := ASettings.MergeCDataSections;
  FNewLineOnNode := ASettings.NewLineOnNode;
  FNewLineOnAttributes := ASettings.NewLineOnAttributes;

  if FCheckCharacters and (FNewLineHandling = TACLXMLNewLineHandling.Replace) then
    ValidateContentChars(FNewLineChars, 'NewLineChars', False);

  //# the buffer is allocated will BufferOverflowSize in order to reduce checks when writing out constant size markup
  SetLength(FBufChars, FBufLen + BufferOverflowSize);

  if ASettings.AutoXmlDeclaration then
  begin
    WriteXmlDeclaration(FStandalone);
    FAutoXmlDeclaration := True;
  end;
end;

//# Write the xml declaration.  This must be the first call.
procedure TACLXMLEncodedRawTextWriter.WriteXmlDeclaration(AStandalone: TACLXMLStandalone);
begin
  if not FOmitXmlDeclaration and not FAutoXmlDeclaration then
  begin
    RawText('<?xml version="');
    RawText('1.0');
    if Encoding <> nil then
    begin
      RawText('" encoding="');
      RawText('utf-8'{FEncoding.WebName});
    end;
    if AStandalone <> TACLXMLStandalone.Omit then
    begin
      RawText('" standalone="');
      if AStandalone = TACLXMLStandalone.Yes then
        RawText('yes')
      else
        RawText('no');
    end;
    RawText('"?>');
  end;
end;

//# Output xml declaration only if user allows it and it was not already output
procedure TACLXMLEncodedRawTextWriter.WriteXmlDeclaration(const AXmldecl: string);
begin
  if not FOmitXmlDeclaration and not FAutoXmlDeclaration then
    WriteProcessingInstruction('xml', AXmldecl);
end;

//# Serialize the beginning of an element start tag: "<prefix:localName"
procedure TACLXMLEncodedRawTextWriter.WriteStartElement(APrefix: string; const ALocalName: string; ANs: string);
begin
  Assert(ALocalName <> '');
  if FNewLineOnNode then
    WriteNewLineAndAlignment;

  Inc(FNestingLevel);
  FBufChars[FBufPos] := '<';
  Inc(FBufPos);
  if APrefix <> '' then
  begin
    RawText(APrefix);
    FBufChars[FBufPos] := ':';
    Inc(FBufPos);
  end;
  RawText(ALocalName);
  FAttrEndPos := FBufPos;
end;

//# Serialize the end of an element start tag in preparation for content serialization: ">"
procedure TACLXMLEncodedRawTextWriter.StartElementContent;
begin
  if FNewLineOnAttributes then
  begin
    if (FBufPos > 0) and (FBufChars[FBufPos - 1] = '"') then
      WriteNewLineAndAlignment(-1);
  end;

  FBufChars[FBufPos] := '>';
  Inc(FBufPos);
  //# StartElementContent is always called; therefore, in order to allow shortcut syntax, we save the
  //# position of the '>' character.  If WriteEndElement is called and no other characters have been
  //# output, then the '>' character can be be overwritten with the shortcut syntax " />".
  FContentPos := FBufPos;
end;

//# Serialize an element end tag: "</prefix:localName>", if content was output.  Otherwise, serialize
//# the shortcut syntax: " />".
procedure TACLXMLEncodedRawTextWriter.WriteEndElement(const APrefix, ALocalName, ANs: string);
begin
  Assert(ALocalName <> '');
  Dec(FNestingLevel);

  if FContentPos <> FBufPos then
  begin
    if FNewLineOnNode then
    begin
      if (FBufPos > 0) and (FBufChars[FBufPos - 1] = '>') then
        WriteNewLineAndAlignment;
    end;

    //# Content has been output, so can't use shortcut syntax
    FBufChars[FBufPos] := '<';
    Inc(FBufPos);
    FBufChars[FBufPos] := '/';
    Inc(FBufPos);

    if APrefix <> '' then
    begin
      RawText(APrefix);
      FBufChars[FBufPos] := ':';
      Inc(FBufPos);
    end;
    RawText(ALocalName);
    FBufChars[FBufPos] := '>';
    Inc(FBufPos);
  end
  else
  begin
    //# Use shortcut syntax; overwrite the already output '>' character
    Dec(FBufPos);
    FBufChars[FBufPos] := ' ';
    Inc(FBufPos);
    FBufChars[FBufPos] := '/';
    Inc(FBufPos);
    FBufChars[FBufPos] := '>';
    Inc(FBufPos);
  end;
end;

//# Serialize a full element end tag: "</prefix:localName>"
procedure TACLXMLEncodedRawTextWriter.WriteFullEndElement(const APrefix, ALocalName, ANs: string);
begin
  Assert(ALocalName <> '');
  Dec(FNestingLevel);

  if FNewLineOnNode then
  begin
    if (FBufPos > 0) and (FBufChars[FBufPos - 1] = '>') then
      WriteNewLineAndAlignment;
  end;

  FBufChars[FBufPos] := '<';
  Inc(FBufPos);
  FBufChars[FBufPos] := '/';
  Inc(FBufPos);

  if APrefix <> '' then
  begin
    RawText(APrefix);
    FBufChars[FBufPos] := ':';
    Inc(FBufPos);
  end;
  RawText(ALocalName);
  FBufChars[FBufPos] := '>';
  Inc(FBufPos);
end;

//# Serialize an attribute tag using double quotes around the attribute value: 'prefix:localName="'
procedure TACLXMLEncodedRawTextWriter.WriteStartAttribute(APrefix: string; ALocalName: string; ANs: string);
begin
  Assert(ALocalName <> '');

  if FNewLineOnAttributes then
    WriteNewLineAndAlignment;

  if FAttrEndPos = FBufPos then
  begin
    FBufChars[FBufPos] := ' ';
    Inc(FBufPos);
  end;

  if APrefix <> '' then
  begin
    RawText(APrefix);
    FBufChars[FBufPos] := ':';
    Inc(FBufPos);
  end;
  RawText(ALocalName);
  FBufChars[FBufPos] := '=';
  Inc(FBufPos);
  FBufChars[FBufPos] := '"';
  Inc(FBufPos);

  FInAttributeValue := True;
end;

//# Serialize the end of an attribute value using double quotes: '"'
procedure TACLXMLEncodedRawTextWriter.WriteEndAttribute;
begin
  FBufChars[FBufPos] := '"';
  Inc(FBufPos);
  FInAttributeValue := False;
  FAttrEndPos := FBufPos;
end;

procedure TACLXMLEncodedRawTextWriter.WriteNamespaceDeclaration(const APrefix, ANamespaceName: string);
begin
  WriteStartNamespaceDeclaration(APrefix);
  WriteString(ANamespaceName);
  WriteEndNamespaceDeclaration;
end;

function TACLXMLEncodedRawTextWriter.GetSupportsNamespaceDeclarationInChunks: Boolean;
begin
  Result := True;
end;

procedure TACLXMLEncodedRawTextWriter.WriteStartNamespaceDeclaration(const APrefix: string);
begin
  //# VSTFDEVDIV bug #583965: Inconsistency between Silverlight 2 and Dev10 in the way a single xmlns attribute is serialized
  //# Resolved as: Won't fix (breaking change)
  if APrefix = '' then
    RawText(' xmlns="')
  else
  begin
    RawText(' xmlns:');
    RawText(APrefix);
    FBufChars[FBufPos] := '=';
    Inc(FBufPos);
    FBufChars[FBufPos] := '"';
    Inc(FBufPos);
  end;

  FInAttributeValue := True;
end;

procedure TACLXMLEncodedRawTextWriter.WriteEndNamespaceDeclaration;
begin
  FInAttributeValue := False;

  FBufChars[FBufPos] := '"';
  Inc(FBufPos);
  FAttrEndPos := FBufPos;
end;

//# Serialize a CData section.  If the "]]>" pattern is found within the text, replace it with "]]><![CDATA[>".
procedure TACLXMLEncodedRawTextWriter.WriteCData(const AText: string);
begin
  Assert(AText <> '');

  if FMergeCDataSections and (FBufPos = FCdataPos) then
  begin
    //# Merge adjacent cdata sections - overwrite the "]]>" characters
    Assert(FBufPos >= 4);
    Dec(FBufPos, 3);
  end
  else
  begin
    //# Start a new cdata section
    FBufChars[FBufPos] := '<';
    Inc(FBufPos);
    FBufChars[FBufPos] := '!';
    Inc(FBufPos);
    FBufChars[FBufPos] := '[';
    Inc(FBufPos);
    FBufChars[FBufPos] := 'C';
    Inc(FBufPos);
    FBufChars[FBufPos] := 'D';
    Inc(FBufPos);
    FBufChars[FBufPos] := 'A';
    Inc(FBufPos);
    FBufChars[FBufPos] := 'T';
    Inc(FBufPos);
    FBufChars[FBufPos] := 'A';
    Inc(FBufPos);
    FBufChars[FBufPos] := '[';
    Inc(FBufPos);
  end;

  WriteCDataSection(AText);

  FBufChars[FBufPos] := ']';
  Inc(FBufPos);
  FBufChars[FBufPos] := ']';
  Inc(FBufPos);
  FBufChars[FBufPos] := '>';
  Inc(FBufPos);

  FTextPos := FBufPos;
  FCdataPos := FBufPos;
end;

//# Serialize a comment.
procedure TACLXMLEncodedRawTextWriter.WriteComment(const AText: string);
begin
  Assert(AText <> '');

  FBufChars[FBufPos] := '<';
  Inc(FBufPos);
  FBufChars[FBufPos] := '!';
  Inc(FBufPos);
  FBufChars[FBufPos] := '-';
  Inc(FBufPos);
  FBufChars[FBufPos] := '-';
  Inc(FBufPos);

  WriteCommentOrPi(AText, '-');

  FBufChars[FBufPos] := '-';
  Inc(FBufPos);
  FBufChars[FBufPos] := '-';
  Inc(FBufPos);
  FBufChars[FBufPos] := '>';
  Inc(FBufPos);
end;

//# Serialize a processing instruction.
procedure TACLXMLEncodedRawTextWriter.WriteProcessingInstruction(const AName, AText: string);
begin
  Assert(AName <> '');

  FBufChars[FBufPos] := '<';
  Inc(FBufPos);
  FBufChars[FBufPos] := '?';
  Inc(FBufPos);
  RawText(AName);

  if AText <> '' then
  begin
    FBufChars[FBufPos] := ' ';
    Inc(FBufPos);
    WriteCommentOrPi(AText, '?');
  end;

  FBufChars[FBufPos] := '?';
  Inc(FBufPos);
  FBufChars[FBufPos] := '>';
  Inc(FBufPos);
end;

//# Serialize an entity reference.
procedure TACLXMLEncodedRawTextWriter.WriteEntityRef(const AName: string);
begin
  Assert(AName <> '');

  FBufChars[FBufPos] := '&';
  Inc(FBufPos);
  RawText(AName);
  FBufChars[FBufPos] := ';';
  Inc(FBufPos);

  if FBufPos > FBufLen then
    FlushBuffer;

  FTextPos := FBufPos;
end;

//# Serialize a character entity reference.
procedure TACLXMLEncodedRawTextWriter.WriteCharEntity(C: Char);
var
  AValue: string;
begin
  AValue := TACLFastHex.Encode(C);

  if FCheckCharacters and not TACLXMLCharType.IsCharData(C) then
    //# we just have a single char, not a surrogate, therefore we have to pass in '\0' for the second char
    raise EACLXMLArgumentException.CreateFmt(SXmlInvalidCharacter, [C, TACLFastHex.Encode(C)]);

  FBufChars[FBufPos] := '&';
  Inc(FBufPos);
  FBufChars[FBufPos] := '#';
  Inc(FBufPos);
  FBufChars[FBufPos] := 'x';
  Inc(FBufPos);
  RawText(AValue);
  FBufChars[FBufPos] := ';';
  Inc(FBufPos);

  if FBufPos > FBufLen then
    FlushBuffer;

  FTextPos := FBufPos;
end;

//# Serialize a whitespace node.
procedure TACLXMLEncodedRawTextWriter.WriteWhitespace(const AWhitespace: string);
var
  AStart, AEnd: PChar;
begin
  Assert(AWhitespace <> '');

  AStart := PChar(AWhitespace);
  AEnd := AStart + Length(AWhitespace);
  if FInAttributeValue then
    WriteAttributeTextBlock(AStart, AEnd)
  else
    WriteElementTextBlock(AStart, AEnd);
end;

//# Serialize either attribute or element text using XML rules.
procedure TACLXMLEncodedRawTextWriter.WriteString(const AText: string);
var
  AStart, AEnd: PChar;
begin
  Assert(AText <> '');

  AStart := PChar(AText);
  AEnd := AStart + Length(AText);
  if FInAttributeValue then
    WriteAttributeTextBlock(AStart, AEnd)
  else
    WriteElementTextBlock(AStart, AEnd);
end;

//# Serialize surrogate character entity.
procedure TACLXMLEncodedRawTextWriter.WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char);
var
  ASurrogateChar: Integer;
begin
  ASurrogateChar := TACLXMLCharType.CombineSurrogateChar(ALowChar, AHighChar);

  FBufChars[FBufPos] := '&';
  Inc(FBufPos);
  FBufChars[FBufPos] := '#';
  Inc(FBufPos);
  FBufChars[FBufPos] := 'x';
  Inc(FBufPos);
  RawText(TACLFastHex.Encode(Char(ASurrogateChar)));
  FBufChars[FBufPos] := ';';
  Inc(FBufPos);
  FTextPos := FBufPos;
end;

//# Serialize either attribute or element text using XML rules. Arguments are validated in the XmlWellformedWriter layer.
procedure TACLXMLEncodedRawTextWriter.WriteChars(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
var
  AStart: PChar;
begin
  Assert(ABuffer <> nil);
  Assert(AIndex >= 0);
  Assert((ACount >= 0) and (AIndex + ACount <= Length(ABuffer)));

  AStart := @ABuffer[AIndex];
  if FInAttributeValue then
    WriteAttributeTextBlock(AStart, AStart + ACount)
  else
    WriteElementTextBlock(AStart, AStart + ACount);
end;

//# Serialize raw data. Arguments are validated in the XmlWellformedWriter layer
procedure TACLXMLEncodedRawTextWriter.WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
var
  AStart: PChar;
begin
  Assert(ABuffer <> nil);
  Assert(AIndex >= 0);
  Assert((ACount >= 0) and (AIndex + ACount <= Length(ABuffer)));

  AStart := @ABuffer[AIndex];
  WriteRawWithCharChecking(AStart, AStart + ACount);
  FTextPos := FBufPos;
end;

//# Serialize raw data.
procedure TACLXMLEncodedRawTextWriter.WriteRaw(const AData: string);
var
  AStart, AEnd: PChar;
begin
  Assert(AData <> '');

  AStart := PChar(AData);
  AEnd := AStart + Length(AData);
  WriteRawWithCharChecking(AStart, AEnd);
  FTextPos := FBufPos;
end;

//# Flush all bytes in the buffer to output and close the output stream or writer.
procedure TACLXMLEncodedRawTextWriter.Close;
begin
  try
    FlushBuffer;
  finally
    //# Future calls to Close or Flush shouldn't write to Stream or Writer
    FWriteToNull := True;
  end;
end;

//# Flush all characters in the buffer to output and call Flush() on the output object.
procedure TACLXMLEncodedRawTextWriter.Flush;
begin
  FlushBuffer;
end;

//# Flush all characters in the buffer to output.  Do not flush the output object.
procedure TACLXMLEncodedRawTextWriter.FlushBuffer;
begin
  try
    try
      //# Output all characters (except for previous characters stored at beginning of buffer)
      if not FWriteToNull then
        //# Write text to TextWriter
        Write(FBufChars, 1, FBufPos - 1);
    except
      //# Future calls to flush (i.e. when Close() is called) don't attempt to write to stream
      FWriteToNull := True;
      raise;
    end;
  finally
    //# Move last buffer character to the beginning of the buffer (so that previous character can always be determined)
    FBufChars[0] := FBufChars[FBufPos - 1];
    //# Reset buffer position
    if FTextPos = FBufPos then
      FTextPos := 1
    else
      FTextPos := 0;
    if FAttrEndPos = FBufPos then
      FAttrEndPos := 1
    else
      FAttrEndPos := 0;
    FContentPos := 0; //# Needs to be zero, since overwriting '>' character is no longer possible
    FCdataPos := 0;   //# Needs to be zero, since overwriting ']]>' characters is no longer possible
    FBufPos := 1;     //# Buffer position starts at 1, because we need to be able to safely step back -1 in case we need to
                      //# close an empty element or in CDATA section detection of double ]; _BUFFER[0] will always be 0
  end;
end;

//# Serialize text that is part of an attribute value.  The '&', '<', '>', and '"' characters are entitized.
procedure TACLXMLEncodedRawTextWriter.WriteAttributeTextBlock(ASrc: PChar; ASrcEnd: PChar);
var
  ADstBegin, ADstEnd, ADst: PChar;
  C: Char;
begin
  ADstBegin := @FBufChars[0];

  ADst := ADstBegin + FBufPos;

  C := #$0000;
  while True do
  begin
    ADstEnd := ADst + (ASrcEnd - ASrc);
    if ADstEnd > ADstBegin + FBufLen  then
      ADstEnd := ADstBegin + FBufLen;

    while ADst < ADstEnd do
    begin
      C := ASrc^;
      if (TACLXMLCharType.charProperties[C] and TACLXMLCharType.AttrValue) = 0 then
        Break;
      ADst^ := C;
      Inc(ADst);
      Inc(ASrc);
    end;
    Assert(ASrc <= ASrcEnd);

    //# end of value
    if ASrc >= ASrcEnd then
      Break;
    //# end of buffer
    if ADst >= ADstEnd then
    begin
      FBufPos := ADst - ADstBegin;
      FlushBuffer;
      ADst := ADstBegin + 1;
      Continue;
    end;
    //# some character needs to be escaped
    case C of
      '&':
        ADst := AmpEntity(ADst);
      '<':
        ADst := LtEntity(ADst);
      '>':
        ADst := GtEntity(ADst);
      '"':
        ADst := QuoteEntity(ADst);
      #$0027:
        begin
          ADst^ := C;
          Inc(ADst);
        end;
      #$0009:
        begin
          if FNewLineHandling = TACLXMLNewLineHandling.None then
          begin
            ADst^ := C;
            Inc(ADst);
          end
          else
            //# escape tab in attributes
            ADst := TabEntity(ADst);
        end;
      #$000D:
        begin
          if FNewLineHandling = TACLXMLNewLineHandling.None then
          begin
            ADst^ := C;
            Inc(ADst);
          end
          else
            //# escape new lines in attributes
            ADst := CarriageReturnEntity(ADst);
        end;
      #$000A:
        begin
          if FNewLineHandling = TACLXMLNewLineHandling.None then
          begin
            ADst^ := C;
            Inc(ADst);
          end
          else
            //# escape new lines in attributes
            ADst := LineFeedEntity(ADst);
        end;
      else
      begin
        if TACLXMLCharType.IsSurrogate(C) then
        begin
          ADst := EncodeSurrogate(ASrc, ASrcEnd, ADst);
          Inc(ASrc, 2);
        end
        else
          if (C <= #$007F) or (C >= #$FFFE) then
          begin
            ADst := InvalidXmlChar(C, ADst, True);
            Inc(ASrc);
          end
          else
          begin
            ADst^ := C;
            Inc(ADst);
            Inc(ASrc);
          end;
        Continue;
      end;
    end;
    Inc(ASrc);
  end;
  FBufPos := ADst - ADstBegin;
end;

//# Serialize text that is part of element content.  The '&', '<', and '>' characters are entitized.
procedure TACLXMLEncodedRawTextWriter.WriteElementTextBlock(ASrc: PChar; ASrcEnd: PChar);
var
  ADst, ADstEnd, ADstBegin: PChar;
  C: Char;
begin
  ADstBegin := @FBufChars[0];
  ADst := ADstBegin + FBufPos;

  C := #$0000;
  while True do
  begin
    ADstEnd := ADst + (ASrcEnd - ASrc);
    if ADstEnd > ADstBegin + FBufLen then
      ADstEnd := ADstBegin + FBufLen;

    while ADst < ADstEnd do
    begin
      C := ASrc^;
      if (TACLXMLCharType.CharProperties[C] and TACLXMLCharType.AttrValue) = 0 then
        Break;
      ADst^ := C;
      Inc(ADst);
      Inc(ASrc);
    end;
    Assert(ASrc <= ASrcEnd);
    //# end of value
    if ASrc >= ASrcEnd then
      Break;
    //# end of buffer
    if ADst >= ADstEnd then
    begin
      FBufPos := Integer((ADst - ADstBegin));
      FlushBuffer;
      ADst := ADstBegin + 1;
      Continue;
    end;
    //# some character needs to be escaped
    case C of
      '&':
        ADst := AmpEntity(ADst);
      '<':
        ADst := LtEntity(ADst);
      '>':
        ADst := GtEntity(ADst);
      '"',
      #$0027, #$0009:
        begin
          ADst^ := C;
          Inc(ADst);
        end;
      #$000A:
        begin
          if FNewLineHandling = TACLXMLNewLineHandling.Replace then
            ADst := WriteNewLine(ADst)
          else
          begin
            ADst^ := C;
            Inc(ADst);
          end;
        end;
      #$000D:
        begin
          case FNewLineHandling of
            TACLXMLNewLineHandling.Replace:
              begin
                //# Replace "\r\n", or "\r" with NewLineChars
                if ASrc[1] = #$000A then
                  Inc(ASrc);
                ADst := WriteNewLine(ADst);
              end;
            TACLXMLNewLineHandling.Entitize:
              //# Entitize 0xD
              ADst := CarriageReturnEntity(ADst);
            TACLXMLNewLineHandling.None:
              begin
                ADst^ := C;
                Inc(ADst);
              end;
          end;
        end;
    else
    begin
      if TACLXMLCharType.IsSurrogate(C) then
      begin
        ADst := EncodeSurrogate(ASrc, ASrcEnd, ADst);
        Inc(ASrc, 2);
      end
      else
        if (C <= #$007F) or (C >= #$FFFE) then
        begin
          ADst := InvalidXmlChar(C, ADst, True);
          Inc(ASrc);
        end
        else
        begin
          ADst^ := C;
          Inc(ADst);
          Inc(ASrc);
        end;
      end;
      Continue;
    end;
    Inc(ASrc);
  end;
  FBufPos := (ADst - ADstBegin);
  FTextPos := FBufPos;
  FContentPos := 0;
end;

procedure TACLXMLEncodedRawTextWriter.WriteNewLineAndAlignment(ANestingLevelCorrection: Integer = 0);
var
  I: Integer;
begin
  RawText(#13);
  for I := 1 to FNestingLevel + ANestingLevelCorrection do
    RawText(#9);
end;

procedure TACLXMLEncodedRawTextWriter.RawText(const S: string);
var
  AStart, AEnd: PChar;
begin
  Assert(S <> '');
  AStart := PChar(S);
  AEnd := AStart + Length(S);
  RawText(AStart, AEnd);
end;

procedure TACLXMLEncodedRawTextWriter.RawText(ASrcBegin: PChar; ASrcEnd: PChar);
var
  ADstBegin, ADst, ASrc, ADstEnd: PChar;
  C: Char;
begin
  ADstBegin := @FBufChars[0];
  ADst := ADstBegin + FBufPos;
  ASrc := ASrcBegin;
  C := #$0000;
  while True do
  begin
    ADstEnd := ADst + (ASrcEnd - ASrc);
    if ADstEnd > ADstBegin + FBufLen then
      ADstEnd := ADstBegin + FBufLen;

    while ADst < ADstEnd do
    begin
      C := ASrc^;
      if C >= TACLXMLCharType.SurHighStart then
        Break;
      Inc(ASrc);
      ADst^ := C;
      Inc(ADst);
    end;
    Assert(ASrc <= ASrcEnd);
    //# end of value
    if ASrc >= ASrcEnd then
      Break;
    //# end of buffer
    if ADst >= ADstEnd then
    begin
      FBufPos := ADst - ADstBegin;
      FlushBuffer;
      ADst := ADstBegin + 1;
      Continue;
    end;

    if TACLXMLCharType.IsSurrogate(C) then
    begin
      ADst := EncodeSurrogate(ASrc, ASrcEnd, ADst);
      Inc(ASrc, 2);
    end
    else
      if (C <= #$007F) or (C >= #$FFFE) then
      begin
        ADst := InvalidXmlChar(C, ADst, False);
        Inc(ASrc);
      end
      else
      begin
        ADst^ := C;
        Inc(ADst);
        Inc(ASrc);
      end;
  end;
  FBufPos := ADst - ADstBegin;
end;

procedure TACLXMLEncodedRawTextWriter.WriteRawWithCharChecking(APSrcBegin: PChar; APSrcEnd: PChar);
var
  ADstBegin, ASrc, ADst, ADstEnd: PChar;
  C: Char;
begin
  ADstBegin := @FBufChars[0];
  ASrc := APSrcBegin;
  ADst := ADstBegin + FBufPos;

  C := #0000;
  while True do
  begin
    ADstEnd := ADst + (APSrcEnd - ASrc);
    if ADstEnd > ADstBegin + FBufLen then
      ADstEnd := ADstBegin + FBufLen;

    while ADst < ADstEnd do
    begin
      C := ASrc^;
      if not ((TACLXMLCharType.CharProperties[C] and TACLXMLCharType.Text) <> 0) then
        Break;
      ADst^ := C;
      Inc(ADst);
      Inc(ASrc);
    end;

    Assert(ASrc <= APSrcEnd);

    if ASrc >= APSrcEnd then
      Break;
    if ADst >= ADstEnd then
    begin
      FBufPos := ADst - ADstBegin;
      FlushBuffer;
      ADst := ADstBegin + 1;
      Continue;
    end;
    case C of
      ']', '<', '&', #$0009:
        begin
          ADst^ := C;
          Inc(ADst);
        end;
      #$000D:
        if FNewLineHandling = TACLXMLNewLineHandling.Replace then
        begin
          if ASrc[1] = #10 then
            Inc(ASrc);
          ADst := WriteNewLine(ADst);
        end
        else
        begin
          ADst^ := C;
          Inc(ADst);
        end;
      #$000A:
        if FNewLineHandling = TACLXMLNewLineHandling.Replace then
          ADst := WriteNewLine(ADst)
        else
        begin
          ADst^ := C;
          Inc(ADst);
        end;
      else
      begin
        if TACLXMLCharType.IsSurrogate(C) then
        begin
          ADst := EncodeSurrogate(ASrc, APSrcEnd, ADst);
          Inc(ASrc, 2);
        end
        else
          if (C <= #$007F) or (C >= #$FFFE) then
          begin
            ADst := InvalidXmlChar(C, ADst, False);
            Inc(ASrc);
          end
          else
          begin
            ADst^ := C;
            Inc(ADst);
            Inc(ASrc);
          end;
        Continue;
      end;
    end;
    Inc(ASrc);
  end;
  FBufPos := ADst - ADstBegin;
end;

procedure TACLXMLEncodedRawTextWriter.WriteCommentOrPi(const AText: string; AStopChar: Char);
var
  ASrcBegin, ADstBegin, ASrc, ASrcEnd, ADst, ADstEnd: PChar;
  C: Char;
begin
  if AText = '' then
  begin
    if FBufPos >= FBufLen then
      FlushBuffer;
    Exit;
  end;

  ASrcBegin := PChar(AText);
  ADstBegin := @FBufChars[0];
  ASrc := ASrcBegin;
  ASrcEnd := ASrcBegin + Length(AText);
  ADst := ADstBegin + FBufPos;
  C := #$0000;
  while True do
  begin
    ADstEnd := ADst + (ASrcEnd - ASrc);
    if ADstEnd > ADstBegin + FBufLen then
      ADstEnd := ADstBegin + FBufLen;

    while ADst < ADstEnd do
    begin
      C := ASrc^;
      if not (((TACLXMLCharType.CharProperties[C] and TACLXMLCharType.Text) <> 0) and (C <> AStopChar)) then
        Break;
      ADst^ := C;
      Inc(ADst);
      Inc(ASrc);
    end;

    Assert(ASrc <= ASrcEnd);
    //# end of value
    if ASrc >= ASrcEnd then
      Break;
    //# end of buffer
    if ADst >= ADstEnd then
    begin
      FBufPos := ADst - ADstBegin;
      FlushBuffer;
      ADst := ADstBegin + 1;
      Continue;
    end;

    case C of
      '-':
        begin
          ADst^ := '-';
          Inc(ADst);
          if C = AStopChar then
          begin
            //# Insert space between adjacent dashes or before comment's end dashes
            if (ASrc + 1 = ASrcEnd) or (ASrc[1] = '-') then
            begin
              ADst^ := ' ';
              Inc(ADst);
            end;
          end;
        end;
      '?':
        begin
          ADst^ := '?';
          Inc(ADst);
          if C = AStopChar then
          begin
            //# Processing instruction: insert space between adjacent '?' and '>'
            if (ASrc + 1 < ASrcEnd) and (ASrc[1] = '>') then
            begin
              ADst^ := ' ';
              Inc(ADst);
            end;
          end;
        end;
      ']':
        begin
          ADst^ := ']';
          Inc(ADst);
        end;
      #$000D:
        if FNewLineHandling = TACLXMLNewLineHandling.Replace then
        begin
           //# Normalize "\r\n", or "\r" to NewLineChars
          if ASrc[1] = #$000A then
            Inc(ASrc);
          ADst := WriteNewLine(ADst);
        end
        else
        begin
          ADst^ := C;
          Inc(ADst);
        end;
      #$000A:
        if FNewLineHandling = TACLXMLNewLineHandling.Replace then
          ADst := WriteNewLine(ADst)
        else
        begin
          ADst^ := C;
          Inc(ADst);
        end;
      '<', '&', #$0009:
        begin
          ADst^ := C;
          Inc(ADst);
        end;
      else
      begin
        if TACLXMLCharType.IsSurrogate(C) then
        begin
          ADst := EncodeSurrogate(ASrc, ASrcEnd, ADst);
          Inc(ASrc, 2);
        end
        else
          if (C <= #$007F) or (C >= #$FFFE) then
          begin
            ADst := InvalidXmlChar(C, ADst, False);
            Inc(ASrc);
          end
          else
          begin
            ADst^ := C;
            Inc(ADst);
            Inc(ASrc);
          end;
        Continue;
      end;
    end;
    Inc(ASrc);
  end;
  FBufPos := ADst - ADstBegin;
end;

procedure TACLXMLEncodedRawTextWriter.WriteCDataSection(const AText: string);
var
  ASrcBegin, ADstBegin, ASrc, ASrcEnd, ADst, ADstEnd: PChar;
  C: Char;
begin
  if AText = '' then
  begin
    if FBufPos >= FBufLen then
      FlushBuffer;
    Exit;
  end;

  ASrcBegin := PChar(AText);
  ADstBegin := @FBufChars[0];
  ASrc := ASrcBegin;
  ASrcEnd := ASrcBegin + Length(AText);
  ADst := ADstBegin + FBufPos;

  C := #$000;
  while True do
  begin
    ADstEnd := ADst + (ASrcEnd - ASrc);
    if ADstEnd > ADstBegin + FBufLen then
      ADstEnd := ADstBegin + FBufLen;

    while ADst < ADstEnd do
    begin
      C := ASrc^;
      if not (((TACLXMLCharType.CharProperties[C] and TACLXMLCharType.AttrValue) <> 0) and (C <> ']')) then
        Break;
      ADst^ := C;
      Inc(ADst);
      Inc(ASrc);
    end;

    Assert(ASrc <= ASrcEnd);
    //# end of value
    if ASrc >= ASrcEnd then
      Break;
    //# end of buffer
    if ADst >= ADstEnd then
    begin
      FBufPos := ADst - ADstBegin;
      FlushBuffer;
      ADst := ADstBegin + 1;
      Continue;
    end;
    //# handle special characters
    case C of
      '>':
        begin
          if FHadDoubleBracket and (ADst[-1] = ']') then
          begin
            //# The characters "]]>" were found within the CData text
            ADst := RawEndCData(ADst);
            ADst := RawStartCData(ADst);
          end;
          ADst^ := '>';
          Inc(ADst);
        end;
      ']':
        begin
          FHadDoubleBracket := ADst[-1] = ']';
          ADst^ := ']';
          Inc(ADst);
        end;
      #$000D:
        if FNewLineHandling = TACLXMLNewLineHandling.Replace then
        begin
          //# Normalize "\r\n", or "\r" to NewLineChars
          if ASrc[1] = #$000A then
            Inc(ASrc);
          ADst := WriteNewLine(ADst);
        end
        else
        begin
          ADst^ := C;
          Inc(ADst);
        end;
      #$000A:
        if FNewLineHandling = TACLXMLNewLineHandling.Replace then
          ADst := WriteNewLine(ADst)
        else
        begin
          ADst^ := C;
          Inc(ADst);
        end;
      '&', '<', '"', #$0027, #$0009:
        begin
          ADst^ := C;
          Inc(ADst);
        end;
      else
      begin
        if TACLXMLCharType.IsSurrogate(C) then
        begin
          ADst := EncodeSurrogate(ASrc, ASrcEnd, ADst);
          Inc(ASrc, 2);
        end
        else
          if (C <= #$007F) or (C >= #$FFFE) then
          begin
            ADst := InvalidXmlChar(C, ADst, False);
            Inc(ASrc);
          end
          else
          begin
            ADst^ := C;
            Inc(ADst);
            Inc(ASrc);
          end;
        Continue;
      end;
    end;
    Inc(ASrc);
  end;
  FBufPos := ADst - ADstBegin;
end;

class function TACLXMLEncodedRawTextWriter.EncodeSurrogate(ASrc: PChar; ASrcEnd: PChar; ADst: PChar): PChar;
var
  ACh, ALowChar: Char;
begin
  ACh := ASrc^;
  Assert(TACLXMLCharType.IsSurrogate(ACh));
  if ACh <= TACLXMLCharType.SurHighEnd then
  begin
    if ASrc + 1 < ASrcEnd then
    begin
      ALowChar := ASrc[1];
      if ALowChar >= TACLXMLCharType.SurLowStart then
      begin
        ADst[0] := ACh;
        ADst[1] := ALowChar;
        Inc(ADst, 2);
        Exit(ADst);
      end;
      raise EACLXMLInvalidSurrogatePairException.Create(ALowChar, ACh);
    end;
    raise EACLXMLArgumentException.Create(SXmlInvalidSurrogateMissingLowChar);
  end;
  raise EACLXMLArgumentException.CreateFmt(SXmlInvalidHighSurrogateChar, [TACLFastHex.Encode(ACh)]);
end;

function TACLXMLEncodedRawTextWriter.InvalidXmlChar(ACh: Char; ADst: PChar; AEntitize: Boolean): PChar;
begin
  Assert(not TACLXMLCharType.IsWhiteSpace(ACh));
  Assert(not TACLXMLCharType.IsAttributeValueChar(ACh));

  if FCheckCharacters then
    raise EACLXMLArgumentException.CreateFmt(SXmlInvalidCharacter, [ACh, TACLFastHex.Encode(ACh)]);

  if AEntitize then
  begin
    if FEncodeInvalidXmlCharAsUCS2 then
      Result := UCS2Entity(ADst, ACh)
    else
      Result := CharEntity(ADst, ACh);
  end
  else
  begin
    ADst^ := ACh;
    Inc(ADst);
    Result := ADst;
  end;
end;

procedure TACLXMLEncodedRawTextWriter.EncodeChar(var ASrc: PChar; APSrcEnd: PChar; var ADst: PChar);
var
  C: Char;
begin
  C := ASrc^;
  if TACLXMLCharType.IsSurrogate(C) then
  begin
    ADst := EncodeSurrogate(ASrc, APSrcEnd, ADst);
    Inc(ASrc, 2);
  end
  else
    if (C <= #$007F) or (C >= #$FFFE) then
    begin
      ADst := InvalidXmlChar(C, ADst, False);
      Inc(ASrc);
    end
    else
    begin
      ADst^ := C;
      Inc(ADst);
      Inc(ASrc);
    end;
end;

//# Write NewLineChars to the specified buffer position and return an updated position.
function TACLXMLEncodedRawTextWriter.WriteNewLine(ADst: PChar): PChar;
var
  ADstBegin: PChar;
begin
  ADstBegin := @FBufChars[0];
  FBufPos := ADst - ADstBegin;
  //# Let RawText do the real work
  RawText(FNewLineChars);
  Result := ADstBegin + FBufPos;
end;

//# Following methods do not check whether pDst is beyond the bufSize because the buffer was allocated with a BufferOverflowSize to accommodate
//# for the writes of small constant-length string as below.

//# Entitize '<' as "&lt;".  Return an updated pointer.
class function TACLXMLEncodedRawTextWriter.LtEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := 'l';
  ADst[2] := 't';
  ADst[3] := ';';
  Result := ADst + 4;
end;

//# Entitize '>' as "&gt;".  Return an updated pointer.
class function TACLXMLEncodedRawTextWriter.GtEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := 'g';
  ADst[2] := 't';
  ADst[3] := ';';
  Result := ADst + 4;
end;

//# Entitize '&' as "&amp;".  Return an updated pointer.
class function TACLXMLEncodedRawTextWriter.AmpEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := 'a';
  ADst[2] := 'm';
  ADst[3] := 'p';
  ADst[4] := ';';
  Result := ADst + 5;
end;

//# Entitize '"' as "&quot;".  Return an updated pointer.
class function TACLXMLEncodedRawTextWriter.QuoteEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := 'q';
  ADst[2] := 'u';
  ADst[3] := 'o';
  ADst[4] := 't';
  ADst[5] := ';';
  Result := ADst + 6;
end;

//# Entitize '\t' as "&#x9;".  Return an updated pointer.
class function TACLXMLEncodedRawTextWriter.TabEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := '#';
  ADst[2] := 'x';
  ADst[3] := '9';
  ADst[4] := ';';
  Result := ADst + 5;
end;

//# Entitize 0xa as "&#xA;".  Return an updated pointer.
class function TACLXMLEncodedRawTextWriter.LineFeedEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := '#';
  ADst[2] := 'x';
  ADst[3] := 'A';
  ADst[4] := ';';
  Result := ADst + 5;
end;

//# Entitize 0xd as "&#xD;".  Return an updated pointer.
class function TACLXMLEncodedRawTextWriter.CarriageReturnEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := '#';
  ADst[2] := 'x';
  ADst[3] := 'D';
  ADst[4] := ';';
  Result := ADst + 5;
end;

class function TACLXMLEncodedRawTextWriter.CharEntity(ADst: PChar; ACh: Char): PChar;
begin
  //# VCL refactored
  ADst[0] := '&';
  ADst[1] := '#';
  ADst[2] := 'x';
  Inc(ADst, 3);
  ADst := TACLFastHex.Encode(ACh, ADst);
  ADst[0] := ';';
  Inc(ADst);
  Result := ADst;
end;

//# https://msdn.microsoft.com/en-us/library/system.xml.xmlconvert.decodename(v=vs.110).aspx
class function TACLXMLEncodedRawTextWriter.UCS2Entity(ADst: PChar; ACh: Char): PChar;
begin
  ADst[0] := '_';
  ADst[1] := 'x';
  Inc(ADst, 2);
  ADst := TACLFastHex.Encode(ACh, ADst);
  ADst[0] := '_';
  Inc(ADst);
  Result := ADst;
end;

//# Write "<![CDATA[" to the specified buffer.  Return an updated pointer.
class function TACLXMLEncodedRawTextWriter.RawStartCData(ADst: PChar): PChar;
begin
  ADst[0] := '<';
  ADst[1] := '!';
  ADst[2] := '[';
  ADst[3] := 'C';
  ADst[4] := 'D';
  ADst[5] := 'A';
  ADst[6] := 'T';
  ADst[7] := 'A';
  ADst[8] := '[';
  Result := ADst + 9;
end;

//# Write "]]>" to the specified buffer.  Return an updated pointer.
class function TACLXMLEncodedRawTextWriter.RawEndCData(ADst: PChar): PChar;
begin
  ADst[0] := ']';
  ADst[1] := ']';
  ADst[2] := '>';
  Result := ADst + 3;
end;

procedure TACLXMLEncodedRawTextWriter.ValidateContentChars(const AChars: string; const APropertyName: string; AAllowOnlyWhitespace: Boolean);
var
  I: Integer;
begin
  if AAllowOnlyWhitespace then
  begin
    if not TACLXMLCharType.IsOnlyWhitespace(AChars) then
      raise EACLXMLArgumentException.CreateFmt(SXmlIndentCharsNotWhitespace, [APropertyName]);
  end
  else
  begin
    //# VCL refactored
    I := 1;
    while I <= Length(AChars) do
    begin
      if not TACLXMLCharType.IsTextChar(AChars[I]) then
      begin
        case AChars[I] of
          #13, #10, #9: {do nothing};
          '<', '&', ']':
            raise EACLXMLArgumentException.CreateFmt(SXmlInvalidCharsInIndent, [APropertyName,
              Format(SXmlInvalidCharacter, [AChars[I], TACLFastHex.Encode(AChars[I])])]);
          else
          begin
            if TACLXMLCharType.IsHighSurrogate(AChars[I]) then
            begin
              if I + 1 <= Length(AChars) then
              begin
                if TACLXMLCharType.IsLowSurrogate(AChars[I + 1]) then
                begin
                  Inc(I, 2);
                  Continue;
                end;
              end;
              raise EACLXMLArgumentException.CreateFmt(SXmlInvalidCharsInIndent, [APropertyName, SXmlInvalidSurrogateMissingLowChar]);
            end
            else
              if TACLXMLCharType.IsLowSurrogate(AChars[I]) then
                raise EACLXMLArgumentException.CreateFmt(SXmlInvalidCharsInIndent, [APropertyName,
                  Format(SXmlInvalidHighSurrogateChar, [TACLFastHex.Encode(AChars[I])])]);
          end;
        end;
      end;
      Inc(I);
    end;
  end;
end;

{ TACLXMLWellFormedWriter.TElementScope }

procedure TACLXMLWellFormedWriter.TElementScope.&Set(const APrefix, ALocalName, ANamespaceUri: string; APrevNSTop: Integer);
begin
  FPrevNSTop := APrevNSTop;
  FPrefix := APrefix;
  FNamespaceUri := ANamespaceUri;
  FLocalName := ALocalName;
  FXmlSpace := TACLXMLSpace(-1);
  FXmlLang := '';
end;

procedure TACLXMLWellFormedWriter.TElementScope.WriteEndElement(ARawWriter: TACLXMLRawWriter);
begin
  ARawWriter.WriteEndElement(FPrefix, FLocalName, FNamespaceUri);
end;

procedure TACLXMLWellFormedWriter.TElementScope.WriteFullEndElement(ARawWriter: TACLXMLRawWriter);
begin
  ARawWriter.WriteFullEndElement(FPrefix, FLocalName, FNamespaceUri);
end;

{ TACLXMLWellFormedWriter.TNamespace }

procedure TACLXMLWellFormedWriter.TNamespace.&Set(const APrefix, ANamespaceUri: string; AKind: TNamespaceKind);
begin
  FPrefix := APrefix;
  FNamespaceUri := ANamespaceUri;
  FKind := AKind;
  FPrevNsIndex := -1;
end;

procedure TACLXMLWellFormedWriter.TNamespace.WriteDecl(AWriter: TACLXMLWriter; ARawWriter: TACLXMLRawWriter);
begin
  Assert(FKind = TNamespaceKind.NeedToWrite);
  if ARawWriter <> nil then
    ARawWriter.WriteNamespaceDeclaration(FPrefix, FNamespaceUri)
  else
  begin
    if FPrefix = '' then
      AWriter.WriteStartAttribute('', 'xmlns', TACLXMLReservedNamespaces.XmlNs)
    else
      AWriter.WriteStartAttribute('xmlns', FPrefix, TACLXMLReservedNamespaces.XmlNs);
    AWriter.WriteString(FNamespaceUri);
    AWriter.WriteEndAttribute;
  end;
end;

{ TACLXMLWellFormedWriter.TAttrName }

procedure TACLXMLWellFormedWriter.TAttrName.&Set(const APrefix, ALocalName, ANamespaceUri: string);
begin
  FPrefix := APrefix;
  FNamespaceUri := ANamespaceUri;
  FLocalName := ALocalName;
  FPrev := 0;
end;

function TACLXMLWellFormedWriter.TAttrName.IsDuplicate(const APrefix, ALocalName, ANamespaceUri: string): Boolean;
begin
  Result := (FLocalName = ALocalName) and ((FPrefix = APrefix) or (FNamespaceUri = ANamespaceUri));
end;

{ TACLXMLWellFormedWriter.TAttributeValueCache.TItem }

procedure TACLXMLWellFormedWriter.TAttributeValueCache.TItem.&Set(AType: TItemType; const AData: TValue);
begin
  FType := AType;
  FData := AData;
end;

{ TACLXMLWellFormedWriter.TAttributeValueCache.TBufferChunk }

constructor TACLXMLWellFormedWriter.TAttributeValueCache.TBufferChunk.Create(const ABuffer: TCharArray;
  AIndex: Integer; ACount: Integer);
begin
  Buffer := ABuffer;
  Index := AIndex;
  Count := ACount;
end;

{ TAttributeValueCache }

constructor TACLXMLWellFormedWriter.TAttributeValueCache.Create;
begin
  FStringValue := TStringBuilder.Create;
  FLastItem := -1;
end;

destructor TACLXMLWellFormedWriter.TAttributeValueCache.Destroy;
begin
  FStringValue.Free;
  inherited Destroy;
end;

function TACLXMLWellFormedWriter.TAttributeValueCache.GetStringValue: string;
begin
  if FSingleStringValue <> '' then
    Result := FSingleStringValue
  else
    Result := FStringValue.ToString;
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.WriteEntityRef(const AName: string);
begin
  if FSingleStringValue <> '' then
    StartComplexValue;

  if AName = 'lt' then
    FStringValue.Append('<')
  else if AName = 'gt' then
    FStringValue.Append('>')
  else if AName = 'quot' then
    FStringValue.Append('"')
  else if AName = 'apos' then
    FStringValue.Append(#$27)
  else if AName = 'amp' then
    FStringValue.Append('&')
  else
  begin
    FStringValue.Append('&');
    FStringValue.Append(AName);
    FStringValue.Append(';');
  end;

  AddItem(TItemType.EntityRef, AName);
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.WriteCharEntity(ACh: Char);
begin
  if FSingleStringValue <> '' then
    StartComplexValue;
  FStringValue.Append(ACh);
  AddItem(TItemType.CharEntity, TValue.From<Char>(ACh));
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char);
begin
  if FSingleStringValue <> '' then
    StartComplexValue;
  FStringValue.Append(AHighChar);
  FStringValue.Append(ALowChar);
  AddItem(TItemType.SurrogateCharEntity, ALowChar + AHighChar);
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.WriteWhitespace(const AWs: string);
begin
  if FSingleStringValue <> '' then
    StartComplexValue;
  FStringValue.Append(AWs);
  AddItem(TItemType.Whitespace, AWs);
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.WriteString(const AText: string);
begin
  if FSingleStringValue <> '' then
    StartComplexValue
  else
  begin
    if FLastItem = -1 then
    begin
      FSingleStringValue := AText;
      Exit;
    end;
  end;

  FStringValue.Append(AText);
  AddItem(TItemType.String, AText);
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.WriteChars(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
begin
  if FSingleStringValue <> '' then
    StartComplexValue;
  FStringValue.Append(ABuffer, AIndex, ACount);
  AddItem(TItemType.StringChars, TValue.From<TBufferChunk>(TBufferChunk.Create(ABuffer, AIndex, ACount)));
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
begin
  if FSingleStringValue <> '' then
    StartComplexValue;
  FStringValue.Append(ABuffer, AIndex, ACount);
  AddItem(TItemType.RawChars, TValue.From<TBufferChunk>(TBufferChunk.Create(ABuffer, AIndex, ACount)));
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.WriteRaw(const AData: string);
begin
  if FSingleStringValue <> '' then
    StartComplexValue;
  FStringValue.Append(AData);
  AddItem(TItemType.Raw, AData);
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.WriteValue(const AValue: string);
begin
  if FSingleStringValue <> '' then
    StartComplexValue;
  FStringValue.Append(AValue);
  AddItem(TItemType.ValueString, AValue);
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.Replay(AWriter: TACLXMLWriter);
var
  ABufChunk: TBufferChunk;
  I: Integer;
  AItem: TItem;
  AChars: TCharArray;
begin
  if FSingleStringValue <> '' then
  begin
    AWriter.WriteString(FSingleStringValue);
    Exit;
  end;

  for I := FFirstItem to FLastItem do
  begin
    AItem := FItems[I];
    case AItem.&Type of
      TItemType.EntityRef:
        AWriter.WriteEntityRef(AItem.Data.AsString);
      TItemType.CharEntity:
        AWriter.WriteCharEntity(AItem.Data.AsType<Char>);
      TItemType.SurrogateCharEntity:
        begin
          AChars := AItem.Data.AsType<TCharArray>;
          AWriter.WriteSurrogateCharEntity(AChars[0], AChars[1]);
        end;
      TItemType.Whitespace:
        AWriter.WriteWhitespace(AItem.Data.AsString);
      TItemType.String:
        AWriter.WriteString(AItem.Data.AsString);
      TItemType.StringChars:
        begin
          ABufChunk := AItem.Data.AsType<TBufferChunk>;
          AWriter.WriteChars(ABufChunk.Buffer, ABufChunk.Index, ABufChunk.Count);
        end;
      TItemType.Raw:
        AWriter.WriteRaw(AItem.Data.AsString);
      TItemType.RawChars:
        begin
          ABufChunk := AItem.Data.AsType<TBufferChunk>;
          AWriter.WriteChars(ABufChunk.Buffer, ABufChunk.Index, ABufChunk.Count);
        end;
      TItemType.ValueString:
        AWriter.WriteValue(AItem.Data.AsString);
      else
        Assert(False, 'Unexpected ItemType value.');
    end;
  end;
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.Trim;
var
  AValBefore, AValAfter: string;
  I, AEndIndex: Integer;
  AItem: TItem;
  ABufChunk: TBufferChunk;
begin
  if FSingleStringValue <> '' then
  begin
    FSingleStringValue := System.SysUtils.Trim(FSingleStringValue); //#TODO:  XmlConvert.TrimString(FSingleStringValue);
    Exit;
  end;

  AValBefore := FStringValue.ToString;
  AValAfter := System.SysUtils.Trim(FSingleStringValue); //#TODO:  XmlConvert.TrimString(AValBefore);
  if AValBefore <> AValAfter then
  begin
    FStringValue.Free;
    FStringValue := TStringBuilder.Create(AValAfter);
  end;

  I := FFirstItem;
  while (I = FFirstItem) and (I <= FLastItem) do
  begin
    AItem := FItems[I];
    case AItem.&Type of
      TItemType.Whitespace:
        Inc(FFirstItem);
      TItemType.String,
      TItemType.Raw,
      TItemType.ValueString:
        begin
          AItem.Data := TrimLeft(AItem.Data.AsString); //# XmlConvert.TrimStringStart(string(AItem.data));
          if AItem.Data.AsString = '' then
            Inc(FFirstItem);
        end;
      TItemType.StringChars,
      TItemType.RawChars:
        begin
          ABufChunk := AItem.Data.AsType<TBufferChunk>;      //# 1. make local copy of struct AItem.Data (in .net class)
          AEndIndex := ABufChunk.Index + ABufChunk.Count;
          while (ABufChunk.Index < AEndIndex) and TACLXMLCharType.IsWhiteSpace(ABufChunk.Buffer[ABufChunk.Index]) do
          begin
            Inc(ABufChunk.Index);
            Dec(ABufChunk.Count);
          end;
          AItem.Data := TValue.From<TBufferChunk>(ABufChunk); //# 2. update AItem.Data with modified data
          if ABufChunk.Index = AEndIndex then
            Inc(FFirstItem); //# no characters left -> move the firstItem index to exclude it from the Replay
        end;
    end;
    Inc(I);
  end;

  I := FLastItem;
  while (I = FLastItem) and (I >= FFirstItem) do
  begin
    AItem := FItems[I];
    case AItem.&Type of
      TItemType.Whitespace:
        Dec(FLastItem);
      TItemType.String,
      TItemType.Raw,
      TItemType.ValueString:
        begin
          AItem.Data := TrimRight(AItem.Data.AsString); //# XmlConvert.TrimStringEnd(string(AItem.data));
          if AItem.Data.AsString = '' then
            Dec(FLastItem);
        end;
      TItemType.StringChars,
      TItemType.RawChars:
        begin
          ABufChunk := AItem.Data.AsType<TBufferChunk>;       //# 1. make local copy of struct AItem.Data (in .net class)
          while (ABufChunk.Count > 0) and TACLXMLCharType.IsWhiteSpace(ABufChunk.Buffer[ABufChunk.Index + ABufChunk.Count - 1]) do
            Dec(ABufChunk.Count);
          AItem.Data := TValue.From<TBufferChunk>(ABufChunk); //# 2. update AItem.Data with modified data
          if ABufChunk.Count = 0 then
            Dec(FLastItem); //# no characters left -> move the lastItem index to exclude it from the Replay
        end;
    end;
    Dec(I);
  end;
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.Clear;
begin
  FSingleStringValue := '';
  FLastItem := -1;
  FFirstItem := 0;
  FStringValue.Length := 0;
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.StartComplexValue;
begin
  Assert(FSingleStringValue <> '');
  Assert(FLastItem = -1);

  FStringValue.Append(FSingleStringValue);
  AddItem(TItemType.String, FSingleStringValue);

  FSingleStringValue := '';
end;

procedure TACLXMLWellFormedWriter.TAttributeValueCache.AddItem(AType: TItemType; AData: TValue);
var
  ANewItemIndex: Integer;
begin
  ANewItemIndex := FLastItem + 1;
  if FItems = nil then
    SetLength(FItems, 4)
  else
    if Length(FItems) = ANewItemIndex then
      SetLength(FItems, ANewItemIndex * 2);

  if FItems[ANewItemIndex] = nil then
    FItems[ANewItemIndex] := TItem.Create;

  FItems[ANewItemIndex].&Set(AType, AData);
  FLastItem := ANewItemIndex;
end;

{ TACLXMLWellFormedWriter.TNamespaceResolverProxy }

constructor TACLXMLWellFormedWriter.TNamespaceResolverProxy.Create(AWfWriter: TACLXMLWellFormedWriter);
begin
  FWfWriter := AWfWriter;
end;

function TACLXMLWellFormedWriter.TNamespaceResolverProxy.LookupNamespace(const APrefix: string): string;
begin
  Result := FWfWriter.LookupNamespace(APrefix);
end;

function TACLXMLWellFormedWriter.TNamespaceResolverProxy.LookupPrefix(const ANamespaceName: string): string;
begin
  Result := FWfWriter.LookupPrefix(ANamespaceName);
end;

{ TACLXMLWellFormedWriter }

constructor TACLXMLWellFormedWriter.Create(AWriter: TACLXMLRawWriter; ASettings: TACLXMLWriterSettings);
var
  ADefaultNs: string;
begin
  FSpecAttr := TSpecialAttribute.No;

  Assert(AWriter <> nil);
  Assert(ASettings <> nil);
  FWriter := AWriter;
  if not Supports(AWriter, IGSXMLNamespaceResolver, FPredefinedNamespaces) then
    FPredefinedNamespaces := nil;
  FWriter.NamespaceResolver := TNamespaceResolverProxy.Create(Self);

  FCheckCharacters := ASettings.CheckCharacters;
  FOmitDuplNamespaces := ASettings.NamespaceHandling = TACLXMLNamespaceHandling.OmitDuplicates;
  FWriteEndDocumentOnClose := ASettings.WriteEndDocumentOnClose;
  FConformanceLevel := ASettings.ConformanceLevel;

  if FConformanceLevel = TACLXMLConformanceLevel.Document then
    FStateTable := FStateTableDocument
  else
    FStateTable := FStateTableAuto;

  FCurrentState := TStates.Start;

  SetLength(FNsStack, NamespaceStackInitialSize);
  FNsStack[0].&Set('xmlns', TACLXMLReservedNamespaces.XmlNs, TNamespaceKind.Special);
  FNsStack[1].&Set('xml', TACLXMLReservedNamespaces.Xml, TNamespaceKind.Special);
  if FPredefinedNamespaces = nil then
    FNsStack[2].&Set('', '', TNamespaceKind.Implied)
  else
  begin
    ADefaultNs := FPredefinedNamespaces.LookupNamespace('');
    FNsStack[2].&Set('', ADefaultNs, TNamespaceKind.Implied);
  end;
  FNsTop := 2;

  SetLength(FElemScopeStack, ElementStackInitialSize);
  FElemScopeStack[0].&Set('', '', '', FNsTop);
  FElemScopeStack[0].XmlSpace := TACLXMLSpace.None;
  FElemScopeStack[0].XmlLang := '';
  FElemTop := 0;

  SetLength(FAttrStack, AttributeArrayInitialSize);
end;

destructor TACLXMLWellFormedWriter.Destroy;
begin
  if WriteState <> TACLXMLWriteState.Closed then
    Close;
  FWriter.Free;
  FNsHashTable.Free;
  FAttrHashTable.Free;
  FAttrValueCache.Free;
  inherited Destroy;
end;

class constructor TACLXMLWellFormedWriter.Initialize;
begin
  FStateToWriteState := TArray<TACLXMLWriteState>.Create(
    TACLXMLWriteState.Start,       //# State.Start
    TACLXMLWriteState.Prolog,      //# State.TopLevel
    TACLXMLWriteState.Prolog,      //# State.Document
    TACLXMLWriteState.Element,     //# State.Element
    TACLXMLWriteState.Content,     //# State.Content
    TACLXMLWriteState.Content,     //# State.B64Content
    TACLXMLWriteState.Attribute,   //# State.B64Attribute
    TACLXMLWriteState.Content,     //# State.AfterRootEle
    TACLXMLWriteState.Attribute,   //# State.Attribute
    TACLXMLWriteState.Attribute,   //# State.SpecialAttr
    TACLXMLWriteState.Content,     //# State.EndDocument
    TACLXMLWriteState.Attribute,   //# State.RootLevelAttr
    TACLXMLWriteState.Attribute,   //# State.RootLevelSpecAttr
    TACLXMLWriteState.Attribute,   //# State.RootLevelB64Attr
    TACLXMLWriteState.Attribute,   //# State.AfterRootLevelAttr
    TACLXMLWriteState.Closed,      //# State.Closed
    TACLXMLWriteState.Error        //# State.Error
  );
  FStateTableDocument := TArray<TState>.Create(
    //#                      TStates.Start           TStates.TopLevel   TStates.Document     TStates.Element          TStates.Content     TStates.B64Content      TStates.B64Attribute   TStates.AfterRootEle    TStates.Attribute,      TStates.SpecialAttr,   TStates.EndDocument,  TStates.RootLevelAttr,      TStates.RootLevelSpecAttr,  TStates.RootLevelB64Attr   TStates.AfterRootLevelAttr, // 16
    { Token.StartDocument  } TStates.Document,       TStates.Error,     TStates.Error,       TStates.Error,           TStates.Error,      TStates.PostB64Cont,    TStates.Error,         TStates.Error,          TStates.Error,          TStates.Error,         TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.EndDocument    } TStates.Error,          TStates.Error,     TStates.Error,       TStates.Error,           TStates.Error,      TStates.PostB64Cont,    TStates.Error,         TStates.EndDocument,    TStates.Error,          TStates.Error,         TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.PI             } TStates.StartDoc,       TStates.TopLevel,  TStates.Document,    TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.AfterRootEle,   TStates.EndAttrSCont,   TStates.EndAttrSCont,  TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.Comment        } TStates.StartDoc,       TStates.TopLevel,  TStates.Document,    TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.AfterRootEle,   TStates.EndAttrSCont,   TStates.EndAttrSCont,  TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.Dtd            } TStates.StartDoc,       TStates.TopLevel,  TStates.Document,    TStates.Error,           TStates.Error,      TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Error,          TStates.Error,          TStates.Error,         TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.StartElement   } TStates.StartDocEle,    TStates.Element,   TStates.Element,     TStates.StartContentEle, TStates.Element,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Error,          TStates.EndAttrSEle,    TStates.EndAttrSEle,   TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.EndElement     } TStates.Error,          TStates.Error,     TStates.Error,       TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Error,          TStates.EndAttrEEle,    TStates.EndAttrEEle,   TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.StartAttribute } TStates.Error,          TStates.Error,     TStates.Error,       TStates.Attribute,       TStates.Error,      TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Error,          TStates.EndAttrSAttr,   TStates.EndAttrSAttr,  TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.EndAttribute   } TStates.Error,          TStates.Error,     TStates.Error,       TStates.Error,           TStates.Error,      TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Error,          TStates.Element,        TStates.Element,       TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.Text           } TStates.Error,          TStates.Error,     TStates.Error,       TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Error,          TStates.Attribute,      TStates.SpecialAttr,   TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.CData          } TStates.Error,          TStates.Error,     TStates.Error,       TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Error,          TStates.EndAttrSCont,   TStates.EndAttrSCont,  TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.AtomicValue    } TStates.Error,          TStates.Error,     TStates.Error,       TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Error,          TStates.Attribute,      TStates.Error,         TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.Base64         } TStates.Error,          TStates.Error,     TStates.Error,       TStates.StartContentB64, TStates.B64Content, TStates.B64Content,     TStates.B64Attribute,  TStates.Error,          TStates.B64Attribute,   TStates.Error,         TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.RawData        } TStates.StartDoc,       TStates.Error,     TStates.Document,    TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.AfterRootEle,   TStates.Attribute,      TStates.SpecialAttr,   TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error,
    { Token.Whitespace     } TStates.StartDoc,       TStates.TopLevel,  TStates.Document,    TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.AfterRootEle,   TStates.Attribute,      TStates.SpecialAttr,   TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error
  );
  FStateTableAuto := TArray<TState>.Create(
    //#                      TStates.Start           TStates.TopLevel       TStates.Document     TStates.Element          TStates.Content     TStates.B64Content      TStates.B64Attribute   TStates.AfterRootEle    TStates.Attribute,      TStates.SpecialAttr,   TStates.EndDocument,  TStates.RootLevelAttr,      TStates.RootLevelSpecAttr,  TStates.RootLevelB64Attr,  TStates.AfterRootLevelAttr  // 16
    { Token.StartDocument  } TStates.Document,       TStates.Error,         TStates.Error,       TStates.Error,           TStates.Error,      TStates.PostB64Cont,    TStates.Error,         TStates.Error,          TStates.Error,          TStates.Error,         TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error, { Token.StartDocument  }
    { Token.EndDocument    } TStates.Error,          TStates.Error,         TStates.Error,       TStates.Error,           TStates.Error,      TStates.PostB64Cont,    TStates.Error,         TStates.EndDocument,    TStates.Error,          TStates.Error,         TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error, { Token.EndDocument    }
    { Token.PI             } TStates.TopLevel,       TStates.TopLevel,      TStates.Error,       TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.AfterRootEle,   TStates.EndAttrSCont,   TStates.EndAttrSCont,  TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error, { Token.PI             }
    { Token.Comment        } TStates.TopLevel,       TStates.TopLevel,      TStates.Error,       TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.AfterRootEle,   TStates.EndAttrSCont,   TStates.EndAttrSCont,  TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error, { Token.Comment        }
    { Token.Dtd            } TStates.StartDoc,       TStates.TopLevel,      TStates.Error,       TStates.Error,           TStates.Error,      TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Error,          TStates.Error,          TStates.Error,         TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error, { Token.Dtd            }
    { Token.StartElement   } TStates.StartFragEle,   TStates.Element,       TStates.Error,       TStates.StartContentEle, TStates.Element,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Element,        TStates.EndAttrSEle,    TStates.EndAttrSEle,   TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error, { Token.StartElement   }
    { Token.EndElement     } TStates.Error,          TStates.Error,         TStates.Error,       TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Error,          TStates.EndAttrEEle,    TStates.EndAttrEEle,   TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error, { Token.EndElement     }
    { Token.StartAttribute } TStates.RootLevelAttr,  TStates.Error,         TStates.Error,       TStates.Attribute,       TStates.Error,      TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Error,          TStates.EndAttrSAttr,   TStates.EndAttrSAttr,  TStates.Error,        TStates.StartRootLevelAttr, TStates.StartRootLevelAttr, TStates.PostB64RootAttr,   TStates.RootLevelAttr,      TStates.Error, { Token.StartAttribute }
    { Token.EndAttribute   } TStates.Error,          TStates.Error,         TStates.Error,       TStates.Error,           TStates.Error,      TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Error,          TStates.Element,        TStates.Element,       TStates.Error,        TStates.AfterRootLevelAttr, TStates.AfterRootLevelAttr, TStates.PostB64RootAttr,   TStates.Error,              TStates.Error, { Token.EndAttribute   }
    { Token.Text           } TStates.StartFragCont,  TStates.StartFragCont, TStates.Error,       TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Content,        TStates.Attribute,      TStates.SpecialAttr,   TStates.Error,        TStates.RootLevelAttr,      TStates.RootLevelSpecAttr,  TStates.PostB64RootAttr,   TStates.Error,              TStates.Error, { Token.Text           }
    { Token.CData          } TStates.StartFragCont,  TStates.StartFragCont, TStates.Error,       TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Content,        TStates.EndAttrSCont,   TStates.EndAttrSCont,  TStates.Error,        TStates.Error,              TStates.Error,              TStates.Error,             TStates.Error,              TStates.Error, { Token.CData          }
    { Token.AtomicValue    } TStates.StartFragCont,  TStates.StartFragCont, TStates.Error,       TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Content,        TStates.Attribute,      TStates.Error,         TStates.Error,        TStates.RootLevelAttr,      TStates.Error,              TStates.PostB64RootAttr,   TStates.Error,              TStates.Error, { Token.AtomicValue    }
    { Token.Base64         } TStates.StartFragB64,   TStates.StartFragB64,  TStates.Error,       TStates.StartContentB64, TStates.B64Content, TStates.B64Content,     TStates.B64Attribute,  TStates.B64Content,     TStates.B64Attribute,   TStates.Error,         TStates.Error,        TStates.RootLevelB64Attr,   TStates.Error,              TStates.RootLevelB64Attr,  TStates.Error,              TStates.Error, { Token.Base64         }
    { Token.RawData        } TStates.StartFragCont,  TStates.TopLevel,      TStates.Error,       TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.Content,        TStates.Attribute,      TStates.SpecialAttr,   TStates.Error,        TStates.RootLevelAttr,      TStates.RootLevelSpecAttr,  TStates.PostB64RootAttr,   TStates.AfterRootLevelAttr, TStates.Error, { Token.RawData        }
    { Token.Whitespace     } TStates.TopLevel,       TStates.TopLevel,      TStates.Error,       TStates.StartContent,    TStates.Content,    TStates.PostB64Cont,    TStates.PostB64Attr,   TStates.AfterRootEle,   TStates.Attribute,      TStates.SpecialAttr,   TStates.Error,        TStates.RootLevelAttr,      TStates.RootLevelSpecAttr,  TStates.PostB64RootAttr,   TStates.AfterRootLevelAttr, TStates.Error  { Token.Whitespace     }
  );
end;

function TACLXMLWellFormedWriter.GetWriteState: TACLXMLWriteState;
begin
  if FCurrentState <= TStates.Error then
    Result := FStateToWriteState[FCurrentState]
  else
  begin
    Assert(False, 'Expected currentState <= State.Error ');
    Result := TACLXMLWriteState.Error;
  end;
end;

function TACLXMLWellFormedWriter.GetSettings: TACLXMLWriterSettings;
begin
  Result := FWriter.Settings;
  Result.ConformanceLevel := FConformanceLevel;
  if FOmitDuplNamespaces then
    Result.NamespaceHandling := TACLXMLNamespaceHandling.OmitDuplicates; //# Result.NamespaceHandling or TACLXMLNamespaceHandling.OmitDuplicates; //# TODO: resolve param tyre
end;

procedure TACLXMLWellFormedWriter.WriteStartDocument;
begin
  WriteStartDocumentImpl(TACLXMLStandalone.Omit);
end;

procedure TACLXMLWellFormedWriter.WriteStartDocument(AStandalone: Boolean);
begin
  if AStandalone then
    WriteStartDocumentImpl(TACLXMLStandalone.Yes)
  else
    WriteStartDocumentImpl(TACLXMLStandalone.No);
end;

procedure TACLXMLWellFormedWriter.WriteEndDocument;
var
  APrevState: TState;
begin
  try
    while FElemTop > 0 do
      WriteEndElement;

    APrevState := FCurrentState;
    AdvanceState(TToken.EndDocument);

    if APrevState <> TStates.AfterRootEle then
      raise EACLXMLArgumentException.Create(SXmlNoRoot);

    FWriter.WriteEndDocument;
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteStartElement(APrefix: string; const ALocalName: string; ANs: string);
var
  ATop: Integer;
begin
  try
    if ALocalName = '' then
      raise EACLXMLArgumentException.Create(SXmlEmptyLocalName);

    CheckNCName(ALocalName);
    AdvanceState(TToken.StartElement);

    if APrefix = '' then
    begin
      if ANs <> '' then
        APrefix := LookupPrefix(ANs);
    end
    else
    begin
      CheckNCName(APrefix);
      if ANs = '' then
        ANs := LookupNamespace(APrefix);

      if ANs = '' then
        raise EACLXMLArgumentException.Create(SXmlPrefixForEmptyNs);
    end;

    if ANs = '' then
    begin
      ANs := LookupNamespace(APrefix);
      if ANs = '' then
      begin
        Assert(Length(APrefix) = 0);
        ANs := '';
      end;
    end;

    if FElemTop = 0 then
      FWriter.OnRootElement(FConformanceLevel);

    FWriter.WriteStartElement(APrefix, ALocalName, ANs);

    Inc(FElemTop);
    ATop := FElemTop;
    if ATop = Length(FElemScopeStack) then
      SetLength(FElemScopeStack, ATop * 2);

    FElemScopeStack[ATop].&Set(APrefix, ALocalName, ANs, FNsTop);

    PushNamespaceImplicit(APrefix, ANs);

    if FAttrCount >= MaxAttrDuplWalkCount then
      FAttrHashTable.Clear;
    FAttrCount := 0;
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteEndElement;
var
  ATop, APrevNsTop: Integer;
begin
  try
    AdvanceState(TToken.EndElement);

    ATop := FElemTop;
    if ATop = 0 then
      raise EACLXMLArgumentException.Create(SXmlNoStartTag);

    FElemScopeStack[ATop].WriteEndElement(FWriter);

    APrevNsTop := FElemScopeStack[ATop].PrevNSTop;
    if FUseNsHashTable and (APrevNsTop < FNsTop) then
      PopNamespaces(APrevNsTop + 1, FNsTop);

    FNsTop := APrevNsTop;
    Dec(ATop);
    FElemTop := ATop;

    if ATop = 0 then
    begin
      if FConformanceLevel = TACLXMLConformanceLevel.Document then
        FCurrentState := TStates.AfterRootEle
      else
        FCurrentState := TStates.TopLevel;
    end;
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteFullEndElement;
var
  ATop, APrevNsTop: Integer;
begin
  try
    AdvanceState(TToken.EndElement);

    ATop := FElemTop;
    if ATop = 0 then
      raise EACLXMLException.Create(SXmlNoStartTag);

    FElemScopeStack[ATop].WriteFullEndElement(FWriter);

    APrevNsTop := FElemScopeStack[ATop].PrevNSTop;
    if FUseNsHashTable and (APrevNsTop < FNsTop) then
      PopNamespaces(APrevNsTop + 1, FNsTop);

    FNsTop := APrevNsTop;
    Dec(ATop);
    FElemTop := ATop;

    if ATop = 0 then
    begin
      if FConformanceLevel = TACLXMLConformanceLevel.Document then
        FCurrentState := TStates.AfterRootEle
      else
        FCurrentState := TStates.TopLevel;
    end;
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteStartAttribute(APrefix: string; ALocalName: string; ANamespaceName: string);
label
  SkipPushAndWrite;
var
  ADefinedNs: string;
begin
  try
    if ALocalName = '' then
    begin
      if APrefix = 'xmlns' then
      begin
        ALocalName := 'xmlns';
        APrefix := '';
      end
      else
        raise EACLXMLArgumentException.Create(SXmlEmptyLocalName);
    end;
    CheckNCName(ALocalName);

    AdvanceState(TToken.StartAttribute);

    if APrefix = '' then
    begin
      if ANamespaceName <> '' then
      begin
        if not ((ALocalName = 'xmlns') and (ANamespaceName = TACLXMLReservedNamespaces.XmlNs)) then
          APrefix := LookupPrefix(ANamespaceName);
      end;
    end;
    if ANamespaceName = '' then
    begin
      if APrefix <> '' then
        ANamespaceName := LookupNamespace(APrefix);
    end;

    if APrefix = '' then
    begin
      if (ALocalName[1] = 'x') and (ALocalName = 'xmlns') then
      begin
        if (ANamespaceName <> '') and (ANamespaceName <> TACLXMLReservedNamespaces.XmlNs) then
          raise EACLXMLArgumentException.Create(SXmlXmlnsPrefix);

        FCurDeclPrefix := '';
        SetSpecialAttribute(TSpecialAttribute.DefaultXmlns);
        goto SkipPushAndWrite;
      end
      else
        if ANamespaceName <> '' then
        begin
          APrefix := LookupPrefix(ANamespaceName);
          if APrefix = '' then
            APrefix := GeneratePrefix;
        end;
    end
    else
    begin
      if APrefix[1] = 'x' then
      begin
        if APrefix = 'xmlns' then
        begin
          if (ANamespaceName <> '') and (ANamespaceName <> TACLXMLReservedNamespaces.XmlNs) then
            raise EACLXMLArgumentException.Create(SXmlXmlnsPrefix);

          FCurDeclPrefix := ALocalName;
          SetSpecialAttribute(TSpecialAttribute.PrefixedXmlns);
          goto SkipPushAndWrite;
        end
        else
          if APrefix = 'xml' then
          begin
            if (ANamespaceName <> '') and (ANamespaceName <> TACLXMLReservedNamespaces.Xml) then
              raise EACLXMLArgumentException.Create('Xml_XmlPrefix');

            if ALocalName = 'space' then
            begin
              SetSpecialAttribute(TSpecialAttribute.XmlSpace);
              goto SkipPushAndWrite;
            end;
            if ALocalName = 'lang' then
            begin
              SetSpecialAttribute(TSpecialAttribute.XmlLang);
              goto SkipPushAndWrite;
            end;
          end;
      end;

      CheckNCName(APrefix);

      if ANamespaceName = '' then
        APrefix := ''
      else
      begin
        ADefinedNs := LookupLocalNamespace(APrefix);
        if (ADefinedNs <> '') and (ADefinedNs <> ANamespaceName) then
          APrefix := GeneratePrefix;
      end;
    end;

    if APrefix <> '' then
      PushNamespaceImplicit(APrefix, ANamespaceName);

SkipPushAndWrite:
    //# add attribute to the list and check for duplicates
    AddAttribute(APrefix, ALocalName, ANamespaceName);

    if FSpecAttr = TSpecialAttribute.No then
      FWriter.WriteStartAttribute(APrefix, ALocalName, ANamespaceName);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteEndAttribute;
var
  AValue: string;
begin
  try
    AdvanceState(TToken.EndAttribute);

    if FSpecAttr <> TSpecialAttribute.No then
    begin
      case FSpecAttr of
        TSpecialAttribute.DefaultXmlns:
          begin
            AValue := FAttrValueCache.StringValue;
            if PushNamespaceExplicit('', AValue) then
            begin
              if FWriter.SupportsNamespaceDeclarationInChunks then
              begin
                FWriter.WriteStartNamespaceDeclaration('');
                FAttrValueCache.Replay(FWriter);
                FWriter.WriteEndNamespaceDeclaration;
              end
              else
                FWriter.WriteNamespaceDeclaration('', AValue);
            end;
            FCurDeclPrefix := '';
          end;
        TSpecialAttribute.PrefixedXmlns:
          begin
            AValue := FAttrValueCache.StringValue;
            if AValue = '' then
              raise EACLXMLArgumentException.Create(SXmlPrefixForEmptyNs);

            if (AValue = TACLXMLReservedNamespaces.XmlNs) or ((AValue = TACLXMLReservedNamespaces.Xml) and (FCurDeclPrefix <> 'xml')) then
              raise EACLXMLArgumentException.Create(SXmlCanNotBindToReservedNamespace);

            if PushNamespaceExplicit(FCurDeclPrefix, AValue) then
            begin
              if FWriter.SupportsNamespaceDeclarationInChunks then
              begin
                FWriter.WriteStartNamespaceDeclaration(FCurDeclPrefix);
                FAttrValueCache.Replay(FWriter);
                FWriter.WriteEndNamespaceDeclaration;
              end
              else
                FWriter.WriteNamespaceDeclaration(FCurDeclPrefix, AValue);
            end;
            FCurDeclPrefix := '';
          end;
        TSpecialAttribute.XmlSpace:
          begin
            FAttrValueCache.Trim;
            AValue := FAttrValueCache.StringValue;

            if AValue = 'default' then
              FElemScopeStack[FElemTop].xmlSpace := TACLXMLSpace.Default
            else
              if AValue = 'preserve' then
                FElemScopeStack[FElemTop].xmlSpace := TACLXMLSpace.Preserve
              else
                raise EACLXMLArgumentException.CreateFmt(SXmlInvalidXmlSpace, [AValue]);

            FWriter.WriteStartAttribute('xml', 'space', TACLXMLReservedNamespaces.Xml);
            FAttrValueCache.Replay(FWriter);
            FWriter.WriteEndAttribute;
          end;
        TSpecialAttribute.XmlLang:
          begin
            AValue := FAttrValueCache.StringValue;
            FElemScopeStack[FElemTop].xmlLang := AValue;
            FWriter.WriteStartAttribute('xml', 'lang', TACLXMLReservedNamespaces.Xml);
            FAttrValueCache.Replay(FWriter);
            FWriter.WriteEndAttribute;
          end;
      end;
      FSpecAttr := TSpecialAttribute.No;
      FAttrValueCache.Clear;
    end
    else
      FWriter.WriteEndAttribute;
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteCData(const AText: string);
begin
  try
    AdvanceState(TToken.CData);
    FWriter.WriteCData(AText);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteComment(const AText: string);
begin
  try
    AdvanceState(TToken.Comment);
    FWriter.WriteComment(AText);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteProcessingInstruction(const AName, AText: string);
begin
  try
    if AName = '' then
      raise EACLXMLArgumentException.Create(SXmlEmptyName);

    CheckNCName(AName);

    if (Length(AName) = 3) and SameText(AName, 'xml') then
    begin
      if FCurrentState <> TStates.Start then
        if FConformanceLevel = TACLXMLConformanceLevel.Document then
          raise EACLXMLArgumentException.Create(SXmlDupXmlDecl)
        else
          raise EACLXMLArgumentException.Create(SXmlCannotWriteXmlDecl);

      FXmlDeclFollows := True;
      AdvanceState(TToken.PI);

      FWriter.WriteXmlDeclaration(AText);
    end
    else
    begin
      AdvanceState(TToken.PI);
      FWriter.WriteProcessingInstruction(AName, AText);
    end;
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteEntityRef(const AName: string);
begin
  try
    if AName = '' then
      raise EACLXMLArgumentException.Create(SXmlEmptyName);

    CheckNCName(AName);

    AdvanceState(TToken.Text);
    if SaveAttrValue then
      FAttrValueCache.WriteEntityRef(AName)
    else
      FWriter.WriteEntityRef(AName);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteCharEntity(ACh: Char);
begin
  try
    if ACh.IsSurrogate then
      raise EACLXMLArgumentException.Create(SXmlInvalidSurrogateMissingLowChar);
    AdvanceState(TToken.Text);
    if SaveAttrValue then
      FAttrValueCache.WriteCharEntity(ACh)
    else
      FWriter.WriteCharEntity(ACh);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char);
begin
  try
    if not Char.IsSurrogatePair(AHighChar, ALowChar) then
      raise EACLXMLInvalidSurrogatePairException.Create(ALowChar, AHighChar);

    AdvanceState(TToken.Text);
    if SaveAttrValue then
      FAttrValueCache.WriteSurrogateCharEntity(ALowChar, AHighChar)
    else
      FWriter.WriteSurrogateCharEntity(ALowChar, AHighChar);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteWhitespace(const AWs: string);
begin
  try
    if not TACLXMLCharType.IsOnlyWhitespace(AWs) then
      raise EACLXMLArgumentException.Create(SXmlNonWhitespace);

    AdvanceState(TToken.Whitespace);
    if SaveAttrValue then
      FAttrValueCache.WriteWhitespace(AWs)
    else
      FWriter.WriteWhitespace(AWs);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteString(const AText: string);
begin
  try
    if AText = '' then
      Exit;

    AdvanceState(TToken.Text);
    if SaveAttrValue then
      FAttrValueCache.WriteString(AText)
    else
      FWriter.WriteString(AText);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteChars(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
begin
  try
    if ABuffer = nil then
      raise EACLXMLArgumentNullException.Create('buffer');

    if AIndex < 0 then
      raise EACLXMLArgumentOutOfRangeException.Create('index');

    if ACount < 0 then
      raise EACLXMLArgumentOutOfRangeException.Create('count');

    if ACount > Length(ABuffer) - AIndex then
      raise EACLXMLArgumentOutOfRangeException.Create('count');

    AdvanceState(TToken.Text);
    if SaveAttrValue then
      FAttrValueCache.WriteChars(ABuffer, AIndex, ACount)
    else
      FWriter.WriteChars(ABuffer, AIndex, ACount);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
begin
  try
    if ABuffer = nil then
      raise EACLXMLArgumentNullException.Create('buffer');

    if AIndex < 0 then
      raise EACLXMLArgumentOutOfRangeException.Create('index');

    if ACount < 0 then
      raise EACLXMLArgumentOutOfRangeException.Create('count');

    if ACount > Length(ABuffer) - AIndex then
      raise EACLXMLArgumentOutOfRangeException.Create('count');

    AdvanceState(TToken.RawData);
    if SaveAttrValue then
      FAttrValueCache.WriteRaw(ABuffer, AIndex, ACount)
    else
      FWriter.WriteRaw(ABuffer, AIndex, ACount);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteRaw(const AData: string);
begin
  try
    if AData = '' then
      Exit;

    AdvanceState(TToken.RawData);
    if SaveAttrValue then
      FAttrValueCache.WriteRaw(AData)
    else
      FWriter.WriteRaw(AData);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

//procedure TACLXMLWellFormedWriter.WriteBase64(const ABuffer: TBytes; AIndex: Integer; ACount: Integer);
//begin
//  try
//    if ABuffer = nil then
//      raise EACLXMLArgumentNullException.Create('buffer');
//    if AIndex < 0 then
//      raise EACLXMLArgumentOutOfRangeException.Create('index');
//    if ACount < 0 then
//      raise EACLXMLArgumentOutOfRangeException.Create('count');
//    if ACount > Length(ABuffer) - AIndex then
//      raise EACLXMLArgumentOutOfRangeException.Create('count');
//
//    AdvanceState(TToken.Base64);
//    FWriter.WriteBase64(ABuffer, AIndex, ACount);
//  except
//    FCurrentState := TStates.Error;
//    raise;
//  end;
//end;

procedure TACLXMLWellFormedWriter.Close;
begin
  if FCurrentState <> TStates.Closed then
  begin
    try
      if FWriteEndDocumentOnClose then
      begin
        while (FCurrentState <> TStates.Error) and (FElemTop > 0) do
          WriteEndElement;
      end
      else
      begin
        if (FCurrentState <> TStates.Error) and (FElemTop > 0) then
        try
          AdvanceState(TToken.EndElement);
        except
          FCurrentState := TStates.Error;
          raise;
        end;
      end;

//      if InBase64 then
//        FWriter.WriteEndBase64;

      FWriter.Flush;
    finally
      try
        FWriter.Close;
      finally
        FCurrentState := TStates.Closed;
      end;
    end;
  end;
end;

procedure TACLXMLWellFormedWriter.Flush;
begin
  try
    FWriter.Flush;
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

function TACLXMLWellFormedWriter.LookupPrefix(const ANs: string): string;
var
  I: Integer;
  APrefix: string;
begin
  try
    if ANs = '' then
      raise EACLXMLArgumentNullException.Create('ns');
    I := FNsTop;
    while I >= 0 do
    begin
      if FNsStack[I].NamespaceUri = ANs then
      begin
        APrefix := FNsStack[I].Prefix;
        Inc(I);
        while I <= FNsTop do
        begin
          if FNsStack[I].Prefix = APrefix then
            Exit('');
          Inc(I);
        end;
        Exit(APrefix);
      end;
      Dec(I);
    end;
    if FPredefinedNamespaces <> nil then
      Result := FPredefinedNamespaces.LookupPrefix(ANs)
    else
      Result := '';
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

function TACLXMLWellFormedWriter.GetXmlSpace: TACLXMLSpace;
var
  I: Integer;
begin
  I := FElemTop;
  while (I >= 0) and (FElemScopeStack[I].XmlSpace = TACLXMLSpace(-1)) do
    Dec(I);
  Assert(I >= 0);
  Result := FElemScopeStack[I].XmlSpace;
end;

function TACLXMLWellFormedWriter.GetXmlLang: string;
var
  I: Integer;
begin
  I := FElemTop;
  while (I > 0) and (FElemScopeStack[I].XmlLang = '') do
    Dec(I);
  Assert(I >= 0);
  Result := FElemScopeStack[I].XmlLang;
end;

procedure TACLXMLWellFormedWriter.ThrowInvalidStateTransition(AToken: TToken; ACurrentState: TState);
var
  AWrongTokenMessage: string;
begin
  AWrongTokenMessage := Format(SXmlWrongToken, [Ord(AToken), Ord(ACurrentState)]);
  case ACurrentState of
    TStates.AfterRootEle, TStates.Start:
      if FConformanceLevel = TACLXMLConformanceLevel.Document then
        raise EACLXMLInvalidOperationException.Create(AWrongTokenMessage + ' ' + SXmlConformanceLevelFragment);
  end;
  raise EACLXMLInvalidOperationException.Create(AWrongTokenMessage);
end;

procedure TACLXMLWellFormedWriter.WriteQualifiedName(const ALocalName, ANs: string);
var
  APrefix: string;
begin
  try
    if ALocalName = '' then
      raise EACLXMLArgumentException.Create(SXmlEmptyLocalName);

    CheckNCName(ALocalName);

    AdvanceState(TToken.Text);
    APrefix := '';
    if ANs <> '' then
    begin
      APrefix := LookupPrefix(ANs);
      if APrefix = '' then
      begin
        if FCurrentState <> TStates.Attribute then
          raise EACLXMLArgumentException.CreateFmt(SXmlUndefNamespace, [ANs]);

        APrefix := GeneratePrefix;
        PushNamespaceImplicit(APrefix, ANs);
      end;
    end;

    if SaveAttrValue then
    begin
      if APrefix <> '' then
      begin
        WriteString(APrefix);
        WriteString(':');
      end;
      WriteString(ALocalName);
    end
    else
      FWriter.WriteQualifiedName(APrefix, ALocalName, ANs);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteValue(const AValue: string);
begin
  try
    if AValue = '' then
      Exit;
    if SaveAttrValue then
    begin
      AdvanceState(TToken.Text);
      FAttrValueCache.WriteValue(AValue);
    end
    else
    begin
      AdvanceState(TToken.AtomicValue);
      FWriter.WriteValue(AValue);
    end;
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteBinHex(const ABuffer: TBytes; AIndex: Integer; ACount: Integer);
begin
  if IsClosedOrErrorState then
    raise EACLXMLInvalidOperationException.Create(SXmlClosedOrError);
  try
    AdvanceState(TToken.Text);
    inherited WriteBinHex(ABuffer, AIndex, ACount);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

function TACLXMLWellFormedWriter.GetSaveAttrValue: Boolean;
begin
  Result := FSpecAttr <> TSpecialAttribute.No;
end;

function TACLXMLWellFormedWriter.GetInBase64: Boolean;
begin
  Result := FCurrentState in [TStates.B64Content, TStates.B64Attribute, TStates.RootLevelB64Attr];
end;

procedure TACLXMLWellFormedWriter.SetSpecialAttribute(ASpecial: TSpecialAttribute);
begin
  FSpecAttr := ASpecial;
  if TStates.Attribute = FCurrentState then
    FCurrentState := TStates.SpecialAttr
  else
    if TStates.RootLevelAttr = FCurrentState then
      FCurrentState := TStates.RootLevelSpecAttr
    else
      Assert(False, 'State.Attribute == currentState || State.RootLevelAttr == currentState');

  if FAttrValueCache = nil then
    FAttrValueCache := TAttributeValueCache.Create;
end;

procedure TACLXMLWellFormedWriter.WriteStartDocumentImpl(AStandalone: TACLXMLStandalone);
begin
  try
    AdvanceState(TToken.StartDocument);

    if FConformanceLevel = TACLXMLConformanceLevel.Auto then
    begin
      FConformanceLevel := TACLXMLConformanceLevel.Document;
      FStateTable := FStateTableDocument;
    end
    else
      if FConformanceLevel = TACLXMLConformanceLevel.Fragment then
        raise EACLXMLInvalidOperationException.Create(SXmlCannotStartDocumentOnFragment);

    if not FXmlDeclFollows then
      FWriter.WriteXmlDeclaration(AStandalone);
  except
    FCurrentState := TStates.Error;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.StartFragment;
begin
  FConformanceLevel := TACLXMLConformanceLevel.Fragment;
  Assert(FStateTable = FStateTableAuto);
end;

//# PushNamespaceImplicit is called when a prefix/namespace pair is used in an element name, attribute name or some other qualified name.
procedure TACLXMLWellFormedWriter.PushNamespaceImplicit(const APrefix, ANs: string);
var
  AKind: TNamespaceKind;
  AExistingNsIndex: Integer;
  ADefinedNs: string;
begin
  //# See if the prefix is already defined
  AExistingNsIndex := LookupNamespaceIndex(APrefix);
  //# Prefix is already defined
  if AExistingNsIndex <> -1 then
  begin
    //# It is defined in the current scope
    if AExistingNsIndex > FElemScopeStack[FElemTop].PrevNSTop then
    begin
      //# The new namespace Uri needs to be the same as the one that is already declared
      if FNsStack[AExistingNsIndex].NamespaceUri <> ANs then
        raise EACLXMLException.CreateFmt(SXmlRedefinePrefix, [APrefix, FNsStack[AExistingNsIndex].NamespaceUri, ANs]);
      //# No additional work needed
      Exit;
    end
    else
    //# The prefix is defined but in a different scope
    begin
      //# existing declaration is special one (xml, xmlns) -> validate that the new one is the same and can be declared
      if FNsStack[AExistingNsIndex].Kind = TNamespaceKind.Special then
      begin
        if APrefix = 'xml' then
        begin
          if ANs <> FNsStack[AExistingNsIndex].namespaceUri then
            raise EACLXMLArgumentException.Create(SXmlXmlPrefix)
          else
            AKind := TNamespaceKind.Implied;
        end
        else
        begin
          Assert(APrefix = 'xmlns');
          raise EACLXMLArgumentException.Create(SXmlXmlnsPrefix);
        end;
      end
      else
      //# regular namespace declaration -> compare the namespace Uris to decide if the prefix is redefined
      begin
        if (FNsStack[AExistingNsIndex].NamespaceUri = ANs) then
          AKind := TNamespaceKind.Implied
        else
          AKind := TNamespaceKind.NeedToWrite;
      end;
    end;
  end
  else
  //# No existing declaration found in the namespace stack
  begin
    //# validate special declaration (xml, xmlns)
    if ((ANs = TACLXMLReservedNamespaces.Xml) and (APrefix <> 'xml')) or ((ANs = TACLXMLReservedNamespaces.XmlNs) and (APrefix <> 'xmlns')) then
      raise EACLXMLArgumentException.CreateFmt(SXmlNamespaceDeclXmlXmlns, [APrefix]);
    //# check if it can be found in the predefinedNamespaces (which are provided by the user)
    if FPredefinedNamespaces <> nil then
    begin
      ADefinedNs := FPredefinedNamespaces.LookupNamespace(APrefix);
      //# compare the namespace Uri to decide if the prefix is redefined
      if ADefinedNs = ANs then
        AKind := TNamespaceKind.Implied
      else
        AKind := TNamespaceKind.NeedToWrite;
    end
    //# Namespace not declared anywhere yet, we need to write it out
    else
      AKind := TNamespaceKind.NeedToWrite;
  end;

  AddNamespace(APrefix, ANs, AKind);
end;

//# PushNamespaceExplicit is called when a namespace declaration is written out;
//# It returs true if the namespace declaration should we written out, false if it should be omited (if OmitDuplicateNamespaceDeclarations is true)
function TACLXMLWellFormedWriter.PushNamespaceExplicit(const APrefix, ANs: string): Boolean;
var
  AWriteItOut: Boolean;
  AExistingNsIndex: Integer;
  AExistingNsKind: TNamespaceKind;
  ADefinedNs: string;
begin
  AWriteItOut := True;
  //# See if the prefix is already defined
  AExistingNsIndex := LookupNamespaceIndex(APrefix);
  //# Existing declaration in the current scope
  if AExistingNsIndex <> -1 then
  begin
    //# It is defined in the current scope
    if AExistingNsIndex > FElemScopeStack[FElemTop].PrevNSTop then
    begin
      //# The new namespace Uri needs to be the same as the one that is already declared
      if (FNsStack[AExistingNsIndex].NamespaceUri <> ANs) and (APrefix <> '') then
        raise EACLXMLException.CreateFmt(SXmlRedefinePrefix, [APrefix, FNsStack[AExistingNsIndex].NamespaceUri, ANs]);
      //# Check for duplicate declarations
      AExistingNsKind := FNsStack[AExistingNsIndex].kind;
      if AExistingNsKind = TNamespaceKind.Written then
      begin
        if APrefix = '' then
          raise DupAttrException('', 'xmlns')
        else
          raise DupAttrException('xmlns', APrefix);
      end;
      //# Check if it can be omitted
      if FOmitDuplNamespaces and (AExistingNsKind <> TNamespaceKind.NeedToWrite) then
        AWriteItOut := False;
      FNsStack[AExistingNsIndex].Kind := TNamespaceKind.Written;
       //# No additional work needed
      Exit(AWriteItOut);
    end
    //# The prefix is defined but in a different scope
    else
    begin
      //# check if is the same and can be omitted
      if FOmitDuplNamespaces and (FNsStack[AExistingNsIndex].NamespaceUri = ANs) then
        AWriteItOut := False;
    end;
  end
  //# No existing declaration found in the namespace stack
  else
  begin
    //# check if it can be found in the predefinedNamespaces (which are provided by the user)
    if FPredefinedNamespaces <> nil then
    begin
      ADefinedNs := FPredefinedNamespaces.LookupNamespace(APrefix);
      //# compare the namespace Uri to decide if the prefix is redefined
      if FOmitDuplNamespaces and (ADefinedNs = ANs) then
        AWriteItOut := False;
    end;
  end;
  //# validate special declaration (xml, xmlns)
  if ((ANs = TACLXMLReservedNamespaces.Xml) and (APrefix <> 'xml')) or ((ANs = TACLXMLReservedNamespaces.XmlNs) and (APrefix <> 'xmlns')) then
    raise EACLXMLArgumentException.CreateFmt(SXmlNamespaceDeclXmlXmlns, [APrefix]);
  if (APrefix <> '') and (APrefix[1] = 'x') then
  begin
    if APrefix = 'xml' then
    begin
      if ANs <> TACLXMLReservedNamespaces.Xml then
        raise EACLXMLArgumentException.Create(SXmlXmlPrefix);
    end
    else
      if APrefix = 'xmlns' then
        raise EACLXMLArgumentException.Create(SXmlXmlnsPrefix);
  end;
  AddNamespace(APrefix, ANs, TNamespaceKind.Written);
  Result := AWriteItOut;
end;

procedure TACLXMLWellFormedWriter.AddNamespace(const APrefix, ANs: string; AKind: TNamespaceKind);
var
  ATop, I: Integer;
begin
  Inc(FNsTop);
  ATop := FNsTop;
  if ATop = Length(FNsStack) then
    SetLength(FNsStack, ATop * 2);

  FNsStack[ATop].&Set(APrefix, ANs, AKind);

  if FUseNsHashTable then
    AddToNamespaceHashtable(FNsTop)
  else
    if FNsTop = MaxNamespacesWalkCount then
    begin
      FNsHashTable.Free;
      FNsHashTable := TDictionary<string, Integer>.Create;
      for I := 0 to FNsTop do
        AddToNamespaceHashtable(I);
      FUseNsHashTable := True;
    end;
end;

procedure TACLXMLWellFormedWriter.AddToNamespaceHashtable(ANamespaceIndex: Integer);
var
  APrefix: string;
  AExistingNsIndex: Integer;
begin
  APrefix := FNsStack[ANamespaceIndex].Prefix;
  if FNsHashTable.TryGetValue(APrefix, AExistingNsIndex) then
    FNsStack[ANamespaceIndex].PrevNsIndex := AExistingNsIndex;
  FNsHashTable.AddOrSetValue(APrefix, ANamespaceIndex);
end;

function TACLXMLWellFormedWriter.LookupNamespaceIndex(const APrefix: string): Integer;
var
  AIndex, I: Integer;
begin
  if FUseNsHashTable then
  begin
    if FNsHashTable.TryGetValue(APrefix, AIndex) then
      Exit(AIndex);
  end
  else
  begin
    for I := FNsTop downto 0 do
      if FNsStack[I].Prefix = APrefix then
        Exit(I);
  end;
  Result := -1;
end;

procedure TACLXMLWellFormedWriter.PopNamespaces(AIndexFrom: Integer; AIndexTo: Integer);
var
  I: Integer;
begin
  Assert(FUseNsHashTable);
  Assert(AIndexFrom <= AIndexTo);
  for I := AIndexTo downto AIndexFrom do
  begin
    Assert(FNsHashTable.ContainsKey(FNsStack[I].Prefix));
    if FNsStack[I].prevNsIndex = -1 then
      FNsHashTable.Remove(FNsStack[I].Prefix)
    else
      FNsHashTable[FNsStack[I].Prefix] := FNsStack[I].PrevNsIndex;
  end;
end;

class function TACLXMLWellFormedWriter.DupAttrException(const APrefix, ALocalName: string): EACLXMLException;
var
  ASb: TStringBuilder;
begin
  ASb := TStringBuilder.Create;
  try
    if APrefix <> '' then
    begin
      ASb.Append(APrefix);
      ASb.Append(':');
    end;
    ASb.Append(ALocalName);
    Result := EACLXMLException.CreateFmt(SXmlDupAttributeName, [ASb.ToString]);
  finally
    ASb.Free;
  end;
end;

//# Advance the state machine
procedure TACLXMLWellFormedWriter.AdvanceState(AToken: TToken);
label
  Advance;
var
  ANewState: TState;
begin
  if FCurrentState >= TStates.Closed then
  begin
    if (FCurrentState = TStates.Closed) or (FCurrentState = TStates.Error) then
      raise EACLXMLInvalidOperationException.Create(SXmlClosedOrError)
    else
      raise EACLXMLInvalidOperationException.CreateFmt(SXmlWrongToken, [Ord(AToken), Ord(FCurrentState)]);
  end;
Advance:
  ANewState := FStateTable[(Ord(AToken) shl 4) + Ord(FCurrentState)];
  if ANewState >= TStates.Error then
  begin
    case ANewState of
      TStates.Error:
        ThrowInvalidStateTransition(AToken, FCurrentState);
      TStates.StartContent:
        begin
          StartElementContent;
          ANewState := TStates.Content;
        end;
      TStates.StartContentEle:
        begin
          StartElementContent;
          ANewState := TStates.Element;
        end;
      TStates.StartContentB64:
        begin
          StartElementContent;
          ANewState := TStates.B64Content;
        end;
      TStates.StartDoc:
        begin
          WriteStartDocument;
          ANewState := TStates.Document;
        end;
      TStates.StartDocEle:
        begin
          WriteStartDocument;
          ANewState := TStates.Element;
        end;
      TStates.EndAttrSEle:
        begin
          WriteEndAttribute;
          StartElementContent;
          ANewState := TStates.Element;
        end;
      TStates.EndAttrEEle:
        begin
          WriteEndAttribute;
          StartElementContent;
          ANewState := TStates.Content;
        end;
      TStates.EndAttrSCont:
        begin
          WriteEndAttribute;
          StartElementContent;
          ANewState := TStates.Content;
        end;
      TStates.EndAttrSAttr:
        begin
          WriteEndAttribute;
          ANewState := TStates.Attribute;
        end;
      TStates.PostB64Cont:
        begin
          //FWriter.WriteEndBase64;
          FCurrentState := TStates.Content;
          goto Advance;
        end;
      TStates.PostB64Attr:
        begin
          //FWriter.WriteEndBase64;
          FCurrentState := TStates.Attribute;
          goto Advance;
        end;
      TStates.PostB64RootAttr:
        begin
          //FWriter.WriteEndBase64;
          FCurrentState := TStates.RootLevelAttr;
          goto Advance;
        end;
      TStates.StartFragEle:
        begin
          StartFragment;
          ANewState := TStates.Element;
        end;
      TStates.StartFragCont:
        begin
          StartFragment;
          ANewState := TStates.Content;
        end;
      TStates.StartFragB64:
        begin
          StartFragment;
          ANewState := TStates.B64Content;
        end;
      TStates.StartRootLevelAttr:
        begin
          WriteEndAttribute;
          ANewState := TStates.RootLevelAttr;
        end;
      else
        Assert(False, 'We should not get to this point.');
    end;
  end;

  FCurrentState := ANewState;
end;

procedure TACLXMLWellFormedWriter.StartElementContent;
var
  AStart, I: Integer;
begin
  AStart := FElemScopeStack[FElemTop].prevNSTop;
  for I := FNsTop downto AStart + 1 do
  begin
    if FNsStack[I].kind = TNamespaceKind.NeedToWrite then
      FNsStack[I].WriteDecl(FWriter, FWriter);
  end;

  FWriter.StartElementContent;
end;

function TACLXMLWellFormedWriter.LookupNamespace(const APrefix: string): string;
var
  I: Integer;
begin
  for I := FNsTop downto 0 do
  begin
    if FNsStack[I].Prefix = APrefix then
      Exit(FNsStack[I].NamespaceUri);
  end;
  if FPredefinedNamespaces <> nil then
    Result := FPredefinedNamespaces.LookupNamespace(APrefix)
  else
    Result := '';
end;

function TACLXMLWellFormedWriter.LookupLocalNamespace(const APrefix: string): string;
var
  I: Integer;
begin
  for I := FNsTop downto FElemScopeStack[FElemTop].PrevNSTop + 1 do
    if FNsStack[I].Prefix = APrefix then
      Exit(FNsStack[I].NamespaceUri);
  Result := '';
end;

function TACLXMLWellFormedWriter.GeneratePrefix: string;
var
  AGenPrefix, S: string;
  I: Integer;
begin
  AGenPrefix := 'p' + IntToStr(FNsTop - 2);
  if LookupNamespace(AGenPrefix) = '' then
    Exit(AGenPrefix);

  I := 0;
  repeat
    S := AGenPrefix + IntToStr(I);
    Inc(I);
  until not (LookupNamespace(S) <> '');
  Result := S;
end;

procedure TACLXMLWellFormedWriter.CheckNCName(const ANcname: string);
var
  ALen: Integer;
  P, AStart: PChar;
begin
  Assert(ANcname <> '');
  AStart := PChar(ANcname);
  if (TACLXMLCharType.CharProperties[AStart^] and TACLXMLCharType.NCStartNameSC) = 0 then
    raise InvalidCharsException(ANcname, 0);

  P := AStart + 1;
  ALen := Length(ANcname) - 1;
  while ALen > 0 do
  begin
    if (TACLXMLCharType.CharProperties[P^] and TACLXMLCharType.NCNameSC) <> 0 then
      Inc(P)
    else
      raise InvalidCharsException(ANcname, P - AStart);
    Dec(ALen);
  end;
end;

class function TACLXMLWellFormedWriter.InvalidCharsException(const AName: string; ABadCharIndex: Integer): EACLXMLException;
begin
  Result := EACLXMLException.CreateFmt(SXmlInvalidNameCharsDetail, [AName, ABadCharIndex, TACLFastHex.Encode(AName[ABadCharIndex + 1])]);
end;

function TACLXMLWellFormedWriter.GetIsClosedOrErrorState: Boolean;
begin
  Result := FCurrentState >= TStates.Closed;
end;

procedure TACLXMLWellFormedWriter.AddAttribute(const APrefix, ALocalName, ANamespaceName: string);
var
  I, ATop, APrev: Integer;
begin
  ATop := FAttrCount;
  Inc(FAttrCount);
  if ATop = Length(FAttrStack) then
    SetLength(FAttrStack, ATop * 2);
  FAttrStack[ATop].&Set(APrefix, ALocalName, ANamespaceName);

  if FAttrCount < MaxAttrDuplWalkCount then
  begin
    for I := 0 to ATop - 1 do
      if FAttrStack[I].IsDuplicate(APrefix, ALocalName, ANamespaceName) then
        raise DupAttrException(APrefix, ALocalName);
  end
  else
  begin
    if FAttrCount = MaxAttrDuplWalkCount then
    begin
      if FAttrHashTable = nil then
        FAttrHashTable := TDictionary<string, Integer>.Create;
      Assert(FAttrHashTable.Count = 0);
      for I := 0 to ATop - 1 do
        AddToAttrHashTable(I);
    end;

    AddToAttrHashTable(ATop);
    APrev := FAttrStack[ATop].Prev;
    while APrev > 0 do
    begin
      Dec(APrev);
      if FAttrStack[APrev].IsDuplicate(APrefix, ALocalName, ANamespaceName) then
        raise DupAttrException(APrefix, ALocalName);
      APrev := FAttrStack[APrev].Prev;
    end;
  end;
end;

procedure TACLXMLWellFormedWriter.AddToAttrHashTable(AAttributeIndex: Integer);
var
  ALocalName: string;
  ACount, APrev: Integer;
begin
  ALocalName := FAttrStack[AAttributeIndex].LocalName;
  ACount := FAttrHashTable.Count;
  FAttrHashTable.AddOrSetValue(ALocalName, 0);
  if ACount <> FAttrHashTable.Count then
    Exit;

  APrev := AAttributeIndex - 1;
  while APrev >= 0 do
  begin
    if FAttrStack[APrev].localName = ALocalName then
      Break;
    Dec(APrev);
  end;
  Assert((APrev >= 0) and (FAttrStack[APrev].LocalName = ALocalName));
  FAttrStack[AAttributeIndex].Prev := APrev + 1;
end;

end.
