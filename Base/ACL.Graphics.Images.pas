{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*                  Images                   *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.Images;

{$I ACL.Config.INC}

interface

uses
  Windows,
  Types,
  ActiveX,
  SysUtils,
  Classes,
  Graphics,
  GDIPOBJ,
  GDIPAPI,
  // ACL
  ACL.Classes,
  ACL.Classes.ByteBuffer,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Gdiplus,
  ACL.Threading,
  ACL.Utils.Clipboard,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type
  TACLImageFormatClass = class of TACLImageFormat;
  TACLImageFormat = class;

  TACLImageCompositingMode = (cmOver, cmReplace);
  TACLImagePixelOffsetMode = (ipomDefault, ipomHalf, ipomNone);
  TACLImageStretchQuality = (
    sqDefault             = 0,
    sqLowQuality          = 1,
    sqHighQuality         = 2,
    sqBilinear            = 3,
    sqBicubic             = 4,
    sqNearestNeighbor     = 5,
    sqHighQualityBilinear = 6,
    sqHighQualityBicubic  = 7
  );

  { EACLImageFormatError }

  EACLImageFormatError = class(Exception);

  { EACLImageUnsupportedFormat }

  EACLImageUnsupportedFormat = class(EACLImageFormatError)
  public
    constructor Create;
  end;

  { TACLImage }

  TACLImage = class
  strict private
    FBits: array of TRGBQuad;
    FComposingMode: TACLImageCompositingMode;
    FHandle: GpImage;
    FPixelOffsetMode: TACLImagePixelOffsetMode;
    FStretchQuality: TACLImageStretchQuality;

    function GetClientRect: TRect;
    function GetHeight: Integer;
    function GetIsEmpty: Boolean;
    function GetWidth: Integer;
    procedure SetHandle(AValue: GpImage);
  protected
    FFormat: TACLImageFormatClass;

    function CloneHandle: GpImage;
    procedure DestroyHandle;
    procedure LoadFromHandle(AHandle: GpImage; AFormat: TACLImageFormatClass = nil);

    function BeginLock(var AData: TBitmapData): Boolean;
    function EndLock(var AData: TBitmapData): Boolean;

    property Handle: GpImage read FHandle;
  public
    constructor Create; overload;
    constructor Create(ABitmap: HBITMAP); overload;
    constructor Create(ABitmap: TBitmap; AAlphaFormat: TAlphaFormat = afPremultiplied); overload;
    constructor Create(AInstance: HINST; const AResName: UnicodeString; AResType: PWideChar); overload;
    constructor Create(AStream: TStream); overload;
    constructor Create(AWidth, AHeight: Integer); overload;
    constructor Create(const ABits: PRGBQuad; AWidth, AHeight: Integer); overload;
    constructor Create(const AFileName: UnicodeString); overload;
    destructor Destroy; override;
    procedure Assign(ASource: TObject);

    procedure ApplyColorSchema(const AColorSchema: TACLColorSchema);
    procedure ConvertToBitmap;

    // Cloning
    function Clone: TACLImage;
    function ToBitmap(AAlphaFormat: TAlphaFormat = afIgnored): TACLBitmap;

    // Drawing
    procedure Draw(DC: HDC; const R, ASource, AMargins: TRect; AAlpha: Byte = $FF; ATile: Boolean = False); overload;
    procedure Draw(DC: HDC; const R, ASource: TRect; AAlpha: Byte = $FF; ATile: Boolean = False); overload;
    procedure Draw(DC: HDC; const R: TRect; AAlpha: Byte = $FF; ATile: Boolean = False); overload;
    procedure Draw(Graphics: GpGraphics; const R, ASource, AMargins: TRect; AAlpha: Byte = $FF; ATile: Boolean = False); overload;
    procedure Draw(Graphics: GpGraphics; const R, ASource: TRect; AAlpha: Byte = $FF; ATile: Boolean = False); overload;
    procedure Draw(Graphics: GpGraphics; const R: TRect; AAlpha: Byte = $FF; ATile: Boolean = False); overload;

    // Sizing
    procedure Crop(const ACropMargins: TRect);
    procedure CropAndResize(const ACropMargins: TRect; AWidth, AHeight: Integer);
    procedure Resize(AWidth, AHeight: Integer);
    procedure Scale(ANumerator, ADenominator: Integer); overload;
    procedure Scale(AScaleFactor: Single); overload;

    procedure LoadFromBitmap(ABitmap: HBITMAP; APalette: HPALETTE = 0); overload;
    procedure LoadFromBitmap(ABitmap: TBitmap; AAlphaFormat: TAlphaFormat = afPremultiplied); overload;
    procedure LoadFromBits(ABits: PRGBQuad; AWidth, AHeight: Integer; AAlphaFormat: TAlphaFormat = afPremultiplied);
    procedure LoadFromFile(const AFileName: UnicodeString);
    procedure LoadFromGraphic(AGraphic: TGraphic);
    procedure LoadFromResource(AInstance: HINST; const AResName: UnicodeString; AResType: PWideChar);
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToFile(const AFileName: UnicodeString); overload;
    procedure SaveToFile(const AFileName: UnicodeString; AFormat: TACLImageFormatClass); overload;
    procedure SaveToStream(AStream: TStream); overload;
    procedure SaveToStream(AStream: TStream; AFormat: TACLImageFormatClass); overload;

    property ClientRect: TRect read GetClientRect;
    property Empty: Boolean read GetIsEmpty;
    property Format: TACLImageFormatClass read FFormat;
    property Height: Integer read GetHeight;
    property Width: Integer read GetWidth;
    //
    property ComposingMode: TACLImageCompositingMode read FComposingMode write FComposingMode;
    property PixelOffsetMode: TACLImagePixelOffsetMode read FPixelOffsetMode write FPixelOffsetMode;
    property StretchQuality: TACLImageStretchQuality read FStretchQuality write FStretchQuality;
  end;

  { TACLImageFormat }

  TACLImageFormat = class
  protected
    class function CheckIsAvailable: Boolean; virtual;
    class function CheckPreamble(AData: PByte; AMaxSize: Integer): Boolean; virtual; abstract;
    class function GetMaxPreamble: Integer; virtual; abstract;

    class function Load(AStream: TStream): GpBitmap; virtual;
    class procedure Save(AStream: TStream; ABitmap: GpBitmap); virtual;
  public
    class function ClipboardFormat: Word; virtual;
    class function Description: string; virtual; abstract;
    class function Ext: string; virtual; abstract;
    class function GetSize(AStream: TStream; out ASize: TSize): Boolean; virtual; abstract;
    class function MimeType: string; virtual; abstract;
  end;

  { TACLImageFormatRepository }

  TACLImageFormatRepository = class
  strict private
    class var FFormats: TList;
    class var FMaxPreamble: Integer;

    class function BuildDialogFilter(const ADescription, AExts: string): string;
  public
    class constructor Create;
    class destructor Destroy;

    class procedure Register(AFormat: TACLImageFormatClass);
    class procedure Unregister(AFormat: TACLImageFormatClass);

    class function GetFormat(AData: PByte; ADataSize: Integer): TACLImageFormatClass; overload;
    class function GetFormat(const AContainer: IACLDataContainer): TACLImageFormatClass; overload;
    class function GetFormat(const AMimeType: string): TACLImageFormatClass; overload;
    class function GetFormat(const AStream: TStream): TACLImageFormatClass; overload;
    class function GetFormatByExt(const AExt: string): TACLImageFormatClass; overload;

    class function GetDialogFilter(const AContainer: IACLDataContainer; out AFilter, AExt: UnicodeString): Boolean; overload;
    class function GetDialogFilter(const AMimeType: UnicodeString; out AFilter, AExt: UnicodeString): Boolean; overload;
    class function GetDialogFilter: string; overload;
    class function GetExtList: string;

    class function GetMimeType(const AFormat: TACLImageFormatClass): UnicodeString; overload;
    class function GetMimeType(const AContainer: IACLDataContainer): UnicodeString; overload;
    class function GetMimeType(const AExt: UnicodeString): UnicodeString; overload;
    class function GetMimeType(const AStream: TStream): UnicodeString; overload;

    class function GetImageInfo(AContainer: IACLDataContainer;
      out AFormat: TACLImageFormatClass; out ADimensions: TSize): Boolean; overload;
    class function GetImageInfo(AStream: TStream;
      out AFormat: TACLImageFormatClass; out ADimensions: TSize): Boolean; overload;
  end;

  { TACLImageFormatBMP }

  TACLImageFormatBMP = class(TACLImageFormat)
  public const
    FormatPreamble = $4D42;
  protected
    class function CheckPreamble(AData: PByte; AMaxSize: Integer): Boolean; override;
    class function GetMaxPreamble: Integer; override;
  public
    class function ClipboardFormat: Word; override;
    class function Description: string; override;
    class function Ext: string; override;
    class function GetSize(AStream: TStream; out ASize: TSize): Boolean; override;
    class function MimeType: string; override;
  end;

  { TACLImageFormatJPEG }

  TACLImageFormatJPEG = class(TACLImageFormat)
  protected
    class function CheckPreamble(AData: PByte; AMaxSize: Integer): Boolean; override;
    class function GetMaxPreamble: Integer; override;
  public
    class function Description: string; override;
    class function Ext: string; override;
    class function MimeType: string; override;
    class function GetSize(AStream: TStream; out ASize: TSize): Boolean; override;
  end;

  { TACLImageFormatJPG }

  TACLImageFormatJPG = class(TACLImageFormatJPEG)
  public
    class function Ext: string; override;
    class function MimeType: string; override;
  end;

  { TACLImageFormatGIF }

  TACLImageFormatGIF = class(TACLImageFormat)
  protected
    class function CheckPreamble(AData: PByte; AMaxSize: Integer): Boolean; override;
    class function GetMaxPreamble: Integer; override;
  public
    class function Description: string; override;
    class function Ext: string; override;
    class function MimeType: string; override;
    class function GetSize(AStream: TStream; out ASize: TSize): Boolean; override;
  end;

  { TACLImageFormatPNG }

  TACLImageFormatPNG = class(TACLImageFormat)
  strict private
    class var FClipboardFormat: Word;
  protected
    class function GetMaxPreamble: Integer; override;
    class function CheckPreamble(AData: PByte; AMaxSize: Integer): Boolean; override;
  public
    class function ClipboardFormat: Word; override;
    class function Description: string; override;
    class function Ext: string; override;
    class function MimeType: string; override;
    class function GetSize(AStream: TStream; out ASize: TSize): Boolean; override;
  end;

  { TACLImageFormatWebP }

  // https://developers.google.com/speed/webp
  TACLImageFormatWebP = class(TACLImageFormat)
  strict private type
    TDecodeFunc = function (const data: PByte; size: Cardinal; width, height: PInteger): PByte; cdecl;
    TEncodeFunc = function (const rgba: PByte; width, height, stride: Integer; quality: Single; var output: PByte): Cardinal; cdecl;
    TFreeFunc = procedure (P: Pointer); cdecl;
    TGetInfoFunc = function (const data: PByte; size: Cardinal; width, height: PInteger): Integer; cdecl;
  strict private
    class var FDecodeFunc: TDecodeFunc;
    class var FEncodeFunc: TEncodeFunc;
    class var FFreeFunc: TFreeFunc;
    class var FGetInfoFunc: TGetInfoFunc;
    class var FLibHandle: THandle;
  protected
    class function CheckIsAvailable: Boolean; override;
    class function CheckPreamble(AData: PByte; AMaxSize: Integer): Boolean; override;
    class function GetMaxPreamble: Integer; override;
    class function Load(AStream: TStream): GpBitmap; override;
    class procedure Save(AStream: TStream; ABitmap: GpBitmap); override;
  public
    class destructor Destroy;
    class function Description: string; override;
    class function Ext: string; override;
    class function MimeType: string; override;
    class function GetSize(AStream: TStream; out ASize: TSize): Boolean; override;
  end;

function acGraphicToBitmap(AGraphic: TGraphic): TACLBitmap;
implementation

uses
  Math,
  ACL.FastCode,
  ACL.Math,
  ACL.Utils.FileSystem,
  ACL.Utils.Stream;

function acGraphicToBitmap(AGraphic: TGraphic): TACLBitmap;
begin
  if AGraphic.SupportsPartialTransparency then
  begin
    Result := TACLBitmap.CreateEx(AGraphic.Width, AGraphic.Height, pf32bit, True);
    Result.Canvas.Draw(0, 0, AGraphic);
  end
  else
    if AGraphic.Transparent then
    begin
      Result := TACLBitmap.CreateEx(AGraphic.Width, AGraphic.Height);
      Result.Canvas.Brush.Color := clFuchsia;
      Result.Canvas.FillRect(Result.ClientRect);
      Result.Canvas.Draw(0, 0, AGraphic);
      Result.MakeTransparent(clFuchsia);
    end
    else
    begin
      Result := TACLBitmap.CreateEx(AGraphic.Width, AGraphic.Height, pf24bit);
      Result.Canvas.Draw(0, 0, AGraphic);
    end;
end;

{ EACLImageUnsupportedFormat }

constructor EACLImageUnsupportedFormat.Create;
begin
  inherited Create('The image that you specified has unsupported file format');
end;

{ TACLImage }

constructor TACLImage.Create;
begin
  StretchQuality := sqDefault;
  PixelOffsetMode := ipomDefault;
end;

constructor TACLImage.Create(ABitmap: HBITMAP);
begin
  Create;
  LoadFromBitmap(ABitmap);
end;

constructor TACLImage.Create(ABitmap: TBitmap; AAlphaFormat: TAlphaFormat = afPremultiplied);
begin
  Create;
  LoadFromBitmap(ABitmap, AAlphaFormat);
end;

constructor TACLImage.Create(AInstance: HINST; const AResName: UnicodeString; AResType: PWideChar);
begin
  Create;
  LoadFromResource(AInstance, AResName, AResType);
end;

constructor TACLImage.Create(AStream: TStream);
begin
  Create;
  AStream.Position := 0; // to keep old behavior
  LoadFromStream(AStream);
end;

constructor TACLImage.Create(const AFileName: UnicodeString);
begin
  Create;
  LoadFromFile(AFileName);
end;

constructor TACLImage.Create(AWidth, AHeight: Integer);
begin
  Create;
  SetHandle(GpCreateBitmap(AWidth, AHeight));
end;

constructor TACLImage.Create(const ABits: PRGBQuad; AWidth, AHeight: Integer);
begin
  Create;
  LoadFromBits(ABits, AWidth, AHeight);
end;

destructor TACLImage.Destroy;
begin
  DestroyHandle;
  inherited Destroy;
end;

procedure TACLImage.Assign(ASource: TObject);
begin
  if ASource is TBitmap then
    LoadFromBitmap(TBitmap(ASource))
  else if ASource is TGraphic then
    LoadFromGraphic(TGraphic(ASource))
  else if ASource is TACLImage then
    SetHandle(TACLImage(ASource).CloneHandle);
end;

procedure TACLImage.ApplyColorSchema(const AColorSchema: TACLColorSchema);
var
  AData: TBitmapData;
begin
  if AColorSchema.IsAssigned then
  begin
    if BeginLock(AData) then
    try
      TACLColors.ApplyColorSchema(AData.Scan0, AData.Width * AData.Height, AColorSchema);
    finally
      EndLock(AData)
    end;
  end;
end;

procedure TACLImage.ConvertToBitmap;
var
  AGraphics: GpGraphics;
  ANewHandle: GpImage;
  AWidth, AHeight: Cardinal;
begin
  if not Empty then
  begin
    GdipCheck(GdipGetImageWidth(Handle, AWidth));
    GdipCheck(GdipGetImageHeight(Handle, AHeight));
    ANewHandle := GpCreateBitmap(AWidth, AHeight);
    if ANewHandle = nil then
      raise Exception.Create('Internal Error');
    GdipCheck(GdipGetImageGraphicsContext(ANewHandle, AGraphics));
    GpDrawImage(AGraphics, Handle, Rect(0, 0, AWidth, AHeight), Rect(0, 0, AWidth, AHeight), False);
    GdipCheck(GdipDeleteGraphics(AGraphics));
    SetHandle(ANewHandle);
  end;
end;

function TACLImage.Clone: TACLImage;
var
  ANewHandle: GpImage;
begin
  Result := TACLImage.Create;
  if GdipCloneImage(Handle, ANewHandle) = Ok then
  begin
    Result.FFormat := Format;
    Result.FStretchQuality := FStretchQuality;
    Result.FPixelOffsetMode := FPixelOffsetMode;
    Result.SetHandle(ANewHandle);
  end;
end;

function TACLImage.ToBitmap(AAlphaFormat: TAlphaFormat = afIgnored): TACLBitmap;

  function CloneAsBitmapCore(const AData: TBitmapData; ASourceAlphaFormat: TAlphaFormat; AMakeOpaque: Boolean): TACLBitmap;
  begin
    Result := TACLBitmap.Create;
    Result.AlphaFormat := ASourceAlphaFormat;
    Result.HandleType := bmDIB;
    Result.Handle := CreateBitmap(AData.Width, AData.Height, 1, 32, AData.Scan0);
    if AMakeOpaque then
      Result.MakeOpaque
    else
      Result.AlphaFormat := AAlphaFormat;
  end;

var
  AData: TBitmapData;
  AHandle: HBITMAP;
begin
  Result := nil;
  if BeginLock(AData) then
  try
    case AData.PixelFormat of
      PixelFormat32bppARGB:
        Result := CloneAsBitmapCore(AData, afIgnored, False);
      PixelFormat32bppPARGB:
        Result := CloneAsBitmapCore(AData, afPremultiplied, False);
      PixelFormat32bppRGB:
        Result := CloneAsBitmapCore(AData, afIgnored, True);
    end;
  finally
    EndLock(AData)
  end;

  if Result = nil then
  begin
    GdipCreateHBITMAPFromBitmap(Handle, AHandle, clBlack);
    Result := TACLBitmap.Create;
    Result.Handle := AHandle;
  end;
end;

procedure TACLImage.Draw(DC: HDC; const R, ASource: TRect; const AMargins: TRect; AAlpha: Byte = $FF; ATile: Boolean = False);
var
  AGraphics: GpGraphics;
begin
  GdipCreateFromHDC(DC, AGraphics);
  Draw(AGraphics, R, ASource, AMargins, AAlpha, ATile);
  GdipDeleteGraphics(AGraphics);
end;

procedure TACLImage.Draw(DC: HDC; const R, ASource: TRect; AAlpha: Byte = $FF; ATile: Boolean = False);
var
  AGraphics: GpGraphics;
begin
  GdipCreateFromHDC(DC, AGraphics);
  Draw(AGraphics, R, ASource, AAlpha, ATile);
  GdipDeleteGraphics(AGraphics);
end;

procedure TACLImage.Draw(DC: HDC; const R: TRect; AAlpha: Byte = $FF; ATile: Boolean = False);
var
  AGraphics: GpGraphics;
begin
  GdipCreateFromHDC(DC, AGraphics);
  Draw(AGraphics, R, AAlpha, ATile);
  GdipDeleteGraphics(AGraphics);
end;

procedure TACLImage.Draw(Graphics: GpGraphics; const R, ASource, AMargins: TRect; AAlpha: Byte = $FF; ATile: Boolean = False);
var
  ADestParts: TACLMarginPartBounds;
  ASourceParts: TACLMarginPartBounds;
  APart: TACLMarginPart;
begin
  if acMarginIsEmpty(AMargins) then
    Draw(Graphics, R, ASource, AAlpha, ATile)
  else
  begin
    acMarginCalculateRects(R, AMargins, ASource, ADestParts);
    acMarginCalculateRects(ASource, AMargins, ASource, ASourceParts);
    for APart := Low(APart) to High(APart) do
      Draw(Graphics, ADestParts[APart], ASourceParts[APart], AAlpha, ATile);
  end;
end;

procedure TACLImage.Draw(Graphics: GpGraphics; const R, ASource: TRect; AAlpha: Byte = $FF; ATile: Boolean = False);
const
  PixelOffsetModeMap: array[TACLImagePixelOffsetMode] of TPixelOffsetMode = (
    PixelOffsetModeDefault, PixelOffsetModeHalf, PixelOffsetModeNone
  );
  ComposingModeMap: array[TACLImageCompositingMode] of TCompositingMode = (
    CompositingModeSourceOver,
    CompositingModeSourceCopy
  );
  StretchQualityMap: array[TACLImageStretchQuality] of TInterpolationMode = (
    InterpolationModeDefault,
    InterpolationModeLowQuality,
    InterpolationModeHighQuality,
    InterpolationModeBilinear,
    InterpolationModeBicubic,
    InterpolationModeNearestNeighbor,
    InterpolationModeHighQualityBilinear,
    InterpolationModeHighQualityBicubic
  );
var
  APrevComposingMode: TCompositingMode;
  APrevInterpolationMode: TInterpolationMode;
  APrevPixelOffsetMode: TPixelOffsetMode;
begin
  if (PixelOffsetMode <> ipomDefault) or (StretchQuality <> sqDefault) or (ComposingMode <> cmOver) then
  begin
    GdipCheck(GdipGetCompositingMode(Graphics, APrevComposingMode));
    GdipCheck(GdipGetPixelOffsetMode(Graphics, APrevPixelOffsetMode));
    GdipCheck(GdipGetInterpolationMode(Graphics, APrevInterpolationMode));
    try
      if PixelOffsetMode <> ipomDefault then
        GdipSetPixelOffsetMode(Graphics, PixelOffsetModeMap[PixelOffsetMode]);
      if StretchQuality <> sqDefault then
        GdipSetInterpolationMode(Graphics, StretchQualityMap[StretchQuality]);
      GdipSetCompositingMode(Graphics, ComposingModeMap[ComposingMode]);
      GpDrawImage(Graphics, FHandle, R, ASource, ATile, AAlpha);
    finally
      GdipCheck(GdipSetInterpolationMode(Graphics, APrevInterpolationMode));
      GdipCheck(GdipSetPixelOffsetMode(Graphics, APrevPixelOffsetMode));
      GdipCheck(GdipSetCompositingMode(Graphics, APrevComposingMode));
    end;
  end
  else
    GpDrawImage(Graphics, FHandle, R, ASource, ATile, AAlpha);
end;

procedure TACLImage.Draw(Graphics: GpGraphics; const R: TRect; AAlpha: Byte = $FF; ATile: Boolean = False);
begin
  Draw(Graphics, R, ClientRect, AAlpha, ATile);
end;

function TACLImage.BeginLock(var AData: TBitmapData): Boolean;
var
  AFormat: Integer;
begin
  Result :=
    (GdipGetImagePixelFormat(Handle, AFormat) = Ok) and
    (GdipBitmapLockBits(Handle, nil, ImageLockModeRead, AFormat, @AData) = Ok);
end;

function TACLImage.EndLock(var AData: TBitmapData): Boolean;
begin
  Result := GdipBitmapUnlockBits(Handle, @AData) = Ok;
end;

procedure TACLImage.Crop(const ACropMargins: TRect);
begin
  CropAndResize(ACropMargins, Width - acMarginWidth(ACropMargins), Height - acMarginHeight(ACropMargins));
end;

procedure TACLImage.CropAndResize(const ACropMargins: TRect; AWidth, AHeight: Integer);
var
  AGraphics: GpGraphics;
  AHandle: GpImage;
begin
  if (AWidth <> Width) or (AHeight <> Height) or (ACropMargins <> NullRect) then
  begin
    if (AWidth <= 0) or (AHeight <= 0) then
      raise EInvalidOperation.CreateFmt('The %dx%d is not valid resolution for an image', [AWidth, AHeight]);

    AHandle := GpCreateBitmap(AWidth, AHeight);
    if AHandle <> nil then
    begin
      GdipGetImageGraphicsContext(AHandle, AGraphics);
      GdipSetPixelOffsetMode(AGraphics, PixelOffsetModeHalf);
      Draw(AGraphics, Rect(0, 0, AWidth, AHeight), acRectContent(ClientRect, ACropMargins));
      GdipDeleteGraphics(AGraphics);
      SetHandle(AHandle);
    end;
  end;
end;

procedure TACLImage.Resize(AWidth, AHeight: Integer);
begin
  CropAndResize(NullRect, AWidth, AHeight);
end;

procedure TACLImage.Scale(ANumerator, ADenominator: Integer);
begin
  if ANumerator <> ADenominator then
    Resize(MulDiv(Width, ANumerator, ADenominator), MulDiv(Height, ANumerator, ADenominator));
end;

procedure TACLImage.Scale(AScaleFactor: Single);
begin
  if not SameValue(AScaleFactor, 1) then
    Resize(Round(AScaleFactor * Width), Round(AScaleFactor * Height));
end;

procedure TACLImage.LoadFromBitmap(ABitmap: HBITMAP; APalette: HPALETTE = 0);
var
  AHandle: GpImage;
begin
  GdipCheck(GdipCreateBitmapFromHBITMAP(ABitmap, APalette, AHandle));
  LoadFromHandle(AHandle);
end;

procedure TACLImage.LoadFromBitmap(ABitmap: TBitmap; AAlphaFormat: TAlphaFormat = afPremultiplied);
begin
  if ABitmap.PixelFormat <> pf32bit then
    LoadFromBitmap(ABitmap.Handle, ABitmap.Palette)
  else
    LoadFromBits(@acGetBitmapBits(ABitmap)[0], ABitmap.Width, ABitmap.Height, AAlphaFormat);
end;

procedure TACLImage.LoadFromBits(ABits: PRGBQuad; AWidth, AHeight: Integer; AAlphaFormat: TAlphaFormat = afPremultiplied);
var
  ACount: Integer;
  I: Integer;
begin
  ACount := AWidth * AHeight;
  SetLength(FBits, ACount);
  FastMove(ABits^, FBits[0], ACount * SizeOf(TRGBQuad));
  if AAlphaFormat = afIgnored then
  begin
    for I := 0 to ACount - 1 do
      FBits[I].rgbReserved := MaxByte;
  end;
  LoadFromHandle(GpCreateBitmap(AWidth, AHeight, @FBits[0],
    IfThen(AAlphaFormat = afPremultiplied, PixelFormat32bppPARGB, PixelFormat32bppARGB)));
end;

procedure TACLImage.LoadFromFile(const AFileName: UnicodeString);
var
  AStream: TACLFileStream;
begin
  AStream := TACLFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(AStream)
  finally
    AStream.Free;
  end;
end;

procedure TACLImage.LoadFromGraphic(AGraphic: TGraphic);
var
  ABitmap: TACLBitmap;
begin
  ABitmap := acGraphicToBitmap(AGraphic);
  try
    LoadFromBitmap(ABitmap);
  finally
    ABitmap.Free;
  end;
end;

procedure TACLImage.LoadFromResource(AInstance: HINST; const AResName: UnicodeString; AResType: PWideChar);
var
  AStream: TStream;
begin
  AStream := TResourceStream.Create(AInstance, AResName, AResType);
  try
    LoadFromStream(AStream);
  finally
    AStream.Free;
  end;
end;

procedure TACLImage.LoadFromStream(AStream: TStream);
var
  AFormat: TACLImageFormatClass;
begin
  AFormat := TACLImageFormatRepository.GetFormat(AStream);
  if AFormat = nil then
  begin
    // Backward-compatibility:
    //   Old plugins that put here formats that can be opened by GDI+ but has no handlers in our repository (like ICO, EMF)
    // raise EACLImageUnsupportedFormat.Create;
    AFormat := TACLImageFormatBMP;
  end;
  LoadFromHandle(AFormat.Load(AStream), AFormat);
end;

procedure TACLImage.SaveToFile(const AFileName: UnicodeString);
begin
  SaveToFile(AFileName, Format);
end;

procedure TACLImage.SaveToFile(const AFileName: UnicodeString; AFormat: TACLImageFormatClass);
var
  AStream: TACLFileStream;
begin
  AStream := TACLFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(AStream, AFormat)
  finally
    AStream.Free;
  end;
end;

procedure TACLImage.SaveToStream(AStream: TStream);
begin
  SaveToStream(AStream, Format);
end;

procedure TACLImage.SaveToStream(AStream: TStream; AFormat: TACLImageFormatClass);
begin
  if Empty then
    raise EInvalidOperation.Create('Image is empty');
  AFormat.Save(AStream, Handle);
end;

function TACLImage.CloneHandle: GpImage;
begin
  if Handle <> nil then
    GdipCheck(GdipCloneImage(Handle, Result))
  else
    Result := nil;
end;

procedure TACLImage.DestroyHandle;
begin
  if Assigned(Handle) then
  begin
    GdipDisposeImage(Handle);
    FHandle := nil;
    SetLength(FBits, 0);
  end;
end;

procedure TACLImage.LoadFromHandle(AHandle: GpImage; AFormat: TACLImageFormatClass = nil);
var
  ID: TGUID;
begin
  SetHandle(AHandle);

  if AFormat <> nil then
    FFormat := AFormat
  else
    FFormat := TACLImageFormatBMP;

  if GdipGetImageRawFormat(AHandle, @ID) = OK then
  begin
    if IsEqualGUID(ID, ImageFormatGIF) then
      FFormat := TACLImageFormatGIF
    else if IsEqualGUID(ID, ImageFormatJPEG) then
      FFormat := TACLImageFormatJPG
    else if IsEqualGUID(ID, ImageFormatPNG) then
      FFormat := TACLImageFormatPNG
    else if IsEqualGUID(ID, ImageFormatMemoryBMP) then
      Exit;
  end;

  //#AI: 1. To unlink image handle from source data.
  //     2. Gdi+ works with memory-bitmaps faster than with other formats
  if FFormat <> TACLImageFormatPNG then // to keep alpha channel unpremultiplied
    ConvertToBitmap;
end;

function TACLImage.GetClientRect: TRect;
var
  W, H: Single;
begin
  if GdipGetImageDimension(Handle, W, H) = Ok then
    Result := Rect(0, 0, Trunc(W), Trunc(H))
  else
    Result := NullRect;
end;

function TACLImage.GetIsEmpty: Boolean;
begin
  Result := Handle = nil;
end;

function TACLImage.GetHeight: Integer;
begin
  if GdipGetImageHeight(Handle, Cardinal(Result)) <> Ok then
    Result := 0;
end;

function TACLImage.GetWidth: Integer;
begin
  if GdipGetImageWidth(Handle, Cardinal(Result)) <> Ok then
    Result := 0;
end;

procedure TACLImage.SetHandle(AValue: GpImage);
begin
  if FHandle <> AValue then
  begin
    DestroyHandle;
    FHandle := AValue;
  end;
end;

{ TACLImageFormat }

class function TACLImageFormat.CheckIsAvailable: Boolean;
begin
  Result := True;
end;

class function TACLImageFormat.ClipboardFormat: Word;
begin
  Result := 0;
end;

class function TACLImageFormat.Load(AStream: TStream): GpBitmap;
var
  AGdiPlusStream: IStream;
begin
  AGdiPlusStream := TACLGdiplusStream.Create(AStream, soReference);
  GdipCheck(GdipCreateBitmapFromStream(AGdiPlusStream, Result));
end;

class procedure TACLImageFormat.Save(AStream: TStream; ABitmap: GpBitmap);
var
  ACodecID: TGUID;
  AStreamIntf: IStream;
begin
  if GpGetCodecByMimeType(MimeType, ACodecID) then
  begin
    AStreamIntf := TStreamAdapter.Create(AStream, soReference);
    GdipCheck(GdipSaveImageToStream(ABitmap, AStreamIntf, @ACodecID, nil));
    AStreamIntf := nil;
  end
  else
    raise EACLImageFormatError.CreateFmt('GDI+ has no codec for the "%s" mime-type', [MimeType]);
end;

{ TACLImageFormatRepository }

class constructor TACLImageFormatRepository.Create;
begin
  // do not change the order
  Register(TACLImageFormatPNG); // must be before BMP
  Register(TACLImageFormatBMP);
  Register(TACLImageFormatGIF);
  Register(TACLImageFormatJPG);
  Register(TACLImageFormatJPEG); // must be after JPG
  Register(TACLImageFormatWebP);
end;

class destructor TACLImageFormatRepository.Destroy;
begin
  FreeAndNil(FFormats);
end;

class procedure TACLImageFormatRepository.Register(AFormat: TACLImageFormatClass);
begin
  if AFormat.CheckIsAvailable then
  begin
    if FFormats = nil then
      FFormats := TList.Create;
    FFormats.Add(AFormat);
    FMaxPreamble := Max(FMaxPreamble, AFormat.GetMaxPreamble);
  end;
end;

class procedure TACLImageFormatRepository.Unregister(AFormat: TACLImageFormatClass);
begin
  if FFormats <> nil then
  begin
    FFormats.Remove(AFormat);
    if FFormats.Count = 0 then
      FreeAndNil(FFormats);
  end;
end;

class function TACLImageFormatRepository.GetFormat(const AContainer: IACLDataContainer): TACLImageFormatClass;
begin
  if AContainer <> nil then
    Result := GetFormat(AContainer.GetDataPtr, AContainer.GetDataSize)
  else
    Result := nil;
end;

class function TACLImageFormatRepository.GetFormat(AData: PByte; ADataSize: Integer): TACLImageFormatClass;
var
  AFormat: TACLImageFormatClass;
  I: Integer;
begin
  if FFormats <> nil then
    for I := 0 to FFormats.Count - 1 do
    begin
      AFormat := FFormats.List[I];
      if (ADataSize >= AFormat.GetMaxPreamble) and AFormat.CheckPreamble(AData, ADataSize) then
        Exit(AFormat);
    end;

  Result := nil;
end;

class function TACLImageFormatRepository.GetFormat(const AMimeType: string): TACLImageFormatClass;
var
  AFormat: TACLImageFormatClass;
  I: Integer;
begin
  if FFormats <> nil then
    for I := 0 to FFormats.Count - 1 do
    begin
      AFormat := FFormats.List[I];
      if acSameText(AMimeType, AFormat.MimeType) then
        Exit(AFormat);
    end;

  Result := nil;
end;

class function TACLImageFormatRepository.GetFormat(const AStream: TStream): TACLImageFormatClass;
var
  ABytes: TBytes;
  ASavedPosition: Int64;
begin
  ASavedPosition := AStream.Position;
  try
    SetLength(ABytes, FMaxPreamble);
    if AStream.Read(ABytes, FMaxPreamble) = FMaxPreamble then
      Result := GetFormat(@ABytes[0], FMaxPreamble)
    else
      Result := nil;
  finally
    AStream.Position := ASavedPosition;
  end;
end;

class function TACLImageFormatRepository.GetFormatByExt(const AExt: string): TACLImageFormatClass;
var
  AFormat: TACLImageFormatClass;
  I: Integer;
begin
  if FFormats <> nil then
    for I := 0 to FFormats.Count - 1 do
    begin
      AFormat := FFormats.List[I];
      if acSameText(AExt, AFormat.Ext) then
        Exit(AFormat);
    end;

  Result := nil;
end;

class function TACLImageFormatRepository.GetDialogFilter(
  const AContainer: IACLDataContainer; out AFilter, AExt: UnicodeString): Boolean;
begin
  Result := GetDialogFilter(GetMimeType(AContainer), AFilter, AExt);
end;

class function TACLImageFormatRepository.GetDialogFilter(
  const AMimeType: UnicodeString; out AFilter, AExt: UnicodeString): Boolean;
var
  AFormat: TACLImageFormatClass;
begin
  AFormat := GetFormat(AMimeType);
  Result := AFormat <> nil;
  if Result then
  begin
    AExt := AFormat.Ext;
    AFilter := BuildDialogFilter(AFormat.Description, '*' + AExt + ';');
  end;
end;

class function TACLImageFormatRepository.GetDialogFilter: string;
begin
  Result := BuildDialogFilter('All Supported', GetExtList);
end;

class function TACLImageFormatRepository.GetExtList: string;
var
  ABuilder: TStringBuilder;
begin
  if FFormats <> nil then
  begin
    ABuilder := TACLStringBuilderManager.Get;
    try
      for var I := 0 to FFormats.Count - 1 do
        ABuilder.Append('*' + TACLImageFormatClass(FFormats.List[I]).Ext + ';');
      Result := ABuilder.ToString;
    finally
      TACLStringBuilderManager.Release(ABuilder)
    end;
  end
  else
    Result := EmptyStr;
end;

class function TACLImageFormatRepository.GetMimeType(const AFormat: TACLImageFormatClass): UnicodeString;
begin
  if AFormat <> nil then
    Result := AFormat.MimeType
  else
    Result := EmptyStr;
end;

class function TACLImageFormatRepository.GetMimeType(const AContainer: IACLDataContainer): UnicodeString;
begin
  Result := GetMimeType(GetFormat(AContainer));
end;

class function TACLImageFormatRepository.GetMimeType(const AExt: UnicodeString): UnicodeString;
var
  AFormat: TACLImageFormatClass;
  I: Integer;
begin
  if FFormats <> nil then
    for I := 0 to FFormats.Count - 1 do
    begin
      AFormat := FFormats.List[I];
      if acSameText(AExt, AFormat.Ext) then
        Exit(AFormat.MimeType);
    end;

  Result := '';
end;

class function TACLImageFormatRepository.GetMimeType(const AStream: TStream): UnicodeString;
begin
  Result := GetMimeType(GetFormat(AStream));
end;

class function TACLImageFormatRepository.GetImageInfo(
  AContainer: IACLDataContainer; out AFormat: TACLImageFormatClass; out ADimensions: TSize): Boolean;
var
  AData: TMemoryStream;
begin
  if AContainer <> nil then
  begin
    AData := AContainer.LockData;
    try
      AData.Position := 0;
      Result := GetImageInfo(AData, AFormat, ADimensions);
    finally
      AContainer.UnlockData;
    end;
  end
  else
    Result := False;
end;

class function TACLImageFormatRepository.GetImageInfo(
  AStream: TStream; out AFormat: TACLImageFormatClass; out ADimensions: TSize): Boolean;
begin
  AFormat := GetFormat(AStream);
  Result := (AFormat <> nil) and AFormat.GetSize(AStream, ADimensions);
end;

class function TACLImageFormatRepository.BuildDialogFilter(const ADescription, AExts: string): string;
begin
  Result := Format('%0:s (%1:s)|%1:s', [ADescription, AExts]);
end;

{ TACLImageFormatBMP }

class function TACLImageFormatBMP.CheckPreamble(AData: PByte; AMaxSize: Integer): Boolean;
begin
  Result := PWord(AData)^ = FormatPreamble;
end;

class function TACLImageFormatBMP.ClipboardFormat: Word;
begin
  Result := CF_BITMAP;
end;

class function TACLImageFormatBMP.Description: string;
begin
  Result := 'Bitmap Image';
end;

class function TACLImageFormatBMP.Ext: string;
begin
  Result := '.bmp';
end;

class function TACLImageFormatBMP.GetMaxPreamble: Integer;
begin
  Result := 2;
end;

class function TACLImageFormatBMP.MimeType: string;
begin
  Result := 'image/bmp';
end;

class function TACLImageFormatBMP.GetSize(AStream: TStream; out ASize: TSize): Boolean;
var
  ABitmapInfo: TBitmapInfo;
  AFileHeader: TBitmapFileHeader;
  AHeaderSize: Integer;
  AOS2Header: TBitmapCoreHeader;
begin
  Result := False;
  try
    AStream.ReadBuffer(AFileHeader, SizeOf(AFileHeader));
    if AFileHeader.bfType = FormatPreamble then
    begin
      AHeaderSize := AStream.ReadInt32;
      if AHeaderSize = SizeOf(AOS2Header) then
      begin
        AStream.ReadBuffer((PByte(@AOS2Header) + SizeOf(AHeaderSize))^, SizeOf(AOS2Header) - SizeOf(AHeaderSize));
        ASize.cx := AOS2Header.bcWidth;
        ASize.cy := AOS2Header.bcHeight;
      end
      else
      begin
        AStream.ReadBuffer((PByte(@ABitmapInfo) + SizeOf(AHeaderSize))^, SizeOf(ABitmapInfo) - SizeOf(AHeaderSize));
        ASize.cx := ABitmapInfo.bmiHeader.biWidth;
        ASize.cy := ABitmapInfo.bmiHeader.biHeight;
      end;
      Result := (ASize.cx > 0) and (ASize.cy > 0);
    end;
  except
    Result := False;
  end;
end;

{ TACLImageFormatJPEG }

class function TACLImageFormatJPEG.CheckPreamble(AData: PByte; AMaxSize: Integer): Boolean;
begin
  Result := (PCardinal(AData)^ and $00FFFFFF) = $FFD8FF;
end;

class function TACLImageFormatJPEG.GetMaxPreamble: Integer;
begin
  Result := 3;
end;

class function TACLImageFormatJPEG.Description: string;
begin
  Result := 'JPEG Image';
end;

class function TACLImageFormatJPEG.Ext: string;
begin
  Result := '.jpeg';
end;

class function TACLImageFormatJPEG.MimeType: string;
begin
  Result := 'image/jpeg';
end;

class function TACLImageFormatJPEG.GetSize(AStream: TStream; out ASize: TSize): Boolean;
var
  AData: array [0..4] of Byte;
  ADataSize: Word;
  AMarker: Word;
begin
  Result := False;
  try
    repeat
      AMarker := AStream.ReadWord;
      if Lo(AMarker) <> $FF then
        Break;

      if Hi(AMarker) in [$D8, $D9] then
        ADataSize := 0
      else
        ADataSize := AStream.ReadWordBE - SizeOf(ADataSize);

      case Hi(AMarker) of
        $D9, $DA:
          Break;
        $C0..$C3, $C5..$C7, $C9..$CB, $CD..$CF:
          begin
            AStream.ReadBuffer(AData, SizeOf(AData));
            ASize.cx := AData[4] or AData[3] shl 8;
            ASize.cy := AData[2] or AData[1] shl 8;
            Result := (ASize.cx > 0) and (ASize.cy > 0);
            Break;
          end;
      else
        AStream.Seek(ADataSize, soFromCurrent);
      end;
    until False;
  except
    Result := False;
  end;
end;

{ TACLImageFormatJPG }

class function TACLImageFormatJPG.Ext: string;
begin
  Result := '.jpg';
end;

class function TACLImageFormatJPG.MimeType: string;
begin
  Result := 'image/jpg';
end;

{ TACLImageFormatGIF }

class function TACLImageFormatGIF.CheckPreamble(AData: PByte; AMaxSize: Integer): Boolean;
begin
  Result := (PCardinal(AData)^ and $00FFFFFF) = $464947;
end;

class function TACLImageFormatGIF.GetMaxPreamble: Integer;
begin
  Result := 3;
end;

class function TACLImageFormatGIF.Description: string;
begin
  Result := 'GIF Image';
end;

class function TACLImageFormatGIF.Ext: string;
begin
  Result := '.gif';
end;

class function TACLImageFormatGIF.MimeType: string;
begin
  Result := 'image/gif';
end;

class function TACLImageFormatGIF.GetSize(AStream: TStream; out ASize: TSize): Boolean;
begin
  try
    AStream.Position := 6;
    ASize.cx := AStream.ReadWord;
    ASize.cy := AStream.ReadWord;
    Result := (ASize.cx > 0) and (ASize.cy > 0);
  except
    Result := False;
  end;
end;

{ TACLImageFormatPNG }

class function TACLImageFormatPNG.CheckPreamble(AData: PByte; AMaxSize: Integer): Boolean;
begin
  Result := (PCardinal(AData)^ and $FFFFFF00) = $474E5000;
end;

class function TACLImageFormatPNG.GetMaxPreamble: Integer;
begin
  Result := 4;
end;

class function TACLImageFormatPNG.ClipboardFormat: Word;
begin
  if FClipboardFormat = 0 then
    FClipboardFormat := RegisterClipboardFormat('PNG');
  Result := FClipboardFormat;
end;

class function TACLImageFormatPNG.Description: string;
begin
  Result := 'PNG Image';
end;

class function TACLImageFormatPNG.Ext: string;
begin
  Result := '.png';
end;

class function TACLImageFormatPNG.MimeType: string;
begin
  Result := 'image/png';
end;

class function TACLImageFormatPNG.GetSize(AStream: TStream; out ASize: TSize): Boolean;
begin
  Result := False;
  try
    if AStream.ReadInt64 = $A1A0A0D474E5089 then
    begin
      AStream.Seek(4, soFromCurrent); // Skip ChunkLength
      if AStream.ReadInt32 = $52444849 {IHDR} then
      begin
        ASize.cx := AStream.ReadInt32BE;
        ASize.cy := AStream.ReadInt32BE;
        Result := (ASize.cx > 0) and (ASize.cy > 0);
      end;
    end;
  except
    Result := False;
  end;
end;

{ TACLImageFormatWebP }

class destructor TACLImageFormatWebP.Destroy;
begin
  FEncodeFunc := nil;
  FDecodeFunc := nil;
  FFreeFunc := nil;
  FreeLibrary(FLibHandle);
end;

class function TACLImageFormatWebP.CheckIsAvailable: Boolean;
begin
  Result := True;
  FLibHandle := acLoadLibrary('libwebp.dll');
  @FGetInfoFunc := acGetProcAddress(FLibHandle, 'WebPGetInfo', Result);
  @FDecodeFunc := acGetProcAddress(FLibHandle, 'WebPDecodeRGBA', Result);
  @FEncodeFunc := acGetProcAddress(FLibHandle, 'WebPEncodeRGBA', Result);
  @FFreeFunc := acGetProcAddress(FLibHandle, 'WebPFree', Result);
end;

class function TACLImageFormatWebP.Description: string;
begin
  Result := 'Web Images';
end;

class function TACLImageFormatWebP.Ext: string;
begin
  Result := '.webp';
end;

class function TACLImageFormatWebP.GetSize(AStream: TStream; out ASize: TSize): Boolean;
var
  AAvailableSize: Int64;
begin
  AAvailableSize := AStream.Size - AStream.Position;
  if AStream is TCustomMemoryStream then
  begin
    Result := FGetInfoFunc(
      PByte(TCustomMemoryStream(AStream).Memory) + AStream.Position,
      AAvailableSize, @ASize.cx, @ASize.cy) <> 0
  end
  else
  begin
    AStream := TMemoryStream.CopyOf(AStream, AAvailableSize);
    try
      Result := GetSize(AStream, ASize);
    finally
      AStream.Free;
    end;
  end;
end;

class function TACLImageFormatWebP.MimeType: string;
begin
  Result := 'image/webp';
end;

class function TACLImageFormatWebP.CheckPreamble(AData: PByte; AMaxSize: Integer): Boolean;
var
  AOffset: Integer;
begin
  Result := acFindStringInMemoryA('WEBP', AData, Min(AMaxSize, GetMaxPreamble), 0, AOffset);
end;

class function TACLImageFormatWebP.GetMaxPreamble: Integer;
begin
  Result := 16;
end;

class function TACLImageFormatWebP.Load(AStream: TStream): GpBitmap;
var
  AAvailableSize: Int64;
  APixels: PByte;
  AHeight: Integer;
  AWidth: Integer;
begin
  AAvailableSize := AStream.Size - AStream.Position;
  if AStream is TCustomMemoryStream then
  begin
    APixels := FDecodeFunc(
      PByte(TCustomMemoryStream(AStream).Memory) + AStream.Position,
      AAvailableSize, @AWidth, @AHeight);
    if APixels = nil then
      raise EACLImageFormatError.Create('WebP returns no data');
    GdipCheck(GdipCreateBitmapFromScan0(AWidth, AHeight, AWidth * 4, PixelFormat32bppARGB, APixels, Result));
  end
  else
  begin
    AStream := TMemoryStream.CopyOf(AStream, AAvailableSize);
    try
      Result := Load(AStream);
    finally
      AStream.Free;
    end;
  end;
end;

class procedure TACLImageFormatWebP.Save(AStream: TStream; ABitmap: GpBitmap);
var
  AData: TBitmapData;
  AEncodedData: PByte;
  AEncodedSize: Cardinal;
begin
  GdipCheck(GdipBitmapLockBits(ABitmap, nil, ImageLockModeRead, PixelFormat32bppARGB, @AData));
  try
    AEncodedSize := FEncodeFunc(AData.Scan0, AData.Width, AData.Height, AData.Stride, 100, AEncodedData);
    try
      if AEncodedSize = 0 then
        raise EACLImageFormatError.Create('WebP failed to encode the image');
      AStream.WriteBuffer(AEncodedData^, AEncodedSize);
    finally
      if AEncodedData <> nil then
        FFreeFunc(AEncodedData);
    end;
  finally
    GdipCheck(GdipBitmapUnlockBits(ABitmap, @AData));
  end;
end;

end.
