////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Basic Form things
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Forms.Base;

{$I ACL.Config.inc}

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
  {System.}Contnrs,
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
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.FontCache,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Threading,
  ACL.UI.Application,
  ACL.UI.Controls.Base,
  ACL.UI.ImageList,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Desktop,
  ACL.Utils.DPIAware,
  ACL.Utils.RTTI,
  ACL.Utils.Strings;

{$IFDEF FPC}
const
  WM_ENTERMENULOOP = $0211;
  WM_EXITMENULOOP  = $0212;
  WM_NCACTIVATE    = LM_NCACTIVATE;
{$ENDIF}

type
{$IFDEF FPC}
  TWindowHook = function (var Message: TMessage): Boolean of object;
  TWMNCActivate = TLMNCActivate;
{$ELSE}
  TShowInTaskbar = (stDefault, stAlways, stNever);
{$ENDIF}

{$REGION ' Basic Form '}

  { TACLBasicForm }

  TACLBasicForm = class(TForm,
    IACLApplicationListener,
    IACLCurrentDpi)
  strict private
    FLoadedClientHeight: Integer;
    FLoadedClientWidth: Integer;
  {$IFNDEF DELPHI120}
    FParentFontLocked: Boolean;
  {$ENDIF}

    procedure ApplyColorSchema;
    procedure SetClientHeight(Value: Integer);
    procedure SetClientWidth(Value: Integer);
    procedure TakeParentFontIfNecessary;
    // IACLCurrentDpi
    function GetCurrentDpi: Integer;
    //# Messages
  {$IFDEF FPC}
    procedure WMEraseBkgnd(var Message: TMessage); message WM_ERASEBKGND;
  {$ELSE}
    procedure CMDialogKey(var Message: TCMDialogKey); message CM_DIALOGKEY;
    procedure CMParentFontChanged(var Message: TCMParentFontChanged); message CM_PARENTFONTCHANGED;
    procedure WMAppCommand(var Message: TMessage); message WM_APPCOMMAND;
    procedure WMDPIChanged(var Message: TWMDpi); message WM_DPICHANGED;
    procedure WMSettingsChanged(var Message: TWMSettingChange); message WM_SETTINGCHANGE;
    procedure WMSysColorChanged(var Message: TMessage); message WM_SYSCOLORCHANGE;
  {$ENDIF}
  {$IFDEF FPC}
  protected type
    TScalingFlags = set of (sfLeft, sfTop, sfWidth, sfHeight, sfFont, sfDesignSize);
  protected
    FCurrentPPI: Integer;
    FIScaling: Boolean;
    ScalingFlags: TScalingFlags;

    function DoAlignChildControls(AAlign: TAlign; AControl: TControl;
      AList: TTabOrderList; var ARect: TRect): Boolean; override;
    procedure DoAutoAdjustLayout(const AMode: TLayoutAdjustmentPolicy; const X, Y: Double); override;
  {$ELSE}
  protected
    procedure ChangeScale(M, D: Integer; IsDpiChange: Boolean); override; final;
  {$ENDIF}
  protected
    procedure AdjustSize; override;
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure ApplyClientSize(AWidth, AHeight: Integer); virtual;
    function DialogChar(var Message: TWMKey): Boolean; {$IFDEF FPC}override;{$ELSE}virtual;{$ENDIF}
    procedure DoShow; override;
    procedure DpiChanged; virtual;
    procedure InitializeNewForm; {$IFDEF FPC}virtual;{$ELSE}override;{$ENDIF}
    procedure Loaded; override;
    procedure ReadState(Reader: TReader); override;
    procedure SetPixelsPerInch(Value: Integer); {$IFDEF DELPHI110ALEXANDRIA}override;{$ENDIF}
    procedure WndProc(var Message: TMessage); override;

    // IACLApplicationListener
    procedure IACLApplicationListener.Changed = ApplicationSettingsChanged;
    procedure ApplicationSettingsChanged(AChanges: TACLApplicationChanges); virtual;

    // Properties
    property LoadedClientHeight: Integer read FLoadedClientHeight;
    property LoadedClientWidth: Integer read FLoadedClientWidth;
  public
    constructor CreateNew(AOwner: TComponent; ADummy: Integer = 0); override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure ScaleForCurrentDPI{$IFDEF DELPHI120}(ForceScaling: Boolean = False){$ENDIF};{$IFDEF FPC}virtual;{$ELSE}override;{$ENDIF}
    procedure ScaleForPPI(ATargetPPI: Integer); overload; {$IFNDEF FPC}override; final;{$ENDIF}
    procedure ScaleForPPI(ATargetPPI: Integer; AWindowRect: PRect); reintroduce; overload; virtual;
    function SetFocusedControl(Control: TWinControl): Boolean; override;
    //# Properties
    property CurrentDpi: Integer read FCurrentPPI;
  published
    property ClientHeight write SetClientHeight;
    property ClientWidth write SetClientWidth;
    property PixelsPerInch write SetPixelsPerInch;
  end;

{$ENDREGION}

