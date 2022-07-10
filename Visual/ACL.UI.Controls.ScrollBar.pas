{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             ScrollBar Control             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.ScrollBar;

{$I ACL.Config.Inc}

interface

uses
  Windows, Messages, SysUtils, Classes, Forms, StdCtrls, Controls, Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.UI.Animation,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

const
  acScrollBarHitArea = 120;
  acScrollBarTimerInitialDelay = 400;
  acScrollBarTimerScrollInterval = 60;

type
  TACLScrollBar = class;
  TACLScrollBarViewInfo = class;

  TACLScrollBarPart = (sbpNone, sbpLineUp, sbpLineDown, sbpThumbnail, sbpPageUp, sbpPageDown);

  { IACLScrollBar }

  IACLScrollBar = interface
  ['{1C60D02A-9DA5-41B9-A616-C57075B728F9}']
    function AllowFading: Boolean;
    function CalcCursorPos: TPoint;
    function GetButtonDownSize: Integer;
    function GetButtonUpSize: Integer;
    function GetEnabled: Boolean;
    function GetScrollBarSize: Integer;
    function GetThumbExtends: TRect;
    function GetThumbIsResizable: Boolean;
    function GetThumbNominalSize: Integer;
    function IsMouseCaptured: Boolean;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect);
    procedure DrawPart(ACanvas: TCanvas; const R: TRect; APart: TACLScrollBarPart; AState: TACLButtonState);
    procedure InvalidateRect(const R: TRect; AUpdateNow: Boolean = False);
    procedure Scroll(ACode: TScrollCode; var APosition: Integer);
  end;

  { TACLScrollInfo }

  TACLScrollInfo = packed record
    Max: Integer;
    Min: Integer;
    Page: Integer;
    Position: Integer;

    function CalculateProgressOffset(AValue: Integer): Integer;
  end;

  { TACLStyleScrollBox }

  TACLStyleScrollBox = class(TACLStyle)
  strict private
    function GetTextureBackground(Kind: TScrollBarKind): TACLResourceTexture;
    function GetTextureButtons(Kind: TScrollBarKind): TACLResourceTexture;
    function GetTextureThumb(Kind: TScrollBarKind): TACLResourceTexture;
  protected
    procedure InitializeResources; override;
  public
    procedure DrawBackground(DC: HDC; const R: TRect; Kind: TScrollBarKind);
    procedure DrawPart(DC: HDC; const R: TRect; Part: TACLScrollBarPart; State: TACLButtonState; Kind: TScrollBarKind);
    procedure DrawSizeGripArea(DC: HDC; const R: TRect);
    function IsThumbResizable(AKind: TScrollBarKind): Boolean;
    //
    property TextureBackground[Kind: TScrollBarKind]: TACLResourceTexture read GetTextureBackground;
    property TextureButtons[Kind: TScrollBarKind]: TACLResourceTexture read GetTextureButtons;
    property TextureThumb[Kind: TScrollBarKind]: TACLResourceTexture read GetTextureThumb;
  published
    property TextureBackgroundHorz: TACLResourceTexture index 0 read GetTexture write SetTexture stored IsTextureStored;
    property TextureBackgroundVert: TACLResourceTexture index 1 read GetTexture write SetTexture stored IsTextureStored;
    property TextureButtonsHorz: TACLResourceTexture index 2 read GetTexture write SetTexture stored IsTextureStored;
    property TextureButtonsVert: TACLResourceTexture index 3 read GetTexture write SetTexture stored IsTextureStored;
    property TextureThumbHorz: TACLResourceTexture index 4 read GetTexture write SetTexture stored IsTextureStored;
    property TextureThumbVert: TACLResourceTexture index 5 read GetTexture write SetTexture stored IsTextureStored;
    property TextureSizeGripArea: TACLResourceTexture index 6 read GetTexture write SetTexture stored IsTextureStored;
  end;

  { TACLScrollBarViewItem }

  TACLScrollBarViewInfoItem = class(TACLUnknownObject, IACLAnimateControl)
  strict private
    FBounds: TRect;
    FOwner: TACLScrollBarViewInfo;
    FPart: TACLScrollBarPart;
    FState: TACLButtonState;

    function GetDisplayBounds: TRect;
    procedure SetState(AState: TACLButtonState);
  protected
    procedure FadingPrepare(out AAnimate: TACLBitmapFadingAnimation);
    procedure FadingRun(AAnimate: TACLBitmapFadingAnimation);
    procedure InternalDraw(ABitmap: TACLBitmap); overload;
    procedure InternalDraw(ACanvas: TCanvas; const R: TRect); overload;
    // IACLAnimateControl
    procedure IACLAnimateControl.Animate = Invalidate;
  public
    constructor Create(AOwner: TACLScrollBarViewInfo; APart: TACLScrollBarPart); virtual;
    destructor Destroy; override;
    procedure Draw(ACanvas: TCanvas);
    procedure Invalidate;
    procedure UpdateState;
    //
    property Bounds: TRect read FBounds write FBounds;
    property DisplayBounds: TRect read GetDisplayBounds;
    property Owner: TACLScrollBarViewInfo read FOwner;
    property Part: TACLScrollBarPart read FPart;
    property State: TACLButtonState read FState write SetState;
  end;

  { TACLScrollBarViewInfo }

  TACLScrollBarViewInfo = class(TACLUnknownObject)
  protected
    FBounds: TRect;
    FButtonDown: TACLScrollBarViewInfoItem;
    FButtonUp: TACLScrollBarViewInfoItem;
    FHotPart: TACLScrollBarPart;
    FKind: TScrollBarKind;
    FOwner: IACLScrollBar;
    FPressedPart: TACLScrollBarPart;
    FScrollInfo: TACLScrollInfo;
    FSmallChange: Word;
    FThumbnail: TACLScrollBarViewInfoItem;
    FThumbnailSize: Integer;

    function GetPageDownRect: TRect;
    function GetPageUpRect: TRect;
    procedure SetHotPart(APart: TACLScrollBarPart);
  protected
    function CalculatePositionFromThumbnail(ATotal: Integer): Integer; virtual;
    function CalculateButtonDownRect: TRect; virtual;
    function CalculateButtonUpRect: TRect; virtual;
    function CalculateThumbnailRect: TRect; virtual;
    procedure CalculatePartStates;
    procedure CalculateRects; virtual;
    //
    function InternalSetScrollParams(AMin, AMax, APosition, APageSize: Integer): Boolean;
    procedure Tracking(X, Y: Integer; const ADownMousePos, ASaveThumbnailPos: TPoint); virtual;
    procedure UpdateParts(AHotPart, APressedPart: TACLScrollBarPart);
  public
    constructor Create(AOwner: IACLScrollBar; AKind: TScrollBarKind); virtual;
    destructor Destroy; override;
    function HitTest(const P: TPoint): TACLScrollBarPart; virtual;
    procedure Calculate(const ABounds: TRect); virtual;
    procedure CheckScrollBarSizes(var AWidth, AHeight: Integer); virtual;
    procedure Draw(ACanvas: TCanvas);
    procedure Invalidate(AUpdateNow: Boolean);
    function SetScrollParams(AMin, AMax, APosition, APageSize: Integer; ARedraw: Boolean = True): Boolean; overload;
    procedure SetScrollParams(const AInfo: TScrollInfo; ARedraw: Boolean = True); overload;
    //
    property Bounds: TRect read FBounds;
    property ButtonDown: TACLScrollBarViewInfoItem read FButtonDown;
    property ButtonUp: TACLScrollBarViewInfoItem read FButtonUp;
    property HotPart: TACLScrollBarPart read FHotPart write SetHotPart;
    property Kind: TScrollBarKind read FKind;
    property Owner: IACLScrollBar read FOwner;
    property PageDownRect: TRect read GetPageDownRect;
    property PageUpRect: TRect read GetPageUpRect;
    property PressedPart: TACLScrollBarPart read FPressedPart;
    property ScrollInfo: TACLScrollInfo read FScrollInfo;
    property SmallChange: Word read FSmallChange write FSmallChange default 1;
    property Thumbnail: TACLScrollBarViewInfoItem read FThumbnail;
    property ThumbnailSize: Integer read FThumbnailSize;
  end;

  { TACLScrollBarController }

  TACLScrollBarController = class(TObject)
  strict private
    FDownMousePos: TPoint;
    FSaveThumbnailPos: TPoint;
    FTimer: TACLTimer;
    FViewInfo: TACLScrollBarViewInfo;

    procedure MouseThumbTracking(X, Y: Integer);
    procedure ScrollTimerHandler(ASender: TObject);
  public
    constructor Create(AViewInfo: TACLScrollBarViewInfo); virtual;
    destructor Destroy; override;
    function GetPositionFromThumbnail: Integer;
    procedure Cancel;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
    procedure MouseEnter;
    procedure MouseLeave;
    procedure MouseMove(X, Y: Integer);
    procedure MouseUp(AButton: TMouseButton; X, Y: Integer);
    procedure Scroll(AScrollCode: TScrollCode); overload;
    procedure Scroll(AScrollPart: TACLScrollBarPart); overload;
    //
    property ViewInfo: TACLScrollBarViewInfo read FViewInfo;
  end;

  { TACLScrollBar }

  TACLScrollBar = class(TACLGraphicControl, IACLScrollBar)
  strict private
    FController: TACLScrollBarController;
    FKind: TScrollBarKind;
    FStyle: TACLStyleScrollBox;
    FViewInfo: TACLScrollBarViewInfo;

    FOnScroll: TScrollEvent;

    function GetScrollInfo: TACLScrollInfo;
    function GetSmallChange: Word;
    procedure SetKind(Value: TScrollBarKind);
    procedure SetSmallChange(AValue: Word);
    procedure SetStyle(const Value: TACLStyleScrollBox);
  protected
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    procedure SetTargetDPI(AValue: Integer); override;

    // IACLScrollBar
    function AllowFading: Boolean;
    function GetButtonDownSize: Integer;
    function GetButtonUpSize: Integer;
    function GetScrollBarSize: Integer;
    function GetThumbNominalSize: Integer;
    function GetThumbIsResizable: Boolean;
    function GetThumbExtends: TRect;
    function IsMouseCaptured: Boolean;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect);
    procedure DrawPart(ACanvas: TCanvas; const R: TRect; APart: TACLScrollBarPart; AState: TACLButtonState);
    procedure Scroll(ScrollCode: TScrollCode; var ScrollPos: Integer); virtual;
    //
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    //
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
    procedure CNHScroll(var Message: TWMHScroll); message CN_HSCROLL;
    procedure CNVScroll(var Message: TWMVScroll); message CN_VSCROLL;
    procedure WMCancelMode(var Message: TWMCancelMode); message WM_CANCELMODE;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    //
    property Controller: TACLScrollBarController read FController;
    property ViewInfo: TACLScrollBarViewInfo read FViewInfo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure InvalidateRect(const R: TRect; AUpdateNow: Boolean = False); reintroduce;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure SetScrollParams(AMin, AMax, APosition, APageSize: Integer; ARedraw: Boolean = True); overload;
    procedure SetScrollParams(const AInfo: TScrollInfo; ARedraw: Boolean = True); overload;
    //
    property ScrollInfo: TACLScrollInfo read GetScrollInfo;
  published
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Kind: TScrollBarKind read FKind write SetKind default sbHorizontal;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property SmallChange: Word read GetSmallChange write SetSmallChange default 1;
    property ResourceCollection;
    property Style: TACLStyleScrollBox read FStyle write SetStyle;
    property Visible;
    //
    property OnScroll: TScrollEvent read FOnScroll write FOnScroll;
  end;

