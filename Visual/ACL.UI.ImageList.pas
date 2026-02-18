////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Advanced Image List
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.ImageList;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.CommCtrl,
  Winapi.Messages,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  {System.}TypInfo,
  // Vcl
  {Vcl.}ActnList,
  {Vcl.}Controls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  // ACL
  ACL.Classes.Collections,
  ACL.Math,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.Images,
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Utils.Common,
  ACL.Utils.Logger,
  ACL.Utils.Strings;

type

  { TACLImageList }

  TACLImageList = class(TImageList,
    IACLColorSchema)
  strict private const
    HeaderLCL = $4C61494C; // LaIL (Lazarus image list)
    HeaderZIP = $5A43494C; // ZCIL (Zlib compressed image list)
  strict private
    FAllowColoration: Boolean;
    FColorSchema: TACLColorSchema;
    FSourceDPI: Integer;

    function ConvertTo32Bit(ASource: TBitmap): TACLBitmap;
    function GetScalable: Boolean;
    procedure SetAllowColoration(AValue: Boolean);
    procedure SetScalable(AValue: Boolean);
    procedure SetSourceDPI(AValue: Integer);
    procedure ReadDataWinIL(AStream: TStream);
  {$IFNDEF FPC}
    function AddSliced(Source: TBitmap; XCount, YCount: Integer): Integer;
    procedure WriteDataCompressed(AStream: TStream);
  protected
    procedure DoDraw(Index: Integer; Canvas: TCanvas;
      X, Y: Integer; Style: Cardinal; Enabled: Boolean = True); override;
  {$ENDIF}
  protected
    procedure Initialize; override;
  public
    function AddBitmap(ABitmap: TBitmap): Integer;
    function AddImage(const AImageFileName: string): Integer; overload;
    function AddImage(const AImage: TACLBaseDib): Integer; overload;
    function AddImage(const AImage: TACLImage): Integer; overload;
    function AddImage(const AImage: TACLSkinImage): Integer; overload;
    function AddIconFromResource(AInstance: HINST; const AName: string): Integer;
  {$IFDEF FPC}
    procedure GetIcon(AIndex: Integer; AIcon: TIcon); reintroduce;
  {$ENDIF}
    function GetImage(AIndex: Integer; AEnabled: Boolean = True): TACLDib;
    procedure ReplaceBitmap(AIndex: Integer; ABitmap: TBitmap);
    //# Clear and Add the Image
    procedure LoadImage(ABitmap: TBitmap); overload;
    procedure LoadImage(AInstance: HINST; const AName: string); overload;
    procedure LoadImage(AInstance: HINST; const AName: string; AType: PChar); overload;
    procedure LoadImage(AStream: TStream); overload;
    //# I/O (native format)
    procedure ReadData(Stream: TStream); override;
    procedure WriteData(Stream: TStream); override;
    // IACLColorSchema
    procedure ApplyColorSchema(const ASchema: TACLColorSchema);
    // Resize
    procedure SetSize(AValue: Integer); overload;
  {$IFDEF FPC}
    procedure SetSize(AWidth, AHeight: Integer); overload;
  {$ENDIF}
  published
    property AllowColoration: Boolean read FAllowColoration write SetAllowColoration default False;
  {$IFNDEF FPC}
    property ColorDepth default cd32Bit;
  {$ENDIF}
    property Scalable: Boolean read GetScalable write SetScalable stored False;
    property SourceDPI: Integer read FSourceDPI write SetSourceDPI default 96;
  end;

  { TACLImageListReplacer }

  /// <summary>
  ///   Automatically replaces the references to ImageLists according to DPI and Dark mode.
  ///   Imagelist must be named according following template:
  ///     [name][dark][scale-factor]
  ///   For example:
  ///     imSmall100,
  ///     imSmall200,
  ///     imSmallDark100,
  ///     imSmallDark200
  /// </summary>
  TACLImageListReplacer = class
  strict private const
    DarkModeSuffix = 'Dark';
  strict private
    FReplacementCache: TACLObjectDictionary;
    FDarkMode: Boolean;
    FTargetDPI: Integer;

    class function GenerateName(const ABaseName, ASuffix: string;
      ATargetDPI: Integer): TComponentName; static;
    class function GetBaseName(const AName: TComponentName): TComponentName; static;
  protected
    procedure UpdateImageList(AInstance: TObject; APropInfo: PPropInfo; APropValue: TObject);
    procedure UpdateImageListProperties(APersistent: TPersistent);
    procedure UpdateImageLists(AForm: TCustomForm);
  public
    constructor Create(ATargetDPI: Integer; ADarkMode: Boolean);
    destructor Destroy; override;
    class procedure Execute(ATargetDPI: Integer; AForm: TCustomForm);
    class function GetReplacement(AImageList: TCustomImageList;
      AForm: TCustomForm): TCustomImageList; overload;
    class function GetReplacement(AImageList: TCustomImageList;
      ATargetDPI: Integer; ADarkMode: Boolean): TCustomImageList; overload;
  end;

