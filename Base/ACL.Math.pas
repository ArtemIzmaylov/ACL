{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*               Math Routines               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Math;

{$I ACL.Config.inc} // FPC:OK

interface

uses
  {System.}Math;

type
  TACLMath = class
  public
    class function IfThen<T>(Condition: Boolean; const True: T): T; overload; inline;
    class function IfThen<T>(Condition: Boolean; const True: T; const False: T): T; overload; inline;
  end;

// MinMax, MaxMin
function MaxMin(const AValue, AMinValue, AMaxValue: Double): Double; overload; inline;
function MaxMin(const AValue, AMinValue, AMaxValue: Int64): Int64; overload; inline;
function MaxMin(const AValue, AMinValue, AMaxValue: Integer): Integer; overload; inline;
function MaxMin(const AValue, AMinValue, AMaxValue: Single): Single; overload; inline;
function MinMax(const AValue, AMinValue, AMaxValue: Double): Double; overload; inline;
function MinMax(const AValue, AMinValue, AMaxValue: Int64): Int64; overload; inline;
function MinMax(const AValue, AMinValue, AMaxValue: Integer): Integer; overload; inline;
function MinMax(const AValue, AMinValue, AMaxValue: Single): Single; overload; inline;

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
  Result := (AValue * ANumerator) div ADenominator;
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

class function TACLMath.IfThen<T>(Condition: Boolean; const True, False: T): T;
begin
  if Condition then
    Exit(True);
  Result := False;
end;

end.
