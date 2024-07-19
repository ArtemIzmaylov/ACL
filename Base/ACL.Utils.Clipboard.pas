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
//  FPC:       Partial
//
unit ACL.Utils.Clipboard;

{$I ACL.Config.inc}

{
   FPC: TODO
     + Clipboard.AsFiles
}

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
  ACL.Utils.Strings;

type
{$IFDEF MSWINDOWS}

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
    function GetStream(AFormat: Word): TCustomMemoryStream;
    procedure SetFiles(AFiles: TACLStringList);
    procedure SetStream(AFormat: Word; AValue: TCustomMemoryStream);
  public
    function HasText: Boolean;
    function SafeGetText: string;
    property AsFiles: TACLStringList read GetFiles write SetFiles;
    property AsStream[AFormat: Word]: TCustomMemoryStream read GetStream write SetStream;
  end;

{$ENDIF}

// FPC stubs
{$IFDEF FPC}
  TStgMedium = record end;
  TFormatEtc = record end;
const
  CF_HDROP = 0;
{$ENDIF}

var
  CF_CONFIG: Word = 0;
  CF_FILEURIS: Word = 0;
  CF_SHELLIDList: Word = 0;

function MakeFormat(AFormat: Word): TFormatEtc;

// DropHandle
{$IFDEF MSWINDOWS}
function acGetFilesFromDrag(ADragQuery: HDROP;
  AFiles: TACLStringList; AFreeDropData: Boolean = True): Boolean;
{$ENDIF}

{$IFDEF FPC}
function CF_UNICODETEXT: Word;
{$ELSE}
function CF_HTML: Word;
{$ENDIF}
implementation

function {%H-}MakeFormat(AFormat: Word): TFormatEtc;
begin
{$IFDEF MSWINDOWS}
  Result.cfFormat := AFormat;
  Result.ptd := nil;
  Result.dwAspect := DVASPECT_CONTENT;
  Result.lindex := -1;
  Result.tymed := TYMED_HGLOBAL;
{$ELSE}
  {$MESSAGE WARN 'NotImplemented'}
  raise ENotImplemented.Create('Clipboard routine');
{$ENDIF}
end;

{$IFDEF FPC}
function CF_UNICODETEXT: Word;
begin
  Result := CF_TEXT;
end;
{$ELSE}
function CF_HTML: Word;
begin
  Result := RegisterClipboardFormat('HTML Format');
end;
{$ENDIF}

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

function TACLClipboardHelper.GetStream(AFormat: Word): TCustomMemoryStream;
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
begin
{$IFDEF MSWINDOWS}
  Result := TACLGlobalMemory.ToFiles(GetAsHandle(CF_HDROP));
{$ELSE}
  {$MESSAGE WARN 'NotImplemented'}
  Result := nil;
  raise ENotImplemented.Create('Clipboard routine');
{$ENDIF}
end;

procedure TACLClipboardHelper.SetFiles(AFiles: TACLStringList);
begin
{$IFDEF MSWINDOWS}
  SetAsHandle(CF_HDROP, TACLGlobalMemory.Alloc(AFiles));
{$ELSE}
  {$MESSAGE WARN 'NotImplemented'}
  raise ENotImplemented.Create('Clipboard routine');
{$ENDIF}
end;

procedure TACLClipboardHelper.SetStream(AFormat: Word; AValue: TCustomMemoryStream);
begin
{$IFDEF FPC}
  AddFormat(AFormat, AValue);
{$ELSE}
  Clipboard.SetAsHandle(AFormat, TACLGlobalMemory.Alloc(AValue));
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
  CF_CONFIG := RegisterClipboardFormat('ACL.CFG');
  CF_FILEURIS := RegisterClipboardFormat('ACL.FileURIs');
  CF_SHELLIDList := RegisterClipboardFormat(CFSTR_SHELLIDLIST);

finalization
  OleUninitialize;
{$ENDIF}
end.
