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

{.$DEFINE DEBUG_MESSAGELOOP}
{$MESSAGE WARN 'Проверить:'}
// 1) В FlyWM (Astra Linux) при захвате клавиатурного хука, top-level форма в режиме StayOnTop проваливается на задний план.
// 2) отключать прозрачность, если мышь за пределами окна - не работает, ибо мы не можем получить координаты мыши
// 2) отключать прозрачность, если окно неактивно - не работает
// 3) ui insight не работает
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
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Logger,
  // VCL
  Graphics,
  Controls,
  Forms;

type

  { IACLLayeredPaint }

  IACLLayeredPaint = interface
  ['{3FE006F2-67DE-4317-B402-D872A77373E4}']
    procedure PaintTo(ACairo: Cairo.Pcairo_t);
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
    class procedure CheckAndFixGeometry(AWinControl: TWinControl);
    class function ResolveWndParent(const AParams: TCreateParams): HWND;
    class procedure SetAlphaExposing(AWidget: PGtkWidget);
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
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.UI.Controls.Base,
  ACL.UI.Forms.Base;

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

type
  TFormAccess = class(TForm);
  TWinControlAccess = class(TWinControl);
  TGtk3WidgetAccess = class(TGtk3Widget);
  TGtk3WidgetSetAccess = class(TGtk3WidgetSet);

  { TACLGtk3CustomControl }

  // based on TGtk3Panel
  TACLGtk3CustomControl = class(TGtk3Bin)
  strict private
    class procedure DoSizeAllocate(AWidget: PGtkLayout;
      AGdkRect: PGdkRectangle; AGtk3Widget: TGtk3Widget); cdecl; static;
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
    procedure SetBorderStyle(AValue: TBorderStyle);
  public
    function ClientToScreen(var P: TPoint): boolean; override;
    function DeliverMessage(var Msg; const AIsInputEvent: Boolean=False): LRESULT; override;
    procedure InitializeWidget; override;
  end;

  { TACLGtk3AdvancedWindow }

  TACLGtk3AdvancedWindow = class(TGtk3Window)
  strict private
    FCreatingWorkaround: TProc;
  public
    function ClientToScreen(var P: TPoint): boolean; override;
    function CreateWidget(const Params: TCreateParams): PGtkWidget; override;
    function GtkEventPaint(Sender: PGtkWidget; AContext: Pcairo_t): Boolean; override;
    procedure OffsetMousePos(const aGlobalX, aGlobalY: double; APoint: PPoint); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: integer); override;
    procedure SetText(const AValue: String); override;
    procedure SetVisible(AValue: Boolean); override;
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
  end;
end;

{ TACLWSHintWindow }

class function TACLWSHintWindow.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
begin
  Result := TLCLHandle(TGtk3HintWindow.Create(AWinControl, AParams));
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
  if IsWidgetOk and (Widget^.window <> nil) then
    Result := inherited ClientToScreen(P)
  else
    Result := False;
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
var
  X, Y: Integer;
begin
  if IsWidgetOk and Gtk3IsGdkWindow(Widget^.window) and
   (FParams.ExStyle and WS_EX_LAYERED <> 0) then
  begin
    X := 0; Y := 0;
    Widget^.window^.get_origin(@X, @Y);
    Inc(P.X, X);
    Inc(P.Y, Y);
    Exit(True);
  end;
  Result := inherited;
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
        LWndParent: HWND;
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
          TACLWSForm.SetAlphaExposing(FWidget);
        if Params.ExStyle and WS_EX_NOACTIVATE <> 0 then
        begin
          Exclude(FWidgetType, wtHintWindow);
          LWindow^.set_type_hint(GDK_WINDOW_TYPE_HINT_UTILITY);
        end;

        if LCLObject.Parent = nil then
        begin
          LWndParent := TACLWSForm.ResolveWndParent(Params);
          if LWndParent <> 0 then
            LWindow^.set_transient_for(PGtkWindow(TGtk3Widget(LWndParent).Widget))
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
  LPainter: IACLLayeredPaint;
