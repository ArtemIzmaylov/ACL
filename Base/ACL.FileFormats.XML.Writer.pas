{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*         Stream based XML Writer           *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
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
  ACL.FileFormats.XML.Types,
  ACL.Utils.Strings;

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

  TACLXMLWriterSettings = record
  public
    CheckCharacters: Boolean;
    CheckWellformed: boolean;
    EncodeInvalidXmlCharAsUCS2: Boolean;
    IndentChars: string;
    NewLineChars: string;
    NewLineHandling: TACLXMLNewLineHandling;
    NewLineOnAttributes: Boolean;
    NewLineOnNode: Boolean;
    OmitXmlDeclaration: Boolean;

    class function Default: TACLXMLWriterSettings; static;
    procedure Reset;
  end;

  { TACLXMLWriter }

  TACLXMLWriter = class abstract
  protected
    function GetWriteState: TACLXMLWriteState; virtual; abstract;
  public
    class function Create(AStream: TStream; const ASettings: TACLXMLWriterSettings): TACLXMLWriter; static;

    procedure WriteStartDocument; overload;
    procedure WriteStartDocument(AStandalone: TACLXMLStandalone); overload; virtual; abstract;
    procedure WriteEndDocument; virtual; abstract;

    procedure WriteStartElement(const APrefix, ALocalName: string); overload; virtual; abstract;
    procedure WriteStartElement(const ALocalName: string); overload;
    procedure WriteEndElement; overload; virtual; abstract;
    procedure WriteFullEndElement; overload; virtual; abstract;
    procedure WriteElementString(const ALocalName, AValue: string); overload;
    procedure WriteElementString(const ALocalName: string; const AValue: AnsiString); overload;
    procedure WriteElementString(const APrefix, ALocalName, ANs, AValue: string); overload;

    procedure WriteAttributeBoolean(const ALocalName: string; AValue: Boolean); overload;
    procedure WriteAttributeBoolean(const APrefix, ALocalName: string; AValue: Boolean); overload;
    procedure WriteAttributeFloat(const ALocalName: string; AValue: Single); overload;
    procedure WriteAttributeFloat(const APrefix, ALocalName: string; AValue: Single); overload;
    procedure WriteAttributeInteger(const ALocalName: string; AValue: Integer); overload;
    procedure WriteAttributeInteger(const APrefix, ALocalName: string; AValue: Integer); overload;
    procedure WriteAttributeInt64(const ALocalName: string; const AValue: Int64); overload;
    procedure WriteAttributeInt64(const APrefix, ALocalName: string; const AValue: Int64); overload;
    procedure WriteAttributeString(const ALocalName, AValue: string); overload;
    procedure WriteAttributeString(const APrefix, ALocalName: string; const AValue: string); overload;
    procedure WriteAttributeString(const ALocalName: string; const AValue: AnsiString); overload;
    procedure WriteAttributeString(const APrefix, ALocalName: string; const AValue: AnsiString); overload;
    procedure WriteSpacePreserveAttribute;
    procedure WriteStartAttribute(const APrefix, ALocalName: string); overload; virtual; abstract;
    procedure WriteStartAttribute(const ALocalName: string); overload;
    procedure WriteEndAttribute; virtual; abstract;

    procedure WriteCData(const AText: string); virtual; abstract;
    procedure WriteComment(const AText: string); virtual; abstract;
    procedure WriteEntityRef(const AName: string); virtual; abstract;
    procedure WriteCharEntity(ACh: Char); virtual; abstract;

    // Value of attribute or node
    procedure WriteString(AStr: PChar; ALength: Integer); overload; virtual; abstract;
    procedure WriteString(const AText: string); overload;
    procedure WriteString(const AText: AnsiString); overload;
    procedure WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char); virtual; abstract;
    procedure WriteChars(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
    procedure WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer); overload; virtual; abstract;
    procedure WriteRaw(const AData: string); overload; virtual; abstract;

    procedure Close; virtual;
    procedure Flush; virtual;

    property WriteState: TACLXMLWriteState read GetWriteState;
  end;

implementation

uses
  System.Character;

{$REGION 'ErrorMessages'}
const
  SXmlInvalidSurrogatePair =
    'The surrogate pair (%s, %s) is invalid. A high surrogate character (0xD800 - 0xDBFF) must ' +
    'always be paired with a low surrogate character (0xDC00 - 0xDFFF).';
  SXmlClosedOrError = 'The Writer is closed or in error state.';
  SXmlDupAttributeName = '"%s" is a duplicate attribute name.';
  SXmlEmptyLocalName = 'The empty string is not a valid local name.';
  SXmlEmptyName = 'The empty string is not a valid name.';
  SXmlIndentCharsNotWhitespace = 'XmlWriterSettings.%s can contain only valid XML white space characters when ' +
    'XmlWriterSettings.CheckCharacters and XmlWriterSettings.NewLineOnAttributes are true.';
  SXmlInvalidCharsInIndent = 'WriterSettings.%s can contain only valid XML text content characters when XmlWriterSettings.CheckCharacters is true. %s';
  SXmlInvalidCharacter = '%s, hexadecimal value %s, is an invalid character.';
  SXmlInvalidHighSurrogateChar = 'Invalid high surrogate character (%s). A high surrogate character must have a value from range (0xD800 - 0xDBFF).';
  SXmlInvalidNameCharsDetail = 'Invalid name character in "%s". The %d character, hexadecimal value %s, cannot be included in a name.';
  SXmlInvalidSurrogateMissingLowChar = 'The surrogate pair is invalid. Missing a low surrogate character.';
  SXmlInvalidLocalName = 'The %s is invalid for local name';
  SXmlNoStartTag = 'There was no XML start tag open.';
  SXmlUnexpectedToken = 'The %s expected, but %s specified.';
{$ENDREGION}

