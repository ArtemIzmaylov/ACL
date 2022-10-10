{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*           Advanced Color Picker           *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.ColorPicker;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.UITypes,
  System.Types,
  System.SysUtils,
  System.Classes,
  // Vcl
  Vcl.Graphics,
  Vcl.Controls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Gdiplus,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.SpinEdit,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Resources,
  ACL.Utils.DPIAware,
  ACL.Utils.Common,
  ACL.Utils.Strings;

const
  cpcnValue = cccnLast + 1;

type
  TACLColorPickerOptions = class;
  TACLColorPickerSubClassColorModifierCell = class;
  TACLColorPickerSubClassPainter = class;

  TACLColorPickerColorComponent = (cpccA, cpccR, cpccG, cpccB, cpccH, cpccS, cpccL);
  TACLColorPickerColorComponents = set of TACLColorPickerColorComponent;

  { TACLColorPickerColorInfo }

  TACLColorPickerColorInfo = class
  strict private
    FAlpha: Byte;
    FHue: Single;
    FLightness: Single;
    FSaturation: Single;

    FOnChanged: TNotifyEvent;

    function GetAlphaColor: TAlphaColor;
    function GetColor: TColor;
    function GetGrayScale: Single;
    function GetR: Byte;
    function GetG: Byte;
    function GetB: Byte;
    procedure SetAlpha(AValue: Byte);
    procedure SetAlphaColor(AValue: TAlphaColor);
    procedure SetColor(const AValue: TColor);
    procedure SetR(const AValue: Byte);
    procedure SetG(const AValue: Byte);
    procedure SetB(const AValue: Byte);
    procedure SetH(const AValue: Single);
    procedure SetL(const AValue: Single);
    procedure SetS(const AValue: Single);
  protected
    procedure Changed;
  public
    property Alpha: Byte read FAlpha write SetAlpha;
    property AlphaColor: TAlphaColor read GetAlphaColor write SetAlphaColor;
    property Color: TColor read GetColor write SetColor;
    // HSL
    property H: Single read FHue write SetH;
    property S: Single read FSaturation write SetS;
    property L: Single read FLightness write SetL;
    // RGB
    property R: Byte read GetR write SetR;
    property G: Byte read GetG write SetG;
    property B: Byte read GetB write SetB;
    // Utils
    property GrayScale: Single read GetGrayScale;
    //
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  { TACLColorPickerSubClass }

  TACLColorPickerSubClass = class(TACLCompoundControlSubClass)
  strict private
    FColor: TACLColorPickerColorInfo;
    FOptions: TACLColorPickerOptions;
    FPainter: TACLColorPickerSubClassPainter;
    FStyle: TACLStyleContent;
    FStyleEdit: TACLStyleEdit;
    FStyleEditButton: TACLStyleButton;
    FStyleHatch: TACLStyleHatch;
    FTargetDPI: Integer;

    FOnColorChanged: TNotifyEvent;

    procedure ColorChangeHandler(Sender: TObject);
    procedure OptionsChangeHandler(Sender: TObject);
  protected
    function CreateViewInfo: TACLCompoundControlSubClassCustomViewInfo; override;
    procedure ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CalculateAutoSize(var AWidth, AHeight: Integer): Boolean; override;
    procedure SetTargetDPI(AValue: Integer); override;
    //
    property Color: TACLColorPickerColorInfo read FColor;
    property Options: TACLColorPickerOptions read FOptions;
    property Painter: TACLColorPickerSubClassPainter read FPainter;
    property Style: TACLStyleContent read FStyle;
    property StyleEdit: TACLStyleEdit read FStyleEdit;
    property StyleEditButton: TACLStyleButton read FStyleEditButton;
    property StyleHatch: TACLStyleHatch read FStyleHatch;
    property TargetDPI: Integer read FTargetDPI;
    //
    property OnColorChanged: TNotifyEvent read FOnColorChanged write FOnColorChanged;
  end;

  { TACLColorPickerSubClassPainter }

  TACLColorPickerSubClassPainter = class(TACLCompoundControlSubClassPersistent)
  strict private
    function GetStyle: TACLStyleContent;
    function GetStyleHatch: TACLStyleHatch;
  public
    function BorderSize: Integer; virtual;
    procedure DrawBorder(ACanvas: TCanvas; const R: TRect); virtual;
    //
    property Style: TACLStyleContent read GetStyle;
    property StyleHatch: TACLStyleHatch read GetStyleHatch;
  end;

  { TACLColorPickerSubClassViewInfo }

  TACLColorPickerSubClassViewInfo = class(TACLCompoundControlSubClassContainerViewInfo)
  strict private
    function GetSubClass: TACLColorPickerSubClass;
  protected
    FEdits: array[TACLColorPickerColorComponent] of TACLColorPickerSubClassColorModifierCell;
    FGamut: TACLColorPickerSubClassColorModifierCell;
    FHexCode: TACLColorPickerSubClassColorModifierCell;
    FPreview: TACLColorPickerSubClassColorModifierCell;
    FSlider1: TACLColorPickerSubClassColorModifierCell;
    FSlider2: TACLColorPickerSubClassColorModifierCell;

    FIndentBetweenElements: Integer;

    procedure CalculateAutoSize(var AWidth, AHeight: Integer); virtual;
    procedure CalculateSubCells(const AChanges: TIntegerSet); override;
    procedure CalculateSubCellsEditors(var R: TRect; const AChanges: TIntegerSet);
    procedure CalculateSubCellsSliders(var R: TRect; const AChanges: TIntegerSet);
    function MeasureEditsAreaSize: TSize;
    procedure RecreateSubCells; override;
  public
    procedure Calculate(const R: TRect; AChanges: TIntegerSet); override;
    //
    property SubClass: TACLColorPickerSubClass read GetSubClass;
  end;

  { TACLColorPickerSubClassColorModifierCell }

  TACLColorPickerSubClassColorModifierCell = class abstract(TACLCompoundControlSubClassCustomViewInfo,
    IACLDraggableObject)
  strict private
    function GetColorInfo: TACLColorPickerColorInfo; inline;
    function GetPainter: TACLColorPickerSubClassPainter; inline;
    function GetSubClass: TACLColorPickerSubClass; inline;
  protected
    FUpdateLocked: Boolean;

    procedure DoCalculate(AChanges: TIntegerSet); override;
    function IsCaptured: Boolean; virtual;
    procedure UpdateEditValue; virtual; abstract;
    // IACLDraggableObject
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
  public
    procedure DragMove(X, Y: Integer); virtual;
    function MeasureSize: TSize; virtual; abstract;
    //
    property ColorInfo: TACLColorPickerColorInfo read GetColorInfo;
    property Painter: TACLColorPickerSubClassPainter read GetPainter;
    property SubClass: TACLColorPickerSubClass read GetSubClass;
  end;

  { TACLColorPickerOptions }

  TACLColorPickerOptions = class(TACLCustomOptionsPersistent)
  strict private
    FAllowEditAlpha: Boolean;

    procedure SetAllowEditAlpha(const Value: Boolean);
  protected
    FOnChange: TNotifyEvent;

    procedure DoAssign(Source: TPersistent); override;
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
  public
    procedure AfterConstruction; override;
  published
    property AllowEditAlpha: Boolean read FAllowEditAlpha write SetAllowEditAlpha default True;
  end;

  { TACLCustomColorPicker }

  TACLCustomColorPicker = class(TACLCompoundControl)
  strict private
    FBorders: TACLBorders;

    function GetColor: TAlphaColor;
    function GetOnColorChanged: TNotifyEvent;
    function GetOptions: TACLColorPickerOptions;
    function GetStyle: TACLStyleContent;
    function GetStyleEdit: TACLStyleEdit;
    function GetStyleEditButton: TACLStyleButton;
    function GetStyleHatch: TACLStyleHatch;
    function GetSubClass: TACLColorPickerSubClass;
    procedure SetBorders(const Value: TACLBorders);
    procedure SetColor(const Value: TAlphaColor);
    procedure SetOnColorChanged(const Value: TNotifyEvent);
    procedure SetOptions(const Value: TACLColorPickerOptions);
    procedure SetStyle(const Value: TACLStyleContent);
    procedure SetStyleEdit(const Value: TACLStyleEdit);
    procedure SetStyleEditButton(const Value: TACLStyleButton);
    procedure SetStyleHatch(const Value: TACLStyleHatch);
  protected
    function AllowCompositionPainting: Boolean; override;
    function CreateSubClass: TACLCompoundControlSubClass; override;
    procedure DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect); override;
    function GetContentOffset: TRect; override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    procedure Paint; override;
    procedure PaintWindow(DC: HDC); override;
    //
    property Borders: TACLBorders read FBorders write SetBorders default acAllBorders;
    property Options: TACLColorPickerOptions read GetOptions write SetOptions;
    property Style: TACLStyleContent read GetStyle write SetStyle;
    property StyleEdit: TACLStyleEdit read GetStyleEdit write SetStyleEdit;
    property StyleEditButton: TACLStyleButton read GetStyleEditButton write SetStyleEditButton;
    property StyleHatch: TACLStyleHatch read GetStyleHatch write SetStyleHatch;
    property SubClass: TACLColorPickerSubClass read GetSubClass;
    //
    property OnColorChanged: TNotifyEvent read GetOnColorChanged write SetOnColorChanged;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    //
    property Color: TAlphaColor read GetColor write SetColor;
  end;

  { TACLColorPicker }

  TACLColorPicker = class(TACLCustomColorPicker)
  published
    property Align;
    property Anchors;
    property AutoSize default True;
    property Borders;
    property Enabled;
    property Font;
    property Options;
    property PopupMenu;
    property ResourceCollection;
    property Style;
    property StyleEdit;
    property StyleEditButton;
    property StyleHatch;
    property Transparent;
    property Visible;

    property OnClick;
    property OnColorChanged;
    property OnDblClick;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  System.Math,
  System.Character;

