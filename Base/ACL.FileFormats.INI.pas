////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Fast-way cross platform INI-file implementation
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.FileFormats.INI;

{$I ACL.Config.inc}
{$POINTERMATH ON}

interface

uses
{$IFDEF MSWINDOWS}
  {Winapi.}Windows,
{$ELSE}
  LCLIntf,
  LCLType,
{$ENDIF}
  // Vcl
{$IFNDEF ACL_BASE_NOVCL}
  {Vcl.}Graphics,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}SysUtils,
  {System.}Types,
  {System.}TypInfo,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Hashes,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Stream,
  ACL.Utils.Strings;

type

  { TACLIniFileSection }

  TACLIniFileSection = class(TACLStringList)
  strict private
    FLockCount: Integer;
    FName: string;
    FNameHash: Integer;

    function GetValueFromName(const Name: string): string;
    procedure SetName(const AValue: string);
  protected
    FOnChange: TNotifyEvent;

    procedure CalculateNameHash;
    procedure Changed; override;
    function FindValue(const AName: string; out AIndex: Integer): Boolean; overload;
    function FindValue(const AName: string; ANameHash: Integer; out AIndex: Integer): Boolean; overload;
    //
    property NameHash: Integer read FNameHash;
  public
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
    // Deleting
    function Delete(const AKey: string): Boolean; overload;
    // Reading
    function ReadBool(const AKey: string; ADefault: Boolean = False): Boolean;
    function ReadEnum<T>(const AKey: string; const ADefault: T): T;
    function ReadFloat(const AKey: string; const ADefault: Double = 0): Double;
    function ReadInt32(const AKey: string; ADefault: Integer = 0): Integer; virtual;
    function ReadInt64(const AKey: string; const ADefault: Int64 = 0): Int64;
    function ReadRect(const AKey: string): TRect; overload;
    function ReadRect(const AKey: string; const ADefault: TRect): TRect; overload;
    function ReadSize(const AKey: string): TSize;
    function ReadStream(const AKey: string; AStream: TStream): Boolean;
    function ReadString(const AKey: string; const ADefault: string = ''): string;
    function ReadStringEx(const AKey: string; out AValue: string): Boolean; virtual;
  {$IFNDEF ACL_BASE_NOVCL}
    function ReadColor(const AKey: string; ADefault: TColor = clDefault): TColor;
    function ReadFont(const AKey: string; AFont: TFont): Boolean;
  {$ENDIF}
    // Writing
    procedure WriteBool(const AKey: string; const AValue: Boolean); overload;
    procedure WriteBool(const AKey: string; const AValue, ADefaultValue: Boolean); overload;
    procedure WriteEnum<T>(const AKey: string; const AValue: T); overload;
    procedure WriteEnum<T>(const AKey: string; const AValue, ADefaultValue: T); overload;
    procedure WriteFloat(const AKey: string; const AValue: Double);
    procedure WriteInt64(const AKey: string; const AValue: Int64); overload;
    procedure WriteInt64(const AKey: string; const AValue, ADefaultValue: Int64); overload;
    procedure WriteInt32(const AKey: string; const AValue: Integer); overload;
    procedure WriteInt32(const AKey: string; const AValue, ADefaultValue: Integer); overload;
    procedure WriteRect(const AKey: string; const AValue: TRect);
    procedure WriteSize(const AKey: string; const AValue: TSize);
    procedure WriteStream(const AKey: string; AStream: TStream);
    procedure WriteString(const AKey, AValue: string); overload; virtual;
    procedure WriteString(const AKey, AValue, ADefaultValue: string); overload;
  {$IFNDEF ACL_BASE_NOVCL}
    procedure WriteColor(const AKey: string; AColor: TColor);
    procedure WriteFont(const AKey: string; AFont: TFont);
  {$ENDIF}
    // Properties
    property Name: string read FName write SetName;
    property ValueFromName[const Name: string]: string read GetValueFromName write WriteString;
  end;

  { TACLIniFile }

  TACLIniFile = class(TACLUnknownObject)
  strict private
    FAutoSave: Boolean;
    FChangeLockCount: Integer;
    FEncoding: TEncoding;
    FFileName: string;
    FPrevSection: TACLIniFileSection;

    FOnChanged: TNotifyEvent;

    function GetName(AIndex: Integer): string;
    function GetSectionCount: Integer;
    function GetSectionData(const ASection: string): string;
    function GetSectionObj(Index: Integer): TACLIniFileSection;
    procedure SectionChangeHandler(Sender: TObject);
    procedure SetFileName(const AValue: string);
    procedure SetSectionData(const ASection, AData: string);
  protected
    FModified: Boolean;
    FSections: TACLObjectList<TACLIniFileSection>;

    function FindValue(const AName, AKey: string;
      out ASection: TACLIniFileSection; out AIndex: Integer): Boolean;
    procedure Changed; virtual;
  public
    constructor Create; overload;
    constructor Create(const AFileName: string; AutoSave: Boolean = True); overload; virtual;
    destructor Destroy; override;
    procedure Assign(AIniFile: TACLIniFile);
    procedure Merge(const AFileName: string; AOverwriteExisting: Boolean = True); overload;
    procedure Merge(const AIniFile: TACLIniFile; AOverwriteExisting: Boolean = True); overload;
    function Equals(Obj: TObject): Boolean; override;

    procedure BeginUpdate;
    procedure EndUpdate;

    // Checking for Exists
    function ExistsKey(const ASection, AKey: string): Boolean; virtual;
    function ExistsSection(const ASection: string): Boolean; virtual;
    function IsEmpty: Boolean; virtual;

    // Sections
    function GetSection(const AName: string; ACanCreate: Boolean = False): TACLIniFileSection;

    // Reading
    function ReadBool(const ASection, AKey: string; ADefault: Boolean = False): Boolean;
    function ReadEnum<T>(const ASection, AKey: string; const ADefault: T): T;
    function ReadFloat(const ASection, AKey: string; const ADefault: Double = 0): Double;
    function ReadInteger(const ASection, AKey: string; ADefault: Integer = 0): Integer; virtual;
    function ReadInt64(const ASection, AKey: string; const ADefault: Int64 = 0): Int64;
    function ReadObject(const ASection, AKey: string; ALoadProc: TACLStreamProc): Boolean;
    function ReadRect(const ASection, AKey: string): TRect; overload;
    function ReadRect(const ASection, AKey: string; const ADefault: TRect): TRect; overload;
    function ReadSize(const ASection, AKey: string): TSize;
    function ReadStream(const ASection, AKey: string; AStream: TStream): Boolean;
    function ReadString(const ASection, AKey: string; const ADefault: string = ''): string;
    function ReadStringEx(const ASection, AKey: string; out AValue: string): Boolean; virtual;
    function ReadStrings(const ASection: string; AStrings: TACLStringList): Integer; overload;
    function ReadStrings(const ASection: string; AStrings: TStrings): Integer; overload;
  {$IFNDEF ACL_BASE_NOVCL}
    function ReadColor(const ASection, AKey: string; ADefault: TColor = clDefault): TColor;
    function ReadFont(const ASection, AKey: string; AFont: TFont): Boolean;
  {$ENDIF}
    procedure ReadKeys(const ASection: string; AKeys: TACLStringList); overload;
    procedure ReadKeys(const ASection: string; AProc: TACLStringEnumProc); overload;

    // Writing
    procedure WriteBool(const ASection, AKey: string; AValue, ADefaultValue: Boolean); overload;
    procedure WriteBool(const ASection, AKey: string; AValue: Boolean); overload;
    procedure WriteEnum<T>(const ASection, AKey: string; const AValue: T); overload;
    procedure WriteEnum<T>(const ASection, AKey: string; const AValue, ADefaultValue: T); overload;
    procedure WriteFloat(const ASection, AKey: string; const AValue: Double);
    procedure WriteInt64(const ASection, AKey: string; const AValue, ADefaultValue: Int64); overload;
    procedure WriteInt64(const ASection, AKey: string; const AValue: Int64); overload;
    procedure WriteInteger(const ASection, AKey: string; AValue, ADefaultValue: Integer); overload;
    procedure WriteInteger(const ASection, AKey: string; AValue: Integer); overload;
    procedure WriteObject(const ASection, AKey: string; ASaveProc: TACLStreamProc);
    procedure WriteRect(const ASection, AKey: string; const AValue: TRect);
    procedure WriteSize(const ASection, AKey: string; const AValue: TSize);
    procedure WriteStream(const ASection, AKey: string; AStream: TStream);
    procedure WriteString(const ASection, AKey, AValue, ADefaultValue: string); overload;
    procedure WriteString(const ASection, AKey, AValue: string); overload; virtual;
    procedure WriteStrings(const ASection: string; AStrings: TACLStringList); overload;
    procedure WriteStrings(const ASection: string; AStrings: TStrings); overload;
  {$IFNDEF ACL_BASE_NOVCL}
    procedure WriteColor(const ASection, AKey: string; AColor: TColor);
    procedure WriteFont(const ASection, AKey: string; AFont: TFont);
  {$ENDIF}

    // Delete
    procedure Clear;
    function DeleteKey(const ASection, AKey: string): Boolean;
    function DeleteSection(const AName: string): Boolean;

    // Rename
    procedure RenameKey(const ASection, AKeyName, ANewKeyName: string); overload;
    procedure RenameKey(const ASection, AKeyName, ANewSection, ANewKeyName: string); overload;
    procedure RenameSection(const ASection, ANewName: string);

    // Load/Save
    procedure LoadFromFile(const AFileName: string); virtual;
    procedure LoadFromResource(Inst: HModule; const AName: string; AType: PChar);
    procedure LoadFromStream(AStream: TStream); virtual;
    procedure LoadFromString(const AString: string); overload;
    procedure LoadFromString(const AString: PChar; ACount: Integer); overload; virtual;
    function SaveToFile(const AFileName: string; AEncoding: TEncoding = nil): Boolean;
    procedure SaveToStream(AStream: TStream); overload;
    procedure SaveToStream(AStream: TStream; AEncoding: TEncoding); overload; virtual;
    function UpdateFile: Boolean; virtual;
    //# Properties
    property AutoSave: Boolean read FAutoSave write FAutoSave;
    property Encoding: TEncoding read FEncoding write FEncoding;
    property FileName: string read FFileName write SetFileName;
    property Modified: Boolean read FModified write FModified;
    //# Sections
    property SectionCount: Integer read GetSectionCount;
    property SectionData[const ASection: string]: string read GetSectionData write SetSectionData;
    property SectionObjs[Index: Integer]: TACLIniFileSection read GetSectionObj;
    property Sections[Index: Integer]: string read GetName;
    //# Events
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  { TACLSyncSafeIniFile }

  TACLSyncSafeIniFile = class(TACLIniFile)
  strict private
    function GetBackupFileName: string;
  public
    constructor Create(const AFileName: string; {%H-}AAutoSave: Boolean = True); override;
    function UpdateFile: Boolean; override;
  end;