procedure acDrawImage(ACanvas: TCanvas; const R: TRect;
  AImages: TCustomImageList; AImageIndex: Integer;
  AEnabled: Boolean = True; ASmoothStrech: Boolean = True);
function acGetImage(AImages: TCustomImageList; AImageIndex: Integer): TACLDib;
function acGetImageListSize(AImages: TCustomImageList; ATargetDPI: Integer): TSize;
function acIs32BitBitmap(ABitmap: TBitmap): Boolean;
procedure acSetImageList(AValue: TCustomImageList; var AFieldValue: TCustomImageList;
  AChangeLink: TChangeLink; ANotifyComponent: TComponent);
implementation

uses
{$IFDEF FPC}
  FPImage,
  FPReadBMP,
  IntfGraphics,
  GraphType,
  RTLConsts,
  Zstream,
{$ELSE}
  System.ZLib,
{$ENDIF}
  // ACL
  ACL.UI.Application,
  ACL.Utils.DPIAware,
  ACL.Utils.RTTI,
  ACL.Utils.Stream;

function acGetImage(AImages: TCustomImageList; AImageIndex: Integer): TACLDib;
{$IFDEF FPC}
var
  LRawImage: TRawImage;
begin
  AImages.GetRawImage(AImageIndex, LRawImage);
  // Бага в LCL:
  //   TCustomImageList.ScaleImage засасывает пиксели в массив TRGBAQuad,
  // у которого раскладка в памяти BGRA. А когда мы запрашивает RawImage, метод
  // TCustomImageListResolution.FillDescription всегда возвращает фиксированный
  // Description для ARGB.
  // В принципе, можно и через TBitmap, но через TRawImage быстрее
  LRawImage.Description.BlueShift  := 0;
  LRawImage.Description.GreenShift := 8;
  LRawImage.Description.RedShift   := 16;
  LRawImage.Description.AlphaShift := 24;
  Result := TACLDib.Create;
  Result.Assign(LRawImage);
{$ELSE}
begin
  Result := TACLDib.Create(AImages.Width, AImages.Height);
  if AImages.HandleAllocated then
  begin
    if AImages.ColorDepth in [cd32Bit, cdDeviceDependent] then
    begin
      Result.Reset;
      ImageList_DrawEx(AImages.Handle, AImageIndex,
        Result.Handle, 0, 0, 0, 0, CLR_NONE, CLR_NONE, ILD_NORMAL);
    end
    else
    begin
      acFillRect(Result.Canvas, Result.ClientRect, clFuchsia);
      ImageList_DrawEx(AImages.Handle, AImageIndex, Result.Handle, 0, 0, 0, 0,
        GetColorFromRGB(AImages.BkColor),
        GetColorFromRGB(AImages.BlendColor), ILD_NORMAL);
      Result.MakeTransparent(clFuchsia);
    end;
  end;
{$ENDIF}
end;

procedure acDrawImage(ACanvas: TCanvas; const R: TRect;
  AImages: TCustomImageList; AImageIndex: Integer;
  AEnabled: Boolean; ASmoothStrech: Boolean);
var
  LImage: TACLDib;
