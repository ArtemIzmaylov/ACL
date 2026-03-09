////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Color Picker
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.ColorPicker;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Character,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // Vcl
  {Vcl.}Graphics,
  {Vcl.}Controls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.UI.Controls.Base,
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
  TACLColorPickerColorModifierCell = class;
  TACLColorPickerPainter = class;

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
    // Events
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  { TACLColorPickerSubClass }

  TACLColorPickerSubClass = class(TACLCompoundControlSubClass)
  strict private
    FColor: TACLColorPickerColorInfo;
    FOptions: TACLColorPickerOptions;
    FPainter: TACLColorPickerPainter;
    FStyle: TACLStyleContent;
    FStyleEdit: TACLStyleEdit;
    FStyleEditButton: TACLStyleButton;
    FStyleHatch: TACLStyleHatch;
    FTargetDPI: Integer;

    FOnColorChanged: TNotifyEvent;

    procedure ColorChangeHandler(Sender: TObject);
    procedure OptionsChangeHandler(Sender: TObject);
  protected
    function CreateViewInfo: TACLCompoundControlCustomViewInfo; override;
    function GetFullRefreshChanges: TIntegerSet; override;
    procedure ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState); override;
  public
    constructor Create(AOwner: IACLCompoundControlSubClassContainer);
    destructor Destroy; override;
    procedure CalculateAutoSize(var AWidth, AHeight: Integer; AMinSize: Boolean); override;
    procedure SetTargetDPI(AValue: Integer); override;
    // Properties
    property Color: TACLColorPickerColorInfo read FColor;
    property Options: TACLColorPickerOptions read FOptions;
    property Painter: TACLColorPickerPainter read FPainter;
    property Style: TACLStyleContent read FStyle;
    property StyleEdit: TACLStyleEdit read FStyleEdit;
    property StyleEditButton: TACLStyleButton read FStyleEditButton;
    property StyleHatch: TACLStyleHatch read FStyleHatch;
    property TargetDPI: Integer read FTargetDPI;
    // Events
    property OnColorChanged: TNotifyEvent read FOnColorChanged write FOnColorChanged;
  end;

  { TACLColorPickerPainter }

  TACLColorPickerPainter = class(TACLCompoundControlPersistent)
  strict private
    function GetStyle: TACLStyleContent;
    function GetStyleHatch: TACLStyleHatch;
  public
    function BorderSize: Integer; virtual;
    procedure DrawBorder(ACanvas: TCanvas; const R: TRect); virtual;
    // Properties
    property Style: TACLStyleContent read GetStyle;
    property StyleHatch: TACLStyleHatch read GetStyleHatch;
  end;

  { TACLColorPickerViewInfo }

  TACLColorPickerViewInfo = class(TACLCompoundControlContainerViewInfo)
  strict private
    FCreating: Boolean;
    function GetSubClass: TACLColorPickerSubClass;
  protected
    FIndentBetweenElements: Integer;
    FEdits: array[TACLColorPickerColorComponent] of TACLColorPickerColorModifierCell;
    FGamut: TACLColorPickerColorModifierCell;
    FHexCode: TACLColorPickerColorModifierCell;
    FPreview: TACLColorPickerColorModifierCell;
    FSlider1: TACLColorPickerColorModifierCell;
    FSlider2: TACLColorPickerColorModifierCell;

    procedure CalculateAutoSize(var AWidth, AHeight: Integer; AMinSize: Boolean); virtual;
    procedure CalculateSubCells(const AChanges: TIntegerSet); override;
    procedure CalculateSubCellsEditors(var R: TRect; const AChanges: TIntegerSet);
    procedure CalculateSubCellsSliders(var R: TRect; const AChanges: TIntegerSet);
    function MeasureEditsAreaSize: TSize;
    procedure RecreateSubCells; override;
  public
    procedure Calculate(const R: TRect; AChanges: TIntegerSet); override;
    // Properties
    property SubClass: TACLColorPickerSubClass read GetSubClass;
  end;

  { TACLColorPickerColorModifierCell }

  TACLColorPickerColorModifierCell = class abstract(TACLCompoundControlCustomViewInfo,
    IACLDraggableObject)
  strict private
    function GetColorInfo: TACLColorPickerColorInfo; inline;
    function GetPainter: TACLColorPickerPainter; inline;
    function GetSubClass: TACLColorPickerSubClass; inline;
  protected
    FUpdateLocked: Boolean;

    procedure DoCalculate(AChanges: TIntegerSet); override;
    function IsCaptured: Boolean; virtual;
    procedure UpdateEditValue; virtual; abstract;
    // IACLDraggableObject
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
  public
    procedure DragMove(X, Y: Integer); virtual;
    function MeasureSize: TSize; virtual; abstract;
    // Properties
    property ColorInfo: TACLColorPickerColorInfo read GetColorInfo;
    property Painter: TACLColorPickerPainter read GetPainter;
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
    procedure SetColor(const Value: TAlphaColor); reintroduce;
    procedure SetOnColorChanged(const Value: TNotifyEvent);
    procedure SetOptions(const Value: TACLColorPickerOptions);
    procedure SetStyle(const Value: TACLStyleContent);
    procedure SetStyleEdit(const Value: TACLStyleEdit);
    procedure SetStyleEditButton(const Value: TACLStyleButton);
    procedure SetStyleHatch(const Value: TACLStyleHatch);
  protected
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure CreateParams(var Params: TCreateParams); override;
    function CreatePadding: TACLPadding; override;
    function CreateSubClass: TACLCompoundControlSubClass; override;
    function GetContentOffset: TRect; override;
    procedure Paint; override;
    procedure SetFocusOnClick; override;
    procedure UpdateTransparency; override;
    //# Properties
    property Borders: TACLBorders read FBorders write SetBorders default acAllBorders;
    property Options: TACLColorPickerOptions read GetOptions write SetOptions;
    property Style: TACLStyleContent read GetStyle write SetStyle;
    property StyleEdit: TACLStyleEdit read GetStyleEdit write SetStyleEdit;
    property StyleEditButton: TACLStyleButton read GetStyleEditButton write SetStyleEditButton;
    property StyleHatch: TACLStyleHatch read GetStyleHatch write SetStyleHatch;
    property SubClass: TACLColorPickerSubClass read GetSubClass;
    //# Events
    property OnColorChanged: TNotifyEvent read GetOnColorChanged write SetOnColorChanged;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    //# Properties
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
    property Padding;
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
  ACL.Graphics.Ex,
  ACL.Graphics.SkinImageSet;

