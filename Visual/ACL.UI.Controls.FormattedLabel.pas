{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*        Label with Formatted Text          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.FormattedLabel;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  // ACL
  ACL.Classes,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.TextLayout,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.FileSystem,
  ACL.Utils.Shell,
  ACL.Utils.Strings;

const
  flhtHyperlink = 'Hyperlink';

type
  TACLFormattedLabelSubClass = class;
  TACLFormattedLabelViewInfo = class;

  TACLFormattedLabelLinkExecuteEvent = procedure (Sender: TObject;
    const ALink: string; var AHandled: Boolean) of object;

  { TACLStyleFormattedLabel }

  TACLStyleFormattedLabel = class(TACLStyleContent)
  protected
    procedure InitializeResources; override;
  published
    property ColorTextHyperlink: TACLResourceColor index 10 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLFormattedLabelFormattedText }

  TACLFormattedLabelFormattedText = class(TACLTextLayout)
  strict private
    FOwner: TACLFormattedLabelSubClass;
  protected
    function GetDefaultHyperLinkColor: TColor; override;
    function GetDefaultTextColor: TColor; override;
  public
    constructor Create(AOwner: TACLFormattedLabelSubClass);
  end;

  { TACLFormattedLabelOptions }

  TACLFormattedLabelOption = (floAutoDetectEmails, floAutoDetectURLs, floAutoDetectTimeCodes);
  TACLFormattedLabelOptions = set of TACLFormattedLabelOption;

  { TACLFormattedLabelSubClass }

  TACLFormattedLabelSubClass = class(TACLCompoundControlSubClass)
  strict private
    FAutoScroll: Boolean;
    FFormattedText: TACLFormattedLabelFormattedText;
    FOptions: TACLFormattedLabelOptions;
    FStyle: TACLStyleFormattedLabel;

    FOnLinkExecute: TACLFormattedLabelLinkExecuteEvent;

    function GetAlignment: TAlignment;
    function GetText: string;
    function GetViewInfo: TACLFormattedLabelViewInfo; inline;
    function GetWordWrap: Boolean;
    procedure SetAlignment(AValue: TAlignment);
    procedure SetAutoScroll(AValue: Boolean);
    procedure SetOptions(AValue: TACLFormattedLabelOptions);
    procedure SetText(const AValue: string);
    procedure SetTextCore(const AValue: string);
    procedure SetWordWrap(AValue: Boolean);
  protected
    function CreateViewInfo: TACLCompoundControlCustomViewInfo; override;
    procedure ExecuteLink(const ALink: string);
    procedure ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState); override;
    //# Properties
    property FormattedText: TACLFormattedLabelFormattedText read FFormattedText;
    property ViewInfo: TACLFormattedLabelViewInfo read GetViewInfo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure MakeVisible(ARow: Integer);
    procedure SetTargetDPI(AValue: Integer); override;
    //# Properties
    property Alignment: TAlignment read GetAlignment write SetAlignment;
    property AutoScroll: Boolean read FAutoScroll write SetAutoScroll;
    property Options: TACLFormattedLabelOptions read FOptions write SetOptions;
    property Style: TACLStyleFormattedLabel read FStyle;
    property Text: string read GetText write SetText;
    property WordWrap: Boolean read GetWordWrap write SetWordWrap;
    //# Events
    property OnLinkExecute: TACLFormattedLabelLinkExecuteEvent read FOnLinkExecute write FOnLinkExecute;
  end;

  { TACLFormattedLabelViewInfo }

  TACLFormattedLabelViewInfo = class(TACLCompoundControlScrollContainerViewInfo)
  strict private
    function GetFormattedText: TACLFormattedLabelFormattedText; inline;
    function GetOrigin: TPoint;
    function GetSubClass: TACLFormattedLabelSubClass; inline;
  protected
    procedure CalculateContentLayout; override;
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDrawCells(ACanvas: TCanvas); override;
  public
    property FormattedText: TACLFormattedLabelFormattedText read GetFormattedText;
    property SubClass: TACLFormattedLabelSubClass read GetSubClass;
  end;

  { TACLFormattedLabel }

  TACLFormattedLabel = class(TACLCompoundControl)
  strict private
    FBorders: TACLBorders;

    function GetAlignment: TAlignment; inline;
    function GetAutoScroll: Boolean; inline;
    function GetOnLinkExecute: TACLFormattedLabelLinkExecuteEvent;
    function GetOptions: TACLFormattedLabelOptions;
    function GetStyle: TACLStyleFormattedLabel;
    function GetSubClass: TACLFormattedLabelSubClass; inline;
    function GetText: string; inline;
    function GetWordWrap: Boolean; inline;
    procedure SetAlignment(AValue: TAlignment); inline;
    procedure SetAutoScroll(AValue: Boolean); inline;
    procedure SetBorders(AValue: TACLBorders);
    procedure SetOnLinkExecute(AValue: TACLFormattedLabelLinkExecuteEvent);
    procedure SetOptions(AValue: TACLFormattedLabelOptions);
    procedure SetStyle(AValue: TACLStyleFormattedLabel);
    procedure SetText(const AValue: string); inline;
    procedure SetWordWrap(AValue: Boolean); inline;
    // Backward compatibility
    procedure ReadText(Reader: TReader);
  protected
    function CreateSubClass: TACLCompoundControlSubClass; override;
    procedure DefineProperties(Filer: TFiler); override;
    function GetContentOffset: TRect; override;
    procedure Paint; override;
    procedure ResourceChanged; override;
    procedure SetDefaultSize; override;
    procedure SetTargetDPI(AValue: Integer); override;
  public const
    DefaultOptions = [floAutoDetectURLs, floAutoDetectEmails];
  public
    constructor Create(AOwner: TComponent); override;
    procedure MakeVisible(ARow: Integer);
    //# Properties
    property SubClass: TACLFormattedLabelSubClass read GetSubClass;
  published
    property Alignment: TAlignment read GetAlignment write SetAlignment default taLeftJustify;
    property AutoScroll: Boolean read GetAutoScroll write SetAutoScroll default True;
    property Borders: TACLBorders read FBorders write SetBorders default [];
    property Caption: string read GetText write SetText;
    property FocusOnClick default True;
    property Padding;
    property ResourceCollection;
    property Options: TACLFormattedLabelOptions read GetOptions write SetOptions default DefaultOptions;
    property Style: TACLStyleFormattedLabel read GetStyle write SetStyle;
    property StyleScrollBox;
    property Transparent;
    property WordWrap: Boolean read GetWordWrap write SetWordWrap default True;
    //# Events
    property OnCalculated;
    property OnLinkExecute: TACLFormattedLabelLinkExecuteEvent read GetOnLinkExecute write SetOnLinkExecute;
    property OnUpdateState;
  end;

