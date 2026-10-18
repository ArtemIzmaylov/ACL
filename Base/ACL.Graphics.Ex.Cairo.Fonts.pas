////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Cairo Fonts Cache
//
//  Author:    Artem Izmaylov
//             © 2024-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Graphics.Ex.Cairo.Fonts;

{$I ACL.Config.inc}

interface

uses
  Cairo,
{$IFDEF MSWINDOWS}
  CairoWin32,
  Windows,
{$ENDIF}
{$IF DEFINED(LCLGtk3)}
  Gtk3Int,
  LazGdk3,
  LazHarfBuzz0,
{$ELSEIF DEFINED(LCLGtk2)}
  Gtk2Proc,
{$ENDIF}
{$IFDEF LINUX}
  CairoFT,
  BaseUnix,
  FreeTypeH,
  LibFontConfig,
{$ENDIF}
{$IFDEF FPC}
  LazUtf8,
  LCLIntf,
  LCLType,
{$ENDIF}
  // Rtl
  Classes,
  Generics.Defaults,
  Generics.Collections,
  Math,
  System.UITypes,
  StrUtils,
  SysUtils,
  // VCL
  Graphics,
  // ACL
  ACL.Classes.Collections,
  ACL.Hashes,
  ACL.Graphics.Fonts,
  ACL.Threading,
  ACL.Utils.Strings;

const
  GLYPH_MASK_FONTINDEX  = $FF000000;
  GLYPH_MASK_GLYPHINDEX = $00FFFFFF;

type

  { TCairoTextMapping }

  TCairoTextMapping = record
  public
    TextOffsets: array of Integer;
    TextReference: PAnsiChar;
    procedure Free;
    procedure Init(AText: PAnsiChar; AGlyphCount: Integer); overload;
    procedure Init(AText: PAnsiChar; AGlyphCount: Integer;
      // кластеры будут прибиты автоматически
      AClusters: Pcairo_text_cluster_t; AClusterCount: Integer); overload;
    function TextAt(AGlyphIndex: Integer): PAnsiChar;
  end;

  { TCairoFontFaceDescriptor }

  TCairoFontFaceDescriptor = record
    Embolden: Boolean;
    FaceIndex: Integer;
    Name: AnsiString;
    Path: AnsiString;
    Styles: TFontStyles;
    Weight: Integer;
    Width: Integer;
    class function Create(AFont: TFont): TCairoFontFaceDescriptor; static;
    class operator Equal(const Left, Right: TCairoFontFaceDescriptor): Boolean;
  end;

  { TCairoFontFaceDescriptorComparer }

  TCairoFontFaceDescriptorComparer = class(TInterfacedObject, IEqualityComparer<TCairoFontFaceDescriptor>)
  strict private type
    HashCode = {$IFDEF FPC}Cardinal{$ELSE}Integer{$ENDIF};
  strict private
    class var FDefault: IEqualityComparer<TCairoFontFaceDescriptor>;
    class function GetDefault: IEqualityComparer<TCairoFontFaceDescriptor>; static;
  public
    // IEqualityComparer
    function Equals(const Left, Right: TCairoFontFaceDescriptor): Boolean; reintroduce;
    function GetHashCode(const Value: TCairoFontFaceDescriptor): HashCode; reintroduce;
    //# Properties
    class property Default: IEqualityComparer<TCairoFontFaceDescriptor> read GetDefault;
  end;

  { TCairoFontFace }

  TCairoFontFace = class
  strict private
    FDescriptor: TCairoFontFaceDescriptor;
  {$IFDEF LINUX}
    FFtFace: PFT_Face;
    FHandle: Pcairo_scaled_font_t;
    FPixelSize: Single;
    class procedure FreeFtFace(AFace: PFT_Face); cdecl; static;
  {$ENDIF}
  protected
    procedure Select(ACairo: Pcairo_t);
  public
    constructor Create(const ADescriptor: TCairoFontFaceDescriptor);
  {$IFDEF LINUX}
    destructor Destroy; override;
  {$ENDIF}
    function TextToGlyphs(ACairo: Pcairo_t;
      AText: PChar; ATextLength: Integer;
      var AGlyphs: Pcairo_glyph_t;
      var AGlyphCount: Integer;
      var AMapping: TCairoTextMapping): Boolean;
    // Properties
    property Descriptor: TCairoFontFaceDescriptor read FDescriptor;
  end;

  { TCairoFonts }

  TCairoFonts = class
  public type
    TCairoFontFaceCache = TACLValueCacheManager<TCairoFontFaceDescriptor, TCairoFontFace>;
    TCairoFontSubstitutions = TACLFontSubstitutions<TCairoFontFaceDescriptor>;
  {$IFDEF LINUX}
    TFontLibraryHandle = PFT_Library;
  {$ELSE}
    TFontLibraryHandle = Pointer;
  {$ENDIF}
  strict private
    class var FCache: TCairoFontFaceCache;
    class var FDefaultFontName: string;
    class var FDefaultFontSize: Integer;
    class var FGlyphSubstitutions: TCairoFontSubstitutions;
    class var FLibrary: TFontLibraryHandle;
    class var FLock: TACLCriticalSection;
    class var FMeasurer: Pcairo_t;
    class var FMeasurerSurface: Pcairo_surface_t;
    class var FSubstitutions: array[Byte] of TCairoFontFaceDescriptor;
    class var FSubstitutionPos: LongWord;
    class var FUtf8Buffer: PAnsiChar;
    class var FUtf8BufferSize: Integer;
    class procedure EnsureInit;
  public
    class constructor Create;
    class destructor Destroy;
    // Не должно вызываться вне Lock
    class function DefaultFontName: string;
    class function DefaultFontSize: Integer;
    class function MeasurerContext: Pcairo_t;
    class function Get(const AFont: TCairoFontFaceDescriptor): TCairoFontFace;
    class function Select(ACairo: Pcairo_t; AFont: TFont): TCairoFontFace; overload;
    class procedure Select(ACairo: Pcairo_t; AFontId: LongWord); overload;
    class function Substitute(ACairo: Pcairo_t; AFont: TCairoFontFace;
      AGlyphs: Pcairo_glyph_t; AGlyphCount: Integer; const AMapping: TCairoTextMapping): Boolean; overload;
    class function Substitute(var AFont: TCairoFontFace; AChar: UCS4Char): Boolean; overload;
    class function Substitute(var AFont: TCairoFontFaceDescriptor; AChar: UCS4Char = 0): Boolean; overload;
    class function ToUtf8(AText: PAnsiChar; ATextLen: Integer; out Utf8Len: Integer): PAnsiChar; overload;
    class function ToUtf8(AText: PWideChar; ATextLen: Integer; out Utf8Len: Integer): PAnsiChar; overload;
    class function UseFontForSubstitution(const ADescriptor: TCairoFontFaceDescriptor): LongWord;
    // Properties
    class property LibraryHandle: TFontLibraryHandle read FLibrary;
    class property Lock: TACLCriticalSection read FLock;
  end;

