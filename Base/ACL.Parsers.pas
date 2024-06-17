////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Parsing routines
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Parsers;

{$I ACL.Config.inc}

interface

uses
  {System.}Generics.Defaults,
  {System.}SysUtils;

const
  acParserDefaultSpaceChars = ' '#13#10#9#0;
  acParserDefaultIdentDelimiters = '%=:+-\/*;,|(){}<>[].@#$^&?!"'#39 +
    acParserDefaultSpaceChars{$IFDEF UNICODE} + '«»'#$201C#$201D{$ENDIF};
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
    Data: PChar;
    DataLength: Integer;
    TokenType: Integer;

    function Compare(const S: string; IgnoreCase: Boolean = True): Boolean;
    function StartsWith(const S: string; IgnoreCase: Boolean = True): Boolean;
    function ToString: string;
    procedure Reset;
  end;

  { TACLParser }

  TACLParser = class
  protected
    FDelimiters: PChar;
    FDelimitersLength: Integer;
    FDelimitersBuffer: string;
    FQuotes: PChar;
    FQuotesLength: Integer;
    FQuotesBuffer: string;
    FSpaces: PChar;
    FSpacesLength: Integer;
    FSpacesBuffer: string;

    FScan: PChar;
    FScanBuffer: string;
    FScanCount: Integer;

    FQuotedTextAsSingleToken: Boolean;
    FQuotedTextAsSingleTokenUnquot: Boolean;
    FSkipDelimiters: Boolean;
    FSkipQuotes: Boolean;
    FSkipSpaces: Boolean;

    function Contains(const W: Char; L: PChar; C: Integer): LongBool; inline;
    function FetchToken(var P: PChar; var C: Integer; var AToken: TACLParserToken): Boolean; virtual;
    function MoveToNext(var P: PChar; var C: Integer): Boolean; inline;
    function ShouldSkipToken(const AToken: TACLParserToken): Boolean; virtual;
  public
    constructor Create; overload;
    constructor Create(const ADelimiters: string); overload;
    constructor Create(const ADelimiters, AQuotes: string); overload;
    constructor Create(const ADelimiters, AQuotes, ASpaces: string); overload;
    procedure Initialize(const P: PChar; C: Integer); overload;
    procedure Initialize(const S: string); overload;
    // Tokens
    function GetToken(out AToken: TACLParserToken): Boolean; overload;
    function GetToken(out AToken: TACLParserToken; const ADelimiters: string): Boolean; overload;
    function GetToken(out AToken: TACLParserToken; const ADelimiters, AQuotes, ASpaces: string): Boolean; overload;
    function MoveToNextSymbol: Boolean; inline;
    // Buffer
    property Scan: PChar read FScan;
    property ScanCount: Integer read FScanCount;
    // Parser Options
    property QuotedTextAsSingleToken: Boolean read FQuotedTextAsSingleToken write FQuotedTextAsSingleToken;
    property QuotedTextAsSingleTokenUnquot: Boolean read FQuotedTextAsSingleTokenUnquot write FQuotedTextAsSingleTokenUnquot;
    property SkipDelimiters: Boolean read FSkipDelimiters write FSkipDelimiters;
    property SkipQuotes: Boolean read FSkipQuotes write FSkipQuotes;
    property SkipSpaces: Boolean read FSkipSpaces write FSkipSpaces;
  end;

  { TACLTokenComparer }

  TACLTokenComparer = class(TInterfacedObject, IEqualityComparer<string>)
  public type
    HashCode = {$IFDEF FPC}UInt32{$ELSE}Integer{$ENDIF};
  public
    // IEqualityComparer<string>
    function Equals(const Left, Right: string): Boolean; reintroduce;
    function GetHashCode(const Value: string): HashCode; reintroduce;
  end;

function acExtractLine(var P: PChar; var C: Integer; out AToken: TACLParserToken): Boolean;
function acExtractString(const S, ABeginStr, AEndStr: string): string; overload;
function acExtractString(const S, ABeginStr, AEndStr: string; out APos1, APos2: Integer): string; overload;
function acExtractString(var P: PChar; var C: Integer; out AToken: TACLParserToken; ADelimiter: Char): Boolean; overload;