implementation

{ TACLStyleFormattedLabel }

procedure TACLStyleFormattedLabel.InitializeResources;
begin
  ColorBorder1.InitailizeDefaults('Common.Colors.Border1', True);
  ColorBorder2.InitailizeDefaults('Common.Colors.Border2', True);
  ColorContent1.InitailizeDefaults('Labels.Colors.Background', True);
  ColorContent2.InitailizeDefaults('Labels.Colors.Background', True);
  ColorText.InitailizeDefaults('Labels.Colors.Text');
  ColorTextDisabled.InitailizeDefaults('Labels.Colors.TextDisabled');
  ColorTextHyperlink.InitailizeDefaults('Labels.Colors.TextHyperlink');
end;

{ TACLFormattedLabelFormattedText }

constructor TACLFormattedLabelFormattedText.Create(AOwner: TACLFormattedLabelSubClass);
begin
  inherited Create(AOwner.Font);
  FOwner := AOwner;
end;

function TACLFormattedLabelFormattedText.GetDefaultHyperLinkColor: TColor;
begin
  if FOwner.EnabledContent then
    Result := FOwner.Style.ColorTextHyperlink.AsColor
  else
    Result := FOwner.Style.ColorTextDisabled.AsColor;
end;

function TACLFormattedLabelFormattedText.GetDefaultTextColor: TColor;
begin
  Result := FOwner.Style.TextColors[FOwner.EnabledContent];
end;

{ TACLFormattedLabelSubClass }

constructor TACLFormattedLabelSubClass.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoScroll := True;
  FOptions := TACLFormattedLabel.DefaultOptions;
  FStyle := TACLStyleFormattedLabel.Create(Self);
  FFormattedText := TACLFormattedLabelFormattedText.Create(Self);
  FFormattedText.SetOption(atoWordWrap, True);
end;

destructor TACLFormattedLabelSubClass.Destroy;
begin
  FreeAndNil(FFormattedText);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLFormattedLabelSubClass.MakeVisible(ARow: Integer);
var
  ABounds: TRect;
  ARowRect: TRect;
begin
  FormattedText.Calculate(MeasureCanvas);
  ABounds := ViewInfo.ClientBounds;
  ARowRect := FormattedText.FLayout[ARow].Bounds;
  ViewInfo.ViewportY := ViewInfo.ViewportY + acCalculateScrollToDelta(
    ARowRect.Top, ARowRect.Bottom, ABounds.Top + ViewInfo.ViewportY,
    ABounds.Bottom + ViewInfo.ViewportY, TACLScrollToMode.MakeVisible);
