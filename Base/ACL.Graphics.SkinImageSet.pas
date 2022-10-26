{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*       Sharable SkinImageSet  Class        *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.SkinImageSet;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.GDIPAPI,
  // System
  System.UITypes,
  System.Types,
  System.Classes,
  System.Generics.Collections,
  // VCL
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex.Gdip,
  ACL.Graphics.SkinImage,
  ACL.Utils.DPIAware,
  ACL.Utils.Common,
  ACL.Utils.Stream;

type
  TACLSkinImageColorationMode = (cmTint, cmHue, cmColor);

  { TACLSkinImageSetItem }

  TACLSkinImageSetItem = class(TACLSkinImage)
  strict private const
    CHUNK_DPI = $49504458;
  strict private
    FDPI: Integer;
    FReferenceCount: Integer;
    FReleasing: Boolean;
  protected
    procedure DoAssign(AObject: TObject); override;
    procedure ReadChunk(AStream: TStream; AChunkID: Integer; AChunkSize: Integer); override;
    procedure WriteChunks(AStream: TStream; var AChunkCount: Integer); override;
    //
    property ReferenceCount: Integer read FReferenceCount;
  public
    constructor Create(DPI: Integer = acDefaultDPI); reintroduce;
    procedure BeforeDestruction; override;
    procedure CopyFrom(AObject: TObject);
    function Clone: TACLSkinImageSetItem;
    function Equals(Obj: TObject): Boolean; override;
    procedure Release; virtual;
    function ToString: string; override;
    //
    procedure ReferenceAdd;
    procedure ReferenceRemove;
    //
    property DPI: Integer read FDPI;
  end;

  { TACLSkinImageSet }

  TACLSkinImageSet = class(TACLLockablePersistent)
  strict private const
    SYNC_WORD = $5458454E;
  strict private
    FItems: TACLList<TACLSkinImageSetItem>;
    FTintedItems: TObject;

    FOnChange: TNotifyEvent;

    procedure CheckDPI(DPI: Integer);
    function GetCount: Integer; inline;
    function GetItem(Index: Integer): TACLSkinImageSetItem; inline;
    procedure SetItem(Index: Integer; AValue: TACLSkinImageSetItem); inline;
    //
    procedure ImageChangeHandler(Sender: TObject);
    procedure ItemsChangeHandler(Sender: TObject; const Item: TACLSkinImageSetItem; Action: TCollectionNotification);
    procedure ReleaseItems;
    procedure ReleaseTintedItems;
  protected
    procedure DoAdd(AImage: TACLSkinImageSetItem);
    procedure DoAssign(Source: TPersistent); override;
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
  public
    constructor Create; overload;
    constructor Create(AChangeEvent: TNotifyEvent); overload;
    destructor Destroy; override;

    procedure Add(AImage: TACLSkinImageSetItem); overload;
    procedure Add(AImage: TBitmap; DPI: Integer); overload;
    procedure Add(AStream: TStream; DPI: Integer); overload;
    function Add(DPI: Integer): TACLSkinImageSetItem; overload;
    procedure Clear;
    function Clone: TACLSkinImageSet;
    procedure Delete(Index: Integer);
    procedure Dormant;
    function Equals(Obj: TObject): Boolean; override;
    function Find(DPI: Integer): TACLSkinImageSetItem;
    function Get(DPI: Integer): TACLSkinImageSetItem; overload;
    function Get(DPI: Integer; const AColor: TAlphaColor; AMode: TACLSkinImageColorationMode): TACLSkinImageSetItem; overload;
    function Get(DPI: Integer; const AColorScheme: TACLColorSchema): TACLSkinImageSetItem; overload;
    function GetHashCode: Integer; override;
    function IsEmpty: Boolean;
    procedure MakeUnique;

    // I/O
    procedure ImportFromImage(const AImage: TBitmap; DPI: Integer = acDefaultDPI);
    procedure ImportFromImageFile(const AFileName: string; DPI: Integer = acDefaultDPI);
    procedure ImportFromImageStream(const AStream: TStream; DPI: Integer = acDefaultDPI);
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromResource(Inst: HINST; const AName: UnicodeString; AType: PChar);
    procedure LoadFromStream(const AStream: TStream);
    procedure SaveToFile(const AFileName: string);
    procedure SaveToStream(const AStream: TStream);

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TACLSkinImageSetItem read GetItem write SetItem; default;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

var
  acSkinImageSetDormantUnusedImages: Boolean = True;

implementation

uses
  System.SysUtils,
  System.Math,
  System.Generics.Defaults;

const
  sErrorCannotDeleteLastImage = 'You cannot delete the last image';
  sErrorResolutionAlreadyExists = 'Image for %d dpi is already exists.';
  sErrorResolutionIsInvalid = 'The %d dpi is not valid.';

type

  { TACLSkinImageSetTintedItem }

  TACLSkinImageSetTintedItem = class(TACLSkinImageSetItem)
  strict private
    FCollection: TList;
    FColor: TAlphaColor;
    FMode: TACLSkinImageColorationMode;
  public
    constructor Create(ACollection: TList; ASource: TACLSkinImageSetItem; AColor: TAlphaColor; AMode: TACLSkinImageColorationMode);
    destructor Destroy; override;
    procedure Dormant; override;
    procedure Release; override;
    //
    property Color: TAlphaColor read FColor;
    property Mode: TACLSkinImageColorationMode read FMode;
  end;

  { TACLSkinImageSetTintedItemList }

  TACLSkinImageSetTintedItemList = class
  strict private
    FList: TList;
    FOwner: TACLSkinImageSet;
  public
    constructor Create(AOwner: TACLSkinImageSet);
    destructor Destroy; override;
    function Find(DPI: Integer; AColor: TAlphaColor; AMode: TACLSkinImageColorationMode): TACLSkinImageSetTintedItem;
    function GetOrCreate(DPI: Integer; const AColor: TAlphaColor; AMode: TACLSkinImageColorationMode): TACLSkinImageSetTintedItem; overload;
    function GetOrCreate(DPI: Integer; const AColorScheme: TACLColorSchema): TACLSkinImageSetItem; overload;
    procedure Release;
  end;

{ TACLSkinImageSetItem }

constructor TACLSkinImageSetItem.Create(DPI: Integer = acDefaultDPI);
begin
  inherited Create;
  FDPI := DPI;
end;

procedure TACLSkinImageSetItem.BeforeDestruction;
begin
  inherited;
  FReleasing := True;
end;

procedure TACLSkinImageSetItem.CopyFrom(AObject: TObject);
begin
  BeginUpdate;
  try
    inherited DoAssign(AObject);
  finally
    EndUpdate;
  end;
end;

function TACLSkinImageSetItem.Clone: TACLSkinImageSetItem;
begin
  Result := TACLSkinImageSetItem.Create(DPI);
  Result.Assign(Self);
end;

function TACLSkinImageSetItem.Equals(Obj: TObject): Boolean;
begin
  Result := inherited Equals(Obj) and (DPI = TACLSkinImageSetItem(Obj).DPI);
end;

procedure TACLSkinImageSetItem.Release;
begin
  FReleasing := True;
end;

function TACLSkinImageSetItem.ToString: string;
begin
  Result := Format('%d%% / %d dpi - %dx%d', [MulDiv(100, DPI, acDefaultDPI), DPI, Width, Height]);
end;

procedure TACLSkinImageSetItem.ReferenceAdd;
begin
  Inc(FReferenceCount);
end;

procedure TACLSkinImageSetItem.ReferenceRemove;
begin
  Dec(FReferenceCount);
  if (FReferenceCount = 1) and not FReleasing and acSkinImageSetDormantUnusedImages then
    Dormant;
  if FReferenceCount = 0 then
    Free;
end;

procedure TACLSkinImageSetItem.DoAssign(AObject: TObject);
begin
  inherited DoAssign(AObject);
  if AObject is TACLSkinImageSetItem then
    FDPI := TACLSkinImageSetItem(AObject).DPI;
end;

procedure TACLSkinImageSetItem.ReadChunk(AStream: TStream; AChunkID, AChunkSize: Integer);
begin
  if AChunkID = CHUNK_DPI then
    FDPI := AStream.ReadWord
  else
    inherited ReadChunk(AStream, AChunkID, AChunkSize);
end;

procedure TACLSkinImageSetItem.WriteChunks(AStream: TStream; var AChunkCount: Integer);
var
  APosition: Int64;
begin
  inherited WriteChunks(AStream, AChunkCount);

  // DPI Chunk
  AStream.BeginWriteChunk(CHUNK_DPI, APosition);
  AStream.WriteWord(DPI);
  AStream.EndWriteChunk(APosition);
  Inc(AChunkCount);
end;

{ TACLSkinImageSet }

constructor TACLSkinImageSet.Create;
begin
  inherited Create;
  FItems := TACLList<TACLSkinImageSetItem>.Create;
  FItems.OnNotify := ItemsChangeHandler;
  FTintedItems := TACLSkinImageSetTintedItemList.Create(Self);
  Clear;
end;

constructor TACLSkinImageSet.Create(AChangeEvent: TNotifyEvent);
begin
  Create;
  OnChange := AChangeEvent;
end;

destructor TACLSkinImageSet.Destroy;
begin
  // do not change the order
  OnChange := nil;
  ReleaseItems;
  FreeAndNil(FTintedItems);
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TACLSkinImageSet.Add(AImage: TACLSkinImageSetItem);
var
  ATempImage: TACLSkinImageSetItem;
begin
  BeginUpdate;
  try
    ATempImage := Get(AImage.DPI);
    if (ATempImage <> nil) and (ATempImage.DPI = AImage.DPI) then
      FItems.Remove(ATempImage);
    DoAdd(AImage);
  finally
    EndUpdate;
  end;
end;

procedure TACLSkinImageSet.Add(AImage: TBitmap; DPI: Integer);
var
  ASkinImage: TACLSkinImageSetItem;
begin
  CheckDPI(DPI);
  ASkinImage := TACLSkinImageSetItem.Create(DPI);
  ASkinImage.LoadFromBitmap(AImage);
  Add(ASkinImage);
end;

procedure TACLSkinImageSet.Add(AStream: TStream; DPI: Integer);
var
  ASkinImage: TACLSkinImageSetItem;
begin
  CheckDPI(DPI);
  ASkinImage := TACLSkinImageSetItem.Create(DPI);
  ASkinImage.LoadFromStream(AStream);
  Add(ASkinImage);
end;

function TACLSkinImageSet.Add(DPI: Integer): TACLSkinImageSetItem;
begin
  CheckDPI(DPI);

  Result := Find(DPI);
  if Result <> nil then
    raise Exception.CreateFmt(sErrorResolutionAlreadyExists, [DPI]);

  Result := TACLSkinImageSetItem.Create(DPI);
  DoAdd(Result);
end;

procedure TACLSkinImageSet.Clear;
var
  I: Integer;
begin
  BeginUpdate;
  try
    ReleaseTintedItems;

    //#AI: for backward compatibility - keep default settings of SkinImage
    for I := Count - 1 downto 0 do
    begin
      if Items[I].DPI <> acDefaultDPI then
        FItems.Delete(I);
    end;

    if Count > 0 then
      Items[0].Clear
    else
      Add(acDefaultDPI);

//# Original code:
//#    FImages.Clear;
//#    Image := ImageAdd(acDefaultDPI);
  finally
    EndUpdate;
  end;
end;

function TACLSkinImageSet.Clone: TACLSkinImageSet;
var
  I: Integer;
begin
  Result := TACLSkinImageSet.Create;
  for I := 0 to Count - 1 do
    Result.Add(Items[I]);
end;

procedure TACLSkinImageSet.Delete(Index: Integer);
begin
  if Count <= 1 then
    raise EInvalidOperation.Create(sErrorCannotDeleteLastImage);
  FItems.Delete(Index);
end;

procedure TACLSkinImageSet.Dormant;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].Dormant;
end;

