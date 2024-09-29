////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Tooltips and their controllers
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.HintWindow;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}DwmApi,
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
  // ACL
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.TextLayout,
  ACL.Timers,
  ACL.UI.Resources,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

const
  HintTextIndentH = 8;
  HintTextIndentV = 5;

type
{$IFDEF FPC}
  TCustomData = Pointer;
{$ENDIF}

  TACLHintWindowHorzAlignment = (hwhaLeft, hwhaCenter, hwhaRight);
  TACLHintWindowVertAlignment = (hwvaAbove, hwvaOver, hwvaBelow);

  { TACLHintData }

  TACLHintData = record
    AlignHorz: TACLHintWindowHorzAlignment;
    AlignVert: TACLHintWindowVertAlignment;
    DelayBeforeShow: Cardinal;
    ScreenBounds: TRect;
    Text: string;

    class operator Equal(const V1, V2: TACLHintData): Boolean;
    class operator NotEqual(const V1, V2: TACLHintData): Boolean;
    procedure Reset;
  end;

  { TACLStyleHint }

  TACLStyleHint = class(TACLStyle)
  strict private
    FRadius: Integer;
  protected
    procedure InitializeResources; override;
  public
    procedure AfterConstruction; override;
    function CreateRegion(const R: TRect): TRegionHandle;
    procedure Draw(ACanvas: TCanvas; const R: TRect);
    //# Properties
    property Radius: Integer read FRadius;
  published
    property ColorBorder: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorContent1: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorContent2: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorText: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLHintWindow }

  TACLHintWindow = class(THintWindow)
  public const
    HeightCorrection = 4;
  strict private
    FClickable: Boolean;
    FLayout: TACLTextLayout;
    FStyle: TACLStyleHint;

    procedure SetStyle(AValue: TACLStyleHint);
    //# Messages
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure WMNCHitTest(var Message: TMessage); message WM_NCHITTEST;
    procedure WMMouseWheel(var Message: TMessage); {$IFNDEF FPC}message WM_MOUSEWHEEL;{$ENDIF}
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  protected
  {$IFDEF FPC}
    FCurrentPPI: Integer;
  {$ENDIF}
    procedure CreateParams(var Params: TCreateParams); override;
    procedure NCPaint(DC: HDC); {$IFNDEF FPC}override;{$ENDIF}
    procedure Paint; override;
    procedure ScaleForPPI(ATargetDpi: Integer); reintroduce; virtual;
    procedure SetHintData(const AHint: string; AData: TCustomData); virtual;
    //# Properties
    property Layout: TACLTextLayout read FLayout;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure ActivateHint(Rect: TRect; const AHint: string); override;
    procedure ActivateHintData(Rect: TRect;
      const AHint: string; AData: TCustomData); override;
    function CalcHintRect(MaxWidth: Integer;
      const AHint: string; AData: TCustomData): TRect; overload; override;
    procedure Hide;
    //# FloatHints
    procedure ShowFloatHint(const AHint: string; const AScreenRect: TRect;
      AHorzAlignment: TACLHintWindowHorzAlignment; AVertAligment: TACLHintWindowVertAlignment); overload;
    procedure ShowFloatHint(const AHint: string; const AControl: TControl;
      AHorzAlignment: TACLHintWindowHorzAlignment; AVertAligment: TACLHintWindowVertAlignment); overload;
    procedure ShowFloatHint(const AHint: string; const P: TPoint); overload;
    //# Properties
    property Clickable: Boolean read FClickable write FClickable;
    property Style: TACLStyleHint read FStyle write SetStyle;
  end;

  { TACLHintController }

  TACLHintPauseMode = (hpmBeforeShow, hpmBeforeHide);

  TACLHintController = class
  strict private
    FDeactivateTimer: TACLTimer;
    FHintData: TACLHintData;
    FHintOwner: TObject;
    FHintPoint: TPoint;
    FHintWindow: TACLHintWindow;
    FPauseMode: TACLHintPauseMode;
    FPauseTimer: TACLTimer;

    function CanShowHintOverOwner: Boolean;
    function GetOwnerForm(out AForm: TCustomForm): Boolean;
    function IsFormActive(AForm: TCustomForm): Boolean;
    procedure DeactivateTimerHandler(Sender: TObject);
    procedure PauseTimerHandler(Sender: TObject);
  protected
    function CanShowHint(AHintOwner: TObject;
      const AHintData: TACLHintData): Boolean; virtual;
    function CreateHintWindow: TACLHintWindow; virtual;
    function GetOwnerControl: TWinControl; virtual;
    //# Properties
    property HintData: TACLHintData read FHintData;
    property HintOwner: TObject read FHintOwner;
    property HintPoint: TPoint read FHintPoint;
    property HintWindow: TACLHintWindow read FHintWindow;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Cancel;
    procedure Hide;
    procedure Update(AHintOwner: TObject;
      const AHintPoint: TPoint; const AHintData: TACLHintData);
  end;