{$REGION ' Custom Form '}

  TACLWindowHookMode = (whmPreprocess, whmPostprocess);

  { TACLWindowHooks }

  TACLWindowHooks = class(TACLList<TWindowHook>)
  public
    function Process(var Message: TMessage): Boolean;
  end;

  { TACLStyleForm }

  TACLStyleForm = class(TACLStyle)
  strict private
    function GetCaptionFont: TFont;
    function GetCaptionFontColor(Active: Boolean): TColor;
  protected
    procedure InitializeResources; override;
  public
    property CaptionFont: TFont read GetCaptionFont;
    property CaptionFontColor[Active: Boolean]: TColor read GetCaptionFontColor;
  published
    property ColorBorder1: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorBorder2: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorContent: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
    property ColorCaption: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
    property ColorCaptionInactive: TACLResourceColor index 5 read GetColor write SetColor stored IsColorStored;
    property ColorText: TACLResourceColor index 6 read GetColor write SetColor stored IsColorStored;
    property Glyphs: TACLResourceTexture index 0 read GetTexture write SetTexture stored IsTextureStored;
  end;

  { TACLCustomForm }

  TACLCustomForm = class(TACLBasicForm,
    IACLResourceChangeListener,
    IACLResourceProvider)
  strict private
    FInCreation: TACLBoolean;
    FInMenuLoop: Integer;
    FPadding: TACLPadding;
    FShowInTaskBar: TShowInTaskbar;
    FStayOnTop: Boolean;
    FStyle: TACLStyleForm;
    FWndProcHooks: array[TACLWindowHookMode] of TACLWindowHooks;

    procedure SetPadding(AValue: TACLPadding);
    procedure SetShowInTaskBar(AValue: TShowInTaskbar);
    procedure SetStayOnTop(AValue: Boolean);
    procedure SetStyle(AStyle: TACLStyleForm);
    procedure PaddingChangeHandler(Sender: TObject);
    procedure UpdateNonClientColors;
  protected
    FOwnerHandle: TWndHandle;
    FRecreateWndLockCount: Integer;

    procedure AdjustClientRect(var Rect: TRect); override;
    procedure AfterFormCreate; virtual;
    procedure BeforeFormCreate; virtual;
    function CanCloseByEscape: Boolean; virtual;
    procedure CreateHandle; override;
    procedure CreateParams(var Params: TCreateParams); override;
    function DialogChar(var Message: TWMKey): Boolean; override;
    procedure DpiChanged; override;
    procedure UpdateImageLists; virtual;

    // Config
    function GetConfigSection: string; virtual;

    // StayOnTop
    function ShouldBeStayOnTop: Boolean; virtual;
    procedure StayOnTopChanged; virtual;

    // IACLResourceChangeListener
    procedure ResourceChanged(Sender: TObject; Resource: TACLResource = nil); overload;
    procedure ResourceChanged; overload; virtual;

    // IACLResourceProvider
    function GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;

    // IACLApplicationListener
    procedure ApplicationSettingsChanged(AChanges: TACLApplicationChanges); override;

    // Properties
    property InCreation: TACLBoolean read FInCreation;
    property InMenuLoop: Integer read FInMenuLoop;
    // Messages
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMRecreateWnd(var Message: TMessage); message {%H-}CM_RECREATEWND;
    procedure CMShowingChanged(var Message: TCMDialogKey); message CM_SHOWINGCHANGED;
    procedure WMEnterMenuLoop(var Msg: TMessage); message WM_ENTERMENULOOP;
    procedure WMExitMenuLoop(var Msg: TMessage); message WM_EXITMENULOOP;
    procedure WMNCActivate(var Msg: TWMNCActivate); message WM_NCACTIVATE;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateDialog(AOwnerHandle: TWndHandle; ANew: Boolean = False); virtual;
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure ShowAndActivate; virtual;
    //# Hooks
    procedure HookWndProc(AHook: TWindowHook; AMode: TACLWindowHookMode = whmPreprocess);
    procedure UnhookWndProc(AHook: TWindowHook);
    //# Placement
    procedure LoadPosition(AConfig: TACLIniFile); virtual;
    procedure SavePosition(AConfig: TACLIniFile); virtual;
    //# Properties
    property Color stored False; // Color synchronizes with resources (ref. to ResourceChanged)
    property DoubleBuffered default True;
    property Padding: TACLPadding read FPadding write SetPadding;
    property ShowInTaskBar: TShowInTaskbar read FShowInTaskBar write SetShowInTaskBar default stDefault;
    property StayOnTop: Boolean read FStayOnTop write SetStayOnTop default False;
    property Style: TACLStyleForm read FStyle write SetStyle;
  end;

{$ENDREGION}

{$REGION ' Helpers '}

  { TACLStayOnTopHelper }

  TACLStayOnTopHelper = class
  strict private
    class var FEvents: TObject;
    class procedure AppEventsModalHandler(Sender: TObject);
    class procedure CheckForApplicationEvents;
    class function StayOnTopAvailable: Boolean;
  public
    class destructor Destroy;
    class function ExecuteCommonDialog(ADialog: TCommonDialog; AHandleWnd: HWND): Boolean;
    class function IsStayOnTop(AHandle: HWND): Boolean;
    class function ShouldBeStayOnTop(AHandle: HWND): Boolean;
    class procedure Refresh(AForm: TACLCustomForm); overload;
    class procedure Refresh; overload;
  end;

{$ENDREGION}

implementation

{$IFNDEF FPC}
uses
  Vcl.AppEvnts;
{$ENDIF}

type
  TCustomFormAccess = class(TCustomForm);
  TWinControlAccess = class(TWinControl);

{$REGION ' Helpers '}

  { TACLFormScalingHelper }

  TACLFormScaling = record
  strict private
    Form: TACLBasicForm;
    LockedControls: TComponentList;
    RedrawLocked: Boolean;
  public
    procedure Done;
    procedure Start(AForm: TACLBasicForm);
  end;

  { TACLFormMouseWheelHelper }

{$IFDEF MSWINDOWS}
  // The helper emulates the "Scrol inactive windows when
  // I hover over them" option from Window 10
  TACLFormMouseWheelHelper = class
  strict private
    class var FHook: HHOOK;
    class function MouseHook(Code: Integer;
      wParam: WParam; lParam: LParam): LRESULT; stdcall; static;
  public
    class destructor Destroy;
    class procedure CheckInstalled;
  end;
{$ENDIF}

{ TACLStayOnTopHelper }

class destructor TACLStayOnTopHelper.Destroy;
begin
  FreeAndNil(FEvents);
end;

class procedure TACLStayOnTopHelper.Refresh(AForm: TACLCustomForm);
const
  StyleMap: array[Boolean] of HWND = (HWND_NOTOPMOST, HWND_TOPMOST);