function TACLSkinImageSet.Equals(Obj: TObject): Boolean;
var
  I: Integer;
begin
  Result := (Obj <> nil) and (ClassType = Obj.ClassType) and (Count = TACLSkinImageSet(Obj).Count);
  if Result then
  begin
    for I := 0 to Count - 1 do
      Result := Result and Items[I].Equals(TACLSkinImageSet(Obj).Items[I]);
  end;
end;

function TACLSkinImageSet.Find(DPI: Integer): TACLSkinImageSetItem;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    Result := FItems.List[I];
    if Result.DPI = DPI then
      Exit;
  end;
  Result := nil;
end;

function TACLSkinImageSet.GetHashCode: Integer;
begin
  Result := Count;
end;

function TACLSkinImageSet.IsEmpty: Boolean;
begin
  Result := (Count = 1) and (Items[0].DPI = acDefaultDPI) and Items[0].Empty;
end;

function TACLSkinImageSet.Get(DPI: Integer): TACLSkinImageSetItem;
var
  AImage: TACLSkinImageSetItem;
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
  begin
    AImage := FItems.List[I];
    if (Result = nil) or (AImage.DPI <= DPI) and (Abs(AImage.DPI - DPI) < Abs(Result.DPI - DPI)) then
      Result := AImage;
  end;
