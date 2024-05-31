{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*           Progress Box Control            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.ProgressBox;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.Messages,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}Types,
  {System.}SysUtils,
  System.UITypes,
  // Vcl
  {Vcl.}Graphics,
  {Vcl.}Controls,
  {Vcl.}Forms,
  // ACL
  ACL.Classes,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.Timers,
  ACL.Threading,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ProgressBar,
  ACL.UI.Resources,
  ACL.Utils.DPIAware;

type

  { TACLStyleProgressBox }

  TACLStyleProgressBox = class(TACLStyle)
  protected
    procedure InitializeResources; override;
  public
    procedure Draw(ACanvas: TCanvas; const R: TRect);
  published
    property ColorBorder1: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorBorder2: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorContent: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorCover: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
    property ColorText: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLProgressBox }

  TACLProgressBoxOption = (pboAllowCancel);
  TACLProgressBoxOptions = set of TACLProgressBoxOption;

  TACLProgressBox = class(TACLCustomControl)
  strict private
    FBoxRect: TRect;
    FCancelButton: TACLButton;
    FCancelled: Boolean;
    FDelayShow: Cardinal;
    FDelayTimer: TACLTimer;
    FEnabledControls: TList;
    FLastUpdateTime: Cardinal;
    FOptions: TACLProgressBoxOptions;
    FProgress: TACLProgressBar;
    FProgressActive: Boolean;
    FSavedFocus: THandle;
    FStyle: TACLStyleProgressBox;
    FText: array[0..3] of string;

    FOnCancel: TNotifyEvent;
    FOnFinish: TNotifyEvent;
    FOnProgress: TNotifyEvent;
    FOnStart: TNotifyEvent;

    function GetActualCoverColor: TAlphaColor;
    function GetProgressTitle: string;
    function GetProgressValue: Single;
    function GetStyleButton: TACLStyleButton;
    function GetStyleProgress: TACLStyleProgress;
    function GetText(Index: Integer): string;
    function GetTextArea: TRect;
    function GetTextStored(Index: Integer): Boolean;
    procedure SetStyle(const Value: TACLStyleProgressBox);
    procedure SetStyleButton(const Value: TACLStyleButton);
    procedure SetStyleProgress(const Value: TACLStyleProgress);
    procedure SetText(Index: Integer; const AValue: string);
  protected
    procedure CalculateControlsPosition;
    procedure CalculateLineRects(const R: TRect; const S1, S2: string; out L1, L2: TRect);
    procedure CreateControls;
    procedure SetTargetDPI(AValue: Integer); override;

    procedure DoCancel;
    procedure DoCancelClick(Sender: TObject);
    procedure DoDelayTimer(Sender: TObject);

    procedure DrawTextArea(ACanvas: TCanvas; R: TRect);
    procedure InvalidateTextBox;
    procedure Paint; override;
    procedure ParentLock;
    procedure ParentUnLock;
    procedure ResourceCollectionChanged; override;
    procedure ShowProgressBox;
    //
    property BoxRect: TRect read FBoxRect;
    property ProgressTitle: string read GetProgressTitle;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Cancel(AWaitForStop: Boolean);
    function Progress(AProgress: Single): Boolean; overload;
    function Progress(ACurrentIndex, ATotalIndexCount: Integer): Boolean; overload;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure StartProgress(AShowBoxNow: Boolean; AOptions: TACLProgressBoxOptions); overload;
    procedure StartProgress(AShowBoxNow: Boolean = False); overload;
    procedure StopProgress;
    //# Properties
    property ProgressActive: Boolean read FProgressActive;
    property ProgressMessage: string index 0 read GetText write SetText;
    property ProgressValue: Single read GetProgressValue;
  published
    property DelayShow: Cardinal read FDelayShow write FDelayShow default 1000;
    property DoubleBuffered default True;
    property Options: TACLProgressBoxOptions read FOptions write FOptions default [pboAllowCancel];
    property ResourceCollection;
    property Style: TACLStyleProgressBox read FStyle write SetStyle;
    property StyleButton: TACLStyleButton read GetStyleButton write SetStyleButton;
    property StyleProgress: TACLStyleProgress read GetStyleProgress write SetStyleProgress;
    property TextButtonCancel: string index 1 read GetText write SetText stored GetTextStored;
    property TextProgressSuffix: string index 2 read GetText write SetText stored GetTextStored;
    property TextWaitingModeTitle: string index 3 read GetText write SetText stored GetTextStored;
    property Visible default False;
    //# Event
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
    property OnFinish: TNotifyEvent read FOnFinish write FOnFinish;
    property OnProgress: TNotifyEvent read FOnProgress write FOnProgress;
    property OnStart: TNotifyEvent read FOnStart write FOnStart;
  end;

