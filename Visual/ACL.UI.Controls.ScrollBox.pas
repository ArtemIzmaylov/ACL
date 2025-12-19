////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   ScrollBox
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.ScrollBox;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
  WSLCLClasses,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
  {Vcl.}StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

type

  { TACLScrollBoxStyle }

  TACLScrollBoxStyle = class(TACLStyleScrollBox)
  protected
    procedure InitializeResources; override;
  public
    procedure DrawBorder(ACanvas: TCanvas;
      const R: TRect; const ABorders: TACLBorders); virtual;
    procedure DrawContent(ACanvas: TCanvas; const R: TRect);
    function IsTransparentBackground: Boolean;
  published
    property ColorBorder1: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorBorder2: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorContent1: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorContent2: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLAbstractScrollingControl }

  TACLAbstractScrollingControl = class(TACLCustomControl)
  {$IFDEF FPC}
  protected
    class procedure WSRegisterClass; override;
  {$ELSE}
  strict private
    FBorderStyle: TBorderStyle;
    procedure SetBorderStyle(AValue: TBorderStyle);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
  {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
  end;

  { TACLCustomScrollingControl }

  TACLCustomScrollingControl = class(TACLAbstractScrollingControl)
  strict private
    FHorzScrollBar: TACLScrollBar;
    FVertScrollBar: TACLScrollBar;
    FSizeGrip: TACLCustomControl;
    FStyle: TACLScrollBoxStyle;

    FOnCustomDraw: TACLCustomDrawEvent;

    procedure BringInternalControlsToTop;
    function CreateScrollBar(AKind: TScrollBarKind): TACLScrollBar;
    procedure SetStyle(AValue: TACLScrollBoxStyle);
  protected
    FZOrderValidationLock: Integer;

    procedure AdjustClientRect(var ARect: TRect); override;
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    procedure AlignScrollBars(const ARect: TRect); virtual;
    function CreateStyle: TACLScrollBoxStyle; virtual;
    function IsInternalControl(AControl: TControl): Boolean;
    procedure Paint; override;
    procedure PaintWindow(DC: HDC); override;
    procedure Scroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer); virtual;
    procedure ScrollContent(dX, dY: Integer); virtual;
    procedure SetScrollParams(ABar: TACLScrollBar; AClientSize, AContentSize: Integer);
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateTransparency; override;
    //# Messages
    procedure WMNCPaint(var Msg: TMessage); message WM_NCPAINT;
    //# Events
    property OnCustomDraw: TACLCustomDrawEvent read FOnCustomDraw write FOnCustomDraw;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  {$IFDEF FPC}
    procedure InvalidatePreferredSize; override;
  {$ENDIF}
    procedure ScrollBy(dX, dY: Integer); {$IFDEF FPC}override; final;{$ENDIF}
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    //# Properties
    property Style: TACLScrollBoxStyle read FStyle write SetStyle;
    property HorzScrollBar: TACLScrollBar read FHorzScrollBar;
    property VertScrollBar: TACLScrollBar read FVertScrollBar;
  end;

  { TACLCustomScrollBox }

  TACLCustomScrollBox = class(TACLCustomScrollingControl)
  strict private
    FAutoRangeLockCount: Integer;
    FFocusing: Boolean;
  protected
    procedure AlignScrollBars(const ARect: TRect); override;
    function CalculateRange: TSize; virtual;
    function MouseWheel(Direction: TACLMouseWheelDirection;
      Shift: TShiftState; const MousePos: TPoint): Boolean; override;
    procedure ScrollContent(dX, dY: Integer); override;
    //# Messages
    procedure CMFocusChanged(var Msg: TMessage); message CM_FOCUSCHANGED;
  public
    procedure DisableAutoRange;
    procedure EnableAutoRange;
    procedure MakeVisible(AControl: TControl); overload;
    procedure MakeVisible(ARect: TRect); overload;
  end;

  { TACLScrollBox }

  TACLScrollBox = class(TACLCustomScrollBox)
  published
    property BorderStyle;
    property ResourceCollection;
    property Style;
    property Transparent;
    property OnCustomDraw;
  end;

implementation

uses
{$I ACL.UI.Core.Impl.inc};

type

  { TACLInnerScrollBar }

  TACLInnerScrollBar = class(TACLScrollBar)
  protected
    procedure MouseEnter; override;
    procedure UpdateTransparency; override;
  end;

  { TACLSizeGrip }

  TACLSizeGrip = class(TACLCustomControl)
  public
    procedure Paint; override;
  end;

