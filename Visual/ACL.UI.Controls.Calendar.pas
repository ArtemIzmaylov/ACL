{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Calendar Control              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Calendar;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // Vcl
  Vcl.Graphics,
  Vcl.Controls,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.GdiPlus,
  ACL.UI.Animation,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Date;

const
  calcnValue = cccnLast + 1;
  calcnLast = calcnValue + 1;

type
  TACLCalendarSubClassScrollButtonCell = class;
  TACLCalendarSubClassTitleCell = class;
  TACLCalendarSubClassTodayCell = class;
  TACLCalendarSubClassViewInfo = class;

  { TACLStyleCalendar }

  TACLStyleCalendar = class(TACLStyle)
  protected
    procedure InitializeResources; override;
  published
    property ColorBackground: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorFrame: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorText: TACLResourceColor index 5 read GetColor write SetColor stored IsColorStored;
    property ColorTextDay: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorTextInactiveDay: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
    property ColorTextSelectedDay: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
    property ColorTextToday: TACLResourceColor index 6 read GetColor write SetColor stored IsColorStored;
    property ColorTextWeekend: TACLResourceColor index 7 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLCalendarSubClass }

  TACLCalendarSubClass = class(TACLCompoundControlSubClass)
  strict private
    FStyle: TACLStyleCalendar;
    FTransparent: Boolean;
    FValue: TDate;

    FOnSelect: TNotifyEvent;

    function GetViewInfo: TACLCalendarSubClassViewInfo; inline;
    procedure SetValue(const AValue: TDate);
  protected
    function CreateStyle: TACLStyleCalendar; virtual;
    function CreateViewInfo: TACLCompoundControlSubClassCustomViewInfo; override;
    function GetFullRefreshChanges: TIntegerSet; override;
    procedure DoSelected; virtual;
    procedure ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //
    property Style: TACLStyleCalendar read FStyle;
    property Transparent: Boolean read FTransparent write FTransparent;
    property Value: TDate read FValue write SetValue;
    property ViewInfo: TACLCalendarSubClassViewInfo read GetViewInfo;
    //
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
  end;

  { TACLCalendarSubClassCustomViewInfo }

  TACLCalendarSubClassCustomViewInfo = class(TACLCompoundControlSubClassCustomViewInfo)
  strict private
    function GetStyle: TACLStyleCalendar; inline;
    function GetSubClass: TACLCalendarSubClass; inline;
  public
    procedure Invalidate;
    //
    property Style: TACLStyleCalendar read GetStyle;
    property SubClass: TACLCalendarSubClass read GetSubClass;
  end;

  { TACLCalendarSubClassViewCustomCell }

  TACLCalendarSubClassViewCustomCell = class(TACLCalendarSubClassCustomViewInfo,
    IACLAnimateControl,
    IACLHotTrackObject)
  protected const
    TagAnimationFrame = 0;
  strict private
    function GetActualFrameColor: TAlphaColor;
    // IACLAnimateControl
    procedure IACLAnimateControl.Animate = Invalidate;
    // IACLHotTrackObject
    procedure Enter;
    procedure Leave;
  protected
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure DoDrawSelection(ACanvas: TCanvas; AColor: TAlphaColor);
    procedure PrepareCanvas(ACanvas: TCanvas); virtual;
    function GetDisplayValue: string; virtual; abstract;
    function GetTextColor: TColor; virtual;
    function GetTextStyle: TFontStyles; virtual;
    function IsSelected: Boolean; virtual;
  public
    destructor Destroy; override;
    //
    property DisplayValue: string read GetDisplayValue;
  end;

  { TACLCalendarSubClassAbstractViewViewInfo }

  TACLCalendarSubClassAbstractViewViewInfo = class(TACLCalendarSubClassCustomViewInfo)
  public
    procedure NextPage(ADirection: TACLMouseWheelDirection); virtual; abstract;
    procedure NextRow(ADirection: TACLMouseWheelDirection); virtual; abstract;
  end;

  { TACLCalendarSubClassCustomViewViewInfo }

  TACLCalendarSubClassCustomViewViewInfo = class(TACLCalendarSubClassAbstractViewViewInfo)
  strict private
    FInitialDate: TDate;

    procedure SetInitialDate(const AValue: TDate);
  protected
    FActualRangeFinish: TDate;
    FActualRangeStart: TDate;
    FCells: array of TACLCalendarSubClassViewCustomCell;
    FCellsArea: TRect;
    FCellsPerRow: Integer;
    FRangeFinish: TDate;
    FRangeStart: TDate;
    FScrollDown: TACLCalendarSubClassScrollButtonCell;
    FScrollUp: TACLCalendarSubClassScrollButtonCell;
    FTitle: TACLCalendarSubClassTitleCell;
    FToday: TACLCalendarSubClassTodayCell;

    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoCalculateLayout; virtual;
    procedure DoCalculateTitleArea(var ARect: TRect; AChanges: TIntegerSet);
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure DoDrawBackground(ACanvas: TCanvas);
    procedure DoUpdateRanges; virtual; abstract;
    function GetTitle: string; virtual; abstract;
    procedure IntializeCells; virtual; abstract;
    function IsOutOfActualRange(const AValue: TDate): Boolean;
    function IsSelected(const AValue: TDate): Boolean; virtual; abstract;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; override;
    //
    property CellsArea: TRect read FCellsArea;
    property InitialDate: TDate read FInitialDate write SetInitialDate;
  end;

  { TACLCalendarSubClassDayViewViewInfo }

  TACLCalendarSubClassDayViewViewInfo = class(TACLCalendarSubClassCustomViewViewInfo)
  protected
    FSelectedDay: TDate;

    procedure DoCalculateLayout; override;
    procedure DoUpdateRanges; override;
    function GetTitle: string; override;
    procedure IntializeCells; override;
    function IsSelected(const AValue: TDate): Boolean; override;
  public
    procedure NextPage(ADirection: TACLMouseWheelDirection); override;
    procedure NextRow(ADirection: TACLMouseWheelDirection); override;
  end;

  { TACLCalendarSubClassCustomDateCell }

  TACLCalendarSubClassCustomDateCell = class(TACLCalendarSubClassViewCustomCell)
  strict private
    FValue: TDate;
  protected
    FOwner: TACLCalendarSubClassCustomViewViewInfo;

    function GetDisplayValue: string; override;
    function GetTextColor: TColor; override;
    function GetTextStyle: TFontStyles; override;
    function IsSelected: Boolean; override;
  public
    constructor Create(AOwner: TACLCalendarSubClassCustomViewViewInfo); reintroduce;
    //
    property Value: TDate read FValue write FValue;
  end;

  { TACLCalendarSubClassDayCell }

  TACLCalendarSubClassDayCell = class(TACLCalendarSubClassCustomDateCell)
  protected
    FIsToday: Boolean;

    function GetTextColor: TColor; override;
  end;

  { TACLCalendarSubClassDayOfWeekCell }

  TACLCalendarSubClassDayOfWeekCell = class(TACLCalendarSubClassViewCustomCell)
  strict private
    FDayOfWeek: Byte;
  protected
    function GetDisplayValue: string; override;
  public
    constructor Create(ASubClass: TACLCalendarSubClass; ADayOfWeek: Byte); reintroduce;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; override;
  end;

  { TACLCalendarSubClassMonthCell }

  TACLCalendarSubClassMonthCell = class(TACLCalendarSubClassCustomDateCell)
  protected
    function GetDisplayValue: string; override;
  end;

  { TACLCalendarSubClassMonthViewViewInfo }

  TACLCalendarSubClassMonthViewViewInfo = class(TACLCalendarSubClassCustomViewViewInfo)
  protected
    FSelectedMonth: TDate;

    procedure DoUpdateRanges; override;
    function GetTitle: string; override;
    procedure IntializeCells; override;
    function IsSelected(const AValue: TDate): Boolean; override;
  public
    procedure NextPage(ADirection: TACLMouseWheelDirection); override;
    procedure NextRow(ADirection: TACLMouseWheelDirection); override;
  end;

  { TACLCalendarSubClassTodayCell }

  TACLCalendarSubClassTodayCell = class(TACLCalendarSubClassViewCustomCell)
  protected
    function GetDisplayValue: string; override;
    function GetTextColor: TColor; override;
    function GetTextStyle: TFontStyles; override;
  end;

  { TACLCalendarSubClassScrollButtonCell }

  TACLCalendarSubClassScrollButtonCell = class(TACLCalendarSubClassViewCustomCell)
  strict private
    FDirection: TACLMouseWheelDirection;
  protected
    function GetDisplayValue: string; override;
  public
    constructor Create(ASubClass: TACLCalendarSubClass; ADirection: TACLMouseWheelDirection); reintroduce;
    //
    property Direction: TACLMouseWheelDirection read FDirection;
  end;

  { TACLCalendarSubClassTitleCell }

  TACLCalendarSubClassTitleCell = class(TACLCalendarSubClassViewCustomCell)
  strict private
    FOwner: TACLCalendarSubClassCustomViewViewInfo;
  protected
    function GetDisplayValue: string; override;
    procedure PrepareCanvas(ACanvas: TCanvas); override;
  public
    constructor Create(AOwner: TACLCalendarSubClassCustomViewViewInfo); reintroduce;
    procedure Calculate(const R: TRect; AChanges: TIntegerSet); override;
  end;

  { TACLCalendarSubClassViewInfo }

  TACLCalendarSubClassViewInfo = class(TACLCalendarSubClassAbstractViewViewInfo,
    IACLAnimateControl)
  strict private
    FActiveView: TACLCalendarSubClassCustomViewViewInfo;
    FDayView: TACLCalendarSubClassDayViewViewInfo;
    FMonthView: TACLCalendarSubClassMonthViewViewInfo;

    // IACLAnimateControl
    procedure IACLAnimateControl.Animate = Invalidate;
  protected
    procedure DoActivateView(AView: TACLCalendarSubClassCustomViewViewInfo; const AInitialDate: TDate);
    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure PrepareAnimationFrame(AFrame: TACLBitmap; const P: TPoint);
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    procedure ActivateDayView(const AMonth: TDateTime);
    procedure ActivateMonthView;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; override;
    procedure NextPage(ADirection: TACLMouseWheelDirection); override;
    procedure NextRow(ADirection: TACLMouseWheelDirection); override;
    procedure Select(const ADate: TDateTime);
    //
    property ActiveView: TACLCalendarSubClassCustomViewViewInfo read FActiveView;
  end;

  { TACLCustomCalendar }

  TACLCustomCalendar = class(TACLCompoundControl)
  strict private
    function GetOnSelect: TNotifyEvent;
    function GetStyle: TACLStyleCalendar;
    function GetSubClass: TACLCalendarSubClass; inline;
    function GetTransparent: Boolean;
    function GetValue: TDate;
    procedure SetOnSelect(const Value: TNotifyEvent);
    procedure SetStyle(AValue: TACLStyleCalendar);
    procedure SetTransparent(const Value: Boolean);
    procedure SetValue(const Value: TDate);
  protected
    function CreateSubClass: TACLCompoundControlSubClass; override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    //
    property Style: TACLStyleCalendar read GetStyle write SetStyle;
    //
    property OnSelect: TNotifyEvent read GetOnSelect write SetOnSelect;
  public
    property SubClass: TACLCalendarSubClass read GetSubClass;
    property Transparent: Boolean read GetTransparent write SetTransparent default False;
    property Value: TDate read GetValue write SetValue;
  end;

  { TACLCalendar }

  TACLCalendar = class(TACLCustomCalendar)
  published
    property ResourceCollection;
    property Style;
    property Value;
    property Transparent;
    //
    property OnSelect;
  end;

