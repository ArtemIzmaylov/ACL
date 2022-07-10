{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*           Multi-Monitor Support           *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.Desktop;

{$I ACL.Config.inc}

interface

uses
  Windows, Types, Classes, Messages, MultiMon,
{$IFNDEF ACL_BASE_NOVCL}
  Forms,
{$ENDIF}
  // ACL
  ACL.Classes.Collections;

type
  TTaskBarPosition = (tbpLeft, tbpTop, tbpRight, tbpBottom);

  { TACLTaskbarInfo }

  TACLTaskbarInfo = record
    AutoHide: Boolean;
    Bounds: TRect;
    Position: TTaskBarPosition;
  end;

  { TACLMonitor }

  TACLMonitor = class
  strict private
    FHandle: HMONITOR;
    FIndex: Integer;

    function GetBoundsRect: TRect;
    function GetHandleIsValid: Boolean;
    function GetPixelsPerInch: Integer;
    function GetPrimary: Boolean;
    function GetWorkareaRect: TRect;
  protected
    function GetInfo(out AInfo: TMonitorInfo): Boolean;
  public
    constructor Create(AHandle: HMONITOR; AIndex: Integer); virtual;
    //
    property BoundsRect: TRect read GetBoundsRect;
    property Handle: HMONITOR read FHandle;
    property HandleIsValid: Boolean read GetHandleIsValid;
    property Index: Integer read FIndex;
    property PixelsPerInch: Integer read GetPixelsPerInch;
    property Primary: Boolean read GetPrimary;
    property WorkareaRect: TRect read GetWorkareaRect;
  end;

  { TACLScreenHelper }

  TACLScreenHelper = class
  strict private
    FMonitors: TACLObjectList;

    function GetMonitor(AIndex: Integer): TACLMonitor;
    function GetMonitorCount: Integer;
    function GetPrimaryMonitor: TACLMonitor;
    procedure MessageHandler(var AMessage: TMessage; var AHandled: Boolean);
  protected
    procedure AddMonitor(AHandle: HMONITOR);
    procedure EnumerateMonitors;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function FindByHandle(AHandle: HMONITOR): TACLMonitor;
    function FindByPoint(const P: TPoint): TACLMonitor;
    function FindByWnd(AWnd: HWND): TACLMonitor;
    //
    property Monitor[Index: Integer]: TACLMonitor read GetMonitor;
    property MonitorCount: Integer read GetMonitorCount;
    property PrimaryMonitor: TACLMonitor read GetPrimaryMonitor;
  end;

function ScreenHelper: TACLScreenHelper;
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
{$IFNDEF ACL_BASE_NOVCL}
function MonitorGetFocusedForm: TCustomForm;
{$ENDIF}
function MonitorGetTaskBarInfo: TACLTaskbarInfo;
function MonitorGetTaskBarRect: TRect;
function MonitorGetWorkArea(const P: TPoint): TRect;
function MonitorIsFullScreenApplicationRunning(AMonitor: TACLMonitor = nil): Boolean;
// Mouse
function MouseCurrentWindow: THandle;
function MouseCursorPos: TPoint;
function MouseCursorSize: TSize;
implementation

uses
{$IFNDEF ACL_BASE_NOVCL}
  Controls,
{$ENDIF}
  ShellAPI, SysUtils,
  // ACL
  ACL.Classes.MessageWindow,
  ACL.Utils.Common,
  ACL.Utils.Strings;

const
  Shcore = 'Shcore.dll';

{$WARNINGS OFF}
function GetDpiForMonitor(hmonitor: HMONITOR; dpiType: Cardinal; out dpiX, dpiY: UINT): HRESULT; stdcall; external Shcore delayed;
{$WARNINGS ON}

var
  FHelper: TACLScreenHelper;

function ScreenHelper: TACLScreenHelper;
begin
  if FHelper = nil then
    FHelper := TACLScreenHelper.Create;
  Result := FHelper;
end;

function EnumMonitorsProc(AHandle: HMONITOR; DC: HDC; R: PRect; Data: TACLScreenHelper): Boolean; stdcall;
begin
  Data.AddMonitor(AHandle);
  Result := True;
end;

function MonitorAlignPopupWindow(const R: TRect): TRect;
var
  AWorkArea: TRect;
begin
  Result := R;
  AWorkArea := MonitorGetBounds(Result.CenterPoint);
  if Result.Top < AWorkArea.Top then
    OffsetRect(Result, 0, AWorkArea.Top - Result.Top);
  if Result.Left < AWorkArea.Left then
    OffsetRect(Result, AWorkArea.Left - Result.Left, 0);
  if Result.Right > AWorkArea.Right then
    OffsetRect(Result, AWorkArea.Right - Result.Right, 0);
  if Result.Bottom > AWorkArea.Bottom then
    OffsetRect(Result, 0, AWorkArea.Bottom - Result.Bottom);
end;

function MonitorGetDefault: TACLMonitor;
begin
  Result := ScreenHelper.PrimaryMonitor;
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
  Result := ScreenHelper.FindByWnd(Wnd);
  if Result = nil then
    Result := MonitorGetDefault;
end;

function MonitorGet(const P: TPoint): TACLMonitor;
begin
  Result := ScreenHelper.FindByPoint(P);
  if Result = nil then
    Result := MonitorGetDefault;
end;

function MonitorGetByIndex(Index: Integer): TACLMonitor;
begin
  if (Index >= 0) and (Index < ScreenHelper.MonitorCount) then
    Result := ScreenHelper.Monitor[Index]
  else
    Result := MonitorGetDefault;
end;

function MonitorIsFullScreenApplicationRunning(AMonitor: TACLMonitor = nil): Boolean;

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
    AAppMonitor := ScreenHelper.FindByWnd(AAppHandle);
    if (AMonitor = nil) or (AMonitor = AAppMonitor) then
    begin
      if Assigned(AAppMonitor) and GetWindowRect(AAppHandle, R) then
      begin
        with AAppMonitor.BoundsRect do
          Result := (R.Right - R.Left >= Right - Left) and (R.Bottom - R.Top >= Bottom - Top);
      end;
    end;
  end;
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
  ATaskBar: TACLTaskbarInfo;
  R: TRect;
begin
  //Note: One of our Forms can be a Desktop toolbar, so, we need to calculate client area manually
  Result := MonitorGetBounds(P);
  ATaskBar := MonitorGetTaskBarInfo;
  if IntersectRect(R, Result, ATaskBar.Bounds) and not ATaskBar.AutoHide then
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

{$IFNDEF ACL_BASE_NOVCL}
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
{$ENDIF}

function MonitorGetTaskBarInfo: TACLTaskbarInfo;
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

function MouseCurrentWindow: THandle;
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
  if not GetCursorPos(Result) then
    Result := Point(-1, -1);
end;

{ TACLMonitor }

constructor TACLMonitor.Create(AHandle: HMONITOR; AIndex: Integer);
begin
  inherited Create;
  FHandle := AHandle;
  FIndex := AIndex;
end;

function TACLMonitor.GetBoundsRect: TRect;
var
  AInfo: TMonitorInfo;
begin
  if GetInfo(AInfo) then
    Result := AInfo.rcMonitor
  else
    Result := NullRect;
end;

function TACLMonitor.GetHandleIsValid: Boolean;
var
  AInfo: TMonitorInfo;
begin
  Result := GetInfo(AInfo);
end;

function TACLMonitor.GetInfo(out AInfo: TMonitorInfo): Boolean;
begin
  AInfo.cbSize := SizeOf(AInfo);
  try
    Result := GetMonitorInfo(Handle, @AInfo);
  except
    Result := False;
  end;
end;

function TACLMonitor.GetPixelsPerInch: Integer;
var
  Xdpi, Ydpi: Cardinal;
{$IFDEF ACL_BASE_NOVCL}
  DC: HDC;
{$ENDIF}
begin
  if CheckWin32Version(6, 3) and (GetDpiForMonitor(Handle, 0, Xdpi, Ydpi) = S_OK) then
    Exit(Xdpi);

{$IFDEF ACL_BASE_NOVCL}
  DC := GetDC(0);
  try
    Result := GetDeviceCaps(DC, LOGPIXELSX);
  finally
    ReleaseDC(0, DC);
  end;
{$ELSE}
  Result := Screen.PixelsPerInch;
{$ENDIF}
end;

function TACLMonitor.GetPrimary: Boolean;
var
  AInfo: TMonitorInfo;
begin
  Result := GetInfo(AInfo) and (AInfo.dwFlags and MONITORINFOF_PRIMARY <> 0);
end;

function TACLMonitor.GetWorkareaRect: TRect;
var
  AInfo: TMonitorInfo;
begin
  if GetInfo(AInfo) then
    Result := AInfo.rcWork
  else
    Result := NullRect;
end;

{ TACLScreenHelper }

constructor TACLScreenHelper.Create;
begin
  inherited Create;
  FMonitors := TACLObjectList.Create;
  MessageWindow.HandlerAdd(MessageHandler);
end;

destructor TACLScreenHelper.Destroy;
begin
  MessageWindow.HandlerRemove(MessageHandler);
  FreeAndNil(FMonitors);
  inherited Destroy;
end;

procedure TACLScreenHelper.AddMonitor(AHandle: HMONITOR);
begin
  FMonitors.Add(TACLMonitor.Create(AHandle, FMonitors.Count));
end;

procedure TACLScreenHelper.EnumerateMonitors;
begin
  FMonitors.Clear;
  EnumDisplayMonitors(0, nil, @EnumMonitorsProc, NativeUInt(Self));
end;

function TACLScreenHelper.FindByHandle(AHandle: HMONITOR): TACLMonitor;

  function DoFind(AHandle: HMONITOR): TACLMonitor;
  var
    I: Integer;
  begin
    Result := nil;
    for I := 0 to MonitorCount - 1 do
      if Monitor[I].Handle = AHandle then
      begin
        Result := Monitor[I];
        Break;
      end;
  end;

begin
  Result := DoFind(AHandle);
  if (Result = nil) and (AHandle <> 0) then
  begin
    EnumerateMonitors;
    Result := DoFind(AHandle);
  end;
end;

function TACLScreenHelper.FindByPoint(const P: TPoint): TACLMonitor;
begin
  Result := FindByHandle(MonitorFromPoint(P, MONITOR_DEFAULTTONEAREST));
end;

function TACLScreenHelper.FindByWnd(AWnd: HWND): TACLMonitor;
begin
  Result := FindByHandle(MonitorFromWindow(AWnd, MONITOR_DEFAULTTONEAREST));
end;

procedure TACLScreenHelper.MessageHandler(var AMessage: TMessage; var AHandled: Boolean);
begin
  case AMessage.Msg of
    WM_SETTINGCHANGE, WM_DISPLAYCHANGE:
      EnumerateMonitors;
  end;
end;

function TACLScreenHelper.GetMonitor(AIndex: Integer): TACLMonitor;
begin
  Result := TACLMonitor(FMonitors[AIndex]);
end;

function TACLScreenHelper.GetMonitorCount: Integer;
begin
  Result := FMonitors.Count;
end;

function TACLScreenHelper.GetPrimaryMonitor: TACLMonitor;

  function FindCore: TACLMonitor;
  var
    I: Integer;
  begin
    for I := 0 to MonitorCount - 1 do
    begin
      if Monitor[I].Primary then
        Exit(Monitor[I]);
    end;
    Result := nil;
  end;

begin
  Result := FindCore;
  if Result = nil then
  begin
    EnumerateMonitors;
    Result := FindCore;
  end;
end;

initialization

finalization
  FreeAndNil(FHelper);
end.
