////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Tooltips
//
//  Author:    Artem Izmaylov
//             © 2006-2026
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
  WSLCLClasses,
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
  ACL.Classes,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.TextLayout,
  ACL.Timers,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Desktop,
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

  { TACLHintData }

  PACLHintData = ^TACLHintData;
  TACLHintData = record
    Area: TRect; // aka CursorRect
    Font: string; // ref. acStringToFont
    Text: string;
    TextRect: TRect; // To display hint over the text rect
    procedure Reset;
  end;

  { TACLHintWindow }

  TACLHintWindow = class(THintWindow)
  public const
    HeightCorrection = 4;
  strict private
    FAutoHideTimer: TACLTimer;
    FClickable: Boolean;
    FLayout: TACLTextLayout;
    FOnHide: TThreadMethod;
    FStyle: TACLStyleHint;

    procedure HandlerAutoHide(Sender: TObject);
    procedure SetStyle(AValue: TACLStyleHint);
    //# Messages
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure WMNCHitTest(var Message: TMessage); message WM_NCHITTEST;
    procedure WMMouseWheel(var Message: TMessage); {$IFNDEF FPC}message WM_MOUSEWHEEL;{$ENDIF}
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  protected
  {$IFDEF FPC}
    FCurrentPPI: Integer;
    class procedure WSRegisterClass; override;
  {$ENDIF}

    procedure CreateParams(var Params: TCreateParams); override;
    procedure NCPaint(DC: HDC); {$IFNDEF FPC}override;{$ENDIF}
    procedure Paint; override;
    procedure ScaleForPPI(ATargetDpi: Integer); reintroduce; virtual;
    procedure SetHintData(const AHint: string; AData: TCustomData); virtual;
    procedure StartAutoHideTimer(ATimeOut: Integer);
    procedure UpdateRegion;{$IFDEF FPC}override;{$ENDIF}

    //# Properties
    property Layout: TACLTextLayout read FLayout;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;

    procedure ActivateHint(Rect: TRect; const AHint: string); override; final;
    procedure ActivateHintData(Rect: TRect;
      const AHint: string; AData: TCustomData); override; final;
    procedure ActivateHintDataEx(Rect: TRect;
      const AHint: string; AData: TCustomData; ATargetDpi: Integer); virtual;
    function CalcHintRect(
      const AHint: string; AData: TCustomData): TRect; reintroduce; overload;
    function CalcHintRect(MaxWidth: Integer;
      const AHint: string; AData: TCustomData): TRect; overload; override;
    procedure InitFont(const AFontData: string);

    //# Float Hints
    procedure Hide;
    procedure ShowFloatHint(const AHint: string; AScreenRect: TRect;
      AHorzAlignment: TACLHintWindowHorzAlignment;
      AVertAligment: TACLHintWindowVertAlignment; ATimeOut: Integer = 0); overload;
    procedure ShowFloatHint(const AHint: string; AControl: TControl;
      AHorzAlignment: TACLHintWindowHorzAlignment;
      AVertAligment: TACLHintWindowVertAlignment; ATimeOut: Integer = 0); overload;
    procedure ShowFloatHint(const AHint: string;
      const APoint: TPoint; ATimeOut: Integer = 0); overload;

    //# Properties
    property Clickable: Boolean read FClickable write FClickable;
    property Style: TACLStyleHint read FStyle write SetStyle;
    //# Events
    property OnHide: TThreadMethod read FOnHide write FOnHide;
  end;

implementation

uses
  {$I ACL.UI.Core.Impl.inc},
  ACL.UI.Controls.Base;

{ TACLHintData }

procedure TACLHintData.Reset;
begin
  Area := NullRect;
  Font := EmptyStr;
  Text := EmptyStr;
  TextRect := NullRect;
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
  FreeAndNil(FAutoHideTimer);
  FreeAndNil(FStyle);
  FreeAndNil(FLayout);
  inherited Destroy;
end;

procedure TACLHintWindow.ActivateHint(Rect: TRect; const AHint: string);
begin
  ActivateHintData(Rect, AHint, nil);
end;

procedure TACLHintWindow.ActivateHintData(Rect: TRect; const AHint: string; AData: TCustomData);
begin
  ActivateHintDataEx(Rect, AHint, AData, acGetTargetDPI(Rect.TopLeft));