type
  TACLXMLRawWriter = class;

  { EACLXMLInvalidSurrogatePairException }

  EACLXMLInvalidSurrogatePairException = class(EACLXMLArgumentException)
  public
    constructor Create(const ALowChar, AHighChar: Char);
  end;

  { TACLXMLRawWriter }

  TACLXMLRawWriter = class (TACLXMLWriter)
  strict private type
    TElementScope = record
      Prefix: string;
      LocalName: string;
    end;
    TState = (Start, &End, StartDoc, Element, ElementText, Attr, AttrText, Closed, Error);
    TToken = (StartDoc, EndDoc, StartElement, EndElement, StartAttr, EndAttr, Text);
  strict private const
    BufferSize  = 1024 * 64; //# Should be greater than default FileStream size (4096), otherwise the FileStream will try to cache the data
    BufferOverflowSize = 32; //# Allow overflow in order to reduce checks when writing out constant size markup
  strict private
    FEncoding: TEncoding;
    FStream: TStream;
    FState: TState;

    FIsXmlDeclarationWritten: boolean;
    FElementStack: TArray<TElementScope>;
    FElementStackTop: Integer;

    FBufChars: TCharArray;
    FBufLen: Integer;
    FBufPos: Integer;
    FNestingLevel: Integer;

    //# writer settings
    FCheckCharacters: Boolean;
    FEncodeInvalidXmlCharAsUCS2: Boolean;
    FIndentChars: string;
    FNewLineChars: string;
    FNewLineHandling: TACLXMLNewLineHandling;
    FNewLineOnAttributes: Boolean;
    FNewLineOnNode: Boolean;
    FOmitXmlDeclaration: Boolean;

    procedure FlushBuffer;
    procedure WriteAttributeTextBlock(ASrc: PChar; ASrcEnd: PChar);
    procedure WriteElementTextBlock(ASrc: PChar; ASrcEnd: PChar);
    procedure WriteNewLineAndAlignment(ANestingLevelCorrection: Integer = 0);
    procedure RawText(const S: string); overload;
    procedure RawText(ASrcBegin: PChar; ASrcEnd: PChar); overload;
    procedure WriteRawWithCharChecking(APSrcBegin: PChar; APSrcEnd: PChar);
    procedure WriteCommentOrPi(const AText: string; AStopChar: Char);
    function EncodeSurrogate(ASrc: PChar; ASrcEnd: PChar; ADst: PChar): PChar;
    function InvalidXmlChar(ACh: Char; ADst: PChar; AEntitize: Boolean): PChar;
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
    procedure Write(const ABuffer: TCharArray; AIndex, ALength: Integer); overload;
    procedure AdvanceState(AToken: TToken);
  strict protected
    function GetWriteState: TACLXMLWriteState; override; final;
    property Stream: TStream read FStream;
    property Encoding: TEncoding read FEncoding;
  public
    constructor CreateEx(AStream: TStream; const ASettings: TACLXMLWriterSettings);
    destructor Destroy; override;

    procedure WriteStartDocument(AStandalone: TACLXMLStandalone); override; final;
    procedure WriteEndDocument; override; final;
    procedure WriteXmlDeclaration(AStandalone: TACLXMLStandalone);

    procedure WriteStartElement(const APrefix, ALocalName: string); override;
    procedure WriteEndElement; override;
    procedure WriteFullEndElement; overload; override;

    procedure WriteStartAttribute(const APrefix, ALocalName: string); override;
    procedure WriteEndAttribute; override;

    procedure WriteCData(const AText: string); override;
    procedure WriteCharEntity(ACh: Char); override;
    procedure WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer); override;
    procedure WriteRaw(const AData: string); override;
    procedure WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char); override;
    procedure WriteComment(const AText: string); override;
    procedure WriteEntityRef(const AName: string); override;
    procedure WriteString(AStr: PChar; ALength: Integer); override;

    procedure Close; override;
    procedure Flush; override;
  end;

  { TACLXMLWellFormedWriter }

  TACLXMLWellFormedWriter = class(TACLXMLWriter)
  protected const
    AttributeArrayInitialSize = 8;
    ElementStackInitialSize = 8;
    NamespaceStackInitialSize = 8;
  protected type
  {$REGION 'Sub-Types'}

    TElementScope = record
      Prefix: string;
      PrevNSTop: Integer;
    end;

    TNamespace = record
    strict private
      FNamespace: string;
      FPrefix: string;
    public
      property Prefix: string read FPrefix write FPrefix;
      property Namespace: string read FNamespace write FNamespace;
    end;

    TAttrName = record
    strict private
      FPrefix: string;
      FLocalName: string;
    public
      constructor Create(const APrefix, ALocalName: string);

      property Prefix: string read FPrefix;
      property LocalName: string read FLocalName;
    end;

  {$ENDREGION}
  strict private
    FWriter: TACLXMLWriter;
    FIsError: boolean;

    FAttrCount: Integer;
    FAttrStack: TArray<TAttrName>;

    FCheckCharacters: Boolean;

    FIsNamespaceDeclaration: boolean;
    FCurrentDeclarationNamespacePrefix: string;
    FCurrentDeclarationNamespace: string;

    FElemScopeStack: TArray<TElementScope>;
    FElemTop: Integer;

    FNsStack: TArray<TNamespace>;
    FNsTop: Integer;
  strict private
    procedure AddAttribute(const APrefix, ALocalName: string);
    procedure CheckNCName(const ANcname: string);
    procedure PushNamespace(const APrefix, ANamespace: string);
    procedure StartElementContent;

    class function DupAttrException(const APrefix, ALocalName: string): EACLXMLException; static;
    class function InvalidCharsException(const AName: string; ABadCharIndex: Integer): EACLXMLException; static;
  protected
    function GetWriteState: TACLXMLWriteState; override;
    property InnerWriter: TACLXMLWriter read FWriter;
  public
    constructor Create(AWriter: TACLXMLWriter; const ASettings: TACLXMLWriterSettings);
    destructor Destroy; override;
    procedure Close; override;
    procedure Flush; override;
    procedure WriteCData(const AText: string); override;
    procedure WriteCharEntity(ACh: Char); override;
    procedure WriteComment(const AText: string); override;
    procedure WriteEndAttribute; override;
    procedure WriteEndDocument; override;
    procedure WriteEndElement; override;
    procedure WriteEntityRef(const AName: string); override;
    procedure WriteFullEndElement; override;
    procedure WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer); override;
    procedure WriteRaw(const AData: string); override;
    procedure WriteStartAttribute(const APrefix, ALocalName: string); override;
    procedure WriteStartDocument(AStandalone: TACLXMLStandalone); override;
    procedure WriteStartElement(const APrefix, ALocalName: string); override;
    procedure WriteString(AStr: PChar; ALength: Integer); override;
    procedure WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char); override;
  end;

{ EACLXMLInvalidSurrogatePairException }

