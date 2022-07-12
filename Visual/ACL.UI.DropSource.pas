{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*           DropSource Component            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.DropSource;

{$I ACL.Config.INC}

interface

uses
  Windows, ActiveX, Classes, ComObj, ShlObj, Generics.Collections,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.Math,
  ACL.ObjectLinks,
  ACL.Threading,
  ACL.Utils.Clipboard,
  ACL.Utils.Common,
  ACL.Utils.Desktop,
  ACL.Utils.FileSystem,
  ACL.Utils.Shell,
  ACL.Utils.Stream,
  ACL.Utils.Strings;

type
  TACLDropSourceAction = (dsaCopy, dsaMove, dsaLink);
  TACLDropSourceActions = set of TACLDropSourceAction;

  { IACLDropSourceOperation }

  IACLDropSourceOperation = interface
  ['{F8DF8282-CEEA-45A4-BD28-6036B3747D5F}']
    procedure DropSourceBegin;
    procedure DropSourceDrop(var AAllowDrop: Boolean);
    procedure DropSourceEnd(AActions: TACLDropSourceActions; AShiftState: TShiftState);
  end;

  { IACLDropSourceDataProviderFiles }

  IACLDropSourceDataProviderFiles = interface
  ['{7EA0E947-D689-432B-B82A-1626D7BA24B4}']
    procedure DropSourceGetFiles(Files: TACLStringList; Config: TACLIniFile);
  end;

  { IACLDropSourceDataProviderFilesAsStreams }

  IACLDropSourceDataProviderFilesAsStreams = interface(IACLDropSourceDataProviderFiles)
  ['{76453619-F799-43D4-AA93-D106CD4BD563}']
    function DropSourceCreateStream(FileIndex: Integer; const FileName: UnicodeString): TStream;
  end;

  { IACLDropSourceData }

  IACLDropSourceData = interface
  ['{D7CD9F0E-5726-438B-B200-150D524FE842}']
    procedure Initialize(Config: TACLIniFile);
  end;

  { IACLDropSourceDataFiles }

  IACLDropSourceDataFiles = interface(IACLDropSourceData)
  ['{A39F822A-3659-4B6E-95BD-545DC3A68B8B}']
    function GetCount: Integer;
    function GetName(Index: Integer): string;
    function GetStream(Index: Integer): TStream;

    property Count: Integer read GetCount;
    property Names[Index: Integer]: string read GetName;
    property Streams[Index: Integer]: TStream read GetStream;
  end;

  { TACLDropSourceData }

  TACLDropSourceData = class abstract(TInterfacedObject, IACLDropSourceData)
  strict private
    FConfig: TACLIniFile;
    FDataFetched: Boolean;
  protected
    procedure CheckData;
    procedure FetchData; virtual; abstract;
    // IACLDropSourceData
    procedure Initialize(AConfig: TACLIniFile);
  public
    constructor Create;
    destructor Destroy; override;
    //
    property Config: TACLIniFile read FConfig;
  end;

  { TACLDropSourceDataFiles }

  TACLDropSourceDataFiles = class(TACLDropSourceData, IACLDropSourceDataFiles)
  strict private
    FList: TACLStringList;
    FProvider: IACLDropSourceDataProviderFiles;

    procedure ReleaseStreams;
  protected
    function CreateStream(AIndex: Integer): TStream; virtual;
    procedure FetchData; override;

    // IACLDropSourceDataFiles
    function GetCount: Integer;
    function GetName(Index: Integer): string;
    function GetStream(Index: Integer): TStream;
  public
    constructor Create; overload;
    constructor Create(const AFileName: UnicodeString); overload;
    constructor Create(const AFiles: TACLStringList); overload;
    constructor Create(const AProvider: IACLDropSourceDataProviderFiles); overload;
    destructor Destroy; override;
    //
    property List: TACLStringList read FList;
    property Provider: IACLDropSourceDataProviderFiles read FProvider;
  end;

  { TACLDragDropDataProvider }

  TACLDragDropDataProvider = class abstract
  public
    function GetFormat: TFormatEtc; virtual; abstract;
    function HasData: Boolean; virtual; abstract;
    function IsSupported(const AFormat: TFormatEtc): Boolean; virtual;
    function Store(var AMedium: TStgMedium; const AFormat: TFormatEtc; ATargetConfig: TACLIniFile = nil): Boolean; virtual; abstract;
  end;

  { TACLDragDropDataProviderConfig }

  TACLDragDropDataProviderConfig = class(TACLDragDropDataProvider)
  strict private
    FConfig: TACLIniFile;
  public
    constructor Create; overload;
    constructor Create(AConfig: TACLIniFile); overload;
    destructor Destroy; override;
    function GetFormat: TFormatEtc; override;
    function HasData: Boolean; override;
    function Store(var AMedium: TStgMedium; const AFormat: TFormatEtc; ATargetConfig: TACLIniFile = nil): Boolean; override;
    //
    property Config: TACLIniFile read FConfig;
  end;

  { TACLDragDropDataProviderFiles }

  TACLDragDropDataProviderFiles = class(TACLDragDropDataProvider)
  strict private
    FData: IACLDropSourceDataFiles;
  protected
    function FilesToHGLOBAL(AFiles: TACLStringList): HGLOBAL; virtual;
  public
    constructor Create(AData: IACLDropSourceDataFiles);
    function GetFormat: TFormatEtc; override;
    function HasData: Boolean; override;
    function Store(var AMedium: TStgMedium; const AFormat: TFormatEtc; ATargetConfig: TACLIniFile = nil): Boolean; override;
    //
    property Data: IACLDropSourceDataFiles read FData;
  end;

  { TACLDragDropDataProviderFileStream }

  TACLDragDropDataProviderFileStream = class(TACLDragDropDataProviderFiles)
  strict private
    FIndex: Integer;
  public
    constructor Create(AData: IACLDropSourceDataFiles; AIndex: Integer);
    function GetFormat: TFormatEtc; override;
    function IsSupported(const AFormat: TFormatEtc): Boolean; override;
    function Store(var AMedium: TStgMedium; const AFormat: TFormatEtc; ATargetConfig: TACLIniFile = nil): Boolean; override;
  end;

  { TACLDragDropDataProviderFileStreamDescriptor }

  TACLDragDropDataProviderFileStreamDescriptor = class(TACLDragDropDataProviderFiles)
  public
    function GetFormat: TFormatEtc; override;
    function Store(var AMedium: TStgMedium; const AFormat: TFormatEtc; ATargetConfig: TACLIniFile = nil): Boolean; override;
  end;

  { TACLDragDropDataProviderFileURIs }

  TACLDragDropDataProviderFileURIs = class(TACLDragDropDataProviderFiles)
  public
    function GetFormat: TFormatEtc; override;
  end;

  { TACLDragDropDataProviderPIDL }

  TACLDragDropDataProviderPIDL = class(TACLDragDropDataProviderFiles)
  protected
    function FilesToHGLOBAL(AFiles: TACLStringList): HGLOBAL; override;
  public
    function GetFormat: TFormatEtc; override;
  end;

  { TACLDragDropDataProviderText }

  TACLDragDropDataProviderText = class(TACLDragDropDataProvider)
  strict private
    FText: string;
  public
    constructor Create(const AText: string);
    function GetFormat: TFormatEtc; override;
    function HasData: Boolean; override;
    function Store(var AMedium: TStgMedium; const AFormat: TFormatEtc; ATargetConfig: TACLIniFile = nil): Boolean; override;
    //
    property Text: string read FText;
  end;

  { TACLDragDropDataProviderTextAnsi }

  TACLDragDropDataProviderTextAnsi = class(TACLDragDropDataProviderText)
  public
    function GetFormat: TFormatEtc; override;
    function Store(var AMedium: TStgMedium; const AFormat: TFormatEtc; ATargetConfig: TACLIniFile = nil): Boolean; override;
  end;

  { TACLDropSource }

  TACLDropSource = class(TACLUnknownObject,
    IDropSource,
    IDataObject)
  strict private
    FAllowedActions: TACLDropSourceActions;
    FDataProviders: TACLObjectList<TACLDragDropDataProvider>;
    FDropResult: TACLDropSourceActions;
    FOwner: IUnknown;
    FShiftStateAtDrop: TShiftState;
    FTargetConfig: TACLIniFile;
    FThreadAttached: THandle;
    FThreadCurrent: THandle;

    function GetAttachThreadId: THandle;
    function GetAttachWindow: THandle;
    procedure AttachThread;
    procedure DetachThread;
  protected
    // IDataObject
    function DAdvise(const AFormat: TFormatEtc; advf: Longint; const advSink: IAdviseSink; out dwConnection: Longint): HRESULT; stdcall;
    function DUnadvise(AConnection: Longint): HRESULT; stdcall;
    function EnumDAdvise(out AEnumAdvise: IEnumStatData): HRESULT; stdcall;
    function EnumFormatEtc(ADirection: Longint; out AEnumFormat: IEnumFormatEtc): HRESULT; stdcall;
    function GetCanonicalFormatEtc(const AFormat: TFormatEtc; out AFormatOut: TFormatEtc): HRESULT; stdcall;
    function GetData(const AFormat: TFormatEtc; out AMedium: TStgMedium): HRESULT; stdcall;
    function GetDataHere(const AFormat: TFormatEtc; out AMedium: TStgMedium): HRESULT; stdcall;
    function QueryGetData(const AFormat: TFormatEtc): HRESULT; stdcall;
    function SetData(const Format: TFormatEtc; var Medium: TStgMedium; Release: BOOL): HRESULT; stdcall;
    // IDropSource
    function GiveFeedback(AEffect: LongInt): HRESULT; stdcall;
    function QueryContinueDrag(AEscapePressed: LongBool; AKeyState: LongInt): HRESULT; stdcall;
    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; override; stdcall;
    //
    procedure DoDrop(var AAllowDrop: Boolean);
    procedure DoDropFinish;
    procedure DoDropStart;
  public
    constructor Create(AOwner: IUnknown);
    destructor Destroy; override;
    function Execute: Boolean;
    procedure ExecuteInThread;
    //
    property AllowedActions: TACLDropSourceActions read FAllowedActions write FAllowedActions;
    property DataProviders: TACLObjectList<TACLDragDropDataProvider> read FDataProviders;
    property Owner: IUnknown read FOwner;
  end;

  { TACLDropSourceOwnerProxy }

  TACLDropSourceOwnerProxy = class(TACLInterfacedObject)
  protected
    FOwner: TObject;

    function QueryInterface(const IID: TGUID; out Obj): HRESULT; override; stdcall;
  public
    constructor Create(AOwner: TObject);
    destructor Destroy; override;
  end;

const
  DropSourceDefaultActions = [dsaCopy, dsaMove, dsaLink];

function DropSourceIsActive: Boolean;
implementation

uses
  Math, SysUtils, Forms;

type

  { TACLDropFormatEtcList }

  TACLDropFormatEtcList = class(TInterfacedObject, IEnumFormatEtc)
  strict private
    FCursor: Integer;
    FList: TACLList<TFormatEtc>;

    function GetFormat(Index: Integer): TFormatEtc;
    function GetFormatCount: Integer;
  protected
    // IEnumFormatEtc
    function Clone(out AEnum: IEnumFormatEtc): HRESULT; stdcall;
    function Next(ACount: Longint; out AList; AFetched: PLongint): HRESULT; stdcall;
    function Reset: HRESULT; stdcall;
    function Skip(ACount: Longint) : HRESULT; stdcall;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AFormat: TFormatEtc);
    procedure Assign(ASource: TACLDropFormatEtcList);
    //
    property Cursor: Integer read FCursor;
    property Format[Index: Integer]: TFormatEtc read GetFormat;
    property FormatCount: Integer read GetFormatCount;
  end;

  { TACLDropSourceThread }

  TACLDropSourceThread = class(TACLThread)
  strict private
    FDropSource: TACLDropSource;
  protected
    procedure Execute; override;
  public
    constructor Create(ADropSource: TACLDropSource);
    destructor Destroy; override;
  end;