implementation

uses
  Types, Consts, Math, ACL.Math;

const
  SCROLL_BAR_MIN_DISTANCE = 34;
  SCROLL_BAR_MAX_DISTANCE = 136;
  SCROLL_BAR_TIMER_PARTS = [sbpLineUp, sbpLineDown, sbpPageUp, sbpPageDown];

  // ScrollBar HitTest
  ssbh_ButtonDown = 1;
  ssbh_ButtonUp   = 2;
  ssbh_Thumb      = 3;

{ TACLScrollInfo }

function TACLScrollInfo.CalculateProgressOffset(AValue: Integer): Integer;
begin
  if (AValue > 0) and (Max <> Min) then
    Result := MulDiv(AValue, Position - Min, Max - Min)
  else
    Result := 0;
end;

{ TACLStyleScrollBox }

procedure TACLStyleScrollBox.DrawBackground(DC: HDC; const R: TRect; Kind: TScrollBarKind);
begin
  TextureBackground[Kind].Draw(DC, R);
end;

procedure TACLStyleScrollBox.DrawPart(DC: HDC; const R: TRect;
  Part: TACLScrollBarPart; State: TACLButtonState; Kind: TScrollBarKind);
begin
  case Part of
    sbpThumbnail:
      TextureThumb[Kind].Draw(DC, R, Ord(State));
    sbpLineUp:
      TextureButtons[Kind].Draw(DC, R, Ord(State));
    sbpLineDown:
      TextureButtons[Kind].Draw(DC, R, Ord(State) + 4);
  end;
