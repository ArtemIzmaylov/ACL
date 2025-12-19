////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Memo
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.Memo;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
  WSLCLClasses,
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
  {Vcl.}Clipbrd,
  {Vcl.}Controls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}Menus,
  {Vcl.}StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Math,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.TextLayout,
  ACL.Timers,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Menus,
  ACL.UI.Resources,
  ACL.UndoRedo,
  ACL.Utils.Clipboard,
  ACL.Utils.FileSystem,
  ACL.Utils.DPIAware,
  ACL.Utils.Shell,
  ACL.Utils.Strings;

const
  // Changes Notifications
  mcnMakeVisible = cccnLast + 1;
  mcnSelection   = cccnLast + 2;
  mcnTextChanged = cccnLast + 3;
  mcnLast        = mcnTextChanged;

type
  TACLMemoSubClass = class;

  { TACLStyleMemo }

  TACLStyleMemo = class(TACLStyleEdit)
  protected
    procedure InitializeResources; override;
  public
    property ColorTextHyperlink: TACLResourceColor index 20
      read GetColor write SetColor stored IsColorStored;
  end;

  { TACLMemoLineInfo }

  TACLMemoLineInfo = record
  public
    InTextFinish: Integer;
    InTextStart: Integer;
    LineBreak: Boolean;
    //LineIndex: Integer;
    RowIndex: Integer;
  end;

  { TACLMemoTextLayout }

  TACLMemoTextLayout = class(TACLTextLayout)
  protected
    FSubClass: TACLMemoSubClass;
    function GetDefaultHyperLinkColor: TColor; override;
    function GetDefaultTextColor: TColor; override;
  public
    constructor Create(ASubClass: TACLMemoSubClass);
    // Properties (ReadOnly!!)
    property Rows: TACLTextLayoutRows read FRows;
    property RowsDirty: Boolean read FRowsDirty;
  end;

  { TACLMemoTextSelectionPainter }

  TACLMemoTextSelectionPainter = class(TACLTextLayoutPainter)
  protected
    procedure UpdateTextColor; override;
  public
    constructor Create(AOwner: TACLTextLayout; ARender: TACLTextLayoutRender); override;
  end;

  { TACLMemoViewInfo }

  TACLMemoViewInfo = class(TACLCompoundControlScrollContainerViewInfo)
  strict private
    FCaretGoal: TPoint;
    FCaretRect: TRect;
    FCaretVisible: Boolean;
    FSelection: TACLRegion;

    function GetLayout: TACLMemoTextLayout;
    function GetSubClass: TACLMemoSubClass;
    procedure SetCaretVisible(AValue: Boolean);
  protected
    procedure CalculateCaretRect;
    procedure CalculateContentLayout; override;
    procedure CalculateSelection;
    procedure DoDrawCells(ACanvas: TCanvas); override;
    function GetOrigin: TPoint;
    function GetScrollInfo(AKind: TScrollBarKind;
      out AInfo: TACLScrollInfo): Boolean; override;
    //# Properties
    property CaretVisible: Boolean read FCaretVisible write SetCaretVisible;
  public
    constructor Create(AOwner: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    procedure Calculate(const R: TRect; AChanges: TIntegerSet); override;
    //# Properties
    property CaretGoal: TPoint read FCaretGoal write FCaretGoal;
    property CaretRect: TRect read FCaretRect;
    property Layout: TACLMemoTextLayout read GetLayout;
    property Selection: TACLRegion read FSelection;
    property SubClass: TACLMemoSubClass read GetSubClass;
  end;

  { TACLMemoDragObject }

  TACLMemoDragObject = class(TACLCompoundControlDragObject)
  strict private
    FCaretPos: Integer;
    FSubClass: TACLMemoSubClass;
  public
    constructor Create(ASubClass: TACLMemoSubClass);
    function DragStart: Boolean; override;
    procedure DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer); override;
  end;

  { TACLMemoSubClass }

  TACLMemoSubClass = class(TACLCompoundControlSubClass,
    IACLEditActions,
    IACLDraggableObject)
  public const
    DefaultUndoLimit = 64;
  strict private
    FAutoScroll: Boolean;
    FCaretBlink: TACLTimer;
    FCaretInLineEnd: Boolean;
    FCaretPos: Integer;
    FEditable: Boolean;
    FHistory: TACLCustomHistoryManager;
    FLayout: TACLMemoTextLayout;
    FLayoutHitTest: TACLTextLayoutHitTest;
    FLines: TStrings;
    FReadOnly: Boolean;
    FSelectionPin: Integer;
    FSelectionRange: Integer;
    FStyle: TACLStyleMemo;
    FTextSettings: TACLTextFormatSettings;

    FOnChanged: TNotifyEvent;
    FOnHyperlink: TACLHyperlinkEvent;
    FOnSelectionChanged: TNotifyEvent;

    function CheckIsTag(ACaretPos: Integer): Boolean;
    function GetAlignment: TAlignment;
    function GetCaret: TPoint;
    function GetSelLength: Integer;
    function GetSelLine: string;
    function GetSelStart: Integer;
    function GetSelText: string;
    function GetText: string;
    function GetViewInfo: TACLMemoViewInfo;
    function GetWordWrap: Boolean;
    procedure SetAlignment(AValue: TAlignment);
    procedure SetAutoScroll(AValue: Boolean);
    procedure SetCaret(const AValue: TPoint);
    procedure SetCaretPos(AValue: Integer);
    procedure SetEditable(AValue: Boolean);
    procedure SetSelLength(AValue: Integer);
    procedure SetSelStart(AValue: Integer);
    procedure SetSelText(const AValue: string);
    procedure SetText(const AValue: string);
    procedure SetTextSettings(const AValue: TACLTextFormatSettings);
    procedure SetWordWrap(AValue: Boolean);
  protected
    function CreateDragObject(const AInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
    function CreateViewInfo: TACLCompoundControlCustomViewInfo; override;
    procedure FocusChanged; override;
    
    //# General
    function LineInfo(ACaretPos: Integer): TACLMemoLineInfo;
    function NextChar(ACaretPos: Integer; AGoForward: Boolean): Integer;
    function NextWord(ACaretPos: Integer; AGoForward: Boolean): Integer;
    procedure MoveSelection(ACaret, ASelectionRange: Integer;
      ALineEnd: Boolean = False; AMakeCaretVisible: Boolean = True); overload;
    procedure MoveSelection(ACaret: Integer; AShift: TShiftState; AKey: Word = 0); overload;
    procedure MoveSelection(ACaret: Integer; AShift: TShiftState; ALineEnd: Boolean); overload;
    procedure MoveSelectionToLineEnd(AShift: TShiftState);
    procedure MoveSelectionToLineStart(AShift: TShiftState);
    procedure MoveSelectionToNextPage(AGoForward: Boolean;AShift: TShiftState);
    procedure MoveSelectionToNextRow(AGoForward: Boolean; AShift: TShiftState);
    procedure ProcessCaretBlinking(Sender: TObject);
    procedure ProcessChanges(AChanges: TIntegerSet = []); override;
    procedure ProcessContextMenuItem(Sender: TObject);
    procedure ProcessKeyDelete(AShift: TShiftState; AGoForward: Boolean);
    procedure ProcessKeyDown(var AKey: Word; AShift: TShiftState); override;
    procedure ProcessKeyPress(var AKey: WideChar); override;
    procedure ProcessMouseClick(AShift: TShiftState); override;
    procedure ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState); override;
    procedure SelectNearestRow(ACaret: Integer);
    procedure SelectNearestWord(ACaret: Integer);

    //# Properties
    property CaretInLineEnd: Boolean read FCaretInLineEnd;
    property Layout: TACLMemoTextLayout read FLayout;
    property LayoutHitTest: TACLTextLayoutHitTest read FLayoutHitTest;
    property SelectionRange: Integer read FSelectionRange; // may be negative
    property ViewInfo: TACLMemoViewInfo read GetViewInfo;
  public
    constructor Create(AOwner: IACLCompoundControlSubClassContainer);
    destructor Destroy; override;
    procedure MakeVisible(const ARect: TRect); overload;
    procedure MakeVisible(const ARow: Integer); overload;
    procedure Select(AStart, ALength: Integer; AGoForward: Boolean = True);
    procedure SetTargetDPI(AValue: Integer); override;
    procedure SetTextEx(const AText: string; const ATextSettings: TACLTextFormatSettings);
    procedure UpdateHitTest(const P: TPoint; ACalcHint: Boolean); override;
    function WantSpecialKey(Key: Word; Shift: TShiftState): Boolean; override;

    // Actions
    function CanExecute(AAction: TACLEditAction): Boolean;
    procedure Execute(AAction: TACLEditAction);

    //# Scrolling
    procedure ScrollHorizontally(const AScrollCode: TScrollCode); override;
    procedure ScrollVertically(const AScrollCode: TScrollCode); override;

    //# Properties
    property Alignment: TAlignment read GetAlignment write SetAlignment;
    property AutoScroll: Boolean read FAutoScroll write SetAutoScroll;
    property Caret: TPoint read GetCaret write SetCaret;
    property CaretPos: Integer read FCaretPos write SetCaretPos;
    property Editable: Boolean read FEditable write SetEditable default True;
    property History: TACLCustomHistoryManager read FHistory;
    property Lines: TStrings read FLines;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelLine: string read GetSelLine;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelText: string read GetSelText write SetSelText;
    property Style: TACLStyleMemo read FStyle;
    property Text: string read GetText write SetText;
    property TextSettings: TACLTextFormatSettings read FTextSettings write SetTextSettings;
    property WordWrap: Boolean read GetWordWrap write SetWordWrap default True;

    //# Events
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property OnSelectionChanged: TNotifyEvent read FOnSelectionChanged write FOnSelectionChanged;
    property OnHyperlink: TACLHyperlinkEvent read FOnHyperlink write FOnHyperlink;
  end;

  { TACLCustomMemo }

  TACLCustomMemo = class(TACLCompoundControl, IACLEditActions, IACLTextEdit)
  strict private
    FBorders: Boolean;

    function GetAlignment: TAlignment;
    function GetCaretPos: TPoint;
    function GetLines: TStrings;
    function GetOnChange: TNotifyEvent;
    function GetOnHyperlink: TACLHyperlinkEvent;
    function GetOnSelectionChanged: TNotifyEvent;
    function GetReadOnly: Boolean;
    function GetSelLength: Integer;
    function GetSelStart: Integer;
    function GetSelText: string;
    function GetStyle: TACLStyleMemo;
    function GetSubClass: TACLMemoSubClass; inline;
    function GetText: string; inline;
    function GetWordWrap: Boolean; inline;
    procedure SetAlignment(AValue: TAlignment);
    procedure SetBorders(AValue: Boolean);
    procedure SetCaretPos(const AValue: TPoint);
    procedure SetLines(AValue: TStrings);
    procedure SetOnChange(AValue: TNotifyEvent);
    procedure SetOnHyperlink(AValue: TACLHyperlinkEvent);
    procedure SetOnSelectionChanged(AValue: TNotifyEvent);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetSelLength(AValue: Integer);
    procedure SetSelStart(AValue: Integer);
    procedure SetSelText(const Value: string);
    procedure SetStyle(AValue: TACLStyleMemo);
    procedure SetText(const AValue: string);
    procedure SetWordWrap(AValue: Boolean);
  protected
    function CreateSubClass: TACLCompoundControlSubClass; override;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
    procedure FocusChanged; override;
    function GetContentOffset: TRect; override;
    procedure InvalidateBorders;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure Paint; override;
    procedure ResourceChanged; override;
    //# Properties
    property Alignment: TAlignment read GetAlignment write SetAlignment default taLeftJustify;
    property Borders: Boolean read FBorders write SetBorders default True;
    property CaretPos: TPoint read GetCaretPos write SetCaretPos;
    property Lines: TStrings read GetLines write SetLines;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelText: string read GetSelText write SetSelText;
    property Style: TACLStyleMemo read GetStyle write SetStyle;
    property SubClass: TACLMemoSubClass read GetSubClass implements IACLEditActions;
    property Text: string read GetText write SetText;
    property WordWrap: Boolean read GetWordWrap write SetWordWrap default False;
    //# Events
    property OnChange: TNotifyEvent read GetOnChange write SetOnChange;
    property OnHyperlink: TACLHyperlinkEvent read GetOnHyperlink write SetOnHyperlink;
    property OnSelectionChanged: TNotifyEvent read GetOnSelectionChanged write SetOnSelectionChanged;
  public
    constructor Create(AOwner: TComponent); override;
    function CanExecute(AAction: TACLEditAction): Boolean;
    procedure Execute(AAction: TACLEditAction);
    procedure MakeVisible(ARow: Integer);
    procedure Select(AStart, ALength: Integer; AGoForward: Boolean = True);
  end;

  { TACLMemo }

  TACLMemo = class(TACLCustomMemo)
  public
    property CaretPos;
    property SelLength;
    property SelStart;
    property SelText;
    property SubClass;
  published
    property Borders;
    property FocusOnClick default True;
    property Padding;
    property ReadOnly;
    property ResourceCollection;
    property Style;
    property StyleScrollBox;
    property Lines stored False;
    property Text;
    property Transparent;
    property WordWrap;
    //# Events
    property OnCalculated;
    property OnChange;
    property OnHyperlink;
    property OnSelectionChanged;
    property OnUpdateState;
  end;

