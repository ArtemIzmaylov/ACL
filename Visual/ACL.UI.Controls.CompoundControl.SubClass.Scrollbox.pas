{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*          Compoud Control Classes          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.CompoundControl.SubClass.Scrollbox;

{$I ACL.Config.inc}

interface

uses
  Windows, SysUtils, Classes, Controls, Graphics, Types, Forms, StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.Math,
  ACL.UI.Animation,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.ScrollBar,
  ACL.Utils.Common,
  ACL.UI.Resources;

type
  TACLCompoundControlSubClassScrollBarThumbnailViewInfo = class;

  TACLScrollEvent = procedure (Sender: TObject; Position: Integer) of object;
  TACLVisibleScrollBars = set of TScrollBarKind;

  { TACLScrollInfo }

  TACLScrollInfo = record
    Min: Integer;
    Max: Integer;
    LineSize: Integer;
    Page: Integer;
    Position: Integer;

    function InvisibleArea: Integer;
    function Range: Integer;
    procedure Reset;
  end;

  { TACLCompoundControlSubClassScrollBarViewInfo }

  TACLCompoundControlSubClassScrollBarViewInfo = class(TACLCompoundControlSubClassContainerViewInfo, IACLPressableObject)
  strict private
    FKind: TScrollBarKind;
    FPageSizeInPixels: Integer;
    FScrollInfo: TACLScrollInfo;
    FScrollTimer: TACLTimer;
    FThumbExtends: TRect;
    FTrackArea: TRect;
    FVisible: Boolean;

    FOnScroll: TACLScrollEvent;

    function GetHitTest: TACLHitTestInfo; inline;
    function GetStyle: TACLStyleScrollBox; inline;
    function GetThumbnailViewInfo: TACLCompoundControlSubClassScrollBarThumbnailViewInfo;
    procedure ScrollTimerHandler(Sender: TObject);
  protected
    function CalculateScrollDelta(const P: TPoint): Integer;
    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure RecreateSubCells; override;

    procedure Scroll(APosition: Integer);
    procedure ScrollTo(const P: TPoint);
    procedure ScrollToMouseCursor(const AInitialDelta: Integer);
    // IACLPressableObject
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
    //
    property HitTest: TACLHitTestInfo read GetHitTest;
    property ThumbnailViewInfo: TACLCompoundControlSubClassScrollBarThumbnailViewInfo read GetThumbnailViewInfo;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass; AKind: TScrollBarKind); reintroduce; virtual;
    destructor Destroy; override;
    function IsThumbResizable: Boolean; virtual;
    function MeasureSize: Integer;
    procedure SetParams(const AScrollInfo: TACLScrollInfo);
    //
    property Kind: TScrollBarKind read FKind;
    property ScrollInfo: TACLScrollInfo read FScrollInfo;
    property Style: TACLStyleScrollBox read GetStyle;
    property ThumbExtends: TRect read FThumbExtends;
    property TrackArea: TRect read FTrackArea;
    property Visible: Boolean read FVisible;
    //
    property OnScroll: TACLScrollEvent read FOnScroll write FOnScroll;
  end;

  { TACLCompoundControlSubClassScrollBarPartViewInfo }

  TACLCompoundControlSubClassScrollBarPartViewInfo = class(TACLCompoundControlSubClassCustomViewInfo,
    IACLAnimateControl,
    IACLPressableObject,
    IACLHotTrackObject)
  strict private
    FOwner: TACLCompoundControlSubClassScrollBarViewInfo;
    FPart: TACLScrollBarPart;
    FState: TACLButtonState;

    function GetActualState: TACLButtonState;
    function GetKind: TScrollBarKind;
    function GetStyle: TACLStyleScrollBox;
    procedure SetState(AValue: TACLButtonState);
  protected
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure UpdateState;
    // IACLAnimateControl
    procedure IACLAnimateControl.Animate = Invalidate;
    // IACLHotTrackObject
    procedure IACLHotTrackObject.Enter = UpdateState;
    procedure IACLHotTrackObject.Leave = UpdateState;
    // IACLPressableObject
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo); virtual;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo); virtual;
    //
    property ActualState: TACLButtonState read GetActualState;
  public
    constructor Create(AOwner: TACLCompoundControlSubClassScrollBarViewInfo; APart: TACLScrollBarPart); reintroduce; virtual;
    destructor Destroy; override;
    procedure Scroll(APosition: Integer);
    //
    property Kind: TScrollBarKind read GetKind;
    property Owner: TACLCompoundControlSubClassScrollBarViewInfo read FOwner;
    property Part: TACLScrollBarPart read FPart;
    property State: TACLButtonState read FState write SetState;
    property Style: TACLStyleScrollBox read GetStyle;
  end;

  { TACLCompoundControlSubClassScrollBarButtonViewInfo }

  TACLCompoundControlSubClassScrollBarButtonViewInfo = class(TACLCompoundControlSubClassScrollBarPartViewInfo)
  strict private
    FTimer: TACLTimer;

    procedure TimerHandler(Sender: TObject);
  protected
    procedure Click;
    // IACLPressableObject
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo); override;
  end;

  { TACLCompoundControlSubClassScrollBarThumbnailDragObject }

  TACLCompoundControlSubClassScrollBarThumbnailDragObject = class(TACLCompoundControlSubClassDragObject)
  strict private
    FOwner: TACLCompoundControlSubClassScrollBarPartViewInfo;
    FSavedBounds: TRect;
    FSavedPosition: Integer;

    function GetTrackArea: TRect;
  public
    constructor Create(AOwner: TACLCompoundControlSubClassScrollBarPartViewInfo);
    function DragStart: Boolean; override;
    procedure DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer); override;
    procedure DragFinished(ACanceled: Boolean); override;
    //
    property Owner: TACLCompoundControlSubClassScrollBarPartViewInfo read FOwner;
    property TrackArea: TRect read GetTrackArea;
  end;

  { TACLCompoundControlSubClassScrollBarThumbnailViewInfo }

  TACLCompoundControlSubClassScrollBarThumbnailViewInfo = class(TACLCompoundControlSubClassScrollBarPartViewInfo,
    IACLDraggableObject)
  protected
    // IACLDraggableObject
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
  end;

  { TACLCompoundControlSubClassScrollContainerViewInfo }

  TACLCompoundControlSubClassScrollContainerViewInfo = class(TACLCompoundControlSubClassContainerViewInfo)
  strict private
    FScrollBarHorz: TACLCompoundControlSubClassScrollBarViewInfo;
    FScrollBarVert: TACLCompoundControlSubClassScrollBarViewInfo;
    FSizeGripArea: TRect;
    FViewportX: Integer;
    FViewportY: Integer;

    function GetViewport: TPoint;
    function GetVisibleScrollBars: TACLVisibleScrollBars;
    procedure SetViewport(const AValue: TPoint);
    procedure SetViewportX(AValue: Integer);
    procedure SetViewportY(AValue: Integer);
    //
    procedure ScrollHorzHandler(Sender: TObject; ScrollPos: Integer);
    procedure ScrollVertHandler(Sender: TObject; ScrollPos: Integer);
  protected
    FClientBounds: TRect;
    FContentSize: TSize;

    function CreateScrollBar(AKind: TScrollBarKind): TACLCompoundControlSubClassScrollBarViewInfo; virtual;
    function GetScrollInfo(AKind: TScrollBarKind; out AInfo: TACLScrollInfo): Boolean; virtual;
    function ScrollViewport(AKind: TScrollBarKind; AScrollCode: TScrollCode): Integer;
    //
    procedure CalculateContentLayout; virtual; abstract;
    procedure CalculateScrollBar(AScrollBar: TACLCompoundControlSubClassScrollBarViewInfo); virtual;
    procedure CalculateScrollBarsPosition(var R: TRect);
    procedure CalculateSubCells(const AChanges: TIntegerSet); override;
    procedure ContentScrolled(ADeltaX, ADeltaY: Integer); virtual;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure UpdateScrollBars; virtual;
  public
    constructor Create(AOwner: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    procedure Calculate(const R: TRect; AChanges: TIntegerSet); override;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; override;
    procedure ScrollByMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);
    procedure ScrollHorizontally(const AScrollCode: TScrollCode);
    procedure ScrollVertically(const AScrollCode: TScrollCode);
    //
    property ClientBounds: TRect read FClientBounds;
    property ContentSize: TSize read FContentSize;
    property ScrollBarHorz: TACLCompoundControlSubClassScrollBarViewInfo read FScrollBarHorz;
    property ScrollBarVert: TACLCompoundControlSubClassScrollBarViewInfo read FScrollBarVert;
    property SizeGripArea: TRect read FSizeGripArea;
    property Viewport: TPoint read GetViewport write SetViewport;
    property ViewportX: Integer read FViewportX write SetViewportX;
    property ViewportY: Integer read FViewportY write SetViewportY;
    property VisibleScrollBars: TACLVisibleScrollBars read GetVisibleScrollBars;
  end;

