////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Skinned Image
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Graphics.SkinImage;

{$I ACL.Config.inc}
{$MINENUMSIZE 1}

{$IFNDEF FPC}
  {$DEFINE ACL_SKINIMAGE_CACHE_HBITMAP}
{$ENDIF}
{.$DEFINE ACL_SKINIMAGE_COLLECT_STATS}

interface

uses
{$IFDEF ACL_CAIRO}
  Cairo,
{$ENDIF}
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  {System.}ZLib,
{$IFDEF FPC}
  {System.}Zstream,
{$ENDIF}
  System.UITypes,
  // VCL
  {Vcl.}Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.ByteBuffer,
  ACL.Classes.Collections,
  ACL.Hashes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Images,
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

const
  sErrorCannotCreateImage = 'Cannot create image handle (%d x %d)';
  sErrorIncorrectDormantData = 'Dormant data has been corrupted';

type
  EACLSkinImageException = class(Exception);
  TACLSkinImageLayout = (ilHorizontal, ilVertical);

  TACLSkinImageBitsState = (ibsUnpremultiplied, ibsPremultiplied);
  TACLSkinImageHitTestMode = (ihtmOpaque, ihtmMask, ihtmTransparent);
  TACLSkinImageSizingMode = (ismDefault, ismMargins, ismTiledAreas);

  { Fixed | Tiled | Center | Tiled | Fixed }

  TACLSkinImageTiledAreasMode = (tpmHorizontal, tpmVertical);
  TACLSkinImageTiledAreasPart = (tpzPart1Fixed, tpzPart1Tile, tpzCenter, tpzPart2Tile, tpzPart2Fixed);
  TACLSkinImageTiledAreasPartBounds = array[TACLSkinImageTiledAreasPart] of TRect;

  PACLSkinImageTiledAreas = ^TACLSkinImageTiledAreas;
  TACLSkinImageTiledAreas = packed record
    Part1TileStart: Integer;
    Part1TileWidth: Integer;
    Part2TileStart: Integer;
    Part2TileWidth: Integer;

    class function FromRect(const R: TRect): TACLSkinImageTiledAreas; static;
    function Compare(const P: TACLSkinImageTiledAreas): Boolean;
    function IsEmpty: Boolean;
    function ToRect: TRect;
  end;

  { TACLSkinImageHeader }

  TACLSkinImageHeader = packed record
    ID: array[0..7] of AnsiChar;
    Version: Integer;
  end;

  { TACLSkinImageFrameState }

  TACLSkinImageFrameState = type DWORD;
  TACLSkinImageFrameStateArray = array of TACLSkinImageFrameState;
  TACLSkinImageFrameStateHelper = record helper for TACLSkinImageFrameState
  public const
    TRANSPARENT = 0;
    SEMITRANSPARENT = 1;
    OPAQUE = 2;
  public
    function IsColor: Boolean; inline;
    function IsOpaque: Boolean; inline;
    function IsTransparent: Boolean; inline;
  end;

  { TACLSkinFrameDormantData }

  TACLSkinFrameDormantData = class
  public
    Data: Pointer;
    DataSize: Cardinal;

    constructor CopyOf(ASource: TACLSkinFrameDormantData);
    constructor Create(ABits: PACLPixel32;
      ACount: Integer; APreferBufferSize: Cardinal); overload;
    constructor Create(AStream: TStream); overload;
    destructor Destroy; override;
    function Equals(Obj: TObject): Boolean; override;
    function GetHashCode: TObjHashCode; override;
    procedure Restore(ABits: PACLPixel32; ACount: Integer);
    procedure SaveToStream(AStream: TStream);
  end;

  { TACLSkinImage }

  TACLSkinImage = class(TACLUnknownPersistent, IACLColorSchema)
  strict private const
  {$REGION ' Private consts '}
    CHUNK_BITS      = $73746962; // bits
    CHUNK_BITZ      = $7A746962; // bitz - compressed bits
    CHUNK_DRAW      = $77617264; // draw
    CHUNK_FRAME     = $6D617266; // fram
    CHUNK_FRAMEINFO = $6D616669; // frmi
    CHUNK_LAYOUT    = $7479616C; // layt

    FLAGS_BITS_HASALPHA = $1;
    FLAGS_BITS_PREPARED = $2;

    FLAGS_DRAW_ALLOWCOLORATION      = $1;
    FLAGS_DRAW_SIZING_BY_MARGINS    = $2;
    FLAGS_DRAW_SIZING_BY_TILEDAREAS = $4;
  {$ENDREGION}
  public const
    CompressionThreshold = 256; // 16x16
    HitTestThreshold = 128;
  strict private
  {$IFDEF ACL_SKINIMAGE_CACHE_HBITMAP}
    FHandle: HBITMAP;
  {$ENDIF}
  private
    FFrameInfoContent: TACLSkinImageFrameStateArray;
  strict private
    FAllowColoration: Boolean;
    FBitCount: Integer;
    FBits: PACLPixel32;
    FBitsState: TACLSkinImageBitsState;
    FContentOffsets: TRect;
    FDormantData: TACLSkinFrameDormantData;
    FDormantPreferSize: Cardinal;
    FFrameCount: Integer;
    FFrameInfo: TACLSkinImageFrameStateArray;
    FFrameInfoIsValid: Boolean;
    FHasAlpha: TACLBoolean;
    FHeight: Integer;
    FHitTestMask: TACLSkinImageHitTestMode;
    FHitTestMaskFrameIndex: Integer;
    FLayout: TACLSkinImageLayout;
    FLoading: Boolean;
    FMargins: TRect;
    FSizingMode: TACLSkinImageSizingMode;
    FStretchMode: TACLStretchMode;
    FTiledAreas: TACLSkinImageTiledAreas;
    FTiledAreasMode: TACLSkinImageTiledAreasMode;
    FUpdateCount: Integer;
    FWidth: Integer;

    procedure CheckUnpacked;
    function CompressData: TACLSkinFrameDormantData;
    function GetActualSizingMode: TACLSkinImageSizingMode; inline;
    function GetClientRect: TRect; inline;
    function GetEmpty: Boolean; inline;
    function GetFrameHeight: Integer; inline;
    function GetFrameInfo(Index: Integer): TACLSkinImageFrameState;
    function GetFrameRect(Index: Integer): TRect;
    function GetFrameSize: TSize; inline;
    function GetFrameWidth: Integer; inline;
    function GetHasAlpha: Boolean;
    procedure SetAllowColoration(const Value: Boolean);
    procedure SetContentOffsets(const Value: TRect);
    procedure SetFrameCount(AValue: Integer);
    procedure SetFrameSize(const AValue: TSize);
    procedure SetHitTestMask(const Value: TACLSkinImageHitTestMode);
    procedure SetHitTestMaskFrameIndex(const Value: Integer);
    procedure SetLayout(AValue: TACLSkinImageLayout);
    procedure SetMargins(const Value: TRect);
    procedure SetSizingMode(const Value: TACLSkinImageSizingMode);
    procedure SetStretchMode(const Value: TACLStretchMode);
    procedure SetTiledAreas(const Value: TACLSkinImageTiledAreas);
    procedure SetTiledAreasMode(const Value: TACLSkinImageTiledAreasMode);

    procedure ReadChunkBits(AStream: TStream; ASize: Integer);
    procedure ReadChunkBitz(AStream: TStream; ASize: Integer);
    procedure ReadChunkDraw(AStream: TStream);
    procedure ReadChunkFrameInfo(AStream: TStream; ASize: Integer);
    procedure ReadChunkLayout(AStream: TStream);
    procedure WriteChunkBits(AStream: TStream; var AChunkCount: Integer);
    procedure WriteChunkDraw(AStream: TStream; var AChunkCount: Integer);
    procedure WriteChunkFrameInfo(AStream: TStream; var AChunkCount: Integer);
    procedure WriteChunkLayout(AStream: TStream; var AChunkCount: Integer);

    procedure ReleaseHandle;
  protected
    FChangeListeners: TACLListOf<TNotifyEvent>;

    procedure BitsNeeded(AState: TACLSkinImageBitsState);
    procedure Changed;
    procedure CheckFrameIndex(var AIndex: Integer); inline;
    procedure CheckFramesInfo;
    procedure ClearData; virtual;
    procedure UnpackFrame(ATarget: PACLPixel32; AFrame, ATargetStride: Integer);

    procedure DoAssign(AObject: TObject); virtual;
    procedure DoAssignParams(ASkinImage: TACLSkinImage); virtual;
    procedure DoCreateBits(AWidth, AHeight: Integer);
    procedure DoSetSize(AWidth, AHeight: Integer);

    // Read
    procedure ReadChunk(AStream: TStream; AChunkID, AChunkSize: Integer); virtual;
    procedure ReadFormatChunked(AStream: TStream);
    procedure ReadFormatObsolette(AStream: TStream; AVersion: Integer);
    // Write
    procedure WriteChunks(AStream: TStream; var AChunkCount: Integer); virtual;

    property BitCount: Integer read FBitCount;
    property Bits: PACLPixel32 read FBits;
    property BitsState: TACLSkinImageBitsState read FBitsState;
  {$IFDEF ACL_SKINIMAGE_CACHE_HBITMAP}
    property Handle: HBITMAP read FHandle;
  {$ENDIF}
  public
    constructor Create; overload; virtual;
    constructor Create(AChangeEvent: TNotifyEvent); overload;
    destructor Destroy; override;
    procedure Assign(AObject: TObject); reintroduce;
    procedure AssignParams(ASkinImage: TACLSkinImage);
    procedure Clear;
    procedure Dormant; virtual;
    function Equals(Obj: TObject): Boolean; override;
    function GetHashCode: TObjHashCode; override;
    function HasFrame(AIndex: Integer): Boolean; inline;
    procedure Optimize;
    procedure SwapLayout;
    // Lock
    procedure BeginUpdate;
    procedure CancelUpdate;
    procedure EndUpdate;
    // IACLColorSchema
    procedure ApplyColorSchema(const AValue: TACLColorSchema);
    procedure ApplyTint(const AColor: TACLPixel32);
    // Drawing
  {$IFDEF ACL_CAIRO}
    procedure Draw(ACairo: Pcairo_t; ARect: TRect;
      AFrameIndex: Integer = 0; AAlpha: Byte = MaxByte); overload;
  {$ENDIF}
    procedure Draw(ACanvas: TCanvas; ARect: TRect;
      AFrameIndex: Integer = 0; AAlpha: Byte = MaxByte); overload;
    procedure Draw(ACanvas: TCanvas; const R: TRect;
      AFrameIndex: Integer; AEnabled: Boolean; AAlpha: Byte = MaxByte); overload;
    // HitTest
    function HitTest(const ABounds: TRect; X, Y: Integer): Boolean;
    function HitTestEx(const ABounds: TRect; X, Y, AMaskFrameIndex: Integer;
      AMaskSensivity: Integer = HitTestThreshold; APixel: PACLPixel32 = nil): Boolean;
    // Listeners
    procedure ListenerAdd(AEvent: TNotifyEvent);
    procedure ListenerRemove(AEvent: TNotifyEvent);
    // I/O
    procedure LoadFromBitmap(ABitmap: TACLDib); overload;
    procedure LoadFromBitmap(ABitmap: TBitmap); overload;
    procedure LoadFromBits(ABits: PACLPixel32; AWidth, AHeight: Integer);
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromResource(AInstance: HINST; const AName: string; AResRoot: PChar);
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToBitmap(ABitmap: TACLDib); overload;
    procedure SaveToBitmap(ABitmap: TBitmap); overload;
    procedure SaveToFile(const AFileName: string); overload;
    procedure SaveToFile(const AFileName: string; AFormat: TACLImageFormatClass); overload;
    procedure SaveToImage(AImage: TACLImage);
    procedure SaveToStream(AStream: TStream); overload; virtual;
    procedure SaveToStream(AStream: TStream; AFormat: TACLImageFormatClass); overload;
    //# Sizes
    property ActualSizingMode: TACLSkinImageSizingMode read GetActualSizingMode;
    property ClientRect: TRect read GetClientRect;
    property Empty: Boolean read GetEmpty;
    property HasAlpha: Boolean read GetHasAlpha;
    property Height: Integer read FHeight;
    property Width: Integer read FWidth;
    //# Frames
    property FrameCount: Integer read FFrameCount write SetFrameCount;
    property FrameInfo[Index: Integer]: TACLSkinImageFrameState read GetFrameInfo;
    property FrameRect[Index: Integer]: TRect read GetFrameRect;
    property FrameSize: TSize read GetFrameSize write SetFrameSize;
    property FrameHeight: Integer read GetFrameHeight;
    property FrameWidth: Integer read GetFrameWidth;
    //# Layout
    property AllowColoration: Boolean read FAllowColoration write SetAllowColoration;
    property ContentOffsets: TRect read FContentOffsets write SetContentOffsets;
    property HitTestMask: TACLSkinImageHitTestMode read FHitTestMask write SetHitTestMask;
    property HitTestMaskFrameIndex: Integer read FHitTestMaskFrameIndex write SetHitTestMaskFrameIndex;
    property Layout: TACLSkinImageLayout read FLayout write SetLayout;
    //# Margins
    property Margins: TRect read FMargins write SetMargins;
    property SizingMode: TACLSkinImageSizingMode read FSizingMode write SetSizingMode;
    property StretchMode: TACLStretchMode read FStretchMode write SetStretchMode;
    property TiledAreas: TACLSkinImageTiledAreas read FTiledAreas write SetTiledAreas;
    property TiledAreasMode: TACLSkinImageTiledAreasMode read FTiledAreasMode write SetTiledAreasMode;
  end;

  { EZLibError }

  EZLibError = class(Exception)
  public
    constructor Create(ACode: Integer);
    class function Check(ACode: Integer; AIgnoreBufferError: Boolean = False): Integer;
  end;

  { EZLibCompressError }

  EZLibCompressError = class(EZLibError);

  { EZLibDecompressError }

  EZLibDecompressError = class(EZLibError);

