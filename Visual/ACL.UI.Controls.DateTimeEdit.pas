////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   DateTimeEdit
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.DateTimeEdit;

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
  {System.}DateUtils,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // VCL
  {Vcl.}Controls,
  {Vcl.}Dialogs,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  // ACL
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.Calendar,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.SpinEdit,
  ACL.UI.Controls.TimeEdit,
  ACL.UI.Dialogs,
  ACL.UI.Forms,
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

type

  { TACLDateTimeEdit }

  TACLDateTimeEditMode = (dtmDateAndTime, dtmDate);

  TACLDateTimeEdit = class(TACLAbstractComboBox)
  strict private
    FMode: TACLDateTimeEditMode;
    FStyleCalendar: TACLStyleCalendar;
    FStylePushButton: TACLStyleButton;
    FStyleSpinButton: TACLStyleButton;

    function IsValueStored: Boolean;
    procedure SetMode(AValue: TACLDateTimeEditMode);
    procedure SetStyleCalendar(const Value: TACLStyleCalendar);
    procedure SetStylePushButton(const Value: TACLStyleButton);
    procedure SetStyleSpinButton(const Value: TACLStyleButton);
  protected
    function CreateDropDownWindow: TACLPopupWindow; override;
    function TextToValue(const AText: string): Variant; override;
    function ValueToText(const AValue: Variant): string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Borders;
    property Buttons;
    property ButtonsImages;
    property Mode: TACLDateTimeEditMode read FMode write SetMode default dtmDateAndTime;
    property ResourceCollection;
    property Style;
    property StyleButton;
    property StyleCalendar: TACLStyleCalendar read FStyleCalendar write SetStyleCalendar;
    property StylePushButton: TACLStyleButton read FStylePushButton write SetStylePushButton;
    property StyleSpinButton: TACLStyleButton read FStyleSpinButton write SetStyleSpinButton;
    property Value stored IsValueStored;
  end;

  { TACLDateTimeEditDropDown }

  TACLDateTimeEditDropDown = class(TACLPopupWindow)
  strict private const
    ButtonWidth = 75;
  strict private
    FButtonCancel: TACLButton;
    FButtonOk: TACLButton;
    FCalendar: TACLCalendar;
    FOwner: TACLDateTimeEdit;
    FTimeEdit: TACLTimeEdit;

    procedure CreateControl(AControlClass: TACLCustomControlClass; out AControl);
    procedure HandlerApply(Sender: TObject);
    procedure HandlerCancel(Sender: TObject);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

type
  TACLCustomControlAccess = class(TACLCustomControl);

{ TACLDateTimeEdit }

constructor TACLDateTimeEdit.Create(AOwner: TComponent);
begin
  inherited;
  FStyleCalendar := TACLStyleCalendar.Create(Self);
  FStylePushButton := TACLStyleButton.Create(Self);
  FStyleSpinButton := TACLStyleSpinButton.Create(Self);
end;

destructor TACLDateTimeEdit.Destroy;
begin
  FreeAndNil(FStylePushButton);
  FreeAndNil(FStyleSpinButton);
  FreeAndNil(FStyleCalendar);
  inherited;
end;

function TACLDateTimeEdit.CreateDropDownWindow: TACLPopupWindow;
begin
  Result := TACLDateTimeEditDropDown.Create(Self);
end;

function TACLDateTimeEdit.IsValueStored: Boolean;
begin
  Result := Value > 0;
end;

procedure TACLDateTimeEdit.SetMode(AValue: TACLDateTimeEditMode);
begin
  if FMode <> AValue then
  begin
    FMode := AValue;
    Value := Value;
  end;
end;

procedure TACLDateTimeEdit.SetStyleCalendar(const Value: TACLStyleCalendar);
begin
  FStyleCalendar.Assign(Value);
end;

procedure TACLDateTimeEdit.SetStylePushButton(const Value: TACLStyleButton);
begin
  FStylePushButton.Assign(Value);
end;

procedure TACLDateTimeEdit.SetStyleSpinButton(const Value: TACLStyleButton);
begin
  FStyleSpinButton.Assign(Value);
end;

function TACLDateTimeEdit.TextToValue(const AText: string): Variant;
begin
  Result := StrToDateTimeDef(AText, 0, FormatSettings);
  if Mode = dtmDate then
    Result := DateOf(Result);
end;

function TACLDateTimeEdit.ValueToText(const AValue: Variant): string;
var
  LStr: string;
begin
  if AValue > 0 then
  begin
    if Mode = dtmDateAndTime then
      LStr := FormatSettings.ShortDateFormat + ' ' + FormatSettings.LongTimeFormat
    else
      LStr := FormatSettings.ShortDateFormat;

    Result := FormatDateTime(LStr, AValue);
  end
  else
    Result := '';
