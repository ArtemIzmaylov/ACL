////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   TimeEdit
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.TimeEdit;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}Variants,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
  // ACL
  ACL.Timers,
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.SpinEdit,
  ACL.UI.Resources;

type

  { TACLTimeEdit }

  TACLTimeEdit = class(TACLCustomSpinEdit)
  strict private
    function GetDateTime: TDateTime;
    function GetTime: TTime;
    function IsTimeStored: Boolean;
    procedure SetTime(AValue: TTime);
  strict private
    procedure DecodeValues(const AText: string; out H, M, S: Integer);
    function EncodeValues(H, M, S: Integer): string;
    procedure Validate(var H, M, S: Integer); overload;
    procedure Validate(var AText: string); overload;
  protected
    procedure CheckInput(var AText, APart1, APart2: string; var AAccept: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Increase(AStep: Integer); override;
    //# Properties
    property DateTime: TDateTime read GetDateTime;
  published
    property Time: TTime read GetTime write SetTime stored IsTimeStored;
  end;

implementation

uses
  ACL.Geometry,
  ACL.Graphics,
  ACL.Utils.Common,
  ACL.Utils.Strings;

{ TACLTimeEdit }

constructor TACLTimeEdit.Create(AOwner: TComponent);
begin
  inherited;
  FEditBox.Text := EncodeValues(0, 0, 0);
end;

procedure TACLTimeEdit.CheckInput(
  var AText, APart1, APart2: string; var AAccept: Boolean);
var
  LChar: Char;
  LCurr: Integer;
  LText: string;
begin
  if FEditBox.SelLength > 0 then
  begin
    LText := APart1 + acDupeString('0', FEditBox.SelLength) + APart2;
    Validate(LText);
  end
  else
    LText := FEditBox.Text;

  LCurr := FEditBox.SelStart;
  for LChar in AText do
  begin
    if CharInSet(LChar, ['0'..'9']) then
    begin
      Inc(LCurr);
      if InRange(LCurr, 1, Length(LText)) and (LText[LCurr] = ':') then
        Inc(LCurr);
      LText[LCurr] := LChar;
    end;
  end;

  Validate(LText);
  APart1 := '';
  APart2 := Copy(LText, LCurr + 1);
  AText  := Copy(LText, 1, LCurr);
end;

procedure TACLTimeEdit.DecodeValues(const AText: string; out H, M, S: Integer);
begin
  H := StrToIntDef(Copy(AText, 1, 2), 0);
  M := StrToIntDef(Copy(AText, 4, 2), 0);
  S := StrToIntDef(Copy(AText, 7, 2), 0);
end;

function TACLTimeEdit.EncodeValues(H, M, S: Integer): string;
begin
  Result :=
    FormatFloat('00', H) + ':' +
    FormatFloat('00', M) + ':' +
    FormatFloat('00', S);
end;

function TACLTimeEdit.GetDateTime: TDateTime;
begin
  Result := Date + Time;
end;

function TACLTimeEdit.GetTime: TTime;
var
  H, M, S: Integer;
begin
  DecodeValues(FEditBox.Text, H, M, S);
  Validate(H, M, S);
  Result := EncodeTime(H, M, S, 0);
end;

procedure TACLTimeEdit.Increase(AStep: Integer);
var
  LCursor: Integer;
  H, M, S: Integer;
begin
  LCursor := FEditBox.SelStart;
  try
    DecodeValues(FEditBox.Text, H, M, S);
    case LCursor of
      0..2: Inc(H, AStep);
      3..5: Inc(M, AStep);
      6..8: Inc(S, AStep);
    else;
    end;
    Validate(H, M, S);
    FEditBox.Text := EncodeValues(H, M, S);
  finally
    FEditBox.SelStart := LCursor;
  end;
end;

function TACLTimeEdit.IsTimeStored: Boolean;
begin
  Result := not IsZero(Time)
end;

procedure TACLTimeEdit.SetTime(AValue: TTime);
var
  H, M, S, X: Word;
begin
  if Time <> AValue then
  begin
    DecodeTime(AValue, H, M, S, X);
    FEditBox.Text := EncodeValues(H, M, S);
  end;
end;

procedure TACLTimeEdit.Validate(var AText: string);
var
  H, M, S: Integer;
begin
  DecodeValues(AText, H, M, S);
  Validate(H, M, S);
  AText := EncodeValues(H, M, S);
end;

procedure TACLTimeEdit.Validate(var H, M, S: Integer);
var
  LValue: Int64;
begin
  LValue := Max(H * 3600 + M * 60 + S, 0);
  S := LValue mod 60;
  LValue := LValue div 60;
  M := LValue mod 60;
  LValue := LValue div 60;
  H := Min(LValue, 23);
end;

end.