type
  TACLCustomEditAccess = class(TACLCustomEdit);

const
  accpSliderArrowWidth = 5;
  accpSliderArrowWidthHalf = 3;
  accpIndentBetweenElements = 6;

type
  { TACLColorPickerColorModifierCellDragObject }

  TACLColorPickerColorModifierCellDragObject = class(TACLCompoundControlDragObject)
  strict private
    FCell: TACLColorPickerColorModifierCell;
  public
    constructor Create(ACell: TACLColorPickerColorModifierCell);
    procedure DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer); override;
    function DragStart: Boolean; override;
  end;

  { TACLColorPickerVisualColorModifierCell }

  TACLColorPickerVisualColorModifierCell = class(TACLColorPickerColorModifierCell)
  strict private
    FContentCache: TACLDib;
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
    //# Properties
    property ContentBounds: TRect read GetContentBounds;
    property ContentFrameRect: TRect read GetContentFrameRect;
    property CursorPosition: TPoint read FCursorPosition write SetCursorPosition;
  end;

  { TACLColorPickerGamutCell }

  TACLColorPickerGamutCell = class(TACLColorPickerVisualColorModifierCell)
  protected
    function CalculateCursorPosition: TPoint; override;
    procedure DrawContent(ACanvas: TCanvas); override;
    procedure DrawCursor(ACanvas: TCanvas); virtual;
    procedure UpdateContentCache(ACanvas: TCanvas; AWidth: Integer; AHeight: Integer); override;
  public
    procedure DragMove(X, Y: Integer); override;
    function MeasureSize: TSize; override;
  end;

  { TACLColorPickerSliderCell }

  TACLColorPickerSliderCell = class(TACLColorPickerVisualColorModifierCell)
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

  { TACLColorPickerAlphaSliderCell }

  TACLColorPickerAlphaSliderCell = class(TACLColorPickerSliderCell)
  protected
    function CalculateCursorPosition: TPoint; override;
    procedure UpdateContentCache(ACanvas: TCanvas; AWidth, AHeight: Integer); override;
  public
    procedure DragMove(X, Y: Integer); override;
  end;

  { TACLColorPickerLightnessSliderCell }

  TACLColorPickerLightnessSliderCell = class(TACLColorPickerSliderCell)
  protected
    function CalculateCursorPosition: TPoint; override;
    procedure UpdateContentCache(ACanvas: TCanvas; AWidth, AHeight: Integer); override;
  public
    procedure DragMove(X, Y: Integer); override;
  end;

  { TACLColorPickerPreviewCell }

  TACLColorPickerPreviewCell = class(TACLColorPickerColorModifierCell)
  protected
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure UpdateEditValue; override;
  public
    function MeasureSize: TSize; override;
  end;

  { TACLColorPickerCustomEditCell }

  TACLColorPickerCustomEditCell = class abstract(TACLColorPickerColorModifierCell)
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

  { TACLColorPickerCustomSpinEditCell }

  TACLColorPickerCustomSpinEditCell = class abstract(TACLColorPickerCustomEditCell)
  strict private
    procedure EditChangeHandler(Sender: TObject);
  protected
    function CreateEdit: TACLCustomEdit; override;
    function GetValue: Integer; virtual; abstract;
    function MeasureEditWidth: Integer; override;
    procedure SetValue(AValue: Integer); virtual; abstract;
    procedure UpdateEditValue; override;
  end;

  { TACLColorPickerSpinEditCell }

  TACLColorPickerSpinEditCell = class(TACLColorPickerCustomSpinEditCell)
  protected
    FType: TACLColorPickerColorComponent;

    function GetCaption: string; override;
    function GetValue: Integer; override;
    procedure SetValue(AValue: Integer); override;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass; AType: TACLColorPickerColorComponent); reintroduce;
  end;

  { TACLColorPickerHexCodeEditCell }

  TACLColorPickerHexCodeEditCell = class(TACLColorPickerCustomEditCell)
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
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'A', 'B', 'C', 'D', 'E', 'F',
    'a', 'b', 'c', 'd', 'e', 'f'
  );
