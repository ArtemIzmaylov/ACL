{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*     Byte Buffers and Data Containers      *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Classes.ByteBuffer;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF MSWINDOWS}
  Windows, // inlining
{$ENDIF}
  // System
  {System.}Classes,
  {System.}SysUtils,
  // ACL
  ACL.Math,
  ACL.Threading,
  ACL.Utils.Common;

type

  { TACLBitStream }

  TACLBitStream = class
  strict private
    FData: PByte;
    FPosition: Integer;
    FSize: Integer;

    function GetRemain: Integer;
    procedure SetPosition(Value: Integer);
  public
    constructor Create(AData: PByte; ASize: Integer);
    function Read(ANumBits: Byte = 1): Integer;
    procedure Skip(ANumBits: Byte = 1);
    //# Properties
    property Position: Integer read FPosition write SetPosition;
    property Remain: Integer read GetRemain;
    property Size: Integer read FSize;
  end;

  { TACLByteBuffer }

  TACLByteBuffer = class
  strict private
    FData: PByte;
    FDataArr: PByteArray;
    FSize: Integer;

    function GetUnused: Integer; inline;
    procedure SetSize(AValue: Integer);
    procedure SetUsed(AValue: Integer); inline;
  protected
    FUsed: Integer;
  public
    constructor Create(ASize: Integer);
    constructor CreateOwned(ABuffer: PByte; ASize: Integer);
    destructor Destroy; override;
    function Equals(Obj: TObject): Boolean; override;
    procedure Flush(AZeroMem: Boolean = True); virtual;
    //# Properties
    property Data: PByte read FData;
    property DataArr: PByteArray read FDataArr;
    property Size: Integer read FSize write SetSize;
    property Unused: Integer read GetUnused;
    property Used: Integer read FUsed write SetUsed;
  end;

  { TACLCircularByteBuffer }

  TACLCircularByteBuffer = class
  strict private
    FData: PByte;
    FDataSize: Integer;
    FLock: TACLCriticalSection;
    FReadOutstrip: Boolean;
    FReadPosition: Integer;
    FWriteChunkSize: Integer;
    FWritePosition: Integer;

    function GetDataAmount: Integer;
    function GetHasDataForWrite: Boolean;
    function SafeGetAvailableDataForRead: Integer;
    function SafeGetAvailableDataForWrite: Integer;
  public
    constructor Create(ASize: Integer);
    destructor Destroy; override;
    function BeginRead(out ABuffer: PByte; out ASize: Integer): Boolean;
    procedure BeginWrite(out ABuffer: PByte; out ASize: Integer);
    procedure Compact(AMaxSize: Integer);
    procedure Flush;
    procedure EndRead(ASize: Integer);
    procedure EndWrite(ASize: Integer);
    //# Properties
    property Data: PByte read FData;
    property DataAmount: Integer read GetDataAmount;
    property HasDataForWrite: Boolean read GetHasDataForWrite;
  end;

  { IACLDataContainer }

  IACLDataContainer = interface
  ['{FBF02DB8-6F2B-42AC-9F87-FB8A313CDDD7}']
    function GetDataPtr: PByte;
    function GetDataSize: Integer;
    function SetDataSize(AValue: Integer): Boolean;

    function LockData: TMemoryStream;
    procedure UnlockData;
  end;

  { TACLDataContainer }

  TACLDataContainer = class(TInterfacedObject, IACLDataContainer)
  protected
    FData: TMemoryStream;
    FDataLock: TACLCriticalSection;
  public
    constructor Create; overload;
    constructor Create(AStream: TStream); overload;
    constructor Create(AStream: TStream; ASize: Integer); overload;
    constructor Create(const AFileName: string); overload;
    destructor Destroy; override;
    // IACLDataContainer
    function GetDataPtr: PByte;
    function GetDataSize: Integer;
    function SetDataSize(AValue: Integer): Boolean;
    function LockData: TMemoryStream;
    procedure UnlockData;
  end;

  { TACLPositionedByteBuffer }

  TACLPositionedByteBuffer = class(TACLByteBuffer)
  strict private
    FCursor: Integer;

    function GetAvailable: Integer; inline;
    procedure SetCursor(AValue: Integer);
  public
    procedure Flush(AZeroMem: Boolean = True); override;
    //# Properties
    property Available: Integer read GetAvailable;
    property Cursor: Integer read FCursor write SetCursor;
  end;

  { TACLRemovableByteBuffer }

  TACLRemovableByteBuffer = class(TACLByteBuffer)
  strict private
    function GetUnused: Integer; inline;
  public
    function MoveTo(AData: PByte; ADataSize: Integer): Integer;
    procedure Remove(ASize: Integer);
    //# Properties
    property Unused: Integer read GetUnused;
  end;

function acCompare(const AContainer1, AContainer2: IACLDataContainer): Boolean;
implementation

uses
  {System.}Math,
  {System.}RTLConsts,
  // ACL
  ACL.FastCode,
  ACL.Utils.FileSystem;