implementation

uses
  ACL.Classes,
  ACL.UI.Menus,
  ACL.Utils.Common,
  ACL.Utils.Desktop;

{ TACLHintData }

class operator TACLHintData.Equal(const V1, V2: TACLHintData): Boolean;
begin
  Result :=
    (V1.AlignHorz = V2.AlignHorz) and
    (V1.AlignVert = V2.AlignVert) and
    (V1.DelayBeforeShow = V2.DelayBeforeShow) and
    (V1.ScreenBounds = V2.ScreenBounds) and
    (V1.Text = V2.Text);
end;

class operator TACLHintData.NotEqual(const V1, V2: TACLHintData): Boolean;
begin
  Result := not (V1 = V2);
end;

procedure TACLHintData.Reset;
begin
  AlignHorz := hwhaLeft;
  AlignVert := hwvaOver;
  DelayBeforeShow := Application.HintPause;
  ScreenBounds := NullRect;
  Text := EmptyStr;
end;

{ TACLStyleHint }

procedure TACLStyleHint.AfterConstruction;
begin
  inherited AfterConstruction;
{$IFNDEF FPC}
  FRadius := IfThen(acOSCheckVersion(6, 2), 0, 3);
{$ENDIF}
end;

function TACLStyleHint.CreateRegion(const R: TRect): TRegionHandle;
begin
  if Radius > 0 then
    Result := CreateRoundRectRgn(R.Left + 1, R.Top + 1, R.Right, R.Bottom, Radius, Radius)
  else
    Result := 0;
end;

procedure TACLStyleHint.Draw(ACanvas: TCanvas; const R: TRect);
begin
  acDrawGradient(ACanvas, R, ColorContent1.AsColor, ColorContent2.AsColor);
  if Radius > 0 then
  begin
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Color := ColorBorder.AsColor;
    ACanvas.RoundRect(R.Left + 1, R.Top + 1, R.Right - 1, R.Bottom - 1, Radius * 2, Radius * 2);
    ACanvas.RoundRect(R.Left + 1, R.Top + 1, R.Right - 1, R.Bottom - 1, Radius, Radius);
  end
  else
    acDrawFrame(ACanvas, R, ColorBorder.AsColor);
end;

procedure TACLStyleHint.InitializeResources;
begin
  inherited InitializeResources;
  ColorBorder.InitailizeDefaults('Hint.Colors.Border');
  ColorContent1.InitailizeDefaults('Hint.Colors.Background1');
  ColorContent2.InitailizeDefaults('Hint.Colors.Background2');
  ColorText.InitailizeDefaults('Hint.Colors.Text');
end;

{ TACLHintWindow }

constructor TACLHintWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DoubleBuffered := True;
  FStyle := TACLStyleHint.Create(Self);
  FLayout := TACLTextLayout.Create(Canvas.Font);
  FLayout.Options := atoWordWrap or atoAutoHeight;
{$IFDEF FPC}
  FCurrentPPI := acDefaultDpi;
{$ENDIF}
end;

destructor TACLHintWindow.Destroy;
begin
  FreeAndNil(FStyle);
  FreeAndNil(FLayout);
  inherited Destroy;
