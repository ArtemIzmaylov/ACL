{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*         Extended Graphic Library          *}
{*            Cairo Integration              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2024-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.Ex.Cairo; // FPC:OK

{$I ACL.Config.inc}

{$POINTERMATH ON}

interface

uses
  cairo,
  gdk2,
  gtk2Def,
  // LCL
  LazUtf8,
  LCLIntf,
  LCLType,
  // VCL
  Math,
  Graphics,
  SysUtils,
  Types,
  // ACL
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Utils.Common;

type

  { EGSCairoError }

  EGSCairoError = class(Exception);

  { TCairoColor }

  TCairoColor = record
    R, G, B, A: Double;
    class function From(A, R, G, B: Byte): TCairoColor; overload; static;
    class function From(Color: TAlphaColor): TCairoColor; overload; static;
    class function From(Color: TColor): TCairoColor; overload; static;
  end;

  { TCairoCanvas }

  TCairoCanvas = class
  strict private
    FOrigin: TPoint;
    FHandle: Pcairo_t;
    FTargetSurface: Pcairo_surface_t;

    procedure SetLineStyle(AWidth: Single; AStyle: TACL2DRenderStrokeStyle);
  public
    //# Initialization
    procedure BeginPaint(ACanvas: TCanvas);
    procedure EndPaint;

    //# Drawing
    procedure FillRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor);
    procedure FillRectangleByGradient(
      AFrom, ATo: TAlphaColor; const ARect: TRect; AVertical: Boolean);
    procedure FillSurface(const ATargetRect, ASourceRect: TRect;
      ASurface: Pcairo_surface_t; AAlpha: Double; ATileMode: Boolean);
    procedure Line(X1, Y1, X2, Y2: Single; Color: TAlphaColor;
      Width: Single = 1; Style: TACL2DRenderStrokeStyle = ssSolid);

    //# Properties
    property Origin: TPoint read FOrigin;
    property Handle: Pcairo_t read FHandle;
  end;

var
  GpPaintCanvas: TCairoCanvas;

(*
  Флаги, поддерживаемые имплементацей на чистом cairo:
    DT_LEFT, DT_CENTER, DT_RIGHT, DT_CALCRECT, DT_TOP, DT_VCENTER, DT_BOTTOM,
    DT_SINGLELINE, DT_HIDEPREFIX, DT_NOPREFIX, DT_NOCLIP, DT_EDITCONTROL,
    DT_WORDBREAK, DT_END_ELLIPSIS
*)
procedure CairoDrawText(ACanvas: TCanvas; const S: string; var R: TRect; AFlags: Cardinal);

// GetTextExtPoint & TextOut
function CairoTextGetLastVisible(ACanvas: TCanvas; const S: string; AMaxWidth: Integer): Integer;
procedure CairoTextOut(ACanvas: TCanvas; X, Y: Integer; AText: PChar; ALength: Integer; AClipRect: PRect = nil);
procedure CairoTextSize(ACanvas: TCanvas; const S: string; AWidth, AHeight: PInteger);

// Utilities
function cairo_create_context(DC: HDC): pcairo_t;
function cairo_create_surface(AData: PACLPixel32Array; AWidth, AHeight: LongInt): Pcairo_surface_t;
procedure cairo_set_source_color(ACairo: pcairo_t; const AColor: TAlphaColor); overload;
procedure cairo_set_source_color(ACairo: pcairo_t; const AColor: TACLPixel32); overload;
procedure cairo_set_source_color(ACairo: pcairo_t; const AColor: TCairoColor); overload;
implementation

uses
  ACL.Graphics.TextLayout;

const
  CairoTextStyleLines = [fsUnderline, fsStrikeOut];

type
  TFontAccess = class(TFont);
  TTextBlock = class(TACLTextLayoutBlockText);

  PCairoGlyphArray = ^TCairoGlyphArray;
  TCairoGlyphArray = array[0..0] of cairo_glyph_t;

  { TCairoTextLayoutMetrics }

  PCairoTextLayoutMetrics = ^TCairoTextLayoutMetrics;
  TCairoTextLayoutMetrics = packed record
    Capacity: Integer;
    Count: Integer;
    Glyphs: TCairoGlyphArray;
    class function Allocate(AGlyphCount: Integer): PCairoTextLayoutMetrics; static;
    procedure Assign(AGlyphs: pcairo_glyph_t; ACount: Integer);
  end;

  { TCairoTextLine }

  PCairoTextLine = ^TCairoTextLine;
  TCairoTextLine = record
    Glyphs: PCairoGlyphArray;
    GlyphCount: Integer;
    Width: Double;
    NextLine: PCairoTextLine;
    procedure Align(ARightBound: Integer; AAlignment: THorzRectAlign);
    procedure CalcMetrics(AFont: pcairo_scaled_font_t);
    function GetCount: Integer;
    function GetMaxWidth: Double;
    procedure Init(AGlyphs: PCairoGlyphArray; AIndex, ACount: Integer);
    procedure Push(AGlyphs: PCairoGlyphArray; AIndex, ACount: Integer);
    procedure Free;
  end;

  { TCairoMeasurer }

  TCairoMeasurer = class
  strict private
    class var FBitmap: TACLDib;
    class var FContext: Pcairo_t;
    class var FDefaultFontData: TFontData;
    class procedure InitDefaultFont;
  public
    class destructor Destroy;
    class function Context(ACanvas: TCanvas): Pcairo_t;
    class function DefaultFontName: string;
    class function DefaultFontSize: Integer;
  end;

  { TACLTextLayoutCairoRender }

  TACLTextLayoutCairoRender = class(TACLTextLayoutCanvasRender)
  strict private
    FFont: Pcairo_scaled_font_t;
    FFontColor: TCairoColor;
    FFontExtents: cairo_font_extents_t;
    FFontHasLines: Boolean;
    FFillColor: TCairoColor;
    FFillColorAssigned: Boolean;
    FHandle: Pcairo_t;
    FLineHeight: Integer;
    FOrigin: TPoint;
  public
    constructor Create(ACanvas: TCanvas); override;
    destructor Destroy; override;
    procedure GetMetrics(out ABaseline, ALineHeight, ASpaceWidth: Integer); override;
    procedure Measure(ABlock: TACLTextLayoutBlockText); override;
    procedure SetFill(AValue: TColor); override;
    procedure SetFont(AFont: TFont); override;
    procedure Shrink(ABlock: TACLTextLayoutBlockText; AMaxSize: Integer); override;
    procedure TextOut(ABlock: TACLTextLayoutBlockText; X, Y: Integer); override;
  end;

