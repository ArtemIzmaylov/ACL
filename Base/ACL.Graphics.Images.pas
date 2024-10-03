////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Images
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Graphics.Images;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  Cairo,
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.ActiveX,
  Winapi.GDIPOBJ,
  Winapi.GDIPAPI,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}ClipBrd,
  {Vcl.}Graphics,
  // ACL
  ACL.Classes.ByteBuffer,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Threading,
  ACL.Utils.Common,
  ACL.Utils.Clipboard,
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

  TACLImageHandle = {$IFDEF FPC}TACLDib{$ELSE}GpImage{$ENDIF};

  { TACLImage }

  TACLImage = class(TPersistent)
  strict private
  {$IFNDEF FPC}
    FBits: TACLPixel32DynArray;
  {$ENDIF}
    FComposingMode: TACLImageCompositingMode;
    FPixelOffsetMode: TACLImagePixelOffsetMode;
    FStretchQuality: TACLImageStretchQuality;
    FHandle: TACLImageHandle;

    function GetClientRect: TRect;
    function GetHeight: Integer;
    function GetIsEmpty: Boolean;
    function GetWidth: Integer;
    procedure SetHandle(AValue: TACLImageHandle);
  protected
    FFormat: TACLImageFormatClass;

    procedure Changed; virtual;
    procedure DestroyHandle;
    procedure LoadFromImage(AImage: TACLImage);
    procedure LoadFromHandle(AHandle: TACLImageHandle; AFormat: TACLImageFormatClass = nil);
  protected
  {$IFNDEF FPC}
    function BeginLock(var AData: TBitmapData;
      APixelFormat: Integer = PixelFormatUndefined;
      ALockMode: TImageLockMode = ImageLockModeRead): Boolean;
    function EndLock(var AData: TBitmapData): Boolean;
    function GetPixelFormat: Integer;
  {$ENDIF}
    property Handle: TACLImageHandle read FHandle;
  public
    constructor Create; overload;
    constructor Create(ABitmap: HBITMAP); overload;
    constructor Create(ABitmap: TBitmap; AAlphaFormat: TAlphaFormat = afPremultiplied); overload;
    constructor Create(AInstance: HINST; const AResName: string; AResType: PChar); overload;
    constructor Create(AStream: TStream); overload;
    constructor Create(AWidth, AHeight: Integer); overload;
    constructor Create(const ABits: PACLPixel32; AWidth, AHeight: Integer); overload;
    constructor Create(const AFileName: string); overload;
    destructor Destroy; override;
    procedure ApplyColorSchema(const AColorSchema: TACLColorSchema);
    procedure Assign(ASource: TPersistent); override;
    procedure AssignTo(ATarget: TPersistent); override;
    procedure Clear;
    procedure ConvertToBitmap;
    function Equals(Obj: TObject): Boolean; override;

    // Cloning
    function Clone: TACLImage;
    function ToBitmap(AAlphaFormat: TAlphaFormat = afIgnored): TACLBitmap;

    // Drawing
    procedure Draw(ACanvas: TCanvas; const ATarget, ASource, AMargins: TRect;
      AAlpha: Byte = MaxByte; ATile: Boolean = False); overload;
    procedure Draw(ACanvas: TCanvas; const ATarget, ASource: TRect;
      AAlpha: Byte = MaxByte; ATile: Boolean = False); overload;
    procedure Draw(ACanvas: TCanvas; const ATarget: TRect;
      AAlpha: Byte = MaxByte; ATile: Boolean = False); overload;
  {$IFNDEF FPC}
    procedure Draw(Graphics: GpGraphics; const R, ASource, AMargins: TRect;
      AAlpha: Byte = MaxByte; ATile: Boolean = False); overload;
    procedure Draw(Graphics: GpGraphics; const R, ASource: TRect;
      AAlpha: Byte = MaxByte; ATile: Boolean = False); overload;
    procedure Draw(Graphics: GpGraphics; const R: TRect;
      AAlpha: Byte = MaxByte; ATile: Boolean = False); overload;
  {$ENDIF}

    // Sizing
    procedure Crop(const ACropMargins: TRect);
    procedure CropAndResize(const ACropMargins: TRect; AWidth, AHeight: Integer);
    procedure Resize(AWidth, AHeight: Integer);
    procedure Scale(ANumerator, ADenominator: Integer); overload;
    procedure Scale(AScaleFactor: Single); overload;

    // I/O
    procedure LoadFromBitmap(ABitmap: HBITMAP; APalette: HPALETTE = 0); overload;
    procedure LoadFromBitmap(ABitmap: TACLDib; AAlphaFormat: TAlphaFormat = afPremultiplied); overload;
    procedure LoadFromBitmap(ABitmap: TBitmap; AAlphaFormat: TAlphaFormat = afPremultiplied); overload;
    procedure LoadFromBits(ABits: PACLPixel32; AWidth, AHeight: Integer; AAlphaFormat: TAlphaFormat = afPremultiplied);
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromGraphic(AGraphic: TGraphic);
    procedure LoadFromResource(AInstance: HINST; const AResName: string; AResType: PChar);
    procedure LoadFromStream(AStream: IACLDataContainer); overload;
    procedure LoadFromStream(AStream: TStream); overload;
    procedure SaveToDib(const ATarget: TACLDib);
    procedure SaveToFile(const AFileName: string); overload;
    procedure SaveToFile(const AFileName: string; AFormat: TACLImageFormatClass); overload;
    procedure SaveToStream(AStream: TStream); overload; virtual;
    procedure SaveToStream(AStream: TStream; AFormat: TACLImageFormatClass); overload;

    property ClientRect: TRect read GetClientRect;
    property Empty: Boolean read GetIsEmpty;
    property Format: TACLImageFormatClass read FFormat;
    property Height: Integer read GetHeight;
    property Width: Integer read GetWidth;
    //# Draw Settings
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

    class procedure Load(AStream: TStream; AImage: TACLImage); virtual;
    class procedure Save(AStream: TStream; AImage: TACLImage); virtual;
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

    class function GetDialogFilter(const AContainer: IACLDataContainer; out AFilter, AExt: string): Boolean; overload;
    class function GetDialogFilter(const AMimeType: string; out AFilter, AExt: string): Boolean; overload;
    class function GetDialogFilter: string; overload;
    class function GetExtList: string;

    class function GetMimeType(const AFormat: TACLImageFormatClass): string; overload;
    class function GetMimeType(const AContainer: IACLDataContainer): string; overload;
    class function GetMimeType(const AExt: string): string; overload;
    class function GetMimeType(const AStream: TStream): string; overload;

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

  { TACLImageFormatJPEG2 }

  TACLImageFormatJPEG2 = class(TACLImageFormatJPEG)
  public
    class function Ext: string; override;
  end;

  { TACLImageFormatJPG }

  TACLImageFormatJPG = class(TACLImageFormatJPEG)
  public
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
    TDecodeFunc = function (const data: PByte; size: Cardinal; width, height: PInteger): PRGBQuad; cdecl;
    TEncodeFunc = function (const rgba: PByte; width, height, stride: Integer; quality: Single; out output: PByte): Cardinal; cdecl;
    TFreeFunc = procedure (P: Pointer); cdecl;
    TGetInfoFunc = function (const data: PByte; size: Cardinal; width, height: PInteger): Integer; cdecl;
  strict private
    class var FDecodeFunc: TDecodeFunc;
    class var FEncodeFunc: TEncodeFunc;
    class var FFreeFunc: TFreeFunc;
    class var FGetInfoFunc: TGetInfoFunc;
    class var FLibHandle: HMODULE;
    class procedure Encode(AStream: TStream; AData: PByte; AWidth, AHeight: Integer);
  protected
    class function CheckIsAvailable: Boolean; override;
    class function CheckPreamble(AData: PByte; AMaxSize: Integer): Boolean; override;
    class function GetMaxPreamble: Integer; override;
    class procedure Load(AStream: TStream; AImage: TACLImage); override;
    class procedure Save(AStream: TStream; AImage: TACLImage); override;
  public
    class destructor Destroy;
    class function Description: string; override;
    class function Ext: string; override;
    class function MimeType: string; override;
    class function GetSize(AStream: TStream; out ASize: TSize): Boolean; override;
  end;

  { TACLImageTools }

  TACLImageTools = class
  protected
    class procedure CropAndResizeCore(const AImage: IACLDataContainer;
      AWidth, AHeight: Integer; AScale: Single; ACropMargins: TRect);
  public
    class function CanPasteFromClipboard: Boolean;
    class procedure CopyToClipboard(AImage: TACLImage);
    class procedure CropAndResize(const AImage: IACLDataContainer;
      AScale: Single; const ACropMargins: TRect);
    class procedure Resize(const AImage: IACLDataContainer;
      AWidth, AHeight: Integer);
    class function PasteFromClipboard: IACLDataContainer;
  end;