function cairo_get_glyph_index(ACairo: Pcairo_t; AText: PAnsiChar; ATextLen: Integer): LongWord;
function cairo_get_glyph_width(ACairo: Pcairo_t; AGlyphIndex: LongWord): cairo_text_extents_t;
function cairo_has_unknown_glyphs(AGlyphs: Pcairo_glyph_t; ACount: Integer): Boolean;
procedure cairo_offset_glyphs(AGlyphs: Pcairo_glyph_t; ACount: Integer; ADeltaX, ADeltaY: Double);
procedure cairo_set_fontId(AGlyphs: Pcairo_glyph_t; ACount: Integer; AFontId: LongWord);
procedure cairo_text_to_glyphs(ACairo: Pcairo_t; AText: PAnsiChar; ATextLen: Integer;
  var AGlyphs: Pcairo_glyph_t; var AGlyphCount: LongInt; var AMapping: TCairoTextMapping);
implementation

const
  CAIRO_FT_SYNTHESIZE_BOLD    = 1 shl 0;
  CAIRO_FT_SYNTHESIZE_OBLIQUE = 1 shl 1;

  FontWeights: array [0..18] of string = (
    'thin', 'extralight', 'ultralight', 'light', 'demilight', 'semilight',
    'book', 'regular', 'normal', 'medium', 'demibold', 'semibold', 'bold',
    'extrabold', 'ultrabold', 'black', 'heavy', 'extrablack', 'ultrablack'
  );

  FontWidths: array [0..8] of string = (
    'ultracondensed', 'extracondensed', 'condensed', 'semicondensed',
    'normal', 'semiexpanded', 'expanded', 'extraexpanded', 'ultraexpanded'
  );

  LanguageMap: array [TACLCharsetGroup] of string = (
    '', 'en', 'ru', 'el', 'hy', 'ka', 'he', 'ar', 'syr', 'dv', 'hi', 'bn', 'pa',
    'gu', 'or', 'ta', 'te', 'kn', 'ml', 'si', 'th', 'lo', 'bo', 'my', 'km','am',
    'chr', 'iu', 'sga', 'non', 'mn', 'ja', 'ja', 'ko', 'zh', 'ii', 'zh', 'tl',
    'hnn', 'bku', 'tbw', 'bug', 'ban', 'su', 'jv', 'lif', 'tdd', 'khb', 'nod',
    'lep', 'sat', 'vai', 'bax', 'syl', 'cjm', 'tyj', 'mni', 'nqo', 'ber', 'zh',
    'emoji', 'math', 'sym', 'pua', 'braille', 'brah', 'ae', 'egy', 'sux', 'gmy',
    'phn', 'inherited'
  );

{$IFDEF LINUX}

  FontWeightsMap: array[0..18] of Integer = (
    FC_WEIGHT_THIN, FC_WEIGHT_EXTRALIGHT, FC_WEIGHT_EXTRALIGHT, FC_WEIGHT_LIGHT,
    FC_WEIGHT_SEMILIGHT, FC_WEIGHT_SEMILIGHT, FC_WEIGHT_BOOK, FC_WEIGHT_REGULAR,
    FC_WEIGHT_REGULAR, FC_WEIGHT_MEDIUM, FC_WEIGHT_SEMIBOLD, FC_WEIGHT_SEMIBOLD,
    FC_WEIGHT_BOLD, FC_WEIGHT_ULTRABOLD, FC_WEIGHT_ULTRABOLD, FC_WEIGHT_HEAVY,
    FC_WEIGHT_HEAVY, FC_WEIGHT_ULTRABLACK, FC_WEIGHT_ULTRABLACK
  );

  FontWidthsMap: array [0..8] of Integer = (
    FC_WIDTH_ULTRACONDENSED, FC_WIDTH_EXTRACONDENSED, FC_WIDTH_CONDENSED,
    FC_WIDTH_SEMICONDENSED, FC_WIDTH_NORMAL, FC_WIDTH_SEMIEXPANDED,
    FC_WIDTH_EXPANDED, FC_WIDTH_EXTRAEXPANDED, FC_WIDTH_ULTRAEXPANDED
  );

