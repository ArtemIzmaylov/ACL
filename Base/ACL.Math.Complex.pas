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

{$I ACL.Config.inc} // FPC:OK

interface

const
  MaxPowerOfTwo = 15; // supported by FFT Engine

type
  TComplexArgument = type Single;

  { TComplex }

  PComplexArray = ^TComplexArray;
  PComplex = ^TComplex;
  TComplex = record
    Re, Im: TComplexArgument;
    class function AllocArray(const ACount: Integer): PComplexArray; static;
    //# Operators
    class operator Add(const C1, C2: TComplex): TComplex; static; inline;
    class operator Equal(const C1, C2: TComplex): Boolean; static; inline;
    class operator NotEqual(const C1, C2: TComplex): Boolean; static; inline;
    class operator Multiply(const C1, C2: TComplex): TComplex; static; inline;
    class operator Multiply(const C1: TComplex; const S: TComplexArgument): TComplex; static; inline;
    class operator Subtract(const C1, C2: TComplex): TComplex; static; inline;
    //# Self-functions
    function Module: TComplexArgument; inline;
    procedure Scale(S: TComplexArgument); inline;
  end;
  TComplexArray = array[0..MaxInt div SizeOf(TComplex) - 1] of TComplex;

  TFFTSize = (fs4, fs8, fs16, fs32, fs64, fs128, fs256, fs512, fs1024, fs2048, fs4096, fs8192, fs16384);

  PFFTTablesMap = ^TFFTTablesMap;
  TFFTTablesMap = array[0..MaxPowerOfTwo] of PComplex;

  { TFastFourierTransform }

  TFastFourierTransform = class
  strict private
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
    //# Properties
    property Count: Integer read FCount;
    property PowerOfTwo: Integer read FPowerOfTwo;
  public
    constructor Create(ASize: TFFTSize);
    destructor Destroy; override;
    procedure Flush;
    procedure Transform(AInverse: Boolean); virtual;
    //# Properties
    property Buffer: PComplexArray read FBuffer;
    property BufferLength: Integer read FBufferLength;
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
  Math,
  SysUtils,
  // ACL
  ACL.FastCode,
  ACL.Utils.Common;

const
  TwoPower: array[0..MaxPowerOfTwo] of Integer = (
    1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768
  );

type
  TFFTReorderDataMap = array[0..MaxPowerOfTwo] of PIntegerArray;

  { TFastFourierTransformHelper }

  TFastFourierTransformHelper = class
  strict private
    class var FReorderDataMap: TFFTReorderDataMap;
    class var FRotateOperatorMapForward: TFFTTablesMap;
    class var FRotateOperatorMapInverse: TFFTTablesMap;
    class function CalculateReorderMap(APower: Integer): PIntegerArray;
    class function CalculateRotateOperator(APower: Integer; AForward: Boolean): PComplex;
  public
    class destructor Destroy;
    class function GetReorderMap(APower: Integer): PIntegerArray;
    class function GetRotateOperator(APower: Integer; AInverse: Boolean): PFFTTablesMap;
  end;

{ TComplex }

class operator TComplex.Add(const C1, C2: TComplex): TComplex;
begin
  Result.Re := C1.Re + C2.Re;
  Result.Im := C1.Im + C2.Im;
end;

class function TComplex.AllocArray(const ACount: Integer): PComplexArray;
begin
  Result := AllocMem(ACount * SizeOf(TComplex))
end;

class operator TComplex.Equal(const C1, C2: TComplex): Boolean;
begin
  Result := SameValue(C1.Re, C2.Re) and SameValue(C1.Im, C2.Im);
end;

function TComplex.Module: TComplexArgument;
begin
  Result := Sqrt(Sqr(Re) + Sqr(Im));
end;

class operator TComplex.Multiply(const C1: TComplex; const S: TComplexArgument): TComplex;
begin
  Result.Re := C1.Re * S;
  Result.Im := C1.Im * S;
end;

class operator TComplex.Multiply(const C1, C2: TComplex): TComplex;
begin
  Result.Re := C1.Re * C2.Re - C1.Im * C2.Im;
  Result.Im := C1.Re * C2.Im + C1.Im * C2.Re;
end;

class operator TComplex.NotEqual(const C1, C2: TComplex): Boolean;
begin
  Result := not (C1 = C2);
end;

procedure TComplex.Scale(S: TComplexArgument);
begin
  Re := Re * S;
  Im := Im * S;
end;

class operator TComplex.Subtract(const C1, C2: TComplex): TComplex;
begin
  Result.Re := C1.Re - C2.Re;
  Result.Im := C1.Im - C2.Im;
end;

{ TFastFourierTransformHelper }

class destructor TFastFourierTransformHelper.Destroy;
var
  I: Integer;
begin
  for I := 0 to Length(FRotateOperatorMapForward) - 1 do
    FreeMemAndNil(Pointer(FRotateOperatorMapForward[I]));
  for I := 0 to Length(FRotateOperatorMapInverse) - 1 do
    FreeMemAndNil(Pointer(FRotateOperatorMapInverse[I]));
  for I := 0 to Length(FReorderDataMap) - 1 do
    FreeMemAndNil(Pointer(FReorderDataMap[I]));
end;

class function TFastFourierTransformHelper.CalculateReorderMap(APower: Integer): PIntegerArray;
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

class function TFastFourierTransformHelper.CalculateRotateOperator(APower: Integer; AForward: Boolean): PComplex;
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

class function TFastFourierTransformHelper.GetRotateOperator(APower: Integer; AInverse: Boolean): PFFTTablesMap;
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

class function TFastFourierTransformHelper.GetReorderMap(APower: Integer): PIntegerArray;
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
  if APowerOfTwo > MaxPowerOfTwo then
    raise Exception.Create('Buffer length too long');

  FPowerOfTwo := APowerOfTwo;
  FBufferLength := ABufferLength;
  FBuffer := TComplex.AllocArray(BufferLength);
  FCount := TwoPower[PowerOfTwo];

  FRotateMap := TFastFourierTransformHelper.GetReorderMap(PowerOfTwo);
  FRotateOperator := TFastFourierTransformHelper.GetRotateOperator(PowerOfTwo, False);
  FRotateOperatorInv := TFastFourierTransformHelper.GetRotateOperator(PowerOfTwo, True);
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

end.
