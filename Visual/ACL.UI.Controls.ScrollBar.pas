{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             ScrollBar Control             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.ScrollBar;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
  {Vcl.}StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.Math,
  ACL.Timers,
  ACL.UI.Animation,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Desktop;

const
  acScrollBarHitArea = 120;
  acScrollBarTimerInitialDelay = 400;
  acScrollBarTimerScrollInterval = 60;

type
  TACLScrollBar = class;
  TACLScrollBarSubClass = class;

  TACLScrollBarPart = (sbpNone, sbpLineUp, sbpLineDown, sbpThumbnail, sbpPageUp, sbpPageDown);

  { IACLScrollBarAppearance }

  IACLScrollBarAppearance = interface
  ['{2B8F4E80-397B-434C-82F6-F163FCA18CD7}']
    function GetButtonDownSize(Kind: TScrollBarKind): Integer;
    function GetButtonUpSize(Kind: TScrollBarKind): Integer;
    function GetScrollBarSize(Kind: TScrollBarKind): Integer;
    function GetThumbExtends(Kind: TScrollBarKind): TRect;
    function GetThumbNominalSize(Kind: TScrollBarKind): Integer;
    function IsThumbResizable(Kind: TScrollBarKind): Boolean;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect; Kind: TScrollBarKind);
    procedure DrawPart(ACanvas: TCanvas; const R: TRect;
      APart: TACLScrollBarPart; AState: TACLButtonState; AKind: TScrollBarKind);
  end;

  { IACLScrollBar }

  IACLScrollBar = interface(IACLControl)
  ['{1C60D02A-9DA5-41B9-A616-C57075B728F9}']
    function AllowFading: Boolean;
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

  TACLStyleScrollBox = class(TACLStyle, IACLScrollBarAppearance)
  strict private
    function GetTextureBackground(Kind: TScrollBarKind): TACLResourceTexture;
    function GetTextureButtons(Kind: TScrollBarKind): TACLResourceTexture;
    function GetTextureThumb(Kind: TScrollBarKind): TACLResourceTexture;
  protected
    procedure InitializeResources; override;
    // IACLScrollBarAppearance
    function GetButtonDownSize(Kind: TScrollBarKind): Integer;
    function GetButtonUpSize(Kind: TScrollBarKind): Integer;
    function GetThumbExtends(Kind: TScrollBarKind): TRect;
    function GetThumbNominalSize(Kind: TScrollBarKind): Integer;
  public
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect; Kind: TScrollBarKind);
    procedure DrawPart(ACanvas: TCanvas; const R: TRect;
      Part: TACLScrollBarPart; State: TACLButtonState; Kind: TScrollBarKind);
    procedure DrawSizeGripArea(ACanvas: TCanvas; const R: TRect);
    function GetScrollBarSize(Kind: TScrollBarKind): Integer;
    function IsThumbResizable(AKind: TScrollBarKind): Boolean;
    //# Properties
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
    FOwner: TACLScrollBarSubClass;
    FPart: TACLScrollBarPart;
    FState: TACLButtonState;

    function GetDisplayBounds: TRect;
    procedure SetState(AState: TACLButtonState);
  protected
    procedure InternalDraw(ACanvas: TCanvas; const R: TRect);
    // IACLAnimateControl
    procedure IACLAnimateControl.Animate = Invalidate;
  public
    constructor Create(AOwner: TACLScrollBarSubClass; APart: TACLScrollBarPart); virtual;
    destructor Destroy; override;
    procedure Draw(ACanvas: TCanvas);
    procedure Invalidate;
    procedure UpdateState;
    //# Properties
    property Bounds: TRect read FBounds write FBounds;
    property DisplayBounds: TRect read GetDisplayBounds;
    property Owner: TACLScrollBarSubClass read FOwner;
    property Part: TACLScrollBarPart read FPart;
    property State: TACLButtonState read FState write SetState;
  end;

  { TACLScrollBarSubClass }

  TACLScrollBarSubClass = class(TACLUnknownObject)
  strict private
    FBounds: TRect;
    FButtonDown: TACLScrollBarViewInfoItem;
    FButtonUp: TACLScrollBarViewInfoItem;
    FHotPart: TACLScrollBarPart;
    FKind: TScrollBarKind;
    FOwner: IACLScrollBar;
    FPressedMousePos: TPoint;
    FPressedPart: TACLScrollBarPart;
    FSaveThumbnailPos: TPoint;
    FScrollInfo: TACLScrollInfo;
    FSmallChange: Word;
    FStyle: IACLScrollBarAppearance;
    FThumbnail: TACLScrollBarViewInfoItem;
    FThumbnailSize: Integer;
    FTimer: TACLTimer;

    function CalculateButtonDownRect: TRect;
    function CalculateButtonUpRect: TRect;
    procedure CalculatePartStates;
    function CalculatePositionFromThumbnail(ATotal: Integer): Integer;
    procedure CalculateRects;
    function CalculateThumbnailRect: TRect;
    function GetPageDownRect: TRect;
    function GetPageUpRect: TRect;
    function GetPositionFromThumbnail: Integer;
    procedure MouseThumbTracking(X, Y: Integer);
    procedure ScrollTimerHandler(ASender: TObject);
    procedure SetHotPart(APart: TACLScrollBarPart);
    procedure UpdateParts(AHotPart, APressedPart: TACLScrollBarPart);
  public
    constructor Create(AOwner: IACLScrollBar;
      AStyle: IACLScrollBarAppearance; AKind: TScrollBarKind);
    destructor Destroy; override;
    procedure Calculate(const ABounds: TRect);
    procedure CheckScrollBarSizes(var AWidth, AHeight: Integer);
    procedure Draw(ACanvas: TCanvas);
    procedure Invalidate(AUpdateNow: Boolean);
    function HitTest(const P: TPoint): TACLScrollBarPart;
    //# Controller
    procedure CancelDrag;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
    procedure MouseEnter;
    procedure MouseLeave;
    procedure MouseMove(X, Y: Integer);
    procedure MouseUp(AButton: TMouseButton; X, Y: Integer);
    procedure Scroll(AScrollCode: TScrollCode); overload;
    procedure Scroll(AScrollPart: TACLScrollBarPart); overload;
    function SetScrollParams(AMin, AMax, APosition, APageSize: Integer;
      ARedraw: Boolean = True): Boolean;
    //# Properties
    property Bounds: TRect read FBounds;
    property ButtonDown: TACLScrollBarViewInfoItem read FButtonDown;
    property ButtonUp: TACLScrollBarViewInfoItem read FButtonUp;
    property HotPart: TACLScrollBarPart read FHotPart write SetHotPart;
    property Kind: TScrollBarKind read FKind write FKind;
    property Owner: IACLScrollBar read FOwner;
    property PageDownRect: TRect read GetPageDownRect;
    property PageUpRect: TRect read GetPageUpRect;
    property PressedPart: TACLScrollBarPart read FPressedPart;
    property ScrollInfo: TACLScrollInfo read FScrollInfo;
    property SmallChange: Word read FSmallChange write FSmallChange default 1;
    property Style: IACLScrollBarAppearance read FStyle;
    property Thumbnail: TACLScrollBarViewInfoItem read FThumbnail;
    property ThumbnailSize: Integer read FThumbnailSize;
  end;

  { TACLScrollBar }

  TACLScrollBar = class(TACLGraphicControl, IACLScrollBar)
  strict private
    FStyle: TACLStyleScrollBox;
    FSubClass: TACLScrollBarSubClass;

    FOnScroll: TScrollEvent;

    function GetKind: TScrollBarKind;
    function GetScrollInfo: TACLScrollInfo;
    function GetSmallChange: Word;
    procedure SetKind(Value: TScrollBarKind);
    procedure SetSmallChange(AValue: Word);
    procedure SetStyle(const Value: TACLStyleScrollBox);
  protected
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateTransparency; override;

    // IACLScrollBar
    function AllowFading: Boolean;
    procedure Scroll(ScrollCode: TScrollCode; var ScrollPos: Integer); virtual;

    //# Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    //# Paint
    procedure Paint; override;

    //# Messages
    procedure CMCancelMode(var Message: TCMCancelMode); message CM_CANCELMODE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
    procedure CNHScroll(var Message: TWMHScroll); message CN_HSCROLL;
    procedure CNVScroll(var Message: TWMVScroll); message CN_VSCROLL;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;

    //# Properties
    property SubClass: TACLScrollBarSubClass read FSubClass;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure SetScrollParams(AMin, AMax, APosition, APageSize: Integer; ARedraw: Boolean = True); overload;
    procedure SetScrollParams(const AInfo: TScrollInfo; ARedraw: Boolean = True); overload;
    //# Properties
    property ScrollInfo: TACLScrollInfo read GetScrollInfo;
  published
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Kind: TScrollBarKind read GetKind write SetKind default sbHorizontal;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property SmallChange: Word read GetSmallChange write SetSmallChange default 1;
    property ResourceCollection;
    property Style: TACLStyleScrollBox read FStyle write SetStyle;
    property Visible;
    //# Events
    property OnScroll: TScrollEvent read FOnScroll write FOnScroll;
  end;

