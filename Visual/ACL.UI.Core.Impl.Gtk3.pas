////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Gtk3 Adapters and Helpers
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Core.Impl.Gtk3;

{$I ACL.Config.inc}

{$SCOPEDENUMS ON}

{.$DEFINE DEBUG_MESSAGELOOP}
{$MESSAGE WARN 'Gtk3: проблемы с кэпчей - неправильные координаты'}
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
    class var FPopupCapturedDevice: PGdkDevice;
    class var FPopupControl: TWinControl;
    class var FPopupError: string;

    class procedure Handler(event: PGdkEvent; data: gpointer); cdecl; static;
    class procedure HandlerException(Sender: TObject; Error: Exception);
    class procedure HandlerInit;
    class procedure HandlerOnDestroy(data: gpointer); cdecl; static;
    class procedure HandlerRemoving(Sender: TComponent);
    class procedure PopupEventHandler(AType: TGdkEventType; AEvent: PGdkEvent; var AHandled: Boolean);
    class procedure TranslateCoords(ATarget: PGtkWidget; AEvent: PGdkEvent);
  public
    class constructor Create;
    class destructor Destroy;
    class procedure Hook(ACallback: TGtkEventCallback);
    class procedure Unhook; overload;
    class procedure Unhook(ACallback: TGtkEventCallback); overload;

    class procedure BeginPopup(APopupControl: TWinControl); overload;
    class procedure BeginPopup(APopupControl: TWinControl; ACallback: TGtkEventCallback); overload;
    class procedure EndPopup(AControl: TWinControl);
    class function IsLooseFocusEvent(AEvent: PGdkEvent): Boolean;
    class function IsPopupAborted: Boolean;

    class procedure ProcessMessages;
    class procedure SetInputRedirection(AControl: TWinControl);
  end;

  { TACLWSForm }

  TACLWSForm = class(TGtk3WSCustomForm)
  strict private
    class procedure BlockTransientWindow(AWindow: PGtkWindow; AState: Boolean);
  protected
    class procedure CheckAndFixGeometry(ACtrl: TWinControl);
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class procedure SetAlphaBlend(const ACustomForm: TCustomForm;
      const AlphaBlend: Boolean; const Alpha: Byte); override;
    class procedure SetFormStyle(const AForm: TCustomform;
      const AFormStyle, AOldFormStyle: TFormStyle); override;
    class procedure SetIcon(const AForm: TCustomForm; const Small, Big: HICON); override;
    class procedure SetRealPopupParent(const AForm, APopupParent: TCustomForm); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
  end;

  { TACLWSAdvancedForm }

  TACLWSAdvancedForm = class(TACLWSForm);

  { TACLWSHintWindow }

  TACLWSHintWindow = class(TACLWSAdvancedForm)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class procedure SetRealPopupParent(
      const AForm, APopupParent: TCustomForm); override;
  end;

  { TACLWSCustomControl }

  TACLWSCustomControl = class(TGtk3WSWinControl)
  published
    class function CreateHandle(
      const AControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class function GetText(
      const AWinControl: TWinControl; var AText: String): Boolean; override;
    class procedure SetBorderStyle(const AWinControl: TWinControl;
      const ABorderStyle: TBorderStyle); override;
    class procedure SetOpacity(const AWinControl: TWinControl; AOpacity: Byte);
  end;

  { TACLWSPopupControl }

  TACLWSPopupControl = class(TACLWSCustomControl)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
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
  ACL.UI.Controls.Base,
  ACL.UI.Core.Impl.Gtk3.Widgets,
  ACL.UI.Forms.Base;

type
  TFormAccess = class(TForm);
  TGtk3WidgetAccess = class(TGtk3Widget);
  TGtk3WidgetSetAccess = class(TGtk3WidgetSet);

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
        HTSYSMENU:
          gdk_window_show_window_menu(TGtk3Widget(AForm.Handle).GetWindow, gtk_get_current_event);
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
  //LXPos, LYPos: gint;
  LPoint: TPoint;
  LWindow: PGtkWindow;
begin
  LDragThreshold := dpiApply(Mouse.DragThreshold, acGetCurrentDpi(AForm));
  if AImmediately or TACLStartDragHelper.Check(AForm, ALocalX, ALocalY, LDragThreshold) then
  begin
    TFormAccess(AForm).MouseCapture := False;
    LWindow := PGtkWindow(TGtk3Widget(AForm.Handle).Widget);
    LPoint := AForm.ClientToScreen(Point(ALocalX, ALocalY));
    case AHitCode of
      HTLEFT..HTBOTTOMRIGHT:
        LWindow^.begin_resize_drag(BorderMap[AHitCode], 1, LPoint.X, LPoint.Y, GDK_CURRENT_TIME);
    else
      begin
        //LXPos := 0; LYPos := 0;
        //LWindow^.window^.get_origin(@LXPos, @LYPos);
        //LWindow^.window^.move(LXPos, LYPos);
        LWindow^.window^.begin_move_drag(1, LPoint.X, LPoint.Y, GDK_CURRENT_TIME);
      end;
    end;
  end;
end;

function LoadDialogIcon(AOwnerWnd: TWndHandle; AType: TMsgDlgType; ASize: Integer): TACLDib;
const
  Map: array[TMsgDlgType] of PChar = (
    'gtk-dialog-warning', 'gtk-dialog-error', 'gtk-dialog-info', 'gtk-dialog-question', ''
  );
begin
  Result := GtkLoadStockIcon(nil, Map[AType], ASize);
end;

procedure ReleaseInputGrab;
var
  LDisplay: PGdkDisplay;
  LSeat: PGdkSeat;
begin
  LDisplay := gdk_display_get_default();
  if LDisplay <> nil then
  begin
    LSeat := gdk_display_get_default_seat(LDisplay);
    if LSeat <> nil then
    begin
      ReleaseCapture;
      gdk_seat_ungrab(LSeat);
    end;
  end;
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
      GDK_2BUTTON_PRESS,
      GDK_3BUTTON_PRESS,
      GDK_BUTTON_RELEASE,
      GDK_TOUCH_END:
        FDragState := TDragState.Canceled;
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
const
  GdkHookFlags = [GDK_POINTER_MOTION_MASK,
    GDK_BUTTON_PRESS_MASK, GDK_BUTTON_RELEASE_MASK,
    GDK_ENTER_NOTIFY_MASK, GDK_LEAVE_NOTIFY_MASK];
var
{$IFNDEF DEBUG_MESSAGELOOP}
  //LAttrs: TGdkWindowAttr;
  LGrabResult: TGdkGrabStatus;
{$ENDIF}
  LDevice: PGdkDevice;
  LWidget: PGtkWidget;
  LWindow: PGdkWindow;
begin
  if FPopupCapturedDevice <> nil then
    raise EInvalidOperation.Create('Gtk3: recursive popups are not supported');

{$IFDEF DEBUG_MESSAGELOOP}
  LDevice := nil;
  LWidget := nil;
  LWindow := nil;
{$ELSE}
  // AI: ref.to: gtkmenu.c, menu_grab_transfer_window_get
  //FillChar(LAttrs{%H-}, SizeOf(LAttrs), 0);
  //LAttrs.x := -100;
  //LAttrs.y := -100;
  //LAttrs.width := 10;
  //LAttrs.height := 10;
  //LAttrs.override_redirect := True;
  //LAttrs.window_type := GDK_WINDOW_TEMP;
  //LAttrs.wclass := GDK_INPUT_ONLY;

  LWidget := TGtk3Widget(APopupControl.Handle).Widget;
  // в таком ключе контекстные меню в скин-движке не реагируют на мышь
  //LWindow := gdk_screen_get_root_window(gtk_widget_get_screen(LWidget));
  //LWindow := gdk_window_new(LWindow, @LAttrs, [GDK_WA_X, GDK_WA_Y, GDK_WA_NOREDIR]);
  //gtk_widget_register_window(LWidget, LWindow);
  //gdk_window_show(LWindow);
  LWindow := LWidget^.window;

  // AI: ref.to: gtkmenu.c, gtk_menu_popup_internal
  LDevice := gtk_get_current_event_device;
  if LDevice = nil then
    LDevice := gdk_seat_get_pointer(gdk_display_get_default_seat(gtk_widget_get_display(LWidget)));
  if gdk_device_get_source(LDevice) = GDK_SOURCE_KEYBOARD then
    LDevice := gdk_device_get_associated_device(LDevice);

  // AI: ref.to: gtkmenu.c, popup_grab_on_window
  LGrabResult := gdk_seat_grab(gdk_device_get_seat(LDevice), LWindow,
    //#AI:
    // В FlyWM (Astra Linux) при захвате клавиатурного хука, top-level форма
    // в режиме StayOnTop проваливается на задний план.
    //
    // Поверхостный тест показал, что в принципе-то граббинг клавиатуры нам
    // и не нужен - мы перехватываем нужные события через SetInputRedirection
    GDK_SEAT_CAPABILITY_ALL_POINTING, True, nil, nil, nil, nil);
  if LGrabResult <> GDK_GRAB_SUCCESS then
  begin
    //gtk_widget_unregister_window(LWidget, LWindow);
    //gdk_window_destroy(LWindow);
    raise EInvalidOperation.CreateFmt('GTK3.Popup: unable to grap the pointer (%d)', [Ord(LGrabResult)]);
  end;
{$ENDIF}

  // если мы тут - все прошло ОК, инициализируем приёмник сообщений и перехватчик
  FPopupError := '';
  FPopupControl := APopupControl;
  FPopupCapturedDevice := LDevice;
  //FPopupWidget := LWidget;
  //FPopupWindow := LWindow;
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

  try
    if FPopupCapturedDevice <> nil then
      gdk_seat_ungrab(gdk_device_get_seat(FPopupCapturedDevice));
    //if FPopupWindow <> nil then
    //begin
    //  gtk_widget_unregister_window(FPopupWidget, FPopupWindow);
    //  gdk_window_destroy(FPopupWindow);
    //end;
  finally
    FPopupCapturedDevice := nil;
    //FPopupWidget := nil;
    //FPopupWindow := nil;
  end;

  if FPopupError <> '' then
    raise Exception.Create(FPopupError);
end;

class function TGtkApp.IsLooseFocusEvent(AEvent: PGdkEvent): Boolean;
var
  LWidget: PGtkWidget;
begin
  Result := False;
  if AEvent^.type_ = GDK_WINDOW_STATE then
  begin
    LWidget := gtk_get_event_widget(AEvent);
    if (LWidget <> nil) and (LWidget^.window <> nil) then
    begin
      if not (GDK_WINDOW_STATE_FOCUSED in LWidget^.window^.get_state) then
        Result := True;
    end;
  end;
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
        TranslateCoords(FInputTarget, event);
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
        begin
          LWidget := TGtk3Widget(FPopupControl.Handle).GetContainerWidget;
          TranslateCoords(LWidget, AEvent);
        end;
        gtk_widget_event(LWidget, AEvent);
      end;
    GDK_WINDOW_STATE:
      if IsLooseFocusEvent(AEvent) then
      begin
        if Screen.ActiveCustomForm <> FPopupControl then
          FPopupControl.Perform(CM_CANCELMODE, 0, 0);
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

class procedure TGtkApp.TranslateCoords(ATarget: PGtkWidget; AEvent: PGdkEvent);
var
  x1, y1, x2, y2: gint;
begin
  case AEvent.type_ of
    GDK_BUTTON_PRESS,
    GDK_BUTTON_RELEASE,
    GDK_MOTION_NOTIFY:
      begin
        if AEvent^.any.window <> ATarget^.window then // because of input-redirection
        begin
          x1 := 0; y1 := 0; x2 := 0; y2 := 0;
          ATarget^.window^.get_origin(@x1, @y1);
          AEvent^.any.window.get_origin(@x2, @y2);
          AEvent^.motion.x := AEvent^.motion.x + x2 - x1;
          AEvent^.motion.y := AEvent^.motion.y + y2 - y1;
          AEvent^.motion.x_root := AEvent^.motion.x_root + x2 - x1;
          AEvent^.motion.y_root := AEvent^.motion.y_root + y2 - y1;
          g_object_unref(AEvent^.any.window);
          AEvent^.any.window := ATarget^.window;
          g_object_ref(AEvent^.any.window);
        end;
        // mark motion data as untrusted, ref.to. TGtk3Widget.GtkEventMouseMove
        if AEvent.type_ = GDK_MOTION_NOTIFY then
          AEvent^.motion.is_hint := 1;
      end;
  end;
end;

{ TACLWSHintWindow }

class function TACLWSHintWindow.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
begin
  Result := TLCLHandle(TGtk3HintWindow.Create(AWinControl, AParams));
end;

class procedure TACLWSHintWindow.SetRealPopupParent(
  const AForm, APopupParent: TCustomForm);
begin
  // to prevent incorrect drag-image & hint positioning if popup-parent is set
end;

{ TACLWSCustomControl }

class function TACLWSCustomControl.CreateHandle(
  const AControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
begin
  Result := TLCLHandle(TACLGtk3CustomControl.Create(AControl, AParams));
end;

class function TACLWSCustomControl.GetText(
  const AWinControl: TWinControl; var AText: String): Boolean;
begin
  Result := False; // кастомные контролы не хранят текст на уровне Widget
end;

class procedure TACLWSCustomControl.SetBorderStyle(
  const AWinControl: TWinControl; const ABorderStyle: TBorderStyle);
begin
  TACLGtk3CustomControl(AWinControl.Handle).SetBorderStyle(ABorderStyle);
end;

class procedure TACLWSCustomControl.SetOpacity(
  const AWinControl: TWinControl; AOpacity: Byte);
var
  LWidget: PGtkWidget;
begin
  if AWinControl.HandleAllocated then
  begin
    LWidget := TGtk3Widget(AWinControl.Handle).Widget;
    if Gtk3IsGtkWindow(LWidget) and (LWidget^.window <> nil) then
      LWidget^.window^.set_opacity(AOpacity / 255)
    else
      LWidget^.set_opacity(AOpacity / 255);
  end;
end;

{ TACLWSPopupControl }

class function TACLWSPopupControl.CreateHandle(
  const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
begin
  if (AParams.Style and WS_POPUP) = 0 then
    Exit(inherited);
  Result := TLCLHandle(TACLGtk3PopupControl.Create(AWinControl, AParams));
end;

class procedure TACLWSPopupControl.ShowHide(const AWinControl: TWinControl);
var
  LWidget: TGtk3Widget;
  LWindow: PGtkWindow;
begin
  LWidget := TGtk3Widget(AWinControl.Handle);
  if (wtWindow in LWidget.WidgetType) and AWinControl.HandleObjectShouldBeVisible then
  begin
    ReleaseInputGrab;
    LWindow := PGtkWindow(LWidget.Widget);
    LWindow^.realize;
    // без вот этого вызова у нас будет флик фона на экран
    TACLWSForm.CheckAndFixGeometry(AWinControl);
    LWindow^.show_all;
    LWindow^.window^.set_events(GDK_ALL_EVENTS_MASK);
    LWindow^.present;
  end
  else
    inherited ShowHide(AWinControl);
end;

{ TACLWSForm }

function ModalFilter(xevent: PGdkXEvent; event: PGdkEvent; data: gpointer): TGdkFilterReturn; cdecl;
begin
  Result := GDK_FILTER_REMOVE;
end;

class procedure TACLWSForm.BlockTransientWindow(AWindow: PGtkWindow; AState: Boolean);
var
  LTransient: PGtkWindow;
begin
  LTransient := AWindow^.transient_for;
  if (LTransient <> nil) and Gtk3IsGdkWindow(LTransient^.window) then
  begin
    if AState then
      gdk_window_add_filter(LTransient^.window, TGdkFilterFunc(@ModalFilter), AWindow)
    else
      gdk_window_remove_filter(LTransient^.window, TGdkFilterFunc(@ModalFilter), AWindow);
  end;
end;

class procedure TACLWSForm.CheckAndFixGeometry(ACtrl: TWinControl);
const
  WaitDelay: gulong = 4000;
  WaitLoops: integer = 4;
var
  I: integer;
  LWnd: PGdkWindow;
begin
  LWnd := TGtk3Widget(ACtrl.Handle).Widget^.window;
  LWnd^.move_resize(ACtrl.Left, ACtrl.Top, ACtrl.Width, ACtrl.Height);
  LWnd^.process_updates(True);

  //Give a little breath to WM.
  for I := 0 to WaitLoops - 1 do
  begin
    g_usleep(WaitDelay);
    // оригинал:
    //g_main_context_iteration(nil, false);

    // Arch Linux (Manjaro 26) на KDE.
    // При форсированом использовании X11 бэка посредством XWayland,
    // окна не показываются на экране при запуске приложения без следующего трюка.
    // Этот метод вызывается в нескольких местах - не просто так. Не убирать!
    while g_main_context_pending(nil) do
      g_main_context_iteration(nil, false);
    // Схожая проблема наблюдалась в Alt.Linux 11 на Gnome (тоже на XWayland), но
    // там это решение не сработало - см. TACLGtk3AdvancedWindow.SetBounds
  end;
end;

class function TACLWSForm.CreateHandle(
  const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  LAllocation: TGtkAllocation;
  LWindow: TGtk3Window;
begin
  if (csDesigning in AWinControl.ComponentState) then
    Exit(inherited);
  if (AParams.Style and WS_CHILD) <> 0 then
    Exit(TACLWSCustomControl.CreateHandle(AWinControl, AParams));

  LAllocation.x := AWinControl.Left;
  LAllocation.y := AWinControl.Top;
  LAllocation.width := AWinControl.Width;
  LAllocation.height := AWinControl.Height;

  LWindow := TACLGtk3AdvancedWindow.Create(AWinControl, AParams);
  LWindow.Widget^.set_allocation(@LAllocation);
  if Gtk3IsGtkWindow(LWindow.Widget) then
    Gtk3WidgetSet.AddWindow(PGtkWindow(LWindow.Widget));

  Result := TLCLHandle(LWindow);
end;

class procedure TACLWSForm.SetAlphaBlend(
  const ACustomForm: TCustomForm; const AlphaBlend: Boolean; const Alpha: Byte);
begin
  TACLWSCustomControl.SetOpacity(ACustomForm, IfThen(AlphaBlend, Alpha, 255));
end;

class procedure TACLWSForm.SetFormStyle(
  const AForm: TCustomform; const AFormStyle, AOldFormStyle: TFormStyle);
var
  LForm: TACLCustomForm;
begin
  if Safe.Cast(AForm, TACLCustomForm, LForm) then
    TACLStayOnTopHelper.Refresh(LForm)
  else
    inherited;
end;

class procedure TACLWSForm.SetIcon(
  const AForm: TCustomForm; const Small, Big: HICON);
begin
  if AForm.Parent = nil then
    inherited SetIcon(AForm, Small, Big);
end;

class procedure TACLWSForm.SetRealPopupParent(const AForm, APopupParent: TCustomForm);
begin
  if AForm.Parent = nil then
    inherited SetRealPopupParent(AForm, GetParentForm(APopupParent));
end;

class procedure TACLWSForm.ShowHide(const AWinControl: TWinControl);
var
  LForm: TCustomForm absolute AWinControl;
  LWidget: TGtk3WidgetAccess;
  LWindow: PGtkWindow;
begin
  if not WSCheckHandleAllocated(AWinControl, 'ShowHide') then
    Exit;

  if LForm.Parent <> nil then
  begin
    TACLWSCustomControl.ShowHide(LForm);
    Exit;
  end;

  LWidget := TGtk3WidgetAccess(LForm.Handle);
  if not (wtWindow in LWidget.WidgetType) then
  begin
    inherited;
    Exit;
  end;

  LWindow := PGtkWindow(LWidget.Widget);
  // LCL: use this if pure SetCapture(0) does not work under wayland (commented)
  // AIMP: DblClick -> ShowModal -> Modal form does not react on mouse
  if LWidget.FParams.ExStyle and WS_EX_NOACTIVATE = 0 then // hint, drag-image, etc
    ReleaseInputGrab;

  if LForm.HandleObjectShouldBeVisible then
  begin
    if LForm = Application.MainForm then
      LogEntry(acGeneralLogFileName, 'Main', 'WindowShow');

    if LForm.FormStyle in fsAllStayOnTop then
      LWindow^.set_keep_above(True);
    if fsModal in LForm.FormState then
    begin
      LWindow^.set_modal(True);
      LWindow^.window^.set_modal_hint(true);
      SetRealPopupParent(LForm, Screen.ActiveCustomForm);
    end;
    LWindow^.realize;

    if LForm.BorderStyle = bsNone then
    begin
      if LWindow^.transient_for = nil then
      begin
        if LForm.PopupParent <> nil then
          SetRealPopupParent(LForm, LForm.PopupParent)
        else
          SetRealPopupParent(LForm, Screen.ActiveCustomForm);
      end;
      if LWidget.Shape <> nil then
      begin
        TACLGtk3AdvancedWindow.SetAlphaExposing(LWidget.Widget);
        LWidget.SetWindowShape(LWidget.Shape, LWindow^.window);
      end;
    end;

    if not GTK3WidgetSet.IsWayland then
      CheckAndFixGeometry(LForm); // !!! Manjaro26 (X11)

    LWidget.BeginUpdate;
    try
      LWidget.Visible := True;
      if (fsModal in LForm.FormState) and (Application.ModalLevel > 0) then
        BlockTransientWindow(LWindow, True);
      SetAlphaBlend(LForm, LForm.AlphaBlend, LForm.AlphaBlendValue);
      CheckAndFixGeometry(LForm); //See issue #41412
      LWindow^.show_all;
      LWindow^.window^.set_events(GDK_ALL_EVENTS_MASK);
      LWindow^.present;
    finally
      LWidget.EndUpdate;
    end;
  end
  else // Hide
  begin
    LWidget.Visible := False;
    if LForm = Application.MainForm then
      LogEntry(acGeneralLogFileName, 'Main', 'WindowHide');
    if (fsModal in LForm.FormState) then
      BlockTransientWindow(LWindow, False);
    if (fsModal in LForm.FormState) or (LForm.BorderStyle = bsNone) then
      LWindow^.set_transient_for(nil);
  end;
end;

{ TACLWSScrollingControl }

class procedure TACLWSScrollingControl.DispatchNonClientMessage(
  AControl: TWinControl; var AMessage: TMessage);
begin
  // do nothing
end;

end.