implementation

uses
  ACL.MUI,
  ACL.Utils.Common;

type

  { TACLMemoLines }

  TACLMemoLines = class(TStrings)
  strict private
    FSubClass: TACLMemoSubClass;
    procedure ReplaceRow(AIndex: Integer;
      const AValue: string; AEntire: Boolean);
  protected
    function Get(Index: Integer): string; override;
    function GetCount: Integer; override;
    function GetObject(Index: Integer): TObject; override;
    function GetTextStr: string; override;
    procedure Put(Index: Integer; const S: string); override;
    procedure PutObject(Index: Integer; AObject: TObject); override;
    procedure SetTextStr(const Value: string); override;
  public
    constructor Create(ASubClass: TACLMemoSubClass);
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const S: string); override;
  end;

  { TACLMemoHistoryCommand }

  TACLMemoHistoryCommand = class(TACLHistoryCommand)
  strict private
    FCaretLineEnd: Boolean;
    FCaretPos: Integer;
    FSelectionRange: Integer;
    FSubClass: TACLMemoSubClass;
    FText: string;
  protected
    procedure DoIt(AAction: TACLHistoryCommandAction); override;
  public
    constructor Create(ASubClass: TACLMemoSubClass);
  end;

{ TACLStyleMemo }

procedure TACLStyleMemo.InitializeResources;
begin
  inherited;
  ColorTextHyperlink.InitailizeDefaults('Labels.Colors.TextHyperlink');
end;

{ TACLMemoTextLayout }

