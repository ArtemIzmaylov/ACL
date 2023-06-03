{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Category Controls             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Category;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.Classes,
  System.Math,
  System.SysUtils,
  System.Types,
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

type

  { TACLStyleCategory }

  TACLStyleCategory = class(TACLStyleBackground)
  strict private
    FHeaderTextAlignment: TAlignment;

    procedure SetHeaderTextAlignment(AValue: TAlignment);
  protected
    procedure DoAssign(ASource: TPersistent); override;
    procedure InitializeResources; override;
  public
    procedure DrawHeader(DC: HDC; const R: TRect);
    procedure DrawHeaderText(ACanvas: TCanvas; const R: TRect; const AText: UnicodeString);
  published
    property HeaderColorContent1: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
    property HeaderColorContent2: TACLResourceColor index 5 read GetColor write SetColor stored IsColorStored;
    property HeaderTextAlignment: TAlignment read FHeaderTextAlignment write SetHeaderTextAlignment default taCenter;
    property HeaderTextFont: TACLResourceFont index 0 read GetFont write SetFont stored IsFontStored;
  end;

  { TACLCategory }

  TACLCategory = class(TACLContainer)
  strict private
    FCaption: UnicodeString;
    FCaptionRect: TRect;
    FFrameRect: TRect;

    function GetStyle: TACLStyleCategory;
    procedure SetCaption(const AValue: UnicodeString);
    procedure SetStyle(const Value: TACLStyleCategory);
  protected
    procedure BoundsChanged; override;
    function CalculateTextSize: TSize;
    function CreatePadding: TACLPadding; override;
    function CreateStyle: TACLStyleBackground; override;
    function GetContentOffset: TRect; override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property AutoSize;
    property Borders;
    property Caption: UnicodeString read FCaption write SetCaption;
    property Padding;
    property Style: TACLStyleCategory read GetStyle write SetStyle;
  end;

implementation

{ TACLStyleCategory }

procedure TACLStyleCategory.DoAssign(ASource: TPersistent);
begin
  inherited DoAssign(ASource);
  if ASource is TACLStyleCategory then
    HeaderTextAlignment := TACLStyleCategory(ASource).HeaderTextAlignment;
end;

procedure TACLStyleCategory.InitializeResources;
begin
  HeaderTextAlignment := taCenter;
  ColorBorder1.InitailizeDefaults('Category.Colors.Border1', True);
  ColorBorder2.InitailizeDefaults('Category.Colors.Border2', True);
  ColorContent1.InitailizeDefaults('Category.Colors.Background1', True);
  ColorContent2.InitailizeDefaults('Category.Colors.Background2', True);
  HeaderColorContent1.InitailizeDefaults('Category.Colors.Header1', True);
  HeaderColorContent2.InitailizeDefaults('Category.Colors.Header2', True);
  HeaderTextFont.InitailizeDefaults('Category.Fonts.Header');
end;

procedure TACLStyleCategory.DrawHeader(DC: HDC; const R: TRect);
begin
  acDrawGradient(DC, R, HeaderColorContent1.AsColor, HeaderColorContent2.AsColor);
  acDrawFrame(DC, R, ColorBorder1.AsColor);
end;

procedure TACLStyleCategory.DrawHeaderText(ACanvas: TCanvas; const R: TRect; const AText: UnicodeString);
begin
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Assign(HeaderTextFont);
  acTextDraw(ACanvas, AText, acRectInflate(R, -4, 0), HeaderTextAlignment, taVerticalCenter);
end;

procedure TACLStyleCategory.SetHeaderTextAlignment(AValue: TAlignment);
begin
  if AValue <> FHeaderTextAlignment then
  begin
    FHeaderTextAlignment := AValue;
    Changed;
  end;
end;

{ TACLCategory }

constructor TACLCategory.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
end;

procedure TACLCategory.BoundsChanged;
begin
  inherited;
  FFrameRect := ClientRect;
  FCaptionRect := acRectSetHeight(FFrameRect, Max(CalculateTextSize.cy + 8, 22));
  FFrameRect.Top := FCaptionRect.Bottom;
  Realign;
end;

function TACLCategory.CalculateTextSize: TSize;
begin
  MeasureCanvas.Font.Assign(Style.HeaderTextFont);
  Result := acTextSize(MeasureCanvas, Caption);
end;

function TACLCategory.CreatePadding: TACLPadding;
begin
  Result := TACLPadding.Create(5);
end;

function TACLCategory.CreateStyle: TACLStyleBackground;
begin
  Result := TACLStyleCategory.Create(Self);
end;

function TACLCategory.GetContentOffset: TRect;
begin
  Result := inherited;
  Result.Top := FCaptionRect.Bottom + dpiApply(1, FCurrentPPI);
end;

function TACLCategory.GetStyle: TACLStyleCategory;
begin
  Result := TACLStyleCategory(inherited Style);
end;

procedure TACLCategory.Paint;
begin
  inherited;
  Style.DrawHeader(Canvas.Handle, FCaptionRect);
  Style.DrawHeaderText(Canvas, FCaptionRect, Caption);
end;

procedure TACLCategory.SetCaption(const AValue: UnicodeString);
begin
  if AValue <> FCaption then
  begin
    FCaption := AValue;
    FullRefresh;
  end;
end;

procedure TACLCategory.SetStyle(const Value: TACLStyleCategory);
begin
  Style.Assign(Value);
end;

end.