end;

procedure TACLStyleScrollBox.DrawSizeGripArea(DC: HDC; const R: TRect);
begin
  if not acRectIsEmpty(R) then
    TextureSizeGripArea.Draw(DC, R);
end;

function TACLStyleScrollBox.IsThumbResizable(AKind: TScrollBarKind): Boolean;
var
  ATexture: TACLResourceTexture;
begin
  if AKind = sbVertical then
    ATexture := TextureThumbVert
  else
    ATexture := TextureThumbHorz;

  Result := not ((ATexture.StretchMode = isCenter) and acMarginIsEmpty(ATexture.Margins));
end;

procedure TACLStyleScrollBox.InitializeResources;
begin
  TextureBackgroundHorz.InitailizeDefaults('ScrollBox.Textures.Horz.Background');
  TextureBackgroundVert.InitailizeDefaults('ScrollBox.Textures.Vert.Background');
  TextureButtonsHorz.InitailizeDefaults('ScrollBox.Textures.Horz.Buttons');
  TextureButtonsVert.InitailizeDefaults('ScrollBox.Textures.Vert.Buttons');
  TextureSizeGripArea.InitailizeDefaults('ScrollBox.Textures.SizeGrip');
  TextureThumbHorz.InitailizeDefaults('ScrollBox.Textures.Horz.Thumb');
  TextureThumbVert.InitailizeDefaults('ScrollBox.Textures.Vert.Thumb');
end;

function TACLStyleScrollBox.GetTextureBackground(Kind: TScrollBarKind): TACLResourceTexture;
begin
  if Kind = sbHorizontal then
    Result := TextureBackgroundHorz
  else
    Result := TextureBackgroundVert;
end;

function TACLStyleScrollBox.GetTextureButtons(Kind: TScrollBarKind): TACLResourceTexture;
begin
  if Kind = sbHorizontal then
    Result := TextureButtonsHorz
  else
    Result := TextureButtonsVert;
end;

function TACLStyleScrollBox.GetTextureThumb(Kind: TScrollBarKind): TACLResourceTexture;
begin
  if Kind = sbHorizontal then
    Result := TextureThumbHorz
  else
    Result := TextureThumbVert;
end;

{ TACLScrollBarViewInfoItem }

constructor TACLScrollBarViewInfoItem.Create(
  AOwner: TACLScrollBarViewInfo; APart: TACLScrollBarPart);
begin
  inherited Create;
  FOwner := AOwner;
  FPart := APart;
end;

destructor TACLScrollBarViewInfoItem.Destroy;
begin
  AnimationManager.RemoveOwner(Self);
  inherited Destroy;
end;

procedure TACLScrollBarViewInfoItem.Draw(ACanvas: TCanvas);
begin
  if not AnimationManager.Draw(Self, ACanvas.Handle, DisplayBounds) then
    InternalDraw(ACanvas, DisplayBounds);
end;

procedure TACLScrollBarViewInfoItem.FadingPrepare(out AAnimate: TACLBitmapFadingAnimation);
begin
  AAnimate := TACLBitmapFadingAnimation.Create(Self, acUIFadingTime);
  InternalDraw(AAnimate.AllocateFrame1(DisplayBounds));