implementation

uses
  Math, DateUtils;

{ TACLStyleCalendar }

procedure TACLStyleCalendar.InitializeResources;
begin
  inherited;
  ColorBackground.InitailizeDefaults('Common.Colors.Content', TAlphaColor.FromColor(clWhite));
  ColorFrame.InitailizeDefaults('Calendar.Colors.Frame', TAlphaColor.FromColor(clHighlight));
  ColorText.InitailizeDefaults('Calendar.Colors.Text', clBlack);
  ColorTextDay.InitailizeDefaults('Calendar.Colors.TextDay', clBlack);
  ColorTextInactiveDay.InitailizeDefaults('Calendar.Colors.TextInactiveDay', clGray);
  ColorTextSelectedDay.InitailizeDefaults('Calendar.Colors.TextSelectedDay', clNavy);
  ColorTextToday.InitailizeDefaults('Calendar.Colors.TextToday', clBlue);
  ColorTextWeekend.InitailizeDefaults('Calendar.Colors.TextWeekend', clMaroon);
end;

{ TACLCalendarSubClass }

constructor TACLCalendarSubClass.Create(AOwner: TComponent);
begin
  inherited;
  FStyle := CreateStyle;
end;

destructor TACLCalendarSubClass.Destroy;
begin
  FreeAndNil(FStyle);
  inherited;
