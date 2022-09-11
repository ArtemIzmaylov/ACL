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

unit ACL.Utils.Strings.Transcode;

{$I ACL.Config.inc}

interface

uses
  // System
  System.SysUtils,
  System.Types,
  System.Classes,
  // ACL
  ACL.Classes,
  ACL.Utils.Common;

type

  { TACLHexcode }

  TACLHexcode = class
  public
    class function Decode(const AChar1, AChar2: Char): Byte; overload;
    class function Decode(const AChar1, AChar2: Char; out AValue: Byte): Boolean; overload;
    class function Decode(const ACode: UnicodeString; AStream: TStream): Boolean; overload;
    class function DecodeString(const ACode: UnicodeString): UnicodeString; overload;
    class function Encode(AStream: TStream): UnicodeString; overload;
    class function Encode(B: PByte; Len: Integer): UnicodeString; overload;
    class function Encode(const AValue: Byte; out AChar1, AChar2: AnsiChar): Boolean; overload;
    class function EncodeFile(const AFileName: UnicodeString): UnicodeString; overload;
    class function EncodeString(const AValue: UnicodeString): UnicodeString; overload;
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
      065, 066, 067, 068, 069, 070, 071, 072,
      073, 074, 075, 076, 077, 078, 079, 080,
      081, 082, 083, 084, 085, 086, 087, 088,
      089, 090, 097, 098, 099, 100, 101, 102,
      103, 104, 105, 106, 107, 108, 109, 110,
      111, 112, 113, 114, 115, 116, 117, 118,
      119, 120, 121, 122, 048, 049, 050, 051,
      052, 053, 054, 055, 056, 057, 043, 047
    );
  {$ENDREGION}
  public
    class function Decode(ASrc: PByte; ASrcSize: Integer; AStream: TStream): Integer; overload;
    class function Decode(const ACode: AnsiString; AStream: TStream): Boolean; overload;
    class function DecodeBytes(const ACode: AnsiString): TBytes; overload;
    class function DecodeBytes(const ACode: UnicodeString): TBytes; overload;
    class function Encode(ASrc: PByte; ASrcSize: Integer; AStream: TStream): Integer; overload;
    class function Encode(P: PByteArray; ASize: Integer): TMemoryStream; overload;
    class function EncodeBytes(const ABytes: PAnsiChar; ACount: Integer): UnicodeString; overload;
    class function EncodeBytes(const ABytes: TBytes): UnicodeString; overload;
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
    class function Decode(Input: PByte; InputLength: Cardinal; var OutputLength: Cardinal; Output: PWordArray = nil): TACLPunycodeStatus; overload;
    class function DecodeDomain(const S: AnsiString): UnicodeString; overload;

    class function Encode(const S: UnicodeString): AnsiString; overload;
    class function Encode(const S: UnicodeString; out A: AnsiString): Boolean; overload;
    class function Encode(Input: PWordArray; InputLength: Cardinal; var OutputLength: Cardinal; Output: PByte = nil): TACLPunycodeStatus; overload;
    class function EncodeDomain(const S: UnicodeString): AnsiString; overload;
  end;

  { TACLTranslit }

  TACLTranslit = class
  public
    class function Decode(const S: UnicodeString): UnicodeString;
    class function Encode(const S: UnicodeString): UnicodeString;
  end;

implementation

uses
  System.AnsiStrings,
  System.Character,
  System.Math,
  // ACL
  ACL.FastCode,
  ACL.Hashes,
  ACL.Parsers,
  ACL.Utils.FileSystem,
  ACL.Utils.Stream,
  ACL.Utils.Strings;

const
  ColChar = 33;
  RArrayL = 'абвгдеёжзийклмнопрстуфхцчшщьыъэюя';
  Translit: array[1..ColChar] of UnicodeString = (
    'a', 'b', 'v', 'g', 'd', 'e', 'yo', 'zh', 'z', 'i', 'i''', 'k', 'l', 'm', 'n',
    'o', 'p', 'r', 's', 't', 'u', 'f', 'h', 'ts', 'ch', 'sh', 'sch', #39, 'y',
    #39, 'e', 'yu', 'ya'
  );

{ TACLHexcode }

class function TACLHexcode.Decode(const AChar1, AChar2: Char): Byte;
begin
  if not Decode(AChar1, AChar2, Result) then
    Result := 0;
