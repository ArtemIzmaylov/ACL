////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Slider
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.Slider;

{$I ACL.Config.inc}

interface

uses
  Messages,
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.FastCode,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.Math,
  ACL.Timers,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.Buttons,
  ACL.UI.Forms,
  ACL.UI.HintWindow,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type
  TACLSlider = class;

  TACLSliderIndent = 1..10;
  TACLSliderMarkSize = 1..5;
  TACLSliderMovingState = (smaStart, smaMoving, smaStop);

  TACLSliderGetHintEvent = procedure (Sender: TObject; AValue: Single; var AHint: string) of object;

  { TACLSliderCustomOptions }

  TACLSliderCustomOptions = class(TACLCustomOptionsPersistent)
  protected
    FOwner: TACLSlider;
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
  public
    constructor Create(AOwner: TACLSlider); virtual;
  end;

  { TACLSliderOptions }

  TACLSliderOptions = class(TACLSliderCustomOptions)
  strict private
    FImmediateUpdate: Boolean;
    FMagnetToDefaultValue: Boolean;
    FMarkSize: TACLSliderMarkSize;
    FMarkVisible: Boolean;
    FTrackAreaOffset: Integer;

    procedure SetMarkSize(AValue: TACLSliderMarkSize);
    procedure SetMarkVisible(AValue: Boolean);
    procedure SetTrackAreaOffset(AValue: Integer);
  protected
    procedure DoAssign(Source: TPersistent); override;
  public
    constructor Create(AOwner: TACLSlider); override;
  published
    property ImmediateUpdate: Boolean read FImmediateUpdate write FImmediateUpdate default True;
    property MagnetToDefaultValue: Boolean read FMagnetToDefaultValue write FMagnetToDefaultValue default False;
    property MarkSize: TACLSliderMarkSize read FMarkSize write SetMarkSize default 3;
    property MarkVisible: Boolean read FMarkVisible write SetMarkVisible default True;
    property TrackAreaOffset: Integer read FTrackAreaOffset write SetTrackAreaOffset default 5;
  end;

  { TACLSliderOptionsLabels }

  TACLSliderLabelsLayout = (sllAroundEdges, sllAfterTrackBar, sllBeforeTrackBar);

  TACLSliderOptionsLabels = class(TACLSliderCustomOptions)
  strict private
    FIsCurrentValueMasked: Boolean;
    FLayout: TACLSliderLabelsLayout;
    FText: array[0..2] of string;
    FWidth: array[0..2] of Integer;

    function GetText(const Index: Integer): string;
    function GetWidth(const Index: Integer): Integer;
    procedure SetLayout(const Value: TACLSliderLabelsLayout);
    procedure SetText(const Index: Integer; const Value: string);
    procedure SetWidth(const Index: Integer; AValue: Integer);
  protected
    procedure DoAssign(Source: TPersistent); override;
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
    function FormatCurrentValue(const AValue: Single): string;
    function HasLabels: Boolean;
    function HasRangeLabels: Boolean;
    //# Properties
    property IsCurrentValueMasked: Boolean read FIsCurrentValueMasked;
  published
    property CurrentValue: string index 0 read GetText write SetText;
    property CurrentValueWidth: Integer index 0 read GetWidth write SetWidth default 0;
    property MaxValue: string index 1 read GetText write SetText;
    property MaxValueWidth: Integer index 1 read GetWidth write SetWidth default 0;
    property MinValue: string index 2 read GetText write SetText;
    property MinValueWidth: Integer index 2 read GetWidth write SetWidth default 0;
    property Layout: TACLSliderLabelsLayout read FLayout write SetLayout default sllAroundEdges;
  end;

  { TACLSliderOptionsValue }

  TACLSliderOptionsValue = class(TACLSliderCustomOptions)
  strict private
    FDefault: Single;
    FMax: Single;
    FMin: Single;
    FPage: Single;
    FPaginate: Boolean;
    FReverse: Boolean;
    FSmallChange: Single;

    function GetRange: Single;
    function IsDefaultStored: Boolean;
    function IsMaxStored: Boolean;
    function IsMinStored: Boolean;
    function IsPageStored: Boolean;
    function IsSmallChangeStored: Boolean;
    procedure SetMax(AValue: Single);
    procedure SetMin(AValue: Single);
    procedure SetPage(AValue: Single);
    procedure SetPaginate(const Value: Boolean);
    procedure SetReverse(AValue: Boolean);
    //# Filers
    procedure ReadDefault(Reader: TReader);
    procedure WriteDefault(Writer: TWriter);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure DoAssign(Source: TPersistent); override;
    function IsDefaultAssigned: Boolean;
    procedure Validate(var AValue: Single); overload;
    procedure Validate; overload;
  public
    constructor Create(AOwner: TACLSlider); override;
    //# Properties
    property Range: Single read GetRange;
  published
    property Default: Single read FDefault write FDefault stored IsDefaultStored;
    property Max: Single read FMax write SetMax stored IsMaxStored;
    property Min: Single read FMin write SetMin stored IsMinStored;
    property Page: Single read FPage write SetPage stored IsPageStored;
    property Paginate: Boolean read FPaginate write SetPaginate default False;
    property Reverse: Boolean read FReverse write SetReverse default False;
    property SmallChange: Single read FSmallChange write FSmallChange stored IsSmallChangeStored;
  end;

  { TACLStyleSlider }

  TACLStyleSlider = class(TACLStyleContent)
  strict private
    function GetMarkColor(Enabled: Boolean): TAlphaColor;
  protected
    procedure InitializeResources; override;
  public
    procedure Draw(ACanvas: TCanvas; const R: TRect; AEnabled: Boolean);
    procedure DrawThumb(ACanvas: TCanvas; const R: TRect; AState: TACLButtonState);
    //# Properties
    property MarkColor[Enabled: Boolean]: TAlphaColor read GetMarkColor;
  published
    property ColorMark: TACLResourceColor index 10 read GetColor write SetColor stored IsColorStored;
    property ColorMarkDisabled: TACLResourceColor index 11 read GetColor write SetColor stored IsColorStored;
    property ColorRangeLabel: TACLResourceColor index 12 read GetColor write SetColor stored IsColorStored;
    property ColorDefaultValue: TACLResourceColor index 13 read GetColor write SetColor stored IsColorStored;
    property Texture: TACLResourceTexture index 0 read GetTexture write SetTexture stored IsTextureStored;
    property TextureThumb: TACLResourceTexture index 1 read GetTexture write SetTexture stored IsTextureStored;
  end;

  { TACLSliderTextViewInfo }

  TACLSliderTextViewInfo = record
    Bounds: TRect;
    HorzAlignment: TAlignment;
    Text: string;
    TextColor: TColor;
    TextSize: TSize;

    function Assigned: Boolean;
    procedure Reset;
  end;

  { TACLSliderViewInfo }

  TACLSliderViewInfo = class
  strict private
    function GetCurrentDpi: Integer; inline;
    function GetDrawingPosition: Single;
    function GetOptions: TACLSliderOptions; inline;
    function GetOptionsLabels: TACLSliderOptionsLabels; inline;
    function GetOptionsValue: TACLSliderOptionsValue; inline;
    function GetStyle: TACLStyleSlider; inline;
  protected const
    DefaultValueAreaSize = 1;
  protected
    FDefaultValueRect: TRect;
    FLabelCurrentValue: TACLSliderTextViewInfo;
    FLabelMaxValue: TACLSliderTextViewInfo;
    FLabelMinValue: TACLSliderTextViewInfo;
    FOwner: TACLSlider;
    FThumbBarRect: TRect;
    FThumbRect: TRect;
    FTickMarks: TACLList<TRect>;
    FTrackBarRect: TRect;

    function CalculateProgressCore(X: Integer): Single;
    procedure CalculateLabels(ACanvas: TCanvas; var R: TRect);
    procedure CalculateLabelsCore(var R: TRect); virtual; abstract;
    procedure CalculateThumbBarRect(const R: TRect); virtual; abstract;
    procedure CalculateThumbRect(AProgress: Single); overload; virtual; abstract;
    procedure CalculateThumbRect; overload;
    procedure CalculateTickMarks(AInterval: Single); overload; virtual; abstract;
    procedure CalculateTickMarks; overload;
    procedure CalculateTrackBarRect; virtual; abstract;
    function GetDefaultValuePosition: Integer;
    function GetMarkSize: Integer;
    function GetThumbSize: Integer; virtual; abstract;
    function GetTrackAreaOffset: Integer;
    function GetTrackSize: Integer; virtual; abstract;
  public
    constructor Create(AOwner: TACLSlider);
    destructor Destroy; override;
    procedure AdjustSize(var AWidth, AHeight: Integer); virtual; abstract;
    procedure Calculate; virtual;
    function CalculateProgress(X, Y: Integer): Single; virtual; abstract;
    function MeasureSize: TSize; virtual;
    //# Properties
    property CurrentDpi: Integer read GetCurrentDpi;
    property DefaultValueRect: TRect read FDefaultValueRect;
    property LabelCurrentValue: TACLSliderTextViewInfo read FLabelCurrentValue;
    property LabelMaxValue: TACLSliderTextViewInfo read FLabelMaxValue;
    property LabelMinValue: TACLSliderTextViewInfo read FLabelMinValue;
    property Options: TACLSliderOptions read GetOptions;
    property OptionsLabels: TACLSliderOptionsLabels read GetOptionsLabels;
    property OptionsValue: TACLSliderOptionsValue read GetOptionsValue;
    property Style: TACLStyleSlider read GetStyle;
    property ThumbBarRect: TRect read FThumbBarRect;
    property ThumbRect: TRect read FThumbRect;
    property TickMarks: TACLList<TRect> read FTickMarks;
    property TrackBarRect: TRect read FTrackBarRect;
  end;

  { TACLSliderHorizontalViewInfo }

  TACLSliderHorizontalViewInfo = class(TACLSliderViewInfo)
  protected
    procedure CalculateLabelsCore(var R: TRect); override;
    procedure CalculateThumbBarRect(const R: TRect); override;
    procedure CalculateThumbRect(AProgress: Single); override;
    procedure CalculateTickMarks(AInterval: Single); override;
    procedure CalculateTrackBarRect; override;
    function GetMaxLabelHeight: Integer;
    function GetThumbSize: Integer; override;
    function GetTrackSize: Integer; override;
  public
    procedure AdjustSize(var AWidth, AHeight: Integer); override;
    function CalculateProgress(X, Y: Integer): Single; override;
    function MeasureSize: TSize; override;
  end;

  { TACLSliderVerticalViewInfo }

  TACLSliderVerticalViewInfo = class(TACLSliderViewInfo)
  protected
    procedure CalculateLabelsCore(var R: TRect); override;
    procedure CalculateThumbBarRect(const R: TRect); override;
    procedure CalculateThumbRect(AProgress: Single); override;
    procedure CalculateTickMarks(AInterval: Single); override;
    procedure CalculateTrackBarRect; override;
    function GetMaxLabelWidth: Integer;
    function GetThumbSize: Integer; override;
    function GetTrackSize: Integer; override;
  public
    procedure AdjustSize(var AWidth, AHeight: Integer); override;
    function CalculateProgress(X, Y: Integer): Single; override;
    function MeasureSize: TSize; override;
  end;

  { TACLSlider }

  TACLSlider = class(TACLContainer)
  strict private
    FOptions: TACLSliderOptions;
    FOptionsLabels: TACLSliderOptionsLabels;
    FOptionsValue: TACLSliderOptionsValue;
    FOrientation: TACLOrientation;
    FPosition: Single;
    FTempPosition: Single;
    FThumbState: TACLButtonState;
    FViewInfo: TACLSliderViewInfo;

    FMoving: Boolean;
    FMovingHint: TACLHintWindow;
    FMovingHintAutoHideTimer: TACLTimer;

    FOnChange: TNotifyEvent;
    FOnDrawBackground: TACLCustomDrawEvent;
    FOnDrawThumb: TACLCustomDrawEvent;
    FOnGetHint: TACLSliderGetHintEvent;

    procedure MovingHintAutoHideTimerHandler(Sender: TObject);
    function GetPositionAsInteger: Integer;
    function GetStyleSlider: TACLStyleSlider;
    procedure InternalSetPosition(AValue: Single);
    function IsPositionStored: Boolean;
    procedure SetOptions(AValue: TACLSliderOptions);
    procedure SetOptionsLabels(const Value: TACLSliderOptionsLabels);
    procedure SetOptionsValue(const Value: TACLSliderOptionsValue);
    procedure SetOrientation(AValue: TACLOrientation);
    procedure SetPosition(APosition: Single); overload;
    procedure SetPosition(APosition: Single; ANotify: Boolean); overload;
    procedure SetPositionAsInteger(const Value: Integer);
    procedure SetStyleSlider(const Value: TACLStyleSlider);
  protected
    procedure Calculate; virtual;
    function CalculatePosition(X, Y: Integer): Single;
    function CalculateThumbState(const P: TPoint): TACLButtonState;

    function CreateOptions: TACLSliderOptions; virtual;
    function CreateOptionsLabels: TACLSliderOptionsLabels; virtual;
    function CreateOptionsValue: TACLSliderOptionsValue; virtual;
    function CreateStyle: TACLStyleBackground; override;
    function CreateViewInfo: TACLSliderViewInfo; virtual;

    procedure BoundsChanged; override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure DoGetHint(const P: TPoint; var AHint: string); override;
    procedure FocusChanged; override;
    procedure NextPage(ADirection: Integer; APageSize: Single);

    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    // Mouse
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure UpdateThumbState(const P: TPoint);

    // Moving Hint
    procedure HideMovingHint;
    procedure ShowMovingHint(APosition: Single; AAutoHide: Boolean);

    // Events
    procedure DoChanged(APosition: Single);

    // Drawing
    procedure DrawText(ACanvas: TCanvas; const AViewInfo: TACLSliderTextViewInfo);
    procedure DrawThumbBar(ACanvas: TCanvas; const ARect: TRect); virtual;
    procedure DrawTickMarks(ACanvas: TCanvas); overload;
    procedure DrawTrackBar(ACanvas: TCanvas; const ARect: TRect); virtual;
    procedure Paint; override;

    // Messages
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;

    property TempPosition: Single read FTempPosition;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    //# Properties
    property Moving: Boolean read FMoving;
    property PositionAsInteger: Integer read GetPositionAsInteger write SetPositionAsInteger;
    property ViewInfo: TACLSliderViewInfo read FViewInfo;
  published
    property AutoSize default False;
    property DoubleBuffered default True;
    property Orientation: TACLOrientation read FOrientation write SetOrientation default oVertical;
    property Enabled;
    property Options: TACLSliderOptions read FOptions write SetOptions;
    property OptionsLabels: TACLSliderOptionsLabels read FOptionsLabels write SetOptionsLabels;
    property OptionsValue: TACLSliderOptionsValue read FOptionsValue write SetOptionsValue;
    property Padding;
    property Position: Single read FPosition write SetPosition stored IsPositionStored;
    property Style: TACLStyleSlider read GetStyleSlider write SetStyleSlider;
    property Transparent;
    //# Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnDblClick;
    property OnDrawBackground: TACLCustomDrawEvent read FOnDrawBackground write FOnDrawBackground;
    property OnDrawThumb: TACLCustomDrawEvent read FOnDrawThumb write FOnDrawThumb;
    property OnGetHint: TACLSliderGetHintEvent read FOnGetHint write FOnGetHint;
    property OnMouseDown;
    property OnMouseUp;
  end;

