{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*         HintWindow Implementation         *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.HintWindow;

{$I ACL.Config.inc}

interface

uses
  Winapi.DwmApi,
  Winapi.Messages,
  Winapi.Windows,
  // System
  System.Types,
  System.Classes,
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  // ACL
  ACL.Classes.Timer,
  ACL.Geometry,
  ACL.Utils.DPIAware,
  ACL.UI.PopupMenu,
  ACL.UI.Resources;

const
  HintTextDrawFlags = DT_NOPREFIX or DT_WORDBREAK;
  HintTextIndentH = 8;
  HintTextIndentV = 5;

type
  TACLHintWindowHorzAlignment = (hwhaLeft, hwhaCenter, hwhaRight);
  TACLHintWindowVertAlignment = (hwvaAbove, hwvaOver, hwvaBelow);

  { TACLHintData }

  TACLHintData = record
    AlignHorz: TACLHintWindowHorzAlignment;
    AlignVert: TACLHintWindowVertAlignment;
    DelayBeforeShow: Cardinal;
    ScreenBounds: TRect;
    Text: UnicodeString;

    class operator Equal(const V1, V2: TACLHintData): Boolean;
    class operator NotEqual(const V1, V2: TACLHintData): Boolean;
    procedure Reset;
  end;

  { TACLStyleHint }

  TACLStyleHint = class(TACLStyle)
  strict private
    FRadius: Integer;
  protected
    procedure InitializeResources; override;
  public
    procedure AfterConstruction; override;
    function CreateRegion(const R: TRect): HRGN;
    procedure Draw(ACanvas: TCanvas; const R: TRect);
    //
    property Radius: Integer read FRadius;
  published
    property ColorBorder: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorContent1: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorContent2: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorText: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLHintWindow }

  TACLHintWindow = class(THintWindow)
  strict private const
    HeightCorrection = 4;
  strict private
    FScaleFactor: TACLScaleFactor;
    FStyle: TACLStyleHint;
    FTextChanging: Boolean;

    function GetPixelsPerInch: Integer; reintroduce;
    procedure SetStyle(AValue: TACLStyleHint);
    //
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure NCPaint(DC: HDC); override;
    procedure Paint; override;
    procedure PaintBackground(ACanvas: TCanvas; const R: TRect); virtual;
    procedure PaintText(ACanvas: TCanvas; R: TRect); virtual;
    procedure ScaleForPPI(const ATargetPPI: Integer); reintroduce;
    //
    property PixelsPerInch: Integer read GetPixelsPerInch;
    property ScaleFactor: TACLScaleFactor read FScaleFactor;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ActivateHint(Rect: TRect; const AHint: string); override;
    function CalcHintRect(MaxWidth: Integer; const AHint: string; AData: TCustomData): TRect; overload; override;
    procedure Hide;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    //
    procedure ShowFloatHint(const AHint: UnicodeString; const AScreenRect: TRect;
      AHorzAlignment: TACLHintWindowHorzAlignment; AVertAligment: TACLHintWindowVertAlignment); overload;
    procedure ShowFloatHint(const AHint: UnicodeString; const AControl: TControl;
      AHorzAlignment: TACLHintWindowHorzAlignment; AVertAligment: TACLHintWindowVertAlignment); overload;
    procedure ShowFloatHint(const AHint: UnicodeString; const P: TPoint); overload;
    //
    property Style: TACLStyleHint read FStyle write SetStyle;
  end;

  { TACLHintController }

  TACLHintPauseMode = (hpmBeforeShow, hpmBeforeHide);

  TACLHintController = class
  strict private
    FDeactivateTimer: TACLTimer;
    FHintData: TACLHintData;
    FHintOwner: TObject;
    FHintPoint: TPoint;
    FHintWindow: TACLHintWindow;
    FPauseMode: TACLHintPauseMode;
    FPauseTimer: TACLTimer;

    function CanShowHintOverOwner: Boolean;
    function IsFormActive(AForm: TCustomForm): Boolean;
    procedure DeactivateTimerHandler(Sender: TObject);
    procedure PauseTimerHandler(Sender: TObject);
  protected
    function CanShowHint(AHintOwner: TObject; const AHintData: TACLHintData): Boolean; virtual;
    function CreateHintWindow: TACLHintWindow; virtual;
    function GetOwnerForm: TCustomForm; virtual;
    //
    property HintData: TACLHintData read FHintData;
    property HintOwner: TObject read FHintOwner;
    property HintPoint: TPoint read FHintPoint;
    property HintWindow: TACLHintWindow read FHintWindow;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Cancel;
    procedure Hide;
    procedure Update(AHintOwner: TObject; const AHintPoint: TPoint; const AHintData: TACLHintData);
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  // ACL
  ACL.Classes,
  ACL.Graphics,
  ACL.Utils.Common,
  ACL.Utils.Desktop;