begin
  if (AImages <> nil) and InRange(AImageIndex, 0, AImages.Count - 1) and acRectVisible(ACanvas, R) then
  begin
    if AImages is TACLImageList then
      LImage := TACLImageList(AImages).GetImage(AImageIndex, AEnabled)
    else
    begin
      LImage := acGetImage(AImages, AImageIndex);
      if not AEnabled then
        LImage.MakeDisabled;
    end;
    try
      LImage.DrawBlend(ACanvas, R, MaxByte, ASmoothStrech);
    finally
      LImage.Free;
    end;
  end;
end;

function acGetImageListSize(AImages: TCustomImageList; ATargetDPI: Integer): TSize;
begin
  if AImages <> nil then
  begin
    Result := TSize.Create(AImages.Width, AImages.Height);
    if (AImages is TACLImageList) and TACLImageList(AImages).Scalable then
      Result.Scale(ATargetDPI, TACLImageList(AImages).SourceDPI);
  end
  else
    Result := NullSize;
end;

function acIs32BitBitmap(ABitmap: TBitmap): Boolean;
begin
  if ABitmap.PixelFormat = pfDevice then
    Result := GetDeviceCaps(ScreenCanvas.Handle, BITSPIXEL) >= 32
  else
    Result := ABitmap.PixelFormat = pf32bit;
end;

procedure acSetImageList(AValue: TCustomImageList;
  var AFieldValue: TCustomImageList; AChangeLink: TChangeLink;
  ANotifyComponent: TComponent);
begin
  if AValue <> AFieldValue then
  begin
    if AFieldValue <> nil then
    begin
      AFieldValue.RemoveFreeNotification(ANotifyComponent);
      if AChangeLink <> nil then
        AFieldValue.UnRegisterChanges(AChangeLink);
    end;
    AFieldValue := AValue;
    if AValue <> nil then
    begin
      if AChangeLink <> nil then
        AValue.RegisterChanges(AChangeLink);
      AValue.FreeNotification(ANotifyComponent);
    end;
    if AChangeLink <> nil then
      AChangeLink.Change;
  end;
end;

