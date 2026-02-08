////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   GroupBox
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.GroupBox;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.Buttons,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

type
  TACLGroupBox = class;

  { TACLCustomGroupBox }

  TACLCustomGroupBox = class(TACLContainer, IACLCursorProvider)
  strict private
    FCaptionSubClass: TACLCheckBoxSubClass;
    FDescription: string;
    FStyleCaption: TACLStyleCheckBox;

    procedure CheckBoxClickHandler(Sender: TObject);
    function GetCaption: string;
    procedure SetCaption(const AValue: string);
    procedure SetDescription(const AValue: string);
    procedure SetStyleCaption(AValue: TACLStyleCheckBox);
  protected
    FCaptionRect: TRect;
    FDescriptionRect: TRect;
    FFrameRect: TRect;

    procedure Calculate(const R: TRect); virtual;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    function CreatePadding: TACLPadding; override;
    function CreateStyleCaption: TACLStyleCheckBox; virtual; abstract;

    procedure AdjustClientRect(var Rect: TRect); override;
    procedure BoundsChanged; override;
    procedure FocusChanged; override;
    function GetContentOffset: TRect; override;
    procedure ResourceChanged; override;
    procedure SetTargetDPI(AValue: Integer); override;

    // Events
    procedure DoCheckBoxClick; virtual;

    // Drawing
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect);
    procedure Paint; override;

    // IACLCursorProvider
    function GetCursor(const P: TPoint): TCursor; reintroduce;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Properties
    property CaptionSubClass: TACLCheckBoxSubClass read FCaptionSubClass;
  published
    property Anchors;
    property AutoSize;
    property Borders;
    property Caption: string read GetCaption write SetCaption;
    property Description: string read FDescription write SetDescription;
    property DoubleBuffered default True;
    property Padding;
    property StyleCaption: TACLStyleCheckBox read FStyleCaption write SetStyleCaption;
    property Transparent;
  end;

  { TACLGroupBoxCheckBox }

  TACLGroupBoxCheckBoxAction = (cbaNone, cbaToggleChildrenEnableState, cbaToggleMinimizeState);

  TACLGroupBoxCheckBox = class(TPersistent)
  strict private
    FAction: TACLGroupBoxCheckBoxAction;
    FOwner: TACLGroupBox;

    function GetChecked: Boolean;
    function GetVisible: Boolean;
    procedure SetAction(AValue: TACLGroupBoxCheckBoxAction);
    procedure SetChecked(AValue: Boolean);
    procedure SetVisible(AValue: Boolean);
  protected
    procedure AssignTo(ATarget: TPersistent); override;
  public
    constructor Create(AOwner: TACLGroupBox);
    procedure Toggle;
  published
    property Action: TACLGroupBoxCheckBoxAction read FAction write SetAction default cbaNone;
    property Checked: Boolean read GetChecked write SetChecked default True;
    property Visible: Boolean read GetVisible write SetVisible default False;
  end;

  { TACLGroupBox }

  TACLGroupBox = class(TACLCustomGroupBox)
  strict private
    FCheckBox: TACLGroupBoxCheckBox;
    FDisabledChildren: TList;
    FMinimized: Boolean;
    FRestoredHeight: Integer;

    FOnCheckBoxStateChanged: TNotifyEvent;

    procedure SetCheckBox(AValue: TACLGroupBoxCheckBox);
    procedure SetMinimized(AValue: Boolean);
    // backward compatibility
    procedure ReadCheckBoxMode(Reader: TReader);
    procedure ReadCheckBoxState(Reader: TReader);
  private
    procedure DisableChildren;
    procedure EnableChildren;
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure ApplyCheckBoxState(AFireEvent: Boolean = True);
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    function CreateStyleCaption: TACLStyleCheckBox; override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure DoCheckBoxClick; override;
    procedure DoCheckBoxStateChanged;
    procedure DoLoaded; override;
    function GetMinimizeStateHeight: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure GetTabOrderList(List: TTabOrderList); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    //# Properties
    property Minimized: Boolean read FMinimized write SetMinimized;
  published
    property CheckBox: TACLGroupBoxCheckBox read FCheckBox write SetCheckBox;
    property OnCheckBoxStateChanged: TNotifyEvent
      read FOnCheckBoxStateChanged write FOnCheckBoxStateChanged;
  end;

  { TACLGroupBoxCaptionStyle }

  TACLGroupBoxCaptionStyle = class(TACLStyleCheckBox)
  protected
    procedure InitializeResources; override;
  end;

implementation

uses
  ACL.UI.Insight.Core;