{$REGION ' Utilities '}

function Contains(const D: TLongWordDynArray; Index: LongWord): Boolean;
var
  I: Integer;
begin
  for I := Low(D) to High(D) do
  begin
    if D[I] = Index then
      Exit(True);
  end;
  Result := False;
end;

procedure OffsetGlyphs(AGlyphs: PCairoGlyphArray; ACount: Integer; ADeltaX, ADeltaY: Double);
var
  I: Integer;
begin
  for I := 0 to ACount - 1 do
    with AGlyphs^[I] do
    begin
      X := X + ADeltaX;
      Y := Y + ADeltaY;
    end;
end;

{$ENDREGION}

{$REGION ' Wrappers '}

function cairo_create_context(DC: HDC): pcairo_t;
begin
  Result := gdk_cairo_create(TGtkDeviceContext(DC).Drawable);
  if Result = nil then
    raise EGSCairoError.Create('Cannot create cairo context');
end;

function cairo_create_surface(AData: PACLPixel32Array; AWidth, AHeight: LongInt): Pcairo_surface_t;
begin
  Result := cairo_image_surface_create_for_data(
    PByte(AData), CAIRO_FORMAT_ARGB32, AWidth, AHeight, AWidth * 4);
end;

function cairo_set_clipping(ACairo: pcairo_t; ACanvas: TCanvas; const AOrigin: TPoint): Boolean;
var
  LRect: TRect;
  LRegion: HRGN;
  LRegionData: TACLRegionData;
  I: Integer;
begin
  Result := True;
  LRegion := CreateRectRgn(0, 0, 0, 0);
  try
    if GetClipRgn(ACanvas.Handle, LRegion) = 1 then
      case GetRgnBox(LRegion, @LRect) of
        SimpleRegion:
          begin
            cairo_rectangle(ACairo, LRect.Left, LRect.Top, LRect.Width, LRect.Height);
            cairo_clip(ACairo);
          end;

        ComplexRegion:
          begin
            LRegionData := TACLRegionData.CreateFromHandle(LRegion);
            try
              for I := 0 to LRegionData.Count - 1 do
              begin
                with LRegionData.Rects^[I] do
                  cairo_rectangle(ACairo, AOrigin.X + Left, AOrigin.Y + Top, Width, Height);
              end;
              cairo_clip(ACairo);
            finally
              LRegionData.Free;
            end;
          end;
      else
        Result := False;
      end;
  finally
    DeleteObject(LRegion);
  end;
end;

procedure cairo_set_dash(ACairo: pcairo_t; const ADashes: array of Double); overload;
begin
  cairo_set_dash(ACairo, @ADashes[0], Length(ADashes), 0);
end;

procedure cairo_set_font(ACairo: pcairo_t; AFont: TFont);
var
  LSlant: cairo_font_slant_t;
  LWeight: cairo_font_weight_t;
begin
  if fsItalic in AFont.Style then
    LSlant := CAIRO_FONT_SLANT_ITALIC
  else
    LSlant := CAIRO_FONT_SLANT_NORMAL;

  if fsBold in AFont.Style then
    LWeight := CAIRO_FONT_WEIGHT_BOLD
  else
    LWeight := CAIRO_FONT_WEIGHT_NORMAL;

  if AFont.IsDefault then
    cairo_select_font_face(ACairo, PChar(TCairoMeasurer.DefaultFontName), LSlant, LWeight)
  else
    cairo_select_font_face(ACairo, PChar(AFont.Name), LSlant, LWeight);

  if AFont.Height = 0 then
    cairo_set_font_size(ACairo, TCairoMeasurer.DefaultFontSize)
  else
    cairo_set_font_size(ACairo, Abs(AFont.Height));
end;

procedure cairo_set_source_color(ACairo: pcairo_t; const AColor: TAlphaColor);
begin
  cairo_set_source_rgba(ACairo, AColor.R / 255, AColor.G / 255, AColor.B / 255, AColor.A / 255);
end;

procedure cairo_set_source_color(ACairo: pcairo_t; const AColor: TACLPixel32);
begin
  cairo_set_source_rgba(ACairo, AColor.R / 255, AColor.G / 255, AColor.B / 255, AColor.A / 255);
end;

procedure cairo_set_source_color(ACairo: pcairo_t; const AColor: TCairoColor);
begin
  cairo_set_source_rgba(ACairo, AColor.R, AColor.G, AColor.B, AColor.A);
end;
{$ENDREGION}

{$REGION ' TextOut'}

procedure CairoDrawTextStyleLines(ACairo: Pcairo_t; AFontStyle: TFontStyles;
  X, Y, AWidth: Double; const AFontExtents: cairo_font_extents_t); overload;
var
  LThickness: Double;
begin
  if CairoTextStyleLines * AFontStyle <> [] then
  begin
    LThickness := Max(AFontExtents.height / 16, 1.0);
    if fsUnderline in AFontStyle then
      cairo_rectangle(ACairo, X, Y + AFontExtents.ascent + LThickness, AWidth, LThickness);
    if fsStrikeOut in AFontStyle then
      cairo_rectangle(ACairo, X, Y + Round(AFontExtents.height / 2) + LThickness, AWidth, LThickness);
    cairo_fill(ACairo);
  end;
end;

procedure CairoDrawTextStyleLines(ACairo: Pcairo_t; AFontStyle: TFontStyles;
  ALines: PCairoTextLine; const AFontExtents: cairo_font_extents_t); overload;
