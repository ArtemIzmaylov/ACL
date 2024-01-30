{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*              CSV File Format              *}
{*                                           *}
{*           (c) Artem Izmaylov              *}
{*                2021-2024                  *}
{*               www.aimp.ru                 *}
{*                                           *}
{*********************************************}

unit ACL.FileFormats.CSV;

{$I ACL.Config.inc} //FPC:OK

interface

uses
  {System.}Classes,
  {System.}SysUtils,
  {System.}Variants,
  // ACL
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings,
  ACL.Utils.Stream;

type
  TACLCSVDocumentRowProc = reference to procedure (ARowIndex: Integer);
  TACLCSVDocumentValueProc = reference to procedure (
    const AValue: string; AIsString: Boolean; AValueIndex: Integer);

  { TACLCSVDocumentSettings }

  TACLCSVDocumentSettings = record
    Encoding: TEncoding;
    Quote: Char;
    ValueSeparator: Char;

    class function Create(const AValueSeparator: Char;
      AEncoding: TEncoding = nil): TACLCSVDocumentSettings; overload; static;
    class function Create(const AValueSeparator, AQuote: Char;
      AEncoding: TEncoding = nil): TACLCSVDocumentSettings; overload; static;
    class function Default: TACLCSVDocumentSettings; static;
  end;

  { TACLCSVDocument }

  TACLCSVDocument = class
  public
    class procedure Read(const AFileName: string;
      const OnRow: TACLCSVDocumentRowProc; const OnValue: TACLCSVDocumentValueProc); overload;
    class procedure Read(const AFileName: string; const ASettings: TACLCSVDocumentSettings;
      const OnRow: TACLCSVDocumentRowProc; const OnValue: TACLCSVDocumentValueProc); overload;
    class procedure Read(const AStream: TStream;
      const OnRow: TACLCSVDocumentRowProc; const OnValue: TACLCSVDocumentValueProc); overload;
    class procedure Read(const AStream: TStream; const ASettings: TACLCSVDocumentSettings;
      const OnRow: TACLCSVDocumentRowProc; const OnValue: TACLCSVDocumentValueProc); overload;
    class procedure ReadData(const S: string;
      const OnRow: TACLCSVDocumentRowProc; const OnValue: TACLCSVDocumentValueProc); overload;
    class procedure ReadData(const S: string; const ASettings: TACLCSVDocumentSettings;
      const OnRow: TACLCSVDocumentRowProc; const OnValue: TACLCSVDocumentValueProc); overload;
    class procedure ReadData(const C: PChar; ACount: Integer; const ASettings: TACLCSVDocumentSettings;
      const OnRow: TACLCSVDocumentRowProc; const OnValue: TACLCSVDocumentValueProc); overload;
  end;

  { TACLCSVDocumentParser }

  TACLCSVDocumentParser = class
  strict private
    FChars: PChar;
    FCount: Integer;
    FSettings: TACLCSVDocumentSettings;
    FValueContainsQuote: Boolean;
    FValueCursor: PChar;

    procedure GoToNext; inline;
    function LookInNext: Char; inline;
    procedure ProcessQuotedValue;
  protected
    procedure DoRowBegin; virtual;
    procedure DoRowEnd; virtual;
    procedure DoValue(const AValue: string; AIsQuotedValue: Boolean); virtual;
    procedure DoValueBegin; inline;
    procedure DoValueEnd; inline;
  public
    constructor Create(AChars: PChar; ACount: Integer; const ASettings: TACLCSVDocumentSettings);
    procedure Parse;
    //# Properties
    property Chars: PChar read FChars;
    property Count: Integer read FCount;
    property Settings: TACLCSVDocumentSettings read FSettings;
  end;

  { TACLCSVDocumentWriter }

  TACLCSVDocumentWriter = class
  strict private
    FRowJustStarted: Boolean;
    FSettings: TACLCSVDocumentSettings;
    FStream: TStream;
    FStreamOwnership: TStreamOwnership;

    procedure Write(const S: string);
    procedure WriteSeparatorIfNecessary;
  public
    constructor Create(const AFileName: string; const ASettings: TACLCSVDocumentSettings); overload;
    constructor Create(const AStream: TStream; const ASettings: TACLCSVDocumentSettings;
      AStreamOwnership: TStreamOwnership = soReference); overload;
    destructor Destroy; override;
    procedure NewRow;
    procedure PutValue(const AValue: Boolean); overload;
    procedure PutValue(const AValue: Double); overload;
    procedure PutValue(const AValue: Integer); overload;
    procedure PutValue(const AValue: Single); overload;
    procedure PutValue(const AValue: string); overload;
    procedure PutValue(const AValue: Variant); overload;
  end;

