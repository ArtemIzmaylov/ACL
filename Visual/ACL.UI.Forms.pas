////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   forms and top-level windows
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Forms;

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
  ACL.UI.Forms.Base,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Desktop,
  ACL.Utils.DPIAware,
  ACL.Utils.RTTI,
  ACL.Utils.Strings;

const
  whmPreprocess  = ACL.UI.Forms.Base.whmPreprocess;
  whmPostprocess = ACL.UI.Forms.Base.whmPostprocess;
{$IFNDEF FPC}
  stAlways  = ACL.UI.Forms.Base.stAlways;
  stDefault = ACL.UI.Forms.Base.stDefault;
  stNever   = ACL.UI.Forms.Base.stNever;

type
  TShowInTaskbar = ACL.UI.Forms.Base.TShowInTaskbar;
{$ENDIF}

type

{$REGION ' Popup Window '}

  { TACLPopupWindow }

  TACLPopupWindowClass = class of TACLPopupWindow;
  TACLPopupWindow = class(TACLBasicForm)
  strict private
    FOwnerFormWnd: HWND;

    FOnClosePopup: TNotifyEvent;
    FOnPopup: TNotifyEvent;

    procedure ConstraintBounds(var R: TRect);
    procedure InitPopup;
    procedure InitScaling;
    procedure ShowPopup(const R: TRect);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  {$IFDEF FPC}
    procedure KeyDownBeforeInterface(var Key: Word; Shift: TShiftState); override;
  {$ENDIF}
    procedure WndProc(var Message: TMessage); override;
    //# Events
    procedure DoPopup; virtual;
    procedure DoPopupClosed; virtual;
    //# Mouse
    function IsMouseInControl: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ClosePopup;
    procedure Popup(R: TRect); virtual;
    procedure PopupUnderControl(const AControlBoundsOnScreen: TRect;
      AAlignment: TAlignment = taLeftJustify);
    //# Properties
    property AutoSize;
    //# Events
    property OnClosePopup: TNotifyEvent read FOnClosePopup write FOnClosePopup;
    property OnPopup: TNotifyEvent read FOnPopup write FOnPopup;
  end;

{$ENDREGION}

{$REGION ' Forms '}

  TACLCustomFormImpl = TACLCustomForm;

  { TACLForm }

  TACLForm = class(TACLCustomFormImpl)
  published
    property Padding;
    property ShowInTaskBar;
    property StayOnTop;
  end;

  { TACLLocalizableForm }

  TACLLocalizableForm = class(TACLForm, IACLLocalizableComponentRoot)
  protected
    function GetConfigSection: string; override;
    // IACLLocalizableComponentRoot
    function GetLangSection: string; virtual;
    procedure LangChange; virtual;
    function LangValue(const AKey: string): string; overload;
    function LangValue(const AKey: string; APartIndex: Integer): string; overload;
    // Messages
    procedure WMLang(var Msg: TMessage); message WM_ACL_LANG;
  public
    procedure AfterConstruction; override;
  end;

{$ENDREGION}

{$REGION ' Helpers '}

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

{$ENDREGION}

  TACLFormCorners = (afcDefault, afcRectangular, afcRounded, afcSmallRounded);

function acGetWindowText(AHandle: HWND): string;
procedure acSetWindowText(AHandle: HWND; const AText: string);
procedure acSwitchToWindow(AHandle: HWND);

procedure acFormsCloseAll;
function acFormSetCorners(AHandle: HWND; ACorners: TACLFormCorners): Boolean;
implementation

type
  TWinControlAccess = class(TWinControl);

function acGetWindowText(AHandle: HWND): string;
{$IFDEF MSWINDOWS}
var
  LBuffer: array[Byte] of Char;
begin
  GetWindowText(AHandle, @LBuffer[0], Length(LBuffer));
  Result := LBuffer;
{$ELSE}
var
  LCtrl: TWinControlAccess;
begin
  LCtrl := TWinControlAccess(FindControl(AHandle));
  if LCtrl <> nil then
    Result := LCtrl.Text
  else
    Result := '';
{$ENDIF}
end;

procedure acSetWindowText(AHandle: HWND; const AText: string);
{$IFDEF MSWINDOWS}
begin
  if AHandle <> 0 then
  begin
    if IsWindowUnicode(AHandle) then
      SetWindowTextW(AHandle, PWideChar(AText))
    else
      DefWindowProcW(AHandle, WM_SETTEXT, 0, LPARAM(PChar(AText))); // fix for app handle
  end;
{$ELSE}
var
  LCtrl: TWinControlAccess;
begin
  LCtrl := TWinControlAccess(FindControl(AHandle));
  if LCtrl <> nil then
    LCtrl.Text := AText;
{$ENDIF}
end;

procedure acSwitchToWindow(AHandle: HWND);
{$IFDEF MSWINDOWS}
var
  AInput: TInput;
begin
  ZeroMemory(@AInput, SizeOf(AInput));
  SendInput(INPUT_KEYBOARD, AInput, SizeOf(AInput));
{$ELSE}
begin
{$ENDIF}
  SetForegroundWindow(AHandle);
  SetFocus(AHandle);