constructor TACLMemoTextLayout.Create(ASubClass: TACLMemoSubClass);
begin
  inherited Create(ASubClass.Font);
  FSubClass := ASubClass;
  SetOption(atoNoClip, True);
end;

function TACLMemoTextLayout.GetDefaultHyperLinkColor: TColor;
begin
  if FSubClass.EnabledContent then
    Result := FSubClass.Style.ColorTextHyperlink.AsColor
  else
    Result := FSubClass.Style.ColorTextDisabled.AsColor;
end;

function TACLMemoTextLayout.GetDefaultTextColor: TColor;
begin
  Result := FSubClass.Style.ColorsText[FSubClass.EnabledContent];
end;

{ TACLMemoTextSelectionPainter }

constructor TACLMemoTextSelectionPainter.Create(
  AOwner: TACLTextLayout; ARender: TACLTextLayoutRender);
begin
  CreateEx(AOwner, ARender, False, True);
end;

procedure TACLMemoTextSelectionPainter.UpdateTextColor;
begin
  Font.Color := TACLMemoTextLayout(Owner).FSubClass.Style.ColorTextSelected.AsColor;
end;

{ TACLMemoDragObject }

constructor TACLMemoDragObject.Create(ASubClass: TACLMemoSubClass);
begin
  inherited Create;
  FSubClass := ASubClass;
end;

procedure TACLMemoDragObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);
var
  LCaretPos: Integer;
begin
  LCaretPos := FSubClass.LayoutHitTest.PositionInText;
  if LCaretPos >= 0 then
    FSubClass.MoveSelection(LCaretPos, FCaretPos - LCaretPos, FSubClass.LayoutHitTest.PositionInLineEnd);
  UpdateAutoScrollDirection(P, FSubClass.ViewInfo.ClientBounds);
end;

function TACLMemoDragObject.DragStart: Boolean;
begin
  FCaretPos := FSubClass.CaretPos;
  Result := True;
end;

{ TACLMemoHistoryCommand }

constructor TACLMemoHistoryCommand.Create(ASubClass: TACLMemoSubClass);
begin
  FSubClass := ASubClass;
end;

procedure TACLMemoHistoryCommand.DoIt(AAction: TACLHistoryCommandAction);
var
  LCaretLineEnd: Boolean;
  LCaretPos: Integer;
  LSelectionRange: Integer;
  LText: string;
begin
  LCaretPos := FCaretPos;
  LCaretLineEnd := FCaretLineEnd;
  LSelectionRange := FSelectionRange;
  LText := FText;

  FText := FSubClass.Text;
  FCaretPos := FSubClass.CaretPos;
  FCaretLineEnd := FSubClass.CaretInLineEnd;
  FSelectionRange := FSubClass.SelectionRange;

  if AAction in [hcaRedo, hcaUndo] then
  begin
    FSubClass.Text := LText;
    FSubClass.MoveSelection(LCaretPos, LSelectionRange, LCaretLineEnd);
  end;
end;

{ TACLMemoSubClass }

constructor TACLMemoSubClass.Create(AOwner: IACLCompoundControlSubClassContainer);
begin
  inherited Create(AOwner);
  FTextSettings := TACLTextFormatSettings.PlainText;
  FHistory := TACLCustomHistoryManager.Create(DefaultUndoLimit);
  FLayout := TACLMemoTextLayout.Create(Self);

  FLayoutHitTest := TACLTextLayoutHitTest.Create(FLayout);
  FLines := TACLMemoLines.Create(Self);
  FStyle := TACLStyleMemo.Create(Self);
  FAutoScroll := True;
  FEditable := True;
end;

destructor TACLMemoSubClass.Destroy;
begin
  FreeAndNil(FLines);
  FreeAndNil(FHistory);
  FreeAndNil(FCaretBlink);
  FreeAndNil(FLayoutHitTest);
  FreeAndNil(FLayout);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

function TACLMemoSubClass.CanExecute(AAction: TACLEditAction): Boolean;
begin
  case AAction of
    eaCut, eaDelete:
      Result := (SelLength > 0) and not ReadOnly;
    eaCopy:
      Result := (SelLength > 0);
    eaPaste:
      Result := not ReadOnly and Clipboard.HasText;
    eaUndo:
      Result := History.CanUndo;
    eaSelectAll:
      Result := (Text <> '') and not ((SelStart = 0) and (SelLength = Length(Text)));
  else
    Result := False;
  end;
end;

function TACLMemoSubClass.CheckIsTag(ACaretPos: Integer): Boolean;
var
  LBlock: TACLTextLayoutBlock;
begin
  Result := Layout.FindBlock(ACaretPos, LBlock) and (LBlock is TACLTextLayoutBlockStyle);
end;