implementation

type

  { TACLCSVDocumentWrappedParser }

  TACLCSVDocumentWrappedParser = class(TACLCSVDocumentParser)
  strict private
    FRowIndex: Integer;
    FValueIndex: Integer;

    FOnRow: TACLCSVDocumentRowProc;
    FOnValue: TACLCSVDocumentValueProc;
  protected
    procedure DoRowBegin; override;
    procedure DoValue(const AValue: string; AIsQuotedValue: Boolean); override;
  public
    constructor Create(AChars: PChar; ACount: Integer;
      const ASettings: TACLCSVDocumentSettings;
      const AOnRow: TACLCSVDocumentRowProc;
      const AOnValue: TACLCSVDocumentValueProc);
  end;

{ TACLCSVDocumentSettings }

class function TACLCSVDocumentSettings.Create(
  const AValueSeparator: Char; AEncoding: TEncoding): TACLCSVDocumentSettings;
begin
  Result := Create(AValueSeparator, '"', AEncoding);
end;

class function TACLCSVDocumentSettings.Create(
  const AValueSeparator, AQuote: Char; AEncoding: TEncoding): TACLCSVDocumentSettings;
begin
  if AEncoding = nil then
    AEncoding := TEncoding.UTF8;
  Result.Encoding := AEncoding;
  Result.Quote := AQuote;
  Result.ValueSeparator := AValueSeparator;
end;

class function TACLCSVDocumentSettings.Default: TACLCSVDocumentSettings;
begin
  Result := Create(',');
end;

{ TACLCSVDocumentParser }

constructor TACLCSVDocumentParser.Create(
  AChars: PChar; ACount: Integer; const ASettings: TACLCSVDocumentSettings);
begin
  inherited Create;
  FSettings := ASettings;
  FChars := AChars;
  FCount := ACount;
end;

procedure TACLCSVDocumentParser.Parse;
var
  AChar: Char;