const
  ResultMap: array[Boolean] of Integer = (S_FALSE, S_OK);

var
  FDropSourceActiveCount: Integer = 0;

function EncodeActions(AActions: TACLDropSourceActions): Cardinal;
begin
  Result := 0;
  if dsaCopy in AActions then
    Result := Result or DROPEFFECT_COPY;
  if dsaMove in AActions then
    Result := Result or DROPEFFECT_MOVE;
  if dsaLink in AActions then
    Result := Result or DROPEFFECT_LINK;
end;

function DropSourceIsActive: Boolean;
begin
  Result := FDropSourceActiveCount > 0;
end;

{ TACLDropSourceData }

constructor TACLDropSourceData.Create;
begin
  inherited Create;
  FConfig := TACLIniFile.Create;
end;

destructor TACLDropSourceData.Destroy;
begin
  FreeAndNil(FConfig);
  inherited Destroy;
end;

procedure TACLDropSourceData.CheckData;
begin
  if not FDataFetched then
  begin
    FDataFetched := True;
    FetchData;
  end;
end;

procedure TACLDropSourceData.Initialize(AConfig: TACLIniFile);
begin
  if not Config.Equals(AConfig) then
    FDataFetched := False;
end;

{ TACLDropSourceDataFiles }

constructor TACLDropSourceDataFiles.Create;
begin
  inherited Create;
  FList := TACLStringList.Create;