end;

function TACLFormattedLabelSubClass.CreateViewInfo: TACLCompoundControlCustomViewInfo;
begin
  Result := TACLFormattedLabelViewInfo.Create(Self);
end;

function TACLFormattedLabelSubClass.GetAlignment: TAlignment;
begin
  Result := FormattedText.HorzAlignment;
end;

function TACLFormattedLabelSubClass.GetText: string;
begin
  Result := FormattedText.Text;
end;

function TACLFormattedLabelSubClass.GetViewInfo: TACLFormattedLabelViewInfo;
begin
  Result := TACLFormattedLabelViewInfo(inherited ViewInfo);
end;

function TACLFormattedLabelSubClass.GetWordWrap: Boolean;
begin
  Result := atoWordWrap and FormattedText.Options <> 0;
end;

procedure TACLFormattedLabelSubClass.SetAlignment(AValue: TAlignment);
begin
  if Alignment <> AValue then
  begin
    FormattedText.HorzAlignment := AValue;
    FullRefresh;
  end;
end;

procedure TACLFormattedLabelSubClass.SetAutoScroll(AValue: Boolean);
begin
  if FAutoScroll <> AValue then
  begin
    FAutoScroll := AValue;
    FullRefresh;
  end;
end;

procedure TACLFormattedLabelSubClass.SetOptions(AValue: TACLFormattedLabelOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;
    SetTextCore(Text);
  end;
end;

procedure TACLFormattedLabelSubClass.SetTargetDPI(AValue: Integer);
begin
  inherited;
  FormattedText.TargetDpi := AValue;
end;

procedure TACLFormattedLabelSubClass.SetText(const AValue: string);
begin
  if Text <> AValue then
    SetTextCore(AValue);
end;

procedure TACLFormattedLabelSubClass.SetTextCore(const AValue: string);
var
  ASettings: TACLTextFormatSettings;
begin
  ASettings := TACLTextFormatSettings.Default;
  ASettings.AllowAutoEmailDetect := floAutoDetectEmails in Options;
  ASettings.AllowAutoTimeCodeDetect := floAutoDetectTimeCodes in Options;
  ASettings.AllowAutoURLDetect := floAutoDetectURLs in Options;
  FormattedText.SetText(AValue, ASettings);
  FullRefresh;
end;

procedure TACLFormattedLabelSubClass.SetWordWrap(AValue: Boolean);
begin
  if WordWrap <> AValue then
  begin
    FormattedText.SetOption(atoWordWrap, AValue);
    FullRefresh;
  end;
end;

procedure TACLFormattedLabelSubClass.ExecuteLink(const ALink: string);
var
  AHandled: Boolean;
begin
  AHandled := False;
  if Assigned(OnLinkExecute) then
    OnLinkExecute(Self, ALink, AHandled);
  if not AHandled and acIsUrlFileName(ALink) then
    ShellExecuteURL(ALink);
end;

procedure TACLFormattedLabelSubClass.ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState);
var
  AHyperlink: TACLTextLayoutBlockHyperlink;
begin
  AHyperlink := TACLTextLayoutBlockHyperlink(HitTest.HitObjectData[flhtHyperlink]);
  if AHyperlink <> nil then
    ExecuteLink(AHyperlink.Hyperlink)
  else
    inherited ProcessMouseClick(AButton, AShift);
end;

procedure TACLFormattedLabelSubClass.ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);
begin
  TACLFormattedLabelViewInfo(ViewInfo).ScrollByMouseWheel(ADirection, AShift);
end;

{ TACLFormattedLabelViewInfo }

procedure TACLFormattedLabelViewInfo.CalculateContentLayout;
begin
  if SubClass.AutoScroll then
  begin
    FormattedText.Bounds := Rect(0, 0, FClientBounds.Width, MaxInt);
    FormattedText.SetOption(atoEndEllipsis, False);
    FormattedText.Calculate(MeasureCanvas);
    FContentSize := FormattedText.MeasureSize;
  end
  else
  begin
    FContentSize := FClientBounds.Size;
    FormattedText.Bounds := TRect.Create(FContentSize);
    FormattedText.SetOption(atoEndEllipsis, True);
  end;
end;

procedure TACLFormattedLabelViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
var
  AHitTest: TACLTextLayoutHitTest;