type
  TCustomFormAccess = class(TCustomForm);

{ Return number of scanlines between the scanline containing cursor hotspot and the last scanline included in the cursor mask. }
function GetCursorHeightMargin: Integer;
var
  IconInfo: TIconInfo;
  BitmapInfoSize, BitmapBitsSize, ImageSize: DWORD;
  Bitmap: PBitmapInfoHeader;
  Bits: Pointer;
  BytesPerScanline: Integer;

  function FindScanline(Source: Pointer; MaxLen: Cardinal; Value: Cardinal): Cardinal;
  var
    P: PByte;
  begin
    P := Source;
    Result := MaxLen;
    while (Result > 0) and (P^ = Value) do
    begin
      Inc(P);
      Dec(Result);
    end;
  end;

begin
  { Default value is entire icon height }
  Result := GetSystemMetrics(SM_CYCURSOR);
  if GetIconInfo(GetCursor, IconInfo) then
  try
    GetDIBSizes(IconInfo.hbmMask, BitmapInfoSize, BitmapBitsSize);
    Bitmap := AllocMem(BitmapInfoSize + BitmapBitsSize);
    try
    Bits := Pointer(PByte(Bitmap) + BitmapInfoSize);
    if GetDIB(IconInfo.hbmMask, 0, Bitmap^, Bits^) and
      (Bitmap^.biBitCount = 1) then
    begin
      { Point Bits to the end of this bottom-up bitmap }
      with Bitmap^ do
      begin
        BytesPerScanline := ((biWidth * biBitCount + 31) and not 31) div 8;
        ImageSize := biWidth * BytesPerScanline;
        Bits := Pointer(PByte(Bits) + BitmapBitsSize - ImageSize);
        { Use the width to determine the height since another mask bitmap may immediately follow }
        Result := FindScanline(Bits, ImageSize, $FF);
        { In case the and mask is blank, look for an empty scanline in the xor mask. }
        if (Result = 0) and (biHeight >= 2 * biWidth) then
          Result := FindScanline(Pointer(PByte(Bits) - ImageSize),
          ImageSize, $00);
        Result := Result div BytesPerScanline;
      end;
      Dec(Result, IconInfo.yHotSpot);
      Result := System.Math.Max(Result, 1)
    end;
    finally
      FreeMem(Bitmap, BitmapInfoSize + BitmapBitsSize);
    end;
  finally
    if IconInfo.hbmColor <> 0 then
      DeleteObject(IconInfo.hbmColor);
    if IconInfo.hbmMask <> 0 then
      DeleteObject(IconInfo.hbmMask);
  end;
end;

{ TACLHintData }

class operator TACLHintData.Equal(const V1, V2: TACLHintData): Boolean;
begin
  Result := (V1.AlignHorz = V2.AlignHorz) and (V1.AlignVert = V2.AlignVert) and
    (V1.DelayBeforeShow = V2.DelayBeforeShow) and (V1.ScreenBounds = V2.ScreenBounds) and
    (V1.Text = V2.Text);
end;

class operator TACLHintData.NotEqual(const V1, V2: TACLHintData): Boolean;
begin
  Result := not (V1 = V2);
end;

procedure TACLHintData.Reset;
begin
  AlignHorz := hwhaLeft;
  AlignVert := hwvaOver;
  DelayBeforeShow := Application.HintPause;
  ScreenBounds := NullRect;
  Text := EmptyStr;
end;

{ TACLStyleHint }

procedure TACLStyleHint.AfterConstruction;
begin
  inherited AfterConstruction;
  FRadius := IfThen(not IsWin8OrLater, 3);