implementation

uses
  Math;

{ TACLScrollInfo }

function TACLScrollInfo.InvisibleArea: Integer;
begin
  Result := Range - Page;
end;

function TACLScrollInfo.Range: Integer;
begin
  Result := Max - Min + 1;
end;

procedure TACLScrollInfo.Reset;
begin
  ZeroMemory(@Self, SizeOf(Self));
end;

{ TACLCompoundControlSubClassScrollBarViewInfo }

constructor TACLCompoundControlSubClassScrollBarViewInfo.Create(ASubClass: TACLCompoundControlSubClass; AKind: TScrollBarKind);
begin
  inherited Create(ASubClass);
  FKind := AKind;
end;

destructor TACLCompoundControlSubClassScrollBarViewInfo.Destroy;
begin
  FreeAndNil(FScrollTimer);
  inherited Destroy;
end;

function TACLCompoundControlSubClassScrollBarViewInfo.IsThumbResizable: Boolean;
begin
  Result := Style.IsThumbResizable(Kind);
end;

function TACLCompoundControlSubClassScrollBarViewInfo.MeasureSize: Integer;
begin
  if not Visible then
    Result := 0
  else
    if Kind = sbVertical then
      Result := Style.TextureBackgroundVert.FrameWidth
    else
      Result := Style.TextureBackgroundHorz.FrameHeight;
