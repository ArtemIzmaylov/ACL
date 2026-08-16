////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Hashing Algorithms
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Hashes;

{$I ACL.Config.inc}

interface

uses
  {System.}Classes,
  {System.}Generics.Defaults,
  {System.}Math,
  {System.}SysUtils,
  {System.}Variants,
  {System.}VarUtils,
  System.AnsiStrings,
{$IFNDEF FPC}
  System.Hash,
{$ENDIF}
  // ACL
  ACL.Classes,
  ACL.Utils.Strings;

type
  TMD5Byte16 = array[0..15] of Byte;

  { TACLHash }

  TACLHashClass = class of TACLHash;
  TACLHash = class abstract
  public
    class function Calculate(AData: PByte; ASize: Cardinal): Variant; overload; inline;
    class function Calculate(AStream: TMemoryStream): Variant; overload; inline;
    class function Calculate(AStream: TStream; AProgressEvent: TACLProgressEvent = nil): Variant; overload; inline;
    class function Calculate(const ABytes: TBytes): Variant; overload; inline;
    class function Calculate(const AText: AnsiString): Variant; overload; inline;
    class function Calculate(const AText: UnicodeString): Variant; overload; inline;
    class function Calculate(const AText: UnicodeString; AEncoding: TEncoding): Variant; overload; inline;
    class function CalculateFromFile(const AFileName: string; AProgressEvent: TACLProgressEvent = nil): Variant; inline;

    class function Finalize(var AState: Pointer): Variant; virtual; abstract;
    class procedure Initialize(out AState: Pointer); virtual; abstract;
    class procedure Reset(var AState: Pointer); virtual;
    class procedure Update(var AState: Pointer; AData: PByte; ASize: Cardinal); overload; virtual; abstract;
    class procedure Update(var AState: Pointer; AStream: TStream; AProgressEvent: TACLProgressEvent = nil); overload;
    class procedure Update(var AState: Pointer; const ABytes: TBytes); overload;
    class procedure Update(var AState: Pointer; const AText: AnsiString); overload;
    class procedure Update(var AState: Pointer; const AText: UnicodeString); overload;
    class procedure Update(var AState: Pointer; const AText: UnicodeString; AEncoding: TEncoding); overload;
    class procedure UpdateFromFile(var AState: Pointer; const AFileName: string; AProgressEvent: TACLProgressEvent = nil);
  end;

  { TACLHash32Bit }

  TACLHash32Bit = class abstract(TACLHash)
  public
    class function Finalize(var AState: Pointer): Variant; override;
    class procedure Initialize(out AState: Pointer); overload; override;
    class procedure Initialize(out AState: Pointer; ABase: Integer); reintroduce; overload;
  end;

  { TACLHashBobJenkins }

  TACLHashBobJenkins = class(TACLHash32Bit)
  strict private
  {$IFDEF FPC}
    class function GetHashValue(const Data; Len, InitVal: Integer): Integer; static;
  {$ENDIF}
  public
    class procedure Update(var AState: Pointer; AData: PByte; ASize: Cardinal); override;
  end;

  { TACLHashCRC32 }

  TACLHashCRC32 = class(TACLHash)
  public type
    PCRC32Table = ^TCRC32Table;
    TCRC32Table = array[Byte] of LongWord;
  public const
  {$REGION ' CRC_TABLE '}
    Table: TCRC32Table = (
      $00000000, $04C11DB7, $09823B6E, $0D4326D9, $130476DC, $17C56B6B,
      $1A864DB2, $1E475005, $2608EDB8, $22C9F00F, $2F8AD6D6, $2B4BCB61,
      $350C9B64, $31CD86D3, $3C8EA00A, $384FBDBD, $4C11DB70, $48D0C6C7,
      $4593E01E, $4152FDA9, $5F15ADAC, $5BD4B01B, $569796C2, $52568B75,
      $6A1936C8, $6ED82B7F, $639B0DA6, $675A1011, $791D4014, $7DDC5DA3,
      $709F7B7A, $745E66CD, $9823B6E0, $9CE2AB57, $91A18D8E, $95609039,
      $8B27C03C, $8FE6DD8B, $82A5FB52, $8664E6E5, $BE2B5B58, $BAEA46EF,
      $B7A96036, $B3687D81, $AD2F2D84, $A9EE3033, $A4AD16EA, $A06C0B5D,
      $D4326D90, $D0F37027, $DDB056FE, $D9714B49, $C7361B4C, $C3F706FB,
      $CEB42022, $CA753D95, $F23A8028, $F6FB9D9F, $FBB8BB46, $FF79A6F1,
      $E13EF6F4, $E5FFEB43, $E8BCCD9A, $EC7DD02D, $34867077, $30476DC0,
      $3D044B19, $39C556AE, $278206AB, $23431B1C, $2E003DC5, $2AC12072,
      $128E9DCF, $164F8078, $1B0CA6A1, $1FCDBB16, $018AEB13, $054BF6A4,
      $0808D07D, $0CC9CDCA, $7897AB07, $7C56B6B0, $71159069, $75D48DDE,
      $6B93DDDB, $6F52C06C, $6211E6B5, $66D0FB02, $5E9F46BF, $5A5E5B08,
      $571D7DD1, $53DC6066, $4D9B3063, $495A2DD4, $44190B0D, $40D816BA,
      $ACA5C697, $A864DB20, $A527FDF9, $A1E6E04E, $BFA1B04B, $BB60ADFC,
      $B6238B25, $B2E29692, $8AAD2B2F, $8E6C3698, $832F1041, $87EE0DF6,
      $99A95DF3, $9D684044, $902B669D, $94EA7B2A, $E0B41DE7, $E4750050,
      $E9362689, $EDF73B3E, $F3B06B3B, $F771768C, $FA325055, $FEF34DE2,
      $C6BCF05F, $C27DEDE8, $CF3ECB31, $CBFFD686, $D5B88683, $D1799B34,
      $DC3ABDED, $D8FBA05A, $690CE0EE, $6DCDFD59, $608EDB80, $644FC637,
      $7A089632, $7EC98B85, $738AAD5C, $774BB0EB, $4F040D56, $4BC510E1,
      $46863638, $42472B8F, $5C007B8A, $58C1663D, $558240E4, $51435D53,
      $251D3B9E, $21DC2629, $2C9F00F0, $285E1D47, $36194D42, $32D850F5,
      $3F9B762C, $3B5A6B9B, $0315D626, $07D4CB91, $0A97ED48, $0E56F0FF,
      $1011A0FA, $14D0BD4D, $19939B94, $1D528623, $F12F560E, $F5EE4BB9,
      $F8AD6D60, $FC6C70D7, $E22B20D2, $E6EA3D65, $EBA91BBC, $EF68060B,
      $D727BBB6, $D3E6A601, $DEA580D8, $DA649D6F, $C423CD6A, $C0E2D0DD,
      $CDA1F604, $C960EBB3, $BD3E8D7E, $B9FF90C9, $B4BCB610, $B07DABA7,
      $AE3AFBA2, $AAFBE615, $A7B8C0CC, $A379DD7B, $9B3660C6, $9FF77D71,
      $92B45BA8, $9675461F, $8832161A, $8CF30BAD, $81B02D74, $857130C3,
      $5D8A9099, $594B8D2E, $5408ABF7, $50C9B640, $4E8EE645, $4A4FFBF2,
      $470CDD2B, $43CDC09C, $7B827D21, $7F436096, $7200464F, $76C15BF8,
      $68860BFD, $6C47164A, $61043093, $65C52D24, $119B4BE9, $155A565E,
      $18197087, $1CD86D30, $029F3D35, $065E2082, $0B1D065B, $0FDC1BEC,
      $3793A651, $3352BBE6, $3E119D3F, $3AD08088, $2497D08D, $2056CD3A,
      $2D15EBE3, $29D4F654, $C5A92679, $C1683BCE, $CC2B1D17, $C8EA00A0,
      $D6AD50A5, $D26C4D12, $DF2F6BCB, $DBEE767C, $E3A1CBC1, $E760D676,
      $EA23F0AF, $EEE2ED18, $F0A5BD1D, $F464A0AA, $F9278673, $FDE69BC4,
      $89B8FD09, $8D79E0BE, $803AC667, $84FBDBD0, $9ABC8BD5, $9E7D9662,
      $933EB0BB, $97FFAD0C, $AFB010B1, $AB710D06, $A6322BDF, $A2F33668,
      $BCB4666D, $B8757BDA, $B5365D03, $B1F740B4);
  {$ENDREGION}
  strict private type
    PState = ^TState;
    TState = record
      Accumulator: LongWord;
      Table: PCRC32Table;
    end;
  public
    class function Finalize(var AState: Pointer): Variant; override;
    class procedure Initialize(out AState: Pointer); overload; override;
    class procedure Initialize(out AState: Pointer; ABase: Integer; ATable: PCRC32Table = nil); reintroduce; overload;
    class procedure Update(var AState: Pointer; AData: PByte; ASize: Cardinal); override;
    class procedure UpdateCore(var AAccumulator: LongWord; AData: PByte; ASize: Cardinal; ATable: PCRC32Table);
  end;

  { TACLHashMD5 }

  TACLHashMD5 = class(TACLHash)
  public
    class procedure Finalize(var AState: Pointer; var AHash: TMD5Byte16); reintroduce; overload;
    class function Finalize(var AState: Pointer): Variant; overload; override;
    class procedure Initialize(out AState: Pointer); override;
    class procedure Reset(var AState: Pointer); override;
    class procedure Update(var AState: Pointer; AData: PByte; ASize: Cardinal); override;
  end;

  { TACLHashSHA1 }

  TACLHashSHA1 = class(TACLHash)
  public
    class function Finalize(var AState: Pointer): Variant; override;
    class procedure Initialize(out AState: Pointer); override;
    class procedure Reset(var AState: Pointer); override;
    class procedure Update(var AState: Pointer; AData: PByte; ASize: Cardinal); override;
  end;

  { TACLHashSHA256 }

  TACLHashSHA256 = class(TACLHash)
  public
    class function Finalize(var AState: Pointer): Variant; override;
    class procedure Initialize(out AState: Pointer); override;
    class procedure Reset(var AState: Pointer); override;
    class procedure Update(var AState: Pointer; AData: PByte; ASize: Cardinal); override;
  end;

