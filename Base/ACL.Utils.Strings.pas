﻿////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   String Utilities
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Utils.Strings;

{$I ACL.Config.inc}
{$POINTERMATH ON}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ELSE}
  LazUtf8,
{$ENDIF}
  // VCL
{$IFNDEF ACL_BASE_NOVCL}
  {Vcl.}Graphics,
{$ENDIF}
  // System
  {System.}Character,
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Generics.Collections,
  {System.}Types,
  System.UITypes,
  // ACL
  ACL.Threading,
  ACL.Utils.Common;

const
  acCRLF = #13#10;
  acEmptyStr = '';
  acEmptyStrA = AnsiString('');
  acEmptyStrU = UnicodeString('');
  acLineBreakMacro = '\n';
  acLineSeparator = WideChar($2028);
  acZero = #0#0;
  acZeroWidthSpace = WideChar($200B);

type
  TAnsiStringDynArray = array of AnsiString;

  TAnsiExplodeStringReceiveResultProc = reference to procedure (
    ACursorStart, ACursorNext: PAnsiChar; var ACanContinue: Boolean);
  TWideExplodeStringReceiveResultProc = reference to procedure (
    ACursorStart, ACursorNext: PWideChar; var ACanContinue: Boolean);

  { TACLTimeFormat }

  TACLFormatTimePart = (ftpMilliSeconds, ftpSeconds, ftpMinutes, ftpHours, ftpDays);
  TACLFormatTimeParts = set of TACLFormatTimePart;

  TACLTimeFormat = class
  public const
    BracketsIn  = ['(', '['];
    BracketsOut = [')', ']'];
  public
    class function Format(const ATimeInMilliSeconds: Int64;
      AParts: TACLFormatTimeParts = [ftpSeconds..ftpHours];
      ASuppressZeroValues: Boolean = True): string; inline;
    class function FormatEx(ATimeInSeconds: Single): string; overload;
    class function FormatEx(ATimeInSeconds: Single; AParts: TACLFormatTimeParts;
      ASuppressZeroValues: Boolean): string; overload;
    class function FormatEx(ATimeInSeconds: Single; AParts: TACLFormatTimeParts;
      const APartDelimiter: string = ':'; ASuppressZeroValues: Boolean = False): string; overload;
    // Parts;Delimiter;Flags
    // Parts: can be (D)ay, (H)our, (M)inute, (S)econd, (Z)millisecond
    // Delimiter: default is ":"
    // Flags: can be: "Z" - suppress (Z)eros
    //
    // Example: HMS;:;Z ->  1:05:30
    // Example: HMS;:   -> 01:05:30
    // Example: MS;:    ->    65:30
    class function FormatEx(ATimeInSeconds: Single; const AFormatString: string): string; overload;
    //
    // Supports:
    // h:mm:ss
    // h:mm:ss.msec
    // m:ss
    // m:ss.msec
    // s
    // s.msec
    class function Parse(const S: string; out ATimeInSeconds: Single): Boolean; overload; inline;
    class function Parse(var Scan: PChar; out ATimeInSeconds: Single): Boolean; overload;
  end;

  { TACLSearchString }

  TACLSearchString = class
  strict private
    FLock: TACLCriticalSection;
    FEmpty: Boolean;
    FIgnoreCase: Boolean;
    FIgnoreDiacritic: Boolean;
    FMask: TStringDynArray;
    FMaskResult: array of Boolean;
    FSeparator: Char;
    FValue: string;

    function GetValueIsNumeric: Boolean;
    function PrepareString(const AValue: string): string;
    procedure SetIgnoreCase(const AValue: Boolean);
    procedure SetValue(AValue: string);
  public
    constructor Create; overload;
    constructor Create(const AMask: string; AIgnoreCase: Boolean = True); overload;
    destructor Destroy; override;
    function Compare(const S: string): Boolean;

    procedure BeginComparing;
    procedure AddToCompare(S: string);
    function EndComparing: Boolean;

    property Empty: Boolean read FEmpty;
    property IgnoreCase: Boolean read FIgnoreCase write SetIgnoreCase;
    property IgnoreDiacritic: Boolean read FIgnoreDiacritic write FIgnoreDiacritic;
    property Separator: Char read FSeparator write FSeparator;
    property Value: string read FValue write SetValue;
    property ValueIsNumeric: Boolean read GetValueIsNumeric;
  end;

  { TACLLCSCalculator }

  // https://en.wikipedia.org/wiki/Longest_common_subsequence_problem
  TACLLCSCalculator = class
  public const
    DefaultEqualsNearbyChars = 2;
  public type
    TDiffState = (tsEquals, tsInserted, tsDeleted);
    TDiffCompareProc = reference to function (ASourceIndex, ATargetIndex: Integer): Boolean;
    TDiffResultProc = reference to procedure (AIndex: Integer; AState: TDiffState);
    TStringDiff = TPair<Char, TDiffState>;
  public
    // Compliance
    class function Compliance(const ASource, ATarget: string): Single; overload;
    class function Compliance(const ASource, ATarget: TStrings): Single; overload;
    // Difference
    class function Difference(const ASource, ATarget: string): TList<TStringDiff>; overload;
    class procedure Difference(const ASourceLength, ATargetLength: Integer;
      const ACompareProc: TDiffCompareProc; const AResultProc: TDiffResultProc;
      const AEqualsNearbyTokens: Integer = 1); overload;
  end;

  { TACLStringBuilder }

  TACLStringBuilder = class
  strict private const
    CacheSize = 4;
    DefaultCapacity = $10;
    HugeCapacityThreshold = 1048576;
  strict private
    class var Cache: array[0..Pred(CacheSize)] of TACLStringBuilder;
  strict private
    FCapacity: Integer;
    FData: TArray<Char>;
    FDataLength: Integer;

    procedure GrowCapacity(ACountNeeded: Integer);
    procedure SetCapacity(AValue: Integer);
    procedure SetDataLength(AValue: Integer);
  public
    constructor Create(ACapacity: Integer = DefaultCapacity);
  {$REGION ' Pool '}
    class destructor Finalize;
    class function Get(ACapacity: Integer = DefaultCapacity): TACLStringBuilder;
    procedure Release; // Push the builder back to pool
  {$ENDREGION}

    function Append(const AValue: Boolean): TACLStringBuilder; overload; inline;
    function Append(const AValue: Byte): TACLStringBuilder; overload; inline;
    function Append(const AValue: Cardinal): TACLStringBuilder; overload; inline;
    function Append(const AValue: Currency): TACLStringBuilder; overload; inline;
    function Append(const AValue: Double): TACLStringBuilder; overload; inline;
    function Append(const AValue: Int64): TACLStringBuilder; overload; inline;
    function Append(const AValue: Integer): TACLStringBuilder; overload; inline;
    function Append(const AValue: PChar; ALength: Integer): TACLStringBuilder; overload;
    function Append(const AValue: Shortint): TACLStringBuilder; overload; inline;
    function Append(const AValue: Single): TACLStringBuilder; overload; inline;
    function Append(const AValue: Smallint): TACLStringBuilder; overload; inline;
    function Append(const AValue: TArray<AnsiChar>; AStartIndex, ACount: Integer): TACLStringBuilder; overload; inline;
    function Append(const AValue: TArray<WideChar>; AStartIndex, ACount: Integer): TACLStringBuilder; overload; inline;
    function Append(const AValue: TObject): TACLStringBuilder; overload; inline;
    function Append(const AValue: UInt64): TACLStringBuilder; overload; inline;
    function Append(const AValue: string): TACLStringBuilder; overload; inline;
    function Append(const AValue: string; AStartIndex: Integer; ACount: Integer = -1): TACLStringBuilder; overload;
    function Append(const AValue: AnsiChar): TACLStringBuilder; overload; inline;
    function Append(const AValue: WideChar): TACLStringBuilder; overload; inline;
    function Append(const AValue: Word): TACLStringBuilder; overload; inline;
    function AppendFormat(const AFormat: string; const AArgs: array of const): TACLStringBuilder; overload;
    function AppendLine(const AValue: string): TACLStringBuilder; overload; inline;
    function AppendLine: TACLStringBuilder; overload; inline;
    function Insert(AIndex: Integer; const AValue: string): TACLStringBuilder;
    function ToString(AStartIndex, ACount: Integer): string; reintroduce; overload;
    function ToString: string; overload; override;
    function ToTrimmedString: string;

    property Capacity: Integer read FCapacity write SetCapacity;
    property Chars: TArray<Char> read FData; // ReadOnly !!!
    property Length: Integer read FDataLength write SetDataLength;
  end;

  { TACLAppVersion }

  TACLAppVersion = record
  public const
    DateTimeNow = -1;
  public
    BuildDate: TDateTime;
    BuildNumber: Integer;
    BuildSuffix: string;
    MajorVersion: Word;
    MinorVersion1: Byte;
    MinorVersion2: Byte;

    class function Create(AVersion: Integer; ABuildNumber: Integer = 0;
      const ABuildSuffix: string = ''; ABuildDate: TDateTime = 0): TACLAppVersion; static;
    class function FormatBuildDate(const ADate: TDateTime): string; static;
    function ID: Integer;
    function ToDisplayString: string;
    function ToScriptString: string;
    function ToString: string;
  end;

  { TACLHexcode }

  TACLHexcode = class
  strict private const
    Map: array[0..15] of Char = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f');
  strict private
    class var FByteToHexMap: array[Byte] of string;
  public
    class constructor Create;

    class function Decode(const AChar1, AChar2: Char): Byte; overload;
    class function Decode(const AChar1, AChar2: Char; out AValue: Byte): Boolean; overload; inline;
    class function Decode(const AChar1: Char; out AValue: Byte): Boolean; overload; inline;
    class function Decode(const ACode: string; AStream: TStream): Boolean; overload;
    class function DecodeString(const ACode: string): UnicodeString; overload;

    class function Encode(ABuffer: PByte; ACount: Integer): string; overload;
    class function Encode(AByte: Byte): string; overload; static; inline;
    class function Encode(AChar: AnsiChar): string; overload; static; inline;
    class function Encode(AChar: WideChar): string; overload; static; inline;
    class function Encode(AChar: WideChar; ABuffer: PWideChar): PWideChar; overload; static;
    class function Encode(AStream: TStream): string; overload;
    class function EncodeFile(const AFileName: string): string; overload;
    class function EncodeString(const AValue: AnsiString): string; overload;
    class function EncodeString(const AValue: UnicodeString): string; overload;
  end;

  { TACLMimecode }

  TACLMimecode = class
  strict private const
  {$REGION 'Internal Constants'}
    PadByte = $3D;
    DecodeTable: array[Byte] of Byte =
    (
      255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
      255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
      255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 062, 255, 255, 255, 063,
      052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 255, 255, 255, 000, 255, 255,
      255, 000, 001, 002, 003, 004, 005, 006, 007, 008, 009, 010, 011, 012, 013, 014,
      015, 016, 017, 018, 019, 020, 021, 022, 023, 024, 025, 255, 255, 255, 255, 255,
      255, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 040,
      041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 255, 255, 255, 255, 255,
      255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
      255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
      255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
      255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
      255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
      255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
      255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
      255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
    );
    EncodeTable: array[0..63] of Byte =
    (
      065, 066, 067, 068, 069, 070, 071, 072, 073, 074, 075, 076, 077, 078, 079, 080,
      081, 082, 083, 084, 085, 086, 087, 088, 089, 090, 097, 098, 099, 100, 101, 102,
      103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118,
      119, 120, 121, 122, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 043, 047
    );
  {$ENDREGION}
  public
    class function Decode(ASrc: PByte; ASrcSize: Integer; AStream: TStream): Integer; overload;
    class function Decode(const ACode: AnsiString; AStream: TStream): Boolean; overload;
    class function DecodeBytes(const ACode: AnsiString): TBytes; overload;
    class function DecodeBytes(const ACode: UnicodeString): TBytes; overload;
    class function Encode(ASrc: PByte; ASrcSize: Integer; AStream: TStream): Integer; overload;
    class function Encode(P: PByteArray; ASize: Integer): TMemoryStream; overload;
    class function EncodeBytes(const ABytes: PAnsiChar; ACount: Integer): string; overload;
    class function EncodeBytes(const ABytes: TBytes): string; overload;
    class function EncodeString(const S: AnsiString; AStream: TStream): Integer; overload;
    class function EncodeString(const S: UnicodeString; AStream: TStream): Integer; overload;
  end;

  { TACLPunycode }

  TACLPunycodeStatus = (apcOK, apcErrorBadInput, apcErrorInsufficientBuffer, apcErrorOverflow);

  TACLPunycode = class
  strict private const
    PUNY_BASE = 36;
    PUNY_DAMP = 700;
    PUNY_DELIMITER = $2D;
    PUNY_INITIAL_BIAS = 72;
    PUNY_INITIAL_N = $80;
    PUNY_SKEW = 38;
    PUNY_TMAX = 26;
    PUNY_TMIN = 1;
  private
    class function AdaptBias(ADelta, ANumPoints: Cardinal; AIsFirstTime: Boolean): Cardinal; inline;
    class function DecodeDigit(ACodePoint: Cardinal): Cardinal; inline;
    class function EncodeDigit(ADigit: Cardinal): Byte; inline;
  public
    class function Decode(const S: AnsiString): UnicodeString; overload;
    class function Decode(Input: PByte; InputLength: Cardinal;
      var OutputLength: Cardinal; Output: PWordArray = nil): TACLPunycodeStatus; overload;
    class function DecodeDomain(const S: AnsiString): UnicodeString; overload;

    class function Encode(const S: UnicodeString): AnsiString; overload;
    class function Encode(const S: UnicodeString; out A: AnsiString): Boolean; overload;
    class function Encode(Input: PWordArray; InputLength: Cardinal;
      var OutputLength: Cardinal; Output: PByte = nil): TACLPunycodeStatus; overload;
    class function EncodeDomain(const S: UnicodeString): AnsiString; overload;
  end;

  { TACLTranslit }

  TACLTranslit = class
  strict private const
    ColChar = 33;
    RArrayL = UnicodeString('абвгдеёжзийклмнопрстуфхцчшщьыъэюя');
    Translit: array[1..ColChar] of UnicodeString = (
      'a', 'b', 'v', 'g', 'd', 'e', 'yo', 'zh', 'z', 'i', 'i''', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u',
      'f', 'h', 'ts', 'ch', 'sh', 'sch', #39, 'y', #39, 'e', 'yu', 'ya'
    );
  public
    class function Decode(const S: UnicodeString): UnicodeString;
    class function Encode(const S: UnicodeString): UnicodeString;
  end;

  { TACLEncodings }

  TACLEncodings = class
  strict private
    class var FCodePages: TObject;
    class var FMap: TObject;
    class var FMapLock: TACLCriticalSection;
  {$IFDEF MSWINDOWS}
    class function CodePageEnumProc(lpCodePageString: PWideChar): Cardinal; stdcall; static;
  {$ENDIF}
  public
    class constructor Create;
    class destructor Destroy;
    class function ASCII: TEncoding;
    class function Default: TEncoding;
    class procedure EnumAnsiCodePages(const AProc: TProc<Integer, string>);
    class function Get(const CodePage: Integer): TEncoding; overload;
    class function Get(const Name: string): TEncoding; overload;
    class function WebName(const Encoding: TEncoding): string;
  end;

  TACLFontData = array[0..3] of string;

var
  DefaultCodePage: Integer = CP_ACP;

  acLangSizeSuffixB: string = 'B';
  acLangSizeSuffixKB: string = 'KB';
  acLangSizeSuffixMB: string = 'MB';
  acLangSizeSuffixGB: string = 'GB';

// Helpers
function StrToIntDef(const S: AnsiString; ADefault: Integer): Integer; overload;

// Allocation and TextConversion
function acAllocStr(const S: string): PChar; overload;
function acAllocStr(const S: string; out ALength: Integer): PChar; overload;
function acMakeString(const P: PAnsiChar; L: Integer): AnsiString; overload; inline;
function acMakeString(const P: PWideChar; L: Integer): UnicodeString; overload; inline;
function acMakeString(const AScanStart, AScanNext: PAnsiChar): AnsiString; overload;
function acMakeString(const AScanStart, AScanNext: PWideChar): UnicodeString; overload;
function acStringLength(const AScanStart, AScanNext: PAnsiChar): Integer; overload; inline;
function acStringLength(const AScanStart, AScanNext: PWideChar): Integer; overload; inline;
function acStringIsRealUnicode(const S: string): Boolean;