end;

constructor TACLDropSourceDataFiles.Create(const AFileName: UnicodeString);
begin
  Create;
  FList.Capacity := 1;
  FList.Add(AFileName);
end;

constructor TACLDropSourceDataFiles.Create(const AFiles: TACLStringList);
begin
  Create;
  FList.Assign(AFiles);
end;

constructor TACLDropSourceDataFiles.Create(const AProvider: IACLDropSourceDataProviderFiles);
begin
  Create;
  FProvider := AProvider;
end;

destructor TACLDropSourceDataFiles.Destroy;
begin
  ReleaseStreams;
  FreeAndNil(FList);
  inherited Destroy;
end;

function TACLDropSourceDataFiles.CreateStream(AIndex: Integer): TStream;
var
  AProvider: IACLDropSourceDataProviderFilesAsStreams;
begin
  if Supports(FProvider, IACLDropSourceDataProviderFilesAsStreams, AProvider) then
    Result := AProvider.DropSourceCreateStream(AIndex, List[AIndex])
  else
    Result := nil;
end;

procedure TACLDropSourceDataFiles.FetchData;
begin
  ReleaseStreams;
  if FProvider <> nil then
  begin
    FList.Clear;
    FProvider.DropSourceGetFiles(FList, Config);
  end;
end;