implementation

{$IFNDEF FPC}
uses
  ACL.Graphics.SkinImageSet;
{$ENDIF}

const
  SCROLL_BAR_TIMER_PARTS = [sbpLineUp, sbpLineDown, sbpPageUp, sbpPageDown];

{ TACLScrollInfo }

function TACLScrollInfo.CalculateProgressOffset(AValue: Integer): Integer;
begin
  if (AValue > 0) and (Max <> Min) then
    Result := MulDiv(AValue, Position - Min, Max - Min)
  else
    Result := 0;
end;

{ TACLStyleScrollBox }

procedure TACLStyleScrollBox.DrawBackground(
  ACanvas: TCanvas; const R: TRect; Kind: TScrollBarKind);
begin
  TextureBackground[Kind].Draw(ACanvas, R);
end;

procedure TACLStyleScrollBox.DrawPart(ACanvas: TCanvas; const R: TRect;
  Part: TACLScrollBarPart; State: TACLButtonState; Kind: TScrollBarKind);
begin
  case Part of
    sbpThumbnail:
      TextureThumb[Kind].Draw(ACanvas, R, Ord(State));
    sbpLineUp:
      TextureButtons[Kind].Draw(ACanvas, R, Ord(State));
    sbpLineDown:
      TextureButtons[Kind].Draw(ACanvas, R, Ord(State) + 4);
  else;
  end;