type
  TACLCustomEditAccess = class(TACLCustomEdit);
  TComponentAccess = class(TComponent);

const
  accpSliderArrowWidth = 5;
  accpSliderArrowWidthHalf = 3;
  accpIndentBetweenElements = 6;

type
  { TACLColorPickerSubClassColorModifierCellDragObject }

  TACLColorPickerSubClassColorModifierCellDragObject = class(TACLCompoundControlSubClassDragObject)
  strict private
    FCell: TACLColorPickerSubClassColorModifierCell;
  public
    constructor Create(ACell: TACLColorPickerSubClassColorModifierCell);
    procedure DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer); override;
    function DragStart: Boolean; override;
  end;

  { TACLColorPickerSubClassVisualColorModifierCell }

  TACLColorPickerSubClassVisualColorModifierCell = class(TACLColorPickerSubClassColorModifierCell)
  strict private
    FContentCache: TACLBitmap;
    FCursorPosition: TPoint;

    procedure SetCursorPosition(const AValue: TPoint);
  protected
    function CalculateCursorPosition: TPoint; virtual; abstract;
    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure DrawContent(ACanvas: TCanvas); virtual;
    procedure FlushContentCache; virtual;
    function GetContentBounds: TRect; virtual;
    function GetContentFrameRect: TRect; virtual;
    function GetCursorColor: TColor; virtual;
    procedure UpdateContentCache; overload;
    procedure UpdateContentCache(ACanvas: TCanvas; AWidth, AHeight: Integer); overload; virtual; abstract;
    procedure UpdateEditValue; override;
  public
    destructor Destroy; override;
    //
    property ContentBounds: TRect read GetContentBounds;
    property ContentFrameRect: TRect read GetContentFrameRect;
    property CursorPosition: TPoint read FCursorPosition write SetCursorPosition;
  end;

  { TACLColorPickerSubClassGamutCell }

  TACLColorPickerSubClassGamutCell = class(TACLColorPickerSubClassVisualColorModifierCell)
  protected
    function CalculateCursorPosition: TPoint; override;
    procedure DrawContent(ACanvas: TCanvas); override;
    procedure DrawCursor(ACanvas: TCanvas); virtual;
    procedure UpdateContentCache(ACanvas: TCanvas; AWidth: Integer; AHeight: Integer); override;
  public
    procedure DragMove(X, Y: Integer); override;
    function MeasureSize: TSize; override;
  end;

  { TACLColorPickerSubClassSliderCell }

  TACLColorPickerSubClassSliderCell = class(TACLColorPickerSubClassVisualColorModifierCell)
  protected
    procedure DrawArrow(ACanvas: TCanvas); virtual;
    procedure DrawContent(ACanvas: TCanvas); override;
    function GetArrowBounds: TRect; virtual;
    function GetContentBounds: TRect; override;
  public
    function MeasureSize: TSize; override;
    //
    property ArrowBounds: TRect read GetArrowBounds;
  end;

  { TACLColorPickerSubClassAlphaSliderCell }

  TACLColorPickerSubClassAlphaSliderCell = class(TACLColorPickerSubClassSliderCell)
  protected
    function CalculateCursorPosition: TPoint; override;
    procedure UpdateContentCache(ACanvas: TCanvas; AWidth, AHeight: Integer); override;
  public
    procedure DragMove(X, Y: Integer); override;
  end;

  { TACLColorPickerSubClassLightnessSliderCell }

  TACLColorPickerSubClassLightnessSliderCell = class(TACLColorPickerSubClassSliderCell)
  protected
    function CalculateCursorPosition: TPoint; override;
    procedure UpdateContentCache(ACanvas: TCanvas; AWidth, AHeight: Integer); override;
  public
    procedure DragMove(X, Y: Integer); override;
  end;

  { TACLColorPickerSubClassPreviewCell }

  TACLColorPickerSubClassPreviewCell = class(TACLColorPickerSubClassColorModifierCell)
  protected
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure UpdateEditValue; override;
  public
    function MeasureSize: TSize; override;
  end;

  { TACLColorPickerSubClassCustomEditCell }

  TACLColorPickerSubClassCustomEditCell = class abstract(TACLColorPickerSubClassColorModifierCell)
  protected
    FEdit: TACLCustomEdit;

    function CreateEdit: TACLCustomEdit; virtual; abstract;
    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    function GetCaption: string; virtual; abstract;
    function IsCaptured: Boolean; override;
    function MeasureEditWidth: Integer; virtual; abstract;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    function MeasureSize: TSize; override;
  end;

  { TACLColorPickerSubClassCustomSpinEditCell }

  TACLColorPickerSubClassCustomSpinEditCell = class abstract(TACLColorPickerSubClassCustomEditCell)
  strict private
    procedure EditChangeHandler(Sender: TObject);
  protected
    function CreateEdit: TACLCustomEdit; override;
    function GetValue: Integer; virtual; abstract;
    function MeasureEditWidth: Integer; override;
    procedure SetValue(AValue: Integer); virtual; abstract;
    procedure UpdateEditValue; override;
  end;

  { TACLColorPickerSubClassSpinEditCell }

  TACLColorPickerSubClassSpinEditCell = class(TACLColorPickerSubClassCustomSpinEditCell)
  protected
    FType: TACLColorPickerColorComponent;

    function GetCaption: string; override;
    function GetValue: Integer; override;
    procedure SetValue(AValue: Integer); override;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass; AType: TACLColorPickerColorComponent); reintroduce;
  end;

  { TACLColorPickerSubClassHexCodeEditCell }

  TACLColorPickerSubClassHexCodeEditCell = class(TACLColorPickerSubClassCustomEditCell)
  strict private
    procedure EditChangeHandler(Sender: TObject);
    procedure EditKeyPressHandler(Sender: TObject; var AKey: Char);
  protected
    function CreateEdit: TACLCustomEdit; override;
    function GetCaption: string; override;
    function MeasureEditWidth: Integer; override;
    procedure UpdateEditValue; override;
  end;

