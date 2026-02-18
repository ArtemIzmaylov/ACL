////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Multi-monitor support
//
//  Author:    Artem Izmaylov
//             © 2006-2025
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
  ACL.Classes.Collections,
  ACL.Utils.Common;

type
  TTaskBarPosition = (tbpLeft, tbpTop, tbpRight, tbpBottom);

  { TACLMonitor }

  TACLMonitor = record
    BoundsRect: TRect;
    MonitorNum: Integer;
    WorkareaRect: TRect;
    function PixelsPerInch: Integer;
    class function Null: TACLMonitor; static;
    class operator Equal(const V1, V2: TACLMonitor): Boolean;
  end;

  { TACLTaskbarInfo }

  TACLTaskbarInfo = record
    AutoHide: Boolean;
    Bounds: TRect;
    BoundsMonitor: TRect;
    Position: TTaskBarPosition;
  end;

// Monitors
function MonitorAlignPopupWindow(const AControlRect: TRect): TRect;
function MonitorGet(const APoint: TPoint): TACLMonitor; overload;
function MonitorGet(const AWnd: TWndHandle): TACLMonitor; overload;
function MonitorGetByIndex(Index: Integer): TACLMonitor;
function MonitorGetDefault: TACLMonitor;

// Одна из наших форм может быть тулбаром рабочего стола - усекать WorkArea,
// и нам нужно знать доступное для нее пространство за вычетом таскабра.
function MonitorGetDesktopClientArea(const P: TPoint): TRect;

function MonitorGetTaskBarInfo: TACLTaskbarInfo;
function MonitorIsFullScreenApplicationRunning(const AMonitor: TACLMonitor): Boolean;

// Mouse
function MouseCurrentWindow: TWndHandle;
function MouseCursorPos: TPoint;
function MouseCursorSize: TSize;
implementation

uses
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

function MonitorAlignPopupWindow(const AControlRect: TRect): TRect;
var
  LRect: TRect;
begin
  Result := AControlRect;
  LRect := MonitorGet(Result.CenterPoint).BoundsRect;
  if Result.Top < LRect.Top then
    Result.Offset(0, LRect.Top - Result.Top);
  if Result.Left < LRect.Left then
    Result.Offset(LRect.Left - Result.Left, 0);
  if Result.Right > LRect.Right then
    Result.Offset(LRect.Right - Result.Right, 0);
  if Result.Bottom > LRect.Bottom then
    Result.Offset(0, LRect.Bottom - Result.Bottom);
end;

function MonitorGetInfo(AMonitor: TMonitor): TACLMonitor;
var
  LInfo: TMonitorInfo;
begin
  if AMonitor = nil then
    Exit(MonitorGetDefault);

  ZeroMemory(@LInfo, SizeOf(LInfo));
  LInfo.cbSize := SizeOf(LInfo);
  if GetMonitorInfo(AMonitor.Handle, @LInfo) then
  begin
    Result.MonitorNum := AMonitor.MonitorNum;
    Result.BoundsRect := LInfo.rcMonitor;
    Result.WorkareaRect := LInfo.rcWork;
  end
  else
  begin
    Result := TACLMonitor.Null;
    Result.MonitorNum := AMonitor.MonitorNum;
  end;
end;

function MonitorGet(const AWnd: TWndHandle): TACLMonitor;
begin
  if AWnd <> 0 then
    Result := MonitorGetInfo(Screen.MonitorFromWindow(AWnd))
  else
    Result := MonitorGetDefault;
end;

function MonitorGet(const APoint: TPoint): TACLMonitor;
begin
  Result := MonitorGetInfo(Screen.MonitorFromPoint(APoint));
end;

function MonitorGetDefault: TACLMonitor;
var
  LMonitor: TMonitor;
  LMonitorCount: Integer;
begin
  LMonitor := nil;
  LMonitorCount := Screen.MonitorCount;
  if (LMonitor = nil) and (LMonitorCount > 1) then
    LMonitor := Screen.PrimaryMonitor;
  if (LMonitor = nil) and (LMonitorCount > 0) then
    LMonitor := Screen.Monitors[0];
  if (LMonitor <> nil) then
    Result := MonitorGetInfo(LMonitor)
  else
    Result := TACLMonitor.Null;
end;

function MonitorGetByIndex(Index: Integer): TACLMonitor;
begin
  if (Index >= 0) and (Index < Screen.MonitorCount) then
    Result := MonitorGetInfo(Screen.Monitors[Index])
  else
    Result := MonitorGetDefault;
end;

function MonitorIsFullScreenApplicationRunning(const AMonitor: TACLMonitor): Boolean;
{$IFDEF MSWINDOWS}

  function IsDesktopWindow(AHandle: TWndHandle): Boolean;
  begin
    Result := acContains(acGetClassName(AHandle), ['progman', 'WorkerW'], True);
  end;

var
  LAppHandle: TWndHandle;
  LAppMonitor: TACLMonitor;
  LRect: TRect;
begin
  Result := False;
  LAppHandle := GetForegroundWindow;
  if (LAppHandle <> 0) and not IsDesktopWindow(LAppHandle) then
  begin
    LAppMonitor := MonitorGet(LAppHandle);
    if AMonitor = LAppMonitor then
    begin
      if GetWindowRect(LAppHandle, LRect) then
      begin
        with LAppMonitor.BoundsRect do
          Result := (LRect.Width >= Width) and (LRect.Height >= Height);
      end;
    end;
  end;
{$ELSE}
begin
  Result := False;
{$ENDIF}
end;