{ TACLSizeGrip }

procedure TACLSizeGrip.Paint;
begin
  TACLCustomScrollingControl(Parent).Style.DrawSizeGripArea(Canvas, ClientRect);
end;

{ TACLScrollBoxStyle }

procedure TACLScrollBoxStyle.DrawBorder(
  ACanvas: TCanvas; const R: TRect; const ABorders: TACLBorders);
begin
  acDrawComplexFrame(ACanvas, R,
    ColorBorder1.AsColor, ColorBorder2.AsColor, ABorders);
end;

procedure TACLScrollBoxStyle.DrawContent(ACanvas: TCanvas; const R: TRect);
begin
  acDrawGradient(ACanvas, R, ColorContent1.Value, ColorContent2.Value);
end;

function TACLScrollBoxStyle.IsTransparentBackground: Boolean;
begin
  Result := acIsSemitransparentFill(ColorContent1, ColorContent2);
end;

procedure TACLScrollBoxStyle.InitializeResources;
begin
  inherited;
  ColorBorder1.InitailizeDefaults('Common.Colors.Border1', True);
  ColorBorder2.InitailizeDefaults('Common.Colors.Border2', True);
  ColorContent1.InitailizeDefaults('Common.Colors.Background1', True);
  ColorContent2.InitailizeDefaults('Common.Colors.Background2', True);
end;

{ TACLAbstractScrollingControl }

constructor TACLAbstractScrollingControl.Create(AOwner: TComponent);
begin
  inherited;
  BorderStyle := bsSingle;
end;

{$IFDEF FPC}
class procedure TACLAbstractScrollingControl.WSRegisterClass;
begin
  RegisterWSComponent(TACLAbstractScrollingControl, TACLWSScrollingControl);
end;
{$ELSE}
procedure TACLAbstractScrollingControl.CreateParams(var Params: TCreateParams);
begin
  inherited;
  if BorderStyle = bsSingle then
    Params.ExStyle := Params.ExStyle or WS_EX_CLIENTEDGE;
end;

procedure TACLAbstractScrollingControl.SetBorderStyle(AValue: TBorderStyle);
const
  SWP_RECALC_NC = SWP_NOSIZE or SWP_NOMOVE or SWP_NOZORDER or SWP_FRAMECHANGED;
var
  LStyle: Cardinal;
begin
  if FBorderStyle <> AValue then
  begin
    FBorderStyle := AValue;
    if HandleAllocated then
    begin
      LStyle := GetWindowLong(Handle, GWL_EXSTYLE);
      if FBorderStyle = bsSingle then
        LStyle := LStyle or WS_EX_CLIENTEDGE
      else
        LStyle := LStyle and not WS_EX_CLIENTEDGE;
      SetWindowLong(Handle, GWL_EXSTYLE, LStyle);
      SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_RECALC_NC);
      Realign;
    end;
  end;
end;
{$ENDIF}

{ TACLCustomScrollingControl }

constructor TACLCustomScrollingControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  FSizeGrip := TACLSizeGrip.Create(Self);
  FSizeGrip.Align := alCustom;
  FSizeGrip.Enabled := False;
  FSizeGrip.Visible := False;
  FSizeGrip.Parent := Self;
  FStyle := CreateStyle;
  FHorzScrollBar := CreateScrollBar(sbHorizontal);
  FVertScrollBar := CreateScrollBar(sbVertical);
end;

destructor TACLCustomScrollingControl.Destroy;
begin
  FreeAndNil(FHorzScrollBar);
  FreeAndNil(FVertScrollBar);
  FreeAndNil(FSizeGrip);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLCustomScrollingControl.AdjustClientRect(var ARect: TRect);
begin
  if VertScrollBar.Visible then
    Dec(ARect.Right, VertScrollBar.Width);
  if HorzScrollBar.Visible then
    Dec(ARect.Bottom, HorzScrollBar.Height);
end;

procedure TACLCustomScrollingControl.AlignControls(AControl: TControl; var ARect: TRect);
var
  LStep: Boolean;
begin
  for LStep := False to True do
  begin
    ARect := ClientRect;
    inherited AlignControls(AControl, ARect);
    ARect := ClientRect;
    AdjustClientRect(ARect);
    AlignScrollBars(ARect);
  end;
  BringInternalControlsToTop;
end;