implementation

uses
  Math;

{ TACLIniFileSection }

procedure TACLIniFileSection.BeginUpdate;
begin
  Inc(FLockCount);
end;

procedure TACLIniFileSection.EndUpdate;
begin
  Dec(FLockCount);
  if FLockCount = 0 then
    Changed;
end;

function TACLIniFileSection.Delete(const AKey: string): Boolean;
var
  AIndex: Integer;
begin
  Result := FindValue(AKey, AIndex);
  if Result then
    Delete(AIndex);
end;

function TACLIniFileSection.ReadBool(const AKey: string; ADefault: Boolean): Boolean;
var
  AIndex: Integer;
begin
  if FindValue(AKey, AIndex) then
    Result := StrToIntDef(ValueFromIndex[AIndex], Ord(ADefault)) <> 0
  else
    Result := ADefault;
end;

function TACLIniFileSection.ReadEnum<T>(const AKey: string; const ADefault: T): T;
var
  AValue: Integer;
begin
  if FindValue(AKey, AValue) and TryStrToInt(ValueFromIndex[AValue], AValue) then
    Result := TACLEnumHelper.SetValue<T>(AValue)
  else
    Result := ADefault;
end;

function TACLIniFileSection.ReadFloat(const AKey: string; const ADefault: Double): Double;
var
  AData: string;
  AValue: Extended;