// Elf
function ElfHash(S: PChar; ACount: Integer; AIgnoryCase: Boolean): Integer; overload;
function ElfHash(const S: string; AIgnoryCase: Boolean = True): Integer; overload; inline;

function acFileNameHash(const S: string): Cardinal; inline;
function acFingerprint(AData: PByte; ASize: NativeUInt): string;
function acVariantHash(const AVariant: Variant): Cardinal;
implementation

{$R-} { Range-Checking }
{$Q-} { Overflow checking }

{$IFDEF FPC}
  {$WARN 4056 off : Conversion between ordinals and pointers is not portable}
{$ENDIF}

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
{$IFDEF FPC}
  md5,
  sha1,
  fpsha256,
  fphashutils,
{$ENDIF}
  // ACL
{$IFDEF MSWINDOWS}
  ACL.FastCode,
{$ENDIF}
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

type
{$IFDEF FPC}
  PSHA1Context = ^TSHA1Context;
{$ELSE}
  PMD5Context  = ^THashMD5;
  PSHA1Context = ^THashSHA1;
  PSHA256      = ^THashSHA2;
{$ENDIF}

function acFileNameHash(const S: string): Cardinal;
{$IFDEF MSWINDOWS}
var
  LCount: Integer;
  LPath: TFileLongPath;
{$ENDIF}
begin
  if S = '' then Exit(0);
  // тоже самое, но просто с меньшим числом вызовов
{$IFDEF MSWINDOWS}
  LCount := LCMapString(LOCALE_INVARIANT, LCMAP_LOWERCASE, PChar(S), Length(S), @LPath[0], Length(LPath));
  Result := THashBobJenkins.GetHashValue(LPath[0], LCount * SizeOf(Char), 0);
{$ELSE}
  Result := TACLHashBobJenkins.Calculate(acLowerCase(S));
{$ENDIF}
end;

