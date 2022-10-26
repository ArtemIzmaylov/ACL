{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*                Collections                *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Classes.Collections;

{$I ACL.Config.inc}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows, // inlining
{$ENDIF}
  // System
  System.Classes,
  System.Contnrs,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SysUtils,
  System.Types,
  // ACL
  ACL.Classes,
  ACL.FastCode,
  ACL.Threading,
  ACL.Utils.Strings;

const
  sErrorValuesAreAlreadyInMap = 'These values are already exists in map';
  sErrorValueWasNotFoundInMap = 'This value was not found in map';

type
  // Стандартные IEnumerable<T> зачем-то наследуются от IEnumerable,
  // заставляя нас реализовывать ненужные оверлоады.

  { IACLEnumerator<T> }

  IACLEnumerator<T> = interface
    function GetCurrent: T;
    function MoveNext: Boolean;
    property Current: T read GetCurrent;
  end;

  { IACLEnumerable<T> }

  IACLEnumerable<T> = interface
    function GetEnumerator: IACLEnumerator<T>;
  end;

  { TACLArrayManager }

  TACLArrayManager<T> = class
  public
    procedure Move(var AArray: array of T; FromIndex, ToIndex, Count: Integer); overload; virtual; abstract;
    procedure Move(var FromArray, ToArray: array of T; FromIndex, ToIndex, Count: Integer); overload; virtual; abstract;
    procedure Finalize(var AArray: array of T; Index, Count: Integer); virtual; abstract;
  end;

  { TACLEnumerable }

  TACLEnumerable<T> = class(TACLUnknownObject, IACLEnumerable<T>)
  public
    // IACLEnumerable<T>
    function GetEnumerator: IACLEnumerator<T>; virtual; abstract;
    function ToArray: TArray<T>; virtual;
  end;

  { TACLMoveArrayManager }

  TACLMoveArrayManager<T> = class(TACLArrayManager<T>)
  public
    procedure Move(var AArray: array of T; FromIndex, ToIndex, Count: Integer); overload; override;
    procedure Move(var FromArray, ToArray: array of T; FromIndex, ToIndex, Count: Integer); overload; override;
    procedure Finalize(var AArray: array of T; Index, Count: Integer); override;
  end;

  { TACLManagedArrayManager }

  TACLManagedArrayManager<T> = class(TACLArrayManager<T>)
  public
    procedure Move(var AArray: array of T; FromIndex, ToIndex, Count: Integer); overload; override;
    procedure Move(var FromArray, ToArray: array of T; FromIndex, ToIndex, Count: Integer); overload; override;
    procedure Finalize(var AArray: array of T; Index, Count: Integer); override;
  end;

  { TACLLinkedListItem }

  TACLLinkedListItem<T> = class
  public
    Next: TACLLinkedListItem<T>;
    Prev: TACLLinkedListItem<T>;
    Value: T;
  end;

  { TACLLinkedList }

  TACLLinkedList<T> = class
  strict private
    FFirst: TACLLinkedListItem<T>;
    FLast: TACLLinkedListItem<T>;
    FOwnValues: Boolean;
  public
    constructor Create(AOwnValues: Boolean = False);
    function Add(const AItem: TACLLinkedListItem<T>): TACLLinkedListItem<T>; overload;
    function Add(const AValue: T): TACLLinkedListItem<T>; overload;
    procedure Clear;
    procedure Delete(AItem: TACLLinkedListItem<T>);
    function Extract(AItem: TACLLinkedListItem<T>): TACLLinkedListItem<T>;
    procedure InsertAfter(ASource, ATarget: TACLLinkedListItem<T>);
    procedure InsertBefore(ASource, ATarget: TACLLinkedListItem<T>);

    property First: TACLLinkedListItem<T> read FFirst;
    property Last: TACLLinkedListItem<T> read FLast;
  end;

  { TACLComponentList }

  TACLComponentList = class(TComponentList)
  public
    function Find(const AName: TComponentName; ARecursive: Boolean): TComponent;
  end;

  { TACLList }

  TACLListCompareProc = reference to function (const Item1, Item2: Pointer): Integer;

  TACLList = class(TList)
  strict private
    FOnChanged: TNotifyEvent;
  protected
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  public
    function ChangePlace(AOldIndex, ANewIndex: Integer): Boolean;
    function Contains(AItem: Pointer): Boolean; inline;
    procedure EnsureCapacity(ACount: Integer);
    procedure Exchange(Index1, Index2: Integer);
    function IsValid(Index: Integer): Boolean;
    //
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  { TACLListHelper }

  TACLListHelper = class helper for TList
  public
    procedure Invert;
    procedure Randomize;
  end;

  TACLListCompareProc<T> = reference to function (const Left, Right: T): Integer;

  TACLList<T> = class(TACLEnumerable<T>)
  strict private type
  {$REGION 'Private Types'}
    TListItems = array of T;

    TCompareProcWrapper = class(TComparer<T>)
    strict private
      FProc: TACLListCompareProc<T>;
    public
      constructor Create(AProc: TACLListCompareProc<T>);
      function Compare(const Left, Right: T): Integer; override;
    end;
  {$ENDREGION}
  strict private
    FComparer: IComparer<T>;
    FCount: Integer;
    FItems: TListItems;
    FItemsManager: TACLArrayManager<T>;

    FOnNotify: TCollectionNotifyEvent<T>;

    function GetCapacity: Integer;
    function GetLast: T; inline;
    function GetItem(Index: Integer): T;
    procedure SetCapacity(Value: Integer);
    procedure SetCount(Value: Integer);
    procedure SetItem(Index: Integer; const Value: T);
    procedure SetLast(const Value: T); inline;
    procedure SetOnNotify(const Value: TCollectionNotifyEvent<T>);

    procedure Grow(ACount: Integer);
    procedure GrowCheck(ACount: Integer); inline;
  protected
    FNotifications: Boolean;

    procedure DeleteRangeCore(AIndex, ACount: Integer; AAction: TCollectionNotification);

    procedure Notify(const Item: T; Action: TCollectionNotification); virtual;
    procedure UpdateNotificationFlag; virtual;
  public
    constructor Create; overload;
    constructor Create(const AComparer: IComparer<T>); overload;
    destructor Destroy; override;
    function GetEnumerator: IACLEnumerator<T>; override;

    // Adding
    function Add(const Value: T): Integer;
    function AddIfAbsent(const Value: T): Integer;
    procedure AddRange(const ASource: TACLList<T>);
    procedure Assign(const ASource: TACLList<T>);
    procedure Insert(Index: Integer; const Value: T); overload;
    procedure Insert(Index: Integer; const Values: array of T); overload;
    procedure Insert(Index: Integer; const Values: array of T; ValueCount: Integer); overload;
    procedure EnsureCapacity(ACount: Integer);
    procedure Move(CurIndex, NewIndex: Integer);
    procedure Merge(const ASource: TACLList<T>);
    function IsValid(Index: Integer): Boolean; inline;

    // Search
    function BinarySearch(const Value: T; out Index: Integer): Boolean;
    function Contains(const Value: T): Boolean;
    function IndexOf(const Value: T; ADirection: TDirection = TDirection.FromBeginning): Integer; virtual;

    // Removing
    procedure Clear; inline;
    procedure Delete(Index: Integer);
    procedure DeleteRange(AIndex, ACount: Integer);
    function Extract(const Value: T): T;
    function Remove(const Value: T): Integer;
    procedure Pack;

    // Sorting
    procedure Sort; overload;
    procedure Sort(AComparer: IComparer<T>); overload;
    procedure Sort(AProc: TACLListCompareProc<T>); overload;

    function ToArray: TArray<T>; override;

    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read FCount write SetCount;
    property Items[Index: Integer]: T read GetItem write SetItem; default;
    property List: TListItems read FItems;
    property First: T index 0 read GetItem write SetItem;
    property Last: T read GetLast write SetLast;

    property OnNotify: TCollectionNotifyEvent<T> read FOnNotify write SetOnNotify;
  end;

  { TACLListEnumerator }

  TACLListEnumerator<T> = class(TInterfacedObject, IACLEnumerator<T>)
  strict private
    FOwner: TACLList<T>;
    FIndex: Integer;
  protected
    // IACLEnumerator<T>
    function GetCurrent: T;
    function MoveNext: Boolean;
  public
    constructor Create(AOwner: TACLList<T>);
  end;

  { TACLVariantList }

  TACLVariantList = class(TACLList<Variant>);

  { TACLInterfaceList }

  TACLInterfaceList = class(TACLList<IUnknown>);

  { TACLListenerList }

  TACLListenerListEnumProc<T: IUnknown> = reference to procedure (const Intf: T);
  TACLListenerListEnumProc = TACLListenerListEnumProc<IUnknown>;

  TACLListenerList = class
  strict private
    FData: TACLInterfaceList;
    FEnumerable: IUnknown;
    FLock: TACLCriticalSection;

    FOnChange: TNotifyEvent;

    procedure Changed;
    procedure ChangeHandler(Sender: TObject; const Item: IUnknown; Action: TCollectionNotification);
    function GetCount: Integer;
  public
    constructor Create(AInitialCapacity: Integer = 0);
    destructor Destroy; override;
    //
    procedure Add(const AListener: IUnknown);
    procedure Clear;
    function Contains(const IID: TGUID): Boolean;
    procedure Enum(AProc: TACLListenerListEnumProc<IUnknown>); overload;
    procedure Enum<T: IUnknown>(AProc: TACLListenerListEnumProc<T>); overload;
    procedure Remove(const AListener: IUnknown);
    //
    property Count: Integer read GetCount;
    property Lock: TACLCriticalSection read FLock;
    //
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  { TACLObjectList }

  TACLObjectList = class(TACLList)
  strict private
    FOwnsObjects: Boolean;

    function GetItem(Index: Integer): TObject;
    procedure SetItem(Index: Integer; AObject: TObject);
  protected
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  public
    constructor Create(AOwnsObjects: Boolean = True);
    function Add(AObject: TObject): Integer;
    function Extract(AIndex: Integer): TObject; overload;
    function Extract(AItem: TObject): TObject; overload;
    function First: TObject;
    function Last: TObject;
    function Remove(AObject: TObject): Integer;
    procedure Insert(Index: Integer; AObject: TObject);
    // Properties
    property Items[Index: Integer]: TObject read GetItem write SetItem; default;
    property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;
  end;

  { TACLObjectList }

  TACLObjectList<T: class> = class(TACLList<T>)
  strict private
    FOwnsObjects: Boolean;

    procedure SetOwnObjects(const Value: Boolean);
  protected
    procedure Notify(const Item: T; Action: TCollectionNotification); override;
    procedure UpdateNotificationFlag; override;
  public
    constructor Create(AOwnsObjects: Boolean = True); overload;
    constructor Create(const AComparer: IComparer<T>; AOwnsObjects: Boolean = True); overload;
    //
    property OwnsObjects: Boolean read FOwnsObjects write SetOwnObjects;
  end;

  { TACLDictionary }

  TACLPairEnum<TKey, TValue> = reference to procedure (const Key: TKey; const Value: TValue);

  TACLDictionary<TKey, TValue> = class(TACLEnumerable<TPair<TKey, TValue>>)
  strict private const
    EMPTY_HASH = -1;
  strict private type
  {$REGION 'Internal Types'}

    TCustomEnumerator = class(TInterfacedObject)
    protected
      FIndex: Integer;
      FOwner: TACLDictionary<TKey, TValue>;
    public
      constructor Create(AOwner: TACLDictionary<TKey, TValue>);
      function MoveNext: Boolean;
    end;

    TPairEnumerator = class(TCustomEnumerator, IACLEnumerator<TPair<TKey, TValue>>)
    public
      function GetCurrent: TPair<TKey, TValue>;
    end;

    TKeyEnumerator = class(TCustomEnumerator,
      IACLEnumerable<TKey>,
      IACLEnumerator<TKey>)
    public
      function GetCurrent: TKey;
      function GetEnumerator: IACLEnumerator<TKey>;
    end;

    TValueEnumerator = class(TCustomEnumerator,
      IACLEnumerable<TValue>,
      IACLEnumerator<TValue>)
    public
      function GetCurrent: TValue;
      function GetEnumerator: IACLEnumerator<TValue>;
    end;

    PItem = ^TItem;
    TItem = record
      HashCode: Integer;
      Key: TKey;
      Value: TValue;
    end;
    TItemArray = array of TItem;

  {$ENDREGION}
  strict private
    FComparer: IEqualityComparer<TKey>;
    FCount: Integer;
    FGrowThreshold: Integer;
    FItems: TItemArray;
    FOwnerships: TDictionaryOwnerships;

    FOnKeyNotify: TCollectionNotifyEvent<TKey>;
    FOnValueNotify: TCollectionNotifyEvent<TValue>;

    procedure DoAddCore(HashCode, Index: Integer; const Key: TKey; const Value: TValue);
    function DoRemove(const Key: TKey; ABucketIndex: Integer; Notification: TCollectionNotification): TValue;
    procedure DoSetValue(Index: Integer; const Value: TValue);
    function GetBucketIndex(const Key: TKey; HashCode: Integer): Integer;
    function GetCapacity: Integer;
    function GetItem(const Key: TKey): TValue;
    procedure Grow;
    function Hash(const Key: TKey): Integer; inline;
    procedure Rehash(ACapacity: Integer);
    procedure RehashAdd(HashCode: Integer; const Key: TKey; const Value: TValue);
    procedure SetItem(const Key: TKey; const Value: TValue);
  protected
    function DoAdd(const Key: TKey; const Value: TValue; ADuplicates: TDuplicates): Boolean;
    procedure KeyNotify(const Key: TKey; Action: TCollectionNotification); virtual;
    procedure SetCapacity(ACapacity: Integer); virtual;
    procedure ValueNotify(const Value: TValue; Action: TCollectionNotification); virtual;
  public
    constructor Create(ACapacity: Integer = 0); overload;
    constructor Create(ACapacity: Integer; const AComparer: IEqualityComparer<TKey>); overload;
    constructor Create(AOwnerships: TDictionaryOwnerships); overload;
    constructor Create(AOwnerships: TDictionaryOwnerships; ACapacity: Integer; const AComparer: IEqualityComparer<TKey>); overload;
    constructor Create(AOwnerships: TDictionaryOwnerships; const AComparer: IEqualityComparer<TKey>); overload;
    constructor Create(const AComparer: IEqualityComparer<TKey>); overload;
    destructor Destroy; override;
    procedure Add(const Key: TKey; const Value: TValue);
    function AddIfAbsent(const Key: TKey; const Value: TValue): Boolean;
    procedure AddOrSetValue(const Key: TKey; const Value: TValue);
    procedure Clear(AKeepCapacity: Boolean = False); virtual;
    function ContainsKey(const Key: TKey): Boolean;
    function ContainsValue(const Value: TValue): Boolean;

    // Enums
    procedure Enum(const AProc: TACLPairEnum<TKey, TValue>); virtual;
    function GetEnumerator: IACLEnumerator<TPair<TKey, TValue>>; override;
    function GetKeys: IACLEnumerable<TKey>; virtual;
    function GetValues: IACLEnumerable<TValue>; virtual;

    procedure Remove(const Key: TKey);
    procedure TrimExcess;
    function TryExtract(const Key: TKey; out Value: TValue): Boolean;
    function TryExtractFirst(out Key: TKey; out Value: TValue): Boolean;
    function TryGetValue(const Key: TKey; out Value: TValue): Boolean;

    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read FCount;
    property Items[const Key: TKey]: TValue read GetItem write SetItem; default;
  public
    property OnKeyNotify: TCollectionNotifyEvent<TKey> read FOnKeyNotify write FOnKeyNotify;
    property OnValueNotify: TCollectionNotifyEvent<TValue> read FOnValueNotify write FOnValueNotify;
  end;

  { TACLStringsDictionary }

  TACLStringsDictionary = class(TACLDictionary<string, string>);

  { TACLThreadList }

  TACLThreadList<T> = class
  public type
    TEnumProc = reference to procedure (const Value: T);
  strict private
    FList: TACLList<T>;
    FLock: IReadWriteSync;
  public
    constructor Create; overload;
    constructor Create(ASync: IReadWriteSync); overload;
    constructor CreateMultiReadExclusiveWrite(CBuilderSux: Integer = 0);
    destructor Destroy; override;
    procedure Add(const Value: T);
    procedure Clear;
    function Contains(const Value: T): Boolean;
    function Count: Integer;
    procedure Enum(AProc: TEnumProc);
    function Read(AIndex: Integer; out AValue: T): Boolean;
    procedure Remove(const Value: T);

    function BeginRead: TACLList<T>;
    function BeginWrite: TACLList<T>;
    procedure EndRead;
    procedure EndWrite;

    function LockList: TACLList<T>;
    procedure UnlockList;
  end;

  { TACLClassMap }

  TACLClassMap<T> = class(TACLUnknownObject)
  strict private
    FData: TACLDictionary<TClass, T>;

    function GetItem(AClass: TClass): T;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AClass: TClass; const AValue: T);
    procedure AddOrSetValue(const AClass: TClass; const AValue: T);
    procedure Remove(const AClass: TClass);
    function TryGetValue(AClass: TClass; out AValue: T): Boolean; reintroduce; overload;
    function TryGetValue(AObject: TObject; out AValue: T): Boolean; reintroduce; overload;
    property Items[AClass: TClass]: T read GetItem; default;
  end;

  { TACLMap }

  TACLMap<TKey, TValue> = class(TACLUnknownObject)
  strict private
    FKeyToValue: TACLDictionary<TKey, TValue>;
    FValueToKey: TACLDictionary<TValue, TKey>;
  public
    constructor Create(
      AComparerKey: IEqualityComparer<TKey> = nil;
      AComparerValue: IEqualityComparer<TValue> = nil;
      AOwnerships: TDictionaryOwnerships = []; ACapacity: Integer = 0); overload;
    constructor Create(ACapacity: Integer; AOwnerships: TDictionaryOwnerships = []); overload;
    constructor Create(AOwnerships: TDictionaryOwnerships); overload;
    destructor Destroy; override;
    procedure Add(const AKey: TKey; const AValue: TValue);
    procedure Clear;
    procedure DeleteByKey(const AKey: TKey); overload;
    procedure DeleteByValue(const AValue: TValue); overload;
    procedure Enum(AProc: TACLPairEnum<TKey, TValue>);
    function GetKey(const AValue: TValue): TKey;
    function GetValue(const AKey: TKey): TValue;
    function TryGetKey(const AValue: TValue; out AKey: TKey): Boolean;
    function TryGetValue(const AKey: TKey; out AValue: TValue): Boolean;
  end;

  { TACLCustomHashSet }

  TACLCustomHashSet<T> = class(TACLEnumerable<T>)
  protected
    function GetCount: Integer; virtual; abstract;
  public
    procedure Clear; virtual; abstract;
    function Contains(const Item: T): Boolean; virtual; abstract;
    function Exclude(const Item: T): Boolean; overload; virtual; abstract;
    function Exclude(const ItemSet: TACLCustomHashSet<T>; AutoFree: Boolean): Boolean; overload;
    function Include(const Item: T): Boolean; overload; virtual; abstract;
    function Include(const ItemSet: TACLCustomHashSet<T>; AutoFree: Boolean): Boolean; overload;
    function ToArray: TArray<T>; override;
    //
    property Count: Integer read GetCount;
  end;

  { TACLHashSet }

  TACLHashSet<T> = class(TACLCustomHashSet<T>)
  protected const
    EMPTY_HASH = -1;
  strict private type
  {$REGION 'Internal Types'}
    TEnumerator = class(TInterfacedObject, IACLEnumerator<T>)
    strict private
      FIndex: Integer;
      FOwner: TACLHashSet<T>;
    public
      constructor Create(AOwner: TACLHashSet<T>);
      function GetCurrent: T;
      function MoveNext: Boolean;
    end;
    TItem = record
      HashCode: Integer;
      Item: T;
    end;
    TItemArray = array of TItem;
  {$ENDREGION}
  strict private
    FComparer: IEqualityComparer<T>;
    FCount: Integer;
    FGrowThreshold: Integer;
    FItems: TItemArray;

    procedure DoAdd(HashCode, Index: Integer; const Item: T);
    procedure DoGrow;
    procedure DoRehash(ACapacity: Integer);
    procedure DoRehashAdd(HashCode: Integer; const Item: T);
    procedure DoRemove(ABucketIndex: Integer);
    function GetBucketIndex(const Item: T; HashCode: Integer): Integer;
    function Hash(const Item: T): Integer; inline;
    procedure SetCapacity(AValue: Integer);
  protected
    function GetCount: Integer; override;
  public
    constructor Create(AInitialCapacity: Integer = 0); overload;
    constructor Create(const AComparer: IEqualityComparer<T>; AInitialCapacity: Integer = 0); overload;
    destructor Destroy; override;
    procedure Clear; override;
    function Contains(const Item: T): Boolean; override;
    function Exclude(const Item: T): Boolean; override;
    function Include(const Item: T): Boolean; override;
    function GetEnumerator: IACLEnumerator<T>; override;
  end;

  { TACLStringSet }

  TACLStringSet = class(TACLHashSet<string>)
  public
    constructor Create(const IgnoreCase: Boolean; InitialCapacity: Integer = 0); reintroduce;
    function Contains(const Item: PWideChar; const ItemLength: Integer): Boolean; reintroduce; overload;
    function Exclude(const Item: PWideChar; const ItemLength: Integer): Boolean; reintroduce; overload;
    function Include(const Item: PWideChar; const ItemLength: Integer): Boolean; reintroduce; overload;
  end;