end;

procedure TACLScrollBarViewInfoItem.FadingRun(AAnimate: TACLBitmapFadingAnimation);
begin
  InternalDraw(AAnimate.AllocateFrame2(DisplayBounds));
  AAnimate.Run;
end;

procedure TACLScrollBarViewInfoItem.Invalidate;
begin
  Owner.Owner.InvalidateRect(Bounds);
end;

procedure TACLScrollBarViewInfoItem.InternalDraw(ABitmap: TACLBitmap);
begin
  InternalDraw(ABitmap.Canvas, ABitmap.ClientRect);
end;

procedure TACLScrollBarViewInfoItem.InternalDraw(ACanvas: TCanvas; const R: TRect);
begin
  Owner.Owner.DrawPart(ACanvas, R, Part, State);
end;

procedure TACLScrollBarViewInfoItem.UpdateState;

  function GetPartState(APart: TACLScrollBarPart): TACLButtonState;
  const
    PartHotStateMap: array[Boolean] of TACLButtonState = (absNormal, absHover);
  begin
    if not Owner.Owner.GetEnabled then
      Result := absDisabled
    else
      if Owner.PressedPart = APart then
        Result := absPressed
      else
        Result := PartHotStateMap[Owner.HotPart = APart];
  end;

begin
  State := GetPartState(Part);
end;

function TACLScrollBarViewInfoItem.GetDisplayBounds: TRect;
begin
  Result := Bounds;
  if Part = sbpThumbnail then
    Result := acRectInflate(Result, Owner.Owner.GetThumbExtends);
end;

procedure TACLScrollBarViewInfoItem.SetState(AState: TACLButtonState);
var
  AAnimator: TACLBitmapFadingAnimation;
begin
  if AState <> FState then
  begin
    if (State = absHover) and (AState = absNormal) and Owner.Owner.AllowFading then
    begin
      FadingPrepare(AAnimator);
      FState := AState;
      FadingRun(AAnimator);
    end;
    FState := AState;
    Invalidate;
  end;
end;

{ TACLScrollBarViewInfo }

constructor TACLScrollBarViewInfo.Create(AOwner: IACLScrollBar; AKind: TScrollBarKind);
begin
  inherited Create;
  FKind := AKind;
  FOwner := AOwner;
  FSmallChange := 1;
  FButtonDown := TACLScrollBarViewInfoItem.Create(Self, sbpLineDown);
  FThumbnail := TACLScrollBarViewInfoItem.Create(Self, sbpThumbnail);
  FButtonUp := TACLScrollBarViewInfoItem.Create(Self, sbpLineUp);
  FScrollInfo.Max := 100;
end;

destructor TACLScrollBarViewInfo.Destroy;
begin
  FreeAndNil(FButtonDown);
  FreeAndNil(FThumbnail);
  FreeAndNil(FButtonUp);
  inherited Destroy;
end;

procedure TACLScrollBarViewInfo.Calculate(const ABounds: TRect);
begin
  FBounds := ABounds;
  FThumbnailSize := Owner.GetThumbNominalSize;
  CalculateRects;
  CalculatePartStates;
end;

function TACLScrollBarViewInfo.CalculatePositionFromThumbnail(ATotal: Integer): Integer;
begin
  if Kind = sbHorizontal then
    Result := MulDiv(ATotal, Thumbnail.Bounds.Left - ButtonUp.Bounds.Right,
      ButtonDown.Bounds.Left - ButtonUp.Bounds.Right - acRectWidth(Thumbnail.Bounds))
  else
    Result := MulDiv(ATotal, Thumbnail.Bounds.Top - ButtonUp.Bounds.Bottom,
      ButtonDown.Bounds.Top - ButtonUp.Bounds.Bottom - acRectHeight(Thumbnail.Bounds));
end;

procedure TACLScrollBarViewInfo.CheckScrollBarSizes(var AWidth, AHeight: Integer);
begin
  if Kind = sbHorizontal then
    AHeight := Owner.GetScrollBarSize
  else
    AWidth := Owner.GetScrollBarSize;
end;

procedure TACLScrollBarViewInfo.CalculatePartStates;
begin
  ButtonDown.UpdateState;
  Thumbnail.UpdateState;
  ButtonUp.UpdateState;
end;

procedure TACLScrollBarViewInfo.CalculateRects;
begin
  ButtonDown.Bounds := CalculateButtonDownRect;
  ButtonUp.Bounds := CalculateButtonUpRect;
  Thumbnail.Bounds := CalculateThumbnailRect; // last
end;

function TACLScrollBarViewInfo.CalculateButtonDownRect: TRect;
begin
  if Kind = sbHorizontal then
    Result := acRectSetLeft(Bounds, Owner.GetButtonDownSize)
  else
    Result := acRectSetTop(Bounds, Owner.GetButtonDownSize);
end;

function TACLScrollBarViewInfo.CalculateButtonUpRect: TRect;
begin
  if Kind = sbHorizontal then
    Result := acRectSetWidth(Bounds, Owner.GetButtonUpSize)
  else
    Result := acRectSetHeight(Bounds, Owner.GetButtonUpSize);
end;

function TACLScrollBarViewInfo.CalculateThumbnailRect: TRect;
var
  ADelta, ASize, ATempValue: Integer;
