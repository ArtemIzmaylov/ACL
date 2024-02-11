{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*              DPI Aware Utils              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.DPIAware;

{$I ACL.Config.inc} // FPC:OK

{$IF DEFINED(FPC) OR NOT DEFINED(ACL_BASE_NOVCL)}
  {$DEFINE USE_VCL}
{$IFEND}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}Types,
  // VCL
{$IFDEF USE_VCL}
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
{$ENDIF}
  // ACL
  ACL.Geometry;

const
  acDefaultDpi = 96;
  acMaxDpi = 480;
  acMinDpi = 96;

  acDefaultDpiValues: array[0..7] of Integer = (96, 120, 144, 168, 192, 216, 240, 288);

type

  { IACLCurrentDpi }

  IACLCurrentDpi = interface
  ['{4941434C-536F-7572-6365-445049000000}']
    function GetCurrentDpi: Integer;
  end;

var
  FSystemDpiCache: Integer = 0; // for internal use

function acCheckDpiValue(AValue: Integer): Integer; inline; deprecated 'use EnsureRange directly';
function acGetCurrentDpi(AObject: TObject): Integer; inline;
function acGetSystemDpi: Integer;
function acTryGetCurrentDpi(AObject: TObject): Integer; // returns 0 if failed

// Fonts
{$IFDEF USE_VCL}
procedure acAssignFont(ATargetFont, ASourceFont: TFont; ATargetDpi, ASourceDpi: Integer);
{$ENDIF}
function acGetFontHeight(AFontSize: Integer; ATargetDpi: Integer = acDefaultDpi): Integer;
function acGetTargetDPI(const APoint: TPoint): Integer; overload;
{$IFDEF USE_VCL}
function acGetTargetDPI(const AControl: TWinControl): Integer; overload;
procedure acSetFontHeight(AFont: TFont; AHeight, ATargetDpi: Integer);
{$ENDIF}

function dpiApply(const AValue: Integer; ATargetDpi: Integer): Integer; overload; inline;
function dpiApply(const AValue: TPoint; ATargetDpi: Integer): TPoint; overload; inline;
function dpiApply(const AValue: TRect; ATargetDpi: Integer): TRect; overload; inline;
function dpiApply(const AValue: TSize; ATargetDpi: Integer): TSize; overload; inline;

function dpiRevert(const AValue: Integer; ASourceDpi: Integer): Integer; overload; inline;
function dpiRevert(const AValue: TPoint; ASourceDpi: Integer): TPoint; overload; inline;
function dpiRevert(const AValue: TRect; ASourceDpi: Integer): TRect; overload; inline;
function dpiRevert(const AValue: TSize; ASourceDpi: Integer): TSize; overload; inline;
implementation

uses
{$IFDEF LCLGtk2}
  gdk2,
{$ENDIF}
{$IFDEF USE_VCL}
  ACL.Graphics,
{$ENDIF}
{$IFDEF MSWINDOWS}
  ACL.Utils.Common,
  ACL.Utils.Desktop,
{$ENDIF}
  {System.}SysUtils;

{$IF DEFINED(USE_VCL)}
type
  TControlAccess = class(TControl);
{$ENDIF}

{$IFDEF LCLGtk2}
function gdk_screen_get_default: Pointer; cdecl; external gdklib;
function gdk_screen_get_resolution(screen: Pointer): Double; cdecl; external gdklib;
{$ENDIF}

function acCheckDpiValue(AValue: Integer): Integer;
begin
  Result := EnsureRange(AValue, acMinDpi, acMaxDpi);
end;

{$IFDEF USE_VCL}
procedure acAssignFont(ATargetFont, ASourceFont: TFont; ATargetDpi, ASourceDpi: Integer);
begin
  ATargetFont.Assign(ASourceFont);
  ATargetFont.Height := dpiApply(dpiRevert(ASourceFont.Height, ASourceDpi), ATargetDpi);
end;

procedure acSetFontHeight(AFont: TFont; AHeight, ATargetDpi: Integer);
var
  APrevPixelsPerInch: Integer;
  ATextMetric: TTextMetric;
begin
  if (ATargetDpi > 0) and (ATargetDpi <> acDefaultDpi) then
  begin
    if AHeight > 0 then
    begin
      APrevPixelsPerInch := MeasureCanvas.Font.PixelsPerInch;
      try
        // AI:
        // https://support.microsoft.com/en-us/help/74299/info-calculating-the-logical-height-and-point-size-of-a-font
        // https://jeffpar.github.io/kbarchive/kb/074/Q74299/
        //
        //                   -(Point Size * LOGPIXELSY)
        //          height = --------------------------
        //                                72
        //
        //          ----------  <------------------------------
        //          |        |           |- Internal Leading  |
        //          | |   |  |  <---------                    |
        //          | |   |  |        |                       |- Cell Height
        //          | |---|  |        |- Character Height     |
        //          | |   |  |        |                       |
        //          | |   |  |        |                       |
        //          ----------  <------------------------------
        //
        //        The following formula computes the point size of a font:
        //
        //                       (Height - Internal Leading) * 72
        //          Point Size = --------------------------------
        //                                  LOGPIXELSY
        //
        MeasureCanvas.Font := AFont;
        MeasureCanvas.Font.PixelsPerInch := acDefaultDpi;
        MeasureCanvas.Font.Height := AHeight;
        GetTextMetrics(MeasureCanvas.Handle, ATextMetric{%H-});
      finally
        MeasureCanvas.Font.PixelsPerInch := APrevPixelsPerInch;
      end;
      AHeight := -(ATextMetric.tmHeight - ATextMetric.tmInternalLeading);
    end;
    AHeight := MulDiv(AHeight, ATargetDpi, acDefaultDpi)
  end;
  AFont.Height := AHeight;
