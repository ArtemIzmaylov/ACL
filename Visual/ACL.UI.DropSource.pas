////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Shell Drop Source
//
//  Author:    Artem Izmaylov
//             © 2006-2025
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
  ACL.Threading,
  ACL.UI.Controls.Base,
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

  TACLDragDropDataProviders = class(TACLObjectListOf<TACLDragDropDataProvider>);

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

{$IF DEFINED(MSWINDOWS)}
  {$I ACL.UI.DropSource.Win32.inc}
{$ELSEIF DEFINED(LCLGtk3)}
  {$I ACL.UI.DropSource.Gtk3.inc}
{$ELSEIF DEFINED(LCLGtk2)}
  {$I ACL.UI.DropSource.Gtk2.inc}
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
    if IsMainThread or not (csFreeNotification in ComponentState) then
      Free
    else
      RunInMainThread(Free, False);
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

{ TACLDropSource }

class function TACLDropSource.Create(
  AHandler: IACLDropSourceOperation; AControl: TWinControl): TACLDropSource;
begin
  Result := TACLDropSourceImpl.CreateCore(AHandler, AControl);
end;

end.
