////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Search thougth app controls
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Insight;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLProc,
  LCLType,
  LMessages,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Generics.Defaults,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  {System.}TypInfo,
  System.Actions,
  System.UITypes,
  // Vcl
  {Vcl.}ActnList,
  {Vcl.}Menus,
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Timers,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.Images,
  ACL.Threading,
{$I ACL.UI.Core.Impl.inc},
  ACL.UI.Controls.Base,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Controls.SearchBox,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Forms,
  ACL.UI.Insight.Core,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type

  { TACLUIInsightSearchBox }

  TACLUIInsightSearchEditMode = (isemIcon, isemEdit);
  TACLUIInsightSearchQueryEvent = procedure (
    Sender: TObject; Sources: TACLUIInsightSearchQueueBuilder) of object;

  TACLUIInsightSearchBox = class(TACLSearchEdit)
  strict private const
    DefaultWidthEdit = 121;
    WM_POSTSELECT = WM_USER;
  strict private
    FCandidates: TACLUIInsightCandidates;
    FHighlight: TWinControl;
    FMode: TACLUIInsightSearchEditMode;
    FState: TACLUIInsightSearchEditMode;
    FStyleIcon: TACLStyleButton;
    FStyleResults: TACLStyleTreeList;
    FStyleResultsScrollBox: TACLStyleScrollBox;
    FWidthEdit: Integer;

    FOnSearchQuery: TACLUIInsightSearchQueryEvent;

    procedure HideHighlightion;
    procedure SetMode(AValue: TACLUIInsightSearchEditMode);
    procedure SetState(AState: TACLUIInsightSearchEditMode);
    procedure SetStyleIcon(AValue: TACLStyleButton);
    procedure SetStyleResults(AValue: TACLStyleTreeList);
    procedure SetStyleResultsScrollBox(AValue: TACLStyleScrollBox);
    procedure SetWidthEdit(AValue: Integer);
    //# Messages
    procedure WMPostSelect(var Message: TMessage); message WM_POSTSELECT;
  protected
    function CreateDropDownWindow: TACLPopupWindow; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoGetHint(const P: TPoint; var AHint: string); override;
    procedure DoPrepareDropDownList(AList: TACLBasicDropDownList); override;
    procedure DoSearch; override;
    procedure InvalidateBorders; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseUpdateCursor(const P: TPoint); override;
    procedure Paint; override;
    procedure PostValue(ANode: TACLTreeListNode); override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure ShowDropDownWindow; override;
    procedure TextChanged; override;
    //# Properties
    property Candidates: TACLUIInsightCandidates read FCandidates;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdjustSize; override;
    //# Properties
    property State: TACLUIInsightSearchEditMode read FState;
  published
    //# Properties
    property Caption;
    property Mode: TACLUIInsightSearchEditMode read FMode write SetMode default isemIcon;
    property StyleIcon: TACLStyleButton read FStyleIcon write SetStyleIcon;
    property StyleResults: TACLStyleTreeList read FStyleResults write SetStyleResults;
    property StyleResultsScrollBox: TACLStyleScrollBox read FStyleResultsScrollBox write SetStyleResultsScrollBox;
    property TabStop stored False;
    property WidthEdit: Integer read FWidthEdit write SetWidthEdit default DefaultWidthEdit;
    //# Events
    property OnSearchQuery: TACLUIInsightSearchQueryEvent read FOnSearchQuery write FOnSearchQuery;
  end;

implementation

uses
  ACL.UI.Dialogs;

type

  { TACLUIInsightSearchResults }

  TACLUIInsightSearchResults = class(TACLBasicComboBoxDropDown)
  strict private
    FHintFont: TFont;
    procedure HandlerDrawEntry(Sender: TObject; ACanvas: TCanvas;
      const R: TRect; ANode: TACLTreeListNode; var AHandled: Boolean);
  protected
    function CalculateHeight: Integer; override;
    procedure DoPopup; override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { TACLUIInsightHighlightWindow }

  TACLUIInsightHighlightWindow = class(TACLCustomControl)
  strict private const
    HideDelay = 1000; // msec
  strict private
    FTimestamp: Cardinal;
    procedure CMCancelMode(var Msg: TMessage); message CM_CANCELMODE;
    procedure CMShowingChanged(var Msg: TMessage); message CM_SHOWINGCHANGED;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure BoundsChanged; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

