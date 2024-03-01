{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*     Formatted Text based on BB Codes      *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.TextLayout;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
  LazUtf8,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Contnrs,
  {System.}Generics.Collections,
  {System.}Generics.Defaults,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  {System.}Variants,
  System.RegularExpressions,
  System.UITypes,
  // VCL
  {Vcl.}Graphics,
  // ACL
  ACL.Classes.Collections,
  ACL.Parsers,
  ACL.FastCode,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Math,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.FileSystem,
  ACL.Utils.Shell,
  ACL.Utils.Strings;

type
  TACLTextLayout = class;
  TACLTextLayoutExporter = class;
  TACLTextLayoutRender = class;

{$REGION ' Blocks '}

  { TACLTextLayoutBlock }

  TACLTextLayoutBlockClass = class of TACLTextLayoutBlock;
  TACLTextLayoutBlock = class abstract
  protected
    FPosition: TPoint;
    FPositionInText: PChar;
    FLength: Word;
  public
    function Bounds: TRect; virtual;
    function Export(AExporter: TACLTextLayoutExporter): Boolean; virtual;
    procedure Shrink(ARender: TACLTextLayoutRender; AMaxRight: Integer); virtual;
    //# Properties
    property Position: TPoint read FPosition;
  end;

  { TACLTextLayoutBlockList }

  TACLTextLayoutBlockList = class(TACLObjectList<TACLTextLayoutBlock>)
  protected
    procedure AddInit(ABlock: TACLTextLayoutBlock; var AScan: PChar; ABlockLength: Integer);
    procedure AddSpan(ABlock: TACLTextLayoutBlockList);
    function CountOfClass(AClass: TACLTextLayoutBlockClass): Integer;
  public
    function BoundingRect: TRect; virtual;
    function Export(AExporter: TACLTextLayoutExporter; AFreeExporter: Boolean): Boolean; virtual;
    procedure Offset(ADeltaX, ADeltaY: Integer); virtual;
  end;

  { TACLTextLayoutBlockLineBreak }

  TACLTextLayoutBlockLineBreak = class(TACLTextLayoutBlock)
  public
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
  end;

  { TACLTextLayoutBlockSpace }

  TACLTextLayoutBlockSpace = class(TACLTextLayoutBlock)
  protected
    FWidth, FHeight: Word;
  public
    function Bounds: TRect; override;
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    procedure Shrink(ARender: TACLTextLayoutRender; AMaxRight: Integer); override;
  end;

  { TACLTextLayoutBlockText }

  TACLTextLayoutBlockText = class(TACLTextLayoutBlock)
  protected
    FLengthVisible: Word;
    FMetrics: Pointer;
    FWidth, FHeight: Word;
  public
    constructor Create(AText: PChar; ATextLength: Word);
    destructor Destroy; override;
    function Bounds: TRect; override;
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    procedure Flush; inline;
    procedure Shrink(ARender: TACLTextLayoutRender; AMaxRight: Integer); override;
    function ToString: string; override;
    //# Properties
    property Text: PChar read FPositionInText;
    property TextLength: Word read FLength;
    property TextLengthVisible: Word read FLengthVisible;
    property TextHeight: Word read FHeight;
    property TextWidth: Word read FWidth;
  end;

  { TACLTextLayoutBlockStyle }

  TACLTextLayoutBlockStyle = class(TACLTextLayoutBlock)
  strict private
    FInclude: Boolean;
  public
    constructor Create(AInclude: Boolean);
    property Include: Boolean read FInclude;
  end;

  { TACLTextLayoutBlockFillColor }

  TACLTextLayoutBlockFillColor = class(TACLTextLayoutBlockStyle)
  strict private
    FColor: TColor;
  public
    constructor Create(const AColor: string; AInclude: Boolean);
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    property Color: TColor read FColor;
  end;

  { TACLTextLayoutBlockFontColor }

  TACLTextLayoutBlockFontColor = class(TACLTextLayoutBlockFillColor)
  public
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
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

  { TACLTextLayoutBlockFontStyle }

  TACLTextLayoutBlockFontStyle = class(TACLTextLayoutBlockStyle)
  strict private
    FStyle: TFontStyle;
  public
    constructor Create(AStyle: TFontStyle; AInclude: Boolean);
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    property Style: TFontStyle read FStyle;
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

  { TACLTextLayoutBlockSpan }

  TACLTextLayoutBlockSpan = class(TACLTextLayoutBlock)
  protected
    FBlocks: TArray<TACLTextLayoutBlock>;
  public
    constructor Create(ABlocks: TACLTextLayoutBlockList);
    destructor Destroy; override;
    function Bounds: TRect; override;
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    property Blocks: TArray<TACLTextLayoutBlock> read FBlocks;
  end;

{$ENDREGION}

{$REGION ' Rows '}

  { TACLTextLayoutRow }

  TACLTextLayoutRow = class(TACLTextLayoutBlockList)
  strict private
    FBaseline: Integer;
    FBounds: TRect;
    FEndEllipsis: TACLTextLayoutBlockText;

    procedure SetBaseline(AValue: Integer);
  protected
    procedure SetEndEllipsis(ARender: TACLTextLayoutRender;
      ARightSide: Integer; AEndEllipsis: TACLTextLayoutBlockText);
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

{$ENDREGION}

{$REGION ' Exporters '}

  { TACLTextLayoutRender }

  TACLTextLayoutRender = class
  public
    procedure GetMetrics(out ABaseline, ALineHeight, ASpaceWidth: Integer); virtual; abstract;
    procedure Measure(ABlock: TACLTextLayoutBlockText); virtual; abstract;
    procedure SetFill(AValue: TColor); virtual; abstract;
    procedure SetFont(AFont: TFont); virtual; abstract;
    procedure Shrink(ABlock: TACLTextLayoutBlockText; AMaxSize: Integer); virtual; abstract;
    procedure TextOut(ABlock: TACLTextLayoutBlockText; X, Y: Integer); virtual; abstract;
  end;

  { TACLTextLayoutValueStack<T> }

  TACLTextLayoutValueStack<T> = class
  strict private
    FCount: Integer;
    FData: array of TPair<T, TClass>;
  public
    constructor Create;
    procedure Assign(ASource: TACLTextLayoutValueStack<T>);
    function Peek: T;
    procedure Pop(AInvoker: TClass);
    procedure Push(const AValue: T; AInvoker: TClass);
    property Count: Integer read FCount;
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
    function OnLineBreak(ABlock: TACLTextLayoutBlock): Boolean; virtual;
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; virtual;
    function OnSpan(ABlock: TACLTextLayoutBlockSpan): Boolean; virtual;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; virtual;
    //# Properties
    property Owner: TACLTextLayout read FOwner;
  public
    constructor Create(AOwner: TACLTextLayout);
  end;

  { TACLTextLayoutVisualExporter }

  TACLTextLayoutVisualExporter = class(TACLTextLayoutExporter)
  strict private
    FFont: TFont;
    FFontSizes: TACLTextLayoutValueStack<Integer>;
    FFontStyles: array[TFontStyle] of Word;
    FRender: TACLTextLayoutRender;
  protected
    procedure CopyState(ASource: TACLTextLayoutVisualExporter); virtual;
    procedure FontChanged(Sender: TObject); virtual;
    function OnFontSize(ABlock: TACLTextLayoutBlockFontSize): Boolean; override;
    function OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean; override;
    //# Properties
    property Render: TACLTextLayoutRender read FRender;
    property Font: TFont read FFont;
  public
    constructor Create(AOwner: TACLTextLayout; ARender: TACLTextLayoutRender); virtual;
    destructor Destroy; override;
    procedure AfterConstruction; override;
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
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  public
    destructor Destroy; override;
    procedure Reset;
    //# Properties
    property HitObject: TACLTextLayoutBlock read FHitObject;
    property HitPoint: TPoint read FHitPoint write FHitPoint;
    property Hyperlink: TACLTextLayoutBlockHyperlink read GetHyperlink;
  end;

  { TACLPlainTextExporter }

  TACLPlainTextExporterClass = class of TACLPlainTextExporter;
  TACLPlainTextExporter = class(TACLTextLayoutExporter)
  protected
    FTarget: TACLStringBuilder;
  public
    constructor Create(ASource: TACLTextLayout; ATarget: TACLStringBuilder); reintroduce;
    function OnLineBreak(ABlock: TACLTextLayoutBlock): Boolean; override;
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  end;

  { TACLTextLayoutPainter }

  TACLTextLayoutPainter = class(TACLTextLayoutVisualExporter)
  strict private
    FDefaultTextColor: TColor;
    FFillColors: TACLTextLayoutValueStack<TColor>;
    FTextColors: TACLTextLayoutValueStack<TColor>;
    procedure UpdateTextColor;
  protected
    function OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean; override;
    function OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean; override;
    function OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean; override;
    function OnText(AText: TACLTextLayoutBlockText): Boolean; override;
  public
    constructor Create(AOwner: TACLTextLayout; ARender: TACLTextLayoutRender); override;
    destructor Destroy; override;
  end;

{$ENDREGION}

{$REGION ' Native Render '}

  TACLTextLayoutCanvasRenderClass = class of TACLTextLayoutCanvasRender;
  TACLTextLayoutCanvasRender = class(TACLTextLayoutRender)
  strict private
    FCanvas: TCanvas;
  public
    constructor Create(ACanvas: TCanvas); virtual;
    procedure GetMetrics(out ABaseline, ALineHeight, ASpaceWidth: Integer); override;
    procedure Measure(ABlock: TACLTextLayoutBlockText); override;
    procedure SetFill(AValue: TColor); override;
    procedure SetFont(AFont: TFont); override;
    procedure Shrink(ABlock: TACLTextLayoutBlockText; AMaxSize: Integer); override;
    procedure TextOut(ABlock: TACLTextLayoutBlockText; X, Y: Integer); override;
    property Canvas: TCanvas read FCanvas;
  end;

{$ENDREGION}

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

  { TACLTextLayout }

  /// <summary>
  ///  Implements text-box with bb-code based formatting support.
  ///  Following bb-codes are supported:
  ///  [b]bold[/b]
  ///  [i]italic[/i]
  ///  [u]underline[/u]
  ///  [s]strike out[/s]
  ///  [color=#RRGGBB]text color[/color]
  ///  [big]Big text[/big]
  ///  [small]Small text[/small]
  ///  [size=XXX]text size[/size], integer value for font height in pt., float value for zoom-factor.
  ///  [backcolor=#RRGGBB]background color[/backcolor]
  ///  [url=hyperlink]text with hyperlink[/url]
  /// </summary>
  TACLTextLayout = class
  public const
    TimeCodePrefix = 'time:';
  strict private
    FBounds: TRect;
    FFont: TFont;
    FOptions: Integer;
    FHorzAlignment: TAlignment;
    FTargetDpi: Integer;
    FText: string;
    FVertAlignment: TVerticalAlignment;

    procedure SetBounds(const ABounds: TRect);
    procedure SetHorzAlignment(AValue: TAlignment);
    procedure SetOptions(AValue: Integer);
    procedure SetVertAlignment(AValue: TVerticalAlignment);
  protected
    FBlocks: TACLTextLayoutBlockList;
    FLayout: TACLTextLayoutRows;
    FLayoutIsDirty: Boolean;
    FTruncated: Boolean;

    function GetDefaultHyperLinkColor: TColor; virtual;
    function GetDefaultTextColor: TColor; virtual;
    function GetPadding: TRect; virtual;
  public
    constructor Create(AFont: TFont);
    destructor Destroy; override;
    //# General
    procedure Calculate(ACanvas: TCanvas); overload;
    procedure Calculate(ARender: TACLTextLayoutRender); overload;
    procedure FlushCalculatedValues;
    procedure Draw(ACanvas: TCanvas); overload;
    procedure Draw(ACanvas: TCanvas; const AClipRect: TRect); overload;
    procedure Draw(ARender: TACLTextLayoutRender); overload; virtual;
    procedure DrawTo(ACanvas: TCanvas; const AClipRect: TRect; const AOrigin: TPoint);
    function MeasureSize: TSize;

    //# Search
    function FindBlock(APositionInText: Integer; out ABlock: TACLTextLayoutBlock): Boolean;
    function FindHyperlink(const P: TPoint; out AHyperlink: TACLTextLayoutBlockHyperlink): Boolean;
    procedure HitTest(const P: TPoint; AHitTest: TACLTextLayoutHitTest);

    //# Text
    function ToString: string; override;
    function ToStringEx(ExporterClass: TACLPlainTextExporterClass): string;
    procedure SetText(const AText: string; const ASettings: TACLTextFormatSettings);

    //# Options
    procedure SetOption(AOptions: Integer{atoXXX}; AState: Boolean);
    property Bounds: TRect read FBounds write SetBounds;
    property Options: Integer read FOptions write SetOptions;
    property TargetDpi: Integer read FTargetDpi write FTargetDpi;
    property HorzAlignment: TAlignment read FHorzAlignment write SetHorzAlignment;
    property VertAlignment: TVerticalAlignment read FVertAlignment write SetVertAlignment;

    //# State
    property Font: TFont read FFont;
    property IsTruncated: Boolean read FTruncated;
    property Text: string read FText;
  end;

  { TACLTextViewInfo }

  TACLTextViewInfo = class(TACLTextLayoutBlockText)
  strict private
    FText: string;
  public
    constructor Create(const AText: string); reintroduce;
    function Measure(ARender: TACLTextLayoutRender): TSize;
  end;

const
  atoAutoHeight  = 1;
  atoAutoWidth   = 2;
  atoEditControl = 4;
  atoEndEllipsis = 8;
  atoNoClip      = 16;
  atoSingleLine  = 32;
  atoWordWrap    = 64;

type
  TACLTextReadingDirection = (trdNeutral, trdLeftToRight, trdRightToLeft);

var
  DefaultTextLayoutCanvasRender: TACLTextLayoutCanvasRenderClass = TACLTextLayoutCanvasRender;

/// <summary>
///  Аналог функции DrawText на базе TextLayout (c поддержкой форматирования)<p>
///  Поддерживаются следующие флаги:
///    DT_LEFT, DT_CENTER, DT_RIGHT, DT_CALCRECT, DT_TOP, DT_VCENTER, DT_BOTTOM,
///    DT_WORDBREAK, DT_NOCLIP, DT_SINGLELINE, DT_END_ELLIPSIS, DT_EDITCONTROL,
///    DT_NOPREFIX, DT_HIDEPREFIX
/// </summary>
procedure acAdvDrawText(ACanvas: TCanvas;
  const AText: string; var ABounds: TRect; AFlags: Cardinal);
procedure acExpandPrefixes(var AText: string; AHide: Boolean);
procedure acDrawFormattedText(ACanvas: TCanvas; const S: string; const R: TRect;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AWordWrap: Boolean);

function acGetReadingDirection(const C: Char): TACLTextReadingDirection; overload;
function acGetReadingDirection(P: PChar; L: Integer): TACLTextReadingDirection; overload; inline;
implementation

type
{$REGION ' Calculator '}

  { TACLTextLayoutCalculator }

  TACLTextLayoutCalculator = class(TACLTextLayoutVisualExporter)
  strict private const
    RtlRangeCapacity = 8;
  strict private
    FEditControl: Boolean;
    FEndEllipsis: Boolean;
    FMaxHeight: Integer;
    FMaxWidth: Integer;
    FSingleLine: Boolean;
    FWordWrap: Boolean;

    FBaseline: Integer;
    FLineHeight: Integer;
    FSpaceWidth: Integer;

    FBounds: TRect;
    FOrigin: TPoint;
    FRow: TACLTextLayoutRow;
    FRowHasAlignment: Boolean;
    FRowTruncated: Boolean;
  {$IFDEF ACL_TEXTLAYOUT_RTL}
    FRowRtlRange: Boolean;
    FRowRtlRanges: TACLList<TACLRange>;
  {$ENDIF}
    FRows: TACLTextLayoutRows;
    FPrevRowEndEllipsis: TACLTextLayoutBlockText;

    function AddBlock(ABlock: TACLTextLayoutBlock; AWidth: Integer = 0): Boolean; inline;
    function AddBlockOfContent(ABlock: TACLTextLayoutBlock; AWidth: Integer): Boolean; inline;
    procedure AlignRows;
    procedure CompleteRow;
    procedure Reorder(ABlocks: TACLTextLayoutBlockList; const ARange: TACLRange);
    procedure TruncateAll;
    procedure TruncateRow;
  protected
    procedure FontChanged(Sender: TObject); override;

    //# Handlers
    function OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean; override;
    function OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean; override;
    function OnFontSize(ABlock: TACLTextLayoutBlockFontSize): Boolean; override;
    function OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean; override;
    function OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean; override;
    function OnLineBreak(ABlock: TACLTextLayoutBlock = nil): Boolean; override;
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnSpan(ABlock: TACLTextLayoutBlockSpan): Boolean; override;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;

    property Baseline: Integer read FBaseline;
    property LineHeight: Integer read FLineHeight;
    property SpaceWidth: Integer read FSpaceWidth;
  public
    constructor Create(AOwner: TACLTextLayout; ARender: TACLTextLayoutRender); override;
    constructor CreateSpan(ACalculator: TACLTextLayoutCalculator);
    destructor Destroy; override;
  end;

{$ENDREGION}

{$REGION ' Importer '}

  { TACLTextImporter }

  TACLTextImporter = class
  strict private const
    FontScalingBig = 1.10;
    FontScalingSmall = 0.9;
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
  {$REGION ' Sub-Types '}
    TContext = class;
    TTokenDetector = function (Ctx: TContext; var Scan: PChar): Boolean;
    TTokenDetectorInText = function (Ctx: TContext; S: PChar; L: Integer): Boolean;
    TContext = class
    public
      HyperlinkDepth: Integer;
      TokenDetectors: array of TTokenDetector;
      TokenInTextDetectors: array of TTokenDetectorInText;
      Output: TACLTextLayoutBlockList;
      Span: TACLTextLayoutBlockList;
      destructor Destroy; override;
    end;
  {$ENDREGION}
  protected
    class function AllocContext(const ASettings: TACLTextFormatSettings;
      AOutput: TACLTextLayoutBlockList): TACLTextImporter.TContext; virtual;
    //# Token Detectors
    class function IsDelimiter(Ctx: TContext; var Scan: PChar): Boolean; static;
    class function IsLineBreak(Ctx: TContext; var Scan: PChar): Boolean; static;
    class function IsLineBreakCpp(Ctx: TContext; var Scan: PChar): Boolean; static;
    class function IsSpace(Ctx: TContext; var Scan: PChar): Boolean; static;
    class function IsStyle(Ctx: TContext; var Scan: PChar): Boolean; static;
    class function IsText(Ctx: TContext; var Scan: PChar): Boolean; static;
    // # TokenInText Detectors
    class function IsEmail(Ctx: TContext; S: PChar; L: Integer): Boolean; static;
    class function IsTimeCode(Ctx: TContext; S: PChar; L: Integer): Boolean; static;
    class function IsURL(Ctx: TContext; S: PChar; L: Integer): Boolean; static;
  public
    class constructor Create;
  end;

{$ENDREGION}

  TACLTextLayoutRefreshHelper = class(TACLTextLayoutExporter)
  protected
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  end;

{$REGION ' BiDi Support '}
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

function acGetReadingDirection(P: PChar; L: Integer): TACLTextReadingDirection;
begin
  if L > 0 then
    Result := acGetReadingDirection(P^)
  else
    Result := trdNeutral;
end;

{$REGION ' acAdvDrawText '}

procedure acExpandPrefixes(var AText: string; AHide: Boolean);
var
{$IFDEF FPC}
  ABytesInChar: Integer;
{$ENDIF}
  ABuffer: TACLStringBuilder;
  AChars: PChar;
  ALength: Integer;
  APrefix: Boolean;
begin
  if AText.Contains('&') then
  begin
    APrefix := False;
    ALength := Length(AText);
    ABuffer := TACLStringBuilder.Create(ALength + 6);
    try
      AChars := PChar(AText);
      while ALength > 0 do
      begin
        if AChars^ = '&' then
        begin
          if APrefix then
            ABuffer.Append(AChars^);
          APrefix := not APrefix;
        end
        else
        begin
          if APrefix and not AHide then
          begin
            ABuffer.Append('[u]');
            ABuffer.Append(AChars^);
          {$IFDEF FPC}
            ABytesInChar := UTF8CodepointSize(AChars) - 1;
            if ABytesInChar > 0 then
            begin
              ABuffer.Append(AChars + 1, ABytesInChar);
              Dec(ALength, ABytesInChar);
              Inc(AChars, ABytesInChar);
            end;
          {$ENDIF}
            ABuffer.Append('[/u]');
            AHide := True; // винда показывает только одно подчеркивание
          end
          else
            ABuffer.Append(AChars^);
          APrefix := False;
        end;
        Dec(ALength);
        Inc(AChars);
      end;
      AText := ABuffer.ToString;
    finally
      ABuffer.Free;
    end;
  end;
end;

procedure acAdvDrawText(ACanvas: TCanvas;
  const AText: string; var ABounds: TRect; AFlags: Cardinal);
const
  //DT_DEFAULT_TABWIDTH = 8;
  DT_REQUIRE_MAXHEIGHT = DT_EDITCONTROL or DT_END_ELLIPSIS;
var
  LText: string;
  LTextLayout: TACLTextLayout;
begin
  LTextLayout := TACLTextLayout.Create(ACanvas.Font);
  try
    // Text
    LText := AText;
    if AFlags and DT_NOPREFIX = 0 then
      acExpandPrefixes(LText, AFlags and DT_HIDEPREFIX <> 0);
    //if AFlags and DT_EXPANDTABS <> 0 then
    //begin
    //  ATabWidth := DT_DEFAULT_TABWIDTH;
    //  if AFlags and DT_TABSTOP <> 0 then
    //  begin
    //    ATabWidth := LoWord(AFlags) shr 8;
    //    if ATabWidth <= 0 then
    //      ATabWidth := DT_DEFAULT_TABWIDTH;
    //    AFlags := AFlags and $FFFF00FF;
    //  end;
    //end;
    LTextLayout.SetText(LText, TACLTextFormatSettings.Formatted);

    // Alignment
    if AFlags and DT_CALCRECT = 0 then
    begin
      if AFlags and DT_CENTER <> 0 then
        LTextLayout.HorzAlignment := taCenter
      else if AFlags and DT_RIGHT <> 0 then
        LTextLayout.HorzAlignment := taRightJustify;

      if AFlags and DT_VCENTER <> 0 then
        LTextLayout.VertAlignment := taVerticalCenter
      else if AFlags and DT_BOTTOM <> 0 then
        LTextLayout.VertAlignment := taAlignBottom;
    end;

    // Settings
    LTextLayout.SetOption(atoAutoHeight, AFlags and DT_REQUIRE_MAXHEIGHT = 0);
    LTextLayout.SetOption(atoEditControl, AFlags and DT_EDITCONTROL <> 0);
    LTextLayout.SetOption(atoEndEllipsis, AFlags and DT_END_ELLIPSIS <> 0);
    LTextLayout.SetOption(atoNoClip, AFlags and DT_NOCLIP <> 0);
    LTextLayout.SetOption(atoSingleLine, AFlags and DT_SINGLELINE <> 0);
    LTextLayout.SetOption(atoWordWrap, AFlags and DT_WORDBREAK <> 0);
    LTextLayout.Bounds := ABounds;

    // Result
    if AFlags and DT_CALCRECT = 0 then
      LTextLayout.Draw(ACanvas)
    else
    begin
      LTextLayout.Calculate(ACanvas);
      ABounds.Size := LTextLayout.MeasureSize;
    end;
  finally
    LTextLayout.Free;
  end;
end;

procedure acDrawFormattedText(ACanvas: TCanvas; const S: string; const R: TRect;
  AHorzAlignment: TAlignment; AVertAlignment: TVerticalAlignment; AWordWrap: Boolean);
var
  AFont: TFont;
  AText: TACLTextLayout;
begin
  if (S <> '') and acRectVisible(ACanvas.Handle, R) then
  begin
    AFont := ACanvas.Font.Clone;
    try
      AText := TACLTextLayout.Create(AFont);
      try
        AText.SetOption(atoWordWrap, AWordWrap);
        AText.SetText(S, TACLTextFormatSettings.Default);
        AText.HorzAlignment := AHorzAlignment;
        AText.VertAlignment := AVertAlignment;
        AText.Bounds := R;
        AText.Draw(ACanvas);
      finally
        AText.Free;
      end;
      ACanvas.Font := AFont;
    finally
      AFont.Free;
    end;
  end;
end;

{$ENDREGION}

{ TACLTextLayoutRefreshHelper }

function TACLTextLayoutRefreshHelper.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  ABlock.Flush;
  Result := True;
end;

{$REGION ' Blocks '}

{ TACLTextLayoutBlock }

function TACLTextLayoutBlock.Bounds: TRect;
begin
  Result := TRect.Create(FPosition);
end;

function TACLTextLayoutBlock.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := True;
end;

procedure TACLTextLayoutBlock.Shrink(ARender: TACLTextLayoutRender; AMaxRight: Integer);
begin
  FPosition.X := Min(FPosition.X, AMaxRight);
end;

{ TACLTextLayoutBlockList }

procedure TACLTextLayoutBlockList.AddInit(
  ABlock: TACLTextLayoutBlock; var AScan: PChar; ABlockLength: Integer);
begin
  Add(ABlock);
  ABlock.FPositionInText := AScan;
  ABlock.FLength := ABlockLength;
  Inc(AScan, ABlockLength);
end;

procedure TACLTextLayoutBlockList.AddSpan(ABlock: TACLTextLayoutBlockList);
var
  I: Integer;
begin
{$IFDEF ACL_TEXTLAYOUT_SPANS}
  if (ABlock.Count > 1) and (ABlock.CountOfClass(TACLTextLayoutBlockText) > 1) then
    Add(TACLTextLayoutBlockSpan.Create(ABlock))
  else
{$ENDIF}
    for I := 0 to ABlock.Count - 1 do
      Add(ABlock.List[I]);

  ABlock.Count := 0;
end;

function TACLTextLayoutBlockList.BoundingRect: TRect;
var
  I: Integer;
begin
  if Count = 0 then
    Exit(NullRect);

  Result := List[0].Bounds;
  for I := 1 to Count - 1 do
    Result.Add(List[I].Bounds);
end;

function TACLTextLayoutBlockList.CountOfClass(AClass: TACLTextLayoutBlockClass): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Count - 1 do
  begin
    if List[I].ClassType = AClass then
      Inc(Result);
  end;
end;

function TACLTextLayoutBlockList.Export(
  AExporter: TACLTextLayoutExporter; AFreeExporter: Boolean): Boolean;
var
  I: Integer;
begin
  Result := True;
  try
    for I := 0 to Count - 1 do
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
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    List[I].FPosition.Offset(ADeltaX, ADeltaY);
end;

{ TACLTextLayoutBlockLineBreak }

function TACLTextLayoutBlockLineBreak.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnLineBreak(Self);
end;

{ TACLTextLayoutBlockSpace }

function TACLTextLayoutBlockSpace.Bounds: TRect;
begin
  Result := TRect.Create(FPosition, FWidth, FHeight);
end;

function TACLTextLayoutBlockSpace.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnSpace(Self);
end;

procedure TACLTextLayoutBlockSpace.Shrink(ARender: TACLTextLayoutRender; AMaxRight: Integer);
begin
  FWidth := MaxMin(AMaxRight - FPosition.X, 0, FWidth);
  inherited;
end;

{ TACLTextLayoutBlockText }

constructor TACLTextLayoutBlockText.Create(AText: PChar; ATextLength: Word);
begin
  inherited Create;
  FPositionInText := AText;
  FLength := ATextLength;
end;

destructor TACLTextLayoutBlockText.Destroy;
begin
  FreeMem(FMetrics);
  inherited;
end;

function TACLTextLayoutBlockText.Bounds: TRect;
begin
  Result := TRect.Create(FPosition, FWidth, FHeight);
end;

function TACLTextLayoutBlockText.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnText(Self);
end;

procedure TACLTextLayoutBlockText.Flush;
begin
  FLengthVisible := 0;
  FHeight := 0;
  FWidth := 0;
end;

procedure TACLTextLayoutBlockText.Shrink(ARender: TACLTextLayoutRender; AMaxRight: Integer);
var
  LMaxWidth: Integer;
begin
  LMaxWidth := AMaxRight - FPosition.X;
  if LMaxWidth <= 0 then
  begin
    FLengthVisible := 0;
    FWidth := 0;
  end
  else
    if FWidth > LMaxWidth then
      ARender.Shrink(Self, LMaxWidth);

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

{ TACLTextLayoutBlockFillColor }

constructor TACLTextLayoutBlockFillColor.Create(const AColor: string; AInclude: Boolean);
begin
  inherited Create(AInclude);
  FColor := StringToColor(AColor);
end;

function TACLTextLayoutBlockFillColor.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnFillColor(Self);
end;

{ TACLTextLayoutBlockFontColor }

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

{ TACLTextLayoutBlockSpan }

constructor TACLTextLayoutBlockSpan.Create(ABlocks: TACLTextLayoutBlockList);
begin
  SetLength(FBlocks, ABlocks.Count);
  FastMove(ABlocks.List[0], FBlocks[0], ABlocks.Count * SizeOf(Pointer));
  FPositionInText := FBlocks[0].FPositionInText;
  FLength :=
    FBlocks[High(FBlocks)].FLength +
    FBlocks[High(FBlocks)].FPositionInText - FPositionInText;
end;

destructor TACLTextLayoutBlockSpan.Destroy;
var
  I: Integer;
begin
  for I := Low(FBlocks) to High(FBlocks) do
    FreeAndNil(FBlocks[I]);
  inherited;
end;

function TACLTextLayoutBlockSpan.Bounds: TRect;
var
  I: Integer;
begin
  Result := FBlocks[0].Bounds;
  for I := Low(FBlocks) + 1 to High(FBlocks) do
    Result.Add(FBlocks[I].Bounds);
end;

function TACLTextLayoutBlockSpan.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := AExporter.OnSpan(Self);
end;

{$ENDREGION}

{$REGION ' Rows '}

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
var
  I: Integer;
begin
  if AValue <> FBaseline then
  begin
    for I := 0 to Count - 1 do
      Inc(List[I].FPosition.Y, AValue - FBaseline);
    FBaseline := AValue;
  end;
end;

procedure TACLTextLayoutRow.SetEndEllipsis(ARender: TACLTextLayoutRender;
  ARightSide: Integer; AEndEllipsis: TACLTextLayoutBlockText);
var
  ABlock: TACLTextLayoutBlock;
  I: Integer;
begin
{$IFDEF DEBUG}
  if AEndEllipsis = nil then
    raise EInvalidOperation.Create('Row: the EndEllipsis block must be specified');
  if EndEllipsis <> nil then
    raise EInvalidOperation.Create('Row: the EndEllipsis block is already specified');
{$ENDIF}

  FEndEllipsis := AEndEllipsis;
  Dec(ARightSide, EndEllipsis.TextWidth);
  FEndEllipsis.FPosition.X := Bounds.Right;

  // Ищем последний видимый блок, после которого можно воткнуть '...'
  for I := Count - 1 downto 0 do
  begin
    ABlock := List[I];
    ABlock.Shrink(ARender, ARightSide);
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
var
  I: Integer;
begin
  if Count = 0 then
    Exit(NullRect);
  Result := List[0].Bounds;
  for I := 1 to Count - 1 do
    Result.Add(List[I].Bounds);
end;

function TACLTextLayoutRows.Export(AExporter: TACLTextLayoutExporter; AFreeExporter: Boolean): Boolean;
var
  I: Integer;
begin
  Result := True;
  try
    for I := 0 to Count - 1 do
    begin
      if not List[I].Export(AExporter, False) then
        Exit(False);
    end;
  finally
    if AFreeExporter then
      AExporter.Free;
  end;
end;

{$ENDREGION}

{$REGION ' Exporters '}

{ TACLTextLayoutValueStack<T> }

constructor TACLTextLayoutValueStack<T>.Create;
begin
  FCount := 0;
  SetLength(FData, 16);
end;

procedure TACLTextLayoutValueStack<T>.Assign(ASource: TACLTextLayoutValueStack<T>);
var
  I: Integer;
begin
  FCount := ASource.FCount;
  SetLength(FData, FCount);
  for I := 0 to FCount - 1 do
    FData[I] := ASource.FData[I];
end;

function TACLTextLayoutValueStack<T>.Peek: T;
begin
  if Count = 0 then
    raise Exception.Create('Stack is empty');
  Result := FData[FCount - 1].Key;
end;

procedure TACLTextLayoutValueStack<T>.Pop(AInvoker: TClass);
var
  I, J: Integer;
begin
  for I := FCount - 1 downto 0 do
    if FData[I].Value = AInvoker then
    begin
      for J := I to FCount - 2 do
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

function TACLTextLayoutExporter.OnLineBreak(ABlock: TACLTextLayoutBlock): Boolean;
begin
  Result := True;
end;

function TACLTextLayoutExporter.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  Result := True;
end;

function TACLTextLayoutExporter.OnSpan(ABlock: TACLTextLayoutBlockSpan): Boolean;
var
  I: Integer;
begin
  for I := Low(ABlock.Blocks) to High(ABlock.Blocks) do
  begin
    if not ABlock.Blocks[I].Export(Self) then
      Exit(False);
  end;
  Result := True;
end;

function TACLTextLayoutExporter.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  Result := True;
end;

{ TACLTextLayoutVisualExporter }

constructor TACLTextLayoutVisualExporter.Create(
  AOwner: TACLTextLayout; ARender: TACLTextLayoutRender);
begin
  inherited Create(AOwner);
  FRender := ARender;
  FFont := Owner.Font.Clone;
  FFont.OnChange := FontChanged;
  FFontSizes := TACLTextLayoutValueStack<Integer>.Create;
  FFontSizes.Push(FFont.Height, nil);
end;

destructor TACLTextLayoutVisualExporter.Destroy;
begin
  FreeAndNil(FFontSizes);
  FreeAndNil(FFont);
  inherited;
end;

procedure TACLTextLayoutVisualExporter.AfterConstruction;
begin
  inherited;
  FontChanged(nil); // apply metrics
end;

procedure TACLTextLayoutVisualExporter.CopyState(ASource: TACLTextLayoutVisualExporter);
begin
  FFont.Assign(ASource.Font);
  FFontSizes.Assign(ASource.FFontSizes);
  FFontStyles := ASource.FFontStyles;
end;

procedure TACLTextLayoutVisualExporter.FontChanged(Sender: TObject);
begin
  Render.SetFont(Font);
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
      AHeight := acGetFontHeight(ABlock.Value, Owner.TargetDpi);

    FFontSizes.Push(AHeight, ABlock.ClassType);
  end
  else
    FFontSizes.Pop(ABlock.ClassType);

  Font.Height := FFontSizes.Peek;
  Result := True;
end;

function TACLTextLayoutVisualExporter.OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean;
var
  LStyles: TFontStyles;
begin
  FFontStyles[ABlock.Style] := Max(FFontStyles[ABlock.Style] + Signs[ABlock.Include], 0);

  LStyles := Font.Style;
  if FFontStyles[ABlock.Style] > 0 then
    Include(LStyles, ABlock.Style)
  else
    Exclude(LStyles, ABlock.Style);
  Font.Style := LStyles;

  Result := True;
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

{ TACLPlainTextExporter }

constructor TACLPlainTextExporter.Create(ASource: TACLTextLayout; ATarget: TACLStringBuilder);
begin
  inherited Create(ASource);
  FTarget := ATarget;
end;

function TACLPlainTextExporter.OnLineBreak(ABlock: TACLTextLayoutBlock): Boolean;
begin
  FTarget.AppendLine;
  Result := True;
end;

function TACLPlainTextExporter.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  FTarget.Append(' ');
  Result := True;
end;

function TACLPlainTextExporter.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  FTarget.Append(ABlock.ToString);
  Result := True;
end;

{ TACLTextLayoutPainter }

constructor TACLTextLayoutPainter.Create(AOwner: TACLTextLayout; ARender: TACLTextLayoutRender);
begin
  inherited;
  FDefaultTextColor := Owner.GetDefaultTextColor;
  FFillColors := TACLTextLayoutValueStack<TColor>.Create;
  FTextColors := TACLTextLayoutValueStack<TColor>.Create;
  Font.Color := FDefaultTextColor;
  Render.SetFill(clNone);
end;

destructor TACLTextLayoutPainter.Destroy;
begin
  FreeAndNil(FFillColors);
  FreeAndNil(FTextColors);
  inherited;
end;

function TACLTextLayoutPainter.OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean;
begin
  if ABlock.Include then
    FFillColors.Push(ABlock.Color, TACLTextLayoutBlockFillColor)
  else
    FFillColors.Pop(TACLTextLayoutBlockFillColor);

  if FFillColors.Count > 0 then
    Render.SetFill(FFillColors.Peek)
  else
    Render.SetFill(clNone);

  Result := True;
end;

function TACLTextLayoutPainter.OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean;
begin
  if ABlock.Include then
    FTextColors.Push(ABlock.Color, TACLTextLayoutBlockFontColor)
  else
    FTextColors.Pop(TACLTextLayoutBlockFontColor);

  UpdateTextColor;
  Result := True;
end;

function TACLTextLayoutPainter.OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean;
begin
  OnFontStyle(ABlock);

  if ABlock.Include then
    FTextColors.Push(Owner.GetDefaultHyperLinkColor, TACLTextLayoutBlockHyperlink)
  else
    FTextColors.Pop(TACLTextLayoutBlockHyperlink);

  UpdateTextColor;
  Result := True;
end;

function TACLTextLayoutPainter.OnText(AText: TACLTextLayoutBlockText): Boolean;
begin
  if AText.TextLengthVisible > 0 then
    Render.TextOut(AText, AText.FPosition.X, AText.FPosition.Y);
  Result := True;
end;

procedure TACLTextLayoutPainter.UpdateTextColor;
var
  LColor: TColor;
begin
  LColor := clDefault;
  if FTextColors.Count > 0 then
    LColor := FTextColors.Peek;
  if LColor = clDefault then
    LColor := FDefaultTextColor;
  Font.Color := LColor;
end;

{$ENDREGION}

{$REGION ' Calculator '}

{ TACLTextLayoutCalculator }

constructor TACLTextLayoutCalculator.Create(AOwner: TACLTextLayout; ARender: TACLTextLayoutRender);
begin
  inherited;
  FRows := Owner.FLayout;
  FRow := TACLTextLayoutRow.Create;
{$IFDEF ACL_TEXTLAYOUT_RTL}
  FRowRtlRanges := TACLList<TACLRange>.Create;
  FRowRtlRanges.Capacity := RtlRangeCapacity;
{$ENDIF}
  FEditControl := atoEditControl and Owner.Options <> 0;
  FEndEllipsis := atoEndEllipsis and Owner.Options <> 0;
  FRowHasAlignment := (Owner.HorzAlignment <> taLeftJustify) and (atoAutoWidth and Owner.Options = 0);
  FSingleLine := atoSingleLine and Owner.Options <> 0;
  FWordWrap := (atoWordWrap and Owner.Options <> 0) and not FSingleLine;

  FBounds := AOwner.Bounds;
  FBounds.Content(Owner.GetPadding);
  FMaxHeight := IfThen(atoAutoHeight and Owner.Options <> 0, MaxInt, FBounds.Height);
  FMaxWidth := IfThen(atoAutoWidth and Owner.Options <> 0, MaxInt, FBounds.Width);
end;

constructor TACLTextLayoutCalculator.CreateSpan(ACalculator: TACLTextLayoutCalculator);
begin
  inherited Create(ACalculator.Owner, ACalculator.Render);
  FRow := TACLTextLayoutRow.Create;
{$IFDEF ACL_TEXTLAYOUT_RTL}
  FRowRtlRanges := TACLList<TACLRange>.Create;
  FRowRtlRanges.Capacity := RtlRangeCapacity;
{$ENDIF}
  FRowHasAlignment := True;
  FMaxHeight := MaxInt;
  FMaxWidth := MaxInt;
  CopyState(ACalculator);
end;

destructor TACLTextLayoutCalculator.Destroy;
begin
  CompleteRow;
  if FRows <> nil then
    AlignRows;
  FreeAndNil(FPrevRowEndEllipsis);
{$IFDEF ACL_TEXTLAYOUT_RTL}
  FreeAndNil(FRowRtlRanges);
{$ENDIF}
  inherited;
end;

function TACLTextLayoutCalculator.AddBlock(ABlock: TACLTextLayoutBlock; AWidth: Integer = 0): Boolean;
begin
  Result := FRow <> nil;
  if Result and (ABlock <> nil) then
  begin
    if Baseline > FRow.Baseline then
      FRow.Baseline := Baseline;
    ABlock.FPosition := Point(FOrigin.X, FOrigin.Y + FRow.Baseline - Baseline);
    FRow.Add(ABlock);
  end;
  Inc(FOrigin.X, AWidth);
end;

function TACLTextLayoutCalculator.AddBlockOfContent(ABlock: TACLTextLayoutBlock; AWidth: Integer): Boolean;
{$IFDEF ACL_TEXTLAYOUT_RTL}
var
  LReadingDirection: TACLTextReadingDirection;
{$ENDIF}
begin
  if FWordWrap then
  begin
    if (FOrigin.X > 0) and (FRowTruncated or (FOrigin.X + AWidth > FMaxWidth)) then
    begin
      if not OnLineBreak then
        Exit(False);
    end;
  end
  else
    if FOrigin.X >= FMaxWidth then
    begin
      TruncateRow;
      // В случае EndEllipsis = True, DrawText выравнивает обрезанный текст
      if FRowTruncated then
      begin
        // Если у нас только 1 строка и она кончилась - прерываем экспорт
        // В противом случае - продолжаем, вдруг встретися LineBreak-токен
        Exit(not FSingleLine);
      end;
      // если есть выравнивание - прерываться нельзя - нужно посчитать все
      // блоки до конца строки, иначе выравнивание отработает некорректо
      if FRowHasAlignment then
        Exit(True);
    end;

  if FRowTruncated then
    Exit(True);

{$IFDEF ACL_TEXTLAYOUT_RTL}
  LReadingDirection := acGetReadingDirection(ABlock.FPositionInText, ABlock.FLength);
  if LReadingDirection = trdLeftToRight then
    FRowRtlRange := False
  else
    if FRowRtlRange then
      FRowRtlRanges.List[FRowRtlRanges.Count - 1].Finish := FRow.Count
    else
      if LReadingDirection = trdRightToLeft then
      begin
        FRowRtlRanges.Add(TACLRange.Create(FRow.Count, FRow.Count));
        FRowRtlRange := True;
      end;
{$ENDIF}

  Result := AddBlock(ABlock, AWidth);
  if FOrigin.X > FMaxWidth then
    TruncateRow;
end;

procedure TACLTextLayoutCalculator.AlignRows;
var
  LOffsetX: Integer;
  LOffsetY: Integer;
  LRow: TACLTextLayoutRow;
  I: Integer;
begin
  LOffsetY := FBounds.Top;
  case Owner.VertAlignment of
    taAlignBottom:
      Inc(LOffsetY, Max(0, (FBounds.Height - FRows.BoundingRect.Bottom)));
    taVerticalCenter:
      Inc(LOffsetY, Max(0, (FBounds.Height - FRows.BoundingRect.Bottom) div 2));
  else;
  end;

  for I := 0 to FRows.Count - 1 do
  begin
    LRow := FRows.List[I];
    LOffsetX := FBounds.Left;
    case Owner.HorzAlignment of
      taRightJustify:
        Inc(LOffsetX, Max(0, (FBounds.Width - LRow.Bounds.Right)));
      taCenter:
        Inc(LOffsetX, Max(0, (FBounds.Width - LRow.Bounds.Right) div 2));
    else
      Dec(LOffsetX, LRow.Bounds.Left);
    end;
    LRow.Offset(LOffsetX, LOffsetY);
  end;
end;

procedure TACLTextLayoutCalculator.CompleteRow;
var
  I: Integer;
begin
  if FRow = nil then
    Exit;
  if FRow.Count > 0 then
    FRow.Bounds := FRow.BoundingRect
  else
    FRow.Bounds.Height := LineHeight;

  if FRows = nil then
  begin
    FreeAndNil(FRow);
    Exit; // possible in span-calculator mode
  end;

  if (FRow.Bounds.Bottom > FMaxHeight) and FEditControl or (FRow.Bounds.Top > FMaxHeight) then
  begin
    TruncateAll;
    Exit;
  end;

  FOrigin.X := 0;
  FOrigin.Y := FRow.Bounds.Bottom;
  FRows.Add(FRow);

{$IFDEF ACL_TEXTLAYOUT_RTL}
  for I := 0 to FRowRtlRanges.Count - 1 do
    Reorder(FRow, FRowRtlRanges.List[I]);
  FRowRtlRanges.Count := 0;
  FRowRtlRange := False;
{$ENDIF}

  if FEndEllipsis then
  begin
    // может так случиться, что следующая строка уже не влезет и нам понадобятся заветные три точки.
    // поэтому считаем их сейчас (в кэш), пока у нас есть актуальный стиль и метрики.
    if FPrevRowEndEllipsis = nil then
      FPrevRowEndEllipsis := TACLTextLayoutBlockText.Create(PChar(acEndEllipsis), Length(acEndEllipsis));
    Render.Measure(FPrevRowEndEllipsis);
  end;
end;

procedure TACLTextLayoutCalculator.FontChanged(Sender: TObject);
begin
  inherited;
  Render.GetMetrics(FBaseline, FLineHeight, FSpaceWidth);
end;

function TACLTextLayoutCalculator.OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean;
begin
  Result := AddBlock(ABlock);
end;

function TACLTextLayoutCalculator.OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean;
begin
  Result := AddBlock(ABlock);
end;

function TACLTextLayoutCalculator.OnFontSize(ABlock: TACLTextLayoutBlockFontSize): Boolean;
begin
  inherited;
  Result := AddBlock(ABlock);
end;

function TACLTextLayoutCalculator.OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean;
begin
  inherited;
  Result := AddBlock(ABlock);
end;

function TACLTextLayoutCalculator.OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean;
begin
  Result := AddBlock(ABlock);
end;

function TACLTextLayoutCalculator.OnLineBreak(ABlock: TACLTextLayoutBlock = nil): Boolean;
begin
  Result := False;
  if FRow <> nil then
  begin
    if ABlock <> nil then
      ABlock.FPosition := FOrigin;
    if FSingleLine then
    begin
      Inc(FOrigin.X, SpaceWidth);
      Exit(True);
    end;
    CompleteRow;
    if FOrigin.Y < FMaxHeight then
    begin
      FRow := TACLTextLayoutRow.Create;
      FRow.Bounds := Bounds(FOrigin.X, FOrigin.Y, 0, 0);
      FRowTruncated := False;
      Result := True;
    end
    else
    begin
      FRow := nil;
      TruncateAll;
    end;
  end;
end;

function TACLTextLayoutCalculator.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  if FRow = nil then
    Exit(False);
  if FRowTruncated then
    Exit(True);

  ABlock.FHeight := LineHeight;
  if not FWordWrap or (FOrigin.X + SpaceWidth <= FMaxWidth) then
    ABlock.FWidth := SpaceWidth
  else
    ABlock.FWidth := 0;

  Result := AddBlock(ABlock, ABlock.FWidth);
end;

function TACLTextLayoutCalculator.OnSpan(ABlock: TACLTextLayoutBlockSpan): Boolean;
var
  I: Integer;
  LSpanCalculator: TACLTextLayoutCalculator;
begin
  if FRow = nil then
    Exit(False);
  if not FWordWrap then
    Exit(inherited);

  // Считаем все блоки, входящие в составной блок.
  // Делаем это в отдельном калькуляторе, дабы не потерять текущие параметры шрифта
  LSpanCalculator := TACLTextLayoutCalculator.CreateSpan(Self);
  try
    for I := Low(ABlock.Blocks) to High(ABlock.Blocks) do
      ABlock.Blocks[I].Export(LSpanCalculator);
  finally
    LSpanCalculator.Free;
  end;

  // Переприменяем параметры шрифта к Render-у
  FontChanged(nil);

  // Нужно переносить блок на следующую строку?
  if (FOrigin.X > 0) and (FRowTruncated or (FOrigin.X + ABlock.Bounds.Width > FMaxWidth)) then
  begin
    if not OnLineBreak then
      Exit(False);
  end;

  // Позиционируем части составного блока
  FWordWrap := False;
  Result := inherited;
  FWordWrap := True;
end;

function TACLTextLayoutCalculator.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  if FRow = nil then
    Exit(False);

  if (ABlock.TextWidth = 0) or
     (ABlock.TextLengthVisible < ABlock.TextLength) // Блок был сжат - его метрики более невалидны
  then
    Render.Measure(ABlock);

  Result := AddBlockOfContent(ABlock, ABlock.TextWidth);
end;

procedure TACLTextLayoutCalculator.Reorder(ABlocks: TACLTextLayoutBlockList; const ARange: TACLRange);
var
  R, L: TRect;
  I: Integer;
begin
  if ARange.Finish > ARange.Start then
  begin
    R := ABlocks.List[ARange.Start].Bounds;
    for I := ARange.Start + 1 to ARange.Finish do
      R.Add(ABlocks.List[I].Bounds);
    for I := ARange.Start to ARange.Finish do
    begin
      L := ABlocks.List[I].Bounds;
      L.Mirror(R);
      ABlocks.List[I].FPosition := L.TopLeft;
    end;
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
      ARow.SetEndEllipsis(Render, FMaxWidth, FPrevRowEndEllipsis);
      FPrevRowEndEllipsis := nil;
    end;
  end;
end;

procedure TACLTextLayoutCalculator.TruncateRow;
var
  LEndEllipsis: TACLTextLayoutBlockText;
begin
  Owner.FTruncated := True;
  if FEndEllipsis then
  begin
    if FRow.EndEllipsis = nil then
    begin
      LEndEllipsis := TACLTextLayoutBlockText.Create(PChar(acEndEllipsis), Length(acEndEllipsis));
      Render.Measure(LEndEllipsis);
      FRow.SetEndEllipsis(Render, FMaxWidth, LEndEllipsis);
    end;
    FOrigin.X := FRow.EndEllipsis.FPosition.X;
    FRowTruncated := True;
  end;
end;

{$ENDREGION}

{$REGION ' Importer '}

{ TACLTextImporter }

class constructor TACLTextImporter.Create;
begin
  FEmailValidator := TRegEx.Create(EmailPattern);
end;

class function TACLTextImporter.AllocContext(
  const ASettings: TACLTextFormatSettings;
  AOutput: TACLTextLayoutBlockList): TContext;
var
  AIndex: Integer;
begin
  Result := TContext.Create;
  Result.Output := AOutput;
  Result.Span := TACLTextLayoutBlockList.Create(False);

{$REGION ' TokenDetectors '}
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

{$REGION ' TokenInTextDetectors '}
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

class function TACLTextImporter.IsDelimiter(Ctx: TContext; var Scan: PChar): Boolean;
begin
  Result := acContains(Scan^, Delimiters);
  if Result then
  begin
    Ctx.Output.AddSpan(Ctx.Span);
    Ctx.Output.AddInit(TACLTextLayoutBlockText.Create(Scan, 1), Scan, 1);
  end;
end;

class function TACLTextImporter.IsEmail(Ctx: TContext; S: PChar; L: Integer): Boolean;
var
  ALink: string;
begin
  if acStrScan(S, L, '@') <> nil then // быстрая проверка
  begin
    ALink := acMakeString(S, L);
    if FEmailValidator.IsMatch(ALink) then
    begin
      Ctx.Output.AddSpan(Ctx.Span);
      Ctx.Output.Add(TACLTextLayoutBlockHyperlink.Create(acMailToPrefix + ALink, True));
      Ctx.Output.Add(TACLTextLayoutBlockText.Create(S, L));
      Ctx.Output.Add(TACLTextLayoutBlockHyperlink.Create(acEmptyStr, False));
      Exit(True);
    end;
  end;
  Result := False;
end;

class function TACLTextImporter.IsLineBreak(Ctx: TContext; var Scan: PChar): Boolean;
begin
  if Scan^ = #10 then //#10
  begin
    Ctx.Output.AddSpan(Ctx.Span);
    Ctx.Output.AddInit(TACLTextLayoutBlockLineBreak.Create, Scan, 1);
    Exit(True);
  end;
  if Scan^ = #13 then // #13 or #13#10
  begin
    Ctx.Output.AddSpan(Ctx.Span);
    Ctx.Output.AddInit(TACLTextLayoutBlockLineBreak.Create, Scan, 1 + Ord((Scan + 1)^ = #10));
    Exit(True);
  end;
  Result := False;
end;

class function TACLTextImporter.IsLineBreakCpp(Ctx: TContext; var Scan: PChar): Boolean;
begin
  Result := (Scan^ = '\') and ((Scan + 1)^ = 'n');
  if Result then
  begin
    Ctx.Output.AddSpan(Ctx.Span);
    Ctx.Output.AddInit(TACLTextLayoutBlockLineBreak.Create, Scan, 2);
  end;
end;

class function TACLTextImporter.IsSpace(Ctx: TContext; var Scan: PChar): Boolean;
begin
  Result := acContains(Scan^, Spaces);
  if Result then
  begin
    Ctx.Output.AddSpan(Ctx.Span);
    Ctx.Output.AddInit(TACLTextLayoutBlockSpace.Create, Scan, 1);
  end;
end;

class function TACLTextImporter.IsStyle(Ctx: TContext; var Scan: PChar): Boolean;
var
  ABlock: TACLTextLayoutBlockStyle;
  AIsClosing: Boolean;
  AScanEnd: PChar;
  AScanParam: PChar;
  AScanTag: PChar;
  ATagLength: Integer;
begin
  Result := False;
  if Scan^ = '[' then
  begin
    AScanEnd := acStrScan(Scan, ']');
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
      AScanParam := acStrScan(AScanTag, acStringLength(Scan, AScanEnd), '=');
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
      ABlock := TACLTextLayoutBlockFontColor.Create(acMakeString(AScanParam + 1, AScanEnd), not AIsClosing)
    else if acCompareTokens('BACKCOLOR', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFillColor.Create(acMakeString(AScanParam + 1, AScanEnd), not AIsClosing)
    else if acCompareTokens('BIG', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFontSize.Create(FontScalingBig, not AIsClosing)
    else if acCompareTokens('SMALL', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFontSize.Create(FontScalingSmall, not AIsClosing)
    else if acCompareTokens('SIZE', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockFontSize.Create(acMakeString(AScanParam + 1, AScanEnd), not AIsClosing)
    else if acCompareTokens('URL', AScanTag, ATagLength) then
      ABlock := TACLTextLayoutBlockHyperlink.Create(acMakeString(AScanParam + 1, AScanEnd), not AIsClosing)
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
      Ctx.Span.AddInit(ABlock, Scan, acStringLength(Scan, AScanEnd));
    end;
  end;
end;

class function TACLTextImporter.IsText(Ctx: TContext; var Scan: PChar): Boolean;
var
  ACursor: PChar;
  ALength: Integer;
  I: Integer;
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
          for I := Low(Ctx.TokenInTextDetectors) to High(Ctx.TokenInTextDetectors) do
          begin
            if Ctx.TokenInTextDetectors[I](Ctx, Scan, ALength) then
            begin
              Inc(Scan, ALength);
              Exit;
            end;
          end;
        Ctx.Span.AddInit(TACLTextLayoutBlockText.Create(Scan, ALength), Scan, ALength);
      end;
      Break;
    end;
  until False;
end;

class function TACLTextImporter.IsTimeCode(Ctx: TContext; S: PChar; L: Integer): Boolean;
var
  ATime: Single;
begin
  Result := False;
  if CharInSet(S^, ['0'..'9']) and (Ctx.Span.Count = 0) then
  begin
    if Ctx.Output.Count > 0 then
    begin
      if ((S - 1)^ > ' ') and not CharInSet((S - 1)^, TACLTimeFormat.BracketsIn) then
        Exit;
    end;
    Result := TACLTimeFormat.Parse(acMakeString(S, L), ATime);
    if Result then
    begin
      Ctx.Output.Add(TACLTextLayoutBlockHyperlink.Create(TACLTextLayout.TimeCodePrefix + IntToStr(Trunc(ATime)), True));
      Ctx.Output.Add(TACLTextLayoutBlockText.Create(S, L));
      Ctx.Output.Add(TACLTextLayoutBlockHyperlink.Create(acEmptyStr, False));
    end;
  end;
end;

class function TACLTextImporter.IsURL(Ctx: TContext; S: PChar; L: Integer): Boolean;
const
  Prefix: PChar = 'www.';
begin
  if Ctx.Span.Count > 0 then
    Exit(False);

  if acIsUrlFileName(S, L) then
  begin
    Ctx.Output.Add(TACLTextLayoutBlockHyperlink.Create(acMakeString(S, L), True));
    Ctx.Output.Add(TACLTextLayoutBlockText.Create(S, L));
    Ctx.Output.Add(TACLTextLayoutBlockHyperlink.Create(acEmptyStr, False));
    Exit(True);
  end;

  if (L > 4) and CompareMem(S, Prefix, 4) then
  begin
    if acStrScan(S + 4, L - 4, '.') <> nil then
    begin
      Ctx.Output.Add(TACLTextLayoutBlockHyperlink.Create('https://' + acMakeString(S, L), True));
      Ctx.Output.Add(TACLTextLayoutBlockText.Create(S, L));
      Ctx.Output.Add(TACLTextLayoutBlockHyperlink.Create(acEmptyStr, False));
      Exit(True);
    end;
  end;

  Result := False;
end;

{$ENDREGION}

{$REGION ' Native Canvases '}

{ TACLTextLayoutCanvasRender }

constructor TACLTextLayoutCanvasRender.Create(ACanvas: TCanvas);
begin
  FCanvas := ACanvas;
  inherited Create;
end;

procedure TACLTextLayoutCanvasRender.Measure(ABlock: TACLTextLayoutBlockText);
var
  LDistance: Integer;
  LTextSize: TSize;
  LWidth: PInteger;
  I: Integer;
begin
  if ABlock.FMetrics = nil then
    ABlock.FMetrics := AllocMem((ABlock.TextLength + 1) * SizeOf(Integer));
  GetTextExtentExPoint(FCanvas.Handle,
    ABlock.Text, ABlock.TextLength, MaxInt,
    @PIntegerArray(ABlock.FMetrics)^[0],
    @PIntegerArray(ABlock.FMetrics)^[1], LTextSize{%H-});
  ABlock.FLengthVisible := ABlock.TextLength;
  ABlock.FHeight := LTextSize.cy;
  ABlock.FWidth := LTextSize.cx;

  LDistance := 0;
  LWidth := @PIntegerArray(ABlock.FMetrics)^[1];
  for I := 0 to PIntegerArray(ABlock.FMetrics)^[0] - 1 do
  begin
    Dec(LWidth^, LDistance);
    Inc(LDistance, LWidth^);
    Inc(LWidth);
  end;
end;

procedure TACLTextLayoutCanvasRender.GetMetrics(out ABaseline, ALineHeight, ASpaceWidth: Integer);
var
  LMetric: TTextMetric;
begin
  GetTextMetrics(FCanvas.Handle, LMetric{%H-});
  ABaseline := LMetric.tmHeight - LMetric.tmDescent;
  ALineHeight := LMetric.tmHeight + LMetric.tmExternalLeading;
  ASpaceWidth := FCanvas.TextWidth(' ');
end;

procedure TACLTextLayoutCanvasRender.SetFill(AValue: TColor);
begin
  if (AValue <> clNone) and (AValue <> clDefault) then
    FCanvas.Brush.Color := AValue
  else
    FCanvas.Brush.Style := bsClear;
end;

procedure TACLTextLayoutCanvasRender.SetFont(AFont: TFont);
begin
  FCanvas.Font := AFont;
end;

procedure TACLTextLayoutCanvasRender.Shrink(ABlock: TACLTextLayoutBlockText; AMaxSize: Integer);
var
  LCharCount: PInteger;
  LCharWidth: PInteger;
  LMetrics: PIntegerArray;
begin
  LMetrics := PIntegerArray(ABlock.FMetrics);
  LCharCount := @LMetrics^[0];
  LCharWidth := @LMetrics^[1 + LCharCount^ - 1];
  while LCharCount^ > 0 do
  begin
    Dec(ABlock.FWidth, LCharWidth^);
    Dec(LCharCount^);
    if ABlock.FWidth <= AMaxSize then Break;
    Dec(LCharWidth);
  end;
{$IFDEF FPC}
  ABlock.FLengthVisible := UTF8CodepointToByteIndex(ABlock.Text, ABlock.TextLength, LCharCount^);
{$ELSE}
  ABlock.FLengthVisible := LCharCount^;
{$ENDIF}
end;

procedure TACLTextLayoutCanvasRender.TextOut(ABlock: TACLTextLayoutBlockText; X, Y: Integer);
begin
  ExtTextOut(FCanvas.Handle, X, Y, 0, nil,
    ABlock.Text, ABlock.TextLengthVisible, @PIntegerArray(ABlock.FMetrics)^[1]);
end;

{$ENDREGION}

{ TACLTextFormatSettings }

class function TACLTextFormatSettings.Default: TACLTextFormatSettings;
begin
  FillChar(Result{%H-}, SizeOf(Result), 0);
  Result.AllowAutoURLDetect := True;
  Result.AllowCppLikeLineBreaks := True;
  Result.AllowFormatting := True;
end;

class function TACLTextFormatSettings.Formatted: TACLTextFormatSettings;
begin
  FillChar(Result{%H-}, SizeOf(Result), 0);
  Result.AllowFormatting := True;
end;

class function TACLTextFormatSettings.PlainText: TACLTextFormatSettings;
begin
  FillChar(Result{%H-}, SizeOf(Result), 0);
end;

{ TACLTextLayout }

constructor TACLTextLayout.Create(AFont: TFont);
begin
  FFont := AFont;
  FTargetDpi := FFont.PixelsPerInch;
  FBlocks := TACLTextLayoutBlockList.Create;
  FLayout := TACLTextLayoutRows.Create;
end;

destructor TACLTextLayout.Destroy;
begin
  FreeAndNil(FBlocks);
  FreeAndNil(FLayout);
  inherited;
end;

procedure TACLTextLayout.Calculate(ACanvas: TCanvas);
var
  LRender: TACLTextLayoutRender;
begin
  if FLayoutIsDirty then
  begin
    LRender := DefaultTextLayoutCanvasRender.Create(ACanvas);
    try
      Calculate(LRender);
    finally
      LRender.Free;
    end;
  end;
end;

procedure TACLTextLayout.Calculate(ARender: TACLTextLayoutRender);
begin
  if FLayoutIsDirty then
  begin
    FTruncated := False;
    FLayout.Count := 0;
    FLayoutIsDirty := False;
    if FBlocks.Count > 0 then
      FBlocks.Export(TACLTextLayoutCalculator.Create(Self, ARender), True);
  end;
end;

procedure TACLTextLayout.FlushCalculatedValues;
begin
  FBlocks.Export(TACLTextLayoutRefreshHelper.Create(Self), True);
  FLayoutIsDirty := True;
end;

procedure TACLTextLayout.Draw(ACanvas: TCanvas);
var
  LRender: TACLTextLayoutRender;
begin
  if Options and atoNoClip <> 0 then
  begin
    LRender := DefaultTextLayoutCanvasRender.Create(ACanvas);
    try
      Draw(LRender);
    finally
      LRender.Free;
    end
  end
  else
    Draw(ACanvas, Bounds);
end;

procedure TACLTextLayout.Draw(ACanvas: TCanvas; const AClipRect: TRect);
var
  LClipRegion: HRGN;
  LRender: TACLTextLayoutRender;
begin
  if acRectVisible(ACanvas.Handle, AClipRect) then
  begin
    LClipRegion := acSaveClipRegion(ACanvas.Handle);
    try
      acIntersectClipRegion(ACanvas.Handle, AClipRect);
      LRender := DefaultTextLayoutCanvasRender.Create(ACanvas);
      try
        Draw(LRender);
      finally
        LRender.Free;
      end;
    finally
      acRestoreClipRegion(ACanvas.Handle, LClipRegion);
    end;
  end;
end;

procedure TACLTextLayout.Draw(ARender: TACLTextLayoutRender);
begin
  Calculate(ARender);
  FLayout.Export(TACLTextLayoutPainter.Create(Self, ARender), True);
end;

procedure TACLTextLayout.DrawTo(ACanvas: TCanvas; const AClipRect: TRect; const AOrigin: TPoint);
var
  APrevOrigin: TPoint;
begin
  if AOrigin <> NullPoint then
  begin
    APrevOrigin := acMoveWindowOrg(ACanvas.Handle, AOrigin);
    try
      Draw(ACanvas, AClipRect - AOrigin);
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
  ASearchPosition: PByte;
  I: Integer;
begin
  if not InRange(APositionInText, 1, Length(FText)) then
    Exit(False);

  ASearchPosition := PByte(PChar(FText) + APositionInText);
  for I := 0 to FBlocks.Count - 1 do
  begin
    AItem := FBlocks.List[I];
    if (PByte(AItem.FPositionInText) >= ASearchPosition) and
       (PByte(AItem.FPositionInText) <  ASearchPosition + AItem.FLength)
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
  AHitTest.Reset;
  AHitTest.HitPoint := P;
  FLayout.Export(AHitTest, False);
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

function TACLTextLayout.GetPadding: TRect;
begin
  Result := NullRect;
end;

function TACLTextLayout.MeasureSize: TSize;
var
  LPadding: TRect;
begin
  if FLayoutIsDirty then
    raise EInvalidOperation.Create(ClassName + ' not calculated yet');
  Result := FLayout.BoundingRect.Size;
  if not Result.IsEmpty then
  begin
    LPadding := GetPadding;
    Inc(Result.cx, LPadding.MarginsWidth);
    Inc(Result.cy, LPadding.MarginsHeight);
  end;
end;

procedure TACLTextLayout.SetBounds(const ABounds: TRect);
begin
  if FBounds <> ABounds then
  begin
    FBounds := ABounds;
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

procedure TACLTextLayout.SetOption(AOptions: Integer; AState: Boolean);
begin
  if AState then
    Options := Options or AOptions
  else
    Options := Options and not AOptions;
end;

procedure TACLTextLayout.SetOptions(AValue: Integer);
begin
  if AValue <> FOptions then
  begin
    FOptions := AValue;
    FLayoutIsDirty := True;
  end;
end;

procedure TACLTextLayout.SetText(const AText: string; const ASettings: TACLTextFormatSettings);
var
  LContext: TACLTextImporter.TContext;
  LCount: Integer;
  LScan: PChar;
  I: Integer;
begin
  FLayoutIsDirty := True;
  FLayout.Clear;
  FBlocks.Clear;
  FText := AText;

  LContext := TACLTextImporter.AllocContext(ASettings, FBlocks);
  try
    LScan := PChar(AText);
    LCount := Length(LContext.TokenDetectors);
    while LScan^ <> #0 do
    begin
      for I := 0 to LCount - 1 do
      begin
        if LContext.TokenDetectors[I](LContext, LScan) then
          Break;
      end;
    end;
    FBlocks.AddSpan(LContext.Span);
  finally
    LContext.Free;
  end;
end;

function TACLTextLayout.ToString: string;
begin
  Result := ToStringEx(TACLPlainTextExporter);
end;

function TACLTextLayout.ToStringEx(ExporterClass: TACLPlainTextExporterClass): string;
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

{ TACLTextImporter.TContext }

destructor TACLTextImporter.TContext.Destroy;
begin
  FreeAndNil(Span);
  inherited;
end;

{ TACLTextViewInfo }

constructor TACLTextViewInfo.Create(const AText: string);
begin
  FText := AText;
  inherited Create(PChar(FText), Length(FText));
end;

function TACLTextViewInfo.Measure(ARender: TACLTextLayoutRender): TSize;
begin
  ARender.Measure(Self);
  Result.cx := FWidth;
  Result.cy := FHeight;
end;

end.
