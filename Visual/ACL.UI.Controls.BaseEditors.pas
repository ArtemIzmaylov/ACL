////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Base classes for editors
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.BaseEditors;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LazUTF8,
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // Vcl
  {Vcl.}ClipBrd,
  {Vcl.}Controls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}StdCtrls,
  {Vcl.}Menus,
  // System
  {System.}Classes,
  {System.}Character,
  {System.}Math,
  {System.}Variants,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // ACL
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Math,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Parsers,
  ACL.Timers,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.Buttons,
  ACL.UI.Menus,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Clipboard,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type
  TACLCustomEdit = class;

  TACLEditAction = (eaCopy, eaCut, eaPaste, eaUndo, eaSelectAll, eaDelete);

  { IACLEditActions }

  IACLEditActions = interface
  ['{A385EC42-BAE6-495F-B3D7-173B62A901AD}']
    function CanExecute(AAction: TACLEditAction): Boolean;
    procedure Execute(AAction: TACLEditAction);
  end;

  { TACLStyleEdit }

  TACLStyleEdit = class(TACLStyle)
  strict private
    function GetBorderColor(AHot, AFocused: Boolean): TColor;
    function GetContentColor(Enabled: Boolean): TColor;
    function GetTextColor(Enabled: Boolean): TColor;
  protected
    procedure InitializeResources; override;
  public
    procedure DrawBorders(ACanvas: TCanvas; const R: TRect; AHot, AFocused: Boolean);
    //# Properties
    property ColorsContent[Enabled: Boolean]: TColor read GetContentColor;
    property ColorsText[Enabled: Boolean]: TColor read GetTextColor;
  published
    property ColorBorder: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorBorderFocused: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorBorderHovered: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorContent: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
    property ColorContentDisabled: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
    property ColorContentSelected: TACLResourceColor index 5 read GetColor write SetColor stored IsColorStored;
    property ColorText: TACLResourceColor index 6 read GetColor write SetColor stored IsColorStored;
    property ColorTextDisabled: TACLResourceColor index 7 read GetColor write SetColor stored IsColorStored;
    property ColorTextHint: TACLResourceColor index 8 read GetColor write SetColor stored IsColorStored;
    property ColorTextSelected: TACLResourceColor index 9 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLStyleEditButton }

  TACLStyleEditButton = class(TACLStyleButton)
  protected
    procedure InitializeResources; override;
    procedure InitializeTextures; override;
  end;

  TACLEditGetDisplayTextEvent = procedure (Sender: TObject;
    const AValue: Variant; var ADisplayText: string) of object;

  { TACLEditSubClass }

  TACLEditSubClass = class(TACLControlSubClass,
    IACLEditActions,
    IACLUpdateLock)
  public type
    TState = (esCaret, esChanged, esDragging,
      esFocused, esReadOnly, esIteract, esNoScrolling);
    TStates = set of TState;
  public type
    TDisplayFormatFunc = function: string of object;
    TInputFilterProc = procedure (var AText, APart1, APart2: string; var AAccept: Boolean) of object;
  strict private type
    TUndoInfo = record
      Head: Integer;
      Redo: Boolean;
      Tail: Integer;
      Text: string;
      function IsAssigned: Boolean;
      procedure Reset;
    end;
  strict private
    FCaretBlink: TACLTimer;
    FCaretPos: Integer;
    FMaxLength: Integer;
    FOffset: Integer;
    FPasswordChar: Char;
    FSelLength: Integer;
    FSelPin: Integer;
    FSelStart: Integer;
    FState: TStates;
    FStyle: TACLStyleEdit;
    FText: string;
    FTextAlign: TAlignment;
    FTextHint: string;
    FUndo: TUndoInfo;
    FUpdateCount: Byte;

    FOnChange: TThreadMethod;
    FOnDisplayFormat: TDisplayFormatFunc;
    FOnInput: TInputFilterProc;
    FOnReturn: TThreadMethod;

    function CalculateStep(AGoForward: Boolean; AShift: TShiftState): Integer;
    procedure HandlerCaretBlink(Sender: TObject);
    function GetSelText: string;
    function GetState(AState: TState): Boolean;
    procedure Modify(const AText: string; ACaretPos: Integer = -1);
    procedure SetCaretPos(AValue: Integer);
    procedure SetMaxLength(AValue: Integer);
    procedure SetPasswordChar(AValue: Char);
    procedure SetSelLength(AValue: Integer);
    procedure SetSelStart(AValue: Integer);
    procedure SetSelText(const Value: string);
    procedure SetState(AState: TState; AValue: Boolean);
    procedure SetText(const AValue: string);
    procedure SetTextAlign(AValue: TAlignment);
    procedure SetTextHint(const Value: string);
    procedure UndoRedo;
  protected
    FCaretRect: TRect;
    FTextArea: TRect;
    FTextRect: TRect;
    FSelectionRect: TRect;

    procedure AssignCanvasParameters(ACanvas: TCanvas); virtual;
    procedure BlockScrolling(ALock: Boolean);
    function CanInput(var AText, APart1, APart2: string): Boolean; virtual;
    function GetDisplayText: string;
    function GetPart1(const AText: string): string; // text before selection
    function GetPart2(const AText: string): string; // text after selection
    function GetTextShadow: TRect; virtual;
    procedure TextChanged; virtual;
    function TextHitTest(X, Y: Integer; AApproximate: Boolean = False): Integer;
    //# Properties
    property CaretPos: Integer read FCaretPos write SetCaretPos;
  public
    constructor Create(const AOwner: IACLControl; AStyle: TACLStyleEdit);
    destructor Destroy; override;
    function AutoHeight: Integer; virtual;
    procedure Calculate(ABounds: TRect); override;
    procedure Changed;
    procedure Draw(ACanvas: TCanvas); override;
    // IACLUpdateLock
    procedure BeginUpdate;
    procedure EndUpdate;
    // Actions
    function CanExecute(AAction: TACLEditAction): Boolean;
    procedure Execute(AAction: TACLEditAction);
    // Keyboard
    procedure KeyChar(var Key: WideChar); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPreview(aKey: Word; Shift: TShiftState; var ACanHandle: Boolean); virtual;
    // Selection
    procedure Select(AStart, ALength: Integer; AGoForward: Boolean = True);
    procedure SetFocused(AValue: Boolean);
    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; const P: TPoint); override;
    procedure MouseMove(Shift: TShiftState; const P: TPoint); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; const P: TPoint); override;
    // Properties
    property Iteract: Boolean index esIteract read GetState write SetState;
    property MaxLength: Integer read FMaxLength write SetMaxLength;
    property PasswordChar: Char read FPasswordChar write SetPasswordChar;
    property ReadOnly: Boolean index esReadOnly read GetState write SetState;
    property SelLength: Integer read FSelLength write SetSelLength;
    property SelStart: Integer read FSelStart write SetSelStart;
    property SelText: string read GetSelText write SetSelText;
    property State: TStates read FState;
    property Style: TACLStyleEdit read FStyle;
    property Text: string read FText write SetText;
    property TextAlign: TAlignment read FTextAlign write SetTextAlign;
    property TextHint: string read FTextHint write SetTextHint;
    // ViewInfo
    property CaretRect: TRect read FCaretRect;
    property SelectionRect: TRect read FSelectionRect;
    property TextArea: TRect read FTextArea;
    property TextRect: TRect read FTextRect;
    // Events
    property OnChange: TThreadMethod read FOnChange write FOnChange;
    property OnDisplayFormat: TDisplayFormatFunc read FOnDisplayFormat write FOnDisplayFormat;
    property OnInput: TInputFilterProc read FOnInput write FOnInput;
    property OnReturn: TThreadMethod read FOnReturn write FOnReturn;
  end;

  { TACLCustomEdit }

  TACLCustomEdit = class(TACLCustomControl,
    IACLCursorProvider,
    IACLEditActions)
  protected const
    InnerBorderSize = 1;
    OuterBorderSize = 1;
    BorderSize = InnerBorderSize + OuterBorderSize;
    ButtonsIndent = 1;
  strict private
    FAutoSelect: Boolean;
    FBorders: Boolean;
    FInplace: Boolean;
    FStyle: TACLStyleEdit;
    FStyleButton: TACLStyleButton;
    FTextPadding: TSize;

    FOnChange: TNotifyEvent;

    procedure CalculateTextPadding;
    //# Setters
    procedure SetBorders(AValue: Boolean);
    procedure SetStyle(AValue: TACLStyleEdit);
    procedure SetStyleButton(AValue: TACLStyleButton);
    //# Messages
    procedure CMChanged(var Message: TMessage); message CM_CHANGED;
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
    procedure CMWantSpecialKey(var Message: TMessage); message CM_WANTSPECIALKEY;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    FEditBox: TACLEditSubClass;

    procedure BoundsChanged; override;
    procedure Calculate(ARect: TRect); virtual;
    procedure CalculateButtons(var ARect: TRect; AIndent: Integer); virtual;
    procedure CalculateContent(ARect: TRect); virtual;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    function CreateStyle: TACLStyleEdit; virtual;
    function CreateStyleButton: TACLStyleButton; virtual;
    function CreateSubClass: TACLEditSubClass; virtual;
  {$IFDEF FPC}
    procedure DoAutoSize; override;
  {$ENDIF}
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
    procedure FocusChanged; override;
    procedure InvalidateBorders;
    procedure SetFocusOnClick; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure TextChanged; reintroduce; virtual;
    //# Drawing
    procedure Paint; override;
    procedure PaintCore; virtual;
    //# Mouse
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    //# IACLCursorProvider
    function GetCursor(const P: TPoint): TCursor; reintroduce; virtual;
    //# Properties
    property Borders: Boolean read FBorders write SetBorders default True;
    property EditBox: TACLEditSubClass read FEditBox implements IACLEditActions;
    property Inplace: Boolean read FInplace;
    property Style: TACLStyleEdit read FStyle write SetStyle;
    property StyleButton: TACLStyleButton read FStyleButton write SetStyleButton;
    property TextPadding: TSize read FTextPadding;
    //# Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateInplace(const AParams: TACLInplaceInfo); virtual;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  {$IFDEF FPC}
    procedure ShouldAutoAdjust(var AWidth, AHeight: Boolean); override;
  {$ENDIF}
  published
    property AutoSize default True;
    property AutoSelect: Boolean read FAutoSelect write FAutoSelect default True;
    property FocusOnClick default True;
  end;

  { TACLEditContextMenu }

  TACLEditContextMenu = class
  strict private
    class var FListener: TACLComponentFreeNotifier;
    class var FPopupMenu: TACLPopupMenu;
    class procedure HandlerBuild(Sender: TObject);
    class procedure HandlerMenuClick(Sender: TObject);
    class procedure HandlerRemoving(AComponent: TComponent);
  public
    class var Captions: array[TACLEditAction] of string;
    class constructor Create;
    class destructor Destroy;
    class procedure ContextPopup(AControl: TControl;
      AInvoker: TComponent; AMousePos: TPoint; var AHandled: Boolean);
    class function Instance(AInvoker: TComponent): TACLPopupMenu; overload;
    class function Instance(AInvoker: TComponent; AClass: TACLPopupMenuClass): TACLPopupMenu; overload;
  end;

  { TACLIncrementalSearch }

  TACLIncrementalSearchMode = (ismSearch, ismFilter);
  TACLIncrementalSearch = class
  public type
    TLookupEvent = procedure (Sender: TObject; var AFound: Boolean) of object;
  strict private
    FLocked: Boolean;
    FMode: TACLIncrementalSearchMode;
    FText: string;
    FTextLength: Integer;

    FOnLookup: TLookupEvent;
    FOnChange: TNotifyEvent;

    function GetActive: Boolean;
    procedure SetText(const AValue: string);
    procedure SetMode(const AValue: TACLIncrementalSearchMode);
  protected
    procedure Changed;
  public
    procedure Cancel;
    function CanProcessKey(Key: Word; Shift: TShiftState;
      ACanStartEvent: TACLKeyPreviewEvent = nil): Boolean;
    function Contains(const AText: string): Boolean;
    function GetHighlightBounds(const AText: string;
      out AHighlightStart, AHighlightFinish: Integer): Boolean;
    function ProcessKey(Key: WideChar): Boolean; overload;
    function ProcessKey(Key: Word; Shift: TShiftState): Boolean; overload;
    //# Properties
    property Active: Boolean read GetActive;
    property Mode: TACLIncrementalSearchMode read FMode write SetMode;
    property Text: string read FText write SetText;
    //# Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnLookup: TLookupEvent read FOnLookup write FOnLookup;
  end;

