{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Editors Controls              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.SpinEdit;

{$I ACL.Config.inc}

interface

uses
  Winapi.Messages,
  Winapi.Windows,
  // System
  System.Classes,
  System.Types,
  System.UITypes,
  // Vcl
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Timers,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.MUI,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.DPIAware;

type
  TACLCustomSpinEdit = class;
  TACLSpinEdit = class;

  TACLSpinEditValueType = (evtInteger, evtFloat);

  { TACLInnerSpinEdit }

  TACLInnerSpinEdit = class(TACLInnerEdit, IACLInnerControl)
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    // Keyboard
    function CheckChar(var AChar: Char): Boolean; virtual;
    procedure KeyPress(var Key: Char); override;
    // IACLInnerControl
    function GetInnerContainer: TWinControl;
    // Messages
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure WMPaste(var Message: TMessage); message WM_PASTE;
  end;

  { TACLCustomSpinEdit }

  TACLCustomSpinEdit = class(TACLCustomEdit)
  strict private
    FAutoClickButton: TACLCustomButtonSubClass;
    FAutoClickTimer: Boolean;
    FAutoClickTimerWaitCount: Integer;
    FButtonLeft: TACLCustomButtonSubClass;
    FButtonRight: TACLCustomButtonSubClass;

    procedure SetAutoClickTimer(AValue: Boolean);
  protected
    function CalculateEditorPosition: TRect; override;
    function CanOpenEditor: Boolean; override;
    function CreateStyleButton: TACLStyleButton; override;
    function HitTest(X, Y: Integer; var ASubClass: TACLCustomButtonSubClass): Boolean;
    procedure Calculate(R: TRect); override;
    procedure CalculateAutoHeight(var ANewHeight: Integer); override;
    procedure DoButtonClick(AStep: Integer); virtual;
    procedure DrawContent(ACanvas: TCanvas); override;
    procedure EditorMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure EditorInitialize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    //
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure WMTimer(var Message: TWMTimer); message WM_TIMER;
    //
    property AutoClickTimer: Boolean read FAutoClickTimer write SetAutoClickTimer;
    property ButtonLeft: TACLCustomButtonSubClass read FButtonLeft;
    property ButtonRight: TACLCustomButtonSubClass read FButtonRight;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property AutoHeight;
    property Anchors;
    property Enabled;
    property ResourceCollection;
    property Style;
    property StyleButton;
    property TabOrder;
    //
    property OnChange;
  end;

  { TACLStyleSpinButton }

  TACLStyleSpinButton = class(TACLStyleEditButton)
  protected
    procedure InitializeTextures; override;
  end;

  { TACLSpinButtonSubClass }

  TACLSpinButtonSubClass = class(TACLCustomButtonSubClass)
  protected
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); override;
  end;

  { TACLSpinEditOptionsValue }

  TACLSpinEditAssignedValue = (seavIncCount, seavMaxValue, seavMinValue);
  TACLSpinEditAssignedValues = set of TACLSpinEditAssignedValue;

  TACLSpinEditOptionsValue = class(TACLLockablePersistent)
  strict private const
    DefaultDisplayFormat = '%s';
  strict private
    FAssignedValues: TACLSpinEditAssignedValues;
    FDisplayFormat: UnicodeString;
    FOwner: TACLSpinEdit;
    FValues: array[0..2] of Variant;
    FValueType: TACLSpinEditValueType;

    function GetValue(const Index: Integer): Variant;
    function IsDisplayFormatStored: Boolean;
    function IsValueStored(const Index: Integer): Boolean;
    procedure SetAssignedValues(const Value: TACLSpinEditAssignedValues);
    procedure SetDisplayFormat(const Value: UnicodeString);
    procedure SetValue(const Index: Integer; const AValue: Variant);
    procedure SetValueType(const Value: TACLSpinEditValueType);
  protected
    procedure DoAssign(Source: TPersistent); override;
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
    procedure ValidateValue(var V: Variant);
    procedure ValidateValueType(var V: Variant);
  public
    constructor Create(AOwner: TACLSpinEdit); virtual;
  published
    property ValueType: TACLSpinEditValueType read FValueType write SetValueType default evtInteger; // must be first!
    property AssignedValues: TACLSpinEditAssignedValues read FAssignedValues write SetAssignedValues stored False;
    property DisplayFormat: UnicodeString read FDisplayFormat write SetDisplayFormat stored IsDisplayFormatStored;
    property IncCount: Variant index 0 read GetValue write SetValue stored IsValueStored;
    property MaxValue: Variant index 1 read GetValue write SetValue stored IsValueStored;
    property MinValue: Variant index 2 read GetValue write SetValue stored IsValueStored;
  end;

  { TACLSpinEdit }

  TACLSpinEdit = class(TACLCustomSpinEdit)
  strict private
    FChanging: Boolean;
    FOptionsValue: TACLSpinEditOptionsValue;
    FValidateDelayTimer: TACLTimer;
    FValue: Variant;

    FOnGetDisplayText: TACLEditGetDisplayTextEvent;

    function FormatValue(const AValue: Variant): string;
    procedure HandlerDelayValidate(Sender: TObject);
    function GetEdit: TACLInnerSpinEdit;
    function IsValueStored: Boolean;
    procedure SetOnGetDisplayText(const Value: TACLEditGetDisplayTextEvent);
    procedure SetOptionsValue(const Value: TACLSpinEditOptionsValue);
    procedure SetValue(AValue: Variant);
  protected
    function CreateEditor: TWinControl; override;
    procedure DoButtonClick(AStep: Integer); override;
    procedure DoSpinEditChanged(Sender: TObject);
    procedure SetDefaultSize; override;
    procedure UpdateDisplayValue; virtual;
    //
    function InplaceGetValue: UnicodeString;
    procedure InplaceSetValue(const AValue: UnicodeString);
    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    // Mouse
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    // Messages
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RefreshDisplayValue;
    //
    property Edit: TACLInnerSpinEdit read GetEdit;
  published
    property Align;
    property OptionsValue: TACLSpinEditOptionsValue read FOptionsValue write SetOptionsValue;
    property Value: Variant read FValue write SetValue stored IsValueStored;
    property OnGetDisplayText: TACLEditGetDisplayTextEvent read FOnGetDisplayText write SetOnGetDisplayText;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
  end;

