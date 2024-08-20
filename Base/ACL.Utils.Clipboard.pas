////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Clipboard and OS-wide data sharing utilities
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Utils.Clipboard;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.ActiveX,
  Winapi.Messages,
  Winapi.ShlObj,
  Winapi.ShellAPI,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}SysUtils,
  // Vcl
{$IFNDEF ACL_BASE_NOVCL}
  {Vcl.}Clipbrd,
{$ENDIF}
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

const
  acMimeConfig = 'text/aimp-config';
  acMimeInternalFileList = 'text/aimp-uri-list';
  acMimeLinuxFileList = 'text/uri-list';
  acMimeHtml = 'text/html';

type
{$IFDEF MSWINDOWS}
  TClipboardFormat = Word;

  TACLGlobalMemory = class
  public
    class function Alloc(AData: PByte; ASize: Integer): HGLOBAL; overload;
    class function Alloc(AData: TACLIniFile): HGLOBAL; overload;
    class function Alloc(AData: TCustomMemoryStream): HGLOBAL; overload;
    class function Alloc(AFiles: TACLStringList): HGLOBAL; overload;
    class function Alloc(const S: AnsiString): HGLOBAL; overload;
    class function Alloc(const S: UnicodeString): HGLOBAL; overload;
    class function ToFiles(AHandle: HGLOBAL): TACLStringList;
    class function ToString(AHandle: HGLOBAL; AWide: Boolean): string; reintroduce;
  end;

  { TACLGlobalMemoryStream }

  TACLGlobalMemoryStream = class(TCustomMemoryStream)
  strict private
    FHandle: HGLOBAL;
  public
    constructor Create(AHandle: HGLOBAL);
    destructor Destroy; override;
  end;

{$ENDIF}

{$IFNDEF ACL_BASE_NOVCL}

  { TACLClipboardHelper }

  TACLClipboardHelper = class helper for TClipboard
  strict private
    function GetFiles: TACLStringList;
    function GetStream(AFormat: TClipboardFormat): TCustomMemoryStream;
    procedure SetFiles(AFiles: TACLStringList);
    procedure SetStream(AFormat: TClipboardFormat; AValue: TCustomMemoryStream);
  public
  {$IFDEF LINUX}
    function EncodeFiles(AFiles: TACLStringList): string;
  {$ENDIF}
    function HasText: Boolean;
    function SafeGetText: string;
    property AsFiles: TACLStringList read GetFiles write SetFiles;
    property AsStream[AFormat: TClipboardFormat]: TCustomMemoryStream read GetStream write SetStream;
  end;

{$ENDIF}

{$IFDEF FPC}
  TFormatEtc = record
    cfFormat: TClipboardFormat;
  end;

  TStgMedium = record
    Owned: Boolean;
    Data: PByte;
    Size: Integer;
  end;
{$ENDIF}

function MakeFormat(AFormat: Word): TFormatEtc;
function MediumAlloc(AData: Pointer; ASize: Integer; out AMedium: TStgMedium): Boolean;
function MediumGetFiles(const AMedium: TStgMedium; out AFiles: TACLStringList): Boolean;
function MediumGetStream(const AMedium: TStgMedium; out AStream: TCustomMemoryStream): Boolean;
function MediumGetString(const AMedium: TStgMedium; AFormat: TClipboardFormat): string;
{$IFDEF FPC}
procedure ReleaseStgMedium(var Medium: TStgMedium);
{$ENDIF}

// DropHandle
{$IFDEF MSWINDOWS}
function acGetFilesFromDrag(ADragQuery: HDROP;
  AFiles: TACLStringList; AFreeDropData: Boolean = True): Boolean;
{$ENDIF}

// Formats
function CF_CONFIG: TClipboardFormat;
function CF_FILEURIS: TClipboardFormat;
function CF_SHELLIDList: TClipboardFormat;
{$IFDEF FPC}
function CF_HDROP: TClipboardFormat;
function CF_UNICODETEXT: TClipboardFormat;
{$ELSE}
function CF_HTML: TClipboardFormat;
{$ENDIF}
implementation

{$IFDEF FPC}
uses
  ACL.Web;
{$ENDIF}

function {%H-}MakeFormat(AFormat: Word): TFormatEtc;
begin
  Result.cfFormat := AFormat;
{$IFDEF MSWINDOWS}
  Result.ptd := nil;
  Result.dwAspect := DVASPECT_CONTENT;
  Result.lindex := -1;
  Result.tymed := TYMED_HGLOBAL;
{$ENDIF}
end;