{ TACLUIInsightSearchBox }

constructor TACLUIInsightSearchBox.Create(AOwner: TComponent);
begin
  inherited;
  FWidthEdit := DefaultWidthEdit;
  FDefaultSize := TSize.Create(DefaultButtonHeight);
  FStyleIcon := TACLStyleButton.Create(Self);
  FStyleResults := TACLStyleTreeList.Create(Self);
  FStyleResultsScrollBox := TACLStyleScrollBox.Create(Self);
  FCandidates := TACLUIInsightCandidates.Create;
  FCandidates.Capacity := 10240;
  SetMode(isemIcon);

  if (AOwner <> nil) and ([csLoading, csReading, csDesigning] * AOwner.ComponentState = [csDesigning]) then
    Caption := '💡';
end;

destructor TACLUIInsightSearchBox.Destroy;
begin
  FreeAndNil(FCandidates);
  FreeAndNil(FStyleResultsScrollBox);
  FreeAndNil(FStyleResults);
  FreeAndNil(FStyleIcon);
  inherited;
end;

procedure TACLUIInsightSearchBox.AdjustSize;
var
  LRect: TRect;
  LWidth: Integer;
begin
  if not HandleAllocated then Exit; // fpc

  LRect := BoundsRect;
  if State = isemIcon then
    LWidth := LRect.Height
  else
    LWidth := WidthEdit;

  if akRight in Anchors then
    LRect.Left := LRect.Right - LWidth
  else
    LRect.Width := LWidth;

  BoundsRect := LRect;
end;

function TACLUIInsightSearchBox.CreateDropDownWindow: TACLPopupWindow;
begin
  Result := TACLUIInsightSearchResults.Create(Self);
end;

procedure TACLUIInsightSearchBox.DoEnter;
begin
  SetState(isemEdit);
  inherited;
end;

procedure TACLUIInsightSearchBox.DoExit;
begin
  SetState(Mode);
  inherited;
end;

procedure TACLUIInsightSearchBox.DoGetHint(const P: TPoint; var AHint: string);
begin
  if (Mode = isemIcon) and (State <> isemIcon) then
    AHint := '';
  inherited;
end;

procedure TACLUIInsightSearchBox.DoPrepareDropDownList(AList: TACLBasicDropDownList);
var
  LBuilder: TACLUIInsightSearchQueueBuilder;
  LCandidate: TACLUIInsightCandidate;
  LNode: TACLTreeListNode;
begin
  Candidates.Count := 0;
  LBuilder := TACLUIInsightSearchQueueBuilder.Create(Candidates);
  try
    if Assigned(OnSearchQuery) then
      OnSearchQuery(Self, LBuilder)
    else
      LBuilder.AddChildren(GetParentForm(Self));
  finally
    LBuilder.Free;
  end;
  for LCandidate in Candidates do
  begin
    LNode := AList.RootNode.AddChild;
    LNode.AddValue(LCandidate.Text);
    LNode.AddValue(LCandidate.LocationText);
    LNode.Data := LCandidate;
  end;
end;

procedure TACLUIInsightSearchBox.DoSearch;
var
  LDropDownList: TACLBasicDropDownList;
begin
  DroppedDown := (State = isemEdit) and (Text <> '');
  if GetDropDownList(LDropDownList) then
    LDropDownList.IncSearch.Text := Text;
end;

procedure TACLUIInsightSearchBox.MouseUpdateCursor(const P: TPoint);
begin
  if State = isemIcon then
    Cursor := crHandPoint
  else
    inherited;
end;

procedure TACLUIInsightSearchBox.HideHighlightion;
begin
  if FHighlight <> nil then
    FHighlight.Hide;
end;

procedure TACLUIInsightSearchBox.InvalidateBorders;
begin
  if State = isemIcon then
    Invalidate
  else
    inherited;
end;

procedure TACLUIInsightSearchBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = vkDown) and (Text <> '') and not DroppedDown then
  begin
    DoSearch;
    Key := 0;
  end
  else
    inherited;
end;

procedure TACLUIInsightSearchBox.Paint;
var
  LState: TACLButtonState;