function acCompare(const AContainer1, AContainer2: IACLDataContainer): Boolean;
begin
  Result := (AContainer1 = AContainer2) or
    (AContainer1 <> nil) and (AContainer2 <> nil) and
    (AContainer1.GetDataSize = AContainer2.GetDataSize) and
    (CompareMem(AContainer1.GetDataPtr, AContainer2.GetDataPtr, AContainer1.GetDataSize));
end;

{ TACLBitStream }

constructor TACLBitStream.Create(AData: PByte; ASize: Integer);
begin
  FData := AData;
  FSize := ASize;
  FPosition := 0;
end;

function TACLBitStream.GetRemain: Integer;
begin
  Result := Size - Position;
end;

function TACLBitStream.Read(ANumBits: Byte): Integer;
var
  AByte: Byte;
  AByteMask: Byte;
begin
  if ANumBits <= 0 then
    raise EInvalidArgument.Create(SBitsIndexError);
  if ANumBits + Position > Size then
    raise EInvalidArgument.Create(SBitsIndexError);

  Result := 0;
  while ANumBits > 0 do
  begin
    AByte := PByte(FData + Position div 8)^;
    AByteMask := 1 shl (7 - Position mod 8);
    Result := (Result shl 1) or Ord(AByte and AByteMask <> 0);
    Inc(FPosition);
    Dec(ANumBits);
  end;
end;

procedure TACLBitStream.SetPosition(Value: Integer);
begin
  if (Value < 0) or (Value > Size) then
    raise EInvalidArgument.Create(SBitsIndexError);
  FPosition := Value;
end;

procedure TACLBitStream.Skip(ANumBits: Byte);
begin
  Position := Position + ANumBits;
end;

{ TACLByteBuffer }

constructor TACLByteBuffer.Create(ASize: Integer);
begin
  inherited Create;
  if ASize < 0 then
    raise EInvalidArgument.Create(ClassName);
  Size := ASize;
end;

constructor TACLByteBuffer.CreateOwned(ABuffer: PByte; ASize: Integer);
begin
  FData := ABuffer;
  FDataArr := PByteArray(FData);
  FSize := ASize;
end;

destructor TACLByteBuffer.Destroy;
begin
  Size := 0;
  inherited Destroy;
end;

function TACLByteBuffer.Equals(Obj: TObject): Boolean;
begin
  Result := (Obj <> nil) and (Obj.ClassType = ClassType) and
    (Size = TACLByteBuffer(Obj).Size) and CompareMem(Data, TACLByteBuffer(Obj).Data, Size);
end;

procedure TACLByteBuffer.Flush(AZeroMem: Boolean);
begin
  if AZeroMem then
    FastZeroMem(Data, Size);
  Used := 0;
end;

function TACLByteBuffer.GetUnused: Integer;
begin
  Result := Size - Used;
end;

procedure TACLByteBuffer.SetSize(AValue: Integer);
var
  ATempBuffer: PByte;
begin
  if (AValue <> Size) and (AValue >= 0) then
  begin
    if (Used > 0) and (AValue > 0) then
    begin
      Used := Min(Used, AValue);
      ATempBuffer := AllocMem(AValue);
      FastMove(Data^, ATempBuffer^, Used);
      FreeMemAndNil(Pointer(FData));
      FData := ATempBuffer;
    end
    else
    begin
      Used := 0;
      if Size > 0 then
        FreeMemAndNil(Pointer(FData));
      if AValue > 0 then
        FData := AllocMem(AValue);
    end;
    FDataArr := PByteArray(FData);
    FSize := AValue;
  end;
end;

procedure TACLByteBuffer.SetUsed(AValue: Integer);
begin
  FUsed := MinMax(AValue, 0, Size);
end;

{ TACLCircularByteBuffer }

constructor TACLCircularByteBuffer.Create(ASize: Integer);
begin
  inherited Create;
  FDataSize := ASize;
  FData := AllocMem(FDataSize);
  FWriteChunkSize := FDataSize div 4;
  FLock := TACLCriticalSection.Create(Self);
end;

destructor TACLCircularByteBuffer.Destroy;
begin
  FreeAndNil(FLock);
  FreeMem(FData);
  inherited Destroy;
end;

procedure TACLCircularByteBuffer.Compact(AMaxSize: Integer);
var
  ACount: Integer;
begin
  FLock.Enter;
  try
    ACount := Min(AMaxSize, SafeGetAvailableDataForRead);
    FastMove(PByte(PByte(FData) + FReadPosition)^, FData^, ACount);
    FReadOutstrip := False;
    FReadPosition := 0;
    FWritePosition := ACount;
  finally
    FLock.Leave;
  end;
end;

procedure TACLCircularByteBuffer.Flush;
begin
  FLock.Enter;
  try
    FReadPosition := 0;
    FWritePosition := 0;
    FReadOutstrip := False;
  finally
    FLock.Leave;
  end;
end;

function TACLCircularByteBuffer.BeginRead(out ABuffer: PByte; out ASize: Integer): Boolean;
begin
  FLock.Enter;
  try
    ASize := SafeGetAvailableDataForRead;
    ABuffer := PByte(FData) + FReadPosition;
    Result := ASize > 0;
  finally
    FLock.Leave;
  end;
end;

