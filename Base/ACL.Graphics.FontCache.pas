////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Font Cache
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Graphics.FontCache;

{$I ACL.Config.inc}

{$WARN SYMBOL_PLATFORM OFF}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
  LazUTF8,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Generics.Defaults,
  {System.}Generics.Collections,
  {System.}Classes,
  {System.}Math,
  {System.}Types,
  {System.}SysUtils,
  System.UITypes,
  // Vcl
  {Vcl.}Graphics,
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
  strict private type
    HashCode = {$IFDEF FPC}Cardinal{$ELSE}Integer{$ENDIF};
  strict private
    class var FDefault: IEqualityComparer<TACLFontData>;
    class function GetDefault: IEqualityComparer<TACLFontData>; static;
  public
    // IEqualityComparer
    function Equals(const Left, Right: TACLFontData): Boolean; reintroduce;
    function GetHashCode(const Value: TACLFontData): HashCode; reintroduce;
    //# Properties
    class property Default: IEqualityComparer<TACLFontData> read GetDefault;
  end;

  { TACLFontInfo }

  TACLFontInfo = class(TFont)
  public
    procedure AssignTo(AFont: TFont); reintroduce;
  end;

  { TACLFontCache }

  TACLFontRemapProc = reference to procedure (var AName: TFontName; var AHeight: Integer);

  TACLFontCache = class
  strict private type
  {$REGION ' Internal Types '}
    PCallbackData = ^TCallbackData;
    TCallbackData = record
      CheckCanceled: TACLTaskCancelCallback;
    end;
  {$ENDREGION}
  strict private
    class var FFontCache: TACLDictionary<TACLFontData, TACLFontInfo>;
    class var FFonts: TACLStringSet;
    class var FLoaderHandle: TObjHandle;
    class var FLock: TACLCriticalSection;
    class var FRemapFontProc: TACLFontRemapProc;

    class function CreateFont(const AFontData: TACLFontData): TACLFontInfo;
    //# Loader
    class procedure AsyncFontLoader(ACheckCanceled: TACLTaskCancelCallback);
    class function AsyncFontLoaderEnumProc(var ALogFont: TLogFont;
      ATextMetric: PTextMetric; AFontType: Integer; AData: PCallbackData): Integer; stdcall; static;
    class procedure AsyncFontLoaderFinished;
  protected
    class procedure StartLoader;
    class procedure WaitForLoader(ACancel: Boolean = False);
  public
    class constructor Create;
    class destructor Destroy;
    class procedure EnumFonts(AProc: TACLStringEnumProc);
    class function GetInfo(const AName: string; AStyle: TFontStyles;
      AHeight: Integer; ATargetDPI: Integer; AQuality: TFontQuality): TACLFontInfo; overload;
    class function GetInfo(const AFontData: TACLFontData): TACLFontInfo; overload;
    //# Remap
    class procedure RemapFont(var AName: TFontName; var AHeight: Integer);
    class property RemapFontProc: TACLFontRemapProc read FRemapFontProc write FRemapFontProc;
  end;

function acResolveFontHeight(AFont: TFont; AHeight: Integer): Integer;
procedure acSetFontHeight(AFont: TFont; AHeight, ATargetDpi: Integer);
implementation

uses
  ACL.Hashes,
  ACL.Utils.Strings;

{$IFNDEF MSWINDOWS}
  {$DEFINE USE_METRICS_CACHE}
{$ENDIF}

{$REGION ' Metrics Cache '}
type
  TMetrics = record
    Ascent: Integer;
    Descent: Integer;
    Height: Integer;
    InternalLeading: Integer;
    class function Create(AHeight, AAscent, ADescent, AInternalLeading: Integer): TMetrics; static;
  end;

  { TMetricsCache }

  TMetricsCache = class(TACLDictionary<String, TMetrics>)
  strict private
    class var FInstance: TMetricsCache;
  public
    constructor Create;
    class destructor Destroy;
    class function Instance: TMetricsCache;
  end;