var
  AStayOnTop: Boolean;
begin
  if (AForm <> nil) and AForm.HandleAllocated and IsWindowVisible(AForm.Handle) then
  begin
    if csDesigning in AForm.ComponentState then Exit;

    AStayOnTop := (AForm.FormStyle = fsStayOnTop) or StayOnTopAvailable and AForm.ShouldBeStayOnTop;
    if IsStayOnTop(AForm.Handle) <> AStayOnTop then
    begin
      if AStayOnTop then
        CheckForApplicationEvents;
      SetWindowPos(AForm.Handle, StyleMap[AStayOnTop], 0, 0, 0, 0,
        SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);
    end;
  end;
end;

class function TACLStayOnTopHelper.ExecuteCommonDialog(
  ADialog: TCommonDialog; AHandleWnd: HWND): Boolean;
begin
  Application.ModalStarted;
  try
    Result := ADialog.Execute{$IFNDEF FPC}(AHandleWnd){$ENDIF};
  finally
    Application.ModalFinished;
  end;
end;

class function TACLStayOnTopHelper.IsStayOnTop(AHandle: HWND): Boolean;
begin
  Result := (AHandle <> 0) and (GetWindowLong(AHandle, GWL_EXSTYLE) and WS_EX_TOPMOST <> 0);
end;

class procedure TACLStayOnTopHelper.Refresh;
var
  AForm: TForm;
  I: Integer;
begin
  for I := Screen.FormCount - 1 downto 0 do
  begin
    AForm := Screen.Forms[I];
    if AForm is TACLCustomForm then
      Refresh(TACLCustomForm(AForm));
  end;
end;

class function TACLStayOnTopHelper.ShouldBeStayOnTop(AHandle: HWND): Boolean;
var
  AControl: TWinControl;
begin
  AControl := FindControl(AHandle);
  Result := (AControl is TACLCustomForm) and TACLCustomForm(AControl).ShouldBeStayOnTop;
end;

class procedure TACLStayOnTopHelper.AppEventsModalHandler(Sender: TObject);
begin
  Refresh;
end;

class procedure TACLStayOnTopHelper.CheckForApplicationEvents;
begin
  if FEvents = nil then
  begin
  {$IFDEF FPC}
    FEvents := TObject.Create;
    Application.AddOnModalBeginHandler(AppEventsModalHandler);
    Application.AddOnModalEndHandler(AppEventsModalHandler);
  {$ELSE}
    FEvents := TApplicationEvents.Create(nil);
    TApplicationEvents(FEvents).OnModalBegin := AppEventsModalHandler;
    TApplicationEvents(FEvents).OnModalEnd := AppEventsModalHandler;
  {$ENDIF}
  end;
end;

class function TACLStayOnTopHelper.StayOnTopAvailable: Boolean;
begin
  Result := Application.ModalLevel = 0;
end;

{ TACLFormScaling }

procedure TACLFormScaling.Start(AForm: TACLBasicForm);

  procedure PopulateControls(AControl: TControl);
  var
    I: Integer;
  begin
    LockedControls.Add(AControl);
    if AControl is TCustomForm then
    begin
      for I := 0 to TCustomFormAccess(AControl).MDIChildCount - 1 do
        PopulateControls(TCustomFormAccess(AControl).MDIChildren[I]);
    end;
    if AControl is TWinControl then
    begin
      for I := 0 to TWinControl(AControl).ControlCount - 1 do
        PopulateControls(TWinControl(AControl).Controls[I]);
    end;
  end;

var
  I: Integer;
begin
  //#AI: don't change the order
  Form := AForm;
  RedrawLocked := acOSCheckVersion(6, 0) and
    IsWindowVisible(AForm.Handle) and not (csDesigning in AForm.ComponentState);
  LockedControls := TComponentList.Create(False);
  PopulateControls(AForm);
  for I := 0 to LockedControls.Count - 1 do
    TControl(LockedControls[I]).Perform(CM_SCALECHANGING, 0, 0);
{$IFDEF MSWINDOWS}
  if RedrawLocked then
    SendMessage(Form.Handle, WM_SETREDRAW, 0, 0);
{$ENDIF}
  AForm.DisableAlign;
end;

procedure TACLFormScaling.Done;
var
  I: Integer;
begin
  //#AI: keep the order
  Form.DpiChanged;
  Form.EnableAlign;
  Form.Realign;
{$IFDEF MSWINDOWS}
  if RedrawLocked then
    SendMessage(Form.Handle, WM_SETREDRAW, 1, 1);
{$ENDIF}
  for I := LockedControls.Count - 1 downto 0 do
    TControl(LockedControls[I]).Perform(CM_SCALECHANGED, 0, 0);
  if RedrawLocked then
    RedrawWindow(Form.Handle, nil, 0, RDW_INVALIDATE or RDW_ALLCHILDREN or RDW_ERASE);
  FreeAndNil(LockedControls);
end;

{$IFDEF MSWINDOWS}

{ TACLFormMouseWheelHelper }

class procedure TACLFormMouseWheelHelper.CheckInstalled;
begin
  if (FHook = 0) and not acOSCheckVersion(10, 0) then
    FHook := SetWindowsHookEx(WH_MOUSE, MouseHook, 0, GetCurrentThreadId);
end;

class destructor TACLFormMouseWheelHelper.Destroy;
begin
  UnhookWindowsHookEx(FHook);
  FHook := 0;
end;

class function TACLFormMouseWheelHelper.MouseHook(
  Code: Integer; wParam: WParam; lParam: LParam): LRESULT; stdcall;
