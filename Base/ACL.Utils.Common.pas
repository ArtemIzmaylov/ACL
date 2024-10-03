﻿////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   General Utilities and Types
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Utils.Common;

{$I ACL.Config.inc}
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
{$IFDEF FPC}
  InterfaceBase,
  LCLIntf,
  LCLType,
  Process,
{$ELSE}
  Winapi.PsAPI,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}SysUtils,
  {System.}Types,
  {System.}TypInfo,
  {System.}Math,
  System.AnsiStrings,
  System.UITypes;

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

  MaxWord = High(Word);

{$IFDEF MSWINDOWS}
  E_ABORT = Winapi.Windows.E_ABORT;
  E_ACCESSDENIED = Winapi.Windows.E_ACCESSDENIED;
  E_FAIL = Winapi.Windows.E_FAIL;
  E_HANDLE = Winapi.Windows.E_HANDLE;
  E_NOTIMPL = Winapi.Windows.E_NOTIMPL;
  E_OUTOFMEMORY = Winapi.Windows.E_OUTOFMEMORY;
  E_INVALIDARG = Winapi.Windows.E_INVALIDARG;
  E_PENDING = Winapi.Windows.E_PENDING;
  E_POINTER = Winapi.Windows.E_POINTER;

  SEM_FAILCRITICALERRORS = Winapi.Windows.SEM_FAILCRITICALERRORS;
{$ELSE}
  E_ABORT = HRESULT($80004004);
  E_ACCESSDENIED = HRESULT($80070005);
  E_FAIL = HRESULT($80004005);
  E_OUTOFMEMORY = HRESULT($8007000E);
  E_HANDLE = HRESULT($80070006);
  E_NOTIMPL = HRESULT($80004001);
  E_INVALIDARG = HRESULT($80070057);
  E_PENDING = HRESULT($8000000A);
  E_POINTER = HRESULT($80004003);

  SEM_FAILCRITICALERRORS = 0; // just a stub
{$ENDIF}

{$IFDEF FPC}
type
  TProc = reference to procedure;
  TProc<T> = reference to procedure (Arg1: T);
  TProc<T1,T2> = reference to procedure (Arg1: T1; Arg2: T2);
  TProc<T1,T2,T3> = reference to procedure (Arg1: T1; Arg2: T2; Arg3: T3);
  TProc<T1,T2,T3,T4> = reference to procedure (Arg1: T1; Arg2: T2; Arg3: T3; Arg4: T4);

  TFunc<TResult> = reference to function: TResult;
  TFunc<T,TResult> = reference to function (Arg1: T): TResult;
  TFunc<T1,T2,TResult> = reference to function (Arg1: T1; Arg2: T2): TResult;
  TFunc<T1,T2,T3,TResult> = reference to function (Arg1: T1; Arg2: T2; Arg3: T3): TResult;
  TFunc<T1,T2,T3,T4,TResult> = reference to function (Arg1: T1; Arg2: T2; Arg3: T3; Arg4: T4): TResult;

  TPredicate<T> = reference to function (Arg1: T): Boolean;
{$ENDIF}

type
  TConsumerC<T> = reference to procedure (const Arg: T);
  TPredicateC<T> = reference to function (const Arg: T): Boolean;
  TObjHashCode = {$IFDEF FPC}PtrInt{$ELSE}Integer{$ENDIF};

{$SCOPEDENUMS ON}
  TACLBoolean = (Default, False, True);
{$SCOPEDENUMS OFF}

  TObjHandle = type NativeUInt;
  PObjHandle = ^TObjHandle;
  TWndHandle = HWND; // to avoid direct references to Winapi

const
  acDefault = TACLBoolean.Default;
  acFalse = TACLBoolean.False;
  acTrue = TACLBoolean.True;

