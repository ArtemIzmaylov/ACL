﻿////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   ImageBox / SubImage Selector
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.Images;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
  LMessages,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Generics.Defaults,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  System.UITypes,
  // ACL
  ACL.Math,
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.SkinImage,
  ACL.UI.Controls.Base,
  ACL.UI.ImageList,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

type
  TACLImagePictureClass = class of TACLImagePicture;
  TACLImagePicture = class;

  { TACLImageBox }

  TACLImageBox = class(TACLGraphicControl)
  strict private
    FFitMode: TACLFitMode;
    FPicture: TACLImagePicture;

    function GetPictureClass: TACLImagePictureClass;
    function GetPictureClassName: string;
    function GetPictureRect: TRect;
    procedure SetFitMode(const Value: TACLFitMode);
    procedure SetPicture(const Value: TACLImagePicture);
    procedure SetPictureClass(const Value: TACLImagePictureClass);
    procedure SetPictureClassName(const Value: string);
  protected
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure Changed;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure Paint; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateTransparency; override;
    //# Properties
    property PictureRect: TRect read GetPictureRect;
  public
    class var PictureClasses: TACLListOf<TACLImagePictureClass>;
    class constructor Create;
    class destructor Destroy;
    class function GetClassByDescription(const ADesctiption: string): TACLImagePictureClass;
    class function GetDescriptionByClass(AClass: TACLImagePictureClass): string;
    class procedure Register(AClass: TACLImagePictureClass);
    class procedure Unregister(AClass: TACLImagePictureClass);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //# Properties
    property PictureClass: TACLImagePictureClass read GetPictureClass write SetPictureClass;
  published
    property AutoSize;
    property FitMode: TACLFitMode read FFitMode write SetFitMode default afmProportionalStretch;
    property PictureClassName: string read GetPictureClassName write SetPictureClassName; //#AI: before Picture
    property Picture: TACLImagePicture read FPicture write SetPicture;
    //# Events
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

  { TACLImagePicture }

  TACLImagePicture = class(TACLLockablePersistent)
  protected
    FOwner: TACLImageBox;

    procedure DoChanged(AChanges: TACLPersistentChanges); override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); virtual;
    procedure SetTargetDPI(AValue: Integer); virtual;
  public
    constructor Create(AImage: TACLImageBox); virtual;
    procedure Draw(ACanvas: TCanvas; const R: TRect; AEnabled: Boolean); virtual; abstract;
    class function GetDescription: string; virtual; abstract;
    function IsEmpty: Boolean; virtual; abstract;
    function GetSize: TSize; virtual; abstract;
  end;

  { TACLImagePictureGlyph }

  TACLImagePictureGlyph = class(TACLImagePicture,
    IACLResourceChangeListener)
  strict private
    FGlyph: TACLGlyph;

    procedure SetGlyph(const Value: TACLGlyph);
  protected
    procedure DoAssign(Source: TPersistent); override;
    procedure SetTargetDPI(AValue: Integer); override;
    // IACLResourceChangeListener
    procedure ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
  public
    constructor Create(AImage: TACLImageBox); override;
    destructor Destroy; override;
    procedure Draw(ACanvas: TCanvas; const R: TRect; AEnabled: Boolean); override;
    class function GetDescription: string; override;
    function IsEmpty: Boolean; override;
    function GetSize: TSize; override;
  published
    property Glyph: TACLGlyph read FGlyph write SetGlyph;
  end;

  { TACLImagePictureImageList }

  TACLImagePictureImageList = class(TACLImagePicture)
  strict private
    FChangeLink: TChangeLink;
    FImageIndex: TImageIndex;
    FImages: TCustomImageList;

    procedure ChangeHandler(Sender: TObject);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImages(const Value: TCustomImageList);
  protected
    procedure DoAssign(Source: TPersistent); override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor Create(AImage: TACLImageBox); override;
    destructor Destroy; override;
    procedure Draw(ACanvas: TCanvas; const R: TRect; AEnabled: Boolean); override;
    class function GetDescription: string; override;
    function GetSize: TSize; override;
    function IsEmpty: Boolean; override;
  published
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property Images: TCustomImageList read FImages write SetImages;
  end;

  { TACLSelectionFrame }

  TACLSelectionFrameHitTestCode = (sfeNone, sfeClient, 
    sfeFrame, sfeLeft, sfeTop, sfeRight, sfeBottom,
    sfeCornerLeftTop, sfeCornerRightTop, sfeCornerLeftBottom, sfeCornerRightBottom);
  TACLSelectionFrameElement = sfeFrame..sfeCornerRightBottom;
  TACLSelectionFrameElements = set of TACLSelectionFrameElement;
  TACLSelectionFrameHandleAlignment = (sfhaInside, sfhaOutside);

  TACLSelectionFrame = class(TACLUnknownObject)
  public const
    DefaultLineSize = 1;
    DefaultCornerSize = 12;
    DefaultFrameSize = 3;
    DefaultSideSize = 16;
  strict private
    FAllowedElements: TACLSelectionFrameElements;
    FBounds: TRect;
    FHandleAlignment: TACLSelectionFrameHandleAlignment;
  protected
    FElements: array [TACLSelectionFrameElement] of TRect;
    FFrameSize: Integer;
    FLineSize: Integer;
  public
    constructor Create;
    procedure Calculate(const ABounds: TRect; ATargetDpi: Integer);
    function CalculateBounds(const AControlBounds: TRect; ATargetDpi: Integer): TRect;
    function CalculateHitTest(const P: TPoint): TACLSelectionFrameHitTestCode;
    procedure Draw(ARender: TACL2DRender; ASelectedElement: TACLSelectionFrameHitTestCode = sfeNone); overload;
    procedure Draw(DC: HDC; ASelectedElement: TACLSelectionFrameHitTestCode = sfeNone); overload;
    //# Properties
    property AllowedElements: TACLSelectionFrameElements read FAllowedElements write FAllowedElements;
    property Bounds: TRect read FBounds;
    property HandleAlignment: TACLSelectionFrameHandleAlignment read FHandleAlignment write FHandleAlignment;
  end;

  { TACLSubImageSelector }

  TACLSubImageSelectorDragMode = (dmNone, dmMove, dmDrawNew,
    dmResizeLeft, dmResizeTop, dmResizeRight, dmResizeBottom,
    dmResizeCornerLeftTop, dmResizeCornerRightTop,
    dmResizeCornerLeftBottom, dmResizeCornerRightBottom);
  TACLSubImageSelectorPaintEvent = procedure (
    Sender: TObject; Canvas: TCanvas; const ImageRect: TRect) of object;

  TACLSubImageSelector = class(TACLCustomControl)
  strict private
    FDisplayImageRect: TRect;
    FDragCapturePoint: TPoint;
    FDragCaptureRect: TRectF;
    FDragMode: TACLSubImageSelectorDragMode;
    FHitTest: TACLSelectionFrameElement;
    FImageCrop: TRectF;
    FImageSize: TSize;
    FIsKeyboardAction: Boolean;
    FSelection: TACLSelectionFrame;

    FOnChanged: TNotifyEvent;
    FOnPaint: TACLSubImageSelectorPaintEvent;

    function CalculateDragMode(Shift: TShiftState): TACLSubImageSelectorDragMode; 
    function GetImageCrop: TRect;
    procedure SetHitTest(AValue: TACLSelectionFrameElement);
    procedure SetImageCrop(const Value: TRect); overload;
    procedure SetImageCrop(const Value: TRectF); overload;
    procedure SetImageSize(const Value: TSize);
  protected
    procedure BoundsChanged; override;
    procedure Calculate;
    procedure Changed;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateHitTest(X, Y: Integer);
    procedure UpdateTransparency; override;
    //# Messages
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
    //# Properties
    property HitTest: TACLSelectionFrameElement read FHitTest write SetHitTest;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //# Properties
    property DisplayImageRect: TRect read FDisplayImageRect;
    property ImageCrop: TRect read GetImageCrop write SetImageCrop;
    property ImageSize: TSize read FImageSize write SetImageSize;
    property IsKeyboardAction: Boolean read FIsKeyboardAction;
  published
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property OnPaint: TACLSubImageSelectorPaintEvent read FOnPaint write FOnPaint;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
  end;

