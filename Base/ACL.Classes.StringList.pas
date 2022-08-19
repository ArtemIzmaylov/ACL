{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*             StringList Class              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Classes.StringList;

{$I ACL.Config.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  // ACL
  ACL.Classes,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type

  { TACLStringList }

  TACLStringList = class;

  PACLStringListItem = ^TACLStringListItem;
  TACLStringListItem = packed record
    FInterface: IUnknown;
    FObject: TObject;
    FString: UnicodeString;

    procedure Exchange(var Item: TACLStringListItem); inline;
    procedure MoveFrom(const Item: TACLStringListItem); inline;
  end;

  PACLStringListItemList = ^TACLStringListItemList;
  TACLStringListItemList = array[0..0] of TACLStringListItem;

  TACLStringListCompareProc = reference to function (const Item1, Item2: TACLStringListItem): Integer;

  TACLStringList = class(TACLUnknownPersistent,
    IACLUpdateLock,
    IStringReceiver)
  strict private
    FCapacity: Integer;
    FCount: Integer;
    FData: Pointer;
    FDelimiter: WideChar;
    FIgnoryCase: Boolean;
    FList: PACLStringListItemList;

    function GetCount: Integer;
    function GetInterface(AIndex: Integer): IUnknown;
    function GetName(AIndex: Integer): UnicodeString;
    function GetObject(AIndex: Integer): TObject;
    function GetString(AIndex: Integer): UnicodeString;
    function GetText: UnicodeString;
    function GetValue(AIndex: Integer): UnicodeString;
    function GetValueFromName(const S: UnicodeString): UnicodeString;
    procedure SetCapacity(Value: Integer);
    procedure SetInterface(AIndex: Integer; const AValue: IUnknown);
    procedure SetName(Index: Integer; const Value: UnicodeString);
    procedure SetObject(AIndex: Integer; const AValue: TObject);
    procedure SetValue(Index: Integer; const Value: UnicodeString);
    procedure SetValueFromName(const AName, AValue: UnicodeString);
    //
    procedure Grow;
    procedure ParseBuffer(ABuffer: PWideChar; ACount: Integer);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure Changed; virtual;
    procedure SetString(AIndex: Integer; const AValue: UnicodeString); virtual;
    procedure SetText(const S: UnicodeString); virtual;
    // IStringReceiver
    procedure IStringReceiver.Add = DoAdd;
    procedure DoAdd(const S: UnicodeString);
    //
    property List: PACLStringListItemList read FList;
  public
    constructor Create; overload;
    constructor Create(const AText: UnicodeString; ASplitText: Boolean = False); overload;
    destructor Destroy; override;
    procedure EnsureCapacity(ACount: Integer);
    function Clone: TACLStringList;
    function IsValid(AIndex: Integer): Boolean; inline;
    procedure Exchange(Index1, Index2: Integer);
    procedure TrimLines;

    function GetDelimitedText(const ADelimiter: UnicodeString; AAddTrailingDelimiter: Boolean = True): UnicodeString;
    procedure SetDelimitedText(const AText: UnicodeString; ADelimiter: WideChar);

    // Lock / Unlock
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;

    // I/O
    function LoadFromFile(const AFileName: UnicodeString; AEncoding: TEncoding = nil): Boolean;
    procedure LoadFromStream(AStream: TStream; AEncoding: TEncoding = nil); virtual;
    procedure LoadFromResource(AInstance: HINST; const AName: UnicodeString; AType: PChar);
    function SaveToFile(const AFile: UnicodeString; AEncoding: TEncoding = nil): Boolean;
    procedure SaveToStream(AStream: TStream; AEncoding: TEncoding = nil); virtual;

    // Inserting
    function Add(const S: UnicodeString; const AObject: NativeInt): Integer; overload;
    function Add(const S: UnicodeString; const AObject: TObject = nil; AInterface: IUnknown = nil): Integer; overload;
    procedure AddEx(const S: UnicodeString);
    procedure Append(const ASource: TACLStringList);
    procedure Assign(Source: TPersistent); override;
    procedure Insert(Index: Integer; const S: UnicodeString; const AObject: TObject = nil; AInterface: IUnknown = nil); virtual;

    // Search
    function Contains(const S: UnicodeString): Boolean;
    function IndexOf(const S: UnicodeString): Integer; virtual;
    function IndexOfName(const AName: UnicodeString): Integer;
    function IndexOfObject(const AObject: TObject): Integer;

    // Removing
    procedure Clear; virtual;
    function Delete(AIndex: Integer): Boolean; inline;
    function DeleteAll: Boolean;
    function DeleteRange(AIndex, ACount: Integer): Boolean;
    function Pack: Integer;
    function Remove(const AObject: NativeUInt): Integer; overload;
    function Remove(const AObject: TObject): Integer; overload;
    function Remove(const S: UnicodeString): Integer; overload;
    function RemoveDuplicates: Integer;

    // Sorting
    procedure Sort; overload;
    procedure Sort(ACompareProc: TACLStringListCompareProc; UseThreading: Boolean); overload;
    procedure SortLogical;
    //
    function First: UnicodeString; inline;
    function Last: UnicodeString; inline;

    // Properties
    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read GetCount;
    property Data: Pointer read FData write FData;
    property Delimiter: WideChar read FDelimiter write FDelimiter;
    property IgnoryCase: Boolean read FIgnoryCase write FIgnoryCase;
    property Text: UnicodeString read GetText write SetText;

    // Row data
    property Interfaces[AIndex: Integer]: IUnknown read GetInterface write SetInterface;
    property Names[Index: Integer]: UnicodeString read GetName write SetName;
    property Objects[Index: Integer]: TObject read GetObject write SetObject;
    property Strings[Index: Integer]: UnicodeString read GetString write SetString; default;
    property ValueFromIndex[Index: Integer]: UnicodeString read GetValue write SetValue;
    property ValueFromName[const Name: UnicodeString]: UnicodeString read GetValueFromName write SetValueFromName;
  end;

  { TACLSortedStrings }

  TACLSortedStrings = class(TACLStringList)
  protected
    procedure SetString(AIndex: Integer; const AValue: UnicodeString); override;
  public
    procedure AfterConstruction; override;
    function Find(const P: PWideChar; ALength: Integer; out AIndex: Integer): Boolean; overload;
    function Find(const S: UnicodeString; out AIndex: Integer): Boolean; overload;
    function IndexOf(const AItem: UnicodeString): Integer; override;
    procedure Insert(Index: Integer; const S: UnicodeString; const AObject: TObject = nil; AInterface: IUnknown = nil); override;
  end;

implementation

uses
  System.Math,
  // ACL
  ACL.FastCode,
  ACL.Parsers,
  ACL.Threading.Sorting,
  ACL.Utils.FileSystem,
  ACL.Utils.Stream;

{ TACLStringListItem }

procedure TACLStringListItem.Exchange(var Item: TACLStringListItem);
var
  ASwap: Pointer;
begin
  ASwap := Pointer(FString);
  Pointer(FString) := Pointer(Item.FString);
  Pointer(Item.FString) := ASwap;

  ASwap := Pointer(FObject);
  Pointer(FObject) := Pointer(Item.FObject);
  Pointer(Item.FObject) := ASwap;

  ASwap := Pointer(FInterface);
  Pointer(FInterface) := Pointer(Item.FInterface);
  Pointer(Item.FInterface) := ASwap;
end;

procedure TACLStringListItem.MoveFrom(const Item: TACLStringListItem);
begin
  Pointer(FInterface) := Pointer(Item.FInterface);
  Pointer(FObject) := Pointer(Item.FObject);
  Pointer(FString) := Pointer(Item.FString);
end;

{ TACLStringList }

constructor TACLStringList.Create;
begin
  inherited Create;
  FIgnoryCase := True;
  FDelimiter := '=';
end;

constructor TACLStringList.Create(const AText: UnicodeString; ASplitText: Boolean);
begin
  Create;
  if ASplitText then
    Text := AText
  else
  begin
    Capacity := 1;
    Add(AText);
  end;
end;

destructor TACLStringList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TACLStringList.EnsureCapacity(ACount: Integer);
begin
  Capacity := Max(Capacity, Count + ACount);
end;

function TACLStringList.Clone: TACLStringList;
begin
  Result := TACLStringList.Create;
  Result.Assign(Self);
end;

function TACLStringList.Contains(const S: UnicodeString): Boolean;
begin
  Result := IndexOf(S) >= 0;
end;

function TACLStringList.GetDelimitedText(const ADelimiter: UnicodeString; AAddTrailingDelimiter: Boolean = True): UnicodeString;
var
  I, D, L, ASize: Integer;
  P: PWideChar;
  S: UnicodeString;
begin
  ASize := 0;
  D := Length(ADelimiter);
  for I := 0 to Count - 1 do
    Inc(ASize, Length(GetString(I)) + D);
  if not AAddTrailingDelimiter then
    Dec(ASize, D);

  System.SetString(Result, nil, ASize);
  P := Pointer(Result);
  for I := 0 to Count - 1 do
  begin
    S := GetString(I);
    L := Length(S);
    if L <> 0 then
    begin
      FastMove(Pointer(S)^, P^, L * SizeOf(WideChar));
      Inc(P, L);
    end;
    if (D <> 0) and (AAddTrailingDelimiter or (I + 1 < Count)) then
    begin
      FastMove(Pointer(ADelimiter)^, P^, D * SizeOf(WideChar));
      Inc(P, D);
    end;
  end;
end;

procedure TACLStringList.SetDelimitedText(const AText: UnicodeString; ADelimiter: WideChar);
var
  ALength: Integer;
begin
  BeginUpdate;
  try
    Clear;
    ALength := Length(AText);
    if ALength > 0 then
    begin
      if Ord(AText[ALength]) = Ord(ADelimiter) then
        Dec(ALength);
      acExplodeString(PChar(AText), ALength, ADelimiter,
        procedure (ACursorStart, ACursorNext: PWideChar; var ACanContinue: Boolean)
        begin
          Add(acExtractString(ACursorStart, ACursorNext));
        end)
    end;
  finally
    EndUpdate;
  end;
end;

function TACLStringList.IsValid(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Count);
end;

procedure TACLStringList.Exchange(Index1, Index2: Integer);
begin
  if IsValid(Index1) and IsValid(Index2) and (Index1 <> Index2) then
  begin
    List^[Index1].Exchange(List^[Index2]);
    Changed;
  end;
end;

procedure TACLStringList.BeginUpdate;
begin
  // do nothing
end;

procedure TACLStringList.EndUpdate;
begin
  // do nothing
end;

function TACLStringList.LoadFromFile(const AFileName: UnicodeString; AEncoding: TEncoding = nil): Boolean;
var
  AFileStream: TStream;
begin
  Result := StreamCreateReader(AFileName, AFileStream);
  if Result then
  try
    LoadFromStream(AFileStream, AEncoding);
  finally
    AFileStream.Free;
  end;
end;

procedure TACLStringList.LoadFromStream(AStream: TStream; AEncoding: TEncoding = nil);
var
  ATempEncoding: TEncoding;
begin
  if AStream.Size > 0 then
    Text := acLoadString(AStream, AEncoding, ATempEncoding)
  else
    Clear;
end;

procedure TACLStringList.LoadFromResource(AInstance: HINST; const AName: UnicodeString; AType: PChar);
var
  AStream: TResourceStream;
begin
  AStream := TResourceStream.Create(AInstance, AName, AType);
  try
    LoadFromStream(AStream);
  finally
    AStream.Free;
  end;
end;

function TACLStringList.SaveToFile(const AFile: UnicodeString; AEncoding: TEncoding = nil): Boolean;
var
  AStream: TStream;
begin
  acFileSetAttr(AFile, 0);
  Result := StreamCreateWriter(AFile, AStream);
  if Result then
  try
    SaveToStream(AStream, AEncoding);
  finally
    AStream.Free;
  end;
end;

procedure TACLStringList.SaveToStream(AStream: TStream; AEncoding: TEncoding = nil);
begin
  AStream.WriteBOM(AEncoding);
  AStream.WriteString(GetText, AEncoding);
end;

function TACLStringList.Add(const S: UnicodeString; const AObject: TObject; AInterface: IUnknown): Integer;
begin
  Result := Count;
  Insert(Count, S, AObject, AInterface);
end;

function TACLStringList.Add(const S: UnicodeString; const AObject: NativeInt): Integer;
begin
  Result := Add(S, TObject(AObject));
end;

procedure TACLStringList.AddEx(const S: UnicodeString);
begin
  Add(S);
end;

procedure TACLStringList.Append(const ASource: TACLStringList);
var
  I: Integer;
begin
  BeginUpdate;
  try
    EnsureCapacity(ASource.Count);
    for I := 0 to ASource.Count - 1 do
    begin
      with ASource.List[I] do
        Add(FString, FObject, FInterface);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLStringList.Assign(Source: TPersistent);
begin
  if Source is TACLStringList then
  begin
    BeginUpdate;
    try
      Clear;
      Append(TACLStringList(Source));
    finally
      EndUpdate;
    end;
  end;
end;

procedure TACLStringList.Insert(Index: Integer; const S: UnicodeString;
  const AObject: TObject = nil; AInterface: IUnknown = nil);
begin
  if (Index >= 0) and (Index <= Count) then
  begin
    BeginUpdate;
    try
      if Count = Capacity then
        Grow;
      if Index < FCount then
        FastMove(FList^[Index], FList^[Index + 1], (Count - Index) * SizeOf(TACLStringListItem));
      with FList^[Index] do
      begin
        Pointer(FInterface) := nil;
        Pointer(FString) := nil;
        FObject := AObject;
        FInterface := AInterface;
        FString := S;
      end;
      Inc(FCount);
      Changed;
    finally
      EndUpdate;
    end;
  end;
end;

function TACLStringList.IndexOf(const S: UnicodeString): Integer;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if acCompareStrings(S, List[I].FString, IgnoryCase) = 0 then
      Exit(I);
  end;
  Result := -1;
end;

function TACLStringList.IndexOfName(const AName: UnicodeString): Integer;
var
  T, S: UnicodeString;
  I, L: Integer;
begin
  T := AName + Delimiter;
  L := Length(T);
  for I := Count - 1 downto 0 do
  begin
    S := List[I].FString;
    if (Length(S) >= L) and (acCompareStrings(PWideChar(T), PWideChar(S), L, L, IgnoryCase) = 0) then
      Exit(I);
  end;
  Result := -1;
end;

function TACLStringList.IndexOfObject(const AObject: TObject): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Count - 1 do
    if AObject = List[I].FObject then
    begin
      Result := I;
      Break;
    end;
end;

procedure TACLStringList.Clear;
begin
  BeginUpdate;
  try
    DeleteAll;
    SetCapacity(0);
  finally
    EndUpdate;
  end;
end;

function TACLStringList.Delete(AIndex: Integer): Boolean;
begin
  Result := DeleteRange(AIndex, 1);
end;

function TACLStringList.DeleteAll: Boolean;
begin
  Result := DeleteRange(0, Count);
end;

function TACLStringList.DeleteRange(AIndex, ACount: Integer): Boolean;
var
  ATailSize: Integer;
begin
  Result := IsValid(AIndex) and (ACount > 0) and (AIndex + ACount <= Count);
  if Result then
  begin
    BeginUpdate;
    try
      ATailSize := Count - AIndex - ACount;
      Finalize(FList^[AIndex], ACount);
      if ATailSize > 0 then
        FastMove(FList^[AIndex + ACount], FList^[AIndex], ATailSize * SizeOf(TACLStringListItem));
      Dec(FCount, ACount);
      Changed;
    finally
      EndUpdate;
    end;
  end;
end;

function TACLStringList.Remove(const S: UnicodeString): Integer;
begin
  Result := IndexOf(S);
  if Result >= 0 then
    Delete(Result);
end;

function TACLStringList.Pack: Integer;
var
  I: Integer;
begin
  BeginUpdate;
  try
    Result := 0;
    for I := Count - 1 downto 0 do
    begin
      if Strings[I] = '' then
      begin
        Inc(Result);
        Delete(I);
      end;
    end;
  finally
    EndUpdate;
  end;
end;

function TACLStringList.Remove(const AObject: NativeUInt): Integer;
begin
  Result := Remove(TObject(AObject));
end;

function TACLStringList.Remove(const AObject: TObject): Integer;
begin
  Result := IndexOfObject(AObject);
  if Result >= 0 then
    Delete(Result);
end;

function TACLStringList.RemoveDuplicates: Integer;
var
  I: Integer;
begin
  BeginUpdate;
  try
    Result := 0;
    for I := Count - 1 downto 0 do
    begin
      if IndexOf(Strings[I]) < I then
      begin
        Inc(Result);
        Delete(I);
      end;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLStringList.Sort;
begin
  Sort(
    function (const Item1, Item2: TACLStringListItem): Integer
    begin
      Result := acCompareStrings(Item1.FString, Item2.FString, False);
    end, True);
end;

procedure TACLStringList.Sort(ACompareProc: TACLStringListCompareProc; UseThreading: Boolean);
begin
  if Count > 0 then
  begin
    BeginUpdate;
    try
      TACLMultithreadedStringListSorter.Sort(Self, ACompareProc, UseThreading);
      Changed;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TACLStringList.SortLogical;
begin
  Sort(
    function (const Item1, Item2: TACLStringListItem): Integer
    begin
      Result := acLogicalCompare(Item1.FString, Item2.FString);
    end, Count > 1000);
end;

procedure TACLStringList.TrimLines;
var
  I: Integer;
begin
  BeginUpdate;
  try
    for I := 0 to Count - 1 do
      Strings[I] := acTrim(Strings[I]);
  finally
    EndUpdate;
  end;
end;

function TACLStringList.First: UnicodeString;
begin
  Result := Strings[0];
end;

function TACLStringList.Last: UnicodeString;
begin
  Result := Strings[Count - 1];
end;

procedure TACLStringList.AssignTo(Dest: TPersistent);
var
  AStrings: TStrings;
  I: Integer;
begin
  if Dest is TStrings then
  begin
    AStrings := TStrings(Dest);
    AStrings.BeginUpdate;
    try
      AStrings.Clear;
      AStrings.Capacity := Count;
      for I := 0 to Count - 1 do
      begin
        with FList[I] do
          AStrings.AddObject(FString, FObject);
      end;
    finally
      AStrings.EndUpdate;
    end;
  end
  else
    inherited AssignTo(Dest);
end;

procedure TACLStringList.Changed;
begin
  // do nothing
end;

procedure TACLStringList.SetString(AIndex: Integer; const AValue: UnicodeString);
begin
  if IsValid(AIndex) then
  begin
    FList^[AIndex].FString := AValue;
    Changed;
  end;
end;

procedure TACLStringList.SetText(const S: UnicodeString);
begin
  ParseBuffer(PWideChar(S), Length(S));
end;

procedure TACLStringList.DoAdd(const S: UnicodeString);
begin
  Add(S);
end;

function TACLStringList.GetCount: Integer;
begin
  Result := FCount;
end;

function TACLStringList.GetInterface(AIndex: Integer): IUnknown;
begin
  if IsValid(AIndex) then
    Result := FList^[AIndex].FInterface
  else
    Result := nil;
end;

function TACLStringList.GetName(AIndex: Integer): UnicodeString;
begin
  Result := GetString(AIndex);
  Result := Copy(Result, 1, acPos(Delimiter, Result) - 1);
end;

function TACLStringList.GetObject(AIndex: Integer): TObject;
begin
  if IsValid(AIndex) then
    Result := FList^[AIndex].FObject
  else
    Result := nil;
end;

function TACLStringList.GetString(AIndex: Integer): UnicodeString;
begin
  if IsValid(AIndex) then
    Result := FList^[AIndex].FString
  else
    Result := '';
end;

function TACLStringList.GetValue(AIndex: Integer): UnicodeString;
begin
  Result := GetString(AIndex);
  Result := Copy(Result, acPos(Delimiter, Result) + 1, MAXINT);
end;

function TACLStringList.GetValueFromName(const S: UnicodeString): UnicodeString;
var
  AIndex: Integer;
begin
  AIndex := IndexOfName(S);
  if AIndex < 0 then
    Result := ''
  else
    Result := ValueFromIndex[AIndex];
end;

function TACLStringList.GetText: UnicodeString;
begin
  Result := GetDelimitedText(sLineBreak);
end;

procedure TACLStringList.SetCapacity(Value: Integer);
begin
  Value := Max(Value, Count);
  if Value <> FCapacity then
  begin
    ReallocMem(FList, Value * SizeOf(TACLStringListItem));
    FCapacity := Value;
  end;
end;

procedure TACLStringList.SetInterface(AIndex: Integer; const AValue: IInterface);
begin
  if IsValid(AIndex) then
  begin
    FList^[AIndex].FInterface := AValue;
    Changed;
  end;
end;

procedure TACLStringList.SetName(Index: Integer; const Value: UnicodeString);
begin
  Strings[Index] := Value + Delimiter + ValueFromIndex[Index];
end;

procedure TACLStringList.SetObject(AIndex: Integer; const AValue: TObject);
begin
  if IsValid(AIndex) then
  begin
    FList^[AIndex].FObject := AValue;
    Changed;
  end;
end;

procedure TACLStringList.SetValue(Index: Integer; const Value: UnicodeString);
begin
  Strings[Index] := Names[Index] + Delimiter + Value;
end;

procedure TACLStringList.SetValueFromName(const AName, AValue: UnicodeString);
var
  AIndex: Integer;
begin
  AIndex := IndexOfName(AName);
  if AIndex < 0 then
    Add(AName + Delimiter + AValue)
  else
    Strings[AIndex] := AName + Delimiter + AValue;
end;

procedure TACLStringList.Grow;
const
  Deltas: array[Boolean] of Integer = (4, 16);
var
  ADelta: Integer;
begin
  if Capacity > 64 then
    ADelta := Capacity div 4
  else
    ADelta := Deltas[Capacity > 8];

  SetCapacity(Capacity + ADelta);
end;

procedure TACLStringList.ParseBuffer(ABuffer: PWideChar; ACount: Integer);
var
  P, AFinish, AStart: PWideChar;
  S: UnicodeString;
begin
  BeginUpdate;
  try
    Clear;
    P := ABuffer;
    AStart := P;
    AFinish := ABuffer + ACount;
    while (NativeUInt(P) + SizeOf(WideChar) <= NativeUInt(AFinish)) do
    begin
      if (P^ <> #10) and (P^ <> #13) and (P^ <> acLineSeparator) then
        Inc(P)
      else
      begin
        System.SetString(S, AStart, P - AStart);
        Add(S);
        if P^ = acLineSeparator then Inc(P);
        if P^ = #13 then Inc(P);
        if P^ = #10 then Inc(P);
        AStart := P;
      end;
    end;
    if NativeUInt(P - AStart) > 0 then
    begin
      System.SetString(S, AStart, P - AStart);
      Add(S);
    end;
  finally
    EndUpdate;
  end;
end;

{ TACLSortedStrings }

procedure TACLSortedStrings.AfterConstruction;
begin
  inherited AfterConstruction;
  IgnoryCase := False;
end;

function TACLSortedStrings.Find(const S: UnicodeString; out AIndex: Integer): Boolean;
begin
  Result := Find(PWideChar(S), Length(S), AIndex);
end;

function TACLSortedStrings.Find(const P: PWideChar; ALength: Integer; out AIndex: Integer): Boolean;
var
  L, H, I, C: Integer;
  S: UnicodeString;
begin
  Result := False;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    S := List^[I].FString;
    C := acCompareStrings(PWideChar(S), P, Length(S), ALength, IgnoryCase);
    if C < 0 then
      L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result := True;
        L := I;
        Break;
      end;
    end;
  end;
  AIndex := L;
end;

function TACLSortedStrings.IndexOf(const AItem: UnicodeString): Integer;
begin
  if not Find(AItem, Result) then
    Result := -1;
end;

procedure TACLSortedStrings.Insert(Index: Integer; const S: UnicodeString;
  const AObject: TObject = nil; AInterface: IUnknown = nil);
begin
  if not Find(S, Index) then
    inherited Insert(Index, S, AObject, AInterface);
end;

procedure TACLSortedStrings.SetString(AIndex: Integer; const AValue: UnicodeString);
begin
  inherited SetString(AIndex, AValue);
  Sort;
end;

end.