function cairo_ft_font_face_create_for_ft_face(face:PFT_Face; load_flags:longint):Pcairo_font_face_t; cdecl; external LIB_CAIRO;
function FcPatternAddBool(pattern: PFcPattern; const obj: PChar; b: TFcBool): TFcBool; cdecl; external libfontconfig.DefaultLibName;
function FcPatternAddCharSet(p:PFcPattern; const obj: PChar; c:PFcCharSet): TFcBool; cdecl; external libfontconfig.DefaultLibName;
function FcPatternAddDouble(pattern: PFcPattern; const obj: PChar; d: cdouble): TFcBool; cdecl; external libfontconfig.DefaultLibName;
function FcPatternAddInteger(pattern: PFcPattern; const obj: PChar; i: cint): TFcBool; cdecl; external libfontconfig.DefaultLibName;
function FcPatternAddString(pattern: PFcPattern; const obj: PChar; const s: PFcChar8): TFcBool; cdecl; external libfontconfig.DefaultLibName;
function FcPatternGetBool(const pattern: PFcPattern; const obj: PChar; n: cint; b: PFcBool): TFcResult; cdecl; external libfontconfig.DefaultLibName;
function FcPatternGetCharSet(const pattern: PFcPattern; const obj: PChar; n: cint; b: PFcCharSet): TFcResult; cdecl; external libfontconfig.DefaultLibName;
function FcPatternGetDouble(const pattern: PFcPattern; const obj: PChar; n: cint; d: pcdouble): TFcResult; cdecl; external libfontconfig.DefaultLibName;
function FcPatternGetInteger(const pattern: PFcPattern; const obj: PChar; n: cint; i: pcint): TFcResult; cdecl; external libfontconfig.DefaultLibName;
function FcPatternGetLangSet(const pattern:PFcPattern; const obj: PChar; n:cint; ls: PFcLangSet): TFcResult; cdecl; external libfontconfig.DefaultLibName;
function FcPatternGetString(const pattern: PFcPattern; const obj: PChar; n: cint; s: PFcChar8): TFcResult; cdecl; external libfontconfig.DefaultLibName;
{$ENDIF}

{$IFDEF LCLGtk3}
function hb_ft_font_create_referenced(ft_face: Pointer): Phb_font_t; cdecl; external LazHarfBuzz0_library;
{$ENDIF}

function cairo_get_glyph_index(ACairo: Pcairo_t; AText: PAnsiChar; ATextLen: Integer): LongWord;
var
  LGlyph: cairo_glyph_t;
  LGlyphNum: Integer;
  LGlyphPtr: Pcairo_glyph_t;
begin
  LGlyphNum := 1;
  LGlyphPtr := @LGlyph;
  cairo_scaled_font_text_to_glyphs(cairo_get_scaled_font(ACairo),
    0, 0, AText, ATextLen, @LGlyphPtr, @LGlyphNum, nil, nil, nil);
  Result := LGlyph.index;
end;

function cairo_get_glyph_width(ACairo: Pcairo_t; AGlyphIndex: LongWord): cairo_text_extents_t;
var
  LGlyph: cairo_glyph_t;
  LSwitchFont: Boolean;
begin
  TCairoFonts.Lock.Enter;
  try
    LSwitchFont := AGlyphIndex and GLYPH_MASK_FONTINDEX <> 0;
    if LSwitchFont then
    begin
      cairo_save(ACairo);
      TCairoFonts.Select(ACairo, AGlyphIndex and GLYPH_MASK_FONTINDEX);
      AGlyphIndex := AGlyphIndex and GLYPH_MASK_GLYPHINDEX;
    end;
    LGlyph.x := 0;
    LGlyph.y := 0;
    LGlyph.index := AGlyphIndex;
    cairo_scaled_font_glyph_extents(cairo_get_scaled_font(ACairo), @LGlyph, 1, @Result);
    if LSwitchFont then
      cairo_restore(ACairo);
  finally
    TCairoFonts.Lock.Leave;
  end;
end;

function cairo_has_unknown_glyphs(AGlyphs: Pcairo_glyph_t; ACount: Integer): Boolean;
var
  I: Integer;
begin
  for I := 0 to ACount - 1 do
  begin
    if AGlyphs[I].index = 0 then
      Exit(True);
  end;
  Result := False;
end;

procedure cairo_offset_glyphs(AGlyphs: Pcairo_glyph_t; ACount: Integer; ADeltaX, ADeltaY: Double);
var
  I: Integer;
begin
  for I := 0 to ACount - 1 do
    with AGlyphs[I] do
    begin
      X := X + ADeltaX;
      Y := Y + ADeltaY;
    end;
end;

procedure cairo_set_fontId(AGlyphs: Pcairo_glyph_t; ACount: Integer; AFontId: LongWord);
begin
  AFontId := AFontId and GLYPH_MASK_FONTINDEX;
  while ACount > 0 do
  begin
    if AGlyphs^.index <> 0 then
      AGlyphs^.index := AFontId or AGlyphs^.index and GLYPH_MASK_GLYPHINDEX;
    Inc(AGlyphs);
    Dec(ACount);
  end;
end;

procedure cairo_text_to_glyphs(ACairo: Pcairo_t; AText: PAnsiChar; ATextLen: Integer;
  var AGlyphs: Pcairo_glyph_t; var AGlyphCount: LongInt; var AMapping: TCairoTextMapping);
var
  LClusterCount: Integer;
  LClusterFlags: cairo_text_cluster_flags_t;
  LClusters: Pcairo_text_cluster_t;
begin
  LClusters := nil;
  LClusterCount := 0;
  cairo_scaled_font_text_to_glyphs(cairo_get_scaled_font(ACairo), 0, 0,
    AText, ATextLen, @AGlyphs, @AGlyphCount, @LClusters, @LClusterCount, @LClusterFlags);
  AMapping.Init(AText, AGlyphCount, LClusters, LClusterCount);
end;

{ TCairoTextMapping }

procedure TCairoTextMapping.Free;
begin
  TextReference := nil;
  TextOffsets := nil;
end;

procedure TCairoTextMapping.Init(AText: PAnsiChar; AGlyphCount: Integer);
begin
  TextReference := AText;
  SetLength(TextOffsets, AGlyphCount);
end;

procedure TCairoTextMapping.Init(AText: PAnsiChar; AGlyphCount: Integer;
  AClusters: Pcairo_text_cluster_t; AClusterCount: Integer);