implementation

uses
{$IFDEF MSWINDOWS}
  ACL.FastCode,
  ACL.Math, // inlining
  ACL.Graphics.Ex.Gdip,
{$ELSE}
  ACL.Graphics.Ex.Cairo,
{$ENDIF}
  ACL.Utils.FileSystem,
  ACL.Utils.Stream;

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

constructor TACLImage.Create(AInstance: HINST; const AResName: string; AResType: PChar);
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

constructor TACLImage.Create(const AFileName: string);
begin
  Create;
  LoadFromFile(AFileName);
end;

constructor TACLImage.Create(AWidth, AHeight: Integer);
begin
  Create;
{$IFDEF FPC}
  SetHandle(TACLImageHandle.Create(AWidth, AHeight));
{$ELSE}
  SetHandle(GpCreateBitmap(AWidth, AHeight));
{$ENDIF}
end;

constructor TACLImage.Create(const ABits: PACLPixel32; AWidth, AHeight: Integer);
begin
  Create;
  LoadFromBits(ABits, AWidth, AHeight);
end;

destructor TACLImage.Destroy;
begin
  DestroyHandle;
  inherited Destroy;
end;

procedure TACLImage.Assign(ASource: TPersistent);
begin
  if ASource = nil then
    Clear
  else if ASource is TBitmap then
    LoadFromBitmap(TBitmap(ASource))
  else if ASource is TGraphic then
    LoadFromGraphic(TGraphic(ASource))
  else if ASource is TACLImage then
    LoadFromImage(TACLImage(ASource))
  else if ASource is TPicture then
    Assign(TPicture(ASource).Graphic)
  else
    inherited;
end;

procedure TACLImage.AssignTo(ATarget: TPersistent);
var
  AStream: TStream;
begin
  if ATarget is TPicture then
  begin
    if Empty then
      TPicture(ATarget).Graphic := nil
    else
    begin
      AStream := TMemoryStream.Create;
      try
        SaveToStream(AStream);
        AStream.Position := 0;
        TPicture(ATarget).LoadFromStream(AStream);
      finally
        AStream.Free;
      end;
    end;
  end
  else
    inherited;
end;