begin
  while ALines <> nil do
  begin
    if ALines.GlyphCount > 0 then
      CairoDrawTextStyleLines(ACairo, AFontStyle, ALines^.Glyphs^[0].X,
        ALines^.Glyphs^[0].Y - AFontExtents.height + AFontExtents.descent,
        ALines^.Width, AFontExtents);
    ALines := ALines^.NextLine;
  end;
end;

function CairoTextGetLastVisible(ACanvas: TCanvas; const S: string; AMaxWidth: Integer): Integer;
var
  LCairo: pcairo_t;
  LFont: pcairo_scaled_font_t;
  LGlyphCount: Integer;
  LGlyphs: PCairoGlyphArray;
  LTextExtents: cairo_text_extents_t;
begin
  LGlyphs := nil;
  LGlyphCount := 0;
  LCairo := TCairoMeasurer.Context(ACanvas);
  LFont := cairo_get_scaled_font(LCairo);
  cairo_scaled_font_text_to_glyphs(LFont, 0, 0,
    PChar(S), Length(S), @LGlyphs, @LGlyphCount, nil, nil, nil);
  if LGlyphs <> nil then
  try
    cairo_scaled_font_glyph_extents(LFont, @LGlyphs^[0], LGlyphCount, @LTextExtents);
    while (LGlyphCount > 0) and (LTextExtents.x_advance > AMaxWidth) do
    begin
      LTextExtents.x_advance := LGlyphs^[LGlyphCount - 1].x;
      Dec(LGlyphCount);
    end;
    Result := UTF8CodepointToByteIndex(PChar(S), Length(S), LGlyphCount);
  finally
    cairo_glyph_free(@LGlyphs^[0]);
  end;
end;

procedure CairoTextOut(ACanvas: TCanvas; X, Y: Integer;
  AText: PChar; ALength: Integer; AClipRect: PRect = nil);
var
  LCairo: pcairo_t;
  LOrigin: TPoint;
  LFont: pcairo_scaled_font_t;
  LFontExtents: cairo_font_extents_t;
  LTextExtents: cairo_text_extents_t;
  LGlyphCount: Integer;
  LGlyphs: pcairo_glyph_t;
begin
  GetWindowOrgEx(ACanvas.Handle, @LOrigin);
  Dec(X, LOrigin.X);
  Dec(Y, LOrigin.Y);

  LCairo := cairo_create_context(ACanvas.Handle);
  try
    if cairo_set_clipping(LCairo, ACanvas, LOrigin) then
    begin
      if AClipRect <> nil then
      begin
        cairo_rectangle(LCairo, AClipRect.Left - LOrigin.X,
          AClipRect.Top - LOrigin.Y, AClipRect.Width, AClipRect.Height);
        cairo_clip(LCairo);
      end;

      cairo_set_font(LCairo, ACanvas.Font);
      cairo_set_source_color(LCairo, TCairoColor.From(TFontAccess(ACanvas.Font).GetColor));

      LGlyphs := nil;
      LGlyphCount := 0;
      LFont := cairo_get_scaled_font(LCairo);
      cairo_scaled_font_extents(LFont, @LFontExtents);
      cairo_scaled_font_text_to_glyphs(LFont,
        X, Y + LFontExtents.height - LFontExtents.descent,
        AText, ALength, @LGlyphs, @LGlyphCount, nil, nil, nil);
      if LGlyphs <> nil then
      try
        cairo_scaled_font_glyph_extents(LFont, LGlyphs, LGlyphCount, @LTextExtents);
        cairo_show_glyphs(LCairo, LGlyphs, LGlyphCount);
        if CairoTextStyleLines * ACanvas.Font.Style <> [] then
          CairoDrawTextStyleLines(LCairo, ACanvas.Font.Style, X, Y, LTextExtents.x_advance, LFontExtents);
      finally
        cairo_glyph_free(LGlyphs);
      end;
    end;
  finally
    cairo_destroy(LCairo);
  end;
end;

procedure CairoTextSize(ACanvas: TCanvas; const S: string; AWidth, AHeight: PInteger);
var
  LCairo: pcairo_t;
  LFontExtents: cairo_font_extents_t;
  LTextExtents: cairo_text_extents_t;
begin
  LCairo := TCairoMeasurer.Context(ACanvas);
  if AHeight <> nil then
  begin
    cairo_font_extents(LCairo, @LFontExtents);
    AHeight^ := Round(LFontExtents.height);
  end;
  if AWidth <> nil then
  begin
    cairo_text_extents(LCairo, PChar(S), @LTextExtents);
    AWidth^ := Round(LTextExtents.width);
  end;
end;

{$ENDREGION}

{$REGION ' DrawText '}

function CairoCalculateTextLayout(AFont: Pcairo_scaled_font_t;
  ALines: PCairoTextLine; const ARect: TRect; AFlags: Cardinal): Integer;
const
  LineBreaks = #13#10;
  WordBreaks = LineBreaks + #9' ';

  procedure InitDelimiters(out D: TLongWordDynArray;
    const S: string; AExtents: Pcairo_text_extents_t = nil);
  var
    I: Integer;
    LGlyphCount: Integer;
    LGlyphs: PCairoGlyphArray;
  begin
    D := nil;
    LGlyphs := nil;
    LGlyphCount := 0;
    cairo_scaled_font_text_to_glyphs(AFont, 0, 0,
      PChar(S), Length(S), @LGlyphs, @LGlyphCount, nil, nil, nil);
    if LGlyphs <> nil then
    try
      SetLength(D{%H-}, LGlyphCount);
      for I := 0 to LGlyphCount - 1 do
        D[I] := LGlyphs^[I].index;
      if AExtents <> nil then
        cairo_scaled_font_glyph_extents(AFont, @LGlyphs^[0], LGlyphCount, AExtents);
    finally
      cairo_glyph_free(@LGlyphs^[0]);
    end;
  end;