procedure TACLCustomScrollingControl.AlignScrollBars(const ARect: TRect);
begin
  FHorzScrollBar.SetBounds(ARect.Left, ARect.Bottom, ARect.Width, HorzScrollBar.Height);
  FHorzScrollBar.Tag := HorzScrollBar.Position;
  FHorzScrollBar.SmallChange := dpiApply(16, FCurrentPPI);
  FVertScrollBar.SetBounds(ARect.Right, ARect.Top, VertScrollBar.Width, ARect.Height);
  FVertScrollBar.SmallChange := dpiApply(16, FCurrentPPI);
  FVertScrollBar.Tag := VertScrollBar.Position;
  FSizeGrip.SetBounds(ARect.Right, ARect.Bottom, VertScrollBar.Width, HorzScrollBar.Height);
  FSizeGrip.Visible := VertScrollBar.Visible and HorzScrollBar.Visible;
end;

procedure TACLCustomScrollingControl.BringInternalControlsToTop;
begin
  if FZOrderValidationLock = 0 then
  begin
    FHorzScrollBar.BringToFront;
    FVertScrollBar.BringToFront;
    FSizeGrip.BringToFront;
  end;
end;

function TACLCustomScrollingControl.CreateScrollBar(AKind: TScrollBarKind): TACLScrollBar;
begin
  Result := TACLInnerScrollBar.CreateEx(Self, AKind, Style, soReference);
  Result.OnScroll := Scroll;
  Result.Align := alCustom;
  Result.Parent := Self;
end;

function TACLCustomScrollingControl.CreateStyle: TACLScrollBoxStyle;
begin
  Result := TACLScrollBoxStyle.Create(Self);
end;

{$IFDEF FPC}
procedure TACLCustomScrollingControl.InvalidatePreferredSize;
begin
  // Realize -> CNPreferredSizeChanged -> InvalidatePreferredSize;
  inherited InvalidatePreferredSize;
  if HandleAllocated then
    BringInternalControlsToTop;
end;
{$ENDIF}

function TACLCustomScrollingControl.IsInternalControl(AControl: TControl): Boolean;
begin
  Result :=
    (AControl = HorzScrollBar) or
    (AControl = VertScrollBar) or
    (AControl = FSizeGrip);
end;

procedure TACLCustomScrollingControl.Paint;
var
  LHandled: Boolean;
begin
  LHandled := False;
  if Assigned(OnCustomDraw) then
    OnCustomDraw(Self, Canvas, ClientRect, LHandled);
  if not (LHandled or Transparent) then
    Style.DrawContent(Canvas, ClientRect);
end;

procedure TACLCustomScrollingControl.PaintWindow(DC: HDC);
{$IFDEF MSWINDOWS}
var
  LRgn: TRegionHandle;
begin
  // ScrollBy anti-flickering workaround
  LRgn := acSaveClipRegion(DC);
  try
    if FSizeGrip.Visible then
      acExcludeFromClipRegion(DC, FSizeGrip.BoundsRect);
    if HorzScrollBar.Visible then
      acExcludeFromClipRegion(DC, HorzScrollBar.BoundsRect);
    if VertScrollBar.Visible then
      acExcludeFromClipRegion(DC, VertScrollBar.BoundsRect);
    inherited;
  finally
    acRestoreClipRegion(DC, LRgn);
  end;
  if FSizeGrip.Visible then
    FSizeGrip.PaintTo(DC, FSizeGrip.Left, FSizeGrip.Top);
  if HorzScrollBar.Visible then
    HorzScrollBar.PaintTo(DC, HorzScrollBar.Left, HorzScrollBar.Top);
  if VertScrollBar.Visible then
    VertScrollBar.PaintTo(DC, VertScrollBar.Left, VertScrollBar.Top);
{$ELSE}
begin
  inherited;
{$ENDIF}
end;