begin
  Result := NullRect;
  if Owner.GetEnabled then
  begin
    if Kind = sbHorizontal then
    begin
      ADelta := ButtonDown.Bounds.Left - ButtonUp.Bounds.Right;
      if ScrollInfo.Page = 0 then
      begin
        ASize := Owner.GetThumbNominalSize;
        if ASize > ADelta then Exit;
        Dec(ADelta, ASize);
        ATempValue := ButtonUp.Bounds.Right + ScrollInfo.CalculateProgressOffset(ADelta);
        Result := Rect(ATempValue, Bounds.Top, ATempValue + ASize, Bounds.Bottom);
      end
      else
      begin
        ASize := Min(ADelta, MulDiv(ScrollInfo.Page, ADelta, ScrollInfo.Max - ScrollInfo.Min + 1));
        if (ADelta < FThumbnailSize) or (ScrollInfo.Max = ScrollInfo.Min) then Exit;
        ASize := Max(FThumbnailSize, ASize);
        Dec(ADelta, ASize);
        Result := Classes.Bounds(ButtonUp.Bounds.Right, Bounds.Top, ASize, acRectHeight(Bounds));
        ASize := (ScrollInfo.Max - ScrollInfo.Min) - (ScrollInfo.Page - 1);
        OffsetRect(Result, MulDiv(ADelta, Min(ScrollInfo.Position - ScrollInfo.Min, ASize), ASize), 0);
      end;
    end
    else
    begin
      ADelta := ButtonDown.Bounds.Top - ButtonUp.Bounds.Bottom;
      if ScrollInfo.Page = 0 then
      begin
        ASize := Owner.GetThumbNominalSize;
        if ASize > ADelta then Exit;
        Dec(ADelta, ASize);
        ATempValue := ButtonUp.Bounds.Bottom + ScrollInfo.CalculateProgressOffset(ADelta);
        Result := Rect(Bounds.Left, ATempValue, Bounds.Right, ATempValue + ASize)
      end
      else
      begin
        ASize := Min(ADelta, MulDiv(ScrollInfo.Page, ADelta, ScrollInfo.Max - ScrollInfo.Min + 1));
        if (ADelta < FThumbnailSize) or (ScrollInfo.Max = ScrollInfo.Min) then Exit;
        ASize := Max(ASize, FThumbnailSize);
        Dec(ADelta, ASize);
        Result := Classes.Bounds(Bounds.Left, ButtonUp.Bounds.Bottom, acRectWidth(Bounds), ASize);
        ASize := (ScrollInfo.Max - ScrollInfo.Min) - (ScrollInfo.Page - 1);
        OffsetRect(Result, 0, MulDiv(ADelta, Min(ScrollInfo.Position - ScrollInfo.Min, ASize), ASize));
      end;
    end;
  end;
end;

procedure TACLScrollBarViewInfo.Draw(ACanvas: TCanvas);
begin
  Owner.DrawBackground(ACanvas, Bounds);
  ButtonUp.Draw(ACanvas);
  ButtonDown.Draw(ACanvas);
  Thumbnail.Draw(ACanvas);
end;

procedure TACLScrollBarViewInfo.Invalidate(AUpdateNow: Boolean);
begin
  Owner.InvalidateRect(Bounds, AUpdateNow);
end;

function TACLScrollBarViewInfo.InternalSetScrollParams(AMin, AMax, APosition, APageSize: Integer): Boolean;
begin
  Result := (ScrollInfo.Min <> AMin) or (ScrollInfo.Max <> AMax) or
    (ScrollInfo.Page <> APageSize) or (ScrollInfo.Position <> APosition);
  FScrollInfo.Page := APageSize;
  FScrollInfo.Min := AMin;
  FScrollInfo.Max := AMax;
end;

function TACLScrollBarViewInfo.SetScrollParams(AMin, AMax, APosition, APageSize: Integer; ARedraw: Boolean = True): Boolean;
begin
  if not Owner.GetThumbIsResizable then
  begin
    if APageSize > 1 then
      Dec(AMax, APageSize);
    APageSize := 0;
  end;
  AMax := Max(AMax, AMin);
  APageSize := Min(APageSize, AMax - AMin);

  APosition := MinMax(APosition, AMin, AMax - APageSize + 1);
  ARedraw := ARedraw and InternalSetScrollParams(AMin, AMax, APosition, APageSize);
  Result := ScrollInfo.Position <> APosition;
  FScrollInfo.Position := APosition;
  Calculate(Bounds);

  if ARedraw then
    Invalidate(PressedPart = sbpThumbnail);
end;

procedure TACLScrollBarViewInfo.SetScrollParams(const AInfo: TScrollInfo; ARedraw: Boolean);
begin
  SetScrollParams(AInfo.nMin, AInfo.nMax, AInfo.nPos, AInfo.nPage, ARedraw);
end;

function TACLScrollBarViewInfo.HitTest(const P: TPoint): TACLScrollBarPart;
begin
  if PtInRect(Thumbnail.DisplayBounds, P) then // first
    Result := sbpThumbnail
  else

  if PtInRect(ButtonUp.DisplayBounds, P) then
    Result := sbpLineUp
  else

  if PtInRect(ButtonDown.DisplayBounds, P) then
    Result := sbpLineDown
  else

  if PtInRect(PageUpRect, P) then
    Result := sbpPageUp
  else

  if PtInRect(PageDownRect, P) then
    Result := sbpPageDown
  else
    Result := sbpNone;
end;

