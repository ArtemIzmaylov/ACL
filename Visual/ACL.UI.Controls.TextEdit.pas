{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*                 Text Editor               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.TextEdit;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type

  { TACLCustomTextEdit }

  TACLTextEditCustomDrawEvent = procedure (Sender: TObject;
    ACanvas: TCanvas; const R: TRect; var AHandled: Boolean) of object;

  TACLCustomTextEdit = class(TACLCustomInplaceEdit)
  strict private
    FInputMask: TACLEditInputMask;
    FMaxLength: Integer;
    FPasswordChar: Boolean;
    FReadOnly: Boolean;
    FTextHint: string;

    FOnCustomDraw: TACLTextEditCustomDrawEvent;

    procedure HandlerInnerEditChanged(Sender: TObject);
    function GetInnerEdit: TACLInnerEdit;
    function GetSelLength: Integer;
    function GetSelStart: Integer;
    function GetSelText: string;
    function GetValue: Variant;
    procedure SetInputMask(AValue: TACLEditInputMask);
    procedure SetMaxLength(AValue: Integer);
    procedure SetPasswordChar(AValue: Boolean);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetSelLength(AValue: Integer);
    procedure SetSelStart(AValue: Integer);
    procedure SetSelText(const Value: string);
    procedure SetText(AValue: string);
    procedure SetTextHint(const AValue: string);
    procedure SetValue(const AValue: Variant);
  protected
    FContentRect: TRect;
    FText: string;
    FTextChangeLockCount: Integer;
    FTextRect: TRect;

    procedure CalculateContent(const R: TRect); override;
    function CalculateEditorPosition: TRect; override;
    procedure DrawEditorContent(ACanvas: TCanvas); virtual;
    procedure DrawText(ACanvas: TCanvas; const R: TRect);
    procedure Loaded; override;
    procedure Paint; override;
    procedure SetDefaultSize; override;
    procedure SetFocusToInnerEdit; override;
    procedure SetTextCore(const AValue: string); virtual;

    // Validation
    function TextToDisplayText(const AText: string): string; virtual;
    function TextToValue(const AText: string): Variant; virtual;
    function ValueToText(const AValue: Variant): string; virtual;

    // InnerEdit
    function CanOpenEditor: Boolean; override;
    function CreateEditor: TWinControl; override;
    procedure EditorUpdateParamsCore; override;
    procedure EditorValidateText;
    procedure RetriveValueFromInnerEdit;

    // Inplace
    function InplaceGetValue: string; override;
    procedure InplaceSetFocus; override;
    procedure InplaceSetValue(const AValue: string); override;

    // Events
    function DoCustomDraw(ACanvas: TCanvas): Boolean; virtual;

    // Messages
    procedure CMWantSpecialKey(var Message: TMessage); message CM_WANTSPECIALKEY;

    property InputMask: TACLEditInputMask read FInputMask write SetInputMask default eimText;
    property MaxLength: Integer read FMaxLength write SetMaxLength default 0;
    property PasswordChar: Boolean read FPasswordChar write SetPasswordChar default False;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property Text: string read FText write SetText;
    property TextHint: string read FTextHint write SetTextHint;
    property Value: Variant read GetValue write SetValue;
    //# Events
    property OnCustomDraw: TACLTextEditCustomDrawEvent read FOnCustomDraw write FOnCustomDraw;
  public
    procedure Localize(const ASection: string); override;
    procedure SelectAll;
    //# Properties
    property InnerEdit: TACLInnerEdit read GetInnerEdit;
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelText: string read GetSelText write SetSelText;
    property ContentRect: TRect read FContentRect;
    property TextRect: TRect read FTextRect;
  published
    property Color;
    property OnChange;
  end;

  { TACLEdit }

  TACLEditClass = class of TACLEdit;
  TACLEdit = class(TACLCustomTextEdit)
  public
    property Value;
  published
    property AutoHeight;
    property Borders;
    property Buttons;
    property ButtonsImages;
    property InputMask;
    property MaxLength;
    property PasswordChar;
    property ReadOnly;
    property ResourceCollection;
    property Style;
    property StyleButton;
    property Text;
    property TextHint;
  end;

implementation

{ TACLCustomTextEdit }

procedure TACLCustomTextEdit.CalculateContent(const R: TRect);
begin
  FContentRect := R;
  FTextRect := R;
  FTextRect.Inflate(-dpiApply(acTextIndent, FCurrentPPI));
end;

function TACLCustomTextEdit.CalculateEditorPosition: TRect;
begin
  Result := FTextRect;
end;

procedure TACLCustomTextEdit.DrawEditorContent(ACanvas: TCanvas);
begin
  DrawText(ACanvas, TextRect);
end;

procedure TACLCustomTextEdit.DrawText(ACanvas: TCanvas; const R: TRect);
begin
  AssignTextDrawParams(ACanvas);
  if Focused or (Text <> '') then
    acTextDraw(ACanvas, TextToDisplayText(Text), R, taLeftJustify, taVerticalCenter)
  else
  begin
    ACanvas.Font.Color := Style.ColorTextDisabled.AsColor;
    acTextDraw(ACanvas, TextHint, R, taLeftJustify, taVerticalCenter);
  end;
end;

procedure TACLCustomTextEdit.Loaded;
begin
  inherited Loaded;
  if Text <> '' then
    Changed;
end;

procedure TACLCustomTextEdit.Localize(const ASection: string);
begin
  inherited Localize(ASection);
  TextHint := LangGet(ASection, 'th', TextHint);
end;

procedure TACLCustomTextEdit.Paint;
begin
  inherited Paint;

  if InnerEdit = nil then
  begin
    if not DoCustomDraw(Canvas) then
      DrawEditorContent(Canvas);
  end;
end;

procedure TACLCustomTextEdit.RetriveValueFromInnerEdit;
begin
  if FTextChangeLockCount = 0 then
  begin
    SetTextCore(InnerEdit.Text);
    EditorUpdateParams;
    Changed;
  end;
end;

procedure TACLCustomTextEdit.SelectAll;
begin
  if InnerEdit <> nil then
    InnerEdit.SelectAll;
end;

procedure TACLCustomTextEdit.SetDefaultSize;
begin
  if not Inplace then
    inherited SetDefaultSize;
end;

procedure TACLCustomTextEdit.SetFocusToInnerEdit;
var
  ASelection: TPoint;
begin
  if InnerEdit <> nil then
  begin
    ASelection := Point(SelStart, SelLength);
    InnerEdit.SetFocus;
    if ASelection.Y > 0 then
    begin
      SelStart := ASelection.X;
      SelLength := ASelection.Y;
    end;
  end;
  Invalidate;
end;

procedure TACLCustomTextEdit.SetTextCore(const AValue: string);
begin
  FText := AValue;
end;

function TACLCustomTextEdit.TextToDisplayText(const AText: string): string;
begin
  if PasswordChar then
    Result := acDupeString('x', Length(AText))
  else
    Result := AText;
end;

function TACLCustomTextEdit.TextToValue(const AText: string): Variant;
begin
  case InputMask of
    eimInteger:
      Result := StrToIntDef(AText, 0);
    eimFloat:
      Result := StrToFloatDef(AText, 0);
    eimDateAndTime:
      Result := StrToDateTimeDef(AText, 0, EditDateTimeFormat);
  else
    Result := AText;
  end;
end;

function TACLCustomTextEdit.ValueToText(const AValue: Variant): string;
begin
  if InputMask = eimDateAndTime then
    Result := FormatDateTime(EditDateTimeFormatToString, AValue, EditDateTimeFormat)
  else
    Result := AValue;
end;

function TACLCustomTextEdit.CanOpenEditor: Boolean;
begin
  Result := not (csDestroying in ComponentState);
end;

function TACLCustomTextEdit.CreateEditor: TWinControl;
var
  AEdit: TACLInnerEdit;
begin
  AEdit := TACLInnerEdit.Create(Self);
  AEdit.OnChange := HandlerInnerEditChanged;
  AEdit.OnValidate := EditorValidateText;
  Result := AEdit;
end;

procedure TACLCustomTextEdit.EditorUpdateParamsCore;
var
  LInnerEdit: TACLInnerEdit;
begin
  Inc(FTextChangeLockCount);
  try
    inherited;
    LInnerEdit := InnerEdit;
    LInnerEdit.PasswordChar := Char(IfThen(PasswordChar, Ord('x'), 0));
    LInnerEdit.InputMask := InputMask;
    LInnerEdit.MaxLength := MaxLength;
    LInnerEdit.ReadOnly := ReadOnly;
    LInnerEdit.Text := Text;
    LInnerEdit.TextHint := TextHint;
  finally
    Dec(FTextChangeLockCount);
  end;
end;

procedure TACLCustomTextEdit.EditorValidateText;
begin
  SetText(ValueToText(TextToValue(Text)));
end;

function TACLCustomTextEdit.InplaceGetValue: string;
begin
  Result := Value;
end;

procedure TACLCustomTextEdit.InplaceSetFocus;
begin
  inherited;
  SelectAll;
end;

procedure TACLCustomTextEdit.InplaceSetValue(const AValue: string);
begin
  Value := AValue;
end;

function TACLCustomTextEdit.DoCustomDraw(ACanvas: TCanvas): Boolean;
begin
  Result := False;
  if Assigned(OnCustomDraw) then
    OnCustomDraw(Self, ACanvas, FContentRect, Result);
end;

procedure TACLCustomTextEdit.CMWantSpecialKey(var Message: TMessage);
begin
  if Inplace then
    Message.Result := 1
  else
    inherited;
end;

procedure TACLCustomTextEdit.HandlerInnerEditChanged(Sender: TObject);
begin
  RetriveValueFromInnerEdit;
end;

function TACLCustomTextEdit.GetInnerEdit: TACLInnerEdit;
begin
  Result := TACLInnerEdit(FEditor);
end;

function TACLCustomTextEdit.GetSelLength: Integer;
begin
  Result := InnerEdit.SelLength;
end;

function TACLCustomTextEdit.GetSelStart: Integer;
begin
  Result := InnerEdit.SelStart;
end;

function TACLCustomTextEdit.GetSelText: string;
begin
  Result := InnerEdit.SelText;
end;

function TACLCustomTextEdit.GetValue: Variant;
begin
  Result := TextToValue(Text);
end;

procedure TACLCustomTextEdit.SetMaxLength(AValue: Integer);
begin
  if AValue <> FMaxLength then
  begin
    FMaxLength := AValue;
    EditorUpdateParams;
  end;
end;

procedure TACLCustomTextEdit.SetInputMask(AValue: TACLEditInputMask);
begin
  if AValue <> FInputMask then
  begin
    FInputMask := AValue;
    Inc(FTextChangeLockCount);
    try
      EditorUpdateParams;
      EditorValidateText;
    finally
      Dec(FTextChangeLockCount);
    end;
  end;
end;

procedure TACLCustomTextEdit.SetPasswordChar(AValue: Boolean);
begin
  if FPasswordChar <> AValue then
  begin
    FPasswordChar := AValue;
    EditorUpdateParams;
  end;
end;

procedure TACLCustomTextEdit.SetReadOnly(AValue: Boolean);
begin
  if AValue <> FReadOnly then
  begin
    FReadOnly := AValue;
    EditorUpdateParams;
  end;
end;

procedure TACLCustomTextEdit.SetSelLength(AValue: Integer);
begin
{$IFDEF FPC}
  AValue := Min(AValue, Length(Text));
{$ENDIF}
  InnerEdit.SelLength := AValue;
end;

procedure TACLCustomTextEdit.SetSelStart(AValue: Integer);
begin
  InnerEdit.SelStart := AValue;
end;

procedure TACLCustomTextEdit.SetSelText(const Value: string);
begin
  InnerEdit.SelText := Value;
  Text := Text;
end;

procedure TACLCustomTextEdit.SetText(AValue: string);
begin
  if AValue <> Text then
  begin
    AValue := ValueToText(TextToValue(AValue));
    if AValue <> Text then
    begin
      SetTextCore(AValue);
      EditorUpdateParams;
      Changed;
    end;
  end;
end;

procedure TACLCustomTextEdit.SetTextHint(const AValue: string);
begin
  if AValue <> FTextHint then
  begin
    FTextHint := AValue;
    EditorUpdateParams;
  end;
end;

procedure TACLCustomTextEdit.SetValue(const AValue: Variant);
begin
  Text := ValueToText(AValue);
end;

end.
