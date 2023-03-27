{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*    General Types for XML Reader/Writer    *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.FileFormats.XML.Types;

{$I ACL.Config.inc}
{$SCOPEDENUMS ON}

// Ported from .NET platform:
// https://github.com/microsoft/referencesource/tree/master/System.Xml/System/Xml/Core

interface

uses
  // System
  System.Character,
  System.Math,
  System.Generics.Defaults,
  System.Generics.Collections,
  System.SysUtils,
  System.Types,
  // ACL
  ACL.Classes.Collections,
  ACL.Parsers,
  ACL.Utils.Common,
  ACL.Utils.Strings;

const
  sXMLBoolValues: array[Boolean] of string = ('false', 'true');

type
  TACLXMLSpace = (
    None,      //# xml:space scope has not been specified.
    Default,   //# The xml:space scope is "default".
    Preserve   //# The xml:space scope is "preserve".
  );

  { EACLXMLException }

  EACLXMLException = class(Exception)
  strict private
    FLineNumber: Integer;
    FLinePosition: Integer;
    FRes: string;
    FSourceUri: string;

    class function CreateMessage(const ARes: string;
      const AArgs: array of const; ALineNumber, ALinePosition: Integer): string; static;
    class function FormatUserMessage(const AMessage: string;
      ALineNumber: Integer; ALinePosition: Integer): string; static;
  public
    constructor Create(const ARes, AArg: string); overload;
    constructor Create(const ARes, AArg, ASourceUri: string); overload;
    constructor Create(const AMessage: string; AInnerException: Exception;
      ALineNumber: Integer; ALinePosition: Integer; const ASourceUri: string); overload;
    constructor Create(const ARes: string; const AArg: string;
      ALineNumber: Integer; ALinePosition: Integer); overload;
    constructor Create(const ARes: string; const AArgs: array of const;
      ALineNumber: Integer; ALinePosition: Integer; const ASourceUri: string = ''); overload;
    constructor Create(const ARes: string; const AArg: string;
      ALineNumber: Integer; ALinePosition: Integer; const ASourceUri: string); overload;
    constructor Create(const ARes: string; const AArgs: array of const; AInnerException: Exception;
      ALineNumber, ALinePosition: Integer; const ASourceUri: string); overload;

    class function BuildCharExceptionArgs(
      AInvChar: Char; ANextChar: Char): TArray<string>; overload; static;
    class function BuildCharExceptionArgs(const AData: TCharArray;
      ALength: Integer; AInvCharIndex: Integer): TArray<string>; overload; static;

    property LineNumber: Integer read FLineNumber;
    property LinePosition: Integer read FLinePosition;
  end;

  { EACLXMLArgumentOutOfRangeException }

  EACLXMLArgumentOutOfRangeException = class(EACLXMLException);

  { EACLXMLArgumentNullException }

  EACLXMLArgumentNullException = class(EACLXMLException);

  { EACLXMLArgumentException }

  EACLXMLArgumentException = class(EACLXMLException);

  { EACLXMLInvalidOperationException }

  EACLXMLInvalidOperationException = class(EACLXMLException);

  { TACLXMLReservedNamespaces }

  TACLXMLReservedNamespaces = class
  public const
    Xml = 'http://www.w3.org/XML/1998/namespace';
    XmlNs = 'http://www.w3.org/2000/xmlns/';
    DataType = 'urn:schemas-microsoft-com:datatypes';
    DataTypeAlias = 'uuid:C2F41010-65B3-11D1-A29F-00AA00C14882';
    DataTypeOld = 'urn:uuid:C2F41010-65B3-11D1-A29F-00AA00C14882/';
    Msxsl = 'urn:schemas-microsoft-com:xslt';
    Xdr = 'urn:schemas-microsoft-com:xml-data';
    XslDebug = 'urn:schemas-microsoft-com:xslt-debug';
    XdrAlias = 'uuid:BDC6E3F0-6DA3-11D1-A2A3-00AA00C14882';
    WdXsl = 'http://www.w3.org/TR/WD-xsl';
    Xs = 'http://www.w3.org/2001/XMLSchema';
    Xsd = 'http://www.w3.org/2001/XMLSchema-datatypes';
    Xsi = 'http://www.w3.org/2001/XMLSchema-instance';
    Xslt = 'http://www.w3.org/1999/XSL/Transform';
    ExsltCommon = 'http://exslt.org/common';
    ExsltDates = 'http://exslt.org/dates-and-times';
    ExsltMath = 'http://exslt.org/math';
    ExsltRegExps = 'http://exslt.org/regular-expressions';
    ExsltSets = 'http://exslt.org/sets';
    ExsltStrings = 'http://exslt.org/strings';
    XQueryFunc = 'http://www.w3.org/2003/11/xpath-functions';
    XQueryDataType = 'http://www.w3.org/2003/11/xpath-datatypes';
    CollationBase = 'http://collations.microsoft.com';
    CollCodePoint = 'http://www.w3.org/2004/10/xpath-functions/collation/codepoint';
    XsltInternal = 'http://schemas.microsoft.com/framework/2003/xml/xslt/internal';
  end;

  { TACLXMLCharType }

  TACLXMLCharType = class
  public type
    TCharProperties = array[Char] of Byte;
  public const
    //# Characters defined in the XML 1.0 Fourth Edition
    //# PubidChar ::=  0x20 | 0xD | 0xA | [a-zA-Z0-9] | [-'()+,./:=?;!*#@$_%] Section 2.3 of spec
    Whitespace    = 1;   //# Whitespace chars -- Section 2.3 [3]
    Letter        = 2;   //# Letters -- Appendix B [84]
    NCStartNameSC = 4;   //# Starting NCName characters -- Section 2.3 [5] (Starting Name characters without ':')
    NCNameSC      = 8;   //# NCName characters -- Section 2.3 [4]          (Name characters without ':')
    CharData      = 16;  //# Character data characters -- Section 2.2 [2]
    NCNameXml4e   = 32;
    Text          = 64;
    AttrValue     = 128;
    //# Surrogate constants
    SurHighStart  = #$d800;    //# 1101 10xx
    SurHighEnd    = #$dbff;
    SurLowStart   = #$dc00;    //# 1101 11xx
    SurLowEnd     = #$dfff;
    SurMask       = #$fc00;    //# 1111 11xx
  strict private const
    //# bitmap for public ID characters - 1 bit per character 0x0 - 0x80; no character > 0x80 is a PUBLIC ID char
    PublicIdBitmap: array[0..7] of Word = ($2400, $0000, $FFBB, $AFFF, $FFFF, $87FF, $FFFE, $07FF);
  strict private
    class var FCharProperties: TCharProperties;
    class constructor Initialize;
    class procedure InitRanges(const ARanges: string; Attribute: Byte); static;
  public
    class function CombineSurrogateChar(ALowChar, AHighChar: Char): Integer; static; inline;
    class function IsAttributeValueChar(C: Char): Boolean; static; inline;
    class function IsCharData(C: Char): Boolean; static; inline;
    class function IsHighSurrogate(C: Char): Boolean; static; inline;
    class function IsLowSurrogate(C: Char): Boolean; static; inline;
    class function IsNameSingleChar(ACh: Char): Boolean; static; inline;
    class function IsNCNameSingleChar(ACh: Char): Boolean; static; inline;
    class function IsOnlyCharData(const S: string): Integer; static; inline;
    class function IsOnlyWhitespace(const S: string): Boolean; static; inline;
    class function IsPubidChar(C: Char): Boolean; static; inline;
    class function IsPublicId(const S: string): Integer; static; inline;
    class function IsSurrogate(C: Char): Boolean; static; inline;
    class function IsTextChar(C: Char): Boolean; static; inline;
    class function IsWhiteSpace(C: Char): Boolean; static; inline;
    class procedure SplitSurrogateChar(ACombinedChar: Integer;
      out ALowChar: Char; out AHighChar: Char); static; inline;

    class property CharProperties: TCharProperties read FCharProperties;
  end;

  TACLXMLConformanceLevel = (
    Auto,     //# With conformance level Auto an XmlReader or XmlWriter
              //# automatically determines whether in incoming XML is an XML fragment or document.
    Fragment, //# Conformance level for XML fragment. An XML fragment can contain any node type that can be a child of an element,
              //# plus it can have a single XML declaration as its first node
    Document  //# Conformance level for XML document as specified in XML 1.0 Specification
  );

  { TACLXMLConvert }

  //# https://msdn.microsoft.com/en-us/library/system.xml.xmlconvert.decodename(v=vs.110).aspx
  TACLXMLConvert = class
  strict private
    class var FMap: TACLStringsMap;

    class function IsEncodedCharacter(const S: string; APosition, ALength: Integer; out ACode: Integer): Boolean; static;
  public
    class constructor Create;
    class destructor Destroy;
    class function DecodeBoolean(const S: string): Boolean; static;
    class function DecodeName(const S: string): string; static;
    class function EncodeName(const S: string): string; static;
    class function EncodeString(const S: string; ARemoveBreakLines, ASkipServiceCharacters: Boolean): string; static;
    class function IsHTMLCode(var P: PWideChar; var L: Integer): Boolean; static;
    class function IsInvalidXmlChar(const C: Word): Boolean; inline;
  end;

implementation

const
  SXMLMessageWithErrorPosition = '%s Line %d, position %d';
  SXMLDefaultException = 'An XML error has occurred.';
  SXMLUserException = '%s';

function IfThen(AValue: Boolean; const ATrue: Char; const AFalse: Char): Char; overload; inline;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

{ EACLXMLException }

constructor EACLXMLException.Create(const AMessage: string;
  AInnerException: Exception; ALineNumber, ALinePosition: Integer; const ASourceUri: string);
begin
  inherited Create(FormatUserMessage(AMessage, ALineNumber, ALinePosition));
  FSourceUri := ASourceUri;
  FLineNumber := ALineNumber;
  FLinePosition := ALinePosition;
end;

constructor EACLXMLException.Create(const ARes, AArg: string; ALineNumber, ALinePosition: Integer);
begin
  Create(ARes, [AArg], nil, ALineNumber, ALinePosition, '');
end;

constructor EACLXMLException.Create(const ARes: string; const AArgs: array of const;
  ALineNumber, ALinePosition: Integer; const ASourceUri: string);
begin
  Create(ARes, AArgs, nil, ALineNumber, ALinePosition, ASourceUri);
end;

class function EACLXMLException.CreateMessage(const ARes: string;
  const AArgs: array of const; ALineNumber, ALinePosition: Integer): string;
begin
  try
    if ALineNumber = 0 then
      Result := Format(ARes, AArgs)
    else
      Result := Format(SXMLMessageWithErrorPosition, [Format(ARes, AArgs), ALineNumber, ALinePosition]);
  except
    Result := '';
  end;
end;

class function EACLXMLException.FormatUserMessage(const AMessage: string; ALineNumber, ALinePosition: Integer): string;
begin
  if AMessage = '' then
    Result := CreateMessage(SXMLDefaultException, [], ALineNumber, ALinePosition)
  else
    if (ALineNumber = 0) and (ALinePosition = 0) then
      Result := AMessage
    else
      Result := CreateMessage(SXMLUserException, [AMessage], ALineNumber, ALinePosition);
end;

constructor EACLXMLException.Create(const ARes: string; const AArgs: array of const;
  AInnerException: Exception; ALineNumber, ALinePosition: Integer; const ASourceUri: string);
begin
  inherited Create(CreateMessage(ARes, AArgs, ALineNumber, ALinePosition));
  FRes := ARes;
  FSourceUri := ASourceUri;
  FLineNumber := ALineNumber;
  FLinePosition := ALinePosition;
end;

class function EACLXMLException.BuildCharExceptionArgs(AInvChar, ANextChar: Char): TArray<string>;
var
  AAStringList: TArray<string>;
  ACombinedChar: Integer;
begin
  SetLength(AAStringList, 2);
  //# for surrogate characters include both high and low char in the message so that a full character is displayed
  if TACLXMLCharType.IsHighSurrogate(AInvChar) and (ANextChar <> #0) then
  begin
    ACombinedChar := TACLXMLCharType.CombineSurrogateChar(ANextChar, AInvChar);
    AAStringList[0] := AInvChar + ANextChar;
    AAStringList[1] := Format('0x%2x', [Ord(ACombinedChar)]);
  end
  else
  begin
    //# don't include 0 character in the string - in means eof-of-string in native code, where this may bubble up to
    if Integer(AInvChar) = 0 then
      AAStringList[0] := '.'
    else
      AAStringList[0] := AInvChar;
    AAStringList[1] := Format('0x%2x', [Ord(AInvChar)]);
  end;
  Result := AAStringList;
end;

class function EACLXMLException.BuildCharExceptionArgs(const AData: TCharArray; ALength, AInvCharIndex: Integer): TArray<string>;
begin
  Assert(AInvCharIndex < Length(AData));
  Assert(AInvCharIndex < ALength);
  Assert(ALength <= Length(AData));

  Result := BuildCharExceptionArgs(AData[AInvCharIndex], IfThen(AInvCharIndex + 1 < ALength, AData[AInvCharIndex + 1], #0));
end;

constructor EACLXMLException.Create(const ARes, AArg: string; ALineNumber, ALinePosition: Integer; const ASourceUri: string);
begin
  Create(ARes, [AArg], nil, ALineNumber, ALinePosition, ASourceUri);
end;

constructor EACLXMLException.Create(const ARes, AArg, ASourceUri: string);
begin
  Create(ARes, [AArg], nil, 0, 0, ASourceUri);
end;

constructor EACLXMLException.Create(const ARes, AArg: string);
begin
  Create(ARes, [AArg], nil, 0, 0, '');
end;

{ TACLXMLCharType }

class constructor TACLXMLCharType.Initialize;
const
  WhitespaceRanges = #$0009#$000A#$000D#$000D#$0020#$0020;
  NCStartNameRanges =
    #$0041#$005A#$005F#$005F#$0061#$007A#$00C0#$00D6#$00D8#$00F6#$00F8#$0131#$0134#$013E +
    #$0141#$0148#$014A#$017E#$0180#$01C3#$01CD#$01F0#$01F4#$01F5#$01FA#$0217#$0250#$02A8#$02BB#$02C1 +
    #$0386#$0386#$0388#$038A#$038C#$038C#$038E#$03A1#$03A3#$03CE#$03D0#$03D6#$03DA#$03DA#$03DC#$03DC +
    #$03DE#$03DE#$03E0#$03E0#$03E2#$03F3#$0401#$040C#$040E#$044F#$0451#$045C#$045E#$0481#$0490#$04C4 +
    #$04C7#$04C8#$04CB#$04CC#$04D0#$04EB#$04EE#$04F5#$04F8#$04F9#$0531#$0556#$0559#$0559#$0561#$0586 +
    #$05D0#$05EA#$05F0#$05F2#$0621#$063A#$0641#$064A#$0671#$06B7#$06BA#$06BE#$06C0#$06CE#$06D0#$06D3 +
    #$06D5#$06D5#$06E5#$06E6#$0905#$0939#$093D#$093D#$0958#$0961#$0985#$098C#$098F#$0990#$0993#$09A8 +
    #$09AA#$09B0#$09B2#$09B2#$09B6#$09B9#$09DC#$09DD#$09DF#$09E1#$09F0#$09F1#$0A05#$0A0A#$0A0F#$0A10 +
    #$0A13#$0A28#$0A2A#$0A30#$0A32#$0A33#$0A35#$0A36#$0A38#$0A39#$0A59#$0A5C#$0A5E#$0A5E#$0A72#$0A74 +
    #$0A85#$0A8B#$0A8D#$0A8D#$0A8F#$0A91#$0A93#$0AA8#$0AAA#$0AB0#$0AB2#$0AB3#$0AB5#$0AB9#$0ABD#$0ABD +
    #$0AE0#$0AE0#$0B05#$0B0C#$0B0F#$0B10#$0B13#$0B28#$0B2A#$0B30#$0B32#$0B33#$0B36#$0B39#$0B3D#$0B3D +
    #$0B5C#$0B5D#$0B5F#$0B61#$0B85#$0B8A#$0B8E#$0B90#$0B92#$0B95#$0B99#$0B9A#$0B9C#$0B9C#$0B9E#$0B9F +
    #$0BA3#$0BA4#$0BA8#$0BAA#$0BAE#$0BB5#$0BB7#$0BB9#$0C05#$0C0C#$0C0E#$0C10#$0C12#$0C28#$0C2A#$0C33 +
    #$0C35#$0C39#$0C60#$0C61#$0C85#$0C8C#$0C8E#$0C90#$0C92#$0CA8#$0CAA#$0CB3#$0CB5#$0CB9#$0CDE#$0CDE +
    #$0CE0#$0CE1#$0D05#$0D0C#$0D0E#$0D10#$0D12#$0D28#$0D2A#$0D39#$0D60#$0D61#$0E01#$0E2E#$0E30#$0E30 +
    #$0E32#$0E33#$0E40#$0E45#$0E81#$0E82#$0E84#$0E84#$0E87#$0E88#$0E8A#$0E8A#$0E8D#$0E8D#$0E94#$0E97 +
    #$0E99#$0E9F#$0EA1#$0EA3#$0EA5#$0EA5#$0EA7#$0EA7#$0EAA#$0EAB#$0EAD#$0EAE#$0EB0#$0EB0#$0EB2#$0EB3 +
    #$0EBD#$0EBD#$0EC0#$0EC4#$0F40#$0F47#$0F49#$0F69#$10A0#$10C5#$10D0#$10F6#$1100#$1100#$1102#$1103 +
    #$1105#$1107#$1109#$1109#$110B#$110C#$110E#$1112#$113C#$113C#$113E#$113E#$1140#$1140#$114C#$114C +
    #$114E#$114E#$1150#$1150#$1154#$1155#$1159#$1159#$115F#$1161#$1163#$1163#$1165#$1165#$1167#$1167 +
    #$1169#$1169#$116D#$116E#$1172#$1173#$1175#$1175#$119E#$119E#$11A8#$11A8#$11AB#$11AB#$11AE#$11AF +
    #$11B7#$11B8#$11BA#$11BA#$11BC#$11C2#$11EB#$11EB#$11F0#$11F0#$11F9#$11F9#$1E00#$1E9B#$1EA0#$1EF9 +
    #$1F00#$1F15#$1F18#$1F1D#$1F20#$1F45#$1F48#$1F4D#$1F50#$1F57#$1F59#$1F59#$1F5B#$1F5B#$1F5D#$1F5D +
    #$1F5F#$1F7D#$1F80#$1FB4#$1FB6#$1FBC#$1FBE#$1FBE#$1FC2#$1FC4#$1FC6#$1FCC#$1FD0#$1FD3#$1FD6#$1FDB +
    #$1FE0#$1FEC#$1FF2#$1FF4#$1FF6#$1FFC#$2126#$2126#$212A#$212B#$212E#$212E#$2180#$2182#$3007#$3007 +
    #$3021#$3029#$3041#$3094#$30A1#$30FA#$3105#$312C#$4E00#$9FA5#$AC00#$D7A3;

  NCNameRanges =
    #$002D#$002E#$0030#$0039#$0041#$005A#$005F#$005F#$0061#$007A#$00B7#$00B7#$00C0#$00D6#$00D8#$00F6 +
    #$00F8#$0131#$0134#$013E#$0141#$0148#$014A#$017E#$0180#$01C3#$01CD#$01F0#$01F4#$01F5#$01FA#$0217 +
    #$0250#$02A8#$02BB#$02C1#$02D0#$02D1#$0300#$0345#$0360#$0361#$0386#$038A#$038C#$038C#$038E#$03A1 +
    #$03A3#$03CE#$03D0#$03D6#$03DA#$03DA#$03DC#$03DC#$03DE#$03DE#$03E0#$03E0#$03E2#$03F3#$0401#$040C +
    #$040E#$044F#$0451#$045C#$045E#$0481#$0483#$0486#$0490#$04C4#$04C7#$04C8#$04CB#$04CC#$04D0#$04EB +
    #$04EE#$04F5#$04F8#$04F9#$0531#$0556#$0559#$0559#$0561#$0586#$0591#$05A1#$05A3#$05B9#$05BB#$05BD +
    #$05BF#$05BF#$05C1#$05C2#$05C4#$05C4#$05D0#$05EA#$05F0#$05F2#$0621#$063A#$0640#$0652#$0660#$0669 +
    #$0670#$06B7#$06BA#$06BE#$06C0#$06CE#$06D0#$06D3#$06D5#$06E8#$06EA#$06ED#$06F0#$06F9#$0901#$0903 +
    #$0905#$0939#$093C#$094D#$0951#$0954#$0958#$0963#$0966#$096F#$0981#$0983#$0985#$098C#$098F#$0990 +
    #$0993#$09A8#$09AA#$09B0#$09B2#$09B2#$09B6#$09B9#$09BC#$09BC#$09BE#$09C4#$09C7#$09C8#$09CB#$09CD +
    #$09D7#$09D7#$09DC#$09DD#$09DF#$09E3#$09E6#$09F1#$0A02#$0A02#$0A05#$0A0A#$0A0F#$0A10#$0A13#$0A28 +
    #$0A2A#$0A30#$0A32#$0A33#$0A35#$0A36#$0A38#$0A39#$0A3C#$0A3C#$0A3E#$0A42#$0A47#$0A48#$0A4B#$0A4D +
    #$0A59#$0A5C#$0A5E#$0A5E#$0A66#$0A74#$0A81#$0A83#$0A85#$0A8B#$0A8D#$0A8D#$0A8F#$0A91#$0A93#$0AA8 +
    #$0AAA#$0AB0#$0AB2#$0AB3#$0AB5#$0AB9#$0ABC#$0AC5#$0AC7#$0AC9#$0ACB#$0ACD#$0AE0#$0AE0#$0AE6#$0AEF +
    #$0B01#$0B03#$0B05#$0B0C#$0B0F#$0B10#$0B13#$0B28#$0B2A#$0B30#$0B32#$0B33#$0B36#$0B39#$0B3C#$0B43 +
    #$0B47#$0B48#$0B4B#$0B4D#$0B56#$0B57#$0B5C#$0B5D#$0B5F#$0B61#$0B66#$0B6F#$0B82#$0B83#$0B85#$0B8A +
    #$0B8E#$0B90#$0B92#$0B95#$0B99#$0B9A#$0B9C#$0B9C#$0B9E#$0B9F#$0BA3#$0BA4#$0BA8#$0BAA#$0BAE#$0BB5 +
    #$0BB7#$0BB9#$0BBE#$0BC2#$0BC6#$0BC8#$0BCA#$0BCD#$0BD7#$0BD7#$0BE7#$0BEF#$0C01#$0C03#$0C05#$0C0C +
    #$0C0E#$0C10#$0C12#$0C28#$0C2A#$0C33#$0C35#$0C39#$0C3E#$0C44#$0C46#$0C48#$0C4A#$0C4D#$0C55#$0C56 +
    #$0C60#$0C61#$0C66#$0C6F#$0C82#$0C83#$0C85#$0C8C#$0C8E#$0C90#$0C92#$0CA8#$0CAA#$0CB3#$0CB5#$0CB9 +
    #$0CBE#$0CC4#$0CC6#$0CC8#$0CCA#$0CCD#$0CD5#$0CD6#$0CDE#$0CDE#$0CE0#$0CE1#$0CE6#$0CEF#$0D02#$0D03 +
    #$0D05#$0D0C#$0D0E#$0D10#$0D12#$0D28#$0D2A#$0D39#$0D3E#$0D43#$0D46#$0D48#$0D4A#$0D4D#$0D57#$0D57 +
    #$0D60#$0D61#$0D66#$0D6F#$0E01#$0E2E#$0E30#$0E3A#$0E40#$0E4E#$0E50#$0E59#$0E81#$0E82#$0E84#$0E84 +
    #$0E87#$0E88#$0E8A#$0E8A#$0E8D#$0E8D#$0E94#$0E97#$0E99#$0E9F#$0EA1#$0EA3#$0EA5#$0EA5#$0EA7#$0EA7 +
    #$0EAA#$0EAB#$0EAD#$0EAE#$0EB0#$0EB9#$0EBB#$0EBD#$0EC0#$0EC4#$0EC6#$0EC6#$0EC8#$0ECD#$0ED0#$0ED9 +
    #$0F18#$0F19#$0F20#$0F29#$0F35#$0F35#$0F37#$0F37#$0F39#$0F39#$0F3E#$0F47#$0F49#$0F69#$0F71#$0F84 +
    #$0F86#$0F8B#$0F90#$0F95#$0F97#$0F97#$0F99#$0FAD#$0FB1#$0FB7#$0FB9#$0FB9#$10A0#$10C5#$10D0#$10F6 +
    #$1100#$1100#$1102#$1103#$1105#$1107#$1109#$1109#$110B#$110C#$110E#$1112#$113C#$113C#$113E#$113E +
    #$1140#$1140#$114C#$114C#$114E#$114E#$1150#$1150#$1154#$1155#$1159#$1159#$115F#$1161#$1163#$1163 +
    #$1165#$1165#$1167#$1167#$1169#$1169#$116D#$116E#$1172#$1173#$1175#$1175#$119E#$119E#$11A8#$11A8 +
    #$11AB#$11AB#$11AE#$11AF#$11B7#$11B8#$11BA#$11BA#$11BC#$11C2#$11EB#$11EB#$11F0#$11F0#$11F9#$11F9 +
    #$1E00#$1E9B#$1EA0#$1EF9#$1F00#$1F15#$1F18#$1F1D#$1F20#$1F45#$1F48#$1F4D#$1F50#$1F57#$1F59#$1F59 +
    #$1F5B#$1F5B#$1F5D#$1F5D#$1F5F#$1F7D#$1F80#$1FB4#$1FB6#$1FBC#$1FBE#$1FBE#$1FC2#$1FC4#$1FC6#$1FCC +
    #$1FD0#$1FD3#$1FD6#$1FDB#$1FE0#$1FEC#$1FF2#$1FF4#$1FF6#$1FFC#$20D0#$20DC#$20E1#$20E1#$2126#$2126 +
    #$212A#$212B#$212E#$212E#$2180#$2182#$3005#$3005#$3007#$3007#$3021#$302F#$3031#$3035#$3041#$3094 +
    #$3099#$309A#$309D#$309E#$30A1#$30FA#$30FC#$30FE#$3105#$312C#$4E00#$9FA5#$AC00#$D7A3;
  CharDataRanges = #$0009#$000A#$000D#$000D#$0020#$D7FF#$E000#$FFFD;

  PublicIDRanges =
    #$000A#$000A#$000D#$000D#$0020#$0021#$0023#$0025#$0027#$003B#$003D#$003D#$003F#$005A#$005F#$005F +
    #$0061#$007A;

  TextRanges = //# TextChar = CharData - { 0xA | 0xD | < | & | 0x9 | ] | 0xDC00 - 0xDFFF }
    #$0020#$0025#$0027#$003B#$003D#$005C#$005E#$D7FF#$E000#$FFFD;

  AttrValueRanges = //# AttrValueChar = CharData - { 0xA | 0xD | 0x9 | < | > | & | \ |  | 0xDC00 - 0xDFFF }
    #$0020#$0021#$0023#$0025#$0028#$003B#$003D#$003D#$003F#$D7FF#$E000#$FFFD;

  //# XML 1.0 Fourth Edition definitions for name characters
  LetterXml4eRanges =
    #$0041#$005A#$0061#$007A#$00C0#$00D6#$00D8#$00F6#$00F8#$0131#$0134#$013E#$0141#$0148#$014A#$017E +
    #$0180#$01C3#$01CD#$01F0#$01F4#$01F5#$01FA#$0217#$0250#$02A8#$02BB#$02C1#$0386#$0386#$0388#$038A +
    #$038C#$038C#$038E#$03A1#$03A3#$03CE#$03D0#$03D6#$03DA#$03DA#$03DC#$03DC#$03DE#$03DE#$03E0#$03E0 +
    #$03E2#$03F3#$0401#$040C#$040E#$044F#$0451#$045C#$045E#$0481#$0490#$04C4#$04C7#$04C8#$04CB#$04CC +
    #$04D0#$04EB#$04EE#$04F5#$04F8#$04F9#$0531#$0556#$0559#$0559#$0561#$0586#$05D0#$05EA#$05F0#$05F2 +
    #$0621#$063A#$0641#$064A#$0671#$06B7#$06BA#$06BE#$06C0#$06CE#$06D0#$06D3#$06D5#$06D5#$06E5#$06E6 +
    #$0905#$0939#$093D#$093D#$0958#$0961#$0985#$098C#$098F#$0990#$0993#$09A8#$09AA#$09B0#$09B2#$09B2 +
    #$09B6#$09B9#$09DC#$09DD#$09DF#$09E1#$09F0#$09F1#$0A05#$0A0A#$0A0F#$0A10#$0A13#$0A28#$0A2A#$0A30 +
    #$0A32#$0A33#$0A35#$0A36#$0A38#$0A39#$0A59#$0A5C#$0A5E#$0A5E#$0A72#$0A74#$0A85#$0A8B#$0A8D#$0A8D +
    #$0A8F#$0A91#$0A93#$0AA8#$0AAA#$0AB0#$0AB2#$0AB3#$0AB5#$0AB9#$0ABD#$0ABD#$0AE0#$0AE0#$0B05#$0B0C +
    #$0B0F#$0B10#$0B13#$0B28#$0B2A#$0B30#$0B32#$0B33#$0B36#$0B39#$0B3D#$0B3D#$0B5C#$0B5D#$0B5F#$0B61 +
    #$0B85#$0B8A#$0B8E#$0B90#$0B92#$0B95#$0B99#$0B9A#$0B9C#$0B9C#$0B9E#$0B9F#$0BA3#$0BA4#$0BA8#$0BAA +
    #$0BAE#$0BB5#$0BB7#$0BB9#$0C05#$0C0C#$0C0E#$0C10#$0C12#$0C28#$0C2A#$0C33#$0C35#$0C39#$0C60#$0C61 +
    #$0C85#$0C8C#$0C8E#$0C90#$0C92#$0CA8#$0CAA#$0CB3#$0CB5#$0CB9#$0CDE#$0CDE#$0CE0#$0CE1#$0D05#$0D0C +
    #$0D0E#$0D10#$0D12#$0D28#$0D2A#$0D39#$0D60#$0D61#$0E01#$0E2E#$0E30#$0E30#$0E32#$0E33#$0E40#$0E45 +
    #$0E81#$0E82#$0E84#$0E84#$0E87#$0E88#$0E8A#$0E8A#$0E8D#$0E8D#$0E94#$0E97#$0E99#$0E9F#$0EA1#$0EA3 +
    #$0EA5#$0EA5#$0EA7#$0EA7#$0EAA#$0EAB#$0EAD#$0EAE#$0EB0#$0EB0#$0EB2#$0EB3#$0EBD#$0EBD#$0EC0#$0EC4 +
    #$0F40#$0F47#$0F49#$0F69#$10A0#$10C5#$10D0#$10F6#$1100#$1100#$1102#$1103#$1105#$1107#$1109#$1109 +
    #$110B#$110C#$110E#$1112#$113C#$113C#$113E#$113E#$1140#$1140#$114C#$114C#$114E#$114E#$1150#$1150 +
    #$1154#$1155#$1159#$1159#$115F#$1161#$1163#$1163#$1165#$1165#$1167#$1167#$1169#$1169#$116D#$116E +
    #$1172#$1173#$1175#$1175#$119E#$119E#$11A8#$11A8#$11AB#$11AB#$11AE#$11AF#$11B7#$11B8#$11BA#$11BA +
    #$11BC#$11C2#$11EB#$11EB#$11F0#$11F0#$11F9#$11F9#$1E00#$1E9B#$1EA0#$1EF9#$1F00#$1F15#$1F18#$1F1D +
    #$1F20#$1F45#$1F48#$1F4D#$1F50#$1F57#$1F59#$1F59#$1F5B#$1F5B#$1F5D#$1F5D#$1F5F#$1F7D#$1F80#$1FB4 +
    #$1FB6#$1FBC#$1FBE#$1FBE#$1FC2#$1FC4#$1FC6#$1FCC#$1FD0#$1FD3#$1FD6#$1FDB#$1FE0#$1FEC#$1FF2#$1FF4 +
    #$1FF6#$1FFC#$2126#$2126#$212A#$212B#$212E#$212E#$2180#$2182#$3007#$3007#$3021#$3029#$3041#$3094 +
    #$30A1#$30FA#$3105#$312C#$4E00#$9FA5#$AC00#$D7A3;

  NCNameXml4eRanges =
    #$002D#$002E#$0030#$0039#$0041#$005A#$005F#$005F#$0061#$007A#$00B7#$00B7#$00C0#$00D6#$00D8#$00F6 +
    #$00F8#$0131#$0134#$013E#$0141#$0148#$014A#$017E#$0180#$01C3#$01CD#$01F0#$01F4#$01F5#$01FA#$0217 +
    #$0250#$02A8#$02BB#$02C1#$02D0#$02D1#$0300#$0345#$0360#$0361#$0386#$038A#$038C#$038C#$038E#$03A1 +
    #$03A3#$03CE#$03D0#$03D6#$03DA#$03DA#$03DC#$03DC#$03DE#$03DE#$03E0#$03E0#$03E2#$03F3#$0401#$040C +
    #$040E#$044F#$0451#$045C#$045E#$0481#$0483#$0486#$0490#$04C4#$04C7#$04C8#$04CB#$04CC#$04D0#$04EB +
    #$04EE#$04F5#$04F8#$04F9#$0531#$0556#$0559#$0559#$0561#$0586#$0591#$05A1#$05A3#$05B9#$05BB#$05BD +
    #$05BF#$05BF#$05C1#$05C2#$05C4#$05C4#$05D0#$05EA#$05F0#$05F2#$0621#$063A#$0640#$0652#$0660#$0669 +
    #$0670#$06B7#$06BA#$06BE#$06C0#$06CE#$06D0#$06D3#$06D5#$06E8#$06EA#$06ED#$06F0#$06F9#$0901#$0903 +
    #$0905#$0939#$093C#$094D#$0951#$0954#$0958#$0963#$0966#$096F#$0981#$0983#$0985#$098C#$098F#$0990 +
    #$0993#$09A8#$09AA#$09B0#$09B2#$09B2#$09B6#$09B9#$09BC#$09BC#$09BE#$09C4#$09C7#$09C8#$09CB#$09CD +
    #$09D7#$09D7#$09DC#$09DD#$09DF#$09E3#$09E6#$09F1#$0A02#$0A02#$0A05#$0A0A#$0A0F#$0A10#$0A13#$0A28 +
    #$0A2A#$0A30#$0A32#$0A33#$0A35#$0A36#$0A38#$0A39#$0A3C#$0A3C#$0A3E#$0A42#$0A47#$0A48#$0A4B#$0A4D +
    #$0A59#$0A5C#$0A5E#$0A5E#$0A66#$0A74#$0A81#$0A83#$0A85#$0A8B#$0A8D#$0A8D#$0A8F#$0A91#$0A93#$0AA8 +
    #$0AAA#$0AB0#$0AB2#$0AB3#$0AB5#$0AB9#$0ABC#$0AC5#$0AC7#$0AC9#$0ACB#$0ACD#$0AE0#$0AE0#$0AE6#$0AEF +
    #$0B01#$0B03#$0B05#$0B0C#$0B0F#$0B10#$0B13#$0B28#$0B2A#$0B30#$0B32#$0B33#$0B36#$0B39#$0B3C#$0B43 +
    #$0B47#$0B48#$0B4B#$0B4D#$0B56#$0B57#$0B5C#$0B5D#$0B5F#$0B61#$0B66#$0B6F#$0B82#$0B83#$0B85#$0B8A +
    #$0B8E#$0B90#$0B92#$0B95#$0B99#$0B9A#$0B9C#$0B9C#$0B9E#$0B9F#$0BA3#$0BA4#$0BA8#$0BAA#$0BAE#$0BB5 +
    #$0BB7#$0BB9#$0BBE#$0BC2#$0BC6#$0BC8#$0BCA#$0BCD#$0BD7#$0BD7#$0BE7#$0BEF#$0C01#$0C03#$0C05#$0C0C +
    #$0C0E#$0C10#$0C12#$0C28#$0C2A#$0C33#$0C35#$0C39#$0C3E#$0C44#$0C46#$0C48#$0C4A#$0C4D#$0C55#$0C56 +
    #$0C60#$0C61#$0C66#$0C6F#$0C82#$0C83#$0C85#$0C8C#$0C8E#$0C90#$0C92#$0CA8#$0CAA#$0CB3#$0CB5#$0CB9 +
    #$0CBE#$0CC4#$0CC6#$0CC8#$0CCA#$0CCD#$0CD5#$0CD6#$0CDE#$0CDE#$0CE0#$0CE1#$0CE6#$0CEF#$0D02#$0D03 +
    #$0D05#$0D0C#$0D0E#$0D10#$0D12#$0D28#$0D2A#$0D39#$0D3E#$0D43#$0D46#$0D48#$0D4A#$0D4D#$0D57#$0D57 +
    #$0D60#$0D61#$0D66#$0D6F#$0E01#$0E2E#$0E30#$0E3A#$0E40#$0E4E#$0E50#$0E59#$0E81#$0E82#$0E84#$0E84 +
    #$0E87#$0E88#$0E8A#$0E8A#$0E8D#$0E8D#$0E94#$0E97#$0E99#$0E9F#$0EA1#$0EA3#$0EA5#$0EA5#$0EA7#$0EA7 +
    #$0EAA#$0EAB#$0EAD#$0EAE#$0EB0#$0EB9#$0EBB#$0EBD#$0EC0#$0EC4#$0EC6#$0EC6#$0EC8#$0ECD#$0ED0#$0ED9 +
    #$0F18#$0F19#$0F20#$0F29#$0F35#$0F35#$0F37#$0F37#$0F39#$0F39#$0F3E#$0F47#$0F49#$0F69#$0F71#$0F84 +
    #$0F86#$0F8B#$0F90#$0F95#$0F97#$0F97#$0F99#$0FAD#$0FB1#$0FB7#$0FB9#$0FB9#$10A0#$10C5#$10D0#$10F6 +
    #$1100#$1100#$1102#$1103#$1105#$1107#$1109#$1109#$110B#$110C#$110E#$1112#$113C#$113C#$113E#$113E +
    #$1140#$1140#$114C#$114C#$114E#$114E#$1150#$1150#$1154#$1155#$1159#$1159#$115F#$1161#$1163#$1163 +
    #$1165#$1165#$1167#$1167#$1169#$1169#$116D#$116E#$1172#$1173#$1175#$1175#$119E#$119E#$11A8#$11A8 +
    #$11AB#$11AB#$11AE#$11AF#$11B7#$11B8#$11BA#$11BA#$11BC#$11C2#$11EB#$11EB#$11F0#$11F0#$11F9#$11F9 +
    #$1E00#$1E9B#$1EA0#$1EF9#$1F00#$1F15#$1F18#$1F1D#$1F20#$1F45#$1F48#$1F4D#$1F50#$1F57#$1F59#$1F59 +
    #$1F5B#$1F5B#$1F5D#$1F5D#$1F5F#$1F7D#$1F80#$1FB4#$1FB6#$1FBC#$1FBE#$1FBE#$1FC2#$1FC4#$1FC6#$1FCC +
    #$1FD0#$1FD3#$1FD6#$1FDB#$1FE0#$1FEC#$1FF2#$1FF4#$1FF6#$1FFC#$20D0#$20DC#$20E1#$20E1#$2126#$2126 +
    #$212A#$212B#$212E#$212E#$2180#$2182#$3005#$3005#$3007#$3007#$3021#$302F#$3031#$3035#$3041#$3094 +
    #$3099#$309A#$309D#$309E#$30A1#$30FA#$30FC#$30FE#$3105#$312C#$4E00#$9FA5#$AC00#$D7A3;
begin
  InitRanges(WhitespaceRanges,  Whitespace);
  InitRanges(LetterXml4eRanges, Letter);
  InitRanges(NCStartNameRanges, NCStartNameSC);
  InitRanges(NCNameRanges,      NCNameSC);
  InitRanges(CharDataRanges,    CharData);
  InitRanges(NCNameXml4eRanges, NCNameXml4e);
  InitRanges(TextRanges,        Text);
  InitRanges(AttrValueRanges,   AttrValue);
end;

class procedure TACLXMLCharType.InitRanges(const ARanges: string; Attribute: Byte);
var
  P: PChar;
  AChar, AEndChar: Char;
  L: Integer;
begin
  L := Length(ARanges);
  P := PChar(ARanges);
  while L > 0 do
  begin
    AChar    := P^;
    Inc(P);
    AEndChar := P^;
    while AChar <= AEndChar do
    begin
      FCharProperties[AChar] := FCharProperties[AChar] or Attribute;
      Inc(AChar);
    end;
    Inc(P);
    Dec(L, 2);
  end;
end;

class function TACLXMLCharType.CombineSurrogateChar(ALowChar, AHighChar: Char): Integer;
begin
  Result := (Ord(ALowChar) - Ord(SurLowStart)) or ((Ord(AHighChar) - Ord(SurHighStart)) shl 10) + $10000;
end;

class procedure TACLXMLCharType.SplitSurrogateChar(ACombinedChar: Integer; out ALowChar: Char; out AHighChar: Char);
var
  V: Integer;
begin
  V := ACombinedChar - $10000;
  ALowChar := Char(Ord(SurLowStart) + V mod 1024);
  AHighChar := Char(Ord(SurHighStart) + V div 1024);
end;

class function TACLXMLCharType.IsAttributeValueChar(C: Char): Boolean;
begin
  Result := (FCharProperties[C] and AttrValue) <> 0;
end;

class function TACLXMLCharType.IsCharData(C: Char): Boolean;
begin
  Result := (FCharProperties[C] and CharData) <> 0;
end;

//# just for fun. dotnet framework uses for testing the method:
//# This method tests whether a value is in a given range with just one test; start and end should be constants
//#        private static bool InRange(int value, int start, int end) {
//#            Debug.Assert(start <= end);
//#            return (uint)(value - start) <= (uint)(end - start);
//#        }
class function TACLXMLCharType.IsSurrogate(C: Char): Boolean;
begin
  Result := (C >= SurHighStart) and (C <= SurLowEnd);
end;

class function TACLXMLCharType.IsTextChar(C: Char): Boolean;
begin
  Result := (FCharProperties[C] and Text) <> 0;
end;

class function TACLXMLCharType.IsHighSurrogate(C: Char): Boolean;
begin
  Result := (C >= SurHighStart) and (C <= SurHighEnd);
end;

class function TACLXMLCharType.IsLowSurrogate(C: Char): Boolean;
begin
  Result := (C >= SurLowStart) and (C <= SurLowEnd);
end;

class function TACLXMLCharType.IsNCNameSingleChar(ACh: Char): Boolean;
begin
  Result := (FCharProperties[ACh] and NCNameSC) <> 0;
end;

class function TACLXMLCharType.IsNameSingleChar(ACh: Char): Boolean;
begin
  Result := IsNCNameSingleChar(ACh) or (ACh = ':');
end;

class function TACLXMLCharType.IsOnlyCharData(const S: string): Integer;
var
  I: Integer;
begin
  I := 1;
  while I <= Length(S) do
  begin
    if (FCharProperties[S[I]] and CharData) = 0 then
    begin
      if (I + 1 > Length(S)) or
        not (TACLXMLCharType.IsHighSurrogate(S[I]) and TACLXMLCharType.IsLowSurrogate(S[I + 1])) then
        Exit(I)
      else
        Inc(I);
    end;
    Inc(I);
  end;
  Result := 0;
end;

class function TACLXMLCharType.IsOnlyWhitespace(const S: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    if (FCharProperties[S[I]] and Whitespace) = 0 then
      Exit(False);
  Result := True;
end;

class function TACLXMLCharType.IsWhiteSpace(C: Char): Boolean;
begin
  Result := FCharProperties[C] and Whitespace <> 0;
end;

class function TACLXMLCharType.IsPubidChar(C: Char): Boolean;
begin
  if C < #$0080 then
    Result := (PublicIdBitmap[Ord(C) shr 4] and (1 shl (Ord(C) and $0F))) <> 0
  else
    Result := False;
end;

class function TACLXMLCharType.IsPublicId(const S: string): Integer;
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    if not IsPubidChar(S[I]) then
      Exit(I);
  Result := 0;
end;

{ TACLXMLConvert }

class constructor TACLXMLConvert.Create;
begin
  FMap := TACLStringsMap.Create;
  FMap.Add(#9, #9);
  FMap.Add(#10, #10);
  FMap.Add(#13, #13);
  FMap.Add(#39, 'apos');
  FMap.Add('"', 'quot');
  FMap.Add('&', 'amp');
  FMap.Add('<', 'lt');
  FMap.Add('>', 'gt');
end;

class destructor TACLXMLConvert.Destroy;
begin
  FreeAndNil(FMap);
end;

class function TACLXMLConvert.IsEncodedCharacter(const S: string; APosition, ALength: Integer; out ACode: Integer): Boolean;
begin
  Result := (APosition <= ALength - 6) and (S[APosition] = '_') and (S[APosition + 1] = 'x') and
    (S[APosition + 6] = '_') and TryStrToInt('$' + Copy(S, APosition + 2, 4), ACode);
end;

class function TACLXMLConvert.IsInvalidXmlChar(const C: Word): Boolean;
begin
  Result := (C <= $001F) or (C >= $FFFF);
end;

class function TACLXMLConvert.DecodeBoolean(const S: string): Boolean;
var
  AValue: Integer;
begin
  if TryStrToInt(S, AValue) then
    Result := AValue <> 0
  else
    Result := acCompareTokens(S, sXMLBoolValues[True]);
end;

class function TACLXMLConvert.DecodeName(const S: string): string;

  function GetReplacement(const S: UnicodeString): UnicodeString;
  begin
    if not FMap.TryGetKey(S, Result) then
    begin
      if (S <> '') and (S[1] = '#') then
        Result := Char(StrToIntDef(Copy(S, 2, MaxInt), 0))
      else
        Result := S;
    end;
  end;

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
      if (P^ = '\') and (L > 0) and FMap.TryGetValue((P + 1)^, V) then
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

class function TACLXMLConvert.EncodeName(const S: string): string;
begin
  Result := EncodeString(S, False, True);
end;

class function TACLXMLConvert.IsHTMLCode(var P: PWideChar; var L: Integer): Boolean;
begin
  while (L > 0) and CharInSet(P^, ['0'..'9', '#', 'A'..'Z', 'a'..'z']) do
  begin
    Inc(P);
    Dec(L);
  end;
  Result := P^ = ';';
end;

class function TACLXMLConvert.EncodeString(const S: string; ARemoveBreakLines, ASkipServiceCharacters: Boolean): string;

  function EncodeChar(const AChar: Char): string; inline;
  begin
    Result := '_x' + IntToHex(Word(AChar), 4) + '_';
  end;

var
  ABuilder: TStringBuilder;
  AChar: Char;
  ALength: Integer;
  AReplacement: string;
  I, X: Integer;
begin
  ALength := Length(S);
  ABuilder := TStringBuilder.Create((ALength * 3) div 2);
  try
    for I := 1 to ALength do
    begin
      AChar := S[I];
      if ARemoveBreakLines and ((Ord(AChar) = 13) or (Ord(AChar) = 10)) then
        ABuilder.Append(' ')
      else if not ASkipServiceCharacters and FMap.TryGetValue(AChar, AReplacement) then
        ABuilder.Append('&').Append(AReplacement).Append(';')
      else if IsInvalidXmlChar(Word(AChar)) then
        ABuilder.Append(EncodeChar(AChar))
      else if IsEncodedCharacter(S, I, ALength, X) then
        ABuilder.Append(EncodeChar('_'))
      else
        ABuilder.Append(AChar);
    end;
    Result := ABuilder.ToString;
  finally
    ABuilder.Free;
  end;
end;

end.