type

  { IObject }

  IObject = interface
  ['{4944656C-7068-6954-6167-4F626A656374}']
    function GetObject: TObject;
  end;

  { IStringReceiver }

  IStringReceiver = interface
  ['{F07E42B3-2680-425D-9119-253D300AE4CF}']
    procedure Add(const S: string);
  end;

  TACLStringEnumProc = reference to procedure (const S: string);

  TACLBooleanHelper = record helper for TACLBoolean
  public
    function ActualValue(ADefault: Boolean): Boolean;
    class function From(AValue: Boolean): TACLBoolean; static;
  end;

  { TACLProcess }

  TExecuteOption = (eoWaitForTerminate, eoShowGUI);
  TExecuteOptions = set of TExecuteOption;

  TACLProcess = class
  public
    class function Execute(const ACmdLine: string; ALog: IStringReceiver;
      AOptions: TExecuteOptions = [eoShowGUI]): LongBool; overload;
    class function Execute(const ACmdLine: string;
      AOptions: TExecuteOptions = [eoShowGUI]; AOutputData: TStream = nil;
      AErrorData: TStream = nil; AExitCode: PCardinal = nil): LongBool; overload;
    class function ExecuteToString(const ACmdLine: string): string;
  {$IFDEF MSWINDOWS}
    class function IsWow64: LongBool; overload;
    class function IsWow64(AProcess: THandle): LongBool; overload;
    class function IsWow64Window(AWindow: HWND): LongBool;
    class function Wow64SetFileSystemRedirection(AValue: Boolean): LongBool;
  {$ENDIF}
  end;

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
    class function Cast(AObject: TObject; AClass: TClass; out AValue): Boolean; inline;
    class function CastOrNil<T: class>(AObject: TObject): T; inline;
  end;

const
{$IF DEFINED(MSWINDOWS)}
  LibExt = '.dll';
{$ELSEIF DEFINED(LINUX)}
  LibExt = '.so';
{$ENDIF}

var
  InvariantFormatSettings: TFormatSettings;

// HMODULE
procedure acFreeLibrary(var ALibHandle: HMODULE);
function acGetProcAddress(ALibHandle: HMODULE; AProcName: PChar): Pointer; overload;
function acGetProcAddress(ALibHandle: HMODULE; AProcName: PChar; var AResult: Boolean): Pointer; overload;
function acLoadLibrary(const AFileName: string; AFlags: Cardinal = 0): HMODULE;
{$IFDEF MSWINDOWS}
function acModuleFileName(AModule: HMODULE): string; inline;
function acModuleHandle(const AFileName: string): HMODULE;
{$ENDIF}

// Window Handles
function acFindWindow(const AClassName: string): TWndHandle;
function acGetClassName(AWnd: TWndHandle): string;
function acGetProcessFileName(AWnd: TWndHandle; out AFileName: string): Boolean;
function acGetWindowRect(AWnd: TWndHandle): TRect;

// System
procedure MinimizeMemoryUsage;
procedure ZeroMemory(Data: Pointer; Size: Integer);

// Interfaces
procedure acGetInterface(const Instance: IInterface; const IID: TGUID; out Intf); overload;
procedure acGetInterface(const Instance: TObject; const IID: TGUID; out Intf); overload;
function acGetInterfaceEx(const Instance: IInterface; const IID: TGUID; out Intf): HRESULT; overload;
function acGetInterfaceEx(const Instance: TObject; const IID: TGUID; out Intf): HRESULT; overload;

procedure acExchangeInt64(var AValue1, AValue2: Int64); inline;
procedure acExchangeIntegers(var AValue1, AValue2); inline;
procedure acExchangePointers(var AValue1, AValue2); inline;
procedure acExchangeStrings(var AValue1, AValue2: string); inline;
function acBoolToHRESULT(AValue: Boolean): HRESULT; inline;
function acGenerateGUID: string;
function acLastSystemErrorMessage: string;
function acLastSystemErrorHRESULT: HRESULT;
function acObjectUID(AObject: TObject): string;
function acSetThreadErrorMode(Mode: DWORD): DWORD; // MSWINDOWS only!
procedure FreeMemAndNil(var P: Pointer);
function IfThen(AValue: Boolean; ATrue, AFalse: TACLBoolean): TACLBoolean; overload;

// Version
function acOSCheckVersion(AMajor, AMinor: Integer; ABuild: Integer = -1): Boolean;
function acOSGetDescription: string;
function IsWine: Boolean;

// HRESULT
function Failed(Status: HRESULT) : BOOL;
function Succeeded(Status: HRESULT): BOOL;

{$IFNDEF MSWINDOWS}
function IsBadReadPtr(Ptr: Pointer; Size: Integer): Boolean; deprecated 'not implemented';
function IsBadWritePtr(Ptr: Pointer; Size: Integer): Boolean; deprecated 'not implemented';
{$ENDIF}
implementation

uses
{$IFDEF MSWINDOWS}
  ACL.Utils.FileSystem,
{$ENDIF}
  ACL.Utils.Strings;