type
  PMouseHookStructEx = ^TMouseHookStructEx;
  TMouseHookStructEx = record
    pt: TPoint;
    hwnd: HWND;
    wHitTestCode: UINT;
    dwExtraInfo: NativeUInt;
    mouseData: DWORD;
  end;

  function ShiftStateToKeys(AShift: TShiftState): WORD;
  begin
    Result := 0;
    if ssShift in AShift then
      Inc(Result, MK_SHIFT);
    if ssCtrl in AShift then
      Inc(Result, MK_CONTROL);
    if ssLeft in AShift then
      Inc(Result, MK_LBUTTON);
    if ssRight in AShift then
      Inc(Result, MK_RBUTTON);
    if ssMiddle in AShift then
      Inc(Result, MK_MBUTTON);
  end;

var
  AControl: TControl;
  AMHS: PMouseHookStructEx;
  APoint: TPoint;
  AWindow: TWinControl;
begin
  Result := 0;
  if (Code >= 0) and ((wParam = WM_MOUSEWHEEL) or (wParam = WM_MOUSEHWHEEL)) and Mouse.WheelPresent then
  begin
    AMHS := PMouseHookStructEx(lParam);

    AWindow := FindControl(AMHS.hwnd);
    if AWindow <> nil then
    begin
      APoint := AMHS.pt;
      if (APoint.X = -1) and (APoint.Y = -1) then
        APoint := MouseCursorPos;

      //#AI: Workaround for Synaptics TouchPad Driver
      if acSameText(acGetClassName(WindowFromPoint(APoint)), 'SynTrackCursorWindowClass') then
      begin
        repeat
          AControl := AWindow.ControlAtPos(AWindow.ScreenToClient(APoint), False, True);
          if AControl = nil then
          begin
            AControl := AWindow;
            Break;
          end;
          if AControl is TWinControl then
            AWindow := TWinControl(AControl)
          else
            Break;
        until False;
      end
      else
        AControl := FindDragTarget(APoint, False);

      if (AControl <> nil) and (AControl <> AWindow) then
      begin
        Result := AControl.Perform(CM_MOUSEWHEEL,
          MakeWParam(ShiftStateToKeys(KeyboardStateToShiftState), HiWord(AMHS.mouseData)),
          PointToLParam(APoint));
        if Result = 1 then
          Exit(1);
      end;
    end;
  end
  else
    Result := CallNextHookEx(FHook, code, wParam, lParam);
end;
{$ENDIF}

{$ENDREGION}

{$REGION ' Basic Form '}

{ TACLBasicForm }

constructor TACLBasicForm.CreateNew(AOwner: TComponent; ADummy: Integer);
begin
{$IFDEF FPC}
  FCurrentPPI := acDefaultDpi;
{$ENDIF}
  inherited CreateNew(AOwner, ADummy);
{$IFDEF FPC}
  InitializeNewForm;
{$ENDIF}
end;

procedure TACLBasicForm.AdjustSize;
begin
{$IFDEF MSWINDOWS}
  // When a top level window is maximized the call to SetWindowPos
  // isn't needed unless the size of the window has changed.
  if IsZoomed(Handle) and (GetParent(Handle) = 0) and not AutoSize then
  begin
    RequestAlign;
    Exit;
  end;
{$ENDIF}
  inherited;
end;

procedure TACLBasicForm.AfterConstruction;
begin
  TACLApplication.ListenerAdd(Self);
  inherited; // OnCreate handler may change the TACLApplication's settings
  if TACLApplication.ColorSchema.IsAssigned then
    ApplyColorSchema;
end;

procedure TACLBasicForm.BeforeDestruction;
begin
  inherited;
  TACLApplication.ListenerRemove(Self);
end;

procedure TACLBasicForm.ApplyColorSchema;
var
  I: Integer;
begin
  for I := 0 to ComponentCount - 1 do
    acApplyColorSchema(Components[I], TACLApplication.ColorSchema);
end;

procedure TACLBasicForm.ApplyClientSize(AWidth, AHeight: Integer);
begin
  if AWidth >  0 then
    inherited ClientWidth := AWidth;
  if AHeight > 0 then
    inherited ClientHeight := AHeight;
end;

{$IFDEF FPC}
function TACLBasicForm.DoAlignChildControls(AAlign: TAlign;
  AControl: TControl; AList: TTabOrderList; var ARect: TRect): Boolean;
begin
  TACLOrderedAlign.List(Self, [AAlign], AList);
  Result := False;
end;

procedure TACLBasicForm.DoAutoAdjustLayout(
  const AMode: TLayoutAdjustmentPolicy; const X, Y: Double);
begin
  if FIScaling or (AMode <> lapAutoAdjustForDPI) then
    inherited
  else
    ScaleForPPI(Round(X * FCurrentPPI));
end;

{$ELSE}
procedure TACLBasicForm.ChangeScale(M, D: Integer; IsDpiChange: Boolean);
begin
  ScaleForPPI(MulDiv(FCurrentPPI, M, D));
end;
{$ENDIF}

procedure TACLBasicForm.ScaleForPPI(ATargetPPI: Integer; AWindowRect: PRect);
var
  LScaling: TACLFormScaling;
  LPrevBounds: TRect;
  LPrevClientRect: TRect;
  LPrevDPI: Integer;
  LPrevParentFont: Boolean;
{$IFNDEF FPC}
  LPrevScaled: Boolean;
{$ENDIF}
begin
  if FIScaling or (ATargetPPI < acMinDPI) then
    Exit;
{$IFNDEF DELPHI120}
  if ATargetPPI = FCurrentPPI then
    Exit;
{$ENDIF}

  LScaling.Start(Self);
  try
    LPrevDPI := FCurrentPPI;
    LPrevBounds := BoundsRect;
    LPrevClientRect := ClientRect;
    LPrevParentFont := ParentFont;

  {$IFDEF FPC}
    FIScaling := True;
    AutoAdjustLayout(lapAutoAdjustForDPI, FCurrentPPI, ATargetPPI, 0, 0);
    FIScaling := False;
  {$ELSE}
    LPrevScaled := Scaled;
    try
      Scaled := True; // for Delphi 11.0
      inherited ScaleForPPI(ATargetPPI);
    finally
      Scaled := LPrevScaled;
    end;
  {$ENDIF}

    FCurrentPPI := ATargetPPI;
    PixelsPerInch := ATargetPPI;
    ParentFont := LPrevParentFont;

    if AWindowRect <> nil then
      BoundsRect := AWindowRect^
    else
      if not (AutoScroll or (HorzScrollBar.Range <> 0) or (VertScrollBar.Range <> 0)) then
      begin
        if WindowState <> wsMaximized then
        begin
          SetBounds(LPrevBounds.Left, LPrevBounds.Top,
            LPrevBounds.Width - LPrevClientRect.Right +
              MulDiv(LPrevClientRect.Right, ATargetPPI, LPrevDPI),
            LPrevBounds.Height - LPrevClientRect.Bottom +
              MulDiv(LPrevClientRect.Bottom, ATargetPPI, LPrevDPI));
        end
        else
          BoundsRect := LPrevBounds;
      end;
  finally
    LScaling.Done;
  end;