function TACLMemoSubClass.CreateDragObject(
  const AInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
begin
  Result := TACLMemoDragObject.Create(Self);
end;

function TACLMemoSubClass.CreateViewInfo: TACLCompoundControlCustomViewInfo;
begin
  Result := TACLMemoViewInfo.Create(Self);
end;

procedure TACLMemoSubClass.Execute(AAction: TACLEditAction);
begin
  case AAction of
    eaCopy:
      Clipboard.AsText := SelText;

    eaCut:
      if not ReadOnly then
      begin
        Execute(eaCopy);
        SelText := '';
      end;

    eaDelete:
      if not ReadOnly then
        SelText := '';

    eaPaste:
      if not ReadOnly then
        SelText := Clipboard.AsText;

    eaSelectAll:
      MoveSelection(Length(Text), -Length(Text), False, False);

    eaUndo:
      History.Undo;
  end;
end;

procedure TACLMemoSubClass.FocusChanged;
begin
  History.Clear;
  inherited;
  if Editable then
  begin
    FreeAndNil(FCaretBlink);
    if Focused then
    begin
      FCaretBlink := TACLTimer.CreateEx(ProcessCaretBlinking, GetCaretBlinkTime);
      FCaretBlink.Start;
    end;
    ViewInfo.CaretVisible := Focused;
  end;
end;

function TACLMemoSubClass.GetAlignment: TAlignment;
begin
  Result := Layout.HorzAlignment;
end;

function TACLMemoSubClass.GetCaret: TPoint;
var
  LLine: TACLMemoLineInfo;
begin
  LLine := LineInfo(CaretPos - Ord(CaretInLineEnd));
  Result.X := CaretPos - LLine.InTextStart;
  Result.Y := LLine.RowIndex;
end;

function TACLMemoSubClass.GetSelLength: Integer;
begin
  Result := Abs(SelectionRange);
end;

function TACLMemoSubClass.GetSelLine: string;
var
  LLine: TACLMemoLineInfo;
begin
  LLine := LineInfo(CaretPos);
  Result := Copy(Text, LLine.InTextStart + 1, LLine.InTextFinish - LLine.InTextStart);
end;

function TACLMemoSubClass.GetSelStart: Integer;
begin
  Result := CaretPos + Min(SelectionRange, 0);
end;

function TACLMemoSubClass.GetSelText: string;
begin
  Result := Copy(Text, 1 + SelStart, SelLength);
end;

function TACLMemoSubClass.GetText: string;
begin
  Result := Layout.Text;
end;

function TACLMemoSubClass.GetViewInfo: TACLMemoViewInfo;
begin
  Result := TACLMemoViewInfo(inherited ViewInfo);
end;

function TACLMemoSubClass.GetWordWrap: Boolean;
begin
  Result := atoWordWrap and Layout.Options <> 0;
end;

function TACLMemoSubClass.LineInfo(ACaretPos: Integer): TACLMemoLineInfo;
var
  LBase: PChar;
  LBlock: TACLTextLayoutBlock;
  LRow: TACLTextLayoutRow;
begin
  Result.InTextStart := ACaretPos;
  Result.InTextFinish := ACaretPos;
  Result.LineBreak := False;
  Result.RowIndex := -1;

  if Layout.FindBlock(Min(ACaretPos, Length(Text) - 1), LBlock) then
  begin
    Result.RowIndex := Layout.GetRowIndex(LBlock);
    if Result.RowIndex >= 0 then
    begin
      LBase := PChar(Layout.Text);
      LRow := Layout.Rows[Result.RowIndex];
      Result.LineBreak := (LRow.LineBreak <> nil) or // linebreak or
        (Result.RowIndex + 1 = Layout.Rows.Count);   // last line in document
      Result.InTextStart  := LRow.PositionInText - LBase;
      Result.InTextFinish := LRow.LineEndPosition - LBase;
    end;
  end;
end;

procedure TACLMemoSubClass.MakeVisible(const ARow: Integer);
begin
  Layout.Calculate(MeasureCanvas);
  if InRange(ARow, 0, Layout.RowCount - 1) then
    MakeVisible(Layout.Rows[ARow].Bounds + ViewInfo.GetOrigin);
end;

procedure TACLMemoSubClass.MakeVisible(const ARect: TRect);
begin
  ViewInfo.Viewport := ViewInfo.Viewport +
    acCalculateScrollToDelta(ARect, ViewInfo.ClientBounds, TACLScrollToMode.MakeVisible);
end;

procedure TACLMemoSubClass.MoveSelection(
  ACaret, ASelectionRange: Integer; ALineEnd, AMakeCaretVisible: Boolean);
begin
  ACaret := EnsureRange(ACaret, 0, Length(Text));
  ASelectionRange := EnsureRange(ASelectionRange, -ACaret, Length(Text) - ACaret);
  if (CaretPos <> ACaret) or (SelectionRange <> ASelectionRange) or
     (CaretInLineEnd <> ALineEnd) and not ALineEnd // только, если выключаем. Включаться оно должно только вместе со сдвигом каретки
  then
  begin
    FCaretPos := ACaret;
    FSelectionRange := ASelectionRange;
    FCaretInLineEnd := ALineEnd;
    if AMakeCaretVisible then
      Changed([mcnSelection, mcnMakeVisible])
    else
      Changed([mcnSelection]);
    if Editable and Focused then
    begin
      ViewInfo.CaretVisible := True;
      if FCaretBlink <> nil then
        FCaretBlink.Restart;
    end;
  end;
end;

procedure TACLMemoSubClass.MoveSelection(
  ACaret: Integer; AShift: TShiftState; AKey: Word);
begin
  if ssShift in AShift then
    MoveSelection(ACaret, FSelectionPin - ACaret)
  else if (SelLength > 0) and (AKey = vkLeft) then
    MoveSelection(SelStart, 0)
  else if (SelLength > 0) and (AKey = vkRight) then
    MoveSelection(SelStart + SelLength, 0)
  else
    MoveSelection(ACaret, 0);
end;

procedure TACLMemoSubClass.MoveSelection(
  ACaret: Integer; AShift: TShiftState; ALineEnd: Boolean);
begin
  MoveSelection(ACaret, IfThen(ssShift in AShift, FSelectionPin - ACaret), ALineEnd);
end;

procedure TACLMemoSubClass.MoveSelectionToLineEnd(AShift: TShiftState);
var
  LLine: TACLMemoLineInfo;
begin
  LLine := LineInfo(CaretPos);
  // Тут интересный момент: если мы уже стоим в конце строки с автопереносом
  // на новую, то vkEnd должен перевести нас в конец следующей строки.
  if (LLine.InTextFinish = CaretPos) and CaretInLineEnd and not LLine.LineBreak then
    LLine := LineInfo(LLine.InTextFinish + 1);
  if LLine.RowIndex >= 0 then
    MoveSelection(LLine.InTextFinish, AShift, not LLine.LineBreak);
end;

procedure TACLMemoSubClass.MoveSelectionToLineStart(AShift: TShiftState);
var
  LLine: TACLMemoLineInfo;
  LLinePrev: TACLMemoLineInfo;
begin
  LLine := LineInfo(CaretPos - Ord(CaretInLineEnd));
  // Тут интересный момент: если мы уже стоим в начале строки, полученной
  // автопереносом, то vkHome должен перевести нас в начало предыдущей строки.
  if LLine.InTextStart = CaretPos then
  begin
    LLinePrev := LineInfo(LLine.InTextStart - 1);
    if (LLinePrev.RowIndex >= 0) and not LLinePrev.LineBreak then
      LLine := LLinePrev;
  end;
  MoveSelection(LLine.InTextStart, AShift);
end;

procedure TACLMemoSubClass.MoveSelectionToNextPage(AGoForward: Boolean; AShift: TShiftState);
var
  LCaret: TPoint;
  LHitTest: TACLTextLayoutHitTest;
  LScrollInfo: TACLScrollInfo;
  LViewport: Integer;
begin
  if not ViewInfo.CaretRect.IsEmpty then
  begin
    LHitTest := TACLTextLayoutHitTest.Create(Layout);
    try
      LViewport := ViewInfo.ViewportY;
      LCaret := ViewInfo.CaretGoal + ViewInfo.GetOrigin;

      if AGoForward then
        ScrollVertically(scPageDown)
      else
        ScrollVertically(scPageUp);

      LCaret := LCaret - ViewInfo.GetOrigin;
      ViewInfo.GetScrollInfo(sbVertical, LScrollInfo);
      if Abs(ViewInfo.ViewportY - LViewport) < LScrollInfo.LineSize then // Уперлись в конец документа
      begin
        // Memo: в этом случае ничего не происходит
        // Rich: переводит каретку в начало / конец документа
        // SynEdit: переводит каретку на первую / последнюю строку

        // Как в RichEdit:
        if AGoForward then
          MoveSelection(MaxInt, AShift)
        else
          MoveSelection(0, AShift);
      end
      else
      begin
        LHitTest.Calculate(LCaret, True);
        if LHitTest.PositionInText >= 0 then
          MoveSelection(LHitTest.PositionInText, AShift, LHitTest.PositionInLineEnd);
      end;
      ViewInfo.CaretGoal := Point(LCaret.X, ViewInfo.CaretGoal.Y);
    finally
      LHitTest.Free;
    end;
  end;
end;

procedure TACLMemoSubClass.MoveSelectionToNextRow(AGoForward: Boolean; AShift: TShiftState);
var
  LCaret: TPoint;
  LHitTest: TACLTextLayoutHitTest;
  LRowIndex: Integer;
begin
  if not ViewInfo.CaretRect.IsEmpty then
  begin
    LHitTest := TACLTextLayoutHitTest.Create(Layout);
    try
      LCaret := ViewInfo.CaretGoal;
      LHitTest.Calculate(LCaret, True);
      LRowIndex := LHitTest.RowIndex + Signs[AGoForward];
      if InRange(LRowIndex, 0, Layout.RowCount - 1) then
      begin
        LCaret.Y := Layout.Rows[LRowIndex].Bounds.CenterPoint.Y;
        LHitTest.Calculate(LCaret, True);
        if LHitTest.PositionInText >= 0 then
        begin
          MoveSelection(LHitTest.PositionInText, AShift, LHitTest.PositionInLineEnd);
          ViewInfo.CaretGoal := LCaret;
        end;
      end
      else
        MoveSelection(CaretPos, AShift);
    finally
      LHitTest.Free;
    end;
  end;
end;

function TACLMemoSubClass.NextChar(ACaretPos: Integer; AGoForward: Boolean): Integer;
var
  LBlock: TACLTextLayoutBlock;
begin
  Result := ACaretPos;
  if AGoForward then
  begin
    if Layout.FindBlock(Result, LBlock) then
    begin
      if LBlock is TACLTextLayoutBlockStyle then
        Result := NextChar(Result + LBlock.Length, True)
      else if LBlock is TACLTextLayoutBlockText then
        Inc(Result, acCharLength(Layout.Text, Result + 1))
      else // space, linebreak and etc
        Inc(Result, LBlock.Length);
    end;
  end
  else
  begin
    Dec(Result, acCharPrevLength(Layout.Text, Result + 1));
    if Layout.FindBlock(Result, LBlock) and not (LBlock is TACLTextLayoutBlockText) then
    begin
      Result := LBlock.PositionInText - PChar(Layout.Text);
      if (Result > 0) and (LBlock is TACLTextLayoutBlockStyle) then
        Result := NextChar(Result, False)
    end;
  end;
end;

function TACLMemoSubClass.NextWord(ACaretPos: Integer; AGoForward: Boolean): Integer;
var
  LRange: TACLRange;
begin
  LRange := EditGetWordSelection(Text, ACaretPos, Signs[AGoForward], CheckIsTag);
  if LRange.Length >= 0 then
    Result := IfThen(AGoForward, LRange.Finish, LRange.Start)
  else
    Result := ACaretPos;
end;

procedure TACLMemoSubClass.ProcessCaretBlinking(Sender: TObject);
begin
  ViewInfo.CaretVisible := not ViewInfo.CaretVisible;
end;

procedure TACLMemoSubClass.ProcessChanges(AChanges: TIntegerSet);
begin
  inherited;
  if (mcnMakeVisible in AChanges) and Focused then
    MakeVisible(ViewInfo.CaretRect + ViewInfo.GetOrigin);
  if (mcnTextChanged in AChanges) then
    CallNotifyEvent(Self, OnChanged);
  if (mcnSelection in AChanges) then
    CallNotifyEvent(Self, OnSelectionChanged);
end;

procedure TACLMemoSubClass.ProcessContextMenuItem(Sender: TObject);
begin
  Execute(TACLEditAction(TComponent(Sender).Tag));
end;

procedure TACLMemoSubClass.ProcessKeyDelete(AShift: TShiftState; AGoForward: Boolean);
var
  LNextPos: Integer;
begin
  if ReadOnly then
    Exit;
  BeginUpdate;
  try
    if SelectionRange = 0 then
    begin
      if ssCtrl in AShift then
        LNextPos := NextWord(CaretPos, AGoForward)
      else
        LNextPos := NextChar(CaretPos, AGoForward);

      MoveSelection(LNextPos, CaretPos - LNextPos);
    end;
    SelText := '';
  finally
    EndUpdate;
  end;
end;

procedure TACLMemoSubClass.ProcessKeyDown(var AKey: Word; AShift: TShiftState);
var
  LLineBreak: string;
  LLineInfo: TACLMemoLineInfo;
begin
  if not Editable then
    Exit;
  case AKey of
    vkReturn:
      if not ReadOnly then
      begin
        LLineBreak := sLineBreak;
        // Вот тут интересный момент:
        // Если мы стоим в начале строки, которая появилась за счет автопереноса,
        // то штатный Memo вставляет два LineBreak - разрыв у длинной строки + новую строку.
        if WordWrap and not CaretInLineEnd then
        begin
          LLineInfo := LineInfo(CaretPos); // ref.to.GetCaret
          if (CaretPos = LLineInfo.InTextStart) and (LLineInfo.RowIndex > 0) then
          begin
            // проверяем факт автопереноса у предыдущей строки
            if not LineInfo(CaretPos - 1).LineBreak then
              LLineBreak := LLineBreak + LLineBreak;
          end;
        end;
        SelText := LLineBreak;
      end;

    vkShift:
      if SelectionRange = 0 then
        FSelectionPin := CaretPos;

    vkHome:
      if ssCtrl in AShift then
        MoveSelection(0, AShift)
      else
        MoveSelectionToLineStart(AShift);

    vkEnd:
      if ssCtrl in AShift then
        MoveSelection(MaxInt, AShift)
      else
        MoveSelectionToLineEnd(AShift);

    vkLeft, vkRight:
      if ssCtrl in AShift then
        MoveSelection(NextWord(CaretPos, AKey = vkRight), AShift, AKey)
      else
        MoveSelection(NextChar(CaretPos{ - Ord(CaretInLineEnd)}, AKey = vkRight), AShift, AKey);

    vkBack:
      ProcessKeyDelete(AShift, False);

    vkDelete:
      if acIsShiftPressed([ssShift], AShift) then
        Execute(eaCut)
      else
        ProcessKeyDelete(AShift, True);

    vkInsert:
      if acIsShiftPressed([ssCtrl], AShift) then
        Execute(eaCopy)
      else if acIsShiftPressed([ssShift], AShift) then
        Execute(eaPaste)
      else
        Exit;

    vkDown:
      if ssCtrl in AShift then
        ScrollVertically(scLineDown)
      else
        MoveSelectionToNextRow(True, AShift);


    vkNext, vkPrior:
      MoveSelectionToNextPage(AKey = vkNext, AShift);

    vkUp:
      if ssCtrl in AShift then
        ScrollVertically(scLineUp)
      else
        MoveSelectionToNextRow(False, AShift);

    vkZ:
      if acIsShiftPressed([ssCtrl, ssShift], AShift) then
        History.Redo
      else if acIsShiftPressed([ssCtrl], AShift) then
        History.Undo
      else
        Exit;

    vkA:
      if acIsShiftPressed([ssCtrl], AShift) then
        Execute(eaSelectAll)
      else
        Exit;

    vkX:
      if acIsShiftPressed([ssCtrl], AShift) then
        Execute(eaCut)
      else
        Exit;

    vkC:
      if acIsShiftPressed([ssCtrl], AShift) then
        Execute(eaCopy)
      else
        Exit;

    vkV:
      if acIsShiftPressed([ssCtrl], AShift) then
        Execute(eaPaste)
      else
        Exit;

  else
    Exit;
  end;
  AKey := 0;
end;

procedure TACLMemoSubClass.ProcessKeyPress(var AKey: WideChar);
begin
  if not Editable then
    Exit;
  if not ReadOnly then
  begin
    if Ord(AKey) = $7F then
      Exit;
    if Ord(AKey) >= Ord(' ') then
      SelText := acString(AKey);
  end;
  AKey := #0;
end;

procedure TACLMemoSubClass.ProcessMouseClick(AShift: TShiftState);
begin
  if LastClickCount > 2 then
    SelectNearestRow(LayoutHitTest.PositionInText - Ord(LayoutHitTest.PositionInLineEnd))
  else if LastClickCount = 2 then
    SelectNearestWord(LayoutHitTest.PositionInText)
  else
    if (LayoutHitTest.Hyperlink <> nil) and (not Editable or
       (LayoutHitTest.PositionInText = CaretPos))
    then
      CallHyperlink(Self, OnHyperlink, LayoutHitTest.Hyperlink.Hyperlink)
    else
      inherited;

  FSelectionPin := SelStart;
end;

procedure TACLMemoSubClass.ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState);
var
  LSelLength: Integer;
