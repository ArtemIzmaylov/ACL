{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             ScrollBox Control             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.ScrollBox;

{$I ACL.Config.Inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Classes,
  System.UITypes,
  System.Types,
  // Vcl
  Vcl.Graphics,
  Vcl.Controls,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Resources,
  ACL.Utils.Common;

type
  TACLScrollBoxViewInfo = class;

  { TACLScrollBoxStyle }

  TACLScrollBoxStyle = class(TACLStyleScrollBox)
  protected
    procedure InitializeResources; override;
  public
    procedure DrawBorder(ACanvas: TCanvas; const R: TRect; const ABorders: TACLBorders);
    procedure DrawContent(ACanvas: TCanvas; const R: TRect);
    function IsTransparentBackground: Boolean;
  published
    property ColorBorder1: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorBorder2: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorContent1: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorContent2: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLCustomScrollBox }

  TACLCustomScrollBox = class(TACLCompoundControl)
  strict private
    FBorders: TACLBorders;
    FRedrawLocked: Byte;

    FOnCustomDraw: TACLCustomDrawEvent;

    function GetBordersWidth: TRect;
    function GetStyle: TACLScrollBoxStyle;
    function GetViewInfo: TACLScrollBoxViewInfo;
    function GetViewPoint: TPoint;
    procedure SetBorders(AValue: TACLBorders);
    procedure SetStyle(AValue: TACLScrollBoxStyle);
    procedure SetViewPoint(const Value: TPoint);

    procedure CMFocusChanged(var Message: TCMFocusChanged); message CM_FOCUSCHANGED;
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure BoundsChanged; override;
    procedure CalculateAutoRange;
    function CalculateRange: TSize; virtual;
    procedure CreateParams(var Params: TCreateParams); override;
    function CreateSubClass: TACLCompoundControlSubClass; override;
    function DoCustomDraw(ACanvas: TCanvas; const R: TRect): Boolean;
    procedure DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect); override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    function IsMouseAtControl: Boolean; override;
    function IsRedrawLocked: Boolean;

    // NC
    function TranslatePoint(const SX, SY: SmallInt): TPoint;
    procedure RecalculateNC;
    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMNCLButtonDown(var Message: TWMNCLButtonDown); message WM_NCLBUTTONDOWN;
    procedure WMNCLButtonUp(var Message: TWMNCLButtonUp); message WM_NCLBUTTONUP;
    procedure WMNCMouseMove(var Message: TWMNCMouseMove); message WM_NCMOUSEMOVE;
    procedure WMNCPaint(var Message: TWMNCPaint); message WM_NCPAINT;
    procedure WMSetRedraw(var Message: TMessage); message WM_SETREDRAW;

    property ViewInfo: TACLScrollBoxViewInfo read GetViewInfo;

    property OnCustomDraw: TACLCustomDrawEvent read FOnCustomDraw write FOnCustomDraw;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DisableAutoRange;
    procedure EnableAutoRange;
    procedure InvalidateRect(const R: TRect); override;
    procedure MakeVisible(AControl: TControl); overload;
    procedure MakeVisible(ARect: TRect); overload;
    procedure ScrollBy(DeltaX, DeltaY: Integer); virtual;
    //
    property Borders: TACLBorders read FBorders write SetBorders default acAllBorders;
    property Style: TACLScrollBoxStyle read GetStyle write SetStyle;
    property ViewPoint: TPoint read GetViewPoint write SetViewPoint;
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

  { TACLScrollBoxSubClass }

  TACLScrollBoxSubClass = class(TACLCompoundControlSubClass)
  protected
    function CreateStyleScrollBox: TACLStyleScrollBox; override;
    function CreateViewInfo: TACLCompoundControlCustomViewInfo; override;
  end;

  { TACLScrollBoxViewInfo }

  TACLScrollBoxViewInfo = class(TACLCompoundControlScrollContainerViewInfo)
  strict private
    function GetControl: TACLCustomScrollBox;
  protected
    procedure CalculateContentLayout; override;
    procedure ContentScrolled(ADeltaX: Integer; ADeltaY: Integer); override;
    procedure RecreateSubCells; override;
  end;

implementation

uses
  Vcl.Forms,
  // System
  System.Math,
  System.SysUtils;

function acGetClientRectOnWindow(AHandle: HWND): TRect;
var
  AWindowInfo: TWindowInfo;
begin
  AWindowInfo.cbSize := SizeOf(AWindowInfo);
  GetWindowInfo(AHandle, AWindowInfo);
  Result := acRectOffsetNegative(AWindowInfo.rcClient, AWindowInfo.rcWindow.TopLeft);
end;

{ TACLScrollBoxStyle }