function acFingerprint(AData: PByte; ASize: NativeUInt): string;
begin
  if ASize > 0 then
    Result := TACLHashMD5.Calculate(AData, ASize) + TACLHashSHA1.Calculate(AData, ASize)
  else
    Result := '';
end;

//==============================================================================
// VariantHash
//==============================================================================

function GetVarDataHash(const AData: TVarData): Cardinal;
{$IFDEF FPC}
const
  varUInt64 = varQWord;
{$ENDIF}
begin
  case AData.vtype of
    varNull:
      Result := 0;
    varEmpty:
      Result := 1;
    varBoolean:
      Result := Ord(AData.VBoolean);
    varShortInt:
      Result := AData.VShortInt;
    varByte:
      Result := AData.VByte;
    varWord:
      Result := AData.VWord;
    varLongWord:
      Result := AData.VLongWord;
    varSmallInt:
      Result := AData.VSmallInt;
    varInteger, varSingle: // 32-bit
      Result := AData.VInteger;
    varCurrency, varDouble, varDate, varInt64, varUInt64: // 64-bit
      Result := Int64Rec(AData.VInt64).Lo xor Int64Rec(AData.VInt64).Hi;
  else
    Result := ElfHash(VarToStr(Variant(AData)), False);
  end;
end;

function GetVarArrayInfo(const AVarData: TVarData; out AType: TVarType; out AArray: PVarArray): Boolean;
begin
  if AVarData.VType = varByRef or varVariant then
    Exit(GetVarArrayInfo(PVarData(AVarData.VPointer)^, AType, AArray));

  Result := AVarData.VType and varArray <> 0;
  if Result then
  begin
    AType := AVarData.VType;
    if AType and varByRef <> 0 then
      AArray := PVarArray(AVarData.VPointer^)
    else
      AArray := AVarData.VArray
  end;