procedure TACLCustomScrollingControl.Scroll(
  Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  if Sender = HorzScrollBar then
    ScrollBy(HorzScrollBar.Tag - ScrollPos, 0);
  if Sender = VertScrollBar then
    ScrollBy(0, VertScrollBar.Tag - ScrollPos);
  if ScrollCode = TScrollCode.scTrack then
    Update;
end;

procedure TACLCustomScrollingControl.ScrollBy(dX, dY: Integer);

  procedure TryScroll(var ADelta: Integer; AScrollBar: TACLScrollBar);
  begin
    if ADelta <> 0 then
    begin
      AScrollBar.Position := AScrollBar.Tag - ADelta;
      ADelta := AScrollBar.Tag - AScrollBar.Position;
      AScrollBar.Tag := AScrollBar.Position;
    end;
  end;

begin
  TryScroll(dX, HorzScrollBar);
  TryScroll(dY, VertScrollBar);
  if (dX <> 0) or (dY <> 0) then
  begin
    Inc(FZOrderValidationLock);
    try
      ScrollContent(dX, dY);
    finally
      Dec(FZOrderValidationLock);
    end;
  end;
end;

procedure TACLCustomScrollingControl.ScrollContent(dX, dY: Integer);
begin
  // do nothing
end;

procedure TACLCustomScrollingControl.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  Inc(FZOrderValidationLock);
  try
    inherited;
  finally
    Dec(FZOrderValidationLock);
  end;
end;

procedure TACLCustomScrollingControl.SetStyle(AValue: TACLScrollBoxStyle);
begin
  FStyle.Assign(AValue);
end;

procedure TACLCustomScrollingControl.SetScrollParams(
  ABar: TACLScrollBar; AClientSize, AContentSize: Integer);
var
  LScrollPos: Integer;
begin
  ABar.Visible := AContentSize > AClientSize;
  ABar.SetScrollParams(0, AContentSize, ABar.Position, AClientSize);
  LScrollPos := ABar.Position;
  if LScrollPos <> ABar.Tag then
    Scroll(ABar, scEndScroll, LScrollPos);
end;

procedure TACLCustomScrollingControl.SetTargetDPI(AValue: Integer);
begin
  Style.TargetDPI := AValue;
  inherited SetTargetDPI(AValue);
end;

procedure TACLCustomScrollingControl.UpdateTransparency;
begin
  if Transparent or Style.IsTransparentBackground then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque];
end;

procedure TACLCustomScrollingControl.WMNCPaint(var Msg: TMessage);
begin
  if BorderStyle <> bsNone then
  begin
    if Msg.LParam = 0 then
      TACLWSScrollingControl.DispatchNonClientMessage(Self, Msg)
    else // Message from TACLWSScrollingControl
    begin
      Canvas.Lock;
      try
        Canvas.Handle := Msg.LParam;
        Style.DrawBorder(Canvas, Rect(0, 0, Width, Height), acAllBorders);
      finally
        Canvas.Handle := 0;
        Canvas.Unlock;
      end;
    end;
  end;
end;

{ TACLCustomScrollBox }

procedure TACLCustomScrollBox.AlignScrollBars(const ARect: TRect);
var
  LSize: TSize;
begin
  if FAutoRangeLockCount = 0 then
  begin
    LSize := CalculateRange;
    SetScrollParams(VertScrollBar, ARect.Height, LSize.Height);
    SetScrollParams(HorzScrollBar, ARect.Width, LSize.Width);
  end;
  inherited;
end;

function TACLCustomScrollBox.CalculateRange: TSize;

  procedure AdjustHorzAutoRange(AControl: TControl; var ARange, AAlignMargin: Integer);
  begin
    if AControl.Align = alRight then
      Inc(AAlignMargin, AControl.Width)
    else
      if (AControl.Align = alLeft) or
         (AControl.Align = alNone) and (AControl.Anchors * [akLeft, akRight] = [akLeft])
      then
        ARange := Max(ARange, HorzScrollBar.Position + AControl.BoundsRect.Right);
  end;

  procedure AdjustVertAutoRange(AControl: TControl; var ARange, AAlignMargin: Integer);
  begin
    if AControl.Align = alBottom then
      Inc(AAlignMargin, AControl.Height)
    else
      if (AControl.Align = alTop) or
         (AControl.Align = alNone) and (AControl.Anchors * [akTop, akBottom] = [akTop])
      then
        ARange := Max(ARange, VertScrollBar.Position + AControl.BoundsRect.Bottom);
  end;

var
  LAlignMarginHorz: Integer;
  LAlignMarginVert: Integer;
  LControl: TControl;
  LRangeHorz: Integer;
  LRangeVert: Integer;
  I: Integer;
begin
  LRangeHorz := 0;
  LRangeVert := 0;
  LAlignMarginHorz := 0;
  LAlignMarginVert := 0;
  for I := 0 to ControlCount - 1 do
  begin
    LControl := Controls[I];
    if LControl.Visible and not IsInternalControl(LControl) then
    begin
      AdjustHorzAutoRange(LControl, LRangeHorz, LAlignMarginHorz);
      AdjustVertAutoRange(LControl, LRangeVert, LAlignMarginVert);
    end;
  end;
  Result := TSize.Create(LRangeHorz + LAlignMarginHorz, LRangeVert + LAlignMarginVert);