procedure TACLScrollBoxStyle.DrawBorder(ACanvas: TCanvas; const R: TRect; const ABorders: TACLBorders);
begin
  acDrawComplexFrame(ACanvas.Handle, R, ColorBorder1.Value, ColorBorder2.Value, ABorders);
end;

procedure TACLScrollBoxStyle.DrawContent(ACanvas: TCanvas; const R: TRect);
begin
  acDrawGradient(ACanvas.Handle, R, ColorContent1.Value, ColorContent2.Value);
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

{ TACLCustomScrollBox }

constructor TACLCustomScrollBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  FBorders := acAllBorders;
end; 

procedure TACLCustomScrollBox.DisableAutoRange;
begin
  BeginUpdate;
end;

procedure TACLCustomScrollBox.EnableAutoRange;
begin
  EndUpdate;
  if not IsUpdateLocked then
    CalculateAutoRange;
end;

procedure TACLCustomScrollBox.InvalidateRect(const R: TRect);

  function ExcludeOpaqueControls: TACLRegion;
  var
    AControl: TControl;
    AIndex: Integer;
  begin
    Result := TACLRegion.Create;
    for AIndex := 0 to ControlCount - 1 do
    begin
      AControl := Controls[AIndex];
      if (csOpaque in AControl.ControlStyle) and AControl.Visible then
        Result.Combine(AControl.BoundsRect, rcmOr);
    end;
  end;

var
  ARegion: TACLRegion;
begin
  if HandleAllocated and not IsRedrawLocked then
  begin
    ARegion := TACLRegion.CreateRect(R);
    try
      ARegion.Combine(ExcludeOpaqueControls, rcmDiff, True);
      ARegion.Combine(ViewInfo.ScrollBarHorz.Bounds, rcmOr);
      ARegion.Combine(ViewInfo.ScrollBarVert.Bounds, rcmOr);
      RedrawWindow(Handle, nil, ARegion.Handle, RDW_INVALIDATE or RDW_FRAME);
    finally
      ARegion.Free;
    end;
  end;
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
      ARect := acRectOffset(ARect, AParent.BoundsRect.TopLeft);
      AParent := AParent.Parent;
    end;

    if AParent = Self then
      MakeVisible(ARect);
  end;
end;

procedure TACLCustomScrollBox.MakeVisible(ARect: TRect);
var
  AClientHeight: Integer;
  AClientWidth: Integer;
begin
  AClientWidth := ClientWidth;
  if ((ARect.Left >= 0) or (ARect.Right <= AClientWidth)) and (ARect.Width < AClientWidth) then
  begin
    if ARect.Left < 0 then
      ViewInfo.ViewportX := ViewInfo.ViewportX + ARect.Left
    else
      if ARect.Right > AClientWidth then
      begin
        if ARect.Right - ARect.Left > AClientWidth then
          ARect.Right := ARect.Left + AClientWidth;
        ViewInfo.ViewportX := ViewInfo.ViewportX + ARect.Right - AClientWidth;
      end;
  end;

  AClientHeight := ClientHeight;
  if ((ARect.Top >= 0) or (ARect.Bottom <= AClientHeight)) and (ARect.Height < AClientHeight) then
  begin
    if ARect.Top < 0 then
      ViewInfo.ViewportY := ViewInfo.ViewportY + ARect.Top
    else
      if ARect.Bottom > AClientHeight then
      begin
        if ARect.Bottom - ARect.Top > AClientHeight then
          ARect.Bottom := ARect.Top + AClientHeight;
        ViewInfo.ViewportY := ViewInfo.ViewportY + ARect.Bottom - AClientHeight;
      end;
  end;
end;

procedure TACLCustomScrollBox.AdjustClientRect(var Rect: TRect);
begin
  Rect := Bounds(-ViewInfo.ViewportX, -ViewInfo.ViewportY, ClientWidth, ClientHeight);
  inherited AdjustClientRect(Rect);
end;

procedure TACLCustomScrollBox.AlignControls(AControl: TControl; var Rect: TRect);
begin
  for var Step := False to True do
  begin
    CalculateAutoRange;
    inherited AlignControls(AControl, Rect);
  end;
end;

procedure TACLCustomScrollBox.BoundsChanged;
begin
  if SubClass <> nil then
    SubClass.Bounds := acRectContent(Bounds(0, 0, Width, Height), GetBordersWidth);
  RecalculateNC;
end;

procedure TACLCustomScrollBox.CalculateAutoRange;
var
  APrevSBV, APrevSBH: TRect;
begin
  APrevSBH := ViewInfo.ScrollBarHorz.Bounds;
  APrevSBV := ViewInfo.ScrollBarVert.Bounds;
  SubClass.Changed([cccnLayout]);
  if (APrevSBV <> ViewInfo.ScrollBarVert.Bounds) or (APrevSBH <> ViewInfo.ScrollBarHorz.Bounds) then
    RecalculateNC;
