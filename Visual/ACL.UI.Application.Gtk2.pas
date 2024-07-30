////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Gtk2 Adapters and Helpers
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Application.Gtk2;

{$I ACL.Config.inc}

{$SCOPEDENUMS ON}

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
  Generics.Collections,
  SysUtils,
  // VCL
  Controls,
  Forms;

type
  TGtk2EventCallback = procedure (AEvent: PGdkEvent; var AHandled: Boolean) of object;

  { TGtk2App }

  TGtk2App = class
  strict private
    class var FHandlerInit: Boolean;
    class var FInputTarget: PGtkWidget;
    class var FHooks: TStack<TGtk2EventCallback>;
    class var FPopupWindow: PGdkWindow;

    class procedure EnsureHandlerInit;
    class procedure Handler(event: PGdkEvent; data: gpointer); cdecl; static;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure Hook(ACallback: TGtk2EventCallback);
    class procedure Unhook;

    class procedure BeginPopup(APopupControl: TWinControl;
     ACallback: TGtk2EventCallback = nil);
    class procedure EndPopup;

    class procedure ProcessMessages;
    class procedure SetInputRedirection(AControl: TWinControl);
  end;

  { TGtk2Controls }

  TGtk2Controls = class
  strict private type
    TDragState = (None, Started, Canceled);
  strict private
    class var FDragState: TDragState;
    class var FDragTarget: TRect;

    class procedure DoDragEvents(AEvent: PGdkEvent; var AHandled: Boolean);
    class function DoDrawNonClientBorder(Widget: PGtkWidget;
      Event: PGDKEventExpose; Data: gPointer): GBoolean; cdecl; static;
  public
    class function CheckStartDrag(AControl: TWinControl; X, Y, AThreshold: Integer): Boolean;
    class procedure SetNonClientBorder(AControl: TWinControl; ASize: Integer);
  end;

  { TACLGtk2PopupControl }

  TACLGtk2PopupControl = class(TGtk2WSWinControl)
  protected
    class function MustBeFocusable(AControl: TWinControl): Boolean; virtual;
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class procedure SetBounds(const AWinControl: TWinControl;
      const ALeft, ATop, AWidth, AHeight: Integer); override;
  end;

function CheckStartDragImpl(AControl: TWinControl; X, Y, AThreshold: Integer): Boolean;
implementation

uses
  ACL.Geometry,
  ACL.Geometry.Utils;

type
  TGtk2WidgetSetAccess = class(TGtk2WidgetSet);

function CheckStartDragImpl(AControl: TWinControl; X, Y, AThreshold: Integer): Boolean;
begin
  Result := TGtk2Controls.CheckStartDrag(AControl, X, Y, AThreshold);
end;

function WidgetSet: TGtk2WidgetSetAccess;
begin
  Result := TGtk2WidgetSetAccess(GTK2WidgetSet);
end;

{ TGtk2App }

class constructor TGtk2App.Create;
begin
  FHooks := TStack<TGtk2EventCallback>.Create;
end;

class destructor TGtk2App.Destroy;
begin
  FreeAndNil(FHooks);
end;

class procedure TGtk2App.Hook(ACallback: TGtk2EventCallback);
begin
  FHooks.Push(ACallback);
  EnsureHandlerInit;
end;

class procedure TGtk2App.Unhook;
begin
  FHooks.Pop;
end;

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
  LCallback: TGtk2EventCallback;
  LHandled: Boolean;
begin
  if FHooks.Count > 0 then
  begin
    // #AI:
    // Без вызова GtkKeySnooper функции GetAsyncKeyState/GetKeyState
    // будут возвращать неактуальные данные, а у нас в тулбарах есть
    // проверки на нажатость кнопок мыши и Escape
    if event._type = GDK_KEY_PRESS then
       GtkKeySnooper(nil, @event.key, WidgetSet.FKeyStateList_);

    LHandled := False;
    LCallback := FHooks.Peek;
    LCallback(event, LHandled);

    if LHandled then
    begin
      // #AI:
      // GDK_KEY_RELEASE обрабатываем после callback-а и только в том случае,
      // если callback запросил "съесть" эвент. В штатном режиме, snopper уже
      // дернется со стороны обработчика gtk_main_do_event
      if event._type = GDK_KEY_RELEASE then
        GtkKeySnooper(nil, @event.key, WidgetSet.FKeyStateList_);
      Exit;
    end;
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
  FPopupWindow := AWindow;
  try
    Hook(ACallback);
  except
    EndPopup;
    raise;
  end;
end;

class procedure TGtk2App.EndPopup;
var
  LDisplay: PGdkDisplay;
begin
  Unhook;
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
  WidgetSet.AppProcessMessages;
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

class function TGtk2Controls.CheckStartDrag(
  AControl: TWinControl; X, Y, AThreshold: Integer): Boolean;
var
  LPoint: TPoint;
begin
  FDragState := TDragState.None;
  FDragTarget := TRect.Create(AControl.ClientToScreen(Point(X, Y)));
  FDragTarget.Inflate(AThreshold);

  TGtk2App.Hook(DoDragEvents);
  try
    repeat
      try
        TGtk2App.ProcessMessages;
      except
        if Application.CaptureExceptions then
          Application.HandleException(AControl)
        else
          raise;
      end;
      if Application.Terminated or not AControl.Visible then
        Break;
      Application.Idle(True);
    until FDragState <> TDragState.None;
    Result := FDragState = TDragState.Started;
  finally
    TGtk2App.Unhook;
  end;
end;

class function TGtk2Controls.DoDrawNonClientBorder(Widget: PGtkWidget;
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

class procedure TGtk2Controls.DoDragEvents(AEvent: PGdkEvent; var AHandled: Boolean);
begin
  if FDragState = TDragState.None then
    case AEvent._type of
      GDK_MOTION_NOTIFY:
        if not FDragTarget.Contains(Mouse.CursorPos) then
          FDragState := TDragState.Started;
      GDK_BUTTON_RELEASE:
        begin
          FDragState := TDragState.Canceled;
          //AHandled := True;
        end;
    end;
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
    ConnectSignalAfter(GTK_OBJECT(LWidget), 'expose-event', @DoDrawNonClientBorder, AControl);
  end;
end;

{ TACLGtk2PopupControl }

class function TACLGtk2PopupControl.CreateHandle(
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
  WidgetSet.SetCallback(LM_PAINT, PGtkObject(AWidget), AWinControl);

  // Финалочка
  Result := TLCLHandle({%H-}PtrUInt(AWidget));
end;

class function TACLGtk2PopupControl.MustBeFocusable(AControl: TWinControl): Boolean;
begin
  Result := False;
end;

class procedure TACLGtk2PopupControl.SetBounds(
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
