////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Custom Skinned Top-Level Window
//
//  Author:    Artem Izmaylov
//             © 2006-2024
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
  ACL.Graphics.FontCache,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Threading,
  ACL.UI.Application,
  ACL.UI.Controls.Base,
  ACL.UI.Forms.Base,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.RTTI,
  ACL.Utils.Strings;

{$IFDEF FPC}
const
  HTNOWHERE     = 0;
  HTCLIENT      = 1;
  HTCAPTION     = 2;
  HTSYSMENU     = 3;
  HTMINBUTTON   = 8;
  HTMAXBUTTON   = 9;
  HTLEFT        = 10;
  HTRIGHT       = 11;
  HTTOP         = 12;
  HTTOPLEFT     = 13;
  HTTOPRIGHT    = 14;
  HTBOTTOM      = 15;
  HTBOTTOMLEFT  = 16;
  HTBOTTOMRIGHT = 17;
  HTCLOSE       = 20;
{$ENDIF}

type

  { TACLCustomStyledForm }

  TACLCustomStyledForm = class(TACLCustomForm)
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
    // Messages
    procedure WndProc(var Message: TMessage); override;
    // Properties
    property HoveredId: Integer read FHoveredId write SetHoveredId;
    property PressedId: Integer read FPressedId write SetPressedId;
    property TinyClientBorders: Boolean read FTinyClientBorders write FTinyClientBorders;
  public
    destructor Destroy; override;
    function Active: Boolean;
  end;

{$REGION ' Form Implementation '}