end;

procedure TACLBasicForm.ScaleForPPI(ATargetPPI: Integer);
begin
  ScaleForPPI(ATargetPPI, nil);
end;

function TACLBasicForm.SetFocusedControl(Control: TWinControl): Boolean;
begin
  Result := inherited SetFocusedControl(Control);
{$IFDEF FPC}
  if Result then
  begin
    if Control = nil then
      Control := Self;
    BroadcastRecursive(CM_FOCUSCHANGED, 0, LParam(Control));
  end;
{$ENDIF}
end;

function TACLBasicForm.DialogChar(var Message: TWMKey): Boolean;
begin
{$IFDEF FPC}
  Result := inherited;
{$ELSE}
  Result := False;
{$ENDIF}
end;

procedure TACLBasicForm.DoShow;
begin
  inherited DoShow;
  ScaleForCurrentDpi; //#AI: for dynamically created forms
end;

procedure TACLBasicForm.InitializeNewForm;
begin
  //#AI:
  // В TCustomForm.InitializeNewForm сначала выставляются дефолтные размеры формы, а уже потом Visible в False.
  // На Wine зз-за этого форма на секунду становится видимой в нулевых координатах.
  Visible := False;
  inherited;
{$IFNDEF FPC}
  if FCurrentPPI = 0 then
    FCurrentPPI := PixelsPerInch;
{$ENDIF}
  if not ParentFont then
    Font.Height := acGetFontHeight(FCurrentPPI, Font.Size);
end;

procedure TACLBasicForm.Loaded;
begin
  inherited;
  TakeParentFontIfNecessary;
end;

procedure TACLBasicForm.DpiChanged;
begin
  TakeParentFontIfNecessary;
end;

procedure TACLBasicForm.ScaleForCurrentDPI;
begin
  DisableAlign;
  try
    if Scaled and not (csDesigning in ComponentState) and (Parent = nil) then
      ScaleForPPI(TACLApplication.GetTargetDPI(Self));
    ScalingFlags := [];
    Perform(CM_PARENTBIDIMODECHANGED, 0, 0);
  finally
    EnableAlign;
  end;
end;

procedure TACLBasicForm.ReadState(Reader: TReader);
begin
  DisableAlign;
  try
    FLoadedClientHeight := 0;
    FLoadedClientWidth := 0;
    inherited;
    ApplyClientSize(FLoadedClientWidth, FLoadedClientHeight);
  finally
    EnableAlign;
  end;
end;

procedure TACLBasicForm.AlignControls(AControl: TControl; var Rect: TRect);
begin
{$IFDEF FPC}
  inherited;
{$ELSE}
  TACLOrderedAlign.Apply(Self, Rect);
{$ENDIF}
end;

procedure TACLBasicForm.ApplicationSettingsChanged(AChanges: TACLApplicationChanges);
begin
  if acScalingMode in AChanges then
  begin
    if Scaled and not (csDesigning in ComponentState) then
      ScaleForCurrentDpi;
  end;
  if acColorSchema in AChanges then
    ApplyColorSchema;
end;

procedure TACLBasicForm.SetClientHeight(Value: Integer);
begin
  if csReadingState in ControlState then
  begin
    FLoadedClientHeight := Value;
    ScalingFlags := ScalingFlags + [sfHeight];
  end
  else
    inherited ClientHeight := Value;
end;

procedure TACLBasicForm.SetClientWidth(Value: Integer);
begin
  if csReadingState in ControlState then
  begin
    FLoadedClientWidth := Value;
    ScalingFlags := ScalingFlags + [sfWidth];
  end
  else
    inherited ClientWidth := Value;
end;

procedure TACLBasicForm.SetPixelsPerInch(Value: Integer);
begin
{$IFNDEF FPC}
  if csReadingState in ControlState then
    FCurrentPPI := Value;
{$ENDIF}
{$IFDEF DELPHI110ALEXANDRIA}
  inherited;
{$ELSE}
  inherited PixelsPerInch := Value;
{$ENDIF}
end;

procedure TACLBasicForm.WndProc(var Message: TMessage);
begin
  if not TACLControls.WndProc(Self, Message) then
    inherited WndProc(Message);
end;

function TACLBasicForm.GetCurrentDpi: Integer;
begin
  Result := FCurrentPPI;
end;

procedure TACLBasicForm.TakeParentFontIfNecessary;
begin
{$IFNDEF DELPHI120}
  // Workaround for
  // The "TForm.ParentFont = true causes scaling error with HighDPI" issue
  // https://quality.embarcadero.com/browse/RSP-30677
  if ParentFont and not FParentFontLocked then
  begin
    FParentFontLocked := True;
    try
      if (Parent <> nil) and not (csDesigning in ComponentState) then
        Font := TWinControlAccess(Parent).Font
      else
        acAssignFont(Font, TACLApplication.DefaultFont, FCurrentPPI, acGetSystemDpi);

      ParentFont := True;
    finally
      FParentFontLocked := False;
    end;
  end;
{$ENDIF}
end;