end;

procedure TACLStyleScrollBox.DrawSizeGripArea(ACanvas: TCanvas; const R: TRect);
begin
  TextureSizeGripArea.Draw(ACanvas, R);
end;

function TACLStyleScrollBox.IsThumbResizable(AKind: TScrollBarKind): Boolean;
var
  ATexture: TACLResourceTexture;
begin
  if AKind = sbVertical then
    ATexture := TextureThumbVert
  else
    ATexture := TextureThumbHorz;

  Result := not ((ATexture.StretchMode = isCenter) and ATexture.Margins.IsZero);
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

function TACLStyleScrollBox.GetButtonDownSize(Kind: TScrollBarKind): Integer;
begin
  if Kind = sbHorizontal then
    Result := TextureButtonsHorz.FrameWidth
  else
    Result := TextureButtonsVert.FrameHeight;
end;

function TACLStyleScrollBox.GetButtonUpSize(Kind: TScrollBarKind): Integer;
begin
  Result := GetButtonDownSize(Kind);
end;

function TACLStyleScrollBox.GetScrollBarSize(Kind: TScrollBarKind): Integer;
begin
  if Kind = sbHorizontal then
    Result := TextureBackgroundHorz.FrameHeight
  else
    Result := TextureBackgroundVert.FrameWidth;
end;

function TACLStyleScrollBox.GetThumbExtends(Kind: TScrollBarKind): TRect;
begin
  Result := NullRect;
end;

