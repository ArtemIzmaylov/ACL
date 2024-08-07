////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Calendar
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.Calendar;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // Vcl
  {Vcl.}Graphics,
  {Vcl.}Controls,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.UI.Animation,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Date;

const
  calcnValue = cccnLast + 1;
  calcnLast = calcnValue + 1;

type
  TACLCalendarScrollButtonCell = class;
  TACLCalendarTitleCell = class;
  TACLCalendarTodayCell = class;
  TACLCalendarViewInfo = class;

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

    function GetViewInfo: TACLCalendarViewInfo; inline;
    procedure SetValue(const AValue: TDate);
  protected
    function CreateStyle: TACLStyleCalendar; virtual;
    function CreateViewInfo: TACLCompoundControlCustomViewInfo; override;
    function GetFullRefreshChanges: TIntegerSet; override;
    procedure DoSelected; virtual;
    procedure ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //# Properties
    property Style: TACLStyleCalendar read FStyle;
    property Transparent: Boolean read FTransparent write FTransparent;
    property Value: TDate read FValue write SetValue;
    property ViewInfo: TACLCalendarViewInfo read GetViewInfo;
    //# Events
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
  end;

  { TACLCalendarCustomViewInfo }

  TACLCalendarCustomViewInfo = class(TACLCompoundControlCustomViewInfo)
  strict private
    function GetStyle: TACLStyleCalendar; inline;
    function GetSubClass: TACLCalendarSubClass; inline;
  public
    procedure Invalidate;
    //# Properties
    property Style: TACLStyleCalendar read GetStyle;
    property SubClass: TACLCalendarSubClass read GetSubClass;
  end;

  { TACLCalendarViewCustomCell }

  TACLCalendarViewCustomCell = class(TACLCalendarCustomViewInfo,
    IACLAnimateControl,
    IACLHotTrackObject)
  protected const
    TagAnimationFrame = 0;
  strict private
    // IACLAnimateControl
    procedure IACLAnimateControl.Animate = Invalidate;
    // IACLHotTrackObject
    procedure OnHotTrack(Action: TACLHotTrackAction);
  protected
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure DoDrawSelection(ACanvas: TCanvas; AColor: TAlphaColor);
    procedure PrepareCanvas(ACanvas: TCanvas); virtual;
    function GetActualFrameColor: TAlphaColor;
    function GetDisplayValue: string; virtual; abstract;
    function GetTextColor: TColor; virtual;
    function GetTextStyle: TFontStyles; virtual;
    function IsSelected: Boolean; virtual;
  public
    destructor Destroy; override;
    //# Properties
    property DisplayValue: string read GetDisplayValue;
  end;

  { TACLCalendarAbstractViewViewInfo }

  TACLCalendarAbstractViewViewInfo = class(TACLCalendarCustomViewInfo)
  public
    procedure NextPage(ADirection: TACLMouseWheelDirection); virtual; abstract;
    procedure NextRow(ADirection: TACLMouseWheelDirection); virtual; abstract;
  end;

  { TACLCalendarCustomViewViewInfo }

  TACLCalendarCustomViewViewInfo = class(TACLCalendarAbstractViewViewInfo)
  strict private
    FInitialDate: TDate;

    procedure SetInitialDate(const AValue: TDate);
  protected
    FActualRangeFinish: TDate;
    FActualRangeStart: TDate;
    FCells: array of TACLCalendarViewCustomCell;
    FCellsArea: TRect;
    FCellsPerRow: Integer;
    FRangeFinish: TDate;
    FRangeStart: TDate;
    FScrollDown: TACLCalendarScrollButtonCell;
    FScrollUp: TACLCalendarScrollButtonCell;
    FTitle: TACLCalendarTitleCell;
    FToday: TACLCalendarTodayCell;

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
    //# Properties
    property CellsArea: TRect read FCellsArea;
    property InitialDate: TDate read FInitialDate write SetInitialDate;
  end;

  { TACLCalendarDayViewViewInfo }

  TACLCalendarDayViewViewInfo = class(TACLCalendarCustomViewViewInfo)
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

  { TACLCalendarCustomDateCell }

  TACLCalendarCustomDateCell = class(TACLCalendarViewCustomCell)
  strict private
    FValue: TDate;
  protected
    FOwner: TACLCalendarCustomViewViewInfo;

    function GetDisplayValue: string; override;
    function GetTextColor: TColor; override;
    function GetTextStyle: TFontStyles; override;
    function IsSelected: Boolean; override;
  public
    constructor Create(AOwner: TACLCalendarCustomViewViewInfo); reintroduce;
    //# Properties
    property Value: TDate read FValue write FValue;
  end;

  { TACLCalendarDayCell }

  TACLCalendarDayCell = class(TACLCalendarCustomDateCell)
  protected
    FIsToday: Boolean;
    function GetTextColor: TColor; override;
  end;

  { TACLCalendarDayOfWeekCell }

  TACLCalendarDayOfWeekCell = class(TACLCalendarViewCustomCell)
  strict private
    FDayOfWeek: Byte;
  protected
    function GetDisplayValue: string; override;
  public
    constructor Create(ASubClass: TACLCalendarSubClass; ADayOfWeek: Byte); reintroduce;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; override;
  end;

  { TACLCalendarMonthCell }

  TACLCalendarMonthCell = class(TACLCalendarCustomDateCell)
  protected
    function GetDisplayValue: string; override;
  end;

  { TACLCalendarMonthViewViewInfo }

  TACLCalendarMonthViewViewInfo = class(TACLCalendarCustomViewViewInfo)
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

  { TACLCalendarTodayCell }

  TACLCalendarTodayCell = class(TACLCalendarViewCustomCell)
  protected
    function GetDisplayValue: string; override;
    function GetTextColor: TColor; override;
    function GetTextStyle: TFontStyles; override;
  end;

  { TACLCalendarScrollButtonCell }

  TACLCalendarScrollButtonCell = class(TACLCalendarViewCustomCell)
  strict private
    FDirection: TACLMouseWheelDirection;
  protected
    function GetDisplayValue: string; override;
    procedure DoDraw(ACanvas: TCanvas); override;
  public
    constructor Create(ASubClass: TACLCalendarSubClass;
      ADirection: TACLMouseWheelDirection); reintroduce;
    //# Properties
    property Direction: TACLMouseWheelDirection read FDirection;
  end;

  { TACLCalendarTitleCell }

  TACLCalendarTitleCell = class(TACLCalendarViewCustomCell)
  strict private
    FOwner: TACLCalendarCustomViewViewInfo;
  protected
    function GetDisplayValue: string; override;
    procedure PrepareCanvas(ACanvas: TCanvas); override;
  public
    constructor Create(AOwner: TACLCalendarCustomViewViewInfo); reintroduce;
    procedure Calculate(const R: TRect; AChanges: TIntegerSet); override;
  end;

  { TACLCalendarViewInfo }

  TACLCalendarViewInfo = class(TACLCalendarAbstractViewViewInfo,
    IACLAnimateControl)
  strict private
    FActiveView: TACLCalendarCustomViewViewInfo;
    FDayView: TACLCalendarDayViewViewInfo;
    FMonthView: TACLCalendarMonthViewViewInfo;

    // IACLAnimateControl
    procedure IACLAnimateControl.Animate = Invalidate;
  protected
    procedure DoActivateView(AView: TACLCalendarCustomViewViewInfo; const AInitialDate: TDate);
    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure PrepareAnimationFrame(AFrame: TACLDib; const P: TPoint);
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    procedure ActivateDayView(const AMonth: TDateTime);
    procedure ActivateMonthView;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; override;
    procedure NextPage(ADirection: TACLMouseWheelDirection); override;
    procedure NextRow(ADirection: TACLMouseWheelDirection); override;
    procedure Select(const ADate: TDateTime);
    //# Properties
    property ActiveView: TACLCalendarCustomViewViewInfo read FActiveView;
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
    procedure UpdateTransparency; override;
    //# Properties
    property Style: TACLStyleCalendar read GetStyle write SetStyle;
    //# Events
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
    //# Events
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