//  { TACLStringSet }
//
//  TACLStringSet = class(TACLCustomHashSet<string>)
//  strict private
//    FData: TACLList<string>;
//    FIgnoreCase: Boolean;
//
//    function FindCore(const Item: PWideChar; const ItemLength: Integer; out Index: Integer): Boolean;
//    function IncludeCore(const Item: PWideChar; const ItemLength: Integer; B: PUnicodeString): Boolean;
//  protected
//    function DoGetEnumerator: TEnumerator<string>; override;
//    function GetCount: Integer; override;
//  public
//    constructor Create(const IgnoreCase: Boolean; InitialCapacity: Integer = 0);
//    destructor Destroy; override;
//    procedure Clear; override;
//    function Contains(const Item: string): Boolean; overload; override;
//    function Contains(const Item: PWideChar; const ItemLength: Integer): Boolean; reintroduce; overload;
//    function Exclude(const Item: string): Boolean; overload; override;
//    function Exclude(const Item: PWideChar; const ItemLength: Integer): Boolean; reintroduce; overload;
//    function Include(const Item: string): Boolean; overload; override;
//    function Include(const Item: PWideChar; const ItemLength: Integer): Boolean; reintroduce; overload;
//    function Include(const Items: TACLStringSet; AAutoFree: Boolean): Boolean; reintroduce; overload;
//    function ToArray: TArray<string>; override;
//  end;

  { TACLStringComparer }

  TACLStringComparer = class(TInterfacedObject,
    IComparer<string>,
    IEqualityComparer<string>)
  strict private
    FIgnoreCase: Boolean;
  public
    constructor Create(IgnoreCase: Boolean = True);
    // IComparer<string>
    function Compare(const Left, Right: string): Integer;
    // IEqualityComparer<string>
    function Equals(const Left, Right: string): Boolean; reintroduce;
    function GetHashCode(const Value: string): Integer; reintroduce;
  end;

  { TACLStringsMap }

  TACLStringsMap = class(TACLMap<string, string>);

  { TACLStringSharedTable }

  TACLStringSharedTable = class
  strict private type
  {$REGION 'Internal types'}
    TItem = class
    public
      Next: TItem;
      Value: UnicodeString;
      ValueHash: Cardinal;

      constructor Create(Hash: Cardinal; P: PWideChar; L: Cardinal; B: PUnicodeString);
    end;
    TItemArray = array of TItem;
  {$ENDREGION}
  strict private
    FTable: TItemArray;
    FTableSize: Cardinal;

    procedure Clear;
    function Share(P: PWideChar; L: Integer; B: PUnicodeString): UnicodeString; overload;
  public
    constructor Create;
    destructor Destroy; override;
    function Share(const P: PWideChar; const L: Integer): UnicodeString; overload; inline;
    function Share(const U: UnicodeString): UnicodeString; overload; inline;
  end;

  { TACLOrderedDictionary }

  TACLOrderedDictionary<TKey, TValue> = class(TACLDictionary<TKey, TValue>)
  strict private type
  {$REGION 'Internal Types'}

    TEnumerator = class(TInterfacedObject)
    protected
      FIndex: Integer;
      FOwner: TACLOrderedDictionary<TKey, TValue>;
    public
      constructor Create(AOwner: TACLOrderedDictionary<TKey, TValue>);
      function MoveNext: Boolean;
    end;

    TPairEnumerator = class(TEnumerator, IACLEnumerator<TPair<TKey, TValue>>)
    public
      function GetCurrent: TPair<TKey, TValue>;
    end;

    TValueEnumerator = class(TEnumerator,
      IACLEnumerable<TValue>,
      IACLEnumerator<TValue>)
    public
      function GetCurrent: TValue;
      function GetEnumerator: IACLEnumerator<TValue>;
    end;

  {$ENDREGION}
  strict private
    FOrder: TACLList<TKey>;

    function GetKey(Index: Integer): TKey; inline;
  protected
    procedure KeyNotify(const Key: TKey; Action: TCollectionNotification); override;
    procedure SetCapacity(AValue: Integer); override;
  public
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure Clear(AKeepCapacity: Boolean = False); override;
    procedure Enum(const AProc: TACLPairEnum<TKey, TValue>); override;
    function GetEnumerator: IACLEnumerator<TPair<TKey, TValue>>; override;
    function GetKeys: IACLEnumerable<TKey>; override;
    function GetValues: IACLEnumerable<TValue>; override;
    //
    property Keys[Index: Integer]: TKey read GetKey; default;
  end;

  { TACLValueCacheManager }

  TACLValueCacheManager<TKey, TValue> = class
  public type
    TRemoveEvent = procedure (Sender: TObject; const AValue: TValue) of object;
  strict private type
    TQueueItem = TPair<TKey, Boolean>;
    PQueueItem = ^TQueueItem;
  strict private
    FCapacity: Integer;
    FComparer: IEqualityComparer<TKey>;
    FData: TACLDictionary<TKey, TValue>;
    FQueue: array of TQueueItem;
    FQueueCursor: Integer;

    FOnRemove: TRemoveEvent;

    procedure ValueHandler(Sender: TObject; const Item: TValue; Action: TCollectionNotification);
  protected
    procedure DoRemove(const Item: TValue); virtual;
  public
    constructor Create(ACapacity: Integer = 256); overload;
    constructor Create(ACapacity: Integer; AEqualityComparer: IEqualityComparer<TKey>); overload;
    destructor Destroy; override;
    procedure Add(const Key: TKey; const Value: TValue);
    procedure Clear;
    function Get(const Key: TKey; out Value: TValue): Boolean;
    procedure Remove(const Key: TKey);
    //
    property Capacity: Integer read FCapacity;
    //
    property OnRemove: TRemoveEvent read FOnRemove write FOnRemove;
  end;

  { TACLObjectDictionary }

  TACLObjectDictionary = class(TACLDictionary<TObject, TObject>);

  { TACLFloatList }

  TACLFloatList = class(TACLList<Single>)
  public
    function Contains(const Value, Tolerance: Single): Boolean; overload;
    function IndexOf(const Value, Tolerance: Single): Integer; reintroduce; overload;
  end;