var
  I: Integer;
begin
  Result := 0;
  MeasureCanvas.SetScaledFont(AFont);
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
  Result := TACLColors.HSLtoRGB(H, S, L);
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

{ TACLColorPickerColorModifierCell }

procedure TACLColorPickerColorModifierCell.DoCalculate(AChanges: TIntegerSet);
begin
  inherited DoCalculate(AChanges);

  if (cpcnValue in AChanges) and not IsCaptured then
  begin
    FUpdateLocked := True;
    UpdateEditValue;
    FUpdateLocked := False;
  end;
end;

function TACLColorPickerColorModifierCell.IsCaptured: Boolean;
begin
  Result := Self = SubClass.PressedObject;
end;

procedure TACLColorPickerColorModifierCell.DragMove(X, Y: Integer);
begin
  // do nothing
end;

function TACLColorPickerColorModifierCell.CreateDragObject(
  const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
begin
  Result := TACLColorPickerColorModifierCellDragObject.Create(Self);
end;

function TACLColorPickerColorModifierCell.GetColorInfo: TACLColorPickerColorInfo;
begin
  Result := SubClass.Color;
end;

function TACLColorPickerColorModifierCell.GetPainter: TACLColorPickerPainter;
begin
  Result := SubClass.Painter;
end;

function TACLColorPickerColorModifierCell.GetSubClass: TACLColorPickerSubClass;
begin
  Result := TACLColorPickerSubClass(inherited SubClass);
end;

{ TACLColorPickerColorModifierCellDragObject }

constructor TACLColorPickerColorModifierCellDragObject.Create(ACell: TACLColorPickerColorModifierCell);
begin
  FCell := ACell;
  inherited Create;
end;

procedure TACLColorPickerColorModifierCellDragObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);
begin
  FCell.DragMove(P.X, P.Y);
end;

function TACLColorPickerColorModifierCellDragObject.DragStart: Boolean;
begin
  Result := True;
end;

{ TACLColorPickerVisualColorModifierCell }

destructor TACLColorPickerVisualColorModifierCell.Destroy;
begin
  FlushContentCache;
  inherited Destroy;
end;

procedure TACLColorPickerVisualColorModifierCell.DoCalculate(AChanges: TIntegerSet);
begin
  inherited DoCalculate(AChanges);

  if (FContentCache = nil) or (cccnStruct in AChanges) or
    (FContentCache.Width <> ContentBounds.Width) or
    (FContentCache.Height <> ContentBounds.Height) then
  begin
    FlushContentCache;
    UpdateEditValue;
  end;
end;

procedure TACLColorPickerVisualColorModifierCell.DoDraw(ACanvas: TCanvas);
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

procedure TACLColorPickerVisualColorModifierCell.DrawContent(ACanvas: TCanvas);
begin
  FContentCache.DrawCopy(ACanvas, ContentBounds.TopLeft);
end;

procedure TACLColorPickerVisualColorModifierCell.FlushContentCache;
begin
  FreeAndNil(FContentCache);
end;

function TACLColorPickerVisualColorModifierCell.GetContentBounds: TRect;
begin
  Result := Bounds;
  Result.Inflate(-Painter.BorderSize);
end;

function TACLColorPickerVisualColorModifierCell.GetContentFrameRect: TRect;
begin
  Result := ContentBounds;
  Result.Inflate(Painter.BorderSize);
end;

function TACLColorPickerVisualColorModifierCell.GetCursorColor: TColor;
begin
  Result := clBlack;