end;

procedure TACLCalendarSubClass.DoSelected;
begin
  if Assigned(OnSelect) then
    OnSelect(Container.GetControl);
end;

function TACLCalendarSubClass.GetFullRefreshChanges: TIntegerSet;
begin
  Result := inherited + [calcnValue];
end;

procedure TACLCalendarSubClass.SetValue(const AValue: TDate);
begin
  if FValue <> AValue then
  begin
    FValue := AValue;
    DoSelected;
    Changed([calcnValue]);
  end;
end;

function TACLCalendarSubClass.CreateStyle: TACLStyleCalendar;
begin
  Result := TACLStyleCalendar.Create(Self);
end;

function TACLCalendarSubClass.CreateViewInfo: TACLCompoundControlSubClassCustomViewInfo;
begin
  Result := TACLCalendarSubClassViewInfo.Create(Self);
end;

function TACLCalendarSubClass.GetViewInfo: TACLCalendarSubClassViewInfo;
begin
  Result := TACLCalendarSubClassViewInfo(inherited ViewInfo);
end;

procedure TACLCalendarSubClass.ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState);
begin
  inherited;

  if AButton <> mbLeft then
    Exit;

  if HitTest.HitObject is TACLCalendarSubClassMonthCell then
    ViewInfo.ActivateDayView(TACLCalendarSubClassMonthCell(HitTest.HitObject).Value)
  else if HitTest.HitObject is TACLCalendarSubClassDayCell then
    Value := TACLCalendarSubClassDayCell(HitTest.HitObject).Value + TimeOf(Value)
  else if HitTest.HitObject is TACLCalendarSubClassScrollButtonCell then
    ViewInfo.NextPage(TACLCalendarSubClassScrollButtonCell(HitTest.HitObject).Direction)
  else if HitTest.HitObject is TACLCalendarSubClassTitleCell then
    ViewInfo.ActivateMonthView
  else if HitTest.HitObject is TACLCalendarSubClassTodayCell then
    ViewInfo.Select(Now);
end;

procedure TACLCalendarSubClass.ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);
begin
  ViewInfo.NextRow(ADirection);
end;

{ TACLCalendarSubClassCustomViewInfo }