{$IFDEF MSWINDOWS}
type
  TGetThreadErrorMode = function: DWORD; stdcall;
  TSetThreadErrorMode = function (NewMode: DWORD; out OldMode: DWORD): LongBool; stdcall;
  TWineGetVersion = function: PAnsiChar; stdcall;

var
  FGetThreadErrorMode: TGetThreadErrorMode = nil;
  FSetThreadErrorMode: TSetThreadErrorMode = nil;
  FWineGetBuildId: TWineGetVersion = nil;
  FWineGetVersion: TWineGetVersion = nil;
{$ENDIF}

function acOSGetDescription: string;
var
  LBuilder: TACLStringBuilder;
{$IFDEF LINUX}
  LDistroName: string;
{$ENDIF}
begin
  LBuilder := TACLStringBuilder.Get(32);
  try
    LBuilder.Append(TOSVersion.Name);
    LBuilder.Append(' / ');
  {$IFDEF LINUX}
    LDistroName := TACLProcess.ExecuteToString('lsb_release -d');
    LDistroName := acTrim(Copy(LDistroName, Pos(':', LDistroName) + 1));
    LBuilder.Append(LDistroName);
  {$ENDIF}
  {$IFDEF MSWINDOWS}
    LBuilder.Append(TOSVersion.Major);
    LBuilder.Append('.');
    LBuilder.Append(TOSVersion.Minor);
    LBuilder.Append('.');
    LBuilder.Append(TOSVersion.Build);
    if Assigned(FWineGetVersion) and Assigned(FWineGetBuildId) then
    begin
      LBuilder.Append(' / Wine: ');
      LBuilder.Append(acString(FWineGetVersion));
      LBuilder.AppendFormat(' (%s)', [FWineGetBuildId]);
    end;
  {$ENDIF}
    Result := LBuilder.ToString;
  finally
    LBuilder.Release;
  end;
end;

function acOSCheckVersion(AMajor, AMinor: Integer; ABuild: Integer = -1): Boolean;
begin
  Result :=
    (TOSVersion.Major > AMajor) or
    (TOSVersion.Major = AMajor) and (TOSVersion.Minor > AMinor) or
    (TOSVersion.Major = AMajor) and (TOSVersion.Minor = AMinor) and
      ((ABuild < 0{dont care}) or (TOSVersion.Build >= ABuild));
end;

function IsWine: Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := Assigned(FWineGetVersion);
{$ELSE}
  Result := False;
{$ENDIF}
end;

function acSetThreadErrorMode(Mode: DWORD): DWORD;
begin
{$IFDEF MSWINDOWS}
  if Assigned(FSetThreadErrorMode) then
  begin
    if not FSetThreadErrorMode(Mode, Result) then
      Result := FGetThreadErrorMode;
  end
  else
    Result := SetErrorMode(Mode);
{$ELSE}
  Result := 0;
{$ENDIF}
end;

{$IFNDEF MSWINDOWS}
function IsBadReadPtr(Ptr: Pointer; Size: Integer): Boolean;
begin
  Result := False; // stub for compilation
end;

function IsBadWritePtr(Ptr: Pointer; Size: Integer): Boolean;
begin
  Result := False; // stub for compilation
end;
{$ENDIF}

//==============================================================================
// HRESULT
//==============================================================================

function Failed(Status: HRESULT) : BOOL;
begin
  Result := Status and HRESULT($80000000) <> 0;
end;

function Succeeded(Status: HRESULT) : BOOL;
begin
  Result := Status and HRESULT($80000000) = 0;
end;

//==============================================================================
// HMODULE
//==============================================================================

{$IFDEF LINUX}
function FindBinPath(const AFileName: string): string;
const
  KnownPaths: array[0..5] of string = (
    '/usr/local/sbin','/usr/local/bin','/usr/sbin','/usr/bin','/sbin','/bin'
  );
var
  I: integer;
begin
  for I := Low(KnownPaths) to High(KnownPaths) do
  begin
    Result := KnownPaths[I] + PathDelim + AFileName;
    if FileExists(Result) then Exit;
  end;
  Result := AFilename;
end;

function ResolveLibraryPath(ALibraryName: string): string;
const
  Arrow = ') => ';
  OpenBracket = ' (';
