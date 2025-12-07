////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   ComboBox
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.ComboBox;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
  LMessages,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // VCL
  {Vcl.}Controls,
  {Vcl.}Graphics,
  // ACL
  ACL.MUI,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.ObjectLinks,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.DropDown,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Forms,
  ACL.UI.Insight,
  ACL.UI.Resources,
  ACL.Threading,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type
{$REGION ' Abstract '}

  { TACLAbstractComboBox }

  TACLAbstractComboBox = class(TACLAbstractDropDownEdit)
  protected
    procedure CalculateButtons(var ARect: TRect; AIndent: Integer); override;
    function CreateDropDownButton: TACLButtonSubClass; override;
    function CreateStyleButton: TACLStyleButton; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  end;

{$ENDREGION}

{$REGION ' Basic '}

  { TACLStyleDropDownList }

  TACLStyleDropDownList = class(TACLStyleTreeList)
  protected
    procedure InitializeResources; override;
  end;

  { TACLBasicComboBox }

  TACLComboBoxCustomDrawEvent =
    procedure (Sender: TObject; ACanvas: TCanvas; const ABounds: TRect) of object;
  TACLComboBoxCustomDrawItemEvent = procedure (Sender: TObject; ACanvas: TCanvas;
    const ABounds: TRect; AIndex: Integer; var AHandled: Boolean) of object;
  TACLComboBoxDeleteItemObjectEvent =
    procedure (Sender: TObject; AItemObject: TObject) of object;
  TACLComboBoxGetDisplayItemTextEvent =
    procedure (Sender: TObject; AIndex: Integer; var AText: string) of object;
  TACLComboBoxGetDisplayTextEvent =
    procedure (Sender: TObject; var AText: string) of object;
  TACLComboBoxPrepareDropDownListEvent =
    procedure (Sender: TObject; AList: TACLTreeListSubClass) of object;

  TACLBasicComboBox = class(TACLAbstractComboBox)
  strict private
    FContentBounds: TRect;
    FLoadedItemIndex: Integer;
    FDropDownListSize: Integer;
    FStyleDropDownList: TACLStyleTreeList;
    FStyleDropDownListScrollBox: TACLStyleScrollBox;

    FOnCustomDraw: TACLComboBoxCustomDrawEvent;
    FOnCustomDrawItem: TACLComboBoxCustomDrawItemEvent;
    FOnDeleteItemObject: TACLComboBoxDeleteItemObjectEvent;
    FOnGetDisplayItemGroupName: TACLComboBoxGetDisplayItemTextEvent;
    FOnGetDisplayItemName: TACLComboBoxGetDisplayItemTextEvent;
    FOnGetDisplayText: TACLComboBoxGetDisplayTextEvent;
    FOnPrepareDropDownData: TNotifyEvent;
    FOnPrepareDropDownList: TACLComboBoxPrepareDropDownListEvent;
    FOnSelect: TNotifyEvent;

    function GetDisplayText: string;
    procedure SetDropDownListSize(AValue: Integer);
    procedure SetStyleDropDownList(AValue: TACLStyleTreeList);
    procedure SetStyleDropDownListScrollBox(AValue: TACLStyleScrollBox);
    // Messages
    procedure CMExit(var Message: TMessage); message CM_EXIT;
  protected
    FChangeLockCount: Integer;
    FItemIndex: Integer;

    procedure CalculateContent(ARect: TRect); override;
    function GetCount: Integer; virtual; abstract;
    function GetDropDownList(out AList: TACLTreeListSubClass): Boolean;
    procedure ItemIndexChanged; virtual;
    procedure Loaded; override;
    procedure PaintCore; override;
    procedure PostValue(AItemIndex: Integer; const AItemText: string);
    procedure SetItemIndex(AValue: Integer); virtual;
    procedure SetTargetDPI(AValue: Integer); override;
    function ValidateItemIndex(AValue: Integer): Integer;

    // Keyboard
    function IsDropDownKey(Key: Word; Shift: TShiftState): Boolean; overload; virtual;
    function IsDropDownKey(Key: WideChar): Boolean; overload; virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyChar(var Key: WideChar); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;

    // Events
    procedure DoBeforeRemoveItem(AObject: TObject); virtual;
    procedure DoCustomDrawItem(ACanvas: TCanvas;
      const R: TRect; AIndex: Integer; var AHandled: Boolean); virtual;
    procedure DoDropDown; override;
    procedure DoGetDisplayText(AIndex: Integer; var AText: string); virtual;
    procedure DoGetGroupName(AIndex: Integer; var AText: string); virtual;
    procedure DoPrepareDropDownData;
    procedure DoPrepareDropDownList(AList: TACLTreeListSubClass); virtual;
    procedure DoSelect; virtual;

    //# Properties
    property DropDownListSize: Integer
      read FDropDownListSize write SetDropDownListSize default 8;
    property StyleDropDownList: TACLStyleTreeList
      read FStyleDropDownList write SetStyleDropDownList;
    property StyleDropDownListScrollBox: TACLStyleScrollBox
      read FStyleDropDownListScrollBox write SetStyleDropDownListScrollBox;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateInplace(const AParams: TACLInplaceInfo); override;
    destructor Destroy; override;
    procedure ChangeItemIndex(AValue: Integer); virtual;
    function MouseWheel(Direction: TACLMouseWheelDirection;
      Shift: TShiftState; const MousePos: TPoint): Boolean; override;
    procedure LockChanges(ALock: Boolean);
    //# Properties
    property Count: Integer read GetCount;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;
    //# Events
    property OnCustomDraw: TACLComboBoxCustomDrawEvent
      read FOnCustomDraw write FOnCustomDraw;
    property OnCustomDrawItem: TACLComboBoxCustomDrawItemEvent
      read FOnCustomDrawItem write FOnCustomDrawItem;
    property OnDeleteItemObject: TACLComboBoxDeleteItemObjectEvent
      read FOnDeleteItemObject write FOnDeleteItemObject;
    property OnGetDisplayText: TACLComboBoxGetDisplayTextEvent
      read FOnGetDisplayText write FOnGetDisplayText;
    property OnGetDisplayItemGroupName: TACLComboBoxGetDisplayItemTextEvent
      read FOnGetDisplayItemGroupName write FOnGetDisplayItemGroupName;
    property OnGetDisplayItemName: TACLComboBoxGetDisplayItemTextEvent
      read FOnGetDisplayItemName write FOnGetDisplayItemName;
    property OnPrepareDropDownData: TNotifyEvent
      read FOnPrepareDropDownData write FOnPrepareDropDownData;
    property OnPrepareDropDownList: TACLComboBoxPrepareDropDownListEvent
      read FOnPrepareDropDownList write FOnPrepareDropDownList;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
  end;

  { TACLBasicComboBoxDropDown }

  TACLBasicComboBoxDropDown = class(TACLPopupWindow,
    IACLControl,
    IACLCompoundControlSubClassContainer,
    IACLCursorProvider)
  strict private
    FCapturedObject: TObject;
    FList: TACLTreeListSubClass;
    FOwner: TACLBasicComboBox;

    function CalculateHeight: Integer;
    // IACLControl
    function GetFont: TFont;
    procedure InvalidateRect(const R: TRect);
    // IACLCompoundControlSubClassContainer
    function GetControl: TWinControl;
    function GetFocused: Boolean;
    // IACLCursorProvider
    function GetCursor(const P: TPoint): TCursor; reintroduce;
    // Handlers
    procedure HandlerCustomDraw(Sender: TObject; ACanvas: TCanvas;
      const R: TRect; ANode: TACLTreeListNode; var AHandled: Boolean);
    procedure HandlerGetGroupName(Sender: TObject;
      ANode: TACLTreeListNode; var AGroupName: string);
    procedure HandlerIncSearch(Sender: TObject);
    // Messages
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure DoInit; virtual; abstract;
    procedure DoShow; override;
    procedure DpiChanged; override;

    //# Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    //# Drawing
    procedure Paint; override;

    function AddItem(ACaption: string): TACLTreeListNode;
    procedure SyncItemIndex;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdjustSize; override;
    procedure AfterConstruction; override;
    procedure ClosePopup(AAccept: Boolean); reintroduce;
    //# Properties
    property Owner: TACLBasicComboBox read FOwner;
    property List: TACLTreeListSubClass read FList;
  end;

  { TACLBasicComboBoxUIInsightAdapter }

  TACLBasicComboBoxUIInsightAdapter = class(TACLUIInsightAdapterWinControl)
  public
    class function GetCaption(AObject: TObject; out AValue: string): Boolean; override;
  end;

