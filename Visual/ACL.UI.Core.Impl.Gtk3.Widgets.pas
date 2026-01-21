////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Wrappers for Gtk3 Widgets
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Core.Impl.Gtk3.Widgets;

{$I ACL.Config.inc}

{$SCOPEDENUMS ON}

interface

uses
  LCLIntf,
  LCLType,
  LMessages,
  Messages,
  // Gtk
  Cairo,
  Gtk3Int,
  Gtk3Objects,
  Gtk3Procs,
  Gtk3WSControls,
  Gtk3WSForms,
  Gtk3Widgets,
  LazCairo1,
  LazGObject2,
  LazGlib2,
  LazGtk3,
  LazGdk3,
  LazGdkPixbuf2,
  WSLCLClasses,
  WSProc,
  // System
  Classes,
  Generics.Collections,
  Math,
  System.UITypes,
  SysUtils,
  Types,
  // ACL
  ACL.Classes,
  ACL.Graphics,
  ACL.Graphics.Ex.Cairo,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Logger,
  // VCL
  Graphics,
  Controls,
  Forms;

type

  { TACLGtk3CustomControl }

  // based on TGtk3Panel
  TACLGtk3CustomControl = class(TGtk3Bin)
  strict private
    class procedure DoSizeAllocate(AWidget: PGtkLayout;
      AGdkRect: PGdkRectangle; AGtk3Widget: TGtk3Widget); cdecl; static;
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    function ClientToScreen(var P: TPoint): boolean; override;
    function DeliverMessage(var Msg; const AIsInputEvent: Boolean=False): LRESULT; override;
    procedure InitializeWidget; override;
    procedure SetBorderStyle(AValue: TBorderStyle);
  end;

  { TACLGtk3AdvancedWindow }

  TACLGtk3AdvancedWindow = class(TGtk3Window)
  strict private
    FCreatingWorkaround: TProc;
    class function OnMapped(AWindow: PGtkWindow; AEvent: PGdkEventAny;
      AImpl: TACLGtk3AdvancedWindow): gboolean; cdecl; static;
  public
    function ClientToScreen(var P: TPoint): boolean; override;
    function CreateWidget(const Params: TCreateParams): PGtkWidget; override;
    function DeliverMessage(var Msg; const AIsInput: Boolean = False): LRESULT; override;
    function GtkEventPaint(Sender: PGtkWidget; AContext: Pcairo_t): Boolean; override;
    procedure InitializeWidget; override;
    procedure OffsetMousePos(const aGlobalX, aGlobalY: double; APoint: PPoint); override;
    procedure Repaint(const ARect: PRect=nil); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: integer); override;
    procedure SetText(const AValue: String); override;
  public
    class function ResolveWndParent(const AParams: TCreateParams): PGtkWindow;
    class procedure SetAlphaExposing(AWidget: PGtkWidget);
  end;

  { TACLGtk3PopupControl }

  TACLGtk3PopupControl = class(TGtk3Widget)
  strict private
    FFirstMapRect: TRect;
    class function WidgetEvent(widget: PGtkWidget;
      Event: PGdkEvent; Data: GPointer): gboolean; cdecl; static;
  public
    function ClientToScreen(var P: TPoint): Boolean; override;
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
    procedure InitializeWidget; override;
    function GtkEventPaint(Sender: PGtkWidget; AContext: Pcairo_t): Boolean; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: integer); override;
  end;

implementation

uses
  ACL.UI.Forms.Base;

type
  TWinControlAccess = class(TWinControl);

const
  GDK_DEFAULT_EVENTS_MASK = [
    GDK_EXPOSURE_MASK, {2}
    GDK_POINTER_MOTION_MASK, {4}
    GDK_POINTER_MOTION_HINT_MASK, {8}
    GDK_BUTTON_MOTION_MASK, {16}
    GDK_BUTTON1_MOTION_MASK, {32}
    GDK_BUTTON2_MOTION_MASK, {64}
    GDK_BUTTON3_MOTION_MASK, {128}
    GDK_BUTTON_PRESS_MASK, {256}
    GDK_BUTTON_RELEASE_MASK, {512}
    GDK_KEY_PRESS_MASK, {1024}
    GDK_KEY_RELEASE_MASK, {2048}
    GDK_ENTER_NOTIFY_MASK, {4096}
    GDK_LEAVE_NOTIFY_MASK, {8192}
    GDK_FOCUS_CHANGE_MASK, {16384}
    GDK_STRUCTURE_MASK, {32768}
    GDK_PROPERTY_CHANGE_MASK, {65536}
    GDK_VISIBILITY_NOTIFY_MASK, {131072}
    GDK_PROXIMITY_IN_MASK, {262144}
    GDK_PROXIMITY_OUT_MASK, {524288}
    GDK_SUBSTRUCTURE_MASK, {1048576}
    GDK_SCROLL_MASK, {2097152}
    GDK_TOUCH_MASK {4194304}
 // GDK_SMOOTH_SCROLL_MASK {8388608} //there is a bug in GTK3, see https://stackoverflow.com/questions/11775161/gtk3-get-mouse-scroll-direction
  ];