end;

function TACLCustomScrollBox.CalculateRange: TSize;

  procedure AdjustHorzAutoRange(AControl: TControl; var ARange, AAlignMargin: Integer);
  begin
    if AControl.Align = alRight then
      Inc(AAlignMargin, AControl.Width)
    else
      if (AControl.Align = alLeft) or (AControl.Align = alNone) and (AControl.Anchors * [akLeft, akRight] = [akLeft]) then
        ARange := Max(ARange, ViewInfo.ViewportX + AControl.BoundsRect.Right);
  end;

  procedure AdjustVertAutoRange(AControl: TControl; var ARange, AAlignMargin: Integer);
  begin
    if AControl.Align = alBottom then
      Inc(AAlignMargin, AControl.Height)
    else
      if (AControl.Align = alTop) or (AControl.Align = alNone) and (AControl.Anchors * [akTop, akBottom] = [akTop]) then
        ARange := Max(ARange, ViewInfo.ViewportY + AControl.BoundsRect.Bottom);
  end;

var
  AAlignMarginHorz, AAlignMarginVert: Integer;
  AControl: TControl;
  ARangeHorz, ARangeVert: Integer;
  I: Integer;
begin
  ARangeHorz := 0;
  ARangeVert := 0;
  AAlignMarginHorz := 0;
  AAlignMarginVert := 0;
  for I := 0 to GetControl.ControlCount - 1 do
  begin
    AControl := GetControl.Controls[I];
    if AControl.Visible then
    begin
      AdjustHorzAutoRange(AControl, ARangeHorz, AAlignMarginHorz);
      AdjustVertAutoRange(AControl, ARangeVert, AAlignMarginVert);
    end;
  end;
  Result := acSize(ARangeHorz + AAlignMarginHorz, ARangeVert + AAlignMarginVert);
end;

procedure TACLCustomScrollBox.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WindowClass.style := 0;
end;

function TACLCustomScrollBox.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLScrollBoxSubClass.Create(Self);
end;

function TACLCustomScrollBox.DoCustomDraw(ACanvas: TCanvas; const R: TRect): Boolean;
begin
  Result := False;
  if Assigned(OnCustomDraw) then
    OnCustomDraw(Self, ACanvas, R, Result);
end;

procedure TACLCustomScrollBox.DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect);
begin
  if not DoCustomDraw(ACanvas, R) then
    Style.DrawContent(ACanvas, R);
end;

function TACLCustomScrollBox.IsMouseAtControl: Boolean;
var
  APoint: TPoint;
begin
  Result := HandleAllocated and IsWindowVisible(Handle);
  if Result then
  begin
    APoint := CalcCursorPos;
    Result := PtInRect(ViewInfo.ScrollBarVert.Bounds, APoint) or PtInRect(ViewInfo.ScrollBarHorz.Bounds, APoint);
  end;
end;

function TACLCustomScrollBox.IsRedrawLocked: Boolean;
begin
  Result := FRedrawLocked > 0;
end;

function TACLCustomScrollBox.TranslatePoint(const SX, SY: SmallInt): TPoint;
begin
  Result := acPointOffsetNegative(Point(SX, SY), acGetWindowRect(Handle).TopLeft);
end;

procedure TACLCustomScrollBox.RecalculateNC;
begin
  if HandleAllocated then
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE or SWP_NOZORDER or SWP_FRAMECHANGED);
end;

procedure TACLCustomScrollBox.WMNCCalcSize(var Message: TWMNCCalcSize);
var
  R: TRect;
begin
  R := acRectContent(Message.CalcSize_Params.rgrc[0], GetBordersWidth);
  Dec(R.Right, ViewInfo.ScrollBarVert.Bounds.Width);
  Dec(R.Bottom, ViewInfo.ScrollBarHorz.Bounds.Height);
  Message.CalcSize_Params.rgrc[0] := R;
end;

procedure TACLCustomScrollBox.WMNCHitTest(var Message: TWMNCHitTest);
begin
  if csDesigning in ComponentState then
  begin
    inherited;
    Exit;
  end;

  SubClass.UpdateHitTest(TranslatePoint(Message.XPos, Message.YPos));
  if SubClass.HitTest.HitObject = SubClass.ViewInfo then
    Message.Result := HTCLIENT
  else
    Message.Result := HTOBJECT;
end;

procedure TACLCustomScrollBox.WMNCLButtonDown(var Message: TWMNCLButtonDown);
begin
  if csDesigning in ComponentState then
    inherited
  else
    with TranslatePoint(Message.XCursor, Message.YCursor) do
      SubClass.MouseDown(mbLeft, KeyboardStateToShiftState, X, Y);
end;

