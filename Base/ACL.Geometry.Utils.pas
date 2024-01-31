﻿{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*       Operators for Geometry types        *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Geometry.Utils; // FPC:OK

(*
   Disclamer:
     FreePascal does not allow to define the operators in record helpers,
     but in objfpc mode it allow to define global operators.
     So, mission of the unit is resolve operators issue in our code.
*)

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

{$IFDEF FPC}
uses
  Types,
  ACL.Geometry,
  ACL.Utils.Common;

operator - (const L: TRect; const R: TPoint): TRect;
operator + (const L: TRect; const R: TPoint): TRect;
operator * (const L: TRect; Borders: TACLBorders): TRect;
operator * (const L: TRect; Factor: Single): TRect;
operator * (const L: TPoint; Factor: Single): TPoint;
operator := (const Value: TSize): TRect;
{$ENDIF}
implementation

{$IFDEF FPC}

operator - (const L: TRect; const R: TPoint): TRect;
begin
  Result := L;
  Result.Offset(-R.X, -R.Y);
end;

operator + (const L: TRect; const R: TPoint): TRect;
begin
  Result := L;
  Result.Offset(R.X, R.Y);
end;

operator * (const L: TPoint; Factor: Single): TPoint;
begin
  Result.X := Round(L.X * Factor);
  Result.Y := Round(L.Y * Factor);
end;

operator * (const L: TRect; Borders: TACLBorders): TRect;
begin
  Result := NullRect;
  if mLeft in Borders then
    Result.Left := L.Left;
  if mRight in Borders then
    Result.Right := L.Right;
  if mTop in Borders then
    Result.Top := L.Top;
  if mBottom in Borders then
    Result.Bottom := L.Bottom;
end;

operator * (const L: TRect; Factor: Single): TRect;
begin
  Result.Bottom := Round(L.Bottom * Factor);
  Result.Right := Round(L.Right * Factor);
  Result.Left := Round(L.Left * Factor);
  Result.Top := Round(L.Top * Factor);
end;

operator := (const Value: TSize): TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := Value.cx;
  Result.Bottom := Value.cy;
end;

{$ENDIF}
end.