procedure DumpMetrics;
var
  S: TStringList;
begin
  S := TStringList.Create;
  try
    TACLFontCache.StartLoader;
    TACLFontCache.EnumFonts(
      procedure (const AName: string)
      var
        LMetrics: TTextMetric;
      begin
        MeasureCanvas.Font.Name := AName;
        MeasureCanvas.Font.Height := 750;
        GetTextMetrics(MeasureCanvas.Handle, LMetrics);
        S.Add(Format('  Add(''%s'', TMetrics.Create(%d, %d, %d, %d));', [AName,
          LMetrics.tmHeight, LMetrics.tmAscent, LMetrics.tmDescent, LMetrics.tmInternalLeading]));
      end);
    S.Sort;
    S.SaveToFile(ParamStr(0) + 'fonts.dump');
  finally
    S.Free;
  end;
end;

{ TMetrics }

class function TMetrics.Create(AHeight, AAscent, ADescent, AInternalLeading: Integer): TMetrics;
begin
  Result.Ascent := AAscent;
  Result.Descent := ADescent;
  Result.Height := AHeight;
  Result.InternalLeading := AInternalLeading;
end;

{ TMetricsCache }

constructor TMetricsCache.Create;
begin
  inherited Create(128);
  Add('Arial Black', TMetrics.Create(750, 585, 165, 218));
  Add('Arial', TMetrics.Create(750, 608, 142, 79));
  Add('Bahnschrift Condensed', TMetrics.Create(750, 621, 129, 125));
  Add('Bahnschrift Light Condensed', TMetrics.Create(750, 621, 129, 125));
  Add('Bahnschrift Light SemiCondensed', TMetrics.Create(750, 621, 129, 125));
  Add('Bahnschrift Light', TMetrics.Create(750, 621, 129, 125));
  Add('Bahnschrift SemiBold Condensed', TMetrics.Create(750, 621, 129, 125));
  Add('Bahnschrift SemiBold SemiConden', TMetrics.Create(750, 621, 129, 125));
  Add('Bahnschrift SemiBold', TMetrics.Create(750, 621, 129, 125));
  Add('Bahnschrift SemiCondensed', TMetrics.Create(750, 621, 129, 125));
  Add('Bahnschrift SemiLight Condensed', TMetrics.Create(750, 621, 129, 125));
  Add('Bahnschrift SemiLight SemiConde', TMetrics.Create(750, 621, 129, 125));
  Add('Bahnschrift SemiLight', TMetrics.Create(750, 621, 129, 125));
  Add('Bahnschrift', TMetrics.Create(750, 621, 129, 125));
  Add('Calibri Light', TMetrics.Create(750, 585, 165, 136));
  Add('Calibri', TMetrics.Create(750, 585, 165, 136));
  Add('Cambria Math', TMetrics.Create(750, 419, 331, 616));
  Add('Cambria', TMetrics.Create(750, 608, 142, 110));
  Add('Candara Light', TMetrics.Create(750, 585, 165, 136));
  Add('Candara', TMetrics.Create(750, 585, 165, 136));
  Add('Comic Sans MS', TMetrics.Create(750, 593, 157, 212));
  Add('Consolas', TMetrics.Create(750, 589, 161, 109));
  Add('Constantia', TMetrics.Create(750, 585, 165, 136));
  Add('Corbel Light', TMetrics.Create(750, 585, 165, 136));
  Add('Corbel', TMetrics.Create(750, 585, 165, 136));
  Add('Courier New', TMetrics.Create(750, 551, 199, 88));
  Add('Ebrima', TMetrics.Create(750, 608, 142, 186));
  Add('Franklin Gothic Medium', TMetrics.Create(750, 606, 144, 89));
  Add('Gabriola', TMetrics.Create(750, 485, 265, 343));
  Add('Gadugi', TMetrics.Create(750, 608, 142, 186));
  Add('Georgia', TMetrics.Create(750, 605, 145, 90));
  Add('HoloLens MDL2 Assets', TMetrics.Create(750, 750, 0, 0));
  Add('Impact', TMetrics.Create(750, 620, 130, 135));
  Add('Ink Free', TMetrics.Create(750, 551, 199, 144));
  Add('Javanese Text', TMetrics.Create(750, 413, 337, 420));
  Add('Leelawadee UI Semilight', TMetrics.Create(750, 608, 142, 186));
  Add('Leelawadee UI', TMetrics.Create(750, 608, 142, 186));
  Add('Lucida Console', TMetrics.Create(750, 592, 158, 0));
  Add('Lucida Sans Unicode', TMetrics.Create(750, 535, 215, 262));
  Add('Malgun Gothic Semilight', TMetrics.Create(750, 614, 136, 186));
  Add('Malgun Gothic', TMetrics.Create(750, 614, 136, 186));
  Add('Marlett', TMetrics.Create(750, 750, 0, 0));
  Add('Microsoft Himalaya', TMetrics.Create(750, 444, 306, 0));
  Add('Microsoft JhengHei Light', TMetrics.Create(750, 607, 143, 186));
  Add('Microsoft JhengHei UI Light', TMetrics.Create(750, 600, 150, 160));
  Add('Microsoft JhengHei UI', TMetrics.Create(750, 600, 150, 160));
  Add('Microsoft JhengHei', TMetrics.Create(750, 607, 143, 186));
  Add('Microsoft New Tai Lue', TMetrics.Create(750, 532, 218, 177));
  Add('Microsoft PhagsPa', TMetrics.Create(750, 612, 138, 164));
  Add('Microsoft Sans Serif', TMetrics.Create(750, 611, 139, 87));
  Add('Microsoft Tai Le', TMetrics.Create(750, 547, 203, 160));
  Add('Microsoft YaHei Light', TMetrics.Create(750, 596, 154, 163));
  Add('Microsoft YaHei UI Light', TMetrics.Create(750, 605, 145, 179));
  Add('Microsoft YaHei UI', TMetrics.Create(750, 600, 150, 160));
  Add('Microsoft YaHei', TMetrics.Create(750, 601, 149, 182));
  Add('Microsoft Yi Baiti', TMetrics.Create(750, 644, 106, 1));
  Add('MingLiU_HKSCS-ExtB', TMetrics.Create(750, 601, 149, 0));
  Add('MingLiU-ExtB', TMetrics.Create(750, 601, 149, 0));
  Add('Modern', TMetrics.Create(750, 586, 164, 94));
  Add('Mongolian Baiti', TMetrics.Create(750, 595, 155, 45));
  Add('MS Gothic', TMetrics.Create(750, 645, 105, 0));
  Add('MS PGothic', TMetrics.Create(750, 645, 105, 0));
  Add('MS UI Gothic', TMetrics.Create(750, 645, 105, 0));
  Add('MV Boli', TMetrics.Create(750, 530, 220, 285));
  Add('Myanmar Text', TMetrics.Create(750, 418, 332, 347));
  Add('Nirmala UI Semilight', TMetrics.Create(750, 608, 142, 186));
  Add('Nirmala UI', TMetrics.Create(750, 608, 142, 186));
  Add('NSimSun', TMetrics.Create(750, 645, 105, 0));
  Add('Palatino Linotype', TMetrics.Create(750, 584, 166, 194));
  Add('PMingLiU-ExtB', TMetrics.Create(750, 601, 149, 0));
  Add('Roman', TMetrics.Create(750, 586, 164, 94));
  Add('Sans Serif Collection', TMetrics.Create(750, 494, 256, 445));
  Add('Script', TMetrics.Create(750, 507, 243, 81));
  Add('Segoe Fluent Icons', TMetrics.Create(750, 750, 0, 0));
  Add('Segoe MDL2 Assets', TMetrics.Create(750, 750, 0, 0));
  Add('Segoe Print', TMetrics.Create(750, 537, 213, 320));
  Add('Segoe Script', TMetrics.Create(750, 516, 234, 276));
  Add('Segoe UI Black', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Emoji', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Historic', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Light', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Semibold', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Semilight', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Symbol', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Variable Display Light', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Variable Display Semib', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Variable Display Semil', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Variable Display', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Variable Small Light', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Variable Small Semibol', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Variable Small Semilig', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Variable Small', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Variable Text Light', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Variable Text Semibold', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Variable Text Semiligh', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI Variable Text', TMetrics.Create(750, 608, 142, 186));
  Add('Segoe UI', TMetrics.Create(750, 608, 142, 186));
  Add('SimSun', TMetrics.Create(750, 645, 105, 0));
  Add('SimSun-ExtB', TMetrics.Create(750, 645, 105, 0));
  Add('Sitka Banner Semibold', TMetrics.Create(750, 595, 155, 231));
  Add('Sitka Banner', TMetrics.Create(750, 595, 155, 231));
  Add('Sitka Display Semibold', TMetrics.Create(750, 595, 155, 231));
  Add('Sitka Display', TMetrics.Create(750, 595, 155, 231));
  Add('Sitka Heading Semibold', TMetrics.Create(750, 595, 155, 231));
  Add('Sitka Heading', TMetrics.Create(750, 595, 155, 231));
  Add('Sitka Small Semibold', TMetrics.Create(750, 595, 155, 231));
  Add('Sitka Small', TMetrics.Create(750, 595, 155, 231));
  Add('Sitka Subheading Semibold', TMetrics.Create(750, 595, 155, 231));
  Add('Sitka Subheading', TMetrics.Create(750, 595, 155, 231));
  Add('Sitka Text Semibold', TMetrics.Create(750, 595, 155, 231));
  Add('Sitka Text', TMetrics.Create(750, 595, 155, 231));
  Add('Sylfaen', TMetrics.Create(750, 573, 177, 181));
  Add('Symbol', TMetrics.Create(750, 615, 135, 138));
  Add('Tahoma', TMetrics.Create(750, 622, 128, 129));
  Add('Times New Roman', TMetrics.Create(750, 604, 146, 73));
  Add('Trebuchet MS', TMetrics.Create(749, 606, 143, 103));
  Add('Verdana', TMetrics.Create(750, 620, 130, 133));
  Add('Webdings', TMetrics.Create(750, 600, 150, 0));
  Add('Wingdings', TMetrics.Create(750, 607, 143, 74));
  Add('Yu Gothic Light', TMetrics.Create(750, 576, 174, 167));
  Add('Yu Gothic Medium', TMetrics.Create(750, 577, 173, 167));
  Add('Yu Gothic UI Light', TMetrics.Create(750, 608, 142, 186));
  Add('Yu Gothic UI Semibold', TMetrics.Create(750, 608, 142, 186));
  Add('Yu Gothic UI Semilight', TMetrics.Create(750, 608, 142, 186));
  Add('Yu Gothic UI', TMetrics.Create(750, 608, 142, 186));
  Add('Yu Gothic', TMetrics.Create(750, 574, 176, 167));