function GtkGetOrigin(AWidget: PGtkWidget): TPoint;
begin
  Result := NullPoint;
  if (AWidget <> nil) and (AWidget^.window <> nil) and AWidget^.get_realized then
    AWidget^.window^.get_origin(@Result.X, @Result.Y);
end;

{ TACLGtk3CustomControl }

function TACLGtk3CustomControl.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  LColor: TGdkRGBA;
begin
  FHasPaint := True;
  FWidgetType := [wtWidget, wtLayout, wtPanel];

  Result := TGtkLayout.new(nil, nil);
  Result^.set_can_focus(True);
  Result^.set_app_paintable(True);
  Result^.set_has_window(True);
  // as GtkFixed have no child control here - nobody triggers resizing
  // GNOME takes care of it, but other WM - not
  // this is here to make TGtk3Panel shown under Plasma
  //Result^.set_size_request(LCLObject.Width,LCLObject.Height);
  PGtkLayout(Result)^.set_size(1, 1);

  if not (csDesigning in LCLObject.ComponentState) then
    g_object_set(PGObject(Result), 'resize-mode', [GTK_RESIZE_QUEUE, nil]);
  g_signal_connect_data(Result, 'size-allocate', TGCallback(@DoSizeAllocate), Self, nil, G_CONNECT_DEFAULT);

  FillChar(LColor, SizeOf(LColor), 0);
  Result^.override_background_color(GTK_STATE_FLAG_NORMAL, @LColor);
  Result^.override_background_color([GTK_STATE_FLAG_ACTIVE], @LColor);
  Result^.override_background_color([GTK_STATE_FLAG_FOCUSED], @LColor);
  Result^.override_background_color([GTK_STATE_FLAG_PRELIGHT], @LColor);
  Result^.override_background_color([GTK_STATE_FLAG_SELECTED], @LColor);
end;

function TACLGtk3CustomControl.ClientToScreen(var P: TPoint): boolean;
begin
  P := P + GtkGetOrigin(Widget);
  Result := True;
end;

function TACLGtk3CustomControl.DeliverMessage(
  var Msg; const AIsInputEvent: Boolean): LRESULT;
var
  LControl: TWinControl;
  LMessage: TLMessage absolute Msg;
begin
  Result := 0;
  try
    if LMessage.Msg = LM_MOUSEWHEEL then
    begin
      LControl := LCLObject;
      while (LControl <> nil) and LControl.HandleAllocated do
      begin
        LControl.WindowProc(LMessage);
        if LMessage.Result <> 0 then
          Exit(LMessage.Result);
        Inc(TLMMouse(Msg).XPos, LControl.Left);
        Inc(TLMMouse(Msg).YPos, LControl.Top);
        LControl := LControl.Parent;
      end;
    end
    else
      Result := inherited;
  except
    Application.HandleException(nil);
  end;
end;

class procedure TACLGtk3CustomControl.DoSizeAllocate(
  AWidget: PGtkLayout; AGdkRect: PGdkRectangle; AGtk3Widget: TGtk3Widget); cdecl;
var
  LWidth, LHeight: guint;
begin
  AWidget.get_size(@LWidth, @LHeight);
  if (LWidth <> AGdkRect^.Width) or (LHeight <> AGdkRect^.Height) then
    AWidget.set_size(AGdkRect^.Width, AGdkRect^.Height);
  if not AGtk3Widget.InUpdate then
  begin
    if AGtk3Widget.LCLObject.ClientRectNeedsInterfaceUpdate then
      AGtk3Widget.LCLObject.DoAdjustClientRectChange;
  end;
end;