implementation

{$IFNDEF FPC}
uses
  ACL.Graphics.SkinImageSet; // inlining
{$ENDIF}

procedure acInvertRect(DC: HDC; const R: TRect);
{$IFDEF FPC}
var
  LDib: TACLDib;
  LPix: PACLPixel32;
  I: Integer;
begin
  LDib := TACLDib.Create(R);
  try
    acBitBlt(LDib.handle, DC, LDib.ClientRect, R.TopLeft);
    for I := 0 to LDib.ColorCount - 1 do
    begin
      LPix := @LDib.Colors^[I];
      LPix^.R := $FF xor LPix^.R;
      LPix^.G := $FF xor LPix^.G;
      LPix^.B := $FF xor LPix^.B;
    end;
    acBitBlt(DC, LDib.Handle, R, NullPoint);
  finally
    LDib.Free;
  end;
{$ELSE}
begin
  PatBlt(DC, R.Left, R.Top, R.Width, R.Height, PATINVERT);
{$ENDIF}
end;

{ TACLImageBox }

constructor TACLImageBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFitMode := afmProportionalStretch;
end;

destructor TACLImageBox.Destroy;
begin
  FreeAndNil(FPicture);
  inherited;
end;

function TACLImageBox.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
var
  ASize: TSize;
begin
  Result := True;
  if AutoSize and (Picture <> nil) and not Picture.IsEmpty then
  begin
    ASize := Picture.GetSize;
    NewHeight := ASize.cy;
    NewWidth := ASize.cx;
  end;
