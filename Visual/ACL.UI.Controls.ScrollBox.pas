////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   ScrollBox
//
//  Author:    Artem Izmaylov
//             © 2006-2024
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
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Resources,
  ACL.Utils.Common;

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

  { TACLCustomScrollingControl }

  TACLCustomScrollingControl = class(TACLCustomInplaceContainer)
  strict private
    FBorders: TBorderStyle;
    FHorzScrollBar: TACLScrollBar;
    FVertScrollBar: TACLScrollBar;
    FSizeGrip: TACLCustomControl;
    FStyle: TACLScrollBoxStyle;

    FOnCustomDraw: TACLCustomDrawEvent;

    function CreateScrollBar(AKind: TScrollBarKind): TACLScrollBar;
    procedure SetBorders(AValue: TBorderStyle);
    procedure SetStyle(AValue: TACLScrollBoxStyle);
  protected
    procedure AdjustClientRect(var ARect: TRect); override;
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    procedure AlignScrollBars(const ARect: TRect); virtual;
    function CreateStyle: TACLScrollBoxStyle; virtual;
    procedure CreateWnd; override;
    function IsInternalControl(AControl: TControl): Boolean;
    procedure Paint; override;
    procedure PaintWindow(DC: HDC); override;
    procedure Scroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer); virtual;
    procedure ScrollContent(dX, dY: Integer); virtual;
    procedure SetScrollParams(ABar: TACLScrollBar; AClientSize, AContentSize: Integer);
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateBorders(AJustCreated: Boolean = False);
    procedure UpdateTransparency; override;
    //# Messages
    procedure WMNCCalcSize(var Msg: TMessage); message WM_NCCALCSIZE;
    procedure WMNCPaint(var Msg: TMessage); message WM_NCPAINT;
    //# Events
    property OnCustomDraw: TACLCustomDrawEvent read FOnCustomDraw write FOnCustomDraw;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ScrollBy(dX, dY: Integer); {$IFDEF FPC}override; final;{$ENDIF}
    //# Properties
    property Borders: TBorderStyle read FBorders write SetBorders default bsSingle;
    property HorzScrollBar: TACLScrollBar read FHorzScrollBar;
    property VertScrollBar: TACLScrollBar read FVertScrollBar;
    property Style: TACLScrollBoxStyle read FStyle write SetStyle;
  end;

  { TACLCustomScrollBox }

  TACLCustomScrollBox = class(TACLCustomScrollingControl)
  strict private
    FAutoRangeLockCount: Integer;
    FFocusing: Boolean;
  protected
    procedure AlignScrollBars(const ARect: TRect); override;
    function CalculateRange: TSize; virtual;
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
    property Borders;
    property ResourceCollection;
    property Style;
    property Transparent;
    property OnCustomDraw;
  end;

implementation

{$IFDEF LCLGtk2}
uses
  ACL.UI.Core.Impl.Gtk2;
{$ENDIF}

type

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

{ TACLCustomScrollingControl }

constructor TACLCustomScrollingControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  FBorders := bsSingle;
  FSizeGrip := TACLSizeGrip.Create(Self);
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
end;

procedure TACLCustomScrollingControl.AlignScrollBars(const ARect: TRect);
begin
  HorzScrollBar.BringToFront;
  HorzScrollBar.SetBounds(ARect.Left, ARect.Bottom, ARect.Width, HorzScrollBar.Height);
  HorzScrollBar.Tag := HorzScrollBar.Position;

  VertScrollBar.BringToFront;
  VertScrollBar.SetBounds(ARect.Right, ARect.Top, VertScrollBar.Width, ARect.Height);
  VertScrollBar.Tag := VertScrollBar.Position;

  FSizeGrip.BringToFront;
  FSizeGrip.SetBounds(ARect.Right, ARect.Bottom, VertScrollBar.Width, HorzScrollBar.Height);
  FSizeGrip.Visible := VertScrollBar.Visible and HorzScrollBar.Visible;
end;

function TACLCustomScrollingControl.CreateScrollBar(AKind: TScrollBarKind): TACLScrollBar;
begin
  Result := TACLScrollBar.CreateEx(Self, AKind, Style, soReference);
  Result.Align := alCustom;
  Result.OnScroll := Scroll;
  Result.Parent := Self;
end;

function TACLCustomScrollingControl.CreateStyle: TACLScrollBoxStyle;
begin
  Result := TACLScrollBoxStyle.Create(Self);