const
  NullTileArea: TACLSkinImageTiledAreas = (
    Part1TileStart: 0; Part1TileWidth: 0;
    Part2TileStart: 0; Part2TileWidth: 0
  );

var
  FSkinImageCompressionLevel: TCompressionlevel = clFastest;
{$IFDEF ACL_SKINIMAGE_COLLECT_STATS}
  FSkinImageCount: Integer = 0;
  FSkinImageDormantCount: Integer = 0;
  FSkinImageMemoryCompressed: Integer = 0;
  FSkinImageMemoryUsage: Integer = 0;
  FSkinImageMemoryUsageInDormant: Integer = 0;
{$ENDIF}

procedure acCalculateTiledAreas(const R: TRect; const AParams: TACLSkinImageTiledAreas;
  ATextureWidth, ATextureHeight: Integer; ATiledAreasMode: TACLSkinImageTiledAreasMode;
  out AParts: TACLSkinImageTiledAreasPartBounds);
implementation

uses
  ACL.FastCode,
  ACL.Graphics.Ex,
{$IFDEF ACL_CAIRO}
  ACL.Graphics.Ex.Cairo,
{$ENDIF}
  ACL.Math,
  ACL.Threading,
  ACL.Utils.Stream;

type
  PByteRef = {$IFDEF FPC}pBytef{$ELSE}PByte{$ENDIF};

  { TAnalyzer }

  TAnalyzer = class
  strict private const
    INVALID_VALUE = $010203;
  strict private
    class procedure RunCore(AColors: PACLPixel32;
      ACount: Integer; var AAlpha, AColor: DWORD); inline;
    class function AnalyzeResultToState(
      var AAlpha: DWORD; var AColor: DWORD): TACLSkinImageFrameState;
  public
    class function Run(Q: PACLPixel32;
      ACount: Integer): TACLSkinImageFrameState; overload;
    class function Run(Q: PACLPixel32;
      APart: TRect; AImageWidth: Integer): TACLSkinImageFrameState; overload;
    class procedure RecoveryAlpha(Q: PACLPixel32;
      ACount: Integer; var AHasSemitransparecy: Boolean);
  end;

  { TRenderer }

  TRenderer = class
  strict private type
    TFillPart = procedure (const ATarget: TRect; AColor: TAlphaColor) of object;
    TDrawPart = procedure (const ATarget, ASource: TRect) of object;
  strict private
    class var FLock: TACLCriticalSection;
    class var FFrame: Integer;
    class var FFrameRect: TRect;
    class var FImage: TACLSkinImage;
  strict private
  {$IFDEF MSWINDOWS}
    class var FDstCanvas: TCanvas;
    class var FFunc: TBlendFunction;
    class var FMemDC: HDC;
    class var FMemBmp: HBITMAP;
    class var FMemBmpBits: Pointer;
    class var FMemBmpInfo: TBitmapInfo;
    class var FPrevBmp: HBITMAP;

    class procedure doWinDraw(const R, SrcR: TRect); inline;
    class procedure doWinDrawOpaque(const ATarget, ASource: TRect);
    class procedure doWinDrawTile(const R, SrcR: TRect);
    class procedure doWinFill(const ATarget: TRect; AColor: TAlphaColor);
    class procedure doWinFinish;
  {$ENDIF}
  strict private
  {$IFDEF ACL_CAIRO}
    class var FAlpha: Double;
    class var FCairo: TACLCairoRender;
    class var FCairoBits: Pointer;
    class var FCairoBitsSize: Integer;
    class var FSourceSurface: Pcairo_surface_t;

    class procedure doCairoInit;
    class procedure doCairoDraw(const ATarget, ASource: TRect);
    class procedure doCairoFill(const ATarget: TRect; AColor: TAlphaColor);
    class procedure doCairoFinish;
  {$ENDIF}
  protected
    // Current State, Valid inside Start/Finish
    class var Finish: TThreadMethod;
    class var FillPart: TFillPart;
    class var DrawPart: TDrawPart;
    class procedure doInit(AExitProc: TThreadMethod; AFillProc: TFillPart; ADrawProc: TDrawPart);
  public
    class constructor Create;
    class destructor Destroy;
    class procedure Start(AImage: TACLSkinImage;
      ACanvas: TCanvas; AFrameIndex: Integer; AAlpha: Byte); overload;
  {$IFDEF ACL_CAIRO}
    class procedure Start(AImage: TACLSkinImage;
      ACairo: Pcairo_t; AFrameIndex: Integer; AAlpha: Byte); overload;
  {$ENDIF}
    class procedure Draw(ARect: TRect);
  end;

procedure acCalculateTiledAreas(const R: TRect; const AParams: TACLSkinImageTiledAreas;
  ATextureWidth, ATextureHeight: Integer; ATiledAreasMode: TACLSkinImageTiledAreasMode;
  out AParts: TACLSkinImageTiledAreasPartBounds);
begin
  if ATiledAreasMode = tpmHorizontal then
  begin
    AParts[tpzPart1Fixed] := R;
    AParts[tpzPart1Fixed].Right := AParts[tpzPart1Fixed].Left + AParams.Part1TileStart;

    AParts[tpzPart2Fixed] := R;
    AParts[tpzPart2Fixed].Left := R.Right - (ATextureWidth - AParams.Part2TileWidth - AParams.Part2TileStart);

    Dec(ATextureWidth, AParams.Part1TileStart);
    Dec(ATextureWidth, AParts[tpzPart2Fixed].Width);
    Dec(ATextureWidth, AParams.Part1TileWidth + AParams.Part2TileWidth);

    AParts[tpzCenter] := R;
    AParts[tpzCenter].Left := AParts[tpzPart1Fixed].Right;
    AParts[tpzCenter].Right := AParts[tpzPart2Fixed].Left;
    if (AParams.Part2TileWidth > 0) or (AParams.Part1TileWidth > 0) then
    begin
      if AParams.Part1TileWidth <= 0 then
        AParts[tpzCenter].Right := AParts[tpzCenter].Left + ATextureWidth
      else
        if AParams.Part2TileWidth <= 0 then
          AParts[tpzCenter].Left := AParts[tpzCenter].Right - ATextureWidth
        else
        begin
          Inc(AParts[tpzCenter].Left, AParams.Part1TileWidth);
          Dec(AParts[tpzCenter].Right, AParams.Part2TileWidth);
          AParts[tpzCenter].CenterHorz(ATextureWidth);
        end;
    end;
    AParts[tpzPart1Tile] := R;
    AParts[tpzPart1Tile].Left := AParts[tpzPart1Fixed].Right;
    AParts[tpzPart1Tile].Right := AParts[tpzCenter].Left;

    AParts[tpzPart2Tile] := R;
    AParts[tpzPart2Tile].Left := AParts[tpzCenter].Right;
    AParts[tpzPart2Tile].Right := AParts[tpzPart2Fixed].Left;
  end
  else
  begin
    AParts[tpzPart1Fixed] := R;
    AParts[tpzPart1Fixed].Bottom := AParts[tpzPart1Fixed].Top + AParams.Part1TileStart;

    AParts[tpzPart2Fixed] := R;
    AParts[tpzPart2Fixed].Top := R.Bottom - (ATextureHeight - AParams.Part2TileWidth - AParams.Part2TileStart);

    Dec(ATextureHeight, AParams.Part1TileStart);
    Dec(ATextureHeight, AParts[tpzPart2Fixed].Height);
    Dec(ATextureHeight, AParams.Part1TileWidth + AParams.Part2TileWidth);

    AParts[tpzCenter] := R;
    AParts[tpzCenter].Top := AParts[tpzPart1Fixed].Bottom;
    AParts[tpzCenter].Bottom := AParts[tpzPart2Fixed].Top;
    if (AParams.Part2TileWidth > 0) or (AParams.Part1TileWidth > 0) then
    begin
      if AParams.Part1TileWidth <= 0 then
        AParts[tpzCenter].Bottom := AParts[tpzCenter].Top + ATextureHeight
      else
        if AParams.Part2TileWidth <= 0 then
          AParts[tpzCenter].Top := AParts[tpzCenter].Bottom - ATextureHeight
        else
        begin
          Inc(AParts[tpzCenter].Top, AParams.Part1TileWidth);
          Dec(AParts[tpzCenter].Bottom, AParams.Part2TileWidth);
          AParts[tpzCenter].CenterVert(ATextureHeight);
        end;
    end;
    AParts[tpzPart1Tile] := R;
    AParts[tpzPart1Tile].Top := AParts[tpzPart1Fixed].Bottom;
    AParts[tpzPart1Tile].Bottom := AParts[tpzCenter].Top;

    AParts[tpzPart2Tile] := R;
    AParts[tpzPart2Tile].Top := AParts[tpzCenter].Bottom;
    AParts[tpzPart2Tile].Bottom := AParts[tpzPart2Fixed].Top;
  end;
end;

{ EZLibError }

constructor EZLibError.Create(ACode: Integer);
begin
{$IFDEF FPC}
  inherited Create(zError(ACode));
{$ELSE}
  inherited Create(string(_z_errmsg[2 - ACode]));
{$ENDIF}
end;