{$IFDEF FPC}
procedure TACLBasicForm.WMEraseBkgnd(var Message: TMessage);
begin
  if (Message.WParam = Message.LParam) and (Message.LParam <> 0) then
  begin
    Canvas.Handle := Message.LParam;
    try
      acFillRect(Canvas, ClientRect, Color);
    finally
      Canvas.Handle := 0;
    end;
  end
  else
    inherited;
end;
{$ELSE}
procedure TACLBasicForm.CMDialogKey(var Message: TCMDialogChar);
begin
  if DialogChar(Message) then
    Message.Result := 1
  else
    inherited;
end;

procedure TACLBasicForm.CMParentFontChanged(var Message: TCMParentFontChanged);
begin
{$IFDEF DELPHI120}
  inherited;
{$ELSE}
  if ParentFont then
  begin
    if Message.wParam <> 0 then
      Font.Assign(Message.Font)
    else
      TakeParentFontIfNecessary;
  end;
{$ENDIF}
end;

procedure TACLBasicForm.WMAppCommand(var Message: TMessage);
begin
  if Message.Result = 0 then
    Message.Result := SendMessage(Application.Handle, Message.Msg, Message.WParam, Message.LParam);
end;

procedure TACLBasicForm.WMDPIChanged(var Message: TWMDpi);
var
  LPrevDPI: Integer;
begin
  if (Message.YDpi = 0) or not Scaled then
    Exit;
  if [csDesigning, csLoading] * ComponentState = [] then
  begin
    if (Message.YDpi <> FCurrentPPI) and (TACLApplication.TargetDPI = 0) then
    begin
      LPrevDPI := FCurrentPPI;
      DoBeforeMonitorDpiChanged(LPrevDPI, Message.YDpi);
      ScaleForPPI(Message.YDpi, Message.ScaledRect);
      DoAfterMonitorDpiChanged(LPrevDPI, Message.YDpi);
    end;
    Message.Result := 0;
  end;
end;

procedure TACLBasicForm.WMSettingsChanged(var Message: TWMSettingChange);
begin
  inherited;
  FSystemDpiCache := 0;
  if (Message.Section <> nil) and (Message.Section = 'ImmersiveColorSet') then
    TACLApplication.UpdateColorSet;
end;

procedure TACLBasicForm.WMSysColorChanged(var Message: TMessage);
begin
  inherited;
  TACLApplication.UpdateColorSet;
end;
{$ENDIF}

{$ENDREGION}

{$REGION ' Custom Form '}

{ TACLWindowHooks }

function TACLWindowHooks.Process(var Message: TMessage): Boolean;
var
  I: Integer;
begin
  if Self = nil then
    Exit(False);
  for I := Count - 1 downto 0 do
    if List[I](Message) then
      Exit(True);
  Result := False;
end;

{ TACLStyleForm }

function TACLStyleForm.GetCaptionFont: TFont;
begin
{$IFDEF FPC}
  Result := Screen.SystemFont;
{$ELSE}
  Result := Screen.CaptionFont;
{$ENDIF}
end;

function TACLStyleForm.GetCaptionFontColor(Active: Boolean): TColor;
begin
  if Active then
    Result := ColorCaption.AsColor
  else
    Result := ColorCaptionInactive.AsColor;
end;

procedure TACLStyleForm.InitializeResources;
begin
  ColorBorder1.InitailizeDefaults('Form.Colors.Border');
  ColorBorder2.InitailizeDefaults('Form.Colors.BorderInactive');
  ColorContent.InitailizeDefaults('Form.Colors.Background', True);
  ColorCaption.InitailizeDefaults('Form.Colors.CaptionText', True);
  ColorCaptionInactive.InitailizeDefaults('Form.Colors.CaptionTextInactive', True);
  ColorText.InitailizeDefaults('Form.Colors.Text', True);
  Glyphs.InitailizeDefaults('Form.Textures.Glyphs');
end;

{ TACLCustomForm }

constructor TACLCustomForm.Create(AOwner: TComponent);
begin
  BeforeFormCreate;
  inherited Create(AOwner);
  AfterFormCreate;
end;

constructor TACLCustomForm.CreateDialog(AOwnerHandle: TWndHandle; ANew: Boolean = False);
var
  AOwner: TComponent;
begin
  FOwnerHandle := AOwnerHandle;
  AOwner := FindControl(AOwnerHandle);
  if AOwner is TCustomForm then
    AOwner := GetParentForm(TCustomForm(AOwner)); // to make a poOwnerFormCenter works correctly
  if AOwner = nil then
    AOwner := Application;
  if ANew then
    CreateNew(AOwner)
  else
    Create(AOwner);
end;

procedure TACLCustomForm.CreateHandle;
begin
  inherited;
  UpdateNonClientColors;
end;

constructor TACLCustomForm.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
begin
  // Lazarus вызывает CreateNew из Create.
  // Из-за чего у нас возникал двойной вызов событий before/after form create
  if FInCreation = TACLBoolean.Default then
  begin
    BeforeFormCreate;
    inherited CreateNew(AOwner, Dummy);
    AfterFormCreate;
  end
  else
    inherited CreateNew(AOwner, Dummy);
end;

destructor TACLCustomForm.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FWndProcHooks[whmPostprocess]);
  FreeAndNil(FWndProcHooks[whmPreprocess]);
  FreeAndNil(FPadding);
  FreeAndNil(FStyle);
  MinimizeMemoryUsage;
end;

procedure TACLCustomForm.AfterConstruction;
begin
  inherited;
  FInCreation := acFalse;
  ResourceChanged;
  UpdateImageLists;
end;

procedure TACLCustomForm.AfterFormCreate;
begin
  DoubleBuffered := True;
{$IFDEF MSWINDOWS}
  TACLFormMouseWheelHelper.CheckInstalled;
{$ENDIF}
end;