end;

procedure TACLCustomScrollingControl.CreateWnd;
begin
  inherited CreateWnd;
  UpdateBorders(True);
end;

function TACLCustomScrollingControl.IsInternalControl(AControl: TControl): Boolean;
begin
  Result := (AControl = HorzScrollBar) or (AControl = VertScrollBar) or (AControl = FSizeGrip);
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
begin
  if FSizeGrip.Visible then
    acExcludeFromClipRegion(DC, FSizeGrip.BoundsRect);
  if HorzScrollBar.Visible then
    acExcludeFromClipRegion(DC, HorzScrollBar.BoundsRect);
  if VertScrollBar.Visible then
    acExcludeFromClipRegion(DC, VertScrollBar.BoundsRect);
  inherited;
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
    ScrollContent(dX, dY);
end;

procedure TACLCustomScrollingControl.ScrollContent(dX, dY: Integer);
begin
  // do nothing
end;

procedure TACLCustomScrollingControl.SetBorders(AValue: TBorderStyle);
begin
  if AValue <> FBorders then
  begin
    FBorders := AValue;
    if HandleAllocated then
      UpdateBorders;
    Realign;
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

procedure TACLCustomScrollingControl.UpdateBorders(AJustCreated: Boolean);
begin
{$IF DEFINED(LCLGtk2)}
  TGtk2Controls.SetNonClientBorder(Self, IfThen(Borders = bsSingle, 2, 0));
{$ELSEIF DEFINED(MSWINDOWS)}
  if not AJustCreated then
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE or SWP_NOZORDER or SWP_FRAMECHANGED);
{$IFEND}
end;

procedure TACLCustomScrollingControl.UpdateTransparency;
begin
  if Transparent or Style.IsTransparentBackground then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque];
end;

procedure TACLCustomScrollingControl.WMNCCalcSize(var Msg: TMessage);
begin
{$IFDEF MSWINDOWS}
  if Borders = bsSingle then
    TWMNCCalcSize(Msg).CalcSize_Params.rgrc[0].Inflate(-2, -2);
{$ENDIF}
end;

procedure TACLCustomScrollingControl.WMNCPaint(var Msg: TMessage);

  procedure DoDrawBorder(DC: HDC);
  begin
    Canvas.Handle := DC;
    try
      Style.DrawBorder(Canvas, Rect(0, 0, Width, Height), acAllBorders);
    finally
      Canvas.Handle := 0;
    end;
  end;

begin
  if Borders = bsSingle then
  begin
  {$IF DEFINED(LCLGtk2)}
    DoDrawBorder(Msg.LParam);
  {$ELSEIF DEFINED(MSWINDOWS)}
    var DC := GetWindowDC(Handle);
    try
      DoDrawBorder(DC);
    finally
      ReleaseDC(Handle, DC);
    end;
  {$IFEND}
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
  AAlignMarginHorz: Integer;
  AAlignMarginVert: Integer;
  AControl: TControl;
  ARangeHorz: Integer;
  ARangeVert: Integer;
  I: Integer;
begin
  ARangeHorz := 0;
  ARangeVert := 0;
  AAlignMarginHorz := 0;
  AAlignMarginVert := 0;
  for I := 0 to ControlCount - 1 do
  begin
    AControl := Controls[I];
    if AControl.Visible and not IsInternalControl(AControl) then
    begin
      AdjustHorzAutoRange(AControl, ARangeHorz, AAlignMarginHorz);
      AdjustVertAutoRange(AControl, ARangeVert, AAlignMarginVert);
    end;
  end;
  Result := TSize.Create(ARangeHorz + AAlignMarginHorz, ARangeVert + AAlignMarginVert);
end;

procedure TACLCustomScrollBox.CMFocusChanged(var Msg: TMessage);
begin
  inherited;
{$IFDEF FPC}
  {$MESSAGE 'TODO - CMFocusChanged - not implemented'}
{$ELSE}
  FFocusing := True;
  MakeVisible(TCMFocusChanged(Msg).Sender);
  FFocusing := False;
{$ENDIF}
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
  AInnerControl: IACLInnerControl;
  AParent: TWinControl;
  ARect: TRect;
begin
  if Supports(AControl, IACLInnerControl, AInnerControl) then
    MakeVisible(AInnerControl.GetInnerContainer)
  else
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

end.