end;
{$ENDIF}

function acGetCurrentDpi(AObject: TObject): Integer;
begin
  Result := acTryGetCurrentDpi(AObject);
  if Result = 0 then
    Result := acGetSystemDpi;
end;

function acGetFontHeight(AFontSize: Integer; ATargetDpi: Integer): Integer;
begin
  Result := -MulDiv(AFontSize, ATargetDpi, 72);
end;

function acGetTargetDPI(const APoint: TPoint): Integer;
begin
{$IFDEF MSWINDOWS}
  if IsWin8OrLater then
    Result := MonitorGet(APoint).PixelsPerInch
  else
{$ENDIF}
    Result := acGetSystemDpi;
end;

{$IFDEF USE_VCL}
function acGetTargetDPI(const AControl: TWinControl): Integer;
var
{$IFDEF MSWINDOWS}
  LPlacement: TWindowPlacement;
{$ENDIF}
  LPosition: TPoint;
begin
{$IFDEF MSWINDOWS}
  LPlacement.length := SizeOf(TWindowPlacement);
  if GetWindowPlacement(AControl.Handle, LPlacement) then
    LPosition := LPlacement.rcNormalPosition.CenterPoint
  else
{$ENDIF}
    LPosition := AControl.ClientToScreen(AControl.ClientRect.CenterPoint);

  Result := acGetTargetDPI(LPosition);
end;
{$ENDIF}

function acGetSystemDpi: Integer;
var
  DC: Integer;
begin
  if FSystemDpiCache = 0 then
  begin
  {$IFDEF FPC}
    // AI, 12.10.2023
    // До тех пор, пока приложение не будет инициализировано (Application.Initialize)
    // Screen.PixelsPerInch / Monitor.PixelsPerInch будут возвращать минимально допустимый ppi - 72
    if not (AppInitialized in Application.Flags) then
    begin
    {$IFDEF LCLGtk2}
      FSystemDpiCache := Round(gdk_screen_get_resolution(gdk_screen_get_default));
    {$ELSE}
      FSystemDpiCache := acDefaultDpi;
    {$ENDIF}
    end
    else
  {$ENDIF}
    begin
      DC := GetDC(0);
      try
        FSystemDpiCache := GetDeviceCaps(DC, LOGPIXELSY);
      finally
        ReleaseDC(0, DC);
      end;
    end;
  end;
  Result := FSystemDpiCache;
end;

function acTryGetCurrentDpi(AObject: TObject): Integer;
var
  AIntf: IACLCurrentDpi;
begin
  if Supports(AObject, IACLCurrentDpi, AIntf) then
    Exit(AIntf.GetCurrentDpi);
{$IF DEFINED(USE_VCL)}
  if AObject is TControl then
  begin
  {$IFDEF FPC}
    Exit(TControlAccess(AObject).Scale96ToScreen(96));
  {$ELSE}
    Exit(TControlAccess(AObject).FCurrentPPI);
  {$ENDIF}
  end;
{$IFEND}
  if AObject is TComponent then
    Exit(acTryGetCurrentDpi(TComponent(AObject).Owner));
  Result := 0;
end;

function dpiApply(const AValue: Integer; ATargetDpi: Integer): Integer;
begin
  if ATargetDpi <> acDefaultDpi then
    Result := MulDiv(AValue, ATargetDpi, acDefaultDpi)
  else
    Result := AValue;
end;

function dpiApply(const AValue: TPoint; ATargetDpi: Integer): TPoint;
begin
  Result := AValue;
  if ATargetDpi <> acDefaultDpi then
    Result.Scale(ATargetDpi, acDefaultDpi);
end;

function dpiApply(const AValue: TRect; ATargetDpi: Integer): TRect;
begin
  Result := AValue;
  if ATargetDpi <> acDefaultDpi then
    Result.Scale(ATargetDpi, acDefaultDpi);
end;

function dpiApply(const AValue: TSize; ATargetDpi: Integer): TSize;
begin
  Result := AValue;
  if ATargetDpi <> acDefaultDpi then
    Result.Scale(ATargetDpi, acDefaultDpi);
end;

function dpiRevert(const AValue: Integer; ASourceDpi: Integer): Integer;
begin
  if ASourceDpi <> acDefaultDpi then
    Result := MulDiv(AValue, acDefaultDpi, ASourceDpi)
  else
    Result := AValue;
end;

function dpiRevert(const AValue: TPoint; ASourceDpi: Integer): TPoint;
begin
  if ASourceDpi <> acDefaultDpi then
  begin
    Result.X := MulDiv(AValue.X, acDefaultDpi, ASourceDpi);
    Result.Y := MulDiv(AValue.Y, acDefaultDpi, ASourceDpi);
  end
  else
    Result := AValue;
end;

function dpiRevert(const AValue: TRect; ASourceDpi: Integer): TRect; overload; inline;
begin
  if ASourceDpi <> acDefaultDpi then
  begin
    Result.Bottom := MulDiv(AValue.Bottom, acDefaultDpi, ASourceDpi);
    Result.Left := MulDiv(AValue.Left, acDefaultDpi, ASourceDpi);
    Result.Right := MulDiv(AValue.Right, acDefaultDpi, ASourceDpi);
    Result.Top := MulDiv(AValue.Top, acDefaultDpi, ASourceDpi);
  end
  else
    Result := AValue;
end;

function dpiRevert(const AValue: TSize; ASourceDpi: Integer): TSize; overload; inline;
begin
  if ASourceDpi <> acDefaultDpi then
  begin
    Result.cX := MulDiv(AValue.cX, acDefaultDpi, ASourceDpi);
    Result.cY := MulDiv(AValue.cY, acDefaultDpi, ASourceDpi);
  end
  else
    Result := AValue;
end;

end.