function TACLStyleScrollBox.GetThumbNominalSize(Kind: TScrollBarKind): Integer;
begin
  if Kind = sbHorizontal then
    Result := TextureThumbHorz.FrameWidth
  else
    Result := TextureThumbVert.FrameHeight;
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
  AOwner: TACLScrollBarSubClass; APart: TACLScrollBarPart);
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
  if not AnimationManager.Draw(Self, ACanvas, DisplayBounds) then
    InternalDraw(ACanvas, DisplayBounds);
end;

procedure TACLScrollBarViewInfoItem.Invalidate;
begin
  Owner.Owner.InvalidateRect(Bounds);
end;

procedure TACLScrollBarViewInfoItem.InternalDraw(ACanvas: TCanvas; const R: TRect);
begin
  Owner.Style.DrawPart(ACanvas, R, Part, State, Owner.Kind);
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
    Result.Inflate(Owner.Style.GetThumbExtends(Owner.Kind));
end;

procedure TACLScrollBarViewInfoItem.SetState(AState: TACLButtonState);
var
  AAnimator: TACLBitmapFadingAnimation;
begin
  if AState <> FState then
  begin
    if (State = absHover) and (AState = absNormal) and Owner.Owner.AllowFading then
    begin
      AAnimator := TACLBitmapFadingAnimation.Create(Self, acUIFadingTime);
      AAnimator.AllocateFrame1(DisplayBounds, InternalDraw);
      FState := AState;
      AAnimator.AllocateFrame2(DisplayBounds, InternalDraw);
      AAnimator.Run;
    end;
    FState := AState;
    Invalidate;
  end;
end;

{ TACLScrollBarSubClass }

constructor TACLScrollBarSubClass.Create(AOwner: IACLScrollBar;
  AStyle: IACLScrollBarAppearance; AKind: TScrollBarKind);
begin
  inherited Create;
  FKind := AKind;
  FOwner := AOwner;
  FStyle := AStyle;
  FSmallChange := 1;
  FScrollInfo.Max := 100;
  FButtonDown := TACLScrollBarViewInfoItem.Create(Self, sbpLineDown);
  FThumbnail := TACLScrollBarViewInfoItem.Create(Self, sbpThumbnail);
  FButtonUp := TACLScrollBarViewInfoItem.Create(Self, sbpLineUp);
  FTimer := TACLTimer.CreateEx(ScrollTimerHandler, acScrollBarTimerInitialDelay, False);
end;

destructor TACLScrollBarSubClass.Destroy;
begin
  FreeAndNil(FTimer);
  FreeAndNil(FButtonDown);
  FreeAndNil(FThumbnail);
  FreeAndNil(FButtonUp);
  inherited Destroy;
end;

procedure TACLScrollBarSubClass.Calculate(const ABounds: TRect);
begin
  FBounds := ABounds;
  FThumbnailSize := Style.GetThumbNominalSize(Kind);
  CalculateRects;
  CalculatePartStates;
end;

function TACLScrollBarSubClass.CalculatePositionFromThumbnail(ATotal: Integer): Integer;
begin
  if Kind = sbHorizontal then
    Result := MulDiv(ATotal, Thumbnail.Bounds.Left - ButtonUp.Bounds.Right,
      ButtonDown.Bounds.Left - ButtonUp.Bounds.Right - Thumbnail.Bounds.Width)
  else
    Result := MulDiv(ATotal, Thumbnail.Bounds.Top - ButtonUp.Bounds.Bottom,
      ButtonDown.Bounds.Top - ButtonUp.Bounds.Bottom - Thumbnail.Bounds.Height);
end;

procedure TACLScrollBarSubClass.CheckScrollBarSizes(var AWidth, AHeight: Integer);
begin
  if Kind = sbHorizontal then
    AHeight := Style.GetScrollBarSize(Kind)
  else
    AWidth := Style.GetScrollBarSize(Kind);
end;

procedure TACLScrollBarSubClass.CalculatePartStates;
begin
  ButtonDown.UpdateState;
  Thumbnail.UpdateState;
  ButtonUp.UpdateState;
end;