end;

procedure TACLCompoundControlSubClassScrollBarViewInfo.SetParams(const AScrollInfo: TACLScrollInfo);
begin
  FScrollInfo := AScrollInfo;
  if not IsThumbResizable then
  begin
    Dec(FScrollInfo.Max, FScrollInfo.Page);
    FScrollInfo.Page := 0;
  end;
  FVisible := FScrollInfo.Page + 1 < FScrollInfo.Range;
  Calculate(Bounds, [cccnLayout]);
end;

function TACLCompoundControlSubClassScrollBarViewInfo.CalculateScrollDelta(const P: TPoint): Integer;
var
  ADelta: TPoint;
begin
  ADelta := acPointOffsetNegative(P, acRectCenter(ThumbnailViewInfo.Bounds));
  if Kind = sbHorizontal then
    Result := Sign(ADelta.X) * Min(Abs(ADelta.X), FPageSizeInPixels)
  else
    Result := Sign(ADelta.Y) * Min(Abs(ADelta.Y), FPageSizeInPixels);
end;

procedure TACLCompoundControlSubClassScrollBarViewInfo.DoCalculate(AChanges: TIntegerSet);
var
  ASize: Integer;
  R1: TRect;
  R2: TRect;
begin
  inherited DoCalculate(AChanges);
  if ChildCount = 0 then
    RecreateSubCells;
  if Visible and ([cccnLayout, cccnStruct] * AChanges <> []) and (ChildCount = 3) then
  begin
    if Kind = sbVertical then
    begin
      FThumbExtends := Style.TextureThumbVert.ContentOffsets;
      FThumbExtends.Right := 0;
      FThumbExtends.Left := 0;

      R2 := Bounds;
      R1 := acRectSetBottom(R2, R2.Bottom, Style.TextureButtonsVert.FrameHeight);
      Children[0].Calculate(R1, [cccnLayout]);
      R2.Bottom := R1.Top;

      R1 := acRectSetHeight(R2, Style.TextureButtonsVert.FrameHeight);
      Children[1].Calculate(R1, [cccnLayout]);
      R2.Top := R1.Bottom;

      FPageSizeInPixels := Max(MulDiv(ScrollInfo.Page, R2.Height, ScrollInfo.Range), 1);
      ASize := MaxMin(R2.Height, FPageSizeInPixels, Style.TextureThumbVert.FrameHeight - acMarginHeight(FThumbExtends));
      Dec(R2.Bottom, ASize);
      FTrackArea := R2;
      R1 := acRectSetHeight(R2, ASize);
      ASize := ScrollInfo.InvisibleArea;
      R1 := acRectOffset(R1, 0, MulDiv(R2.Height, Min(ScrollInfo.Position - ScrollInfo.Min, ASize), ASize));
    end
    else
    begin
      FThumbExtends := Style.TextureThumbHorz.ContentOffsets;
      FThumbExtends.Bottom := 0;
      FThumbExtends.Top := 0;

      R2 := Bounds;
      R1 := acRectSetRight(R2, R2.Right, Style.TextureButtonsHorz.FrameWidth);
      Children[0].Calculate(R1, [cccnLayout]);
      R2.Right := R1.Left;

      R1 := acRectSetWidth(R2, Style.TextureButtonsHorz.FrameWidth);
      Children[1].Calculate(R1, [cccnLayout]);
      R2.Left := R1.Right;

      FPageSizeInPixels := Max(MulDiv(ScrollInfo.Page, R2.Width, ScrollInfo.Range), 1);
      ASize := MaxMin(R2.Width, FPageSizeInPixels, Style.TextureThumbHorz.FrameWidth - acMarginWidth(FThumbExtends));
      Dec(R2.Right, ASize);
      FTrackArea := R2;
      R1 := acRectSetWidth(R2, ASize);
      ASize := ScrollInfo.InvisibleArea;
      R1 := acRectOffset(R1, MulDiv(R2.Width, Min(ScrollInfo.Position - ScrollInfo.Min, ASize), ASize), 0);
    end;
    Children[2].Calculate(acRectInflate(R1, FThumbExtends), [cccnLayout]);
  end;
