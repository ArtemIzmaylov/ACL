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
  {System.}Variants,
  {System.}Types,
  System.UITypes,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  // ACL
  ACL.Classes,
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.Timers,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.DPIAware;

type
  TACLSpinEditValueType = (evtInteger, evtFloat);

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
    procedure Calculate(R: TRect); override;
    procedure CalculateAutoHeight(var ANewHeight: Integer); override;
    function CalculateEditorPosition: TRect; override;
    function CanOpenEditor: Boolean; override;
    //# Buttons
    function ButtonAtPos(X, Y: Integer; out AButton: TACLCustomButtonSubClass): Boolean;
    procedure ButtonClick(AStep: Integer); virtual;
    function CreateStyleButton: TACLStyleButton; override;
    //# Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    //# Paint
    procedure DrawContent(ACanvas: TCanvas); override;
    //# Messages
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure WMTimer(var Message: TWMTimer); message WM_TIMER;
    //# Properties
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
    //# Events
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

  TACLSpinEdit = class;
  TACLSpinEditAssignedValue = (seavIncCount, seavMaxValue, seavMinValue);
  TACLSpinEditAssignedValues = set of TACLSpinEditAssignedValue;

  TACLSpinEditOptionsValue = class(TACLLockablePersistent)
  strict private const
    DefaultDisplayFormat = '%s';
  strict private
    FAssignedValues: TACLSpinEditAssignedValues;
    FDisplayFormat: string;
    FOwner: TACLSpinEdit;
    FValues: array[0..2] of Variant;
    FValueType: TACLSpinEditValueType;

    function GetValue(const Index: Integer): Variant;
    function IsDisplayFormatStored: Boolean;
    function IsValueStored(const Index: Integer): Boolean;
    procedure SetAssignedValues(const Value: TACLSpinEditAssignedValues);
    procedure SetDisplayFormat(const Value: string);
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
    property ValueType: TACLSpinEditValueType read FValueType write SetValueType default evtInteger; // first!
    property AssignedValues: TACLSpinEditAssignedValues read FAssignedValues write SetAssignedValues stored False;
    property DisplayFormat: string read FDisplayFormat write SetDisplayFormat stored IsDisplayFormatStored;
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
    function GetInnerEdit: TACLInnerEdit;
    function IsValueStored: Boolean;
    procedure SetOnGetDisplayText(const Value: TACLEditGetDisplayTextEvent);
    procedure SetOptionsValue(const Value: TACLSpinEditOptionsValue);
    procedure SetValue(AValue: Variant);
  protected
    procedure ButtonClick(AStep: Integer); override;
    function CreateEditor: TWinControl; override;
    procedure EditorUpdateParamsCore; override;
    procedure DoSpinEditChanged(Sender: TObject);
    procedure SetDefaultSize; override;
    procedure UpdateDisplayValue; virtual;
    // Inplace
    function InplaceGetValue: string;
    procedure InplaceSetValue(const AValue: string);
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
    //# Properties
    property InnerEdit: TACLInnerEdit read GetInnerEdit;
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
{$IFNDEF FPC}
  ACL.Graphics.SkinImageSet, // inlinging
{$ENDIF}
  ACL.Geometry,
  ACL.Graphics,
  ACL.Math,
  ACL.Utils.Common,
  ACL.Utils.Strings;

{ TACLCustomSpinEdit }

constructor TACLCustomSpinEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csDoubleClicks];
  FButtonLeft := TACLSpinButtonSubClass.Create(Self);
  FButtonLeft.Tag := -1;
  FButtonRight := TACLSpinButtonSubClass.Create(Self);
  FButtonRight.Tag := 1;
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
  ASize.Height := R.Height;
  FButtonLeft.IsEnabled := Enabled;
  FButtonLeft.Calculate(Bounds(0, 0, ASize.cx, ASize.cy));
  FButtonRight.IsEnabled := Enabled;
  FButtonRight.Calculate(Bounds(Width - ASize.cx, 0, ASize.cx, ASize.cy));
  EditorUpdateBounds;
end;

procedure TACLCustomSpinEdit.CalculateAutoHeight(var ANewHeight: Integer);
begin
  ANewHeight := CalculateTextHeight + 2 * 1{border size};
  ANewHeight := Max(ANewHeight, StyleButton.Texture.FrameHeight);
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

function TACLCustomSpinEdit.ButtonAtPos(X, Y: Integer; out AButton: TACLCustomButtonSubClass): Boolean;
begin
  if PtInRect(ButtonLeft.Bounds, Point(X, Y)) then
    AButton := ButtonLeft
  else if PtInRect(ButtonRight.Bounds, Point(X, Y)) then
    AButton := ButtonRight
  else
    AButton := nil;

  Result := Assigned(AButton);
end;

procedure TACLCustomSpinEdit.ButtonClick(AStep: Integer);
begin
  // do nothing
end;

function TACLCustomSpinEdit.CreateStyleButton: TACLStyleButton;
begin
  Result := TACLStyleSpinButton.Create(Self);
end;

procedure TACLCustomSpinEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if ButtonAtPos(X, Y, FAutoClickButton) then
    AutoClickTimer := True;
  ButtonLeft.MouseDown(Button, Point(X, Y));
  ButtonRight.MouseDown(Button, Point(X, Y));
