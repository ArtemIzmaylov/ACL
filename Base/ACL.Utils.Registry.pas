////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Registry Access
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK (Windows Only!)
//
unit ACL.Utils.Registry;

{$I ACL.Config.inc}

{$IFNDEF MSWINDOWS}
  {$MESSAGE FATAL 'Windows platform is required'}
{$ENDIF}

interface

uses
  Winapi.Windows,
  System.SysUtils,
  // ACL
  ACL.Classes,
  ACL.Utils.Common,
{$IFDEF ACL_LOG_REGISTRY}
  ACL.Utils.Logger,
{$ENDIF}
  ACL.Utils.FileSystem;

function acRegDeleteValue(Key: HKEY; const SubKey, Value: UnicodeString): Boolean; overload;
function acRegDeleteValue(Key: HKEY; const Value: UnicodeString): Boolean; overload;
function acRegEnumKeys(Key: HKEY; const SubKey: UnicodeString; AEnum: TACLStringEnumProc): Boolean;
function acRegKeyDelete(Key: HKEY; const SubKey: UnicodeString): Boolean;
function acRegKeyDeleteWithSubKeys(Key: HKEY; const ASubKeyPath: UnicodeString): Boolean;
function acRegKeyExists(Key: HKEY; const SubKey: UnicodeString): Boolean;
function acRegOpen(Key: HKEY; const SubKey: UnicodeString; AFlags: Cardinal): HKEY;
function acRegOpenCreate(Key: HKEY; const SubKey: UnicodeString): HKEY;
function acRegOpenRead(Key: HKEY; const SubKey: UnicodeString): HKEY; overload;
function acRegOpenRead(Key: HKEY; const SubKey: UnicodeString; out AResultKey: HKEY): Boolean; overload;
function acRegOpenWrite(Key: HKEY; const SubKey: UnicodeString; ACanCreate: Boolean = False): HKEY; overload;
function acRegOpenWrite(Key: HKEY; const SubKey: UnicodeString; out AResultKey: HKEY; ACanCreate: Boolean = False): Boolean; overload;
function acRegQueryValue(Key: HKEY; const S: UnicodeString; out AType, ASize: Cardinal): Boolean;
function acRegReadBinary(Key: HKEY; const ValueName: UnicodeString; out ABytes: TBytes): Boolean;
function acRegReadDefaultStr(Key: HKEY; const SubKey: UnicodeString): UnicodeString;
function acRegReadInt(Key: HKEY; const ValueName: UnicodeString; ADefaultValue: Integer = 0): DWORD;
function acRegReadStr(Key: HKEY; const SubKey, ValueName: UnicodeString): UnicodeString; overload;
function acRegReadStr(Key: HKEY; const ValueName: UnicodeString): UnicodeString; overload;
function acRegReadValue(Key: HKEY; const S: UnicodeString; Data: PByte; var ASize: Cardinal): Boolean;
function acRegValueExists(Key: HKEY; const ValueName: UnicodeString): Boolean;
function acRegWriteDefaultStr(Key: HKEY; const SubKey, Value: UnicodeString): Boolean;
function acRegWriteInt(Key: HKEY; const ValueName: UnicodeString; Value: DWORD): Boolean;
function acRegWriteStr(Key: HKEY; const SubPath, ValueName, Value: UnicodeString): Boolean; overload;
function acRegWriteStr(Key: HKEY; const ValueName, Value: UnicodeString): Boolean; overload;
procedure acRegClose(Key: HKEY);
implementation

function RegCheck(ARegError: Cardinal): Boolean;
begin
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', 'RegCheck(%d)', [ARegError]);
{$ENDIF}
  Result := ARegError = ERROR_SUCCESS;
end;

function acRegQueryValue(Key: HKEY; const S: UnicodeString; out AType, ASize: Cardinal): Boolean;
begin
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', 'RegQueryValue(%d, %s)', [Key, S]);
{$ENDIF}
  Result := RegCheck(RegQueryValueExW(Key, PWideChar(S), nil, @AType, nil, @ASize));
end;

function acRegReadValue(Key: HKEY; const S: UnicodeString; Data: PByte; var ASize: Cardinal): Boolean;
var
  AType: Cardinal;
begin
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', 'RegReadValue(%d, %s)', [Key, S]);
{$ENDIF}
  Result := RegCheck(RegQueryValueExW(Key, PWideChar(S), nil, @AType, Data, @ASize));
end;

function acRegKeyDelete(Key: HKEY; const SubKey: UnicodeString): Boolean;
begin
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', 'RegDeleteKey(%d, %s)', [Key, SubKey]);
{$ENDIF}
  Result := RegCheck(RegDeleteKeyW(Key, PWideChar(SubKey)));
end;