procedure TACLScrollBarSubClass.CalculateRects;
begin
  ButtonDown.Bounds := CalculateButtonDownRect;
  ButtonUp.Bounds := CalculateButtonUpRect;
  Thumbnail.Bounds := CalculateThumbnailRect; // last
end;

function TACLScrollBarSubClass.CalculateButtonDownRect: TRect;
begin
  Result := Bounds;
  if Kind = sbHorizontal then
    Result.Left := Result.Right - Style.GetButtonDownSize(Kind)
  else
    Result.Top := Result.Bottom - Style.GetButtonDownSize(Kind);
end;

function TACLScrollBarSubClass.CalculateButtonUpRect: TRect;
begin
  Result := Bounds;
  if Kind = sbHorizontal then
    Result.Width := Style.GetButtonUpSize(Kind)
  else
    Result.Height := Style.GetButtonUpSize(Kind);
end;

function TACLScrollBarSubClass.CalculateThumbnailRect: TRect;
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
        ASize := Style.GetThumbNominalSize(Kind);
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
        Result := {System.}Classes.Bounds(ButtonUp.Bounds.Right, Bounds.Top, ASize, Bounds.Height);
        ASize := (ScrollInfo.Max - ScrollInfo.Min) - (ScrollInfo.Page - 1);
        Result.Offset(MulDiv(ADelta, Min(ScrollInfo.Position - ScrollInfo.Min, ASize), ASize), 0);
      end;
    end
    else
    begin
      ADelta := ButtonDown.Bounds.Top - ButtonUp.Bounds.Bottom;
      if ScrollInfo.Page = 0 then
      begin
        ASize := Style.GetThumbNominalSize(Kind);
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
        Result := {System.}Classes.Bounds(Bounds.Left, ButtonUp.Bounds.Bottom, Bounds.Width, ASize);
        ASize := (ScrollInfo.Max - ScrollInfo.Min) - (ScrollInfo.Page - 1);
        Result.Offset(0, MulDiv(ADelta, Min(ScrollInfo.Position - ScrollInfo.Min, ASize), ASize));
      end;
    end;
  end;
end;

procedure TACLScrollBarSubClass.CancelDrag;
begin
  if PressedPart <> sbpNone then
  begin
    FTimer.Enabled := False;
    if PressedPart = sbpThumbnail then
    begin
      FScrollInfo.Position := GetPositionFromThumbnail;
      Scroll(scPosition);
    end;
    UpdateParts(sbpNone, sbpNone);
    Scroll(scEndScroll);
    CalculateRects;
    Invalidate(False);
  end;
end;

procedure TACLScrollBarSubClass.Draw(ACanvas: TCanvas);
begin
  Style.DrawBackground(ACanvas, Bounds, Kind);
  ButtonUp.Draw(ACanvas);
  ButtonDown.Draw(ACanvas);
  Thumbnail.Draw(ACanvas);
end;

procedure TACLScrollBarSubClass.Invalidate(AUpdateNow: Boolean);
begin
  Owner.InvalidateRect(Bounds);
  if AUpdateNow then
    Owner.Update;
end;

function TACLScrollBarSubClass.GetPageDownRect: TRect;
begin
  if Thumbnail.Bounds.IsEmpty then
    Exit(NullRect);
  if Kind = sbHorizontal then
    Result := Rect(Thumbnail.Bounds.Right, Bounds.Top, ButtonDown.Bounds.Left, Bounds.Bottom)
  else
    Result := Rect(Bounds.Left, Thumbnail.Bounds.Bottom, Bounds.Right, ButtonDown.Bounds.Top);
end;

function TACLScrollBarSubClass.GetPageUpRect: TRect;
begin
  if Thumbnail.Bounds.IsEmpty then
    Exit(NullRect);
  if Kind = sbHorizontal then
    Result := Rect(ButtonUp.Bounds.Right, Bounds.Top, Thumbnail.Bounds.Left, Bounds.Bottom)
  else
    Result := Rect(Bounds.Left, ButtonUp.Bounds.Bottom, Bounds.Right, Thumbnail.Bounds.Top);
end;