var
  I, J: Integer;
  LDeltaY: Double;
  LGlyphCount: Integer;
  LGlyphs: PCairoGlyphArray;
  LGlyphWidth: Double;
  LGlyphWidths: TDoubleDynArray;
  LEndEllipsis: TLongWordDynArray;
  LFontExtents: cairo_font_extents_t;
  LTextExtents: cairo_text_extents_t;
  LLineScan: PCairoTextLine;
  LLineStart: Integer;
  LLineBreaks: TLongWordDynArray;
  LWordBreaks: TLongWordDynArray;
  LOffsetX, LOffsetY: Double;
  LHeight: Double;
  LWidth: Double;
begin
  LGlyphs := ALines^.Glyphs;
  LGlyphCount := ALines^.GlyphCount;
  cairo_scaled_font_extents(AFont, @LFontExtents);

  // Считаем лейаут
  if AFlags and DT_SINGLELINE = 0 then
  begin
    LOffsetX := 0;
    LOffsetY := 0;
    LGlyphWidth := 0;
    InitDelimiters(LLineBreaks, LineBreaks);
    // В этом режиме мы переносим строки только по LDelimitersHardBreak
    if AFlags and DT_WORDBREAK = 0 then
    begin
      for I := 0 to LGlyphCount - 1 do
      begin
        if I + 1 < LGlyphCount then
          LGlyphWidth := LGlyphs^[I + 1].X - LGlyphs^[I].X;
        LGlyphs^[I].X := LOffsetX;
        LGlyphs^[I].Y := LOffsetY;
        LOffsetX := LOffsetX + LGlyphWidth;
        if Contains(LLineBreaks, LGlyphs^[I].Index) then
        begin
          ALines.Push(LGlyphs, I + 1, LGlyphCount);
          LOffsetY := LOffsetY + LFontExtents.height;
          LOffsetX := 0;
        end;
      end;
    end
    else // Wordbreak
    begin
      SetLength(LGlyphWidths{%H-}, LGlyphCount);
      for I := 0 to LGlyphCount - 2 do
        LGlyphWidths[I] := LGlyphs^[I + 1].X - LGlyphs^[I].X;
      cairo_scaled_font_glyph_extents(AFont, @LGlyphs^[LGlyphCount - 1], 1, @LTextExtents);
      LGlyphWidths[LGlyphCount - 1] := LTextExtents.x_advance;

      I := 0;
      LLineStart := 0;
      LWidth := ARect.Width;
      InitDelimiters(LWordBreaks, WordBreaks);
      while I < LGlyphCount do
      begin
        // слово не влезает - откатываемся к ближайшему разделителю
        if LOffsetX + LGlyphWidths[I] > LWidth then
        begin
          J := I;
          while (J > LLineStart) and not Contains(LWordBreaks, LGlyphs^[J].Index) do
            Dec(J);
          // Если в текущей строке не нашлось ни одного разделителя -
          // оставляем "как есть". В противном случае - переносим строку.
          if J > LLineStart then
          begin
            LLineStart := J + 1;
            ALines.Push(LGlyphs, LLineStart, LGlyphCount);
            LOffsetY := LOffsetY + LFontExtents.height;
            LOffsetX := 0;
            I := LLineStart;
            Continue;
          end;
        end;

        LGlyphs^[I].X := LOffsetX;
        LGlyphs^[I].Y := LOffsetY;
        LOffsetX := LOffsetX + LGlyphWidths[I];
        if Contains(LLineBreaks, LGlyphs^[I].Index) then
        begin
          LLineStart := I + 1;
          ALines.Push(LGlyphs, LLineStart, LGlyphCount);
          LOffsetY := LOffsetY + LFontExtents.height;
          LOffsetX := 0;
        end;
        Inc(I);
      end;
    end;
  end;

  // EndEllipsis
  if AFlags and DT_END_ELLIPSIS <> 0 then
  begin
    // Считаем метрики
    ALines.CalcMetrics(AFont);
    // Ищем последнюю видимую строку
    LLineScan := ALines;
    LHeight := ARect.Height;
    // В случае DT_EDITCONTROL - нам нужна последняя полностью видимая строка!
    LOffsetY := IfThen(AFlags and DT_EDITCONTROL <> 0, LFontExtents.height, 0);
    while LHeight > LOffsetY do
    begin
      LHeight := LHeight - LFontExtents.height;
      if (LHeight > LOffsetY) and (LLineScan.NextLine <> nil) then
        LLineScan := LLineScan.NextLine
      else
        Break;
    end;
    // Текст-то обрезан у нас?
    if (LLineScan^.NextLine <> nil) or // не все строки влезли
       (LLineScan^.Width > ARect.Width) then
    begin
      // Инициализируем '...'
      InitDelimiters(LEndEllipsis, '.', @LTextExtents);
      LWidth := ARect.Width - 3 * LTextExtents.x_advance;
      // Теперь ищем позицию по x, куда можно вставить '...'
      I := LLineScan^.GlyphCount - 1;
      // Вот тут интересно: если мы не в самом конце строки - не смещаем индекс,
      // чтобы заюзать неиспользуемые глифы из следующей строки.
      if LLineScan^.NextLine = nil then
        Dec(I, 2);
      while I >= 0 do
      begin
        if (LLineScan^.Glyphs^[I].X <= LWidth) or (I = 0) then
        begin
          // Подменяем имеющиеся глифы на глиф точки
          LLineScan^.Glyphs^[I + 0].index := LEndEllipsis[0];
          LLineScan^.Glyphs^[I + 1].index := LEndEllipsis[0];
          LLineScan^.Glyphs^[I + 2].index := LEndEllipsis[0];
          LLineScan^.Glyphs^[I + 1].x := LLineScan^.Glyphs^[I + 0].x + LTextExtents.x_advance;
          LLineScan^.Glyphs^[I + 2].x := LLineScan^.Glyphs^[I + 1].x + LTextExtents.x_advance;
          LLineScan^.Glyphs^[I + 1].y := LLineScan^.Glyphs^[I].y;
          LLineScan^.Glyphs^[I + 2].y := LLineScan^.Glyphs^[I].y;
          LLineScan^.GlyphCount := I + 3;
          // Усекаем лейаут по текущей строке (последующие строки будут освобождены)
          LLineScan^.Free;
          // Мы уже учли DT_EDITCONTROL - нет смысла делать работу еще раз
          AFlags := AFlags and not DT_EDITCONTROL;
          // Обновляем количество символов для вывода
          LGlyphCount := (LLineScan^.Glyphs - LGlyphs) + LLineScan^.GlyphCount;
          Break;
        end;
        Dec(I);
      end;
    end;
  end;

  // Считаем метрики
  ALines.CalcMetrics(AFont);

  // Позиционирование
  if AFlags and DT_CALCRECT = 0 then
  begin
    // DT_EDITCONTROL - скрываем частично видимые строки
    if AFlags and DT_EDITCONTROL <> 0 then
    begin
      LHeight := 0;
      LLineScan := ALines;
      LGlyphCount := 0;
      while (LLineScan <> nil) and (LHeight + LFontExtents.height <= ARect.Height) do
      begin
        Inc(LGlyphCount, LLineScan^.GlyphCount);
        LHeight := LHeight + LFontExtents.height;
        LLineScan := LLineScan.NextLine;
      end;
    end
    else
      LHeight := ALines.GetCount * LFontExtents.height;

    // Выравнивание по горизонтали
    if AFlags and DT_CENTER <> 0 then
      ALines.Align(ARect.Width, THorzRectAlign.Center)
    else if AFlags and DT_RIGHT <> 0 then
      ALines.Align(ARect.Width, THorzRectAlign.Right);

    // Выравнивание по вертикали
    if AFlags and DT_VCENTER <> 0 then
      LDeltaY := (ARect.Top + ARect.Bottom - LHeight) / 2
    else if AFlags and DT_BOTTOM <> 0 then
      LDeltaY := ARect.Bottom - LHeight
    else
      LDeltaY := ARect.Top;

    OffsetGlyphs(LGlyphs, LGlyphCount, ARect.Left,
      LDeltaY + LFontExtents.height - LFontExtents.descent);
  end;
  Result := LGlyphCount;
