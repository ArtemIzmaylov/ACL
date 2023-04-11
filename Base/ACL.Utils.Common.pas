{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*             System Utilities              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.Common;

{$I ACL.Config.inc}
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
  Winapi.Messages,
  Winapi.PsAPI,
{$ENDIF}
  // System
  System.UITypes,
  System.Types,
  System.SysUtils,
  System.Classes,
  System.Math;

const
  SIZE_ONE_KILOBYTE = 1024;
  SIZE_ONE_MEGABYTE = SIZE_ONE_KILOBYTE * SIZE_ONE_KILOBYTE;
  SIZE_ONE_GIGABYTE = SIZE_ONE_KILOBYTE * SIZE_ONE_MEGABYTE;

  InvalidPoint: TPoint = (X: -1; Y: -1);
  InvalidSize: TSize = (cx: -1; cy: -1);
  NullPoint: TPoint = (X: 0; Y: 0);
  NullRect: TRect = (Left: 0; Top: 0; Right: 0; Bottom: 0);
  NullSize: TSize = (cx: 0; cy: 0);
  Signs: array[Boolean] of Integer = (-1, 1);

  MaxWord = Word.MaxValue;

{$IFDEF MSWINDOWS}
  E_HANDLE = Winapi.Windows.E_HANDLE;
{$ELSE}
  E_HANDLE = HRESULT($80070006);
{$ENDIF}


type
{$SCOPEDENUMS ON}
  TACLBoolean = (Default, False, True);
{$SCOPEDENUMS OFF}

const
  acDefault = TACLBoolean.Default;
  acFalse = TACLBoolean.False;
  acTrue = TACLBoolean.True;

type
  TProcedureRef = reference to procedure;

  { IObject }

  IObject = interface
  ['{4944656C-7068-6954-6167-4F626A656374}']
    function GetObject: TObject;
  end;

  { IStringReceiver }

  IStringReceiver = interface
  ['{F07E42B3-2680-425D-9119-253D300AE4CF}']
    procedure Add(const S: UnicodeString);
  end;

  TACLStringEnumProc = reference to procedure (const S: UnicodeString);

  TACLBooleanHelper = record helper for TACLBoolean
  public
    function ActualValue(ADefault: Boolean): Boolean;
    class function From(AValue: Boolean): TACLBoolean; static;
  end;

{$IFDEF MSWINDOWS}

  { TProcessHelper }

  TExecuteOption = (eoWaitForTerminate, eoShowGUI);
  TExecuteOptions = set of TExecuteOption;

  TProcessHelper = class
  public
    class function Execute(const ACmdLine: UnicodeString; AOptions: TExecuteOptions = [eoShowGUI];
      AOutputData: TStream = nil; AErrorData: TStream = nil; AProcessInfo: PProcessInformation = nil;
      AExitCode: PCardinal = nil): LongBool; overload;
    class function Execute(const ACmdLine: UnicodeString; ALog: IStringReceiver;
      AOptions: TExecuteOptions = [eoShowGUI]): LongBool; overload;
    // Wow64
    class function IsWow64: LongBool; overload;
    class function IsWow64(AProcess: THandle): LongBool; overload;
    class function IsWow64Window(AWindow: HWND): LongBool;
    class function Wow64SetFileSystemRedirection(AValue: Boolean): LongBool;
  end;

{$ENDIF}

  { TACLInterfaceHelper }

  TACLInterfaceHelper<T: IUnknown> = class
  public
    class function GetGuid: TGUID; static;
  end;

  { TACLEnumHelper }

  TACLEnumHelper = class
  public
    class function GetValue<T>(const Value: T): Integer; static;
    class function SetValue<T>(const Value: Integer): T; static;
  end;

  { Safe }

  Safe = class
  public
    class function Cast(const AObject: TObject; const AClass: TClass; out AValue): Boolean; inline;
  end;

var
  IsWin8OrLater: Boolean;
  IsWin10OrLater: Boolean;
  IsWin11OrLater: Boolean;
  IsWinSeven: Boolean;
  IsWinSevenOrLater: Boolean;
  IsWinVistaOrLater: Boolean;
  IsWinXP: Boolean;
  IsWine: Boolean;

  InvariantFormatSettings: TFormatSettings;

// HMODULE
function acGetProcessFileName(const AWindowHandle: THandle; out AFileName: UnicodeString): Boolean;
function acGetProcAddress(ALibHandle: HMODULE; AProcName: PWideChar; var AResult: Boolean): Pointer;
function acLoadLibrary(const AFileName: UnicodeString; AFlags: Cardinal = 0): HMODULE;
function acModuleFileName(AModule: HMODULE): UnicodeString; inline;
function acModuleHandle(const AFileName: UnicodeString): HMODULE;

// Window Handles
{$IFDEF MSWINDOWS}
function acGetWindowRect(AHandle: HWND): TRect;
function acFindWindow(const AClassName: UnicodeString): HWND;
function acGetClassName(Handle: HWND): UnicodeString;
function acGetWindowText(AHandle: HWND): UnicodeString;
procedure acSwitchToWindow(AHandle: HWND);
procedure acSetWindowText(AHandle: HWND; const AText: UnicodeString);
{$ENDIF}

// System
procedure MinimizeMemoryUsage;

{$IFDEF MSWINDOWS}
function GetExactTickCount: Int64;
function TickCountToTime(const ATicks: Int64): Cardinal;
function TimeToTickCount(const ATime: Cardinal): Int64;
{$ENDIF}

// Interfaces
procedure acGetInterface(const Instance: IInterface; const IID: TGUID; out Intf); overload;
procedure acGetInterface(const Instance: TObject; const IID: TGUID; out Intf); overload;
function acGetInterfaceEx(const Instance: IInterface; const IID: TGUID; out Intf): HRESULT; overload;
function acGetInterfaceEx(const Instance: TObject; const IID: TGUID; out Intf): HRESULT; overload;

procedure acExchangeInt64(var AValue1, AValue2: Int64); inline;
procedure acExchangeIntegers(var AValue1, AValue2); inline;
procedure acExchangePointers(var AValue1, AValue2); inline;
procedure acExchangeStrings(var AValue1, AValue2: UnicodeString); inline;
function acBoolToHRESULT(AValue: Boolean): HRESULT; inline;
function acGenerateGUID: UnicodeString;
function acObjectUID(AObject: TObject): string;
{$IFDEF MSWINDOWS}
function acSetThreadErrorMode(Mode: DWORD): DWORD;
{$ENDIF}
procedure FreeMemAndNil(var P: Pointer);
function IfThen(AValue: Boolean; ATrue: TACLBoolean; AFalse: TACLBoolean): TACLBoolean; overload;

{$IFDEF MSWINDOWS}
// Wine
function WineGetVersion(out AVersion: string): Boolean;
{$ENDIF}
implementation

uses
{$IFNDEF ACL_BASE_NOVCL}
  Vcl.Forms,
{$ENDIF}
  // System
  System.AnsiStrings,
  System.TypInfo,
  // ACL
  ACL.Math,
  ACL.Utils.Strings,
  ACL.Utils.Stream,
  ACL.Utils.FileSystem,
  ACL.Threading;

{$IFDEF MSWINDOWS}
type
  TGetThreadErrorMode = function: DWORD; stdcall;
  TSetThreadErrorMode = function (NewMode: DWORD; out OldMode: DWORD): LongBool; stdcall;
  TWineGetVersion = function: PAnsiChar; stdcall;

var
  FPerformanceCounterFrequency: Int64 = 0;
  FGetThreadErrorMode: TGetThreadErrorMode = nil;
  FSetThreadErrorMode: TSetThreadErrorMode = nil;
  FWineGetBuildId: TWineGetVersion = nil;
  FWineGetVersion: TWineGetVersion = nil;

function WineGetVersion(out AVersion: string): Boolean;
begin
  Result := Assigned(FWineGetVersion) and Assigned(FWineGetBuildId);
  if Result then
    AVersion := Format('%s (%s)', [FWineGetVersion, FWineGetBuildId])
end;
{$ENDIF}

procedure CheckOSVersion;
begin
{$IFDEF MSWINDOWS}
  IsWine := Assigned(FWineGetVersion);
  IsWinXP := (TOSVersion.Major = 5) and (TOSVersion.Minor = 1);
  IsWinVistaOrLater := TOSVersion.Check(6, 0);
  IsWinSeven := (TOSVersion.Major = 6) and (TOSVersion.Minor = 1);
  IsWinSevenOrLater := TOSVersion.Check(6, 1);
  IsWin8OrLater := TOSVersion.Check(6, 2);
  IsWin10OrLater := TOSVersion.Check(10, 0);
  IsWin11OrLater := TOSVersion.Check(10, 0) and (TOSVersion.Build >= 22000);
{$ENDIF}
end;

{$IFDEF MSWINDOWS}
function acSetThreadErrorMode(Mode: DWORD): DWORD;
begin
  if Assigned(FSetThreadErrorMode) then
  begin
    if not FSetThreadErrorMode(Mode, Result) then
      Result := FGetThreadErrorMode;
  end
  else
    Result := SetErrorMode(Mode);
end;
{$ENDIF}

//==============================================================================
// HMODULE
//==============================================================================

function acGetProcessFileName(const AWindowHandle: THandle; out AFileName: UnicodeString): Boolean;
{$IFDEF MSWINDOWS}
var
  AProcess: THandle;
  AProcessID: Cardinal;
begin
  Result := False;
  if (AWindowHandle <> 0) and (GetWindowThreadProcessId(AWindowHandle, AProcessID) > 0) then
  begin
    AProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, True, AProcessID);
    if AProcess <> 0 then
    try
      SetLength(AFileName, MAX_PATH);
      SetLength(AFileName, GetModuleFileNameEx(AProcess, 0, PWideChar(AFileName), Length(AFileName)));
      Result := True;
    finally
      CloseHandle(AProcess);
    end;
  end;