var
  LGlyphIndex: Integer;
  LTextOffset: Integer;
  I, J: Integer;
begin
  try
    LGlyphIndex := 0;
    LTextOffset := 0;
    Init(AText, AGlyphCount);
    for I := 0 to AClusterCount - 1 do
    begin
      for J := 1 to AClusters[I].num_glyphs do
      begin
        TextOffsets[LGlyphIndex] := LTextOffset;
        Inc(LGlyphIndex);
      end;
      Inc(LTextOffset, AClusters[I].num_bytes);
    end;
  finally
    cairo_text_cluster_free(AClusters);
  end;
end;

function TCairoTextMapping.TextAt(AGlyphIndex: Integer): PAnsiChar;
begin
  Result := TextReference + TextOffsets[AGlyphIndex];
end;

{ TCairoFontFaceDescriptor }

class function TCairoFontFaceDescriptor.Create(AFont: TFont): TCairoFontFaceDescriptor;
var
  LFace: string;
{$IFDEF LINUX}
  LDelimiter: Integer;
{$ENDIF}
begin
  Result := Default(TCairoFontFaceDescriptor);
  Result.Styles := AFont.Style * [fsBold, fsItalic]; // Strikeout/Underline рисуются нами
  Result.Weight := -1;
  Result.Width := -1;

  LFace := AFont.Name;
  if (LFace = '') or (LFace = 'default') then
    LFace := TCairoFonts.DefaultFontName;

{$IFDEF LINUX}
  LDelimiter := LastDelimiter(' ', LFace);
  if LDelimiter > 0 then
  begin
    Result.Weight := IndexStr(LowerCase(Copy(LFace, LDelimiter + 1)), FontWeights);
    if Result.Weight >= 0 then
    begin
      Result.Weight := FontWeightsMap[Result.Weight];
      SetLength(LFace, LDelimiter);
    end;
  end;

  LDelimiter := LastDelimiter(' ', LFace);
  if LDelimiter > 0 then
  begin
    Result.Width := IndexStr(LowerCase(Copy(LFace, LDelimiter + 1)), FontWidths);
    if Result.Width >= 0 then
    begin
      Result.Width := FontWidthsMap[Result.Width];
      SetLength(LFace, LDelimiter);
    end;
  end;

  if Result.Weight < 0 then
    Result.Weight := IfThen(fsBold in AFont.Style, FC_WEIGHT_BOLD, FC_WEIGHT_REGULAR);
  if Result.Width < 0 then
    Result.Width := FC_WIDTH_NORMAL;
{$ENDIF}

  Result.Name := acAString(LFace);
end;

class operator TCairoFontFaceDescriptor.Equal(const Left, Right: TCairoFontFaceDescriptor): Boolean;
begin
  Result :=
    (Left.Embolden = Right.Embolden) and
    (Left.FaceIndex = Right.FaceIndex) and
    (Left.Styles = Right.Styles) and
    (Left.Weight = Right.Weight) and
    (Left.Width = Right.Width) and
    (Left.Path = Right.Path) and
    (Left.Name = Right.Name)
end;

{ TCairoFontFaceDescriptorComparer }

class function TCairoFontFaceDescriptorComparer.GetDefault: IEqualityComparer<TCairoFontFaceDescriptor>;
begin
  if FDefault = nil then
    FDefault := TCairoFontFaceDescriptorComparer.Create;
  Result := FDefault;
end;

function TCairoFontFaceDescriptorComparer.Equals(const Left, Right: TCairoFontFaceDescriptor): Boolean;
begin
  Result := Left = Right;
end;

function TCairoFontFaceDescriptorComparer.GetHashCode(const Value: TCairoFontFaceDescriptor): HashCode;
var
  LState: Pointer;
begin
  if Value.Path <> '' then
    Result := TACLHashBobJenkins.Calculate(Value.Path)
  else
  begin
    TACLHashBobJenkins.Initialize(LState);
    TACLHashBobJenkins.Update(LState, Value.Name);
    TACLHashBobJenkins.Update(LState, @Value.Styles, SizeOf(Value.Styles));
    Result := TACLHashBobJenkins.Finalize(LState);
  end;
end;

{ TCairoFontFace }

{$IFDEF LINUX}
constructor TCairoFontFace.Create(const ADescriptor: TCairoFontFaceDescriptor);
var
  LCode: Integer;
  LCtmMatrix: cairo_matrix_t;
  LFontFace: Pcairo_font_face_t;
  LFontMatrix: cairo_matrix_t;
  LOptions: Pcairo_font_options_t;
  LSynthesizesFlags: LongWord;
