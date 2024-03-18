{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             ImageList Classes             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.ImageList;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
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
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.Images,
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.UI.Resources,
  ACL.Utils.Common;

type

  { TACLImageList }

  TACLImageList = class(TImageList)
  strict private const
    HeaderLCL = $4C61494C; // LaIL (Lazarus image list)
    HeaderZIP = $5A43494C; // ZCIL (Zlib compressed image list)
  strict private
    FSourceDPI: Integer;

    function ConvertTo32Bit(ASource: TBitmap): TACLBitmap;
    function GetScalable: Boolean;
    procedure SetScalable(AValue: Boolean);
    procedure SetSourceDPI(AValue: Integer);
    procedure ReadDataWinIL(AStream: TStream);
  {$IFNDEF FPC}
  protected
    procedure DoDraw(Index: Integer; Canvas: TCanvas;
      X, Y: Integer; Style: Cardinal; Enabled: Boolean = True); override;
  {$ENDIF}
  public
    procedure AfterConstruction; override;
    procedure AddBitmap(ABitmap: TBitmap);
    procedure AddImage(AImage: TACLSkinImage);
    function AddIconFromResource(AInstance: HINST; const AName: string): Integer;
    procedure ReplaceBitmap(AIndex: Integer; ABitmap: TBitmap);
    //# Clear and Add the Image
    procedure LoadImage(ABitmap: TBitmap); overload;
    procedure LoadImage(AInstance: HINST; const AName: string); overload;
    procedure LoadImage(AInstance: HINST; const AName: string; AType: PChar); overload;
    procedure LoadImage(AStream: TStream); overload;
    //# I/O (native format)
    procedure ReadData(Stream: TStream); override;
    procedure WriteData(Stream: TStream); override;
    // Resize
    procedure SetSize(AValue: Integer); overload;
  {$IFDEF FPC}
    procedure SetSize(AWidth, AHeight: Integer); overload;
  {$ENDIF}
  published
  {$IFNDEF FPC}
    property ColorDepth default cd32Bit;
  {$ENDIF}
    property Masked default False;
    property Scalable: Boolean read GetScalable write SetScalable stored False;
    property SourceDPI: Integer read FSourceDPI write SetSourceDPI default 96;
  end;

procedure acDrawImage(ACanvas: TCanvas; const R: TRect;
  AImages: TCustomImageList; AImageIndex: Integer;
  AEnabled: Boolean = True; ASmoothStrech: Boolean = True);
function acGetImage(AImages: TCustomImageList; AImageIndex: Integer): TACLBitmapLayer;
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
  ACL.Utils.DPIAware,
  ACL.Utils.RTTI,
  ACL.Utils.Stream;

function acGetImage(AImages: TCustomImageList; AImageIndex: Integer): TACLBitmapLayer;
{$IFDEF FPC}
var
  ARawImage: TRawImage;
begin
  AImages.GetRawImage(AImageIndex, ARawImage);
  // Бага в LCL:
  //   TCustomImageList.ScaleImage засасывает пиксели в массив TRGBAQuad,
  // у которого раскладка в памяти BGRA. А когда мы запрашивает RawImage, метод
  // TCustomImageListResolution.FillDescription всегда возвращает фиксированный
  // Description для ARGB.
  // В принципе, можно и через TBitmap, но через TRawImage быстрее
  ARawImage.Description.BlueShift  := 0;
  ARawImage.Description.GreenShift := 8;
  ARawImage.Description.RedShift   := 16;
  ARawImage.Description.AlphaShift := 24;
  Result := TACLBitmapLayer.Create;
  Result.Assign(ARawImage);
{$ELSE}
begin
  Result := TACLBitmapLayer.Create(AImages.Width, AImages.Height);
  Result.Reset;
  AImages.Draw(Result.Canvas, 0, 0, AImageIndex);
{$ENDIF}
end;

procedure acDrawImage(ACanvas: TCanvas; const R: TRect;
  AImages: TCustomImageList; AImageIndex: Integer;
  AEnabled: Boolean; ASmoothStrech: Boolean);
var
  LImage: TACLBitmapLayer;
begin
  if (AImages <> nil) and (AImageIndex >= 0) and acRectVisible(ACanvas, R) then
  begin
  {$IFNDEF FPC}
    if (R.Width = AImages.Width) or (R.Height = AImages.Height) then
    begin
      AImages.Draw(ACanvas, R.Left, R.Top, AImageIndex, AEnabled);
      Exit;
    end;
  {$ENDIF}
    LImage := acGetImage(AImages, AImageIndex);
    try
      if not AEnabled then
        LImage.MakeDisabled;
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
    Result := GetDeviceCaps(ScreenCanvas.Handle, NUMCOLORS) >= 32
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

{ TACLImageList }

procedure TACLImageList.AfterConstruction;
begin
  inherited AfterConstruction;
  FSourceDPI := acDefaultDPI;
{$IFNDEF FPC}
  ColorDepth := cd32Bit;
{$ENDIF}
  Masked := False;
end;

procedure TACLImageList.AddBitmap(ABitmap: TBitmap);
var
  LTemp: TACLBitmap;
begin
  if acIs32BitBitmap(ABitmap) then
  begin
  {$IFDEF FPC}
    AddSliced(ABitmap, ABitmap.Width div Width, ABitmap.Height div Height);
  {$ELSE}
    Add(ABitmap, nil);
  {$ENDIF}
  end
  else
  begin
    LTemp := ConvertTo32Bit(ABitmap);
    try
      AddBitmap(LTemp);
    finally
      LTemp.Free;
    end;
  end;
end;

procedure TACLImageList.AddImage(AImage: TACLSkinImage);
var
  LTmp: TBitmap;
begin
  LTmp := TBitmap.Create;
  try
    AImage.SaveToBitmap(LTmp);
    AddBitmap(LTmp);
  finally
    LTmp.Free;
  end;
end;

function TACLImageList.AddIconFromResource(AInstance: HINST; const AName: string): Integer;
var
  LTmp: TIcon;
begin
  LTmp := TIcon.Create;
  try
    LTmp.Handle := LoadIcon(AInstance, PChar(AName));
    if LTmp.HandleAllocated then
      Result := AddIcon(LTmp)
    else
      Result := -1;
  finally
    LTmp.Free;
  end;
end;

{$IFNDEF FPC}
procedure TACLImageList.DoDraw(Index: Integer; Canvas: TCanvas;
  X, Y: Integer; Style: Cardinal; Enabled: Boolean = True);
var
  ALayer: TACLBitmapLayer;
begin
  if (Width > 0) and (Height > 0) then
  begin
    ALayer := TACLBitmapLayer.Create(Width, Height);
    try
      if ColorDepth = cd32Bit then
      begin
        ALayer.Reset;
        inherited DoDraw(Index, ALayer.Canvas, 0, 0, Style);
      end
      else
      begin
        acFillRect(ALayer.Canvas, ALayer.ClientRect, clFuchsia);
        inherited DoDraw(Index, ALayer.Canvas, 0, 0, Style);
        ALayer.MakeTransparent(clFuchsia);
      end;
      if not Enabled then
        ALayer.MakeDisabled;
      ALayer.DrawBlend(Canvas, Point(X, Y));
    finally
      ALayer.Free;
    end;
  end;
end;
{$ENDIF}

function TACLImageList.ConvertTo32Bit(ASource: TBitmap): TACLBitmap;
begin
  Result := TACLBitmap.Create;
  Result.Assign(ASource);
  Result.MakeTransparent(clFuchsia);
end;

function TACLImageList.GetScalable: Boolean;
begin
  Result := FSourceDPI > 0;
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
    raise EInvalidGraphic.Create('LCL-imagelists are not supported.')
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
const
  NUM_OVERLAY   = 15;
  NUM_OVERLAY_0 = 4;
type
  TILFileHeader = packed record // Ref. NT\shell\comctl32\v6\image.h
    magic, version: Word;
    cImage, cAlloc, cGrow: SHORT;
    cx, cy: SHORT;
    clrBk: TColorRef; flags: SHORT;
    overlayIndexes: array [0..NUM_OVERLAY - 1] of SHORT;
  end;

  function IsMasked(Img: TLazIntfImage; X, Y, W, H: Integer): Boolean;
  var
    I, J: Integer;
  begin
    for I := X to X + W - 1 do
      for J := Y to Y + H - 1 do
      begin
        if Img.Masked[I, J] then
          Exit(True);
      end;
    Result := False;
  end;

  function ReadImage(const AHeader: TILFileHeader): TBitmap;
  var
    AColor: TFPColor;
    AImage: TLazIntfImage;
    AReader: TFPCustomImageReader;
    I, J, X, Y: Integer;
  begin
    AImage := TLazIntfImage.Create(0, 0, [riqfRGB, riqfAlpha, riqfMask]);
    try
      // TFPReaderBMP инвертирует альфу при чтении 32-битных картинок:
      //     RGBAToFPColor
      //     138027e, 2 мар 2004 02:46, "Corrected alpha in colormap"
      //     packages/fcl-image/src/fpreadbmp.pp
      // Посему мы тут используем TLazReaderBMP:
      AReader := TLazReaderBMP.Create;
      try
        AImage.LoadFromStream(AStream, AReader);
      finally
        AReader.Free;
      end;

      if AHeader.Flags and {ILC_MASK}1 <> 0 then
      begin
        with TLazIntfImageMask.CreateWithImage(AImage) do
        try
          AReader := TFPReaderBMP.Create;
          try
            LoadFromStream(AStream, AReader);
          finally
            AReader.Free;
          end;
        finally
          Free;
        end;

        if AImage.HasMask then
        begin
          // AI, 25.12.2023
          // Вот тут интересная штука: виндовый ImageList накладывает маску "покадрово":
          // Если кадр маски имеет хоть один белый пиксель - надо выставлять альфу согласно
          // маске, в противном случае маски нет, и, скорее всего, у кадра уже правильный альфа-канал
          X := 0; Y := 0;
          while Y < AImage.Height do
          begin
            while X < AImage.Width do
            begin
              if IsMasked(AImage, X, Y, AHeader.cx, AHeader.cy) then
              begin
                for I := X to X + AHeader.cx - 1 do
                  for J := Y to Y + AHeader.cy - 1 do
                  begin
                    AColor := AImage.Colors[I, J];
                    if AImage.Masked[I, J] then // маска в IL инвертирована
                      AColor.Alpha := Low(AColor.Alpha)
                    else if AColor.Alpha = 0 then
                      AColor.Alpha := High(AColor.Alpha);
                    AImage.Colors[I, J] := AColor;
                  end;
              end;
              Inc(X, AHeader.cx);
            end;
            Inc(Y, AHeader.cy);
            X := 0;
          end;
        end;
      end;
      Result := TBitmap.Create;
      Result.LoadFromIntfImage(AImage);
    finally
      AImage.Free;
    end;
  end;

const
  ILFILEHEADER_SIZE0 = SizeOf(TILFileHeader) - SizeOf(Short) * (NUM_OVERLAY - NUM_OVERLAY_0);
var
  ABitmap: TBitmap;
  AHeader: TILFileHeader;
begin
  // AI: В принципе, лазарь умеет работать с дельфевыми IL, однако из-за того,
  // что GetDescriptionFromDevice возвращает Depth = 24 в gtk2 в linux-е,
  // он херит альфа канал, а у нас IL строго 32-битный с альфой
  AStream.ReadBuffer(AHeader{%H-}, ILFILEHEADER_SIZE0);
  if AHeader.magic <> $4C49 then
    raise EReadError.CreateRes(@SImageReadFail);
  if AHeader.Version > $101 then
    AStream.ReadBuffer(AHeader.overlayIndexes[NUM_OVERLAY_0], SizeOf(AHeader) - ILFILEHEADER_SIZE0);

  ABitmap := ReadImage(AHeader);
  try
    BeginUpdate;
    try
      Clear;
      SetSize(AHeader.cx, AHeader.cy);
      AddSliced(ABitmap, ABitmap.Width div AHeader.cx, ABitmap.Height div AHeader.cy);
      while Count > AHeader.cImage do
        Delete(Count - 1);
    finally
      EndUpdate;
    end;
  finally
    ABitmap.Free;
  end;
{$ELSE}
begin
  inherited ReadData(AStream);
{$ENDIF}
end;

procedure TACLImageList.WriteData(Stream: TStream);
{$IFDEF FPC}
begin
  Stream.WriteInt32(HeaderLCL);
  inherited WriteData(Stream);
{$ELSE}
var
  LData: TMemoryStream;
  LPosition1: Int64;
  LPosition2: Int64;
begin
  LData := TMemoryStream.Create;
  try
    inherited WriteData(LData);

    Stream.WriteInt32(HeaderZIP);
    Stream.WriteInt32(LData.Size); // uncompressed size
    Stream.WriteInt32(0); // compressed size
    LPosition1 := Stream.Position;

    with TCompressionStream.Create(TCompressionLevel.clDefault, Stream) do
    try
      WriteBuffer(LData.Memory^, LData.Size);
    finally
      Free;
    end;

    LPosition2 := Stream.Position;
    Stream.Position := LPosition1 - SizeOf(Integer);
    Stream.WriteInt32(LPosition2 - LPosition1); // match the "compressed size"
    Stream.Position := LPosition2;
  finally
    LData.Free;
  end;
{$ENDIF}
end;

end.
