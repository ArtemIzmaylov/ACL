////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Gtk3 Adapters and Helpers
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Core.Impl.Gtk3;

{$I ACL.Config.inc}

{$SCOPEDENUMS ON}

{$DEFINE DEBUG_MESSAGELOOP}

{$MESSAGE WARN 'LazGtk3 проверить:'}
// LCL-Gtk2 безусловно релизит кэпчу на button-up (см.gtkMouseBtnRelease)
interface

uses
  LCLIntf,
  LCLType,
  LMessages,
  Messages,
  // Gtk
  Cairo,
  Glib2,
  Gtk3Int,
  Gtk3Objects,
  LazGObject2,
  LazGtk3,
  LazGdk3,
  LazGdkPixbuf2,
  Gtk3WSControls,
  Gtk3WSForms,
  Gtk3Widgets,
  WSLCLClasses,
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
  ACL.Utils.DPIAware,
  ACL.Utils.Common,
  // VCL
  Graphics,
  Controls,
  Forms;

type

  { IACLLayeredPaint }

  IACLLayeredPaint = interface
  ['{3FE006F2-67DE-4317-B402-D872A77373E4}']
    procedure PaintTo(ACairo: Pcairo_t);
  end;

  { TGtkApp }

  TGtkEventCallback = procedure (AType: TGdkEventType; AEvent: PGdkEvent; var AHandled: Boolean) of object;
  TGtkApp = class
  strict private
    class var FFreeNotifier: TACLComponentFreeNotifier;
    class var FHandlerInit: Boolean;
    class var FHooks: TList<TGtkEventCallback>;
    class var FInputTarget: PGtkWidget;
    class var FInputTargetWnd: TWinControl;
    class var FOldExceptionHandler: TExceptionEvent;
    class var FPopupControl: TWinControl;
    class var FPopupError: string;
    class var FPopupWindow: PGdkWindow;

    class procedure Handler(event: PGdkEvent; data: gpointer); cdecl; static;
    class procedure HandlerException(Sender: TObject; Error: Exception);
    class procedure HandlerInit;
    class procedure HandlerOnDestroy(data: gpointer); cdecl; static;
    class procedure HandlerRemoving(Sender: TComponent);
    class procedure PopupEventHandler(AType: TGdkEventType; AEvent: PGdkEvent; var AHandled: Boolean);
  public
    class constructor Create;
    class destructor Destroy;
    class procedure Hook(ACallback: TGtkEventCallback);
    class procedure Unhook; overload;
    class procedure Unhook(ACallback: TGtkEventCallback); overload;

    class procedure BeginPopup(APopupControl: TWinControl); overload;
    class procedure BeginPopup(APopupControl: TWinControl; ACallback: TGtkEventCallback); overload;
    class procedure EndPopup(AControl: TWinControl);
    class function IsPopupAborted: Boolean;

    class procedure ProcessMessages;
    class procedure SetInputRedirection(AControl: TWinControl);
  end;

  { TACLWSHintWindow }

  TACLWSHintWindow = class(TGtk3WSHintWindow);

  { TACLWSPopupControl }

  TACLWSPopupControl = class(TGtk3WSWinControl)
  //protected
  //  class function MustBeFocusable(AControl: TWinControl): Boolean; virtual;
  //published
  //  class function CreateHandle(const AWinControl: TWinControl;
  //    const AParams: TCreateParams): TLCLHandle; override;
  //  class procedure SetColor(const AWinControl: TWinControl); override;
  //  class procedure SetBounds(const AWinControl: TWinControl;
  //    const ALeft, ATop, AWidth, AHeight: Integer); override;
  end;

  { TACLWSForm }

  TACLWSForm = class(TGtk3WSCustomForm)
  //protected
  //  class function ResolveWndParent(const AParams: TCreateParams): HWND;
  //published
  //  class function CreateHandle(const AWinControl: TWinControl;
  //    const AParams: TCreateParams): TLCLHandle; override;
  //  class procedure ShowHide(const AWinControl: TWinControl); override;
  end;

  { TACLWSAdvancedForm }

  TACLWSAdvancedForm = class(TGtk3WSCustomForm)
  //strict private
  //  class function DoAlphaExposing(Widget: PGtkWidget;
  //    Event: PGDKEventExpose; Data: gPointer): GBoolean; cdecl; static;
  //  class function DoRealize(Widget: PGtkWidget; Data: Pointer): GBoolean; cdecl; static;
  //published
  //  class function CreateHandle(const AWinControl: TWinControl;
  //    const AParams: TCreateParams): TLCLHandle; override;
  //  class procedure SetAlphaExposing(AWidget: PGtkWidget; AWidgetInfo: PWidgetInfo);
  //  class procedure SetCallbacks(const AWidget: PGtkWidget;
  //    const AWidgetInfo: PWidgetInfo); override;
  //  class procedure SetColor(const AWinControl: TWinControl); override;
  //  class procedure SetFormBorderStyle(const AForm: TCustomForm;
  //    const AFormBorderStyle: TFormBorderStyle); override;
  //  class procedure SetFormStyle(const AForm: TCustomform;
  //    const AFormStyle, AOldFormStyle: TFormStyle); override;
  //  class procedure SetWindowCapabities(AForm: TCustomForm; AWidget: PGtkWidget);
  //  class procedure ShowHide(const AWinControl: TWinControl); override;
  end;

  { TACLWSCustomControl }

  TACLWSCustomControl = class(TGtk3WSWinControl)
  published
    class function CreateHandle(
      const AControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class procedure SetBorderStyle(const AWinControl: TWinControl;
      const ABorderStyle: TBorderStyle); override;
  end;

  { TACLWSPopupWindow }

  TACLWSPopupWindow = class(TACLWSAdvancedForm);

  { TACLWSScrollingControl }

  TACLWSScrollingControl = class(TACLWSCustomControl)
  public
    class procedure DispatchNonClientMessage(
      AControl: TWinControl; var AMessage: TMessage); static;
  end;

  { TACLStartDragHelper }

  TACLStartDragHelper = class
  strict private type
    TDragState = (None, Started, Canceled);
  strict private
    class var FDragState: TDragState;
    class var FDragTarget: TRect;
    class procedure DoDragEvents(AType: TGdkEventType; AEvent: PGdkEvent; var AHandled: Boolean);
  public
    class function Check(AControl: TWinControl; X, Y, AThreshold: Integer): Boolean;
  end;

function LoadDialogIcon(AOwnerWnd: TWndHandle; AType: TMsgDlgType; ASize: Integer): TACLDib;
procedure SetDragImageListOpacity(Opacity: Byte);
procedure SetWindowStayOnTop(AWnd: TWndHandle; AValue: Boolean);

function GtkNCGetCursor(AHitCode: Integer): TCursor;
function GtkNCProcessMessage(AForm: TCustomForm; var Msg: TLMMouse): Boolean;
procedure GtkNCStartDrag(AForm: TCustomForm; ALocalX, ALocalY, AHitCode: Integer; AImmediately: Boolean = False);

function GtkLoadStockIcon(AWidget: PGtkWidget; AName: PChar; ASize: Integer): TACLDib;
implementation

uses
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.UI.Controls.Base,
  ACL.UI.Forms.Base;

type
  TFormAccess = class(TForm);
  TWinControlAccess = class(TWinControl);
  TGtk3WidgetSetAccess = class(TGtk3WidgetSet);

  { TACLGtk3CustomControl }

  // based on TGtk3Panel
  TACLGtk3CustomControl = class(TGtk3Bin)
  strict private
    class procedure DoSizeAllocate(AWidget: PGtkLayout;
      AGdkRect: PGdkRectangle; AGtk3Widget: TGtk3Widget); cdecl; static;
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
    function DeliverMessage(var Msg; const AIsInputEvent: Boolean=False): LRESULT; override;
    procedure InitializeWidget; override;
    procedure SetBorderStyle(AValue: TBorderStyle);
  end;

procedure SetDragImageListOpacity(Opacity: Byte);
var
  LWnd: PGtkWindow;
begin
  if Assigned(GTK3WidgetSet) then
  begin
    LWnd := PGtkWindow(TGtk3WidgetSetAccess(GTK3WidgetSet).FDragImageList);
    if LWnd <> nil then
      LWnd^.set_opacity(Opacity / 255);
  end;
end;

function GtkLoadStockIcon(AWidget: PGtkWidget; AName: PChar; ASize: Integer): TACLDib;
var
  LError: PGError;
  LIcon: PGdkPixbuf;
  LIconSet: PGtkIconTheme;
  I: Integer;
begin
  Result := nil;
  LError := nil;
  LIcon := gtk_icon_theme_load_icon(gtk_icon_theme_get_default, AName, ASize, [], @LError);
  if LIcon <> nil then
  try
    Result := TACLDib.Create;
    Result.Assign(LIcon);
  finally
    g_object_unref(LIcon);
  end;
  g_clear_error(@LError);
end;

function GtkNCGetCursor(AHitCode: Integer): TCursor;
const
  CursorMap: array [HTLEFT..HTBOTTOMRIGHT] of TCursor = (
    crSizeWE, crSizeWE, crSizeNS, crSizeNW,
    crSizeNE, crSizeNS, crSizeSW, crSizeSE
 );
begin
  case AHitCode of
    HTLEFT..HTBOTTOMRIGHT:
      Result := CursorMap[AHitCode];
  else
    Result := crArrow;
  end;
end;

function GtkNCProcessMessage(AForm: TCustomForm; var Msg: TLMMouse): Boolean;
var
  LHitCode: Integer;
  LPoint: TSmallPoint;
begin
  Result := False;
  case Msg.Msg of
    LM_LBUTTONDBLCLK:
      begin
        LHitCode := TACLControls.NCHitTest(AForm, Msg);
        if LHitCode = HTCAPTION then
        begin
          if AForm.WindowState = wsMaximized then
            AForm.WindowState := wsNormal
          else
            AForm.WindowState := wsMaximized;
        end;
        Result := LHitCode <> HTCLIENT;
      end;

    LM_LBUTTONDOWN:
    begin
      LHitCode := TACLControls.NCHitTest(AForm, Msg);
      case LHitCode of
        HTLEFT..HTBOTTOMRIGHT:
          GtkNCStartDrag(AForm, Msg.XPos, Msg.YPos, LHitCode, True);
        HTCAPTION:
          GtkNCStartDrag(AForm, Msg.XPos, Msg.YPos, LHitCode, False);
        //HTSYSMENU:
        //  gdk_window_show_window_menu(gtk_widget_get_root_window(PGtkWidget(Handle)), gtk_get_current_event);
      end;
      Result := LHitCode <> HTCLIENT;
    end
  end;
end;

procedure GtkNCStartDrag(AForm: TCustomForm; ALocalX, ALocalY, AHitCode: Integer; AImmediately: Boolean);
const
  BorderMap: array[HTLEFT..HTBOTTOMRIGHT] of TGdkWindowEdge = (
    GDK_WINDOW_EDGE_WEST, GDK_WINDOW_EDGE_EAST,
    GDK_WINDOW_EDGE_NORTH, GDK_WINDOW_EDGE_NORTH_WEST, GDK_WINDOW_EDGE_NORTH_EAST,
    GDK_WINDOW_EDGE_SOUTH, GDK_WINDOW_EDGE_SOUTH_WEST, GDK_WINDOW_EDGE_SOUTH_EAST
  );
var
  LDragThreshold: Integer;
  LXPos, LYPos: gint;
  LScreenPoint: TPoint;
  LWindow: PGtkWindow;
begin
  //LDragThreshold := dpiApply(Mouse.DragThreshold, acGetCurrentDpi(AForm));
  //if AImmediately or CheckStartDragImpl(AForm, ALocalX, ALocalY, LDragThreshold) then
  //begin
  //  TFormAccess(AForm).MouseCapture := False;
  //  LWindow := PGtkWindow(AForm.Handle);
  //  LScreenPoint := AForm.ClientToScreen(Point(ALocalX, ALocalY));
  //  LastMouse.Down := False;
  //  case AHitCode of
  //    HTLEFT..HTBOTTOMRIGHT:
  //      gtk_window_begin_resize_drag(LWindow, BorderMap[AHitCode], 1,
  //        LScreenPoint.X, LScreenPoint.Y, GDK_CURRENT_TIME);
  //  else
  //    begin
  //      LXPos := 0; LYPos := 0;
  //      gdk_window_get_origin(GetControlWindow(LWindow), @LXPos, @LYPos);
  //      gtk_widget_set_uposition(PGtkWidget(LWindow), LXPos, LYPos);
  //      gtk_window_begin_move_drag(LWindow, 1, LScreenPoint.X, LScreenPoint.Y, GDK_CURRENT_TIME);
  //    end;
  //  end;
  //end;
  {$MESSAGE WARN 'LazGtk3'}
  raise ENotImplemented.Create('LazGtk3');
end;

function IsChild(AChild, AParent: PGtkWidget): Boolean;
begin
  while AChild <> nil do
  begin
    if AChild = AParent then
      Exit(True);
    AChild := AChild.parent;
  end;
  Result := False;
end;

function LoadDialogIcon(AOwnerWnd: TWndHandle; AType: TMsgDlgType; ASize: Integer): TACLDib;
const
  Map: array[TMsgDlgType] of PChar = (
    'gtk-dialog-warning', 'gtk-dialog-error', 'gtk-dialog-info', 'gtk-dialog-question', ''
  );
begin
  Result := GtkLoadStockIcon(nil, Map[AType], ASize);
end;

procedure SetWindowStayOnTop(AWnd: TWndHandle; AValue: Boolean);
var
  LWindow: TGtk3Widget;
begin
  if Safe.Cast(TObject(AWnd), TGtk3Window, LWindow) then
    LWindow.GetWindow.set_keep_above(AValue);
end;

function WidgetSet: TGtk3WidgetSetAccess;
begin
  Result := TGtk3WidgetSetAccess(GTK3WidgetSet);
end;

{ TACLStartDragHelper }

class function TACLStartDragHelper.Check(AControl: TWinControl; X, Y, AThreshold: Integer): Boolean;
var
  LPoint: TPoint;
begin
  FDragState := TDragState.None;
  FDragTarget := TRect.Create(AControl.ClientToScreen(Point(X, Y)));
  FDragTarget.Inflate(AThreshold);

  TGtkApp.Hook(DoDragEvents);
  try
    repeat
      try
        TGtkApp.ProcessMessages;
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
    TGtkApp.Unhook;
  end;
end;

class procedure TACLStartDragHelper.DoDragEvents(
  AType: TGdkEventType; AEvent: PGdkEvent; var AHandled: Boolean);
begin
  if FDragState = TDragState.None then
    case AType of
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

{ TGtkApp }

class constructor TGtkApp.Create;
begin
  FHooks := TList<TGtkEventCallback>.Create;
  FFreeNotifier := TACLComponentFreeNotifier.Create(nil);
  FFreeNotifier.OnFreeNotify := HandlerRemoving;
end;

class destructor TGtkApp.Destroy;
begin
  if FHandlerInit then
  begin
    FHandlerInit := False;
    gdk_event_handler_set(@gtk_main_do_event, nil, nil);
  end;
  FreeAndNil(FFreeNotifier);
  FreeAndNil(FHooks);
end;

class procedure TGtkApp.BeginPopup(APopupControl: TWinControl);
begin
  BeginPopup(APopupControl, PopupEventHandler);
end;

class procedure TGtkApp.BeginPopup(
  APopupControl: TWinControl; ACallback: TGtkEventCallback);
//{$IFNDEF DEBUG_MESSAGELOOP}
//const
//  GdkHookFlags = GDK_POINTER_MOTION_MASK or
//    GDK_BUTTON_PRESS_MASK or GDK_BUTTON_RELEASE_MASK or
//    GDK_ENTER_NOTIFY_MASK or GDK_LEAVE_NOTIFY_MASK;
//{$ENDIF}
var
//{$IFNDEF DEBUG_MESSAGELOOP}
//  AAttrs: TGdkWindowAttr;
//  ACurrTime: Integer;
//{$ENDIF}
  AWindow: PGdkWindow;
begin
  if FPopupWindow <> nil then
    raise EInvalidOperation.Create('Gtk3: recursive popups are not supported');

  {$MESSAGE WARN 'LazGtk3'}
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
    raise EInvalidOperation.Create('GTK3.Popup: unable to grap the pointer');
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
  FPopupError := '';
  FPopupControl := APopupControl;
  FPopupWindow := AWindow;
  try
    FOldExceptionHandler := Application.OnException;
    Application.OnException := HandlerException;
    Hook(ACallback);
  except
    EndPopup(FPopupControl);
    raise;
  end;
end;

class procedure TGtkApp.EndPopup(AControl: TWinControl);
var
  LDisplay: PGdkDisplay;
begin
  if FPopupControl <> AControl then Exit;

  Unhook;
  FPopupControl := nil;
  SetInputRedirection(nil);
  Application.OnException := FOldExceptionHandler;
  if FPopupWindow <> nil then
  try
    {$MESSAGE WARN 'LazGtk3'}
    //LDisplay := gdk_drawable_get_display(FPopupWindow);
    ////gdk_display_keyboard_ungrab(ADisplay, GDK_CURRENT_TIME);
    //gdk_display_pointer_ungrab(LDisplay, GDK_CURRENT_TIME);
    //gdk_window_destroy(FPopupWindow);
  finally
    FPopupWindow := nil;
  end;
  if FPopupError <> '' then
    raise Exception.Create(FPopupError);
end;

class procedure TGtkApp.Handler(event: PGdkEvent; data: gpointer); cdecl;
var
  LCallback: TGtkEventCallback;
  LHandled: Boolean;
begin
  if (FHooks <> nil) and (FHooks.Count > 0) then
  begin
    LHandled := False;
    LCallback := FHooks.Last;
    LCallback(event^.type_, event, LHandled);
    if LHandled then Exit;
  end;

  // Input-Redirection
  case event.type_ of
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

class procedure TGtkApp.HandlerException(Sender: TObject; Error: Exception);
begin
  FPopupError := Error.ToString;
end;

class procedure TGtkApp.HandlerInit;
begin
  if not FHandlerInit then
  begin
    FHandlerInit := True;
    gdk_event_handler_set(Handler, nil, HandlerOnDestroy);
  end;
end;

class procedure TGtkApp.HandlerOnDestroy(data: gpointer); cdecl;
begin
  FHandlerInit := False;
end;

class procedure TGtkApp.HandlerRemoving(Sender: TComponent);
begin
  if FInputTargetWnd = Sender then
    SetInputRedirection(nil);
end;

class procedure TGtkApp.Hook(ACallback: TGtkEventCallback);
begin
  FHooks.Add(ACallback);
  HandlerInit;
end;

class procedure TGtkApp.Unhook;
begin
  FHooks.Delete(FHooks.Count - 1);
end;

class procedure TGtkApp.Unhook(ACallback: TGtkEventCallback);
begin
  FHooks.Remove(ACallback);
end;

class function TGtkApp.IsPopupAborted: Boolean;
begin
  Result := FPopupError <> '';
end;

class procedure TGtkApp.ProcessMessages;
begin
  WidgetSet.AppProcessMessages;
end;

class procedure TGtkApp.PopupEventHandler(
  AType: TGdkEventType; AEvent: PGdkEvent; var AHandled: Boolean);
var
  LWidget: PGtkWidget;
  LWidgetOfPopupWnd: PGtkWidget;
begin
  case AType of
    GDK_KEY_PRESS, GDK_KEY_RELEASE:
      if FInputTarget <> nil then
      begin
        gtk_widget_event(FInputTarget, AEvent);
        AHandled := True;
        Exit;
      end;
  end;

  case AType of
    GDK_BUTTON_RELEASE,
    GDK_BUTTON_PRESS,
    GDK_2BUTTON_PRESS,
    GDK_3BUTTON_PRESS,
    GDK_MOTION_NOTIFY,
    GDK_KEY_PRESS,
    GDK_KEY_RELEASE,
    GDK_SCROLL:
      begin
        AHandled := True;
        LWidget := gtk_get_event_widget(AEvent);
        LWidgetOfPopupWnd := TGtk3Widget(FPopupControl.Handle).Widget;
        if not IsChild(LWidget, LWidgetOfPopupWnd) then
          LWidget := TGtk3Widget(FPopupControl.Handle).GetContainerWidget;
        gtk_widget_event(LWidget, AEvent);
      end;
  end;
end;

class procedure TGtkApp.SetInputRedirection(AControl: TWinControl);
begin
  if FInputTargetWnd <> nil then
  begin
    FInputTarget := nil;
    FInputTargetWnd.RemoveFreeNotification(FFreeNotifier);
    FInputTargetWnd := nil;
  end;
  if AControl <> nil then
  begin
    FInputTargetWnd := AControl;
    FInputTargetWnd.FreeNotification(FFreeNotifier);
    FInputTarget := TGtk3Widget(AControl.Handle).GetContainerWidget;
  end;
  HandlerInit;
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
  Result^.show_all;
end;

procedure TACLGtk3CustomControl.InitializeWidget;
begin
  inherited InitializeWidget;
  SetBorderStyle(TWinControlAccess(LCLObject).BorderStyle);
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

procedure TACLGtk3CustomControl.SetBorderStyle(AValue: TBorderStyle);
begin
  PGtkLayout(Widget)^.set_border_width(IfThen(AValue <> bsNone, 2));
end;

{ TACLWSCustomControl }

class function TACLWSCustomControl.CreateHandle(
  const AControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
begin
  Result := TLCLHandle(TACLGtk3CustomControl.Create(AControl, AParams));
end;

class procedure TACLWSCustomControl.SetBorderStyle(
  const AWinControl: TWinControl; const ABorderStyle: TBorderStyle);
begin
  TACLGtk3CustomControl(AWinControl.Handle).SetBorderStyle(ABorderStyle);
end;

(*
{ TACLWSForm }

class function TACLWSForm.CreateHandle(
  const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  LParams: TCreateParams;
begin
  LParams := AParams;
  LParams.WndParent := ResolveWndParent(LParams);
  Result := inherited CreateHandle(AWinControl, LParams);
end;

class procedure TACLWSForm.ShowHide(const AWinControl: TWinControl);
begin
  if AWinControl.Parent <> nil then
    TGtk2WSWinControl.ShowHide(AWinControl)
  else
    inherited ShowHide(AWinControl);
end;

class function TACLWSForm.ResolveWndParent(const AParams: TCreateParams): HWND;
var
  LWndParent: PGtkWidget;
begin
  if AParams.Style and WS_CHILD = 0 then
  begin
    LWndParent := {%H-}PGtkWidget(AParams.WndParent);
    while (LWndParent <> nil) and not GTK_IS_WINDOW(LWndParent) do
      LWndParent := LWndParent^.parent;
    Result := HWND(LWndParent);
  end
  else
    Result := AParams.WndParent;
end;

{ TACLWSAdvancedForm }

class function TACLWSAdvancedForm.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  LAllocation: TGtkAllocation;
  LBox: PGtkWidget;
  LForm: TCustomForm absolute AWinControl;
  LWidgetInfo: PWidgetInfo;
  LWnd: PGtkWidget;
  LWndParent: HWND;
  LWndType: TGtkWindowType;
begin
  if (csDesigning in AWinControl.ComponentState) then
    Exit(inherited);
  if AParams.Style and WS_CHILD <> 0 then
    Exit(inherited);

  if AParams.ExStyle and WS_EX_NOACTIVATE <> 0 then
    LWndType := GTK_WINDOW_POPUP
  else if AParams.ExStyle and WS_EX_LAYERED <> 0 then
    LWndType := GTK_WINDOW_TOPLEVEL
  else
    LWndType := FormStyleMap[LForm.BorderStyle];

  LWnd := gtk_window_new(LWndType);
  // This is done with the expectation to avoid the button blinking for forms
  // that hide it, but currently it doesn't seem to make a difference.
  gtk_window_set_skip_taskbar_hint(PGtkWindow(LWnd), True);
  gtk_window_set_decorated(PGtkWindow(LWnd), False);
  gtk_widget_set_app_paintable(LWnd, True);
  gtk_window_set_resizable(PGtkWindow(LWnd), FormResizableMap[LForm.BorderStyle] <> 0);
  gtk_window_set_title(PGtkWindow(LWnd), AParams.Caption);

  LWndParent := TACLWSForm.ResolveWndParent(AParams);
  if LWndParent <> 0 then
    gtk_window_set_transient_for(PGtkWindow(LWnd), PGtkWindow(LWndParent))
  else
    if LForm.FormStyle in fsAllStayOnTop then
      gtk_window_set_keep_above(PGtkWindow(LWnd), true);

  case LForm.WindowState of
    wsMaximized:
      gtk_window_maximize(PGtkWindow(LWnd));
    wsMinimized:
      gtk_window_iconify(PGtkWindow(LWnd));
    wsFullscreen:
      gtk_window_fullscreen(PGtkWindow(LWnd));
  else;
  end;

  // the clipboard needs a widget
  if ClipboardWidget = nil then
    Gtk2WidgetSet.SetClipboardWidget(LWnd);

  {.$IFDEF HASX}
  if (LForm = Application.MainForm) and not Application.HasOption('disableaccurateframe') then
    Gtk2WidgetSet.CreateDummyWidgetFrame(-1, -1, -1, -1);
  {.$ENDIF}

  LWidgetInfo := CreateWidgetInfo(LWnd, LForm, AParams);
  LWidgetInfo^.FormBorderStyle := Ord(LForm.BorderStyle);
  FillChar(LWidgetInfo^.FormWindowState, SizeOf(LWidgetInfo^.FormWindowState), #0);
  LWidgetInfo^.FormWindowState.new_window_state := GDK_WINDOW_STATE_WITHDRAWN;
  LWidgetInfo^.UserData := Pointer(1);

  if AParams.ExStyle and WS_EX_LAYERED = 0 then
  begin
    LBox := CreateFormContents(LForm, LWnd, LWidgetInfo);
    gtk_container_add(PGtkContainer(LWnd), LBox);
    gtk_widget_show(LBox);
  end;

  LAllocation.X := AParams.X;
  LAllocation.Y := AParams.Y;
  LAllocation.Width := AParams.Width;
  LAllocation.Height := AParams.Height;
  gtk_widget_size_allocate(LWnd, @LAllocation);

  Set_RC_Name(LForm, LWnd);
  SetCallbacks(LWnd, LWidgetInfo);
  SetWindowCapabities(LForm, LWnd);

  if AParams.ExStyle and WS_EX_LAYERED <> 0 then
    TGtkControls.SetAlphaExposing(LWnd, LWidgetInfo);

  SetWindowCapabities(LForm, LWnd);
  Result := TLCLHandle({%H-}PtrUInt(LWnd));
end;

class function TACLWSAdvancedForm.DoRealize(Widget: PGtkWidget; Data: Pointer): GBoolean; cdecl;
begin
  // таким образом пытаемся добраться до метода RealizeAccelerator
  Result := gtkRealizeCB(Widget, Data);
  SetWindowCapabities(TCustomForm(Data), Widget);
end;

class procedure TACLWSAdvancedForm.SetCallbacks(
  const AWidget: PGtkWidget; const AWidgetInfo: PWidgetInfo);
var
  LFixed: PGtkWidget;
begin
  inherited SetCallbacks(AWidget, AWidgetInfo);

  if AWidgetInfo^.Style and WS_CHILD = 0 then
  begin
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
end;

class procedure TACLWSAdvancedForm.SetColor(const AWinControl: TWinControl);
var
  LWidgetInfo: PWidgetInfo;
begin
  LWidgetInfo := GetWidgetInfo(Pointer(AWinControl.Handle));
  if (LWidgetInfo = nil) or (LWidgetInfo^.ExStyle and WS_EX_LAYERED = 0) then
    inherited;
end;

class procedure TACLWSAdvancedForm.SetFormBorderStyle(
  const AForm: TCustomForm; const AFormBorderStyle: TFormBorderStyle);
var
  LWidget: PGtkWidget;
  LWidgetInfo: PWidgetInfo;
begin
  if AForm.Parent <> nil then Exit;
  LWidget := {%H-}PGtkWidget(AForm.Handle);
  LWidgetInfo := GetWidgetInfo(LWidget);
  if FormStyleMap[AFormBorderStyle] <> FormStyleMap[TFormBorderStyle(LWidgetInfo.FormBorderStyle)] then
    RecreateWnd(AForm)
  else
  begin
    SetWindowCapabities(AForm, LWidget);
    LWidgetInfo^.FormBorderStyle := Ord(AFormBorderStyle);
  end;
end;

class procedure TACLWSAdvancedForm.SetFormStyle(
  const AForm: TCustomform; const AFormStyle, AOldFormStyle: TFormStyle);
var
  LForm: TACLCustomForm;
begin
  if Safe.Cast(AForm, TACLCustomForm, LForm) then
    TACLStayOnTopHelper.Refresh(LForm)
  else
    inherited;
end;

class procedure TACLWSAdvancedForm.SetWindowCapabities(AForm: TCustomForm; AWidget: PGtkWidget);
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

class procedure TACLWSAdvancedForm.ShowHide(const AWinControl: TWinControl);
var
  LForm: TCustomForm absolute AWinControl;
  LWindow: PGtkWindow;
  LWidgetInfo: PWidgetInfo;
begin
  if AWinControl.Parent <> nil then
  begin
    TGtk2WSWinControl.ShowHide(AWinControl);
    Exit;
  end;

  LWindow := {%H-}PGtkWindow(LForm.Handle);
  LWidgetInfo := GetWidgetInfo(LWindow);
  if (fsModal in LForm.FormState) and LForm.HandleObjectShouldBeVisible then
  begin
    // только ради GDK_WINDOW_TYPE_HINT_DIALOG, чтобы модалка
    // ни при каких условиях не создавала собственную кнопку на таскбаре
    gtk_window_set_default_size(LWindow, Max(1, LForm.Width), Max(1, LForm.Height));
    gtk_widget_set_uposition(PGtkWidget(LWindow), LForm.Left, LForm.Top);
    gtk_window_set_type_hint(LWindow, GDK_WINDOW_TYPE_HINT_DIALOG);
    GtkWindowShowModal(LForm, LWindow);

    InvalidateLastWFPResult(LForm, LForm.BoundsRect);
  end
  else
  begin
    if LWidgetInfo^.ExStyle and WS_EX_NOACTIVATE <> 0 then
    begin
      if LForm.HandleObjectShouldBeVisible then
        gtk_window_set_type_hint(LWindow, GDK_WINDOW_TYPE_HINT_TOOLTIP);
    end;
    inherited;
    SetWindowCapabities(LForm, PGtkWidget(LWindow));
  end;
end;

{ TACLWSPopupControl }

class function TACLWSPopupControl.CreateHandle(
  const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  LAllocation: TGtkAllocation;
  LClientAreaWidget: PGtkWidget;
  LWidget: PGtkWidget;
  LWidgetInfo: PWidgetInfo;
begin
  if (AParams.Style and WS_POPUP) = 0 then
    Exit(inherited);

  // В этом случае у нас вместо контрола будет урезанная попап-форма
  if MustBeFocusable(AWinControl) then
    LWidget := gtk_window_new(GTK_WINDOW_TOPLEVEL)
  else
    LWidget := gtk_window_new(GTK_WINDOW_POPUP);

  gtk_widget_set_app_paintable(LWidget, True);
  gtk_window_set_decorated(PGtkWindow(LWidget), False);
  gtk_window_set_skip_taskbar_hint(PGtkWindow(LWidget), True);
  if AParams.WndParent <> 0 then
  begin
    gtk_window_set_transient_for(PGtkWindow(LWidget),
      GTK_WINDOW(gtk_widget_get_toplevel({%H-}PGtkWidget(AParams.WndParent))));
  end
  else
    gtk_window_set_keep_above(PGtkWindow(LWidget), true); // stay-on-top

  LWidgetInfo := CreateWidgetInfo(LWidget, AWinControl, AParams);
  FillChar(LWidgetInfo^.FormWindowState, SizeOf(LWidgetInfo^.FormWindowState), #0);
  LWidgetInfo^.FormWindowState.new_window_state := GDK_WINDOW_STATE_WITHDRAWN;

  // Размеры
  LAllocation.X := AParams.X;
  LAllocation.Y := AParams.Y;
  LAllocation.Width := AParams.Width;
  LAllocation.Height := AParams.Height;
  gtk_widget_size_allocate(LWidget, @LAllocation);

  Set_RC_Name(AWinControl, LWidget);
  SetCallbacks(PGtkObject(LWidget), AWinControl);

  // Если у попап-контрола есть дочерние элементы - мы должны создать подложку,
  // на которой они будут лежать (по аналогии с тем, как делается для формы -
  // см. CreateFormContents), в противном случае LCL не найдет куда их положить
  // и контролы не будут видны на экране.
  if AWinControl.ControlCount > 0 then
  begin
    LClientAreaWidget := gtk_layout_new(nil, nil);
    gtk_container_add(PGtkContainer(LWidget), LClientAreaWidget);
    gtk_widget_show(LClientAreaWidget);
    SetFixedWidget(LWidget, LClientAreaWidget);
    SetMainWidget(LWidget, LClientAreaWidget);
  end
  else
    LWidgetInfo^.ClientWidget := LWidget; // для Paint и MouseCapture, после setCallbacks

  // После того, как мы актуализировали ClientWidget - ставим обработчик сигнала на LM_PAINT
  if AParams.ExStyle and WS_EX_LAYERED <> 0 then
    TGtkControls.SetAlphaExposing(LWidget, LWidgetInfo)
  else
    WidgetSet.SetCallback(LM_PAINT, PGtkObject(LWidget), AWinControl);

  // Финалочка
  Result := TLCLHandle({%H-}PtrUInt(LWidget));
end;

class procedure TACLWSPopupControl.SetColor(const AWinControl: TWinControl);
var
  LWidgetInfo: PWidgetInfo;
begin
  LWidgetInfo := GetWidgetInfo(Pointer(AWinControl.Handle));
  if (LWidgetInfo = nil) or (LWidgetInfo^.ExStyle and WS_EX_LAYERED = 0) then
    inherited SetColor(AWinControl);
end;

class function TACLWSPopupControl.MustBeFocusable(AControl: TWinControl): Boolean;
begin
  Result := False;
end;

class procedure TACLWSPopupControl.SetBounds(
  const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer);
var
  LWindow: PGtkWindow;
begin
  LWindow := {%H-}PGtkWindow(AWinControl.Handle);
  if GTK_IS_WINDOW(LWindow) then
  begin
    gtk_window_move(LWindow, ALeft, ATop);
    gtk_window_resize(LWindow, AWidth, AHeight);
  end
  else
    inherited SetBounds(AWinControl, ALeft, ATop, AWidth, AHeight);
end;
    *)

{ TACLWSScrollingControl }

class procedure TACLWSScrollingControl.DispatchNonClientMessage(
  AControl: TWinControl; var AMessage: TMessage);
begin
  // do nothing
end;

end.