procedure TACLCalendarSubClassCustomViewInfo.Invalidate;
begin
  SubClass.InvalidateRect(Bounds);
end;

function TACLCalendarSubClassCustomViewInfo.GetStyle: TACLStyleCalendar;
begin
  Result := SubClass.Style;
end;

function TACLCalendarSubClassCustomViewInfo.GetSubClass: TACLCalendarSubClass;
begin
  Result := TACLCalendarSubClass(inherited SubClass);
end;

{ TACLCalendarSubClassViewCustomCell }

destructor TACLCalendarSubClassViewCustomCell.Destroy;
begin
  AnimationManager.RemoveOwner(Self);
  inherited;
end;

procedure TACLCalendarSubClassViewCustomCell.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
begin
  inherited;
  AInfo.Cursor := crHandPoint;
end;

procedure TACLCalendarSubClassViewCustomCell.DoDraw(ACanvas: TCanvas);
begin
  PrepareCanvas(ACanvas);
  acTextDraw(ACanvas, DisplayValue, Bounds, taCenter, taVerticalCenter);
  DoDrawSelection(ACanvas, GetActualFrameColor);
end;

procedure TACLCalendarSubClassViewCustomCell.DoDrawSelection(ACanvas: TCanvas; AColor: TAlphaColor);
const
  FrameSize = 2;
begin
  if AColor <> TAlphaColor.None then
    acDrawFrame(ACanvas.Handle, Bounds, AColor, ScaleFactor.Apply(FrameSize));
end;

function TACLCalendarSubClassViewCustomCell.GetTextColor: TColor;
begin
  Result := Style.ColorText.AsColor;
end;

function TACLCalendarSubClassViewCustomCell.GetTextStyle: TFontStyles;
begin
  Result := [];
end;

function TACLCalendarSubClassViewCustomCell.IsSelected: Boolean;
begin
  Result := False;
end;

procedure TACLCalendarSubClassViewCustomCell.PrepareCanvas(ACanvas: TCanvas);
begin
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font := SubClass.Font;
  ACanvas.Font.Style := GetTextStyle;
  ACanvas.Font.Color := GetTextColor;
end;

procedure TACLCalendarSubClassViewCustomCell.Enter;
begin
  AnimationManager.RemoveOwner(Self);
  Invalidate;
end;

procedure TACLCalendarSubClassViewCustomCell.Leave;
var
  AAnimation: TACLAnimation;
begin
  if IsSelected then
    Exit;
  if acUIFadingEnabled then
  begin
    AAnimation := TACLAnimation.Create(Self, acUIFadingTime);
    AAnimation.Tag := TagAnimationFrame;
    AAnimation.Run;
  end
  else
    Invalidate
end;

function TACLCalendarSubClassViewCustomCell.GetActualFrameColor: TAlphaColor;
var
  AAnimation: TACLAnimation;
begin
  if AnimationManager.Find(Self, AAnimation, TagAnimationFrame) then
  begin
    Result := Style.ColorFrame.Value;
    Result.A := Trunc(Result.A * (1 - AAnimation.Progress));
  end
  else
    if (SubClass.HoveredObject = Self) or IsSelected then
      Result := Style.ColorFrame.Value
    else
      Result := TAlphaColor.None;
end;

{ TACLCalendarSubClassCustomViewViewInfo }

constructor TACLCalendarSubClassCustomViewViewInfo.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited;
  FTitle := TACLCalendarSubClassTitleCell.Create(Self);
  FScrollDown := TACLCalendarSubClassScrollButtonCell.Create(SubClass, mwdUp);
  FScrollUp := TACLCalendarSubClassScrollButtonCell.Create(SubClass, mwdDown);
  FToday := TACLCalendarSubClassTodayCell.Create(SubClass);
end;

destructor TACLCalendarSubClassCustomViewViewInfo.Destroy;
var
  I: Integer;
begin
  for I := Low(FCells) to High(FCells) do
    FreeAndNil(FCells[I]);
  FreeAndNil(FToday);
  FreeAndNil(FScrollDown);
  FreeAndNil(FScrollUp);
  FreeAndNil(FTitle);
  inherited;
end;

procedure TACLCalendarSubClassCustomViewViewInfo.AfterConstruction;
begin
  inherited;
  IntializeCells;
end;

procedure TACLCalendarSubClassCustomViewViewInfo.BeforeDestruction;
begin
  inherited;
  AnimationManager.RemoveOwner(Self);
end;

function TACLCalendarSubClassCustomViewViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
var
  I: Integer;
begin
  if FTitle.CalculateHitTest(AInfo) then
    Exit(True);
  if FScrollDown.CalculateHitTest(AInfo) then
    Exit(True);
  if FScrollUp.CalculateHitTest(AInfo) then
    Exit(True);
  if FToday.CalculateHitTest(AInfo) then
    Exit(True);
  for I := Low(FCells) to High(FCells) do
  begin
    if FCells[I].CalculateHitTest(AInfo) then
      Exit(True);
  end;
  Result := False;
end;