end;
{$ELSE}
begin
  Result := False;
end;
{$ENDIF}

function acGetProcAddress(ALibHandle: HMODULE; AProcName: PWideChar; var AResult: Boolean): Pointer;
begin
  Result := GetProcAddress(ALibHandle, AProcName);
  AResult := AResult and (Result <> nil);
end;

function acLoadLibrary(const AFileName: UnicodeString; AFlags: Cardinal = 0): HMODULE;
var
  APrevCurPath: UnicodeString;
begin
{$IFDEF MSWINDOWS}
  var AErrorMode := acSetThreadErrorMode(SEM_FailCriticalErrors);
  try
{$ENDIF}
    APrevCurPath := acGetCurrentDir;
    try
      acSetCurrentDir(acExtractFilePath(AFileName));
    {$IFDEF MSWINDOWS}
      if AFlags <> 0 then
        Result := LoadLibraryEx(PWideChar(AFileName), 0, AFlags)
      else
    {$ENDIF}
        Result := LoadLibrary(PWideChar(AFileName));
    finally
      acSetCurrentDir(APrevCurPath);
    end;
{$IFDEF MSWINDOWS}
  finally
    acSetThreadErrorMode(AErrorMode);
  end;
{$ENDIF}
end;

function acModuleHandle(const AFileName: UnicodeString): HMODULE;
begin
  Result := GetModuleHandle(PWideChar(AFileName));