implementation

{$IFNDEF FPC}
uses
  ACL.Graphics.SkinImageSet;
{$ENDIF}

{ TACLSliderCustomOptions }

constructor TACLSliderCustomOptions.Create(AOwner: TACLSlider);
begin
  FOwner := AOwner;
end;

procedure TACLSliderCustomOptions.DoChanged(AChanges: TACLPersistentChanges);
begin
  if [apcLayout, apcStruct] * AChanges <> [] then
    FOwner.FullRefresh
  else
    FOwner.Invalidate;
end;

{ TACLSliderOptions}

constructor TACLSliderOptions.Create(AOwner: TACLSlider);
begin
  inherited;
  FMarkSize := 3;
  FMarkVisible := True;
  FImmediateUpdate := True;
  FTrackAreaOffset := 5;
end;

procedure TACLSliderOptions.DoAssign(Source: TPersistent);
begin
  inherited;

  if Source is TACLSliderOptions then
  begin
    ImmediateUpdate := TACLSliderOptions(Source).ImmediateUpdate;
    MagnetToDefaultValue := TACLSliderOptions(Source).MagnetToDefaultValue;
    MarkSize := TACLSliderOptions(Source).MarkSize;
    MarkVisible := TACLSliderOptions(Source).MarkVisible;
    TrackAreaOffset := TACLSliderOptions(Source).TrackAreaOffset;
  end;