begin
  inherited;
  if (AButton = mbLeft) and Editable and (LayoutHitTest.PositionInText >= 0) then
  begin
    if LastClickCount > 1 then
      Exit;
    if (ssShift in AShift) and (FSelectionPin >= 0) then
      LSelLength := FSelectionPin - FLayoutHitTest.PositionInText
    else
      LSelLength := 0;

    MoveSelection(
      LayoutHitTest.PositionInText, LSelLength,
      LayoutHitTest.PositionInLineEnd);
  end;
end;

procedure TACLMemoSubClass.ProcessMouseWheel(
  ADirection: TACLMouseWheelDirection; AShift: TShiftState);
begin
  ViewInfo.ScrollByMouseWheel(ADirection, AShift);
end;

procedure TACLMemoSubClass.ScrollHorizontally(const AScrollCode: TScrollCode);
begin
  ViewInfo.ScrollHorizontally(AScrollCode);
end;

procedure TACLMemoSubClass.ScrollVertically(const AScrollCode: TScrollCode);
begin
  ViewInfo.ScrollVertically(AScrollCode);
end;

procedure TACLMemoSubClass.Select(AStart, ALength: Integer; AGoForward: Boolean);
begin
  AStart  := MinMax(IfThen(Editable, AStart),  0, Length(Text));
  ALength := MinMax(IfThen(Editable, ALength), 0, Length(Text) - AStart);
  if AGoForward then
    MoveSelection(AStart + ALength, -ALength)
  else
    MoveSelection(AStart, ALength);