procedure TACLCalendarSubClassCustomViewViewInfo.DoCalculate(AChanges: TIntegerSet);
begin
  if calcnValue in AChanges then
  begin
    if not InRange(DateOf(SubClass.Value), FRangeStart, FRangeFinish) then
      InitialDate := StartOfTheMonth(SubClass.Value);
    DoUpdateRanges;
  end;
  if cccnLayout in AChanges then
    DoCalculateLayout;
end;

procedure TACLCalendarSubClassCustomViewViewInfo.DoCalculateLayout;
var
  ABounds: TRect;
  ACellHeight: Integer;
  ACellWidth: Integer;
  ARowCount: Integer;
  X, Y: Integer;
begin
  ABounds := Bounds;
  DoCalculateTitleArea(ABounds, []);
  ARowCount := Ceil(Length(FCells) / FCellsPerRow);
  ACellHeight := ABounds.Height div ARowCount;
  ACellWidth := ABounds.Width div FCellsPerRow;
  for X := 0 to FCellsPerRow - 1 do
    for Y := 0 to ARowCount - 1 do
    begin
      FCells[Y * FCellsPerRow + X].Calculate(System.Types.Bounds(
        ABounds.Left + X * ACellWidth, ABounds.Top + Y * ACellHeight, ACellWidth, ACellHeight), []);
    end;

  FCellsArea := FCells[Low(FCells)].Bounds;
  for X := Low(FCells) + 1 to High(FCells) do
    acRectUnion(FCellsArea, FCells[X].Bounds);
end;

procedure TACLCalendarSubClassCustomViewViewInfo.DoCalculateTitleArea(var ARect: TRect; AChanges: TIntegerSet);
var
  R: TRect;
begin
  R := ARect;
  FTitle.Calculate(R, AChanges);
  R.Bottom := FTitle.Bounds.Bottom;
  R.Left := R.Right - R.Height;
  FScrollUp.Calculate(R, AChanges);
  R := acRectOffset(R, -R.Height, 0);
  FScrollDown.Calculate(R, AChanges);
  ARect.Top := R.Bottom;
  FToday.Calculate(acRectSetBottom(ARect, ARect.Bottom, FTitle.Bounds.Height), AChanges);
  ARect.Bottom := FToday.Bounds.Top;
end;

procedure TACLCalendarSubClassCustomViewViewInfo.DoDraw(ACanvas: TCanvas);
var
  I: Integer;
begin
  DoDrawBackground(ACanvas);
  FTitle.Draw(ACanvas);
  FScrollDown.Draw(ACanvas);
  FScrollUp.Draw(ACanvas);
  FToday.Draw(ACanvas);
  for I := Low(FCells) to High(FCells) do
    FCells[I].Draw(ACanvas);
end;

procedure TACLCalendarSubClassCustomViewViewInfo.DoDrawBackground(ACanvas: TCanvas);
begin
  if not SubClass.Transparent then
    acFillRect(ACanvas.Handle, Bounds, Style.ColorBackground.Value);
end;

function TACLCalendarSubClassCustomViewViewInfo.IsOutOfActualRange(const AValue: TDate): Boolean;
begin
  Result := (CompareDateTime(AValue, FActualRangeStart) < 0) or (CompareDateTime(AValue, FActualRangeFinish) > 0);
end;

procedure TACLCalendarSubClassCustomViewViewInfo.SetInitialDate(const AValue: TDate);
begin
  if not SameDate(AValue, InitialDate) then
  begin
    FInitialDate := AValue;
    DoUpdateRanges;
    Invalidate;
  end;
end;

{ TACLCalendarSubClassDayViewViewInfo }

procedure TACLCalendarSubClassDayViewViewInfo.NextPage(ADirection: TACLMouseWheelDirection);
begin
  InitialDate := TACLDateUtils.AddMonths(InitialDate, Signs[ADirection = mwdDown]);
end;

procedure TACLCalendarSubClassDayViewViewInfo.NextRow(ADirection: TACLMouseWheelDirection);
begin
  InitialDate := TACLDateUtils.AddDays(InitialDate, Signs[ADirection = mwdDown] * FCellsPerRow);
end;

procedure TACLCalendarSubClassDayViewViewInfo.DoCalculateLayout;
begin
  inherited;
  FCellsArea.Top := FCells[7].Bounds.Top;
end;

procedure TACLCalendarSubClassDayViewViewInfo.DoUpdateRanges;
var
  ACell: TACLCalendarSubClassDayCell;
  ANow: TDateTime;
  I: Integer;
begin
  ANow := Now;
  FSelectedDay := DateOf(SubClass.Value);

  FRangeStart := TACLDateUtils.GetStartOfWeek(InitialDate);
  FRangeFinish := FRangeStart;
  for I := 7 to 48 do
  begin
    ACell := TACLCalendarSubClassDayCell(FCells[I]);
    ACell.FIsToday := SameDate(ANow, FRangeFinish);
    ACell.Value := FRangeFinish;
    FRangeFinish := FRangeFinish + 1;
  end;
  FRangeFinish := FRangeFinish - 1;

  FActualRangeStart := TACLDateUtils.GetStartOfMonth(InitialDate);
  if (FRangeStart >= FActualRangeStart) and (TACLDateUtils.GetDayOfMonth(FRangeStart) > 15) then
    FActualRangeStart := TACLDateUtils.AddMonths(FActualRangeStart, 1);
  FActualRangeFinish := TACLDateUtils.GetEndOfMonth(FActualRangeStart);

  DoCalculateLayout;
