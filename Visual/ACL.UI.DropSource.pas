////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Shell drop source
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.DropSource;

{$I ACL.Config.inc}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.ActiveX,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Math,
  {System.}SysUtils,
  // VCL
  {Vcl.}Controls,
  {Vcl.}ClipBrd,
  {Vcl.}Forms,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.Math,
  ACL.ObjectLinks,
  ACL.UI.Controls.Base,
  ACL.Threading,
  ACL.Utils.Clipboard,
  ACL.Utils.Common,
  ACL.Utils.Desktop,
  ACL.Utils.FileSystem,
  ACL.Utils.Shell,
  ACL.Utils.Stream,
  ACL.Utils.Strings;

type

{$REGION ' General '}

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
    procedure DropSourceGetFiles(Files: TACLStringList);
  end;

  { IACLDropSourceDataProviderFilesAsStreams }

  IACLDropSourceDataProviderFilesAsStreams = interface(IACLDropSourceDataProviderFiles)
  ['{76453619-F799-43D4-AA93-D106CD4BD563}']
    function DropSourceCreateStream(FileIndex: Integer; const FileName: string): TStream;
  end;

  { IACLDropSourceDataFiles }

  IACLDropSourceDataFiles = interface
  ['{A39F822A-3659-4B6E-95BD-545DC3A68B8B}']
    function GetCount: Integer;
    function GetName(Index: Integer): string;
    function GetStream(Index: Integer): TStream;

    property Count: Integer read GetCount;
    property Names[Index: Integer]: string read GetName;
    property Streams[Index: Integer]: TStream read GetStream;
  end;

  { TACLDropSourceData }

  TACLDropSourceData = class abstract(TInterfacedObject)
  strict private
    FDataFetched: Boolean;
  protected
    procedure CheckData;
    procedure FetchData; virtual; abstract;
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
    constructor Create(const AFileName: string); overload;
    constructor Create(const AFiles: TACLStringList); overload;
    constructor Create(const AProvider: IACLDropSourceDataProviderFiles); overload;
    destructor Destroy; override;
    //# Properties
    property List: TACLStringList read FList;
    property Provider: IACLDropSourceDataProviderFiles read FProvider;
  end;

  { TACLDragDropDataProvider }

  TACLDragDropDataProvider = class abstract
  public
    function GetFormat: TFormatEtc; virtual; abstract;
    function HasData: Boolean; virtual; abstract;
    function IsSupported(const AFormat: TFormatEtc): Boolean; virtual;
    function Store(out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean; virtual; abstract;
  end;

  { TACLDragDropDataProviders }

  TACLDragDropDataProviders = class(TACLObjectList<TACLDragDropDataProvider>);

  { TACLDropSource }

  TACLDropSource = class(TACLComponent)
  strict private
    FAllowedActions: TACLDropSourceActions;
    FDataProviders: TACLDragDropDataProviders;
    FControl: TWinControl;
    FHandler: IACLDropSourceOperation;
    FShiftStateAtDrop: TShiftState;
  protected
    FDropResult: TACLDropSourceActions;

    constructor CreateCore(AHandler: IACLDropSourceOperation; AControl: TWinControl);
    procedure ExecuteCore; virtual; abstract;
    procedure ExecuteSafeFree;
    // TComponent
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    // IUnknown
    function QueryInterface({$IFDEF FPC}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HRESULT; override;
    //# Events
    procedure DoDrop(var AAllowDrop: Boolean);
    procedure DoDropFinish;
    procedure DoDropStart;
  public
    class function Create(AHandler: IACLDropSourceOperation;
      AControl: TWinControl): TACLDropSource; reintroduce; static;
    destructor Destroy; override;
    procedure Cancel; virtual;
    function Execute: Boolean;
    // In this case, The DropSource will be automatically freed after execution
    procedure ExecuteInThread;
    //# Properties
    property AllowedActions: TACLDropSourceActions read FAllowedActions write FAllowedActions;
    property DataProviders: TACLDragDropDataProviders read FDataProviders;
    property Control: TWinControl read FControl;
    property Handler: IACLDropSourceOperation read FHandler;
  end;

{$ENDREGION}

{$REGION ' Formats / General '}

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
    function Store(out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean; override;
    //# Properties
    property Config: TACLIniFile read FConfig;
  end;

  { TACLDragDropDataProviderFiles }

  TACLDragDropDataProviderFiles = class(TACLDragDropDataProvider)
  strict private
    FData: IACLDropSourceDataFiles;
  protected
    function StoreFiles(AFiles: TACLStringList; out AMedium: TStgMedium): Boolean; virtual;
  public
    constructor Create(AData: IACLDropSourceDataFiles);
    function GetFormat: TFormatEtc; override;
    function HasData: Boolean; override;
    function Store(out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean; override;
    //# Properties
    property Data: IACLDropSourceDataFiles read FData;
  end;

  { TACLDragDropDataProviderFileURIs }

  TACLDragDropDataProviderFileURIs = class(TACLDragDropDataProviderFiles)
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
    function Store(out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean; override;
    //# Properties
    property Text: string read FText;
  end;

{$ENDREGION}

{$REGION ' Formats / Windows Specific '}
{$IFDEF MSWINDOWS}

  { TACLDragDropDataProviderFileStream }

  TACLDragDropDataProviderFileStream = class(TACLDragDropDataProviderFiles)
  strict private
    FIndex: Integer;
  public
    constructor Create(AData: IACLDropSourceDataFiles; AIndex: Integer);
    function GetFormat: TFormatEtc; override;
    function IsSupported(const AFormat: TFormatEtc): Boolean; override;
    function Store(out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean; override;
  end;

  { TACLDragDropDataProviderFileStreamDescriptor }

  TACLDragDropDataProviderFileStreamDescriptor = class(TACLDragDropDataProviderFiles)
  public
    function GetFormat: TFormatEtc; override;
    function Store(out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean; override;
  end;

  { TACLDragDropDataProviderPIDL }

  TACLDragDropDataProviderPIDL = class(TACLDragDropDataProviderFiles)
  protected
    function StoreFiles(AFiles: TACLStringList; out AMedium: TStgMedium): Boolean; override;
  public
    function GetFormat: TFormatEtc; override;
  end;

{$ENDIF}
{$ENDREGION}

const
  DropSourceDefaultActions = [dsaCopy, dsaMove, dsaLink];

function DropSourceIsActive: Boolean;
implementation

{$IFDEF MSWINDOWS}
uses
  Winapi.ShlObj,
  Winapi.Windows,
  System.Win.ComObj;
{$ENDIF}

var
  FDropSourceActiveCount: Integer = 0;

function DropSourceIsActive: Boolean;
begin
  Result := FDropSourceActiveCount > 0;
end;

{$REGION ' General '}

{ TACLDropSourceData }

procedure TACLDropSourceData.CheckData;
begin
  if not FDataFetched then
  begin
    FDataFetched := True;
    FetchData;
  end;
end;

{ TACLDropSourceDataFiles }

constructor TACLDropSourceDataFiles.Create;
begin
  inherited Create;
  FList := TACLStringList.Create;
end;

constructor TACLDropSourceDataFiles.Create(const AFileName: string);
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
    FProvider.DropSourceGetFiles(FList);
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
  LFormat: TFormatEtc;
begin
  LFormat := GetFormat;
  Result := (AFormat.cfFormat = LFormat.cfFormat)
  {$IFDEF MSWINDOWS}
    and (AFormat.tymed and LFormat.tymed = LFormat.tymed);
  {$ENDIF}
end;

{ TACLDropSource }

constructor TACLDropSource.CreateCore(
  AHandler: IACLDropSourceOperation; AControl: TWinControl);
begin
  inherited Create(nil);
  FHandler := AHandler;
  FControl := AControl;
  FControl.FreeNotification(Self);
  FAllowedActions := DropSourceDefaultActions;
  FDataProviders := TACLDragDropDataProviders.Create;
end;

destructor TACLDropSource.Destroy;
begin
  Cancel;
  FreeAndNil(FDataProviders);
  inherited Destroy;
end;

procedure TACLDropSource.Cancel;
begin
  if FControl <> nil then
  begin
    FControl.RemoveFreeNotification(Self);
    FControl := nil;
  end;
  FHandler := nil;
end;

procedure TACLDropSource.DoDrop(var AAllowDrop: Boolean);
var
  LIntf: IACLDropSourceOperation;
begin
  FShiftStateAtDrop := acGetShiftState;
  if Supports(Handler, IACLDropSourceOperation, LIntf) then
    LIntf.DropSourceDrop(AAllowDrop);
end;

procedure TACLDropSource.DoDropFinish;
begin
  if Handler <> nil then
    Handler.DropSourceEnd(FDropResult, FShiftStateAtDrop);
end;

procedure TACLDropSource.DoDropStart;
begin
  if Handler <> nil then
    Handler.DropSourceBegin;
end;

function TACLDropSource.Execute: Boolean;
begin
  InterlockedIncrement(FDropSourceActiveCount);
  try
    RunInMainThread(DoDropStart);
    try
      FDropResult := [];
      ExecuteCore;
      Result := FDropResult <> [];
    finally
      RunInMainThread(DoDropFinish);
    end;
  finally
    InterlockedDecrement(FDropSourceActiveCount);
  end;
end;

procedure TACLDropSource.ExecuteInThread;
begin
  if IsWine then
    ExecuteSafeFree
  else
    TThread.CreateAnonymousThread(ExecuteSafeFree).Start;
end;

procedure TACLDropSource.ExecuteSafeFree;
begin
  try
    try
      Execute;
    except
      // do nothing
    end;
  finally
    Free;
  end;
end;

procedure TACLDropSource.Notification(
  AComponent: TComponent; AOperation: TOperation);
begin
  if (AOperation = opRemove) and (AComponent = Control) then
    Cancel;
  inherited;
end;

function TACLDropSource.QueryInterface;
begin
  Result := inherited;
  if Assigned(Handler) and (Result <> S_OK) then
    Result := Handler.QueryInterface(IID, Obj);
end;
{$ENDREGION}

{$REGION ' Formats / General '}

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

function TACLDragDropDataProviderConfig.Store(
  out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean;
var
  LStream: TMemoryStream;
begin
  LStream := TMemoryStream.Create;
  try
    Config.SaveToStream(LStream);
    LStream.Position := 0;
    Result := MediumAlloc(LStream.Memory, LStream.Size, AMedium);
  finally
    LStream.Free;
  end;
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
  Result := FData.Count > 0;
end;

function TACLDragDropDataProviderFiles.Store(
  out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean;
var
  LFiles: TACLStringList;
  I: Integer;
begin
  LFiles := TACLStringList.Create;
  try
    LFiles.Capacity := FData.Count;
    for I := 0 to Data.Count - 1 do
      LFiles.Add(Data.Names[I]);
    Result := (LFiles.Count > 0) and StoreFiles(LFiles, AMedium);
  finally
    LFiles.Free;
  end;
end;

function TACLDragDropDataProviderFiles.StoreFiles(
  AFiles: TACLStringList; out AMedium: TStgMedium): Boolean;
{$IFDEF MSWINDOWS}
begin
  AMedium.tymed := TYMED_HGLOBAL;
  AMedium.hGlobal := TACLGlobalMemory.Alloc(AFiles);
  Result := AMedium.hGlobal <> 0;
{$ELSE}
var
  LFiles: string;
begin
  LFiles := Clipboard.EncodeFiles(AFiles);
  Result := MediumAlloc(PChar(LFiles), Length(LFiles), AMedium);
{$ENDIF}
end;

{ TACLDragDropDataProviderFileURIs }

function TACLDragDropDataProviderFileURIs.GetFormat: TFormatEtc;
begin
  Result := MakeFormat(CF_FILEURIS);
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

function TACLDragDropDataProviderText.Store(
  out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean;
begin
  Result := MediumAlloc(PChar(Text), (Length(Text) + 1) * SizeOf(Char), AMedium);
end;

{$ENDREGION}

{$REGION ' Formats / Windows Specific '}
{$IFDEF MSWINDOWS}

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
  Result := (AFormat.cfFormat = GetFormat.cfFormat) and
    (AFormat.tymed and TYMED_ISTREAM <> 0) and (AFormat.lindex = FIndex);
end;

function TACLDragDropDataProviderFileStream.Store(
  out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean;
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
  out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean;
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
    AMedium.hGlobal := TACLGlobalMemory.Alloc(PByte(ADescriptor), ADescriptorSize);
    Result := True;
  finally
    FreeMem(ADescriptor);
  end;
end;

{ TACLDragDropDataProviderPIDL }

function TACLDragDropDataProviderPIDL.StoreFiles(
  AFiles: TACLStringList; out AMedium: TStgMedium): Boolean;
var
  LStream: TMemoryStream;
begin
  Result := False;
  if TPIDLHelper.FilesToShellListStream(AFiles, LStream) then
  try
    Result := MediumAlloc(LStream.Memory, LStream.Size, AMedium);
  finally
    LStream.Free;
  end;
end;

function TACLDragDropDataProviderPIDL.GetFormat: TFormatEtc;
begin
  Result := MakeFormat(CF_SHELLIDList);
end;

{$ENDIF}
{$ENDREGION}

{$REGION ' Win32 Implementation '}
{$IFDEF MSWINDOWS}
type

  { TACLDropFormatEtcList }

  TACLDropFormatEtcList = class(TInterfacedObject, IEnumFormatEtc)
  strict private const
    ResultMap: array[Boolean] of Integer = (S_FALSE, S_OK);
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
    //# Properties
    property Cursor: Integer read FCursor;
    property Format[Index: Integer]: TFormatEtc read GetFormat;
    property FormatCount: Integer read GetFormatCount;
  end;

  { TACLDropSourceWin32 }

  TACLDropSourceWin32 = class(TACLDropSource, IDropSource, IDataObject)
  strict private
    FThreadAttached: THandle;
    FThreadCurrent: THandle;

    function GetAttachThreadId: THandle;
    function GetAttachWindow: TWndHandle;
    procedure AttachThread;
    procedure DetachThread;
  protected
    procedure ExecuteCore; override;
    // IDataObject
    function DAdvise(const AFormat: TFormatEtc; advf: Longint;
      const advSink: IAdviseSink; out dwConnection: Longint): HRESULT; stdcall;
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

  { TACLDropSourceWin32 }

  procedure TACLDropSourceWin32.AttachThread;
  begin
    FThreadAttached := GetAttachThreadId;
    FThreadCurrent := GetCurrentThreadId;
    if FThreadAttached <> FThreadCurrent then
      AttachThreadInput(FThreadAttached, FThreadCurrent, True);
  end;

  procedure TACLDropSourceWin32.DetachThread;
  begin
    if (FThreadAttached <> 0) and (FThreadAttached <> FThreadCurrent) then
    begin
      AttachThreadInput(FThreadAttached, FThreadCurrent, False);
      FThreadAttached := 0;
    end;
  end;

  procedure TACLDropSourceWin32.ExecuteCore;
  var
    LActions: Integer;
    LResult: Integer;
  begin
    AttachThread;
    try
      LActions := 0;
      if dsaCopy in AllowedActions then
        LActions := LActions or DROPEFFECT_COPY;
      if dsaMove in AllowedActions then
        LActions := LActions or DROPEFFECT_MOVE;
      if dsaLink in AllowedActions then
        LActions := LActions or DROPEFFECT_LINK;

      OleInitialize(nil);
      try
        if DoDragDrop(Self, Self, LActions, LResult) = DRAGDROP_S_DROP then
        begin
          if LResult and DROPEFFECT_COPY <> 0 then
            Include(FDropResult, dsaCopy);
          if LResult and DROPEFFECT_MOVE <> 0 then
            Include(FDropResult, dsaMove);
          if LResult and DROPEFFECT_LINK <> 0 then
            Include(FDropResult, dsaLink);
        end;
      finally
        OleUninitialize;
      end;
    finally
      DetachThread;
    end;
  end;

  function TACLDropSourceWin32.GiveFeedback(AEffect: LongInt): HRESULT; stdcall;
  begin
    Result := DRAGDROP_S_USEDEFAULTCURSORS;
  end;

  function TACLDropSourceWin32.QueryContinueDrag(AEscapePressed: LongBool; AKeyState: LongInt): HRESULT; stdcall;
  var
    LAllow: Boolean;
  begin
    if AEscapePressed or (Handler = nil) then
      Exit(DRAGDROP_S_CANCEL);
    if AKeyState and (MK_LBUTTON or MK_RBUTTON) <> 0 then
      Exit(S_OK);

    LAllow := True;
    // if we move files from one control of our application to other and if OnDrop event handler
    // will show the Modal Dialog - application will hangs (on WinXP) because of attached input
    // So, we must detach thread input
    DetachThread;
    DoDrop(LAllow);
    if LAllow then
      Result := DRAGDROP_S_DROP
    else
      Result := DRAGDROP_S_CANCEL;
  end;

  function TACLDropSourceWin32.DAdvise(const AFormat: TFormatEtc; advf: Longint;
    const advSink: IAdviseSink; out dwConnection: Longint): HRESULT; stdcall;
  begin
    Result := OLE_E_ADVISENOTSUPPORTED;
  end;

  function TACLDropSourceWin32.DUnadvise(AConnection: Longint):HRESULT; stdcall;
  begin
    Result := OLE_E_ADVISENOTSUPPORTED;
  end;

  function TACLDropSourceWin32.EnumDAdvise(out AEnumAdvise: IEnumStatData): HRESULT; stdcall;
  begin
    Result := OLE_E_ADVISENOTSUPPORTED;
  end;

  function TACLDropSourceWin32.EnumFormatEtc(
    ADirection: Longint; out AEnumFormat: IEnumFormatEtc): HRESULT; stdcall;
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

  function TACLDropSourceWin32.GetCanonicalFormatEtc(
    const AFormat: TFormatEtc; out AFormatOut: TFormatEtc): HRESULT; stdcall;
  begin
    AFormatOut.ptd := nil;
    Result := E_NOTIMPL;
  end;

  function TACLDropSourceWin32.QueryGetData(const AFormat: TFormatEtc): HRESULT; stdcall;
  var
    LProvider: TACLDragDropDataProvider;
    I: Integer;
  begin
    Result := DV_E_FORMATETC;
    if AFormat.dwAspect = DVASPECT_CONTENT then
    begin
      for I := 0 to DataProviders.Count - 1 do
      begin
        LProvider := DataProviders[I];
        if LProvider.IsSupported(AFormat) and LProvider.HasData then
          Exit(S_OK);
      end;
    end;
  end;

  function TACLDropSourceWin32.GetAttachThreadId: THandle;
  var
    AAttach: TWndHandle;
  begin
    AAttach := GetAttachWindow;
    if AAttach <> 0 then
      Result := GetWindowThreadProcessId(AAttach, nil)
    else
      Result := MainThreadID;
  end;

  function TACLDropSourceWin32.GetAttachWindow: TWndHandle;
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

  function TACLDropSourceWin32.GetData(const AFormat: TFormatEtc; out AMedium: TStgMedium): HRESULT; stdcall;
  var
    LProvider: TACLDragDropDataProvider;
    I: Integer;
  begin
    ZeroMemory(@AMedium, SizeOf(AMedium));
    for I := 0 to DataProviders.Count - 1 do
    begin
      LProvider := DataProviders[I];
      if LProvider.IsSupported(AFormat) and LProvider.HasData then
      begin
        if LProvider.Store(AMedium, AFormat) then
          Exit(S_OK);
      end;
    end;
    Result := DV_E_FORMATETC;
  end;

  function TACLDropSourceWin32.GetDataHere(const AFormat: TFormatEtc; out AMedium: TStgMedium): HRESULT; stdcall;
  begin
    Result := E_NOTIMPL;
  end;

  function TACLDropSourceWin32.SetData(const Format: TFormatEtc;
    var Medium: TStgMedium; Release: BOOL): HRESULT; stdcall;
  begin
    Result := E_NOTIMPL;
    try
  //    if (Format.tymed = TYMED_HGLOBAL) and (Format.cfFormat = CF_CONFIG) then
  //    begin
  //      StreamLoad(FTargetConfig.LoadFromStream, TACLGlobalMemoryStream.Create(Medium.hGlobal));
  //      Result := S_OK;
  //    end;
    finally
      if Release then
        ReleaseStgMedium(Medium);
    end;
  end;

{$ENDIF}
{$ENDREGION}

{ TACLDropSource }

class function TACLDropSource.Create(
  AHandler: IACLDropSourceOperation; AControl: TWinControl): TACLDropSource;
begin
{$IF DEFINED(MSWINDOWS)}
  Result := TACLDropSourceWin32.CreateCore(AHandler, AControl);
{$ELSE}
  Result := TACLDropSource.CreateCore(AHandler, AControl);
{$ENDIF}
end;

end.