end;

function acModuleFileName(AModule: HMODULE): UnicodeString;
begin
  Result := GetModuleName(AModule);
end;

// ---------------------------------------------------------------------------------------------------------------------
// Internal Tools
// ---------------------------------------------------------------------------------------------------------------------

{$IFDEF MSWINDOWS}
function GetExactTickCount: Int64;
begin
  //# https://docs.microsoft.com/ru-ru/windows/win32/api/profileapi/nf-profileapi-queryperformancecounter?redirectedfrom=MSDN
  //# On systems that run Windows XP or later, the function will always succeed and will thus never return zero.
  if not QueryPerformanceCounter(Result) then
    Result := GetTickCount;
end;

function TickCountToTime(const ATicks: Int64): Cardinal;
begin
  if FPerformanceCounterFrequency = 0 then
    QueryPerformanceFrequency(FPerformanceCounterFrequency);
  Result := (ATicks * 1000) div FPerformanceCounterFrequency;
end;

function TimeToTickCount(const ATime: Cardinal): Int64;
begin
  if FPerformanceCounterFrequency = 0 then
    QueryPerformanceFrequency(FPerformanceCounterFrequency);
  Result := (Int64(ATime) * FPerformanceCounterFrequency) div 1000;
end;
{$ENDIF}

procedure FreeMemAndNil(var P: Pointer);
begin
  if P <> nil then
  begin
    FreeMem(P);
    P := nil;
  end;