end;

function TACLStyleHint.CreateRegion(const R: TRect): HRGN;
begin
  if Radius > 0 then
    Result := CreateRoundRectRgn(R.Left + 1, R.Top + 1, R.Right, R.Bottom, Radius, Radius)
  else
    Result := 0;
end;

procedure TACLStyleHint.Draw(ACanvas: TCanvas; const R: TRect);
begin
  acDrawGradient(ACanvas.Handle, R, ColorContent1.AsColor, ColorContent2.AsColor);
  if IsWin8OrLater then
    acDrawFrame(ACanvas.Handle, R, ColorBorder.AsColor)
  else
  begin
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Color := ColorBorder.AsColor;
    ACanvas.RoundRect(R.Left + 1, R.Top + 1, R.Right - 1, R.Bottom - 1, 6, 6);
    ACanvas.RoundRect(R.Left + 1, R.Top + 1, R.Right - 1, R.Bottom - 1, 3, 3);
  end;
end;

procedure TACLStyleHint.InitializeResources;
begin
  inherited InitializeResources;
  ColorBorder.InitailizeDefaults('Hint.Colors.Border');
  ColorContent1.InitailizeDefaults('Hint.Colors.Background1');
  ColorContent2.InitailizeDefaults('Hint.Colors.Background2');
  ColorText.InitailizeDefaults('Hint.Colors.Text');
end;

{ TACLHintWindow }

constructor TACLHintWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DoubleBuffered := True;
  FScaleFactor := TACLScaleFactor.Create;
  FStyle := TACLStyleHint.Create(Self);
  ScaleForPPI(Screen.PixelsPerInch);
  Font := Screen.HintFont; // after ScaleForPPI
end;

destructor TACLHintWindow.Destroy;
begin
  FreeAndNil(FScaleFactor);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLHintWindow.ActivateHint(Rect: TRect; const AHint: string);
var
  AMonitor: TACLMonitor;
  AMonitorBounds: TRect;
begin
  if (AHint <> Caption) or not IsWindowVisible(Handle) then
  begin
    AMonitor := MonitorGet(Rect.TopLeft);
    if AMonitor.PixelsPerInch <> PixelsPerInch then
    begin
      ScaleForPPI(AMonitor.PixelsPerInch);
      Rect := acRectOffset(CalcHintRect(Screen.Width div 3, AHint, nil), Rect.TopLeft);
    end;

    Caption := AHint;
    Inc(Rect.Bottom, 4);
    UpdateBoundsRect(Rect);

    AMonitorBounds := AMonitor.BoundsRect;
    Rect.Top := Min(Rect.Top,  AMonitorBounds.Bottom - Height);
    Rect.Top := Max(Rect.Top, AMonitorBounds.Top);
    Rect.Left := Min(Rect.Left, AMonitorBounds.Right - Width);
    Rect.Left := Max(Rect.Left, AMonitorBounds.Left);

    SetWindowPos(Handle, HWND_TOPMOST, Rect.Left, Rect.Top, Width, Height, SWP_NOACTIVATE);
    ShowWindow(Handle, SW_SHOWNOACTIVATE);
    Invalidate;
  end;
end;

function TACLHintWindow.CalcHintRect(MaxWidth: Integer; const AHint: string; AData: TCustomData): TRect;
begin
  MeasureCanvas.Font := Font;
  Result := Rect(0, 0, MaxWidth, 2);
  acSysDrawText(MeasureCanvas, Result, AHint, DT_CALCRECT or HintTextDrawFlags);
  Result := acRectOffsetNegative(Result, Result.TopLeft);
  Inc(Result.Right, 2 * ScaleFactor.Apply(HintTextIndentH));
  Inc(Result.Bottom, 2 * ScaleFactor.Apply(HintTextIndentV));
  Dec(Result.Bottom, HeightCorrection);
end;

procedure TACLHintWindow.Hide;
const
  SWP_FLAGS = SWP_NOACTIVATE or SWP_NOSIZE or SWP_NOMOVE or SWP_NOZORDER;
begin
  SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_HIDEWINDOW or SWP_FLAGS);
end;

procedure TACLHintWindow.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if not FTextChanging then
    inherited SetBounds(ALeft, ATop, AWidth, AHeight);