end;

{ TACLDateTimeEditDropDown }

constructor TACLDateTimeEditDropDown.Create(AOwner: TComponent);
begin
  inherited;
  FOwner := AOwner as TACLDateTimeEdit;

  CreateControl(TACLCalendar, FCalendar);
  FCalendar.Style := FOwner.StyleCalendar;
  if FOwner.Value > 0 then
    FCalendar.Value := TDateTime(FOwner.Value)
  else
    FCalendar.Value := Now;

  CreateControl(TACLTimeEdit, FTimeEdit);
  FTimeEdit.Time := TDateTime(FOwner.Value);
  FTimeEdit.Style := FOwner.Style;
  FTimeEdit.StyleButton := FOwner.StyleSpinButton;
  FTimeEdit.Visible := FOwner.Mode = dtmDateAndTime;

  CreateControl(TACLButton, FButtonOk);
  FButtonOk.Caption := TACLDialogsStrs.MsgDlgButtons[mbOK];
  FButtonOk.Width := dpiApply(ButtonWidth, FCurrentPPI);
  FButtonOk.Style := FOwner.StylePushButton;
  FButtonOk.OnClick := HandlerApply;

  CreateControl(TACLButton, FButtonCancel);
  FButtonCancel.Caption := TACLDialogsStrs.MsgDlgButtons[mbCancel];
  FButtonCancel.OnClick := HandlerCancel;
  FButtonCancel.Width := dpiApply(ButtonWidth, FCurrentPPI);
  FButtonCancel.Style := FOwner.StylePushButton;

  Constraints.MinWidth := dpiApply(290, FCurrentPPI);
  Constraints.MinHeight := dpiApply(320, FCurrentPPI);
  Constraints.MaxHeight := Constraints.MinHeight;
  Constraints.MaxWidth := Constraints.MinWidth;
  SetBounds(0, 0, Constraints.MinWidth, Constraints.MinHeight);
end;

procedure TACLDateTimeEditDropDown.Resize;
var
  AContentRect: TRect;
  ADeferUpdate: TACLDeferPlacementUpdate;
  AIndent: Integer;
  R: TRect;
begin
  inherited;
  if FCalendar = nil then Exit;

  ADeferUpdate := TACLDeferPlacementUpdate.Create;
  try
    AIndent := dpiApply(acIndentBetweenElements, FCurrentPPI);
    AContentRect := ClientRect;
    AContentRect.Inflate(-AIndent);

    // Buttons
    R := AContentRect;
    R.Top := R.Bottom - FButtonCancel.Height;
    ADeferUpdate.Add(FButtonCancel, R.Right - FButtonCancel.Width,
      R.Top, FButtonCancel.Width, FButtonCancel.Height);
    R.Right := R.Right - FButtonCancel.Width - AIndent;
    ADeferUpdate.Add(FButtonOk, R.Right - FButtonOk.Width,
      R.Top, FButtonOk.Width, FButtonOk.Height);
    AContentRect.Bottom := R.Top - 2 * AIndent;

    // TimeEdit
    if FTimeEdit.Visible then
    begin
      R := AContentRect.Split(srBottom, FTimeEdit.Height);
      R.CenterHorz(FTimeEdit.Width);
      ADeferUpdate.Add(FTimeEdit, R.Left, R.Top, FTimeEdit.Width, FTimeEdit.Height);
      AContentRect.Bottom := R.Top - AIndent;
    end;

    ADeferUpdate.Add(FCalendar, AContentRect);
    ADeferUpdate.Apply;
  finally
    ADeferUpdate.Free;
  end;
end;

procedure TACLDateTimeEditDropDown.CreateControl(AControlClass: TACLCustomControlClass; out AControl);
begin
  TObject(AControl) := AControlClass.Create(Self);
  TACLCustomControlAccess(AControl).Parent := Self;
  TACLCustomControlAccess(AControl).ResourceCollection := FOwner.ResourceCollection;
end;

procedure TACLDateTimeEditDropDown.HandlerApply(Sender: TObject);
begin
  FOwner.Value := DateOf(FCalendar.Value) + TimeOf(FTimeEdit.Time);
  ClosePopup;
end;

procedure TACLDateTimeEditDropDown.HandlerCancel(Sender: TObject);
begin
  ClosePopup;
end;

procedure TACLDateTimeEditDropDown.Paint;
begin
  Canvas.Brush.Color := FCalendar.Style.ColorBackground.AsColor;
  Canvas.Pen.Color := FOwner.Style.ColorBorder.AsColor;
  Canvas.Rectangle(ClientRect);
end;

end.