constructor EACLXMLInvalidSurrogatePairException.Create(const ALowChar, AHighChar: Char);
begin
  CreateFmt(SXmlInvalidSurrogatePair, [TACLHexCode.Encode(ALowChar), TACLHexCode.Encode(AHighChar)]);
end;

{ TACLXMLWriterSettings }

class function TACLXMLWriterSettings.Default: TACLXMLWriterSettings;
begin
  Result.Reset;
end;

procedure TACLXMLWriterSettings.Reset;
begin
  CheckCharacters := True;
  CheckWellformed := True;
  IndentChars := #9;
  NewLineChars := sLineBreak;
  NewLineHandling := TACLXMLNewLineHandling.Replace;
  NewLineOnAttributes := False;
  NewLineOnNode := False;
  OmitXmlDeclaration := False;
  EncodeInvalidXmlCharAsUCS2 := True;
end;

{ TACLXMLWriter }

class function TACLXMLWriter.Create(AStream: TStream; const ASettings: TACLXMLWriterSettings): TACLXMLWriter;
begin
  Result := TACLXMLRawWriter.CreateEx(AStream, ASettings);
  if ASettings.CheckWellformed then
    Result := TACLXMLWellFormedWriter.Create(Result, ASettings);
end;

procedure TACLXMLWriter.Flush;
begin
  //# do nothing
end;

procedure TACLXMLWriter.WriteStartElement(const ALocalName: string);
begin
  WriteStartElement('', ALocalName);
end;

procedure TACLXMLWriter.WriteString(const AText: string);
begin
  WriteString(PChar(AText), Length(AText));
end;

procedure TACLXMLWriter.WriteString(const AText: AnsiString);
begin
  WriteString(acStringFromAnsiString(AText));
end;