end;

procedure TACLHintWindow.ActivateHintDataEx(Rect: TRect;
  const AHint: string; AData: TCustomData; ATargetDpi: Integer);
var
  LMonitorBounds: TRect;
  LHintSize: TSize;
begin
  if ATargetDpi <> FCurrentPPI then
  begin
    ScaleForPPI(ATargetDpi);
    Rect := CalcHintRect(AHint, AData) + Rect.TopLeft;
  end;

  Caption := AHint;
  SetHintData(AHint, AData);
  Inc(Rect.Bottom, HeightCorrection);
  LHintSize := Rect.Size;

  LMonitorBounds := MonitorGet(Rect.TopLeft).BoundsRect;
  Rect.Left := Min(Rect.Left, LMonitorBounds.Right - LHintSize.cx);
  Rect.Left := Max(Rect.Left, LMonitorBounds.Left);
  if Rect.Top + LHintSize.cy > LMonitorBounds.Bottom then
    Rect.Top := MouseCursorPos.Y - MouseCursorSize.cy div 2 - LHintSize.cy;
  Rect.Top := Max(Rect.Top, LMonitorBounds.Top);
  Rect.Size := LHintSize;

{$IFDEF FPC}
  BoundsRect := Rect;
  HintRect := Rect;
  Visible := True;
{$ELSE}
  UpdateBoundsRect(Rect);
  SetWindowPos(Handle, HWND_TOPMOST, Rect.Left, Rect.Top, LHintSize.cx, LHintSize.cy, SWP_NOACTIVATE);
  ShowWindow(Handle, SW_SHOWNOACTIVATE);
{$ENDIF}
  Invalidate;
end;

procedure TACLHintWindow.AfterConstruction;
begin
  inherited;
  ScaleForPPI(Screen.PixelsPerInch);
  InitFont('');
end;

function TACLHintWindow.CalcHintRect(const AHint: string; AData: TCustomData): TRect;
begin
  Result := CalcHintRect(Screen.Width div 3, AHint, AData);
end;

function TACLHintWindow.CalcHintRect(MaxWidth: Integer;
  const AHint: string; AData: TCustomData): TRect;
var
  LHintData: PACLHintData absolute AData;
begin
  Layout.Bounds := Rect(0, 0, MaxWidth, 2);
  SetHintData(AHint, AData);
  Layout.Calculate(Canvas);
  Result := TRect.Create(Layout.MeasureSize);

  Inc(Result.Right, 2 * dpiApply(HintTextIndentH, FCurrentPPI));
  Inc(Result.Bottom, 2 * dpiApply(HintTextIndentV, FCurrentPPI));
  Dec(Result.Bottom, HeightCorrection);

  // In this case, we should display hint over the text
  if (LHintData <> nil) and (LHintData.TextRect <> NullRect) then
  begin
    Result.Offset(
      -dpiApply(HintTextIndentH, FCurrentPPI),
      -dpiApply(HintTextIndentV, FCurrentPPI));
  end;
end;

procedure TACLHintWindow.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := WS_POPUP;
  if Owner is TWinControl then
    Params.WndParent := TWinControl(Owner).Handle;
end;

{$IFDEF FPC}
class procedure TACLHintWindow.WSRegisterClass;
const
  Done: Boolean = False;
begin
  if Done then Exit;
  RegisterWSComponent(TACLHintWindow, TACLWSHintWindow);
  Done := True;
end;
{$ENDIF}

procedure TACLHintWindow.HandlerAutoHide(Sender: TObject);
begin
  Hide;
end;

procedure TACLHintWindow.Hide;
begin
  FreeAndNil(FAutoHideTimer);
{$IFDEF FPC}
  Visible := False;
{$ELSE}
  SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_HIDEWINDOW or
    SWP_NOACTIVATE or SWP_NOSIZE or SWP_NOMOVE or SWP_NOZORDER);
{$ENDIF}
  if Assigned(OnHide) then OnHide();
end;

