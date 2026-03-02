////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Formatted Text based on BB-codes
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Graphics.TextLayout;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
  LazUtf8,
{$ELSE}
  Character,
  Windows,
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
  System.UITypes,
  // VCL
  {Vcl.}Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Parsers,
  ACL.FastCode,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.Ex.Stub,
  ACL.Graphics.Fonts,
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

{$REGION ' Advanced Font '}

  { TACLFontShadow }

  TACLFontShadow = class(TPersistent)
  public const
  {$REGION ' Consts '}
    BlurRadiusFactor = 10;
    Offsets: array[TACLMarginPart] of TPoint =
    (
      (X: -1; Y: -1), (X: -1; Y:  0), (X: -1; Y:  1),
      (X:  0; Y: -1), (X:  0; Y:  1), (X:  1; Y:  0),
      (X:  1; Y: -1), (X:  1; Y:  1), (X:  0; Y:  0)
    );
  {$ENDREGION}
  strict private
    FBlur: Integer;
    FBlurSize: Integer;
    FColor: TAlphaColor;
    FDirection: TACLMarginPart;
    FSize: Integer;

    FOnChange: TNotifyEvent;

    function GetAssigned: Boolean;
  protected
    procedure Changed; virtual;
    function GetDrawIterations: Integer; inline;
    function GetTextExtends: TRect;
    // Get/Set
    function GetBlur: Integer; virtual;
    function GetColor: TAlphaColor; virtual;
    function GetDirection: TACLMarginPart; virtual;
    function GetSize: Integer; virtual;
    procedure SetBlur(AValue: Integer); virtual;
    procedure SetColor(AValue: TAlphaColor); virtual;
    procedure SetDirection(AValue: TACLMarginPart); virtual;
    procedure SetSize(AValue: Integer); virtual;
  public
    constructor Create(AChangeEvent: TNotifyEvent);
    procedure Assign(Source: TPersistent); override;
    function Equals(Obj: TObject): Boolean; override;
    procedure Reset; virtual;
    // Properties
    property Assigned: Boolean read GetAssigned;
    property Blur: Integer read GetBlur write SetBlur;
    property Color: TAlphaColor read GetColor write SetColor;
    property Direction: TACLMarginPart read GetDirection write SetDirection;
    property Size: Integer read GetSize write SetSize;
  end;

  { TACLFont }

  TACLFont = class sealed(TFont)
  strict private
    FColorAlpha: Byte;
    FShadow: TACLFontShadow;

    procedure ChangeHandler(Sender: TObject);
    function GetAlphaColor: TAlphaColor;
    function GetTextExtends: TRect; inline;
    procedure SetAlphaColor(const Value: TAlphaColor);
    procedure SetColorAlpha(const AValue: Byte);
    procedure SetShadow(const AValue: TACLFontShadow);
  public
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure Assign(Source: TPersistent); override;
    function AppendTextExtends(const S: TSize): TSize;
    function MeasureSize(const S: PChar; ALength: Integer): TSize; overload;
    function MeasureSize(const S: string): TSize; overload;
    // Properties
    property AlphaColor: TAlphaColor read GetAlphaColor write SetAlphaColor;
    property TextExtends: TRect read GetTextExtends;
  published
    property ColorAlpha: Byte read FColorAlpha write SetColorAlpha default MaxByte;
    property Shadow: TACLFontShadow read FShadow write SetShadow;
  end;

{$ENDREGION}

{$REGION ' Blocks '}

  { TACLTextLayoutBlock }

  TACLTextLayoutBlockClass = class of TACLTextLayoutBlock;
  TACLTextLayoutBlock = class abstract
  protected
    FPosition: TPoint;
    FPositionInText: PChar;
    FHeight: Word;
    FLength: Word;
  public
    function Bounds: TRect; virtual;
    function Export(AExporter: TACLTextLayoutExporter): Boolean; virtual;
    procedure FlushCalculatedValues; virtual;
    procedure Shrink(ARender: TACLTextLayoutRender; AMaxRight: Integer); virtual;
    procedure Rebase(AOldBase, ANewBase: PChar);
    function ToString: string; override;
    //# Properties
    property Length: Word read FLength;
    property Position: TPoint read FPosition;
    property PositionInText: PChar read FPositionInText;
  end;

  { TACLTextLayoutBlockList }

  TACLTextLayoutBlockList = class(TACLObjectListOf<TACLTextLayoutBlock>)
  protected
    procedure AddInit(ABlock: TACLTextLayoutBlock; var AScan: PChar; ABlockLength: Integer);
    procedure AddSpan(ABlock: TACLTextLayoutBlockList);
    function CountOfClass(AClass: TACLTextLayoutBlockClass): Integer;
  public
    function BoundingRect: TRect; virtual;
    function Export(AExporter: TACLTextLayoutExporter; AFreeExporter: Boolean): Boolean; virtual;
    function Find(APositionInText: PChar; out ABlock: TACLTextLayoutBlock): Boolean;
    procedure Offset(ADeltaX, ADeltaY: Integer); virtual;
    procedure Rebase(AOldBase, ANewBase: PChar); virtual;
    function ToString: string; override;
  end;

  { TACLTextLayoutBlockLineBreak }

  TACLTextLayoutBlockLineBreak = class(TACLTextLayoutBlock)
  public
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
  end;

  { TACLTextLayoutBlockSpace }

  TACLTextLayoutBlockSpace = class(TACLTextLayoutBlock)
  protected
    FWidth: Word;
  public
    function Bounds: TRect; override;
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    procedure Shrink(ARender: TACLTextLayoutRender; AMaxRight: Integer); override;
  end;

  { TACLTextLayoutBlockText }

  TACLTextLayoutBlockText = class(TACLTextLayoutBlock)
  protected
    FMetrics: Pointer;
    FLengthVisible: Word;
    FWidth: Word;
  public
    constructor Create(AText: PChar; ATextLength: Word);
    destructor Destroy; override;
    function Bounds: TRect; override;
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
    procedure FlushCalculatedValues; override;
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
  public
    Color: TColor;
    constructor Create(const AColor: string; AInclude: Boolean);
    function Export(AExporter: TACLTextLayoutExporter): Boolean; override;
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
    procedure FlushCalculatedValues; override;
    property Blocks: TArray<TACLTextLayoutBlock> read FBlocks;
  end;

{$ENDREGION}

{$REGION ' Rows '}

  { TACLTextLayoutRow }

  TACLTextLayoutRow = class(TACLTextLayoutBlockList)
  strict private
    FBaseline: Integer;
    FBounds: TRect;
    FCharBroken: TACLTextLayoutBlockText;
    FEndEllipsis: TACLTextLayoutBlockText;
    procedure SetBaseline(AValue: Integer);
  protected
    FHead: PChar;
    FTail: PChar;
    //# Special
    procedure SetCharBroken(ABlock: TACLTextLayoutBlockText);
    procedure SetEndEllipsis(ARender: TACLTextLayoutRender;
      ARightSide: Integer; AEndEllipsis: TACLTextLayoutBlockText);
    //# Properties
    property Baseline: Integer read FBaseline write SetBaseline;
  public
    constructor Create;
    destructor Destroy; override;
    function LineBreak: TACLTextLayoutBlockLineBreak;
    function LineEndPosition(AIncludeLineBreak: Boolean = False): PChar;
    procedure Offset(ADeltaX, ADeltaY: Integer); override;
    procedure Rebase(AOldBase, ANewBase: PChar); override;
    function ToString: string; override;
    //# Properties
    property Bounds: TRect read FBounds write FBounds;
    property CharBroken: TACLTextLayoutBlockText read FCharBroken;
    property EndEllipsis: TACLTextLayoutBlockText read FEndEllipsis;
    property PositionInText: PChar read FHead;
  end;

  { TACLTextLayoutRows }

  TACLTextLayoutRows = class(TACLObjectListOf<TACLTextLayoutRow>)
  public
    function BoundingRect: TRect;
    function Export(AExporter: TACLTextLayoutExporter; AFreeExporter: Boolean): Boolean;
  end;

{$ENDREGION}

{$REGION ' Exporters '}

  { TACLTextLayoutRender }

  TACLTextLayoutRender = class
  public
    function CreateCompatibleRender(ADib: TACLDib): TACLTextLayoutRender; virtual; abstract;
    // Drawing
    procedure DrawImage(ADib: TACLDib; const R: TRect); virtual; abstract;
    procedure DrawText(ABlock: TACLTextLayoutBlockText; X, Y: Integer); virtual; abstract;
    procedure DrawUnderline(const R: TRect); virtual; abstract;
    procedure FillBackground(const R: TRect); virtual; abstract;
    function GetClipBox(out R: TRect): Boolean; virtual; abstract;
    // Measuring
    procedure GetMetrics(out ABaseline, ALineHeight, ASpaceWidth: Integer); virtual; abstract;
    procedure Measure(ABlock: TACLTextLayoutBlockText); virtual; abstract;
    // Metrics
    class function GetChar(ABlock: TACLTextLayoutBlockText; var AOffset: Integer): PChar; virtual; abstract;
    class function GetCharPos(ABlock: TACLTextLayoutBlock; AOffset: Integer): TRect; virtual; abstract;
    class procedure Shrink(ABlock: TACLTextLayoutBlockText; AMaxSize: Integer); virtual; abstract;
    // Setup
    procedure SetFill(AValue: TColor); virtual; abstract;
    procedure SetFont(AFont: TFont); virtual; abstract;
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
    function OnLineBreak(ABlock: TACLTextLayoutBlockLineBreak): Boolean; virtual;
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
    FBlock: TACLTextLayoutBlock;
    FBlockSpan: TACLTextLayoutBlockSpan;
    FHyperlinks: TStack;
    FPoint: TPoint;
    FPosition: PChar;
    FPositionInLineEnd: Boolean;
    FPositionInText: Integer;
    FRowIndex: Integer;

    function GetHint: string;
    function GetHyperlink: TACLTextLayoutBlockHyperlink;
    function GetRowIndex: Integer;
    procedure SetResult(ABlock: TACLTextLayoutBlock;
      APositionInText: PChar; ARowIndex: Integer = -1);
  protected
    function OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean; override;
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnSpan(ABlock: TACLTextLayoutBlockSpan): Boolean; override;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  public
    destructor Destroy; override;
    procedure Calculate(const P: TPoint; ANearest: Boolean = False);
    procedure Reset;
    //# Properties
    property Block: TACLTextLayoutBlock read FBlock;
    property BlockSpan: TACLTextLayoutBlockSpan read FBlockSpan;
    property Hint: string read GetHint;
    property Hyperlink: TACLTextLayoutBlockHyperlink read GetHyperlink;
    property Point: TPoint read FPoint;
    property Position: PChar read FPosition;
    property PositionInLineEnd: Boolean read FPositionInLineEnd;
    property PositionInText: Integer read FPositionInText;
    property RowIndex: Integer read GetRowIndex;
  end;

  { TACLPlainTextExporter }

  TACLPlainTextExporterClass = class of TACLPlainTextExporter;
  TACLPlainTextExporter = class(TACLTextLayoutExporter)
  protected
    FBuffer: TACLStringBuilder;
  public
    constructor Create(ASource: TACLTextLayout);
    destructor Destroy; override;
    function OnLineBreak(ABlock: TACLTextLayoutBlockLineBreak): Boolean; override;
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
    function ToString: string; override;
  end;

  { TACLTextLayoutPainter }

  TACLTextLayoutPainter = class(TACLTextLayoutVisualExporter)
  strict private
    FClipBox: TRect;
    FDefaultTextColor: TColor;
    FDrawBackground: Boolean;
    FDrawContent: Boolean;
    FHasBackground: Boolean;
    FFillColors: TACLTextLayoutValueStack<TColor>;
    FTextColors: TACLTextLayoutValueStack<TColor>;
  protected
    function OnFillColor(ABlock: TACLTextLayoutBlockFillColor): Boolean; override;
    function OnFontColor(ABlock: TACLTextLayoutBlockFontColor): Boolean; override;
    function OnHyperlink(ABlock: TACLTextLayoutBlockHyperlink): Boolean; override;
    function OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean; override;
    function OnText(AText: TACLTextLayoutBlockText): Boolean; override;
    procedure UpdateTextColor; virtual;
  public
    constructor Create(AOwner: TACLTextLayout; ARender: TACLTextLayoutRender); override;
    constructor CreateEx(AOwner: TACLTextLayout;
      ARender: TACLTextLayoutRender; ADrawBackground, ADrawContent: Boolean); virtual;
    destructor Destroy; override;
  end;

  { TACLTextLayoutShadowPainter }

  TACLTextLayoutShadowPainter = class(TACLTextLayoutVisualExporter)
  strict private
    FBuffer: TACLDib;
    FOrigin: TPoint;
    FShadow: TACLFontShadow;
    FShadowDirection: TPoint;
    FShadowSize: Integer;
    FShadowStroke: Boolean;
    FTargetRender: TACLTextLayoutRender;
  protected
    function OnText(ABlock: TACLTextLayoutBlockText): Boolean; override;
  public
    constructor Create(AOwner: TACLTextLayout; ARender: TACLTextLayoutRender); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
  end;

