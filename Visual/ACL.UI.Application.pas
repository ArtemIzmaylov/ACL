////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Application Controller
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Application;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  System.UITypes,
  // VCL
  {Vcl.}Graphics,
  {Vcl.}Controls,
  {Vcl.}Forms,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.FileFormats.INI,
  ACL.Graphics,
  ACL.Graphics.FontCache,
  ACL.Timers,
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

type
  TACLApplicationChange = (acDarkMode, acDarkModeForSystem,
    acAccentColor, acColorSchema, acScalingMode, acDefaultFont);
  TACLApplicationChanges = set of TACLApplicationChange;

  { IACLApplicationListener }

  IACLApplicationListener = interface
  ['{87E7C980-20D9-4F0E-BBCF-A5660615C806}']
    procedure Changed(AChanges: TACLApplicationChanges);
  end;

  { TACLApplication }

  TACLApplication = class
  strict private const
    DefaultCatchExceptions = True;
    DefaultHideHintPause = 10000;
  strict private
    class var FActualAccentColor: TAlphaColor;
    class var FActualDarkMode: Boolean;
    class var FActualDarkModeForSystem: Boolean;
    class var FCatchExceptions: Boolean;
    class var FColorSchema: TACLColorSchema;
    class var FColorSchemaUseNative: Boolean;
    class var FChangeAggregator: TACLTimer;
    class var FDarkMode: TACLBoolean;
    class var FDefaultFont: TFont;
    class var FGlobalSettings: TObject;
    class var FListeners: TACLListenerList;
    class var FTargetDPI: Integer;

  {$IFDEF FPC}
    class procedure DefaultFontChanged(Sender: TObject);
  {$ENDIF}
    class procedure DelayedChangeHandler(Sender: TObject);
    class function GetDefaultFont: TFont; static;
    class procedure SetColorSchema(const AValue: TACLColorSchema); static;
    class procedure SetColorSchemaUseNative(AValue: Boolean); static;
    class procedure SetDarkMode(AValue: TACLBoolean); static;
    class procedure SetTargetDPI(AValue: Integer); static;
  protected
    class procedure Changed(AChanges: TACLApplicationChanges);
  public
    class constructor Create;
    class destructor Destroy;
    class procedure ConfigLoad(AConfig: TACLIniFile; const ASection: string);
    class procedure ConfigSave(AConfig: TACLIniFile; const ASection: string);
    class procedure ListenerAdd(AListener: IUnknown);
    class procedure ListenerRemove(AListener: IUnknown);
    class procedure SetDefaultFont(AName: TFontName; AHeight: Integer);
    class procedure UpdateColorSet;

    class function GetHandle: TWndHandle;
    class function IsDestroying: Boolean;
    class function IsMinimized: Boolean;
    class procedure Minimize;
    class procedure ModalFinish(var AList: Pointer);
    class procedure ModalStart(out AList: Pointer);
    class procedure PostTerminate;
    class procedure RestoreIfMinimized;

    class function GetActualColor(ALightColor, ADarkColor: TColor): TColor; overload;
    class function GetActualColor(ALightColor, ADarkColor: TAlphaColor): TAlphaColor; overload;
    class function GetTargetDPI(AControl: TWinControl): Integer;
    class function IsDarkMode: Boolean;
    class function IsDarkModeOfSystemBar: Boolean;

    class property AccentColor: TAlphaColor read FActualAccentColor;
    class property CatchExceptions: Boolean read FCatchExceptions write FCatchExceptions;
    class property ColorSchema: TACLColorSchema read FColorSchema write SetColorSchema;
    class property ColorSchemaUseNative: Boolean read FColorSchemaUseNative write SetColorSchemaUseNative;
    class property DarkMode: TACLBoolean read FDarkMode write SetDarkMode;
    class property DefaultFont: TFont read GetDefaultFont;
    class property TargetDPI: Integer read FTargetDPI write SetTargetDPI;
  end;

  { TACLApplicationController }

  TACLApplicationController = class(TACLComponent)
  strict private
    function GetDarkMode: TACLBoolean;
    function GetTargetDPI: Integer;
    procedure SetDarkMode(AValue: TACLBoolean);
    procedure SetTargetDPI(AValue: Integer);
  published
    property DarkMode: TACLBoolean read GetDarkMode write SetDarkMode default TACLBoolean.Default;
    property TargetDPI: Integer read GetTargetDPI write SetTargetDPI default 0;
  end;

