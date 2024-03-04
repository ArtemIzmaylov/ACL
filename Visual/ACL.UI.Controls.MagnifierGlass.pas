{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*          Magnifier Glass Control          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.MagnifierGlass;

{$I ACL.Config.inc} // FPC:OK

interface

uses
  Messages,
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // VCL
  {Vcl.}Graphics,
  // ACL
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Timers,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Resources,
  ACL.Utils.DPIAware;

type

  { TACLStyleMagnifierGlass }

  TACLStyleMagnifierGlass = class(TACLStyleBackground)
  protected
    procedure InitializeResources; override;
  published
    property ColorGridLine: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLMagnifierGlass }

  TACLMagnifierGlass = class(TACLContainer)
  strict private
    FBuffer: TACLDib;
    FColorAtPoint: TColor;
    FShowGridLines: Boolean;
    FZoom: Integer;
    FZoomedSize: TSize;

    FOnUpdate: TNotifyEvent;

    function GetForegroundColor(ABackgroundColor: TColor): TColor;
    function GetStyle: TACLStyleMagnifierGlass;
    function GetZoomActual: Integer;
    procedure SetShowGridLines(AValue: Boolean);
    procedure SetStyle(const Value: TACLStyleMagnifierGlass);
    procedure SetZoom(AZoom: Integer);
    procedure WMTimer(var Message: TMessage); message WM_TIMER;
  protected
    procedure DoUpdate;

    function CreateStyle: TACLStyleBackground; override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure Loaded; override;
    procedure Paint; override;
    procedure PrepareBuffer(const ACursorPos: TPoint);
    procedure Resize; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateSizes;
    //# Properties
    property ZoomActual: Integer read GetZoomActual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //# Properties
    property ColorAtPoint: TColor read FColorAtPoint;
  published
    property Align;
    property DoubleBuffered default True;
    property ShowGridLines: Boolean read FShowGridLines write SetShowGridLines default True;
    property Style: TACLStyleMagnifierGlass read GetStyle write SetStyle;
    property Zoom: Integer read FZoom write SetZoom default 2;
    //# Events
    property OnUpdate: TNotifyEvent read FOnUpdate write FOnUpdate;
  end;

implementation

uses
  // ACL
  ACL.Utils.Common,
  ACL.Utils.Desktop;

{ TACLStyleMagnifierGlass }

procedure TACLStyleMagnifierGlass.InitializeResources;
begin
  inherited;
  ColorGridLine.InitailizeDefaults('Common.Colors.Text', False);
end;

{ TACLMagnifierGlass }

constructor TACLMagnifierGlass.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DoubleBuffered := True;
  FShowGridLines := True;
  FBuffer := TACLBitmapLayer.Create(BoundsRect);
  FZoom := 2;
  Resize;
end;

destructor TACLMagnifierGlass.Destroy;
begin
  FreeAndNil(FBuffer);
  inherited Destroy;
end;

function TACLMagnifierGlass.CreateStyle: TACLStyleBackground;
begin
  Result := TACLStyleMagnifierGlass.Create(Self);
end;

procedure TACLMagnifierGlass.CreateWnd;
begin
  inherited CreateWnd;
  SetTimer(Handle, 1, 33, nil);
end;

procedure TACLMagnifierGlass.DestroyWnd;
begin
  KillTimer(Handle, 1);
  inherited DestroyWnd;
end;

procedure TACLMagnifierGlass.DoUpdate;
begin
  if Assigned(OnUpdate) then OnUpdate(Self);
end;

procedure TACLMagnifierGlass.Resize;
begin
  inherited Resize;
  UpdateSizes;
end;

procedure TACLMagnifierGlass.Loaded;
begin
  inherited Loaded;
  Resize;
end;

procedure TACLMagnifierGlass.Paint;
begin
  PrepareBuffer(MouseCursorPos);
  FBuffer.DrawCopy(Canvas.Handle, NullPoint);
  inherited Paint;
end;