procedure TACLXMLWriter.WriteChars(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
begin
  Assert(ABuffer <> nil);
  Assert(AIndex >= 0);
  Assert((ACount >= 0) and (AIndex + ACount <= Length(ABuffer)));

  WriteString(@ABuffer[AIndex], ACount);
end;

procedure TACLXMLWriter.WriteAttributeBoolean(const ALocalName: string; AValue: Boolean);
begin
  WriteAttributeString(ALocalName, sXMLBoolValues[AValue]);
end;

procedure TACLXMLWriter.WriteAttributeBoolean(const APrefix, ALocalName: string; AValue: Boolean);
begin
  WriteAttributeString(APrefix, ALocalName, sXMLBoolValues[AValue]);
end;

procedure TACLXMLWriter.WriteAttributeFloat(const APrefix, ALocalName: string; AValue: Single);
begin
  WriteAttributeString(APrefix, ALocalName, FloatToStr(AValue, TFormatSettings.Invariant));
end;

procedure TACLXMLWriter.WriteAttributeFloat(const ALocalName: string; AValue: Single);
begin
  WriteAttributeString(ALocalName, FloatToStr(AValue, TFormatSettings.Invariant));
end;

procedure TACLXMLWriter.WriteAttributeInteger(const ALocalName: string; AValue: Integer);
begin
  WriteAttributeString(ALocalName, IntToStr(AValue));
end;

procedure TACLXMLWriter.WriteAttributeInteger(const APrefix, ALocalName: string; AValue: Integer);
begin
  WriteAttributeString(APrefix, ALocalName, IntToStr(AValue));
end;

procedure TACLXMLWriter.WriteAttributeInt64(const ALocalName: string; const AValue: Int64);
begin
  WriteAttributeString(ALocalName, IntToStr(AValue));
end;

procedure TACLXMLWriter.WriteAttributeInt64(const APrefix, ALocalName: string; const AValue: Int64);
begin
  WriteAttributeString(APrefix, ALocalName, IntToStr(AValue));
end;

procedure TACLXMLWriter.WriteAttributeString(const ALocalName, AValue: string);
begin
  WriteStartAttribute('', ALocalName);
  WriteString(AValue);
  WriteEndAttribute;
end;

procedure TACLXMLWriter.WriteAttributeString(const APrefix, ALocalName, AValue: string);
begin
  WriteStartAttribute(APrefix, ALocalName);
  WriteString(AValue);
  WriteEndAttribute;
end;

procedure TACLXMLWriter.WriteAttributeString(const APrefix, ALocalName: string; const AValue: AnsiString);
begin
  WriteStartAttribute(APrefix, ALocalName);
  WriteString(AValue);
  WriteEndAttribute;
end;

procedure TACLXMLWriter.WriteAttributeString(const ALocalName: string; const AValue: AnsiString);
begin
  WriteStartAttribute('', ALocalName);
  WriteString(AValue);
  WriteEndAttribute;
end;

procedure TACLXMLWriter.WriteSpacePreserveAttribute;
begin
  WriteAttributeString('xml', 'space', 'preserve');
end;

procedure TACLXMLWriter.WriteStartAttribute(const ALocalName: string);
begin
  WriteStartAttribute('', ALocalName);
end;

procedure TACLXMLWriter.WriteStartDocument;
begin
  WriteStartDocument(TACLXMLStandalone.Omit);
end;

procedure TACLXMLWriter.Close;
begin
  //# do nothing
end;

procedure TACLXMLWriter.WriteElementString(const ALocalName, AValue: string);
begin
  WriteElementString('', ALocalName, '', AValue);
end;

procedure TACLXMLWriter.WriteElementString(const APrefix, ALocalName, ANs, AValue: string);
begin
  WriteStartElement(APrefix, ALocalName);
  if ANs <> '' then
    WriteAttributeString('xmlns', ANs);
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

{ TACLXMLRawWriter }

procedure TACLXMLRawWriter.Write(const ABuffer: TCharArray; AIndex, ALength: Integer);
var
  ABytes: TBytes;
begin
  ABytes := Encoding.GetBytes(ABuffer, AIndex, ALength);
  ALength := Length(ABytes);
  if ALength > 0 then
    Stream.WriteBuffer(ABytes[0], ALength);
end;

procedure TACLXMLRawWriter.WriteStartDocument(AStandalone: TACLXMLStandalone);
begin
  AdvanceState(TToken.StartDoc);
  WriteXmlDeclaration(AStandalone);
end;

procedure TACLXMLRawWriter.WriteEndDocument;
begin
end;

procedure TACLXMLRawWriter.WriteEndElement;
begin
  if FState <> TState.Element then
  begin
    WriteFullEndElement;
    Exit;
  end;

  AdvanceState(TToken.EndElement);
  Dec(FNestingLevel);
  Dec(FElementStackTop);

  //# Use shortcut syntax; overwrite the already output '>' character
  FBufChars[FBufPos] := '/';
  Inc(FBufPos);
  FBufChars[FBufPos] := '>';
  Inc(FBufPos);
end;

procedure TACLXMLRawWriter.WriteFullEndElement;
var
  ALocalName, APrefix: string;
begin
  if FState = TState.Element then
  begin
    FBufChars[FBufPos] := '>';
    Inc(FBufPos);
  end;

  AdvanceState(TToken.EndElement);

  Dec(FNestingLevel);
  APrefix := FElementStack[FElementStackTop].Prefix;
  ALocalName := FElementStack[FElementStackTop].LocalName;
  Dec(FElementStackTop);

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

function TACLXMLRawWriter.GetWriteState: TACLXMLWriteState;
const
  StateToWriteState: array[TState] of TACLXMLWriteState = (
    TACLXMLWriteState.Start,
    TACLXMLWriteState.Content,
    TACLXMLWriteState.Prolog,
    TACLXMLWriteState.Element,
    TACLXMLWriteState.Content,
    TACLXMLWriteState.Attribute,
    TACLXMLWriteState.Attribute,
    TACLXMLWriteState.Closed,
    TACLXMLWriteState.Error
  );
begin
  Result := StateToWriteState[FState];
end;

//# Construct an instance of this class that outputs text to the TextWriter interface.
constructor TACLXMLRawWriter.CreateEx(AStream: TStream; const ASettings: TACLXMLWriterSettings);
begin
  FStream := AStream;
  FEncoding := TEncoding.UTF8;
  FBufPos := 1;        //# buffer position starts at 1, because we need to be able to safely step back -1 in case we need to
                       //# close an empty element or in CDATA section detection of double ]; _BUFFER[0] will always be 0
  FBufLen := BufferSize;

  FIndentChars := ASettings.IndentChars;
  FNewLineHandling := ASettings.NewLineHandling;
  FOmitXmlDeclaration := ASettings.OmitXmlDeclaration;
  FNewLineChars := ASettings.NewLineChars;
  FCheckCharacters := ASettings.CheckCharacters;
  FEncodeInvalidXmlCharAsUCS2 := ASettings.EncodeInvalidXmlCharAsUCS2;
  FNewLineOnNode := ASettings.NewLineOnNode;
  FNewLineOnAttributes := ASettings.NewLineOnAttributes;

  if FCheckCharacters and (FNewLineHandling = TACLXMLNewLineHandling.Replace) then
    ValidateContentChars(FNewLineChars, 'NewLineChars', False);

  //# the buffer is allocated will BufferOverflowSize in order to reduce checks when writing out constant size markup
  SetLength(FBufChars, FBufLen + BufferOverflowSize);
  SetLength(FElementStack, 8);
  FElementStackTop := -1;

  FState := TState.Start;
end;

destructor TACLXMLRawWriter.Destroy;
begin
  Close;
  inherited;
end;

procedure TACLXMLRawWriter.AdvanceState(AToken: TToken);
var
  SaveState, State: TState;
begin
  State := Self.FState;
  if (State = TState.Element) and (AToken in [TToken.StartElement, TToken.Text]) then
  begin
    FBufChars[FBufPos] := '>';
    Inc(FBufPos);
  end;

  case Ord(FState) shl 16 + Ord(AToken) of
    Ord(TState.Start)       shl 16 + Ord(TToken.StartDoc)     : FState := TState.StartDoc;
    Ord(TState.Start)       shl 16 + Ord(TToken.StartElement) : FState := TState.Element;
    Ord(TState.StartDoc)    shl 16 + Ord(TToken.StartElement) : FState := TState.Element;
    Ord(TState.Element)     shl 16 + Ord(TToken.EndElement)   :
      if FElementStackTop = 0 then FState := TState.&End else FState := TState.ElementText;
    Ord(TState.Element)     shl 16 + Ord(TToken.StartElement) : FState := TState.Element;
    Ord(TState.Element)     shl 16 + Ord(TToken.StartAttr)    : FState := TState.Attr;
    Ord(TState.Element)     shl 16 + Ord(TToken.Text)         : FState := TState.ElementText;
    Ord(TState.ElementText) shl 16 + Ord(TToken.Text)         : FState := TState.ElementText;
    Ord(TState.ElementText) shl 16 + Ord(TToken.EndElement)   :
      if FElementStackTop = 0 then FState := TState.&End else FState := TState.ElementText;
    Ord(TState.ElementText) shl 16 + Ord(TToken.StartElement) : FState := TState.Element;
    Ord(TState.Attr)        shl 16 + Ord(TToken.Text)         : FState := TState.AttrText;
    Ord(TState.Attr)        shl 16 + Ord(TToken.EndAttr)      : FState := TState.Element;
    Ord(TState.AttrText)    shl 16 + Ord(TToken.Text)         : FState := TState.AttrText;
    Ord(TState.AttrText)    shl 16 + Ord(TToken.EndAttr)      : FState := TState.Element;
  else
    SaveState := FState;
    FState := TState.Error;
    raise Exception.CreateFmt('Invalid state (FState = %d, AToken = %d)', [Ord(SaveState), Ord(AToken)]);
  end;
end;

//# Write the xml declaration.  This must be the first call.
procedure TACLXMLRawWriter.WriteXmlDeclaration(AStandalone: TACLXMLStandalone);
begin
  if not (FOmitXmlDeclaration or FIsXmlDeclarationWritten) then
  begin
    FIsXmlDeclarationWritten := True;
    RawText('<?xml version="');
    RawText('1.0');
    if Encoding <> nil then
    begin
      RawText('" encoding="');
      RawText(TACLEncodings.WebName(Encoding));
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

//# Serialize the beginning of an element start tag: "<prefix:localName"
procedure TACLXMLRawWriter.WriteStartElement(const APrefix, ALocalName: string);
var
  AElementStackTop: Integer;
begin
  Assert(ALocalName <> '');

  if (FState = TState.Start) and not FOmitXmlDeclaration then
    WriteStartDocument;

  AdvanceState(TToken.StartElement);
  if (FElementStackTop >= 0) and FNewLineOnNode or (FElementStackTop < 0) and not FOmitXmlDeclaration then
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

  Inc(FElementStackTop);
  AElementStackTop := FElementStackTop;
  if Length(FElementStack) = AElementStackTop then
    SetLength(FElementStack, Length(FElementStack) * 2);
  FElementStack[AElementStackTop].Prefix := APrefix;
  FElementStack[AElementStackTop].LocalName := ALocalName;
end;

//# Serialize an attribute tag using double quotes around the attribute value: 'prefix:localName="'
procedure TACLXMLRawWriter.WriteStartAttribute(const APrefix, ALocalName: string);
begin
  Assert(ALocalName <> '');

  AdvanceState(TToken.StartAttr);

  if FNewLineOnAttributes then
    WriteNewLineAndAlignment;

  FBufChars[FBufPos] := ' ';
  Inc(FBufPos);

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
end;

//# Serialize the end of an attribute value using double quotes: '"'
procedure TACLXMLRawWriter.WriteEndAttribute;
begin
  AdvanceState(TToken.EndAttr);
  FBufChars[FBufPos] := '"';
  Inc(FBufPos);
end;

//# Serialize a CData section.  If the "]]>" pattern is found within the text, replace it with "]]><![CDATA[>".
procedure TACLXMLRawWriter.WriteCData(const AText: string);
var
  ASrcBegin, ADstBegin, ASrc, ASrcEnd, ADst, ADstEnd: PChar;
  C: Char;
  HadDoubleBracket: boolean;
begin
  Assert(AText <> '');
  AdvanceState(TToken.Text);

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
  HadDoubleBracket := False;

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
          if HadDoubleBracket and (ADst[-1] = ']') then
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
          HadDoubleBracket := ADst[-1] = ']';
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

  FBufChars[FBufPos] := ']';
  Inc(FBufPos);
  FBufChars[FBufPos] := ']';
  Inc(FBufPos);
  FBufChars[FBufPos] := '>';
  Inc(FBufPos);
end;

//# Serialize a comment.
procedure TACLXMLRawWriter.WriteComment(const AText: string);
begin
  Assert(AText <> '');

  AdvanceState(TToken.Text);

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

//# Serialize an entity reference.
procedure TACLXMLRawWriter.WriteEntityRef(const AName: string);
begin
  Assert(AName <> '');

  AdvanceState(TToken.Text);

  FBufChars[FBufPos] := '&';
  Inc(FBufPos);
  RawText(AName);
  FBufChars[FBufPos] := ';';
  Inc(FBufPos);

  if FBufPos > FBufLen then
    FlushBuffer;
end;

//# Serialize a character entity reference.
procedure TACLXMLRawWriter.WriteCharEntity(ACh: Char);
var
  AValue: string;
begin
  AdvanceState(TToken.Text);

  AValue := TACLHexCode.Encode(ACh);

  if FCheckCharacters and not TACLXMLCharType.IsCharData(ACh) then
    //# we just have a single char, not a surrogate, therefore we have to pass in '\0' for the second char
    raise EACLXMLArgumentException.CreateFmt(SXmlInvalidCharacter, [ACh, TACLHexCode.Encode(ACh)]);

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
end;

//# Serialize either attribute or element text using XML rules.
procedure TACLXMLRawWriter.WriteString(AStr: PChar; ALength: Integer);
var
  AEnd: PChar;
begin
  AdvanceState(TToken.Text);
  if ALength > 0 then
  begin
    AEnd := AStr + ALength;
    if FState = TState.AttrText then
      WriteAttributeTextBlock(AStr, AEnd)
    else
      WriteElementTextBlock(AStr, AEnd);
  end;
end;

//# Serialize surrogate character entity.
procedure TACLXMLRawWriter.WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char);
var
  ASurrogateChar: Integer;