function TACLDropSourceDataFiles.GetCount: Integer;
begin
  CheckData;
  Result := FList.Count;
end;

function TACLDropSourceDataFiles.GetName(Index: Integer): string;
begin
  CheckData;
  Result := FList[Index];
end;

function TACLDropSourceDataFiles.GetStream(Index: Integer): TStream;
begin
  CheckData;
  Result := TStream(FList.Objects[Index]);
  if Result = nil then
  begin
    Result := CreateStream(Index);
    if Result = nil then
      Result := TMemoryStream.Create;
    FList.Objects[Index] := Result;
  end;
end;

procedure TACLDropSourceDataFiles.ReleaseStreams;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
  begin
    FList.Objects[I].Free;
    FList.Objects[I] := nil;
  end;
end;

{ TACLDragDropDataProvider }

function TACLDragDropDataProvider.IsSupported(const AFormat: TFormatEtc): Boolean;
var
  AMyFormat: TFormatEtc;
begin
  AMyFormat := GetFormat;
  Result := (AFormat.cfFormat = AMyFormat.cfFormat) and (AFormat.tymed and AMyFormat.tymed = AMyFormat.tymed);
end;

{ TACLDragDropDataProviderConfig }

constructor TACLDragDropDataProviderConfig.Create;
begin
  inherited Create;
  FConfig := TACLIniFile.Create;
end;

constructor TACLDragDropDataProviderConfig.Create(AConfig: TACLIniFile);
begin
  Create;
  Config.Assign(AConfig);
end;

destructor TACLDragDropDataProviderConfig.Destroy;
begin
  FreeAndNil(FConfig);
  inherited Destroy;
end;

function TACLDragDropDataProviderConfig.GetFormat: TFormatEtc;
begin
  Result := MakeFormat(CF_CONFIG);
end;

function TACLDragDropDataProviderConfig.HasData: Boolean;
begin
  Result := True;
end;

function TACLDragDropDataProviderConfig.Store(var AMedium: TStgMedium;
  const AFormat: TFormatEtc; ATargetConfig: TACLIniFile = nil): Boolean;
begin
  AMedium.tymed := TYMED_HGLOBAL;
  AMedium.hGlobal := acConfigToHGLOBAL(Config);
  Result := True;
end;

{ TACLDragDropDataProviderFiles }

constructor TACLDragDropDataProviderFiles.Create(AData: IACLDropSourceDataFiles);
begin
  inherited Create;
  FData := AData;
end;

function TACLDragDropDataProviderFiles.GetFormat: TFormatEtc;
begin
  Result := MakeFormat(CF_HDROP);
end;

function TACLDragDropDataProviderFiles.HasData: Boolean;
begin
  Result := True;
end;

function TACLDragDropDataProviderFiles.Store(var AMedium: TStgMedium;
  const AFormat: TFormatEtc; ATargetConfig: TACLIniFile = nil): Boolean;
var
  AFiles: TACLStringList;
  I: Integer;
begin
  Result := False;
  Data.Initialize(ATargetConfig);

  AFiles := TACLStringList.Create;
  try
    AFiles.Capacity := FData.Count;
    for I := 0 to Data.Count - 1 do
      AFiles.Add(Data.Names[I]);
    if AFiles.Count > 0 then
    begin
      AMedium.tymed := TYMED_HGLOBAL;
      AMedium.hGlobal := FilesToHGLOBAL(AFiles);
      Result := AMedium.hGlobal <> 0;
    end;
  finally
    AFiles.Free;
  end;