procedure TACLGtk3CustomControl.InitializeWidget;
begin
  inherited InitializeWidget;
  SetBorderStyle(TWinControlAccess(LCLObject).BorderStyle);
  SetVisible(LCLObject.HandleObjectShouldBeVisible);
end;

procedure TACLGtk3CustomControl.SetBorderStyle(AValue: TBorderStyle);
begin
  PGtkLayout(Widget)^.set_border_width(IfThen(AValue <> bsNone, 2));
end;

{ TACLGtk3AdvancedWindow }

function TACLGtk3AdvancedWindow.ClientToScreen(var P: TPoint): boolean;
begin
  P := P + GtkGetOrigin(Widget);
  Result := True;
end;

function TACLGtk3AdvancedWindow.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  LWindow: PGtkWindow;
begin
  FWidget := nil;
  try
    // TGtk3Window многое прячет у себя "под капотом", а нам нужно всего ничего
    // - правильно настроить исходное окно. Всё остальное пойдёт неизменным.
    // Можно было бы скопировать целый класс вместе с обвязкой...
    // Но, к счастью, нашёлся обходной манёвр:
    // Между созданием окна и его контентом вызывается SetText, на котором мы
    // дёрнем наш callback и сделаем донастройку.
    FCreatingWorkaround :=
      procedure
      var
        LWindow: PGtkWindow;
        LWndParent: PGtkWindow;
      begin
        LWindow := PGtkWindow(FWidget);
        if LWindow = nil then
        begin
          if LCLObject.Parent = nil then
            raise EInvalidOperation.Create('Gtk3: Window creation workaround failed');
          Exit; // Dont worry, just Form get used as Frame
        end;

        if Params.ExStyle and WS_EX_TOOLWINDOW <> 0 then
          LWindow^.set_type_hint(GDK_WINDOW_TYPE_HINT_UTILITY);
        if Params.ExStyle and WS_EX_LAYERED <> 0 then
          TACLGtk3AdvancedWindow.SetAlphaExposing(FWidget);
        if Params.ExStyle and WS_EX_NOACTIVATE <> 0 then
        begin
          Exclude(FWidgetType, wtHintWindow);
          LWindow^.set_type_hint(GDK_WINDOW_TYPE_HINT_UTILITY);
        end;

        if LCLObject.Parent = nil then
        begin
          LWndParent := TACLGtk3AdvancedWindow.ResolveWndParent(Params);
          if LWndParent <> nil then
            LWindow^.set_transient_for(LWndParent)
          else if TCustomForm(LCLObject).FormStyle in fsAllStayOnTop then
            LWindow^.set_keep_above(true);
        end;

        FCreatingWorkaround := nil;
      end;

    if Params.ExStyle and WS_EX_NOACTIVATE <> 0 then
      FWidgetType := [wtHintWindow]; // to force to the GTK_WINDOW_POPUP

    Result := inherited;

    if (Params.ExStyle and WS_EX_LAYERED <> 0) and Gtk3IsGtkWindow(Widget) then
    begin
      PGtkWindow(Widget)^.set_app_paintable(True);
      PGtkWindow(Widget)^.set_decorated(False);
      PGtkWindow(Widget)^.window^.set_decorations([]);
    end;
  finally
    FCreatingWorkaround := nil;
  end;
end;

function TACLGtk3AdvancedWindow.GtkEventPaint(Sender: PGtkWidget; AContext: Pcairo_t): Boolean;
var
  LPainter: ICairoPainter;
begin
  Result := True;
  if Supports(LCLObject, ICairoPainter, LPainter) then
    LPainter.PaintTo(Cairo.Pcairo_t(AContext))
  else
    Result := inherited;
end;

procedure TACLGtk3AdvancedWindow.InitializeWidget;
begin
  inherited;
  g_signal_connect_data(Widget, 'map-event', TGCallback(@OnMapped), Self, nil, G_CONNECT_DEFAULT);
end;

class function TACLGtk3AdvancedWindow.OnMapped(AWindow: PGtkWindow;
  AEvent: PGdkEventAny; AImpl: TACLGtk3AdvancedWindow): gboolean; cdecl;
begin
  if AImpl.LCLObject = Application.MainForm then
    LogEntry(acGeneralLogFileName, 'Main', 'WindowMapped');
  AImpl.SetBounds(
    AImpl.LCLObject.Left, AImpl.LCLObject.Top,
    AImpl.LCLObject.Width, AImpl.LCLObject.Height);
  Result := False;