class function EZLibError.Check(ACode: Integer; AIgnoreBufferError: Boolean = False): Integer;
begin
  Result := ACode;
  if AIgnoreBufferError and (ACode <> Z_BUF_ERROR) then
    Exit;
  if ACode < 0 then
    raise Create(ACode){$IFNDEF FPC} at ReturnAddress{$ENDIF};
end;

{ TACLSkinImageTiledAreas }

function TACLSkinImageTiledAreas.Compare(const P: TACLSkinImageTiledAreas): Boolean;
begin
  Result := (P.Part1TileStart = Part1TileStart) and
    (P.Part1TileWidth = Part1TileWidth) and
    (P.Part2TileStart = Part2TileStart) and
    (P.Part2TileWidth = Part2TileWidth);
end;

class function TACLSkinImageTiledAreas.FromRect(const R: TRect): TACLSkinImageTiledAreas;
begin
  Result.Part1TileStart := R.Left;
  Result.Part1TileWidth := R.Top;
  Result.Part2TileStart := R.Right;
  Result.Part2TileWidth := R.Bottom;
end;

function TACLSkinImageTiledAreas.IsEmpty: Boolean;
begin
  Result := (Part1TileWidth = 0) and (Part2TileWidth = 0);
end;

function TACLSkinImageTiledAreas.ToRect: TRect;
begin
  Result := Rect(Self.Part1TileStart, Self.Part1TileWidth, Self.Part2TileStart, Self.Part2TileWidth);
end;

{ TACLSkinImageFrameStateHelper }

function TACLSkinImageFrameStateHelper.IsColor: Boolean;
begin
  Result := Self and $FF000000 <> 0;
end;

function TACLSkinImageFrameStateHelper.IsOpaque: Boolean;
begin
  Result := (Self = OPAQUE) or IsColor and (TAlphaColor(Self).A = MaxByte);
end;

function TACLSkinImageFrameStateHelper.IsTransparent: Boolean;
begin
  Result := (Self = TRANSPARENT);
end;

{ TACLSkinFrameDormantData }

constructor TACLSkinFrameDormantData.CopyOf(ASource: TACLSkinFrameDormantData);
begin
  DataSize := ASource.DataSize;
  Data := AllocMem(DataSize);
  FastMove(ASource.Data^, Data^, DataSize);
end;

constructor TACLSkinFrameDormantData.Create(
  ABits: PACLPixel32; ACount: Integer; APreferBufferSize: Cardinal);
const
  Delta = 256;
  Levels: array[TCompressionLevel] of ShortInt = (
    Z_NO_COMPRESSION, Z_BEST_SPEED, Z_DEFAULT_COMPRESSION, Z_BEST_COMPRESSION
  );
var
  AInSize: Cardinal;
  AOutSize: Cardinal;
  ZStream: TZStreamRec;
begin
  // Our own ZCompress implementation, because standard version works with Integer, not Cardinal.
  AInSize := ACount * SizeOf(TACLPixel32);
  if APreferBufferSize > 0 then
    AOutSize := APreferBufferSize
  else
  begin
    AOutSize := 12{ZLib Header} + AInSize div 2;
    if AInSize < 100 then
      Inc(AOutSize, AInSize div 3);
  end;

  GetMem(Data, AOutSize);
  try
    FillChar(ZStream{%H-}, SizeOf(ZStream), 0);
    ZStream.next_in := PByteRef(ABits);
    ZStream.next_out := Data;
    ZStream.avail_in := AInSize;
    ZStream.avail_out := AOutSize;

    EZLibCompressError.Check(DeflateInit(ZStream, Levels[FSkinImageCompressionLevel]));
    try
      while EZLibCompressError.Check(deflate(ZStream, Z_FINISH), True) <> Z_STREAM_END do
      begin
        Inc(AOutSize, Delta);
        ReallocMem(Data, AOutSize);
        ZStream.next_out := PByteRef(Data) + ZStream.total_out;
        ZStream.avail_out := Delta;
      end;
    finally
      EZLibCompressError.Check(deflateEnd(ZStream));
    end;

    if Abs(Int64(ZStream.total_out) - Int64(AOutSize)) > Delta then
      ReallocMem(Data, ZStream.total_out);

    DataSize := ZStream.total_out;
  except
    FreeMemAndNil(Data);
    raise;
  end;
end;

constructor TACLSkinFrameDormantData.Create(AStream: TStream);
begin
  AStream.ReadBuffer(DataSize, SizeOf(Cardinal));
  GetMem(Data, DataSize);
  AStream.ReadBuffer(Data^, DataSize);
end;

destructor TACLSkinFrameDormantData.Destroy;
begin
  FreeMem(Data);
  inherited;
end;

function TACLSkinFrameDormantData.Equals(Obj: TObject): Boolean;
begin
  Result := (Obj <> nil) and (Obj.ClassType = ClassType) and
    (DataSize = TACLSkinFrameDormantData(Obj).DataSize) and
    (CompareMem(Data, TACLSkinFrameDormantData(Obj).Data, DataSize));
end;

function TACLSkinFrameDormantData.GetHashCode: TObjHashCode;
var
  AHashValue: Cardinal;
begin
  AHashValue := TACLHashCRC32.Calculate(Data, DataSize);
  Result := TObjHashCode(AHashValue);
end;

procedure TACLSkinFrameDormantData.Restore(ABits: PACLPixel32; ACount: Integer);
var
  ASize: Cardinal;
  ZStream: TZStreamRec;
begin
  ASize := ACount * SizeOf(TACLPixel32);
  FillChar(ZStream{%H-}, SizeOf(TZStreamRec), 0);
  ZStream.next_in := Data;
  ZStream.avail_in := DataSize;
  ZStream.next_out := PByteRef(ABits);
  ZStream.avail_out := ASize;

  EZLibDecompressError.Check(InflateInit(ZStream));
  EZLibDecompressError.Check(inflate(ZStream, Z_NO_FLUSH));
  EZLibDecompressError.Check(inflateEnd(ZStream));

  if ZStream.total_out <> ASize then
    raise EACLSkinImageException.Create(sErrorIncorrectDormantData);
end;

procedure TACLSkinFrameDormantData.SaveToStream(AStream: TStream);
begin
  AStream.WriteBuffer(DataSize, SizeOf(Cardinal));
  AStream.WriteBuffer(Data^, DataSize);
end;

{$REGION ' TACLSkinImage '}

{ TACLSkinImage }

constructor TACLSkinImage.Create;
begin
  inherited Create;
  FAllowColoration := True;
  FChangeListeners := TACLListOf<TNotifyEvent>.Create;
  FFrameCount := 1;
{$IFDEF ACL_SKINIMAGE_COLLECT_STATS}
  InterlockedIncrement(FSkinImageCount);
{$ENDIF}
end;

constructor TACLSkinImage.Create(AChangeEvent: TNotifyEvent);
begin
  Create;
  ListenerAdd(AChangeEvent);
end;

destructor TACLSkinImage.Destroy;
begin
  ClearData;
{$IFDEF ACL_SKINIMAGE_COLLECT_STATS}
  InterlockedDecrement(FSkinImageCount);
{$ENDIF}
  FreeAndNil(FChangeListeners);
  inherited Destroy;
end;

procedure TACLSkinImage.Assign(AObject: TObject);
begin
  if AObject <> Self then
  begin
    BeginUpdate;
    try
      DoAssign(AObject);
      Changed;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TACLSkinImage.AssignParams(ASkinImage: TACLSkinImage);
begin
  BeginUpdate;
  try
    DoAssignParams(ASkinImage);
    Changed;
  finally
    EndUpdate;
  end;
end;

procedure TACLSkinImage.Clear;
begin
  if not Empty then
  begin
    ClearData;
    Changed;
  end;
end;

function TACLSkinImage.Equals(Obj: TObject): Boolean;
begin
  if (Obj = nil) or (ClassType <> Obj.ClassType) then
    Exit(False);
  if (Height <> TACLSkinImage(Obj).Height) then
    Exit(False);
  if (Width <> TACLSkinImage(Obj).Width) then
    Exit(False);
  if (Margins <> TACLSkinImage(Obj).Margins) then
    Exit(False);
  if (AllowColoration <> TACLSkinImage(Obj).AllowColoration) then
    Exit(False);
  if (HitTestMask <> TACLSkinImage(Obj).HitTestMask) then
    Exit(False);
  if (HitTestMaskFrameIndex <> TACLSkinImage(Obj).HitTestMaskFrameIndex) then
    Exit(False);
  if (Layout <> TACLSkinImage(Obj).Layout) then
    Exit(False);
  if (StretchMode <> TACLSkinImage(Obj).StretchMode) then
    Exit(False);
  if not TiledAreas.Compare(TACLSkinImage(Obj).TiledAreas) then
    Exit(False);
  if (TiledAreasMode <> TACLSkinImage(Obj).TiledAreasMode) then
    Exit(False);
  if (ContentOffsets <> TACLSkinImage(Obj).ContentOffsets) then
    Exit(False);
  if (SizingMode <> TACLSkinImage(Obj).SizingMode) then
    Exit(False);
  if (FrameCount <> TACLSkinImage(Obj).FrameCount) then
    Exit(False);
  if FDormantData <> nil then
    Exit(FDormantData.Equals(TACLSkinImage(Obj).FDormantData));
  if (Bits <> nil) and (TACLSkinImage(Obj).Bits <> nil) then
    Exit(CompareMem(Bits, TACLSkinImage(Obj).Bits, SizeOf(TACLPixel32) * BitCount));
  Result := False;
end;

function TACLSkinImage.GetHashCode: TObjHashCode;
//var
//  AHashValue: Cardinal;
begin
  raise ENotSupportedException.Create('TACLSkinImage.GetHashCode');
//  if FDormantData <> nil then
//    Result := FDormantData.GetHashCode
//  else
//    if Bits <> nil then
//    begin
//      AHashValue := TACLHashCRC32.Calculate(PByte(Bits), BitCount);
//      Result := TObjHashCode(AHashValue);
//    end
//    else
//      Result := 0;
end;

function TACLSkinImage.HasFrame(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FrameCount);
end;

procedure TACLSkinImage.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TACLSkinImage.BitsNeeded(AState: TACLSkinImageBitsState);
begin
  CheckUnpacked;
  if AState <> FBitsState then
  begin
    if HasAlpha then
    begin
      case AState of
        ibsPremultiplied:
          TACLColors.Premultiply(Bits, BitCount);
        ibsUnpremultiplied:
          TACLColors.Unpremultiply(Bits, BitCount);
      end;
    end;
    FBitsState := AState;
  end;
end;

procedure TACLSkinImage.CancelUpdate;
begin
  Dec(FUpdateCount);
end;

procedure TACLSkinImage.EndUpdate;
begin
  Dec(FUpdateCount);
  Changed;
end;

procedure TACLSkinImage.ApplyColorSchema(const AValue: TACLColorSchema);
begin
  if not Empty and AllowColoration and AValue.IsAssigned then
  begin
    BitsNeeded(ibsUnpremultiplied);
    TACLColors.ApplyColorSchema(Bits, BitCount, AValue);
    Changed;
  end;
end;

procedure TACLSkinImage.ApplyTint(const AColor: TACLPixel32);
begin
  if not Empty then
  begin
    BitsNeeded(ibsUnpremultiplied);
    TACLColors.Tint(Bits, BitCount, AColor);
    Changed;
  end;
end;

{$IFDEF ACL_CAIRO}
procedure TACLSkinImage.Draw(ACairo: Pcairo_t;
  ARect: TRect; AFrameIndex: Integer = 0; AAlpha: Byte = MaxByte);