function CalculateTextFieldSize(AFont: TFont; ADigits: Integer): Integer;
const
  AllowedChars: array[0..21] of Char = (
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'a', 'b', 'c', 'd', 'e', 'f'
  );
var
  I: Integer;
begin
  Result := 0;
  MeasureCanvas.Font := AFont;
  for I := 0 to Length(AllowedChars) - 1 do
    Result := Max(Result, MeasureCanvas.TextWidth(AllowedChars[I]));
  Result := Result * ADigits;
end;

{ TACLColorPickerColorInfo }

procedure TACLColorPickerColorInfo.Changed;
begin
  CallNotifyEvent(Self, OnChanged);
end;

function TACLColorPickerColorInfo.GetAlphaColor: TAlphaColor;
begin
  Result := TAlphaColor.FromColor(Color, Alpha);
end;

function TACLColorPickerColorInfo.GetColor: TColor;
begin
  TACLColors.HSLtoRGB(H, S, L, Result);
end;

function TACLColorPickerColorInfo.GetGrayScale: Single;
begin
  Result := R * 0.3 + G * 0.59 + B * 0.11;
end;

function TACLColorPickerColorInfo.GetR: Byte;
begin
  Result := GetRValue(Color);
end;

function TACLColorPickerColorInfo.GetG: Byte;
begin
  Result := GetGValue(Color);
end;

function TACLColorPickerColorInfo.GetB: Byte;
begin
  Result := GetBValue(Color);
end;

procedure TACLColorPickerColorInfo.SetAlpha(AValue: Byte);
begin
  if FAlpha <> AValue then
  begin
    FAlpha := AValue;
    Changed;
  end;
end;

procedure TACLColorPickerColorInfo.SetAlphaColor(AValue: TAlphaColor);
begin
  if AlphaColor <> AValue then
  begin
    FAlpha := AValue.A;
    if AValue.IsValid then
      TACLColors.RGBtoHSL(AValue.ToColor, FHue, FSaturation, FLightness)
    else
    begin
      FHue := 0;
      FSaturation := 0;
      FLightness := 0;
    end;
    Changed;
  end;
end;

procedure TACLColorPickerColorInfo.SetColor(const AValue: TColor);
begin
  AlphaColor := TAlphaColor.FromColor(AValue, Alpha);
end;

procedure TACLColorPickerColorInfo.SetB(const AValue: Byte);
begin
  AlphaColor := TAlphaColor.FromARGB(Alpha, R, G, AValue);
end;

procedure TACLColorPickerColorInfo.SetG(const AValue: Byte);
begin
  AlphaColor := TAlphaColor.FromARGB(Alpha, R, AValue, B);
end;

procedure TACLColorPickerColorInfo.SetR(const AValue: Byte);
begin
  AlphaColor := TAlphaColor.FromARGB(Alpha, AValue, G, B);
end;

procedure TACLColorPickerColorInfo.SetH(const AValue: Single);
begin
  if H <> AValue then
  begin
    FHue := AValue;
    Changed;
  end;
end;

procedure TACLColorPickerColorInfo.SetL(const AValue: Single);
begin
  if L <> AValue then
  begin
    FLightness := AValue;
    Changed;
  end;
end;

procedure TACLColorPickerColorInfo.SetS(const AValue: Single);
begin
  if S <> AValue then
  begin
    FSaturation := AValue;
    Changed;
  end;
end;

{ TACLColorPickerSubClassColorModifierCell }

procedure TACLColorPickerSubClassColorModifierCell.DoCalculate(AChanges: TIntegerSet);
begin
  inherited DoCalculate(AChanges);

  if (cpcnValue in AChanges) and not IsCaptured then
  begin
    FUpdateLocked := True;
    UpdateEditValue;
    FUpdateLocked := False;
  end;
end;

function TACLColorPickerSubClassColorModifierCell.IsCaptured: Boolean;
begin
  Result := Self = SubClass.PressedObject;
end;

procedure TACLColorPickerSubClassColorModifierCell.DragMove(X, Y: Integer);
begin
  // do nothing
end;