end;

procedure TACLSliderOptions.SetMarkSize(AValue: TACLSliderMarkSize);
begin
  if AValue <> FMarkSize then
  begin
    FMarkSize := AValue;
    if MarkVisible then
      Changed([apcLayout]);
  end;
end;

procedure TACLSliderOptions.SetMarkVisible(AValue: Boolean);
begin
  SetBooleanFieldValue(FMarkVisible, AValue, [apcLayout]);
end;

procedure TACLSliderOptions.SetTrackAreaOffset(AValue: Integer);
begin
  SetIntegerFieldValue(FTrackAreaOffset, AValue, [apcLayout]);
end;

{ TACLSliderOptionsLabels }

procedure TACLSliderOptionsLabels.DoAssign(Source: TPersistent);
var
  I: Integer;
begin
  inherited;

  if Source is TACLSliderOptionsLabels then
  begin
    for I := Low(FText) to High(FText) do
      SetText(I, TACLSliderOptionsLabels(Source).GetText(I));
    for I := Low(FWidth) to High(FWidth) do
      SetWidth(I, TACLSliderOptionsLabels(Source).GetWidth(I));
    Layout := TACLSliderOptionsLabels(Source).Layout;
  end;
end;

procedure TACLSliderOptionsLabels.DoChanged(AChanges: TACLPersistentChanges);
begin
  inherited;
  FIsCurrentValueMasked := acContains('%', CurrentValue);
end;

function TACLSliderOptionsLabels.FormatCurrentValue(const AValue: Single): string;
begin
  if IsCurrentValueMasked then
    Result := Format(CurrentValue, [AValue])
  else
    Result := CurrentValue;
end;

function TACLSliderOptionsLabels.HasLabels: Boolean;
begin
  Result := HasRangeLabels or (CurrentValue <> '');
end;

function TACLSliderOptionsLabels.HasRangeLabels: Boolean;
begin
  Result := (MinValue <> '') or (MaxValue <> '');
end;

function TACLSliderOptionsLabels.GetWidth(const Index: Integer): Integer;
begin
  Result := FWidth[Index];
end;

function TACLSliderOptionsLabels.GetText(const Index: Integer): string;
begin
  Result := FText[Index];
end;

procedure TACLSliderOptionsLabels.SetLayout(const Value: TACLSliderLabelsLayout);
begin
  if FLayout <> Value then
  begin
    FLayout := Value;
    Changed;
  end;
end;

procedure TACLSliderOptionsLabels.SetWidth(const Index: Integer; AValue: Integer);
begin
  AValue := Max(AValue, 0);
  if FWidth[Index] <> AValue then
  begin
    FWidth[Index] := AValue;
    Changed;
  end;
end;

procedure TACLSliderOptionsLabels.SetText(const Index: Integer; const Value: string);
begin
  if GetText(Index) <> Value then
  begin
    FText[Index] := Value;
    Changed;
  end;
end;

{ TACLSliderOptionsValue }

constructor TACLSliderOptionsValue.Create(AOwner: TACLSlider);
begin
  inherited;
  FMax := 100;
  FPage := 10;
  FDefault := -1;
  FSmallChange := 1;
end;

procedure TACLSliderOptionsValue.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('Default', ReadDefault, WriteDefault, IsDefaultAssigned and IsZero(Default));
end;

procedure TACLSliderOptionsValue.DoAssign(Source: TPersistent);
begin
  inherited;

  if Source is TACLSliderOptionsValue then
  begin
    Reverse := TACLSliderOptionsValue(Source).Reverse;
    Paginate := TACLSliderOptionsValue(Source).Paginate;
    Page := TACLSliderOptionsValue(Source).Page;
    Default := TACLSliderOptionsValue(Source).Default;
    Max := TACLSliderOptionsValue(Source).Max;
    Min := TACLSliderOptionsValue(Source).Min;
    SmallChange := TACLSliderOptionsValue(Source).SmallChange;
  end;
end;

function TACLSliderOptionsValue.IsDefaultAssigned: Boolean;
begin
  Result := InRange(Default, Min, Max);
end;

function TACLSliderOptionsValue.GetRange: Single;
begin
  Result := Max - Min;
end;

function TACLSliderOptionsValue.IsDefaultStored: Boolean;
begin
  Result := not SameValue(FDefault, -1)
end;

function TACLSliderOptionsValue.IsMaxStored: Boolean;
begin
  Result := not SameValue(FMax, 100);
end;

function TACLSliderOptionsValue.IsMinStored: Boolean;
begin
  Result := not IsZero(FMin)
end;

function TACLSliderOptionsValue.IsPageStored: Boolean;
begin
  Result := not SameValue(FPage, 10);
end;

function TACLSliderOptionsValue.IsSmallChangeStored: Boolean;
begin
  Result := not SameValue(SmallChange, 1);
end;

procedure TACLSliderOptionsValue.Validate(var AValue: Single);
begin
  if Paginate then
  begin
    AValue := AValue - Min;
    AValue := Round(AValue / Page) * Page;
    AValue := AValue + Min;
  end;
  AValue := MinMax(AValue, Min, Max);
end;

procedure TACLSliderOptionsValue.Validate;
begin
  FOwner.Position := FOwner.Position;
end;

procedure TACLSliderOptionsValue.SetMax(AValue: Single);
begin
  AValue := {System.}Math.Max(AValue, Min + 1);
  if AValue <> FMax then
  begin
    FMax := AValue;
    Validate;
  end;
end;

procedure TACLSliderOptionsValue.SetMin(AValue: Single);
begin
  AValue := {System.}Math.Min(AValue, Max - 1);
  if AValue <> FMin then
  begin
    FMin := AValue;
    Validate;
  end;
end;

procedure TACLSliderOptionsValue.SetPage(AValue: Single);
begin
  AValue := {System.}Math.Max(AValue, 0.01);
  SetSingleFieldValue(FPage, AValue, [apcLayout]);
end;

procedure TACLSliderOptionsValue.SetPaginate(const Value: Boolean);
begin
  SetBooleanFieldValue(FPaginate, Value, [apcLayout]);
end;

procedure TACLSliderOptionsValue.SetReverse(AValue: Boolean);
begin
  SetBooleanFieldValue(FReverse, AValue, [apcLayout]);
end;

procedure TACLSliderOptionsValue.ReadDefault(Reader: TReader);
begin
  Default := Reader.ReadDouble;