implementation

uses
  ACL.Geometry,
  ACL.Utils.Common;

const
  sTextCancel = 'Cancel';
  sTextReady = 'Ready...';

{ TACLStyleProgressBox }

procedure TACLStyleProgressBox.Draw(ACanvas: TCanvas; const R: TRect);
begin
  acFillRect(ACanvas, R, ColorContent.Value);
  acDrawComplexFrame(ACanvas, R, ColorBorder1.Value, ColorBorder2.Value);
end;

procedure TACLStyleProgressBox.InitializeResources;
begin
  ColorBorder1.InitailizeDefaults('ProgressBox.Colors.Border1', True);
  ColorBorder2.InitailizeDefaults('ProgressBox.Colors.Border2', True);
  ColorContent.InitailizeDefaults('ProgressBox.Colors.Content', True);
  ColorCover.InitailizeDefaults('ProgressBox.Colors.Cover', True);
  ColorText.InitailizeDefaults('ProgressBox.Colors.Text');
end;

{ TACLProgressBox }

constructor TACLProgressBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FText[1] := sTextCancel;
  FText[2] := sTextReady;
  FDefaultSize := TSize.Create(330, 140);
  FStyle := TACLStyleProgressBox.Create(Self);
  FEnabledControls := TList.Create;
  FOptions := [pboAllowCancel];
  FDelayShow := 1000;
  DoubleBuffered := True;
  Visible := False;
  TabStop := True;
  CreateControls;
end;

destructor TACLProgressBox.Destroy;
begin
  FreeAndNil(FEnabledControls);
  FreeAndNil(FDelayTimer);
  FreeAndNil(FStyle);
  inherited Destroy;;
end;

procedure TACLProgressBox.CreateControls;
begin
  FDelayTimer := TACLTimer.CreateEx(DoDelayTimer);

  FProgress := TACLProgressBar.Create(Self);
  FProgress.Parent := Self;

  FCancelButton := TACLButton.Create(Self);
  FCancelButton.Parent := Self;
  FCancelButton.OnClick := DoCancelClick;
  FCancelButton.Caption := TextButtonCancel;
  FCancelButton.Cursor := crHandPoint;
end;

procedure TACLProgressBox.DoCancel;
begin
  if Assigned(OnCancel) then OnCancel(Self);
end;

procedure TACLProgressBox.DoCancelClick(Sender: TObject);
begin
  Cancel(False);
end;

procedure TACLProgressBox.DoDelayTimer(Sender: TObject);
begin
  FDelayTimer.Enabled := False;
  ShowProgressBox;
end;

procedure TACLProgressBox.CalculateControlsPosition;
begin
  FBoxRect := ClientRect;
  FBoxRect.CenterHorz(dpiApply(330, FCurrentPPI));
  FBoxRect.CenterVert(dpiApply(140, FCurrentPPI));
  if Assigned(FProgress) then
  begin
    FProgress.SetBounds(
      BoxRect.Left + dpiApply(10, FCurrentPPI),
      BoxRect.Top + dpiApply(76, FCurrentPPI),
      dpiApply(311, FCurrentPPI), dpiApply(18, FCurrentPPI));
  end;
  if Assigned(FCancelButton) then
  begin
    FCancelButton.SetBounds(
      BoxRect.Left + dpiApply(108, FCurrentPPI),
      BoxRect.Top + dpiApply(104, FCurrentPPI),
      dpiApply(120, FCurrentPPI), dpiApply(25, FCurrentPPI));
  end;