function acStringFromAnsiString(const S: AnsiString; CodePage: Integer = -1): string; inline;
// Converts string (Unicode in Delphi or UTF8 in Lazarus) to AnsiString according
// to specified codepage, if codepage is not specified the DefaultCodePage will be used.
function acStringToAnsiString(const S: string; CodePage: Integer = -1): AnsiString; inline;

// Special conversion functions between Delphi and FreePascal
// Delphi: maps to acUStringFromAnsiString with CP_ACP
// FPC: returns S as it is
function acString(const S: AnsiString): string; overload; inline;
// Delphi: returns S as it is
// FPC: asumes that string is UTF8-encoded
function acString(const S: UnicodeString): string; overload; inline;
function acUString(const S: string): UnicodeString; inline;
// Delphi: maps to acStringToAnsiString with CP_ACP
// FPC: return S as it is
function acAString(const S: string): AnsiString;

function acUStringFromBytes(const Bytes: PByte; Count: Integer): UnicodeString; overload;
function acUStringFromBytes(const Bytes: TBytes): UnicodeString; overload;
function acUStringFromAnsiString(const S: AnsiChar): WideChar; overload;
function acUStringFromAnsiString(const S: AnsiString): UnicodeString; overload;
function acUStringFromAnsiString(const S: AnsiString; CodePage: Integer): UnicodeString; overload;
function acUStringFromAnsiString(const S: PAnsiChar; Length, CodePage: Integer): UnicodeString; overload;
function acUStringToAnsiString(const S: UnicodeString; CodePage: Integer = -1): AnsiString; overload;
function acUStringToBytes(W: PWideChar; ACount: Integer): RawByteString;

// UTF8
// Unlike built-in to RTL and Windows OS versions of UTF8 Decoder
// The acDecodeUtf8 returns an empty string if UTF8 sequence is malformed
function acDecodeUtf8(const Source: AnsiString): UnicodeString;
function acEncodeUtf8(const Source: UnicodeString): AnsiString;
function acUtf8IsWellformed(Source: PAnsiChar; SourceBytes: Integer): Boolean;
function acUtf8ToUnicode(Dest: PWideChar; MaxDestChars: Integer; Source: PAnsiChar; SourceBytes: Integer): Integer;
// Delphi: just maps to acDecodeUtf8 / acEncodeUtf8
// FPC: returns string as it is (we asume that AnsiString is already utf8-encoded);
function acStringFromUtf8(const S: AnsiString): string;
function acStringToUtf8(const S: string): AnsiString;

// Characters
function acCharLength(const P: PChar): Integer; overload;
function acCharLength(const S: string; Index: Integer): Integer; overload;

// Search
function acContains(const AChar: AnsiChar; const AString: AnsiString): Boolean; inline; overload;
function acContains(const AChar: WideChar; const AString: UnicodeString): Boolean; inline; overload;
function acContains(const ASubStr, AString: string; AIgnoreCase: Boolean = False): Boolean; inline; overload;
function acFindStringInMemoryA(const S: AnsiString;
  AMem: PByte; AMemSize, AMemOffset: Integer; out AOffset: Integer): Boolean;
function acFindStringInMemoryW(const S: UnicodeString;
  AMem: PByte; AMemSize, AMemOffset: Integer; out AOffset: Integer): Boolean;
function acPos(const ACharToSearch: AnsiChar; const AString: AnsiString): Integer; overload;
function acPos(const ACharToSearch: WideChar; const AString: UnicodeString): Integer; overload;
function acPos(const ASubStr, AString: string;
  AIgnoreCase: Boolean = False; AOffset: Integer = 1): Integer; overload; inline;
function acPos(const ASubStr, AString: string;
  AIgnoreCase, AWholeWords: Boolean; AOffset: Integer = 1): Integer; overload;

// Explode
function acExplodeString(AScan: PAnsiChar; AScanCount: Integer;
  const ADelimiters: AnsiString; AReceiveProc: TAnsiExplodeStringReceiveResultProc): Integer; overload;
function acExplodeString(AScan: PWideChar; AScanCount: Integer;
  const ADelimiters: UnicodeString; AReceiveProc: TWideExplodeStringReceiveResultProc): Integer; overload;
function acExplodeString(const S: AnsiString;
  const ADelimiters: AnsiString; AReceiveProc: TAnsiExplodeStringReceiveResultProc): Integer; overload;
function acExplodeString(const S: UnicodeString;
  const ADelimiters: UnicodeString; AReceiveProc: TWideExplodeStringReceiveResultProc): Integer; overload;
function acExplodeString(const S, ADelimiters: string; out AParts: TStringDynArray): Integer; overload;
function acExplodeStringAsIntegerArray(const S: string;
  ADelimiter: Char; AArray: PInteger; AArrayLength: Integer): Integer;
function acCharCount(const S: string): Integer; overload;
function acCharCount(const S, ACharacters: string): Integer; overload;
function acCharCount(P: PChar; ALength: Integer; const ACharacters: string): Integer; overload;

// Case
function acAllWordsWithCaptialLetter(const S: UnicodeString; IgnoreSourceCase: Boolean = False): UnicodeString; overload;
function acFirstWordWithCaptialLetter(const S: UnicodeString): UnicodeString; overload;
function acLowerCase(const S: string): string; overload; inline;
function acLowerCase(const S: AnsiChar): AnsiChar; overload; inline;
function acLowerCase(const S: WideChar): WideChar; overload; inline;
function acUpperCase(const S: string): string; overload; inline;
function acUpperCase(const S: AnsiChar): AnsiChar; overload; inline;
function acUpperCase(const S: WideChar): WideChar; overload; inline;

// Comparing
function acBeginsWith(const S, ATestPrefix: string; AIgnoreCase: Boolean = True): Boolean;
function acEndsWith(const S, ATestSuffix: string; AIgnoreCase: Boolean = True): Boolean;
function acCompareStringByMask(const AMask, AStr: string): Boolean;
function acCompareStrings(const S1, S2: string; AIgnoreCase: Boolean = True): Integer; overload;
function acCompareStrings(P1, P2: PChar; L1, L2: Integer; AIgnoreCase: Boolean = True): Integer; overload;
function acLogicalCompare(const S1, S2: string; AIgnoreCase: Boolean = True): Integer; overload;
function acLogicalCompare(P1, P2: PChar; P1Len, P2Len: Integer; AIgnoreCase: Boolean = True): Integer; overload;
function acSameText(const S1, S2: string): Boolean;
function acSameTextEx(const S: string; const AStrs: array of string): Boolean;

// Encoding
function acDetectEncoding(ABuffer: PByte; ABufferSize: Integer;
  ADefaultEncoding: TEncoding = nil): TEncoding; overload; deprecated;
function acDetectEncoding(ABuffer: TBytes;
  out AEncoding: TEncoding; ADefaultEncoding: TEncoding = nil): Integer; overload;
function acDetectEncoding(AStream: TStream;
  ADefaultEncoding: TEncoding = nil): TEncoding; overload;
function acIsNativeStringEncoding(AEncoding: TEncoding): Boolean;

// Load/Save String
function acLoadString(AStream: TStream;
  ADefaultEncoding: TEncoding; out AEncoding: TEncoding): string; overload;
function acLoadString(AStream: TStream;
  AEncoding: TEncoding = nil): string; overload;
function acLoadString(const AFileName: string;
  AEncoding: TEncoding = nil): string; overload;
procedure acSaveString(const AStream: TStream; const AString: UnicodeString;
  AEncoding: TEncoding = nil; AWriteBOM: Boolean = True); overload;
procedure acSaveString(const AFileName: string; const AString: UnicodeString;
  AEncoding: TEncoding = nil; AWriteBOM: Boolean = True); overload;
{$IF DEFINED(FPC) AND NOT DEFINED(UNICODE)}
procedure acSaveString(const AStream: TStream; const AString: string;
  AEncoding: TEncoding = nil; AWriteBOM: Boolean = True); overload;
procedure acSaveString(const AFileName: string; const AString: string;
  AEncoding: TEncoding = nil; AWriteBOM: Boolean = True); overload;
{$IFEND}