begin
  FPixelSize := 18;
  FDescriptor := ADescriptor;
  LCode := FT_New_Face(TCairoFonts.LibraryHandle, PChar(Descriptor.Path), Descriptor.FaceIndex, FFtFace);
  if LCode <> 0 then
    raise EInvalidGraphicOperation.CreateFmt('FT_New_Face(%s) failed (%d).', [Descriptor.Path, LCode]);

  LOptions := cairo_font_options_create;
  LFontFace := cairo_ft_font_face_create_for_ft_face(FFtFace, 0);
  try
    // The actual contents of the cairo_user_data_key_t struct is never used, and there is no
    // need to initialize the object; only the unique address of a cairo_data_key_t object is used.
    cairo_font_face_set_user_data(LFontFace, Pcairo_user_data_key_t(Self), FFtFace, @FreeFtFace);

    cairo_font_options_set_hint_metrics(LOptions, CAIRO_HINT_METRICS_ON);
    cairo_font_options_set_hint_style(LOptions, CAIRO_HINT_STYLE_SLIGHT);
    cairo_font_options_set_antialias(LOptions, CAIRO_ANTIALIAS_SUBPIXEL);
    cairo_font_options_set_subpixel_order(LOptions, CAIRO_SUBPIXEL_ORDER_RGB);

    cairo_matrix_init_identity(@LCtmMatrix);
    cairo_matrix_init_scale(@LFontMatrix, FPixelSize, FPixelSize);

    LSynthesizesFlags := 0;
    if (fsItalic in Descriptor.Styles) and (FFtFace^.style_flags and FT_STYLE_FLAG_ITALIC = 0) then
      LSynthesizesFlags := LSynthesizesFlags or CAIRO_FT_SYNTHESIZE_OBLIQUE;
    if (fsBold in Descriptor.Styles) and Descriptor.Embolden then// (FFtFace^.style_flags and FT_STYLE_FLAG_BOLD = 0) - failed on "NotoSans ExtraCondensed ExtraBold"
      LSynthesizesFlags := LSynthesizesFlags or CAIRO_FT_SYNTHESIZE_BOLD;
    if LSynthesizesFlags <> 0 then
      cairo_ft_font_face_set_synthesize(LFontFace, LSynthesizesFlags);

    FHandle := cairo_scaled_font_create(LFontFace, @LFontMatrix, @LCtmMatrix, LOptions);
    if FHandle = nil then
      raise EInvalidGraphicOperation.Create('Failed to create cairo scaled font');
  finally
    cairo_font_options_destroy(LOptions);
    cairo_font_face_destroy(LFontFace);
  end;
end;

destructor TCairoFontFace.Destroy;
begin
  cairo_scaled_font_destroy(FHandle);
  inherited Destroy;
end;

class procedure TCairoFontFace.FreeFtFace(AFace: PFT_Face); cdecl;
begin
  // FT_Done_FreeType автоматически прибьёт все открытые им FtFace-ы.
  // Если шрифт попал в кэш-пул cairo, то прибиваться он будет при финализации
  // библиотеки, которая происходит сильно позже вызова FT_Done_FreeType из нашего кода.
  if TCairoFonts.LibraryHandle <> nil then
    FT_Done_Face(AFace);
end;

procedure TCairoFontFace.Select(ACairo: Pcairo_t);
begin
  cairo_set_scaled_font(ACairo, FHandle);
end;

{$ELSE}

constructor TCairoFontFace.Create(const ADescriptor: TCairoFontFaceDescriptor);
begin
  FDescriptor := ADescriptor;
end;