end;

procedure CairoDrawTextCore(ACanvas: TCanvas;
  const S: string; var R: TRect; AFlags: Cardinal);
var
  LCairo: Pcairo_t;
  LFont: Pcairo_scaled_font_t;
  LFontExtents: cairo_font_extents_t;
  LGlyphCount: Integer;
  LGlyphs: PCairoGlyphArray;
  LLines: TCairoTextLine;
  LOrigin: TPoint;
  LRect: TRect;
begin
  LCairo := cairo_create_context(ACanvas.Handle);
  try
    cairo_set_font(LCairo, ACanvas.Font);

    LGlyphs := nil;
    LGlyphCount:= 0;
    LFont := cairo_get_scaled_font(LCairo);
    cairo_scaled_font_text_to_glyphs(LFont, 0, 0,
      PChar(S), Length(S), @LGlyphs, @LGlyphCount, nil, nil, nil);
    if LGlyphs <> nil then
    try
      cairo_scaled_font_extents(LFont, @LFontExtents);
      if AFlags and DT_CALCRECT <> 0 then
      begin
        LLines.Init(LGlyphs, 0, LGlyphCount);
        try
          CairoCalculateTextLayout(LFont, @LLines, R, AFlags);
          R.Height := Ceil(LLines.GetCount * LFontExtents.height);
          R.Width := Ceil(LLines.GetMaxWidth);
        finally
          LLines.Free;
        end;
      end
      else
      begin
        GetWindowOrgEx(ACanvas.Handle, @LOrigin);
        if cairo_set_clipping(LCairo, ACanvas, LOrigin) then
        begin
          LRect := R;
          LRect.Offset(-LOrigin.X, -LOrigin.Y);
          LLines.Init(LGlyphs, 0, LGlyphCount);
          try
            CairoCalculateTextLayout(LFont, @LLines, LRect, AFlags);
            cairo_set_source_color(LCairo, TCairoColor.From(TFontAccess(ACanvas.Font).GetColor));
            if AFlags and DT_NOCLIP = 0 then
            begin
              cairo_rectangle(LCairo, LRect.Left, LRect.Top, LRect.Width, LRect.Height);
              cairo_clip(LCairo);
            end;
            cairo_show_glyphs(LCairo, @LGlyphs^[0], LGlyphCount);
            if CairoTextStyleLines * ACanvas.Font.Style <> [] then
              CairoDrawTextStyleLines(LCairo, ACanvas.Font.Style, @LLines, LFontExtents);
          finally
            LLines.Free;
          end;
        end;
      end;
    finally
      cairo_glyph_free(@LGlyphs^[0]);
    end;
  finally
    cairo_destroy(LCairo);
  end;
end;

procedure CairoDrawText(ACanvas: TCanvas; const S: string; var R: TRect; AFlags: Cardinal);
var
  LText: string;
begin
  if S = '' then
    Exit;

  LText := S;
  if AFlags and DT_NOPREFIX = 0 then
  begin
    if AFlags and DT_HIDEPREFIX <> 0 then
      acExpandPrefixes(LText, True)
    else
      // Может просто DT_NOPREFIX забыли?
      if LText.Contains('&') then
      begin
        acAdvDrawText(ACanvas, S, R, AFlags);
        Exit;
      end;
  end;

  CairoDrawTextCore(ACanvas, LText, R, AFlags);
end;

{$ENDREGION}

{ TCairoColor }

class function TCairoColor.From(A, R, G, B: Byte): TCairoColor;
begin
  Result.R := R / 255;
  Result.G := G / 255;
  Result.B := B / 255;
  Result.A := A / 255;
end;

class function TCairoColor.From(Color: TAlphaColor): TCairoColor;
begin
  Result := From(Color.A, Color.R, Color.G, Color.B);