var
  LState: TACLSkinImageFrameState;
begin
  if not (Empty or ARect.IsEmpty) then
  begin
    BitsNeeded(ibsPremultiplied);
    CheckFrameIndex(AFrameIndex);
    LState := FrameInfo[AFrameIndex];

    if LState.IsTransparent then
      Exit;
    if LState.IsColor then
    begin
      if (StretchMode = isCenter) and (ActualSizingMode = ismDefault) then
      begin
        ARect.CenterHorz(FrameWidth);
        ARect.CenterVert(FrameHeight);
      end;
      cairo_set_source_color(ACairo, TAlphaColor(LState));
      cairo_rectangle(ACairo, ARect.Left, ARect.Top, ARect.Width, ARect.Height);
      cairo_fill(ACairo);
      Exit;
    end;

    TRenderer.Start(Self, ACairo, AFrameIndex, AAlpha);
    try
      TRenderer.Draw(ARect);
    finally
      TRenderer.Finish();
    end;
  end;
end;
{$ENDIF}

procedure TACLSkinImage.Draw(ACanvas: TCanvas; ARect: TRect; AFrameIndex: Integer; AAlpha: Byte);
var
  LState: TACLSkinImageFrameState;
begin
  if not Empty and acRectVisible(ACanvas, ARect) then
  begin
    BitsNeeded(ibsPremultiplied);
    CheckFrameIndex(AFrameIndex);
    LState := FrameInfo[AFrameIndex];

    if LState.IsTransparent then
      Exit;
    if LState.IsColor then
    begin
      if (StretchMode = isCenter) and (ActualSizingMode = ismDefault) then
      begin
        ARect.CenterHorz(FrameWidth);
        ARect.CenterVert(FrameHeight);
      end;
      acFillRect(ACanvas, ARect, TAlphaColor(LState));
      Exit;
    end;

    TRenderer.Start(Self, ACanvas, AFrameIndex, AAlpha);
    try
      TRenderer.Draw(ARect);
    finally
      TRenderer.Finish();
    end;
  end;
end;

procedure TACLSkinImage.Draw(ACanvas: TCanvas; const R: TRect;
  AFrameIndex: Integer; AEnabled: Boolean; AAlpha: Byte = MaxByte);
var
  ALayer: TACLDib;
begin
  if AEnabled then
    Draw(ACanvas, R, AFrameIndex, AAlpha)
  else
  begin
    ALayer := TACLDib.Create(R);
    try
      Draw(ALayer.Canvas, ALayer.ClientRect, AFrameIndex);
      ALayer.MakeDisabled;
      ALayer.DrawBlend(ACanvas, R, AAlpha);
    finally
      ALayer.Free;
    end;
  end;
end;

function TACLSkinImage.HitTest(const ABounds: TRect; X, Y: Integer): Boolean;
begin
  if HitTestMask = ihtmMask then
    Result := HitTestEx(ABounds, X, Y, HitTestMaskFrameIndex)
  else
    Result := HitTestMask = ihtmOpaque;
end;

function TACLSkinImage.HitTestEx(const ABounds: TRect; X, Y: Integer;
  AMaskFrameIndex, AMaskSensivity: Integer; APixel: PACLPixel32): Boolean;

  procedure ConvertPointRelativeRects(var P: TPoint; const DR, SR: TRect);
  begin
    P.X := MulDiv(P.X - DR.Left, SR.Width, DR.Width) + SR.Left;
    P.Y := MulDiv(P.Y - DR.Top, SR.Height, DR.Height) + SR.Top;
  end;

  procedure ConvertPointForTiledAreasMode(var P: TPoint; const DR, FR: TRect);
  var
    APart: TACLSkinImageTiledAreasPart;
    S, D: TACLSkinImageTiledAreasPartBounds;
  begin
    acCalculateTiledAreas(FR, TiledAreas, FR.Width, FR.Height, TiledAreasMode, S);
    acCalculateTiledAreas(DR, TiledAreas, FR.Width, FR.Height, TiledAreasMode, D);
    for APart := Low(TACLSkinImageTiledAreasPart) to High(TACLSkinImageTiledAreasPart) do
      if D[APart].Contains(P) then
      begin
        ConvertPointRelativeRects(P, D[APart], S[APart]);
        Break;
      end;
  end;

  procedure ConvertPointForMarginsMode(var P: TPoint; const DR, FR: TRect);
  var
    APart: TACLMarginPart;
    DZ, SZ: TACLMarginPartBounds;
  begin
    acCalcPartBounds(DZ, Margins, DR, FR, StretchMode);
    acCalcPartBounds(SZ, Margins, FR, FR, StretchMode);
    for APart := Low(APart) to High(APart) do
      if DZ[APart].Contains(P) then
      begin
        ConvertPointRelativeRects(P, DZ[APart], SZ[APart]);
        Break;
      end;
  end;

  function ConvertPointToLocalCoords(var P: TPoint; const AFrameRect: TRect): Boolean;
  begin
    if {ABounds.IsEmpty or }not ABounds.Contains(P) then
      Exit(False);
    case ActualSizingMode of
      ismMargins:
        ConvertPointForMarginsMode(P, ABounds, AFrameRect);
      ismTiledAreas:
        ConvertPointForTiledAreasMode(P, ABounds, AFrameRect);
    else
      ConvertPointRelativeRects(P, ABounds, AFrameRect);
    end;
    Result := AFrameRect.Contains(P);
  end;

var
  LPixel: TACLPixel32;
  LPoint: TPoint;
begin
  if Empty then
  begin
    if APixel <> nil then
      LongWord(APixel^) := 0;
    Exit(True);
  end;

  Result := False;
  LPoint := Point(X, Y);
  if ConvertPointToLocalCoords(LPoint, FrameRect[AMaskFrameIndex]) then
  begin
    CheckUnpacked;
    LPixel := Bits[LPoint.X + LPoint.Y * Width];
    Result := LPixel.A >= AMaskSensivity;
    if Result and (APixel <> nil) then
      APixel^ := LPixel;
  end;
end;

procedure TACLSkinImage.ListenerAdd(AEvent: TNotifyEvent);
begin
  FChangeListeners.Add(AEvent)
end;

procedure TACLSkinImage.ListenerRemove(AEvent: TNotifyEvent);
begin
  FChangeListeners.Remove(AEvent)
end;

procedure TACLSkinImage.LoadFromBits(ABits: PACLPixel32; AWidth, AHeight: Integer);
begin
  DoCreateBits(AWidth, AHeight);
  FastMove(ABits^, Bits^, BitCount * SizeOf(TACLPixel32));
  Changed;
end;

procedure TACLSkinImage.LoadFromBitmap(ABitmap: TACLDib);
begin
  LoadFromBits(ABitmap.Colors, ABitmap.Width, ABitmap.Height);
end;

procedure TACLSkinImage.LoadFromBitmap(ABitmap: TBitmap);
{$IFDEF FPC}
var
  LDib: TACLDib;
begin
  LDib := TACLDib.Create;
  try
    LDib.Assign(ABitmap);
    if (ABitmap.PixelFormat > pfDevice) and (ABitmap.PixelFormat < pf32bit) then
      LDib.MakeTransparent(TACLColors.MaskPixel);
    LoadFromBitmap(LDib);
    FBitsState := ibsPremultiplied; // ref.to: TACLBaseDib.Assign(TRawImage)
  finally
    LDib.Free;
  end;
end;
{$ELSE}
var
  AInfo: TBitmapInfo;
begin
  DoCreateBits(ABitmap.Width, ABitmap.Height);
  acInitBitmap32Info(AInfo, Width, Height);
  GetDIBits(MeasureCanvas.Handle, ABitmap.Handle, 0, Height, Bits, AInfo, DIB_RGB_COLORS);
  if (ABitmap.PixelFormat > pfDevice) and (ABitmap.PixelFormat < pf32bit) then
    TACLColors.MakeTransparent(Bits, BitCount, TACLColors.MaskPixel);
  if ABitmap.AlphaFormat = afPremultiplied then
    FBitsState := ibsPremultiplied;
  Changed;
end;
{$ENDIF}

procedure TACLSkinImage.LoadFromFile(const AFileName: string);
var
  LStream: TACLFileStream;
begin
  LStream := TACLFileStream.Create(AFileName, fmOpenReadOnly);
  try
    LoadFromStream(LStream);
  finally
    LStream.Free;
  end;
end;

procedure TACLSkinImage.LoadFromResource(AInstance: HINST; const AName: string; AResRoot: PChar);
var
  ABitmap: TBitmap;
  AStream: TStream;
begin
  if AResRoot = RT_BITMAP then
  begin
    ABitmap := TACLBitmap.Create;
    try
      ABitmap.LoadFromResourceName(AInstance, AName);
      LoadFromBitmap(ABitmap);
    finally
      ABitmap.Free;
    end;
  end
  else
  begin
    AStream := TResourceStream.Create(AInstance, AName, AResRoot);
    try
      LoadFromStream(AStream);
    finally
      AStream.Free;
    end;
  end;
end;

procedure TACLSkinImage.LoadFromStream(AStream: TStream);

  function ImageToBitmap(AStream: TStream; const AHeader: TACLSkinImageHeader): TBitmap;
  begin
    if PWord(@AHeader.ID[0])^ = TACLImageFormatBMP.FormatPreamble then
    begin
      Result := TACLBitmap.Create;
      Result.LoadFromStream(AStream);
    end
    else
      with TACLImage.Create(AStream) do
      try
        Result := ToBitmap;
      finally
        Free;
      end;
  end;

var
  ABitmap: TBitmap;
  AHeader: TACLSkinImageHeader;
begin
  FLoading := True;
  BeginUpdate;
  try
    Clear;
    if AStream.Read(AHeader{%H-}, SizeOf(AHeader)) = SizeOf(AHeader) then
    begin
      if (AHeader.ID = 'ACLIMG32') and (AHeader.Version = 1) then
        ReadFormatChunked(AStream)
      else if (AHeader.ID = 'ASEIMG32') and (AHeader.Version = 1) then
        ReadFormatObsolette(AStream, 2)
      else if (AHeader.ID = 'MySknImg') and (AHeader.Version = 1) then
        ReadFormatObsolette(AStream, 1)
      else
      begin
        AStream.Seek(-SizeOf(AHeader), soFromCurrent);
        ABitmap := ImageToBitmap(AStream, AHeader);
        try
          LoadFromBitmap(ABitmap);
        finally
          ABitmap.Free;
        end;
      end;
    end;
  finally
    EndUpdate;
    FLoading := False;
  end;
end;

procedure TACLSkinImage.Optimize;
begin
  BeginUpdate;
  try
    BitsNeeded(ibsPremultiplied);
    // При вертикальной раскладке фреймы рисуются быстрее
    if Layout = ilHorizontal then 
      SwapLayout;
    CheckFramesInfo;
  finally
    CancelUpdate;
  end;
end;

procedure TACLSkinImage.SaveToBitmap(ABitmap: TACLDib);
begin
  ABitmap.Resize(Width, Height);
  if not Empty then
  begin
    BitsNeeded(ibsUnpremultiplied);
    FastMove(Bits^, ABitmap.Colors^, BitCount * SizeOf(TACLPixel32));
  end;
end;