// Replacing
function acRemoveChar(const S: string; ACharToRemove: Char): string;
function acRemoveDiacritic(const S: string): string;
function acRemoveSurrogates(const S: UnicodeString; AReplaceBy: WideChar = #0): UnicodeString;
function acReplaceChar(const S: string; ACharToReplace, AReplaceBy: Char): string;
function acReplaceChars(const S, ACharsToReplace: string; AReplaceBy: Char = '_'): string;
function acStringReplace(const S, OldPattern, NewPattern: string;
  AIgnoreCase: Boolean = False; AWholeWords: Boolean = False): string;

// Integer <-> PChar (supports for the FullWidth Numbers too)
function acIsDigit(AChar: Char): Boolean; inline;
function acPCharToIntDef(AChars: PChar; ACount: Integer; ADefaultValue: Int64 = 0): Int64; inline;
function acTryPCharToInt(AChars: PChar; ACount: Integer; out AValue: Int64): Boolean;

// Linebreaks
function acDecodeLineBreaks(const S: string): string;
function acEncodeLineBreaks(const S: string): string;
function acRemoveLineBreaks(const S: string): string;
function acReplaceLineBreaks(const S, ReplaceBy: string): string;

// Conversion
function acFontStyleDecode(const Style: TFontStyles): Byte;
function acFontStyleEncode(Style: Integer): TFontStyles;
{$IFNDEF ACL_BASE_NOVCL}
function acFontToString(AFont: TFont): string; overload;
function acFontToString(const AName: string; AColor: TColor;
  AHeight: Integer; AStyle: TFontStyles): string; overload;
procedure acStringToFont(const S: string; const Font: TFont);
{$ENDIF}
procedure acStringToFontData(const S: string; out AFontData: TACLFontData);
function acPointToString(const P: TPoint): string;
function acRectToString(const R: TRect): string;
function acSizeToString(const S: TSize): string;
function acStringToPoint(const S: string): TPoint;
function acStringToRect(const S: string): TRect;
function acStringToSize(const S: string): TSize;

// Formatting
function acFormatFloat(const AFormat: string;
  const AValue: Double): string; overload;
function acFormatFloat(const AFormat: string;
  const AValue: Double; AShowPlusSign: Boolean): string; overload;
function acFormatSize(const AValue: Int64; AAllowGigaBytes: Boolean = True): string;
function acFormatTrackNo(ATrack: Integer): string;

// Utils
function IfThenW(ACondition: Boolean; const ATrue: string; const AFalse: string = ''): string; overload; inline;
function IfThenW(const A, B: AnsiString): AnsiString; overload; inline;
function IfThenW(const A, B: UnicodeString): UnicodeString; overload; inline;
function acDupeString(const AText: string; ACount: Integer): string;
function acTrim(const S: string): string;
procedure acStrLCopy(ADest: PAnsiChar; const ASource: AnsiString; AMax: Integer); overload;
procedure acStrLCopy(ADest: PWideChar; const ASource: UnicodeString; AMax: Integer); overload;
function acStrLen(S: PAnsiChar; AMaxScanCount: Integer): Integer; overload; inline;
function acStrLen(S: PWideChar; AMaxScanCount: Integer): Integer; overload; inline;
function acStrScan(Str: PAnsiChar; ACount: Integer; C: AnsiChar): PAnsiChar; overload; inline;
function acStrScan(Str: PAnsiChar; C: AnsiChar): PAnsiChar; overload; inline;
function acStrScan(Str: PWideChar; ACount: Integer; C: WideChar): PWideChar; overload; inline;
function acStrScan(Str: PWideChar; C: WideChar): PWideChar; overload; inline;
implementation

uses
  // System
  System.AnsiStrings,
  {System.}RTLConsts,
  // ACL
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FastCode,
  ACL.Parsers,
  ACL.Utils.FileSystem,
  ACL.Utils.Stream;

const
  MaxPreambleLength = 3;

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

function StrToIntDef(const S: AnsiString; ADefault: Integer): Integer;
begin
  Result := {System.}SysUtils.StrToIntDef(string(S), ADefault);
end;

// -----------------------------------------------------------------------------
// Conversion
// -----------------------------------------------------------------------------

function acStringToPoint(const S: string): TPoint;
begin
  Result := NullPoint;
  acExplodeStringAsIntegerArray(S, ',', @Result.X, 2);
end;

function acStringToSize(const S: string): TSize;
begin
  Result := NullSize;
  acExplodeStringAsIntegerArray(S, ',', @Result.cx, 2);
end;

function acStringToRect(const S: string): TRect;
begin
  Result := NullRect;
  acExplodeStringAsIntegerArray(S, ',', @Result.Left, 4);
end;

function acPointToString(const P: TPoint): string;
begin
  Result := Format('%d,%d', [P.X, P.Y]);
end;

function acSizeToString(const S: TSize): string;
begin
  Result := Format('%d,%d', [S.cx, S.cy]);
end;

function acRectToString(const R: TRect): string;
begin
  Result := Format('%d,%d,%d,%d', [R.Left, R.Top, R.Right, R.Bottom]);
end;

function acFontStyleEncode(Style: Integer): TFontStyles;
begin
  Result := [];
  if 1 and Style = 1 then
    Result := Result + [TFontStyle.fsItalic];
  if 2 and Style = 2 then
    Result := Result + [TFontStyle.fsBold];
  if 4 and Style = 4 then
    Result := Result + [TFontStyle.fsUnderline];
  if 8 and Style = 8 then
    Result := Result + [TFontStyle.fsStrikeOut];
end;

function acFontStyleDecode(const Style: TFontStyles): Byte;
begin
  Result := 0;
  if TFontStyle.fsItalic in Style then
    Result := 1;
  if TFontStyle.fsBold in Style then
    Result := Result or 2;
  if TFontStyle.fsUnderline in Style then
    Result := Result or 4;
  if TFontStyle.fsStrikeOut in Style then
    Result := Result or 8;
end;

function acFontToString(const AName: string;
  AColor: TColor; AHeight: Integer; AStyle: TFontStyles): string; overload;
begin
  Result := Format('%s,%d,%d,%d', [AName, AColor, AHeight, acFontStyleDecode(AStyle)]);
end;

{$IFNDEF ACL_BASE_NOVCL}
function acFontToString(AFont: TFont): string; overload;
begin
  Result := acFontToString(AFont.Name, AFont.Color, AFont.Height, AFont.Style);
end;

procedure acStringToFont(const S: string; const Font: TFont);
var
  AFontData: TACLFontData;
begin
  acStringToFontData(S, AFontData);
  Font.Name := AFontData[0];
  Font.Color := StrToIntDef(AFontData[1], 0);
  Font.Height := StrToIntDef(AFontData[2], 0);
  Font.Style := acFontStyleEncode(StrToIntDef(AFontData[3], 0));
end;
{$ENDIF}

procedure acStringToFontData(const S: string; out AFontData: TACLFontData);
var
  ALen: Integer;
  APos: Integer;
  AStart, AScan: PChar;
begin
  AScan := PChar(S);
  ALen := Length(S);
  AStart := AScan;
  APos := 0;
  while (ALen >= 0) and (APos <= High(AFontData)) do
  begin
    if (AScan^ = ',') or (ALen = 0) then
    begin
      AFontData[APos] := acMakeString(AStart, AScan);
      AStart := AScan;
      Inc(AStart);
      Inc(APos);
    end;
    Dec(ALen);
    Inc(AScan);
  end;
end;

// ---------------------------------------------------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------------------------------------------------

function acFormatFloat(const AFormat: string; const AValue: Double): string;
begin
  Result := FormatFloat(AFormat, AValue, InvariantFormatSettings);
end;

function acFormatFloat(const AFormat: string; const AValue: Double; AShowPlusSign: Boolean): string;
const
  SignsMap: array[Boolean] of string = ('', '+');
begin
  Result := SignsMap[(AValue >= 0) and AShowPlusSign] + acFormatFloat(AFormat, AValue);
end;

function acFormatSize(const AValue: Int64; AAllowGigaBytes: Boolean = True): string;
begin
  if AValue < 0 then
    Exit('-' + acFormatSize(-AValue, AAllowGigaBytes));

  if AValue < SIZE_ONE_KILOBYTE then
    Result := IntToStr(AValue) + ' ' + acLangSizeSuffixB
  else if AValue < SIZE_ONE_MEGABYTE then
    Result := FormatFloat('0.00', AValue / SIZE_ONE_KILOBYTE) + ' ' + acLangSizeSuffixKB
  else if not AAllowGigaBytes or (AValue < SIZE_ONE_GIGABYTE)then
    Result := FormatFloat('0.00', AValue / SIZE_ONE_MEGABYTE) + ' ' + acLangSizeSuffixMB
  else
    Result := FormatFloat('0.00', AValue / SIZE_ONE_GIGABYTE) + ' ' + acLangSizeSuffixGB;
end;

function acFormatTrackNo(ATrack: Integer): string;
begin
  if (ATrack >= 0) and (ATrack < 10) then
    Result := '0' + IntToStr(ATrack)
  else
    Result := IntToStr(ATrack);
end;

// ---------------------------------------------------------------------------------------------------------------------
// Text Conversions
// ---------------------------------------------------------------------------------------------------------------------

function acAString(const S: string): AnsiString;
begin
{$IF DEFINED(UNICODE)}
  Result := acUStringToAnsiString(S, CP_ACP);
{$ELSE}
  Result := S;
{$ENDIF}
end;

function acString(const S: AnsiString): string;
begin
{$IF DEFINED(UNICODE)}
  Result := acUStringFromAnsiString(S, CP_ACP);
{$ELSE}
  Result := S;
{$ENDIF}
end;

function acString(const S: UnicodeString): string; inline;
begin
{$IF DEFINED(UNICODE)}
  Result := S;
{$ELSEIF DEFINED(FPC)}
  Result := acEncodeUtf8(S);
{$ELSE}
  Result := acStringToAnsiString(S, CP_ACP);
{$ENDIF}
end;

function acStringIsRealUnicode(const S: string): Boolean;
var
  I: Integer;
  L: Integer;
  P: PChar;
begin
  L := Length(S);
  P := PChar(S);
  for I := 1 to L do
  begin
    if Ord(P^) >= $7F then
      Exit(True); // Unicode (inc.UTF8) or Extended ASCII
    Inc(P);
  end;
  Result := False;
end;

function acStringFromAnsiString(const S: AnsiString; CodePage: Integer = -1): string;
begin
  if CodePage < 0 then
    CodePage := DefaultCodePage;
  Result := acString(acUStringFromAnsiString(S, CodePage));
end;

function acStringToAnsiString(const S: string; CodePage: Integer = -1): AnsiString;
begin
  if CodePage < 0 then
    CodePage := DefaultCodePage;
  Result := acUStringToAnsiString(acUString(S), CodePage);
end;

function acUString(const S: string): UnicodeString; inline;
begin
{$IF DEFINED(UNICODE)}
  Result := S;
{$ELSEIF DEFINED(FPC)}
  Result := acDecodeUtf8(S);
{$ELSE}
  Result := acUStringFromAnsiString(S, CP_ACP);
{$ENDIF}
end;

function acUStringToAnsiString(const S: UnicodeString; CodePage: Integer): AnsiString; overload;
{$IFDEF FPC}
var
  LData: TBytes;
begin
  if CodePage < 0 then CodePage := DefaultCodePage;  
  LData := TACLEncodings.Get(CodePage).GetBytes(S);
  Result := acMakeString(PAnsiChar(@LData[0]), Length(LData));
{$ELSE}
var
  LLen: Integer;
  LTmp: PWideChar;
begin
  if CodePage < 0 then CodePage := DefaultCodePage;
  LTmp := PWideChar(S);
  LLen := LocaleCharsFromUnicode(CodePage, 0, LTmp, Length(S), nil, 0, nil, nil);
  SetLength(Result, LLen);
  LocaleCharsFromUnicode(CodePage, 0, LTmp, Length(S), PAnsiChar(Result), LLen, nil, nil);
{$ENDIF}
end;

function acUStringToBytes(W: PWideChar; ACount: Integer): RawByteString;
var
  B: PByte;
begin
  SetLength(Result{%H-}, ACount);
  if ACount > 0 then
  begin
    B := @Result[1];
    while ACount > 0 do
    begin
      B^ := Byte(W^);
      Dec(ACount);
      Inc(W);
      Inc(B);
    end;
  end;
end;

function acUStringFromAnsiString(const S: AnsiString): UnicodeString;
begin
  Result := acUStringFromAnsiString(S, DefaultCodePage);
end;

function acUStringFromAnsiString(const S: AnsiChar): WideChar;
begin
{$IFDEF FPC}
  Result := PWideChar(acUStringFromAnsiString(PAnsiChar(@S), 1, DefaultCodePage))^;
{$ELSE}
  UnicodeFromLocaleChars(DefaultCodePage, 0, @S, 1, @Result, 1);
{$ENDIF}
end;

function acUStringFromAnsiString(const S: PAnsiChar; Length, CodePage: Integer): UnicodeString;
{$IFDEF FPC}
var
  LTxt: TBytes;
  LUni: TUnicodeCharArray;
begin
{$MESSAGE WARN 'OPTIMIZE'}
  SetLength(LTxt{%H-}, Length);
  Move(S^, LTxt[0], Length);
  LUni := TACLEncodings.Get(CodePage).GetChars(LTxt);
  Result := acMakeString(PWideChar(@LUni[0]), System.Length(LUni));
{$ELSE}
var
  LLen: Integer;
begin
  LLen := UnicodeFromLocaleChars(CodePage, 0, S, Length, nil, 0);
  SetLength(Result, LLen);
  UnicodeFromLocaleChars(CodePage, 0, S, Length, PWideChar(Result), LLen);
{$ENDIF}
end;

function acUStringFromAnsiString(const S: AnsiString; CodePage: Integer): UnicodeString;
begin
  Result := acUStringFromAnsiString(PAnsiChar(S), Length(S), CodePage);
end;

function acUStringFromBytes(const Bytes: TBytes): UnicodeString;
var
  LCount: Integer;
begin
  LCount := Length(Bytes);
  if LCount > 0 then
    Result := acUStringFromBytes(@Bytes[0], LCount)
  else
    Result := acEmptyStrU;
end;

function acUStringFromBytes(const Bytes: PByte; Count: Integer): UnicodeString;
var
  B: PByte;
  W: PWord;
begin
  if Count <= 0 then
    Exit(acEmptyStrU);

  SetLength(Result{%H-}, Count);
  B := Bytes;
  W := @Result[1];
  while Count > 0 do
  begin
    W^ := B^;
    Dec(Count);
    Inc(W);
    Inc(B);
  end;
end;

//==============================================================================
// Search
//==============================================================================

function acContains(const AChar: AnsiChar; const AString: AnsiString): Boolean;
begin
  Result := acStrScan(Pointer(AString), AChar) <> nil;
end;

function acContains(const AChar: WideChar; const AString: UnicodeString): Boolean;
begin
  Result := acStrScan(Pointer(AString), AChar) <> nil;
end;

function acContains(const ASubStr, AString: string; AIgnoreCase: Boolean = False): Boolean;
begin
  Result := acPos(ASubStr, AString, AIgnoreCase) > 0;
end;

function FindDataInMemory(const AData, AMem: PByte;
  ADataSize, AMemSize, AMemOffset: Integer; out AOffset: Integer): Boolean;
var
  P: PByte;
  C: Integer;
begin
  Result := False;
  if ADataSize = 0 then Exit;
  P := AMem + AMemOffset;
  C := AMemSize - AMemOffset;
  while C >= ADataSize do
  begin
    Result :=
      (PByteArray(P)^[0] = PByteArray(AData)^[0]) and
      (PByteArray(P)^[ADataSize - 1] = PByteArray(AData)^[ADataSize - 1]) and
      (CompareMem(P, AData, ADataSize));

    if Result then
    begin
      AOffset := AMemSize - C;
      Break;
    end;
    Dec(C);
    Inc(P);
  end;
end;

function acFindStringInMemoryA(const S: AnsiString;
  AMem: PByte; AMemSize, AMemOffset: Integer; out AOffset: Integer): Boolean;
begin
  Result := FindDataInMemory(PByte(@S[1]), AMem, Length(S), AMemSize, AMemOffset, AOffset);
end;

function acFindStringInMemoryW(const S: UnicodeString;
  AMem: PByte; AMemSize, AMemOffset: Integer; out AOffset: Integer): Boolean;
begin
  Result := FindDataInMemory(PByte(@S[1]), AMem, Length(S) * SizeOf(WideChar), AMemSize, AMemOffset, AOffset);
end;

function acPos(const ACharToSearch: AnsiChar; const AString: AnsiString): Integer;
var
  P, R: PAnsiChar;
begin
  P := PAnsiChar(AString);
  R := acStrScan(P, Length(AString), ACharToSearch);
  if R <> nil then
    Result := 1 + (R - P)
  else
    Result := 0
end;

function acPos(const ACharToSearch: WideChar; const AString: UnicodeString): Integer;
var
  P, R: PWideChar;
begin
  P := PWideChar(AString);
  R := acStrScan(P, Length(AString), ACharToSearch);
  if R <> nil then
    Result := 1 + (R - P)
  else
    Result := 0
end;

function acPos(const ASubStr, AString: string; AIgnoreCase: Boolean = False; AOffset: Integer = 1): Integer;
begin
  if AIgnoreCase then
    Result := Pos(acUpperCase(ASubStr), acUpperCase(AString), AOffset)
  else
    Result := Pos(ASubStr, AString, AOffset);
end;

function acPos(const ASubStr, AString: string; AIgnoreCase, AWholeWords: Boolean; AOffset: Integer = 1): Integer;
var
  AStrLen: Integer;
  ASubStrLen: Integer;
begin
  if AWholeWords then
  begin
    AStrLen := Length(AString);
    ASubStrLen := Length(ASubStr);
    Result := AOffset;
    repeat
      Result := acPos(ASubStr, AString, AIgnoreCase, Result);
      if Result > 0 then
      begin
        if ((Result = 1) or (acPos(AString[Result - 1], acParserDefaultDelimiterChars) > 0)) and
           ((Result + ASubStrLen > AStrLen) or (acPos(AString[Result + ASubStrLen], acParserDefaultDelimiterChars) > 0))
        then
          Break;
        Inc(Result, ASubStrLen);
      end
      else
        Break;
    until False;
  end
  else
    Result := acPos(ASubStr, AString, AIgnoreCase, AOffset);
end;

//==============================================================================
// Allocation
//==============================================================================

function acAllocStr(const S: string): PChar;
var
  L: Integer;
begin
  Result := acAllocStr(S, L);
end;

function acAllocStr(const S: string; out ALength: Integer): PChar;
begin
  ALength := Length(S);
  Result := AllocMem((ALength + 1) * SizeOf(Char));
  FastMove(S[1], Result^, ALength * SizeOf(Char));
end;

function acMakeString(const P: PAnsiChar; L: Integer): AnsiString; inline;
begin
  if L > 0 then
    SetString(Result, P, L)
  else
    Result := '';
end;

function acMakeString(const P: PWideChar; L: Integer): UnicodeString;
begin
  if L > 0 then
    SetString(Result, P, L)
  else
    Result := '';
end;

function acMakeString(const AScanStart, AScanNext: PAnsiChar): AnsiString; overload;
begin
  SetString(Result, AScanStart, acStringLength(AScanStart, AScanNext));
end;

function acMakeString(const AScanStart, AScanNext: PWideChar): UnicodeString;
begin
  SetString(Result, AScanStart, acStringLength(AScanStart, AScanNext));
end;

function acStringLength(const AScanStart, AScanNext: PAnsiChar): Integer;
begin
  if AScanNext > AScanStart then
    Result := AScanNext - AScanStart
  else
    Result := 0;
end;

function acStringLength(const AScanStart, AScanNext: PWideChar): Integer;
begin
  if AScanNext > AScanStart then
    Result := AScanNext - AScanStart
  else
    Result := 0;
end;

//==============================================================================
// UTF8
//==============================================================================

function acUtf8IsWellformed(Source: PAnsiChar; SourceBytes: Integer): Boolean;
begin
  Result := acUtf8ToUnicode(nil, MaxInt, Source, SourceBytes) > 0;
end;

function acUtf8ToUnicode(Dest: PWideChar; MaxDestChars: Integer; Source: PAnsiChar; SourceBytes: Integer): Integer;
const
  Masks: array[1..3] of Byte = ($3F, $1F, $F);
var
  AByte: Byte;
  AByteRemaining: Integer;
  ACharAccumulator: Cardinal;
begin
  if Source = nil then
    Exit(0);

  Result := 0;
  if Dest <> nil then
    FastZeroMem(Dest, MaxDestChars * SizeOf(WideChar));

  while (SourceBytes > 0) and (Result < MaxDestChars) do
  begin
    AByte := Cardinal(Source^);
    Dec(SourceBytes);
    Inc(Source);

    // Aggregate the char
    ACharAccumulator := AByte;
    if AByte and $80 <> 0 then // non-single byte
    begin
      if AByte and $F0 = $F0 then
        AByteRemaining := 3 // 4 byte-wide
      else if AByte and $E0 = $E0 then
        AByteRemaining := 2 // 3 byte-wide
      else if AByte and $C0 = $C0 then
        AByteRemaining := 1 // 2 byte-wide
      else
        Exit(-1); // malformed bit-stream

      if AByteRemaining > SourceBytes then
        Exit(-1); // incomplete multibyte char

      ACharAccumulator := AByte and Masks[AByteRemaining];
      while AByteRemaining > 0 do
      begin
        AByte := Byte(Source^);
        if AByte and $C0 <> $80 then
          Exit(-1); // malformed trail byte or out of range char
        ACharAccumulator := (ACharAccumulator shl 6) or (AByte and $3F);
        Dec(AByteRemaining);
        Dec(SourceBytes);
        Inc(Source);
      end;
    end;

    // Post the char
    if ACharAccumulator > MaxWord then // Surrogate
    begin
      if Result + 2 > MaxDestChars then
        Break;
      if Dest <> nil then
      begin
        Dest^ := WideChar((((ACharAccumulator - $10000) shr 10) and $3FF) or $D800);
        Inc(Dest);
        Dest^ := WideChar((((ACharAccumulator - $10000) and $3FF) or $DC00));
        Inc(Dest);
      end;
      Inc(Result, 2);
    end
    else
    begin
      if Dest <> nil then
      begin
        Dest^ := WideChar(ACharAccumulator);
        Inc(Dest);
      end;
      Inc(Result);
    end;
  end;
end;

function acDecodeUtf8(const Source: AnsiString): UnicodeString;
var
  L: Integer;
begin
  L := Length(Source);
  if L > 0 then
  begin
    SetLength(Result{%H-}, L);
    L := acUtf8ToUnicode(PWideChar(Result), L, PAnsiChar(Source), L);
    if L > 0 then
      SetLength(Result, L);
  end;
  if L <= 0 then
    Result := '';
end;

function acEncodeUtf8(const Source: UnicodeString): AnsiString;
var
  L: Integer;
begin
  Result := '';
  L := Length(Source);
  if L > 0 then
  begin
    SetLength(Result, L * 3); // SetLength includes space for null terminator
    L := System.UnicodeToUtf8(PAnsiChar(Result), Length(Result) + 1, PWideChar(Source), L);
    if L > 0 then
      SetLength(Result, L - 1)
  end;
end;

function acStringToUtf8(const S: string): AnsiString;
begin
{$IFDEF FPC}
  Result := S;
{$ELSE}
  Result := acEncodeUtf8(S);
{$ENDIF}
end;

function acStringFromUtf8(const S: AnsiString): string;
begin
{$IFDEF FPC}
  Result := S;
{$ELSE}
  Result := acDecodeUtf8(S);
{$ENDIF}
end;

// -----------------------------------------------------------------------------
// Characters
// -----------------------------------------------------------------------------

function acCharLength(const P: PChar): Integer;
begin
{$IFDEF FPC}
  Result := UTF8CodepointSizeFast(P);
{$ELSE}
  Result := 1 + Ord(P^.IsHighSurrogate);
{$ENDIF}
end;

function acCharLength(const S: string; Index: Integer): Integer;
begin
  Result := acCharLength(@S[Index]);
end;

// -----------------------------------------------------------------------------
// ExplodeString
// -----------------------------------------------------------------------------

function acExplodeString(AScan: PAnsiChar; AScanCount: Integer;
  const ADelimiters: AnsiString; AReceiveProc: TAnsiExplodeStringReceiveResultProc): Integer;
var
  ACanContinue: Boolean;
  ACursor: PAnsiChar;
  ADelimiterCode: AnsiChar;
  AIsDelimiter: Boolean;
  AIsFastWay: Boolean;
begin
  Result := 0;
  if AScanCount > 0 then
  begin
    ACursor := AScan;
    ACanContinue := True;

    AIsFastWay := Length(ADelimiters) = 1;
    if AIsFastWay then
      ADelimiterCode := ADelimiters[1]
    else
      ADelimiterCode := #0;

    while (AScanCount >= 0) and ACanContinue do
    begin
      if AIsFastWay then
        AIsDelimiter := AScan^ = ADelimiterCode
      else
        AIsDelimiter := acContains(AScan^, ADelimiters);

      if (AScanCount = 0) or AIsDelimiter then
      begin
        AReceiveProc(ACursor, AScan, ACanContinue);
        ACursor := AScan;
        Inc(ACursor);
        Inc(Result);
      end;
      Dec(AScanCount);
      Inc(AScan);
    end;
  end;
end;

function acExplodeString(const S, ADelimiters: string; out AParts: TStringDynArray): Integer;
var
  AArray: PString;
  AArrayLength: Integer;
  AScan: PChar;
  AScanCount: Integer;
begin
  AScan := PChar(S);
  AScanCount := Length(S);

  Result := acCharCount(AScan, AScanCount, ADelimiters) + 1;
  SetLength(AParts{%H-}, Result);
  if Result > 0 then
  begin
    AArray := @AParts[0];
    AArrayLength := Result;
    Result := acExplodeString(AScan, AScanCount, ADelimiters,
      procedure (ACursorStart, ACursorNext: PChar; var ACanContinue: Boolean)
      begin
        AArray^ := acMakeString(ACursorStart, ACursorNext);
        Dec(AArrayLength);
        Inc(AArray);
        ACanContinue := AArrayLength > 0;
      end);
  end;
end;

function acExplodeString(const S, ADelimiters: AnsiString;
  AReceiveProc: TAnsiExplodeStringReceiveResultProc): Integer;
begin
  Result := acExplodeString(PAnsiChar(S), Length(S), ADelimiters, AReceiveProc);
end;

function acExplodeString(const S, ADelimiters: UnicodeString;
  AReceiveProc: TWideExplodeStringReceiveResultProc): Integer;
begin
  Result := acExplodeString(PWideChar(S), Length(S), ADelimiters, AReceiveProc);
end;

function acExplodeString(AScan: PWideChar; AScanCount: Integer;
  const ADelimiters: UnicodeString; AReceiveProc: TWideExplodeStringReceiveResultProc): Integer;
var
  ACanContinue: Boolean;
  ACursor: PWideChar;
  ADelimiterCode: WideChar;
  AIsDelimiter: Boolean;
  AIsFastWay: Boolean;
begin
  Result := 0;
  if AScanCount > 0 then
  begin
    ACursor := AScan;
    ACanContinue := True;

    AIsFastWay := Length(ADelimiters) = 1;
    if AIsFastWay then
      ADelimiterCode := ADelimiters[1]
    else
      ADelimiterCode := #0;

    while (AScanCount >= 0) and ACanContinue do
    begin
      if AIsFastWay then
        AIsDelimiter := AScan^ = ADelimiterCode
      else
        AIsDelimiter := acContains(AScan^, ADelimiters);

      if (AScanCount = 0) or AIsDelimiter then
      begin
        AReceiveProc(ACursor, AScan, ACanContinue);
        ACursor := AScan;
        Inc(ACursor);
        Inc(Result);
      end;

      Dec(AScanCount);
      Inc(AScan);
    end;
  end;
end;

function acExplodeStringAsIntegerArray(const S: string;
  ADelimiter: Char; AArray: PInteger; AArrayLength: Integer): Integer;
begin
  if (AArray = nil) or (AArrayLength <= 0) then
    Result := 0
  else
    Result := acExplodeString(PChar(S), Length(S), ADelimiter,
      procedure (ACursorStart, ACursorNext: PChar; var ACanContinue: Boolean)
      begin
        AArray^ := acPCharToIntDef(ACursorStart, acStringLength(ACursorStart, ACursorNext));
        Dec(AArrayLength);
        Inc(AArray);
        ACanContinue := AArrayLength > 0;
      end);
end;

function acCharCount(const S: string): Integer;
begin
{$IFDEF UNICODE}
  Result := Length(S);
{$ELSE}
  Result := UTF8Length(S);
{$ENDIF}
end;

function acCharCount(const S, ACharacters: string): Integer;
begin
  Result := acCharCount(PChar(S), Length(S), ACharacters);
end;

function acCharCount(P: PChar; ALength: Integer; const ACharacters: string): Integer;
begin
  Result := 0;
  while ALength > 0 do
  begin
    if acContains(P^, ACharacters) then
      Inc(Result);
    Dec(ALength);
    Inc(P);
  end;
end;

//==============================================================================
// Charcase
//==============================================================================

//  Test('swoosh fever (extended version)', 'Swoosh Fever (Extended Version)');
//  Test('there''s nothing to do', 'There''s Nothing To Do');
//  Test('21th', '21th');
//  Test('dear monsters, be patient', 'Dear Monsters, Be Patient');
function acAllWordsWithCaptialLetter(const S: UnicodeString; IgnoreSourceCase: Boolean = False): UnicodeString;
var
  AChar1: WideChar;
  ADelims: UnicodeString;
  AEndOfWordFound: Boolean;
  APos, ALen: Cardinal;
begin
  APos := 1;
  ALen := Length(S);
  if IgnoreSourceCase then
    Result := S
  else
    Result := S.ToLower;

  ADelims := acParserDefaultDelimiterChars;
  AEndOfWordFound := True;
  while APos <= ALen do
  begin
    AChar1 := Result[APos];
    if AEndOfWordFound then
      Result[APos] := acUpperCase(AChar1);
    AEndOfWordFound := (AChar1 <> #39) and acContains(AChar1, ADelims);
    Inc(APos);
  end;
end;

function acFirstWordWithCaptialLetter(const S: UnicodeString): UnicodeString;
var
  APos, ALen: Cardinal;
  Ch1, Ch2: WideChar;
begin
  Result := S.ToLower;
  ALen := Length(Result);
  APos := 0;
  if ALen > 0 then
  repeat
    Inc(APos);
    Ch1 := Result[APos];
    Ch2 := acUpperCase(Ch1);
    if Ch1 <> Ch2 then
    begin
      Result[APos] := Ch2;
      Break;
    end;
  until (APos + 1 > ALen);
end;

function acLowerCase(const S: string): string;
begin
  Result := S.ToLower;
end;

function acLowerCase(const S: AnsiChar): AnsiChar;
begin
  Result := AnsiLowerCase(S)[1];
end;

function acLowerCase(const S: WideChar): WideChar;
begin
  Result := S.ToLower
end;

function acUpperCase(const S: string): string;
begin
  Result := S.ToUpper;
end;

function acUpperCase(const S: AnsiChar): AnsiChar;
begin
  Result := AnsiUpperCase(S)[1];
end;

function acUpperCase(const S: WideChar): WideChar;
begin
  Result := S.ToUpper;
end;

//==============================================================================
// Comparing
//==============================================================================

function acBeginsWith(const S, ATestPrefix: string; AIgnoreCase: Boolean = True): Boolean;
var
  L: Integer;
begin
  L := Length(ATestPrefix);
  Result := (Length(S) >= L) and (acCompareStrings(PChar(S), PChar(ATestPrefix), L, L, AIgnoreCase) = 0);
end;

function acEndsWith(const S, ATestSuffix: string; AIgnoreCase: Boolean = True): Boolean;
var
  LS: Integer;
  LT: Integer;
begin
  LS := Length(S);
  LT := Length(ATestSuffix);
  Result := (LS >= LT) and (acCompareStrings(PChar(S) + LS - LT, PChar(ATestSuffix), LT, LT, AIgnoreCase) = 0);
end;

function acCompareStringByMask(const AMask, AStr: string): Boolean;
begin
  with TACLSearchString.Create(AMask) do
  try
    Result := Compare(AStr);
  finally
    Free;
  end;
end;

function acCompareStrings(const S1, S2: string; AIgnoreCase: Boolean = True): Integer;
begin
{$IFDEF MSWINDOWS}
  Result := acCompareStrings(PChar(S1), PChar(S2), Length(S1), Length(S2), AIgnoreCase);
{$ELSE}
  if AIgnoreCase then
    Result := AnsiCompareText(S1, S2)
  else
    Result := AnsiCompareStr(S1, S2);
{$ENDIF}
end;

function acCompareStrings(P1, P2: PChar; L1, L2: Integer; AIgnoreCase: Boolean = True): Integer;
{$IFDEF MSWINDOWS}
const
  CaseMap: array[Boolean] of Integer = (0, NORM_IGNORECASE);
begin
  Result := CompareStringW(LOCALE_USER_DEFAULT, CaseMap[AIgnoreCase], P1, L1, P2, L2) - CSTR_EQUAL;
end;
{$ELSE}
begin
  Result := acCompareStrings(acMakeString(P1, L1), acMakeString(P2, L2), AIgnoreCase);
end;
{$ENDIF}

function acLogicalCompare(const S1, S2: string; AIgnoreCase: Boolean = True): Integer;
begin
  Result := acLogicalCompare(PChar(S1), PChar(S2), Length(S1), Length(S2), AIgnoreCase);
end;

function acLogicalCompare(P1, P2: PChar; P1Len, P2Len: Integer; AIgnoreCase: Boolean = True): Integer;
var
  AIsDigit1: Boolean;
  AIsDigit2: Boolean;
  SL1, SL2: Integer;
begin
  Result := 0;
  while P1Len > 0 do
  begin
    if P2Len = 0 then
      Exit(1);

    AIsDigit1 := acIsDigit(P1^);
    AIsDigit2 := acIsDigit(P2^);
    if AIsDigit1 and AIsDigit2 then
    begin
      SL1 := 0;
      SL2 := 0;
      while (SL1 < P1Len) and acIsDigit((P1 + SL1)^) do
        Inc(SL1);
      while (SL2 < P2Len) and acIsDigit((P2 + SL2)^) do
        Inc(SL2);
      Result := Sign(acPCharToIntDef(P1, SL1, 0) - acPCharToIntDef(P2, SL2, 0));
      Dec(P1Len, SL1);
      Dec(P2Len, SL2);
      Inc(P1, SL1);
      Inc(P2, SL2);
    end
    else
      if AIsDigit1 or AIsDigit2 then
      begin
        Result := acCompareStrings(P1, P2, 1, 1, AIgnoreCase);
        Dec(P1Len);
        Dec(P2Len);
        Inc(P1);
        Inc(P2);
      end
      else
      begin
        SL1 := 0;
        SL2 := 0;
        while (SL1 < P1Len) and not acIsDigit((P1 + SL1)^) do
          Inc(SL1);
        while (SL2 < P2Len) and not acIsDigit((P2 + SL2)^) do
          Inc(SL2);
        Result := acCompareStrings(P1, P2, SL1, SL2, AIgnoreCase);
        Dec(P1Len, SL1);
        Dec(P2Len, SL2);
        Inc(P1, SL1);
        Inc(P2, SL2);
      end;

    if Result <> 0 then
      Exit;
  end;
  if P2Len > 0 then
    Result := -1;
end;

function acSameText(const S1, S2: string): Boolean;
var
  L1, L2: Integer;
begin
  L1 := Length(S1);
  L2 := Length(S2);
  Result := (L1 = L2) and (acCompareStrings(S1, S2) = 0);
end;

function acSameTextEx(const S: string; const AStrs: array of string): Boolean;
var
  I: Integer;
begin
  for I := 0 to Length(AStrs) - 1 do
  begin
    if acSameText(S, AStrs[I]) then
      Exit(True);
  end;
  Result := False;
end;

// ---------------------------------------------------------------------------------------------------------------------
// acDetectEncoding
// ---------------------------------------------------------------------------------------------------------------------

function acDetectEncoding(ABuffer: PByte; ABufferSize: Integer; ADefaultEncoding: TEncoding = nil): TEncoding;
var
  ABytes: TBytes;
begin
  SetLength(ABytes{%H-}, Min(ABufferSize, MaxPreambleLength));
  FastMove(ABuffer^, ABytes, Length(ABytes));
  acDetectEncoding(ABytes, Result, ADefaultEncoding);
end;

function acDetectEncoding(ABuffer: TBytes; out AEncoding: TEncoding; ADefaultEncoding: TEncoding = nil): Integer;
begin
  AEncoding := nil;
  if ADefaultEncoding = nil then
    ADefaultEncoding := TACLEncodings.Default;
  Result := TEncoding.GetBufferEncoding(ABuffer, AEncoding, ADefaultEncoding);
end;

function acDetectEncoding(AStream: TStream; ADefaultEncoding: TEncoding = nil): TEncoding;
var
  ABytes: TBytes;
  ASavedPosition: Int64;
begin
  ASavedPosition := AStream.Position;
  try
    SetLength(ABytes{%H-}, MaxPreambleLength);
    SetLength(ABytes, Max(0, AStream.Read(ABytes, Length(ABytes))));
    Inc(ASavedPosition, acDetectEncoding(ABytes, Result, ADefaultEncoding))
  finally
    AStream.Position := ASavedPosition;
  end;
end;

function acIsNativeStringEncoding(AEncoding: TEncoding): Boolean;
begin
{$IF DEFINED(UNICODE)}
  Result := AEncoding = TEncoding.Unicode;
{$ELSEIF DEFINED(FPC)}
  Result := AEncoding = TEncoding.UTF8;
{$ELSE}
  Result := False;
{$ENDIF}
end;

// ---------------------------------------------------------------------------------------------------------------------
// Load/Save String
// ---------------------------------------------------------------------------------------------------------------------

function acLoadString(AStream: TStream; AEncoding: TEncoding = nil): string;
var
  LUnused: TEncoding;
begin
  Result := acLoadString(AStream, AEncoding, LUnused);
end;

function acLoadString(AStream: TStream; ADefaultEncoding: TEncoding; out AEncoding: TEncoding): string;
var
  LBytes: TBytes;
  LSize: Cardinal;
begin
  AEncoding := acDetectEncoding(AStream, ADefaultEncoding);
  LSize := AStream.Available;
  if LSize <= 0 then
    Exit(acEmptyStr);
  if acIsNativeStringEncoding(AEncoding) then
  begin
    SetLength(Result{%H-}, LSize div SizeOf(Char));
    AStream.ReadBuffer(Result[1], LSize);
  end
  else
  begin
    SetLength(LBytes{%H-}, LSize);
    AStream.ReadBuffer(LBytes[0], LSize);
    try
      Result := acString(AEncoding.GetString(LBytes));
    except
      Result := acString(TACLEncodings.Default.GetString(LBytes));
    end;
  end;
end;

function acLoadString(const AFileName: string; AEncoding: TEncoding = nil): string;
var
  LStream: TStream;
begin
  if StreamCreateReader(AFileName, LStream) then
  try
    Result := acLoadString(LStream, AEncoding);
  finally
    LStream.Free;
  end
  else
    Result := acEmptyStr;
end;

procedure acSaveString(const AStream: TStream; const AString: UnicodeString;
  AEncoding: TEncoding = nil; AWriteBOM: Boolean = True);
begin
  if AWriteBOM then
    AStream.WriteBOM(AEncoding);
  AStream.WriteString(AString, AEncoding);
end;

procedure acSaveString(const AFileName: string; const AString: UnicodeString;
  AEncoding: TEncoding = nil; AWriteBOM: Boolean = True);
var
  LStream: TStream;
begin
  LStream := StreamCreateWriter(AFileName);
  try
    acSaveString(LStream, AString, AEncoding, AWriteBOM);
  finally
    LStream.Free;
  end;
end;

{$IF DEFINED(FPC) AND NOT DEFINED(UNICODE)}
procedure acSaveString(const AStream: TStream; const AString: string;
  AEncoding: TEncoding = nil; AWriteBOM: Boolean = True);
begin
  if AWriteBOM then
    AStream.WriteBOM(AEncoding);
  {$MESSAGE 'TODO - Utf8 optimization'}
  if AEncoding = TEncoding.UTF8 then
    AStream.WriteStringA(AString)
  else
    AStream.WriteString(AString, AEncoding);
end;

procedure acSaveString(const AFileName: string; const AString: string;
  AEncoding: TEncoding = nil; AWriteBOM: Boolean = True);
var
  LStream: TStream;
begin
  LStream := StreamCreateWriter(AFileName);
  try
    acSaveString(LStream, AString, AEncoding, AWriteBOM);
  finally
    LStream.Free;
  end;
end;
{$IFEND}

// ---------------------------------------------------------------------------------------------------------------------
// Replacing
// ---------------------------------------------------------------------------------------------------------------------

function acStringReplace(const S, OldPattern, NewPattern: string; AIgnoreCase, AWholeWords: Boolean): string;
var
 ALength: Integer;
 AOffset: Integer;
 AOffsetNew: Integer;
 APattern: string;
 ASearchStr: string;
begin
  if AIgnoreCase then
  begin
    APattern := acUpperCase(OldPattern);
    ASearchStr := acUpperCase(S);
  end
  else
  begin
    APattern := OldPattern;
    ASearchStr := S;
  end;

  Result := '';
  AOffset := 1;
  ALength := Length(S);
  while AOffset <= ALength do
  begin
    AOffsetNew := acPos(APattern, ASearchStr, False, AWholeWords, AOffset);
    if AOffsetNew = 0 then
    begin
      if AOffset = 1 then
        Exit(S);
      Result := Result + Copy(S, AOffset, ALength - AOffset + 1);
      Break;
    end;
    Result := Result + Copy(S, AOffset, AOffsetNew - AOffset) + NewPattern;
    AOffset := AOffsetNew + Length(APattern);
  end;
end;

function acRemoveChar(const S: string; ACharToRemove: Char): string;
begin
  if acContains(ACharToRemove, S) then
    Result := acStringReplace(S, ACharToRemove, '')
  else
    Result := S;
end;

function acRemoveDiacritic(const S: string): string;
var
  B: TACLStringBuilder;
  C: WideChar;
  U: UnicodeString;
begin
  B := TACLStringBuilder.Get(Length(S));
  try
    U := acUString(S);
    for C in U do
    begin
      case Word(C) of
        $C0..$C6: B.Append('A');
        $C8..$CB: B.Append('E');
        $CC..$CF: B.Append('I');
        $D2..$D6: B.Append('O');
        $D9..$DC: B.Append('U');
        $E0..$E6: B.Append('a');
        $E8..$EB: B.Append('e');
        $EC..$EF: B.Append('I');
        $F2..$F6: B.Append('o');
        $F9..$FC: B.Append('u');
        $000010D: B.Append('c'); // č
        $0000159: B.Append('r'); // ř
        $000017E: B.Append('z'); // ž
        $0000401: B.Append(#$0415); // Ё
        $0000451: B.Append(#$0435); // ё
      else
        B.Append(C);
      end;
    end;
    Result := B.ToString;
  finally
    B.Release;
  end;
end;

function acRemoveSurrogates(const S: UnicodeString; AReplaceBy: WideChar = #0): UnicodeString;
var
  ABuffer: TACLStringBuilder;
  AHasSurrogates: Boolean;
  AScan: PWideChar;
begin
  AHasSurrogates := False;
  AScan := PWideChar(S);
  while Ord(AScan^) <> 0 do
  begin
    if Ord(AScan^) >= $D800 then
    begin
      AHasSurrogates := True;
      Break;
    end;
    Inc(AScan);
  end;

  if AHasSurrogates then
  begin
    ABuffer := TACLStringBuilder.Get(Length(S));
    try
      AScan := PWideChar(S);
      while Ord(AScan^) <> 0 do
      begin
        if (Ord(AScan^) >= $D800) and (Ord(PWideChar(AScan + 1)^) and $DC00 = $DC00) then
        begin
          if Ord(AReplaceBy) <> 0 then
            ABuffer.Append(AReplaceBy);
          Inc(AScan, 2);
        end
        else
        begin
          ABuffer.Append(AScan^);
          Inc(AScan);
        end;
      end;
      Result := acUString(ABuffer.ToString);
    finally
      ABuffer.Release;
    end;
  end
  else
    Result := S;
end;

function acReplaceChar(const S: string; ACharToReplace, AReplaceBy: Char): string;
var
  P: PChar;
begin
  if ACharToReplace = AReplaceBy then
    Exit(S);
  if not acContains(ACharToReplace, S) then
    Exit(S);

  Result := S;
  UniqueString(Result);
  P := PChar(Result);
  while P^ <> #0 do
  begin
    if P^ = ACharToReplace then
      P^ := AReplaceBy;
    Inc(P);
  end;
end;

function acReplaceChars(const S, ACharsToReplace: string; AReplaceBy: Char = '_'): string;
var
  AChar: Char;
begin
  Result := S;
  for AChar in ACharsToReplace do
    Result := acReplaceChar(Result, AChar, AReplaceBy);
end;

// ---------------------------------------------------------------------------------------------------------------------
// Integer <> PChar
// ---------------------------------------------------------------------------------------------------------------------

function acIsDigit(AChar: Char): Boolean;
begin
  Result :=
  {$IFDEF UNICODE}
    (Ord(AChar) >= $FF10) and (Ord(AChar) <= $FF19) or
  {$ENDIF}
    (Ord(AChar) >= Ord('0')) and (Ord(AChar) <= Ord('9'));
end;

function acTryPCharToInt(AChars: PChar; ACount: Integer; out AValue: Int64): Boolean;
var
  ADigit: Integer;
  ANegative: Boolean;
  AWord: Word;
begin
  if ACount = 0 then
    Exit(False);

  ANegative := AChars^ = '-';
  if ANegative then
  begin
    Inc(AChars);
    Dec(ACount);
    if ACount = 0 then
      Exit(False);
  end;

  AValue := 0;
  while ACount > 0 do
  begin
    AWord := Ord(AChars^);
  {$IFDEF UNICODE}
    if AWord >= $FF10 then // fullwidth numbers
      ADigit := AWord - $FF10
    else
  {$ENDIF}
      ADigit := AWord - Ord('0');

    if (ADigit < 0) or (ADigit > 9) then
      Exit(False);
    AValue := AValue * 10 + ADigit;
    Dec(ACount);
    Inc(AChars);
  end;

  if ANegative then
    AValue := -AValue;
  Result := True;
end;

function acPCharToIntDef(AChars: PChar; ACount: Integer; ADefaultValue: Int64): Int64;
begin
  if not acTryPCharToInt(AChars, ACount, Result) then
    Result := ADefaultValue;
end;

function acDecodeLineBreaks(const S: string): string;
begin
  Result := acStringReplace(S, acLineBreakMacro, sLineBreak);
end;

function acEncodeLineBreaks(const S: string): string;
begin
  Result := acReplaceLineBreaks(S, acLineBreakMacro);
end;

function acRemoveLineBreaks(const S: string): string;
begin
  Result := acReplaceLineBreaks(S, '');
end;

function acReplaceLineBreaks(const S, ReplaceBy: string): string;
begin
  Result := acStringReplace(S, acCRLF, ReplaceBy);
  Result := acStringReplace(Result, #13, ReplaceBy);
  Result := acStringReplace(Result, #10, ReplaceBy);
end;

function IfThenW(ACondition: Boolean; const ATrue, AFalse: string): string;
begin
  if ACondition then
    Result := ATrue
  else
    Result := AFalse;
end;

function IfThenW(const A, B: AnsiString): AnsiString;
begin
  if A = '' then
    Result := B
  else
    Result := A;
end;

function IfThenW(const A, B: UnicodeString): UnicodeString;
begin
  if A = '' then
    Result := B
  else
    Result := A;
end;

function acDupeString(const AText: string; ACount: Integer): string;
var
  ABuffer: TACLStringBuilder;
  ACapacity: Integer;
begin
  ACapacity := Length(AText) * ACount;
  if ACapacity <= 0 then
    Exit('');

  ABuffer := TACLStringBuilder.Get(ACapacity);
  try
    while ACount > 0 do
    begin
      ABuffer.Append(AText);
      Dec(ACount);
    end;
    Result := ABuffer.ToString;
  finally
    ABuffer.Release
  end;
end;

function acTrim(const S: string): string;
var
  I, E, L: Integer;
begin
  I := 1;
  L := Length(S);
  E := L;
  while (I <= E) and (S[I] <= ' ') do
    Inc(I);
  while (E >= I) and (S[E] <= ' ') do
    Dec(E);
  if (I > 1) or (E < L) then
    Result := Copy(S, I, E - I + 1)
  else
    Result := S;
end;

procedure acStrLCopy(ADest: PAnsiChar; const ASource: AnsiString; AMax: Integer);
begin
  FastZeroMem(ADest, AMax);
  FastMove(PAnsiChar(ASource)^, ADest^, Min(AMax, Length(ASource)));
end;

procedure acStrLCopy(ADest: PWideChar; const ASource: UnicodeString; AMax: Integer);
begin
  FastZeroMem(ADest, AMax * SizeOf(WideChar));
  FastMove(PWideChar(ASource)^, ADest^, SizeOf(WideChar) * Min(AMax, Length(ASource)));
end;

function acStrLen(S: PAnsiChar; AMaxScanCount: Integer): Integer;
begin
  Result := 0;
  if S <> nil then
    while (S^ <> #0) and (AMaxScanCount > 0) do
    begin
      Dec(AMaxScanCount);
      Inc(Result);
      Inc(S);
    end;
end;

function acStrLen(S: PWideChar; AMaxScanCount: Integer): Integer;
begin
  Result := 0;
  if S <> nil then
    while (S^ <> #0) and (AMaxScanCount > 0) do
    begin
      Dec(AMaxScanCount);
      Inc(Result);
      Inc(S);
    end;
end;

function acStrScan(Str: PAnsiChar; C: AnsiChar): PAnsiChar;
begin
  Result := Str;
  if Result <> nil then
    while Result^ <> C do
    begin
      if Result^ = #0 then
        Exit(nil);
      Inc(Result);
    end;
end;

function acStrScan(Str: PAnsiChar; ACount: Integer; C: AnsiChar): PAnsiChar; overload; inline;
begin
  Result := Str;
  while (Result <> nil) and (Result^ <> C) do
  begin
    Dec(ACount);
    Inc(Result);
    if ACount <= 0 then
      Exit(nil);
  end;
end;

function acStrScan(Str: PWideChar; C: WideChar): PWideChar;
begin
  Result := Str;
  if Result <> nil then
    while Result^ <> C do
    begin
      if Result^ = #0 then
        Exit(nil);
      Inc(Result);
    end;
end;

function acStrScan(Str: PWideChar; ACount: Integer; C: WideChar): PWideChar;
begin
  Result := Str;
  while (Result <> nil) and (Result^ <> C) do
  begin
    Dec(ACount);
    Inc(Result);
    if ACount <= 0 then
      Exit(nil);
  end;
end;

{ TACLEncodings }

class constructor TACLEncodings.Create;
begin
  FMap := TACLDictionary<Integer, TEncoding>.Create([doOwnsValues]);
  FMapLock := TACLCriticalSection.Create;
end;

class destructor TACLEncodings.Destroy;
begin
  FreeAndNil(FCodePages);
  FreeAndNil(FMapLock);
  FreeAndNil(FMap);
end;

class function TACLEncodings.ASCII: TEncoding;
begin
  try
    Result := TEncoding.ASCII;
  except
    // EEncodingError: Invalid code page
    Result := TEncoding.ANSI;
  end;
end;

class function TACLEncodings.Default: TEncoding;
begin
  Result := Get(DefaultCodePage);
end;

class procedure TACLEncodings.EnumAnsiCodePages(const AProc: TProc<Integer, string>);
var
  I: Integer;
begin
  if FCodePages = nil then
  begin
    FCodePages := TACLStringList.Create;
  {$IFDEF FPC}
    TACLStringList(FCodePages).Add('windows-1250', 1250);
    TACLStringList(FCodePages).Add('windows-1251', 1251);
    TACLStringList(FCodePages).Add('windows-1252', 1252);
    TACLStringList(FCodePages).Add('windows-1253', 1253);
    TACLStringList(FCodePages).Add('windows-1254', 1254);
    TACLStringList(FCodePages).Add('windows-1255', 1255);
    TACLStringList(FCodePages).Add('windows-1256', 1256);
    TACLStringList(FCodePages).Add('windows-1257', 1257);
    TACLStringList(FCodePages).Add('windows-1258', 1258);
  {$ELSE}
    EnumSystemCodePagesW(@CodePageEnumProc, CP_INSTALLED);
  {$ENDIF}
    TACLStringList(FCodePages).SortLogical;
    TACLStringList(FCodePages).Insert(0, 'Default', TObject(CP_ACP));
  end;
  for I := 0 to TACLStringList(FCodePages).Count - 1 do
    AProc(Integer(TACLStringList(FCodePages).Objects[I]), TACLStringList(FCodePages).Strings[I]);
end;

class function TACLEncodings.Get(const CodePage: Integer): TEncoding;
var
  AMap: TACLDictionary<Integer, TEncoding>;
begin
  if (CodePage = 0) or (CodePage = CP_ACP) then
    Exit(TEncoding.Default);
  AMap := TACLDictionary<Integer, TEncoding>(FMap);
  if not AMap.TryGetValue(CodePage, Result) then
  begin
    FMapLock.Enter;
    try
      if not AMap.TryGetValue(CodePage, Result) then
      begin
        Result := TEncoding.GetEncoding(CodePage);
        AMap.Add(CodePage, Result)
      end;
    finally
      FMapLock.Leave;
    end;
  end;
end;

class function TACLEncodings.Get(const Name: string): TEncoding;
begin
  if acSameText(Name, 'utf-8') then
    Exit(TEncoding.UTF8);
{$IFDEF FPC}
  Result := Get(CodePageNameToCodePage(Name));
{$ELSE}
  // По-хорошему, надо бы тут использовать GetCodePageFromEncodingName, но она спрятана в SysUtils.
  // Пока используем такой вот костыльный подход.
  // TODO: сделать свой аналог GetCodePageFromEncodingName
  with TEncoding.GetEncoding(Name) do
  try
    Result := Get(CodePage);
  finally
    Free;
  end;
{$ENDIF}
end;

class function TACLEncodings.WebName(const Encoding: TEncoding): string;
var
  AStartPos: Integer;
begin
  Result := acString(Encoding.EncodingName);
  AStartPos := acPos('(', Result) + 1;
  if AStartPos > 1 then
    Result := Copy(Result, AStartPos, acPos(')', Result) - AStartPos);
  Result := acLowerCase(Result);
end;

{$IFDEF MSWINDOWS}
class function TACLEncodings.CodePageEnumProc(lpCodePageString: PWideChar): Cardinal; stdcall;
var
  LCodePage: Integer;
  LCodePageInfo: TCPInfoEx;
begin
  LCodePage := StrToIntDef(lpCodePageString, -1);
  if (LCodePage > 0) and GetCPInfoEx(LCodePage, 0, LCodePageInfo) then
    TACLStringList(FCodePages).Add(LCodePageInfo.CodePageName, LCodePage);
  Result := 1;
end;
{$ENDIF}

{ TACLTimeFormat }

class function TACLTimeFormat.Format(const ATimeInMilliSeconds: Int64;
  AParts: TACLFormatTimeParts; ASuppressZeroValues: Boolean): string;
begin
  Result := FormatEx(ATimeInMilliSeconds / 1000, AParts, ':', ASuppressZeroValues);
end;

class function TACLTimeFormat.FormatEx(ATimeInSeconds: Single;
  AParts: TACLFormatTimeParts; ASuppressZeroValues: Boolean): string;
begin
  Result := FormatEx(ATimeInSeconds, AParts, ':', ASuppressZeroValues);
end;

class function TACLTimeFormat.FormatEx(ATimeInSeconds: Single;
  AParts: TACLFormatTimeParts; const APartDelimiter: string;
  ASuppressZeroValues: Boolean): string;

  procedure AppendResult(ABuffer: TACLStringBuilder; const APartDelimiter, AValue: string); inline;
  begin
    if ABuffer.Length > 0 then
      ABuffer.Append(APartDelimiter);
    ABuffer.Append(AValue);
  end;

  function FormatPart(APartValue: Integer; ASuppressZeroValues: Boolean; APart: TACLFormatTimePart): string; inline;
  begin
    if (APartValue = 0) and ASuppressZeroValues and (APart > ftpMinutes) then
      Result := EmptyStr
    else if (APartValue > 9) or ASuppressZeroValues then
      Result := IntToStr(APartValue)
    else
      Result := '0' + IntToStr(APartValue);
  end;

  procedure UpTo(var AValue: Single; ADivFactor: Integer); inline;
  begin
    AValue := Ceil(AValue / ADivFactor) * ADivFactor;
  end;

  function Split(var AValue: Single; ADivFactor: Integer): Integer; inline;
  begin
    Result := Trunc(AValue / ADivFactor);
    AValue := AValue - Result * ADivFactor;
  end;

const
  Factors: array[TACLFormatTimePart] of Integer = (1, 1, SecsPerMin, SecsPerHour, SecsPerDay);
var
  ABuffer: TACLStringBuilder;
  AHasSign: Boolean;
  APart: TACLFormatTimePart;
begin
  AHasSign := ATimeInSeconds < 0;
  ATimeInSeconds := Abs(ATimeInSeconds);

  // Rounding
  for APart := Low(TACLFormatTimePart) to ftpHours do
  begin
    if APart in AParts then
      Break
    else
      UpTo(ATimeInSeconds, Factors[TACLFormatTimePart(Ord(APart) + 1)]);
  end;

  // format
  ABuffer := TACLStringBuilder.Get(16);
  try
    for APart := High(TACLFormatTimePart) downto ftpSeconds do
    begin
      if APart in AParts then
        AppendResult(ABuffer, APartDelimiter,
          FormatPart(Split(ATimeInSeconds, Factors[APart]),
          ASuppressZeroValues and (ABuffer.Length = 0), APart));
    end;
    if ftpMilliSeconds in AParts then
      AppendResult(ABuffer, '.', FormatFloat('000', ATimeInSeconds * 1000));
    if AHasSign and (ABuffer.Length > 0) then
      ABuffer.Insert(0, '-');

    Result := ABuffer.ToString;
  finally
    ABuffer.Release;
  end;
end;

class function TACLTimeFormat.FormatEx(
  ATimeInSeconds: Single; const AFormatString: string): string;

  function GetPartValue(var AParts: TStringDynArray;
    AIndex: Integer; const ADefaultValue: string = ''): string;
  begin
    if (AIndex >= 0) and (AIndex < Length(AParts)) then
      Result := AParts[AIndex]
    else
      Result := ADefaultValue;
  end;

  function GetTimeParts(const S: string): TACLFormatTimeParts;
  const
    Map: array[TACLFormatTimePart] of Char = ('Z', 'S', 'M', 'H', 'D');
  var
    APart: TACLFormatTimePart;
  begin
    Result := [];
    for APart := Low(TACLFormatTimePart) to High(TACLFormatTimePart) do
    begin
      if acContains(Map[APart], S) then
        Include(Result, APart);
    end;
  end;

var
  AParts: TStringDynArray;
begin
  acExplodeString(AFormatString, ';', AParts);
  Result := FormatEx(ATimeInSeconds, GetTimeParts(GetPartValue(AParts, 0)),
    GetPartValue(AParts, 1, ':'), acContains('Z', GetPartValue(AParts, 2)));
end;

class function TACLTimeFormat.FormatEx(ATimeInSeconds: Single): string;
var
  LParts: TACLFormatTimeParts;
begin
  LParts := [ftpSeconds, ftpMinutes];
  if ATimeInSeconds >= 3600 then
    Include(LParts, ftpHours);
  if ATimeInSeconds >= 86400 then
    Include(LParts, ftpDays);
  Result := FormatEx(ATimeInSeconds, LParts, True);
end;

class function TACLTimeFormat.Parse(var Scan: PChar; out ATimeInSeconds: Single): Boolean;
const
  Digits = ['0'..'9'];
var
  ACurr, ACurr2: PChar;
  AMillis: Int64;
begin
  if not CharInSet(Scan^, Digits) then
    Exit(False);

  // [h]h or [m]m
  ACurr := Scan + 1;
  ATimeInSeconds := Ord(Scan^) - Ord('0');
  if CharInSet(ACurr^, Digits) then
  begin
    ATimeInSeconds := ATimeInSeconds * 10 + Ord(ACurr^) - Ord('0');
    Inc(ACurr);
  end;
  if ACurr^ <> ':' then
    Exit(False);

  // mm or ss
  if CharInSet((ACurr + 1)^, Digits) and CharInSet((ACurr + 2)^, Digits) then
  begin
    ATimeInSeconds := ATimeInSeconds * 60 +
      (Ord((ACurr + 1)^) - Ord('0')) * 10 +
      (Ord((ACurr + 2)^) - Ord('0'));
    Inc(ACurr, 3);
  end
  else
    Exit(False);

  // ss
  if ACurr^ = ':' then
  begin
    if CharInSet((ACurr + 1)^, Digits) and CharInSet((ACurr + 2)^, Digits) then
    begin
      ATimeInSeconds := ATimeInSeconds * 60 +
        (Ord((ACurr + 1)^) - Ord('0')) * 10 +
        (Ord((ACurr + 2)^) - Ord('0'));
      Inc(ACurr, 3);
    end
    else
      Exit(False);
  end;

  // milliseconds
  if ACurr^ = '.' then
  begin
    Inc(ACurr);
    ACurr2 := ACurr;
    while CharInSet(ACurr2^, Digits) do
      Inc(ACurr2);
    if acTryPCharToInt(ACurr, acStringLength(ACurr, ACurr2), AMillis) then
    begin
      if AMillis > 0 then
        ATimeInSeconds := ATimeInSeconds + AMillis / 1000;
      ACurr := ACurr2;
    end
    else
      Exit(False);
  end;

  Result := (ACurr^ <= ' ') or CharInSet(ACurr^, BracketsOut);
  if Result then
    Scan := ACurr;
end;

class function TACLTimeFormat.Parse(const S: string; out ATimeInSeconds: Single): Boolean;
var
  P: PChar;
begin
  P := PChar(S);
  while (P^ <> #0) and (P^ <= ' ') do
    Inc(P);
  Result := Parse(P, ATimeInSeconds);
end;

{ TACLSearchString }

constructor TACLSearchString.Create;
begin
  inherited Create;
  FLock := TACLCriticalSection.Create;
  FEmpty := True;
  FIgnoreCase := True;
  FIgnoreDiacritic := True;
  FSeparator := ' ';
end;

constructor TACLSearchString.Create(const AMask: string; AIgnoreCase: Boolean = True);
begin
  Create;
  IgnoreCase := AIgnoreCase;
  Value := AMask;
end;

destructor TACLSearchString.Destroy;
begin
  FreeAndNil(FLock);
  inherited Destroy;
end;

function TACLSearchString.Compare(const S: string): Boolean;
begin
  BeginComparing;
  AddToCompare(S);
  Result := EndComparing;
end;

procedure TACLSearchString.BeginComparing;
var
  I: Integer;
begin
  FLock.Enter;
  for I := 0 to Length(FMaskResult) - 1 do
    FMaskResult[I] := False;
end;

procedure TACLSearchString.AddToCompare(S: string);
var
  ACur: Integer;
  AMask: string;
  AScan: PByte;
  ASize: Integer;
  I: Integer;
begin
  S := PrepareString(S);
  UniqueString(S);
  AScan := PByte(@S[1]);
  ASize := Length(S) * SizeOf(Char);
  for I := 0 to Length(FMask) - 1 do
  begin
    if not FMaskResult[I] then
    begin
      AMask := FMask[I];
    {$IFDEF UNICODE}
      if acFindStringInMemoryW(AMask, AScan, ASize, 0, ACur) then
    {$ELSE}
      if acFindStringInMemoryA(AMask, AScan, ASize, 0, ACur) then
    {$ENDIF}
      begin
        FastZeroMem(AScan + ACur, Length(AMask) * SizeOf(Char));
        FMaskResult[I] := True;
      end
      else
        FMaskResult[I] := AMask = '';
    end;
  end;
end;

function TACLSearchString.EndComparing: Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to Length(FMaskResult) - 1 do
    Result := Result and FMaskResult[I];
  FLock.Leave;
end;

function TACLSearchString.GetValueIsNumeric: Boolean;
var
  X: Integer;
begin
  Result := TryStrToInt(Value, X);
end;

function TACLSearchString.PrepareString(const AValue: string): string;
begin
  Result := AValue;
  if IgnoreDiacritic then
    Result := acRemoveDiacritic(Result);
  if IgnoreCase then
    Result := acUpperCase(Result);
end;

procedure TACLSearchString.SetIgnoreCase(const AValue: Boolean);
begin
  if FIgnoreCase <> AValue then
  begin
    FIgnoreCase := AValue;
    Value := Value;
  end;
end;

procedure TACLSearchString.SetValue(AValue: string);
begin
  FLock.Enter;
  try
    FValue := AValue;
    FEmpty := AValue = '';
    if Empty then
    begin
      SetLength(FMask, 0);
      SetLength(FMaskResult, 0);
    end
    else
    begin
      if acUnquot(AValue) then
      begin
        SetLength(FMask, 1);
        FMask[0] := PrepareString(AValue);
      end
      else
        acExplodeString(PrepareString(AValue), Separator, FMask);

      SetLength(FMaskResult, Length(FMask));
    end;
  finally
    FLock.Leave;
  end;
end;

{ TACLLCSCalculator }

class function TACLLCSCalculator.Compliance(const ASource, ATarget: string): Single;
var
  AEqualsCount: Integer;
  ASourceLength, ATargetLength: Integer;
begin
  ASourceLength := Length(ASource);
  ATargetLength := Length(ATarget);
  if (ASourceLength = 0) and (ATargetLength = 0) then
    Exit(1);

  AEqualsCount := 0;
  Difference(ASourceLength, ATargetLength,
    function (ASourceIndex, ATargetIndex: Integer): Boolean
    begin
      Result :=
        acLowerCase(ASource[ASourceIndex + 1]) =
        acLowerCase(ATarget[ATargetIndex + 1]);
    end,
    procedure ({%H-}AIndex: Integer; AState: TDiffState)
    begin
      if AState = tsEquals then
        Inc(AEqualsCount);
    end,
    DefaultEqualsNearbyChars
  );
  Result := AEqualsCount / Max(ASourceLength, ATargetLength);
end;

class function TACLLCSCalculator.Compliance(const ASource, ATarget: TStrings): Single;
var
  AEqualsCount: Integer;
  ASourceLength, ATargetLength: Integer;
begin
  ASourceLength := ASource.Count;
  ATargetLength := ATarget.Count;
  if (ASourceLength = 0) and (ATargetLength = 0) then
    Exit(1);

  AEqualsCount := 0;
  Difference(ASourceLength, ATargetLength,
    function (ASourceIndex, ATargetIndex: Integer): Boolean
    begin
      Result := SameText(ASource[ASourceIndex], ATarget[ATargetIndex]);
    end,
    procedure ({%H-}AIndex: Integer; AState: TDiffState)
    begin
      if AState = tsEquals then
        Inc(AEqualsCount);
    end,
    DefaultEqualsNearbyChars
  );
  Result := AEqualsCount / Max(ASourceLength, ATargetLength);
end;

class function TACLLCSCalculator.Difference(const ASource, ATarget: string): TList<TStringDiff>;
var
  ADifferences: TList<TStringDiff>;
  ASourceLength, ATargetLength: Integer;
begin
  ASourceLength := Length(ASource);
  ATargetLength := Length(ATarget);

  ADifferences := TList<TStringDiff>.Create;
  ADifferences.Capacity := Max(ASourceLength, ATargetLength);

  Difference(ASourceLength, ATargetLength,
    function (ASourceIndex, ATargetIndex: Integer): Boolean
    begin
      Result := ASource[ASourceIndex + 1] = ATarget[ATargetIndex + 1];
    end,
    procedure (AIndex: Integer; AState: TDiffState)
    var
      AChar: Char;
    begin
      if AState = tsInserted then
        AChar := ATarget[AIndex + 1]
      else
        AChar := ASource[AIndex + 1];

      ADifferences.Add(TStringDiff.Create(AChar, AState));
    end,
    DefaultEqualsNearbyChars
  );
  Result := ADifferences;
end;

class procedure TACLLCSCalculator.Difference(const ASourceLength, ATargetLength: Integer;
  const ACompareProc: TDiffCompareProc; const AResultProc: TDiffResultProc; const AEqualsNearbyTokens: Integer);
type
  TDiffMatrix = array of array of Integer;

  function CreateMatrix: TDiffMatrix;
  var
    S, T: Integer;
  begin
    SetLength(Result{%H-}, ASourceLength + 1, ATargetLength + 1);
    for S := 0 to ASourceLength do
      Result[S, 0] := 0;
    for T := 0 to ATargetLength do
      Result[0, T] := 0;
    for S := 1 to ASourceLength do
      for T := 1 to ATargetLength do
      begin
        if ACompareProc(S - 1, T - 1) then
          Result[S, T] := Result[S - 1, T - 1] + 1
        else
          Result[S, T] := Max(Result[S, T - 1], Result[S - 1, T]);
      end;
  end;

  function CheckEquals(S, T: Integer): Boolean;

    procedure CheckNeighbors(S, T, ADelta: Integer; var AResult: Integer);
    begin
      while (AResult < AEqualsNearbyTokens) and InRange(S, 1, ASourceLength) and InRange(T, 1, ATargetLength) and ACompareProc(S - 1, T - 1) do
      begin
        Inc(S, ADelta);
        Inc(T, ADelta);
        Inc(AResult);
      end;
    end;

  var
    AEquals: Integer;
  begin
    Result := ACompareProc(S - 1, T - 1);
    if Result and (AEqualsNearbyTokens > 1) then
    begin
      AEquals := 1;
      CheckNeighbors(S + 1, T + 1, 1, AEquals);
      CheckNeighbors(S - 1, T - 1, -1, AEquals);
      Result := AEquals >= AEqualsNearbyTokens;
    end;
  end;

  procedure ComputeDifferences(const AMatrix: TDiffMatrix; S, T: Integer);
  begin
    if (S > 0) and (T > 0) and CheckEquals(S, T) then
    begin
      ComputeDifferences(AMatrix, S - 1, T - 1);
      AResultProc(S - 1, tsEquals);
    end
    else

    if (T > 0) and ((S = 0) or (AMatrix[S, T - 1] >= AMatrix[S - 1, T])) then
    begin
      ComputeDifferences(AMatrix, S, T - 1);
      AResultProc(T - 1, tsInserted);
    end
    else

    if (S > 0) and ((T = 0) or (AMatrix[S, T - 1] < AMatrix[S - 1, T])) then
    begin
      ComputeDifferences(AMatrix, S - 1, T);
      AResultProc(S - 1, tsDeleted);
    end;
  end;

begin
  ComputeDifferences(CreateMatrix, ASourceLength, ATargetLength);
end;

{ TACLStringBuilder }

constructor TACLStringBuilder.Create(ACapacity: Integer);
begin
  Capacity := ACapacity;
end;

class destructor TACLStringBuilder.Finalize;
var
  I: Integer;
begin
  for I := 0 to CacheSize - 1 do
    FreeAndNil(Cache[I]);
end;

class function TACLStringBuilder.Get(ACapacity: Integer): TACLStringBuilder;
var
  AIndex: Integer;
begin
  AIndex := 0;
  Result := nil;
  while (Result = nil) and (AIndex < CacheSize) do
  begin
    Result := AtomicExchange(Pointer(Cache[AIndex]), nil);
    Inc(AIndex);
  end;

  if Result <> nil then
  begin
    Result.Length := 0; // first
    Result.Capacity := ACapacity;
  end
  else
    Result := TACLStringBuilder.Create(ACapacity);
end;

function TACLStringBuilder.Append(const AValue: PChar; ALength: Integer): TACLStringBuilder;
var
  ANewLength: Integer;
begin
  if ALength > 0 then
  begin
    ANewLength := FDataLength + ALength;
    if ANewLength > Capacity then
      GrowCapacity(ANewLength);
    FastMove(AValue^, FData[FDataLength], ALength * SizeOf(Char));
    FDataLength := ANewLength;
  end;
  Result := Self;
end;

function TACLStringBuilder.Append(const AValue: string): TACLStringBuilder;
begin
  Result := Append(PChar(AValue), System.Length(AValue));
end;

function TACLStringBuilder.Append(const AValue: AnsiChar): TACLStringBuilder;
begin
  if FDataLength = Capacity then
    GrowCapacity(FDataLength + 1);
  FData[FDataLength] := Char(AValue);
  Inc(FDataLength);
  Result := Self;
end;

function TACLStringBuilder.Append(const AValue: WideChar): TACLStringBuilder;
begin
{$IF DEFINED(UNICODE)}
  if FDataLength = Capacity then
    GrowCapacity(FDataLength + 1);
  FData[FDataLength] := AValue;
  Inc(FDataLength);
  Result := Self;
{$ELSEIF DEFINED(FPC)}
  Result := Append(acString(AValue));
{$ELSE}
  Result := Append(AnsiChar(AValue));
{$ENDIF}
end;

function TACLStringBuilder.Append(const AValue: string; AStartIndex, ACount: Integer): TACLStringBuilder;
begin
  if ACount < 0 then
    ACount := System.Length(AValue) - AStartIndex;
  if AStartIndex + ACount > System.Length(AValue) then
    raise ERangeError.CreateResFmt(@SListIndexError, [AStartIndex]);
  if AStartIndex < 0 then
    raise ERangeError.CreateResFmt(@SListIndexError, [AStartIndex]);
  if ACount > 0 then
    Append(@AValue[AStartIndex + Low(string)], ACount);
  Result := Self;
end;

function TACLStringBuilder.AppendLine: TACLStringBuilder;
begin
  Result := Append(sLineBreak);
end;

function TACLStringBuilder.Insert(AIndex: Integer; const AValue: string): TACLStringBuilder;
var
  ALength: Integer;
begin
  if AIndex < 0 then
    raise ERangeError.CreateResFmt(@SParamIsNegative, ['Index']); // DO NOT LOCALIZE
  if AIndex > Length then
    raise ERangeError.CreateResFmt(@SListIndexError, [AIndex]);
  ALength := System.Length(AValue);
  if ALength > 0 then
  begin
    if FDataLength > AIndex then
      FastMove(FData[AIndex], FData[AIndex + ALength], (FDataLength - AIndex) * SizeOf(WideChar));
    FastMove(AValue[Low(string)], FData[AIndex], ALength * SizeOf(WideChar));
    Inc(FDataLength, ALength);
  end;
  Result := Self;
end;

procedure TACLStringBuilder.GrowCapacity(ACountNeeded: Integer);
var
  ANewCapacity: Integer;
begin
  ANewCapacity := (Capacity * 3) div 2;
  if ANewCapacity < ACountNeeded then
    ANewCapacity := ACountNeeded * 2; // this line may overflow ANewCapacity to a negative value
  if ANewCapacity < 0 then // if ANewCapacity has been overflowed
    ANewCapacity := ACountNeeded;
  Capacity := ANewCapacity;
end;

procedure TACLStringBuilder.Release;
var
  ABuilder: TACLStringBuilder;
  AIndex: Integer;
begin
  ABuilder := Self;
  if ABuilder.Capacity < HugeCapacityThreshold then
  begin
    AIndex := 0;
    while (ABuilder <> nil) and (AIndex < CacheSize) do
    begin
      ABuilder := AtomicExchange(Pointer(Cache[AIndex]), Pointer(ABuilder));
      Inc(AIndex);
    end;
  end;
  FreeAndNil(ABuilder);
end;

procedure TACLStringBuilder.SetCapacity(AValue: Integer);
begin
  if AValue <> Capacity then
  begin
    if AValue < Length then
      raise ERangeError.CreateResFmt(@SListCapacityError, [AValue]);
    FCapacity := AValue;
    SetLength(FData, Capacity);
  end;
end;

procedure TACLStringBuilder.SetDataLength(AValue: Integer);
begin
  // Keep the order
  if AValue < 0 then
    raise ERangeError.CreateResFmt(@SParamIsNegative, ['Value']);
  if AValue > Capacity then
    GrowCapacity(AValue);
  FDataLength := AValue;
end;

function TACLStringBuilder.ToString: string;
begin
  if Length > 0 then
    SetString(Result, PChar(@FData[0]), Length)
  else
    Result := '';
end;

function TACLStringBuilder.ToTrimmedString: string;
var
  S, L: Integer;
begin
  S := 0;
  L := FDataLength - 1;
  while (S <= L) and (FData[S] <= ' ') do
    Inc(S);
  while (L >= 1) and (FData[L] <= ' ') do
    Dec(L);
  Result := ToString(S, L - S + 1);
end;

function TACLStringBuilder.ToString(AStartIndex, ACount: Integer): string;
begin
  if ACount = 0 then
    Exit(acEmptyStr);
  if ACount < 0 then
    raise ERangeError.CreateResFmt(@SParamIsNegative, ['ACount']);
  if not InRange(AStartIndex, 0, FDataLength - 1) then
    raise ERangeError.CreateResFmt(@SListIndexError, [AStartIndex]);
  if not InRange(AStartIndex + ACount, 0, FDataLength) then
    raise ERangeError.CreateResFmt(@SListIndexError, [AStartIndex + ACount - 1]);
  SetString(Result, PChar(@FData[AStartIndex]), ACount);
end;

function TACLStringBuilder.Append(const AValue: Currency): TACLStringBuilder;
begin
  Result := Append(CurrToStr(AValue));
end;

function TACLStringBuilder.Append(const AValue: Double): TACLStringBuilder;
begin
  Result := Append(FloatToStr(AValue));
end;

function TACLStringBuilder.Append(const AValue: Int64): TACLStringBuilder;
begin
  Result := Append(IntToStr(AValue));
end;

function TACLStringBuilder.Append(const AValue: Boolean): TACLStringBuilder;
begin
  Result := Append(BoolToStr(AValue, True));
end;

function TACLStringBuilder.Append(const AValue: Byte): TACLStringBuilder;
begin
  Result := Append(IntToStr(AValue));
end;

function TACLStringBuilder.Append(const AValue: Cardinal): TACLStringBuilder;
begin
  Result := Append(UIntToStr(AValue));
end;

function TACLStringBuilder.Append(const AValue: Integer): TACLStringBuilder;
begin
  Result := Append(IntToStr(AValue));
end;

function TACLStringBuilder.Append(const AValue: TObject): TACLStringBuilder;
begin
  Result := Append(AValue.ToString);
end;

function TACLStringBuilder.Append(const AValue: UInt64): TACLStringBuilder;
begin
  Result := Append(UIntToStr(AValue));
end;

function TACLStringBuilder.Append(const AValue: Word): TACLStringBuilder;
begin
  Result := Append(IntToStr(AValue));
end;

function TACLStringBuilder.AppendFormat(const AFormat: string; const AArgs: array of const): TACLStringBuilder;
begin
  Result := Append(Format(AFormat, AArgs));
end;

function TACLStringBuilder.AppendLine(const AValue: string): TACLStringBuilder;
begin
  Result := Append(AValue).AppendLine;
end;

function TACLStringBuilder.Append(const AValue: Shortint): TACLStringBuilder;
begin
  Result := Append(IntToStr(AValue));
end;

function TACLStringBuilder.Append(const AValue: Single): TACLStringBuilder;
begin
  Result := Append(FloatToStr(AValue));
end;

function TACLStringBuilder.Append(const AValue: Smallint): TACLStringBuilder;
begin
  Result := Append(IntToStr(AValue));
end;

function TACLStringBuilder.Append(const AValue: TArray<AnsiChar>; AStartIndex, ACount: Integer): TACLStringBuilder;
begin
{$IFDEF UNICODE}
  Result := Append(acUStringFromAnsiString(PAnsiChar(@AValue[AStartIndex]), ACount, DefaultCodePage));
{$ELSE}
  Result := Append(@AValue[AStartIndex], ACount);
{$ENDIF}
end;

function TACLStringBuilder.Append(const AValue: TArray<WideChar>; AStartIndex, ACount: Integer): TACLStringBuilder;
begin
{$IFDEF UNICODE}
  Result := Append(@AValue[AStartIndex], ACount);
{$ELSE}
  Result := Append(acString(acMakeString(PWideChar(@AValue[AStartIndex]), ACount)));
{$ENDIF}
end;

{ TACLAppVersion }

class function TACLAppVersion.Create(AVersion, ABuildNumber: Integer;
  const ABuildSuffix: string; ABuildDate: TDateTime): TACLAppVersion;
begin
  if ABuildDate = TACLAppVersion.DateTimeNow then
    ABuildDate := Now;
  Result.BuildDate := ABuildDate;
  Result.BuildNumber := ABuildNumber;
  Result.BuildSuffix := ABuildSuffix;

  Result.MajorVersion := AVersion div 1000;
  AVersion := AVersion mod 1000;
  Result.MinorVersion1 := AVersion div 100;
  AVersion := AVersion mod 100;
  Result.MinorVersion2 := AVersion div 10;
end;

class function TACLAppVersion.FormatBuildDate(const ADate: TDateTime): string;
begin
  Result := FormatDateTime('(dd.MM.yyyy)', ADate);
end;

function TACLAppVersion.ID: Integer;
begin
  Result := MajorVersion * 1000 + MinorVersion1 * 100 + MinorVersion2 * 10;
end;

function TACLAppVersion.ToDisplayString: string;
begin
  Result := 'v' + ToString;
  if BuildDate > 0 then
    Result := Result + ' ' + FormatBuildDate(BuildDate);
end;

function TACLAppVersion.ToScriptString: string;
var
  ABuffer: TACLStringBuilder;
begin
  ABuffer := TACLStringBuilder.Get;
  try
    ABuffer.Append(MajorVersion);
    ABuffer.Append('.');
    ABuffer.Append(MinorVersion1);
    ABuffer.Append('.');
    ABuffer.Append(MinorVersion2);
    ABuffer.Append('.');
    ABuffer.Append(BuildNumber);
    Result := ABuffer.ToString;
  finally
    ABuffer.Release;
  end;
end;

function TACLAppVersion.ToString: string;
var
  ABuffer: TACLStringBuilder;
begin
  ABuffer := TACLStringBuilder.Get;
  try
    ABuffer.Append(MajorVersion);
    ABuffer.Append('.');
    ABuffer.Append(MinorVersion1);
    ABuffer.Append(MinorVersion2);
    if BuildNumber > 0 then
      ABuffer.Append('.').Append(BuildNumber);
    if BuildSuffix <> '' then
      ABuffer.Append(' ').Append(BuildSuffix);
    Result := ABuffer.ToString;
  finally
    ABuffer.Release
  end;
end;

{ TACLHexcode }

class constructor TACLHexcode.Create;
var
  B: Byte;
begin
  for B := Low(Byte) to High(Byte) do
    FByteToHexMap[B] := Map[B shr 4] + Map[B and $F];
end;

class function TACLHexcode.Decode(const AChar1, AChar2: Char): Byte;
begin
  if not Decode(AChar1, AChar2, Result) then
    Result := 0;
end;

class function TACLHexcode.Decode(const AChar1, AChar2: Char; out AValue: Byte): Boolean;
var
  X1, X2: Byte;
begin
  Result := Decode(AChar1, X1) and Decode(AChar2, X2);
  if Result then
    AValue := X1 shl 4 or X2;
end;

class function TACLHexcode.Decode(const ACode: string; AStream: TStream): Boolean;
var
  B: Byte;
  L: Integer;
  P: Int64;
  W: PChar;
begin
  Result := False;
  if (AStream <> nil) and (ACode <> '') then
  begin
    W := @ACode[1];
    L := Length(ACode);
    if L mod 2 = 0 then
    begin
      L := L div 2;
      P := AStream.Position;
      AStream.Size := Max(AStream.Size, P + L);
      AStream.Position := P;
      while L > 0 do
      begin
        if Decode(W^, (W + 1)^, B) then
          AStream.WriteBuffer(B, SizeOf(B))
        else
        begin
          AStream.Position := P;
          AStream.Size := P;
          Exit(False);
        end;
        Inc(W, 2);
        Dec(L);
      end;
      Result := True;
    end;
  end;
end;

class function TACLHexcode.Decode(const AChar1: Char; out AValue: Byte): Boolean;
begin
  Result := True;
  case AChar1 of
    '0'..'9':
      AValue := Ord(AChar1) - Ord('0');
    'A'..'F':
      AValue := Ord(AChar1) - Ord('A') + 10;
    'a'..'f':
      AValue := Ord(AChar1) - Ord('a') + 10;
  else
    Result := False;
  end;
end;

class function TACLHexcode.DecodeString(const ACode: string): UnicodeString;
var
  AStream: TBytesStream;
begin
  AStream := TBytesStream.Create;
  try
    AStream.Size := Length(ACode) div 2;
    Decode(ACode, AStream);
    Result := TEncoding.UTF8.GetString(AStream.Bytes);
  finally
    AStream.Free;
  end;
end;

class function TACLHexcode.Encode(ABuffer: PByte; ACount: Integer): string;
var
  AScan: PChar;
begin
  System.SetString(Result, nil, 2 * ACount);
  AScan := @Result[1];
  while ACount > 0 do
  begin
    AScan^ := Map[ABuffer^ shr 4];
    Inc(AScan);
    AScan^ := Map[ABuffer^ and $F];
    Inc(ABuffer);
    Inc(AScan);
    Dec(ACount);
  end;
end;

class function TACLHexcode.Encode(AStream: TStream): string;
var
  B: PByte;
  L: Integer;
begin
  if AStream is TMemoryStream then
    Result := Encode(TMemoryStream(AStream).Memory, AStream.Size)
  else
  begin
    L := AStream.Size;
    B := AllocMem(L);
    try
      AStream.Position := 0;
      AStream.ReadBuffer(B^, L);
      Result := Encode(B, L);
    finally
      FreeMem(B, L);
    end;
  end;
end;

class function TACLHexcode.Encode(AByte: Byte): string;
begin
  Result := FByteToHexMap[AByte];
end;

class function TACLHexcode.Encode(AChar: WideChar): string;
begin
  Result := FByteToHexMap[Ord(AChar) shr 8] + FByteToHexMap[Ord(AChar) and $FF];
end;

class function TACLHexcode.Encode(AChar: WideChar; ABuffer: PWideChar): PWideChar;
var
  AScan: PCardinal absolute ABuffer;
begin
  AScan^ := PCardinal(FByteToHexMap[Ord(AChar) shr 8])^;
  Inc(AScan);
  AScan^ := PCardinal(FByteToHexMap[Ord(AChar) and $FF])^;
  Inc(AScan);
  Result := ABuffer;
end;

class function TACLHexcode.Encode(AChar: AnsiChar): string;
begin
  Result := FByteToHexMap[Ord(AChar)];
end;

class function TACLHexcode.EncodeFile(const AFileName: string): string;
var
  AStream: TStream;
begin
  AStream := TACLFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Result := Encode(AStream);
  finally
    AStream.Free;
  end;
end;

class function TACLHexcode.EncodeString(const AValue: AnsiString): string;
begin
  Result := Encode(PByte(PAnsiChar(AValue)), Length(AValue));
end;

class function TACLHexcode.EncodeString(const AValue: UnicodeString): string;
var
  ABytes: TBytes;
begin
  ABytes := TEncoding.UTF8.GetBytes(AValue);
  Result := Encode(@ABytes[0], Length(ABytes));
end;

{ TACLMimecode }

class function TACLMimecode.Decode(ASrc: PByte; ASrcSize: Integer; AStream: TStream): Integer;

  function CalcDiscardValue(ASrc: PByteArray; ASrcSize: Integer): Integer;
  begin
    if (ASrcSize > 1) and (ASrc^[ASrcSize - 2] = PadByte) then
      Result := 2 * Ord(ASrc^[ASrcSize - 1] = PadByte)
    else
      if ASrcSize > 0 then
        Result := Ord(ASrc^[ASrcSize - 1] = PadByte)
      else
        Result := 0;
  end;

  function CheckCodeAlphabetic(ASrc: PByte; ASrcSize: Integer): Boolean;
  begin
    Result := True;
    while (ASrcSize > 0) and Result do
    begin
      Result := Result and (DecodeTable[ASrc^] <> $FF);
      Dec(ASrcSize);
      Inc(ASrc);
    end;
  end;

var
  AData, X: Integer;
  ADataBytes: array[0..3] of Byte absolute AData;
  ADiscard: Integer;
begin
  Result := -1;
  if CheckCodeAlphabetic(ASrc, ASrcSize) then
  begin
    Result := 0;
    ADiscard := CalcDiscardValue(PByteArray(ASrc), ASrcSize);
    Dec(ASrcSize, ADiscard);
    while ASrcSize > 0 do
    begin
      AData := DecodeTable[ASrc^] shl 18;
      Inc(ASrc);
      AData := AData or DecodeTable[ASrc^] shl 12;
      Inc(ASrc);
      AData := AData or DecodeTable[ASrc^] shl 6;
      Inc(ASrc);
      AData := AData or DecodeTable[ASrc^];
      Inc(ASrc);

      X := ADataBytes[2];
      ADataBytes[2] := ADataBytes[0];
      ADataBytes[0] := X;

      X := Min(ASrcSize - 1, 3);
      AStream.Write(ADataBytes[0], X);
      Dec(ASrcSize, 4);
      Inc(Result, X);
    end;
  end;
end;

class function TACLMimecode.Decode(const ACode: AnsiString; AStream: TStream): Boolean;
var
  ANewSize: Integer;
begin
  AStream.Size := Length(ACode);
  ANewSize := Decode(@ACode[1], Length(ACode), AStream);
  Result := ANewSize >= 0;
  if Result then
  begin
    AStream.Size := ANewSize;
    AStream.Position := 0;
  end;
end;

class function TACLMimecode.DecodeBytes(const ACode: UnicodeString): TBytes;
begin
  Result := DecodeBytes(acUStringToBytes(PWideChar(ACode), Length(ACode)));
end;

class function TACLMimecode.DecodeBytes(const ACode: AnsiString): TBytes;
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    Decode(ACode, AStream);
    SetLength(Result{%H-}, AStream.Size);
    AStream.Position := 0;
    AStream.ReadBuffer(Result[0], Length(Result));
  finally
    AStream.Free;
  end;
end;

class function TACLMimecode.Encode(ASrc: PByte; ASrcSize: Integer; AStream: TStream): Integer;

  procedure OutputBytes(AStream: TStream; var ABank: Integer; ASize: Integer);
  var
    {%H-}ABuffer: array[0..3] of Byte;
    I: Integer;
  begin
    for I := ASize to 3 do
      ABuffer[I] := PadByte;
    for I := ASize - 1 downto 1 do
    begin
      ABuffer[I] := EncodeTable[ABank and $3F];
      ABank := ABank shr 6;
    end;
    ABuffer[0] := EncodeTable[ABank];

    AStream.WriteBuffer(ABuffer[0], SizeOf(ABuffer));
  end;

var
  ABank: Integer;
  AOverHead: Integer;
  ASrcLimit: Integer;
begin
  if ASrcSize <= 0 then
    Exit(0);

  Result := AStream.Position;
  ASrcLimit := Trunc(ASrcSize / 3) * 3;
  AOverHead := ASrcSize - ASrcLimit;

  while ASrcLimit > 0 do
  begin
    ABank := ASrc^;
    ABank := ABank shl 8;
    ABank := ABank or PByte(ASrc + 1)^;
    ABank := ABank shl 8;
    ABank := ABank or PByte(ASrc + 2)^;
    OutputBytes(AStream, ABank, 4);
    Dec(ASrcLimit, 3);
    Inc(ASrc, 3);
  end;

  case AOverHead of
    1:
      begin
        ABank := ASrc^;
        ABank := ABank shl 4;
        OutputBytes(AStream, ABank, 2);
      end;

    2:
      begin
        ABank := ASrc^;
        ABank := ABank shl 8;
        ABank := ABank or PByte(ASrc + 1)^;
        ABank := ABank shl 2;
        OutputBytes(AStream, ABank, 3);
      end;
  end;
  Result := AStream.Position - Result;
end;

class function TACLMimecode.Encode(P: PByteArray; ASize: Integer): TMemoryStream;
begin
  Result := TMemoryStream.Create;
  Result.Size := (ASize * 14) div 10; // 137% max
  Result.Size := Encode(@P^[0], ASize, Result);
  Result.Position := 0;
end;

class function TACLMimecode.EncodeBytes(const ABytes: PAnsiChar; ACount: Integer): string;
var
  AStream: TMemoryStream;
begin
  AStream := Encode(PByteArray(ABytes), ACount);
  try
    Result := acLoadString(AStream);
  finally
    AStream.Free;
  end;
end;

class function TACLMimecode.EncodeBytes(const ABytes: TBytes): string;
var
  AStream: TMemoryStream;
begin
  AStream := Encode(@ABytes[0], Length(ABytes));
  try
    Result := acLoadString(AStream);
  finally
    AStream.Free;
  end;
end;

class function TACLMimecode.EncodeString(const S: AnsiString; AStream: TStream): Integer;
begin
  Result := Encode(PByte(PAnsiChar(S)), Length(S), AStream);
end;

class function TACLMimecode.EncodeString(const S: UnicodeString; AStream: TStream): Integer;
begin
  Result := Encode(PByte(PWideChar(S)), Length(S) * SizeOf(WideChar), AStream);
end;

{ TACLPunycode }

class function TACLPunycode.Decode(const S: AnsiString): UnicodeString;
var
  AOutputLength: Cardinal;
begin
  AOutputLength := 0;
  if (Decode(PByte(S), Length(S), AOutputLength) = apcOK) and (Cardinal(Length(S)) <> AOutputLength) then
  begin
    SetLength(Result{%H-}, AOutputLength);
    Decode(PByte(S), Length(S), AOutputLength, PWordArray(Result));
  end
  else
    Result := UnicodeString(S);
end;

class function TACLPunycode.Decode(Input: PByte; InputLength: Cardinal; var OutputLength: Cardinal; Output: PWordArray = nil): TACLPunycodeStatus;
var
  ABasicPoints: Cardinal;
  ABias: Cardinal;
  ADigit: Cardinal;
  AIndex: Cardinal;
  AInputValue: Byte;
  AOutIndex: Cardinal;
  APrevI: Cardinal;
  I, W, K, T, N: Cardinal;
  J: Integer;
begin
  if InputLength = 0 then
    Exit(apcErrorBadInput);

  AOutIndex := 0;
  ABias := PUNY_INITIAL_BIAS;
  N := PUNY_INITIAL_N;
  I := 0;

  ABasicPoints := 0;
  for J := 0 to InputLength - 1 do
    if Input[J] = PUNY_DELIMITER then
    begin
      ABasicPoints := J;
      Break;
    end;

  if (Output <> nil) and (ABasicPoints > OutputLength) then
    Exit(apcErrorInsufficientBuffer);

  for J := 0 to ABasicPoints - 1 do
  begin
    AInputValue := Input[J];
    if AInputValue >= $80 then
      Exit(apcErrorBadInput);
    if Output <> nil then
      Output[AOutIndex] := AInputValue;
    Inc(AOutIndex);
  end;

  if ABasicPoints > 0 then
    AIndex := ABasicPoints + 1
  else
    AIndex := 0;

  while AIndex < InputLength do
  begin
    APrevI := I;
    W := 1;
    K := PUNY_BASE;
    while True do
    begin
      if AIndex >= InputLength then
        Exit(apcErrorBadInput);

      ADigit := DecodeDigit(Input[AIndex]);
      Inc(AIndex);
      if ADigit >= PUNY_BASE then
        Exit(apcErrorBadInput);

      if ADigit > (MaxWord - I) / W then
        Exit(apcErrorOverflow);
      Inc(I, ADigit * W);

      if K <= ABias then
        T := PUNY_TMIN
      else
        if K >= ABias + PUNY_TMAX then
          T := PUNY_TMAX
        else
          T := K - ABias;

      if ADigit < T then
        Break;
      if W > MaxWord / (PUNY_BASE - T) then
        Exit(apcErrorOverflow);
      W := W * (PUNY_BASE - T);
      Inc(K, PUNY_BASE);
    end;

    ABias := AdaptBias(I - APrevI, AOutIndex + 1, APrevI = 0);

    if I / (AOutIndex + 1) > MaxWord - N then
      Exit(apcErrorOverflow);
    Inc(N, I div (AOutIndex + 1));
    I := I mod (AOutIndex + 1);

    if Output <> nil then
    begin
      if AOutIndex >= OutputLength then
        Exit(apcErrorInsufficientBuffer);
      FastMove(Output[I], Output[I + 1], (AOutIndex - I) * SizeOf(Word));
      Output[i] := N;
    end;
    Inc(AOutIndex);
    Inc(I);
  end;

  OutputLength := AOutIndex;
  Result := apcOK;
end;

class function TACLPunycode.DecodeDomain(const S: AnsiString): UnicodeString;
var
  AResult: UnicodeString;
begin
  AResult := '';
  acExplodeString(PAnsiChar(S), Length(S), '.',
    procedure (ACursorStart, ACursorFinish: PAnsiChar; var {%H-}ACanContinue: Boolean)
    var
      A: AnsiString;
    begin
      A := acMakeString(ACursorStart, ACursorFinish);
      if AResult <> '' then
        AResult := AResult + '.';
      if System.AnsiStrings.SameText(Copy(A, 1, 4), 'xn--') then
        AResult := AResult + Decode(Copy(A, 5, MaxInt))
      else
        AResult := AResult + UnicodeString(A);
    end);
  Result := AResult;
end;

class function TACLPunycode.Encode(const S: UnicodeString): AnsiString;
begin
  if not Encode(S, Result) then
    Result := AnsiString(S);
end;

class function TACLPunycode.Encode(const S: UnicodeString; out A: AnsiString): Boolean;
var
  AOutputLength: Cardinal;
begin
  AOutputLength := 0;
  Result := (Encode(PWordArray(S), Length(S), AOutputLength) = apcOK) and (Cardinal(Length(S) + 1) <> AOutputLength);
  if Result then
  begin
    SetLength(A{%H-}, AOutputLength);
    Encode(PWordArray(S), Length(S), AOutputLength, PByte(A));
  end;
end;

class function TACLPunycode.Encode(Input: PWordArray; InputLength: Cardinal; var OutputLength: Cardinal; Output: PByte = nil): TACLPunycodeStatus;
var
  ABasicPointsCount: Cardinal;
  ABias: Cardinal;
  ADelta: Cardinal;
  AInputValue: Word;
  AOutIndex: Cardinal;
  N, H, M, Q, K, T: Cardinal;
  J: Integer;
begin
  if InputLength = 0 then
    Exit(apcErrorBadInput);

  ABias := PUNY_INITIAL_BIAS;
  ADelta := 0;
  AOutIndex := 0;
  N := PUNY_INITIAL_N;

  for J := 0 to InputLength - 1 do
  begin
    AInputValue := Input[J];
    if AInputValue < $80 then
    begin
      if Output <> nil then
      begin
        if OutputLength - AOutIndex < 2 then
          Exit(apcErrorInsufficientBuffer);
        Output[AOutIndex] := AInputValue;
      end;
      Inc(AOutIndex);
    end;
  end;

  ABasicPointsCount := AOutIndex;
  if ABasicPointsCount > 0 then
  begin
    if Output <> nil then
      Output[AOutIndex] := PUNY_DELIMITER;
    Inc(AOutIndex);
  end;

  H := ABasicPointsCount;
  while H < InputLength do
  begin
    M := MaxWord;
    for J := 0 to InputLength - 1 do
    begin
      AInputValue := Input[J];
      if (AInputValue >= N) and (AInputValue < M) then
        M := AInputValue;
    end;

    if M - N > (MaxWord - ADelta) / (H + 1) then
      Exit(apcErrorOverflow);
    Inc(ADelta, (M - N) * (H + 1));
    N := M;

    for J := 0 to InputLength - 1 do
    begin
      if Input[J] < N then
      begin
        Inc(ADelta);
        if ADelta = 0 then
          Exit(apcErrorOverflow);
      end;

      if Input[J] = N then
      begin
        Q := ADelta;
        K := PUNY_BASE;
        while True do
        begin
          if (Output <> nil) and (AOutIndex >= OutputLength) then
            Exit(apcErrorInsufficientBuffer);

          if K <= ABias then
            T := PUNY_TMIN
          else
            if K >= ABias + PUNY_TMAX then
              T := PUNY_TMAX
            else
              T := K - ABias;

          if Q < T then
            Break;

          if Output <> nil then
            Output[AOutIndex] := EncodeDigit(T + (Q - T) mod (PUNY_BASE - T));

          Q := (Q - T) div (PUNY_BASE - T);
          Inc(K, PUNY_BASE);
          Inc(AOutIndex);
        end;

        if Output <> nil then
          Output[AOutIndex] := EncodeDigit(Q);
        Inc(AOutIndex);

        ABias := AdaptBias(ADelta, H + 1, H = ABasicPointsCount);
        ADelta := 0;
        Inc(H);
      end;
    end;

    Inc(ADelta);
    Inc(N);
  end;

  OutputLength := AOutIndex;
  Result := apcOK;
end;

class function TACLPunycode.EncodeDomain(const S: UnicodeString): AnsiString;
var
  AResult: AnsiString;
begin
  AResult := '';
  acExplodeString(S, '.',
    procedure (ACursorStart, ACursorNext: PWideChar; var {%H-}ACanContinue: Boolean)
    var
      A: AnsiString;
      U: UnicodeString;
    begin
      U := acMakeString(ACursorStart, ACursorNext);
      if AResult <> '' then
        AResult := AResult + '.';
      if Encode(U, A) then
        AResult := AResult + 'xn--' + A
      else
        AResult := AResult + AnsiString(U);
    end);
  Result := AResult;
end;

class function TACLPunycode.AdaptBias(ADelta, ANumPoints: Cardinal; AIsFirstTime: Boolean): Cardinal;
var
  K: Word;
begin
  if AIsFirstTime then
    ADelta := ADelta div PUNY_DAMP
  else
    ADelta := ADelta shr 1;

  Inc(ADelta, ADelta div ANumPoints);

  K := 0;
  while ADelta > ((PUNY_BASE - PUNY_TMIN) * PUNY_TMAX) / 2 do
  begin
    ADelta := ADelta div (PUNY_BASE - PUNY_TMIN);
    Inc(K, PUNY_BASE);
  end;

  Result := K + (PUNY_BASE - PUNY_TMIN + 1) * ADelta div (ADelta + PUNY_SKEW);
end;

class function TACLPunycode.DecodeDigit(ACodePoint: Cardinal): Cardinal;
begin
  if ACodePoint - 48 < 10 then
    Result := ACodePoint - 22
  else
    if ACodePoint - 65 < 26 then
      Result := ACodePoint - 65
    else
      if ACodePoint - 97 < 26 then
        Result := ACodePoint - 97
      else
        Result := PUNY_BASE;
end;

class function TACLPunycode.EncodeDigit(ADigit: Cardinal): Byte;
begin
  Result := ADigit + 22 + 75 * Byte(ADigit < 26);
end;

{ TACLTranslit }

class function TACLTranslit.Decode(const S: UnicodeString): UnicodeString;
var
  I, ID: Integer;
  IsUpper: Boolean;
  LenS: Integer;

  function FindID(const AStr: UnicodeString): Integer;
  var
    J: Integer;
  begin
    for J := 1 to ColChar do
    begin
    {$IFDEF FPC}
      if Translit[J].Equals(AStr, True) then
    {$ELSE}
      if acSameText(AStr, Translit[J]) then
    {$ENDIF}
        Exit(J);
    end;
    Result := -1;
  end;

begin
  Result := '';
  LenS := Length(S);
  I := 1;
  while I <= LenS do
  begin
    IsUpper := S[I] <> acLowerCase(S[I]);
    ID := -1;

    if I + 2 <= LenS then
    begin
      ID := FindID(S[I] + S[I + 1] + S[I + 2]);
      if ID > 0 then
        Inc(I, 2);
    end;

    if (ID = -1) and (I + 1 <= LenS) then
    begin
      ID := FindID(S[I] + S[I + 1]);
      if ID > 0 then
        Inc(I);
    end;

    if ID = -1 then
      ID := FindID(S[I]);

    if ID <= 0 then
      Result := Result + S[I]
    else
      if IsUpper then
        Result := Result + acUpperCase(RArrayL[ID])
      else
        Result := Result + RArrayL[ID];

    Inc(I);
  end;
end;

class function TACLTranslit.Encode(const S: UnicodeString): UnicodeString;
var
  I: Integer;
  IsUpper: Boolean;
  LenS: Integer;
  P: integer;
  C: WideChar;
begin
  Result := '';
  LenS := Length(S);
  for I := 1 to LenS do
  begin
    C := acLowerCase(S[I]);
    IsUpper := C <> S[I];
    P := acPos(C, RArrayL);
    if P <> 0 then
    begin
      if IsUpper then
        Result := Result + acFirstWordWithCaptialLetter(Translit[p])
      else
        Result := Result + Translit[p];
    end
    else
      Result := Result + S[I];
  end;
end;

end.