{$ENDREGION}

{$REGION ' ComboBox '}

  { TACLComboBox }

  {$SCOPEDENUMS ON}
  TACLComboBoxAutoCompleteMode = (False, Standard, Lookup);
  {$SCOPEDENUMS OFF}

  TACLComboBoxMode = (cbmEdit, cbmList);
  TACLComboBox = class(TACLBasicComboBox)
  strict private
    FAutoComplete: TACLComboBoxAutoCompleteMode;
    FAutoCompletionLastKey: Word;
    FItems: TStrings;
    FMode: TACLComboBoxMode;
    FTextChangeLockCount: Integer;

    procedure DoAutoComplete;
    function GetHasSelection: Boolean;
    function GetSelectedObject: TObject;
    procedure SetItems(AItems: TStrings);
    procedure SetMode(AValue: TACLComboBoxMode);
  protected
    function CreateDropDownWindow: TACLPopupWindow; override;

    // Keyboard
    function IsDropDownKey(Key: WideChar): Boolean; overload; override;
    function IsDropDownKey(Key: Word; Shift: TShiftState): Boolean; overload; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    // Data
    function GetCount: Integer; override;
    procedure ItemIndexChanged; override;
    procedure SetItemIndex(AValue: Integer); override;
    procedure SetTextCore(const AValue: string); override;
    procedure SynchronizeText;
    procedure TextChanged; override;

    // Events
    procedure DoStringChanged; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateInplace(const AParams: TACLInplaceInfo); override;
    destructor Destroy; override;
    procedure AddItem(const S: string; AObject: TObject = nil);
    function IndexOf(const S: string): Integer;
    function IndexOfObject(AObject: TObject): Integer;
    procedure Localize(const ASection, AName: string); override;
    //# Properties
    property HasSelection: Boolean read GetHasSelection;
    property SelectedObject: TObject read GetSelectedObject;
    property Value;
  published
    property AutoComplete: TACLComboBoxAutoCompleteMode
      read FAutoComplete write FAutoComplete default TACLComboBoxAutoCompleteMode.Standard;
    property AutoSize;
    property Borders;
    property Buttons;
    property ButtonsImages;
    property DropDownListSize;
    property NumbersOnly;
    property Items: TStrings read FItems write SetItems;
    property ItemIndex; // after Items
    property MaxLength;
    property Mode: TACLComboBoxMode read FMode write SetMode default cbmEdit;
    property ReadOnly;
    property ResourceCollection;
    property Style;
    property StyleButton;
    property StyleDropDownList;
    property StyleDropDownListScrollBox;
    property Text;
    property TextHint;
    //# Events
    property OnChange;
    property OnCustomDraw;
    property OnCustomDrawItem;
    property OnDeleteItemObject;
    property OnDropDown;
    property OnGetDisplayItemGroupName;
    property OnGetDisplayItemName;
    property OnGetDisplayText;
    property OnPrepareDropDownList;
    property OnSelect;
  end;

  { TACLComboBoxDropDown }

  TACLComboBoxDropDown = class(TACLBasicComboBoxDropDown)
  protected
    procedure DoInit; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  { TACLComboBoxDropDownButton }

  TACLComboBoxDropDownButton = class(TACLButtonSubClass)
  protected
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); override;
  public
    procedure AfterConstruction; override;
  end;

  { TACLComboBoxUIInsightAdapter }

  TACLComboBoxUIInsightAdapter = class(TACLBasicComboBoxUIInsightAdapter)
  public
    class procedure GetChildren(AObject: TObject;
      ABuilder: TACLUIInsightSearchQueueBuilder); override;
  end;