end;

function GetVarArrayHash(AVarType: TVarType; AVarArray: PVarArray): Cardinal;
const
  MagicNumber = $5bd1e995;
var
  I: Integer;
  LIndex: Integer;
  LHash: Cardinal;
  LData: TVarData;
  LVarPtr: Pointer;
begin
  Result := 0;
  if AVarArray.DimCount <> 1 then
    raise Exception.Create('Wrong variant array dimension for hashing!');
  for I := AVarArray.Bounds[0].LowBound to AVarArray.Bounds[0].ElementCount -1 do
  begin
    LIndex := I;
    AVarType := AVarType and varTypeMask;
    if AVarType = varVariant then
    begin
      LVarPtr := nil;
      VarResultCheck(SafeArrayPtrOfIndex(AVarArray, @LIndex, LVarPtr));
      LHash := GetVarDataHash(PVarData(LVarPtr)^);
    end
    else
    begin
      LData.VType := AVarType;
      FillChar(LData.VBytes, SizeOf(LData.VBytes), 0);
      VarResultCheck(SafeArrayGetElement(AVarArray, @LIndex, @LData.VPointer));
      LHash := GetVarDataHash(LData);
    end;
    if AVarArray.Bounds[0].ElementCount = 1 then
      Result := LHash
    else
    begin
      LHash  := LHash xor ((LHash * MagicNumber) shr 24);
      LHash  := Cardinal(LHash * MagicNumber);
      Result := Cardinal(Result * MagicNumber) xor LHash;
    end;
  end;
end;

function acVariantHash(const AVariant: Variant): Cardinal;
var
  LVarType: TVarType;
  LVarArray: PVarArray;
begin
  if GetVarArrayInfo(TVarData(AVariant), LVarType, LVarArray) then
    Result := GetVarArrayHash(LVarType, LVarArray)
  else
    Result := GetVarDataHash(TVarData(AVariant));
end;

//==============================================================================
// ELF Hash
//==============================================================================

function ElfHash(S: PChar; ACount: Integer; AIgnoryCase: Boolean): Integer;
var
{$IFDEF MSWINDOWS}
  ABuffer: array[0..63] of WideChar;
{$ENDIF}
  LIndex: Integer;
begin
  if AIgnoryCase then
  begin
  {$IFDEF MSWINDOWS}
    if ACount > Length(ABuffer) then
  {$ENDIF}
      Exit(ElfHash(acUpperCase(acMakeString(S, ACount)), False));
  {$IFDEF MSWINDOWS}
    ACount := LCMapStringW(0, LCMAP_UPPERCASE, S, ACount, @ABuffer[0], ACount);
    S := @ABuffer[0];
  {$ENDIF}
  end;

  Result := 0;
  while ACount > 0 do
  begin
    Result := Result shl 4 + Ord(S^);
    LIndex := Result and $F0000000;
    Result := Result xor (LIndex shr 24);
    Result := Result and (not LIndex);
    Dec(ACount);
    Inc(S);
  end;