end;

function TACLSkinImageSet.Get(DPI: Integer; const AColor: TAlphaColor; AMode: TACLSkinImageColorationMode): TACLSkinImageSetItem;
begin
  if AColor.IsValid then
    Result := TACLSkinImageSetTintedItemList(FTintedItems).GetOrCreate(DPI, AColor, AMode)
  else
    Result := Get(DPI);
end;

function TACLSkinImageSet.Get(DPI: Integer; const AColorScheme: TACLColorSchema): TACLSkinImageSetItem;
begin
  if AColorScheme.IsAssigned then
    Result := TACLSkinImageSetTintedItemList(FTintedItems).GetOrCreate(DPI, AColorScheme)
  else
    Result := Get(DPI);
end;

procedure TACLSkinImageSet.MakeUnique;
var
  AIndex: Integer;
begin
  BeginUpdate;
  try
    for AIndex := 0 to Count - 1 do
    begin
      if Items[AIndex].ReferenceCount > 1 then
        Items[AIndex] := Items[AIndex].Clone;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLSkinImageSet.ReleaseItems;
begin
  FItems.Clear;
  ReleaseTintedItems;
end;

procedure TACLSkinImageSet.ReleaseTintedItems;
begin
  TACLSkinImageSetTintedItemList(FTintedItems).Release;