implementation

{$IF DEFINED(MSWINDOWS)}
  {$I ACL.UI.Application.Win32.inc}
{$ELSEIF DEFINED(LCLGtkX)}
  {$I ACL.UI.Application.GtkX.inc}
{$ENDIF}

{$IFDEF FPC}
type
  PModalLock = ^TModalLock;
  TModalLock = record
    Focus: TWndHandle;
    List: TList;
  end;
{$ENDIF}

{ TACLApplication }

class constructor TACLApplication.Create;
begin
  CatchExceptions := DefaultCatchExceptions;
  FChangeAggregator := TACLTimer.CreateEx(DelayedChangeHandler, 100);
  FGlobalSettings := TGlobalSettings.Create(FChangeAggregator.Restart);
  UpdateColorSet;
end;

class destructor TACLApplication.Destroy;
begin
  FreeAndNil(FGlobalSettings);
  FreeAndNil(FChangeAggregator);
  FreeAndNil(FDefaultFont);
end;

class procedure TACLApplication.Changed(AChanges: TACLApplicationChanges);
var
  LIntf: IACLApplicationListener;
begin
  if (FListeners <> nil) and (AChanges <> []) then
    for LIntf in FListeners.Enumerate<IACLApplicationListener> do
      LIntf.Changed(AChanges);
end;

class procedure TACLApplication.ConfigLoad(AConfig: TACLIniFile; const ASection: string);
begin
  TargetDPI := AConfig.ReadInteger(ASection, 'TargetDPI');
  DarkMode := AConfig.ReadEnum<TACLBoolean>(ASection, 'DarkMode', TACLBoolean.Default);
  ColorSchema := TACLColorSchema.CreateFromDword(AConfig.ReadInt64(ASection, 'ColorSchema'));
  ColorSchemaUseNative := AConfig.ReadBool(ASection, 'UseNativeColorSchema');
  CatchExceptions := AConfig.ReadBool(ASection, 'CatchExceptions', DefaultCatchExceptions);
  Application.HintHidePause := AConfig.ReadInteger(ASection, 'HideHintPause', DefaultHideHintPause);
  Application.ShowHint := Application.HintHidePause > 0;
end;

class procedure TACLApplication.ConfigSave(AConfig: TACLIniFile; const ASection: string);
begin
  AConfig.WriteEnum<TACLBoolean>(ASection, 'DarkMode', DarkMode, TACLBoolean.Default);
  AConfig.WriteInt64(ASection, 'ColorSchema', ColorSchema.ToDword, 0);
  AConfig.WriteInteger(ASection, 'TargetDPI', TargetDPI, 0);
  AConfig.WriteInteger(ASection, 'HideHintPause', Application.HintHidePause, DefaultHideHintPause);
  AConfig.WriteBool(ASection, 'CatchExceptions', CatchExceptions, DefaultCatchExceptions);
  AConfig.WriteBool(ASection, 'UseNativeColorSchema', ColorSchemaUseNative, False);
end;

class procedure TACLApplication.DelayedChangeHandler(Sender: TObject);
begin
  FChangeAggregator.Stop;
  UpdateColorSet;
end;

class function TACLApplication.GetActualColor(ALightColor, ADarkColor: TAlphaColor): TAlphaColor;
begin
  if IsDarkMode then
    Result := ADarkColor
  else
    Result := ALightColor;

  TACLColors.ApplyColorSchema(Result, ColorSchema);
end;

class function TACLApplication.GetDefaultFont: TFont;
begin
{$IFDEF FPC}
  if FDefaultFont = nil then
  begin
    FDefaultFont := TFont.Create;
    FDefaultFont.ResolveHeight;
    FDefaultFont.OnChange := DefaultFontChanged;
  end;
  Result := FDefaultFont;
{$ELSE}
  Result := Application.DefaultFont;
{$ENDIF}
end;