{$IFDEF FPC}
type

  { TWin32ImageList }

  TWin32ImageList = class(TACLBitmap)
  strict private
    FImageCount: Integer;
    FImageSize: TSize;
    procedure ApplyMask(AImage: TLazIntfImage);
    function ReadBmp(ATarget: TFPCustomImage;
      ASource: TStream; AReader: TFPCustomImageReaderClass): TFPCustomImage;
  public
    procedure LoadFromStream(AStream: TStream); reintroduce;
    property ImageCount: Integer read FImageCount;
    property ImageSize: TSize read FImageSize;
  end;

  procedure TWin32ImageList.ApplyMask(AImage: TLazIntfImage);
  const
    MaxAlpha = High(TFPColor.Alpha);

    function IsMasked(X, Y: Integer): Boolean;
    var
      I, J: Integer;
    begin
      for I := X to X + ImageSize.cx - 1 do
      begin
        for J := Y to Y + ImageSize.cy - 1 do
          if InRange(AImage.Colors[I, J].Alpha, 1, MaxAlpha - 1) then
            Exit(False); // Если есть альфа (не 0, и не MaxAlpha) - значит маску игнорируем
      end;
      for I := X to X + ImageSize.cx - 1 do
      begin
        for J := Y to Y + ImageSize.cy - 1 do
          if AImage.Masked[I, J] then
            Exit(True);
      end;
      Result := False;
    end;

    procedure ApplyMaskToFrame(X, Y: Integer);
    var
      LColor: TFPColor;
      I, J: Integer;
    begin
      for I := X to X + ImageSize.cx - 1 do
        for J := Y to Y + ImageSize.cy - 1 do
        begin
          LColor := AImage.Colors[I, J];
          LColor.Alpha := IfThen(AImage.Masked[I, J], 0, MaxAlpha); // маска в IL инвертирована
          AImage.Colors[I, J] := LColor;
        end;
    end;

  var
    X, Y: Integer;
  begin
    X := 0; Y := 0;
    while Y < AImage.Height do
    begin
      while X < AImage.Width do
      begin
        if IsMasked(X, Y) then
          ApplyMaskToFrame(X, Y);
        Inc(X, ImageSize.cx);
      end;
      Inc(Y, ImageSize.cy);
      X := 0;
    end;
  end;

  procedure TWin32ImageList.LoadFromStream(AStream: TStream);
  var
    LFlags: Word;
    LImage: TLazIntfImage;
    LVersion: Word;
  begin
    // Refer to TILFileHeader described in NT\shell\comctl32\v6\image.h
    if AStream.ReadWord <> $4C49 then // Magic
      raise EReadError.CreateRes(@SImageReadFail);
    LVersion := AStream.ReadWord;
    FImageCount := AStream.ReadWord;
    AStream.ReadWord; // cAlloc;
    AStream.ReadWord; // cGrow;
    FImageSize.cx := AStream.ReadWord;
    FImageSize.cy := AStream.ReadWord;
    AStream.ReadInt32; // BkColorRef
    LFlags := AStream.ReadWord;
    if LVersion > $101 then
      AStream.Skip(15 * SizeOf(Word))
    else
      AStream.Skip(04 * SizeOf(Word));

    LImage := TLazIntfImage.Create(0, 0, [riqfRGB, riqfAlpha, riqfMask]);
    try
      // 1. Images
      //    TLazReaderBMP, т.к. TFPReaderBMP инвертирует альфу при чтении 32-битных картинок:
      //       RGBAToFPColor
      //       138027e, 2 мар 2004 02:46, "Corrected alpha in colormap"
      //       packages/fcl-image/src/fpreadbmp.pp
      ReadBmp(LImage, AStream, TLazReaderBMP);

      // 2. Mask
      if LFlags and {ILC_MASK}1 <> 0 then
      begin
        ReadBmp(TLazIntfImageMask.CreateWithImage(LImage), AStream, TFPReaderBMP).Free;
        if LImage.HasMask then
          ApplyMask(LImage);
      end;

      // 3. Convert to 32-bit ARGB bitmap
      with TACLDib.Create do
      try
        Assign(LImage);
        AssignTo(Self);
      finally
        Free;
      end;
    finally
      LImage.Free;
    end;
  end;

  function TWin32ImageList.ReadBmp(ATarget: TFPCustomImage;
    ASource: TStream; AReader: TFPCustomImageReaderClass): TFPCustomImage;
  var
    LReader: TFPCustomImageReader;
  begin
    LReader := AReader.Create;
    try
      Result := ATarget;
      Result.LoadFromStream(ASource, LReader);
    finally
      LReader.Free;
    end;
  end;
{$ENDIF}

{ TACLImageList }

function TACLImageList.AddBitmap(ABitmap: TBitmap): Integer;
var
  LTemp: TACLBitmap;
begin
  if acIs32BitBitmap(ABitmap) then
    Result := AddSliced(ABitmap, ABitmap.Width div Width, ABitmap.Height div Height)
  else
  begin
    LTemp := ConvertTo32Bit(ABitmap);
    try
      Result := AddBitmap(LTemp);
    finally
      LTemp.Free;
    end;
  end;
end;

function TACLImageList.AddImage(const AImageFileName: string): Integer;
var
  LImage: TACLImage;
begin
  LImage := TACLImage.Create(AImageFileName);
  try
    Result := AddImage(LImage);
  finally
    LImage.Free;
  end;
end;

function TACLImageList.AddImage(const AImage: TACLImage): Integer;
var
  LTemp: TACLBitmap;
begin
  LTemp := AImage.ToBitmap;
  try
    Result := AddBitmap(LTemp);
  finally
    LTemp.Free;
  end;
end;

function TACLImageList.AddImage(const AImage: TACLSkinImage): Integer;
var
  LTmp: TBitmap;
begin
  LTmp := TBitmap.Create;
  try
    AImage.SaveToBitmap(LTmp);
    Result := AddBitmap(LTmp);
  finally
    LTmp.Free;
  end;
end;

{$IFNDEF FPC}
function TACLImageList.AddSliced(Source: TBitmap; XCount, YCount: Integer): Integer;
var
  LBitmap: TACLBitmap;
  LRect: TRect;
  X, Y: Integer;
