////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Multi-monitor support
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Utils.Desktop;

{$I ACL.Config.inc}

interface

uses
{$IFDEF MSWINDOWS}
  {Winapi.}MultiMon,
  {Winapi.}ShellApi,
  {Winapi.}Windows,
{$ELSE}
  LCLIntf,
  LCLType,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Forms,
  // ACL
  ACL.Classes.Collections;

type
  TTaskBarPosition = (tbpLeft, tbpTop, tbpRight, tbpBottom);

  TACLMonitor = TMonitor;

  { TACLTaskbarInfo }

  TACLTaskbarInfo = record
    AutoHide: Boolean;
    Bounds: TRect;
    Position: TTaskBarPosition;
  end;

// Monitors
function MonitorAlignPopupWindow(const R: TRect): TRect;
function MonitorGet(const P: TPoint): TACLMonitor; overload;
function MonitorGet(const R: TRect): TACLMonitor; overload;
function MonitorGet(Wnd: THandle): TACLMonitor; overload;
function MonitorGetBounds(const P: TPoint): TRect; overload;
function MonitorGetBounds(Wnd: THandle): TRect; overload;
function MonitorGetBoundsByIndex(Index: Integer): TRect;
function MonitorGetByIndex(Index: Integer): TACLMonitor;
function MonitorGetDefault: TACLMonitor;
function MonitorGetDefaultBounds: TRect;
function MonitorGetDesktopClientArea(const P: TPoint): TRect;
function MonitorGetFocusedForm: TCustomForm;
function MonitorGetTaskBarInfo: TACLTaskbarInfo;
function MonitorGetTaskBarRect: TRect;
function MonitorGetWorkArea(const P: TPoint): TRect;
function MonitorIsFullScreenApplicationRunning(AMonitor: TACLMonitor = nil): Boolean;
// Mouse
function MouseCurrentWindow: HWND;
function MouseCursorPos: TPoint;
function MouseCursorSize: TSize;
implementation

uses
  ACL.Utils.Common,
  ACL.Utils.Strings;

function MonitorAlignPopupWindow(const R: TRect): TRect;
var
  AWorkArea: TRect;
begin
  Result := R;
  AWorkArea := MonitorGetBounds(Result.CenterPoint);
  if Result.Top < AWorkArea.Top then
    Result.Offset(0, AWorkArea.Top - Result.Top);
  if Result.Left < AWorkArea.Left then
    Result.Offset(AWorkArea.Left - Result.Left, 0);
  if Result.Right > AWorkArea.Right then
    Result.Offset(AWorkArea.Right - Result.Right, 0);
  if Result.Bottom > AWorkArea.Bottom then
    Result.Offset(0, AWorkArea.Bottom - Result.Bottom);
end;

function MonitorGetDefault: TACLMonitor;
begin
  Result := Screen.PrimaryMonitor;
end;

function MonitorGetDefaultBounds: TRect;
var
  AMonitor: TACLMonitor;
begin
  AMonitor := MonitorGetDefault;
  if AMonitor <> nil then
    Result := AMonitor.BoundsRect
  else
    Result := NullRect;
end;

function MonitorGet(Wnd: THandle): TACLMonitor;
begin
  Result := Screen.MonitorFromWindow(Wnd);
  if Result = nil then
    Result := MonitorGetDefault;
end;

function MonitorGet(const P: TPoint): TACLMonitor;
begin
  Result := Screen.MonitorFromPoint(P);
  if Result = nil then
    Result := MonitorGetDefault;
end;

function MonitorGetByIndex(Index: Integer): TACLMonitor;
begin
  if (Index >= 0) and (Index < Screen.MonitorCount) then
    Result := Screen.Monitors[Index]
  else
    Result := MonitorGetDefault;
end;

function MonitorIsFullScreenApplicationRunning(AMonitor: TACLMonitor = nil): Boolean;
{$IFDEF MSWINDOWS}

  function IsDesktopWindow(AHandle: THandle): Boolean;
  begin
    Result := acSameTextEx(acGetClassName(AHandle), ['progman', 'WorkerW']);
  end;

var
  AAppHandle: THandle;
  AAppMonitor: TACLMonitor;
  R: TRect;