{$ENDREGION}

{$REGION ' Native Render '}

  TACLTextLayoutCanvasRenderClass = class of TACLTextLayoutCanvasRender;
  TACLTextLayoutCanvasRender = class(TACLTextLayoutRender)
  strict private
    FCanvas: TCanvas;
  public
    constructor Create(ACanvas: TCanvas); virtual;
    function CreateCompatibleRender(ADib: TACLDib): TACLTextLayoutRender; override;
    // Drawing
    procedure DrawImage(ADib: TACLDib; const R: TRect); override;
    procedure DrawText(ABlock: TACLTextLayoutBlockText; X, Y: Integer); override;
    procedure DrawUnderline(const R: TRect); override;
    procedure FillBackground(const R: TRect); override;
    function GetClipBox(out R: TRect): Boolean; override;
    // Measuring
    procedure GetMetrics(out ABaseline, ALineHeight, ASpaceWidth: Integer); override;
    procedure Measure(ABlock: TACLTextLayoutBlockText); override;
    // Metrics
    class function GetChar(ABlock: TACLTextLayoutBlockText; var AOffset: Integer): PChar; override;
    class function GetCharPos(ABlock: TACLTextLayoutBlock; AOffset: Integer): TRect; override;
    class procedure Shrink(ABlock: TACLTextLayoutBlockText; AMaxSize: Integer); override;
    // Setup
    procedure SetFill(AValue: TColor); override;
    procedure SetFont(AFont: TFont); override;
    // Properties
    property Canvas: TCanvas read FCanvas;
  end;

  { TACLTextLayoutCanvasRender32 }

  TACLTextLayoutCanvasRender32 = class(TACLTextLayoutCanvasRender)
  strict private
    FFont: TACLFont;
  public
    destructor Destroy; override;
    procedure DrawText(ABlock: TACLTextLayoutBlockText; X, Y: Integer); override;
    procedure DrawUnderline(const R: TRect); override;
    procedure FillBackground(const R: TRect); override;
    procedure SetFont(AFont: TFont); override;
  end;

{$ENDREGION}

{$REGION ' TextLayout '}

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
    class operator Equal(const V1, V2: TACLTextFormatSettings): Boolean;
    class operator NotEqual(const V1, V2: TACLTextFormatSettings): Boolean;
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

    function GetRowCount: Integer;
    procedure SetBounds(const ABounds: TRect);
    procedure SetHorzAlignment(AValue: TAlignment);
    procedure SetOptions(AValue: Integer);
    procedure SetVertAlignment(AValue: TVerticalAlignment);
  protected
    FBlocks: TACLTextLayoutBlockList;
    FRows: TACLTextLayoutRows;
    FRowsDirty: Boolean;
    FTruncated: Boolean;

    function GetDefaultHyperLinkColor: TColor; virtual;
    function GetDefaultRender: TACLTextLayoutCanvasRenderClass; virtual;
    function GetDefaultTextColor: TColor; virtual;
    function GetRowIndex(ABlock: TACLTextLayoutBlock): Integer;
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
    function FindBlock(APositionInText: Integer;
      out ABlock: TACLTextLayoutBlock; AVisible: Boolean = True): Boolean;
    function FindCharBounds(APositionInText: Integer;
      out ABounds: TRect): Boolean; overload;
    function FindHyperlink(const P: TPoint;
      out AHyperlink: TACLTextLayoutBlockHyperlink): Boolean;

    //# Text
    function ToString: string; override; // exports visible text
    function ToStringEx(ExporterClass: TACLPlainTextExporterClass): string; // exports original text
    procedure ReplaceText(AStart, ALength: Integer;
      const ANewText: string; const ASettings: TACLTextFormatSettings);
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
    property RowCount: Integer read GetRowCount;
    property Text: string read FText;
  end;

  { TACLTextLayout32 }

  TACLTextLayout32 = class(TACLTextLayout)
  protected
    function GetDefaultRender: TACLTextLayoutCanvasRenderClass; override;
  end;

  { TACLTextViewInfo }

  TACLTextViewInfo = class(TACLTextLayoutBlockText)
  strict private
    FText: string;
  public
    constructor Create(const AText: string); reintroduce;
    function Measure(ARender: TACLTextLayoutRender): TSize;
  end;

{$ENDREGION}

const
  atoAutoHeight  = 1;
  atoAutoWidth   = 2;
  atoEditControl = 4;
  atoEndEllipsis = 8;
  atoNoClip      = 16;
  atoSingleLine  = 32;
  atoWordWrap    = 64;
  atoCharBreak   = 128;

const
  // acAdvDrawText
  ADT_ALPHABLEND = 1;
  ADT_FORMATTING = 2;

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
  const AText: string; var ABounds: TRect; AFlags, AExFlags: Cardinal);
procedure acExpandPrefixes(var AText: string; var AExFlags: Cardinal; AHide: Boolean);

{$REGION ' DrawText w alpha-channel '}
procedure DrawText32(ACanvas: TCanvas; const R: TRect; AText: string;
  AFont: TACLFont; AAlignment: TAlignment = taLeftJustify;
  AVertAlignment: TVerticalAlignment = taVerticalCenter; AEndEllipsis: Boolean = True);
procedure DrawText32Core(const AText: PChar; ALength, AWidth, AHeight: Integer;
  AFont: TACLFont; const ATextOffset: TPoint; ATextDuplicateIndent: Integer;
  ADrawProc: TProc<TACLDib>);
procedure DrawText32Duplicated(ACanvas: TCanvas; const R: TRect;
  const AText: string; const ATextOffset: TPoint; ADuplicateOffset: Integer; AFont: TACLFont);
{$ENDREGION}
implementation

uses
{$IFDEF ACL_CAIRO_TEXTOUT}
  ACL.Graphics.Ex.Cairo,
{$ENDIF}
  ACL.Web;

type

{$REGION ' Calculator '}

  { TACLTextLayoutCalculator }

  TACLTextLayoutCalculator = class(TACLTextLayoutVisualExporter)
  strict private const
    RtlRangeCapacity = 8;
  strict private
    FCharBreak: Boolean;
    FMaxLineCount: Integer;
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
    FRowTruncated: Boolean;
  {$IFDEF ACL_TEXTLAYOUT_RTL}
    FRowRtlRange: Boolean;
    FRowRtlRanges: TACLListOf<TACLRange>;
  {$ENDIF}
    FRows: TACLTextLayoutRows;
    FPrevRowEndEllipsis: TACLTextLayoutBlockText;

    function AddBlock(ABlock: TACLTextLayoutBlock;
      AWidth: Integer = 0): Boolean; {$IFNDEF DEBUG}inline;{$ENDIF}
    function AddBlockOfContent(ABlock: TACLTextLayoutBlock;
      AWidth: Integer): Boolean; {$IFNDEF DEBUG}inline;{$ENDIF}
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
    function OnLineBreak(ABlock: TACLTextLayoutBlockLineBreak = nil): Boolean; override;
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
    Spaces = acParserDefaultSpaceChars;
    Delimiters = '[]()\' +
      #$200B#$201c#$201D#$2018#$2019#$FF08#$FF09#$FF0C#$FF1A#$FF1B#$FF1F#$060C +
      #$3000#$3001#$3002#$300c#$300d#$300e#$300f#$300a#$300b#$3008#$3009#$3014#$3015 +
      Spaces; // Spaces в конце!
    StyleDelimiters = '[]'#13#10#9#0;
  protected type
  {$REGION ' Sub-Types '}
    TContext = class;
    TTokenDetector = function (Ctx: TContext; var Scan: PChar; ScanEnd: PChar): Boolean;
    TTokenDetectorInText = function (Ctx: TContext; S: PChar; L: Integer): Boolean;
    TContext = class
    public
      HyperlinkDepth: Integer;
      TokenDetectors: array of TTokenDetector;
      TokenInTextDetectors: array of TTokenDetectorInText;
      Output: TACLTextLayoutBlockList;
      Span: TACLTextLayoutBlockList;
      destructor Destroy; override;
      procedure Run(Scan: PChar; Length: Integer);
    end;
  {$ENDREGION}
  protected
    class function AllocContext(const ASettings: TACLTextFormatSettings;
      AOutput: TACLTextLayoutBlockList): TACLTextImporter.TContext;

    //# Token Detectors
    class function IsLineBreak(Ctx: TContext;
      var Scan: PChar; ScanEnd: PChar): Boolean; static;
    class function IsLineBreakCpp(Ctx: TContext;
      var Scan: PChar; ScanEnd: PChar): Boolean; static;
    class function IsSpace(Ctx: TContext;
      var Scan: PChar; ScanEnd: PChar): Boolean; static;
    class function IsStyle(Ctx: TContext;
      var Scan: PChar; ScanEnd: PChar): Boolean; static;
    class function IsText(Ctx: TContext;
      var Scan: PChar; ScanEnd: PChar): Boolean; static;
    class function IsTimeCode(Ctx: TContext;
      var Scan: PChar; ScanEnd: PChar): Boolean; static;

    // # TokenInText Detectors
    class function IsEmail(Ctx: TContext; S: PChar; L: Integer): Boolean; static;
    class function IsURL(Ctx: TContext; S: PChar; L: Integer): Boolean; static;
  end;

{$ENDREGION}

{$REGION ' acAdvDrawText '}