procedure TACLCustomForm.BeforeFormCreate;
begin
  FInCreation := acTrue;
  FPadding := TACLPadding.Create(0);
  FPadding.OnChanged := PaddingChangeHandler;
  FStyle := TACLStyleForm.Create(Self);
end;

function TACLCustomForm.CanCloseByEscape: Boolean;
begin
  Result := False;
end;

procedure TACLCustomForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if (Parent = nil) and (ParentWindow = 0) then
  begin
    if ShowInTaskBar = stAlways then
      Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
    if (Application.MainForm <> nil) and Application.MainForm.HandleAllocated then
      Params.WndParent := Application.MainFormHandle;
    if FOwnerHandle <> 0 then
      Params.WndParent := FOwnerHandle;
  end;
end;

procedure TACLCustomForm.DpiChanged;
begin
  inherited;
  if FInCreation = acFalse then
    ResourceChanged;
  UpdateImageLists;
end;

procedure TACLCustomForm.HookWndProc(AHook: TWindowHook; AMode: TACLWindowHookMode = whmPreprocess);
begin
  if FWndProcHooks[AMode] = nil then
    FWndProcHooks[AMode] := TACLWindowHooks.Create;
  FWndProcHooks[AMode].Add(AHook);
end;

procedure TACLCustomForm.UnhookWndProc(AHook: TWindowHook);
begin
  if FWndProcHooks[whmPostprocess] <> nil then
    FWndProcHooks[whmPostprocess].Remove(AHook);
  if FWndProcHooks[whmPreprocess] <> nil then
    FWndProcHooks[whmPreprocess].Remove(AHook);
end;

procedure TACLCustomForm.LoadPosition(AConfig: TACLIniFile);

  function IsFormResizable: Boolean;
  begin
    Result := BorderStyle in [bsSizeable, bsSizeToolWin];
  end;

  procedure RestoreBounds(ABounds: TRect);
  begin
    if IsFormResizable then
      ABounds.Size := dpiApply(ABounds.Size, FCurrentPPI)
    else
      ABounds.Size := TSize.Create(Width, Height);

  {$IFDEF FPC}
    BoundsRect := ABounds;
  {$ELSE}
    var LPlacement: TWindowPlacement;
    ZeroMemory(@LPlacement, SizeOf(LPlacement));
    LPlacement.Length := SizeOf(TWindowPlacement);
    LPlacement.rcNormalPosition := ABounds;
    SetWindowPlacement(Handle, LPlacement);
  {$ENDIF}
  end;

var
  LCfgSection: string;
begin
  Inc(FRecreateWndLockCount);
  try
    LCfgSection := GetConfigSection;
    if AConfig.ExistsKey(LCfgSection, 'WindowRect') then
    begin
      RestoreBounds(AConfig.ReadRect(LCfgSection, 'WindowRect'));
      Position := poDesigned;
      DefaultMonitor := dmDesktop;
      if not MonitorGetBounds(BoundsRect.TopLeft).Contains(BoundsRect) then
        MakeFullyVisible;
    end;
    if IsFormResizable and AConfig.ReadBool(LCfgSection, 'WindowMaximized') then
      WindowState := wsMaximized;
  finally
    Dec(FRecreateWndLockCount);
  end;
end;

procedure TACLCustomForm.SavePosition(AConfig: TACLIniFile);
var
  LBounds: TRect;
  LCfgSection: string;
  LIsMaximized: Boolean;
{$IFNDEF FPC}
  LPlacement: TWindowPlacement;
{$ENDIF}
begin
  if HandleAllocated then
  begin
    LCfgSection := GetConfigSection;
  {$IFDEF FPC}
    LBounds := BoundsRect;
    LIsMaximized := WindowState = wsMaximized;
  {$ELSE}
    LPlacement.Length := SizeOf(TWindowPlacement);
    if not GetWindowPlacement(Handle, LPlacement) then
      Exit;
    LBounds := LPlacement.rcNormalPosition;
    case WindowState of
      wsMaximized:
        LIsMaximized := True;
      wsMinimized:
        LIsMaximized := LPlacement.flags and WPF_RESTORETOMAXIMIZED = WPF_RESTORETOMAXIMIZED;
    else
      LIsMaximized := False;
    end;
  {$ENDIF}
    LBounds.Height := dpiRevert(LBounds.Height, FCurrentPPI);
    LBounds.Width := dpiRevert(LBounds.Width, FCurrentPPI);
    AConfig.WriteBool(LCfgSection, 'WindowMaximized', LIsMaximized);
    AConfig.WriteRect(LCfgSection, 'WindowRect', LBounds);
  end;
end;

procedure TACLCustomForm.ShowAndActivate;
begin
  if TACLApplication.IsMinimized then
    Visible := False;
  Show;
  SetForegroundWindow(Handle);
  SetFocus;
end;

procedure TACLCustomForm.UpdateImageLists;
begin
  TACLImageListReplacer.Execute(FCurrentPPI, Self);
end;

procedure TACLCustomForm.UpdateNonClientColors;
{$IFDEF MSWINDOWS}
const
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
var
  LValue: LongBool;
  LWidth: Integer;
begin
  // https://stackoverflow.com/questions/39261826/change-the-color-of-the-title-bar-caption-of-a-win32-application
  if HandleAllocated and acOSCheckVersion(10, 0, 18985) then
  begin
    LValue := TACLApplication.IsDarkMode;
    DwmSetWindowAttribute(Handle, DWMWA_USE_IMMERSIVE_DARK_MODE, @LValue, SizeOf(LValue));
    // Fully recalculate and redraw the window
    LWidth := Width;
    SetWindowPos(Handle, 0, 0, 0, LWidth + 1,
      Height, SWP_NOZORDER or SWP_NOACTIVATE or SWP_NOMOVE);
    SetWindowPos(Handle, 0, 0, 0, LWidth,
      Height, SWP_NOZORDER or SWP_NOACTIVATE or SWP_NOMOVE);
  end;
{$ELSE}
begin
{$ENDIF}
end;