implementation

uses
  System.Math,
  System.RTLConsts,
  System.SysConst,
  System.TypInfo,
  // ACL
  ACL.Utils.Common,
  ACL.Hashes;

{ TACLEnumerable<T> }

function TACLEnumerable<T>.ToArray: TArray<T>;
var
  ACapacity: Integer;
  AIndex: Integer;
begin
  Result := nil;
  AIndex := 0;
  ACapacity := 0;
  for var AValue in Self do
  begin
    if AIndex >= ACapacity then
    begin
      ACapacity := GrowCollection(ACapacity, AIndex + 1);
      SetLength(Result, ACapacity);
    end;
    Result[AIndex] := AValue;
    Inc(AIndex);
  end;
  SetLength(Result, AIndex);
end;

{ TACLMoveArrayManager<T> }

procedure TACLMoveArrayManager<T>.Finalize(var AArray: array of T; Index, Count: Integer);
begin
  System.FillChar(AArray[Index], Count * SizeOf(T), 0);
end;

procedure TACLMoveArrayManager<T>.Move(var AArray: array of T; FromIndex, ToIndex, Count: Integer);
begin
  System.Move(AArray[FromIndex], AArray[ToIndex], Count * SizeOf(T));
end;

procedure TACLMoveArrayManager<T>.Move(var FromArray, ToArray: array of T; FromIndex, ToIndex, Count: Integer);
begin
  System.Move(FromArray[FromIndex], ToArray[ToIndex], Count * SizeOf(T));
end;

{ TACLManagedArrayManager<T> }

procedure TACLManagedArrayManager<T>.Finalize(var AArray: array of T; Index, Count: Integer);
begin
  System.Finalize(AArray[Index], Count);
  System.FillChar(AArray[Index], Count * SizeOf(T), 0);
end;

procedure TACLManagedArrayManager<T>.Move(var AArray: array of T; FromIndex, ToIndex, Count: Integer);
var
  I: Integer;
begin
  if Count > 0 then
    if FromIndex < ToIndex then
      for I := Count - 1 downto 0 do
        AArray[ToIndex + I] := AArray[FromIndex + I]
    else if FromIndex > ToIndex then
      for I := 0 to Count - 1 do
        AArray[ToIndex + I] := AArray[FromIndex + I];
end;

procedure TACLManagedArrayManager<T>.Move(var FromArray, ToArray: array of T; FromIndex, ToIndex, Count: Integer);
var
  I: Integer;
begin
  if Count > 0 then
    if FromIndex < ToIndex then
      for I := Count - 1 downto 0 do
        ToArray[ToIndex + I] := FromArray[FromIndex + I]
    else if FromIndex > ToIndex then
      for I := 0 to Count - 1 do
        ToArray[ToIndex + I] := FromArray[FromIndex + I];
end;

{ TACLLinkedList<T> }

constructor TACLLinkedList<T>.Create(AOwnValues: Boolean);
begin
  FOwnValues := AOwnValues;
  if AOwnValues then
  begin
    if (TypeInfo(T) = nil) or (PTypeInfo(TypeInfo(T))^.Kind <> tkClass) then
      raise EInvalidCast.CreateRes(@SInvalidCast);
  end;
end;

function TACLLinkedList<T>.Add(const AItem: TACLLinkedListItem<T>): TACLLinkedListItem<T>;
begin
  Result := AItem;
  if Last <> nil then
    InsertAfter(Result, Last)
  else
  begin
    FLast := Result;
    FFirst := Result;
  end;
end;

function TACLLinkedList<T>.Add(const AValue: T): TACLLinkedListItem<T>;
begin
  Result := TACLLinkedListItem<T>.Create;
  Result.Value := AValue;
  Result := Add(Result);
end;

procedure TACLLinkedList<T>.Clear;
begin
  while FFirst <> nil do
    Delete(FFirst);
end;

procedure TACLLinkedList<T>.Delete(AItem: TACLLinkedListItem<T>);
begin
  AItem := Extract(AItem);
  try
    if FOwnValues then
      PObject(@AItem.Value)^.Free;
  finally
    AItem.Free;
  end;
end;

function TACLLinkedList<T>.Extract(AItem: TACLLinkedListItem<T>): TACLLinkedListItem<T>;
begin
  if AItem.Next <> nil then
    AItem.Next.Prev := AItem.Prev
  else
    FLast := AItem.Prev;

  if AItem.Prev <> nil then
    AItem.Prev.Next := AItem.Next
  else
    FFirst := AItem.Next;

  Result := AItem;
  Result.Next := nil;
  Result.Prev := nil;
end;

procedure TACLLinkedList<T>.InsertAfter(ASource, ATarget: TACLLinkedListItem<T>);
begin
  ASource.Next := ATarget.Next;
  if ATarget.Next <> nil then
    ATarget.Next.Prev := ASource
  else
    FLast := ASource;

  ATarget.Next := ASource;
  ASource.Prev := ATarget;
end;

procedure TACLLinkedList<T>.InsertBefore(ASource, ATarget: TACLLinkedListItem<T>);
begin
  ASource.Prev := ATarget.Prev;
  if ATarget.Prev <> nil then
    ATarget.Prev.Next := ASource
  else
    FFirst := ASource;

  ATarget.Prev := ASource;
  ASource.Next := ATarget;
end;

{ TACLComponentList }

function TACLComponentList.Find(const AName: TComponentName; ARecursive: Boolean): TComponent;
var
  AItem: TComponent;
  I: Integer;
begin
  Result := nil;
  if AName <> '' then
    for I := 0 to Count - 1 do
    begin
      AItem := Items[I];
      if acSameText(AItem.Name, AName) then
        Exit(AItem);
      if ARecursive then
      begin
        AItem := acFindComponent(AItem, AName);
        if AItem <> nil then
          Exit(AITem);
      end;
    end;
end;

{ TACLList }

function TACLList.ChangePlace(AOldIndex, ANewIndex: Integer): Boolean;
var
  AOldValue: Pointer;
  CP, NP: PPointer;
  I: Integer;
begin
  Result := IsValid(AOldIndex) and IsValid(ANewIndex);
  if Result then
  begin
    if AOldIndex <> ANewIndex then
    begin
      AOldValue := List[AOldIndex];
      if AOldIndex > ANewIndex then
      begin
        CP := @List[AOldIndex - 1];
        NP := @List[AOldIndex];
        for I := AOldIndex - 1 downto ANewIndex do
        begin
          NP^ := CP^;
          Dec(NP);
          Dec(CP)
        end;
      end
      else
      begin
        CP := @List[AOldIndex];
        NP := @List[AOldIndex + 1];
        for I := AOldIndex to ANewIndex - 1 do
        begin
          CP^ := NP^;
          Inc(NP);
          Inc(CP)
        end;
      end;
      List[ANewIndex] := AOldValue;
    end;
    CallNotifyEvent(Self, OnChanged);
  end;
end;

function TACLList.Contains(AItem: Pointer): Boolean;
begin
  Result := IndexOf(AItem) >= 0;
end;

procedure TACLList.EnsureCapacity(ACount: Integer);
begin
  Capacity := Max(Capacity, Count + ACount);
end;

procedure TACLList.Exchange(Index1, Index2: Integer);
begin
  inherited Exchange(Index1, Index2);
  if Assigned(OnChanged) then OnChanged(Self);
end;

function TACLList.IsValid(Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index < Count);
end;

procedure TACLList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  inherited Notify(Ptr, Action);
  if Assigned(OnChanged) then OnChanged(Self);
end;

{ TACLList<T> }

constructor TACLList<T>.Create;
begin
  Create(nil);
end;

constructor TACLList<T>.Create(const AComparer: IComparer<T>);
begin
  FComparer := AComparer;
  if FComparer = nil then
    FComparer := TComparer<T>.Default;
  if System.IsManagedType(T) then
    FItemsManager := TACLManagedArrayManager<T>.Create
  else
    FItemsManager := TACLMoveArrayManager<T>.Create;
end;

destructor TACLList<T>.Destroy;
begin
  Clear;
  FreeAndNil(FItemsManager);
  inherited Destroy;
end;

function TACLList<T>.GetEnumerator: IACLEnumerator<T>;
begin
  Result := TACLListEnumerator<T>.Create(Self);
end;

function TACLList<T>.Add(const Value: T): Integer;
begin
  GrowCheck(Count + 1);
  Result := Count;
  FItems[Count] := Value;
  Inc(FCount);
  if FNotifications then
    Notify(Value, cnAdded);
end;

function TACLList<T>.AddIfAbsent(const Value: T): Integer;
begin
  Result := IndexOf(Value);
  if Result < 0 then
    Result := Add(Value);
end;

procedure TACLList<T>.AddRange(const ASource: TACLList<T>);
begin
  Insert(Count, ASource.List, ASource.Count);
end;

procedure TACLList<T>.Assign(const ASource: TACLList<T>);
begin
  Clear;
  AddRange(ASource);
end;

procedure TACLList<T>.Insert(Index: Integer; const Value: T);
begin
  if (Index < 0) or (Index > Count) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  GrowCheck(Count + 1);
  if Index <> Count then
  begin
    FItemsManager.Move(FItems, Index, Index + 1, Count - Index);
    FItemsManager.Finalize(FItems, Index, 1);
  end;

  FItems[Index] := Value;
  Inc(FCount);

  if FNotifications then
    Notify(Value, cnAdded);
end;

procedure TACLList<T>.Insert(Index: Integer; const Values: array of T);
begin
  Insert(Index, Values, Length(Values));
end;

procedure TACLList<T>.Insert(Index: Integer; const Values: array of T; ValueCount: Integer);
var
  I: Integer;