end;

procedure TACLGtk3AdvancedWindow.OffsetMousePos(
  const aGlobalX, aGlobalY: double; APoint: PPoint);
begin
  APoint^ := APoint^ - GetClientOffset;
end;

procedure TACLGtk3AdvancedWindow.Repaint(const ARect: PRect);
begin
  if FParams.ExStyle and WS_EX_LAYERED = 0 then
    inherited;
end;

procedure TACLGtk3AdvancedWindow.SetBounds(ALeft, ATop, AWidth, AHeight: integer);
var
  LForm: TCustomForm;
  LFormSizeIsFixed: Boolean;

  function GetActualSize(ASize, AConstraintSize, ADefaultSize: Integer): Integer;
  begin
    if LFormSizeIsFixed then
      Result := ASize
    else if AConstraintSize > 0 then
      Result := AConstraintSize
    else
      Result := ADefaultSize;
  end;

var
  LGeometry: TGdkGeometry;
  LGeometryHints: TGdkWindowHints;
  LRect: TGdkRectangle;
  LWindow: PGtkWindow;
begin
  LWindow := PGtkWindow(Widget);
  BeginUpdate;
  try
    // Наша реализация решает сразу три проблемы:
    // 1) Оригинальная функция зачем-то сдвигает окно c BorderStyle = bsNone на
    //    Origin от Window.transient_for - это ломает наши дропдауны и меню.
    // 2) Оригинальная функция не разруливает ситуацию, когда Constraints.MaxWidth
    //    задан, а Constraints.MaxHeight нет (или наоборот)
    // 3) При работе на X11-бэке заметил (Alt.Linux 11 Gnome), что окно ATE не
    //    показывается на экране. Gtk+ Inspector показал, что CentralWidget формы
    //    (Layout внутри ScrollWindow) не аллокирован (1x1 по -1,-1). Причём повторяется
    //    это лишь на сложных формах. Что именно вызывает сбой - непонятно, но
    //    нашёл обходной манёвр: пока WidgetMapped = False, выставляем форме все
    //    Constraint-ы. После непосредственного показа формы - выставляем актуальные
    //    Похожая проблема была замечена на Manjaro 26, но там это решение не сработало
    //    - см. TACLWSForm.CheckAndFixGeometry

    LForm := TCustomForm(LCLObject);
    LFormSizeIsFixed := not WidgetMapped or
      (LForm.BorderStyle in [bsDialog, bsSingle, bsToolWindow]);

    LRect.x := ALeft;
    LRect.y := ATop;
    LRect.width := AWidth;
    LRect.Height := AHeight;
    LWindow^.size_allocate(@LRect);

    FillChar(LGeometry, SizeOf(LGeometry), 0);
    LGeometry.win_gravity := GDK_GRAVITY_NORTH_WEST;
    LGeometry.max_aspect := 1;
    LGeometry.height_inc := 1;
    LGeometry.width_inc := 1;
    LGeometry.base_width := LForm.Width;
    LGeometry.base_height := LForm.Height;
    LGeometry.min_height := GetActualSize(LForm.Height, LForm.Constraints.MinHeight, 0);
    LGeometry.max_height := GetActualSize(LForm.Height, LForm.Constraints.MaxHeight, MAXSHORT);
    LGeometry.min_width := GetActualSize(LForm.Width, LForm.Constraints.MinWidth, 0);
    LGeometry.max_width := GetActualSize(LForm.Width, LForm.Constraints.MaxWidth, MAXSHORT);
    LGeometryHints := [GDK_HINT_POS, GDK_HINT_BASE_SIZE];
    if (LForm.Constraints.MinWidth > 0) or (LForm.Constraints.MinHeight > 0) then
      LGeometryHints := LGeometryHints + [GDK_HINT_MIN_SIZE];
    if (LForm.Constraints.MaxWidth > 0) or (LForm.Constraints.MaxHeight > 0) then
      LGeometryHints := LGeometryHints + [GDK_HINT_MAX_SIZE];
    if LFormSizeIsFixed then
      LGeometryHints := LGeometryHints + [GDK_HINT_MAX_SIZE, GDK_HINT_MIN_SIZE];
    LWindow^.set_geometry_hints(nil, @LGeometry, LGeometryHints);

    if LWindow^.window <> nil then
    begin
      LWindow^.set_resizable(True);
      LWindow^.resize(AWidth, AHeight);
      LWindow^.move(ALeft, ATop);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLGtk3AdvancedWindow.SetText(const AValue: String);