procedure TACLSkinImage.SaveToBitmap(ABitmap: TBitmap);
{$IFNDEF FPC}
var
  LDC: HDC;
  LInfo: TBitmapInfo;
{$ENDIF}
begin
  ABitmap.SetSize(Width, Height);
  if not Empty then
  begin
    BitsNeeded(ibsUnpremultiplied);
  {$IFDEF FPC}
    if HasAlpha then
      ABitmap.PixelFormat := pf32bit
    else
      ABitmap.PixelFormat := pf24bit;

    acSetBitmapBits(ABitmap, Bits, BitCount);
  {$ELSE}
    LDC := GetDC(0);
    try
      ABitmap.AlphaFormat := afIgnored;
      ABitmap.PixelFormat := pf32bit;
      acInitBitmap32Info(LInfo, Width, Height);
      SetDIBits(LDC, ABitmap.Handle, 0, Height, Bits, LInfo, DIB_RGB_COLORS);
      if not HasAlpha then
        ABitmap.PixelFormat := pf24bit;
    finally
      ReleaseDC(0, LDC);
    end;
  {$ENDIF}
  end;
end;

procedure TACLSkinImage.SaveToFile(const AFileName: string; AFormat: TACLImageFormatClass);
var
  LStream: TStream;
begin
  LStream := TACLFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(LStream, AFormat);
  finally
    LStream.Free;
  end;
end;

procedure TACLSkinImage.SaveToImage(AImage: TACLImage);
var
  LAlphaFormat: TAlphaFormat;
begin
  if Empty then
    AImage.Clear
  else
  begin
    CheckUnpacked;
    if not HasAlpha then
      LAlphaFormat := afIgnored
    else if BitsState = ibsPremultiplied then
      LAlphaFormat := afPremultiplied
    else
      LAlphaFormat := afDefined;

    AImage.LoadFromBits(Bits, Self.Width, Self.Height, LAlphaFormat);
  end;
end;

procedure TACLSkinImage.SaveToStream(AStream: TStream; AFormat: TACLImageFormatClass);
var
  LBitmap: TBitmap;
  LImage: TACLImage;
begin
  if Empty then
    Exit;

  if AFormat = TACLImageFormatBMP then
  begin
    LBitmap := TBitmap.Create;
    try
      SaveToBitmap(LBitmap);
      LBitmap.SaveToStream(AStream);
    finally
      LBitmap.Free;
    end;
  end
  else
  begin
    LImage := TACLImage.Create;
    try
      SaveToImage(LImage);
      LImage.SaveToStream(AStream, AFormat);
    finally
      LImage.Free;
    end;
  end;
end;

procedure TACLSkinImage.SaveToFile(const AFileName: string);
var
  LStream: TStream;
begin
  LStream := TACLFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(LStream);
  finally
    LStream.Free;
  end;
end;

procedure TACLSkinImage.SaveToStream(AStream: TStream);
var
  LChunkCount: Integer;
  LHeader: TACLSkinImageHeader;
  LPosition1: Int64;
  LPosition2: Int64;
begin
  LChunkCount := 0;
  LHeader.ID := 'ACLIMG32';
  LHeader.Version := 1;
  AStream.WriteBuffer(LHeader, SizeOf(LHeader));
  LPosition1 := AStream.Position;
  AStream.WriteInt32(LChunkCount);
  WriteChunks(AStream, LChunkCount);
  LPosition2 := AStream.Position;
  AStream.Position := LPosition1;
  AStream.WriteInt32(LChunkCount);
  AStream.Position := LPosition2;
end;

procedure TACLSkinImage.Changed;
var
  I: Integer;
begin
  if not FLoading then
  begin
    FFrameInfoIsValid := False;
    FHasAlpha := TACLBoolean.Default;
  end;
  if FUpdateCount = 0 then
  begin
    for I := 0 to FChangeListeners.Count - 1 do
      FChangeListeners.List[I](Self);
  end;
end;

procedure TACLSkinImage.Dormant;
begin
  if (Bits <> nil) and (BitCount >= CompressionThreshold) then
  begin
    FreeAndNil(FDormantData);
    FDormantData := CompressData;
  {$IFDEF ACL_SKINIMAGE_COLLECT_STATS}
    Inc(FSkinImageMemoryCompressed, FDormantData.DataSize);
    Inc(FSkinImageMemoryUsageInDormant, BitCount * SizeOf(TACLPixel32));
    Inc(FSkinImageDormantCount);
  {$ENDIF}
    ReleaseHandle;
  end;
end;

procedure TACLSkinImage.CheckFrameIndex(var AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FrameCount) then
    AIndex := 0;
end;

procedure TACLSkinImage.CheckFramesInfo;
var
  LState: TACLSkinImageFrameState;
  I: Integer;
begin
  if not FFrameInfoIsValid then
  begin
    if Length(FFrameInfo) <> FrameCount then
    begin
      SetLength(FFrameInfo, FrameCount);
      SetLength(FFrameInfoContent, FrameCount);
    end;

    BitsNeeded(ibsPremultiplied);
    for I := 0 to FrameCount - 1 do
      FFrameInfo[I] := TAnalyzer.Run(FBits, FrameRect[I], Width);

    if ActualSizingMode = ismMargins then
    begin
      for I := 0 to FrameCount - 1 do
      begin
        LState := FFrameInfo[I];
        if LState.IsColor or LState.IsTransparent then
          FFrameInfoContent[I] := LState
        else
          FFrameInfoContent[I] := TAnalyzer.Run(FBits, FrameRect[I].Split(Margins), Width);
      end;
    end
    else
    begin
      for I := 0 to FrameCount - 1 do
        FFrameInfoContent[I] := FFrameInfo[I];
    end;

    FFrameInfoIsValid := True;
  end;
end;

procedure TACLSkinImage.CheckUnpacked;
var
  LData: TACLSkinFrameDormantData;
  LPrevAlpha: TACLBoolean;
  LPrevFramesAreValid: Boolean;
  LPrevState: TACLSkinImageBitsState;
begin
  if (FBits = nil) and (FDormantData <> nil) then
  begin
    LData := FDormantData;
    try
      LPrevAlpha := FHasAlpha;
      LPrevState := FBitsState;
      LPrevFramesAreValid := FFrameInfoIsValid;
      FDormantPreferSize := LData.DataSize;
      FDormantData := nil;
      DoCreateBits(Width, Height);
      LData.Restore(Bits, BitCount);
      FFrameInfoIsValid := LPrevFramesAreValid;
      FBitsState := LPrevState;
      FHasAlpha := LPrevAlpha;
    finally
      FreeAndNil(LData);
    end;
  end;
end;

procedure TACLSkinImage.ClearData;
begin
{$IFDEF ACL_SKINIMAGE_COLLECT_STATS}
  if FDormantData <> nil then
  begin
    Dec(FSkinImageMemoryUsageInDormant, BitCount * SizeOf(TACLPixel32));
    Dec(FSkinImageMemoryCompressed, FDormantData.DataSize);
    Dec(FSkinImageDormantCount);
  end;
{$ENDIF}
  FreeAndNil(FDormantData);
  ReleaseHandle;
  DoSetSize(0, 0);
  FHasAlpha := TACLBoolean.Default;
  FBitsState := ibsUnpremultiplied;
  FFrameInfoIsValid := False;
end;

function TACLSkinImage.CompressData: TACLSkinFrameDormantData;
begin
  Result := TACLSkinFrameDormantData.Create(Bits, BitCount, FDormantPreferSize);
  FDormantPreferSize := Result.DataSize;
end;

procedure TACLSkinImage.DoAssign(AObject: TObject);
var
  LSource: TACLSkinImage;
begin
  if AObject is TBitmap then
    LoadFromBitmap(TBitmap(AObject))
  else
    if AObject is TACLSkinImage then
    begin
      ClearData;
      LSource := TACLSkinImage(AObject);
      if LSource.FDormantData <> nil then
      begin
        DoSetSize(LSource.Width, LSource.Height);
        FDormantData := TACLSkinFrameDormantData.CopyOf(LSource.FDormantData);
      {$IFDEF ACL_SKINIMAGE_COLLECT_STATS}
        Inc(FSkinImageMemoryUsageInDormant, BitCount * SizeOf(TACLPixel32));
        Inc(FSkinImageMemoryCompressed, FDormantData.DataSize);
        Inc(FSkinImageDormantCount);
      {$ENDIF}
      end
      else
      begin
        DoCreateBits(LSource.Width, LSource.Height);
        if (LSource.Bits <> nil) and (Bits <> nil) and (BitCount > 0) then
          FastMove(LSource.Bits^, Bits^, BitCount * SizeOf(TACLPixel32));
      end;
      FBitsState := LSource.FBitsState;
      FHasAlpha := LSource.FHasAlpha;
      DoAssignParams(LSource);
    end;
end;

procedure TACLSkinImage.DoAssignParams(ASkinImage: TACLSkinImage);
begin
  FAllowColoration := ASkinImage.AllowColoration;
  FSizingMode := ASkinImage.SizingMode;
  HitTestMask := ASkinImage.HitTestMask;
  Layout := ASkinImage.Layout;
  Margins := ASkinImage.Margins;
  StretchMode := ASkinImage.StretchMode;
  TiledAreas := ASkinImage.TiledAreas;
  TiledAreasMode := ASkinImage.TiledAreasMode;
  ContentOffsets := ASkinImage.ContentOffsets;
  FrameCount := ASkinImage.FrameCount; // after set Layout
  HitTestMaskFrameIndex := ASkinImage.HitTestMaskFrameIndex;
end;

procedure TACLSkinImage.DoCreateBits(AWidth, AHeight: Integer);
begin
  ClearData;
  DoSetSize(AWidth, AHeight);
  if BitCount > 0 then
  begin
  {$IFDEF ACL_SKINIMAGE_COLLECT_STATS}
    Inc(FSkinImageMemoryUsage, BitCount * SizeOf(TACLPixel32));
  {$ENDIF}
  {$IFDEF ACL_SKINIMAGE_CACHE_HBITMAP}
    acCreateDib32(Width, Height, FBits, FHandle);
  {$ELSE}
    FBits := AllocMem(BitCount * SizeOf(TACLPixel32));
  {$ENDIF}
  end;
end;

procedure TACLSkinImage.DoSetSize(AWidth, AHeight: Integer);
begin
  FWidth := AWidth;
  FHeight := AHeight;
  FBitCount := Width * Height;
end;

procedure TACLSkinImage.ReadChunk(AStream: TStream; AChunkID, AChunkSize: Integer);
begin
  case AChunkID of
    CHUNK_BITS:
      ReadChunkBits(AStream, AChunkSize);
    CHUNK_BITZ:
      ReadChunkBitz(AStream, AChunkSize);
    CHUNK_DRAW:
      ReadChunkDraw(AStream);
    CHUNK_LAYOUT:
      ReadChunkLayout(AStream);
    CHUNK_FRAMEINFO:
      ReadChunkFrameInfo(AStream, AChunkSize);
    CHUNK_FRAME:
      begin
        HitTestMask := TACLSkinImageHitTestMode(AStream.ReadByte);
        HitTestMaskFrameIndex := AStream.ReadInt32;
      end;
  end;
end;

procedure TACLSkinImage.ReadFormatChunked(AStream: TStream);
var
  LChunkID: Integer;
  LChunkSize: Integer;
  LPosition: Int64;
  I: Integer;
begin
  for I := 0 to AStream.ReadInt32 - 1 do
  begin
    LChunkID := AStream.ReadInt32;
    LChunkSize := AStream.ReadInt32;
    if LChunkSize < 0 then
      Break;

    LPosition := AStream.Position;
    try
      ReadChunk(AStream, LChunkID, LChunkSize);
    finally
      AStream.Position := LPosition + LChunkSize;
    end;
  end;
end;