function TACLColorPickerSubClassColorModifierCell.CreateDragObject(
  const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
begin
  Result := TACLColorPickerSubClassColorModifierCellDragObject.Create(Self);
end;

function TACLColorPickerSubClassColorModifierCell.GetColorInfo: TACLColorPickerColorInfo;
begin
  Result := SubClass.Color;
end;

function TACLColorPickerSubClassColorModifierCell.GetPainter: TACLColorPickerSubClassPainter;
begin
  Result := SubClass.Painter;
end;

function TACLColorPickerSubClassColorModifierCell.GetSubClass: TACLColorPickerSubClass;
begin
  Result := TACLColorPickerSubClass(inherited SubClass);
end;

{ TACLColorPickerSubClassColorModifierCellDragObject }

constructor TACLColorPickerSubClassColorModifierCellDragObject.Create(ACell: TACLColorPickerSubClassColorModifierCell);
begin
  FCell := ACell;
  inherited Create;
end;

procedure TACLColorPickerSubClassColorModifierCellDragObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);
begin
  FCell.DragMove(P.X, P.Y);
end;

function TACLColorPickerSubClassColorModifierCellDragObject.DragStart: Boolean;
begin
  Result := True;
end;

{ TACLColorPickerSubClassVisualColorModifierCell }

destructor TACLColorPickerSubClassVisualColorModifierCell.Destroy;
begin
  FlushContentCache;
  inherited Destroy;
end;

procedure TACLColorPickerSubClassVisualColorModifierCell.DoCalculate(AChanges: TIntegerSet);
begin
  inherited DoCalculate(AChanges);

  if (FContentCache = nil) or (cccnStruct in AChanges) or
    (FContentCache.Width <> acRectWidth(ContentBounds)) or
    (FContentCache.Height <> acRectHeight(ContentBounds)) then
  begin
    FlushContentCache;
    UpdateEditValue;
  end;
end;

procedure TACLColorPickerSubClassVisualColorModifierCell.DoDraw(ACanvas: TCanvas);
var
  ASaveIndex: Integer;
begin
  if not IsRectEmpty(ContentFrameRect) then
    Painter.DrawBorder(ACanvas, ContentFrameRect);
  if not IsRectEmpty(ContentBounds) then
  begin
    ASaveIndex := acSaveDC(ACanvas);
    try
      if acIntersectClipRegion(ACanvas.Handle, Bounds) then
      begin
        if FContentCache = nil then
          UpdateContentCache;
        DrawContent(ACanvas);
      end;
    finally
      acRestoreDC(ACanvas, ASaveIndex);
    end;
  end;
end;

procedure TACLColorPickerSubClassVisualColorModifierCell.DrawContent(ACanvas: TCanvas);
begin
  ACanvas.Draw(ContentBounds.Left, ContentBounds.Top, FContentCache);
end;

procedure TACLColorPickerSubClassVisualColorModifierCell.FlushContentCache;
begin
  FreeAndNil(FContentCache);
end;

function TACLColorPickerSubClassVisualColorModifierCell.GetContentBounds: TRect;
begin
  Result := acRectInflate(Bounds, -Painter.BorderSize);
end;

function TACLColorPickerSubClassVisualColorModifierCell.GetContentFrameRect: TRect;
begin
  Result := acRectInflate(ContentBounds, Painter.BorderSize);
end;

function TACLColorPickerSubClassVisualColorModifierCell.GetCursorColor: TColor;
begin
  Result := clBlack;
end;

procedure TACLColorPickerSubClassVisualColorModifierCell.UpdateContentCache;
begin
  FlushContentCache;
  FContentCache := TACLBitmap.CreateEx(ContentBounds, pf32bit, True);
  UpdateContentCache(FContentCache.Canvas, FContentCache.Width, FContentCache.Height);
end;

procedure TACLColorPickerSubClassVisualColorModifierCell.UpdateEditValue;
begin
  CursorPosition := CalculateCursorPosition;
  FlushContentCache;
  Invalidate;
end;

procedure TACLColorPickerSubClassVisualColorModifierCell.SetCursorPosition(const AValue: TPoint);
begin
  if FCursorPosition <> AValue then
  begin
    FCursorPosition := AValue;
    Invalidate;
  end;
end;

{ TACLColorPickerSubClass }

constructor TACLColorPickerSubClass.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColor := TACLColorPickerColorInfo.Create;
  FColor.OnChanged := ColorChangeHandler;
  FStyle := TACLStyleContent.Create(Self);
  FStyleEdit := TACLStyleEdit.Create(Self);
  FStyleEditButton := TACLStyleSpinButton.Create(Self);
  FStyleHatch := TACLStyleHatch.Create(Self);
  FOptions := TACLColorPickerOptions.Create;
  FOptions.FOnChange := OptionsChangeHandler;
  FPainter := TACLColorPickerSubClassPainter.Create(Self);
  FTargetDPI := acDefaultDPI;
end;

destructor TACLColorPickerSubClass.Destroy;
begin
  FreeAndNil(FStyleHatch);
  FreeAndNil(FStyleEditButton);
  FreeAndNil(FStyleEdit);
  FreeAndNil(FOptions);
  FreeAndNil(FPainter);
  FreeAndNil(FColor);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

function TACLColorPickerSubClass.CalculateAutoSize(var AWidth, AHeight: Integer): Boolean;
begin
  TACLColorPickerSubClassViewInfo(ViewInfo).CalculateAutoSize(AWidth, AHeight);
  Result := True;
end;

procedure TACLColorPickerSubClass.SetTargetDPI(AValue: Integer);
begin
  FTargetDPI := AValue;
  Style.TargetDPI := AValue;
  inherited SetTargetDPI(AValue);
end;

function TACLColorPickerSubClass.CreateViewInfo: TACLCompoundControlSubClassCustomViewInfo;
begin
  Result := TACLColorPickerSubClassViewInfo.Create(Self);
end;

procedure TACLColorPickerSubClass.ColorChangeHandler(Sender: TObject);
begin
  Changed([cpcnValue]);
  Update;
  CallNotifyEvent(Sender, OnColorChanged);
end;

procedure TACLColorPickerSubClass.OptionsChangeHandler(Sender: TObject);
begin
  FullRefresh;
  Container.GetControl.Realign;
end;

procedure TACLColorPickerSubClass.ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState);
begin
  inherited;
  if HitTest.HitObject is TACLColorPickerSubClassColorModifierCell then
    TACLColorPickerSubClassColorModifierCell(HitTest.HitObject).DragMove(HitTest.HitPoint.X, HitTest.HitPoint.Y);
end;

{ TACLColorPickerSubClassPainter }

function TACLColorPickerSubClassPainter.BorderSize: Integer;
begin
  Result := 2;