function TACLImage.Equals(Obj: TObject): Boolean;
var
{$IFNDEF FPC}
  LData1: TBitmapData;
  LData2: TBitmapData;
{$ENDIF}
  LImage: TACLImage absolute Obj;
begin
  Result := False;
  if Self = Obj then
    Exit(True);
  if Obj is TACLImage then
  begin
  {$IFDEF FPC}
    Result := (Handle <> nil) and Handle.Equals(LImage.Handle);
  {$ELSE}
    if (LImage.Width = Width) and (LImage.Height = Height) then
    begin
      if BeginLock(LData1) then
      try
        if LImage.BeginLock(LData2) then
        try
          Result :=
            (LData1.Width = LData2.Width) and
            (LData1.Height = LData2.Height) and
            (LData1.Stride = LData2.Stride) and
            (CompareMem(LData1.Scan0, LData2.Scan0, Cardinal(LData1.Stride) * LData1.Height));
        finally
          LImage.EndLock(LData2);
        end;
      finally
        EndLock(LData1);
      end;
    end;
  {$ENDIF}
  end;
end;

procedure TACLImage.ApplyColorSchema(const AColorSchema: TACLColorSchema);
{$IFDEF FPC}
begin
  if AColorSchema.IsAssigned then
    TACLColors.ApplyColorSchema(PACLPixel32(Handle.Colors), Handle.ColorCount, AColorSchema);
{$ELSE}
var
  LData: TBitmapData;
begin
  if AColorSchema.IsAssigned then
  begin
    if BeginLock(LData, ImageLockModeWrite, PixelFormat32bppARGB) then
    try
      TACLColors.ApplyColorSchema(LData.Scan0, LData.Width * LData.Height, AColorSchema);
    finally
      EndLock(LData)
    end;
  end;
{$ENDIF}
end;

procedure TACLImage.ConvertToBitmap;
{$IFDEF FPC}
begin
{$ELSE}
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
{$ENDIF}
end;

procedure TACLImage.Clear;
begin
  SetHandle(nil);
end;

function TACLImage.Clone: TACLImage;
begin
  Result := TACLImage.Create;
  Result.Assign(Self);
end;

function TACLImage.ToBitmap(AAlphaFormat: TAlphaFormat = afIgnored): TACLBitmap;
{$IFDEF FPC}
var
  LDib: TACLDib;
begin
  Result := nil;
  if (Handle <> nil) and not Handle.Empty then
  begin
    Result := TACLBitmap.CreateEx(Width, Height);
    if AAlphaFormat = afPremultiplied then
    begin
      LDib := TACLDib.Create;
      try
        LDib.Assign(Handle);
        LDib.Premultiply;
        LDib.AssignTo(Result);
      finally
        LDib.Free;
      end;
    end
    else
      Handle.AssignTo(Result);
  end;
end;
{$ELSE}

  function CloneAsBitmapCore(const AData: TBitmapData;
    ASourceAlphaFormat: TAlphaFormat; AMakeOpaque: Boolean): TACLBitmap;
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
  LData: TBitmapData;
  LHandle: HBITMAP;
begin
  Result := nil;
  if BeginLock(LData) then
  try
    case LData.PixelFormat of
      PixelFormat32bppARGB:
        Result := CloneAsBitmapCore(LData, afDefined, False);
      PixelFormat32bppPARGB:
        Result := CloneAsBitmapCore(LData, afPremultiplied, False);
      PixelFormat32bppRGB:
        Result := CloneAsBitmapCore(LData, afIgnored, True);
    end;
  finally
    EndLock(LData)
  end;

  if Result = nil then
  begin
    GdipCreateHBITMAPFromBitmap(Handle, LHandle, clBlack);
    Result := TACLBitmap.Create;
    Result.Handle := LHandle;
  end;
end;
{$ENDIF}

procedure TACLImage.Draw(ACanvas: TCanvas;
  const ATarget, ASource, AMargins: TRect; AAlpha: Byte; ATile: Boolean);
{$IFDEF FPC}
var
  LAlpha: Double;
  LPart: TACLMarginPart;
  LSource: Pcairo_surface_t;
  LSourceParts: TACLMarginPartBounds;
  LTargetParts: TACLMarginPartBounds;
begin
  if Handle = nil then
    Exit;

  LAlpha := AAlpha / 255;
  LSource := cairo_create_surface(Handle.Colors, Handle.Width, Handle.Height);
  try
    GpPaintCanvas.BeginPaint(ACanvas);
    try
      if AMargins.IsZero then
        GpPaintCanvas.FillSurface(ATarget, ASource, LSource, LAlpha, ATile)
      else
      begin
        acCalcPartBounds(LSourceParts, AMargins, ASource, ASource);
        acCalcPartBounds(LTargetParts, AMargins, ATarget, ASource);
        for LPart := Low(LPart) to High(LPart) do
          GpPaintCanvas.FillSurface(LTargetParts[LPart], LSourceParts[LPart], LSource, LAlpha, ATile);
      end;
    finally
      GpPaintCanvas.EndPaint;
    end;
  finally
    cairo_surface_destroy(LSource);
  end;
end;
{$ELSE}
var
  LGraphics: GpGraphics;
begin
  GdipCreateFromHDC(ACanvas.Handle, LGraphics);
  Draw(LGraphics, ATarget, ASource, AMargins, AAlpha, ATile);
  GdipDeleteGraphics(LGraphics);
end;
{$ENDIF}