procedure acExpandPrefixes(var AText: string; var AExFlags: Cardinal; AHide: Boolean);
var
  ABytesInChar: Integer;
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
            AExFlags := AExFlags or ADT_FORMATTING;
            ABuffer.Append('[u]');
            ABuffer.Append(AChars^);
            ABytesInChar := acCharLength(AChars) - 1;
            if ABytesInChar > 0 then
            begin
              ABuffer.Append(AChars + 1, ABytesInChar);
              Dec(ALength, ABytesInChar);
              Inc(AChars, ABytesInChar);
            end;
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
  const AText: string; var ABounds: TRect; AFlags, AExFlags: Cardinal);
const
  //DT_DEFAULT_TABWIDTH = 8;
  DT_CHARBREAK = DT_EDITCONTROL or DT_WORDBREAK;
  DT_REQUIRE_MAXHEIGHT = DT_EDITCONTROL or DT_END_ELLIPSIS;
var
  LText: string;
  LTextLayout: TACLTextLayout;
begin
  if AExFlags and ADT_ALPHABLEND <> 0 then
    LTextLayout := TACLTextLayout32.Create(ACanvas.Font)
  else
    LTextLayout := TACLTextLayout.Create(ACanvas.Font);
  try
    // Text
    LText := AText;
    if AFlags and DT_NOPREFIX = 0 then
      acExpandPrefixes(LText, AExFlags, AFlags and DT_HIDEPREFIX <> 0);
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
    if AExFlags and ADT_FORMATTING <> 0 then
      LTextLayout.SetText(LText, TACLTextFormatSettings.Formatted)
    else
      LTextLayout.SetText(LText, TACLTextFormatSettings.PlainText);

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
    LTextLayout.SetOption(atoCharBreak, AFlags and DT_CHARBREAK = DT_CHARBREAK);
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
{$ENDREGION}

{$REGION ' Advanced Font '}

{ TACLFont }

destructor TACLFont.Destroy;
begin
  FreeAndNil(FShadow);
  inherited Destroy;
end;

procedure TACLFont.AfterConstruction;
begin
  inherited;
  FColorAlpha := MaxByte;
  FShadow := TACLFontShadow.Create(ChangeHandler);
end;

procedure TACLFont.Assign(Source: TPersistent);
begin
  inherited Assign(Source);

  if Source is TACLFont then
  begin
    ColorAlpha := TACLFont(Source).ColorAlpha;
    Shadow := TACLFont(Source).Shadow;
  end;
end;

function TACLFont.AppendTextExtends(const S: TSize): TSize;
var
  AExtends: TRect;
begin
  Result := S;
  if not Result.IsEmpty then
  begin
    AExtends := TextExtends;
    Inc(Result.cx, AExtends.MarginsWidth);
    Inc(Result.cy, AExtends.MarginsHeight);
  end;
end;

function TACLFont.MeasureSize(const S: PChar; ALength: Integer): TSize;
begin
  Result := AppendTextExtends(acTextSize(Self, S, ALength));
end;

function TACLFont.MeasureSize(const S: string): TSize;
begin
  Result := AppendTextExtends(acTextSize(Self, S));
end;

procedure TACLFont.ChangeHandler(Sender: TObject);
begin
  Changed;
end;

function TACLFont.GetAlphaColor: TAlphaColor;
begin
  Result := TAlphaColor.FromColor(Color, ColorAlpha);
end;

function TACLFont.GetTextExtends: TRect;
begin
  Result := Shadow.GetTextExtends;
end;

procedure TACLFont.SetAlphaColor(const Value: TAlphaColor);
begin
  Color := Value.ToColor;
  ColorAlpha := Value.A;
end;

procedure TACLFont.SetColorAlpha(const AValue: Byte);
begin
  if FColorAlpha <> AValue then
  begin
    FColorAlpha := AValue;
    Changed;
  end;
end;

procedure TACLFont.SetShadow(const AValue: TACLFontShadow);
begin
  FShadow.Assign(AValue);
end;

{ TACLFontShadow }

constructor TACLFontShadow.Create(AChangeEvent: TNotifyEvent);
begin
  inherited Create;
  Reset;
  FOnChange := AChangeEvent;
end;

procedure TACLFontShadow.Assign(Source: TPersistent);
begin
  if Source is TACLFontShadow then
  begin
    Color := TACLFontShadow(Source).Color;
    Direction := TACLFontShadow(Source).Direction;
    Size := TACLFontShadow(Source).Size;
    Blur := TACLFontShadow(Source).Blur;
  end;
end;

function TACLFontShadow.Equals(Obj: TObject): Boolean;
begin
  Result := (ClassType = Obj.ClassType) and
    (TACLFontShadow(Obj).Blur = Blur) and
    (TACLFontShadow(Obj).Color = Color) and
    (TACLFontShadow(Obj).Size = Size) and
    (TACLFontShadow(Obj).Direction = Direction);
end;

function TACLFontShadow.GetTextExtends: TRect;
var
  AIndent: Integer;
begin
  Result := NullRect;
  if Assigned then
  begin
    AIndent := Size + FBlurSize + IfThen(FBlurSize > 0, Size);
    if Direction in [mzLeftTop, mzTop, mzRightTop, mzClient] then
      Result.Top := AIndent
    else
      Result.Top := FBlurSize;

    if Direction in [mzLeftTop, mzLeft, mzLeftBottom, mzClient] then
      Result.Left := AIndent
    else
      Result.Left := FBlurSize;

    if Direction in [mzLeftBottom, mzBottom, mzRightBottom, mzClient] then
      Result.Bottom := AIndent
    else
      Result.Bottom := FBlurSize;

    if Direction in [mzRightTop, mzRight, mzRightBottom, mzClient] then
      Result.Right := AIndent
    else
      Result.Right := FBlurSize;
  end;
end;

procedure TACLFontShadow.Reset;
begin
  FColor := TAlphaColor.None;
  FDirection := mzRightBottom;
  FBlur := 0;
  FBlurSize := 0;
  FSize := 1;
  Changed;
end;

procedure TACLFontShadow.Changed;
begin
  CallNotifyEvent(Self, FOnChange);
end;

function TACLFontShadow.GetAssigned: Boolean;
begin
  Result := (Size > 0) and Color.IsValid;
end;

function TACLFontShadow.GetBlur: Integer;
begin
  Result := FBlur;
end;

function TACLFontShadow.GetColor: TAlphaColor;
begin
  Result := FColor;
end;

function TACLFontShadow.GetDirection: TACLMarginPart;
begin
  Result := FDirection;
end;

function TACLFontShadow.GetDrawIterations: Integer;
begin
  if not Assigned then
    Result := 0
  else
    if Direction = mzClient then
      Result := Size * 2
    else
      Result := Size;
end;

function TACLFontShadow.GetSize: Integer;
begin
  Result := FSize;
end;

procedure TACLFontShadow.SetBlur(AValue: Integer);
begin
  AValue := EnsureRange(AValue, 0, 5 * BlurRadiusFactor);
  if FBlur <> AValue then
  begin
    FBlur := AValue;
    FBlurSize := (Blur div BlurRadiusFactor) + Ord(Blur mod BlurRadiusFactor <> 0);
    Changed;
  end;
end;