function EditGetWordSelection(const AText: string; ACaret, ADirection: Integer;
  AIsInsideTag: TFunc<Integer, Boolean> = nil): TACLRange; // 0-based
implementation

type
  TControlAccess = class(TControl);

function EditGetWordSelection(const AText: string; ACaret, ADirection: Integer;
  AIsInsideTag: TFunc<Integer, Boolean> = nil): TACLRange; // 0-based
{$WARN SYMBOL_DEPRECATED OFF}
const
  LineBreaks = [#10, #13];

  function IsMeanfulCharacter(AIndex: Integer; AIsLetterOrDigit: Boolean): Boolean;
  var
    LChar: UCS4Char;
  begin
    LChar := acCharUCS4(AText, AIndex);
    Result := not TCharacter.IsWhiteSpace(LChar) and
      ((TCharacter.IsLetterOrDigit(LChar) = AIsLetterOrDigit) or
        Assigned(AIsInsideTag) and AIsInsideTag(AIndex - 1{to 0-based}));
  end;

  function IsSpace(AIndex: Integer): Boolean;
  begin
    Result := not CharInSet(AText[AIndex], LineBreaks) and
      TCharacter.IsWhiteSpace(AText[AIndex]);
  end;

  function IsSpaceOrTag(AIndex: Integer): Boolean;
  begin
    Result := not CharInSet(AText[AIndex], LineBreaks) and
      (TCharacter.IsWhiteSpace(AText[AIndex]) or
       Assigned(AIsInsideTag) and AIsInsideTag(AIndex - 1{to 0-based}));
  end;

var
  LLength: Integer;
  LLetter: Boolean;
  LRange1: Integer;
  LRange2: Integer;
begin
  LLength := Length(AText);
  if LLength = 0 then
    Exit(TACLRange.Create(0, -1));

  ACaret  := Max(EnsureRange(ACaret + Ord(ADirection > 0), 0, LLength), 1);

{$REGION ' Пропуск стартовых пробелов при навигации '}
  if ADirection <> 0 then
  begin
    while InRange(ACaret, 1, LLength) and IsSpaceOrTag(ACaret) do
    begin
      if ADirection < 0 then
        Dec(ACaret, Max(1, acCharPrevLength(AText, ACaret)))
      else
        Inc(ACaret, Max(1, acCharLength(AText, ACaret)));
    end;
    if ACaret > LLength then
      Exit(TACLRange.Create(0, -1));
  end;
{$ENDREGION}

{$REGION ' Пропуск LineBreak '}
  if CharInSet(AText[ACaret], LineBreaks) then
  begin
    while InRange(ACaret, 1, LLength) and CharInSet(AText[ACaret], LineBreaks) do
    begin
      if ADirection < 0 then
        Dec(ACaret)
      else // в случае выделения слова или навигации вперёд
        Inc(ACaret);
    end;
    if ADirection >= 0 then
    begin
      while InRange(ACaret, 1, LLength) and IsSpace(ACaret) do
        Inc(ACaret);
    end;
    if ADirection <> 0 then
    begin
      if ADirection > 0 then
        Dec(ACaret); // ACaret уже ссылается на следующий символ
      Exit(TACLRange.Create(ACaret, ACaret));
    end;
    if ACaret > LLength then
      Exit(TACLRange.Create(0, -1));
  end;
{$ENDREGION}

{$REGION ' Выделение ближайшего слова '}
  LRange1 := ACaret;
  LRange2 := ACaret;
  if IsSpace(ACaret) then
  begin
    // Если мы попали на пробел:
    // 1) сдвигаем диапазон вправо до первого слова / конца строки
    // 2) сдвигаем диапазон влево до начала ближайшего слова / начала строки
    while (LRange2 <= LLength) and IsSpaceOrTag(LRange2) do
      Inc(LRange2);
    while (LRange1 >= 1) and IsSpaceOrTag(LRange1) do
      Dec(LRange1, Max(1, acCharPrevLength(AText, LRange1)));
    while (LRange1 >= 1) and IsMeanfulCharacter(LRange1, True) do
      Dec(LRange1, Max(1, acCharPrevLength(AText, LRange1)));
  end
  else
  begin
    // Каретка у нас с нуля, а размер текущего символа не обязательно = 1
    Inc(LRange1);
    Dec(LRange1, acCharPrevLength(AText, LRange1));

    // Если мы попали в слово:
    // 1) сдвигаем диапазон влево до начала слова
    // 2) сдвигаем диапазон вправо до конца слова
    //    + захватываем все пробелы до следующего слова / конца строки
    LLetter := IsMeanfulCharacter(LRange1, True);
    while (LRange1 >= 1) and IsMeanfulCharacter(LRange1, LLetter) do
      Dec(LRange1, Max(1, acCharPrevLength(AText, LRange1)));
    while (LRange2 <= LLength) and IsMeanfulCharacter(LRange2, LLetter) do
      Inc(LRange2, Max(1, acCharLength(AText, LRange2)));
    while (LRange2 <= LLength) and IsSpaceOrTag(LRange2) do
      Inc(LRange2);
  end;

  // ARange1 / ARange2 указывают на первые символы, которые НЕ попадают в диапазон.
  // Корректируем их таким образом, чтобы они указывали на byte-диапазон искомого слова.
  // Не забываем, что на выходе индексация у нас должна быть с 0, а не 1.
  Dec(LRange2); // каретка с 0
  if LRange1 > 0 then
  begin
    Inc(LRange1, acCharLength(AText, LRange1));
    Dec(LRange1); // каретка с 0
  end;

  Result := TACLRange.Create(LRange1, LRange2);
{$ENDREGION}
{$WARN SYMBOL_DEPRECATED ON}
end;

{ TACLStyleEdit }

procedure TACLStyleEdit.DrawBorders(ACanvas: TCanvas; const R: TRect; AHot, AFocused: Boolean);
begin
  acDrawFrame(ACanvas, R, GetBorderColor(AHot, AFocused));
end;

function TACLStyleEdit.GetBorderColor(AHot, AFocused: Boolean): TColor;
begin
  if AFocused then
    Exit(ColorBorderFocused.AsColor);
  if AHot then
    Exit(ColorBorderHovered.AsColor);
  Result := ColorBorder.AsColor;
end;

function TACLStyleEdit.GetContentColor(Enabled: Boolean): TColor;
begin
  if Enabled then
    Result := ColorContent.AsColor
  else
    Result := ColorContentDisabled.AsColor;
end;

function TACLStyleEdit.GetTextColor(Enabled: Boolean): TColor;
begin
  if Enabled then
    Result := ColorText.AsColor
  else
    Result := ColorTextDisabled.AsColor
end;

procedure TACLStyleEdit.InitializeResources;
begin
  ColorBorder.InitailizeDefaults('EditBox.Colors.Border');
  ColorBorderFocused.InitailizeDefaults('EditBox.Colors.BorderFocused');
  ColorBorderHovered.InitailizeDefaults('EditBox.Colors.BorderFocused');
  ColorContent.InitailizeDefaults('EditBox.Colors.Content');
  ColorContentDisabled.InitailizeDefaults('EditBox.Colors.ContentDisabled');
  ColorContentSelected.InitailizeDefaults('EditBox.Colors.ContentSelected', clHighlight);
  ColorText.InitailizeDefaults('EditBox.Colors.Text');
  ColorTextDisabled.InitailizeDefaults('EditBox.Colors.TextDisabled');
  ColorTextSelected.InitailizeDefaults('EditBox.Colors.TextSelected', clHighlightText);
  ColorTextHint.InitailizeDefaults('EditBox.Colors.TextHint', clGrayText);
end;

{ TACLStyleEditButton }

procedure TACLStyleEditButton.InitializeResources;
begin
  ColorText.InitailizeDefaults('EditBox.Colors.ButtonText');
  ColorTextDisabled.InitailizeDefaults('EditBox.Colors.ButtonTextDisabled');
  ColorTextHover.InitailizeDefaults('EditBox.Colors.ButtonTextHover');
  ColorTextPressed.InitailizeDefaults('EditBox.Colors.ButtonTextPressed');
  InitializeTextures;
end;

procedure TACLStyleEditButton.InitializeTextures;
begin
  Texture.InitailizeDefaults('EditBox.Textures.Button');
end;

{ TACLEditSubClass }

constructor TACLEditSubClass.Create(const AOwner: IACLControl; AStyle: TACLStyleEdit);
begin
  inherited Create(AOwner);
  FState := [esChanged, esIteract];
  FStyle := AStyle;
  FUndo.Reset;
end;

destructor TACLEditSubClass.Destroy;
begin
  FreeAndNil(FCaretBlink);
  inherited;
end;

procedure TACLEditSubClass.AssignCanvasParameters(ACanvas: TCanvas);
begin
  ACanvas.Brush.Style := bsClear;
  ACanvas.SetScaledFont(Owner.GetFont);
  ACanvas.Font.Color := Style.ColorsText[Owner.GetEnabled];
end;

function TACLEditSubClass.AutoHeight: Integer;
begin
  AssignCanvasParameters(MeasureCanvas);
  Result := acFontHeight(MeasureCanvas) + GetTextShadow.MarginsHeight;
end;

procedure TACLEditSubClass.Calculate(ABounds: TRect);
var
  LMaxOffset: Integer;
  LShadow: TRect;
  LText: string;
  LTextWidth: Integer;
begin
  if (esChanged in State) or (ABounds <> Bounds) then
  begin
    inherited;

    Exclude(FState, esChanged);
    AssignCanvasParameters(MeasureCanvas);
    LShadow := GetTextShadow;

  {$REGION ' Text '}
    LText := GetDisplayText;
    FTextArea := Bounds;
    FTextArea.CenterVert(acFontHeight(MeasureCanvas) + LShadow.MarginsHeight);
    FTextRect := FTextArea;
    LTextWidth := acTextSize(MeasureCanvas, LText).cx + LShadow.MarginsWidth;
    case TextAlign of
      taCenter:
        FTextRect.CenterHorz(LTextWidth);
      taRightJustify:
        FTextRect.Left := FTextRect.Right - LTextWidth;
    else
      FTextRect.Width := LTextWidth;
    end;
    FTextArea.Intersect(Bounds);
  {$ENDREGION}

  {$REGION ' Selection '}
    if FSelLength > 0 then
    begin
      FSelectionRect := FTextRect;
      Inc(FSelectionRect.Left, LShadow.Left);
      Inc(FSelectionRect.Left, acTextSize(MeasureCanvas, GetPart1(LText)).cx);
      FSelectionRect.Width := acTextSize(MeasureCanvas, SelText).Width;
    end
    else
      FSelectionRect := NullRect;
  {$ENDREGION}

  {$REGION ' Caret '}
    FCaretRect := FTextRect;
    if FCaretPos > 0 then
    begin
      Inc(FCaretRect.Left, LShadow.Left);
      Inc(FCaretRect.Left, acTextSize(MeasureCanvas, Copy(LText, 1, CaretPos)).cx);
      FCaretRect := FCaretRect.Split(srLeft, dpiApply(1, Owner.GetCurrentDpi));
    end
    else
      FCaretRect.Width := dpiApply(1, Owner.GetCurrentDpi);
  {$ENDREGION}

  {$REGION ' Scrolling '}
    LMaxOffset := Max(FTextRect.Width - FTextArea.Width + FCaretRect.Width, 0);
    if [esFocused, esNoScrolling] * State = [esFocused] then
    begin
      if FCaretRect.Right - FOffset > FTextArea.Right then
        FOffset := FCaretRect.Right - FTextArea.Right + {Indent}FTextRect.Height;
      if FCaretRect.Left  - FOffset < FTextArea.Left then
        FOffset := FCaretRect.Left  - FTextArea.Left  - {Indent}FTextRect.Height;
    end;
    FOffset := MinMax(FOffset, FTextRect.Left - FTextArea.Left, LMaxOffset);

    FCaretRect.Offset(-FOffset, 0);
    FSelectionRect.Offset(-FOffset, 0);
    FTextRect.Offset(-FOffset, 0);
  {$ENDREGION}
  end;
end;

function TACLEditSubClass.CalculateStep(AGoForward: Boolean; AShift: TShiftState): Integer;
var
  LRange: TACLRange;
begin
  if ssCtrl in AShift then
  begin
    LRange := EditGetWordSelection(Text, CaretPos, Signs[AGoForward]);
    if LRange.Length >= 0 then
      Result := IfThen(AGoForward, LRange.Finish, LRange.Start) - CaretPos
    else
      Result := 0;
  end
  else
    if InRange(CaretPos + Signs[AGoForward], 1, Length(Text)) then
    begin
      if AGoForward then
        Result :=  acCharLength(FText, CaretPos + 1)
      else
        Result := -acCharPrevLength(FText, CaretPos + 1)
    end
    else
      Result := Signs[AGoForward];
end;

function TACLEditSubClass.CanExecute(AAction: TACLEditAction): Boolean;
begin
  case AAction of
    eaCut, eaDelete:
      Result := (SelLength > 0) and not ReadOnly;
    eaCopy:
      Result := (SelLength > 0);
    eaPaste:
      Result := not ReadOnly and Clipboard.HasText;
    eaUndo:
      Result := FUndo.IsAssigned;
    eaSelectAll:
      Result := (Text <> '') and not ((SelStart = 0) and (SelLength = Length(Text)));
  else
    Result := False;
  end;
end;

function TACLEditSubClass.CanInput(var AText, APart1, APart2: string): Boolean;
begin
  Result := (MaxLength = 0) or
    (acCharCount(APart1) + acCharCount(APart2) + acCharCount(AText) <= MaxLength);
  if Result and Assigned(OnInput) then
    OnInput(AText, APart1, APart2, Result);
end;

procedure TACLEditSubClass.Changed;
begin
  Include(FState, esChanged);
  if FUpdateCount = 0 then Refresh;
end;

procedure TACLEditSubClass.Draw(ACanvas: TCanvas);
var
  LClipRgn1: TRegionHandle;
  LClipRect: TRect;
  LText: string;
begin
  if acStartClippedDraw(ACanvas, FTextArea, LClipRgn1) then
  try
    AssignCanvasParameters(ACanvas);
    LText := GetDisplayText;

    if (SelLength > 0) and (esFocused in State){HideSelection} then
    begin
      LClipRect := FTextArea;
      LClipRect.Right := FSelectionRect.Left;
      acTextOut(ACanvas, FTextRect.Left, FTextRect.Top, LText, @LClipRect);

      LClipRect := FTextArea;
      LClipRect.Left := FSelectionRect.Right;
      acTextOut(ACanvas, FTextRect.Left, FTextRect.Top, LText, @LClipRect);

      ACanvas.Font.Color := Style.ColorTextSelected.AsColor;
      acFillRect(ACanvas, FSelectionRect, Style.ColorContentSelected.AsColor);
      acTextOut(ACanvas, FTextRect.Left, FTextRect.Top, LText, @FSelectionRect);
    end
    else
      if (LText <> '') or (esFocused in State) then
        acTextOut(ACanvas, FTextRect.Left, FTextRect.Top, LText)
      else
      begin
        ACanvas.Font.Color := Style.ColorTextHint.AsColor;
        acTextOut(ACanvas, FTextArea.Left, FTextArea.Top, TextHint);
      end;

    if [esCaret, esFocused] * State = [esCaret, esFocused] then
      acFillRect(ACanvas, FCaretRect, Style.ColorsText[True]);
  finally
    acEndClippedDraw(ACanvas, LClipRgn1);
  end;
end;

procedure TACLEditSubClass.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TACLEditSubClass.BlockScrolling(ALock: Boolean);
begin
  if ALock then
    Include(FState, esNoScrolling)
  else
    Exclude(FState, esNoScrolling);
end;

procedure TACLEditSubClass.EndUpdate;
begin
  Dec(FUpdateCount);
  if (FUpdateCount = 0) and (esChanged in State) then
    Refresh;
end;

procedure TACLEditSubClass.Execute(AAction: TACLEditAction);
begin
  case AAction of
    eaCopy:
      if SelLength > 0 then
        Clipboard.AsText := SelText;

    eaDelete:
      if not ReadOnly then
        SelText := '';

    eaCut:
      if not ReadOnly then
      begin
        Execute(eaCopy);
        SelText := '';
      end;

    eaPaste:
      if not ReadOnly then
        SelText := Clipboard.AsText;

    eaUndo:
      UndoRedo;

    eaSelectAll:
      Select(0, Length(Text));
  end;
end;

function TACLEditSubClass.GetDisplayText: string;
begin
  if Ord(PasswordChar) <> 0 then
    Result := acDupeString(PasswordChar, Length(Text))
  else if esFocused in State then
    Result := Text
  else if Assigned(OnDisplayFormat) then
    Result := OnDisplayFormat
  else
    Result := Text;
end;

function TACLEditSubClass.GetPart1(const AText: string): string;
begin
  Result := Copy(AText, 1, SelStart);
end;

function TACLEditSubClass.GetPart2(const AText: string): string;
begin
  Result := Copy(AText, 1 + SelStart + SelLength);
end;

function TACLEditSubClass.GetSelText: string;
begin
  Result := Copy(Text, 1 + SelStart, SelLength);
end;

function TACLEditSubClass.GetState(AState: TState): Boolean;
begin
  Result := AState in State;
end;

function TACLEditSubClass.GetTextShadow: TRect;
begin
  Result := NullRect;
end;

procedure TACLEditSubClass.HandlerCaretBlink(Sender: TObject);
begin
  if esCaret in State then
    Exclude(FState, esCaret)
  else
    Include(FState, esCaret);

  Invalidate;
end;

procedure TACLEditSubClass.KeyChar(var Key: WideChar);
begin
  if not (esIteract in State) then
    Exit;
  if not ReadOnly then
  begin
    if Ord(Key) = $7F then
      Exit;
    if Ord(Key) >= Ord(' ') then
      SelText := acString(Key);
  end;
  Key := #0;
end;

procedure TACLEditSubClass.KeyDown(var Key: Word; Shift: TShiftState);

  procedure ProcessBackspaceKey;
  var
    LCount: Integer;
  begin
    if ReadOnly then
      Exit;
    BeginUpdate;
    try
      if SelLength = 0 then
      begin
        if SelStart = 0 then Exit;
        LCount := CalculateStep(False, Shift);
        Select(SelStart + LCount, Abs(LCount), False);
      end;
      SelText := '';
    finally
      EndUpdate;
    end;
  end;

  function ProcessControlKey: Boolean;
  begin
    case Key of
      vkA: Execute(eaSelectAll);
      vkX: Execute(eaCut);
      vkC: Execute(eaCopy);
      vkV: Execute(eaPaste);
      vkZ: Execute(eaUndo);
    else
      Exit(False);
    end;
    Result := True;
  end;

  procedure ProcessDeleteKey;
  begin
    if ReadOnly then
      Exit;
    if acIsShiftPressed([ssShift], Shift) then
      Execute(eaCut)
    else
    begin
      BeginUpdate;
      try
        if SelLength = 0 then
          SelLength := CalculateStep(True, Shift);
        SelText := '';
      finally
        EndUpdate;
      end;
    end;
  end;

  procedure ProcessNavigationKey(APos: Integer; AArrows: Boolean);
  begin
    if ssShift in Shift then
      Select(Min(APos, FSelPin), Abs(APos - FSelPin), APos >= FSelPin)
    else
      if (SelLength > 0) and AArrows then
      begin
        if APos > CaretPos then
          Select(SelStart + SelLength, 0)
        else
          Select(SelStart, 0)
      end
      else
        CaretPos := APos;
  end;

begin
  if not (esIteract in State) then
    Exit;
  case Key of
    vkBack:
      ProcessBackspaceKey;
    vkHome:
      ProcessNavigationKey(0, False);
    vkEnd:
      ProcessNavigationKey(MaxInt, False);
    vkRight:
      ProcessNavigationKey(CaretPos + CalculateStep(True, Shift), True);
    vkLeft:
      ProcessNavigationKey(CaretPos + CalculateStep(False, Shift), True);
    vkDelete:
      ProcessDeleteKey;
    vkShift:
      if SelLength = 0 then
        FSelPin := SelStart + IfThen(CaretPos > SelStart, SelLength);

    vkReturn:
      if Assigned(OnReturn) then
        OnReturn
      else
        Exit;

    vkInsert:
      if acIsShiftPressed([ssCtrl], Shift) then
        Execute(eaCopy)
      else if acIsShiftPressed([ssShift], Shift) then
        Execute(eaPaste)
      else
        Exit;
  else
    if not (acIsShiftPressed([ssCtrl], Shift) and ProcessControlKey) then
      Exit;
  end;
  Key := 0;
end;

procedure TACLEditSubClass.KeyPreview(
  aKey: Word; Shift: TShiftState; var ACanHandle: Boolean);
const
  ControlKeys = [vkLWin{91}, vkF1..vkF20, vkCONTROL, vkSHIFT, vkMENU, vkRETURN];
begin
  if not (esIteract in State) then
    Exit;
  if AKey = vkINSERT then
    ACanHandle := acIsShiftPressed([ssCtrl], Shift) or acIsShiftPressed([ssShift], Shift)
  else if acIsShiftPressed([ssCtrl], Shift) then
    ACanHandle := AKey in [vkC, vkV, vkX, vkA, vkZ, vkLeft, vkRight]
  else
    ACanHandle := ([ssCtrl, ssAlt] * Shift = []) and not (AKey in ControlKeys);
end;

procedure TACLEditSubClass.Modify(const AText: string; ACaretPos: Integer);
var
  LValue: string;
begin
  if MaxLength > 0 then
    LValue := acCharCopy(AText, 1, MaxLength)
  else
    LValue := AText;

  if LValue <> FText then
  begin
    BeginUpdate;
    try
      FText := LValue;

      // До эвентов. На эвентах может быть выполнена коррекция
      if ACaretPos < 0 then
        Select(SelStart, SelLength, SelStart <> CaretPos)
      else
        Select(ACaretPos, 0);

      TextChanged;
      Changed;
    finally
      EndUpdate;
    end;
  end
  else
    if ACaretPos > 0 then
      Select(ACaretPos, 0);
end;

procedure TACLEditSubClass.MouseDown(
  Button: TMouseButton; Shift: TShiftState; const P: TPoint);
var
  LRange: TACLRange;
begin
  if not (esIteract in State) then
    Exit;
  if (Button = mbLeft) and Bounds.Contains(P) then
  begin
    CaretPos := TextHitTest(P.X, P.Y, True);
    if ssDouble in Shift then
    begin
      LRange := EditGetWordSelection(Text, CaretPos, 0);
      if LRange.Length > 0 then
        Select(LRange.Start, LRange.Length);
      FSelPin := SelStart;
    end
    else
    begin
      Include(FState, esDragging);
      FSelPin := CaretPos;
    end;
  end;
end;

procedure TACLEditSubClass.MouseMove(Shift: TShiftState; const P: TPoint);
var
  LIndex: Integer;
begin
  if esDragging in State then
  begin
    LIndex := TextHitTest(P.X, P.Y, True);
    if LIndex >= 0 then
      Select(Min(LIndex, FSelPin), Abs(LIndex - FSelPin), LIndex >= FSelPin);
  end;
end;

procedure TACLEditSubClass.MouseUp(
  Button: TMouseButton; Shift: TShiftState; const P: TPoint);
begin
  Exclude(FState, esDragging); // last
end;

procedure TACLEditSubClass.Select(AStart, ALength: Integer; AGoForward: Boolean);
var
  LCaret: Integer;
begin
  AStart  := MinMax(IfThen(Iteract, AStart),  0, Length(Text));
  ALength := MinMax(IfThen(Iteract, ALength), 0, Length(Text) - AStart);
  LCaret  := AStart + IfThen(AGoForward, ALength);
  if (AStart <> FSelStart) or (ALength <> FSelLength) or (LCaret <> FCaretPos) then
  begin
    FSelStart := AStart;
    FCaretPos := LCaret;
    FSelLength := ALength;
    Changed;
  end;
end;

procedure TACLEditSubClass.SetCaretPos(AValue: Integer);
begin
  BeginUpdate;
  try
    AValue := MinMax(AValue, 0, Length(Text));
    if AValue <> FCaretPos then
    begin
      FCaretPos := AValue;
      Include(FState, esCaret);
      if FCaretBlink <> nil then
        FCaretBlink.Restart;
      Changed;
    end;
    Select(CaretPos, 0);
  finally
    EndUpdate;
  end;
end;

procedure TACLEditSubClass.SetFocused(AValue: Boolean);
var
  LInterval: Cardinal;
begin
  AValue := AValue and Iteract;
  if (esFocused in State) <> AValue then
  begin
    if AValue then
    begin
      Include(FState, esCaret);
      Include(FState, esFocused);
      LInterval := GetCaretBlinkTime;
      if (LInterval <> 0) and (LInterval <> INFINITE) then
        FCaretBlink := TACLTimer.CreateEx(HandlerCaretBlink, LInterval).Start;
    end
    else
    begin
      Exclude(FState, esFocused);
      Exclude(FState, esCaret);
      FreeAndNil(FCaretBlink);
    end;
    FUndo.Reset;
    Changed;
  end;
end;

procedure TACLEditSubClass.SetMaxLength(AValue: Integer);
begin
  AValue := Max(AValue, 0);
  if FMaxLength <> AValue then
  begin
    FMaxLength := AValue;
    SetText(Text);
  end;
end;

procedure TACLEditSubClass.SetPasswordChar(AValue: Char);
begin
  if FPasswordChar <> AValue then
  begin
    FPasswordChar := AValue;
    Changed;
  end;
end;

procedure TACLEditSubClass.SetSelLength(AValue: Integer);
begin
  Select(SelStart, AValue);
end;

procedure TACLEditSubClass.SetSelStart(AValue: Integer);
begin
  Select(AValue, SelLength, False);
end;

procedure TACLEditSubClass.SetSelText(const Value: string);
var
  LHead: Integer;
  LPart1: string;
  LPart2: string;
  LTail: Integer;
  LValue: string;
begin
  LValue := Value;
  LPart1 := GetPart1(Text);
  LPart2 := GetPart2(Text);
  if CanInput(LValue, LPart1, LPart2) then
  begin
    BeginUpdate;
    try
      LHead := Length(LPart1);
      LTail := Length(LPart2);
      if not FUndo.Redo and FUndo.IsAssigned and
        (InRange(LHead,             FUndo.Head, Length(Text) - FUndo.Tail) or
         InRange(LHead + SelLength, FUndo.Head, Length(Text) - FUndo.Tail)) then
      begin
        FUndo.Head := Min(FUndo.Head, LHead);
        FUndo.Tail := Min(FUndo.Tail, LTail);
      end
      else
      begin
        FUndo.Reset;
        FUndo.Head := LHead;
        FUndo.Tail := LTail;
        FUndo.Text := Text;
      end;
      Modify(LPart1 + LValue + LPart2, Length(LPart1) + Length(LValue));
    finally
      EndUpdate;
    end;
  end;
end;

procedure TACLEditSubClass.SetState(AState: TState; AValue: Boolean);
begin
  if (AState in State) <> AValue then
  begin
    if AValue then
      Include(FState, AState)
    else
      Exclude(FState, AState);

    Changed;
  end;
end;

procedure TACLEditSubClass.SetText(const AValue: string);
begin
  Modify(AValue, 0);
end;

procedure TACLEditSubClass.SetTextAlign(AValue: TAlignment);
begin
  if FTextAlign <> AValue then
  begin
    FTextAlign := AValue;
    Changed;
  end;
end;

procedure TACLEditSubClass.SetTextHint(const Value: string);
begin
  if FTextHint <> Value then
  begin
    FTextHint := Value;
    Changed;
  end;
end;

procedure TACLEditSubClass.TextChanged;
begin
  if Assigned(OnChange) then OnChange();
end;

function TACLEditSubClass.TextHitTest(X, Y: Integer; AApproximate: Boolean): Integer;
var
  LCharLen: Integer;
  LRect: TRect;
  LText: PChar;
  LTextCur: PChar;
  LTextEnd: PChar;
  LTextStr: string;
begin
  Result := -1;
  LRect := FTextRect;
  LRect.Content(GetTextShadow);

  if AApproximate then
  begin
    X := MinMax(X, LRect.Left, LRect.Right - 1);
    Y := MinMax(Y, LRect.Top, LRect.Bottom - 1);
  end;

  if PtInRect(LRect, Point(X, Y)) then
  begin
    AssignCanvasParameters(MeasureCanvas);
    LTextStr := GetDisplayText;
    LText := PChar(LTextStr);
    LTextCur := LText;
    LTextEnd := LText + Length(LTextStr);
    while LText < LTextEnd do
    begin
      LCharLen := acCharLength(LTextCur);
      LRect.Width := acTextSize(MeasureCanvas, LTextCur, LCharLen).cx;
      if PtInRect(LRect, Point(X, Y)) then
      begin
        if X > (LRect.Right + LRect.Left) div 2 then
          Inc(LTextCur, LCharLen);
        Exit(LTextCur - LText);
      end;
      LRect.Left := LRect.Right;
      Inc(LTextCur, LCharLen);
    end;
  end;
end;

procedure TACLEditSubClass.UndoRedo;
var
  LUndo: TUndoInfo;
begin
  if FUndo.IsAssigned then
  begin
    BeginUpdate;
    try
      LUndo := FUndo;
      FUndo.Text := Text;
      FUndo.Redo := True;
      Text := LUndo.Text;
      Select(LUndo.Head, Length(Text) - LUndo.Tail - LUndo.Head);
    finally
      EndUpdate;
    end;
  end;
end;

{ TACLEditSubClass.TUndoInfo }

function TACLEditSubClass.TUndoInfo.IsAssigned: Boolean;
begin
  Result := Text <> '';
end;

procedure TACLEditSubClass.TUndoInfo.Reset;
begin
  Redo := False;
  Head := 0;
  Tail := 0;
  Text := '';
end;

{ TACLCustomEdit }

constructor TACLCustomEdit.Create(AOwner: TComponent);
begin
  inherited;
  CalculateTextPadding;
  ControlStyle := ControlStyle + [csOpaque];
  FDefaultSize := TSize.Create(121, 21);
  FStyle := TACLStyleEdit.Create(Self);
  FStyleButton := CreateStyleButton;
  RegisterSubClass(FEditBox, CreateSubClass);
  FEditBox.OnChange := TextChanged;
  FAutoSelect := not Inplace;
  FocusOnClick := True;
  AutoSize := not Inplace;
  Borders := not Inplace;
  TabStop := True;
end;

constructor TACLCustomEdit.CreateInplace(const AParams: TACLInplaceInfo);
begin
  FInplace := True;
  Create(AParams.Parent);
  OnKeyDown := AParams.OnKeyDown;
  OnExit := AParams.OnApply;
  Parent := AParams.Parent;
  FTextPadding.cy := 0;
  FTextPadding.cx := AParams.TextBounds.Left - AParams.Bounds.Left;
  BoundsRect := AParams.Bounds;
end;

destructor TACLCustomEdit.Destroy;
begin
  FreeAndNil(FStyleButton);
  FreeAndNil(FStyle);
  inherited;
end;

procedure TACLCustomEdit.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
begin
  inherited;
  if FEditBox.Iteract then
    TACLEditContextMenu.ContextPopup(Self, FEditBox, MousePos, Handled);
end;

{$IFDEF FPC}
procedure TACLCustomEdit.DoAutoSize;
begin
  // do nothing
end;

procedure TACLCustomEdit.ShouldAutoAdjust(var AWidth, AHeight: Boolean);
begin
  AHeight := not AutoSize;
  AWidth := True;
end;
{$ENDIF}

procedure TACLCustomEdit.BoundsChanged;
begin
  if not (csDestroying in ComponentState) then
  begin
    Calculate(ClientRect);
    inherited;
  end;
end;

procedure TACLCustomEdit.Calculate(ARect: TRect);
begin
  if Borders then
    ARect.Inflate(-OuterBorderSize);
  CalculateButtons(ARect, ButtonsIndent * Trunc(FCurrentPPI / acDefaultDpi));
  if Borders then
    ARect.Inflate(-InnerBorderSize);
  CalculateContent(ARect);
end;

procedure TACLCustomEdit.CalculateButtons(var ARect: TRect; AIndent: Integer);
begin
end;

procedure TACLCustomEdit.CalculateContent(ARect: TRect);
begin
  ARect.Inflate(-FTextPadding.cx, -FTextPadding.cy);
  FEditBox.BeginUpdate;
  try
    FEditBox.Changed; // force recalculate
    FEditBox.Calculate(ARect);
  finally
    FEditBox.EndUpdate;
  end;
end;

procedure TACLCustomEdit.CalculateTextPadding;
begin
  FTextPadding := TSize.Create(dpiApply(acTextIndent, FCurrentPPI));
end;

function TACLCustomEdit.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  if AutoSize then
  begin
    NewHeight := FEditBox.AutoHeight + 2 * FTextPadding.Height;
    if Borders then
      Inc(NewHeight, 2 * BorderSize);
  end;
  Result := True;
end;

procedure TACLCustomEdit.CMChanged(var Message: TMessage);
begin
  CallNotifyEvent(Self, OnChange);
end;

procedure TACLCustomEdit.CMEnter(var Message: TCMEnter);
begin
  inherited;
  if AutoSelect then
    FEditBox.Execute(eaSelectAll);
end;

procedure TACLCustomEdit.CMWantSpecialKey(var Message: TMessage);
begin
  if Inplace then
    Message.Result := 1
  else
    inherited;
end;

procedure TACLCustomEdit.FocusChanged;
begin
  inherited;
  FEditBox.SetFocused(Focused);
  InvalidateBorders;
end;

function TACLCustomEdit.GetCursor(const P: TPoint): TCursor;
begin
  if FEditBox.Iteract and FEditBox.Bounds.Contains(P) then
    Result := crIBeam
  else
    Result := Cursor;
end;

procedure TACLCustomEdit.InvalidateBorders;
begin
  if Borders and HandleAllocated and not (csDestroying in ComponentState) then
    acInvalidateBorders(Self, ClientRect, TRect.CreateMargins(BorderSize));
end;

procedure TACLCustomEdit.MouseEnter;
begin
  inherited;
  InvalidateBorders;
end;

procedure TACLCustomEdit.MouseLeave;
begin
  inherited;
  InvalidateBorders;
end;

function TACLCustomEdit.CreateStyle: TACLStyleEdit;
begin
  Result := TACLStyleEdit.Create(Self);
end;

function TACLCustomEdit.CreateStyleButton: TACLStyleButton;
begin
  Result := TACLStyleEditButton.Create(Self);
end;

function TACLCustomEdit.CreateSubClass: TACLEditSubClass;
begin
  Result := TACLEditSubClass.Create(Self, Style);
end;

procedure TACLCustomEdit.Paint;
begin
  acFillRect(Canvas, ClientRect, Style.ColorsContent[Enabled]);
  if Borders then
    Style.DrawBorders(Canvas, ClientRect,
      not (csDesigning in ComponentState) and MouseInClient,
      not (csDesigning in ComponentState) and Focused);
  PaintCore;
end;

procedure TACLCustomEdit.PaintCore;
begin
  SubClasses.Draw(Canvas);
end;

procedure TACLCustomEdit.SetBorders(AValue: Boolean);
begin
  if AValue <> FBorders then
  begin
    FBorders := AValue;
    FRedrawOnResize := Borders;
    if HandleAllocated then
    begin
      AdjustSize;
      Realign;
      Invalidate;
    end;
  end;
end;

procedure TACLCustomEdit.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if not (csLoading in ComponentState) then
    CanAutoSize(AWidth, AHeight);
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
end;

procedure TACLCustomEdit.SetFocusOnClick;
begin
  EditBox.BlockScrolling(True);
  inherited;
  EditBox.BlockScrolling(False);
end;

procedure TACLCustomEdit.SetStyle(AValue: TACLStyleEdit);
begin
  FStyle.Assign(AValue);
end;

procedure TACLCustomEdit.SetStyleButton(AValue: TACLStyleButton);
begin
  FStyleButton.Assign(AValue);
end;

procedure TACLCustomEdit.SetTargetDPI(AValue: Integer);
begin
  inherited;
  if not Inplace then
    CalculateTextPadding;
  Style.TargetDPI := AValue;
  StyleButton.TargetDPI := AValue;
end;

procedure TACLCustomEdit.TextChanged;
begin
  if not (csLoading in ComponentState) then Changed;
end;

procedure TACLCustomEdit.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS or DLGC_WANTCHARS;
end;

{ TACLEditContextMenu }

class constructor TACLEditContextMenu.Create;
begin
  FListener := TACLComponentFreeNotifier.Create(nil);
  FListener.OnFreeNotify := HandlerRemoving;
  Captions[eaCopy] := 'Copy';
  Captions[eaCut] := 'Cut';
  Captions[eaPaste] := 'Paste';
  Captions[eaSelectAll] := 'SelectAll';
  Captions[eaDelete] := 'Delete';
  Captions[eaUndo] := 'Undo';
end;

class destructor TACLEditContextMenu.Destroy;
begin
  FreeAndNil(FListener);
end;

class procedure TACLEditContextMenu.ContextPopup(AControl: TControl;
  AInvoker: TComponent; AMousePos: TPoint; var AHandled: Boolean);
var
  LMenu: TACLPopupMenu;
begin
  if AHandled or (TControlAccess(AControl).GetPopupMenu <> nil) then
    Exit;
  TControlAccess(AControl).SendCancelMode(AControl);
  if AControl is TWinControl then
    acSafeSetFocus(TWinControl(AControl));
  LMenu := Instance(AInvoker);
  LMenu.PopupComponent := AControl;
  LMenu.Popup(AControl.ClientToScreen(AMousePos));
  AHandled := True;
end;

class procedure TACLEditContextMenu.HandlerBuild(Sender: TObject);
var
  LEdit: IACLEditActions;
  LMenu: TACLPopupMenu absolute Sender;

  procedure AddAction(AAction: TACLEditAction);
  //const
  //  ShortcutMap: array[TACLEditAction] of Word = (vkC, vkX, vkV, vkZ, vkA, 0);
  begin
    LMenu.Items.AddItem(Captions[AAction], Ord(AAction), HandlerMenuClick
      {, ShortCut(ShortcutMap[AAction], [ssCtrl])}).Enabled := LEdit.CanExecute(AAction);
  end;

begin
  if Supports(LMenu.Owner, IACLEditActions, LEdit) then
  begin
    LMenu.Items.Clear;
    AddAction(eaUndo);
    LMenu.Items.AddSeparator;
    AddAction(eaCut);
    AddAction(eaCopy);
    AddAction(eaPaste);
    AddAction(eaDelete);
    LMenu.Items.AddSeparator;
    AddAction(eaSelectAll);
  end;
end;

class procedure TACLEditContextMenu.HandlerMenuClick(Sender: TObject);
var
  LEdit: IACLEditActions;
begin
  if (FPopupMenu <> nil) and Supports(FPopupMenu.Owner, IACLEditActions, LEdit) then
    LEdit.Execute(TACLEditAction(TMenuItem(Sender).Tag));
end;

class procedure TACLEditContextMenu.HandlerRemoving(AComponent: TComponent);
begin
  if AComponent = FPopupMenu then
    FPopupMenu := nil;
end;

class function TACLEditContextMenu.Instance(AInvoker: TComponent): TACLPopupMenu;
begin
  Result := Instance(AInvoker, TACLPopupMenu);
end;

class function TACLEditContextMenu.Instance(
  AInvoker: TComponent; AClass: TACLPopupMenuClass): TACLPopupMenu;
begin
  if (FPopupMenu = nil) or (FPopupMenu.Owner <> AInvoker) then
  begin
    FreeAndNil(FPopupMenu);
    FPopupMenu := AClass.Create(AInvoker);
    FPopupMenu.FreeNotification(FListener);
    FPopupMenu.OnPopup := HandlerBuild;
  end;
  Result := FPopupMenu;
end;

{ TACLIncrementalSearch }

procedure TACLIncrementalSearch.Cancel;
begin
  SetText('');
end;

function TACLIncrementalSearch.CanProcessKey(Key: Word;
  Shift: TShiftState; ACanStartEvent: TACLKeyPreviewEvent = nil): Boolean;
const
  ControlKeys = [91, VK_F1..VK_F20, VK_CONTROL, VK_SHIFT, VK_MENU, VK_RETURN, VK_DELETE, VK_INSERT];
begin
  Result := True;
  if Key in ControlKeys then
    Exit(False);
  if [ssCtrl, ssAlt] * Shift <> [] then
    Exit(False);
  if (ssShift in Shift) and not Active then
    Exit(False);
  if not Active then
  begin
    if Key = VK_SPACE then
      Exit(False);
    if Assigned(ACanStartEvent) then
      ACanStartEvent(Key, Shift, Result);
  end;
end;

function TACLIncrementalSearch.ProcessKey(Key: WideChar): Boolean;
begin
  Result := not Key.IsControl and (Key <> #8) and (Active or (Key <> ' '));
  if Result then
    SetText(Text + acString(Key));
end;

function TACLIncrementalSearch.ProcessKey(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True;
  case Key of
    VK_ESCAPE:
      Cancel;
    VK_SPACE:
      Result := Active and ([ssAlt, ssCtrl] * Shift = []);
    VK_BACK:
      SetText(acCharCopy(Text, 1, acCharCount(Text) - 1));
  else
    Result := False;
  end;
end;

function TACLIncrementalSearch.Contains(const AText: string): Boolean;
var
  X: Integer;
begin
  Result := not Active or GetHighlightBounds(AText, X, X);
end;

function TACLIncrementalSearch.GetHighlightBounds(
  const AText: string; out AHighlightStart, AHighlightFinish: Integer): Boolean;
var
  APosition: Integer;
begin
  Result := False;
  if Active then
  begin
    APosition := 0;
    if Mode = ismSearch then
    begin
      if acBeginsWith(AText, Text) then
        APosition := 1;
    end
    else
      APosition := acPos(Text, AText, True);

    if APosition > 0 then
    begin
      AHighlightStart := APosition - 1;
      AHighlightFinish := AHighlightStart + FTextLength;
      Result := True;
    end;
  end;
end;

function TACLIncrementalSearch.GetActive: Boolean;
begin
  Result := FTextLength > 0;
end;

procedure TACLIncrementalSearch.Changed;
begin
  CallNotifyEvent(Self, OnChange);
end;

procedure TACLIncrementalSearch.SetMode(const AValue: TACLIncrementalSearchMode);
begin
  if FMode <> AValue then
  begin
    FMode := AValue;
    if Active then
      Changed;
  end;
end;

procedure TACLIncrementalSearch.SetText(const AValue: string);
var
  AFound: Boolean;
  APrevText: string;
  APrevTextLength: Integer;
begin
  if not FLocked and (FText <> AValue) then
  begin
    FLocked := True;
    try
      APrevText := FText;
      APrevTextLength := FTextLength;

      FText := AValue;
      FTextLength := Length(FText);

      if (Mode = ismSearch) and (AValue <> '') and Assigned(OnLookup) then
      begin
        AFound := False;
        OnLookup(Self, AFound);
        if not AFound then
        begin
          FText := APrevText;
          FTextLength := APrevTextLength;
        end;
      end;

      Changed;
    finally
      FLocked := False;
    end;
  end;
end;

end.
