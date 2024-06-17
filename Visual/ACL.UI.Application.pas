////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Application Controller
//
//  Author:    Artem Izmaylov
//             © 2006-2024
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
{$ELSE}
  {Winapi.}Messages,
  {Winapi.}Windows,
{$ENDIF}
  // System
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
  ACL.Utils.Common;

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
    DefaultHideHintPause = 10000;
  strict private
    class var FActualAccentColor: TAlphaColor;
    class var FActualDarkMode: Boolean;
    class var FActualDarkModeForSystem: Boolean;
    class var FColorSchema: TACLColorSchema;
    class var FColorSchemaUseNative: Boolean;
    class var FDarkMode: TACLBoolean;
    class var FDefaultFont: TFont;
    class var FListeners: TACLListenerList;
    class var FTargetDPI: Integer;

  {$IFDEF FPC}
    class procedure DefaultFontChanged(Sender: TObject);
  {$ENDIF}
    class function DecodeColorScheme(const AValue: Word): TACLColorSchema;
    class function EncodeColorScheme(const AValue: TACLColorSchema): Word;
    class function GetDefaultFont: TFont; static;
    class function GetNativeColorAccent: TAlphaColor;
    class procedure GetNativeDarkMode(out ADarkModeForApps, ADarkModeForSystem: Boolean);
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

    class function GetHandle: HWND;
    class function IsMinimized: Boolean;
    class procedure Minimize;
    class procedure PostTerminate;
    class procedure RestoreIfMinimized;

    class function GetActualColor(ALightColor, ADarkColor: TColor): TColor; overload;
    class function GetActualColor(ALightColor, ADarkColor: TAlphaColor): TAlphaColor; overload;
    class function GetTargetDPI(AControl: TWinControl): Integer;
    class function IsDarkMode: Boolean;
    class function IsDarkModeOfSystemBar: Boolean;

    class property AccentColor: TAlphaColor read FActualAccentColor;
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

uses
{$IFDEF MSWINDOWS}
  ACL.Utils.Registry,
{$ENDIF}
  ACL.Utils.DPIAware;

{ TACLApplication }

class constructor TACLApplication.Create;
begin
  UpdateColorSet;
end;

class destructor TACLApplication.Destroy;
begin
  FreeAndNil(FDefaultFont);
end;

class procedure TACLApplication.ConfigLoad(AConfig: TACLIniFile; const ASection: string);
begin
  TargetDPI := AConfig.ReadInteger(ASection, 'TargetDPI');
  DarkMode := AConfig.ReadEnum<TACLBoolean>(ASection, 'DarkMode', TACLBoolean.Default);
  ColorSchema := DecodeColorScheme(AConfig.ReadInteger(ASection, 'ColorSchema'));
  ColorSchemaUseNative := AConfig.ReadBool(ASection, 'UseNativeColorSchema');
  Application.HintHidePause := AConfig.ReadInteger(ASection, 'HideHintPause', DefaultHideHintPause);
  Application.ShowHint := Application.HintHidePause > 0;
end;

class procedure TACLApplication.ConfigSave(AConfig: TACLIniFile; const ASection: string);
begin
  AConfig.WriteInteger(ASection, 'ColorSchema', EncodeColorScheme(ColorSchema), 0);
  AConfig.WriteInteger(ASection, 'TargetDPI', TargetDPI, 0);
  AConfig.WriteInteger(ASection, 'HideHintPause', Application.HintHidePause, DefaultHideHintPause);
  AConfig.WriteEnum<TACLBoolean>(ASection, 'DarkMode', DarkMode, TACLBoolean.Default);
  AConfig.WriteBool(ASection, 'UseNativeColorSchema', ColorSchemaUseNative, False);
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

class procedure TACLApplication.Changed(AChanges: TACLApplicationChanges);
begin
  if (FListeners <> nil) and (AChanges <> []) then
    FListeners.Enum<IACLApplicationListener>(
      procedure (const AIntf: IACLApplicationListener)
      begin
        AIntf.Changed(AChanges);
      end);