end;

function TACLImageBox.GetPictureClass: TACLImagePictureClass;
begin
  if Picture <> nil then
    Result := TACLImagePictureClass(Picture.ClassType)
  else
    Result := nil;
end;

function TACLImageBox.GetPictureClassName: string;
begin
  if Picture <> nil then
    Result := Picture.ClassName
  else
    Result := '';
end;

function TACLImageBox.GetPictureRect: TRect;
begin
  if Picture <> nil then
  begin
    Result := ClientRect;
    Result.Center(acFitSize(ClientRect.Size, Picture.GetSize, FitMode));
  end
  else
    Result := NullRect;
end;

procedure TACLImageBox.Changed;
begin
  if AutoSize then
    AdjustSize;
  Invalidate;
end;

procedure TACLImageBox.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;
  if Picture <> nil then
    Picture.Notification(AComponent, AOperation);
end;

procedure TACLImageBox.Paint;
begin
  if csDesigning in ComponentState then
    acDrawHatch(Canvas.Handle, ClientRect);
  if (Picture <> nil) and not Picture.IsEmpty then
    Picture.Draw(Canvas, PictureRect, Enabled);
end;

procedure TACLImageBox.SetTargetDPI(AValue: Integer);
begin
  inherited;
  if FPicture <> nil then
    FPicture.SetTargetDPI(AValue);
end;

procedure TACLImageBox.SetFitMode(const Value: TACLFitMode);
begin
  if FFitMode <> Value then
  begin
    FFitMode := Value;
    Changed;
  end;
end;

procedure TACLImageBox.SetPicture(const Value: TACLImagePicture);
begin
  if Picture <> Value then
  begin
    PictureClass := TACLImagePictureClass(Value.ClassType);
    Picture.Assign(Value);
  end;
end;

procedure TACLImageBox.SetPictureClass(const Value: TACLImagePictureClass);
begin
  if PictureClass <> Value then
  begin
    FreeAndNil(FPicture);
    if Value <> nil then
    begin
      FPicture := Value.Create(Self);
      FPicture.SetTargetDPI(FCurrentPPI);
    end;
    Changed;
  end;
end;

procedure TACLImageBox.SetPictureClassName(const Value: string);
begin
  PictureClass := TACLImagePictureClass(FindClass(Value));
end;

{ TACLImageBox }

class constructor TACLImageBox.Create;
begin
  PictureClasses := TACLListOf<TACLImagePictureClass>.Create;
  Register(TACLImagePictureGlyph);
  Register(TACLImagePictureImageList);
end;

class destructor TACLImageBox.Destroy;
begin
  FreeAndNil(PictureClasses);
end;

class function TACLImageBox.GetClassByDescription(const ADesctiption: string): TACLImagePictureClass;
var
  I: Integer;
begin
  for I := 0 to PictureClasses.Count - 1 do
  begin
    if PictureClasses[I].GetDescription = ADesctiption then
      Exit(PictureClasses[I]);
  end;
  Result := nil;
end;

class function TACLImageBox.GetDescriptionByClass(AClass: TACLImagePictureClass): string;
var
  I: Integer;
begin
  for I := 0 to PictureClasses.Count - 1 do
  begin
    if PictureClasses[I] = AClass then
      Exit(PictureClasses[I].GetDescription);
  end;
  Result := '';