end;

procedure TACLSliderOptionsValue.WriteDefault(Writer: TWriter);
begin
{$IFDEF FPC}
  Writer.WriteFloat(Default);
{$ELSE}
  Writer.WriteDouble(Default);
{$ENDIF}
end;

{ TACLStyleSlider }

procedure TACLStyleSlider.Draw(ACanvas: TCanvas; const R: TRect; AEnabled: Boolean);
begin
  Texture.Draw(ACanvas, R, Ord(AEnabled));
end;

procedure TACLStyleSlider.DrawThumb(ACanvas: TCanvas; const R: TRect; AState: TACLButtonState);
begin
  TextureThumb.Draw(ACanvas, R, Ord(AState));
end;

procedure TACLStyleSlider.InitializeResources;
begin
  inherited InitializeResources;
  ColorMark.InitailizeDefaults('Slider.Colors.Mark', True);
  ColorMarkDisabled.InitailizeDefaults('Slider.Colors.MarkDisabled', True);
  ColorRangeLabel.InitailizeDefaults('Common.Colors.TextDisabled');
  ColorDefaultValue.InitailizeDefaults('Slider.Colors.DefaultValue');
  Texture.InitailizeDefaults('Slider.Textures.Background');
  TextureThumb.InitailizeDefaults('Slider.Textures.Thumb');
end;

function TACLStyleSlider.GetMarkColor(Enabled: Boolean): TAlphaColor;
begin
  if Enabled then
    Result := ColorMark.Value
  else
    Result := ColorMarkDisabled.Value;
end;

{ TACLSliderTextViewInfo }

function TACLSliderTextViewInfo.Assigned: Boolean;
begin
  Result := TextSize.cx > 0;
end;

procedure TACLSliderTextViewInfo.Reset;
begin
  Bounds := NullRect;
  HorzAlignment := taLeftJustify;
  Text := '';
  TextSize := NullSize;
  TextColor := clWindowText;
end;

{ TACLSliderViewInfo }

constructor TACLSliderViewInfo.Create(AOwner: TACLSlider);
begin
  FOwner := AOwner;
  FTickMarks := TACLList<TRect>.Create;
end;

destructor TACLSliderViewInfo.Destroy;
begin
  FreeAndNil(FTickMarks);
  inherited;
end;

procedure TACLSliderViewInfo.Calculate;
var
  R: TRect;
begin
  R := FOwner.ClientRect;

  MeasureCanvas.Font := FOwner.Font;
  CalculateLabels(MeasureCanvas, R);

  R.Content(FOwner.Padding.GetScaledMargins(CurrentDpi));
  CalculateThumbBarRect(R);
  CalculateTrackBarRect;
  CalculateThumbRect;
  CalculateTickMarks;
end;

function TACLSliderViewInfo.CalculateProgressCore(X: Integer): Single;
begin
  Result := MinMax((X - GetThumbSize / 2) / GetTrackSize, 0, 1);
  if OptionsValue.Reverse then
    Result := 1 - Result;
end;

procedure TACLSliderViewInfo.CalculateLabels(ACanvas: TCanvas; var R: TRect);

  procedure InitializeViewInfo(var AViewInfo: TACLSliderTextViewInfo;
    const AText: string; ACustomTextWidth: Integer);
  begin
    if AText <> '' then
    begin
      AViewInfo.Text := AText;
      AViewInfo.TextColor := Style.ColorRangeLabel.AsColor;
      if ACustomTextWidth > 0 then
      begin
        AViewInfo.TextSize.cx := ACustomTextWidth;
        AViewInfo.TextSize.cy := acFontHeight(ACanvas);
      end
      else
        AViewInfo.TextSize := acTextSize(ACanvas, AText);
    end;
  end;

begin
  LabelCurrentValue.Reset;
  LabelMinValue.Reset;
  LabelMaxValue.Reset;

  if OptionsLabels.HasLabels then
  begin
    if OptionsLabels.HasRangeLabels then
    begin
      if OptionsValue.Reverse then
      begin
        InitializeViewInfo(FLabelMaxValue, OptionsLabels.MinValue, OptionsLabels.MinValueWidth);
        InitializeViewInfo(FLabelMinValue, OptionsLabels.MaxValue, OptionsLabels.MaxValueWidth);
      end
      else
      begin
        InitializeViewInfo(FLabelMaxValue, OptionsLabels.MaxValue, OptionsLabels.MaxValueWidth);
        InitializeViewInfo(FLabelMinValue, OptionsLabels.MinValue, OptionsLabels.MinValueWidth);
      end;
    end;

    if OptionsLabels.CurrentValue <> '' then
    begin
      FLabelCurrentValue.Text := OptionsLabels.FormatCurrentValue(GetDrawingPosition);
      FLabelCurrentValue.TextColor := Style.TextColors[FOwner.Enabled];
      if OptionsLabels.CurrentValueWidth > 0 then
      begin
        FLabelCurrentValue.TextSize.cx := OptionsLabels.CurrentValueWidth;
        FLabelCurrentValue.TextSize.cy := acFontHeight(ACanvas);
      end
      else
        FLabelCurrentValue.TextSize := Max(
          acTextSize(ACanvas, OptionsLabels.FormatCurrentValue(OptionsValue.Max)),
          acTextSize(ACanvas, OptionsLabels.FormatCurrentValue(OptionsValue.Min)));
    end;

    CalculateLabelsCore(R);
  end;
end;

procedure TACLSliderViewInfo.CalculateThumbRect;
var
  AThumbPosition: Single;
  ARange: Single;
begin
  ARange := OptionsValue.Range;
  if ARange > 0 then
  begin
    AThumbPosition := (GetDrawingPosition - OptionsValue.Min) / ARange;
    if OptionsValue.Reverse then
      AThumbPosition := 1 - AThumbPosition;
    CalculateThumbRect(AThumbPosition);
  end
  else
    FThumbRect := NullRect;
end;

procedure TACLSliderViewInfo.CalculateTickMarks;
var
  ARange: Single;
begin
  ARange := OptionsValue.Range;
  if (ARange > 0) and Options.MarkVisible then
  begin
    FTickMarks.Count := 0;
    ARange := OptionsValue.Page * GetTrackSize / ARange;
    if ARange > 0 then
      CalculateTickMarks(ARange);
  end
  else
    FTickMarks.Clear;
end;

function TACLSliderViewInfo.GetDrawingPosition: Single;
begin
  if not Options.ImmediateUpdate and FOwner.Moving then
    Result := FOwner.TempPosition
  else
    Result := FOwner.Position;
end;

function TACLSliderViewInfo.GetCurrentDpi: Integer;
begin
  Result := FOwner.FCurrentPPI;
end;

function TACLSliderViewInfo.GetDefaultValuePosition: Integer;
var
  AValue: Single;
begin
  AValue := OptionsValue.Default;
  if OptionsValue.Reverse then
    AValue := OptionsValue.Max - AValue;
  Result := GetThumbSize div 2 + FastTrunc(GetTrackSize * AValue / OptionsValue.Range);
end;

function TACLSliderViewInfo.GetMarkSize: Integer;
begin
  if Options.MarkVisible then
    Result := dpiApply(Options.MarkSize, CurrentDpi)
  else
    Result := 0;
end;

function TACLSliderViewInfo.GetOptions: TACLSliderOptions;
begin
  Result := FOwner.Options;
end;

function TACLSliderViewInfo.GetOptionsLabels: TACLSliderOptionsLabels;
begin
  Result := FOwner.OptionsLabels;
end;

function TACLSliderViewInfo.GetOptionsValue: TACLSliderOptionsValue;
begin
  Result := FOwner.OptionsValue;
end;

function TACLSliderViewInfo.GetStyle: TACLStyleSlider;
begin
  Result := FOwner.Style;
end;

