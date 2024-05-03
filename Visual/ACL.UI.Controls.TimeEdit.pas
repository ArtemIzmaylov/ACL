{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*                 Time Edit                 *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.TimeEdit;

{$I ACL.Config.inc} // FPC:OK

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
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.SpinEdit,
  ACL.UI.Forms,
  ACL.UI.Resources;

type
  { TACLInnerTimeEdit }

  TACLTimeEditorSection = (tesNone, tesHour, tesMinutes, tesSeconds);

  TACLInnerTimeEdit = class(TACLInnerEdit)
  strict private
    function GetDateTime: TDateTime;
    function GetFocusedSection: TACLTimeEditorSection;
    function GetTime: TTime;
    function Replace(const AStr, AWithStr: string; AFrom, ALength: Integer): string;
    procedure CleanSelection;
    procedure SetTime(AValue: TTime);
  protected
    procedure Decode(const AText: string; out H, M, S: Integer);
    procedure Encode(H, M, S: Integer);
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPressCore(var Key: WideChar); override;
    procedure Validate(var H, M, S: Integer); reintroduce;
    procedure ValidateEdit(const AText: string); reintroduce;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Increase(AForward: Boolean);
    //# Properties
    property DateTime: TDateTime read GetDateTime;
    property FocusedSection: TACLTimeEditorSection read GetFocusedSection;
    property Time: TTime read GetTime write SetTime;
  end;

  { TACLTimeEdit }

  TACLTimeEdit = class(TACLCustomSpinEdit)
  strict private
    function GetDateTime: TDateTime;
    function GetEdit: TACLInnerTimeEdit;
    function GetTime: TTime;
    function IsTimeStored: Boolean;
    procedure SetTime(AValue: TTime);
  protected
    function CreateEditor: TWinControl; override;
    procedure ButtonClick(AStep: Integer); override;
    procedure DoEditChange(Sender: TObject);
    function DoMouseWheel(Shift: TShiftState; Delta: Integer; Pos: TPoint): Boolean; override;
    //# Properties
    property Edit: TACLInnerTimeEdit read GetEdit;
  public
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

{ TACLInnerTimeEdit }

constructor TACLInnerTimeEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  MaxLength := 8;
  Alignment := taCenter;
  ValidateEdit(Text);
end;

procedure TACLInnerTimeEdit.CleanSelection;
var
  LPrevSelStart: Integer;
begin
  LPrevSelStart := SelStart;
  try
    ValidateEdit(Replace(Text, acDupeString('0', SelLength), SelStart, SelLength));
  finally
    SelStart := LPrevSelStart;
    SelLength := 0;
  end;
end;

procedure TACLInnerTimeEdit.Decode(const AText: string; out H, M, S: Integer);
begin
  H := StrToIntDef(Copy(AText, 1, 2), 0);
  M := StrToIntDef(Copy(AText, 4, 2), 0);
  S := StrToIntDef(Copy(AText, 7, 2), 0);
end;

procedure TACLInnerTimeEdit.Encode(H, M, S: Integer);
begin
  Text :=
    FormatFloat('00', H) + ':' +
    FormatFloat('00', M) + ':' +
    FormatFloat('00', S);
end;

procedure TACLInnerTimeEdit.Increase(AForward: Boolean);
var
  LPrevSelStart: Integer;
  H, M, S: Integer;
begin
  LPrevSelStart := SelStart;
  try
    Decode(Text, H, M, S);
    case FocusedSection of
      tesHour:
        Inc(H, Signs[AForward]);
      tesMinutes:
        Inc(M, Signs[AForward]);
      tesSeconds:
        Inc(S, Signs[AForward]);
    else;
    end;
    Validate(H, M, S);
    Encode(H, M, S);
  finally
    SelStart := LPrevSelStart;
  end;
end;

procedure TACLInnerTimeEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_UP, VK_DOWN:
      begin
        Increase(Key = VK_UP);
        Key := 0;
      end;

    VK_DELETE:
      begin
        SelLength := Max(SelLength, 1);
        CleanSelection;
        Key := 0;
      end;

    VK_BACK:
      begin
        if SelLength = 0 then
        begin
          SelStart := SelStart - 1;
          SelLength := 1;
        end;
        CleanSelection;
        Key := 0;
      end;
  end;
end;

procedure TACLInnerTimeEdit.KeyPressCore(var Key: WideChar);
var
  LCursor: Integer;
begin
  if CharInSet(Key, ['0'..'9']) then
  begin
    LCursor := SelStart;
    try
      if SelLength > 0 then
        CleanSelection;
      if FocusedSection = tesNone then
        Inc(LCursor, 1);
      ValidateEdit(Replace(Text, acString(Key), LCursor, 1));
    finally
      SelStart := LCursor + 1;
    end;
  end;
  Key := #0;
end;

function TACLInnerTimeEdit.Replace(
  const AStr, AWithStr: string; AFrom, ALength: Integer): string;
begin
  Result :=
    Copy(AStr, 1, AFrom) + AWithStr +
    Copy(AStr, AFrom + ALength + 1);
end;

procedure TACLInnerTimeEdit.Validate(var H, M, S: Integer);
var
  AValue: Int64;
begin
  AValue := Max(H * 3600 + M * 60 + S, 0);
  S := AValue mod 60;
  AValue := AValue div 60;
  M := AValue mod 60;
  AValue := AValue div 60;
  H := AValue mod 24;
end;

procedure TACLInnerTimeEdit.ValidateEdit(const AText: string);
var
  H, M, S: Integer;
begin
  Decode(AText, H, M, S);
  Validate(H, M, S);
  Encode(H, M, S);
end;

function TACLInnerTimeEdit.GetDateTime: TDateTime;
begin
  Result := Date + Time;
end;

function TACLInnerTimeEdit.GetFocusedSection: TACLTimeEditorSection;
begin
  case SelStart of
    0..2: Result := tesHour;
    3..5: Result := tesMinutes;
    6..8: Result := tesSeconds;
  else
    Result := tesNone;
  end;
end;

function TACLInnerTimeEdit.GetTime: TTime;
var
  H, M, S: Integer;
begin
  Decode(Text, H, M, S);
  Validate(H, M, S);
  Result := EncodeTime(H, M, S, 0);
end;

procedure TACLInnerTimeEdit.SetTime(AValue: TTime);
var
  H, M, S, X: Word;
begin
  if Time <> AValue then
  begin
    DecodeTime(AValue, H, M, S, X);
    Encode(H, M, S);
  end;
end;

{ TACLTimeEdit }

function TACLTimeEdit.CreateEditor: TWinControl;
var
  AEdit: TACLInnerTimeEdit;
begin
  AEdit := TACLInnerTimeEdit.Create(Self);
  AEdit.Parent := Self;
  AEdit.OnChange := DoEditChange;
  Result := AEdit;
end;

procedure TACLTimeEdit.DoEditChange(Sender: TObject);
begin
  if Assigned(OnChange) then OnChange(Self);
end;

function TACLTimeEdit.DoMouseWheel;
begin
  if not inherited then
    Edit.Increase(Delta >= 0);
  Result := True;
end;

procedure TACLTimeEdit.ButtonClick(AStep: Integer);
begin
  Edit.Increase(AStep > 0);
end;

function TACLTimeEdit.GetDateTime: TDateTime;
begin
  Result := Edit.DateTime;
end;

function TACLTimeEdit.GetEdit: TACLInnerTimeEdit;
begin
  Result := FEditor as TACLInnerTimeEdit;
end;

function TACLTimeEdit.GetTime: TTime;
begin
  Result := Edit.Time;
end;

function TACLTimeEdit.IsTimeStored: Boolean;
begin
  Result := not IsZero(Time)
end;

procedure TACLTimeEdit.SetTime(AValue: TTime);
begin
  Edit.Time := AValue;
end;

end.
