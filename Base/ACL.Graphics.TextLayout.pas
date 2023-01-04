{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*     Formatted Text based on BB Codes      *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.TextLayout;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.UITypes,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Math,
  System.SysUtils,
  System.Types,
  System.RegularExpressions,
  // VCL
  Vcl.Graphics,
  // ACL
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Parsers,
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics,
{$IFDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
  ACL.Graphics.FontCache,
{$ENDIF}
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Shell,
  ACL.Utils.Strings;

type
  TACLTextImporter = class;
  TACLTextLayoutBlock = class;
  TACLTextLayoutBlockList = class;
  TACLTextLayoutBlockStyleHyperlink = class;
  TACLTextLayoutExporter = class;
  TACLTextLayoutHitTest = class;

  TACLTextReadingDirection = (trdNeutral, trdLeftToRight, trdRightToLeft);

  { TACLTextFormatSettings }

  TACLTextFormatSettings = record
    AllowAutoEmailDetect: Boolean;
    AllowAutoURLDetect: Boolean;
    AllowCppLikeLineBreaks: Boolean; // support for "\n"
    AllowFormatting: Boolean;

    class function Default: TACLTextFormatSettings; static;
    class function PlainText: TACLTextFormatSettings; static;
  end;

  TACLTextLayoutOption = (tloAutoHeight, tloAutoWidth, tloEditControl, tloEndEllipsis, tloWordWrap);
  TACLTextLayoutOptions = set of TACLTextLayoutOption;

  { TACLTextLayout }

  TACLTextLayout = class
  strict private
    FBounds: TRect;
    FFont: TFont;
    FHorzAlignment: TAlignment;
    FOptions: TACLTextLayoutOptions;
    FText: string;
    FVertAlignment: TVerticalAlignment;

    procedure SetBounds(const AValue: TRect);
    procedure SetOptions(AOptions: TACLTextLayoutOptions);
    procedure SetHorzAlignment(AValue: TAlignment);
    procedure SetVertAlignment(AValue: TVerticalAlignment);
  protected
    FBlocks: TACLTextLayoutBlockList;
    FLayout: TACLTextLayoutBlockList;
    FLayoutIsDirty: Boolean;
    FTruncated: Boolean;

    procedure ApplyAlignment(const AOrigin: TPoint; AMaxWidth, AMaxHeight: Integer;
      AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment);
    procedure CalculateCore(AMaxWidth, AMaxHeight: Integer); virtual;
    function CreateImporter(const AFormatSettings: TACLTextFormatSettings): TACLTextImporter; virtual;
    function CreateLayoutCalculator(AWidth, AHeight: Integer): TACLTextLayoutExporter; virtual;
    function CreateRender(ACanvas: TCanvas): TACLTextLayoutExporter; virtual;
    procedure DrawCore(ACanvas: TCanvas); virtual;

    function GetDefaultHyperLinkColor: TColor; virtual;
    function GetDefaultTextColor: TColor; virtual;
  public
    constructor Create(AFont: TFont);
    destructor Destroy; override;
    procedure Calculate;
    procedure Draw(ACanvas: TCanvas); overload;
    procedure Draw(ACanvas: TCanvas; const AClipRect: TRect); overload;
    procedure DrawTo(ACanvas: TCanvas; const AClipRect: TRect; const AOrigin: TPoint);
    function FindBlock(APositionInText: Integer; out ABlock: TACLTextLayoutBlock): Boolean;
    function FindHyperlink(const P: TPoint; out AHyperlink: TACLTextLayoutBlockStyleHyperlink): Boolean;
    procedure HitTest(const P: TPoint; AHitTest: TACLTextLayoutHitTest);
    function IsTruncated: Boolean;
    function MeasureSize: TSize; virtual;
    procedure Refresh;
    procedure SetOption(AOption: TACLTextLayoutOption; AState: Boolean);
    procedure SetText(const AText: string; const AFormatSettings: TACLTextFormatSettings);
    function ToString: string; override;
    //
    property Bounds: TRect read FBounds write SetBounds;
    property Font: TFont read FFont;
    property HorzAlignment: TAlignment read FHorzAlignment write SetHorzAlignment;
    property Options: TACLTextLayoutOptions read FOptions write SetOptions;
    property Text: string read FText;
    property VertAlignment: TVerticalAlignment read FVertAlignment write SetVertAlignment;
  end;

  { TACLTextLayoutBlock }

  TACLTextLayoutBlockClass = class of TACLTextLayoutBlock;
  TACLTextLayoutBlock = class abstract
  protected
    FBounds: TRect;
    FLength: Word;
    FPositionInText: Integer; // 1-based
  public
    function Export(AExporter: TACLTextLayoutExporter): Boolean; dynamic;
    procedure Offset(ADeltaX, ADeltaY: Integer); dynamic;
    procedure ReduceWidth(AMaxRight: Integer); virtual;
    //
    property Bounds: TRect read FBounds;
  end;

  { TACLTextLayoutBlockList }

  TACLTextLayoutBlockList = class(TACLObjectList<TACLTextLayoutBlock>)
  strict private
    function GetBoundingRect: TRect;
  public
    function Export(AExporter: TACLTextLayoutExporter; AFreeExporter: Boolean): Boolean;
    procedure Offset(ADeltaX, ADeltaY: Integer);
    //
    property BoundingRect: TRect read GetBoundingRect;
  end;

  { TACLTextLayoutBlockLineBreak }

  TACLTextLayoutBlockLineBreak = class(TACLTextLayoutBlock)
  public
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
  end;

  { TACLTextLayoutBlockSpace }

  TACLTextLayoutBlockSpace = class(TACLTextLayoutBlock)
  public
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
  end;

  { TACLTextLayoutBlockText }

  TACLTextLayoutBlockText = class(TACLTextLayoutBlock)
  strict private
  {$IFDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
    function GetTextSize: TSize; inline;
  {$ENDIF}
  protected
  {$IFDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
    FTextViewInfo: TACLTextViewInfo;
  {$ELSE}
    FCharacterCount: Integer;
    FCharacterWidths: PInteger;
    FTextSize: TSize;
  {$ENDIF}
  {$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
    FReadingDirection: TACLTextReadingDirection;
  {$ENDIF}
    FText: PWideChar;
    FVisibleLength: Integer;
  public
    destructor Destroy; override;
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    procedure Flush; inline;
    procedure ReduceWidth(AMaxRight: Integer); override;
    function ToString: string; override;

  {$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
    property ReadingDirection: TACLTextReadingDirection read FReadingDirection;
  {$ENDIF}
    property Text: PWideChar read FText;
    property TextLength: Word read FLength;
  {$IFDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
    property TextSize: TSize read GetTextSize;
    property TextViewInfo: TACLTextViewInfo read FTextViewInfo;
  {$ELSE}
    property TextSize: TSize read FTextSize;
  {$ENDIF}
    property VisibleLength: Integer read FVisibleLength;
  end;

  { TACLTextLayoutBlockStyle }

  TACLTextLayoutBlockStyleClass = class of TACLTextLayoutBlockStyle;
  TACLTextLayoutBlockStyle = class(TACLTextLayoutBlock)
  strict private
    FIsSetMode: Boolean;
  protected
    procedure AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout); virtual;
    procedure SetParameters(const AParameters: string); virtual;
    //
    property IsSetMode: Boolean read FIsSetMode;
  public
    constructor Create(AIsSetMode: Boolean);
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
  end;

  { TACLTextLayoutBlockStyleStack }

  TACLTextLayoutBlockStyleStack = class
  strict private
    FList: TList;
    FModified: Boolean;

    function GetCount: Integer;
    function GetItem(Index: Integer): TACLTextLayoutBlock;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(AStyle: TACLTextLayoutBlockStyle);
    procedure AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout);
    procedure Assign(ASource: TACLTextLayoutBlockStyleStack);
    procedure Clear;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TACLTextLayoutBlock read GetItem; default;
    property Modified: Boolean read FModified write FModified;
  end;

  { TACLTextLayoutBlockStyleBold }

  TACLTextLayoutBlockStyleBold = class(TACLTextLayoutBlockStyle)
  public
    procedure AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout); override;
  end;

  { TACLTextLayoutBlockStyleColor }

  TACLTextLayoutBlockStyleColor = class(TACLTextLayoutBlockStyle)
  protected
    FColor: TColor;

    procedure AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout); override;
    procedure SetParameters(const AParameters: string); override;
  end;

  { TACLTextLayoutBlockStyleFill }

  TACLTextLayoutBlockStyleFill = class(TACLTextLayoutBlockStyleColor)
  protected
    procedure AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout); override;
  end;

  { TACLTextLayoutBlockStyleHyperlink }

  TACLTextLayoutBlockStyleHyperlink = class(TACLTextLayoutBlockStyle)
  protected
    FHyperlink: string;

    procedure AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout); override;
    procedure SetParameters(const AParameters: string); override;
  public
    property Hyperlink: string read FHyperlink;
  end;

  { TACLTextLayoutBlockStyleItalic }

  TACLTextLayoutBlockStyleItalic = class(TACLTextLayoutBlockStyle)
  public
    procedure AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout); override;
  end;

  { TACLTextLayoutBlockStyleStrikeOut }

  TACLTextLayoutBlockStyleStrikeOut = class(TACLTextLayoutBlockStyle)
  public
    procedure AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout); override;
  end;

  { TACLTextLayoutBlockStyleUnderline }

  TACLTextLayoutBlockStyleUnderline = class(TACLTextLayoutBlockStyle)
  public
    procedure AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout); override;
  end;

  { TACLTextLayoutRow }

  TACLTextLayoutRow = class(TACLTextLayoutBlock)
  strict private
    FBlocks: TACLTextLayoutBlockList;
    FEndEllipsis: TACLTextLayoutBlock;

    procedure SetEndEllipsis(AValue: TACLTextLayoutBlock);
  public
    constructor Create;
    destructor Destroy; override;
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    procedure Offset(ADeltaX, ADeltaY: Integer); override;

    property Blocks: TACLTextLayoutBlockList read FBlocks;
    property EndEllipsis: TACLTextLayoutBlock read FEndEllipsis write SetEndEllipsis;
  end;

  { TACLTextLayoutExporter }

  TACLTextLayoutExporter = class abstract
  strict private
    FOwner: TACLTextLayout;
  protected
    function AddLineBreak: Boolean; dynamic;
    function AddSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; dynamic;
    function AddStyle(ABlock: TACLTextLayoutBlockStyle): Boolean; dynamic;
    function AddText(ABlock: TACLTextLayoutBlockText): Boolean; dynamic;
    //
    property Owner: TACLTextLayout read FOwner;
  public
    constructor Create(AOwner: TACLTextLayout); virtual;
  end;

  { TACLTextLayoutVisualExporter }

  TACLTextLayoutVisualExporter = class(TACLTextLayoutExporter)
  strict private
    FCanvas: TCanvas;
    FDefaultTextColor: TColor;
    FHasBackground: Boolean;
    FStyleStack: TACLTextLayoutBlockStyleStack;

    function GetCanvas: TCanvas; inline;
  protected
    function AddStyle(ABlock: TACLTextLayoutBlockStyle): Boolean; override;
    procedure PrepareCanvas(ACanvas: TCanvas); virtual;
    //
    property HasBackground: Boolean read FHasBackground;
    property StyleStack: TACLTextLayoutBlockStyleStack read FStyleStack;
  public
    constructor Create(AOwner: TACLTextLayout); override;
    destructor Destroy; override;
    //
    property Canvas: TCanvas read GetCanvas write FCanvas;
  end;

  { TACLTextLayoutCalculator }

  TACLTextLayoutCalculator = class(TACLTextLayoutVisualExporter)
  strict private
    FAutoHeight: Boolean;
    FAutoWidth: Boolean;
    FEditControl: Boolean;
    FEndEllipsis: Boolean;
    FMaxHeight: Integer;
    FMaxWidth: Integer;
    FWordWrap: Boolean;

    FCurrentRow: TACLTextLayoutRow;
  {$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
    FCurrentRowRtlRange: Boolean;
    FCurrentRowRtlRanges: TACLList<TACLRange>;
  {$ENDIF}
    FCurrentRowStartStyle: TACLTextLayoutBlockStyleStack;
    FLayout: TACLTextLayoutBlockList;
    FOrigin: TPoint;
    FSpaceSize: TSize;

    function GetLineHeight: Integer; inline;
    function GetSpaceSize: TSize;
  protected
    function AddLineBreak: Boolean; override;
    function AddSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function AddStyle(ABlock: TACLTextLayoutBlockStyle): Boolean; override;
    function AddText(ABlock: TACLTextLayoutBlockText): Boolean; override;

    procedure CompleteCurrentRow;
    procedure MeasureSize(ABlock: TACLTextLayoutBlockText); inline;
    procedure Reorder(ABlocks: TACLTextLayoutBlockList; const ARange: TACLRange);
    procedure SetEndEllipsis(ARow: TACLTextLayoutRow);

    property LineHeight: Integer read GetLineHeight;
    property SpaceSize: TSize read GetSpaceSize;
  public
    constructor Create(AOwner: TACLTextLayout; AWidth, AHeight: Integer); reintroduce;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

  { TACLTextLayoutHitTest }

  TACLTextLayoutHitTest = class(TACLTextLayoutExporter)
  strict private
    FHitObject: TACLTextLayoutBlock;
    FHitPoint: TPoint;
    FHyperlink: TACLTextLayoutBlockStyleHyperlink;
    FHyperlinkChecked: TACLBoolean;
    FStyleStack: TACLTextLayoutBlockStyleStack;

    function GetHyperlink: TACLTextLayoutBlockStyleHyperlink;
  protected
    function AddBlock(ABlock: TACLTextLayoutBlock): Boolean; inline;
    function AddLineBreak: Boolean; override;
    function AddSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function AddStyle(ABlock: TACLTextLayoutBlockStyle): Boolean; override;
    function AddText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  public
    constructor Create(AOwner: TACLTextLayout); override;
    destructor Destroy; override;
    procedure Reset;
    //
    property HitObject: TACLTextLayoutBlock read FHitObject;
    property HitPoint: TPoint read FHitPoint write FHitPoint;
    property Hyperlink: TACLTextLayoutBlockStyleHyperlink read GetHyperlink;
  end;

  { TACLTextLayoutRender }

  TACLTextLayoutRender = class(TACLTextLayoutVisualExporter)
  protected
    function AddSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function AddText(AText: TACLTextLayoutBlockText): Boolean; override;
  public
    constructor Create(AOwner: TACLTextLayout; ACanvas: TCanvas); reintroduce;
  end;

  { TACLTextImporter }

  TACLTextImporter = class
  protected type
    TTokenController = function (ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean;
  protected const
    Delimiters = acParserDefaultIdentDelimiters +
      #$200B#$201c#$201D#$2018#$2019#$FF08#$FF09#$FF0C#$FF1A#$FF1B#$FF1F#$060C +
      #$3000#$3001#$3002#$300c#$300d#$300e#$300f#$300a#$300b#$3008#$3009#$3014#$3015;
    EmailPattern =
      '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}' +
      '[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$';
    Spaces = acParserDefaultSpaceChars;
    UrlEndDelimiters = Spaces + '[]()';
  strict private
    class var FEmailValidator: TRegEx;
    class var FStyleTokens: TACLStringList;
  protected
    FTokenControllers: TACLList<TTokenController>;

    procedure PopulateTokenControllers(const ASettings: TACLTextFormatSettings); virtual;
    //# Token Controllers
    class function IsCppLikeLineBreakToken(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean; static;
    class function IsDelimiterToken(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean; static;
    class function IsEmail(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean; static;
    class function IsLineBreakToken(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean; static;
    class function IsSpaceToken(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean; static;
    class function IsStyleToken(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean; static;
    class function IsTextToken(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean; static;
    class function IsURL(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean; static;
    //# Utils
    class procedure AddBlock(ATarget: TACLTextLayout; ABlock: TACLTextLayoutBlock;
      const ABaseScan: PWideChar; var AScan: PWideChar; var ALength: Integer; ABlockLength: Integer); static; inline;
    class procedure AddTextBlock(ATarget: TACLTextLayout; ABaseScan, AText: PWideChar; ALength: Integer); static; inline;
    class procedure ReplaceWithHyperlink(ATarget: TACLTextLayout;
      AFirstBlockToReplace: TACLTextLayoutBlockText; AScan: PWideChar; const AHyperlinkPrefix: string); static;
    class procedure ScanUntilDelimiter(var AScan: PWideChar; var ALength: Integer; const ADelimiters: UnicodeString); static; inline;
  public
    class constructor Create;
    class destructor Destroy;
    constructor Create(const ASettings: TACLTextFormatSettings);
    destructor Destroy; override;
    procedure Run(ATarget: TACLTextLayout; const AText: string); virtual;
  end;

  { TACLTextPlainTextExporter }

  TACLTextPlainTextExporter = class(TACLTextLayoutExporter)
  strict private
    FTarget: TStringBuilder;
  public
    constructor Create(ASource: TACLTextLayout; ATarget: TStringBuilder); reintroduce;
    function AddLineBreak: Boolean; override;
    function AddSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function AddText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  end;

procedure acDrawFormattedText(ACanvas: TCanvas; const S: UnicodeString; const R: TRect;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AWordWrap: Boolean);
function acGetReadingDirection(const C: Char): TACLTextReadingDirection; overload;
function acGetReadingDirection(P: PWideChar; L: Integer): TACLTextReadingDirection; overload; inline;
implementation

type
  TACLTextLayoutRefreshHelper = class(TACLTextLayoutExporter)
  protected
    function AddText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  end;

{$REGION 'BiDi Support'}
//#AI:
// This code was taken from the https://source.winehq.org/source/dlls/gdi32/bidi.c
type
  TCharacterDirection =
  (
     // input types
              // ON MUST be zero, code relies on ON = N = 0
     ON = 0,  // Other Neutral
     L,       // Left Letter
     R,       // Right Letter
     AN,      // Arabic Number
     EN,      // European Number
     AL,      // Arabic Letter (Right-to-left)
     NSM,     // Non-spacing Mark
     CS,      // Common Separator
     ES,      // European Separator
     ET,      // European Terminator (post/prefix e.g. $ and %)

     // resolved types
     BN,      // Boundary neutral (type of RLE etc after explicit levels)

     // input types,
     S,       // Segment Separator (TAB)        // used only in L1
     WS,      // White space                    // used only in L1
     B,       // Paragraph Separator (aka as PS)

     // types for explicit controls
     RLO,     // these are used only in X1-X9
     RLE,
     LRO,
     LRE,
     PDF,

     LRI, // Isolate formatting characters new with 6.3
     RLI,
     FSI,
     PDI,

     // resolved types, also resolved directions
     NI = ON // alias, where ON, WS and S are treated the same
  );

const
  BidiDirectionTable: array[0..4511] of Word = (
    // level 1 offsets
    $0100, $0110, $0120, $0130, $0140, $0150, $0160, $0170, $0180, $0190, $01a0, $01b0, $01c0, $01d0, $01e0, $01f0,
    $0200, $0110, $0110, $0210, $0220, $0110, $0230, $0240, $0250, $0260, $0270, $0280, $0290, $02a0, $0110, $02b0,
    $02c0, $02d0, $02e0, $02f0, $0300, $0310, $0320, $0310, $0110, $0310, $0310, $0330, $0340, $0350, $0360, $0370,
    $0380, $0390, $03a0, $03b0, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110,
    $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $03c0, $0110, $0110,
    $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110,
    $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110,
    $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110,
    $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110,
    $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110,
    $0110, $0110, $0110, $0110, $03d0, $0110, $03e0, $03f0, $0400, $0410, $0420, $0430, $0110, $0110, $0110, $0110,
    $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110,
    $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110,
    $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110,
    $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110,
    $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0110, $0440, $0450, $0460, $0470, $0480,
    // level 2 offsets
    $0490, $04a0, $04b0, $04c0, $04d0, $04e0, $04d0, $04f0, $0500, $0510, $0520, $0530, $0540, $0550, $0540, $0550,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0560, $0570, $0570, $0580, $0590,
    $05a0, $05a0, $05a0, $05a0, $05a0, $05a0, $05a0, $05b0, $05c0, $0540, $0540, $0540, $0540, $0540, $0540, $05d0,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $05e0, $0540, $0540, $0540, $0540, $0540, $0540, $0540,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $05f0, $0600, $05a0, $0610, $0620, $0630, $0640, $0650,
    $0660, $0670, $0680, $0680, $0690, $05a0, $06a0, $06b0, $0680, $0680, $0680, $0680, $0680, $06c0, $06d0, $06e0,
    $06f0, $0700, $0680, $05a0, $0710, $0680, $0680, $0680, $0680, $0680, $0720, $0730, $0630, $0630, $0740, $0750,
    $0630, $0760, $0770, $0780, $0630, $0790, $07a0, $0540, $0540, $0540, $0680, $07b0, $0540, $07c0, $07d0, $05a0,
    $07e0, $0540, $0540, $07f0, $0800, $0810, $0820, $0540, $0830, $0540, $0540, $0840, $0850, $0540, $0820, $0860,
    $0870, $0540, $0540, $0840, $0880, $0830, $0540, $0890, $0870, $0540, $0540, $0840, $08a0, $0540, $0820, $08b0,
    $0830, $0540, $0540, $08c0, $0850, $08d0, $0820, $0540, $08e0, $0540, $0540, $0540, $08f0, $0540, $0540, $0900,
    $0910, $0540, $0540, $0920, $0930, $0940, $0820, $0950, $0830, $0540, $0540, $0840, $0960, $0540, $0820, $0540,
    $0970, $0540, $0540, $0980, $0850, $0540, $0820, $0540, $0540, $0540, $0540, $0540, $0990, $09a0, $0540, $0540,
    $0540, $0540, $0540, $09b0, $09c0, $0540, $0540, $0540, $0540, $0540, $0540, $09d0, $09e0, $0540, $0540, $0540,
    $0540, $09f0, $0540, $0a00, $0540, $0540, $0540, $0a10, $0a20, $0a30, $05a0, $0a40, $08d0, $0540, $0540, $0540,
    $0540, $0540, $0a50, $0a60, $0540, $0a70, $0a80, $0a90, $0aa0, $0ab0, $0540, $0540, $0540, $0540, $0540, $0540,
    $0540, $0540, $0540, $0540, $0540, $0a50, $0540, $0540, $0540, $0ac0, $0540, $0540, $0540, $0540, $0540, $0540,
    $04d0, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0ad0, $0ae0, $0540, $0540, $0540, $0540, $0540, $0540,
    $0540, $0af0, $0540, $0af0, $0540, $0820, $0540, $0820, $0540, $0540, $0540, $0b00, $0b10, $0b20, $0540, $0ac0,
    $0b30, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0940, $0540, $0b40, $0540, $0540, $0540, $0540, $0540,
    $0540, $0540, $0b50, $0b60, $0b70, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0b80, $0590, $0590,
    $0540, $0b90, $0540, $0540, $0540, $0ba0, $0bb0, $0bc0, $0540, $0540, $0540, $0bd0, $0540, $0540, $0540, $0540,
    $0be0, $0540, $0540, $0bf0, $08e0, $0540, $0c00, $0be0, $0970, $0540, $0c10, $0540, $0540, $0540, $0c20, $0970,
    $0540, $0540, $0c30, $0c40, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0c50, $0c60, $0c70,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $05a0, $05a0, $05a0, $0c80,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0c90, $0ca0, $0cb0, $0cb0, $0cc0,
    $0cd0, $0590, $0ce0, $0cf0, $0d00, $0d10, $0d20, $0d30, $0d40, $0540, $0d50, $0d50, $0540, $05a0, $05a0, $0a80,
    $0d60, $0d70, $0d80, $0d90, $0da0, $0590, $0540, $0540, $0db0, $0590, $0590, $0590, $0590, $0590, $0590, $0590,
    $0590, $0dc0, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590,
    $0590, $0590, $0590, $0dd0, $0540, $0540, $0540, $04e0, $0590, $0de0, $0590, $0590, $0590, $0590, $0590, $0590,
    $0590, $0590, $0df0, $0540, $0e00, $0540, $0590, $0590, $0e10, $0e20, $0540, $0540, $0540, $0540, $0e30, $0590,
    $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590,
    $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0e40, $0590, $0590, $0590, $0590, $0590,
    $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0e50, $0590, $0e60, $0590, $0590, $0590, $0590, $0590, $0590,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0e70, $0e80,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0e90, $0540, $0540, $0540, $0540, $0540, $0540, $05a0, $05a0,
    $0590, $0590, $0590, $0590, $0590, $0540, $0540, $0540, $0590, $0ea0, $0590, $0590, $0590, $0590, $0590, $0eb0,
    $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0590, $0dd0, $0540, $0ec0,
    $0ed0, $0590, $0ee0, $0ef0, $0540, $0540, $0540, $0540, $0540, $0f00, $04d0, $0540, $0540, $0540, $0540, $0f10,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0590, $0590, $0eb0, $0540,
    $0540, $0cc0, $0540, $0540, $0540, $0590, $0540, $0f20, $0540, $0540, $0540, $0f30, $0f40, $0540, $0540, $0540,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0f50, $0540, $0540, $0540, $0540, $0540, $0b80, $0540, $0f60,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0590, $0590, $0590, $0590,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0590, $0590, $0590, $0df0, $0540, $0540, $0540,
    $0cb0, $0540, $0540, $0540, $0540, $0540, $0e90, $0f70, $0540, $0920, $0540, $0540, $0540, $0540, $0540, $0970,
    $0590, $0590, $0f80, $0540, $0540, $0540, $0540, $0540, $0f90, $0540, $0540, $0540, $0540, $0540, $0540, $0540,
    $0fa0, $0540, $0fb0, $0fc0, $0540, $0540, $0540, $0fd0, $0540, $0540, $0540, $0540, $0fe0, $0540, $05a0, $0ff0,
    $0540, $0540, $1000, $0540, $1010, $0970, $0540, $0540, $07e0, $0540, $0540, $1020, $0540, $0540, $1030, $0540,
    $0540, $0540, $1040, $1050, $1060, $0540, $0540, $0840, $0540, $0540, $0540, $1070, $0830, $0540, $0960, $08d0,
    $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $1080, $0540,
    $0540, $1090, $10a0, $10b0, $10c0, $0680, $0680, $0680, $0680, $0680, $0680, $0680, $10d0, $10e0, $0680, $0680,
    $0680, $0680, $0680, $0680, $0680, $0680, $0680, $0680, $0680, $0680, $0680, $0680, $0680, $0680, $0680, $0680,
    $0680, $0680, $0680, $10f0, $0540, $0680, $0680, $0680, $0680, $1100, $0680, $0680, $1110, $0540, $0540, $1120,
    $05a0, $0ac0, $05a0, $0590, $0590, $1130, $1140, $1150, $0680, $0680, $0680, $0680, $0680, $0680, $0680, $1160,
    $1170, $04c0, $04d0, $04e0, $04d0, $04e0, $0dd0, $0540, $0540, $0540, $0540, $0540, $0540, $0540, $1180, $1190,
    // values
    $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000b, $000d, $000b, $000c, $000d, $000a, $000a,
    $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000d, $000d, $000d, $000b,
    $000c, $0000, $0000, $0009, $0009, $0009, $0000, $0000, $0000, $0000, $0000, $0008, $0007, $0008, $0007, $0007,
    $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0007, $0000, $0000, $0000, $0000, $0000,
    $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0000,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0000, $000a,
    $000a, $000a, $000a, $000a, $000a, $000d, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a,
    $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a,
    $0007, $0000, $0009, $0009, $0009, $0009, $0000, $0000, $0000, $0000, $0001, $0000, $0000, $000a, $0000, $0000,
    $0009, $0009, $0004, $0004, $0000, $0001, $0000, $0000, $0000, $0004, $0001, $0000, $0000, $0000, $0000, $0000,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006,
    $0001, $0001, $0001, $0001, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0001,
    $0001, $0001, $0001, $0001, $0000, $0000, $0001, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0001, $0001, $0000, $0000, $0009,
    $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006,
    $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0002, $0006,
    $0002, $0006, $0006, $0002, $0006, $0006, $0002, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
    $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0001, $0001, $0001, $0001, $0002,
    $0002, $0002, $0002, $0002, $0002, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0003, $0003, $0003, $0003, $0003, $0003, $0000, $0000, $0005, $0009, $0009, $0005, $0007, $0005, $0000, $0000,
    $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0005, $0005, $0001, $0005, $0005,
    $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005,
    $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0006, $0006, $0006, $0006, $0006,
    $0003, $0003, $0003, $0003, $0003, $0003, $0003, $0003, $0003, $0003, $0009, $0003, $0003, $0005, $0005, $0005,
    $0006, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005,
    $0005, $0005, $0005, $0005, $0005, $0005, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0003, $0000, $0006,
    $0006, $0006, $0006, $0006, $0006, $0005, $0005, $0006, $0006, $0000, $0006, $0006, $0006, $0006, $0005, $0005,
    $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0005, $0005, $0005, $0005, $0005, $0005,
    $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0001, $0005,
    $0005, $0006, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005,
    $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001, $0005, $0005, $0005,
    $0005, $0005, $0005, $0005, $0005, $0005, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006,
    $0006, $0005, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0006, $0006, $0006, $0006, $0006,
    $0006, $0006, $0006, $0006, $0002, $0002, $0000, $0000, $0000, $0000, $0002, $0001, $0001, $0006, $0002, $0002,
    $0002, $0002, $0002, $0002, $0002, $0002, $0006, $0006, $0006, $0006, $0002, $0006, $0006, $0006, $0006, $0006,
    $0006, $0006, $0006, $0006, $0002, $0006, $0006, $0006, $0002, $0006, $0006, $0006, $0006, $0006, $0001, $0001,
    $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0001,
    $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0006, $0006, $0006, $0001, $0001, $0002, $0001,
    $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0001, $0001, $0001, $0001, $0001,
    $0005, $0005, $0005, $0005, $0005, $0001, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0001, $0001,
    $0001, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006,
    $0006, $0006, $0003, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006,
    $0006, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0006, $0001, $0001, $0001,
    $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001, $0001, $0001, $0006, $0001, $0001,
    $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001, $0001,
    $0001, $0006, $0006, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001,
    $0001, $0001, $0009, $0009, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0009, $0001, $0001, $0006, $0001,
    $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0006, $0006, $0001, $0001, $0006, $0006, $0006, $0001, $0001,
    $0006, $0006, $0001, $0001, $0001, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0006, $0006, $0006, $0006, $0006, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0006, $0001, $0001,
    $0001, $0009, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001, $0006,
    $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001,
    $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0009, $0000, $0001, $0001, $0001, $0001, $0001,
    $0006, $0001, $0001, $0001, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006,
    $0006, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006, $0001, $0006, $0006, $0006, $0006, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0001, $0001,
    $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0006, $0006, $0006, $0001, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0006, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001, $0001, $0001, $0009,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001,
    $0001, $0006, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0006, $0001, $0006, $0000, $0000, $0000, $0000, $0001, $0001,
    $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001,
    $0006, $0006, $0006, $0006, $0006, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006,
    $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006,
    $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006,
    $0006, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0006, $0006, $0001, $0001, $0006, $0006, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0006, $0006,
    $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0006, $0006, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0006, $0001, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001,
    $000c, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0001, $0001, $0001,
    $0001, $0001, $0006, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0006, $0006, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006,
    $0006, $0006, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0009, $0001, $0006, $0001, $0001,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0006, $0006, $0006, $000a, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001, $0001, $0001, $0001, $0001,
    $0006, $0006, $0006, $0001, $0001, $0001, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006, $0001, $0001, $0001, $0001,
    $0000, $0001, $0001, $0001, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0001, $0001, $0006, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001,
    $0006, $0001, $0006, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001, $0001,
    $0001, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001, $0006,
    $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001,
    $0006, $0006, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0006, $0001, $0006, $0006, $0006, $0006, $0006, $0001, $0006, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006, $0006, $0006,
    $0001, $0001, $0006, $0006, $0006, $0006, $0001, $0001, $0006, $0006, $0001, $0006, $0006, $0006, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0006, $0006, $0001, $0001, $0001, $0006, $0001, $0006,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006, $0006,
    $0006, $0006, $0006, $0006, $0001, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0006, $0006, $0006, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006,
    $0006, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001, $0001, $0001, $0006, $0001, $0001,
    $0001, $0001, $0001, $0001, $0006, $0001, $0001, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001,
    $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0006, $0006, $0006, $0006, $0006,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0001, $0000,
    $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0001,
    $000c, $000c, $000c, $000c, $000c, $000c, $000c, $000c, $000c, $000c, $000c, $000a, $000a, $000a, $0001, $0002,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $000c, $000d, $0011, $000f, $0012, $0010, $000e, $0007,
    $0009, $0009, $0009, $0009, $0009, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0007, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $000c,
    $000a, $000a, $000a, $000a, $000a, $0001, $0013, $0014, $0015, $0016, $000a, $000a, $000a, $000a, $000a, $000a,
    $0004, $0001, $0001, $0001, $0004, $0004, $0004, $0004, $0004, $0004, $0008, $0008, $0000, $0000, $0000, $0001,
    $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0008, $0008, $0000, $0000, $0000, $0001,
    $0009, $0009, $0009, $0009, $0009, $0009, $0009, $0009, $0009, $0009, $0009, $0009, $0009, $0009, $0009, $0009,
    $0000, $0000, $0001, $0000, $0000, $0000, $0000, $0001, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0000, $0001, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0000, $0000,
    $0000, $0000, $0000, $0000, $0001, $0000, $0001, $0000, $0001, $0000, $0001, $0001, $0001, $0001, $0009, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0001, $0001, $0001, $0001,
    $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0001, $0001, $0001, $0001,
    $0000, $0000, $0008, $0009, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0000, $0000, $0000, $0000, $0000, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0001,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004,
    $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0004, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0006,
    $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0000, $0000, $0000, $0000, $0000,
    $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001,
    $000c, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006, $0006, $0001, $0001,
    $0000, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0000, $0000, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0001,
    $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0000,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000,
    $0006, $0006, $0006, $0000, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0000, $0000,
    $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0006, $0001, $0001, $0001, $0006, $0001, $0001, $0001, $0001, $0006, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0001, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0009, $0009, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006,
    $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006, $0006,
    $0001, $0001, $0001, $0006, $0001, $0001, $0006, $0006, $0006, $0006, $0001, $0001, $0006, $0006, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0006, $0006, $0006, $0006, $0006, $0001,
    $0001, $0006, $0006, $0001, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0006, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001, $0001,
    $0006, $0001, $0006, $0006, $0006, $0001, $0001, $0006, $0006, $0001, $0001, $0001, $0001, $0001, $0006, $0006,
    $0001, $0001, $0001, $0001, $0001, $0006, $0001, $0001, $0006, $0001, $0001, $0001, $0001, $0006, $0001, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0002, $0006, $0002,
    $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0008, $0002, $0002, $0002, $0002, $0002, $0002,
    $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0001, $0002, $0002, $0002, $0002, $0002, $0001, $0002, $0001,
    $0002, $0002, $0001, $0002, $0002, $0001, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
    $0005, $0005, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0001, $0001, $0001, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005,
    $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0000, $0000,
    $0001, $0001, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005,
    $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001,
    $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0000, $0001, $0001,
    $0007, $0000, $0007, $0001, $0000, $0007, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0009,
    $0000, $0000, $0008, $0008, $0000, $0000, $0000, $0001, $0000, $0009, $0009, $0000, $0001, $0001, $0001, $0001,
    $0005, $0005, $0005, $0005, $0005, $0001, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005,
    $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0005, $0001, $0001, $000a,
    $0001, $0000, $0000, $0009, $0009, $0009, $0000, $0000, $0000, $0000, $0000, $0008, $0007, $0008, $0007, $0007,
    $0009, $0009, $0000, $0000, $0000, $0009, $0009, $0001, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0001,
    $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0000, $0000, $0000, $0000, $0000, $0001, $0001
  );
{$ENDREGION}

function acCharacterType(const C: Word): TCharacterDirection;
var
  W: Word;
begin
  W := BidiDirectionTable[C shr 8] + (C shr 4) and $0F;
  W := BidiDirectionTable[W];
  W := BidiDirectionTable[W + C and $0F];
  Result := TCharacterDirection(W);
end;

function acGetReadingDirection(const C: Char): TACLTextReadingDirection;
begin
  case acCharacterType(Ord(C)) of
    TCharacterDirection.R,
    TCharacterDirection.AL,
    TCharacterDirection.RLE,
    TCharacterDirection.RLO:
      Result := trdRightToLeft;
    TCharacterDirection.L,
    TCharacterDirection.LRE,
    TCharacterDirection.LRO:
      Result := trdLeftToRight;
  else
    Result := trdNeutral;
  end;
end;

function acGetReadingDirection(P: PWideChar; L: Integer): TACLTextReadingDirection;
begin
  if L > 0 then
    Result := acGetReadingDirection(P^)
  else
    Result := trdNeutral;
end;

procedure acDrawFormattedText(ACanvas: TCanvas; const S: UnicodeString; const R: TRect;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AWordWrap: Boolean);
var
  AFont: TFont;
  AText: TACLTextLayout;
begin
  if not R.IsEmpty and (S <> '') and RectVisible(ACanvas.Handle, R) then
  begin
    AFont := ACanvas.Font.Clone;
    try
      AText := TACLTextLayout.Create(AFont);
      try
        AText.SetOption(tloWordWrap, AWordWrap);
        AText.SetText(S, TACLTextFormatSettings.Default);
        AText.Bounds := R;
        AText.HorzAlignment := AHorzAlignment;
        AText.VertAlignment := AVertAlignment;
        AText.Draw(ACanvas);
      finally
        AText.Free;
      end;
    finally
      AFont.Free;
    end;
  end;
end;

{ TACLTextFormatSettings }

class function TACLTextFormatSettings.Default: TACLTextFormatSettings;
begin
  ZeroMemory(@Result, SizeOf(Result));
  Result.AllowAutoURLDetect := True;
  Result.AllowCppLikeLineBreaks := True;
  Result.AllowFormatting := True;
end;

class function TACLTextFormatSettings.PlainText: TACLTextFormatSettings;
begin
  ZeroMemory(@Result, SizeOf(Result));
end;

{ TACLTextLayout }

constructor TACLTextLayout.Create(AFont: TFont);
begin
  FFont := AFont;
  FBlocks := TACLTextLayoutBlockList.Create;
  FLayout := TACLTextLayoutBlockList.Create;
end;

destructor TACLTextLayout.Destroy;
begin
  FreeAndNil(FBlocks);
  FreeAndNil(FLayout);
  inherited;
end;

procedure TACLTextLayout.Calculate;
begin
  if FLayoutIsDirty then
  begin
    FLayoutIsDirty := False;
    FLayout.Count := 0;
    FTruncated := False;
    CalculateCore(acRectWidth(Bounds), acRectHeight(Bounds));
  end;
end;

procedure TACLTextLayout.Draw(ACanvas: TCanvas);
begin
  Draw(ACanvas, Bounds);
end;

procedure TACLTextLayout.Draw(ACanvas: TCanvas; const AClipRect: TRect);
var
  AClipRegion: Integer;
begin
  if RectVisible(ACanvas.Handle, AClipRect) then
  begin
    Calculate;
    AClipRegion := acSaveClipRegion(ACanvas.Handle);
    try
      if acIntersectClipRegion(ACanvas.Handle, AClipRect) then
        DrawCore(ACanvas);
    finally
      acRestoreClipRegion(ACanvas.Handle, AClipRegion);
    end;
  end;
end;

procedure TACLTextLayout.DrawTo(ACanvas: TCanvas; const AClipRect: TRect; const AOrigin: TPoint);
var
  APrevOrigin: TPoint;
begin
  if AOrigin <> NullPoint then
  begin
    APrevOrigin := acMoveWindowOrg(ACanvas.Handle, AOrigin);
    try
      Draw(ACanvas, acRectOffsetNegative(AClipRect, AOrigin));
    finally
      acRestoreWindowOrg(ACanvas.Handle, APrevOrigin);
    end;
  end
  else
    Draw(ACanvas, AClipRect);
end;

function TACLTextLayout.FindBlock(APositionInText: Integer; out ABlock: TACLTextLayoutBlock): Boolean;
var
  AItem: TACLTextLayoutBlock;
  I: Integer;
begin
  for I := 0 to FBlocks.Count - 1 do
  begin
    AItem := FBlocks.List[I];
    if (AItem.FPositionInText >= APositionInText) and (APositionInText < AItem.FPositionInText + AItem.FLength) then
    begin
      ABlock := AItem;
      Exit(True);
    end;
  end;
  Result := False;
end;

function TACLTextLayout.FindHyperlink(const P: TPoint; out AHyperlink: TACLTextLayoutBlockStyleHyperlink): Boolean;
var
  AHitTest: TACLTextLayoutHitTest;
begin
  AHitTest := TACLTextLayoutHitTest.Create(Self);
  try
    HitTest(P, AHitTest);
    Result := AHitTest.Hyperlink <> nil;
    if Result then
      AHyperlink := AHitTest.Hyperlink;
  finally
    AHitTest.Free;
  end;
end;

procedure TACLTextLayout.HitTest(const P: TPoint; AHitTest: TACLTextLayoutHitTest);
begin
  Calculate;
  AHitTest.Reset;
  AHitTest.HitPoint := P;
  FLayout.Export(AHitTest, False);
end;

function TACLTextLayout.IsTruncated: Boolean;
begin
  Calculate;
  Result := FTruncated;
end;

function TACLTextLayout.MeasureSize: TSize;
begin
  Calculate;
  Result := acSize(FLayout.BoundingRect);
end;

procedure TACLTextLayout.Refresh;
begin
  FBlocks.Export(TACLTextLayoutRefreshHelper.Create(Self), True);
  FLayoutIsDirty := True;
end;

procedure TACLTextLayout.SetOption(AOption: TACLTextLayoutOption; AState: Boolean);
begin
  if AState then
    Options := Options + [AOption]
  else
    Options := Options - [AOption];
end;

procedure TACLTextLayout.SetText(const AText: string; const AFormatSettings: TACLTextFormatSettings);
var
  AImporter: TACLTextImporter;
begin
  AImporter := CreateImporter(AFormatSettings);
  try
    FLayout.Clear;
    FBlocks.Clear;
    FText := AText;
    AImporter.Run(Self, Text);
    FLayoutIsDirty := True;
  finally
    AImporter.Free;
  end;
end;

procedure TACLTextLayout.SetBounds(const AValue: TRect);
begin
  if FBounds <> AValue then
  begin
    FBounds := AValue;
    FLayoutIsDirty := True;
  end;
end;

procedure TACLTextLayout.SetOptions(AOptions: TACLTextLayoutOptions);
begin
  if FOptions <> AOptions then
  begin
    FOptions := AOptions;
    FLayoutIsDirty := True;
  end;
end;

procedure TACLTextLayout.SetHorzAlignment(AValue: TAlignment);
begin
  if FHorzAlignment <> AValue then
  begin
    FHorzAlignment := AValue;
    FLayoutIsDirty := True;
  end;
end;

procedure TACLTextLayout.SetVertAlignment(AValue: TVerticalAlignment);
begin
  if FVertAlignment <> AValue then
  begin
    FVertAlignment := AValue;
    FLayoutIsDirty := True;
  end;
end;

function TACLTextLayout.ToString: string;
var
  B: TStringBuilder;
begin
  B := TACLStringBuilderManager.Get(Length(Text));
  try
    FBlocks.Export(TACLTextPlainTextExporter.Create(Self, B), True);
    Result := B.ToString;
  finally
    TACLStringBuilderManager.Release(B);
  end;
end;

function TACLTextLayout.CreateImporter(const AFormatSettings: TACLTextFormatSettings): TACLTextImporter;
begin
  Result := TACLTextImporter.Create(AFormatSettings);
end;

function TACLTextLayout.CreateLayoutCalculator(AWidth, AHeight: Integer): TACLTextLayoutExporter;
begin
  Result := TACLTextLayoutCalculator.Create(Self, AWidth, AHeight);
end;

function TACLTextLayout.CreateRender(ACanvas: TCanvas): TACLTextLayoutExporter;
begin
  Result := TACLTextLayoutRender.Create(Self, ACanvas);
end;

procedure TACLTextLayout.DrawCore(ACanvas: TCanvas);
var
  APrevFont: HFONT;
begin
  APrevFont := GetCurrentObject(ACanvas.Handle, OBJ_FONT);
  try
    FLayout.Export(CreateRender(ACanvas), True);
  finally
    SelectObject(ACanvas.Handle, APrevFont);
  end;
end;

procedure TACLTextLayout.ApplyAlignment(const AOrigin: TPoint; AMaxWidth, AMaxHeight: Integer;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment);
var
  AOffsetX: Integer;
  AOffsetY: Integer;
  ARow: TACLTextLayoutBlock;
  I: Integer;
begin
  AOffsetY := AOrigin.Y;
  case AVertAlignment of
    taAlignBottom:
      Inc(AOffsetY, Max(0, (AMaxHeight - FLayout.BoundingRect.Bottom)));
    taVerticalCenter:
      Inc(AOffsetY, Max(0, (AMaxHeight - FLayout.BoundingRect.Bottom) div 2));
  end;

  for I := 0 to FLayout.Count - 1 do
  begin
    ARow := FLayout.List[I];
    AOffsetX := AOrigin.X;
    case AHorzAlignment of
      taRightJustify:
        Inc(AOffsetX, Max(0, (AMaxWidth - ARow.FBounds.Right)));
      taCenter:
        Inc(AOffsetX, Max(0, (AMaxWidth - ARow.FBounds.Right) div 2));
    end;
    ARow.Offset(AOffsetX, AOffsetY);
  end;
end;

procedure TACLTextLayout.CalculateCore(AMaxWidth, AMaxHeight: Integer);
begin
  if FBlocks.Count > 0 then
    FBlocks.Export(CreateLayoutCalculator(AMaxWidth, AMaxHeight), True);
  ApplyAlignment(Bounds.TopLeft, AMaxWidth, AMaxHeight, HorzAlignment, VertAlignment);
end;

function TACLTextLayout.GetDefaultHyperLinkColor: TColor;
var
  H, S, L: Byte;
begin
  Result := GetDefaultTextColor;
  TACLColors.RGBtoHSLi(Result, H, S, L);
  TACLColors.HSLtoRGBi(154, Max(S, 154), Min(Max(L, 100), 200), Result);
end;

function TACLTextLayout.GetDefaultTextColor: TColor;
begin
  Result := Font.Color;
end;

{ TACLTextLayoutBlock }

function TACLTextLayoutBlock.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := True;
end;

procedure TACLTextLayoutBlock.Offset(ADeltaX, ADeltaY: Integer);
begin
  FBounds := acRectOffset(FBounds, ADeltaX, ADeltaY);
end;

procedure TACLTextLayoutBlock.ReduceWidth(AMaxRight: Integer);
begin
  if FBounds.Right > AMaxRight then
    FBounds.Right := Max(FBounds.Left, AMaxRight);
end;

{ TACLTextLayoutBlockList }

function TACLTextLayoutBlockList.Export(AExporter: TACLTextLayoutExporter; AFreeExporter: Boolean): Boolean;
begin
  Result := True;
  try
    for var I := 0 to Count - 1 do
    begin
      if not List[I].Export(AExporter) then
        Exit(False);
    end;
  finally
    if AFreeExporter then
      FreeAndNil(AExporter);
  end;
end;

procedure TACLTextLayoutBlockList.Offset(ADeltaX, ADeltaY: Integer);
begin
  for var I := 0 to Count - 1 do
    List[I].Offset(ADeltaX, ADeltaY);
end;

function TACLTextLayoutBlockList.GetBoundingRect: TRect;
begin
  if Count = 0 then
    Exit(NullRect);

  Result := First.FBounds;
  for var I := 1 to Count - 1 do
    acRectUnion(Result, List[I].FBounds);
end;

{ TACLTextLayoutBlockLineBreak }

function TACLTextLayoutBlockLineBreak.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.AddLineBreak;
end;

{ TACLTextLayoutBlockSpace }

function TACLTextLayoutBlockSpace.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.AddSpace(Self);
end;

{ TACLTextLayoutBlockText }

destructor TACLTextLayoutBlockText.Destroy;
begin
  Flush;
  inherited;
end;

function TACLTextLayoutBlockText.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.AddText(Self);
end;

procedure TACLTextLayoutBlockText.Flush;
begin
  FVisibleLength := 0;
{$IFDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
  FreeAndNil(FTextViewInfo);
{$ELSE}
  FCharacterCount := 0;
  FTextSize := NullSize;
  FreeMemAndNil(Pointer(FCharacterWidths));
{$ENDIF}
end;

procedure TACLTextLayoutBlockText.ReduceWidth(AMaxRight: Integer);
var
{$IFDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
  AReducedCharacters: Integer;
  AReducedWidth: Integer;
{$ELSE}
  ACount: Integer;
  AScan: PInteger;
{$ENDIF}
begin
  if Bounds.Right > AMaxRight then
  begin
  {$IFDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
    FTextViewInfo.AdjustToWidth(AMaxRight - Bounds.Left, AReducedCharacters, AReducedWidth);
    Dec(FVisibleLength, AReducedCharacters);
    Dec(FBounds.Right, AReducedWidth);
  {$ELSE}
    ACount := FCharacterCount;
    AScan := FCharacterWidths;
    Inc(AScan, ACount - 1);
    while (ACount > 0) and (Bounds.Right > AMaxRight) do
    begin
      Dec(FBounds.Right, AScan^);
      Dec(FVisibleLength);
      Dec(ACount);
      Dec(AScan);
    end;
  {$ENDIF}
  end;
end;

function TACLTextLayoutBlockText.ToString: string;
begin
  SetString(Result, FText, FLength);
end;

{$IFDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
function TACLTextLayoutBlockText.GetTextSize: TSize;
begin
  Result := FTextViewInfo.Size;
end;
{$ENDIF}

{ TACLTextLayoutBlockStyle }

constructor TACLTextLayoutBlockStyle.Create(AIsSetMode: Boolean);
begin
  FIsSetMode := AIsSetMode;
end;

function TACLTextLayoutBlockStyle.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.AddStyle(Self);
end;

procedure TACLTextLayoutBlockStyle.AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout);
begin
  // do nothing
end;

procedure TACLTextLayoutBlockStyle.SetParameters(const AParameters: string);
begin
  // do nothing
end;

{ TACLTextLayoutBlockStyleStack }

constructor TACLTextLayoutBlockStyleStack.Create;
begin
  FList := TList.Create;
end;

destructor TACLTextLayoutBlockStyleStack.Destroy;
begin
  FreeAndNil(FList);
  inherited;
end;

procedure TACLTextLayoutBlockStyleStack.Add(AStyle: TACLTextLayoutBlockStyle);
var
  AClass: TClass;
  I: Integer;
begin
  if AStyle.IsSetMode then
  begin
    FModified := True;
    FList.Add(AStyle);
    Exit;
  end;

  AClass := AStyle.ClassType;
  for I := FList.Count - 1 downto 0 do
    if TObject(FList.List[I]).ClassType = AClass then
    begin
      FList.Delete(I);
      FModified := True;
      Break;
    end;
end;

procedure TACLTextLayoutBlockStyleStack.AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout);
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
    TACLTextLayoutBlockStyle(FList.List[I]).AdjustCanvasParameters(ACanvas, ALayout);
end;

procedure TACLTextLayoutBlockStyleStack.Assign(ASource: TACLTextLayoutBlockStyleStack);
begin
  FList.Assign(ASource.FList);
  FModified := True;
end;

procedure TACLTextLayoutBlockStyleStack.Clear;
begin
  FList.Clear;
  FModified := True;
end;

function TACLTextLayoutBlockStyleStack.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TACLTextLayoutBlockStyleStack.GetItem(Index: Integer): TACLTextLayoutBlock;
begin
  Result := TACLTextLayoutBlock(FList.List[Index]);
end;

{ TACLTextLayoutBlockStyleBold }

procedure TACLTextLayoutBlockStyleBold.AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout);
begin
  ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
end;

{ TACLTextLayoutBlockStyleColor }

procedure TACLTextLayoutBlockStyleColor.AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout);
begin
  ACanvas.Font.Color := FColor;
end;

procedure TACLTextLayoutBlockStyleColor.SetParameters(const AParameters: string);
begin
  if not IdentToColor('cl' + AParameters, Integer(FColor)) then
    FColor := StringToColor(AParameters);
end;

{ TACLTextLayoutBlockStyleFill }

procedure TACLTextLayoutBlockStyleFill.AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout);
begin
  ACanvas.Brush.Color := FColor;
end;

{ TACLTextLayoutBlockStyleHyperlink }

procedure TACLTextLayoutBlockStyleHyperlink.AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout);
begin
  ACanvas.Font.Style := ACanvas.Font.Style + [fsUnderline];
  ACanvas.Font.Color := ALayout.GetDefaultHyperLinkColor;
end;

procedure TACLTextLayoutBlockStyleHyperlink.SetParameters(const AParameters: string);
begin
  FHyperlink := AParameters;
end;

{ TACLTextLayoutBlockStyleItalic }

procedure TACLTextLayoutBlockStyleItalic.AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout);
begin
  ACanvas.Font.Style := ACanvas.Font.Style + [fsItalic];
end;

{ TACLTextLayoutBlockStyleStrikeOut }

procedure TACLTextLayoutBlockStyleStrikeOut.AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout);
begin
  ACanvas.Font.Style := ACanvas.Font.Style + [fsStrikeOut];
end;

{ TACLTextLayoutBlockStyleUnderline }

procedure TACLTextLayoutBlockStyleUnderline.AdjustCanvasParameters(ACanvas: TCanvas; ALayout: TACLTextLayout);
begin
  ACanvas.Font.Style := ACanvas.Font.Style + [fsUnderline];
end;

{ TACLTextLayoutRow }

constructor TACLTextLayoutRow.Create;
begin
  FBlocks := TACLTextLayoutBlockList.Create(False);
end;

destructor TACLTextLayoutRow.Destroy;
begin
  EndEllipsis := nil;
  FreeAndNil(FBlocks);
  inherited;
end;

function TACLTextLayoutRow.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := FBlocks.Export(AExporter, False);
end;

procedure TACLTextLayoutRow.Offset(ADeltaX, ADeltaY: Integer);
begin
  inherited;
  FBlocks.Offset(ADeltaX, ADeltaY);
end;

procedure TACLTextLayoutRow.SetEndEllipsis(AValue: TACLTextLayoutBlock);
begin
  if FEndEllipsis <> AValue then
  begin
    FreeAndNil(FEndEllipsis);
    FEndEllipsis := AValue;
  end;
end;

{ TACLTextLayoutExporter }

constructor TACLTextLayoutExporter.Create(AOwner: TACLTextLayout);
begin
  FOwner := AOwner;
end;

function TACLTextLayoutExporter.AddLineBreak: Boolean;
begin
  Result := True;
end;

function TACLTextLayoutExporter.AddSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  Result := True;
end;

function TACLTextLayoutExporter.AddStyle(ABlock: TACLTextLayoutBlockStyle): Boolean;
begin
  Result := True;
end;

function TACLTextLayoutExporter.AddText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  Result := True;
end;

{ TACLTextLayoutVisualExporter }

constructor TACLTextLayoutVisualExporter.Create(AOwner: TACLTextLayout);
begin
  inherited;
  FDefaultTextColor := Owner.GetDefaultTextColor;
  FStyleStack := TACLTextLayoutBlockStyleStack.Create;
  FStyleStack.Modified := True;
end;

destructor TACLTextLayoutVisualExporter.Destroy;
begin
  FreeAndNil(FStyleStack);
  inherited;
end;

function TACLTextLayoutVisualExporter.AddStyle(ABlock: TACLTextLayoutBlockStyle): Boolean;
begin
  FStyleStack.Add(ABlock);
  Result := True;
end;

procedure TACLTextLayoutVisualExporter.PrepareCanvas(ACanvas: TCanvas);
begin
  ACanvas.Font.Assign(Owner.Font);
  ACanvas.Font.Color := FDefaultTextColor;
  ACanvas.Brush.Style := bsClear;
  StyleStack.AdjustCanvasParameters(ACanvas, Owner);
  FHasBackground := ACanvas.Brush.Style <> bsClear;
end;

function TACLTextLayoutVisualExporter.GetCanvas: TCanvas;
begin
  if FStyleStack.Modified then
  begin
    FStyleStack.Modified := False;
    PrepareCanvas(FCanvas);
  end;
  Result := FCanvas;
end;

{ TACLTextLayoutCalculator }

constructor TACLTextLayoutCalculator.Create(AOwner: TACLTextLayout; AWidth, AHeight: Integer);
begin
  inherited Create(AOwner);
{$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
  FCurrentRowRtlRanges := TACLList<TACLRange>.Create;
  FCurrentRowRtlRanges.Capacity := 8;
{$ENDIF}
  FCurrentRowStartStyle := TACLTextLayoutBlockStyleStack.Create;
  FLayout := Owner.FLayout;
  FAutoHeight := tloAutoHeight in Owner.Options;
  FAutoWidth := tloAutoWidth in Owner.Options;
  FEditControl := tloEditControl in Owner.Options;
  FEndEllipsis := tloEndEllipsis in Owner.Options;
  FWordWrap := tloWordWrap in Owner.Options;
  FMaxHeight := AHeight;
  FMaxWidth := AWidth;
end;

procedure TACLTextLayoutCalculator.AfterConstruction;
begin
  Canvas := MeasureCanvas;
  inherited;
  AddLineBreak;
end;

procedure TACLTextLayoutCalculator.BeforeDestruction;
begin
  inherited;
  CompleteCurrentRow;
  FreeAndNil(FCurrentRowStartStyle);
{$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
  FreeAndNil(FCurrentRowRtlRanges);
{$ENDIF}
end;

function TACLTextLayoutCalculator.AddLineBreak: Boolean;
begin
  CompleteCurrentRow;
  Result := FAutoHeight or (FOrigin.Y <= FMaxHeight);
  if Result then
    FCurrentRow := TACLTextLayoutRow.Create;
end;

function TACLTextLayoutCalculator.AddSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
var
  ABlockWidth: Integer;
begin
  if FCurrentRow = nil then
    Exit(False);

  ABlockWidth := SpaceSize.cx;
  if not FWordWrap or FAutoWidth or (FOrigin.X + ABlockWidth <= FMaxWidth) then
  begin
    ABlock.FBounds := Bounds(FOrigin.X, FOrigin.Y, ABlockWidth, LineHeight);
    FOrigin.X := ABlock.FBounds.Right;
    FCurrentRow.Blocks.Add(ABlock);
  end;
  Result := True;
end;

function TACLTextLayoutCalculator.AddStyle(ABlock: TACLTextLayoutBlockStyle): Boolean;
begin
  if FCurrentRow = nil then
    Exit(False);
  inherited;
  ABlock.FBounds := Bounds(FOrigin.X, FOrigin.Y, 0, 0);
  FCurrentRow.Blocks.Add(ABlock);
  FSpaceSize := NullSize;
  Result := True;
end;

function TACLTextLayoutCalculator.AddText(ABlock: TACLTextLayoutBlockText): Boolean;
{$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
var
  ARange: TACLRange;
{$ENDIF}
begin
  if FCurrentRow = nil then
    Exit(False);

  ABlock.FVisibleLength := ABlock.TextLength;
  if not FWordWrap and (FOrigin.X >= FMaxWidth) then
  begin
    Owner.FTruncated := True;
    if not FAutoWidth then
    begin
      // Для пограничной ситуации, когда предыдущий блок разместился четко по границе FMaxWidth
      if FEndEllipsis then
        SetEndEllipsis(FCurrentRow);
      Exit(True);
    end;
  end;

{$IFDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
  if ABlock.TextViewInfo = nil then
{$ELSE}
  if ABlock.TextSize.cy = 0 then
{$ENDIF}
    MeasureSize(ABlock);

  if FWordWrap and (FOrigin.X + ABlock.TextSize.cx > FMaxWidth) and (FOrigin.X > 0) then
  begin
    if not AddLineBreak then
      Exit(False);
  end;

{$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
  if ABlock.ReadingDirection = trdLeftToRight then
    FCurrentRowRtlRange := False
  else
    if FCurrentRowRtlRange then
    begin
      ARange := FCurrentRowRtlRanges.Last;
      ARange.Finish := FCurrentRow.Blocks.Count;
      FCurrentRowRtlRanges.Last := ARange;
    end
    else
      if ABlock.ReadingDirection = trdRightToLeft then
      begin
        FCurrentRowRtlRanges.Add(TACLRange.Create(FCurrentRow.Blocks.Count, FCurrentRow.Blocks.Count));
        FCurrentRowRtlRange := True;
      end;
{$ENDIF}

  ABlock.FBounds := Bounds(FOrigin.X, FOrigin.Y, ABlock.TextSize.cx, ABlock.TextSize.cy);
  FOrigin.X := ABlock.FBounds.Right;
  FCurrentRow.Blocks.Add(ABlock);

  if FOrigin.X > FMaxWidth then
  begin
    Owner.FTruncated := True;
    if FEndEllipsis and not FAutoWidth then
      SetEndEllipsis(FCurrentRow);
  end;
  Result := True;
end;

procedure TACLTextLayoutCalculator.CompleteCurrentRow;
begin
  if FCurrentRow <> nil then
  begin
    if FCurrentRow.Blocks.Count > 0 then
      FCurrentRow.FBounds := FCurrentRow.Blocks.BoundingRect
    else
      FCurrentRow.FBounds := Bounds(FOrigin.X, FOrigin.Y, 0, LineHeight);

    FOrigin.Y := FCurrentRow.FBounds.Bottom;
    FOrigin.X := 0;

    if (FCurrentRow.FBounds.Bottom > FMaxHeight) and not FAutoHeight and FEditControl then
    begin
      Owner.FTruncated := True;
      FreeAndNil(FCurrentRow);
      if FEndEllipsis and (FLayout.Count > 0) then
      begin
        StyleStack.Assign(FCurrentRowStartStyle); // чтобы посчитать корректный размер EndEllipsis
        SetEndEllipsis(TACLTextLayoutRow(FLayout.Last));
      end;
    end
    else
      FLayout.Add(FCurrentRow);

  {$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
    for var I := 0 to FCurrentRowRtlRanges.Count - 1 do
      Reorder(FCurrentRow.Blocks, FCurrentRowRtlRanges.List[I]);
    FCurrentRowRtlRanges.Count := 0;
    FCurrentRowRtlRange := False;
  {$ENDIF}
    if FEndEllipsis then
      FCurrentRowStartStyle.Assign(StyleStack);
  end;
  FCurrentRow := nil;
end;

procedure TACLTextLayoutCalculator.MeasureSize(ABlock: TACLTextLayoutBlockText);
{$IFNDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
var
  ADistance: Integer;
  AWidthScan: PInteger;
  I: Integer;
{$ENDIF}
begin
  ABlock.FVisibleLength := ABlock.TextLength;
{$IFDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
  FreeAndNil(ABlock.FTextViewInfo);
  ABlock.FTextViewInfo := TACLTextViewInfo.Create(Canvas.Handle, Canvas.Font, ABlock.Text, ABlock.TextLength);
{$ELSE}
  if ABlock.FCharacterWidths = nil then
    ABlock.FCharacterWidths := AllocMem(ABlock.TextLength * SizeOf(Integer));
  GetTextExtentExPoint(Canvas.Handle, ABlock.Text, ABlock.TextLength,
    MaxInt, @ABlock.FCharacterCount, ABlock.FCharacterWidths, ABlock.FTextSize);

  ADistance := 0;
  AWidthScan := ABlock.FCharacterWidths;
  for I := 0 to ABlock.FCharacterCount - 1 do
  begin
    AWidthScan^ := AWidthScan^ - ADistance;
    Inc(ADistance, AWidthScan^);
    Inc(AWidthScan);
  end;
{$ENDIF}
end;

procedure TACLTextLayoutCalculator.Reorder(ABlocks: TACLTextLayoutBlockList; const ARange: TACLRange);
var
  R: TRect;
  I: Integer;
begin
  if ARange.Finish > ARange.Start then
  begin
    R := ABlocks.List[ARange.Start].Bounds;
    for I := ARange.Start + 1 to ARange.Finish do
      acRectUnion(R, ABlocks.List[I].Bounds);
    for I := ARange.Start to ARange.Finish do
      ABlocks.List[I].FBounds := acRectMirror(ABlocks.List[I].Bounds, R);
  end;
end;

procedure TACLTextLayoutCalculator.SetEndEllipsis(ARow: TACLTextLayoutRow);
var
  ABlock: TACLTextLayoutBlock;
  ABlockIndex: Integer;
  AEndEllipsisBlock: TACLTextLayoutBlockText;
  AMaxRight: Integer;
begin
  if ARow.EndEllipsis = nil then
  begin
    AEndEllipsisBlock := TACLTextLayoutBlockText.Create;
    AEndEllipsisBlock.FText := PWideChar(acEndEllipsis);
    AEndEllipsisBlock.FLength := Length(acEndEllipsis);

    MeasureSize(AEndEllipsisBlock);
    AMaxRight := FMaxWidth - AEndEllipsisBlock.TextSize.cx;

    ABlockIndex := ARow.Blocks.Count - 1;
    while ABlockIndex >= 0 do
    begin
      ABlock := ARow.Blocks.List[ABlockIndex];
      ABlock.ReduceWidth(AMaxRight);
      if ABlock.Bounds.Left < AMaxRight then
        Break;
      Dec(ABlockIndex);
    end;

    if ABlockIndex >= 0 then
      AEndEllipsisBlock.FBounds := ARow.Blocks.List[ABlockIndex].Bounds
    else
      AEndEllipsisBlock.FBounds := ARow.Bounds;

    AEndEllipsisBlock.FBounds.Left := AEndEllipsisBlock.FBounds.Right + 1;
    AEndEllipsisBlock.FBounds.Width := AEndEllipsisBlock.TextSize.cx;

    for var I := ABlockIndex + 1 to ARow.Blocks.Count - 1 do
      ARow.Blocks.List[I].Offset(AEndEllipsisBlock.TextSize.cx, 0);

    ARow.Blocks.Insert(ABlockIndex + 1, AEndEllipsisBlock);
    ARow.EndEllipsis := AEndEllipsisBlock;
    ARow.FBounds.Right := AEndEllipsisBlock.Bounds.Right;
  end;
end;

function TACLTextLayoutCalculator.GetLineHeight: Integer;
begin
  Result := SpaceSize.cy;
end;

function TACLTextLayoutCalculator.GetSpaceSize: TSize;
begin
  if FSpaceSize.cx = 0 then
    GetTextExtentPoint32W(Canvas.Handle, Space, 1, FSpaceSize);
  Result := FSpaceSize;
end;

{ TACLTextLayoutHitTest }

constructor TACLTextLayoutHitTest.Create(AOwner: TACLTextLayout);
begin
  inherited Create(AOwner);
  FStyleStack := TACLTextLayoutBlockStyleStack.Create;
end;

destructor TACLTextLayoutHitTest.Destroy;
begin
  FreeAndNil(FStyleStack);
  inherited;
end;

procedure TACLTextLayoutHitTest.Reset;
begin
  FHitObject := nil;
  FHyperlinkChecked := TACLBoolean.Default;
  FHyperlink := nil;
  FStyleStack.Clear;
end;

function TACLTextLayoutHitTest.AddBlock(ABlock: TACLTextLayoutBlock): Boolean;
begin
  if PtInRect(ABlock.FBounds, FHitPoint) then
  begin
    FHitObject := ABlock;
    Exit(False);
  end;
  Result := True;
end;

function TACLTextLayoutHitTest.AddLineBreak: Boolean;
begin
  Result := True;
end;

function TACLTextLayoutHitTest.AddSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  Result := AddBlock(ABlock);
end;

function TACLTextLayoutHitTest.AddStyle(ABlock: TACLTextLayoutBlockStyle): Boolean;
begin
  FStyleStack.Add(ABlock);
  Result := True;
end;

function TACLTextLayoutHitTest.AddText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  Result := AddBlock(ABlock);
end;

function TACLTextLayoutHitTest.GetHyperlink: TACLTextLayoutBlockStyleHyperlink;
begin
  if FHyperlinkChecked = TACLBoolean.Default then
  begin
    FHyperlinkChecked := TACLBoolean.False;
    for var I := FStyleStack.Count - 1 downto 0 do
      if FStyleStack.Items[I] is TACLTextLayoutBlockStyleHyperlink then
      begin
        FHyperlink := TACLTextLayoutBlockStyleHyperlink(FStyleStack.Items[I]);
        FHyperlinkChecked := TACLBoolean.True;
        Break;
      end;
  end;
  Result := FHyperlink;
end;

{ TACLTextLayoutRender }

constructor TACLTextLayoutRender.Create(AOwner: TACLTextLayout; ACanvas: TCanvas);
begin
  inherited Create(AOwner);
  Canvas := ACanvas;
end;

function TACLTextLayoutRender.AddSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  if HasBackground then
    Canvas.FillRect(ABlock.Bounds);
  if fsUnderline in Canvas.Font.Style then
    ExtTextOut(Canvas.Handle, ABlock.Bounds.Left, ABlock.Bounds.Top, ETO_CLIPPED, @ABlock.FBounds, ' ', 1, nil);
  Result := True;
end;

function TACLTextLayoutRender.AddText(AText: TACLTextLayoutBlockText): Boolean;
begin
  if AText.VisibleLength > 0 then
  {$IFDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
    AText.FTextViewInfo.DrawCore(Canvas.Handle, AText.Bounds.Left, AText.Bounds.Top, AText.FVisibleLength);
  {$ELSE}
    ExtTextOut(Canvas.Handle, AText.Bounds.Left, AText.Bounds.Top, 0,
      @AText.FBounds, AText.FText, AText.FVisibleLength, AText.FCharacterWidths);
  {$ENDIF}
  Result := True;
end;

{ TACLTextPlainTextExporter }

constructor TACLTextPlainTextExporter.Create(ASource: TACLTextLayout; ATarget: TStringBuilder);
begin
  inherited Create(ASource);
  FTarget := ATarget;
end;

function TACLTextPlainTextExporter.AddLineBreak: Boolean;
begin
  FTarget.AppendLine;
  Result := True;
end;

function TACLTextPlainTextExporter.AddSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  FTarget.Append(Space);
  Result := True;
end;

function TACLTextPlainTextExporter.AddText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  FTarget.Append(ABlock.ToString);
  Result := True;
end;

{ TACLTextImporter }

class constructor TACLTextImporter.Create;
begin
  FStyleTokens := TACLStringList.Create;
  FStyleTokens.Add('B', TObject(TACLTextLayoutBlockStyleBold));
  FStyleTokens.Add('I', TObject(TACLTextLayoutBlockStyleItalic));
  FStyleTokens.Add('S', TObject(TACLTextLayoutBlockStyleStrikeOut));
  FStyleTokens.Add('U', TObject(TACLTextLayoutBlockStyleUnderline));
  FStyleTokens.Add('COLOR', TObject(TACLTextLayoutBlockStyleColor));
  FStyleTokens.Add('BACKCOLOR', TObject(TACLTextLayoutBlockStyleFill));
  FStyleTokens.Add('URL', TObject(TACLTextLayoutBlockStyleHyperlink));

  FEmailValidator := TRegEx.Create(EmailPattern);
end;

class destructor TACLTextImporter.Destroy;
begin
  FreeAndNil(FStyleTokens);
end;

constructor TACLTextImporter.Create(const ASettings: TACLTextFormatSettings);
begin
  FTokenControllers := TACLList<TTokenController>.Create;
  PopulateTokenControllers(ASettings);
end;

destructor TACLTextImporter.Destroy;
begin
  FreeAndNil(FTokenControllers);
  inherited;
end;

procedure TACLTextImporter.Run(ATarget: TACLTextLayout; const AText: string);
var
  ABaseScan: PChar;
  ALength: Integer;
  AScan: PChar;
  I: Integer;
begin
  AScan := PChar(AText);
  ABaseScan := AScan;
  ALength := Length(AText);
  while ALength > 0 do
  begin
    for I := 0 to FTokenControllers.Count - 1 do
    begin
      if FTokenControllers.List[I](ATarget, ABaseScan, AScan, ALength) then
        Break;
    end;
  end;
end;

procedure TACLTextImporter.PopulateTokenControllers(const ASettings: TACLTextFormatSettings);
begin
  FTokenControllers.Capacity := 8;

  if ASettings.AllowFormatting then
    FTokenControllers.Add(IsStyleToken);

  FTokenControllers.Add(IsLineBreakToken);
  if ASettings.AllowCppLikeLineBreaks then
    FTokenControllers.Add(IsCppLikeLineBreakToken);

  if ASettings.AllowAutoEmailDetect then
    FTokenControllers.Add(IsEmail);
  if ASettings.AllowAutoURLDetect then
    FTokenControllers.Add(IsURL);

  FTokenControllers.Add(IsSpaceToken);
  FTokenControllers.Add(IsDelimiterToken);
  FTokenControllers.Add(IsTextToken);
end;

class function TACLTextImporter.IsDelimiterToken(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean;
begin
  Result := acPos(AScan^, Delimiters) > 0;
  if Result then
  begin
    AddTextBlock(ATarget, ABaseScan, AScan, 1);
    Dec(ALength);
    Inc(AScan);
  end;
end;

class function TACLTextImporter.IsEmail(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean;
var
  ABlock: TACLTextLayoutBlock;
  AFirstTextBlock: TACLTextLayoutBlockText;
  ATempLength: Integer;
  ATempScan: PWideChar;
  ATextBlock: TACLTextLayoutBlockText;
  I: Integer;
begin
  Result := False;
  if AScan^ = '@' then
  begin
    AFirstTextBlock := nil;
    for I := ATarget.FBlocks.Count - 1 downto 0 do
    begin
      ABlock := ATarget.FBlocks.List[I];
      if ABlock.ClassType = TACLTextLayoutBlockText then
      begin
        ATextBlock := TACLTextLayoutBlockText(ABlock);
        if (ATextBlock.TextLength = 1) and (acPos(ATextBlock.FText^, UrlEndDelimiters) > 0) then
          Break;
        AFirstTextBlock := ATextBlock;
      end
      else
        Break;
    end;

    if AFirstTextBlock <> nil then
    begin
      ATempScan := AScan;
      ATempLength := ALength;
      ScanUntilDelimiter(ATempScan, ATempLength, UrlEndDelimiters);
      if FEmailValidator.IsMatch(acMakeString(AFirstTextBlock.FText, acStringLength(AFirstTextBlock.FText, ATempScan))) then
      begin
        ReplaceWithHyperlink(ATarget, AFirstTextBlock, ATempScan, acMailToPrefix);
        AScan := ATempScan;
        ALength := ATempLength;
      end;
    end;
  end;
end;

class function TACLTextImporter.IsCppLikeLineBreakToken(
  ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean;
begin
  Result := (AScan^ = '\') and (ALength > 1) and ((AScan + 1)^ = 'n');
  if Result then
    AddBlock(ATarget, TACLTextLayoutBlockLineBreak.Create, ABaseScan, AScan, ALength, 2);
end;

class function TACLTextImporter.IsLineBreakToken(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean;
begin
  Result := True;
  //#10
  if AScan^ = #10 then
    AddBlock(ATarget, TACLTextLayoutBlockLineBreak.Create, ABaseScan, AScan, ALength, 1)
  else

  //#13#10 or #13
  if AScan^ = #13 then
  begin
    if (AScan + 1)^ = #10 then
      AddBlock(ATarget, TACLTextLayoutBlockLineBreak.Create, ABaseScan, AScan, ALength, 2)
    else
      AddBlock(ATarget, TACLTextLayoutBlockLineBreak.Create, ABaseScan, AScan, ALength, 1);
  end
  else
    Result := False;
end;

class function TACLTextImporter.IsSpaceToken(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean;
begin
  Result := acPos(AScan^, Spaces) > 0;
  if Result then
    AddBlock(ATarget, TACLTextLayoutBlockSpace.Create, ABaseScan, AScan, ALength, 1);
end;

class function TACLTextImporter.IsStyleToken(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean;

  function TryGetBlockClass(P: PWideChar; L: Integer; out ABlockClass: TACLTextLayoutBlockStyleClass): Boolean;
  var
    I: Integer;
    S: string;
  begin
    for I := 0 to FStyleTokens.Count - 1 do
    begin
      S := FStyleTokens.Strings[I];
      if acCompareTokens(PChar(S), P, Length(S), L) then
      begin
        ABlockClass := TACLTextLayoutBlockStyleClass(FStyleTokens.Objects[I]);
        Exit(True);
      end;
    end;
    Result := False;
  end;

var
  ABlock: TACLTextLayoutBlockStyle;
  ABlockClass: TACLTextLayoutBlockStyleClass;
  AIsClosing: Boolean;
  N, C, P: PWideChar;
begin
  Result := False;
  if AScan^ = '[' then
  begin
    C := WStrScan(AScan, ALength, ']');
    if C = nil then
      Exit;

    N := AScan + 1;
    AIsClosing := N^ = '/';
    if AIsClosing then
    begin
      P := C;
      Inc(N);
    end
    else
    begin
      P := WStrScan(N, acStringLength(AScan, C), '=');
      if P = nil then
        P := C;
    end;

    Result := TryGetBlockClass(N, acStringLength(N, P), ABlockClass);
    if Result then
    begin
      ABlock := ABlockClass.Create(not AIsClosing);
      if P <> C then
        ABlock.SetParameters(acExtractString(P + 1, C));

      Inc(C);
      AddBlock(ATarget, ABlock, ABaseScan, AScan, ALength, acStringLength(AScan, C));
    end;
  end;
end;

class function TACLTextImporter.IsTextToken(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean;
var
  ACursor: PWideChar;
begin
  ACursor := AScan;
  repeat
    Dec(ALength);
    Inc(AScan);

    if ALength = 0 then
    begin
      AddTextBlock(ATarget, ABaseScan, ACursor, acStringLength(ACursor, AScan));
      Break;
    end;

    if acPos(AScan^, Delimiters) > 0 then
    begin
      AddTextBlock(ATarget, ABaseScan, ACursor, acStringLength(ACursor, AScan));
      Break;
    end;
  until False;
  Result := True;
end;

class function TACLTextImporter.IsURL(ATarget: TACLTextLayout; var ABaseScan, AScan: PWideChar; var ALength: Integer): Boolean;

  function GetLastBlockAsText(var ABlock: TACLTextLayoutBlockText): Boolean;
  var
    ALastBlock: TACLTextLayoutBlock;
  begin
    if ATarget.FBlocks.Count > 0 then
    begin
      ALastBlock := ATarget.FBlocks.Last;
      Result := ALastBlock is TACLTextLayoutBlockText;
      if Result then
        ABlock := TACLTextLayoutBlockText(ALastBlock);
    end
    else
      Result := False;
  end;

  function IsProtocol(var ABlock: TACLTextLayoutBlockText): Boolean;
  begin
    Result := (ALength > 3) and acCompareTokens(AScan, '://', 3, 3) and GetLastBlockAsText(ABlock);
  end;

  function IsWWW(var ABlock: TACLTextLayoutBlockText): Boolean;
  begin
    Result := (AScan^ = '.') and GetLastBlockAsText(ABlock) and acCompareTokens(ABlock.Text, 'www', ABlock.TextLength, 3);
  end;

var
  ATextBlock: TACLTextLayoutBlockText;
begin
  if IsProtocol(ATextBlock) then
  begin
    ScanUntilDelimiter(AScan, ALength, UrlEndDelimiters);
    ReplaceWithHyperlink(ATarget, ATextBlock, AScan, '');
    Result := True;
  end
  else
    if IsWWW(ATextBlock) then
    begin
      ScanUntilDelimiter(AScan, ALength, UrlEndDelimiters);
      ReplaceWithHyperlink(ATarget, ATextBlock, AScan, 'https://');
      Result := True;
    end
    else
      Result := False;
end;

class procedure TACLTextImporter.AddBlock(ATarget: TACLTextLayout; ABlock: TACLTextLayoutBlock;
  const ABaseScan: PWideChar; var AScan: PWideChar; var ALength: Integer; ABlockLength: Integer);
begin
  ATarget.FBlocks.Add(ABlock);
  ABlock.FPositionInText := acStringLength(ABaseScan, AScan) + 1;
  ABlock.FLength := ABlockLength;
  Dec(ALength, ABlockLength);
  Inc(AScan, ABlockLength);
end;

class procedure TACLTextImporter.AddTextBlock(ATarget: TACLTextLayout; ABaseScan, AText: PWideChar; ALength: Integer);
var
  ABlock: TACLTextLayoutBlockText;
begin
  if ALength > 0 then
  begin
    ABlock := TACLTextLayoutBlockText.Create;
    ABlock.FText := AText;
  {$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
    ABlock.FReadingDirection := acGetReadingDirection(AText, ALength);
  {$ENDIF}
    AddBlock(ATarget, ABlock, ABaseScan, AText, ALength, ALength);
  end;
end;

class procedure TACLTextImporter.ReplaceWithHyperlink(ATarget: TACLTextLayout;
  AFirstBlockToReplace: TACLTextLayoutBlockText; AScan: PWideChar; const AHyperlinkPrefix: string);
var
  AHyperlinkBlock: TACLTextLayoutBlockStyleHyperlink;
  AIndex: Integer;
begin
  AIndex := ATarget.FBlocks.IndexOf(AFirstBlockToReplace, TDirection.FromEnd);
  ATarget.FBlocks.DeleteRange(AIndex + 1, ATarget.FBlocks.Count - 1 - AIndex);
  AFirstBlockToReplace.FLength := acStringLength(AFirstBlockToReplace.FText, AScan);

  AHyperlinkBlock := TACLTextLayoutBlockStyleHyperlink.Create(True);
  AHyperlinkBlock.SetParameters(AHyperlinkPrefix + AFirstBlockToReplace.ToString);
  ATarget.FBlocks.Insert(AIndex, AHyperlinkBlock);

  ATarget.FBlocks.Add(TACLTextLayoutBlockStyleHyperlink.Create(False));
end;

class procedure TACLTextImporter.ScanUntilDelimiter(var AScan: PWideChar; var ALength: Integer; const ADelimiters: UnicodeString);
begin
  while (ALength > 0) and (acPos(AScan^, ADelimiters) = 0) do
  begin
    Dec(ALength);
    Inc(AScan);
  end;
end;

{ TACLTextLayoutRefreshHelper }

function TACLTextLayoutRefreshHelper.AddText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  ABlock.Flush;
  Result := True;
end;

end.
