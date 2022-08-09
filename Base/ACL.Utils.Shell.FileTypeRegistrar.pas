{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*              Common Classes               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.Shell.FileTypeRegistrar;

// Refer to the http://msdn.microsoft.com/en-us/library/windows/desktop/cc144154(v=vs.85).aspx for more details

{$I ACL.Config.inc}

interface

uses
  Winapi.ActiveX,
  Winapi.Windows,
  Winapi.ShellAPI,
  Winapi.ShlObj,
  // System
  System.SysUtils,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.FileFormats.XML,
  ACL.Parsers,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Registry,
  ACL.Utils.Shell,
  ACL.Utils.Strings;

const
  RootClassesPath = 'Software\Classes\';
  RootCurrentVersion = 'Software\Microsoft\Windows\CurrentVersion\';
  RootRegisteredApps = 'Software\RegisteredApplications\';
  RootShellCommand = 'shell\open\command\';

type

  { TACLFileTypeIconLibraryItem }

  TACLFileTypeIconLibraryItem = class
  strict private
    FExtentions: string;
    FGroupName: string;
    FIconIndex: Integer;
  public
    constructor Create(ANode: TACLXMLNode);
    function IsOurExt(const AExt: UnicodeString): Boolean;
    //
    property Extentions: UnicodeString read FExtentions;
    property GroupName: UnicodeString read FGroupName;
    property IconIndex: Integer read FIconIndex;
  end;

  { TACLFileTypeIconLibrary }

  TACLFileTypeIconLibrary = class
  strict private
    FAuthor: UnicodeString;
    FFileName: UnicodeString;
    FItems: TACLObjectList;
    FName: UnicodeString;

    function GetCount: Integer;
    function GetItem(Index: Integer): TACLFileTypeIconLibraryItem;
  public
    constructor Create; overload;
    constructor Create(const LibFileName: UnicodeString); overload;
    destructor Destroy; override;
    procedure Clear;
    function Find(const AExt, AGroupName: UnicodeString; out AIconIndex: Integer): Boolean; overload;
    function Find(const AExt, AGroupName: UnicodeString; out AItem: TACLFileTypeIconLibraryItem): Boolean; overload;
    function Find(const AExt: UnicodeString; out AItem: TACLFileTypeIconLibraryItem): Boolean; overload;
    procedure Load(const LibFileName: UnicodeString; const DefaultMap: AnsiString = '');
    //
    property Author: UnicodeString read FAuthor;
    property FileName: UnicodeString read FFileName;
    property Name: UnicodeString read FName;
    //
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TACLFileTypeIconLibraryItem read GetItem; default;
  end;

  { TACLFileTypeInfo }

  TACLFileTypeInfo = packed record
    Ext: UnicodeString;
    GroupName: UnicodeString;
    Title: UnicodeString;

    function GetProgID(const AppName: UnicodeString): UnicodeString;
  end;

  { TACLFileTypeUserChoice }

  TACLFileTypeUserChoice = packed record
    AppName: UnicodeString;
    ProgID: UnicodeString;
    RootKey: HKEY;
    SubKey: UnicodeString;
    Value: UnicodeString;

    procedure Associate;
    function IsAssociated: Boolean;
    procedure Unassociate;
  end;

  { TACLFileTypeRegistrar }

  TACLFileTypeRegistrar = class abstract
  public type
    TEnumProc = reference to procedure (const AInfo: TACLFileTypeInfo);
  strict private
    class function CreateComObject(const CLSID, IID: TGUID; out AIntf): Boolean;
  protected
    // App information
    class function AppClientType: string; virtual; abstract;
    class function AppDescription: string; virtual; abstract;
    class function AppDisplayName: string; virtual;
    class function AppDropTargetClass: string; virtual;
    class function AppFileName: string; virtual; abstract;
    class function AppFileNameOfIconLibrary: string; virtual;
    class function AppFileNameOfInstaller: string; virtual;
    class function AppGetClientPath: UnicodeString;
    class function AppGetDefaultIconLibraryMap: AnsiString; virtual;
    class function AppName: string; virtual; abstract;
    class function AppVersion: Cardinal; virtual; abstract;

    class procedure RegisterApplication(const AIconLibraryFileName: string); virtual;
    class procedure RegisterFileTypeCommand(AKey: HKEY; const ATypeRoot, AName, ACaption, ACmdLine, ADropTargetClass: string);
    class procedure RegisterFileTypeCommands(AKey: HKEY; const ATypeRoot: string; const AInfo: TACLFileTypeInfo); virtual;
    class function RegisterFileTypeInfo(AKey: HKEY; const AInfo: TACLFileTypeInfo; ALibrary: TACLFileTypeIconLibrary): Boolean; virtual;
    class procedure UnregisterApplication; virtual;
    class function UnregisterFileTypeInfo(AKey: HKEY; const AInfo: TACLFileTypeInfo): Boolean; virtual;
    class procedure UpdateUserChoice(AState: Boolean);
  public
    class procedure EnumFileTypes(AProc: TEnumProc); virtual; abstract;
    class procedure SetAppAsDefault;
    class procedure ShowRegistrationUI;

    class function LoadIconLibrary(const AFileName: string): TACLFileTypeIconLibrary;
    class function GetIconLibrary: string;
    class function GetRegistered: Boolean;
    class procedure SetIconLibrary(const Value: string);
    class procedure SetRegistered(AValue: Boolean);
  end;

implementation

uses
  System.AnsiStrings;

{ TACLFileTypeIconLibraryItem }

constructor TACLFileTypeIconLibraryItem.Create(ANode: TACLXMLNode);
begin
  inherited Create;
  FExtentions := ANode.Attributes.GetValue('Exts');
  FIconIndex := StrToIntDef(ANode.Attributes.GetValue('id'), 0);
  FGroupName := ANode.Attributes.GetValue('Type');
end;

function TACLFileTypeIconLibraryItem.IsOurExt(const AExt: UnicodeString): Boolean;
begin
  Result := acIsOurFile(Extentions, AExt);
end;

{ TACLFileTypeIconLibrary }

constructor TACLFileTypeIconLibrary.Create;
begin
  inherited Create;
  FItems := TACLObjectList.Create;
end;

constructor TACLFileTypeIconLibrary.Create(const LibFileName: UnicodeString);
begin
  Create;
  Load(LibFileName);
end;

destructor TACLFileTypeIconLibrary.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TACLFileTypeIconLibrary.Clear;
begin
  FItems.Clear;
end;

function TACLFileTypeIconLibrary.Find(const AExt, AGroupName: UnicodeString; out AIconIndex: Integer): Boolean;
var
  AItem: TACLFileTypeIconLibraryItem;
begin
  Result := Find(AExt, AGroupName, AItem);
  if Result then
    AIconIndex := AItem.IconIndex;
end;

function TACLFileTypeIconLibrary.Find(const AExt, AGroupName: UnicodeString; out AItem: TACLFileTypeIconLibraryItem): Boolean;
var
  I: Integer;
begin
  Result := Find(AExt, AItem);
  if not Result then
    for I := 0 to Count - 1 do
    begin
      Result := acSameText(Items[I].GroupName, AGroupName);
      if Result then
      begin
        AItem := Items[I];
        Break;
      end;
    end;
end;

function TACLFileTypeIconLibrary.Find(const AExt: UnicodeString; out AItem: TACLFileTypeIconLibraryItem): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
  begin
    Result := Items[I].IsOurExt(AExt);
    if Result then
    begin
      AItem := Items[I];
      Break;
    end;
  end;
end;

procedure TACLFileTypeIconLibrary.Load(const LibFileName: UnicodeString; const DefaultMap: AnsiString = '');
var
  AHandle: THandle;
  AXmlDoc: TACLXMLDocument;
begin
  AHandle := acLoadLibrary(LibFileName, LOAD_LIBRARY_AS_DATAFILE);
  try
    Clear;
    AXmlDoc := TACLXMLDocument.Create;
    try
      FFileName := LibFileName;
      if FindResourceW(AHandle, 'MAP', 'XML') <> 0 then
        AXmlDoc.LoadFromResource(AHandle, 'MAP', 'XML')
      else
        AXmlDoc.LoadFromString(DefaultMap);

      if AXmlDoc.Count > 0 then
      begin
        AXmlDoc[0].Enum(
          procedure (ANode: TACLXMLNode)
          begin
            if System.AnsiStrings.SameText(ANode.NodeName, 'author') then
              FAuthor := ANode.NodeValue
            else if System.AnsiStrings.SameText(ANode.NodeName, 'name') then
              FName := ANode.NodeValue
            else if System.AnsiStrings.SameText(ANode.NodeName, 'icon') then
              FItems.Add(TACLFileTypeIconLibraryItem.Create(ANode));
          end);
      end;
    finally
      AXmlDoc.Free;
    end;
  finally
    FreeLibrary(AHandle);
  end;
end;

function TACLFileTypeIconLibrary.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TACLFileTypeIconLibrary.GetItem(Index: Integer): TACLFileTypeIconLibraryItem;
begin
  Result := TACLFileTypeIconLibraryItem(FItems.Items[Index]);
end;

{ TACLFileTypeInfo }

function TACLFileTypeInfo.GetProgID(const AppName: UnicodeString): UnicodeString;
begin
  Result := Ext;
  if Result[1] = '.' then
    Delete(Result, 1, 1);
  Result := AppName + '.AssocFile.' + acUpperCase(Result);
end;

{ TACLFileTypeUserChoice }

procedure TACLFileTypeUserChoice.Associate;
var
  AKey: HKEY;
  AOldProgID: UnicodeString;
begin
  if acRegOpenWrite(RootKey, SubKey, AKey, True) then
  try
    AOldProgID := acRegReadStr(AKey, Value);
    if not acSameText(AOldProgID, ProgID) then
    begin
      acRegWriteStr(AKey, AppName + '.Backup', AOldProgID);
      acRegWriteStr(AKey, Value, ProgID);
    end;
  finally
    acRegClose(AKey);
  end;
end;

function TACLFileTypeUserChoice.IsAssociated: Boolean;
var
  AKey: HKEY;
begin
  Result := False;
  if acRegOpenRead(RootKey, SubKey, AKey) then
  try
    Result := acRegReadStr(AKey, Value) = ProgID;
  finally
    acRegClose(AKey);
  end;
end;

procedure TACLFileTypeUserChoice.Unassociate;
var
  AKey: HKEY;
begin
  if acRegOpenWrite(RootKey, SubKey, AKey) then
  try
    if acSameText(acRegReadStr(AKey, Value), ProgID) then
    begin
      if acRegWriteStr(AKey, Value, acRegReadStr(AKey, AppName + '.Backup')) then
        acRegDeleteValue(AKey, AppName + '.Backup');
    end;
  finally
    acRegClose(AKey);
  end;
end;

{ TACLFileTypeRegistrar }

class procedure TACLFileTypeRegistrar.SetAppAsDefault;
var
  AIntf: IApplicationAssociationRegistration;
begin
  SetRegistered(True);
  UpdateUserChoice(True);
  //#AI:
  //# Note: the SetAppAsDefaultAll method not intended for use in Windows 8, see:
  //# http://msdn.microsoft.com/en-us/library/windows/desktop/bb776338(v=vs.85).aspx
  if CreateComObject(CLSID_ApplicationAssociationRegistration, IApplicationAssociationRegistration, AIntf) then
    AIntf.SetAppAsDefaultAll(PChar(AppName));
end;

class procedure TACLFileTypeRegistrar.ShowRegistrationUI;
var
  AIntf: IApplicationAssociationRegistrationUI;
  AResult: Boolean;
begin
  AResult := False;
  if not IsWin10OrLater then
  begin
    if CreateComObject(CLSID_ApplicationAssociationRegistrationUI, IApplicationAssociationRegistrationUI, AIntf) then
      AResult := Succeeded(AIntf.LaunchAdvancedAssociationUI(PChar(AppName)))
  end;

  if not AResult then
    ShellExecute('control.exe', '/NAME Microsoft.DefaultPrograms /PAGE pageDefaultProgram');
end;

class function TACLFileTypeRegistrar.AppDisplayName: string;
begin
  Result := AppName;
end;

class function TACLFileTypeRegistrar.AppDropTargetClass: string;
begin
  Result := '';
end;

class function TACLFileTypeRegistrar.AppFileNameOfIconLibrary: string;
begin
  Result := AppFileName;
end;

class function TACLFileTypeRegistrar.AppFileNameOfInstaller: string;
begin
  Result := '';
end;

class function TACLFileTypeRegistrar.CreateComObject(const CLSID, IID: TGUID; out AIntf): Boolean;
begin
  Result := Succeeded(CoCreateInstance(CLSID, nil, CLSCTX_INPROC_SERVER or CLSCTX_LOCAL_SERVER, IID, AIntf));
end;

class procedure TACLFileTypeRegistrar.RegisterFileTypeCommand(
  AKey: HKEY; const ATypeRoot, AName, ACaption, ACmdLine, ADropTargetClass: string);
begin
  acRegWriteDefaultStr(AKey, ATypeRoot + '\shell\' + AName + '\', ACaption);
  acRegWriteDefaultStr(AKey, ATypeRoot + '\shell\' + AName + '\command\', ACmdLine);
  acRegWriteStr(AKey, ATypeRoot + '\shell\' + AName + '\', 'MultiSelectModel', 'Player');
  if ADropTargetClass <> '' then
    acRegWriteStr(AKey, ATypeRoot + '\shell\' + AName + '\DropTarget\', 'CLSID', ADropTargetClass);
end;

class procedure TACLFileTypeRegistrar.RegisterFileTypeCommands(
  AKey: HKEY; const ATypeRoot: string; const AInfo: TACLFileTypeInfo);
begin
  RegisterFileTypeCommand(AKey, ATypeRoot, 'open', 'Open', '"' + acSelfExeName + '" "%1"', AppDropTargetClass);
end;

class function TACLFileTypeRegistrar.RegisterFileTypeInfo(
  AKey: HKEY; const AInfo: TACLFileTypeInfo; ALibrary: TACLFileTypeIconLibrary): Boolean;
var
  AIconIndex: Integer;
  ATypeRoot: UnicodeString;
begin
  Result := AKey <> 0;
  if Result then
  begin
    if not ALibrary.Find(AInfo.Ext, AInfo.GroupName, AIconIndex) then
      AIconIndex := 0;

    ATypeRoot := AInfo.GetProgID(AppName);
    acRegWriteDefaultStr(AKey, ATypeRoot, AppDisplayName + ': ' + AInfo.Title);
    acRegWriteDefaultStr(AKey, ATypeRoot + '\DefaultIcon', ALibrary.FileName + ',' + IntToStr(AIconIndex));
    if AppDropTargetClass <> '' then
      acRegWriteDefaultStr(AKey, ATypeRoot + '\CLSID', AppDropTargetClass);
    RegisterFileTypeCommands(AKey, ATypeRoot, AInfo);
  end;
end;

class function TACLFileTypeRegistrar.UnregisterFileTypeInfo(AKey: HKEY; const AInfo: TACLFileTypeInfo): Boolean;
begin
  Result := acRegKeyDeleteWithSubKeys(AKey, AInfo.GetProgID(AppName));
end;

class procedure TACLFileTypeRegistrar.UpdateUserChoice(AState: Boolean);
var
  AKey: HKEY;
  AUserChoice: TACLFileTypeUserChoice;
begin
  if acRegOpenWrite(HKEY_LOCAL_MACHINE, RootClassesPath, AKey) then
  try
    AUserChoice.AppName := AppName;
    AUserChoice.RootKey := AKey;
    AUserChoice.Value := '';

    EnumFileTypes(
      procedure (const AInfo: TACLFileTypeInfo)
      begin
        AUserChoice.SubKey := acLowerCase(AInfo.Ext);
        AUserChoice.ProgID := AInfo.GetProgID(AUserChoice.AppName);
        if AState then
          AUserChoice.Associate
        else
          AUserChoice.Unassociate;
      end);
  finally
    acRegClose(AKey);
  end;
end;

class function TACLFileTypeRegistrar.AppGetClientPath: UnicodeString;
begin
  Result := 'Software\Clients\' + IfThenW(AppClientType, 'Unknown') + '\' + AppName + '\';
end;

class function TACLFileTypeRegistrar.AppGetDefaultIconLibraryMap: AnsiString;
begin
  Result := '';
end;

class function TACLFileTypeRegistrar.LoadIconLibrary(const AFileName: string): TACLFileTypeIconLibrary;
begin
  Result := TACLFileTypeIconLibrary.Create;
  Result.Load(AFileName, AppGetDefaultIconLibraryMap);
end;

class function TACLFileTypeRegistrar.GetIconLibrary: string;
begin
  Result := acRegReadStr(HKEY_LOCAL_MACHINE, AppGetClientPath, 'IconLibrary');
  if Result = '' then
    Result := AppFileNameOfIconLibrary;
end;

class procedure TACLFileTypeRegistrar.RegisterApplication(const AIconLibraryFileName: string);
var
  AClassesRootKey: HKEY;
  AIconLibrary: TACLFileTypeIconLibrary;
  AKey: HKEY;
begin
  acRegWriteDefaultStr(HKEY_LOCAL_MACHINE, AppGetClientPath, AppDisplayName);
  acRegWriteDefaultStr(HKEY_LOCAL_MACHINE, AppGetClientPath + 'DefaultIcon', AppFileName + ',0');
  acRegWriteDefaultStr(HKEY_LOCAL_MACHINE, AppGetClientPath + RootShellCommand, AppFileName);
  acRegWriteStr(HKEY_LOCAL_MACHINE, AppGetClientPath, 'IconLibrary', AIconLibraryFileName);

  if acRegOpenWrite(HKEY_LOCAL_MACHINE, AppGetClientPath + 'InstallInfo\', AKey, True) then
  try
    acRegWriteInt(AKey, 'IconsVisible', 1);
    if AppFileNameOfInstaller <> '' then
    begin
      acRegWriteStr(AKey, 'HideIconsCommand', '"' + AppFileNameOfInstaller + '" /REG=R0');
      acRegWriteStr(AKey, 'ReinstallCommand', '"' + AppFileNameOfInstaller + '" /REG=R1');
      acRegWriteStr(AKey, 'ShowIconsCommand', '"' + AppFileNameOfInstaller + '" /REG=R1');
    end;
  finally
    acRegClose(AKey);
  end;

  if acRegOpenWrite(HKEY_LOCAL_MACHINE, AppGetClientPath + 'Capabilities\', AKey, True) then
  try
    acRegWriteStr(AKey, 'ApplicationIcon', '"' + AppFileName + ',0"');
    acRegWriteStr(AKey, 'ApplicationName', AppName);
    acRegWriteStr(AKey, 'ApplicationDescription', AppDescription);
    acRegWriteInt(AKey, 'ApplicationVersion', AppVersion);
  finally
    acRegClose(AKey);
  end;

  if acRegOpenWrite(HKEY_LOCAL_MACHINE, AppGetClientPath + 'Capabilities\FileAssociations\', AKey, True) then
  try
    if acRegOpenWrite(HKEY_LOCAL_MACHINE, RootClassesPath, AClassesRootKey) then
    try
      AIconLibrary := LoadIconLibrary(AIconLibraryFileName);
      try
        EnumFileTypes(
          procedure (const AFileTypeInfo: TACLFileTypeInfo)
          begin
            if RegisterFileTypeInfo(AClassesRootKey, AFileTypeInfo, AIconLibrary) then
              acRegWriteStr(AKey, AFileTypeInfo.Ext, AFileTypeInfo.GetProgID(AppName));
          end);
      finally
        AIconLibrary.Free;
      end;
    finally
      acRegClose(AClassesRootKey);
    end;
  finally
    acRegClose(AKey);
  end;

  acRegWriteStr(HKEY_LOCAL_MACHINE, RootRegisteredApps, AppName, AppGetClientPath + 'Capabilities\');
end;

class procedure TACLFileTypeRegistrar.UnregisterApplication;
var
  AKey: HKEY;
begin
  UpdateUserChoice(False);

  if acRegOpenWrite(HKEY_LOCAL_MACHINE, RootClassesPath, AKey) then
  try
    EnumFileTypes(
      procedure (const AInfo: TACLFileTypeInfo)
      begin
        UnregisterFileTypeInfo(AKey, AInfo);
      end);
  finally
    acRegClose(AKey);
  end;

  acRegDeleteValue(HKEY_LOCAL_MACHINE, RootRegisteredApps, AppName);
  acRegKeyDeleteWithSubKeys(HKEY_LOCAL_MACHINE, AppGetClientPath);
end;

class function TACLFileTypeRegistrar.GetRegistered: Boolean;
var
  AKey: HKEY;
  AVersion: Cardinal;
begin
  Result := False;
  if acRegOpenRead(HKEY_LOCAL_MACHINE, AppGetClientPath + 'Capabilities\', AKey) then
  try
    AVersion := acRegReadInt(AKey, 'ApplicationVersion');
    Result := (AVersion > 0) and (AVersion <= AppVersion);
  finally
    acRegClose(AKey);
  end;
end;

class procedure TACLFileTypeRegistrar.SetIconLibrary(const Value: string);
begin
  if GetRegistered then
  begin
    RegisterApplication(Value);
    UpdateShellCache;
  end;
end;

class procedure TACLFileTypeRegistrar.SetRegistered(AValue: Boolean);
begin
  if AValue <> GetRegistered then
  begin
    if AValue then
      RegisterApplication(AppFileNameOfIconLibrary)
    else
      UnregisterApplication;

    UpdateShellCache;
  end;
end;

end.