begin
  if (Index < 0) or (Index > Count) or (ValueCount < 0) or (ValueCount > Length(Values)) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  GrowCheck(Count + ValueCount);
  if Index <> Count then
  begin
    FItemsManager.Move(FItems, Index, Index + ValueCount, Count - Index);
    FItemsManager.Finalize(FItems, Index, ValueCount);
  end;

  for I := 0 to ValueCount - 1 do
    FItems[Index + I] := Values[I];
  Inc(FCount, ValueCount);

  if FNotifications then
  begin
    for I := 0 to ValueCount - 1 do
      Notify(Values[I], cnAdded);
  end;
end;

procedure TACLList<T>.EnsureCapacity(ACount: Integer);
begin
  Capacity := Max(Capacity, Count + ACount);
end;

function TACLList<T>.IsValid(Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index < FCount);
end;

procedure TACLList<T>.Merge(const ASource: TACLList<T>);
var
  I: Integer;
begin
  EnsureCapacity(ASource.Count);
  for I := 0 to ASource.Count - 1 do
    AddIfAbsent(ASource.List[I]);
end;

procedure TACLList<T>.Move(CurIndex, NewIndex: Integer);
var
   ATemp: T;
begin
  if CurIndex = NewIndex then
    Exit;
  if not IsValid(NewIndex) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  ATemp := FItems[CurIndex];
  FItems[CurIndex] := Default(T);
  if CurIndex < NewIndex then
    FItemsManager.Move(FItems, CurIndex + 1, CurIndex, NewIndex - CurIndex)
  else
    FItemsManager.Move(FItems, NewIndex, NewIndex + 1, CurIndex - NewIndex);

  FItemsManager.Finalize(FItems, NewIndex, 1);
  FItems[NewIndex] := ATemp;
end;

function TACLList<T>.BinarySearch(const Value: T; out Index: Integer): Boolean;
begin
  Result := TArray.BinarySearch<T>(FItems, Value, Index, FComparer, 0, Count);
end;

function TACLList<T>.Contains(const Value: T): Boolean;
begin
  Result := IndexOf(Value) >= 0;
end;

function TACLList<T>.IndexOf(const Value: T; ADirection: TDirection = TDirection.FromBeginning): Integer;
var
  I: Integer;
begin
  if ADirection = TDirection.FromBeginning then
  begin
    for I := 0 to Count - 1 do
    begin
      if FComparer.Compare(FItems[I], Value) = 0 then
        Exit(I);
    end;
  end
  else
    for I := Count - 1 downto 0 do
    begin
      if FComparer.Compare(FItems[I], Value) = 0 then
        Exit(I);
    end;

  Result := -1;
end;

procedure TACLList<T>.Clear;
begin
  Capacity := 0;
end;

procedure TACLList<T>.Delete(Index: Integer);
begin
  DeleteRange(Index, 1);
end;

procedure TACLList<T>.DeleteRange(AIndex, ACount: Integer);
begin
  DeleteRangeCore(AIndex, ACount, cnRemoved);
end;

function TACLList<T>.Extract(const Value: T): T;
var
  AIndex: Integer;
begin
  AIndex := IndexOf(Value);
  if AIndex < 0 then
    Result := Default(T)
  else
  begin
    Result := FItems[AIndex];
    DeleteRangeCore(AIndex, 1, cnExtracted);
  end;
end;

function TACLList<T>.Remove(const Value: T): Integer;
begin
  Result := IndexOf(Value);
  if Result >= 0 then
    Delete(Result);
end;

procedure TACLList<T>.Pack;
var
  AEndIndex: Integer;
  APackedCount: Integer;
  AStartIndex: Integer;
begin
  if FCount = 0 then
    Exit;

  APackedCount := 0;
  AStartIndex := 0;
  repeat
    // Locate the first/next non-nil element in the list
    while (AStartIndex < FCount) and (FComparer.Compare(FItems[AStartIndex], Default(T)) = 0) do
      Inc(AStartIndex);

    if AStartIndex < FCount then // There is nothing more to do
    begin
      // Locate the next nil pointer
      AEndIndex := AStartIndex;
      while (AEndIndex < FCount) and (FComparer.Compare(FItems[AEndIndex], Default(T)) <> 0) do
        Inc(AEndIndex);
      Dec(AEndIndex);

      // Move this block of non-null items to the index recorded in PackedToCount:
      // If this is a contiguous non-nil block at the start of the list then
      // AStartIndex and PackedToCount will be equal (and 0) so don't bother with the move.
      if AStartIndex > APackedCount then
        FItemsManager.Move(FItems, AStartIndex, APackedCount, AEndIndex - AStartIndex + 1);

      // Set the PackedToCount to reflect the number of items in the list
      // that have now been packed.
      Inc(APackedCount, AEndIndex - AStartIndex + 1);

      // Reset AStartIndex to the element following AEndIndex
      AStartIndex := AEndIndex + 1;
    end;
  until AStartIndex >= FCount;

  // Set Count so that the 'free' item
  FCount := APackedCount;
end;

procedure TACLList<T>.Sort;
begin
  Sort(FComparer);
end;

procedure TACLList<T>.Sort(AComparer: IComparer<T>);
begin
  TArray.Sort<T>(FItems, AComparer, 0, Count);
end;

procedure TACLList<T>.Sort(AProc: TACLListCompareProc<T>);
begin
  Sort(TCompareProcWrapper.Create(AProc));
end;

function TACLList<T>.ToArray: TArray<T>;
var
  I: Integer;
begin
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := List[I];
end;

procedure TACLList<T>.DeleteRangeCore(AIndex, ACount: Integer; AAction: TCollectionNotification);
var
  AOldItems: TListItems;
  ATailCount, I: Integer;
begin
  if (AIndex < 0) or (ACount < 0) or (AIndex + ACount > Count) or (AIndex + ACount < 0) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  if ACount = 0 then
    Exit;

  if FNotifications then
  begin
    SetLength(AOldItems, ACount);
    FItemsManager.Move(FItems, AOldItems, AIndex, 0, ACount);
  end;

  ATailCount := Count - (AIndex + ACount);
  if ATailCount > 0 then
  begin
    FItemsManager.Move(FItems, AIndex + ACount, AIndex, ATailCount);
    FItemsManager.Finalize(FItems, Count - ACount, ACount);
  end
  else
    FItemsManager.Finalize(FItems, AIndex, ACount);

  Dec(FCount, ACount);
  if FNotifications then
  begin
    for I := 0 to Length(AOldItems) - 1 do
      Notify(AOldItems[I], AAction);
  end;
end;

procedure TACLList<T>.UpdateNotificationFlag;
begin
  FNotifications := Assigned(OnNotify);
end;

procedure TACLList<T>.Notify(const Item: T; Action: TCollectionNotification);
begin
  if Assigned(OnNotify) then
    OnNotify(Self, Item, Action);
end;

function TACLList<T>.GetCapacity: Integer;
begin
  Result := Length(FItems);
end;

function TACLList<T>.GetItem(Index: Integer): T;
begin
  if (Index < 0) or (Index >= Count) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  Result := FItems[Index];
end;

function TACLList<T>.GetLast: T;
begin
  Result := Items[Count - 1];
end;

procedure TACLList<T>.SetCapacity(Value: Integer);
begin
  if Value < Count then
    Count := Value;
  SetLength(FItems, Value);
end;

procedure TACLList<T>.SetCount(Value: Integer);
begin
  if Value < 0 then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  if Value > Capacity then
    SetCapacity(Value);
  if Value < Count then
    DeleteRange(Value, Count - Value);
  FCount := Value;
end;

procedure TACLList<T>.SetItem(Index: Integer; const Value: T);
var
  AOldItem: T;
begin
  if (Index < 0) or (Index >= Count) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  if FNotifications then
  begin
    AOldItem := FItems[Index];
    FItems[Index] := Value;
    Notify(AOldItem, cnRemoved);
    Notify(Value, cnAdded);
  end
  else
    FItems[Index] := Value;
end;

procedure TACLList<T>.SetLast(const Value: T);
begin
  Items[Count - 1] := Value;
end;

procedure TACLList<T>.SetOnNotify(const Value: TCollectionNotifyEvent<T>);
begin
  FOnNotify := Value;
  UpdateNotificationFlag;
end;

procedure TACLList<T>.Grow(ACount: Integer);
var
  ANewCount: Integer;
begin
  ANewCount := Length(FItems);
  if ANewCount = 0 then
    ANewCount := ACount
  else
    repeat
      ANewCount := ANewCount * 2;
      if ANewCount < 0 then
        OutOfMemoryError;
    until ANewCount >= ACount;

  Capacity := ANewCount;
end;

procedure TACLList<T>.GrowCheck(ACount: Integer);
begin
  if ACount > Length(FItems) then
    Grow(ACount)
  else if ACount < 0 then
    OutOfMemoryError;
end;

{ TACLListEnumerator<T> }

constructor TACLListEnumerator<T>.Create(AOwner: TACLList<T>);
begin
  FIndex := -1;
  FOwner := AOwner;
end;

function TACLListEnumerator<T>.GetCurrent: T;
begin
  Result := FOwner.List[FIndex];
end;

function TACLListEnumerator<T>.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FOwner.Count;
end;

{ TACLList<T>.TCompareProcWrapper }

constructor TACLList<T>.TCompareProcWrapper.Create(AProc: TACLListCompareProc<T>);
begin
  FProc := AProc;
end;

function TACLList<T>.TCompareProcWrapper.Compare(const Left, Right: T): Integer;
begin
  Result := FProc(Left, Right);
end;

{ TACLListHelper }

procedure TACLListHelper.Invert;
var
  S1, S2: PPointer;
  I: Integer;
  P: Pointer;
begin
  S1 := @List[0];
  S2 := @List[Count - 1];
  for I := 0 to (Count - 1) div 2 - Integer(Odd(Count)) do
  begin
    P := S1^;
    S1^ := S2^;
    S2^ := P;
    Inc(S1);
    Dec(S2);
  end;
end;

procedure TACLListHelper.Randomize;
var
  L: TList;
  I, J: Integer;
begin
  L := TList.Create;
  try
    L.Capacity := Count;
    for I := 0 to Count - 1 do
      L.Add(List[I]);
    for I := 0 to Count - 1 do
    begin
      J := Random(L.Count);
      List[I] := L.List[J];
      L.Delete(J);
    end;
  finally
    L.Free;
  end;
end;

{ TDictionary<TKey,TValue> }

constructor TACLDictionary<TKey, TValue>.Create(ACapacity: Integer = 0);
begin
  Create(ACapacity, nil);
end;

constructor TACLDictionary<TKey, TValue>.Create(const AComparer: IEqualityComparer<TKey>);
begin
  Create(0, AComparer);
end;

constructor TACLDictionary<TKey, TValue>.Create(ACapacity: Integer; const AComparer: IEqualityComparer<TKey>);
begin
  if ACapacity < 0 then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  FComparer := AComparer;
  if FComparer = nil then
    FComparer := TEqualityComparer<TKey>.Default;

  SetCapacity(ACapacity);
end;

constructor TACLDictionary<TKey, TValue>.Create(AOwnerships: TDictionaryOwnerships);
begin
  Create(AOwnerships, 0, nil);
end;

constructor TACLDictionary<TKey, TValue>.Create(AOwnerships: TDictionaryOwnerships; const AComparer: IEqualityComparer<TKey>);
begin
  Create(AOwnerships, 0, AComparer);
end;

constructor TACLDictionary<TKey, TValue>.Create(AOwnerships: TDictionaryOwnerships; ACapacity: Integer; const AComparer: IEqualityComparer<TKey>);
begin
  Create(ACapacity, AComparer);

  if doOwnsKeys in AOwnerships then
  begin
    if (TypeInfo(TKey) = nil) or (PTypeInfo(TypeInfo(TKey))^.Kind <> tkClass) then
      raise EInvalidCast.CreateRes(@SInvalidCast);
  end;

  if doOwnsValues in AOwnerships then
  begin
    if (TypeInfo(TValue) = nil) or (PTypeInfo(TypeInfo(TValue))^.Kind <> tkClass) then
      raise EInvalidCast.CreateRes(@SInvalidCast);
  end;

  FOwnerships := AOwnerships;
end;

destructor TACLDictionary<TKey, TValue>.Destroy;
begin
  Clear;
  inherited;
end;

procedure TACLDictionary<TKey, TValue>.Add(const Key: TKey; const Value: TValue);
begin
  DoAdd(Key, Value, dupError);
end;

