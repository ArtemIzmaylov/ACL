////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Mathematics routines
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Math;

{$I ACL.Config.inc}

interface

uses
  {System.}Math;

{$IFDEF FPC}
type
  TArithmeticException = TFPUException;
  TArithmeticExceptions = TFPUExceptionMask;

const
  exAllArithmeticExceptions = [
    exInvalidOp, exDenormalized, exZeroDivide,
    exOverflow, exUnderflow, exPrecision];
{$ENDIF}

type
  TACLMath = class
  public
    class function IfThen<T>(Condition: Boolean; const True: T): T; overload; inline;
    class function IfThen<T>(Condition: Boolean; const True: T; const False: T): T; overload; inline;
    class procedure Exchange<T>(var L, R: T); inline;
    class procedure ExchangePtr(var L, R); inline;
  end;

procedure InitFPUforCLibs;
procedure InitFPUforDelphi;

// MinMax, MaxMin
function MaxMin(const AValue, AMinValue, AMaxValue: Double): Double; overload; inline;
function MaxMin(const AValue, AMinValue, AMaxValue: Int64): Int64; overload; inline;
function MaxMin(const AValue, AMinValue, AMaxValue: Integer): Integer; overload; inline;
function MaxMin(const AValue, AMinValue, AMaxValue: Single): Single; overload; inline;
function MinMax(const AValue, AMinValue, AMaxValue: Double): Double; overload; inline;
function MinMax(const AValue, AMinValue, AMaxValue: Int64): Int64; overload; inline;
function MinMax(const AValue, AMinValue, AMaxValue: Integer): Integer; overload; inline;
function MinMax(const AValue, AMinValue, AMaxValue: Single): Single; overload; inline;

// PowerOf2
function NextPowerOf2(AValue: Integer): Integer;
function PrevPowerOf2(AValue: Integer): Integer;

// Random
function acRandom(ACount: Integer): Integer; inline;
function acRandomRange(AMin, AMax: Integer): Integer; inline;

// Swapping
function Swap16(const AValue: Word): Word;
function Swap32(const AValue: Integer): Integer;
function Swap64(const AValue: Int64): Int64;

// 64-bit int utils
function HiInteger(const A: UInt64): Integer;
function LoInteger(const A: UInt64): Integer;
function MakeInt64(const A, B: Integer): UInt64;
function MulDiv(const AValue, ANumerator, ADenominator: Integer): Integer;
function MulDiv64(const AValue, ANumerator, ADenominator: Int64): Int64;
implementation

uses
{$IFDEF FPC}
  LCLType;
{$ELSE}
  Windows;
{$ENDIF}

procedure InitFPUforCLibs;
begin
  SetExceptionMask(exAllArithmeticExceptions);
end;

procedure InitFPUforDelphi;
begin
  // Delphi 11.3 and newer operates with floating point errors like C++
  // https://docwiki.embarcadero.com/RADStudio/Athens/en/Floating_Point_Operation_Exception_Masks
  // Restoring the old behavior:
  SetExceptionMask([exPrecision, exUnderflow, exDenormalized]);
end;

function NextPowerOf2(AValue: Integer): Integer;
begin
  if AValue < 1 then Exit(1);
  Result := AValue - 1;
  Result := Result or (Result shr 1);
  Result := Result or (Result shr 2);
  Result := Result or (Result shr 4);
  Result := Result or (Result shr 8);
  Result := Result or (Result shr 16);
  Inc(Result);
end;

function PrevPowerOf2(AValue: Integer): Integer;
begin
  if AValue < 1 then Exit(0);
  Result := AValue;
  Result := Result or (Result shr 1);
  Result := Result or (Result shr 2);
  Result := Result or (Result shr 4);
  Result := Result or (Result shr 8);
  Result := Result or (Result shr 16);
  Dec(Result, Result shr 1);
end;

{ MinMax / MaxMin }

function MaxMin(const AValue, AMinValue, AMaxValue: Double): Double; overload;
begin
  Result := Max(Min(AValue, AMaxValue), AMinValue);
end;

function MaxMin(const AValue, AMinValue, AMaxValue: Int64): Int64; overload;
begin
  Result := Max(Min(AValue, AMaxValue), AMinValue);