procedure TACLImage.Draw(ACanvas: TCanvas;
  const ATarget, ASource: TRect; AAlpha: Byte; ATile: Boolean);
{$IFDEF FPC}
begin
  Draw(ACanvas, ATarget, ASource, NullRect, AAlpha, ATile);
end;
{$ELSE}
var
  LGraphics: GpGraphics;
begin
  GdipCreateFromHDC(ACanvas.Handle, LGraphics);
  Draw(LGraphics, ATarget, ASource, AAlpha, ATile);
  GdipDeleteGraphics(LGraphics);
end;
{$ENDIF}

procedure TACLImage.Draw(ACanvas: TCanvas;
  const ATarget: TRect; AAlpha: Byte; ATile: Boolean);
{$IFDEF FPC}
begin
  Draw(ACanvas, ATarget, ClientRect, NullRect, AAlpha, ATile);
end;
{$ELSE}
var
  LGraphics: GpGraphics;
begin
  GdipCreateFromHDC(ACanvas.Handle, LGraphics);
  Draw(LGraphics, ATarget, AAlpha, ATile);
  GdipDeleteGraphics(LGraphics);
end;
{$ENDIF}

{$IFNDEF FPC}
procedure TACLImage.Draw(Graphics: GpGraphics;
  const R, ASource, AMargins: TRect; AAlpha: Byte; ATile: Boolean);
var
  ADestParts: TACLMarginPartBounds;
  ASourceParts: TACLMarginPartBounds;
  APart: TACLMarginPart;
begin
  if AMargins.IsZero then
    Draw(Graphics, R, ASource, AAlpha, ATile)
  else
  begin
    acCalcPartBounds(ADestParts, AMargins, R, ASource);
    acCalcPartBounds(ASourceParts, AMargins, ASource, ASource);
    for APart := Low(APart) to High(APart) do
      Draw(Graphics, ADestParts[APart], ASourceParts[APart], AAlpha, ATile);
  end;
end;

procedure TACLImage.Draw(Graphics: GpGraphics;
  const R, ASource: TRect; AAlpha: Byte; ATile: Boolean);
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

procedure TACLImage.Draw(Graphics: GpGraphics; const R: TRect; AAlpha: Byte; ATile: Boolean);
begin
  Draw(Graphics, R, ClientRect, AAlpha, ATile);
end;

function TACLImage.BeginLock(var AData: TBitmapData; APixelFormat: Integer; ALockMode: TImageLockMode): Boolean;
begin
  if APixelFormat = PixelFormatUndefined then
    APixelFormat := GetPixelFormat;
  Result := GdipBitmapLockBits(Handle, nil, ALockMode, APixelFormat, @AData) = Ok;
end;

function TACLImage.EndLock(var AData: TBitmapData): Boolean;
begin
  Result := GdipBitmapUnlockBits(Handle, @AData) = Ok;
end;

function TACLImage.GetPixelFormat: Integer;
begin
  if GdipGetImagePixelFormat(FHandle, Result) <> Ok then
    Result := PixelFormatUndefined;
end;
{$ENDIF}

procedure TACLImage.Crop(const ACropMargins: TRect);
begin
  CropAndResize(ACropMargins,
    Width - ACropMargins.MarginsWidth,
    Height - ACropMargins.MarginsHeight);
end;

procedure TACLImage.CropAndResize(const ACropMargins: TRect; AWidth, AHeight: Integer);
var
  AHandle: TACLImageHandle;
{$IFDEF MSWINDOWS}
  AGraphics: GpGraphics;
{$ENDIF}
begin
  if (AWidth <> Width) or (AHeight <> Height) or (ACropMargins <> NullRect) then
  begin
    if (AWidth <= 0) or (AHeight <= 0) then
      raise EInvalidOperation.CreateFmt('The %dx%d is not valid resolution for an image', [AWidth, AHeight]);
  {$IFDEF MSWINDOWS}
    AHandle := GpCreateBitmap(AWidth, AHeight);
    if AHandle <> nil then
    begin
      GdipGetImageGraphicsContext(AHandle, AGraphics);
      GdipSetPixelOffsetMode(AGraphics, PixelOffsetModeHalf);
      Draw(AGraphics, Rect(0, 0, AWidth, AHeight), ClientRect.Split(ACropMargins));
      GdipDeleteGraphics(AGraphics);
      SetHandle(AHandle);
    end;
  {$ELSE}
    AHandle := TACLImageHandle.Create(AWidth, AHeight);
    Draw(AHandle.Canvas, Rect(0, 0, AWidth, AHeight), ClientRect.Split(ACropMargins));
    SetHandle(AHandle);
  {$ENDIF}
  end;
end;

procedure TACLImage.Resize(AWidth, AHeight: Integer);
begin
  CropAndResize(NullRect, AWidth, AHeight);
end;

procedure TACLImage.Scale(ANumerator, ADenominator: Integer);
begin
  if ANumerator <> ADenominator then
    Resize(
      MulDiv(Width, ANumerator, ADenominator),
      MulDiv(Height, ANumerator, ADenominator));
end;

procedure TACLImage.Scale(AScaleFactor: Single);
begin
  if not SameValue(AScaleFactor, 1) then
    Resize(Round(AScaleFactor * Width), Round(AScaleFactor * Height));
end;

procedure TACLImage.LoadFromBitmap(ABitmap: HBITMAP; APalette: HPALETTE = 0);
{$IFDEF FPC}
var
  LBitmap: TBitmap;
begin
  LBitmap := TBitmap.Create;
  try
    LBitmap.Handle := ABitmap;
    LBitmap.Palette := APalette;
    LoadFromBitmap(LBitmap);
  finally
    LBitmap.Free;
  end;