end;

procedure TACLCustomSpinEdit.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LButton: TACLCustomButtonSubClass;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if ButtonAtPos(X, Y, LButton) and (LButton = FAutoClickButton) then
  begin
    if not AutoClickTimer or (FAutoClickTimerWaitCount > 0) then
      ButtonClick(Signs[FAutoClickButton = ButtonRight]);
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

procedure TACLCustomSpinEdit.DrawContent(ACanvas: TCanvas);
var
  LInnerBounds: TRect;
  LPrevClip: HRGN;
begin
  LPrevClip := acSaveClipRegion(ACanvas.Handle);
  try
    LInnerBounds := ClientRect;
    if Borders then
      LInnerBounds.Inflate(-1, -1);
    if acIntersectClipRegion(ACanvas.Handle, LInnerBounds) then
    begin
      ButtonLeft.Draw(ACanvas);
      ButtonRight.Draw(ACanvas);
    end;
  finally
    acRestoreClipRegion(ACanvas.Handle, LPrevClip);
  end;
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
        ButtonClick(10 * Signs[FAutoClickButton = ButtonRight])
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
  FOwner.EditorUpdateParams;
  FOwner.Value := FOwner.Value;
  FOwner.UpdateDisplayValue;
end;

procedure TACLSpinEditOptionsValue.ValidateValue(var V: Variant);
begin
  ValidateValueType(V);
  if seavMaxValue in AssignedValues then
    V := Min(Double(V), Double(MaxValue));
  if seavMinValue in AssignedValues then
    V := Max(Double(V), Double(MinValue));
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

procedure TACLSpinEditOptionsValue.SetDisplayFormat(const Value: string);
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
            MinValue := Min(Double(MinValue), Double(MaxValue));
        seavMinValue:
          if seavMaxValue in AssignedValues then
            MaxValue := Max(Double(MaxValue), Double(MinValue));
      else;
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
  if not InnerEdit.Focused then
    UpdateDisplayValue;
end;

function TACLSpinEdit.CreateEditor: TWinControl;
var
  AEdit: TACLInnerEdit;
begin
  AEdit := TACLInnerEdit.Create(Self);
  AEdit.Alignment := taCenter;
  AEdit.Parent := Self;
  AEdit.Text := '0';
  AEdit.OnChange := DoSpinEditChanged;
  AEdit.OnValidate := UpdateDisplayValue;
  Result := AEdit;
end;

procedure TACLSpinEdit.EditorUpdateParamsCore;
const
  Map: array[TACLSpinEditValueType] of TACLEditInputMask = (eimInteger, eimFloat);
begin
  InnerEdit.InputMask := Map[OptionsValue.ValueType];
  inherited;
end;

procedure TACLSpinEdit.ButtonClick(AStep: Integer);
begin
  Value := Value + AStep * OptionsValue.IncCount;
  InnerEdit.SelectAll;
end;

procedure TACLSpinEdit.DoSpinEditChanged(Sender: TObject);
begin
  if InnerEdit.Focused then
  begin
    FChanging := True;
    try
      FreeAndNil(FValidateDelayTimer);
      InplaceSetValue(InnerEdit.Text);
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
  if InnerEdit.Focused then
  begin
    ASelStart := InnerEdit.SelStart;
    InnerEdit.Text := InplaceGetValue;
    InnerEdit.SelStart := ASelStart;
  end
  else
    InnerEdit.Text := FormatValue(InplaceGetValue);
end;

procedure TACLSpinEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  case Key of
    VK_RETURN:
      UpdateDisplayValue;
    VK_UP:
      ButtonClick(1);
    VK_DOWN:
      ButtonClick(-1);
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
    ButtonClick(Signs[WheelDelta > 0]);
    Result := True;
  end;
end;

procedure TACLSpinEdit.CMEnter(var Message: TCMEnter);
begin
  inherited;
  UpdateDisplayValue;
  if InnerEdit.AutoSelect and InnerEdit.Focused then
    InnerEdit.SelectAll;
end;

procedure TACLSpinEdit.CMExit(var Message: TCMExit);
begin
  inherited;
  UpdateDisplayValue;
end;

function TACLSpinEdit.InplaceGetValue: string;
begin
  if OptionsValue.ValueType = evtInteger then
    Result := IntToStr(Value)
  else
    Result := FormatFloat('0.00######', Value);
end;

procedure TACLSpinEdit.InplaceSetValue(const AValue: string);
begin
  Value := StrToFloatDef(AValue, 0);
end;

procedure TACLSpinEdit.HandlerDelayValidate(Sender: TObject);
var
 APrevValue: string;
begin
  APrevValue := InnerEdit.Text;
  if (InnerEdit.SelLength = 0) and (APrevValue <> '') then
  begin
    FreeAndNil(FValidateDelayTimer);
    UpdateDisplayValue;
    if InnerEdit.Text <> APrevValue then Beep;
  end;
end;

function TACLSpinEdit.GetInnerEdit: TACLInnerEdit;
begin
  Result := FEditor as TACLInnerEdit;
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