end;

procedure TACLColorPickerSubClassPainter.DrawBorder(ACanvas: TCanvas; const R: TRect);
begin
  Style.DrawBorder(ACanvas, R, acAllBorders);
end;

function TACLColorPickerSubClassPainter.GetStyle: TACLStyleContent;
begin
  Result := TACLColorPickerSubClass(SubClass).Style;
end;

function TACLColorPickerSubClassPainter.GetStyleHatch: TACLStyleHatch;
begin
  Result := TACLColorPickerSubClass(SubClass).StyleHatch;
end;

{ TACLColorPickerSubClassViewInfo }

procedure TACLColorPickerSubClassViewInfo.Calculate(const R: TRect; AChanges: TIntegerSet);
begin
  inherited;
  FIndentBetweenElements := ScaleFactor.Apply(accpIndentBetweenElements);
end;

procedure TACLColorPickerSubClassViewInfo.CalculateAutoSize(var AWidth, AHeight: Integer);

  procedure Include(const ASize: TSize);
  begin
    if not acSizeIsEmpty(ASize) then
    begin
      Inc(AWidth, ASize.cx);
      Inc(AWidth, FIndentBetweenElements);
      AHeight := Max(AHeight, ASize.cy);
    end;
  end;

begin
  AWidth := 0;
  AHeight := 0;

  if FSlider1 <> nil then
    Include(FSlider1.MeasureSize);
  if FSlider2 <> nil then
    Include(FSlider2.MeasureSize);
  Include(MeasureEditsAreaSize);

  if FGamut <> nil then
    Include(acSize(Max(AHeight, FGamut.MeasureSize.cy)));

  // Content Offsets
  Inc(AHeight, 2 * FIndentBetweenElements);
  Inc(AWidth, 2 * FIndentBetweenElements);
end;

procedure TACLColorPickerSubClassViewInfo.CalculateSubCells(const AChanges: TIntegerSet);
var
  ARect: TRect;
begin
  inherited CalculateSubCells(AChanges);

  ARect := acRectInflate(Bounds, -FIndentBetweenElements);
  CalculateSubCellsEditors(ARect, AChanges);
  CalculateSubCellsSliders(ARect, AChanges);
  if FGamut <> nil then
    FGamut.Calculate(ARect, AChanges);
end;

procedure TACLColorPickerSubClassViewInfo.CalculateSubCellsEditors(var R: TRect; const AChanges: TIntegerSet);

  function PlaceCell(ACell: TACLColorPickerSubClassColorModifierCell; var R: TRect): Boolean;
  begin
    Result := ACell <> nil;
    if Result then
    begin
      ACell.Calculate(acRectSetHeight(R, ACell.MeasureSize.cy), AChanges);
      R.Top := ACell.Bounds.Bottom + FIndentBetweenElements;
    end;
  end;

var
  AComponent: TACLColorPickerColorComponent;
  ARect: TRect;
begin
  ARect := acRectSetRight(R, R.Right, MeasureEditsAreaSize.cx);
  if FPreview <> nil then
  begin
    FPreview.Calculate(acRectSetHeight(ARect, ARect.Width), AChanges);
    ARect.Top := FPreview.Bounds.Bottom + FIndentBetweenElements;
  end;
  for AComponent := Low(AComponent) to High(AComponent) do
  begin
    if PlaceCell(FEdits[AComponent], ARect) and (AComponent in [cpccA, cpccB, cpccL]) then
      Inc(ARect.Top, FIndentBetweenElements);
  end;
  PlaceCell(FHexCode, ARect);
  R.Right := ARect.Left - FIndentBetweenElements;
end;

procedure TACLColorPickerSubClassViewInfo.CalculateSubCellsSliders(var R: TRect; const AChanges: TIntegerSet);

  procedure Place(var R: TRect; ACell: TACLColorPickerSubClassColorModifierCell);
  begin
    if ACell <> nil then
    begin
      ACell.Calculate(acRectSetRight(R, R.Right, ACell.MeasureSize.cx), AChanges);
      R.Right := ACell.Bounds.Left - FIndentBetweenElements;
    end;
  end;

begin
  InflateRect(R, 0, accpSliderArrowWidthHalf);
  Place(R, FSlider2);
  Place(R, FSlider1);
  InflateRect(R, 0, -accpSliderArrowWidthHalf);
end;

function TACLColorPickerSubClassViewInfo.MeasureEditsAreaSize: TSize;

  procedure Include(const ACellSize: TSize; var ASize: TSize);
  begin
    ASize.cx := Max(ASize.cx, ACellSize.cx);
    Inc(ASize.cy, ACellSize.cy + FIndentBetweenElements);
  end;

var
  ACell: TACLColorPickerSubClassColorModifierCell;
  AComponent: TACLColorPickerColorComponent;
begin
  Result := acSize(0, 0);
  for AComponent := Low(AComponent) to High(AComponent) do
  begin
    ACell := FEdits[AComponent];
    if ACell <> nil then
    begin
      Include(ACell.MeasureSize, Result);
      if AComponent in [cpccA, cpccB, cpccL] then
        Inc(Result.cy, FIndentBetweenElements);
    end;
  end;
  if FHexCode <> nil then
    Include(FHexCode.MeasureSize, Result);
  if FPreview <> nil then
    Include(acSize(Result.cx), Result);
  if Result.cy > 0 then
    Inc(Result.cy, FIndentBetweenElements);
end;

procedure TACLColorPickerSubClassViewInfo.RecreateSubCells;
var
  AComponent: TACLColorPickerColorComponent;
  AComponents: TACLColorPickerColorComponents;
begin
  AddCell(TACLColorPickerSubClassPreviewCell.Create(SubClass), FPreview);
  AddCell(TACLColorPickerSubClassGamutCell.Create(SubClass), FGamut);
  AddCell(TACLColorPickerSubClassLightnessSliderCell.Create(SubClass), FSlider1);
  if SubClass.Options.AllowEditAlpha then
    AddCell(TACLColorPickerSubClassAlphaSliderCell.Create(SubClass), FSlider2)
  else
    FSlider2 := nil;

  AComponents := [Low(AComponent)..High(AComponent)];
  if not SubClass.Options.AllowEditAlpha then
    Exclude(AComponents, cpccA);
  for AComponent := Low(AComponent) to High(AComponent) do
  begin
    if AComponent in AComponents then
      AddCell(TACLColorPickerSubClassSpinEditCell.Create(SubClass, AComponent), FEdits[AComponent])
    else
      FEdits[AComponent] := nil;
  end;

  AddCell(TACLColorPickerSubClassHexCodeEditCell.Create(SubClass), FHexCode);
end;