type

  { TACLGroupBoxCheckBoxSubClass }

  TACLGroupBoxCheckBoxSubClass = class(TACLCheckBoxSubClass)
  protected
    procedure AssignCanvasParameters(ACanvas: TCanvas); override;
  end;

  { TACLGroupBoxUIInsightAdapter }

  TACLGroupBoxUIInsightAdapter = class(TACLUIInsightAdapterWinControl)
  public
    class function MakeVisible(AObject: TObject): Boolean; override;
  end;

{ TACLCustomGroupBox }

constructor TACLCustomGroupBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  FStyleCaption := CreateStyleCaption;
  RegisterSubClass(FCaptionSubClass, TACLGroupBoxCheckBoxSubClass.Create(Self, StyleCaption));
  CaptionSubClass.Alignment := taLeftJustify;
  CaptionSubClass.CheckState := cbChecked;
  CaptionSubClass.ShowCheckMark := False;
  CaptionSubClass.OnClick := CheckBoxClickHandler;
  DoubleBuffered := True;
end;

destructor TACLCustomGroupBox.Destroy;
begin
  FreeAndNil(FStyleCaption);
  inherited Destroy;
end;

procedure TACLCustomGroupBox.Calculate(const R: TRect);
var
  LHeight: Integer;
  LIndent: Integer;
  LMargins: TRect;
  LWidth: Integer;
begin
  TabStop := CaptionSubClass.ShowCheckMark;
  FocusOnClick := CaptionSubClass.ShowCheckMark;

  FDescriptionRect := NullRect;
  if CaptionSubClass.Caption <> '' then
  begin
    LWidth := -1;
    LHeight := -1;
    CaptionSubClass.CalculateAutoSize(LWidth, LHeight);
    LIndent := dpiApply(acTextIndent, FCurrentPPI);

    FCaptionRect := R;
    LMargins := Padding.GetScaledMargins(FCurrentPPI);
    LMargins.MarginsAdd(GetContentOffset);
    Inc(FCaptionRect.Left, LMargins.Left);
    Dec(FCaptionRect.Right, LMargins.Right);
    FCaptionRect.Height := LHeight;

    if Description <> '' then
    begin
      FDescriptionRect := FCaptionRect.Split(srRight, 2 * LIndent + acTextSize(Font, Description).Width);
      FCaptionRect.Right := FDescriptionRect.Left - dpiApply(16, FCurrentPPI);
    end;

    FCaptionRect.Width := Min(LWidth, FCaptionRect.Width);
    FCaptionSubClass.Calculate(FCaptionRect);
    FCaptionRect.Inflate(LIndent, 0);
  end
  else
  begin
    FCaptionRect := R;
    FCaptionRect.Height := 0;
    CaptionSubClass.Calculate(NullRect);
  end;

  FFrameRect := R;
  FFrameRect.Top := (FCaptionRect.Top + FCaptionRect.Bottom) div 2 + FCaptionRect.Height and $1;
end;

function TACLCustomGroupBox.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  Result := inherited CanAutoSize(NewWidth, NewHeight);
  if not FCaptionRect.IsEmpty then
  begin
    NewHeight := Max(NewHeight, FCaptionRect.Height);
    NewWidth := Max(NewWidth, FCaptionRect.Width);
  end;
end;

function TACLCustomGroupBox.CreatePadding: TACLPadding;
begin
  Result := TACLPadding.Create(8);
end;

procedure TACLCustomGroupBox.AdjustClientRect(var Rect: TRect);
begin
  inherited;
  Rect.Top := Max(Rect.Top, FCaptionRect.Bottom);
end;

procedure TACLCustomGroupBox.BoundsChanged;
begin
  inherited;
  Calculate(ClientRect);
end;

procedure TACLCustomGroupBox.CheckBoxClickHandler(Sender: TObject);
begin
  DoCheckBoxClick;
end;

procedure TACLCustomGroupBox.DoCheckBoxClick;
begin
  // do nothing
end;

procedure TACLCustomGroupBox.FocusChanged;
begin
  inherited FocusChanged;
  CaptionSubClass.IsFocused := Focused;
  Invalidate;
end;

function TACLCustomGroupBox.GetContentOffset: TRect;
begin
  if FCaptionRect.IsEmpty then
    Result := inherited
  else
  begin
    Result := acBorderOffsets;
    Inc(Result.Top, FFrameRect.Top + 1);
  end;
end;

function TACLCustomGroupBox.GetCursor(const P: TPoint): TCursor;
begin
  if CaptionSubClass.ShowCheckMark and PtInRect(CaptionSubClass.Bounds, P) then
    Result := crHandPoint
  else
    Result := Cursor;
end;

procedure TACLCustomGroupBox.ResourceChanged;
begin
  if not (csDestroying in ComponentState) then
    FullRefresh;
  inherited;
end;

procedure TACLCustomGroupBox.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  StyleCaption.TargetDPI := AValue;
end;

