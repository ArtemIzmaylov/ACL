{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*              Stream Utilities             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.Stream;

{$I ACL.Config.inc}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
  // System
  System.Classes,
  System.SysUtils,
  System.Types,
  System.Variants,
  // ACL
  ACL.Classes,
  ACL.Classes.ByteBuffer,
  ACL.Threading,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type
  TACLStreamProc = reference to procedure (AStream: TStream);

  { EACLCannotModifyReadOnlyStream }

  EACLCannotModifyReadOnlyStream = class(EInvalidOperation)
  public
    constructor Create;
  end;

  { IACLStreamContainer }

  IACLStreamContainer = interface
  ['{41434C53-7472-6561-6D43-6F6E746E7200}']
    function Size: Int64;
    function Lock: TStream;
    procedure Unlock;
  end;

  { TACLStreamContainer }

  TACLStreamContainer = class(TInterfacedObject, IACLStreamContainer)
  strict private
    FData: TMemoryStream;
    FLock: TACLCriticalSection;
  public
    constructor Create; overload;
    constructor Create(const AStream: TStream; ASize: Integer = -1); overload;
    constructor Create(const AStreamWriteProc: TACLStreamProc); overload;
    constructor Create(const AString: string); overload;
    constructor CreateOwned(AData: TMemoryStream);
    destructor Destroy; override;
    // IACLStreamContainer
    function Size: Int64;
    function Lock: TStream;
    procedure Unlock;
  end;

  { TACLStreamWrapper }

  TACLStreamWrapper = class(TStream)
  strict private
    FSource: TStream;
    FSourceOwnership: TStreamOwnership;
  protected
    function GetSize: Int64; override;
    procedure SetSize(const NewSize: Int64); override;

    property Source: TStream read FSource;
  public
    constructor Create(ASource: TStream; ASourceOwnership: TStreamOwnership); virtual;
    destructor Destroy; override;

    function Read(var Buffer; Count: Longint): Longint; override;
    function Read(Buffer: TBytes; Offset, Count: Longint): Longint; override; final;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function Write(const Buffer; Count: LongInt): LongInt; override;
    function Write(const Buffer: TBytes; Offset, Count: Longint): Longint; override; final;

    class function Unwrap(AStream: TStream): TStream;
  end;

  { TACLBufferedStream }

  TACLBufferedStream = class(TACLStreamWrapper)
  public const
    DefaultBufferSize = 256 * SIZE_ONE_KILOBYTE;
  strict private
    FBuffer: TACLByteBuffer;
    FBufferAllocationBase: Int64;
    FBufferModified: Boolean;
    FBufferPosition: Int64;

    procedure BufferCheckSaveChanges;
    procedure BufferNextBlock;
  protected
    function GetSize: Int64; override;
  public
    constructor Create(ASource: TStream;
      ASourceOwnership: TStreamOwnership = soOwned;
      ABufferSize: Integer = DefaultBufferSize); reintroduce;
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function Write(const Buffer; Count: LongInt): LongInt; override;
  end;

  { TACLSubStream }

  TACLSubStream = class(TACLStreamWrapper)
  strict private
    FOffset: Int64;
    FPosition: Int64;
    FSize: Int64;
  protected
    function GetSize: Int64; override;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(
      ASource: TStream; const AOffset, ASize: Int64;
      ASourceOwnership: TStreamOwnership = soReference); reintroduce;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    //
    property Offset: Int64 read FOffset;
    property Size: Int64 read FSize;
  end;

  { TACLSubStreamContainer }

  TACLSubStreamContainer = class(TInterfacedObject, IACLStreamContainer)
  strict private
    FOffset: Int64;
    FSize: Int64;
    FSource: IACLStreamContainer;
    FStream: TStream;
  public
    constructor Create(ASource: IACLStreamContainer; const AOffset, ASize: Int64);
    // IACLStreamContainer
    function Size: Int64;
    function Lock: TStream;
    procedure Unlock;
  end;

  { TACLStreamHelper }

  TACLStreamHelper = class helper for TStream
  public
    procedure Assign(ASource: TStream);

    function Available: Int64; inline;
    function FindString(const S: AnsiString; AMaxSearchOffset: Cardinal = MaxWord): Boolean; overload;
    function FindString(const S: array of AnsiString;
      out AFoundString: AnsiString; AMaxSearchOffset: Cardinal = MaxWord): Boolean; overload;
    function FindStringEx(const S: array of AnsiString;
      out AFoundString: AnsiString; AMaxSearchOffset: Cardinal = MaxWord): Int64;
    procedure Insert(AData: TMemoryStream; const AInsertPosition, ADataSizeToOverride: Int64;
      AProgressEvent: TACLProgressEvent; AProgressSender: TObject = nil);
    procedure Skip(ACount: LongInt); inline;

    function ReadBoolean: Boolean; inline;
    function ReadByte: Byte; inline;
    function ReadDouble: Double; inline;
    function ReadDoubleBE: Double; inline;
    function ReadGuid: TGUID; inline;
    function ReadInt32: Integer; inline;
    function ReadInt32BE: Integer; inline;
    function ReadInt64: Int64; inline;
    function ReadInt64BE: Int64; inline;
    function ReadRect: TRect; inline;
    function ReadSingle: Single; inline;
    function ReadSize: TSize; inline;
    function ReadString(ALength: Integer): UnicodeString;
    function ReadStringA(ALength: Integer): AnsiString;
    function ReadStringWithLength: UnicodeString;
    function ReadStringWithLengthA: AnsiString;
    function ReadVariant: Variant;
    function ReadWord: Word; inline;
    function ReadWordBE: Word; inline;

    function WriteBOM(AEncoding: TEncoding): Integer; inline;
    procedure WriteBoolean(const AValue: Boolean); inline;
    procedure WriteByte(const AValue: Byte); inline;
    function WriteBytes(const ABytes: TBytes): Integer; inline;
    procedure WriteDouble(const AValue: Double); inline;
    procedure WriteGUID(const AValue: TGUID); inline;
    procedure WriteInt32(const AValue: Integer); inline;
    procedure WriteInt32BE(const AValue: Integer); inline;
    procedure WriteInt64(const AValue: Int64); inline;
    procedure WriteInt64BE(const AValue: Int64); inline;
    function WritePadding(ASize: Integer): Integer;
    procedure WriteRect(const AValue: TRect); inline;
    procedure WriteSingle(const AValue: Single); inline;
    procedure WriteSize(const AValue: TSize); inline;
    function WriteString(const S: UnicodeString; AEncoding: TEncoding = nil): Integer;
    function WriteStringA(const S: AnsiString): Integer;
    function WriteStringWithLength(const S: UnicodeString): Word;
    function WriteStringWithLengthA(const S: AnsiString): Word;
    procedure WriteVariant(const AValue: Variant);
    procedure WriteWord(const AValue: Word); inline;
    procedure WriteWordBE(const AValue: Word); inline;

    procedure BeginWriteChunk(AChunkID: Integer; out AMarkerPosition: Int64);
    procedure EndWriteChunk(var AMarkerPosition: Int64);
  end;

  { TACLMemoryStream }

  TACLMemoryStream = class(TMemoryStream)
  public
    property Capacity;
  end;

  { TACLMemoryStreamHelper }

  TACLMemoryStreamHelper = class helper for TMemoryStream
  public
    class function CopyOf(AStream: TStream): TMemoryStream; overload;
    class function CopyOf(AStream: TStream; ASize: Integer): TMemoryStream; overload;
  end;

  { TACLAnsiStringStream }

  TACLAnsiStringStream = class(TACLMemoryStream)
  strict private const
    MemoryDelta = $2000; { Must be a power of 2 }
  strict private
    FData: AnsiString;
  protected
  {$IFDEF DELPHI110ALEXANDRIA}
    function Realloc(var ANewCapacity: NativeInt): Pointer; override;
  {$ELSE}
    function Realloc(var ANewCapacity: Integer): Pointer; override;
  {$ENDIF}
  public
    constructor Create(const AData: AnsiString);
    //# Properties
    property Data: AnsiString read FData;
  end;

// Equals
function StreamEquals(const AStream1, AStream2: TStream): Boolean;

// Copy
procedure StreamCopy(ATargetStream, ASourceStream: TStream); overload;
procedure StreamCopy(ATargetStream, ASourceStream: TStream; ASize: Int64); overload;
procedure StreamCopy(ATargetStream, ASourceStream: TStream; const AOffset, ASize: Int64); overload;

// I/O Tools
function StreamCreateReader(const AFileName: UnicodeString): TStream; overload;
function StreamCreateReader(const AFileName: UnicodeString; out AStream: TStream): Boolean; overload;
function StreamCreateWriter(const AFileName: UnicodeString): TStream; overload;
function StreamCreateWriter(const AFileName: UnicodeString; out AStream: TStream): Boolean; overload;
procedure StreamLoad(AEvent: TACLStreamProc; AStreamContainer: IACLStreamContainer); overload; inline;
procedure StreamLoad(AEvent: TACLStreamProc; AStream: TStream; AFreeStream: Boolean = True); overload; inline;
function StreamLoadFromFile(AStream: TStream; const AFileName: UnicodeString): Boolean;
function StreamResourceExists(AInstance: HINST; const AResourceName: UnicodeString; AResourceType: PWideChar): Boolean;
function StreamSaveToFile(const AStream: IACLStreamContainer; const AFileName: UnicodeString): Boolean; overload;
function StreamSaveToFile(const AStream: TStream; const AFileName: UnicodeString): Boolean; overload;

// Load/Save String
function acLoadString(AStream: TStream; ADefaultEncoding: TEncoding; out AEncoding: TEncoding): UnicodeString; overload;
function acLoadString(AStream: TStream; AEncoding: TEncoding = nil): UnicodeString; overload;
function acLoadString(const AFileName: UnicodeString; AEncoding: TEncoding = nil): UnicodeString; overload;
function acSaveString(AStream: TStream; const AString: UnicodeString; AEncoding: TEncoding = nil; AWriteBOM: Boolean = True): Boolean; overload;
function acSaveString(const AFileName, AString: UnicodeString; AEncoding: TEncoding = nil; AWriteBOM: Boolean = True): Boolean; overload;
function acSaveString(const AFileName: UnicodeString; const AString: AnsiString): Boolean; overload;
implementation

uses
  System.Math,
  // ACL
  ACL.Math,
  ACL.FastCode,
  ACL.Utils.FileSystem;

const
  sErrorCannotModifyReadOnlyStream = 'You cannot modify read-only stream';
  sErrorUnsupportedVariantType = 'Unsupported Variant Type';

type
  TMemoryStreamAccess = class(TMemoryStream);

// ---------------------------------------------------------------------------------------------------------------------
// Equals
// ---------------------------------------------------------------------------------------------------------------------

function StreamEquals(const AStream1, AStream2: TStream): Boolean;
const
  BufferSize = MaxWord;
var
  ABuffer1: PByte;
  ABuffer1Remain: Integer;
  ABuffer2: PByte;
  ABuffer2Remain: Integer;
  APosition1: Int64;
  APosition2: Int64;
begin
  if AStream1 = AStream2 then
    Exit(True);
  if AStream1.Size <> AStream2.Size then
    Exit(False);

  if (AStream1 is TCustomMemoryStream) and (AStream2 is TCustomMemoryStream) then
    Exit(CompareMem(
      TCustomMemoryStream(AStream1).Memory,
      TCustomMemoryStream(AStream2).Memory,
      TCustomMemoryStream(AStream1).Size));

  Result := True;
  APosition1 := AStream1.Position;
  APosition2 := AStream2.Position;
  try
    ABuffer1 := AllocMem(BufferSize);
    ABuffer2 := AllocMem(BufferSize);
    try
      AStream1.Position := 0;
      AStream2.Position := 0;
      repeat
        ABuffer1Remain := AStream1.Read(ABuffer1^, BufferSize);
        ABuffer2Remain := AStream2.Read(ABuffer2^, BufferSize);
        if ABuffer1Remain <> ABuffer2Remain then
          Exit(False);
        if not CompareMem(ABuffer1, ABuffer2, ABuffer1Remain) then
          Exit(False);
      until (ABuffer1Remain = 0) or (ABuffer2Remain = 0);
    finally
      FreeMem(ABuffer1);
      FreeMem(ABuffer2);
    end;
  finally
    AStream1.Position := APosition1;
    AStream2.Position := APosition2;
  end;
end;

// ---------------------------------------------------------------------------------------------------------------------
// Copy
// ---------------------------------------------------------------------------------------------------------------------

procedure StreamCopy(ATargetStream, ASourceStream: TStream);
begin
  StreamCopy(ATargetStream, ASourceStream, 0, ASourceStream.Size);
end;

procedure StreamCopy(ATargetStream, ASourceStream: TStream; ASize: Int64);
const
  MaxBufferSize = $F000;
var
  ABytes: PByte;
  ABytesForRead: Integer;
  ABytesPerStep: Integer;
var
  AStreamAccess: TMemoryStreamAccess;
  ANewCapacity: Integer;
begin
  if ASize > 0 then
  begin
    if ATargetStream is TMemoryStream then
    begin
      AStreamAccess := TMemoryStreamAccess(ATargetStream);
      ANewCapacity := Max(AStreamAccess.Capacity, ASize + AStreamAccess.Size);
      if ANewCapacity > AStreamAccess.Capacity then
        AStreamAccess.Capacity := ANewCapacity;
    end;
    ABytesPerStep := Min(ASize, MaxBufferSize);
    ABytes := AllocMem(ABytesPerStep);
    try
      while ASize > 0 do
      begin
        ABytesForRead := Min(ASize, ABytesPerStep);
        ASourceStream.ReadBuffer(ABytes^, ABytesForRead);
        ATargetStream.WriteBuffer(ABytes^, ABytesForRead);
        Dec(ASize, ABytesForRead);
      end;
    finally
      FreeMem(ABytes);
    end;
  end;
end;

procedure StreamCopy(ATargetStream, ASourceStream: TStream; const AOffset, ASize: Int64);
begin
  ASourceStream.Position := AOffset;
  StreamCopy(ATargetStream, ASourceStream, ASize);
end;

// ---------------------------------------------------------------------------------------------------------------------
// I/O Tools
// ---------------------------------------------------------------------------------------------------------------------

function StreamCreateReader(const AFileName: UnicodeString; out AStream: TStream): Boolean; overload;
begin
  try
    AStream := StreamCreateReader(AFileName);
    Result := AStream <> nil;
  except
    Result := False;
  end;
end;

function StreamCreateReader(const AFileName: UnicodeString): TStream; overload;
begin
  Result := TACLBufferedFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
end;

function StreamCreateWriter(const AFileName: UnicodeString): TStream;
begin
  Result := TACLBufferedFileStream.Create(AFileName, fmCreate or fmShareDenyNone);
end;

function StreamCreateWriter(const AFileName: UnicodeString; out AStream: TStream): Boolean;
begin
  try
    AStream := StreamCreateWriter(AFileName);
    Result := AStream <> nil;
  except
    Result := False;
  end;
end;

procedure StreamLoad(AEvent: TACLStreamProc; AStreamContainer: IACLStreamContainer);
var
  AStream: TStream;
begin
  AStream := AStreamContainer.Lock;
  try
    AEvent(AStream);
  finally
    AStreamContainer.Unlock;
  end;
end;

procedure StreamLoad(AEvent: TACLStreamProc; AStream: TStream; AFreeStream: Boolean = True);
begin
  AEvent(AStream);
  if AFreeStream then
    AStream.Free;
end;

function StreamResourceExists(AInstance: HINST; const AResourceName: UnicodeString; AResourceType: PWideChar): Boolean;
begin
  Result := FindResource(AInstance, PWideChar(AResourceName), AResourceType) <> 0;
end;

function StreamLoadFromFile(AStream: TStream; const AFileName: UnicodeString): Boolean;
var
  AFileStream: TStream;
begin
  Result := StreamCreateReader(AFileName, AFileStream);
  if Result then
  try
    StreamCopy(AStream, AFileStream, AFileStream.Size);
    AStream.Position := 0;
  finally
    AFileStream.Free;
  end;
end;

function StreamSaveToFile(const AStream: IACLStreamContainer; const AFileName: UnicodeString): Boolean; overload;
var
  S: TStream;
begin
  S := AStream.Lock;
  try
    Result := StreamSaveToFile(S, AFileName);
  finally
    AStream.Unlock;
  end;
end;

function StreamSaveToFile(const AStream: TStream; const AFileName: UnicodeString): Boolean;
var
  AFileStream: TStream;
begin
  Result := StreamCreateWriter(AFileName, AFileStream);
  if Result then
  try
    StreamCopy(AFileStream, AStream, 0, AStream.Size);
  finally
    AFileStream.Free;
  end;
end;

// ---------------------------------------------------------------------------------------------------------------------
// Load/Save String
// ---------------------------------------------------------------------------------------------------------------------

function acSaveString(const AFileName: UnicodeString; const AString: AnsiString): Boolean;
var
  AStream: TStream;
begin
  Result := StreamCreateWriter(AFileName, AStream);
  if Result then
  try
    AStream.WriteStringA(AString);
  finally
    AStream.Free;
  end;
end;

function acLoadString(AStream: TStream; ADefaultEncoding: TEncoding; out AEncoding: TEncoding): UnicodeString;
var
  ABytes: TBytes;
  ASize: Cardinal;
begin
  AEncoding := acDetectEncoding(AStream, ADefaultEncoding);
  ASize := AStream.Size - AStream.Position;
  if ASize <= 0 then
    Result := ''
  else
    if AEncoding = TEncoding.Unicode then
    begin
      ASize := ASize div SizeOf(WideChar);
      SetLength(Result, ASize);
      AStream.ReadBuffer(Result[1], ASize * SizeOf(WideChar));
    end
    else
    begin
      SetLength(ABytes, ASize);
      AStream.ReadBuffer(ABytes[0], ASize);
      try
        Result := AEncoding.GetString(ABytes);
      except
        Result := TACLEncodings.Default.GetString(ABytes);
      end;
    end;
end;

function acLoadString(AStream: TStream; AEncoding: TEncoding = nil): UnicodeString;
var
  X: TEncoding;
begin
  Result := acLoadString(AStream, AEncoding, X);
end;

function acLoadString(const AFileName: UnicodeString; AEncoding: TEncoding = nil): UnicodeString;
var
  AStream: TStream;
begin
  AStream := StreamCreateReader(AFileName);
  if AStream <> nil then
  try
    Result := acLoadString(AStream, AEncoding);
  finally
    AStream.Free;
  end
  else
    Result := '';
end;

function acSaveString(AStream: TStream; const AString: UnicodeString;
  AEncoding: TEncoding = nil; AWriteBOM: Boolean = True): Boolean;
begin
  Result := True;
  if AWriteBOM then
    AStream.WriteBOM(AEncoding);
  AStream.WriteString(AString, AEncoding);
end;

function acSaveString(const AFileName, AString: UnicodeString;
  AEncoding: TEncoding = nil; AWriteBOM: Boolean = True): Boolean;
var
  AStream: TStream;
begin
  Result := StreamCreateWriter(AFileName, AStream);
  if Result then
  try
    Result := acSaveString(AStream, AString, AEncoding, AWriteBOM);
  finally
    AStream.Free;
  end;
end;

{ EACLCannotModifyReadOnlyStream }

constructor EACLCannotModifyReadOnlyStream.Create;
begin
  inherited Create(sErrorCannotModifyReadOnlyStream);
end;

{ TACLStreamContainer }

constructor TACLStreamContainer.Create;
begin
  CreateOwned(TMemoryStream.Create);
end;

constructor TACLStreamContainer.Create(const AStream: TStream; ASize: Integer);
begin
  Create;
  if ASize < 0 then
    ASize := AStream.Size - AStream.Position;
  FData.Size := ASize;
  AStream.ReadBuffer(FData.Memory^, ASize);
end;

constructor TACLStreamContainer.Create(const AStreamWriteProc: TACLStreamProc);
begin
  Create;
  AStreamWriteProc(FData);
end;

constructor TACLStreamContainer.Create(const AString: string);
begin
  Create;
  acSaveString(FData, AString);
end;

constructor TACLStreamContainer.CreateOwned(AData: TMemoryStream);
begin
  FData := AData;
  FLock := TACLCriticalSection.Create;
end;

destructor TACLStreamContainer.Destroy;
begin
  FreeAndNil(FData);
  FreeAndNil(FLock);
  inherited;
end;

function TACLStreamContainer.Lock: TStream;
begin
  FLock.Enter;
  Result := FData;
  Result.Position := 0;
end;

function TACLStreamContainer.Size: Int64;
begin
  Result := FData.Size;
end;

procedure TACLStreamContainer.Unlock;
begin
  FLock.Leave;
end;

{ TACLStreamWrapper }

constructor TACLStreamWrapper.Create(ASource: TStream; ASourceOwnership: TStreamOwnership);
begin
  FSource := ASource;
  FSourceOwnership := ASourceOwnership;
end;

destructor TACLStreamWrapper.Destroy;
begin
  if FSourceOwnership = soOwned then
    FreeAndNil(FSource);
  inherited;
end;

class function TACLStreamWrapper.Unwrap(AStream: TStream): TStream;
begin
  Result := AStream;
  while Result is TACLStreamWrapper do
    Result := TACLStreamWrapper(Result).Source;
end;

function TACLStreamWrapper.Read(var Buffer; Count: Longint): Longint;
begin
  Result := Source.Read(Buffer, Count);
end;

function TACLStreamWrapper.Read(Buffer: TBytes; Offset, Count: Longint): Longint;
begin
  Result := Read(Buffer[Offset], Count);
end;

function TACLStreamWrapper.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := Source.Seek(Offset, Origin);
end;

function TACLStreamWrapper.Write(const Buffer; Count: LongInt): LongInt;
begin
  Result := Source.Write(Buffer, Count);
end;

function TACLStreamWrapper.Write(const Buffer: TBytes; Offset, Count: Longint): Longint;
begin
  Result := Write(Buffer[Offset], Count);
end;

function TACLStreamWrapper.GetSize: Int64;
begin
  Result := Source.Size;
end;

procedure TACLStreamWrapper.SetSize(const NewSize: Int64);
begin
  Source.Size := NewSize;
end;

{ TACLBufferedStream }

constructor TACLBufferedStream.Create(ASource: TStream; ASourceOwnership: TStreamOwnership; ABufferSize: Integer);
begin
  inherited Create(ASource, ASourceOwnership);
  if ABufferSize < SIZE_ONE_KILOBYTE then
    ABufferSize := DefaultBufferSize;
  FBuffer := TACLByteBuffer.Create(ABufferSize);
  BufferNextBlock;
end;

destructor TACLBufferedStream.Destroy;
begin
  BufferCheckSaveChanges;
  FreeAndNil(FBuffer);
  inherited;
end;

function TACLBufferedStream.GetSize: Int64;
begin
  Result := inherited;
  if FBufferModified then
    Result := Max(Result, FBuffer.Used + FBufferAllocationBase);
end;

function TACLBufferedStream.Read(var Buffer; Count: Longint): Longint;

  procedure BlockRead(ADest: PByte; var ACount: LongInt);
  var
    AOffset: Integer;
    ASize: Integer;
  begin
    while ACount > 0 do
    begin
      if (FBufferPosition < FBufferAllocationBase) or (FBufferPosition >= FBuffer.Used + FBufferAllocationBase) then
      begin
        BufferNextBlock;
        if FBuffer.Used = 0 then
          Break;
      end;
      AOffset := FBufferPosition - FBufferAllocationBase;
      ASize := Min(ACount, FBuffer.Used - AOffset);
      FastMove(FBuffer.DataArr^[AOffset], ADest^, ASize);
      Inc(FBufferPosition, ASize);
      Dec(ACount, ASize);
      Inc(ADest, ASize);
    end;
  end;

begin
  Result := Count;
  BlockRead(@Buffer, Count);
  Dec(Result, Count);
end;

function TACLBufferedStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  case Origin of
    soCurrent:
      Result := FBufferPosition + Offset;
    soEnd:
      Result := Size + Offset;
    else
      Result := Offset;
  end;

  FBufferPosition := MinMax(Result, 0, Size);
  Result := FBufferPosition;
end;

function TACLBufferedStream.Write(const Buffer; Count: LongInt): LongInt;

  procedure BlockWrite(ASource: PByte; var ACount: LongInt);
  var
    AOffset: Integer;
    ASize: Integer;
  begin
    while ACount > 0 do
    begin
      if (FBufferPosition < FBufferAllocationBase) or (FBufferPosition >= FBuffer.Size + FBufferAllocationBase) then
        BufferNextBlock;
      AOffset := FBufferPosition - FBufferAllocationBase;
      ASize := Min(ACount, FBuffer.Size - AOffset);
      FastMove(ASource^, FBuffer.DataArr^[AOffset], ASize);
      FBuffer.Used := Max(FBuffer.Used, AOffset + ASize);
      FBufferModified := True;
      Inc(FBufferPosition, ASize);
      Inc(ASource, ASize);
      Dec(ACount, ASize);
    end;
  end;

begin
  Result := Count;
  BlockWrite(@Buffer, Count);
  Dec(Result, Count);
end;

procedure TACLBufferedStream.BufferCheckSaveChanges;
begin
  if FBufferModified then
  begin
    FBufferModified := False;
    Source.Position := FBufferAllocationBase;
    Source.WriteBuffer(FBuffer.Data^, FBuffer.Used);
  end;
end;

procedure TACLBufferedStream.BufferNextBlock;
begin
  BufferCheckSaveChanges;
  FBufferAllocationBase := FBufferPosition;
  Source.Position := FBufferAllocationBase;
  FBuffer.Used := Source.Read(FBuffer.Data^, FBuffer.Size);
  FBufferModified := False;
end;

{ TACLSubStream }

constructor TACLSubStream.Create(ASource: TStream; const AOffset, ASize: Int64; ASourceOwnership: TStreamOwnership = soReference);
var
  ARealSize: Int64;
begin
  inherited Create(ASource, ASourceOwnership);
  ARealSize := Source.Size;
  FOffset := Min(AOffset, ARealSize);
  FSize := Min(ASize, ARealSize - FOffset);
end;

function TACLSubStream.GetSize: Int64;
begin
  Result := FSize;
end;

function TACLSubStream.Read(var Buffer; Count: Longint): Longint;
begin
  TMonitor.Enter(Source);
  try
    Source.Position := FPosition + FOffset;
    Result := Source.Read(Buffer, Min(Count, FSize - FPosition));
    if Result > 0 then
      Inc(FPosition, Result);
  finally
    TMonitor.Exit(Source);
  end;
end;

function TACLSubStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  case Origin of
    soCurrent:
      Result := FPosition + Offset;
    soEnd:
      Result := Size + Offset;
  else
    Result := Offset;
  end;
  Result := MaxMin(Result, 0, Size);
  FPosition := Result;
end;

procedure TACLSubStream.SetSize(const NewSize: Int64);
begin
  raise EACLCannotModifyReadOnlyStream.Create;
end;

function TACLSubStream.Write(const Buffer; Count: Longint): Longint;
begin
  raise EACLCannotModifyReadOnlyStream.Create;
end;

{ TACLSubStreamContainer }

constructor TACLSubStreamContainer.Create(ASource: IACLStreamContainer; const AOffset, ASize: Int64);
begin
  FSize := ASize;
  FSource := ASource;
  FOffset := AOffset;
end;

function TACLSubStreamContainer.Lock: TStream;
begin
  FStream := TACLSubStream.Create(FSource.Lock, FOffset, FSize);
  Result := FStream;
end;

function TACLSubStreamContainer.Size: Int64;
begin
  Result := FSize;
end;

procedure TACLSubStreamContainer.Unlock;
begin
  FreeAndNil(FStream);
  FSource.Unlock;
end;

{ TACLStreamHelper }

function TACLStreamHelper.ReadBoolean: Boolean;
begin
  ReadBuffer(Result, SizeOf(Result));
end;

function TACLStreamHelper.ReadByte: Byte;
begin
  ReadBuffer(Result, SizeOf(Result));
end;

function TACLStreamHelper.ReadDouble: Double;
begin
  ReadBuffer(Result, SizeOf(Result));
end;

function TACLStreamHelper.ReadDoubleBE: Double;
var
  AValue: Int64;
begin
  AValue := ReadInt64BE;
  Result := PDouble(@AValue)^;
end;

function TACLStreamHelper.ReadGuid: TGUID;
begin
  ReadBuffer(Result, SizeOf(Result));
end;

function TACLStreamHelper.ReadInt32: Integer;
begin
  ReadBuffer(Result, SizeOf(Result));
end;

function TACLStreamHelper.ReadInt32BE: Integer;
begin
  Result := Swap32(ReadInt32);
end;

function TACLStreamHelper.ReadInt64: Int64;
begin
  ReadBuffer(Result, SizeOf(Result));
end;

function TACLStreamHelper.ReadInt64BE: Int64;
begin
  Result := Swap64(ReadInt64);
end;

function TACLStreamHelper.ReadRect: TRect;
begin
  ReadBuffer(Result, SizeOf(Result));
end;

function TACLStreamHelper.ReadSingle: Single;
begin
  ReadBuffer(Result, SizeOf(Result));
end;

function TACLStreamHelper.ReadSize: TSize;
begin
  ReadBuffer(Result, SizeOf(Result));
end;

function TACLStreamHelper.ReadString(ALength: Integer): UnicodeString;
begin
  if ALength > 0 then
  begin
    SetLength(Result, ALength);
    ReadBuffer(Result[1], SizeOf(WideChar) * ALength);
  end
  else
    Result := EmptyStr;
end;

function TACLStreamHelper.ReadStringA(ALength: Integer): AnsiString;
begin
  if ALength > 0 then
  begin
    SetLength(Result, ALength);
    ReadBuffer(Result[1], ALength);
  end
  else
    Result := EmptyAnsiStr;
end;

function TACLStreamHelper.ReadStringWithLength: UnicodeString;
var
  ALength: Word;
begin
  ALength := ReadWord;
  if ALength > 0 then
  begin
    SetLength(Result, ALength);
    ReadBuffer(PWideChar(Result)^, 2 * ALength);
  end
  else
    Result := EmptyStr;
end;

function TACLStreamHelper.ReadStringWithLengthA: AnsiString;
begin
  Result := ReadStringA(ReadWord);
end;

function TACLStreamHelper.ReadVariant: Variant;
const
  ValTtoVarT: array[TValueType] of Integer =
  (
    varNull, varError, varShortInt, varSmallInt, varInteger, varDouble, varString, varError, varBoolean,
    varBoolean, varError, varError, varString, varEmpty, varError, varSingle, varCurrency, varDate, varOleStr,
    varInt64, varError, varDouble
  );
var
  ASize: Integer;
  AValueType: TValueType;
begin
  VarClear(Result);
  AValueType := TValueType(ReadByte);
  case AValueType of
    vaNil:
      Exit;
    vaNull:
      Exit(Null);
    vaInt8:
      TVarData(Result).VShortInt := ReadByte;
    vaInt16:
      TVarData(Result).VSmallint := ReadWord;
    vaInt32:
      TVarData(Result).VInteger := ReadInt32;
    vaInt64:
      TVarData(Result).VInt64 := ReadInt64;
    vaExtended:
      TVarData(Result).VDouble := ReadDouble;
    vaSingle:
      TVarData(Result).VSingle := ReadSingle;
    vaCurrency:
      TVarData(Result).VCurrency := ReadSingle;
    vaDate:
      TVarData(Result).VDate := ReadDouble;
    vaFalse, vaTrue:
      TVarData(Result).VBoolean := AValueType = vaTrue;
    vaString:
      Exit(ReadStringWithLength);
    vaList:
      begin
        ASize := ReadVariant;
        Result := VarArrayCreate([0, ASize - 1], varVariant);
        for var I := 0 to ASize - 1 do
          Result[I] := ReadVariant;
        Exit;
      end;
  else
    raise EReadError.Create(sErrorUnsupportedVariantType);
  end;
  TVarData(Result).VType := ValTtoVarT[AValueType];
end;

function TACLStreamHelper.ReadWord: Word;
begin
  ReadBuffer(Result, SizeOf(Result));
end;

function TACLStreamHelper.ReadWordBE: Word;
begin
  Result := Swap16(ReadWord);
end;

procedure TACLStreamHelper.Assign(ASource: TStream);
begin
  Size := 0;
  StreamCopy(Self, ASource);
end;

function TACLStreamHelper.Available: Int64;
begin
  Result := Size - Position;
end;

procedure TACLStreamHelper.BeginWriteChunk(AChunkID: Integer; out AMarkerPosition: Int64);
begin
  WriteInt32(AChunkID);
  WriteInt32(0);
  AMarkerPosition := Position;
end;

procedure TACLStreamHelper.EndWriteChunk(var AMarkerPosition: Int64);
var
  AChunkSize: Int64;
begin
  AChunkSize := Position - AMarkerPosition;
  if AChunkSize >= MaxInt then
    raise EInvalidOperation.CreateFmt('StreamEndWriteChunk: %d, %d, %d', [AChunkSize, Position, AMarkerPosition]);
  Position := AMarkerPosition - SizeOf(Integer);
  WriteInt32(AChunkSize);
  Position := AMarkerPosition + AChunkSize;
end;

function TACLStreamHelper.FindString(const S: array of AnsiString; out AFoundString: AnsiString; AMaxSearchOffset: Cardinal): Boolean;
var
  APosition: Int64;
begin
  APosition := FindStringEx(S, AFoundString, AMaxSearchOffset);
  Result := APosition >= 0;
  if Result then
    Position := APosition;
end;

function TACLStreamHelper.FindString(const S: AnsiString; AMaxSearchOffset: Cardinal): Boolean;
var
  AFoundString: AnsiString;
begin
  Result := FindString([S], AFoundString, AMaxSearchOffset);
end;

function TACLStreamHelper.FindStringEx(const S: array of AnsiString; out AFoundString: AnsiString; AMaxSearchOffset: Cardinal): Int64;

  function CalculateMaxStringLength: Integer;
  var
    I: Integer;
  begin
    Result := 0;
    for I := 0 to Length(S) - 1 do
      Result := Max(Result, Length(S[I]));
    Inc(Result);
  end;

  function CalculateScanCount(ADataSize, ADataOffset: Integer): Integer;
  begin
    Result := 1 + Max(0, Integer(AMaxSearchOffset) - ADataSize) div (ADataSize - ADataOffset);
  end;

  function InternalSearchStrings(out AOffset: Integer; AData: PByteArray; ADataSize: Cardinal): Boolean;
  var
    ATempOffset: Integer;
    I: Integer;
  begin
    Result := False;
    AOffset := MaxInt;
    for I := 0 to Length(S) - 1 do
    begin
      if acFindStringInMemoryA(S[I], @AData^[0], ADataSize, 0, ATempOffset) and (ATempOffset < AOffset) then
      begin
        AOffset := ATempOffset;
        AFoundString := S[I];
        Result := True;
      end;
    end;
  end;

var
  ABlockData: PByteArray;
  ABlockSize: Cardinal;
  ADataReaded: Cardinal;
  AMaxStringLength: Cardinal;
  AOffset: Integer;
  ASavedPosition: Int64;
  AScanCount: Integer;
begin
  Result := -1;
  AMaxStringLength := CalculateMaxStringLength;
  if AMaxStringLength > 0 then
  begin
    ASavedPosition := Position;
    ABlockSize := Max(AMaxStringLength, 4096);
    ABlockData := AllocMem(ABlockSize);
    if ABlockData <> nil then
    try
      FastZeroMem(ABlockData, ABlockSize);
      AScanCount := CalculateScanCount(ABlockSize, AMaxStringLength);
      while AScanCount >= 0 do
      begin
        ADataReaded := Read(ABlockData^[AMaxStringLength], ABlockSize - AMaxStringLength);
        if InternalSearchStrings(AOffset, ABlockData, ABlockSize) then
        begin
          Result := Position - ADataReaded - AMaxStringLength + AOffset;
          Break;
        end;
        FastMove(ABlockData^[ABlockSize - AMaxStringLength - 1], ABlockData^[0], AMaxStringLength);
        Dec(AScanCount);
      end;
    finally
      Position := ASavedPosition;
      FreeMem(ABlockData);
    end;
  end;
end;

procedure TACLStreamHelper.Insert(AData: TMemoryStream; const AInsertPosition, ADataSizeToOverride: Int64;
  AProgressEvent: TACLProgressEvent; AProgressSender: TObject = nil);
const
  TempBufferSize = SIZE_ONE_MEGABYTE;

  function GetNewDataSize: Int64;
  begin
    if AData <> nil then
      Result := AData.Size
    else
      Result := 0;
  end;

  procedure Progress(const AValue, ATotal: Int64);
  begin
    try
      if Assigned(AProgressEvent) and (ATotal > 0) then
        AProgressEvent(AProgressSender, 100 * AValue / ATotal);
    except
      // do nothing
    end;
  end;

  procedure InsertSmallerBlock(AInsertPosition, ADataSizeToOverride: Int64);
  var
    AReaded, ANewSize: Integer;
    AStreamSize: Int64;
    ATempBuffer: PByte;
  begin
    ANewSize := 0;
    ATempBuffer := AllocMem(TempBufferSize);
    try
      Position := AInsertPosition;
      if GetNewDataSize > 0 then
      begin
        WriteBuffer(AData.Memory^, AData.Size);
        ANewSize := AData.Size;
      end;
      AStreamSize := Size;
      repeat
        Position := AInsertPosition + ADataSizeToOverride;
        AReaded := Read(ATempBuffer^, TempBufferSize);
        Position := AInsertPosition + ANewSize;
        WriteBuffer(ATempBuffer^, AReaded);
        Inc(AInsertPosition, AReaded);
        Progress(AInsertPosition, AStreamSize);
      until AReaded = 0;
      Size := Position;
    finally
      FreeMem(ATempBuffer);
    end;
  end;

  procedure InsertBiggerBlock(ADeltaSize: Integer);
  var
    ABytesToRead: Integer;
    ALimitPos, ATempPos, ANewTempPos: Int64;
    AStreamSize: Int64;
    ATempBuffer: PByte;
  begin
    ATempBuffer := AllocMem(TempBufferSize);
    try
      AStreamSize := Size;
      ATempPos := AStreamSize;
      ALimitPos := AInsertPosition + ADataSizeToOverride;
      repeat
        ANewTempPos := Max(ALimitPos, ATempPos - TempBufferSize);
        ABytesToRead := ATempPos - ANewTempPos;
        if ABytesToRead > 0 then
        begin
          Position := ANewTempPos;
          ReadBuffer(ATempBuffer^, ABytesToRead);
          Position := ANewTempPos + ADeltaSize;
          WriteBuffer(ATempBuffer^, ABytesToRead);
          Progress(AStreamSize - ANewTempPos, AStreamSize);
          ATempPos := ANewTempPos;
        end;
      until ATempPos = ALimitPos;
    finally
      FreeMem(ATempBuffer, TempBufferSize);
    end;
    Position := AInsertPosition;
    if GetNewDataSize > 0 then
      WriteBuffer(AData.Memory^, AData.Size);
  end;

var
  ADelta: Integer;
begin
  ADelta := GetNewDataSize - ADataSizeToOverride;
  if ADelta > 0 then
    InsertBiggerBlock(ADelta)
  else
    if ADelta < 0 then
      InsertSmallerBlock(AInsertPosition, ADataSizeToOverride)
    else
      if AData <> nil then
      begin
        Position := AInsertPosition;
        WriteBuffer(AData.Memory^, AData.Size);
      end;
end;

procedure TACLStreamHelper.Skip(ACount: LongInt);
begin
  if ACount > 0 then
    Seek(ACount, soCurrent);
end;

function TACLStreamHelper.WriteBOM(AEncoding: TEncoding): Integer;
begin
  if AEncoding = nil then
    AEncoding := TEncoding.Unicode; // #AI: Old-style behavior
  Result := WriteBytes(AEncoding.GetPreamble);
end;

procedure TACLStreamHelper.WriteBoolean(const AValue: Boolean);
begin
  WriteBuffer(AValue, SizeOf(AValue));
end;

procedure TACLStreamHelper.WriteByte(const AValue: Byte);
begin
  WriteBuffer(AValue, SizeOf(AValue));
end;

function TACLStreamHelper.WriteBytes(const ABytes: TBytes): Integer;
begin
  Result := Length(ABytes);
  if Result > 0 then
    WriteBuffer(ABytes[0], Result);
end;

procedure TACLStreamHelper.WriteDouble(const AValue: Double);
begin
  WriteBuffer(AValue, SizeOf(AValue));
end;

procedure TACLStreamHelper.WriteGUID(const AValue: TGUID);
begin
  WriteBuffer(AValue, SizeOf(AValue));
end;

procedure TACLStreamHelper.WriteInt32(const AValue: Integer);
begin
  WriteBuffer(AValue, SizeOf(AValue));
end;

procedure TACLStreamHelper.WriteInt32BE(const AValue: Integer);
begin
  WriteInt32(Swap32(AValue));
end;

procedure TACLStreamHelper.WriteInt64(const AValue: Int64);
begin
  WriteBuffer(AValue, SizeOf(AValue));
end;

procedure TACLStreamHelper.WriteInt64BE(const AValue: Int64);
begin
  WriteInt64(Swap64(AValue));
end;

function TACLStreamHelper.WritePadding(ASize: Integer): Integer;
var
  P: Pointer;
begin
  if ASize > 0 then
  begin
    P := AllocMem(ASize);
    try
      FastZeroMem(P, ASize);
      WriteBuffer(P^, ASize);
    finally
      FreeMem(P, ASize);
    end;
  end;
  Result := ASize;
end;

procedure TACLStreamHelper.WriteRect(const AValue: TRect);
begin
  WriteBuffer(AValue, SizeOf(AValue));
end;

procedure TACLStreamHelper.WriteSingle(const AValue: Single);
begin
  WriteBuffer(AValue, SizeOf(AValue));
end;

procedure TACLStreamHelper.WriteSize(const AValue: TSize);
begin
  WriteBuffer(AValue, SizeOf(AValue));
end;

function TACLStreamHelper.WriteString(const S: UnicodeString; AEncoding: TEncoding): Integer;
begin
  if AEncoding <> nil then
    Result := WriteBytes(AEncoding.GetBytes(S))
  else
  begin
    Result := Length(S) * SizeOf(WideChar);
    if Result > 0 then
      WriteBuffer(S[1], Result);
  end;
end;

function TACLStreamHelper.WriteStringA(const S: AnsiString): Integer;
begin
  Result := Length(S);
  if Result > 0 then
    WriteBuffer(S[1], Result);
end;

function TACLStreamHelper.WriteStringWithLength(const S: UnicodeString): Word;
var
  ALength: Word;
begin
  ALength := Length(S);
  WriteWord(ALength);
  if ALength > 0 then
    WriteBuffer(PWideChar(S)^, 2 * ALength);
  Result := 2 * ALength + SizeOf(ALength);
end;

function TACLStreamHelper.WriteStringWithLengthA(const S: AnsiString): Word;
begin
  Result := Length(S);
  WriteWord(Result);
  if Result > 0 then
    WriteBuffer(S[1], Result);
  Inc(Result, SizeOf(Result));
end;

procedure TACLStreamHelper.WriteVariant(const AValue: Variant);

  procedure WriteValueType(Value: TValueType);
  begin
    WriteByte(Ord(Value));
  end;

  procedure WriteInteger(Value: Integer);
  begin
  {$IFDEF ACL_PACK_VARIANT_INTEGERS}
    if (Value >= Low(ShortInt)) and (Value <= High(ShortInt)) then
    begin
      WriteValueType(vaInt8);
      WriteByte(Value);
    end
    else
      if (Value >= Low(SmallInt)) and (Value <= High(SmallInt)) then
      begin
        WriteValueType(vaInt16);
        WriteWord(Value);
      end
      else
  {$ENDIF}
      begin
        WriteValueType(vaInt32);
        WriteInt32(Value);
      end;
  end;

  procedure WriteCardinal(Value: Cardinal); // to prevent from Variant conversion error
  begin
    WriteInteger(Value);
  end;

  procedure WriteArrayProc(const Value: Variant);
  var
    I, L, H: Integer;
  begin
    if VarArrayDimCount(Value) <> 1 then
      raise EWriteError.Create(sErrorUnsupportedVariantType);
    L := VarArrayLowBound(Value, 1);
    H := VarArrayHighBound(Value, 1);
  {$IFDEF ACL_PACK_VARIANT_ARRAYS}
    if L = H then
    begin
      WriteVariant(Value[L]);
      Exit;
    end;
  {$ENDIF}
    WriteValueType(vaList);
    WriteInteger(H - L + 1);
    for I := L to H do
      WriteVariant(Value[I]);
  end;

var
  AVarType: Integer;
begin
  if VarIsArray(AValue) then
  begin
    WriteArrayProc(AValue);
    Exit;
  end;

  AVarType := VarType(AValue) and varTypeMask;
  case AVarType of
    varEmpty:
      WriteValueType(vaNil);
    varNull:
      WriteValueType(vaNull);

    varLongWord:
      WriteCardinal(AValue);

    varByte, varShortInt, varSmallInt, varWord, varInteger:
      WriteInteger(AValue);

    varString, varUString, varOleStr:
      begin
        WriteValueType(vaString);
        WriteStringWithLength(AValue);
      end;

    varInt64:
      begin
        WriteValueType(vaInt64);
        WriteInt64(AValue);
      end;

    varSingle:
      begin
        WriteValueType(vaSingle);
        WriteSingle(AValue);
      end;

    varDouble:
      begin
        WriteValueType(vaExtended);
        WriteDouble(AValue);
      end;

    varCurrency:
      begin
        WriteValueType(vaCurrency);
        WriteSingle(AValue);
      end;

    varDate:
      begin
        WriteValueType(vaDate);
        WriteDouble(AValue);
      end;

    varBoolean:
      if AValue then
        WriteValueType(vaTrue)
      else
        WriteValueType(vaFalse);
  else
    raise EWriteError.Create(sErrorUnsupportedVariantType);
  end;
end;

procedure TACLStreamHelper.WriteWord(const AValue: Word);
begin
  WriteBuffer(AValue, SizeOf(AValue));
end;

procedure TACLStreamHelper.WriteWordBE(const AValue: Word);
begin
  WriteWord(Swap16(AValue));
end;

{ TACLMemoryStreamHelper }

class function TACLMemoryStreamHelper.CopyOf(AStream: TStream): TMemoryStream;
begin
  Result := TMemoryStream.Create;
  Result.Size := AStream.Size;
  StreamCopy(Result, AStream);
  Result.Position := 0;
end;

class function TACLMemoryStreamHelper.CopyOf(AStream: TStream; ASize: Integer): TMemoryStream;
begin
  Result := TMemoryStream.Create;
  Result.Size := ASize;
  AStream.ReadBuffer(Result.Memory^, ASize);
end;

{ TACLAnsiStringStream }

constructor TACLAnsiStringStream.Create(const AData: AnsiString);
begin
  FData := AData;
  SetPointer(PAnsiChar(Data), Length(Data));
end;

function TACLAnsiStringStream.Realloc;
begin
  if (ANewCapacity > 0) and (ANewCapacity <> Size) then
    ANewCapacity := (ANewCapacity + (MemoryDelta - 1)) and not (MemoryDelta - 1);
  if ANewCapacity <> Capacity then
    SetLength(FData, ANewCapacity);
  Result := PAnsiChar(FData);
end;

end.