function TACLSliderViewInfo.GetTrackAreaOffset: Integer;
begin
  Result := dpiApply(Options.TrackAreaOffset, CurrentDpi);
end;

function TACLSliderViewInfo.MeasureSize: TSize;
begin
  Result.cy := 2 * GetTrackAreaOffset + 2 * GetMarkSize + 3 + dpiApply(6, CurrentDpi);
  Result.cx := 3 * GetThumbSize;
end;

{ TACLSliderHorizontalViewInfo }

function TACLSliderHorizontalViewInfo.MeasureSize: TSize;
var
  ALabelHeight: Integer;
  AMargins: TRect;
begin
  Result := inherited;

  AMargins := FOwner.Padding.GetScaledMargins(CurrentDpi);
  Inc(Result.cx, AMargins.MarginsWidth);
  Inc(Result.cy, AMargins.MarginsHeight);

  if OptionsLabels.HasLabels then
    case OptionsLabels.Layout of
      sllAfterTrackBar, sllBeforeTrackBar:
        begin
          ALabelHeight := LabelMaxValue.TextSize.cy;
          ALabelHeight := Max(ALabelHeight, LabelMinValue.TextSize.cy);
          ALabelHeight := Max(ALabelHeight, LabelCurrentValue.TextSize.cy);

          Inc(Result.cy, dpiApply(acIndentBetweenElements, CurrentDpi));
          Inc(Result.cy, ALabelHeight);

          Result.cx := Max(Result.cx, LabelCurrentValue.TextSize.cx + LabelMaxValue.TextSize.cx +
            LabelMinValue.TextSize.cx + 2 * dpiApply(acIndentBetweenElements, CurrentDpi));
        end;

      sllAroundEdges:
        if OptionsLabels.HasRangeLabels then
        begin
          Inc(Result.cx, LabelMaxValue.TextSize.cx);
          Inc(Result.cx, LabelMinValue.TextSize.cx);
          Inc(Result.cx, 2 * dpiApply(acIndentBetweenElements, CurrentDpi));

          Result.cy := Max(Result.cy, LabelMaxValue.TextSize.cy);
          Result.cy := Max(Result.cy, LabelMinValue.TextSize.cy);

          if LabelCurrentValue.Assigned then
          begin
            Inc(Result.cy, dpiApply(acIndentBetweenElements, CurrentDpi));
            Inc(Result.cy, LabelCurrentValue.TextSize.cy);
          end;
        end
        else
          if LabelCurrentValue.Assigned then
          begin
            Result.cy := Max(Result.cy, LabelCurrentValue.TextSize.cy);
            Inc(Result.cx, dpiApply(acIndentBetweenElements, CurrentDpi));
            Inc(Result.cx, LabelCurrentValue.TextSize.cx);
          end;
    end;
end;

procedure TACLSliderHorizontalViewInfo.CalculateLabelsCore(var R: TRect);

  procedure PlaceRangeLabels(const R: TRect);
  begin
    FLabelMinValue.Bounds := TRect.Create(R.TopLeft, LabelMinValue.TextSize);
    FLabelMinValue.HorzAlignment := taLeftJustify;

    FLabelMaxValue.Bounds := R.Split(srRight, LabelMaxValue.TextSize.cx);
    FLabelMaxValue.Bounds.Height := LabelMaxValue.TextSize.cy;
    FLabelMaxValue.HorzAlignment := taRightJustify;
  end;

  procedure PlaceLabels(const R: TRect);
  begin
    PlaceRangeLabels(R);
    FLabelCurrentValue.Bounds := R;
    FLabelCurrentValue.Bounds.Center(LabelCurrentValue.TextSize);
  end;

begin
  FLabelCurrentValue.HorzAlignment := taCenter;

  case OptionsLabels.Layout of
    sllAfterTrackBar:
      begin
        PlaceLabels(R.Split(srBottom, GetMaxLabelHeight));
        Dec(R.Bottom, dpiApply(acIndentBetweenElements, CurrentDpi));
        Dec(R.Bottom, GetMaxLabelHeight);
      end;

    sllBeforeTrackBar:
      begin
        PlaceLabels(R.Split(srTop, GetMaxLabelHeight));
        Inc(R.Top, dpiApply(acIndentBetweenElements, CurrentDpi));
        Inc(R.Top, GetMaxLabelHeight);
      end;

    sllAroundEdges:
      if OptionsLabels.HasRangeLabels then
      begin
        if LabelCurrentValue.Assigned then
        begin
          FLabelCurrentValue.Bounds := R.Split(srBottom, LabelCurrentValue.TextSize.cy);
          R.Bottom := LabelCurrentValue.Bounds.Top - dpiApply(acIndentBetweenElements, CurrentDpi);
        end;

        PlaceRangeLabels(R.CenterTo(R.Width, Max(LabelMaxValue.TextSize.cy, LabelMinValue.TextSize.cy)));
        if LabelMinValue.Assigned then
          R.Left := LabelMinValue.Bounds.Right + dpiApply(acIndentBetweenElements, CurrentDpi);
        if LabelMaxValue.Assigned then
          R.Right := LabelMaxValue.Bounds.Left - dpiApply(acIndentBetweenElements, CurrentDpi);
        FLabelMinValue.HorzAlignment := taRightJustify;
        FLabelMaxValue.HorzAlignment := taLeftJustify;
      end
      else
        if LabelCurrentValue.Assigned then
        begin
          FLabelCurrentValue.HorzAlignment := taLeftJustify;
          FLabelCurrentValue.Bounds := R.Split(srRight, LabelCurrentValue.TextSize.cx);
          FLabelCurrentValue.Bounds.CenterVert(LabelCurrentValue.TextSize.cy);
          R.Right := LabelCurrentValue.Bounds.Left - dpiApply(acIndentBetweenElements, CurrentDpi);
        end;
  end;
end;

procedure TACLSliderHorizontalViewInfo.AdjustSize(var AWidth, AHeight: Integer);
var
  AMinSize: TSize;
begin
  AMinSize := MeasureSize;
  AWidth := Max(AWidth, AMinSize.cx);
  if FOwner.AutoSize then
    AHeight := AMinSize.cy
  else
    AHeight := Max(AHeight, AMinSize.cy);
end;

function TACLSliderHorizontalViewInfo.CalculateProgress(X, Y: Integer): Single;
begin
  Result := CalculateProgressCore(X - FThumbBarRect.Left);
end;

procedure TACLSliderHorizontalViewInfo.CalculateThumbBarRect(const R: TRect);
begin
  FThumbBarRect := R;
  FThumbBarRect.Inflate(0, -(GetMarkSize + 1));
end;

procedure TACLSliderHorizontalViewInfo.CalculateThumbRect(AProgress: Single);
begin
  FThumbRect := FThumbBarRect.Split(srLeft, GetThumbSize);
  FThumbRect.Offset(Trunc(GetTrackSize * AProgress), 0);
end;

procedure TACLSliderHorizontalViewInfo.CalculateTickMarks(AInterval: Single);
var
  AMarkThickness: Integer;
  AMarkSize: Integer;
  AMaxPosition: Single;
  APosition: Single;
  X0, Y1, Y2, X: Integer;
begin
  APosition := GetThumbSize div 2;
  AMaxPosition := ThumbBarRect.Width - APosition + 1;
  AMarkThickness := dpiApply(1, CurrentDpi);
  AMarkSize := GetMarkSize;

  X0 := FThumbBarRect.Left;
  Y1 := FThumbBarRect.Top - 1 - GetMarkSize;
  Y2 := FThumbBarRect.Bottom + 1;

  while APosition <= AMaxPosition do
  begin
    X := X0 + FastTrunc(APosition);
    FTickMarks.Add(Bounds(X, Y1, AMarkThickness, AMarkSize));
    FTickMarks.Add(Bounds(X, Y2, AMarkThickness, AMarkSize));
    APosition := APosition + AInterval;
  end;