begin
  Result := False;
  AAppHandle := GetForegroundWindow;
  if (AAppHandle <> 0) and not IsDesktopWindow(AAppHandle) then
  begin
    AAppMonitor := MonitorGet(AAppHandle);
    if (AMonitor = nil) or (AMonitor = AAppMonitor) then
    begin
      if Assigned(AAppMonitor) and GetWindowRect(AAppHandle, R) then
      begin
        with AAppMonitor.BoundsRect do
          Result := (R.Right - R.Left >= Right - Left) and (R.Bottom - R.Top >= Bottom - Top);
      end;
    end;
  end;
{$ELSE}
begin
  Result := False;
{$ENDIF}
end;

function MonitorGetBoundsByIndex(Index: Integer): TRect;
var
  AMonitor: TACLMonitor;
begin
  AMonitor := MonitorGetByIndex(Index);
  if AMonitor <> nil then
    Result := AMonitor.BoundsRect
  else
    Result := NullRect;
end;

function MonitorGetBounds(Wnd: THandle): TRect;
var
  AMonitor: TACLMonitor;
begin
  AMonitor := MonitorGet(Wnd);
  if AMonitor <> nil then
    Result := AMonitor.BoundsRect
  else
    Result := NullRect;
end;

function MonitorGetBounds(const P: TPoint): TRect;
var
  AMonitor: TACLMonitor;
begin
  AMonitor := MonitorGet(P);
  if AMonitor <> nil then
    Result := AMonitor.BoundsRect
  else
    Result := NullRect;
end;

function MonitorGet(const R: TRect): TACLMonitor;
begin
  Result := MonitorGet(Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
end;

function MonitorGetDesktopClientArea(const P: TPoint): TRect;
var
  ARect: TRect;
  ATaskBar: TACLTaskbarInfo;
begin
  //Note: One of our Forms can be a Desktop toolbar, so, we need to calculate client area manually
  Result := MonitorGetBounds(P);
  ATaskBar := MonitorGetTaskBarInfo;
  if IntersectRect({%H-}ARect, Result, ATaskBar.Bounds) and not ATaskBar.AutoHide then
    case ATaskBar.Position of
      tbpLeft:
        Result.Left := ATaskBar.Bounds.Right;
      tbpTop:
        Result.Top := ATaskBar.Bounds.Bottom;
      tbpRight:
        Result.Right := ATaskBar.Bounds.Left;
      tbpBottom:
        Result.Bottom := ATaskBar.Bounds.Top;
    end;
end;

function MonitorGetFocusedForm: TCustomForm;
var
  AControl: TControl;
begin
  AControl := FindControl(GetFocus);
  if AControl <> nil then
    Result := GetParentForm(AControl)
  else
    Result := nil;
end;

function MonitorGetTaskBarInfo: TACLTaskbarInfo;
{$IFDEF MSWINDOWS}
var
	AData: TAppBarData;
begin
  ZeroMemory(@AData, SizeOf(AData));
  AData.cbSize := SizeOf(TAppBarData);
	AData.Hwnd := FindWindow('ShellTrayWnd', nil);
  if AData.hWnd = 0 then
    AData.Hwnd := FindWindow('Shell_TrayWnd', nil);

  ZeroMemory(@Result, SizeOf(Result));
  if AData.Hwnd <> 0 then
  begin
    SHAppBarMessage(ABM_GETTASKBARPOS, AData);
    Result.Position := TTaskBarPosition(AData.uEdge);
    Result.Bounds := AData.rc;
    Result.AutoHide := SHAppBarMessage(ABM_GETSTATE, AData) and ABS_AUTOHIDE = ABS_AUTOHIDE;
  end;
end;
{$ELSE}
begin
  FillChar(Result{%H-}, SizeOf(Result), 0);
end;
{$ENDIF}

function MonitorGetTaskBarRect: TRect;
begin
  Result := MonitorGetTaskBarInfo.Bounds;
end;

function MonitorGetWorkArea(const P: TPoint): TRect;
var
  AMonitor: TACLMonitor;
begin
  AMonitor := MonitorGet(P);
  if Assigned(AMonitor) then
    Result := AMonitor.WorkareaRect
  else
    Result := NullRect;
end;

function MouseCurrentWindow: HWND;
begin
  Result := WindowFromPoint(MouseCursorPos);
end;

function MouseCursorSize: TSize;
begin
  Result.cx := GetSystemMetrics(SM_CXCURSOR);
  Result.cy := GetSystemMetrics(SM_CYCURSOR);
end;

function MouseCursorPos: TPoint;
begin
  if not GetCursorPos(Result{%H-}) then
    Result := Point(-1, -1);
end;

end.