end;

class procedure TACLImageBox.Register(AClass: TACLImagePictureClass);
begin
  if not PictureClasses.Contains(AClass) then
  begin
    RegisterClass(AClass);
    PictureClasses.Add(AClass);
  end;
end;

class procedure TACLImageBox.Unregister(AClass: TACLImagePictureClass);
begin
  UnRegisterClass(AClass);
  if PictureClasses <> nil then
    PictureClasses.Remove(AClass);
end;

procedure TACLImageBox.UpdateTransparency;
begin
  ControlStyle := ControlStyle - [csOpaque];
end;

{ TACLImagePicture }

constructor TACLImagePicture.Create(AImage: TACLImageBox);
begin
  FOwner := AImage;
end;

procedure TACLImagePicture.DoChanged(AChanges: TACLPersistentChanges);
begin
  FOwner.Changed;
end;

procedure TACLImagePicture.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  // do nothing
end;

procedure TACLImagePicture.SetTargetDPI(AValue: Integer);
begin
  // do nothing
end;

{ TACLImagePictureGlyph }

constructor TACLImagePictureGlyph.Create(AImage: TACLImageBox);
begin
  inherited Create(AImage);
  FGlyph := TACLGlyph.Create(Self);
end;

destructor TACLImagePictureGlyph.Destroy;
begin
  FreeAndNil(FGlyph);
  inherited;
end;

procedure TACLImagePictureGlyph.Draw(ACanvas: TCanvas; const R: TRect; AEnabled: Boolean);
begin
  Glyph.Draw(ACanvas, R, AEnabled);
end;

class function TACLImagePictureGlyph.GetDescription: string;
begin
  Result := 'Glyph';
end;

function TACLImagePictureGlyph.GetSize: TSize;
begin
  Result := Glyph.FrameSize;
end;

function TACLImagePictureGlyph.IsEmpty: Boolean;
begin
  Result := Glyph.Empty;
end;

procedure TACLImagePictureGlyph.DoAssign(Source: TPersistent);
begin
  if Source is TACLImagePictureGlyph then
    Glyph.Assign(TACLImagePictureGlyph(Source))
  else
    inherited;
end;

procedure TACLImagePictureGlyph.ResourceChanged(Sender: TObject; Resource: TACLResource);
begin
  Changed;
end;

procedure TACLImagePictureGlyph.SetTargetDPI(AValue: Integer);
begin
  Glyph.TargetDPI := AValue;
end;

procedure TACLImagePictureGlyph.SetGlyph(const Value: TACLGlyph);
begin
  Glyph.Assign(Value);
end;

{ TACLImagePictureImageList }

constructor TACLImagePictureImageList.Create(AImage: TACLImageBox);
begin
  inherited;
  FImageIndex := -1;
  FChangeLink := TChangeLink.Create;
  FChangeLink.OnChange := ChangeHandler;
end;

destructor TACLImagePictureImageList.Destroy;
begin
  Images := nil;
  FreeAndNil(FChangeLink);
  inherited;
end;

procedure TACLImagePictureImageList.DoAssign(Source: TPersistent);
begin
  if Source is TACLImagePictureImageList then
  begin
    Images := TACLImagePictureImageList(Source).Images;
    ImageIndex := TACLImagePictureImageList(Source).ImageIndex;
  end;
end;

procedure TACLImagePictureImageList.Draw(ACanvas: TCanvas; const R: TRect; AEnabled: Boolean);
begin
  acDrawImage(ACanvas, R, Images, ImageIndex, AEnabled);
end;

class function TACLImagePictureImageList.GetDescription: string;
begin
  Result := 'ImageList';
end;

function TACLImagePictureImageList.GetSize: TSize;
begin
  Result := acGetImageListSize(Images, FOwner.FCurrentPPI)
end;

function TACLImagePictureImageList.IsEmpty: Boolean;
begin
  Result := (Images = nil) or (ImageIndex < 0);
end;

procedure TACLImagePictureImageList.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;
  if AComponent = Images then
    Images := nil;
end;

procedure TACLImagePictureImageList.ChangeHandler(Sender: TObject);
begin
  Changed;
end;

procedure TACLImagePictureImageList.SetImageIndex(const Value: TImageIndex);
begin
  if ImageIndex <> Value then
  begin
    FImageIndex := Value;
    Changed;
  end;