procedure TACLHintWindow.InitFont(const AFontData: string);
begin
  if AFontData <> '' then
    acStringToFont(AFontData, Font)
  else
    Font.Assign(Screen.HintFont, acGetSystemDpi, FCurrentPPI);

  Canvas.Font := Font;
end;

procedure TACLHintWindow.NCPaint(DC: HDC);
begin
  // do nothing
end;

procedure TACLHintWindow.Paint;
var
  LRect: TRect;
begin
  LRect := Rect(0, 0, Width, Height);
  Style.Draw(Canvas, LRect);

  LRect.Inflate(
    -dpiApply(HintTextIndentH, FCurrentPPI),
    -dpiApply(HintTextIndentV, FCurrentPPI));
  Canvas.Font := Font;
  Canvas.Font.Color := Style.ColorText.AsColor;
  Layout.Bounds := LRect;
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
  if AData <> nil then
    InitFont(PACLHintData(AData)^.Font)
  else
    InitFont('');

  Layout.SetText(AHint, TACLTextFormatSettings.Formatted);
end;

procedure TACLHintWindow.SetStyle(AValue: TACLStyleHint);
begin
  FStyle.Assign(AValue);
end;

procedure TACLHintWindow.ShowFloatHint(
  const AHint: string; AScreenRect: TRect;
  AHorzAlignment: TACLHintWindowHorzAlignment;
  AVertAligment: TACLHintWindowVertAlignment;
  ATimeOut: Integer = 0);
const
  IndentFromControl = 6;
var
  LHintPos: TPoint;
  LHintSize: TSize;
begin
  ScaleForPPI(acGetTargetDPI(AScreenRect.TopLeft));

  LHintPos.X := AScreenRect.Left - dpiApply(HintTextIndentH, FCurrentPPI);
  LHintPos.Y := AScreenRect.Top - dpiApply(HintTextIndentV, FCurrentPPI);
  LHintSize := CalcHintRect(AHint, nil).Size;

  case AHorzAlignment of
    hwhaRight:
      LHintPos.X := (AScreenRect.Right - LHintSize.cx);
    hwhaCenter:
      LHintPos.X := (AScreenRect.Right + AScreenRect.Left - LHintSize.cx) div 2;
  else;
  end;

  AScreenRect.Inflate(0, dpiApply(IndentFromControl, FCurrentPPI));

  case AVertAligment of
    hwvaAbove:
      LHintPos.Y := AScreenRect.Top - (LHintSize.cy + HeightCorrection);
    hwvaOver:
      LHintPos.Y := (AScreenRect.Bottom + AScreenRect.Top - (LHintSize.cy + HeightCorrection)) div 2;
    hwvaBelow:
      LHintPos.Y := AScreenRect.Bottom;
  end;

  ActivateHint(TRect.Create(LHintPos, LHintSize), AHint);
  StartAutoHideTimer(ATimeOut);
end;

procedure TACLHintWindow.ShowFloatHint(
  const AHint: string; const APoint: TPoint; ATimeOut: Integer);
var
  LRect: TRect;
begin
  LRect := CalcHintRect(AHint, nil);
  LRect.Location := APoint;
  ActivateHint(LRect, AHint);
  StartAutoHideTimer(ATimeOut);
end;

procedure TACLHintWindow.ShowFloatHint(
  const AHint: string; AControl: TControl;
  AHorzAlignment: TACLHintWindowHorzAlignment;
  AVertAligment: TACLHintWindowVertAlignment;
  ATimeOut: Integer);
begin
  ShowFloatHint(AHint, AControl.ClientRect + AControl.ClientOrigin,
    AHorzAlignment, AVertAligment, ATimeOut);
end;

procedure TACLHintWindow.StartAutoHideTimer(ATimeOut: Integer);
begin
  FreeAndNil(FAutoHideTimer);
  if ATimeOut > 0 then
  begin
    FAutoHideTimer := TACLTimer.CreateEx(HandlerAutoHide, ATimeOut);
    FAutoHideTimer.Start;
  end;
end;

procedure TACLHintWindow.UpdateRegion;
begin
  if HandleAllocated then
    acRegionSetToWindow(Handle, Style.CreateRegion(Rect(0, 0, Width, Height)), True);
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
{$IFNDEF FPC}
  UpdateRegion;
{$ENDIF}
end;

end.