end;

procedure TACLHintWindow.ActivateHint(Rect: TRect; const AHint: string);
begin
  ActivateHintData(Rect, AHint, nil);
end;

procedure TACLHintWindow.ActivateHintData(Rect: TRect; const AHint: string; AData: TCustomData);
var
  AMonitor: TACLMonitor;
  AMonitorBounds: TRect;
  AHintSize: TSize;
begin
  if (AHint <> Caption) or not IsWindowVisible(Handle) then
  begin
    AMonitor := MonitorGet(Rect.TopLeft);
    if AMonitor.PixelsPerInch <> FCurrentPPI then
    begin
      ScaleForPPI(AMonitor.PixelsPerInch);
      Rect := CalcHintRect(Screen.Width div 3, AHint, AData) + Rect.TopLeft;
    end;

    Caption := AHint;
    SetHintData(AHint, AData);
    Inc(Rect.Bottom, HeightCorrection);
    AHintSize := Rect.Size;

    AMonitorBounds := AMonitor.BoundsRect;
    Rect.Top := Min(Rect.Top,  AMonitorBounds.Bottom - AHintSize.cy);
    Rect.Top := Max(Rect.Top, AMonitorBounds.Top);
    Rect.Left := Min(Rect.Left, AMonitorBounds.Right - AHintSize.cx);
    Rect.Left := Max(Rect.Left, AMonitorBounds.Left);
    Rect.Size := AHintSize;

  {$IFDEF FPC}
    BoundsRect := Rect;
    HintRect := Rect;
    Visible := True;
  {$ELSE}
    UpdateBoundsRect(Rect);
    SetWindowPos(Handle, HWND_TOPMOST,
      Rect.Left, Rect.Top, AHintSize.cx, AHintSize.cy, SWP_NOACTIVATE);
    ShowWindow(Handle, SW_SHOWNOACTIVATE);
  {$ENDIF}
    Invalidate;
  end;
end;

procedure TACLHintWindow.AfterConstruction;
begin
  inherited;
  ScaleForPPI(Screen.PixelsPerInch);
  Font := Screen.HintFont; // after ScaleForPPI
end;

function TACLHintWindow.CalcHintRect(
  MaxWidth: Integer; const AHint: string; AData: TCustomData): TRect;
begin
  Canvas.Font := Font;
  Layout.Bounds := Rect(0, 0, MaxWidth, 2);
  SetHintData(AHint, AData);
  Layout.Calculate(Canvas);
  Result := TRect.Create(Layout.MeasureSize);

  Inc(Result.Right, 2 * dpiApply(HintTextIndentH, FCurrentPPI));
  Inc(Result.Bottom, 2 * dpiApply(HintTextIndentV, FCurrentPPI));
  Dec(Result.Bottom, HeightCorrection);
end;

procedure TACLHintWindow.Hide;
begin
{$IFDEF FPC}
  Visible := False;
{$ELSE}
  SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_HIDEWINDOW or
    SWP_NOACTIVATE or SWP_NOSIZE or SWP_NOMOVE or SWP_NOZORDER);
{$ENDIF}
end;

procedure TACLHintWindow.ShowFloatHint(
  const AHint: string; const AScreenRect: TRect;
  AHorzAlignment: TACLHintWindowHorzAlignment;
  AVertAligment: TACLHintWindowVertAlignment);
const
  Indent = 6;
var
  AHintPos: TPoint;
  AHintSize: TSize;