end;

procedure TACLCustomScrollBox.CMFocusChanged(var Msg: TMessage);
begin
  inherited;
  FFocusing := True;
  try
    MakeVisible(TControl(Msg.LParam));
  finally
    FFocusing := False;
  end;
end;

function TACLCustomScrollBox.MouseWheel(Direction: TACLMouseWheelDirection;
  Shift: TShiftState; const MousePos: TPoint): Boolean;
var
  LBar: TACLInnerScrollBar;
begin
  if ssShift in Shift then
    LBar := TACLInnerScrollBar(HorzScrollBar)
  else
    LBar := TACLInnerScrollBar(VertScrollBar);

  Result := (LBar <> nil) and LBar.Visible and LBar.MouseWheel(Direction, Shift, MousePos);
end;

procedure TACLCustomScrollBox.DisableAutoRange;
begin
  Inc(FAutoRangeLockCount)
end;

procedure TACLCustomScrollBox.EnableAutoRange;
begin
  Dec(FAutoRangeLockCount);
  if FAutoRangeLockCount = 0 then
    Realign;
end;

procedure TACLCustomScrollBox.MakeVisible(AControl: TControl);
var
  AParent: TWinControl;
  ARect: TRect;
begin
  if AControl <> nil then
  begin
    HandleNeeded;
    ARect := AControl.BoundsRect;

    AParent := AControl.Parent;
    while (AParent <> nil) and (AParent <> Self) do
    begin
      ARect.Offset(AParent.BoundsRect.TopLeft);
      AParent := AParent.Parent;
    end;

    if AParent = Self then
      MakeVisible(ARect);
  end;
end;

procedure TACLCustomScrollBox.MakeVisible(ARect: TRect);
var
  LClientRect: TRect;
  LScrollBy: TPoint;
begin
  LScrollBy := NullPoint;
  LClientRect := ClientRect;
  AdjustClientRect(LClientRect);

  if not FFocusing then
  begin
    if ARect.Width > LClientRect.Width then
      ARect.Width := LClientRect.Width;
    if ARect.Height > LClientRect.Height then
      ARect.Height := LClientRect.Height;
  end;

  if ARect.Width <= LClientRect.Width then
  begin
    if ARect.Left < LClientRect.Left then
      LScrollBy.X := -ARect.Left
    else
      if ARect.Right > LClientRect.Right then
      begin
        if ARect.Right - ARect.Left > LClientRect.Right then
          ARect.Right := ARect.Left + LClientRect.Right;
        LScrollBy.X := LClientRect.Right - ARect.Right;
      end;
  end;

  if ARect.Height <= LClientRect.Height then
  begin
    if ARect.Top < LClientRect.Top then
      LScrollBy.Y := -ARect.Top
    else
      if ARect.Bottom > LClientRect.Bottom then
      begin
        if ARect.Bottom - ARect.Top > LClientRect.Bottom then
          ARect.Bottom := ARect.Top + LClientRect.Bottom;
        LScrollBy.Y := LClientRect.Bottom - ARect.Bottom;
      end;
  end;

  ScrollBy(LScrollBy.X, LScrollBy.Y);
end;

procedure TACLCustomScrollBox.ScrollContent(dX, dY: Integer);
var
  LControl: TControl;
  LDeferUpdate: TACLDeferPlacementUpdate;
  I: Integer;
begin
  LDeferUpdate := TACLDeferPlacementUpdate.Create;
  try
    for I := 0 to ControlCount - 1 do
    begin
      LControl := Controls[I];
      if not IsInternalControl(LControl) then
        LDeferUpdate.Add(LControl, LControl.BoundsRect.OffsetTo(dX, dY));
    end;
    LDeferUpdate.Apply;
  finally
    LDeferUpdate.Free;
  end;
end;

{ TACLInnerScrollBar }

procedure TACLInnerScrollBar.MouseEnter;
begin
  inherited;
  TACLMouseTracker.Start(Parent as TACLCustomScrollingControl);
end;

procedure TACLInnerScrollBar.UpdateTransparency;
begin
  ControlStyle := ControlStyle + [csOpaque];
end;

end.