end;

function MaxMin(const AValue, AMinValue, AMaxValue: Integer): Integer; overload;
begin
  Result := Max(Min(AValue, AMaxValue), AMinValue);
end;

function MaxMin(const AValue, AMinValue, AMaxValue: Single): Single; overload;
begin
  Result := Max(Min(AValue, AMaxValue), AMinValue);
end;

function MinMax(const AValue, AMinValue, AMaxValue: Double): Double; overload;
begin
  Result := Min(Max(AValue, AMinValue), AMaxValue);
end;

function MinMax(const AValue, AMinValue, AMaxValue: Int64): Int64; overload;
begin
  Result := Min(Max(AValue, AMinValue), AMaxValue);
end;

function MinMax(const AValue, AMinValue, AMaxValue: Integer): Integer; overload;
begin
  Result := Min(Max(AValue, AMinValue), AMaxValue);
end;

function MinMax(const AValue, AMinValue, AMaxValue: Single): Single; overload;
begin
  Result := Min(Max(AValue, AMinValue), AMaxValue);
end;

{ Random }

function acRandom(ACount: Integer): Integer;
begin
  if ACount <= 0 then Exit(0);
{$IFDEF FPC}
  Result := Round((ACount - 1) * Random);
  Result := MinMax(Result, 0, ACount - 1);
{$ELSE}
  Result := Random(ACount);
{$ENDIF}
end;

function acRandomRange(AMin, AMax: Integer): Integer;
begin
  Result := AMin + acRandom(AMax - AMin);
end;

{ Swapping }

function Swap16(const AValue: Word): Word;
{$IFDEF ACL_PUREPASCAL}
var
  B: array [0..1] of Byte absolute AValue;
begin
  Result := (B[0] shl 8) or B[1];
end;
{$ELSE}
asm
  bswap eax
  shr eax, 16;
end;
{$ENDIF}

function Swap32(const AValue: Integer): Integer;
{$IFDEF ACL_PUREPASCAL}
var
  B: array [0..3] of Byte absolute AValue;
begin
  Result := (B[0] shl 24) or (B[1] shl 16) or (B[2] shl 8) or B[3];
end;
{$ELSE}
asm
  bswap eax
end;
{$ENDIF}

function Swap64(const AValue: Int64): Int64;
var
  B: array [1..8] of Byte absolute AValue;
  I: Integer;
begin
  Result := 0;
  for I := 1 to 8 do
    Result := Int64(Result shl 8) or Int64(B[I]);
end;

function HiInteger(const A: UInt64): Integer;
begin
  Result := Integer(A shr 32);
end;

function LoInteger(const A: UInt64): Integer;
begin
  Result := Integer(A);
end;

function MakeInt64(const A, B: Integer): UInt64;
begin
  Result := UInt64(A) or (UInt64(B) shl 32);
end;

function MulDiv(const AValue, ANumerator, ADenominator: Integer): Integer;
begin
{$IFDEF FPC}
  Result := LCLType.MulDiv(AValue, ANumerator, ADenominator);
{$ELSE}
  Result := Windows.MulDiv(AValue, ANumerator, ADenominator);
{$ENDIF}
end;

function MulDiv64(const AValue, ANumerator, ADenominator: Int64): Int64;
var
  ARatio: Double;
begin
  if ADenominator <> 0 then
    ARatio := ANumerator / ADenominator
  else
    ARatio := 0;

  Result := Round(ARatio * AValue); //#AI: must be round!!
end;

{ TACLMath }

class function TACLMath.IfThen<T>(Condition: Boolean; const True: T): T;
begin
  if Condition then
    Exit(True);
  Result := Default(T);
end;

class procedure TACLMath.Exchange<T>(var L, R: T);
var
  LTemp: T;
begin
  LTemp := L;
  L := R;
  R := LTemp;
end;

class procedure TACLMath.ExchangePtr(var L, R);
var
  LTemp: Pointer;
begin
  LTemp := Pointer(L);
  Pointer(L) := Pointer(R);
  Pointer(R) := LTemp;
end;

class function TACLMath.IfThen<T>(Condition: Boolean; const True, False: T): T;
begin
  if Condition then
    Exit(True);
  Result := False;
end;

end.