begin
  ScaleForPPI(MonitorGet(AScreenRect.TopLeft).PixelsPerInch);
  AHintPos.X := AScreenRect.Left - dpiApply(HintTextIndentH, FCurrentPPI);
  AHintPos.Y := AScreenRect.Top - dpiApply(HintTextIndentV, FCurrentPPI);
  AHintSize := CalcHintRect(Screen.Width div 3, AHint, nil).Size;

  case AHorzAlignment of
    hwhaRight:
      AHintPos.X := (AScreenRect.Right - AHintSize.cx);
    hwhaCenter:
      AHintPos.X := (AScreenRect.Right + AScreenRect.Left - AHintSize.cx) div 2;
  else;
  end;

  case AVertAligment of
    hwvaAbove:
      AHintPos.Y := AScreenRect.Top - (AHintSize.cy + HeightCorrection) - dpiApply(Indent, FCurrentPPI);
    hwvaBelow:
      AHintPos.Y := AScreenRect.Bottom + dpiApply(Indent, FCurrentPPI);
    hwvaOver:
      AHintPos.Y := (AScreenRect.Bottom + AScreenRect.Top - (AHintSize.cy + HeightCorrection)) div 2;
  end;

  ActivateHint(Bounds(AHintPos.X, AHintPos.Y, AHintSize.cx, AHintSize.cy), AHint);
end;

procedure TACLHintWindow.ShowFloatHint(const AHint: string; const P: TPoint);
var
  LRect: TRect;
begin
  LRect := CalcHintRect(Screen.Width div 3, AHint, nil);
  LRect.Location := P;
  ActivateHint(LRect, AHint);
end;

procedure TACLHintWindow.ShowFloatHint(const AHint: string; const AControl: TControl;
  AHorzAlignment: TACLHintWindowHorzAlignment; AVertAligment: TACLHintWindowVertAlignment);
begin
  ShowFloatHint(AHint, AControl.ClientRect + AControl.ClientOrigin, AHorzAlignment, AVertAligment);
end;

procedure TACLHintWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP;
  if Owner is TWinControl then
    Params.WndParent := TWinControl(Owner).Handle;
end;

procedure TACLHintWindow.NCPaint(DC: HDC);
begin
  // do nothing
end;

procedure TACLHintWindow.Paint;
begin
  Style.Draw(Canvas, ClientRect);

  Canvas.Font := Font;
  Canvas.Font.Color := Style.ColorText.AsColor;
  Layout.Bounds :=
    ClientRect.InflateTo(
      -dpiApply(HintTextIndentH, FCurrentPPI),
      -dpiApply(HintTextIndentV, FCurrentPPI));
  Layout.Draw(Canvas);
end;

procedure TACLHintWindow.ScaleForPPI(ATargetDpi: Integer);
begin
  if FCurrentPPI <> ATargetDpi then
  begin
  {$IFDEF FPC}
    FCurrentPPI := ATargetDpi;
  {$ELSE}
    ChangeScale(ATargetDpi, FCurrentPPI, True);
  {$ENDIF}
    Layout.TargetDpi := ATargetDpi;
    Style.TargetDpi := ATargetDpi;
  end;
end;

procedure TACLHintWindow.SetHintData(const AHint: string; AData: TCustomData);
begin
  Layout.SetText(AHint, TACLTextFormatSettings.Formatted);
end;

procedure TACLHintWindow.SetStyle(AValue: TACLStyleHint);
begin
  FStyle.Assign(AValue);
end;

procedure TACLHintWindow.CMTextChanged(var Message: TMessage);
begin
  Layout.SetText(Caption, TACLTextFormatSettings.Formatted);
end;

procedure TACLHintWindow.WMNCHitTest(var Message: TMessage);
begin
  if Clickable then
    Message.Result := HTCLIENT
  else
    Message.Result := HTTRANSPARENT;
end;

procedure TACLHintWindow.WMMouseWheel(var Message: TMessage);
begin
  Hide;
end;

procedure TACLHintWindow.WMSize(var Message: TWMSize);
begin
  inherited;
  if HandleAllocated then
    SetWindowRgn(Handle, Style.CreateRegion(Rect(0, 0, Width, Height)), True);
end;

{ TACLHintController }

constructor TACLHintController.Create;
begin
  inherited Create;
  FPauseTimer := TACLTimer.CreateEx(PauseTimerHandler);
end;

destructor TACLHintController.Destroy;
begin
  Cancel;
  FreeAndNil(FPauseTimer);
  inherited Destroy;
end;

procedure TACLHintController.Cancel;
begin
  Hide;
  FHintOwner := nil;
end;

