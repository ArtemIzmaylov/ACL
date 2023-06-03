
{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*              Styles Support               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Resources;

{$I ACL.Config.inc}
{$R *.res}

interface

uses
  Winapi.Windows,
  // System
  System.UITypes,
  System.Types,
  System.Variants,
  System.Classes,
  System.Generics.Defaults,
  System.Generics.Collections,
  // VCL
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.Ex.Gdip,
  ACL.Graphics.FontCache,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.ObjectLinks,
  ACL.UI.Application,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.RTTI;

type
  TACLGlyph = class;
  TACLResource = class;
  TACLCustomResourceCollection = class;

  { IACLResourceChangeListener }

  IACLResourceChangeListener = interface
  ['{CE4647B5-37FB-4955-B51C-9397D35C4201}']
    procedure ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
  end;

  { IACLResourceCollection }

  IACLResourceCollection = interface
  ['{47DA9266-349E-4294-A963-D16C8A6CF8FC}']
    function GetCollection: TACLCustomResourceCollection;
  end;

  { IACLResourceCollectionSetter }

  IACLResourceCollectionSetter = interface
  ['{ED1CCFB7-371C-44A3-97DF-E7796122262C}']
    procedure SetCollection(const AValue: TACLCustomResourceCollection);
  end;

  { IACLResourceProvider }

  IACLResourceProvider = interface
  ['{CBBB0C1E-E002-4BB3-8BCC-9F0144928E43}']
    function GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
  end;

  { IACLResourceChangeNotifier }

  IACLResourceChangeNotifier = interface
  ['{EF29AFA5-5C45-44B0-915C-F1C5B9D40AE8}']
    procedure ListenerAdd(AListener: IACLResourceChangeListener);
    procedure ListenerRemove(AListener: IACLResourceChangeListener);
  end;

//----------------------------------------------------------------------------------------------------------------------
// Resources
//----------------------------------------------------------------------------------------------------------------------

  { TACLResourceListenerList }

  TACLResourceListenerList = class(TACLListenerList)
  public
    procedure NotifyBeginUpdate;
    procedure NotifyEndUpdate;
    procedure NotifyRemoving(AObject: TObject);
    procedure NotifyResourceChanged(Sender: TObject; AResource: TACLResource = nil);
  end;

  { TACLResource }

  TACLResourceClass = class of TACLResource;
  TACLResource = class abstract(TACLLockablePersistent,
    IACLObjectRemoveNotify,
    IACLResourceChangeListener,
    IACLResourceChangeNotifier)
  strict private
    FID: string;
    FIDDefault: string;
    FListeners: TACLResourceListenerList;
    FMaster: TACLResource;
    FOwner: TPersistent;
    FTargetDPI: Integer;

    procedure SetIDDefault(const AValue: string);
    procedure SetMaster(AValue: TACLResource);
    procedure SetTargetDPI(AValue: Integer);
  private
    procedure UpdateMaster; inline;
    // IACLResourceChangeListener
    procedure ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
    // IACLObjectRemoveNotify
    procedure Removing(AObject: TObject);
  protected
    function GetOwner: TPersistent; override;

    procedure DoAssign(Source: TPersistent); override; final;
    procedure DoAssignCore(ASource: TACLResource; AAssignValue: Boolean); virtual; abstract;
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
    procedure DoFlushCache; virtual;
    procedure DoFullRefresh; virtual;
    procedure DoMasterChanged; virtual;
    procedure DoReset; virtual;
    procedure DoResourceChanged(Sender: TObject; Resource: TACLResource = nil); virtual;
    procedure DoTargetDpiChanged; virtual;

    function EqualsValuesCore(AResource: TACLResource): Boolean; virtual; abstract;
    function GetResourceClass: TACLResourceClass; virtual;
    procedure Initialize; virtual;
    function IsIDStored: Boolean; virtual;
    function IsValueStored: Boolean; virtual;
    procedure SetID(const ID: string); virtual;
    function ToStringCore: string; virtual;

    procedure ValueChanged;

    property IDDefault: string read FIDDefault write SetIDDefault;
    property Master: TACLResource read FMaster;
  public
    constructor Create(AOwner: TPersistent);
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function Clone: TACLResource; virtual;
    function EqualsValues(AResource: TACLResource): Boolean;
    procedure DrawPreview(ACanvas: TCanvas; const R: TRect); virtual;
    procedure InitailizeDefaults(const DefaultID: string); virtual;
    function IsDefault: Boolean;
    procedure Reset;
    function ToString: string; override; final;
    class function TypeName: string; virtual;

    // IACLResourceChangeNotifier
    procedure ListenerAdd(AListener: IACLResourceChangeListener);
    procedure ListenerRemove(AListener: IACLResourceChangeListener);

    property ID: string read FID write SetID stored IsIDStored;
    property Owner: TPersistent read FOwner;
    property TargetDPI: Integer read FTargetDPI write SetTargetDPI;
  end;

  TACLResourceEnumProc = TRttiEnumProc<TACLResource>;

  { TACLResourceSimple }

  TACLResourceSimple<T> = class abstract(TACLResource)
  strict private
    FValue: T;
    FValueDefault: T;

    procedure SetValue(const AValue: T);
  protected
    procedure DoAssignCore(ASource: TACLResource; AAssignValue: Boolean); override;
    procedure DoReset; override;

    function CompareValues(const AValue1, AValue2: T): Boolean; virtual; abstract;
    function EqualsValuesCore(AResource: TACLResource): Boolean; override;
    function GetDefaultValue: T; virtual;
    function GetValue: T; virtual;
    procedure Initialize; override;
    function IsValueStored: Boolean; override;
  public
    procedure InitailizeDefaults(const DefaultID: string); overload; override;
    procedure InitailizeDefaults(const DefaultID: string; const DefaultValue: T); reintroduce; overload; virtual;
    //
    property Value: T read GetValue write SetValue stored IsValueStored;
    property ValueDefault: T read FValueDefault;
  end;

  { TACLResourceColor }

  TACLResourceColor = class(TACLResourceSimple<TAlphaColor>, IACLColorSchema)
  strict private
    FActualValue: TAlphaColor;
    FAllowColoration: TACLBoolean;
    FOpacity: Byte;

    function GetActualAllowColoration: Boolean;
    function GetAsColor: TColor;
    procedure SetAllowColoration(AValue: TACLBoolean);
    procedure SetAsColor(AValue: TColor);
    procedure SetOpacity(AValue: Byte);
  protected
    FColorSchema: TACLColorSchema;
    FIsAlphaSupported: Boolean;

    procedure DoAssignCore(ASource: TACLResource; AAssignValue: Boolean); override;
    procedure DoFlushCache; override;
    procedure DoReset; override;

    function CompareValues(const AValue1, AValue2: TAlphaColor): Boolean; override;
    function EqualsValuesCore(AResource: TACLResource): Boolean; override;
    procedure Initialize; override;
    function GetDefaultValue: TAlphaColor; override;
    function GetValue: TAlphaColor; override;
    function ToStringCore: string; override;
  public
    // IACLColorSchema
    procedure ApplyColorSchema(const AValue: TACLColorSchema);

    procedure DrawPreview(ACanvas: TCanvas; const R: TRect); override;
    procedure InitailizeDefaults(const DefaultID: string; AIsAlphaSupported: Boolean = False{backward compatibility}); reintroduce; overload;
    procedure InitailizeDefaults(const DefaultID: string; const DefaultValue: TColor); reintroduce; overload;
    procedure InitailizeDefaults(const DefaultID: string; const DefaultValue: TAlphaColor); override;
    function HasAlpha: Boolean; inline;
    function IsEmpty: Boolean; inline;

    property ActualAllowColoration: Boolean read GetActualAllowColoration;
    property AsColor: TColor read GetAsColor write SetAsColor;
    property IsAlphaSupported: Boolean read FIsAlphaSupported;
  published
    property AllowColoration: TACLBoolean read FAllowColoration write SetAllowColoration default TACLBoolean.Default;
    property Opacity: Byte read FOpacity write SetOpacity default MaxByte;
    property Value;
    property ID; // must be last
  end;

  { TACLResourceMargins }

  TACLResourceMargins = class(TACLResourceSimple<TRect>)
  strict private
    function IsSideStored(const Index: Integer): Boolean;

    function GetAll: Integer;
    function GetSide(AIndex: Integer): Integer;
    procedure SetAll(AValue: Integer);
    procedure SetSide(AIndex, AValue: Integer);
  protected
    function CompareValues(const AValue1, AValue2: TRect): Boolean; override;
    function GetDefaultValue: TRect; override;
    function ToStringCore: string; override;
  published
    property All: Integer read GetAll write SetAll stored False;
    property Bottom: Integer index 3 read GetSide write SetSide stored IsSideStored;
    property Left: Integer index 0 read GetSide write SetSide stored IsSideStored;
    property Right: Integer index 2 read GetSide write SetSide stored IsSideStored;
    property Top: Integer index 1 read GetSide write SetSide stored IsSideStored;
    property ID; // must be last
  end;

  { TACLResourceFont }

  TACLResourceFontAssignedValue = (rfavName, rfavColor, rfavHeight, rfavQuality, rfavStyle);
  TACLResourceFontAssignedValues = set of TACLResourceFontAssignedValue;

  TACLResourceFont = class(TACLResource,
    IACLColorSchema,
    IACLResourceProvider)
  strict private
    FActualFontColor: TAlphaColor;
    FActualFontInfo: TACLFontInfo;
    FAssignedValues: TACLResourceFontAssignedValues;
    FHeight: Integer;
    FName: TFontName;
    FQuality: TFontQuality;
    FStyle: TFontStyles;

    function GetAllowColoration: Boolean;
    function GetColor: TAlphaColor; inline;
    function GetColorID: string;
    function GetFontInfo: TACLFontInfo; inline;
    function GetHeight: Integer;
    function GetName: TFontName;
    function GetQuality: TFontQuality;
    function GetSize: Integer;
    function GetStyle: TFontStyles;
    function IsColorIDStored: Boolean;
    function IsColorStored: Boolean;
    function IsHeightStored: Boolean;
    function IsNameStored: Boolean;
    function IsQualityStored: Boolean;
    function IsStyleStored: Boolean;
    procedure SetAllowColoration(const Value: Boolean);
    procedure SetAssignedValues(const Value: TACLResourceFontAssignedValues);
    procedure SetColor(const Value: TAlphaColor);
    procedure SetColorID(const Value: string);
    procedure SetHeight(const Value: Integer);
    procedure SetName(const Value: TFontName);
    procedure SetQuality(const Value: TFontQuality);
    procedure SetSize(const Value: Integer);
    procedure SetStyle(const Value: TFontStyles);

    procedure ReadID(Reader: TReader);
    procedure WriteID(Writer: TWriter);

    // IACLResourceProvider
    function GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
  protected
    FColor: TACLResourceColor; // for property editor

    procedure AssignTo(Dest: TPersistent); override;
    procedure DoAssignCore(ASource: TACLResource; AAssignValue: Boolean); override;
    procedure DoFlushCache; override;
    procedure DoFullRefresh; override;
    procedure DoReset; override;
    procedure DoResetValues(AValues: TACLResourceFontAssignedValues);
    procedure DoResourceChanged(Sender: TObject; Resource: TACLResource = nil); override;

    procedure DefineProperties(Filer: TFiler); override;
    function EqualsValuesCore(AResource: TACLResource): Boolean; override;
    procedure Initialize; override;
    function IsValueStored: Boolean; override;
    function ToStringCore: string; override;
  public
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    procedure DrawPreview(ACanvas: TCanvas; const R: TRect); override;
    // IACLColorSchema
    procedure ApplyColorSchema(const AValue: TACLColorSchema);
  published
    property ID; // must be first
    property AllowColoration: Boolean read GetAllowColoration write SetAllowColoration default True;
    property Color: TAlphaColor read GetColor write SetColor stored IsColorStored;
    property ColorID: string read GetColorID write SetColorID stored IsColorIDStored;
    property Size: Integer read GetSize write SetSize stored False; // before the Height
    property Height: Integer read GetHeight write SetHeight stored IsHeightStored;
    property Name: TFontName read GetName write SetName stored IsNameStored;
    property Quality: TFontQuality read GetQuality write SetQuality stored IsQualityStored;
    property Style: TFontStyles read GetStyle write SetStyle stored IsStyleStored;
    property AssignedValues: TACLResourceFontAssignedValues read FAssignedValues write SetAssignedValues stored False; // must be last
  end;

  { TACLResourceInteger }

  TACLResourceInteger = class(TACLResourceSimple<Integer>)
  protected
    function CompareValues(const AValue1, AValue2: Integer): Boolean; override;
    function ToStringCore: string; override;
  published
    property ID;
    property Value;
  end;

  { TACLResourceTexture }

  TACLResourceTexture = class(TACLResource,
    IACLColorSchema,
    IACLResourceProvider)
  strict private
    FAllowColoration: TACLBoolean;
    FColorSchema: TACLColorSchema;
    FImage: TACLSkinImageSetItem;
    FImageDpi: Integer;
    FImageSet: TACLSkinImageSet;
    FScalable: TACLBoolean;

    function GetActualAllowColoration: Boolean;
    function GetActualColorSchema: TACLColorSchema;
    function GetActualScalable: Boolean;
    function GetDefaultAllowColoration: Boolean;
    function GetContentOffsets: TRect; inline;
    function GetEmpty: Boolean; inline;
    function GetFrameCount: Integer; inline;
    function GetFrameHeight: Integer; inline;
    function GetFrameSize: TSize; inline;
    function GetFrameWidth: Integer; inline;
    function GetHasAlpha: Boolean; inline;
    function GetImageSet: TACLSkinImageSet;
    function GetMargins: TRect; inline;
    function GetOverriden: Boolean; inline;
    function GetStretchMode: TACLStretchMode; inline;
    procedure SetAllowColoration(AValue: TACLBoolean);
    procedure SetImage(AImage: TACLSkinImageSetItem);
    procedure SetOverriden(AValue: Boolean);
    procedure SetScalable(AValue: TACLBoolean);
    procedure SkinImageChangeHandler(Sender: TObject);
    // IACLResourceProvider
    function GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
  protected
    procedure DoAssignCore(ASource: TACLResource; AAssignValue: Boolean); override;
    procedure DoMasterChanged; override;
    procedure DoResourceChanged(Sender: TObject; Resource: TACLResource = nil); override;
    procedure DoTargetDpiChanged; override;

    procedure DataRead(Stream: TStream);
    procedure DataWrite(Stream: TStream);
    procedure DefineProperties(Filer: TFiler); override;

    function EqualsValuesCore(AResource: TACLResource): Boolean; override;
    procedure Initialize; override;
    procedure LoadFromBitmapResourceCore(AInstance: HINST; const AName: UnicodeString; const AMargins, AContentOffsets: TRect;
      AFrameCount: Integer; ALayout: TACLSkinImageLayout = ilHorizontal; AStretchMode: TACLStretchMode = isStretch);

    function GetActualImage(ATargetDPI: Integer; AAllowColoration: TACLBoolean): TACLSkinImageSetItem; virtual;
    function GetHitTestMode: TACLSkinImageHitTestMode; virtual;
    function IsTextureStored: Boolean;
    function IsValueStored: Boolean; override;
    function ToStringCore: string; override;
    procedure UpdateImage; inline;
    procedure UpdateImageScaleFactor;
  public
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; inline;
    procedure Draw(DC: HDC; const R: TRect; AFrameIndex: Integer = 0; AEnabled: Boolean = True; AAlpha: Byte = MaxByte); overload;
    procedure Draw(DC: HDC; const R: TRect; AFrameIndex: Integer; ABorders: TACLBorders); overload;
    procedure DrawClipped(DC: HDC; const AClipRect, R: TRect; AFrameIndex: Integer; AAlpha: Byte = MaxByte);
    function HasFrame(AIndex: Integer): Boolean; inline;
    function HitTest(const ABounds: TRect; X, Y: Integer): Boolean; virtual;
    procedure InitailizeDefaults(const DefaultID: UnicodeString;
      AInstance: HINST; const AName: UnicodeString; const AMargins, AContentOffsets: TRect;
      AFrameCount: Integer; ALayout: TACLSkinImageLayout = ilHorizontal; AStretchMode: TACLStretchMode = isStretch); reintroduce; overload;
    procedure ImportFromImage(const AImage: TBitmap; DPI: Integer = acDefaultDPI);
    procedure ImportFromImageFile(const AFileName: string; DPI: Integer = acDefaultDPI);
    procedure ImportFromImageResource(const AInstance: HINST; const AResName: string; AResType: PWideChar; DPI: Integer = acDefaultDPI);
    procedure ImportFromImageStream(const AStream: TStream; DPI: Integer = acDefaultDPI);
    procedure MakeUnique;
    // IACLColorSchema
    procedure ApplyColorSchema(const AValue: TACLColorSchema);
    //
    property ContentOffsets: TRect read GetContentOffsets;
    property Empty: Boolean read GetEmpty;
    property FrameCount: Integer read GetFrameCount;
    property FrameHeight: Integer read GetFrameHeight;
    property FrameSize: TSize read GetFrameSize;
    property FrameWidth: Integer read GetFrameWidth;
    property HasAlpha: Boolean read GetHasAlpha;
    property HitTestMode: TACLSkinImageHitTestMode read GetHitTestMode;
    property Margins: TRect read GetMargins;
    property StretchMode: TACLStretchMode read GetStretchMode;
    //
    property ActualAllowColoration: Boolean read GetActualAllowColoration;
    property ActualColorSchema: TACLColorSchema read GetActualColorSchema;
    property ActualScalable: Boolean read GetActualScalable;
    property Image: TACLSkinImageSetItem read FImage;
    property ImageDpi: Integer read FImageDpi;
    property ImageSet: TACLSkinImageSet read GetImageSet;
  published
    property ID; // must be first
    property Overriden: Boolean read GetOverriden write SetOverriden stored False;
    property AllowColoration: TACLBoolean read FAllowColoration write SetAllowColoration default TACLBoolean.Default;
    property Scalable: TACLBoolean read FScalable write SetScalable default TACLBoolean.Default;
  end;

  { IACLGlyph }

  IACLGlyph = interface
  ['{F59A5559-9DB6-4DE7-B0DC-A24A564CD78A}']
    function GetGlyph: TACLGlyph;
  end;

  { TACLGlyph }

  TACLGlyph = class(TACLResourceTexture)
  strict private
    FFrameIndex: Integer;

    procedure SetFrameIndex(AValue: Integer);
  protected
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
    function GetResourceClass: TACLResourceClass; override;
  public
    procedure Draw(DC: HDC; const R: TRect; AEnabled: Boolean = True; AAlpha: Byte = $FF); reintroduce;
  published
    property FrameIndex: Integer read FFrameIndex write SetFrameIndex default 0;
  end;

  { TACLResourceClassRepository }

  TACLResourceClassRepository = class
  public type
    TEnumProc = reference to procedure (AClass: TACLResourceClass);
  strict private
    class var FItems: TList;
  public
    class procedure Enum(AProc: TEnumProc);
    class procedure Register(AClass: TACLResourceClass);
    class procedure Unregister(AClass: TACLResourceClass);
  end;

//----------------------------------------------------------------------------------------------------------------------
// Styles
//----------------------------------------------------------------------------------------------------------------------

  { TACLStyleMap }

  TACLStyleMap<T: TACLResource> = class(TObjectDictionary<Integer, TACLResource>)
  strict private
    FOwner: TPersistent;
  public
    constructor Create(AOwner: TPersistent); reintroduce;
    procedure Assign(ASource: TACLStyleMap<T>);
    procedure EnumResources(AEnumProc: TACLResourceEnumProc);
    function GetOrCreate(Index: Integer): T;
    procedure ResourceChanged(AResource: TACLResource);
    procedure SetTargetDPI(AValue: Integer);
  end;

  { TACLStyleColorsMap }

  TACLStyleColorsMap = class(TACLStyleMap<TACLResourceColor>);

  { TACLStyleFontsMap }

  TACLStyleFontsMap = class(TACLStyleMap<TACLResourceFont>);

  { TACLStyle }

  TACLStyleClass = class of TACLStyle;
  TACLStyle = class(TACLLockablePersistent,
    IACLObjectRemoveNotify,
    IACLColorSchema,
    IACLResourceChangeListener,
    IACLResourceCollection,
    IACLResourceCollectionSetter,
    IACLResourceProvider)
  strict private
    FCollection: TACLCustomResourceCollection;
    FColors: TACLStyleColorsMap;
    FFonts: TACLStyleFontsMap;
    FIntegers: TACLStyleMap<TACLResourceInteger>;
    FMargins: TACLStyleMap<TACLResourceMargins>;
    FOwner: TPersistent;
    FTargetDPI: Integer;
    FTextures: TACLStyleMap<TACLResourceTexture>;
    // IACLResourceChangeListener
    procedure ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
    // IACLResourceCollection
    function GetCollection: TACLCustomResourceCollection;
    // IACLObjectRemoveNotify
    procedure Removing(AObject: TObject);
    // IACLResourceCollectionSetter
    procedure SetCollection(const Value: TACLCustomResourceCollection);
  protected
    procedure DoAssign(ASource: TPersistent); override;
    procedure DoAssignResources(ASource: TACLStyle); virtual;
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
    procedure DoReset; virtual;
    procedure DoResourceChanged(AResource: TACLResource = nil); virtual;
    procedure DoSetTargetDPI(AValue: Integer); virtual;
    procedure InitializeResources; virtual;
    function GetOwner: TPersistent; override;

    // DPI
    function Scale(AValue: Integer): Integer; inline;
    procedure SetTargetDPI(AValue: Integer); virtual;

    // Colors
    function GetColor(AIndex: Integer): TACLResourceColor;
    function IsColorStored(AIndex: Integer): Boolean;
    procedure SetColor(AIndex: Integer; AValue: TACLResourceColor);

    // Fonts
    function GetFont(AIndex: Integer): TACLResourceFont;
    function IsFontStored(AIndex: Integer): Boolean;
    procedure SetFont(AIndex: Integer; AValue: TACLResourceFont);

    // Margins
    function GetMargins(AIndex: Integer): TACLResourceMargins;
    function IsMarginsStored(AIndex: Integer): Boolean;
    procedure SetMargins(AIndex: Integer; AValue: TACLResourceMargins);

    // Textures
    function GetTexture(AIndex: Integer): TACLResourceTexture;
    function IsTextureStored(AIndex: Integer): Boolean;
    procedure SetTexture(AIndex: Integer; AValue: TACLResourceTexture);

    // Integers
    function GetInteger(AIndex: Integer): TACLResourceInteger;
    function IsIntegerStored(AIndex: Integer): Boolean;
    procedure SetInteger(AIndex: Integer; AValue: TACLResourceInteger);

    property Owner: TPersistent read FOwner;
  public
    constructor Create(AOwner: TPersistent);
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure EnumResources(AEnumProc: TACLResourceEnumProc); virtual;
    procedure Refresh; overload;
    class procedure Refresh(AObject: TObject); overload;
    procedure Reset;
    // IACLColorSchema,
    procedure ApplyColorSchema(const AColorSchema: TACLColorSchema);
    // IACLResourceProvider
    function GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject; virtual;
    //
    property TargetDPI: Integer read FTargetDPI write SetTargetDPI;
  published
    property Collection: TACLCustomResourceCollection read FCollection write SetCollection;
  end;

  TACLStyleEnumProc = reference to procedure (AStyle: TACLStyle);

//----------------------------------------------------------------------------------------------------------------------
// Collection
//----------------------------------------------------------------------------------------------------------------------

  TACLResourceCollectionItems = class;

  { TACLResourceCollectionItem }

  TACLResourceCollectionItem = class(TACLCollectionItem,
    IACLResourceProvider,
    IACLResourceCollection,
    IACLResourceChangeListener)
  strict private
    FDescription: string;
    FID: string;
    FResource: TACLResource;

    function GetCollection: TACLResourceCollectionItems;
    function GetResourceClassName: string;
    procedure SetID(const Value: string);
    procedure SetResource(AValue: TACLResource);
    procedure SetResourceClassName(const AValue: string);
    // IACLResourceCollection
    function IACLResourceCollection.GetCollection = GetCollectionEx;
    function GetCollectionEx: TACLCustomResourceCollection;
    // IACLResourceProvider
    function GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
    // IACLResourceChangeListener
    procedure ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
  protected
    function GetDisplayName: string; override;
  public
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    //
    property Collection: TACLResourceCollectionItems read GetCollection;
  published
    property ID: string read FID write SetID;
    property Description: string read FDescription write FDescription;
    property ResourceClassName: string read GetResourceClassName write SetResourceClassName; //# must be first, hidden
    property Resource: TACLResource read FResource write SetResource;
  end;

  { TACLResourceCollectionItems }

  TACLResourceCollectionItems = class(TACLCollection)
  public type
    TEnumProc = reference to function (AResource: TACLResourceCollectionItem): Boolean;
  strict private
    FOwner: TACLCustomResourceCollection;

    function GetItem(Index: Integer): TACLResourceCollectionItem; inline;
  protected
    FIndex: TDictionary<string, TACLResourceCollectionItem>;

    function AddCore(const ID: string; AClass: TACLResourceClass): TACLResourceCollectionItem;
    function GetOwner: TPersistent; override;
    procedure UpdateCore(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TACLCustomResourceCollection);
    destructor Destroy; override;

    function Add(const ID: string; AClass: TACLResourceClass): TACLResource; overload;
    function Add<T: TACLResource>(const ID: string): T; overload;
    procedure Add(AItems: TACLResourceCollectionItems); overload;
    procedure Add(AStyle: TACLStyle); overload;

    function AddColor(const ID: string; AColor: TColor): TACLResourceColor;
    function AddMargins(const ID: string; const AValue: TRect): TACLResourceMargins;
    function AddResource(AResource: TACLResource; ID: string = ''): TACLResource;
    function AddTexture(const ID: string; ASkinImage: TACLSkinImageSet): TACLResourceTexture; overload;
    function AddTexture(const ID: string;
      const AResInstance: HINST; const AResName: UnicodeString;
      const AMargins, AContentOffsets: TRect; AFrameCount: Integer;
      const ALayout: TACLSkinImageLayout = ilHorizontal;
      const AStretchMode: TACLStretchMode = isStretch): TACLResourceTexture; overload;
    function AddRemap(const ID, MasterID: string; AClass: TACLResourceClass): TACLResource;

    procedure EnumResources(AProc: TACLResourceEnumProc); overload;
    procedure EnumResources(AResourceClass: TClass; AProc: TEnumProc); overload;
    function GetResource(const ID: string): TACLResourceCollectionItem; overload;
    function GetResource(const ID: string; AResourceClass: TClass): TObject; overload;

    property Items[Index: Integer]: TACLResourceCollectionItem read GetItem; default;
  {$WARNINGS OFF}
    property Owner: TACLCustomResourceCollection read FOwner;
  {$WARNINGS ON}
  end;

  { TACLCustomResourceCollection }

  TACLCustomResourceCollection = class(TACLComponent,
    IACLApplicationListener,
    IACLColorSchema,
    IACLResourceChangeListener,
    IACLResourceChangeNotifier,
    IACLResourceProvider,
    IACLUpdateLock)
  strict private
    FItems: TACLResourceCollectionItems;
    FListeners: TACLResourceListenerList;

    procedure SetItems(AValue: TACLResourceCollectionItems);
    // IACLApplicationListener
    procedure IACLApplicationListener.Changed = ApplicationSettingsChanged;
    // IACLResourceChangeListener
    procedure IACLResourceChangeListener.ResourceChanged = _ResourceChanged;
    procedure _ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
  protected
    procedure ApplicationSettingsChanged(AChanges: TACLApplicationChanges); virtual;
    function GetDefaultResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject; virtual;
    procedure ResourceChanged(AResource: TACLResource = nil); virtual;

    property Listeners: TACLResourceListenerList read FListeners;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    procedure EnumResources(AProc: TACLResourceEnumProc); overload;
    procedure EnumResources(AResourceClass: TClass; AProc: TACLResourceCollectionItems.TEnumProc); overload;
    procedure EnumResources(AResourceClass: TClass; AList: TACLStringList); overload;
    procedure EnumResources(AResourceClass: TClass; AList: TStrings); overload;
    // IACLColorSchema
    procedure ApplyColorSchema(const AColorSchema: TACLColorSchema); virtual;
    // IACLUpdateLock
    procedure BeginUpdate;
    procedure EndUpdate;
    // IACLResourceProvider
    function GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
    // IACLResourceChangeNotifier
    procedure ListenerAdd(AListener: IACLResourceChangeListener);
    procedure ListenerRemove(AListener: IACLResourceChangeListener);
    // I/O
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromResource(AInstance: HINST; const AName: string);
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToFile(const AFileName: string);
    procedure SaveToStream(AStream: TStream);
  published
    property Items: TACLResourceCollectionItems read FItems write SetItems;
  end;

  { TACLResourceCollection }

  TACLResourceCollection = class(TACLCustomResourceCollection)
  strict private
    FMasterCollection: TACLCustomResourceCollection;

    procedure SetMasterCollection(const AValue: TACLCustomResourceCollection);
  protected
    function GetDefaultResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    procedure BeforeDestruction; override;
  published
    property MasterCollection: TACLCustomResourceCollection read FMasterCollection write SetMasterCollection;
  end;

  { TACLRootResourceCollection }

  TACLRootResourceCollection = class
  strict private
    class var FFinalized: Boolean;
    class var FInstance: TACLCustomResourceCollection;

    class procedure InitializeCursors;
  public
    class destructor Destroy;
    class function GetInstance: TACLCustomResourceCollection;
    class function GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject; overload;
    class function GetResource(const ID: string; AResourceClass: TClass; ASender: TObject; out AResource): Boolean; overload;
    class function HasInstance: Boolean;

    class procedure ListenerAdd(AListener: IACLResourceChangeListener);
    class procedure ListenerRemove(AListener: IACLResourceChangeListener);
  end;

procedure acApplyColorSchemaForPublishedProperties(AObject: TObject; const AColorSchema: TACLColorSchema);
function acResourceCollectionFieldSet(var AField: TACLCustomResourceCollection; AOwner: TComponent;
  const AListener: IACLResourceChangeListener; ANewValue: TACLCustomResourceCollection): Boolean;
implementation

uses
  System.TypInfo,
  System.SysUtils,
  System.Math,
  // VCL
  Vcl.Forms,
  // ACL
  ACL.Math,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Forms,
  ACL.Utils.Strings;

type

  { TACLRootResourceCollectionImpl }

  TACLRootResourceCollectionImpl = class(TACLCustomResourceCollection)
  strict private
    procedure InheritIfNecessary(const AResourceName, ASuffix: string);
  protected
    procedure ApplicationSettingsChanged(AChanges: TACLApplicationChanges); override;
    procedure InitializeResources;
  public
    constructor Create; reintroduce;
  end;

procedure acApplyColorSchemaForPublishedProperties(AObject: TObject; const AColorSchema: TACLColorSchema);
var
  APropCount: Integer;
  APropInfo: PPropInfo;
  APropList: PPropList;
  APropObject: TObject;
  ASchema: IACLColorSchema;
  I: Integer;
begin
  if TRTTI.GetProperties(AObject, APropList, APropCount) then
  try
    for I := 0 to APropCount - 1 do
    begin
      APropInfo := APropList^[I];
      if APropInfo^.PropType^^.Kind = tkClass then
      begin
        APropObject := GetObjectProp(AObject, APropInfo);
        if (APropObject = nil) or (APropObject is TComponent) then
          Continue;
        if Supports(APropObject, IACLColorSchema, ASchema) then
          ASchema.ApplyColorSchema(AColorSchema)
        else
          acApplyColorSchemaForPublishedProperties(APropObject, AColorSchema);
      end;
    end;
  finally
    FreeMem(APropList);
  end;
end;

function acResourceCollectionFieldSet(var AField: TACLCustomResourceCollection; AOwner: TComponent;
  const AListener: IACLResourceChangeListener; ANewValue: TACLCustomResourceCollection): Boolean;
begin
  Result := AField <> ANewValue;
  if Result then
  begin
    if AField <> nil then
    begin
      AField.RemoveFreeNotification(AOwner);
      if AListener <> nil then
        AField.ListenerRemove(AListener);
      AField := nil;
    end;
    if ANewValue <> nil then
    begin
      AField := ANewValue;
      if AListener <> nil then
        AField.ListenerAdd(AListener);
      AField.FreeNotification(AOwner);
    end;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// Resources
//----------------------------------------------------------------------------------------------------------------------

{ TACLResourceListenerList }

procedure TACLResourceListenerList.NotifyBeginUpdate;
begin
  Enum<IACLUpdateLock>(
    procedure (const AIntf: IACLUpdateLock)
    begin
      AIntf.BeginUpdate;
    end);
end;

procedure TACLResourceListenerList.NotifyEndUpdate;
begin
  Enum<IACLUpdateLock>(
    procedure (const AIntf: IACLUpdateLock)
    begin
      AIntf.EndUpdate;
    end);
end;

procedure TACLResourceListenerList.NotifyRemoving(AObject: TObject);
begin
  Enum<IACLObjectRemoveNotify>(
    procedure (const AIntf: IACLObjectRemoveNotify)
    begin
      AIntf.Removing(AObject);
    end);
end;

procedure TACLResourceListenerList.NotifyResourceChanged(Sender: TObject; AResource: TACLResource);
begin
  Enum<IACLResourceChangeListener>(
    procedure (const AIntf: IACLResourceChangeListener)
    begin
      AIntf.ResourceChanged(Sender, AResource);
    end);
end;

{ TACLResource }

constructor TACLResource.Create(AOwner: TPersistent);
begin
  inherited Create;
  FListeners := TACLResourceListenerList.Create;

  BeginUpdate;
  try
    // don't change the order
    FTargetDPI := acDefaultDPI;
    Initialize;
    FOwner := AOwner;
    UpdateMaster;
  finally
    CancelUpdate;
  end;
end;

destructor TACLResource.Destroy;
begin
  FreeAndNil(FListeners);
  inherited;
end;

procedure TACLResource.AfterConstruction;
var
  AIntf: IACLResourceChangeNotifier;
begin
  inherited AfterConstruction;
  if Supports(Owner, IACLResourceChangeNotifier, AIntf) then
    AIntf.ListenerAdd(Self);
end;

procedure TACLResource.BeforeDestruction;
var
  AIntf: IACLResourceChangeNotifier;
begin
  BeginUpdate;
  inherited BeforeDestruction;
  if Supports(Owner, IACLResourceChangeNotifier, AIntf) then
    AIntf.ListenerRemove(Self);
  FListeners.NotifyRemoving(Self);
  SetMaster(nil);
end;

function TACLResource.Clone: TACLResource;
begin
  Result := TACLResourceClass(ClassType).Create(nil);
  Result.Assign(Self);
end;

function TACLResource.EqualsValues(AResource: TACLResource): Boolean;
begin
  Result := (AResource <> nil) and (GetResourceClass = AResource.GetResourceClass) and EqualsValuesCore(AResource);
end;

procedure TACLResource.DrawPreview(ACanvas: TCanvas; const R: TRect);
begin
  acTextDraw(ACanvas, ToString, acRectInflate(R, -acTextIndent, 0), taLeftJustify, taVerticalCenter, True);
end;

procedure TACLResource.InitailizeDefaults(const DefaultID: string);
begin
  IDDefault := DefaultID;
end;

function TACLResource.IsDefault: Boolean;
begin
  Result := not (IsIDStored or IsValueStored);
end;

procedure TACLResource.Reset;
begin
  BeginUpdate;
  try
    DoReset;
    DoFlushCache;
  finally
    EndUpdate;
  end;
end;

function TACLResource.ToString: string;
begin
  Result := ToStringCore;
  Result := ID + IfThenW((ID <> '') and (Result <> ''), ' - ') + Result;
end;

class function TACLResource.TypeName: string;
begin
  Result := acStringReplace(ClassName, TACLResource.ClassName, '');
end;

procedure TACLResource.ListenerAdd(AListener: IACLResourceChangeListener);
begin
  FListeners.Add(AListener);
end;

procedure TACLResource.ListenerRemove(AListener: IACLResourceChangeListener);
begin
  FListeners.Remove(AListener);
end;

procedure TACLResource.DoAssign(Source: TPersistent);
begin
  if (Source is TACLResource) and (TACLResource(Source).GetResourceClass = GetResourceClass) then
  begin
    ID := TACLResource(Source).ID;
    DoAssignCore(TACLResource(Source), ID = '');
  end;
end;

procedure TACLResource.DoChanged(AChanges: TACLPersistentChanges);
var
  AIntf: IACLResourceChangeListener;
begin
  DoFlushCache;
  FListeners.NotifyResourceChanged(Self, Self);
  if Supports(FOwner, IACLResourceChangeListener, AIntf) then
    AIntf.ResourceChanged(Self, Self);
end;

procedure TACLResource.DoFlushCache;
begin
  // do nothing
end;

procedure TACLResource.DoFullRefresh;
begin
  DoFlushCache;
  UpdateMaster;
end;

procedure TACLResource.DoMasterChanged;
begin
  Changed;
end;

procedure TACLResource.DoTargetDpiChanged;
begin
  DoFlushCache;
end;

procedure TACLResource.DoReset;
begin
  ID := FIDDefault;
end;

procedure TACLResource.DoResourceChanged(Sender: TObject; Resource: TACLResource = nil);
begin
  if Resource = nil then
    UpdateMaster
  else
    if (Master <> nil) and (Resource = Master) then
      Changed;
end;

function TACLResource.GetResourceClass: TACLResourceClass;
begin
  Result := TACLResourceClass(ClassType);
end;

procedure TACLResource.Initialize;
begin
  Reset;
end;

function TACLResource.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

function TACLResource.IsIDStored: Boolean;
begin
  Result := ID <> FIDDefault;
end;

function TACLResource.IsValueStored: Boolean;
begin
  Result := FMaster = nil;
end;

function TACLResource.ToStringCore: string;
begin
  Result := '';
end;

procedure TACLResource.SetID(const ID: string);
begin
  if ID <> FID then
  begin
    FID := ID;
    UpdateMaster;
  end;
end;

procedure TACLResource.ValueChanged;
begin
  ID := '';
  Changed;
end;

procedure TACLResource.SetIDDefault(const AValue: string);
begin
  if FID = FIDDefault then
  begin
    FIDDefault := AValue;
    ID := IDDefault;
  end
  else
    FIDDefault := AValue;
end;

procedure TACLResource.SetMaster(AValue: TACLResource);
begin
  if AValue <> Master then
  begin
    BeginUpdate;
    try
      if FMaster <> nil then
      begin
        FMaster.ListenerRemove(Self);
        FMaster := nil;
      end;
      if AValue <> nil then
      begin
        FMaster := AValue;
        FMaster.ListenerAdd(Self);
      end;
      DoMasterChanged;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TACLResource.SetTargetDPI(AValue: Integer);
begin
  AValue := acCheckDPIValue(AValue);
  if FTargetDPI <> AValue then
  begin
    FTargetDPI := AValue;
    DoTargetDpiChanged;
  end;
end;

procedure TACLResource.UpdateMaster;
var
  AMaster: TACLResource;
  AProvider: IACLResourceProvider;
begin
  AMaster := nil;
  if (ID <> '') and Supports(FOwner, IACLResourceProvider, AProvider) then
  begin
    AMaster := AProvider.GetResource(ID, GetResourceClass, Self) as TACLResource;
    if AMaster = Self then
      AMaster := nil;
  end;
  SetMaster(AMaster);
end;

procedure TACLResource.ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
begin
  BeginUpdate;
  try
    DoFlushCache;
    DoResourceChanged(Sender, Resource);
  finally
    EndUpdate;
  end;
end;

procedure TACLResource.Removing(AObject: TObject);
begin
  if AObject = Master then
    UpdateMaster;
end;

{ TACLResourceSimple<T> }

procedure TACLResourceSimple<T>.Initialize;
begin
  FValueDefault := GetDefaultValue;
  inherited Initialize;
end;

procedure TACLResourceSimple<T>.InitailizeDefaults(const DefaultID: string);
begin
  InitailizeDefaults(DefaultID, GetDefaultValue);
end;

procedure TACLResourceSimple<T>.InitailizeDefaults(const DefaultID: string; const DefaultValue: T);
begin
  ID := DefaultID;
  IDDefault := DefaultID;
  if CompareValues(FValue, FValueDefault) then
    FValue := DefaultValue;
  FValueDefault := DefaultValue;
end;

procedure TACLResourceSimple<T>.DoAssignCore(ASource: TACLResource; AAssignValue: Boolean);
begin
  if AAssignValue then
    Value := TACLResourceSimple<T>(ASource).Value;
end;

procedure TACLResourceSimple<T>.DoReset;
begin
  Value := GetDefaultValue;
  inherited DoReset;
end;

function TACLResourceSimple<T>.EqualsValuesCore(AResource: TACLResource): Boolean;
begin
  Result := CompareValues(Value, TACLResourceSimple<T>(AResource).Value);
end;

function TACLResourceSimple<T>.IsValueStored: Boolean;
begin
  Result := inherited IsValueStored and
    not CompareValues(FValue, GetDefaultValue) and
    not CompareValues(FValue, ValueDefault);
end;

function TACLResourceSimple<T>.GetDefaultValue: T;
begin
  Result := Default(T);
end;

function TACLResourceSimple<T>.GetValue: T;
begin
  if Master <> nil then
    Result := TACLResourceSimple<T>(Master).Value
  else
    if CompareValues(FValue, GetDefaultValue) then
      Result := ValueDefault
    else
      Result := FValue;
end;

procedure TACLResourceSimple<T>.SetValue(const AValue: T);
begin
  if (ID <> '') or not CompareValues(FValue, AValue) then
  begin
    FValue := AValue;
    ValueChanged;
  end;
end;

{ TACLResourceColor }

procedure TACLResourceColor.DrawPreview(ACanvas: TCanvas; const R: TRect);
begin
  acDrawColorPreview(ACanvas, acRectSetWidth(R, acRectHeight(R)), Value);
  inherited DrawPreview(ACanvas, Rect(R.Left + acRectHeight(R), R.Top, R.Right, R.Bottom));
end;

procedure TACLResourceColor.InitailizeDefaults(const DefaultID: string; AIsAlphaSupported: Boolean);
begin
  InitailizeDefaults(DefaultID, GetDefaultValue);
  FIsAlphaSupported := AIsAlphaSupported;
end;

procedure TACLResourceColor.InitailizeDefaults(const DefaultID: string; const DefaultValue: TColor);
begin
  InitailizeDefaults(DefaultID, TAlphaColor.FromColor(DefaultValue));
  FIsAlphaSupported := False;
end;

procedure TACLResourceColor.InitailizeDefaults(const DefaultID: string; const DefaultValue: TAlphaColor);
begin
  inherited InitailizeDefaults(DefaultID, DefaultValue);
  FIsAlphaSupported := True;
end;

function TACLResourceColor.HasAlpha: Boolean;
begin
  Result := IsAlphaSupported and (Value.A < MaxByte);
end;

function TACLResourceColor.IsEmpty: Boolean;
begin
  Result := Value = TAlphaColor.None;
end;

procedure TACLResourceColor.ApplyColorSchema(const AValue: TACLColorSchema);
begin
  if FColorSchema <> AValue then
  begin
    FColorSchema := AValue;
    if IsValueStored then
      Changed([apcContent]);
  end;
end;

function TACLResourceColor.CompareValues(const AValue1, AValue2: TAlphaColor): Boolean;
begin
  Result := AValue1 = AValue2;
end;

procedure TACLResourceColor.DoAssignCore(ASource: TACLResource; AAssignValue: Boolean);
begin
  FAllowColoration := TACLResourceColor(ASource).AllowColoration;
  FOpacity := TACLResourceColor(ASource).Opacity;
  FColorSchema := TACLResourceColor(ASource).FColorSchema;
  inherited;
end;

procedure TACLResourceColor.DoFlushCache;
begin
  FActualValue := TAlphaColor.Default;
end;

procedure TACLResourceColor.DoReset;
begin
  FAllowColoration := TACLBoolean.Default;
  FOpacity := MaxByte;
  inherited;
end;

function TACLResourceColor.EqualsValuesCore(AResource: TACLResource): Boolean;
begin
  Result := inherited EqualsValuesCore(AResource) and
    (FOpacity = TACLResourceColor(AResource).Opacity) and
    (FAllowColoration = TACLResourceColor(AResource).AllowColoration);
end;

procedure TACLResourceColor.Initialize;
begin
  FActualValue := TAlphaColor.Default;
  FIsAlphaSupported := True;
  FOpacity := MaxByte;
  inherited;
end;

function TACLResourceColor.GetDefaultValue: TAlphaColor;
begin
  Result := TAlphaColor.Default;
end;

function TACLResourceColor.GetValue: TAlphaColor;
begin
  if FActualValue = TAlphaColor.Default then
  begin
    FActualValue := inherited;
    if Opacity <> MaxByte then
      FActualValue.A := TACLColors.PremultiplyTable[FActualValue.A, Opacity];
    if IsValueStored and FColorSchema.IsAssigned and ActualAllowColoration then
      FActualValue := TAlphaColor.ApplyColorSchema(FActualValue, FColorSchema);
  end;
  Result := FActualValue;
end;

function TACLResourceColor.ToStringCore: string;
begin
  Result := Value.ToString;
  if Opacity <> MaxByte then
    Result := Format('%s (%d%%)', [Result, MulDiv(100, Opacity, MaxByte)]);
end;

function TACLResourceColor.GetActualAllowColoration: Boolean;
begin
  if FAllowColoration <> TACLBoolean.Default then
    Result := FAllowColoration = TACLBoolean.True
  else
    if Master <> nil then
      Result := TACLResourceColor(Master).ActualAllowColoration
    else
      Result := True;
end;

function TACLResourceColor.GetAsColor: TColor;
begin
  Result := Value.ToColor;
end;

procedure TACLResourceColor.SetAllowColoration(AValue: TACLBoolean);
begin
  if FAllowColoration <> AValue then
  begin
    FAllowColoration := AValue;
    Changed;
  end;
end;

procedure TACLResourceColor.SetAsColor(AValue: TColor);
begin
  Value := TAlphaColor.FromColor(AValue);
end;

procedure TACLResourceColor.SetOpacity(AValue: Byte);
begin
  if FOpacity <> AValue then
  begin
    FOpacity := AValue;
    Changed;
  end;
end;

{ TACLResourceMargins }

function TACLResourceMargins.CompareValues(const AValue1, AValue2: TRect): Boolean;
begin
  Result := AValue1 = AValue2;
end;

function TACLResourceMargins.GetAll: Integer;
begin
  if (Left = Top) and (Top = Right) and (Right = Bottom) then
    Result := Left
  else
    Result := 0;
end;

function TACLResourceMargins.GetDefaultValue: TRect;
begin
  Result := ValueDefault;
end;

function TACLResourceMargins.GetSide(AIndex: Integer): Integer;
begin
  if Master <> nil then
    Result := TACLResourceMargins(Master).GetSide(AIndex)
  else
    case AIndex of
      0: Result := Value.Left;
      1: Result := Value.Top;
      2: Result := Value.Right;
    else
      Result := Value.Bottom;
    end;
end;

function TACLResourceMargins.IsSideStored(const Index: Integer): Boolean;
begin
  Result := IsValueStored;
end;

procedure TACLResourceMargins.SetAll(AValue: Integer);
begin
  Value := Rect(AValue, AValue, AValue, AValue);
end;

procedure TACLResourceMargins.SetSide(AIndex, AValue: Integer);
var
  ARect: TRect;
begin
  AValue := Max(AValue, 0);
  if AValue <> GetSide(AIndex) then
  begin
    ARect := Value;
    case AIndex of
      0: ARect.Left := AValue;
      1: ARect.Top := AValue;
      2: ARect.Right := AValue;
    else
      ARect.Bottom := AValue;
    end;
    Value := ARect;
  end;
end;

function TACLResourceMargins.ToStringCore: string;
begin
  Result := acRectToString(Value);
end;

{ TACLResourceFont }

destructor TACLResourceFont.Destroy;
begin
  FreeAndNil(FColor);
  inherited;
end;

procedure TACLResourceFont.Assign(Source: TPersistent);
begin
  if Source is TFont then
  begin
    BeginUpdate;
    try
      Color := TAlphaColor.FromColor(TFont(Source).Color);
      Height := TFont(Source).Height;
      Style := TFont(Source).Style;
      Quality := TFont(Source).Quality;
      Name := TFont(Source).Name;
    finally
      EndUpdate;
    end;
  end
  else
    inherited;
end;

procedure TACLResourceFont.ApplyColorSchema(const AValue: TACLColorSchema);
begin
  FColor.ApplyColorSchema(AValue);
end;

procedure TACLResourceFont.DrawPreview(ACanvas: TCanvas; const R: TRect);
begin
  acDrawColorPreview(ACanvas, acRectSetWidth(R, acRectHeight(R)), Color);
  inherited DrawPreview(ACanvas, Rect(R.Left + acRectHeight(R), R.Top, R.Right, R.Bottom));
end;

procedure TACLResourceFont.AssignTo(Dest: TPersistent);
begin
  if Dest is TFont then
  begin
    GetFontInfo.AssignTo(TFont(Dest));
    TFont(Dest).Color := Color.ToColor;
//    //#AI
//    //# it lead to call the OnChange event even if font parameters are same
//    //# TFont(Dest).Handle := 0;
//    TFont(Dest).Name := Name;
//    TFont(Dest).Style := Style;
//    TFont(Dest).Color := Color.ToColor;
//
//    //# https://forums.embarcadero.com/thread.jspa?messageID=667590&tstart=0
//    //# https://github.com/virtual-treeview/virtual-treeview/issues/465
//    if Quality = fqClearTypeNatural then
//      TFont(Dest).Quality := fqClearType
//    else
//      TFont(Dest).Quality := Quality;
//
//    acSetFontHeight(TFont(Dest), Height, TargetDPI);
  end
  else
    inherited AssignTo(Dest);
end;

procedure TACLResourceFont.DoAssignCore(ASource: TACLResource; AAssignValue: Boolean);
begin
  FHeight := TACLResourceFont(ASource).Height;
  FName := TACLResourceFont(ASource).Name;
  FStyle := TACLResourceFont(ASource).Style;
  Color := TACLResourceFont(ASource).Color;
  FQuality := TACLResourceFont(ASource).Quality;
  FAssignedValues := TACLResourceFont(ASource).AssignedValues; // must be last
  Changed;
end;

procedure TACLResourceFont.DoFlushCache;
begin
  FColor.DoFlushCache;
  FActualFontColor := TAlphaColor.Default;
  FActualFontInfo := nil;
end;

procedure TACLResourceFont.DoFullRefresh;
begin
  inherited;
  FColor.DoFullRefresh;
end;

procedure TACLResourceFont.DoReset;
begin
  inherited DoReset;
  AssignedValues := [];
end;

procedure TACLResourceFont.DoResetValues(AValues: TACLResourceFontAssignedValues);
begin
  if rfavColor in AValues then
    FColor.Reset;
end;

procedure TACLResourceFont.DoResourceChanged(Sender: TObject; Resource: TACLResource = nil);
begin
  inherited;
  if Resource = nil then
    FColor.UpdateMaster;
  if Resource = FColor then
  begin
    if FColor.IsDefault then
      Exclude(FAssignedValues, rfavColor);
    Changed;
  end;
end;

procedure TACLResourceFont.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('ID', ReadID, WriteID, IsIDStored);
end;

function TACLResourceFont.EqualsValuesCore(AResource: TACLResource): Boolean;
begin
  Result :=
    (Height = TACLResourceFont(AResource).Height) and
    (Name = TACLResourceFont(AResource).Name) and
    (Style = TACLResourceFont(AResource).Style) and
    (Quality = TACLResourceFont(AResource).Quality) and
    (FColor.EqualsValues(TACLResourceFont(AResource).FColor));
end;

function TACLResourceFont.GetName: TFontName;
begin
  if rfavName in AssignedValues then
    Result := FName
  else
    if Master <> nil then
      Result := TACLResourceFont(Master).Name
    else
      Result := TFontName(DefFontData.Name);
end;

function TACLResourceFont.GetQuality: TFontQuality;
begin
  if rfavQuality in AssignedValues then
    Result := FQuality
  else
    if Master <> nil then
      Result := TACLResourceFont(Master).Quality
    else
      Result := DefFontData.Quality;
end;

function TACLResourceFont.GetAllowColoration: Boolean;
begin
  Result := FColor.ActualAllowColoration;
end;

function TACLResourceFont.GetColor: TAlphaColor;
begin
  if FActualFontColor = TAlphaColor.Default then
  begin
    if rfavColor in AssignedValues then
      FActualFontColor := FColor.Value
    else if Master <> nil then
      FActualFontColor := TACLResourceFont(Master).Color
    else
      FActualFontColor := TAlphaColor.Default;
  end;
  Result := FActualFontColor;
end;

function TACLResourceFont.GetColorID: string;
begin
  if rfavColor in AssignedValues then
    Result := FColor.ID
  else
    if Master <> nil then
      Result := TACLResourceFont(Master).ColorID
    else
      Result := '';
end;

function TACLResourceFont.GetFontInfo: TACLFontInfo;
begin
  if FActualFontInfo = nil then
    FActualFontInfo := TACLFontCache.GetInfo(Name, Style, Height, TargetDPI, Quality);
  Result := FActualFontInfo;
end;

function TACLResourceFont.GetHeight: Integer;
begin
  if rfavHeight in AssignedValues then
    Result := FHeight
  else
    if Master <> nil then
      Result := TACLResourceFont(Master).Height
    else
      // У нас все размеры определяются для 100% масштаба
      Result := MulDiv(DefFontData.Height, acDefaultDPI, acGetSystemDpi);
end;

function TACLResourceFont.GetSize: Integer;
begin
  Result := -MulDiv(Height, 72, acDefaultDPI);
end;

function TACLResourceFont.GetStyle: TFontStyles;
begin
  if rfavStyle in AssignedValues then
    Result := FStyle
  else
    if Master <> nil then
      Result := TACLResourceFont(Master).Style
    else
      Result := DefFontData.Style;
end;

function TACLResourceFont.IsColorIDStored: Boolean;
begin
  Result := (rfavColor in AssignedValues) and FColor.IsIDStored;
end;

function TACLResourceFont.IsColorStored: Boolean;
begin
  Result := (rfavColor in AssignedValues) and not FColor.IsIDStored;
end;

function TACLResourceFont.IsHeightStored: Boolean;
begin
  Result := rfavHeight in AssignedValues;
end;

function TACLResourceFont.IsNameStored: Boolean;
begin
  Result := rfavName in AssignedValues;
end;

function TACLResourceFont.IsQualityStored: Boolean;
begin
  Result := rfavQuality in AssignedValues;
end;

function TACLResourceFont.IsStyleStored: Boolean;
begin
  Result := rfavStyle in AssignedValues;
end;

procedure TACLResourceFont.Initialize;
begin
  FColor := TACLResourceColor.Create(Self);
  inherited;
end;

function TACLResourceFont.IsValueStored: Boolean;
begin
  Result := IsHeightStored or IsStyleStored or IsNameStored or IsColorStored or IsColorIDStored;
end;

function TACLResourceFont.ToStringCore: string;
begin
  Result := Format('%s, %dpt', [Name, Abs(Size)])
end;

procedure TACLResourceFont.SetAllowColoration(const Value: Boolean);
begin
  FColor.AllowColoration := TACLBoolean.From(Value);
end;

procedure TACLResourceFont.SetAssignedValues(const Value: TACLResourceFontAssignedValues);
begin
  if FAssignedValues <> Value then
  begin
    DoResetValues(AssignedValues - Value);
    FAssignedValues := Value;
    Changed;
  end;
end;

procedure TACLResourceFont.SetColor(const Value: TAlphaColor);
begin
  BeginUpdate;
  try
    AssignedValues := AssignedValues + [rfavColor];
    FColor.Value := Value;
  finally
    EndUpdate;
  end;
end;

procedure TACLResourceFont.SetColorID(const Value: string);
begin
  BeginUpdate;
  try
    AssignedValues := AssignedValues + [rfavColor];
    FColor.ID := Value;
  finally
    EndUpdate;
  end;
end;

procedure TACLResourceFont.SetName(const Value: TFontName);
begin
  BeginUpdate;
  try
    AssignedValues := AssignedValues + [rfavName];
    if Value <> FName then
    begin
      FName := Value;
      Changed;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLResourceFont.SetQuality(const Value: TFontQuality);
begin
  BeginUpdate;
  try
    AssignedValues := AssignedValues + [rfavQuality];
    if FQuality <> Value then
    begin
      FQuality := Value;
      Changed;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLResourceFont.SetHeight(const Value: Integer);
begin
  BeginUpdate;
  try
    AssignedValues := AssignedValues + [rfavHeight];
    if Value <> FHeight then
    begin
      FHeight := Value;
      Changed;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLResourceFont.SetSize(const Value: Integer);
begin
  Height := -MulDiv(Value, acDefaultDPI, 72);
end;

procedure TACLResourceFont.SetStyle(const Value: TFontStyles);
begin
  BeginUpdate;
  try
    AssignedValues := AssignedValues + [rfavStyle];
    if Value <> FStyle then
    begin
      FStyle := Value;
      Changed;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLResourceFont.ReadID(Reader: TReader);
begin
  ID := Reader.ReadString;
end;

procedure TACLResourceFont.WriteID(Writer: TWriter);
begin
  Writer.WriteString(ID);
end;

function TACLResourceFont.GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
var
  AProvider: IACLResourceProvider;
begin
  if Supports(Owner, IACLResourceProvider, AProvider) then
    Result := AProvider.GetResource(ID, AResourceClass, ASender)
  else
    Result := nil;
end;

{ TACLResourceInteger }

function TACLResourceInteger.CompareValues(const AValue1, AValue2: Integer): Boolean;
begin
  Result := AValue1 = AValue2;
end;

function TACLResourceInteger.ToStringCore: string;
begin
  Result := IntToStr(Value);
end;

{ TACLResourceTexture }

destructor TACLResourceTexture.Destroy;
begin
  SetImage(nil);
  FreeAndNil(FImageSet);
  inherited Destroy;
end;

procedure TACLResourceTexture.ApplyColorSchema(const AValue: TACLColorSchema);
begin
  if FColorSchema <> AValue then
  begin
    FColorSchema := AValue;
    UpdateImage;
  end;
end;

procedure TACLResourceTexture.Assign(Source: TPersistent);
begin
  if Source is TACLResourceTexture then
    inherited Assign(Source)
  else
  begin
    Overriden := True;
    if Source <> nil then
      ImageSet.Assign(Source)
    else
      ImageSet.Clear;
  end;
end;

procedure TACLResourceTexture.DoAssignCore(ASource: TACLResource; AAssignValue: Boolean);
begin
  AllowColoration := TACLResourceTexture(ASource).AllowColoration;
  Scalable := TACLResourceTexture(ASource).Scalable;
  if AAssignValue then
  begin
    FColorSchema := TACLResourceTexture(ASource).FColorSchema;
    ImageSet.Assign(TACLResourceTexture(ASource).ImageSet);
  end
  else
    ApplyColorSchema(TACLResourceTexture(ASource).FColorSchema);
end;

procedure TACLResourceTexture.DoMasterChanged;
begin
  inherited;

  if Master <> nil then
    FreeAndNil(FImageSet)
  else
    if (FImageSet = nil) and not IsDestroying then
    begin
      FImageSet := TACLSkinImageSet.Create;
      FImageSet.OnChange := SkinImageChangeHandler;
    end;

  UpdateImage;
end;

procedure TACLResourceTexture.DoResourceChanged(Sender: TObject; Resource: TACLResource);
begin
  inherited;
  UpdateImage;
end;

procedure TACLResourceTexture.DoTargetDpiChanged;
begin
  inherited;
  UpdateImage;
end;

procedure TACLResourceTexture.DataRead(Stream: TStream);
begin
  Overriden := True;
  ImageSet.LoadFromStream(Stream);
end;

procedure TACLResourceTexture.DataWrite(Stream: TStream);
begin
  ImageSet.SaveToStream(Stream);
end;

procedure TACLResourceTexture.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('Data', DataRead, DataWrite, IsTextureStored);
end;

function TACLResourceTexture.EqualsValuesCore(AResource: TACLResource): Boolean;
begin
  Result := ImageSet.Equals(TACLResourceTexture(AResource).ImageSet);
end;

procedure TACLResourceTexture.Initialize;
begin
  FScalable := TACLBoolean.Default;
  FImageDpi := acDefaultDpi;
  inherited Initialize;
  DoMasterChanged;
end;

procedure TACLResourceTexture.LoadFromBitmapResourceCore(AInstance: HINST; const AName: UnicodeString;
  const AMargins, AContentOffsets: TRect; AFrameCount: Integer; ALayout: TACLSkinImageLayout; AStretchMode: TACLStretchMode);
begin
  Overriden := True;
  FImageSet.BeginUpdate;
  try
    FImageSet.Clear;
    FImageSet[0].LoadFromResource(AInstance, AName, RT_BITMAP);
    FImageSet[0].Layout := ALayout;
    FImageSet[0].FrameCount := AFrameCount;
    FImageSet[0].Margins := AMargins;
    FImageSet[0].ContentOffsets := AContentOffsets;
    FImageSet[0].StretchMode := AStretchMode;
  finally
    FImageSet.EndUpdate;
  end;
end;

function TACLResourceTexture.ToStringCore: string;
begin
  if (Image <> nil) and not Image.Empty then
  begin
    with FrameSize do
      Result := Format('%dx%d', [cx, cy]);
  end
  else
    Result := 'No Image';
end;

procedure TACLResourceTexture.UpdateImage;
begin
  if not IsDestroying then
    SetImage(GetActualImage(TargetDPI, AllowColoration));
end;

procedure TACLResourceTexture.UpdateImageScaleFactor;
begin
  if Image <> nil then
  begin
    if ActualScalable then
      FImageDpi := MulDiv(acDefaultDpi, TargetDPI, Image.DPI)
    else
      FImageDpi := acDefaultDpi;
  end;
end;

procedure TACLResourceTexture.Clear;
begin
  Overriden := True;
  ImageSet.Clear;
end;

function TACLResourceTexture.HasFrame(AIndex: Integer): Boolean;
begin
  Result := Image.HasFrame(AIndex);
end;

function TACLResourceTexture.HitTest(const ABounds: TRect; X, Y: Integer): Boolean;
begin
  Result := Image.HitTest(ABounds, X, Y);
end;

procedure TACLResourceTexture.Draw(DC: HDC; const R: TRect; AFrameIndex: Integer; AEnabled: Boolean; AAlpha: Byte);
begin
  Image.Draw(DC, R, AFrameIndex, AEnabled, AAlpha);
end;

procedure TACLResourceTexture.Draw(DC: HDC; const R: TRect; AFrameIndex: Integer; ABorders: TACLBorders);
begin
  if (ABorders <> acAllBorders) and not acMarginIsEmpty(Margins) then
    DrawClipped(DC, R, acRectInflate(R, Margins, acAllBorders - ABorders), AFrameIndex)
  else
    Draw(DC, R, AFrameIndex);
end;

procedure TACLResourceTexture.DrawClipped(DC: HDC; const AClipRect, R: TRect; AFrameIndex: Integer; AAlpha: Byte);
var
  AClipRegion: HRGN;
begin
  AClipRegion := acSaveClipRegion(DC);
  try
    if acIntersectClipRegion(DC, AClipRect) then
      Draw(DC, R, AFrameIndex, True, AAlpha);
  finally
    acRestoreClipRegion(DC, AClipRegion);
  end;
end;

procedure TACLResourceTexture.InitailizeDefaults(const DefaultID: UnicodeString;
  AInstance: HINST; const AName: UnicodeString; const AMargins, AContentOffsets: TRect;
  AFrameCount: Integer; ALayout: TACLSkinImageLayout = ilHorizontal; AStretchMode: TACLStretchMode = isStretch);
begin
  inherited InitailizeDefaults(DefaultID);
  LoadFromBitmapResourceCore(AInstance, AName, AMargins, AContentOffsets, AFrameCount, ALayout, AStretchMode);
end;

procedure TACLResourceTexture.ImportFromImage(const AImage: TBitmap; DPI: Integer = acDefaultDPI);
begin
  Overriden := True;
  ImageSet.ImportFromImage(AImage, DPI);
end;

procedure TACLResourceTexture.ImportFromImageFile(const AFileName: string; DPI: Integer = acDefaultDPI);
begin
  Overriden := True;
  ImageSet.ImportFromImageFile(AFileName, DPI);
end;

procedure TACLResourceTexture.ImportFromImageResource(const AInstance: HINST;
  const AResName: string; AResType: PWideChar; DPI: Integer = acDefaultDPI);
var
  AStream: TStream;
begin
  AStream := TResourceStream.Create(AInstance, AResName, AResType);
  try
    ImportFromImageStream(AStream, DPI);
  finally
    AStream.Free;
  end;
end;

procedure TACLResourceTexture.ImportFromImageStream(const AStream: TStream; DPI: Integer = acDefaultDPI);
begin
  Overriden := True;
  ImageSet.ImportFromImageStream(AStream, DPI);
end;

function TACLResourceTexture.IsTextureStored: Boolean;
begin
  Result := Overriden and (ID = '');
end;

function TACLResourceTexture.IsValueStored: Boolean;
begin
  Result := IsTextureStored or (Scalable <> TACLBoolean.Default);
end;

procedure TACLResourceTexture.MakeUnique;
var
  AHandle: TACLSkinImageSet;
begin
  BeginUpdate;
  try
    if not Overriden or (ID <> '') then
    begin
      AHandle := ImageSet;
      Overriden := True;
      ImageSet.Assign(AHandle);
    end;
    ImageSet.MakeUnique;
  finally
    EndUpdate;
  end;
end;

function TACLResourceTexture.GetActualAllowColoration: Boolean;
begin
  if FAllowColoration <> TACLBoolean.Default then
    Result := FAllowColoration <> TACLBoolean.False
  else
    if Overriden then
      Result := GetDefaultAllowColoration
    else
      Result := TACLResourceTexture(Master).ActualAllowColoration;
end;

function TACLResourceTexture.GetActualColorSchema: TACLColorSchema;
begin
  if AllowColoration = TACLBoolean.False then
    Result := TACLColorSchema.Default
  else
    if Overriden then
    begin
      if ActualAllowColoration then
        Result := FColorSchema
      else
        Result := TACLColorSchema.Default;
    end
    else
      Result := TACLResourceTexture(Master).ActualColorSchema;
end;

function TACLResourceTexture.GetActualScalable: Boolean;
begin
  if Scalable <> TACLBoolean.Default then
    Result := Scalable <> TACLBoolean.False
  else
    if Overriden then
      Result := True
    else
      Result := TACLResourceTexture(Master).ActualScalable
end;

function TACLResourceTexture.GetDefaultAllowColoration: Boolean;
var
  AImage: TACLSkinImage;
begin
  //# for backward compatibility
  AImage := ImageSet.Get(acDefaultDPI);
  Result := (AImage = nil) or AImage.AllowColoration;
end;

function TACLResourceTexture.GetContentOffsets: TRect;
begin
  Result := dpiApply(Image.ContentOffsets, ImageDpi);
end;

function TACLResourceTexture.GetEmpty: Boolean;
begin
  Result := Image.Empty;
end;

function TACLResourceTexture.GetFrameCount: Integer;
begin
  Result := Image.FrameCount;
end;

function TACLResourceTexture.GetFrameHeight: Integer;
begin
  Result := dpiApply(Image.FrameHeight, ImageDpi);
end;

function TACLResourceTexture.GetFrameSize: TSize;
begin
  Result := dpiApply(Image.FrameSize, ImageDpi);
end;

function TACLResourceTexture.GetFrameWidth: Integer;
begin
  Result := dpiApply(Image.FrameWidth, ImageDpi);
end;

function TACLResourceTexture.GetHasAlpha: Boolean;
begin
  Result := Image.HasAlpha;
end;

function TACLResourceTexture.GetActualImage(ATargetDPI: Integer; AAllowColoration: TACLBoolean): TACLSkinImageSetItem;
begin
  if Overriden then
  begin
    if AAllowColoration = TACLBoolean.Default then
      AAllowColoration := TACLBoolean.From(GetDefaultAllowColoration);
    if AAllowColoration = TACLBoolean.True then
      Result := ImageSet.Get(ATargetDPI, FColorSchema)
    else
      Result := ImageSet.Get(ATargetDPI, TACLColorSchema.Default);
  end
  else
  begin
    if AAllowColoration = TACLBoolean.Default then
      AAllowColoration := AllowColoration;
    Result := TACLResourceTexture(Master).GetActualImage(ATargetDPI, AAllowColoration);
  end;
end;

function TACLResourceTexture.GetHitTestMode: TACLSkinImageHitTestMode;
begin
  Result := Image.HitTestMask;
end;

function TACLResourceTexture.GetImageSet: TACLSkinImageSet;
begin
  if Overriden then
    Result := FImageSet
  else
    Result := TACLResourceTexture(Master).ImageSet;
end;

function TACLResourceTexture.GetMargins: TRect;
begin
  Result := dpiApply(Image.Margins, ImageDpi);
end;

function TACLResourceTexture.GetOverriden: Boolean;
begin
  Result := Master = nil;
end;

function TACLResourceTexture.GetStretchMode: TACLStretchMode;
begin
  Result := Image.StretchMode;
end;

procedure TACLResourceTexture.SetAllowColoration(AValue: TACLBoolean);
begin
  if FAllowColoration <> AValue then
  begin
    FAllowColoration := AValue;
    UpdateImage;
  end;
end;

procedure TACLResourceTexture.SetImage(AImage: TACLSkinImageSetItem);
begin
  BeginUpdate;
  try
    if AImage <> FImage then
    begin
      if FImage <> nil then
      begin
        FImage.ReferenceRemove;
        FImage := nil;
      end;
      if AImage <> nil then
      begin
        FImage := AImage;
        FImage.ReferenceAdd;
      end;
      Changed;
    end;
    UpdateImageScaleFactor;
  finally
    EndUpdate;
  end;
end;

procedure TACLResourceTexture.SetOverriden(AValue: Boolean);
begin
  if AValue then
    ID := ''
  else
    ID := IDDefault;
end;

procedure TACLResourceTexture.SetScalable(AValue: TACLBoolean);
begin
  if FScalable <> AValue then
  begin
    FScalable := AValue;
    UpdateImageScaleFactor;
  end;
end;

procedure TACLResourceTexture.SkinImageChangeHandler(Sender: TObject);
begin
  BeginUpdate;
  try
    UpdateImage;
    Changed;
  finally
    EndUpdate;
  end;
end;

function TACLResourceTexture.GetResource(const ID: string; AResourceClass: TClass; ASender: TObject): TObject;
var
  AProvider: IACLResourceProvider;
begin
  if Supports(Owner, IACLResourceProvider, AProvider) then
    Result := AProvider.GetResource(ID, AResourceClass, ASender)
  else
    Result := nil;
end;

{ TACLGlyph }

procedure TACLGlyph.Draw(DC: HDC; const R: TRect; AEnabled: Boolean; AAlpha: Byte);
var
  ALayer: TACLBitmapLayer;
begin
  ALayer := TACLBitmapLayer.Create(Image.FrameSize);
  try
    Image.Draw(ALayer.Handle, ALayer.ClientRect, FrameIndex, AEnabled);
    ALayer.DrawBlend(DC, R, AAlpha, True);
  finally
    ALayer.Free;
  end;
end;

procedure TACLGlyph.DoChanged(AChanges: TACLPersistentChanges);
begin
  inherited;
  FrameIndex := FrameIndex;
end;

function TACLGlyph.GetResourceClass: TACLResourceClass;
begin
  Result := TACLResourceTexture;
end;

procedure TACLGlyph.SetFrameIndex(AValue: Integer);
begin
  AValue := Max(AValue, 0);
  if not Image.Empty then
    AValue := Min(AValue, FrameCount - 1);
  if FFrameIndex <> AValue then
  begin
    FFrameIndex := AValue;
    Changed([apcContent]);
  end;
end;

{ TACLResourceClassRepository }

class procedure TACLResourceClassRepository.Enum(AProc: TEnumProc);
var
  I: Integer;
begin
  if FItems <> nil then
  begin
    for I := 0 to FItems.Count - 1 do
      AProc(FItems.List[I]);
  end;
end;

class procedure TACLResourceClassRepository.Register(AClass: TACLResourceClass);
begin
  RegisterClass(AClass);
  if FItems = nil then
    FItems := TList.Create;
  FItems.Add(AClass);
end;

class procedure TACLResourceClassRepository.Unregister(AClass: TACLResourceClass);
begin
  UnRegisterClass(AClass);
  if FItems <> nil then
  begin
    FItems.Remove(AClass);
    if FItems.Count = 0 then
      FreeAndNil(FItems);
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// Style
//----------------------------------------------------------------------------------------------------------------------

{ TACLStyleMap<T> }

constructor TACLStyleMap<T>.Create(AOwner: TPersistent);
begin
  inherited Create([doOwnsValues]);
  FOwner := AOwner;
end;

procedure TACLStyleMap<T>.EnumResources(AEnumProc: TACLResourceEnumProc);
var
  AResource: TACLResource;
begin
  for AResource in Values do
    AEnumProc(AResource);
end;

procedure TACLStyleMap<T>.Assign(ASource: TACLStyleMap<T>);
var
  AKey: Integer;
begin
  Clear;
  for AKey in ASource.Keys do
    GetOrCreate(AKey).Assign(ASource.GetOrCreate(AKey));
end;

function TACLStyleMap<T>.GetOrCreate(Index: Integer): T;
begin
  if not TryGetValue(Index, TACLResource(Result)) then
  begin
    Result := T(TACLResourceClass(T).Create(FOwner));
    Add(Index, Result);
  end;
end;

procedure TACLStyleMap<T>.ResourceChanged(AResource: TACLResource);
var
  AValue: TACLResource;
begin
  for AValue in Values do
    AValue.ResourceChanged(AResource);
end;

procedure TACLStyleMap<T>.SetTargetDPI(AValue: Integer);
var
  AResource: TACLResource;
begin
  for AResource in Values do
    AResource.TargetDPI := AValue;
end;

{ TACLStyle }

constructor TACLStyle.Create(AOwner: TPersistent);
begin
  inherited Create;
  FOwner := AOwner;
  FTargetDPI := acDefaultDPI;
  FColors := TACLStyleColorsMap.Create(Self);
  FMargins := TACLStyleMap<TACLResourceMargins>.Create(Self);
  FTextures := TACLStyleMap<TACLResourceTexture>.Create(Self);
  FIntegers := TACLStyleMap<TACLResourceInteger>.Create(Self);
  FFonts := TACLStyleFontsMap.Create(Self);
  TACLRootResourceCollection.ListenerAdd(Self);
end;

destructor TACLStyle.Destroy;
begin
  FreeAndNil(FIntegers);
  FreeAndNil(FTextures);
  FreeAndNil(FMargins);
  FreeAndNil(FColors);
  FreeAndNil(FFonts);
  inherited Destroy;
end;

procedure TACLStyle.AfterConstruction;
begin
  inherited AfterConstruction;

  BeginUpdate;
  try
    InitializeResources;
  finally
    CancelUpdate;
  end;
end;

procedure TACLStyle.BeforeDestruction;
begin
  inherited BeforeDestruction;
  BeginUpdate;
  TACLRootResourceCollection.ListenerRemove(Self);
  Collection := nil;
end;

procedure TACLStyle.EnumResources(AEnumProc: TACLResourceEnumProc);
begin
  FColors.EnumResources(AEnumProc);
  FFonts.EnumResources(AEnumProc);
  FIntegers.EnumResources(AEnumProc);
  FMargins.EnumResources(AEnumProc);
  FTextures.EnumResources(AEnumProc);
end;

procedure TACLStyle.Reset;
begin
  BeginUpdate;
  try
    DoReset;
  finally
    EndUpdate;
  end;
end;

procedure TACLStyle.ApplyColorSchema(const AColorSchema: TACLColorSchema);
begin
  BeginUpdate;
  try
    EnumResources(
      procedure (const AResource: TACLResource)
      begin
        acApplyColorSchema(AResource, AColorSchema);
      end);
  finally
    EndUpdate;
  end;
end;

procedure TACLStyle.Refresh;
begin
  ResourceChanged(nil);
end;

class procedure TACLStyle.Refresh(AObject: TObject);
begin
  TRTTI.EnumClassProperties<TACLStyle>(AObject,
    procedure (const AStyle: TACLStyle)
    begin
      AStyle.Refresh;
    end, False, [mvPublished]);
end;

function TACLStyle.Scale(AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, TargetDPI, acDefaultDPI);
end;

procedure TACLStyle.SetTargetDPI(AValue: Integer);
begin
  if AValue <> FTargetDPI then
  begin
    BeginUpdate;
    try
      FTargetDPI := AValue;
      DoSetTargetDPI(FTargetDPI);
    finally
      EndUpdate;
    end;
  end;
end;

function TACLStyle.GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
var
  ACollection: TACLCustomResourceCollection;
  AIntf: IACLResourceCollection;
begin
  ACollection := FCollection;
  if (ACollection = nil) and Supports(FOwner, IACLResourceCollection, AIntf) then
    ACollection := AIntf.GetCollection;
  if (ACollection = nil) then
    ACollection := TACLRootResourceCollection.GetInstance;
  Result := ACollection.GetResource(ID, AResourceClass, ASender);
end;

procedure TACLStyle.DoAssign(ASource: TPersistent);
begin
  if ASource is TACLStyle then
  begin
    Collection := TACLStyle(ASource).Collection;
    DoAssignResources(TACLStyle(ASource));
    DoSetTargetDPI(FTargetDPI);
    Changed;
  end;
end;

procedure TACLStyle.DoAssignResources(ASource: TACLStyle);
begin
  FColors.Assign(ASource.FColors);
  FMargins.Assign(ASource.FMargins);
  FTextures.Assign(ASource.FTextures);
  FFonts.Assign(ASource.FFonts);
  FIntegers.Assign(ASource.FIntegers);
end;

procedure TACLStyle.DoChanged(AChanges: TACLPersistentChanges);
var
  AIntf: IACLResourceChangeListener;
begin
  BeginUpdate;
  try
    if Supports(FOwner, IACLResourceChangeListener, AIntf) then
      AIntf.ResourceChanged(Self, nil);
    //# too slowly in Design time
    //# acDesignerSetModified(FOwner);
  finally
    CancelUpdate;
  end;
end;

procedure TACLStyle.DoReset;
begin
  FColors.Clear;
  FFonts.Clear;
  FIntegers.Clear;
  FMargins.Clear;
  FTextures.Clear;
  InitializeResources;
end;

procedure TACLStyle.DoResourceChanged(AResource: TACLResource = nil);
begin
  FColors.ResourceChanged(AResource);
  FMargins.ResourceChanged(AResource);
  FTextures.ResourceChanged(AResource);
  FFonts.ResourceChanged(AResource);
  FIntegers.ResourceChanged(AResource);
end;

procedure TACLStyle.DoSetTargetDPI(AValue: Integer);
begin
  FColors.SetTargetDPI(AValue);
  FFonts.SetTargetDPI(AValue);
  FIntegers.SetTargetDPI(AValue);
  FMargins.SetTargetDPI(AValue);
  FTextures.SetTargetDPI(AValue);
end;

procedure TACLStyle.InitializeResources;
begin
  // do nothing
end;

function TACLStyle.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

function TACLStyle.GetColor(AIndex: Integer): TACLResourceColor;
begin
  Result := FColors.GetOrCreate(AIndex);
end;

function TACLStyle.GetFont(AIndex: Integer): TACLResourceFont;
begin
  Result := FFonts.GetOrCreate(AIndex);
end;

function TACLStyle.GetInteger(AIndex: Integer): TACLResourceInteger;
begin
  Result := FIntegers.GetOrCreate(AIndex);
end;

function TACLStyle.GetMargins(AIndex: Integer): TACLResourceMargins;
begin
  Result := FMargins.GetOrCreate(AIndex);
end;

function TACLStyle.GetTexture(AIndex: Integer): TACLResourceTexture;
begin
  Result := FTextures.GetOrCreate(AIndex);
end;

function TACLStyle.IsColorStored(AIndex: Integer): Boolean;
begin
  Result := not GetColor(AIndex).IsDefault;
end;

function TACLStyle.IsFontStored(AIndex: Integer): Boolean;
begin
  Result := not GetFont(AIndex).IsDefault;
end;

function TACLStyle.IsIntegerStored(AIndex: Integer): Boolean;
begin
  Result := not GetInteger(AIndex).IsDefault;
end;

function TACLStyle.IsMarginsStored(AIndex: Integer): Boolean;
begin
  Result := not GetMargins(AIndex).IsDefault;
end;

function TACLStyle.IsTextureStored(AIndex: Integer): Boolean;
begin
  Result := not GetTexture(AIndex).IsDefault;
end;

procedure TACLStyle.SetColor(AIndex: Integer; AValue: TACLResourceColor);
begin
  GetColor(AIndex).Assign(AValue);
end;

procedure TACLStyle.SetFont(AIndex: Integer; AValue: TACLResourceFont);
begin
  GetFont(AIndex).Assign(AValue);
end;

procedure TACLStyle.SetInteger(AIndex: Integer; AValue: TACLResourceInteger);
begin
  GetInteger(AIndex).Assign(AValue);
end;

procedure TACLStyle.SetMargins(AIndex: Integer; AValue: TACLResourceMargins);
begin
  GetMargins(AIndex).Assign(AValue);
end;

procedure TACLStyle.SetTexture(AIndex: Integer; AValue: TACLResourceTexture);
begin
  GetTexture(AIndex).Assign(AValue);
end;

procedure TACLStyle.ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
begin
  if (Resource = nil) or (Resource.Owner <> Self) then
  begin
    BeginUpdate;
    try
      DoResourceChanged(Resource);
    finally
      EndUpdate;
    end;
  end
  else
    Changed;
end;

function TACLStyle.GetCollection: TACLCustomResourceCollection;
begin
  Result := FCollection;
end;

procedure TACLStyle.Removing(AObject: TObject);
begin
  if AObject = Collection then
    Collection := nil;
end;

procedure TACLStyle.SetCollection(const Value: TACLCustomResourceCollection);
begin
  if FCollection <> Value then
  begin
    if FCollection <> nil then
    begin
      FCollection.ListenerRemove(Self);
      FCollection := nil;
    end;
    if Value <> nil then
    begin
      FCollection := Value;
      FCollection.ListenerAdd(Self);
    end;
    ResourceChanged(Self);
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// Collection
//----------------------------------------------------------------------------------------------------------------------

{ TACLResourceCollectionItem }

destructor TACLResourceCollectionItem.Destroy;
begin
  ID := '';
  FreeAndNil(FResource);
  inherited Destroy;
end;

procedure TACLResourceCollectionItem.Assign(Source: TPersistent);
begin
  if Source is TACLResourceCollectionItem then
  begin
    ResourceClassName := TACLResourceCollectionItem(Source).ResourceClassName;
    Resource := TACLResourceCollectionItem(Source).Resource;
    Description := TACLResourceCollectionItem(Source).Description;
    ID := TACLResourceCollectionItem(Source).ID;
  end;
end;

function TACLResourceCollectionItem.GetDisplayName: string;
begin
  if FResource <> nil then
    Result := FResource.TypeName + ' - ' + IfThenW(Description, ID)
  else
    Result := '<empty>';
end;

function TACLResourceCollectionItem.GetCollection: TACLResourceCollectionItems;
begin
  Result := TACLResourceCollectionItems(inherited Collection);
end;

function TACLResourceCollectionItem.GetResourceClassName: string;
begin
  if FResource <> nil then
    Result := FResource.ClassName
  else
    Result := '';
end;

procedure TACLResourceCollectionItem.SetID(const Value: string);
begin
  if FID <> Value then
  begin
    if FID <> '' then
      Collection.FIndex.Remove(ID);
    FID := Value;
    if FID <> '' then
      Collection.FIndex.AddOrSetValue(ID, Self);
    Changed(True);
  end;
end;

procedure TACLResourceCollectionItem.SetResource(AValue: TACLResource);
begin
  if FResource <> nil then
    FResource.Assign(AValue);
end;

procedure TACLResourceCollectionItem.SetResourceClassName(const AValue: string);
var
  AClass: TPersistentClass;
begin
  AClass := GetClass(AValue);
  if AClass = nil then
    AClass := GetClass(TACLResource.ClassName + AValue);
  if (AClass <> nil) and not AClass.InheritsFrom(TACLResource) or (AClass = nil) and (AValue <> '') then
    raise EInvalidCast.CreateFmt('The %s is not valid resource', [AValue]);
  FreeAndNil(FResource);
  FResource := TACLResourceClass(AClass).Create(Self);
  Changed(False);
end;

function TACLResourceCollectionItem.GetCollectionEx: TACLCustomResourceCollection;
begin
  Result := Collection.Owner;
end;

function TACLResourceCollectionItem.GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
begin
  Result := Collection.Owner.GetResource(ID, AResourceClass, ASender);
end;

procedure TACLResourceCollectionItem.ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
begin
  Changed(False);
end;

{ TACLResourceCollectionItems }

constructor TACLResourceCollectionItems.Create(AOwner: TACLCustomResourceCollection);
begin
  FOwner := AOwner;
  inherited Create(TACLResourceCollectionItem);
  FIndex := TDictionary<string, TACLResourceCollectionItem>.Create;
end;

destructor TACLResourceCollectionItems.Destroy;
begin
  FreeAndNil(FIndex);
  inherited;
end;

function TACLResourceCollectionItems.Add(const ID: string; AClass: TACLResourceClass): TACLResource;
begin
  BeginUpdate;
  try
    Result := TACLResource(GetResource(ID, AClass));
    if Result = nil then
      Result := AddCore(ID, AClass).Resource;
    if Result = nil then
      raise EInvalidOperation.CreateFmt('The "%s" is unknown resource', [AClass.ClassName]);
  finally
    EndUpdate;
  end;
end;

procedure TACLResourceCollectionItems.Add(AItems: TACLResourceCollectionItems);
begin
  BeginUpdate;
  try
    AItems.EnumResources(
      procedure (const AResource: TACLResource)
      begin
        AddResource(AResource)
      end);
  finally
    EndUpdate;
  end;
end;

procedure TACLResourceCollectionItems.Add(AStyle: TACLStyle);
begin
  BeginUpdate;
  try
    AStyle.EnumResources(
      procedure (const AResource: TACLResource)
      begin
        AddResource(AResource)
      end);
  finally
    EndUpdate;
  end;
end;

function TACLResourceCollectionItems.Add<T>(const ID: string): T;
begin
  Result := T(Add(ID, TACLResourceClass(T)));
end;

function TACLResourceCollectionItems.AddColor(const ID: string; AColor: TColor): TACLResourceColor;
begin
  BeginUpdate;
  try
    Result := Add<TACLResourceColor>(ID);
    Result.AsColor := AColor;
  finally
    EndUpdate;
  end;
end;

function TACLResourceCollectionItems.AddMargins(const ID: string; const AValue: TRect): TACLResourceMargins;
begin
  BeginUpdate;
  try
    Result := Add<TACLResourceMargins>(ID);
    Result.Value := AValue;
  finally
    EndUpdate;
  end;
end;

function TACLResourceCollectionItems.AddResource(AResource: TACLResource; ID: string = ''): TACLResource;
begin
  BeginUpdate;
  try
    if ID = '' then
      ID := AResource.IDDefault;
    Result := Add(ID, AResource.GetResourceClass);
    Result.Assign(AResource);
  finally
    EndUpdate;
  end;
end;

function TACLResourceCollectionItems.AddTexture(const ID: string; ASkinImage: TACLSkinImageSet): TACLResourceTexture;
begin
  BeginUpdate;
  try
    Result := Add<TACLResourceTexture>(ID);
    Result.Overriden := True;
    Result.ImageSet.Assign(ASkinImage);
  finally
    EndUpdate;
  end;
end;

function TACLResourceCollectionItems.AddTexture(const ID: string;
  const AResInstance: HINST; const AResName: UnicodeString;
  const AMargins, AContentOffsets: TRect; AFrameCount: Integer;
  const ALayout: TACLSkinImageLayout = ilHorizontal;
  const AStretchMode: TACLStretchMode = isStretch): TACLResourceTexture;
begin
  BeginUpdate;
  try
    Result := Add<TACLResourceTexture>(ID);
    Result.Overriden := True;
    Result.LoadFromBitmapResourceCore(AResInstance, AResName, AMargins, AContentOffsets, AFrameCount, ALayout, AStretchMode);
  finally
    EndUpdate;
  end;
end;

function TACLResourceCollectionItems.AddRemap(const ID, MasterID: string; AClass: TACLResourceClass): TACLResource;
begin
  BeginUpdate;
  try
    Result := Add(ID, AClass);
    Result.ID := MasterID;
  finally
    EndUpdate;
  end;
end;

procedure TACLResourceCollectionItems.EnumResources(AProc: TACLResourceEnumProc);
var
  AItem: TACLResourceCollectionItem;
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    AItem := Items[I];
    if AItem.Resource <> nil then
      AProc(AItem.Resource);
  end;
end;

procedure TACLResourceCollectionItems.EnumResources(AResourceClass: TClass; AProc: TEnumProc);
var
  AItem: TACLResourceCollectionItem;
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    AItem := Items[I];
    if (AItem.Resource <> nil) and ((AResourceClass = nil) or AItem.Resource.InheritsFrom(AResourceClass)) then
    begin
      if AProc(AItem) then
        Break;
    end;
  end;
end;

function TACLResourceCollectionItems.GetResource(const ID: string): TACLResourceCollectionItem;
var
  AItem: TACLResourceCollectionItem;
begin
  if FIndex.TryGetValue(ID, AItem) then
    Result := AItem
  else
    Result := nil;
end;

function TACLResourceCollectionItems.GetResource(const ID: string; AResourceClass: TClass): TObject;
var
  AItem: TACLResourceCollectionItem;
begin
  if FIndex.TryGetValue(ID, AItem) then
  begin
    if (AItem.Resource <> nil) and AItem.Resource.InheritsFrom(AResourceClass) then
      Exit(AItem.Resource);
  end;
  Result := nil;
end;

function TACLResourceCollectionItems.AddCore(const ID: string; AClass: TACLResourceClass): TACLResourceCollectionItem;
begin
  BeginUpdate;
  try
    Result := TACLResourceCollectionItem(inherited Add);
    Result.ResourceClassName := AClass.ClassName;
    Result.ID := ID;
  finally
    EndUpdate;
  end;
end;

function TACLResourceCollectionItems.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TACLResourceCollectionItems.UpdateCore(Item: TCollectionItem);
begin
  inherited UpdateCore(Item);

  if Item <> nil then
    FOwner.ResourceChanged(TACLResourceCollectionItem(Item).Resource)
  else
    FOwner.ResourceChanged;
end;

function TACLResourceCollectionItems.GetItem(Index: Integer): TACLResourceCollectionItem;
begin
  Result := TACLResourceCollectionItem(inherited Items[Index]);
end;

{ TACLCustomResourceCollection }

constructor TACLCustomResourceCollection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FListeners := TACLResourceListenerList.Create;
  FItems := TACLResourceCollectionItems.Create(Self);
  TACLApplication.ListenerAdd(Self);
end;

destructor TACLCustomResourceCollection.Destroy;
begin
  FreeAndNil(FListeners);
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TACLCustomResourceCollection.BeforeDestruction;
begin
  TACLApplication.ListenerRemove(Self);
  FListeners.NotifyRemoving(Self);
  FListeners.Clear;
  inherited BeforeDestruction;
  FItems.Clear;
end;

procedure TACLCustomResourceCollection.EnumResources(AProc: TACLResourceEnumProc);
begin
  Items.EnumResources(AProc);
end;

procedure TACLCustomResourceCollection.EnumResources(AResourceClass: TClass; AProc: TACLResourceCollectionItems.TEnumProc);
begin
  Items.EnumResources(AResourceClass, AProc);
end;

procedure TACLCustomResourceCollection.EnumResources(AResourceClass: TClass; AList: TACLStringList);
begin
  EnumResources(AResourceClass,
    function (AResource: TACLResourceCollectionItem): Boolean
    begin
      AList.Add(AResource.ID, AResource.Resource);
      Result := False;
    end);
  AList.SortLogical;
end;

procedure TACLCustomResourceCollection.EnumResources(AResourceClass: TClass; AList: TStrings);
var
  ATempList: TACLStringList;
  I: Integer;
begin
  ATempList := TACLStringList.Create;
  try
    EnumResources(AResourceClass, ATempList);
    for I := 0 to ATempList.Count - 1 do
      AList.AddObject(ATempList[I], ATempList.Objects[I]);
  finally
    ATempList.Free;
  end;
end;

procedure TACLCustomResourceCollection.ApplyColorSchema(const AColorSchema: TACLColorSchema);
var
  I: Integer;
begin
  BeginUpdate;
  try
    for I := 0 to Items.Count - 1 do
      acApplyColorSchema(Items[I].Resource, AColorSchema);
  finally
    EndUpdate;
  end;
end;

procedure TACLCustomResourceCollection.BeginUpdate;
begin
  Listeners.NotifyBeginUpdate;
  Items.BeginUpdate;
end;

procedure TACLCustomResourceCollection.EndUpdate;
begin
  Items.EndUpdate;
  Listeners.NotifyEndUpdate;
end;

function TACLCustomResourceCollection.GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
begin
  Result := Items.GetResource(ID, AResourceClass);
  if (Result = nil) or (Result = ASender) then
    Result := GetDefaultResource(ID, AResourceClass, ASender);
end;

procedure TACLCustomResourceCollection.ListenerAdd(AListener: IACLResourceChangeListener);
begin
  FListeners.Add(AListener);
end;

procedure TACLCustomResourceCollection.ListenerRemove(AListener: IACLResourceChangeListener);
begin
  if FListeners <> nil then
    FListeners.Remove(AListener);
end;

procedure TACLCustomResourceCollection.LoadFromFile(const AFileName: string);
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

procedure TACLCustomResourceCollection.LoadFromResource(AInstance: HINST; const AName: string);
var
  AStream: TStream;
begin
  AStream := TResourceStream.Create(AInstance, AName, RT_RCDATA);
  try
    LoadFromStream(AStream);
  finally
    AStream.Free;
  end;
end;

procedure TACLCustomResourceCollection.LoadFromStream(AStream: TStream);
begin
  BeginUpdate;
  try
    Items.Clear;
    AStream.ReadComponent(Self);
  finally
    EndUpdate;
  end;
end;

procedure TACLCustomResourceCollection.SaveToFile(const AFileName: string);
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

procedure TACLCustomResourceCollection.SaveToStream(AStream: TStream);
begin
  AStream.WriteComponent(Self);
end;

function TACLCustomResourceCollection.GetDefaultResource(
  const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
begin
  Result := nil;
end;

procedure TACLCustomResourceCollection.ResourceChanged(AResource: TACLResource);
begin
  BeginUpdate;
  try
    EnumResources(
      procedure (const AResource: TACLResource)
      begin
        AResource.DoFullRefresh;
      end);

    FListeners.NotifyResourceChanged(Self, AResource);
    acDesignerSetModified(Self);
  finally
    EndUpdate
  end;
end;

procedure TACLCustomResourceCollection.ApplicationSettingsChanged(AChanges: TACLApplicationChanges);
begin
  if acColorSchema in AChanges then
    ApplyColorSchema(TACLApplication.ColorSchema);
end;

procedure TACLCustomResourceCollection._ResourceChanged(Sender: TObject; Resource: TACLResource);
begin
  ResourceChanged(Resource);
end;

procedure TACLCustomResourceCollection.SetItems(AValue: TACLResourceCollectionItems);
begin
  FItems.Assign(AValue);
end;

{ TACLResourceCollection }

procedure TACLResourceCollection.BeforeDestruction;
begin
  inherited;
  MasterCollection := nil;
end;

function TACLResourceCollection.GetDefaultResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
begin
  if MasterCollection <> nil then
    Result := MasterCollection.GetResource(ID, AResourceClass, ASender)
  else
    Result := TACLRootResourceCollection.GetResource(ID, AResourceClass, ASender);
end;

procedure TACLResourceCollection.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = MasterCollection) then
    MasterCollection := nil;
end;

procedure TACLResourceCollection.SetMasterCollection(const AValue: TACLCustomResourceCollection);
begin
  if acResourceCollectionFieldSet(FMasterCollection, Self, Self, AValue) then
    ResourceChanged;
end;

{ TACLRootResourceCollection }

class destructor TACLRootResourceCollection.Destroy;
begin
  FFinalized := True;
  if Application.ShowHint then
  begin
    Application.ShowHint := False; // to destroy HintWindow instance
    Application.ShowHint := True;
  end;
  FreeAndNil(FInstance);
end;

class function TACLRootResourceCollection.GetInstance: TACLCustomResourceCollection;
begin
  if (FInstance = nil) and not FFinalized then
  begin
    FInstance := TACLRootResourceCollectionImpl.Create;
    InitializeCursors;
  end;
  Result := FInstance;
end;

class function TACLRootResourceCollection.GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
begin
  Result := GetInstance.GetResource(ID, AResourceClass, ASender)
end;

class function TACLRootResourceCollection.GetResource(const ID: string; AResourceClass: TClass; ASender: TObject; out AResource): Boolean;
begin
  TObject(AResource) := GetResource(ID, AResourceClass, ASender);
  Result := TObject(AResource) <> nil;
end;

class function TACLRootResourceCollection.HasInstance: Boolean;
begin
  Result := FInstance <> nil;
end;

class procedure TACLRootResourceCollection.ListenerAdd(AListener: IACLResourceChangeListener);
begin
  GetInstance.ListenerAdd(AListener);
end;

class procedure TACLRootResourceCollection.ListenerRemove(AListener: IACLResourceChangeListener);
begin
  if FInstance <> nil then
    FInstance.ListenerRemove(AListener);
end;

class procedure TACLRootResourceCollection.InitializeCursors;

  procedure DoSetCursor(ID: Integer; ACursor: HCURSOR);
  begin
    if ACursor <> 0 then
      Screen.Cursors[ID] := ACursor;
  end;

begin
  DoSetCursor(crNo, LoadCursor(0, IDC_NO));
  DoSetCursor(crAppStart, LoadCursor(0, IDC_APPSTARTING));
  DoSetCursor(crHandPoint, LoadCursor(0, IDC_HAND));
  DoSetCursor(crHourGlass, LoadCursor(0, IDC_WAIT));
  DoSetCursor(crSizeAll, LoadCursor(0, IDC_SIZEALL));
  DoSetCursor(crSizeNESW, LoadCursor(0, IDC_SIZENESW));
  DoSetCursor(crSizeNS, LoadCursor(0, IDC_SIZENS));
  DoSetCursor(crSizeNWSE, LoadCursor(0, IDC_SIZENWSE));
  DoSetCursor(crSizeWE, LoadCursor(0, IDC_SIZEWE));
  DoSetCursor(crNoDrop, LoadCursor(0, IDC_NO));
  DoSetCursor(crHSplit, LoadCursor(0, IDC_SIZEWE));
  DoSetCursor(crVSplit, LoadCursor(0, IDC_SIZENS));
  DoSetCursor(crDrag, LoadCursor(LoadLibrary('ole32.dll'), MakeIntResource(3)));
  DoSetCursor(crRemove, LoadCursor(HInstance, 'CR_REMOVE'));
  DoSetCursor(crDragLink, LoadCursor(HInstance, 'CR_DRAGLINK'));
end;

{ TACLRootResourceCollectionImpl }

constructor TACLRootResourceCollectionImpl.Create;
begin
  inherited Create(nil);
  InitializeResources;
end;

procedure TACLRootResourceCollectionImpl.InitializeResources;
begin
  BeginUpdate;
  try
    LoadFromResource(HInstance, 'ACLDEFAULTSKIN' + IfThenW(TACLApplication.IsDarkMode, '_DARK'));
    if IsWin11OrLater then
    begin
      InheritIfNecessary('Buttons.Textures.Button', '.W11');
      InheritIfNecessary('Popup.Margins.Borders', '.W11');
      InheritIfNecessary('Popup.Margins.CornerRadius', '.W11');
      InheritIfNecessary('Slider.Textures.Thumb', '.W11');
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLRootResourceCollectionImpl.ApplicationSettingsChanged(AChanges: TACLApplicationChanges);
begin
  if acDarkMode in AChanges then
    InitializeResources;
  inherited;
end;

procedure TACLRootResourceCollectionImpl.InheritIfNecessary(const AResourceName, ASuffix: string);
var
  AResource: TACLResourceCollectionItem;
begin
  AResource := Items.GetResource(AResourceName);
  if AResource <> nil then
  begin
    if Items.GetResource(AResourceName + ASuffix) <> nil then
      AResource.Resource.ID := AResourceName + ASuffix;
  end;
end;

initialization
  TACLResourceClassRepository.Register(TACLResourceColor);
  TACLResourceClassRepository.Register(TACLResourceFont);
  TACLResourceClassRepository.Register(TACLResourceMargins);
  TACLResourceClassRepository.Register(TACLResourceTexture);
  TACLResourceClassRepository.Register(TACLResourceInteger);

finalization
  TACLResourceClassRepository.Unregister(TACLResourceColor);
  TACLResourceClassRepository.Unregister(TACLResourceFont);
  TACLResourceClassRepository.Unregister(TACLResourceMargins);
  TACLResourceClassRepository.Unregister(TACLResourceTexture);
  TACLResourceClassRepository.Unregister(TACLResourceInteger);
end.
