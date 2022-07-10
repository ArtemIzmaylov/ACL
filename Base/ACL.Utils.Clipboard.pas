{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*   Clipboard and Data Sharing Utilities    *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.Clipboard;

{$I ACL.Config.inc}

interface

uses
  Windows, Messages, ActiveX, ShellAPI, ShlObj, Classes,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.FileFormats.INI;

type

  { TACLGlobalMemoryStream }

  TACLGlobalMemoryStream = class(TCustomMemoryStream)
  strict private
    FHandle: HGLOBAL;
  public
    constructor Create(AHandle: HGLOBAL);
    destructor Destroy; override;
  end;

var
  CF_CONFIG: Word = 0;
  CF_FILEURIS: Word = 0;

function GlobalAllocFromData(AData: PByte; ADataSize: Integer): HGLOBAL;
function GlobalAllocFromStream(AStream: TMemoryStream): HGLOBAL;
function MakeFormat(AFormat: Word): TFormatEtc;

// Clipboard
function acClipboardFormatName(const AFormat: Word): UnicodeString;
function acCopyToClipboard(AFormat, AMem: THandle): Cardinal;
procedure acCopyFilesToClipboard(const AFileList: TACLStringList);
procedure acCopyFileToClipboard(const AFileName: UnicodeString);
procedure acCopyStringToClipboard(const S: AnsiString); overload;
procedure acCopyStringToClipboard(const S: UnicodeString); overload;
function acTextFromClipboard(AFormat: Word = CF_UNICODETEXT): UnicodeString;

// DropHandle
function acGetFilesFromDrag(ADragQuery: THandle; const AFiles: TACLStringList; AFreeDropData: Boolean = True): Boolean;
function acMakeDropHandle(const AFileList: TACLStringList): THandle;

// Files & HGLOBAL
function acFilesFromHGLOBAL(AGlobal: HGLOBAL): UnicodeString; overload;
function acFilesFromHGLOBAL(AGlobal: HGLOBAL; AFiles: TACLStringList): Boolean; overload;

// Text & HGLOBAL
procedure acConfigFromHGLOBAL(AGlobal: HGLOBAL; AConfig: TACLIniFile);
function acConfigToHGLOBAL(const AConfig: TACLIniFile): HGLOBAL;
function acTextFromHGLOBAL(AGlobal: HGLOBAL; ALines: TACLStringList; AUnicode: Boolean = False): Boolean; overload;
function acTextFromHGLOBAL(AGlobal: HGLOBAL; AUnicode: Boolean = False): UnicodeString; overload;
function acTextToHGLOBAL(const S: AnsiString): HGLOBAL; overload;
function acTextToHGLOBAL(const S: UnicodeString): HGLOBAL; overload;
implementation

uses
  SysUtils,
  ACL.FastCode,
  ACL.Utils.FileSystem,
  ACL.Utils.Stream,
  ACL.Utils.Strings;

function GlobalAllocFromData(AData: PByte; ADataSize: Integer): HGLOBAL;
var
  ALockPtr: Pointer;
begin
  Result := 0;
  if ADataSize <> 0 then
  begin
    Result := GlobalAlloc(GMEM_MOVEABLE or GMEM_ZEROINIT, ADataSize);
    ALockPtr := GlobalLock(Result);
    if ALockPtr <> nil then
    try
      FastMove(AData^, ALockPtr^, ADataSize);
    finally
      GlobalUnlock(Result);
    end;
  end;
end;

function GlobalAllocFromStream(AStream: TMemoryStream): HGLOBAL;
begin
  Result := GlobalAllocFromData(AStream.Memory, AStream.Size);
end;

function MakeFormat(AFormat: Word): TFormatEtc;
begin
  Result.cfFormat := AFormat;
  Result.ptd := nil;
  Result.dwAspect := DVASPECT_CONTENT;
  Result.lindex := -1;
  Result.tymed := TYMED_HGLOBAL;
end;

// Clipboard -----------------------------------------------------------------------------------------------------------

procedure acCopyStringToClipboard(const S: AnsiString);
begin
  acCopyToClipboard(CF_TEXT, acTextToHGLOBAL(S));
end;

function acClipboardFormatName(const AFormat: Word): UnicodeString;
var
  B: array[0..64] of WideChar;
begin
  GetClipboardFormatNameW(AFormat, @B[0], Length(B));
  Result := B;
end;

function acCopyToClipboard(AFormat, AMem: THandle): Cardinal;
begin
  if not OpenClipboard(0) then
    Exit(GetLastError);

  EmptyClipboard;
  SetClipboardData(AFormat, AMem);
  Result := GetLastError;
  CloseClipboard;
end;

procedure acCopyFilesToClipboard(const AFileList: TACLStringList);
begin
  acCopyToClipboard(CF_HDROP, acMakeDropHandle(AFileList));
end;

procedure acCopyFileToClipboard(const AFileName: UnicodeString);
var
  AList: TACLStringList;
begin
  if acFileExists(AFileName) then
  begin
    AList := TACLStringList.Create;
    try
      AList.Add(AFileName);
      acCopyFilesToClipboard(AList);
    finally
      AList.Free;
    end;
  end;
end;

procedure acCopyStringToClipboard(const S: UnicodeString);
begin
  acCopyToClipboard(CF_UNICODETEXT, acTextToHGLOBAL(S));
end;

function acTextFromClipboard(AFormat: Word = CF_UNICODETEXT): UnicodeString;
begin
  if OpenClipboard(0) then
  try
    Result := acTextFromHGLOBAL(GetClipboardData(AFormat), AFormat = CF_UNICODETEXT);
  finally
    CloseClipboard;
  end
  else
    Result := '';
end;

// DropHandle ----------------------------------------------------------------------------------------------------------

function acGetFilesFromDrag(ADragQuery: THandle; const AFiles: TACLStringList; AFreeDropData: Boolean = True): Boolean;
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

function acMakeDropHandle(const AFileList: TACLStringList): THandle;
var
  ADropFiles: PDropFiles;
  ARequiredSize: Integer;
  AText: UnicodeString;
begin
  AText := AFileList.GetDelimitedText(UNICODE_NULL);
  ARequiredSize := SizeOf(TDropFiles) + (Length(AText) + 1) * SizeOf(WideChar);
  Result := GlobalAlloc(GMEM_MOVEABLE or GMEM_ZEROINIT, ARequiredSize);
  if Result <> 0 then
  begin
    ADropFiles := GlobalLock(Result);
    try
      ADropFiles.pFiles := SizeOf(TDropFiles);
      ADropFiles.fWide := True;
      FastMove(PWideChar(AText)^, PWideChar(NativeUInt(ADropFiles) + ADropFiles.pFiles)^, Length(AText) * SizeOf(WideChar));
    finally
      GlobalUnlock(Result);
    end;
  end;
end;

// Files ---------------------------------------------------------------------------------------------------------------

function acFilesFromHGLOBAL(AGlobal: HGLOBAL): UnicodeString;
var
  AList: TACLStringList;
begin
  AList := TACLStringList.Create;
  try
    acFilesFromHGLOBAL(AGlobal, AList);
    Result := AList.Text;
  finally
    AList.Free;
  end;
end;

function acFilesFromHGLOBAL(AGlobal: HGLOBAL; AFiles: TACLStringList): Boolean;
var
  ADropFiles: PDropFiles;
  AFileName: PAnsiChar;
  AString: UnicodeString;
begin
  Result := False;
  ADropFiles := PDropFiles(GlobalLock(AGlobal));
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
          AString := acStringFromAnsi(AFileName);
          Inc(AFileName, Length(AString) + 1);
        end;
        AFiles.Add(AString);
        Result := True;
      end;
    end;
  finally
    GlobalUnlock(AGlobal);
  end;
end;

// Text ----------------------------------------------------------------------------------------------------------------

function acTextToHGLOBAL(const S: AnsiString): HGLOBAL;
begin
  Result := GlobalAllocFromData(@S[1], Length(S) + 1);
end;

procedure acConfigFromHGLOBAL(AGlobal: HGLOBAL; AConfig: TACLIniFile);
var
  AStream: TStream;
begin
  AConfig.Clear;
  if AGlobal <> 0 then
  begin
    AStream := TACLHGlobalReadOnlyStream.Create(AGlobal);
    try
      AConfig.LoadFromStream(AStream);
    finally
      AStream.Free;
    end;
  end;
end;

function acConfigToHGLOBAL(const AConfig: TACLIniFile): HGLOBAL;
var
  AStream: TMemoryStream;
begin
  if AConfig <> nil then
  begin
    AStream := TMemoryStream.Create;
    try
      AConfig.SaveToStream(AStream);
      Result := GlobalAllocFromData(AStream.Memory, AStream.Size);
    finally
      AStream.Free;
    end;
  end
  else
    Result := 0;
end;

function acTextFromHGLOBAL(AGlobal: HGLOBAL; ALines: TACLStringList; AUnicode: Boolean = False): Boolean;
begin
  ALines.Text := acTextFromHGLOBAL(AGlobal, AUnicode);
  Result := ALines.Count > 0;
end;

function acTextFromHGLOBAL(AGlobal: HGLOBAL; AUnicode: Boolean = False): UnicodeString;
var
  APtr: Pointer;
begin
  APtr := GlobalLock(AGlobal);
  try
    if AUnicode then
      Result := PWideChar(APtr)
    else
      Result := acStringFromAnsi(PAnsiChar(APtr));
  finally
    GlobalUnlock(AGlobal);
  end;
end;

function acTextToHGLOBAL(const S: UnicodeString): HGLOBAL;
begin
  Result := GlobalAllocFromData(@S[1], (Length(S) + 1) * SizeOf(WideChar));
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

initialization
  OleInitialize(nil);
  CF_CONFIG := RegisterClipboardFormat('ACL.CFG');
  CF_FILEURIS := RegisterClipboardFormat('ACL.FileURIs');

finalization
  OleUninitialize;
end.
