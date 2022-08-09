{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*           Image Based Controls            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Images;

{$I ACL.Config.inc}

interface

uses
  Winapi.Messages,
  Winapi.Windows,
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.ImgList,
  // System
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // ACL
  ACL.Math,
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Layers,
  ACL.Graphics.GdiPlus,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.UI.Controls.BaseControls,
  ACL.UI.ImageList,
  ACL.UI.Resources;

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
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    procedure Changed;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure Paint; override;
    procedure SetTargetDPI(AValue: Integer); override;
    //
    property PictureRect: TRect read GetPictureRect;
  public
    class var PictureClasses: TACLList<TACLImagePictureClass>;
    class constructor Create;
    class destructor Destroy;
    class function GetClassByDescription(const ADesctiption: string): TACLImagePictureClass;
    class function GetDescriptionByClass(AClass: TACLImagePictureClass): string;
    class procedure Register(AClass: TACLImagePictureClass);
    class procedure Unregister(AClass: TACLImagePictureClass);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //
    property PictureClass: TACLImagePictureClass read GetPictureClass write SetPictureClass;
  published
    property AutoSize;
    property FitMode: TACLFitMode read FFitMode write SetFitMode default afmProportionalStretch;
    property PictureClassName: string read GetPictureClassName write SetPictureClassName; //#AI: before Picture
    property Picture: TACLImagePicture read FPicture write SetPicture;
    //
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
    FElements: array [TACLSelectionFrameElement] of TACLRegion;
    FFrameSize: Integer;
    FHandleAlignment: TACLSelectionFrameHandleAlignment;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Calculate(const ABounds: TRect; AScaleFactor: TACLScaleFactor);
    function CalculateBounds(const AControlBounds: TRect; AScaleFactor: TACLScaleFactor): TRect;
    function CalculateHitTest(const P: TPoint): TACLSelectionFrameHitTestCode;
    procedure Draw(DC: HDC; ASelectedElement: TACLSelectionFrameHitTestCode = sfeNone);
    //
    property AllowedElements: TACLSelectionFrameElements read FAllowedElements write FAllowedElements;
    property Bounds: TRect read FBounds;
    property HandleAlignment: TACLSelectionFrameHandleAlignment read FHandleAlignment write FHandleAlignment;
  end;

  { TACLSubImageSelector }

  TACLSubImageSelectorDragMode = (dmNone, dmMove, dmDrawNew, dmResizeLeft, dmResizeTop, dmResizeRight, dmResizeBottom,
    dmResizeCornerLeftTop, dmResizeCornerRightTop, dmResizeCornerLeftBottom, dmResizeCornerRightBottom);
  TACLSubImageSelectorPaintEvent = procedure (Sender: TObject; Canvas: TCanvas; const ImageRect: TRect) of object;

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
    procedure Calculate;
    procedure Changed;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    procedure Paint; override;
    procedure Resize; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateHitTest(X, Y: Integer);
    // Messages
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
    //
    property HitTest: TACLSelectionFrameElement read FHitTest write SetHitTest;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //
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

uses
  Math,
  // ACL
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

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
    Result := acRectCenter(ClientRect, acFitSize(acSize(ClientRect), Picture.GetSize, FitMode))
  else
    Result := NullRect;
end;

function TACLImageBox.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  Result := cbsTransparent;
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
  if IsDesigning then
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
      FPicture.SetTargetDPI(ScaleFactor.TargetDPI);
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
  PictureClasses := TACLList<TACLImagePictureClass>.Create;
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
  Glyph.Draw(ACanvas.Handle, R, AEnabled);
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
  Result := acGetImageListSize(Images, FOwner.ScaleFactor)
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
    FElements[AElement] := TACLRegion.Create;
end;

destructor TACLSelectionFrame.Destroy;
var
  AElement: TACLSelectionFrameElement;
begin
  for AElement := Low(AElement) to High(AElement) do
    FreeAndNil(FElements[AElement]);
  inherited;
end;

procedure TACLSelectionFrame.Calculate(const ABounds: TRect; AScaleFactor: TACLScaleFactor);

  procedure AddSideElement(AElement: TACLSelectionFrameElement; const R: TRect; ALineSize: Integer);
  begin
    if AElement in AllowedElements then
    begin
      if not acRectIsEmpty(R) then
        FElements[sfeFrame].Combine(acRectInflate(R, 2 * ALineSize), rcmDiff);
      FElements[AElement].Combine(R, rcmCopy);
    end
    else
      FElements[AElement].Reset;
  end;

var
  ACornerSize: Integer;
  ALineSize: Integer;
  ARect: TRect;
  ASideSize: Integer;
begin
  FBounds := ABounds;
  FFrameSize := AScaleFactor.Apply(DefaultFrameSize);

  ALineSize := AScaleFactor.Apply(DefaultLineSize);
  ASideSize := AScaleFactor.Apply(DefaultSideSize);
  ACornerSize := AScaleFactor.Apply(DefaultCornerSize);
  ACornerSize := Min(ACornerSize, Min(FBounds.Width, FBounds.Height) div 3);

  if sfeFrame in AllowedElements then
  begin
    if HandleAlignment = sfhaOutside then
    begin
      FElements[sfeFrame].Combine(acRectInflate(Bounds, -FFrameSize + ALineSize), rcmCopy);
      FElements[sfeFrame].Combine(acRectInflate(Bounds, -FFrameSize), rcmDiff);
    end
    else
    begin  
      FElements[sfeFrame].Combine(Bounds, rcmCopy);
      FElements[sfeFrame].Combine(acRectInflate(Bounds, -ALineSize), rcmDiff);
    end;
  end
  else
    FElements[sfeFrame].Reset;

  AddSideElement(sfeCornerLeftTop, acRectSetSize(FBounds, ACornerSize, ACornerSize), ALineSize);
  AddSideElement(sfeCornerRightTop, acRectSetHeight(acRectSetRight(FBounds, FBounds.Right, ACornerSize), ACornerSize), ALineSize);
  AddSideElement(sfeCornerLeftBottom, acRectSetWidth(acRectSetBottom(FBounds, FBounds.Bottom, ACornerSize), ACornerSize), ALineSize);
  AddSideElement(sfeCornerRightBottom, acRectSetRight(acRectSetBottom(FBounds, FBounds.Bottom, ACornerSize), FBounds.Right, ACornerSize), ALineSize);

  ARect := acRectCenterVertically(ABounds, MaxMin(ASideSize, 0, FBounds.Height - 3 * (ACornerSize + 1)));
  AddSideElement(sfeLeft, acRectSetWidth(ARect, ACornerSize), ALineSize);
  AddSideElement(sfeRight, acRectSetRight(ARect, ARect.Right, ACornerSize), ALineSize);

  ARect := acRectCenterHorizontally(ABounds, MaxMin(ASideSize, 0, FBounds.Width - 3 * (ACornerSize + 1)));
  AddSideElement(sfeBottom, acRectSetBottom(ARect, ARect.Bottom, ACornerSize), ALineSize);
  AddSideElement(sfeTop, acRectSetHeight(ARect, ACornerSize), ALineSize);
end;

function TACLSelectionFrame.CalculateBounds(const AControlBounds: TRect; AScaleFactor: TACLScaleFactor): TRect;
begin
  Result := AControlBounds;
  if HandleAlignment = sfhaOutside then
    Result := acRectInflate(Result, AScaleFactor.Apply(DefaultFrameSize) - AScaleFactor.Apply(DefaultLineSize));
end;

function TACLSelectionFrame.CalculateHitTest(const P: TPoint): TACLSelectionFrameHitTestCode;
var
  AIndex: TACLSelectionFrameElement;
begin
  Result := sfeNone;
  if PtInRect(acRectInflate(Bounds, FFrameSize), P) then
  begin
    Result := sfeFrame;
    for AIndex := High(AIndex) downto Low(AIndex) do
    begin
      if PtInRegion(FElements[AIndex].Handle, P.X, P.Y) then
        Exit(AIndex);
    end;
    if PtInRect(acRectInflate(Bounds, -FFrameSize), P) then
      Exit(sfeClient);    
  end;
end;

procedure TACLSelectionFrame.Draw(DC: HDC; ASelectedElement: TACLSelectionFrameHitTestCode = sfeNone);
var
  AElement: TACLSelectionFrameElement;
  ARegion: HRGN;
  ASaveIndex: Integer;
  AWindowOrg: TPoint;
begin
  ASaveIndex := SaveDC(DC);
  try
    GetWindowOrgEx(DC, AWindowOrg);
    for AElement := Low(AElement) to High(AElement) do
    begin
      ARegion := FElements[AElement].Handle;
      OffsetRgn(ARegion, -AWindowOrg.X, -AWindowOrg.Y);
      SelectClipRgn(DC, ARegion);
      acIntersectClipRegion(DC, Bounds);
      acExcludeFromClipRegion(DC, acRectInflate(Bounds, -FFrameSize));
      if ASelectedElement = AElement then
        acDrawHatch(DC, Bounds, clWhite, clBlack, 1)
      else
        PatBlt(DC, Bounds.Left, Bounds.Top, Bounds.Width, Bounds.Height, PATINVERT);
      OffsetRgn(ARegion, AWindowOrg.X, AWindowOrg.Y);
    end;
  finally
    RestoreDC(DC, ASaveIndex);
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
  FDisplayImageRect := acFitRect(ClientRect, ScaleFactor.Apply(ImageSize.cx), ScaleFactor.Apply(ImageSize.cy), afmFit);

  if not DisplayImageRect.IsEmpty then
  begin
    ARect := acRectScale(FImageCrop, DisplayImageRect.Width / ImageSize.cx).Round;
    ARect := acRectOffset(ARect, FDisplayImageRect.TopLeft);
    FSelection.Calculate(ARect, ScaleFactor);
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
  AOffset: TPoint;
begin
  inherited;
  FIsKeyboardAction := True;
  try
    AOffset := NullPoint;
    case Key of
      VK_LEFT:
        AOffset.X := IfThen(ImageCrop.Left > 0, -1);
      VK_UP:
        AOffset.Y := IfThen(ImageCrop.Top > 0, -1);
      VK_RIGHT:
        AOffset.X := IfThen(ImageCrop.Right < ImageSize.cx, 1);
      VK_DOWN:
        AOffset.Y := IfThen(ImageCrop.Bottom < ImageSize.cy, 1);
    end;
    if (AOffset.X <> 0) or (AOffset.Y <> 0) then
      ImageCrop := acRectOffset(ImageCrop, AOffset)
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
    Cursor := CursorsMap[CalculateDragMode(Shift)];
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
      ARect := TRectF.Create(Max(FDragCaptureRect.Left + dX, 0), FDragCaptureRect.Top, FDragCaptureRect.Right, FDragCaptureRect.Bottom);
    dmResizeTop:
      ARect := TRectF.Create(FDragCaptureRect.Left, Max(FDragCaptureRect.Top + dY, 0), FDragCaptureRect.Right, FDragCaptureRect.Bottom);
    dmResizeRight:
      ARect := TRectF.Create(FDragCaptureRect.Left, FDragCaptureRect.Top, Min(FDragCaptureRect.Right + dX, ImageSize.cx), FDragCaptureRect.Bottom);
    dmResizeBottom:
      ARect := TRectF.Create(FDragCaptureRect.Left, FDragCaptureRect.Top, FDragCaptureRect.Right, Min(FDragCaptureRect.Bottom + dY, ImageSize.cy));

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
        ARect := acRectScale(ARect, ImageSize.cx / DisplayImageRect.Width);
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

function TACLSubImageSelector.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  Result := cbsTransparent;
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
      acFillRect(Canvas.Handle, DisplayImageRect, TAlphaColor.FromColor(clBlack, 160));
    finally
      RestoreDC(Canvas.Handle, ASaveIndex);
    end;
  end;
end;

procedure TACLSubImageSelector.Resize;
begin
  inherited Resize;
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