end;

procedure TACLColorPickerVisualColorModifierCell.UpdateContentCache;
begin
  FlushContentCache;
  FContentCache := TACLDib.Create(ContentBounds);
  UpdateContentCache(FContentCache.Canvas, FContentCache.Width, FContentCache.Height);
end;

procedure TACLColorPickerVisualColorModifierCell.UpdateEditValue;
begin
  CursorPosition := CalculateCursorPosition;
  FlushContentCache;
  Invalidate;
end;

procedure TACLColorPickerVisualColorModifierCell.SetCursorPosition(const AValue: TPoint);
begin
  if FCursorPosition <> AValue then
  begin
    FCursorPosition := AValue;
    Invalidate;
  end;
end;

{ TACLColorPickerSubClass }

constructor TACLColorPickerSubClass.Create(AOwner: IACLCompoundControlSubClassContainer);
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
  FPainter := TACLColorPickerPainter.Create(Self);
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

function TACLColorPickerSubClass.GetFullRefreshChanges: TIntegerSet;
begin
  Result := inherited + [cpcnValue];
end;

procedure TACLColorPickerSubClass.CalculateAutoSize(var AWidth, AHeight: Integer; AMinSize: Boolean);
begin
  TACLColorPickerViewInfo(ViewInfo).CalculateAutoSize(AWidth, AHeight, AMinSize);
end;

procedure TACLColorPickerSubClass.SetTargetDPI(AValue: Integer);
begin
  FTargetDPI := AValue;
  Style.TargetDPI := AValue;
  inherited SetTargetDPI(AValue);
end;

function TACLColorPickerSubClass.CreateViewInfo: TACLCompoundControlCustomViewInfo;
begin
  Result := TACLColorPickerViewInfo.Create(Self);
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
  if HitTest.HitObject is TACLColorPickerColorModifierCell then
    TACLColorPickerColorModifierCell(HitTest.HitObject).DragMove(HitTest.Point.X, HitTest.Point.Y);
end;

{ TACLColorPickerPainter }

function TACLColorPickerPainter.BorderSize: Integer;
begin
  Result := 2;
end;

procedure TACLColorPickerPainter.DrawBorder(ACanvas: TCanvas; const R: TRect);
begin
  Style.DrawBorder(ACanvas, R, acAllBorders);
end;

function TACLColorPickerPainter.GetStyle: TACLStyleContent;
begin
  Result := TACLColorPickerSubClass(SubClass).Style;
end;

function TACLColorPickerPainter.GetStyleHatch: TACLStyleHatch;
begin
  Result := TACLColorPickerSubClass(SubClass).StyleHatch;
end;

{ TACLColorPickerViewInfo }

procedure TACLColorPickerViewInfo.Calculate(const R: TRect; AChanges: TIntegerSet);
begin
  inherited;
  FIndentBetweenElements := dpiApply(accpIndentBetweenElements, CurrentDpi);
end;

procedure TACLColorPickerViewInfo.CalculateAutoSize(var AWidth, AHeight: Integer; AMinSize: Boolean);

  procedure Include(const ASize: TSize);
  begin
    if not ASize.IsEmpty then
    begin
      Inc(AWidth, ASize.cx);
      Inc(AWidth, FIndentBetweenElements);
      AHeight := Max(AHeight, ASize.cy);
    end;
  end;

var
  LSize: TSize;
begin
  if FCreating then Exit;

  AWidth := 0;
  AHeight := 0;

  if FSlider1 <> nil then
    Include(FSlider1.MeasureSize);
  if FSlider2 <> nil then
    Include(FSlider2.MeasureSize);
  Include(MeasureEditsAreaSize);

  if FGamut <> nil then
  begin
    LSize := FGamut.MeasureSize;
    if not AMinSize then
      LSize := TSize.Create(Max(AHeight, LSize.cy));
    Include(LSize);
  end;
end;

procedure TACLColorPickerViewInfo.CalculateSubCells(const AChanges: TIntegerSet);
var
  LRect: TRect;
begin
  inherited;
  LRect := Bounds;
  CalculateSubCellsEditors(LRect, AChanges);
  CalculateSubCellsSliders(LRect, AChanges);
  if FGamut <> nil then
    FGamut.Calculate(LRect, AChanges);
end;

procedure TACLColorPickerViewInfo.CalculateSubCellsEditors(var R: TRect; const AChanges: TIntegerSet);

  function PlaceCell(ACell: TACLColorPickerColorModifierCell; var R: TRect): Boolean;
  var
    LCellRect: TRect;
  begin
    Result := ACell <> nil;
    if Result then
    begin
      LCellRect := R;
      LCellRect.Height := ACell.MeasureSize.cy;
      ACell.Calculate(LCellRect, AChanges);
      R.Top := ACell.Bounds.Bottom + FIndentBetweenElements;
    end;
  end;