procedure TACLSkinImage.ReadFormatObsolette(AStream: TStream; AVersion: Integer);
type
  TACLSkinImageHeaderData = packed record
    BitsSize: Integer;
    BitsPrepared: Boolean;
    BitsHasAlpha: Boolean;

    FramesCount: Integer;
    HitTestMask: TACLSkinImageHitTestMode;
    HitTestMaskFrameIndex: Integer;
    Layout: TACLSkinImageLayout;
    Margins: TRect;
    StretchMode: Byte;
    TiledAreas: TACLSkinImageTiledAreas;
    TiledAreasMode : TACLSkinImageTiledAreasMode;
    Width, Height: Integer;
  end;

var
  LHeaderData: TACLSkinImageHeaderData;
begin
  AStream.ReadBuffer(LHeaderData{%H-}, SizeOf(LHeaderData));
  if AVersion = 1 then
    LHeaderData.StretchMode := Max(LHeaderData.StretchMode - 1, 0);

  DoCreateBits(LHeaderData.Width, LHeaderData.Height);
  if LHeaderData.BitsSize > 0 then
    AStream.ReadBuffer(Bits^, LHeaderData.BitsSize);
  Layout := LHeaderData.Layout;
  FrameCount := LHeaderData.FramesCount;
  TiledAreas := LHeaderData.TiledAreas;
  TiledAreasMode := LHeaderData.TiledAreasMode;
  Margins := LHeaderData.Margins;
  HitTestMaskFrameIndex := LHeaderData.HitTestMaskFrameIndex;
  HitTestMask := LHeaderData.HitTestMask;
  StretchMode := TACLStretchMode(LHeaderData.StretchMode);

  if LHeaderData.BitsHasAlpha then
    FHasAlpha := TACLBoolean.True
  else
    FHasAlpha := TACLBoolean.False;

  if LHeaderData.BitsPrepared then
    FBitsState := ibsPremultiplied
  else
    FBitsState := ibsUnpremultiplied;

  if AVersion = 2 then
    AStream.Skip(FrameCount);

  if AStream.Read(FContentOffsets, SizeOf(TRect)) <> SizeOf(TRect) then
    FContentOffsets := NullRect;
end;

procedure TACLSkinImage.WriteChunks(AStream: TStream; var AChunkCount: Integer);
begin
  WriteChunkBits(AStream, AChunkCount);
  WriteChunkDraw(AStream, AChunkCount);
  WriteChunkLayout(AStream, AChunkCount);
  WriteChunkFrameInfo(AStream, AChunkCount);
end;

function TACLSkinImage.GetActualSizingMode: TACLSkinImageSizingMode;
begin
  if (SizingMode <> ismMargins) and not TiledAreas.IsEmpty then
    Result := ismTiledAreas
  else
    if (SizingMode <> ismTiledAreas) and not Margins.IsZero then
      Result := ismMargins
    else
      Result := ismDefault;
end;

function TACLSkinImage.GetClientRect: TRect;
begin
  Result := Rect(0, 0, Width, Height);
end;

function TACLSkinImage.GetEmpty: Boolean;
begin
  Result := BitCount = 0;
end;

function TACLSkinImage.GetFrameHeight: Integer;
begin
  if Layout = ilHorizontal then
    Result := Height
  else
    Result := Height div FrameCount;
end;

function TACLSkinImage.GetFrameInfo(Index: Integer): TACLSkinImageFrameState;
begin
  CheckFramesInfo;
  if (Index < 0) or (Index >= Length(FFrameInfo)) then
    raise EInvalidArgument.CreateFmt('%s: %d is invalid FrameInfo index', [ClassName, Index]);
  Result := FFrameInfo[Index];
end;

function TACLSkinImage.GetFrameSize: TSize;
begin
  Result.cx := FrameWidth;
  Result.cy := FrameHeight;
end;

function TACLSkinImage.GetFrameWidth: Integer;
begin
  if Layout = ilHorizontal then
    Result := Width div FrameCount
  else
    Result := Width;
end;

function TACLSkinImage.GetFrameRect(Index: Integer): TRect;
var
  ATemp: Integer;
begin
  CheckFrameIndex(Index);
  Result := ClientRect;
  case Layout of
    ilHorizontal:
      begin
        ATemp := FrameWidth;
        Result.Left := ATemp * Index;
        Result.Right := Result.Left + ATemp;
      end;

    ilVertical:
      begin
        ATemp := FrameHeight;
        Result.Top := ATemp * Index;
        Result.Bottom := Result.Top + ATemp;
      end;
  end;
end;

function TACLSkinImage.GetHasAlpha: Boolean;
var
  LHasSemitransparecy: Boolean;
  LState: TACLSkinImageFrameState;
begin
  if FHasAlpha = TACLBoolean.Default then
  begin
    CheckUnpacked;
    LHasSemitransparecy := False;
    LState := TAnalyzer.Run(Bits, BitCount);
    if LState.IsTransparent then // null-alpha
    begin
      TAnalyzer.RecoveryAlpha(Bits, BitCount, LHasSemitransparecy);
      if LHasSemitransparecy then
        FHasAlpha := TACLBoolean.True
      else
        FHasAlpha := TACLBoolean.False;
    end
    else
      FHasAlpha := TACLBoolean.From(not LState.IsOpaque);
  end;
  Result := FHasAlpha = TACLBoolean.True;
end;

procedure TACLSkinImage.SetAllowColoration(const Value: Boolean);
begin
  if FAllowColoration <> Value then
  begin
    FAllowColoration := Value;
    Changed;
  end;
end;

procedure TACLSkinImage.SetContentOffsets(const Value: TRect);
begin
  if FContentOffsets <> Value then
  begin
    FContentOffsets := Value;
    Changed;
  end;
end;

procedure TACLSkinImage.SetFrameCount(AValue: Integer);
begin
  if Layout = ilHorizontal then
    AValue := MaxMin(AValue, 1, Width)
  else
    AValue := MaxMin(AValue, 1, Height);

  if AValue <> FrameCount then
  begin
    FFrameCount := AValue;
    Changed;
  end;
end;

procedure TACLSkinImage.SetFrameSize(const AValue: TSize);
var
  LBitmap: TACLDib;
  LBitsState: TACLSkinImageBitsState;
  LFrameBitmap: TACLDib;
  LFrameCount: Integer;
  LFrameRect: TRect;
  I: Integer;
begin
  if not (Empty or AValue.isEmpty) and (AValue <> FrameSize) then
  begin
    BeginUpdate;
    try
      LFrameCount := FrameCount;
      LBitmap := TACLDib.Create(AValue.cx, AValue.cy * FrameCount);
      try
        LFrameRect := TRect.Create(AValue);
        LFrameBitmap := TACLDib.Create(FrameWidth, FrameHeight);
        try
          for I := 0 to LFrameCount - 1 do
          begin
            LFrameBitmap.Reset;
            Draw(LFrameBitmap.Canvas, LFrameBitmap.ClientRect, I);
            LFrameBitmap.DrawBlend(LBitmap.Canvas, LFrameRect, MaxByte, True);
            LFrameRect.Offset(0, LFrameRect.Height);
          end;
        finally
          LFrameBitmap.Free;
        end;
        LBitsState := FBitsState;
        LoadFromBitmap(LBitmap);
        Layout := ilVertical;
        FrameCount := LFrameCount;
        FBitsState := LBitsState;
      finally
        LBitmap.Free;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TACLSkinImage.SetHitTestMask(const Value: TACLSkinImageHitTestMode);
begin
  if FHitTestMask <> Value then
  begin
    FHitTestMask := Value;
    Changed;
  end;
end;

procedure TACLSkinImage.SetHitTestMaskFrameIndex(const Value: Integer);
begin
  if FHitTestMaskFrameIndex <> Value then
  begin
    FHitTestMaskFrameIndex := Value;
    Changed;
  end;
end;

procedure TACLSkinImage.SetLayout(AValue: TACLSkinImageLayout);
begin
  if AValue <> FLayout then
  begin
    FLayout := AValue;
    Changed;
  end;
end;

procedure TACLSkinImage.SetMargins(const Value: TRect);
begin
  if not EqualRect(Value, FMargins) then
  begin
    FMargins := Value;
    Changed;
  end;
end;

procedure TACLSkinImage.SetSizingMode(const Value: TACLSkinImageSizingMode);
begin
  if FSizingMode <> Value then
  begin
    FSizingMode := Value;
    Changed;
  end;
end;

procedure TACLSkinImage.SetStretchMode(const Value: TACLStretchMode);
begin
  if FStretchMode <> Value then
  begin
    FStretchMode := Value;
    Changed;
  end;
end;

procedure TACLSkinImage.SetTiledAreas(const Value: TACLSkinImageTiledAreas);
begin
  if not TiledAreas.Compare(Value) then
  begin
    FTiledAreas := Value;
    Changed;
  end;
end;

procedure TACLSkinImage.SetTiledAreasMode(const Value: TACLSkinImageTiledAreasMode);
begin
  if TiledAreasMode <> Value then
  begin
    FTiledAreasMode := Value;
    Changed;
  end;
end;

procedure TACLSkinImage.SwapLayout;
const
  SwapLayout: array[TACLSkinImageLayout] of TACLSkinImageLayout = (ilVertical, ilHorizontal);
var
  LFrame: Integer;
  LTemp: PACLPixel32Array;
  LTempFrames: Integer;
  LTempSize: Integer;
  LTempState: TACLSkinImageBitsState;
  LTempStride: Integer;
begin
  if Empty or (FrameCount = 1) then Exit;

  BeginUpdate;
  try
    CheckUnpacked;
    LTempState := FBitsState;
    LTempFrames := FrameCount;
    LTempSize := BitCount * SizeOf(TACLPixel32);
    LTemp := AllocMem(LTempSize);
    try
      if Layout = ilVertical then
      begin
        LTempStride := Width{=FrameWidth} * FrameCount;
        for LFrame := 0 to FrameCount - 1 do
          UnpackFrame(@LTemp^[LFrame * Width{=FrameWidth}], LFrame, LTempStride);
        DoCreateBits(LTempStride, FrameHeight);
        Layout := ilHorizontal;
      end
      else
      begin
        LTempStride := FrameHeight * FrameWidth;
        for LFrame := 0 to FrameCount - 1 do
          UnpackFrame(@LTemp^[LFrame * LTempStride], LFrame, FrameWidth);
        DoCreateBits(FrameWidth, FrameHeight * FrameCount);
        Layout := ilVertical;
      end;
      FBitsState := LTempState;
      FrameCount := LTempFrames;
      FastMove(LTemp^, Bits^, LTempSize);
    finally
      FreeMem(LTemp, LTempSize);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLSkinImage.ReadChunkBits(AStream: TStream; ASize: Integer);
var
  AFlags: Integer;
  AHeight: Integer;
  AWidth: Integer;
begin
  AFlags := AStream.ReadInt32;
  AWidth := AStream.ReadInt32;
  AHeight := AStream.ReadInt32;

  DoCreateBits(AWidth, AHeight);
  if BitCount > 0 then
    AStream.ReadBuffer(Bits^, BitCount * SizeOf(TACLPixel32));

  FHasAlpha := TACLBoolean.From(AFlags and FLAGS_BITS_HASALPHA = FLAGS_BITS_HASALPHA);
  FBitsState := TACLSkinImageBitsState(AFlags and FLAGS_BITS_PREPARED = FLAGS_BITS_PREPARED);
end;

procedure TACLSkinImage.ReadChunkBitz(AStream: TStream; ASize: Integer);
var
  AFlags: Integer;
  AHeight: Integer;
  AWidth: Integer;