procedure TACLCircularByteBuffer.BeginWrite(out ABuffer: PByte; out ASize: Integer);
begin
  FLock.Enter;
  try
    ASize := Min(SafeGetAvailableDataForWrite, FWriteChunkSize);
    ABuffer := PByte(FData) + FWritePosition;
  finally
    FLock.Leave;
  end;
end;

procedure TACLCircularByteBuffer.EndRead(ASize: Integer);
begin
  FLock.Enter;
  try
    Inc(FReadPosition, ASize);
  {$IFDEF DEBUG}
    if FReadPosition > FDataSize then
      raise Exception.Create(ClassName + '.EndWrite');
  {$ENDIF}
    if FReadPosition = FDataSize then
    begin
      FReadOutstrip := False;
      FReadPosition := 0;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TACLCircularByteBuffer.EndWrite(ASize: Integer);
begin
  FLock.Enter;
  try
    Inc(FWritePosition, ASize);
  {$IFDEF DEBUG}
    if FWritePosition > FDataSize then
      raise Exception.Create(ClassName + '.EndWrite');
  {$ENDIF}
    if FWritePosition = FDataSize then
    begin
      FWritePosition := 0;
      FReadOutstrip := True;
    end;
  finally
    FLock.Leave;
  end;
end;

function TACLCircularByteBuffer.GetDataAmount: Integer;
begin
  FLock.Enter;
  try
    if FReadOutstrip then
      Result := FWritePosition + FDataSize - FReadPosition
    else
      Result := FWritePosition - FReadPosition;
  finally
    FLock.Leave;
  end;
end;

function TACLCircularByteBuffer.GetHasDataForWrite: Boolean;
begin
  FLock.Enter;
  try
    Result := SafeGetAvailableDataForWrite > 0;
  finally
    FLock.Leave;
  end;
end;

function TACLCircularByteBuffer.SafeGetAvailableDataForRead: Integer;
begin
  if FReadOutstrip then
    Result := FDataSize - FReadPosition
  else
    Result := FWritePosition - FReadPosition;
end;

function TACLCircularByteBuffer.SafeGetAvailableDataForWrite: Integer;
begin
  if FReadOutstrip then
    Result := FReadPosition - FWritePosition
  else
    Result := FDataSize - FWritePosition;
end;

{ TACLDataContainer }

constructor TACLDataContainer.Create;
begin
  inherited Create;
  FData := TMemoryStream.Create;
  FDataLock := TACLCriticalSection.Create(Self, ClassName + '.Lock');
end;

constructor TACLDataContainer.Create(AStream: TStream);
begin
  AStream.Position := 0;
  Create(AStream, AStream.Size);
end;

constructor TACLDataContainer.Create(AStream: TStream; ASize: Integer);
begin
  Create;
  SetDataSize(ASize);
  AStream.ReadBuffer(FData.Memory^, ASize);
end;

constructor TACLDataContainer.Create(const AFileName: string);
var
  LStream: TStream;
begin
  LStream := TACLFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Create(LStream);
  finally
    LStream.Free;
  end;
end;

destructor TACLDataContainer.Destroy;
begin
  FreeAndNil(FData);
  FreeAndNil(FDataLock);
  inherited;
end;

function TACLDataContainer.GetDataPtr: PByte;
begin
  Result := FData.Memory;
end;

function TACLDataContainer.GetDataSize: Integer;
begin
  FDataLock.Enter;
  try
    Result := FData.Size;
  finally
    FDataLock.Leave;
  end;
end;

function TACLDataContainer.SetDataSize(AValue: Integer): Boolean;
begin
  FDataLock.Enter;
  try
    FData.Size := AValue;
    if AValue > 0 then
      FastZeroMem(FData.Memory, FData.Size);
    Result := True;
  finally
    FDataLock.Leave;
  end;
end;

function TACLDataContainer.LockData: TMemoryStream;
begin
  FDataLock.Enter;
  Result := FData;
end;

procedure TACLDataContainer.UnlockData;
begin
  FDataLock.Leave;
end;

{ TACLPositionedByteBuffer }

procedure TACLPositionedByteBuffer.Flush(AZeroMem: Boolean = True);
begin
  inherited Flush(AZeroMem);
  Cursor := 0;
end;

function TACLPositionedByteBuffer.GetAvailable: Integer;
begin
  Result := Used - Cursor;
end;

procedure TACLPositionedByteBuffer.SetCursor(AValue: Integer);
begin
  FCursor := MinMax(AValue, 0, Used);
end;

{ TACLRemovableByteBuffer }

function TACLRemovableByteBuffer.GetUnused: Integer;
begin
  Result := Size - Used;
end;

function TACLRemovableByteBuffer.MoveTo(AData: PByte; ADataSize: Integer): Integer;
begin
  Result := Min(ADataSize, Used);
  FastMove(Data^, AData^, Result);
  Remove(Result);
end;

procedure TACLRemovableByteBuffer.Remove(ASize: Integer);
begin
  ASize := Min(ASize, Used);
  Dec(FUsed, ASize);
  if Used > 0 then
    FastMove(DataArr^[ASize], Data^, Used);
end;

end.