end;
{$ELSE}
var
  LHandle: GpImage;
begin
  if GdipCreateBitmapFromHBITMAP(ABitmap, APalette, LHandle) = Ok then
    LoadFromHandle(LHandle, nil);
end;
{$ENDIF}

procedure TACLImage.LoadFromBitmap(ABitmap: TBitmap; AAlphaFormat: TAlphaFormat);
begin
  if ABitmap.PixelFormat <> pf32bit then
    LoadFromBitmap(ABitmap.Handle, ABitmap.Palette)
  else
    LoadFromBits(@acGetBitmapBits(ABitmap)[0], ABitmap.Width, ABitmap.Height, AAlphaFormat);
end;

procedure TACLImage.LoadFromBitmap(ABitmap: TACLDib; AAlphaFormat: TAlphaFormat);
begin
  LoadFromBits(@ABitmap.Colors[0], ABitmap.Width, ABitmap.Height, AAlphaFormat);
end;

procedure TACLImage.LoadFromBits(ABits: PACLPixel32;
  AWidth, AHeight: Integer; AAlphaFormat: TAlphaFormat);
{$IFDEF FPC}
var
  LHandle: TACLImageHandle;
begin
  LHandle := TACLImageHandle.Create;
  LHandle.Assign(ABits, AWidth, AHeight);
  if AAlphaFormat = afIgnored then
    LHandle.MakeOpaque;
  LoadFromHandle(LHandle);
end;
{$ELSE}
const
  PixelFormatMap: array[TAlphaFormat] of Integer = (
    PixelFormat32bppARGB, // PixelFormat32bppRGB - однако мы сбросили альфу в 255
    PixelFormat32bppARGB,
    PixelFormat32bppPARGB
  );
var
  AColorCount: Integer;
  AColors: TACLPixel32DynArray;
begin
  AColorCount := AWidth * AHeight;
  SetLength(AColors, AColorCount);
  FastMove(ABits^, AColors[0], AColorCount * SizeOf(TRGBQuad));

  if AAlphaFormat = afIgnored then
  begin
    for var I := 0 to AColorCount - 1 do
      AColors[I].A := MaxByte;
  end;

  LoadFromHandle(GpCreateBitmap(AWidth, AHeight, @AColors[0], PixelFormatMap[AAlphaFormat]));
  FBits := AColors;
end;
{$ENDIF}

procedure TACLImage.LoadFromFile(const AFileName: string);
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
  LDib: TACLDib;
begin
  LDib := TACLDib.Create;
  try
    LDib.Assign(AGraphic);
    LoadFromBitmap(LDib);
  finally
    LDib.Free;
  end;
end;

procedure TACLImage.LoadFromResource(AInstance: HINST; const AResName: string; AResType: PChar);
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

procedure TACLImage.LoadFromStream(AStream: IACLDataContainer);
var
  LStream: TStream;
begin
  LStream := AStream.LockData;
  try
    LoadFromStream(LStream);
  finally
    AStream.UnlockData;
  end;
end;

procedure TACLImage.LoadFromStream(AStream: TStream);
var
  LFormat: TACLImageFormatClass;
begin
  LFormat := TACLImageFormatRepository.GetFormat(AStream);
  if LFormat = nil then
  begin
    // Backward-compatibility:
    //   Old plugins that put here formats that can be opened by GDI+ but has no handlers in our repository (like ICO, EMF)
    // raise EACLImageUnsupportedFormat.Create;
    LFormat := TACLImageFormatBMP;
  end;
  LFormat.Load(AStream, Self);
end;

procedure TACLImage.SaveToDib(const ATarget: TACLDib);
{$IFDEF FPC}
begin
  ATarget.Assign(Handle);
{$ELSE}
var
  LData: TBitmapData;
begin
  if BeginLock(LData) then
  try
    case LData.PixelFormat of
      PixelFormat32bppRGB,
      PixelFormat32bppARGB,
      PixelFormat32bppPARGB:
        begin
          ATarget.Assign(LData.Scan0, LData.Width, LData.Height);
          if LData.PixelFormat = PixelFormat32bppARGB then
            ATarget.Premultiply;
          if LData.PixelFormat = PixelFormat32bppRGB then
            ATarget.MakeOpaque;
          Exit;
        end;
    end;
  finally
    EndLock(LData)
  end;

  ATarget.Resize(Width, Height);
  Draw(ATarget.Canvas, ATarget.ClientRect);
  ATarget.MakeOpaque;
{$ENDIF}
end;

procedure TACLImage.SaveToFile(const AFileName: string);
var
  LFormat: TACLImageFormatClass;
begin
  LFormat := TACLImageFormatRepository.GetFormatByExt(acExtractFileExt(AFileName));
  if LFormat = nil then
    raise EACLImageUnsupportedFormat.Create;
  SaveToFile(AFileName, LFormat);
end;

procedure TACLImage.SaveToFile(const AFileName: string; AFormat: TACLImageFormatClass);
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
  AFormat.Save(AStream, Self);
end;

procedure TACLImage.Changed;
begin
  // do nothing
end;

procedure TACLImage.DestroyHandle;
begin
  if Handle <> nil then
  begin
  {$IFDEF FPC}
    FreeAndNil(FHandle);
  {$ELSE}
    // keep the order
    GdipDisposeImage(Handle);
    FHandle := nil;
    FBits := nil;
  {$ENDIF}
  end;
end;