end;

procedure TACLSliderHorizontalViewInfo.CalculateTrackBarRect;
begin
  FTrackBarRect := FThumbBarRect;
  FTrackBarRect.Inflate(0, -GetTrackAreaOffset);

  if OptionsValue.IsDefaultAssigned then
  begin
    FDefaultValueRect := FTrackBarRect;
    FDefaultValueRect.Inflate(0, -1);
    FDefaultValueRect.Left := FTrackBarRect.Left + GetDefaultValuePosition;
    FDefaultValueRect.Right := FDefaultValueRect.Left + dpiApply(DefaultValueAreaSize, CurrentDpi);
  end
  else
    FDefaultValueRect := NullRect;
end;

function TACLSliderHorizontalViewInfo.GetMaxLabelHeight: Integer;
begin
  Result := LabelCurrentValue.TextSize.cy;
  Result := Max(Result, LabelMinValue.TextSize.cy);
  Result := Max(Result, LabelMaxValue.TextSize.cy);
end;

function TACLSliderHorizontalViewInfo.GetThumbSize: Integer;
begin
  Result := Style.TextureThumb.FrameWidth;
end;

function TACLSliderHorizontalViewInfo.GetTrackSize: Integer;
begin
  Result := ThumbBarRect.Width - GetThumbSize;
end;

{ TACLSliderVerticalViewInfo }

procedure TACLSliderVerticalViewInfo.AdjustSize(var AWidth, AHeight: Integer);
var
  AMinSize: TSize;
begin
  AMinSize := MeasureSize;
  AHeight := Max(AHeight, AMinSize.cy);
  if FOwner.AutoSize then
    AWidth := AMinSize.cx
  else
    AWidth := Max(AWidth, AMinSize.cx);
end;

function TACLSliderVerticalViewInfo.MeasureSize: TSize;
var
  AMargins: TRect;
begin
  Result := inherited;
  acExchangeIntegers(Result.cx, Result.cy);

  AMargins := FOwner.Padding.GetScaledMargins(CurrentDpi);
  Inc(Result.cx, AMargins.MarginsWidth);
  Inc(Result.cy, AMargins.MarginsHeight);

  if OptionsLabels.HasLabels then
    case OptionsLabels.Layout of
      sllAfterTrackBar, sllBeforeTrackBar:
        begin
          Inc(Result.cx, dpiApply(acIndentBetweenElements, CurrentDpi));
          Inc(Result.cx, GetMaxLabelWidth);

          Result.cy := Max(Result.cy,
            LabelCurrentValue.TextSize.cy +
            LabelMaxValue.TextSize.cy +
            LabelMinValue.TextSize.cy + 2 * dpiApply(acIndentBetweenElements, CurrentDpi));
        end;

      sllAroundEdges:
        if OptionsLabels.HasRangeLabels then
        begin
          if LabelMinValue.Assigned then
          begin
            Inc(Result.cy, dpiApply(acIndentBetweenElements, CurrentDpi));
            Inc(Result.cy, LabelMinValue.TextSize.cy);
            Result.cx := Max(Result.cx, LabelMinValue.TextSize.cx);
          end;

          if LabelMaxValue.Assigned then
          begin
            Inc(Result.cy, dpiApply(acIndentBetweenElements, CurrentDpi));
            Inc(Result.cy, LabelMaxValue.TextSize.cy);
            Result.cx := Max(Result.cx, LabelMaxValue.TextSize.cx);
          end;

          if LabelCurrentValue.Assigned then
          begin
            Inc(Result.cx, dpiApply(acIndentBetweenElements, CurrentDpi));
            Inc(Result.cx, LabelCurrentValue.TextSize.cx);
          end;
        end
        else
          if LabelCurrentValue.Assigned then
          begin
            Inc(Result.cy, LabelCurrentValue.TextSize.cy);
            Inc(Result.cy, dpiApply(acIndentBetweenElements, CurrentDpi));
            Result.cx := Max(Result.cx, LabelCurrentValue.TextSize.cx);
          end;
    end;
end;

procedure TACLSliderVerticalViewInfo.CalculateLabelsCore(var R: TRect);

  procedure PlaceRangeLabels(const R: TRect; AAlignment: TAlignment);
  begin
    FLabelMinValue.Bounds := R.Split(srTop, LabelMinValue.TextSize.cy);
    FLabelMinValue.HorzAlignment := AAlignment;
    FLabelMaxValue.Bounds := R.Split(srBottom, LabelMaxValue.TextSize.cy);
    FLabelMaxValue.HorzAlignment := AAlignment;
  end;

  procedure PlaceCurrentValueLabel(const R: TRect; AAlignment: TAlignment);
  begin
    FLabelCurrentValue.Bounds := R;
    FLabelCurrentValue.Bounds.CenterVert(LabelCurrentValue.TextSize.cy);
    FLabelCurrentValue.HorzAlignment := AAlignment;
  end;

  procedure PlaceLabels(const R: TRect; AAlignment: TAlignment);
  begin
    PlaceRangeLabels(R, AAlignment);
    PlaceCurrentValueLabel(R, AAlignment);
  end;

begin
  case OptionsLabels.Layout of
    sllAfterTrackBar:
      begin
        PlaceLabels(R.Split(srRight, GetMaxLabelWidth), taLeftJustify);
        Dec(R.Right, dpiApply(acIndentBetweenElements, CurrentDpi));
        Dec(R.Right, GetMaxLabelWidth);
      end;

    sllBeforeTrackBar:
      begin
        PlaceLabels(R.Split(srLeft, GetMaxLabelWidth), taRightJustify);
        Inc(R.Left, dpiApply(acIndentBetweenElements, CurrentDpi));
        Inc(R.Left, GetMaxLabelWidth);
      end;

    sllAroundEdges:
      if OptionsLabels.HasRangeLabels then
      begin
        if LabelCurrentValue.Assigned then
        begin
          PlaceCurrentValueLabel(R.Split(srRight, LabelCurrentValue.TextSize.cx), taLeftJustify);
          R.Right := LabelCurrentValue.Bounds.Left - dpiApply(acIndentBetweenElements, CurrentDpi);
        end;

        PlaceRangeLabels(R.CenterTo(GetMaxLabelWidth, R.Height), taCenter);
        if LabelMinValue.Assigned then
          R.Top := LabelMinValue.Bounds.Bottom + dpiApply(acIndentBetweenElements, CurrentDpi);
        if LabelMaxValue.Assigned then
          R.Bottom := LabelMaxValue.Bounds.Top - dpiApply(acIndentBetweenElements, CurrentDpi);
      end
      else
        if LabelCurrentValue.Assigned then
        begin
          PlaceCurrentValueLabel(R.Split(srTop, LabelCurrentValue.TextSize.cy), taCenter);
          R.Top := LabelCurrentValue.Bounds.Bottom + dpiApply(acIndentBetweenElements, CurrentDpi);
        end;
  end;
end;

function TACLSliderVerticalViewInfo.CalculateProgress(X, Y: Integer): Single;
begin
  Result := CalculateProgressCore(Y - FThumbBarRect.Top);
end;

procedure TACLSliderVerticalViewInfo.CalculateThumbBarRect(const R: TRect);
begin
  FThumbBarRect := R;
  FThumbBarRect.Inflate(-(GetMarkSize + 1), 0);

  if OptionsValue.IsDefaultAssigned then
  begin
    FDefaultValueRect := FTrackBarRect;
    FDefaultValueRect.Inflate(-1, 0);
    FDefaultValueRect.Top := FTrackBarRect.Top + GetDefaultValuePosition;
    FDefaultValueRect.Bottom := FDefaultValueRect.Top + dpiApply(DefaultValueAreaSize, CurrentDpi);
  end
  else
    FDefaultValueRect := NullRect;
