uses
  Winapi.Messages,
  Winapi.Windows,
  // ACL
  ACL.Utils.Messaging,
  ACL.Utils.Registry;

type

  { TGlobalSettings }

  TGlobalSettings = class
  strict private
    FHandle: TWndHandle;
    FOnChange: TThreadMethod;
    procedure WndProc(var Message: TMessage);
  public
    constructor Create(AOnChange: TThreadMethod);
    destructor Destroy; override;
    function GetColorAccent: TAlphaColor;
    procedure GetDarkMode(out ADarkModeForApps, ADarkModeForSystem: Boolean);
  end;

  { TGlobalSettings }

  constructor TGlobalSettings.Create(AOnChange: TThreadMethod);
  begin
    FOnChange := AOnChange;
    FHandle := acWndAlloc(WndProc, ClassName);
  end;

  destructor TGlobalSettings.Destroy;
  begin
    acWndFree(FHandle);
    inherited;
  end;

  function TGlobalSettings.GetColorAccent: TAlphaColor;
  var
    LKey: HKEY;
  begin
    if acRegOpenRead(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\DWM\', LKey) then
    try
      Result := acRegReadInt(LKey, 'AccentColor');
      Result := TAlphaColor.FromARGB(Result.A, Result.B, Result.G, Result.R);
    finally
      acRegClose(LKey);
    end
    else
      Result := TAlphaColor.Default;
  end;

  procedure TGlobalSettings.GetDarkMode(out ADarkModeForApps, ADarkModeForSystem: Boolean);
  var
    LKey: HKEY;
  begin
    if acRegOpenRead(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize', LKey) then
    try
      ADarkModeForApps := acRegReadInt(LKey, 'AppsUseLightTheme', 1) = 0;
      ADarkModeForSystem := acRegReadInt(LKey, 'SystemUsesLightTheme', 1) = 0;
    finally
      acRegClose(LKey);
    end
    else
    begin
      ADarkModeForSystem := TACLColors.IsDark(ColorToRGB(clWindow));
      ADarkModeForApps := ADarkModeForSystem;
    end;
  end;

  procedure TGlobalSettings.WndProc(var Message: TMessage);
  begin
    try
      if Message.Msg = WM_SYSCOLORCHANGE then
        FOnChange();
      if Message.Msg = WM_SETTINGCHANGE then
      begin
        FSystemDpiCache := 0;
        if lstrcmp(TWMSettingChange(Message).Section, 'ImmersiveColorSet') = 0 then
          FOnChange();
      end;
    except
      // do nothing
    end;
    acWndDefaultProc(FHandle, Message);
  end;
