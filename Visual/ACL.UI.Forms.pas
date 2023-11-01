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
    procedure CMParentFontChanged(var Message: TCMParentFontChanged); message CM_PARENTFONTCHANGED;
    procedure WMAppCommand(var Message: TMessage); message WM_APPCOMMAND;
    procedure WMDPIChanged(var Message: TWMDpi); message WM_DPICHANGED;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure WMSettingsChanged(var Message: TWMSettingChange); message WM_SETTINGCHANGE;
  protected
    procedure ChangeScale(M, D: Integer; IsDpiChange: Boolean); override;
    procedure DoShow; override;
    procedure DpiChanged; virtual;
    procedure InitializeNewForm; override;
    procedure Loaded; override;
    procedure ReadState(Reader: TReader); override;
    procedure SetPixelsPerInch(Value: Integer); {$IFDEF DELPHI110ALEXANDRIA}override;{$ENDIF}

    // IACLApplicationListener
    procedure IACLApplicationListener.Changed = ApplicationSettingsChanged;
    procedure ApplicationSettingsChanged(AChanges: TACLApplicationChanges); virtual;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure ScaleForCurrentDPI; override;
    procedure ScaleForPPI(ATargetPPI: Integer); overload; override; final;
    procedure ScaleForPPI(ATargetPPI: Integer; AWindowRect: PRect); reintroduce; overload; virtual;
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

  TACLForm = class(TACLBasicForm,
    IACLResourceChangeListener,
    IACLResourceProvider)
  strict private
    FFormCreated: Boolean;
    FShowOnTaskBar: Boolean;
    FStayOnTop: Boolean;
    FWndProcHooks: array[TACLWindowHookMode] of TACLWindowHooks;

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
    procedure PopupUnderControl(const AControlBoundsOnScreen: TRect;
      AAlignment: TAlignment = taLeftJustify; ATargetDpi: Integer = 0); 
    // Properties
    property Popuped: Boolean read FPopuped;
    // Events
    property OnClosePopup: TNotifyEvent read FOnClosePopup write FOnClosePopup;
    property OnPopup: TNotifyEvent read FOnPopup write FOnPopup;
  end;

  { TACLLocalizableForm }

  TACLLocalizableForm = class(TACLForm, IACLLocalizableComponentRoot)
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
    class function GetReplacement(AImageList: TCustomImageList;
      AForm: TCustomForm): TCustomImageList; overload;
    class function GetReplacement(AImageList: TCustomImageList;
      ATargetDPI: Integer; ADarkMode: Boolean): TCustomImageList; overload;
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

procedure TACLBasicForm.ApplyColorSchema;
begin
  for var I := 0 to ComponentCount - 1 do
    acApplyColorSchema(Components[I], TACLApplication.ColorSchema);
end;

procedure TACLBasicForm.ScaleForPPI(ATargetPPI: Integer; AWindowRect: PRect);
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

procedure TACLBasicForm.ScaleForPPI(ATargetPPI: Integer);
begin
  ScaleForPPI(ATargetPPI, nil);
end;

procedure TACLBasicForm.ChangeScale(M, D: Integer; IsDpiChange: Boolean);
begin
  ScaleForPPI(MulDiv(FCurrentPPI, M, D));
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
  if FCurrentPPI = 0 then
    FCurrentPPI := PixelsPerInch;
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
  if csReadingState in ControlState then
    FCurrentPPI := Value;
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
        acAssignFont(Font, Application.DefaultFont, FCurrentPPI, acGetSystemDpi);

      ParentFont := True;
    finally
      FParentFontLocked := False;
    end;
  end;
end;

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

procedure TACLBasicForm.WMSetCursor(var Message: TWMSetCursor);
begin
  if not TACLControlsHelper.WMSetCursor(Self, Message) then
    inherited;
end;

procedure TACLBasicForm.WMSettingsChanged(var Message: TWMSettingChange);
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

//procedure TACLCustomPopupForm.PopupUnderControl(
//  AControl: TControl; AAlignment: TAlignment = taLeftJustify);
//begin
//  PopupUnderControl( AControl.BoundsRect, Control.ClientToScreen(NullPoint), Alignment, acGetCurrentDpi(Control));
//end;

procedure TACLCustomPopupForm.PopupUnderControl(const AControlBoundsOnScreen: TRect;
  AAlignment: TAlignment = taLeftJustify; ATargetDpi: Integer = 0);

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
  DoPopup;
  if AutoSize then
    HandleNeeded;
  if ATargetDpi >= acMinDpi then
    ScaleForPPI(ATargetDpi);
  AdjustSize;

  ARect := acRect(AControlBoundsOnScreen.Size);
  ARect := acRectSetHeight(ARect, Height);
  ValidatePopupFormBounds(ARect);
  ARect := acRectOffset(ARect, CalculateOffset(ARect));

  AWorkareaRect := MonitorGet(ARect.CenterPoint).WorkareaRect;
  if ARect.Bottom > AWorkareaRect.Bottom then
  begin
    OffsetRect(ARect, 0, -(ARect.Height + AControlBoundsOnScreen.Height + 4));
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
begin
  if EnumProperties(APersistent, AProperties, APropertyCount) then
  try
    for var I := 0 to APropertyCount - 1 do
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
begin
  for var I := 0 to AForm.ComponentCount - 1 do
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

{ TACLFormScaling }

procedure TACLFormScaling.Start(AForm: TACLBasicForm);

  procedure PopulateControls(AControl: TControl);
  begin
    LockedControls.Add(AControl);
    if AControl is TCustomForm then
    begin
      for var I := 0 to TCustomFormAccess(AControl).MDIChildCount - 1 do
        PopulateControls(TCustomFormAccess(AControl).MDIChildren[I]);
    end;
    if AControl is TWinControl then
    begin
      for var I := 0 to TWinControl(AControl).ControlCount - 1 do
        PopulateControls(TWinControl(AControl).Controls[I]);
    end;
  end;

begin
  //#AI: don't change the order
  Form := AForm;
  RedrawLocked := IsWinVistaOrLater and IsWindowVisible(AForm.Handle);
  LockedControls := TComponentList.Create(False);
  PopulateControls(AForm);
  for var I := 0 to LockedControls.Count - 1 do
    TControl(LockedControls[I]).Perform(CM_SCALECHANGING, 0, 0);
  if RedrawLocked then
    SendMessage(Form.Handle, WM_SETREDRAW, 0, 0);
  AForm.DisableAlign;
end;

procedure TACLFormScaling.Done;
begin
  //#AI: keep the order
  Form.DpiChanged;
  Form.EnableAlign;
  Form.Realign;
  if RedrawLocked then
    SendMessage(Form.Handle, WM_SETREDRAW, 1, 1);
  for var I := LockedControls.Count - 1 downto 0 do
    TControl(LockedControls[I]).Perform(CM_SCALECHANGED, 0, 0);
  if RedrawLocked then
    RedrawWindow(Form.Handle, nil, 0, RDW_INVALIDATE or RDW_ALLCHILDREN or RDW_ERASE);
  FreeAndNil(LockedControls);
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

finalization
  FreeAndNil(FApplicationEvents);
end.
