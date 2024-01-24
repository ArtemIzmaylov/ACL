{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*           Mathematics Routines            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Math.Complex;

{$I ACL.Config.inc}
{%FPC: OK}

// [!] Warning:
// Don't mix usage of TFastFourierTransform and TFastFourierTransformUniversal
// functions for same data (TFastFourierTransformUniversal doesn't reorder data)

interface

const
  PowerOfTwoMax = 15; // supported by FFT Engine

type
  TComplexArgument = type Single;

  { TComplex }

  PComplexArray = ^TComplexArray;

  PComplex = ^TComplex;
  TComplex = record
    Re, Im: TComplexArgument;

    class function AllocArray(const ACount: Integer): PComplexArray; static;
    function Module: TComplexArgument; inline;
  end;

  TComplexArray = array[0..0] of TComplex;

  TFFTSize = (fs4, fs8, fs16, fs32, fs64, fs128, fs256, fs512, fs1024, fs2048, fs4096, fs8192, fs16384);

  PFFTTablesMap = ^TFFTTablesMap;
  TFFTTablesMap = array[0..PowerOfTwoMax] of PComplex;

  { TFastFourierTransform }

  TFastFourierTransform = class(TObject)
  private
    FBuffer: PComplexArray;
    FBufferLength: Integer;
    FCount: Integer;
    FPowerOfTwo: Integer;
    FRotateMap: PIntegerArray;
    FRotateOperator: PFFTTablesMap;
    FRotateOperatorInv: PFFTTablesMap;
  protected
    procedure Initialize(APowerOfTwo, ABufferLength: Integer); virtual;
    procedure TransformStep(AData: PComplexArray; AInverse: Boolean);
    //
    property Count: Integer read FCount;
    property PowerOfTwo: Integer read FPowerOfTwo;
  public
    constructor Create(ASize: TFFTSize);
    destructor Destroy; override;
    procedure Flush;
    procedure Transform(AInverse: Boolean); virtual;
    //
    property Buffer: PComplexArray read FBuffer;
    property BufferLength: Integer read FBufferLength;
  end;

  { TFastFourierTransformUniversal }

  TFastFourierTransformUniversal = class(TFastFourierTransform)
  private
    FK: array [Boolean] of TComplexArgument;
    FOperatorV: array [Boolean] of PComplexArray;
    FOperatorW: array [Boolean] of PComplexArray;
    FTempBuffer: PComplexArray;
    FTempBufferOffset: Integer;
    function CalculateV(AInverse: Boolean): PComplexArray;
    function CalculateW(AInverse: Boolean): PComplexArray;
  protected
    procedure Initialize(APowerOfTwo: Integer; ABufferLength: Integer); override;
  public
    constructor Create(ASize: Cardinal); virtual;
    destructor Destroy; override;
    procedure Transform(AInverse: Boolean); override;
  end;

const
  FFTSizePowerOfTwo: array[TFFTSize] of Integer = (
    2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
  );
  FFTSizeToInteger: array[TFFTSize] of Integer = (
    4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384
  );

implementation

uses
  SysUtils,
  // ACL
  ACL.FastCode,
  ACL.Utils.Common;

const
  TwoPower: array[0..PowerOfTwoMax] of Integer = (
    1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768
  );

type
  TFFTReorderDataMap = array[0..PowerOfTwoMax] of PIntegerArray;

  { TFastFourierTransformHelper }

  TFastFourierTransformHelper = class(TObject)
  private
    FReorderDataMap: TFFTReorderDataMap;
    FRotateOperatorMapForward: TFFTTablesMap;
    FRotateOperatorMapInverse: TFFTTablesMap;
    function CalculateReorderMap(APower: Integer): PIntegerArray;
    function CalculateRotateOperator(APower: Integer; AForward: Boolean): PComplex;
  public
    destructor Destroy; override;
    function GetReorderMap(APower: Integer): PIntegerArray;
    function GetRotateOperator(APower: Integer; AInverse: Boolean): PFFTTablesMap;
  end;

var
  FFastFourierTransformHelper: TFastFourierTransformHelper;

{ TComplex }

class function TComplex.AllocArray(const ACount: Integer): PComplexArray;
begin
  Result := AllocMem(ACount * SizeOf(TComplex))
end;

function TComplex.Module: TComplexArgument;
begin
  Result := Sqrt(Sqr(Re) + Sqr(Im));
end;

{ TFastFourierTransformHelper }

destructor TFastFourierTransformHelper.Destroy;
var
  I: Integer;
begin
  for I := 0 to Length(FRotateOperatorMapForward) - 1 do
    FreeMemAndNil(Pointer(FRotateOperatorMapForward[I]));
  for I := 0 to Length(FRotateOperatorMapInverse) - 1 do
    FreeMemAndNil(Pointer(FRotateOperatorMapInverse[I]));
  for I := 0 to Length(FReorderDataMap) - 1 do
    FreeMemAndNil(Pointer(FReorderDataMap[I]));
  inherited Destroy;
end;

function TFastFourierTransformHelper.CalculateReorderMap(APower: Integer): PIntegerArray;
var
  ACount: Integer;
  AHalf: Integer;
  I, J, K: Integer;
begin
  ACount := TwoPower[APower];
  Result := AllocMem(ACount * SizeOf(Integer));

  J := 0;
  AHalf := ACount div 2;
  for I := 0 to ACount - 2 do
  begin
    Result^[I] := J;
    K := AHalf;
    while K <= J do
    begin
      Dec(J, K);
      K := K shr 1;
    end;
    Inc(J, K);
  end;
end;

function TFastFourierTransformHelper.CalculateRotateOperator(APower: Integer; AForward: Boolean): PComplex;
var
  AScan: PComplex;
  CS, SN: Double;
  PS, I: Integer;
  UR, UI, Ut: Double;
begin
  UR := 1;
  UI := 0;
  PS := TwoPower[APower];
  CS := Cos(Pi / PS);
  SN := Sin(Pi / PS) * Signs[AForward];
  Result := AllocMem(PS * SizeOf(TComplex));
  AScan := Result;
  for I := 0 to PS - 1 do
  begin
    AScan^.Re := UR;
    AScan^.Im := UI;
    Ut := UR * CS - UI * SN;
    UI := UI * CS + UR * SN;
    UR := Ut;
    Inc(AScan);
  end;
end;

function TFastFourierTransformHelper.GetRotateOperator(APower: Integer; AInverse: Boolean): PFFTTablesMap;
var
  I: Integer;
begin
  if AInverse then
    Result := @FRotateOperatorMapInverse
  else
    Result := @FRotateOperatorMapForward;

  if Result^[APower] = nil then
    for I := APower downto 0 do
    begin
      if Result^[I] = nil then
        Result^[I] := CalculateRotateOperator(I, not AInverse)
      else
        Break;
    end;
end;

function TFastFourierTransformHelper.GetReorderMap(APower: Integer): PIntegerArray;
begin
  if FReorderDataMap[APower] = nil then
    FReorderDataMap[APower] := CalculateReorderMap(APower);
  Result := FReorderDataMap[APower];
end;

{ TFastFourierTransform }

constructor TFastFourierTransform.Create(ASize: TFFTSize);
begin
  Initialize(FFTSizePowerOfTwo[ASize], FFTSizeToInteger[ASize]);
end;

destructor TFastFourierTransform.Destroy;
begin
  FreeMemAndNil(Pointer(FBuffer));
  inherited Destroy;
end;

procedure TFastFourierTransform.Flush;
begin
  FastZeroMem(Buffer, BufferLength * SizeOf(TComplex));
end;

procedure TFastFourierTransform.Transform(AInverse: Boolean);
var
  C: PComplex;
  I: Integer;
  K: TComplexArgument;
begin
  TransformStep(Buffer, AInverse);

  if AInverse then
  begin
    C := @Buffer^[0];
    K := 1 / Count;
    for I := 0 to Count - 1 do
    begin
      C^.Re := C^.Re * K;
      C^.Im := C^.Im * K;
      Inc(C);
    end;
  end;
end;

procedure TFastFourierTransform.Initialize(APowerOfTwo, ABufferLength: Integer);
begin
  if APowerOfTwo > PowerOfTwoMax then
    raise Exception.Create('Buffer length too long');

  FPowerOfTwo := APowerOfTwo;
  FBufferLength := ABufferLength;
  FBuffer := TComplex.AllocArray(BufferLength);
  FCount := TwoPower[PowerOfTwo];

  if FFastFourierTransformHelper = nil then
    FFastFourierTransformHelper := TFastFourierTransformHelper.Create;
  FRotateMap := FFastFourierTransformHelper.GetReorderMap(PowerOfTwo);
  FRotateOperator := FFastFourierTransformHelper.GetRotateOperator(PowerOfTwo, False);
  FRotateOperatorInv := FFastFourierTransformHelper.GetRotateOperator(PowerOfTwo, True);
end;

procedure TFastFourierTransform.TransformStep(AData: PComplexArray; AInverse: Boolean);
var
  AComplex: TComplex;
  C1, C2, UC: PComplex;
  I, J, P, P1, P2: Integer;
  Re, Im: TComplexArgument;
  W: PFFTTablesMap;
begin
  if AInverse then
    W := FRotateOperatorInv
  else
    W := FRotateOperator;

  for I := 0 to Count - 2 do
  begin
    J := FRotateMap^[I];
    if I < J then
    begin
      AComplex  := AData^[J];
      AData^[J] := AData^[I];
      AData^[I] := AComplex;
    end;
  end;

  P1 := 1;
  P2 := P1 shl 1;
  for P := 0 to PowerOfTwo - 1 do
  begin
    UC := W^[P];
    for J := 0 to P1 - 1 do
    begin
      I := J;
      while I < Count do
      begin
        C1 := @AData^[I];
        C2 := @AData^[I + P1];
        Re := C2^.Re * UC^.Re - C2^.Im * UC^.Im;
        Im := C2^.Re * UC^.Im + C2^.Im * UC^.Re;
        C2^.Re := C1^.Re - Re;
        C2^.Im := C1^.Im - Im;
        C1^.Re := C1^.Re + Re;
        C1^.Im := C1^.Im + Im;
        Inc(I, P2);
      end;
      Inc(UC);
    end;
    Inc(P1, P1);
    Inc(P2, P2);
  end;
end;

{ TFastFourierTransformUniversal }

constructor TFastFourierTransformUniversal.Create(ASize: Cardinal);
var
  N1, N2, APowerOfTwo: Integer;
begin
  N1 := 1;
  N2 := ASize shl 1;
  APowerOfTwo := 0;
  while N1 < N2 do
  begin
    Inc(N1, N1);
    Inc(APowerOfTwo);
  end;
  Initialize(APowerOfTwo, ASize);
end;

destructor TFastFourierTransformUniversal.Destroy;
var
  B: Boolean;
begin
  for B := Low(B) to High(B) do
  begin
    FreeMemAndNil(Pointer(FOperatorV[B]));
    FreeMemAndNil(Pointer(FOperatorW[B]));
  end;
  inherited Destroy;
end;

procedure TFastFourierTransformUniversal.Initialize(APowerOfTwo, ABufferLength: Integer);
var
  B: Boolean;
begin
  inherited Initialize(APowerOfTwo, ABufferLength);

  for B := Low(B) to High(B) do
  begin
    FOperatorV[B] := CalculateV(B);
    FOperatorW[B] := CalculateW(B);
  end;

  FK[False] := 1 / Count;
  FK[True]  := FK[False] / BufferLength;

  FTempBuffer := TComplex.AllocArray(Count);
  FTempBufferOffset := 2 * (BufferLength - 1);
end;

procedure TFastFourierTransformUniversal.Transform(AInverse: Boolean);
var
  B, T, O: PComplex;
  I: Integer;
  K: TComplexArgument;
begin
  // Input data
  B := @Buffer^[0];
  O := @FOperatorV[AInverse]^[0];
  T := @FTempBuffer^[0];
  for I := 0 to BufferLength - 1 do
  begin
    T^.Re := B^.Re * O^.Re - B^.Im * O^.Im;
    T^.Im := B^.Re * O^.Im + B^.Im * O^.Re;
    Inc(B);
    Inc(O);
    Inc(T);
  end;
  FastZeroMem(T, (Count - BufferLength) * SizeOf(TComplex));

  // Transform
  TransformStep(FTempBuffer, False);

  O := @FOperatorW[AInverse]^[0];
  T := @FTempBuffer^[0];
  for I := 0 to Count - 1 do
  begin
    K := T^.Re * O^.Re - T^.Im * O^.Im;
    T^.Im := T^.Re * O^.Im + T^.Im * O^.Re;
    T^.Re := K;
    Inc(T);
    Inc(O);
  end;

  TransformStep(FTempBuffer, True);

  // Output Data
  K := FK[AInverse];
  B := @FBuffer^[0];
  O := @FOperatorV[AInverse]^[0];
  T := @FTempBuffer^[FTempBufferOffset];
  for I := 0 to BufferLength - 1 do
  begin
    B^.Re := K * (T^.Re * O^.Re - T^.Im * O^.Im);
    B^.Im := K * (T^.Re * O^.Im + T^.Im * O^.Re);
    Dec(T);
    Inc(O);
    Inc(B);
  end;
end;

function TFastFourierTransformUniversal.CalculateV(AInverse: Boolean): PComplexArray;
var
  AArg, PiN: TComplexArgument;
  I: Integer;
begin
  PiN := Pi / BufferLength;
  if AInverse then
    PiN := -PiN;

  Result := TComplex.AllocArray(BufferLength);
  for I := 0 to BufferLength - 1 do
  begin
    AArg := PiN * I * I;
    Result[I].Re := Cos(AArg);
    Result[I].Im := Sin(AArg);
  end;
end;

function TFastFourierTransformUniversal.CalculateW(AInverse: Boolean): PComplexArray;
var
  AArg, PiN: TComplexArgument;
  I, N22: Integer;
begin
  PiN := Pi / BufferLength;
  if AInverse then
    PiN := -PiN;

  Result := TComplex.AllocArray(Count);
  N22 := 2 * (BufferLength - 1);
  for I := 0 to Count - 1 do
  begin
    AArg := -PiN * N22 * N22;
    Result[I].Re := Cos(AArg);
    Result[I].Im := Sin(AArg);
    Dec(N22);
  end;

  TransformStep(Result, False);
end;

initialization

finalization
  FreeAndNil(FFastFourierTransformHelper);
end.