begin
  AHitTest := TACLTextLayoutHitTest.Create(FormattedText);
  try
    FormattedText.HitTest(AInfo.HitPoint - GetOrigin, AHitTest);
    AInfo.HitObject := AHitTest.HitObject;
    AInfo.HitObjectData[flhtHyperlink] := AHitTest.Hyperlink;
    if AHitTest.Hyperlink <> nil then
      AInfo.Cursor := crHandPoint;
  finally
    AHitTest.Free;
  end;
end;

procedure TACLFormattedLabelViewInfo.DoDrawCells(ACanvas: TCanvas);
begin
  FormattedText.DrawTo(ACanvas, Bounds, GetOrigin);
end;

function TACLFormattedLabelViewInfo.GetFormattedText: TACLFormattedLabelFormattedText;
begin
  Result := SubClass.FormattedText;
end;

function TACLFormattedLabelViewInfo.GetOrigin: TPoint;
begin
  Result := ClientBounds.TopLeft - Point(ViewportX, ViewportY);
end;

function TACLFormattedLabelViewInfo.GetSubClass: TACLFormattedLabelSubClass;
begin
  Result := TACLFormattedLabelSubClass(inherited SubClass);
end;

{ TACLFormattedLabel }

constructor TACLFormattedLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBorders := [];
  FocusOnClick := True;
end;

procedure TACLFormattedLabel.MakeVisible(ARow: Integer);
begin
  SubClass.MakeVisible(ARow);
end;

procedure TACLFormattedLabel.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Style.TargetDPI := AValue;
end;

function TACLFormattedLabel.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLFormattedLabelSubClass.Create(Self);
end;

procedure TACLFormattedLabel.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('Text', ReadText, nil, False);
end;

function TACLFormattedLabel.GetContentOffset: TRect;
begin
  Result := dpiApply(acBorderOffsets, FCurrentPPI) * Borders;
end;

procedure TACLFormattedLabel.Paint;
begin
  Style.Draw(Canvas, ClientRect, Transparent, Borders);
  inherited Paint;
end;

procedure TACLFormattedLabel.ResourceChanged;
begin
  SubClass.FormattedText.FlushCalculatedValues;
  inherited;
end;

function TACLFormattedLabel.GetAlignment: TAlignment;
begin
  Result := SubClass.Alignment;
end;

function TACLFormattedLabel.GetAutoScroll: Boolean;
begin
  Result := SubClass.AutoScroll;
end;

function TACLFormattedLabel.GetOnLinkExecute: TACLFormattedLabelLinkExecuteEvent;
begin
  Result := SubClass.OnLinkExecute
end;

function TACLFormattedLabel.GetOptions: TACLFormattedLabelOptions;
begin
  Result := SubClass.Options;
end;

function TACLFormattedLabel.GetStyle: TACLStyleFormattedLabel;
begin
  Result := SubClass.Style;
end;

function TACLFormattedLabel.GetSubClass: TACLFormattedLabelSubClass;
begin
  Result := TACLFormattedLabelSubClass(inherited SubClass);
end;

function TACLFormattedLabel.GetText: string;
begin
  Result := SubClass.Text;
end;

function TACLFormattedLabel.GetWordWrap: Boolean;
begin
  Result := SubClass.WordWrap;
end;

procedure TACLFormattedLabel.SetAlignment(AValue: TAlignment);
begin
  SubClass.Alignment := AValue;
end;

procedure TACLFormattedLabel.SetAutoScroll(AValue: Boolean);
begin
  SubClass.AutoScroll := AValue;
end;

procedure TACLFormattedLabel.SetBorders(AValue: TACLBorders);
begin
  if FBorders <> AValue then
  begin
    FBorders := AValue;
    ResourceChanged;
  end;
end;

procedure TACLFormattedLabel.SetDefaultSize;
begin
  SetBounds(Left, Top, 75, 15);
end;

procedure TACLFormattedLabel.SetOnLinkExecute(AValue: TACLFormattedLabelLinkExecuteEvent);
begin
  SubClass.OnLinkExecute := AValue;
end;

procedure TACLFormattedLabel.SetOptions(AValue: TACLFormattedLabelOptions);
begin
  SubClass.Options := AValue;
end;

procedure TACLFormattedLabel.SetStyle(AValue: TACLStyleFormattedLabel);
begin
  SubClass.Style.Assign(AValue);
end;

procedure TACLFormattedLabel.SetText(const AValue: string);
begin
  SubClass.Text := AValue;
end;

procedure TACLFormattedLabel.SetWordWrap(AValue: Boolean);
begin
  SubClass.WordWrap := AValue;
end;

procedure TACLFormattedLabel.ReadText(Reader: TReader);
begin
  Caption := Reader.ReadString;
end;

end.