end;

class destructor TMetricsCache.Destroy;
begin
  FreeAndNil(FInstance);
end;

class function TMetricsCache.Instance: TMetricsCache;
begin
  if FInstance = nil then
    FInstance := TMetricsCache.Create;
  Result := FInstance;
end;
{$ENDREGION}

function acResolveFontHeight(AFont: TFont; AHeight: Integer): Integer;
var
  LLogFont: TLogFont;
{$IFDEF USE_METRICS_CACHE}
  LMetrics: TMetrics;
{$ELSE}
  LPrevPPI: Integer;
  LTextMetric: TTextMetric;
{$ENDIF}
begin
  if AHeight = 0 then
  begin
    if GetObject(AFont.Handle, SizeOf(LLogFont), @LLogFont) <> 0 then
      AHeight := -Abs(LLogFont.lfHeight);
  end;
  if AHeight > 0 then
  begin
  {$IFDEF USE_METRICS_CACHE}
    if TMetricsCache.Instance.TryGetValue(AFont.Name, LMetrics) then
      AHeight := -MulDiv(AHeight, LMetrics.Height - LMetrics.InternalLeading, LMetrics.Height)
    else
      AHeight := -MulDiv(AHeight, 72, 96);
  {$ELSE}
    LPrevPPI := MeasureCanvas.Font.PixelsPerInch;
    try
      // AI:
      // https://support.microsoft.com/en-us/help/74299/info-calculating-the-logical-height-and-point-size-of-a-font
      // https://jeffpar.github.io/kbarchive/kb/074/Q74299/
      //
      //                   -(Point Size * LOGPIXELSY)
      //          height = --------------------------
      //                                72
      //
      //          ----------  <------------------------------
      //          |        |           |- Internal Leading  |
      //          | |   |  |  <---------                    |
      //          | |   |  |        |                       |- Cell Height
      //          | |---|  |        |- Character Height     |
      //          | |   |  |        |                       |
      //          | |   |  |        |                       |
      //          ----------  <------------------------------
      //
      //        The following formula computes the point size of a font:
      //
      //                       (Height - Internal Leading) * 72
      //          Point Size = --------------------------------
      //                                  LOGPIXELSY
      //
      MeasureCanvas.Font := AFont;
      MeasureCanvas.Font.PixelsPerInch := acDefaultDpi;
      MeasureCanvas.Font.Height := AHeight;
      GetTextMetrics(MeasureCanvas.Handle, LTextMetric{%H-});
    finally
      MeasureCanvas.Font.PixelsPerInch := LPrevPPI;
    end;
    AHeight := -(LTextMetric.tmHeight - LTextMetric.tmInternalLeading);
  {$ENDIF}
  end;
  Result := AHeight;