end;

function ElfHash(const S: string; AIgnoryCase: Boolean = True): Integer;
begin
{$IFNDEF MSWINDOWS}
  if AIgnoryCase then
    Exit(ElfHash(acUpperCase(S), False));
{$ENDIF}
  Result := ElfHash(PChar(S), Length(S), AIgnoryCase);
end;

{ TACLHash }

class function TACLHash.Calculate(AData: PByte; ASize: Cardinal): Variant;
var
  AState: Pointer;
begin
  Initialize(AState);
  Update(AState, AData, ASize);
  Result := Finalize(AState);
end;

class function TACLHash.Calculate(AStream: TStream; AProgressEvent: TACLProgressEvent): Variant;
var
  AState: Pointer;
begin
  Initialize(AState);
  Update(AState, AStream, AProgressEvent);
  Result := Finalize(AState);
end;

class function TACLHash.Calculate(const ABytes: TBytes): Variant;
var
  AState: Pointer;
begin
  Initialize(AState);
  Update(AState, ABytes);
  Result := Finalize(AState);
end;

class function TACLHash.Calculate(const AText: AnsiString): Variant;
var
  AState: Pointer;
begin
  Initialize(AState);
  Update(AState, AText);
  Result := Finalize(AState);
end;

class function TACLHash.Calculate(const AText: UnicodeString): Variant;
begin
  Result := Calculate(AText, TEncoding.UTF8);
end;

class function TACLHash.Calculate(const AText: UnicodeString; AEncoding: TEncoding): Variant;
var
  AState: Pointer;
begin
  Initialize(AState);
  Update(AState, AText, AEncoding);
  Result := Finalize(AState);
end;

class function TACLHash.Calculate(AStream: TMemoryStream): Variant;
begin
  Result := Calculate(AStream.Memory, AStream.Size);
end;

class function TACLHash.CalculateFromFile(
  const AFileName: string; AProgressEvent: TACLProgressEvent): Variant;
var
  AState: Pointer;
begin
  Initialize(AState);
  UpdateFromFile(AState, AFileName, AProgressEvent);
  Result := Finalize(AState);
end;

class procedure TACLHash.Reset(var AState: Pointer);
begin
  Finalize(AState);
  Initialize(AState);
end;

class procedure TACLHash.Update(var AState: Pointer; const AText: AnsiString);
begin
  if AText <> '' then
    Update(AState, PByte(PAnsiChar(AText)), Length(AText));
end;

class procedure TACLHash.Update(var AState: Pointer; const AText: UnicodeString);
begin
  Update(AState, AText, TEncoding.UTF8);
end;

class procedure TACLHash.Update(var AState: Pointer; const AText: UnicodeString; AEncoding: TEncoding);
begin
  if AText <> '' then
  begin
    if AEncoding <> nil then
      Update(AState, AEncoding.GetBytes(AText))
    else
      Update(AState, PByte(PWideChar(AText)), Length(AText) * SizeOf(WideChar));
  end;
end;

class procedure TACLHash.Update(var AState: Pointer; const ABytes: TBytes);
begin
  Update(AState, @ABytes[0], Length(ABytes));
end;

class procedure TACLHash.Update(var AState: Pointer; AStream: TStream; AProgressEvent: TACLProgressEvent);
var
  AData: array [Byte] of Byte;
  ALength: Cardinal;
  APosition: Int64;
  ASize: Int64;
begin
  ASize := AStream.Size;
  if AStream is TCustomMemoryStream then
  begin
    APosition := AStream.Position;
    Update(AState, PByte(TCustomMemoryStream(AStream).Memory) + APosition, ASize - APosition);
  end
  else
    repeat
      ALength := AStream.Read(AData{%H-}, SizeOf(AData));
      APosition := AStream.Position;
      Update(AState, @AData[0], ALength);
      CallProgressEvent(AProgressEvent, APosition, ASize);
    until APosition = ASize;