procedure TCairoFontFace.Select(ACairo: Pcairo_t);
const
  SlantMap: array[Boolean] of cairo_font_slant_t =
    (CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_SLANT_ITALIC);
  WeightMap: array[Boolean] of cairo_font_weight_t =
    (CAIRO_FONT_WEIGHT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
begin
  cairo_select_font_face(ACairo, PAnsiChar(Descriptor.Name),
    SlantMap[fsItalic in Descriptor.Styles],
    WeightMap[fsBold in Descriptor.Styles]);
end;

{$ENDIF}

function TCairoFontFace.TextToGlyphs;
{$IFDEF LCLGtk3}
const
  Directions: array[TACLTextReadingDirection] of Thb_direction_t = (
    HB_DIRECTION_INVALID, HB_DIRECTION_LTR, HB_DIRECTION_RTL
  );
  Scripts: array[TACLCharsetGroup] of Thb_script_t = (HB_SCRIPT_INVALID,
    HB_SCRIPT_LATIN, HB_SCRIPT_CYRILLIC, HB_SCRIPT_GREEK, HB_SCRIPT_ARMENIAN,
    HB_SCRIPT_GEORGIAN, HB_SCRIPT_HEBREW, HB_SCRIPT_ARABIC, HB_SCRIPT_SYRIAC,
    HB_SCRIPT_THAANA, HB_SCRIPT_DEVANAGARI, HB_SCRIPT_BENGALI, HB_SCRIPT_GURMUKHI,
    HB_SCRIPT_GUJARATI, HB_SCRIPT_ORIYA, HB_SCRIPT_TAMIL, HB_SCRIPT_TELUGU,
    HB_SCRIPT_KANNADA, HB_SCRIPT_MALAYALAM, HB_SCRIPT_SINHALA, HB_SCRIPT_THAI,
    HB_SCRIPT_LAO, HB_SCRIPT_TIBETAN, HB_SCRIPT_MYANMAR, HB_SCRIPT_KHMER,
    HB_SCRIPT_ETHIOPIC, HB_SCRIPT_CHEROKEE, HB_SCRIPT_INVALID,
    HB_SCRIPT_OGHAM, HB_SCRIPT_RUNIC, HB_SCRIPT_MONGOLIAN, HB_SCRIPT_HIRAGANA,
    HB_SCRIPT_KATAKANA, HB_SCRIPT_HANGUL, HB_SCRIPT_HAN, HB_SCRIPT_YI,
    HB_SCRIPT_BOPOMOFO, HB_SCRIPT_TAGALOG, HB_SCRIPT_HANUNOO, HB_SCRIPT_BUHID,
    HB_SCRIPT_TAGBANWA, HB_SCRIPT_BUGINESE, HB_SCRIPT_BALINESE, HB_SCRIPT_SUNDANESE,
    HB_SCRIPT_JAVANESE, HB_SCRIPT_LIMBU, HB_SCRIPT_INVALID, HB_SCRIPT_INVALID,
    HB_SCRIPT_INVALID, HB_SCRIPT_LEPCHA, HB_SCRIPT_INVALID, HB_SCRIPT_VAI,
    HB_SCRIPT_BAMUM, HB_SCRIPT_INVALID, HB_SCRIPT_CHAM, HB_SCRIPT_INVALID,
    HB_SCRIPT_INVALID, HB_SCRIPT_NKO, HB_SCRIPT_TIFINAGH,
    HB_SCRIPT_INVALID, HB_SCRIPT_INVALID, HB_SCRIPT_INVALID,
    HB_SCRIPT_INVALID, HB_SCRIPT_INVALID, HB_SCRIPT_BRAILLE, HB_SCRIPT_BRAHMI,
    HB_SCRIPT_AVESTAN, HB_SCRIPT_EGYPTIAN_HIEROGLYPHS, HB_SCRIPT_CUNEIFORM,
    HB_SCRIPT_INVALID, HB_SCRIPT_PHOENICIAN, HB_SCRIPT_INVALID
  );
var
  I, X, Y: Integer;
  LBuffer: Phb_buffer_t;
  LChar: UCS4Char;
  LCharDirection: TACLTextReadingDirection;
  LCharGroup: TACLCharsetGroup;
  LCharLength: Integer;
  LFont: Phb_font_t;
  LFontMatrix: cairo_matrix_t;
  LFontId: LongWord;
  LFontScale: Double;
  LFontUpem: Double;
  LGlyphCount: Integer;
  LGlyphs: Phb_glyph_info_t;
  LGlyphsPos: Phb_glyph_position_t;
begin
  Result := False;
  LBuffer := hb_buffer_create;
  if LBuffer <> nil then
  try
    LFont := hb_ft_font_create_referenced(FFtFace);
    if LFont <> nil then
    try
      LChar := acCharUCS4FromUtf8(AText, ATextLength, LCharLength);
      LCharGroup := acGetCharsetGroup(LChar);
      LCharDirection := acGetReadingDirection(LChar);
      if Scripts[LCharGroup] <> HB_SCRIPT_INVALID then
        hb_buffer_set_script(LBuffer, Scripts[LCharGroup]);
      if Directions[LCharDirection] <> HB_DIRECTION_INVALID then
        hb_buffer_set_direction(LBuffer, Directions[LCharDirection]);
      hb_buffer_add_utf8(LBuffer, AText, ATextLength, 0, -1);
      hb_shape(LFont, LBuffer, nil, 0);

      LGlyphCount := 0;
      LGlyphs := hb_buffer_get_glyph_infos(LBuffer, @LGlyphCount);
      LGlyphsPos := hb_buffer_get_glyph_positions(LBuffer, nil);
      if (LGlyphs <> nil) and (LGlyphCount > 0) then
      begin
        if AGlyphCount > 0 then
          LGlyphCount := Min(LGlyphCount, AGlyphCount);
        if AGlyphs = nil then
          AGlyphs := cairo_glyph_allocate(LGlyphCount);

        cairo_get_font_matrix(ACairo, @LFontMatrix);
        LFontUpem := hb_face_get_upem(hb_font_get_face(LFont));
        LFontScale := LFontMatrix.xx / IfThen(LFontUpem > 0, LFontUpem, 64.0);

        X := 0; Y := 0;
        AMapping.Init(AText, LGlyphCount);
        for I := 0 to LGlyphCount - 1 do
        begin
          AGlyphs[I].index := LGlyphs[I].codepoint;
          AGlyphs[I].x := Round(LFontScale * (LGlyphsPos[I].x_offset + X));
          AGlyphs[I].y := Round(LFontScale * (LGlyphsPos[I].y_offset + Y));
          AMapping.TextOffsets[I] := LGlyphs[I].cluster;
          Inc(X, LGlyphsPos[I].x_advance);
          Inc(Y, LGlyphsPos[I].y_advance);
        end;

        AGlyphCount := LGlyphCount;
        Exit(True);
      end;
    finally
      hb_font_destroy(LFont);
    end;
  finally
    hb_buffer_destroy(LBuffer);
  end;
{$ELSE}
begin
  Result := False;
{$ENDIF}
end;

{ TCairoFonts }

class constructor TCairoFonts.Create;
begin
  FLock := TACLCriticalSection.Create;
  FSubstitutionPos := 1;
end;

class destructor TCairoFonts.Destroy;
begin
  FreeAndNil(FGlyphSubstitutions);
  FreeAndNil(FCache);
  if FMeasurer <> nil then
    cairo_destroy(FMeasurer);
  if FMeasurerSurface <> nil then
    cairo_surface_destroy(FMeasurerSurface);
  if FLibrary <> nil then
  try
  {$IFDEF LINUX}
    FT_Done_FreeType(FLibrary);
    UnLoadFontConfigLib;
  {$ENDIF}
  finally
    FLibrary := nil;
  end;
  FreeMem(FUtf8Buffer);
  FreeAndNil(FLock);
  inherited;
end;

class procedure TCairoFonts.EnsureInit;
var
  LFont: TLogFont;
begin
  if FLibrary <> nil then Exit;

  Lock.Enter;
  try
    if FLibrary <> nil then
      Exit;
  {$IFDEF LINUX}
    if FT_Init_FreeType(FLibrary) <> 0 then
      raise Exception.Create('FT_Init_FreeType faied');
    LoadFontConfigLib('');
  {$ELSE}
    FLibrary := Pointer($123);
  {$ENDIF}

    FCache := TCairoFontFaceCache.Create(256, TCairoFontFaceDescriptorComparer.Default, True);
    FGlyphSubstitutions := TCairoFontSubstitutions.Create(TCairoFontFaceDescriptorComparer.Default);

    GetObject(GetStockObject(DEFAULT_GUI_FONT), SizeOf(TLogFont), @LFont);
    FDefaultFontName := string(LFont.lfFaceName);
    FDefaultFontSize := LFont.lfHeight;
    if FDefaultFontName = '' then
    {$IF DEFINED(LCLGtk3)}
      FDefaultFontName := GTK3WidgetSet.DefaultAppFontName;
    {$ELSEIF DEFINED(LCLGtk2)}
      FDefaultFontName := GetDefaultFontName;
    {$ELSE}
      FDefaultFontName := string(DefFontData.Name);
    {$ENDIF}
    if FDefaultFontSize = 0 then
      FDefaultFontSize := DefFontData.Height;
    if FDefaultFontSize = 0 then
      FDefaultFontSize := -11;
  finally
    Lock.Leave;
  end;
end;

class function TCairoFonts.DefaultFontName: string;
begin
  EnsureInit;
  Result := FDefaultFontName;
end;

class function TCairoFonts.DefaultFontSize: Integer;
begin
  EnsureInit;
  Result := FDefaultFontSize;
end;

class function TCairoFonts.MeasurerContext: Pcairo_t;
begin
  CheckIsMainThread;

  if (FMeasurer <> nil) and (cairo_status(FMeasurer) <> CAIRO_STATUS_SUCCESS) then
  begin
    cairo_destroy(FMeasurer);
    if FMeasurerSurface <> nil then
      cairo_surface_destroy(FMeasurerSurface);
    FMeasurerSurface := nil;
    FMeasurer := nil;
  end;

  if FMeasurer = nil then
  begin
  {$IFDEF LCLGtk3} // CAIRO_HINT_METRICS_ON требует контекст реального окна
    FMeasurer := Pcairo_t(gdk_cairo_create(gdk_get_default_root_window));
  {$ELSE}
    FMeasurerSurface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1, 1);
    FMeasurer := cairo_create(FMeasurerSurface);
  {$ENDIF}
  end;
  Result := FMeasurer;