function MonitorGetDesktopClientArea(const P: TPoint): TRect;
{$IFDEF MSWINDOWS}
var
  LRect: TRect;
  LRects: array[0..3] of TRect;
  LTaskBar: TACLTaskbarInfo;
begin
  Result := MonitorGet(P).BoundsRect;
  // Одна из наших форм может быть тулбаром рабочего стола - усекать WorkArea,
  // и нам нужно знать доступное для нее пространство за вычетом таскабра.
  // Посему все считаем вручную
  LTaskBar := MonitorGetTaskBarInfo;
  if LTaskBar.AutoHide or LTaskBar.Bounds.IsEmpty then
    Exit;
  if Result.IntersectsWith(LTaskBar.Bounds) then // окно на другом мониторе
  begin
    // У чела стоит Start11 и таскбар закреплен вверху экрана, однако API говорит,
    // что Position = Bottom, но Bounds-ы возвращаются корректные (для Top-а)
    // В итоге у нас получается рект с нулевой площадью, что приводит к поломке попапов
    //    case ATaskBar.Position of
    //      tbpLeft:
    //        Result.Left := ATaskBar.Bounds.Right;
    //      tbpTop:
    //        Result.Top := ATaskBar.Bounds.Bottom;
    //      tbpRight:
    //        Result.Right := ATaskBar.Bounds.Left;
    //      tbpBottom:
    //        Result.Bottom := ATaskBar.Bounds.Top;
    //    end;
    // Поэтому делаем так: вычитаем рект taskbar-а, а в качестве результата
    // возвращаем рект наибольшей площади
    // +-----------+
    // +     0     +
    // +-----------+
    // + 1 - T - 2 +
    // +-----------+
    // +     3     +
    // -------------
    LRects[0] := Rect(Result.Left, Result.Top, Result.Right, LTaskBar.Bounds.Top);
    LRects[1] := Rect(Result.Left, LTaskBar.Bounds.Top, LTaskBar.Bounds.Left, LTaskBar.Bounds.Bottom);
    LRects[2] := Rect(LTaskBar.Bounds.Right, LTaskBar.Bounds.Top, Result.Right, LTaskBar.Bounds.Bottom);
    LRects[3] := Rect(Result.Left, LTaskBar.Bounds.Bottom, Result.Right, Result.Bottom);
    Result := LRects[0];
    for LRect in LRects do
    begin
      if LRect.Width * LRect.Height > Result.Width * Result.Height then
        Result := LRect;
    end;
  end;
{$ELSE}
begin
  // В Linux наши формы не поддерживают режим тулбара рабочего стола
  Result := MonitorGet(P).WorkareaRect;
{$ENDIF}
end;

function MonitorGetTaskBarInfo: TACLTaskbarInfo;
{$IFDEF MSWINDOWS}
var
  AData: TAppBarData;
begin
  ZeroMemory(@Result, SizeOf(Result));
  ZeroMemory(@AData, SizeOf(AData));
  AData.cbSize := SizeOf(TAppBarData);
  AData.Hwnd := FindWindow('ShellTrayWnd', nil);
  if AData.hWnd = 0 then
    AData.Hwnd := FindWindow('Shell_TrayWnd', nil);
  if AData.Hwnd <> 0 then
  begin
    SHAppBarMessage(ABM_GETTASKBARPOS, AData);
    Result.AutoHide := SHAppBarMessage(ABM_GETSTATE, AData) and ABS_AUTOHIDE = ABS_AUTOHIDE;
    Result.Position := TTaskBarPosition(AData.uEdge);
    Result.BoundsMonitor := MonitorGet(AData.rc.CenterPoint).BoundsRect;
    Result.Bounds := AData.rc;
  end;
end;
{$ELSE}
var
  LMonitor: TACLMonitor;
begin
  LMonitor := MonitorGetDefault;
  Result.AutoHide := False;
  Result.BoundsMonitor := LMonitor.BoundsRect;
  // Область уведомлений сверху (Ubuntu, Gnome-based linux)
  if LMonitor.WorkareaRect.Top > LMonitor.BoundsRect.Top then
  begin
    Result.Bounds := Result.BoundsMonitor;
    Result.Bounds.Bottom := LMonitor.WorkareaRect.Top;
    Result.Position := tbpTop;
  end
  else
  // Обычная панель задач (KDE Plasma, Mate, Cinnamon)
  //if LMonitor.WorkareaRect.Bottom < LMonitor.BoundsRect.Bottom then
  begin
    Result.Bounds := Result.BoundsMonitor;
    Result.Bounds.Top := LMonitor.WorkareaRect.Bottom;
    Result.Position := tbpBottom;
  end
end;
{$ENDIF}

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

{ TACLMonitor }

class operator TACLMonitor.Equal(const V1, V2: TACLMonitor): Boolean;
begin
  Result := (V1.BoundsRect = V2.BoundsRect);// and (V1.WorkareaRect = V2.WorkareaRect);
end;

class function TACLMonitor.Null: TACLMonitor;
begin
  FillChar(Result{%H-}, SizeOf(Result), 0);
end;

function TACLMonitor.PixelsPerInch: Integer;
begin
  Result := acGetTargetDPI(BoundsRect.CenterPoint);
end;

end.
