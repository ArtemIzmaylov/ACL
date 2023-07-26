{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*     Formatted Text based on BB Codes      *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.TextLayout;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.Character,
  System.Classes,
  System.Contnrs,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Math,
  System.RegularExpressions,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants,
  // VCL
  Vcl.Graphics,
  // ACL
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Parsers,
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Math,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.FileSystem,
  ACL.Utils.Shell,
  ACL.Utils.Strings;

type
  TACLTextImporter = class;
  TACLTextLayoutBlock = class;
  TACLTextLayoutBlockHyperlink = class;
  TACLTextLayoutBlockList = class;
  TACLTextLayoutExporter = class;
  TACLTextLayoutHitTest = class;
  TACLTextLayoutRows = class;

  TACLTextReadingDirection = (trdNeutral, trdLeftToRight, trdRightToLeft);

  TACLTextPlainTextExporterClass = class of TACLTextPlainTextExporter;
  TACLTextPlainTextExporter = class;

  { TACLTextFormatSettings }

  TACLTextFormatSettings = record
    AllowAutoEmailDetect: Boolean;
    AllowAutoTimeCodeDetect: Boolean;
    AllowAutoURLDetect: Boolean;
    AllowCppLikeLineBreaks: Boolean; // \n
    AllowFormatting: Boolean;

    class function Default: TACLTextFormatSettings; static;
    class function Formatted: TACLTextFormatSettings; static;
    class function PlainText: TACLTextFormatSettings; static;
  end;

  TACLTextLayoutOption = (tloAutoHeight, tloAutoWidth, tloEditControl, tloEndEllipsis, tloWordWrap);
  TACLTextLayoutOptions = set of TACLTextLayoutOption;

  { TACLTextLayout }

  TACLTextLayout = class
  public const
    TimeCodePrefix = 'time:';
  strict private
    FBounds: TRect;
    FFont: TFont;
    FHorzAlignment: TAlignment;
    FOptions: TACLTextLayoutOptions;
    FTargetDPI: Integer;
    FText: string;
    FVertAlignment: TVerticalAlignment;

    procedure SetBounds(const AValue: TRect);
    procedure SetOptions(AOptions: TACLTextLayoutOptions);
    procedure SetHorzAlignment(AValue: TAlignment);
    procedure SetVertAlignment(AValue: TVerticalAlignment);
  protected
    FBlocks: TACLTextLayoutBlockList;
    FLayout: TACLTextLayoutRows;
    FLayoutIsDirty: Boolean;
    FTruncated: Boolean;

    procedure ApplyAlignment(const AOrigin: TPoint; AMaxWidth, AMaxHeight: Integer);
    procedure CalculateCore(AMaxWidth, AMaxHeight: Integer); virtual;
    function CreateLayoutCalculator(AWidth, AHeight: Integer): TACLTextLayoutExporter; virtual;
    function CreateRender(ACanvas: TCanvas): TACLTextLayoutExporter; virtual;
    procedure DrawCore(ACanvas: TCanvas); virtual;

    function GetDefaultHyperLinkColor: TColor; virtual;
    function GetDefaultTextColor: TColor; virtual;
    procedure Refresh;
  public
    constructor Create(AFont: TFont);
    destructor Destroy; override;
    procedure Calculate;
    procedure Draw(ACanvas: TCanvas); overload;
    procedure Draw(ACanvas: TCanvas; const AClipRect: TRect); overload;
    procedure DrawTo(ACanvas: TCanvas; const AClipRect: TRect; const AOrigin: TPoint);
    function FindBlock(APositionInText: Integer; out ABlock: TACLTextLayoutBlock): Boolean;
    function FindHyperlink(const P: TPoint; out AHyperlink: TACLTextLayoutBlockHyperlink): Boolean;
    procedure HitTest(const P: TPoint; AHitTest: TACLTextLayoutHitTest);
    function IsTruncated: Boolean;
    function MeasureSize: TSize; virtual;
    procedure SetOption(AOption: TACLTextLayoutOption; AState: Boolean);
    procedure SetText(const AText: string; const ASettings: TACLTextFormatSettings);
    function ToString: string; override;
    function ToStringEx(ExporterClass: TACLTextPlainTextExporterClass): string;
    //
    property Bounds: TRect read FBounds write SetBounds;
    property Font: TFont read FFont;
    property HorzAlignment: TAlignment read FHorzAlignment write SetHorzAlignment;
    property Options: TACLTextLayoutOptions read FOptions write SetOptions;
    property TargetDPI: Integer read FTargetDPI write FTargetDPI;
    property Text: string read FText;
    property VertAlignment: TVerticalAlignment read FVertAlignment write SetVertAlignment;
  end;

  { TACLTextLayoutBlock }

  TACLTextLayoutBlockClass = class of TACLTextLayoutBlock;
  TACLTextLayoutBlock = class abstract
  protected
    FLength: Word;
    FPosition: TPoint;
    FPositionInText: PWideChar;
  public
    function Bounds: TRect; dynamic;
    function Export(AExporter: TACLTextLayoutExporter): Boolean; dynamic;
    procedure Shrink(AMaxRight: Integer); virtual;
  end;

  { TACLTextLayoutBlockList }

  TACLTextLayoutBlockList = class(TACLObjectList<TACLTextLayoutBlock>)
  protected
    procedure AddInit(ABlock: TACLTextLayoutBlock; var AScan: PWideChar; ABlockLength: Integer);
  public
    function BoundingRect: TRect; dynamic;
    function Export(AExporter: TACLTextLayoutExporter; AFreeExporter: Boolean): Boolean; dynamic;
    procedure Offset(ADeltaX, ADeltaY: Integer); dynamic;
  end;

  { TACLTextLayoutBlockLineBreak }

  TACLTextLayoutBlockLineBreak = class(TACLTextLayoutBlock)
  public
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
  end;

  { TACLTextLayoutBlockSpace }

  TACLTextLayoutBlockSpace = class(TACLTextLayoutBlock)
  protected
    FSize: TSize;
  public
    function Bounds: TRect; override;
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    procedure Shrink(AMaxRight: Integer); override;
  end;

  { TACLTextLayoutBlockText }

  TACLTextLayoutBlockText = class(TACLTextLayoutBlock)
  protected
    FCharacterCount: Integer;
    FCharacterWidths: PInteger;
    FTextSize: TSize;
  public
    constructor Create(AText: PWideChar; ATextLength: Word);
    destructor Destroy; override;
    function Bounds: TRect; override;
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    procedure Flush; inline;
    procedure Shrink(AMaxRight: Integer); override;
    function ToString: string; override;

    property Text: PWideChar read FPositionInText;
    property TextLength: Word read FLength;
    property TextSize: TSize read FTextSize;
  end;

  { TACLTextLayoutBlockStyle }

  TACLTextLayoutBlockStyle = class(TACLTextLayoutBlock)
  strict private
    FInclude: Boolean;
  public
    constructor Create(AInclude: Boolean);
    property Include: Boolean read FInclude;
  end;

  { TACLTextLayoutBlockFontColor }

  TACLTextLayoutBlockFontColor = class(TACLTextLayoutBlockStyle)
  strict private
    FColor: TColor;
  public
    constructor Create(const AColor: string; AInclude: Boolean);
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    property Color: TColor read FColor;
  end;

  { TACLTextLayoutBlockFontSize }

  TACLTextLayoutBlockFontSize = class(TACLTextLayoutBlockStyle)
  strict private
    FValue: Variant;
  public
    constructor Create(const AValue: Variant; AInclude: Boolean);
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    property Value: Variant read FValue;
  end;

  { TACLTextLayoutBlockFontBig }

  TACLTextLayoutBlockFontBig = class(TACLTextLayoutBlockFontSize)
  public
    constructor Create(AInclude: Boolean);
  end;

  { TACLTextLayoutBlockFontSmall }

  TACLTextLayoutBlockFontSmall = class(TACLTextLayoutBlockFontSize)
  public
    constructor Create(AInclude: Boolean);
  end;

  { TACLTextLayoutBlockFontStyle }

  TACLTextLayoutBlockFontStyle = class(TACLTextLayoutBlockStyle)
  strict private
    FStyle: TFontStyle;
  public
    constructor Create(AStyle: TFontStyle; AInclude: Boolean);
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    property Style: TFontStyle read FStyle;
  end;

  { TACLTextLayoutBlockFillColor }

  TACLTextLayoutBlockFillColor = class(TACLTextLayoutBlockFontColor)
  public
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
  end;

  { TACLTextLayoutBlockHyperlink }

  TACLTextLayoutBlockHyperlink = class(TACLTextLayoutBlockFontStyle)
  strict private
    FHyperlink: string;
  public
    constructor Create(const AHyperlink: string; AInclude: Boolean);
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    property Hyperlink: string read FHyperlink;
  end;

  { TACLTextLayoutRow }

  TACLTextLayoutRow = class(TACLTextLayoutBlockList)
  strict private
    FBaseline: Integer; 
    FBounds: TRect;
    FEndEllipsis: TACLTextLayoutBlockText;

    procedure SetBaseline(AValue: Integer);
  protected
    procedure SetEndEllipsis(ARightSide: Integer; AEndEllipsis: TACLTextLayoutBlockText);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Offset(ADeltaX, ADeltaY: Integer); override;
    property Baseline: Integer read FBaseline write SetBaseline;
    property Bounds: TRect read FBounds write FBounds;
    property EndEllipsis: TACLTextLayoutBlockText read FEndEllipsis;
  end;

  { TACLTextLayoutRows }

  TACLTextLayoutRows = class(TACLObjectList<TACLTextLayoutRow>)
  public
    function BoundingRect: TRect;
    function Export(AExporter: TACLTextLayoutExporter; AFreeExporter: Boolean): Boolean; inline;
  end;

  { TACLTextLayoutExporter }

  TACLTextLayoutExporter = class abstract
  strict private
    FOwner: TACLTextLayout;
  protected
    function OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean; virtual;
    function OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean; virtual;
    function OnFontSize(ABlock: TACLTextLayoutBlockFontSize): Boolean; virtual;
    function OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean; virtual;
    function OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean; virtual;
    function OnLineBreak: Boolean; virtual;
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; virtual;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; virtual;
    //
    property Owner: TACLTextLayout read FOwner;
  public
    constructor Create(AOwner: TACLTextLayout);
  end;

  { TACLTextLayoutValueStack<T> }

  TACLTextLayoutValueStack<T> = class
  strict private
    FCount: Integer;
    FData: array of TPair<T, TClass>;
  public
    constructor Create;
    function Peek: T;
    procedure Pop(AInvoker: TClass);
    procedure Push(const AValue: T; AInvoker: TClass);
    property Count: Integer read FCount;
  end;

  { TACLTextLayoutVisualExporter }

  TACLTextLayoutVisualExporter = class(TACLTextLayoutExporter)
  strict private
    FCanvas: TCanvas;
    FFont: TFont;
    FFontSizes: TACLTextLayoutValueStack<Integer>;
    FFontStyles: array[TFontStyle] of Word;
  protected
    function OnFontSize(ABlock: TACLTextLayoutBlockFontSize): Boolean; override;
    function OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean; override;
    property Canvas: TCanvas read FCanvas;
    property Font: TFont read FFont write FFont;
  public
    constructor Create(ACanvas: TCanvas; AOwner: TACLTextLayout);
    destructor Destroy; override;
  end;

  { TACLTextLayoutCalculator }

  TACLTextLayoutCalculator = class(TACLTextLayoutVisualExporter)
  strict private
    FEditControl: Boolean;
    FEndEllipsis: Boolean;
    FMaxHeight: Integer;
    FMaxWidth: Integer;
    FWordWrap: Boolean;

    FBaseline: Integer;
    FLineHeight: Integer;
    FSpaceWidth: Integer;

    FOrigin: TPoint;
    FRow: TACLTextLayoutRow;
    FRowAlign: TAlignment;
    FRowTruncated: Boolean;
  {$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
    FRowRtlRange: Boolean;
    FRowRtlRanges: TACLList<TACLRange>;
  {$ENDIF}
    FRows: TACLTextLayoutRows;
    FPrevRowEndEllipsis: TACLTextLayoutBlockText;

    function ActualOrigin: TPoint; inline;
    function AddStyle(ABlock: TACLTextLayoutBlockStyle): Boolean; inline;
    function CreateEndEllipsisBlock: TACLTextLayoutBlockText;
    procedure CompleteRow;
    procedure TruncateAll;
    procedure TruncateRow;
  protected
    function OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean; override;
    function OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean; override;
    function OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean; override;
    function OnFontSize(ABlock: TACLTextLayoutBlockFontSize): Boolean; override;
    function OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean; override;
    function OnLineBreak: Boolean; override;
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;

    procedure MeasureSize(ABlock: TACLTextLayoutBlockText); inline;
    procedure Reorder(ABlocks: TACLTextLayoutBlockList; const ARange: TACLRange);
    procedure UpdateMetrics;

    property Baseline: Integer read FBaseline;
    property LineHeight: Integer read FLineHeight;
    property SpaceWidth: Integer read FSpaceWidth;
  public
    constructor Create(AOwner: TACLTextLayout; AWidth, AHeight: Integer); reintroduce;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
  end;

  { TACLTextLayoutHitTest }

  TACLTextLayoutHitTest = class(TACLTextLayoutExporter)
  strict private
    FHitObject: TACLTextLayoutBlock;
    FHitPoint: TPoint;
    FHyperlinks: TStack;

    function GetHyperlink: TACLTextLayoutBlockHyperlink;
  protected
    function OnBlock(ABlock: TACLTextLayoutBlock): Boolean; inline;
    function OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean; override;
    function OnLineBreak: Boolean; override;
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  public
    destructor Destroy; override;
    procedure Reset;
    //
    property HitObject: TACLTextLayoutBlock read FHitObject;
    property HitPoint: TPoint read FHitPoint write FHitPoint;
    property Hyperlink: TACLTextLayoutBlockHyperlink read GetHyperlink;
  end;

  { TACLTextLayoutRender }

  TACLTextLayoutRender = class(TACLTextLayoutVisualExporter)
  strict private
    FDefaultTextColor: TColor;
    FFillColors: TACLTextLayoutValueStack<TColor>;
    FFontColors: TACLTextLayoutValueStack<TColor>;
    FHasBackground: Boolean;

    procedure UpdateFillColor; inline;
    procedure UpdateFontColor; inline;
  protected
    function OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean; override;
    function OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean; override;
    function OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean; override;
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnText(AText: TACLTextLayoutBlockText): Boolean; override;

    property HasBackground: Boolean read FHasBackground;
  public
    constructor Create(AOwner: TACLTextLayout; ACanvas: TCanvas); reintroduce;
    destructor Destroy; override;
  end;

  { TACLTextImporter }

  TACLTextImporter = class
  protected const
    EmailPattern =
      '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}' +
      '[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$';
    Spaces = acParserDefaultSpaceChars;
    Delimiters = '[]()\' +
      #$200B#$201c#$201D#$2018#$2019#$FF08#$FF09#$FF0C#$FF1A#$FF1B#$FF1F#$060C +
      #$3000#$3001#$3002#$300c#$300d#$300e#$300f#$300a#$300b#$3008#$3009#$3014#$3015 + Spaces; // Spaces в конце!
  strict private
    class var FEmailValidator: TRegEx;
  protected type
  {$REGION 'Sub-Types'}
    TContext = class;
    TTokenDetector = function (Ctx: TContext; var Scan: PWideChar): Boolean;
    TTokenDetectorInText = function (Ctx: TContext; S: PWideChar; L: Integer): Boolean;
    TContext = class
    public
      Blocks: TACLTextLayoutBlockList;
      HyperlinkDepth: Integer;
      TokenDetectors: array of TTokenDetector;
      TokenInTextDetectors: array of TTokenDetectorInText;
    end;
  {$ENDREGION}
  protected
    class function AllocContext(const ASettings: TACLTextFormatSettings): TACLTextImporter.TContext; virtual;
    //# Token Detectors
    class function IsDelimiter(Ctx: TContext; var Scan: PWideChar): Boolean; static;
    class function IsLineBreak(Ctx: TContext; var Scan: PWideChar): Boolean; static;
    class function IsLineBreakCpp(Ctx: TContext; var Scan: PWideChar): Boolean; static;
    class function IsSpace(Ctx: TContext; var Scan: PWideChar): Boolean; static;
    class function IsStyle(Ctx: TContext; var Scan: PWideChar): Boolean; static;
    class function IsText(Ctx: TContext; var Scan: PWideChar): Boolean; static;
    // # TokenInText Detectors
    class function IsEmail(Ctx: TContext; S: PWideChar; L: Integer): Boolean; static;
    class function IsTimeCode(Ctx: TContext; S: PWideChar; L: Integer): Boolean; static;
    class function IsURL(Ctx: TContext; S: PWideChar; L: Integer): Boolean; static;
  public
    class constructor Create;
  end;

  { TACLTextPlainTextExporter }

  TACLTextPlainTextExporter = class(TACLTextLayoutExporter)
  protected
    FTarget: TACLStringBuilder;
  public
    constructor Create(ASource: TACLTextLayout; ATarget: TACLStringBuilder); reintroduce;
    function OnLineBreak: Boolean; override;
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  end;

  { TACLTextFormattedTextExporter }

  TACLTextFormattedTextExporter = class(TACLTextPlainTextExporter)
  public
    function OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean; override;
    function OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean; override;
    function OnFontSize(ABlock: TACLTextLayoutBlockFontSize): Boolean; override;
    function OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean; override;
    function OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean; override;
  end;

procedure acDrawFormattedText(ACanvas: TCanvas; const S: UnicodeString; const R: TRect;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AWordWrap: Boolean);
function acGetReadingDirection(const C: Char): TACLTextReadingDirection; overload;
function acGetReadingDirection(P: PWideChar; L: Integer): TACLTextReadingDirection; overload; inline;
implementation

type
  TACLTextLayoutRefreshHelper = class(TACLTextLayoutExporter)
  protected
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
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

class function TACLTextFormatSettings.Formatted: TACLTextFormatSettings;
begin
  ZeroMemory(@Result, SizeOf(Result));
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
  FTargetDPI := FFont.PixelsPerInch;
  FBlocks := TACLTextLayoutBlockList.Create;
  FLayout := TACLTextLayoutRows.Create;
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
  ASearchPosition: NativeUInt;
begin
  if not InRange(APositionInText, 1, Length(FText)) then
    Exit(False);

  ASearchPosition := NativeUInt(PWideChar(FText) + APositionInText);
  for var I := 0 to FBlocks.Count - 1 do
  begin
    AItem := FBlocks.List[I];
    if (NativeUInt(AItem.FPositionInText) >= ASearchPosition) and
       (NativeUInt(AItem.FPositionInText) <  ASearchPosition + AItem.FLength)
    then
      begin
        ABlock := AItem;
        Exit(True);
      end;
  end;
  Result := False;
end;

function TACLTextLayout.FindHyperlink(const P: TPoint; out AHyperlink: TACLTextLayoutBlockHyperlink): Boolean;
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

procedure TACLTextLayout.SetText(const AText: string; const ASettings: TACLTextFormatSettings);
var
  AContext: TACLTextImporter.TContext;
  ACount: Integer;
  AScan: PChar;
begin
  FLayoutIsDirty := True;
  FLayout.Clear;
  FBlocks.Clear;
  FText := AText;

  AContext := TACLTextImporter.AllocContext(ASettings);
  try
    AContext.Blocks := FBlocks;
    AScan := PWideChar(AText);
    ACount := Length(AContext.TokenDetectors);
    while AScan^ <> #0 do
      for var I := 0 to ACount - 1 do
      begin
        if AContext.TokenDetectors[I](AContext, AScan) then
          Break;
      end;
  finally
    AContext.Free;
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
begin
  Result := ToStringEx(TACLTextPlainTextExporter);
end;

function TACLTextLayout.ToStringEx(ExporterClass: TACLTextPlainTextExporterClass): string;
var
  B: TACLStringBuilder;
begin
  B := TACLStringBuilder.Get(Length(Text));
  try
    FBlocks.Export(ExporterClass.Create(Self, B), True);
    Result := B.ToString;
  finally
    B.Release
  end;
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

procedure TACLTextLayout.CalculateCore(AMaxWidth, AMaxHeight: Integer);
begin
  if FBlocks.Count > 0 then
    FBlocks.Export(CreateLayoutCalculator(AMaxWidth, AMaxHeight), True);
  ApplyAlignment(Bounds.TopLeft, AMaxWidth, AMaxHeight);
end;

procedure TACLTextLayout.ApplyAlignment(const AOrigin: TPoint; AMaxWidth, AMaxHeight: Integer);
var
  AOffsetX: Integer;
  AOffsetY: Integer;
  ARow: TACLTextLayoutRow;
begin
  AOffsetY := AOrigin.Y;
  case VertAlignment of
    taAlignBottom:
      Inc(AOffsetY, Max(0, (AMaxHeight - FLayout.BoundingRect.Bottom)));
    taVerticalCenter:
      Inc(AOffsetY, Max(0, (AMaxHeight - FLayout.BoundingRect.Bottom) div 2));
  end;

  for var I := 0 to FLayout.Count - 1 do
  begin
    ARow := FLayout.List[I];
    AOffsetX := AOrigin.X;
    case HorzAlignment of
      taRightJustify:
        Inc(AOffsetX, Max(0, (AMaxWidth - ARow.Bounds.Right)));
      taCenter:
        Inc(AOffsetX, Max(0, (AMaxWidth - ARow.Bounds.Right) div 2));
      taLeftJustify:
        Dec(AOffsetX, ARow.Bounds.Left);
    end;
    ARow.Offset(AOffsetX, AOffsetY);
  end;
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

function TACLTextLayoutBlock.Bounds: TRect; 
begin
  Result := TRect.Create(FPosition);
end;

function TACLTextLayoutBlock.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := True;
end;

procedure TACLTextLayoutBlock.Shrink(AMaxRight: Integer);
begin
  FPosition.X := Min(FPosition.X, AMaxRight);
end;

{ TACLTextLayoutBlockList }

procedure TACLTextLayoutBlockList.AddInit(ABlock: TACLTextLayoutBlock; var AScan: PWideChar; ABlockLength: Integer);
begin
  Add(ABlock);
  ABlock.FPositionInText := AScan;
  ABlock.FLength := ABlockLength;
  Inc(AScan, ABlockLength);
end;

function TACLTextLayoutBlockList.BoundingRect: TRect;
begin
  if Count = 0 then
    Exit(NullRect);

  Result := First.Bounds;
  for var I := 1 to Count - 1 do
    acRectUnion(Result, List[I].Bounds);
end;

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
    List[I].FPosition.Offset(ADeltaX, ADeltaY);
end;

{ TACLTextLayoutBlockLineBreak }

function TACLTextLayoutBlockLineBreak.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnLineBreak;
end;

{ TACLTextLayoutBlockSpace }

function TACLTextLayoutBlockSpace.Bounds: TRect;
begin
  Result := acRect(FPosition, FSize);
end;

function TACLTextLayoutBlockSpace.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnSpace(Self);
end;

procedure TACLTextLayoutBlockSpace.Shrink(AMaxRight: Integer);
begin
  FSize.cx := MaxMin(AMaxRight - FPosition.X, 0, FSize.cx);
  inherited;
end;

{ TACLTextLayoutBlockText }

constructor TACLTextLayoutBlockText.Create(AText: PWideChar; ATextLength: Word);
begin
  inherited Create;
  FPositionInText := AText;
  FLength := ATextLength;
end;

destructor TACLTextLayoutBlockText.Destroy;
begin
  FreeMemAndNil(Pointer(FCharacterWidths));
  inherited;
end;

function TACLTextLayoutBlockText.Bounds: TRect;
begin
  Result := acRect(FPosition, TextSize);
end;

function TACLTextLayoutBlockText.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnText(Self);
end;

procedure TACLTextLayoutBlockText.Flush;
begin
  FCharacterCount := 0;
  FTextSize := NullSize;
end;

procedure TACLTextLayoutBlockText.Shrink(AMaxRight: Integer);
var
  AMaxWidth: Integer;
  AScan: PInteger;
begin
  AMaxWidth := AMaxRight - FPosition.X;
  if AMaxWidth <= 0 then
  begin
    FCharacterCount := 0;
    FTextSize.cx := 0;
  end
  else
    if TextSize.cx > AMaxWidth then
    begin
      AScan := FCharacterWidths;
      Inc(AScan, FCharacterCount - 1);
      while (FCharacterCount > 0) and (TextSize.cx > AMaxWidth) do
      begin
        Dec(FTextSize.cx, AScan^);
        Dec(FCharacterCount);
        Dec(AScan);
      end;
    end;

  inherited;
end;

function TACLTextLayoutBlockText.ToString: string;
begin
  SetString(Result, Text, TextLength);
end;

{ TACLTextLayoutBlockStyle }

constructor TACLTextLayoutBlockStyle.Create(AInclude: Boolean);
begin
  FInclude := AInclude;
end;

{ TACLTextLayoutBlockFontColor }

constructor TACLTextLayoutBlockFontColor.Create(const AColor: string; AInclude: Boolean);
begin
  inherited Create(AInclude);
  if not IdentToColor('cl' + AColor, Integer(FColor)) then
    FColor := StringToColor(AColor);
end;

function TACLTextLayoutBlockFontColor.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnFontColor(Self);
end;

{ TACLTextLayoutBlockFontSize }

constructor TACLTextLayoutBlockFontSize.Create(const AValue: Variant; AInclude: Boolean);
var
  AValueFloat: Single;
  AValueInt32: Integer;
begin
  inherited Create(AInclude);

  if VarIsNumeric(AValue) then
    FValue := AValue
  else if TryStrToInt(AValue, AValueInt32) then
    FValue := AValueInt32
  else if TryStrToFloat(AValue, AValueFloat) then
    FValue := AValueFloat
  else
    FValue := 1.0;
end;

function TACLTextLayoutBlockFontSize.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnFontSize(Self);
end;

{ TACLTextLayoutBlockFontBig }

constructor TACLTextLayoutBlockFontBig.Create(AInclude: Boolean);
begin
  inherited Create(1.10, AInclude);
end;

{ TACLTextLayoutBlockFontSmall }

constructor TACLTextLayoutBlockFontSmall.Create(AInclude: Boolean);
begin
  inherited Create(0.9, AInclude);
end;

{ TACLTextLayoutBlockFontStyle }

constructor TACLTextLayoutBlockFontStyle.Create(AStyle: TFontStyle; AInclude: Boolean);
begin
  inherited Create(AInclude);
  FStyle := AStyle;
end;

function TACLTextLayoutBlockFontStyle.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnFontStyle(Self);
end;

{ TACLTextLayoutBlockFillColor }

function TACLTextLayoutBlockFillColor.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnFillColor(Self);
end;

{ TACLTextLayoutBlockHyperlink }

constructor TACLTextLayoutBlockHyperlink.Create(const AHyperlink: string; AInclude: Boolean);
begin
  inherited Create(fsUnderline, AInclude);
  FHyperlink := AHyperlink;
end;

function TACLTextLayoutBlockHyperlink.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnHyperlink(Self);
end;

{ TACLTextLayoutRow }

constructor TACLTextLayoutRow.Create;
begin
  inherited Create(False);
end;

destructor TACLTextLayoutRow.Destroy;
begin
  FreeAndNil(FEndEllipsis);
  inherited;
end;

procedure TACLTextLayoutRow.Offset(ADeltaX, ADeltaY: Integer);
begin
  FBounds.Offset(ADeltaX, ADeltaY);
  inherited;
end;

procedure TACLTextLayoutRow.SetBaseline(AValue: Integer);
begin
  if AValue <> FBaseline then
  begin
    for var I := 0 to Count - 1 do
      Inc(List[I].FPosition.Y, AValue - FBaseline);
    FBaseline := AValue;
  end;
end;

procedure TACLTextLayoutRow.SetEndEllipsis(ARightSide: Integer; AEndEllipsis: TACLTextLayoutBlockText);
var
  ABlock: TACLTextLayoutBlock;
begin
{$IFDEF DEBUG}
  if AEndEllipsis = nil then
    raise EInvalidOperation.Create('Row: the EndEllipsis block must be specified');
  if EndEllipsis <> nil then
    raise EInvalidOperation.Create('Row: the EndEllipsis block is already specified');
{$ENDIF}

  FEndEllipsis := AEndEllipsis;
  Dec(ARightSide, EndEllipsis.TextSize.Width);
  FEndEllipsis.FPosition.X := Bounds.Right;

  // Ищем последний видимый блок, после которого можно воткнуть '...'
  for var I := Count - 1 downto 0 do
  begin
    ABlock := List[I];
    ABlock.Shrink(ARightSide);
    if ABlock.FPosition.X < ARightSide then
    begin
      EndEllipsis.FPosition.X := ABlock.Bounds.Right + 1;
      Break;
    end;
  end;

  // Позицию по Y берем от последнего блока,
  // т.к. '...' был посчитан с его параметрами шрифта
  if Count > 0 then
    EndEllipsis.FPosition.Y := Last.FPosition.Y
  else
    EndEllipsis.FPosition.Y := Bounds.Top;

  // Вставка так же идет в конец строки,
  // дабы при отрисовке все необходимые style-блоки уже отработали.
  Add(EndEllipsis);

  // Корректируем ширину строки
  FBounds.Right := EndEllipsis.Bounds.Right;
end;

{ TACLTextLayoutRows }

function TACLTextLayoutRows.BoundingRect: TRect;
begin
  if Count = 0 then
    Exit(NullRect);
  Result := List[0].Bounds;
  for var I := 1 to Count - 1 do
    Result.Union(List[I].Bounds);
end;

function TACLTextLayoutRows.Export(AExporter: TACLTextLayoutExporter; AFreeExporter: Boolean): Boolean;
begin
  Result := True;
  try
    for var I := 0 to Count - 1 do
    begin
      if not List[I].Export(AExporter, False) then
        Exit(False);
    end;
  finally
    if AFreeExporter then
      AExporter.Free;
  end;
end;

{ TACLTextLayoutExporter }

constructor TACLTextLayoutExporter.Create(AOwner: TACLTextLayout);
begin
  FOwner := AOwner;
end;

function TACLTextLayoutExporter.OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean;
begin
  Result := True;
end;

function TACLTextLayoutExporter.OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean;
begin
  Result := True;
end;

function TACLTextLayoutExporter.OnFontSize(ABlock: TACLTextLayoutBlockFontSize): Boolean;
begin
  Result := True;
end;

function TACLTextLayoutExporter.OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean;
begin
  Result := True;
end;

function TACLTextLayoutExporter.OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean;
begin
  Result := True;
end;

function TACLTextLayoutExporter.OnLineBreak: Boolean;
begin
  Result := True;
end;

function TACLTextLayoutExporter.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  Result := True;
end;

function TACLTextLayoutExporter.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  Result := True;
end;

{ TACLTextLayoutValueStack<T> }

constructor TACLTextLayoutValueStack<T>.Create;
begin
  FCount := 0;
  SetLength(FData, 16);
end;

function TACLTextLayoutValueStack<T>.Peek: T;
begin
  if Count = 0 then
    raise Exception.Create('Stack is empty');
  Result := FData[FCount - 1].Key;
end;

procedure TACLTextLayoutValueStack<T>.Pop(AInvoker: TClass);
begin
  for var I := FCount - 1 downto 0 do
    if FData[I].Value = AInvoker then
    begin
      for var J := I to FCount - 2 do
        FData[J] := FData[J + 1];
      Dec(FCount);
      Break;
    end;
end;

procedure TACLTextLayoutValueStack<T>.Push(const AValue: T; AInvoker: TClass);
begin
  if FCount = Length(FData) then
    SetLength(FData, 2 * Length(FData));
  FData[FCount] := TPair<T, TClass>.Create(AValue, AInvoker);
  Inc(FCount);
end;

{ TACLTextLayoutVisualExporter }

constructor TACLTextLayoutVisualExporter.Create(ACanvas: TCanvas; AOwner: TACLTextLayout);
begin
  inherited Create(AOwner);
  FCanvas := ACanvas;
  FCanvas.Font.Assign(Owner.Font);
  FFont := FCanvas.Font;
  FFontSizes := TACLTextLayoutValueStack<Integer>.Create;
  FFontSizes.Push(FFont.Height, nil);
end;

destructor TACLTextLayoutVisualExporter.Destroy;
begin
  FreeAndNil(FFontSizes);
  inherited;
end;

function TACLTextLayoutVisualExporter.OnFontSize(ABlock: TACLTextLayoutBlockFontSize): Boolean;
var
  AHeight: Integer;
begin
  if ABlock.Include then
  begin
    if VarIsFloat(ABlock.Value) then
      AHeight := Round(Font.Height * ABlock.Value)
    else
      AHeight := acGetFontHeight(ABlock.Value, Owner.TargetDPI);

    FFontSizes.Push(AHeight, ABlock.ClassType);
  end
  else
    FFontSizes.Pop(ABlock.ClassType);

  Font.Height := FFontSizes.Peek;
  Result := True;
end;

function TACLTextLayoutVisualExporter.OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean;
begin
  FFontStyles[ABlock.Style] := Max(FFontStyles[ABlock.Style] + Signs[ABlock.Include], 0);

  if FFontStyles[ABlock.Style] > 0 then
    Font.Style := Font.Style + [ABlock.Style]
  else
    Font.Style := Font.Style - [ABlock.Style];

  Result := True;
end;

{ TACLTextLayoutCalculator }

constructor TACLTextLayoutCalculator.Create(AOwner: TACLTextLayout; AWidth, AHeight: Integer);
begin
  inherited Create(MeasureCanvas, AOwner);
  FRows := Owner.FLayout;
{$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
  FRowRtlRanges := TACLList<TACLRange>.Create;
  FRowRtlRanges.Capacity := 8;
{$ENDIF}
  FEditControl := tloEditControl in Owner.Options;
  FEndEllipsis := tloEndEllipsis in Owner.Options;
  FMaxHeight := IfThen(tloAutoHeight in Owner.Options, MaxInt, AHeight);
  FMaxWidth := IfThen(tloAutoWidth in Owner.Options, MaxInt, AWidth);
  FWordWrap := tloWordWrap in Owner.Options;

  if tloAutoWidth in Owner.Options then
    FRowAlign := taLeftJustify
  else
    FRowAlign := Owner.HorzAlignment;

  FRow := TACLTextLayoutRow.Create;
  UpdateMetrics;
end;

destructor TACLTextLayoutCalculator.Destroy;
begin
  FreeAndNil(FPrevRowEndEllipsis);
{$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
  FreeAndNil(FRowRtlRanges);
{$ENDIF}
  inherited;
end;

procedure TACLTextLayoutCalculator.BeforeDestruction;
begin
  inherited;
  CompleteRow;
end;

function TACLTextLayoutCalculator.OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean;
begin
  Result := AddStyle(ABlock);
end;

function TACLTextLayoutCalculator.OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean;
begin
  Result := AddStyle(ABlock);
end;

function TACLTextLayoutCalculator.OnFontSize(ABlock: TACLTextLayoutBlockFontSize): Boolean;
begin
  inherited;
  UpdateMetrics;
  Result := AddStyle(ABlock);
end;

function TACLTextLayoutCalculator.OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean;
begin
  inherited;
  UpdateMetrics;
  Result := AddStyle(ABlock);
end;

function TACLTextLayoutCalculator.OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean;
begin
  Result := AddStyle(ABlock);
end;

function TACLTextLayoutCalculator.OnLineBreak: Boolean;
begin
  Result := FRow <> nil;
  if Result then  
  begin
    CompleteRow;
    FRow := TACLTextLayoutRow.Create;
    FRow.Bounds := Bounds(FOrigin.X, FOrigin.Y, 0, 0);
    FRowTruncated := False;
  end;
end;

function TACLTextLayoutCalculator.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  if FRow = nil then
    Exit(False);
  if FRowTruncated then
    Exit(True);  

  ABlock.FPosition := ActualOrigin;
  if not FWordWrap or (FOrigin.X + SpaceWidth <= FMaxWidth) then
  begin
    ABlock.FSize := acSize(SpaceWidth, LineHeight);
    FOrigin.X := ABlock.FPosition.X + SpaceWidth;
    FRow.Add(ABlock);
  end;
  Result := True;
end;

function TACLTextLayoutCalculator.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
{$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
var
  ARange: TACLRange;
  AReadingDirection: TACLTextReadingDirection;
{$ENDIF}
begin
  if FRow = nil then
    Exit(False);

  if FOrigin.Y >= FMaxHeight then
  begin
    TruncateAll;
    Exit(False);
  end;

  if not FWordWrap and (FOrigin.X >= FMaxWidth) then
  begin
    TruncateRow;
    // В случае EndEllipsis = True, DrawText выравнивает обрезанный текст
    if FEndEllipsis then 
      Exit(True);
    // если есть выравнивание - надо посчитать всю строку до конца,
    // иначе выравнивание отработает некорректо
    if FRowAlign = taLeftJustify then
      Exit(True);
  end;

  // Блок был сжат - его метрики более невалидны
  if (ABlock.TextSize.cy = 0) or (ABlock.FCharacterCount < ABlock.TextLength) then
    MeasureSize(ABlock);

  if FWordWrap and (FOrigin.X + ABlock.TextSize.cx > FMaxWidth) and (FOrigin.X > 0) then
  begin
    if not OnLineBreak then
    begin
      TruncateAll;
      Exit(False);
    end;
  end;

  if FRowTruncated then
    Exit(True);

{$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
  AReadingDirection := acGetReadingDirection(ABlock.Text, ABlock.TextLength);
  if AReadingDirection = trdLeftToRight then
    FRowRtlRange := False
  else
    if FRowRtlRange then
    begin
      ARange := FRowRtlRanges.Last;
      ARange.Finish := FRow.Count;
      FRowRtlRanges.Last := ARange;
    end
    else
      if AReadingDirection = trdRightToLeft then
      begin
        FRowRtlRanges.Add(TACLRange.Create(FRow.Count, FRow.Count));
        FRowRtlRange := True;
      end;
{$ENDIF}

  ABlock.FPosition := ActualOrigin;
  FOrigin.X := ABlock.FPosition.X + ABlock.TextSize.Width;
  FRow.Add(ABlock);

  if FOrigin.X > FMaxWidth then
    TruncateRow;
  Result := True;
end;

procedure TACLTextLayoutCalculator.MeasureSize(ABlock: TACLTextLayoutBlockText);
var
  ADistance: Integer;
  AWidthScan: PInteger;
begin
  if ABlock.FCharacterWidths = nil then
    ABlock.FCharacterWidths := AllocMem(ABlock.TextLength * SizeOf(Integer));
  GetTextExtentExPoint(Canvas.Handle, ABlock.Text, ABlock.TextLength,
    MaxInt, @ABlock.FCharacterCount, ABlock.FCharacterWidths, ABlock.FTextSize);

  ADistance := 0;
  AWidthScan := ABlock.FCharacterWidths;
  for var I := 0 to ABlock.FCharacterCount - 1 do
  begin
    AWidthScan^ := AWidthScan^ - ADistance;
    Inc(ADistance, AWidthScan^);
    Inc(AWidthScan);
  end;
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
      ABlocks.List[I].FPosition := acRectMirror(ABlocks.List[I].Bounds, R).TopLeft;
  end;
end;

function TACLTextLayoutCalculator.ActualOrigin: TPoint;
begin
  if FBaseline > FRow.Baseline then
    FRow.Baseline := FBaseline;
  Result := TPoint.Create(FOrigin.X, FOrigin.Y + FRow.Baseline - FBaseline);
end;

function TACLTextLayoutCalculator.AddStyle(ABlock: TACLTextLayoutBlockStyle): Boolean;
begin
  Result := FRow <> nil;
  if Result then
  begin
    ABlock.FPosition := ActualOrigin;
    FRow.Add(ABlock);
  end;
end;

function TACLTextLayoutCalculator.CreateEndEllipsisBlock: TACLTextLayoutBlockText;
begin
  Result := TACLTextLayoutBlockText.Create(PChar(acEndEllipsis), Length(acEndEllipsis));
  MeasureSize(Result);
end;

procedure TACLTextLayoutCalculator.CompleteRow;
begin
  if FRow = nil then
    Exit;
  if FRow.Count > 0 then
    FRow.Bounds := FRow.BoundingRect
  else
    FRow.Bounds.Height := LineHeight;

  if (FRow.Bounds.Bottom > FMaxHeight) and FEditControl or (FRow.Bounds.Top > FMaxHeight) then
  begin
    TruncateAll;
    Exit;
  end;

  FOrigin.X := 0;
  FOrigin.Y := FRow.Bounds.Bottom;
  FRows.Add(FRow);

{$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
  for var I := 0 to FRowRtlRanges.Count - 1 do
    Reorder(FRow, FRowRtlRanges.List[I]);
  FRowRtlRanges.Count := 0;
  FRowRtlRange := False;
{$ENDIF}

  if FEndEllipsis then
  begin
    // может так случиться, что следующая строка уже не влезет и нам понадобятся заветные три точки.
    // поэтому считаем их сейчас (в кэш), пока у нас есть актуальный стиль и метрики.
    if FPrevRowEndEllipsis = nil then
      FPrevRowEndEllipsis := CreateEndEllipsisBlock;
    MeasureSize(FPrevRowEndEllipsis);
  end;
end;

procedure TACLTextLayoutCalculator.TruncateAll;
var
  ARow: TACLTextLayoutRow;
begin
  Owner.FTruncated := True;
  FreeAndNil(FRow);
  if FEndEllipsis and (FPrevRowEndEllipsis <> nil) then
  begin
    ARow := FRows.Last;
    if ARow.EndEllipsis = nil then
    begin
      ARow.SetEndEllipsis(FMaxWidth, FPrevRowEndEllipsis);
      FPrevRowEndEllipsis := nil;
    end;
  end;
end;

procedure TACLTextLayoutCalculator.TruncateRow;
begin
  Owner.FTruncated := True;
  if FEndEllipsis then
  begin
    if FRow.EndEllipsis = nil then
      FRow.SetEndEllipsis(FMaxWidth, CreateEndEllipsisBlock);
    FOrigin.X := FRow.EndEllipsis.FPosition.X;
    FRowTruncated := True;
  end;
end;

procedure TACLTextLayoutCalculator.UpdateMetrics;
var
  ATextMetric: TTextMetric;
begin
  GetTextMetrics(Canvas.Handle, ATextMetric);
  FBaseline := ATextMetric.tmHeight - ATextMetric.tmDescent;
  FLineHeight := ATextMetric.tmHeight + ATextMetric.tmExternalLeading;
  FSpaceWidth := Canvas.TextWidth(' ');
end;

{ TACLTextLayoutHitTest }

destructor TACLTextLayoutHitTest.Destroy;
begin
  FreeAndNil(FHyperlinks);
  inherited;
end;

procedure TACLTextLayoutHitTest.Reset;
begin
  FHitObject := nil;
  FreeAndNil(FHyperlinks);
end;

function TACLTextLayoutHitTest.OnBlock(ABlock: TACLTextLayoutBlock): Boolean;
begin
  if PtInRect(ABlock.Bounds, FHitPoint) then
  begin
    FHitObject := ABlock;
    Exit(False);
  end;
  Result := True;
end;

function TACLTextLayoutHitTest.OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean;
begin
  if ABlock.Include then
  begin
    if FHyperlinks = nil then
      FHyperlinks := TStack.Create;
    FHyperlinks.Push(ABlock);
  end
  else
    if (FHyperlinks <> nil) and (FHyperlinks.Count > 0) then
      FHyperlinks.Pop;

  Result := True;
end;

function TACLTextLayoutHitTest.OnLineBreak: Boolean;
begin
  Result := True;
end;

function TACLTextLayoutHitTest.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  Result := OnBlock(ABlock);
end;

function TACLTextLayoutHitTest.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  Result := OnBlock(ABlock);
end;

function TACLTextLayoutHitTest.GetHyperlink: TACLTextLayoutBlockHyperlink;
begin
  if (FHyperlinks <> nil) and (FHyperlinks.Count > 0) then
    Result := FHyperlinks.Peek
  else
    Result := nil;
end;

{ TACLTextLayoutRender }

constructor TACLTextLayoutRender.Create(AOwner: TACLTextLayout; ACanvas: TCanvas);
begin
  inherited Create(ACanvas, AOwner);
  FDefaultTextColor := Owner.GetDefaultTextColor;
  FFontColors := TACLTextLayoutValueStack<TColor>.Create;
  FFillColors := TACLTextLayoutValueStack<TColor>.Create;
  UpdateFillColor;
  UpdateFontColor;
end;

destructor TACLTextLayoutRender.Destroy;
begin
  FreeAndNil(FFillColors);
  FreeAndNil(FFontColors);
  inherited;
end;

function TACLTextLayoutRender.OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean;
begin
  if ABlock.Include then
    FFillColors.Push(ABlock.Color, TACLTextLayoutBlockFillColor)
  else
    FFillColors.Pop(TACLTextLayoutBlockFillColor);

  UpdateFillColor;
  Result := True;
end;

function TACLTextLayoutRender.OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean;
begin
  if ABlock.Include then
    FFontColors.Push(ABlock.Color, TACLTextLayoutBlockFontColor)
  else
    FFontColors.Pop(TACLTextLayoutBlockFontColor);

  UpdateFontColor;
  Result := True;
end;

function TACLTextLayoutRender.OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean;
begin
  OnFontStyle(ABlock);
  if ABlock.Include then
    FFontColors.Push(Owner.GetDefaultHyperLinkColor, TACLTextLayoutBlockHyperlink)
  else
    FFontColors.Pop(TACLTextLayoutBlockHyperlink);

  UpdateFontColor;
  Result := True;
end;

function TACLTextLayoutRender.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
var
  ABounds: TRect;
begin
  ABounds := ABlock.Bounds;
  if HasBackground then
    Canvas.FillRect(ABounds);
  if fsUnderline in Font.Style then
    ExtTextOut(Canvas.Handle, ABounds.Left, ABounds.Top, ETO_CLIPPED, @ABounds, ' ', 1, nil);
  Result := True;
end;

function TACLTextLayoutRender.OnText(AText: TACLTextLayoutBlockText): Boolean;
begin
  if AText.FCharacterCount > 0 then
  begin
    ExtTextOut(Canvas.Handle, AText.FPosition.X, AText.FPosition.Y, 
      0, nil, AText.Text, AText.FCharacterCount, AText.FCharacterWidths);
  end;
  Result := True;
end;

procedure TACLTextLayoutRender.UpdateFillColor;
var
  AFillColor: TColor;
begin
  if FFillColors.Count > 0 then
    AFillColor := FFillColors.Peek
  else
    AFillColor := clNone;

  FHasBackground := (AFillColor <> clNone) and (AFillColor <> clDefault);
  if FHasBackground then
    Canvas.Brush.Color := AFillColor
  else
    Canvas.Brush.Style := bsClear;
end;

procedure TACLTextLayoutRender.UpdateFontColor;
var
  AFontColor: TColor;
begin
  AFontColor := clDefault;
  if FFontColors.Count > 0 then
    AFontColor := FFontColors.Peek;
  if AFontColor = clDefault then
    AFontColor := FDefaultTextColor;
  Font.Color := AFontColor;
end;

{ TACLTextPlainTextExporter }

constructor TACLTextPlainTextExporter.Create(ASource: TACLTextLayout; ATarget: TACLStringBuilder);
begin
  inherited Create(ASource);
  FTarget := ATarget;
end;

function TACLTextPlainTextExporter.OnLineBreak: Boolean;
begin
  FTarget.AppendLine;
  Result := True;
end;

function TACLTextPlainTextExporter.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  FTarget.Append(Space);
  Result := True;
end;

function TACLTextPlainTextExporter.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  FTarget.Append(ABlock.ToString);
  Result := True;
end;

{ TACLTextImporter }

class constructor TACLTextImporter.Create;
begin
  FEmailValidator := TRegEx.Create(EmailPattern);
end;

class function TACLTextImporter.AllocContext(const ASettings: TACLTextFormatSettings): TContext;
var
  AIndex: Integer;
begin
  Result := TContext.Create;

{$REGION 'TokenDetectors'}
  SetLength(Result.TokenDetectors, 4 + Ord(ASettings.AllowCppLikeLineBreaks) + Ord(ASettings.AllowFormatting));

  AIndex := 0;
  if ASettings.AllowFormatting then
  begin
    Result.TokenDetectors[AIndex] := IsStyle;
    Inc(AIndex);
  end;

  Result.TokenDetectors[AIndex] := IsLineBreak;
  Inc(AIndex);
  if ASettings.AllowCppLikeLineBreaks then
  begin
    Result.TokenDetectors[AIndex] := IsLineBreakCpp;
    Inc(AIndex);
  end;

  Result.TokenDetectors[AIndex] := IsSpace;
  Inc(AIndex);
  Result.TokenDetectors[AIndex] := IsDelimiter;
  Inc(AIndex);
  Result.TokenDetectors[AIndex] := IsText;
{$ENDREGION}

{$REGION 'TokenInTextDetectors'}
  AIndex := 0;
  SetLength(Result.TokenInTextDetectors,
    Ord(ASettings.AllowAutoEmailDetect) +
    Ord(ASettings.AllowAutoTimeCodeDetect) +
    Ord(ASettings.AllowAutoURLDetect));
  if ASettings.AllowAutoEmailDetect then
  begin
    Result.TokenInTextDetectors[AIndex] := IsEmail;
    Inc(AIndex);
  end;
  if ASettings.AllowAutoURLDetect then
  begin
    Result.TokenInTextDetectors[AIndex] := IsURL;
    Inc(AIndex);
  end;
  if ASettings.AllowAutoTimeCodeDetect then
    Result.TokenInTextDetectors[AIndex] := IsTimeCode;
{$ENDREGION}
end;

class function TACLTextImporter.IsDelimiter(Ctx: TContext; var Scan: PWideChar): Boolean;
begin
  Result := acContains(Scan^, Delimiters);
  if Result then
    Ctx.Blocks.AddInit(TACLTextLayoutBlockText.Create(Scan, 1), Scan, 1);
end;

class function TACLTextImporter.IsEmail(Ctx: TContext; S: PWideChar; L: Integer): Boolean;
var
  ALink: UnicodeString;
begin
  if WStrScan(S, L, '@') <> nil then // быстрая проверка
  begin
    ALink := acMakeString(S, L);
    if FEmailValidator.IsMatch(ALink) then
    begin
      Ctx.Blocks.Add(TACLTextLayoutBlockHyperlink.Create(acMailToPrefix + ALink, True));
      Ctx.Blocks.Add(TACLTextLayoutBlockText.Create(S, L));
      Ctx.Blocks.Add(TACLTextLayoutBlockHyperlink.Create(acEmptyStr, False));
      Exit(True);
    end;
  end;
  Result := False;
end;

class function TACLTextImporter.IsLineBreak(Ctx: TContext; var Scan: PWideChar): Boolean;
begin
  Result := True;
  if Scan^ = #10 then //#10
    Ctx.Blocks.AddInit(TACLTextLayoutBlockLineBreak.Create, Scan, 1)
  else if Scan^ = #13 then // #13 or #13#10
    Ctx.Blocks.AddInit(TACLTextLayoutBlockLineBreak.Create, Scan, 1 + Ord((Scan + 1)^ = #10))
  else
    Result := False;
end;

class function TACLTextImporter.IsLineBreakCpp(Ctx: TContext; var Scan: PWideChar): Boolean;
begin
  Result := (Scan^ = '\') and ((Scan + 1)^ = 'n');
  if Result then
    Ctx.Blocks.AddInit(TACLTextLayoutBlockLineBreak.Create, Scan, 2);
end;

class function TACLTextImporter.IsSpace(Ctx: TContext; var Scan: PWideChar): Boolean;
begin
  Result := acContains(Scan^, Spaces);
  if Result then
    Ctx.Blocks.AddInit(TACLTextLayoutBlockSpace.Create, Scan, 1);
end;

class function TACLTextImporter.IsStyle(Ctx: TContext; var Scan: PWideChar): Boolean;
var
  ABlock: TACLTextLayoutBlockStyle;
  AIsClosing: Boolean;
  AScanEnd: PWideChar;
  AScanParam: PWideChar;
  AScanTag: PWideChar;
  ATagLength: Integer;
begin
  Result := False;
  if Scan^ = '[' then
  begin
    AScanEnd := WStrScan(Scan, ']');
    if AScanEnd = nil then
      Exit;

    AScanTag := Scan + 1;
    AIsClosing := AScanTag^ = '/';
    if AIsClosing then
    begin
      AScanParam := AScanEnd;
      Inc(AScanTag);
    end
    else
    begin
      AScanParam := WStrScan(AScanTag, acStringLength(Scan, AScanEnd), '=');
      if AScanParam = nil then
        AScanParam := AScanEnd;
    end;

    ATagLength := acStringLength(AScanTag, AScanParam);
    if acCompareTokens('B', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFontStyle.Create(TFontStyle.fsBold, not AIsClosing)
    else if acCompareTokens('U', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFontStyle.Create(TFontStyle.fsUnderline, not AIsClosing)
    else if acCompareTokens('I', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFontStyle.Create(TFontStyle.fsItalic, not AIsClosing)
    else if acCompareTokens('S', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFontStyle.Create(TFontStyle.fsStrikeOut, not AIsClosing)
    else if acCompareTokens('COLOR', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFontColor.Create(acExtractString(AScanParam + 1, AScanEnd), not AIsClosing)
    else if acCompareTokens('BACKCOLOR', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFillColor.Create(acExtractString(AScanParam + 1, AScanEnd), not AIsClosing)
    else if acCompareTokens('BIG', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFontBig.Create(not AIsClosing)
    else if acCompareTokens('SMALL', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFontSmall.Create(not AIsClosing)
    else if acCompareTokens('SIZE', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFontSize.Create(acExtractString(AScanParam + 1, AScanEnd), not AIsClosing)
    else if acCompareTokens('URL', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockHyperlink.Create(acExtractString(AScanParam + 1, AScanEnd), not AIsClosing)
    else
      ABlock := nil;

    Result := ABlock <> nil;
    if Result then
    begin
      Inc(AScanEnd);
      if ABlock.ClassType = TACLTextLayoutBlockHyperlink then
      begin
        if AIsClosing then
          Dec(Ctx.HyperlinkDepth)
        else
          Inc(Ctx.HyperlinkDepth);
      end;
      Ctx.Blocks.AddInit(ABlock, Scan, acStringLength(Scan, AScanEnd));
    end;
  end;
end;

class function TACLTextImporter.IsText(Ctx: TContext; var Scan: PWideChar): Boolean;
var
  ACursor: PWideChar;
  ALength: Integer;
begin
  Result := True;
  ACursor := Scan;
  repeat
    Inc(ACursor);
    if (ACursor^ = #0) or acContains(ACursor^, Delimiters) then
    begin
      ALength := acStringLength(Scan, ACursor);
      if ALength > 0 then
      begin
        if Ctx.HyperlinkDepth <= 0 then
          for var I := Low(Ctx.TokenInTextDetectors) to High(Ctx.TokenInTextDetectors) do
          begin
            if Ctx.TokenInTextDetectors[I](Ctx, Scan, ALength) then
            begin
              Inc(Scan, ALength);
              Exit;
            end;
          end;
        Ctx.Blocks.AddInit(TACLTextLayoutBlockText.Create(Scan, ALength), Scan, ALength);
      end;
      Break;
    end;
  until False;
end;

class function TACLTextImporter.IsTimeCode(Ctx: TContext; S: PWideChar; L: Integer): Boolean;
var
  ATime: Single;
begin
  Result := False;
  if S^.IsDigit then
  begin
    if Ctx.Blocks.Count > 0 then
    begin
      if ((S - 1)^ > ' ') and not CharInSet((S - 1)^, TACLTimeFormat.BracketsIn) then
        Exit;
    end;
    Result := TACLTimeFormat.Parse(acMakeString(S, L), ATime);
    if Result then
    begin
      Ctx.Blocks.Add(TACLTextLayoutBlockHyperlink.Create(TACLTextLayout.TimeCodePrefix + IntToStr(Trunc(ATime)), True));
      Ctx.Blocks.Add(TACLTextLayoutBlockText.Create(S, L));
      Ctx.Blocks.Add(TACLTextLayoutBlockHyperlink.Create(acEmptyStr, False));
    end;
  end;
end;

class function TACLTextImporter.IsURL(Ctx: TContext; S: PWideChar; L: Integer): Boolean;
const
  Prefix: PWideChar = 'www.';
begin
  if acIsUrlFileName(S, L) then
  begin
    Ctx.Blocks.Add(TACLTextLayoutBlockHyperlink.Create(acMakeString(S, L), True));
    Ctx.Blocks.Add(TACLTextLayoutBlockText.Create(S, L));
    Ctx.Blocks.Add(TACLTextLayoutBlockHyperlink.Create(acEmptyStr, False));
    Exit(True);
  end;

  if (L > 4) and CompareMem(S, Prefix, 4) then
  begin
    if WStrScan(S + 4, L - 4, '.') <> nil then
    begin
      Ctx.Blocks.Add(TACLTextLayoutBlockHyperlink.Create('https://' + acMakeString(S, L), True));
      Ctx.Blocks.Add(TACLTextLayoutBlockText.Create(S, L));
      Ctx.Blocks.Add(TACLTextLayoutBlockHyperlink.Create(acEmptyStr, False));
      Exit(True);
    end;
  end;

  Result := False;
end;

{ TACLTextLayoutRefreshHelper }

function TACLTextLayoutRefreshHelper.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  ABlock.Flush;
  Result := True;
end;

{ TACLTextFormattedTextExporter }

function TACLTextFormattedTextExporter.OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean;
begin
  if ABlock.Include then
    FTarget.Append('[BACKCOLOR=').Append(ColorToString(ABlock.Color)).Append(']')
  else
    FTarget.Append('[/BACKCOLOR]');

  Result := True;
end;

function TACLTextFormattedTextExporter.OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean;
begin
  if ABlock.Include then
    FTarget.Append('[COLOR=').Append(ColorToString(ABlock.Color)).Append(']')
  else
    FTarget.Append('[/COLOR]');

  Result := True;
end;

function TACLTextFormattedTextExporter.OnFontSize(ABlock: TACLTextLayoutBlockFontSize): Boolean;
begin
  if ABlock.Include then
    FTarget.Append('[SIZE=').Append(VarToStr(ABlock.Value)).Append(']')
  else
    FTarget.Append('[/SIZE]');

  Result := True;
end;

function TACLTextFormattedTextExporter.OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean;
const
  Map: array[TFontStyle] of string = ('B', 'I', 'U', 'S');
begin
  if ABlock.Include then
    FTarget.Append('[').Append(Map[ABlock.Style]).Append(']')
  else
    FTarget.Append('[/').Append(Map[ABlock.Style]).Append(']');

  Result := True;
end;

function TACLTextFormattedTextExporter.OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean;
begin
  if ABlock.Include then
    FTarget.Append('[URL=').Append(ABlock.Hyperlink).Append(']')
  else
    FTarget.Append('[/URL]');

  Result := True;
end;

end.