end;

class function TCairoFonts.Get(const AFont: TCairoFontFaceDescriptor): TCairoFontFace;
var
  LFaceDescriptor: TCairoFontFaceDescriptor;
begin
  EnsureInit;
  if not FCache.Get(AFont, Result) then
  begin
    LFaceDescriptor := AFont;
    if LFaceDescriptor.Path = '' then
      Substitute(LFaceDescriptor);
    Result := TCairoFontFace.Create(LFaceDescriptor);
    FCache.Add(AFont, Result);
  end;
end;

class function TCairoFonts.Select(ACairo: Pcairo_t; AFont: TFont): TCairoFontFace;
begin
  Result := Get(TCairoFontFaceDescriptor.Create(AFont));
  Result.Select(ACairo);
  if AFont.Height = 0 then
    cairo_set_font_size(ACairo, DefaultFontSize)
  else
    cairo_set_font_size(ACairo, Abs(acResolveFontHeight(AFont, AFont.Height)));
end;

class procedure TCairoFonts.Select(ACairo: Pcairo_t; AFontId: LongWord);
var
  LFontIndex: LongWord;
  LMatrix: cairo_matrix_t;
begin
  LFontIndex := (AFontId and GLYPH_MASK_FONTINDEX) shr 24;
  if LFontIndex < FSubstitutionPos then
  begin
    cairo_get_font_matrix(ACairo, @LMatrix);
    Get(FSubstitutions[LFontIndex]).Select(ACairo);
    cairo_set_font_matrix(ACairo, @LMatrix);
  end;
end;

class function TCairoFonts.Substitute(
  ACairo: Pcairo_t; AFont: TCairoFontFace;
  AGlyphs: Pcairo_glyph_t; AGlyphCount: Integer;
  const AMapping: TCairoTextMapping): Boolean;
var
  LChar: UCS4Char;
  LCharLen: Integer;
  LCharPtr: PAnsiChar;
  LCurrentFont: TCairoFontFaceDescriptor;
  LCurrentFontId: LongWord;
  LFont: TCairoFontFaceDescriptor;
  LDelta: Double;
  LGlyphIndex: LongWord;
  I: Integer;
begin
  Result := False;
  if cairo_has_unknown_glyphs(AGlyphs, AGlyphCount) then
  begin
    Lock.Enter;
    cairo_save(ACairo);
    try
      LCurrentFontId := 0;
      for I := 0 to AGlyphCount - 1 do
      begin
        if AGlyphs[I].index <> 0 then
          Continue;

        LCharPtr := AMapping.TextAt(I);
        LChar := acCharUCS4FromUtf8(LCharPtr, 4{?!}, LCharLen);
        if LChar < 32 then Continue;

        if FGlyphSubstitutions.Find(AFont.Descriptor, LChar, LFont, LGlyphIndex) then
        begin
          if LGlyphIndex <> 0 then
          begin
            // Если кэш пошёл на новый круг, то старый индекс уже неактуален
            LCurrentFont := LFont;
            LCurrentFontId := UseFontForSubstitution(LFont);
            Select(ACairo, LCurrentFontId);
          end;
        end
        else
        begin
          LGlyphIndex := 0;
          LFont := AFont.Descriptor;
          if Substitute(LFont, LChar) then
          begin
            LCurrentFont := LFont;
            LCurrentFontId := UseFontForSubstitution(LFont);
            Select(ACairo, LCurrentFontId);
            LGlyphIndex := cairo_get_glyph_index(ACairo, LCharPtr, LCharLen);
          end;
          FGlyphSubstitutions.Add(AFont.Descriptor, LChar, LCurrentFont, LGlyphIndex);
        end;

        if LGlyphIndex <> 0 then
        begin
          AGlyphs[I].index :=
            (LCurrentFontId and GLYPH_MASK_FONTINDEX) or
            (LGlyphIndex and GLYPH_MASK_GLYPHINDEX);
          if I + 1 < AGlyphCount then
          begin
            LDelta := cairo_get_glyph_width(ACairo, LGlyphIndex).x_advance - (AGlyphs[I + 1].x - AGlyphs[I].x);
            if LDelta <> 0 then
              cairo_offset_glyphs(@AGlyphs[I + 1], AGlyphCount - I - 1, LDelta, 0);
          end;
          Result := True; // Eсть подстановка!
        end;
      end;
    finally
      cairo_restore(ACairo);
      Lock.Leave;
    end;
  end;
end;

class function TCairoFonts.Substitute(var AFont: TCairoFontFace; AChar: UCS4Char): Boolean;
var
  LDescription: TCairoFontFaceDescriptor;
