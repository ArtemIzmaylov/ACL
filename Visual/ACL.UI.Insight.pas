////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   search thougth app controls
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Insight;

{$I ACL.Config.inc}
{$R ACL.UI.Insight.res}

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
  ACL.Graphics,
  ACL.Threading,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.DropDown,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Controls.SearchBox,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Menus,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type
  TACLUIInsightSearchQueueBuilder = class;

  TACLUIInsightAdapter = class;
  TACLUIInsightAdapterClass = class of TACLUIInsightAdapter;

  { TACLUIInsightCandidate }

  TACLUIInsightCandidate = class
  protected
    FLocation: TArray<TObject>;
    FLocationText: string;
    FText: string;
  public
    function Clone: TACLUIInsightCandidate;

    property Location: TArray<TObject> read FLocation;
    property LocationText: string read FLocationText;
    property Text: string read FText;
  end;

  { TACLUIInsightCandidates }

  TACLUIInsightCandidates = class(TACLObjectListOf<TACLUIInsightCandidate>);

  { TACLUIInsightSearchQueueBuilder }

  TACLUIInsightSearchQueueBuilder = class
  strict private
    FCandidates: TACLUIInsightCandidates;
    FNestedCaptions: TStack<string>;
    FNestedObjects: TStack<TObject>;

    function GetCurrentLocation: string;
  public
    constructor Create(ATarget: TACLUIInsightCandidates);
    destructor Destroy; override;
    procedure Add(AObject: TObject);
    procedure AddCandidate(AObject: TObject; const AValue: string);
    procedure AddChildren(AObject: TObject);
  end;

  { TACLUIInsightButton }

  TACLUIInsightButtonSearchQueryEvent = procedure (
    Sender: TObject; Sources: TACLUIInsightSearchQueueBuilder) of object;

  TACLUIInsightButton = class(TACLCustomDropDown)
  protected const
    WM_POSTSELECT = WM_USER;
  strict private
    FActionList: TActionList;
    FShortCut: TShortCut;
    FStyleSearchEdit: TACLStyleEdit;
    FStyleSearchEditButton: TACLStyleEditButton;
    FStyleSearchResults: TACLStyleTreeList;
    FStyleSearchResultsScrollBox: TACLStyleScrollBox;

    FOnSearchQuery: TACLUIInsightButtonSearchQueryEvent;

    procedure SetStyleSearchEdit(const Value: TACLStyleEdit);
    procedure SetStyleSearchEditButton(const Value: TACLStyleEditButton);
    procedure SetStyleSearchResults(const Value: TACLStyleTreeList);
    procedure SetStyleSearchResultsScrollBox(const Value: TACLStyleScrollBox);
    procedure SetShortCut(AValue: TShortCut);
    procedure HandlerStartSearch(Sender: TObject);
    procedure WMPostSelect(var Message: TMessage); message WM_POSTSELECT;
  protected
    FLastSearchString: string;

    function CreateDropDownWindow: TACLPopupWindow; override;
    procedure DoGetHint(const P: TPoint; var AHint: string); override;
    procedure PopulateCandidates(ACandidates: TACLUIInsightCandidates); virtual;
    procedure SelectCandidate(ACandidate: TACLUIInsightCandidate); virtual;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure ShowDropDownWindow; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ShortCut: TShortCut read FShortCut write SetShortCut default scNone;
    property StyleSearchEdit: TACLStyleEdit read FStyleSearchEdit write SetStyleSearchEdit;
    property StyleSearchEditButton: TACLStyleEditButton
      read FStyleSearchEditButton write SetStyleSearchEditButton;
    property StyleSearchResults: TACLStyleTreeList
      read FStyleSearchResults write SetStyleSearchResults;
    property StyleSearchResultsScrollBox: TACLStyleScrollBox
      read FStyleSearchResultsScrollBox write SetStyleSearchResultsScrollBox;

    property OnSearchQuery: TACLUIInsightButtonSearchQueryEvent read FOnSearchQuery write FOnSearchQuery;
  end;

  { TACLUIInsight }

  TACLUIInsight = class
  strict private
    class var FClassAdapters: TACLClassMap<TACLUIInsightAdapterClass>;
    class var FObjectAdapters: TACLDictionary<TObject, TACLUIInsightAdapterClass>;
  public
    class constructor Create;
    class destructor Destroy;
    class function GetAdapter(AObject: TObject; out AAdapter: TACLUIInsightAdapterClass): Boolean;
    class procedure Register(AClass: TClass; AAdapter: TACLUIInsightAdapterClass); overload;
    class procedure Register(AObject: TObject; AAdapter: TACLUIInsightAdapterClass); overload;
    class procedure Unregister(AClass: TClass); overload;
    class procedure Unregister(AObject: TObject); overload;
  end;

  { TACLUIInsightAdapter }

  TACLUIInsightAdapter = class
  public
    class function GetBoundsOnScreen(AObject: TObject; out ABounds: TRect): Boolean; virtual;
    class function GetCaption(AObject: TObject; out AValue: string): Boolean; virtual;
    class procedure GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder); virtual;
    class function GetGroupCaption(AObject: TObject; out AValue: string): Boolean; virtual;
    class function GetKeywors(AObject: TObject; out AValue: string): Boolean; virtual;
    class function MakeVisible(AObject: TObject): Boolean; virtual;
  end;

  { TACLUIInsightAdapterControl }

  TACLUIInsightAdapterControl = class(TACLUIInsightAdapter)
  public
    class function GetBoundsOnScreen(AObject: TObject; out ABounds: TRect): Boolean; override;
    class function GetCaption(AObject: TObject; out AValue: string): Boolean; override;
    class function GetKeywors(AObject: TObject; out AValue: string): Boolean; override;
  end;

  { TACLUIInsightAdapterWinControl }

  TACLUIInsightAdapterWinControl = class(TACLUIInsightAdapterControl)
  public
    class function GetBoundsOnScreen(AObject: TObject; out ABounds: TRect): Boolean; override;
    class procedure GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder); override;
  end;