procedure TACLMagnifierGlass.PrepareBuffer(const ACursorPos: TPoint);

  procedure DrawBackground(ACanvas: TCanvas; const R: TRect);
  begin
    if csDesigning in ComponentState then
      acFillRect(ACanvas, R, Style.ColorContent1.AsColor)
    else
    begin
      acFillRect(ACanvas, R, clBlack);
      acStretchBlt(ACanvas.Handle, ScreenCanvas.Handle, R, Bounds(
        ACursorPos.X - FZoomedSize.cx div 2 + 1,
        ACursorPos.Y - FZoomedSize.cy div 2 + 1,
        FZoomedSize.cx, FZoomedSize.cy));
      ScreenCanvas.Release;
    end;
  end;

  procedure DrawGridLines(DC: HDC; const R: TRect);
  var
    ABrush: THandle;
    I, W, S: Integer;
  begin
    S := Ord(ZoomActual >= 20) + Ord(ZoomActual >= 5);
    ABrush := CreateSolidBrush(Style.ColorGridLine.AsColor);
    for I := R.Left to Trunc(R.Right / ZoomActual) - 1 do
    begin
      W := S * Ord(I mod 10 = 0);
      FillRect(DC, Rect(I * ZoomActual - W, 0, I * ZoomActual + 1 + W, Height), ABrush);
    end;
    for I := R.Top to Trunc(R.Bottom / ZoomActual) - 1 do
    begin
      W := S * Ord(I mod 10 = 0);
      FillRect(DC, Rect(0, I * ZoomActual - W, Width, I * ZoomActual + 1 + W), ABrush);
    end;
    DeleteObject(ABrush);
  end;

var
  X, Y, S: Integer;
begin
  if not FBuffer.Empty then
  begin
    DrawBackground(FBuffer.Canvas, FBuffer.ClientRect);
    if (Zoom > 2) and ShowGridLines then
      DrawGridLines(FBuffer.Canvas.Handle, FBuffer.ClientRect);

    X := Trunc(FBuffer.Width  / (2 * ZoomActual)) * ZoomActual - ZoomActual div 2;
    Y := Trunc(FBuffer.Height / (2 * ZoomActual)) * ZoomActual - ZoomActual div 2;
    if PtInRect(FBuffer.ClientRect, Point(X, Y)) then
      FColorAtPoint := FBuffer.Colors^[X + Y * FBuffer.Width].ToColor;

    S := dpiApply(6, FCurrentPPI);
    FBuffer.Canvas.Pen.Color := GetForegroundColor(ColorAtPoint);
    FBuffer.Canvas.MoveTo(X - S + 1, Y);
    FBuffer.Canvas.LineTo(X + S, Y);
    FBuffer.Canvas.MoveTo(X, Y - S + 1);
    FBuffer.Canvas.LineTo(X, Y + S);
  end;
end;

procedure TACLMagnifierGlass.UpdateSizes;
var
  AOldBuffer: TACLDib;
begin
  FZoomedSize.cx := Trunc(Width / ZoomActual);
  FZoomedSize.cy := Trunc(Height / ZoomActual);

  AOldBuffer := FBuffer;
  FBuffer := TACLDib.Create(Width - Width mod ZoomActual, Height - Height mod ZoomActual);
  FreeAndNil(AOldBuffer);
end;

function TACLMagnifierGlass.GetForegroundColor(ABackgroundColor: TColor): TColor;
var
  H, S, L: Byte;
begin
  TACLColors.RGBtoHSLi(ABackgroundColor, H, S, L);
  TACLColors.HSLtoRGBi((Integer(H) + 128) mod 256, MaxByte, 128, Result);
end;

function TACLMagnifierGlass.GetStyle: TACLStyleMagnifierGlass;
begin
  Result := TACLStyleMagnifierGlass(inherited Style);
end;

function TACLMagnifierGlass.GetZoomActual: Integer;
begin
  Result := dpiApply(Zoom, FCurrentPPI);
end;

procedure TACLMagnifierGlass.SetShowGridLines(AValue: Boolean);
begin
  if FShowGridLines <> AValue then
  begin
    FShowGridLines := AValue;
    Invalidate;
  end;
end;

procedure TACLMagnifierGlass.SetStyle(const Value: TACLStyleMagnifierGlass);
begin
  inherited Style := Value;
end;

procedure TACLMagnifierGlass.SetTargetDPI(AValue: Integer);
begin
  inherited;
  UpdateSizes;
end;

procedure TACLMagnifierGlass.SetZoom(AZoom: Integer);
begin
  AZoom := EnsureRange(AZoom, 2, 50);
  if AZoom <> FZoom then
  begin
    FZoom := AZoom;
    UpdateSizes;
    Invalidate;
  end;
end;

procedure TACLMagnifierGlass.WMTimer(var Message: TMessage);
begin
  DoUpdate;
  Invalidate;
end;

end.
