{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             ScrollBox Control             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.ScrollBox;

{$I ACL.Config.inc} // FPC:OK

{$IFNDEF FPC}
  // Для кроссплатформенной реализации, скроллбокс кладет все дочерние контролы
  // на специальный контрол-подложку. Однако в Delphi в design-time этот подход
  // не работает. Delphi "не видит" подложку и неправильно строит дерево Structure.
  {$DEFINE SB_DT_WORKAROUND}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Messages,
  {Winapi.}Windows,
{$ENDIF}
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
  // ACL
  ACL.Geometry,
  ACL.Geometry.Utils,
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
    FContentHost: TWinControl;

    FOnCustomDraw: TACLCustomDrawEvent;

    function GetBordersWidth: TRect;
    function GetStyle: TACLScrollBoxStyle;
    function GetViewInfo: TACLScrollBoxViewInfo;
    function GetViewPoint: TPoint;
    procedure SetBorders(AValue: TACLBorders);
    procedure SetStyle(AValue: TACLScrollBoxStyle);
    procedure SetViewPoint(const Value: TPoint);
  protected
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure BoundsChanged; override;
    function CalculateRange(AContentHost: TWinControl): TSize; virtual;
    function CreateSubClass: TACLCompoundControlSubClass; override;
    procedure Paint; override;
    procedure UpdateTransparency; override;
  {$IFNDEF FPC}
    procedure WndProc(var Message: TMessage); override;
  {$ENDIF}
    //# Properties
    property ContentHost: TWinControl read FContentHost;
    property ViewInfo: TACLScrollBoxViewInfo read GetViewInfo;
    //# Events
    property OnCustomDraw: TACLCustomDrawEvent read FOnCustomDraw write FOnCustomDraw;
  public
    constructor Create(AOwner: TComponent); override;
  {$IFDEF FPC}
    procedure InsertControl(AControl: TControl; Index: Integer); override;
  {$ENDIF}
    procedure DisableAutoRange;
    procedure EnableAutoRange;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure MakeVisible(AControl: TControl); overload;
    procedure MakeVisible(ARect: TRect); overload;
    procedure ScrollBy(DeltaX, DeltaY: Integer); reintroduce;
    //# Properties
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

  { TACLScrollBoxContentHost }

  TACLScrollBoxContentHost = class(TACLCustomControl)
  protected
    procedure AdjustClientRect(var ARect: TRect); override;
    procedure Paint; override;
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
  end;

implementation

{ TACLScrollBoxStyle }

procedure TACLScrollBoxStyle.DrawBorder(ACanvas: TCanvas; const R: TRect; const ABorders: TACLBorders);
begin
  acDrawComplexFrame(ACanvas, R, ColorBorder1.Value, ColorBorder2.Value, ABorders);
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

{ TACLCustomScrollBox }

constructor TACLCustomScrollBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  FContentHost := TACLScrollBoxContentHost.Create(Self);
{$IFDEF SB_DT_WORKAROUND}
  FContentHost.ControlStyle := FContentHost.ControlStyle + [csNoDesignVisible];
{$ENDIF}
  FContentHost.SetSubComponent(True);
  FContentHost.Parent := Self;
  FBorders := acAllBorders;
end;

procedure TACLCustomScrollBox.AlignControls(AControl: TControl; var Rect: TRect);
var
  LStep: Boolean;
begin
{$IFDEF SB_DT_WORKAROUND}
  if csDesigning in ComponentState then
    inherited;
{$ENDIF}
  for LStep := False to True do
  begin
    SubClass.Changed([cccnLayout]);
    ContentHost.BoundsRect := ViewInfo.ClientBounds;
  end;
end;

procedure TACLCustomScrollBox.BoundsChanged;
begin
  SubClass.Bounds := Bounds(0, 0, Width, Height).Split(GetBordersWidth);
end;

function TACLCustomScrollBox.CalculateRange(AContentHost: TWinControl): TSize;

  procedure AdjustHorzAutoRange(AControl: TControl; var ARange, AAlignMargin: Integer);
  begin
    if AControl.Align = alRight then
      Inc(AAlignMargin, AControl.Width)
    else
      if (AControl.Align = alLeft) or
         (AControl.Align = alNone) and (AControl.Anchors * [akLeft, akRight] = [akLeft])
      then
        ARange := Max(ARange, ViewInfo.ViewportX + AControl.BoundsRect.Right);
  end;

  procedure AdjustVertAutoRange(AControl: TControl; var ARange, AAlignMargin: Integer);
  begin
    if AControl.Align = alBottom then
      Inc(AAlignMargin, AControl.Height)
    else
      if (AControl.Align = alTop) or
         (AControl.Align = alNone) and (AControl.Anchors * [akTop, akBottom] = [akTop])
      then
        ARange := Max(ARange, ViewInfo.ViewportY + AControl.BoundsRect.Bottom);
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
  for I := 0 to AContentHost.ControlCount - 1 do
  begin
    AControl := AContentHost.Controls[I];
    if AControl.Visible then
    begin
      AdjustHorzAutoRange(AControl, ARangeHorz, AAlignMarginHorz);
      AdjustVertAutoRange(AControl, ARangeVert, AAlignMarginVert);
    end;
  end;
  Result := TSize.Create(ARangeHorz + AAlignMarginHorz, ARangeVert + AAlignMarginVert);
end;

{$IFDEF FPC}
procedure TACLCustomScrollBox.InsertControl(AControl: TControl; Index: Integer);
begin
  if AControl <> ContentHost then
    AControl.Parent := ContentHost
  else
    inherited;
end;
{$ENDIF}

function TACLCustomScrollBox.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLScrollBoxSubClass.Create(Self);
end;

procedure TACLCustomScrollBox.DisableAutoRange;
begin
  BeginUpdate;
end;

procedure TACLCustomScrollBox.EnableAutoRange;
begin
  EndUpdate;
  if not IsUpdateLocked then
    Realign;
end;

function TACLCustomScrollBox.GetBordersWidth: TRect;
begin
  Result := acBorderOffsets * Borders;
end;

procedure TACLCustomScrollBox.GetChildren(Proc: TGetChildProc; Root: TComponent);
begin
{$IFDEF SB_DT_WORKAROUND}
  if csDesigning in ComponentState then
    inherited
  else
{$ENDIF}
    TACLScrollBoxContentHost(ContentHost).GetChildren(Proc, Root);
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
      while (AParent <> nil) and (AParent <> ContentHost) do
      begin
        ARect.Offset(AParent.BoundsRect.TopLeft);
        AParent := AParent.Parent;
      end;

      if AParent = ContentHost then
        MakeVisible(ARect);
    end;
end;

procedure TACLCustomScrollBox.MakeVisible(ARect: TRect);
var
  AClientHeight: Integer;
  AClientWidth: Integer;
begin
  AClientWidth := ContentHost.Width;
  if ARect.Width <= AClientWidth then
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

  AClientHeight := ContentHost.Height;
  if ARect.Height <= AClientHeight then
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

procedure TACLCustomScrollBox.Paint;
begin
  inherited;
{$IFDEF SB_DT_WORKAROUND}
  if csDesigning in ComponentState then
    Style.DrawContent(Canvas, ClientRect)
  else
{$ENDIF}
    Style.DrawBorder(Canvas, ClientRect, Borders);
end;

procedure TACLCustomScrollBox.ScrollBy(DeltaX, DeltaY: Integer);
begin
  ContentHost.ScrollBy(DeltaX, DeltaY);
  ContentHost.Update;
end;

procedure TACLCustomScrollBox.SetBorders(AValue: TACLBorders);
begin
  if AValue <> FBorders then
  begin
    FBorders := AValue;
  {$IFDEF SB_DT_WORKAROUND}
    if (csDesigning in ComponentState) and HandleAllocated then
      SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE or SWP_NOZORDER or SWP_FRAMECHANGED);
  {$ENDIF}
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