begin
  try
    AData := ReadString(AKey);
    if not TextToFloat({$IFDEF FPC}PChar{$ENDIF}(AData), AValue, InvariantFormatSettings) then
    begin
      if not TextToFloat({$IFDEF FPC}PChar{$ENDIF}(AData), AValue) then // Backward compatibility
        AValue := ADefault;
    end;
    Result := AValue;
  except
    Result := ADefault;
  end;
end;

function TACLIniFileSection.ReadInt32(const AKey: string; ADefault: Integer): Integer;
var
  AIndex: Integer;
begin
  if FindValue(AKey, AIndex) then
    Result := StrToIntDef(ValueFromIndex[AIndex], ADefault)
  else
    Result := ADefault;
end;

function TACLIniFileSection.ReadInt64(const AKey: string; const ADefault: Int64): Int64;
var
  AIndex: Integer;
begin
  if FindValue(AKey, AIndex) then
    Result := StrToInt64Def(ValueFromIndex[AIndex], ADefault)
  else
    Result := ADefault;
end;

function TACLIniFileSection.ReadRect(const AKey: string): TRect;
begin
  Result := ReadRect(AKey, NullRect);
end;

function TACLIniFileSection.ReadRect(const AKey: string; const ADefault: TRect): TRect;
var
  AIndex: Integer;
begin
  if FindValue(AKey, AIndex) then
    Result := acStringToRect(ValueFromIndex[AIndex])
  else
    Result := ADefault;
end;

function TACLIniFileSection.ReadSize(const AKey: string): TSize;
begin
  Result := acStringToSize(ReadString(AKey));
end;

function TACLIniFileSection.ReadStream(const AKey: string; AStream: TStream): Boolean;
begin
  Result := TACLHexCode.Decode(ReadString(AKey), AStream);
  if Result then
    AStream.Position := 0;
end;

function TACLIniFileSection.ReadString(const AKey, ADefault: string): string;
var
  AIndex: Integer;
begin
  if FindValue(AKey, AIndex) then
    Result := ValueFromIndex[AIndex]
  else
    Result := ADefault;
end;

function TACLIniFileSection.ReadStringEx(const AKey: string; out AValue: string): Boolean;
var
  AIndex: Integer;
begin
  Result := FindValue(AKey, AIndex);
  if Result then
    AValue := ValueFromIndex[AIndex]
end;

procedure TACLIniFileSection.WriteBool(const AKey: string; const AValue: Boolean);
begin
  WriteInt32(AKey, Ord(AValue));
end;

procedure TACLIniFileSection.WriteBool(const AKey: string; const AValue, ADefaultValue: Boolean);
begin
  if AValue <> ADefaultValue then
    WriteBool(AKey, AValue)
  else
    Delete(AKey);
end;

procedure TACLIniFileSection.WriteEnum<T>(const AKey: string; const AValue: T);
begin
  WriteInt32(AKey, TACLEnumHelper.GetValue<T>(AValue));
end;

procedure TACLIniFileSection.WriteEnum<T>(const AKey: string; const AValue, ADefaultValue: T);
var
  LValue1: Integer;
  LValue2: Integer;
begin
  LValue1 := TACLEnumHelper.GetValue<T>(AValue);
  LValue2 := TACLEnumHelper.GetValue<T>(ADefaultValue);
  if LValue1 <> LValue2 then
    WriteInt32(AKey, LValue1)
  else
    Delete(AKey);
end;

procedure TACLIniFileSection.WriteFloat(const AKey: string; const AValue: Double);
begin
  WriteString(AKey, FloatToStr(AValue, InvariantFormatSettings));
end;

procedure TACLIniFileSection.WriteInt32(const AKey: string; const AValue: Integer);
begin
  WriteString(AKey, IntToStr(AValue));
end;

procedure TACLIniFileSection.WriteInt32(const AKey: string; const AValue, ADefaultValue: Integer);
begin
  if AValue <> ADefaultValue then
    WriteInt32(AKey, AValue)
  else
    Delete(AKey);