function TACLCalendarSubClass.CreateViewInfo: TACLCompoundControlCustomViewInfo;
begin
  Result := TACLCalendarViewInfo.Create(Self);
end;

function TACLCalendarSubClass.GetViewInfo: TACLCalendarViewInfo;
begin
  Result := TACLCalendarViewInfo(inherited ViewInfo);
end;

procedure TACLCalendarSubClass.ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState);
begin
  inherited;

  if AButton <> mbLeft then
    Exit;

  if HitTest.HitObject is TACLCalendarMonthCell then
    ViewInfo.ActivateDayView(TACLCalendarMonthCell(HitTest.HitObject).Value)
  else if HitTest.HitObject is TACLCalendarDayCell then
    Value := TACLCalendarDayCell(HitTest.HitObject).Value + TimeOf(Value)
  else if HitTest.HitObject is TACLCalendarScrollButtonCell then
    ViewInfo.NextPage(TACLCalendarScrollButtonCell(HitTest.HitObject).Direction)
  else if HitTest.HitObject is TACLCalendarTitleCell then
    ViewInfo.ActivateMonthView
  else if HitTest.HitObject is TACLCalendarTodayCell then
    ViewInfo.Select(Now);
end;

procedure TACLCalendarSubClass.ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);
begin
  ViewInfo.NextRow(ADirection);