procedure TACLCustomScrollBox.UpdateTransparency;
begin
  if Transparent or Style.IsTransparentBackground then
    ContentHost.ControlStyle := ContentHost.ControlStyle - [csOpaque]
  else
    ContentHost.ControlStyle := ContentHost.ControlStyle + [csOpaque];
end;

{$IFNDEF FPC}
procedure TACLCustomScrollBox.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    CM_FOCUSCHANGED:
      MakeVisible(TCMFocusChanged(Message).Sender);

    CM_CONTROLLISTCHANGING:
    {$IFDEF SB_DT_WORKAROUND}
      if not (csDesigning in ComponentState) then
    {$ENDIF}
      if TCMControlListChanging(Message).Inserting then
      begin
        if (TCMControlListChanging(Message).ControlListItem^.Parent = Self) and
           (TCMControlListChanging(Message).ControlListItem^.Control <> ContentHost) then
        begin
          TCMControlListChanging(Message).ControlListItem^.Parent := ContentHost;
          TCMControlListChanging(Message).ControlListItem^.Control.Parent := ContentHost;
          Exit;
        end;
      end;

  {$IFDEF SB_DT_WORKAROUND}
    WM_NCCALCSIZE:
      if csDesigning in ComponentState then
      begin
        TWMNCCalcSize(Message).CalcSize_Params.rgrc[0].Content(GetBordersWidth);
        Exit;
      end;

    WM_NCPAINT:
      if csDesigning in ComponentState then
      begin
        Canvas.Handle := GetWindowDC(Handle);
        try
          Style.DrawBorder(Canvas, Rect(0, 0, Width, Height), Borders);
        finally
          ReleaseDC(Handle, Canvas.Handle);
          Canvas.Handle := 0;
        end;
        Exit;
      end;
  {$ENDIF}
  end;
  inherited;
end;

{$ENDIF}

{ TACLScrollBoxContentHost }

procedure TACLScrollBoxContentHost.AdjustClientRect(var ARect: TRect);
var
  LViewPoint: TPoint;
begin
  LViewPoint := TACLCustomScrollBox(Parent).ViewPoint;
  ARect := Bounds(-LViewPoint.X, -LViewPoint.Y, ClientWidth, ClientHeight);
  inherited AdjustClientRect(ARect);
end;

procedure TACLScrollBoxContentHost.Paint;
var
  LBox: TACLCustomScrollBox;
  LHandled: Boolean;
begin
  LHandled := False;
  LBox := TACLCustomScrollBox(Owner);
  if Assigned(LBox.OnCustomDraw) then
    LBox.OnCustomDraw(LBox, Canvas, ClientRect, LHandled);
  if not LHandled and not LBox.Transparent then
    LBox.Style.DrawContent(Canvas, ClientRect);
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
var
  LControl: TACLCustomScrollBox;
begin
  LControl := GetControl;
  FContentSize := LControl.CalculateRange(LControl.ContentHost);
end;

procedure TACLScrollBoxViewInfo.ContentScrolled(ADeltaX, ADeltaY: Integer);
begin
  GetControl.ScrollBy(ADeltaX, ADeltaY);
end;

function TACLScrollBoxViewInfo.GetControl: TACLCustomScrollBox;
begin
  Result := SubClass.Container.GetControl as TACLCustomScrollBox;
end;

end.