function TACLDictionary<TKey, TValue>.AddIfAbsent(const Key: TKey; const Value: TValue): Boolean;
begin
  Result := DoAdd(Key, Value, dupIgnore);
end;

procedure TACLDictionary<TKey, TValue>.AddOrSetValue(const Key: TKey; const Value: TValue);
begin
  DoAdd(Key, Value, dupAccept);
end;

procedure TACLDictionary<TKey, TValue>.Clear(AKeepCapacity: Boolean = False);
var
  AItem: PItem;
  I: Integer;
begin
  FCount := 0;

  for I := 0 to Length(FItems) - 1 do
  begin
    AItem := @FItems[I];
    if AItem^.HashCode <> EMPTY_HASH then
    begin
      AItem^.HashCode := EMPTY_HASH;

      KeyNotify(AItem^.Key, cnRemoved);
      AItem^.Key := Default(TKey);

      ValueNotify(AItem^.Value, cnRemoved);
      AItem^.Value := Default(TValue);
    end;
  end;

  if not AKeepCapacity then
  begin
    FGrowThreshold := 0;
    SetLength(FItems, 0);
    SetCapacity(0);
  end;
end;

function TACLDictionary<TKey, TValue>.ContainsKey(const Key: TKey): Boolean;
begin
  Result := GetBucketIndex(Key, Hash(Key)) >= 0;
end;

function TACLDictionary<TKey, TValue>.ContainsValue(const Value: TValue): Boolean;
var
  AComparer: IEqualityComparer<TValue>;
  I: Integer;
begin
  AComparer := TEqualityComparer<TValue>.Default;
  for I := 0 to Length(FItems) - 1 do
  begin
    if (FItems[I].HashCode <> EMPTY_HASH) and AComparer.Equals(FItems[I].Value, Value) then
      Exit(True);
  end;
  Result := False;
end;

procedure TACLDictionary<TKey, TValue>.Enum(const AProc: TACLPairEnum<TKey, TValue>);
var
  I: Integer;
begin
  for I := 0 to Length(FItems) - 1 do
  begin
    with FItems[I] do
      if HashCode <> EMPTY_HASH then
        AProc(Key, Value);
  end;
end;

procedure TACLDictionary<TKey, TValue>.Remove(const Key: TKey);
var
  AIndex: Integer;
begin
  AIndex := GetBucketIndex(Key, Hash(Key));
  if AIndex >= 0 then
    DoRemove(Key, AIndex, cnRemoved);
end;

procedure TACLDictionary<TKey, TValue>.TrimExcess;
begin
  SetCapacity(Count + 1); // Ensure at least one empty slot for GetBucketIndex to terminate.
end;

function TACLDictionary<TKey, TValue>.TryExtract(const Key: TKey; out Value: TValue): Boolean;
var
  AIndex: Integer;
begin
  AIndex := GetBucketIndex(Key, Hash(Key));
  Result := AIndex >= 0;
  if Result then
    Value := DoRemove(Key, AIndex, cnExtracted)
  else
    Value := Default(TValue);
end;

function TACLDictionary<TKey, TValue>.TryExtractFirst(out Key: TKey; out Value: TValue): Boolean;
var
  I: Integer;
begin
  for I := 0 to Length(FItems) - 1 do
  begin
    if FItems[I].HashCode <> EMPTY_HASH then
    begin
      Key := FItems[I].Key;
      Value := DoRemove(Key, I, cnExtracted);
      Exit(True);
    end;
  end;

  Key := Default(TKey);
  Value := Default(TValue);
  Result := False;
end;

function TACLDictionary<TKey, TValue>.TryGetValue(const Key: TKey; out Value: TValue): Boolean;
var
  AIndex: Integer;
begin
  AIndex := GetBucketIndex(Key, Hash(Key));
  Result := AIndex >= 0;
  if Result then
    Value := FItems[AIndex].Value
  else
    Value := Default(TValue);
end;

procedure TACLDictionary<TKey, TValue>.KeyNotify(const Key: TKey; Action: TCollectionNotification);
begin
  if Assigned(FOnKeyNotify) then
    FOnKeyNotify(Self, Key, Action);
  if (Action = cnRemoved) and (doOwnsKeys in FOwnerships) then
    PObject(@Key)^.DisposeOf;
end;

procedure TACLDictionary<TKey, TValue>.ValueNotify(const Value: TValue; Action: TCollectionNotification);
begin
  if Assigned(FOnValueNotify) then
    FOnValueNotify(Self, Value, Action);
  if (Action = cnRemoved) and (doOwnsValues in FOwnerships) then
    PObject(@Value)^.DisposeOf;
end;

procedure TACLDictionary<TKey, TValue>.DoAddCore(HashCode, Index: Integer; const Key: TKey; const Value: TValue);
begin
  FItems[Index].HashCode := HashCode;
  FItems[Index].Key := Key;
  FItems[Index].Value := Value;
  Inc(FCount);

  KeyNotify(Key, cnAdded);
  ValueNotify(Value, cnAdded);
end;

function TACLDictionary<TKey, TValue>.DoRemove(const Key: TKey; ABucketIndex: Integer; Notification: TCollectionNotification): TValue;
var
  AGap: Integer;
  AHashCode: Integer;
  AIndex: Integer;
begin
  if ABucketIndex < 0 then
    raise EListError.CreateRes(@SGenericItemNotFound);

  // Removing item from linear probe hash table is moderately
  // tricky. We need to fill in gaps, which will involve moving items
  // which may not even hash to the same location.
  // Knuth covers it well enough in Vol III. 6.4.; but beware, Algorithm R
  // (2nd ed) has a bug: step R4 should go to step R1, not R2 (already errata'd).
  // My version does linear probing forward, not backward, however.

  // gap refers to the hole that needs filling-in by shifting items down.
  // index searches for items that have been probed out of their slot,
  // but being careful not to move items if their bucket is between
  // our gap and our index (so that they'd be moved before their bucket).
  // We move the item at index into the gap, whereupon the new gap is
  // at the index. If the index hits a hole, then we're done.

  // If our load factor was exactly 1, we'll need to hit this hole
  // in order to terminate. Shouldn't normally be necessary, though.
  AIndex := ABucketIndex;
  FItems[AIndex].HashCode := EMPTY_HASH;
  Result := FItems[AIndex].Value;

  AGap := AIndex;
  while True do
  begin
    Inc(AIndex);
    if AIndex = Length(FItems) then
      AIndex := 0;

    AHashCode := FItems[AIndex].HashCode;
    if AHashCode = EMPTY_HASH then
      Break;

    if not InCircularRange(AGap, AHashCode and (Length(FItems) - 1), AIndex) then
    begin
      FItems[AGap] := FItems[AIndex];
      AGap := AIndex;
      // The gap moved, but we still need to find it to terminate.
      FItems[AGap].HashCode := EMPTY_HASH;
    end;
  end;

  FItems[AGap].HashCode := EMPTY_HASH;
  FItems[AGap].Key := Default(TKey);
  FItems[AGap].Value := Default(TValue);
  Dec(FCount);

  KeyNotify(Key, Notification);
  ValueNotify(Result, Notification);
end;

procedure TACLDictionary<TKey, TValue>.DoSetValue(Index: Integer; const Value: TValue);
var
  AOldValue: TValue;
begin
  AOldValue := FItems[Index].Value;
  FItems[Index].Value := Value;
  ValueNotify(AOldValue, cnRemoved);
  ValueNotify(Value, cnAdded);
end;

function TACLDictionary<TKey, TValue>.GetBucketIndex(const Key: TKey; HashCode: Integer): Integer;
var
  AHashCode: Integer;
begin
  if Length(FItems) = 0 then
    Exit(not High(Integer));

  Result := HashCode and (Length(FItems) - 1);
  while True do
  begin
    AHashCode := FItems[Result].HashCode;

    // Not found: return complement of insertion point.
    if AHashCode = EMPTY_HASH then
      Exit(not Result);

    // Found: return location.
    if (AHashCode = HashCode) and FComparer.Equals(FItems[Result].Key, Key) then
      Exit(Result);

    Inc(Result);
    if Result >= Length(FItems) then
      Result := 0;
  end;
end;

function TACLDictionary<TKey, TValue>.GetCapacity: Integer;
begin
  Result := Length(FItems);
end;

function TACLDictionary<TKey, TValue>.GetItem(const Key: TKey): TValue;
var
  AIndex: Integer;
begin
  AIndex := GetBucketIndex(Key, Hash(Key));
  if AIndex < 0 then
    raise EListError.CreateRes(@SGenericItemNotFound);
  Result := FItems[AIndex].Value;
end;

function TACLDictionary<TKey, TValue>.GetKeys: IACLEnumerable<TKey>;
begin
  Result := TKeyEnumerator.Create(Self);
end;

function TACLDictionary<TKey, TValue>.GetValues: IACLEnumerable<TValue>;
begin
  Result := TValueEnumerator.Create(Self);
end;

procedure TACLDictionary<TKey, TValue>.Grow;
begin
  Rehash(Max(Length(FItems) * 2, 4));
end;

function TACLDictionary<TKey, TValue>.Hash(const Key: TKey): Integer;
const
  PositiveMask = not Integer($80000000);
begin
  // Double-Abs to avoid -MaxInt and MinInt problems.
  // Not using compiler-Abs because we *must* get a positive integer;
  // for compiler, Abs(Low(Integer)) is a null op.
  Result := PositiveMask and ((PositiveMask and FComparer.GetHashCode(Key)) + 1);
end;

procedure TACLDictionary<TKey, TValue>.Rehash(ACapacity: Integer);
var
  ANewItems: TItemArray;
  AOldItems: TItemArray;
  I: Integer;
begin
  if ACapacity = Length(FItems) then
    Exit;
  if ACapacity < 0 then
    OutOfMemoryError;

  AOldItems := FItems;
  SetLength(ANewItems, ACapacity);
  for I := 0 to Length(ANewItems) - 1 do
    ANewItems[I].HashCode := EMPTY_HASH;
  FItems := ANewItems;
  FGrowThreshold := ACapacity shr 1 + ACapacity shr 2; // 75%

  for I := 0 to Length(AOldItems) - 1 do
  begin
    with AOldItems[I] do
      if HashCode <> EMPTY_HASH then
        RehashAdd(HashCode, Key, Value);
  end;
end;

procedure TACLDictionary<TKey, TValue>.RehashAdd(HashCode: Integer; const Key: TKey; const Value: TValue);
var
  AIndex: Integer;
begin
  AIndex := not GetBucketIndex(Key, HashCode);
  FItems[AIndex].HashCode := HashCode;
  FItems[AIndex].Key := Key;
  FItems[AIndex].Value := Value;
end;

function TACLDictionary<TKey, TValue>.DoAdd(const Key: TKey; const Value: TValue; ADuplicates: TDuplicates): Boolean;
var
  AHashCode: Integer;
  AIndex: Integer;
begin
  Result := True;
  if Count >= FGrowThreshold then
    Grow;

  AHashCode := Hash(Key);
  AIndex := GetBucketIndex(Key, AHashCode);
  if AIndex < 0 then
    DoAddCore(AHashCode, not AIndex, Key, Value)
  else
    case ADuplicates of
      dupAccept:
        DoSetValue(AIndex, Value);
      dupIgnore:
        Exit(False);
    else
      raise EListError.CreateRes(@SGenericDuplicateItem);
    end;
end;

function TACLDictionary<TKey, TValue>.GetEnumerator: IACLEnumerator<TPair<TKey, TValue>>;
begin
  Result := TPairEnumerator.Create(Self);
end;

procedure TACLDictionary<TKey, TValue>.SetCapacity(ACapacity: Integer);
var
  ANewCapacity: Integer;
begin
  if ACapacity < Count then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  if ACapacity = 0 then
    Rehash(0)
  else
  begin
    ANewCapacity := 4;
    while ANewCapacity < ACapacity do
      ANewCapacity := ANewCapacity shl 1;
    Rehash(ANewCapacity);
  end
end;

procedure TACLDictionary<TKey, TValue>.SetItem(const Key: TKey; const Value: TValue);
var
  AIndex: Integer;
  AOldValue: TValue;
begin
  AIndex := GetBucketIndex(Key, Hash(Key));
  if AIndex < 0 then
    raise EListError.CreateRes(@SGenericItemNotFound);

  AOldValue := FItems[AIndex].Value;
  FItems[AIndex].Value := Value;

  ValueNotify(AOldValue, cnRemoved);
  ValueNotify(Value, cnAdded);
end;

{ TACLDictionary<TKey, TValue>.TCustomEnumerator }