var
  LComponent: TACLColorPickerColorComponent;
  LPreview: TRect;
  LRect: TRect;
begin
  LRect := R.Split(srRight, MeasureEditsAreaSize.cx);
  if FPreview <> nil then
  begin
    LPreview := LRect;
    LPreview.Height := LPreview.Width;
    FPreview.Calculate(LPreview, AChanges);
    LRect.Top := FPreview.Bounds.Bottom + FIndentBetweenElements;
  end;
  for LComponent := Low(LComponent) to High(LComponent) do
  begin
    if PlaceCell(FEdits[LComponent], LRect) and (LComponent in [cpccA, cpccB, cpccL]) then
      Inc(LRect.Top, FIndentBetweenElements);
  end;
  PlaceCell(FHexCode, LRect);
  R.Right := LRect.Left - FIndentBetweenElements;
end;

procedure TACLColorPickerViewInfo.CalculateSubCellsSliders(var R: TRect; const AChanges: TIntegerSet);

  procedure Place(var R: TRect; ACell: TACLColorPickerColorModifierCell);
  begin
    if ACell <> nil then
    begin
      ACell.Calculate(R.Split(srRight, ACell.MeasureSize.cx), AChanges);
      R.Right := ACell.Bounds.Left - FIndentBetweenElements;
    end;
  end;

begin
  R.Inflate(0, accpSliderArrowWidthHalf);
  Place(R, FSlider2);
  Place(R, FSlider1);
  R.Inflate(0, -accpSliderArrowWidthHalf);
end;

function TACLColorPickerViewInfo.MeasureEditsAreaSize: TSize;

  procedure Include(const ACellSize: TSize; var ASize: TSize);
  begin
    ASize.cx := Max(ASize.cx, ACellSize.cx);
    Inc(ASize.cy, ACellSize.cy + FIndentBetweenElements);
  end;

var
  LCell: TACLColorPickerColorModifierCell;
  LComponent: TACLColorPickerColorComponent;
begin
  Result := NullSize;
  for LComponent := Low(LComponent) to High(LComponent) do
  begin
    LCell := FEdits[LComponent];
    if LCell <> nil then
    begin
      Include(LCell.MeasureSize, Result);
      if LComponent in [cpccA, cpccB, cpccL] then
        Inc(Result.cy, FIndentBetweenElements);
    end;
  end;
  if FHexCode <> nil then
    Include(FHexCode.MeasureSize, Result);
  if FPreview <> nil then
    Include(TSize.Create(Result.cx), Result);
  if Result.cy > 0 then
    Dec(Result.cy, FIndentBetweenElements);
end;

procedure TACLColorPickerViewInfo.RecreateSubCells;
var
  LComponent: TACLColorPickerColorComponent;
  LComponents: TACLColorPickerColorComponents;
begin
  FCreating := True;
  try
    inherited;
    AddCell(TACLColorPickerPreviewCell.Create(SubClass), FPreview);
    AddCell(TACLColorPickerGamutCell.Create(SubClass), FGamut);
    AddCell(TACLColorPickerLightnessSliderCell.Create(SubClass), FSlider1);
    if SubClass.Options.AllowEditAlpha then
      AddCell(TACLColorPickerAlphaSliderCell.Create(SubClass), FSlider2)
    else
      FSlider2 := nil;

    LComponents := [Low(LComponent)..High(LComponent)];
    if not SubClass.Options.AllowEditAlpha then
      Exclude(LComponents, cpccA);
    for LComponent := Low(LComponent) to High(LComponent) do
    begin
      if LComponent in LComponents then
        AddCell(TACLColorPickerSpinEditCell.Create(SubClass, LComponent), FEdits[LComponent])
      else
        FEdits[LComponent] := nil;
    end;

    AddCell(TACLColorPickerHexCodeEditCell.Create(SubClass), FHexCode);
  finally
    FCreating := False;
  end;
end;

function TACLColorPickerViewInfo.GetSubClass: TACLColorPickerSubClass;
begin
  Result := TACLColorPickerSubClass(inherited SubClass);
end;

{ TACLColorPickerGamutCell }

procedure TACLColorPickerGamutCell.DragMove(X, Y: Integer);
begin
  X := Min(ContentBounds.Width, Max(0, X - ContentBounds.Left));
  Y := Min(ContentBounds.Height, Max(0, Y - ContentBounds.Top));
  ColorInfo.H := X / ContentBounds.Width;
  ColorInfo.S := 1 - Y / ContentBounds.Height;
  CursorPosition := Point(X, Y);