procedure TACLImage.LoadFromHandle(AHandle: TACLImageHandle; AFormat: TACLImageFormatClass);
{$IFNDEF FPC}
var
  ID: TGUID;
{$ENDIF}
begin
  SetHandle(AHandle);

  if AFormat <> nil then
    FFormat := AFormat
  else
    FFormat := TACLImageFormatBMP;

{$IFNDEF FPC}
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
{$ENDIF}
end;

procedure TACLImage.LoadFromImage(AImage: TACLImage);
var
  LHandle: TACLImageHandle;
begin
  if Self = AImage then Exit;

  FComposingMode := AImage.FComposingMode;
  FStretchQuality := AImage.FStretchQuality;
  FPixelOffsetMode := AImage.FPixelOffsetMode;

{$IFDEF FPC}
  if (AImage <> nil) and not AImage.Empty then
  begin
    LHandle := TACLImageHandle.Create;
    LHandle.Assign(AImage.Handle);
    SetHandle(LHandle);
  end
{$ELSE}
  if GdipCloneImage(AImage.Handle, LHandle) = Ok then
  begin
    SetLength(FBits, Length(AImage.FBits));
    if Length(FBits) > 0 then
      FastMove(AImage.FBits[0], FBits[0], SizeOf(AImage.FBits));
    SetHandle(LHandle);
  end
{$ENDIF}
  else
    Clear;
end;

function TACLImage.GetClientRect: TRect;
begin
{$IFDEF FPC}
  if Handle <> nil then
    Exit(Handle.ClientRect);
{$ELSE}
  var W, H: Single;
  if GdipGetImageDimension(Handle, W, H) = Ok then
    Exit(Rect(0, 0, Trunc(W), Trunc(H)));
{$ENDIF}
  Result := NullRect;
end;

function TACLImage.GetIsEmpty: Boolean;
begin
  Result := Handle = nil;
end;

function TACLImage.GetHeight: Integer;
begin
{$IFDEF FPC}
  if Handle <> nil then
    Result := Handle.Height
  else
    Result := 0;
{$ELSE}
  if GdipGetImageHeight(Handle, Cardinal(Result)) <> Ok then
    Result := 0;
{$ENDIF}
end;

function TACLImage.GetWidth: Integer;
begin
{$IFDEF FPC}
  if Handle <> nil then
    Result := Handle.Width
  else
    Result := 0;
{$ELSE}
  if GdipGetImageWidth(Handle, Cardinal(Result)) <> Ok then
    Result := 0;
{$ENDIF}
end;

procedure TACLImage.SetHandle(AValue: TACLImageHandle);
begin
  if FHandle <> AValue then
  begin
    DestroyHandle;
    FHandle := AValue;
    Changed;
  end;
end;

{ TACLImageFormat }

class function TACLImageFormat.CheckIsAvailable: Boolean;
begin
{$IFDEF FPC}
  Result := TPicture.FindGraphicClassWithFileExt(Ext, False) <> nil;
{$ELSE}
  Result := True;
{$ENDIF}
end;

class function TACLImageFormat.ClipboardFormat: Word;
begin
  Result := 0;
end;

class procedure TACLImageFormat.Load(AStream: TStream; AImage: TACLImage);
{$IFDEF FPC}
var
  LGraphic: TGraphic;
begin
  LGraphic := TPicture.FindGraphicClassWithFileExt(Ext).Create;
  try
    LGraphic.LoadFromStream(AStream);
    AImage.LoadFromGraphic(LGraphic);
  finally
    LGraphic.Free;
  end;
{$ELSE}
var
  AAvailableSize: Int64;
  AGdiPlusStream: IStream;
  AHandle: GpImage;
  ANewPosition: UInt64;
begin
  AAvailableSize := AStream.Available;
  // TMemoryStream.CopyOf:
  // Для некоторых форматов GDI+ хранит референс на TStream и подгружает оттуда данные по мере необходимости.
  // Поэтому нам важно сохранить оригинальный стрим живым.
  AGdiPlusStream := TACLGdiplusStream.Create(TMemoryStream.CopyOf(AStream, AAvailableSize), soOwned);
  if GdipLoadImageFromStreamICM(AGdiPlusStream, AHandle) <> Ok then
  begin
    AGdiPlusStream.Seek(0, STREAM_SEEK_SET, ANewPosition);
    GdipCheck(GdipCreateBitmapFromStream(AGdiPlusStream, AHandle));
  end;
  AImage.LoadFromHandle(AHandle, Self);
{$ENDIF}
end;

class procedure TACLImageFormat.Save(AStream: TStream; AImage: TACLImage);
{$IFDEF FPC}
var
  LBitmap: TBitmap;
  LGraphic: TGraphic;
begin
  LGraphic := TPicture.FindGraphicClassWithFileExt(Ext).Create;
  try
    LBitmap := TBitmap.Create;
    try
      AImage.Handle.AssignTo(LBitmap);
      LGraphic.Assign(LBitmap);
    finally
      LBitmap.Free;
    end;
    LGraphic.SaveToStream(AStream);
  finally
    LGraphic.Free;
  end;
{$ELSE}
var
  ACodecID: TGUID;
  AStreamIntf: IStream;
begin
  if GpGetCodecByMimeType(MimeType, ACodecID) then
  begin
    AStreamIntf := TStreamAdapter.Create(AStream, soReference);
    GdipCheck(GdipSaveImageToStream(AImage.Handle, AStreamIntf, @ACodecID, nil));
    AStreamIntf := nil;
  end
  else
    raise EACLImageFormatError.CreateFmt('GDI+ has no codec for the "%s" mime-type', [MimeType]);
{$ENDIF}
end;