end;

class procedure TACLApplication.SetDefaultFont(AName: TFontName; AHeight: Integer);
begin
  TACLFontCache.RemapFont(AName, AHeight);
  AHeight := MulDiv(AHeight, acGetSystemDpi, acDefaultDpi);
  DefaultFont.Name := AName;
  DefaultFont.Height := AHeight;
  DefFontData.Height := AHeight;
end;

class procedure TACLApplication.UpdateColorSet;
var
  AActualAccentColor: TAlphaColor;
  AActualColorSchema: TACLColorSchema;
  AActualDarkMode: Boolean;
  AActualDarkModeForSystem: Boolean;
  AChanges: TACLApplicationChanges;
begin
  AChanges := [];

  GetNativeDarkMode(AActualDarkMode, AActualDarkModeForSystem);
  case DarkMode of
    TACLBoolean.True:
      AActualDarkMode := True;
    TACLBoolean.False:
      AActualDarkMode := False;
  else;
  end;

  AActualAccentColor := GetNativeColorAccent;
  if AActualAccentColor <> FActualAccentColor then
  begin
    FActualAccentColor := AActualAccentColor;
    Include(AChanges, acAccentColor);
  end;

  if ColorSchemaUseNative then
  begin
    AActualColorSchema := TACLColorSchema.CreateFromColor(AccentColor);
    if AActualColorSchema <> FColorSchema then
    begin
      FColorSchema := AActualColorSchema;
      Include(AChanges, acColorSchema);
    end;
  end;

  if AActualDarkModeForSystem <> FActualDarkModeForSystem then
  begin
    FActualDarkModeForSystem := AActualDarkModeForSystem;
    Include(AChanges, acDarkModeForSystem);
  end;

  if AActualDarkMode <> FActualDarkMode then
  begin
    FActualDarkMode := AActualDarkMode;
    Include(AChanges, acDarkMode);
    if ColorSchema.IsAssigned then
      Include(AChanges, acColorSchema);
  end;

  if AChanges <> [] then
    Changed(AChanges);
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

class function TACLApplication.DecodeColorScheme(const AValue: Word): TACLColorSchema;
begin
  if AValue = 0 then
    Result := TACLColorSchema.Default
  else
    Result := TACLColorSchema.Create(AValue and $FF, AValue shr 8);
end;

class function TACLApplication.EncodeColorScheme(const AValue: TACLColorSchema): Word;
begin
  if AValue.IsAssigned then
    Result := MakeWord(AValue.Hue, AValue.HueIntensity)
  else
    Result := 0;
end;

class function TACLApplication.GetNativeColorAccent: TAlphaColor;
{$IFDEF MSWINDOWS}
var
  AKey: HKEY;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  if acRegOpenRead(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\DWM\', AKey) then
  try
    Result := acRegReadInt(AKey, 'AccentColor');
    Result := TAlphaColor.FromARGB(Result.A, Result.B, Result.G, Result.R);
  finally
    acRegClose(AKey);
  end
  else
{$ENDIF}
    Result := TAlphaColor.Default;
end;

class procedure TACLApplication.GetNativeDarkMode(out ADarkModeForApps, ADarkModeForSystem: Boolean);
{$IFDEF MSWINDOWS}
var
  AKey: HKEY;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  if acRegOpenRead(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize', AKey) then
  try
    ADarkModeForApps := acRegReadInt(AKey, 'AppsUseLightTheme', 1) = 0;
    ADarkModeForSystem := acRegReadInt(AKey, 'SystemUsesLightTheme', 1) = 0;
  finally
    acRegClose(AKey);
  end
  else
{$ENDIF}
  begin
    ADarkModeForApps := False;
    ADarkModeForSystem := False;
  end;
end;

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