end;

class procedure TACLHash.UpdateFromFile(var AState: Pointer;
  const AFileName: string; AProgressEvent: TACLProgressEvent);
var
  AStream: TACLFileStream;
begin
  AStream := TACLFileStream.Create(AFileName, fmOpenReadOnly);
  try
    Update(AState, AStream, AProgressEvent);
  finally
    AStream.Free;
  end;
end;

{ TACLHash32Bit }

class function TACLHash32Bit.Finalize(var AState: Pointer): Variant;
begin
  Result := Integer(AState);
end;

class procedure TACLHash32Bit.Initialize(out AState: Pointer);
begin
  Initialize(AState, 0);
end;

class procedure TACLHash32Bit.Initialize(out AState: Pointer; ABase: Integer);
begin
  AState := Pointer(ABase);
end;

{ TACLHashBobJenkins }

class procedure TACLHashBobJenkins.Update(var AState: Pointer; AData: PByte; ASize: Cardinal);
begin
{$REGION ' Overflow workaround '}
  while ASize >= SIZE_ONE_GIGABYTE do
  begin
    AState := Pointer({$IFNDEF FPC}THashBobJenkins.{$ENDIF}GetHashValue(AData^, SIZE_ONE_GIGABYTE, Integer(AState)));
    Inc(AData, SIZE_ONE_GIGABYTE);
    Dec(ASize, SIZE_ONE_GIGABYTE);
  end;
{$ENDREGION}
  AState := Pointer({$IFNDEF FPC}THashBobJenkins.{$ENDIF}GetHashValue(AData^, ASize, Integer(AState)));
end;

{$IFDEF FPC}
{$REGION 'HashLittle'}
class function TACLHashBobJenkins.GetHashValue(const Data; Len, InitVal: Integer): Integer;

  function Rot(x, k: Cardinal): Cardinal; inline;
  begin
    Result := (x shl k) or (x shr (32 - k));
  end;

  procedure Mix(var a, b, c: Cardinal); inline;
  begin
    Dec(a, c); a := a xor Rot(c, 4); Inc(c, b);
    Dec(b, a); b := b xor Rot(a, 6); Inc(a, c);
    Dec(c, b); c := c xor Rot(b, 8); Inc(b, a);
    Dec(a, c); a := a xor Rot(c,16); Inc(c, b);
    Dec(b, a); b := b xor Rot(a,19); Inc(a, c);
    Dec(c, b); c := c xor Rot(b, 4); Inc(b, a);
  end;

  procedure Final(var a, b, c: Cardinal); inline;
  begin
    c := c xor b; Dec(c, Rot(b,14));
    a := a xor c; Dec(a, Rot(c,11));
    b := b xor a; Dec(b, Rot(a,25));
    c := c xor b; Dec(c, Rot(b,16));
    a := a xor c; Dec(a, Rot(c, 4));
    b := b xor a; Dec(b, Rot(a,14));
    c := c xor b; Dec(c, Rot(b,24));
  end;

{$POINTERMATH ON}
var
  pb: PByte;
  pd: PCardinal absolute pb;
  a, b, c: Cardinal;
label
  case_1, case_2, case_3, case_4, case_5, case_6,
  case_7, case_8, case_9, case_10, case_11, case_12;