begin
  AdvanceState(TToken.Text);

  ASurrogateChar := TACLXMLCharType.CombineSurrogateChar(ALowChar, AHighChar);

  FBufChars[FBufPos] := '&';
  Inc(FBufPos);
  FBufChars[FBufPos] := '#';
  Inc(FBufPos);
  FBufChars[FBufPos] := 'x';
  Inc(FBufPos);
  RawText(TACLHexCode.Encode(Char(ASurrogateChar)));
  FBufChars[FBufPos] := ';';
  Inc(FBufPos);
end;

//# Serialize raw data. Arguments are validated in the XmlWellformedWriter layer
procedure TACLXMLRawWriter.WriteRaw(const ABuffer: TCharArray; AIndex: Integer; ACount: Integer);
var
  AStart: PChar;
begin
  Assert(ABuffer <> nil);
  Assert(AIndex >= 0);
  Assert((ACount >= 0) and (AIndex + ACount <= Length(ABuffer)));

  AdvanceState(TToken.Text);
  AStart := @ABuffer[AIndex];
  WriteRawWithCharChecking(AStart, AStart + ACount);
end;

//# Serialize raw data.
procedure TACLXMLRawWriter.WriteRaw(const AData: string);
var
  AStart, AEnd: PChar;
begin
  Assert(AData <> '');

  AdvanceState(TToken.Text);
  AStart := PChar(AData);
  AEnd := AStart + Length(AData);
  WriteRawWithCharChecking(AStart, AEnd);
end;

//# Flush all bytes in the buffer to output and close the output stream or writer.
procedure TACLXMLRawWriter.Close;
begin
  if FState in [TState.Closed, TState.Error] then
    Exit;

  try
    FlushBuffer;
    FState := TState.Closed;
  except
    FState := TState.Error;
  end;
end;

//# Flush all characters in the buffer to output and call Flush() on the output object.
procedure TACLXMLRawWriter.Flush;
begin
  FlushBuffer;
end;

//# Flush all characters in the buffer to output.  Do not flush the output object.
procedure TACLXMLRawWriter.FlushBuffer;
begin
  if FState in [TState.Closed, TState.Error] then
    Exit;

  try
    //# Output all characters (except for previous characters stored at beginning of buffer)
    Write(FBufChars, 1, FBufPos - 1);
    //# Move last buffer character to the beginning of the buffer (so that previous character can always be determined)
    FBufChars[0] := FBufChars[FBufPos - 1];
    //# Reset buffer position
    FBufPos := 1;     //# Buffer position starts at 1, because we need to be able to safely step back -1 in case we need to
                      //# close an empty element or in CDATA section detection of double ]; _BUFFER[0] will always be 0
  except
    //# Future calls to flush (i.e. when Close() is called) don't attempt to write to stream
    FState := TState.Error;
    raise;
  end;