constructor TACLDictionary<TKey, TValue>.TCustomEnumerator.Create(AOwner: TACLDictionary<TKey, TValue>);
begin
  FOwner := AOwner;
  FIndex := -1;
end;

function TACLDictionary<TKey, TValue>.TCustomEnumerator.MoveNext: Boolean;
begin
  Result := False;
  repeat
    Inc(FIndex);
    if FIndex >= FOwner.Capacity then
      Exit(False);
    if FOwner.FItems[FIndex].HashCode <> FOwner.EMPTY_HASH then
      Exit(True);
  until False;
end;

{ TACLDictionary<TKey, TValue>.TPairEnumerator }

function TACLDictionary<TKey, TValue>.TPairEnumerator.GetCurrent: TPair<TKey, TValue>;
begin
  with FOwner.FItems[FIndex] do
    Result := TPair<TKey, TValue>.Create(Key, Value);
end;

{ TACLDictionary<TKey, TValue>.TKeyEnumerator }

function TACLDictionary<TKey, TValue>.TKeyEnumerator.GetCurrent: TKey;
begin
  Result := FOwner.FItems[FIndex].Key;
end;

function TACLDictionary<TKey, TValue>.TKeyEnumerator.GetEnumerator: IACLEnumerator<TKey>;
begin
  Result := Self;
end;

{ TACLDictionary<TKey, TValue>.TValueEnumerator }

function TACLDictionary<TKey, TValue>.TValueEnumerator.GetCurrent: TValue;
begin
  Result := FOwner.FItems[FIndex].Value;
end;

function TACLDictionary<TKey, TValue>.TValueEnumerator.GetEnumerator: IACLEnumerator<TValue>;
begin
  Result := Self;
end;

{ TACLThreadList<T> }

constructor TACLThreadList<T>.Create;
begin
  Create(TSimpleRWSync.Create);
end;

constructor TACLThreadList<T>.Create(ASync: IReadWriteSync);
begin
  FLock := ASync;
  FList := TACLList<T>.Create;
end;

constructor TACLThreadList<T>.CreateMultiReadExclusiveWrite;
begin
  Create(TMultiReadExclusiveWriteSynchronizer.Create);
end;

destructor TACLThreadList<T>.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TACLThreadList<T>.Add(const Value: T);
var
  AList: TACLList<T>;
begin
  AList := BeginWrite;
  try
    AList.Add(Value);
  finally
    EndWrite;
  end;
end;

procedure TACLThreadList<T>.Clear;
var
  AList: TACLList<T>;
begin
  AList := BeginWrite;
  try
    AList.Clear;
  finally
    EndWrite;
  end;
end;

function TACLThreadList<T>.Contains(const Value: T): Boolean;
var
  AList: TACLList<T>;
begin
  AList := BeginRead;
  try
    Result := AList.Contains(Value);
  finally
    EndRead;
  end;
end;

function TACLThreadList<T>.Count: Integer;
begin
  Result := FList.Count;
end;

procedure TACLThreadList<T>.Enum(AProc: TEnumProc);
var
  AList: TACLList<T>;
  I: Integer;
begin
  AList := BeginRead;
  try
    for I := 0 to AList.Count - 1 do
      AProc(AList.List[I]);
  finally
    EndRead;
  end;
end;

function TACLThreadList<T>.Read(AIndex: Integer; out AValue: T): Boolean;
var
  AList: TACLList<T>;
  I: Integer;
begin
  AList := BeginRead;
  try
    Result := (AIndex >= 0) and (AIndex < AList.Count);
    if Result then
      AValue := AList.List[AIndex];
  finally
    EndRead;
  end;
end;

procedure TACLThreadList<T>.Remove(const Value: T);
var
  AList: TACLList<T>;
begin
  AList := BeginWrite;
  try
    AList.Remove(Value);
  finally
    EndWrite;
  end;
end;

function TACLThreadList<T>.BeginRead: TACLList<T>;
begin
  FLock.BeginRead;
  Result := FList;
end;

function TACLThreadList<T>.BeginWrite: TACLList<T>;
begin
  FLock.BeginWrite;
  Result := FList;
end;

procedure TACLThreadList<T>.EndRead;
begin
  FLock.EndRead;
end;

procedure TACLThreadList<T>.EndWrite;
begin
  FLock.EndWrite;
end;

function TACLThreadList<T>.LockList: TACLList<T>;
begin
  Result := BeginWrite;
end;

procedure TACLThreadList<T>.UnlockList;
begin
  EndWrite;
end;

{ TACLListenerList }

constructor TACLListenerList.Create(AInitialCapacity: Integer = 0);
begin
  inherited Create;
  FData := TACLInterfaceList.Create;
  FData.OnNotify := ChangeHandler;
  if AInitialCapacity > 0 then
    FData.Capacity := AInitialCapacity;
  FLock := TACLCriticalSection.Create(Self);
end;

destructor TACLListenerList.Destroy;
begin
  FData.OnNotify := nil;
  FreeAndNil(FLock);
  FreeAndNil(FData);
  inherited Destroy;
end;

procedure TACLListenerList.Add(const AListener: IInterface);
begin
  Lock.Enter;
  try
    FData.Add(AListener);
  finally
    Lock.Leave;
  end;
end;

procedure TACLListenerList.Clear;
begin
  Lock.Enter;
  try
    if Count > 0 then
    begin
      FData.OnNotify := nil;
      FData.Clear;
      FData.OnNotify := ChangeHandler;
      Changed;
    end;
  finally
    Lock.Leave;
  end;
end;

function TACLListenerList.Contains(const IID: TGUID): Boolean;
var
  I: Integer;
begin
  Lock.Enter;
  try
    for I := 0 to FData.Count - 1 do
    begin
      if Supports(FData.List[I], IID) then
        Exit(True);
    end;
    Result := False;
  finally
    Lock.Leave;
  end;
end;

procedure TACLListenerList.Enum(AProc: TACLListenerListEnumProc<IUnknown>);
begin
  Enum<IUnknown>(AProc);
end;

procedure TACLListenerList.Enum<T>(AProc: TACLListenerListEnumProc<T>);
var
  AEnumerable: IUnknown;
  AGuid: TGUID;
  AGuidAssigned: Boolean;
  AIndex: Integer;
  AIntf: T;
begin
  Lock.Enter;
  try
    AEnumerable := FEnumerable; // recursive call
    try
      AIndex := 0;
      AGuid := TACLInterfaceHelper<T>.GetGUID;
      AGuidAssigned := AGuid <> IUnknown;
      while AIndex < FData.Count do
      begin
        FEnumerable := FData.List[AIndex];
        if AGuidAssigned then
        begin
          if Supports(FEnumerable, AGuid, AIntf) then
            AProc(AIntf);
        end
        else
          AProc(FEnumerable);

        if FEnumerable <> nil then
          Inc(AIndex);
      end;
    finally
      FEnumerable := AEnumerable;
    end;
  finally
    Lock.Leave;
  end;
end;

function TACLListenerList.GetCount: Integer;
begin
  Result := FData.Count;
end;

procedure TACLListenerList.Remove(const AListener: IInterface);
begin
  if Self <> nil then
  begin
    Lock.Enter;
    try
      if AListener = FEnumerable then
        FEnumerable := nil;
      FData.Remove(AListener);
    finally
      Lock.Leave;
    end;
  end;
end;

procedure TACLListenerList.Changed;
begin
  CallNotifyEvent(Self, OnChange);
end;

procedure TACLListenerList.ChangeHandler(Sender: TObject; const Item: IInterface; Action: TCollectionNotification);
begin
  Changed;
end;

{ TACLObjectList }

constructor TACLObjectList.Create(AOwnsObjects: Boolean = True);
begin
  inherited Create;
  FOwnsObjects := AOwnsObjects;
end;

function TACLObjectList.Add(AObject: TObject): Integer;
begin
  Result := inherited Add(AObject);
end;

function TACLObjectList.Extract(AIndex: Integer): TObject;
begin
  Result := nil;
  if IsValid(AIndex) then
  begin
    Result := Items[AIndex];
    List[AIndex] := nil;
    Delete(AIndex);
    Notify(Result, lnExtracted);
  end;
end;

function TACLObjectList.Extract(AItem: TObject): TObject;
begin
  Result := Extract(IndexOf(AItem));
end;

function TACLObjectList.First: TObject;
begin
  Result := TObject(inherited First);
end;

function TACLObjectList.GetItem(Index: Integer): TObject;
begin
  Result := TObject(inherited Items[Index]);
end;

procedure TACLObjectList.Insert(Index: Integer; AObject: TObject);
begin
  inherited Insert(Index, AObject);
end;

function TACLObjectList.Last: TObject;
begin
  Result := TObject(inherited Last);
end;

procedure TACLObjectList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if (Action = lnDeleted) and (OwnsObjects and Assigned(Ptr)) then
    TObject(Ptr).Free;
  inherited Notify(Ptr, Action);
end;

function TACLObjectList.Remove(AObject: TObject): Integer;
begin
  Result := inherited Remove(AObject);
end;

procedure TACLObjectList.SetItem(Index: Integer; AObject: TObject);
begin
  inherited Items[Index] := AObject;
end;

{ TACLObjectList<T> }

constructor TACLObjectList<T>.Create(AOwnsObjects: Boolean);
begin
  inherited Create;
  OwnsObjects := AOwnsObjects;
end;

constructor TACLObjectList<T>.Create(const AComparer: IComparer<T>; AOwnsObjects: Boolean);
begin
  inherited Create(AComparer);
  OwnsObjects := AOwnsObjects;
end;

procedure TACLObjectList<T>.Notify(const Item: T; Action: TCollectionNotification);
begin
  inherited Notify(Item, Action);
  if (Action = cnRemoved) and OwnsObjects then
    Item.Free;
end;

procedure TACLObjectList<T>.UpdateNotificationFlag;
begin
  FNotifications := Assigned(OnNotify) or OwnsObjects;
end;

procedure TACLObjectList<T>.SetOwnObjects(const Value: Boolean);
begin
  FOwnsObjects := Value;
  UpdateNotificationFlag;
end;

{ TACLClassMap<T> }

constructor TACLClassMap<T>.Create;
begin
  FData := TACLDictionary<TClass, T>.Create;
end;

destructor TACLClassMap<T>.Destroy;
begin
  FreeAndNil(FData);
  inherited Destroy;
end;

procedure TACLClassMap<T>.Add(const AClass: TClass; const AValue: T);
begin
  FData.Add(AClass, AValue);
end;

procedure TACLClassMap<T>.AddOrSetValue(const AClass: TClass; const AValue: T);
begin
  FData.AddOrSetValue(AClass, AValue);
end;

procedure TACLClassMap<T>.Remove(const AClass: TClass);
//var
//  AIndex: Integer;
//  ASuccessors: TArray<TClass>;
begin
  FData.Remove(AClass);
//  if ARemoveSuccessors and (AClass <> nil) then
//  begin
//    ASuccessors := FData.Keys.ToArray;
//    for AIndex := 0 to Length(ASuccessors) - 1 do
//    begin
//      if ASuccessors[AIndex].InheritsFrom(AClass) then
//        FData.Remove(ASuccessors[AIndex]);
//    end;
//  end;
end;

function TACLClassMap<T>.TryGetValue(AObject: TObject; out AValue: T): Boolean;
begin
  if AObject <> nil then
    Result := TryGetValue(AObject.ClassType, AValue)
  else
    Result := TryGetValue(nil, AValue);
end;

function TACLClassMap<T>.TryGetValue(AClass: TClass; out AValue: T): Boolean;
begin
  repeat
    Result := FData.TryGetValue(AClass, AValue);
    if AClass <> nil then
      AClass := AClass.ClassParent;
  until Result or (AClass = nil);
end;

function TACLClassMap<T>.GetItem(AClass: TClass): T;
begin
  if not TryGetValue(AClass, Result) then
    raise Exception.CreateFmt('Value for the %s class was not found', [AClass.ClassName]);
end;

{ TACLMap<TKey, TValue> }

constructor TACLMap<TKey, TValue>.Create(AComparerKey: IEqualityComparer<TKey>;
  AComparerValue: IEqualityComparer<TValue>; AOwnerships: TDictionaryOwnerships; ACapacity: Integer);
begin
  FValueToKey := TACLDictionary<TValue, TKey>.Create(ACapacity, AComparerValue);
  FKeyToValue := TACLDictionary<TKey, TValue>.Create(AOwnerships, ACapacity, AComparerKey);