end;

procedure TACLImagePictureImageList.SetImages(const Value: TCustomImageList);
begin
  if Images <> Value then
  begin
    BeginUpdate;
    try
      acSetImageList(Value, FImages, FChangeLink, FOwner);
    finally
      EndUpdate;
    end;
  end;
end;

{ TACLSelectionFrame }

constructor TACLSelectionFrame.Create;
var
  AElement: TACLSelectionFrameElement;
begin
  AllowedElements := [Low(TACLSelectionFrameElement)..High(TACLSelectionFrameElement)];
  for AElement := Low(AElement) to High(AElement) do
    FElements[AElement] := NullRect;
end;

procedure TACLSelectionFrame.Calculate(const ABounds: TRect; ATargetDpi: Integer);
var
  ACornerSize: Integer;
  AElement: TACLSelectionFrameElement;
  ARect: TRect;
  ASideSize: Integer;
begin
  FBounds := ABounds;
  FFrameSize := dpiApply(DefaultFrameSize, ATargetDpi);

  FLineSize := dpiApply(DefaultLineSize, ATargetDpi);
  ASideSize := dpiApply(DefaultSideSize, ATargetDpi);
  ACornerSize := dpiApply(DefaultCornerSize, ATargetDpi);
  ACornerSize := Min(ACornerSize, Min(FBounds.Width, FBounds.Height) div 3);

  FElements[sfeFrame] := Bounds;
  if HandleAlignment = sfhaOutside then
    FElements[sfeFrame].Inflate(-FFrameSize + FLineSize);

  ARect := ABounds;
  ARect.Height := ACornerSize;
  FElements[sfeCornerLeftTop] := ARect;
  FElements[sfeCornerLeftTop].Width := ACornerSize;
  FElements[sfeCornerRightTop] := ARect.Split(srRight, ACornerSize);

  ARect := FBounds.Split(srBottom, ACornerSize);
  FElements[sfeCornerLeftBottom] := ARect;
  FElements[sfeCornerLeftBottom].Width := ACornerSize;
  FElements[sfeCornerRightBottom] := ARect.Split(srRight, FBounds.Right, ACornerSize);

  ARect := ABounds;
  ARect.CenterVert(MaxMin(ASideSize, 0, FBounds.Height - 3 * (ACornerSize + 1)));
  FElements[sfeLeft] := ARect;
  FElements[sfeLeft].Width := ACornerSize;
  FElements[sfeRight] := ARect.Split(srRight, ACornerSize);

  ARect := ABounds;
  ARect.CenterHorz(MaxMin(ASideSize, 0, FBounds.Width - 3 * (ACornerSize + 1)));
  FElements[sfeBottom] := ARect.Split(srBottom, ACornerSize);
  FElements[sfeTop] := ARect;
  FElements[sfeTop].Height := ACornerSize;

  for AElement := Low(TACLSelectionFrameElement) to High(TACLSelectionFrameElement) do
  begin
    if not (AElement in AllowedElements) then
      FElements[AElement] := NullRect;
  end;
end;

function TACLSelectionFrame.CalculateBounds(const AControlBounds: TRect; ATargetDpi: Integer): TRect;
begin
  Result := AControlBounds;
  if HandleAlignment = sfhaOutside then
    Result.Inflate(
      dpiApply(DefaultFrameSize, ATargetDpi) -
      dpiApply(DefaultLineSize, ATargetDpi));
end;

function TACLSelectionFrame.CalculateHitTest(const P: TPoint): TACLSelectionFrameHitTestCode;
var
  AIndex: TACLSelectionFrameElement;
begin
  Result := sfeNone;
  if PtInRect(Bounds.InflateTo(FFrameSize), P) then
  begin
    for AIndex := High(AIndex) downto sfeLeft do
    begin
      if PtInRect(FElements[AIndex], P) then
        Exit(AIndex);
    end;
    if PtInRect(Bounds.InflateTo(-FFrameSize), P) then
      Result := sfeClient
    else
      Result := sfeFrame;
  end;
end;

