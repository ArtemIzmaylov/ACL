{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*              Date Utilities               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.Date;

interface

uses
  Winapi.Windows;

type
  TCalendarId = type DWORD;

  TWeekDay = (wdMonday, wdTuesday, wdWednesday, wdThusday, wdFriday, wdSaturday, wdSunday);
  TWeekDays = set of TWeekDay;

  { TWeekDaysHelper }

  TWeekDaysHelper = record helper for TWeekDays
  public
    class function FromInteger(AValue: Integer): TWeekDays; static;
    function ToInteger: Integer;
  end;

  { TACLDateUtils }

  TACLDateUtils = class
  strict private
    class var FFirstDayInWeek: TWeekDay;
    class var FWeekLayout: array[1..7] of TWeekDay;

    class procedure InitializeWeekLayout;
  public
    class constructor Create;
    class function AddDays(const AValue: TDateTime; ACount: Integer): TDateTime;
    class function AddMonths(const AValue: TDateTime; ACount: Integer; ADayOfMonth: Byte = 0): TDateTime;
    class function AddWeeks(const AValue: TDateTime; ACount: Integer): TDateTime;
    class function AddYears(const AValue: TDateTime; ACount: Integer; ADayOfMonth: Byte = 0): TDateTime;
    class function GetDayOfMonth(const AValue: TDateTime): Byte;
    class function GetDayOfWeek(const AValue: TDateTime): Byte;
    class function GetDayOfWeekName(ADay: Byte; AShort: Boolean): string;
    class function GetDaysInMonth(const AValue: TDateTime): Byte;
    class function GetEndOfMonth(const AValue: TDateTime): TDateTime;
    class function GetEndOfYear(const AValue: TDateTime): TDateTime;
    class function GetMonthOfYear(const AValue: TDateTime): Byte;
    class function GetNearestFutureValue(const ANow, ACurrentValue, ADelta: TDateTime): TDateTime;
    class function GetStartOfMonth(const AValue: TDateTime): TDateTime;
    class function GetStartOfWeek(const AValue: TDateTime): TDateTime;
    class function GetStartOfYear(const AValue: TDateTime): TDateTime;
    class function InRange(const AValue, AMinDate, AMaxDate{Non-inclusive}: TDateTime): Boolean;
    class function IsWeekend(const AValue: TDateTime): Boolean;
    class function DateTimeToMilliseconds(const AValue: TDateTime): UInt64;
    class function DateTimeToSeconds(const AValue: TDateTime): UInt64;
    class function MillisecondsToDateTime(const AValue: UInt64): TDateTime;
    class function MinutesToDateTime(const AValue: Integer): TDateTime;
    class function SecondsToDateTime(const AValue: UInt64): TDateTime;
    // Conversion
    class function DayOfWeekToWeekDay(ADayOfWeek: Byte): TWeekDay;
    class function WeekDayToDayOfWeek(AWeekDay: TWeekDay): Byte;
    // just for testing
    class procedure SetFirstDayInWeek(AValue: TWeekDay);
  end;

implementation

uses
  System.Math,
  System.DateUtils,
  System.SysUtils;

function GetCalendarID(Locale: LCID): TCalendarId; overload;
begin
  GetLocaleInfo(Locale, LOCALE_ICALENDARTYPE or CAL_RETURN_NUMBER, @Result, SizeOf(Result));
end;

function GetCalendarID: TCalendarId; overload;
begin
  Result := GetCalendarID(GetThreadLocale);
end;

{ TWeekDaysHelper }

class function TWeekDaysHelper.FromInteger(AValue: Integer): TWeekDays;
var
  I: TWeekDay;
begin
  Result := [];
  for I := Low(TWeekDay) to High(TWeekDay) do
  begin
    if AValue and (1 shl Ord(I)) <> 0 then
      Include(Result, I);
  end;
end;

function TWeekDaysHelper.ToInteger: Integer;
var
  I: TWeekDay;
begin
  Result := 0;
  for I := Low(TWeekDay) to High(TWeekDay) do
  begin
    if I in Self then
      Inc(Result, 1 shl Ord(I));
  end;
end;

{ TCalendar }

class function TACLDateUtils.AddDays(const AValue: TDateTime; ACount: Integer): TDateTime;
begin
  Result := AValue + ACount;
end;

class function TACLDateUtils.AddMonths(const AValue: TDateTime; ACount: Integer; ADayOfMonth: Byte = 0): TDateTime;
var
  AYear, M, ADay: Word;
  AMonth: Integer;
begin
  DecodeDate(AValue, AYear, M, ADay);
  if ADayOfMonth <> 0 then
    ADay := ADayOfMonth;

  AMonth := Integer(M) + ACount;
  while AMonth <= 0 do
  begin
    Inc(AMonth, MonthsPerYear);
    Dec(AYear);
  end;
  while AMonth > MonthsPerYear do
  begin
    Dec(AMonth, MonthsPerYear);
    Inc(AYear);
  end;
  ADay := Min(ADay, DaysInAMonth(AYear, AMonth));

  Result := EncodeDate(AYear, AMonth, ADay) + TimeOf(AValue);
end;

class function TACLDateUtils.AddWeeks(const AValue: TDateTime; ACount: Integer): TDateTime;
begin
  Result := AddDays(AValue, ACount * DaysPerWeek);
end;

class function TACLDateUtils.AddYears(const AValue: TDateTime; ACount: Integer; ADayOfMonth: Byte = 0): TDateTime;
var
  AYear, AMonth, ADay: Word;
begin
  DecodeDate(AValue, AYear, AMonth, ADay);
  if ADayOfMonth <> 0 then
    ADay := ADayOfMonth;
  AYear := AYear + ACount;
  ADay := Min(ADay, DaysInAMonth(AYear, AMonth));
  Result := EncodeDate(AYear, AMonth, ADay) + TimeOf(AValue);
end;

class constructor TACLDateUtils.Create;
begin
  case GetCalendarID of
    CAL_GREGORIAN, CAL_GREGORIAN_US, CAL_HIJRI:
      SetFirstDayInWeek(wdSunday);
    CAL_GREGORIAN_ARABIC:
      SetFirstDayInWeek(wdSaturday);
  else
    SetFirstDayInWeek(wdMonday);
  end;
end;

class function TACLDateUtils.GetDayOfMonth(const AValue: TDateTime): Byte;
begin
  Result := System.DateUtils.DayOfTheMonth(AValue);
end;

class function TACLDateUtils.GetDayOfWeek(const AValue: TDateTime): Byte;
begin
  Result := Trunc(AValue) - Trunc(GetStartOfWeek(AValue)) + 1;
end;

class function TACLDateUtils.GetDayOfWeekName(ADay: Byte; AShort: Boolean): string;
const
  FormatSettignsDaysLayout: array[TWeekDay] of Integer = (2, 3, 4, 5, 6, 7, 1);
begin
  ADay := FormatSettignsDaysLayout[DayOfWeekToWeekDay(ADay)];
  if AShort then
    Result := FormatSettings.ShortDayNames[ADay]
  else
    Result := FormatSettings.LongDayNames[ADay];
end;

class function TACLDateUtils.GetDaysInMonth(const AValue: TDateTime): Byte;
begin
  Result := DaysInMonth(AValue);
end;

class function TACLDateUtils.GetEndOfMonth(const AValue: TDateTime): TDateTime;
begin
  Result := EndOfTheMonth(AValue);
end;

class function TACLDateUtils.GetEndOfYear(const AValue: TDateTime): TDateTime;
begin
  Result := EndOfTheYear(AValue)
end;

class function TACLDateUtils.GetMonthOfYear(const AValue: TDateTime): Byte;
begin
  Result := MonthOf(AValue);
end;

class function TACLDateUtils.GetNearestFutureValue(const ANow, ACurrentValue, ADelta: TDateTime): TDateTime;
begin
  if (ADelta < 0) or IsZero(ADelta) then
    raise EInvalidArgument.Create('Datetime delta must be a positive value');

  Result := ACurrentValue;
  if Result > ANow then
  begin
    while Result - ADelta > ANow do
      Result := Result - ADelta;
  end
  else
    while Result < ANow do
      Result := Result + ADelta;
end;

class function TACLDateUtils.GetStartOfMonth(const AValue: TDateTime): TDateTime;
begin
  Result := StartOfTheMonth(AValue);
end;

class function TACLDateUtils.GetStartOfWeek(const AValue: TDateTime): TDateTime;
const
  OffsetDistance: array[TWeekDay] of Integer = (0, 6, 5, 4, 3, 2, 1);
begin
  Result := AddDays(AValue, OffsetDistance[FFirstDayInWeek]);
  Result := System.DateUtils.StartOfTheWeek(Result); // always starts from Monday
  Result := AddDays(Result, -OffsetDistance[FFirstDayInWeek]);
end;

class function TACLDateUtils.GetStartOfYear(const AValue: TDateTime): TDateTime;
begin
  Result := StartOfTheYear(AValue);
end;

class procedure TACLDateUtils.InitializeWeekLayout;
var
  AIndex: TWeekDay;
  I: Integer;
begin
  AIndex := FFirstDayInWeek;
  for I := 1 to 7 do
  begin
    FWeekLayout[I] := AIndex;
    AIndex := TWeekDay((Ord(AIndex) + 1) mod (Ord(High(TWeekDay)) - Ord(Low(TWeekDay)) + 1));
  end;
end;

class function TACLDateUtils.InRange(const AValue, AMinDate, AMaxDate: TDateTime): Boolean;
begin
  try
    Result := System.Math.InRange(DateTimeToSeconds(AValue), DateTimeToSeconds(AMinDate), DateTimeToSeconds(AMaxDate));
  except
    Result := (AValue >= AMinDate) and (AValue <= AMaxDate);
  end;
end;

class function TACLDateUtils.IsWeekend(const AValue: TDateTime): Boolean;
begin
  Result := DayOfWeekToWeekDay(GetDayOfWeek(AValue)) in [wdSaturday, wdSunday];
end;

class function TACLDateUtils.DateTimeToMilliseconds(const AValue: TDateTime): UInt64;
var
  H, M, S, MSec: Word;
begin
  DecodeTime(TimeOf(AValue), H, M, S, MSec);
  Result := UInt64(DaysBetween(DateOf(AValue), 0)) * MSecsPerDay;
  Result := Result + (H * SecsPerHour + M * SecsPerMin + S) * MSecsPerSec + MSec;
end;

class function TACLDateUtils.DateTimeToSeconds(const AValue: TDateTime): UInt64;
begin
  Result := DateTimeToMilliseconds(AValue) div MSecsPerSec;
end;

class function TACLDateUtils.MillisecondsToDateTime(const AValue: UInt64): TDateTime;
var
  ATime: UInt64;
  ADays: UInt64;
  TS: TTimeStamp;
begin
  DivMod(AValue, MSecsPerDay, ADays, ATime);
  TS.Time := ATime;
  TS.Date := DateDelta;
  Result := TimeStampToDateTime(TS) + ADays;
end;

class function TACLDateUtils.MinutesToDateTime(const AValue: Integer): TDateTime;
begin
  Result := SecondsToDateTime(AValue * SecsPerMin);
end;

class function TACLDateUtils.SecondsToDateTime(const AValue: UInt64): TDateTime;
begin
  Result := MillisecondsToDateTime(AValue * MSecsPerSec);
end;

class function TACLDateUtils.DayOfWeekToWeekDay(ADayOfWeek: Byte): TWeekDay;
begin
  Result := FWeekLayout[ADayOfWeek];
end;

class function TACLDateUtils.WeekDayToDayOfWeek(AWeekDay: TWeekDay): Byte;
var
  I: Integer;
begin
  for I := Low(FWeekLayout) to High(FWeekLayout) do
  begin
    if FWeekLayout[I] = AWeekDay then
      Exit(I);
  end;
  Result := 0;
end;

class procedure TACLDateUtils.SetFirstDayInWeek(AValue: TWeekDay);
begin
  FFirstDayInWeek := AValue;
  InitializeWeekLayout;
end;

end.