end;

function TACLColorPickerGamutCell.MeasureSize: TSize;
begin
  Result := TSize.Create(dpiApply(200, CurrentDpi));
end;

function TACLColorPickerGamutCell.CalculateCursorPosition: TPoint;
begin
  Result := Point(
    Round(ContentBounds.Width * ColorInfo.H),
    Round(ContentBounds.Height * (1 - ColorInfo.S)));
end;

procedure TACLColorPickerGamutCell.UpdateContentCache(ACanvas: TCanvas; AWidth, AHeight: Integer);
var
  I: Integer;
begin
  ExPainter.BeginPaint(ACanvas);
  try
    for I := 0 to AWidth - 1 do
    begin
      ExPainter.FillRectangleByGradient(Rect(I, 0, I + 1, AHeight),
        TAlphaColor.FromColor(TACLColors.HSLToRGB(I / AWidth, 1, 0.5)),
        TAlphaColor.FromColor(TACLColors.HSLToRGB(I / AWidth, 0, 0.5)),
        True);
    end;
  finally
    ExPainter.EndPaint;
  end;
end;

procedure TACLColorPickerGamutCell.DrawContent(ACanvas: TCanvas);
begin
  inherited DrawContent(ACanvas);
  DrawCursor(ACanvas);
end;

procedure TACLColorPickerGamutCell.DrawCursor(ACanvas: TCanvas);
const
  LineThin = 3;
  LineWidth = 5;
  AreaSize = (LineWidth + LineThin) * 2 + LineThin;
var
  LLine: TRect;
  LRect: TRect;
begin
  LRect := {System.}Classes.Bounds(
    CursorPosition.X - AreaSize div 2,
    CursorPosition.Y - AreaSize div 2, AreaSize, AreaSize);
  LRect.Offset(ContentBounds.TopLeft);

  ACanvas.Brush.Color := GetCursorColor;

  LLine := LRect;
  LLine.CenterVert(LineThin);
  ACanvas.FillRect(LLine.Split(srLeft, LineWidth));
  ACanvas.FillRect(LLine.Split(srRight, LRect.Right, LineWidth));

  LLine := LRect;
  LLine.CenterHorz(LineThin);
  ACanvas.FillRect(LLine.Split(srTop, LineWidth));
  ACanvas.FillRect(LLine.Split(srBottom, LRect.Bottom, LineWidth));
end;

{ TACLColorPickerSliderCell }

function TACLColorPickerSliderCell.MeasureSize: TSize;
begin
  Result := TSize.Create(dpiApply(20, CurrentDpi));
end;

procedure TACLColorPickerSliderCell.DrawArrow(ACanvas: TCanvas);
var
  R1, R2: TRect;
  I: Integer;
begin
  R1 := ArrowBounds;
  R2 := ArrowBounds.Split(srRight, 1);
  ACanvas.Brush.Color := Painter.Style.ColorText.AsColor;
  for I := R1.Left to R1.Right - 1 do
  begin
    ACanvas.FillRect(R2);
    R2.Inflate(0, -1);
    R2.Offset(-1, 0);
  end;
end;

procedure TACLColorPickerSliderCell.DrawContent(ACanvas: TCanvas);
begin
  inherited DrawContent(ACanvas);
  DrawArrow(ACanvas);
end;

function TACLColorPickerSliderCell.GetArrowBounds: TRect;
begin
  Result := Bounds.Split(srRight, accpSliderArrowWidth);
  Result.Height := accpSliderArrowWidth * 2 - 1;
  Result.Offset(0, CursorPosition.Y);
end;

function TACLColorPickerSliderCell.GetContentBounds: TRect;
begin
  Result := inherited GetContentBounds;
  Result.Inflate(0, -accpSliderArrowWidth + Painter.BorderSize);
  Result.Right := ArrowBounds.Left - acTextIndent - Painter.BorderSize;
end;

{ TACLColorPickerAlphaSliderCell }

function TACLColorPickerAlphaSliderCell.CalculateCursorPosition: TPoint;
begin
  Result := Point(0, MulDiv(ContentBounds.Height, ColorInfo.Alpha, MaxByte));
end;

procedure TACLColorPickerAlphaSliderCell.DragMove(X, Y: Integer);
begin
  Y := Min(ContentBounds.Height, Max(0, Y - ContentBounds.Top));
  ColorInfo.Alpha := Round(MaxByte * Y / ContentBounds.Height);
  CursorPosition := Point(0, Y);
end;