var
  LCandidate: string;
  LCandidateFlags: string;
  LCandidateVersion: string;
  LLibList: TStrings;
  LLibVersion: Integer;
  LPosArrow: Integer;
  LPosDot: Integer;
  LPosOpenBracket: Integer;
  LTemp: string;
begin
  if not RunCommand(FindBinPath('ldconfig'), ['-p'], LTemp, []) then
    Exit('');
  if TryStrToInt(Copy(ExtractFileExt(ALibraryName), 2), LLibVersion) then
    ALibraryName := ChangeFileExt(ALibraryName, '')
  else
    LLibVersion := 0;

  LLibList := TStringList.Create;
  try
    LLibList.Text := LTemp;
    for LTemp in LLibList do
    begin
      LPosArrow := Pos(Arrow, LTemp);
      LPosOpenBracket := Pos(OpenBracket, LTemp);
      if (LPosOpenBracket > 0) and (LPosArrow > 0) then
      begin
        LCandidate := LTemp.TrimLeft;
        if LCandidate.StartsWith(ALibraryName + '.') then
        begin
          LCandidateVersion := Copy(LCandidate, Length(ALibraryName) + 2, LPosOpenBracket - Length(ALibraryName) - 3);
          LPosDot := Pos('.', LCandidateVersion);
          if LPosDot > 0 then
            LCandidateVersion := Copy(LCandidateVersion, LPosDot - 1);
          if StrToIntDef(LCandidateVersion, -1) >= LLibVersion then
          begin
            Inc(LPosOpenBracket, Length(OpenBracket));
            LCandidateFlags := Copy(LTemp, LPosOpenBracket, LPosArrow - LPosOpenBracket);
            if LCandidateFlags.Contains('x86-64') = {$IFDEF CPU64}True{$ELSE}False{$ENDIF} then
              Exit(Copy(LTemp, LPosArrow + Length(Arrow)));
          end;
        end;
      end;
    end;
  finally
    LLibList.Free;
  end;
  Result := '';
end;
{$ENDIF}

function acLoadLibrary(const AFileName: string; AFlags: Cardinal = 0): HMODULE;
{$IFDEF MSWINDOWS}
var
  AErrorMode: Cardinal;
  APrevCurPath: string;
begin
  AErrorMode := acSetThreadErrorMode(SEM_FAILCRITICALERRORS);
  try
    APrevCurPath := acGetCurrentDir;
    try
      acSetCurrentDir(acExtractFilePath(AFileName));
      if AFlags <> 0 then
        Result := LoadLibraryEx(PChar(AFileName), 0, AFlags)
      else
        Result := LoadLibrary(PChar(AFileName));
    finally
      acSetCurrentDir(APrevCurPath);
    end;
  finally
    acSetThreadErrorMode(AErrorMode);
  end;
{$ELSE}
var
  LActualLibPath: string;
begin
  if ExtractFilePath(AFileName) <> '' then
    LActualLibPath := AFileName
  else
  begin
    LActualLibPath := IncludeTrailingPathDelimiter(GetCurrentDir) + AFileName;
    if not FileExists(LActualLibPath) then
      LActualLibPath := ResolveLibraryPath(AFileName);
  end;
  if LActualLibPath <> '' then
    Result := LoadLibrary(LActualLibPath)
  else
    Result := 0;
{$ENDIF}
end;

procedure acFreeLibrary(var ALibHandle: HMODULE);
begin
  if ALibHandle <> 0 then
  try
    FreeLibrary(ALibHandle);
  finally
    ALibHandle := 0;
  end;
end;

function acGetProcAddress(ALibHandle: HMODULE; AProcName: PChar): Pointer; overload;
begin
  Result := GetProcAddress(ALibHandle, AProcName);
end;

function acGetProcAddress(ALibHandle: HMODULE; AProcName: PChar; var AResult: Boolean): Pointer;
begin
  Result := GetProcAddress(ALibHandle, AProcName);
  AResult := AResult and (Result <> nil);
end;

{$IFDEF MSWINDOWS}
function acModuleHandle(const AFileName: string): HMODULE;
begin
  Result := GetModuleHandle(PChar(AFileName));
end;

function acModuleFileName(AModule: HMODULE): string;
begin
  Result := GetModuleName(AModule);
end;
{$ENDIF}

// ---------------------------------------------------------------------------------------------------------------------
// Internal Tools
// ---------------------------------------------------------------------------------------------------------------------