begin
  if State = isemIcon then
  begin
    if not Enabled then
      LState := absDisabled
    else if MouseInClient then
      LState := absHover
    else
      LState := absNormal;

    StyleIcon.Draw(Canvas, ClientRect, LState);
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := StyleIcon.TextColors[LState];
    acTextDraw(Canvas, Caption, ClientRect.InflateTo(-acTextIndent), taCenter, taVerticalCenter);
  end
  else
    inherited;
end;

procedure TACLUIInsightSearchBox.PostValue(ANode: TACLTreeListNode);
//var
//  PrevOnChange: TThreadMethod;
begin
// наверное стоит оставить именно то, что ввёл пользователь
//  PrevOnChange := EditBox.OnChange;
//  EditBox.OnChange := nil;
//  Text := ANode.Caption;
//  EditBox.OnChange := PrevOnChange;
  if ANode.Data <> nil then
    PostMessage(Handle, WM_POSTSELECT, 0, LPARAM(TACLUIInsightCandidate(ANode.Data).Clone));
end;

procedure TACLUIInsightSearchBox.SetMode(AValue: TACLUIInsightSearchEditMode);
begin
  FMode := AValue;
  TabStop := Mode = isemEdit;
  SetState(Mode);
end;

procedure TACLUIInsightSearchBox.SetState(AState: TACLUIInsightSearchEditMode);
begin
  EditBox.Iteract := AState = isemEdit;
  Transparent := AState <> isemEdit;
  if FState <> AState then
  begin
    FState := AState;
    DroppedDown := False;
    HideHighlightion;
    MouseUpdateCursor(CalcCursorPos);
    AdjustSize;
    Invalidate;
  end;
end;

procedure TACLUIInsightSearchBox.SetStyleIcon(AValue: TACLStyleButton);
begin
  FStyleIcon.Assign(AValue);
end;

procedure TACLUIInsightSearchBox.SetStyleResults(AValue: TACLStyleTreeList);
begin
  FStyleResults.Assign(AValue);
end;

procedure TACLUIInsightSearchBox.SetStyleResultsScrollBox(AValue: TACLStyleScrollBox);
begin
  FStyleResultsScrollBox.Assign(AValue);
end;

procedure TACLUIInsightSearchBox.SetTargetDPI(AValue: Integer);
begin
  inherited;
  StyleIcon.TargetDPI := AValue;
  StyleResults.TargetDPI := AValue;
  StyleResultsScrollBox.TargetDPI := AValue;
end;

procedure TACLUIInsightSearchBox.SetWidthEdit(AValue: Integer);
begin
  AValue := Max(AValue, DefaultButtonHeight);
  if FWidthEdit <> AValue then
  begin
    FWidthEdit := AValue;
    if State = isemEdit then
      AdjustSize;
  end;
end;

procedure TACLUIInsightSearchBox.ShowDropDownWindow;
var
  LThreshold: Integer;
begin
  LThreshold := Parent.Width div 4;
  if Left + Width > Parent.Width - LThreshold then
    DropDownAlignment := taRightJustify
  else if Left < LThreshold then
    DropDownAlignment := taLeftJustify
  else
    DropDownAlignment := taCenter;

  inherited;
end;

procedure TACLUIInsightSearchBox.TextChanged;
begin
  HideHighlightion;
  inherited;
end;

procedure TACLUIInsightSearchBox.WMPostSelect(var Message: TMessage);
var
  LAdapter: TACLUIInsightAdapterClass;
  LBounds: TRect;
  LObject: TObject;
  LParent: TWinControl;
begin
  LObject := TObject(Message.LParam);
  if LObject is TACLUIInsightCandidate then
  try
    PostMessage(Handle, WM_POSTSELECT, 0, LPARAM(TACLUIInsightCandidate(LObject).GetLastVisibleObject));
  finally
    LObject.Free;
  end
  else
    if TACLUIInsight.GetAdapter(LObject, LAdapter) then
    begin
      if not LAdapter.GetPosition(LObject, LBounds, LParent) then
        raise EInvalidOperation.CreateFmt('Cannot find the "%s" object on screen', [LObject.ClassName]);
      if FHighlight = nil then
        FHighlight := TACLUIInsightHighlightWindow.Create(Self);
      FHighlight.BoundsRect := LBounds;
      FHighlight.Parent := LParent;
      FHighlight.Show;
      FHighlight.BoundsRect := LBounds;
    end;
end;

{ TACLUIInsightSearchResults }