end;

procedure TACLSliderVerticalViewInfo.CalculateThumbRect(AProgress: Single);
begin
  FThumbRect := FThumbBarRect.Split(srTop, GetThumbSize);
  FThumbRect.Offset(0, Trunc(GetTrackSize * AProgress));
end;

procedure TACLSliderVerticalViewInfo.CalculateTickMarks(AInterval: Single);
var
  AMarkThickness: Integer;
  AMarkSize: Integer;
  AMaxPosition: Single;
  APosition: Single;
  Y0, X1, X2, Y: Integer;
begin
  APosition := GetThumbSize div 2;
  AMaxPosition := ThumbBarRect.Height - APosition + 1;
  AMarkThickness := dpiApply(1, CurrentDpi);
  AMarkSize := GetMarkSize;

  Y0 := FThumbBarRect.Top;
  X1 := FThumbBarRect.Left - 1 - GetMarkSize;
  X2 := FThumbBarRect.Right + 1;

  while APosition <= AMaxPosition do
  begin
    Y := Y0 + Trunc(APosition);
    FTickMarks.Add(Bounds(X1, Y, AMarkSize, AMarkThickness));
    FTickMarks.Add(Bounds(X2, Y, AMarkSize, AMarkThickness));
    APosition := APosition + AInterval;
  end;
end;

procedure TACLSliderVerticalViewInfo.CalculateTrackBarRect;
begin
  FTrackBarRect := FThumbBarRect;
  FTrackBarRect.Inflate(-GetTrackAreaOffset, 0);
end;

function TACLSliderVerticalViewInfo.GetMaxLabelWidth: Integer;
begin
  Result := LabelCurrentValue.TextSize.cx;
  Result := Max(Result, LabelMinValue.TextSize.cx);
  Result := Max(Result, LabelMaxValue.TextSize.cx);
end;

function TACLSliderVerticalViewInfo.GetThumbSize: Integer;
begin
  Result := Style.TextureThumb.FrameHeight;
end;

function TACLSliderVerticalViewInfo.GetTrackSize: Integer;
begin
  Result := ThumbBarRect.Height - GetThumbSize;
end;

{ TACLSlider }

constructor TACLSlider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOrientation := oVertical;
  FOptions := CreateOptions;
  FOptionsValue := CreateOptionsValue;
  FOptionsLabels := CreateOptionsLabels;
  FDefaultSize := TSize.Create(20, 100);
  FViewInfo := CreateViewInfo;
  FocusOnClick := True;
  ParentDoubleBuffered := False;
  DoubleBuffered := True;
  Borders := [];
  TabStop := True;
end;

destructor TACLSlider.Destroy;
begin
  FreeAndNil(FMovingHintAutoHideTimer);
  FreeAndNil(FMovingHint);
  FreeAndNil(FOptionsLabels);
  FreeAndNil(FOptionsValue);
  FreeAndNil(FOptions);
  FreeAndNil(FViewInfo);
  inherited Destroy;
end;

procedure TACLSlider.Calculate;
begin
  if not (csDestroying in ComponentState) then
    ViewInfo.Calculate;
end;

function TACLSlider.CalculatePosition(X, Y: Integer): Single;
begin
  Result := OptionsValue.Range * ViewInfo.CalculateProgress(X, Y) + OptionsValue.Min;
  OptionsValue.Validate(Result);
  if Options.MagnetToDefaultValue and OptionsValue.IsDefaultAssigned then
  begin
    if Abs(OptionsValue.Default - Result) < Sqr(OptionsValue.Range) / 200 / ViewInfo.GetTrackSize then
      Result := OptionsValue.Default;
  end;
end;

function TACLSlider.CalculateThumbState(const P: TPoint): TACLButtonState;
begin
  if not Enabled then
    Result := absDisabled
  else
    if PtInRect(ViewInfo.ThumbRect, P) or Focused and not (csDesigning in ComponentState) then
    begin
      if Moving then
        Result := absPressed
      else
        Result := absHover;
    end
    else
      Result := absNormal;
end;

function TACLSlider.CreateOptions: TACLSliderOptions;
begin
  Result := TACLSliderOptions.Create(Self);
end;

function TACLSlider.CreateOptionsLabels: TACLSliderOptionsLabels;
begin
  Result := TACLSliderOptionsLabels.Create(Self);
end;

function TACLSlider.CreateOptionsValue: TACLSliderOptionsValue;
begin
  Result := TACLSliderOptionsValue.Create(Self);
end;

function TACLSlider.CreateStyle: TACLStyleBackground;
begin
  Result := TACLStyleSlider.Create(Self);
end;

function TACLSlider.CreateViewInfo: TACLSliderViewInfo;
begin
  if Orientation = oVertical then
    Result := TACLSliderVerticalViewInfo.Create(Self)
  else
    Result := TACLSliderHorizontalViewInfo.Create(Self);
end;

procedure TACLSlider.BoundsChanged;
begin
  inherited;
  Calculate;
end;

function TACLSlider.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  Result := True;
  ViewInfo.AdjustSize(NewWidth, NewHeight);
end;

procedure TACLSlider.FocusChanged;
begin
  inherited FocusChanged;
  UpdateThumbState(CalcCursorPos);
  Invalidate;
end;

procedure TACLSlider.DoGetHint(const P: TPoint; var AHint: string);
begin
  if Moving then
    AHint := ''
  else
    if Assigned(OnGetHint) then
      OnGetHint(Self, Position, AHint);
end;

procedure TACLSlider.NextPage(ADirection: Integer; APageSize: Single);
var
  ALevelUp: Boolean;
begin
  if Orientation = oVertical then
  begin
    if OptionsValue.Reverse then
      ALevelUp := ADirection >= 0
    else
      ALevelUp := ADirection <= 0;
  end
  else
    if OptionsValue.Reverse then
      ALevelUp := ADirection <= 0
    else
      ALevelUp := ADirection >= 0;

  SetPosition(Position + Signs[ALevelUp] * APageSize, True);
end;

procedure TACLSlider.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);

  case Key of
    VK_PRIOR:
      NextPage(Signs[Orientation = oVertical], OptionsValue.Page);
    VK_NEXT:
      NextPage(Signs[Orientation = oHorizontal], OptionsValue.Page);
    VK_HOME, VK_END:
      SetPosition(IfThen(OptionsValue.Reverse = (Key = VK_HOME), OptionsValue.Max, OptionsValue.Min), True);
    VK_RIGHT, VK_UP:
      NextPage(1, IfThen(OptionsValue.Paginate, OptionsValue.Page, OptionsValue.SmallChange));
    VK_LEFT, VK_DOWN:
      NextPage(-1, IfThen(OptionsValue.Paginate, OptionsValue.Page, OptionsValue.SmallChange));
    VK_DELETE:
      if OptionsValue.IsDefaultAssigned then
        SetPosition(OptionsValue.Default, True);
  else
    Exit;
  end;

  ShowMovingHint(Position, True);
  Key := 0;
end;

function TACLSlider.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
var
  ADelta: Single;
begin
  Result := not Moving;
  if Result then
  begin
    if OptionsValue.Paginate then
      ADelta := OptionsValue.Page
    else if OptionsValue.SmallChange > 0 then
      ADelta := OptionsValue.SmallChange
    else
      ADelta := OptionsValue.Range / ViewInfo.GetTrackSize;

    NextPage(WheelDelta, ADelta);
    ShowMovingHint(Position, True);
  end;
end;

procedure TACLSlider.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ANewPosition: Single;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if (Button = mbLeft) and not (ssDouble in Shift) then
  begin
    FMoving := PtInRect(ViewInfo.ThumbBarRect, Point(X, Y));
    if FMoving then
    begin
      ANewPosition := CalculatePosition(X, Y);
      if ANewPosition <> Position then
        InternalSetPosition(ANewPosition);
      ShowMovingHint(ANewPosition, False);
    end;
    UpdateThumbState(Point(X, Y));
  end;