procedure TACLColorPickerAlphaSliderCell.UpdateContentCache(ACanvas: TCanvas; AWidth, AHeight: Integer);
begin
  Painter.StyleHatch.Draw(ACanvas, Rect(0, 0, AWidth, AHeight), 2);
  ExPainter.BeginPaint(ACanvas);
  try
    ExPainter.FillRectangleByGradient(Rect(0, 0, AWidth, AHeight),
      TAlphaColor.None, TAlphaColor.FromColor(ColorInfo.Color), True);
  finally
    ExPainter.EndPaint;
  end;
end;

{ TACLColorPickerLightnessSliderCell }

procedure TACLColorPickerLightnessSliderCell.DragMove(X, Y: Integer);
begin
  Y := Min(ContentBounds.Height, Max(0, Y - ContentBounds.Top));
  ColorInfo.L := 1 - Y / ContentBounds.Height;
  CursorPosition := Point(0, Y);
end;

function TACLColorPickerLightnessSliderCell.CalculateCursorPosition: TPoint;
begin
  Result := Point(0, Round((1 - ColorInfo.L) * ContentBounds.Height));
end;

procedure TACLColorPickerLightnessSliderCell.UpdateContentCache(ACanvas: TCanvas; AWidth, AHeight: Integer);
var
  AColor: TAlphaColor;
begin
  ExPainter.BeginPaint(ACanvas);
  try
    AColor := TAlphaColor.FromColor(TACLColors.HSLtoRGB(ColorInfo.H, ColorInfo.S, 0.5));
    ExPainter.FillRectangleByGradient(
      Rect(0, 0, AWidth, AHeight div 2), $FFFFFFFF, AColor, True);
    ExPainter.FillRectangleByGradient(
      Rect(0, AHeight div 2, AWidth, AHeight), AColor, $FF000000, True);
  finally
    ExPainter.EndPaint;
  end;
end;

{ TACLColorPickerPreviewCell }

procedure TACLColorPickerPreviewCell.DoDraw(ACanvas: TCanvas);
var
  R: TRect;
begin
  R := Bounds;
  Painter.DrawBorder(ACanvas, R);
  R.Inflate(-Painter.BorderSize);
  Painter.StyleHatch.Draw(ACanvas, R, 2);
  acFillRect(ACanvas, R, ColorInfo.AlphaColor);
end;

function TACLColorPickerPreviewCell.MeasureSize: TSize;
begin
  Result := TSize.Create(dpiApply(48, CurrentDpi));
end;

procedure TACLColorPickerPreviewCell.UpdateEditValue;
begin
  Invalidate;
end;

{ TACLColorPickerCustomEditCell }

constructor TACLColorPickerCustomEditCell.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited Create(ASubClass);
  FEdit := CreateEdit;
  FEdit.Align := alCustom;
  FEdit.Parent := SubClass.Container.GetControl;
  TACLCustomEditAccess(FEdit).SetTargetDPI(SubClass.TargetDPI);
  if csDesigning in SubClass.Container.GetControl.ComponentState then
    TACLCustomEditAccess(FEdit).SetDesigning(True);
end;

destructor TACLColorPickerCustomEditCell.Destroy;
begin
  FreeAndNil(FEdit);
  inherited Destroy;
end;

procedure TACLColorPickerCustomEditCell.DoCalculate(AChanges: TIntegerSet);
begin
  if [cccnStruct, cccnLayout] * AChanges <> [] then
    FEdit.BoundsRect := Bounds.Split(srRight, MeasureEditWidth);
  inherited DoCalculate(AChanges);
end;

procedure TACLColorPickerCustomEditCell.DoDraw(ACanvas: TCanvas);
begin
  ACanvas.Font := SubClass.Font;
  ACanvas.Font.Color := SubClass.Style.TextColors[SubClass.EnabledContent];
  ACanvas.Brush.Style := bsClear;
  acTextDraw(ACanvas, GetCaption, Bounds, taLeftJustify, taVerticalCenter);
end;

function TACLColorPickerCustomEditCell.IsCaptured: Boolean;
begin
  Result := inherited IsCaptured or FEdit.Focused;
end;

function TACLColorPickerCustomEditCell.MeasureSize: TSize;
begin
  Result.cx := acTextSize(SubClass.Font, GetCaption).cx +
    dpiApply(accpIndentBetweenElements, CurrentDpi) + MeasureEditWidth;
  Result.cy := FEdit.Height;
end;

{ TACLColorPickerCustomSpinEditCell }

function TACLColorPickerCustomSpinEditCell.CreateEdit: TACLCustomEdit;
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

procedure TACLColorPickerCustomSpinEditCell.EditChangeHandler(Sender: TObject);
begin
  if not FUpdateLocked then
    SetValue(TACLSpinEdit(FEdit).Value);
end;