procedure TACLScrollBarViewInfo.Tracking(X, Y: Integer; const ADownMousePos, ASaveThumbnailPos: TPoint);
var
  ADelta, ASize: Integer;
begin
  if not PtInRect(acRectInflate(Bounds, acScrollBarHitArea), Point(X, Y)) then
  begin
    Thumbnail.Bounds := acRectSetPos(Thumbnail.Bounds, ASaveThumbnailPos);
    Exit;
  end;

  if Kind = sbHorizontal then
  begin
    ADelta := X - ADownMousePos.X;
    if ADelta <> 0 then
    begin
      ASize := acRectWidth(Thumbnail.Bounds);
      if (ADelta < 0) and (ASaveThumbnailPos.X + ADelta < ButtonUp.Bounds.Right) then
        ADelta := ButtonUp.Bounds.Right - ASaveThumbnailPos.X;
      if (ADelta > 0) and (ASaveThumbnailPos.X + ASize + ADelta > ButtonDown.Bounds.Left) then
        ADelta := ButtonDown.Bounds.Left - (ASaveThumbnailPos.X + ASize);
      Thumbnail.Bounds := acRectOffset(Thumbnail.Bounds, -Thumbnail.Bounds.Left + ASaveThumbnailPos.X + ADelta, 0)
    end
  end
  else
  begin
    ADelta := Y - ADownMousePos.Y;
    if ADelta <> 0 then
    begin
      ASize := acRectHeight(Thumbnail.Bounds);
      if (ADelta < 0) and (ASaveThumbnailPos.Y + ADelta < ButtonUp.Bounds.Bottom) then
        ADelta := ButtonUp.Bounds.Bottom - ASaveThumbnailPos.Y;
      if (ADelta > 0) and (ASaveThumbnailPos.Y + ASize + ADelta > ButtonDown.Bounds.Top) then
        ADelta := ButtonDown.Bounds.Top - (ASaveThumbnailPos.Y + ASize);
      Thumbnail.Bounds := acRectOffset(Thumbnail.Bounds, 0, -Thumbnail.Bounds.Top + ASaveThumbnailPos.Y + ADelta);
    end;
  end;
end;

procedure TACLScrollBarViewInfo.UpdateParts(AHotPart, APressedPart: TACLScrollBarPart);
begin
  if (AHotPart <> FHotPart) or (APressedPart <> FPressedPart) then
  begin
    FPressedPart := APressedPart;
    FHotPart := AHotPart;
    CalculatePartStates;
  end;
end;

function TACLScrollBarViewInfo.GetPageDownRect: TRect;
begin
  if acRectIsEmpty(Thumbnail.Bounds) then
    Result := NullRect
  else
    if Kind = sbHorizontal then
      Result := Rect(Thumbnail.Bounds.Right, Bounds.Top, ButtonDown.Bounds.Left, Bounds.Bottom)
    else
      Result := Rect(Bounds.Left, Thumbnail.Bounds.Bottom, Bounds.Right, ButtonDown.Bounds.Top);
end;

function TACLScrollBarViewInfo.GetPageUpRect: TRect;
begin
  if acRectIsEmpty(Thumbnail.Bounds) then
    Result := NullRect
  else
    if Kind = sbHorizontal then
      Result := Rect(ButtonUp.Bounds.Right, Bounds.Top, Thumbnail.Bounds.Left, Bounds.Bottom)
    else
      Result := Rect(Bounds.Left, ButtonUp.Bounds.Bottom, Bounds.Right, Thumbnail.Bounds.Top);
end;

procedure TACLScrollBarViewInfo.SetHotPart(APart: TACLScrollBarPart);
begin
  UpdateParts(APart, PressedPart);
end;

{ TACLScrollBarController }

constructor TACLScrollBarController.Create(AViewInfo: TACLScrollBarViewInfo);
begin
  inherited Create;
  FViewInfo := AViewInfo;
  FTimer := TACLTimer.CreateEx(ScrollTimerHandler, acScrollBarTimerInitialDelay, False);
end;

destructor TACLScrollBarController.Destroy;
begin
  FreeAndNil(FTimer);
  inherited Destroy;
end;

procedure TACLScrollBarController.Cancel;
begin
  if ViewInfo.PressedPart <> sbpNone then
  begin
    FTimer.Enabled := False;
    if ViewInfo.PressedPart = sbpThumbnail then
    begin
      ViewInfo.FScrollInfo.Position := GetPositionFromThumbnail;
      Scroll(scPosition);
    end;
    ViewInfo.UpdateParts(sbpNone, sbpNone);
    Scroll(scEndScroll);
    ViewInfo.CalculateRects;
    ViewInfo.Invalidate(False);
  end;
end;

procedure TACLScrollBarController.MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
var
  APart: TACLScrollBarPart;
begin
  if AButton = mbMiddle then
  begin
    Include(AShift, ssShift);
    AButton := mbLeft;
  end;

  if AButton = mbLeft then
  begin
    APart := ViewInfo.HitTest(Point(X, Y));
    if APart <> sbpNone then
    begin
      if APart = sbpThumbnail then
      begin
        FDownMousePos := Point(X, Y);
        FSaveThumbnailPos := ViewInfo.Thumbnail.Bounds.TopLeft;
        Scroll(scTrack);
      end;
      if APart in SCROLL_BAR_TIMER_PARTS then
      begin
        if ssShift in AShift then
        begin
          FSaveThumbnailPos := ViewInfo.Thumbnail.Bounds.TopLeft;
          FDownMousePos := acRectCenter(ViewInfo.Thumbnail.Bounds);
          Scroll(scTrack);
          MouseThumbTracking(X, Y);
          APart := sbpThumbnail;
        end
        else
        begin
          Scroll(APart);
          FTimer.Interval := acScrollBarTimerInitialDelay;
          FTimer.Enabled := True;
        end;
      end;
      ViewInfo.UpdateParts(APart, APart);
      ViewInfo.Invalidate(True);
    end;
  end;