end;

function IfThen(AValue: Boolean; ATrue: TACLBoolean; AFalse: TACLBoolean): TACLBoolean;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

procedure acGetInterface(const Instance: IInterface; const IID: TGUID; out Intf);
begin
  if not Supports(Instance, IID, Intf) then
    Pointer(Intf) := nil;
end;

procedure acGetInterface(const Instance: TObject; const IID: TGUID; out Intf);
begin
  if not Supports(Instance, IID, Intf) then
    Pointer(Intf) := nil;
end;

function acGetInterfaceEx(const Instance: IInterface; const IID: TGUID; out Intf): HRESULT;
begin
  if Instance <> nil then
    Result := Instance.QueryInterface(IID, Intf)
  else
    Result := E_NOINTERFACE;
end;

function acGetInterfaceEx(const Instance: TObject; const IID: TGUID; out Intf): HRESULT;
begin
  if Instance = nil then
    Result := E_HANDLE
  else
    if Supports(Instance, IID, Intf) then
      Result := S_OK
    else
      Result := E_NOINTERFACE;
end;

procedure acExchangeInt64(var AValue1, AValue2: Int64);
var
  ATempValue: Int64;
begin
  ATempValue := AValue1;
  AValue1 := AValue2;
  AValue2 := ATempValue;
end;

procedure acExchangeIntegers(var AValue1, AValue2);
var
  ATempValue: Integer;
begin
  ATempValue := Integer(AValue1);
  Integer(AValue1) := Integer(AValue2);
  Integer(AValue2) := ATempValue;
end;

procedure acExchangePointers(var AValue1, AValue2);
var
  ATempValue: Pointer;
begin
  ATempValue := Pointer(AValue1);
  Pointer(AValue1) := Pointer(AValue2);
  Pointer(AValue2) := ATempValue;
end;

procedure acExchangeStrings(var AValue1, AValue2: UnicodeString);
var
  ATempValue: UnicodeString;
begin
  ATempValue := AValue1;
  AValue1 := AValue2;
  AValue2 := ATempValue;
end;

function acBoolToHRESULT(AValue: Boolean): HRESULT;
begin
  if AValue then
    Result := S_OK
  else
    Result := E_FAIL;
end;

function acGenerateGUID: UnicodeString;
var
  G: TGUID;
begin
  CreateGUID(G);
  Result := GUIDToString(G);
end;

function acObjectUID(AObject: TObject): string;
begin
  Result := IntToHex(NativeUInt(AObject), SizeOf(Pointer) * 2);
end;

procedure MinimizeMemoryUsage;
begin
{$IFDEF MSWINDOWS}
  SetProcessWorkingSetSize(GetCurrentProcess, NativeUInt(-1), NativeUInt(-1));
{$ENDIF}
end;

//==============================================================================
// Window Handle
//==============================================================================
{$IFDEF MSWINDOWS}
function acGetClassName(Handle: HWND): UnicodeString;
var
  ABuf: array[0..64] of WideChar;
begin
  ZeroMemory(@ABuf[0], SizeOf(ABuf));
  GetClassNameW(Handle, @ABuf[0], Length(ABuf));
  Result := ABuf;
end;

function acGetWindowRect(AHandle: HWND): TRect;
begin
  if not GetWindowRect(AHandle, Result) then
    Result := NullRect;
