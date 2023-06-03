{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*               Color Palette               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.ColorPalette;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.Types,
  System.Classes,
  System.UITypes,
  // Vcl
  Vcl.Graphics,
  // ACL
  ACL.Classes.Collections,
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex.Gdip,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Resources,
  ACL.Utils.DPIAware;

type
  TACLColorPalette = class;
  TACLColorPaletteOptionsView = class;
  TACLColorPaletteViewInfo = class;

  TACLColorPaletteStyle = (cpsOffice, cpsClassic);

  { TACLColorPaletteItem }

  TACLColorPaletteItem = class(TCollectionItem)
  strict private
    FColor: TAlphaColor;

    procedure SetColor(AValue: TAlphaColor);
  public
    procedure AfterConstruction; override;
    procedure Assign(Source: TPersistent); override;
  published
    property Color: TAlphaColor read FColor write SetColor default 0;
  end;

  { TACLColorPaletteItems }

  TACLColorPaletteItems = class(TCollection)
  strict private
    FOwner: TACLColorPalette;

    function GetItem(Index: Integer): TACLColorPaletteItem;
  protected
    procedure PopulateClassicColors;
    procedure PopulateOfficeColors;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TACLColorPalette); reintroduce;
    function Add(AColor: TAlphaColor): TACLColorPaletteItem;
    procedure Populate(AStyle: TACLColorPaletteStyle);
    //
    property Items[Index: Integer]: TACLColorPaletteItem read GetItem; default;
  end;

  { TACLColorPaletteItemViewInfo }

  TACLColorPaletteItemViewInfo = class
  strict private
    FBorders: TACLBorders;
    FBounds: TRect;
    FColor: TAlphaColor;
    FViewInfo: TACLColorPaletteViewInfo;

    function GetPalette: TACLColorPalette;
    function GetSelected: Boolean;
  public
    constructor Create(AViewInfo: TACLColorPaletteViewInfo;
      AColor: TAlphaColor; const ABounds: TRect; ABorders: TACLBorders = acAllBorders);
    procedure Draw(ACanvas: TCanvas);
    //
    property Borders: TACLBorders read FBorders write FBorders;
    property Bounds: TRect read FBounds;
    property Color: TAlphaColor read FColor;
    property Palette: TACLColorPalette read GetPalette;
    property Selected: Boolean read GetSelected;
    property ViewInfo: TACLColorPaletteViewInfo read FViewInfo;
  end;

  { TACLColorPaletteViewInfo }

  TACLColorPaletteViewInfo = class
  strict private const
    BorderSize = 2;
  strict private
    FCells: TACLObjectList<TACLColorPaletteItemViewInfo>;
    FHeight: Integer;
    FOwner: TACLColorPalette;
    FWidth: Integer;

    function AdjustColor(AColor: TAlphaColor; ALightness: Single): TAlphaColor;
    function GetCurrentDpi: Integer;
    function GetItems: TACLColorPaletteItems;
    function GetOptions: TACLColorPaletteOptionsView;
  protected
    function CalculateCellSpacing(ACellSize, AWidth: Integer): Integer;
    procedure CalculateClassicLayout(ABounds: TRect);
    procedure CalculateOfficeLikeLayout(ABounds: TRect);
  public
    constructor Create(AOwner: TACLColorPalette);
    destructor Destroy; override;
    procedure Calculate(const ABounds: TRect);
    procedure Draw(ACanvas: TCanvas);
    function HitTest(const P: TPoint): TACLColorPaletteItemViewInfo;
    //
    property CurrentDpi: Integer read GetCurrentDpi;
    property Height: Integer read FHeight;
    property Items: TACLColorPaletteItems read GetItems;
    property Options: TACLColorPaletteOptionsView read GetOptions;
    property Owner: TACLColorPalette read FOwner;
    property Width: Integer read FWidth;
  end;

  { TACLStyleColorPalette }

  TACLStyleColorPalette = class(TACLStyle)
  protected
    procedure InitializeResources; override;
  public
    procedure DrawFrame(ACanvas: TCanvas; const R: TRect; ASelected: Boolean; ABorders: TACLBorders);
    procedure DrawHatch(ACanvas: TCanvas; const R: TRect);
  published
    property ColorBorder1: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorBorder2: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorHatch1: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorHatch2: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
    property ColorSelectedBorder1: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
    property ColorSelectedBorder2: TACLResourceColor index 5 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLColorPaletteOptionsView }

  TACLColorPaletteOptionsView = class(TACLCustomOptionsPersistent)
  strict private
    FCellSize: Integer;
    FCellSpacing: Integer;
    FOwner: TACLColorPalette;
    FStyle: TACLColorPaletteStyle;
    FStyleOfficeTintCount: Integer;

    procedure SetCellSize(AValue: Integer);
    procedure SetCellSpacing(AValue: Integer);
    procedure SetStyle(AValue: TACLColorPaletteStyle);
    procedure SetStyleOfficeTintCount(AValue: Integer);
  protected
    procedure DoAssign(Source: TPersistent); override;
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
  public
    constructor Create(AOwner: TACLColorPalette);
  published
    property CellSize: Integer read FCellSize write SetCellSize default 16;
    property CellSpacing: Integer read FCellSpacing write SetCellSpacing default -1;
    property Style: TACLColorPaletteStyle read FStyle write SetStyle default cpsOffice;
    property StyleOfficeTintCount: Integer read FStyleOfficeTintCount write SetStyleOfficeTintCount default 5;
  end;

  { TACLColorPalette }

  TACLColorPalette = class(TACLCustomControl)
  strict private
    FColor: TAlphaColor;
    FHoveredColor: TACLColorPaletteItemViewInfo;
    FItems: TACLColorPaletteItems;
    FOptionsView: TACLColorPaletteOptionsView;
    FStyle: TACLStyleColorPalette;
    FViewInfo: TACLColorPaletteViewInfo;

    FOnColorChanged: TNotifyEvent;

    procedure SetColor(AValue: TAlphaColor);
    procedure SetHoveredColor(AValue: TACLColorPaletteItemViewInfo);
    procedure SetItems(AValue: TACLColorPaletteItems);
    procedure SetOptionsView(AValue: TACLColorPaletteOptionsView);
    procedure SetStyle(AValue: TACLStyleColorPalette);
  protected
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    procedure InitializeDefaultPalette;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure Paint; override;
    procedure SetTargetDPI(AValue: Integer); override;
    //
    property HoveredColor: TACLColorPaletteItemViewInfo read FHoveredColor write SetHoveredColor;
    property ViewInfo: TACLColorPaletteViewInfo read FViewInfo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    property DoubleBuffered default True;
    property FocusOnClick;
    property Items: TACLColorPaletteItems read FItems write SetItems;
    property OptionsView: TACLColorPaletteOptionsView read FOptionsView write SetOptionsView;
    property Color: TAlphaColor read FColor write SetColor default 0;
    property ResourceCollection;
    property Style: TACLStyleColorPalette read FStyle write SetStyle;
    //
    property OnColorChanged: TNotifyEvent read FOnColorChanged write FOnColorChanged;
  end;