end;

procedure TACLIniFileSection.WriteInt64(const AKey: string; const AValue, ADefaultValue: Int64);
begin
  if AValue <> ADefaultValue then
    WriteInt64(AKey, AValue)
  else
    Delete(AKey);
end;

procedure TACLIniFileSection.WriteInt64(const AKey: string; const AValue: Int64);
begin
  WriteString(AKey, IntToStr(AValue));
end;

procedure TACLIniFileSection.WriteRect(const AKey: string; const AValue: TRect);
begin
  WriteString(AKey, acRectToString(AValue));
end;

procedure TACLIniFileSection.WriteSize(const AKey: string; const AValue: TSize);
begin
  WriteString(AKey, acSizeToString(AValue));
end;

procedure TACLIniFileSection.WriteStream(const AKey: string; AStream: TStream);
begin
  WriteString(AKey, TACLHexCode.Encode(AStream), '');
end;

procedure TACLIniFileSection.WriteString(const AKey, AValue, ADefaultValue: string);
begin
  if AValue <> ADefaultValue then
    WriteString(AKey, AValue)
  else
    Delete(AKey);
end;

procedure TACLIniFileSection.WriteString(const AKey, AValue: string);
var
  AIndex: Integer;
  AKeyHash: Integer;
begin
  AKeyHash := ElfHash(AKey);
  if FindValue(AKey, AKeyHash, AIndex) then
  begin
    List^[AIndex].FString := AKey + Delimiter + AValue;
    List^[AIndex].FObject := TObject(AKeyHash);
    Changed;
  end
  else
    Add(AKey + Delimiter + AValue, AKeyHash);
end;

{$IFNDEF ACL_BASE_NOVCL}
function TACLIniFileSection.ReadColor(const AKey: string; ADefault: TColor): TColor;
var
  A: array[0..2] of Integer;
begin
  case acExplodeStringAsIntegerArray(ReadString(AKey), ',', @A[0], Length(A)) of
    0: Result := ADefault;
    1: Result := A[0];
    else
      Result := RGB(A[0], A[1], A[2]);
  end;
end;

function TACLIniFileSection.ReadFont(const AKey: string; AFont: TFont): Boolean;
var
  AFontStr: string;
begin
  Result := ReadStringEx(AKey, AFontStr);
  if Result then
    acStringToFont(AFontStr, AFont);
end;

procedure TACLIniFileSection.WriteColor(const AKey: string; AColor: TColor);
begin
  AColor := ColorToRGB(AColor);
  WriteString(AKey, IntToStr(GetRValue(AColor)) + ',' + IntToStr(GetGValue(AColor)) + ',' + IntToStr(GetBValue(AColor)));
end;

procedure TACLIniFileSection.WriteFont(const AKey: string; AFont: TFont);
begin
  WriteString(AKey, acFontToString(AFont));
end;
{$ENDIF}

procedure TACLIniFileSection.CalculateNameHash;
begin
  FNameHash := ElfHash(Name);
end;

procedure TACLIniFileSection.Changed;
begin
  if FLockCount = 0 then
    CallNotifyEvent(Self, FOnChange);
end;

function TACLIniFileSection.FindValue(const AName: string; out AIndex: Integer): Boolean;
begin
  Result := (Count > 0) and FindValue(AName, ElfHash(AName), AIndex)
end;

function TACLIniFileSection.FindValue(const AName: string; ANameHash: Integer; out AIndex: Integer): Boolean;
var
  AKeyHash: Integer;
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    AKeyHash := NativeUInt(List^[I].FObject);
    if AKeyHash = 0 then
    begin
      AKeyHash := ElfHash(Names[I]);
      List^[I].FObject := TObject(AKeyHash);
    end;
    if (AKeyHash = ANameHash) and acSameText(AName, Names[I]) then
    begin
      AIndex := I;
      Exit(True);
    end;
  end;
  Result := False;
end;

function TACLIniFileSection.GetValueFromName(const Name: string): string;
var
  AIndex: Integer;
begin
  if FindValue(Name, AIndex) then
    Result := ValueFromIndex[AIndex]
  else
    Result := '';
end;

procedure TACLIniFileSection.SetName(const AValue: string);
begin
  if AValue <> Name then
  begin
    FName := AValue;
    FNameHash := 0;
    Changed;
  end;
end;

{ TACLIniFile }

constructor TACLIniFile.Create;
begin
  Create('', False);
end;

constructor TACLIniFile.Create(const AFileName: string; AutoSave: Boolean = True);
begin
  inherited Create;
  FAutoSave := AutoSave;
  FEncoding := TEncoding.Unicode;
  FFileName := AFileName;
  FSections := TACLObjectList<TACLIniFileSection>.Create;
  if AFileName <> '' then
    LoadFromFile(AFileName);
end;

destructor TACLIniFile.Destroy;
begin
  if AutoSave then
    UpdateFile;
  FreeAndNil(FSections);
  inherited Destroy;
end;

procedure TACLIniFile.Assign(AIniFile: TACLIniFile);
var
  M: TMemoryStream;
begin
  Clear;
  if AIniFile <> nil then
  begin
    M := TMemoryStream.Create;
    try
      AIniFile.SaveToStream(M);
      M.Position := 0;
      LoadFromStream(M);
    finally
      M.Free;
    end;
  end;
end;