end;

procedure TACLScrollBarController.MouseEnter;
begin
  ViewInfo.Owner.InvalidateRect(ViewInfo.Bounds);
end;

procedure TACLScrollBarController.MouseLeave;
begin
  if ViewInfo.PressedPart <> sbpThumbnail then
    ViewInfo.HotPart := sbpNone;
end;

procedure TACLScrollBarController.MouseMove(X, Y: Integer);
var
  APart: TACLScrollBarPart;
begin
  if ViewInfo.PressedPart = sbpThumbnail then
    MouseThumbTracking(X, Y)
  else
  begin
    APart := ViewInfo.HitTest(Point(X, Y));
    if ViewInfo.PressedPart <> sbpNone then
      FTimer.Enabled := ViewInfo.PressedPart = APart;
    ViewInfo.HotPart := APart;
  end;
end;

procedure TACLScrollBarController.MouseUp(AButton: TMouseButton; X, Y: Integer);
begin
  Cancel;
  ViewInfo.HotPart := ViewInfo.HitTest(Point(X, Y));
end;

procedure TACLScrollBarController.Scroll(AScrollCode: TScrollCode);
var
  ANewPos: Integer;
begin
  ANewPos := ViewInfo.ScrollInfo.Position;
  case AScrollCode of
    scLineUp:
      Dec(ANewPos, ViewInfo.SmallChange);
    scLineDown:
      Inc(ANewPos, ViewInfo.SmallChange);
    scPageUp:
      Dec(ANewPos, Math.Max(ViewInfo.SmallChange, ViewInfo.ScrollInfo.Page));
    scPageDown:
      Inc(ANewPos, Math.Max(ViewInfo.SmallChange, ViewInfo.ScrollInfo.Page));
    scTop:
      ANewPos := ViewInfo.ScrollInfo.Min;
    scBottom:
      ANewPos := ViewInfo.ScrollInfo.Max;
  end;
  ANewPos := MinMax(ANewPos, ViewInfo.ScrollInfo.Min, ViewInfo.ScrollInfo.Max);
  ViewInfo.Owner.Scroll(AScrollCode, ANewPos);
  ANewPos := MinMax(ANewPos, ViewInfo.ScrollInfo.Min, ViewInfo.ScrollInfo.Max);
  if ANewPos <> ViewInfo.ScrollInfo.Position then
  begin
    if AScrollCode = scTrack then
    begin
      ViewInfo.FScrollInfo.Position := ANewPos;
      ViewInfo.Invalidate(False);
    end
    else
      ViewInfo.SetScrollParams(ViewInfo.ScrollInfo.Min, ViewInfo.ScrollInfo.Max, ANewPos, ViewInfo.ScrollInfo.Page);
  end;
end;

procedure TACLScrollBarController.Scroll(AScrollPart: TACLScrollBarPart);
const
  ScrollCodeMap: array[TACLScrollBarPart] of TScrollCode = (
    scLineUp, scLineUp, scLineDown, scTrack, scPageUp, scPageDown
  );
begin
  if AScrollPart <> sbpNone then
    Scroll(ScrollCodeMap[AScrollPart]);
end;

procedure TACLScrollBarController.MouseThumbTracking(X, Y: Integer);
var
  ANewPos: Integer;
begin
  ViewInfo.Tracking(X, Y, FDownMousePos, FSaveThumbnailPos);
  ANewPos := GetPositionFromThumbnail;
  if ANewPos <> ViewInfo.ScrollInfo.Position then
  begin
    ViewInfo.FScrollInfo.Position := ANewPos;
    Scroll(sbpThumbnail);
  end;
  ViewInfo.Invalidate(False);
end;

procedure TACLScrollBarController.ScrollTimerHandler(ASender: TObject);
begin
  if ViewInfo.Owner.IsMouseCaptured and (ViewInfo.PressedPart in SCROLL_BAR_TIMER_PARTS) then
  begin
    FTimer.Interval := acScrollBarTimerScrollInterval;
    FTimer.Enabled := ViewInfo.HitTest(ViewInfo.Owner.CalcCursorPos) = ViewInfo.PressedPart;
    if FTimer.Enabled then
      Scroll(ViewInfo.PressedPart);
  end
  else
    Cancel;
end;

function TACLScrollBarController.GetPositionFromThumbnail: Integer;
begin
  Result := ViewInfo.ScrollInfo.Min + ViewInfo.CalculatePositionFromThumbnail(
    ViewInfo.ScrollInfo.Max - ViewInfo.ScrollInfo.Min +
    IfThen(ViewInfo.ScrollInfo.Page > 0, - ViewInfo.ScrollInfo.Page + 1));
end;

{ TACLScrollBar }

constructor TACLScrollBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csOpaque, csCaptureMouse];
  FKind := sbHorizontal;
  FViewInfo := TACLScrollBarViewInfo.Create(Self, Kind);
  FController := TACLScrollBarController.Create(ViewInfo);
  FStyle := TACLStyleScrollBox.Create(Self);
end;