end;

{ TACLCalendarCustomViewInfo }

procedure TACLCalendarCustomViewInfo.Invalidate;
begin
  SubClass.InvalidateRect(Bounds);
end;

function TACLCalendarCustomViewInfo.GetStyle: TACLStyleCalendar;
begin
  Result := SubClass.Style;
end;

function TACLCalendarCustomViewInfo.GetSubClass: TACLCalendarSubClass;
begin
  Result := TACLCalendarSubClass(inherited SubClass);
end;

{ TACLCalendarViewCustomCell }

destructor TACLCalendarViewCustomCell.Destroy;
begin
  AnimationManager.RemoveOwner(Self);
  inherited;
end;

procedure TACLCalendarViewCustomCell.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
begin
  inherited;
  AInfo.Cursor := crHandPoint;
end;

procedure TACLCalendarViewCustomCell.DoDraw(ACanvas: TCanvas);
begin
  PrepareCanvas(ACanvas);
  acTextDraw(ACanvas, DisplayValue, Bounds, taCenter, taVerticalCenter);
  DoDrawSelection(ACanvas, GetActualFrameColor);
end;

procedure TACLCalendarViewCustomCell.DoDrawSelection(ACanvas: TCanvas; AColor: TAlphaColor);
const
  FrameSize = 2;
begin
  if AColor <> TAlphaColor.None then
    acDrawFrame(ACanvas, Bounds, AColor, dpiApply(FrameSize, CurrentDpi));
end;

function TACLCalendarViewCustomCell.GetTextColor: TColor;
begin
  Result := Style.ColorText.AsColor;
end;

function TACLCalendarViewCustomCell.GetTextStyle: TFontStyles;
begin
  Result := [];
end;

function TACLCalendarViewCustomCell.IsSelected: Boolean;
begin
  Result := False;
end;

procedure TACLCalendarViewCustomCell.PrepareCanvas(ACanvas: TCanvas);
begin
  ACanvas.SetScaledFont(SubClass.Font);
  ACanvas.Font.Color := GetTextColor;
  ACanvas.Font.Style := GetTextStyle;
  ACanvas.Font.ResolveHeight;
  ACanvas.Brush.Style := bsClear;
end;