begin
  Result := -1;
  if (XCount <= 0) or (YCount <= 0) then
    Exit(-1);
  if (YCount = 1) then // в этом случае Windows сама порежет битмап
    Exit(Add(Source, nil));

  LBitmap := TACLBitmap.CreateEx(Width, Height, pf32Bit);
  try
    LRect := Rect(0, 0, Source.Width div XCount, Source.Height div YCount);
    for Y := 0 to YCount - 1 do
    begin
      for X := 0 to XCount - 1 do
      begin
        LBitmap.Canvas.CopyRect(LBitmap.ClientRect, Source.Canvas, LRect);
        Result := Add(LBitmap, nil);
        LRect.Offset(LRect.Width, 0);
      end;
      LRect.Offset(-LRect.Left, LRect.Height);
    end;
  finally
    LBitmap.Free;
  end;
end;
{$ENDIF}

function TACLImageList.AddIconFromResource(AInstance: HINST; const AName: string): Integer;
var
  LIcon: TIcon;
begin
  LIcon := TIcon.Create;
  try
    Result := -1;
    try
      LIcon.LoadFromResourceName(AInstance, AName);
      if LIcon.HandleAllocated then
        Result := AddIcon(LIcon);
    except
      // ignored
    end;
  finally
    LIcon.Free;
  end;
end;

function TACLImageList.AddImage(const AImage: TACLBaseDib): Integer;
var
  LTmp: TBitmap;
begin
  LTmp := TBitmap.Create;
  try
    AImage.AssignTo(LTmp);
    Result := AddBitmap(LTmp);
  finally
    LTmp.Free;
  end;
end;

{$IFDEF FPC}
procedure TACLImageList.GetIcon(AIndex: Integer; AIcon: TIcon);
var
  LBitmap: TBitmap;
begin
  LBitmap := TBitmap.Create;
  try
    GetBitmap(AIndex, LBitmap);
    AIcon.Assign(LBitmap);
  finally
    LBitmap.Free;
  end;
end;
{$ENDIF}

function TACLImageList.ConvertTo32Bit(ASource: TBitmap): TACLBitmap;
begin
  Result := TACLBitmap.Create;
  Result.Assign(ASource);
  Result.MakeTransparent(clFuchsia);
end;

{$IFNDEF FPC}
procedure TACLImageList.DoDraw(Index: Integer;
  Canvas: TCanvas; X, Y: Integer; Style: Cardinal; Enabled: Boolean);
var
  LDib: TACLDib;
begin
  if (Width > 0) and (Height > 0) then
  begin
    LDib := GetImage(Index, Enabled);
    try
      LDib.DrawBlend(Canvas, Point(X, Y));
    finally
      LDib.Free;
    end;
  end;
end;
{$ENDIF}

function TACLImageList.GetImage(AIndex: Integer; AEnabled: Boolean): TACLDib;
begin
  Result := acGetImage(Self, AIndex);
  if not AEnabled then
    Result.MakeDisabled
  else
    if AllowColoration and FColorSchema.IsAssigned then
    begin
      Result.Unpremultiply;
      Result.ApplyColorSchema(FColorSchema);
      Result.Premultiply;
    end;
end;

function TACLImageList.GetScalable: Boolean;
begin
  Result := FSourceDPI > 0;
end;

procedure TACLImageList.Initialize;
begin
  FSourceDPI := acDefaultDPI;
  try
    inherited;
  {$IFNDEF FPC}
    // Set ColorDepth property forces to create Handle.
    // So, setup it only for new instance of ImageList.
    if (Owner = nil) or ([csDesigning, csReading] * Owner.ComponentState <> [csReading]) then
      ColorDepth := cd32Bit;
  {$ENDIF}
  except
    raise ENotEnoughGraphicResources.Create('ImageList.Init', Width, Height);
  end;
end;

procedure TACLImageList.LoadImage(ABitmap: TBitmap);
begin
  Clear;
  if not ABitmap.Empty then
    AddBitmap(ABitmap);
end;

procedure TACLImageList.LoadImage(AInstance: HINST; const AName: string);
var
  LTmp: TBitmap;