end;

class function TCairoColor.From(Color: TColor): TCairoColor;
begin
  Color := ColorToRGB(Color);
  Result := From(255, GetRValue(Color), GetGValue(Color), GetBValue(Color));
end;

{ TCairoCanvas }

procedure TCairoCanvas.BeginPaint(ACanvas: TCanvas);
begin
  if FHandle <> nil then
    raise EInvalidGraphicOperation.Create(ClassName + ' recursive calls not yet supported');

  // Если DC у DIB-а уже захвачен - рисуем на нем, не переключаемся.
  // Иначе запрос Bits спровоцирует отключение канваса и следующий за нами
  // вызов уже получит канвас без Handle-а и не сможет получить валидный WindowOrg
  if not ACanvas.HandleAllocated and (ACanvas is TACLDibCanvas) then
  begin
    FTargetSurface := cairo_create_surface(
      TACLDibCanvas(ACanvas).Owner.Colors,
      TACLDibCanvas(ACanvas).Owner.Width,
      TACLDibCanvas(ACanvas).Owner.Height);
    FHandle := cairo_create(FTargetSurface);
    FOrigin := NullPoint;
  end
  else
  begin
    GetWindowOrgEx(ACanvas.Handle, {%H-}FOrigin);
    FHandle := cairo_create_context(ACanvas.Handle);
  end;

  cairo_set_clipping(Handle, ACanvas, FOrigin);
end;

procedure TCairoCanvas.EndPaint;
begin
  if FHandle <> nil then
  try
    cairo_destroy(FHandle);
    if FTargetSurface <> nil then
      cairo_surface_destroy(FTargetSurface);
    FTargetSurface := nil;
  finally
    FHandle := nil;
  end;
end;

procedure TCairoCanvas.FillRectangle(X1, Y1, X2, Y2: Single; Color: TAlphaColor);
begin
  if (X2 > X1) and (Y2 > Y1) then
  begin
    cairo_set_source_color(Handle, Color);
    cairo_rectangle(Handle, X1 - Origin.X, Y1 - Origin.Y, X2 - X1, Y2 - Y1);
    cairo_fill(Handle);
  end;
end;

procedure TCairoCanvas.FillRectangleByGradient(
  AFrom, ATo: TAlphaColor; const ARect: TRect; AVertical: Boolean);
var
  LPattern: Pcairo_pattern_t;
begin
  if AVertical then
    LPattern := cairo_pattern_create_linear(0, ARect.Top - Origin.Y, 0, ARect.Bottom - Origin.Y)
  else
    LPattern := cairo_pattern_create_linear(ARect.Left - Origin.X, 0, ARect.Right - Origin.X, 0);

  with TCairoColor.From(AFrom) do
    cairo_pattern_add_color_stop_rgba(LPattern, 0.0, R, G, B, A);
  with TCairoColor.From(ATo) do
    cairo_pattern_add_color_stop_rgba(LPattern, 1.0, R, G, B, A);

  cairo_rectangle(Handle, ARect.Left - Origin.X,
    ARect.Top - Origin.Y, ARect.Width, ARect.Height);
  cairo_set_source(Handle, LPattern);
  cairo_fill(Handle);

  cairo_pattern_destroy(LPattern);
end;

procedure TCairoCanvas.FillSurface(const ATargetRect, ASourceRect: TRect;
  ASurface: Pcairo_surface_t; AAlpha: Double; ATileMode: Boolean);
var
  LCairo: Pcairo_t;
  LMatrix: cairo_matrix_t;
  LSurface: Pcairo_surface_t;
  LSourceW, LSourceH: LongInt;
  LTargetW, LTargetH: Double;
  X, Y: Double;
begin
  LSourceH := ASourceRect.Height;
  LSourceW := ASourceRect.Width;
  LTargetH := ATargetRect.Height;
  LTargetW := ATargetRect.Width;
  X := ATargetRect.Left - Origin.X;
  Y := ATargetRect.Top - Origin.Y;

  if ATileMode then
  begin
    LSurface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, LSourceW, LSourceH);

    LCairo := cairo_create(LSurface);
    cairo_set_source_surface(LCairo, ASurface, -ASourceRect.Left, -ASourceRect.Top);
    cairo_rectangle(LCairo, 0, 0, LSourceW, LSourceH);
    cairo_paint_with_alpha(LCairo, AAlpha);
    cairo_destroy(LCairo);

    cairo_set_source_surface(Handle, LSurface, X, Y);
    cairo_pattern_set_extend(cairo_get_source(Handle), CAIRO_EXTEND_REPEAT);
    cairo_rectangle(Handle, X, Y, LTargetW, LTargetH);
    cairo_fill(Handle);
    cairo_surface_destroy(LSurface);
  end
  else
  begin
    cairo_set_source_surface(Handle, ASurface, 0, 0);
    cairo_matrix_init_identity(@LMatrix);
    cairo_matrix_translate(@LMatrix, ASourceRect.Left, ASourceRect.Top);
    cairo_matrix_scale(@LMatrix, LSourceW / LTargetW, LSourceH / LTargetH);
    cairo_matrix_translate(@LMatrix, -X, -Y);
    cairo_pattern_set_matrix(cairo_get_source(Handle), @LMatrix);
    cairo_pattern_set_filter(cairo_get_source(Handle), CAIRO_FILTER_NEAREST);
    cairo_rectangle(Handle, X, Y, LTargetW, LTargetH);
    if AAlpha < 1.0 then
    begin
      cairo_save(Handle);
      cairo_clip(Handle);
      cairo_paint_with_alpha(Handle, 1.0);
      cairo_restore(Handle);
    end
    else
      cairo_fill(Handle);
  end;
end;

procedure TCairoCanvas.Line(X1, Y1, X2, Y2: Single;
  Color: TAlphaColor; Width: Single; Style: TACL2DRenderStrokeStyle);