end;

procedure TACLCompoundControlSubClassScrollBarViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
begin
  inherited;
  AInfo.IsScrollBarArea := True;
end;

procedure TACLCompoundControlSubClassScrollBarViewInfo.DoDraw(ACanvas: TCanvas);
begin
  Style.DrawBackground(ACanvas.Handle, Bounds, Kind);
  inherited DoDraw(ACanvas);
end;

procedure TACLCompoundControlSubClassScrollBarViewInfo.RecreateSubCells;
begin
  FChildren.Add(TACLCompoundControlSubClassScrollBarButtonViewInfo.Create(Self, sbpLineDown));
  FChildren.Add(TACLCompoundControlSubClassScrollBarButtonViewInfo.Create(Self, sbpLineUp));
  FChildren.Add(TACLCompoundControlSubClassScrollBarThumbnailViewInfo.Create(Self, sbpThumbnail));
end;

procedure TACLCompoundControlSubClassScrollBarViewInfo.Scroll(APosition: Integer);
begin
  if Assigned(OnScroll) then
    OnScroll(Self, APosition);
end;

procedure TACLCompoundControlSubClassScrollBarViewInfo.ScrollTo(const P: TPoint);
var
  ADelta: TPoint;
  ADragObject: TACLCompoundControlSubClassDragObject;
begin
  ADelta := acPointOffsetNegative(P, acRectCenter(ThumbnailViewInfo.Bounds));
  if acPointIsEqual(ADelta, NullPoint) then
    Exit;
  
  ADragObject := ThumbnailViewInfo.CreateDragObject(nil);
  try
    if ADragObject.DragStart then
    begin
      ADragObject.DragMove(P, ADelta.X, ADelta.Y);
      ADragObject.DragFinished(False);
    end;
  finally
    ADragObject.Free;
  end;
end;

procedure TACLCompoundControlSubClassScrollBarViewInfo.ScrollToMouseCursor(const AInitialDelta: Integer);
var
  ACenter: TPoint;
  ADelta: Integer;
begin
  if HitTest.HitObject <> Self then
    Exit;

  ADelta := CalculateScrollDelta(HitTest.HitPoint);
  if Sign(ADelta) <> Sign(AInitialDelta) then
    Exit;

  ACenter := acRectCenter(ThumbnailViewInfo.Bounds);
  if Kind = sbHorizontal then
    Inc(ACenter.X, ADelta)
  else
    Inc(ACenter.Y, ADelta);

  ScrollTo(ACenter);
end;

