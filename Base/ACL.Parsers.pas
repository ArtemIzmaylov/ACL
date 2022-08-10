{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*             Parsers Routines              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Parsers;

{$I ACL.Config.INC}

interface

uses
  Winapi.Windows,
  // System
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Math,
  System.SysUtils;

const
  acParserDefaultSpaceChars = ' '#13#10#9#0;
  acParserDefaultIdentDelimiters = '%=:+-\/*;,|(){}<>[].@#$^&?!"«»'#39#$201C#$201D + acParserDefaultSpaceChars;
  acParserDefaultDelimiterChars = acParserDefaultIdentDelimiters + '_';
  acParserDefaultQuotes = '"'#39;

  // Token Types
  acTokenUndefined  = 0;
  acTokenSpace      = 1;
  acTokenDelimiter  = 2;
  acTokenQuot       = 3;
  acTokenQuotedText = 4;
  acTokenIdent      = 5;

  acTokenMax        = acTokenIdent;

type

  { TACLParserToken }

  TACLParserToken = record
    Context: Pointer;
    Data: PWideChar;
    DataLength: Integer;
    TokenType: Integer;

    function Compare(const S: UnicodeString; IgnoreCase: Boolean = True): Boolean;
    function StartsWith(const S: UnicodeString; IgnoreCase: Boolean = True): Boolean;
    function ToString: UnicodeString;
    procedure Reset;
  end;

  { TACLParser }

  TACLParser = class
  protected
    FDelimiters: PWideChar;
    FDelimitersLength: Integer;
    FDelimitersBuffer: UnicodeString;
    FQuotes: PWideChar;
    FQuotesLength: Integer;
    FQuotesBuffer: UnicodeString;
    FSpaces: PWideChar;
    FSpacesLength: Integer;
    FSpacesBuffer: UnicodeString;

    FScan: PWideChar;
    FScanBuffer: UnicodeString;
    FScanCount: Integer;

    FQuotedTextAsSingleToken: Boolean;
    FQuotedTextAsSingleTokenUnquot: Boolean;
    FSkipDelimiters: Boolean;
    FSkipQuotes: Boolean;
    FSkipSpaces: Boolean;

    function Contains(const W: WideChar; L: PWideChar; C: Integer): LongBool; inline;
    function FetchToken(var P: PWideChar; var C: Integer; var AToken: TACLParserToken): Boolean; virtual;
    function MoveToNext(var P: PWideChar; var C: Integer): Boolean; inline;
    function ShouldSkipToken(const AToken: TACLParserToken): Boolean; virtual;
  public
    constructor Create; overload;
    constructor Create(const ADelimiters: UnicodeString); overload;
    constructor Create(const ADelimiters, AQuotes: UnicodeString); overload;
    constructor Create(const ADelimiters, AQuotes, ASpaces: UnicodeString); overload;
    procedure Initialize(const P: PWideChar; C: Integer); overload;
    procedure Initialize(const S: UnicodeString); overload;
    // Tokens
    function GetToken(out AToken: TACLParserToken): Boolean; overload;
    function GetToken(out AToken: TACLParserToken; const ADelimiters: UnicodeString): Boolean; overload;
    function GetToken(out AToken: TACLParserToken; const ADelimiters, AQuotes, ASpaces: UnicodeString): Boolean; overload;
    function MoveToNextSymbol: Boolean; inline;
    // Buffer
    property Scan: PWideChar read FScan;
    property ScanCount: Integer read FScanCount;
    // Parser Options
    property QuotedTextAsSingleToken: Boolean read FQuotedTextAsSingleToken write FQuotedTextAsSingleToken;
    property QuotedTextAsSingleTokenUnquot: Boolean read FQuotedTextAsSingleTokenUnquot write FQuotedTextAsSingleTokenUnquot;
    property SkipDelimiters: Boolean read FSkipDelimiters write FSkipDelimiters;
    property SkipQuotes: Boolean read FSkipQuotes write FSkipQuotes;
    property SkipSpaces: Boolean read FSkipSpaces write FSkipSpaces;
  end;

function acExtractLine(var P: PWideChar; var C: Integer; out AToken: TACLParserToken): Boolean;

function acExtractString(const AScanStart, AScanNext: PAnsiChar): AnsiString; overload;
function acExtractString(const AScanStart, AScanNext: PWideChar): UnicodeString; overload;
function acExtractString(const S, ABeginStr, AEndStr: UnicodeString): UnicodeString; overload;
function acExtractString(const S, ABeginStr, AEndStr: UnicodeString; out APos1, APos2: Integer): UnicodeString; overload;
function acExtractString(var P: PWideChar; var C: Integer; out AToken: TACLParserToken; const ADelimiter: WideChar): Boolean; overload;
function acStringLength(const AScanStart, AScanNext: PAnsiChar): Integer; overload; inline;
function acStringLength(const AScanStart, AScanNext: PWideChar): Integer; overload; inline;

procedure acUnquot(var AToken: TACLParserToken); overload;
procedure acUnquot(var S: UnicodeString); overload;

function acCompareTokens(B1, B2: PWideChar; L1, L2: Integer): Boolean; overload;
function acCompareTokens(const S1, S2: UnicodeString): Boolean; overload;
implementation

uses
  ACL.Utils.Strings;

function acExtractLine(var P: PWideChar; var C: Integer; out AToken: TACLParserToken): Boolean;
begin
  AToken.Reset;
  AToken.Data := P;
  while C > 0 do
  begin
    if P^ = #13 then
    begin
      Inc(P);
      Dec(C);
      if (C > 0) and (P^ = #10) then
      begin
        Inc(P);
        Dec(C);
      end;
      Break;
    end
    else
      if P^ = #10 then
      begin
        Inc(P);
        Dec(C);
        Break;
      end;

    Inc(AToken.DataLength);
    Inc(P);
    Dec(C);
  end;
  Result := AToken.DataLength > 0;
end;

function acExtractString(const AScanStart, AScanNext: PAnsiChar): AnsiString; overload;
begin
  SetString(Result, AScanStart, acStringLength(AScanStart, AScanNext));
end;

function acExtractString(const AScanStart, AScanNext: PWideChar): UnicodeString;
begin
  SetString(Result, AScanStart, acStringLength(AScanStart, AScanNext));
end;

function acExtractString(var P: PWideChar; var C: Integer; out AToken: TACLParserToken; const ADelimiter: WideChar): Boolean;
begin
  AToken.Reset;
  AToken.Data := P;
  while C > 0 do
  begin
    if P^ = ADelimiter then
    begin
      Inc(P);
      Dec(C);
      Break;
    end;
    Inc(AToken.DataLength);
    Inc(P);
    Dec(C);
  end;
  Result := AToken.DataLength > 0;
end;

function acExtractString(const S, ABeginStr, AEndStr: UnicodeString): UnicodeString;
var
  APos1, APos2: Integer;
begin
  Result := acExtractString(S, ABeginStr, AEndStr, APos1, APos2);
end;

function acExtractString(const S, ABeginStr, AEndStr: UnicodeString; out APos1, APos2: Integer): UnicodeString;
begin
  APos1 := acPos(ABeginStr, S, True);
  if APos1 = 0 then
    Exit('');

  if AEndStr <> '' then
    APos2 := acPos(AEndStr, S, True, APos1 + Length(ABeginStr))
  else
    APos2 := Length(S) + 1;

  Result := Copy(S, APos1 + Length(ABeginStr), APos2 - APos1 - Length(ABeginStr));
end;

function acStringLength(const AScanStart, AScanNext: PAnsiChar): Integer;
begin
  if NativeUInt(AScanNext) > NativeUInt(AScanStart) then
    Result := NativeUInt(AScanNext) - NativeUInt(AScanStart)
  else
    Result := 0;
end;

function acStringLength(const AScanStart, AScanNext: PWideChar): Integer;
begin
  if NativeUInt(AScanNext) > NativeUInt(AScanStart) then
    Result := (NativeUInt(AScanNext) - NativeUInt(AScanStart)) div SizeOf(WideChar)
  else
    Result := 0;
end;

procedure acUnquot(var AToken: TACLParserToken);
begin
  if (AToken.DataLength >= 2) and (acPos(AToken.Data^, acParserDefaultQuotes) > 0) then
  begin
    if PWideChar(NativeUInt(AToken.Data) + SizeOf(WideChar) * NativeUInt(AToken.DataLength - 1))^ = AToken.Data^ then
    begin
      Dec(AToken.DataLength, 2);
      Inc(AToken.Data);
    end;
  end;
end;

procedure acUnquot(var S: UnicodeString); overload;
var
  I, J: Integer;
begin
  I := 1;
  J := Length(S);
  if J >= 2 then
  begin
    if (acPos(S[I], acParserDefaultQuotes) > 0) and (S[J] = S[I]) then
    begin
      Inc(I);
      Dec(J);
    end;
    if (I <> 1) or (J <> Length(S)) then
      S := Copy(S, I, J - I + 1);
  end;
end;

function acCompareTokens(const S1, S2: UnicodeString): Boolean;
begin
  Result := acCompareTokens(PWideChar(S1), PWideChar(S2), Length(S1), Length(S2));
end;

function acCompareTokens(B1, B2: PWideChar; L1, L2: Integer): Boolean;
var
  C1, C2: Word;
begin
  Result := L1 = L2;
  if Result then
    while L1 > 0 do
    begin
      C1 := Ord(B1^);
      C2 := Ord(B2^);
      if C1 <> C2 then
      begin
        if (C1 >= Ord('a')) and (C1 <= Ord('z')) then
          C1 := C1 xor $20;
        if (C2 >= Ord('a')) and (C2 <= Ord('z')) then
          C2 := C2 xor $20;
        if (C1 <> C2) then
          Exit(False);
      end;
      Inc(B1);
      Inc(B2);
      Dec(L1);
    end;
end;

{ TACLParser }

constructor TACLParser.Create;
begin
  Create(acParserDefaultDelimiterChars);
end;

constructor TACLParser.Create(const ADelimiters: UnicodeString);
begin
  Create(ADelimiters, acParserDefaultQuotes);
end;

constructor TACLParser.Create(const ADelimiters, AQuotes: UnicodeString);
begin
  Create(ADelimiters, AQuotes, acParserDefaultSpaceChars);
end;

constructor TACLParser.Create(const ADelimiters, AQuotes, ASpaces: UnicodeString);
begin
  FQuotesBuffer := AQuotes;
  FQuotes := PWideChar(FQuotesBuffer);
  FQuotesLength := Length(FQuotesBuffer);

  FSpacesBuffer := ASpaces;
  FSpaces := PWideChar(FSpacesBuffer);
  FSpacesLength := Length(FSpacesBuffer);

  FDelimitersBuffer := ADelimiters;
  FDelimiters := PWideChar(FDelimitersBuffer);
  FDelimitersLength := Length(FDelimitersBuffer);

  FQuotedTextAsSingleToken := False;
  FQuotedTextAsSingleTokenUnquot := True;
  FSkipDelimiters := True;
  FSkipSpaces := True;
end;

procedure TACLParser.Initialize(const S: UnicodeString);
begin
  FScanBuffer := S;
  FScan := PWideChar(FScanBuffer);
  FScanCount := Length(FScanBuffer);
end;

procedure TACLParser.Initialize(const P: PWideChar; C: Integer);
begin
  FScan := P;
  FScanCount := C;
  FScanBuffer := EmptyStr;
end;

function TACLParser.GetToken(out AToken: TACLParserToken): Boolean;
begin
  repeat
    AToken.Reset;
    Result := FetchToken(FScan, FScanCount, AToken);
  until not (Result and ShouldSkipToken(AToken));
end;

function TACLParser.GetToken(out AToken: TACLParserToken; const ADelimiters: UnicodeString): Boolean;
var
  TB: PWideChar;
  TL: Integer;
begin
  TB := FDelimiters;
  TL := FDelimitersLength;
  try
    FDelimiters := PWideChar(ADelimiters);
    FDelimitersLength := Length(ADelimiters);
    Result := GetToken(AToken);
  finally
    FDelimitersLength := TL;
    FDelimiters := TB;
  end;
end;

function TACLParser.GetToken(out AToken: TACLParserToken; const ADelimiters, AQuotes, ASpaces: UnicodeString): Boolean;
var
  TB1, TB2: PWideChar;
  TL1, TL2: Integer;
begin
  TB1 := FQuotes;
  TB2 := FSpaces;
  TL1 := FQuotesLength;
  TL2 := FSpacesLength;
  try
    FQuotes := PWideChar(AQuotes);
    FQuotesLength := Length(AQuotes);
    FSpaces := PWideChar(ASpaces);
    FSpacesLength := Length(ASpaces);
    Result := GetToken(AToken, ADelimiters);
  finally
    FSpacesLength := TL2;
    FQuotesLength := TL1;
    FSpaces := TB2;
    FQuotes := TB1;
  end;
end;

function TACLParser.MoveToNextSymbol: Boolean;
begin
  Result := MoveToNext(FScan, FScanCount);
end;

function TACLParser.Contains(const W: WideChar; L: PWideChar; C: Integer): LongBool;
begin
  Result := False;
  while C > 0 do
  begin
    Result := W = L^;
    if Result then
      Break;
    Inc(L);
    Dec(C);
  end;
end;

function TACLParser.FetchToken(var P: PWideChar; var C: Integer; var AToken: TACLParserToken): Boolean;

  procedure ExtractIdent(var AToken: TACLParserToken; ATokenType: Integer; ADelimiters: PWideChar; ADelimitersCount: Integer);
  begin
    AToken.Data := P;
    AToken.TokenType := ATokenType;
    while (C > 0) and not Contains(P^, ADelimiters, ADelimitersCount) do
    begin
      Dec(C);
      Inc(P);
    end;
    AToken.DataLength := (NativeUInt(P) - NativeUInt(AToken.Data)) div SizeOf(WideChar);
  end;

  procedure SetToken(var AToken: TACLParserToken; var P: PWideChar; var C: Integer; ATokenType, ATokenLength: Integer); inline;
  begin
    AToken.Data := P;
    AToken.DataLength := ATokenLength;
    AToken.TokenType := ATokenType;
    Inc(P, ATokenLength);
    Dec(C, ATokenLength);
  end;

var
  AQuot: WideChar;
  ASavedC: Integer;
  ASavedP: PWideChar;
begin
  if C > 0 then
  begin
    // Spaces
    if Contains(P^, FSpaces, FSpacesLength) then
      SetToken(AToken, P, C, acTokenSpace, 1)
    else

    // Quotes
    if Contains(P^, FQuotes, FQuotesLength) then
    begin
      if QuotedTextAsSingleToken then
      begin
        AQuot := P^;
        ASavedP := P;
        ASavedC := C;
        MoveToNext(P, C);
        ExtractIdent(AToken, acTokenQuotedText, @AQuot, 1);
        if C = 0 then // unterminated quoted string
        begin
          P := ASavedP;
          C := ASavedC;
          SetToken(AToken, P, C, acTokenQuot, 1);
        end
        else
        begin
          MoveToNext(P, C);
          if not QuotedTextAsSingleTokenUnquot then
          begin
            Dec(AToken.Data);
            Inc(AToken.DataLength, 2);
          end;
          Exit(True); // special for an empty strings
        end;
      end
      else
        SetToken(AToken, P, C, acTokenQuot, 1);
    end
    else

    // Delimiters
    if Contains(P^, FDelimiters, FDelimitersLength) then
      SetToken(AToken, P, C, acTokenDelimiter, 1)
    else
      ExtractIdent(AToken, acTokenIdent, FDelimiters, FDelimitersLength);
  end;
  Result := AToken.DataLength > 0;
end;

function TACLParser.MoveToNext(var P: PWideChar; var C: Integer): Boolean;
begin
  Result := C > 0;
  if Result then
  begin
    Inc(P);
    Dec(C);
  end;
end;

function TACLParser.ShouldSkipToken(const AToken: TACLParserToken): Boolean;
begin
  Result :=
    SkipQuotes and (AToken.TokenType = acTokenQuot) or
    SkipSpaces and (AToken.TokenType = acTokenSpace) or
    SkipDelimiters and (AToken.TokenType = acTokenDelimiter);
end;

{ TACLParserToken }

function TACLParserToken.Compare(const S: UnicodeString; IgnoreCase: Boolean = True): Boolean;
begin
  if Length(S) <> DataLength then
    Exit(False);
  if IgnoreCase then
    Result := acCompareStrings(Data, PWideChar(S), DataLength, DataLength) = 0
  else
    Result := CompareMem(Data, PWideChar(S), DataLength);
end;

procedure TACLParserToken.Reset;
begin
  FillChar(Self, SizeOf(Self), 0);
end;

function TACLParserToken.StartsWith(const S: UnicodeString; IgnoreCase: Boolean): Boolean;
var
  L: Integer;
begin
  L := Length(S);
  if IgnoreCase then
    Result := (DataLength >= L) and (acCompareStrings(Data, PWideChar(S), L, L) = 0)
  else
    Result := (DataLength >= L) and CompareMem(Data, PWideChar(S), L);
end;

function TACLParserToken.ToString: UnicodeString;
begin
  SetString(Result, Data, DataLength);
end;

end.