begin
  SetLineStyle(Width, Style);
  cairo_set_source_color(FHandle, Color);
  cairo_set_line_width(FHandle, Width);
  cairo_move_to(FHandle, X1 - Origin.X, Y1 - Origin.Y);
  cairo_line_to(FHandle, X2 - Origin.X, Y2 - Origin.Y);
  cairo_stroke(FHandle);
end;

procedure TCairoCanvas.SetLineStyle(AWidth: Single; AStyle: TACL2DRenderStrokeStyle);
begin
  case AStyle of
    ssDashDotDot:
      cairo_set_dash(FHandle, [4 * AWidth, AWidth, AWidth, AWidth, AWidth, AWidth]);
    ssDashDot:
      cairo_set_dash(FHandle, [4 * AWidth, AWidth, AWidth, AWidth]);
    ssDash:
      cairo_set_dash(FHandle, [4 * AWidth, AWidth]);
    ssDot:
      cairo_set_dash(FHandle, [AWidth]);
  else
    cairo_set_dash(FHandle, nil, 0, 0);
  end;
end;

{ TCairoTextLine }

procedure TCairoTextLine.Align(ARightBound: Integer; AAlignment: THorzRectAlign);
var
  LDeltaX: Double;
begin
  if GlyphCount > 0 then
  begin
    if AAlignment = THorzRectAlign.Center then
      LDeltaX := (ARightBound - (Glyphs^[0].x * 2 + Width)) / 2
    else if AAlignment = THorzRectAlign.Right then
      LDeltaX := (ARightBound - (Glyphs^[0].x + Width))
    else
      LDeltaX := -Glyphs^[0].x;

    OffsetGlyphs(Glyphs, GlyphCount, LDeltaX, 0);
  end;
  if NextLine <> nil then
    NextLine^.Align(ARightBound, AAlignment);
end;

procedure TCairoTextLine.CalcMetrics(AFont: pcairo_scaled_font_t);
var
  LExtents: cairo_text_extents_t;
begin
  if GlyphCount > 0 then
  begin
    cairo_scaled_font_glyph_extents(AFont, @Glyphs^[GlyphCount - 1], 1, @LExtents);
    Width := LExtents.x_advance + Glyphs^[GlyphCount - 1].x - Glyphs^[0].x;
  end
  else
    Width := 0;

  if NextLine <> nil then
    NextLine^.CalcMetrics(AFont);
end;

function TCairoTextLine.GetCount: Integer;
begin
  Result := 1;
  if NextLine <> nil then
    Inc(Result, NextLine^.GetCount);
end;

procedure TCairoTextLine.Free;
begin
  if NextLine <> nil then
  begin
    NextLine^.Free;
    Dispose(NextLine);
    NextLine := nil;
  end;
end;

function TCairoTextLine.GetMaxWidth: Double;
begin
  Result := Width;
  if NextLine <> nil then
    Result := Max(Result, NextLine^.GetMaxWidth);
end;

procedure TCairoTextLine.Init(AGlyphs: PCairoGlyphArray; AIndex, ACount: Integer);
begin
  Glyphs := @AGlyphs[AIndex];
  GlyphCount := ACount - AIndex;
  NextLine := nil;
  Width := -1;
end;

procedure TCairoTextLine.Push(AGlyphs: PCairoGlyphArray; AIndex, ACount: Integer);
var
  LCurr: PCairoTextLine;
begin
  LCurr := @Self;
  while LCurr^.NextLine <> nil do
    LCurr := LCurr^.NextLine;
  New(LCurr^.NextLine);
  LCurr^.NextLine^.Init(AGlyphs, AIndex, ACount);
  LCurr^.GlyphCount := LCurr^.NextLine^.Glyphs - LCurr^.Glyphs;
end;

{ TCairoMeasurer }

class destructor TCairoMeasurer.Destroy;
begin
  if FContext <> nil then
  begin
    cairo_destroy(FContext);
    FContext := nil;
  end;
  FreeAndNil(FBitmap);
end;

class function TCairoMeasurer.Context(ACanvas: TCanvas): Pcairo_t;
begin
  if FBitmap = nil then
  begin
    FBitmap := TACLDib.Create(1, 1);
    FBitmap.Canvas.Font := ACanvas.Font;
    FContext := cairo_create_context(FBitmap.Canvas.Handle);
    cairo_set_font(FContext, ACanvas.Font);
  end
  else
    if FBitmap.Canvas.Font.Handle <> ACanvas.Font.Handle then
    //if not ACanvas.Font.IsEqual(FBitmap.Canvas.Font) then
    begin
      FBitmap.Canvas.Font := ACanvas.Font;
      cairo_set_font(FContext, ACanvas.Font);
    end;

  Result := FContext;
end;

class function TCairoMeasurer.DefaultFontName: string;
begin
  if FDefaultFontData.Name = '' then
    InitDefaultFont;
  Result := FDefaultFontData.Name;
end;

class function TCairoMeasurer.DefaultFontSize: Integer;
begin
  if FDefaultFontData.Height = 0 then
    InitDefaultFont;
  Result := FDefaultFontData.Height;
end;

class procedure TCairoMeasurer.InitDefaultFont;
begin
  FDefaultFontData := GetFontData(GetStockObject(DEFAULT_GUI_FONT));
end;

{ TCairoTextLayoutMetrics }

class function TCairoTextLayoutMetrics.Allocate(AGlyphCount: Integer): PCairoTextLayoutMetrics;
begin
  Result := AllocMem(SizeOf(TCairoTextLayoutMetrics) + AGlyphCount * SizeOf(cairo_glyph_t));
  Result^.Capacity := AGlyphCount;
  Result^.Count := 0;
end;

procedure TCairoTextLayoutMetrics.Assign(AGlyphs: pcairo_glyph_t; ACount: Integer);
begin
  if ACount > Capacity then
    raise EInvalidArgument.CreateFmt('TCairoTextLayoutMetrics.Assign capacity exceeded (%d -> %d)', [ACount, Capacity]);
  Count := ACount;
  Move(AGlyphs^, Glyphs[0], ACount * SizeOf(cairo_glyph_t));