begin
  Result := True;
  if Supports(LCLObject, IACLLayeredPaint, LPainter) then
    LPainter.PaintTo(Cairo.Pcairo_t(AContext))
  else
    Result := inherited;
end;

procedure TACLGtk3AdvancedWindow.OffsetMousePos(
  const aGlobalX, aGlobalY: double; APoint: PPoint);
begin
  with getClientOffset do
  begin
    dec(APoint^.x, x);
    dec(APoint^.y, y);
  end;
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

  LForm := TCustomForm(LCLObject);
  LFormSizeIsFixed := not WidgetMapped or
    (LForm.BorderStyle in [bsDialog, bsSingle, bsToolWindow]);

  LRect.x := ALeft;
  LRect.y := ATop;
  LRect.width := AWidth;
  LRect.Height := AHeight;
  LWindow^.size_allocate(@LRect);

  FillChar(LGeometry, SizeOf(LGeometry), 0);
  LGeometry.max_aspect := 1;
  LGeometry.height_inc := 1;
  LGeometry.width_inc := 1;
  LGeometry.base_width := LForm.Width;
  LGeometry.base_height := LForm.Height;
  LGeometry.win_gravity := LWindow^.get_gravity;
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
    LWindow^.window^.move_resize(ALeft, ATop, AWidth, AHeight);
    LWindow^.window^.process_updates(true);
  end;
end;

procedure TACLGtk3AdvancedWindow.SetText(const AValue: String);
begin
  // Эта хрень дергается между созданием Window и Layout. Cм.CreateHandle.
  if Assigned(FCreatingWorkaround) then FCreatingWorkaround();
  inherited SetText(AValue);
end;

procedure TACLGtk3AdvancedWindow.SetVisible(AValue: Boolean);
var
  LWasMapped: Boolean;
begin
  LWasMapped := WidgetMapped;
  inherited SetVisible(AValue);
  if not LWasMapped then // см. TACLGtk3AdvancedWindow.SetBounds
    SetBounds(LCLObject.Left, LCLObject.Top, LCLObject.Width, LCLObject.Height);
end;

{ TACLGtk3PopupControl }

function TACLGtk3PopupControl.ClientToScreen(var P: TPoint): Boolean;
var
  x, y: gint;
begin
  Widget^.window^.get_origin(@x, @y);
  Inc(P.X, X);
  Inc(P.Y, Y);
  Result := True;
end;

function TACLGtk3PopupControl.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  LWindow: PGtkWindow;
  LWndParent: HWND;
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

  LWndParent := TACLWSForm.ResolveWndParent(Params);
  if LWndParent <> 0 then
    LWindow^.set_transient_for(PGtkWindow(TGtk3Widget(LWndParent).Widget));
  if Params.ExStyle and WS_EX_LAYERED <> 0 then
    TACLWSAdvancedForm.SetAlphaExposing(FWidget);
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
  LPainter: IACLLayeredPaint;
begin
  Result := True;
  if Supports(LCLObject, IACLLayeredPaint, LPainter) then
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
  if wtWindow in LWidget.WidgetType then
  begin
    ReleaseInputGrab;
    LWindow := PGtkWindow(LWidget.Widget);
    LWindow^.realize;
    // без вот этого вызова у нас будет флик фона на экран
    TACLWSAdvancedForm.CheckAndFixGeometry(AWinControl);
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

class procedure TACLWSForm.CheckAndFixGeometry(AWinControl: TWinControl);
const
  WaitDelay: gulong = 4000;
  WaitLoops: integer = 4;
var
  LWnd: PGdkWindow;
  I: integer;
begin
  LWnd := TGtk3Widget(AWinControl.Handle).Widget^.window;
  LWnd^.move_resize(AWinControl.Left, AWinControl.Top, AWinControl.Width, AWinControl.Height);
  LWnd^.process_updates(True);

  //Give a little breath to WM.
  for I := 0 to WaitLoops - 1 do
  begin
    g_usleep(WaitDelay);
    g_main_context_iteration(nil, false);
  end;

  //Note that here may be still wrong geometry under x11,
  //but LCL should be happy at this point.
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