end;

function acWantSpecialKey(AChild: TControl; ACharCode: Word; AShift: TShiftState): Boolean;
begin
  Result := (AChild <> nil) and ([ssCtrl, ssAlt, ssShift] * AShift = []) and (
    (AChild.Perform(CM_WANTSPECIALKEY, ACharCode, 0) <> 0) or
    (AChild.Perform(WM_GETDLGCODE, 0, 0) and DLGC_WANTALLKEYS <> 0));
end;

procedure acFormsCloseAll;
var
  AIndex: Integer;
  APrevCount: Integer;
begin
  AIndex := 0;
  while AIndex < Screen.FormCount do
  begin
    APrevCount := Screen.FormCount;
    if Application.MainForm <> Screen.Forms[AIndex] then
    begin
      Screen.Forms[AIndex].Close;
      Application.ProcessMessages; // to process PostMessages;
    end;
    if APrevCount = Screen.FormCount then
      Inc(AIndex);
  end;
end;

function acFormSetCorners(AHandle: HWND; ACorners: TACLFormCorners): Boolean;
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

class function TACLFormImageListReplacer.GetReplacement(
  AImageList: TCustomImageList; AForm: TCustomForm): TCustomImageList;
begin
  Result := GetReplacement(AImageList, acGetCurrentDpi(AForm), TACLApplication.IsDarkMode);
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

{$REGION ' Popup Window '}

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
{$IFDEF FPC}
  KeyPreview := True;
  ShowInTaskBar := stNever;
{$ENDIF}
  Scaled := False; // manual control
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
    Hide;
    if FOwnerFormWnd <> 0 then
      SendMessage(FOwnerFormWnd, WM_EXITMENULOOP, 0, 0);
  finally
    DoPopupClosed;
  end;
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
    Params.WndParent := GetParentForm(TWinControl(Owner)).Handle;
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
  LSourceDPI: Integer;
begin
  LSourceDPI := acTryGetCurrentDpi(Owner);
  if LSourceDPI <> 0 then
    ScaleForPPI(LSourceDPI);
  if Owner is TControl then
    acAssignFont(Font, TWinControlAccess(Owner).Font, CurrentDpi, LSourceDPI);
end;

function TACLPopupWindow.IsMouseInControl: Boolean;
begin
  Result := PtInRect(Rect(0, 0, Width, Height), CalcCursorPos);
end;

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

  Visible := True;
end;

{$IFDEF FPC}
procedure TACLPopupWindow.KeyDownBeforeInterface(var Key: Word; Shift: TShiftState);
var
  LHandler: TControl;
begin
  if Key = VK_ESCAPE then
  begin
    LHandler := ActiveControl;
    if LHandler = nil then
      LHandler := ActiveDefaultControl;
    if not acWantSpecialKey(LHandler, Key, Shift) then
    begin
      ClosePopup;
      Key := 0;
      Exit;
    end;
  end;
  inherited;
end;
{$ENDIF}

procedure TACLPopupWindow.WndProc(var Message: TMessage);
begin
  if Visible then
    case Message.Msg of
      WM_GETDLGCODE:
        Message.Result := DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTALLKEYS or DLGC_WANTCHARS;
      WM_ACTIVATEAPP:
        ClosePopup;
      WM_CONTEXTMENU, WM_MOUSEWHEEL, WM_MOUSEHWHEEL, CM_MOUSEWHEEL:
        Exit;
      CM_CANCELMODE:
        if not ContainsControl(TCMCancelMode(Message).Sender) then
          ClosePopup;
      WM_ACTIVATE:
        with TWMActivate(Message) do
          if Active = WA_INACTIVE then
            TACLMainThread.RunPostponed(ClosePopup, Self)
          else // c нашей формой, по идее, это не нужно:
            SendMessage(ActiveWindow, WM_NCACTIVATE, WPARAM(True), 0);

    {$IFNDEF FPC}
      WM_KEYDOWN, CM_DIALOGKEY, CM_WANTSPECIALKEY:
        if TWMKey(Message).CharCode = VK_ESCAPE then
        begin
          ClosePopup;
          TWMKey(Message).CharCode := 0;
          TWMKey(Message).Result := 1;
          Exit;
        end;
    {$ENDIF}
    end;
  inherited;
end;

{$ENDREGION}

{$REGION ' Form '}

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
var
  LSection: string;
begin
  LSection := GetLangSection;
  Caption := LangFile.ReadString(LSection, 'Caption', Caption);
  LangApplyTo(LSection, Self);
end;

function TACLLocalizableForm.LangValue(const AKey: string): string;
begin
  Result := LangGet(GetLangSection, AKey);
end;

function TACLLocalizableForm.LangValue(const AKey: string; APartIndex: Integer): string;
begin
  Result := LangExtractPart(LangValue(AKey), APartIndex);
end;

procedure TACLLocalizableForm.WMLang(var Msg: TMessage);
begin
  LangChange;
end;

{$ENDREGION}

end.