procedure TACLCalendarViewCustomCell.OnHotTrack(Action: TACLHotTrackAction);
var
  AAnimation: TACLAnimation;
begin
  case Action of
    htaEnter:
      begin
        AnimationManager.RemoveOwner(Self);
        Invalidate;
      end;

    htaLeave:
      if not IsSelected then
      begin
        if acUIFadingEnabled then
        begin
          AAnimation := TACLAnimation.Create(Self, acUIFadingTime);
          AAnimation.Tag := TagAnimationFrame;
          AAnimation.Run;
        end
        else
          Invalidate;
      end;
  else;
  end
end;

function TACLCalendarViewCustomCell.GetActualFrameColor: TAlphaColor;
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

{ TACLCalendarCustomViewViewInfo }

constructor TACLCalendarCustomViewViewInfo.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited;
  FTitle := TACLCalendarTitleCell.Create(Self);
  FScrollDown := TACLCalendarScrollButtonCell.Create(SubClass, mwdUp);
  FScrollUp := TACLCalendarScrollButtonCell.Create(SubClass, mwdDown);
  FToday := TACLCalendarTodayCell.Create(SubClass);
end;

destructor TACLCalendarCustomViewViewInfo.Destroy;
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

procedure TACLCalendarCustomViewViewInfo.AfterConstruction;
begin
  inherited;
  IntializeCells;
end;

procedure TACLCalendarCustomViewViewInfo.BeforeDestruction;
begin
  inherited;
  AnimationManager.RemoveOwner(Self);
end;

function TACLCalendarCustomViewViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
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

procedure TACLCalendarCustomViewViewInfo.DoCalculate(AChanges: TIntegerSet);
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

procedure TACLCalendarCustomViewViewInfo.DoCalculateLayout;
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
      FCells[Y * FCellsPerRow + X].Calculate(
        Types.Bounds(
          ABounds.Left + X * ACellWidth,
          ABounds.Top + Y * ACellHeight,
          ACellWidth, ACellHeight), []);
    end;

  FCellsArea := FCells[Low(FCells)].Bounds;
  for X := Low(FCells) + 1 to High(FCells) do
    FCellsArea.Add(FCells[X].Bounds);
end;

procedure TACLCalendarCustomViewViewInfo.DoCalculateTitleArea(var ARect: TRect; AChanges: TIntegerSet);
var
  R: TRect;
begin
  R := ARect;
  FTitle.Calculate(R, AChanges);
  R.Bottom := FTitle.Bounds.Bottom;
  R.Left := R.Right - R.Height;
  FScrollUp.Calculate(R, AChanges);
  R.Offset(-R.Height, 0);
  FScrollDown.Calculate(R, AChanges);
  ARect.Top := R.Bottom;
  FToday.Calculate(ARect.Split(srBottom, FTitle.Bounds.Height), AChanges);
  ARect.Bottom := FToday.Bounds.Top;
end;

procedure TACLCalendarCustomViewViewInfo.DoDraw(ACanvas: TCanvas);
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

procedure TACLCalendarCustomViewViewInfo.DoDrawBackground(ACanvas: TCanvas);
begin
  if not SubClass.Transparent then
    acFillRect(ACanvas, Bounds, Style.ColorBackground.Value);
end;

function TACLCalendarCustomViewViewInfo.IsOutOfActualRange(const AValue: TDate): Boolean;
begin
  Result :=
    (CompareDateTime(AValue, FActualRangeStart) < 0) or
    (CompareDateTime(AValue, FActualRangeFinish) > 0);
end;

procedure TACLCalendarCustomViewViewInfo.SetInitialDate(const AValue: TDate);
begin
  if not SameDate(AValue, InitialDate) then
  begin
    FInitialDate := AValue;
    DoUpdateRanges;
    Invalidate;
  end;
end;

{ TACLCalendarDayViewViewInfo }

procedure TACLCalendarDayViewViewInfo.NextPage(ADirection: TACLMouseWheelDirection);
begin
  InitialDate := TACLDateUtils.AddMonths(InitialDate, Signs[ADirection = mwdDown]);
