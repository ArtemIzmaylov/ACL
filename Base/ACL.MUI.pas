{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*          Multilanguage UI Engine          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.MUI;

{$I ACL.Config.inc}

interface

uses
  Windows, Classes, Messages, Generics.Collections,
{$IFNDEF ACL_BASE_NOVCL}
  Forms, Graphics,
{$ENDIF}
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FileFormats.INI;

const
  sLangExt = '.lng';
  sDefaultLang  = 'English' + sLangExt;
  sDefaultLang2 = 'Russian' + sLangExt;

  sLangAuthor = 'Author';
  sLangIcon = 'Icon';
  sLangID = 'LangId';
  sLangMainSection = 'File';
  sLangMsg = 'MSG';
  sLangName = 'Name';
  sLangPartSeparator = '|';
  sLangVersionId = 'VersionId';

  sLangMacroBegin = '@Lng:';
  sLangMacroEnd = ';';

const
  WM_ACL_LANG = WM_USER + 101;

  LANG_EN_US = LANG_ENGLISH   or (SUBLANG_ENGLISH_US shl 10); // 1033
  LANG_RU_RU = LANG_RUSSIAN   or (SUBLANG_DEFAULT    shl 10); // 1049
  LANG_UK_UA = LANG_UKRAINIAN or (SUBLANG_DEFAULT    shl 10); // 1058

type

  { IACLLocalizableComponent }

  IACLLocalizableComponent = interface
  ['{41434C4D-5549-436F-6D70-6F6E656E7400}']
    procedure Localize(const ASection: UnicodeString);
  end;

  { IACLLocalizableComponentRoot }

  IACLLocalizableComponentRoot = interface
  ['{9250A6D0-932D-4996-811F-4F8B0CC72DFE}']
    function GetLangSection: UnicodeString;
  end;

  { IACLLocalizationListener }

  IACLLocalizationListener = interface
  ['{5A92CDBE-DBF8-42EE-9661-2D6392618D64}']
    procedure LangChanged;
  end;

  { IACLLocalizationListener2 }

  IACLLocalizationListener2 = interface(IACLLocalizationListener)
  ['{AB6E20E3-32B9-49F6-9309-B1B3BFFA0633}']
    procedure LangInitialize;
  end;

  { IACLLocalizationListener3 }

  IACLLocalizationListener3 = interface(IACLLocalizationListener)
  ['{EED7CE81-1E91-4382-A3EF-46BA995E3CF5}']
    procedure LangChanging;
  end;

  { TACLCodePages }

  TACLCodePages = class
  strict private
    FList: TStringList;
    function GetCount: Integer;
    function GetID(Index: Integer): Integer;
    function GetName(Index: Integer): string;
  protected
    procedure AddCodePage(ID: Cardinal);
    //
    class function CompareCodePages(List: TStringList; Index1, Index2: Integer): Integer; static;
    class function EnumCodePagesProc(lpCodePageString: PWideChar): Cardinal; stdcall; static;
  public
    constructor Create;
    destructor Destroy; override;
    function IndexOf(ACodePageID: Integer): Integer;
    //
    property ID[Index: Integer]: Integer read GetID;
    property Name[Index: Integer]: string read GetName;
    property Count: Integer read GetCount;
  end;

  { TACLLocalizationInfo }

  TACLLocalizationInfo = packed record
    Author: UnicodeString;
    LangID: Integer;
    Name: UnicodeString;
    VersionID: Integer;
  end;

  { TACLLocalization }

  TACLLocalizationClass = class of TACLLocalization;
  TACLLocalization = class(TACLIniFile)
  strict private
    FListeners: TACLListenerList;

    function GetLangID: Integer;
    function GetShortFileName: UnicodeString;
    procedure SetLangID(const Value: Integer);
  protected
    procedure LangChanged;
  public
    constructor Create(const AFileName: UnicodeString; AutoSave: Boolean = True); override;
    destructor Destroy; override;
    procedure ExpandLinks(AInst: HINST; const AName: UnicodeString; AType: PWideChar); overload;
    procedure ExpandLinks(ALinks: TACLIniFile); overload;
    procedure LoadFromFile(const AFileName: UnicodeString); override;
    procedure LoadFromStream(AStream: TStream); override;
    //
    function ReadStringEx(const ASection, AKey: UnicodeString; out AValue: UnicodeString): Boolean; override;
    // Listeners
    class procedure ListenerAdd(const AListener: IACLLocalizationListener);
    class procedure ListenerRemove(const AListener: IACLLocalizationListener);
    // Properties
    property LangID: Integer read GetLangID write SetLangID;
    property ShortFileName: UnicodeString read GetShortFileName;
  end;

var
  LangFilePath: UnicodeString = '';

function CodePages: TACLCodePages;
function GetCodePageByLCID(LCID: Cardinal): UINT;
function GetUserLangID: Integer;
function LangFile: TACLLocalization;

procedure LangApplyTo(const AParentSection: UnicodeString; AComponent: TComponent);
procedure LangApplyToItems(const ASection: UnicodeString; AItems: TStrings);

function LangExpandMacros(const AText: UnicodeString; const ADefaultSection: UnicodeString = ''): UnicodeString;
function LangExtractPart(const AValue: UnicodeString; APartIndex: Integer): UnicodeString;
function LangGetComponentPath(const AComponent: TComponent): UnicodeString;
procedure LangGetFiles(AList: TACLStringList);

function LangGet(const ASection, AItemName: UnicodeString; const ADefaultValue: UnicodeString = ''): UnicodeString;
function LangGetMsg(ID: Integer): UnicodeString;
function LangGetMsgPart(ID, APart: Integer): UnicodeString;

{$IFNDEF ACL_BASE_NOVCL}
function LangGetInfo(const ALangFile: TACLIniFile; var AData: TACLLocalizationInfo; AIcon: TIcon): Boolean; overload;
function LangGetInfo(const ALangFile: UnicodeString; var AData: TACLLocalizationInfo): Boolean; overload;
function LangGetInfo(const ALangFile: UnicodeString; var AData: TACLLocalizationInfo; AIcon: TIcon): Boolean; overload;
{$ENDIF}

procedure LangSetFileClass(AClass: TACLLocalizationClass);
implementation

uses
  TypInfo, SysUtils,
{$IFNDEF ACL_BASE_NOVCL}
  Controls, Menus, ActnList,
{$ENDIF}
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

const
  LOCALE_RETURN_NUMBER = $20000000;   { return number instead of string }

var
  FLangFile: TACLLocalization;
  FLangFileClass: TACLLocalizationCLass = TACLLocalization;
  FCodePages: TACLCodePages;
  LCodePages: TACLCodePages;

function CodePages: TACLCodePages;
begin
  if FCodePages = nil then
    FCodePages := TACLCodePages.Create;
  Result := FCodePages;
end;

function LangGetComponentPath(const AComponent: TComponent): UnicodeString;
var
  S: IACLLocalizableComponentRoot;
begin
  if Supports(AComponent, IACLLocalizableComponentRoot, S) then
    Result := S.GetLangSection
  else
    if AComponent <> nil then
    begin
      Result := LangGetComponentPath(AComponent.Owner);
      if AComponent.Name <> '' then
        Result := Result + IfThenW(Result <> '', '.') + AComponent.Name;
    end
    else
      Result := '';
end;

function GetCodePageByLCID(LCID: Cardinal): UINT;
begin
  GetLocaleInfo(LCID, LOCALE_IDEFAULTANSICODEPAGE or LOCALE_RETURN_NUMBER, @Result, SizeOf(Result) div SizeOf(Char));
end;

function GetUserLangID: Integer;
begin
  Result := Word(GetUserDefaultUILanguage);
  if Result <> 0 then
    Result := Result and $3FF
  else
    Result := 0;
end;

function LangFile: TACLLocalization;
begin
  if FLangFile = nil then
    FLangFile := FLangFileClass.Create;
  Result := FLangFile;
end;

procedure LangSetFileClass(AClass: TACLLocalizationClass);
begin
  FLangFileClass := AClass;
  FreeAndNil(FLangFile);
end;

procedure LangApplyTo(const AParentSection: UnicodeString; AComponent: TComponent);
{$IFNDEF ACL_BASE_NOVCL}
  function IsActionAssigned(AObject: TObject): Boolean;
  var
    APropInfo: PPropInfo;
  begin
    APropInfo := GetPropInfo(AObject, 'Action');
    Result := (APropInfo <> nil) and (GetOrdProp(AObject, APropInfo) <> 0);
  end;

  function CanLocalizeCaptionAndHint: Boolean;
  begin
    Result := not (IsActionAssigned(AComponent) or (AComponent is TMenuItem) and TMenuItem(AComponent).IsLine);
  end;
{$ENDIF}

  procedure SetStringValue(APropInfo: PPropInfo; const S: UnicodeString);
  begin
    if APropInfo <> nil then
      SetStrProp(AComponent, APropInfo, S);
  end;

var
  AIntf: IACLLocalizableComponent;
  I: Integer;
  S: UnicodeString;
begin
  if not LangFile.IsEmpty then
  begin
  {$IFNDEF ACL_BASE_NOVCL}
    if AComponent is TAction then
    begin
      TAction(AComponent).Caption := LangFile.ReadString(AParentSection, AComponent.Name);
      TAction(AComponent).Hint := IfThenW(LangFile.ReadString(AParentSection, AComponent.Name + '.h'), TAction(AComponent).Caption);
    end
    else
      if CanLocalizeCaptionAndHint then
  {$ENDIF}
      begin
        if LangFile.ReadStringEx(AParentSection, AComponent.Name, S) then
          SetStringValue(GetPropInfo(AComponent, 'Caption'), S);
        if LangFile.ReadStringEx(AParentSection, AComponent.Name + '.h', S) then
          SetStringValue(GetPropInfo(AComponent, 'Hint'), S);
      end;

    if Supports(AComponent, IACLLocalizableComponent, AIntf) then
      AIntf.Localize(AParentSection + '.' + AComponent.Name)
    else
      for I := 0 to AComponent.ComponentCount - 1 do
        LangApplyTo(AParentSection, AComponent.Components[I]);
  end;
end;

procedure LangApplyToItems(const ASection: UnicodeString; AItems: TStrings);
var
  I: Integer;
begin
  AItems.BeginUpdate;
  try
    for I := 0 to AItems.Count - 1 do
      AItems.Strings[I] := LangFile.ReadString(ASection, 'i[' + IntToStr(I) + ']', AItems.Strings[I]);
  finally
    AItems.EndUpdate;
  end;
end;

function LangExpandMacros(const AText: UnicodeString; const ADefaultSection: UnicodeString = ''): UnicodeString;
var
  K, I, J, L: Integer;
  S: TStringBuilder;
  V: UnicodeString;
begin
  if Pos(sLangMacroBegin, AText) = 0 then
    Exit(AText);

  S := TACLStringBuilderManager.Get(Length(AText));
  try
    I := 1;
    repeat
      J := Pos(sLangMacroBegin, AText, I);
      L := Pos(sLangMacroEnd, AText, J + 1);
      if (J = 0) or (L = 0) then
      begin
        S.Append(AText, I - 1, Length(AText) - I + 1);
        Break;
      end;
      S.Append(AText, I - 1, J - I);

      // Expand
      J := J + Length(sLangMacroBegin);
      V := Copy(AText, J, L - J);
      K := acPos('\', V);
      if K = 0 then
        S.Append(LangGet(ADefaultSection, V))
      else
        S.Append(LangGet(Copy(V, 1, K - 1), Copy(V, K + 1, MaxInt)));

      I := L + Length(sLangMacroEnd);
    until False;
    Result := S.ToString;
  finally
    TACLStringBuilderManager.Release(S);
  end;
end;

function LangExtractPart(const AValue: UnicodeString; APartIndex: Integer): UnicodeString;
var
  APos: Integer;
begin
  Result := AValue;
  while APartIndex > 0 do
  begin
    APos := acPos(sLangPartSeparator, Result);
    if APos = 0 then
      APos := Length(Result);
    Delete(Result, 1, APos);
    Dec(APartIndex);
  end;
  APos := acPos(sLangPartSeparator, Result) - 1;
  if APos < 0 then
    APos := Length(Result);
  Result := Copy(Result, 1, APos);
end;

procedure LangGetFiles(AList: TACLStringList);
begin
  acEnumFiles(LangFilePath, '*' + sLangExt + ';', AList);
  AList.SortLogical;
end;

function LangGet(const ASection, AItemName: UnicodeString; const ADefaultValue: UnicodeString = ''): UnicodeString;
begin
  Result := LangFile.ReadString(ASection, AItemName, ADefaultValue);
end;

function LangGetMsg(ID: Integer): UnicodeString;
begin
  Result := Langfile.ReadString(sLangMsg, IntToStr(ID));
end;

function LangGetMsgPart(ID, APart: Integer): UnicodeString;
begin
  Result := LangExtractPart(LangGetMsg(ID), APart);
end;

{$IFNDEF ACL_BASE_NOVCL}
function LangGetInfo(const ALangFile: TACLIniFile; var AData: TACLLocalizationInfo; AIcon: TIcon): Boolean; overload;
begin
  AData.Author := ALangFile.ReadString(sLangMainSection, sLangAuthor);
  AData.LangID := ALangFile.ReadInteger(sLangMainSection, sLangID);
  AData.Name := ALangFile.ReadString(sLangMainSection, sLangName);
  AData.VersionID := ALangFile.ReadInteger(sLangMainSection, sLangVersionId, 0);
  if AIcon <> nil then
  begin
    if not ALangFile.ReadObject(sLangMainSection, sLangIcon, AIcon.LoadFromStream) then
      AIcon.Handle := 0;
  end;
  Result := True;
end;

function LangGetInfo(const ALangFile: UnicodeString; var AData: TACLLocalizationInfo): Boolean; overload;
begin
  Result := LangGetInfo(ALangFile, AData, nil);
end;

function LangGetInfo(const ALangFile: UnicodeString; var AData: TACLLocalizationInfo; AIcon: TIcon): Boolean;
var
  AInfo: TACLIniFile;
begin
  AInfo := TACLIniFile.Create(ALangFile, False);
  try
    Result := LangGetInfo(AInfo, AData, AIcon);
  finally
    AInfo.Free;
  end;
end;
{$ENDIF}

{ TACLLocalization }

constructor TACLLocalization.Create(const AFileName: UnicodeString; AutoSave: Boolean = True);
begin
  inherited Create(AFileName, False);
  FListeners := TACLListenerList.Create;
end;

destructor TACLLocalization.Destroy;
begin
  FreeAndNil(FListeners);
  inherited Destroy;
end;

procedure TACLLocalization.ExpandLinks(AInst: HINST; const AName: UnicodeString; AType: PWideChar);
var
  ALinks: TACLIniFile;
begin
  ALinks := TACLIniFile.Create;
  try
    ALinks.LoadFromResource(AInst, AName, AType);
    ExpandLinks(ALinks);
  finally
    ALinks.Free;
  end;
end;

procedure TACLLocalization.ExpandLinks(ALinks: TACLIniFile);
var
  AItemName: UnicodeString;
  AItems: TACLStringList;
  ASectionName: UnicodeString;
  AValue: UnicodeString;
  I, J, P: Integer;
begin
  AItems := TACLStringList.Create;
  try
    for I := 0 to ALinks.SectionCount - 1 do
    begin
      AItems.Clear;
      ASectionName := ALinks.Sections[I];
      ALinks.ReadKeys(ASectionName, AItems);
      for J := 0 to AItems.Count - 1 do
      begin
        AItemName := AItems[J];
        if not ExistsKey(ASectionName, AItemName) then
        begin
          AValue := ALinks.ReadString(ASectionName, AItemName);
          P := acPos('>', AValue);
          if P = 0 then
            AValue := ReadString(ASectionName, Copy(AValue, 2, MaxInt))
          else
            AValue := ReadString(Copy(AValue, 2, P - 2), Copy(AValue, P + 1, MaxInt));

          WriteString(ASectionName, AItemName, AValue);
        end;
      end;
    end;
  finally
    AItems.Free;
  end;
end;

procedure TACLLocalization.LoadFromFile(const AFileName: UnicodeString);
begin
  inherited LoadFromFile(LangFilePath + AFileName);
end;

procedure TACLLocalization.LoadFromStream(AStream: TStream);
begin
  inherited LoadFromStream(AStream);
  DefaultCodePage := ReadInteger(sLangMainSection, 'ANSICP', CP_ACP);
  LangChanged;
end;

function TACLLocalization.ReadStringEx(const ASection, AKey: UnicodeString; out AValue: UnicodeString): Boolean;
begin
  Result := inherited ReadStringEx(ASection, AKey, AValue);
  if Result then
    AValue := acDecodeLineBreaks(AValue);
end;

class procedure TACLLocalization.ListenerAdd(const AListener: IACLLocalizationListener);
begin
  LangFile.FListeners.Add(AListener);
end;

class procedure TACLLocalization.ListenerRemove(const AListener: IACLLocalizationListener);
begin
  if FLangFile <> nil then
    LangFile.FListeners.Remove(AListener);
end;

procedure TACLLocalization.LangChanged;
{$IFNDEF ACL_BASE_NOVCL}
var
  I: Integer;
{$ENDIF}
begin
  if not acSameTextEx(ShortFileName, [sDefaultLang, sDefaultLang2]) then
    Merge(LangFilePath + sDefaultLang, False);

  FListeners.Enum<IACLLocalizationListener2>(
    procedure (const AIntf: IACLLocalizationListener2)
    begin
      AIntf.LangInitialize;
    end);

  FListeners.Enum<IACLLocalizationListener3>(
    procedure (const AIntf: IACLLocalizationListener3)
    begin
      AIntf.LangChanging;
    end);

{$IFNDEF ACL_BASE_NOVCL}
  if Assigned(Application.MainForm) then
    SendMessage(Application.MainForm.Handle, WM_ACL_LANG, 0, 0);
  for I := 0 to Screen.FormCount - 1 do
    SendMessage(Screen.Forms[I].Handle, WM_ACL_LANG, 0, 0);
{$ENDIF}

  FListeners.Enum<IACLLocalizationListener>(
    procedure (const AIntf: IACLLocalizationListener)
    begin
      AIntf.LangChanged;
    end);
end;

function TACLLocalization.GetLangID: Integer;
begin
  Result := ReadInteger(sLangMainSection, sLangID);
end;

function TACLLocalization.GetShortFileName: UnicodeString;
begin
  Result := acExtractFileName(FileName);
end;

procedure TACLLocalization.SetLangID(const Value: Integer);
begin
  WriteInteger(sLangMainSection, sLangID, Value);
end;

{ TACLCodePages }

constructor TACLCodePages.Create;
begin
  inherited Create;
  FList := TStringList.Create;
  LCodePages := Self;
  EnumSystemCodePagesW(@EnumCodePagesProc, CP_INSTALLED);
  LCodePages := nil;
  FList.CustomSort(CompareCodePages);
end;

destructor TACLCodePages.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

function TACLCodePages.IndexOf(ACodePageID: Integer): Integer;
begin
  Result := FList.IndexOfObject(TObject(ACodePageID));
end;

procedure TACLCodePages.AddCodePage(ID: Cardinal);
var
  AInfo: TCPInfoEx;
begin
  if GetCPInfoEx(ID, 0, AInfo) then
    FList.AddObject(AInfo.CodePageName, TObject(ID));
end;

class function TACLCodePages.CompareCodePages(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := acLogicalCompare(List[Index1], List[Index2]);
end;

class function TACLCodePages.EnumCodePagesProc(lpCodePageString: PWideChar): Cardinal; stdcall;
var
  ACodePage: Integer;
begin
  ACodePage := StrToIntDef(lpCodePageString, -1);
  if ACodePage > 0 then
    LCodePages.AddCodePage(ACodePage);
  Result := 1;
end;

function TACLCodePages.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TACLCodePages.GetID(Index: Integer): Integer;
begin
  Result := Integer(FList.Objects[Index]);
end;

function TACLCodePages.GetName(Index: Integer): string;
begin
  Result := FList[Index];
end;

initialization
  LangFilePath := acSelfPath + 'Langs' + PathDelim;

finalization
  FreeAndNil(FLangFile);
  FreeAndNil(FCodePages);
end.