constructor TACLUIInsightSearchResults.Create(AOwner: TComponent);
begin
  inherited;
  FHintFont := TFont.Create;
  Constraints.MinWidth := 600;
  List.OnCustomDrawNode := HandlerDrawEntry;
end;

destructor TACLUIInsightSearchResults.Destroy;
begin
  TACLMainThread.Unsubscribe(Self);
  FreeAndNil(FHintFont);
  inherited;
end;

function TACLUIInsightSearchResults.CalculateHeight: Integer;
begin
  if List.AbsoluteVisibleNodes.Count > 0 then
    Result := inherited
  else
    Result := dpiApply(List.OptionsView.Nodes.Height, FCurrentPPI);
end;

procedure TACLUIInsightSearchResults.DoPopup;
begin
  inherited;
  Font.ResolveHeight;
  FHintFont.Assign(Font);
  FHintFont.Size := FHintFont.Size - 1;
  List.OptionsView.Nodes.Height := 3 * acTextIndent +
    dpiRevert(acFontHeight(Font) + acFontHeight(FHintFont), FCurrentPPI);
  AdjustSize;
end;

procedure TACLUIInsightSearchResults.HandlerDrawEntry(Sender: TObject;
  ACanvas: TCanvas; const R: TRect; ANode: TACLTreeListNode; var AHandled: Boolean);
var
  LRect: TRect;
begin
  LRect := R;
  LRect.Inflate(-dpiApply(acTextIndent, FCurrentPPI));

  ACanvas.Font := Font;
  ACanvas.Font.Color := List.Style.RowColorsText[True];
  acSysDrawText(ACanvas, LRect, ANode.Values[0], DT_TOP or DT_SINGLELINE or DT_END_ELLIPSIS);

  ACanvas.Font := FHintFont;
  ACanvas.Font.Color := List.Style.RowColorsText[ANode.Selected];
  acSysDrawText(ACanvas, LRect, ANode.Values[1], DT_BOTTOM or DT_SINGLELINE or DT_END_ELLIPSIS);

  AHandled := True;
end;

procedure TACLUIInsightSearchResults.Paint;
var
  LRect: TRect;
begin
  inherited;
  if List.AbsoluteVisibleNodes.Count = 0 then
  begin
    LRect := List.Bounds;
    Canvas.Font := FHintFont;
    Canvas.Font.Color := List.Style.RowColorsText[False];
    acSysDrawText(Canvas, LRect, TACLDialogsStrs.SearchNoResults, DT_VCENTER or DT_CENTER or DT_SINGLELINE);
  end;
end;

{ TACLUIInsightHighlightWindow }

constructor TACLUIInsightHighlightWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IFNDEF MSWINDOWS}
  Transparent := True;
{$ENDIF}
  Visible := False;
  Color := clRed;
end;

procedure TACLUIInsightHighlightWindow.BoundsChanged;
{$IFNDEF LCLGtk3}
var
  LRegion: TRegionHandle;
{$ENDIF}
begin
  inherited;
  if HandleAllocated then
  begin
  {$IFDEF LCLGtk3}
    TACLWSCustomControl.SetOpacity(Self, 128);
  {$ELSE}
    LRegion := CreateRectRgnIndirect(ClientRect);
    acRegionCombine(LRegion, ClientRect.InflateTo(-dpiApply(2, FCurrentPPI)), RGN_DIFF);
    acRegionSetToWindow(Handle, LRegion, True);
  {$ENDIF}
  end;
end;

procedure TACLUIInsightHighlightWindow.CMCancelMode(var Msg: TMessage);
begin
  inherited;
  Hide;
end;

procedure TACLUIInsightHighlightWindow.CMShowingChanged(var Msg: TMessage);
begin
  inherited;
  MouseCapture := Showing;
  if Showing then
    FTimestamp := TACLThread.Timestamp;
  BoundsChanged;
end;

procedure TACLUIInsightHighlightWindow.MouseDown(
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Hide;
  inherited;
end;

procedure TACLUIInsightHighlightWindow.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if ClientRect.Contains(Point(X, Y)) and TACLThread.IsTimeout(FTimestamp, HideDelay) then
    Hide;
end;

procedure TACLUIInsightHighlightWindow.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTALLKEYS or DLGC_WANTARROWS or DLGC_WANTTAB;
end;

end.