end;

procedure TACLCalendarDayViewViewInfo.NextRow(ADirection: TACLMouseWheelDirection);
begin
  InitialDate := TACLDateUtils.AddDays(InitialDate, Signs[ADirection = mwdDown] * FCellsPerRow);
end;

procedure TACLCalendarDayViewViewInfo.DoCalculateLayout;
begin
  inherited;
  FCellsArea.Top := FCells[7].Bounds.Top;
end;

procedure TACLCalendarDayViewViewInfo.DoUpdateRanges;
var
  ACell: TACLCalendarDayCell;
  ANow: TDateTime;
  I: Integer;
begin
  ANow := Now;
  FSelectedDay := DateOf(SubClass.Value);

  FRangeStart := TACLDateUtils.GetStartOfWeek(InitialDate);
  FRangeFinish := FRangeStart;
  for I := 7 to 48 do
  begin
    ACell := TACLCalendarDayCell(FCells[I]);
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

function TACLCalendarDayViewViewInfo.GetTitle: string;
begin
  Result := Format('%s %d', [FormatSettings.LongMonthNames[MonthOf(FActualRangeStart)], YearOf(FActualRangeStart)]);
end;

procedure TACLCalendarDayViewViewInfo.IntializeCells;
var
  I: Integer;
begin
  FCellsPerRow := 7;
  SetLength(FCells, 49);
  for I := 0 to 6 do
    FCells[I] := TACLCalendarDayOfWeekCell.Create(SubClass, I + 1);
  for I := 7 to 48 do
    FCells[I] := TACLCalendarDayCell.Create(Self);
end;

function TACLCalendarDayViewViewInfo.IsSelected(const AValue: TDate): Boolean;
begin
  Result := SameDate(FSelectedDay, AValue)
end;

{ TACLCalendarCustomDateCell }

constructor TACLCalendarCustomDateCell.Create(AOwner: TACLCalendarCustomViewViewInfo);
begin
  inherited Create(AOwner.SubClass);
  FOwner := AOwner;
end;

function TACLCalendarCustomDateCell.GetDisplayValue: string;
begin
  Result := IntToStr(DayOfTheMonth(Value));
end;

function TACLCalendarCustomDateCell.GetTextColor: TColor;
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

function TACLCalendarCustomDateCell.GetTextStyle: TFontStyles;
begin
  if IsSelected then
    Result := [fsBold]
  else
    Result := [];
end;

function TACLCalendarCustomDateCell.IsSelected: Boolean;
begin
  Result := FOwner.IsSelected(Value);
end;

{ TACLCalendarDayCell }

function TACLCalendarDayCell.GetTextColor: TColor;
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

{ TACLCalendarDayOfWeekCell }

constructor TACLCalendarDayOfWeekCell.Create(ASubClass: TACLCalendarSubClass; ADayOfWeek: Byte);
begin
  inherited Create(ASubClass);
  FDayOfWeek := ADayOfWeek;
end;

function TACLCalendarDayOfWeekCell.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  Result := False;
end;

function TACLCalendarDayOfWeekCell.GetDisplayValue: string;
begin
  Result := TACLDateUtils.GetDayOfWeekName(FDayOfWeek, True);
end;

{ TACLCalendarMonthCell }

function TACLCalendarMonthCell.GetDisplayValue: string;
begin
  Result := FormatSettings.LongMonthNames[TACLDateUtils.GetMonthOfYear(Value)];
end;

{ TACLCalendarMonthViewViewInfo }

procedure TACLCalendarMonthViewViewInfo.NextPage(ADirection: TACLMouseWheelDirection);
begin
  InitialDate := TACLDateUtils.AddYears(InitialDate, Signs[ADirection = mwdDown]);
end;

