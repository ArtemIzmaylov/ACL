////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   StringList
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Classes.StringList;

{$I ACL.Config.inc}

interface

uses
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
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
    FString: string;
    procedure Assign(const Item: TACLStringListItem); inline;
    procedure Exchange(var Item: TACLStringListItem); inline;
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
    FDelimiter: Char;
    FIgnoryCase: Boolean;
    FList: PACLStringListItemList;

    function GetCount: Integer;
    function GetInterface(AIndex: Integer): IUnknown;
    function GetName(AIndex: Integer): string;
    function GetObject(AIndex: Integer): TObject;
    function GetString(AIndex: Integer): string;
    function GetText: string;
    function GetValue(AIndex: Integer): string;
    function GetValueFromName(const S: string): string;
    procedure SetCapacity(Value: Integer);
    procedure SetInterface(AIndex: Integer; const AValue: IUnknown);
    procedure SetName(Index: Integer; const Value: string);
    procedure SetObject(AIndex: Integer; const AValue: TObject);
    procedure SetValue(Index: Integer; const Value: string);
    procedure SetValueFromName(const AName, AValue: string);
    // Interla;
    procedure Grow;
    procedure ParseBuffer(ABuffer: PChar; ACount: Integer);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure Changed; virtual;
    procedure SetString(AIndex: Integer; const AValue: string); virtual;
    procedure SetText(const S: string); virtual;
    // IStringReceiver
    procedure IStringReceiver.Add = DoAdd;
    procedure DoAdd(const S: string);
    //# Properties
    property List: PACLStringListItemList read FList;
  public
    constructor Create; overload;
    constructor Create(const AText: string; ASplitText: Boolean = False); overload;
    destructor Destroy; override;
    procedure EnsureCapacity(ACount: Integer);
    function Clone: TACLStringList;
    function IsValid(AIndex: Integer): Boolean; inline;
    procedure Exchange(Index1, Index2: Integer);
    procedure Shuffle;
    procedure TrimLines;

    function GetDelimitedText(const ADelimiter: string; AAddTrailingDelimiter: Boolean = True): string;
    procedure SetDelimitedText(const AText: string; ADelimiter: Char);

    // Lock / Unlock
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;

    // I/O
    function LoadFromFile(const AFileName: string; AEncoding: TEncoding = nil): Boolean;
    procedure LoadFromStream(AStream: TStream; AEncoding: TEncoding = nil); virtual;
    procedure LoadFromResource(AInstance: HModule; const AName: string; AType: PChar);
    function SaveToFile(const AFileName: string; AEncoding: TEncoding = nil): Boolean;
    procedure SaveToStream(AStream: TStream; AEncoding: TEncoding = nil); virtual;

    // Inserting
    function Add(const S: string; AObject: NativeInt): Integer; overload;
    function Add(const S: string; AObject: TObject = nil; AInterface: IUnknown = nil): Integer; overload;
    function AddPair(const Name, Value: string;
      AObject: TObject = nil; AInterface: IUnknown = nil): Integer;
    procedure AddEx(const S: string);
    procedure Append(const ASource: TACLStringList); overload;
    procedure Append(const ASource: string); overload;
    procedure Assign(Source: TPersistent); override;
    procedure Insert(Index: Integer; const S: string;
      AObject: TObject = nil; AInterface: IUnknown = nil); virtual;

    // Search
    function Contains(const S: string): Boolean;
    function IndexOf(const S: string): Integer; virtual;
    function IndexOfName(const AName: string): Integer;
    function IndexOfObject(AObject: TObject): Integer;

    // Removing
    procedure Clear; virtual;
    function Delete(AIndex: Integer): Boolean; inline;
    function DeleteAll: Boolean;
    function DeleteRange(AIndex, ACount: Integer): Boolean;
    function Pack: Integer;
    function Remove(const AObject: NativeUInt): Integer; overload;
    function Remove(const AObject: TObject): Integer; overload;
    function Remove(const S: string): Integer; overload;
    function RemoveDuplicates: Integer;

    // Sorting
    procedure Sort; overload;
    procedure Sort(ACompareProc: TACLStringListCompareProc; UseThreading: Boolean); overload;
    procedure SortLogical;
    //
    function First: string; inline;
    function Last: string; inline;

    // Properties
    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read GetCount;
    property Data: Pointer read FData write FData;
    property Delimiter: Char read FDelimiter write FDelimiter;
    property IgnoryCase: Boolean read FIgnoryCase write FIgnoryCase;
    property Text: string read GetText write SetText;

    // Row data
    property Interfaces[AIndex: Integer]: IUnknown read GetInterface write SetInterface;
    property Names[Index: Integer]: string read GetName write SetName;
    property Objects[Index: Integer]: TObject read GetObject write SetObject;
    property Strings[Index: Integer]: string read GetString write SetString; default;
    property ValueFromIndex[Index: Integer]: string read GetValue write SetValue;
    property ValueFromName[const Name: string]: string read GetValueFromName write SetValueFromName;
  end;

  { TACLSortedStrings }

  TACLSortedStrings = class(TACLStringList)
  protected
    procedure SetString(AIndex: Integer; const AValue: string); override;
  public
    procedure AfterConstruction; override;
    function Find(const P: PChar; ALength: Integer; out AIndex: Integer): Boolean; overload;
    function Find(const S: string; out AIndex: Integer): Boolean; overload;
    function IndexOf(const AItem: string): Integer; override;
    procedure Insert(Index: Integer; const S: string;
      AObject: TObject = nil; AInterface: IUnknown = nil); override;
  end;