begin
  LTmp := TACLBitmap.Create;
  try
    LTmp.LoadFromResourceName(AInstance, AName);
    LoadImage(LTmp);
  finally
    LTmp.Free;
  end;
end;

procedure TACLImageList.LoadImage(AInstance: HINST; const AName: string; AType: PChar);
var
  LStream: TStream;
begin
  LStream := TResourceStream.Create(AInstance, AName, AType);
  try
    LoadImage(LStream);
  finally
    LStream.Free;
  end;
end;

procedure TACLImageList.LoadImage(AStream: TStream);
var
  LImg: TACLImage;
  LTmp: TBitmap;
begin
  LImg := TACLImage.Create(AStream);
  try
    LTmp := LImg.ToBitmap;
    try
      LoadImage(LTmp);
    finally
      LTmp.Free;
    end;
  finally
    LImg.Free;
  end;
end;

procedure TACLImageList.SetAllowColoration(AValue: Boolean);
begin
  if FAllowColoration <> AValue then
  begin
    FAllowColoration := AValue;
    Change;
  end;
end;

procedure TACLImageList.SetScalable(AValue: Boolean);
begin
  if Scalable <> AValue then
  begin
    FSourceDPI := IfThen(AValue, acDefaultDPI);
    Change;
  end;
end;

procedure TACLImageList.ReplaceBitmap(AIndex: Integer; ABitmap: TBitmap);
var
  LTmp: TACLBitmap;
begin
  if acIs32BitBitmap(ABitmap) then
    Replace(AIndex, ABitmap, nil)
  else
  begin
    LTmp := ConvertTo32Bit(ABitmap);
    try
      Replace(AIndex, LTmp, nil);
    finally
      LTmp.Free;
    end;
  end;
end;

procedure TACLImageList.SetSize(AValue: Integer);
begin
  SetSize(AValue, AValue);
end;

{$IFDEF FPC}
procedure TACLImageList.SetSize(AWidth, AHeight: Integer);
begin
  Width := AWidth;
  Height := AHeight;
end;
{$ENDIF}

procedure TACLImageList.SetSourceDPI(AValue: Integer);
begin
  if AValue <> 0 then
    AValue := EnsureRange(AValue, acMinDpi, acMaxDpi);
  if AValue <> FSourceDPI then
  begin
    FSourceDPI := AValue;
    Change;
  end;
end;

procedure TACLImageList.ReadData(Stream: TStream);
var
  LData: TMemoryStream;
  LDataOffset: Int64;
  LDataSize: Int64;
  LDataSub: TACLSubStream;
  LHeader: Integer;
begin
  LHeader := Stream.ReadInt32;
  if LHeader = HeaderLCL then
  begin
  {$IFDEF FPC}
    inherited ReadData(Stream);
  {$ELSE}
    raise EInvalidGraphic.Create('LCL-ImageLists are not supported.')
  {$ENDIF}
  end
  else

  if LHeader = HeaderZIP then
  begin
    LData := TMemoryStream.Create;
    try
      LData.Size := Stream.ReadInt32;
      LDataSize := Stream.ReadInt32;
      LDataOffset := Stream.Position;
      LDataSub := TACLSubStream.Create(Stream, LDataOffset, LDataSize);
      try
        with TDecompressionStream.Create(LDataSub) do
        try
          ReadBuffer(LData.Memory^, LData.Size);
        finally
          Free;
        end;
      finally
        LDataSub.Free;
      end;
      ReadDataWinIL(LData);
    finally
      LData.Free;
    end;
  end
  else
  begin
    Stream.Seek(-SizeOf(Integer), soCurrent);
    ReadDataWinIL(Stream);
  end;
end;

procedure TACLImageList.ReadDataWinIL(AStream: TStream);
{$IFDEF FPC}
var
  LImages: TWin32ImageList;