end;

procedure TACLProgressBox.CalculateLineRects(const R: TRect; const S1, S2: string; out L1, L2: TRect);
begin
  L1 := R;
  if S1 = '' then
    L1.Bottom := L1.Top;
  if S2 = '' then
    L2 := NullRect
  else
  begin
    L2 := R;
    L1.Bottom := L1.Top + L1.Height div 2;
    L2.Top := L1.Bottom;
  end;
end;

procedure TACLProgressBox.DrawTextArea(ACanvas: TCanvas; R: TRect);
var
  L1, L2: TRect;
begin
  ACanvas.Font.Assign(Font);
  ACanvas.Font.Color := Style.ColorText.AsColor;
  ACanvas.Brush.Style := bsClear;
  R.Inflate(-4);
  CalculateLineRects(R, ProgressTitle, ProgressMessage, L1, L2);
  acTextDraw(ACanvas, ProgressMessage, L2, taLeftJustify, taVerticalCenter, True);
  ACanvas.Font.Style := [fsBold];
  acTextDraw(ACanvas, ProgressTitle, L1, taCenter, taVerticalCenter, True);
end;

procedure TACLProgressBox.Paint;
begin
  Style.Draw(Canvas, BoxRect);
  DrawTextArea(Canvas, GetTextArea);
  acExcludeFromClipRegion(Canvas.Handle, BoxRect);
  if acRectVisible(Canvas, ClientRect) then
  begin
    acDrawTransparentControlBackground(Self, Canvas.Handle, ClientRect);
    acFillRect(Canvas, ClientRect, GetActualCoverColor);
  end;
end;

procedure TACLProgressBox.ParentLock;
var
  AControl: TControl;
  I: Integer;
begin
  FEnabledControls.Clear;
  for I := Parent.ControlCount - 1 downto 0 do
  begin
    AControl := Parent.Controls[I];
    if (AControl <> Self) and AControl.Enabled then
    begin
      AControl.Enabled := False;
      FEnabledControls.Add(AControl);
    end;
  end;
end;

procedure TACLProgressBox.ParentUnLock;
var
  I: Integer;
begin
  for I := FEnabledControls.Count - 1 downto 0 do
    TControl(FEnabledControls.List[I]).Enabled := True;
  FEnabledControls.Clear;
end;

procedure TACLProgressBox.InvalidateTextBox;
begin
  InvalidateRect(GetTextArea);
end;

procedure TACLProgressBox.ResourceCollectionChanged;
begin
  inherited;
  FCancelButton.ResourceCollection := ResourceCollection;
  FProgress.ResourceCollection := ResourceCollection;
end;

procedure TACLProgressBox.ShowProgressBox;
begin
  BringToFront;
  Align := alClient;
  FCancelButton.Enabled := pboAllowCancel in Options;
  Visible := True;
end;

procedure TACLProgressBox.Cancel(AWaitForStop: Boolean);
begin
  FCancelButton.Enabled := False;
  FCancelled := True;
  DoCancel;
  if AWaitForStop then
  begin
    while ProgressActive do
    begin
      Application.ProcessMessages;
      Sleep(50);
    end;
  end;
end;

procedure TACLProgressBox.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Style.SetTargetDPI(AValue);
end;

function TACLProgressBox.Progress(AProgress: Single): Boolean;
begin
  if AProgress < 0 then
  begin
    if FProgress.WaitingMode and TACLThread.IsTimeout(FLastUpdateTime, 500) then
    begin
      FCancelled := FCancelled or (GetKeyState(VK_ESCAPE) < 0);
      FLastUpdateTime := TACLThread.Timestamp;
      InvalidateTextBox;
      Application.ProcessMessages;
    end;
  end
  else
    if FProgress.WaitingMode or not SameValue(FProgress.Progress, AProgress, 0.1) then
    begin
      FProgress.WaitingMode := False;
      FProgress.Progress := AProgress;
      CallNotifyEvent(Self, OnProgress);
      InvalidateTextBox;
      Application.ProcessMessages;
    end;

  Result := not FCancelled;