function acUnquot(var AToken: TACLParserToken): Boolean; overload;
function acUnquot(var S: string): Boolean; overload;

function acCompareTokens(B1, B2: PChar; L1, L2: Integer): Boolean; overload;
function acCompareTokens(const S: string; P: PChar; L: Integer): Boolean; overload; inline;
function acCompareTokens(const S1, S2: string): Boolean; overload; inline;
implementation

uses
  ACL.Utils.Strings;

{$IFDEF FPC}
  {$WARN 4055 off : Conversion between ordinals and pointers is not portable}
{$ENDIF}

function acExtractLine(var P: PChar; var C: Integer; out AToken: TACLParserToken): Boolean;
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

function acExtractString(var P: PChar; var C: Integer; out AToken: TACLParserToken; ADelimiter: Char): Boolean;
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

function acExtractString(const S, ABeginStr, AEndStr: string): string;
var
  APos1, APos2: Integer;
begin
  Result := acExtractString(S, ABeginStr, AEndStr, APos1, APos2);
end;

function acExtractString(const S, ABeginStr, AEndStr: string; out APos1, APos2: Integer): string;
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

function acUnquot(var AToken: TACLParserToken): Boolean;
begin
  Result := False;
  if (AToken.DataLength >= 2) and acContains(AToken.Data^, acParserDefaultQuotes) then
  begin
    if PChar(NativeUInt(AToken.Data) + SizeOf(Char) * NativeUInt(AToken.DataLength - 1))^ = AToken.Data^ then
    begin
      Dec(AToken.DataLength, 2);
      Inc(AToken.Data);
      Result := True;
    end;
  end;
end;

function acUnquot(var S: string): Boolean;
var
  I, J: Integer;
begin
  Result := False;
  I := 1;
  J := Length(S);
  if J >= 2 then
  begin
    if acContains(S[I], acParserDefaultQuotes) and (S[J] = S[I]) then
    begin
      Inc(I);
      Dec(J);
    end;
    Result := (I <> 1) or (J <> Length(S));
    if Result then
      S := Copy(S, I, J - I + 1);
  end;
end;

function acCompareTokens(const S: string; P: PChar; L: Integer): Boolean; overload;
begin
  Result := acCompareTokens(PChar(S), P, L, Length(S));
end;

function acCompareTokens(const S1, S2: string): Boolean;
begin
  Result := acCompareTokens(PChar(S1), PChar(S2), Length(S1), Length(S2));
end;

function acCompareTokens(B1, B2: PChar; L1, L2: Integer): Boolean;
var
  C1, C2: Word;
begin
  Result := L1 = L2;
  if Result then
    while L1 > 0 do
    begin
      C1 := Word(B1^);
      C2 := Word(B2^);
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

constructor TACLParser.Create(const ADelimiters: string);
begin
  Create(ADelimiters, acParserDefaultQuotes);
end;

constructor TACLParser.Create(const ADelimiters, AQuotes: string);
begin
  Create(ADelimiters, AQuotes, acParserDefaultSpaceChars);
end;

constructor TACLParser.Create(const ADelimiters, AQuotes, ASpaces: string);
begin
  FQuotesBuffer := AQuotes;
  FQuotes := PChar(FQuotesBuffer);
  FQuotesLength := Length(FQuotesBuffer);

  FSpacesBuffer := ASpaces;
  FSpaces := PChar(FSpacesBuffer);
  FSpacesLength := Length(FSpacesBuffer);

  FDelimitersBuffer := ADelimiters;
  FDelimiters := PChar(FDelimitersBuffer);
  FDelimitersLength := Length(FDelimitersBuffer);

  FQuotedTextAsSingleToken := False;
  FQuotedTextAsSingleTokenUnquot := True;
  FSkipDelimiters := True;
  FSkipSpaces := True;
end;

procedure TACLParser.Initialize(const S: string);
begin
  FScanBuffer := S;
  FScan := PChar(FScanBuffer);
  FScanCount := Length(FScanBuffer);