end;

procedure acSetFontHeight(AFont: TFont; AHeight, ATargetDpi: Integer);
begin
  if (ATargetDpi > 0) and (ATargetDpi <> acDefaultDpi) then
  begin
    if AHeight >= 0 then
      AHeight := acResolveFontHeight(AFont, AHeight);
    AHeight := MulDiv(AHeight, ATargetDpi, acDefaultDpi)
  end;
  AFont.Height := AHeight;
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

function TACLFontDataComparer.GetHashCode(const Value: TACLFontData): HashCode;
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
  TACLHashBobJenkins.Update(AState, Value.Name);
  Result := TACLHashBobJenkins.Finalize(AState);
end;

class function TACLFontDataComparer.GetDefault: IEqualityComparer<TACLFontData>;
begin
  if FDefault = nil then
    FDefault := TACLFontDataComparer.Create;
  Result := FDefault;
end;

{ TACLFontInfo }

procedure TACLFontInfo.AssignTo(AFont: TFont);
begin
  if Handle <> AFont.Handle then // Why VCL does not check it?
  begin
    AFont.Assign(Self);
  {$IFDEF FPC}
    AFont.Height := Height;
  {$ENDIF}
  end;
end;

{ TACLFontCache }

class constructor TACLFontCache.Create;
begin
  FLock := TACLCriticalSection.Create;
  FFonts := TACLStringSet.Create(False, 512);
  FFontCache := TACLDictionary<TACLFontData, TACLFontInfo>.Create(
    [doOwnsValues], 64, TACLFontDataComparer.Create);
  TACLMainThread.RunPostponed(StartLoader);
