////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Custom Skinned Top-Level Window
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Forms.Styled;

{$I ACL.Config.inc}

//{$MESSAGE WARN 'TACLCustomStyledForm - ToDo:'}
(*
    Linux: клик по иконке - вызов системного меню
    Windows: нет тени у окна (актульно для Windows 8 и Windows 10)
*)
interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
  LMessages,
  WSLCLClasses,
{$ELSE}
  Winapi.ActiveX,
  Winapi.CommDlg,
  Winapi.DwmApi,
  Winapi.Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  {System.}TypInfo,
  // Vcl
  {Vcl.}ActnList,
  {Vcl.}Controls,
  {Vcl.}Dialogs,
  {Vcl.}ExtCtrls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}Menus,
  // ACL
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Graphics,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Threading,
  ACL.UI.Application,
  ACL.UI.Controls.Base,
{$IFDEF LCLGtk2}
  ACL.UI.Core.Impl.Gtk2,
{$ENDIF}
  ACL.UI.Forms.Base,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.RTTI,
  ACL.Utils.Strings;

type

  { TACLAbstractStyledForm }

  TACLAbstractStyledForm = class(TACLCustomForm)
  strict private
    FHoveredId: Integer;
    FPressedId: Integer;
    FTinyClientBorders: Boolean;
    procedure SetHoveredId(AValue: Integer);
    procedure SetPressedId(AValue: Integer);
  protected type
  {$REGION ' Types '}
    {$SCOPEDENUMS ON}
    TFormButton = (Minimize, Maximize, Close);
    {$SCOPEDENUMS OFF}

    TFormMetrics = record
    public
      // Metrics
      BorderWidth: Integer;
      ButtonSize: TSize;
      CaptionContentOffset: Integer;
      CaptionHeight: Integer;
      IconWidth: Integer;
      // Rects
      RectCaption: TRect;
      RectButtons: array[TFormButton] of TRect;
      RectIcon: TRect;
      RectIconHitBox: TRect;
      RectText: TRect;
    end;
  {$ENDREGION}
  protected const
    ButtonHitCodes: array[TFormButton] of Integer = (HTMINBUTTON, HTMAXBUTTON, HTCLOSE);
  protected
    FMetrics: TFormMetrics;

    procedure AdjustClientRect(var Rect: TRect); override;
    procedure BordersChanged;
    procedure CalculateMetrics; virtual;
    procedure DpiChanged; override;
    procedure InitializeNewForm; override;
    procedure InvalidateFrame;
    procedure Resize; override;
    procedure ResourceChanged; override;
    procedure ToggleMaximize;
    // Mouse
    function HitTest(const P: TPoint): Integer;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseTracking;
    // Drawing
    procedure Paint; override;
    procedure PaintAppIcon(ACanvas: TCanvas; const R: TRect; AIcon: TIcon); virtual;
    procedure PaintBorderIcons(ACanvas: TCanvas);
    procedure PaintBorders(ACanvas: TCanvas);
    procedure PaintCaption(ACanvas: TCanvas);
    function UseCustomStyle: Boolean; virtual;
    // Messages
    procedure WMNCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
    procedure WndProc(var Message: TMessage); override;
    // Properties
    property HoveredId: Integer read FHoveredId write SetHoveredId;
    property PressedId: Integer read FPressedId write SetPressedId;
    property TinyClientBorders: Boolean read FTinyClientBorders write FTinyClientBorders;
  public
    destructor Destroy; override;
    function Active: Boolean;
  end;