function TACLColorPickerCustomSpinEditCell.MeasureEditWidth: Integer;
begin
  Result := CalculateTextFieldSize(SubClass.Font, 3) +
    TACLSpinEdit(FEdit).StyleButton.Texture.FrameWidth * 2 + 4 * acTextIndent;
end;

procedure TACLColorPickerCustomSpinEditCell.UpdateEditValue;
begin
  TACLSpinEdit(FEdit).Value := GetValue;
  TACLSpinEdit(FEdit).Update;
end;

{ TACLColorPickerSpinEditCell }

constructor TACLColorPickerSpinEditCell.Create(
  ASubClass: TACLCompoundControlSubClass; AType: TACLColorPickerColorComponent);
begin
  FType := AType;
  inherited Create(ASubClass);
end;

function TACLColorPickerSpinEditCell.GetCaption: string;
const
  Map: array[TACLColorPickerColorComponent] of string = ('A:', 'R:', 'G:', 'B:', 'H:', 'S:', 'L:');
begin
  Result := Map[FType];
end;

function TACLColorPickerSpinEditCell.GetValue: Integer;
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

procedure TACLColorPickerSpinEditCell.SetValue(AValue: Integer);
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

{ TACLColorPickerHexCodeEditCell }

function TACLColorPickerHexCodeEditCell.CreateEdit: TACLCustomEdit;
begin
  Result := TACLEdit.Create(SubClass);
  TACLEdit(Result).ResourceCollection := SubClass.ResourceCollection;
  TACLEdit(Result).Style := SubClass.StyleEdit;
  TACLEdit(Result).MaxLength := IfThen(SubClass.Options.AllowEditAlpha, 8, 6);
  TACLEdit(Result).OnChange := EditChangeHandler;
  TACLEdit(Result).OnKeyPress := EditKeyPressHandler;
end;

function TACLColorPickerHexCodeEditCell.GetCaption: string;
begin
  Result := '#';
end;

function TACLColorPickerHexCodeEditCell.MeasureEditWidth: Integer;
begin
  Result := CalculateTextFieldSize(SubClass.Font, 8) + 6 * acTextIndent;
end;

procedure TACLColorPickerHexCodeEditCell.UpdateEditValue;
begin
  if ColorInfo.Alpha = 0 then
    TACLEdit(FEdit).Value := ''
  else if SubClass.Options.AllowEditAlpha then
    TACLEdit(FEdit).Value := ColorInfo.AlphaColor.ToString
  else
    TACLEdit(FEdit).Value := ColorToString(ColorInfo.Color);

  FEdit.Update;
end;

procedure TACLColorPickerHexCodeEditCell.EditChangeHandler(Sender: TObject);
begin
  if not FUpdateLocked then
    ColorInfo.AlphaColor := TAlphaColor.FromString(TACLEdit(FEdit).Value);
end;

procedure TACLColorPickerHexCodeEditCell.EditKeyPressHandler(Sender: TObject; var AKey: Char);
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

function TACLCustomColorPicker.CreatePadding: TACLPadding;
begin
  Result := TACLPadding.Create(6);
end;

procedure TACLCustomColorPicker.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := Params.Style or WS_CLIPCHILDREN;
end;

procedure TACLCustomColorPicker.AlignControls(AControl: TControl; var Rect: TRect);
begin
  // do nothing
end;

function TACLCustomColorPicker.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLColorPickerSubClass.Create(Self);
end;

procedure TACLCustomColorPicker.Paint;
begin
  Style.Draw(Canvas, ClientRect, Transparent, Borders);
  inherited Paint;
end;

function TACLCustomColorPicker.GetColor: TAlphaColor;
begin
  Result := SubClass.Color.AlphaColor;
  if (Result <> 0) and not Options.AllowEditAlpha then
    Result.A := MaxByte;
end;

function TACLCustomColorPicker.GetContentOffset: TRect;
begin
  Result := dpiApply(acBorderOffsets, FCurrentPPI) * Borders;
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

procedure TACLCustomColorPicker.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var
  LWidth, LHeight: Integer;
begin
  if not AutoSize then
  begin
    LHeight := AHeight;
    LWidth := AWidth;
    CalculateAutoSize(LWidth, LHeight, True);
    AHeight := Max(AHeight, LHeight);
    AWidth := Max(AWidth, LWidth);
  end;
  inherited;
end;

procedure TACLCustomColorPicker.SetColor(const Value: TAlphaColor);
begin
  SubClass.Color.AlphaColor := Value;
end;

procedure TACLCustomColorPicker.SetFocusOnClick;
begin
  acSafeSetFocus(Self);
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

procedure TACLCustomColorPicker.UpdateTransparency;
begin
  if Transparent or Style.IsTransparentBackground then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque];
end;

end.
