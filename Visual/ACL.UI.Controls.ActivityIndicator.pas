////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Activity Indicator
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.ActivityIndicator;

{$I ACL.Config.inc}

interface

uses
{$IFDEF MSWINDOWS}
  Windows, // inlining
{$ENDIF}
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
  ACL.Graphics.Ex,
  ACL.Timers,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Labels,
  ACL.UI.Resources,
  ACL.Utils.DPIAware;

type

  { TACLStyleActivityIndicator }

  TACLStyleActivityIndicator = class(TACLStyleLabel)
  protected const
    DotCount = 5;
    DotSize = 7;
    IndentBetweenDots = 5;
  protected
    procedure InitializeResources; override;
  public
    procedure DrawDot(ACanvas: TCanvas; const R: TRect; Active: Boolean);
  published
    property ColorActivity1: TACLResourceColor index 7 read GetColor write SetColor stored IsColorStored;
    property ColorActivity2: TACLResourceColor index 8 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLActivityIndicator }

  TACLActivityIndicator = class(TACLLabel)
  strict private
    FTimer: TACLTimer;

    procedure HandlerTimer(Sender: TObject);
    function GetActive: Boolean;
    function GetIndicatorWidth: Integer;
    function GetStyle: TACLStyleActivityIndicator;
    procedure SetActive(const Value: Boolean);
    procedure SetStyle(const Value: TACLStyleActivityIndicator);
  protected
    procedure Calculate(const R: TRect); override;
    function CreateStyle: TACLStyleLabel; override;
    procedure DrawBackground(ACanvas: TCanvas); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function MeasureSize(AWidth: Integer = 0): TSize; override;
  published
    property Align;
    property Active: Boolean read GetActive write SetActive default False;
    property AutoSize default True;
    property Style: TACLStyleActivityIndicator read GetStyle write SetStyle;
  end;

implementation

{ TACLStyleActivityIndicator }

procedure TACLStyleActivityIndicator.DrawDot(ACanvas: TCanvas; const R: TRect; Active: Boolean);
var
  AColor: TAlphaColor;
  ARect: TRect;
begin
  if Active then
    AColor := ColorActivity2.Value
  else
    AColor := ColorActivity1.Value;

  ARect := R;
  if not Active then
    ARect.Inflate(-2);

  acFillRect(ACanvas, ARect, AColor);
end;

procedure TACLStyleActivityIndicator.InitializeResources;
begin
  inherited;
  ColorActivity1.InitailizeDefaults('Common.Colors.Activity1', True);
  ColorActivity2.InitailizeDefaults('Common.Colors.Activity2', True);
end;

{ TACLActivityIndicator }

constructor TACLActivityIndicator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTimer := TACLTimer.CreateEx(HandlerTimer, 500);
  AutoSize := True;
  Resize;
end;

destructor TACLActivityIndicator.Destroy;
begin
  FreeAndNil(FTimer);
  inherited;
end;

procedure TACLActivityIndicator.Calculate(const R: TRect);
var
  ARect: TRect;
begin
  ARect := R;
  ARect.Right := ARect.Right - GetIndicatorWidth;
  inherited Calculate(ARect);
end;

function TACLActivityIndicator.CreateStyle: TACLStyleLabel;
begin
  Result := TACLStyleActivityIndicator.Create(Self);
end;

procedure TACLActivityIndicator.DrawBackground(ACanvas: TCanvas);
var
  LDotSize: Integer;
  LIndentBetweenDots: Integer;
  LRect: TRect;
  I: Integer;
begin
  inherited;

  LDotSize := dpiApply(Style.DotSize, FCurrentPPI);
  LIndentBetweenDots := dpiApply(Style.IndentBetweenDots, FCurrentPPI);

  // Draw dots
  LRect := ClientRect;
  LRect.CenterVert(LDotSize);
  LRect.Left := LRect.Right - LDotSize;
  for I := Style.DotCount - 1 downto 0 do
  begin
    Style.DrawDot(Canvas, LRect, I = FTimer.Tag);
    LRect.Offset(-LDotSize - LIndentBetweenDots, 0);
  end;
end;

function TACLActivityIndicator.GetActive: Boolean;
begin
  Result := FTimer.Enabled;
end;

function TACLActivityIndicator.GetIndicatorWidth: Integer;
begin
  Result := (
    dpiApply(Style.IndentBetweenDots, FCurrentPPI) +
    dpiApply(Style.DotSize, FCurrentPPI)) * Style.DotCount;
end;

function TACLActivityIndicator.GetStyle: TACLStyleActivityIndicator;
begin
  Result := TACLStyleActivityIndicator(inherited Style);
end;

procedure TACLActivityIndicator.SetActive(const Value: Boolean);
begin
  FTimer.Enabled := Value;
  FTimer.Tag := 0;
end;

procedure TACLActivityIndicator.SetStyle(const Value: TACLStyleActivityIndicator);
begin
  inherited Style := Value;
end;

procedure TACLActivityIndicator.HandlerTimer(Sender: TObject);
begin
  FTimer.Tag := (FTimer.Tag + 1) mod Style.DotCount;
  Invalidate;
end;

function TACLActivityIndicator.MeasureSize(AWidth: Integer): TSize;
var
  LIndicatorWidth: Integer;
begin
  LIndicatorWidth := GetIndicatorWidth;
  if AWidth > 0 then
    Dec(AWidth, LIndicatorWidth);
  Result := inherited MeasureSize(AWidth);
  Result.cy := Max(Result.cy, dpiApply(Style.DotSize, FCurrentPPI));
  Result.cx := Result.cx + LIndicatorWidth;
end;

end.