procedure TACLCustomGroupBox.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  if not Transparent then
    Style.DrawContent(ACanvas, R);
end;

procedure TACLCustomGroupBox.Paint;
var
  LClipRgn: TRegionHandle;
begin
  DrawBackground(Canvas, ClientRect);
  if FCaptionRect.IsEmpty then
    Style.DrawBorder(Canvas, FFrameRect, Borders)
  else
  begin
    LClipRgn := acSaveClipRegion(Canvas.Handle);
    try
      CaptionSubClass.Draw(Canvas);
      if not FDescriptionRect.IsEmpty then
      begin
        Canvas.Font := Font;
        Canvas.Font.Color := StyleCaption.ColorTextDisabled.AsColor;
        Canvas.Brush.Style := bsClear;
        acTextDraw(Canvas, Description, FDescriptionRect, taCenter);
      end;
      acExcludeFromClipRegion(Canvas.Handle, FCaptionRect);
      acExcludeFromClipRegion(Canvas.Handle, FDescriptionRect);
      Style.DrawBorder(Canvas, FFrameRect, Borders);
    finally
      acRestoreClipRegion(Canvas.Handle, LClipRgn);
    end;
  end;
end;

function TACLCustomGroupBox.GetCaption: string;
begin
  Result := CaptionSubClass.Caption;
end;

procedure TACLCustomGroupBox.SetCaption(const AValue: string);
begin
  if Caption <> AValue then
  begin
    CaptionSubClass.Caption := AValue;
    FullRefresh;
    Realign;
  end;
end;

procedure TACLCustomGroupBox.SetDescription(const AValue: string);
begin
  if Description <> AValue then
  begin
    FDescription := AValue;
    Calculate(ClientRect);
    Invalidate;
  end;
end;

procedure TACLCustomGroupBox.SetStyleCaption(AValue: TACLStyleCheckBox);
begin
  FStyleCaption.Assign(AValue);
end;

{ TACLGroupBoxCheckBox }

constructor TACLGroupBoxCheckBox.Create(AOwner: TACLGroupBox);
begin
  FOwner := AOwner;
end;

procedure TACLGroupBoxCheckBox.AssignTo(ATarget: TPersistent);
begin
  if ATarget is TACLGroupBoxCheckBox then
  begin
    TACLGroupBoxCheckBox(ATarget).Action := Action;
    TACLGroupBoxCheckBox(ATarget).Checked := Checked;
    TACLGroupBoxCheckBox(ATarget).Visible := Visible;
  end;
end;

procedure TACLGroupBoxCheckBox.Toggle;
begin
  Checked := not Checked;
end;

function TACLGroupBoxCheckBox.GetChecked: Boolean;
begin
  Result := FOwner.CaptionSubClass.CheckState = cbChecked;
end;

function TACLGroupBoxCheckBox.GetVisible: Boolean;
begin
  Result := FOwner.CaptionSubClass.ShowCheckMark;
end;

procedure TACLGroupBoxCheckBox.SetAction(AValue: TACLGroupBoxCheckBoxAction);
begin
  if AValue <> FAction then
  begin
    FAction := AValue;
    FOwner.EnableChildren;
    FOwner.Minimized := False;
    FOwner.ApplyCheckBoxState;
  end;
end;

procedure TACLGroupBoxCheckBox.SetChecked(AValue: Boolean);
begin
  if Checked <> AValue then
  begin
    if AValue then
      FOwner.CaptionSubClass.CheckState := cbChecked
    else
      FOwner.CaptionSubClass.CheckState := cbUnchecked;

    FOwner.ApplyCheckBoxState;
  end;
end;

procedure TACLGroupBoxCheckBox.SetVisible(AValue: Boolean);
begin
  if Visible <> AValue then
  begin
    FOwner.CaptionSubClass.ShowCheckMark := AValue;
    FOwner.BoundsChanged; // recalculate
    FOwner.ApplyCheckBoxState;
  end;
end;

{ TACLGroupBox }

constructor TACLGroupBox.Create(AOwner: TComponent);
begin
  inherited;
  FCheckBox := TACLGroupBoxCheckBox.Create(Self);
end;

destructor TACLGroupBox.Destroy;
begin
  FreeAndNil(FDisabledChildren);
  FreeAndNil(FCheckBox);
  inherited Destroy;
end;

procedure TACLGroupBox.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if Minimized then
    AHeight := GetMinimizeStateHeight;
  inherited;
end;

procedure TACLGroupBox.AdjustClientRect(var Rect: TRect);
begin
  inherited;
  if Minimized then
  begin
    Rect.Top := GetMinimizeStateHeight;
    Rect.Bottom := High(SmallInt);
  end;
end;