procedure FreeMemAndNil(var P: Pointer);
begin
  if P <> nil then
  begin
    FreeMem(P);
    P := nil;
  end;
end;

function IfThen(AValue: Boolean; ATrue, AFalse: TACLBoolean): TACLBoolean;
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

procedure acExchangeStrings(var AValue1, AValue2: string);
var
  ATempValue: string;
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

function acGenerateGUID: string;
var
  G: TGUID;
begin
  CreateGUID(G);
  Result := GUIDToString(G);
end;

function acIsOK(Status: HRESULT): Boolean;
begin
  Result := Status and HRESULT($80000000) = 0;
end;

function acLastSystemErrorMessage: string;
begin
  Result := SysErrorMessage({$IFDEF FPC}GetLastOSError{$ELSE}GetLastError{$ENDIF});
end;

function acLastSystemErrorHRESULT: HRESULT;
begin
{$IFDEF MSWINDOWS}
  if GetLastError <> ERROR_SUCCESS then
    Result := HResultFromWin32(GetLastError)
  else
{$ENDIF}
    Result := E_FAIL;
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

procedure ZeroMemory(Data: Pointer; Size: Integer);
begin
  FillChar(Data^, Size, 0);
end;

//==============================================================================
// Window Handle
//==============================================================================

function acGetClassName(AWnd: TWndHandle): string;
{$IFDEF MSWINDOWS}
var
  ABuf: array[0..64] of Char;
begin
  ZeroMemory(@ABuf[0], SizeOf(ABuf));
  GetClassName(AWnd, @ABuf[0], Length(ABuf));
  Result := ABuf;
{$ELSE}
begin
  Result := '';
{$ENDIF}
end;

function acFindWindow(const AClassName: string): TWndHandle;
begin
{$IFDEF MSWINDOWS}
  Result := FindWindow(PChar(AClassName), nil);
{$ELSE}
  Result := 0;
{$ENDIF}
end;

function acGetWindowRect(AWnd: TWndHandle): TRect;
begin
  if GetWindowRect(AWnd, Result{%H-}) = {$IFDEF FPC}0{$ELSE}False{$ENDIF} then
    Result := NullRect;
end;

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

// -----------------------------------------------------------------------------
// Process
// -----------------------------------------------------------------------------

function acGetProcessFileName(AWnd: TWndHandle; out AFileName: string): Boolean;
{$IFDEF MSWINDOWS}
var
  AProcess: THandle;
  AProcessID: Cardinal;
{$ENDIF}
begin
  Result := False;
{$IFDEF MSWINDOWS}
  if (AWnd <> 0) and (GetWindowThreadProcessId(AWnd, AProcessID) > 0) then
  begin
    AProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, True, AProcessID);
    if AProcess <> 0 then
    try
      SetLength(AFileName, MAX_PATH);
      SetLength(AFileName, GetModuleFileNameEx(AProcess, 0, PChar(AFileName), Length(AFileName)));
      Result := True;
    finally
      CloseHandle(AProcess);
    end;
  end;
{$ENDIF}
end;

{$REGION ' TLiveLogStream '}
type
  TLiveLogStream = class(TStream)
  strict private
    FBuffer: TACLStringBuilder;
    FLog: IStringReceiver;
    procedure Flush;
  public
    constructor Create(ALog: IStringReceiver);
    destructor Destroy; override;
    class function Obtain(ALog: IStringReceiver): TLiveLogStream;
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

{ TLiveLogStream }

class function TLiveLogStream.Obtain(ALog: IStringReceiver): TLiveLogStream;
begin
  if ALog <> nil then
    Exit(TLiveLogStream.Create(ALog));
  Result := nil;
end;

constructor TLiveLogStream.Create(ALog: IStringReceiver);
begin
  FLog := ALog;
  FBuffer := TACLStringBuilder.Create(128);
end;

destructor TLiveLogStream.Destroy;
begin
  Flush;
  FreeAndNil(FBuffer);
  inherited;
end;

procedure TLiveLogStream.Flush;
begin
  if FBuffer.Length > 0 then
  begin
    FLog.Add(FBuffer.ToString);
    FBuffer.Length := 0;
  end;
end;

function TLiveLogStream.Write(const Buffer; Count: Longint): Longint;
var
  LBytes: PByte;
begin
  Result := Count;
  LBytes := @Buffer;
  while Count > 0 do
  begin
    case LBytes^ of
      13, 10:
        Flush;
    else
      FBuffer.Append(AnsiChar(LBytes^));
    end;
    Inc(LBytes);
    Dec(Count);
  end;