end;

procedure TACLHintWindow.ShowFloatHint(const AHint: UnicodeString; const AScreenRect: TRect;
  AHorzAlignment: TACLHintWindowHorzAlignment; AVertAligment: TACLHintWindowVertAlignment);
const
  Indent = 6;
var
  AHintPos: TPoint;
  AHintSize: TSize;
begin
  ScaleForPPI(MonitorGet(AScreenRect.TopLeft).PixelsPerInch);
  AHintPos.X := AScreenRect.Left - ScaleFactor.Apply(HintTextIndentH);
  AHintPos.Y := AScreenRect.Top - ScaleFactor.Apply(HintTextIndentV);
  AHintSize := acSize(CalcHintRect(Screen.Width div 3, AHint, nil));

  case AHorzAlignment of
    hwhaRight:
      AHintPos.X := (AScreenRect.Right - AHintSize.cx);
    hwhaCenter:
      AHintPos.X := (AScreenRect.Right + AScreenRect.Left - AHintSize.cx) div 2;
  end;

  case AVertAligment of
    hwvaAbove:
      AHintPos.Y := AScreenRect.Top - (AHintSize.cy + HeightCorrection) - ScaleFactor.Apply(Indent);
    hwvaBelow:
      AHintPos.Y := AScreenRect.Bottom + ScaleFactor.Apply(Indent);
    hwvaOver:
      AHintPos.Y := (AScreenRect.Bottom + AScreenRect.Top - (AHintSize.cy + HeightCorrection)) div 2;
  end;

  ActivateHint(Bounds(AHintPos.X, AHintPos.Y, AHintSize.cx, AHintSize.cy), AHint);
end;

procedure TACLHintWindow.ShowFloatHint(const AHint: UnicodeString; const P: TPoint);
begin
  ActivateHint(acRectSetPos(CalcHintRect(Screen.Width div 3, AHint, nil), P), AHint);
end;

procedure TACLHintWindow.ShowFloatHint(const AHint: UnicodeString; const AControl: TControl;
  AHorzAlignment: TACLHintWindowHorzAlignment; AVertAligment: TACLHintWindowVertAlignment);
begin
  ShowFloatHint(AHint, acRectOffset(AControl.ClientRect, AControl.ClientToScreen(NullPoint)), AHorzAlignment, AVertAligment);
end;

procedure TACLHintWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP;
end;

procedure TACLHintWindow.NCPaint(DC: HDC);
begin
  // do nothing
end;

procedure TACLHintWindow.Paint;
begin
  PaintBackground(Canvas, ClientRect);
  PaintText(Canvas,
    acRectInflate(ClientRect,
      -ScaleFactor.Apply(HintTextIndentH),
      -ScaleFactor.Apply(HintTextIndentV)));
end;

procedure TACLHintWindow.PaintBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Draw(ACanvas, R);
end;

procedure TACLHintWindow.PaintText(ACanvas: TCanvas; R: TRect);
begin
  ACanvas.Font := Font;
  ACanvas.Font.Color := Style.ColorText.AsColor;
  acSysDrawText(ACanvas, R, Caption, HintTextDrawFlags);
end;

procedure TACLHintWindow.ScaleForPPI(const ATargetPPI: Integer);
var
  ACurrentPPI: Integer;
begin
  ACurrentPPI := PixelsPerInch;
  if ACurrentPPI <> ATargetPPI then
  begin
    ScaleFactor.Assign(ATargetPPI, acDefaultDPI);
    ChangeScale(ATargetPPI, ACurrentPPI);
    Style.SetTargetDPI(ATargetPPI);
  end;
end;

function TACLHintWindow.GetPixelsPerInch: Integer;
begin
  Result := ScaleFactor.TargetDPI;
end;

procedure TACLHintWindow.SetStyle(AValue: TACLStyleHint);
begin
  FStyle.Assign(AValue);
end;

procedure TACLHintWindow.CMTextChanged(var Message: TMessage);
begin
  FTextChanging := True;
  inherited; //#AI: Reduce flicker, see THintWindow.CMTextChanged implementation
  FTextChanging := False;
end;

procedure TACLHintWindow.WMMouseWheel(var Message: TWMMouseWheel);
begin
  Hide;