end;

procedure TACLSkinImageSet.ImportFromImage(const AImage: TBitmap; DPI: Integer = acDefaultDPI);
begin
  BeginUpdate;
  try
    ReleaseItems;
    Add(AImage, DPI);
  finally
    EndUpdate;
  end;
end;

procedure TACLSkinImageSet.ImportFromImageFile(const AFileName: string; DPI: Integer = acDefaultDPI);
var
  AStream: TStream;
begin
  AStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    ImportFromImageStream(AStream);
  finally
    AStream.Free;
  end;
end;

procedure TACLSkinImageSet.ImportFromImageStream(const AStream: TStream; DPI: Integer = acDefaultDPI);
begin
  BeginUpdate;
  try
    ReleaseItems;
    Add(AStream, DPI);
  finally
    EndUpdate;
  end;
end;

procedure TACLSkinImageSet.LoadFromFile(const AFileName: string);
var
  AStream: TStream;
begin
  AStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(AStream);
  finally
    AStream.Free;
  end;
end;

procedure TACLSkinImageSet.LoadFromResource(Inst: HINST; const AName: UnicodeString; AType: PChar);
var
  AStream: TStream;
begin
  AStream := TResourceStream.Create(Inst, AName, AType);
  try
    LoadFromStream(AStream);
  finally
    AStream.Free;
  end;
end;

procedure TACLSkinImageSet.LoadFromStream(const AStream: TStream);
var
  ASyncWord: Integer;
  ASyncWordSize: Integer;
begin
  BeginUpdate;
  try
    Clear;
    repeat
      Items[Count - 1].LoadFromStream(AStream);

      ASyncWordSize := AStream.Read(ASyncWord, SizeOf(ASyncWord));
      if (ASyncWordSize <> SizeOf(ASyncWord)) or (ASyncWord <> SYNC_WORD) then
      begin
        AStream.Seek(-ASyncWordSize, soCurrent);
        Break;
      end;

      FItems.Add(TACLSkinImageSetItem.Create);
    until False;
    Changed;
  finally
    EndUpdate;
  end;
end;

procedure TACLSkinImageSet.SaveToFile(const AFileName: string);
var
  AStream: TStream;
begin
  AStream := TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(AStream);
  finally
    AStream.Free;
  end;
end;

procedure TACLSkinImageSet.SaveToStream(const AStream: TStream);
var
  I: Integer;
begin
  BeginUpdate;
  try
    for I := 0 to Count - 1 do
    begin
      if I > 0 then
        AStream.WriteInt32(SYNC_WORD);
      Items[I].SaveToStream(AStream);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLSkinImageSet.CheckDPI(DPI: Integer);
begin
  if (DPI < acMinDPI) or (DPI > acMaxDPI) then
    raise Exception.CreateFmt(sErrorResolutionIsInvalid, [DPI]);
end;

procedure TACLSkinImageSet.DoAdd(AImage: TACLSkinImageSetItem);
var
  AIndex, I: Integer;
begin
  AIndex := 0;
  for I := 0 to Count - 1 do
  begin
    if Items[I].DPI < AImage.DPI then
      AIndex := I + 1;
  end;
  FItems.Insert(AIndex, AImage);
end;

procedure TACLSkinImageSet.DoAssign(Source: TPersistent);
begin
  if Source is TACLSkinImageSet then
  begin
    ReleaseItems;
    FItems.AddRange(TACLSkinImageSet(Source).FItems);
  end
  else
  begin
    Clear;
    MakeUnique;
    Items[0].Assign(Source);
  end;
end;

