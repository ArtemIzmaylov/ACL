{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*              SkinImage Class              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.SkinImage;

{$I ACL.Config.inc}
{$MINENUMSIZE 1}

interface

uses
  Winapi.Windows,
  // System
  System.Classes,
  System.Generics.Collections,
  System.Math,
  System.SysUtils,
  System.UITypes,
  System.ZLib,
  // VCL
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Images,
  ACL.Hashes,
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

    class function FormRect(const R: TRect): TACLSkinImageTiledAreas; static;
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

  { TACLSkinImageBitsStorage }

  TACLSkinImageBitsStorage = class
  public
    Data: Pointer;
    DataSize: Cardinal;
    HasAlpha: TACLBoolean;
    State: TACLSkinImageBitsState;

    constructor Create; overload;
    constructor Create(ABits: PRGBQuadArray; ACount: Integer;
      AHasAlpha: TACLBoolean; AState: TACLSkinImageBitsState); overload;
    constructor Create(AStream: TStream); overload;
    destructor Destroy; override;
    function Clone: TACLSkinImageBitsStorage;
    function Equals(Obj: TObject): Boolean; override;
    function GetHashCode: Integer; override;
    procedure Restore(ABits: PRGBQuadArray; ACount: Integer;
      out AHasAlpha: TACLBoolean; out AState: TACLSkinImageBitsState);
    procedure SaveToStream(AStream: TStream);
  end;

  { TACLSkinImage }

  TACLSkinImage = class(TACLUnknownPersistent, IACLColorSchema)
  strict private const
  {$REGION 'Private consts'}
    CHUNK_BITS      = $73746962; // bits
    CHUNK_BITZ      = $7A746962; // bitz - compressed bits
    CHUNK_DRAW      = $77617264; // draw
    CHUNK_FRAMEINFO = $6D616669; // frmi
    CHUNK_LAYOUT    = $7479616C; // layt

    FLAGS_BITS_HASALPHA = $1;
    FLAGS_BITS_PREPARED = $2;

    FLAGS_DRAW_ALLOWCOLORATION = $1;
    FLAGS_DRAW_SIZING_BY_MARGINS   = $2;
    FLAGS_DRAW_SIZING_BY_TiledAreas = $4;
  {$ENDREGION}
  public const
    HitTestThreshold = 128;
  strict private
    FAllowColoration: Boolean;
    FBitCount: Integer;
    FBits: PRGBQuadArray;
    FBitsState: TACLSkinImageBitsState;
    FContentOffsets: TRect;
    FDormantData: TACLSkinImageBitsStorage;
    FFramesCount: Integer;
    FFramesInfo: TACLSkinImageFrameStateArray;
    FFramesInfoContent: TACLSkinImageFrameStateArray;
    FFramesInfoIsValid: Boolean;
    FHandle: HBITMAP;
    FHasAlpha: TACLBoolean;
    FHeight: Integer;
    FHitTestMask: TACLSkinImageHitTestMode;
    FHitTestMaskFrameIndex: Integer;
    FLayout: TACLSkinImageLayout;
    FMargins: TRect;
    FSizingMode: TACLSkinImageSizingMode;
    FStretchMode: TACLStretchMode;
    FTiledAreas: TACLSkinImageTiledAreas;
    FTiledAreasMode: TACLSkinImageTiledAreasMode;
    FUpdateCount: Integer;
    FWidth: Integer;

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
    FChangeListeners: TACLList<TNotifyEvent>;

    procedure Changed;
    procedure CheckFrameIndex(var AIndex: Integer); inline;
    procedure CheckFramesInfo;
    procedure CheckUnpacked;
    procedure ClearData; virtual;

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
    property Bits: PRGBQuadArray read FBits;
    property BitsState: TACLSkinImageBitsState read FBitsState;
    property Handle: HBITMAP read FHandle;
  public
    constructor Create; overload; virtual;
    constructor Create(AChangeEvent: TNotifyEvent); overload;
    destructor Destroy; override;
    procedure Assign(AObject: TObject); reintroduce;
    procedure AssignParams(ASkinImage: TACLSkinImage);
    procedure Clear;
    procedure CheckBitsState(ARequiredState: TACLSkinImageBitsState);
    procedure Dormant; virtual;
    function Equals(Obj: TObject): Boolean; override;
    function GetHashCode: Integer; override;
    function HasFrame(AIndex: Integer): Boolean; inline;
    // Lock
    procedure BeginUpdate;
    procedure CancelUpdate;
    procedure EndUpdate;
    // IACLColorSchema
    procedure ApplyColorSchema(const AValue: TACLColorSchema);
    // Drawing
    procedure Draw(DC: HDC; const R: TRect; AFrameIndex: Integer = 0; AAlpha: Byte = MaxByte); overload;
    procedure Draw(DC: HDC; const R: TRect; AFrameIndex: Integer; AEnabled: Boolean; AAlpha: Byte = MaxByte); overload;
    procedure Draw(DC: HDC; const R: TRect; AFrameIndex1, AFrameIndex2, AMixAlpha: Integer); overload;
    procedure DrawClipped(DC: HDC; const AClipRect, R: TRect; AFrameIndex: Integer; AAlpha: Byte = MaxByte);
    // HitTest
    function HitTest(const ABounds: TRect; X, Y: Integer): Boolean;
    function HitTestCore(const ABounds: TRect; AFrameIndex, X, Y: Integer): Boolean;
    // Pixels
    function GetPixel(X, Y: Integer; out APixel: TRGBQuad): Boolean;
    // Listeners
    procedure ListenerAdd(AEvent: TNotifyEvent);
    procedure ListenerRemove(AEvent: TNotifyEvent);
    // I/O
    procedure LoadFromBitmap(ABitmap: TBitmap);
    procedure LoadFromBits(ABits: PRGBQuad; AWidth, AHeight: Integer);
    procedure LoadFromFile(const AFileName: UnicodeString);
    procedure LoadFromResource(AInstance: HINST; const AName: UnicodeString; AResRoot: PWideChar);
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToBitmap(ABitmap: TBitmap);
    procedure SaveToFile(const AFileName: UnicodeString); overload;
    procedure SaveToFile(const AFileName: UnicodeString; AFormat: TACLImageFormatClass); overload;
    procedure SaveToStream(AStream: TStream); overload; virtual;
    procedure SaveToStream(AStream: TStream; AFormat: TACLImageFormatClass); overload;
    //
    property ActualSizingMode: TACLSkinImageSizingMode read GetActualSizingMode;
    property ClientRect: TRect read GetClientRect;
    property Empty: Boolean read GetEmpty;
    property HasAlpha: Boolean read GetHasAlpha;
    property Height: Integer read FHeight;
    property Width: Integer read FWidth;
    //
    property FrameCount: Integer read FFramesCount write SetFrameCount;
    property FrameInfo[Index: Integer]: TACLSkinImageFrameState read GetFrameInfo;
    property FrameRect[Index: Integer]: TRect read GetFrameRect;
    property FrameSize: TSize read GetFrameSize write SetFrameSize;
    property FrameHeight: Integer read GetFrameHeight;
    property FrameWidth: Integer read GetFrameWidth;
    //
    property AllowColoration: Boolean read FAllowColoration write SetAllowColoration;
    property ContentOffsets: TRect read FContentOffsets write SetContentOffsets;
    property HitTestMask: TACLSkinImageHitTestMode read FHitTestMask write SetHitTestMask;
    property HitTestMaskFrameIndex: Integer read FHitTestMaskFrameIndex write SetHitTestMaskFrameIndex;
    property Layout: TACLSkinImageLayout read FLayout write SetLayout;
    //
    property Margins: TRect read FMargins write SetMargins;
    property SizingMode: TACLSkinImageSizingMode read FSizingMode write SetSizingMode;
    property StretchMode: TACLStretchMode read FStretchMode write SetStretchMode;
    property TiledAreas: TACLSkinImageTiledAreas read FTiledAreas write SetTiledAreas;
    property TiledAreasMode: TACLSkinImageTiledAreasMode read FTiledAreasMode write SetTiledAreasMode;
  end;

const
  NullTileArea: TACLSkinImageTiledAreas = (Part1TileStart: 0; Part1TileWidth: 0; Part2TileStart: 0; Part2TileWidth: 0);

var
  FSkinImageCompressionLevel: TZCompressionLevel = zcFastest;
{$IFDEF ACL_DEBUG_SKINIMAGE_STAT}
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
  System.Types,
  // ACL
  ACL.FastCode,
  ACL.Graphics.Ex,
  ACL.Graphics.Ex.Gdip,
  ACL.Math,
  ACL.Threading,
  ACL.Utils.Stream;

type

  { TACLSkinImageAnalyzer }

  TACLSkinImageAnalyzer = class
  strict private const
    INVALID_VALUE = $010203;
  strict private
    class procedure AnalyzeCore(Q: PRGBQuad; Count: Integer; var AAlpha: DWORD; var AColor: DWORD); inline;
    class function AnalyzeResultToState(var AAlpha: DWORD; var AColor: DWORD): TACLSkinImageFrameState; inline;
  public
    class function Analyze(Q: PRGBQuad; ACount: Integer): TACLSkinImageFrameState;
    class function AnalyzeFrame(Q: PRGBQuadArray; const AFrameRect: TRect; AImageWidth: Integer): TACLSkinImageFrameState;
    class procedure RecoveryAlpha(Q: PRGBQuad; ACount: Integer; var AHasSemiTransparentPixels: Boolean);
  end;

  { TACLSkinImageRenderer }

  TACLSkinImageRenderer = class(TObject)
  strict private
    FAlpha: Byte;
    FBitsChanged: Boolean;
    FClientRect: TRect;
    FDestDC: HDC;
    FFunc: TBlendFunction;
    FLock: TACLCriticalSection;
    FMemDC: HDC;
    FOldBmp: HBITMAP;
    FOpacue: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure BitsChanged;
    procedure DrawBegin(DC: HDC; const R: TRect; const AAlpha: Byte; AHandle: HBITMAP; AHasAlpha: Boolean);
    procedure Draw(const R, ASource: TRect; AIsTileMode: Boolean);
    procedure DrawEnd;
    //
    property Alpha: Byte read FAlpha;
    property ClientRect: TRect read FClientRect;
    property DestDC: HDC read FDestDC;
  end;

var
  FRenderer: TACLSkinImageRenderer;
{$IFNDEF ACL_DEBUG_SKINIMAGE_STAT}
  FSkinImageCount: Integer = 0;
{$ENDIF}

procedure acCalculateTiledAreas(const R: TRect; const AParams: TACLSkinImageTiledAreas;
  ATextureWidth, ATextureHeight: Integer; ATiledAreasMode: TACLSkinImageTiledAreasMode;
  out AParts: TACLSkinImageTiledAreasPartBounds);

  procedure CalculateHorizontalMode;
  begin
    AParts[tpzPart1Fixed] := R;
    AParts[tpzPart1Fixed].Right := AParts[tpzPart1Fixed].Left + AParams.Part1TileStart;

    AParts[tpzPart2Fixed] := R;
    AParts[tpzPart2Fixed].Left := R.Right - (ATextureWidth - AParams.Part2TileWidth - AParams.Part2TileStart);

    Dec(ATextureWidth, AParams.Part1TileStart);
    Dec(ATextureWidth, acRectWidth(AParts[tpzPart2Fixed]));
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
          AParts[tpzCenter] := acRectCenterHorizontally(AParts[tpzCenter], ATextureWidth);
        end;
    end;
    AParts[tpzPart1Tile] := R;
    AParts[tpzPart1Tile].Left := AParts[tpzPart1Fixed].Right;
    AParts[tpzPart1Tile].Right := AParts[tpzCenter].Left;

    AParts[tpzPart2Tile] := R;
    AParts[tpzPart2Tile].Left := AParts[tpzCenter].Right;
    AParts[tpzPart2Tile].Right := AParts[tpzPart2Fixed].Left;
  end;

  procedure CalculateVerticalMode;
  begin
    AParts[tpzPart1Fixed] := R;
    AParts[tpzPart1Fixed].Bottom := AParts[tpzPart1Fixed].Top + AParams.Part1TileStart;

    AParts[tpzPart2Fixed] := R;
    AParts[tpzPart2Fixed].Top := R.Bottom - (ATextureHeight - AParams.Part2TileWidth - AParams.Part2TileStart);

    Dec(ATextureHeight, AParams.Part1TileStart);
    Dec(ATextureHeight, acRectHeight(AParts[tpzPart2Fixed]));
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
          AParts[tpzCenter] := acRectCenterVertically(AParts[tpzCenter], ATextureHeight);
        end;
    end;
    AParts[tpzPart1Tile] := R;
    AParts[tpzPart1Tile].Top := AParts[tpzPart1Fixed].Bottom;
    AParts[tpzPart1Tile].Bottom := AParts[tpzCenter].Top;

    AParts[tpzPart2Tile] := R;
    AParts[tpzPart2Tile].Top := AParts[tpzCenter].Bottom;
    AParts[tpzPart2Tile].Bottom := AParts[tpzPart2Fixed].Top;
  end;

begin
  if ATiledAreasMode = tpmHorizontal then
    CalculateHorizontalMode
  else
    CalculateVerticalMode;
end;

procedure acAlphaBlend(DC, MemDC: HDC; const R, SrcR: TRect; const AFunc: TBlendFunction); inline;
begin
  AlphaBlend(DC, R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top, MemDC,
    SrcR.Left, SrcR.Top, SrcR.Right - SrcR.Left, SrcR.Bottom - SrcR.Top, AFunc);
end;

procedure acAlphaBlendTile(DC, MemDC: HDC; const R, SrcR: TRect; const AFunc: TBlendFunction);
var
  AClipRgn: Integer;
  ALayer: TACLBitmapLayer;
  R1: TRect;
  W, H: Integer;
  X, Y, XCount, YCount: Integer;
begin
  W := SrcR.Right - SrcR.Left;
  H := SrcR.Bottom - SrcR.Top;
  R1 := acRectSetHeight(R, H);
  XCount := acCalcPatternCount(R.Right - R.Left, W);
  YCount := acCalcPatternCount(R.Bottom - R.Top, H);

  if XCount * YCount > 10 then
  begin
    ALayer := TACLBitmapLayer.Create(R);
    try
      acTileBlt(ALayer.Handle, MemDC, ALayer.ClientRect, SrcR);
      acAlphaBlend(DC, ALayer.Handle, R, ALayer.ClientRect, AFunc);
    finally
      ALayer.Free;
    end;
  end
  else
  begin
    AClipRgn := acSaveClipRegion(DC);
    try
      acIntersectClipRegion(DC, R);
      for Y := 1 to YCount do
      begin
        R1.Left := R.Left;
        R1.Right := R.Left + W;
        for X := 1 to XCount do
        begin
          acAlphaBlend(DC, MemDC, R1, SrcR, AFunc);
          Inc(R1.Left, W);
          Inc(R1.Right, W);
        end;
        Inc(R1.Top, H);
        Inc(R1.Bottom, H);
      end;
    finally
      acRestoreClipRegion(DC, AClipRgn);
    end;
  end;
end;

procedure SkinImageAdded;
begin
  Inc(FSkinImageCount);
  if FSkinImageCount = 1 then
    FRenderer := TACLSkinImageRenderer.Create;
end;

procedure SkinImageRemoved;
begin
  Dec(FSkinImageCount);
  if FSkinImageCount = 0 then
    FreeAndNil(FRenderer);
end;

function acBitsAlloc(ACount: Integer): PRGBQuadArray; inline;
begin
  Result := AllocMem(ACount * SizeOf(TRGBQuad));
end;

procedure acBitsCopy(ASrc, ADst: PRGBQuadArray; ACount: Integer);
begin
  if (ASrc <> nil) and (ADst <> nil) and (ACount > 0) then
    FastMove(ASrc^, ADst^, ACount * SizeOf(TRGBQuad));
end;

function ZCompressCheck(code: Integer): Integer; overload;
begin
  Result := code;
  if code < 0 then
    raise EZCompressionError.Create(string(_z_errmsg[2 - code])) at ReturnAddress;
end;

function ZCompressCheckWithoutBufferError(code: Integer): Integer; overload;
begin
  Result := code;
  if (code < 0) and (code <> Z_BUF_ERROR) then
    raise EZCompressionError.Create(string(_z_errmsg[2 - code])) at ReturnAddress;
end;

function ZDecompressCheck(code: Integer): Integer; overload;
begin
  Result := code;
  if code < 0 then
    raise EZDecompressionError.Create(string(_z_errmsg[2 - code])) at ReturnAddress;
end;

{ TACLSkinImageTiledAreas }

function TACLSkinImageTiledAreas.Compare(const P: TACLSkinImageTiledAreas): Boolean;
begin
  Result := (P.Part1TileStart = Part1TileStart) and
    (P.Part1TileWidth = Part1TileWidth) and
    (P.Part2TileStart = Part2TileStart) and
    (P.Part2TileWidth = Part2TileWidth);
end;

class function TACLSkinImageTiledAreas.FormRect(const R: TRect): TACLSkinImageTiledAreas;
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

{ TACLSkinImageBitsStorage }

constructor TACLSkinImageBitsStorage.Create;
begin
  // do nothing
end;

constructor TACLSkinImageBitsStorage.Create(ABits: PRGBQuadArray;
  ACount: Integer; AHasAlpha: TACLBoolean; AState: TACLSkinImageBitsState);
const
  Delta = 256;
var
  AInSize: Cardinal;
  AOutSize: Cardinal;
  ZStream: TZStreamRec;
begin
  // Our own ZCompress implementation, because standard version works with Integer, not Cardinal.
  AInSize := ACount * SizeOf(TRGBQuad);
  AOutSize := MulDiv(AInSize, 3, 4);
  GetMem(Data, AOutSize);
  try
    FillChar(ZStream, SizeOf(ZStream), 0);
    ZStream.next_in := PByte(ABits);
    ZStream.next_out := Data;
    ZStream.avail_in := AInSize;
    ZStream.avail_out := AOutSize;

    ZCompressCheck(DeflateInit(ZStream, ZLevels[FSkinImageCompressionLevel]));
    try
      while ZCompressCheckWithoutBufferError(deflate(ZStream, Z_FINISH)) <> Z_STREAM_END do
      begin
        Inc(AOutSize, Delta);
        ReallocMem(Data, AOutSize);
        ZStream.next_out := PByte(Data) + ZStream.total_out;
        ZStream.avail_out := Delta;
      end;
    finally
      ZCompressCheck(deflateEnd(ZStream));
    end;

    ReallocMem(Data, ZStream.total_out);
    DataSize := ZStream.total_out;
  except
    FreeMemAndNil(Data);
    raise;
  end;
  HasAlpha := AHasAlpha;
  State := AState;
end;

constructor TACLSkinImageBitsStorage.Create(AStream: TStream);
begin
  AStream.ReadBuffer(DataSize, SizeOf(Cardinal));
  GetMem(Data, DataSize);
  AStream.ReadBuffer(Data^, DataSize);
end;

destructor TACLSkinImageBitsStorage.Destroy;
begin
  FreeMem(Data, DataSize);
  inherited;
end;

function TACLSkinImageBitsStorage.Clone: TACLSkinImageBitsStorage;
begin
  Result := TACLSkinImageBitsStorage.Create;
  Result.DataSize := DataSize;
  Result.HasAlpha := HasAlpha;
  Result.State := State;
  GetMem(Result.Data, DataSize);
  FastMove(Data^, Result.Data^, DataSize);
end;

function TACLSkinImageBitsStorage.Equals(Obj: TObject): Boolean;
begin
  Result := (Obj <> nil) and (Obj.ClassType = ClassType) and
    (DataSize = TACLSkinImageBitsStorage(Obj).DataSize) and
    (CompareMem(Data, TACLSkinImageBitsStorage(Obj).Data, DataSize));
end;

function TACLSkinImageBitsStorage.GetHashCode: Integer;
var
  AHashValue: Cardinal;
begin
  AHashValue := TACLHashCRC32.Calculate(Data, DataSize);
  Result := Integer(AHashValue);
end;

procedure TACLSkinImageBitsStorage.Restore(ABits: PRGBQuadArray;
  ACount: Integer; out AHasAlpha: TACLBoolean; out AState: TACLSkinImageBitsState);
var
  ASize: Cardinal;
  ZStream: TZStreamRec;
begin
  ASize := ACount * SizeOf(TRGBQuad);
  ZeroMemory(@ZStream, SizeOf(TZStreamRec));
  ZStream.next_in := Data;
  ZStream.avail_in := DataSize;
  ZStream.next_out := PByte(ABits);
  ZStream.avail_out := ASize;

  ZDecompressCheck(InflateInit(ZStream));
  ZDecompressCheck(inflate(ZStream, Z_NO_FLUSH));
  ZDecompressCheck(inflateEnd(ZStream));

  if ZStream.total_out <> ASize then
    raise EACLSkinImageException.Create(sErrorIncorrectDormantData);

  AHasAlpha := HasAlpha;
  AState := State;
end;

procedure TACLSkinImageBitsStorage.SaveToStream(AStream: TStream);
begin
  AStream.WriteBuffer(DataSize, SizeOf(Cardinal));
  AStream.WriteBuffer(Data^, DataSize);
end;

{ TACLSkinImage }

constructor TACLSkinImage.Create;
begin
  inherited Create;
  FAllowColoration := True;
  FChangeListeners := TACLList<TNotifyEvent>.Create;
  FFramesCount := 1;
  SkinImageAdded;
end;

constructor TACLSkinImage.Create(AChangeEvent: TNotifyEvent);
begin
  Create;
  ListenerAdd(AChangeEvent);
end;

destructor TACLSkinImage.Destroy;
begin
  ClearData;
  SkinImageRemoved;
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
  if Assigned(Bits) <> Assigned(TACLSkinImage(Obj).Bits) then
    Exit(False);
  if (BitCount <> TACLSkinImage(Obj).BitCount) then
    Exit(False);
  if FDormantData <> nil then
    Exit(FDormantData.Equals(TACLSkinImage(Obj).FDormantData));
  if Bits <> nil then
    Exit(CompareMem(Bits, TACLSkinImage(Obj).Bits, SizeOf(TRGBQuad) * BitCount));
  Result := False;
end;

function TACLSkinImage.GetHashCode: Integer;
var
  AHashValue: Cardinal;
begin
  if FDormantData <> nil then
    Result := FDormantData.GetHashCode
  else
    if Bits <> nil then
    begin
      AHashValue := TACLHashCRC32.Calculate(PByte(Bits), BitCount);
      Result := Integer(AHashValue);
    end
    else
      Result := 0;
end;

function TACLSkinImage.HasFrame(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FrameCount);
end;

procedure TACLSkinImage.BeginUpdate;
begin
  Inc(FUpdateCount);
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
  if AllowColoration and AValue.IsAssigned then
  begin
    CheckUnpacked;
    TACLColors.ApplyColorSchema(PRGBQuad(Bits), BitCount, AValue);
    Changed;
  end;
end;

procedure TACLSkinImage.Draw(DC: HDC; const R: TRect; AFrameIndex: Integer = 0; AAlpha: Byte = MaxByte);

  procedure DoDrawWithMargins(ARenderer: TACLSkinImageRenderer; const ASource: TRect; AContentState: TACLSkinImageFrameState);
  var
    ADestParts: TACLMarginPartBounds;
    ASourceParts: TACLMarginPartBounds;
    APart: TACLMarginPart;
  begin
    acMarginCalculateRects(ARenderer.ClientRect, Margins, ASource, ADestParts, StretchMode);
    acMarginCalculateRects(ASource, Margins, ASource, ASourceParts, StretchMode);
    for APart := Low(APart) to High(APart) do
    begin
      if APart = mzClient then
      begin
        if AContentState.IsTransparent then
          Continue;
        if AContentState.IsColor then
        begin
          acFillRect(ARenderer.DestDC, ADestParts[APart], TAlphaColor(AContentState));
          Continue;
        end;
      end;
      ARenderer.Draw(ADestParts[APart], ASourceParts[APart], StretchMode = isTile);
    end;
  end;

  procedure DoDrawTiledAreas(ARenderer: TACLSkinImageRenderer; const ASource: TRect);
  var
    APart: TACLSkinImageTiledAreasPart;
    S, D: TACLSkinImageTiledAreasPartBounds;
  begin
    acCalculateTiledAreas(ASource, TiledAreas, FrameWidth, FrameHeight, TiledAreasMode, S);
    acCalculateTiledAreas(ARenderer.ClientRect, TiledAreas, FrameWidth, FrameHeight, TiledAreasMode, D);
    for APart := Low(TACLSkinImageTiledAreasPart) to High(TACLSkinImageTiledAreasPart) do
      ARenderer.Draw(D[APart], S[APart], StretchMode = isTile);
  end;

  procedure DoDraw(DC: HDC; const R, ASource: TRect; AState: TACLSkinImageFrameState);
  begin
    if AState.IsTransparent then
      Exit;

    if AState.IsColor then
    begin
      if (StretchMode = isCenter) and (ActualSizingMode = ismDefault) then
        acFillRect(DC, acRectCenter(R, ASource.Width, ASource.Height), TAlphaColor(AState))
      else
        acFillRect(DC, R, TAlphaColor(AState));
      Exit;
    end;

    FRenderer.DrawBegin(DC, R, AAlpha, Handle, not AState.IsOpaque);
    try
      case ActualSizingMode of
        ismMargins:
          DoDrawWithMargins(FRenderer, ASource, FFramesInfoContent[AFrameIndex]);
        ismTiledAreas:
          DoDrawTiledAreas(FRenderer, ASource);
      else {ismDefault}
        if StretchMode = isCenter then
          FRenderer.Draw(acRectCenter(FRenderer.ClientRect, ASource.Width, ASource.Height), ASource, False)
        else
          FRenderer.Draw(FRenderer.ClientRect, ASource, StretchMode = isTile);
      end;
    finally
      FRenderer.DrawEnd;
    end;
  end;

begin
  if not (Empty or acRectIsEmpty(R)) and RectVisible(DC, R) then
  begin
    CheckUnpacked;
    CheckBitsState(ibsPremultiplied);
    CheckFrameIndex(AFrameIndex);
    DoDraw(DC, R, FrameRect[AFrameIndex], FrameInfo[AFrameIndex]);
  end;
end;

procedure TACLSkinImage.Draw(DC: HDC; const R: TRect; AFrameIndex: Integer; AEnabled: Boolean; AAlpha: Byte = MaxByte);
var
  ALayer: TACLBitmapLayer;
begin
  if AEnabled then
    Draw(DC, R, AFrameIndex, AAlpha)
  else
  begin
    ALayer := TACLBitmapLayer.Create(R);
    try
      ALayer.Reset;
      Draw(ALayer.Handle, ALayer.ClientRect, AFrameIndex);
      ALayer.MakeDisabled;
      ALayer.DrawBlend(DC, R, AAlpha);
    finally
      ALayer.Free;
    end;
  end;
end;

procedure TACLSkinImage.Draw(DC: HDC; const R: TRect; AFrameIndex1, AFrameIndex2, AMixAlpha: Integer);
var
  ALayer1, ALayer2: TACLBitmapLayer;
  I: Integer;
begin
  ALayer1 := TACLBitmapLayer.Create(R);
  ALayer2 := TACLBitmapLayer.Create(R);
  try
    ALayer1.Reset;
    ALayer2.Reset;
    Draw(ALayer1.Handle, ALayer1.ClientRect, AFrameIndex1);
    Draw(ALayer2.Handle, ALayer2.ClientRect, AFrameIndex2);
    for I := 0 to ALayer1.ColorCount - 1 do
      TACLColors.AlphaBlend(ALayer1.Colors^[I], ALayer2.Colors^[I], AMixAlpha, False);
    ALayer1.DrawBlend(DC, R.TopLeft);
  finally
    ALayer1.Free;
    ALayer2.Free;
  end;
end;

procedure TACLSkinImage.DrawClipped(DC: HDC; const AClipRect, R: TRect; AFrameIndex: Integer; AAlpha: Byte);
var
  AClipRegion: HRGN;
begin
  AClipRegion := acSaveClipRegion(DC);
  try
    if acIntersectClipRegion(DC, AClipRect) then
      Draw(DC, R, AFrameIndex, AAlpha);
  finally
    acRestoreClipRegion(DC, AClipRegion);
  end;
end;

function TACLSkinImage.HitTest(const ABounds: TRect; X, Y: Integer): Boolean;
begin
  if HitTestMask = ihtmMask then
    Result := HitTestCore(ABounds, HitTestMaskFrameIndex, X, Y)
  else
    Result := HitTestMask = ihtmOpaque;
end;

function TACLSkinImage.HitTestCore(const ABounds: TRect; AFrameIndex, X, Y: Integer): Boolean;

  procedure ConvertPointRelativeRects(var P: TPoint; const DR, SR: TRect);
  begin
    P.X := MulDiv(P.X - DR.Left, acRectWidth(SR), acRectWidth(DR)) + SR.Left;
    P.Y := MulDiv(P.Y - DR.Top, acRectHeight(SR), acRectHeight(DR)) + SR.Top;
  end;

  procedure ConvertPointForTiledAreasMode(var P: TPoint; const DR, FR: TRect);
  var
    APart: TACLSkinImageTiledAreasPart;
    S, D: TACLSkinImageTiledAreasPartBounds;
  begin
    acCalculateTiledAreas(FR, TiledAreas, acRectWidth(FR), acRectHeight(FR), TiledAreasMode, S);
    acCalculateTiledAreas(DR, TiledAreas, acRectWidth(FR), acRectHeight(FR), TiledAreasMode, D);
    for APart := Low(TACLSkinImageTiledAreasPart) to High(TACLSkinImageTiledAreasPart) do
      if PtInRect(D[APart], P) then
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
    acMarginCalculateRects(DR, Margins, FR, DZ, StretchMode);
    acMarginCalculateRects(FR, Margins, FR, SZ, StretchMode);
    for APart := Low(APart) to High(APart) do
      if PtInRect(DZ[APart], P) then
      begin
        ConvertPointRelativeRects(P, DZ[APart], SZ[APart]);
        Break;
      end;
  end;

  function ConvertPointToLocalCoords(var P: TPoint; const DR, FR: TRect): Boolean;
  begin
    Result := False;
    if not acRectIsEmpty(DR) then
    begin
      case ActualSizingMode of
        ismMargins:
          ConvertPointForMarginsMode(P, DR, FR);
        ismTiledAreas:
          ConvertPointForTiledAreasMode(P, DR, FR);
      else
        ConvertPointRelativeRects(P, DR, FR);
      end;
      Result := PtInRect(FR, P);
    end;
  end;

var
  APixel: TRGBQuad;
  APoint: TPoint;
begin
  if not Empty then
  begin
    Result := False;
    APoint := Point(X, Y);
    if ConvertPointToLocalCoords(APoint, ABounds, FrameRect[AFrameIndex]) then
    begin
      if GetPixel(APoint.X, APoint.Y, APixel) then
        Result := APixel.rgbReserved >= HitTestThreshold;
    end;
  end
  else
    Result := True;
end;

function TACLSkinImage.GetPixel(X, Y: Integer; out APixel: TRGBQuad): Boolean;
var
  AOffset: Integer;
begin
  CheckUnpacked;
  CheckBitsState(ibsPremultiplied);
  AOffset := X + Y * Width;
  Result := InRange(AOffset, 0, BitCount - 1);
  if Result then
    APixel := Bits^[AOffset];
end;

procedure TACLSkinImage.ListenerAdd(AEvent: TNotifyEvent);
begin
  FChangeListeners.Add(AEvent)
end;

procedure TACLSkinImage.ListenerRemove(AEvent: TNotifyEvent);
begin
  FChangeListeners.Remove(AEvent)
end;

procedure TACLSkinImage.LoadFromBits(ABits: PRGBQuad; AWidth, AHeight: Integer);
begin
  DoCreateBits(AWidth, AHeight);
  FastMove(ABits^, Bits^, BitCount * SizeOf(TRGBQuad));
  Changed;
end;

procedure TACLSkinImage.LoadFromBitmap(ABitmap: TBitmap);
var
  AInfo: TBitmapInfo;
begin
  DoCreateBits(ABitmap.Width, ABitmap.Height);
  acFillBitmapInfoHeader(AInfo.bmiHeader, Width, Height);
  GetDIBits(MeasureCanvas.Handle, ABitmap.Handle, 0, Height, Bits, AInfo, DIB_RGB_COLORS);

  if (ABitmap.PixelFormat > pfDevice) and (ABitmap.PixelFormat < pf32bit) then
    TACLColors.MakeTransparent(PRGBQuad(Bits), BitCount, TACLColors.MaskPixel);
  if ABitmap.AlphaFormat = afPremultiplied then
    FBitsState := ibsPremultiplied;

  Changed;
end;

procedure TACLSkinImage.LoadFromFile(const AFileName: UnicodeString);
var
  AStream: TACLFileStream;
begin
  AStream := TACLFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(AStream);
  finally
    AStream.Free;
  end;
end;

procedure TACLSkinImage.LoadFromResource(AInstance: HINST; const AName: UnicodeString; AResRoot: PWideChar);
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
  BeginUpdate;
  try
    Clear;
    if AStream.Read(AHeader, SizeOf(AHeader)) = SizeOf(AHeader) then
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
  end;
end;

procedure TACLSkinImage.SaveToBitmap(ABitmap: TBitmap);
var
  AInfo: TBitmapInfo;
  DC: HDC;
begin
  ABitmap.SetSize(Width, Height);
  if not Empty then
  begin
    CheckUnpacked;
    CheckBitsState(ibsUnpremultiplied);

    DC := GetDC(0);
    try
      ABitmap.AlphaFormat := afIgnored;
      ABitmap.PixelFormat := pf32bit;
      acFillBitmapInfoHeader(AInfo.bmiHeader, Width, Height);
      SetDIBits(DC, ABitmap.Handle, 0, Height, Bits, AInfo, DIB_RGB_COLORS);
      if not HasAlpha then
        ABitmap.PixelFormat := pf24bit;
    finally
      ReleaseDC(0, DC);
    end;
  end;
end;

procedure TACLSkinImage.SaveToFile(const AFileName: UnicodeString; AFormat: TACLImageFormatClass);
var
  AStream: TStream;
begin
  AStream := TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(AStream, AFormat);
  finally
    AStream.Free;
  end;
end;

procedure TACLSkinImage.SaveToStream(AStream: TStream; AFormat: TACLImageFormatClass);
var
  AAlphaFormat: TAlphaFormat;
  ABitmap: TBitmap;
begin
  if Empty then
    Exit;

  if AFormat = TACLImageFormatBMP then
  begin
    ABitmap := TBitmap.Create;
    try
      SaveToBitmap(ABitmap);
      ABitmap.SaveToStream(AStream);
    finally
      ABitmap.Free;
    end;
  end
  else
  begin
    CheckUnpacked;
    if not HasAlpha then
      AAlphaFormat := afIgnored
    else if BitsState = ibsPremultiplied then
      AAlphaFormat := afPremultiplied
    else
      AAlphaFormat := afDefined;

    with TACLImage.Create do
    try
      LoadFromBits(@Bits^[0], Self.Width, Self.Height, AAlphaFormat);
      SaveToStream(AStream, AFormat);
    finally
      Free;
    end;
  end;
end;

procedure TACLSkinImage.SaveToFile(const AFileName: UnicodeString);
var
  AStream: TStream;
begin
  AStream := TACLFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(AStream);
  finally
    AStream.Free;
  end;
end;

procedure TACLSkinImage.SaveToStream(AStream: TStream);
var
  AChunkCount: Integer;
  AHeader: TACLSkinImageHeader;
  APosition1: Int64;
  APosition2: Int64;
begin
  HasAlpha;
  CheckFramesInfo;

  AChunkCount := 0;
  AHeader.ID := 'ACLIMG32';
  AHeader.Version := 1;
  AStream.WriteBuffer(AHeader, SizeOf(AHeader));
  APosition1 := AStream.Position;
  AStream.WriteInt32(AChunkCount);
  WriteChunks(AStream, AChunkCount);
  APosition2 := AStream.Position;
  AStream.Position := APosition1;
  AStream.WriteInt32(AChunkCount);
  AStream.Position := APosition2;
end;

procedure TACLSkinImage.Changed;
var
  I: Integer;
begin
  FRenderer.BitsChanged;
  FFramesInfoIsValid := False;
  if FUpdateCount = 0 then
  begin
    for I := 0 to FChangeListeners.Count - 1 do
      FChangeListeners.List[I](Self);
  end;
end;

procedure TACLSkinImage.CheckBitsState(ARequiredState: TACLSkinImageBitsState);
begin
  if ARequiredState <> FBitsState then
  begin
    CheckUnpacked;
    if HasAlpha then
    begin
      case ARequiredState of
        ibsPremultiplied:
          TACLColors.Premultiply(PRGBQuad(Bits), BitCount);
        ibsUnpremultiplied:
          TACLColors.Unpremultiply(PRGBQuad(Bits), BitCount);
      end;
    end;
    FBitsState := ARequiredState;
    FRenderer.BitsChanged;
  end;
end;

procedure TACLSkinImage.Dormant;
begin
  if not Empty and (Bits <> nil) then
  begin
    FreeAndNil(FDormantData);
    FDormantData := TACLSkinImageBitsStorage.Create(Bits, BitCount, FHasAlpha, FBitsState);
  {$IFDEF ACL_DEBUG_SKINIMAGE_STAT}
    Inc(FSkinImageMemoryCompressed, FDormantData.DataSize);
    Inc(FSkinImageMemoryUsageInDormant, BitCount * SizeOf(TRGBQuad));
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
  AState: TACLSkinImageFrameState;
  I: Integer;
begin
  if not FFramesInfoIsValid then
  begin
    CheckUnpacked;
    CheckBitsState(ibsPremultiplied);

    if Length(FFramesInfo) <> FrameCount then
    begin
      SetLength(FFramesInfo, FrameCount);
      SetLength(FFramesInfoContent, FrameCount);
    end;

    for I := 0 to FrameCount - 1 do
      FFramesInfo[I] := TACLSkinImageAnalyzer.AnalyzeFrame(FBits, FrameRect[I], Width);

    if ActualSizingMode = ismMargins then
    begin
      for I := 0 to FrameCount - 1 do
      begin
        AState := FFramesInfo[I];
        if AState.IsColor or AState.IsTransparent then
          FFramesInfoContent[I] := AState
        else
          FFramesInfoContent[I] := TACLSkinImageAnalyzer.AnalyzeFrame(FBits, acRectContent(FrameRect[I], Margins), Width);
      end;
    end
    else
    begin
      for I := 0 to FrameCount - 1 do
        FFramesInfoContent[I] := FFramesInfo[I];
    end;

    FFramesInfoIsValid := True;
  end;
end;

procedure TACLSkinImage.CheckUnpacked;
var
  AData: TACLSkinImageBitsStorage;
begin
  if (FBits = nil) and (FDormantData <> nil) then
  begin
    AData := FDormantData;
    try
      FDormantData := nil;
      DoCreateBits(Width, Height);
      AData.Restore(Bits, BitCount, FHasAlpha, FBitsState);
    finally
      FreeAndNil(AData);
    end;
  end;
end;

procedure TACLSkinImage.ClearData;
begin
{$IFDEF ACL_DEBUG_SKINIMAGE_STAT}
  if FDormantData <> nil then
  begin
    Dec(FSkinImageMemoryUsageInDormant, BitCount * SizeOf(TRGBQuad));
    Dec(FSkinImageMemoryCompressed, FDormantData.DataSize);
    Dec(FSkinImageDormantCount);
  end;
{$ENDIF}
  FreeAndNil(FDormantData);
  ReleaseHandle;
  DoSetSize(0, 0);
  FHasAlpha := TACLBoolean.Default;
  FBitsState := ibsUnpremultiplied;
  FFramesInfoIsValid := False;
end;

procedure TACLSkinImage.DoAssign(AObject: TObject);
var
  ASkinImage: TACLSkinImage;
begin
  if AObject is TBitmap then
    LoadFromBitmap(TBitmap(AObject))
  else
    if AObject is TACLSkinImage then
    begin
      ClearData;
      ASkinImage := TACLSkinImage(AObject);
      if ASkinImage.FDormantData <> nil then
      begin
        DoSetSize(ASkinImage.Width, ASkinImage.Height);
        FDormantData := ASkinImage.FDormantData.Clone;
      {$IFDEF ACL_DEBUG_SKINIMAGE_STAT}
        Inc(FSkinImageMemoryUsageInDormant, BitCount * SizeOf(TRGBQuad));
        Inc(FSkinImageMemoryCompressed, FDormantData.DataSize);
        Inc(FSkinImageDormantCount);
      {$ENDIF}
      end
      else
      begin
        DoCreateBits(ASkinImage.Width, ASkinImage.Height);
        acBitsCopy(ASkinImage.Bits, Bits, BitCount);
        FBitsState := ASkinImage.FBitsState;
        FHasAlpha := ASkinImage.FHasAlpha;
      end;
      DoAssignParams(ASkinImage);
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
var
  AInfo: TBitmapInfo;
begin
  ClearData;
  DoSetSize(AWidth, AHeight);
  if BitCount > 0 then
  begin
  {$IFDEF ACL_DEBUG_SKINIMAGE_STAT}
    Inc(FSkinImageMemoryUsage, BitCount * SizeOf(TRGBQuad));
  {$ENDIF}
    acFillBitmapInfoHeader(AInfo.bmiHeader, Width, Height);
    FHandle := CreateDIBSection(0, AInfo, DIB_RGB_COLORS, Pointer(FBits), 0, 0);
    if (FHandle = 0) or (FBits = nil) then
      raise EACLSkinImageException.CreateFmt(sErrorCannotCreateImage, [Width, Height]);
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
    $6D617266: // deprecated
      begin
        HitTestMask := TACLSkinImageHitTestMode(AStream.ReadByte);
        HitTestMaskFrameIndex := AStream.ReadInt32;
      end;
  end;
end;

procedure TACLSkinImage.ReadFormatChunked(AStream: TStream);
var
  AChunkID: Integer;
  AChunkSize: Integer;
  APosition: Int64;
  I: Integer;
begin
  for I := 0 to AStream.ReadInt32 - 1 do
  begin
    AChunkID := AStream.ReadInt32;
    AChunkSize := AStream.ReadInt32;
    if AChunkSize < 0 then
      Break;

    APosition := AStream.Position;
    try
      ReadChunk(AStream, AChunkID, AChunkSize);
    finally
      AStream.Position := APosition + AChunkSize;
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
  AHeaderData: TACLSkinImageHeaderData;
begin
  AStream.ReadBuffer(AHeaderData, SizeOf(AHeaderData));
  if AVersion = 1 then
    AHeaderData.StretchMode := Max(AHeaderData.StretchMode - 1, 0);

  DoCreateBits(AHeaderData.Width, AHeaderData.Height);
  if AHeaderData.BitsSize > 0 then
    AStream.ReadBuffer(Bits^, AHeaderData.BitsSize);
  Layout := AHeaderData.Layout;
  FrameCount := AHeaderData.FramesCount;
  TiledAreas := AHeaderData.TiledAreas;
  TiledAreasMode := AHeaderData.TiledAreasMode;
  Margins := AHeaderData.Margins;
  HitTestMaskFrameIndex := AHeaderData.HitTestMaskFrameIndex;
  HitTestMask := AHeaderData.HitTestMask;
  StretchMode := TACLStretchMode(AHeaderData.StretchMode);

  if AHeaderData.BitsHasAlpha then
    FHasAlpha := TACLBoolean.True
  else
    FHasAlpha := TACLBoolean.False;

  if AHeaderData.BitsPrepared then
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
    if (SizingMode <> ismTiledAreas) and not acMarginIsEmpty(Margins) then
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
  if (Index < 0) or (Index >= Length(FFramesInfo)) then
    raise EACLSkinImageException.Create('Invalid FrameInfo Index');
  Result := FFramesInfo[Index];
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
  AHasSemiTransparentPixels: Boolean;
  AState: TACLSkinImageFrameState;
begin
  if FHasAlpha = TACLBoolean.Default then
  begin
    CheckUnpacked;
    AState := TACLSkinImageAnalyzer.Analyze(PRGBQuad(Bits), BitCount);
    if AState.IsTransparent then // null-alpha
    begin
      TACLSkinImageAnalyzer.RecoveryAlpha(PRGBQuad(Bits), BitCount, AHasSemiTransparentPixels);
      if AHasSemiTransparentPixels then
        FHasAlpha := TACLBoolean.True
      else
        FHasAlpha := TACLBoolean.False;
    end
    else
      FHasAlpha := TACLBoolean.From(not AState.IsOpaque);
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
    FFramesCount := AValue;
    Changed;
  end;
end;

procedure TACLSkinImage.SetFrameSize(const AValue: TSize);
var
  ABitmap: TACLBitmap;
  AFrameBitmap: TACLBitmapLayer;
  AFrameRect: TRect;
  AFrameCount: Integer;
  I: Integer;
begin
  if not (Empty or acSizeIsEqual(AValue, FrameSize) or acSizeIsEmpty(AValue)) then
  begin
    BeginUpdate;
    try
      AFrameCount := FrameCount;
      ABitmap := TACLBitmap.CreateEx(AValue.cx, AValue.cy * FrameCount, pf32bit, True);
      try
        ABitmap.AlphaFormat := afPremultiplied;
        AFrameRect := acRect(AValue);
        AFrameBitmap := TACLBitmapLayer.Create(FrameWidth, FrameHeight);
        try
          for I := 0 to AFrameCount - 1 do
          begin
            AFrameBitmap.Reset;
            Draw(AFrameBitmap.Handle, AFrameBitmap.ClientRect, I);
            AFrameBitmap.DrawBlend(ABitmap.Canvas.Handle, AFrameRect, MaxByte, True);
            OffsetRect(AFrameRect, 0, acRectHeight(AFrameRect));
          end;
        finally
          AFrameBitmap.Free;
        end;
        LoadFromBitmap(ABitmap);
        Layout := ilVertical;
        FrameCount := AFrameCount;
      finally
        ABitmap.Free;
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
    AStream.ReadBuffer(Bits^, BitCount * SizeOf(TRGBQuad));

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
  FDormantData := TACLSkinImageBitsStorage.Create(AStream);
  FDormantData.HasAlpha := TACLBoolean.From(AFlags and FLAGS_BITS_HASALPHA = FLAGS_BITS_HASALPHA);
  FDormantData.State := TACLSkinImageBitsState(AFlags and FLAGS_BITS_PREPARED = FLAGS_BITS_PREPARED);
  FHasAlpha := FDormantData.HasAlpha;
  FBitsState := FDormantData.State;
{$IFDEF ACL_DEBUG_SKINIMAGE_STAT}
  Inc(FSkinImageMemoryUsageInDormant, BitCount * SizeOf(TRGBQuad));
  Inc(FSkinImageMemoryCompressed, FDormantData.DataSize);
  Inc(FSkinImageDormantCount);
{$ENDIF}
end;

procedure TACLSkinImage.ReadChunkDraw(AStream: TStream);
var
  AFlags: Integer;
begin
  AFlags := AStream.ReadInt32;
  AllowColoration := AFlags and FLAGS_DRAW_ALLOWCOLORATION = FLAGS_DRAW_ALLOWCOLORATION;
  StretchMode := TACLStretchMode(AStream.ReadByte);

  if AFlags and FLAGS_DRAW_SIZING_BY_MARGINS <> 0 then
    SizingMode := ismMargins
  else if AFlags and FLAGS_DRAW_SIZING_BY_TiledAreas <> 0 then
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

  SetLength(FFramesInfo, FrameCount);
  SetLength(FFramesInfoContent, FrameCount);

  for I := 0 to FrameCount - 1 do
    FFramesInfo[I] := AStream.ReadInt32;

  if ASize > 1 + 4 + 4 * FrameCount then
  begin
    for I := 0 to FrameCount - 1 do
      FFramesInfoContent[I] := AStream.ReadInt32;
  end
  else
  begin
    for I := 0 to FrameCount - 1 do
      FFramesInfoContent[I] := FFramesInfo[I];
  end;
  FFramesInfoIsValid := True;
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
  AStream.ReadBuffer(ATiledAreas, SizeOf(ATiledAreas));
  TiledAreas := ATiledAreas;
end;

procedure TACLSkinImage.WriteChunkBits(AStream: TStream; var AChunkCount: Integer);

  function GetFlags: Integer;
  begin
    Result :=
      IfThen(HasAlpha, FLAGS_BITS_HASALPHA) or
      IfThen(FBitsState = ibsPremultiplied, FLAGS_BITS_PREPARED);
  end;

var
  APosition: Int64;
begin
  if BitCount > 0 then
  begin
    if FSkinImageCompressionLevel = zcNone then
    begin
      CheckUnpacked;
      AStream.BeginWriteChunk(CHUNK_BITS, APosition);
      AStream.WriteInt32(GetFlags);
      AStream.WriteInt32(Width);
      AStream.WriteInt32(Height);
      AStream.WriteBuffer(Bits^, BitCount * SizeOf(TRGBQuad));
      AStream.EndWriteChunk(APosition);
      Inc(AChunkCount);
    end
    else
    begin
      AStream.BeginWriteChunk(CHUNK_BITZ, APosition);
      AStream.WriteInt32(GetFlags);
      AStream.WriteInt32(Width);
      AStream.WriteInt32(Height);

    {$IFDEF DEBUG}
      if FDormantData <> nil then
      begin
        if (FDormantData.HasAlpha <> FHasAlpha) or (FDormantData.State <> BitsState) then
          raise EACLSkinImageException.Create('DormantData has a different state');
      end;
    {$ENDIF}

      if FDormantData <> nil then
        FDormantData.SaveToStream(AStream)
      else
        with TACLSkinImageBitsStorage.Create(Bits, BitCount, FHasAlpha, FBitsState) do
        try
          SaveToStream(AStream);
        finally
          Free;
        end;

      AStream.EndWriteChunk(APosition);
      Inc(AChunkCount);
    end;
  end;
end;

procedure TACLSkinImage.WriteChunkDraw(AStream: TStream; var AChunkCount: Integer);
var
  APosition: Int64;
begin
  AStream.BeginWriteChunk(CHUNK_DRAW, APosition);
  AStream.WriteInt32(
    IfThen(AllowColoration, FLAGS_DRAW_ALLOWCOLORATION) or
    IfThen(SizingMode = ismMargins, FLAGS_DRAW_SIZING_BY_MARGINS) or
    IfThen(SizingMode = ismTiledAreas, FLAGS_DRAW_SIZING_BY_TiledAreas));
  AStream.WriteByte(Ord(StretchMode));
  AStream.EndWriteChunk(APosition);
  Inc(AChunkCount);
end;

procedure TACLSkinImage.WriteChunkFrameInfo(AStream: TStream; var AChunkCount: Integer);
var
  APosition: Int64;
  I: Integer;
begin
  CheckFramesInfo;
  AStream.BeginWriteChunk(CHUNK_FRAMEINFO, APosition);
  AStream.WriteByte(Ord(HitTestMask));
  AStream.WriteInt32(HitTestMaskFrameIndex);
  for I := 0 to FrameCount - 1 do
    AStream.WriteInt32(FFramesInfo[I]);
  for I := 0 to FrameCount - 1 do
    AStream.WriteInt32(FFramesInfoContent[I]);
  AStream.EndWriteChunk(APosition);
  Inc(AChunkCount);
end;

procedure TACLSkinImage.WriteChunkLayout(AStream: TStream; var AChunkCount: Integer);
var
  APosition: Int64;
begin
  AStream.BeginWriteChunk(CHUNK_LAYOUT, APosition);
  AStream.WriteBoolean(Layout = ilVertical);
  AStream.WriteInt32(FrameCount);
  AStream.WriteRect(Margins);
  AStream.WriteRect(ContentOffsets);
  AStream.WriteBoolean(TiledAreasMode = tpmVertical);
  AStream.WriteBuffer(TiledAreas, SizeOf(TACLSkinImageTiledAreas));
  AStream.EndWriteChunk(APosition);
  Inc(AChunkCount);
end;

procedure TACLSkinImage.ReleaseHandle;
begin
  if FHandle <> 0 then
  begin
  {$IFDEF ACL_DEBUG_SKINIMAGE_STAT}
    Dec(FSkinImageMemoryUsage, BitCount * SizeOf(TRGBQuad));
  {$ENDIF}
    DeleteObject(FHandle);
    FHandle := 0;
    FBits := nil;
  end;
end;

{ TACLSkinImageAnalyzer }

class function TACLSkinImageAnalyzer.Analyze(Q: PRGBQuad; ACount: Integer): TACLSkinImageFrameState;
var
  AAlpha: DWORD;
  AColor: DWORD;
begin
  if ACount = 0 then
    Exit(TACLSkinImageFrameState.TRANSPARENT);

  AColor := PDWORD(Q)^;
  AAlpha := Q^.rgbReserved;
  AnalyzeCore(Q, ACount, AAlpha, AColor);
  Result := AnalyzeResultToState(AAlpha, AColor);
end;

class function TACLSkinImageAnalyzer.AnalyzeFrame(
  Q: PRGBQuadArray; const AFrameRect: TRect; AImageWidth: Integer): TACLSkinImageFrameState;
var
  AAlpha: DWORD;
  AColor: DWORD;
  AWidth: Integer;
  Y: Integer;
begin
  if AFrameRect.IsEmpty then
    Exit(TACLSkinImageFrameState.TRANSPARENT);

  AColor := PDWORD(Q)^;
  AAlpha := Q^[0].rgbReserved;
  AWidth := acRectWidth(AFrameRect);
  for Y := AFrameRect.Top to AFrameRect.Bottom - 1 do
  begin
    AnalyzeCore(@Q^[AFrameRect.Left + Y * AImageWidth], AWidth, AAlpha, AColor);
    if AAlpha = INVALID_VALUE then
      Break;
  end;
  Result := AnalyzeResultToState(AAlpha, AColor);
end;

class procedure TACLSkinImageAnalyzer.RecoveryAlpha(Q: PRGBQuad; ACount: Integer; var AHasSemiTransparentPixels: Boolean);
begin
  while ACount > 0 do
  begin
    if TACLColors.IsMask(Q^) then
    begin
      AHasSemiTransparentPixels := True;
      TACLColors.Flush(Q^);
    end
    else
      Q^.rgbReserved := $FF;

    Dec(ACount);
    Inc(Q);
  end;
end;

class procedure TACLSkinImageAnalyzer.AnalyzeCore(Q: PRGBQuad; Count: Integer; var AAlpha: DWORD; var AColor: DWORD);
begin
  while Count > 0 do
  begin
    if AAlpha <> Q^.rgbReserved then
    begin
      AAlpha := INVALID_VALUE;
      Break;
    end;
    if AColor <> PDWORD(Q)^ then
      AColor := INVALID_VALUE;
    Dec(Count);
    Inc(Q);
  end;
end;

class function TACLSkinImageAnalyzer.AnalyzeResultToState(var AAlpha: DWORD; var AColor: DWORD): TACLSkinImageFrameState;
begin
  if AAlpha = INVALID_VALUE then
    Exit(TACLSkinImageFrameState.SEMITRANSPARENT);
  if AAlpha = 0 then
    Exit(TACLSkinImageFrameState.TRANSPARENT);
  if AColor <> INVALID_VALUE then
  begin
    TACLColors.Unpremultiply(TRGBQuad(AColor));
    Exit(AColor);
  end;
  if AAlpha < MaxByte then
    Result := TACLSkinImageFrameState.SEMITRANSPARENT
  else
    Result := TACLSkinImageFrameState.OPAQUE;
end;

{ TACLSkinImageRenderer }

constructor TACLSkinImageRenderer.Create;
begin
  inherited Create;
  ZeroMemory(@FFunc, SizeOf(FFunc));
  FFunc.BlendOp := AC_SRC_OVER;
  FFunc.AlphaFormat := AC_SRC_ALPHA;
  FLock := TACLCriticalSection.Create(Self);
end;

destructor TACLSkinImageRenderer.Destroy;
begin
  FreeAndNil(FLock);
  DeleteDC(FMemDC);
  FMemDC := 0;
  inherited Destroy;
end;

procedure TACLSkinImageRenderer.BitsChanged;
begin
  FBitsChanged := True;
end;

procedure TACLSkinImageRenderer.DrawBegin(DC: HDC; const R: TRect; const AAlpha: Byte; AHandle: HBITMAP; AHasAlpha: Boolean);
begin
  FLock.Enter;
  FAlpha := AAlpha;
  FClientRect := R;
  FDestDC := DC;

  if FBitsChanged then
  begin
    FBitsChanged := False;
    GdiFlush;
  end;

  if FMemDC = 0 then
    FMemDC := CreateCompatibleDC(0);
  FOldBmp := SelectObject(FMemDC, AHandle);
  FOpacue := not AHasAlpha and (AAlpha = 255);
  FFunc.SourceConstantAlpha := Alpha;
end;

procedure TACLSkinImageRenderer.Draw(const R, ASource: TRect; AIsTileMode: Boolean);
const
  Map: array[Boolean] of TACLStretchMode = (isStretch, isTile);
begin
  if FOpacue then
  begin
    if AIsTileMode then
      acTileBlt(FDestDC, FMemDC, R, ASource)
    else
      acStretchBlt(FDestDC, FMemDC, R, ASource);
  end
  else
    if AIsTileMode then
      acAlphaBlendTile(FDestDC, FMemDC, R, ASource, FFunc)
    else
      acAlphaBlend(FDestDC, FMemDC, R, ASource, FFunc);
end;

procedure TACLSkinImageRenderer.DrawEnd;
begin
  SelectObject(FMemDC, FOldBmp);
  FDestDC := 0;
  FLock.Leave;
end;

end.
