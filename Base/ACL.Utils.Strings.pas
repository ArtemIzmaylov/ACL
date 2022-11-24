{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*             Strings Utilities             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.Strings;

{$I ACL.Config.inc}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
{$IFNDEF ACL_BASE_NOVCL}
  Vcl.Graphics,
{$ENDIF}
  // System
{$IFNDEF ACL_BASE_NOVCL}
  System.UITypes,
{$ENDIF}
  System.Types,
  System.Math,
  System.SysUtils,
  System.Character,
  System.Classes,
  System.Generics.Collections;

const
  acCRLF = UnicodeString(#13#10);
  acLineBreakMacro = '\n';
  acLineSeparator = WideChar($2028);
  acZero = #0#0;
  acZeroWidthSpace = WideChar($200B);

  UNICODE_BOM = WideChar($FEFF);
  UNICODE_BOM_EX = AnsiString(#$FF#$FE);
  UNICODE_NULL = WideChar($0000);

type
  TAnsiStringDynArray = array of AnsiString;

  TAnsiExplodeStringReceiveResultProc = reference to procedure (ACursorStart, ACursorNext: PAnsiChar; var ACanContinue: Boolean);
  TWideExplodeStringReceiveResultProc = reference to procedure (ACursorStart, ACursorNext: PWideChar; var ACanContinue: Boolean);

  { TACLTimeFormat }

  TACLFormatTimePart = (ftpMilliSeconds, ftpSeconds, ftpMinutes, ftpHours, ftpDays);
  TACLFormatTimeParts = set of TACLFormatTimePart;

  TACLTimeFormat = class
  public
    class function Format(const ATimeInMilliSeconds: Int64;
      AParts: TACLFormatTimeParts = [ftpSeconds..ftpHours]; ASuppressZeroValues: Boolean = True): UnicodeString; inline;
    class function FormatEx(ATimeInSeconds: Single; AParts: TACLFormatTimeParts; ASuppressZeroValues: Boolean): UnicodeString; overload;
    class function FormatEx(ATimeInSeconds: Single; AParts: TACLFormatTimeParts;
      const APartDelimiter: UnicodeString = ':'; ASuppressZeroValues: Boolean = False): UnicodeString; overload;
    // Parts;Delimiter;Flags
    // Parts: can be (D)ay, (H)our, (M)inute, (S)econd, (Z)millisecond
    // Delimiter: default is ":"
    // Flags: can be: "Z" - suppress (Z)eros
    //
    // Example: HMS;:;Z ->  1:05:30
    // Example: HMS;:   -> 01:05:30
    // Example: MS;:    ->    65:30
    class function FormatEx(ATimeInSeconds: Single; const AFormatString: UnicodeString): UnicodeString; overload;
    //
    // Supports:
    // h:mm:ss
    // h:mm:ss.msec
    // m:ss
    // m:ss.msec
    // s
    // s.msec
    class function Parse(S: string; out ATimeInSeconds: Single): Boolean;
  end;

  { TACLSearchString }

  TACLSearchString = class
  strict private
    FEmpty: Boolean;
    FIgnoreCase: Boolean;
    FMask: TStringDynArray;
    FMaskResult: array of Boolean;
    FSeparator: Char;
    FValue: UnicodeString;

    function GetValueIsNumeric: Boolean;
    function PrepareString(const AValue: UnicodeString): UnicodeString;
    procedure SetIgnoreCase(const AValue: Boolean);
    procedure SetValue(const AValue: UnicodeString);
  public
    constructor Create; overload;
    constructor Create(const AMask: UnicodeString; AIgnoreCase: Boolean = True); overload;
    function Compare(const S: UnicodeString): Boolean;

    procedure BeginComparing;
    procedure AddToCompare(S: UnicodeString);
    function EndComparing: Boolean;

    property Empty: Boolean read FEmpty;
    property IgnoreCase: Boolean read FIgnoreCase write SetIgnoreCase;
    property Separator: Char read FSeparator write FSeparator;
    property Value: UnicodeString read FValue write SetValue;
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

  { TACLStringBuilderHelper }

  TACLStringBuilderHelper = class helper for TStringBuilder
  public
    function Append(const AValue: PWideChar; ALength: Integer): TStringBuilder; overload;
  end;

  { TACLStringBuilderManager }

  TACLStringBuilderManager = class
  strict private const
    CacheSize = 4;
    HugeCapacityThreshold = 1048576;
  strict private
    class var Cache: array[0..Pred(CacheSize)] of TStringBuilder;
  public
    class destructor Finalize;
    class function Get(ACapacity: Integer = 0): TStringBuilder;
    class procedure Release(var ABuilder: TStringBuilder);
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

  { TACLEncodings }

  TACLEncodings = class
  strict private
    class var FCodePages: TObject;
    class var FMap: TObject;

    class function CodePageEnumProc(lpCodePageString: PWideChar): Cardinal; stdcall; static;
  public
    class constructor Create;
    class destructor Destroy;
    class function Default: TEncoding;
    class procedure EnumAnsiCodePages(const AProc: TProc<Integer, string>);
    class function Get(const CodePage: Integer): TEncoding; overload;
    class function Get(const Name: string): TEncoding; overload;
  end;

  TACLFontData = array[0..3] of UnicodeString;

var
  DefaultCodePage: Integer = CP_ACP;

  acLangSizeSuffixB: string = 'B';
  acLangSizeSuffixKB: string = 'KB';
  acLangSizeSuffixMB: string = 'MB';
  acLangSizeSuffixGB: string = 'GB';

function StrToIntDef(const S: AnsiString; ADefault: Integer): Integer; overload;

// Text Conversions
function acAnsiFromUnicode(const S: UnicodeString): AnsiString; overload;
function acAnsiFromUnicode(const S: UnicodeString; CodePage: Integer): AnsiString; overload;
function acBytesFromUnicode(W: PWideChar; ACount: Integer): RawByteString;
function acStringFromAnsi(const S: AnsiChar): WideChar; overload;
function acStringFromAnsi(const S: AnsiString): UnicodeString; overload;
function acStringFromAnsi(const S: AnsiString; CodePage: Integer): UnicodeString; overload;
function acStringFromAnsi(const S: PAnsiChar; ALength, ACodePage: Integer): UnicodeString; overload;
function acStringFromBytes(const ABytes: TBytes): UnicodeString; overload;
function acStringFromBytes(B: PByte; Count: Integer): UnicodeString; overload;
function acStringIsRealUnicode(const S: UnicodeString): Boolean;

// UTF8
// Unlike built-in to RTL and Windows OS versions of these functions
// Our functions returns an empty string if UTF8 sequence is invalid
function acDecodeUTF8(const Source: AnsiString): UnicodeString;
function acEncodeUTF8(const Source: UnicodeString): AnsiString;
function acUnicodeToUtf8(Dest: PAnsiChar; MaxDestBytes: Cardinal; Source: PWideChar; SourceChars: Cardinal): Cardinal;
function acUtf8ToUnicode(Dest: PWideChar; MaxDestChars: Cardinal; Source: PAnsiChar; SourceBytes: Integer): Integer;

// Search
function acFindString(const ACharToSearch: WideChar; const AString: UnicodeString; out AIndex: Integer): Boolean; overload;
function acFindString(const AStringToSearch, AString: UnicodeString; out AIndex: Integer; AIgnoreCase: Boolean = False; AOffset: Integer = 1): Boolean; overload;
function acFindStringInMemoryA(const S: AnsiString; AMem: PByte; AMemSize, AMemOffset: Integer; out AOffset: Integer): Boolean;
function acFindStringInMemoryW(const S: UnicodeString; AMem: PByte; AMemSize, AMemOffset: Integer; out AOffset: Integer): Boolean;

// Allocation
function acAllocStr(const S: UnicodeString): PWideChar; overload;
function acAllocStr(const S: UnicodeString; out ALength: Integer): PWideChar; overload;
function acMakeString(const P: PWideChar; L: Integer): UnicodeString; overload; inline;
function acMakeString(const P: PAnsiChar; L: Integer): AnsiString; overload; inline;

// Pos
function acPos(const ACharToSearch: WideChar; const AString: UnicodeString): Integer; overload;
function acPos(const ASubStr, AString: UnicodeString; AIgnoreCase, AWholeWords: Boolean; AOffset: Integer = 1): Integer; overload;
function acPos(const ASubStr, AString: UnicodeString; AIgnoreCase: Boolean = False; AOffset: Integer = 1): Integer; overload;

// Explode
function acExplodeString(const S: UnicodeString; const ADelimiters: UnicodeString; AReceiveProc: TWideExplodeStringReceiveResultProc): Integer; overload;
function acExplodeString(const S: UnicodeString; const ADelimiters: UnicodeString; out AParts: TStringDynArray): Integer; overload;
function acExplodeString(AScan: PAnsiChar; AScanCount: Integer; ADelimiter: AnsiChar; AReceiveProc: TAnsiExplodeStringReceiveResultProc): Integer; overload;
function acExplodeString(AScan: PWideChar; AScanCount: Integer; const ADelimiters: UnicodeString; AReceiveProc: TWideExplodeStringReceiveResultProc): Integer; overload;
function acExplodeStringAsIntegerArray(const S: UnicodeString; ADelimiter: WideChar; AArray: PInteger; AArrayLength: Integer): Integer;
function acGetCharacterCount(const S, ACharacters: UnicodeString): Integer; overload;
function acGetCharacterCount(P: PWideChar; ALength: Integer; const ACharacters: UnicodeString): Integer; overload;

// Case
function acAllWordsWithCaptialLetter(const S: UnicodeString; IgnoreSourceCase: Boolean = False): UnicodeString;
function acFirstWordWithCaptialLetter(const S: UnicodeString): UnicodeString;
function acLowerCase(const S: UnicodeString): UnicodeString; overload; inline;
function acLowerCase(const S: WideChar): WideChar; overload; inline;
function acUpperCase(const S: UnicodeString): UnicodeString; overload; inline;
function acUpperCase(const S: WideChar): WideChar; overload; inline;

// Comparing
function acBeginsWith(const S, ATestPrefix: UnicodeString; AIgnoreCase: Boolean = True): Boolean;
function acEndsWith(const S, ATestSuffix: UnicodeString; AIgnoreCase: Boolean = True): Boolean;
function acCompareStringByMask(const AMask, AStr: UnicodeString): Boolean;
function acCompareStrings(const S1, S2: UnicodeString; AIgnoreCase: Boolean = True): Integer; overload;
function acCompareStrings(P1, P2: PWideChar; L1, L2: Integer; AIgnoreCase: Boolean = True): Integer; overload;
function acLogicalCompare(const S1, S2: UnicodeString; AIgnoreCase: Boolean = True): Integer; overload;
function acLogicalCompare(P1, P2: PWideChar; P1Len, P2Len: Integer; AIgnoreCase: Boolean = True): Integer; overload;
function acSameText(const S1, S2: UnicodeString): Boolean;
function acSameTextEx(const S: UnicodeString; const AStrs: array of UnicodeString): Boolean;

// Encoding
function acDetectEncoding(ABuffer: PByte; ABufferSize: Integer; ADefaultEncoding: TEncoding = nil): TEncoding; overload; deprecated;
function acDetectEncoding(ABuffer: TBytes; out AEncoding: TEncoding; ADefaultEncoding: TEncoding = nil): Integer; overload;
function acDetectEncoding(AStream: TStream; ADefaultEncoding: TEncoding = nil): TEncoding; overload;

// Replacing
function acRemoveChar(const S: UnicodeString; const ACharToRemove: WideChar): UnicodeString;
function acReplaceChar(const S: UnicodeString; const ACharToReplace, AReplaceBy: WideChar): UnicodeString;
function acReplaceChars(const S: UnicodeString; const ACharsToReplace: UnicodeString; const AReplaceBy: WideChar = '_'): UnicodeString;
function acStringReplace(const S, OldPattern, NewPattern: string; AIgnoreCase: Boolean = False; AWholeWords: Boolean = False): string;

// Integer <-> PWideChar;
function acPWideCharToIntDef(AChars: PWideChar; ACount: Integer; const ADefaultValue: Int64): Int64; inline;
function acTryPWideCharToInt(AChars: PWideChar; ACount: Integer; out AValue: Int64): Boolean;

// Linebreaks
function acDecodeLineBreaks(const S: UnicodeString): UnicodeString;
function acEncodeLineBreaks(const S: UnicodeString): UnicodeString;
function acRemoveLineBreaks(const S: UnicodeString): UnicodeString;
function acReplaceLineBreaks(const S, ReplaceBy: UnicodeString): UnicodeString;

// Conversion
{$IFNDEF ACL_BASE_NOVCL}
function acFontStyleDecode(const Style: TFontStyles): Byte;
function acFontStyleEncode(Style: Integer): TFontStyles;
function acFontToString(AFont: TFont): UnicodeString; overload;
function acFontToString(const AName: UnicodeString; AColor: TColor; AHeight: Integer; AStyle: TFontStyles): UnicodeString; overload;
procedure acStringToFont(const S: UnicodeString; const Font: TFont);
procedure acStringToFontData(const S: UnicodeString; out AFontData: TACLFontData);
{$ENDIF}
function acPointToString(const P: TPoint): UnicodeString;
function acRectToString(const R: TRect): UnicodeString;
function acSizeToString(const S: TSize): UnicodeString;
function acStringToPoint(const S: UnicodeString): TPoint;
function acStringToRect(const S: UnicodeString): TRect;
function acStringToSize(const S: UnicodeString): TSize;

// Formatting
function acFormatFloat(const AFormat: UnicodeString; const AValue: Double; AShowPlusSign: Boolean): UnicodeString; overload;
function acFormatFloat(const AFormat: UnicodeString; const AValue: Double; const ADecimalSeparator: Char = '.'): UnicodeString; overload;
function acFormatSize(const AValue: Int64; AAllowGigaBytes: Boolean = True): UnicodeString;
function acFormatTrackNo(ATrack: Integer): UnicodeString;

// Utils
function IfThenW(AValue: Boolean; const ATrue: UnicodeString; const AFalse: UnicodeString = ''): UnicodeString; overload; inline;
function IfThenW(const A, B: UnicodeString): UnicodeString; overload; inline;
function acDupeString(const AText: UnicodeString; ACount: Integer): UnicodeString;
function acTrim(const S: UnicodeString): UnicodeString;
function WStrLength(S: PWideChar; AMaxScanCount: Integer): Integer;
function WStrScan(Str: PWideChar; ACount: Integer; C: WideChar): PWideChar; overload;
function WStrScan(Str: PWideChar; C: WideChar): PWideChar; overload;
procedure acStrLCopy(ADest: PWideChar; const ASource: UnicodeString; AMax: Integer);
procedure acCryptStringXOR(var S: UnicodeString; const AKey: UnicodeString);
implementation

uses
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FastCode,
  ACL.Parsers,
  ACL.Utils.Common;

const
  MaxPreambleLength = 3;

type
  TStringBuilderAccess = class(TStringBuilder);

function StrToIntDef(const S: AnsiString; ADefault: Integer): Integer;
begin
  Result := System.SysUtils.StrToIntDef(string(S), ADefault);
end;

// ---------------------------------------------------------------------------------------------------------------------
// Conversion
// ---------------------------------------------------------------------------------------------------------------------

function acStringToPoint(const S: UnicodeString): TPoint;
begin
  Result := NullPoint;
  acExplodeStringAsIntegerArray(S, ',', @Result.X, 2);
end;

function acStringToSize(const S: UnicodeString): TSize;
begin
  Result := NullSize;
  acExplodeStringAsIntegerArray(S, ',', @Result.cx, 2);
end;

function acStringToRect(const S: UnicodeString): TRect;
begin
  Result := NullRect;
  acExplodeStringAsIntegerArray(S, ',', @Result.Left, 4);
end;

function acPointToString(const P: TPoint): UnicodeString;
begin
  Result := Format('%d,%d', [P.X, P.Y]);
end;

function acSizeToString(const S: TSize): UnicodeString;
begin
  Result := Format('%d,%d', [S.cx, S.cy]);
end;

function acRectToString(const R: TRect): UnicodeString;
begin
  Result := Format('%d,%d,%d,%d', [R.Left, R.Top, R.Right, R.Bottom]);
end;

{$IFNDEF ACL_BASE_NOVCL}
function acFontStyleEncode(Style: Integer): TFontStyles;
begin
  Result := [];
  if 1 and Style = 1 then
    Result := Result + [fsItalic];
  if 2 and Style = 2 then
    Result := Result + [fsBold];
  if 4 and Style = 4 then
    Result := Result + [fsUnderline];
  if 8 and Style = 8 then
    Result := Result + [fsStrikeOut];
end;

function acFontStyleDecode(const Style: TFontStyles): Byte;
begin
  Result := 0;
  if fsItalic in Style then
    Result := 1;
  if fsBold in Style then
    Result := Result or 2;
  if fsUnderline in Style then
    Result := Result or 4;
  if fsStrikeOut in Style then
    Result := Result or 8;
end;

function acFontToString(const AName: UnicodeString;
  AColor: TColor; AHeight: Integer; AStyle: TFontStyles): UnicodeString; overload;
begin
  Result := Format('%s,%d,%d,%d', [AName, AColor, AHeight, acFontStyleDecode(AStyle)]);
end;

function acFontToString(AFont: TFont): UnicodeString; overload;
begin
  Result := acFontToString(AFont.Name, AFont.Color, AFont.Height, AFont.Style);
end;

procedure acStringToFont(const S: UnicodeString; const Font: TFont);
var
  AFontData: TACLFontData;
begin
  acStringToFontData(S, AFontData);
  Font.Name := AFontData[0];
  Font.Color := StrToIntDef(AFontData[1], 0);
  Font.Height := StrToIntDef(AFontData[2], 0);
  Font.Style := acFontStyleEncode(StrToIntDef(AFontData[3], 0));
end;

procedure acStringToFontData(const S: UnicodeString; out AFontData: TACLFontData);
var
  ALen: Integer;
  APos: Integer;
  AStart, AScan: PWideChar;
begin
  AScan := PWideChar(S);
  ALen := Length(S);
  AStart := AScan;
  APos := 0;
  while (ALen >= 0) and (APos <= High(AFontData)) do
  begin
    if (AScan^ = ',') or (ALen = 0) then
    begin
      SetString(AFontData[APos], AStart, (NativeUInt(AScan) - NativeUInt(AStart)) div SizeOf(WideChar));
      AStart := AScan;
      Inc(AStart);
      Inc(APos);
    end;
    Dec(ALen);
    Inc(AScan);
  end;
end;
{$ENDIF}

// ---------------------------------------------------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------------------------------------------------

function acFormatSize(const AValue: Int64; AAllowGigaBytes: Boolean = True): UnicodeString;
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

function acFormatTrackNo(ATrack: Integer): UnicodeString;
begin
  if (ATrack >= 0) and (ATrack < 10) then
    Result := '0' + IntToStr(ATrack)
  else
    Result := IntToStr(ATrack);
end;

function acFormatFloat(const AFormat: UnicodeString; const AValue: Double; const ADecimalSeparator: Char = '.'): UnicodeString;
var
  AFormatSettings: TFormatSettings;
begin
  AFormatSettings := FormatSettings;
  AFormatSettings.DecimalSeparator := ADecimalSeparator;
  Result := FormatFloat(AFormat, AValue, AFormatSettings);
end;

function acFormatFloat(const AFormat: UnicodeString; const AValue: Double; AShowPlusSign: Boolean): UnicodeString;
const
  SignsMap: array[Boolean] of string = ('', '+');
begin
  Result := SignsMap[(AValue >= 0) and AShowPlusSign] + acFormatFloat(AFormat, AValue);
end;

// ---------------------------------------------------------------------------------------------------------------------
// Text Conversions
// ---------------------------------------------------------------------------------------------------------------------

function acAnsiFromUnicode(const S: UnicodeString): AnsiString; overload;
begin
  Result := acAnsiFromUnicode(S, DefaultCodePage);
end;

function acAnsiFromUnicode(const S: UnicodeString; CodePage: Integer): AnsiString; overload;
var
  ALen: Integer;
  ATemp: PWideChar;
begin
  ATemp := PWideChar(S);
  ALen := LocaleCharsFromUnicode(CodePage, 0, ATemp, Length(S), nil, 0, nil, nil);
  SetLength(Result, ALen);
  LocaleCharsFromUnicode(CodePage, 0, ATemp, Length(S), PAnsiChar(Result), ALen, nil, nil);
end;

function acBytesFromUnicode(W: PWideChar; ACount: Integer): RawByteString;
var
  B: PByte;
begin
  SetLength(Result, ACount);
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

function acStringFromAnsi(const S: AnsiString): UnicodeString;
begin
  Result := acStringFromAnsi(S, DefaultCodePage);
end;

function acStringFromAnsi(const S: AnsiChar): WideChar;
begin
  UnicodeFromLocaleChars(DefaultCodePage, 0, @S, 1, @Result, 1);
end;

function acStringFromAnsi(const S: PAnsiChar; ALength, ACodePage: Integer): UnicodeString;
var
  ATargetLength: Integer;
begin
  ATargetLength := UnicodeFromLocaleChars(ACodePage, 0, S, ALength, nil, 0);
  SetLength(Result, ATargetLength);
  UnicodeFromLocaleChars(ACodePage, 0, S, ALength, PWideChar(Result), ATargetLength);
end;

function acStringFromAnsi(const S: AnsiString; CodePage: Integer): UnicodeString;
begin
  Result := acStringFromAnsi(PAnsiChar(S), Length(S), CodePage);
end;

function acStringFromBytes(const ABytes: TBytes): UnicodeString;
begin
  Result := acStringFromBytes(@ABytes[0], Length(ABytes));
end;

function acStringFromBytes(B: PByte; Count: Integer): UnicodeString;
var
  W: PWord;
begin
  SetLength(Result, Count);
  if Count > 0 then
  begin
    W := @Result[1];
    while Count > 0 do
    begin
      W^ := B^;
      Dec(Count);
      Inc(W);
      Inc(B);
    end;
  end;
end;

function acStringIsRealUnicode(const S: UnicodeString): Boolean;
var
  I: Integer;
  L: Integer;
  P: PWideChar;
begin
  L := Length(S);
  P := PWideChar(S);
  for I := 1 to L do
  begin
    if Ord(P^) >= $7F then
      Exit(True); // Unicode or Extended ASCII
    Inc(P);
  end;
  Result := False;
end;

//==============================================================================
// Search
//==============================================================================

function FindDataInMemory(const AData, AMem: PByte; ADataSize, AMemSize, AMemOffset: Integer; out AOffset: Integer): Boolean;
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
    Result := (PByteArray(P)^[0] = PByteArray(AData)^[0]) and
      (PByteArray(P)^[ADataSize - 1] = PByteArray(AData)^[ADataSize - 1]) and
       CompareMem(P, AData, ADataSize);

    if Result then
    begin
      AOffset := AMemSize - C;
      Break;
    end;
    Dec(C);
    Inc(P);
  end;
end;

function acFindStringInMemoryA(const S: AnsiString; AMem: PByte; AMemSize, AMemOffset: Integer; out AOffset: Integer): Boolean;
begin
  Result := FindDataInMemory(PByte(@S[1]), AMem, Length(S), AMemSize, AMemOffset, AOffset);
end;

function acFindStringInMemoryW(const S: UnicodeString; AMem: PByte; AMemSize, AMemOffset: Integer; out AOffset: Integer): Boolean;
begin
  Result := FindDataInMemory(PByte(@S[1]), AMem, Length(S) * SizeOf(WideChar), AMemSize, AMemOffset, AOffset);
end;

//==============================================================================
// Allocation
//==============================================================================

function acAllocStr(const S: UnicodeString): PWideChar;
var
  L: Integer;
begin
  Result := acAllocStr(S, L);
end;

function acAllocStr(const S: UnicodeString; out ALength: Integer): PWideChar;
begin
  ALength := Length(S);
  Result := AllocMem((ALength + 1) * SizeOf(WideChar));
  FastMove(S[1], Result^, ALength * SizeOf(WideChar));
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

//==============================================================================
// Position
//==============================================================================

function acFindString(const ACharToSearch: WideChar; const AString: UnicodeString; out AIndex: Integer): Boolean;
begin
  AIndex := acPos(ACharToSearch, AString);
  Result := AIndex > 0;
end;

function acFindString(const AStringToSearch, AString: UnicodeString; out AIndex: Integer; AIgnoreCase: Boolean = False; AOffset: Integer = 1): Boolean;
begin
  AIndex := acPos(AStringToSearch, AString, AIgnoreCase, AOffset);
  Result := AIndex > 0;
end;

function acPos(const ACharToSearch: WideChar; const AString: UnicodeString): Integer;
var
  P, R: PWideChar;
begin
  P := PWideChar(AString);
  R := WStrScan(P, Length(AString), ACharToSearch);
  if R <> nil then
    Result := 1 + (NativeUInt(R) - NativeUInt(P)) div SizeOf(WideChar)
  else
    Result := 0
end;

function acPos(const ASubStr, AString: UnicodeString; AIgnoreCase: Boolean = False; AOffset: Integer = 1): Integer;
begin
  if AIgnoreCase then
    Result := Pos(acUpperCase(ASubStr), acUpperCase(AString), AOffset)
  else
    Result := Pos(ASubStr, AString, AOffset);
end;

function acPos(const ASubStr, AString: UnicodeString; AIgnoreCase, AWholeWords: Boolean; AOffset: Integer = 1): Integer;
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
// UTF8: Default Delphi's algorithm was changed in D2009 and it have another behavior.
//       Old Behavior: for non-UTF8 strings function return an empty string.
//==============================================================================

function acUnicodeToUtf8(Dest: PAnsiChar; MaxDestBytes: Cardinal; Source: PWideChar; SourceChars: Cardinal): Cardinal;
var
  I, C, Count: Cardinal;
begin
  Result := 0;
  if (Source = nil) or (Dest = nil) then Exit;

  I := 0;
  Count := 0;
  while (I < SourceChars) and (Count < MaxDestBytes) do
  begin
    C := Cardinal(Source[I]);
    Inc(I);
    if C <= $7F then
    begin
      Dest[Count] := AnsiChar(C);
      Inc(Count);
    end
    else

    if C > $7FF then
    begin
      if Count + 3 > MaxDestBytes then Break;
      Dest[Count]     := AnsiChar($E0 or (C shr 12));
      Dest[Count + 1] := AnsiChar($80 or ((C shr 6) and $3F));
      Dest[Count + 2] := AnsiChar($80 or (C and $3F));
      Inc(Count, 3);
    end
    else //  $7F < Source[i] <= $7FF
    begin
      if Count + 2 > MaxDestBytes then Break;
      Dest[Count]     := AnsiChar($C0 or (C shr 6));
      Dest[Count + 1] := AnsiChar($80 or (C and $3F));
      Inc(Count, 2);
    end;
  end;
  if Count >= MaxDestBytes then
    Count := MaxDestBytes - 1;
  Dest[Count] := #0;
  Result := Count + 1;  // convert zero based index to byte count
end;

function acUtf8ToUnicode(Dest: PWideChar; MaxDestChars: Cardinal; Source: PAnsiChar; SourceBytes: Integer): Integer;
var
  AChar: WideChar;
  C: Byte;
  Count, WC: Cardinal;
begin
  if Source = nil then
    Exit(0);

  Count := 0;
  Result := -1;
  FastZeroMem(Dest, MaxDestChars * SizeOf(WideChar));
  while (SourceBytes > 0) and (Count < MaxDestChars) do
  begin
    WC := Cardinal(Source^);
    Dec(SourceBytes);
    Inc(Source);
    if WC and $80 = 0 then
      AChar := WideChar(WC)
    else
    begin
      if SourceBytes = 0 then
        Exit; // incomplete multibyte char

      WC := WC and $3F;
      if WC and $20 <> 0 then
      begin
        C := Byte(Source^);
        Dec(SourceBytes);
        Inc(Source);
        if C and $C0 <> $80 then Exit;      // malformed trail byte or out of range char
        if SourceBytes <= 0 then Exit;      // incomplete multibyte char
        WC := (WC shl 6) or (C and $3F);
      end;
      C := Byte(Source^);
      Dec(SourceBytes);
      Inc(Source);
      if C and $C0 <> $80 then Exit;      // malformed trail byte
      AChar := WideChar((WC shl 6) or (C and $3F));
    end;
    Dest^ := AChar;
    Inc(Count);
    Inc(Dest);
  end;
  Result := Count;
end;

function acDecodeUTF8(const Source: AnsiString): UnicodeString;
var
  L: Integer;
begin
  L := Length(Source);
  if L > 0 then
  begin
    SetLength(Result, L);
    L := acUtf8ToUnicode(PWideChar(Result), L, PAnsiChar(Source), L);
    if L > 0 then
      SetLength(Result, L);
  end;
  if L <= 0 then
    Result := '';
end;

function acEncodeUTF8(const Source: UnicodeString): AnsiString;
var
  L: Integer;
begin
  Result := '';
  L := Length(Source);
  if L > 0 then
  begin
    SetLength(Result, L * 3); // SetLength includes space for null terminator
    L := UnicodeToUtf8(PAnsiChar(Result), Length(Result) + 1, PWideChar(Source), L);
    if L > 0 then
      SetLength(Result, L - 1)
  end;
end;

// ---------------------------------------------------------------------------------------------------------------------
// ExplodeString
// ---------------------------------------------------------------------------------------------------------------------

function acExplodeString(AScan: PAnsiChar; AScanCount: Integer; ADelimiter: AnsiChar; AReceiveProc: TAnsiExplodeStringReceiveResultProc): Integer;
var
  ACanContinue: Boolean;
  ACursor: PAnsiChar;
begin
  Result := 0;
  if AScanCount > 0 then
  begin
    ACursor := AScan;
    ACanContinue := True;
    while (AScanCount >= 0) and ACanContinue do
    begin
      if (AScanCount = 0) or (AScan^ = ADelimiter) then
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

function acExplodeString(const S, ADelimiters: UnicodeString; out AParts: TStringDynArray): Integer;
var
  AArray: PString;
  AArrayLength: Integer;
  AScan: PWideChar;
  AScanCount: Integer;
begin
  AScan := PWideChar(S);
  AScanCount := Length(S);

  Result := acGetCharacterCount(AScan, AScanCount, ADelimiters) + 1;
  SetLength(AParts, Result);
  if Result > 0 then
  begin
    AArray := @AParts[0];
    AArrayLength := Result;
    Result := acExplodeString(AScan, AScanCount, ADelimiters,
      procedure (ACursorStart, ACursorNext: PWideChar; var ACanContinue: Boolean)
      begin
        AArray^ := acExtractString(ACursorStart, ACursorNext);
        Dec(AArrayLength);
        Inc(AArray);
        ACanContinue := AArrayLength > 0;
      end);
  end;
end;

function acExplodeString(const S, ADelimiters: UnicodeString; AReceiveProc: TWideExplodeStringReceiveResultProc): Integer;
begin
  Result := acExplodeString(PWideChar(S), Length(S), ADelimiters, AReceiveProc);
end;

function acExplodeString(AScan: PWideChar; AScanCount: Integer;
  const ADelimiters: UnicodeString; AReceiveProc: TWideExplodeStringReceiveResultProc): Integer;
var
  ACanContinue: Boolean;
  ACursor: PWideChar;
  ADelimiterCode: Word;
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
      ADelimiterCode := Ord(ADelimiters[1])
    else
      ADelimiterCode := 0;

    while (AScanCount >= 0) and ACanContinue do
    begin
      if AIsFastWay then
        AIsDelimiter := Ord(AScan^) = ADelimiterCode
      else
        AIsDelimiter := acPos(AScan^, ADelimiters) > 0;

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

function acExplodeStringAsIntegerArray(const S: UnicodeString;
  ADelimiter: WideChar; AArray: PInteger; AArrayLength: Integer): Integer;
begin
  if (AArray = nil) or (AArrayLength <= 0) then
    Result := 0
  else
    Result := acExplodeString(S, ADelimiter,
      procedure (ACursorStart, ACursorNext: PWideChar; var ACanContinue: Boolean)
      begin
        AArray^ := acPWideCharToIntDef(ACursorStart, acStringLength(ACursorStart, ACursorNext), 0);
        Dec(AArrayLength);
        Inc(AArray);
        ACanContinue := AArrayLength > 0;
      end);
end;

function acGetCharacterCount(const S, ACharacters: UnicodeString): Integer;
begin
  Result := acGetCharacterCount(PWideChar(S), Length(S), ACharacters);
end;

function acGetCharacterCount(P: PWideChar; ALength: Integer; const ACharacters: UnicodeString): Integer;
begin
  Result := 0;
  while ALength > 0 do
  begin
    if acPos(P^, ACharacters) > 0 then
      Inc(Result);
    Dec(ALength);
    Inc(P);
  end;
end;

//==============================================================================
// Charset
//==============================================================================

function acFirstWordWithCaptialLetter(const S: UnicodeString): UnicodeString;
var
  APos, ALen: Cardinal;
  Ch1, Ch2: WideChar;
begin
  Result := acLowerCase(S);
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

//  Test('swoosh fever (extended version)', 'Swoosh Fever (Extended Version)');
//  Test('there''s nothing to do', 'There''s Nothing To Do');
//  Test('21th', '21th');
//  Test('dear monsters, be patient', 'Dear Monsters, Be Patient');
function acAllWordsWithCaptialLetter(const S: UnicodeString; IgnoreSourceCase: Boolean = False): UnicodeString;
var
  AChar1: WideChar;
  AEndOfWordFound: Boolean;
  APos, ALen: Cardinal;
begin
  APos := 1;
  ALen := Length(S);
  if IgnoreSourceCase then
    Result := S
  else
    Result := acLowerCase(S);

  AEndOfWordFound := True;
  while APos <= ALen do
  begin
    AChar1 := Result[APos];
    if AEndOfWordFound then
      Result[APos] := acUpperCase(AChar1);
    AEndOfWordFound := (AChar1 <> #39) and (acPos(AChar1, acParserDefaultDelimiterChars) > 0);
    Inc(APos);
  end;
end;

function acLowerCase(const S: UnicodeString): UnicodeString;
begin
  Result := S.ToLower;
end;

function acLowerCase(const S: WideChar): WideChar;
begin
  Result := S.ToLower
end;

function acUpperCase(const S: UnicodeString): UnicodeString;
begin
  Result := S.ToUpper;
end;

function acUpperCase(const S: WideChar): WideChar;
begin
  Result := S.ToUpper;
end;

//==============================================================================
// Comparing
//==============================================================================

function acBeginsWith(const S, ATestPrefix: UnicodeString; AIgnoreCase: Boolean = True): Boolean;
var
  L: Integer;
begin
  L := Length(ATestPrefix);
  Result := (Length(S) >= L) and (acCompareStrings(PWideChar(S), PWideChar(ATestPrefix), L, L, AIgnoreCase) = 0);
end;

function acEndsWith(const S, ATestSuffix: UnicodeString; AIgnoreCase: Boolean = True): Boolean;
var
  LS: Integer;
  LT: Integer;
begin
  LS := Length(S);
  LT := Length(ATestSuffix);
  Result := (LS >= LT) and (acCompareStrings(PWideChar(S) + LS - LT, PWideChar(ATestSuffix), LT, LT, AIgnoreCase) = 0);
end;

function acCompareStringByMask(const AMask, AStr: UnicodeString): Boolean;
begin
  with TACLSearchString.Create(AMask) do
  try
    Result := Compare(AStr);
  finally
    Free;
  end;
end;

function acCompareStrings(const S1, S2: UnicodeString; AIgnoreCase: Boolean = True): Integer;
begin
{$IFDEF MSWINDOWS}
  Result := acCompareStrings(PWideChar(S1), PWideChar(S2), Length(S1), Length(S2), AIgnoreCase);
{$ELSE}
  if AIgnoreCase then
    Result := AnsiCompareStr(S1, S2)
  else
    Result := AnsiCompareText(S1, S2);
{$ENDIF}
end;

function acCompareStrings(P1, P2: PWideChar; L1, L2: Integer; AIgnoreCase: Boolean = True): Integer;
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

function acLogicalCompare(const S1, S2: UnicodeString; AIgnoreCase: Boolean = True): Integer;
begin
  Result := acLogicalCompare(PWideChar(S1), PWideChar(S2), Length(S1), Length(S2), AIgnoreCase);
end;

function acLogicalCompare(P1, P2: PWideChar; P1Len, P2Len: Integer; AIgnoreCase: Boolean = True): Integer;
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

    AIsDigit1 := P1^.IsDigit;
    AIsDigit2 := P2^.IsDigit;
    if AIsDigit1 and AIsDigit2 then
    begin
      SL1 := 0;
      SL2 := 0;
      while (SL1 < P1Len) and (P1 + SL1)^.IsDigit do
        Inc(SL1);
      while (SL2 < P2Len) and (P2 + SL2)^.IsDigit do
        Inc(SL2);
      Result := Sign(acPWideCharToIntDef(P1, SL1, 0) - acPWideCharToIntDef(P2, SL2, 0));
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
        while (SL1 < P1Len) and not (P1 + SL1)^.IsDigit do
          Inc(SL1);
        while (SL2 < P2Len) and not (P2 + SL2)^.IsDigit do
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

function acSameText(const S1, S2: UnicodeString): Boolean;
var
  L1, L2: Integer;
begin
  L1 := Length(S1);
  L2 := Length(S2);
  Result := (L1 = L2) and (acCompareStrings(PWideChar(S1), PWideChar(S2), L1, L2) = 0);
end;

function acSameTextEx(const S: UnicodeString; const AStrs: array of UnicodeString): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Length(AStrs) - 1 do
    Result := Result or acSameText(S, AStrs[I]);
end;

// ---------------------------------------------------------------------------------------------------------------------
// acDetectEncoding
// ---------------------------------------------------------------------------------------------------------------------

function acDetectEncoding(ABuffer: PByte; ABufferSize: Integer; ADefaultEncoding: TEncoding = nil): TEncoding;
var
  ABytes: TBytes;
begin
  SetLength(ABytes, Min(ABufferSize, MaxPreambleLength));
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
    SetLength(ABytes, MaxPreambleLength);
    SetLength(ABytes, Max(0, AStream.Read(ABytes, Length(ABytes))));
    Inc(ASavedPosition, acDetectEncoding(ABytes, Result, ADefaultEncoding))
  finally
    AStream.Position := ASavedPosition;
  end;
end;

// ---------------------------------------------------------------------------------------------------------------------
// Replacing
// ---------------------------------------------------------------------------------------------------------------------

function acStringReplace(const S, OldPattern, NewPattern: string; AIgnoreCase: Boolean = False; AWholeWords: Boolean = False): string;
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
      Result := Result + Copy(S, AOffset, ALength - AOffset + 1);
      Break;
    end;
    Result := Result + Copy(S, AOffset, AOffsetNew - AOffset) + NewPattern;
    AOffset := AOffsetNew + Length(APattern);
  end;
end;

function acRemoveChar(const S: UnicodeString; const ACharToRemove: WideChar): UnicodeString;
begin
  if acPos(ACharToRemove, S) > 0 then
    Result := acStringReplace(S, ACharToRemove, '')
  else
    Result := S;
end;

function acReplaceChar(const S: UnicodeString; const ACharToReplace, AReplaceBy: WideChar): UnicodeString;
var
  P: PWideChar;
begin
  if Ord(ACharToReplace) = Ord(AReplaceBy) then
    Exit(S);
  if acPos(ACharToReplace, S) = 0 then
    Exit(S);

  Result := S;
  UniqueString(Result);
  P := PWideChar(Result);
  while Ord(P^) <> 0 do
  begin
    if Ord(P^) = Ord(ACharToReplace) then
      P^ := AReplaceBy;
    Inc(P);
  end;
end;

function acReplaceChars(const S: UnicodeString; const ACharsToReplace: UnicodeString; const AReplaceBy: WideChar = '_'): UnicodeString;
var
  I: Integer;
begin
  Result := S;
  for I := 1 to Length(S) do
  begin
    if acPos(Result[I], ACharsToReplace) > 0 then
      Result[I] := AReplaceBy;
  end;
end;

// ---------------------------------------------------------------------------------------------------------------------
// Integer <-> PWideChar
// ---------------------------------------------------------------------------------------------------------------------

function acTryPWideCharToInt(AChars: PWideChar; ACount: Integer; out AValue: Int64): Boolean;
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
    if AWord >= $FF10 then // fullwidth numbers
      ADigit := AWord - $FF10
    else
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

function acPWideCharToIntDef(AChars: PWideChar; ACount: Integer; const ADefaultValue: Int64): Int64; inline;
begin
  if not acTryPWideCharToInt(AChars, ACount, Result) then
    Result := ADefaultValue;
end;

function acDecodeLineBreaks(const S: UnicodeString): UnicodeString;
begin
  Result := acStringReplace(S, acLineBreakMacro, acCRLF);
end;

function acEncodeLineBreaks(const S: UnicodeString): UnicodeString;
begin
  Result := acReplaceLineBreaks(S, acLineBreakMacro);
end;

function acRemoveLineBreaks(const S: UnicodeString): UnicodeString;
begin
  Result := acReplaceLineBreaks(S, '');
end;

function acReplaceLineBreaks(const S, ReplaceBy: UnicodeString): UnicodeString;
begin
  Result := acStringReplace(S, acCRLF, ReplaceBy);
  Result := acStringReplace(Result, #13, ReplaceBy);
  Result := acStringReplace(Result, #10, ReplaceBy);
end;

function IfThenW(AValue: Boolean; const ATrue: UnicodeString; const AFalse: UnicodeString = ''): UnicodeString;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

function IfThenW(const A, B: UnicodeString): UnicodeString;
begin
  if A = '' then
    Result := B
  else
    Result := A;
end;

function acDupeString(const AText: UnicodeString; ACount: Integer): UnicodeString;
var
  ABuffer: TStringBuilder;
  ACapacity: Integer;
begin
  ACapacity := Length(AText) * ACount;
  if ACapacity <= 0 then
    Exit('');

  ABuffer := TACLStringBuilderManager.Get(ACapacity);
  try
    while ACount > 0 do
    begin
      ABuffer.Append(AText);
      Dec(ACount);
    end;
    Result := ABuffer.ToString;
  finally
    TACLStringBuilderManager.Release(ABuffer);
  end;
end;

function acTrim(const S: UnicodeString): UnicodeString;
var
  I, L: Integer;
begin
  I := 1;
  L := Length(S);
  while (I <= L) and (S[I] <= ' ') do Inc(I);
  while (L >= I) and (S[L] <= ' ') do Dec(L);
  Result := Copy(S, I, L - I + 1);
end;

procedure acStrLCopy(ADest: PWideChar; const ASource: UnicodeString; AMax: Integer);
begin
  FastZeroMem(ADest, AMax * SizeOf(WideChar));
  FastMove(PWideChar(ASource)^, ADest^, SizeOf(WideChar) * Min(AMax, Length(ASource)));
end;

function WStrLength(S: PWideChar; AMaxScanCount: Integer): Integer;
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

function WStrScan(Str: PWideChar; C: WideChar): PWideChar;
begin
  Result := Str;
  if Result <> nil then
    while (Ord(Result^) <> Ord(C)) do
    begin
      if Ord(Result^) = Ord(#0) then
        Exit(nil);
      Inc(Result);
    end;
end;

function WStrScan(Str: PWideChar; ACount: Integer; C: WideChar): PWideChar;
begin
  Result := Str;
  while (Result <> nil) and (Ord(Result^) <> Ord(C)) do
  begin
    Dec(ACount);
    Inc(Result);
    if ACount <= 0 then
      Exit(nil);
  end;
end;

procedure acCryptStringXOR(var S: UnicodeString; const AKey: UnicodeString);
var
  I, L: Integer;
begin
  L := Length(AKey);
  for I := 1 to Length(S) do
    S[I] := WideChar(Word(S[I]) xor Word(AKey[I mod L + 1]));
end;

{ TACLEncodings }

class constructor TACLEncodings.Create;
begin
  FMap := TACLDictionary<Integer, TEncoding>.Create([doOwnsValues]);
end;

class destructor TACLEncodings.Destroy;
begin
  FreeAndNil(FCodePages);
  FreeAndNil(FMap);
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
    EnumSystemCodePagesW(@CodePageEnumProc, CP_INSTALLED);
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
    TMonitor.Enter(FMap);
    try
      if not AMap.TryGetValue(CodePage, Result) then
      begin
        Result := TEncoding.GetEncoding(CodePage);
        AMap.Add(CodePage, Result)
      end;
    finally
      TMonitor.Exit(FMap);
    end;
  end;
end;

class function TACLEncodings.Get(const Name: string): TEncoding;
var
  AEncoding: TEncoding;
begin
  if acSameText(Name, 'utf-8') then
    Exit(TEncoding.UTF8);

  // По-хорошему, надо бы тут использовать GetCodePageFromEncodingName, но она спрятана в SysUtils.
  // Пока используем такой вот костыльный подход.
  // TODO: сделать свой аналог GetCodePageFromEncodingName
  AEncoding := TEncoding.GetEncoding(Name);
  try
    Result := Get(AEncoding.CodePage);
  finally
    AEncoding.Free;
  end;
end;

class function TACLEncodings.CodePageEnumProc(lpCodePageString: PWideChar): Cardinal; stdcall;
var
  ACodePage: Integer;
  ACodePageInfo: TCPInfoEx;
begin
  ACodePage := StrToIntDef(lpCodePageString, -1);
  if ACodePage > 0 then
  begin
    if GetCPInfoEx(ACodePage, 0, ACodePageInfo) and (ACodePageInfo.MaxCharSize = 1) then
      TACLStringList(FCodePages).Add(ACodePageInfo.CodePageName, ACodePage);
  end;
  Result := 1;
end;

{ TACLTimeFormat }

class function TACLTimeFormat.Format(const ATimeInMilliSeconds: Int64;
  AParts: TACLFormatTimeParts = [ftpSeconds..ftpHours]; ASuppressZeroValues: Boolean = True): UnicodeString;
begin
  Result := FormatEx(ATimeInMilliSeconds / 1000, AParts, ':', ASuppressZeroValues);
end;

class function TACLTimeFormat.FormatEx(ATimeInSeconds: Single;
  AParts: TACLFormatTimeParts; ASuppressZeroValues: Boolean): UnicodeString;
begin
  Result := FormatEx(ATimeInSeconds, AParts, ':', ASuppressZeroValues);
end;

class function TACLTimeFormat.FormatEx(ATimeInSeconds: Single; AParts: TACLFormatTimeParts;
  const APartDelimiter: UnicodeString = ':'; ASuppressZeroValues: Boolean = False): UnicodeString;

  procedure AppendResult(ABuffer: TStringBuilder; const APartDelimiter, AValue: UnicodeString); inline;
  begin
    if ABuffer.Length > 0 then
      ABuffer.Append(APartDelimiter);
    ABuffer.Append(AValue);
  end;

  function FormatPart(APartValue: Integer; ASuppressZeroValues: Boolean; APart: TACLFormatTimePart): UnicodeString; inline;
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
  ABuffer: TStringBuilder;
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
  ABuffer := TACLStringBuilderManager.Get(16);
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
    TACLStringBuilderManager.Release(ABuffer);
  end;
end;

class function TACLTimeFormat.FormatEx(ATimeInSeconds: Single; const AFormatString: UnicodeString): UnicodeString;

  function GetPartValue(var AParts: TStringDynArray; AIndex: Integer; const ADefaultValue: UnicodeString = ''): UnicodeString;
  begin
    if (AIndex >= 0) and (AIndex < Length(AParts)) then
      Result := AParts[AIndex]
    else
      Result := ADefaultValue;
  end;

  function GetTimeParts(const S: UnicodeString): TACLFormatTimeParts;
  const
    Map: array[TACLFormatTimePart] of WideChar = ('Z', 'S', 'M', 'H', 'D');
  var
    APart: TACLFormatTimePart;
  begin
    Result := [];
    for APart := Low(TACLFormatTimePart) to High(TACLFormatTimePart) do
    begin
      if acPos(Map[APart], S) > 0 then
        Include(Result, APart);
    end;
  end;

var
  AParts: TStringDynArray;
begin
  acExplodeString(AFormatString, ';', AParts);
  Result := FormatEx(ATimeInSeconds, GetTimeParts(GetPartValue(AParts, 0)),
    GetPartValue(AParts, 1, ':'), acPos('Z', GetPartValue(AParts, 2)) > 0);
end;

class function TACLTimeFormat.Parse(S: string; out ATimeInSeconds: Single): Boolean;

  function ExtractValue(const ADelimiters: string; var S: string; out AValue: Integer): Boolean;
  var
    ADelimPos: Integer;
  begin
    Result := False;
    ADelimPos := LastDelimiter(ADelimiters, S);
    if ADelimPos > 0 then
    begin
      Result := TryStrToInt(Copy(S, ADelimPos + 1, MaxWord), AValue);
      if Result then
        Delete(S, ADelimPos, MaxInt);
    end;
  end;

  procedure Append(AValue: Integer; AModifier: Single);
  begin
    if ATimeInSeconds < 0 then
      ATimeInSeconds := 0;
    ATimeInSeconds := ATimeInSeconds + AValue * AModifier;
  end;

var
  AValue: Integer;
begin
  ATimeInSeconds := -1; // Invalid

  if ExtractValue('.', S, AValue) then // milliseconds
    Append(AValue, 1 / 1000);

  if ExtractValue(':', S, AValue) then // seconds
  begin
    Append(AValue, 1);
    if ExtractValue(':', S, AValue) then // minutes
    begin
      Append(AValue, 60);
      Append(StrToIntDef(S, 0), 3600);
    end
    else
      Append(StrToIntDef(S, 0), 60);
  end
  else
    Append(StrToIntDef(S, 0), 1);

  Result := ATimeInSeconds >= 0;
end;

{ TACLSearchString }

constructor TACLSearchString.Create;
begin
  inherited Create;
  FEmpty := True;
  FIgnoreCase := True;
  FSeparator := ' ';
end;

constructor TACLSearchString.Create(const AMask: UnicodeString; AIgnoreCase: Boolean = True);
begin
  Create;
  IgnoreCase := AIgnoreCase;
  Value := AMask;
end;

function TACLSearchString.Compare(const S: UnicodeString): Boolean;
begin
  BeginComparing;
  AddToCompare(S);
  Result := EndComparing;
end;

procedure TACLSearchString.BeginComparing;
var
  I: Integer;
begin
  TMonitor.Enter(Self);
  for I := 0 to Length(FMaskResult) - 1 do
    FMaskResult[I] := False;
end;

procedure TACLSearchString.AddToCompare(S: UnicodeString);
var
  ACur: Integer;
  AMask: UnicodeString;
  AScan: PByte;
  ASize: Integer;
  I: Integer;
begin
  S := PrepareString(S);
  UniqueString(S);
  AScan := PByte(@S[1]);
  ASize := Length(S) * SizeOf(WideChar);
  for I := 0 to Length(FMask) - 1 do
  begin
    if not FMaskResult[I] then
    begin
      AMask := FMask[I];
      if acFindStringInMemoryW(AMask, AScan, ASize, 0, ACur) then
      begin
        FastZeroMem(AScan + ACur, Length(AMask) * SizeOf(WideChar));
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
  TMonitor.Exit(Self);
end;

function TACLSearchString.GetValueIsNumeric: Boolean;
var
  X: Integer;
begin
  Result := TryStrToInt(Value, X);
end;

function TACLSearchString.PrepareString(const AValue: UnicodeString): UnicodeString;
begin
  if IgnoreCase then
    Result := acUpperCase(AValue)
  else
    Result := AValue;
end;

procedure TACLSearchString.SetIgnoreCase(const AValue: Boolean);
begin
  if FIgnoreCase <> AValue then
  begin
    FIgnoreCase := AValue;
    Value := Value;
  end;
end;

procedure TACLSearchString.SetValue(const AValue: UnicodeString);
begin
  TMonitor.Enter(Self);
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
      acExplodeString(PrepareString(AValue), Separator, FMask);
      SetLength(FMaskResult, Length(FMask));
    end;
  finally
    TMonitor.Exit(Self);
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
      Result := ASource[ASourceIndex + 1].ToLower = ATarget[ATargetIndex + 1].ToLower;
    end,
    procedure (AIndex: Integer; AState: TDiffState)
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
    procedure (AIndex: Integer; AState: TDiffState)
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

  ADifferences := TList<TPair<Char, TDiffState>>.Create;
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
    SetLength(Result, ASourceLength + 1, ATargetLength + 1);
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

{ TACLStringBuilderHelper }

function TACLStringBuilderHelper.Append(const AValue: PWideChar; ALength: Integer): TStringBuilder;
var
  APosition: Integer;
begin
  if ALength > 0 then
  begin
    APosition := Length{$IFDEF DELPHI103RIO} + 1{$ENDIF};
    Length := Length + ALength;
    FastMove(AValue^, FData[APosition], ALength * SizeOf(WideChar));
  end;
  Result := Self;
end;

{ TACLStringBuilderManager }

class destructor TACLStringBuilderManager.Finalize;
var
  I: Integer;
begin
  for I := 0 to CacheSize - 1 do
    FreeAndNil(Cache[I]);
end;

class function TACLStringBuilderManager.Get(ACapacity: Integer): TStringBuilder;
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
    Result.Length := 0;
    ACapacity := Max(Result.Capacity, ACapacity);
    if ACapacity <> Result.Capacity then
      Result.Capacity := ACapacity
  {$IFDEF DELPHI103RIO}
    else
      UniqueString(TStringBuilderAccess(Result).FData);
  {$ENDIF}
  end
  else
    Result := TStringBuilder.Create(ACapacity);
end;

class procedure TACLStringBuilderManager.Release(var ABuilder: TStringBuilder);
var
  AIndex: Integer;
begin
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
  ABuffer: TStringBuilder;
begin
  ABuffer := TACLStringBuilderManager.Get;
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
    TACLStringBuilderManager.Release(ABuffer);
  end;
end;

function TACLAppVersion.ToString: string;
var
  ABuffer: TStringBuilder;
begin
  ABuffer := TACLStringBuilderManager.Get;
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
    TACLStringBuilderManager.Release(ABuffer);
  end;
end;

end.