end;

procedure TACLMemoSubClass.SelectNearestRow(ACaret: Integer);
var
  LLine: TACLMemoLineInfo;
begin
  if ACaret < 0 then Exit;
  LLine := LineInfo(ACaret);
  MoveSelection(LLine.InTextFinish, LLine.InTextStart - LLine.InTextFinish, True);
end;

procedure TACLMemoSubClass.SelectNearestWord(ACaret: Integer);
var
  LRange: TACLRange;
begin
  if ACaret < 0 then Exit;
  LRange := EditGetWordSelection(Text, ACaret, 0, CheckIsTag);
  if LRange.Length > 0 then
    MoveSelection(LRange.Finish, -LRange.Length,
      LineInfo(LRange.Start).RowIndex <>
      LineInfo(LRange.Finish).RowIndex);
end;

procedure TACLMemoSubClass.SetAlignment(AValue: TAlignment);
begin
  if Alignment <> AValue then
  begin
    Layout.HorzAlignment := AValue;
    FullRefresh;
  end;
end;

procedure TACLMemoSubClass.SetAutoScroll(AValue: Boolean);
begin
  if FAutoScroll <> AValue then
  begin
    FAutoScroll := AValue;
    if not AutoScroll then
      FEditable := False;
    Changed([cccnLayout]);
  end;
end;

procedure TACLMemoSubClass.SetCaret(const AValue: TPoint);
begin
  if InRange(AValue.Y, 0, Layout.RowCount - 1) then
    CaretPos := Layout.Rows[AValue.Y].PositionInText - PChar(Layout.Text) + AValue.X;
end;

procedure TACLMemoSubClass.SetCaretPos(AValue: Integer);
begin
  Select(AValue, 0);
end;

procedure TACLMemoSubClass.SetEditable(AValue: Boolean);
begin
  if Editable <> AValue then
  begin
    FEditable := AValue;
    if Editable then
      FAutoScroll := True;
    Select(CaretPos, 0);
    FocusChanged;
  end;
end;

procedure TACLMemoSubClass.SetSelLength(AValue: Integer);
begin
  Select(SelStart, AValue);
end;

procedure TACLMemoSubClass.SetSelStart(AValue: Integer);
begin
  Select(AValue, SelLength, False);
end;

procedure TACLMemoSubClass.SetSelText(const AValue: string);
begin
  if (SelLength = 0) and (AValue = '') then
    Exit;
  if History.CanRun and Focused then
    History.Run(TACLMemoHistoryCommand.Create(Self));
  Layout.ReplaceText(SelStart, SelLength, AValue, TextSettings);
  Changed([cccnStruct, cccnLayout]);
  MoveSelection(SelStart + Length(AValue), 0);
  Changed([mcnTextChanged]);
end;

procedure TACLMemoSubClass.SetTargetDPI(AValue: Integer);
begin
  inherited;
  Style.TargetDpi := AValue;
  Layout.TargetDpi := AValue;
end;

procedure TACLMemoSubClass.SetText(const AValue: string);
begin
  SetTextEx(AValue, TextSettings);
end;

procedure TACLMemoSubClass.SetTextEx(
  const AText: string; const ATextSettings: TACLTextFormatSettings);
begin
  if (FTextSettings <> ATextSettings) or (Text <> AText) then
  begin
    FTextSettings := ATextSettings;
    Layout.SetText(AText, TextSettings);
    Changed([cccnStruct, cccnLayout]); // first (cccnStruct to flush Hovered/PressedObject)
    MoveSelection(0, 0);
  end;
end;

procedure TACLMemoSubClass.SetTextSettings(const AValue: TACLTextFormatSettings);
begin
  SetTextEx(Text, AValue);
end;

procedure TACLMemoSubClass.SetWordWrap(AValue: Boolean);
begin
  if WordWrap <> AValue then
  begin
    Layout.SetOption(atoWordWrap, AValue);
    Changed([cccnLayout]);
  end;
end;

procedure TACLMemoSubClass.UpdateHitTest(const P: TPoint; ACalcHint: Boolean);
var
  LPoint: TPoint;
  LRect: TRect;
begin
  LPoint := P;
  LayoutHitTest.Reset;
  if DragAndDropController.IsActive then
  begin
    LRect := ViewInfo.ClientBounds.InflateTo(-2);
    LPoint.X := EnsureRange(LPoint.X, LRect.Left, LRect.Right);
    LPoint.Y := EnsureRange(LPoint.Y, LRect.Top, LRect.Bottom);
  end;
  inherited;
  if (HitTest.HitObject = ViewInfo) or (HitTest.HitObject = nil) then
  begin
    LayoutHitTest.Calculate(LPoint - ViewInfo.GetOrigin, True);
    HitTest.HitObject := LayoutHitTest.Block;
    if Editable then
      HitTest.Data[cchdViewInfo] := Self;
    if LayoutHitTest.Hyperlink <> nil then
      HitTest.Cursor := crHandPoint
    else if Editable then
      HitTest.Cursor := crIBeam;
  end;
end;

function TACLMemoSubClass.WantSpecialKey(Key: Word; Shift: TShiftState): Boolean;
begin
  if Key = vkTab then
    Exit(False);
  if Key = vkEscape then
    Exit(DragAndDropController.IsActive);
  Result := True;
end;

{ TACLMemoViewInfo }

constructor TACLMemoViewInfo.Create(AOwner: TACLCompoundControlSubClass);
begin
  inherited;
  FSelection := TACLRegion.Create;
end;

destructor TACLMemoViewInfo.Destroy;
begin
  FreeAndNil(FSelection);
  inherited;
end;

procedure TACLMemoViewInfo.Calculate(const R: TRect; AChanges: TIntegerSet);
begin
  inherited;
  if [mcnSelection, cccnLayout, cccnStruct] * AChanges <> [] then
  begin
    CalculateCaretRect;
    CalculateSelection;
  end;