procedure TACLSkinImageSet.DoChanged(AChanges: TACLPersistentChanges);
begin
  CallNotifyEvent(Self, OnChange);
end;

procedure TACLSkinImageSet.ImageChangeHandler(Sender: TObject);
begin
  ReleaseTintedItems;
  Changed;
end;

procedure TACLSkinImageSet.ItemsChangeHandler(Sender: TObject;
  const Item: TACLSkinImageSetItem; Action: TCollectionNotification);
begin
  if Action = cnAdded then
  begin
    Item.ReferenceAdd;
    Item.ListenerAdd(ImageChangeHandler);
  end
  else
  begin
    Item.Release;
    Item.ListenerRemove(ImageChangeHandler);
    Item.ReferenceRemove;
  end;
  Changed;
end;

function TACLSkinImageSet.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TACLSkinImageSet.GetItem(Index: Integer): TACLSkinImageSetItem;
begin
  Result := FItems[Index];
end;

procedure TACLSkinImageSet.SetItem(Index: Integer; AValue: TACLSkinImageSetItem);
begin
  FItems[Index] := AValue;
end;

{ TACLSkinImageSetTintedItem }

constructor TACLSkinImageSetTintedItem.Create(ACollection: TList;
  ASource: TACLSkinImageSetItem; AColor: TAlphaColor; AMode: TACLSkinImageColorationMode);
var
  H, S, L: Byte;
begin
  inherited Create(ASource.DPI);
  FColor := AColor;
  FMode := AMode;
  FCollection := ACollection;
  FCollection.Add(Self);
  Assign(ASource);

  CheckUnpacked;
  CheckBitsState(ibsUnpremultiplied);
  case AMode of
    cmTint:
      TACLColors.Tint(PRGBQuad(Bits), BitCount, AColor.ToQuad);
    cmColor:
      TACLColors.ChangeColor(PRGBQuad(Bits), BitCount, AColor.ToQuad);
    cmHue:
      begin
        TACLColors.RGBtoHSLi(AColor.ToColor, H, S, L);
        TACLColors.ChangeHue(PRGBQuad(Bits), BitCount, H, MulDiv(100, S, MaxByte));
      end;
  end;
end;

destructor TACLSkinImageSetTintedItem.Destroy;
begin
  if FCollection <> nil then
    FCollection.Remove(Self);
  inherited Destroy;
end;

procedure TACLSkinImageSetTintedItem.Dormant;
begin
  // unsupported
end;

procedure TACLSkinImageSetTintedItem.Release;
begin
  FCollection := nil;
end;

{ TACLSkinImageSetTintedItemList }

constructor TACLSkinImageSetTintedItemList.Create(AOwner: TACLSkinImageSet);
begin
  FOwner := AOwner;
  FList := TList.Create;
end;

destructor TACLSkinImageSetTintedItemList.Destroy;
begin
  FreeAndNil(FList);
  inherited;
end;

function TACLSkinImageSetTintedItemList.Find(DPI: Integer; AColor: TAlphaColor; AMode: TACLSkinImageColorationMode): TACLSkinImageSetTintedItem;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
  begin
    Result := TACLSkinImageSetTintedItem(FList.List[I]);
    if (Result.DPI = DPI) and (Result.Color = AColor) and (Result.Mode = AMode) then
      Exit;
  end;
  Result := nil;
end;

function TACLSkinImageSetTintedItemList.GetOrCreate(DPI: Integer; const AColorScheme: TACLColorSchema): TACLSkinImageSetItem;
var
  R, G, B: Byte;
begin
  TACLColors.HSLtoRGBi(AColorScheme.Hue, MulDiv(MaxByte, AColorScheme.HueIntensity, 100), 128, R, G, B);
  Result := GetOrCreate(DPI, TAlphaColor.FromARGB(MaxByte, R, G, B), cmHue);
end;

function TACLSkinImageSetTintedItemList.GetOrCreate(DPI: Integer; const AColor: TAlphaColor; AMode: TACLSkinImageColorationMode): TACLSkinImageSetTintedItem;
var
  ASource: TACLSkinImageSetItem;
begin
  Result := Find(DPI, AColor, AMode);
  if Result = nil then
  begin
    ASource := FOwner.Get(DPI);
    if ASource.DPI <> DPI then
      Result := Find(ASource.DPI, AColor, AMode);
    if Result = nil then
      Result := TACLSkinImageSetTintedItem.Create(FList, ASource, AColor, AMode);
  end;
end;

procedure TACLSkinImageSetTintedItemList.Release;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
    TACLSkinImageSetTintedItem(FList.List[I]).Release;
  FList.Clear;
end;

end.