begin
  // Эта хрень дергается между созданием Window и Layout. Cм.CreateHandle.
  if Assigned(FCreatingWorkaround) then FCreatingWorkaround();
  inherited SetText(AValue);
end;

class function TACLGtk3AdvancedWindow.ResolveWndParent(const AParams: TCreateParams): PGtkWindow;
var
  LWndParent: TGtk3Widget;
begin
  LWndParent := TGtk3Widget(AParams.WndParent);
  if AParams.Style and WS_CHILD = 0 then
  begin
    while (LWndParent <> nil) and not Gtk3IsGtkWindow(LWndParent.Widget) do
      LWndParent := LWndParent.getParent;
  end;
  if (LWndParent <> nil) and Gtk3IsGtkWindow(LWndParent.Widget) then
    Result := PGtkWindow(LWndParent.Widget)
  else
    Result := nil;
end;

class procedure TACLGtk3AdvancedWindow.SetAlphaExposing(AWidget: PGtkWidget);
var
  LScreen: PGdkScreen;
  LVisual: PGdkVisual;
begin
  AWidget^.set_app_paintable(True);
  LScreen := TGdkScreen.get_default;
  LVisual := LScreen^.get_rgba_visual;
  if (LVisual <> nil) and LScreen^.is_composited then
    AWidget^.set_visual(LVisual)
  else
    LogEntry(acGeneralLogFileName, 'Gtk3', 'Alpha-composing is unavailable')
end;

{ TACLGtk3PopupControl }

function TACLGtk3PopupControl.ClientToScreen(var P: TPoint): Boolean;
begin
  P := P + GtkGetOrigin(Widget);
  Result := True;
end;

function TACLGtk3PopupControl.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  LWindow: PGtkWindow;
  LWndParent: PGtkWindow;
begin
  FHasPaint := True;
  FFirstMapRect := NullRect;
  LWindow := TGtkWindow.new(GTK_WINDOW_POPUP);
  LWindow^.set_app_paintable(True);
  LWindow^.set_events(GDK_DEFAULT_EVENTS_MASK);
  LWindow^.set_decorated(False);
  LWindow^.set_has_resize_grip(False);
  LWindow^.set_resizable(true);
  LWindow^.set_type_hint(GDK_WINDOW_TYPE_HINT_POPUP_MENU); // not decorated
  FWidgetType := [wtWidget, wtWindow];
  FWidget := LWindow;

  LWndParent := TACLGtk3AdvancedWindow.ResolveWndParent(Params);
  if LWndParent <> nil then
    LWindow^.set_transient_for(LWndParent);
  if Params.ExStyle and WS_EX_LAYERED <> 0 then
    TACLGtk3AdvancedWindow.SetAlphaExposing(FWidget);
  FWidget^.realize;

  Result := FWidget;
end;

procedure TACLGtk3PopupControl.InitializeWidget;
begin
  inherited InitializeWidget;
  g_signal_connect_data(FWidget, 'event', TGCallback(@WidgetEvent), Self, nil, G_CONNECT_DEFAULT);
end;

function TACLGtk3PopupControl.GtkEventPaint(Sender: PGtkWidget; AContext: Pcairo_t): Boolean;
var
  LPainter: ICairoPainter;
begin
  Result := True;
  if Supports(LCLObject, ICairoPainter, LPainter) then
    LPainter.PaintTo(Cairo.Pcairo_t(AContext))
  else
    Result := inherited;
end;

procedure TACLGtk3PopupControl.SetBounds(ALeft, ATop, AWidth, AHeight: integer);
begin
  BeginUpdate;
  try
    inherited;
    Move(ALeft, ATop);
  finally
    EndUpdate;
  end;
end;

class function TACLGtk3PopupControl.WidgetEvent(
  Widget: PGtkWidget; Event: PGdkEvent; Data: GPointer): gboolean; cdecl;
begin
  Result := True;
  case event^.type_ of
    GDK_KEY_PRESS, GDK_KEY_RELEASE:
      TACLGtk3PopupControl(data).GtkEventKey(widget, event, event^.type_ = GDK_KEY_PRESS);
    GDK_MOTION_NOTIFY:
      TACLGtk3PopupControl(data).GtkEventMouseMove(widget, event);
  else
    Result := False;
  end;
end;

end.