function acRegKeyDeleteWithSubKeys(Key: HKEY; const ASubKeyPath: UnicodeString): Boolean;
var
  ABuffer: array[0..63] of WideChar;
  ACount, ALength: Cardinal;
  AErrorCode: Integer;
  ASubKey: HKEY;
  I: Integer;
begin
  Result := (ASubKeyPath <> '') and (Key <> 0);
  if not Result then Exit;

  if acRegOpenRead(Key, ASubKeyPath, ASubKey) then
  begin
    try
      if RegCheck(RegQueryInfoKey(ASubKey, nil, nil, nil, @ACount, nil, nil, nil, nil, nil, nil, nil)) then
      begin
        for I := ACount - 1 downto 0 do
        begin
          ALength := Length(ABuffer);
          ZeroMemory(@ABuffer[0], SizeOf(ABuffer));
          AErrorCode := RegEnumKeyExW(ASubKey, DWORD(I), @ABuffer[0], ALength, nil, nil, nil, nil);
          if AErrorCode = ERROR_SUCCESS then
            acRegKeyDeleteWithSubKeys(ASubKey, ABuffer);
        end;
      end;
    finally
      acRegClose(ASubKey);
    end;
    Result := acRegKeyDelete(Key, ASubKeyPath);
  end;
end;

function acRegDeleteValue(Key: HKEY; const Value: UnicodeString): Boolean;
begin
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', 'RegDeleteValue(%d, %s)', [Key, Value]);
{$ENDIF}
  Result := RegCheck(RegDeleteValueW(Key, PWideChar(Value)));
end;

function acRegDeleteValue(Key: HKEY; const SubKey, Value: UnicodeString): Boolean;
begin
  Key := acRegOpenWrite(Key, SubKey, True);
  Result := (Key <> 0) and acRegDeleteValue(Key, Value);
  acRegClose(Key);
end;

function acRegKeyExists(Key: HKEY; const SubKey: UnicodeString): Boolean;
var
  K: Integer;
begin
  Result := Key <> 0;
  if Result then
  begin
    K := acRegOpenRead(Key, SubKey);
    Result := K <> 0;
    if Result then
      acRegClose(K);
  end;
end;

function acRegWriteInt(Key: HKEY; const ValueName: UnicodeString; Value: DWORD): Boolean;
begin
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', 'RegWriteInt(%d, %s, %d)', [Key, ValueName, Value]);
{$ENDIF}
  Result := Key <> 0;
  if Result then
    Result := RegCheck(RegSetValueExW(Key, PWideChar(ValueName), 0, REG_DWORD, @Value, SizeOf(DWORD)));
end;

function acRegEnumKeys(Key: HKEY; const SubKey: UnicodeString; AEnum: TACLStringEnumProc): Boolean;
var
  ABuf: TFilePath;
  AReg: HKEY;
  ASubKeys, ALength: Cardinal;
  I: Integer;
begin
  AReg := acRegOpenRead(Key, SubKey);
  Result := AReg <> 0;
  if Result then
  begin
    if RegQueryInfoKeyW(AReg, nil, nil, nil, @ASubKeys, nil, nil, nil, nil, nil, nil, nil) = ERROR_SUCCESS then
    begin
      for I := 0 to Integer(ASubKeys) - 1 do
      begin
        ALength := High(ABuf);
        acClearFilePath(ABuf);
        RegEnumKeyExW(AReg, I, @ABuf[0], ALength, nil, nil, nil, nil);
        AEnum(ABuf);
      end;
      acRegClose(AReg);
    end;
  end;
end;

function acRegReadBinary(Key: HKEY; const ValueName: UnicodeString; out ABytes: TBytes): Boolean;
var
  AType, ASize: Cardinal;
begin
  Result := False;
  if Key <> 0 then
  begin
    Result := acRegQueryValue(Key, ValueName, AType, ASize);
    Result := Result and (AType = REG_BINARY);
    if Result then
    begin
      SetLength(ABytes, ASize);
      Result := acRegReadValue(Key, ValueName, @ABytes[0], ASize);
    end;
  end;
end;

function acRegReadDefaultStr(Key: HKEY; const SubKey: UnicodeString): UnicodeString;
begin
  Key := acRegOpenRead(Key, SubKey);
  Result := acRegReadStr(Key, '');
  acRegClose(Key);
end;

function acRegReadInt(Key: HKEY; const ValueName: UnicodeString; ADefaultValue: Integer = 0): DWORD;
var
  AType, ASize: Cardinal;
begin
  Result := ADefaultValue;
  if Key <> 0 then
  begin
  {$IFDEF ACL_LOG_REGISTRY}
    AddToDebugLog('Registry', 'RegReadInt(%d, %s)', [Key, ValueName]);
  {$ENDIF}
    ASize := SizeOf(Cardinal);
    if not RegCheck(RegQueryValueExW(Key, PWideChar(ValueName), nil, @AType, PByte(@Result), @ASize)) or (AType <> REG_DWORD) then
      Result := ADefaultValue;
  end;