end;

function TACLCalendarSubClassDayViewViewInfo.GetTitle: string;
begin
  Result := Format('%s %d', [FormatSettings.LongMonthNames[MonthOf(FActualRangeStart)], YearOf(FActualRangeStart)]);
end;

procedure TACLCalendarSubClassDayViewViewInfo.IntializeCells;
var
  I: Integer;
begin
  FCellsPerRow := 7;
  SetLength(FCells, 49);
  for I := 0 to 6 do
    FCells[I] := TACLCalendarSubClassDayOfWeekCell.Create(SubClass, I + 1);
  for I := 7 to 48 do
    FCells[I] := TACLCalendarSubClassDayCell.Create(Self);
end;

function TACLCalendarSubClassDayViewViewInfo.IsSelected(const AValue: TDate): Boolean;
begin
  Result := SameDate(FSelectedDay, AValue)
end;

{ TACLCalendarSubClassCustomDateCell }

constructor TACLCalendarSubClassCustomDateCell.Create(AOwner: TACLCalendarSubClassCustomViewViewInfo);
begin
  inherited Create(AOwner.SubClass);
  FOwner := AOwner;
end;

function TACLCalendarSubClassCustomDateCell.GetDisplayValue: string;
begin
  Result := IntToStr(DayOfTheMonth(Value));
end;

function TACLCalendarSubClassCustomDateCell.GetTextColor: TColor;
var
  AColorResource: TACLResourceColor;
begin
  if IsSelected then
    AColorResource := Style.ColorTextSelectedDay
  else if FOwner.IsOutOfActualRange(Value) then
    AColorResource := Style.ColorTextInactiveDay
  else
    AColorResource := Style.ColorTextDay;

  Result := AColorResource.AsColor;
end;

function TACLCalendarSubClassCustomDateCell.GetTextStyle: TFontStyles;
begin
  if IsSelected then
    Result := [fsBold]
  else
    Result := [];
end;

function TACLCalendarSubClassCustomDateCell.IsSelected: Boolean;
begin
  Result := FOwner.IsSelected(Value);
end;

{ TACLCalendarSubClassDayCell }

function TACLCalendarSubClassDayCell.GetTextColor: TColor;
var
  AColorResource: TACLResourceColor;
begin
  if IsSelected then
    AColorResource := Style.ColorTextSelectedDay
  else if FIsToday then
    AColorResource := Style.ColorTextToday
  else if FOwner.IsOutOfActualRange(Value) then
    AColorResource := Style.ColorTextInactiveDay
  else if TACLDateUtils.IsWeekend(Value) then
    AColorResource := Style.ColorTextWeekend
  else
    AColorResource := Style.ColorTextDay;

  Result := AColorResource.AsColor;
end;

{ TACLCalendarSubClassDayOfWeekCell }

constructor TACLCalendarSubClassDayOfWeekCell.Create(ASubClass: TACLCalendarSubClass; ADayOfWeek: Byte);
begin
  inherited Create(ASubClass);
  FDayOfWeek := ADayOfWeek;
end;

function TACLCalendarSubClassDayOfWeekCell.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  Result := False;
end;

function TACLCalendarSubClassDayOfWeekCell.GetDisplayValue: string;
begin
  Result := TACLDateUtils.GetDayOfWeekName(FDayOfWeek, True);
end;

{ TACLCalendarSubClassMonthCell }

function TACLCalendarSubClassMonthCell.GetDisplayValue: string;
begin
  Result := FormatSettings.LongMonthNames[TACLDateUtils.GetMonthOfYear(Value)];
end;

{ TACLCalendarSubClassMonthViewViewInfo }

procedure TACLCalendarSubClassMonthViewViewInfo.NextPage(ADirection: TACLMouseWheelDirection);
begin
  InitialDate := TACLDateUtils.AddYears(InitialDate, Signs[ADirection = mwdDown]);
end;

procedure TACLCalendarSubClassMonthViewViewInfo.NextRow(ADirection: TACLMouseWheelDirection);
begin
  InitialDate := TACLDateUtils.AddMonths(InitialDate, Signs[ADirection = mwdDown] * FCellsPerRow);
end;

procedure TACLCalendarSubClassMonthViewViewInfo.DoUpdateRanges;
var
  I: Integer;
begin
  FSelectedMonth := TACLDateUtils.GetStartOfMonth(SubClass.Value);

  FRangeStart := TACLDateUtils.GetStartOfMonth(InitialDate);
  FRangeFinish := FRangeStart;
  for I := Low(FCells) to High(FCells) do
  begin
    TACLCalendarSubClassMonthCell(FCells[I]).Value := FRangeFinish;
    FRangeFinish := TACLDateUtils.AddMonths(FRangeFinish, 1);
  end;
  FRangeFinish := TACLDateUtils.AddMonths(FRangeFinish, -1);

  FActualRangeStart := TACLDateUtils.GetStartOfYear(InitialDate);
  if (FRangeStart >= FActualRangeStart) and (TACLDateUtils.GetMonthOfYear(FRangeStart) > 6) then
    FActualRangeStart := TACLDateUtils.AddYears(FActualRangeStart, 1);
  FActualRangeFinish := TACLDateUtils.GetEndOfYear(FActualRangeStart);