end;

constructor TACLMap<TKey, TValue>.Create(ACapacity: Integer; AOwnerships: TDictionaryOwnerships);
begin
  Create(nil, nil, AOwnerships, ACapacity);
end;

constructor TACLMap<TKey, TValue>.Create(AOwnerships: TDictionaryOwnerships);
begin
  Create(nil, nil, AOwnerships);
end;

destructor TACLMap<TKey, TValue>.Destroy;
begin
  Clear;
  FreeAndNil(FKeyToValue);
  FreeAndNil(FValueToKey);
  inherited Destroy;
end;

procedure TACLMap<TKey, TValue>.Add(const AKey: TKey; const AValue: TValue);
begin
  try
    FKeyToValue.Add(AKey, AValue);
    FValueToKey.Add(AValue, AKey);
  except
    FValueToKey.Remove(AValue);
    FKeyToValue.Remove(AKey);
    raise;
  end;
end;

procedure TACLMap<TKey, TValue>.Clear;
begin
  if FKeyToValue <> nil then
    FKeyToValue.Clear;
  if FValueToKey <> nil then
    FValueToKey.Clear;
end;

procedure TACLMap<TKey, TValue>.DeleteByKey(const AKey: TKey);
var
  AValue: TValue;
begin
  if FKeyToValue.TryExtract(AKey, AValue) then
  begin
    FValueToKey.Remove(AValue);
    FKeyToValue.KeyNotify(AKey, cnRemoved);
  end;
end;

procedure TACLMap<TKey, TValue>.DeleteByValue(const AValue: TValue);
var
  AKey: TKey;
begin
  if FValueToKey.TryExtract(AValue, AKey) then
  begin
    FKeyToValue.Remove(AKey);
    FValueToKey.KeyNotify(AValue, cnRemoved);
  end;
end;

procedure TACLMap<TKey, TValue>.Enum(AProc: TACLPairEnum<TKey, TValue>);
begin
  FKeyToValue.Enum(AProc);
end;

function TACLMap<TKey, TValue>.GetKey(const AValue: TValue): TKey;
begin
  if not TryGetKey(AValue, Result) then
    raise Exception.Create(sErrorValueWasNotFoundInMap);
end;

function TACLMap<TKey, TValue>.TryGetKey(const AValue: TValue; out AKey: TKey): Boolean;
begin
  Result := FValueToKey.TryGetValue(AValue, AKey);
end;

function TACLMap<TKey, TValue>.GetValue(const AKey: TKey): TValue;
begin
  if not TryGetValue(AKey, Result) then
    raise Exception.Create(sErrorValueWasNotFoundInMap);
end;

function TACLMap<TKey, TValue>.TryGetValue(const AKey: TKey; out AValue: TValue): Boolean;
begin
  Result := FKeyToValue.TryGetValue(AKey, AValue);
end;

{ TACLCustomHashSet<T> }

function TACLCustomHashSet<T>.Exclude(const ItemSet: TACLCustomHashSet<T>; AutoFree: Boolean): Boolean;
var
  AItem: T;
begin
  Result := False;
  for AItem in ItemSet do
    Result := Exclude(AItem) or Result;
  if AutoFree then
    ItemSet.Free;
end;

function TACLCustomHashSet<T>.Include(const ItemSet: TACLCustomHashSet<T>; AutoFree: Boolean): Boolean;
var
  AItem: T;
begin
  Result := False;
  for AItem in ItemSet do
    Result := Include(AItem) or Result;
  if AutoFree then
    ItemSet.Free;
end;

function TACLCustomHashSet<T>.ToArray: TArray<T>;
var
  AIndex: Integer;
  AValue: T;
begin
  AIndex := 0;
  SetLength(Result, Count);
  for AValue in Self do
  begin
    Result[AIndex] := AValue;
    Inc(AIndex);
  end;
end;

{ TACLHashSet<T> }

constructor TACLHashSet<T>.Create(AInitialCapacity: Integer = 0);
begin
  Create(nil, AInitialCapacity);
end;

constructor TACLHashSet<T>.Create(const AComparer: IEqualityComparer<T>; AInitialCapacity: Integer = 0);
begin
  FComparer := AComparer;
  if FComparer = nil then
    FComparer := TEqualityComparer<T>.Default;
  SetCapacity(AInitialCapacity);
end;

destructor TACLHashSet<T>.Destroy;
begin
  Clear;
  inherited;
end;

procedure TACLHashSet<T>.Clear;
begin
  FCount := 0;
  FGrowThreshold := 0;
  SetLength(FItems, 0);
  SetCapacity(0);
end;

function TACLHashSet<T>.Contains(const Item: T): Boolean;
begin
  Result := GetBucketIndex(Item, Hash(Item)) >= 0;
end;

function TACLHashSet<T>.Exclude(const Item: T): Boolean;
var
  AIndex: Integer;
begin
  AIndex := GetBucketIndex(Item, Hash(Item));
  Result := AIndex >= 0;
  if Result then
    DoRemove(AIndex);
end;

function TACLHashSet<T>.Include(const Item: T): Boolean;
var
  AHashCode: Integer;
  AIndex: Integer;
begin
  if Count >= FGrowThreshold then
    DoGrow;
  AHashCode := Hash(Item);
  AIndex := GetBucketIndex(Item, AHashCode);
  Result := AIndex < 0;
  if Result then
    DoAdd(AHashCode, not AIndex, Item);
end;

function TACLHashSet<T>.GetEnumerator: IACLEnumerator<T>;
begin
  Result := TEnumerator.Create(Self);
end;

procedure TACLHashSet<T>.SetCapacity(AValue: Integer);
var
  ANewCapacity: Integer;
begin
  if AValue < Count then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  ANewCapacity := 0;
  if AValue > 0 then
  begin
    ANewCapacity := 4;
    while ANewCapacity < AValue do
      ANewCapacity := ANewCapacity shl 1;
  end;
  DoRehash(ANewCapacity);
end;

procedure TACLHashSet<T>.DoAdd(HashCode, Index: Integer; const Item: T);
begin
  FItems[Index].HashCode := HashCode;
  FItems[Index].Item := Item;
  Inc(FCount);
end;

procedure TACLHashSet<T>.DoGrow;
begin
  DoRehash(Max(Length(FItems) * 2, 4));
end;

procedure TACLHashSet<T>.DoRehash(ACapacity: Integer);
var
  ANewItems: TItemArray;
  AOldItems: TItemArray;
  I: Integer;
begin
  if ACapacity = Length(FItems) then
    Exit;
  if ACapacity < 0 then
    OutOfMemoryError;

  AOldItems := FItems;
  SetLength(ANewItems, ACapacity);
  for I := 0 to Length(ANewItems) - 1 do
    ANewItems[I].HashCode := EMPTY_HASH;
  FItems := ANewItems;
  FGrowThreshold := ACapacity shr 1 + ACapacity shr 2; // 75%

  for I := 0 to Length(AOldItems) - 1 do
  begin
    with AOldItems[I] do
      if HashCode <> EMPTY_HASH then
        DoRehashAdd(HashCode, Item);
  end;
end;

procedure TACLHashSet<T>.DoRehashAdd(HashCode: Integer; const Item: T);
var
  AIndex: Integer;
begin
  AIndex := not GetBucketIndex(Item, HashCode);
  FItems[AIndex].HashCode := HashCode;
  FItems[AIndex].Item := Item;
end;

procedure TACLHashSet<T>.DoRemove(ABucketIndex: Integer);
var
  AGap: Integer;
  AHashCode: Integer;
  AIndex: Integer;
begin
  if ABucketIndex < 0 then
    raise EListError.CreateRes(@SGenericItemNotFound);

  AIndex := ABucketIndex;
  FItems[AIndex].HashCode := EMPTY_HASH;

  AGap := AIndex;
  while True do
  begin
    Inc(AIndex);
    if AIndex = Length(FItems) then
      AIndex := 0;

    AHashCode := FItems[AIndex].HashCode;
    if AHashCode = EMPTY_HASH then
      Break;

    if not InCircularRange(AGap, AHashCode and (Length(FItems) - 1), AIndex) then
    begin
      FItems[AGap] := FItems[AIndex];
      AGap := AIndex;
      // The gap moved, but we still need to find it to terminate.
      FItems[AGap].HashCode := EMPTY_HASH;
    end;
  end;

  FItems[AGap].HashCode := EMPTY_HASH;
  FItems[AGap].Item := Default(T);
  Dec(FCount);
end;

function TACLHashSet<T>.GetBucketIndex(const Item: T; HashCode: Integer): Integer;
var
  AHashCode: Integer;
begin
  if Length(FItems) = 0 then
    Exit(not High(Integer));

  Result := HashCode and (Length(FItems) - 1);
  while True do
  begin
    AHashCode := FItems[Result].HashCode;

    // Not found: return complement of insertion point.
    if AHashCode = EMPTY_HASH then
      Exit(not Result);

    // Found: return location.
    if (AHashCode = HashCode) and FComparer.Equals(FItems[Result].Item, Item) then
      Exit(Result);

    Inc(Result);
    if Result >= Length(FItems) then
      Result := 0;
  end;
end;

function TACLHashSet<T>.GetCount: Integer;
begin
  Result := FCount;
end;

function TACLHashSet<T>.Hash(const Item: T): Integer;
const
  PositiveMask = not Integer($80000000);
begin
  // Double-Abs to avoid -MaxInt and MinInt problems.
  // Not using compiler-Abs because we *must* get a positive integer;
  // for compiler, Abs(Low(Integer)) is a null op.
  Result := PositiveMask and ((PositiveMask and FComparer.GetHashCode(Item)) + 1);
end;

{ TACLHashSet<T>.TEnumerator }

constructor TACLHashSet<T>.TEnumerator.Create(AOwner: TACLHashSet<T>);
begin
  FOwner := AOwner;
  FIndex := -1;
end;

function TACLHashSet<T>.TEnumerator.GetCurrent: T;
begin
  Result := FOwner.FItems[FIndex].Item;
end;

function TACLHashSet<T>.TEnumerator.MoveNext: Boolean;
begin
  Result := False;
  repeat
    Inc(FIndex);
    if FIndex >= Length(FOwner.FItems) then
      Exit(False);
    if FOwner.FItems[FIndex].HashCode <> FOwner.EMPTY_HASH then
      Exit(True);
  until False;
end;

//{ TACLStringSet }
//
//constructor TACLStringSet.Create(const IgnoreCase: Boolean; InitialCapacity: Integer = 0);
//begin
//  inherited Create;
//  FIgnoreCase := IgnoreCase;
//  FData := TACLList<string>.Create;
//  FData.Capacity := InitialCapacity;
//end;
//
//destructor TACLStringSet.Destroy;
//begin
//  FreeAndNil(FData);
//  inherited;
//end;
//
//function TACLStringSet.DoGetEnumerator: TEnumerator<string>;
//begin
//  Result := FData.GetEnumerator;
//end;
//
//function TACLStringSet.Contains(const Item: string): Boolean;
//begin
//  Result := Contains(PWideChar(Item), Length(Item));
//end;
//
//procedure TACLStringSet.Clear;
//begin
//  FData.Clear;
//end;
//
//function TACLStringSet.Contains(const Item: PWideChar; const ItemLength: Integer): Boolean;
//var
//  AIndex: Integer;
//begin
//  Result := FindCore(Item, ItemLength, AIndex);
//end;
//
//function TACLStringSet.Exclude(const Item: PWideChar; const ItemLength: Integer): Boolean;
//var
//  AIndex: Integer;
//begin
//  Result := FindCore(Item, ItemLength, AIndex);
//  if Result then
//    FData.Delete(AIndex);
//end;
//
//function TACLStringSet.Exclude(const Item: string): Boolean;
//begin
//  Result := Exclude(PWideChar(Item), Length(Item));
//end;
//
//function TACLStringSet.Include(const Item: string): Boolean;
//begin
//  Result := IncludeCore(PWideChar(Item), Length(Item), @Item);
//end;
//
//function TACLStringSet.Include(const Item: PWideChar; const ItemLength: Integer): Boolean;
//begin
//  Result := IncludeCore(Item, ItemLength, nil);
//end;
//
//function TACLStringSet.Include(const Items: TACLStringSet; AAutoFree: Boolean): Boolean;
//var
//  I: Integer;
//begin
//  Result := False;
//  if Items <> nil then
//  try
//    for I := 0 to Items.FData.Count - 1 do
//      Result := Include(Items.FData.List[I]) or Result;
//  finally
//    if AAutoFree then
//      Items.Free;
//  end;
//end;
//
//function TACLStringSet.ToArray: TArray<string>;
//begin
//  Result := FData.ToArray;
//end;
//
//function TACLStringSet.FindCore(const Item: PWideChar; const ItemLength: Integer; out Index: Integer): Boolean;
//var
//  L, H, I, C: Integer;
//  S: UnicodeString;
//begin
//  Result := False;
//  L := 0;
//  H := FData.Count - 1;
//  while L <= H do
//  begin
//    I := (L + H) shr 1;
//    S := FData.List[I];
//    C := Length(S) - ItemLength;
//    if C = 0 then
//    begin
//      if FIgnoreCase then
//        C := acCompareStrings(PWideChar(S), Item, ItemLength, ItemLength)
//      else
//        C := BinaryCompare(PWideChar(S), Item, ItemLength * SizeOf(WideChar));
//    end;
//    if C < 0 then
//      L := I + 1
//    else
//    begin
//      H := I - 1;
//      if C = 0 then
//      begin
//        Result := True;
//        L := I;
//        Break;
//      end;
//    end;
//  end;
//  Index := L;
//end;
//
//function TACLStringSet.GetCount: Integer;
//begin
//  Result := FData.Count;
//end;
//
//function TACLStringSet.IncludeCore(const Item: PWideChar; const ItemLength: Integer; B: PUnicodeString): Boolean;
//var
//  AIndex: Integer;
//begin
//  Result := not FindCore(Item, ItemLength, AIndex);
//  if Result then
//  begin
//    if B <> nil then
//      FData.Insert(AIndex, B^)
//    else
//      FData.Insert(AIndex, acMakeString(Item, ItemLength));
//  end;
//end;