procedure TACLSelectionFrame.Draw(ARender: TACL2DRender; ASelectedElement: TACLSelectionFrameHitTestCode);

  procedure DrawElements(const AClipRect: TRect);
  var
    I: TACLSelectionFrameElement;
    LClipData: TACL2DRenderRawData;
  begin
    if ARender.Clip(AClipRect, LClipData) then
    try
      for I := Low(FElements) to High(FElements) do
      begin
        if I = ASelectedElement then
          ARender.FillHatchRectangle(FElements[I], TAlphaColors.Black, TAlphaColors.White, 1)
        else
          ARender.FillRectangle(FElements[I], TAlphaColors.Black);
      end;
    finally
      ARender.ClipRestore(LClipData);
    end;
  end;

var
  AGdi: IACL2DRenderGdiCompatible;
begin
  if Supports(ARender, IACL2DRenderGdiCompatible, AGdi) then
  begin
    AGdi.GdiDraw(
      procedure (DC: HDC; out UpdatedRect: TRect)
      begin
        Draw(DC, ASelectedElement);
        UpdatedRect := Bounds;
      end)
  end
  else
  begin
    DrawElements(Bounds.Split(srBottom, FFrameSize));
    DrawElements(Bounds.Split(srRight, FFrameSize));
    DrawElements(Bounds.Split(srTop, FFrameSize));
    DrawElements(Bounds.Split(srLeft, FFrameSize));
  end;
end;

procedure TACLSelectionFrame.Draw(DC: HDC; ASelectedElement: TACLSelectionFrameHitTestCode = sfeNone);

  procedure DrawElement(AElement: TACLSelectionFrameElement);
  var
    R: TRect;
  begin
    R := FElements[AElement];
    if not R.IsEmpty then
    begin
      if ASelectedElement = AElement then
        acDrawHatch(DC, R, clWhite, clBlack, 1)
      else
        acInvertRect(DC, R);

      acExcludeFromClipRegion(DC, R.InflateTo(2 * FLineSize));
    end;
  end;

var
  AClipRgn: TRegionHandle;
  AElement: TACLSelectionFrameElement;
begin
  AClipRgn := acSaveClipRegion(DC);
  try
    acIntersectClipRegion(DC, Bounds);
    acExcludeFromClipRegion(DC, Bounds.InflateTo(-FFrameSize));
    for AElement := High(AElement) downto Low(AElement) do
    begin
      if AElement <> sfeFrame then
        DrawElement(AElement);
    end;
    if not FElements[sfeFrame].IsEmpty then
    begin
      acExcludeFromClipRegion(DC, FElements[sfeFrame].InflateTo(-FLineSize));
      DrawElement(sfeFrame);
    end;
  finally
    acRestoreClipRegion(DC, AClipRgn);
  end;
end;

{ TACLSubImageSelector }

constructor TACLSubImageSelector.Create(AOwner: TComponent);
begin
  FSelection := TACLSelectionFrame.Create;
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csCaptureMouse];
  FocusOnClick := True;
end;

destructor TACLSubImageSelector.Destroy;
begin
  FreeAndNil(FSelection);
  inherited Destroy;
end;

procedure TACLSubImageSelector.Calculate;
var
  ARect: TRect;
begin
  FDisplayImageRect := acFitRect(ClientRect,
    dpiApply(ImageSize.cx, FCurrentPPI),
    dpiApply(ImageSize.cy, FCurrentPPI), afmFit);

  if not DisplayImageRect.IsEmpty then
  begin
    ARect := (FImageCrop * (DisplayImageRect.Width / ImageSize.cx)).Round;
    ARect.Offset(FDisplayImageRect.TopLeft);
    FSelection.Calculate(ARect, FCurrentPPI);
  end;

  Invalidate;
  Update;
end;

procedure TACLSubImageSelector.Changed;
begin
  CallNotifyEvent(Self, OnChanged);
end;

procedure TACLSubImageSelector.KeyDown(var Key: Word; Shift: TShiftState);
var
  ARect: TRect;
begin
  inherited;
  FIsKeyboardAction := True;
  try
    ARect := ImageCrop;
    case Key of
      VK_LEFT:
        ARect.Offset(IfThen(ImageCrop.Left > 0, -1), 0);
      VK_UP:
        ARect.Offset(0, IfThen(ImageCrop.Top > 0, -1));
      VK_RIGHT:
        ARect.Offset(IfThen(ImageCrop.Right < ImageSize.cx, 1), 0);
      VK_DOWN:
        ARect.Offset(0, IfThen(ImageCrop.Bottom < ImageSize.cy, 1));
    else
      Exit;
    end;
    ImageCrop := ARect;
  finally
    FIsKeyboardAction := False;
  end;