function TACLScrollBarSubClass.GetPositionFromThumbnail: Integer;
begin
  Result := ScrollInfo.Min + CalculatePositionFromThumbnail(
    ScrollInfo.Max - ScrollInfo.Min + IfThen(ScrollInfo.Page > 0, - ScrollInfo.Page + 1));
end;

function TACLScrollBarSubClass.HitTest(const P: TPoint): TACLScrollBarPart;
begin
  if PtInRect(Thumbnail.DisplayBounds, P) then // first
    Result := sbpThumbnail
  else if PtInRect(ButtonUp.DisplayBounds, P) then
    Result := sbpLineUp
  else if PtInRect(ButtonDown.DisplayBounds, P) then
    Result := sbpLineDown
  else if PtInRect(PageUpRect, P) then
    Result := sbpPageUp
  else if PtInRect(PageDownRect, P) then
    Result := sbpPageDown
  else
    Result := sbpNone;
end;

procedure TACLScrollBarSubClass.MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
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
    APart := HitTest(Point(X, Y));
    if APart <> sbpNone then
    begin
      if APart = sbpThumbnail then
      begin
        FPressedMousePos := Point(X, Y);
        FSaveThumbnailPos := Thumbnail.Bounds.TopLeft;
        Scroll(scTrack);
      end;
      if APart in SCROLL_BAR_TIMER_PARTS then
      begin
        if ssShift in AShift then
        begin
          FSaveThumbnailPos := Thumbnail.Bounds.TopLeft;
          FPressedMousePos := Thumbnail.Bounds.CenterPoint;
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
      UpdateParts(APart, APart);
      Invalidate(True);
    end;
  end;
end;

procedure TACLScrollBarSubClass.MouseEnter;
begin
  Invalidate(False);
end;

procedure TACLScrollBarSubClass.MouseLeave;
begin
  if PressedPart <> sbpThumbnail then
    HotPart := sbpNone;
end;

procedure TACLScrollBarSubClass.MouseMove(X, Y: Integer);
var
  LPart: TACLScrollBarPart;
begin
  if PressedPart = sbpThumbnail then
    MouseThumbTracking(X, Y)
  else
  begin
    LPart := HitTest(Point(X, Y));
    if PressedPart <> sbpNone then
      FTimer.Enabled := PressedPart = LPart;
    HotPart := LPart;
  end;
end;

procedure TACLScrollBarSubClass.MouseThumbTracking(X, Y: Integer);
var
  ADelta, ASize: Integer;
  ANewPos: Integer;
begin
  if PtInRect(Bounds.InflateTo(acScrollBarHitArea), Point(X, Y)) then
  begin
    if Kind = sbHorizontal then
    begin
      ADelta := X - FPressedMousePos.X;
      if ADelta <> 0 then
      begin
        ASize := Thumbnail.Bounds.Width;
        if (ADelta < 0) and (FSaveThumbnailPos.X + ADelta < ButtonUp.Bounds.Right) then
          ADelta := ButtonUp.Bounds.Right - FSaveThumbnailPos.X;
        if (ADelta > 0) and (FSaveThumbnailPos.X + ASize + ADelta > ButtonDown.Bounds.Left) then
          ADelta := ButtonDown.Bounds.Left - (FSaveThumbnailPos.X + ASize);
        Thumbnail.Bounds.Offset(-Thumbnail.Bounds.Left + FSaveThumbnailPos.X + ADelta, 0)
      end
    end
    else
    begin
      ADelta := Y - FPressedMousePos.Y;
      if ADelta <> 0 then
      begin
        ASize := Thumbnail.Bounds.Height;
        if (ADelta < 0) and (FSaveThumbnailPos.Y + ADelta < ButtonUp.Bounds.Bottom) then
          ADelta := ButtonUp.Bounds.Bottom - FSaveThumbnailPos.Y;
        if (ADelta > 0) and (FSaveThumbnailPos.Y + ASize + ADelta > ButtonDown.Bounds.Top) then
          ADelta := ButtonDown.Bounds.Top - (FSaveThumbnailPos.Y + ASize);
        Thumbnail.Bounds.Offset(0, -Thumbnail.Bounds.Top + FSaveThumbnailPos.Y + ADelta);
      end;
    end;
  end
  else
    Thumbnail.Bounds.Location := FSaveThumbnailPos;

  ANewPos := GetPositionFromThumbnail;
  if ANewPos <> ScrollInfo.Position then
  begin
    FScrollInfo.Position := ANewPos;
    Scroll(sbpThumbnail);
  end;
  Invalidate(False);
