﻿{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*  UI Insight - Search thougth app controls *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2021-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Insight;

{$I ACL.Config.inc}
{$R ACL.UI.Insight.res}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Actions,
  System.UITypes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SysUtils,
  System.Classes,
  System.Types,
  // Vcl
  Vcl.ActnList,
  Vcl.Menus,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Gdiplus,
  ACL.Math,
  ACL.Threading,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.DropDown,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Controls.SearchBox,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common,
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

  TACLUIInsightCandidates = class(TACLObjectList<TACLUIInsightCandidate>);

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

  TACLUIInsightButtonSearchQueryEvent = procedure (Sender: TObject; Sources: TACLUIInsightSearchQueueBuilder) of object;

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

    function CreateButtonViewInfo: TACLCustomDropDownEditButtonViewInfo; override;
    function GetDropDownFormClass: TACLCustomPopupFormClass; override;
    procedure DoGetHint(const P: TPoint; var AHint: string); override;
    procedure PopulateCandidates(ACandidates: TACLUIInsightCandidates); virtual;
    procedure SelectCandidate(ACandidate: TACLUIInsightCandidate); virtual;
    procedure SetDefaultSize; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure ShowDropDownWindow; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ShortCut: TShortCut read FShortCut write SetShortCut default scNone;
    property StyleSearchEdit: TACLStyleEdit read FStyleSearchEdit write SetStyleSearchEdit;
    property StyleSearchEditButton: TACLStyleEditButton read FStyleSearchEditButton write SetStyleSearchEditButton;
    property StyleSearchResults: TACLStyleTreeList read FStyleSearchResults write SetStyleSearchResults;
    property StyleSearchResultsScrollBox: TACLStyleScrollBox read FStyleSearchResultsScrollBox write SetStyleSearchResultsScrollBox;

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
  System.TypInfo,
  System.Math;

type

  { TACLUIInsightHighlightWindow }

  TACLUIInsightHighlightWindow = class(TACLCustomPopupForm)
  strict private const
    Alpha = 40;
    HideDelay = 1000; // msec
  strict private
    FFlashTimer: TACLTimer;
    FTimestamp: Cardinal;

    procedure HandlerFlashTimer(Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DoClosePopup; override;
    procedure DoPopup; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    function IsShortCut(var Message: TWMKey): Boolean; override;
  end;

  { TACLUIInsightSearchBox }

  TACLUIInsightSearchBox = class(TACLSearchEdit)
  protected
    procedure CMWantSpecialKey(var Message: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
  end;

  { TACLUIInsightSearchPopupWindow }

  TACLUIInsightSearchPopupWindow = class(TACLCustomPopupForm)
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
    procedure HandlerSearchResultsDrawEntry(Sender: TObject; ACanvas: TCanvas; const R: TRect; ANode: TACLTreeListNode; var AHandled: Boolean);
    procedure HandlerSearchResultsKeyUp(Sender: TObject; var Key: Word; ShiftState: TShiftState);
    procedure HandlerSearchResultsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure HandlerSearchResultsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure CalculateViewInfo;
    procedure Paint; override;
    procedure PopulateCandidates; virtual;
    procedure Resize; override;
    procedure ResourceChanged; override;
    procedure SelectCandidate(const ANode: TACLTreeListNode); virtual;
    procedure UpdateFonts;
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
  I: Integer;
  B: TStringBuilder;
{$IFNDEF DELPHI110ALEXANDRIA}
  C: TArray<string>;
{$ENDIF}
begin
  Result := '';
  if FNestedCaptions.Count > 0 then
  begin
    B := TACLStringBuilderManager.Get;
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
      TACLStringBuilderManager.Release(B)
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
  if ShortCut <> scNone then
  begin
    if AHint <> '' then
      AHint := AHint + ' (' + ShortCutToText(ShortCut) + ')'
    else
      AHint := ShortCutToText(ShortCut);
  end;
end;

function TACLUIInsightButton.CreateButtonViewInfo: TACLCustomDropDownEditButtonViewInfo;
begin
  Result := inherited;
  Result.HasArrow := False;
end;

function TACLUIInsightButton.GetDropDownFormClass: TACLCustomPopupFormClass;
begin
  Result := TACLUIInsightSearchPopupWindow;
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
  AAlignment: TAlignment;
  AThreshold: Integer;
begin
  AThreshold := Parent.Width div 4;
  if Left > Parent.Width - AThreshold then
    AAlignment := taRightJustify
  else if Left < AThreshold then
    AAlignment := taLeftJustify
  else
    AAlignment := taCenter;

  FDropDown.PopupUnderControl(
    acRectInflate(BoundsRect,
      ScaleFactor.Apply(TACLUIInsightSearchPopupWindow.BeakSize) div 2,
      ScaleFactor.Apply(acTextIndent)),
    ClientToScreen(NullPoint), AAlignment, ScaleFactor);
end;

procedure TACLUIInsightButton.SetDefaultSize;
begin
  SetBounds(Left, Top, DefaultButtonHeight, DefaultButtonHeight);
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
    DropDown;
  end;
end;

procedure TACLUIInsightButton.WMPostSelect(var Message: TMessage);
begin
  SelectCandidate(TACLUIInsightCandidate(Message.LParam));
end;

{ TACLUIInsightHighlightWindow }

constructor TACLUIInsightHighlightWindow.Create(AOwner: TComponent);
begin
  inherited;
  AlphaBlend := True;
  AlphaBlendValue := Alpha;
  StayOnTop := True;
  FTimestamp := GetTickCount;
end;

procedure TACLUIInsightHighlightWindow.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.WindowClass.style := Params.WindowClass.style and not CS_DROPSHADOW;
end;

procedure TACLUIInsightHighlightWindow.DoClosePopup;
begin
  inherited;
  FreeAndNil(FFlashTimer);
  Release;
end;

procedure TACLUIInsightHighlightWindow.DoPopup;
begin
  FFlashTimer := TACLTimer.CreateEx(HandlerFlashTimer, GetCaretBlinkTime, True);
  inherited;
end;

function TACLUIInsightHighlightWindow.IsShortCut(var Message: TWMKey): Boolean;
var
  AForm: TCustomForm;
begin
  AForm := GetParentForm(Owner as TACLUIInsightButton);
  Result := (AForm <> nil) and AForm.IsShortCut(Message);
end;

procedure TACLUIInsightHighlightWindow.KeyDown(var Key: Word; Shift: TShiftState);
begin
  PopupClose;
end;

procedure TACLUIInsightHighlightWindow.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if GetTickCount - FTimestamp > HideDelay then
    PopupClose;
end;

procedure TACLUIInsightHighlightWindow.Paint;
begin
  Canvas.Brush.Color := clRed;
  Canvas.FillRect(ClientRect)
end;

procedure TACLUIInsightHighlightWindow.HandlerFlashTimer(Sender: TObject);
begin
  FFlashTimer.Tag := (FFlashTimer.Tag + 1) mod 2;
  AlphaBlendValue := MulDiv(FFlashTimer.Tag + 1, Alpha, 2);
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
  FreeAndNil(FCandidates);
  FreeAndNil(FHintFont);
  inherited;
end;

procedure TACLUIInsightSearchPopupWindow.AfterConstruction;
begin
  inherited;
  PopulateCandidates;
end;

procedure TACLUIInsightSearchPopupWindow.CalculateViewInfo;
var
  ABeakSize: TSize;
  ABounds: TRect;
  AButtonCenter: TPoint;
  ARegion: HRGN;
begin
  ABounds := ClientRect;
  ABeakSize.cy := ScaleFactor.Apply(BeakSize);
  ABeakSize.cx := {2 * }ABeakSize.cy;
  AButtonCenter := acMapRect(Owner.Handle, Handle, Owner.ClientRect).CenterPoint;
  FContentMargins := acMargins(ScaleFactor.Apply(acIndentBetweenElements));

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
      Inc(FContentMargins.Top, ABeakSize.cy);
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
      Inc(FContentMargins.Bottom, ABeakSize.cy);
    end;

  ARegion := CreatePolygonRgn(FPolyline[0], Length(FPolyline), WINDING);
  SetWindowRgn(Handle, ARegion, True);
  DeleteObject(ARegion);
end;

procedure TACLUIInsightSearchPopupWindow.AdjustClientRect(var Rect: TRect);
begin
  Rect := acRectContent(Rect, FContentMargins);
end;

procedure TACLUIInsightSearchPopupWindow.Paint;
begin
  GpPaintCanvas.BeginPaint(Canvas.Handle);
  try
    GpPaintCanvas.SmoothingMode := smNone;
    GpPaintCanvas.PixelOffsetMode := pomHalf;
    GpPaintCanvas.FillRectangle(TAlphaColor.FromColor(Color), ClientRect);
    GpPaintCanvas.DrawLine(TAlphaColor.FromColor(FBorderColor), FPolyline, gpsSolid, 2);
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
  CalculateViewInfo;
  inherited;
  Realign;
end;

procedure TACLUIInsightSearchPopupWindow.ResourceChanged;
var
  AColor: TACLResourceColor;
begin
  if TACLRootResourceCollection.GetResource('Common.Colors.Background1', TACLResourceColor, nil, AColor) then
    Color := AColor.AsColor;
  if TACLRootResourceCollection.GetResource('Common.Colors.Border3', TACLResourceColor, nil, AColor) then
    FBorderColor := AColor.AsColor;
  UpdateFonts;
  Invalidate;
end;

procedure TACLUIInsightSearchPopupWindow.SelectCandidate(const ANode: TACLTreeListNode);
begin
  if ANode <> nil then
    PostMessage(Owner.Handle, TACLUIInsightButton.WM_POSTSELECT, 0, LPARAM(TACLUIInsightCandidate(ANode.Data).Clone));
end;

procedure TACLUIInsightSearchPopupWindow.UpdateFonts;
begin
  FHintFont.Assign(Font);
  FHintFont.Size := FHintFont.Size - 1;
  FSearchResults.OptionsView.Nodes.Height := ScaleFactor.Revert(acFontHeight(Font) + acFontHeight(FHintFont)) + 3 * acTextIndent;
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
  ARect: TRect;
begin
  ARect := acRectInflate(R, -ScaleFactor.Apply(acTextIndent));

  ACanvas.Font := Font;
  ACanvas.Font.Color := SearchResults.Style.RowColorsText[True];
  acTextDraw(ACanvas, ANode.Caption, ARect, taLeftJustify, taAlignTop, True);

  ACanvas.Font := FHintFont;
  ACanvas.Font.Color := SearchResults.Style.RowColorsText[ANode.Selected];
  acTextDraw(ACanvas, ANode.Caption, ARect, taLeftJustify, taAlignBottom, True);

  AHandled := True;
end;

procedure TACLUIInsightSearchPopupWindow.HandlerSearchResultsKeyUp(Sender: TObject; var Key: Word; ShiftState: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    SelectCandidate(SearchResults.FocusedNode);
    PopupClose;
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
    PopupClose;
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