procedure TACLCompoundControlSubClassScrollBarViewInfo.MouseDown(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
var
  ADelta: Integer;
begin
  if (AButton = mbLeft) and (ssShift in AShift) or (AButton = mbMiddle) then
    ScrollTo(AHitTestInfo.HitPoint)
  else
    if AButton = mbLeft then
    begin
      FreeAndNil(FScrollTimer);
      ADelta := CalculateScrollDelta(AHitTestInfo.HitPoint);
      if ADelta <> 0 then
      begin
        FScrollTimer := TACLTimer.CreateEx(ScrollTimerHandler, acScrollBarTimerInitialDelay, True);
        FScrollTimer.Tag := ADelta;
        ScrollTimerHandler(nil);
      end;
    end;
end;

procedure TACLCompoundControlSubClassScrollBarViewInfo.MouseUp(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
begin
  FreeAndNil(FScrollTimer);
end;

procedure TACLCompoundControlSubClassScrollBarViewInfo.ScrollTimerHandler(Sender: TObject);
begin
  if ssLeft in KeyboardStateToShiftState then
  begin
    FScrollTimer.Interval := acScrollBarTimerScrollInterval;
    ScrollToMouseCursor(FScrollTimer.Tag);
  end
  else
    FreeAndNil(FScrollTimer);
end;

function TACLCompoundControlSubClassScrollBarViewInfo.GetHitTest: TACLHitTestInfo;
begin
  Result := SubClass.Controller.HitTest;
end;

function TACLCompoundControlSubClassScrollBarViewInfo.GetStyle: TACLStyleScrollBox;
begin
  Result := SubClass.StyleScrollBox;
end;

function TACLCompoundControlSubClassScrollBarViewInfo.GetThumbnailViewInfo: TACLCompoundControlSubClassScrollBarThumbnailViewInfo;
begin
  Result := Children[2] as TACLCompoundControlSubClassScrollBarThumbnailViewInfo;
end;

{ TACLCompoundControlSubClassScrollBarPartViewInfo }

constructor TACLCompoundControlSubClassScrollBarPartViewInfo.Create(
  AOwner: TACLCompoundControlSubClassScrollBarViewInfo; APart: TACLScrollBarPart);
begin
  inherited Create(AOwner.SubClass);
  FOwner := AOwner;
  FPart := APart;
end;

destructor TACLCompoundControlSubClassScrollBarPartViewInfo.Destroy;
begin
  AnimationManager.RemoveOwner(Self);
  inherited Destroy;
end;

procedure TACLCompoundControlSubClassScrollBarPartViewInfo.Scroll(APosition: Integer);
begin
  Owner.Scroll(APosition);
end;

procedure TACLCompoundControlSubClassScrollBarPartViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
begin
  inherited;
  AInfo.IsScrollBarArea := True;
end;

procedure TACLCompoundControlSubClassScrollBarPartViewInfo.DoDraw(ACanvas: TCanvas);
begin
  if not AnimationManager.Draw(Self, ACanvas.Handle, Bounds) then
    Style.DrawPart(ACanvas.Handle, Bounds, Part, ActualState, Kind);
end;

procedure TACLCompoundControlSubClassScrollBarPartViewInfo.UpdateState;
begin
  if SubClass.Controller.PressedObject = Self then
    State := absPressed
  else if SubClass.Controller.HoveredObject = Self then
    State := absHover
  else
    State := absNormal;
end;

procedure TACLCompoundControlSubClassScrollBarPartViewInfo.MouseDown(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
begin
  UpdateState;
end;

procedure TACLCompoundControlSubClassScrollBarPartViewInfo.MouseUp(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
begin
  UpdateState;
end;

function TACLCompoundControlSubClassScrollBarPartViewInfo.GetActualState: TACLButtonState;
begin
  if SubClass.EnabledContent then
    Result := State
  else
    Result := absDisabled;
end;

function TACLCompoundControlSubClassScrollBarPartViewInfo.GetKind: TScrollBarKind;
begin
  Result := Owner.Kind;
end;

function TACLCompoundControlSubClassScrollBarPartViewInfo.GetStyle: TACLStyleScrollBox;
begin
  Result := Owner.Style;
end;

procedure TACLCompoundControlSubClassScrollBarPartViewInfo.SetState(AValue: TACLButtonState);
var
  AAnimator: TACLBitmapFadingAnimation;
begin
  if AValue <> FState then
  begin
    AnimationManager.RemoveOwner(Self);

    if acUIFadingEnabled and (AValue = absNormal) and (FState = absHover) then
    begin
      AAnimator := TACLBitmapFadingAnimation.Create(Self, acUIFadingTime);
      DrawTo(AAnimator.AllocateFrame1(Bounds).Canvas, 0, 0);
      FState := AValue;
      DrawTo(AAnimator.AllocateFrame2(Bounds).Canvas, 0, 0);
      AAnimator.Run;
    end
    else
      FState := AValue;

    Invalidate;
  end;
end;

{ TACLCompoundControlSubClassScrollBarButtonViewInfo }

procedure TACLCompoundControlSubClassScrollBarButtonViewInfo.Click;
begin
  case Part of
    sbpLineDown:
      Scroll(Owner.ScrollInfo.Position + Owner.ScrollInfo.LineSize);
    sbpLineUp:
      Scroll(Owner.ScrollInfo.Position - Owner.ScrollInfo.LineSize);
  end;
end;

procedure TACLCompoundControlSubClassScrollBarButtonViewInfo.MouseDown(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
begin
  if AButton = mbLeft then
  begin
    Click;
    FTimer := TACLTimer.CreateEx(TimerHandler, acScrollBarTimerInitialDelay, True);
  end;
  inherited MouseDown(AButton, AShift, AHitTestInfo);
end;

procedure TACLCompoundControlSubClassScrollBarButtonViewInfo.MouseUp(
  AButton: TMouseButton; AShift: TShiftState; AHitTestInfo: TACLHitTestInfo);
begin
  FreeAndNil(FTimer);
  inherited MouseUp(AButton, AShift, AHitTestInfo);
end;

procedure TACLCompoundControlSubClassScrollBarButtonViewInfo.TimerHandler(Sender: TObject);
begin
  FTimer.Interval := acScrollBarTimerScrollInterval;
  Click;
end;

{ TACLCompoundControlSubClassScrollBarThumbnailDragObject }

constructor TACLCompoundControlSubClassScrollBarThumbnailDragObject.Create(
  AOwner: TACLCompoundControlSubClassScrollBarPartViewInfo);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TACLCompoundControlSubClassScrollBarThumbnailDragObject.DragStart: Boolean;
begin
  FSavedBounds := Owner.Bounds;
  FSavedPosition := Owner.Owner.ScrollInfo.Position;
  Result := True;
end;

procedure TACLCompoundControlSubClassScrollBarThumbnailDragObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);

  procedure CheckDeltas(var ADeltaX, ADeltaY: Integer; APosition, ALeftBound, ARightBound: Integer);
  begin
    ADeltaY := 0;
    if ADeltaX + APosition < ALeftBound then
      ADeltaX := ALeftBound - APosition;
    if ADeltaX + APosition > ARightBound then
      ADeltaX := ARightBound - APosition;
  end;

  function CalculatePosition(APosition, ALeftBound, ARightBound: Integer): Integer;
  begin
    Result := Owner.Owner.ScrollInfo.Min + MulDiv(Owner.Owner.ScrollInfo.InvisibleArea,
      APosition - ALeftBound, ARightBound - ALeftBound);
  end;

var
  R: TRect;
begin
  R := acRectContent(Owner.Bounds, Owner.Owner.ThumbExtends);
  if Owner.Kind = sbHorizontal then
    CheckDeltas(ADeltaX, ADeltaY, R.Left, TrackArea.Left, TrackArea.Right)
  else
    CheckDeltas(ADeltaY, ADeltaX, R.Top, TrackArea.Top, TrackArea.Bottom);

  if PtInRect(acRectInflate(Owner.Owner.Bounds, acScrollBarHitArea), P) then
  begin
    OffsetRect(R, ADeltaX, ADeltaY);

    if Owner.Kind = sbHorizontal then
      Owner.Scroll(CalculatePosition(R.Left, TrackArea.Left, TrackArea.Right))
    else
      Owner.Scroll(CalculatePosition(R.Top, TrackArea.Top, TrackArea.Bottom));

    Owner.Calculate(acRectInflate(R, Owner.Owner.ThumbExtends), [cccnLayout]);
  end
  else
  begin
    ADeltaX := FSavedBounds.Left - Owner.Bounds.Left;
    ADeltaY := FSavedBounds.Top - Owner.Bounds.Top;

    Owner.Scroll(FSavedPosition);
    Owner.Calculate(FSavedBounds, [cccnLayout]);
  end;
  Owner.Owner.Invalidate;
end;

procedure TACLCompoundControlSubClassScrollBarThumbnailDragObject.DragFinished(ACanceled: Boolean);
begin
  if ACanceled then
    Owner.Scroll(FSavedPosition);
  Owner.UpdateState;
end;

function TACLCompoundControlSubClassScrollBarThumbnailDragObject.GetTrackArea: TRect;
begin
  Result := Owner.Owner.TrackArea;
end;

{ TACLCompoundControlSubClassScrollBarThumbnailViewInfo }

function TACLCompoundControlSubClassScrollBarThumbnailViewInfo.CreateDragObject(
  const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
begin
  Result := TACLCompoundControlSubClassScrollBarThumbnailDragObject.Create(Self);
end;

{ TACLCompoundControlViewInfo }

constructor TACLCompoundControlSubClassScrollContainerViewInfo.Create(AOwner: TACLCompoundControlSubClass);
begin
  inherited Create(AOwner);
  FScrollBarHorz := CreateScrollBar(sbHorizontal);
  FScrollBarHorz.OnScroll := ScrollHorzHandler;
  FScrollBarVert := CreateScrollBar(sbVertical);
  FScrollBarVert.OnScroll := ScrollVertHandler;
end;

destructor TACLCompoundControlSubClassScrollContainerViewInfo.Destroy;
begin
  FreeAndNil(FScrollBarHorz);
  FreeAndNil(FScrollBarVert);
  inherited Destroy;
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.Calculate(const R: TRect; AChanges: TIntegerSet);
begin
  inherited Calculate(R, AChanges);
  if [cccnLayout, cccnStruct] * AChanges <> [] then
    CalculateContentLayout;
  if [cccnViewport, cccnLayout, cccnStruct] * AChanges <> [] then
    UpdateScrollBars;
end;

function TACLCompoundControlSubClassScrollContainerViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  Result := ScrollBarHorz.CalculateHitTest(AInfo) or ScrollBarVert.CalculateHitTest(AInfo) or inherited CalculateHitTest(AInfo);
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.ScrollByMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);
var
  ACount: Integer;
begin
  ACount := TACLMouseWheel.GetScrollLines(AShift);
  while ACount > 0 do
  begin
    if ssShift in AShift then
      ScrollHorizontally(TACLMouseWheel.DirectionToScrollCode[ADirection])
    else
      ScrollVertically(TACLMouseWheel.DirectionToScrollCode[ADirection]);

    Dec(ACount);
  end
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.ScrollHorizontally(const AScrollCode: TScrollCode);
begin
  ViewportX := ScrollViewport(sbHorizontal, AScrollCode);
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.ScrollVertically(const AScrollCode: TScrollCode);
begin
  ViewportY := ScrollViewport(sbVertical, AScrollCode);
end;

function TACLCompoundControlSubClassScrollContainerViewInfo.CreateScrollBar(
  AKind: TScrollBarKind): TACLCompoundControlSubClassScrollBarViewInfo;
begin
  Result := TACLCompoundControlSubClassScrollBarViewInfo.Create(SubClass, AKind);
end;

function TACLCompoundControlSubClassScrollContainerViewInfo.GetScrollInfo(
  AKind: TScrollBarKind; out AInfo: TACLScrollInfo): Boolean;
begin
  AInfo.Reset;
  AInfo.LineSize := 5;
  case AKind of
    sbVertical:
      begin
        AInfo.Position := ViewportY;
        AInfo.Max := ContentSize.cy - 1;
        AInfo.Page := acRectHeight(ClientBounds);
      end;

    sbHorizontal:
      begin
        AInfo.Page := acRectWidth(ClientBounds);
        AInfo.Max := ContentSize.cx - 1;
        AInfo.Position := ViewportX;
      end;
  end;
  Result := (AInfo.Max >= AInfo.Page) and (AInfo.Max > AInfo.Min);
end;

function TACLCompoundControlSubClassScrollContainerViewInfo.ScrollViewport(
  AKind: TScrollBarKind; AScrollCode: TScrollCode): Integer;
var
  AInfo: TACLScrollInfo;
begin
  Result := 0;
  if GetScrollInfo(AKind, AInfo) then
    case AScrollCode of
      scLineUp:
        Result := AInfo.Position - AInfo.LineSize;
      scLineDown:
        Result := AInfo.Position + AInfo.LineSize;
      scPageUp:
        Result := AInfo.Position - Integer(AInfo.Page);
      scPageDown:
        Result := AInfo.Position + Integer(AInfo.Page);
      scTop:
        Result := AInfo.Min;
      scBottom:
        Result := AInfo.Max;
    end;
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.CalculateScrollBar(
  AScrollBar: TACLCompoundControlSubClassScrollBarViewInfo);
var
  AScrollInfo: TACLScrollInfo;
begin
  if not GetScrollInfo(AScrollBar.Kind, AScrollInfo) then
    AScrollInfo.Reset;
  AScrollBar.SetParams(AScrollInfo);
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.CalculateScrollBarsPosition(var R: TRect);
var
  R1: TRect;
begin
  R1 := acRectSetTop(R, ScrollBarHorz.MeasureSize);
  Dec(R1.Right, ScrollBarVert.MeasureSize);
  ScrollBarHorz.Calculate(R1, [cccnLayout]);

  R1 := acRectSetLeft(R, ScrollBarVert.MeasureSize);
  Dec(R1.Bottom, ScrollBarHorz.MeasureSize);
  ScrollBarVert.Calculate(R1, [cccnLayout]);

  FSizeGripArea := ScrollBarVert.Bounds;
  FSizeGripArea.Bottom := ScrollBarHorz.Bounds.Bottom;
  FSizeGripArea.Top := ScrollBarHorz.Bounds.Top;

  Dec(R.Bottom, ScrollBarHorz.Bounds.Height);
  Dec(R.Right, ScrollBarVert.Bounds.Width);
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.CalculateSubCells(const AChanges: TIntegerSet);
begin
  FClientBounds := Bounds;
  CalculateScrollBarsPosition(FClientBounds);
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.ContentScrolled(ADeltaX, ADeltaY: Integer);
begin
  SubClass.Changed([cccnViewport]);
  SubClass.Update;
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.DoDraw(ACanvas: TCanvas);
begin
  inherited DoDraw(ACanvas);
  SubClass.StyleScrollBox.DrawSizeGripArea(ACanvas.Handle, SizeGripArea);
  ScrollBarHorz.Draw(ACanvas);
  ScrollBarVert.Draw(ACanvas);
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.UpdateScrollBars;
var
  AVisibleScrollBars: TACLVisibleScrollBars;
begin
  AVisibleScrollBars := VisibleScrollBars;
  try
    CalculateScrollBar(ScrollBarHorz);
    CalculateScrollBar(ScrollBarVert);
    SetViewportX(FViewportX);
    SetViewportY(FViewportY);
  finally
    if AVisibleScrollBars <> VisibleScrollBars then
      Calculate(Bounds, [cccnLayout]);
  end;
end;

function TACLCompoundControlSubClassScrollContainerViewInfo.GetViewport: TPoint;
begin
  Result := Point(ViewportX, ViewportY);
end;

function TACLCompoundControlSubClassScrollContainerViewInfo.GetVisibleScrollBars: TACLVisibleScrollBars;
begin
  Result := [];
  if ScrollBarHorz.Visible then
    Include(Result, sbHorizontal);
  if ScrollBarVert.Visible then
    Include(Result, sbVertical);
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.SetViewport(const AValue: TPoint);
begin
  ViewportX := AValue.X;
  ViewportY := AValue.Y;
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.SetViewportX(AValue: Integer);
var
  ADelta: Integer;
begin
  AValue := MaxMin(AValue, 0, ContentSize.cx - acRectWidth(ClientBounds));
  if AValue <> FViewportX then
  begin
    ADelta := FViewportX - AValue;
    FViewportX := AValue;
    ContentScrolled(ADelta, 0);
  end;
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.SetViewportY(AValue: Integer);
var
  ADelta: Integer;
begin
  AValue := MaxMin(AValue, 0, ContentSize.cy - acRectHeight(ClientBounds));
  if AValue <> FViewportY then
  begin
    ADelta := FViewportY - AValue;
    FViewportY := AValue;
    ContentScrolled(0, ADelta);
  end;
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.ScrollHorzHandler(Sender: TObject; ScrollPos: Integer);
begin
  ViewportX := ScrollPos;
end;

procedure TACLCompoundControlSubClassScrollContainerViewInfo.ScrollVertHandler(Sender: TObject; ScrollPos: Integer);
begin
  ViewportY := ScrollPos;
end;

end.