function TACLColorPickerSubClassViewInfo.GetSubClass: TACLColorPickerSubClass;
begin
  Result := TACLColorPickerSubClass(inherited SubClass);
end;

{ TACLColorPickerSubClassGamutCell }

procedure TACLColorPickerSubClassGamutCell.DragMove(X, Y: Integer);
begin
  X := Min(acRectWidth(ContentBounds), Max(0, X - ContentBounds.Left));
  Y := Min(acRectHeight(ContentBounds), Max(0, Y - ContentBounds.Top));
  ColorInfo.H := X / acRectWidth(ContentBounds);
  ColorInfo.S := 1 - Y / acRectHeight(ContentBounds);
  CursorPosition := Point(X, Y);
end;

function TACLColorPickerSubClassGamutCell.MeasureSize: TSize;
begin
  Result := acSize(ScaleFactor.Apply(200));
end;

function TACLColorPickerSubClassGamutCell.CalculateCursorPosition: TPoint;
begin
  Result := Point(Round(acRectWidth(ContentBounds) * ColorInfo.H), Round(acRectHeight(ContentBounds) * (1 - ColorInfo.S)));
end;

procedure TACLColorPickerSubClassGamutCell.UpdateContentCache(ACanvas: TCanvas; AWidth, AHeight: Integer);
var
  I: Integer;
begin
  GpPaintCanvas.BeginPaint(ACanvas.Handle);
  try
    for I := 0 to AWidth - 1 do
    begin
      GpPaintCanvas.FillRectangleByGradient(
        TAlphaColor.FromColor(TACLColors.HSLToRGB(I / AWidth, 1, 0.5)),
        TAlphaColor.FromColor(TACLColors.HSLToRGB(I / AWidth, 0, 0.5)),
        Rect(I, 0, I + 1, AHeight), gmVertical);
    end;
  finally
    GpPaintCanvas.EndPaint;
  end;
end;

procedure TACLColorPickerSubClassGamutCell.DrawContent(ACanvas: TCanvas);
begin
  inherited DrawContent(ACanvas);
  DrawCursor(ACanvas);
end;

procedure TACLColorPickerSubClassGamutCell.DrawCursor(ACanvas: TCanvas);
const
  LineThin = 3;
  LineWidth = 5;
  AreaSize = (LineWidth + LineThin) * 2 + LineThin;
var
  R: TRect;
begin
  R := System.Classes.Bounds(CursorPosition.X - AreaSize div 2, CursorPosition.Y - AreaSize div 2, AreaSize, AreaSize);
  R := acRectOffset(R, ContentBounds.TopLeft);

  ACanvas.Brush.Color := GetCursorColor;
  ACanvas.FillRect(acRectSetWidth(acRectCenterVertically(R, LineThin), LineWidth));
  ACanvas.FillRect(acRectSetRight(acRectCenterVertically(R, LineThin), R.Right, LineWidth));
  ACanvas.FillRect(acRectSetHeight(acRectCenterHorizontally(R, LineThin), LineWidth));
  ACanvas.FillRect(acRectSetBottom(acRectCenterHorizontally(R, LineThin), R.Bottom, LineWidth));
end;

{ TACLColorPickerSubClassSliderCell }

function TACLColorPickerSubClassSliderCell.MeasureSize: TSize;
begin
  Result := acSize(ScaleFactor.Apply(20));
end;

procedure TACLColorPickerSubClassSliderCell.DrawArrow(ACanvas: TCanvas);
var
  R1, R2: TRect;
  I: Integer;
begin
  R1 := ArrowBounds;
  R2 := acRectSetRight(R1, R1.Right, 1);
  ACanvas.Brush.Color := Painter.Style.ColorText.AsColor;
  for I := R1.Left to R1.Right - 1 do
  begin
    ACanvas.FillRect(R2);
    R2 := acRectInflate(R2, 0, -1);
    R2 := acRectOffset(R2, -1, 0);
  end;
end;

procedure TACLColorPickerSubClassSliderCell.DrawContent(ACanvas: TCanvas);
begin
  inherited DrawContent(ACanvas);
  DrawArrow(ACanvas);
end;

function TACLColorPickerSubClassSliderCell.GetArrowBounds: TRect;
begin
  Result := acRectSetRight(Bounds, Bounds.Right, accpSliderArrowWidth);
  Result := acRectSetHeight(Result, accpSliderArrowWidth * 2 - 1);
  Result := acRectOffset(Result, 0, CursorPosition.Y);
end;

function TACLColorPickerSubClassSliderCell.GetContentBounds: TRect;
begin
  Result := inherited GetContentBounds;
  Result := acRectInflate(Result, 0, -accpSliderArrowWidth + Painter.BorderSize);
  Result.Right := ArrowBounds.Left - acTextIndent - Painter.BorderSize;
end;

{ TACLColorPickerSubClassAlphaSliderCell }

function TACLColorPickerSubClassAlphaSliderCell.CalculateCursorPosition: TPoint;
begin
  Result := Point(0, MulDiv(acRectHeight(ContentBounds), ColorInfo.Alpha, MaxByte));
end;

procedure TACLColorPickerSubClassAlphaSliderCell.DragMove(X, Y: Integer);
begin
  Y := Min(acRectHeight(ContentBounds), Max(0, Y - ContentBounds.Top));
  ColorInfo.Alpha := Round(MaxByte * Y / acRectHeight(ContentBounds));
  CursorPosition := Point(0, Y);
end;

procedure TACLColorPickerSubClassAlphaSliderCell.UpdateContentCache(ACanvas: TCanvas; AWidth, AHeight: Integer);
begin
  Painter.StyleHatch.Draw(ACanvas, Rect(0, 0, AWidth, AHeight), 2);
  GpPaintCanvas.BeginPaint(ACanvas.Handle);
  try
    GpPaintCanvas.FillRectangleByGradient(0, TAlphaColor.FromColor(ColorInfo.Color), Rect(0, 0, AWidth, AHeight), gmVertical);
  finally
    GpPaintCanvas.EndPaint;
  end;
end;

{ TACLColorPickerSubClassLightnessSliderCell }

procedure TACLColorPickerSubClassLightnessSliderCell.DragMove(X, Y: Integer);
begin
  Y := Min(acRectHeight(ContentBounds), Max(0, Y - ContentBounds.Top));
  ColorInfo.L := 1 - Y / acRectHeight(ContentBounds);
  CursorPosition := Point(0, Y);
end;

function TACLColorPickerSubClassLightnessSliderCell.CalculateCursorPosition: TPoint;
begin
  Result := Point(0, Round((1 - ColorInfo.L) * acRectHeight(ContentBounds)));
end;