end;

{ TACLTextLayoutCairoRender }

constructor TACLTextLayoutCairoRender.Create(ACanvas: TCanvas);
begin
  inherited Create(ACanvas);
  FHandle := cairo_create_context(ACanvas.Handle);
  GetWindowOrgEx(Canvas.Handle, @FOrigin);
  cairo_set_clipping(FHandle, Canvas, FOrigin);
end;

destructor TACLTextLayoutCairoRender.Destroy;
begin
  cairo_destroy(FHandle);
  inherited Destroy;
end;

procedure TACLTextLayoutCairoRender.GetMetrics(
  out ABaseline, ALineHeight, ASpaceWidth: Integer);
var
  LTextExtents: cairo_text_extents_t;
begin
  cairo_text_extents(FHandle, ' ', @LTextExtents);
  ASpaceWidth := Round(LTextExtents.x_advance);
  ALineHeight := Round(FFontExtents.height);
  ABaseLine := Round(FFontExtents.height - FFontExtents.descent);
  FLineHeight := ALineHeight;
end;

procedure TACLTextLayoutCairoRender.Measure(ABlock: TACLTextLayoutBlockText);
var
  LBlock: TTextBlock absolute ABlock;
  LExtents: cairo_text_extents_t;
  LGlyphCount: Integer;
  LGlyphs: Pcairo_glyph_t;
begin
  LGlyphs := nil;
  LGlyphCount := 0;
  LBlock.FLengthVisible := 0;
  cairo_scaled_font_text_to_glyphs(FFont, 0, 0,
    LBlock.Text, LBlock.TextLength, @LGlyphs, @LGlyphCount, nil, nil, nil);
  if LGlyphs <> nil then
  try
    if LBlock.FMetrics = nil then
      LBlock.FMetrics := TCairoTextLayoutMetrics.Allocate(LGlyphCount);
    PCairoTextLayoutMetrics(LBlock.FMetrics).Assign(LGlyphs, LGlyphCount);
    cairo_scaled_font_glyph_extents(FFont, LGlyphs, LGlyphCount, @LExtents);
    LBlock.FLengthVisible := LBlock.TextLength;
    LBlock.FWidth := Round(LExtents.x_advance);
    LBlock.FHeight := FLineHeight;
  finally
    cairo_glyph_free(LGlyphs);
  end;
end;

procedure TACLTextLayoutCairoRender.SetFill(AValue: TColor);
begin
  FFillColor := TCairoColor.From(AValue);
  FFillColorAssigned := AValue <> clNone;
end;

procedure TACLTextLayoutCairoRender.SetFont(AFont: TFont);
begin
  Canvas.Font := AFont; // иначе TFont.GetColor не сработает
  cairo_set_font(FHandle, AFont);
  FFontColor := TCairoColor.From(TFontAccess(Canvas.Font).GetColor);
  cairo_set_source_color(FHandle, FFontColor);
  FFont := cairo_get_scaled_font(FHandle);
  cairo_scaled_font_extents(FFont, @FFontExtents);
  FFontHasLines := CairoTextStyleLines * AFont.Style <> [];
  FLineHeight := Round(FFontExtents.height);
end;

procedure TACLTextLayoutCairoRender.Shrink(
  ABlock: TACLTextLayoutBlockText; AMaxSize: Integer);
var
  LBlock: TTextBlock absolute ABlock;
  LGlyph: Pcairo_glyph_t;
  LMetrics: PCairoTextLayoutMetrics;
  LWidth: Double;
begin
  LMetrics := PCairoTextLayoutMetrics(LBlock.FMetrics);
  LGlyph := @LMetrics^.Glyphs[LMetrics^.Count - 1];
  LWidth := LBlock.FWidth;
  while LMetrics^.Count > 0 do
  begin
    LWidth := LGlyph^.x;
    Dec(LMetrics^.Count);
    if LWidth <= AMaxSize then Break;
    Dec(LGlyph);
  end;
  LBlock.FWidth := Round(LWidth);
  LBlock.FLengthVisible := UTF8CodepointToByteIndex(LBlock.Text, LBlock.TextLength, LMetrics^.Count);
end;

procedure TACLTextLayoutCairoRender.TextOut(ABlock: TACLTextLayoutBlockText; X, Y: Integer);
var
  LBlock: TTextBlock absolute ABlock;
  LMetrics: PCairoTextLayoutMetrics;
  LOffsetY: Double;
begin
  LMetrics := PCairoTextLayoutMetrics(LBlock.FMetrics);
  if (LMetrics <> nil) and (LMetrics^.Count > 0) then
  begin
    Dec(X, FOrigin.X);
    Dec(Y, FOrigin.Y);

    if FFillColorAssigned then
    begin
      cairo_set_source_color(FHandle, FFillColor);
      cairo_rectangle(FHandle, X, Y, LBlock.TextWidth, LBlock.TextHeight);
      cairo_fill(FHandle);
      cairo_set_source_color(FHandle, FFontColor);
    end;

    LOffsetY := Y + FFontExtents.height - FFontExtents.descent;
    OffsetGlyphs(@LMetrics^.Glyphs[0], LMetrics^.Count,  X,  LOffsetY);
    cairo_show_glyphs(FHandle, @LMetrics^.Glyphs[0], LMetrics^.Count);
    OffsetGlyphs(@LMetrics^.Glyphs[0], LMetrics^.Count, -X, -LOffsetY);

    if FFontHasLines then
      CairoDrawTextStyleLines(FHandle, Canvas.Font.Style, X, Y, ABlock.TextWidth, FFontExtents);
  end;
end;

initialization
  GpPaintCanvas := TCairoCanvas.Create;
{$IFDEF ACL_CAIRO_TEXTOUT}
  DefaultTextLayoutCanvasRender := TACLTextLayoutCairoRender;
{$ENDIF}

finalization
  FreeAndNil(GpPaintCanvas);
end.