end;

procedure TACLParser.Initialize(const P: PChar; C: Integer);
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

function TACLParser.GetToken(out AToken: TACLParserToken; const ADelimiters: string): Boolean;
var
  TB: PChar;
  TL: Integer;
begin
  TB := FDelimiters;
  TL := FDelimitersLength;
  try
    FDelimiters := PChar(ADelimiters);
    FDelimitersLength := Length(ADelimiters);
    Result := GetToken(AToken);
  finally
    FDelimitersLength := TL;
    FDelimiters := TB;
  end;
end;

function TACLParser.GetToken(out AToken: TACLParserToken;
  const ADelimiters, AQuotes, ASpaces: string): Boolean;
var
  TB1, TB2: PChar;
  TL1, TL2: Integer;
begin
  TB1 := FQuotes;
  TB2 := FSpaces;
  TL1 := FQuotesLength;
  TL2 := FSpacesLength;
  try
    FQuotes := PChar(AQuotes);
    FQuotesLength := Length(AQuotes);
    FSpaces := PChar(ASpaces);
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

function TACLParser.Contains(const W: Char; L: PChar; C: Integer): LongBool;
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

function TACLParser.FetchToken(var P: PChar; var C: Integer; var AToken: TACLParserToken): Boolean;

  procedure ExtractIdent(var AToken: TACLParserToken;
    ATokenType: Integer; ADelimiters: PChar; ADelimitersCount: Integer);
  begin
    AToken.Data := P;
    AToken.TokenType := ATokenType;
    while (C > 0) and not Contains(P^, ADelimiters, ADelimitersCount) do
    begin
      Dec(C);
      Inc(P);
    end;
    AToken.DataLength := (NativeUInt(P) - NativeUInt(AToken.Data)) div SizeOf(Char);
  end;

  procedure SetToken(var AToken: TACLParserToken;
    var P: PChar; var C: Integer; ATokenType, ATokenLength: Integer); inline;
  begin
    AToken.Data := P;
    AToken.DataLength := ATokenLength;
    AToken.TokenType := ATokenType;
    Inc(P, ATokenLength);
    Dec(C, ATokenLength);
  end;

var
  AQuot: Char;
  ASavedC: Integer;
  ASavedP: PChar;
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

function TACLParser.MoveToNext(var P: PChar; var C: Integer): Boolean;
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

function TACLParserToken.Compare(const S: string; IgnoreCase: Boolean = True): Boolean;
begin
  if Length(S) <> DataLength then
    Exit(False);
  if IgnoreCase then
    Result := acCompareStrings(Data, PChar(S), DataLength, DataLength) = 0
  else
    Result := CompareMem(Data, PChar(S), DataLength * SizeOf(Char));
end;

procedure TACLParserToken.Reset;
begin
  FillChar(Self, SizeOf(Self), 0);
end;

function TACLParserToken.StartsWith(const S: string; IgnoreCase: Boolean): Boolean;
var
  L: Integer;
begin
  L := Length(S);
  if IgnoreCase then
    Result := (DataLength >= L) and (acCompareStrings(Data, PChar(S), L, L) = 0)
  else
    Result := (DataLength >= L) and CompareMem(Data, PChar(S), L * SizeOf(Char));
end;

function TACLParserToken.ToString: string;
begin
  SetString(Result, Data, DataLength);
end;

{ TACLTokenComparer }

function TACLTokenComparer.Equals(const Left, Right: string): Boolean;
begin
  Result := acCompareTokens(Left, Right);
end;

function TACLTokenComparer.GetHashCode(const Value: string): HashCode;
var
  LChar: Char;
  LCode: Word;
  LIndex: Integer;
begin
  Result := 0;
  for LChar in Value do
  begin
    LCode := Word(LChar);
    if (LCode >= Ord('a')) and (LCode <= Ord('z')) then
      LCode := LCode xor $20;
    Result := Result shl 4 + LCode;
    LIndex := Result and $F0000000;
    Result := Result xor (LIndex shr 24);
    Result := Result and (not LIndex);
  end;
end;

end.