end;

function acFindWindow(const AClassName: UnicodeString): HWND;
begin
  Result := FindWindowW(PWideChar(AClassName), nil);
end;

function acGetWindowText(AHandle: HWND): UnicodeString;
var
  B: array[BYTE] of WideChar;
begin
  GetWindowTextW(AHandle, @B[0], Length(B));
  Result := B;
end;

procedure acSetWindowText(AHandle: HWND; const AText: UnicodeString);
begin
  if AHandle <> 0 then
  begin
    if IsWindowUnicode(AHandle) then
      SetWindowTextW(AHandle, PWideChar(AText))
    else
      DefWindowProcW(AHandle, WM_SETTEXT, 0, LPARAM(PWideChar(AText))); // fix for app handle
  end;
end;

procedure acSwitchToWindow(AHandle: HWND);
var
  AInput: TInput;
begin
  ZeroMemory(@AInput, SizeOf(AInput));
  SendInput(INPUT_KEYBOARD, AInput, SizeOf(AInput));
  SetForegroundWindow(AHandle);
  SetFocus(AHandle);
end;
{$ENDIF}

{ TACLBooleanHelper }

function TACLBooleanHelper.ActualValue(ADefault: Boolean): Boolean;
begin
  if Self = TACLBoolean.Default then
    Result := ADefault
  else
    Result := Self = TACLBoolean.True;
end;

class function TACLBooleanHelper.From(AValue: Boolean): TACLBoolean;
begin
  if AValue then
    Result := TACLBoolean.True
  else
    Result := TACLBoolean.False;
end;

{ TProcessHelper }

{$IFDEF MSWINDOWS}
class function TProcessHelper.Execute(const ACmdLine: UnicodeString;
  AOptions: TExecuteOptions = [eoShowGUI]; AOutputData: TStream = nil; AErrorData: TStream = nil;
  AProcessInfo: PProcessInformation = nil; AExitCode: PCardinal = nil): LongBool;

  function CreateProcess(var PI: TProcessInformation; var SI: TStartupInfo): LongBool;
  var
    ATempCmdLine: WideString; // must be WideString!
  begin
    ATempCmdLine := ACmdLine;
    Result := CreateProcessW(nil, PWideChar(ATempCmdLine), nil, nil, True, 0, nil, nil, SI, PI);
    Result := Result and (WaitForInputIdle(PI.hProcess, 5000) <> WAIT_TIMEOUT); // Function returns WAIT_FAILED for console app
  end;

  procedure ReadData(AInputStream: THandleStream; AOutputStream: TStream);
  var
    AAvailable: Cardinal;
    ATempData: array of Byte;
  begin
    if (AInputStream <> nil) and (AOutputStream <> nil) then
    repeat
      AAvailable := 0;
      if PeekNamedPipe(AInputStream.Handle, nil, 0, nil, @AAvailable, nil) and (AAvailable > 0) then
      begin
	      if AAvailable > Cardinal(Length(ATempData)) then
          SetLength(ATempData, AAvailable);
        AInputStream.ReadBuffer(ATempData[0], AAvailable);
        AOutputStream.WriteBuffer(ATempData[0], AAvailable);
      end;
    until AAvailable = 0;
  end;

var
  AProcessInformation: TProcessInformation;
  ASecurityAttrs: TSecurityAttributes;
  AStartupInfo: TStartupInfo;
  AStdErrorRead, AStdErrorWrite: THandle;
  AStdErrorStream: THandleStream;
  AStdOutputRead, AStdOutputWrite: THandle;
  AStdOutputStream: THandleStream;