class function TACLWSForm.ResolveWndParent(const AParams: TCreateParams): HWND;
var
  LWndParent: TGtk3Widget;
begin
  if AParams.Style and WS_CHILD <> 0 then
    Exit(AParams.WndParent);

  LWndParent := TGtk3Widget(AParams.WndParent);
  while (LWndParent <> nil) and not Gtk3IsGtkWindow(LWndParent.Widget) do
    LWndParent := LWndParent.getParent;
  Result := HWND(LWndParent);
end;

class procedure TACLWSForm.SetAlphaExposing(AWidget: PGtkWidget);
var
  LScreen: PGdkScreen;
  LVisual: PGdkVisual;
begin
  LScreen := AWidget^.get_screen;
  if LScreen <> nil then
  begin
    LVisual := LScreen^.get_rgba_visual;
    if LVisual = nil then
    begin
      LogEntry(acGeneralLogFileName, 'Gtk3', 'Alpha-composing is unavailable');
      Exit;
    end;
    AWidget^.set_visual(LVisual);
  end;
end;

class procedure TACLWSForm.SetAlphaBlend(
  const ACustomForm: TCustomForm; const AlphaBlend: Boolean; const Alpha: Byte);
var
  LWindow: PGdkWindow;
begin
  if ACustomForm.HandleAllocated then
  begin
    LWindow := TGtk3Widget(ACustomForm.Handle).GetWindow;
    if LWindow <> nil then
      LWindow^.set_opacity(IfThen(AlphaBlend, Alpha / 255, 1.0));
  end;
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
    inherited SetRealPopupParent(AForm, APopupParent);
end;

class procedure TACLWSForm.ShowHide(const AWinControl: TWinControl);
var
  LForm: TCustomForm absolute AWinControl;
  LVisible: Boolean;
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
  if {(csDesigning in LForm.compo) or }not (wtWindow in LWidget.WidgetType) then
  begin
    inherited;
    Exit;
  end;

  if Gtk3IsGtkWindow(LWidget.Widget) then
    LWindow := PGtkWindow(LWidget.Widget)
  else
    LWindow := nil;

  LVisible := LForm.HandleObjectShouldBeVisible;

  // LCL: use this if pure SetCapture(0) does not work under wayland (commented)
  // AIMP: DblClick -> ShowModal -> Modal form does not react on mouse
  if LWidget.FParams.ExStyle and WS_EX_NOACTIVATE = 0 then // hint, drag-image, etc
    ReleaseInputGrab;

  if LVisible then
  begin
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
        LWindow^.set_app_paintable(True);
        LWindow^.set_visual(TGdkScreen.get_default^.get_rgba_visual);
        LWidget.SetWindowShape(LWidget.Shape, LWindow^.window);
      end;
    end;
  end;

  LWidget.BeginUpdate;
  try
    LWidget.Visible := LVisible;
    if LWidget.Visible then
    begin
      if (fsModal in LForm.FormState) and (Application.ModalLevel > 0) then
        BlockTransientWindow(LWindow, True);
      CheckAndFixGeometry(LForm); //See issue #41412
      LWindow^.show_all;
      LWindow^.window^.set_events(GDK_ALL_EVENTS_MASK);
      LWindow^.present;
      SetAlphaBlend(LForm, LForm.AlphaBlend, LForm.AlphaBlendValue);
    end
    else // Hide
    begin
      if (fsModal in LForm.FormState) then
        BlockTransientWindow(LWindow, False);
      if (fsModal in LForm.FormState) or (LForm.BorderStyle = bsNone) then
        LWindow^.set_transient_for(nil);
    end;
  finally
    LWidget.EndUpdate;
  end;
end;

{ TACLWSScrollingControl }

class procedure TACLWSScrollingControl.DispatchNonClientMessage(
  AControl: TWinControl; var AMessage: TMessage);
begin
  // do nothing
end;

end.