procedure TACLCustomForm.AdjustClientRect(var Rect: TRect);
begin
  inherited AdjustClientRect(Rect);
  Rect.Content(Padding.GetScaledMargins(FCurrentPPI));
end;

function TACLCustomForm.ShouldBeStayOnTop: Boolean;
begin
  Result := StayOnTop{$IFNDEF FPC} or TACLStayOnTopHelper.ShouldBeStayOnTop(GetOwnerWindow);{$ENDIF}
end;

procedure TACLCustomForm.StayOnTopChanged;
begin
  // nothing
end;

procedure TACLCustomForm.ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
begin
  if FInCreation = acFalse then
    ResourceChanged;
end;

procedure TACLCustomForm.ResourceChanged;
begin
  Color := Style.ColorContent.AsColor;
end;

function TACLCustomForm.GetResource(const ID: string;
  AResourceClass: TClass; ASender: TObject = nil): TObject;
begin
  Result := TACLRootResourceCollection.GetResource(ID, AResourceClass, ASender);
end;

procedure TACLCustomForm.ApplicationSettingsChanged(AChanges: TACLApplicationChanges);
begin
  inherited;
  if acDarkMode in AChanges then
  begin
    UpdateNonClientColors;
    UpdateImageLists;
  end;
end;

function TACLCustomForm.DialogChar(var Message: TWMKey): Boolean;
begin
  case Message.CharCode of
    VK_RETURN:
      if [ssCtrl, ssAlt, ssShift] * KeyDataToShiftState(Message.KeyData) = [ssCtrl] then
      begin
        if fsModal in FormState then
        begin
          ModalResult := mrOk;
          Exit(True);
        end;
      end;

    VK_ESCAPE:
      if [ssCtrl, ssAlt, ssShift] * KeyDataToShiftState(Message.KeyData) = [] then
      begin
        if fsModal in FormState then
        begin
          ModalResult := mrCancel;
          Exit(True);
        end;
        if CanCloseByEscape then
        begin
          Close;
          Exit(True);
        end;
      end;
  end;
  Result := inherited;
end;

procedure TACLCustomForm.CMFontChanged(var Message: TMessage);
begin
  if FInCreation = acFalse then
    ResourceChanged;
  inherited;
end;

procedure TACLCustomForm.CMRecreateWnd(var Message: TMessage);
begin
  if FRecreateWndLockCount = 0 then
    inherited;
end;

procedure TACLCustomForm.CMShowingChanged(var Message: TCMDialogKey);
var
  AIsDefaultPositionCenter: Boolean;
begin
  AIsDefaultPositionCenter := Position in [poMainFormCenter, poOwnerFormCenter];
  inherited;
  if Visible and AIsDefaultPositionCenter then
    MakeFullyVisible;
end;

procedure TACLCustomForm.WMEnterMenuLoop(var Msg: TMessage);
begin
  Inc(FInMenuLoop);
  inherited;
end;

procedure TACLCustomForm.WMExitMenuLoop(var Msg: TMessage);
begin
  inherited;
  Dec(FInMenuLoop);
end;

procedure TACLCustomForm.WMNCActivate(var Msg: TWMNCActivate);
begin
  // Чтобы не было промаргивания при фокусировке контрола внутри попапа.
  if (FInMenuLoop <> 0) and not Msg.Active then
    Msg.Active := True;
  inherited;
end;

procedure TACLCustomForm.WMPaint(var Message: TWMPaint);
begin
  if (Message.DC <> 0) or not DoubleBuffered then
    PaintHandler(Message)
  else
    TACLControls.BufferedPaint(Self);
end;

procedure TACLCustomForm.WndProc(var Message: TMessage);
begin
  if not FWndProcHooks[whmPreprocess].Process(Message) then
  begin
    inherited WndProc(Message);
  {$IFDEF MSWINDOWS}
    if (Message.Msg = WM_SHOWWINDOW) or
       (Message.Msg = WM_WINDOWPOSCHANGED) and Visible
    then
      TACLStayOnTopHelper.Refresh;
  {$ENDIF}
    if Message.Msg <> CM_RELEASE then
      FWndProcHooks[whmPostprocess].Process(Message);
  end;
end;

function TACLCustomForm.GetConfigSection: string;
begin
  Result := Name;
end;

procedure TACLCustomForm.SetPadding(AValue: TACLPadding);
begin
  FPadding.Assign(AValue);
end;

procedure TACLCustomForm.SetShowInTaskBar(AValue: TShowInTaskbar);
{$IFDEF FPC}
begin
  inherited ShowInTaskBar := AValue
{$ELSE}
var
  LExStyle: Cardinal;
begin
  if FShowInTaskBar <> AValue then
  begin
    FShowInTaskBar := AValue;
    if HandleAllocated and not (csDesigning in ComponentState) then
    begin
      LExStyle := GetWindowLong(Handle, GWL_EXSTYLE);
      if ShowInTaskBar = stAlways then
        LExStyle := LExStyle or WS_EX_APPWINDOW
      else
        LExStyle := LExStyle and not WS_EX_APPWINDOW;
      SetWindowLong(Handle, GWL_EXSTYLE, LExStyle);
    end;
  end;
{$ENDIF}
end;

procedure TACLCustomForm.SetStayOnTop(AValue: Boolean);
begin
  if AValue <> FStayOnTop then
  begin
    FStayOnTop := AValue;
    TACLStayOnTopHelper.Refresh;
    StayOnTopChanged;
  end;
end;

procedure TACLCustomForm.SetStyle(AStyle: TACLStyleForm);
begin
  FStyle.Assign(AStyle);
end;

procedure TACLCustomForm.PaddingChangeHandler(Sender: TObject);
begin
  Realign;
end;

{$ENDREGION}

end.