{ TACLImageFormatRepository }

class constructor TACLImageFormatRepository.Create;
begin
  // keep the order
  Register(TACLImageFormatPNG); // must be before BMP (BMP codec is GDI+ based and will load PNG too)
  Register(TACLImageFormatBMP);
  Register(TACLImageFormatGIF);

  Register(TACLImageFormatJPEG);  // canonical
  Register(TACLImageFormatJPEG2); // alternate extension
  Register(TACLImageFormatJPG);   // alternate mimetype

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
    SetLength(ABytes{%H-}, FMaxPreamble);
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
  const AContainer: IACLDataContainer; out AFilter, AExt: string): Boolean;
begin
  Result := GetDialogFilter(GetMimeType(AContainer), AFilter, AExt);
end;

class function TACLImageFormatRepository.GetDialogFilter(
  const AMimeType: string; out AFilter, AExt: string): Boolean;
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
  ABuilder: TACLStringBuilder;
  I: Integer;
begin
  if FFormats <> nil then
  begin
    ABuilder := TACLStringBuilder.Get;
    try
      for I := 0 to FFormats.Count - 1 do
      begin
        ABuilder.Append('*');
        ABuilder.Append(TACLImageFormatClass(FFormats.List[I]).Ext);
        ABuilder.Append(';');
      end;
      Result := ABuilder.ToString;
    finally
      ABuilder.Release;
    end;
  end
  else
    Result := EmptyStr;
end;

class function TACLImageFormatRepository.GetMimeType(const AFormat: TACLImageFormatClass): string;
begin
  if AFormat <> nil then
    Result := AFormat.MimeType
  else
    Result := EmptyStr;
end;

class function TACLImageFormatRepository.GetMimeType(const AContainer: IACLDataContainer): string;
begin
  Result := GetMimeType(GetFormat(AContainer));
end;

class function TACLImageFormatRepository.GetMimeType(const AExt: string): string;
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

class function TACLImageFormatRepository.GetMimeType(const AStream: TStream): string;
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
    AStream.ReadBuffer(AFileHeader{%H-}, SizeOf(AFileHeader));
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
  Result := '.jpg';
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
            AStream.ReadBuffer(AData{%H-}, SizeOf(AData));
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

{ TACLImageFormatJPEG2 }

class function TACLImageFormatJPEG2.Ext: string;
begin
  Result := '.jpeg';
end;

{ TACLImageFormatJPG }

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
    FClipboardFormat := RegisterClipboardFormat({$IFDEF FPC}MimeType{$ELSE}'PNG'{$ENDIF});
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
  acFreeLibrary(FLibHandle);
  FEncodeFunc := nil;
  FDecodeFunc := nil;
  FFreeFunc := nil;
end;

class function TACLImageFormatWebP.CheckIsAvailable: Boolean;
begin
  Result := True;
  FLibHandle := acLoadLibrary('libwebp' + LibExt);
  @FGetInfoFunc := acGetProcAddress(FLibHandle, 'WebPGetInfo', Result);
  @FDecodeFunc := acGetProcAddress(FLibHandle, 'WebPDecodeBGRA', Result);
  @FEncodeFunc := acGetProcAddress(FLibHandle, 'WebPEncodeBGRA', Result);
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
begin
  if AStream is TCustomMemoryStream then
  begin
    Result := FGetInfoFunc(
      PByte(TCustomMemoryStream(AStream).Memory) + AStream.Position,
      AStream.Available, @ASize.cx, @ASize.cy) <> 0;
  end
  else
  begin
    AStream := TMemoryStream.CopyOf(AStream, AStream.Available);
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

class procedure TACLImageFormatWebP.Load(AStream: TStream; AImage: TACLImage);
var
  LPixels: PACLPixel32;
  LHeight: Integer;
  LWidth: Integer;
begin
  if AStream is TCustomMemoryStream then
  begin
    LPixels := PACLPixel32(FDecodeFunc(
      PByte(TCustomMemoryStream(AStream).Memory) + AStream.Position,
      AStream.Available, @LWidth, @LHeight));
    if LPixels <> nil then
    try
      AImage.LoadFromBits(LPixels, LWidth, LHeight, afDefined);
    finally
      FFreeFunc(LPixels);
    end;
  end
  else
  begin
    AStream := TMemoryStream.CopyOf(AStream, AStream.Available);
    try
      Load(AStream, AImage);
    finally
      AStream.Free;
    end;
  end;
end;

class procedure TACLImageFormatWebP.Save(AStream: TStream; AImage: TACLImage);
{$IFDEF MSWINDOWS}
var
  LData: TBitmapData;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  GdipCheck(GdipBitmapLockBits(AImage.Handle, nil, ImageLockModeRead, PixelFormat32bppARGB, @LData));
  try
    Encode(AStream, LData.Scan0, LData.Width, LData.Height);
  finally
    GdipCheck(GdipBitmapUnlockBits(AImage.Handle, @LData));
  end;
{$ELSE}
  Encode(AStream, PByte(AImage.Handle.Colors), AImage.Width, AImage.Height);
{$ENDIF}
end;

class procedure TACLImageFormatWebP.Encode(
  AStream: TStream; AData: PByte; AWidth, AHeight: Integer);
var
  LEncodedData: PByte;
  LEncodedSize: Cardinal;
begin
  LEncodedSize := FEncodeFunc(AData, AWidth, AHeight, AWidth * 4, 100, LEncodedData);
  try
    if LEncodedSize = 0 then
      raise EACLImageFormatError.Create('WebP failed to encode the image');
    AStream.WriteBuffer(LEncodedData^, LEncodedSize);
  finally
    if LEncodedData <> nil then
      FFreeFunc(LEncodedData);
  end;