procedure TACLColorPickerSubClassLightnessSliderCell.UpdateContentCache(ACanvas: TCanvas; AWidth, AHeight: Integer);
var
  AColor: TAlphaColor;
begin
  GpPaintCanvas.BeginPaint(ACanvas.Handle);
  try
    AColor := TAlphaColor.FromColor(TACLColors.HSLtoRGB(ColorInfo.H, ColorInfo.S, 0.5));
    GpPaintCanvas.FillRectangleByGradient($FFFFFFFF, AColor, Rect(0, 0, AWidth, AHeight div 2), gmVertical);
    GpPaintCanvas.FillRectangleByGradient(AColor, $FF000000, Rect(0, AHeight div 2, AWidth, AHeight), gmVertical);
  finally
    GpPaintCanvas.EndPaint;
  end;
end;

{ TACLColorPickerSubClassPreviewCell }

procedure TACLColorPickerSubClassPreviewCell.DoDraw(ACanvas: TCanvas);
var
  R: TRect;
begin
  R := Bounds;
  Painter.DrawBorder(ACanvas, R);
  R := acRectInflate(R, -Painter.BorderSize);
  Painter.StyleHatch.Draw(ACanvas, R, 2);
  acFillRect(ACanvas.Handle, R, ColorInfo.AlphaColor);
end;

function TACLColorPickerSubClassPreviewCell.MeasureSize: TSize;
begin
  Result := acSize(ScaleFactor.Apply(48));
end;

procedure TACLColorPickerSubClassPreviewCell.UpdateEditValue;
begin
  Invalidate;
end;

{ TACLColorPickerSubClassCustomEditCell }

constructor TACLColorPickerSubClassCustomEditCell.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited Create(ASubClass);
  FEdit := CreateEdit;
  FEdit.Parent := SubClass.Container.GetControl;
  TACLCustomEditAccess(FEdit).SetTargetDPI(SubClass.TargetDPI);
  if csDesigning in SubClass.Container.GetControl.ComponentState then
    TComponentAccess(FEdit).SetDesigning(True);
end;

destructor TACLColorPickerSubClassCustomEditCell.Destroy;
begin
  FreeAndNil(FEdit);
  inherited Destroy;
end;

procedure TACLColorPickerSubClassCustomEditCell.DoCalculate(AChanges: TIntegerSet);
begin
  if [cccnStruct, cccnLayout] * AChanges <> [] then
    FEdit.BoundsRect := acRectSetRight(Bounds, Bounds.Right, MeasureEditWidth);
  inherited DoCalculate(AChanges);
end;

procedure TACLColorPickerSubClassCustomEditCell.DoDraw(ACanvas: TCanvas);
begin
  ACanvas.Font := SubClass.Font;
  ACanvas.Font.Color := SubClass.Style.TextColors[SubClass.EnabledContent];
  ACanvas.Brush.Style := bsClear;
  acTextDraw(ACanvas, GetCaption, Bounds, taLeftJustify, taVerticalCenter);
end;

function TACLColorPickerSubClassCustomEditCell.IsCaptured: Boolean;
begin
  Result := inherited IsCaptured or FEdit.Focused;
end;

function TACLColorPickerSubClassCustomEditCell.MeasureSize: TSize;
begin
  Result.cx := acTextSize(SubClass.Font, GetCaption).cx + ScaleFactor.Apply(accpIndentBetweenElements) + MeasureEditWidth;
  Result.cy := FEdit.Height;
end;

{ TACLColorPickerSubClassCustomSpinEditCell }

function TACLColorPickerSubClassCustomSpinEditCell.CreateEdit: TACLCustomEdit;
var
  AEdit: TACLSpinEdit;
begin
  AEdit := TACLSpinEdit.Create(SubClass);
  AEdit.ResourceCollection := SubClass.ResourceCollection;
  AEdit.Style := SubClass.StyleEdit;
  AEdit.StyleButton := SubClass.StyleEditButton;
  AEdit.OptionsValue.MaxValue := 255;
  AEdit.OptionsValue.MinValue := 0;
  AEdit.OnChange := EditChangeHandler;
  Result := AEdit;
end;

procedure TACLColorPickerSubClassCustomSpinEditCell.EditChangeHandler(Sender: TObject);
begin
  if not FUpdateLocked then
    SetValue(TACLSpinEdit(FEdit).Value);
end;

function TACLColorPickerSubClassCustomSpinEditCell.MeasureEditWidth: Integer;
begin
  Result := CalculateTextFieldSize(SubClass.Font, 3) +
    TACLSpinEdit(FEdit).StyleButton.Texture.FrameWidth * 2 + 4 * acTextIndent;
end;

procedure TACLColorPickerSubClassCustomSpinEditCell.UpdateEditValue;
begin
  TACLSpinEdit(FEdit).Value := GetValue;
  TACLSpinEdit(FEdit).Update;
end;

{ TACLColorPickerSubClassSpinEditCell }

constructor TACLColorPickerSubClassSpinEditCell.Create(
  ASubClass: TACLCompoundControlSubClass; AType: TACLColorPickerColorComponent);
begin
  FType := AType;
  inherited Create(ASubClass);
end;

function TACLColorPickerSubClassSpinEditCell.GetCaption: string;
const
  Map: array[TACLColorPickerColorComponent] of string = ('A:', 'R:', 'G:', 'B:', 'H:', 'S:', 'L:');
begin
  Result := Map[FType];
end;

function TACLColorPickerSubClassSpinEditCell.GetValue: Integer;
begin
  Result := 0;
  case FType of
    cpccA: Result := ColorInfo.Alpha;
    cpccR: Result := ColorInfo.R;
    cpccG: Result := ColorInfo.G;
    cpccB: Result := ColorInfo.B;
    cpccH: Result := Round(ColorInfo.H * 255);
    cpccS: Result := Round(ColorInfo.S * 255);
    cpccL: Result := Round(ColorInfo.L * 255);
  end;
end;

procedure TACLColorPickerSubClassSpinEditCell.SetValue(AValue: Integer);
begin
  case FType of
    cpccA: ColorInfo.Alpha := AValue;
    cpccR: ColorInfo.R := AValue;
    cpccG: ColorInfo.G := AValue;
    cpccB: ColorInfo.B := AValue;
    cpccH: ColorInfo.H := AValue / 255;
    cpccS: ColorInfo.S := AValue / 255;
    cpccL: ColorInfo.L := AValue / 255;
  end;
end;

{ TACLColorPickerSubClassHexCodeEditCell }