class function TACLApplication.GetActualColor(ALightColor, ADarkColor: TColor): TColor;
begin
  if IsDarkMode then
    Result := ADarkColor
  else
    Result := ALightColor;

  TACLColors.ApplyColorSchema(Result, ColorSchema);
end;

class function TACLApplication.GetTargetDPI(AControl: TWinControl): Integer;
begin
  if TargetDPI <> 0 then
    Result := TargetDPI
  else
    Result := acGetTargetDPI(AControl);
end;

class function TACLApplication.IsDarkMode: Boolean;
begin
  Result := FActualDarkMode;
end;

class function TACLApplication.IsDarkModeOfSystemBar: Boolean;
begin
  Result := FActualDarkModeForSystem;
end;

class function TACLApplication.IsDestroying: Boolean;
begin
  Result := (Application = nil) or (csDestroying in Application.ComponentState);
end;

class procedure TACLApplication.ListenerAdd(AListener: IUnknown);
begin
  if FListeners = nil then
    FListeners := TACLListenerList.Create(4096);
  FListeners.Add(AListener);
end;

class procedure TACLApplication.ListenerRemove(AListener: IUnknown);
begin
  if FListeners <> nil then
  begin
    FListeners.Remove(AListener);
    if FListeners.Count = 0 then
      FreeAndNil(FListeners);
  end;
end;

class procedure TACLApplication.ModalFinish(var AList: Pointer);
begin
{$IFDEF FPC}
  Screen.EnableForms(PModalLock(AList)^.List);
  SetFocus(PModalLock(AList)^.Focus);
  FreeMem(AList);
{$ELSE}
  EnableTaskWindows(AList);
{$ENDIF}
  Application.ModalFinished;
  AList := nil;
end;

class procedure TACLApplication.ModalStart(out AList: Pointer);
{$IFDEF FPC}
var
  LLock: PModalLock;
{$ENDIF}
begin
  // В общем суть такая, плагин (Enhancer в частности) поднимает модальное MFC-окно,
  // при этом не блокирует наши окна, пользователь закрывает наше окно, а затем - MFC-шное
  // Посколькуо наше окно уже убилось, MouseUp, до этого залоченный модальный
  // message loop, завершается по убитым объектам и все рушится.
  Application.ModalStarted;
{$IFDEF FPC}
  LLock := AllocMem(SizeOf(TModalLock));
  LLock^.Focus := GetFocus;
  LLock^.List := Screen.DisableForms(nil);
  AList := LLock;
{$ELSE}
  AList := DisableTaskWindows(0);
{$ENDIF}
end;

class procedure TACLApplication.SetDefaultFont(AName: TFontName; AHeight: Integer);
begin
  TACLFontCache.RemapFont(AName, AHeight);
  AHeight := MulDiv(AHeight, acGetSystemDpi, acDefaultDpi);

  DefFontData.Name := TFontDataName(AName);
  DefFontData.Height := AHeight;

{$IFDEF FPC}
  DefaultFont.BeginUpdate;
  try
{$ENDIF}
    DefaultFont.Name := AName;
    DefaultFont.Height := AHeight;
{$IFDEF FPC}
  finally
    DefaultFont.EndUpdate;
  end;
{$ENDIF}
end;

class procedure TACLApplication.UpdateColorSet;
var
  LActualAccentColor: TAlphaColor;
  LActualColorSchema: TACLColorSchema;
  LActualDarkMode: Boolean;
  LActualDarkModeForSystem: Boolean;
  LChanges: TACLApplicationChanges;