end;

//# Serialize text that is part of an attribute value.  The '&', '<', '>', and '"' characters are entitized.
procedure TACLXMLRawWriter.WriteAttributeTextBlock(ASrc: PChar; ASrcEnd: PChar);
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
procedure TACLXMLRawWriter.WriteElementTextBlock(ASrc: PChar; ASrcEnd: PChar);
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
      '"', #$0027, #$0009:
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

      #$000D:
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
    else
    begin
      if TACLXMLCharType.IsSurrogate(C) then
      try
        ADst := EncodeSurrogate(ASrc, ASrcEnd, ADst);
        Inc(ASrc, 2);
      except
        ADst := InvalidXmlChar(C, ADst, True);
        Inc(ASrc);
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
end;

procedure TACLXMLRawWriter.WriteNewLineAndAlignment(ANestingLevelCorrection: Integer = 0);
begin
  RawText(FNewLineChars);
  for var I := 1 to FNestingLevel + ANestingLevelCorrection do
    RawText(FIndentChars);
end;

procedure TACLXMLRawWriter.RawText(const S: string);
var
  AStart, AEnd: PChar;
begin
  Assert(S <> '');
  AStart := PChar(S);
  AEnd := AStart + Length(S);
  RawText(AStart, AEnd);
end;

procedure TACLXMLRawWriter.RawText(ASrcBegin: PChar; ASrcEnd: PChar);
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

procedure TACLXMLRawWriter.WriteRawWithCharChecking(APSrcBegin: PChar; APSrcEnd: PChar);
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

procedure TACLXMLRawWriter.WriteCommentOrPi(const AText: string; AStopChar: Char);
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

function TACLXMLRawWriter.EncodeSurrogate(ASrc: PChar; ASrcEnd: PChar; ADst: PChar): PChar;
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
  raise EACLXMLArgumentException.CreateFmt(SXmlInvalidHighSurrogateChar, [TACLHexCode.Encode(ACh)]);
end;

function TACLXMLRawWriter.InvalidXmlChar(ACh: Char; ADst: PChar; AEntitize: Boolean): PChar;
begin
  Assert(not TACLXMLCharType.IsWhiteSpace(ACh));
  Assert(not TACLXMLCharType.IsAttributeValueChar(ACh));

  if FCheckCharacters then
    raise EACLXMLArgumentException.CreateFmt(SXmlInvalidCharacter, [ACh, TACLHexCode.Encode(ACh)]);

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

//# Write NewLineChars to the specified buffer position and return an updated position.
function TACLXMLRawWriter.WriteNewLine(ADst: PChar): PChar;
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
class function TACLXMLRawWriter.LtEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := 'l';
  ADst[2] := 't';
  ADst[3] := ';';
  Result := ADst + 4;
end;

//# Entitize '>' as "&gt;".  Return an updated pointer.
class function TACLXMLRawWriter.GtEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := 'g';
  ADst[2] := 't';
  ADst[3] := ';';
  Result := ADst + 4;
end;

//# Entitize '&' as "&amp;".  Return an updated pointer.
class function TACLXMLRawWriter.AmpEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := 'a';
  ADst[2] := 'm';
  ADst[3] := 'p';
  ADst[4] := ';';
  Result := ADst + 5;
end;

//# Entitize '"' as "&quot;".  Return an updated pointer.
class function TACLXMLRawWriter.QuoteEntity(ADst: PChar): PChar;
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
class function TACLXMLRawWriter.TabEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := '#';
  ADst[2] := 'x';
  ADst[3] := '9';
  ADst[4] := ';';
  Result := ADst + 5;
end;

//# Entitize 0xa as "&#xA;".  Return an updated pointer.
class function TACLXMLRawWriter.LineFeedEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := '#';
  ADst[2] := 'x';
  ADst[3] := 'A';
  ADst[4] := ';';
  Result := ADst + 5;
end;

//# Entitize 0xd as "&#xD;".  Return an updated pointer.
class function TACLXMLRawWriter.CarriageReturnEntity(ADst: PChar): PChar;
begin
  ADst[0] := '&';
  ADst[1] := '#';
  ADst[2] := 'x';
  ADst[3] := 'D';
  ADst[4] := ';';
  Result := ADst + 5;
end;

class function TACLXMLRawWriter.CharEntity(ADst: PChar; ACh: Char): PChar;
begin
  //# VCL refactored
  ADst[0] := '&';
  ADst[1] := '#';
  ADst[2] := 'x';
  Inc(ADst, 3);
  ADst := TACLHexCode.Encode(ACh, ADst);
  ADst[0] := ';';
  Inc(ADst);
  Result := ADst;
end;

//# https://msdn.microsoft.com/en-us/library/system.xml.xmlconvert.decodename(v=vs.110).aspx
class function TACLXMLRawWriter.UCS2Entity(ADst: PChar; ACh: Char): PChar;
begin
  ADst[0] := '_';
  ADst[1] := 'x';
  Inc(ADst, 2);
  ADst := TACLHexCode.Encode(ACh, ADst);
  ADst[0] := '_';
  Inc(ADst);
  Result := ADst;
end;

//# Write "<![CDATA[" to the specified buffer.  Return an updated pointer.
class function TACLXMLRawWriter.RawStartCData(ADst: PChar): PChar;
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
class function TACLXMLRawWriter.RawEndCData(ADst: PChar): PChar;
begin
  ADst[0] := ']';
  ADst[1] := ']';
  ADst[2] := '>';
  Result := ADst + 3;
end;

procedure TACLXMLRawWriter.ValidateContentChars(const AChars: string; const APropertyName: string; AAllowOnlyWhitespace: Boolean);
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
    I := 1;
    while I <= Length(AChars) do
    begin
      if not TACLXMLCharType.IsTextChar(AChars[I]) then
      begin
        case AChars[I] of
          #13, #10, #9: {do nothing};
          '<', '&', ']':
            raise EACLXMLArgumentException.CreateFmt(SXmlInvalidCharsInIndent, [APropertyName,
              Format(SXmlInvalidCharacter, [AChars[I], TACLHexCode.Encode(AChars[I])])]);
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
                  Format(SXmlInvalidHighSurrogateChar, [TACLHexCode.Encode(AChars[I])])]);
          end;
        end;
      end;
      Inc(I);
    end;
  end;