implementation

uses
{$IFDEF FPC}
  ACL.Graphics.Ex.Cairo;
{$ELSE}
  ACL.Graphics.Ex.Gdip;
{$ENDIF}

type

  { TACLUIInsightHighlightWindow }

  TACLUIInsightHighlightWindow = class(TACLPopupWindow)
  strict private const
    Alpha = 40;
    HideDelay = 1000; // msec
    FlashTimerId = 42;
  strict private
    FTimestamp: Cardinal;
    procedure UpdateAlpha;
    procedure WMTimer(var Message: TWMTimer); message WM_TIMER;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DoPopup; override;
    procedure DoPopupClosed; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DestroyWnd; override;
  end;

  { TACLUIInsightSearchBox }

  TACLUIInsightSearchBox = class(TACLSearchEdit)
  protected
    procedure CMWantSpecialKey(var Message: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
  end;

  { TACLUIInsightSearchPopupWindow }

  TACLUIInsightSearchPopupWindow = class(TACLPopupWindow)
  public const
    BeakSize = 8;
  strict private
    FBorderColor: TColor;
    FCandidates: TACLUIInsightCandidates;
    FCapturedObject: TObject;
    FContentMargins: TRect;
    FHintFont: TFont;
    FOwner: TACLUIInsightButton;
    FPolyline: array of TPoint;
    FSearchEdit: TACLSearchEdit;
    FSearchResults: TACLTreeList;

    procedure HandlerSearch(Sender: TObject);
    procedure HandlerSearchResultsDrawEntry(Sender: TObject;
      ACanvas: TCanvas; const R: TRect; ANode: TACLTreeListNode; var AHandled: Boolean);
    procedure HandlerSearchResultsKeyUp(
      Sender: TObject; var Key: Word; ShiftState: TShiftState);
    procedure HandlerSearchResultsMouseDown(
      Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure HandlerSearchResultsMouseUp(
      Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure Calculate;
    procedure DoPopup; override;
    procedure Paint; override;
    procedure PopulateCandidates; virtual;
    procedure Resize; override;
    procedure SelectCandidate(const ANode: TACLTreeListNode); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;

    property Owner: TACLUIInsightButton read FOwner;
    property SearchEdit: TACLSearchEdit read FSearchEdit;
    property SearchResults: TACLTreeList read FSearchResults;
  end;

function TryGetPropValue(AObject: TObject; const APropName: string; out AValue: string): Boolean;
var
  APropInfo: PPropInfo;
begin
  APropInfo := GetPropInfo(AObject, APropName);
  if APropInfo <> nil then
  begin
    AValue := GetStrProp(AObject, APropInfo);
    Result := AValue <> '';
  end
  else
    Result := False;
end;

{ TACLUIInsightSearchBox }

procedure TACLUIInsightSearchBox.CMWantSpecialKey(var Message: TCMWantSpecialKey);
begin
  if Message.CharCode = VK_ESCAPE then
    Message.Result := Ord(Text <> '')
  else
    inherited;
end;

{ TACLUIInsightCandidate }

function TACLUIInsightCandidate.Clone: TACLUIInsightCandidate;
begin
  Result := TACLUIInsightCandidate.Create;
  Result.FLocation := FLocation;
  Result.FLocationText := FLocationText;
  Result.FText := FText;
end;

{ TACLUIInsightSearchQueueBuilder }

constructor TACLUIInsightSearchQueueBuilder.Create(ATarget: TACLUIInsightCandidates);
begin
  FCandidates := ATarget;
  FNestedCaptions := TStack<string>.Create;
  FNestedObjects := TStack<TObject>.Create;
end;

destructor TACLUIInsightSearchQueueBuilder.Destroy;
begin
  FreeAndNil(FNestedObjects);
  FreeAndNil(FNestedCaptions);
  inherited;
end;

procedure TACLUIInsightSearchQueueBuilder.Add(AObject: TObject);
var
  AAdapter: TACLUIInsightAdapterClass;
  AValue: string;
begin
  if TACLUIInsight.GetAdapter(AObject, AAdapter) then
  begin
    FNestedObjects.Push(AObject);
    try
      if AAdapter.GetCaption(AObject, AValue) then
        AddCandidate(AObject, AValue);
      if AAdapter.GetKeywors(AObject, AValue) then
        AddCandidate(AObject, AValue);
      if AAdapter.GetGroupCaption(AObject, AValue) and (AValue <> '') then
      begin
        FNestedCaptions.Push(AValue);
        try
          AAdapter.GetChildren(AObject, Self);
        finally
          FNestedCaptions.Pop;
        end;
      end
      else
        AAdapter.GetChildren(AObject, Self);
    finally
      FNestedObjects.Pop;
    end;
  end;
end;

procedure TACLUIInsightSearchQueueBuilder.AddChildren(AObject: TObject);
var
  AAdapter: TACLUIInsightAdapterClass;
begin
  if TACLUIInsight.GetAdapter(AObject, AAdapter) then
    AAdapter.GetChildren(AObject, Self);
end;

function TACLUIInsightSearchQueueBuilder.GetCurrentLocation: string;
var
  B: TACLStringBuilder;
{$IFNDEF DELPHI110ALEXANDRIA}
  C: TArray<string>;
{$ENDIF}
  I: Integer;
begin
  Result := '';
  if FNestedCaptions.Count > 0 then
  begin
    B := TACLStringBuilder.Get;
    try
    {$IFNDEF DELPHI110ALEXANDRIA}
      C := FNestedCaptions.ToArray;
    {$ENDIF}
      for I := 0 to FNestedCaptions.Count - 1 do
      begin
        if B.Length > 0 then
          B.Append(' » ');
      {$IFDEF DELPHI110ALEXANDRIA}
        B.Append(FNestedCaptions.List[I]);
      {$ELSE}
        B.Append(C[I]);
      {$ENDIF}
      end;
      Result := B.ToString;
    finally
      B.Release;
    end;
  end;
end;

procedure TACLUIInsightSearchQueueBuilder.AddCandidate(AObject: TObject; const AValue: string);
var
  ACandidate: TACLUIInsightCandidate;
begin
  if AValue <> '' then
  begin
    ACandidate := TACLUIInsightCandidate.Create;
    ACandidate.FLocation := FNestedObjects.ToArray;
    ACandidate.FLocationText := GetCurrentLocation;
    ACandidate.FText := AValue;
    FCandidates.Add(ACandidate);
  end;
end;

{ TACLUIInsightButton }

constructor TACLUIInsightButton.Create(AOwner: TComponent);
begin
  inherited;
  DropDownButton.HasArrow := False;
  FStyleSearchEdit := TACLStyleEdit.Create(Self);
  FStyleSearchEditButton := TACLSearchEditStyleButton.Create(Self);
  FStyleSearchResults := TACLStyleTreeList.Create(Self);
  FStyleSearchResultsScrollBox := TACLStyleScrollBox.Create(Self);
  if (AOwner <> nil) and ([csLoading, csReading, csDesigning] * AOwner.ComponentState = [csDesigning]) then
    Glyph.ImportFromImageResource(HInstance, 'ACLUIINSIGHT', 'PNG');
end;

destructor TACLUIInsightButton.Destroy;
begin
  FreeAndNil(FActionList);
  FreeAndNil(FStyleSearchResultsScrollBox);
  FreeAndNil(FStyleSearchResults);
  FreeAndNil(FStyleSearchEditButton);
  FreeAndNil(FStyleSearchEdit);
  inherited;
end;

procedure TACLUIInsightButton.DoGetHint(const P: TPoint; var AHint: string);
begin
  inherited;
  AHint := acMenuAppendShortCut(AHint, ShortCut);
end;

function TACLUIInsightButton.CreateDropDownWindow: TACLPopupWindow;
begin
  Result := TACLUIInsightSearchPopupWindow.Create(Self);
end;

procedure TACLUIInsightButton.PopulateCandidates(ACandidates: TACLUIInsightCandidates);
var
  ABuilder: TACLUIInsightSearchQueueBuilder;
begin
  ABuilder := TACLUIInsightSearchQueueBuilder.Create(ACandidates);
  try
    if Assigned(FOnSearchQuery) then
      FOnSearchQuery(Self, ABuilder)
    else
      ABuilder.AddChildren(GetParentForm(Self));
  finally
    ABuilder.Free;
  end;
end;

procedure TACLUIInsightButton.SelectCandidate(ACandidate: TACLUIInsightCandidate);

  function GetLastVisibleObject: TObject;
  var
    AAdapter: TACLUIInsightAdapterClass;
    AObject: TObject;
    I: Integer;
  begin
    for I := 0 to Length(ACandidate.Location) - 1 do
    begin
      AObject := ACandidate.Location[I];
      if not TACLUIInsight.GetAdapter(AObject, AAdapter) then
        raise EInvalidOperation.CreateFmt('Adapter was not found for "%s"', [AObject.ClassName]);
      if not AAdapter.MakeVisible(AObject) then
        Exit(AObject);
    end;
    Result := ACandidate.Location[High(ACandidate.Location)];
  end;

var
  AAdapter: TACLUIInsightAdapterClass;
  ABounds: TRect;
  AObject: TObject;
begin
  try
    AObject := GetLastVisibleObject;
    if TACLUIInsight.GetAdapter(AObject, AAdapter) then
    begin
      if not AAdapter.GetBoundsOnScreen(AObject, ABounds) then
        raise EInvalidOperation.CreateFmt('Cannot find the "%s" object on screen', [AObject.ClassName]);
      TACLUIInsightHighlightWindow.Create(Self).Popup(ABounds);
    end;
  finally
    ACandidate.Free;
  end;
end;

procedure TACLUIInsightButton.SetTargetDPI(AValue: Integer);
begin
  inherited;
  StyleSearchEdit.TargetDPI := AValue;
  StyleSearchEditButton.TargetDPI := AValue;
  StyleSearchResults.TargetDPI := AValue;
  StyleSearchResultsScrollBox.TargetDPI := AValue;
end;

procedure TACLUIInsightButton.ShowDropDownWindow;
var
  LAlignment: TAlignment;
  LBounds: TRect;
  LThreshold: Integer;
begin
  LThreshold := Parent.Width div 4;
  if Left > Parent.Width - LThreshold then
    LAlignment := taRightJustify
  else if Left < LThreshold then
    LAlignment := taLeftJustify
  else
    LAlignment := taCenter;

  LBounds := ClientToScreen(ClientRect);
  LBounds.Inflate(
    dpiApply(TACLUIInsightSearchPopupWindow.BeakSize, FCurrentPPI) div 2,
    dpiApply(acTextIndent, FCurrentPPI));
  DropDownWindow.PopupUnderControl(LBounds, LAlignment);
end;

procedure TACLUIInsightButton.SetShortCut(AValue: TShortCut);
var
  AAction: TAction;
begin
  if FShortCut <> AValue then
  begin
    FreeAndNil(FActionList);
    FShortCut := AValue;
    if FShortCut <> 0 then
    begin
      FActionList := TActionList.Create(Self);
      AAction := TAction.Create(FActionList);
      AAction.OnExecute := HandlerStartSearch;
      AAction.ActionList := FActionList;
      AAction.ShortCut := FShortCut;
    end;
  end;
end;

procedure TACLUIInsightButton.SetStyleSearchEdit(const Value: TACLStyleEdit);
begin
  FStyleSearchEdit.Assign(Value);
end;

procedure TACLUIInsightButton.SetStyleSearchEditButton(const Value: TACLStyleEditButton);
begin
  FStyleSearchEditButton.Assign(Value);
end;

procedure TACLUIInsightButton.SetStyleSearchResults(const Value: TACLStyleTreeList);
begin
  FStyleSearchResults.Assign(Value);
end;

procedure TACLUIInsightButton.SetStyleSearchResultsScrollBox(const Value: TACLStyleScrollBox);
begin
  FStyleSearchResultsScrollBox.Assign(Value);
end;

procedure TACLUIInsightButton.HandlerStartSearch(Sender: TObject);
begin
  if CanFocus then
  begin
    SetFocus;
    DroppedDown := True;
  end;
end;

procedure TACLUIInsightButton.WMPostSelect(var Message: TMessage);
begin
  SelectCandidate(TACLUIInsightCandidate(Message.LParam));
end;

{ TACLUIInsightHighlightWindow }

constructor TACLUIInsightHighlightWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AlphaBlend := True;
  Color := clRed;
end;

procedure TACLUIInsightHighlightWindow.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.ExStyle := Params.ExStyle or WS_EX_TOPMOST;
  Params.WindowClass.style := Params.WindowClass.style and not CS_DROPSHADOW;
end;

procedure TACLUIInsightHighlightWindow.DestroyWnd;
begin
  KillTimer(Handle, FlashTimerId);
  inherited DestroyWnd;
end;

procedure TACLUIInsightHighlightWindow.DoPopup;
begin
  FTimestamp := TACLThread.Timestamp;
  AlphaBlendValue := Alpha;
  SetTimer(Handle, FlashTimerId, GetCaretBlinkTime, nil);
  inherited;
  TACLMainThread.RunPostponed(UpdateAlpha, Self);
end;

procedure TACLUIInsightHighlightWindow.DoPopupClosed;
begin
  inherited;
  TACLMainThread.RunPostponed(Free, Self);
end;

procedure TACLUIInsightHighlightWindow.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if TACLThread.IsTimeout(FTimestamp, HideDelay) and IsMouseInControl then
    ClosePopup;
end;

procedure TACLUIInsightHighlightWindow.UpdateAlpha;
begin
  AlphaBlendValue := MulDiv(Tag + 1, Alpha, 2);
end;

procedure TACLUIInsightHighlightWindow.WMTimer(var Message: TWMTimer);
begin
  if Message.TimerID = FlashTimerId then
  begin
    Tag := (Tag + 1) mod 2;
    UpdateAlpha;
  end
  else
    inherited;
end;

{ TACLUIInsightSearchPopupWindow }

constructor TACLUIInsightSearchPopupWindow.Create(AOwner: TComponent);
begin
  FOwner := AOwner as TACLUIInsightButton;
  inherited;
  FHintFont := TFont.Create;
  FCandidates := TACLUIInsightCandidates.Create;
  FCandidates.Capacity := 10240;
  Constraints.MinWidth := 400;

  FSearchEdit := TACLUIInsightSearchBox.Create(Self);
  FSearchEdit.Parent := Self;
  FSearchEdit.Align := alTop;
  FSearchEdit.AlignWithMargins := True;
  FSearchEdit.Style := Owner.StyleSearchEdit;
  FSearchEdit.StyleButton := Owner.StyleSearchEditButton;
  FSearchEdit.OnChange := HandlerSearch;

  FSearchResults := TACLTreeList.Create(Self);
  FSearchResults.Parent := Self;
  FSearchResults.Align := alClient;
  FSearchResults.AlignWithMargins := True;
  FSearchResults.BeginUpdate;
  try
    FSearchResults.OptionsView.Columns.Visible := False;
    FSearchResults.OptionsView.Nodes.GridLines := [];
    FSearchResults.OptionsBehavior.HotTrack := True;
    FSearchResults.Style := Owner.StyleSearchResults;
    FSearchResults.StyleScrollBox := Owner.StyleSearchResultsScrollBox;
  finally
    FSearchResults.EndUpdate;
  end;

  FSearchResults.OnCustomDrawNode := HandlerSearchResultsDrawEntry;
  FSearchResults.OnMouseDown := HandlerSearchResultsMouseDown;
  FSearchResults.OnMouseUp := HandlerSearchResultsMouseUp;
  FSearchResults.OnKeyUp := HandlerSearchResultsKeyUp;

  FSearchEdit.FocusControl := FSearchResults;
  FSearchEdit.Text := Owner.FLastSearchString;
end;

destructor TACLUIInsightSearchPopupWindow.Destroy;
begin
  TACLMainThread.Unsubscribe(Self);
  FreeAndNil(FCandidates);
  FreeAndNil(FHintFont);
  inherited;
end;

procedure TACLUIInsightSearchPopupWindow.AfterConstruction;
begin
  inherited;
  PopulateCandidates;
end;

procedure TACLUIInsightSearchPopupWindow.Calculate;
var
  ABeakSize: TSize;
  ABounds: TRect;
  AButtonCenter: TPoint;
  AContentMargins: TRect;
  ARegion: TRegionHandle;
begin
  ABounds := ClientRect;
  ABeakSize.cy := dpiApply(BeakSize, FCurrentPPI);
  ABeakSize.cx := {2 * }ABeakSize.cy;
  AButtonCenter := acMapRect(Owner.Handle, Handle, Owner.ClientRect).CenterPoint;
  AContentMargins := TRect.CreateMargins(dpiApply(acIndentBetweenElements, FCurrentPPI));

  if (AButtonCenter.X < ABounds.Left + ABeakSize.cx) or (AButtonCenter.X > ABounds.Right - ABeakSize.cx) then
  begin
    SetLength(FPolyline, 5);
    FPolyline[0] := Point(ABounds.Left, ABounds.Top);
    FPolyline[1] := Point(ABounds.Right, ABounds.Top);
    FPolyline[2] := Point(ABounds.Right, ABounds.Bottom);
    FPolyline[3] := Point(ABounds.Left, ABounds.Bottom);
    FPolyline[4] := Point(ABounds.Left, ABounds.Top);
  end
  else
    if AButtonCenter.Y < ABounds.Top then
    begin
      SetLength(FPolyline, 8);
      FPolyline[0] := Point(ABounds.Left, ABounds.Top + ABeakSize.cy);
      FPolyline[1] := Point(AButtonCenter.X - ABeakSize.cx, ABounds.Top + ABeakSize.cy);
      FPolyline[2] := Point(AButtonCenter.X, ABounds.Top);
      FPolyline[3] := Point(AButtonCenter.X + ABeakSize.cx, ABounds.Top + ABeakSize.cy);
      FPolyline[4] := Point(ABounds.Right, ABounds.Top + ABeakSize.cy);
      FPolyline[5] := Point(ABounds.Right, ABounds.Bottom);
      FPolyline[6] := Point(ABounds.Left, ABounds.Bottom);
      FPolyline[7] := Point(ABounds.Left, ABounds.Top + ABeakSize.cy);
      Inc(AContentMargins.Top, ABeakSize.cy);
    end
    else
    begin
      SetLength(FPolyline, 8);
      FPolyline[0] := Point(ABounds.Left, ABounds.Top);
      FPolyline[1] := Point(ABounds.Right, ABounds.Top);
      FPolyline[2] := Point(ABounds.Right, ABounds.Bottom - ABeakSize.cy);
      FPolyline[3] := Point(AButtonCenter.X + ABeakSize.cx, ABounds.Bottom - ABeakSize.cy);
      FPolyline[4] := Point(AButtonCenter.X, ABounds.Bottom);
      FPolyline[5] := Point(AButtonCenter.X - ABeakSize.cx, ABounds.Bottom - ABeakSize.cy);
      FPolyline[6] := Point(ABounds.Left, ABounds.Bottom - ABeakSize.cy);
      FPolyline[7] := Point(ABounds.Left, ABounds.Top);
      Inc(AContentMargins.Bottom, ABeakSize.cy);
    end;

  ARegion := CreatePolygonRgn({$IFDEF FPC}@{$ENDIF}FPolyline[0], Length(FPolyline), WINDING);
  acRegionSetToWindow(Handle, ARegion, True);
  DeleteObject(ARegion);

  if AContentMargins <> FContentMargins then
  begin
    FContentMargins := AContentMargins;
    Realign;
  end;
end;

procedure TACLUIInsightSearchPopupWindow.AdjustClientRect(var Rect: TRect);
begin
  Rect.Content(FContentMargins);
end;

procedure TACLUIInsightSearchPopupWindow.DoPopup;
var
  LColor: TACLResourceColor;
begin
  if TACLRootResourceCollection.GetResource('Common.Colors.Background1', TACLResourceColor, nil, LColor) then
    Color := LColor.AsColor;
  if TACLRootResourceCollection.GetResource('Common.Colors.Border3', TACLResourceColor, nil, LColor) then
    FBorderColor := LColor.AsColor;
  Font.ResolveHeight;
  FHintFont.Assign(Font);
  FHintFont.Size := FHintFont.Size - 1;
  FSearchResults.OptionsView.Nodes.Height := 3 * acTextIndent +
    dpiRevert(acFontHeight(Font) + acFontHeight(FHintFont), FCurrentPPI);
  inherited;
{$IFDEF FPC}
  TACLMainThread.RunPostponed(Calculate, Self);
{$ENDIF}
end;

procedure TACLUIInsightSearchPopupWindow.Paint;
begin
  GpPaintCanvas.BeginPaint(Canvas);
  try
  {$IFNDEF FPC}
    GpPaintCanvas.SmoothingMode := smNone;
    GpPaintCanvas.PixelOffsetMode := pomHalf;
  {$ENDIF}
    GpPaintCanvas.FillRectangle(ClientRect, TAlphaColor.FromColor(Color));
    GpPaintCanvas.Line(FPolyline, TAlphaColor.FromColor(FBorderColor), 2);
  finally
    GpPaintCanvas.EndPaint;
  end;
end;

procedure TACLUIInsightSearchPopupWindow.PopulateCandidates;
begin
  Owner.PopulateCandidates(FCandidates);
  HandlerSearch(nil);
end;

procedure TACLUIInsightSearchPopupWindow.Resize;
begin
  inherited;
  Calculate;
end;

procedure TACLUIInsightSearchPopupWindow.SelectCandidate(const ANode: TACLTreeListNode);
begin
  if ANode <> nil then
    PostMessage(Owner.Handle, TACLUIInsightButton.WM_POSTSELECT, 0, LPARAM(TACLUIInsightCandidate(ANode.Data).Clone));
end;

procedure TACLUIInsightSearchPopupWindow.HandlerSearch(Sender: TObject);
var
  ACandidate: TACLUIInsightCandidate;
  ANode: TACLTreeListNode;
  ASearchString: TACLSearchString;
  I: Integer;
begin
  SearchResults.BeginUpdate;
  try
    SearchResults.Clear;
    ASearchString := TACLSearchString.Create(SearchEdit.Text);
    try
      Owner.FLastSearchString := SearchEdit.Text;
      if not ASearchString.Empty then
        for I := 0 to FCandidates.Count - 1 do
        begin
          ACandidate := FCandidates.List[I];
          if ASearchString.Compare(ACandidate.Text) then
          begin
            ANode := SearchResults.RootNode.AddChild;
            ANode.Caption := ACandidate.Text;
            ANode.AddValue(ACandidate.LocationText);
            ANode.Data := ACandidate;
          end;
        end;
    finally
      ASearchString.Free;
    end;
  finally
    SearchResults.EndUpdate;
  end;
end;

procedure TACLUIInsightSearchPopupWindow.HandlerSearchResultsDrawEntry(Sender: TObject;
  ACanvas: TCanvas; const R: TRect; ANode: TACLTreeListNode; var AHandled: Boolean);
var
  LRect: TRect;
begin
  LRect := R;
  LRect.Inflate(-dpiApply(acTextIndent, FCurrentPPI));

  ACanvas.Font := Font;
  ACanvas.Font.Color := SearchResults.Style.RowColorsText[True];
  acSysDrawText(ACanvas, LRect, ANode.Caption, DT_TOP or DT_SINGLELINE or DT_END_ELLIPSIS);

  ACanvas.Font := FHintFont;
  ACanvas.Font.Color := SearchResults.Style.RowColorsText[ANode.Selected];
  acSysDrawText(ACanvas, LRect, ANode.Caption, DT_BOTTOM or DT_SINGLELINE or DT_END_ELLIPSIS);

  AHandled := True;
end;

procedure TACLUIInsightSearchPopupWindow.HandlerSearchResultsKeyUp(
  Sender: TObject; var Key: Word; ShiftState: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    SelectCandidate(SearchResults.FocusedNode);
    ClosePopup;
  end;
end;

procedure TACLUIInsightSearchPopupWindow.HandlerSearchResultsMouseDown(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FCapturedObject := SearchResults.ObjectAtPos(X, Y);
end;

procedure TACLUIInsightSearchPopupWindow.HandlerSearchResultsMouseUp(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FCapturedObject = SearchResults.ObjectAtPos(X, Y) then
  begin
    if FCapturedObject is TACLTreeListNode then
      SelectCandidate(TACLTreeListNode(FCapturedObject));
    ClosePopup;
  end;
end;

{ TACLUIInsight }

class constructor TACLUIInsight.Create;
begin
  Register(TControl, TACLUIInsightAdapterControl);
  Register(TWinControl, TACLUIInsightAdapterWinControl);
end;

class destructor TACLUIInsight.Destroy;
begin
  FreeAndNil(FObjectAdapters);
  FreeAndNil(FClassAdapters);
end;

class function TACLUIInsight.GetAdapter(AObject: TObject; out AAdapter: TACLUIInsightAdapterClass): Boolean;
begin
  if (FObjectAdapters <> nil) and FObjectAdapters.TryGetValue(AObject, AAdapter) then
    Exit(True);
  if (FClassAdapters <> nil) and FClassAdapters.TryGetValue(AObject, AAdapter) then
    Exit(True);
  Result := False;
end;

class procedure TACLUIInsight.Register(AObject: TObject; AAdapter: TACLUIInsightAdapterClass);
begin
  if FObjectAdapters = nil then
    FObjectAdapters := TACLDictionary<TObject, TACLUIInsightAdapterClass>.Create;
  FObjectAdapters.Add(AObject, AAdapter);
end;

class procedure TACLUIInsight.Register(AClass: TClass; AAdapter: TACLUIInsightAdapterClass);
begin
  if FClassAdapters = nil then
    FClassAdapters := TACLClassMap<TACLUIInsightAdapterClass>.Create;
  FClassAdapters.Add(AClass, AAdapter);
end;

class procedure TACLUIInsight.Unregister(AClass: TClass);
begin
  if FClassAdapters <> nil then
    FClassAdapters.Remove(AClass);
end;

class procedure TACLUIInsight.Unregister(AObject: TObject);
begin
  if FObjectAdapters <> nil then
    FObjectAdapters.Remove(AObject);
end;

{ TACLUIInsightAdapter }

class function TACLUIInsightAdapter.GetBoundsOnScreen(AObject: TObject; out ABounds: TRect): Boolean;
begin
  Result := False;
end;

class function TACLUIInsightAdapter.GetCaption(AObject: TObject; out AValue: string): Boolean;
begin
  Result := False;
end;

class procedure TACLUIInsightAdapter.GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
begin
  // do nothing
end;

class function TACLUIInsightAdapter.GetGroupCaption(AObject: TObject; out AValue: string): Boolean;
begin
  Result := GetCaption(AObject, AValue);
end;

class function TACLUIInsightAdapter.GetKeywors(AObject: TObject; out AValue: string): Boolean;
begin
  Result := False;
end;

class function TACLUIInsightAdapter.MakeVisible(AObject: TObject): Boolean;
begin
  Result := True;
end;

{ TACLUIInsightAdapterControl }

class function TACLUIInsightAdapterControl.GetBoundsOnScreen(AObject: TObject; out ABounds: TRect): Boolean;
var
  AControl: TControl absolute AObject;
  AWinControl: TWinControl;
begin
  AWinControl := AControl.Parent;
  Result := AWinControl.HandleAllocated and IsWindowVisible(AWinControl.Handle);
  if Result then
    ABounds := acMapRect(AWinControl.Handle, 0, AControl.BoundsRect);
end;

class function TACLUIInsightAdapterControl.GetCaption(AObject: TObject; out AValue: string): Boolean;
begin
  Result := TryGetPropValue(AObject, 'Caption', AValue);
end;

class function TACLUIInsightAdapterControl.GetKeywors(AObject: TObject; out AValue: string): Boolean;
begin
  Result := TryGetPropValue(AObject, 'Hint', AValue);
end;

{ TACLUIInsightAdapterWinControl }

class function TACLUIInsightAdapterWinControl.GetBoundsOnScreen(AObject: TObject; out ABounds: TRect): Boolean;
var
  AWinControl: TWinControl absolute AObject;
begin
  Result := AWinControl.HandleAllocated and IsWindowVisible(AWinControl.Handle);
  if Result then
    ABounds := acMapRect(AWinControl.Handle, 0, Rect(0, 0, AWinControl.Width, AWinControl.Height));
end;

class procedure TACLUIInsightAdapterWinControl.GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
var
  AControl: TControl;
  AWinControl: TWinControl absolute AObject;
  I: Integer;
begin
  for I := 0 to AWinControl.ControlCount - 1 do
  begin
    AControl := AWinControl.Controls[I];
    if AControl.Visible then
      ABuilder.Add(AControl);
  end;
end;

end.