begin
  // AI: В принципе, лазарь умеет работать с дельфевыми IL, однако из-за того,
  // что GetDescriptionFromDevice возвращает Depth = 24 в gtk2 в linux-е,
  // он херит альфа канал, а у нас IL строго 32-битный с альфой
  LImages := TWin32ImageList.Create;
  try
    LImages.LoadFromStream(AStream);
    BeginUpdate;
    try
      Clear;
      SetSize(LImages.ImageSize.cx, LImages.ImageSize.cy);
      AddSliced(LImages,
        LImages.Width div LImages.ImageSize.cx,
        LImages.Height div LImages.ImageSize.cy);
      while Count > LImages.ImageCount do
        Delete(Count - 1);
    finally
      EndUpdate;
    end;
  finally
    LImages.Free;
  end;
{$ELSE}
begin
  try
    inherited ReadData(AStream);
  except
    raise ENotEnoughGraphicResources.Create('ImageList.' + Name, Width, Height);
  end;
{$ENDIF}
end;

procedure TACLImageList.WriteData(Stream: TStream);
begin
{$IFDEF FPC}
  Stream.WriteInt32(HeaderLCL);
{$ELSE}
  // TImageList.Assign uses ReadData/WriteData.
  // So, we MUST generate a compatible stream to make the IDE Designer works correctly
  if csWriting in ComponentState then
    WriteDataCompressed(Stream)
  else
{$ENDIF}
    inherited;
end;

procedure TACLImageList.ApplyColorSchema(const ASchema: TACLColorSchema);
begin
  if FColorSchema <> ASchema then
  begin
    FColorSchema := ASchema;
    Change;
  end;
end;

{$IFNDEF FPC}
procedure TACLImageList.WriteDataCompressed(AStream: TStream);
var
  LData: TMemoryStream;
  LPosition1: Int64;
  LPosition2: Int64;
begin
  LData := TMemoryStream.Create;
  try
    inherited WriteData(LData);
    AStream.WriteInt32(HeaderZIP);
    AStream.WriteInt32(LData.Size); // uncompressed size
    AStream.WriteInt32(0); // compressed size
    LPosition1 := AStream.Position;

    with TCompressionStream.Create(TCompressionLevel.clMax, AStream) do
    try
      WriteBuffer(LData.Memory^, LData.Size);
    finally
      Free;
    end;

    LPosition2 := AStream.Position;
    AStream.Position := LPosition1 - SizeOf(Integer);
    AStream.WriteInt32(LPosition2 - LPosition1); // match the "compressed size"
    AStream.Position := LPosition2;
  finally
    LData.Free;
  end;
end;
{$ENDIF}

{ TACLImageListReplacer }

constructor TACLImageListReplacer.Create(ATargetDPI: Integer; ADarkMode: Boolean);
begin
  FDarkMode := ADarkMode;
  FTargetDPI := ATargetDPI;
  FReplacementCache := TACLObjectDictionary.Create;
end;

destructor TACLImageListReplacer.Destroy;
begin
  FreeAndNil(FReplacementCache);
  inherited Destroy;
end;

class procedure TACLImageListReplacer.Execute(ATargetDPI: Integer; AForm: TCustomForm);
begin
  with TACLImageListReplacer.Create(ATargetDPI, TACLApplication.IsDarkMode) do
  try
    UpdateImageLists(AForm);
  finally
    Free;
  end;
end;

class function TACLImageListReplacer.GetReplacement(
  AImageList: TCustomImageList; AForm: TCustomForm): TCustomImageList;
begin
  Result := GetReplacement(AImageList, acGetCurrentDpi(AForm), TACLApplication.IsDarkMode);
end;

class function TACLImageListReplacer.GetReplacement(
  AImageList: TCustomImageList; ATargetDPI: Integer; ADarkMode: Boolean): TCustomImageList;

  function CheckReference(const AReference: string; var AResult: TCustomImageList): Boolean;
  var
    LReference: TComponent;
  begin
    LReference := AImageList.Owner.FindComponent(AReference);
    Result := LReference is TCustomImageList;
    if Result then
      AResult := TCustomImageList(LReference);
  end;

  function TryFind(const ABaseName: TComponentName; ATargetDPI: Integer; var AResult: TCustomImageList): Boolean;
  begin
    Result := False;
    if ADarkMode then
      Result := CheckReference(GenerateName(ABaseName, DarkModeSuffix, ATargetDPI), AResult);
    if not Result then
      Result := CheckReference(GenerateName(ABaseName, EmptyStr, ATargetDPI), AResult);
    if not Result and (ATargetDPI = acDefaultDPI) then
      Result := CheckReference(ABaseName, AResult);
  end;