{$IFDEF MSWINDOWS}
  TACLCustomStyledFormImpl = class(TACLCustomStyledForm)
  strict private
    FNativeBorderSize: Integer;
    FNativeCaptionSize: Integer;
    FWeAreSkinned: Boolean;
  protected
    procedure CalculateMetrics; override;
    procedure CreateHandle; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure PaintAppIcon(ACanvas: TCanvas; const R: TRect; AIcon: TIcon); override;
    // Messages
    procedure WMNCCalcSize(var Msg: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMNCMouseMove(var Msg: TMessage); message WM_NCMOUSEMOVE;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;
{$ENDIF}

{$IFDEF LCLGtk2}

  { TACLCustomStyledFormImpl }

  TACLCustomStyledFormImpl = class(TACLCustomStyledForm,
    IACLCursorProvider,
    IACLMouseTracking)
  strict private
    FInLoaded: Boolean;
    // IACLCursorProvider
    function GetCursor(const P: TPoint): TCursor;
    // IACLMouseTracking
    function IsMouseAtControl: Boolean;
    procedure IACLMouseTracking.MouseEnter = Nothing;
    procedure IACLMouseTracking.MouseLeave = Nothing;
    procedure Nothing;
  protected
    procedure ApplyClientSize(AWidth, AHeight: Integer); override;
    procedure CalculateMetrics; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Resizing(State: TWindowState); override;
    procedure Loaded; override;
    class procedure WSRegisterClass; override;
  public
    procedure SetBoundsKeepBase(aLeft, aTop, aWidth, aHeight: Integer); override;
  end;
{$ENDIF}
{$ENDREGION}

implementation

uses
{$IF DEFINED(LCLGtk2)}
  GLib2,
  Gdk2,
  Gdk2x,
  Gtk2,
  Gtk2Def,
  Gtk2Globals,
  Gtk2Int,
  Gtk2proc,
  Gtk2WSForms,
  WSLCLClasses,
{$ENDIF}
{$IFDEF FPC}
  ACL.Graphics.Ex.Cairo,
{$ELSE}
  ACL.Graphics.Ex.Gdip,
{$ENDIF}
  ACL.Graphics.Ex,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.UI.Forms;

{ TACLCustomStyledForm }

destructor TACLCustomStyledForm.Destroy;
begin
  TACLMouseTracker.Release(Self);
  inherited;
end;

function TACLCustomStyledForm.Active: Boolean;
begin
  Result := inherited Active or (InMenuLoop > 0);
end;

procedure TACLCustomStyledForm.AdjustClientRect(var Rect: TRect);
begin
  if not (csDesigning in ComponentState) then
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

procedure TACLCustomStyledForm.CalculateMetrics;
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

procedure TACLCustomStyledForm.BordersChanged;
begin
  CalculateMetrics;
  Realign;
  Invalidate;
end;

procedure TACLCustomStyledForm.DpiChanged;
begin
  inherited;
  BordersChanged;
end;

function TACLCustomStyledForm.HitTest(const P: TPoint): Integer;
var
  LButton: TFormButton;
  LRect: TRect;
begin
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

procedure TACLCustomStyledForm.InitializeNewForm;
begin
  inherited;
  CalculateMetrics;
end;

procedure TACLCustomStyledForm.InvalidateFrame;
begin
  Invalidate;
end;

procedure TACLCustomStyledForm.MouseDown(
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
    PressedId := HitTest(Point(X, Y));
end;

procedure TACLCustomStyledForm.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  HoveredId := HitTest(Point(X, Y));
end;

procedure TACLCustomStyledForm.MouseUp(
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

procedure TACLCustomStyledForm.MouseTracking;
begin
  if (WindowState = wsMinimized) or not (HandleAllocated and IsWindowVisible(Handle)) then
    HoveredId := HTNOWHERE
  else
    with ScreenToClient(Mouse.CursorPos) do
      MouseMove(KeyboardStateToShiftState, X, Y);
end;

procedure TACLCustomStyledForm.Paint;
begin
  if not (csDesigning in ComponentState) then
  begin
    PaintBorders(Canvas);
    PaintBorderIcons(Canvas);
    PaintCaption(Canvas);
  end;
  inherited;
end;

procedure TACLCustomStyledForm.PaintAppIcon(ACanvas: TCanvas; const R: TRect; AIcon: TIcon);
begin
  ACanvas.StretchDraw(R, AIcon);
end;

procedure TACLCustomStyledForm.PaintBorderIcons(ACanvas: TCanvas);

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

procedure TACLCustomStyledForm.PaintBorders(ACanvas: TCanvas);
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

procedure TACLCustomStyledForm.PaintCaption(ACanvas: TCanvas);
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

procedure TACLCustomStyledForm.Resize;
begin
  CalculateMetrics;
  MouseTracking;
  inherited;
end;

procedure TACLCustomStyledForm.ResourceChanged;
begin
  Color := Style.ColorContent.AsColor;
end;

procedure TACLCustomStyledForm.ToggleMaximize;
begin
  if WindowState = wsMaximized then
    WindowState := wsNormal
  else
    WindowState := wsMaximized;
end;

procedure TACLCustomStyledForm.SetHoveredId(AValue: Integer);
begin
  if FHoveredId <> AValue then
  begin
    FHoveredId := AValue;
    InvalidateFrame;
  end;
end;

procedure TACLCustomStyledForm.SetPressedId(AValue: Integer);
begin
  if FPressedId <> AValue then
  begin
    FPressedId := AValue;
    InvalidateFrame;
  end;
end;

procedure TACLCustomStyledForm.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    WM_ACTIVATE, CM_ACTIVATE, CM_DEACTIVATE:
      InvalidateFrame;
    WM_MOUSELEAVE, CM_MOUSELEAVE:
      MouseTracking;
  end;
end;

{$REGION ' Form Implementation - Windows'}{$IFDEF MSWINDOWS}

{ TACLCustomStyledFormImpl }

constructor TACLCustomStyledFormImpl.Create(AOwner: TComponent);
begin
  inherited;
//  TACLShadowWindow.Create(Self);
end;

procedure TACLCustomStyledFormImpl.CalculateMetrics;
begin
  FWeAreSkinned := acOSCheckVersion(6, 2) and not (csDesigning in ComponentState);
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

procedure TACLCustomStyledFormImpl.CreateHandle;
begin
  inherited;
  acFormSetCorners(Handle, afcRounded);
end;

procedure TACLCustomStyledFormImpl.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.WindowClass.Style := Params.WindowClass.Style or CS_VREDRAW or CS_HREDRAW;
end;

procedure TACLCustomStyledFormImpl.PaintAppIcon(ACanvas: TCanvas; const R: TRect; AIcon: TIcon);
begin
  DrawIconEx(ACanvas.Handle, R.Left, R.Top, AIcon.Handle, R.Width, R.Width, 0, 0, DI_NORMAL);
end;

procedure TACLCustomStyledFormImpl.WMNCCalcSize(var Msg: TWMNCCalcSize);
var
  LRect: TRect;
begin
  if FWeAreSkinned then
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

procedure TACLCustomStyledFormImpl.WMNCHitTest(var Msg: TWMNCHitTest);
begin
  if FWeAreSkinned then
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

procedure TACLCustomStyledFormImpl.WMNCMouseMove(var Msg: TMessage);
begin
  inherited;
  MouseTracking;
end;

procedure TACLCustomStyledFormImpl.WndProc(var Message: TMessage);
begin
  inherited;
  case Message.Msg of
    WM_ACTIVATEAPP:
      InvalidateFrame;
    WM_NCMOUSELEAVE:
      MouseTracking;
  end;
end;
{$ENDIF}{$ENDREGION}

{$REGION ' Form Implementation - Gtk2'}{$IFDEF LCLGtk2}
type

  { TAIMPGtk2CustomForm }

  TAIMPGtk2CustomForm = class(TGtk2WSCustomForm)
  strict private
    class var FFakeObj: TObject;
    class function DoRealize(Widget: PGtkWidget; Data: Pointer): GBoolean; cdecl; static;
    class procedure SetWindowCapabities(AForm: TACLCustomStyledForm; AWidget: PGtkWidget);
  public
    class destructor Destroy;
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class procedure SetCallbacks(const AWidget: PGtkWidget;
      const AWidgetInfo: PWidgetInfo); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
  end;

//procedure gdk_window_show_window_menu(window: PGdkWindow; event: PGdkEvent);
//const
//  SubstructureNotifyMask   = 1 shl 19;
//  SubstructureRedirectMask = 1 shl 20;
//var
//  deviceId: Integer;
//  display: PGdkDisplay;
//  x, y: gdouble;
//  xclient: TXClientMessageEvent;
//begin
//  case event^._type of
//    GDK_BUTTON_PRESS, GDK_BUTTON_RELEASE:;
//  else
//    Exit;
//  end;
//
//  gdk_event_get_root_coords(event, @x, @y);
//
//  display := gdk_drawable_get_display(window);
//  deviceId := 0;
//  g_object_get(event^.button.device, 'device-id', @deviceId, nil);
//
//  GDK_WINDOW_IMPL_X11(window);
//
//  FillChar(xclient, sizeOf(xclient), 0);
//  xclient._type := 33;//ClientMessage = 33;
//  xclient.window := GDK_WINDOW_XID (window);
//  xclient.message_type := gdk_x11_get_xatom_by_name_for_display(display, '_GTK_SHOW_WINDOW_MENU');
//  xclient.data.l[0] := deviceId;
//  xclient.data.l[1] := 0;
//  xclient.data.l[2] := 0;
//  //xclient.data.l[0] := device_id;
//  //xclient.data.l[1] := x_root * impl->window_scale;
//  //xclient.data.l[2] := y_root * impl->window_scale;
//  xclient.format := 32;
//
//  XSendEvent(GDK_DISPLAY_XDISPLAY(display), GDK_WINDOW_XROOTWIN (window),
//    False, SubstructureRedirectMask or SubstructureNotifyMask, @xclient);
//end;

{ TAIMPGtk2CustomForm }

class destructor TAIMPGtk2CustomForm.Destroy;
begin
  FreeAndNil(FFakeObj);
end;

class function TAIMPGtk2CustomForm.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
begin
  Result := inherited CreateHandle(AWinControl, AParams);
  SetWindowCapabities(TACLCustomStyledForm(AWinControl), PGtkWidget(Result));
end;

class function TAIMPGtk2CustomForm.DoRealize(Widget: PGtkWidget; Data: Pointer): GBoolean; cdecl;
begin
  if FFakeObj = nil then
    FFakeObj := TObject.Create;
  // таким образом пытаемся добраться до метода RealizeAccelerator
  Result := gtkRealizeCB(Widget, FFakeObj); // главное не отдать туда форму или nil.
  SetWindowCapabities(TACLCustomStyledForm(Data), Widget);
end;

class procedure TAIMPGtk2CustomForm.SetCallbacks(
  const AWidget: PGtkWidget; const AWidgetInfo: PWidgetInfo);
var
  LFixed: PGtkWidget;
begin
  inherited SetCallbacks(AWidget, AWidgetInfo);

  // подменяем gtkRealizeCB нашим обработчиком, чтобы подсунуть окну правильную декорацию и функционал
  g_signal_handlers_disconnect_by_func(AWidget, @gtkRealizeCB, AWidgetInfo^.LCLObject);
  g_signal_connect(AWidget, 'realize', TGTKSignalFunc(@DoRealize), AWidgetInfo^.LCLObject);

  LFixed := GetFixedWidget(AWidget);
  if LFixed <> nil then
  begin
    g_signal_handlers_disconnect_by_func(LFixed, @gtkRealizeCB, AWidgetInfo^.LCLObject);
    g_signal_connect(LFixed, 'realize', TGTKSignalFunc(@DoRealize), AWidgetInfo^.LCLObject);
  end;
end;

class procedure TAIMPGtk2CustomForm.SetWindowCapabities(AForm: TACLCustomStyledForm; AWidget: PGtkWidget);
var
  LWnd: PGdkWindow;
begin
  if AForm.Parent = nil then
  begin
    LWnd := gtk_widget_get_toplevel(AWidget)^.window;
    if LWnd <> nil then
    begin
      gdk_window_set_decorations(LWnd, 0);
      gdk_window_set_functions(LWnd, GetWindowFunction(AForm));
    end;
  end;
end;

class procedure TAIMPGtk2CustomForm.ShowHide(const AWinControl: TWinControl);
var
  LForm: TACLCustomStyledForm absolute AWinControl;
  LGtkWindow: PGtkWindow;
begin
  if (fsModal in LForm.FormState) and LForm.HandleObjectShouldBeVisible then
  begin
    // только ради GDK_WINDOW_TYPE_HINT_DIALOG, чтобы модалка
    // ни при каких условиях не создавала собственную кнопку на таскбаре
    LGtkWindow := {%H-}PGtkWindow(LForm.Handle);
    gtk_window_set_default_size(LGtkWindow, Max(1, LForm.Width), Max(1, LForm.Height));
    gtk_widget_set_uposition(PGtkWidget(LGtkWindow), LForm.Left, LForm.Top);
    gtk_window_set_type_hint(LGtkWindow, GDK_WINDOW_TYPE_HINT_DIALOG);
    GtkWindowShowModal(LForm, LGtkWindow);

    InvalidateLastWFPResult(LForm, LForm.BoundsRect);
  end
  else
  begin
    inherited;
    SetWindowCapabities(LForm, PGtkWidget(LForm.Handle));
  end;
end;

{ TACLCustomStyledFormImpl }

procedure TACLCustomStyledFormImpl.ApplyClientSize(AWidth, AHeight: Integer);
begin
  // Здесь делаем коррекцию client-size только на величину одного бордера,
  // чтобы привязанные к akRight/akBottom контролы посчитали правильный офсет.
  // Реальная коррекция размеров формы будет выполняться на Loaded+SetBoundsKeepBase.
  CalculateMetrics;
  if AWidth > 0 then
    Inc(AWidth, FMetrics.BorderWidth);
  if AHeight > 0 then
    Inc(AHeight, FMetrics.BorderWidth);
  inherited;
end;

procedure TACLCustomStyledFormImpl.CalculateMetrics;
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

function TACLCustomStyledFormImpl.GetCursor(const P: TPoint): TCursor;
const
  CursorMap: array [HTLEFT..HTBOTTOMRIGHT] of TCursor = (
    crSizeWE, crSizeWE, crSizeNS, crSizeNW, crSizeNE, crSizeNS, crSizeSW, crSizeSE
  );
var
  LCode: Integer;
begin
  LCode := HitTest(P);
  case LCode of
    HTLEFT..HTBOTTOMRIGHT:
      Result := CursorMap[LCode];
  else
    Result := crArrow;
  end;
end;

function TACLCustomStyledFormImpl.IsMouseAtControl: Boolean;
begin
  MouseTracking;
  Result := HoveredId <> HTNOWHERE;
end;

procedure TACLCustomStyledFormImpl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
const
  BorderMap: array[HTLEFT..HTBOTTOMRIGHT] of TGdkWindowEdge = (
    GDK_WINDOW_EDGE_WEST, GDK_WINDOW_EDGE_EAST,
    GDK_WINDOW_EDGE_NORTH, GDK_WINDOW_EDGE_NORTH_WEST, GDK_WINDOW_EDGE_NORTH_EAST,
    GDK_WINDOW_EDGE_SOUTH, GDK_WINDOW_EDGE_SOUTH_WEST, GDK_WINDOW_EDGE_SOUTH_EAST
  );
var
  LPoint: TPoint;
  LHitCode: Integer;
begin
  if Button = mbLeft then
  begin
    LPoint := ClientToScreen(Point(X, Y));
    LHitCode := HitTest(Point(X, Y));
    case LHitCode of
      //HTSYSMENU:
      //  gdk_window_show_window_menu(gtk_widget_get_root_window(PGtkWidget(Handle)), gtk_get_current_event);

      HTLEFT..HTBOTTOMRIGHT:
        if acCanStartDragging(Self, X, Y) then
        begin
          MouseCapture := False;
          LastMouse.Down := False;
          gtk_window_begin_resize_drag(PGtkWindow(Handle),
            BorderMap[LHitCode], 1, LPoint.X, LPoint.Y, GDK_CURRENT_TIME);
        end;

      HTCAPTION:
        if ssDouble in Shift then
          ToggleMaximize
        else
          if acCanStartDragging(Self, X, Y) then
          begin
            MouseCapture := False;
            LastMouse.Down := False;
            gtk_window_begin_move_drag(PGtkWindow(Handle), 1, LPoint.X, LPoint.Y, GDK_CURRENT_TIME);
          end;
    else
      inherited MouseDown(Button, Shift, X, Y);
    end;
  end;
end;

procedure TACLCustomStyledFormImpl.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  case HoveredId of
    HTNOWHERE, HTCLIENT:
      TACLMouseTracker.Release(Self);
  else
    TACLMouseTracker.Start(Self);
  end;
end;

procedure TACLCustomStyledFormImpl.Resizing(State: TWindowState);
begin
  if State <> WindowState then
  begin
    inherited;
    BordersChanged;
  end
  else
    inherited;
end;

procedure TACLCustomStyledFormImpl.Loaded;
begin
  FInLoaded := True;
  inherited;
  FInLoaded := False;
end;

procedure TACLCustomStyledFormImpl.SetBoundsKeepBase(aLeft, aTop, aWidth, aHeight: Integer);
begin
  if FInLoaded then
  begin
    CalculateMetrics;
    if LoadedClientWidth > 0 then
      aWidth := LoadedClientWidth + 2 * FMetrics.BorderWidth;
    if LoadedClientHeight > 0 then;
      aHeight := LoadedClientHeight + 2 * FMetrics.BorderWidth + FMetrics.CaptionHeight;
  end;
  inherited SetBoundsKeepBase(aLeft, aTop, aWidth, aHeight);
end;

procedure TACLCustomStyledFormImpl.Nothing;
begin
  // do nothing
end;

class procedure TACLCustomStyledFormImpl.WSRegisterClass;
begin
  inherited;
  RegisterWSComponent(Self, TAIMPGtk2CustomForm);
end;
{$ENDIF}
{$ENDREGION}
end.