end;

procedure TACLMemoViewInfo.CalculateCaretRect;
var
  LWidth: Integer;
begin
  LWidth := 0;
  SystemParametersInfo(SPI_GETCARETWIDTH, 0, @LWidth, 0);
  LWidth := Max(LWidth, 1);

  FCaretRect := NullRect;
  // Спец.кейс для vkEnd на строке с автопереносом:
  // Каретка стоит перед следующим символом, который по факту уже на следущей
  // строке, в этом случае мы берем предыдущий символ, но каретку ставим после него.
  if SubClass.CaretInLineEnd and Layout.FindCharBounds(SubClass.CaretPos - 1, FCaretRect) then
    FCaretRect.Left := FCaretRect.Right - LWidth
  else if Layout.FindCharBounds(SubClass.CaretPos, FCaretRect) then
    FCaretRect.Width := LWidth
  // Каретка в конце документа
  else if Layout.Rows.Count > 0 then
  begin
    FCaretRect := Layout.Rows.Last.Bounds;
    FCaretRect.Left := FCaretRect.Right;
    // Документ шире, чем зона видимости, поэтому каретка будет рисоваться
    // в пределах последней строки, а не после неё
    if FCaretRect.Left > Layout.Bounds.Width then
      Dec(FCaretRect.Left, LWidth);
    FCaretRect.Width := LWidth;
  end
  else
  begin
    FCaretRect := Layout.Bounds;
    FCaretRect.Height := acFontHeight(Layout.Font);
    FCaretRect.Width := LWidth;
    case Layout.HorzAlignment of
      taCenter:
        FCaretRect.Offset((Layout.Bounds.Right - LWidth) div 2, 0);
      taRightJustify:
        FCaretRect.Offset(Layout.Bounds.Right - LWidth, 0);
    end;
  end;
  FCaretGoal.X := FCaretRect.Left;
  FCaretGoal.Y := FCaretRect.CenterPoint.Y;
end;

procedure TACLMemoViewInfo.CalculateContentLayout;
begin
  Layout.Bounds := FClientBounds.Size;
  Layout.SetOption(atoAutoHeight, SubClass.AutoScroll);
  Layout.SetOption(atoEndEllipsis, not SubClass.AutoScroll);
  Layout.SetOption(atoEditControl, True);
  Layout.Calculate(MeasureCanvas);
  FContentSize := Layout.MeasureSize;
end;

procedure TACLMemoViewInfo.CalculateSelection;
var
  LRectBgn: TRect;
  LRectEnd: TRect;
  LRectTmp: TRect;
  LRow: TACLTextLayoutRow;
  LSelectionEnd: Integer;
  LSelectionMax: Integer;
begin
  FSelection.Reset;
  if SubClass.SelectionRange <> 0 then
  begin
    LSelectionMax := Length(SubClass.Text);
    LSelectionEnd := SubClass.CaretPos + SubClass.SelectionRange + 1;
    if Layout.FindCharBounds(Min(LSelectionEnd, LSelectionMax) - 1, LRectEnd) then
    begin
      LRectBgn := CaretRect;
      if SubClass.SelectionRange < 0 then
        TACLMath.Exchange<TRect>(LRectBgn, LRectEnd);
      if LSelectionEnd > LSelectionMax then
        LRectEnd.Left := LRectEnd.Right;
      for LRow in Layout.Rows do
      begin
        if InRange(LRow.Bounds.CenterPoint.Y, LRectBgn.Top, LRectEnd.Bottom) then
        begin
          LRectTmp := LRow.Bounds;
          if LRectTmp.Left = LRectTmp.Right then // linebreak, styles and etc.
            LRectTmp.Right := LRectTmp.Left + 4;
          if (LRectBgn.Top >= LRow.Bounds.Top) and (LRectBgn.Bottom <= LRow.Bounds.Bottom) then
            LRectTmp.Left := LRectBgn.Left;
          if (LRectEnd.Top >= LRow.Bounds.Top) and (LRectEnd.Bottom <= LRow.Bounds.Bottom) then
            LRectTmp.Right := LRectEnd.Left;
          FSelection.Combine(LRectTmp, rcmOr);
        end;
      end;
    end;
  end;
end;

procedure TACLMemoViewInfo.DoDrawCells(ACanvas: TCanvas);
var
  LClipRgn: TRegionHandle;
  LOrigin: TPoint;
  LRender: TACLTextLayoutRender;
begin
  LOrigin := acMoveWindowOrg(ACanvas.Handle, GetOrigin);
  try
    Layout.Draw(ACanvas);
    if not Selection.Empty then
    begin
      LClipRgn := acSaveClipRegion(ACanvas.Handle);
      try
        if acCombineWithClipRegion(ACanvas.Handle, Selection.Handle, RGN_AND) then
        begin
          ACanvas.Brush.Color := SubClass.Style.ColorContentSelected.AsColor;
          ACanvas.FillRect(Selection.Bounds);
          LRender := Layout.GetDefaultRender.Create(ACanvas);
          try
            Layout.Rows.Export(TACLMemoTextSelectionPainter.Create(Layout, LRender), True);
          finally
            LRender.Free;
          end;
        end;
      finally
        acRestoreClipRegion(ACanvas.Handle, LClipRgn);
      end;
    end;
    if CaretVisible then
    begin
      ACanvas.Brush.Color := SubClass.Style.ColorText.AsColor;
      ACanvas.FillRect(CaretRect);
    end;
  finally
    acRestoreWindowOrg(ACanvas.Handle, LOrigin);
  end;
end;

function TACLMemoViewInfo.GetLayout: TACLMemoTextLayout;
begin
  Result := SubClass.Layout;
end;

function TACLMemoViewInfo.GetOrigin: TPoint;
begin
  Result := ClientBounds.TopLeft - Point(ViewportX, ViewportY);
end;

function TACLMemoViewInfo.GetScrollInfo(
  AKind: TScrollBarKind; out AInfo: TACLScrollInfo): Boolean;
begin
  Result := inherited;
  AInfo.LineSize := acFontHeight(Layout.Font);
end;

function TACLMemoViewInfo.GetSubClass: TACLMemoSubClass;
begin
  Result := TACLMemoSubClass(inherited SubClass);
end;

procedure TACLMemoViewInfo.SetCaretVisible(AValue: Boolean);
begin
  if FCaretVisible <> AValue then
  begin
    FCaretVisible := AValue;
    if not CaretRect.IsEmpty then
      SubClass.InvalidateRect(CaretRect + GetOrigin);
  end;
end;

{ TACLCustomMemo }

constructor TACLCustomMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBorders := True;
  FDefaultSize := TSize.Create(300, 300);
  FocusOnClick := True;
  TabStop := True;
end;

function TACLCustomMemo.CanExecute(AAction: TACLEditAction): Boolean;
begin
  Result := SubClass.CanExecute(AAction);
end;

function TACLCustomMemo.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLMemoSubClass.Create(Self);
end;

procedure TACLCustomMemo.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
begin
  inherited;
  if SubClass.Editable then
    TACLEditContextMenu.ContextPopup(Self, SubClass, MousePos, Handled);
end;

procedure TACLCustomMemo.Execute(AAction: TACLEditAction);
begin
  SubClass.Execute(AAction);
end;

procedure TACLCustomMemo.FocusChanged;
begin
  inherited;
  InvalidateBorders;
end;

function TACLCustomMemo.GetAlignment: TAlignment;
begin
  Result := SubClass.Alignment;
end;