procedure TACLCustomScrollBox.WMNCLButtonUp(var Message: TWMNCLButtonUp);
begin
  if csDesigning in ComponentState then
    inherited
  else
    with TranslatePoint(Message.XCursor, Message.YCursor) do
      SubClass.MouseUp(mbLeft, KeyboardStateToShiftState, X, Y);
end;

procedure TACLCustomScrollBox.WMNCMouseMove(var Message: TWMNCMouseMove);
begin
  if csDesigning in ComponentState then
    inherited
  else
  begin
    with TranslatePoint(Message.XCursor, Message.YCursor) do
      SubClass.MouseMove(KeyboardStateToShiftState, X, Y);
    MouseTracker.Add(Self);
  end;
end;

procedure TACLCustomScrollBox.WMNCPaint(var Message: TWMNCPaint);
var
  AClienRect: TRect;
  ALayer: TACLBitmapLayer;
  AWindowDC: HDC;
begin
  if (Width > 0) and (Height > 0) then
  begin
    ALayer := TACLBitmapLayer.Create(BoundsRect);
    try
      AClienRect := acGetClientRectOnWindow(Handle);
      acExcludeFromClipRegion(ALayer.Handle, AClienRect);
      SubClass.Draw(ALayer.Canvas);
      Style.DrawBorder(ALayer.Canvas, ALayer.ClientRect, Borders);

      AWindowDC := GetWindowDC(Handle);
      acExcludeFromClipRegion(AWindowDC, AClienRect);
      ALayer.DrawCopy(AWindowDC, NullPoint);
      ReleaseDC(Handle, AWindowDC);
    finally
      ALayer.Free;
    end;
  end;
end;

procedure TACLCustomScrollBox.WMSetRedraw(var Message: TMessage);
begin
  inherited;
  if Message.WParam = 0 then
    Inc(FRedrawLocked)
  else
    Dec(FRedrawLocked);
end;

function TACLCustomScrollBox.GetBordersWidth: TRect;
begin
  Result := acMarginGetReal(acBorderOffsets, Borders);
end;

function TACLCustomScrollBox.GetStyle: TACLScrollBoxStyle;
begin
  Result := TACLScrollBoxStyle(StyleScrollBox);
end;

function TACLCustomScrollBox.GetViewInfo: TACLScrollBoxViewInfo;
begin
  Result := TACLScrollBoxViewInfo(SubClass.ViewInfo);
end;

function TACLCustomScrollBox.GetViewPoint: TPoint;
begin
  Result := Point(ViewInfo.ViewportX, ViewInfo.ViewportY);
end;

function TACLCustomScrollBox.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if Transparent then
    Result := cbsTransparent
  else
    if Style.IsTransparentBackground then
      Result := cbsSemitransparent
    else
      Result := cbsOpaque;
end;

procedure TACLCustomScrollBox.ScrollBy(DeltaX, DeltaY: Integer);
begin
  inherited;
  Update;
end;

procedure TACLCustomScrollBox.SetBorders(AValue: TACLBorders);
begin
  if AValue <> FBorders then
  begin
    FBorders := AValue;
    BoundsChanged;
    Realign;
  end;
end;

procedure TACLCustomScrollBox.SetStyle(AValue: TACLScrollBoxStyle);
begin
  StyleScrollBox.Assign(AValue);
end;

procedure TACLCustomScrollBox.SetViewPoint(const Value: TPoint);
begin
  ViewInfo.ViewportX := Value.X;
  ViewInfo.ViewportY := Value.Y;
end;

procedure TACLCustomScrollBox.CMFocusChanged(var Message: TCMFocusChanged);
begin
  inherited;
  MakeVisible(Message.Sender);
end;

{ TACLScrollBoxSubClass }

function TACLScrollBoxSubClass.CreateStyleScrollBox: TACLStyleScrollBox;
begin
  Result := TACLScrollBoxStyle.Create(Self);
end;

function TACLScrollBoxSubClass.CreateViewInfo: TACLCompoundControlCustomViewInfo;
begin
  Result := TACLScrollBoxViewInfo.Create(Self);
end;

{ TACLScrollBoxViewInfo }

procedure TACLScrollBoxViewInfo.CalculateContentLayout;
begin
  FContentSize := GetControl.CalculateRange;
end;

procedure TACLScrollBoxViewInfo.ContentScrolled(ADeltaX, ADeltaY: Integer);
begin
  GetControl.ScrollBy(ADeltaX, ADeltaY);
end;

procedure TACLScrollBoxViewInfo.RecreateSubCells;
begin
  // do nothing
end;

function TACLScrollBoxViewInfo.GetControl: TACLCustomScrollBox;
begin
  Result := SubClass.Container.GetControl as TACLCustomScrollBox;
end;

end.