implementation

uses
  ACL.FastCode,
  ACL.Threading.Sorting,
  ACL.Utils.FileSystem,
  ACL.Utils.Stream;

{ TACLStringListItem }

procedure TACLStringListItem.Assign(const Item: TACLStringListItem);
begin
  Pointer(FInterface) := Pointer(Item.FInterface);
  Pointer(FObject) := Pointer(Item.FObject);
  Pointer(FString) := Pointer(Item.FString);
end;

procedure TACLStringListItem.Exchange(var Item: TACLStringListItem);
var
  LSwap: Pointer;
begin
  LSwap := Pointer(FString);
  Pointer(FString) := Pointer(Item.FString);
  Pointer(Item.FString) := LSwap;

  LSwap := Pointer(FObject);
  Pointer(FObject) := Pointer(Item.FObject);
  Pointer(Item.FObject) := LSwap;

  LSwap := Pointer(FInterface);
  Pointer(FInterface) := Pointer(Item.FInterface);
  Pointer(Item.FInterface) := LSwap;
end;

{ TACLStringList }

constructor TACLStringList.Create;
begin
  inherited Create;
  FIgnoryCase := True;
  FDelimiter := '=';
end;

constructor TACLStringList.Create(const AText: string; ASplitText: Boolean);
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

function TACLStringList.Contains(const S: string): Boolean;
begin
  Result := IndexOf(S) >= 0;
end;

function TACLStringList.GetDelimitedText(
  const ADelimiter: string; AAddTrailingDelimiter: Boolean = True): string;
var
  I, D, L, ASize: Integer;
  P: PChar;
  S: string;
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
      FastMove(Pointer(S)^, P^, L * SizeOf(Char));
      Inc(P, L);
    end;
    if (D <> 0) and (AAddTrailingDelimiter or (I + 1 < Count)) then
    begin
      FastMove(Pointer(ADelimiter)^, P^, D * SizeOf(Char));
      Inc(P, D);
    end;
  end;
end;

procedure TACLStringList.SetDelimitedText(const AText: string; ADelimiter: Char);
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
        procedure (ACursorStart, ACursorNext: PChar; var {%H-}ACanContinue: Boolean)
        begin
          Add(acMakeString(ACursorStart, ACursorNext));
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

function TACLStringList.LoadFromFile(const AFileName: string; AEncoding: TEncoding = nil): Boolean;
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
begin
  Text := acLoadString(AStream, AEncoding);
end;

procedure TACLStringList.LoadFromResource(AInstance: HModule; const AName: string; AType: PChar);
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

function TACLStringList.SaveToFile(const AFileName: string; AEncoding: TEncoding = nil): Boolean;
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

procedure TACLStringList.SaveToStream(AStream: TStream; AEncoding: TEncoding = nil);
begin
  AStream.WriteBOM(AEncoding);
  AStream.WriteString(Text, AEncoding);
end;

function TACLStringList.Add(const S: string; AObject: NativeInt): Integer;
begin
  Result := Add(S, TObject(AObject));
end;

function TACLStringList.Add(const S: string; AObject: TObject; AInterface: IUnknown): Integer;
begin
  Result := Count;
  Insert(Count, S, AObject, AInterface);
end;

function TACLStringList.AddPair(const Name, Value: string;
  AObject: TObject = nil; AInterface: IUnknown = nil): Integer;
begin
  Result := Add(Name + Delimiter + Value, AObject, AInterface);
end;

procedure TACLStringList.AddEx(const S: string);
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

procedure TACLStringList.Append(const ASource: string);
begin
  BeginUpdate;
  try
    ParseBuffer(PChar(ASource), Length(ASource))
  finally
    EndUpdate;
  end;
end;

procedure TACLStringList.Assign(Source: TPersistent);
var
  I: Integer;
begin
  if Source is TACLStringList then
  begin
    if Self = Source then Exit;
    BeginUpdate;
    try
      Clear;
      Append(TACLStringList(Source));
    finally
      EndUpdate;
    end;
  end
  else
    if Source is TStrings then
    begin
      BeginUpdate;
      try
        Clear;
        EnsureCapacity(TStrings(Source).Count);
        for I := 0 to TStrings(Source).Count - 1 do
          Add(TStrings(Source).Strings[I], TStrings(Source).Objects[I]);
      finally
        EndUpdate;
      end;
    end;
end;

procedure TACLStringList.Insert(Index: Integer; const S: string;
  AObject: TObject = nil; AInterface: IUnknown = nil);
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

function TACLStringList.IndexOf(const S: string): Integer;
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