{$IFDEF MSWINDOWS}

  { TACLCustomStyledForm }

  TACLCustomStyledForm = class(TACLAbstractStyledForm)
  strict private
    FNativeBorderSize: Integer;
    FNativeCaptionSize: Integer;
  protected
    procedure CalculateMetrics; override;
    procedure CreateHandle; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure PaintAppIcon(ACanvas: TCanvas; const R: TRect; AIcon: TIcon); override;
    function UseCustomStyle: Boolean; override;
    // Messages
    procedure WMNCCalcSize(var Msg: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCMouseMove(var Msg: TMessage); message WM_NCMOUSEMOVE;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

{$ENDIF}

{$IFDEF LCLGtk2}

  { TACLCustomStyledForm }

  TACLCustomStyledForm = class(TACLAbstractStyledForm, IACLMouseTracking)
  strict private
    FClientOffsets: TRect;
    FInLoaded: Boolean;
    // IACLMouseTracking
    function IsMouseAtControl: Boolean;
    procedure IACLMouseTracking.MouseEnter = Nothing;
    procedure IACLMouseTracking.MouseLeave = Nothing;
    procedure Nothing;
    procedure UpdateClientOffsets;
    // Messages
    procedure WMLButtonDblClk(var Message: TLMLButtonDblClk); message LM_LBUTTONDBLCLK;
    procedure WMMouseMove(var Message: TLMMouseMove); message LM_MOUSEMOVE;
  protected
    procedure CalculateMetrics; override;
    procedure Resize; override;
    procedure Resizing(State: TWindowState); override;
    procedure Loaded; override;
    procedure SetClientHeight(Value: Integer);override;
    procedure SetClientWidth(Value: Integer); override;
    class procedure WSRegisterClass; override;
    property ClientOffsets: TRect read FClientOffsets;
  public
    procedure SetBoundsKeepBase(aLeft, aTop, aWidth, aHeight: Integer); override;
  end;

{$ENDIF}

implementation

uses
{$IFDEF LCLGtk2}
  Gdk2,
{$ENDIF}
  ACL.Graphics.Ex,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet;

{ TACLAbstractStyledForm }

destructor TACLAbstractStyledForm.Destroy;
begin
  TACLMouseTracker.Release(Self);
  inherited;
end;

function TACLAbstractStyledForm.Active: Boolean;
begin
  Result := inherited Active or (InMenuLoop > 0);
end;

procedure TACLAbstractStyledForm.AdjustClientRect(var Rect: TRect);
begin
  if UseCustomStyle and not (csDesigning in ComponentState) then
  begin
    Inc(Rect.Top, FMetrics.CaptionHeight);
    if TinyClientBorders then
    begin
      Inc(Rect.Top, FMetrics.BorderWidth);
      Inc(Rect.Left);
      Dec(Rect.Right);
      Dec(Rect.Bottom);
    end
    else
      Rect.Inflate(-FMetrics.BorderWidth);
  end;
  Rect.Content(Padding.GetScaledMargins(FCurrentPPI));
end;

procedure TACLAbstractStyledForm.CalculateMetrics;
var
  LRect: TRect;
begin
  FMetrics.RectCaption := ClientRect;
  FMetrics.RectCaption.Height := FMetrics.CaptionHeight + FMetrics.BorderWidth;

  FMetrics.RectText := FMetrics.RectCaption;
  if FMetrics.BorderWidth > 0 then
    Inc(FMetrics.RectText.Top);
  Inc(FMetrics.RectText.Left, FMetrics.BorderWidth);
  Inc(FMetrics.RectText.Top, FMetrics.CaptionContentOffset);

  FMetrics.RectIcon := FMetrics.RectText;
  if BorderStyle in [bsSingle, bsSizeable] then
  begin
    FMetrics.RectIcon.Width := FMetrics.IconWidth;
    FMetrics.RectIconHitBox := FMetrics.RectIcon;
    FMetrics.RectIcon.CenterVert(FMetrics.IconWidth);
    FMetrics.RectText.Left := FMetrics.RectIcon.Right + dpiApply(acTextIndent, FCurrentPPI);
  end
  else
  begin
    FMetrics.RectIconHitBox.Width := 0;
    FMetrics.RectIcon.Width := 0;
  end;

  LRect := FMetrics.RectText;
  LRect.Height := FMetrics.ButtonSize.cy;
  if biSystemMenu in BorderIcons then
  begin
    FMetrics.RectButtons[TFormButton.Close] := LRect.Split(srRight, FMetrics.ButtonSize.cx);
    LRect.Right := FMetrics.RectButtons[TFormButton.Close].Left;
  end;
  if biMaximize in BorderIcons then
  begin
    FMetrics.RectButtons[TFormButton.Maximize] := LRect.Split(srRight, FMetrics.ButtonSize.cx);
    LRect.Right := FMetrics.RectButtons[TFormButton.Maximize].Left;
  end;
  if biMinimize in BorderIcons then
  begin
    FMetrics.RectButtons[TFormButton.Minimize] := LRect.Split(srRight, FMetrics.ButtonSize.cx);
    LRect.Right := FMetrics.RectButtons[TFormButton.Minimize].Left;
  end;
  FMetrics.RectText.Right := LRect.Right - dpiApply(acTextIndent, FCurrentPPI);
end;

procedure TACLAbstractStyledForm.BordersChanged;
begin
  CalculateMetrics;
  Realign;
  Invalidate;
end;

procedure TACLAbstractStyledForm.DpiChanged;
begin
  inherited;
  BordersChanged;
end;

function TACLAbstractStyledForm.HitTest(const P: TPoint): Integer;
var
  LButton: TFormButton;
  LRect: TRect;
begin
  if not UseCustomStyle then
    Exit(HTNOWHERE);

  LRect := ClientRect;
  if not LRect.Contains(P) then
    Exit(HTNOWHERE);

  if FMetrics.RectIconHitBox.Contains(P) then
    Exit(HTSYSMENU);
  for LButton := Low(LButton) to High(LButton) do
  begin
    if FMetrics.RectButtons[LButton].Contains(P) then
      Exit(ButtonHitCodes[LButton]);
  end;

  if BorderStyle in [bsSizeable, bsSizeToolWin] then
  begin
    LRect.Inflate(-FMetrics.BorderWidth);
    if P.X < LRect.Left then
    begin
      if P.Y < LRect.Top then
        Exit(HTTOPLEFT);
      if P.Y > LRect.Bottom then
        Exit(HTBOTTOMLEFT);
      Exit(HTLEFT);
    end;

    if P.X > LRect.Right then
    begin
      if P.Y < LRect.Top then
        Exit(HTTOPRIGHT);
      if P.Y > LRect.Bottom then
        Exit(HTBOTTOMRIGHT);
      Exit(HTRIGHT);
    end;

    if P.Y < LRect.Top then
      Exit(HTTOP);
    if P.Y > LRect.Bottom then
      Exit(HTBOTTOM);
  end;

  if InRange(P.Y, LRect.Top, LRect.Top + FMetrics.CaptionHeight) then
    Result := HTCAPTION
  else
    Result := HTCLIENT;
end;

procedure TACLAbstractStyledForm.InitializeNewForm;
begin
  inherited;
  CalculateMetrics;
end;

procedure TACLAbstractStyledForm.InvalidateFrame;
begin
  Invalidate;
end;

procedure TACLAbstractStyledForm.MouseDown(
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
    PressedId := HitTest(Point(X, Y));
end;

procedure TACLAbstractStyledForm.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  HoveredId := HitTest(Point(X, Y));
end;

procedure TACLAbstractStyledForm.MouseUp(
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if PressedId = HoveredId then
  begin
    case PressedId of
      HTCLOSE:
        Close;
      HTMINBUTTON:
        WindowState := wsMinimized;
      HTMAXBUTTON:
        ToggleMaximize;
    end;
  end;
  HoveredId := HTNOWHERE;
  PressedId := HTNOWHERE;
end;

procedure TACLAbstractStyledForm.MouseTracking;
begin
  if UseCustomStyle then
  begin
    if (WindowState = wsMinimized) or not (HandleAllocated and IsWindowVisible(Handle)) then
      HoveredId := HTNOWHERE
    else
      with ScreenToClient(Mouse.CursorPos) do
        MouseMove(KeyboardStateToShiftState, X, Y);
  end;
end;

procedure TACLAbstractStyledForm.Paint;
begin
  if not (csDesigning in ComponentState) then
  begin
    PaintBorders(Canvas);
    PaintBorderIcons(Canvas);
    PaintCaption(Canvas);
  end;
  inherited;
end;

procedure TACLAbstractStyledForm.PaintAppIcon(ACanvas: TCanvas; const R: TRect; AIcon: TIcon);
begin
  ACanvas.StretchDraw(R, AIcon);
end;

procedure TACLAbstractStyledForm.PaintBorderIcons(ACanvas: TCanvas);

  function GetHighlightColor(AButton: TFormButton): TAlphaColor;
  var
    LColor: TColor;
  begin
    LColor := $808080;
    if AButton = TFormButton.Close then
      LColor := Style.ColorBorder1.AsColor;
    Result := TAlphaColor.FromColor(LColor, 40);
  end;

var
  LGlyphs: TACLSkinImageSetItem;
  LButton: TFormButton;
  LRect: TRect;
begin
  LGlyphs := Style.Glyphs.Image.Clone;
  try
    LGlyphs.ApplyTint(TACLPixel32.Create(Style.CaptionFontColor[Active]));

    for LButton := Low(LButton) to High(LButton) do
    begin
      LRect := FMetrics.RectButtons[LButton];
      if ButtonHitCodes[LButton] = HoveredId then
        acFillRect(ACanvas, LRect, GetHighlightColor(LButton));
      if ButtonHitCodes[LButton] = PressedId then
        acFillRect(ACanvas, LRect, TAlphaColor.FromColor($808080, 60));

      case LButton of
        TFormButton.Minimize:
          LGlyphs.Draw(ACanvas, LRect, 0);
        TFormButton.Maximize:
          LGlyphs.Draw(ACanvas, LRect, 1 + Ord(WindowState = wsMaximized));
        TFormButton.Close:
          LGlyphs.Draw(ACanvas, LRect, 3);
      end;
    end;
  finally
    LGlyphs.Free;
  end;
end;

procedure TACLAbstractStyledForm.PaintBorders(ACanvas: TCanvas);
begin
  if FMetrics.BorderWidth > 0 then
  begin
    if Active then
      ACanvas.Brush.Color := Style.ColorBorder1.AsColor
    else
      ACanvas.Brush.Color := Style.ColorBorder2.AsColor;

    ACanvas.FrameRect(ClientRect);
  end;
end;

procedure TACLAbstractStyledForm.PaintCaption(ACanvas: TCanvas);
var
  LIcon: TIcon;
begin
  if not FMetrics.RectIcon.IsEmpty then
  begin
    LIcon := Icon;
    if LIcon.Empty then
      LIcon := Application.Icon;
    PaintAppIcon(ACanvas, FMetrics.RectIcon, LIcon);
  end;

  ACanvas.Font := Style.CaptionFont;
  ACanvas.Font.Color := Style.CaptionFontColor[Active];
  ACanvas.Brush.Style := bsClear;
  acTextDraw(ACanvas, Caption, FMetrics.RectText, taLeftJustify, taVerticalCenter, True);
end;

function TACLAbstractStyledForm.UseCustomStyle: Boolean;
begin
  Result := True;
end;

procedure TACLAbstractStyledForm.WMNCHitTest(var Msg: TWMNCHitTest);
begin
  if UseCustomStyle then
  begin
    Msg.Result := HitTest(ScreenToClient(Msg.Pos));
    case Msg.Result of
      HTMINBUTTON, HTMAXBUTTON, HTCLOSE:
        Msg.Result := HTCLIENT;
    end;
  end
  else
    inherited;
end;

procedure TACLAbstractStyledForm.Resize;
begin
  CalculateMetrics;
  MouseTracking;
  inherited;
end;

procedure TACLAbstractStyledForm.ResourceChanged;
begin
  Color := Style.ColorContent.AsColor;
end;

procedure TACLAbstractStyledForm.ToggleMaximize;
begin
  if WindowState = wsMaximized then
    WindowState := wsNormal
  else
    WindowState := wsMaximized;
end;

procedure TACLAbstractStyledForm.SetHoveredId(AValue: Integer);
begin
  if FHoveredId <> AValue then
  begin
    FHoveredId := AValue;
    InvalidateFrame;
  end;
end;

procedure TACLAbstractStyledForm.SetPressedId(AValue: Integer);
begin
  if FPressedId <> AValue then
  begin
    FPressedId := AValue;
    InvalidateFrame;
  end;
end;

procedure TACLAbstractStyledForm.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    WM_ACTIVATE, CM_ACTIVATE, CM_DEACTIVATE:
      InvalidateFrame;
    WM_MOUSELEAVE, CM_MOUSELEAVE:
      MouseTracking;
  end;
end;

{$IFDEF MSWINDOWS}

{ TACLCustomStyledForm }

constructor TACLCustomStyledForm.Create(AOwner: TComponent);
begin
  inherited;
//  TACLShadowWindow.Create(Self);
end;

procedure TACLCustomStyledForm.CalculateMetrics;
begin
  ZeroMemory(@FMetrics, SizeOf(FMetrics));
  if BorderStyle <> bsNone then
  begin
    FMetrics.BorderWidth := FNativeBorderSize;
    FMetrics.CaptionHeight := FNativeCaptionSize;
    FMetrics.IconWidth := GetSystemMetrics(SM_CXSMICON);
    FMetrics.ButtonSize.cx := dpiApply(42, FCurrentPPI);
    FMetrics.ButtonSize.cy := FNativeBorderSize + FNativeCaptionSize - 1;
  end;
  if HandleAllocated and IsZoomed(Handle) then
    FMetrics.CaptionContentOffset := FMetrics.BorderWidth div 2;
  inherited;
end;

procedure TACLCustomStyledForm.CreateHandle;
begin
  inherited;
  acFormSetCorners(Handle, afcRounded);
end;

procedure TACLCustomStyledForm.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.WindowClass.Style := Params.WindowClass.Style or CS_VREDRAW or CS_HREDRAW;
end;

procedure TACLCustomStyledForm.PaintAppIcon(ACanvas: TCanvas; const R: TRect; AIcon: TIcon);
begin
  DrawIconEx(ACanvas.Handle, R.Left, R.Top, AIcon.Handle, R.Width, R.Width, 0, 0, DI_NORMAL);
end;

function TACLCustomStyledForm.UseCustomStyle: Boolean;
begin
  Result := acOSCheckVersion(6, 2) and not (csDesigning in ComponentState);
end;

procedure TACLCustomStyledForm.WMNCCalcSize(var Msg: TWMNCCalcSize);
var
  LRect: TRect;
begin
  if UseCustomStyle then
  begin
    LRect := Msg.CalcSize_Params.rgrc[0];
    inherited;
    FNativeBorderSize := Msg.CalcSize_Params.rgrc[0].Left - LRect.Left;
    FNativeCaptionSize := Msg.CalcSize_Params.rgrc[0].Top - LRect.Top - FNativeBorderSize;
    Msg.CalcSize_Params.rgrc[0] := LRect;
    BordersChanged;
  end
  else
    inherited;
end;

procedure TACLCustomStyledForm.WMNCMouseMove(var Msg: TMessage);
begin
  inherited;
  MouseTracking;
end;

procedure TACLCustomStyledForm.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    WM_ACTIVATEAPP:
      InvalidateFrame;
    WM_NCMOUSELEAVE:
      MouseTracking;
  end;
end;

{$ENDIF}

{$IFDEF LCLGtk2}

{ TACLCustomStyledForm }

procedure TACLCustomStyledForm.CalculateMetrics;
var
  LRect: TRect;
begin
  ZeroMemory(@FMetrics, SizeOf(FMetrics));
  if BorderStyle <> bsNone then
  begin
    if WindowState <> wsMaximized then
      FMetrics.BorderWidth := dpiApply(8, FCurrentPPI);
    FMetrics.CaptionHeight := dpiApply(26, FCurrentPPI);
    FMetrics.IconWidth := dpiApply(16, FCurrentPPI);
    FMetrics.ButtonSize.cx := dpiApply(48, FCurrentPPI);
    FMetrics.ButtonSize.cy := FMetrics.CaptionHeight + FMetrics.BorderWidth;
  end;
  inherited;
end;

function TACLCustomStyledForm.IsMouseAtControl: Boolean;
begin
  MouseTracking;
  Result := HoveredId <> HTNOWHERE;
end;

procedure TACLCustomStyledForm.Resize;
begin
  inherited Resize;
  UpdateClientOffsets;
end;

procedure TACLCustomStyledForm.Resizing(State: TWindowState);
begin
  if State <> WindowState then
  begin
    inherited;
    BordersChanged;
  end
  else
    inherited;
end;

procedure TACLCustomStyledForm.Loaded;
begin
  FInLoaded := True;
  inherited;
  FInLoaded := False;
end;

procedure TACLCustomStyledForm.SetClientHeight(Value: Integer);
begin
  if not (csReadingState in ControlState) then
    Inc(Value, 2 * FMetrics.BorderWidth + FMetrics.CaptionHeight);
  inherited SetClientHeight(Value);
end;

procedure TACLCustomStyledForm.SetClientWidth(Value: Integer);
begin
  if not (csReadingState in ControlState) then
    Inc(Value, 2 * FMetrics.BorderWidth);
  inherited SetClientWidth(Value);
end;

procedure TACLCustomStyledForm.SetBoundsKeepBase(aLeft, aTop, aWidth, aHeight: Integer);
begin
  if FInLoaded then
  begin
    CalculateMetrics;
    if LoadedClientWidth > 0 then
      aWidth  := LoadedClientWidth  + 2 * FMetrics.BorderWidth;
    if LoadedClientHeight > 0 then;
      aHeight := LoadedClientHeight + 2 * FMetrics.BorderWidth + FMetrics.CaptionHeight;
  end;
  inherited SetBoundsKeepBase(aLeft, aTop, aWidth, aHeight);
end;

procedure TACLCustomStyledForm.Nothing;
begin
  // do nothing
end;

procedure TACLCustomStyledForm.UpdateClientOffsets;
var
  LControl: TControl;
  LDelta: TRect;
  LRect: TRect;
  I: Integer;
begin
  if FIScaling then
    Exit;
  if wcfCreatingHandle in FWinControlFlags then
    Exit;
  if csLoading in ComponentState then
    Exit;
  if not HandleAllocated then
    Exit;

  LRect := ClientRect;
  AdjustClientRect(LRect);
  LRect := TRect.CreateMargins(ClientRect, LRect);
  if LRect = FClientOffsets then Exit;

  LDelta.Left   := LRect.Left   - FClientOffsets.Left;
  LDelta.Top    := LRect.Top    - FClientOffsets.Top;
  LDelta.Right  := LRect.Right  - FClientOffsets.Right;
  LDelta.Bottom := LRect.Bottom - FClientOffsets.Bottom;
  FClientOffsets := LRect;

  DisableAlign;
  try
    for I := 0 to ControlCount - 1 do
    begin
      LControl := Controls[I];
      if not (LControl.Align in [alNone, alCustom]) then
        Continue;

      LRect := LControl.BoundsRect;
      if TAnchorKind.akTop in LControl.Anchors then
      begin
        LRect.Offset(0, LDelta.Top);
        if TAnchorKind.akBottom in LControl.Anchors then
          Dec(LRect.Bottom, LDelta.MarginsHeight);
      end
      else
        if TAnchorKind.akBottom in LControl.Anchors then
          LRect.Offset(0, -LDelta.Bottom);

      if TAnchorKind.akLeft in LControl.Anchors then
      begin
        LRect.Offset(LDelta.Left, 0);
        if TAnchorKind.akRight in LControl.Anchors then
          Dec(LRect.Right, LDelta.MarginsWidth);
      end
      else
        if TAnchorKind.akRight in LControl.Anchors then
          LRect.Offset(-LDelta.Right, 0);

      LControl.BoundsRect := LRect;
    end;
  finally
    EnableAlign;
  end;
end;

procedure TACLCustomStyledForm.WMLButtonDblClk(var Message: TLMLButtonDblClk);
begin
  if not GtkNCProcessMessage(Self, Message) then
    inherited;
end;

procedure TACLCustomStyledForm.WMMouseMove(var Message: TLMMouseMove);
begin
  inherited;
  case HoveredId of
    HTNOWHERE, HTCLIENT:
      TACLMouseTracker.Release(Self);
  else
    TACLMouseTracker.Start(Self);
  end;
end;

class procedure TACLCustomStyledForm.WSRegisterClass;
const
  Done: Boolean = False;
begin
  if Done then exit;
  inherited;
  RegisterWSComponent(TACLCustomStyledForm, TACLWSAdvancedForm);
  Done := True;
end;

{$ENDIF}

end.