begin
  //if FGlyphSubstitutions.Find(AFont.Descriptor, AChar, LDescription, LUnused) then
  //begin
  //  AFont := Get(LDescription);
  //  Exit(True);
  //end;
  LDescription := AFont.Descriptor;
  if Substitute(LDescription, AChar) then
  begin
    AFont := Get(LDescription);
    Exit(True);
  end;
  Result := False;
end;

class function TCairoFonts.Substitute(
  var AFont: TCairoFontFaceDescriptor; AChar: UCS4Char): Boolean;
{$IFDEF LINUX}
const
  SlantMap: array[Boolean] of Integer = (FC_SLANT_ROMAN, FC_SLANT_ITALIC);
var
  LBoolean: TFcBool;
  LCharSet: PFcCharSet;
  LCharSetGroup: TACLCharsetGroup;
  LConfig: PFcConfig;
  LPattern: PFcPattern;
  LResult: TFcResult;
  LResultPattern: PFcPattern;
  LString: PFcChar8;
  LValue: Integer;
begin
  EnsureInit;
  Result := False;
  LPattern := FcPatternCreate;
  try
    FcPatternAddString(LPattern, FC_FAMILY, PChar(AFont.Name));
    FcPatternAddInteger(LPattern, FC_WEIGHT, AFont.Weight);
    FcPatternAddInteger(LPattern, FC_WIDTH, AFont.Width);
    FcPatternAddInteger(LPattern, FC_SLANT, SlantMap[fsItalic in AFont.Styles]);
    FcPatternAddBool(LPattern, FC_SCALABLE, 1);
    FcPatternAddBool(LPattern, FC_OUTLINE, 1);

    if AChar <> 0 then
    begin
      LCharSetGroup := acGetCharsetGroup(AChar);
      if LCharSetGroup <> TACLCharsetGroup.Unknown then
        FcPatternAddString(LPattern, FC_LANG, PChar(LanguageMap[LCharSetGroup]));
      LCharSet := FcCharSetCreate;
      FcCharSetAddChar(LCharSet, AChar);
      FcPatternAddCharSet(LPattern, FC_CHARSET, LCharSet);
      FcCharSetDestroy(LCharSet);
    end;

    LConfig := FcConfigGetCurrent;
    FcConfigSubstitute(LConfig, LPattern, FcMatchPattern);
    FcDefaultSubstitute(LPattern);
    LResult := FcResultNoMatch;
    LResultPattern := FcFontMatch(LConfig, LPattern, @LResult);

    if LResultPattern <> nil then
    try
      if LResult = FcResultMatch then
      begin
        LString := nil;
        if FcPatternGetString(LResultPattern, FC_FILE, 0, @LString) = FcResultMatch then
        begin
          AFont.Path := StrPas(LString);
          Result := True;
        end;
        LString := nil;
        if FcPatternGetString(LResultPattern, FC_FAMILY, 0, @LString) = FcResultMatch then
          AFont.Name := StrPas(LString);
        if FcPatternGetInteger(LResultPattern, FC_INDEX, 0, @LValue) = FcResultMatch then
          AFont.FaceIndex := LValue;
        if FcPatternGetBool(LResultPattern, FC_EMBOLDEN, 0, @LBoolean) = FcResultMatch then
          AFont.Embolden := LBoolean <> 0;
        if FcPatternGetInteger(LResultPattern, FC_WEIGHT, 0, @LValue) = FcResultMatch then
        begin
          if (LValue < AFont.Weight) and (fsBold in AFont.Styles) and
            // может получиться так: мы запрашивали FC_WEIGHT_BOLD, а FontConfig
            // вернул нам FC_WEIGHT_SEMIBOLD, визуально это уже жирный шрифт, а
            // если мы включим Embolden - получится ExtraBold
            // '/usr/share/fonts/ttf/google-droid/DroidSansHebrew-Bold.ttf'
            // Итого, Embolden включаем только в том случае, если:
            // 1) FontConfig вернул нам Regular / Thin шрифт, а мы просили Bold
            // 2) FontConfig вернул нам Bold, а мы просили ExtraBold или что по круче.
            ((LValue < FC_WEIGHT_SEMIBOLD) or (LValue >= FC_WEIGHT_BOLD))
          then
            AFont.Embolden := True;
        end;
      end;
    finally
      FcPatternDestroy(LResultPattern);
    end;
  finally
    FcPatternDestroy(LPattern);
  end;
{$ELSE}
begin
  Result := False;
{$ENDIF}
end;

class function TCairoFonts.ToUtf8(AText: PAnsiChar; ATextLen: Integer; out Utf8Len: Integer): PAnsiChar;
begin
  Result := AText;
  Utf8Len := ATextLen;
end;

class function TCairoFonts.ToUtf8(AText: PWideChar; ATextLen: Integer; out Utf8Len: Integer): PAnsiChar;
begin
  if FUtf8BufferSize < 3 * ATextLen + 1 then
  begin
    FUtf8BufferSize := 3 * ATextLen + 1;
    ReallocMem(FUtf8Buffer, FUtf8BufferSize);
  end;
  Result := FUtf8Buffer;
  Utf8Len := acUnicodeToUtf8(Result, FUtf8BufferSize - 1, AText, ATextLen);
  Result[Utf8Len] := #0;
end;

class function TCairoFonts.UseFontForSubstitution(const ADescriptor: TCairoFontFaceDescriptor): LongWord;
var
  I: LongWord;
begin
  for I := 1 to FSubstitutionPos - 1 do
  begin
    if FSubstitutions[I] = ADescriptor then
      Exit(I shl 24);
  end;
  FSubstitutions[FSubstitutionPos] := ADescriptor;
  Result := FSubstitutionPos shl 24;
  Inc(FSubstitutionPos);
  if FSubstitutionPos > MaxByte then
    FSubstitutionPos := 1; // 0 зарезервирован под оригинальный шрифт
end;

end.