begin
  if Bits <> nil then
    raise EACLSkinImageException.Create('InvalidState');

  AFlags := AStream.ReadInt32;
  AWidth := AStream.ReadInt32;
  AHeight := AStream.ReadInt32;
  DoSetSize(AWidth, AHeight);
  if ASize > 12 then
    FDormantData := TACLSkinFrameDormantData.Create(AStream);
  FHasAlpha := TACLBoolean.From(AFlags and FLAGS_BITS_HASALPHA = FLAGS_BITS_HASALPHA);
  FBitsState := TACLSkinImageBitsState(AFlags and FLAGS_BITS_PREPARED = FLAGS_BITS_PREPARED);
{$IFDEF ACL_SKINIMAGE_COLLECT_STATS}
  Inc(FSkinImageMemoryUsageInDormant, BitCount * SizeOf(TACLPixel32));
  Inc(FSkinImageMemoryCompressed, FDormantData.DataSize);
  Inc(FSkinImageDormantCount);
{$ENDIF}
end;

procedure TACLSkinImage.ReadChunkDraw(AStream: TStream);
var
  LFlags: Integer;
begin
  LFlags := AStream.ReadInt32;
  AllowColoration := LFlags and FLAGS_DRAW_ALLOWCOLORATION = FLAGS_DRAW_ALLOWCOLORATION;
  StretchMode := TACLStretchMode(AStream.ReadByte);

  if LFlags and FLAGS_DRAW_SIZING_BY_MARGINS <> 0 then
    SizingMode := ismMargins
  else if LFlags and FLAGS_DRAW_SIZING_BY_TILEDAREAS <> 0 then
    SizingMode := ismTiledAreas
  else
    SizingMode := ismDefault;
end;

procedure TACLSkinImage.ReadChunkFrameInfo(AStream: TStream; ASize: Integer);
var
  I: Integer;
begin
  HitTestMask := TACLSkinImageHitTestMode(AStream.ReadByte);
  HitTestMaskFrameIndex := AStream.ReadInt32;

  SetLength(FFrameInfo, FrameCount);
  SetLength(FFrameInfoContent, FrameCount);

  for I := 0 to FrameCount - 1 do
    FFrameInfo[I] := AStream.ReadInt32;

  if ASize > 1 + 4 + 4 * FrameCount then
  begin
    for I := 0 to FrameCount - 1 do
      FFrameInfoContent[I] := AStream.ReadInt32;
  end
  else
  begin
    for I := 0 to FrameCount - 1 do
      FFrameInfoContent[I] := FFrameInfo[I];
  end;
  FFrameInfoIsValid := True;
end;

procedure TACLSkinImage.ReadChunkLayout(AStream: TStream);
const
  LayoutMap: array[Boolean] of TACLSkinImageLayout = (ilHorizontal, ilVertical);
  TileMap: array[Boolean] of TACLSkinImageTiledAreasMode = (tpmHorizontal, tpmVertical);
var
  ATiledAreas: TACLSkinImageTiledAreas;
begin
  Layout := LayoutMap[AStream.ReadBoolean];
  FrameCount := AStream.ReadInt32;
  Margins := AStream.ReadRect;
  ContentOffsets := AStream.ReadRect;

  TiledAreasMode := TileMap[AStream.ReadBoolean];
  AStream.ReadBuffer(ATiledAreas{%H-}, SizeOf(ATiledAreas));
  TiledAreas := ATiledAreas;
end;

procedure TACLSkinImage.WriteChunkBits(AStream: TStream; var AChunkCount: Integer);
var
  LFlags: Integer;
  LPosition: Int64;
begin
  if BitCount = 0 then Exit;

  LFlags := 
    IfThen(HasAlpha, FLAGS_BITS_HASALPHA) or
    IfThen(BitsState = ibsPremultiplied, FLAGS_BITS_PREPARED);

  if FSkinImageCompressionLevel = TCompressionlevel.clNone then
  begin
    CheckUnpacked;
    AStream.BeginWriteChunk(CHUNK_BITS, LPosition);
    AStream.WriteInt32(LFlags);
    AStream.WriteInt32(Width);
    AStream.WriteInt32(Height);
    AStream.WriteBuffer(Bits^, BitCount * SizeOf(TACLPixel32));
    AStream.EndWriteChunk(LPosition);
    Inc(AChunkCount);
  end
  else
  begin
    AStream.BeginWriteChunk(CHUNK_BITZ, LPosition);
    AStream.WriteInt32(LFlags);
    AStream.WriteInt32(Width);
    AStream.WriteInt32(Height);

    if FDormantData <> nil then
      FDormantData.SaveToStream(AStream)
    else
      with CompressData do
      try
        SaveToStream(AStream);
      finally
        Free;
      end;

    AStream.EndWriteChunk(LPosition);
    Inc(AChunkCount);
  end;
end;

procedure TACLSkinImage.WriteChunkDraw(AStream: TStream; var AChunkCount: Integer);
var
  LPosition: Int64;
begin
  AStream.BeginWriteChunk(CHUNK_DRAW, LPosition);
  AStream.WriteInt32(
    IfThen(AllowColoration, FLAGS_DRAW_ALLOWCOLORATION) or
    IfThen(SizingMode = ismMargins, FLAGS_DRAW_SIZING_BY_MARGINS) or
    IfThen(SizingMode = ismTiledAreas, FLAGS_DRAW_SIZING_BY_TILEDAREAS));
  AStream.WriteByte(Ord(StretchMode));
  AStream.EndWriteChunk(LPosition);
  Inc(AChunkCount);
end;

procedure TACLSkinImage.WriteChunkFrameInfo(AStream: TStream; var AChunkCount: Integer);
var
  LPosition: Int64;
  I: Integer;
begin
  if FFrameInfoIsValid then
  begin
    AStream.BeginWriteChunk(CHUNK_FRAMEINFO, LPosition);
    AStream.WriteByte(Ord(HitTestMask));
    AStream.WriteInt32(HitTestMaskFrameIndex);
    for I := 0 to FrameCount - 1 do
      AStream.WriteInt32(FFrameInfo[I]);
    for I := 0 to FrameCount - 1 do
      AStream.WriteInt32(FFrameInfoContent[I]);
    AStream.EndWriteChunk(LPosition);
  end
  else
  begin
    AStream.BeginWriteChunk(CHUNK_FRAME, LPosition);
    AStream.WriteByte(Ord(HitTestMask));
    AStream.WriteInt32(HitTestMaskFrameIndex);
    AStream.EndWriteChunk(LPosition);
  end;
  Inc(AChunkCount);
end;

procedure TACLSkinImage.WriteChunkLayout(AStream: TStream; var AChunkCount: Integer);
var
  LPosition: Int64;
begin
  AStream.BeginWriteChunk(CHUNK_LAYOUT, LPosition);
  AStream.WriteBoolean(Layout = ilVertical);
  AStream.WriteInt32(FrameCount);
  AStream.WriteRect(Margins);
  AStream.WriteRect(ContentOffsets);
  AStream.WriteBoolean(TiledAreasMode = tpmVertical);
  AStream.WriteBuffer(TiledAreas, SizeOf(TACLSkinImageTiledAreas));
  AStream.EndWriteChunk(LPosition);
  Inc(AChunkCount);
end;

procedure TACLSkinImage.ReleaseHandle;
begin
  if FBits <> nil then
  try
  {$IFDEF ACL_SKINIMAGE_COLLECT_STATS}
    Dec(FSkinImageMemoryUsage, BitCount * SizeOf(TACLPixel32));
  {$ENDIF}
  {$IFDEF ACL_SKINIMAGE_CACHE_HBITMAP}
    DeleteObject(FHandle);
    FHandle := 0;
  {$ELSE}
    FreeMem(FBits);
  {$ENDIF}
  finally
    FBits := nil;
  end;
end;

procedure TACLSkinImage.UnpackFrame(ATarget: PACLPixel32; AFrame, ATargetStride: Integer);
var
  LBytesPerRow: Integer;
  LFrameRect: TRect;
  LSource: PACLPixel32;
begin
  CheckUnpacked;
  LFrameRect := FrameRect[AFrame];
  LBytesPerRow := LFrameRect.Width * SizeOf(TACLPixel32);
  LSource := @Bits[LFrameRect.Left + LFrameRect.Top * Width];
  if (Layout = ilVertical) and (ATargetStride = LFrameRect.Width) then
    FastMove(LSource^, ATarget^, LBytesPerRow * LFrameRect.Height)
  else // general way
    while LFrameRect.Top < LFrameRect.Bottom do
    begin
      FastMove(LSource^, ATarget^, LBytesPerRow);
      Inc(ATarget, ATargetStride);
      Inc(LFrameRect.Top);
      Inc(LSource, Width);
    end;
end;

{ TAnalyzer }

class function TAnalyzer.AnalyzeResultToState(
  var AAlpha: DWORD; var AColor: DWORD): TACLSkinImageFrameState;
begin
  if AAlpha = INVALID_VALUE then
    Exit(TACLSkinImageFrameState.SEMITRANSPARENT);
  if AAlpha = 0 then
    Exit(TACLSkinImageFrameState.TRANSPARENT);
  if AColor <> INVALID_VALUE then
  begin
    TACLColors.Unpremultiply(TACLPixel32(AColor));
    Exit(AColor);
  end;
  if AAlpha < MaxByte then
    Result := TACLSkinImageFrameState.SEMITRANSPARENT
  else
    Result := TACLSkinImageFrameState.OPAQUE;
end;

class procedure TAnalyzer.RecoveryAlpha(
  Q: PACLPixel32; ACount: Integer; var AHasSemitransparecy: Boolean);
begin
  if Q = nil then
    Exit;
  while ACount > 0 do
  begin
    if TACLColors.IsMask(Q^) then
    begin
      AHasSemitransparecy := True;
      TACLColors.Flush(Q^);
    end
    else
      Q^.A := $FF;

    Dec(ACount);
    Inc(Q);
  end;
end;

class function TAnalyzer.Run(Q: PACLPixel32; ACount: Integer): TACLSkinImageFrameState;
var
  LAlpha: DWORD;
  LColor: DWORD;
begin
  if (Q = nil) or (ACount = 0) then
    Exit(TACLSkinImageFrameState.TRANSPARENT);

  LAlpha := Q[0].A;
  LColor := DWORD(Q[0]);
  RunCore(Q, ACount, LAlpha, LColor);
  Result := AnalyzeResultToState(LAlpha, LColor);
end;

class function TAnalyzer.Run(Q: PACLPixel32;
  APart: TRect; AImageWidth: Integer): TACLSkinImageFrameState;
var
  LAlpha: DWORD;
  LColor: DWORD;
  LFirst: PACLPixel32;
begin
  if (Q = nil) or APart.IsEmpty then
    Exit(TACLSkinImageFrameState.TRANSPARENT);

  LFirst := @Q[APart.Left + APart.Top * AImageWidth];
  LColor := DWORD(LFirst^);
  LAlpha := LFirst^.A;
  while APart.Top < APart.Bottom do
  begin
    RunCore(LFirst, APart.Width, LAlpha, LColor);
    if LAlpha = INVALID_VALUE then Break;
    Inc(LFirst, AImageWidth);
    Inc(APart.Top);
  end;
  Result := AnalyzeResultToState(LAlpha, LColor);
end;

class procedure TAnalyzer.RunCore(
  AColors: PACLPixel32; ACount: Integer; var AAlpha, AColor: DWORD);
begin
  while ACount > 0 do
  begin
    if AAlpha <> AColors^.A then
    begin
      AAlpha := INVALID_VALUE;
      Break;
    end;
    if AColor <> PDWORD(AColors)^ then
      AColor := INVALID_VALUE;
    Inc(AColors);
    Dec(ACount);
  end;