const
  StandardColorPalette: array[0..14] of TAlphaColor = (
    $FF0000FF, $FF00FF00, $FFFF0000,
    $FFFFFF00, $FFFF00FF, $FF00FFFF,
    $FF000080, $FF008000, $FF800000,
    $FF808000, $FF800080, $FF008080,
    $FFFFFFFF, $FF808080, $FF000000
  );

implementation

uses
  System.SysUtils,
  System.Math,
  // Vcl
  Vcl.Forms,
  // ACl
  ACL.Math;

{ TACLColorPaletteItem }

procedure TACLColorPaletteItem.AfterConstruction;
begin
  inherited;
  Color := TAlphaColor.None;
end;

procedure TACLColorPaletteItem.Assign(Source: TPersistent);
begin
  if Source is TACLColorPaletteItem then
    Color := TACLColorPaletteItem(Source).Color;
end;

procedure TACLColorPaletteItem.SetColor(AValue: TAlphaColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    Changed(False);
  end;
end;

{ TACLColorPaletteItems }

constructor TACLColorPaletteItems.Create(AOwner: TACLColorPalette);
begin
  inherited Create(TACLColorPaletteItem);
  FOwner := AOwner;
end;

function TACLColorPaletteItems.Add(AColor: TAlphaColor): TACLColorPaletteItem;
begin
  BeginUpdate;
  try
    Result := inherited Add as TACLColorPaletteItem;
    Result.Color := AColor;
  finally
    EndUpdate;
  end;
end;

procedure TACLColorPaletteItems.Populate(AStyle: TACLColorPaletteStyle);
begin
  BeginUpdate;
  try
    Clear;
    case AStyle of
      cpsOffice:
        PopulateOfficeColors;
      cpsClassic:
        PopulateClassicColors;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLColorPaletteItems.PopulateClassicColors;
const
  NumPaletteEntries = 20;
var
  ACount: Integer;
  AIndex: Integer;
  APaletteEntries: array[0..NumPaletteEntries - 1] of TPaletteEntry;
begin
  ACount := GetPaletteEntries(GetStockObject(DEFAULT_PALETTE), 0, NumPaletteEntries, APaletteEntries);
  for AIndex := 0 to ACount - 1 do
  begin
    Add(TAlphaColor.FromARGB(MaxByte,
      APaletteEntries[AIndex].peRed,
      APaletteEntries[AIndex].peGreen,
      APaletteEntries[AIndex].peBlue));
  end;
end;

procedure TACLColorPaletteItems.PopulateOfficeColors;
var
  I: Integer;
begin
  for I := Low(StandardColorPalette) to High(StandardColorPalette) do
    Add(StandardColorPalette[I]);
end;

function TACLColorPaletteItems.GetItem(Index: Integer): TACLColorPaletteItem;
begin
  Result := inherited Items[Index] as TACLColorPaletteItem;
end;

procedure TACLColorPaletteItems.Update(Item: TCollectionItem);
begin
  if Item = nil then
    FOwner.AdjustSize;
  FOwner.Invalidate;
end;

{ TACLColorPaletteItemViewInfo }

constructor TACLColorPaletteItemViewInfo.Create(
  AViewInfo: TACLColorPaletteViewInfo; AColor: TAlphaColor;
  const ABounds: TRect; ABorders: TACLBorders = acAllBorders);
begin
  FColor := AColor;
  FBounds := ABounds;
  FViewInfo := AViewInfo;
  FBorders := ABorders;
end;

procedure TACLColorPaletteItemViewInfo.Draw(ACanvas: TCanvas);
begin
  Palette.Style.DrawHatch(ACanvas, Bounds);
  acFillRect(ACanvas.Handle, Bounds, Color);
  Palette.Style.DrawFrame(ACanvas, Bounds, Selected, Borders);
  if Selected then
    acExcludeFromClipRegion(ACanvas.Handle, Bounds);
end;

function TACLColorPaletteItemViewInfo.GetPalette: TACLColorPalette;
begin
  Result := ViewInfo.Owner;
end;

function TACLColorPaletteItemViewInfo.GetSelected: Boolean;
begin
  Result := Palette.Color = Color;
end;

{ TACLColorPaletteViewInfo }

constructor TACLColorPaletteViewInfo.Create(AOwner: TACLColorPalette);
begin
  inherited Create;
  FOwner := AOwner;
  FCells := TACLObjectList<TACLColorPaletteItemViewInfo>.Create;
end;

destructor TACLColorPaletteViewInfo.Destroy;
begin
  FreeAndNil(FCells);
  inherited;
end;

procedure TACLColorPaletteViewInfo.Calculate(const ABounds: TRect);
begin
  FCells.Count := 0;
  if Options.Style = cpsOffice then
    CalculateOfficeLikeLayout(ABounds)
  else
    CalculateClassicLayout(ABounds);
end;

function TACLColorPaletteViewInfo.CalculateCellSpacing(ACellSize, AWidth: Integer): Integer;
begin
  if Options.CellSpacing >= 0 then
    Result := dpiApply(Options.CellSpacing, CurrentDpi)
  else
    if Items.Count < 2 then
      Result := 0
    else
      if Options.Style = cpsOffice then
        Result := (AWidth - ACellSize * Items.Count) div (Items.Count - 1)
      else
        Result := (AWidth - (AWidth div ACellSize) * ACellSize) div (Items.Count - 1);

  Result := Max(Result, 0);
end;

procedure TACLColorPaletteViewInfo.CalculateClassicLayout(ABounds: TRect);
var
  AItemBounds: TRect;
  ASize: Integer;
  ASpace: Integer;
  I: Integer;
begin
  ASize := dpiApply(Options.CellSize, CurrentDpi);
  ASpace := CalculateCellSpacing(ASize, acRectWidth(ABounds));

  AItemBounds := acRectSetSize(ABounds, ASize, ASize);
  for I := 0 to Items.Count - 1 do
  begin
    if AItemBounds.Right > ABounds.Right then
    begin
      ABounds.Top := AItemBounds.Bottom + ASpace;
      AItemBounds := acRectSetSize(ABounds, ASize, ASize);
    end;
    FCells.Add(TACLColorPaletteItemViewInfo.Create(Self, Items[I].Color, AItemBounds));
    OffsetRect(AItemBounds, ASpace + ASize, 0);
  end;

  if Items.Count > 0 then
  begin
    FHeight := FCells.Last.Bounds.Bottom - FCells.First.Bounds.Top;
    FWidth := FCells.Last.Bounds.Right - FCells.First.Bounds.Left;
  end
  else
  begin
    FWidth := 0;
    FHeight := 0;
  end;
end;

procedure TACLColorPaletteViewInfo.CalculateOfficeLikeLayout(ABounds: TRect);

  function GetBorders(Index: Integer): TACLBorders;
  begin
    if Index = 0 then
      Result := [mLeft, mTop, mRight]
    else if Index = Options.StyleOfficeTintCount - 1 then
      Result := [mLeft, mBottom, mRight]
    else
      Result := [mLeft, mRight];
  end;

var
  AColor: TAlphaColor;
  AItemBounds: TRect;
  ASize: Integer;
  ASpace: Integer;
  I, J: Integer;
begin
  ASize := dpiApply(Options.CellSize, CurrentDpi);
  ASpace := CalculateCellSpacing(ASize, acRectWidth(ABounds));

  FWidth := ASize * Items.Count + ASpace * (Items.Count - 1);
  FHeight := ASize + ASpace + Options.StyleOfficeTintCount * ASize - (Options.StyleOfficeTintCount - 1) * BorderSize;

  for I := 0 to Items.Count - 1 do
  begin
    AColor := Items[I].Color;
    AItemBounds := acRectSetSize(ABounds, ASize, ASize);
    ABounds.Left := AItemBounds.Right + ASpace;
    FCells.Add(TACLColorPaletteItemViewInfo.Create(Self, AColor, AItemBounds));
    AItemBounds := acRectOffset(AItemBounds, 0, ASize + ASpace);
    if AColor <> TAlphaColor.None then
      for J := 0 to Options.StyleOfficeTintCount - 1 do
      begin
        FCells.Add(TACLColorPaletteItemViewInfo.Create(Self,
          AdjustColor(AColor, 1 - (J + 1) / (Options.StyleOfficeTintCount + 1)),
          AItemBounds, GetBorders(J)));
        AItemBounds := acRectOffset(AItemBounds, 0, ASize - BorderSize);
      end;
  end;
end;

procedure TACLColorPaletteViewInfo.Draw(ACanvas: TCanvas);
var
  AItemViewInfo: TACLColorPaletteItemViewInfo;
  ASaveIndex: Integer;
  I: Integer;
begin
  ASaveIndex := acSaveDC(ACanvas);
  try
    for I := 0 to FCells.Count - 1 do
    begin
      AItemViewInfo := FCells[I];
      AItemViewInfo.Draw(ACanvas);
    end;
  finally
    acRestoreDC(ACanvas, ASaveIndex)
  end;
end;

function TACLColorPaletteViewInfo.HitTest(const P: TPoint): TACLColorPaletteItemViewInfo;
var
  I: Integer;
begin
  for I := 0 to FCells.Count - 1 do
  begin
    if PtInRect(FCells[I].Bounds, P) then
      Exit(FCells[I]);
  end;
  Result := nil;
end;

function TACLColorPaletteViewInfo.AdjustColor(AColor: TAlphaColor; ALightness: Single): TAlphaColor;
var
  AColorQuad: TRGBQuad;
  H, S, L: Single;
begin
  AColorQuad := AColor.ToQuad;
  TACLColors.RGBtoHSL(AColorQuad.rgbRed, AColorQuad.rgbGreen, AColorQuad.rgbBlue, H, S, L);

  if L >= 0.8 then
    ALightness := ALightness * 0.2 + 0.8
  else if L >= 0.5 then
    ALightness := ALightness * 0.5 + 0.5
  else
    ALightness := ALightness * 0.49;

  TACLColors.HSLtoRGB(H, S, ALightness, AColorQuad.rgbRed, AColorQuad.rgbGreen, AColorQuad.rgbBlue);
  Result := TAlphaColor.FromColor(AColorQuad);
end;

function TACLColorPaletteViewInfo.GetCurrentDpi: Integer;
begin
  Result := FOwner.FCurrentPPI;
end;

function TACLColorPaletteViewInfo.GetItems: TACLColorPaletteItems;
begin
  Result := FOwner.Items;
end;

function TACLColorPaletteViewInfo.GetOptions: TACLColorPaletteOptionsView;
begin
  Result := FOwner.OptionsView;
end;

{ TACLStyleColorPalette }

procedure TACLStyleColorPalette.DrawFrame(ACanvas: TCanvas; const R: TRect; ASelected: Boolean; ABorders: TACLBorders);
begin
  acDrawComplexFrame(ACanvas.Handle, R, ColorBorder1.Value, ColorBorder2.Value, ABorders);
  if ASelected then
    acDrawComplexFrame(ACanvas.Handle, R, ColorSelectedBorder1.Value, ColorSelectedBorder2.Value, acAllBorders);
end;

procedure TACLStyleColorPalette.DrawHatch(ACanvas: TCanvas; const R: TRect);
begin
  acDrawHatch(ACanvas.Handle, R, ColorHatch1.AsColor, ColorHatch2.AsColor, 4);
end;

procedure TACLStyleColorPalette.InitializeResources;
begin
  ColorBorder1.InitailizeDefaults('Common.Colors.Border1', True);
  ColorBorder2.InitailizeDefaults('Common.Colors.Border2', True);
  ColorSelectedBorder1.InitailizeDefaults('Common.Colors.Text', True);
  ColorSelectedBorder2.InitailizeDefaults('Common.Colors.Border2', True);
  ColorHatch1.InitailizeDefaults('Common.Colors.Hatch1', acHatchDefaultColor1);
  ColorHatch2.InitailizeDefaults('Common.Colors.Hatch2', acHatchDefaultColor2);
end;

{ TACLColorPaletteOptionsView }

constructor TACLColorPaletteOptionsView.Create(AOwner: TACLColorPalette);
begin
  inherited Create;
  FOwner := AOwner;
  FCellSize := 16;
  FCellSpacing := -1;
  FStyleOfficeTintCount := 5;
end;

procedure TACLColorPaletteOptionsView.DoAssign(Source: TPersistent);
begin
  if Source is TACLColorPaletteOptionsView then
  begin
    Style := TACLColorPaletteOptionsView(Source).Style;
    CellSize := TACLColorPaletteOptionsView(Source).CellSize;
    CellSpacing := TACLColorPaletteOptionsView(Source).CellSpacing;
    StyleOfficeTintCount := TACLColorPaletteOptionsView(Source).StyleOfficeTintCount;
  end;
end;

procedure TACLColorPaletteOptionsView.DoChanged(AChanges: TACLPersistentChanges);
begin
  FOwner.FullRefresh;
end;

procedure TACLColorPaletteOptionsView.SetCellSize(AValue: Integer);
begin
  SetIntegerFieldValue(FCellSize, Max(AValue, 1));
end;

procedure TACLColorPaletteOptionsView.SetCellSpacing(AValue: Integer);
begin
  SetIntegerFieldValue(FCellSpacing, Max(AValue, -1));
end;

procedure TACLColorPaletteOptionsView.SetStyle(AValue: TACLColorPaletteStyle);
begin
  if FStyle <> AValue then
  begin
    FStyle := AValue;
    Changed;
  end;
end;

procedure TACLColorPaletteOptionsView.SetStyleOfficeTintCount(AValue: Integer);
begin
  SetIntegerFieldValue(FStyleOfficeTintCount, MinMax(AValue, 1, 10));
end;

{ TACLColorPalette }

constructor TACLColorPalette.Create(AOwner: TComponent);
begin
  inherited;
  FStyle := TACLStyleColorPalette.Create(Self);
  FItems := TACLColorPaletteItems.Create(Self);
  FViewInfo := TACLColorPaletteViewInfo.Create(Self);
  FOptionsView := TACLColorPaletteOptionsView.Create(Self);
  DoubleBuffered := True;
  InitializeDefaultPalette;
end;

destructor TACLColorPalette.Destroy;
begin
  FreeAndNil(FOptionsView);
  FreeAndNil(FViewInfo);
  FreeAndNil(FStyle);
  FreeAndNil(FItems);
  inherited;
end;

function TACLColorPalette.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  Result := cbsTransparent;
end;

procedure TACLColorPalette.InitializeDefaultPalette;
begin
  Items.Populate(OptionsView.Style);
end;

procedure TACLColorPalette.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  ViewInfo.Calculate(Rect(0, 0, AWidth, AHeight));
  inherited SetBounds(ALeft, ATop, ViewInfo.Width, ViewInfo.Height);
end;

procedure TACLColorPalette.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  AItem: TACLColorPaletteItemViewInfo;
begin
  inherited;
  AItem := ViewInfo.HitTest(Point(X, Y));
  if AItem <> nil then
    Color := AItem.Color;
end;

procedure TACLColorPalette.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  HoveredColor := ViewInfo.HitTest(Point(X, Y));
end;

procedure TACLColorPalette.Paint;
begin
  inherited;
  ViewInfo.Draw(Canvas);
end;

procedure TACLColorPalette.SetOptionsView(AValue: TACLColorPaletteOptionsView);
begin
  FOptionsView.Assign(AValue);
end;

procedure TACLColorPalette.SetTargetDPI(AValue: Integer);
begin
  inherited;
  Style.TargetDPI := AValue;
end;

procedure TACLColorPalette.SetColor(AValue: TAlphaColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    CallNotifyEvent(Self, OnColorChanged);
    Invalidate;
  end;
end;

procedure TACLColorPalette.SetHoveredColor(AValue: TACLColorPaletteItemViewInfo);
begin
  if FHoveredColor <> AValue then
  begin
    FHoveredColor := AValue;
    Application.CancelHint;
    if AValue <> nil then
      Hint := AValue.Color.ToString
    else
      Hint := '';
  end;
end;

procedure TACLColorPalette.SetItems(AValue: TACLColorPaletteItems);
begin
  FItems.Assign(AValue);
end;

procedure TACLColorPalette.SetStyle(AValue: TACLStyleColorPalette);
begin
  FStyle.Assign(AValue);
end;

end.