procedure TACLCalendarMonthViewViewInfo.NextRow(ADirection: TACLMouseWheelDirection);
begin
  InitialDate := TACLDateUtils.AddMonths(InitialDate, Signs[ADirection = mwdDown] * FCellsPerRow);
end;

procedure TACLCalendarMonthViewViewInfo.DoUpdateRanges;
var
  I: Integer;
begin
  FSelectedMonth := TACLDateUtils.GetStartOfMonth(SubClass.Value);

  FRangeStart := TACLDateUtils.GetStartOfMonth(InitialDate);
  FRangeFinish := FRangeStart;
  for I := Low(FCells) to High(FCells) do
  begin
    TACLCalendarMonthCell(FCells[I]).Value := FRangeFinish;
    FRangeFinish := TACLDateUtils.AddMonths(FRangeFinish, 1);
  end;
  FRangeFinish := TACLDateUtils.AddMonths(FRangeFinish, -1);

  FActualRangeStart := TACLDateUtils.GetStartOfYear(InitialDate);
  if (FRangeStart >= FActualRangeStart) and (TACLDateUtils.GetMonthOfYear(FRangeStart) > 6) then
    FActualRangeStart := TACLDateUtils.AddYears(FActualRangeStart, 1);
  FActualRangeFinish := TACLDateUtils.GetEndOfYear(FActualRangeStart);
end;

function TACLCalendarMonthViewViewInfo.GetTitle: string;
begin
  Result := IntToStr(YearOf(FActualRangeStart));
end;

procedure TACLCalendarMonthViewViewInfo.IntializeCells;
var
  I: Integer;
begin
  FCellsPerRow := 3;
  SetLength(FCells, 12);
  for I := Low(FCells) to High(FCells) do
    FCells[I] := TACLCalendarMonthCell.Create(Self);
end;

function TACLCalendarMonthViewViewInfo.IsSelected(const AValue: TDate): Boolean;
begin
  Result := SameDate(AValue, FSelectedMonth);
end;

{ TACLCalendarTodayCell }

function TACLCalendarTodayCell.GetDisplayValue: string;
begin
  Result := FormatDateTime(FormatSettings.LongDateFormat, Now);
end;

function TACLCalendarTodayCell.GetTextColor: TColor;
begin
  Result := Style.ColorTextToday.AsColor;
end;

function TACLCalendarTodayCell.GetTextStyle: TFontStyles;
begin
  Result := [];
end;

{ TACLCalendarScrollButtonCell }

constructor TACLCalendarScrollButtonCell.Create(
  ASubClass: TACLCalendarSubClass; ADirection: TACLMouseWheelDirection);
begin
  inherited Create(ASubClass);
  FDirection := ADirection;
end;

function TACLCalendarScrollButtonCell.GetDisplayValue: string;
begin
  if Direction = mwdDown then
    Result := '>'
  else
    Result := '<';
end;

procedure TACLCalendarScrollButtonCell.DoDraw(ACanvas: TCanvas);
const
  Map: array[Boolean] of TACLArrowKind = (makLeft, makRight);
begin
  acDrawArrow(ACanvas, Bounds, GetTextColor, Map[Direction = mwdDown], 192);
  DoDrawSelection(ACanvas, GetActualFrameColor);
end;

{ TACLCalendarTitleCell }

constructor TACLCalendarTitleCell.Create(AOwner: TACLCalendarCustomViewViewInfo);
begin
  FOwner := AOwner;
  inherited Create(AOwner.SubClass);
end;

procedure TACLCalendarTitleCell.Calculate(const R: TRect; AChanges: TIntegerSet);
var
  AIndent: Integer;
  ATextSize: TSize;
begin
  MeasureCanvas.SetScaledFont(SubClass.Font);
  ATextSize := MeasureCanvas.TextExtent('Qq');
  AIndent := (R.Width div 7 - ATextSize.cx) div 2;

  PrepareCanvas(MeasureCanvas);
  ATextSize := MeasureCanvas.TextExtent(DisplayValue);
  inherited Calculate(TRect.Create(R.TopLeft,
    ATextSize.cx + 2 * AIndent,
    ATextSize.cy + 2 * Min(AIndent, acIndentBetweenElements)), AChanges);
