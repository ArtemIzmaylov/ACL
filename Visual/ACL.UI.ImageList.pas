{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             ImageList Classes             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.ImageList;

{$I ACL.Config.inc}

interface

uses
  Winapi.Messages,
  Winapi.Windows,
  // System
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Types,
  System.TypInfo,
  System.ZLib,
  // Vcl
  Vcl.ActnList,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Timers,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Images,
  ACL.Graphics.Ex,
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.UI.Animation,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common;

type

  { TACLImageList }

  TACLImageList = class(TImageList)
  strict private const
    CompressedStreamID = $5A43494C; // ZCIL
  strict private
    FSourceDPI: Integer;

    function GetScalable: Boolean;
    procedure SetScalable(AValue: Boolean);
    procedure SetSourceDPI(AValue: Integer);
  protected
    procedure DoDraw(Index: Integer; Canvas: TCanvas; X, Y: Integer; Style: Cardinal; Enabled: Boolean = True); override;
    procedure ReadData(Stream: TStream); override;
    procedure WriteData(Stream: TStream); override;
  public
    procedure AfterConstruction; override;
    procedure AddBitmap(ABitmap: TBitmap);
    procedure AddImage(AImage: TACLSkinImage);
    function AddIconFromResource(AInstance: HINST; const AName: string): Integer;
    procedure LoadFromBitmap(ABitmap: TBitmap);
    procedure LoadFromResource(AInstance: HINST; const AName: string); overload;
    procedure LoadFromResource(AInstance: HINST; const AName: string; const AType: PChar); overload;
    procedure LoadFromStream(AStream: TStream);
    procedure ReplaceBitmap(AIndex: Integer; ABitmap: TBitmap);
    procedure SetSize(AValue: Integer); overload;
  published
    property ColorDepth default cd32Bit;
    property Masked default False;
    property Scalable: Boolean read GetScalable write SetScalable stored False;
    property SourceDPI: Integer read FSourceDPI write SetSourceDPI default 96;
  end;

procedure acDrawImage(ACanvas: TCanvas; const R: TRect; AImageList: TCustomImageList;
  AImageIndex: Integer; AIsEnabled: Boolean = True);
function acGetImageListSize(AImageList: TCustomImageList; ATargetDPI: Integer): TSize;
procedure acSetImageList(AValue: TCustomImageList; var AFieldValue: TCustomImageList;
  AChangeLink: TChangeLink; ANotifyComponent: TComponent);
implementation

uses
  System.Math,
  System.RTLConsts,
  // ACL
  ACL.Utils.DPIAware,
  ACL.Utils.RTTI,
  ACL.Utils.Stream;

procedure acDrawImage(ACanvas: TCanvas; const R: TRect;
  AImageList: TCustomImageList; AImageIndex: Integer; AIsEnabled: Boolean = True);
var
  ALayer: TACLBitmapLayer;
begin
  if (AImageList <> nil) and (AImageIndex >= 0) and RectVisible(ACanvas.Handle, R) then
  begin
    if (R.Width <> AImageList.Width) or (R.Height <> AImageList.Height) then
    begin
      ALayer := TACLBitmapLayer.Create(AImageList.Width, AImageList.Height);
      try
        AImageList.Draw(ALayer.Canvas, 0, 0, AImageIndex, AIsEnabled);
        ALayer.DrawBlend(ACanvas.Handle, R, MaxByte, True);
      finally
        ALayer.Free;
      end;
    end
    else
      AImageList.Draw(ACanvas, R.Left, R.Top, AImageIndex, AIsEnabled);
  end;
end;

function acGetImageListSize(AImageList: TCustomImageList; ATargetDPI: Integer): TSize;
begin
  if AImageList <> nil then
  begin
    Result := TSize.Create(AImageList.Width, AImageList.Height);
    if (AImageList is TACLImageList) and TACLImageList(AImageList).Scalable then
      Result.Scale(ATargetDPI, TACLImageList(AImageList).SourceDPI);
  end
  else
    Result := NullSize;
end;

procedure acSetImageList(AValue: TCustomImageList; var AFieldValue: TCustomImageList; AChangeLink: TChangeLink; ANotifyComponent: TComponent);
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
  ColorDepth := cd32Bit;
  Masked := False;
end;

procedure TACLImageList.AddBitmap(ABitmap: TBitmap);
var
  B: TACLBitmap;
begin
  if ABitmap.PixelFormat = pf32bit then
    Add(ABitmap, nil)
  else
  begin
    B := TACLBitmap.Create;
    try
      B.Assign(ABitmap);
      B.PixelFormat := pf32bit;
      B.MakeTransparent(clFuchsia);
      Add(B, nil);
    finally
      B.Free;
    end;
  end;
end;

procedure TACLImageList.AddImage(AImage: TACLSkinImage);
var
  ABitmap: TBitmap;
begin
  ABitmap := TBitmap.Create;
  try
    AImage.SaveToBitmap(ABitmap);
    AddBitmap(ABitmap);
  finally
    ABitmap.Free;
  end;
end;

function TACLImageList.AddIconFromResource(AInstance: HINST; const AName: string): Integer;
var
  AIcon: TIcon;
begin
  AIcon := TIcon.Create;
  try
    AIcon.Handle := LoadIcon(AInstance, PChar(AName));
    if AIcon.HandleAllocated then
      Result := AddIcon(AIcon)
    else
      Result := -1;
  finally
    AIcon.Free;
  end;
end;

procedure TACLImageList.DoDraw(Index: Integer; Canvas: TCanvas; X, Y: Integer; Style: Cardinal; Enabled: Boolean = True);
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
        acFillRect(ALayer.Handle, ALayer.ClientRect, clFuchsia);
        inherited DoDraw(Index, ALayer.Canvas, 0, 0, Style);
        ALayer.MakeTransparent(clFuchsia);
      end;
      if not Enabled then
        ALayer.MakeDisabled;
      ALayer.DrawBlend(Canvas.Handle, Point(X, Y));
    finally
      ALayer.Free;
    end;
  end;
end;

function TACLImageList.GetScalable: Boolean;
begin
  Result := FSourceDPI > 0;
end;

procedure TACLImageList.LoadFromBitmap(ABitmap: TBitmap);
begin
  Clear;
  if not ABitmap.Empty then
    AddBitmap(ABitmap);
end;

procedure TACLImageList.LoadFromResource(AInstance: HINST; const AName: string);
var
  ABitmap: TBitmap;
begin
  ABitmap := TACLBitmap.Create;
  try
    ABitmap.LoadFromResourceName(AInstance, AName);
    LoadFromBitmap(ABitmap);
  finally
    ABitmap.Free;
  end;
end;

procedure TACLImageList.LoadFromResource(AInstance: HINST; const AName: string; const AType: PChar);
var
  ABitmap: TBitmap;
begin
  with TACLImage.Create(AInstance, AName, AType) do
  try
    ABitmap := ToBitmap;
  finally
    Free;
  end;

  try
    if ABitmap.PixelFormat = pfDevice then
      ABitmap.PixelFormat := pf32bit;
    LoadFromBitmap(ABitmap);
  finally
    ABitmap.Free;
  end;
end;

procedure TACLImageList.LoadFromStream(AStream: TStream);
var
  ABitmap: TBitmap;
begin
  ABitmap := TACLBitmap.Create;
  try
    ABitmap.LoadFromStream(AStream);
    LoadFromBitmap(ABitmap);
  finally
    ABitmap.Free;
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
  B: TACLBitmap;
begin
  if ABitmap.PixelFormat = pf32bit then
    Replace(AIndex, ABitmap, nil)
  else
  begin
    B := TACLBitmap.Create;
    try
      B.Assign(ABitmap);
      B.PixelFormat := pf32bit;
      B.MakeTransparent(clFuchsia);
      Replace(AIndex, B, nil);
    finally
      B.Free;
    end;
  end;
end;

procedure TACLImageList.SetSize(AValue: Integer);
begin
  SetSize(AValue, AValue);
end;

procedure TACLImageList.SetSourceDPI(AValue: Integer);
begin
  if AValue <> 0 then
    AValue := acCheckDPIValue(AValue);
  if AValue <> FSourceDPI then
  begin
    FSourceDPI := AValue;
    Change;
  end;
end;

procedure TACLImageList.ReadData(Stream: TStream);
var
  AData: TMemoryStream;
  ADataCompressed: TACLSubStream;
  AOffset: Int64;
  ASize: Int64;
begin
  if Stream.ReadInt32 = CompressedStreamID then
  begin
    AData := TMemoryStream.Create;
    try
      AData.Size := Stream.ReadInt32;

      ASize := Stream.ReadInt32;
      AOffset := Stream.Position;
      ADataCompressed := TACLSubStream.Create(Stream, AOffset, ASize);
      try
        ZDecompressStream(ADataCompressed, AData);
      finally
        ADataCompressed.Free;
      end;

      AData.Position := 0;
      inherited ReadData(AData);
    finally
      AData.Free;
    end;
  end
  else
  begin
    Stream.Seek(-SizeOf(Integer), soCurrent);
    inherited;
  end;
end;

procedure TACLImageList.WriteData(Stream: TStream);
var
  AData: TMemoryStream;
  APosition1: Int64;
  APosition2: Int64;
begin
  AData := TMemoryStream.Create;
  try
    inherited WriteData(AData);

    Stream.WriteInt32(CompressedStreamID);
    Stream.WriteInt32(AData.Size); // uncompressed size
    Stream.WriteInt32(0); // compressed size
    APosition1 := Stream.Position;

    AData.Position := 0;
    ZCompressStream(AData, Stream);

    APosition2 := Stream.Position;
    Stream.Position := APosition1 - SizeOf(Integer);
    Stream.WriteInt32(APosition2 - APosition1); // match the "compressed size"
    Stream.Position := APosition2;
  finally
    AData.Free;
  end;
end;

end.