end;

function TACLCalendarSubClassMonthViewViewInfo.GetTitle: string;
begin
  Result := IntToStr(YearOf(FActualRangeStart));
end;

procedure TACLCalendarSubClassMonthViewViewInfo.IntializeCells;
var
  I: Integer;
begin
  FCellsPerRow := 3;
  SetLength(FCells, 12);
  for I := Low(FCells) to High(FCells) do
    FCells[I] := TACLCalendarSubClassMonthCell.Create(Self);
end;

function TACLCalendarSubClassMonthViewViewInfo.IsSelected(const AValue: TDate): Boolean;
begin
  Result := SameDate(AValue, FSelectedMonth);
end;

{ TACLCalendarSubClassTodayCell }

function TACLCalendarSubClassTodayCell.GetDisplayValue: string;
begin
  Result := FormatDateTime(FormatSettings.LongDateFormat, Now);
end;

function TACLCalendarSubClassTodayCell.GetTextColor: TColor;
begin
  Result := Style.ColorTextToday.AsColor;
end;

function TACLCalendarSubClassTodayCell.GetTextStyle: TFontStyles;
begin
  Result := [];
end;

{ TACLCalendarSubClassScrollButtonCell }

constructor TACLCalendarSubClassScrollButtonCell.Create(ASubClass: TACLCalendarSubClass; ADirection: TACLMouseWheelDirection);
begin
  inherited Create(ASubClass);
  FDirection := ADirection;
end;

function TACLCalendarSubClassScrollButtonCell.GetDisplayValue: string;
begin
  if Direction = mwdDown then
    Result := '>'
  else
    Result := '<';
end;

{ TACLCalendarSubClassTitleCell }

constructor TACLCalendarSubClassTitleCell.Create(AOwner: TACLCalendarSubClassCustomViewViewInfo);
begin
  FOwner := AOwner;
  inherited Create(AOwner.SubClass);
end;

procedure TACLCalendarSubClassTitleCell.Calculate(const R: TRect; AChanges: TIntegerSet);
var
  AIndent: Integer;
  ATextSize: TSize;
begin
  MeasureCanvas.Font := SubClass.Font;
  ATextSize := MeasureCanvas.TextExtent('Qq');
  AIndent := (R.Width div 7 - ATextSize.cx) div 2;

  PrepareCanvas(MeasureCanvas);
  ATextSize := MeasureCanvas.TextExtent(DisplayValue);
  inherited Calculate(acRectSetSize(R, ATextSize.cx + 2 * AIndent, ATextSize.cy + 2 * Min(AIndent, acIndentBetweenElements)), AChanges);
end;

function TACLCalendarSubClassTitleCell.GetDisplayValue: string;
begin
  Result := FOwner.GetTitle;
end;

procedure TACLCalendarSubClassTitleCell.PrepareCanvas(ACanvas: TCanvas);
begin
  inherited;
  ACanvas.Font.Size := ACanvas.Font.Size + 2;
end;

{ TACLCalendarSubClassViewInfo }

constructor TACLCalendarSubClassViewInfo.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited;
  FDayView := TACLCalendarSubClassDayViewViewInfo.Create(ASubClass);
  FMonthView := TACLCalendarSubClassMonthViewViewInfo.Create(ASubClass);
  FActiveView := FDayView;
end;

destructor TACLCalendarSubClassViewInfo.Destroy;
begin
  AnimationManager.RemoveOwner(Self);
  FreeAndNil(FMonthView);
  FreeAndNil(FDayView);
  inherited;
end;

procedure TACLCalendarSubClassViewInfo.ActivateDayView(const AMonth: TDateTime);
begin
  DoActivateView(FDayView, AMonth);
end;

procedure TACLCalendarSubClassViewInfo.ActivateMonthView;
begin
  DoActivateView(FMonthView, TACLDateUtils.GetStartOfYear(FDayView.InitialDate));
end;

function TACLCalendarSubClassViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  Result := ActiveView.CalculateHitTest(AInfo);
end;

procedure TACLCalendarSubClassViewInfo.NextPage(ADirection: TACLMouseWheelDirection);
const
  ModeMap: array[TACLMouseWheelDirection] of TACLBitmapSlideAnimationMode = (samBottomToTop, samTopToBottom);
var
  AAnimation: TACLCustomBitmapAnimation;
begin
  if acUIFadingEnabled then
  begin
    AAnimation := TACLBitmapSlideAnimation.Create(ModeMap[ADirection], Self, acUIFadingTime);
    PrepareAnimationFrame(AAnimation.AllocateFrame1(ActiveView.CellsArea), ActiveView.CellsArea.TopLeft);
    ActiveView.NextPage(ADirection);
    PrepareAnimationFrame(AAnimation.AllocateFrame2(ActiveView.CellsArea), ActiveView.CellsArea.TopLeft);
    AAnimation.Run;
  end
  else
    ActiveView.NextPage(ADirection);
