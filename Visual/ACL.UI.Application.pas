{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*           Application Routines            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Application;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.UITypes,
  System.SysUtils,
  // VCL
  Vcl.Graphics,
  Vcl.Controls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.FileFormats.INI,
  ACL.Graphics,
  ACL.Utils.Common;

type
  TACLApplicationChange = (acDarkMode, acDarkModeForSystem, acAccentColor, acColorSchema, acScalingMode);
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
    class var FListeners: TACLListenerList;
    class var FTargetDPI: Integer;

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
    class procedure ConfigLoad(AConfig: TACLIniFile; const ASection: UnicodeString);
    class procedure ConfigSave(AConfig: TACLIniFile; const ASection: UnicodeString);
    class procedure ListenerAdd(AListener: IUnknown);
    class procedure ListenerRemove(AListener: IUnknown);
    class procedure SetDefaultFont(const AName: TFontName; AHeight: Integer);
    class procedure UpdateColorSet;

    class function GetHandle: HWND;
    class function IsMinimized: Boolean;
    class procedure ExecCommand(ASysCommand: Integer);
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
  Vcl.Forms,
  // ACL
  ACL.UI.Controls.BaseControls,
  ACL.Utils.DPIAware,
  ACL.Utils.Registry;

{ TACLApplication }

class constructor TACLApplication.Create;
begin
  UpdateColorSet;
end;

class procedure TACLApplication.ConfigLoad(AConfig: TACLIniFile; const ASection: UnicodeString);
begin
  TargetDPI := AConfig.ReadInteger(ASection, 'TargetDPI');
  DarkMode := TACLBoolean(AConfig.ReadInteger(ASection, 'DarkMode', Ord(TACLBoolean.Default)));
  ColorSchema := DecodeColorScheme(AConfig.ReadInteger(ASection, 'ColorSchema'));
  ColorSchemaUseNative := AConfig.ReadBool(ASection, 'UseNativeColorSchema');
  Application.HintHidePause := AConfig.ReadInteger(ASection, 'HideHintPause', DefaultHideHintPause);
  Application.ShowHint := Application.HintHidePause > 0;
end;

class procedure TACLApplication.ConfigSave(AConfig: TACLIniFile; const ASection: UnicodeString);
begin
  AConfig.WriteInteger(ASection, 'ColorSchema', EncodeColorScheme(ColorSchema), 0);
  AConfig.WriteInteger(ASection, 'TargetDPI', TargetDPI, 0);
  AConfig.WriteInteger(ASection, 'DarkMode', Ord(DarkMode), Ord(TACLBoolean.Default));
  AConfig.WriteInteger(ASection, 'HideHintPause', Application.HintHidePause, DefaultHideHintPause);
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
  Result := Application.DefaultFont;
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

class procedure TACLApplication.SetDefaultFont(const AName: TFontName; AHeight: Integer);
begin
  AHeight := MulDiv(AHeight, acSystemScaleFactor.TargetDPI, acDefaultDPI);
  Application.DefaultFont.Name := AName;
  Application.DefaultFont.Height := AHeight;
  DefFontData.Height := AHeight;
end;

class procedure TACLApplication.UpdateColorSet;
var
  AActualAccentColor: TAlphaColor;
  AActualColorSchema: TACLColorSchema;
  AActualDarkMode: Boolean;
  AActualDarkModeForSystem: Boolean;
  AChanges: TACLApplicationChanges;
  H, S, L: Byte;
begin
  AChanges := [];

  GetNativeDarkMode(AActualDarkMode, AActualDarkModeForSystem);
  case DarkMode of
    TACLBoolean.True:
      AActualDarkMode := True;
    TACLBoolean.False:
      AActualDarkMode := False;
  end;

  AActualAccentColor := GetNativeColorAccent;
  if AActualAccentColor <> FActualAccentColor then
  begin
    FActualAccentColor := AActualAccentColor;
    Include(AChanges, acAccentColor);
  end;

  if ColorSchemaUseNative then
  begin
    if AccentColor.IsValid then
    begin
      TACLColors.RGBtoHSLi(AccentColor.R, AccentColor.G, AccentColor.B, H, S, L);
      AActualColorSchema := TACLColorSchema.Create(H, MulDiv(100, S, MaxByte));
    end
    else
      AActualColorSchema := TACLColorSchema.Default;

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
  if Application.MainFormOnTaskBar then
    Result := Application.MainFormHandle
  else
    Result := Application.Handle;
end;

class function TACLApplication.IsMinimized: Boolean;
begin
  Result := IsIconic(GetHandle);
end;

class procedure TACLApplication.ExecCommand(ASysCommand: Integer);
begin
  SendMessage(GetHandle, WM_SYSCOMMAND, ASysCommand, 0);
end;

class procedure TACLApplication.Minimize;
begin
  ExecCommand(SC_MINIMIZE);
end;

class procedure TACLApplication.PostTerminate;
begin
  if Application.MainForm <> nil then
    PostMessage(Application.MainFormHandle, WM_CLOSE, 0, 0)
  else
    PostQuitMessage(0);
end;

class procedure TACLApplication.RestoreIfMinimized;
begin
  if IsMinimized then
    ExecCommand(SC_RESTORE);
end;

class function TACLApplication.DecodeColorScheme(const AValue: Word): TACLColorSchema;
begin
  if AValue = 0 then
    Result := TACLColorSchema.Default
  else
    Result := TACLColorSchema.Create(LoByte(AValue), HiByte(AValue));
end;

class function TACLApplication.EncodeColorScheme(const AValue: TACLColorSchema): Word;
begin
  if AValue.IsAssigned then
    Result := MakeWord(AValue.Hue, AValue.HueIntensity)
  else
    Result := 0;
end;

class function TACLApplication.GetNativeColorAccent: TAlphaColor;
var
  AKey: HKEY;
begin
  if acRegOpenRead(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\DWM\', AKey) then
  try
    Result := acRegReadInt(AKey, 'AccentColor');
    Result := TAlphaColor.FromARGB(Result.A, Result.B, Result.G, Result.R);
  finally
    acRegClose(AKey);
  end
  else
    Result := TAlphaColor.Default;
end;

class procedure TACLApplication.GetNativeDarkMode(out ADarkModeForApps, ADarkModeForSystem: Boolean);
var
  AKey: HKEY;
begin
  if acRegOpenRead(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize', AKey) then
  try
    ADarkModeForApps := acRegReadInt(AKey, 'AppsUseLightTheme', 1) = 0;
    ADarkModeForSystem := acRegReadInt(AKey, 'SystemUsesLightTheme', 1) = 0;
  finally
    acRegClose(AKey);
  end
  else
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
    AValue := acCheckDPIValue(AValue);
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