var
  ABaseName: TComponentName;
  I: Integer;
begin
  Result := AImageList;

  ABaseName := GetBaseName(AImageList.Name);
  if (ABaseName <> '') and (AImageList.Owner <> nil) and not TryFind(ABaseName, ATargetDPI, Result) then
  begin
    for I := High(acDefaultDPIValues) downto Low(acDefaultDPIValues) do
    begin
      if (acDefaultDPIValues[I] < ATargetDPI) and TryFind(ABaseName, acDefaultDPIValues[I], Result) then
        Break;
    end;
  end;
end;

procedure TACLImageListReplacer.UpdateImageList(AInstance: TObject; APropInfo: PPropInfo; APropValue: TObject);
var
  ANewValue: TObject;
begin
  if not FReplacementCache.TryGetValue(APropValue, ANewValue) then
  begin
    ANewValue := GetReplacement(TCustomImageList(APropValue), FTargetDPI, FDarkMode);
    FReplacementCache.Add(APropValue, ANewValue);
  end;
  if APropValue <> ANewValue then
    SetObjectProp(AInstance, APropInfo, ANewValue);
end;

procedure TACLImageListReplacer.UpdateImageListProperties(APersistent: TPersistent);

  function EnumProperties(AObject: TObject; out AList: PPropList; out ACount: Integer): Boolean;
  begin
    Result := False;
    if AObject <> nil then
    begin
      ACount := GetTypeData(AObject.ClassInfo)^.PropCount;
      Result := ACount > 0;
      if Result then
      begin
        AList := AllocMem(ACount * SizeOf(Pointer));
        GetPropInfos(AObject.ClassInfo, AList);
      end;
    end;
  end;

var
  APropClass: TClass;
  AProperties: PPropList;
  APropertyCount: Integer;
  APropInfo: PPropInfo;
  APropValue: TObject;
  I: Integer;
begin
  if EnumProperties(APersistent, AProperties, APropertyCount) then
  try
    for I := 0 to APropertyCount - 1 do
    begin
      APropInfo := AProperties^[I];
      if APropInfo.PropType^.Kind = tkClass then
      begin
        APropClass := GetObjectPropClass(APropInfo);
        if APropClass.InheritsFrom(TComponent) then
        begin
          if APropClass.InheritsFrom(TCustomImageList) then
          begin
            APropValue := GetObjectProp(APersistent, APropInfo);
            if APropValue <> nil then
              UpdateImageList(APersistent, APropInfo, APropValue);
          end;
        end
        else
          if APropClass.InheritsFrom(TPersistent) then
          begin
            APropValue := GetObjectProp(APersistent, APropInfo);
            if APropValue <> nil then
              UpdateImageListProperties(TPersistent(APropValue));
          end;
      end;
    end;
  finally
    FreeMem(AProperties);
  end;
end;

procedure TACLImageListReplacer.UpdateImageLists(AForm: TCustomForm);
var
  I: Integer;
begin
  for I := 0 to AForm.ComponentCount - 1 do
    UpdateImageListProperties(AForm.Components[I]);
end;

class function TACLImageListReplacer.GenerateName(
  const ABaseName, ASuffix: string; ATargetDPI: Integer): TComponentName;
begin
  Result := ABaseName + ASuffix + IntToStr(MulDiv(100, ATargetDPI, acDefaultDPI));
end;

class function TACLImageListReplacer.GetBaseName(const AName: TComponentName): TComponentName;
var
  ALength: Integer;
begin
  Result := AName;
  ALength := Length(Result);
  while (ALength > 0) and CharInSet(Result[ALength], ['0'..'9']) do
    Dec(ALength);
  SetLength(Result, ALength);
  if acEndsWith(Result, DarkModeSuffix) then
    SetLength(Result, ALength - Length(DarkModeSuffix));
end;

end.