end;

procedure TACLCalendarSubClassViewInfo.NextRow(ADirection: TACLMouseWheelDirection);
begin
  ActiveView.NextRow(ADirection);
end;

procedure TACLCalendarSubClassViewInfo.Select(const ADate: TDateTime);
var
  AAnimation: TACLCustomBitmapAnimation;
begin
  if ADate <> SubClass.Value then
  begin
    if acUIFadingEnabled then
    begin
      AAnimation := TACLBitmapFadingAnimation.Create(Self, acUIFadingTime);
      PrepareAnimationFrame(AAnimation.AllocateFrame1(ActiveView.Bounds), Bounds.TopLeft);
      SubClass.Value := ADate;
      PrepareAnimationFrame(AAnimation.AllocateFrame2(ActiveView.Bounds), Bounds.TopLeft);
      AAnimation.Run;
    end
    else
      SubClass.Value := ADate;
  end;
end;

procedure TACLCalendarSubClassViewInfo.DoActivateView(AView: TACLCalendarSubClassCustomViewViewInfo; const AInitialDate: TDate);

  procedure DoActivateViewCore;
  begin
    FActiveView := AView;
    DoCalculate(SubClass.GetFullRefreshChanges);
    FActiveView.InitialDate := AInitialDate;
  end;

const
  ModeMap: array[Boolean] of TACLBitmapZoomAnimationMode = (zamZoomIn, zamZoomOut);
var
  AAnimation: TACLCustomBitmapAnimation;
begin
  if ActiveView <> AView then
  begin
    if acUIFadingEnabled then
    begin
      AAnimation := TACLBitmapZoomAnimation.Create(ModeMap[AView = FMonthView], Self, acUIFadingTime);
      PrepareAnimationFrame(AAnimation.AllocateFrame1(Bounds), Bounds.TopLeft);
      DoActivateViewCore;
      PrepareAnimationFrame(AAnimation.AllocateFrame2(Bounds), Bounds.TopLeft);
      AAnimation.Run;
    end
    else
      DoActivateViewCore;
  end;
end;

procedure TACLCalendarSubClassViewInfo.DoCalculate(AChanges: TIntegerSet);
begin
  ActiveView.Calculate(Bounds, AChanges);
end;

procedure TACLCalendarSubClassViewInfo.DoDraw(ACanvas: TCanvas);
var
  AAnimation: TACLAnimation;
  ASaveIndex: Integer;
begin
  if AnimationManager.Find(Self, AAnimation) then
  begin
    if AAnimation is TACLBitmapSlideAnimation then
    begin
      ASaveIndex := SaveDC(ACanvas.Handle);
      try
        AAnimation.Draw(ACanvas.Handle, ActiveView.CellsArea);
        acExcludeFromClipRegion(ACanvas.Handle, ActiveView.CellsArea);
        ActiveView.Draw(ACanvas);
      finally
        RestoreDC(ACanvas.Handle, ASaveIndex);
      end;
    end
    else
      AAnimation.Draw(ACanvas.Handle, Bounds);
  end
  else
    ActiveView.Draw(ACanvas);
end;

procedure TACLCalendarSubClassViewInfo.PrepareAnimationFrame(AFrame: TACLBitmap; const P: TPoint);
begin
  DrawTo(AFrame.Canvas, Bounds.Left - P.X, Bounds.Top - P.Y);
  AFrame.MakeOpaque;
end;

{ TACLCustomCalendar }

function TACLCustomCalendar.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLCalendarSubClass.Create(Self);
end;

function TACLCustomCalendar.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if Transparent then
    Result := cbsTransparent
  else
    if Style.ColorBackground.HasAlpha then
      Result := cbsSemitransparent
    else
      Result := cbsOpaque;
end;

function TACLCustomCalendar.GetOnSelect: TNotifyEvent;
begin
  Result := SubClass.OnSelect;
end;

function TACLCustomCalendar.GetStyle: TACLStyleCalendar;
begin
  Result := SubClass.Style;
end;

function TACLCustomCalendar.GetSubClass: TACLCalendarSubClass;
begin
  Result := TACLCalendarSubClass(inherited SubClass);
end;

function TACLCustomCalendar.GetTransparent: Boolean;
begin
  Result := SubClass.Transparent;
end;

function TACLCustomCalendar.GetValue: TDate;
begin
  Result := SubClass.Value;
end;

procedure TACLCustomCalendar.SetOnSelect(const Value: TNotifyEvent);
begin
  SubClass.OnSelect := Value;
end;

procedure TACLCustomCalendar.SetStyle(AValue: TACLStyleCalendar);
begin
  SubClass.Style.Assign(AValue);
end;

procedure TACLCustomCalendar.SetTransparent(const Value: Boolean);
begin
  if Transparent <> Value then
  begin
    SubClass.Transparent := Value;
    UpdateTransparency;
  end;
end;

procedure TACLCustomCalendar.SetValue(const Value: TDate);
begin
  SubClass.Value := Value;
end;

end.