end;

function TACLDragDropDataProviderFiles.FilesToHGLOBAL(AFiles: TACLStringList): HGLOBAL;
begin
  Result := acMakeDropHandle(AFiles);
end;

{ TACLDragDropDataProviderPIDL }

function TACLDragDropDataProviderPIDL.FilesToHGLOBAL(AFiles: TACLStringList): HGLOBAL;
var
  AStream: TMemoryStream;
begin
  Result := 0;
  if TPIDLHelper.FilesToShellListStream(AFiles, AStream) then
  try
    Result := GlobalAllocFromData(AStream.Memory, AStream.Size);
  finally
    AStream.Free;
  end;
end;

function TACLDragDropDataProviderPIDL.GetFormat: TFormatEtc;
begin
  Result := MakeFormat(CF_SHELLIDList);
end;

{ TACLDragDropDataProviderText }

constructor TACLDragDropDataProviderText.Create(const AText: string);
begin
  inherited Create;
  FText := AText;
end;

function TACLDragDropDataProviderText.GetFormat: TFormatEtc;
begin
  Result := MakeFormat(CF_UNICODETEXT);
end;

function TACLDragDropDataProviderText.HasData: Boolean;
begin
  Result := Text <> '';
end;

function TACLDragDropDataProviderText.Store(var AMedium: TStgMedium;
  const AFormat: TFormatEtc; ATargetConfig: TACLIniFile = nil): Boolean;
begin
  AMedium.tymed := TYMED_HGLOBAL;
  AMedium.hGlobal := acTextToHGLOBAL(Text);
  Result := True;
end;

{ TACLDragDropDataProviderFileStream }

constructor TACLDragDropDataProviderFileStream.Create(AData: IACLDropSourceDataFiles; AIndex: Integer);
begin
  inherited Create(AData);
  FIndex := AIndex;
end;

function TACLDragDropDataProviderFileStream.GetFormat: TFormatEtc;
begin
  Result := MakeFormat(RegisterClipboardFormat(CFSTR_FILECONTENTS));
  Result.tymed := TYMED_ISTREAM;
  Result.lindex := FIndex;
end;

function TACLDragDropDataProviderFileStream.IsSupported(const AFormat: TFormatEtc): Boolean;
begin
  Result := (AFormat.cfFormat = GetFormat.cfFormat) and (AFormat.tymed and TYMED_ISTREAM <> 0) and (AFormat.lindex = FIndex);
end;

function TACLDragDropDataProviderFileStream.Store(var AMedium: TStgMedium;
  const AFormat: TFormatEtc; ATargetConfig: TACLIniFile = nil): Boolean;
begin
  Result := (AFormat.tymed and TYMED_ISTREAM <> 0) and (Data.Count > 0);
  if Result then
  begin
    AMedium.tymed := TYMED_ISTREAM;
    IStream(AMedium.stm) := TStreamAdapter.Create(Data.Streams[FIndex]);
  end;
end;

{ TACLDragDropDataProviderFileStreamDescriptor }

function TACLDragDropDataProviderFileStreamDescriptor.GetFormat: TFormatEtc;
begin
  Result := MakeFormat(RegisterClipboardFormat(CFSTR_FILEDESCRIPTORW));
end;

function TACLDragDropDataProviderFileStreamDescriptor.Store(
  var AMedium: TStgMedium; const AFormat: TFormatEtc; ATargetConfig: TACLIniFile = nil): Boolean;
var
  ADescriptor: PFileGroupDescriptorW;
  ADescriptorSize: Integer;
  AFileDescriptor: PFileDescriptorW;
  AFileSize: Int64;
  I: Integer;
begin
  ADescriptorSize := SizeOf(TFileGroupDescriptorW) + (Data.Count - 1) * SizeOf(TFileDescriptorW);
  ADescriptor := AllocMem(ADescriptorSize);
  try
    ADescriptor.cItems := Data.Count;
    for I := 0 to Data.Count - 1 do
    begin
      AFileDescriptor := @ADescriptor.fgd[I];
      StrLCopy(@AFileDescriptor.cFileName[0], PChar(acExtractFileName(Data.Names[I])), MAX_PATH);
      AFileSize := Data.Streams[I].Size;
      AFileDescriptor.dwFlags := FD_PROGRESSUI or FD_FILESIZE;
      AFileDescriptor.nFileSizeHigh := HiInteger(AFileSize);
      AFileDescriptor.nFileSizeLow := LoInteger(AFileSize);
    end;
    AMedium.tymed := TYMED_HGLOBAL;
    AMedium.hGlobal := GlobalAllocFromData(PByte(ADescriptor), ADescriptorSize);
    Result := True;
  finally
    FreeMem(ADescriptor);
  end;
