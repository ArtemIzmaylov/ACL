{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*         SQLite Database Wrappers          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.SQLite3;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Sqlite,
  System.SysUtils,
  System.Variants,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings,
  ACL.Utils.Strings.Transcode,
  ACL.Threading;

const
  sKeyDelim = ';';

  SQLITE_STATIC     = Pointer( 0);
  SQLITE_TRANSIENT  = Pointer(-1);

  SQLITE_MAX_FUNCTION_ARG_COUNT = 127;

type
  HSQLCONTEXT = Pointer;
  HSQLDB = Pointer;
  HSQLQUERY = Pointer;
  HSQLVALUE = Pointer;

  TACLSQLiteBase = class;
  TACLSQLiteColumnType = (sctUnknown, sctFloat, sctText, sctBlob, sctNull);

  TSQLFunction = TxFunc;

  { EACLSQLiteError }

  EACLSQLiteError = class(Exception)
  strict private
    FErrorCode: Integer;
  public
    constructor Create(AHandle: HSQLDB; AError: Integer; const AAdditionalInfo: string = '');
    //
    property ErrorCode: Integer read FErrorCode;
  end;

  { TACLSQLiteColumn }

  TACLSQLiteColumn = class
  protected
    FDataType: TACLSQLiteColumnType;
    FName: UnicodeString;
    FNameHash: Integer;
  public
    property DataType: TACLSQLiteColumnType read FDataType;
    property Name: UnicodeString read FName;
    property NameHash: Integer read FNameHash;
  end;

  { TACLSQLiteTable }

  TACLSQLiteTableClass = class of TACLSQLiteTable;
  TACLSQLiteTable = class
  strict private
    FColumns: TACLObjectList;
    FDatabase: TACLSQLiteBase;
    FDataTypesFetched: Boolean;
    FQuery: HSQLQUERY;

    function FetchDataTypes: Boolean;
    function GetColumn(Index: Integer): TACLSQLiteColumn;
    function GetColumnCount: Integer;
  public
    constructor Create(ADatabase: TACLSQLiteBase; AQuery: HSQLQUERY); virtual;
    destructor Destroy; override;
    function GetFieldIndex(const Name: UnicodeString): Integer;
    function NextRecord: Boolean;
    // I/O
    function ReadBlob(AIndex: Integer; AData: TMemoryStream): Integer; overload;
    function ReadBlob(const AName: UnicodeString; AData: TMemoryStream): Integer; overload; inline;
    function ReadDouble(AIndex: Integer): Double; overload;
    function ReadDouble(const AName: UnicodeString): Double; overload; inline;
    function ReadInt(AIndex: Integer): Int64; overload;
    function ReadInt(const AName: UnicodeString): Int64; overload; inline;
    function ReadStr(AIndex: Integer; out ALength: Integer): PWideChar; overload;
    function ReadStr(AIndex: Integer; ASharedStrings: TACLStringSharedTable = nil): UnicodeString; overload; inline;
    function ReadStr(const AName: UnicodeString; ASharedStrings: TACLStringSharedTable = nil): UnicodeString; overload; inline;
    // Properties
    property Column[Index: Integer]: TACLSQLiteColumn read GetColumn; default;
    property ColumnCount: Integer read GetColumnCount;
    property Database: TACLSQLiteBase read FDatabase;
  end;

  { TACLSQLiteBase }

  TACLSQLiteBase = class(TACLUnknownObject)
  strict private
    FFileName: UnicodeString;
    FHandle: HSQLDB;
    FLock: TACLCriticalSection;
    FUpdateCount: Integer;

    function GetVersion: Integer;
    procedure SetVersion(AValue: Integer);
  protected
    procedure CheckError(AErrorCode: Integer; const AAdditionalInfo: string = '');
    procedure CreateFunction(const AName: PWideChar; AArgCount: Integer; AFunc: TSQLFunction);
    procedure DestroySubClasses; virtual;
    function GetTableClass: TACLSQLiteTableClass; virtual;
    procedure InitializeFunctions; virtual;
    procedure InitializeTables; virtual;
    procedure PrepareQuery(const S: UnicodeString; out AHandle: HSQLQUERY); virtual;
    // Lock / Unlock
    procedure Lock;
    procedure Unlock;
    //
    property Handle: HSQLDB read FHandle;
  public
    constructor Create(const AFileName: UnicodeString); virtual;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;

    procedure Compress; overload;
    procedure Compress(out AOldSize, ANewSize: Int64); overload;
    procedure Transaction(Proc: TProcedureRef);

    // Statements
    procedure Exec(const AFormatLine: UnicodeString; const AArguments: array of const); overload;
    procedure Exec(const AQuery: UnicodeString); overload;
    function Exec(const AQuery: UnicodeString; out AHandle: HSQLQUERY): Boolean; overload;
    function Exec(const AQuery: UnicodeString; out ATable: TACLSQLiteTable): Boolean; overload;
    function ExecInt(const AQuery: UnicodeString): Int64;
    // Use "?" symbol in Query for set BlobData position
    procedure ExecInsertBlob(const AQuery: UnicodeString; const AData: TMemoryStream); overload;
    procedure ExecInsertBlob(const AQuery: UnicodeString; const AData: PByte; const ASize: Int64); overload;

    // Utilities
    function FetchColumns(const ATableName: UnicodeString): TACLStringList;

    // Properties
    property FileName: UnicodeString read FFileName;
    property Version: Integer read GetVersion write SetVersion;
  end;

  { TACLSQLQueryBuilder }

  TACLSQLQueryBuilder = class
  strict private
    FBuffer: TStringBuilder;
    FPrevIsValue: Boolean;

    function TypeCore(const APreparedValue: string): TACLSQLQueryBuilder;
    function ValCore(const APreparedValue: string): TACLSQLQueryBuilder;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: TACLSQLQueryBuilder;
    function ToString: string; override;

    // General
    function Done: string;
    function Raw(const S: string): TACLSQLQueryBuilder; inline;

    // Abbreviations
    function N(const AName: UnicodeString): TACLSQLQueryBuilder; overload; inline;
    function V(const AValue: Single): TACLSQLQueryBuilder; overload; inline;
    function V(const AValue: Double): TACLSQLQueryBuilder; overload; inline;
    function V(const AValue: Int64): TACLSQLQueryBuilder; overload; inline;
    function V(const AValue: Integer): TACLSQLQueryBuilder; overload; inline;
    function V(const AValue: TDateTime): TACLSQLQueryBuilder; overload; inline;
    function V(const AValue: UnicodeString): TACLSQLQueryBuilder; overload; inline;
    function V(const AValue: Variant): TACLSQLQueryBuilder; overload; inline;
    function VBlob: TACLSQLQueryBuilder; overload; inline;

    // Operators
    function Above: TACLSQLQueryBuilder; inline;
    function AboveOrEqual: TACLSQLQueryBuilder; inline;
    function &And: TACLSQLQueryBuilder; inline;
    function &As: TACLSQLQueryBuilder; inline;
    function Asterisk: TACLSQLQueryBuilder; inline;
    function Below: TACLSQLQueryBuilder; inline;
    function BelowOrEqual: TACLSQLQueryBuilder; inline;
    function Equal: TACLSQLQueryBuilder; reintroduce; inline;
    function &Not: TACLSQLQueryBuilder; inline;
    function Minus: TACLSQLQueryBuilder; inline;
    function NotEquals: TACLSQLQueryBuilder; inline;
    function &On: TACLSQLQueryBuilder; inline;
    function &Or: TACLSQLQueryBuilder; inline;
    function Plus: TACLSQLQueryBuilder; inline;

    // Directives
    function AlterTable: TACLSQLQueryBuilder; inline;
    function Comma: TACLSQLQueryBuilder; inline;
    function Count: TACLSQLQueryBuilder; inline;
    function CreateIndex: TACLSQLQueryBuilder; inline;
    function CreateTable: TACLSQLQueryBuilder; inline;
    function Delete: TACLSQLQueryBuilder; inline;
    function DeleteFrom(const TableName: string): TACLSQLQueryBuilder; inline;
    function Descending: TACLSQLQueryBuilder; inline;
    function Distinct: TACLSQLQueryBuilder; inline;
    function DropTable: TACLSQLQueryBuilder; inline;
    function From: TACLSQLQueryBuilder; inline;
    function GroupBy: TACLSQLQueryBuilder; inline;
    function Insert: TACLSQLQueryBuilder; inline;
    function Into: TACLSQLQueryBuilder; inline;
    function Limit(ALimit: Integer): TACLSQLQueryBuilder; overload; inline;
    function Limit(AStart, ALimit: Integer): TACLSQLQueryBuilder; overload; inline;
    function OrderBy: TACLSQLQueryBuilder; inline;
    function Rename: TACLSQLQueryBuilder; inline;
    function Replace: TACLSQLQueryBuilder; inline;
    function Select: TACLSQLQueryBuilder; inline;
    function SelectAll: TACLSQLQueryBuilder; inline;
    function &Set: TACLSQLQueryBuilder; inline;
    function &To: TACLSQLQueryBuilder; inline;
    function Unique: TACLSQLQueryBuilder; inline;
    function Update: TACLSQLQueryBuilder; inline;
    function Values: TACLSQLQueryBuilder; inline;
    function Where: TACLSQLQueryBuilder; inline;

    // Brackets
    function OpenBracket: TACLSQLQueryBuilder; inline;
    function CloseBracket: TACLSQLQueryBuilder; inline;

    // Types
    function TypeAuto: TACLSQLQueryBuilder; inline;
    function TypeBlob: TACLSQLQueryBuilder; inline;
    function TypeDouble: TACLSQLQueryBuilder; inline;
    function TypeInt32: TACLSQLQueryBuilder; inline;
    function TypeInt64: TACLSQLQueryBuilder; inline;
    function TypePrimaryKey: TACLSQLQueryBuilder; inline;
    function TypeText: TACLSQLQueryBuilder; inline;
  end;

function PrepareData(const AData: Int64): UnicodeString; inline; overload;
function PrepareData(const AData: UnicodeString): UnicodeString; inline; overload;
function PrepareData(const AData: Variant): UnicodeString; inline; overload;
function SQLiteEncodeDateTime(const DateTime: TDateTime): UnicodeString;
function SQLiteFormatDouble(const AValue: Double): UnicodeString;

// Values
function SQLiteVarToDouble(AValue: Pointer): Double; inline;
function SQLiteVarToInt32(AValue: Pointer): Integer; inline;
function SQLiteVarToInt64(AValue: Pointer): Int64; inline;
function SQLiteVarToText(AValue: Pointer): UnicodeString; inline;

// Result
procedure SQLiteResultSet(AContext: HSQLCONTEXT; const AValue: Double); overload;
procedure SQLiteResultSet(AContext: HSQLCONTEXT; const AValue: Integer); overload;
procedure SQLiteResultSet(AContext: HSQLCONTEXT; const AValue: UnicodeString); overload;
procedure SQLiteResultSetNull(AContext: HSQLCONTEXT);
implementation

uses
  System.Math,
  // ACL
  ACL.Hashes,
  ACL.Math;
  
const
  SQLErrorMessage = 'Error: %s (%d)' + acCRLF + 'Last query:' + acCRLF + '%s';

  SQLITE_GET_TABLES_QUERY = 'SELECT name FROM sqlite_master WHERE (type="table") ORDER BY name;';

type

  { TSQLLiteHelper }

  TSQLLiteHelper = class
  strict private
    class function KeyFind(AVar1, AVar2: Pointer): Integer; static;
  public
    // Callback methods
    class procedure FreeText(P: Pointer); cdecl; static;
    // Collation
    class function LogicalCompare(UserData: Pointer; P1Size: Integer; P1: PWideChar; P2Size: Integer; P2: PWideChar): Integer; cdecl; static;
    class function NoCaseCompare(UserData: Pointer; P1Size: Integer; P1: PWideChar; P2Size: Integer; P2: PWideChar): Integer; cdecl; static;
    // Additional Methods
    class procedure Base64(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray); cdecl; static;
    class procedure KeyContains(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray); cdecl; static;
    class procedure KeyContainsOneFrom(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray); cdecl; static;
    class procedure KeyContainsOneFromRange(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray); cdecl; static;
    class procedure KeyExclude(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray); cdecl; static;
    class procedure KeyInclude(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray); cdecl; static;
    class procedure Lower(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray); cdecl; static;
    class procedure Upper(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray); cdecl; static;
  end;

//=============================================================================
// Formatting
//=============================================================================

function PrepareData(const AData: Int64): UnicodeString; inline; overload;
begin
  Result := IntToStr(AData);
end;

function PrepareData(const AData: UnicodeString): UnicodeString; inline; overload;
begin
  //# Surrogates does not supported by SQLite
  Result := acRemoveSurrogates(AData, ' ');
  Result := #39 + acStringReplace(Result, #39, #39#39) + #39;
end;

function PrepareData(const AData: Variant): UnicodeString;
begin
  if VarIsStr(AData) then
    Result := PrepareData(UnicodeString(AData))
  else if VarType(AData) in [varSingle, varDouble, varCurrency, varDate] then
    Result := SQLiteFormatDouble(AData)
  else if VarIsNull(AData) then
    Result := 'NULL'
  else
    Result := IntToStr(AData);
end;

function SQLiteFormatDouble(const AValue: Double): UnicodeString;
begin
  Result := FloatToStr(AValue, InvariantFormatSettings);
end;

function SQLiteEncodeDateTime(const DateTime: TDateTime): UnicodeString;
begin
  Result := SQLiteFormatDouble(DateTime);
end;

//=============================================================================
// Variables
//=============================================================================

function SQLiteVarToDouble(AValue: Pointer): Double;
begin
  Result := sqlite3_value_double(AValue);
end;

function SQLiteVarToInt32(AValue: Pointer): Integer;
begin
  Result := sqlite3_value_int(AValue);
end;

function SQLiteVarToInt64(AValue: Pointer): Int64;
begin
  Result := sqlite3_value_int64(AValue);
end;

function SQLiteVarToText(AValue: Pointer): UnicodeString;
begin
  SetString(Result, sqlite3_value_text16(AValue), sqlite3_value_bytes16(AValue) div SizeOf(WideChar));
end;

procedure SQLiteResultSet(AContext: HSQLCONTEXT; const AValue: Double); overload;
begin
  sqlite3_result_double(AContext, AValue);
end;

procedure SQLiteResultSet(AContext: HSQLCONTEXT; const AValue: Integer); overload;
begin
  sqlite3_result_int(AContext, AValue);
end;

procedure SQLiteResultSet(AContext: HSQLCONTEXT; const AValue: UnicodeString); overload;
var
  AData: PWideChar;
  ALength: Integer;
begin
  AData := acAllocStr(AValue, ALength);
  sqlite3_result_text16(AContext, AData, ALength * SizeOf(WideChar), TSQLLiteHelper.FreeText);
end;

procedure SQLiteResultSetNull(AContext: HSQLCONTEXT);
begin
  sqlite3_result_null(AContext);
end;

//=============================================================================
// Variables
//=============================================================================

{ EACLSQLiteError }

constructor EACLSQLiteError.Create(AHandle: HSQLDB; AError: Integer; const AAdditionalInfo: string);
begin
  FErrorCode := AError;
  inherited CreateFmt(SQLErrorMessage, [sqlite3_errmsg16(AHandle), AError, AAdditionalInfo]);
end;

{ TACLSQLiteTable }

constructor TACLSQLiteTable.Create(ADatabase: TACLSQLiteBase; AQuery: HSQLQUERY);
begin
  inherited Create;
  FColumns := TACLObjectList.Create;
  FDatabase := ADatabase;
  FQuery := AQuery;
end;

destructor TACLSQLiteTable.Destroy;
begin
  sqlite3_finalize(FQuery);
  FreeAndNil(FColumns);
  inherited Destroy;
end;

function TACLSQLiteTable.GetFieldIndex(const Name: UnicodeString): Integer;
var
  AColumn: TACLSQLiteColumn;
  AHash, I: Integer;
begin
  AHash := ElfHash(Name);
  if not FDataTypesFetched then
    FDataTypesFetched := FetchDataTypes;
  Result := -1;
  for I := 0 to FColumns.Count - 1 do
  begin
    AColumn := TACLSQLiteColumn(FColumns.List[I]);
    if (AColumn.NameHash = AHash) and acSameText(AColumn.Name, Name) then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TACLSQLiteTable.NextRecord: Boolean;
begin
  Result := sqlite3_step(FQuery) = SQLITE_ROW;
end;

function TACLSQLiteTable.ReadBlob(AIndex: Integer; AData: TMemoryStream): Integer;
var
  ABlobBuffer: PByte;
begin
  Result := sqlite3_column_bytes16(FQuery, AIndex);
  if Assigned(AData) then
  begin
    ABlobBuffer := sqlite3_column_blob(FQuery, AIndex);
    if Assigned(ABlobBuffer) then
    begin
      AData.Size := Result;
      Move(ABlobBuffer^, AData.Memory^, AData.Size);
    end
    else
      AData.Size := 0;
  end;
end;

function TACLSQLiteTable.ReadBlob(const AName: UnicodeString; AData: TMemoryStream): Integer;
begin
  Result := ReadBlob(GetFieldIndex(AName), AData);
end;

function TACLSQLiteTable.ReadDouble(AIndex: Integer): Double;
begin
  Result := sqlite3_column_double(FQuery, AIndex);
end;

function TACLSQLiteTable.ReadDouble(const AName: UnicodeString): Double;
begin
  Result := ReadDouble(GetFieldIndex(AName));
end;

function TACLSQLiteTable.ReadInt(AIndex: Integer): Int64;
begin
  Result := sqlite3_column_int64(FQuery, AIndex);
end;

function TACLSQLiteTable.ReadInt(const AName: UnicodeString): Int64;
begin
  Result := ReadInt(GetFieldIndex(AName));
end;

function TACLSQLiteTable.ReadStr(AIndex: Integer; ASharedStrings: TACLStringSharedTable): UnicodeString;
var
  L: Integer;
  P: PWideChar;
begin
  P := ReadStr(AIndex, L);
  if ASharedStrings <> nil then
    Result := ASharedStrings.Share(P, L)
  else
    Result := acMakeString(P, L);
end;

function TACLSQLiteTable.ReadStr(AIndex: Integer; out ALength: Integer): PWideChar;
begin
  ALength := sqlite3_column_bytes16(FQuery, AIndex) div SizeOf(WideChar);
  Result := sqlite3_column_text16(FQuery, AIndex);
end;

function TACLSQLiteTable.ReadStr(const AName: UnicodeString; ASharedStrings: TACLStringSharedTable): UnicodeString;
begin
  Result := ReadStr(GetFieldIndex(AName), ASharedStrings);
end;

function TACLSQLiteTable.FetchDataTypes: Boolean;
var
  AColumn: TACLSQLiteColumn;
  ADataType: Integer;
  I, ACount: Integer;
begin
  FColumns.Clear;
  ACount := sqlite3_column_count(FQuery);
  FColumns.Capacity := ACount;
  for I := 0 to ACount - 1 do
  begin
    ADataType := MinMax(sqlite3_column_type(FQuery, I), 0, SQLITE_NULL);
    AColumn := TACLSQLiteColumn.Create;
    AColumn.FName := sqlite3_column_name16(FQuery, I);
    AColumn.FNameHash := ElfHash(AColumn.FName);
    AColumn.FDataType := TACLSQLiteColumnType(ADataType);
    FColumns.Add(AColumn);
  end;
  Result := True;
end;

function TACLSQLiteTable.GetColumn(Index: Integer): TACLSQLiteColumn;
begin
  if not FDataTypesFetched then
    FDataTypesFetched := FetchDataTypes;
  Result := TACLSQLiteColumn(FColumns[Index]);
end;

function TACLSQLiteTable.GetColumnCount: Integer;
begin
  if not FDataTypesFetched then
    FDataTypesFetched := FetchDataTypes;
  Result := FColumns.Count;
end;

{ TACLSQLiteBase }

constructor TACLSQLiteBase.Create(const AFileName: UnicodeString);
begin
  inherited Create;
  FFileName := AFileName;
  FLock := TACLCriticalSection.Create(Self);

  CheckError(sqlite3_open16(PWideChar(AFileName), FHandle));
  CheckError(sqlite3_create_collation16(Handle, 'NOCASE', SQLITE_UTF16, nil, @TSQLLiteHelper.NoCaseCompare));
  CheckError(sqlite3_create_collation16(Handle, 'UNICODE', SQLITE_UTF16, nil, @TSQLLiteHelper.NoCaseCompare));
  CheckError(sqlite3_create_collation16(Handle, 'LOGICAL', SQLITE_UTF16, nil, @TSQLLiteHelper.LogicalCompare));
  CheckError(sqlite3_busy_timeout(Handle, 10000));

  InitializeFunctions;
  InitializeTables;
end;

destructor TACLSQLiteBase.Destroy;
begin
  Lock;
  try
    DestroySubClasses;
  finally
    Unlock;
  end;
  inherited Destroy;
  FreeAndNil(FLock);
end;

procedure TACLSQLiteBase.Compress;
begin
  Exec('VACUUM');
end;

procedure TACLSQLiteBase.Compress(out AOldSize, ANewSize: Int64);
begin
  Lock;
  try
    AOldSize := acFileSize(FileName);
    Compress;
    ANewSize := acFileSize(FileName);
  finally
    Unlock;
  end;
end;

function TACLSQLiteBase.FetchColumns(const ATableName: UnicodeString): TACLStringList;
var
  ATable: TACLSQLiteTable;
begin
  Lock;
  try
    Result := TACLStringList.Create;
    if Exec('PRAGMA table_info(' + ATableName + ');', ATable) then
    try
      repeat
        Result.Add(ATable.ReadStr('name'));
      until not ATable.NextRecord;
    finally
      ATable.Free;
    end;
  finally
    Unlock;
  end;
end;

procedure TACLSQLiteBase.BeginUpdate;
begin
  Lock;
//#AI: this is not safe: https://www.sqlite.org/howtocorrupt.html
//  if FUpdateCount = 0 then
//    Exec(SYNC_CMD + SYNC_NONE);
  Inc(FUpdateCount);
end;

procedure TACLSQLiteBase.EndUpdate;
begin
  Dec(FUpdateCount);
//  if FUpdateCount = 0 then
//    Exec(SYNC_CMD + SYNC_FULL);
  Unlock;
end;

procedure TACLSQLiteBase.Exec(const AFormatLine: UnicodeString; const AArguments: array of const);
begin
  Exec(Format(AFormatLine, AArguments));
end;

function TACLSQLiteBase.Exec(const AQuery: UnicodeString; out AHandle: HSQLQUERY): Boolean;
begin
  Lock;
  try
    PrepareQuery(AQuery, AHandle);
    Result := sqlite3_step(AHandle) = SQLITE_ROW;
    if not Result then
      sqlite3_finalize(AHandle);
  finally
    Unlock;
  end;
end;

function TACLSQLiteBase.Exec(const AQuery: UnicodeString; out ATable: TACLSQLiteTable): Boolean;
var
  AQueryHandle: HSQLQUERY;
begin
  Result := Exec(AQuery, AQueryHandle);
  if Result then
    ATable := GetTableClass.Create(Self, AQueryHandle);
end;

procedure TACLSQLiteBase.Exec(const AQuery: UnicodeString);
var
  AQueryHandle: HSQLQUERY;
begin
  Lock;
  try
    PrepareQuery(AQuery, AQueryHandle);
    CheckError(sqlite3_step(AQueryHandle));
    sqlite3_finalize(AQueryHandle);
  finally
    Unlock;
  end;
end;

function TACLSQLiteBase.ExecInt(const AQuery: UnicodeString): Int64;
var
  ATable: TACLSQLiteTable;
begin
  Lock;
  try
    Result := -1;
    if Exec(AQuery, ATable) then
    try
      Result := ATable.ReadInt(0);
    finally
      FreeAndNil(ATable);
    end;
  finally
    Unlock;
  end;
end;

procedure TACLSQLiteBase.ExecInsertBlob(const AQuery: UnicodeString; const AData: TMemoryStream);
begin
  if AData <> nil then
    ExecInsertBlob(AQuery, AData.Memory, AData.Size)
  else
    ExecInsertBlob(AQuery, nil, 0);
end;

procedure TACLSQLiteBase.ExecInsertBlob(const AQuery: UnicodeString; const AData: PByte; const ASize: Int64);
var
  AQueryHandle: HSQLQUERY;
begin
  Lock;
  try
    PrepareQuery(AQuery, AQueryHandle);
    try
      sqlite3_bind_blob(AQueryHandle, 1, AData, ASize, SQLITE_STATIC);
      CheckError(sqlite3_step(AQueryHandle));
    finally
      sqlite3_finalize(AQueryHandle);
    end;
  finally
    Unlock;
  end;
end;

procedure TACLSQLiteBase.Transaction(Proc: TProcedureRef);
begin
  Lock;
  try
    Exec('BEGIN;');
    try
      Proc();
      Exec('COMMIT;');
    except
      Exec('ROLLBACK;');
      raise;
    end;
  finally
    Unlock;
  end;
end;

procedure TACLSQLiteBase.CheckError(AErrorCode: Integer; const AAdditionalInfo: string = '');
begin
  if (AErrorCode <> SQLITE_OK) and (AErrorCode < SQLITE_ROW) then
    raise EACLSQLiteError.Create(Handle, AErrorCode, AAdditionalInfo);
end;

procedure TACLSQLiteBase.CreateFunction(const AName: PWideChar; AArgCount: Integer; AFunc: TSQLFunction);
begin
  CheckError(sqlite3_create_function16(Handle, AName, AArgCount, SQLITE_UTF16, nil, AFunc, nil, nil));
end;

procedure TACLSQLiteBase.DestroySubClasses;
begin
  CheckError(sqlite3_close(Handle));
  FHandle := nil;
end;

function TACLSQLiteBase.GetTableClass: TACLSQLiteTableClass;
begin
  Result := TACLSQLiteTable;
end;

function TACLSQLiteBase.GetVersion: Integer;
begin
  Result := ExecInt('PRAGMA user_version');
end;

procedure TACLSQLiteBase.InitializeFunctions;
begin
  CreateFunction('Base64', 1, @TSQLLiteHelper.Base64);
  CreateFunction('KeyContains', 2, @TSQLLiteHelper.KeyContains);
  CreateFunction('KeyContainsOneFrom', -1, @TSQLLiteHelper.KeyContainsOneFrom);
  CreateFunction('KeyContainsOneFromRange', 3, @TSQLLiteHelper.KeyContainsOneFromRange);
  CreateFunction('KeyExclude', 2, @TSQLLiteHelper.KeyExclude);
  CreateFunction('KeyInclude', 2, @TSQLLiteHelper.KeyInclude);
  CreateFunction('Lower', 1, @TSQLLiteHelper.Lower);
  CreateFunction('Upper', 1, @TSQLLiteHelper.Upper);
end;

procedure TACLSQLiteBase.InitializeTables;
begin
  // do nothing
end;

procedure TACLSQLiteBase.PrepareQuery(const S: UnicodeString; out AHandle: HSQLQUERY);
var
  ANext: PWideChar;
begin
  CheckError(sqlite3_prepare16_v2(Handle, PWideChar(S), Length(S) * SizeOf(WideChar), AHandle, ANext), S);
end;

procedure TACLSQLiteBase.Lock;
begin
  FLock.Enter;
end;

procedure TACLSQLiteBase.Unlock;
begin
  FLock.Leave;
end;

procedure TACLSQLiteBase.SetVersion(AValue: Integer);
begin
  Exec('PRAGMA user_version = ' + PrepareData(AValue));
end;

{ TSQLLiteHelper }

class procedure TSQLLiteHelper.FreeText(P: Pointer);
begin
  FreeMem(P);
end;

class function TSQLLiteHelper.LogicalCompare(UserData: Pointer; P1Size: Integer; P1: PWideChar; P2Size: Integer; P2: PWideChar): Integer;
begin
  Result := acLogicalCompare(P1, P2, P1Size div SizeOf(WideChar), P2Size div SizeOf(WideChar));
end;

class function TSQLLiteHelper.NoCaseCompare(UserData: Pointer; P1Size: Integer; P1: PWideChar; P2Size: Integer; P2: PWideChar): Integer;
begin
  Result := acCompareStrings(P1, P2, P1Size div SizeOf(WideChar), P2Size div SizeOf(WideChar));
end;

class procedure TSQLLiteHelper.Base64(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray);
var
  AStream: TStringStream;
begin
  AStream := TStringStream.Create;
  try
    TACLMimecode.EncodeString(acEncodeUTF8(SQLiteVarToText(Vars^[0])), AStream);
    SQLiteResultSet(Context, AStream.DataString);
  finally
    AStream.Free;
  end;
end;

class procedure TSQLLiteHelper.KeyContains(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray); cdecl;
begin
  SQLiteResultSet(Context, Ord(KeyFind(Vars^[0], Vars^[1]) >= 0));
end;

class procedure TSQLLiteHelper.KeyContainsOneFrom(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray);
var
  AResult: Boolean;
  I: Integer;
begin
  AResult := False;
  for I := 1 to Count - 1 do
  begin
    AResult := KeyFind(Vars^[0], Vars^[I]) >= 0;
    if AResult then
      Break;
  end;
  SQLiteResultSet(Context, Ord(AResult));
end;

class procedure TSQLLiteHelper.KeyContainsOneFromRange(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray); cdecl;
var
  AKeyLength: Integer;
  AKeys, AScan: PWideChar;
  AKeysLength: Integer;
  AValue1, AValue2: Integer;
begin
  AKeysLength := sqlite3_value_bytes16(Vars^[0]) div SizeOf(WideChar);
  AKeys := sqlite3_value_text16(Vars^[0]);
  AValue1 := SQLiteVarToInt32(Vars^[1]);
  AValue2 := SQLiteVarToInt32(Vars^[2]);
  repeat
    AScan := WStrScan(AKeys, AKeysLength, sKeyDelim);
    if AScan <> nil then
    begin
      AKeyLength := (NativeUInt(AScan) - NativeUInt(AKeys)) div SizeOf(WideChar);
      Inc(AScan); // Skip Separator
    end
    else
      AKeyLength := AKeysLength;

    if InRange(acPWideCharToIntDef(AKeys, AKeyLength, 0), AValue1, AValue2) then
    begin
      SQLiteResultSet(Context, 1);
      Exit;
    end;

    AKeys := AScan;
    Dec(AKeysLength, AKeyLength + 1);
  until AKeysLength <= 0;
  SQLiteResultSet(Context, 0);
end;

class procedure TSQLLiteHelper.KeyExclude(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray); cdecl;
var
  AData: UnicodeString;
  APosition: Integer;
begin
  if Count = 2 then
  begin
    APosition := KeyFind(Vars^[0], Vars^[1]);
    AData := SQLiteVarToText(Vars^[0]);
    if APosition >= 0 then
    begin
      Delete(AData, APosition + 1, sqlite3_value_bytes16(Vars^[1]) div SizeOf(WideChar) + 1);
      AData := acStringReplace(AData, sKeyDelim + sKeyDelim, sKeyDelim);
      APosition := Length(AData);
      if (APosition > 0) and (AData[APosition] = sKeyDelim) then
        Delete(AData, APosition, 1);
    end;
    SQLiteResultSet(Context, AData);
  end
  else
    SQLiteResultSetNull(Context);
end;

class procedure TSQLLiteHelper.KeyInclude(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray); cdecl;
var
  AData: UnicodeString;
  APosition: Integer;
begin
  if Count = 2 then
  begin
    APosition := KeyFind(Vars^[0], Vars^[1]);
    AData := SQLiteVarToText(Vars^[0]);
    if APosition < 0 then
    begin
      AData := AData + IfThenW(AData <> '', sKeyDelim) + SQLiteVarToText(Vars^[1]);
      AData := acStringReplace(AData, sKeyDelim + sKeyDelim, sKeyDelim);
    end;
    SQLiteResultSet(Context, AData);
  end
  else
    SQLiteResultSetNull(Context);
end;

class procedure TSQLLiteHelper.Upper(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray);
var
  L: Integer;
  W: PWideChar;
begin
  W := sqlite3_value_text16(Vars^[0]);
  L := sqlite3_value_bytes16(Vars^[0]) div SizeOf(WideChar);
  LCMapString(LOCALE_USER_DEFAULT, LCMAP_UPPERCASE or LCMAP_LINGUISTIC_CASING, W, L, W, L);
  sqlite3_result_text16(Context, W, L * SizeOf(WideChar), nil);
end;

class procedure TSQLLiteHelper.Lower(Context: HSQLCONTEXT; Count: Integer; Vars: PPointerArray);
var
  L: Integer;
  W: PWideChar;
begin
  W := sqlite3_value_text16(Vars^[0]);
  L := sqlite3_value_bytes16(Vars^[0]) div SizeOf(WideChar);
  LCMapString(LOCALE_USER_DEFAULT, LCMAP_LOWERCASE or LCMAP_LINGUISTIC_CASING, W, L, W, L);
  sqlite3_result_text16(Context, W, L * SizeOf(WideChar), nil);
end;

class function TSQLLiteHelper.KeyFind(AVar1, AVar2: Pointer): Integer;
var
  I: Integer;
  L: WideChar;
  L1, L2: Integer;
  T1, T2: PWideChar;
begin
  Result := -1;
  L1 := sqlite3_value_bytes16(AVar1) div SizeOf(WideChar);
  L2 := sqlite3_value_bytes16(AVar2) div SizeOf(WideChar);
  if (L1 = L2) and (L2 = 0) then
    Result := 0
  else
    if (L1 >= L2) and (L2 > 0) then
    begin
      L := sKeyDelim;
      T1 := sqlite3_value_text16(AVar1);
      T2 := sqlite3_value_text16(AVar2);
      for I := 0 to L1 - L2 do
      begin
        if (L = sKeyDelim) and ((I + L2 = L1) or (PWideChar(T1 + L2)^ = sKeyDelim)) and CompareMem(T1, T2, L2 * SizeOf(WideChar)) then
        begin
          Result := I;
          Break;
        end;
        L := T1^;
        Inc(T1);
      end;
    end;
end;

{ TACLSQLQueryBuilder }

constructor TACLSQLQueryBuilder.Create;
begin
  FBuffer := TStringBuilder.Create(256);
end;

destructor TACLSQLQueryBuilder.Destroy;
begin
  FreeAndNil(FBuffer);
  inherited;
end;

class function TACLSQLQueryBuilder.New: TACLSQLQueryBuilder;
begin
  Result := TACLSQLQueryBuilder.Create;
end;

function TACLSQLQueryBuilder.ToString: string;
begin
  Result := FBuffer.ToString;
end;

function TACLSQLQueryBuilder.Done: string;
begin
  Result := Raw(';').ToString;
  Free;
end;

function TACLSQLQueryBuilder.DropTable: TACLSQLQueryBuilder;
begin
  Result := Raw('DROP TABLE ');
end;

function TACLSQLQueryBuilder.Raw(const S: string): TACLSQLQueryBuilder;
begin
  FPrevIsValue := False;
  FBuffer.Append(S);
  Result := Self;
end;

function TACLSQLQueryBuilder.Rename: TACLSQLQueryBuilder;
begin
  Result := Raw(' RENAME ');
end;

function TACLSQLQueryBuilder.Replace: TACLSQLQueryBuilder;
begin
  Result := Raw('REPLACE ');
end;

function TACLSQLQueryBuilder.N(const AName: UnicodeString): TACLSQLQueryBuilder;
begin
  Result := ValCore(AName); // todo, blob markers
end;

function TACLSQLQueryBuilder.V(const AValue: Double): TACLSQLQueryBuilder;
begin
  Result := ValCore(SQLiteFormatDouble(AValue));
end;

function TACLSQLQueryBuilder.V(const AValue: UnicodeString): TACLSQLQueryBuilder;
begin
  Result := ValCore(PrepareData(AValue));
end;

function TACLSQLQueryBuilder.V(const AValue: Variant): TACLSQLQueryBuilder;
begin
  Result := ValCore(PrepareData(AValue));
end;

function TACLSQLQueryBuilder.V(const AValue: Single): TACLSQLQueryBuilder;
begin
  Result := ValCore(SQLiteFormatDouble(AValue));
end;

function TACLSQLQueryBuilder.V(const AValue: Integer): TACLSQLQueryBuilder;
begin
  Result := ValCore(IntToStr(AValue));
end;

function TACLSQLQueryBuilder.V(const AValue: Int64): TACLSQLQueryBuilder;
begin
  Result := ValCore(IntToStr(AValue));
end;

function TACLSQLQueryBuilder.V(const AValue: TDateTime): TACLSQLQueryBuilder;
begin
  Result := ValCore(SQLiteEncodeDateTime(AValue));
end;

function TACLSQLQueryBuilder.VBlob: TACLSQLQueryBuilder;
begin
  Result := ValCore('?');
end;

function TACLSQLQueryBuilder.ValCore(const APreparedValue: string): TACLSQLQueryBuilder;
begin
  if APreparedValue = EmptyStr then
    raise EInvalidArgument.Create('Value cannot be set to an empty value');
  if FPrevIsValue then
  begin
    FBuffer.Append(', ');
    FPrevIsValue := False;
  end;
  Result := Raw(APreparedValue);
  FPrevIsValue := True;
end;

function TACLSQLQueryBuilder.OpenBracket: TACLSQLQueryBuilder;
begin
  if FPrevIsValue then
  begin
    FBuffer.Append(' ');
    FPrevIsValue := False;
  end;
  Result := Raw('(');
end;

function TACLSQLQueryBuilder.CloseBracket: TACLSQLQueryBuilder;
begin
  Result := Raw(')');
end;

function TACLSQLQueryBuilder.Above: TACLSQLQueryBuilder;
begin
  Result := Raw(' > ');
end;

function TACLSQLQueryBuilder.AboveOrEqual: TACLSQLQueryBuilder;
begin
  Result := Raw(' >= ');
end;

function TACLSQLQueryBuilder.AlterTable: TACLSQLQueryBuilder;
begin
  Result := Raw('ALTER TABLE ');
end;

function TACLSQLQueryBuilder.&And: TACLSQLQueryBuilder;
begin
  Result := Raw(' AND ');
end;

function TACLSQLQueryBuilder.&As: TACLSQLQueryBuilder;
begin
  Result := Raw(' as ');
end;

function TACLSQLQueryBuilder.Asterisk: TACLSQLQueryBuilder;
begin
  Result := Raw('*');
end;

function TACLSQLQueryBuilder.Below: TACLSQLQueryBuilder;
begin
  Result := Raw(' < ');
end;

function TACLSQLQueryBuilder.BelowOrEqual: TACLSQLQueryBuilder;
begin
  Result := Raw(' <= ');
end;

function TACLSQLQueryBuilder.Equal: TACLSQLQueryBuilder;
begin
  Result := Raw(' = ');
end;

function TACLSQLQueryBuilder.&Not: TACLSQLQueryBuilder;
begin
  Result := Raw(' NOT ');
end;

function TACLSQLQueryBuilder.NotEquals: TACLSQLQueryBuilder;
begin
  Result := Raw(' <> ');
end;

function TACLSQLQueryBuilder.&On: TACLSQLQueryBuilder;
begin
  Result := Raw(' ON ');
end;

function TACLSQLQueryBuilder.&Or: TACLSQLQueryBuilder;
begin
  Result := Raw(' OR ');
end;

function TACLSQLQueryBuilder.OrderBy: TACLSQLQueryBuilder;
begin
  Result := Raw(' ORDER BY ');
end;

function TACLSQLQueryBuilder.Plus: TACLSQLQueryBuilder;
begin
  Result := Raw('+');
end;

function TACLSQLQueryBuilder.CreateIndex: TACLSQLQueryBuilder;
begin
  Result := Raw('CREATE UNIQUE INDEX IF NOT EXISTS ');
end;

function TACLSQLQueryBuilder.CreateTable: TACLSQLQueryBuilder;
begin
  Result := Raw('CREATE TABLE IF NOT EXISTS ');
end;

function TACLSQLQueryBuilder.Comma: TACLSQLQueryBuilder;
begin
  Result := Raw(', ');
end;

function TACLSQLQueryBuilder.Count: TACLSQLQueryBuilder;
begin
  Result := Raw('Count');
end;

function TACLSQLQueryBuilder.Delete: TACLSQLQueryBuilder;
begin
  Result := Raw('DELETE ');
end;

function TACLSQLQueryBuilder.DeleteFrom(const TableName: string): TACLSQLQueryBuilder;
begin
  Result := Delete.From.N(TableName);
end;

function TACLSQLQueryBuilder.Descending: TACLSQLQueryBuilder;
begin
  Result := Raw(' DESC ');
end;

function TACLSQLQueryBuilder.Distinct: TACLSQLQueryBuilder;
begin
  Result := Raw(' DISTINCT ');
end;

function TACLSQLQueryBuilder.From: TACLSQLQueryBuilder;
begin
  Result := Raw(' FROM ');
end;

function TACLSQLQueryBuilder.GroupBy: TACLSQLQueryBuilder;
begin
  Result := Raw(' GROUP BY ');
end;

function TACLSQLQueryBuilder.Insert: TACLSQLQueryBuilder;
begin
  Result := Raw('INSERT ');
end;

function TACLSQLQueryBuilder.Into: TACLSQLQueryBuilder;
begin
  Result := Raw('INTO ');
end;

function TACLSQLQueryBuilder.Limit(ALimit: Integer): TACLSQLQueryBuilder;
begin
  Result := Limit(0, ALimit);
end;

function TACLSQLQueryBuilder.Limit(AStart, ALimit: Integer): TACLSQLQueryBuilder;
begin
  if (AStart > 0) or (ALimit > 0) then
  begin
    Raw(' LIMIT ');
    if AStart > 0 then
    begin
      Raw(IntToStr(AStart));
      Raw(', ');
    end;
    if ALimit > 0 then
      Raw(IntToStr(ALimit))
    else
      Raw(IntToStr(MaxInt));
  end;
  Result := Self;
end;

function TACLSQLQueryBuilder.Minus: TACLSQLQueryBuilder;
begin
  Result := Raw('-');
end;

function TACLSQLQueryBuilder.Select: TACLSQLQueryBuilder;
begin
  Result := Raw('SELECT ');
end;

function TACLSQLQueryBuilder.SelectAll: TACLSQLQueryBuilder;
begin
  Result := Raw('SELECT * ');
end;

function TACLSQLQueryBuilder.&Set: TACLSQLQueryBuilder;
begin
  Result := Raw(' SET ');
end;

function TACLSQLQueryBuilder.&To: TACLSQLQueryBuilder;
begin
  Result := Raw(' TO ');
end;

function TACLSQLQueryBuilder.Values: TACLSQLQueryBuilder;
begin
  Result := Raw(' VALUES ');
end;

function TACLSQLQueryBuilder.Where: TACLSQLQueryBuilder;
begin
  Result := Raw(' WHERE ');
end;

function TACLSQLQueryBuilder.TypeAuto: TACLSQLQueryBuilder;
begin
  Result := TypeCore(' AUTOINCREMENT');
end;

function TACLSQLQueryBuilder.TypeBlob: TACLSQLQueryBuilder;
begin
  Result := TypeCore(' BLOB');
end;

function TACLSQLQueryBuilder.TypeCore(const APreparedValue: string): TACLSQLQueryBuilder;
begin
  Result := Raw(APreparedValue);
  FPrevIsValue := True;
end;

function TACLSQLQueryBuilder.TypeDouble: TACLSQLQueryBuilder;
begin
  Result := TypeCore(' DOUBLE');
end;

function TACLSQLQueryBuilder.TypeInt32: TACLSQLQueryBuilder;
begin
  Result := TypeCore(' INTEGER');
end;

function TACLSQLQueryBuilder.TypeInt64: TACLSQLQueryBuilder;
begin
  Result := TypeCore(' INT64');
end;

function TACLSQLQueryBuilder.TypePrimaryKey: TACLSQLQueryBuilder;
begin
  Result := TypeCore(' PRIMARY KEY');
end;

function TACLSQLQueryBuilder.TypeText: TACLSQLQueryBuilder;
begin
  Result := TypeCore(' TEXT COLLATE UNICODE');
end;

function TACLSQLQueryBuilder.Unique: TACLSQLQueryBuilder;
begin
  Result := Raw(' UNIQUE ');
end;

function TACLSQLQueryBuilder.Update: TACLSQLQueryBuilder;
begin
  Result := Raw('UPDATE ');
end;

end.