begin
  LChanges := [];

  TGlobalSettings(FGlobalSettings).GetDarkMode(LActualDarkMode, LActualDarkModeForSystem);
  case DarkMode of
    TACLBoolean.True:
      LActualDarkMode := True;
    TACLBoolean.False:
      LActualDarkMode := False;
  else;
  end;

  LActualAccentColor := TGlobalSettings(FGlobalSettings).GetColorAccent;
  if LActualAccentColor <> FActualAccentColor then
  begin
    FActualAccentColor := LActualAccentColor;
    Include(LChanges, acAccentColor);
  end;

  if ColorSchemaUseNative then
  begin
    LActualColorSchema := TACLColorSchema.CreateFromColor(AccentColor);
    if LActualColorSchema <> FColorSchema then
    begin
      FColorSchema := LActualColorSchema;
      Include(LChanges, acColorSchema);
    end;
  end;

  if LActualDarkModeForSystem <> FActualDarkModeForSystem then
  begin
    FActualDarkModeForSystem := LActualDarkModeForSystem;
    Include(LChanges, acDarkModeForSystem);
  end;

  if LActualDarkMode <> FActualDarkMode then
  begin
    FActualDarkMode := LActualDarkMode;
    Include(LChanges, acDarkMode);
    if ColorSchema.IsAssigned then
      Include(LChanges, acColorSchema);
  end;

  if LChanges <> [] then
    Changed(LChanges);
end;

class function TACLApplication.GetHandle: HWND;
begin
  if Application.{%H-}MainFormOnTaskBar then
    Result := Application.MainFormHandle
  else
    Result := Application.{%H-}Handle;
end;

class function TACLApplication.IsMinimized: Boolean;
begin
  Result := IsIconic(GetHandle);
end;

class procedure TACLApplication.Minimize;
begin
{$IFDEF MSWINDOWS}
  SendMessage(GetHandle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
{$ELSE}
  Application.Minimize;
{$ENDIF}
end;

class procedure TACLApplication.PostTerminate;
begin
{$IFDEF MSWINDOWS}
  if Application.MainForm <> nil then
    PostMessage(Application.MainFormHandle, WM_CLOSE, 0, 0)
  else
    PostQuitMessage(0);
{$ELSE}
  if Application.MainForm <> nil then
    Application.MainForm.Close
  else
    Application.Terminate;
{$ENDIF}
end;

class procedure TACLApplication.RestoreIfMinimized;
begin
  if IsMinimized then
  {$IFDEF MSWINDOWS}
    SendMessage(GetHandle, WM_SYSCOMMAND, SC_RESTORE, 0);
  {$ELSE}
    Application.Restore;
  {$ENDIF}
end;

{$IFDEF FPC}
class procedure TACLApplication.DefaultFontChanged(Sender: TObject);
begin
  Changed([acDefaultFont]);
end;
{$ENDIF}

class procedure TACLApplication.SetColorSchema(const AValue: TACLColorSchema);
begin
  if FColorSchema <> AValue then
  begin
    FColorSchema := AValue;
    FColorSchemaUseNative := False;
    Changed([acColorSchema]);
  end;
end;

class procedure TACLApplication.SetColorSchemaUseNative(AValue: Boolean);
begin
  if FColorSchemaUseNative <> AValue then
  begin
    FColorSchemaUseNative := AValue;
    if ColorSchemaUseNative then
      UpdateColorSet;
  end;
end;

class procedure TACLApplication.SetDarkMode(AValue: TACLBoolean);
begin
  if FDarkMode <> AValue then
  begin
    FDarkMode := AValue;
    UpdateColorSet;
  end;
end;

class procedure TACLApplication.SetTargetDPI(AValue: Integer);
begin
  if AValue <> 0 then
    AValue := EnsureRange(AValue, acMinDpi, acMaxDpi);
  if AValue <> FTargetDPI then
  begin
    FTargetDPI := AValue;
    Changed([acScalingMode]);
  end;
end;

{ TACLApplicationController }

function TACLApplicationController.GetDarkMode: TACLBoolean;
begin
  Result := TACLApplication.DarkMode;
end;

function TACLApplicationController.GetTargetDPI: Integer;
begin
  Result := TACLApplication.TargetDPI;
end;

procedure TACLApplicationController.SetDarkMode(AValue: TACLBoolean);
begin
  TACLApplication.DarkMode := AValue;
end;

procedure TACLApplicationController.SetTargetDPI(AValue: Integer);
begin
  TACLApplication.TargetDPI := AValue;
end;

end.