end;

function TACLCalendarTitleCell.GetDisplayValue: string;
begin
  Result := FOwner.GetTitle;
end;

procedure TACLCalendarTitleCell.PrepareCanvas(ACanvas: TCanvas);
begin
  inherited;
  ACanvas.Font.Size := ACanvas.Font.Size + 2;
end;

{ TACLCalendarViewInfo }

constructor TACLCalendarViewInfo.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited;
  FDayView := TACLCalendarDayViewViewInfo.Create(ASubClass);
  FMonthView := TACLCalendarMonthViewViewInfo.Create(ASubClass);
  FActiveView := FDayView;
end;

destructor TACLCalendarViewInfo.Destroy;
begin
  AnimationManager.RemoveOwner(Self);
  FreeAndNil(FMonthView);
  FreeAndNil(FDayView);
  inherited;
end;

procedure TACLCalendarViewInfo.ActivateDayView(const AMonth: TDateTime);
begin
  DoActivateView(FDayView, AMonth);
end;

procedure TACLCalendarViewInfo.ActivateMonthView;
begin
  DoActivateView(FMonthView, TACLDateUtils.GetStartOfYear(FDayView.InitialDate));
end;

function TACLCalendarViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  Result := ActiveView.CalculateHitTest(AInfo);
end;

procedure TACLCalendarViewInfo.NextPage(ADirection: TACLMouseWheelDirection);
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

procedure TACLCalendarViewInfo.NextRow(ADirection: TACLMouseWheelDirection);
begin
  ActiveView.NextRow(ADirection);
end;

procedure TACLCalendarViewInfo.Select(const ADate: TDateTime);
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

procedure TACLCalendarViewInfo.DoActivateView(AView: TACLCalendarCustomViewViewInfo; const AInitialDate: TDate);

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

procedure TACLCalendarViewInfo.DoCalculate(AChanges: TIntegerSet);
begin
  ActiveView.Calculate(Bounds, AChanges);
end;

procedure TACLCalendarViewInfo.DoDraw(ACanvas: TCanvas);
var
  AAnimation: TACLAnimation;
  APrevRgn: TRegionHandle;
begin
  if AnimationManager.Find(Self, AAnimation) then
  begin
    if AAnimation is TACLBitmapSlideAnimation then
    begin
      APrevRgn := acSaveClipRegion(ACanvas.Handle);
      try
        AAnimation.Draw(ACanvas, ActiveView.CellsArea);
        acExcludeFromClipRegion(ACanvas.Handle, ActiveView.CellsArea);
        ActiveView.Draw(ACanvas);
      finally
        acRestoreClipRegion(ACanvas.Handle, APrevRgn);
      end;
    end
    else
      AAnimation.Draw(ACanvas, Bounds);
  end
  else
    ActiveView.Draw(ACanvas);
end;

procedure TACLCalendarViewInfo.PrepareAnimationFrame(AFrame: TACLDib; const P: TPoint);
begin
  if SubClass.Transparent then
  begin
    acDrawTransparentControlBackground(
      SubClass.Container.GetControl, AFrame.Handle, AFrame.ClientRect, False);
  end;
  DrawTo(AFrame.Canvas, Bounds.Left - P.X, Bounds.Top - P.Y);
  AFrame.MakeOpaque;
end;

{ TACLCustomCalendar }

function TACLCustomCalendar.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLCalendarSubClass.Create(Self);
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
    Invalidate;
  end;
end;

procedure TACLCustomCalendar.SetValue(const Value: TDate);
begin
  SubClass.Value := Value;
end;

procedure TACLCustomCalendar.UpdateTransparency;
begin
  if Transparent or Style.ColorBackground.HasAlpha then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque];
end;

end.