end;

{ TABLImageEditor }

class procedure TACLImageTools.CropAndResize(
  const AImage: IACLDataContainer; AScale: Single; const ACropMargins: TRect);
begin
  if (AImage <> nil) and (not SameValue(AScale, 1) or (ACropMargins <> NullRect)) then
    CropAndResizeCore(AImage, -1, -1, AScale, ACropMargins);
end;

class procedure TACLImageTools.CropAndResizeCore(const AImage: IACLDataContainer;
  AWidth, AHeight: Integer; AScale: Single; ACropMargins: TRect);
var
  LImage: TACLImage;
  LImageData: TMemoryStream;
begin
  LImageData := AImage.LockData;
  try
    LImage := TACLImage.Create(LImageData);
    try
      if ACropMargins <> NullRect then
        LImage.Crop(ACropMargins);
      if (AWidth > 0) and (AHeight > 0) then
        LImage.Resize(AWidth, AHeight)
      else if AScale > 0 then
        LImage.Scale(AScale);

      LImageData.Position := 0;
      LImage.SaveToStream(LImageData);
      LImageData.Size := LImageData.Position;
    finally
      LImage.Free;
    end;
  finally
    AImage.UnlockData;
  end;
end;

class function TACLImageTools.CanPasteFromClipboard: Boolean;
begin
  Result :=
    Clipboard.HasFormat(TACLImageFormatBMP.ClipboardFormat) or
    Clipboard.HasFormat(TACLImageFormatPNG.ClipboardFormat);
end;

class procedure TACLImageTools.CopyToClipboard(AImage: TACLImage);

  procedure Copy(AImage: TACLImage; AFormat: TACLImageFormatClass);
  var
    LStream: TMemoryStream;
  begin
    LStream := TMemoryStream.Create;
    try
      AImage.SaveToStream(LStream, AFormat);
      LStream.Position := 0;
      Clipboard.AsStream[AFormat.ClipboardFormat] := LStream;
    finally
      LStream.Free;
    end;
  end;

  procedure CopyAsBMP(AImage: TACLImage);
  {$IFDEF MSWINDOWS}
  var
    ABitmap: TBitmap;
    AData: THandle;
    AFormat: Word;
    APalette: HPALETTE;
  {$ENDIF}
  begin
  {$IFDEF MSWINDOWS}
    ABitmap := AImage.ToBitmap(afPremultiplied);
    try
      ABitmap.SaveToClipboardFormat(AFormat, AData, APalette);
      Clipboard.SetAsHandle(AFormat, AData);
    finally
      ABitmap.Free;
    end;
  {$ELSE}
    Copy(AImage, TACLImageFormatBMP);
  {$ENDIF}
  end;

  procedure CopyAsPNG(AImage: TACLImage);
  begin
    Copy(AImage, TACLImageFormatPNG);
  end;

begin
  Clipboard.Open;
  try
    Clipboard.Clear;
    CopyAsBMP(AImage);
    CopyAsPNG(AImage);
  finally
    Clipboard.Close;
  end;
end;

class procedure TACLImageTools.Resize(const AImage: IACLDataContainer; AWidth, AHeight: Integer);
begin
  if (AImage <> nil) and (AWidth > 0) and (AHeight > 0) then
    CropAndResizeCore(AImage, AWidth, AHeight, -1, NullRect);
end;

class function TACLImageTools.PasteFromClipboard: IACLDataContainer;
{$IFDEF MSWINDOWS}

  function CreateFromFormat(AFormat: Word): IACLDataContainer;
  var
    LHandle: TObjHandle;
  begin
    LHandle := Clipboard.GetAsHandle(TACLImageFormatPNG.ClipboardFormat);
    if LHandle <> 0 then
    begin
      Result := TACLDataContainer.Create;
      Result.SetDataSize(GlobalSize(LHandle));
      FastMove(GlobalLock(LHandle)^, Result.GetDataPtr^, Result.GetDataSize);
      GlobalUnlock(LHandle);
    end
    else
      Result := nil;
  end;

  function CreateFromBitmap: IACLDataContainer;
  var
    LBitmap: TACLBitmap;
    LData: TMemoryStream;
  begin
    LBitmap := TACLBitmap.Create;
    try
      LBitmap.Assign(Clipboard);
      Result := TACLDataContainer.Create;
      with TACLImage.Create(LBitmap) do
      try
        LData := Result.LockData;
        try
          SaveToStream(LData, TACLImageFormatPNG);
        finally
          Result.UnlockData;
        end;
      finally
        Free;
      end;
    finally
      LBitmap.Free;
    end;
  end;

{$ELSE}

  function CreateFromFormat(AFormat: Word): IACLDataContainer;
  begin
    Result := TACLDataContainer.Create;
    if not Clipboard.GetFormat(AFormat, Result.GetDataUnsafe) then
      Result := nil;
  end;

  function CreateFromBitmap: IACLDataContainer;
  begin
    Result := CreateFromFormat(TACLImageFormatBMP.ClipboardFormat);
  end;

{$ENDIF}

begin
  if Clipboard.HasFormat(TACLImageFormatPNG.ClipboardFormat) then
    Result := CreateFromFormat(TACLImageFormatPNG.ClipboardFormat)
  else if Clipboard.HasFormat(TACLImageFormatBMP.ClipboardFormat) then
    Result := CreateFromBitmap
  else
    Result := nil;
end;

end.