end;

class function TACLHexcode.Decode(const AChar1, AChar2: Char; out AValue: Byte): Boolean;

  function TryDecode(const C: Char; out X: Byte): Boolean; inline;
  begin
    Result := True;
    case C of
      '0'..'9':
        X := Ord(C) - Ord('0');
      'A'..'F':
        X := Ord(C) - Ord('A') + 10;
      'a'..'f':
        X := Ord(C) - Ord('a') + 10;
    else
      Result := False;
    end;
  end;

var
  X1, X2: Byte;
begin
  Result := TryDecode(AChar1, X1) and TryDecode(AChar2, X2);
  if Result then
    AValue := X1 shl 4 or X2;
end;

class function TACLHexcode.Decode(const ACode: UnicodeString; AStream: TStream): Boolean;
var
  B: Byte;
  L: Integer;
  P: Int64;
  W: PWideChar;
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

class function TACLHexcode.DecodeString(const ACode: UnicodeString): UnicodeString;
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

class function TACLHexcode.Encode(B: PByte; Len: Integer): UnicodeString;
var
  AScan: PWideChar;
  C1, C2: AnsiChar;
begin
  System.SetString(Result, nil, 2 * Len);
  AScan := @Result[1];
  while Len > 0 do
  begin
    Encode(B^, C1, C2);
    AScan^ := WideChar(C1);
    Inc(AScan);
    AScan^ := WideChar(C2);
    Inc(AScan);
    Dec(Len);
    Inc(B);
  end;
end;

class function TACLHexcode.Encode(AStream: TStream): UnicodeString;
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

class function TACLHexcode.Encode(const AValue: Byte; out AChar1, AChar2: AnsiChar): Boolean;
const
  Map: array[0..15] of AnsiChar = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
begin
  AChar1 := Map[AValue shr 4];
  AChar2 := Map[AValue and $F];
  Result := True;
end;

class function TACLHexcode.EncodeString(const AValue: UnicodeString): UnicodeString;
var
  ABytes: TBytes;
begin
  ABytes := TEncoding.UTF8.GetBytes(AValue);
  Result := Encode(@ABytes[0], Length(ABytes));
end;

class function TACLHexcode.EncodeFile(const AFileName: UnicodeString): UnicodeString;
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
  Result := DecodeBytes(acAnsiFromUnicode(ACode));
end;

class function TACLMimecode.DecodeBytes(const ACode: AnsiString): TBytes;
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    Decode(ACode, AStream);
    SetLength(Result, AStream.Size);
    AStream.Position := 0;
    AStream.ReadBuffer(Result[0], Length(Result));
  finally
    AStream.Free;
  end;
end;

class function TACLMimecode.Encode(ASrc: PByte; ASrcSize: Integer; AStream: TStream): Integer;

  procedure OutputBytes(AStream: TStream; var ABank: Integer; ASize: Integer);
  var
    ABuffer: array[0..3] of Byte;
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

class function TACLMimecode.EncodeBytes(const ABytes: PAnsiChar; ACount: Integer): UnicodeString;
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

class function TACLMimecode.EncodeBytes(const ABytes: TBytes): UnicodeString;
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
  if (Decode(PByte(S), Length(S), AOutputLength) = apcOK) and (Cardinal(Length(S)) <> AOutputLength) then
  begin
    SetLength(Result, AOutputLength);
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
    procedure (ACursorStart, ACursorFinish: PAnsiChar; var ACanContinue: Boolean)
    var
      A: AnsiString;
    begin
      A := acExtractString(ACursorStart, ACursorFinish);
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
  Result := (Encode(PWordArray(S), Length(S), AOutputLength) = apcOK) and (Cardinal(Length(S) + 1) <> AOutputLength);
  if Result then
  begin
    SetLength(A, AOutputLength);
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
    procedure (ACursorStart, ACursorNext: PWideChar; var ACanContinue: Boolean)
    var
      A: AnsiString;
      U: UnicodeString;
    begin
      U := acExtractString(ACursorStart, ACursorNext);
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
    Result := -1;
    for J := 1 to ColChar do
      if acSameText(AStr, Translit[J]) then
      begin
        Result := J;
        Break;
      end;
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