end;

{ TACLXMLWellFormedWriter.TAttrName }

constructor TACLXMLWellFormedWriter.TAttrName.Create(const APrefix, ALocalName: string);
begin
  FPrefix := APrefix;
  FLocalName := ALocalName;
end;

{ TACLXMLWellFormedWriter }

constructor TACLXMLWellFormedWriter.Create(AWriter: TACLXMLWriter; const ASettings: TACLXMLWriterSettings);
begin
  Assert(AWriter <> nil);
  FWriter := AWriter;

  FCheckCharacters := ASettings.CheckCharacters;
  SetLength(FNsStack, NamespaceStackInitialSize);
  FNsStack[0].Prefix :='xmlns';
  FNsStack[0].Namespace := TACLXMLReservedNamespaces.XmlNs;
  FNsStack[1].Prefix := 'xml';
  FNsStack[1].Namespace := TACLXMLReservedNamespaces.Xml;
  FNsTop := 1;

  SetLength(FElemScopeStack, ElementStackInitialSize);
  FElemScopeStack[0].PrevNSTop := FNsTop;
  FElemTop := 0;

  SetLength(FAttrStack, AttributeArrayInitialSize);
end;

destructor TACLXMLWellFormedWriter.Destroy;
begin
  if WriteState <> TACLXMLWriteState.Closed then
    Close;
  FreeAndNil(FWriter);
  inherited Destroy;
end;

function TACLXMLWellFormedWriter.GetWriteState: TACLXMLWriteState;
begin
  if FIsError then
    Result := TACLXMLWriteState.Error
  else
    Result := FWriter.WriteState;
end;

procedure TACLXMLWellFormedWriter.WriteEndDocument;
begin
  FWriter.WriteEndDocument;
end;

procedure TACLXMLWellFormedWriter.WriteStartElement(const APrefix, ALocalName: string);
var
  ATop: Integer;
begin
  try
    if WriteState = TACLXMLWriteState.Element then
      StartElementContent;

    if ALocalName = '' then
      raise EACLXMLArgumentException.Create(SXmlEmptyLocalName);

    CheckNCName(ALocalName);
    if APrefix <> '' then
      CheckNCName(APrefix);

    FWriter.WriteStartElement(APrefix, ALocalName);

    Inc(FElemTop);
    ATop := FElemTop;
    if ATop = Length(FElemScopeStack) then
      SetLength(FElemScopeStack, ATop * 2);

    FElemScopeStack[ATop].PrevNSTop := FNsTop;
    FElemScopeStack[ATop].Prefix := APrefix;

    FAttrCount := 0;
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteEndElement;
var
  ATop: Integer;
begin
  try
    if FWriter.WriteState = TACLXMLWriteState.Element then
      StartElementContent;

    ATop := FElemTop;
    if ATop = 0 then
      raise EACLXMLArgumentException.Create(SXmlNoStartTag);
    FWriter.WriteEndElement;

    FNsTop := FElemScopeStack[ATop].PrevNSTop;
    Dec(ATop);
    FElemTop := ATop;
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteFullEndElement;
var
  ATop: Integer;
begin
  try
    if WriteState = TACLXMLWriteState.Element then
      StartElementContent;

    ATop := FElemTop;
    if ATop = 0 then
      raise EACLXMLException.Create(SXmlNoStartTag);

    FWriter.WriteFullEndElement;

    FNsTop := FElemScopeStack[ATop].PrevNSTop;
    Dec(ATop);
    FElemTop := ATop;
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteStartAttribute(const APrefix, ALocalName: string);
begin
  try
    CheckNCName(ALocalName);
    FIsNamespaceDeclaration := False;
    if APrefix <> '' then
    begin
      CheckNCName(APrefix);
      if APrefix = 'xmlns' then
      begin
        if (ALocalName = 'xml') or (ALocalName = 'xmlns') then
          raise EACLXMLArgumentException.CreateFmt(SXmlInvalidLocalName, [ALocalName]);
        FIsNamespaceDeclaration := True;
        FCurrentDeclarationNamespacePrefix := ALocalName;
        FCurrentDeclarationNamespace := '';
      end;
    end
    else
    begin
      if ALocalName = 'xml' then
      begin
        FIsNamespaceDeclaration := True;
        FCurrentDeclarationNamespacePrefix := ''; // default namespace
        FCurrentDeclarationNamespace := '';
      end;
    end;

    FWriter.WriteStartAttribute(APrefix, ALocalName);
    AddAttribute(APrefix, ALocalName);
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteEndAttribute;
begin
  try
    if FIsNamespaceDeclaration then
    begin
      PushNamespace(FCurrentDeclarationNamespacePrefix, FCurrentDeclarationNamespace);
      FIsNamespaceDeclaration := False;
    end;
    FWriter.WriteEndAttribute;
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteCData(const AText: string);
begin
  try
    if WriteState = TACLXMLWriteState.Element then
      StartElementContent;
    FWriter.WriteCData(AText);
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteComment(const AText: string);
begin
  try
    if WriteState = TACLXMLWriteState.Element then
      StartElementContent;
    FWriter.WriteComment(AText);
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteEntityRef(const AName: string);
begin
  try
    if AName = '' then
      raise EACLXMLArgumentException.Create(SXmlEmptyName);

    CheckNCName(AName);

    if (FWriter.WriteState = TACLXMLWriteState.Attribute) and FIsNamespaceDeclaration then
      raise EACLXMLArgumentException.CreateFmt(SXmlUnexpectedToken, ['Namespace', 'EntityRef']);
    if WriteState = TACLXMLWriteState.Element then
      StartElementContent;
    FWriter.WriteEntityRef(AName);
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteCharEntity(ACh: Char);
begin
  try
    if ACh.IsSurrogate then
      raise EACLXMLArgumentException.Create(SXmlInvalidSurrogateMissingLowChar);
    if (FWriter.WriteState = TACLXMLWriteState.Attribute) and FIsNamespaceDeclaration then
      raise EACLXMLArgumentException.CreateFmt(SXmlUnexpectedToken, ['Namespace', 'CharEntity']);
    if WriteState = TACLXMLWriteState.Element then
      StartElementContent;
    FWriter.WriteCharEntity(ACh);
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteSurrogateCharEntity(ALowChar: Char; AHighChar: Char);
begin
  try
    if not Char.IsSurrogatePair(AHighChar, ALowChar) then
      raise EACLXMLInvalidSurrogatePairException.Create(ALowChar, AHighChar);
    if (FWriter.WriteState = TACLXMLWriteState.Attribute) and FIsNamespaceDeclaration then
      raise EACLXMLArgumentException.CreateFmt(SXmlUnexpectedToken, ['Namespace', 'CharEntity']);
    FWriter.WriteSurrogateCharEntity(ALowChar, AHighChar);
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteString(AStr: PChar; ALength: Integer);
begin
  try
    if FIsNamespaceDeclaration and (ALength > 0) then
    begin
      var L := Length(FCurrentDeclarationNamespace);
      SetLength(FCurrentDeclarationNamespace, L + ALength);
      Move(AStr^, FCurrentDeclarationNamespace[L + 1], ALength * SizeOf(Char));
    end;

    FWriter.WriteString(AStr, ALength);
  except
    FIsError := True;
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
    if FIsNamespaceDeclaration then
      raise EACLXMLArgumentException.CreateFmt(SXmlUnexpectedToken, ['Namespace', 'Raw']);
    if WriteState = TACLXMLWriteState.Element then
      StartElementContent;
    FWriter.WriteRaw(ABuffer, AIndex, ACount);
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteRaw(const AData: string);
begin
  try
    if FIsNamespaceDeclaration then
      raise EACLXMLArgumentException.CreateFmt(SXmlUnexpectedToken, ['Namespace', 'Raw']);
    if WriteState = TACLXMLWriteState.Element then
      StartElementContent;
    FWriter.WriteRaw(AData);
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.Close;
begin
  if not (WriteState in [TACLXMLWriteState.Closed, TACLXMLWriteState.Error]) then
  try
    FWriter.Close;
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.Flush;
begin
  try
    FWriter.Flush;
  except
    FIsError := True;
    raise;
  end;