end;

class destructor TACLFontCache.Destroy;
begin
  TACLMainThread.Unsubscribe(StartLoader);
  WaitForLoader(True);
  FreeAndNil(FFontCache);
  FreeAndNil(FFonts);
  FreeAndNil(FLock);
end;

class procedure TACLFontCache.EnumFonts(AProc: TACLStringEnumProc);
var
  LName: string;
begin
  WaitForLoader;
  FLock.Enter;
  try
    for LName in FFonts do
      AProc(LName);
  finally
    FLock.Leave;
  end;
end;

//class function TACLFontCache.GetInfo(const AFont: TFont): TACLFontInfo;
//var
//  LFontData: TACLFontData;
//begin
//  FLock.Enter;
//  try
//    LFontData := TACLFontData.Create(AFont);
//    if not FFontCache.TryGetValue(LFontData, Result) then
//    begin
//    {$IFDEF ACL_LOG_FONTCACHE}
//      AddToDebugLog('FontCache', 'GetInfo(%s)', [LFontData.ToString]);
//    {$ENDIF}
//      Result := TACLFontInfo.Create;
//      Result.Assign(AFont);
//      FFontCache.Add(LFontData, Result);
//    end;
//  finally
//    FLock.Leave;
//  end;
//end;

class function TACLFontCache.GetInfo(const AFontData: TACLFontData): TACLFontInfo;
begin
  FLock.Enter;
  try
    if not FFontCache.TryGetValue(AFontData, Result) then
    begin
    {$IFDEF ACL_LOG_FONTCACHE}
      AddToDebugLog('FontCache', 'GetInfo(%s)', [AFontData.ToString]);
    {$ENDIF}
      Result := CreateFont(AFontData);
      FFontCache.Add(AFontData, Result);
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

