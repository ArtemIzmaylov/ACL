////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Forms and Top-level Windows
//
//  Author:    Artem Izmaylov
//             © 2006-2025
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
  WSLCLClasses,
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
{$IFDEF ACL_USE_SKINNED_FORM}
  ACL.UI.Forms.Styled,
{$ENDIF}
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Desktop,
  ACL.Utils.DPIAware,
  ACL.Utils.RTTI,
  ACL.Utils.Strings;

{$IFNDEF FPC}
const
  stAlways  = ACL.UI.Forms.Base.stAlways;
  stDefault = ACL.UI.Forms.Base.stDefault;
  stNever   = ACL.UI.Forms.Base.stNever;
type
  TShowInTaskbar = ACL.UI.Forms.Base.TShowInTaskbar;
{$ENDIF}
type
  TShowMode = ACL.UI.Forms.Base.TShowMode;

{$REGION ' Drag Image '}

  { TACLDragImage }

  TACLDragImage = class(TForm)
  strict private
    procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
  {$IFDEF FPC}
    class procedure WSRegisterClass; override;
  {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    procedure Show;
  end;

{$ENDREGION}

{$REGION ' Popup Window '}

  { TACLPopupWindow }

  TACLPopupWindowClass = class of TACLPopupWindow;
  TACLPopupWindow = class(TACLBasicForm)
  strict private
    FDropDownMode: Boolean;
    FOwnerFormWnd: TWndHandle;
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
    class procedure WSRegisterClass; override;
  {$ENDIF}
    procedure WndProc(var Message: TMessage); override;
    //# Mouse
    function IsMouseInControl: Boolean;
    //# Events
    procedure DoPopup; virtual;
    procedure DoPopupClosed; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ClosePopup;
    procedure Popup(R: TRect); virtual;
    procedure PopupUnderControl(const AControlBoundsOnScreen: TRect;
      AAlignment: TAlignment = taLeftJustify);
    //# Properties
    property AutoSize;
    property DropDownMode: Boolean read FDropDownMode write FDropDownMode default False;
    //# Events
    property OnClosePopup: TNotifyEvent read FOnClosePopup write FOnClosePopup;
    property OnPopup: TNotifyEvent read FOnPopup write FOnPopup;
  end;

{$ENDREGION}

{$REGION ' Forms '}

{$IFDEF ACL_USE_SKINNED_FORM}
  TACLCustomFormImpl = TACLCustomStyledForm;
{$ELSE}
  TACLCustomFormImpl = TACLCustomForm;
{$ENDIF}

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

function acGetWindowText(AHandle: HWND): string;
procedure acSetWindowText(AHandle: HWND; const AText: string);
implementation

uses
{$I ACL.UI.Core.Impl.inc};

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

function acWantSpecialKey(AChild: TControl; ACharCode: Word; AShift: TShiftState): Boolean;
begin
  Result := (AChild <> nil) and ([ssCtrl, ssAlt, ssShift] * AShift = []) and (
    (AChild.Perform(CM_WANTSPECIALKEY, ACharCode, 0) <> 0) or
    (AChild.Perform(WM_GETDLGCODE, 0, 0) and DLGC_WANTALLKEYS <> 0));
end;

{$REGION ' Drag Image '}

{ TACLDragImage }

constructor TACLDragImage.Create(AOwner: TComponent);
begin
  CreateNew(AOwner);
  AlphaBlend := True;
  AlphaBlendValue := acDragImageAlpha;
  Position := poDesigned;
  BorderStyle := bsNone;
  Scaled := False;
end;

procedure TACLDragImage.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.ExStyle := WS_EX_TOPMOST or WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE;
  Params.Style := WS_POPUP;
end;

procedure TACLDragImage.Paint;
begin
  acFillRect(Canvas, ClientRect, acDragImageColor);
end;

procedure TACLDragImage.CMDesignHitTest(var Message: TCMDesignHitTest);
begin
  Message.Result := 1;
end;

procedure TACLDragImage.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TACLDragImage.WMNCHitTest(var Message: TWMNCHitTest);
begin
  Message.Result := HTTRANSPARENT;
end;

{$IFDEF FPC}
class procedure TACLDragImage.WSRegisterClass;
begin
  RegisterWSComponent(TACLDragImage, TACLWSHintWindow);
end;
{$ENDIF}

procedure TACLDragImage.Show;
begin
{$IFDEF FPC}
  inherited;
{$ELSE}
  ShowWindow(Handle, SW_SHOWNA);
{$ENDIF}
end;

{$ENDREGION}

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
  InitPopupMode(Safe.CastOrNil<TWinControl>(AOwner));
{$IFDEF FPC}
  KeyPreview := True;
  ShowInTaskBar := stNever;
{$ENDIF}
  Scaled := False; // manual control
end;

destructor TACLPopupWindow.Destroy;
begin
  TACLMainThread.Unsubscribe(Self);
  TACLObjectLinks.Release(Self);
  inherited;
end;

procedure TACLPopupWindow.ClosePopup;
begin
  MouseCapture := False;
  if Visible then
  try
  {$IFDEF LCLGtkX}
    TGtkApp.EndPopup(Self);
  {$ENDIF}
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
  if DropDownMode then
  begin
    Params.ExStyle := Params.ExStyle or WS_EX_NOACTIVATE;
    Params.Style := WS_POPUP;
  end
  else
    Params.ExStyle := Params.ExStyle or WS_EX_TOOLWINDOW;

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
    Font.Assign(TWinControlAccess(Owner).Font, LSourceDPI, CurrentDpi);
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
  if DropDownMode then
    ControlStyle := ControlStyle - [csCaptureMouse]
  else
    ControlStyle := ControlStyle + [csCaptureMouse];

  BoundsRect := R;

  if Screen.ActiveCustomForm <> nil then
    FOwnerFormWnd := Screen.ActiveCustomForm.Handle
  else
    FOwnerFormWnd := 0;

  if FOwnerFormWnd <> 0 then
    SendMessage(FOwnerFormWnd, WM_ENTERMENULOOP, 0, 0);

  Visible := True;
{$IFDEF LCLGtkX}
  try
    TGtkApp.BeginPopup(Self);
    if DropDownMode then
      TGtkApp.SetInputRedirection(Safe.CastOrNil<TWinControl>(Owner));
  except
    ClosePopup;
    raise;
  end;
{$ELSE}
  if DropDownMode then
    MouseCapture := True;
{$ENDIF}
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

class procedure TACLPopupWindow.WSRegisterClass;
begin
  RegisterWSComponent(TACLPopupWindow, TACLWSPopupWindow);
end;

{$ENDIF}

procedure TACLPopupWindow.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    CM_CANCELMODE:
      if Visible and not (fsShowing in FormState) then
      begin
        if not ContainsControl(TCMCancelMode(Message).Sender) then
          ClosePopup;
      end;

    WM_CAPTURECHANGED:
      if DropDownMode and not MouseCapture then
        ClosePopup;

    WM_CONTEXTMENU, WM_MOUSEWHEEL, WM_MOUSEHWHEEL, CM_MOUSEWHEEL:
      Exit;
    WM_GETDLGCODE:
      Message.Result := DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTALLKEYS or DLGC_WANTCHARS;

    WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN:
      if not IsMouseInControl then
        ClosePopup;

    WM_MOUSEMOVE:
      if DropDownMode then
        UpdateCursor;

    WM_ACTIVATE:
      if Visible then
      begin
        if TWMActivate(Message).Active = WA_INACTIVE then
          TACLMainThread.RunPostponed(ClosePopup, Self)
      {$IFDEF MSWINDOWS}
        else // c нашей формой, по идее, это не нужно:
          SendMessage(TWMActivate(Message).ActiveWindow, WM_NCACTIVATE, WPARAM(True), 0);
      {$ENDIF}
      end;

    WM_ACTIVATEAPP:
      if not (fsShowing in FFormState) then
        ClosePopup;

  {$IFNDEF FPC}
    WM_KEYDOWN, CM_DIALOGKEY, CM_WANTSPECIALKEY:
      if Visible and (TWMKey(Message).CharCode = VK_ESCAPE) then
      begin
        ClosePopup;
        TWMKey(Message).CharCode := 0;
        TWMKey(Message).Result := 1;
        Exit;
      end;

    CN_KEYDOWN:
      if DropDownMode and (PopupParent <> nil) then // ref.TApplication.IsKeyMsg
      begin
        if TWMKey(Message).CharCode = VK_TAB then
          PopupParent.WindowProc(Message); // to SelectNext
        if TWMKey(Message).CharCode <> VK_ESCAPE then
          Exit; // key will be processed by IME
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