end;

procedure TACLXMLWellFormedWriter.WriteStartDocument(AStandalone: TACLXMLStandalone);
begin
  try
    FWriter.WriteStartDocument(AStandalone)
  except
    FIsError := True;
    raise;
  end;
end;

//# PushNamespaceExplicit is called when a namespace declaration is written out;
procedure TACLXMLWellFormedWriter.PushNamespace(const APrefix, ANamespace: string);
var
  ATop: Integer;
begin
  ATop := FNsTop;
  Inc(ATop);
  if ATop = Length(FNsStack) then
    SetLength(FNsStack, Length(FNsStack) + 1);
  FNsStack[ATop].Prefix := APrefix;
  FNsStack[ATop].Namespace := ANamespace;
  FNsTop := ATop;
end;

class function TACLXMLWellFormedWriter.DupAttrException(const APrefix, ALocalName: string): EACLXMLException;
var
  ASb: TACLStringBuilder;
begin
  ASb := TACLStringBuilder.Get;
  try
    if APrefix <> '' then
      ASb.Append(APrefix).Append(':');
    ASb.Append(ALocalName);
    Result := EACLXMLException.CreateFmt(SXmlDupAttributeName, [ASb.ToString]);
  finally
    ASb.Release;
  end;
end;

procedure TACLXMLWellFormedWriter.StartElementContent;

  function GetNamespace(const APrefix: string): string;
  begin
    for var I := FNsTop downto 0 do
    begin
      if FNsStack[I].Prefix = APrefix then
        Exit(FNsStack[I].Namespace);
    end;
    raise EACLXMLException.CreateFmt('Unable to find namespace for the "%s" prefix', [APrefix]);
  end;

var
  AAttrNamespaces: TArray<string>;
  AHasAttrWithNamespace: Boolean;
  ALocalName: string;
  ANamespace: string;
  APrefix: string;
begin
  AHasAttrWithNamespace := False;
  SetLength(AAttrNamespaces, FAttrCount);
  for var AttrIndex := 0 to FAttrCount - 1 do
  begin
    APrefix := FAttrStack[AttrIndex].Prefix;
    if APrefix <> '' then
    begin
      AAttrNamespaces[AttrIndex] := GetNamespace(APrefix);
      AHasAttrWithNamespace := True;
    end;
  end;

  if AHasAttrWithNamespace then
    for var AttrIndex := 1 to FAttrCount - 1 do
    begin
      ANamespace := AAttrNamespaces[AttrIndex];
      if ANamespace = '' then
        Continue;

      ALocalName := FAttrStack[AttrIndex].LocalName;
      for var AttrIndex2 := 0 to AttrIndex - 1 do
      begin
        if (FAttrStack[AttrIndex2].LocalName = ALocalName) and (AAttrNamespaces[AttrIndex2] = ANamespace) then
          raise DupAttrException(FAttrStack[AttrIndex].Prefix, FAttrStack[AttrIndex].LocalName);
      end;
    end;


  APrefix := FElemScopeStack[FElemTop].Prefix;
  if APrefix <> '' then
    GetNamespace(APrefix); // check if we have namespace for the element

  FAttrCount := 0;
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
    if (TACLXMLCharType.CharProperties[P^] and TACLXMLCharType.NCNameSC) = 0 then
      raise InvalidCharsException(ANcname, P - AStart);
    Dec(ALen);
    Inc(P);
  end;
end;

class function TACLXMLWellFormedWriter.InvalidCharsException(const AName: string; ABadCharIndex: Integer): EACLXMLException;
begin
  Result := EACLXMLException.CreateFmt(SXmlInvalidNameCharsDetail,
    [AName, ABadCharIndex, TACLHexCode.Encode(AName[ABadCharIndex + 1])]);
end;

procedure TACLXMLWellFormedWriter.AddAttribute(const APrefix, ALocalName: string);
var
  ATop: Integer;
begin
  for var I := 0 to FAttrCount - 1 do
  begin
    if (FAttrStack[I].LocalName = ALocalName) and (FAttrStack[I].Prefix = APrefix) then
      raise DupAttrException(APrefix, ALocalName);
  end;

  ATop := FAttrCount;
  Inc(FAttrCount);
  if ATop = Length(FAttrStack) then
    SetLength(FAttrStack, ATop * 2);
  FAttrStack[ATop] := TAttrName.Create(APrefix, ALocalName);
end;

end.