end;
{$ENDREGION}

{ TACLProcess }

class function TACLProcess.Execute(const ACmdLine: string;
  AOptions: TExecuteOptions = [eoShowGUI]; AOutputData: TStream = nil;
  AErrorData: TStream = nil; AExitCode: PCardinal = nil): LongBool;
{$IFDEF MSWINDOWS}

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
{$ELSE}
var
  LError: string;
  LExitCode: Integer;
  LOutput: string;
  LProcess: TProcess;
begin
  LProcess := DefaultTProcess.Create(nil);
  try
    LProcess.{%H-}CommandLine{%H-}:= ACmdLine;
    if eoShowGUI in AOptions then
      LProcess.ShowWindow := swoShow
    else
      LProcess.ShowWindow := swoHide;

    if eoWaitForTerminate in AOptions then
    begin
      Result := LProcess.RunCommandLoop(LOutput, LError, LExitCode) = 0;
      if AExitCode <> nil then
        AExitCode^ := LExitCode;
      if AErrorData <> nil then
        AErrorData.Write(PChar(LError)^, Length(LError));
      if AOutputData <> nil then
        AOutputData.Write(PChar(LOutput)^, Length(LOutput));
    end
    else
      LProcess.Execute;
  finally
    LProcess.Free;
  end;
end;
{$ENDIF}

class function TACLProcess.Execute(const ACmdLine: string;
  ALog: IStringReceiver; AOptions: TExecuteOptions = [eoShowGUI]): LongBool;
var
  LErrorData: TStream;
  LExitCode: Cardinal;
  LOutputData: TStream;
begin
  LExitCode := 0;
  LErrorData := TLiveLogStream.Obtain(ALog);
  LOutputData := TLiveLogStream.Obtain(ALog);
  try
    if ALog <> nil then
      ALog.Add('Executing: ' + ACmdLine);
    if Execute(ACmdLine, AOptions, LOutputData, LErrorData, @LExitCode) then
      Result := LExitCode = 0
    else
    begin
      if ALog <> nil then
        ALog.Add(acLastSystemErrorMessage);
      Result := False;
    end;
  finally
    LOutputData.Free;
    LErrorData.Free;
  end;
end;

class function TACLProcess.ExecuteToString(const ACmdLine: string): string;
var
  LData: TStringStream;
begin
  LData := TStringStream.Create;
  try
    Execute(ACmdLine, [eoWaitForTerminate], LData);
    Result := LData.DataString;
  finally
    LData.Free;
  end;
end;

{$IFDEF MSWINDOWS}
class function TACLProcess.IsWow64: LongBool;
begin
{$IFDEF CPUX64}
  Result := False;
{$ELSE}
  Result := IsWow64(GetCurrentProcess);
{$ENDIF}
end;

class function TACLProcess.IsWow64(AProcess: THandle): LongBool;
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

class function TACLProcess.IsWow64Window(AWindow: TWndHandle): LongBool;
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

class function TACLProcess.Wow64SetFileSystemRedirection(AValue: Boolean): LongBool;
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
    else;
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

class function Safe.Cast(AObject: TObject; AClass: TClass; out AValue): Boolean;
begin
  Result := (AObject <> nil) and AObject.InheritsFrom(AClass);
  if Result then
    TObject(AValue) := AObject
  else
    TObject(AValue) := nil;
end;

class function Safe.CastOrNil<T>(AObject: TObject): T;
begin
  if (AObject <> nil) and AObject.InheritsFrom(GetTypeData(TypeInfo(T)).ClassType) then
    Result := T(AObject)
  else
    Result := nil;
end;


initialization
{$IFDEF MSWINDOWS}
  var ALibHandle := GetModuleHandle('ntdll.dll');
  FWineGetBuildId := GetProcAddress(ALibHandle, 'wine_get_build_id');
  FWineGetVersion := GetProcAddress(ALibHandle, 'wine_get_version');

  ALibHandle := GetModuleHandle(kernel32);
  FGetThreadErrorMode := GetProcAddress(ALibHandle, 'GetThreadErrorMode');
  FSetThreadErrorMode := GetProcAddress(ALibHandle, 'SetThreadErrorMode');
{$ENDIF}
  InvariantFormatSettings := TFormatSettings.Invariant;
end.
