{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*        Fast IniFile Implementation        *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.FileFormats.INI;

{$I ACL.Config.INC}

interface

uses
{$IFNDEF ACL_BASE_NOVCL}
  Winapi.Windows,
  Vcl.Graphics,
{$ENDIF}
  // System
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Types,
  System.TypInfo,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Hashes,
  ACL.Parsers,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Stream,
  ACL.Utils.Strings;

type

  { TACLIniFileSection }

  TACLIniFileSection = class(TACLStringList)
  strict private
    FLockCount: Integer;
    FName: UnicodeString;
    FNameHash: Integer;

    function GetValueFromName(const Name: UnicodeString): UnicodeString;
    procedure SetName(const AValue: UnicodeString);
  protected
    FOnChange: TNotifyEvent;

    procedure CalculateNameHash;
    procedure Changed; override;
    function FindValue(const AName: UnicodeString; out AIndex: Integer): Boolean; overload;
    function FindValue(const AName: UnicodeString; ANameHash: Integer; out AIndex: Integer): Boolean; overload;
    //
    property NameHash: Integer read FNameHash;
  public
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
    // Deleting
    function Delete(const AKey: UnicodeString): Boolean; overload;
    // Reading
    function ReadBool(const AKey: UnicodeString; ADefault: Boolean = False): Boolean;
    function ReadEnum<T>(const AKey: UnicodeString; const ADefault: T): T;
    function ReadFloat(const AKey: UnicodeString; const ADefault: Double = 0): Double;
    function ReadInt32(const AKey: UnicodeString; ADefault: Integer = 0): Integer; virtual;
    function ReadInt64(const AKey: UnicodeString; const ADefault: Int64 = 0): Int64;
    function ReadRect(const AKey: UnicodeString): TRect; overload;
    function ReadRect(const AKey: UnicodeString; const ADefault: TRect): TRect; overload;
    function ReadSize(const AKey: UnicodeString): TSize;
    function ReadStream(const AKey: UnicodeString; AStream: TStream): Boolean;
    function ReadString(const AKey: UnicodeString; const ADefault: UnicodeString = ''): UnicodeString;
    function ReadStringEx(const AKey: UnicodeString; out AValue: UnicodeString): Boolean; virtual;
  {$IFNDEF ACL_BASE_NOVCL}
    function ReadColor(const AKey: UnicodeString; ADefault: TColor = clDefault): TColor;
    function ReadFont(const AKey: UnicodeString; AFont: TFont): Boolean;
  {$ENDIF}
    // Writing
    procedure WriteBool(const AKey: UnicodeString; const AValue: Boolean); overload;
    procedure WriteBool(const AKey: UnicodeString; const AValue, ADefaultValue: Boolean); overload;
    procedure WriteEnum<T>(const AKey: UnicodeString; const AValue: T); overload;
    procedure WriteEnum<T>(const AKey: UnicodeString; const AValue, ADefaultValue: T); overload;
    procedure WriteFloat(const AKey: UnicodeString; const AValue: Double);
    procedure WriteInt64(const AKey: UnicodeString; const AValue: Int64); overload;
    procedure WriteInt64(const AKey: UnicodeString; const AValue, ADefaultValue: Int64); overload;
    procedure WriteInt32(const AKey: UnicodeString; const AValue: Integer); overload;
    procedure WriteInt32(const AKey: UnicodeString; const AValue, ADefaultValue: Integer); overload;
    procedure WriteRect(const AKey: UnicodeString; const AValue: TRect);
    procedure WriteSize(const AKey: UnicodeString; const AValue: TSize);
    procedure WriteStream(const AKey: UnicodeString; AStream: TStream);
    procedure WriteString(const AKey, AValue: UnicodeString); overload; virtual;
    procedure WriteString(const AKey, AValue, ADefaultValue: UnicodeString); overload;
  {$IFNDEF ACL_BASE_NOVCL}
    procedure WriteColor(const AKey: UnicodeString; AColor: TColor);
    procedure WriteFont(const AKey: UnicodeString; AFont: TFont);
  {$ENDIF}
    //
    property Name: UnicodeString read FName write SetName;
    property ValueFromName[const Name: UnicodeString]: UnicodeString read GetValueFromName write WriteString;
  end;

  { TACLIniFile }

  TACLIniFile = class(TACLUnknownObject)
  strict private
    FAutoSave: Boolean;
    FChangeLockCount: Integer;
    FEncoding: TEncoding;
    FFileName: UnicodeString;
    FPrevSection: TACLIniFileSection;

    FOnChanged: TNotifyEvent;

    function GetSectionData(const ASection: UnicodeString): UnicodeString;
    function GetSectionCount: Integer;
    function GetName(AIndex: Integer): UnicodeString;
    procedure SectionChangeHandler(Sender: TObject);
    procedure SetFileName(const AValue: UnicodeString);
    procedure SetSectionData(const ASection, AData: UnicodeString);
  protected
    FModified: Boolean;
    FSections: TACLObjectList<TACLIniFileSection>;

    function FindValue(const AName, AKey: UnicodeString; out ASection: TACLIniFileSection; out AIndex: Integer): Boolean;
    procedure Changed; virtual;
  public
    constructor Create; overload;
    constructor Create(const AFileName: UnicodeString; AutoSave: Boolean = True); overload; virtual;
    destructor Destroy; override;
    procedure Assign(AIniFile: TACLIniFile);
    procedure Merge(const AFileName: string; AOverwriteExisting: Boolean = True); overload;
    procedure Merge(const AIniFile: TACLIniFile; AOverwriteExisting: Boolean = True); overload;
    function Equals(Obj: TObject): Boolean; override;

    procedure BeginUpdate;
    procedure EndUpdate;

    // Checking for Exists
    function ExistsKey(const ASection, AKey: UnicodeString): Boolean; virtual;
    function ExistsSection(const ASection: UnicodeString): Boolean; virtual;
    function IsEmpty: Boolean; virtual;

    // Sections
    function GetSection(const AName: UnicodeString; ACanCreate: Boolean = False): TACLIniFileSection;

    // Reading
    function ReadBool(const ASection, AKey: UnicodeString; ADefault: Boolean = False): Boolean;
    function ReadEnum<T>(const ASection, AKey: UnicodeString; const ADefault: T): T;
    function ReadFloat(const ASection, AKey: UnicodeString; const ADefault: Double = 0): Double;
    function ReadInteger(const ASection, AKey: UnicodeString; ADefault: Integer = 0): Integer; virtual;
    function ReadInt64(const ASection, AKey: UnicodeString; const ADefault: Int64 = 0): Int64;
    function ReadObject(const ASection, AKey: UnicodeString; ALoadProc: TACLStreamProc): Boolean;
    function ReadRect(const ASection, AKey: UnicodeString): TRect; overload;
    function ReadRect(const ASection, AKey: UnicodeString; const ADefault: TRect): TRect; overload;
    function ReadSize(const ASection, AKey: UnicodeString): TSize;
    function ReadStream(const ASection, AKey: UnicodeString; AStream: TStream): Boolean;
    function ReadString(const ASection, AKey: UnicodeString; const ADefault: UnicodeString = ''): UnicodeString;
    function ReadStringEx(const ASection, AKey: UnicodeString; out AValue: UnicodeString): Boolean; virtual;
    function ReadStrings(const ASection: UnicodeString; AStrings: TACLStringList): Integer; overload;
    function ReadStrings(const ASection: UnicodeString; AStrings: TStrings): Integer; overload;
  {$IFNDEF ACL_BASE_NOVCL}
    function ReadColor(const ASection, AKey: UnicodeString; ADefault: TColor = clDefault): TColor;
    function ReadFont(const ASection, AKey: UnicodeString; AFont: TFont): Boolean;
  {$ENDIF}
    procedure ReadKeys(const ASection: UnicodeString; AKeys: TACLStringList); overload;
    procedure ReadKeys(const ASection: UnicodeString; AProc: TACLStringEnumProc); overload;

    // Writing
    procedure WriteBool(const ASection, AKey: UnicodeString; AValue, ADefaultValue: Boolean); overload;
    procedure WriteBool(const ASection, AKey: UnicodeString; AValue: Boolean); overload;
    procedure WriteEnum<T>(const ASection, AKey: UnicodeString; const AValue: T); overload;
    procedure WriteEnum<T>(const ASection, AKey: UnicodeString; const AValue, ADefaultValue: T); overload;
    procedure WriteFloat(const ASection, AKey: UnicodeString; const AValue: Double);
    procedure WriteInt64(const ASection, AKey: UnicodeString; const AValue, ADefaultValue: Int64); overload;
    procedure WriteInt64(const ASection, AKey: UnicodeString; const AValue: Int64); overload;
    procedure WriteInteger(const ASection, AKey: UnicodeString; AValue, ADefaultValue: Integer); overload;
    procedure WriteInteger(const ASection, AKey: UnicodeString; AValue: Integer); overload;
    procedure WriteObject(const ASection, AKey: UnicodeString; ASaveProc: TACLStreamProc);
    procedure WriteRect(const ASection, AKey: UnicodeString; const AValue: TRect);
    procedure WriteSize(const ASection, AKey: UnicodeString; const AValue: TSize);
    procedure WriteStream(const ASection, AKey: UnicodeString; AStream: TStream);
    procedure WriteString(const ASection, AKey, AValue, ADefaultValue: UnicodeString); overload;
    procedure WriteString(const ASection, AKey, AValue: UnicodeString); overload; virtual;
    procedure WriteStrings(const ASection: UnicodeString; AStrings: TACLStringList); overload;
    procedure WriteStrings(const ASection: UnicodeString; AStrings: TStrings); overload;
  {$IFNDEF ACL_BASE_NOVCL}
    procedure WriteColor(const ASection, AKey: UnicodeString; AColor: TColor);
    procedure WriteFont(const ASection, AKey: UnicodeString; AFont: TFont);
  {$ENDIF}

    // Delete
    procedure Clear;
    function DeleteKey(const ASection, AKey: UnicodeString): Boolean;
    function DeleteSection(const AName: UnicodeString): Boolean;

    // Rename
    procedure RenameKey(const ASection, AKeyName, ANewKeyName: UnicodeString); overload;
    procedure RenameKey(const ASection, AKeyName, ANewSection, ANewKeyName: UnicodeString); overload;
    procedure RenameSection(const ASection, ANewName: UnicodeString);

    // Load/Save
    procedure LoadFromFile(const AFileName: UnicodeString); virtual;
    procedure LoadFromResource(Inst: HINST; const AName: UnicodeString; AType: PChar);
    procedure LoadFromStream(AStream: TStream); virtual;
    procedure LoadFromString(const AString: UnicodeString); overload;
    procedure LoadFromString(const AString: PWideChar; ACount: Integer); overload; virtual;
    function SaveToFile(const AFileName: UnicodeString; AEncoding: TEncoding = nil): Boolean;
    procedure SaveToStream(AStream: TStream); overload;
    procedure SaveToStream(AStream: TStream; AEncoding: TEncoding); overload; virtual;
    function UpdateFile: Boolean; virtual;
    //
    property AutoSave: Boolean read FAutoSave write FAutoSave;
    property Encoding: TEncoding read FEncoding write FEncoding;
    property FileName: UnicodeString read FFileName write SetFileName;
    property Modified: Boolean read FModified write FModified;
    //
    property SectionCount: Integer read GetSectionCount;
    property SectionData[const ASection: UnicodeString]: UnicodeString read GetSectionData write SetSectionData;
    property Sections[Index: Integer]: UnicodeString read GetName;
    //
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  { TACLSyncSafeIniFile }

  TACLSyncSafeIniFile = class(TACLIniFile)
  strict private
    function GetBackupFileName: UnicodeString;
  public
    constructor Create(const AFileName: UnicodeString; AAutoSave: Boolean = True); override;
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

function TACLIniFileSection.Delete(const AKey: UnicodeString): Boolean;
var
  AIndex: Integer;
begin
  Result := FindValue(AKey, AIndex);
  if Result then
    Delete(AIndex);
end;

function TACLIniFileSection.ReadBool(const AKey: UnicodeString; ADefault: Boolean): Boolean;
var
  AIndex: Integer;
begin
  if FindValue(AKey, AIndex) then
    Result := StrToIntDef(ValueFromIndex[AIndex], Ord(ADefault)) <> 0
  else
    Result := ADefault;
end;

function TACLIniFileSection.ReadEnum<T>(const AKey: UnicodeString; const ADefault: T): T;
var
  AValue: Integer;
begin
  if FindValue(AKey, AValue) and TryStrToInt(ValueFromIndex[AValue], AValue) then
    Result := TACLEnumHelper.SetValue<T>(AValue)
  else
    Result := ADefault;
end;

function TACLIniFileSection.ReadFloat(const AKey: UnicodeString; const ADefault: Double): Double;
var
  AData: UnicodeString;
  AValue: Extended;
begin
  try
    AData := ReadString(AKey);
    if not TextToFloat(AData, AValue, InvariantFormatSettings) then
    begin
      if not TextToFloat(AData, AValue) then // Backward compatibility
        AValue := ADefault;
    end;
    Result := AValue;
  except
    Result := ADefault;
  end;
end;

function TACLIniFileSection.ReadInt32(const AKey: UnicodeString; ADefault: Integer): Integer;
var
  AIndex: Integer;
begin
  if FindValue(AKey, AIndex) then
    Result := StrToIntDef(ValueFromIndex[AIndex], ADefault)
  else
    Result := ADefault;
end;

function TACLIniFileSection.ReadInt64(const AKey: UnicodeString; const ADefault: Int64): Int64;
var
  AIndex: Integer;
begin
  if FindValue(AKey, AIndex) then
    Result := StrToInt64Def(ValueFromIndex[AIndex], ADefault)
  else
    Result := ADefault;
end;

function TACLIniFileSection.ReadRect(const AKey: UnicodeString): TRect;
begin
  Result := ReadRect(AKey, NullRect);
end;

function TACLIniFileSection.ReadRect(const AKey: UnicodeString; const ADefault: TRect): TRect;
var
  AIndex: Integer;
begin
  if FindValue(AKey, AIndex) then
    Result := acStringToRect(ValueFromIndex[AIndex])
  else
    Result := ADefault;
end;

function TACLIniFileSection.ReadSize(const AKey: UnicodeString): TSize;
begin
  Result := acStringToSize(ReadString(AKey));
end;

function TACLIniFileSection.ReadStream(const AKey: UnicodeString; AStream: TStream): Boolean;
begin
  Result := TACLHexCode.Decode(ReadString(AKey), AStream);
  if Result then
    AStream.Position := 0;
end;

function TACLIniFileSection.ReadString(const AKey, ADefault: UnicodeString): UnicodeString;
var
  AIndex: Integer;
begin
  if FindValue(AKey, AIndex) then
    Result := ValueFromIndex[AIndex]
  else
    Result := ADefault;
end;

function TACLIniFileSection.ReadStringEx(const AKey: UnicodeString; out AValue: UnicodeString): Boolean;
var
  AIndex: Integer;
begin
  Result := FindValue(AKey, AIndex);
  if Result then
    AValue := ValueFromIndex[AIndex]
end;

procedure TACLIniFileSection.WriteBool(const AKey: UnicodeString; const AValue: Boolean);
begin
  WriteInt32(AKey, Ord(AValue));
end;

procedure TACLIniFileSection.WriteBool(const AKey: UnicodeString; const AValue, ADefaultValue: Boolean);
begin
  if AValue <> ADefaultValue then
    WriteBool(AKey, AValue)
  else
    Delete(AKey);
end;

procedure TACLIniFileSection.WriteEnum<T>(const AKey: UnicodeString; const AValue: T);
begin
  WriteInt32(AKey, TACLEnumHelper.GetValue(AValue));
end;

procedure TACLIniFileSection.WriteEnum<T>(const AKey: UnicodeString; const AValue, ADefaultValue: T);
begin
  if TACLEnumHelper.GetValue(AValue) <> TACLEnumHelper.GetValue(ADefaultValue) then
    WriteEnum(AKey, AValue)
  else
    Delete(AKey);
end;

procedure TACLIniFileSection.WriteFloat(const AKey: UnicodeString; const AValue: Double);
begin
  WriteString(AKey, FloatToStr(AValue, InvariantFormatSettings));
end;

procedure TACLIniFileSection.WriteInt32(const AKey: UnicodeString; const AValue: Integer);
begin
  WriteString(AKey, IntToStr(AValue));
end;

procedure TACLIniFileSection.WriteInt32(const AKey: UnicodeString; const AValue, ADefaultValue: Integer);
begin
  if AValue <> ADefaultValue then
    WriteInt32(AKey, AValue)
  else
    Delete(AKey);
end;

procedure TACLIniFileSection.WriteInt64(const AKey: UnicodeString; const AValue, ADefaultValue: Int64);
begin
  if AValue <> ADefaultValue then
    WriteInt64(AKey, AValue)
  else
    Delete(AKey);
end;

procedure TACLIniFileSection.WriteInt64(const AKey: UnicodeString; const AValue: Int64);
begin
  WriteString(AKey, IntToStr(AValue));
end;

procedure TACLIniFileSection.WriteRect(const AKey: UnicodeString; const AValue: TRect);
begin
  WriteString(AKey, acRectToString(AValue));
end;

procedure TACLIniFileSection.WriteSize(const AKey: UnicodeString; const AValue: TSize);
begin
  WriteString(AKey, acSizeToString(AValue));
end;

procedure TACLIniFileSection.WriteStream(const AKey: UnicodeString; AStream: TStream);
begin
  WriteString(AKey, TACLHexCode.Encode(AStream), '');
end;

procedure TACLIniFileSection.WriteString(const AKey, AValue, ADefaultValue: UnicodeString);
begin
  if AValue <> ADefaultValue then
    WriteString(AKey, AValue)
  else
    Delete(AKey);
end;

procedure TACLIniFileSection.WriteString(const AKey, AValue: UnicodeString);
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
function TACLIniFileSection.ReadColor(const AKey: UnicodeString; ADefault: TColor): TColor;
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

function TACLIniFileSection.ReadFont(const AKey: UnicodeString; AFont: TFont): Boolean;
var
  AFontStr: UnicodeString;
begin
  Result := ReadStringEx(AKey, AFontStr);
  if Result then
    acStringToFont(AFontStr, AFont);
end;

procedure TACLIniFileSection.WriteColor(const AKey: UnicodeString; AColor: TColor);
begin
  AColor := ColorToRGB(AColor);
  WriteString(AKey, IntToStr(GetRValue(AColor)) + ',' + IntToStr(GetGValue(AColor)) + ',' + IntToStr(GetBValue(AColor)));
end;

procedure TACLIniFileSection.WriteFont(const AKey: UnicodeString; AFont: TFont);
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

function TACLIniFileSection.FindValue(const AName: UnicodeString; out AIndex: Integer): Boolean;
begin
  Result := (Count > 0) and FindValue(AName, ElfHash(AName), AIndex)
end;

function TACLIniFileSection.FindValue(const AName: UnicodeString; ANameHash: Integer; out AIndex: Integer): Boolean;
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

function TACLIniFileSection.GetValueFromName(const Name: UnicodeString): UnicodeString;
var
  AIndex: Integer;
begin
  if FindValue(Name, AIndex) then
    Result := ValueFromIndex[AIndex]
  else
    Result := '';
end;

procedure TACLIniFileSection.SetName(const AValue: UnicodeString);
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

constructor TACLIniFile.Create(const AFileName: UnicodeString; AutoSave: Boolean = True);
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

  procedure MergeSection(const ASection: UnicodeString);
  var
    AKey: UnicodeString;
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

function TACLIniFile.ExistsKey(const ASection, AKey: UnicodeString): Boolean;
var
  AIndex: Integer;
  AList: TACLIniFileSection;
begin
  Result := FindValue(ASection, AKey, AList, AIndex);
end;

function TACLIniFile.ExistsSection(const ASection: UnicodeString): Boolean;
begin
  Result := GetSection(ASection) <> nil;
end;

function TACLIniFile.IsEmpty: Boolean;
begin
  Result := SectionCount = 0;
end;

function TACLIniFile.ReadBool(const ASection, AKey: UnicodeString; ADefault: Boolean = False): Boolean;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadBool(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadEnum<T>(const ASection, AKey: UnicodeString; const ADefault: T): T;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadEnum(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadFloat(const ASection, AKey: UnicodeString; const ADefault: Double = 0): Double;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadFloat(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadInteger(const ASection, AKey: UnicodeString; ADefault: Integer = 0): Integer;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadInt32(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadInt64(const ASection, AKey: UnicodeString; const ADefault: Int64 = 0): Int64;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadInt64(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadRect(const ASection, AKey: UnicodeString): TRect;
begin
  Result := ReadRect(ASection, AKey, NullRect);
end;

function TACLIniFile.ReadRect(const ASection, AKey: UnicodeString; const ADefault: TRect): TRect;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadRect(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadSize(const ASection, AKey: UnicodeString): TSize;
begin
  Result := acStringToSize(ReadString(ASection, AKey));
end;

function TACLIniFile.ReadStream(const ASection, AKey: UnicodeString; AStream: TStream): Boolean;
begin
  Result := TACLHexCode.Decode(ReadString(ASection, AKey), AStream);
  if Result then
    AStream.Position := 0;
end;

function TACLIniFile.ReadString(const ASection, AKey: UnicodeString; const ADefault: UnicodeString = ''): UnicodeString;
begin
  if not ReadStringEx(ASection, AKey, Result) then
    Result := ADefault;
end;

function TACLIniFile.ReadStringEx(const ASection, AKey: UnicodeString; out AValue: UnicodeString): Boolean;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  Result := (ASectionObj <> nil) and ASectionObj.ReadStringEx(AKey, AValue);
end;

function TACLIniFile.ReadStrings(const ASection: UnicodeString; AStrings: TACLStringList): Integer;
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

function TACLIniFile.ReadStrings(const ASection: UnicodeString; AStrings: TStrings): Integer;
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
function TACLIniFile.ReadColor(const ASection, AKey: UnicodeString; ADefault: TColor = clDefault): TColor;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  if ASectionObj <> nil then
    Result := ASectionObj.ReadColor(AKey, ADefault)
  else
    Result := ADefault;
end;

function TACLIniFile.ReadFont(const ASection, AKey: UnicodeString; AFont: TFont): Boolean;
var
  ASectionObj: TACLIniFileSection;
begin
  ASectionObj := GetSection(ASection);
  Result := (ASectionObj <> nil) and ASectionObj.ReadFont(AKey, AFont);
end;
{$ENDIF}

procedure TACLIniFile.ReadKeys(const ASection: UnicodeString; AKeys: TACLStringList);
var
  AList: TACLIniFileSection;
  AName: UnicodeString;
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

procedure TACLIniFile.ReadKeys(const ASection: UnicodeString; AProc: TACLStringEnumProc);
var
  AList: TACLIniFileSection;
  AName: UnicodeString;
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

function TACLIniFile.ReadObject(const ASection, AKey: UnicodeString; ALoadProc: TACLStreamProc): Boolean;
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

procedure TACLIniFile.WriteBool(const ASection, AKey: UnicodeString; AValue: Boolean);
begin
  WriteInteger(ASection, AKey, Ord(AValue));
end;

procedure TACLIniFile.WriteEnum<T>(const ASection, AKey: UnicodeString; const AValue: T);
begin
  GetSection(ASection, True).WriteEnum(AKey, AValue);
end;

procedure TACLIniFile.WriteEnum<T>(const ASection, AKey: UnicodeString; const AValue, ADefaultValue: T);
begin
  if TACLEnumHelper.GetValue(AValue) <> TACLEnumHelper.GetValue(ADefaultValue) then
    WriteEnum(ASection, AKey, AValue)
  else
    DeleteKey(ASection, AKey);
end;

procedure TACLIniFile.WriteBool(const ASection, AKey: UnicodeString; AValue, ADefaultValue: Boolean);
begin
  WriteInteger(ASection, AKey, Ord(AValue), Ord(ADefaultValue));
end;

procedure TACLIniFile.WriteFloat(const ASection, AKey: UnicodeString; const AValue: Double);
begin
  WriteString(ASection, AKey, FloatToStr(AValue, InvariantFormatSettings));
end;

procedure TACLIniFile.WriteInteger(const ASection, AKey: UnicodeString; AValue: Integer);
begin
  WriteString(ASection, AKey, IntToStr(AValue));
end;

procedure TACLIniFile.WriteInteger(const ASection, AKey: UnicodeString; AValue, ADefaultValue: Integer);
begin
  if AValue <> ADefaultValue then
    WriteInteger(ASection, AKey, AValue)
  else
    DeleteKey(ASection, AKey);
end;

procedure TACLIniFile.WriteInt64(const ASection, AKey: UnicodeString; const AValue: Int64);
begin
  WriteString(ASection, AKey, IntToStr(AValue));
end;

procedure TACLIniFile.WriteInt64(const ASection, AKey: UnicodeString; const AValue, ADefaultValue: Int64);
begin
  if AValue <> ADefaultValue then
    WriteInt64(ASection, AKey, AValue)
  else
    DeleteKey(ASection, AKey);
end;

procedure TACLIniFile.WriteObject(const ASection, AKey: UnicodeString; ASaveProc: TACLStreamProc);
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

procedure TACLIniFile.WriteRect(const ASection, AKey: UnicodeString; const AValue: TRect);
begin
  WriteString(ASection, AKey, acRectToString(AValue));
end;

procedure TACLIniFile.WriteSize(const ASection, AKey: UnicodeString; const AValue: TSize);
begin
  WriteString(ASection, AKey, acSizeToString(AValue));
end;

procedure TACLIniFile.WriteStream(const ASection, AKey: UnicodeString; AStream: TStream);
begin
  WriteString(ASection, AKey, TACLHexCode.Encode(AStream), '');
end;

procedure TACLIniFile.WriteString(const ASection, AKey, AValue: UnicodeString);
begin
  BeginUpdate;
  try
    GetSection(ASection, True).WriteString(AKey, AValue);
  finally
    EndUpdate;
  end;
end;

procedure TACLIniFile.WriteStrings(const ASection: UnicodeString; AStrings: TACLStringList);
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

procedure TACLIniFile.WriteStrings(const ASection: UnicodeString; AStrings: TStrings);
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

procedure TACLIniFile.WriteString(const ASection, AKey, AValue, ADefaultValue: UnicodeString);
begin
  if AValue <> ADefaultValue then
    WriteString(ASection, AKey, AValue)
  else
    DeleteKey(ASection, AKey);
end;

{$IFNDEF ACL_BASE_NOVCL}
procedure TACLIniFile.WriteColor(const ASection, AKey: UnicodeString; AColor: TColor);
begin
  GetSection(ASection, True).WriteColor(AKey, AColor);
end;

procedure TACLIniFile.WriteFont(const ASection, AKey: UnicodeString; AFont: TFont);
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

function TACLIniFile.DeleteKey(const ASection, AKey: UnicodeString): Boolean;
var
  AList: TACLIniFileSection;
begin
  AList := GetSection(ASection);
  Result := (AList <> nil) and AList.Delete(AKey);
end;

function TACLIniFile.DeleteSection(const AName: UnicodeString): Boolean;
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

procedure TACLIniFile.RenameKey(const ASection, AKeyName, ANewKeyName: UnicodeString);
begin
  RenameKey(ASection, AKeyName, ASection, ANewKeyName);
end;

procedure TACLIniFile.RenameKey(const ASection, AKeyName, ANewSection, ANewKeyName: UnicodeString);
var
  AIndex: Integer;
  AList: TACLIniFileSection;
  AValue: UnicodeString;
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

procedure TACLIniFile.RenameSection(const ASection, ANewName: UnicodeString);
var
  AList: TACLIniFileSection;
begin
  AList := GetSection(ASection);
  if AList <> nil then
    AList.Name := ANewName;
end;

procedure TACLIniFile.LoadFromFile(const AFileName: UnicodeString);
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

procedure TACLIniFile.LoadFromResource(Inst: HINST; const AName: UnicodeString; AType: PChar);
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

procedure TACLIniFile.LoadFromString(const AString: UnicodeString);
begin
  LoadFromString(PWideChar(AString), Length(AString));
end;

function TACLIniFile.SaveToFile(const AFileName: UnicodeString; AEncoding: TEncoding = nil): Boolean;
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
  AList: TACLIniFileSection;
  I, J: Integer;
begin
  if AEncoding = nil then
    AEncoding := TEncoding.Unicode;
  AStream.WriteBOM(AEncoding);
  for I := 0 to FSections.Count - 1 do
  begin
    AList := FSections.List[I];
    if AList.Count > 0 then
    begin
      //Note: AList.SortLogical; we cannot use that because of SectionData[''] allow us to set raw data
      AStream.WriteString('[' + AList.Name + ']' + acCRLF, AEncoding);
      for J := 0 to AList.Count - 1 do
        AStream.WriteString(AList.Strings[J] + acCRLF, AEncoding);
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

function TACLIniFile.GetSection(const AName: UnicodeString; ACanCreate: Boolean): TACLIniFileSection;
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

function TACLIniFile.FindValue(const AName, AKey: UnicodeString;
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

procedure TACLIniFile.LoadFromString(const AString: PWideChar; ACount: Integer);

  procedure ParseLine(S, F: PWideChar; var ASection: TACLIniFileSection);
  var
    ALength: Integer;
  begin
    ALength := acStringLength(S, F);
    if ALength > 0 then
    begin
      if Ord(S^) = Ord('[') then
        ASection := GetSection(acMakeString(S + 1, ALength - 2), True)
      else if ASection <> nil then
        ASection.Add(acMakeString(S, ALength));
    end;
  end;

var
  ASection: TACLIniFileSection;
  F: PWideChar;
  P: PWideChar;
  S: PWideChar;
begin
  BeginUpdate;
  try
    Clear;
    P := AString;
    S := P;
    F := S + ACount;
    ASection := nil;
    while (NativeUInt(P) + SizeOf(WideChar) <= NativeUInt(F)) do
    begin
      if (Ord(P^) <> Ord(#10)) and (Ord(P^) <> Ord(#13)) and (Ord(P^) <> Ord(acLineSeparator)) then
        Inc(P)
      else
      begin
        ParseLine(S, P, ASection);
        if Ord(P^) = Ord(acLineSeparator) then Inc(P);
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

function TACLIniFile.GetName(AIndex: Integer): UnicodeString;
begin
  Result := FSections.Items[AIndex].Name;
end;

function TACLIniFile.GetSectionData(const ASection: UnicodeString): UnicodeString;
var
  AList: TACLIniFileSection;
begin
  AList := GetSection(ASection);
  if AList <> nil then
    Result := AList.Text
  else
    Result := EmptyStr;
end;

procedure TACLIniFile.SectionChangeHandler(Sender: TObject);
begin
  Changed;
end;

procedure TACLIniFile.SetFileName(const AValue: UnicodeString);
begin
  if not acSameText(AValue, FileName) then
  begin
    FFileName := AValue;
    Changed;
  end;
end;

procedure TACLIniFile.SetSectionData(const ASection, AData: UnicodeString);
begin
  GetSection(ASection, True).Text := AData;
end;

{ TACLSyncSafeIniFile }

constructor TACLSyncSafeIniFile.Create(const AFileName: UnicodeString; AAutoSave: Boolean);
var
  ABackupFileName: UnicodeString;
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
  ATempFileName: UnicodeString;
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

function TACLSyncSafeIniFile.GetBackupFileName: UnicodeString;
begin
  Result := FileName + '.bak';
end;

end.