end;

procedure TACLScrollBarSubClass.MouseUp(AButton: TMouseButton; X, Y: Integer);
begin
  CancelDrag;
  HotPart := HitTest(Point(X, Y));
end;

procedure TACLScrollBarSubClass.Scroll(AScrollCode: TScrollCode);
var
  ANewPos: Integer;
begin
  ANewPos := ScrollInfo.Position;
  case AScrollCode of
    scLineUp:
      Dec(ANewPos, SmallChange);
    scLineDown:
      Inc(ANewPos, SmallChange);
    scPageUp:
      Dec(ANewPos, {System.}Math.Max(SmallChange, ScrollInfo.Page));
    scPageDown:
      Inc(ANewPos, {System.}Math.Max(SmallChange, ScrollInfo.Page));
    scTop:
      ANewPos := ScrollInfo.Min;
    scBottom:
      ANewPos := ScrollInfo.Max;
  else;
  end;
  ANewPos := MinMax(ANewPos, ScrollInfo.Min, ScrollInfo.Max);
  Owner.Scroll(AScrollCode, ANewPos);
  ANewPos := MinMax(ANewPos, ScrollInfo.Min, ScrollInfo.Max);
  if ANewPos <> ScrollInfo.Position then
  begin
    if AScrollCode = scTrack then
    begin
      FScrollInfo.Position := ANewPos;
      Invalidate(False);
    end
    else
      SetScrollParams(ScrollInfo.Min, ScrollInfo.Max, ANewPos, ScrollInfo.Page);
  end;
end;

procedure TACLScrollBarSubClass.Scroll(AScrollPart: TACLScrollBarPart);
const
  ScrollCodeMap: array[TACLScrollBarPart] of TScrollCode = (
    scLineUp, scLineUp, scLineDown, scTrack, scPageUp, scPageDown
  );
begin
  if AScrollPart <> sbpNone then
    Scroll(ScrollCodeMap[AScrollPart]);
end;

function TACLScrollBarSubClass.SetScrollParams(
  AMin, AMax, APosition, APageSize: Integer; ARedraw: Boolean = True): Boolean;
begin
  if not Style.IsThumbResizable(Kind) then
  begin
    if APageSize > 1 then
      Dec(AMax, APageSize);
    APageSize := 0;
  end;
  AMax := Max(AMax, AMin);
  APageSize := Min(APageSize, AMax - AMin);

  APosition := MinMax(APosition, AMin, AMax - APageSize + 1);
  if (ScrollInfo.Min = AMin) and (ScrollInfo.Max = AMax) and
     (ScrollInfo.Page = APageSize) and (ScrollInfo.Position = APosition)
  then
    ARedraw := False;

  FScrollInfo.Page := APageSize;
  FScrollInfo.Min := AMin;
  FScrollInfo.Max := AMax;

  Result := ScrollInfo.Position <> APosition;
  FScrollInfo.Position := APosition;
  Calculate(Bounds);

  if ARedraw then
    Invalidate(PressedPart = sbpThumbnail);
end;

procedure TACLScrollBarSubClass.UpdateParts(AHotPart, APressedPart: TACLScrollBarPart);
begin
  if (AHotPart <> FHotPart) or (APressedPart <> FPressedPart) then
  begin
    FPressedPart := APressedPart;
    FHotPart := AHotPart;
    CalculatePartStates;
  end;
end;

procedure TACLScrollBarSubClass.ScrollTimerHandler(ASender: TObject);
begin
  if PressedPart in SCROLL_BAR_TIMER_PARTS then
  begin
    FTimer.Interval := acScrollBarTimerScrollInterval;
    FTimer.Enabled := HitTest(Owner.ScreenToClient(MouseCursorPos)) = PressedPart;
    if FTimer.Enabled then
      Scroll(PressedPart);
  end
  else
    CancelDrag;