end;

procedure TACLSlider.MouseLeave;
begin
  inherited MouseLeave;

  if not Moving then
    UpdateThumbState(InvalidPoint);
end;

procedure TACLSlider.MouseMove(Shift: TShiftState; X: Integer; Y: Integer);
var
  ANewPosition: Single;
begin
  inherited MouseMove(Shift, X, Y);

  if Moving then
  begin
    ANewPosition := CalculatePosition(X, Y);
    InternalSetPosition(ANewPosition);
    ShowMovingHint(ANewPosition, False);
  end
  else
    UpdateThumbState(Point(X, Y));
end;

procedure TACLSlider.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Moving then
  begin
    if not Options.ImmediateUpdate then
      SetPosition(FTempPosition, True);
    HideMovingHint;
    FMoving := False;
  end;
  if Button = mbRight then
  begin
    if OptionsValue.IsDefaultAssigned then
      SetPosition(OptionsValue.Default, True);
  end;
  UpdateThumbState(Point(X, Y));
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TACLSlider.HideMovingHint;
begin
  FreeAndNil(FMovingHintAutoHideTimer);
  FreeAndNil(FMovingHint);
end;

procedure TACLSlider.ShowMovingHint(APosition: Single; AAutoHide: Boolean);
var
  AHint: string;
begin
  AHint := '';
//  if OptionsLabels.IsCurrentValueMasked then
//    AHint := OptionsLabels.FormatCurrentValue(APosition);
  if Assigned(OnGetHint) then
    OnGetHint(Self, APosition, AHint);

  if AHint <> '' then
  begin
    Application.CancelHint;
    if FMovingHint = nil then
      FMovingHint := TACLHintWindow.Create(nil);
    FMovingHint.ShowFloatHint(AHint, Self, hwhaCenter, hwvaAbove);

    if AAutoHide then
    begin
      if FMovingHintAutoHideTimer = nil then
        FMovingHintAutoHideTimer := TACLTimer.CreateEx(MovingHintAutoHideTimerHandler, 1000, True);
      FMovingHintAutoHideTimer.Restart;
    end
    else
      FreeAndNil(FMovingHintAutoHideTimer);
  end;
end;

procedure TACLSlider.DoChanged(APosition: Single);
begin
  CallNotifyEvent(Self, OnChange);
end;

procedure TACLSlider.DrawText(ACanvas: TCanvas; const AViewInfo: TACLSliderTextViewInfo);
begin
  if not AViewInfo.Bounds.IsEmpty then
  begin
    Canvas.Font := Font;
    Canvas.Font.Color := AViewInfo.TextColor;
    Canvas.Brush.Style := bsClear;
    acTextDraw(ACanvas, AViewInfo.Text, AViewInfo.Bounds, AViewInfo.HorzAlignment, taAlignTop, True);
  end;
end;

procedure TACLSlider.DrawTickMarks(ACanvas: TCanvas);
var
  AColor: TAlphaColor;
  I: Integer;
begin
  AColor := Style.MarkColor[Enabled];
  if AColor.IsValid then
  begin
    for I := 0 to ViewInfo.TickMarks.Count - 1 do
      acFillRect(ACanvas, ViewInfo.TickMarks.List[I], AColor);
  end;
end;

procedure TACLSlider.DrawThumbBar(ACanvas: TCanvas; const ARect: TRect);
begin
  if not CallCustomDrawEvent(Self, OnDrawThumb, ACanvas, ARect) then
    Style.DrawThumb(ACanvas, ARect, FThumbState);
end;

procedure TACLSlider.DrawTrackBar(ACanvas: TCanvas; const ARect: TRect);
begin
  if not CallCustomDrawEvent(Self, OnDrawBackground, ACanvas, ARect) then
    Style.Draw(ACanvas, ARect, Enabled);
  if not ViewInfo.DefaultValueRect.IsEmpty then
    acFillRect(ACanvas, ViewInfo.DefaultValueRect, Style.ColorDefaultValue.Value);
end;

procedure TACLSlider.Paint;
begin
  DrawTrackBar(Canvas, ViewInfo.TrackBarRect);
  DrawThumbBar(Canvas, ViewInfo.ThumbRect);
  DrawTickMarks(Canvas);

  DrawText(Canvas, ViewInfo.LabelCurrentValue);
  DrawText(Canvas, ViewInfo.LabelMinValue);
  DrawText(Canvas, ViewInfo.LabelMaxValue);
end;

function TACLSlider.IsPositionStored: Boolean;
begin
  Result := not IsZero(FPosition)
end;

procedure TACLSlider.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if (csLoading in ComponentState) or IsInScaling then
    inherited SetBounds(ALeft, ATop, AWidth, AHeight)
  else
  begin
    ViewInfo.AdjustSize(AWidth, AHeight);
    inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  end;
end;

procedure TACLSlider.UpdateThumbState(const P: TPoint);
var
  ANewState: TACLButtonState;
begin
  ANewState := CalculateThumbState(P);
  if ANewState <> FThumbState then
  begin
    FThumbState := ANewState;
    InvalidateRect(ViewInfo.ThumbRect);
  end;
end;

procedure TACLSlider.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  UpdateThumbState(CalcCursorPos);
  Invalidate;
end;

procedure TACLSlider.CMHintShow(var Message: TCMHintShow);
begin
  if not FMoving then
    inherited;
end;

procedure TACLSlider.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS;
end;

procedure TACLSlider.MovingHintAutoHideTimerHandler(Sender: TObject);
begin
  if not FMoving then
    HideMovingHint;
  FreeAndNil(FMovingHintAutoHideTimer);
end;

function TACLSlider.GetPositionAsInteger: Integer;
begin
  Result := Round(Position);
end;

function TACLSlider.GetStyleSlider: TACLStyleSlider;
begin
  Result := TACLStyleSlider(inherited Style);
end;

procedure TACLSlider.InternalSetPosition(AValue: Single);
begin
  OptionsValue.Validate(AValue);
  if not Options.ImmediateUpdate and Moving then
    FTempPosition := AValue
  else
    Position := AValue;

  ViewInfo.Calculate;
  Invalidate;
end;

procedure TACLSlider.SetOptions(AValue: TACLSliderOptions);
begin
  FOptions.Assign(AValue);
end;

procedure TACLSlider.SetOptionsLabels(const Value: TACLSliderOptionsLabels);
begin
  FOptionsLabels.Assign(Value);
end;

procedure TACLSlider.SetOptionsValue(const Value: TACLSliderOptionsValue);
begin
  FOptionsValue.Assign(Value);
end;

procedure TACLSlider.SetOrientation(AValue: TACLOrientation);
begin
  if AValue <> FOrientation then
  begin
    FOrientation := AValue;
    if [csDesigning, csLoading] * ComponentState = [csDesigning] then
      SetBounds(Left, Top, Height, Width);
    FreeAndNil(FViewInfo);
    FViewInfo := CreateViewInfo;
    FullRefresh;
  end;
end;

procedure TACLSlider.SetPosition(APosition: Single);
begin
  SetPosition(APosition, Options.ImmediateUpdate);
end;

procedure TACLSlider.SetPosition(APosition: Single; ANotify: Boolean);
begin
  OptionsValue.Validate(APosition);
  if FPosition <> APosition then
  begin
    FPosition := APosition;
    if ANotify then
      DoChanged(APosition);
    Calculate;
    Invalidate;
  end;
end;

procedure TACLSlider.SetPositionAsInteger(const Value: Integer);
begin
  Position := Value;
end;

procedure TACLSlider.SetStyleSlider(const Value: TACLStyleSlider);
begin
  inherited Style := Value;
end;

end.