end;

procedure TACLSubImageSelector.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);

  FDragCapturePoint := Point(X, Y);
  FDragCaptureRect := FImageCrop;
  UpdateHitTest(X, Y);

  if PtInRect(DisplayImageRect, FDragCapturePoint) then
    FDragMode := CalculateDragMode(Shift)
  else
    FDragMode := dmNone;
end;

procedure TACLSubImageSelector.MouseMove(Shift: TShiftState; X, Y: Integer);
const
  CursorsMap: array[TACLSubImageSelectorDragMode] of TCursor = (
    crDefault, crSizeAll, crCross,
    crSizeWE, crSizeNS, crSizeWE, crSizeNS,
    crSizeNWSE, crSizeNESW, crSizeNESW, crSizeNWSE
  );
var
  ARect: TRectF;
  dX, dY: Single;
begin
  inherited;

  if not (ssLeft in Shift) then
  begin
    UpdateHitTest(X, Y);
    if PtInRect(DisplayImageRect, Point(X, Y)) then
      Cursor := CursorsMap[CalculateDragMode(Shift)]
    else
      Cursor := crDefault;
    Exit;
  end;

  X := MinMax(X, DisplayImageRect.Left, DisplayImageRect.Right);
  Y := MinMax(Y, DisplayImageRect.Top, DisplayImageRect.Bottom);

  dX := (X - FDragCapturePoint.X) * ImageSize.cx / DisplayImageRect.Width;
  dY := (Y - FDragCapturePoint.Y) * ImageSize.cy / DisplayImageRect.Height;

  case FDragMode of
    dmMove:
      begin
        ARect := FDragCaptureRect;
        ARect.Offset(dX, dY);
      end;

    dmResizeLeft:
      ARect := TRectF.Create(Max(FDragCaptureRect.Left + dX, 0),
        FDragCaptureRect.Top, FDragCaptureRect.Right, FDragCaptureRect.Bottom);

    dmResizeTop:
      ARect := TRectF.Create(FDragCaptureRect.Left, Max(FDragCaptureRect.Top + dY, 0),
        FDragCaptureRect.Right, FDragCaptureRect.Bottom);

    dmResizeRight:
      ARect := TRectF.Create(FDragCaptureRect.Left, FDragCaptureRect.Top,
        Min(FDragCaptureRect.Right + dX, ImageSize.cx), FDragCaptureRect.Bottom);

    dmResizeBottom:
      ARect := TRectF.Create(FDragCaptureRect.Left, FDragCaptureRect.Top,
        FDragCaptureRect.Right, Min(FDragCaptureRect.Bottom + dY, ImageSize.cy));

    dmResizeCornerLeftTop:
      ARect := TRectF.Create(
        Max(FDragCaptureRect.Left + dX, 0),
        Max(FDragCaptureRect.Top + dY, 0),
        FDragCaptureRect.Right,
        FDragCaptureRect.Bottom);

    dmResizeCornerLeftBottom:
      ARect := TRectF.Create(
        Max(FDragCaptureRect.Left + dX, 0),
        FDragCaptureRect.Top,
        FDragCaptureRect.Right,
        Min(FDragCaptureRect.Bottom + dY, ImageSize.cy));

    dmResizeCornerRightTop:
      ARect := TRectF.Create(
        FDragCaptureRect.Left,
        Max(FDragCaptureRect.Top + dY, 0),
        Min(FDragCaptureRect.Right + dX, ImageSize.cx),
        FDragCaptureRect.Bottom);

    dmResizeCornerRightBottom:
      ARect := TRectF.Create(
        FDragCaptureRect.Left, FDragCaptureRect.Top,
        Min(FDragCaptureRect.Right + dX, ImageSize.cx),
        Min(FDragCaptureRect.Bottom + dY, ImageSize.cy));

    dmDrawNew:
      begin
        ARect := TRectF.Create(
          Min(X, FDragCapturePoint.X), Min(Y, FDragCapturePoint.Y),
          Max(X, FDragCapturePoint.X), Max(Y, FDragCapturePoint.Y));
        ARect.Offset(-DisplayImageRect.Left, -DisplayImageRect.Top);
        ARect := ARect * (ImageSize.cx / DisplayImageRect.Width);
      end;

  else
    Exit;
  end;

  if [ssCtrl, ssShift, ssAlt] * Shift <> [] then
  begin
    ARect.Height := Min(ARect.Width, ARect.Height);
    ARect.Width := ARect.Height;
  end;

  ARect.Height := Min(Max(10, ARect.Height), ImageSize.cy);
  ARect.Width  := Min(Max(10, ARect.Width), ImageSize.cx);

  ARect.Offset(0, Max(0, -ARect.Top));
  ARect.Offset(0, Min(0, ImageSize.cy - ARect.Bottom));
  ARect.Offset(Max(0, -ARect.Left), 0);
  ARect.Offset(Min(0, ImageSize.cx - ARect.Right), 0);

  SetImageCrop(ARect);
