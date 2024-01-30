{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*                  Crypto                   *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Crypto;

{$I ACL.Config.inc} //FPC:OK

interface

uses
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils;

type
  { TRC4 }

  TRC4Key = record
    State: array[0..255] of Byte;
    X, Y: Integer;
  end;

  TRC4 = class
  public
    class function CryptString(const AStr: UnicodeString; const APassword: string): UnicodeString;

    class procedure Crypt(var AKey: TRC4Key; AData: PByte; ADataSize: Integer); overload; inline;
    class procedure Crypt(var AKey: TRC4Key; AInData, AOutData: PByte; ADataSize: Integer); overload;
    class procedure Initialize(out AKey: TRC4Key; APassword: PByteArray; APasswordLength: Integer); overload;
    class procedure Initialize(out AKey: TRC4Key; const APassword: string); overload;
    class procedure Initialize(out AKey: TRC4Key; const APassword: TBytes); overload;
  end;

  { TXORStream }

  TXORStream = class(TStream)
  strict private
    FBuffer: TBytes;
    FKey: TBytes;
    FKeyLength: Integer;
    FKeyOffset: Integer;
    FStream: TStream;
    FStreamOwnership: TStreamOwnership;

    procedure DoXOR(P: PByte; C: Integer);
  public
    constructor Create(const AKey: TBytes;
      AStream: TStream; AStreamOwnership: TStreamOwnership);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

function acDecryptString(const S: string; const Key: string): UnicodeString;
function acEncryptString(const S: UnicodeString; const Key: string): string;

procedure acCryptStringXOR(var S: UnicodeString; const AKey: UnicodeString);
implementation

uses
  ACL.FastCode,
  ACL.Utils.Strings;

function acDecryptString(const S: string; const Key: string): UnicodeString;
begin
  Result := TRC4.CryptString(TEncoding.Unicode.GetString(TACLMimecode.DecodeBytes(S)), Key);
end;

function acEncryptString(const S: UnicodeString; const Key: string): string;
begin
  Result := TACLMimecode.EncodeBytes(TEncoding.Unicode.GetBytes(TRC4.CryptString(S, Key)));
end;

procedure acCryptStringXOR(var S: UnicodeString; const AKey: UnicodeString);
var
  I, L: Integer;
begin
  L := Length(AKey);
  for I := 1 to Length(S) do
    S[I] := WideChar(Word(S[I]) xor Word(AKey[I mod L + 1]));
end;

{ TRC4 }

class procedure TRC4.Crypt(var AKey: TRC4Key; AData: PByte; ADataSize: Integer);
begin
  Crypt(AKey, AData, AData, ADataSize);
end;

class procedure TRC4.Crypt(var AKey: TRC4Key; AInData, AOutData: PByte; ADataSize: Integer);
var
  T, I, J: Integer;
begin
  I := AKey.X;
  J := AKey.Y;
  while ADataSize > 0 do
  begin
    I := Byte(I + 1);
    J := Byte(J + AKey.State[I]);

    T := AKey.State[I];
    AKey.State[I] := AKey.State[J];
    AKey.State[J] := T;

    T := Byte(AKey.State[I] + AKey.State[J]);
    AOutData^ := AInData^ xor AKey.State[T];

    Dec(ADataSize);
    Inc(AOutData);
    Inc(AInData);
  end;
  AKey.X := I;
  AKey.Y := J;
end;

class function TRC4.CryptString(const AStr: UnicodeString; const APassword: string): UnicodeString;
var
  LKey: TRC4Key;
begin
  if AStr <> '' then
  begin
    Initialize(LKey, APassword);
    SetLength(Result{%H-}, Length(AStr));
    Crypt(LKey, @AStr[1], @Result[1], Length(Result) * SizeOf(WideChar));
  end
  else
    Result := acEmptyStrU;
end;

class procedure TRC4.Initialize(out AKey: TRC4Key; APassword: PByteArray; APasswordLength: Integer);
var
  ATempKey: TRC4Key;
  I, J, K: Integer;
begin
  AKey.X := 0;
  AKey.Y := 0;
  for I := 0 to 255 do
  begin
    ATempKey.State[I] := APassword^[I mod APasswordLength];
    AKey.State[I] := I;
  end;

  J := 0;
  for I := 0 to 255 do
  begin
    J := (J + AKey.State[I] + ATempKey.State[I]) and $FF;
    K := AKey.State[I];
    AKey.State[I] := AKey.State[J];
    AKey.State[j] := K;
  end;
end;

class procedure TRC4.Initialize(out AKey: TRC4Key; const APassword: string);
begin
{$IFDEF UNICODE}
  Initialize(AKey, TEncoding.UTF8.GetBytes(APassword));
{$ELSE}
  Initialize(AKey, PByteArray(PAnsiChar(APassword)), Length(APassword));
{$ENDIF}
end;

class procedure TRC4.Initialize(out AKey: TRC4Key; const APassword: TBytes);
begin
  Initialize(AKey, @APassword[0], Length(APassword));
end;

{ TXORStream }

constructor TXORStream.Create(const AKey: TBytes;
  AStream: TStream; AStreamOwnership: TStreamOwnership);
begin
  FStream := AStream;
  FStreamOwnership := AStreamOwnership;
  FKey := AKey;
  FKeyLength := Length(AKey);
  FKeyOffset := FStream.Position mod FKeyLength;
  SetLength(FBuffer, 256);
end;

destructor TXORStream.Destroy;
begin
  if FStreamOwnership = soOwned then
    FreeAndNil(FStream);
  inherited;
end;

function TXORStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := FStream.Read(Buffer, Count);
  DoXOR(@Buffer, Result);
end;

function TXORStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := FStream.Seek(Offset, Origin);
  FKeyOffset := Result mod FKeyLength;
end;

function TXORStream.Write(const Buffer; Count: Longint): Longint;
var
  AScan: PByte;
  ASize: Integer;
begin
  Result := 0;
  AScan := @Buffer;
  while Count > 0 do
  begin
    ASize := Min(Count, Length(FBuffer));
    FastMove(AScan^, FBuffer[0], ASize);
    DoXOR(@FBuffer[0], ASize);
    Inc(Result, FStream.Write(FBuffer[0], ASize));
    Inc(AScan, ASize);
    Dec(Count, ASize);
  end;
end;

procedure TXORStream.DoXOR(P: PByte; C: Integer);
begin
  while C > 0 do
  begin
    P^ := P^ xor FKey[FKeyOffset];
    Inc(FKeyOffset);
    if FKeyOffset = FKeyLength then
      FKeyOffset := 0;
    Dec(C);
    Inc(P);
  end;
end;

end.