end;

{ TACLDragDropDataProviderFileURIs }

function TACLDragDropDataProviderFileURIs.GetFormat: TFormatEtc;
begin
  Result := MakeFormat(CF_FILEURIS);
end;

{ TACLDragDropDataProviderTextAnsi }

function TACLDragDropDataProviderTextAnsi.GetFormat: TFormatEtc;
begin
  Result := MakeFormat(CF_TEXT);
end;

function TACLDragDropDataProviderTextAnsi.Store(var AMedium: TStgMedium;
  const AFormat: TFormatEtc; ATargetConfig: TACLIniFile): Boolean;
begin
  AMedium.tymed := TYMED_HGLOBAL;
  AMedium.hGlobal := acTextToHGLOBAL(acAnsiFromUnicode(Text));
  Result := True;
end;

{ TACLDropSource }

constructor TACLDropSource.Create(AOwner: IUnknown);
begin
  inherited Create;
  FOwner := AOwner;
  FAllowedActions := DropSourceDefaultActions;
  FDataProviders := TACLObjectList<TACLDragDropDataProvider>.Create;
end;

destructor TACLDropSource.Destroy;
begin
  FOwner := nil;
  FreeAndNil(FDataProviders);
  inherited Destroy;
end;

procedure TACLDropSource.AttachThread;
begin
  FThreadAttached := GetAttachThreadId;
  FThreadCurrent := GetCurrentThreadId;
  if FThreadAttached <> FThreadCurrent then
    AttachThreadInput(FThreadAttached, FThreadCurrent, True);
end;

procedure TACLDropSource.DetachThread;
begin
  if (FThreadAttached <> 0) and (FThreadAttached <> FThreadCurrent) then
  begin
    AttachThreadInput(FThreadAttached, FThreadCurrent, False);
    FThreadAttached := 0;
  end;
end;

function TACLDropSource.Execute: Boolean;
var
  AEffect: Integer;
begin
  InterlockedIncrement(FDropSourceActiveCount);
  try
    RunInMainThread(DoDropStart);
    try
      AttachThread;
      try
        OleInitialize(nil);
        try
          FDropResult := [];
          if DoDragDrop(Self, Self, EncodeActions(AllowedActions), AEffect) = DRAGDROP_S_DROP then
          begin
            if AEffect and DROPEFFECT_COPY <> 0 then
              Include(FDropResult, dsaCopy);
            if AEffect and DROPEFFECT_MOVE <> 0 then
              Include(FDropResult, dsaMove);
            if AEffect and DROPEFFECT_LINK <> 0 then
              Include(FDropResult, dsaLink);
          end;
          Result := FDropResult <> [];
        finally
          OleUninitialize;
        end;
      finally
        DetachThread;
      end;
    finally
      RunInMainThread(DoDropFinish);
    end;
  finally
    InterlockedDecrement(FDropSourceActiveCount);
  end;
end;

procedure TACLDropSource.ExecuteInThread;
begin
  TACLDropSourceThread.Create(Self);
end;

procedure TACLDropSource.DoDrop(var AAllowDrop: Boolean);
var
  AOperation: IACLDropSourceOperation;
begin
  FShiftStateAtDrop := acGetShiftState;
  if Supports(Owner, IACLDropSourceOperation, AOperation) then
  try
    AOperation.DropSourceDrop(AAllowDrop);
  finally
    AOperation := nil;
  end;
end;

procedure TACLDropSource.DoDropFinish;
var
  AOperation: IACLDropSourceOperation;
begin
  if Supports(Owner, IACLDropSourceOperation, AOperation) then
    AOperation.DropSourceEnd(FDropResult, FShiftStateAtDrop);
  FreeAndNil(FTargetConfig);
end;

procedure TACLDropSource.DoDropStart;
var
  AOperation: IACLDropSourceOperation;
begin
  FTargetConfig := TACLIniFile.Create;
  if Supports(Owner, IACLDropSourceOperation, AOperation) then
    AOperation.DropSourceBegin;
end;

function TACLDropSource.GiveFeedback(AEffect: LongInt): HRESULT; stdcall;
begin
  Result := DRAGDROP_S_USEDEFAULTCURSORS;