end;

procedure TACLSubImageSelector.Paint;
var
  ASaveIndex: Integer;
begin
  inherited Paint;

  if csDesigning in ComponentState then
  begin
    Canvas.Pen.Style := psDash;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(0, 0, Width, Height);
  end;

  if Assigned(OnPaint) then
    OnPaint(Self, Canvas, DisplayImageRect);

  if Enabled then
  begin
    ASaveIndex := SaveDC(Canvas.Handle);
    try
      FSelection.Draw(Canvas.Handle, HitTest);
      acExcludeFromClipRegion(Canvas.Handle, FSelection.Bounds);
      acFillRect(Canvas, DisplayImageRect, TAlphaColor.FromColor(clBlack, 160));
    finally
      RestoreDC(Canvas.Handle, ASaveIndex);
    end;
  end;
end;

procedure TACLSubImageSelector.BoundsChanged;
begin
  inherited;
  Calculate;
end;

procedure TACLSubImageSelector.SetTargetDPI(AValue: Integer);
begin
  inherited;
  Calculate;
end;

procedure TACLSubImageSelector.UpdateHitTest(X, Y: Integer);
begin
  HitTest := FSelection.CalculateHitTest(Point(X, Y));
end;

procedure TACLSubImageSelector.UpdateTransparency;
begin
  ControlStyle := ControlStyle - [csOpaque];
end;

procedure TACLSubImageSelector.WMGetDlgCode(var AMessage: TWMGetDlgCode);
begin
  inherited;
  AMessage.Result := DLGC_WANTARROWS;
end;

function TACLSubImageSelector.CalculateDragMode(Shift: TShiftState): TACLSubImageSelectorDragMode;
const
  Map: array[TACLSelectionFrameHitTestCode] of TACLSubImageSelectorDragMode = (
    dmDrawNew,
    dmMove, 
    dmNone,
    dmResizeLeft,
    dmResizeTop,
    dmResizeRight,
    dmResizeBottom,
    dmResizeCornerLeftTop,
    dmResizeCornerRightTop,
    dmResizeCornerLeftBottom,
    dmResizeCornerRightBottom
  );
begin
  Result := Map[HitTest];
  if Result = dmNone then
  begin
    if [ssAlt, ssShift, ssCtrl] * Shift <> [] then
      Result := dmDrawNew
    else
      Result := dmMove;
  end;
end;

function TACLSubImageSelector.GetImageCrop: TRect;
begin
  Result := FImageCrop.Round;
end;

procedure TACLSubImageSelector.SetImageCrop(const Value: TRect);
begin
  SetImageCrop(TRectF.Create(Value));
end;

procedure TACLSubImageSelector.SetHitTest(AValue: TACLSelectionFrameElement);
begin
  if HitTest <> AValue then
  begin
    FHitTest := AValue;
    Invalidate;
  end;
end;

procedure TACLSubImageSelector.SetImageCrop(const Value: TRectF);
begin
  if FImageCrop <> Value then
  begin
    FImageCrop.Bottom := MinMax(Value.Bottom, 0, ImageSize.cy);
    FImageCrop.Left := MinMax(Value.Left, 0, ImageSize.cx);
    FImageCrop.Right := MinMax(Value.Right, 0, ImageSize.cx);
    FImageCrop.Top := MinMax(Value.Top, 0, ImageSize.cy);
    Calculate;
    Changed;
  end;
end;

procedure TACLSubImageSelector.SetImageSize(const Value: TSize);
begin
  if ImageSize <> Value then
  begin
    FImageSize := Value;
    SetImageCrop(Bounds(0, 0, Min(ImageSize.cx, ImageSize.cy), Min(ImageSize.cx, ImageSize.cy)));
    Calculate;
  end;
end;

end.