end;

procedure TACLHintWindow.WMSize(var Message: TWMSize);
begin
  inherited;
  if HandleAllocated then
    SetWindowRgn(Handle, Style.CreateRegion(Rect(0, 0, Width, Height)), True);
end;

{ TACLHintController }

constructor TACLHintController.Create;
begin
  inherited Create;
  FPauseTimer := TACLTimer.CreateEx(PauseTimerHandler);
end;

destructor TACLHintController.Destroy;
begin
  Cancel;
  FreeAndNil(FPauseTimer);
  inherited Destroy;
end;

procedure TACLHintController.Hide;
begin
  FPauseTimer.Enabled := False;
  FreeAndNil(FDeactivateTimer);
  FreeAndNil(FHintWindow);
end;

procedure TACLHintController.Cancel;
begin
  Hide;
  FHintOwner := nil;
end;

procedure TACLHintController.Update(AHintOwner: TObject; const AHintPoint: TPoint; const AHintData: TACLHintData);
begin
  if (HintOwner <> AHintOwner) or (HintData <> AHintData) or (FHintPoint <> AHintPoint) then
  begin
    Cancel;
    if CanShowHint(AHintOwner, AHintData) then
    begin
      FHintOwner := AHintOwner;
      FHintData := AHintData;
      FPauseMode := hpmBeforeShow;
      FPauseTimer.Interval := Max(1, HintData.DelayBeforeShow);
      FPauseTimer.Enabled := True;
    end;
  end;
  FHintPoint := AHintPoint;
  FHintData := AHintData;
end;

function TACLHintController.CanShowHint(AHintOwner: TObject; const AHintData: TACLHintData): Boolean;
var
  AForm: TCustomForm;
begin
  Result := Application.ShowHint and (AHintOwner <> nil) and (AHintData.Text <> '');
  if Result then
  begin
    AForm := GetOwnerForm;
    Result := (AForm <> nil) and IsFormActive(AForm) and not acMenusHasActivePopup;
  end;
end;

function TACLHintController.CanShowHintOverOwner: Boolean;
begin
  // Otherwise cases, the hint does not want to be transparent for mouse (for some reason)
  // and prevents the user from clicking on the item
  Result := IsWinVistaOrLater and not IsWine and (not IsWinSeven or DwmCompositionEnabled);
end;

function TACLHintController.CreateHintWindow: TACLHintWindow;
begin
  Result := TACLHintWindow.Create(nil);
end;

function TACLHintController.GetOwnerForm: TCustomForm;
begin
  Result := nil;
end;

function TACLHintController.IsFormActive(AForm: TCustomForm): Boolean;
begin
  Result := (AForm <> nil) and ((AForm.ParentWindow <> 0) or AForm.Active);
end;

procedure TACLHintController.DeactivateTimerHandler(Sender: TObject);
var
  AForm: TCustomForm;
begin
  AForm := GetOwnerForm;
  if (AForm <> nil) and not IsFormActive(AForm)or not ((HintWindow <> nil) and IsWindowVisible(HintWindow.Handle)) then
    Hide;
end;

procedure TACLHintController.PauseTimerHandler(Sender: TObject);
const
  SWP_TOPMOST = SWP_SHOWWINDOW or SWP_NOSIZE or SWP_NOMOVE or SWP_NOACTIVATE;
begin
  case FPauseMode of
    hpmBeforeHide:
      Hide;
    hpmBeforeShow:
      begin
        if HintWindow = nil then
          FHintWindow := CreateHintWindow;

        if HintData.ScreenBounds.IsEmpty or (FHintData.AlignVert = hwvaOver) and not CanShowHintOverOwner then
          HintWindow.ShowFloatHint(HintData.Text, acPointOffset(HintPoint, 0, GetCursorHeightMargin))
        else
          HintWindow.ShowFloatHint(HintData.Text, HintData.ScreenBounds, HintData.AlignHorz, HintData.AlignVert);

        if FDeactivateTimer = nil then
          FDeactivateTimer := TACLTimer.CreateEx(DeactivateTimerHandler, 10, True);
        FPauseTimer.Interval := Application.HintHidePause;
        FPauseMode := hpmBeforeHide;
      end;
  end;
end;

end.