begin
  a := Cardinal($DEADBEEF) + Cardinal(Len) + Cardinal(InitVal);
  b := a;
  c := a;

  pb := @Data;

  // 4-byte aligned data
  if (Cardinal(pb) and 3) = 0 then
  begin
    while Len > 12 do
    begin
      Inc(a, pd[0]);
      Inc(b, pd[1]);
      Inc(c, pd[2]);
      Mix(a, b, c);
      Dec(Len, 12);
      Inc(pd, 3);
    end;

    case Len of
      0: Exit(Integer(c));
      1: Inc(a, pd[0] and $FF);
      2: Inc(a, pd[0] and $FFFF);
      3: Inc(a, pd[0] and $FFFFFF);
      4: Inc(a, pd[0]);
      5:
      begin
        Inc(a, pd[0]);
        Inc(b, pd[1] and $FF);
      end;
      6:
      begin
        Inc(a, pd[0]);
        Inc(b, pd[1] and $FFFF);
      end;
      7:
      begin
        Inc(a, pd[0]);
        Inc(b, pd[1] and $FFFFFF);
      end;
      8:
      begin
        Inc(a, pd[0]);
        Inc(b, pd[1]);
      end;
      9:
      begin
        Inc(a, pd[0]);
        Inc(b, pd[1]);
        Inc(c, pd[2] and $FF);
      end;
      10:
      begin
        Inc(a, pd[0]);
        Inc(b, pd[1]);
        Inc(c, pd[2] and $FFFF);
      end;
      11:
      begin
        Inc(a, pd[0]);
        Inc(b, pd[1]);
        Inc(c, pd[2] and $FFFFFF);
      end;
      12:
      begin
        Inc(a, pd[0]);
        Inc(b, pd[1]);
        Inc(c, pd[2]);
      end;
    end;
  end
  else
  begin
    // Ignoring rare case of 2-byte aligned data. This handles all other cases.
    while Len > 12 do
    begin
      Inc(a, pb[0] + pb[1] shl 8 + pb[2] shl 16 + pb[3] shl 24);
      Inc(b, pb[4] + pb[5] shl 8 + pb[6] shl 16 + pb[7] shl 24);
      Inc(c, pb[8] + pb[9] shl 8 + pb[10] shl 16 + pb[11] shl 24);
      Mix(a, b, c);
      Dec(Len, 12);
      Inc(pb, 12);
    end;

    case Len of
      0: Exit(Integer(c));
      1: goto case_1;
      2: goto case_2;
      3: goto case_3;
      4: goto case_4;
      5: goto case_5;
      6: goto case_6;
      7: goto case_7;
      8: goto case_8;
      9: goto case_9;
      10: goto case_10;
      11: goto case_11;
      12: goto case_12;
    end;

case_12:
    Inc(c, pb[11] shl 24);
case_11:
    Inc(c, pb[10] shl 16);
case_10:
    Inc(c, pb[9] shl 8);
case_9:
    Inc(c, pb[8]);
case_8:
    Inc(b, pb[7] shl 24);
case_7:
    Inc(b, pb[6] shl 16);
case_6:
    Inc(b, pb[5] shl 8);
case_5:
    Inc(b, pb[4]);
case_4:
    Inc(a, pb[3] shl 24);
case_3:
    Inc(a, pb[2] shl 16);
case_2:
    Inc(a, pb[1] shl 8);
case_1:
    Inc(a, pb[0]);
  end;

  Final(a, b, c);
  Result := Integer(c);
end;
{$ENDREGION}
{$ENDIF}

{ TACLHashCRC32 }

class procedure TACLHashCRC32.Initialize(out AState: Pointer);
begin
  Initialize(AState, 0);
end;

class procedure TACLHashCRC32.Initialize(out AState: Pointer; ABase: Integer; ATable: PCRC32Table);
var
  AInternalState: PState;
begin
  if ATable = nil then
    ATable := @Table;

  New(AInternalState);
  AInternalState^.Accumulator := ABase;
  AInternalState^.Table := ATable;
  AState := AInternalState;
end;

class function TACLHashCRC32.Finalize(var AState: Pointer): Variant;
begin
  Result := PState(AState)^.Accumulator;
  FreeMemAndNil(AState);
end;

class procedure TACLHashCRC32.Update(var AState: Pointer; AData: PByte; ASize: Cardinal);
begin
  with PState(AState)^ do
    UpdateCore(Accumulator, AData, ASize, Table);
end;

class procedure TACLHashCRC32.UpdateCore(var AAccumulator: LongWord;
  AData: PByte; ASize: Cardinal; ATable: PCRC32Table);
begin
  while ASize > 0 do
  begin
    AAccumulator := (AAccumulator shl 8) xor ATable^[((AAccumulator shr 24) and $FF) xor AData^];
    Inc(AData);
    Dec(ASize);
  end;
end;

{ TACLHashMD5 }

class function TACLHashMD5.Finalize(var AState: Pointer): Variant;
{$IFDEF FPC}
var
  LHash: TMD5Digest;