end;

function acRegValueExists(Key: HKEY; const ValueName: UnicodeString): Boolean;
var
  AType, ASize: Cardinal;
begin
  Result := (Key <> 0) and acRegQueryValue(Key, ValueName, AType, ASize);
end;

procedure acRegClose(Key: HKEY);
begin
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', 'RegCloseKey(%d)', [Key]);
{$ENDIF}
  if Key <> 0 then
    RegCloseKey(Key);
end;

function acRegWriteDefaultStr(Key: HKEY; const SubKey, Value: UnicodeString): Boolean;
begin
  Result := acRegWriteStr(Key, SubKey, '', Value);
end;

function acRegWriteStr(Key: HKEY; const SubPath, ValueName, Value: UnicodeString): Boolean;
begin
  Key := acRegOpenWrite(Key, SubPath, True);
  Result := acRegWriteStr(Key, ValueName, Value);
  acRegClose(Key);
end;

function acRegWriteStr(Key: HKEY; const ValueName, Value: UnicodeString): Boolean;
begin
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', 'RegWriteStr(%d, %s, %s)', [Key, ValueName, Value]);
{$ENDIF}
  Result := Key <> 0;
  if Result then
    Result := RegCheck(RegSetValueExW(Key, PWideChar(ValueName), 0, REG_SZ,
      PWideChar(Value), SizeOf(WideChar) * (Length(Value) + 1)));
end;

function acRegReadStr(Key: HKEY; const ValueName: UnicodeString): UnicodeString;
var
  ABuffer: PWideChar;
  AType, ASize: Cardinal;
begin
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', 'RegReadStr(%d, %s)', [Key, ValueName]);
{$ENDIF}
  Result := '';
  if Key <> 0 then
  begin
    ASize := 0;
    if acRegQueryValue(Key, ValueName, AType, ASize) and ((AType = REG_SZ) or (AType = REG_EXPAND_SZ)) then
    begin
      ABuffer := AllocMem(ASize);
      try
        if acRegReadValue(Key, ValueName, PByte(ABuffer), ASize) then
          Result := ABuffer;
      finally
        FreeMem(ABuffer);
      end;
    end;
  end;
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', ' Result = %s', [Result]);
{$ENDIF}
end;

function acRegReadStr(Key: HKEY; const SubKey, ValueName: UnicodeString): UnicodeString; overload;
begin
  Result := '';
  Key := acRegOpenRead(Key, SubKey);
  if Key <> 0 then
  begin
    Result := acRegReadStr(Key, ValueName);
    acRegClose(Key);
  end;
end;

function acRegOpen(Key: HKEY; const SubKey: UnicodeString; AFlags: Cardinal): HKEY;
begin
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', 'RegOpen(%d, %s, %d)', [Key, SubKey, AFlags]);
{$ENDIF}
  if not RegCheck(RegOpenKeyExW(Key, PWideChar(SubKey), 0, AFlags, Result)) then
    Result := 0;
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', 'Result = %d', [Result]);
{$ENDIF}
end;

function acRegOpenRead(Key: HKEY; const SubKey: UnicodeString): HKEY;
begin
  Result := acRegOpen(Key, SubKey, KEY_READ);
end;

function acRegOpenRead(Key: HKEY; const SubKey: UnicodeString; out AResultKey: HKEY): Boolean; overload;
begin
  AResultKey := acRegOpenRead(Key, SubKey);
  Result := AResultKey <> 0;
end;

function acRegOpenCreate(Key: HKEY; const SubKey: UnicodeString): HKEY;
begin
{$IFDEF ACL_LOG_REGISTRY}
  AddToDebugLog('Registry', 'RegCreate(%d, %s)', [Key, SubKey]);
{$ENDIF}
  if not RegCheck(RegCreateKeyExW(Key, PWideChar(SubKey), 0, nil, 0, KEY_ALL_ACCESS, nil, Result, nil)) then
    Result := 0;
end;

function acRegOpenWrite(Key: HKEY; const SubKey: UnicodeString; ACanCreate: Boolean = False): HKEY;
begin
  Result := acRegOpen(Key, SubKey, KEY_READ or KEY_WRITE);
  if Result = 0 then
  begin
    if ACanCreate then
      Result := acRegOpenCreate(Key, SubKey);
  end;
end;

function acRegOpenWrite(Key: HKEY; const SubKey: UnicodeString; out AResultKey: HKEY; ACanCreate: Boolean = False): Boolean;
begin
  AResultKey := acRegOpenWrite(Key, SubKey, ACanCreate);
  Result := AResultKey <> 0;
end;

end.