end;

function TACLDropSource.QueryContinueDrag(AEscapePressed: LongBool; AKeyState: LongInt): HRESULT; stdcall;
const
  ResultFlags: array[Boolean] of Integer = (DRAGDROP_S_CANCEL, DRAGDROP_S_DROP);
var
  AAllowDrop: Boolean;
begin
  if AEscapePressed or (Owner is TACLDropSourceOwnerProxy) and (TACLDropSourceOwnerProxy(Owner).FOwner = nil) then
    Result := DRAGDROP_S_CANCEL
  else
    if (AKeyState and MK_LBUTTON = 0) and (AKeyState and MK_RBUTTON = 0) then
    begin
      AAllowDrop := True;
      // if we move files from one control of our application to other and if OnDrop event handler
      // will show the Modal Dialog - application will hangs (on WinXP) because of attached input
      // So, we must detach thread input
      DetachThread;
      DoDrop(AAllowDrop);
      Result := ResultFlags[AAllowDrop];
    end
    else
      Result := S_OK;
end;

function TACLDropSource.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  Result := inherited QueryInterface(IID, Obj);
  if Assigned(Owner) and (Result <> S_OK) then
    Result := Owner.QueryInterface(IID, Obj);
end;

function TACLDropSource.DAdvise(const AFormat: TFormatEtc; advf: Longint;
  const advSink: IAdviseSink; out dwConnection: Longint): HRESULT; stdcall;
begin
  Result := OLE_E_ADVISENOTSUPPORTED;
end;

function TACLDropSource.DUnadvise(AConnection: Longint):HRESULT; stdcall;
begin
  Result := OLE_E_ADVISENOTSUPPORTED;
end;

function TACLDropSource.EnumDAdvise(out AEnumAdvise: IEnumStatData): HRESULT; stdcall;
begin
  Result := OLE_E_ADVISENOTSUPPORTED;
end;

function TACLDropSource.EnumFormatEtc(ADirection: Longint; out AEnumFormat: IEnumFormatEtc): HRESULT; stdcall;
const
  ResultMap: array[Boolean] of HRESULT = (E_NOTIMPL, S_OK);
var
  ADataProvider: TACLDragDropDataProvider;
  AFormatEtcList: TACLDropFormatEtcList;
  I: Integer;
begin
  AEnumFormat := nil;
  if ADirection = DATADIR_GET then
  begin
    AFormatEtcList := TACLDropFormatEtcList.Create;
    for I := 0 to DataProviders.Count - 1 do
    begin
      ADataProvider := DataProviders[I];
      if ADataProvider.HasData then
        AFormatEtcList.Add(ADataProvider.GetFormat);
    end;
    if AFormatEtcList.FormatCount > 0 then
      AEnumFormat := AFormatEtcList;
  end;
  Result := ResultMap[AEnumFormat <> nil];
end;

function TACLDropSource.GetCanonicalFormatEtc(const AFormat: TFormatEtc; out AFormatOut: TFormatEtc): HRESULT; stdcall;
begin
  AFormatOut.ptd := nil;
  Result := E_NOTIMPL;
end;

function TACLDropSource.QueryGetData(const AFormat: TFormatEtc): HRESULT; stdcall;
var
  ADataProvider: TACLDragDropDataProvider;
  I: Integer;
begin
  Result := DV_E_FORMATETC;
  if AFormat.dwAspect = DVASPECT_CONTENT then
  begin
    for I := 0 to DataProviders.Count - 1 do
    begin
      ADataProvider := DataProviders[I];
      if ADataProvider.IsSupported(AFormat) and ADataProvider.HasData then
        Exit(S_OK);
    end;
  end;
end;

function TACLDropSource.GetAttachThreadId: THandle;
var
  AAttach: THandle;
begin
  AAttach := GetAttachWindow;
  if AAttach <> 0 then
    Result := GetWindowThreadProcessId(AAttach, nil)
  else
    Result := MainThreadID;
end;

function TACLDropSource.GetAttachWindow: THandle;
begin
  Result := GetForegroundWindow;
  // Fallback to the unsafe method in case GetForegroundWindow didn't work
  // out (from MSDN: The foreground window can be NULL in certain
  // circumstances, such as when a window is losing activation).
  if Result = 0 then
  begin
    // Get handle of window under mouse-cursor.
    // Warning: This introduces a race condition. The cursor might have moved
    // from the original drop source window to another window. This can happen
    // easily if the user moves the cursor rapidly or if sufficient time has
    // elapsed since DragDetect exited.
    Result := MouseCurrentWindow;
  end;
