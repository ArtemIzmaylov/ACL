﻿////////////////////////////////////////////////////////////////////////////////
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

procedure acAssignFont(ATargetFont, ASourceFont: TFont; ATargetDpi, ASourceDpi: Integer);
procedure acSetFontHeight(AFont: TFont; AHeight, ATargetDpi: Integer);
implementation

uses
  ACL.Hashes,
  ACL.Utils.Strings;

procedure acAssignFont(ATargetFont, ASourceFont: TFont; ATargetDpi, ASourceDpi: Integer);
begin
  ATargetFont.Assign(ASourceFont);
  ATargetFont.Height := dpiApply(dpiRevert(ASourceFont.Height, ASourceDpi), ATargetDpi);
end;

procedure acSetFontHeight(AFont: TFont; AHeight, ATargetDpi: Integer);
var
  APrevPixelsPerInch: Integer;
  ATextMetric: TTextMetric;
begin
  if (ATargetDpi > 0) and (ATargetDpi <> acDefaultDpi) then
  begin
    if AHeight > 0 then
    begin
      APrevPixelsPerInch := MeasureCanvas.Font.PixelsPerInch;
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
        GetTextMetrics(MeasureCanvas.Handle, ATextMetric{%H-});
      finally
        MeasureCanvas.Font.PixelsPerInch := APrevPixelsPerInch;
      end;
      AHeight := -(ATextMetric.tmHeight - ATextMetric.tmInternalLeading);
    end;
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