{ TACLStringSet }

constructor TACLStringSet.Create(const IgnoreCase: Boolean; InitialCapacity: Integer);
begin
  if IgnoreCase then
    inherited Create(TACLStringComparer.Create, InitialCapacity)
  else
    inherited Create(TStringComparer.Ordinal, InitialCapacity);
end;

function TACLStringSet.Contains(const Item: PWideChar; const ItemLength: Integer): Boolean;
begin
  Result := Contains(acMakeString(Item, ItemLength));
end;

function TACLStringSet.Exclude(const Item: PWideChar; const ItemLength: Integer): Boolean;
begin
  Result := Exclude(acMakeString(Item, ItemLength));
end;

function TACLStringSet.Include(const Item: PWideChar; const ItemLength: Integer): Boolean;
begin
  Result := Include(acMakeString(Item, ItemLength));
end;

{ TACLStringComparer }

constructor TACLStringComparer.Create(IgnoreCase: Boolean = True);
begin
  inherited Create;
  FIgnoreCase := IgnoreCase;
end;

function TACLStringComparer.Compare(const Left, Right: string): Integer;
begin
  Result := acCompareStrings(Left, Right, FIgnoreCase)
end;

function TACLStringComparer.Equals(const Left, Right: string): Boolean;
var
  L1, L2: Integer;
begin
  L1 := Length(Left);
  L2 := Length(Right);
  if L1 <> L2 then
    Result := False
  else
    if FIgnoreCase then
      Result := acCompareStrings(PChar(Left), PChar(Right), L1, L2, True) = 0
    else
      Result := CompareMem(PChar(Left), PChar(Right), L1 * SizeOf(Char));
end;

function TACLStringComparer.GetHashCode(const Value: string): Integer;
begin
  if FIgnoreCase then
    Result := TACLHashBobJenkins.Calculate(acUpperCase(Value), nil)
  else
    Result := TACLHashBobJenkins.Calculate(Value, nil);
end;

{ TACLStringSharedTable }

constructor TACLStringSharedTable.Create;
begin
  inherited Create;
  FTableSize := Word.MaxValue;
  SetLength(FTable, FTableSize);
end;

destructor TACLStringSharedTable.Destroy;
begin
  Clear;
  SetLength(FTable, 0);
  inherited Destroy;
end;

procedure TACLStringSharedTable.Clear;
var
  AItem: TItem;
  ATempItem: TItem;
  I: Integer;
begin
  for I := 0 to FTableSize - 1 do
  begin
    AItem := FTable[I];
    FTable[I] := nil;
    while AItem <> nil do
    begin
      ATempItem := AItem;
      AItem := AItem.Next;
      ATempItem.Free;
    end;
  end;
end;

function TACLStringSharedTable.Share(const P: PWideChar; const L: Integer): UnicodeString;
begin
  Result := Share(P, L, nil);
end;

function TACLStringSharedTable.Share(const U: UnicodeString): UnicodeString;
begin
  Result := Share(PWideChar(U), Length(U), @U);
end;

function TACLStringSharedTable.Share(P: PWideChar; L: Integer; B: PUnicodeString): UnicodeString;
var
  AIndex: Integer;
  AItem: TItem;
  AHash: Cardinal;
begin
  AHash := Cardinal(TACLHashBobJenkins.Calculate(PByte(P), L * SizeOf(WideChar)));
  AIndex := AHash mod FTableSize;
  AItem := FTable[AIndex];
  if AItem = nil then
  begin
    AItem := TItem.Create(AHash, P, L, B);
    FTable[AIndex] := AItem;
  end
  else
    repeat
      if (AItem.ValueHash = AHash) and (Length(AItem.Value) = L) then
      begin
        if CompareMem(PWideChar(AItem.Value), P, L * SizeOf(WideChar)) then
          Break;
      end;

      if AItem.Next = nil then
      begin
        AItem.Next := TItem.Create(AHash, P, L, B);
        AItem := AItem.Next;
        Break;
      end;
      AItem := AItem.Next;
    until False;

  Result := AItem.Value;
end;

{ TACLStringSharedTable.TItem }

constructor TACLStringSharedTable.TItem.Create(Hash: Cardinal; P: PWideChar; L: Cardinal; B: PUnicodeString);
begin
  ValueHash := Hash;
  if B <> nil then
    Value := B^
  else
    SetString(Value, P, L);
end;

{ TACLOrderedDictionary<TKey, TValue> }

procedure TACLOrderedDictionary<TKey, TValue>.AfterConstruction;
begin
  inherited;
  FOrder := TACLList<TKey>.Create;
  FOrder.Capacity := Capacity;
end;

destructor TACLOrderedDictionary<TKey, TValue>.Destroy;
begin
  FreeAndNil(FOrder);
  inherited;
end;

procedure TACLOrderedDictionary<TKey, TValue>.Clear(AKeepCapacity: Boolean = False);
begin
  if AKeepCapacity then
    FOrder.Count := 0
  else
    FOrder.Clear;

  inherited;
end;

procedure TACLOrderedDictionary<TKey, TValue>.Enum(const AProc: TACLPairEnum<TKey, TValue>);
var
  AKey: TKey;
  I: Integer;
begin
  for I := 0 to FOrder.Count - 1 do
  begin
    AKey := FOrder.List[I];
    AProc(AKey, Items[AKey]);
  end;
end;

procedure TACLOrderedDictionary<TKey, TValue>.KeyNotify(const Key: TKey; Action: TCollectionNotification);
begin
  case Action of
    cnAdded:
      FOrder.Add(Key);
    cnRemoved, cnExtracted:
      FOrder.Remove(Key);
  end;
  inherited;
end;

procedure TACLOrderedDictionary<TKey, TValue>.SetCapacity(AValue: Integer);
begin
  if FOrder <> nil then
    FOrder.Capacity := AValue;
  inherited;
end;

function TACLOrderedDictionary<TKey, TValue>.GetEnumerator: IACLEnumerator<TPair<TKey, TValue>>;
begin
  Result := TPairEnumerator.Create(Self);
end;

function TACLOrderedDictionary<TKey, TValue>.GetKey(Index: Integer): TKey;
begin
  Result := FOrder.List[Index];
end;

function TACLOrderedDictionary<TKey, TValue>.GetKeys: IACLEnumerable<TKey>;
begin
  Result := FOrder;
end;

function TACLOrderedDictionary<TKey, TValue>.GetValues: IACLEnumerable<TValue>;
begin
  Result := TValueEnumerator.Create(Self);
end;

{ TACLOrderedDictionary<TKey, TValue>.TEnumerator }

constructor TACLOrderedDictionary<TKey, TValue>.TEnumerator.Create(AOwner: TACLOrderedDictionary<TKey, TValue>);
begin
  FOwner := AOwner;
  FIndex := -1;
end;

function TACLOrderedDictionary<TKey, TValue>.TEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FOwner.FOrder.Count;
end;

{ TACLOrderedDictionary<TKey, TValue>.TEnumerator }

function TACLOrderedDictionary<TKey, TValue>.TPairEnumerator.GetCurrent: TPair<TKey, TValue>;
var
  AKey: TKey;
begin
  AKey := FOwner.FOrder.List[FIndex];
  Result := TPair<TKey, TValue>.Create(AKey, FOwner.Items[AKey]);
end;

{ TACLOrderedDictionary<TKey, TValue>.TValueEnumerator }

function TACLOrderedDictionary<TKey, TValue>.TValueEnumerator.GetCurrent: TValue;
begin
  Result := FOwner.Items[FOwner.FOrder.List[FIndex]];
end;

function TACLOrderedDictionary<TKey, TValue>.TValueEnumerator.GetEnumerator: IACLEnumerator<TValue>;
begin
  Result := Self;
end;

{ TACLValueCacheManager<TKey, TValue> }

constructor TACLValueCacheManager<TKey, TValue>.Create(ACapacity: Integer);
begin
  Create(ACapacity, nil);
end;

constructor TACLValueCacheManager<TKey, TValue>.Create(
  ACapacity: Integer; AEqualityComparer: IEqualityComparer<TKey>);
begin
  FCapacity := ACapacity;
  FData := TACLDictionary<TKey, TValue>.Create(ACapacity, AEqualityComparer);
  FData.OnValueNotify := ValueHandler;
  SetLength(FQueue, FCapacity);
  FQueueCursor := 0;
end;

destructor TACLValueCacheManager<TKey, TValue>.Destroy;
begin
  FreeAndNil(FData);
  inherited;
end;

procedure TACLValueCacheManager<TKey, TValue>.Add(const Key: TKey; const Value: TValue);
var
  AQueueItem: PQueueItem;
begin
  AQueueItem := @FQueue[FQueueCursor];

  if AQueueItem^.Value then
  begin
    FData.Remove(AQueueItem^.Key);
    AQueueItem^.Key := Default(TKey);
    AQueueItem^.Value := False;
  end;

  FData.Add(Key, Value);
  AQueueItem^.Key := Key;
  AQueueItem^.Value := True;

  FQueueCursor := (FQueueCursor + 1) mod FCapacity;
end;

procedure TACLValueCacheManager<TKey, TValue>.Clear;
var
  I: Integer;
begin
  FData.Clear(True);
  for I := 0 to Length(FQueue) - 1 do
    FQueue[I].Value := False;
  FQueueCursor := 0;
end;

function TACLValueCacheManager<TKey, TValue>.Get(const Key: TKey; out Value: TValue): Boolean;
begin
  Result := FData.TryGetValue(Key, Value);
end;

procedure TACLValueCacheManager<TKey, TValue>.Remove(const Key: TKey);
var
  AQueueItem: PQueueItem;
  I: Integer;
begin
  for I := 0 to Length(FQueue) - 1 do
  begin
    AQueueItem := @FQueue[I];
    if AQueueItem^.Value and FComparer.Equals(AQueueItem^.Key, Key) then
    begin
      FData.Remove(AQueueItem^.Key);
      AQueueItem^.Key := Default(TKey);
      AQueueItem^.Value := False;
      Break;
    end;
  end;
end;

procedure TACLValueCacheManager<TKey, TValue>.DoRemove(const Item: TValue);
begin
  if Assigned(OnRemove) then
    OnRemove(Self, Item);
end;

procedure TACLValueCacheManager<TKey, TValue>.ValueHandler(
  Sender: TObject; const Item: TValue; Action: TCollectionNotification);
begin
  if Action = cnRemoved then
    DoRemove(Item);
end;

{ TACLFloatList }

function TACLFloatList.Contains(const Value, Tolerance: Single): Boolean;
begin
  Result := IndexOf(Value, Tolerance) >= 0;
end;

function TACLFloatList.IndexOf(const Value, Tolerance: Single): Integer;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if FastAbs(List[I] - Value) < Tolerance then
      Exit(I);
  end;
  Result := -1;
end;

end.