destructor TACLScrollBar.Destroy;
begin
  FreeAndNil(FStyle);
  FreeAndNil(FViewInfo);
  FreeAndNil(FController);
  inherited Destroy;
end;

procedure TACLScrollBar.DrawPart(ACanvas: TCanvas; const R: TRect; APart: TACLScrollBarPart; AState: TACLButtonState);
begin
  Style.DrawPart(ACanvas.Handle, R, APart, AState, Kind);
end;

procedure TACLScrollBar.Paint;
begin
  ViewInfo.Draw(Canvas);
end;

procedure TACLScrollBar.InvalidateRect(const R: TRect; AUpdateNow: Boolean = False);
begin
  inherited InvalidateRect(R);
  if AUpdateNow then
    Update;
end;

function TACLScrollBar.IsMouseCaptured: Boolean;
begin
  Result := GetCaptureControl = Self;
end;

procedure TACLScrollBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  Controller.MouseDown(Button, Shift, X, Y);
end;

procedure TACLScrollBar.MouseEnter;
begin
  inherited MouseEnter;
  Controller.MouseEnter;
end;

procedure TACLScrollBar.MouseLeave;
begin
  Controller.MouseLeave;
  inherited MouseLeave;
end;

procedure TACLScrollBar.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  Controller.MouseMove(X, Y);
end;

procedure TACLScrollBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  Controller.MouseUp(Button, X, Y);
end;

procedure TACLScrollBar.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.DrawBackground(ACanvas.Handle, R, Kind);
end;

procedure TACLScrollBar.Scroll(ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  if Assigned(OnScroll) then OnScroll(Self, ScrollCode, ScrollPos);
end;

procedure TACLScrollBar.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  ViewInfo.Calculate(ClientRect);
  if not Enabled then
    Controller.Cancel;
  Invalidate;
end;

procedure TACLScrollBar.CNHScroll(var Message: TWMHScroll);
begin
  Controller.Scroll(TScrollCode(Message.ScrollCode));
end;

procedure TACLScrollBar.CMVisibleChanged(var Message: TMessage);
begin
  if not Visible then
    Controller.Cancel;
  inherited;
end;

procedure TACLScrollBar.CNVScroll(var Message: TWMVScroll);
begin
  Controller.Scroll(TScrollCode(Message.ScrollCode));
end;

procedure TACLScrollBar.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TACLScrollBar.WMCancelMode(var Message: TWMCancelMode);
begin
  Controller.Cancel;
  inherited;
end;

procedure TACLScrollBar.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Style.SetTargetDPI(AValue);
end;

procedure TACLScrollBar.AfterConstruction;
begin
  SetBounds(Left, Top, 200, 20);
end;

function TACLScrollBar.AllowFading: Boolean;
begin
  Result := acUIFadingEnabled;
end;

function TACLScrollBar.GetButtonDownSize: Integer;
begin
  Result := GetButtonUpSize;
end;

function TACLScrollBar.GetButtonUpSize: Integer;
begin
  if Kind = sbHorizontal then
    Result := Style.TextureButtonsHorz.FrameWidth
  else
    Result := Style.TextureButtonsVert.FrameHeight;
end;

function TACLScrollBar.GetScrollBarSize: Integer;
begin
  if Kind = sbHorizontal then
    Result := Style.TextureBackgroundHorz.FrameHeight
  else
    Result := Style.TextureBackgroundVert.FrameWidth;
end;

function TACLScrollBar.GetScrollInfo: TACLScrollInfo;
begin
  Result := ViewInfo.ScrollInfo;
end;

function TACLScrollBar.GetSmallChange: Word;
begin
  Result := ViewInfo.SmallChange;
end;

function TACLScrollBar.GetThumbNominalSize: Integer;
begin
  if Kind = sbHorizontal then
    Result := Style.TextureThumbHorz.FrameWidth
  else
    Result := Style.TextureThumbVert.FrameHeight;
end;

function TACLScrollBar.GetThumbIsResizable: Boolean;
begin
  Result := Style.IsThumbResizable(Kind);
end;

function TACLScrollBar.GetThumbExtends: TRect;
begin
  Result := NullRect;
end;

procedure TACLScrollBar.SetScrollParams(AMin, AMax, APosition, APageSize: Integer; ARedraw: Boolean = True);
begin
  ViewInfo.SetScrollParams(AMin, AMax, APosition, APageSize, ARedraw);
end;

procedure TACLScrollBar.SetScrollParams(const AInfo: TScrollInfo; ARedraw: Boolean = True);
begin
  SetScrollParams(AInfo.nMin, AInfo.nMax, AInfo.nPos, AInfo.nPage, ARedraw);
end;

procedure TACLScrollBar.SetSmallChange(AValue: Word);
begin
  ViewInfo.SmallChange := Max(AValue, 1);
end;

procedure TACLScrollBar.SetKind(Value: TScrollBarKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    ViewInfo.FKind := Value;
    UpdateTransparency;
    AdjustSize;
  end;
end;

procedure TACLScrollBar.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if not IsLoading then
    ViewInfo.CheckScrollBarSizes(AWidth, AHeight);
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  ViewInfo.Calculate(ClientRect);
end;

function TACLScrollBar.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if Style.TextureBackground[Kind].HasAlpha then
    Result := cbsSemitransparent
  else
    Result := cbsOpaque;
end;

procedure TACLScrollBar.SetStyle(const Value: TACLStyleScrollBox);
begin
  FStyle.Assign(Value);
end;

end.