{$ENDREGION}

implementation

uses
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Math;

type

  { TACLComboBoxStrings }

  TACLComboBoxStrings = class(TStringList)
  strict private
    FOwner: TACLComboBox;
  protected
    procedure BeforeRemoveItem(AObject: TObject);
    procedure Changed; override;
  public
    constructor Create(AOwner: TACLComboBox);
    function FindItemBeginsWith(const AText: string): Integer;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
  end;

{$IFDEF FPC}
  TACLStringsHelper = class helper for TStrings
  public
    function Updating: Boolean;
  end;

function TACLStringsHelper.Updating: Boolean;
begin
  Result := UpdateCount > 0;
end;
{$ENDIF}

{$REGION ' Abstract '}

{ TACLStyleDropDownList }

procedure TACLStyleDropDownList.InitializeResources;
begin
  inherited;
  BorderColor.InitailizeDefaults('EditBox.Colors.BorderFocused', True);
end;

{ TACLAbstractComboBox }

procedure TACLAbstractComboBox.CalculateButtons(var ARect: TRect; AIndent: Integer);
var
  LRect: TRect;
begin
  inherited;
  if DropDownButtonVisible then
  begin
    LRect := ARect;
    LRect.Inflate(-AIndent);
    DropDownButton.Calculate(LRect.Split(srRight, StyleButton.Texture.FrameWidth));
    ARect.Right := DropDownButton.Bounds.Left;
  end
  else
    DropDownButton.Calculate(NullRect);
end;

function TACLAbstractComboBox.CreateDropDownButton: TACLButtonSubClass;
begin
  Result := TACLComboBoxDropDownButton.Create(Self, StyleButton);
end;

function TACLAbstractComboBox.CreateStyleButton: TACLStyleButton;
begin
  Result := TACLStyleEditButton.Create(Self);
end;