end;

function TACLDropSource.GetData(const AFormat: TFormatEtc; out AMedium: TStgMedium): HRESULT; stdcall;
var
  ADataProvider: TACLDragDropDataProvider;
  I: Integer;
begin
  Result := DV_E_FORMATETC;
  ZeroMemory(@AMedium, SizeOf(AMedium));
  for I := 0 to DataProviders.Count - 1 do
  begin
    ADataProvider := DataProviders[I];
    if ADataProvider.IsSupported(AFormat) and ADataProvider.HasData then
    begin
      if ADataProvider.Store(AMedium, AFormat, FTargetConfig) then
        Exit(S_OK);
    end;
  end;
end;

function TACLDropSource.GetDataHere(const AFormat: TFormatEtc; out AMedium: TStgMedium): HRESULT; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TACLDropSource.SetData(const Format: TFormatEtc; var Medium: TStgMedium; Release: BOOL): HRESULT; stdcall;
begin
  Result := E_NOTIMPL;
  try
    if (Format.tymed = TYMED_HGLOBAL) and (Format.cfFormat = CF_CONFIG) then
    begin
      acConfigFromHGLOBAL(Medium.hGlobal, FTargetConfig);
      Result := S_OK;
    end;
  finally
    if Release then
      ReleaseStgMedium(Medium);
  end;
end;

{ TACLDropFormatEtcList }

constructor TACLDropFormatEtcList.Create;
begin
  inherited Create;
  FList := TACLList<TFormatEtc>.Create;
end;

destructor TACLDropFormatEtcList.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TACLDropFormatEtcList.Add(const AFormat: TFormatEtc);
begin
  FList.Add(AFormat);
end;

procedure TACLDropFormatEtcList.Assign(ASource: TACLDropFormatEtcList);
var
  I: Integer;
begin
  FList.Clear;
  FCursor := ASource.Cursor;
  for I := 0 to ASource.FormatCount - 1 do
    Add(ASource.Format[I]);
end;

function TACLDropFormatEtcList.Next(ACount: Longint; out AList; AFetched: PLongint): HRESULT;
var
  AFormatList: PFormatEtc;
  AIndex: Integer;
begin
  AFormatList := @AList;

  AIndex := 0;
  while (AIndex < ACount) and (Cursor < FormatCount) do
  begin
    AFormatList^ := Format[Cursor];
    Inc(AFormatList);
    Inc(FCursor);
    Inc(AIndex);
  end;
  if Assigned(AFetched) then
    AFetched^ := AIndex;
  Result := ResultMap[AIndex = ACount];
end;

function TACLDropFormatEtcList.Skip(ACount: Longint): HRESULT;
begin
  Result := ResultMap[Cursor + ACount <= FormatCount];
  FCursor := Min(FormatCount, Cursor + ACount);
end;

function TACLDropFormatEtcList.Reset: HRESULT;
begin
  FCursor := 0;
  Result := S_OK;
end;

function TACLDropFormatEtcList.Clone(out AEnum: IEnumFormatEtc): HRESULT;
var
  AFormatEtc: TACLDropFormatEtcList;
begin
  AFormatEtc := TACLDropFormatEtcList.Create;
  AFormatEtc.Assign(Self);
  AEnum := AFormatEtc;
  Result := S_OK;
end;

function TACLDropFormatEtcList.GetFormat(Index: Integer): TFormatEtc;
begin
  Result := FList[Index];
end;

function TACLDropFormatEtcList.GetFormatCount: Integer;
begin
  Result := FList.Count;
end;

{ TACLDropSourceThread }

constructor TACLDropSourceThread.Create(ADropSource: TACLDropSource);
begin
  inherited Create;
  FDropSource := ADropSource;
  FreeOnTerminate := True;
end;

destructor TACLDropSourceThread.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FDropSource);
end;

procedure TACLDropSourceThread.Execute;
begin
  try
    FDropSource.Execute;
  except
    Terminate;
  end;
end;

{ TACLDropSourceOwnerProxy }

constructor TACLDropSourceOwnerProxy.Create(AOwner: TObject);
begin
  inherited Create;
  TACLObjectLinks.RegisterWeakReference(AOwner, @FOwner);
end;

destructor TACLDropSourceOwnerProxy.Destroy;
begin
  TACLObjectLinks.UnregisterWeakReference(@FOwner);
  inherited Destroy;
end;

function TACLDropSourceOwnerProxy.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  if GetInterface(IID, Obj) or Supports(FOwner, IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

end.