function TACLStringList.IndexOfName(const AName: string): Integer;
var
  T, S: string;
  I, L: Integer;
begin
  T := AName + Delimiter;
  L := Length(T);
  for I := Count - 1 downto 0 do
  begin
    S := List[I].FString;
    if (Length(S) >= L) and (acCompareStrings(PChar(T), PChar(S), L, L, IgnoryCase) = 0) then
      Exit(I);
  end;
  Result := -1;
end;

function TACLStringList.IndexOfObject(AObject: TObject): Integer;
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

function TACLStringList.Remove(const S: string): Integer;
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

function TACLStringList.First: string;
begin
  Result := Strings[0];
end;

function TACLStringList.Last: string;
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

procedure TACLStringList.SetString(AIndex: Integer; const AValue: string);
begin
  if IsValid(AIndex) then
  begin
    FList^[AIndex].FString := AValue;
    Changed;
  end;
end;

procedure TACLStringList.SetText(const S: string);
begin
  BeginUpdate;
  try
    Clear;
    ParseBuffer(PChar(S), Length(S));
  finally
    EndUpdate;
  end;
end;

procedure TACLStringList.DoAdd(const S: string);
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

function TACLStringList.GetName(AIndex: Integer): string;
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

function TACLStringList.GetString(AIndex: Integer): string;
begin
  if IsValid(AIndex) then
    Result := FList^[AIndex].FString
  else
    Result := '';
end;

function TACLStringList.GetValue(AIndex: Integer): string;
begin
  Result := GetString(AIndex);
  Result := Copy(Result, acPos(Delimiter, Result) + 1, MAXINT);
end;

function TACLStringList.GetValueFromName(const S: string): string;
var
  AIndex: Integer;
begin
  AIndex := IndexOfName(S);
  if AIndex < 0 then
    Result := ''
  else
    Result := ValueFromIndex[AIndex];
end;

function TACLStringList.GetText: string;
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

procedure TACLStringList.SetName(Index: Integer; const Value: string);
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

procedure TACLStringList.SetValue(Index: Integer; const Value: string);
begin
  Strings[Index] := Names[Index] + Delimiter + Value;
end;

procedure TACLStringList.SetValueFromName(const AName, AValue: string);
var
  AIndex: Integer;
begin
  AIndex := IndexOfName(AName);
  if AIndex < 0 then
    Add(AName + Delimiter + AValue)
  else
    Strings[AIndex] := AName + Delimiter + AValue;
end;

procedure TACLStringList.Shuffle;
var
  L: TACLStringList;
  I, J: Integer;
begin
  L := TACLStringList.Create;
  try
    L.Assign(Self);
    for I := 0 to Count - 1 do
    begin
      J := Random(L.Count);
      List[I].Assign(L.List[J]);
      L.Delete(J);
    end;
  finally
    L.Free;
  end;
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

procedure TACLStringList.ParseBuffer(ABuffer: PChar; ACount: Integer);
{$ifdef fpc}{$push}{$WARN 4055 off}{$endif}
var
  P, AFinish, AStart: PChar;
begin
  P := ABuffer;
  AStart := P;
  AFinish := ABuffer + ACount;
  while NativeUInt(P) + SizeOf(Char) <= NativeUInt(AFinish) do
  begin
    if (P^ <> #10) and (P^ <> #13){$IFDEF UNICODE}and (P^ <> acLineSeparator){$ENDIF} then
      Inc(P)
    else
    begin
      Add(acMakeString(AStart, P - AStart));
    {$IFDEF UNICODE}
      if P^ = acLineSeparator then Inc(P);
    {$ENDIF}
      if P^ = #13 then Inc(P);
      if P^ = #10 then Inc(P);
      AStart := P;
    end;
  end;
  if NativeUInt(P - AStart) > 0 then
    Add(acMakeString(AStart, P - AStart));
{$ifdef fpc}{$pop}{$endif}
end;

{ TACLSortedStrings }

procedure TACLSortedStrings.AfterConstruction;
begin
  inherited AfterConstruction;
  IgnoryCase := False;
end;

function TACLSortedStrings.Find(const S: string; out AIndex: Integer): Boolean;
begin
  Result := Find(PChar(S), Length(S), AIndex);
end;

function TACLSortedStrings.Find(const P: PChar; ALength: Integer; out AIndex: Integer): Boolean;
var
  L, H, I, C: Integer;
  S: String;
begin
  Result := False;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    S := List^[I].FString;
    C := acCompareStrings(PChar(S), P, Length(S), ALength, IgnoryCase);
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

function TACLSortedStrings.IndexOf(const AItem: string): Integer;
begin
  if not Find(AItem, Result) then
    Result := -1;
end;

procedure TACLSortedStrings.Insert(Index: Integer; const S: string;
  AObject: TObject = nil; AInterface: IUnknown = nil);
begin
  if not Find(S, Index) then
    inherited Insert(Index, S, AObject, AInterface);
end;

procedure TACLSortedStrings.SetString(AIndex: Integer; const AValue: string);
begin
  inherited SetString(AIndex, AValue);
  Sort;
end;

end.