procedure TACLAbstractComboBox.MouseDown(
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and not FEditBox.Iteract and
    (SubClasses.HitTest(Point(X, Y)) = FEditBox)
  then
    DroppedDown := True
  else
    inherited;
end;
{$ENDREGION}

{$REGION ' Basic '}

{ TACLBasicComboBox }

constructor TACLBasicComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEditBox.OnDisplayFormat := GetDisplayText;
  FStyleDropDownList := TACLStyleDropDownList.Create(Self);
  FStyleDropDownListScrollBox := TACLStyleScrollBox.Create(Self);
  FDropDownListSize := 8;
  FLoadedItemIndex := -1;
  FItemIndex := -1;
end;

constructor TACLBasicComboBox.CreateInplace(const AParams: TACLInplaceInfo);
begin
  inherited CreateInplace(AParams);
  OnSelect := AParams.OnApply;
end;

destructor TACLBasicComboBox.Destroy;
begin
  FreeAndNil(FStyleDropDownListScrollBox);
  FreeAndNil(FStyleDropDownList);
  inherited;
end;

procedure TACLBasicComboBox.CalculateContent(ARect: TRect);
begin
  FContentBounds := ARect;
  inherited;
end;

procedure TACLBasicComboBox.ChangeItemIndex(AValue: Integer);
begin
  if csLoading in ComponentState then
  begin
    FLoadedItemIndex := AValue;
    Exit;
  end;

  FItemIndex := ValidateItemIndex(AValue);
  ItemIndexChanged;
  Invalidate;
end;

procedure TACLBasicComboBox.CMExit(var Message: TMessage);
begin
  HideDropDownWindowPostponed;
  inherited;
end;

procedure TACLBasicComboBox.DoBeforeRemoveItem(AObject: TObject);
begin
  if Assigned(OnDeleteItemObject) then
    OnDeleteItemObject(Self, AObject);
end;

procedure TACLBasicComboBox.DoCustomDrawItem(
  ACanvas: TCanvas; const R: TRect; AIndex: Integer; var AHandled: Boolean);
begin
  if Assigned(OnCustomDrawItem) then
    OnCustomDrawItem(Self, ACanvas, R, AIndex, AHandled);
end;

procedure TACLBasicComboBox.DoDropDown;
begin
  DoPrepareDropDownData;
  inherited;
end;

procedure TACLBasicComboBox.DoGetDisplayText(AIndex: Integer; var AText: string);
begin
  if Assigned(OnGetDisplayItemName) then
    OnGetDisplayItemName(Self, AIndex, AText);
end;

procedure TACLBasicComboBox.DoGetGroupName(AIndex: Integer; var AText: string);
begin
  if Assigned(OnGetDisplayItemGroupName) then
    OnGetDisplayItemGroupName(Self, AIndex, AText);
end;

procedure TACLBasicComboBox.DoSelect;
begin
  CallNotifyEvent(Self, OnSelect);
end;

procedure TACLBasicComboBox.DoPrepareDropDownData;
begin
  if Count = 0 then
    CallNotifyEvent(Self, OnPrepareDropDownData);
end;

procedure TACLBasicComboBox.DoPrepareDropDownList(AList: TACLTreeListSubClass);
begin
  if Assigned(OnPrepareDropDownList) then
    OnPrepareDropDownList(Self, AList);
end;

function TACLBasicComboBox.GetDisplayText: string;
begin
  Result := FEditBox.Text;
  if Assigned(OnGetDisplayText) then
    OnGetDisplayText(Self, Result)
  else
    if Assigned(OnGetDisplayItemName) and (ItemIndex >= 0) then
      OnGetDisplayItemName(Self, ItemIndex, Result);
end;

function TACLBasicComboBox.GetDropDownList(out AList: TACLTreeListSubClass): Boolean;
begin
  Result := DroppedDown;
  if Result then
    AList := TACLBasicComboBoxDropDown(DropDownWindow).List
end;

function TACLBasicComboBox.IsDropDownKey(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True;
end;

function TACLBasicComboBox.IsDropDownKey(Key: WideChar): Boolean;
begin
  Result := True;
end;

procedure TACLBasicComboBox.ItemIndexChanged;
begin
  if DroppedDown then
    TACLBasicComboBoxDropDown(DropDownWindow).SyncItemIndex;
  if (FChangeLockCount = 0) and not (csLoading in ComponentState) then
  begin
    DoSelect;
    Changed;
  end;
end;

procedure TACLBasicComboBox.KeyChar(var Key: WideChar);
var
  LDropDownList: TACLTreeListSubClass;
begin
  if GetDropDownList(LDropDownList) and IsDropDownKey(Key) then
    LDropDownList.KeyChar(Key)
  else
    inherited;
end;

procedure TACLBasicComboBox.KeyDown(var Key: Word; Shift: TShiftState);
var
  LDropDownList: TACLTreeListSubClass;
  LIndex: Integer;
begin
  if GetDropDownList(LDropDownList) and IsDropDownKey(Key, Shift) then
  begin
    LDropDownList.KeyDown(Key, Shift);
    Exit;
  end;

  inherited;

  if [ssShift, ssAlt, ssCtrl] * Shift = [] then
  begin
    case Key of
      vkUp:
        begin
          DoPrepareDropDownData;
          LIndex := Max(0, ItemIndex - 1);
        end;
      vkDown:
        begin
          DoPrepareDropDownData;
          LIndex := Min(Count - 1, ItemIndex + 1);
        end;
    else
      Exit;
    end;

    if LIndex <> ItemIndex then
    begin
      ItemIndex := LIndex;
      Execute(eaSelectAll);
    end;
    Key := 0;
  end;
end;

procedure TACLBasicComboBox.KeyUp(var Key: Word; Shift: TShiftState);
var
  LDropDownList: TACLTreeListSubClass;
begin
  if GetDropDownList(LDropDownList) and IsDropDownKey(Key, Shift) then
  begin
    LDropDownList.KeyUp(Key, Shift);
    case Key of
      vkReturn, vkEscape:
        TACLBasicComboBoxDropDown(DropDownWindow).ClosePopup(Key = VK_RETURN);
    end;
  end
  else
    inherited;
end;

procedure TACLBasicComboBox.Loaded;
begin
  inherited;
  ItemIndex := FLoadedItemIndex;
end;

procedure TACLBasicComboBox.LockChanges(ALock: Boolean);
begin
  if ALock then
    Inc(FChangeLockCount)
  else
    Dec(FChangeLockCount);
end;

function TACLBasicComboBox.MouseWheel(Direction: TACLMouseWheelDirection;
  Shift: TShiftState; const MousePos: TPoint): Boolean;
var
  LList: TACLTreeListSubClass;
begin
  Result := inherited;
  if not Result then
  begin
    if GetDropDownList(LList) then
      LList.MouseWheel(Direction, Shift)
    else
    begin
      DoPrepareDropDownData;
      ItemIndex := Max(0, ItemIndex - TACLMouseWheel.DirectionToInteger[Direction]);
    end;
    Result := True;
  end;
end;

procedure TACLBasicComboBox.PaintCore;
begin
  inherited;
  if Assigned(OnCustomDraw) then
    OnCustomDraw(Self, Canvas, FContentBounds);
end;

procedure TACLBasicComboBox.PostValue(AItemIndex: Integer; const AItemText: string);
begin
  // Если в OnSelect возникнет мобальный диалог с подтверждением -
  // он сфорсирует закрытие дропа, что приведет к разрушению стэка вызова.
  TACLMainThread.RunPostponed(
    procedure
    begin
      if InRange(AItemIndex, 0, Count - 1) then
        SetItemIndex(AItemIndex)
      else // если список является лукапом и заполнился на эвенте
        Text := AItemText;
      Execute(eaSelectAll);
    end, Self);
end;

procedure TACLBasicComboBox.SetDropDownListSize(AValue: Integer);
begin
  FDropDownListSize := EnsureRange(AValue, 1, 25);
end;

procedure TACLBasicComboBox.SetItemIndex(AValue: Integer);
begin
  AValue := ValidateItemIndex(AValue);
  if AValue <> FItemIndex then
    ChangeItemIndex(AValue);
end;

procedure TACLBasicComboBox.SetTargetDPI(AValue: Integer);
begin
  inherited;
  StyleDropDownList.TargetDPI := AValue;
  StyleDropDownListScrollBox.TargetDPI := AValue;
end;

procedure TACLBasicComboBox.SetStyleDropDownListScrollBox(AValue: TACLStyleScrollBox);
begin
  FStyleDropDownListScrollBox.Assign(AValue);
end;

procedure TACLBasicComboBox.SetStyleDropDownList(AValue: TACLStyleTreeList);
begin
  FStyleDropDownList.Assign(AValue);
end;

function TACLBasicComboBox.ValidateItemIndex(AValue: Integer): Integer;
begin
  Result := EnsureRange(AValue, -1, Count - 1);
end;

{ TACLBasicComboBoxDropDown }

constructor TACLBasicComboBoxDropDown.Create(AOwner: TComponent);
begin
  FOwner := AOwner as TACLBasicComboBox;
  inherited Create(AOwner);
  DropDownMode := True;

  FList := TACLTreeListSubClass.Create(Self);
  FList.OnCustomDrawNode := HandlerCustomDraw;
  FList.OnIncSearch := HandlerIncSearch;

  List.BeginUpdate;
  try
    if Assigned(Owner.OnGetDisplayItemGroupName) then
    begin
      List.OnGetNodeGroup := HandlerGetGroupName;
      List.OptionsBehavior.Groups := True;
    end;

    List.OptionsBehavior.GroupsFocus := False;
    List.OptionsBehavior.HotTrack := True;
    List.OptionsBehavior.IncSearchColumnIndex := 0;
    List.OptionsBehavior.IncSearchMode := ismFilter;
    List.OptionsBehavior.SortingMode := tlsmDisabled;
    List.OptionsView.Columns.Visible := False;
    List.OptionsView.Nodes.GridLines := [];
    List.Style := Owner.StyleDropDownList;
    List.StyleInplaceEdit := Owner.Style;
    List.StyleScrollBox := Owner.StyleDropDownListScrollBox;
    List.SetTargetDPI(FCurrentPPI);

    DoInit;

    Owner.DoPrepareDropDownList(List);
  finally
    List.EndUpdate;
  end;
end;

destructor TACLBasicComboBoxDropDown.Destroy;
begin
  FreeAndNil(FList);
  inherited;
end;

procedure TACLBasicComboBoxDropDown.AfterConstruction;
begin
  inherited AfterConstruction;
  SyncItemIndex;
end;

function TACLBasicComboBoxDropDown.AddItem(ACaption: string): TACLTreeListNode;
var
  LIndex: Integer;
begin
  LIndex := List.RootNode.ChildrenCount;
  Owner.DoGetDisplayText(LIndex, ACaption);
  Result := List.RootNode.AddChild;
  Result.Caption := ACaption;
  Result.Tag := LIndex;
end;

procedure TACLBasicComboBoxDropDown.AdjustSize;
begin
  if List <> nil then
  begin
    Height := CalculateHeight;
    List.MakeVisible(List.FocusedNode);
  end;
{$IFDEF FPC}
  inherited;
{$ENDIF}
end;

procedure TACLBasicComboBoxDropDown.AlignControls(AControl: TControl; var Rect: TRect);
begin
  if List <> nil then
    List.Calculate(Rect);
end;

function TACLBasicComboBoxDropDown.CalculateHeight: Integer;
var
  LCell: TACLCompoundControlBaseContentCell;
  LNode: Integer;
begin
  Result := 2;
  if List.AbsoluteVisibleNodes.Count > 0 then
  begin
    LNode := Min(List.AbsoluteVisibleNodes.Count, Owner.DropDownListSize) - 1;
    if List.ContentViewInfo.ViewItems.Find(List.AbsoluteVisibleNodes[LNode], LCell) then
      Result := LCell.AbsBounds.Bottom + List.Bounds.Height -
        List.ViewInfo.Content.ViewItemsArea.Height;
  end;
end;

procedure TACLBasicComboBoxDropDown.ClosePopup(AAccept: Boolean);
begin
  if AAccept and List.HasSelection then
    Owner.PostValue(List.FocusedNode.Tag, List.FocusedNode.Caption);
  inherited ClosePopup;
end;

procedure TACLBasicComboBoxDropDown.CMFontChanged(var Message: TMessage);
begin
  inherited;
  if List <> nil then
  begin
    List.FullRefresh;
    AdjustSize;
  end;
end;

procedure TACLBasicComboBoxDropDown.HandlerCustomDraw(
  Sender: TObject; ACanvas: TCanvas; const R: TRect;
  ANode: TACLTreeListNode; var AHandled: Boolean);
begin
  Owner.DoCustomDrawItem(ACanvas, R, ANode.Tag, AHandled);
end;

procedure TACLBasicComboBoxDropDown.HandlerGetGroupName(
  Sender: TObject; ANode: TACLTreeListNode; var AGroupName: string);
begin
  Owner.DoGetGroupName(ANode.Tag, AGroupName);
end;

procedure TACLBasicComboBoxDropDown.HandlerIncSearch(Sender: TObject);
var
  LNewHeight: Integer;
begin
  if List.IncSearch.Mode = ismFilter then
  begin
    LNewHeight := CalculateHeight;
    if LNewHeight <> Height then
    begin
      if Top < FOwner.ClientOrigin.Y then // над комбиком?
        SetBounds(Left, Top + Height - LNewHeight, Width, LNewHeight)
      else
        Height := LNewHeight;
    end;
  end;
end;

procedure TACLBasicComboBoxDropDown.InvalidateRect(const R: TRect);
begin
  acInvalidateRect(Self, R);
end;

procedure TACLBasicComboBoxDropDown.MouseDown(
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  List.MouseDown(Button, Shift, Point(X, Y));
  FCapturedObject := List.HitTest.HitObject;
end;

procedure TACLBasicComboBoxDropDown.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  List.MouseMove(Shift, Point(X, Y));
end;

procedure TACLBasicComboBoxDropDown.MouseUp(
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  List.MouseUp(Button, Shift, Point(X, Y));
  if (FCapturedObject = List.HitTest.HitObject) and List.HitTest.HitAtNode then
  begin
    if List.OptionsView.CheckBoxes then
    begin
      if not List.HitTest.IsCheckable then
        List.HitTest.Node.Checked := not List.HitTest.Node.Checked;
    end
    else
      ClosePopup(True);
  end;
end;

procedure TACLBasicComboBoxDropDown.Paint;
begin
  List.Draw(Canvas);
end;

procedure TACLBasicComboBoxDropDown.DoShow;
begin
  inherited;
  List.MakeVisible(List.FocusedNode);
end;

procedure TACLBasicComboBoxDropDown.DpiChanged;
begin
  inherited;
  if List <> nil then
    List.SetTargetDPI(FCurrentPPI);
end;

function TACLBasicComboBoxDropDown.GetControl: TWinControl;
begin
  Result := Self;
end;

function TACLBasicComboBoxDropDown.GetCursor(const P: TPoint): TCursor;
begin
  if List <> nil then
    Result := List.GetCursor(P)
  else
    Result := crDefault;
end;

function TACLBasicComboBoxDropDown.GetFocused: Boolean;
begin
  Result := True;
end;

function TACLBasicComboBoxDropDown.GetFont: TFont;
begin
  Result := Font;
end;

procedure TACLBasicComboBoxDropDown.SyncItemIndex;
var
  AItem: TACLTreeListNode;
begin
  if List.RootNode.Find(AItem, Owner.ItemIndex) then
    List.FocusedNode := AItem;
end;

procedure TACLBasicComboBoxDropDown.WndProc(var Message: TMessage);
const
  MSG_MOUSEWHEEL = {$IFDEF FPC}WM_MOUSEWHEEL{$ELSE}CM_MOUSEWHEEL{$ENDIF};
begin
  if Message.Msg = WM_MOUSEWHEEL then
    Message.Result := Owner.Perform(MSG_MOUSEWHEEL, Message.WParam, Message.LParam)
  else
    inherited;
end;

{ TACLBasicComboBoxUIInsightAdapter }

class function TACLBasicComboBoxUIInsightAdapter.GetCaption(
  AObject: TObject; out AValue: string): Boolean;
var
  LCtrl: TACLBasicComboBox absolute AObject;
begin
  Result := LCtrl.ItemIndex = -1;
  if Result then
    AValue := LCtrl.Text;
end;

{$ENDREGION}

{ TACLComboBox }

constructor TACLComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoComplete := TACLComboBoxAutoCompleteMode.Standard;
  FItems := TACLComboBoxStrings.Create(Self);
  FEditBox.Iteract := True;
end;

constructor TACLComboBox.CreateInplace(const AParams: TACLInplaceInfo);
begin
  inherited CreateInplace(AParams);
  Mode := cbmList;
end;

destructor TACLComboBox.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TACLComboBox.AddItem(const S: string; AObject: TObject = nil);
begin
  Items.AddObject(S, AObject)
end;

function TACLComboBox.CreateDropDownWindow: TACLPopupWindow;
begin
  Result := TACLComboBoxDropDown.Create(Self);
end;

procedure TACLComboBox.DoAutoComplete;
var
  LCurrText: string;
  LCurrTextLen: Integer;
  LDropDownList: TACLTreeListSubClass;
begin
  case AutoComplete of
    TACLComboBoxAutoCompleteMode.Lookup:
      begin
        DroppedDown := True;
        if GetDropDownList(LDropDownList) then
          LDropDownList.IncSearch.Text := FEditBox.Text;
      end;

    TACLComboBoxAutoCompleteMode.Standard:
      if (FAutoCompletionLastKey <> 0) and
         (FAutoCompletionLastKey <> vkDelete) and
         (FAutoCompletionLastKey <> vkBack) then
      begin
        LCurrText := FEditBox.Text;
        LCurrTextLen := acCharCount(LCurrText);
        FItemIndex := TACLComboBoxStrings(FItems).FindItemBeginsWith(LCurrText);
        if ItemIndex >= 0 then
        begin
          FEditBox.Text := Items.Strings[ItemIndex];
          FEditBox.Select(LCurrTextLen, acCharCount(FEditBox.Text) - LCurrTextLen);
        end;
      end;
  end;
end;

procedure TACLComboBox.DoStringChanged;
begin
  ItemIndex := Items.IndexOf(Text);
end;

function TACLComboBox.IndexOf(const S: string): Integer;
begin
  Result := Items.IndexOf(S);
end;

function TACLComboBox.IndexOfObject(AObject: TObject): Integer;
begin
  Result := Items.IndexOfObject(AObject);
end;

function TACLComboBox.IsDropDownKey(Key: WideChar): Boolean;
begin
  if AutoComplete = TACLComboBoxAutoCompleteMode.Lookup then
    Result := Ord(Key) in [{vkUp, vkDown, }vkEscape, vkReturn]
  else
    Result := inherited;
end;

function TACLComboBox.IsDropDownKey(Key: Word; Shift: TShiftState): Boolean;
begin
  if AutoComplete = TACLComboBoxAutoCompleteMode.Lookup then
    Result := Key in [vkUp, vkDown, vkEscape, vkReturn]
  else
    Result := inherited;
end;

procedure TACLComboBox.ItemIndexChanged;
begin
  SynchronizeText;
  inherited ItemIndexChanged;
end;

procedure TACLComboBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  FAutoCompletionLastKey := IfThen([ssCtrl, ssAlt] * Shift = [], Key);
  inherited KeyDown(Key, Shift);
end;

function TACLComboBox.GetCount: Integer;
begin
  Result := Items.Count;
end;

function TACLComboBox.GetHasSelection: Boolean;
begin
  Result := (ItemIndex >= 0) and (ItemIndex < Items.Count);
end;

function TACLComboBox.GetSelectedObject: TObject;
begin
  if HasSelection then
    Result := Items.Objects[ItemIndex]
  else
    Result := nil;
end;

procedure TACLComboBox.Localize(const ASection, AName: string);
var
  LPrevItemIndex: Integer;
begin
  LockChanges(True);
  try
    LPrevItemIndex := FItemIndex;
    try
      inherited;
      LangApplyToItems(LangSubSection(ASection, AName), Items);
    finally
      ItemIndex := LPrevItemIndex;
    end;
  finally
    LockChanges(False);
  end;
end;

procedure TACLComboBox.SetItems(AItems: TStrings);
begin
  FItems.Assign(AItems);
end;

procedure TACLComboBox.SetMode(AValue: TACLComboBoxMode);
begin
  if AValue <> FMode then
  begin
    FMode := AValue;
    if Mode = cbmList then
      DoPrepareDropDownData;
    FEditBox.Iteract := Mode = cbmEdit;
    FEditBox.Select(0, 0);
  end;
end;

procedure TACLComboBox.SetItemIndex(AValue: Integer);
begin
  AValue := ValidateItemIndex(AValue);
  if AValue <> FItemIndex then
    ChangeItemIndex(AValue)
  else
    if Items.Updating then
    begin
      LockChanges(True);
      try
        SynchronizeText;
      finally
        LockChanges(False);
      end;
    end;
end;

procedure TACLComboBox.SetTextCore(const AValue: string);
begin
  if not HasSelection or (Items[ItemIndex] <> AValue) then
    FItemIndex := Items.IndexOf(AValue);

  Inc(FTextChangeLockCount);
  try
    if (Mode = cbmList) and (ItemIndex < 0) then
      inherited SetTextCore(acEmptyStr)
    else
      inherited SetTextCore(AValue);
  finally
    Dec(FTextChangeLockCount);
  end;
end;

procedure TACLComboBox.SynchronizeText;
begin
  if ItemIndex >= 0 then
    Text := Items.Strings[ItemIndex]
  else
    Text := '';
end;

procedure TACLComboBox.TextChanged;
begin
  if FTextChangeLockCount = 0 then
  begin
    if (Mode = cbmEdit) and (AutoComplete <> TACLComboBoxAutoCompleteMode.False) then
    begin
      Inc(FTextChangeLockCount);
      try
        DoPrepareDropDownData;
        DoAutoComplete;
      finally
        Dec(FTextChangeLockCount);
      end;
    end
    else
      FItemIndex := Items.IndexOf(Text);

    inherited;
  end;
end;

{ TACLComboBoxDropDown }

constructor TACLComboBoxDropDown.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if TACLComboBox(Owner).AutoComplete = TACLComboBoxAutoCompleteMode.False then
    List.OptionsBehavior.IncSearchColumnIndex := -1;
  if TACLComboBox(Owner).AutoComplete = TACLComboBoxAutoCompleteMode.Lookup then
    List.OptionsBehavior.IncSearchAutoSelect := False;
end;

procedure TACLComboBoxDropDown.DoInit;
var
  I: Integer;
begin
  for I := 0 to TACLComboBox(Owner).Items.Count - 1 do
    AddItem(TACLComboBox(Owner).Items[I]);
end;

{ TACLComboBoxDropDownButton }

procedure TACLComboBoxDropDownButton.AfterConstruction;
begin
  inherited;
  Part := abpDropDownArrow;
end;

procedure TACLComboBoxDropDownButton.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Texture.Draw(ACanvas, R, 5 + Ord(State));
end;

{ TACLComboBoxStrings }

constructor TACLComboBoxStrings.Create(AOwner: TACLComboBox);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TACLComboBoxStrings.BeforeRemoveItem(AObject: TObject);
begin
  if Assigned(AObject) and Assigned(FOwner) then
    FOwner.DoBeforeRemoveItem(AObject);
end;

procedure TACLComboBoxStrings.Clear;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
    BeforeRemoveItem(Objects[I]);
  inherited Clear;
end;

procedure TACLComboBoxStrings.Delete(Index: Integer);
begin
  BeforeRemoveItem(Objects[Index]);
  inherited Delete(Index);
end;

function TACLComboBoxStrings.FindItemBeginsWith(const AText: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  if Length(AText) > 0 then
    for I := 0 to Count - 1 do
    begin
      if Copy(Strings[I], 1, Length(AText)) = AText then
        Exit(I);
    end;
end;

procedure TACLComboBoxStrings.Changed;
begin
  if UpdateCount = 0 then
  begin
    if Assigned(FOwner) then
      FOwner.DoStringChanged;
    inherited Changed;
  end;
end;

{ TACLComboBoxUIInsightAdapter }

class procedure TACLComboBoxUIInsightAdapter.GetChildren(
  AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
var
  LComboBox: TACLComboBox absolute AObject;
  I: Integer;
begin
  for I := 0 to LComboBox.Count - 1 do
    ABuilder.AddCandidate(LComboBox, LComboBox.Items[I]);
end;

initialization
  TACLUIInsight.Register(TACLBasicComboBox, TACLBasicComboBoxUIInsightAdapter);
  TACLUIInsight.Register(TACLComboBox, TACLComboBoxUIInsightAdapter);
end.