function MediumAlloc(AData: Pointer; ASize: Integer; out AMedium: TStgMedium): Boolean;
begin
{$IFDEF MSWINDOWS}
  AMedium.tymed := TYMED_HGLOBAL;
  AMedium.hGlobal := TACLGlobalMemory.Alloc(AData, ASize);
  Result := AMedium.hGlobal <> 0;
{$ELSE}
  Result := ASize > 0;
  if Result then
  begin
    AMedium.Owned := True;
    AMedium.Size := ASize;
    AMedium.Data := AllocMem(ASize);
    Move(AData^, AMedium.Data^, AMedium.Size);
  end;
{$ENDIF}
end;

function MediumGetFiles(const AMedium: TStgMedium; out AFiles: TACLStringList): Boolean;
{$IFDEF MSWINDOWS}
begin
  if AMedium.tymed = TYMED_HGLOBAL then
  begin
    AFiles := TACLGlobalMemory.ToFiles(AMedium.hGlobal);
    Result := AFiles <> nil;
  end
  else
    Result := False;
{$ELSE}
var
  I: Integer;
begin
  AFiles := TACLStringList.Create;
  if (AMedium.Data <> nil) and (AMedium.Size > 0) then
    AFiles.Append(PChar(AMedium.Data), AMedium.Size);
  for I := 0 to AFiles.Count - 1 do
  begin
    if AFiles[I].StartsWith(acFileProtocol, True) then
      AFiles[I] := acURLDecode(Copy(AFiles[I], Length(acFileProtocol) + 1));
  end;
  Result := AFiles.Count > 0;
  if not Result then
    FreeAndNil(AFiles);
{$ENDIF}
end;

function MediumGetStream(const AMedium: TStgMedium; out AStream: TCustomMemoryStream): Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := AMedium.tymed = TYMED_HGLOBAL;
  if Result then
    AStream := TACLGlobalMemoryStream.Create(AMedium.hGlobal);
{$ELSE}
  Result := (AMedium.Data <> nil) and (AMedium.Size > 0);
  if Result then
  begin
    AStream := TMemoryStream.Create;
    AStream.Size := AMedium.Size;
    Move(AMedium.Data^, AStream.Memory^, AMedium.Size);
  end;
{$ENDIF}
end;

function MediumGetString(const AMedium: TStgMedium; AFormat: TClipboardFormat): string;
{$IFDEF MSWINDOWS}
var
  LFiles: TACLStringList;
begin
  case AFormat of
    CF_TEXT:
      Result := TACLGlobalMemory.ToString(AMedium.hGlobal, False);
    CF_UNICODETEXT:
      Result := TACLGlobalMemory.ToString(AMedium.hGlobal, True);
    CF_HDROP:
      begin
        LFiles := TACLGlobalMemory.ToFiles(AMedium.hGlobal);
        if LFiles <> nil then
        try
          Result := LFiles.Text;
        finally
          LFiles.Free;
        end;
      end;
  else
    Result := TACLGlobalMemory.ToString(AMedium.hGlobal, False);
  end;
{$ELSE}
begin
  Result := acMakeString(PChar(AMedium.Data), AMedium.Size);
{$ENDIF}
end;

{$IFDEF FPC}
procedure ReleaseStgMedium(var Medium: TStgMedium);
begin
  if Medium.Owned then
    FreeMem(Medium.Data, Medium.Size);
  FillChar(Medium, SizeOf(Medium), 0);
end;
{$ENDIF}

{$REGION ' Clipboard Formats '}

function CF_CONFIG: TClipboardFormat;
begin
  Result := RegisterClipboardFormat(acMimeConfig);
end;

function CF_FILEURIS: TClipboardFormat;
begin
  Result := RegisterClipboardFormat(acMimeInternalFileList);
end;

function CF_SHELLIDList: TClipboardFormat;
begin
{$IFDEF MSWINDOWS}
  Result := RegisterClipboardFormat(CFSTR_SHELLIDLIST);
{$ELSE}
  Result := 0
{$ENDIF}
end;

{$IFDEF FPC}

function CF_HDROP: TClipboardFormat;
begin
  Result := RegisterClipboardFormat(acMimeLinuxFileList);
end;

function CF_UNICODETEXT: TClipboardFormat;
begin
  Result := CF_TEXT;
end;

{$ELSE}

function CF_HTML: TClipboardFormat;
begin
  Result := RegisterClipboardFormat('HTML Format');
end;