procedure TACLIniFile.Merge(const AFileName: string; AOverwriteExisting: Boolean);
var
  AIniFile: TACLIniFile;
begin
  AIniFile := TACLIniFile.Create(AFileName, False);
  try
    Merge(AIniFile, AOverwriteExisting);
  finally
    AIniFile.Free;
  end;
end;

procedure TACLIniFile.Merge(const AIniFile: TACLIniFile; AOverwriteExisting: Boolean = True);

  procedure MergeSection(const ASection: string);
  var
    AKey: string;
    AKeys: TACLStringList;
    I: Integer;
  begin
    if ExistsSection(ASection) then
    begin
      AKeys := TACLStringList.Create;
      try
        AIniFile.ReadKeys(ASection, AKeys);
        for I := 0 to AKeys.Count - 1 do
        begin
          AKey := AKeys[I];
          if AOverwriteExisting or not ExistsKey(ASection, AKey) then
            WriteString(ASection, AKey, AIniFile.ReadString(ASection, AKey));
        end;
      finally
        AKeys.Free;
      end;
    end
    else
      SectionData[ASection] := AIniFile.SectionData[ASection];
  end;

var
  I: Integer;
begin
  for I := 0 to AIniFile.SectionCount - 1 do
    MergeSection(AIniFile.Sections[I]);
end;

function TACLIniFile.Equals(Obj: TObject): Boolean;
var
  M1, M2: TMemoryStream;
begin
  Result := False;
  if Obj is TACLIniFile then
  begin
    M1 := TMemoryStream.Create;
    M2 := TMemoryStream.Create;
    try
      SaveToStream(M1);
      TACLIniFile(Obj).SaveToStream(M2);
      Result := (M1.Size = M2.Size) and CompareMem(M1.Memory, M2.Memory, M1.Size);
    finally
      M1.Free;
      M2.Free;
    end;
  end;
end;

procedure TACLIniFile.BeginUpdate;
begin
  Inc(FChangeLockCount);
end;

procedure TACLIniFile.EndUpdate;
begin
  Dec(FChangeLockCount);
  if FChangeLockCount = 0 then
    Changed;
end;

function TACLIniFile.ExistsKey(const ASection, AKey: string): Boolean;
var
  AIndex: Integer;
  AList: TACLIniFileSection;
begin
  Result := FindValue(ASection, AKey, AList, AIndex);
end;

function TACLIniFile.ExistsSection(const ASection: string): Boolean;
begin
  Result := GetSection(ASection) <> nil;
end;

function TACLIniFile.IsEmpty: Boolean;
begin
  Result := SectionCount = 0;
end;