procedure TACLFontShadow.SetColor(AValue: TAlphaColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    Changed;
  end;
end;

procedure TACLFontShadow.SetDirection(AValue: TACLMarginPart);
begin
  if Direction <> AValue then
  begin
    FDirection := AValue;
    Changed;
  end;
end;

procedure TACLFontShadow.SetSize(AValue: Integer);
begin
  AValue := MinMax(AValue, 1, 3);
  if AValue <> Size then
  begin
    FSize := AValue;
    Changed;
  end;
end;

{$ENDREGION}

{$REGION ' DrawText w alpha-channel '}
var
  FGammaTable: array[Byte] of Byte;
  FGammaTableInitialized: Boolean;
  FTextBlur: TACLBlurFilter;
  FTextBuffer: TACLDib;

function CanDrawText32(ACanvas: TCanvas; const AText: string;
  const ARect: TRect; AFont: TACLFont): Boolean; inline;
begin
  Result := (AText <> '') and not ARect.IsEmpty and
    ((AFont.ColorAlpha > 0) and (AFont.Color <> clNone) or AFont.Shadow.Assigned) and
    acRectVisible(ACanvas, ARect);
end;

procedure Text32ApplyBlur(ALayer: TACLDib; AShadow: TACLFontShadow);
begin
  if AShadow.Blur > 0 then
  begin
    if FTextBlur = nil then
      FTextBlur := TACLBlurFilter.Create;
    FTextBlur.Radius := Round(AShadow.Blur / TACLFontShadow.BlurRadiusFactor);
    FTextBlur.Apply(ALayer);
  end;
end;

procedure Text32RecoverAlpha(ALayer: TACLDib; const ATextColor: TACLPixel32);
const
  K = 700; // [1..5000]
var
  AAlpha: Integer;
  P: PACLPixel32;
  I: Integer;
begin
  if not FGammaTableInitialized then
  begin
    for I := 0 to MaxByte do
      FGammaTable[I] := FastTrunc(MaxByte * Power(I / MaxByte, 1000 / K));
    FGammaTableInitialized := True;
  end;

  P := ALayer.Colors;
  for I := 1 to ALayer.ColorCount do
  begin
    if PDWORD(P)^ and TACLPixel32.EssenceMask <> 0 then
    begin
      AAlpha := 128 + FGammaTable[P^.R] * 77 + FGammaTable[P^.G] * 151 + FGammaTable[P^.B] * 28;
      AAlpha := AAlpha * ATextColor.A shr 16;
      P^.B := TACLColors.PremultiplyTable[ATextColor.B, AAlpha];
      P^.G := TACLColors.PremultiplyTable[ATextColor.G, AAlpha];
      P^.R := TACLColors.PremultiplyTable[ATextColor.R, AAlpha];
      P^.A := AAlpha;
    end
    else
      P^.A := 0;

    Inc(P);
  end;
end;

procedure DrawText32Core(const AText: PChar; ALength, AWidth, AHeight: Integer;
  AFont: TACLFont; const ATextOffset: TPoint; ATextDuplicateIndent: Integer;
  ADrawProc: TProc<TACLDib>);

  procedure Text32Output(ACanvas: TCanvas; const AOffset: TPoint);
  begin
    acTextOut(ACanvas, AOffset.X, AOffset.Y, AText, ALength, nil);
    if ATextDuplicateIndent > 0 then
      acTextOut(ACanvas, AOffset.X + ATextDuplicateIndent, AOffset.Y, AText, ALength, nil);
  end;

var
  LPoint: TPoint;
  LTextColor: TACLPixel32;
  I, J: Integer;
begin
  if (AWidth <= 0) or (AHeight <= 0) then
    Exit;

  if FTextBuffer = nil then
    FTextBuffer := TACLDib.Create(AWidth, AHeight)
  else
    FTextBuffer.Resize(AWidth, AHeight);

  FTextBuffer.Canvas.SetScaledFont(AFont);
  FTextBuffer.Canvas.Font.Color := clWhite;
  FTextBuffer.Canvas.Brush.Style := bsClear;

  if AFont.Shadow.Assigned then
  begin
    FTextBuffer.Reset;

    if AFont.Shadow.Direction = mzClient then
    begin
      for I := -AFont.Shadow.Size to AFont.Shadow.Size do
      for J := -AFont.Shadow.Size to AFont.Shadow.Size do
        if I <> J then
          Text32Output(FTextBuffer.Canvas, ATextOffset + Point(I, J));
    end
    else
    begin
      LPoint := ATextOffset;
      for I := 1 to AFont.Shadow.Size do
      begin
        LPoint := LPoint + TACLFontShadow.Offsets[AFont.Shadow.Direction];
        Text32Output(FTextBuffer.Canvas, LPoint);
      end;
    end;
    Text32ApplyBlur(FTextBuffer, AFont.Shadow);
    Text32RecoverAlpha(FTextBuffer, TACLPixel32.Create(AFont.Shadow.Color));
    ADrawProc(FTextBuffer);
  end;

  LTextColor := TACLPixel32.Create(acGetActualColor(AFont.Color, clBlack), AFont.ColorAlpha);
  if LTextColor.A > 0 then
  begin
    FTextBuffer.Reset;
    Text32Output(FTextBuffer.Canvas, ATextOffset);
    Text32RecoverAlpha(FTextBuffer, LTextColor);
    ADrawProc(FTextBuffer);
  end;
end;

procedure DrawText32(ACanvas: TCanvas; const R: TRect; AText: string;
  AFont: TACLFont; AAlignment: TAlignment; AVertAlignment: TVerticalAlignment;
  AEndEllipsis: Boolean);
var
  LTextExtends: TRect;
  LTextOffset: TPoint;
  LTextSize: TSize;
begin
  if CanDrawText32(ACanvas, AText, R, AFont) then
  begin
    MeasureCanvas.SetScaledFont(AFont);
    LTextExtends := AFont.TextExtends;
    LTextSize := acTextSize(MeasureCanvas, AText);
    if AEndEllipsis then
      acTextEllipsize(MeasureCanvas, AText, LTextSize, R.Width - LTextExtends.MarginsWidth);
    Inc(LTextSize.cy, LTextExtends.MarginsHeight);
    Inc(LTextSize.cx, LTextExtends.MarginsWidth);
    LTextOffset := acTextAlign(R, LTextSize, AAlignment, AVertAlignment);
    DrawText32Core(PChar(AText), Length(AText),
      LTextSize.cx, LTextSize.cy, AFont, LTextExtends.TopLeft, 0,
      procedure (ABuffer: TACLDib)
      begin
        ABuffer.DrawBlend(ACanvas, LTextOffset);
      end);
  end;
end;

procedure DrawText32Duplicated(ACanvas: TCanvas; const R: TRect;
  const AText: string; const ATextOffset: TPoint; ADuplicateOffset: Integer;
  AFont: TACLFont);
begin
  if CanDrawText32(ACanvas, AText, R, AFont) then
  begin
    DrawText32Core(PChar(AText), Length(AText), R.Width, R.Height, AFont,
      ATextOffset + AFont.TextExtends.TopLeft, ADuplicateOffset,
      procedure (ABuffer: TACLDib)
      begin
        ABuffer.DrawBlend(ACanvas, R.TopLeft);
      end);
  end;
end;
{$ENDREGION}

{$REGION ' Blocks '}

{ TACLTextLayoutBlock }

function TACLTextLayoutBlock.Bounds: TRect;
begin
  Result := TRect.Create(FPosition, 0, FHeight);
end;

function TACLTextLayoutBlock.Export(AExporter: TACLTextLayoutExporter): Boolean;
begin
  Result := True;
end;

procedure TACLTextLayoutBlock.FlushCalculatedValues;
begin
  // do nothing
end;

procedure TACLTextLayoutBlock.Rebase(AOldBase, ANewBase: PChar);
begin
  FPositionInText := ANewBase + (FPositionInText - AOldBase);
end;

procedure TACLTextLayoutBlock.Shrink(ARender: TACLTextLayoutRender; AMaxRight: Integer);
begin
  FPosition.X := Min(FPosition.X, AMaxRight);
end;

function TACLTextLayoutBlock.ToString: string;
begin
  if (FPositionInText <> nil) and (FLength > 0) then
    SetString(Result, FPositionInText, FLength)
  else
    Result := '';
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
  if (ABlock.Count > 1) and (ABlock.CountOfClass(TACLTextLayoutBlockText) > 1) then
    Add(TACLTextLayoutBlockSpan.Create(ABlock))
  else
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

function TACLTextLayoutBlockList.Find(
  APositionInText: PChar; out ABlock: TACLTextLayoutBlock): Boolean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    ABlock := List[I];
    if (APositionInText >= ABlock.PositionInText) and
       (APositionInText <  ABlock.PositionInText + ABlock.FLength)
    then
      Exit(True);
  end;
  Result := False;
end;

procedure TACLTextLayoutBlockList.Offset(ADeltaX, ADeltaY: Integer);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    List[I].FPosition.Offset(ADeltaX, ADeltaY);
end;

procedure TACLTextLayoutBlockList.Rebase(AOldBase, ANewBase: PChar);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    List[I].Rebase(AOldBase, ANewBase);
end;

function TACLTextLayoutBlockList.ToString: string;
var
  LBuilder: TACLStringBuilder;
  I: Integer;
begin
  LBuilder := TACLStringBuilder.Get;
  try
    for I := 0 to Count - 1 do
      LBuilder.Append(List[I].ToString);
    Result := LBuilder.ToString;
  finally
    LBuilder.Release;
  end;
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

procedure TACLTextLayoutBlockText.FlushCalculatedValues;
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
  if (FPositionInText <> nil) and (TextLengthVisible > 0) then
    SetString(Result, FPositionInText, TextLengthVisible)
  else
    Result := '';
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
  Color := StringToColor(AColor);
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

procedure TACLTextLayoutBlockSpan.FlushCalculatedValues;
var
  I: Integer;
begin
  for I := Low(FBlocks) to High(FBlocks) do
    FBlocks[I].FlushCalculatedValues;
  inherited;
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
  FreeAndNil(FCharBroken);
  inherited;
end;

function TACLTextLayoutRow.LineBreak: TACLTextLayoutBlockLineBreak;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
  begin
    if List[I].ClassType = TACLTextLayoutBlockLineBreak then
      Exit(TACLTextLayoutBlockLineBreak(List[I]));
  end;
  Result := nil;
end;

function TACLTextLayoutRow.LineEndPosition(AIncludeLineBreak: Boolean = False): PChar;
var
  LBlock: TACLTextLayoutBlock;
begin
  Result := FTail;
  if AIncludeLineBreak then
  begin
    LBlock := LineBreak;
    if LBlock <> nil then
      Result := LBlock.PositionInText + LBlock.Length;
  end;
end;

procedure TACLTextLayoutRow.Offset(ADeltaX, ADeltaY: Integer);
begin
  FBounds.Offset(ADeltaX, ADeltaY);
  inherited;
end;

procedure TACLTextLayoutRow.Rebase(AOldBase, ANewBase: PChar);
begin
  inherited;
  if FHead <> nil then
    FHead := ANewBase + (FHead - AOldBase);
  if FTail <> nil then
    FTail := ANewBase + (FTail - AOldBase);
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

procedure TACLTextLayoutRow.SetCharBroken(ABlock: TACLTextLayoutBlockText);
begin
{$IFDEF DEBUG}
  if ABlock = nil then
    raise EInvalidOperation.Create('Row: the CharBroken block must be specified');
  if CharBroken <> nil then
    raise EInvalidOperation.Create('Row: the CharBroken block is already specified');
{$ENDIF}
  FCharBroken := ABlock;
  FHead := ABlock.PositionInText;
  FTail := ABlock.PositionInText;
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

function TACLTextLayoutRow.ToString: string;
begin
  if PositionInText = nil then
    Exit('');
  if EndEllipsis <> nil then
    Result := inherited
  else
    Result := acMakeString(FHead, FTail);
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

function TACLTextLayoutExporter.OnLineBreak(ABlock: TACLTextLayoutBlockLineBreak): Boolean;
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
  LHeight: Integer;
begin
  if ABlock.Include then
  begin
    if VarIsFloat(ABlock.Value) then
      LHeight := Round(Font.Height * ABlock.Value)
    else
      LHeight := acGetFontHeight(ABlock.Value, Owner.TargetDpi);

    FFontSizes.Push(LHeight, ABlock.ClassType);
  end
  else
    FFontSizes.Pop(ABlock.ClassType);

  Font.Height := FFontSizes.Peek;
  Result := True;
end;

function TACLTextLayoutVisualExporter.OnFontStyle(ABlock: TACLTextLayoutBlockFontStyle): Boolean;
begin
  if ABlock.Include then
    Inc(FFontStyles[ABlock.Style])
  else if FFontStyles[ABlock.Style] > 0 then
    Dec(FFontStyles[ABlock.Style]);

  if FFontStyles[ABlock.Style] > 0 then
    Font.Style := Font.Style + [ABlock.Style]
  else
    Font.Style := Font.Style - [ABlock.Style];

  Result := True;
end;

{ TACLTextLayoutHitTest }

destructor TACLTextLayoutHitTest.Destroy;
begin
  FreeAndNil(FHyperlinks);
  inherited;
end;

procedure TACLTextLayoutHitTest.Calculate(const P: TPoint; ANearest: Boolean);
var
  I: Integer;
  LRow: TACLTextLayoutRow;
  LRowBox: TRect;
begin
  Reset;
  FPoint := P;
  Owner.FRows.Export(Self, False);
  if Block = nil then
    FreeAndNil(FHyperlinks);
  if Block <> nil then
  begin
    if RowIndex >= 0 then
    begin
      LRow := Owner.FRows.List[RowIndex];
      if (LRow <> nil) and (FPosition >= LRow.LineEndPosition) then
      begin
        SetResult(Block, LRow.LineEndPosition, RowIndex);
        FPositionInLineEnd := True;
      end;
    end;
  end
  else
    if ANearest then
    begin
      LRowBox := Owner.FRows.BoundingRect;
      if Point.Y < LRowBox.Top then
        SetResult(nil, PChar(Owner.Text), 0)
      else if Point.Y > LRowBox.Bottom then
        SetResult(nil, PChar(Owner.Text) + Length(Owner.Text), Owner.RowCount - 1)
      else
        for I := 0 to Owner.FRows.Count - 1 do
        begin
          LRow := Owner.FRows.List[I];
          if (Point.Y >= LRow.Bounds.Top) and (Point.Y < LRow.Bounds.Bottom) then
          begin
            if Point.X < LRow.Bounds.Left then
              SetResult(nil, LRow.PositionInText, I)
            else
            begin
              SetResult(nil, LRow.LineEndPosition, I);
              FPositionInLineEnd := (LRow.Count > 0) and (LRow.LineBreak = nil);
            end;
            Break;
          end;
        end;
    end;
end;

function TACLTextLayoutHitTest.GetHint: string;
var
  LRow: TACLTextLayoutRow;
  LRowIndex: Integer;
begin
  LRowIndex := RowIndex;
  if LRowIndex >= 0 then
  begin
    LRow := Owner.FRows[LRowIndex];
    Result := acMakeString(LRow.FHead, LRow.FTail);
  end
  else
    Result := '';
end;

function TACLTextLayoutHitTest.GetHyperlink: TACLTextLayoutBlockHyperlink;
begin
  if (FHyperlinks <> nil) and (FHyperlinks.Count > 0) then
    Result := FHyperlinks.Peek
  else
    Result := nil;
end;

function TACLTextLayoutHitTest.GetRowIndex: Integer;
begin
  if FRowIndex < 0 then
    FRowIndex := Owner.GetRowIndex(Block);
  Result := FRowIndex;
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
  if ABlock.Bounds.Contains(Point) then
  begin
    SetResult(ABlock, ABlock.FPositionInText +
      MulDiv(1, Point.X - ABlock.FPosition.X, ABlock.FWidth));
    Exit(False);
  end;
  Result := True;
end;

function TACLTextLayoutHitTest.OnSpan(ABlock: TACLTextLayoutBlockSpan): Boolean;
begin
  if FBlockSpan = nil then
  begin
    FBlockSpan := ABlock;
    Result := inherited;
    if Result then
      FBlockSpan := nil;
  end
  else
    Result := inherited;
end;

function TACLTextLayoutHitTest.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
var
  LPos: Integer;
begin
  if ABlock.Bounds.Contains(Point) then
  begin
    LPos := Point.X - ABlock.FPosition.X;
    SetResult(ABlock, Owner.GetDefaultRender.GetChar(ABlock, LPos));
    FPoint.X := LPos + ABlock.FPosition.X;
    Exit(False);
  end;
  Result := True;
end;

procedure TACLTextLayoutHitTest.Reset;
begin
  FBlock := nil;
  FBlockSpan := nil;
  FRowIndex := -1;
  FPositionInLineEnd := False;
  FPositionInText := -1;
  FPosition := nil;
  FreeAndNil(FHyperlinks);
end;

procedure TACLTextLayoutHitTest.SetResult(
  ABlock: TACLTextLayoutBlock; APositionInText: PChar; ARowIndex: Integer = -1);
var
  LPositionBase: PChar;
  LPositionEnd: PChar;
begin
  FBlock := ABlock;
  FRowIndex := ARowIndex;
  FPosition := nil;
  LPositionBase := PChar(Owner.Text);
  LPositionEnd := Length(Owner.Text) + LPositionBase;
  if APositionInText < LPositionBase then
    FPositionInText := -1
  else if APositionInText > LPositionEnd then
    FPositionInText := -1
  else
  begin
    FPosition := APositionInText;
    FPositionInText := FPosition - LPositionBase;
  end;
end;

{ TACLPlainTextExporter }

constructor TACLPlainTextExporter.Create;
begin
  inherited;
  FBuffer := TACLStringBuilder.Create(Length(Owner.Text))
end;

destructor TACLPlainTextExporter.Destroy;
begin
  FreeAndNil(FBuffer);
  inherited;
end;

function TACLPlainTextExporter.OnLineBreak(ABlock: TACLTextLayoutBlockLineBreak): Boolean;
begin
  FBuffer.AppendLine;
  Result := True;
end;

function TACLPlainTextExporter.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  FBuffer.Append(' ');
  Result := True;
end;

function TACLPlainTextExporter.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  FBuffer.Append(ABlock.Text, ABlock.TextLength);
  Result := True;
end;

function TACLPlainTextExporter.ToString: string;
begin
  Result := FBuffer.ToString;
end;

{ TACLTextLayoutPainter }

constructor TACLTextLayoutPainter.Create;
begin
  CreateEx(AOwner, ARender, True, True);
end;

constructor TACLTextLayoutPainter.CreateEx(AOwner: TACLTextLayout;
  ARender: TACLTextLayoutRender; ADrawBackground, ADrawContent: Boolean);
begin
  inherited Create(AOwner, ARender);
  FDrawContent := ADrawContent;
  FDrawBackground := ADrawBackground;
  FDefaultTextColor := Owner.GetDefaultTextColor;
  FFillColors := TACLTextLayoutValueStack<TColor>.Create;
  FTextColors := TACLTextLayoutValueStack<TColor>.Create;
  if not ARender.GetClipBox(FClipBox) then
  begin
    FClipBox := Rect(
      Integer.MinValue, Integer.MinValue,
      Integer.MaxValue, Integer.MaxValue);
  end;
  UpdateTextColor;
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

  if FDrawBackground then
  begin
    FHasBackground := FFillColors.Count > 0;
    if FHasBackground then
      Render.SetFill(FFillColors.Peek)
    else
      Render.SetFill(clNone);
  end;

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

function TACLTextLayoutPainter.OnSpace(ABlock: TACLTextLayoutBlockSpace): Boolean;
begin
  if (ABlock.FWidth > 0) and FClipBox.IntersectsWith(ABlock.Bounds) then
  begin
    if (fsUnderline in Font.Style) and FDrawContent then
      Render.DrawUnderline(ABlock.Bounds)
    else if FHasBackground then
      Render.FillBackground(ABlock.Bounds);
  end;
  Result := True;
end;

function TACLTextLayoutPainter.OnText(AText: TACLTextLayoutBlockText): Boolean;
begin
  if (AText.TextLengthVisible > 0) and FClipBox.IntersectsWith(AText.Bounds) then
  begin
    if FDrawContent then
      Render.DrawText(AText, AText.FPosition.X, AText.FPosition.Y)
    else if FHasBackground then
      Render.FillBackground(AText.Bounds);
  end;
  Result := AText.Position.Y < FClipBox.Bottom;
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

{ TACLTextLayoutShadowPainter }

constructor TACLTextLayoutShadowPainter.Create;
var
  LClipBox: TRect;
  LFont: TACLFont;
  LLayoutBox: TRect;
begin
  FTargetRender := ARender;
  LFont := AOwner.Font as TACLFont;
  LLayoutBox := AOwner.FRows.BoundingRect;
  LLayoutBox.Inflate(LFont.TextExtends);
  if ARender.GetClipBox(LClipBox) then
    LLayoutBox.Intersect(LClipBox);
  if LLayoutBox.IsEmpty then
    LLayoutBox.Size := TSize.Create(1);

  FOrigin := LLayoutBox.TopLeft;
  FBuffer := TACLDib.Create(LLayoutBox);
  inherited Create(AOwner, ARender.CreateCompatibleRender(FBuffer));
  FShadow := LFont.Shadow;
  FShadowDirection := TACLFontShadow.Offsets[FShadow.Direction];
  FShadowStroke := FShadowDirection = NullPoint;
  FShadowSize := FShadow.Size;
end;

destructor TACLTextLayoutShadowPainter.Destroy;
begin
  Render.Free; // end drawing
  if FBuffer <> nil then
  begin
    Text32ApplyBlur(FBuffer, FShadow);
    Text32RecoverAlpha(FBuffer, TACLPixel32.Create(FShadow.Color));
    FTargetRender.DrawImage(FBuffer, TRect.Create(FOrigin, FBuffer.Size));
    FBuffer.Free;
  end;
  inherited;
end;

procedure TACLTextLayoutShadowPainter.AfterConstruction;
begin
  inherited;
  Font.Color := clWhite;
  Render.SetFill(clNone);
end;

function TACLTextLayoutShadowPainter.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
var
  I, J: Integer;
begin
  if ABlock.TextWidth > 0 then
  begin
    if FShadowStroke then
    begin
      for I := -FShadowSize to FShadowSize do
      for J := -FShadowSize to FShadowSize do
        if I <> J then
          Render.DrawText(ABlock,
            ABlock.Position.X + I - FOrigin.X,
            ABlock.Position.Y + J - FOrigin.Y);
    end
    else
      for I := 1 to FShadowSize do
      begin
        Render.DrawText(ABlock,
          ABlock.Position.X + I * FShadowDirection.X - FOrigin.X,
          ABlock.Position.Y + I * FShadowDirection.Y - FOrigin.Y);
      end;
  end;
  Result := True;
end;

{$ENDREGION}

{$REGION ' Calculator '}

{ TACLTextLayoutCalculator }

constructor TACLTextLayoutCalculator.Create(AOwner: TACLTextLayout; ARender: TACLTextLayoutRender);
begin
  inherited;
  FRows := Owner.FRows;
  FRow := TACLTextLayoutRow.Create;
  FRow.FHead := PChar(AOwner.Text);
  FRow.FTail := FRow.FHead;
{$IFDEF ACL_TEXTLAYOUT_RTL}
  FRowRtlRanges := TACLListOf<TACLRange>.Create;
  FRowRtlRanges.Capacity := RtlRangeCapacity;
{$ENDIF}
  FEditControl := atoEditControl and Owner.Options <> 0;
  FEndEllipsis := atoEndEllipsis and Owner.Options <> 0;
  FSingleLine := atoSingleLine and Owner.Options <> 0;
  FWordWrap := (atoWordWrap and Owner.Options <> 0) and not FSingleLine;
  FCharBreak := (atoCharBreak and Owner.Options <> 0) and FWordWrap;

  FBounds := AOwner.Bounds;
  if Owner.Font is TACLFont then
    FBounds.Content(TACLFont(Owner.Font).TextExtends);
  FMaxLineCount := MaxInt;
  FMaxHeight := IfThen(atoAutoHeight and Owner.Options <> 0, MaxInt, FBounds.Height);
  FMaxWidth := IfThen(atoAutoWidth and Owner.Options <> 0, MaxInt, FBounds.Width);
end;

constructor TACLTextLayoutCalculator.CreateSpan(ACalculator: TACLTextLayoutCalculator);
begin
  inherited Create(ACalculator.Owner, ACalculator.Render);
  FRow := TACLTextLayoutRow.Create;
{$IFDEF ACL_TEXTLAYOUT_RTL}
  FRowRtlRanges := TACLListOf<TACLRange>.Create;
  FRowRtlRanges.Capacity := RtlRangeCapacity;
{$ENDIF}
  FMaxLineCount := MaxInt;
  FMaxHeight := MaxInt;
  FMaxWidth := MaxInt;
  CopyState(ACalculator);
  FontChanged(nil);
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
    if FRow.FHead = nil then
      FRow.FHead := ABlock.PositionInText;
    if ABlock.PositionInText <> nil then
      FRow.FTail := ABlock.PositionInText + ABlock.Length;
    if Baseline > FRow.Baseline then
      FRow.Baseline := Baseline;
    ABlock.FPosition := Point(FOrigin.X, FOrigin.Y + FRow.Baseline - Baseline);
    ABlock.FHeight := FLineHeight;
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
    if (FOrigin.X >= FMaxWidth) and not FCharBreak then
    begin
      TruncateRow;
      // В случае EndEllipsis = True, DrawText выравнивает обрезанный текст
      if FRowTruncated then
      begin
        // Если у нас только 1 строка и она кончилась - прерываем экспорт
        // В противом случае - продолжаем - может встретиться LineBreak-токен
        Exit(not FSingleLine);
      end;
    end;

  if FRowTruncated then
    Exit(True);

{$IFDEF ACL_TEXTLAYOUT_RTL}
  LReadingDirection := acGetReadingDirection(ABlock.FPositionInText, ABlock.FLength);
  if LReadingDirection = TACLTextReadingDirection.LeftToRight then
    FRowRtlRange := False
  else
    if FRowRtlRange then
      FRowRtlRanges.List[FRowRtlRanges.Count - 1].Finish := FRow.Count
    else
      if LReadingDirection = TACLTextReadingDirection.RightToLeft then
      begin
        FRowRtlRanges.Add(TACLRange.Create(FRow.Count, FRow.Count));
        FRowRtlRange := True;
      end;
{$ENDIF}

  Result := AddBlock(ABlock, AWidth);
  if (FOrigin.X > FMaxWidth) and not FCharBreak then
    TruncateRow;
end;

procedure TACLTextLayoutCalculator.AlignRows;
var
  LBoundingBox: TRect;
  LOffsetX: Integer;
  LOffsetY: Integer;
  LRight: Integer;
  LRow: TACLTextLayoutRow;
  I: Integer;
begin
  LBoundingBox := FRows.BoundingRect;

  LOffsetY := FBounds.Top;
  case Owner.VertAlignment of
    taAlignBottom:
      Inc(LOffsetY, Max(0, (FBounds.Height - LBoundingBox.Bottom)));
    taVerticalCenter:
      Inc(LOffsetY, Max(0, (FBounds.Height - LBoundingBox.Bottom) div 2));
  else;
  end;

  LRight := Max(FBounds.Width, LBoundingBox.Width);
  for I := 0 to FRows.Count - 1 do
  begin
    LRow := FRows.List[I];
    LOffsetX := FBounds.Left;
    case Owner.HorzAlignment of
      taRightJustify:
        Inc(LOffsetX, Max(0, (LRight - LRow.Bounds.Right)));
      taCenter:
        Inc(LOffsetX, Max(0, (LRight - LRow.Bounds.Right) div 2));
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
    FRow.Bounds := FRow.BoundingRect;
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
  if ABlock.Include then
  begin
    inherited;
    Result := AddBlock(ABlock);
  end
  else
  begin
    Result := AddBlock(ABlock);
    inherited;
  end;
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

function TACLTextLayoutCalculator.OnLineBreak(ABlock: TACLTextLayoutBlockLineBreak = nil): Boolean;
begin
  Result := False;
  if FRow <> nil then
  begin
    if ABlock <> nil then // hard break
      AddBlock(ABlock, IfThen(FSingleLine, SpaceWidth));
    if FSingleLine then
      Exit(True);
    if ABlock <> nil then // hard break
      FRow.FTail := ABlock.PositionInText;
    CompleteRow;
    Dec(FMaxLineCount);
    if (FOrigin.Y < FMaxHeight) and (FMaxLineCount > 0) then
    begin
      FRow := TACLTextLayoutRow.Create;
      if ABlock <> nil then // hard break
      begin
        FRow.FHead := ABlock.PositionInText + ABlock.Length;
        FRow.FTail := FRow.FHead;
      end;
      FRow.Bounds := Bounds(FOrigin.X, FOrigin.Y, 0, FLineHeight);
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
  FWordWrap := FCharBreak and (ABlock.Bounds.Width > FMaxWidth);
  Result := inherited;
  FWordWrap := True;
end;

function TACLTextLayoutCalculator.OnText(ABlock: TACLTextLayoutBlockText): Boolean;
begin
  if FRow = nil then
    Exit(False);

  if (ABlock.TextWidth = 0) or
     (ABlock.TextLengthVisible < ABlock.TextLength) // блок с EndEllipsis - метрики невалидны
  then
    Render.Measure(ABlock);

  Result := AddBlockOfContent(ABlock, ABlock.TextWidth);

  if FCharBreak and (ABlock.TextWidth > FMaxWidth) then
  begin
    ABlock.Shrink(Render, FMaxWidth);
    ABlock.FLengthVisible := Max(ABlock.FLengthVisible, 1);
    if (FRow <> nil) and (ABlock.TextLengthVisible < ABlock.TextLength) then
    begin
      FRow.FTail := ABlock.PositionInText + ABlock.TextLengthVisible;
      if OnLineBreak and (FRow <> nil) then
      begin
        FRow.SetCharBroken(TACLTextLayoutBlockText.Create(
          ABlock.Text + ABlock.TextLengthVisible,
          ABlock.TextLength - ABlock.TextLengthVisible));
        Result := OnText(FRow.CharBroken);
      end;
    end;
  end;
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

class function TACLTextImporter.AllocContext(
  const ASettings: TACLTextFormatSettings;
  AOutput: TACLTextLayoutBlockList): TContext;
var
  LIndex: Integer;
begin
  Result := TContext.Create;
  Result.Output := AOutput;
  Result.Span := TACLTextLayoutBlockList.Create(False);

{$REGION ' TokenDetectors '}
  SetLength(Result.TokenDetectors, 3 +
    Ord(ASettings.AllowAutoTimeCodeDetect) +
    Ord(ASettings.AllowCppLikeLineBreaks) +
    Ord(ASettings.AllowFormatting));

  LIndex := 0;
  if ASettings.AllowAutoTimeCodeDetect then
  begin
    Result.TokenDetectors[LIndex] := IsTimeCode; // до IsStyle
    Inc(LIndex);
  end;
  if ASettings.AllowFormatting then
  begin
    Result.TokenDetectors[LIndex] := IsStyle;
    Inc(LIndex);
  end;
  if ASettings.AllowCppLikeLineBreaks then
  begin
    Result.TokenDetectors[LIndex] := IsLineBreakCpp;
    Inc(LIndex);
  end;

  Result.TokenDetectors[LIndex] := IsLineBreak;
  Inc(LIndex);
  Result.TokenDetectors[LIndex] := IsSpace;
  Inc(LIndex);
  Result.TokenDetectors[LIndex] := IsText;
{$ENDREGION}

{$REGION ' TokenInTextDetectors '}
  LIndex := 0;
  SetLength(Result.TokenInTextDetectors,
    Ord(ASettings.AllowAutoEmailDetect) +
    Ord(ASettings.AllowAutoURLDetect));
  if ASettings.AllowAutoEmailDetect then
  begin
    Result.TokenInTextDetectors[LIndex] := IsEmail;
    Inc(LIndex);
  end;
  if ASettings.AllowAutoURLDetect then
    Result.TokenInTextDetectors[LIndex] := IsURL;
{$ENDREGION}
end;

class function TACLTextImporter.IsEmail(Ctx: TContext; S: PChar; L: Integer): Boolean;
begin
  Result := (acStrScan(S, L, '@') <> nil){fast check} and acIsEmail(S, L);
  if Result then
  begin
    Ctx.Output.AddSpan(Ctx.Span);
    Ctx.Output.Add(TACLTextLayoutBlockHyperlink.Create(acMailToPrefix + acMakeString(S, L), True));
    Ctx.Output.Add(TACLTextLayoutBlockText.Create(S, L));
    Ctx.Output.Add(TACLTextLayoutBlockHyperlink.Create(acEmptyStr, False));
  end;
end;

class function TACLTextImporter.IsLineBreak(
  Ctx: TContext; var Scan: PChar; ScanEnd: PChar): Boolean;
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
    Ctx.Output.AddInit(TACLTextLayoutBlockLineBreak.Create,
      Scan, 1 + Ord((Scan + 1 < ScanEnd) and ((Scan + 1)^ = #10)));
    Exit(True);
  end;
  Result := False;
end;

class function TACLTextImporter.IsLineBreakCpp(
  Ctx: TContext; var Scan: PChar; ScanEnd: PChar): Boolean;
begin
  Result := (Scan^ = '\') and (Scan + 1 < ScanEnd) and ((Scan + 1)^ = 'n');
  if Result then
  begin
    Ctx.Output.AddSpan(Ctx.Span);
    Ctx.Output.AddInit(TACLTextLayoutBlockLineBreak.Create, Scan, 2);
  end;
end;

class function TACLTextImporter.IsSpace(
  Ctx: TContext; var Scan: PChar; ScanEnd: PChar): Boolean;
begin
  Result := acContains(Scan^, Spaces);
  if Result then
  begin
    Ctx.Output.AddSpan(Ctx.Span);
    Ctx.Output.AddInit(TACLTextLayoutBlockSpace.Create, Scan, 1);
  end;
end;

class function TACLTextImporter.IsStyle(
  Ctx: TContext; var Scan: PChar; ScanEnd: PChar): Boolean;
var
  LBlock: TACLTextLayoutBlockStyle;
  LClosing: Boolean;
  LScanEnd: PChar;
  LScanParam: PChar;
  LScanTag: PChar;
  LTagLength: Integer;
begin
  Result := False;
  if Scan^ = '[' then
  begin
    LScanEnd := Scan + 1;
    while (LScanEnd < ScanEnd) and not acContains(LScanEnd^, StyleDelimiters) do
      Inc(LScanEnd);
    if LScanEnd = ScanEnd then
      Exit;
    if LScanEnd^ <> ']' then
      Exit;

    LScanTag := Scan + 1;
    LClosing := LScanTag^ = '/';
    if LClosing then
    begin
      LScanParam := LScanEnd;
      Inc(LScanTag);
    end
    else
    begin
      LScanParam := acStrScan(LScanTag, LScanEnd - Scan, '=');
      if LScanParam = nil then
        LScanParam := LScanEnd;
    end;

    LTagLength := LScanParam - LScanTag;
    if acCompareTokens('B', LScanTag, LTagLength) then
      LBlock := TACLTextLayoutBlockFontStyle.Create(TFontStyle.fsBold, not LClosing)
    else if acCompareTokens('U', LScanTag, LTagLength) then
      LBlock := TACLTextLayoutBlockFontStyle.Create(TFontStyle.fsUnderline, not LClosing)
    else if acCompareTokens('I', LScanTag, LTagLength) then
      LBlock := TACLTextLayoutBlockFontStyle.Create(TFontStyle.fsItalic, not LClosing)
    else if acCompareTokens('S', LScanTag, LTagLength) then
      LBlock := TACLTextLayoutBlockFontStyle.Create(TFontStyle.fsStrikeOut, not LClosing)
    else if acCompareTokens('COLOR', LScanTag, LTagLength) then
      LBlock := TACLTextLayoutBlockFontColor.Create(acMakeString(LScanParam + 1, LScanEnd), not LClosing)
    else if acCompareTokens('BACKCOLOR', LScanTag, LTagLength) then
      LBlock := TACLTextLayoutBlockFillColor.Create(acMakeString(LScanParam + 1, LScanEnd), not LClosing)
    else if acCompareTokens('BIG', LScanTag, LTagLength) then
      LBlock := TACLTextLayoutBlockFontSize.Create(FontScalingBig, not LClosing)
    else if acCompareTokens('SMALL', LScanTag, LTagLength) then
      LBlock := TACLTextLayoutBlockFontSize.Create(FontScalingSmall, not LClosing)
    else if acCompareTokens('SIZE', LScanTag, LTagLength) then
      LBlock := TACLTextLayoutBlockFontSize.Create(acMakeString(LScanParam + 1, LScanEnd), not LClosing)
    else if acCompareTokens('URL', LScanTag, LTagLength) then
      LBlock := TACLTextLayoutBlockHyperlink.Create(acMakeString(LScanParam + 1, LScanEnd), not LClosing)
    else
      LBlock := nil;

    Result := LBlock <> nil;
    if Result then
    begin
      Inc(LScanEnd);
      if LBlock.ClassType = TACLTextLayoutBlockHyperlink then
      begin
        if LClosing then
          Dec(Ctx.HyperlinkDepth)
        else
          Inc(Ctx.HyperlinkDepth);
      end;
      Ctx.Span.AddInit(LBlock, Scan, acStringLength(Scan, LScanEnd));
    end;
  end;
end;

class function TACLTextImporter.IsText(
  Ctx: TContext; var Scan: PChar; ScanEnd: PChar): Boolean;
var
  I: Integer;
  LCursor: PChar;
  LLength: Integer;
begin
  Result := True;

  LCursor := Scan;
  while (LCursor < ScanEnd) and not acContains(LCursor^, Delimiters) do
    Inc(LCursor);

  LLength := acStringLength(Scan, LCursor);
  if LLength > 0 then
  begin
    if Ctx.HyperlinkDepth < 1 then
      for I := Low(Ctx.TokenInTextDetectors) to High(Ctx.TokenInTextDetectors) do
      begin
        if Ctx.TokenInTextDetectors[I](Ctx, Scan, LLength) then
        begin
          Inc(Scan, LLength);
          Exit;
        end;
      end;
    Ctx.Span.AddInit(TACLTextLayoutBlockText.Create(Scan, LLength), Scan, LLength);
  end
  else
    if LCursor < ScanEnd then // Delimiter
    begin
      Ctx.Output.AddSpan(Ctx.Span);
      Ctx.Output.AddInit(TACLTextLayoutBlockText.Create(Scan, 1), Scan, 1);
    end;
end;

class function TACLTextImporter.IsTimeCode(Ctx: TContext; var Scan: PChar; ScanEnd: PChar): Boolean;
var
  LScan: PChar;
  LTime: Single;
begin
  LScan := Scan;
  Result := TACLTimeFormat.Parse(LScan, ScanEnd, LTime);
  if Result then
  begin
    Ctx.Output.Add(TACLTextLayoutBlockHyperlink.Create(
      TACLTextLayout.TimeCodePrefix + IntToStr(Trunc(LTime)), True));
    Ctx.Output.Add(TACLTextLayoutBlockText.Create(Scan, LScan - Scan));
    Ctx.Output.Add(TACLTextLayoutBlockHyperlink.Create(acEmptyStr, False));
    Scan := LScan;
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

{ TACLTextImporter.TContext }

destructor TACLTextImporter.TContext.Destroy;
begin
  FreeAndNil(Span);
  inherited;
end;

procedure TACLTextImporter.TContext.Run(Scan: PChar; Length: Integer);
var
  I: Integer;
  LScanEnd: PChar;
  LTokens: Integer;
begin
  LScanEnd := Scan + Length;
  LTokens := System.Length(TokenDetectors);
  while Scan < LScanEnd do
  begin
    for I := 0 to LTokens - 1 do
    begin
      if TokenDetectors[I](Self, Scan, LScanEnd) then
        Break;
    end;
  end;
  Output.AddSpan(Span);
end;
{$ENDREGION}

{$REGION ' Native Render '}

{ TACLTextLayoutCanvasRender }

constructor TACLTextLayoutCanvasRender.Create(ACanvas: TCanvas);
begin
  FCanvas := ACanvas;
  inherited Create;
end;

function TACLTextLayoutCanvasRender.CreateCompatibleRender(ADib: TACLDib): TACLTextLayoutRender;
begin
  Result := TACLTextLayoutCanvasRenderClass(ClassType).Create(ADib.Canvas);
end;

procedure TACLTextLayoutCanvasRender.DrawImage(ADib: TACLDib; const R: TRect);
begin
  ADib.DrawBlend(Canvas, R);
end;

procedure TACLTextLayoutCanvasRender.DrawText(ABlock: TACLTextLayoutBlockText; X, Y: Integer);
begin
  ExtTextOut(FCanvas.Handle, X, Y, 0, nil,
    ABlock.Text, ABlock.TextLengthVisible,
    @PIntegerArray(ABlock.FMetrics)^[1]);
end;

procedure TACLTextLayoutCanvasRender.DrawUnderline(const R: TRect);
var
  LRect: TRect;
  LSize: Integer;
begin
  LRect := R;
  LSize := R.Width;
  ExtTextOut(FCanvas.Handle, LRect.Left, LRect.Top, ETO_CLIPPED, @LRect, ' ', 1, @LSize);
end;

procedure TACLTextLayoutCanvasRender.FillBackground(const R: TRect);
begin
  if Canvas.Brush.Style <> bsClear then
    Canvas.FillRect(R);
end;

class function TACLTextLayoutCanvasRender.GetChar(
  ABlock: TACLTextLayoutBlockText; var AOffset: Integer): PChar;
var
  I: Integer;
  LLeft: Integer;
  LMetrics: PIntegerArray;
  LScan: PInteger;
begin
  Result := ABlock.Text;
  LMetrics := ABlock.FMetrics;
  if LMetrics <> nil then
  begin
    LLeft := AOffset;
    LScan := @LMetrics^[1];
    for I := 1 to LMetrics^[0] do
    begin
      if LLeft < LScan^ div 2 then
      begin
      {$IFDEF UNICODE}
        if not Result^.IsLowSurrogate then
      {$ENDIF}
          Break;
      end;
    {$IFDEF UNICODE}
      Inc(Result);
    {$ELSE}
      Inc(Result, acUtf8CharLength(Result));
    {$ENDIF}
      Dec(LLeft, LScan^);
      Inc(LScan);
    end;
    Dec(AOffset, LLeft);
  end;
end;

class function TACLTextLayoutCanvasRender.GetCharPos(
  ABlock: TACLTextLayoutBlock; AOffset: Integer): TRect;
var
  LCount: Integer;
  LMetrics: PIntegerArray;
  LText: PChar;
  LWidth: PInteger;
{$IFNDEF UNICODE}
  LCharLen: Integer;
{$ENDIF}
begin
  Result := ABlock.Bounds;
  if ABlock is TACLTextLayoutBlockText then
  begin
    LMetrics := TACLTextLayoutBlockText(ABlock).FMetrics;
    if LMetrics <> nil then
    begin
      LCount :=  LMetrics^[0]; // count
      LWidth := @LMetrics^[1]; // array of widths
      LText  := ABlock.PositionInText;
      while (AOffset > 0) and (LCount > 0) do
      begin
      {$IFDEF UNICODE}
        Dec(AOffset);
        Inc(LText);
      {$ELSE}
        LCharLen := acUtf8CharLength(LText);
        Dec(AOffset, LCharLen);
        Inc(LText, LCharLen);
      {$ENDIF}
        Inc(Result.Left, LWidth^);
        Dec(LCount);
        Inc(LWidth);
      end;
      if LCount > 0 then // а это возможно?!
      begin
        Result.Width := LWidth^;
      {$IFDEF UNICODE}
        if LText^.IsLowSurrogate then
          Result.Left := Result.Right
        else
          if LText^.IsHighSurrogate then
          begin
            Inc(LWidth);
            Inc(Result.Right, LWidth^);
          end;
      {$ENDIF}
      end;
    end;
  end;
end;

function TACLTextLayoutCanvasRender.GetClipBox(out R: TRect): Boolean;
begin
{$IFDEF FPC}
  Result := LCLIntf.GetClipBox(Canvas.Handle, @R) >= NULLREGION;
{$ELSE}
  Result := Windows.GetClipBox(Canvas.Handle,  R) >= NULLREGION;
{$ENDIF}
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
  LWidth    := @PIntegerArray(ABlock.FMetrics)^[1];
  for I := 0 to PIntegerArray(ABlock.FMetrics)^[0] - 1 do
  begin
    Dec(LWidth^, LDistance);
    Inc(LDistance, LWidth^);
    Inc(LWidth);
  end;
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
  FCanvas.SetScaledFont(AFont);
end;

class procedure TACLTextLayoutCanvasRender.Shrink(ABlock: TACLTextLayoutBlockText; AMaxSize: Integer);
var
  LCharCount: PInteger;
  LCharWidth: PInteger;
  LMetrics: PIntegerArray;
  LWidth: Integer;
begin
  LMetrics := PIntegerArray(ABlock.FMetrics);
  LCharCount := @LMetrics^[0];
  LCharWidth := @LMetrics^[1 + LCharCount^ - 1];
  LWidth := ABlock.FWidth;
  while LCharCount^ > 0 do
  begin
    Dec(LWidth, LCharWidth^);
    Dec(LCharCount^);
    if LWidth <= AMaxSize then Break;
    Dec(LCharWidth);
  end;
  ABlock.FWidth := Max(LWidth, 0);
{$IFDEF UNICODE}
  ABlock.FLengthVisible := LCharCount^;
{$ELSE}
  ABlock.FLengthVisible := UTF8CodepointToByteIndex(ABlock.Text, ABlock.TextLength, LCharCount^);
{$ENDIF}
end;

{ TACLTextLayoutCanvasRender32 }

destructor TACLTextLayoutCanvasRender32.Destroy;
begin
  FreeAndNil(FFont);
  inherited;
end;

procedure TACLTextLayoutCanvasRender32.DrawText(
  ABlock: TACLTextLayoutBlockText; X, Y: Integer);
begin
  DrawText32Core(ABlock.Text, ABlock.TextLength,
    ABlock.FWidth, ABlock.FHeight, FFont, NullPoint, 0,
    procedure (ABuffer: TACLDib)
    begin
      ABuffer.DrawBlend(Canvas, Point(X, Y));
    end);
end;

procedure TACLTextLayoutCanvasRender32.DrawUnderline(const R: TRect);
begin
  DrawText32Core(' ', 1, R.Width, R.Height, FFont, NullPoint, 0,
    procedure (ABuffer: TACLDib)
    begin
      ABuffer.DrawBlend(Canvas, R.TopLeft);
    end);
end;

procedure TACLTextLayoutCanvasRender32.FillBackground(const R: TRect);
begin
  if Canvas.Brush.Style = bsSolid then
    acFillRect(Canvas, R, TAlphaColor.FromColor(Canvas.Brush.Color));
end;

procedure TACLTextLayoutCanvasRender32.SetFont(AFont: TFont);
begin
  if FFont = nil then
    FFont := TACLFont.Create;
  inherited;
  FFont.Assign(AFont);
  FFont.Shadow.Reset;
end;

{$ENDREGION}

{$REGION ' TextLayout '}

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

class operator TACLTextFormatSettings.Equal(const V1, V2: TACLTextFormatSettings): Boolean;
begin
  Result :=
    (V1.AllowAutoEmailDetect = V2.AllowAutoEmailDetect) and
    (V1.AllowAutoTimeCodeDetect = V2.AllowAutoTimeCodeDetect) and
    (V1.AllowCppLikeLineBreaks = V2.AllowCppLikeLineBreaks) and
    (V1.AllowAutoURLDetect = V2.AllowAutoURLDetect) and
    (V1.AllowFormatting = V2.AllowFormatting);
end;

class operator TACLTextFormatSettings.NotEqual(const V1, V2: TACLTextFormatSettings): Boolean;
begin
  Result := not (V1 = V2);
end;

{ TACLTextLayout }

constructor TACLTextLayout.Create(AFont: TFont);
begin
  FFont := AFont;
  FTargetDpi := FFont.PixelsPerInch;
  FBlocks := TACLTextLayoutBlockList.Create;
  FRows := TACLTextLayoutRows.Create;
end;

destructor TACLTextLayout.Destroy;
begin
  FreeAndNil(FBlocks);
  FreeAndNil(FRows);
  inherited;
end;

procedure TACLTextLayout.Calculate(ACanvas: TCanvas);
var
  LRender: TACLTextLayoutRender;
begin
  if FRowsDirty then
  begin
    LRender := GetDefaultRender.Create(ACanvas);
    try
      Calculate(LRender);
    finally
      LRender.Free;
    end;
  end;
end;

procedure TACLTextLayout.Calculate(ARender: TACLTextLayoutRender);
begin
  if FRowsDirty then
  begin
    FTruncated := False;
    FRows.Count := 0;
    FRowsDirty := False;
    if FBlocks.Count > 0 then
      FBlocks.Export(TACLTextLayoutCalculator.Create(Self, ARender), True);
  end;
end;

procedure TACLTextLayout.FlushCalculatedValues;
var
  I: Integer;
begin
  for I := 0 to FBlocks.Count - 1 do
    FBlocks.List[I].FlushCalculatedValues;
  FRowsDirty := True;
end;

procedure TACLTextLayout.Draw(ACanvas: TCanvas);
var
  LRender: TACLTextLayoutRender;
begin
  if Options and atoNoClip <> 0 then
  begin
    LRender := GetDefaultRender.Create(ACanvas);
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
  LClipRegion: TRegionHandle;
  LRender: TACLTextLayoutRender;
begin
  if acStartClippedDraw(ACanvas, AClipRect, LClipRegion) then
  try
    LRender := GetDefaultRender.Create(ACanvas);
    try
      Draw(LRender);
    finally
      LRender.Free;
    end;
  finally
    acEndClippedDraw(ACanvas, LClipRegion);
  end;
end;

procedure TACLTextLayout.Draw(ARender: TACLTextLayoutRender);
begin
  Calculate(ARender);
  if (Font is TACLFont) and TACLFont(Font).Shadow.Assigned then
  begin
    FRows.Export(TACLTextLayoutPainter.CreateEx(Self, ARender, True, False), True);
    FRows.Export(TACLTextLayoutShadowPainter.Create(Self, ARender), True);
    FRows.Export(TACLTextLayoutPainter.CreateEx(Self, ARender, False, True), True);
  end
  else
    FRows.Export(TACLTextLayoutPainter.Create(Self, ARender), True);
end;

procedure TACLTextLayout.DrawTo(ACanvas: TCanvas; const AClipRect: TRect; const AOrigin: TPoint);
var
  LOrigin: TPoint;
begin
  if AOrigin <> NullPoint then
  begin
    LOrigin := acMoveWindowOrg(ACanvas.Handle, AOrigin);
    try
      Draw(ACanvas, AClipRect - AOrigin);
    finally
      acRestoreWindowOrg(ACanvas.Handle, LOrigin);
    end;
  end
  else
    Draw(ACanvas, AClipRect);
end;

function TACLTextLayout.FindBlock(APositionInText: Integer;
  out ABlock: TACLTextLayoutBlock; AVisible: Boolean = True): Boolean;
var
  I: Integer;
  LGoal: PChar;
  LRow: TACLTextLayoutRow;
begin
  Result := False;
  if InRange(APositionInText, 0, Length(FText) - 1) then
  begin
    LGoal := PChar(FText) + APositionInText;
    if not AVisible then
      Result := FBlocks.Find(LGoal, ABlock)
    else
      for I := 0 to FRows.Count - 1 do
      begin
        LRow := FRows.List[I];
        if (LGoal >= LRow.PositionInText) and
           (LGoal <  LRow.LineEndPosition(True)) and
           (LRow.Find(LGoal, ABlock))
        then
          Exit(True);
      end;
  end;
end;

function TACLTextLayout.FindCharBounds(
  APositionInText: Integer; out ABounds: TRect): Boolean;
var
  LBlock: TACLTextLayoutBlock;
begin
  Result := FindBlock(APositionInText, LBlock);
  if Result then
  begin
    ABounds := GetDefaultRender.GetCharPos(LBlock,
      PChar(FText) + APositionInText - LBlock.PositionInText);
  end;
end;

function TACLTextLayout.FindHyperlink(const P: TPoint;
  out AHyperlink: TACLTextLayoutBlockHyperlink): Boolean;
var
  LHitTest: TACLTextLayoutHitTest;
begin
  LHitTest := TACLTextLayoutHitTest.Create(Self);
  try
    LHitTest.Calculate(P);
    Result := LHitTest.Hyperlink <> nil;
    if Result then
      AHyperlink := LHitTest.Hyperlink;
  finally
    LHitTest.Free;
  end;
end;

function TACLTextLayout.GetDefaultHyperLinkColor: TColor;
var
  H, S, L: Byte;
begin
  Result := GetDefaultTextColor;
  TACLColors.RGBtoHSLi(Result, H, S, L);
  Result := TACLColors.HSLtoRGBi(154, Max(S, 154), EnsureRange(L, 100, 200));
end;

function TACLTextLayout.GetDefaultRender: TACLTextLayoutCanvasRenderClass;
begin
  Result := DefaultTextLayoutCanvasRender;
end;

function TACLTextLayout.GetDefaultTextColor: TColor;
begin
  Result := Font.Color;
end;

function TACLTextLayout.GetRowCount: Integer;
begin
  if FRowsDirty then
    raise EInvalidOperation.Create(ClassName + ' is not yet calculated');
  Result := FRows.Count;
end;

function TACLTextLayout.GetRowIndex(ABlock: TACLTextLayoutBlock): Integer;
var
  I: Integer;
begin
  for I := 0 to RowCount - 1 do
  begin
    if FRows[I].Contains(ABlock) then
      Exit(I);
  end;
  Result := -1;
end;

function TACLTextLayout.MeasureSize: TSize;
begin
  if FRowsDirty then
    raise EInvalidOperation.Create(ClassName + ' is not yet calculated');
  Result := FRows.BoundingRect.Size;
  if not Result.IsEmpty and (Font is TACLFont) then
    Result := TACLFont(Font).AppendTextExtends(Result)
end;

procedure TACLTextLayout.SetBounds(const ABounds: TRect);
begin
  if FBounds <> ABounds then
  begin
    FBounds := ABounds;
    FRowsDirty := True;
  end;
end;

procedure TACLTextLayout.SetHorzAlignment(AValue: TAlignment);
begin
  if FHorzAlignment <> AValue then
  begin
    FHorzAlignment := AValue;
    FRowsDirty := True;
  end;
end;

procedure TACLTextLayout.SetVertAlignment(AValue: TVerticalAlignment);
begin
  if FVertAlignment <> AValue then
  begin
    FVertAlignment := AValue;
    FRowsDirty := True;
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
    FRowsDirty := True;
  end;
end;

procedure TACLTextLayout.ReplaceText(AStart, ALength: Integer;
  const ANewText: string; const ASettings: TACLTextFormatSettings);
var
  LNewBlocks: TACLTextLayoutBlockList;
  LOffset: Integer;
  LOldBase: PChar;
  LStart: TACLTextLayoutBlock;
  LStartIndex: Integer;
  LStop: TACLTextLayoutBlock;
  LStopIndex: Integer;
  I: Integer;
begin
{$REGION ' Optimized Replace '}
  if FindBlock(Max(0, AStart - 1), LStart, False) and
     FindBlock(AStart + ALength, LStop, False) then
  begin
    LStartIndex := FBlocks.IndexOf(LStart);
    LStopIndex := FBlocks.IndexOf(LStop);
    if (LStartIndex < 0) or (LStopIndex < 0) then
      raise EInvalidOperation.Create(ClassName + ': bad indexes in ReplaceText');

    LNewBlocks := TACLTextLayoutBlockList.Create(False);
    try
      LNewBlocks.Capacity := LStopIndex - LStartIndex + 2;

      LOldBase := PChar(Text);
      LOffset := Length(ANewText) - ALength;
      FText :=
        Copy(Text, 1,  AStart) + ANewText +
        Copy(Text, 1 + AStart + ALength);

      with TACLTextImporter.AllocContext(ASettings, LNewBlocks) do
      try
        Run(// пропускаем текст до стартового блока
          PChar(FText) + (LStart.PositionInText - LOldBase),
          // парсим диапазон, включающий в себя новый текст + содержимое start/stop блоков
          LStop.PositionInText + LStop.Length - LStart.PositionInText + LOffset);
      finally
        Free;
      end;

      // Удаляем старые блоки
      FRowsDirty := True;
      FRows.Clear;
      while LStartIndex <= LStopIndex do
      begin
        FBlocks.Delete(LStartIndex);
        Dec(LStopIndex);
      end;
      // Актуализируем референсы
      FBlocks.Rebase(LOldBase, PChar(FText));
      if LOffset <> 0 then
      begin
        for I := LStartIndex to FBlocks.Count - 1 do
          Inc(FBlocks.List[I].FPositionInText, LOffset);
      end;
      // Вставка новых блоков
      for I := 0 to LNewBlocks.Count - 1 do
        FBlocks.Insert(LStartIndex + I, LNewBlocks.List[I]);
    finally
      LNewBlocks.Free;
    end;
  end
  else
{$ENDREGION}
    SetText(
      Copy(Text, 1,  AStart) + ANewText +
      Copy(Text, 1 + AStart + ALength), ASettings);
end;

procedure TACLTextLayout.SetText(const AText: string; const ASettings: TACLTextFormatSettings);
begin
  FRowsDirty := True;
  FRows.Clear;
  FBlocks.Clear;
  FText := AText;

  with TACLTextImporter.AllocContext(ASettings, FBlocks) do
  try
    Run(PChar(FText), Length(FText));
  finally
    Free;
  end;
end;

function TACLTextLayout.ToString: string;
begin
  if FRowsDirty then
    Result := ''
  else
    Result := FRows.ToString;
end;

function TACLTextLayout.ToStringEx(ExporterClass: TACLPlainTextExporterClass): string;
var
  LExporter: TACLPlainTextExporter;
begin
  LExporter := ExporterClass.Create(Self);
  try
    FBlocks.Export(LExporter, False);
    Result := LExporter.ToString;
  finally
    LExporter.Free;
  end;
end;

{ TACLTextLayout32 }

function TACLTextLayout32.GetDefaultRender: TACLTextLayoutCanvasRenderClass;
begin
{$IFDEF ACL_CAIRO_TEXTOUT}
  Result := TACLTextLayoutCairoRender; // Cairo is already alpha-channel aware
{$ELSE}
  Result := TACLTextLayoutCanvasRender32;
{$ENDIF}
end;

{ TACLTextViewInfo }

constructor TACLTextViewInfo.Create(const AText: string);
begin
  FText := AText;
  inherited Create(PChar(FText), System.Length(FText));
end;

function TACLTextViewInfo.Measure(ARender: TACLTextLayoutRender): TSize;
begin
  ARender.Measure(Self);
  Result.cx := FWidth;
  Result.cy := FHeight;
end;

{$ENDREGION}

initialization

finalization
  FreeAndNil(FTextBuffer);
  FreeAndNil(FTextBlur);
end.