class procedure TACLFontCache.RemapFont(var AName: TFontName; var AHeight: Integer);
begin
  if Assigned(RemapFontProc) then
    RemapFontProc(AName, AHeight);
end;

class procedure TACLFontCache.AsyncFontLoader(ACheckCanceled: TACLTaskCancelCallback);
var
  AData: TCallbackData;
  ADC: HDC;
  ALogFont: TLogFont;
begin
  ADC := CreateCompatibleDC(0);
  try
    AData.CheckCanceled := ACheckCanceled;
    FillChar(ALogFont{%H-}, SizeOf(ALogFont), #0);
    ALogFont.lfCharset := DEFAULT_CHARSET;
    EnumFontFamiliesEx(ADC, {$IFDEF FPC}@{$ENDIF}ALogFont,
       @AsyncFontLoaderEnumProc, {%H-}LPARAM(@AData), 0);
  finally
    DeleteDC(ADC);
  end;
end;

class function TACLFontCache.AsyncFontLoaderEnumProc(var ALogFont: TLogFont;
  ATextMetric: PTextMetric; AFontType: Integer; AData: PCallbackData): Integer;
begin
  if AFontType <> RASTER_FONTTYPE then
  begin
    if ALogFont.lfFaceName[0] <> '@' then // vertical;
      FFonts.Include(ALogFont.lfFaceName);
  end;
  Result := Ord(not AData.CheckCanceled);
end;

class procedure TACLFontCache.AsyncFontLoaderFinished;
begin
{$IFDEF ACL_LOG_FONTCACHE}
  AddToDebugLog('FontCache', 'Loader Finished');
{$ENDIF}
  FLoaderHandle := TObjHandle(-1);
end;

class function TACLFontCache.CreateFont(const AFontData: TACLFontData): TACLFontInfo;
begin
  Result := TACLFontInfo.Create;
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

class procedure TACLFontCache.StartLoader;
begin
  if FLoaderHandle = 0 then
    FLoaderHandle := TaskDispatcher.Run(AsyncFontLoader, AsyncFontLoaderFinished, tmcmAsync);
end;

class procedure TACLFontCache.WaitForLoader(ACancel: Boolean);
begin
  if (FLoaderHandle = 0) and not ACancel then
    StartLoader;
  if FLoaderHandle <> TObjHandle(-1) then
  begin
    if ACancel then
      TaskDispatcher.Cancel(FLoaderHandle, True)
    else
      TaskDispatcher.WaitFor(FLoaderHandle);
  end;
end;

end.