begin
  AStdErrorRead := 0;
  AStdErrorWrite := 0;
  AStdOutputRead := 0;
  AStdOutputWrite := 0;
  Result := False;

  ZeroMemory(@AStartupInfo, SizeOf(AStartupInfo));
  ZeroMemory(@AProcessInformation, SizeOf(AProcessInformation));
  AStartupInfo.cb := SizeOf(TStartupInfo);
  AStartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  AStartupInfo.wShowWindow := IfThen(eoShowGUI in AOptions, SW_SHOW, SW_HIDE);

  if (eoWaitForTerminate in AOptions) and ((AOutputData <> nil) or (AErrorData <> nil)) then
  begin
    ZeroMemory(@ASecurityAttrs, SizeOf(ASecurityAttrs));
    ASecurityAttrs.nLength := SizeOf(SECURITY_ATTRIBUTES);
    ASecurityAttrs.bInheritHandle := True;
    if not CreatePipe(AStdOutputRead, AStdOutputWrite, @ASecurityAttrs, 0) then Exit;
    if not CreatePipe(AStdErrorRead, AStdErrorWrite, @ASecurityAttrs, 0) then Exit;

    AStartupInfo.dwFlags := AStartupInfo.dwFlags or STARTF_USESTDHANDLES;
    AStartupInfo.hStdOutput := AStdOutputWrite;
    AStartupInfo.hStdError := AStdErrorWrite;
  end;

  // Warning! The Unicode version of this function, CreateProcessW, can modify the
  // contents of this string. Therefore, this parameter cannot be a pointer to
  // read-only memory (such as a const variable or a literal string). If this
  // parameter is a constant string, the function may cause an access violation.
  Result := CreateProcess(AProcessInformation, AStartupInfo);
  if Result then
  begin
    if Assigned(AProcessInfo) then
      AProcessInfo^ := AProcessInformation;
    if eoWaitForTerminate in AOptions then
    try
      if (AOutputData <> nil) or (AErrorData <> nil) then
      begin
        AStdErrorStream := THandleStream.Create(AStdErrorRead);
        AStdOutputStream := THandleStream.Create(AStdOutputRead);
        try
          repeat
            ReadData(AStdErrorStream, AErrorData);
            ReadData(AStdOutputStream, AOutputData);
          until WaitForSingleObject(AProcessInformation.hProcess, 10) = WAIT_OBJECT_0;
          ReadData(AStdErrorStream, AErrorData);
          ReadData(AStdOutputStream, AOutputData);
        finally
          AStdOutputStream.Free;
          AStdErrorStream.Free;
        end;
      end
      else
        WaitForSingleObject(AProcessInformation.hProcess, INFINITE);

      if AExitCode <> nil then
        GetExitCodeProcess(AProcessInformation.hProcess, AExitCode^);
    finally
      CloseHandle(AProcessInformation.hThread);
      CloseHandle(AProcessInformation.hProcess);
    end;
  end;

  CloseHandle(AStdOutputRead);
  CloseHandle(AStdOutputWrite);
  CloseHandle(AStdErrorRead);
  CloseHandle(AStdErrorWrite);
end;

class function TProcessHelper.Execute(const ACmdLine: UnicodeString;
  ALog: IStringReceiver; AOptions: TExecuteOptions = [eoShowGUI]): LongBool;

  procedure Log(const S: UnicodeString);
  begin
    if ALog <> nil then
      ALog.Add(S);
  end;

var
  AErrorData: TStringStream;
  AOutputData: TStringStream;
begin
  AErrorData := TStringStream.Create;
  AOutputData := TStringStream.Create;
  try
    Log('Executing: ' + ACmdLine);
    Result := Execute(ACmdLine, AOptions, AOutputData, AErrorData);
    if Result then
    begin
      Log(AOutputData.DataString);
      Log(AErrorData.DataString);
    end
    else
      Log(SysErrorMessage(GetLastError));
  finally
    AOutputData.Free;
    AErrorData.Free;
  end;
end;

class function TProcessHelper.IsWow64(AProcess: THandle): LongBool;
type
  TIsWow64ProcessProc = function (hProcess: THandle; out AValue: LongBool): LongBool; stdcall;
var
  ALibHandle: THandle;
  AWow64Proc: TIsWow64ProcessProc;
begin
  ALibHandle := GetModuleHandle(kernel32);
  AWow64Proc := TIsWow64ProcessProc(GetProcAddress(ALibHandle, 'IsWow64Process'));
  if not (Assigned(AWow64Proc) and AWow64Proc(AProcess, Result)) then
    Result := False;