function TACLCustomMemo.GetCaretPos: TPoint;
begin
  Result := SubClass.Caret;
end;

function TACLCustomMemo.GetContentOffset: TRect;
begin
  if Borders then
    Result := dpiApply(acBorderOffsets, FCurrentPPI)
  else
    Result := NullRect;
end;

function TACLCustomMemo.GetLines: TStrings;
begin
  Result := SubClass.Lines;
end;

procedure TACLCustomMemo.MakeVisible(ARow: Integer);
begin
  SubClass.MakeVisible(ARow);
end;

procedure TACLCustomMemo.MouseEnter;
begin
  inherited;
  InvalidateBorders;
end;

procedure TACLCustomMemo.MouseLeave;
begin
  inherited;
  InvalidateBorders;
end;

procedure TACLCustomMemo.Paint;
begin
  if not Transparent then
    acFillRect(Canvas, ClientRect, Style.ColorsContent[Enabled]);
  if Borders then
    Style.DrawBorders(Canvas, ClientRect,
      not (csDesigning in ComponentState) and Enabled and MouseInClient,
      not (csDesigning in ComponentState) and Focused);
  inherited Paint;
end;

procedure TACLCustomMemo.ResourceChanged;
begin
  SubClass.Layout.FlushCalculatedValues;
  inherited;
end;

function TACLCustomMemo.GetOnChange: TNotifyEvent;
begin
  Result := SubClass.OnChanged;
end;

function TACLCustomMemo.GetOnHyperlink: TACLHyperlinkEvent;
begin
  Result := SubClass.OnHyperlink
end;

function TACLCustomMemo.GetOnSelectionChanged: TNotifyEvent;
begin
  Result := SubClass.OnSelectionChanged;
end;

function TACLCustomMemo.GetReadOnly: Boolean;
begin
  Result := SubClass.ReadOnly;
end;

function TACLCustomMemo.GetSelLength: Integer;
begin
  Result := SubClass.SelLength;
end;

function TACLCustomMemo.GetSelStart: Integer;
begin
  Result := SubClass.SelStart;
end;

function TACLCustomMemo.GetSelText: string;
begin
  Result := SubClass.SelText;
end;

function TACLCustomMemo.GetStyle: TACLStyleMemo;
begin
  Result := SubClass.Style;
end;

function TACLCustomMemo.GetSubClass: TACLMemoSubClass;
begin
  Result := TACLMemoSubClass(inherited SubClass);
end;

function TACLCustomMemo.GetText: string;
begin
  Result := SubClass.Text;
end;

function TACLCustomMemo.GetWordWrap: Boolean;
begin
  Result := SubClass.WordWrap;
end;

procedure TACLCustomMemo.InvalidateBorders;
begin
  if Borders and HandleAllocated then
    acInvalidateBorders(Self, ClientRect, acBorderOffsets);
end;

procedure TACLCustomMemo.Select(AStart, ALength: Integer; AGoForward: Boolean);
begin
  SubClass.Select(AStart, ALength, AGoForward);
end;

procedure TACLCustomMemo.SetAlignment(AValue: TAlignment);
begin
  SubClass.Alignment := AValue;
end;

procedure TACLCustomMemo.SetBorders(AValue: Boolean);
begin
  if FBorders <> AValue then
  begin
    FBorders := AValue;
    ResourceChanged;
  end;
end;

procedure TACLCustomMemo.SetCaretPos(const AValue: TPoint);
begin
  SubClass.Caret := AValue;
end;

procedure TACLCustomMemo.SetLines(AValue: TStrings);
begin
  SubClass.Lines.Assign(AValue);
end;

procedure TACLCustomMemo.SetOnChange(AValue: TNotifyEvent);
begin
   SubClass.OnChanged := AValue;
end;

procedure TACLCustomMemo.SetOnHyperlink(AValue: TACLHyperlinkEvent);
begin
  SubClass.OnHyperlink := AValue;
end;

procedure TACLCustomMemo.SetOnSelectionChanged(AValue: TNotifyEvent);
begin
  SubClass.OnSelectionChanged := AValue;
end;

procedure TACLCustomMemo.SetReadOnly(AValue: Boolean);
begin
  SubClass.ReadOnly := AValue;
end;

procedure TACLCustomMemo.SetSelLength(AValue: Integer);
begin
  SubClass.SelLength := AValue;
end;

procedure TACLCustomMemo.SetSelStart(AValue: Integer);
begin
  SubClass.SelStart := AValue;
end;

procedure TACLCustomMemo.SetSelText(const Value: string);
begin
  SubClass.SelText := Value;
end;

procedure TACLCustomMemo.SetStyle(AValue: TACLStyleMemo);
begin
  SubClass.Style.Assign(AValue);
end;

procedure TACLCustomMemo.SetText(const AValue: string);
begin
  SubClass.Text := AValue;
end;

procedure TACLCustomMemo.SetWordWrap(AValue: Boolean);
begin
  SubClass.WordWrap := AValue;
end;

{ TACLMemoLines }

constructor TACLMemoLines.Create(ASubClass: TACLMemoSubClass);
begin
  inherited Create;
  FSubClass := ASubClass;
end;

procedure TACLMemoLines.Assign(Source: TPersistent);
begin
  if Source is TStrings then
    FSubClass.Text := TStrings(Source).Text
  else
    inherited;
end;

procedure TACLMemoLines.Clear;
begin
  FSubClass.Text := '';
end;

procedure TACLMemoLines.Delete(Index: Integer);
begin
  ReplaceRow(Index, '', True);
end;

function TACLMemoLines.Get(Index: Integer): string;
begin
  Result := FSubClass.Layout.Rows[Index].ToString;
end;

function TACLMemoLines.GetCount: Integer;
begin
  Result := FSubClass.Layout.RowCount;
end;

function TACLMemoLines.GetObject(Index: Integer): TObject;
begin
  Result := nil;
end;

function TACLMemoLines.GetTextStr: string;
begin
  Result := FSubClass.Text;
end;

procedure TACLMemoLines.Insert(Index: Integer; const S: string);
var
  LBase: PChar;
  LTail: PChar;
begin
  if (Index < 0) or (Index > Count) then
    raise EInvalidArgument.Create('Index out of bounds');

  LBase := PChar(FSubClass.Text);
  if Index > 0 then
    LTail := FSubClass.Layout.Rows[Index - 1].LineEndPosition
  else
    LTail := LBase;

  FSubClass.Text :=
    Copy(FSubClass.Text, 1,  LTail - LBase) +
      IfThenW(Index > 0, sLineBreak) + S +
    Copy(FSubClass.Text, 1 + LTail - LBase);
end;

procedure TACLMemoLines.Put(Index: Integer; const S: string);
begin
  ReplaceRow(Index, S, False);
end;

procedure TACLMemoLines.PutObject(Index: Integer; AObject: TObject);
begin
  // do nothing
end;

procedure TACLMemoLines.ReplaceRow(
  AIndex: Integer; const AValue: string; AEntire: Boolean);
var
  LBase: PChar;
  LRow: TACLTextLayoutRow;
begin
  LBase := PChar(FSubClass.Text);
  LRow := FSubClass.Layout.Rows[AIndex];
  FSubClass.Text :=
    Copy(FSubClass.Text, 1,  LRow.PositionInText - LBase) + AValue +
    Copy(FSubClass.Text, 1 + LRow.LineEndPosition(True) - LBase);
end;

procedure TACLMemoLines.SetTextStr(const Value: string);
begin
  FSubClass.Text := Value;
end;

end.