implementation

uses
  System.Math,
  System.Variants,
  System.SysUtils,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.Math,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type
  TWinControlAccess = class(TWinControl);

{ TACLInnerSpinEdit }

procedure TACLInnerSpinEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or ES_CENTER;
end;

function TACLInnerSpinEdit.CheckChar(var AChar: Char): Boolean;
var
  S: UnicodeString;
  X: Double;
begin
  if AChar = '.' then
    AChar := FormatSettings.DecimalSeparator;
  Result := CharInSet(AChar, ['0'..'9', '-', FormatSettings.DecimalSeparator]);
  if Result then
  begin
    S := Text;
    S := Copy(S, 1, SelStart) + AChar + Copy(S, SelStart + SelLength + 1, MaxInt);
    Result := (S = '-') or TryStrToFloat(S, X);
  end;
end;

procedure TACLInnerSpinEdit.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);
  if not (CharInSet(Key, [#3, #$16, Char(VK_BACK)]) or CheckChar(Key)) then
  begin
    Key := #0;
    Beep;
  end;
end;

procedure TACLInnerSpinEdit.WMPaste(var Message: TMessage);
begin
  inherited;
  TACLSpinEdit(Container).UpdateDisplayValue;
end;

function TACLInnerSpinEdit.GetInnerContainer: TWinControl;
begin
  Result := Parent;
end;

procedure TACLInnerSpinEdit.CMTextChanged(var Message: TMessage);
begin
  if not (csLoading in Parent.ComponentState) then
    inherited;
end;

{ TACLCustomSpinEdit }

constructor TACLCustomSpinEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csDoubleClicks];
  FButtonLeft := TACLSpinButtonSubClass.Create(Self);
  FButtonLeft.Tag := -1;
  FButtonRight := TACLSpinButtonSubClass.Create(Self);
  FButtonRight.Tag := 1;
  EditorOpen;
  ResourceChanged;
end;

destructor TACLCustomSpinEdit.Destroy;
begin
  FreeAndNil(FEditor);
  FreeAndNil(FButtonLeft);
  FreeAndNil(FButtonRight);
  inherited Destroy;
end;

procedure TACLCustomSpinEdit.Calculate(R: TRect);
var
  ASize: TSize;
begin
  ASize := StyleButton.Texture.FrameSize;
  ASize.Scale(R.Height, ASize.cy);
  FButtonLeft.IsEnabled := Enabled;
  FButtonLeft.Calculate(Bounds(0, 0, ASize.cx, ASize.cy));
  FButtonRight.IsEnabled := Enabled;
  FButtonRight.Calculate(Bounds(Width - ASize.cx, 0, ASize.cx, ASize.cy));
  EditorUpdateBounds;
end;

procedure TACLCustomSpinEdit.CalculateAutoHeight(var ANewHeight: Integer);
begin
  ANewHeight := Max(StyleButton.Texture.FrameHeight, CalculateTextHeight);
end;

function TACLCustomSpinEdit.CalculateEditorPosition: TRect;
begin
  Result := ClientRect;
  Result.Left := ButtonLeft.Bounds.Right;
  Result.Right := ButtonRight.Bounds.Left;
  if IsWin11OrLater then
    Result.Inflate(0, -dpiApply(acTextIndent, FCurrentPPI))
  else
    Result.Inflate(0, -1);
end;

function TACLCustomSpinEdit.CanOpenEditor: Boolean;
begin
  Result := True;
end;

function TACLCustomSpinEdit.CreateStyleButton: TACLStyleButton;
begin
  Result := TACLStyleSpinButton.Create(Self);
end;

function TACLCustomSpinEdit.HitTest(X, Y: Integer; var ASubClass: TACLCustomButtonSubClass): Boolean;
begin
  if PtInRect(ButtonLeft.Bounds, Point(X, Y)) then
    ASubClass := ButtonLeft
  else
    if PtInRect(ButtonRight.Bounds, Point(X, Y)) then
      ASubClass := ButtonRight
    else
      ASubClass := nil;

  Result := Assigned(ASubClass);
end;

procedure TACLCustomSpinEdit.EditorMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  MouseMove(Shift, X + FEditor.Left, Y + FEditor.Top);
end;

procedure TACLCustomSpinEdit.EditorInitialize;
begin
  inherited EditorInitialize;
  TWinControlAccess(FEditor).OnMouseMove := EditorMouseMove;
end;

procedure TACLCustomSpinEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if HitTest(X, Y, FAutoClickButton) then
    AutoClickTimer := True;
  ButtonLeft.MouseDown(Button, Point(X, Y));
  ButtonRight.MouseDown(Button, Point(X, Y));
end;

procedure TACLCustomSpinEdit.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ASubClass: TACLCustomButtonSubClass;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if HitTest(X, Y, ASubClass) and (ASubClass = FAutoClickButton) then
  begin
    if not AutoClickTimer or (FAutoClickTimerWaitCount > 0) then
      DoButtonClick(Signs[FAutoClickButton = ButtonRight]);
  end;
  ButtonRight.MouseUp(Button, Point(X, Y));
  ButtonLeft.MouseUp(Button, Point(X, Y));
  FAutoClickButton := nil;
  AutoClickTimer := False;
end;

procedure TACLCustomSpinEdit.MouseLeave;
begin
  inherited MouseLeave;
  ButtonRight.MouseMove([], InvalidPoint);
  ButtonLeft.MouseMove([], InvalidPoint);
end;

procedure TACLCustomSpinEdit.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  ButtonRight.MouseMove(Shift, Point(X, Y));
  ButtonLeft.MouseMove(Shift, Point(X, Y));
end;

procedure TACLCustomSpinEdit.DoButtonClick(AStep: Integer);
begin
  // do nothing
end;

procedure TACLCustomSpinEdit.DrawContent(ACanvas: TCanvas);
begin
  ButtonLeft.Draw(ACanvas);
  ButtonRight.Draw(ACanvas);
end;

procedure TACLCustomSpinEdit.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  FullRefresh;
end;

procedure TACLCustomSpinEdit.WMTimer(var Message: TWMTimer);
begin
  inherited;
  if Message.TimerID = NativeUInt(Self) then
  begin
    if FAutoClickTimerWaitCount > 0 then
      Dec(FAutoClickTimerWaitCount)
    else
      if Assigned(FAutoClickButton) then
        DoButtonClick(10 * Signs[FAutoClickButton = ButtonRight])
      else
        AutoClickTimer := False;
  end;
end;

procedure TACLCustomSpinEdit.SetAutoClickTimer(AValue: Boolean);
begin
  if AutoClickTimer <> AValue then
  begin
    FAutoClickTimer := AValue;
    FAutoClickTimerWaitCount := 5;
    if AutoClickTimer then
      SetTimer(Handle, NativeUInt(Self), 100, nil)
    else
      KillTimer(Handle, NativeUInt(Self));
  end;
end;

{ TACLStyleSpinButton }

procedure TACLStyleSpinButton.InitializeTextures;
begin
  Texture.InitailizeDefaults('EditBox.Textures.SpinButton');
end;

{ TACLSpinButtonSubClass }

procedure TACLSpinButtonSubClass.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Texture.Draw(ACanvas, R, Ord(State) + 5 * Ord(Tag > 0));
end;

{ TACLSpinEditOptionsValue }

constructor TACLSpinEditOptionsValue.Create(AOwner: TACLSpinEdit);
begin
  inherited Create;
  FOwner := AOwner;
  FDisplayFormat := DefaultDisplayFormat;
  FValues[0] := 1;
  FValues[1] := 0;
  FValues[2] := 0;
end;

procedure TACLSpinEditOptionsValue.DoAssign(Source: TPersistent);
begin
  if Source is TACLSpinEditOptionsValue then
  begin
    ValueType := TACLSpinEditOptionsValue(Source).ValueType; // first
    MaxValue := TACLSpinEditOptionsValue(Source).MaxValue;
    MinValue := TACLSpinEditOptionsValue(Source).MinValue;
    IncCount := TACLSpinEditOptionsValue(Source).IncCount;
    DisplayFormat := TACLSpinEditOptionsValue(Source).DisplayFormat;
    AssignedValues := TACLSpinEditOptionsValue(Source).AssignedValues; // last
  end;
end;

procedure TACLSpinEditOptionsValue.DoChanged(AChanges: TACLPersistentChanges);
begin
  FOwner.Value := FOwner.Value;
  FOwner.UpdateDisplayValue;
end;

procedure TACLSpinEditOptionsValue.ValidateValue(var V: Variant);
begin
  ValidateValueType(V);
  if seavMaxValue in AssignedValues then
    V := Min(V, MaxValue);
  if seavMinValue in AssignedValues then
    V := Max(V, MinValue);
  ValidateValueType(V);
end;

procedure TACLSpinEditOptionsValue.ValidateValueType(var V: Variant);
const
  MaxValue: Double =  MaxInt / 1.0;
  MinValue: Double = -MaxInt / 1.0;
begin
  V := MinMax(V, MinValue, MaxValue);
  if ValueType = evtInteger then
    V := VarAsType(V, varInteger)
  else
    V := VarAsType(V, varDouble);
end;

function TACLSpinEditOptionsValue.GetValue(const Index: Integer): Variant;
begin
  Result := FValues[Index];
end;

function TACLSpinEditOptionsValue.IsDisplayFormatStored: Boolean;
begin
  Result := FDisplayFormat <> DefaultDisplayFormat;
end;

function TACLSpinEditOptionsValue.IsValueStored(const Index: Integer): Boolean;
begin
  Result := TACLSpinEditAssignedValue(Index) in AssignedValues;
end;

procedure TACLSpinEditOptionsValue.SetAssignedValues(const Value: TACLSpinEditAssignedValues);
begin
  if FAssignedValues <> Value then
  begin
    FAssignedValues := Value;
    Changed([apcLayout]);
  end;
end;

procedure TACLSpinEditOptionsValue.SetDisplayFormat(const Value: UnicodeString);
begin
  if FDisplayFormat <> Value then
  begin
    FDisplayFormat := IfThenW(Value, DefaultDisplayFormat);
    Changed([apcLayout]);
  end;
end;

procedure TACLSpinEditOptionsValue.SetValue(const Index: Integer; const AValue: Variant);
begin
  BeginUpdate;
  try
    AssignedValues := AssignedValues + [TACLSpinEditAssignedValue(Index)];
    if not VarSameValue(GetValue(Index), AValue) then
    begin
      FValues[Index] := AValue;
      ValidateValueType(FValues[Index]);
      case TACLSpinEditAssignedValue(Index) of
        seavMaxValue:
          if seavMinValue in AssignedValues then
            MinValue := Min(MinValue, MaxValue);
        seavMinValue:
          if seavMaxValue in AssignedValues then
            MaxValue := Max(MaxValue, MinValue);
      end;
      Changed([apcLayout]);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLSpinEditOptionsValue.SetValueType(const Value: TACLSpinEditValueType);
var
  I: Integer;
begin
  if FValueType <> Value then
  begin
    FValueType := Value;
    for I := Low(FValues) to High(FValues) do
      ValidateValueType(FValues[I]);
    Changed([apcLayout]);
  end;
end;

{ TACLSpinEdit }

constructor TACLSpinEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOptionsValue := TACLSpinEditOptionsValue.Create(Self);
  FValue := 0;
end;

destructor TACLSpinEdit.Destroy;
begin
  FreeAndNil(FValidateDelayTimer);
  FreeAndNil(FOptionsValue);
  inherited Destroy;
end;

procedure TACLSpinEdit.RefreshDisplayValue;
begin
  if not Edit.Focused then
    UpdateDisplayValue;
end;

function TACLSpinEdit.CreateEditor: TWinControl;
var
  AEdit: TACLInnerSpinEdit;
begin
  AEdit := TACLInnerSpinEdit.Create(nil);
  AEdit.Parent := Self;
  AEdit.Text := '0';
  AEdit.BorderStyle := bsNone;
  AEdit.Ctl3D := False;
  AEdit.OnChange := DoSpinEditChanged;
  Result := AEdit;
end;

procedure TACLSpinEdit.DoButtonClick(AStep: Integer);
begin
  Value := Value + AStep * OptionsValue.IncCount;
  Edit.SelectAll;
end;

procedure TACLSpinEdit.DoSpinEditChanged(Sender: TObject);
begin
  if Edit.Focused then
  begin
    FChanging := True;
    try
      FreeAndNil(FValidateDelayTimer);
      InplaceSetValue(Edit.Text);
      FValidateDelayTimer := TACLTimer.CreateEx(HandlerDelayValidate, 750, True);
    finally
      FChanging := False;
    end;
  end;
end;

procedure TACLSpinEdit.UpdateDisplayValue;
var
  ASelStart: Integer;
begin
  if Edit.Focused then
  begin
    ASelStart := Edit.SelStart;
    Edit.Text := InplaceGetValue;
    Edit.SelStart := ASelStart;
  end
  else
    Edit.Text := FormatValue(InplaceGetValue);
end;

procedure TACLSpinEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  case Key of
    VK_RETURN:
      UpdateDisplayValue;
    VK_UP:
      DoButtonClick(1);
    VK_DOWN:
      DoButtonClick(-1);
  else
    Exit;
  end;
  Key := 0;
end;

function TACLSpinEdit.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if not Result then
  begin
    DoButtonClick(Signs[WheelDelta > 0]);
    Result := True;
  end;
end;

procedure TACLSpinEdit.CMEnter(var Message: TCMEnter);
begin
  inherited;
  UpdateDisplayValue;
  if Edit.AutoSelect and Edit.Focused then
    Edit.SelectAll;
end;

procedure TACLSpinEdit.CMExit(var Message: TCMExit);
begin
  inherited;
  UpdateDisplayValue;
end;

function TACLSpinEdit.InplaceGetValue: UnicodeString;
begin
  if OptionsValue.ValueType = evtInteger then
    Result := IntToStr(Value)
  else
    Result := FormatFloat('0.00######', Value);
end;

procedure TACLSpinEdit.InplaceSetValue(const AValue: UnicodeString);
begin
  Value := StrToFloatDef(AValue, 0);
end;

procedure TACLSpinEdit.HandlerDelayValidate(Sender: TObject);
var
 APrevValue: UnicodeString;
begin
  APrevValue := Edit.Text;
  if (Edit.SelLength = 0) and (APrevValue <> '') then
  begin
    FreeAndNil(FValidateDelayTimer);
    UpdateDisplayValue;
    if Edit.Text <> APrevValue then
      Beep;
  end;
end;

function TACLSpinEdit.GetEdit: TACLInnerSpinEdit;
begin
  Result := FEditor as TACLInnerSpinEdit;
end;

function TACLSpinEdit.IsValueStored: Boolean;
begin
  Result := not VarSameValue(Value, 0);
end;

function TACLSpinEdit.FormatValue(const AValue: Variant): string;
begin
  Result := Format(OptionsValue.DisplayFormat, [AValue]);
  if Assigned(OnGetDisplayText) then
    OnGetDisplayText(Self, AValue, Result);
end;

procedure TACLSpinEdit.SetDefaultSize;
begin
  SetBounds(Left, Top, 100, 20);
end;

procedure TACLSpinEdit.SetOnGetDisplayText(const Value: TACLEditGetDisplayTextEvent);
begin
  FOnGetDisplayText := Value;
  RefreshDisplayValue;
end;

procedure TACLSpinEdit.SetOptionsValue(const Value: TACLSpinEditOptionsValue);
begin
  OptionsValue.Assign(Value);
end;

procedure TACLSpinEdit.SetValue(AValue: Variant);
begin
  OptionsValue.ValidateValue(AValue);
  if not VarSameValue(AValue, FValue) then
  begin
    FValue := AValue;
    if not FChanging then
      UpdateDisplayValue;
    if not (csLoading in ComponentState) then
      Changed;
  end;
end;

end.