end;

function TACLProgressBox.Progress(ACurrentIndex, ATotalIndexCount: Integer): Boolean;
begin
  Result := Progress(100 * (ACurrentIndex + 1) / ATotalIndexCount);
end;

procedure TACLProgressBox.StartProgress(AShowBoxNow: Boolean; AOptions: TACLProgressBoxOptions);
begin
  Options := AOptions;
  StartProgress(AShowBoxNow);
end;

procedure TACLProgressBox.StartProgress(AShowBoxNow: Boolean = False);
begin
  if not FProgressActive then
  begin
    FSavedFocus := acSaveFocus;
    ParentLock;
    FProgress.WaitingMode := True;
    FProgress.Progress := 0;
    FProgressActive := True;
    FLastUpdateTime := TACLThread.Timestamp;
    FCancelled := False;
    if AShowBoxNow then
      ShowProgressBox
    else
    begin
      FDelayTimer.Interval := DelayShow;
      FDelayTimer.Enabled := True;
    end;
    CallNotifyEvent(Self, OnStart);
  end;
end;

procedure TACLProgressBox.StopProgress;
begin
  if ProgressActive then
  begin
    ParentUnLock;
    FDelayTimer.Enabled := False;
    FProgressActive := False;
    Visible := False;
    acRestoreFocus(FSavedFocus);
    CallNotifyEvent(Self, OnFinish);
  end;
end;

function TACLProgressBox.GetText(Index: Integer): string;
begin
  Result := FText[Index];
end;

function TACLProgressBox.GetTextArea: TRect;
begin
  Result := BoxRect;
  Result.Inflate(-8, 0);
  Result := Bounds(Result.Left, Result.Top + 12, Result.Width, 55);
end;

function TACLProgressBox.GetTextStored(Index: Integer): Boolean;
begin
  case Index of
    1: Result := FText[1] <> sTextCancel;
    2: Result := FText[2] <> sTextReady;
    else
      Result := FText[Index] <> '';
  end;
end;

procedure TACLProgressBox.SetText(Index: Integer; const AValue: string);
begin
  if FText[Index] <> AValue then
  begin
    FText[Index] := AValue;
    FCancelButton.Caption := TextButtonCancel;
    InvalidateTextBox;
    //Update;
  end;
end;

function TACLProgressBox.GetProgressValue: Single;
begin
  Result := FProgress.Progress;
end;

function TACLProgressBox.GetActualCoverColor: TAlphaColor;
begin
  Result := Style.ColorCover.Value;
  if Result.A = MaxByte then // backward compatibility
    Result.A := 50;
end;

function TACLProgressBox.GetProgressTitle: string;
begin
  if FProgress.WaitingMode then
    Result := TextWaitingModeTitle
  else
    Result := FormatFloat('0.00', FProgress.Progress) + '% ' + TextProgressSuffix;
end;

function TACLProgressBox.GetStyleButton: TACLStyleButton;
begin
  Result := FCancelButton.Style;
end;

function TACLProgressBox.GetStyleProgress: TACLStyleProgress;
begin
  Result := FProgress.Style;
end;

procedure TACLProgressBox.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  CalculateControlsPosition;
end;

procedure TACLProgressBox.SetStyle(const Value: TACLStyleProgressBox);
begin
  FStyle.Assign(Value);
end;

procedure TACLProgressBox.SetStyleButton(const Value: TACLStyleButton);
begin
  FCancelButton.Style.Assign(Value);
end;

procedure TACLProgressBox.SetStyleProgress(const Value: TACLStyleProgress);
begin
  FProgress.Style.Assign(Value);
end;

end.