{$ENDIF}
{$ENDREGION}

{$IFDEF MSWINDOWS}
function acGetFilesFromDrag(ADragQuery: HDROP;
  AFiles: TACLStringList; AFreeDropData: Boolean = True): Boolean;
var
  AFilename: PWideChar;
  I, ACount, Size: Integer;
begin
  ACount := DragQueryFileW(ADragQuery, $FFFFFFFF, nil, 0);
  Result := ACount > 0;
  if Result then
  try
    AFiles.Clear;
    AFiles.Capacity := ACount;
    for I := 0 to ACount - 1 do
    begin
      Size := DragQueryFileW(ADragQuery, I, nil, 0) + 1;
      AFilename := AllocMem(Size * 2);
      try
        DragQueryFileW(ADragQuery, I, AFilename, Size);
        AFiles.Add(AFileName, nil);
      finally
        FreeMemory(AFilename);
      end;
    end;
  finally
    if AFreeDropData then
      DragFinish(ADragQuery);
  end;
end;

{ TACLGlobalMemory }

class function TACLGlobalMemory.Alloc(AData: PByte; ASize: Integer): HGLOBAL;
var
  ALockPtr: Pointer;
begin
  Result := 0;
  if ASize <> 0 then
  begin
    Result := GlobalAlloc(GMEM_MOVEABLE, ASize);
    ALockPtr := GlobalLock(Result);
    if ALockPtr <> nil then
    try
      Move(AData^, ALockPtr^, ASize);
    finally
      GlobalUnlock(Result);
    end;
  end;
end;

class function TACLGlobalMemory.Alloc(AData: TCustomMemoryStream): HGLOBAL;
begin
  Result := Alloc(AData.Memory, AData.Size);
end;

class function TACLGlobalMemory.Alloc(const S: UnicodeString): HGLOBAL;
begin
  Result := Alloc(PByte(PWideChar(S)), (Length(S) + 1) * SizeOf(WideChar));
end;

class function TACLGlobalMemory.Alloc(AFiles: TACLStringList): HGLOBAL;
var
  ADropFiles: PDropFiles;
  ARequiredSize: Integer;
  AText: UnicodeString;
