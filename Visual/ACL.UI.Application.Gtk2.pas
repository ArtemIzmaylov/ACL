{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*         Gtk2 Adapters and Helpers         *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2024-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Application.Gtk2;

{$I ACL.Config.inc} // FPC:OK

{$DEFINE DEBUG_MESSAGELOOP}

interface

uses
  LCLIntf,
  LCLType,
  LMessages,
  Messages,
  // Gtk
  Gtk2,
  Glib2,
  Gdk2,
  Gtk2Int,
  Gtk2Proc,
  Gtk2Def,
  Gtk2Extra,
  Gtk2Globals,
  Gtk2WSControls,
  WSLCLClasses,
  // System
  Classes,
  SysUtils,
  // VCL
  Controls;

type

  { TGtk2App }

  TGtk2EventCallback = procedure (AEvent: PGdkEvent; var AHandled: Boolean) of object;

  TGtk2App = class
  strict private
    class var FHandlerInit: Boolean;
    class var FInputTarget: PGtkWidget;
    class var FPopupCallback: TGtk2EventCallback;
    class var FPopupWindow: PGdkWindow;

    class procedure EnsureHandlerInit;
    class procedure Handler(event: PGdkEvent; data: gpointer); cdecl; static;
  public
    class procedure BeginPopup(APopupControl: TWinControl;
     ACallback: TGtk2EventCallback = nil);
    class procedure EndPopup;

    class procedure ProcessMessages;
    class procedure SetInputRedirection(AControl: TWinControl);
  end;

  { TGtk2Controls }

  TGtk2Controls = class
  strict private
    class function DrawNonClientBorder(Widget: PGtkWidget;
      Event: PGDKEventExpose; Data: gPointer): GBoolean; cdecl; static;
  public
    class procedure SetNonClientBorder(AControl: TWinControl; ASize: Integer);
  end;

  { TGtk2PopupControl }

  TGtk2PopupControl = class(TGtk2WSWinControl)
  protected
    class function MustBeFocusable(AControl: TWinControl): Boolean; virtual;
  published
    class function CreateHandle(
      const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class procedure SetBounds(const AWinControl: TWinControl;
      const ALeft, ATop, AWidth, AHeight: Integer); override;
  end;

implementation

{ TGtk2App }

class procedure TGtk2App.EnsureHandlerInit;
begin
  if not FHandlerInit then
  begin
    FHandlerInit := True;
    gdk_event_handler_set(Handler, nil, nil);
  end;
end;

class procedure TGtk2App.Handler(event: PGdkEvent; data: gpointer); cdecl;
var
  AHandled: Boolean;
begin
  if Assigned(FPopupCallback) then
  begin
    AHandled := False;
    FPopupCallback(event, AHandled);
    if AHandled then Exit;
  end;

  // Input-Redirection
  case event._type of
    GDK_MOTION_NOTIFY,
    GDK_BUTTON_RELEASE,
    GDK_BUTTON_PRESS,
    GDK_2BUTTON_PRESS,
    GDK_3BUTTON_PRESS,
    GDK_KEY_PRESS,
    GDK_KEY_RELEASE,
    GDK_SCROLL:
      if FInputTarget <> nil then
      begin
        gtk_widget_event(FInputTarget, event);
        Exit;
      end;
  end;

  gtk_main_do_event(event);
end;

class procedure TGtk2App.BeginPopup(
  APopupControl: TWinControl; ACallback: TGtk2EventCallback);
{$IFNDEF DEBUG_MESSAGELOOP}
const
  GdkHookFlags = GDK_POINTER_MOTION_MASK or
    GDK_BUTTON_PRESS_MASK or GDK_BUTTON_RELEASE_MASK or
    GDK_ENTER_NOTIFY_MASK or GDK_LEAVE_NOTIFY_MASK;
{$ENDIF}
var
{$IFNDEF DEBUG_MESSAGELOOP}
  AAttrs: TGdkWindowAttr;
  ACurrTime: Integer;
{$ENDIF}
  AWindow: PGdkWindow;
begin
  if FPopupWindow <> nil then
    raise EInvalidOperation.Create('Gtk2: recursive popups are not supported');

{$IFDEF DEBUG_MESSAGELOOP}
  AWindow := nil;
{$ELSE}
  // AI: ref.to: gtk2/gtkmenu.c, menu_grab_transfer_window_get
  FillChar(AAttrs{%H-}, SizeOf(AAttrs), 0);
  AAttrs.x := -100;
  AAttrs.y := -100;
  AAttrs.width := 10;
  AAttrs.height := 10;
  AAttrs.override_redirect := True;
  AAttrs.window_type := GDK_WINDOW_TEMP;
  AAttrs.wclass := GDK_INPUT_ONLY;

  ACurrTime := gtk_get_current_event_time;
  AWindow := gtk_widget_get_root_window({%H-}PGtkWidget(APopupControl.Handle));
  AWindow := gdk_window_new(AWindow, @AAttrs, GDK_WA_X or GDK_WA_Y or GDK_WA_NOREDIR);
  gdk_window_show(AWindow);

  // захватываем мышь глобально (на уровне оконного менеджера)
  if gdk_pointer_grab(AWindow, True, GdkHookFlags, nil, nil, ACurrTime) <> 0 then
  begin
    gdk_window_destroy(AWindow);
    raise EInvalidOperation.Create('GTK2.Popup: unable to grap the pointer');
  end;

  //#AI:
  // В FlyWM (Astra Linux) при захвате клавиатурного хука, top-level форма
  // в режиме StayOnTop проваливается на задний план.
  //
  // Поверхостный тест показал, что в принципе-то граббинг клавиатуры нам
  // и не нужен - мы перехватываем нужные события через SetKeyboardRedirection
  //
  // Захватываем клавиатуру глобально
  //if gdk_keyboard_grab(AWindow, True, ACurrTime) <> 0 then
  //begin
  //  gdk_display_pointer_ungrab(gdk_drawable_get_display(AWindow), ACurrTime);
  //  gdk_window_destroy(AWindow);
  //  raise EInvalidOperation.Create('GTK2.Popup: unable to grap the keyboard');
  //end;
{$ENDIF}

  // если мы тут - все прошло ОК, инициализируем приемник сообщений и перехватчик
  try
    FPopupCallback := ACallback;
    FPopupWindow := AWindow;
    EnsureHandlerInit;
  except
    EndPopup;
    raise;
  end;
end;

class procedure TGtk2App.EndPopup;
var
  LDisplay: PGdkDisplay;
begin
  FPopupCallback := nil;
  SetInputRedirection(nil);

  if FPopupWindow <> nil then
  try
    LDisplay := gdk_drawable_get_display(FPopupWindow);
    //gdk_display_keyboard_ungrab(ADisplay, GDK_CURRENT_TIME);
    gdk_display_pointer_ungrab(LDisplay, GDK_CURRENT_TIME);
    gdk_window_destroy(FPopupWindow);
  finally
    FPopupWindow := nil;
  end;
end;

class procedure TGtk2App.ProcessMessages;
begin
  Gtk2WidgetSet.AppProcessMessages;
end;

class procedure TGtk2App.SetInputRedirection(AControl: TWinControl);
begin
  if AControl <> nil then
    FInputTarget := GetFixedWidget({%H-}PGtkWidget(AControl.Handle))
  else
    FInputTarget := nil;

  EnsureHandlerInit;
end;

{ TGtk2Controls }

class function TGtk2Controls.DrawNonClientBorder(Widget: PGtkWidget;
  Event: PGDKEventExpose; Data: gPointer): GBoolean; cdecl;
var
  LPrevClient: PGtkWidget;
  LWidgetInfo: PWinWidgetInfo;
  LWnd: HWND;
  LWndDC: HDC;
begin
  if gtk_container_get_border_width(PGtkContainer(Widget)) > 0 then
  begin
    LWnd := {%H-}HWND(Widget);
    LWidgetInfo := GetWidgetInfo(Widget);

    // AI: делаем вот такой финт ушами, чтобы LCL-ая обвязка создала DC именно
    // вокруг контейнер-виджета, а не вокруг его CoreWidget (как оно по есть)
    LPrevClient := LWidgetInfo^.ClientWidget;
    try
      LWidgetInfo^.ClientWidget := Widget;
      LWndDC := GetDC(LWnd);
    finally
      LWidgetInfo^.ClientWidget := LPrevClient;
    end;

    SetWindowOrgEx(LWndDC, -Widget^.Allocation.x, -Widget^.Allocation.y, nil);
    SendMessage(LWnd, WM_NCPAINT, 0, LWndDC);
    ReleaseDC(LWnd, LWndDC);
  end;
  Result := CallBackDefaultReturn;
end;

class procedure TGtk2Controls.SetNonClientBorder(AControl: TWinControl; ASize: Integer);
var
  LWidget: PGtkWidget;
begin
  LWidget := {%H-}PGtkWidget(AControl.Handle);
  // Ref.to: GTKAPIWidget_new (Gtk2WinapiWindow.pp)
  if GTK_IS_CONTAINER(LWidget) then
  begin
    gtk_container_set_border_width(GTK_CONTAINER(LWidget), ASize);
    ConnectSignalAfter(GTK_OBJECT(LWidget), 'expose-event', @DrawNonClientBorder, AControl);
  end;
end;

{ TGtk2PopupControl }

class function TGtk2PopupControl.CreateHandle(
  const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  AAllocation: TGtkAllocation;
  AClientAreaWidget: PGtkWidget;
  AWidget: PGtkWidget;
  AWidgetInfo: PWidgetInfo;
begin
  if (AParams.Style and WS_POPUP) = 0 then
    Exit(inherited);

  // В этом случае у нас вместо контрола будет урезанная попап-форма
  if MustBeFocusable(AWinControl) then
    AWidget := gtk_window_new(GTK_WINDOW_TOPLEVEL) // см. описание TGtk2PopupPanel
  else
    AWidget := gtk_window_new(GTK_WINDOW_POPUP);

  gtk_widget_set_app_paintable(AWidget, True);
  gtk_window_set_decorated(PGtkWindow(AWidget), False);
  gtk_window_set_skip_taskbar_hint(PGtkWindow(AWidget), True);
  if AParams.WndParent <> 0 then
  begin
    gtk_window_set_transient_for(PGtkWindow(AWidget),
      GTK_WINDOW(gtk_widget_get_toplevel({%H-}PGtkWidget(AParams.WndParent))));
  end
  else
    gtk_window_set_keep_above(PGtkWindow(AWidget), true); // stay-on-top

  AWidgetInfo := CreateWidgetInfo(AWidget, AWinControl, AParams);
  FillChar(AWidgetInfo^.FormWindowState, SizeOf(AWidgetInfo^.FormWindowState), #0);
  AWidgetInfo^.FormWindowState.new_window_state := GDK_WINDOW_STATE_WITHDRAWN;

  // Размеры
  AAllocation.X := AParams.X;
  AAllocation.Y := AParams.Y;
  AAllocation.Width := AParams.Width;
  AAllocation.Height := AParams.Height;
  gtk_widget_size_allocate(AWidget, @AAllocation);

  Set_RC_Name(AWinControl, AWidget);
  SetCallbacks(PGtkObject(AWidget), AWinControl);

  // Если у попап-контрола есть дочерние элементы - мы должны создать подложку,
  // на которой они будут лежать (по аналогии с тем, как делается для формы -
  // см. CreateFormContents), в противном случае LCL не найдет куда их положить
  // и контролы не будут видны на экране.
  if AWinControl.ControlCount > 0 then
  begin
    AClientAreaWidget := gtk_layout_new(nil, nil);
    gtk_container_add(PGtkContainer(AWidget), AClientAreaWidget);
    gtk_widget_show(AClientAreaWidget);
    SetFixedWidget(AWidget, AClientAreaWidget);
    SetMainWidget(AWidget, AClientAreaWidget);
  end
  else
    AWidgetInfo^.ClientWidget := AWidget; // для Paint и MouseCapture, после setCallbacks

  // После того, как мы актуализировали ClientWidget - ставим обработчик сигнала на LM_PAINT
  Gtk2WidgetSet.SetCallback(LM_PAINT, PGtkObject(AWidget), AWinControl);

  // Финалочка
  Result := TLCLHandle({%H-}PtrUInt(AWidget));
end;

class function TGtk2PopupControl.MustBeFocusable(AControl: TWinControl): Boolean;
begin
  Result := False;
end;

class procedure TGtk2PopupControl.SetBounds(
  const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer);
var
  AWindow: PGtkWindow;
begin
  AWindow := {%H-}PGtkWindow(AWinControl.Handle);
  if GTK_IS_WINDOW(AWindow) then
  begin
    gtk_window_move(AWindow, ALeft, ATop);
    gtk_window_resize(AWindow, AWidth, AHeight);
  end
  else
    inherited SetBounds(AWinControl, ALeft, ATop, AWidth, AHeight);
end;

end.
