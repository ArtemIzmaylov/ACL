﻿{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*    Forms and Top Level Window Classes     *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Forms;

{$I ACL.Config.inc} // FPC:Partial

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
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
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Threading,
  ACL.UI.Application,
  ACL.UI.Controls.BaseControls,
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
{$ENDIF}

type
{$IFDEF FPC}
  TScalingFlags = set of (sfLeft, sfTop, sfWidth, sfHeight, sfFont, sfDesignSize);
  TWindowHook = function (var Message: TMessage): Boolean of object;
{$ENDIF}

  { TACLBasicForm }

  TACLBasicForm = class(TForm,
    IACLApplicationListener,
    IACLCurrentDpi)
  strict private
    FLoadedClientHeight: Integer;
    FLoadedClientWidth: Integer;
    FParentFontLocked: Boolean;

    procedure ApplyColorSchema;
    procedure SetClientHeight(Value: Integer);
    procedure SetClientWidth(Value: Integer);
    procedure TakeParentFontIfNecessary;
    // IACLCurrentDpi
    function GetCurrentDpi: Integer;
    //# Messages
  {$IFNDEF FPC}
    procedure CMParentFontChanged(var Message: TCMParentFontChanged); message CM_PARENTFONTCHANGED;
    procedure WMAppCommand(var Message: TMessage); message WM_APPCOMMAND;
    procedure WMDPIChanged(var Message: TWMDpi); message WM_DPICHANGED;
    procedure WMSettingsChanged(var Message: TWMSettingChange); message WM_SETTINGCHANGE;
  {$ENDIF}
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
  protected
  {$IFDEF FPC}
    ScalingFlags: TScalingFlags;
  {$ENDIF}

    procedure ChangeScale(M, D: Integer{$IFNDEF FPC}; IsDpiChange: Boolean{$ENDIF}); override;
    procedure DoShow; override;
    procedure DpiChanged; virtual;
    procedure InitializeNewForm; {$IFDEF FPC}virtual;{$ELSE}override;{$ENDIF}
    procedure Loaded; override;
    procedure ReadState(Reader: TReader); override;
    procedure SetPixelsPerInch(Value: Integer); {$IFDEF DELPHI110ALEXANDRIA}override;{$ENDIF}

    // IACLApplicationListener
    procedure IACLApplicationListener.Changed = ApplicationSettingsChanged;
    procedure ApplicationSettingsChanged(AChanges: TACLApplicationChanges); virtual;
  public
    constructor CreateNew(AOwner: TComponent; ADummy: Integer = 0); override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure ScaleForCurrentDPI{$IFDEF DELPHI120}(ForceScaling: Boolean = False){$ENDIF};{$IFNDEF FPC}override;{$ENDIF}
    procedure ScaleForPPI(ATargetPPI: Integer); overload; {$IFNDEF FPC}override; final;{$ENDIF}
    procedure ScaleForPPI(ATargetPPI: Integer; AWindowRect: PRect); reintroduce; overload; virtual;
    //# Properties
    property CurrentDpi: Integer read {$IFDEF FPC}GetCurrentDpi{$ELSE}FCurrentPPI{$ENDIF};
  published
    property ClientHeight write SetClientHeight;
    property ClientWidth write SetClientWidth;
    property PixelsPerInch write SetPixelsPerInch;
  end;

  { TACLWindowHooks }

  TACLWindowHooks = class(TACLList<TWindowHook>)
  public
    function Process(var Message: TMessage): Boolean;
  end;

  { TACLForm }

  TACLWindowHookMode = (whmPreprocess, whmPostprocess);

  TACLForm = class(TACLBasicForm,
    IACLResourceChangeListener,
    IACLResourceProvider)
  strict private
    FFormCreated: Boolean;
    FInMenuLoop: Integer;
  {$IFNDEF FPC}
    FShowOnTaskBar: Boolean;
  {$ENDIF}
    FStayOnTop: Boolean;
    FWndProcHooks: array[TACLWindowHookMode] of TACLWindowHooks;

    function GetShowOnTaskBar: Boolean;
    procedure SetShowOnTaskBar(AValue: Boolean);
    procedure SetStayOnTop(AValue: Boolean);
    procedure UpdateNonClientColors;
  protected
    FOwnerHandle: THandle;
    FRecreateWndLockCount: Integer;

    procedure AfterFormCreate; virtual;
    procedure BeforeFormCreate; virtual;
    function CanCloseByEscape: Boolean; virtual;
    procedure CreateHandle; override;
    procedure CreateParams(var Params: TCreateParams); override;
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

    // Messages
    procedure CMDialogKey(var Message: TCMDialogKey); message CM_DIALOGKEY;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMRecreateWnd(var Message: TMessage); message CM_RECREATEWND;
    procedure CMShowingChanged(var Message: TCMDialogKey); message CM_SHOWINGCHANGED;
    procedure WMEnterMenuLoop(var Msg: TMessage); message WM_ENTERMENULOOP;
    procedure WMExitMenuLoop(var Msg: TMessage); message WM_EXITMENULOOP;
  {$IFNDEF FPC}
    procedure WMNCActivate(var Msg: TWMNCActivate); message WM_NCACTIVATE;
    procedure WMShowWindow(var Message: TMessage); message WM_SHOWWINDOW;
    procedure WMWindowPosChanged(var Message: TMessage); message WM_WINDOWPOSCHANGED;
  {$ENDIF}
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateDialog(AOwnerHandle: THandle; ANew: Boolean = False); virtual;
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure ShowAndActivate; virtual;
    // Hooks
    procedure HookWndProc(AHook: TWindowHook; AMode: TACLWindowHookMode = whmPreprocess);
    procedure UnhookWndProc(AHook: TWindowHook);
    // Placement
    procedure LoadPosition(AConfig: TACLIniFile); virtual;
    procedure SavePosition(AConfig: TACLIniFile); virtual;
  published
    property Color stored False; // Color synchronizes with resources (ref. to ResourceChanged)
    property DoubleBuffered default True;
    property ShowOnTaskBar: Boolean read GetShowOnTaskBar write SetShowOnTaskBar default False;
    property StayOnTop: Boolean read FStayOnTop write SetStayOnTop default False;
  end;

  { TACLPopupWindow }

  TACLPopupWindowClass = class of TACLPopupWindow;
  TACLPopupWindow = class(TACLBasicForm)
  strict private
    FOwnerFormWnd: THandle;

    FOnClosePopup: TNotifyEvent;
    FOnPopup: TNotifyEvent;

    procedure ConstraintBounds(var R: TRect);
    procedure InitPopup;
    procedure InitScaling;
    procedure ShowPopup(const R: TRect);
    //# Messages
    procedure CMCancelMode(var Message: TCMCancelMode); message CM_CANCELMODE;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;
    //# Events
    procedure DoPopup; virtual;
    procedure DoPopupClosed; virtual;
    //# Mouse
    function IsMouseInControl: Boolean;
    //procedure MouseTracking; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ClosePopup;
    procedure Popup(R: TRect); virtual;
    procedure PopupUnderControl(const AControlBoundsOnScreen: TRect; AAlignment: TAlignment = taLeftJustify);
    //# Properties
    property AutoSize;
    //# Events
    property OnClosePopup: TNotifyEvent read FOnClosePopup write FOnClosePopup;
    property OnPopup: TNotifyEvent read FOnPopup write FOnPopup;
  end;

  { TACLLocalizableForm }

  TACLLocalizableForm = class(TACLForm, IACLLocalizableComponentRoot)
  strict private
    procedure WMLANG(var Msg: TMessage); message WM_ACL_LANG;
  protected
    function GetConfigSection: string; override;
    // IACLLocalizableComponentRoot
    function GetLangSection: string; virtual;
    procedure LangChange; virtual;
    function LangValue(const AKey: string): string; overload;
    function LangValue(const AKey: string; APartIndex: Integer): string; overload;
  public
    procedure AfterConstruction; override;
  end;

  { TACLFormImageListReplacer }

  TACLFormImageListReplacer = class
  strict private const
    DarkModeSuffix = 'Dark';
  strict private
    FReplacementCache: TACLObjectDictionary;
    FDarkMode: Boolean;
    FTargetDPI: Integer;

    class function GenerateName(const ABaseName, ASuffix: string; ATargetDPI: Integer): TComponentName; static;
    class function GetBaseImageListName(const AName: TComponentName): TComponentName; static;
  protected
    procedure UpdateImageList(AInstance: TObject; APropInfo: PPropInfo; APropValue: TObject);
    procedure UpdateImageListProperties(APersistent: TPersistent);
    procedure UpdateImageLists(AForm: TCustomForm);
  public
    constructor Create(ATargetDPI: Integer; ADarkMode: Boolean);
    destructor Destroy; override;
    class procedure Execute(ATargetDPI: Integer; AForm: TCustomForm);
    class function GetReplacement(AImageList: TCustomImageList;
      AForm: TCustomForm): TCustomImageList; overload;
    class function GetReplacement(AImageList: TCustomImageList;
      ATargetDPI: Integer; ADarkMode: Boolean): TCustomImageList; overload;
  end;

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
    class procedure Refresh(AForm: TACLForm); overload;
    class procedure Refresh; overload;
  end;

  TACLFormCorners = (afcDefault, afcRectangular, afcRounded, afcSmallRounded);

procedure FormDisableCloseButton(AHandle: HWND);
function FormSetCorners(AHandle: THandle; ACorners: TACLFormCorners): Boolean;
procedure TerminateOpenForms;
implementation

{$IFNDEF FPC}
uses
  Vcl.AppEvnts;
{$ENDIF}

type
  TCustomFormAccess = class(TCustomForm);
  TWinControlAccess = class(TWinControl);

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

procedure FormDisableCloseButton(AHandle: HWND);
begin
{$IFDEF MSWINDOWS}
  EnableMenuItem(GetSystemMenu(AHandle, False), SC_CLOSE, MF_BYCOMMAND or MF_DISABLED);
{$ELSE}
  {$MESSAGE WARN 'NotImplemented-FormDisableCloseButton'}
  raise ENotImplemented.Create('FormDisableCloseButton');
{$ENDIF}
end;

function FormSetCorners(AHandle: THandle; ACorners: TACLFormCorners): Boolean;
{$IFDEF MSWINDOWS}
const
  // Windows 11
  //   https://docs.microsoft.com/en-us/windows/apps/desktop/modernize/apply-rounded-corners
  DWMWA_WINDOW_CORNER_PREFERENCE = 33;
  //   Values (SizeOf = 4)
  DWMWCP_DEFAULT    = 0; // Let the system decide whether or not to round window corners.
  DWMWCP_DONOTROUND = 1; // Never round window corners.
  DWMWCP_ROUND      = 2; // Round the corners if appropriate.
  DWMWCP_ROUNDSMALL = 3; // Round the corners if appropriate, with a small radius.
const
  BorderCorners: array[TACLFormCorners] of Cardinal = (
    DWMWCP_DEFAULT, DWMWCP_DONOTROUND, DWMWCP_ROUND, DWMWCP_ROUNDSMALL
  );
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  Result := IsWin11OrLater and Succeeded(DwmSetWindowAttribute(AHandle,
    DWMWA_WINDOW_CORNER_PREFERENCE, @BorderCorners[ACorners], SizeOf(Cardinal)));
{$ELSE}
  Result := False;
{$ENDIF}
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

procedure TerminateOpenForms;

  procedure TerminateForm(AForm: TForm);
  begin
    if AForm <> Application.MainForm then
    begin
      AForm.Close;
      Application.ProcessMessages; // to process PostMessages;
    end;
  end;

var
  AIndex: Integer;
  APrevCount: Integer;
begin
  AIndex := 0;
  while AIndex < Screen.FormCount do
  begin
    APrevCount := Screen.FormCount;
    TerminateForm(Screen.Forms[AIndex]);
    if APrevCount = Screen.FormCount then
      Inc(AIndex);
  end;
end;

{ TACLBasicForm }

constructor TACLBasicForm.CreateNew(AOwner: TComponent; ADummy: Integer);
begin
  inherited CreateNew(AOwner, ADummy);
{$IFDEF FPC}
  InitializeNewForm;
{$ENDIF}
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

procedure TACLBasicForm.ChangeScale(M, D: Integer{$IFNDEF FPC}; IsDpiChange: Boolean{$ENDIF});
begin
  ScaleForPPI(MulDiv(FCurrentPPI, M, D));
end;

procedure TACLBasicForm.ScaleForPPI(ATargetPPI: Integer; AWindowRect: PRect);
{$IFDEF FPC}
begin
  {$MESSAGE WARN 'TACLBasicForm.ScaleForPPI'}
end;
{$ELSE}
var
  LPrevBounds: TRect;
  LPrevClientRect: TRect;
  LPrevDPI: Integer;
  LPrevParentFont: Boolean;
  LPrevScaled: Boolean;
  LScaling: TACLFormScaling;
begin
  if (ATargetPPI <> FCurrentPPI) and (ATargetPPI >= acMinDPI) and not FIScaling then
  begin
    LScaling.Start(Self);
    try
      LPrevDPI := FCurrentPPI;
      LPrevBounds := BoundsRect;
      LPrevClientRect := ClientRect;
      LPrevParentFont := ParentFont;

      LPrevScaled := Scaled;
      try
        Scaled := True; // for Delphi 11.0
        inherited ScaleForPPI(ATargetPPI);
      finally
        Scaled := LPrevScaled;
      end;

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
    DpiChanged;
  end;
end;
{$ENDIF}

procedure TACLBasicForm.ScaleForPPI(ATargetPPI: Integer);
begin
  ScaleForPPI(ATargetPPI, nil);
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
    if FLoadedClientWidth >  0 then
      inherited ClientWidth := FLoadedClientWidth;
    if FLoadedClientHeight > 0 then
      inherited ClientHeight := FLoadedClientHeight;
  finally
    EnableAlign;
  end;
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

function TACLBasicForm.GetCurrentDpi: Integer;
begin
  Result := FCurrentPPI;
end;

procedure TACLBasicForm.TakeParentFontIfNecessary;
begin
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
end;

{$IFNDEF FPC}
procedure TACLBasicForm.CMParentFontChanged(var Message: TCMParentFontChanged);
begin
  if ParentFont then
  begin
    if Message.wParam <> 0 then
      Font.Assign(Message.Font)
    else
      TakeParentFontIfNecessary;
  end;
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

{$ENDIF}

procedure TACLBasicForm.WMSetCursor(var Message: TWMSetCursor);
begin
  if not TACLControls.WMSetCursor(Self, Message) then
    inherited;
end;

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

{ TACLForm }

constructor TACLForm.Create(AOwner: TComponent);
begin
  BeforeFormCreate;
  inherited Create(AOwner);
  AfterFormCreate;
end;

constructor TACLForm.CreateDialog(AOwnerHandle: THandle; ANew: Boolean = False);
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

procedure TACLForm.CreateHandle;
begin
  inherited;
  UpdateNonClientColors;
end;

constructor TACLForm.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
begin
  BeforeFormCreate;
  inherited CreateNew(AOwner, Dummy);
  AfterFormCreate;
end;

destructor TACLForm.Destroy;
begin
  TACLRootResourceCollection.ListenerRemove(Self);
  inherited Destroy;
  FreeAndNil(FWndProcHooks[whmPostprocess]);
  FreeAndNil(FWndProcHooks[whmPreprocess]);
  MinimizeMemoryUsage;
end;

procedure TACLForm.HookWndProc(AHook: TWindowHook; AMode: TACLWindowHookMode = whmPreprocess);
begin
  if FWndProcHooks[AMode] = nil then
    FWndProcHooks[AMode] := TACLWindowHooks.Create;
  FWndProcHooks[AMode].Add(AHook);
end;

procedure TACLForm.UnhookWndProc(AHook: TWindowHook);
begin
  if FWndProcHooks[whmPostprocess] <> nil then
    FWndProcHooks[whmPostprocess].Remove(AHook);
  if FWndProcHooks[whmPreprocess] <> nil then
    FWndProcHooks[whmPreprocess].Remove(AHook);
end;

procedure TACLForm.LoadPosition(AConfig: TACLIniFile);
{$IFDEF FPC}
begin
  {$MESSAGE WARN 'NotImplemented-LoadPosition'}
  raise ENotImplemented.Create('LoadPosition');
end;
{$ELSE}

  function IsFormResizable: Boolean;
  begin
    Result := BorderStyle in [bsSizeable, bsSizeToolWin];
  end;

var
  APlacement: TWindowPlacement;
begin
  Inc(FRecreateWndLockCount);
  try
    if AConfig.ExistsKey(GetConfigSection, 'WindowRect') then
    begin
      ZeroMemory(@APlacement, SizeOf(APlacement));
      APlacement.Length := SizeOf(TWindowPlacement);
      APlacement.rcNormalPosition := AConfig.ReadRect(GetConfigSection, 'WindowRect');

      if IsFormResizable then
      begin
        APlacement.rcNormalPosition.Height := dpiApply(APlacement.rcNormalPosition.Height, FCurrentPPI);
        APlacement.rcNormalPosition.Width := dpiApply(APlacement.rcNormalPosition.Width, FCurrentPPI);
      end
      else
      begin
        APlacement.rcNormalPosition.Height := Height;
        APlacement.rcNormalPosition.Width := Width;
      end;

      SetWindowPlacement(Handle, APlacement);

      Position := poDesigned;
      DefaultMonitor := dmDesktop;
      if not BoundsRect.Contains(MonitorGetBounds(BoundsRect.TopLeft)) then
        MakeFullyVisible;
    end;

    if IsFormResizable and AConfig.ReadBool(GetConfigSection, 'WindowMaximized') then
      WindowState := wsMaximized;
  finally
    Dec(FRecreateWndLockCount);
  end;
end;
{$ENDIF}

procedure TACLForm.SavePosition(AConfig: TACLIniFile);
{$IFDEF FPC}
begin
  {$MESSAGE WARN 'NotImplemented-SavePosition'}
  raise ENotImplemented.Create('SavePosition');
end;
{$ELSE}
var
  AIsMaximized: Boolean;
  APlacement: TWindowPlacement;
begin
  APlacement.Length := SizeOf(TWindowPlacement);
  if HandleAllocated and GetWindowPlacement(Handle, APlacement) then
  begin
    APlacement.rcNormalPosition.Height := dpiRevert(APlacement.rcNormalPosition.Height, FCurrentPPI);
    APlacement.rcNormalPosition.Width := dpiRevert(APlacement.rcNormalPosition.Width, FCurrentPPI);
    case WindowState of
      wsMaximized:
        AIsMaximized := True;
      wsMinimized:
        AIsMaximized := APlacement.flags and WPF_RESTORETOMAXIMIZED = WPF_RESTORETOMAXIMIZED;
    else
      AIsMaximized := False;
    end;
    AConfig.WriteBool(GetConfigSection, 'WindowMaximized', AIsMaximized);
    AConfig.WriteRect(GetConfigSection, 'WindowRect', APlacement.rcNormalPosition);
  end;
end;
{$ENDIF}

procedure TACLForm.ShowAndActivate;
begin
  if TACLApplication.IsMinimized then
    Visible := False;
  Show;
  SetForegroundWindow(Handle);
  SetFocus;
end;

procedure TACLForm.AfterConstruction;
begin
  inherited;
  FFormCreated := True;
  ResourceChanged;
  UpdateImageLists;
end;

procedure TACLForm.AfterFormCreate;
begin
  DoubleBuffered := True;
  TACLRootResourceCollection.ListenerAdd(Self);
{$IFDEF MSWINDOWS}
  TACLFormMouseWheelHelper.CheckInstalled;
{$ENDIF}
end;

procedure TACLForm.BeforeFormCreate;
begin
  // do nothing
end;

function TACLForm.CanCloseByEscape: Boolean;
begin
  Result := False;
end;

procedure TACLForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if (Parent = nil) and (ParentWindow = 0) then
  begin
    if ShowOnTaskBar then
      Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
    if (Application.MainForm <> nil) and Application.MainForm.HandleAllocated then
      Params.WndParent := Application.MainFormHandle;
    if FOwnerHandle <> 0 then
      Params.WndParent := FOwnerHandle;
  end;
end;

procedure TACLForm.DpiChanged;
begin
  inherited;
  if FFormCreated then
    ResourceChanged;
  UpdateImageLists;
end;

procedure TACLForm.UpdateImageLists;
begin
  TACLFormImageListReplacer.Execute(FCurrentPPI, Self);
end;

procedure TACLForm.UpdateNonClientColors;
{$IFDEF MSWINDOWS}
const
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
var
  LValue: LongBool;
  LWidth: Integer;
begin
  // https://stackoverflow.com/questions/39261826/change-the-color-of-the-title-bar-caption-of-a-win32-application
  if IsWin10OrLater and HandleAllocated and (TOSVersion.Build >= 18985) then
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

function TACLForm.ShouldBeStayOnTop: Boolean;
begin
  Result := StayOnTop{$IFNDEF FPC} or TACLStayOnTopHelper.ShouldBeStayOnTop(GetOwnerWindow);{$ENDIF}
end;

procedure TACLForm.StayOnTopChanged;
begin
  // nothing
end;

procedure TACLForm.ResourceChanged(Sender: TObject; Resource: TACLResource = nil);
begin
  if FFormCreated then
    ResourceChanged;
end;

procedure TACLForm.ResourceChanged;
var
  AColor: TACLResourceColor;
begin
  if TACLRootResourceCollection.GetResource('Common.Colors.Background1', TACLResourceColor, Self, AColor) then
    Color := AColor.AsColor;
end;

function TACLForm.GetResource(const ID: string; AResourceClass: TClass; ASender: TObject = nil): TObject;
begin
  Result := TACLRootResourceCollection.GetResource(ID, AResourceClass, ASender);
end;

procedure TACLForm.ApplicationSettingsChanged(AChanges: TACLApplicationChanges);
begin
  inherited;
  if acDarkMode in AChanges then
  begin
    UpdateNonClientColors;
    UpdateImageLists;
  end;
end;

procedure TACLForm.CMDialogKey(var Message: TCMDialogKey);
begin
  case Message.CharCode of
    VK_RETURN:
      if [ssCtrl, ssAlt, ssShift] * KeyDataToShiftState(Message.KeyData) = [ssCtrl] then
      begin
        if fsModal in FormState then
        begin
          ModalResult := mrOk;
          Exit;
        end;
      end;

    VK_ESCAPE:
      if [ssCtrl, ssAlt, ssShift] * KeyDataToShiftState(Message.KeyData) = [] then
      begin
        if fsModal in FormState then
        begin
          ModalResult := mrCancel;
          Exit;
        end;
        if CanCloseByEscape then
        begin
          Close;
          Exit;
        end;
      end;
  end;
  inherited;
end;

procedure TACLForm.CMFontChanged(var Message: TMessage);
begin
  if FFormCreated then
    ResourceChanged;
  inherited;
end;

procedure TACLForm.CMRecreateWnd(var Message: TMessage);
begin
  if FRecreateWndLockCount = 0 then
    inherited;
end;

procedure TACLForm.CMShowingChanged(var Message: TCMDialogKey);
var
  AIsDefaultPositionCenter: Boolean;
begin
  AIsDefaultPositionCenter := Position in [poMainFormCenter, poOwnerFormCenter];
  inherited;
  if Visible and AIsDefaultPositionCenter then
    MakeFullyVisible;
end;

procedure TACLForm.WMEnterMenuLoop(var Msg: TMessage);
begin
  Inc(FInMenuLoop);
  inherited;
end;

procedure TACLForm.WMExitMenuLoop(var Msg: TMessage);
begin
  inherited;
  Dec(FInMenuLoop);
end;

{$IFNDEF FPC}
procedure TACLForm.WMNCActivate(var Msg: TWMNCActivate);
begin
  // Чтобы не было промаргивания при фокусировке контрола внутри попапа.
  if (FInMenuLoop <> 0) and not Msg.Active then
    Msg.Active := True;
  inherited;
end;

procedure TACLForm.WMShowWindow(var Message: TMessage);
begin
  inherited;
  TACLStayOnTopHelper.Refresh;
end;

procedure TACLForm.WMWindowPosChanged(var Message: TMessage);
begin
  inherited;
  if Visible then
    TACLStayOnTopHelper.Refresh(Self);
end;
{$ENDIF}

procedure TACLForm.WndProc(var Message: TMessage);
begin
  if not FWndProcHooks[whmPreprocess].Process(Message) then
  begin
    inherited WndProc(Message);
    if Message.Msg <> CM_RELEASE then
      FWndProcHooks[whmPostprocess].Process(Message);
  end;
end;

function TACLForm.GetConfigSection: string;
begin
  Result := Name;
end;

function TACLForm.GetShowOnTaskBar: Boolean;
begin
{$IFDEF FPC}
  Result := ShowInTaskBar = stAlways;
{$ELSE}
  Result := FShowOnTaskBar;
{$ENDIF}
end;

procedure TACLForm.SetShowOnTaskBar(AValue: Boolean);
{$IFDEF FPC}
begin
  if AValue then
    ShowInTaskBar := stAlways
  else
    ShowInTaskBar := stDefault;
{$ELSE}
var
  LExStyle: Cardinal;
begin
  if FShowOnTaskBar <> AValue then
  begin
    FShowOnTaskBar := AValue;
    if HandleAllocated and not (csDesigning in ComponentState) then
    begin
      LExStyle := GetWindowLong(Handle, GWL_EXSTYLE);
      if ShowOnTaskBar then
        LExStyle := LExStyle or WS_EX_APPWINDOW
      else
        LExStyle := LExStyle and not WS_EX_APPWINDOW;
      SetWindowLong(Handle, GWL_EXSTYLE, LExStyle);
    end;
  end;
{$ENDIF}
end;

procedure TACLForm.SetStayOnTop(AValue: Boolean);
begin
  if AValue <> FStayOnTop then
  begin
    FStayOnTop := AValue;
    TACLStayOnTopHelper.Refresh;
    StayOnTopChanged;
  end;
end;

{ TACLPopupWindow }

constructor TACLPopupWindow.Create(AOwner: TComponent);
begin
  CreateNew(AOwner);
  DoubleBuffered := True;
  Visible := False;
  BorderStyle := bsNone;
  DefaultMonitor := dmDesktop;
  Position := poDesigned;
  FormStyle := fsStayOnTop;
  InitScaling;
end;

destructor TACLPopupWindow.Destroy;
begin
  TACLMainThread.Unsubscribe(Self);
  TACLObjectLinks.Release(Self);
  inherited;
end;

procedure TACLPopupWindow.ClosePopup;
begin
  if Visible then
  try
//    KillTimer(WindowHandle, MouseTrackerId);
//    MouseCapture := False;
    Hide;
    if FOwnerFormWnd <> 0 then
      SendMessage(FOwnerFormWnd, WM_EXITMENULOOP, 0, 0);
  finally
    DoPopupClosed;
  end;
end;

procedure TACLPopupWindow.CMCancelMode(var Message: TCMCancelMode);
begin
  if Visible and not ContainsControl(Message.Sender) then
    ClosePopup;
end;

procedure TACLPopupWindow.ConstraintBounds(var R: TRect);
var
  AHeight: Integer;
  AWidth: Integer;
begin
  AHeight := Max(Constraints.MinHeight, R.Height);
  AWidth := Max(Constraints.MinWidth, R.Width);
  if AutoSize then
  begin
    AHeight := Max(AHeight, Height);
    AWidth := Max(AWidth, Width);
  end;
  if Constraints.MaxHeight > 0 then
    AHeight := Min(AHeight, Constraints.MaxHeight);
  if Constraints.MaxWidth > 0 then
    AWidth := Min(AWidth, Constraints.MaxWidth);
  R.Right := R.Left + AWidth;
  R.Bottom := R.Top + AHeight;
end;

procedure TACLPopupWindow.CreateParams(var Params: TCreateParams);
begin
  inherited;
  if Owner is TWinControl then
    Params.WndParent := TWinControl(Owner).Handle;
  Params.WindowClass.Style := Params.WindowClass.Style or CS_HREDRAW or CS_VREDRAW or CS_DROPSHADOW;
end;

procedure TACLPopupWindow.DoPopup;
begin
  CallNotifyEvent(Self, OnPopup);
end;

procedure TACLPopupWindow.DoPopupClosed;
begin
  CallNotifyEvent(Self, OnClosePopup);
end;

procedure TACLPopupWindow.InitPopup;
begin
  SendCancelMode(Self);
  InitScaling;
  DoPopup;
  if AutoSize then
    HandleNeeded;
  AdjustSize;
end;

procedure TACLPopupWindow.InitScaling;
var
  LSourceDPI: IACLCurrentDpi;
begin
  Scaled := True;
  if Supports(Owner, IACLCurrentDpi, LSourceDPI) then
    ScaleForPPI(LSourceDPI.GetCurrentDpi);
  if Owner is TControl then
    Font := TWinControlAccess(Owner).Font;
  Scaled := False; // manual control
end;

function TACLPopupWindow.IsMouseInControl: Boolean;
begin
  Result := PtInRect(Rect(0, 0, Width, Height), CalcCursorPos);
end;

{procedure TACLPopupWindow.MouseTracking;
var
  LCapture: TControl;
begin
  if IsMouseInControl then
    MouseCapture := False
  else
  begin
    LCapture := GetCaptureControl;
    if LCapture = nil then
      MouseCapture := True
    else
      if (LCapture <> Self) and not ContainsControl(LCapture) then
        ClosePopup;
  end;
end;}

procedure TACLPopupWindow.Popup(R: TRect);
begin
  InitPopup;
  ConstraintBounds(R);
  ShowPopup(MonitorAlignPopupWindow(R));
end;

procedure TACLPopupWindow.PopupUnderControl(
  const AControlBoundsOnScreen: TRect; AAlignment: TAlignment);

  function CalculateOffset(const ARect: TRect): TPoint;
  begin
    if AAlignment <> taLeftJustify then
    begin
      Result.X := AControlBoundsOnScreen.Width - ARect.Width;
      if AAlignment = taCenter then
        Result.X := Result.X div 2;
    end
    else
      Result.X := 0;

    Result.X := AControlBoundsOnScreen.Left + Result.X;
    Result.Y := AControlBoundsOnScreen.Top + AControlBoundsOnScreen.Height + 2;
  end;

var
  ARect: TRect;
  AWorkareaRect: TRect;
begin
  InitPopup;

  ARect := TRect.Create(AControlBoundsOnScreen.Size);
  ARect.Height := Height;
  ConstraintBounds(ARect);
  ARect.Offset(CalculateOffset(ARect));

  AWorkareaRect := MonitorGet(ARect.CenterPoint).WorkareaRect;
  if ARect.Bottom > AWorkareaRect.Bottom then
  begin
    ARect.Offset(0, -(ARect.Height + AControlBoundsOnScreen.Height + 4));
    ARect.Top := Max(ARect.Top, AWorkareaRect.Top);
  end;
  if ARect.Left < AWorkareaRect.Left then
    ARect.Offset(AWorkareaRect.Left - ARect.Left, 0);
  if ARect.Right > AWorkareaRect.Right then
    ARect.Offset(AWorkareaRect.Right - ARect.Right, 0);

  ShowPopup(ARect);
end;

procedure TACLPopupWindow.ShowPopup(const R: TRect);
begin
  BoundsRect := R;

  if Screen.ActiveCustomForm <> nil then
    FOwnerFormWnd := Screen.ActiveCustomForm.Handle
  else
    FOwnerFormWnd := 0;

  if FOwnerFormWnd <> 0 then
    SendMessage(FOwnerFormWnd, WM_ENTERMENULOOP, 0, 0);

//  SetTimer(Handle, MouseTrackerId, 1, nil);
  Visible := True;
end;

procedure TACLPopupWindow.WndProc(var Message: TMessage);
begin
  if Visible then
    case Message.Msg of
      WM_GETDLGCODE:
        Message.Result := DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTALLKEYS or DLGC_WANTCHARS;

//      WM_MOUSEACTIVATE:
//        begin
//          Message.Result := MA_NOACTIVATE;
//          Exit;
//        end;
//
//      WM_LBUTTONDBLCLK, WM_MBUTTONDBLCLK, WM_RBUTTONDBLCLK,
//      WM_LBUTTONDOWN, WM_MBUTTONDOWN, WM_RBUTTONDOWN:
//        if not IsMouseInControl then
//          ClosePopup;
//
//      WM_TIMER:
//        if TWMTimer(Message).TimerID = MouseTrackerId then
//          MouseTracking;

    {$IFDEF MSWINDOWS}
      WM_ACTIVATEAPP:
        ClosePopup;
      WM_CONTEXTMENU, CM_MOUSEWHEEL:
        Exit;
      WM_ACTIVATE:
        with TWMActivate(Message) do
          if Active = WA_INACTIVE then
            TACLMainThread.RunPostponed(ClosePopup, Self)
          else // c нашей формой, по идее, это не нужно:
            SendMessage(ActiveWindow, WM_NCACTIVATE, WPARAM(True), 0);
    {$ENDIF}

      WM_KEYDOWN, CM_DIALOGKEY, CM_WANTSPECIALKEY:
        if TWMKey(Message).CharCode = VK_ESCAPE then
        begin
          ClosePopup;
          TWMKey(Message).CharCode := 0;
          TWMKey(Message).Result := 1;
          Exit;
        end;
    end;
  inherited;
end;

{ TACLLocalizableForm }

procedure TACLLocalizableForm.AfterConstruction;
begin
  inherited AfterConstruction;
  LangChange;
end;

function TACLLocalizableForm.GetConfigSection: string;
begin
  Result := GetLangSection; // backward compatibility
end;

function TACLLocalizableForm.GetLangSection: string;
begin
  Result := Name;
end;

procedure TACLLocalizableForm.LangChange;
begin
  Caption := LangFile.ReadString(GetLangSection, 'Caption', Caption);
  LangApplyTo(GetLangSection, Self);
end;

function TACLLocalizableForm.LangValue(const AKey: string): string;
begin
  Result := LangGet(GetLangSection, AKey);
end;

function TACLLocalizableForm.LangValue(const AKey: string; APartIndex: Integer): string;
begin
  Result := LangExtractPart(LangValue(AKey), APartIndex);
end;

procedure TACLLocalizableForm.WMLANG(var Msg: TMessage);
begin
  LangChange;
end;

{ TACLFormImageListReplacer }

constructor TACLFormImageListReplacer.Create(ATargetDPI: Integer; ADarkMode: Boolean);
begin
  FDarkMode := ADarkMode;
  FTargetDPI := ATargetDPI;
  FReplacementCache := TACLObjectDictionary.Create;
end;

destructor TACLFormImageListReplacer.Destroy;
begin
  FreeAndNil(FReplacementCache);
  inherited Destroy;
end;

class procedure TACLFormImageListReplacer.Execute(ATargetDPI: Integer; AForm: TCustomForm);
begin
  with TACLFormImageListReplacer.Create(ATargetDPI, TACLApplication.IsDarkMode) do
  try
    UpdateImageLists(AForm);
  finally
    Free;
  end;
end;

class function TACLFormImageListReplacer.GetReplacement(AImageList: TCustomImageList; AForm: TCustomForm): TCustomImageList;
begin
  Result := GetReplacement(AImageList, TCustomFormAccess(AForm).FCurrentPPI, TACLApplication.IsDarkMode);
end;

class function TACLFormImageListReplacer.GetReplacement(
  AImageList: TCustomImageList; ATargetDPI: Integer; ADarkMode: Boolean): TCustomImageList;

  function CheckReference(const AReference: TComponent; var AResult: TCustomImageList): Boolean;
  begin
    Result := AReference is TCustomImageList;
    if Result then
      AResult := TCustomImageList(AReference);
  end;

  function TryFind(const ABaseName: TComponentName; ATargetDPI: Integer; var AResult: TCustomImageList): Boolean;
  begin
    Result := False;
    if ADarkMode then
      Result := CheckReference(AImageList.Owner.FindComponent(GenerateName(ABaseName, DarkModeSuffix, ATargetDPI)), AResult);
    if not Result then
      Result := CheckReference(AImageList.Owner.FindComponent(GenerateName(ABaseName, EmptyStr, ATargetDPI)), AResult);
    if not Result and (ATargetDPI = acDefaultDPI) then
      Result := CheckReference(AImageList.Owner.FindComponent(ABaseName), AResult);
  end;

var
  ABaseName: TComponentName;
  I: Integer;
begin
  Result := AImageList;

  ABaseName := GetBaseImageListName(AImageList.Name);
  if (ABaseName <> '') and (AImageList.Owner <> nil) and not TryFind(ABaseName, ATargetDPI, Result) then
  begin
    for I := High(acDefaultDPIValues) downto Low(acDefaultDPIValues) do
    begin
      if (acDefaultDPIValues[I] < ATargetDPI) and TryFind(ABaseName, acDefaultDPIValues[I], Result) then
        Break;
    end;
  end;
end;

procedure TACLFormImageListReplacer.UpdateImageList(AInstance: TObject; APropInfo: PPropInfo; APropValue: TObject);
var
  ANewValue: TObject;
begin
  if not FReplacementCache.TryGetValue(APropValue, ANewValue) then
  begin
    ANewValue := GetReplacement(TCustomImageList(APropValue), FTargetDPI, FDarkMode);
    FReplacementCache.Add(APropValue, ANewValue);
  end;
  if APropValue <> ANewValue then
    SetObjectProp(AInstance, APropInfo, ANewValue);
end;

procedure TACLFormImageListReplacer.UpdateImageListProperties(APersistent: TPersistent);

  function EnumProperties(AObject: TObject; out AList: PPropList; out ACount: Integer): Boolean;
  begin
    Result := False;
    if AObject <> nil then
    begin
      ACount := GetTypeData(AObject.ClassInfo)^.PropCount;
      Result := ACount > 0;
      if Result then
      begin
        AList := AllocMem(ACount * SizeOf(Pointer));
        GetPropInfos(AObject.ClassInfo, AList);
      end;
    end;
  end;

var
  APropClass: TClass;
  AProperties: PPropList;
  APropertyCount: Integer;
  APropInfo: PPropInfo;
  APropValue: TObject;
  I: Integer;
begin
  if EnumProperties(APersistent, AProperties, APropertyCount) then
  try
    for I := 0 to APropertyCount - 1 do
    begin
      APropInfo := AProperties^[I];
      if APropInfo.PropType^.Kind = tkClass then
      begin
        APropClass := GetObjectPropClass(APropInfo);
        if APropClass.InheritsFrom(TComponent) then
        begin
          if APropClass.InheritsFrom(TCustomImageList) then
          begin
            APropValue := GetObjectProp(APersistent, APropInfo);
            if APropValue <> nil then
              UpdateImageList(APersistent, APropInfo, APropValue);
          end;
        end
        else
          if APropClass.InheritsFrom(TPersistent) then
          begin
            APropValue := GetObjectProp(APersistent, APropInfo);
            if APropValue <> nil then
              UpdateImageListProperties(TPersistent(APropValue));
          end;
      end;
    end;
  finally
    FreeMem(AProperties);
  end;
end;

procedure TACLFormImageListReplacer.UpdateImageLists(AForm: TCustomForm);
var
  I: Integer;
begin
  for I := 0 to AForm.ComponentCount - 1 do
    UpdateImageListProperties(AForm.Components[I]);
end;

class function TACLFormImageListReplacer.GenerateName(
  const ABaseName, ASuffix: string; ATargetDPI: Integer): TComponentName;
begin
  Result := ABaseName + ASuffix + IntToStr(MulDiv(100, ATargetDPI, acDefaultDPI));
end;

class function TACLFormImageListReplacer.GetBaseImageListName(const AName: TComponentName): TComponentName;
var
  ALength: Integer;
begin
  Result := AName;
  ALength := Length(Result);
  while (ALength > 0) and CharInSet(Result[ALength], ['0'..'9']) do
    Dec(ALength);
  SetLength(Result, ALength);
  if acEndsWith(Result, DarkModeSuffix) then
    SetLength(Result, ALength - Length(DarkModeSuffix));
end;

{ TACLStayOnTopHelper }

class destructor TACLStayOnTopHelper.Destroy;
begin
  FreeAndNil(FEvents);
end;

class procedure TACLStayOnTopHelper.Refresh(AForm: TACLForm);
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
    if AForm is TACLForm then
      Refresh(TACLForm(AForm));
  end;
end;

class function TACLStayOnTopHelper.ShouldBeStayOnTop(AHandle: HWND): Boolean;
var
  AControl: TWinControl;
begin
  AControl := FindControl(AHandle);
  Result := (AControl is TACLForm) and TACLForm(AControl).ShouldBeStayOnTop;
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
  RedrawLocked := IsWinVistaOrLater and IsWindowVisible(AForm.Handle);
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
  if (FHook = 0) and not IsWin10OrLater then
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

end.