begin
  if FCount = 0 then
    Exit;

  DoRowBegin;
  while FCount > 0 do
  begin
    AChar := FChars^;
    if AChar = Settings.Quote then
      ProcessQuotedValue
    else

    if AChar = Settings.ValueSeparator then
    begin
      DoValueEnd;
      GoToNext;
      while (FCount > 0) and CharInSet(FChars^, [#9, ' ']) and (FChars^ <> Settings.ValueSeparator) do
        GoToNext;
      DoValueBegin;
    end
    else

    if AChar = #10 then
    begin
      DoRowEnd;
      GoToNext;
      DoRowBegin;
    end
    else

    if AChar = #13 then
    begin
      DoRowEnd;
      if LookInNext = #10 then
        GoToNext;
      GoToNext;
      DoRowBegin;
    end
    else
      GoToNext;
  end;
  DoRowEnd;
end;

procedure TACLCSVDocumentParser.DoRowBegin;
begin
  DoValueBegin;
end;

procedure TACLCSVDocumentParser.DoRowEnd;
begin
  DoValueEnd;
end;

procedure TACLCSVDocumentParser.DoValue(const AValue: string; AIsQuotedValue: Boolean);
begin
  // do nothing
end;

procedure TACLCSVDocumentParser.DoValueBegin;
begin
  FValueCursor := FChars;
  FValueContainsQuote := False;
end;

procedure TACLCSVDocumentParser.DoValueEnd;
var
  ACount: Integer;
  AIsQuotedValue: Boolean;
  AValue: string;
begin
  ACount := acStringLength(FValueCursor, FChars);
  if ACount > 0 then
  begin
    AIsQuotedValue := (FValueCursor^ = Settings.Quote) and ((FValueCursor + ACount - 1)^ = Settings.Quote);
    if AIsQuotedValue then
    begin
      Inc(FValueCursor);
      Dec(ACount, 2);
    end
    else
      if (FCount > 0) and (FChars^ = Settings.ValueSeparator) then
      begin
        while (ACount > 0) and CharInSet((FValueCursor + ACount - 1)^, [' ', #9]) do
          Dec(ACount);
      end;

    SetString(AValue, FValueCursor, ACount);
    if FValueContainsQuote then
      AValue := acStringReplace(AValue, Settings.Quote + Settings.Quote, Settings.Quote);
    DoValue(AValue, AIsQuotedValue);
  end
  else
    DoValue('', False);
end;

procedure TACLCSVDocumentParser.GoToNext;
begin
  Inc(FChars);
  Dec(FCount);
end;

function TACLCSVDocumentParser.LookInNext: Char;
begin
  if FCount > 1 then
    Result := (FChars + 1)^
  else
    Result := #0;
end;

procedure TACLCSVDocumentParser.ProcessQuotedValue;
begin
  GoToNext;
  if (FCount > 0) and (FChars^ = Settings.Quote) then
  begin
    FValueContainsQuote := True;
    GoToNext;
    Exit;
  end;

  while FCount > 0 do
  begin
    if FChars^ = Settings.Quote then
    begin
      if LookInNext <> Settings.Quote then
      begin
        GoToNext;
        Break;
      end;
      FValueContainsQuote := True;
      GoToNext;
    end;
    GoToNext;
  end;
end;

{ TACLCSVDocument }

class procedure TACLCSVDocument.Read(const AFileName: string;
  const ASettings: TACLCSVDocumentSettings;
  const OnRow: TACLCSVDocumentRowProc;
  const OnValue: TACLCSVDocumentValueProc);
var
  AStream: TACLFileStream;
begin
  AStream := TACLFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Read(AStream, ASettings, OnRow, OnValue);
  finally
    AStream.Free;
  end;
end;

class procedure TACLCSVDocument.Read(const AFileName: string;
  const OnRow: TACLCSVDocumentRowProc;
  const OnValue: TACLCSVDocumentValueProc);
begin
  Read(AFileName, TACLCSVDocumentSettings.Default, OnRow, OnValue);
end;

class procedure TACLCSVDocument.Read(const AStream: TStream;
  const OnRow: TACLCSVDocumentRowProc;
  const OnValue: TACLCSVDocumentValueProc);
begin
  Read(AStream, TACLCSVDocumentSettings.Default, OnRow, OnValue);
end;

class procedure TACLCSVDocument.Read(const AStream: TStream;
  const ASettings: TACLCSVDocumentSettings;
  const OnRow: TACLCSVDocumentRowProc;
  const OnValue: TACLCSVDocumentValueProc);
begin
  ReadData(_S(acLoadString(AStream, ASettings.Encoding)), ASettings, OnRow, OnValue);
end;

class procedure TACLCSVDocument.ReadData(const S: string;
  const OnRow: TACLCSVDocumentRowProc;
  const OnValue: TACLCSVDocumentValueProc);
begin
  ReadData(S, TACLCSVDocumentSettings.Default, OnRow, OnValue);
end;

class procedure TACLCSVDocument.ReadData(const S: string;
  const ASettings: TACLCSVDocumentSettings;
  const OnRow: TACLCSVDocumentRowProc;
  const OnValue: TACLCSVDocumentValueProc);
begin
  ReadData(PChar(S), Length(S), ASettings, OnRow, OnValue);
end;

class procedure TACLCSVDocument.ReadData(const C: PChar; ACount: Integer;
  const ASettings: TACLCSVDocumentSettings;
  const OnRow: TACLCSVDocumentRowProc;
  const OnValue: TACLCSVDocumentValueProc);
begin
  with TACLCSVDocumentWrappedParser.Create(C, ACount, ASettings, OnRow, OnValue) do
  try
    Parse;
  finally
    Free;
  end;
end;

{ TACLCSVDocumentWrappedParser }

constructor TACLCSVDocumentWrappedParser.Create(AChars: PChar; ACount: Integer;
  const ASettings: TACLCSVDocumentSettings;
  const AOnRow: TACLCSVDocumentRowProc;
  const AOnValue: TACLCSVDocumentValueProc);
begin
  inherited Create(AChars, ACount, ASettings);
  FOnRow := AOnRow;
  FOnValue := AOnValue;
end;

procedure TACLCSVDocumentWrappedParser.DoRowBegin;
begin
  inherited;
  FValueIndex := 0;
  if Assigned(FOnRow) then
    FOnRow(FRowIndex);
  Inc(FRowIndex);
end;

procedure TACLCSVDocumentWrappedParser.DoValue(const AValue: string; AIsQuotedValue: Boolean);
begin
  inherited;
  if Assigned(FOnValue) then
    FOnValue(AValue, AIsQuotedValue, FValueIndex);
  Inc(FValueIndex);
end;

{ TACLCSVDocumentWriter }

constructor TACLCSVDocumentWriter.Create(const AFileName: string; const ASettings: TACLCSVDocumentSettings);
begin
  Create(TACLFileStream.Create(AFileName, fmCreate), ASettings, soOwned);
end;

constructor TACLCSVDocumentWriter.Create(const AStream: TStream;
  const ASettings: TACLCSVDocumentSettings; AStreamOwnership: TStreamOwnership);
begin
  FSettings := ASettings;
  FStream := AStream;
  FStreamOwnership := AStreamOwnership;
  FRowJustStarted := True;
end;

destructor TACLCSVDocumentWriter.Destroy;
begin
  if FStreamOwnership = soOwned then
    FreeAndNil(FStream);
  inherited;
end;

procedure TACLCSVDocumentWriter.NewRow;
begin
  FRowJustStarted := True;
  Write(acCRLF);
end;

procedure TACLCSVDocumentWriter.PutValue(const AValue: Double);
begin
  WriteSeparatorIfNecessary;
  Write(FloatToStr(AValue, InvariantFormatSettings));
end;

procedure TACLCSVDocumentWriter.PutValue(const AValue: Boolean);
begin
  PutValue(Ord(AValue));
end;

procedure TACLCSVDocumentWriter.PutValue(const AValue: Integer);
begin
  WriteSeparatorIfNecessary;
  Write(IntToStr(AValue));
end;

procedure TACLCSVDocumentWriter.PutValue(const AValue: Variant);
begin
  if VarIsFloat(AValue) then
    PutValue(Double(AValue))
  else if VarIsOrdinal(AValue) then
    PutValue(Integer(AValue))
  else
    PutValue(VarToStrDef(AValue, EmptyStr));
end;

procedure TACLCSVDocumentWriter.PutValue(const AValue: string);
begin
  WriteSeparatorIfNecessary;
  Write(FSettings.Quote);
  Write(AValue);
  Write(FSettings.Quote);
end;

procedure TACLCSVDocumentWriter.PutValue(const AValue: Single);
begin
  WriteSeparatorIfNecessary;
  Write(FloatToStr(AValue, InvariantFormatSettings));
end;

procedure TACLCSVDocumentWriter.Write(const S: string);
begin
  FStream.WriteString(_U(S), FSettings.Encoding);
end;

procedure TACLCSVDocumentWriter.WriteSeparatorIfNecessary;
begin
  if FRowJustStarted then
    FRowJustStarted := False
  else
    Write(FSettings.ValueSeparator);
end;

end.
