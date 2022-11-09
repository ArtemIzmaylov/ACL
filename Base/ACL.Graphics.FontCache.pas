{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*                Font Cache                 *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.FontCache;

{$I ACL.Config.inc}
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  Winapi.Windows,
  // System
  System.UITypes,
  System.Generics.Defaults,
  System.Generics.Collections,
  System.Classes,
  // Vcl
  Vcl.Graphics,
  // ACL
  ACL.Classes.Collections,
  ACL.Graphics,
  ACL.Threading,
  ACL.Threading.Pool,
  ACL.Utils.Common,
{$IFDEF ACL_LOG_FONTCACHE}
  ACL.Utils.Logger,
{$ENDIF}
  ACL.Utils.DPIAware;

type

  { TACLFontData }

  TACLFontData = record
    Charset: TFontCharset;
    Height: Integer;
    Name: TFontName;
    Orientation: Integer;
    Pitch: TFontPitch;
    Quality: TFontQuality;
    Style: TFontStyles;
    TargetDPI: Integer;

    class function Create(AFont: TFont): TACLFontData; static;
    function ToString: string;
  end;

  { TACLFontDataComparer }

  TACLFontDataComparer = class(TInterfacedObject, IEqualityComparer<TACLFontData>)
  strict private
    class var FDefault: IEqualityComparer<TACLFontData>;
    class function GetDefault: IEqualityComparer<TACLFontData>; static;
  public
    // IEqualityComparer
    function Equals(const Left, Right: TACLFontData): Boolean; reintroduce;
    function GetHashCode(const Value: TACLFontData): Integer; reintroduce;
    //
    class property Default: IEqualityComparer<TACLFontData> read GetDefault;
  end;

  { TACLFontGlyphSet   }

  TACLFontGlyphSet = class
  strict private
    FPanose: TPanose;
    FSet: TBits;
  public
    constructor Create(DC: HDC);
    destructor Destroy; override;
    function Contains(const W: Char): Boolean; inline;
    function GetPanoseDistance(const ASet: TACLFontGlyphSet): Integer;
    //
    property Panose: TPanose read FPanose;
  end;

  { TACLFontInfo }

  TACLFontInfo = class
  strict private
    FFont: TFont;
    FGlyphSet: TACLFontGlyphSet;
  public
    constructor Create(AOwnedFont: TFont; AGlyphSet: TACLFontGlyphSet);
    destructor Destroy; override;
    procedure AssignTo(AFont: TFont);
    //
    property GlyphSet: TACLFontGlyphSet read FGlyphSet;
    property Font: TFont read FFont;
  end;

  { TACLFontCache }

  TACLFontRemapProc = reference to procedure (var AName: TFontName; var AHeight: Integer);

  TACLFontCache = class
  strict private type
  {$REGION 'Internal Types'}
    PCallbackData = ^TCallbackData;
    TCallbackData = record
      CheckCanceled: TACLTaskCancelCallback;
      DC: HDC;
      TempFont: TFont;
    end;
  {$ENDREGION}
  strict private
    class var FFontDataToFontInfo: TACLDictionary<TACLFontData, TACLFontInfo>;
    class var FLoaderHandle: THandle;
    class var FLock: TACLCriticalSection;
    class var FNameToGlyphSet: TACLDictionary<TFontName, TACLFontGlyphSet>;
    class var FRemapFontProc: TACLFontRemapProc;

    class procedure AsyncFontLoader(ACheckCanceled: TACLTaskCancelCallback);
    class function AsyncFontLoaderEnumProc(var ALogFont: TLogFontW;
      ATextMetric: PTextMetricW; AFontType: Integer; AData: PCallbackData): Integer; stdcall; static;
    class procedure AsyncFontLoaderFinished;
    class function AsyncPutGlyphSet(const AName: TFontName; AGlyphSet: TACLFontGlyphSet): TACLFontGlyphSet;

    class function CreateFont(const AFontData: TACLFontData): TFont;
    class function CreateFontInfo(const AFontData: TACLFontData): TACLFontInfo;
    class function CreateFontInfoCore(const AFontData: TACLFontData; AOwnedFont: TFont): TACLFontInfo;
    class procedure StartLoader;
    class procedure WaitForLoader(ACancel: Boolean = False);
  public
    class constructor Create;
    class destructor Destroy;
    class procedure EnumFonts(AProc: TACLStringEnumProc);
    class function GetInfo(const AFont: TFont): TACLFontInfo; overload;
    class function GetInfo(const AFontData: TACLFontData): TACLFontInfo; overload;
    class function GetInfo(const AName: string; AStyle: TFontStyles;
      AHeight: Integer; ATargetDPI: Integer; AQuality: TFontQuality): TACLFontInfo; overload;
    class function GetSubstituteFont(DC: HDC; AFontInfo: TACLFontInfo; const ACharacter: Char): TACLFontInfo;
    class procedure RemapFont(var AName: TFontName; var AHeight: Integer);
    //
    class property RemapFontProc: TACLFontRemapProc read FRemapFontProc write FRemapFontProc;
  end;

  { TACLTextViewInfo }

  TACLTextViewInfo = class
  strict private type
  {$REGION 'TSpan'}
    PSpan = ^TSpan;
    TSpan = record
      CharacterWidths: PIntegerArray;
      FontHandle: HFONT;
      GlyphCount: Integer;
      Glyphs: PWord;
      Height: Integer;
      Width: Integer;
      Next: PSpan;
      Prev: PSpan;
    end;
  {$ENDREGION}
  strict private
    class var FCaretPosBuffer: Pointer;
    class var FCaretPosBufferSize: Integer;
    class var FClassLock: TACLCriticalSection;

    class function GetCaretPosBuffer(AItemCount: Integer): Pointer;
  strict private
    FData: PSpan;
    FSize: TSize;

    procedure AppendSpan(ASpan: PSpan);
    procedure CalculateSize;
    function CreateSpan(DC: HDC; AFontInfo: TACLFontInfo; ABuffer: PWideChar; ALength: Integer): PSpan;
    procedure CreateSpans(DC: HDC; AFontInfo: TACLFontInfo; AText: PWideChar; ATextLength: Integer);
    procedure Release(ASpan: PSpan);
  protected
    class constructor Create;
    class destructor Destroy;
  public
    constructor Create(DC: HDC; AFont: TFont; const AText: string); overload;
    constructor Create(DC: HDC; AFont: TFont; const AText: PChar; ALength: Integer); overload;
    constructor Create(DC: HDC; AFont: TACLFontInfo; const AText: PChar; ALength: Integer); overload;
    constructor Create(DC: HDC; AFont: TACLFontInfo; const AText: string); overload;
    destructor Destroy; override;
    procedure AdjustToWidth(AWidth: Integer; out AReducedCharacters, AReducedWidth: Integer);
    procedure Draw(DC: HDC; X, Y: Integer; AMaxLength: Integer = MaxInt); inline;
    procedure DrawCore(DC: HDC; X, Y: Integer; AMaxLength: Integer = MaxInt);
    //
    property Size: TSize read FSize;
  end;

implementation

uses
  Winapi.ActiveX,
  // System
  System.SysUtils,
  System.Math,
  // ACL
  ACL.FastCode,
  ACL.Parsers,
  ACL.Hashes,
  ACL.Utils.Strings;

const
  CLASS_CMultiLanguage: TGUID = '{275C23E2-3747-11D0-9FEA-00AA003F8646}';

type

  { IMLangCodePages }

  IMLangCodePages = interface(IUnknown)
  ['{359F3443-BD4A-11D0-B188-00AA0038C969}']
    function GetCharCodePages(const chSrc: Char; out pdwCodePages: DWORD): HResult; stdcall;
    function GetStrCodePages(const pszSrc: PChar; const cchSrc: ULONG; dwPriorityCodePages: DWORD; out pdwCodePages: DWORD; out pcchCodePages: ULONG): HResult; stdcall;
    function CodePageToCodePages(const uCodePage: SYSUINT; out pdwCodePages: LongWord): HResult; stdcall;
    function CodePagesToCodePage(const dwCodePages: LongWord; const uDefaultCodePage: SYSUINT; out puCodePage: SYSUINT): HResult; stdcall;
  end;

  { IMLangFontLink }

  IMLangFontLink = interface(IMLangCodePages)
  ['{359F3441-BD4A-11D0-B188-00AA0038C969}']
    function GetFontCodePages(const hDC: THandle; const hFont: THandle; out pdwCodePages: LongWord): HResult; stdcall;
    function MapFont(const hDC: THandle; const dwCodePages: LongWord; hSrcFont: THandle; out phDestFont: THandle): HResult; stdcall;
    function ReleaseFont(const hFont: THandle): HResult; stdcall;
    function ResetFontMapping: HResult; stdcall;
  end;

function CreateFontLink: IMLangFontLink;
begin
{$IFDEF CPUX86}
  try
    Set8087CW(Default8087CW or $08);
{$ENDIF CPUX86}
    if not Succeeded(CoCreateInstance(CLASS_CMultiLanguage, nil, CLSCTX_INPROC_SERVER or CLSCTX_LOCAL_SERVER, IMLangFontLink, Result)) then
      Result := nil;
{$IFDEF CPUX86}
  finally
    Reset8087CW;
  end;
{$ENDIF CPUX86}
end;

{ TACLFontData }

class function TACLFontData.Create(AFont: TFont): TACLFontData;
begin
  Result.Charset := AFont.Charset;
  Result.Height := AFont.Height;
  Result.Name := AFont.Name;
  Result.TargetDPI := acDefaultDPI;
  Result.Orientation := AFont.Orientation;
  Result.Pitch := AFont.Pitch;
  Result.Quality := AFont.Quality;
  Result.Style := AFont.Style;
  TACLFontCache.RemapFont(Result.Name, Result.Height);
end;

function TACLFontData.ToString: string;
begin
  Result := Format('%s %dpt %ddpi %d <%d> P%d (style: %d)',
    [Name, Height, TargetDpi, Ord(Charset), Orientation, Ord(Pitch), acFontStyleDecode(Style)]);
end;

{ TACLFontDataComparer }

function TACLFontDataComparer.Equals(const Left, Right: TACLFontData): Boolean;
begin
  Result :=
    (Left.Charset = Right.Charset) and
    (Left.Height = Right.Height) and
    (Left.Orientation = Right.Orientation) and
    (Left.Pitch = Right.Pitch) and
    (Left.Quality = Right.Quality) and
    (Left.Style = Right.Style) and
    (Left.TargetDPI = Right.TargetDPI) and
    AnsiSameText(Left.Name, Right.Name);
end;

function TACLFontDataComparer.GetHashCode(const Value: TACLFontData): Integer;
var
  AState: Pointer;
begin
  TACLHashBobJenkins.Initialize(AState);
  TACLHashBobJenkins.Update(AState, @Value.Charset, SizeOf(Value.Charset));
  TACLHashBobJenkins.Update(AState, @Value.Height, SizeOf(Value.Height));
  TACLHashBobJenkins.Update(AState, @Value.Orientation, SizeOf(Value.Orientation));
  TACLHashBobJenkins.Update(AState, @Value.Pitch, SizeOf(Value.Pitch));
  TACLHashBobJenkins.Update(AState, @Value.Quality, SizeOf(Value.Quality));
  TACLHashBobJenkins.Update(AState, @Value.Style, SizeOf(Value.Style));
  TACLHashBobJenkins.Update(AState, @Value.TargetDPI, SizeOf(Value.TargetDPI));
  TACLHashBobJenkins.Update(AState, Value.Name, TEncoding.UTF8);
  Result := TACLHashBobJenkins.Finalize(AState);
end;

class function TACLFontDataComparer.GetDefault: IEqualityComparer<TACLFontData>;
begin
  if FDefault = nil then
    FDefault := TACLFontDataComparer.Create;
  Result := FDefault;
end;

{ TACLFontGlyphSet }

constructor TACLFontGlyphSet.Create(DC: HDC);
var
  AGlyphSet: PGlyphSet;
  AOutlineTextMetrics: TOutlineTextmetric;
  ARange: TWCRange;
  ASize: Integer;
  I, J: Integer;
begin
  FSet := TBits.Create;
  FSet.Size := MaxWord;

  if GetOutlineTextMetricsW(DC, SizeOf(AOutlineTextMetrics), @AOutlineTextMetrics) <> 0 then
    FPanose := AOutlineTextMetrics.otmPanoseNumber;

  ASize := Winapi.Windows.GetFontUnicodeRanges(DC, nil);
  if ASize = 0 then //# "Roboto Bk"
    Exit;

  GetMem(AGlyphSet, ASize);
  try
    GetFontUnicodeRanges(DC, AGlyphSet);
    for I := 0 to 255 do
      FSet[I] := True;
    for I := 61440 to 61695 do
      FSet[I] := True;
    for I := 0 to AGlyphSet.cRanges - 1 do
    begin
      ARange := AGlyphSet.ranges[I];
      for J := Ord(ARange.wcLow) to Ord(ARange.wcLow) + ARange.cGlyphs - 1 do
        FSet[J] := True;
    end;
  finally
    FreeMem(AGlyphSet);
  end;
end;

destructor TACLFontGlyphSet.Destroy;
begin
  FreeAndNil(FSet);
  inherited;
end;

function TACLFontGlyphSet.Contains(const W: Char): Boolean;
begin
  Result := FSet[Ord(W)];
end;

function TACLFontGlyphSet.GetPanoseDistance(const ASet: TACLFontGlyphSet): Integer;
var
  I: Integer;
  P1, P2: PByte;
begin
  Result := 0;
  P1 := @FPanose;
  P2 := @ASet.FPanose;
  for I := 1 to SizeOf(FPanose) do
  begin
    Inc(Result, Sqr(P1^ - P2^));
    Inc(P1);
    Inc(P2);
  end;
end;

{ TACLFontInfo }

constructor TACLFontInfo.Create(AOwnedFont: TFont; AGlyphSet: TACLFontGlyphSet);
begin
  FFont := AOwnedFont;
  FGlyphSet := AGlyphSet;
end;

destructor TACLFontInfo.Destroy;
begin
  FreeAndNil(FFont);
  inherited;
end;

procedure TACLFontInfo.AssignTo(AFont: TFont);
begin
  if Font.Handle <> AFont.Handle then // Why VCL does not check it?
    AFont.Assign(Font);
end;

{ TACLFontCache }

class constructor TACLFontCache.Create;
begin
  FLock := TACLCriticalSection.Create;
  FNameToGlyphSet := TACLDictionary<TFontName, TACLFontGlyphSet>.Create([doOwnsValues], 512, nil);
  FFontDataToFontInfo := TACLDictionary<TACLFontData, TACLFontInfo>.Create([doOwnsValues], 64, TACLFontDataComparer.Create);
  TACLMainThread.RunPostponed(StartLoader);
end;

class destructor TACLFontCache.Destroy;
begin
  TACLMainThread.Unsubscribe(StartLoader);
  WaitForLoader(True);
  FreeAndNil(FFontDataToFontInfo);
  FreeAndNil(FNameToGlyphSet);
  FreeAndNil(FLock);
end;

class procedure TACLFontCache.EnumFonts(AProc: TACLStringEnumProc);
begin
  WaitForLoader;
  FLock.Enter;
  try
    for var Key in FNameToGlyphSet.GetKeys do
      AProc(Key);
  finally
    FLock.Leave;
  end;
end;

class function TACLFontCache.GetInfo(const AFont: TFont): TACLFontInfo;
var
  AFontData: TACLFontData;
begin
  FLock.Enter;
  try
    AFontData := TACLFontData.Create(AFont);
    if not FFontDataToFontInfo.TryGetValue(AFontData, Result) then
    begin
    {$IFDEF ACL_LOG_FONTCACHE}
      AddToDebugLog('FontCache', 'GetInfo(%s)', [AFontData.ToString]);
    {$ENDIF}
      Result := CreateFontInfoCore(AFontData, AFont.Clone);
    end;
  finally
    FLock.Leave;
  end;
end;

class function TACLFontCache.GetInfo(const AFontData: TACLFontData): TACLFontInfo;
begin
  FLock.Enter;
  try
    if not FFontDataToFontInfo.TryGetValue(AFontData, Result) then
    begin
    {$IFDEF ACL_LOG_FONTCACHE}
      AddToDebugLog('FontCache', 'GetInfo(%s)', [AFontData.ToString]);
    {$ENDIF}
      Result := CreateFontInfo(AFontData);
    end;
  finally
    FLock.Leave;
  end;
end;

class function TACLFontCache.GetInfo(const AName: string; AStyle: TFontStyles;
  AHeight: Integer; ATargetDPI: Integer; AQuality: TFontQuality): TACLFontInfo;
var
  AData: TACLFontData;
begin
  AData.Charset := DefFontData.Charset;
  AData.Height := AHeight;
  AData.Name := AName;
  AData.Orientation := 0;
  AData.Pitch := fpDefault;
  AData.Quality := AQuality;
  AData.Style := AStyle;
  AData.TargetDPI := ATargetDPI;
  RemapFont(AData.Name, AData.Height);
  Result := GetInfo(AData);
end;

class function TACLFontCache.GetSubstituteFont(DC: HDC; AFontInfo: TACLFontInfo; const ACharacter: Char): TACLFontInfo;
var
  ADistance: Integer;
  AFontData: TACLFontData;
  AMinDistance: Integer;
  ASuggestedFontName: TFontName;
begin
  WaitForLoader;

  FLock.Enter;
  try
    AMinDistance := MaxInt;
    FNameToGlyphSet.Enum(
      procedure (const Key: TFontName; const Value: TACLFontGlyphSet)
      begin
        if Value.Contains(ACharacter) then
        begin
          ADistance := AFontInfo.GlyphSet.GetPanoseDistance(Value);
          if ADistance < AMinDistance then
          begin
            AMinDistance := ADistance;
            ASuggestedFontName := Key;
          end;
        end;
      end);
  finally
    FLock.Leave;
  end;

  if ASuggestedFontName <> '' then
  begin
  {$IFDEF ACL_LOG_FONTCACHE}
    AddToDebugLog('FontCache', 'GetSubstituteFont(%s -> %s)', [AFontInfo.Font.Name, ASuggestedFontName]);
  {$ENDIF}
    AFontData := TACLFontData.Create(AFontInfo.Font);
    AFontData.Name := ASuggestedFontName;
    Result := GetInfo(AFontData);
  end
  else
    Result := nil;
end;

class procedure TACLFontCache.RemapFont(var AName: TFontName; var AHeight: Integer);
begin
  if Assigned(RemapFontProc) then
    RemapFontProc(AName, AHeight);
end;

class procedure TACLFontCache.AsyncFontLoader(ACheckCanceled: TACLTaskCancelCallback);
var
  AData: TCallbackData;
  ADC: HDC;
  ALogFont: TLogFontW;
begin
  ADC := CreateCompatibleDC(0);
  try
    AData.DC := ADC;
    AData.CheckCanceled := ACheckCanceled;
    AData.TempFont := TFont.Create;
    try
      ZeroMemory(@ALogFont, SizeOf(ALogFont));
      ALogFont.lfCharset := DEFAULT_CHARSET;
      EnumFontFamiliesEx(ADC, ALogFont, @AsyncFontLoaderEnumProc, NativeInt(@AData), 0);
    finally
      AData.TempFont.Free;
    end;
  finally
    DeleteDC(ADC);
  end;
end;

class function TACLFontCache.AsyncFontLoaderEnumProc(var ALogFont: TLogFontW;
  ATextMetric: PTextMetricW; AFontType: Integer; AData: PCallbackData): Integer;
var
  AFontName: string;
begin
  if AFontType <> RASTER_FONTTYPE then
  begin
    if ALogFont.lfFaceName[0] <> '@' then
    begin
      AFontName := ALogFont.lfFaceName;
      if not FNameToGlyphSet.ContainsKey(AFontName) then
      begin
        AData.TempFont.Name := AFontName;
        AData.TempFont.Charset := ALogFont.lfCharSet;
        SelectObject(AData.DC, AData.TempFont.Handle);
        AsyncPutGlyphSet(AFontName, TACLFontGlyphSet.Create(AData.DC));
      end;
    end;
  end;

  Result := Ord(not AData.CheckCanceled);
end;

class procedure TACLFontCache.AsyncFontLoaderFinished;
begin
{$IFDEF ACL_LOG_FONTCACHE}
  AddToDebugLog('FontCache', 'Loader Finished');
{$ENDIF}
  FLoaderHandle := 0;
end;

class function TACLFontCache.AsyncPutGlyphSet(const AName: TFontName; AGlyphSet: TACLFontGlyphSet): TACLFontGlyphSet;
begin
  FLock.Enter;
  try
    if FNameToGlyphSet.AddIfAbsent(AName, AGlyphSet) then
      Result := AGlyphSet
    else
    begin
      AGlyphSet.Free;
      Result := FNameToGlyphSet.Items[AName];
    end;
  finally
    FLock.Leave;
  end;
end;

class function TACLFontCache.CreateFont(const AFontData: TACLFontData): TFont;
begin
  Result := TFont.Create;
  Result.Name := AFontData.Name;
  Result.Orientation := AFontData.Orientation;
  Result.Pitch := AFontData.Pitch;
  Result.Quality := AFontData.Quality;
  Result.Style := AFontData.Style;

  if AFontData.CharSet <> DEFAULT_CHARSET then
    Result.Charset := AFontData.Charset
  else
    Result.Charset := DefFontData.Charset;

  acSetFontHeight(Result, AFontData.Height, AFontData.TargetDPI);
end;

class function TACLFontCache.CreateFontInfo(const AFontData: TACLFontData): TACLFontInfo;
begin
  Result := CreateFontInfoCore(AFontData, CreateFont(AFontData));
end;

class function TACLFontCache.CreateFontInfoCore(const AFontData: TACLFontData; AOwnedFont: TFont): TACLFontInfo;
var
  AGlyphSet: TACLFontGlyphSet;
  AMeasureDC: HDC;
  APrevFontHandle: HFONT;
begin
  if not FNameToGlyphSet.TryGetValue(AFontData.Name, AGlyphSet) then
  begin
    AMeasureDC := MeasureCanvas.Handle;
    APrevFontHandle := SelectObject(AMeasureDC, AOwnedFont.Handle);
  {$IFDEF ACL_LOG_FONTCACHE}
    AddToDebugLog('FontCache', 'ForceCreateGlyphSet(%s)', [AFontData.ToString]);
  {$ENDIF}
    AGlyphSet := AsyncPutGlyphSet(AFontData.Name, TACLFontGlyphSet.Create(AMeasureDC));
    SelectObject(AMeasureDC, APrevFontHandle);
  end;
  Result := TACLFontInfo.Create(AOwnedFont, AGlyphSet);
  FFontDataToFontInfo.Add(AFontData, Result);
end;

class procedure TACLFontCache.StartLoader;
begin
  if FLoaderHandle = 0 then
    FLoaderHandle := TaskDispatcher.Run(AsyncFontLoader, AsyncFontLoaderFinished, tmcmAsync);
end;

class procedure TACLFontCache.WaitForLoader(ACancel: Boolean);
begin
  if FLoaderHandle <> 0 then
  begin
    if ACancel then
      TaskDispatcher.Cancel(FLoaderHandle, True)
    else
      TaskDispatcher.WaitFor(FLoaderHandle);
  end;
end;

{ TACLTextViewInfo }

constructor TACLTextViewInfo.Create(DC: HDC; AFont: TFont; const AText: string);
begin
  Create(DC, AFont, PChar(AText), Length(AText));
end;

constructor TACLTextViewInfo.Create(DC: HDC; AFont: TFont; const AText: PChar; ALength: Integer);
begin
  Create(DC, TACLFontCache.GetInfo(AFont), AText, ALength);
end;

constructor TACLTextViewInfo.Create(DC: HDC; AFont: TACLFontInfo; const AText: string);
begin
  Create(DC, AFont, PChar(AText), Length(AText));
end;

constructor TACLTextViewInfo.Create(DC: HDC; AFont: TACLFontInfo; const AText: PChar; ALength: Integer);
begin
  CreateSpans(DC, AFont, AText, ALength);
  CalculateSize;
end;

destructor TACLTextViewInfo.Destroy;
var
  ASpan: PSpan;
begin
  while FData <> nil do
  begin
    ASpan := FData;
    FData := ASpan.Next;
    Release(ASpan);
  end;
  inherited;
end;

class constructor TACLTextViewInfo.Create;
begin
  FClassLock := TACLCriticalSection.Create;
end;

class destructor TACLTextViewInfo.Destroy;
begin
  FreeAndNil(FClassLock);
  FreeMem(FCaretPosBuffer);
end;

procedure TACLTextViewInfo.AdjustToWidth(AWidth: Integer; out AReducedCharacters, AReducedWidth: Integer);

  procedure AdjustSpanToWidth(ASpan: PSpan; var ACurrentWidth, AReducedCharacters, AReducedWidth: Integer);
  var
    ACount: Integer;
    AScan: PInteger;
  begin
    ACount := ASpan^.GlyphCount;
    AScan := @ASpan^.CharacterWidths^[ACount - 1];
    while (ACount > 0) and (ACurrentWidth > AWidth) do
    begin
      Dec(ACurrentWidth, AScan^);
      Inc(AReducedWidth, AScan^);
      Inc(AReducedCharacters);
      Dec(ACount);
      Dec(AScan);
    end;
  end;

var
  ACurrentWidth: Integer;
  ASpan: PSpan;
begin
  AReducedCharacters := 0;
  AReducedWidth := 0;
  if FData = nil then
    Exit;

  ASpan := FData;
  while ASpan.Next <> nil do
    ASpan := ASpan.Next;

  ACurrentWidth := Size.cx;
  while (ASpan <> nil) and (ACurrentWidth > AWidth) do
  begin
    AdjustSpanToWidth(ASpan, ACurrentWidth, AReducedCharacters, AReducedWidth);
    ASpan := ASpan.Prev;
  end;
end;

procedure TACLTextViewInfo.Draw(DC: HDC; X, Y: Integer; AMaxLength: Integer = MaxInt);
var
  APrevFont: HFONT;
begin
  APrevFont := GetCurrentObject(DC, OBJ_FONT);
  DrawCore(DC, X, Y, AMaxLength);
  SelectObject(DC, APrevFont)
end;

procedure TACLTextViewInfo.DrawCore(DC: HDC; X, Y: Integer; AMaxLength: Integer);
var
  ASpan: PSpan;
begin
  ASpan := FData;
  while (ASpan <> nil) and (AMaxLength > 0) do
  begin
    SelectObject(DC, ASpan^.FontHandle);
    ExtTextOut(DC, X, Y, ETO_GLYPH_INDEX or ETO_IGNORELANGUAGE, nil,
      @ASpan^.Glyphs^, Min(ASpan^.GlyphCount, AMaxLength), @ASpan^.CharacterWidths[0]);
    Dec(AMaxLength, ASpan^.GlyphCount);
    Inc(X, ASpan^.Width);
    ASpan := ASpan.Next;
  end;
end;

procedure TACLTextViewInfo.AppendSpan(ASpan: PSpan);
var
  ASpanScan: PSpan;
begin
  if FData = nil then
    FData := ASpan
  else
  begin
    ASpanScan := FData;
    while ASpanScan.Next <> nil do
      ASpanScan := ASpanScan.Next;
    ASpan.Next := nil;
    ASpan.Prev := ASpanScan;
    ASpanScan.Next := ASpan;
  end;
end;

procedure TACLTextViewInfo.CalculateSize;
var
  AScan: PSpan;
begin
  FSize := NullSize;
  AScan := FData;
  while AScan <> nil do
  begin
    FSize.cy := Max(FSize.cy, AScan^.Height);
    Inc(FSize.cx, AScan^.Width);
    AScan := AScan.Next;
  end;
end;

function TACLTextViewInfo.CreateSpan(DC: HDC; AFontInfo: TACLFontInfo; ABuffer: PWideChar; ALength: Integer): PSpan;

  function GetCharacterPlacementSlow(DC: HDC; ABuffer: PWideChar; ALength: Integer;
    var AGcpResults: TGCPResultsW; AGcpFlags: Cardinal): Integer;
  var
    I, AAdd, AStep, AExtraLength: Integer;
  begin
    AStep := (ALength + 1) div 2; //# 50% of text length
    AAdd := AStep;
    for I := 0 to 2 do
    begin
      AExtraLength := ALength + AAdd;
      AGcpResults.nGlyphs := AExtraLength;
      ReallocMem(AGcpResults.lpDx, SizeOf(Integer) * AExtraLength);
      ReallocMem(AGcpResults.lpGlyphs, SizeOf(Word) * AExtraLength);
      if ALength > 0 then
        PWord(AGcpResults.lpGlyphs)^ := 0; // unlim number of characters that will be ligated together.
      Result := GetCharacterPlacement(DC, ABuffer, ALength, 0, AGcpResults, AGcpFlags);
      if Result <> 0 then
        Exit;
      Inc(AAdd, AStep);
    end;
  end;

var
  ACaretBasedWidth: Integer;
  AGcpFlags: Cardinal;
  AGcpResults: TGCPResultsW;
  AHeight: Integer;
  ALangInfo: Cardinal;
  AOldFont: HFONT;
  ASize: Cardinal;
  AWidth: Integer;
begin
  AOldFont := SelectObject(DC, AFontInfo.Font.Handle);
  FClassLock.Enter;
  try
    ZeroMemory(@AGcpResults, SizeOf(TGCPResults));
    AGcpResults.lStructSize := SizeOf(TGCPResults);
    AGcpResults.lpCaretPos := GetCaretPosBuffer(ALength);
    AGcpResults.nGlyphs := ALength;

    AGcpFlags := 0;
    ALangInfo := 0;
    if not IsWine then
      ALangInfo := GetFontLanguageInfo(DC);
    if ALangInfo and GCP_USEKERNING <> 0 then
      AGcpFlags := AGcpFlags or GCP_USEKERNING;
    if ALangInfo and GCP_DIACRITIC <> 0 then
      AGcpFlags := AGcpFlags or GCP_LIGATE;

    GetMem(AGcpResults.lpDx, SizeOf(Integer) * ALength);
    GetMem(AGcpResults.lpGlyphs, SizeOf(Word) * ALength);
    if ALength > 0 then
      PWord(AGcpResults.lpGlyphs)^ := 0; // unlim number of characters that will be ligated together.

    ASize := GetCharacterPlacement(DC, ABuffer, ALength, 0, AGcpResults, AGcpFlags);
    if (ASize = 0) and (ALength > 0) then
      ASize := GetCharacterPlacementSlow(DC, ABuffer, ALength, AGcpResults, AGcpFlags);
    AWidth := LongRec(ASize).Lo;
    AHeight := LongRec(ASize).Hi;
    if ALength > 0 then
    begin
      ACaretBasedWidth := PIntegerArray(AGcpResults.lpCaretPos)[ALength - 1];
      if ACaretBasedWidth > $FFFF then
        AWidth := ACaretBasedWidth + PIntegerArray(AGcpResults.lpDx)[ALength - 1];
    end;

    New(Result);
    Result^.FontHandle := AFontInfo.Font.Handle;
    Result^.CharacterWidths := Pointer(AGcpResults.lpDx);
    Result^.GlyphCount := AGcpResults.nGlyphs;
    Result^.Glyphs := Pointer(AGcpResults.lpGlyphs);
    Result^.Height := AHeight;
    Result^.Width := AWidth;
    Result^.Next := nil;
    Result^.Prev := nil;
  finally
    FClassLock.Leave;
    SelectObject(DC, AOldFont);
  end;
end;

procedure TACLTextViewInfo.CreateSpans(DC: HDC; AFontInfo: TACLFontInfo; AText: PWideChar; ATextLength: Integer);

  procedure ProcessSpan(var ATextScan: PWideChar; var ATextLength: Integer; AFontInfo, ADefaultFontInfo: TACLFontInfo);
  var
    ACursor: PWideChar;
    AOffset: Integer;
  begin
    AOffset := 0;
    ACursor := AText;
    while (AOffset < ATextLength) and
      ((AFontInfo = nil) or AFontInfo.GlyphSet.Contains(ACursor^)) and
      ((AFontInfo = ADefaultFontInfo) or not ADefaultFontInfo.GlyphSet.Contains(ACursor^)) do
    begin
      Inc(ACursor);
      Inc(AOffset);
    end;
    if AOffset > 0 then
    begin
      if AFontInfo = nil then
        AFontInfo := ADefaultFontInfo;
      AppendSpan(CreateSpan(DC, AFontInfo, AText, AOffset));
      Dec(ATextLength, AOffset);
      Inc(AText, AOffset);
    end;
  end;

begin
  repeat
    ProcessSpan(AText, ATextLength, AFontInfo, AFontInfo);
    if ATextLength > 0 then
      ProcessSpan(AText, ATextLength, TACLFontCache.GetSubstituteFont(DC, AFontInfo, AText^), AFontInfo);
  until ATextLength = 0;
end;

procedure TACLTextViewInfo.Release(ASpan: PSpan);
begin
  FreeMem(ASpan^.CharacterWidths);
  FreeMem(ASpan^.Glyphs);
  Dispose(ASpan);
end;

class function TACLTextViewInfo.GetCaretPosBuffer(AItemCount: Integer): Pointer;
var
  ASize: Integer;
begin
  ASize := SizeOf(Integer) * AItemCount;
  if ASize > FCaretPosBufferSize then
  begin
    ReallocMem(FCaretPosBuffer, ASize);
    FCaretPosBufferSize := ASize;
  end;
  Result := FCaretPosBuffer;
end;

end.