end;

procedure TACLScrollBarSubClass.SetHotPart(APart: TACLScrollBarPart);
begin
  UpdateParts(APart, PressedPart);
end;

{ TACLScrollBar }

constructor TACLScrollBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csOpaque, csCaptureMouse];
  FStyle := TACLStyleScrollBox.Create(Self);
  FSubClass := TACLScrollBarSubClass.Create(Self, Style, sbHorizontal);
end;

destructor TACLScrollBar.Destroy;
begin
  FreeAndNil(FSubClass);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLScrollBar.Paint;
begin
  SubClass.Draw(Canvas);
end;

procedure TACLScrollBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  SubClass.MouseDown(Button, Shift, X, Y);
end;

procedure TACLScrollBar.MouseEnter;
begin
  inherited MouseEnter;
  SubClass.MouseEnter;
end;

procedure TACLScrollBar.MouseLeave;
begin
  SubClass.MouseLeave;
  inherited MouseLeave;
end;

procedure TACLScrollBar.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  SubClass.MouseMove(X, Y);
end;

procedure TACLScrollBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  SubClass.MouseUp(Button, X, Y);
end;

procedure TACLScrollBar.Scroll(ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  if Assigned(OnScroll) then OnScroll(Self, ScrollCode, ScrollPos);
end;

procedure TACLScrollBar.CMCancelMode(var Message: TCMCancelMode);
begin
  SubClass.CancelDrag;
  inherited;
end;

procedure TACLScrollBar.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  SubClass.CancelDrag;
  SubClass.Calculate(ClientRect);
  Invalidate;
end;

procedure TACLScrollBar.CNHScroll(var Message: TWMHScroll);
begin
  SubClass.Scroll(TScrollCode(Message.ScrollCode));
end;

procedure TACLScrollBar.CMVisibleChanged(var Message: TMessage);
begin
  SubClass.CancelDrag;
  inherited;
end;

procedure TACLScrollBar.CNVScroll(var Message: TWMVScroll);
begin
  SubClass.Scroll(TScrollCode(Message.ScrollCode));
end;

procedure TACLScrollBar.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
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

function TACLScrollBar.GetKind: TScrollBarKind;
begin
  Result := SubClass.Kind;
end;

function TACLScrollBar.GetScrollInfo: TACLScrollInfo;
begin
  Result := SubClass.ScrollInfo;
end;

function TACLScrollBar.GetSmallChange: Word;
begin
  Result := SubClass.SmallChange;
end;

procedure TACLScrollBar.SetScrollParams(AMin, AMax, APosition, APageSize: Integer; ARedraw: Boolean = True);
begin
  SubClass.SetScrollParams(AMin, AMax, APosition, APageSize, ARedraw);
end;

procedure TACLScrollBar.SetScrollParams(const AInfo: TScrollInfo; ARedraw: Boolean = True);
begin
  SetScrollParams(AInfo.nMin, AInfo.nMax, AInfo.nPos, AInfo.nPage, ARedraw);
end;

procedure TACLScrollBar.SetSmallChange(AValue: Word);
begin
  SubClass.SmallChange := Max(AValue, 1);
end;

procedure TACLScrollBar.SetKind(Value: TScrollBarKind);
begin
  if Kind <> Value then
  begin
    SubClass.Kind := Value;
    UpdateTransparency;
    AdjustSize;
    Invalidate;
  end;
end;

procedure TACLScrollBar.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if not (csLoading in ComponentState) then
    SubClass.CheckScrollBarSizes(AWidth, AHeight);
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  SubClass.Calculate(ClientRect);
end;

procedure TACLScrollBar.SetStyle(const Value: TACLStyleScrollBox);
begin
  FStyle.Assign(Value);
end;

procedure TACLScrollBar.UpdateTransparency;
begin
  if Style.TextureBackground[Kind].HasAlpha then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque]
end;

end.
