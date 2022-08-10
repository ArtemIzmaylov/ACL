{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Editors Controls              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.DateTimeEdit;

{$I ACL.Config.inc}

interface

uses
  Winapi.Messages,
  Winapi.Windows,
  // System
  System.Classes,
  System.DateUtils,
  System.Types,
  System.UITypes,
  // VCL
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Graphics,
  Vcl.ImgList,
  // ACL
  ACL.Classes,
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Utils.Common,
  ACL.UI.Dialogs,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.Calendar,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.SpinEdit,
  ACL.UI.Controls.TimeEdit,
  ACL.UI.Forms;

type

  { TACLDateTimeEdit }

  TACLDateTimeEditMode = (dtmDateAndTime, dtmDate);

  TACLDateTimeEdit = class(TACLCustomComboBox)
  strict private
    FMode: TACLDateTimeEditMode;
    FStyleCalendar: TACLStyleCalendar;
    FStylePushButton: TACLStyleButton;
    FStyleSpinButton: TACLStyleButton;

    FOnSelect: TNotifyEvent;

    function IsValueStored: Boolean;
    procedure SetMode(AValue: TACLDateTimeEditMode);
    procedure SetStyleCalendar(const Value: TACLStyleCalendar);
    procedure SetStylePushButton(const Value: TACLStyleButton);
    procedure SetStyleSpinButton(const Value: TACLStyleButton);
  protected
    procedure Changed; override;
    function GetDropDownFormClass: TACLCustomPopupFormClass; override;
    function TextToValue(const AText: string): Variant; override;
    function ValueToText(const AValue: Variant): string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Buttons;
    property ButtonsImages;
    property Mode: TACLDateTimeEditMode read FMode write SetMode default dtmDateAndTime;
    property ResourceCollection;
    property Style;
    property StyleButton;
    property StyleCalendar: TACLStyleCalendar read FStyleCalendar write SetStyleCalendar;
    property StylePushButton: TACLStyleButton read FStylePushButton write SetStylePushButton;
    property StyleSpinButton: TACLStyleButton read FStyleSpinButton write SetStyleSpinButton;
    property Value stored IsValueStored;

    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
  end;

  { TACLDateTimeEditDropDownForm }

  TACLDateTimeEditDropDownForm = class(TACLCustomPopupForm)
  strict private const
    ButtonWidth = 75;
  strict private
    FButtonCancel: TACLButton;
    FButtonOk: TACLButton;
    FCalendar: TACLCalendar;
    FOwner: TACLDateTimeEdit;
    FTimeEdit: TACLTimeEdit;

    procedure CreateControl(AControlClass: TACLCustomControlClass; out AControl);
    procedure HandlerApply(Sender: TObject);
    procedure HandlerCancel(Sender: TObject);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  System.SysUtils,
{$IFNDEF DELPHI110ALEXANDRIA}
  System.Character,
{$ENDIF}
  // ACL
  ACL.Geometry;

type
  TACLCustomControlAccess = class(TACLCustomControl);

{$REGION 'Fixed Version of TryStrToDateTime from Delphi 11.0'}
{$IFNDEF DELPHI110ALEXANDRIA}
type
  TDatePart = (dpNone, dpChar, dpSep, dpMonth, dpDay, dpYear, dpYearCurEra, dpEraName, dpQuote);
  TDateItem = record
    FPart: TDatePart;
    FLen: Byte;
    FChar: Char;
  end;
  TDateSeq = array [1 .. 16] of TDateItem;

function GetDateSequence(const DateFormat: string): TDateSeq;
var
  I: Integer;
  PrevChar, Ch: Char;
  CountChar: Integer;
  P: PChar;
  Part: TDatePart;
  InQuote, InDoubleQuote: Boolean;
begin
  // http://docwiki.embarcadero.com/Libraries/en/System.SysUtils.DateTimeToString
  I := Low(TDateSeq);
  InQuote := False;
  InDoubleQuote := False;
  CountChar := 0;
  PrevChar := #0;
  P := PChar(DateFormat);
  while True do
  begin
    Ch := P^;
    if PrevChar <> Ch then
    begin
      case PrevChar of
      'Y', 'y': Part := dpYear;
      'M', 'm': Part := dpMonth;
      'D', 'd': Part := dpDay;
      '/':      Part := dpSep;
      'G', 'g': Part := dpEraName;
      'E', 'e': Part := dpYearCurEra;
      ' ', #0:  Part := dpNone;
      '''':
        begin
          Part := dpQuote;
          if not InDoubleQuote then
            InQuote := not InQuote;
        end;
      '"':
        begin
          Part := dpQuote;
          if not InQuote then
            InDoubleQuote := not InDoubleQuote;
        end;
      else      Part := dpChar;
      end;
      if (Part <> dpQuote) and (InQuote or InDoubleQuote) then
        Part := dpChar;
      if not (Part in [dpNone, dpQuote]) then
      begin
        if I = High(TDateSeq) + 1 then
        begin
          I := Low(TDateSeq);
          Break;
        end;
        if (CountChar = 1) and (Part in [dpYear, dpYearCurEra, dpMonth, dpDay]) then
          CountChar := 2;
        Result[I].FPart := Part;
        Result[I].FLen := CountChar;
        Result[I].FChar := PrevChar;
        Inc(I);
      end;
      if Part <> dpQuote then
        CountChar := 1;
      PrevChar := Ch;
    end
    else
      Inc(CountChar);
    if P^ = #0 then
      Break;
    Inc(P);
  end;
  Result[I].FPart := dpNone;
end;

function ScanBlanks(const S: string; var Pos: Integer): Boolean;
var
  I: Integer;
begin
  I := Pos;
  while (I <= High(S)) and (S[I] = ' ') do Inc(I);
  Result := I > Pos;
  Pos := I;
end;

function ScanNumber(const S: string; var Pos: Integer; var Number: Word; MaxChars: Integer): Integer;
var
  I, E: Integer;
  N: Word;
begin
  Result := 0;
  ScanBlanks(S, Pos);
  I := Pos;
  E := High(S);
  if (MaxChars >= 0) and (E - I + 1 > MaxChars) then
    E := I + MaxChars - 1;
  N := 0;
  while (I <= E) and CharInSet(S[I], ['0'..'9']) and (N < 1000) do
  begin
    N := N * 10 + (Ord(S[I]) - Ord('0'));
    Inc(I);
  end;
  if I > Pos then
  begin
    Result := I - Pos;
    Pos := I;
    Number := N;
  end;
end;

function ScanString(const S: string; var Pos: Integer; const Symbol: string): Boolean;
var
  L: Integer;
begin
  Result := False;
  if Symbol <> '' then
  begin
    ScanBlanks(S, Pos);
    L := Symbol.Length;
    if AnsiStrLIComp(PChar(Symbol), PChar(S) + Pos - Low(string), L) = 0 then
    begin
      Inc(Pos, L);
      Result := True;
    end;
  end;
end;

function ScanChar(const S: string; var Pos: Integer; Ch: Char): Boolean;
var
  C: Char;
begin
  Result := False;
  ScanBlanks(S, Pos);
  if Pos <= High(S) then
  begin
    C := S[Pos];
    if C = Ch then
      Result := True
    else if (C >= 'a') and (C <= 'z') and (Ch >= 'a') and (Ch <= 'z') then
      Result := Char(Word(C) xor $0020) = Char(Word(Ch) xor $0020)
    else
      Result := C.ToUpper = Ch.ToUpper;
    if Result then
      Inc(Pos);
  end;
end;

procedure ScanToNumber(const S: string; var Pos: Integer);
begin
  while (Pos <= High(S)) and not CharInSet(S[Pos], ['0'..'9']) do
  begin
    if IsLeadChar(S[Pos]) then
      Pos := NextCharIndex(S, Pos)
    else
      Inc(Pos);
  end;
end;

function ScanName(const S: string; var Pos: Integer; var Name: string; AnAbbr: Boolean): Boolean;
var
  Start: Integer;
begin
  Start := Pos;
  while (Pos <= High(S)) and (S[Pos].IsLetter or AnAbbr and (S[Pos] = '.')) do
  begin
    if IsLeadChar(S[Pos]) then
      Pos := NextCharIndex(S, Pos)
    else
      Inc(Pos);
  end;
  Name := S.Substring(Start - 1, Pos - Start);
  Result := not Name.IsEmpty;
end;

function ScanDate(const S: string; var Pos: Integer; var Date: TDateTime;
  const AFormatSettings: TFormatSettings): Boolean; overload;
type
  TNamesArray = array[1..12] of string;
  PNamesArray =^TNamesArray;
  TSpecifiedParts = set of (spDay, spDayOfWeek, spMonth, spYear, spEra, spShortYear);
var
  DateSeq: TDateSeq;
  I, J: Integer;
  Y, M, D, DW: Word;
  CenturyBase: Integer;
  Name: string;
  PNames: PNamesArray;
  EraYearOffset: Integer;
  Was: TSpecifiedParts;

  function EraToYear(Year: Integer): Integer;
  begin
{$IFDEF MSWINDOWS}
    if SysLocale.PriLangID = LANG_KOREAN then
    begin
      if Year <= 99 then
        Inc(Year, (CurrentYear + Abs(EraYearOffset + 1)) div 100 * 100);
      if EraYearOffset > 0 then
        EraYearOffset := -EraYearOffset;
    end;
{$ENDIF MSWINDOWS}
    Result := Year + EraYearOffset;
  end;

begin
  DateSeq := GetDateSequence(AFormatSettings.ShortDateFormat);
  EraYearOffset := 0;
  DW := 0;
  Was := [];
  ScanBlanks(S, Pos);
  for I := Low(DateSeq) to High(DateSeq) do
  begin
    if AFormatSettings.DateSeparator <> ' ' then
      ScanBlanks(S, Pos);
    case DateSeq[I].FPart of
    dpNone:
      Break;
    dpEraName:
      begin
        if (I < High(DateSeq)) and (DateSeq[I].FPart <> dpNone) then
        begin
          if not ScanName(S, Pos, Name, True) then
            Exit(False);
        end
        else
        begin
          ScanToNumber(S, Pos);
          Name := S.SubString(0, Pos - Low(string)).Trim;
        end;
        EraYearOffset := AFormatSettings.GetEraYearOffset(Name);
        if EraYearOffset = -MaxInt then
          Exit(False);
        Include(Was, spEra);
      end;
    dpSep:
      if AFormatSettings.DateSeparator = ' ' then
      begin
        if not ScanBlanks(S, Pos) then
          Exit(False);
      end
      else if AFormatSettings.DateSeparator <> #0 then
      begin
        if not ScanChar(S, Pos, AFormatSettings.DateSeparator) then
          Exit(False);
      end;
    dpMonth:
      begin
        if spMonth in Was then
          Exit(False);
        if DateSeq[I].FLen >= 3 then
        begin
          if not ScanName(S, Pos, Name, (AFormatSettings.DateSeparator <> '.') and (DateSeq[I].FLen = 3)) then
            Exit(False);
          if DateSeq[I].FLen = 3 then
            PNames := @AFormatSettings.ShortMonthNames
          else
            PNames := @AFormatSettings.LongMonthNames;
          M := 0;
          for J := 1 to 12 do
            if AnsiSameText(PNames^[J], Name) then
            begin
              M := J;
              Break;
            end;
          if M = 0 then
            Exit(False);
        end
        else
        begin
          if ScanNumber(S, Pos, M, DateSeq[I].FLen) = 0 then
            Exit(False);
        end;
        Include(Was, spMonth);
      end;
    dpDay:
      if DateSeq[I].FLen >= 3 then
      begin
        if spDayOfWeek in Was then
          Exit(False);
        if not ScanName(S, Pos, Name, (AFormatSettings.DateSeparator <> '.') and (DateSeq[I].FLen = 3)) then
          Exit(False);
        if DateSeq[I].FLen = 3 then
          PNames := @AFormatSettings.ShortDayNames
        else
          PNames := @AFormatSettings.LongDayNames;
        DW := 0;
        for J := 1 to 7 do
          if AnsiSameText(PNames^[J], Name) then
          begin
            DW := J;
            Break;
          end;
        if DW = 0 then
          Exit(False);
        Include(Was, spDayOfWeek);
      end
      else
      begin
        if spDay in Was then
          Exit(False);
        if ScanNumber(S, Pos, D, DateSeq[I].FLen) = 0 then
          Exit(False);
        Include(Was, spDay);
      end;
    dpYear,
    dpYearCurEra:
      begin
        if spYear in Was then
          Exit(False);
        // Consider year in the last era, when the mask has 'ee' or 'e', and 'g' is not yet occured
        if DateSeq[I].FPart = dpYearCurEra then
        begin
          if EraYearOffset = 0 then
          begin
            if High(AFormatSettings.EraInfo) >= 0 then
              EraYearOffset := AFormatSettings.EraInfo[High(AFormatSettings.EraInfo)].EraOffset
            else
              Exit(False);
          end;
        end
        else
          EraYearOffset := 0;
        // Try read as maximum digits as it is possible
        if (DateSeq[I].FLen <= 2) and
           ((I = High(DateSeq)) or not (DateSeq[I + 1].FPart in [dpMonth, dpDay, dpYear, dpYearCurEra])) then
          J := 4
        else
          J := DateSeq[I].FLen;
        J := ScanNumber(S, Pos, Y, J);
        if J = 0 then
          Exit(False);
        // Consider year as "short year", when the mask has 'y', 'yy', etc
        if (J <= 2) and (DateSeq[I].FPart = dpYear) then
          Include(Was, spShortYear);
        Include(Was, spYear);
      end;
    dpChar:
      for J := 1 to DateSeq[I].FLen do
        if not ScanChar(S, Pos, DateSeq[I].FChar) then
          Exit(False);
    else
      Exit(False);
    end;
  end;
  if not (spYear in Was) then
    Y := CurrentYear
  else if EraYearOffset > 0 then
    Y := EraToYear(Y)
  else if [spYear, spShortYear] * Was = [spYear, spShortYear] then
  begin
    CenturyBase := CurrentYear - AFormatSettings.TwoDigitYearCenturyWindow;
    Inc(Y, CenturyBase div 100 * 100);
    if (AFormatSettings.TwoDigitYearCenturyWindow > 0) and (Y < CenturyBase) then
      Inc(Y, 100);
  end;
  if not (spDay in Was) then
    D := 1;
  if not (spMonth in Was) then
    Exit(False);
  Result := TryEncodeDate(Y, M, D, Date);
  if Result and (spDayOfWeek in Was) then
  begin
    if DayOfWeek(Date) <> DW then
      Exit(False);
  end;
end;

function ScanTime(const S: string; var Pos: Integer; var Time: TDateTime;
  const AFormatSettings: TFormatSettings): Boolean; overload;
var
  BaseHour: Integer;
  Hour, Min, Sec, MSec: Word;
begin
  Result := False;
  BaseHour := -1;
  if ScanString(S, Pos, AFormatSettings.TimeAMString) or ScanString(S, Pos, 'AM') then
    BaseHour := 0
  else if ScanString(S, Pos, AFormatSettings.TimePMString) or ScanString(S, Pos, 'PM') then
    BaseHour := 12;
  if BaseHour >= 0 then ScanBlanks(S, Pos);
  if ScanNumber(S, Pos, Hour, -1) = 0 then Exit;
  Min := 0;
  Sec := 0;
  MSec := 0;
  if ScanChar(S, Pos, AFormatSettings.TimeSeparator) then
  begin
    if ScanNumber(S, Pos, Min, -1) = 0 then Exit;
    if ScanChar(S, Pos, AFormatSettings.TimeSeparator) then
    begin
      if ScanNumber(S, Pos, Sec, -1) = 0 then Exit;
      if ScanChar(S, Pos, AFormatSettings.DecimalSeparator) then
        if ScanNumber(S, Pos, MSec, -1) = 0 then Exit;
    end;
  end;
  if BaseHour < 0 then
    if ScanString(S, Pos, AFormatSettings.TimeAMString) or ScanString(S, Pos, 'AM') then
      BaseHour := 0
    else
      if ScanString(S, Pos, AFormatSettings.TimePMString) or ScanString(S, Pos, 'PM') then
        BaseHour := 12;
  if BaseHour >= 0 then
  begin
    if (Hour = 0) or (Hour > 12) then Exit;
    if Hour = 12 then Hour := 0;
    Inc(Hour, BaseHour);
  end;
  ScanBlanks(S, Pos);
  Result := TryEncodeTime(Hour, Min, Sec, MSec, Time);
end;

function TryStrToDateTime(const S: string; out Value: TDateTime; const AFormatSettings: TFormatSettings): Boolean;
var
  Pos: Integer;
  NumberPos: Integer;
  BlankPos, OrigBlankPos: Integer;
  LDate, LTime: TDateTime;
  Stop: Boolean;
begin
  Result := True;
  Pos := Low(string);
  LTime := 0;

  // date data scanned; searched for the time data
  if ScanDate(S, Pos, LDate, AFormatSettings) then
  begin
    // search for time data; search for the first number in the time data
    NumberPos := Pos;
    ScanToNumber(S, NumberPos);

    // the first number of the time data was found
    if NumberPos < High(S) then
    begin
      // search between the end of date and the start of time for AM and PM
      // strings; if found, then ScanTime from this position where it is found
      BlankPos := Pos - 1;
      Stop := False;
      while (not Stop) and (BlankPos < NumberPos) do
      begin
        // blank was found; scan for AM/PM strings that may follow the blank
        if (BlankPos > 0) and (BlankPos < NumberPos) then
        begin
          Inc(BlankPos); // start after the blank
          OrigBlankPos := BlankPos; // keep BlankPos because ScanString modifies it
          Stop := ScanString(S, BlankPos, AFormatSettings.TimeAMString) or
                  ScanString(S, BlankPos, 'AM') or
                  ScanString(S, BlankPos, AFormatSettings.TimePMString) or
                  ScanString(S, BlankPos, 'PM');

          // ScanString jumps over the AM/PM string; if found, then it is needed
          // by ScanTime to correctly scan the time
          BlankPos := OrigBlankPos;
        end
        // no more blanks found; end the loop
        else
          Stop := True;

        // search of the next blank if no AM/PM string has been found
        if not Stop then
        begin
          while (S[BlankPos] <> ' ') and (BlankPos <= High(S)) do
            Inc(BlankPos);
          if BlankPos > High(S) then
            BlankPos := 0;
        end;
      end;

      // loop was forcely stopped; check if AM/PM has been found
      if Stop then
        // AM/PM has been found; check if it is before or after the time data
        if BlankPos > 0 then
          if BlankPos < NumberPos then // AM/PM is before the time number
            Pos := BlankPos
          else
            Pos := NumberPos // AM/PM is after the time number
        else
          Pos := NumberPos
      // the blank found is after the the first number in time data
      else
        Pos := NumberPos;

      // get the time data
      Result := ScanTime(S, Pos, LTime, AFormatSettings);

      // time data scanned with no errors
      if Result then
        if LDate >= 0 then
          Value := LDate + LTime
        else
          Value := LDate - LTime;
    end
    // no time data; return only date data
    else
      Value := LDate;
  end
  // could not scan date data; try to scan time data
  else
    Result := TryStrToTime(S, Value, AFormatSettings)
end;

function StrToDateTimeDef(const S: string; const Default: TDateTime; const AFormatSettings: TFormatSettings): TDateTime;
begin
  if not TryStrToDateTime(S, Result, AFormatSettings) then
    Result := Default;
end;
{$ENDIF}
{$ENDREGION}

{ TACLDateTimeEdit }

constructor TACLDateTimeEdit.Create(AOwner: TComponent);
begin
  inherited;
  FStyleCalendar := TACLStyleCalendar.Create(Self);
  FStylePushButton := TACLStyleButton.Create(Self);
  FStyleSpinButton := TACLStyleSpinButton.Create(Self);
end;

destructor TACLDateTimeEdit.Destroy;
begin
  FreeAndNil(FStylePushButton);
  FreeAndNil(FStyleSpinButton);
  FreeAndNil(FStyleCalendar);
  inherited;
end;

procedure TACLDateTimeEdit.Changed;
begin
  inherited;
  CallNotifyEvent(Self, OnSelect);
end;

function TACLDateTimeEdit.GetDropDownFormClass: TACLCustomPopupFormClass;
begin
  Result := TACLDateTimeEditDropDownForm;
end;

function TACLDateTimeEdit.IsValueStored: Boolean;
begin
  Result := Value > 0;
end;

procedure TACLDateTimeEdit.SetMode(AValue: TACLDateTimeEditMode);
begin
  if FMode <> AValue then
  begin
    FMode := AValue;
    Value := Value;
  end;
end;

procedure TACLDateTimeEdit.SetStyleCalendar(const Value: TACLStyleCalendar);
begin
  FStyleCalendar.Assign(Value);
end;

procedure TACLDateTimeEdit.SetStylePushButton(const Value: TACLStyleButton);
begin
  FStylePushButton.Assign(Value);
end;

procedure TACLDateTimeEdit.SetStyleSpinButton(const Value: TACLStyleButton);
begin
  FStyleSpinButton.Assign(Value);
end;

function TACLDateTimeEdit.TextToValue(const AText: string): Variant;
begin
  Result := StrToDateTimeDef(AText, 0, FormatSettings);
  if Mode = dtmDate then
    Result := DateOf(Result);
end;

function TACLDateTimeEdit.ValueToText(const AValue: Variant): string;
var
  AFormatString: string;
begin
  if AValue > 0 then
  begin
    if Mode = dtmDateAndTime then
      AFormatString := FormatSettings.ShortDateFormat + ' ' + FormatSettings.LongTimeFormat
    else
      AFormatString := FormatSettings.ShortDateFormat;

    Result := FormatDateTime(AFormatString, AValue);
  end
  else
    Result := '';
end;

{ TACLDateTimeEditDropDownForm }

constructor TACLDateTimeEditDropDownForm.Create(AOwner: TComponent);
begin
  inherited;
  FOwner := AOwner as TACLDateTimeEdit;

  CreateControl(TACLCalendar, FCalendar);
  FCalendar.Style := FOwner.StyleCalendar;
  FCalendar.Value := FOwner.Value;

  CreateControl(TACLTimeEdit, FTimeEdit);
  FTimeEdit.Time := FOwner.Value;
  FTimeEdit.Style := FOwner.Style;
  FTimeEdit.StyleButton := FOwner.StyleSpinButton;
  FTimeEdit.Visible := FOwner.Mode = dtmDateAndTime;

  CreateControl(TACLButton, FButtonOk);
  FButtonOk.Caption := TACLDialogsStrs.MsgDlgButtons[mbOK];
  FButtonOk.Width := ButtonWidth;
  FButtonOk.Style := FOwner.StylePushButton;
  FButtonOk.OnClick := HandlerApply;

  CreateControl(TACLButton, FButtonCancel);
  FButtonCancel.Caption := TACLDialogsStrs.MsgDlgButtons[mbCancel];
  FButtonCancel.OnClick := HandlerCancel;
  FButtonCancel.Width := ButtonWidth;
  FButtonCancel.Style := FOwner.StylePushButton;

  Constraints.MinWidth := 290;
  Constraints.MinHeight := 320;
  Constraints.MaxHeight := Constraints.MinHeight;
  Constraints.MaxWidth := Constraints.MinWidth;
  SetBounds(0, 0, Constraints.MinWidth, Constraints.MinHeight);
end;

procedure TACLDateTimeEditDropDownForm.Resize;
var
  AHandle: THandle;
  AContentRect: TRect;
  AIndent: Integer;
  R: TRect;
begin
  inherited;
  if FCalendar = nil then Exit;

  AHandle := BeginDeferWindowPos(4);
  try
    AIndent := ScaleFactor.Apply(acIndentBetweenElements);
    AContentRect := acRectInflate(ClientRect, -AIndent);

    // Buttons
    R := AContentRect;
    R.Top := R.Bottom - FButtonCancel.Height;
    DeferWindowPos(AHandle, FButtonCancel.Handle, 0, R.Right - FButtonCancel.Width, R.Top, 0, 0, SWP_NOZORDER or SWP_NOSIZE);
    R.Right := R.Right - FButtonCancel.Width - AIndent;
    DeferWindowPos(AHandle, FButtonOk.Handle, 0, R.Right - FButtonOk.Width, R.Top, 0, 0, SWP_NOZORDER or SWP_NOSIZE);
    AContentRect.Bottom := R.Top - 2 * AIndent;

    // TimeEdit
    if FTimeEdit.Visible then
    begin
      R := acRectSetBottom(AContentRect, AContentRect.Bottom, FTimeEdit.Height);
      R := acRectCenterHorizontally(R, FTimeEdit.Width);
      DeferWindowPos(AHandle, FTimeEdit.Handle, 0, R.Left, R.Top, 0, 0, SWP_NOZORDER or SWP_NOSIZE);
      AContentRect.Bottom := R.Top - AIndent;
    end;

    DeferWindowPos(AHandle, FCalendar.Handle, 0, AContentRect.Left,
      AContentRect.Top, AContentRect.Width, AContentRect.Height, SWP_NOZORDER);
  finally
    EndDeferWindowPos(AHandle);
  end;
end;

procedure TACLDateTimeEditDropDownForm.CreateControl(AControlClass: TACLCustomControlClass; out AControl);
begin
  TObject(AControl) := AControlClass.Create(Self);
  TACLCustomControlAccess(AControl).Parent := Self;
  TACLCustomControlAccess(AControl).ResourceCollection := FOwner.ResourceCollection;
end;

procedure TACLDateTimeEditDropDownForm.HandlerApply(Sender: TObject);
begin
  FOwner.Value := DateOf(FCalendar.Value) + TimeOf(FTimeEdit.Time);
  Close;
end;

procedure TACLDateTimeEditDropDownForm.HandlerCancel(Sender: TObject);
begin
  Close;
end;

procedure TACLDateTimeEditDropDownForm.Paint;
begin
  Canvas.Brush.Color := FCalendar.Style.ColorBackground.AsColor;
  Canvas.Pen.Color := FOwner.Style.ColorBorder.AsColor;
  Canvas.Rectangle(ClientRect);
end;

end.
