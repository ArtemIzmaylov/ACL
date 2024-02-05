﻿{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*        Activity Indicator Control         *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.ActivityIndicator;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  // ACL
  ACL.Math,
  ACL.Classes,
  ACL.Timers,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
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

    function GetActive: Boolean;
    function GetStyle: TACLStyleActivityIndicator;
    function GetTextOffset: Integer;
    procedure SetActive(const Value: Boolean);
    procedure SetStyle(const Value: TACLStyleActivityIndicator);
    //
    procedure HandlerTimer(Sender: TObject);
  protected
    procedure Calculate(const R: TRect); override;
    function CreateStyle: TACLStyleLabel; override;
    procedure DrawBackground(ACanvas: TCanvas); override;
    function MeasureSize(AWidth: Integer = 0): TSize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Align;
    property Active: Boolean read GetActive write SetActive default False;
    property AutoSize default True;
    property Style: TACLStyleActivityIndicator read GetStyle write SetStyle;
  end;

implementation

uses
  System.Math;

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

  acFillRect(ACanvas.Handle, ARect, AColor);
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
  ARect.Right := ARect.Right - GetTextOffset;
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
begin
  inherited;

  LDotSize := dpiApply(Style.DotSize, FCurrentPPI);
  LIndentBetweenDots := dpiApply(Style.IndentBetweenDots, FCurrentPPI);

  // Draw dots
  LRect := ClientRect;
  LRect.CenterVert(LDotSize);
  LRect.Left := LRect.Right - LDotSize;
  for var I := Style.DotCount - 1 downto 0 do
  begin
    Style.DrawDot(Canvas, LRect, I = FTimer.Tag);
    LRect.Offset(-LDotSize - LIndentBetweenDots, 0);
  end;
end;

function TACLActivityIndicator.GetActive: Boolean;
begin
  Result := FTimer.Enabled;
end;

function TACLActivityIndicator.GetStyle: TACLStyleActivityIndicator;
begin
  Result := TACLStyleActivityIndicator(inherited Style);
end;

function TACLActivityIndicator.GetTextOffset: Integer;
begin
  Result := (dpiApply(Style.IndentBetweenDots, FCurrentPPI) + dpiApply(Style.DotSize, FCurrentPPI)) * Style.DotCount;
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
begin
  if AWidth > 0 then
    Dec(AWidth, GetTextOffset);
  Result := inherited MeasureSize(AWidth);
  Result.cy := Max(Result.cy, dpiApply(Style.DotSize, FCurrentPPI));
  Result.cx := Result.cx + GetTextOffset;
end;

end.