procedure TACLGroupBox.ApplyCheckBoxState(AFireEvent: Boolean = True);
begin
  if (csDesigning in ComponentState) or not CheckBox.Visible then
    Exit;
  if (csLoading in ComponentState) then
    Exit;
  if CheckBox.Action in [cbaToggleChildrenEnableState, cbaToggleMinimizeState] then
  begin
    if CheckBox.Checked then
      EnableChildren
    else
      DisableChildren;
  end;
  if CheckBox.Action = cbaToggleMinimizeState then
    Minimized := not CheckBox.Checked;
  if AFireEvent then
    DoCheckBoxStateChanged;
end;

function TACLGroupBox.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  Result := inherited;
  if Minimized then
    NewHeight := GetMinimizeStateHeight;
end;

function TACLGroupBox.CreateStyleCaption: TACLStyleCheckBox;
begin
  Result := TACLGroupBoxCaptionStyle.Create(Self);
end;

procedure TACLGroupBox.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('CheckBoxMode', ReadCheckBoxMode, nil, False);
  Filer.DefineProperty('CheckBoxState', ReadCheckBoxState, nil, False);
end;

procedure TACLGroupBox.DoCheckBoxClick;
begin
  CheckBox.Toggle;
end;

procedure TACLGroupBox.DoCheckBoxStateChanged;
begin
  CallNotifyEvent(Self, OnCheckBoxStateChanged);
end;

procedure TACLGroupBox.DoLoaded;
begin
  inherited;
  ApplyCheckBoxState(False); // !!
end;

function TACLGroupBox.GetMinimizeStateHeight: Integer;
begin
  Result := FCaptionRect.Bottom + acBorderOffsets.Bottom;
end;

procedure TACLGroupBox.GetTabOrderList(List: TTabOrderList);
begin
  if not Minimized then
    inherited;
end;

procedure TACLGroupBox.DisableChildren;
var
  LControl: TControl;
  I: Integer;
begin
  if FDisabledChildren = nil then
  begin
    FDisabledChildren := TList.Create;
    for I := 0 to ControlCount - 1 do
    begin
      LControl := Controls[I];
      if LControl.Enabled then
      begin
        FDisabledChildren.Add(LControl);
        LControl.Enabled := False;
      end;
    end;
  end;
end;

procedure TACLGroupBox.EnableChildren;
var
  LControl: TControl;
  I: Integer;
begin
  if FDisabledChildren <> nil then
  try
    for I := 0 to ControlCount - 1 do
    begin
      LControl := Controls[I];
      if FDisabledChildren.Remove(LControl) >= 0 then
        LControl.Enabled := True;
    end;
  finally
    FreeAndNil(FDisabledChildren);
  end;
end;

procedure TACLGroupBox.SetCheckBox(AValue: TACLGroupBoxCheckBox);
begin
  FCheckBox.Assign(AValue);
end;

procedure TACLGroupBox.SetMinimized(AValue: Boolean);
begin
  if FMinimized <> AValue then
  begin
    FMinimized := AValue;
    if Minimized then
    begin
      FRestoredHeight := Height;
      Height := GetMinimizeStateHeight;
    end
    else
      Height := FRestoredHeight;
  end;
end;

procedure TACLGroupBox.ReadCheckBoxMode(Reader: TReader);
var
  AIdent: string;
begin
  AIdent := Reader.ReadIdent;
  CheckBox.Visible := AIdent <> 'msgcbNone';
  if AIdent = 'msgcbToggleEnableState' then
    CheckBox.Action := cbaToggleChildrenEnableState
  else
    CheckBox.Action := cbaNone;
end;

procedure TACLGroupBox.ReadCheckBoxState(Reader: TReader);
begin
  CheckBox.Checked := Reader.ReadBoolean;
end;

{ TACLGroupBoxCaptionStyle }

procedure TACLGroupBoxCaptionStyle.InitializeResources;
begin
  ColorText.InitailizeDefaults('Groups.Colors.HeaderText');
  ColorTextHover.InitailizeDefaults('Groups.Colors.HeaderText');
  ColorTextPressed.InitailizeDefaults('Groups.Colors.HeaderText');
  ColorTextDisabled.InitailizeDefaults('Groups.Colors.HeaderText');
  InitializeTextures;
end;

{ TACLGroupBoxCheckBoxSubClass }

procedure TACLGroupBoxCheckBoxSubClass.AssignCanvasParameters(ACanvas: TCanvas);
begin
  inherited;
  ACanvas.Font.Style := [TFontStyle.fsBold];
end;

{ TACLGroupBoxUIInsightAdapter }

class function TACLGroupBoxUIInsightAdapter.MakeVisible(AObject: TObject): Boolean;
begin
  Result := not TACLGroupBox(AObject).Minimized;
end;

initialization
  TACLUIInsight.Register(TACLGroupBox, TACLGroupBoxUIInsightAdapter);
end.