function TACLIniFile.ReadBool(const ASection, AKey: string; ADefault: Boolean = False): Boolean;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadBool(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadEnum<T>(const ASection, AKey: string; const ADefault: T): T;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadEnum<T>(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadFloat(const ASection, AKey: string; const ADefault: Double = 0): Double;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadFloat(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadInteger(const ASection, AKey: string; ADefault: Integer = 0): Integer;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadInt32(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadInt64(const ASection, AKey: string; const ADefault: Int64 = 0): Int64;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadInt64(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadRect(const ASection, AKey: string): TRect;
begin
  Result := ReadRect(ASection, AKey, NullRect);
end;

function TACLIniFile.ReadRect(const ASection, AKey: string; const ADefault: TRect): TRect;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadRect(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadSize(const ASection, AKey: string): TSize;
begin
  Result := acStringToSize(ReadString(ASection, AKey));
end;

function TACLIniFile.ReadStream(const ASection, AKey: string; AStream: TStream): Boolean;
begin
  Result := TACLHexCode.Decode(ReadString(ASection, AKey), AStream);
  if Result then
    AStream.Position := 0;
end;

function TACLIniFile.ReadString(const ASection, AKey: string; const ADefault: string = ''): string;
begin
  if not ReadStringEx(ASection, AKey, Result) then
    Result := ADefault;
end;

function TACLIniFile.ReadStringEx(const ASection, AKey: string; out AValue: string): Boolean;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  Result := (ASectionObj <> nil) and ASectionObj.ReadStringEx(AKey, AValue);
end;

function TACLIniFile.ReadStrings(const ASection: string; AStrings: TACLStringList): Integer;
var
  ACount: Integer;
  AList: TACLIniFileSection;
  AValueIndex: Integer;
  I: Integer;
begin
  AStrings.Clear;
  AList := GetSection(ASection);
  if AList <> nil then
  begin
    if AList.FindValue('Count', AValueIndex) then
    begin
      ACount := StrToIntDef(AList.ValueFromIndex[AValueIndex], 0);
      AStrings.Capacity := ACount;
      for I := 1 to ACount do
        AStrings.Add(AList.ValueFromName['i' + IntToStr(I)]);
    end
    else
      AStrings.Text := AList.Text; // backward compatibility
  end;
  Result := AStrings.Count;
end;

function TACLIniFile.ReadStrings(const ASection: string; AStrings: TStrings): Integer;
var
  ACount: Integer;
  AList: TACLIniFileSection;
  AValueIndex: Integer;
  I: Integer;
begin
  AStrings.Clear;
  AList := GetSection(ASection);
  if AList <> nil then
  begin
    if AList.FindValue('Count', AValueIndex) then
    begin
      ACount := StrToIntDef(AList.ValueFromIndex[AValueIndex], 0);
      AStrings.Capacity := ACount;
      for I := 1 to ACount do
        AStrings.Add(AList.ValueFromName['i' + IntToStr(I)]);
    end
    else
      AStrings.Text := AList.Text; // backward compatibility
  end;
  Result := AStrings.Count;
end;

{$IFNDEF ACL_BASE_NOVCL}
function TACLIniFile.ReadColor(const ASection, AKey: string; ADefault: TColor = clDefault): TColor;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadColor(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadFont(const ASection, AKey: string; AFont: TFont): Boolean;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  Result := (ASectionObj <> nil) and ASectionObj.ReadFont(AKey, AFont);
end;
{$ENDIF}

procedure TACLIniFile.ReadKeys(const ASection: string; AKeys: TACLStringList);
var
  AList: TACLIniFileSection;
  AName: string;
  I: Integer;
begin
  AList := GetSection(ASection);
  if AList <> nil then
  begin
    AKeys.EnsureCapacity(AList.Count);
    for I := 0 to AList.Count - 1 do
    begin
      AName := AList.Names[I];
      if AName <> '' then
        AKeys.Add(AName);
    end;
  end;
end;

procedure TACLIniFile.ReadKeys(const ASection: string; AProc: TACLStringEnumProc);
var
  AList: TACLIniFileSection;
  AName: string;
  I: Integer;
begin
  AList := GetSection(ASection);
  if AList <> nil then
    for I := 0 to AList.Count - 1 do
    begin
      AName := AList.Names[I];
      if AName <> '' then
        AProc(AName);
    end;
end;

function TACLIniFile.ReadObject(const ASection, AKey: string; ALoadProc: TACLStreamProc): Boolean;
var
  AStream: TMemoryStream;
begin
  try
    AStream := TMemoryStream.Create;
    try
      Result := ReadStream(ASection, AKey, AStream) and (AStream.Size > 0);
      if Result then
      begin
        AStream.Position := 0;
        ALoadProc(AStream);
      end;
    finally
      AStream.Free;
    end;
  except
    Result := False;
  end;
end;

procedure TACLIniFile.WriteBool(const ASection, AKey: string; AValue: Boolean);
begin
  WriteInteger(ASection, AKey, Ord(AValue));
end;

procedure TACLIniFile.WriteEnum<T>(const ASection, AKey: string; const AValue: T);
begin
  GetSection(ASection, True).WriteEnum<T>(AKey, AValue);
end;

procedure TACLIniFile.WriteEnum<T>(const ASection, AKey: string; const AValue, ADefaultValue: T);
var
  LValue1: Integer;
  LValue2: Integer;
begin
  LValue1 := TACLEnumHelper.GetValue<T>(AValue);
  LValue2 := TACLEnumHelper.GetValue<T>(ADefaultValue);
  if LValue1 <> LValue2 then
    WriteInteger(ASection, AKey, LValue1)
  else
    DeleteKey(ASection, AKey);
end;

procedure TACLIniFile.WriteBool(const ASection, AKey: string; AValue, ADefaultValue: Boolean);
begin
  WriteInteger(ASection, AKey, Ord(AValue), Ord(ADefaultValue));
end;

procedure TACLIniFile.WriteFloat(const ASection, AKey: string; const AValue: Double);
begin
  WriteString(ASection, AKey, FloatToStr(AValue, InvariantFormatSettings));
end;

procedure TACLIniFile.WriteInteger(const ASection, AKey: string; AValue: Integer);
begin
  WriteString(ASection, AKey, IntToStr(AValue));
end;

procedure TACLIniFile.WriteInteger(const ASection, AKey: string; AValue, ADefaultValue: Integer);
begin
  if AValue <> ADefaultValue then
    WriteInteger(ASection, AKey, AValue)
  else
    DeleteKey(ASection, AKey);
end;

procedure TACLIniFile.WriteInt64(const ASection, AKey: string; const AValue: Int64);
begin
  WriteString(ASection, AKey, IntToStr(AValue));
end;

procedure TACLIniFile.WriteInt64(const ASection, AKey: string; const AValue, ADefaultValue: Int64);
begin
  if AValue <> ADefaultValue then
    WriteInt64(ASection, AKey, AValue)
  else
    DeleteKey(ASection, AKey);
end;

procedure TACLIniFile.WriteObject(const ASection, AKey: string; ASaveProc: TACLStreamProc);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    ASaveProc(AStream);
    if AStream.Size > 0 then
    begin
      AStream.Position := 0;
      WriteStream(ASection, AKey, AStream);
    end;
  finally
    AStream.Free;
  end;
end;

procedure TACLIniFile.WriteRect(const ASection, AKey: string; const AValue: TRect);
begin
  WriteString(ASection, AKey, acRectToString(AValue));
end;

procedure TACLIniFile.WriteSize(const ASection, AKey: string; const AValue: TSize);
begin
  WriteString(ASection, AKey, acSizeToString(AValue));
end;

procedure TACLIniFile.WriteStream(const ASection, AKey: string; AStream: TStream);
begin
  WriteString(ASection, AKey, TACLHexCode.Encode(AStream), '');
end;

procedure TACLIniFile.WriteString(const ASection, AKey, AValue: string);
begin
  BeginUpdate;
  try
    GetSection(ASection, True).WriteString(AKey, AValue);
  finally
    EndUpdate;
  end;
end;

procedure TACLIniFile.WriteStrings(const ASection: string; AStrings: TACLStringList);
var
  AList: TACLIniFileSection;
  I: Integer;
begin
  BeginUpdate;
  try
    AList := GetSection(ASection, True);
    AList.Clear;
    AList.Capacity := AStrings.Count;
    AList.WriteString('Count', IntToStr(AStrings.Count));
    for I := 0 to AStrings.Count - 1 do
      AList.WriteString('i' + IntToStr(I + 1), AStrings[I]);
  finally
    EndUpdate;
  end;
end;

procedure TACLIniFile.WriteStrings(const ASection: string; AStrings: TStrings);
var
  AList: TACLIniFileSection;
  I: Integer;
begin
  BeginUpdate;
  try
    AList := GetSection(ASection, True);
    AList.Clear;
    AList.Capacity := AStrings.Count;
    AList.WriteString('Count', IntToStr(AStrings.Count));
    for I := 0 to AStrings.Count - 1 do
      AList.WriteString('i' + IntToStr(I + 1), AStrings[I]);
  finally
    EndUpdate;
  end;
end;

procedure TACLIniFile.WriteString(const ASection, AKey, AValue, ADefaultValue: string);
begin
  if AValue <> ADefaultValue then
    WriteString(ASection, AKey, AValue)
  else
    DeleteKey(ASection, AKey);
end;

{$IFNDEF ACL_BASE_NOVCL}
procedure TACLIniFile.WriteColor(const ASection, AKey: string; AColor: TColor);
begin
  GetSection(ASection, True).WriteColor(AKey, AColor);
end;

procedure TACLIniFile.WriteFont(const ASection, AKey: string; AFont: TFont);
begin
  GetSection(ASection, True).WriteFont(AKey, AFont);
end;
{$ENDIF}

procedure TACLIniFile.Clear;
begin
  BeginUpdate;
  try
    FPrevSection := nil;
    FSections.Clear;
    Changed;
  finally
    EndUpdate;
  end;
end;

function TACLIniFile.DeleteKey(const ASection, AKey: string): Boolean;
var
  AList: TACLIniFileSection;
begin
  AList := GetSection(ASection);
  Result := (AList <> nil) and AList.Delete(AKey);
end;

function TACLIniFile.DeleteSection(const AName: string): Boolean;
var
  ASection: TACLIniFileSection;
begin
  ASection := GetSection(AName);
  Result := ASection <> nil;
  if Result then
  begin
    if ASection = FPrevSection then
      FPrevSection := nil;
    FSections.Remove(ASection);
    Changed;
  end;
end;

procedure TACLIniFile.RenameKey(const ASection, AKeyName, ANewKeyName: string);
begin
  RenameKey(ASection, AKeyName, ASection, ANewKeyName);
end;

procedure TACLIniFile.RenameKey(const ASection, AKeyName, ANewSection, ANewKeyName: string);
var
  AIndex: Integer;
  AList: TACLIniFileSection;
  AValue: string;
begin
  if FindValue(ASection, AKeyName, AList, AIndex) then
  begin
    BeginUpdate;
    try
      AValue := AList.ValueFromIndex[AIndex];
      AList.Delete(AIndex);
      WriteString(ANewSection, ANewKeyName, AValue);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TACLIniFile.RenameSection(const ASection, ANewName: string);
var
  AList: TACLIniFileSection;
begin
  AList := GetSection(ASection);
  if AList <> nil then
    AList.Name := ANewName;
end;

procedure TACLIniFile.LoadFromFile(const AFileName: string);
var
  AStream: TStream;
begin
  BeginUpdate;
  try
    Clear;
    FFileName := AFileName;
    if StreamCreateReader(AFileName, AStream) then
    try
      LoadFromStream(AStream);
    finally
      AStream.Free;
    end;
  finally
    EndUpdate;
    FModified := False;
  end;
end;

procedure TACLIniFile.LoadFromResource(Inst: HModule; const AName: string; AType: PChar);
var
  AResStream: TStream;
begin
  AResStream := TResourceStream.Create(Inst, AName, AType);
  try
    LoadFromStream(AResStream);
  finally
    AResStream.Free;
  end;
end;

procedure TACLIniFile.LoadFromStream(AStream: TStream);
begin
  LoadFromString(acLoadString(AStream, nil, FEncoding));
end;

procedure TACLIniFile.LoadFromString(const AString: string);
begin
  LoadFromString(PChar(AString), Length(AString));
end;

function TACLIniFile.SaveToFile(const AFileName: string; AEncoding: TEncoding = nil): Boolean;
var
  AStream: TStream;
begin
  acFileSetAttr(AFileName, 0);
  Result := StreamCreateWriter(AFileName, AStream);
  if Result then
  try
    SaveToStream(AStream, AEncoding);
  finally
    AStream.Free;
  end;
end;

procedure TACLIniFile.SaveToStream(AStream: TStream);
begin
  SaveToStream(AStream, TEncoding.Unicode);
end;

procedure TACLIniFile.SaveToStream(AStream: TStream; AEncoding: TEncoding);
var
  LSection: TACLIniFileSection;
  I, J: Integer;
begin
  if AEncoding = TEncoding.Unicode then
    AEncoding := nil; // TACLStreamHelper will operate in more optimal way

  AStream.WriteBOM(AEncoding);
  for I := 0 to FSections.Count - 1 do
  begin
    LSection := FSections.List[I];
    if LSection.Count > 0 then
    begin
      // We cannot use that because of SectionData[''] allow us to set raw data
      // LSection.SortLogical;
      AStream.WriteString('[' + LSection.Name + ']', AEncoding);
      AStream.WriteString(acCRLF, AEncoding);
      for J := 0 to LSection.Count - 1 do
      begin
        AStream.WriteString(LSection.Strings[J], AEncoding);
        AStream.WriteString(acCRLF, AEncoding);
      end;
      AStream.WriteString(acCRLF, AEncoding);
    end;
  end;
end;

function TACLIniFile.UpdateFile: Boolean;
begin
  Result := FFileName <> '';
  if Result and Modified then
  begin
    Result := SaveToFile(FFileName, Encoding);
    if Result then
      FModified := False;
  end;
end;

function TACLIniFile.GetSection(const AName: string; ACanCreate: Boolean): TACLIniFileSection;
var
  AHash: Integer;
  ASection: TACLIniFileSection;
  I: Integer;
begin
  Result := nil;

  if FSections.Count > 0 then
  begin
    if (FPrevSection <> nil) and acSameText(FPrevSection.Name, AName) then
      Exit(FPrevSection);

    AHash := ElfHash(AName);
    for I := 0 to FSections.Count - 1 do
    begin
      ASection := FSections.List[I];
      if ASection.NameHash = 0 then
        ASection.CalculateNameHash;
      if (ASection.NameHash = AHash) and acSameText(ASection.Name, AName) then
      begin
        FPrevSection := ASection;
        Exit(FPrevSection);
      end;
    end;
  end;

  if (Result = nil) and ACanCreate then
  begin
    Result := TACLIniFileSection.Create;
    Result.Name := AName;
    Result.FOnChange := SectionChangeHandler;
    FSections.Add(Result);
  end;
end;

function TACLIniFile.FindValue(const AName, AKey: string;
  out ASection: TACLIniFileSection; out AIndex: Integer): Boolean;
begin
  ASection := GetSection(AName);
  if ASection <> nil then
    Result := ASection.FindValue(AKey, AIndex)
  else
    Result := False;
end;

procedure TACLIniFile.Changed;
begin
  FModified := True;
  if FChangeLockCount = 0 then
    CallNotifyEvent(Self, OnChanged);
end;

procedure TACLIniFile.LoadFromString(const AString: PChar; ACount: Integer);

  procedure ParseLine(S, F: PChar; var ASection: TACLIniFileSection);
  var
    ALength: Integer;
  begin
    ALength := acStringLength(S, F);
    if ALength > 0 then
    begin
      if S^ = '[' then
        ASection := GetSection(acMakeString(S + 1, ALength - 2), True)
      else if ASection <> nil then
        ASection.Add(acMakeString(S, ALength));
    end;
  end;

var
  ASection: TACLIniFileSection;
  F: PChar;
  P: PChar;
  S: PChar;
begin
  BeginUpdate;
  try
    Clear;
    P := AString;
    S := P;
    F := S + ACount;
    ASection := nil;
    while P < F do
    begin
      if (P^ <> #10) and (P^ <> #13){$IFDEF UNICODE}and (Ord(P^) <> Ord(acLineSeparator)){$ENDIF} then
        Inc(P)
      else
      begin
        ParseLine(S, P, ASection);
      {$IFDEF UNICODE}
        if Ord(P^) = Ord(acLineSeparator) then Inc(P);
      {$ENDIF}
        if Ord(P^) = Ord(#13) then Inc(P);
        if Ord(P^) = Ord(#10) then Inc(P);
        S := P;
      end;
    end;
    ParseLine(S, P, ASection);
  finally
    EndUpdate;
  end;
end;

function TACLIniFile.GetSectionCount: Integer;
begin
  Result := FSections.Count;
end;

function TACLIniFile.GetName(AIndex: Integer): string;
begin
  Result := SectionObjs[AIndex].Name;
end;

function TACLIniFile.GetSectionData(const ASection: string): string;
var
  AList: TACLIniFileSection;
begin
  AList := GetSection(ASection);
  if AList <> nil then
    Result := AList.Text
  else
    Result := EmptyStr;
end;

function TACLIniFile.GetSectionObj(Index: Integer): TACLIniFileSection;
begin
  Result := FSections.Items[Index];
end;

procedure TACLIniFile.SectionChangeHandler(Sender: TObject);
begin
  Changed;
end;

procedure TACLIniFile.SetFileName(const AValue: string);
begin
  if not acSameText(AValue, FileName) then
  begin
    FFileName := AValue;
    Changed;
  end;
end;

procedure TACLIniFile.SetSectionData(const ASection, AData: string);
begin
  GetSection(ASection, True).Text := AData;
end;

{ TACLSyncSafeIniFile }

constructor TACLSyncSafeIniFile.Create(const AFileName: string; AAutoSave: Boolean);
var
  ABackupFileName: string;
begin
  inherited Create(AFileName, True);

  if SectionCount = 0 then
  begin
    ABackupFileName := GetBackupFileName;
    if acFileExists(ABackupFileName) then
    begin
      LoadFromFile(ABackupFileName);
      FileName := AFileName;
    end;
  end;
end;

function TACLSyncSafeIniFile.UpdateFile: Boolean;
var
  ATempFileName: string;
begin
  Result := True;
  if Modified then
  begin
    ATempFileName := FileName + '.new';
    Result := SaveToFile(ATempFileName, Encoding) and acReplaceFile(ATempFileName, FileName, GetBackupFileName);
    if Result then
      FModified := False;
  end
end;

function TACLSyncSafeIniFile.GetBackupFileName: string;
begin
  Result := FileName + '.bak';
end;

end.
