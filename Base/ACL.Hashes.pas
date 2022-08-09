{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*            Hashing Algorithms             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Hashes;


{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.AnsiStrings,
  System.Classes,
  System.Generics.Defaults,
  System.Hash,
  System.SysUtils,
  // ACL
  ACL.Classes;

type
  TMD5Byte16 = array[0..15] of Byte;

  { TACLHash }

  TACLHashClass = class of TACLHash;
  TACLHash = class abstract
  public
    class function Calculate(AData: PByte; ASize: Integer): Variant; overload; inline;
    class function Calculate(AStream: TMemoryStream): Variant; overload; inline;
    class function Calculate(AStream: TStream; AProgressEvent: TACLProgressEvent = nil): Variant; overload; inline;
    class function Calculate(const ABytes: TBytes): Variant; overload; inline;
    class function Calculate(const AText: AnsiString): Variant; overload; inline;
    class function Calculate(const AText: UnicodeString): Variant; overload; inline;
    class function Calculate(const AText: UnicodeString; AEncoding: TEncoding): Variant; overload; inline;
    class function CalculateFromFile(const AFileName: UnicodeString; AProgressEvent: TACLProgressEvent = nil): Variant; inline;

    class function Finalize(var AState: Pointer): Variant; virtual; abstract;
    class procedure Initialize(out AState: Pointer); virtual; abstract;
    class procedure Reset(var AState: Pointer); virtual;
    class procedure Update(var AState: Pointer; AData: PByte; ASize: Integer); overload; virtual; abstract;
    class procedure Update(var AState: Pointer; AStream: TStream; AProgressEvent: TACLProgressEvent = nil); overload;
    class procedure Update(var AState: Pointer; const ABytes: TBytes); overload;
    class procedure Update(var AState: Pointer; const AText: AnsiString); overload;
    class procedure Update(var AState: Pointer; const AText: UnicodeString); overload;
    class procedure Update(var AState: Pointer; const AText: UnicodeString; AEncoding: TEncoding); overload;
    class procedure UpdateFromFile(var AState: Pointer; const AFileName: UnicodeString; AProgressEvent: TACLProgressEvent = nil);
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
  public
    class procedure Update(var AState: Pointer; AData: PByte; ASize: Integer); override;
  end;

  { TACLHashCRC32 }

  TACLHashCRC32 = class(TACLHash)
  public type
    PCRC32Table = ^TCRC32Table;
    TCRC32Table = array[Byte] of LongWord;
  public const
  {$REGION 'CRC_TABLE'}
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
    class procedure Update(var AState: Pointer; AData: PByte; ASize: Integer); override;
    class procedure UpdateCore(var AAccumulator: LongWord; AData: PByte; ASize: Integer; ATable: PCRC32Table);
  end;

  { TACLHashCryptoApiBased }

  TACLHashCryptoApiBased = class abstract(TACLHash)
  protected type
    PState = ^TState;
    TState = record
      Handle: ULONG_PTR;
      ProviderHandle: ULONG_PTR;
      Reserved: ULONG_PTR;
    end;
  protected
    class procedure CryptCheck(AResult: LongBool);
    class procedure FinalizeState(AState: Pointer); virtual;
    class function GetAlgorithmId: Cardinal; virtual; abstract;
    class function GetProviderName: PWideChar; virtual;
    class function GetProviderType: Cardinal; virtual;
  public
    class function Finalize(var AState: Pointer): Variant; overload; override;
    class procedure Finalize(var AState: Pointer; out AHash: TBytes); reintroduce; overload;
    class procedure Initialize(out AState: Pointer); override;
    class procedure Reset(var AState: Pointer); override;
    class procedure Update(var AState: Pointer; AData: PByte; ASize: Integer); override;
  end;

  { TACLHashCustomHMAC }

  TACLHashCustomHMAC = class(TACLHashCryptoApiBased)
  strict private
    class procedure CreateHashHandle(var AState: Pointer);
  protected
    class procedure FinalizeState(AState: Pointer); override;
  public
    class procedure Initialize(out AState: Pointer; AKey: TBytes); reintroduce;
    class procedure Reset(var AState: Pointer); override;
  end;

  { TACLHashHMACSHA1 }

  TACLHashHMACSHA1 = class(TACLHashCustomHMAC)
  protected
    class function GetAlgorithmId: Cardinal; override;
  end;

  { TACLHashMD5 }

  TACLHashMD5 = class(TACLHashCryptoApiBased)
  protected
    class function GetAlgorithmId: Cardinal; override;
  public
    class procedure Finalize(var AState: Pointer; var AHash: TMD5Byte16); reintroduce; overload;
  end;

  { TACLHashSHA1 }

  TACLHashSHA1 = class(TACLHashCryptoApiBased)
  protected
    class function GetAlgorithmId: Cardinal; override;
  end;

  { TACLHashSHA256 }

  TACLHashSHA256 = class(TACLHashCryptoApiBased)
  protected
    class function GetAlgorithmId: Cardinal; override;
    class function GetProviderName: PWideChar; override;
    class function GetProviderType: Cardinal; override;
  end;

  { TACLHashSHA512 }

  TACLHashSHA512 = class(TACLHashSHA256)
  protected
    class function GetAlgorithmId: Cardinal; override;
  end;

// Elf
function ElfHash(S: PWideChar; ACount: Integer; AIgnoryCase: Boolean): Integer; overload;
function ElfHash(const S: UnicodeString; AIgnoryCase: Boolean = True): Integer; overload; inline;

implementation

uses
  System.Math,
  // ACL
  ACL.FastCode,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings,
  ACL.Utils.Strings.Transcode;

{$REGION 'CryptoAPI Implemenation'}
type
  HCRYPTHASH = ULONG_PTR;
  HCRYPTKEY  = ULONG_PTR;
  HCRYPTPROV = ULONG_PTR;

  PHMACInfo = ^THMACInfo;
  THMACInfo = record
    HashAlgid: Cardinal;
    pbInnerString: PBYTE;
    cbInnerString: DWORD;
    pbOuterString: PBYTE;
    cbOuterString: DWORD;
  end;

const
  PROV_RSA_FULL      = 1;
  {$EXTERNALSYM PROV_RSA_FULL}
  PROV_RSA_SIG       = 2;
  {$EXTERNALSYM PROV_RSA_SIG}
  PROV_RSA_AES       = 24;
  {$EXTERNALSYM PROV_RSA_AES}

const
  HP_ALGID         = $0001; // Hash algorithm
  {$EXTERNALSYM HP_ALGID}
  HP_HASHVAL       = $0002; // Hash value
  {$EXTERNALSYM HP_HASHVAL}
  HP_HASHSIZE      = $0004; // Hash value size
  {$EXTERNALSYM HP_HASHSIZE}
  HP_HMAC_INFO     = $0005; // information for creating an HMAC
  {$EXTERNALSYM HP_HMAC_INFO}
  HP_TLS1PRF_LABEL = $0006; // label for TLS1 PRF
  {$EXTERNALSYM HP_TLS1PRF_LABEL}
  HP_TLS1PRF_SEED  = $0007; // seed for TLS1 PRF
  {$EXTERNALSYM HP_TLS1PRF_SEED}

  CALG_MD2	          = $00008001; //# Microsoft Base Cryptographic Provider.
  {$EXTERNALSYM CALG_MD2}
  CALG_MD4          	= $00008002;
  {$EXTERNALSYM CALG_MD4}
  CALG_MD5	          = $00008003; //# Microsoft Base Cryptographic Provider.
  {$EXTERNALSYM CALG_MD5}
  CALG_HMAC           = $00008009; //# Microsoft Base Cryptographic Provider.
  {$EXTERNALSYM CALG_HMAC}
  CALG_NO_SIGN	      = $00002000;
  {$EXTERNALSYM CALG_NO_SIGN}
  CALG_RC2	          = $00006602; //# Microsoft Base Cryptographic Provider.
  {$EXTERNALSYM CALG_RC2}
  CALG_RC4	          = $00006801; //# Microsoft Base Cryptographic Provider.
  {$EXTERNALSYM CALG_RC4}
  CALG_RC5	          = $0000660d;
  {$EXTERNALSYM CALG_RC5}
  CALG_RSA_KEYX	      = $0000a400; //# Microsoft Base Cryptographic Provider.
  {$EXTERNALSYM CALG_RSA_KEYX}
  CALG_RSA_SIGN	      = $00002400; //# Microsoft Base Cryptographic Provider.
  {$EXTERNALSYM CALG_RSA_SIGN}
  CALG_SHA	          = $00008004; //# Microsoft Base Cryptographic Provider.
  {$EXTERNALSYM CALG_SHA}
  CALG_SHA1         	= $00008004; //# Microsoft Base Cryptographic Provider.
  {$EXTERNALSYM CALG_SHA1}
  CALG_SHA_256	      = $0000800c; //# Microsoft Enhanced RSA and AES Cryptographic Provider, Windows XP with SP3 and newer
  {$EXTERNALSYM CALG_SHA_256}
  CALG_SHA_384	      = $0000800d; //# Microsoft Enhanced RSA and AES Cryptographic Provider, Windows XP with SP3 and newer
  {$EXTERNALSYM CALG_SHA_384}
  CALG_SHA_512	      = $0000800e; //# Microsoft Enhanced RSA and AES Cryptographic Provider, Windows XP with SP3 and newer
  {$EXTERNALSYM CALG_SHA_512}

function CryptCreateHash(hProv: HCRYPTPROV; Algid: Cardinal; hKey: HCRYPTKEY; dwFlags: DWORD; var phHash: HCRYPTHASH): BOOL; stdcall; external advapi32;
{$EXTERNALSYM CryptCreateHash}
function CryptHashData(hHash: HCRYPTHASH; pbData: LPBYTE; dwDataLen, dwFlags: DWORD): BOOL; stdcall; external advapi32;
{$EXTERNALSYM CryptHashData}
function CryptDestroyHash(hHash: HCRYPTHASH): BOOL; stdcall; external advapi32;
{$EXTERNALSYM CryptDestroyHash}
function CryptGetHashParam(hHash: HCRYPTHASH; dwParam: DWORD; pbData: LPBYTE; var pdwDataLen: DWORD; dwFlags: DWORD): BOOL; stdcall; external advapi32;
{$EXTERNALSYM CryptGetHashParam}
function CryptSetHashParam(hHash: HCRYPTHASH; dwParam: DWORD; pbData: LPBYTE; dwFlags: DWORD): BOOL; stdcall; external advapi32;
{$EXTERNALSYM CryptSetHashParam}
function CryptAcquireContextW(var phProv: HCRYPTPROV; pszContainer: LPCTSTR; pszProvider: LPCTSTR; dwProvType: DWORD; dwFlags: DWORD): BOOL; stdcall; external advapi32;
{$EXTERNALSYM CryptAcquireContextW}
function CryptReleaseContext(hProv: HCRYPTPROV; dwFlags: ULONG_PTR): BOOL; stdcall; external advapi32;
{$EXTERNALSYM CryptReleaseContext}
function CryptDeriveKey(hProv: HCRYPTPROV; Algid: Cardinal; hBaseData: HCRYPTHASH; dwFlags: DWORD; var phKey: HCRYPTKEY): BOOL; stdcall; external advapi32;
{$EXTERNALSYM CryptDeriveKey}
function CryptDestroyKey(hKey: HCRYPTKEY): BOOL; stdcall; external advapi32;
{$EXTERNALSYM CryptDestroyKey}
{$ENDREGION}

//==============================================================================
// ELF Hash
//==============================================================================

const
  ElfHashUpCaseBufferSize = 64;

function ElfHash(S: PWideChar; ACount: Integer; AIgnoryCase: Boolean): Integer;
var
  ABuffer: array[0..ElfHashUpCaseBufferSize - 1] of WideChar;
  AIndex: Integer;
begin
  if AIgnoryCase then
  begin
    ACount := Min(ACount, Length(ABuffer));
    ACount := LCMapStringW(0, LCMAP_UPPERCASE, S, ACount, @ABuffer[0], ACount);
    S := @ABuffer[0];
  end;

  Result := 0;
  while ACount > 0 do
  begin
    Result := Result shl 4 + Ord(S^);
    AIndex := Result and $F0000000;
    Result := Result xor (AIndex shr 24);
    Result := Result and (not AIndex);
    Dec(ACount);
    Inc(S);
  end;
end;

function ElfHash(const S: UnicodeString; AIgnoryCase: Boolean = True): Integer;
begin
  Result := ElfHash(PWideChar(S), Length(S), AIgnoryCase);
end;

{ TACLHash }

class function TACLHash.Calculate(AData: PByte; ASize: Integer): Variant;
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

class function TACLHash.CalculateFromFile(const AFileName: UnicodeString; AProgressEvent: TACLProgressEvent): Variant;
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
    Update(AState, @AText[1], Length(AText));
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
      Update(AState, PByte(PWideChar(AText)), Length(AText) * SizeOf(Char));
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
      ALength := AStream.Read(AData, SizeOf(AData));
      APosition := AStream.Position;
      Update(AState, @AData[0], ALength);
      CallProgressEvent(AProgressEvent, APosition, ASize);
    until APosition = ASize;
end;

class procedure TACLHash.UpdateFromFile(var AState: Pointer; const AFileName: UnicodeString; AProgressEvent: TACLProgressEvent);
var
  AStream: TACLFileStream;
begin
  AStream := TACLFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
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

class procedure TACLHashBobJenkins.Update(var AState: Pointer; AData: PByte; ASize: Integer);
begin
  AState := Pointer(THashBobJenkins.GetHashValue(AData^, ASize, Integer(AState)));
end;

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

class procedure TACLHashCRC32.Update(var AState: Pointer; AData: PByte; ASize: Integer);
begin
  with PState(AState)^ do
    UpdateCore(Accumulator, AData, ASize, Table);
end;

class procedure TACLHashCRC32.UpdateCore(var AAccumulator: LongWord; AData: PByte; ASize: Integer; ATable: PCRC32Table);
begin
  while ASize > 0 do
  begin
    AAccumulator := (AAccumulator shl 8) xor ATable^[((AAccumulator shr 24) and $FF) xor AData^];
    Inc(AData);
    Dec(ASize);
  end;
end;

{ TACLHashCryptoApiBased }

class procedure TACLHashCryptoApiBased.Finalize(var AState: Pointer; out AHash: TBytes);
var
  AValue, ALength: Cardinal;
begin
  try
    try
      ALength := SizeOf(AValue);
      CryptCheck(CryptGetHashParam(PState(AState).Handle, HP_HASHSIZE, @AValue, ALength, 0));

      ALength := AValue;
      SetLength(AHash, ALength);
      CryptCheck(CryptGetHashParam(PState(AState).Handle, HP_HASHVAL, @AHash[0], ALength, 0));
    finally
      FinalizeState(AState);
    end;
  finally
    FreeMemAndNil(AState);
  end;
end;

class function TACLHashCryptoApiBased.Finalize(var AState: Pointer): Variant;
var
  AHash: TBytes;
begin
  Finalize(AState, AHash);
  Result := acLowerCase(TACLHexcode.Encode(@AHash[0], Length(AHash)));
end;

class procedure TACLHashCryptoApiBased.Initialize(out AState: Pointer);
var
  AInternalState: PState;
begin
  New(AInternalState);
  try
    AState := AInternalState;
    CryptCheck(CryptAcquireContextW(AInternalState^.ProviderHandle, nil, GetProviderName, GetProviderType, $F0000000));
    CryptCheck(CryptCreateHash(AInternalState^.ProviderHandle, GetAlgorithmId, 0, 0, AInternalState^.Handle));
  except
    FreeMemAndNil(AState);
    raise;
  end;
end;

class procedure TACLHashCryptoApiBased.Reset(var AState: Pointer);
var
  AHashAlgorithm, ALength: Cardinal;
begin
  ALength := SizeOf(AHashAlgorithm);
  CryptCheck(CryptGetHashParam(PState(AState).Handle, HP_ALGID, @AHashAlgorithm, ALength, 0));
  CryptCheck(CryptDestroyHash(PState(AState).Handle));
  CryptCheck(CryptCreateHash(PState(AState).ProviderHandle, AHashAlgorithm, 0, 0, PState(AState).Handle));
end;

class procedure TACLHashCryptoApiBased.Update(var AState: Pointer; AData: PByte; ASize: Integer);
begin
  CryptCheck(CryptHashData(PState(AState).Handle, AData, ASize, 0));
end;

class function TACLHashCryptoApiBased.GetProviderName: PWideChar;
begin
  Result := nil;
end;

class function TACLHashCryptoApiBased.GetProviderType: Cardinal;
begin
  Result := PROV_RSA_FULL;
end;

class procedure TACLHashCryptoApiBased.CryptCheck(AResult: LongBool);
begin
  if not AResult then
    RaiseLastOSError;
end;

class procedure TACLHashCryptoApiBased.FinalizeState(AState: Pointer);
begin
  CryptCheck(CryptDestroyHash(PState(AState).Handle));
  CryptCheck(CryptReleaseContext(PState(AState).ProviderHandle, 0));
end;

{ TACLHashCustomHMAC }

class procedure TACLHashCustomHMAC.Initialize(out AState: Pointer; AKey: TBytes);
begin
  inherited Initialize(AState);
  Update(AState, AKey);
  CryptCheck(CryptDeriveKey(PState(AState).ProviderHandle, CALG_RC4, PState(AState).Handle, 0, PState(AState).Reserved));
  CryptCheck(CryptDestroyHash(PState(AState).Handle));
  CreateHashHandle(AState);
end;

class procedure TACLHashCustomHMAC.Reset(var AState: Pointer);
begin
  CryptCheck(CryptDestroyHash(PState(AState).Handle));
  CreateHashHandle(AState);
end;

class procedure TACLHashCustomHMAC.CreateHashHandle(var AState: Pointer);
var
  AInfo: THMACInfo;
begin
  ZeroMemory(@AInfo, SizeOf(AInfo));
  AInfo.HashAlgid := GetAlgorithmId;
  CryptCheck(CryptCreateHash(PState(AState).ProviderHandle, CALG_HMAC, PState(AState).Reserved, 0, PState(AState).Handle));
  CryptCheck(CryptSetHashParam(PState(AState).Handle, HP_HMAC_INFO, @AInfo, 0));
end;

class procedure TACLHashCustomHMAC.FinalizeState(AState: Pointer);
begin
  CryptCheck(CryptDestroyKey(PState(AState).Reserved));
  inherited;
end;

{ TACLHashHMACSHA1 }

class function TACLHashHMACSHA1.GetAlgorithmId: Cardinal;
begin
  Result := CALG_SHA1;
end;

{ TACLHashMD5 }

class procedure TACLHashMD5.Finalize(var AState: Pointer; var AHash: TMD5Byte16);
var
  AHashValue: TBytes;
begin
  Finalize(AState, AHashValue);
  Assert(SizeOf(AHash) = Length(AHashValue));
  FastMove(AHashValue[0], AHash[0], Length(AHashValue));
end;

class function TACLHashMD5.GetAlgorithmId: Cardinal;
begin
  Result := CALG_MD5;
end;

{ TACLHashSHA1 }

class function TACLHashSHA1.GetAlgorithmId: Cardinal;
begin
  Result := CALG_SHA1;
end;

{ TACLHashSHA256 }

class function TACLHashSHA256.GetAlgorithmId: Cardinal;
begin
  Result := CALG_SHA_256;
end;

class function TACLHashSHA256.GetProviderName: PWideChar;
begin
  Result := 'Microsoft Enhanced RSA and AES Cryptographic Provider';
end;

class function TACLHashSHA256.GetProviderType: Cardinal;
begin
  Result := PROV_RSA_AES;
end;

{ TACLHashSHA512 }

class function TACLHashSHA512.GetAlgorithmId: Cardinal;
begin
  Result := CALG_SHA_512;
end;

end.