begin
  MD5Final(PMD5Context(AState)^, LHash);
  Result := MD5Print(LHash);
{$ELSE}
begin
  Result := PMD5Context(AState).HashAsString;
{$ENDIF}
  FreeMemAndNil(AState);
end;

class procedure TACLHashMD5.Finalize(var AState: Pointer; var AHash: TMD5Byte16);
begin
{$IFDEF FPC}
  MD5Final(PMD5Context(AState)^, PMD5Digset(@AHash)^);
{$ELSE}
  var LBytes := PMD5Context(AState).HashAsBytes;
  Move(LBytes, AHash[0], Min(Length(LBytes), SizeOf(AHash)));
{$ENDIF}
  FreeMemAndNil(AState);
end;

class procedure TACLHashMD5.Initialize(out AState: Pointer);
var
  LContext: PMD5Context absolute AState;
begin
  New(LContext);
{$IFDEF FPC}
  MD5Init(LContext^);
{$ELSE}
  LContext^ := THashMD5.Create;
{$ENDIF}
end;

class procedure TACLHashMD5.Reset(var AState: Pointer);
begin
{$IFDEF FPC}
  MD5Init(PMD5Context(AState)^);
{$ELSE}
  PMD5Context(AState)^.Reset;
{$ENDIF}
end;

class procedure TACLHashMD5.Update(var AState: Pointer; AData: PByte; ASize: Cardinal);
begin
{$IFDEF FPC}
  MD5Update(PMD5Context(AState)^, AData^, ASize);
{$ELSE}
  PMD5Context(AState)^.Update(AData^, ASize);
{$ENDIF}
end;

{ TACLHashSHA1 }

class function TACLHashSHA1.Finalize(var AState: Pointer): Variant;
{$IFDEF FPC}
var
  LHash: TSHA1Digest;
begin
  SHA1Final(PSHA1Context(AState)^, LHash);
  Result := SHA1Print(LHash);
{$ELSE}
begin
  Result := PSHA1Context(AState)^.HashAsString;
{$ENDIF}
  FreeMemAndNil(AState);
end;

class procedure TACLHashSHA1.Initialize(out AState: Pointer);
var
  LContext: PSHA1Context absolute AState;
begin
  New(LContext);
{$IFDEF FPC}
  SHA1Init(LContext^);
{$ELSE}
  LContext^ := THashSHA1.Create;
{$ENDIF}
end;

class procedure TACLHashSHA1.Reset(var AState: Pointer);
begin
{$IFDEF FPC}
  SHA1Init(PSHA1Context(AState)^);
{$ELSE}
  PSHA1Context(AState)^.Reset;
{$ENDIF}
end;

class procedure TACLHashSHA1.Update(var AState: Pointer; AData: PByte; ASize: Cardinal);
begin
{$IFDEF FPC}
  SHA1Update(PSHA1Context(AState)^, AData^, ASize);
{$ELSE}
  PSHA1Context(AState)^.Update(AData^, ASize);
{$ENDIF}
end;

{ TACLHashSHA256 }

class function TACLHashSHA256.Finalize(var AState: Pointer): Variant;
{$IFDEF FPC}
var
  LHash: AnsiString;
begin
  PSHA256(AState)^.Final;
  BytesToHexStr(LHash, @PSHA256(AState)^.Digest[0], SHA256_DIGEST_SIZE);
  Result := acLowerCase(LHash);
{$ELSE}
begin
  Result := PSHA256(AState).HashAsString;
{$ENDIF}
  FreeMemAndNil(AState);
end;

class procedure TACLHashSHA256.Initialize(out AState: Pointer);
var
  LContext: PSHA256 absolute AState;
begin
  New(LContext);
{$IFDEF FPC}
  LContext^.Init;
{$ELSE}
  LContext^ := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
{$ENDIF}
end;

class procedure TACLHashSHA256.Reset(var AState: Pointer);
begin
  PSHA256(AState)^.{$IFDEF FPC}Init{$ELSE}Reset{$ENDIF};
end;

class procedure TACLHashSHA256.Update(var AState: Pointer; AData: PByte; ASize: Cardinal);
begin
  PSHA256(AState)^.Update(AData{$IFNDEF FPC}^{$ENDIF}, ASize);
end;

end.