begin
  AText := AFiles.GetDelimitedText(#0);
  ARequiredSize := SizeOf(TDropFiles) + (Length(AText) + 1) * SizeOf(WideChar);
  Result := GlobalAlloc(GMEM_MOVEABLE or GMEM_ZEROINIT, ARequiredSize);
  if Result <> 0 then
  begin
    ADropFiles := GlobalLock(Result);
    try
      ADropFiles.pFiles := SizeOf(TDropFiles);
      ADropFiles.fWide := True;
      Move(PWideChar(AText)^, PWideChar(NativeUInt(ADropFiles) +
        ADropFiles.pFiles)^, Length(AText) * SizeOf(WideChar));
    finally
      GlobalUnlock(Result);
    end;
  end;
end;

class function TACLGlobalMemory.Alloc(const S: AnsiString): HGLOBAL;
begin
  Result := Alloc(PByte(PAnsiChar(S)), Length(S) + 1);
end;

class function TACLGlobalMemory.Alloc(AData: TACLIniFile): HGLOBAL;
var
  AStream: TMemoryStream;
begin
  if AData <> nil then
  begin
    AStream := TMemoryStream.Create;
    try
      AData.SaveToStream(AStream);
      Result := Alloc(AStream);
    finally
      AStream.Free;
    end;
  end
  else
    Result := 0;
end;

class function TACLGlobalMemory.ToFiles(AHandle: HGLOBAL): TACLStringList;
var
  ADropFiles: PDropFiles;
  AFileName: PAnsiChar;
  AString: UnicodeString;
begin
  Result := nil;
  ADropFiles := PDropFiles(GlobalLock(AHandle));
  try
    if ADropFiles <> nil then
    begin
      AFileName := PAnsiChar(ADropFiles) + ADropFiles^.pFiles;
      while (AFileName^ <> #0) do
      begin
        if ADropFiles^.fWide then
        begin
          AString := PWideChar(AFileName);
          Inc(AFileName, (Length(AString) + 1) * 2);
        end
        else
        begin
          AString := acStringFromAnsiString(AFileName);
          Inc(AFileName, Length(AString) + 1);
        end;
        if Result = nil then
          Result := TACLStringList.Create;
        Result.Add(AString);
      end;
    end;
  finally
    GlobalUnlock(AHandle);
  end;
end;

class function TACLGlobalMemory.ToString(AHandle: HGLOBAL; AWide: Boolean): string;
var
  LPtr: Pointer;
begin
  LPtr := GlobalLock(AHandle);
  try
    if AWide then
      Result := acString(PWideChar(LPtr))
    else
      Result := acString(PAnsiChar(LPtr));
  finally
    GlobalUnlock(AHandle);
  end;
end;

{ TACLGlobalMemoryStream }

constructor TACLGlobalMemoryStream.Create(AHandle: HGLOBAL);
begin
  FHandle := AHandle;
  if FHandle <> 0 then
    SetPointer(GlobalLock(FHandle), GlobalSize(FHandle));
end;

destructor TACLGlobalMemoryStream.Destroy;
begin
  if FHandle <> 0 then
    GlobalUnlock(FHandle);
  inherited;
end;
{$ENDIF}

{$IFNDEF ACL_BASE_NOVCL}

{ TACLClipboardHelper }

{$IFDEF LINUX}
function TACLClipboardHelper.EncodeFiles(AFiles: TACLStringList): string;
var
  I: Integer;
begin
  AFiles := AFiles.Clone;
  try
    for I := 0 to AFiles.Count - 1 do
    begin
      if not acIsUrlFileName(AFiles[I]) then
        AFiles[I] := acFileProtocol + acURLEncode(AFiles[I]);
    end;
    Result := AFiles.GetDelimitedText(#10, False);
  finally
    AFiles.Free;
  end;
end;
{$ENDIF}

function TACLClipboardHelper.GetStream(AFormat: TClipboardFormat): TCustomMemoryStream;
begin
{$IFDEF FPC}
  Result := TMemoryStream.Create;
  if not GetFormat(AFormat, Result) then
    FreeAndNil(Result);
{$ELSE}
  var LHandle := GetAsHandle(AFormat);
  if LHandle <> 0 then
    Result := TACLGlobalMemoryStream.Create(LHandle)
  else
    Result := nil;
{$ENDIF}
end;

function TACLClipboardHelper.SafeGetText: string;
begin
  try
    Result := AsText;
  except
    Result := acEmptyStr;
  end;
end;

function TACLClipboardHelper.GetFiles: TACLStringList;
{$IFDEF MSWINDOWS}
begin
  Result := TACLGlobalMemory.ToFiles(GetAsHandle(CF_HDROP));
{$ELSE}
var
  I: Integer;
  LMedium: TStgMedium;
  LStream: TMemoryStream;
begin
  LStream := TMemoryStream.Create;
  try
    if GetFormat(FindFormatID(acMimeLinuxFileList), LStream) then
    begin
      LMedium.Owned := False;
      LMedium.Data := LStream.Memory;
      LMedium.Size := LStream.Size;
      if MediumGetFiles(LMedium, Result) then Exit;
    end;
  finally
    LStream.Free;
  end;
  Result := TACLStringList.Create;
{$ENDIF}
end;

procedure TACLClipboardHelper.SetFiles(AFiles: TACLStringList);
{$IFDEF MSWINDOWS}
begin
  SetAsHandle(CF_HDROP, TACLGlobalMemory.Alloc(AFiles));
{$ELSE}

  procedure Append(const AMimeType, AData: AnsiString);
  begin
    AddFormat(RegisterClipboardFormat(AMimeType), PAnsiChar(AData)^, Length(AData));
  end;

var
  LFiles: AnsiString;
begin
  Open;
  try
    Clear;
    LFiles := EncodeFiles(AFiles);
    Append(acMimeLinuxFileList, LFiles);
    LFiles := 'copy'#10 + LFiles;
    Append('x-special/mate-copied-files', LFiles);
    Append('x-special/gnome-copied-files', LFiles);
  finally
    Close;
  end;
{$ENDIF}
end;

procedure TACLClipboardHelper.SetStream(AFormat: TClipboardFormat; AValue: TCustomMemoryStream);
begin
{$IFDEF FPC}
  AddFormat(AFormat, AValue);
{$ELSE}
  Clipboard.SetAsHandle(AFormat, TACLGlobalMemory.Alloc(AValue.Memory, AValue.Size));
{$ENDIF}
end;

function TACLClipboardHelper.HasText: Boolean;
begin
  Result := HasFormat(CF_TEXT){$IFDEF MSWINDOWS} or HasFormat(CF_UNICODETEXT){$ENDIF};
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
initialization
  OleInitialize(nil);
finalization
  OleUninitialize;
{$ENDIF}
end.