end;

class function TProcessHelper.IsWow64: LongBool;
begin
{$IFDEF CPUX64}
  Result := False;
{$ELSE}
  Result := IsWow64(GetCurrentProcess);
{$ENDIF}
end;

class function TProcessHelper.IsWow64Window(AWindow: HWND): LongBool;
var
  AProcessID: Cardinal;
  AProcessHandle: THandle;
begin
  Result := False;
  if GetWindowThreadProcessId(AWindow, AProcessID) <> 0 then
  begin
    AProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION, True, AProcessID);
    if AProcessHandle <> 0 then
    try
      Result := IsWow64(AProcessHandle);
    finally
      CloseHandle(AProcessHandle);
    end;
  end;
end;

class function TProcessHelper.Wow64SetFileSystemRedirection(AValue: Boolean): LongBool;
type
  TWow64SetProc = function (AValue: LongBool): LongBool; stdcall;
var
  ALibHandle: THandle;
  AWow64SetProc: TWow64SetProc;
begin
  ALibHandle := GetModuleHandle(kernel32);
  AWow64SetProc := TWow64SetProc(GetProcAddress(ALibHandle, 'Wow64EnableWow64FsRedirection'));
  Result := Assigned(AWow64SetProc) and AWow64SetProc(AValue);
end;
{$ENDIF}

{ TACLInterfaceHelper }

class function TACLInterfaceHelper<T>.GetGuid: TGUID;
begin
  Result := GetTypeData(TypeInfo(T))^.GUID;
end;

{ TACLEnumHelper }

class function TACLEnumHelper.GetValue<T>(const Value: T): Integer;
var
  ATypeInfo: PTypeInfo;
begin
  ATypeInfo := TypeInfo(T);
  if ATypeInfo^.Kind = tkEnumeration then
    case GetTypeData(ATypeInfo).OrdType of
      otUByte, otSByte:
        Exit(PByte(@Value)^);
      otUWord, otSWord:
        Exit(PWord(@Value)^);
      otULong, otSLong:
        Exit(PInteger(@Value)^);
    end;
  raise EInvalidArgument.Create('Unexpected ordinal type');
end;

class function TACLEnumHelper.SetValue<T>(const Value: Integer): T;
var
  ATypeData: PTypeData;
  ATypeInfo: PTypeInfo;
  AValue: Integer;
begin
  ATypeInfo := TypeInfo(T);
  if ATypeInfo^.Kind <> tkEnumeration then
    raise EInvalidArgument.Create('Unexpected type');

  ATypeData := GetTypeData(ATypeInfo);
  AValue := EnsureRange(Value, ATypeData.MinValue, ATypeData.MaxValue);
  case ATypeData.OrdType of
    otUByte, otSByte:
      PByte(@Result)^ := AValue;
    otUWord, otSWord:
      PWord(@Result)^ := AValue;
    otULong, otSLong:
      PInteger(@Result)^ := AValue;
  else
    raise EInvalidArgument.Create('Unexpected ordinal type');
  end;
end;

{ Safe }

class function Safe.Cast(const AObject: TObject; const AClass: TClass; out AValue): Boolean;
begin
  Result := (AObject <> nil) and AObject.InheritsFrom(AClass);
  if Result then
    TObject(AValue) := AObject
  else
    TObject(AValue) := nil;
end;

initialization
{$IFDEF MSWINDOWS}
  var ALibHandle := GetModuleHandle('ntdll.dll');
  FWineGetBuildId := GetProcAddress(ALibHandle, 'wine_get_build_id');
  FWineGetVersion := GetProcAddress(ALibHandle, 'wine_get_version');

  ALibHandle := GetModuleHandle(kernel32);
  FGetThreadErrorMode := GetProcAddress(ALibHandle, 'GetThreadErrorMode');
  FSetThreadErrorMode := GetProcAddress(ALibHandle, 'SetThreadErrorMode');

  CheckOSVersion;
{$ENDIF}
  InvariantFormatSettings := TFormatSettings.Invariant;
end.