procedure TACLHintController.Hide;
begin
  FPauseTimer.Enabled := False;
  FreeAndNil(FDeactivateTimer);
  FreeAndNil(FHintWindow);
end;

procedure TACLHintController.Update(AHintOwner: TObject;
  const AHintPoint: TPoint; const AHintData: TACLHintData);
begin
  if (HintOwner <> AHintOwner) or (HintData <> AHintData) or (FHintPoint <> AHintPoint) then
  begin
    Cancel;
    if CanShowHint(AHintOwner, AHintData) then
    begin
      FHintOwner := AHintOwner;
      FHintData := AHintData;
      FPauseMode := hpmBeforeShow;
      FPauseTimer.Interval := Max(1, HintData.DelayBeforeShow);
      FPauseTimer.Enabled := True;
    end;
  end;
  FHintPoint := AHintPoint;
  FHintData := AHintData;
end;

function TACLHintController.CanShowHint(
  AHintOwner: TObject; const AHintData: TACLHintData): Boolean;
var
  LForm: TCustomForm;
begin
  Result := Application.ShowHint and (AHintOwner <> nil) and (AHintData.Text <> '') and
    GetOwnerForm(LForm) and IsFormActive(LForm) and not acMenusHasActivePopup;
end;

function TACLHintController.CanShowHintOverOwner: Boolean;
begin
  // Otherwise cases, the hint does not want to be transparent for mouse (for some reason)
  // and prevents the user from clicking on the item
{$IFDEF MSWINDOWS}
  if IsWine then
    Exit(False);
  if (TOSVersion.Build = 6) and (TOSVersion.Build = 1) then
    Exit(DwmCompositionEnabled);
  Result := acOSCheckVersion(6, 0);
{$ELSE}
  Result := True;
{$ENDIF}
end;

function TACLHintController.CreateHintWindow: TACLHintWindow;
begin
  Result := TACLHintWindow.Create(GetOwnerControl);
end;

function TACLHintController.GetOwnerControl: TWinControl;
begin
  Result := nil;
end;

function TACLHintController.GetOwnerForm(out AForm: TCustomForm): Boolean;
var
  LCtrl: TWinControl;
begin
  LCtrl := GetOwnerControl;
  if LCtrl <> nil then
    AForm := GetParentForm(LCtrl)
  else
    AForm := nil;
  Result := AForm <> nil;
end;

function TACLHintController.IsFormActive(AForm: TCustomForm): Boolean;
begin
  Result := (AForm <> nil) and ((AForm.ParentWindow <> 0) or AForm.Active);
end;

procedure TACLHintController.DeactivateTimerHandler(Sender: TObject);
var
  LForm: TCustomForm;
begin
  if GetOwnerForm(LForm) and not IsFormActive(LForm) or
    not ((HintWindow <> nil) and IsWindowVisible(HintWindow.Handle))
  then
    Hide;
end;

procedure TACLHintController.PauseTimerHandler(Sender: TObject);
var
  LHintPos: TPoint;
begin
  case FPauseMode of
    hpmBeforeHide:
      Hide;
    hpmBeforeShow:
      begin
        if HintWindow = nil then
          FHintWindow := CreateHintWindow;

        if HintData.ScreenBounds.IsEmpty or (FHintData.AlignVert = hwvaOver) and not CanShowHintOverOwner then
        begin
          LHintPos := HintPoint;
          LHintPos.Offset(0, {$IFDEF FPC}25{$ELSE}Screen.CursorHeightMargin{$ENDIF});
          HintWindow.ShowFloatHint(HintData.Text, LHintPos);
        end
        else
          HintWindow.ShowFloatHint(HintData.Text,
            HintData.ScreenBounds,
            HintData.AlignHorz,
            HintData.AlignVert);

        if FDeactivateTimer = nil then
          FDeactivateTimer := TACLTimer.CreateEx(DeactivateTimerHandler, 10, True);
        FPauseTimer.Interval := Application.HintHidePause;
        FPauseMode := hpmBeforeHide;
      end;
  end;
end;

end.