end;
{$ENDREGION}

{ TRenderer }

class constructor TRenderer.Create;
begin
  FLock := TACLCriticalSection.Create(nil, 'SkinImageRender');
{$IFDEF MSWINDOWS}
  ZeroMemory(@FFunc, SizeOf(FFunc));
  FFunc.BlendOp := AC_SRC_OVER;
  FFunc.AlphaFormat := AC_SRC_ALPHA;
{$ENDIF}
{$IFDEF ACL_CAIRO}
  FCairo := TACLCairoRender.Create;
{$ENDIF}
end;

class destructor TRenderer.Destroy;
begin
  FreeAndNil(FLock);
{$IFDEF MSWINDOWS}
  ZeroMemory(@FMemBmpInfo, SizeOf(FMemBmpInfo));
  FMemBmpBits := nil;
  DeleteObject(FMemBmp);
  DeleteDC(FMemDC);
  FMemBmp := 0;
  FMemDC := 0;
{$ENDIF}
{$IFDEF ACL_CAIRO}
  FreeMemAndNil(FCairoBits);
  FreeAndNil(FCairo);
{$ENDIF}
end;

{$IFDEF MSWINDOWS}
class procedure TRenderer.doWinDraw(const R, SrcR: TRect);
begin
  if not (R.IsEmpty or SrcR.IsEmpty) then
    AlphaBlend(FDstCanvas.Handle,
      R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top, FMemDC,
      SrcR.Left, SrcR.Top, SrcR.Right - SrcR.Left, SrcR.Bottom - SrcR.Top, FFunc);
end;

class procedure TRenderer.doWinDrawTile(const R, SrcR: TRect);
var
  LClipping: TRegionHandle;
  LLayer: TACLDib;
  W, H: Integer;
  X, Xi, XCount: Integer;
  Y, Yi, YCount: Integer;
begin
  if R.IsEmpty or SrcR.IsEmpty then
    Exit;

  W := SrcR.Right - SrcR.Left;
  H := SrcR.Bottom - SrcR.Top;

  XCount := acCalcPatternCount(R.Width, W);
  YCount := acCalcPatternCount(R.Height, H);

  if XCount * YCount > 10 then
  begin
    LLayer := TACLDib.Create(R);
    try
      acTileBlt(LLayer.Handle, FMemDC, LLayer.ClientRect, SrcR);
      AlphaBlend(FDstCanvas.Handle, R.Left, R.Top, R.Width, R.Height,
        LLayer.Handle, 0, 0, LLayer.Width, LLayer.Height, FFunc);
    finally
      LLayer.Free;
    end;
  end
  else
    if acStartClippedDraw(FDstCanvas, R, LClipping) then
    try
      Y := R.Top;
      for Yi := 1 to YCount do
      begin
        X := R.Left;
        for Xi := 1 to XCount do
        begin
          AlphaBlend(FDstCanvas.Handle, X, Y, W, H, FMemDC, SrcR.Left, SrcR.Top, W, H, FFunc);
          Inc(X, W);
        end;
        Inc(Y, H);
      end;
    finally
      acEndClippedDraw(FDstCanvas, LClipping);
    end;
end;

class procedure TRenderer.doWinDrawOpaque(const ATarget, ASource: TRect);
begin
  if ATarget.IsEmpty or ASource.IsEmpty then
    Exit;
  if FImage.StretchMode = isTile then
    acTileBlt(FDstCanvas.Handle, FMemDC, ATarget, ASource)
  else
    acStretchBlt(FDstCanvas.Handle, FMemDC, ATarget, ASource);
end;

class procedure TRenderer.doWinFill(const ATarget: TRect; AColor: TAlphaColor);
begin
  acFillRect(FDstCanvas, ATarget, AColor);
end;

class procedure TRenderer.doWinFinish;
begin
  SelectObject(FMemDC, FPrevBmp);
  doInit(nil, nil, nil);
  FDstCanvas := nil;
  FImage := nil;
  FLock.Leave;
end;

{$ENDIF}

class procedure TRenderer.doInit(
  AExitProc: TThreadMethod; AFillProc: TFillPart; ADrawProc: TDrawPart);
begin
  Finish := AExitProc;
  FillPart := AFillProc;
  DrawPart := ADrawProc;
end;

class procedure TRenderer.Start(AImage: TACLSkinImage;
  ACanvas: TCanvas; AFrameIndex: Integer; AAlpha: Byte);
begin
  FLock.Enter;
  FImage := AImage;
  FFrame := AFrameIndex;
  FFrameRect := FImage.FrameRect[FFrame];
{$IFDEF MSWINDOWS}
  FDstCanvas := ACanvas;
  if FMemDC = 0 then
    FMemDC := CreateCompatibleDC(0);
  FFunc.SourceConstantAlpha := AAlpha;

  {$IFDEF ACL_SKINIMAGE_CACHE_HBITMAP}
    FPrevBmp := SelectObject(FMemDC, AImage.Handle);
  {$ELSE}
    if (FMemBmp = 0) or (FMemBmpBits = nil) or
      (FFrameRect.Height > -FMemBmpInfo.bmiHeader.biHeight) or
      (FFrameRect.Width > FMemBmpInfo.bmiHeader.biWidth) then
    begin
      DeleteObject(FMemBmp);
      FMemBmpBits := nil;
      FMemBmp := 0;
      acInitBitmap32Info(FMemBmpInfo, FFrameRect.Width, FFrameRect.Height);
      FMemBmp := CreateDIBSection(0, FMemBmpInfo, DIB_RGB_COLORS, FMemBmpBits, 0, 0);
      if (FMemBmp = 0) or (FMemBmpBits = nil) then
        raise EACLSkinImageException.CreateFmt(
          sErrorCannotCreateImage, [FFrameRect.Width, FFrameRect.Height]);
    end;

    FFrameRect.Offset(-FFrameRect.Left, -FFrameRect.Top);
    FImage.UnpackFrame(FMemBmpBits, FFrame, FMemBmpInfo.bmiHeader.biWidth);
    FPrevBmp := SelectObject(FMemDC, FMemBmp);
  {$ENDIF}

  if (AAlpha = 255) and FImage.FrameInfo[AFrameIndex].IsOpaque then
    doInit(doWinFinish, doWinFill, doWinDrawOpaque)
  else if FImage.StretchMode = isTile then
    doInit(doWinFinish, doWinFill, doWinDrawTile)
  else
    doInit(doWinFinish, doWinFill, doWinDraw);
{$ELSE}
  FAlpha := AAlpha / 255;
  FCairo.BeginPaint(ACanvas);
  doCairoInit;
{$ENDIF}
end;

{$IFDEF ACL_CAIRO}
class procedure TRenderer.Start(AImage: TACLSkinImage;
  ACairo: Pcairo_t; AFrameIndex: Integer; AAlpha: Byte);
begin
  FLock.Enter;
  FImage := AImage;
  FAlpha := AAlpha / 255;
  FFrame := AFrameIndex;
  FFrameRect := FImage.FrameRect[FFrame];
  FCairo.BeginPaint(ACairo);
  doCairoInit;
end;

class procedure TRenderer.doCairoInit;
var
  LRequired: Integer;
begin
  doInit(doCairoFinish, doCairoFill, doCairoDraw);
  if (FImage.Width >= MAXSHORT) or (FImage.Height >= MAXSHORT) then
  begin
    LRequired := FFrameRect.Width * FFrameRect.Height * SizeOf(TACLPixel32);
    if LRequired > FCairoBitsSize then
    begin
      FCairoBitsSize := LRequired;
      ReallocMem(FCairoBits, FCairoBitsSize);
    end;
    FImage.UnpackFrame(FCairoBits, FFrame, FFrameRect.Width);
    FSourceSurface := cairo_create_surface(FCairoBits, FFrameRect.Width, FFrameRect.Height);
    FFrameRect.Offset(-FFrameRect.Left, -FFrameRect.Top);
  end
  else
    FSourceSurface := cairo_create_surface(FImage.Bits, FImage.Width, FImage.Height);
end;

class procedure TRenderer.doCairoDraw(const ATarget, ASource: TRect);
begin
  if not (ATarget.IsEmpty or ASource.IsEmpty) then
    FCairo.FillSurface(ATarget, ASource, FSourceSurface, FAlpha, FImage.StretchMode = isTile);
end;

class procedure TRenderer.doCairoFill(const ATarget: TRect; AColor: TAlphaColor);
begin
  FCairo.FillRectangle(ATarget.Left, ATarget.Top, ATarget.Right, ATarget.Bottom, AColor);
end;

class procedure TRenderer.doCairoFinish;
begin
  FCairo.EndPaint;
  cairo_surface_destroy(FSourceSurface);
  doInit(nil, nil, nil);
  FSourceSurface := nil;
  FImage := nil;
  FLock.Leave;
end;
{$ENDIF}

class procedure TRenderer.Draw(ARect: TRect);

  procedure DoDrawWithMargins(const ATarget, ASource: TRect; AContentState: TACLSkinImageFrameState);
  var
    LSourceParts: TACLMarginPartBounds;
    LTargetParts: TACLMarginPartBounds;
  begin
    acCalcPartBounds(LTargetParts, FImage.Margins, ATarget, ASource, FImage.StretchMode);
    acCalcPartBounds(LSourceParts, FImage.Margins, ASource, ASource, FImage.StretchMode);

    DrawPart(LTargetParts[mzLeftTop], LSourceParts[mzLeftTop]);
    DrawPart(LTargetParts[mzLeft], LSourceParts[mzLeft]);
    DrawPart(LTargetParts[mzLeftBottom], LSourceParts[mzLeftBottom]);

    DrawPart(LTargetParts[mzTop], LSourceParts[mzTop]);
    DrawPart(LTargetParts[mzBottom], LSourceParts[mzBottom]);

    DrawPart(LTargetParts[mzRight], LSourceParts[mzRight]);
    DrawPart(LTargetParts[mzRightTop], LSourceParts[mzRightTop]);
    DrawPart(LTargetParts[mzRightBottom], LSourceParts[mzRightBottom]);

    if not AContentState.IsTransparent then
    begin
      if AContentState.IsColor then
        FillPart(LTargetParts[mzClient], TAlphaColor(AContentState))
      else
        DrawPart(LTargetParts[mzClient], LSourceParts[mzClient]);
    end;
  end;

  procedure DoDrawTiledAreas(const ATarget: TRect);
  var
    I: TACLSkinImageTiledAreasPart;
    S, D: TACLSkinImageTiledAreasPartBounds;
  begin
    acCalculateTiledAreas(FFrameRect, FImage.TiledAreas,
      FImage.FrameWidth, FImage.FrameHeight, FImage.TiledAreasMode, S);
    acCalculateTiledAreas(ATarget, FImage.TiledAreas,
      FImage.FrameWidth, FImage.FrameHeight, FImage.TiledAreasMode, D);
    for I := Low(TACLSkinImageTiledAreasPart) to High(TACLSkinImageTiledAreasPart) do
      DrawPart(D[I], S[I]);
  end;

begin
  case FImage.ActualSizingMode of
    ismMargins:
      DoDrawWithMargins(ARect, FFrameRect, FImage.FFrameInfoContent[FFrame]);
    ismTiledAreas:
      DoDrawTiledAreas(ARect);
  else {ismDefault}
    if FImage.StretchMode = isCenter then
    begin
      ARect.CenterHorz(FImage.FrameWidth);
      ARect.CenterVert(FImage.FrameHeight);
    end;
    DrawPart(ARect, FFrameRect);
  end;
end;

end.