function TACLColorPickerSubClassHexCodeEditCell.CreateEdit: TACLCustomEdit;
begin
  Result := TACLEdit.Create(SubClass);
  TACLEdit(Result).ResourceCollection := SubClass.ResourceCollection;
  TACLEdit(Result).Style := SubClass.StyleEdit;
  TACLEdit(Result).MaxLength := IfThen(SubClass.Options.AllowEditAlpha, 8, 6);
  TACLEdit(Result).OnChange := EditChangeHandler;
  TACLEdit(Result).OnKeyPress := EditKeyPressHandler;
end;

function TACLColorPickerSubClassHexCodeEditCell.GetCaption: string;
begin
  Result := '#';
end;

function TACLColorPickerSubClassHexCodeEditCell.MeasureEditWidth: Integer;
begin
  Result := CalculateTextFieldSize(SubClass.Font, 8) + 6 * acTextIndent;
end;

procedure TACLColorPickerSubClassHexCodeEditCell.UpdateEditValue;
begin
  if SubClass.Options.AllowEditAlpha then
    TACLEdit(FEdit).Value := ColorInfo.AlphaColor.ToString
  else
    TACLEdit(FEdit).Value := ColorToString(ColorInfo.Color);

  FEdit.Update;
end;

procedure TACLColorPickerSubClassHexCodeEditCell.EditChangeHandler(Sender: TObject);
begin
  if not FUpdateLocked then
    ColorInfo.AlphaColor := TAlphaColor.FromString(TACLEdit(FEdit).Value);
end;

procedure TACLColorPickerSubClassHexCodeEditCell.EditKeyPressHandler(Sender: TObject; var AKey: Char);
begin
{$WARNINGS OFF}
  if TCharacter.IsControl(AKey) or TCharacter.IsDigit(AKey) then
    Exit;
  if TCharacter.IsLetter(AKey) and CharInSet(AKey, ['a'..'f', 'A'..'F']) then
    Exit;
{$WARNINGS ON}
  AKey := #0;
end;

{ TACLColorPickerOptions }

procedure TACLColorPickerOptions.AfterConstruction;
begin
  inherited AfterConstruction;
  FAllowEditAlpha := True;
end;

procedure TACLColorPickerOptions.DoAssign(Source: TPersistent);
begin
  if Source is TACLColorPickerOptions then
    AllowEditAlpha := TACLColorPickerOptions(Source).AllowEditAlpha;
end;

procedure TACLColorPickerOptions.DoChanged(AChanges: TACLPersistentChanges);
begin
  CallNotifyEvent(Self, FOnChange);
end;

procedure TACLColorPickerOptions.SetAllowEditAlpha(const Value: Boolean);
begin
  SetBooleanFieldValue(FAllowEditAlpha, Value);
end;

{ TACLCustomColorPicker }

constructor TACLCustomColorPicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBorders := acAllBorders;
  FocusOnClick := True;
  AutoSize := True;
end;

procedure TACLCustomColorPicker.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var
  AMinWidth, AMinHeight: Integer;
begin
  if not AutoSize and SubClass.CalculateAutoSize(AMinWidth, AMinHeight) then
  begin
    AHeight := Max(AHeight, AMinHeight);
    AWidth := Max(AWidth, AMinWidth);
  end;
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
end;

function TACLCustomColorPicker.AllowCompositionPainting: Boolean;
begin
  Result := False;
end;

function TACLCustomColorPicker.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLColorPickerSubClass.Create(Self);
end;

procedure TACLCustomColorPicker.DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.DrawContent(ACanvas, R);
end;

procedure TACLCustomColorPicker.Paint;
begin
  Style.DrawBorder(Canvas, ClientRect, Borders);
  inherited Paint;
end;

procedure TACLCustomColorPicker.PaintWindow(DC: HDC);
var
  I: Integer;
begin
  for I := 0 to ControlCount - 1 do
    acExcludeFromClipRegion(DC, Controls[I].BoundsRect);
  inherited PaintWindow(DC);
end;

function TACLCustomColorPicker.GetColor: TAlphaColor;
begin
  Result := SubClass.Color.AlphaColor;
  if (Result <> 0) and not Options.AllowEditAlpha then
    Result.A := MaxByte;
end;

function TACLCustomColorPicker.GetContentOffset: TRect;
begin
  Result := acMarginGetReal(ScaleFactor.Apply(acBorderOffsets), Borders);
end;

function TACLCustomColorPicker.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if Transparent then
    Result := cbsTransparent
  else
    if Style.IsTransparentBackground then
      Result := cbsSemitransparent
    else
      Result := cbsOpaque;
end;

function TACLCustomColorPicker.GetOnColorChanged: TNotifyEvent;
begin
  Result := SubClass.OnColorChanged;
end;

function TACLCustomColorPicker.GetOptions: TACLColorPickerOptions;
begin
  Result := SubClass.Options;
end;

function TACLCustomColorPicker.GetStyle: TACLStyleContent;
begin
  Result := SubClass.Style;
end;

function TACLCustomColorPicker.GetStyleEdit: TACLStyleEdit;
begin
  Result := SubClass.StyleEdit;
end;

function TACLCustomColorPicker.GetStyleEditButton: TACLStyleButton;
begin
  Result := SubClass.StyleEditButton;
end;

function TACLCustomColorPicker.GetStyleHatch: TACLStyleHatch;
begin
  Result := SubClass.StyleHatch;
end;

function TACLCustomColorPicker.GetSubClass: TACLColorPickerSubClass;
begin
  Result := TACLColorPickerSubClass(inherited SubClass);
end;

procedure TACLCustomColorPicker.SetBorders(const Value: TACLBorders);
begin
  if Value <> FBorders then
  begin
    FBorders := Value;
    AdjustSize;
    Realign;
    Invalidate;
  end;
end;

procedure TACLCustomColorPicker.SetColor(const Value: TAlphaColor);
begin
  SubClass.Color.AlphaColor := Value;
end;

procedure TACLCustomColorPicker.SetOnColorChanged(const Value: TNotifyEvent);
begin
  SubClass.OnColorChanged := Value;
end;

procedure TACLCustomColorPicker.SetOptions(const Value: TACLColorPickerOptions);
begin
  SubClass.Options.Assign(Value);
end;

procedure TACLCustomColorPicker.SetStyle(const Value: TACLStyleContent);
begin
  SubClass.Style.Assign(Value);
end;

procedure TACLCustomColorPicker.SetStyleEdit(const Value: TACLStyleEdit);
begin
  SubClass.StyleEdit.Assign(Value);
end;

procedure TACLCustomColorPicker.SetStyleEditButton(const Value: TACLStyleButton);
begin
  SubClass.StyleEditButton.Assign(Value);
end;

procedure TACLCustomColorPicker.SetStyleHatch(const Value: TACLStyleHatch);
begin
  SubClass.StyleHatch.Assign(Value);
end;

end.
