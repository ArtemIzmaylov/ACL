{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*                 Text Editor               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.TextEdit;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.UITypes,
  System.Classes,
  System.Types,
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Geometry,
  ACL.Graphics,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Parsers,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Forms,
  ACL.UI.ImageList,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type

  { TACLCustomTextEdit }

  TACLTextEditCustomDrawEvent = procedure (Sender: TObject; ACanvas: TCanvas; const R: TRect; var AHandled: Boolean) of object;

  TACLCustomTextEdit = class(TACLCustomInplaceEdit)
  strict private
    FInputMask: TACLEditInputMask;
    FMaxLength: Integer;
    FPasswordChar: Boolean;
    FReadOnly: Boolean;
    FTextHint: UnicodeString;

    FOnCustomDraw: TACLTextEditCustomDrawEvent;

    procedure HandlerInnerEditChanged(Sender: TObject);
    function GetInnerEdit: TACLInnerEdit;
    function GetSelLength: Integer;
    function GetSelStart: Integer;
    function GetSelText: UnicodeString;
    function GetValue: Variant;
    procedure SetInputMask(AValue: TACLEditInputMask);
    procedure SetMaxLength(AValue: Integer);
    procedure SetPasswordChar(AValue: Boolean);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetSelLength(const Value: Integer);
    procedure SetSelStart(const Value: Integer);
    procedure SetSelText(const Value: UnicodeString);
    procedure SetText(AValue: UnicodeString);
    procedure SetTextHint(const AValue: UnicodeString);
    procedure SetValue(const AValue: Variant);
  protected
    FContentRect: TRect;
    FText: UnicodeString;
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
    procedure SetTextCore(const AValue: UnicodeString); virtual;

    // Validation
    function TextToDisplayText(const AText: UnicodeString): UnicodeString; virtual;
    function TextToValue(const AText: UnicodeString): Variant; virtual;
    function ValueToText(const AValue: Variant): UnicodeString; virtual;

    // InnerEdit
    function CanOpenEditor: Boolean; override;
    function CreateEditor: TWinControl; override;
    procedure EditorUpdateParamsCore; override;
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
    property Text: UnicodeString read FText write SetText;
    property TextHint: UnicodeString read FTextHint write SetTextHint;
    property Value: Variant read GetValue write SetValue;

    property OnCustomDraw: TACLTextEditCustomDrawEvent read FOnCustomDraw write FOnCustomDraw;
  public
    procedure Localize(const ASection: string); override;
    procedure SelectAll;
    //
    property InnerEdit: TACLInnerEdit read GetInnerEdit;
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelText: UnicodeString read GetSelText write SetSelText;
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

uses
  Vcl.Consts,
  // System
  System.Math,
  System.Character,
  System.SysUtils;

type
  TACLInnerEditAccess = class(TACLInnerEdit);

{ TACLCustomTextEdit }

procedure TACLCustomTextEdit.Localize(const ASection: string);
begin
  inherited Localize(ASection);
  TextHint := LangGet(ASection, 'th', TextHint);
end;

procedure TACLCustomTextEdit.SelectAll;
begin
  SelStart := 0;
  SelLength := MaxInt;
end;

procedure TACLCustomTextEdit.CalculateContent(const R: TRect);
begin
  FContentRect := R;
  FTextRect := acRectInflate(R, -ScaleFactor.Apply(acTextIndent));
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
    acTextDraw(ACanvas.Handle, TextToDisplayText(Text), R, taLeftJustify, taVerticalCenter)
  else
  begin
    ACanvas.Font.Color := Style.ColorTextDisabled.AsColor;
    acTextDraw(ACanvas.Handle, TextHint, R, taLeftJustify, taVerticalCenter);
  end;
end;

procedure TACLCustomTextEdit.Loaded;
begin
  inherited Loaded;
  if Text <> '' then
    Changed;
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

procedure TACLCustomTextEdit.SetTextCore(const AValue: UnicodeString);
begin
  FText := AValue;
end;

function TACLCustomTextEdit.TextToDisplayText(const AText: UnicodeString): UnicodeString;
begin
  if PasswordChar then
    Result := acDupeString('x', Length(AText))
  else
    Result := AText;
end;

function TACLCustomTextEdit.TextToValue(const AText: UnicodeString): Variant;
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

function TACLCustomTextEdit.ValueToText(const AValue: Variant): UnicodeString;
begin
  if InputMask = eimDateAndTime then
    Result := FormatDateTime(EditDateTimeFormatToString, AValue, EditDateTimeFormat)
  else
    Result := AValue;
end;

function TACLCustomTextEdit.CanOpenEditor: Boolean;
begin
  Result := not IsDesigning;
end;

function TACLCustomTextEdit.CreateEditor: TWinControl;
var
  AEdit: TACLInnerEdit;
begin
  AEdit := TACLInnerEdit.Create(nil);
  AEdit.OnChange := HandlerInnerEditChanged;
  Result := AEdit;
end;

procedure TACLCustomTextEdit.EditorUpdateParamsCore;
var
  AInnerEdit: TACLInnerEditAccess;
begin
  Inc(FTextChangeLockCount);
  try
    inherited;
    AInnerEdit := TACLInnerEditAccess(InnerEdit);
    AInnerEdit.PasswordChar := Char(IfThen(PasswordChar, Ord('x'), 0));
    AInnerEdit.InputMask := InputMask;
    AInnerEdit.MaxLength := MaxLength;
    AInnerEdit.ReadOnly := ReadOnly;
    AInnerEdit.Text := Text;
    AInnerEdit.TextHint := TextHint;
  finally
    Dec(FTextChangeLockCount);
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
  if InnerEdit <> nil then
    Result := InnerEdit.SelLength
  else
    Result := 0;
end;

function TACLCustomTextEdit.GetSelStart: Integer;
begin
  if InnerEdit <> nil then
    Result := InnerEdit.SelStart
  else
    Result := 0;
end;

function TACLCustomTextEdit.GetSelText: UnicodeString;
begin
  if InnerEdit <> nil then
    Result := InnerEdit.SelText
  else
    Result := '';
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
    EditorUpdateParams;
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

procedure TACLCustomTextEdit.SetSelLength(const Value: Integer);
begin
  HandleNeeded;
  if HasEditor then
    InnerEdit.SelLength := Value;
end;

procedure TACLCustomTextEdit.SetSelStart(const Value: Integer);
begin
  HandleNeeded;
  if HasEditor then
    InnerEdit.SelStart := Value;
end;

procedure TACLCustomTextEdit.SetSelText(const Value: UnicodeString);
begin
  HandleNeeded;
  if HasEditor then
    InnerEdit.SelText := Value;
  Text := Text;
end;

procedure TACLCustomTextEdit.SetText(AValue: UnicodeString);
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

procedure TACLCustomTextEdit.SetTextHint(const AValue: UnicodeString);
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
