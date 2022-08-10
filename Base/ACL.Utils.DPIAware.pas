{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*              DPI Aware Utils              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.DPIAware;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
{$IFNDEF ACL_BASE_NOVCL}
  Vcl.Graphics,
{$ENDIF}
  ACL.Geometry;

const
  acDefaultDPI = 96;
  acMaxDPI = 480;
  acMinDPI = 96;

  acDefaultDPIValues: array[0..7] of Integer = (96, 120, 144, 168, 192, 216, 240, 288);

type

  { TACLScaleFactorHelper }

  TACLScaleFactorHelper = class helper for TACLScaleFactor
  public
    function TargetDPI: Integer;
  end;

{$IFNDEF ACL_BASE_NOVCL}
procedure acAssignFont(ATargetFont, ASourceFont: TFont; ATargetScaleFactor, ASourceScaleFactor: TACLScaleFactor);
{$ENDIF}
function acCheckDPIValue(AValue: Integer): Integer;
function acGetFontHeight(AFontSize: Integer; ATargetDPI: Integer = acDefaultDPI): Integer;
function acGetScaleFactor(AObject: TObject): TACLScaleFactor;
function acGetSystemDPI: Integer;
{$IFNDEF ACL_BASE_NOVCL}
procedure acSetFontHeight(AFont: TFont; AHeight, ATargetDPI: Integer);
{$ENDIF}

function acDefaultScaleFactor: TACLScaleFactor;
function acSystemScaleFactor: TACLScaleFactor;
implementation

uses
{$IFNDEF ACL_BASE_NOVCL}
  ACL.Graphics,
{$ENDIF}
  System.SysUtils,
  System.Math;

type

  { TACLSystemScaleFactor }

  TACLSystemScaleFactor = class(TACLScaleFactor)
  public
    procedure AfterConstruction; override;
    procedure Update;
  end;

var
  FDefaultScaleFactor: TACLScaleFactor;
  FSystemScaleFactor: TACLScaleFactor;

{$IFNDEF ACL_BASE_NOVCL}
procedure acAssignFont(ATargetFont, ASourceFont: TFont; ATargetScaleFactor, ASourceScaleFactor: TACLScaleFactor);
begin
  ATargetFont.Assign(ASourceFont);
  ATargetFont.Height := ATargetScaleFactor.Apply(ASourceScaleFactor.Revert(ASourceFont.Height));
end;
{$ENDIF}

function acCheckDPIValue(AValue: Integer): Integer;
begin
  Result := Min(Max(AValue, acMinDPI), acMaxDPI);
end;

function acGetScaleFactor(AObject: TObject): TACLScaleFactor;
var
  AIntf: IACLScaleFactor;
begin
  if Supports(AObject, IACLScaleFactor, AIntf) then
    Result := AIntf.Value
  else
    Result := acSystemScaleFactor;
end;

function acGetFontHeight(AFontSize: Integer; ATargetDPI: Integer = acDefaultDPI): Integer;
begin
  Result := -MulDiv(AFontSize, ATargetDPI, 72);
end;

function acGetSystemDPI: Integer;
var
  DC: Integer;
begin
  DC := GetDC(0);
  try
    // #AI: don't use cached value
    Result := GetDeviceCaps(DC, LOGPIXELSY);
  finally
    ReleaseDC(0, DC);
  end;
end;

{$IFNDEF ACL_BASE_NOVCL}
procedure acSetFontHeight(AFont: TFont; AHeight, ATargetDPI: Integer);
var
  APrevPixelsPerInch: Integer;
  ATextMetric: TTextMetricW;
begin
  if ATargetDPI <> acDefaultDPI then
  begin
    if AHeight > 0 then
    begin
      APrevPixelsPerInch := MeasureCanvas.Font.PixelsPerInch;
      try
        //#AI: https://support.microsoft.com/en-us/help/74299/info-calculating-the-logical-height-and-point-size-of-a-font
        MeasureCanvas.Font := AFont;
        MeasureCanvas.Font.PixelsPerInch := acDefaultDPI;
        MeasureCanvas.Font.Height := AHeight;
        GetTextMetrics(MeasureCanvas.Handle, ATextMetric);
      finally
        MeasureCanvas.Font.PixelsPerInch := APrevPixelsPerInch;
      end;
      AHeight := -(ATextMetric.tmHeight - ATextMetric.tmInternalLeading);
    end;
    AHeight := MulDiv(AHeight, ATargetDPI, acDefaultDPI)
  end;
  AFont.Height := AHeight;
end;
{$ENDIF}

function acDefaultScaleFactor: TACLScaleFactor;
begin
  if FDefaultScaleFactor = nil then
    FDefaultScaleFactor := TACLScaleFactor.Create;
  Result := FDefaultScaleFactor;
end;

function acSystemScaleFactor: TACLScaleFactor;
begin
  if FSystemScaleFactor = nil then
    FSystemScaleFactor := TACLSystemScaleFactor.Create;
  Result := FSystemScaleFactor;
end;

{ TACLSystemScaleFactor }

procedure TACLSystemScaleFactor.AfterConstruction;
begin
  inherited;
  Update;
end;

procedure TACLSystemScaleFactor.Update;
begin
  Assign(acGetSystemDPI, acDefaultDPI);
end;

{ TACLScaleFactorHelper }

function TACLScaleFactorHelper.TargetDPI: Integer;
begin
  Result := Apply(acDefaultDPI);
end;

initialization

finalization
  FreeAndNil(FDefaultScaleFactor);
  FreeAndNil(FSystemScaleFactor);
end.
