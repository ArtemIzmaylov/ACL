{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*               Form Classes                *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Forms;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.CommDlg,
  Winapi.ActiveX,
  // System
  System.Types,
  System.SysUtils,
  System.Classes,
  System.Contnrs,
  System.TypInfo,
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  Vcl.ImgList,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.ActnList,
  Vcl.Menus,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Math,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Threading,
  ACL.UI.Application,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Desktop,
  ACL.Utils.DPIAware,
  ACL.Utils.FileSystem,
  ACL.Utils.Registry,
  ACL.Utils.Strings;

const
  CM_SCALECHANGING = $BF00;
  CM_SCALECHANGED  = $BF01;

type

  { TACLBasicForm }

  TACLBasicForm = class(TForm, IACLApplicationListener)
  strict private
    procedure ApplyColorSchema;
    procedure WMAppCommand(var Message: TMessage); message WM_APPCOMMAND;
  protected
    // IACLApplicationListener
    procedure IACLApplicationListener.Changed = ApplicationSettingsChanged;
    procedure ApplicationSettingsChanged(AChanges: TACLApplicationChanges); virtual;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

  { TACLBasicScalableForm }

  TACLBasicScalableForm = class(TACLBasicForm, IACLCurrentDpi)
  strict private
    FLoadedClientHeight: Integer;
    FLoadedClientWidth: Integer;
    FParentFontLocked: Boolean;

    procedure SetClientHeight(Value: Integer);
    procedure SetClientWidth(Value: Integer);
    procedure TakeParentFontIfNecessary;
    procedure CMParentFontChanged(var Message: TCMParentFontChanged); message CM_PARENTFONTCHANGED;
  {$IFNDEF DELPHI102TOKYO}
    procedure WMNCCreate(var Message: TWMNCCreate); message WM_NCCREATE;
  {$ENDIF}
    procedure WMDPIChanged(var Message: TMessage); message WM_DPICHANGED;
    procedure WMSettingsChanged(var Message: TWMSettingChange); message WM_SETTINGCHANGE;
    // IACLCurrentDpi
    function GetCurrentDpi: Integer;
  protected
    procedure ApplicationSettingsChanged(AChanges: TACLApplicationChanges); override;
    procedure ChangeScale(M, D: Integer); overload; override; final;
    procedure ChangeScale(M, D: Integer; IsDpiChange: Boolean); override;
    procedure DoShow; override;
    procedure DpiChanged; virtual;
    procedure InitializeNewForm; override;
    function IsDesigning: Boolean;
    procedure Loaded; override;
    procedure ReadState(Reader: TReader); override;
    procedure ScaleControlsForDpi(NewPPI: Integer); override;
    procedure SetParent(AParent: TWinControl); override;
    procedure SetPixelsPerInch(Value: Integer); {$IFDEF DELPHI110ALEXANDRIA}override;{$ENDIF}
  public
    procedure ScaleForCurrentDPI; override;
    procedure ScaleForPPI(ATargetDPI: Integer; AWindowRect: PRect); reintroduce; overload; virtual;
    procedure ScaleForPPI(NewPPI: Integer); overload; override; final;
    property CurrentDpi: Integer read FCurrentPPI;
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

  TACLForm = class(TACLBasicScalableForm,
    IACLResourceChangeListener,
    IACLResourceProvider)
  strict private
    FFormCreated: Boolean;
    FShowOnTaskBar: Boolean;
    FStayOnTop: Boolean;
    FWndProcHooks: array[TACLWindowHookMode] of TACLWindowHooks;

    procedure SetShowOnTaskBar(AValue: Boolean);
    procedure SetStayOnTop(AValue: Boolean);
  protected
    FOwnerHandle: THandle;
    FRecreateWndLockCount: Integer;

    procedure AfterFormCreate; virtual;
    procedure BeforeFormCreate; virtual;
    function CanCloseByEscape: Boolean; virtual;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DpiChanged; override;
    procedure UpdateImageLists; virtual;

    // Config
    function GetConfigSection: UnicodeString; virtual;

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
    procedure WMShowWindow(var Message: TWMShowWindow); message WM_SHOWWINDOW;
    procedure WMWindowPosChanged(var Message: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateDialog(AOwnerHandle: THandle; ANew: Boolean = False); virtual;
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    function IsDestroying: Boolean; inline;
    //
    procedure HookWndProc(AHook: TWindowHook; AMode: TACLWindowHookMode = whmPreprocess);
    procedure UnhookWndProc(AHook: TWindowHook);
    //
    procedure LoadPosition(AConfig: TACLIniFile); virtual;
    procedure SavePosition(AConfig: TACLIniFile); virtual;
    procedure ShowAndActivate; virtual;
  published
    property Color stored False; // Color synchronizes with resources (ref. to ResourceChanged)
    property DoubleBuffered default True;
    property ShowOnTaskBar: Boolean read FShowOnTaskBar write SetShowOnTaskBar default False;
    property StayOnTop: Boolean read FStayOnTop write SetStayOnTop default False;
  end;

  { TACLCustomPopupForm }

  TACLCustomPopupFormClass = class of TACLCustomPopupForm;
  TACLCustomPopupForm = class(TACLForm)
  strict private
    FPopuped: Boolean;
    FPrevHandle: THandle;

    FOnClosePopup: TNotifyEvent;
    FOnPopup: TNotifyEvent;

    procedure ShowPopup(const R: TRect);
  protected
    FUseOwnMessagesLoop: Boolean;

    procedure CreateParams(var Params: TCreateParams); override;
    procedure Deactivate; override;
    procedure WndProc(var Message: TMessage); override;

    procedure DoClosePopup; virtual;
    procedure DoPopup; virtual;
    procedure Initialize; virtual;
    procedure ValidatePopupFormBounds(var R: TRect); virtual;

    procedure CMDialogKey(var Message: TWMKey); override;
    procedure CMWantSpecialKey(var Message: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Popup(R: TRect); virtual;
    procedure PopupClose;
    procedure PopupUnderControl(Control: TControl; Alignment: TAlignment = taLeftJustify); overload;
    procedure PopupUnderControl(const AControlBounds: TRect; const AControlOrigin: TPoint;
      AAlignment: TAlignment = taLeftJustify; ATargetDpi: Integer = 0); overload;
    //
    property Popuped: Boolean read FPopuped;
    //
    property OnClosePopup: TNotifyEvent read FOnClosePopup write FOnClosePopup;
    property OnPopup: TNotifyEvent read FOnPopup write FOnPopup;
  end;

  { TACLLocalizableForm }

  TACLLocalizableForm = class(TACLForm,
    IACLLocalizableComponentRoot)
  strict private
    procedure WMLANG(var Msg: TMessage); message WM_ACL_LANG;
  protected
    function GetConfigSection: UnicodeString; override;
    // IACLLocalizableComponentRoot
    function GetLangSection: UnicodeString; virtual;
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
    class function GetReplacement(AImageList: TCustomImageList; AForm: TCustomForm): TCustomImageList; overload;
    class function GetReplacement(AImageList: TCustomImageList; ATargetDPI: Integer; ADarkMode: Boolean): TCustomImageList; overload;
  end;

  { TACLStayOnTopHelper }

  TACLStayOnTopHelper = class
  strict private
    class procedure AppEventsModalHandler(Sender: TObject);
    class procedure CheckForApplicationEvents;
    class function StayOnTopAvailable: Boolean;
  public
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

uses
  Winapi.DwmApi,
  // System
  System.Math,
  System.Character,
  // Vcl
  Vcl.AppEvnts,
  // ACL.UI
  ACL.UI.Controls.BaseControls;

const
  // Windows 11
  //   https://docs.microsoft.com/en-us/windows/apps/desktop/modernize/apply-rounded-corners
  DWMWA_WINDOW_CORNER_PREFERENCE = 33;
  //   Values (SizeOf = 4)
  DWMWCP_DEFAULT    = 0; // Let the system decide whether or not to round window corners.
  DWMWCP_DONOTROUND = 1; // Never round window corners.
  DWMWCP_ROUND      = 2; // Round the corners if appropriate.
  DWMWCP_ROUNDSMALL = 3; // Round the corners if appropriate, with a small radius.

type
  TApplicationAccess = class(TApplication);
  TCustomFormAccess = class(TCustomForm);
  TScrollingWinControlAccess = class(TScrollingWinControl);
  TWinControlAccess = class(TWinControl);

  TEnableNonClientDpiScalingProc = function (AHandle: HWND): LongBool; stdcall;

  { TACLFormScalingHelper }

  TACLFormScalingHelper = class
  strict private type
  {$REGION 'Internal Types'}
    TState = class
    protected
      LockedControls: TComponentList;
      RedrawLocked: Boolean;
    end;
  {$ENDREGION}
  strict private
    class var FScalingForms: TList;

    class procedure PopulateControls(AControl: TControl; ATargetList: TComponentList);
    class procedure ScalingBegin(AForm: TCustomFormAccess; out AState: TState);
    class procedure ScalingEnd(AForm: TCustomFormAccess; AState: TState);
  public
    class function GetCurrentPPI(AForm: TCustomForm): Integer;
    class function IsScaleChanging(AForm: TCustomForm): Boolean;
    class procedure ScaleForPPI(AForm: TCustomFormAccess; ATargetDPI: Integer; AWindowRect: PRect = nil);
  end;

  { TACLFormMouseWheelHelper }

  TACLFormMouseWheelHelper = class
  strict private
    class var FHook: HHOOK;

    class function MouseHook(Code: Integer; wParam: WParam; lParam: LParam): LRESULT; stdcall; static;
  public
    class destructor Destroy;
    class procedure CheckInstalled;
  end;

var
  FApplicationEvents: TApplicationEvents;
  FEnableNonClientDpiScaling: TEnableNonClientDpiScalingProc;

procedure FormDisableCloseButton(AHandle: HWND);
begin
  EnableMenuItem(GetSystemMenu(AHandle, False), SC_CLOSE, MF_BYCOMMAND or MF_DISABLED);
end;

function FormSetCorners(AHandle: THandle; ACorners: TACLFormCorners): Boolean;
const
  BorderCorners: array[TACLFormCorners] of Cardinal = (
    DWMWCP_DEFAULT, DWMWCP_DONOTROUND, DWMWCP_ROUND, DWMWCP_ROUNDSMALL
  );
begin
  Result := IsWin11OrLater and Succeeded(DwmSetWindowAttribute(AHandle,
    DWMWA_WINDOW_CORNER_PREFERENCE, @BorderCorners[ACorners], SizeOf(Cardinal)));
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

procedure TACLBasicForm.ApplicationSettingsChanged(AChanges: TACLApplicationChanges);
begin
  if acColorSchema in AChanges then
    ApplyColorSchema;
end;

procedure TACLBasicForm.ApplyColorSchema;
var
  I: Integer;
begin
  for I := 0 to ComponentCount - 1 do
    acApplyColorSchema(Components[I], TACLApplication.ColorSchema);
end;

procedure TACLBasicForm.WMAppCommand(var Message: TMessage);
begin
  if Message.Result = 0 then
    Message.Result := SendMessage(Application.Handle, Message.Msg, Message.WParam, Message.LParam);
end;

{ TACLBasicScalableForm }

procedure TACLBasicScalableForm.ScaleForPPI(ATargetDPI: Integer; AWindowRect: PRect);
begin
  TACLFormScalingHelper.ScaleForPPI(TCustomFormAccess(Self), ATargetDPI, AWindowRect);
end;

procedure TACLBasicScalableForm.ScaleForPPI(NewPPI: Integer);
{$IFDEF DELPHI110ALEXANDRIA}
var
  APrevScaled: Boolean;
{$ENDIF}
begin
  if TACLFormScalingHelper.IsScaleChanging(Self) then
  begin
  {$IFDEF DELPHI110ALEXANDRIA}
    APrevScaled := Scaled;
    try
      Scaled := True;
      inherited ScaleForPPI(NewPPI);
    finally
      Scaled := APrevScaled;
    end;
  {$ELSE}
    inherited ScaleForPPI(NewPPI);
  {$ENDIF}
    TakeParentFontIfNecessary;
  end
  else
    ScaleForPPI(NewPPI, nil);
end;

procedure TACLBasicScalableForm.ChangeScale(M, D: Integer);
begin
  ChangeScale(M, D, False);
end;

procedure TACLBasicScalableForm.ChangeScale(M, D: Integer; IsDpiChange: Boolean);
var
  AState: TObject;
begin
  TACLControlsHelper.ScaleChanging(Self, AState);
  try
    inherited ChangeScale(M, D, IsDpiChange);
    PixelsPerInch := MulDiv(PixelsPerInch, M, D);
    TakeParentFontIfNecessary;
    DpiChanged;
  finally
    TACLControlsHelper.ScaleChanged(Self, AState);
  end;
end;

procedure TACLBasicScalableForm.DoShow;
begin
  inherited DoShow;
  ScaleForCurrentDpi; //#AI: for dynamically created forms
end;

procedure TACLBasicScalableForm.InitializeNewForm;
begin
  //#AI:
  // В TCustomForm.InitializeNewForm сначала выставляются дефолтные размеры формы, а уже потом Visible в False.
  // На Wine зз-за этого форма на секунду становится видимой в нулевых координатах.
  Visible := False;
  inherited;
  FCurrentPPI := TACLFormScalingHelper.GetCurrentPPI(Self);
  if not ParentFont then
    Font.Height := acGetFontHeight(FCurrentPPI, Font.Size);
end;

function TACLBasicScalableForm.IsDesigning: Boolean;
begin
  Result := csDesigning in ComponentState;
end;

procedure TACLBasicScalableForm.Loaded;
begin
  inherited;
  TakeParentFontIfNecessary;
end;

procedure TACLBasicScalableForm.DpiChanged;
begin
  // do nothing
end;

procedure TACLBasicScalableForm.SetParent(AParent: TWinControl);
begin
  inherited SetParent(AParent);
  TACLControlsHelper.UpdateDpiOnParentChange(Self);
end;

procedure TACLBasicScalableForm.ScaleControlsForDpi(NewPPI: Integer);
begin
  DisableAlign;
  try
    inherited ScaleControlsForDpi(NewPPI);
  finally
    EnableAlign;
  end;
end;

procedure TACLBasicScalableForm.ScaleForCurrentDPI;
begin
  DisableAlign;
  try
    if Scaled and not IsDesigning and (Parent = nil) then
      ScaleForPPI(TACLApplication.GetTargetDPI(Self));
    ScalingFlags := [];
    Perform(CM_PARENTBIDIMODECHANGED, 0, 0);
  finally
    EnableAlign;
  end;
end;

procedure TACLBasicScalableForm.ReadState(Reader: TReader);

  procedure WinControlReadState;
  var
    AProc: procedure (Reader: TReader) of object;
  begin
    TMethod(AProc).Code := @TScrollingWinControlAccess.ReadState;
    TMethod(AProc).Data := Self;
    AProc(Reader);
  end;

begin
{$IFNDEF DELPHI110ALEXANDRIA}
  if ClassParent = TForm then
    OldCreateOrder := not ModuleIsCpp;
{$ENDIF}

  DisableAlign;
  try
    FLoadedClientHeight := 0;
    FLoadedClientWidth := 0;

    WinControlReadState;

    if FLoadedClientWidth >  0 then
      inherited ClientWidth := FLoadedClientWidth;
    if FLoadedClientHeight > 0 then
      inherited ClientHeight := FLoadedClientHeight;
  finally
    EnableAlign;
  end;
end;

procedure TACLBasicScalableForm.ApplicationSettingsChanged(AChanges: TACLApplicationChanges);
begin
  if acScalingMode in AChanges then
  begin
    if Scaled and not IsDesigning then
      ScaleForCurrentDpi;
  end;
  inherited;
end;

procedure TACLBasicScalableForm.SetClientHeight(Value: Integer);
begin
  if csReadingState in ControlState then
  begin
    FLoadedClientHeight := Value;
    ScalingFlags := ScalingFlags + [sfHeight];
  end
  else
    inherited ClientHeight := Value;
end;

procedure TACLBasicScalableForm.SetClientWidth(Value: Integer);
begin
  if csReadingState in ControlState then
  begin
    FLoadedClientWidth := Value;
    ScalingFlags := ScalingFlags + [sfWidth];
  end
  else
    inherited ClientWidth := Value;
end;

procedure TACLBasicScalableForm.SetPixelsPerInch(Value: Integer);
begin
  if csReadingState in ControlState then
    FCurrentPPI := Value;
{$IFDEF DELPHI110ALEXANDRIA}
  inherited;
{$ELSE}
  inherited PixelsPerInch := Value;
{$ENDIF}
end;

function TACLBasicScalableForm.GetCurrentDpi: Integer;
begin
  Result := FCurrentPPI;
end;

procedure TACLBasicScalableForm.TakeParentFontIfNecessary;
begin
  // Workaround for
  // The "TForm.ParentFont = true causes scaling error with HighDPI" issue
  // https://quality.embarcadero.com/browse/RSP-30677
  if ParentFont and not FParentFontLocked then
  begin
    FParentFontLocked := True;
    try
      if (Parent <> nil) and not IsDesigning then
        Font := TWinControlAccess(Parent).Font
      else
        acAssignFont(Font, Application.DefaultFont, FCurrentPPI, acGetSystemDpi);

      ParentFont := True;
    finally
      FParentFontLocked := False;
    end;
  end;
end;

procedure TACLBasicScalableForm.CMParentFontChanged(var Message: TCMParentFontChanged);
begin
  if ParentFont then
  begin
    if Message.wParam <> 0 then
      Font.Assign(Message.Font)
    else
      TakeParentFontIfNecessary;
  end;
end;

{$IFNDEF DELPHI102TOKYO}
procedure TACLBasicScalableForm.WMNCCreate(var Message: TWMNCCreate);
begin
  inherited;
  if Scaled and IsWinVistaOrLater and IsProcessDPIAware then
  begin
    if Assigned(FEnableNonClientDpiScaling) then
      FEnableNonClientDpiScaling(WindowHandle);
  end;
end;
{$ENDIF}

procedure TACLBasicScalableForm.WMDPIChanged(var Message: TMessage);
var
  ATargetDPI: Integer;
  APrevPixelsPerInch: Integer;
begin
  if [csDesigning, csLoading] * ComponentState = [] then
  begin
    ATargetDPI := LoWord(Message.WParam);
    if (ATargetDPI = 0) or not Scaled then
    begin
      if (Application.MainForm <> nil) and Application.MainForm.Scaled then
        PixelsPerInch := Application.MainForm.PixelsPerInch
      else
        Exit;
    end;

    if (ATargetDPI <> TACLFormScalingHelper.GetCurrentPPI(Self)) and Scaled and (TACLApplication.TargetDPI = 0) then
    begin
      if Assigned(OnBeforeMonitorDpiChanged) then
        OnBeforeMonitorDpiChanged(Self, PixelsPerInch, ATargetDPI);
      APrevPixelsPerInch := PixelsPerInch;
      ScaleForPPI(ATargetDPI, PRect(Message.LParam));
      if Assigned(OnAfterMonitorDpiChanged) then
        OnAfterMonitorDpiChanged(Self, APrevPixelsPerInch, PixelsPerInch);
    end;
    Message.Result := 0;
  end;
end;

procedure TACLBasicScalableForm.WMSettingsChanged(var Message: TWMSettingChange);
begin
  inherited;
  FSystemDpiCache := 0;
  if (Message.Section <> nil) and (Message.Section = 'ImmersiveColorSet') then
    TACLApplication.UpdateColorSet;
end;

{ TACLWindowHooks }

function TACLWindowHooks.Process(var Message: TMessage): Boolean;
begin
  if Self = nil then
    Exit(False);
  for var I := Count - 1 downto 0 do
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

function TACLForm.IsDestroying: Boolean;
begin
  Result := csDestroying in ComponentState;
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
        APlacement.rcNormalPosition := acRectSetSize(APlacement.rcNormalPosition, Width, Height);

      SetWindowPlacement(Handle, APlacement);

      Position := poDesigned;
      DefaultMonitor := dmDesktop;
      if not acRectInRect(BoundsRect, MonitorGetBounds(BoundsRect.TopLeft)) then
        MakeFullyVisible;
    end;

    if IsFormResizable and AConfig.ReadBool(GetConfigSection, 'WindowMaximized') then
      WindowState := wsMaximized;
  finally
    Dec(FRecreateWndLockCount);
  end;
end;

procedure TACLForm.SavePosition(AConfig: TACLIniFile);
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
  TACLFormMouseWheelHelper.CheckInstalled;
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
  if FFormCreated then
    ResourceChanged;
  UpdateImageLists;
end;

procedure TACLForm.UpdateImageLists;
begin
  TACLFormImageListReplacer.Execute(FCurrentPPI, Self);
end;

function TACLForm.ShouldBeStayOnTop: Boolean;
begin
  Result := StayOnTop or TACLStayOnTopHelper.ShouldBeStayOnTop(GetOwnerWindow);
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
    UpdateImageLists;
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

procedure TACLForm.WMShowWindow(var Message: TWMShowWindow);
begin
  inherited;
  TACLStayOnTopHelper.Refresh;
end;

procedure TACLForm.WMWindowPosChanged(var Message: TWMWindowPosChanged);
begin
  inherited;
  if Visible then
    TACLStayOnTopHelper.Refresh(Self);
end;

procedure TACLForm.WndProc(var Message: TMessage);
begin
  if not FWndProcHooks[whmPreprocess].Process(Message) then
  begin
    if not TACLControlsHelper.ProcessMessage(Self, Message) then
      inherited WndProc(Message);
    if Message.Msg <> CM_RELEASE then
      FWndProcHooks[whmPostprocess].Process(Message);
  end;
end;

function TACLForm.GetConfigSection: UnicodeString;
begin
  Result := Name;
end;

procedure TACLForm.SetShowOnTaskBar(AValue: Boolean);
var
  AExStyle: Cardinal;
begin
  if FShowOnTaskBar <> AValue then
  begin
    FShowOnTaskBar := AValue;
    if HandleAllocated and not IsDesigning then
    begin
      AExStyle := GetWindowLong(Handle, GWL_EXSTYLE);

      if ShowOnTaskBar then
        AExStyle := AExStyle or WS_EX_APPWINDOW
      else
        AExStyle := AExStyle and not WS_EX_APPWINDOW;

      SetWindowLong(Handle, GWL_EXSTYLE, AExStyle);
    end;
  end;
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

{ TACLCustomPopupForm }

constructor TACLCustomPopupForm.Create(AOwner: TComponent);
begin
  if AOwner is TWinControl then
    FOwnerHandle := TWinControl(AOwner).Handle;
  CreateNew(AOwner);
  Initialize;
end;

destructor TACLCustomPopupForm.Destroy;
begin
  TACLMainThread.Unsubscribe(Self);
  TACLObjectLinks.Release(Self);
  inherited Destroy;
end;

procedure TACLCustomPopupForm.Popup(R: TRect);
begin
  DoPopup;
  if AutoSize then
    HandleNeeded;
  AdjustSize;
  ValidatePopupFormBounds(R);
  ShowPopup(MonitorAlignPopupWindow(R));
end;

procedure TACLCustomPopupForm.PopupClose;
begin
  if FPopuped then
  begin
    FPopuped := False;
    Hide;
    DoClosePopup;
  end;
end;

procedure TACLCustomPopupForm.PopupUnderControl(Control: TControl; Alignment: TAlignment = taLeftJustify);
begin
  PopupUnderControl(Control.BoundsRect, Control.ClientToScreen(NullPoint), Alignment, acGetCurrentDpi(Control));
end;

procedure TACLCustomPopupForm.PopupUnderControl(const AControlBounds: TRect;
  const AControlOrigin: TPoint; AAlignment: TAlignment = taLeftJustify; ATargetDpi: Integer = 0);

  function CalculateOffset(const ARect: TRect): TPoint;
  begin
    if AAlignment <> taLeftJustify then
    begin
      Result.X := acRectWidth(AControlBounds) - acRectWidth(ARect);
      if AAlignment = taCenter then
        Result.X := Result.X div 2;
    end
    else
      Result.X := 0;

    Result.X := AControlOrigin.X + Result.X;
    Result.Y := AControlOrigin.Y + acRectHeight(AControlBounds) + 2;
  end;

var
  ARect: TRect;
  AWorkareaRect: TRect;
begin
  DoPopup;
  if AutoSize then
    HandleNeeded;
  if ATargetDpi >= acMinDpi then
    ScaleForPPI(ATargetDpi);
  AdjustSize;

  ARect := acRectOffset(AControlBounds, -AControlBounds.Left, -AControlBounds.Top);
  ARect := acRectSetHeight(ARect, Height);
  ValidatePopupFormBounds(ARect);
  ARect := acRectOffset(ARect, CalculateOffset(ARect));

  AWorkareaRect := MonitorGet(ARect.CenterPoint).WorkareaRect;
  if ARect.Bottom > AWorkareaRect.Bottom then
  begin
    OffsetRect(ARect, 0, -(acRectHeight(ARect) + acRectHeight(AControlBounds) + 4));
    ARect.Top := Max(ARect.Top, AWorkareaRect.Top);
  end;
  if ARect.Left < AWorkareaRect.Left then
    OffsetRect(ARect, AWorkareaRect.Left - ARect.Left, 0);
  if ARect.Right > AWorkareaRect.Right then
    OffsetRect(ARect, AWorkareaRect.Right - ARect.Right, 0);

  ShowPopup(ARect);
end;

procedure TACLCustomPopupForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WindowClass.Style := Params.WindowClass.Style or CS_DROPSHADOW or CS_VREDRAW or CS_HREDRAW;
end;

procedure TACLCustomPopupForm.Deactivate;
begin
  inherited Deactivate;
  PopupClose;
end;

procedure TACLCustomPopupForm.WndProc(var Message: TMessage);
begin
  inherited WndProc(Message);
  if FPopuped then
    case Message.Msg of
      WM_ACTIVATEAPP:
        with TWMActivateApp(Message) do
          if not Active then
          begin
            SendMessage(FPrevHandle, WM_NCACTIVATE, WPARAM(False), 0);
            PopupClose;
          end;

      WM_ACTIVATE:
        with TWMActivate(Message) do
          if Active = WA_INACTIVE then
            TACLMainThread.RunPostponed(PopupClose, Self)
          else
          begin
            FPrevHandle := ActiveWindow;
            SendMessage(FPrevHandle, WM_NCACTIVATE, WPARAM(True), 0);
          end;
    end;
end;

procedure TACLCustomPopupForm.DoClosePopup;
begin
  CallNotifyEvent(Self, OnClosePopup);
end;

procedure TACLCustomPopupForm.DoPopup;
begin
  CallNotifyEvent(Self, OnPopup);
end;

procedure TACLCustomPopupForm.Initialize;
var
  ASourceDPI: IACLCurrentDpi;
  ATargetDPI: Integer;
begin
  Visible := False;
  BorderStyle := bsNone;
  DefaultMonitor := dmDesktop;
  Position := poDesigned;
  FormStyle := fsStayOnTop;

  if Supports(Owner, IACLCurrentDpi, ASourceDPI) then
  begin
    ATargetDPI := ASourceDPI.GetCurrentDpi;
    if ATargetDPI <> acDefaultDPI then
      Perform(WM_DPICHANGED, MakeLong(ATargetDPI, ATargetDPI), 0);
  end;
end;

procedure TACLCustomPopupForm.ValidatePopupFormBounds(var R: TRect);
var
  AHeight: Integer;
  AWidth: Integer;
begin
  AHeight := Max(Constraints.MinHeight, acRectHeight(R));
  AWidth := Max(Constraints.MinWidth, acRectWidth(R));
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

procedure TACLCustomPopupForm.ShowPopup(const R: TRect);
var
  AApp: TApplicationAccess;
  AMsg: TMsg;
begin
  BoundsRect := R;
  FPopuped := True;
  Visible := True;
  BringToFront;
  if FUseOwnMessagesLoop then
  begin
    AApp := TApplicationAccess(Application);
    repeat
      if PeekMessage(AMsg, 0, 0, 0, PM_REMOVE) then
      begin
        if (AMsg.Message <> WM_QUIT) and not (AApp.IsHintMsg(AMsg) or AApp.IsMDIMsg(AMsg)) then
        begin
          TranslateMessage(AMsg);
          DispatchMessage(AMsg);
        end;
      end;
      WaitMessage;
    until not Visible;
  end;
end;

procedure TACLCustomPopupForm.CMDialogKey(var Message: TWMKey);
begin
  inherited;
  if Message.CharCode = VK_ESCAPE then
    PopupClose;
end;

procedure TACLCustomPopupForm.CMWantSpecialKey(var Message: TCMWantSpecialKey);
begin
  inherited;
  if Message.CharCode = VK_ESCAPE then
    Message.Result := 1;
end;

{ TACLLocalizableForm }

procedure TACLLocalizableForm.AfterConstruction;
begin
  inherited AfterConstruction;
  LangChange;
end;

function TACLLocalizableForm.GetConfigSection: UnicodeString;
begin
  Result := GetLangSection; // backward compatibility
end;

function TACLLocalizableForm.GetLangSection: UnicodeString;
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

class function TACLFormImageListReplacer.GenerateName(const ABaseName, ASuffix: string; ATargetDPI: Integer): TComponentName;
begin
  Result := ABaseName + ASuffix + IntToStr(MulDiv(100, ATargetDPI, acDefaultDPI));
end;

class function TACLFormImageListReplacer.GetBaseImageListName(const AName: TComponentName): TComponentName;
var
  ALength: Integer;
begin
  Result := AName;
  ALength := Length(Result);
  while (ALength > 0) and Result[ALength].IsNumber do
    Dec(ALength);
  SetLength(Result, ALength);
  if acEndsWith(Result, DarkModeSuffix) then
    SetLength(Result, ALength - Length(DarkModeSuffix));
end;

{ TACLStayOnTopHelper }

class procedure TACLStayOnTopHelper.Refresh(AForm: TACLForm);
const
  StyleMap: array[Boolean] of HWND = (HWND_NOTOPMOST, HWND_TOPMOST);
var
  AStayOnTop: Boolean;
begin
  if (AForm <> nil) and AForm.HandleAllocated and not AForm.IsDesigning and IsWindowVisible(AForm.Handle) then
  begin
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

class function TACLStayOnTopHelper.ExecuteCommonDialog(ADialog: TCommonDialog; AHandleWnd: HWND): Boolean;
begin
  Application.ModalStarted;
  try
    Result := ADialog.Execute(AHandleWnd);
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
  if FApplicationEvents = nil then
  begin
    FApplicationEvents := TApplicationEvents.Create(nil);
    FApplicationEvents.OnModalBegin := AppEventsModalHandler;
    FApplicationEvents.OnModalEnd := AppEventsModalHandler;
  end;
end;

class function TACLStayOnTopHelper.StayOnTopAvailable: Boolean;
begin
  Result := Application.ModalLevel = 0;
end;

{ TACLFormScalingHelper }

class function TACLFormScalingHelper.GetCurrentPPI(AForm: TCustomForm): Integer;
begin
  Result := TCustomFormAccess(AForm).FCurrentPPI;
  if Result = 0 then
    Result := TCustomFormAccess(AForm).PixelsPerInch;
end;

class procedure TACLFormScalingHelper.ScaleForPPI(AForm: TCustomFormAccess; ATargetDPI: Integer; AWindowRect: PRect);

  function IsClientSizeStored(AForm: TCustomFormAccess): Boolean;
  begin
    Result := not (AForm.AutoScroll or (AForm.HorzScrollBar.Range <> 0) or (AForm.VertScrollBar.Range <> 0));
  end;

var
  APrevBounds: TRect;
  APrevClientRect: TRect;
  APrevDPI: Integer;
  APrevParentFont: Boolean;
  AState: TState;
begin
  APrevDPI := TACLFormScalingHelper.GetCurrentPPI(AForm);
  if (ATargetDPI <> APrevDPI) and (ATargetDPI >= acMinDPI) and not IsScaleChanging(AForm) then
  begin
    ScalingBegin(AForm, AState);
    try
      APrevBounds := AForm.BoundsRect;
      APrevClientRect := AForm.ClientRect;
      APrevParentFont := AForm.ParentFont;
      AForm.ScaleForPPI(ATargetDPI);
      AForm.ParentFont := APrevParentFont;
      AForm.PixelsPerInch := ATargetDPI;
      if AWindowRect <> nil then
        AForm.BoundsRect := AWindowRect^
      else
        if IsClientSizeStored(AForm) then
        begin
          if AForm.WindowState <> wsMaximized then
          begin
            AForm.SetBounds(APrevBounds.Left, APrevBounds.Top,
              acRectWidth(APrevBounds) - APrevClientRect.Right + MulDiv(APrevClientRect.Right, ATargetDPI, APrevDPI),
              acRectHeight(APrevBounds) - APrevClientRect.Bottom + MulDiv(APrevClientRect.Bottom, ATargetDPI, APrevDPI));
          end
          else
            AForm.BoundsRect := APrevBounds;
        end;
    finally
      ScalingEnd(AForm, AState);
    end;
  end;
end;

class function TACLFormScalingHelper.IsScaleChanging(AForm: TCustomForm): Boolean;
begin
  Result := (FScalingForms <> nil) and (FScalingForms.IndexOf(AForm) >= 0);
end;

class procedure TACLFormScalingHelper.PopulateControls(AControl: TControl; ATargetList: TComponentList);
var
  I: Integer;
begin
  ATargetList.Add(AControl);
  if AControl is TCustomForm then
  begin
    for I := 0 to TCustomFormAccess(AControl).MDIChildCount - 1 do
      PopulateControls(TCustomFormAccess(AControl).MDIChildren[I], ATargetList);
  end;
  if AControl is TWinControl then
  begin
    for I := 0 to TWinControl(AControl).ControlCount - 1 do
      PopulateControls(TWinControl(AControl).Controls[I], ATargetList);
  end;
end;

class procedure TACLFormScalingHelper.ScalingBegin(AForm: TCustomFormAccess; out AState: TState);
var
  I: Integer;
begin
  if FScalingForms = nil then
    FScalingForms := TList.Create;
  FScalingForms.Add(AForm);

  //#AI: don't change the order
  AState := TState.Create;
  AState.RedrawLocked := IsWinVistaOrLater and IsWindowVisible(AForm.Handle);
  AState.LockedControls := TComponentList.Create(False);
  PopulateControls(AForm, AState.LockedControls);
  for I := 0 to AState.LockedControls.Count - 1 do
    TControl(AState.LockedControls[I]).Perform(CM_SCALECHANGING, 0, 0);
  if AState.RedrawLocked then
    acLockRedraw(AForm);
  AForm.DisableAlign;
end;

class procedure TACLFormScalingHelper.ScalingEnd(AForm: TCustomFormAccess; AState: TState);
var
  I: Integer;
begin
  //#AI: don't change the order
  AForm.EnableAlign;
  AForm.Realign;
  if AState.RedrawLocked then
    acUnlockRedraw(AForm, False);
  for I := AState.LockedControls.Count - 1 downto 0 do
    TControl(AState.LockedControls[I]).Perform(CM_SCALECHANGED, 0, 0);
  if AState.RedrawLocked then
    acFullRedraw(AForm);

  FScalingForms.Remove(AForm);
  if FScalingForms.Count = 0 then
    FreeAndNil(FScalingForms);
  FreeAndNil(AState.LockedControls);
  FreeAndNil(AState);
end;

{ TACLFormMouseWheelHelper }

class procedure TACLFormMouseWheelHelper.CheckInstalled;
begin
  // this helper emulates the "Scrol inactive windows when I hover over them" option from Window 10
  if (FHook = 0) and not IsWin10OrLater then
    FHook := SetWindowsHookEx(WH_MOUSE, MouseHook, 0, GetCurrentThreadId);
end;

class destructor TACLFormMouseWheelHelper.Destroy;
begin
  UnhookWindowsHookEx(FHook);
  FHook := 0;
end;

class function TACLFormMouseWheelHelper.MouseHook(Code: Integer; wParam: WParam; lParam: LParam): LRESULT; stdcall;
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

initialization
  @FEnableNonClientDpiScaling := GetProcAddress(GetModuleHandle(user32), 'EnableNonClientDpiScaling');

finalization
  FreeAndNil(FApplicationEvents);
end.
