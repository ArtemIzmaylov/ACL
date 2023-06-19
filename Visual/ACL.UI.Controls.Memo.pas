{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Editors Controls              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Memo;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // VCL
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  Vcl.Menus,
  Vcl.StdCtrls,
  // System
  System.UITypes,
  System.Classes,
  System.Types,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Resources;

type
  TACLMemo = class;

  { TACLInnerMemo }

  TACLInnerMemo = class(TMemo, IACLInnerControl)
  strict private
    function GetContainer: TACLMemo;
  protected
    procedure Change; override;
  {$IFDEF DELPHI110ALEXANDRIA}
    procedure UpdateEditMargins; override;
  {$ENDIF}
    procedure WndProc(var Message: TMessage); override;
    // Key
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer); override;
    // IACLInnerControl
    function GetInnerContainer: TWinControl;
    // Messages
    procedure WMContextMenu(var Message: TWMContextMenu); message WM_CONTEXTMENU;
    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHitTest;
    procedure WMNCPaint(var Message: TWMNCPaint); message WM_NCPAINT;
  public
    constructor Create(AOwner: TComponent); override;
    //
    property Container: TACLMemo read GetContainer;
  end;

  { TACLCustomEditContainer }

  TACLCustomEditContainer = class(TACLCustomEdit)
  strict private
    FScrollBarHorz: TACLScrollBar;
    FScrollBarVert: TACLScrollBar;
    FScrolling: Boolean;
    FStyleScrollBox: TACLStyleScrollBox;

    function GetSizeGripArea: TRect;
    procedure SetStyleScrollBox(AValue: TACLStyleScrollBox);
    procedure ScrollBarHandler(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure WMCommand(var Message: TWMCommand); message WM_COMMAND;
  protected
    procedure CalculateContent(const R: TRect); override;
    function CalculateEditorPosition: TRect; override;
    procedure SetDefaultSize; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure DrawContent(ACanvas: TCanvas); override;
    procedure ResourceChanged; override;

    // Scrollbars
    function CreateScrollBar(AKind: TScrollBarKind): TACLScrollBar;
    function GetScrollBars: TScrollStyle; virtual; abstract;
    procedure SetScrollBars(AValue: TScrollStyle); virtual; abstract;
    procedure Scroll(Kind: TScrollBarKind; ScrollCode: TScrollCode; var ScrollPos: Integer); virtual;
    procedure UpdateScrollBars;

    property DoubleBuffered default True;
    property ScrollBarHorz: TACLScrollBar read FScrollBarHorz;
    property ScrollBars: TScrollStyle read GetScrollBars write SetScrollBars;
    property ScrollBarVert: TACLScrollBar read FScrollBarVert;
    property SizeGripArea: TRect read GetSizeGripArea;
    property StyleScrollBox: TACLStyleScrollBox read FStyleScrollBox write SetStyleScrollBox;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { TACLMemo }

  TACLMemo = class(TACLCustomEditContainer)
  strict private
    function GetCaretPos: TPoint;
    function GetHideSelection: Boolean;
    function GetInnerMemo: TACLInnerMemo;
    function GetLines: TStrings;
    function GetMaxLength: Integer;
    function GetReadOnly: Boolean;
    function GetSelLength: Integer;
    function GetSelLine: UnicodeString;
    function GetSelStart: Integer;
    function GetSelText: UnicodeString;
    function GetText: UnicodeString;
    procedure SetCaretPos(const AValue: TPoint);
    procedure SetHideSelection(const Value: Boolean);
    procedure SetLines(AValue: TStrings);
    procedure SetMaxLength(AValue: Integer);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetSelLength(const Value: Integer);
    procedure SetSelStart(const Value: Integer);
    procedure SetSelText(const Value: UnicodeString);
    procedure SetText(const Value: UnicodeString);
  protected
    function GetScrollBars: TScrollStyle; override;
    procedure SetScrollBars(AValue: TScrollStyle); override;

    function CanOpenEditor: Boolean; override;
    function CreateEditor: TWinControl; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Clear;
    procedure CopyToClipboard;
    procedure CutToClipboard;
    procedure PasteFromClipboard;
    //
    property CaretPos: TPoint read GetCaretPos write SetCaretPos;
    property InnerMemo: TACLInnerMemo read GetInnerMemo;
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelLine: UnicodeString read GetSelLine;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelText: UnicodeString read GetSelText write SetSelText;
    property Text: UnicodeString read GetText write SetText;
  published
    property Borders;
    property Lines: TStrings read GetLines write SetLines;
    property HideSelection: Boolean read GetHideSelection write SetHideSelection default True;
    property MaxLength: Integer read GetMaxLength write SetMaxLength default 0;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property ScrollBars default ssNone;
    property ResourceCollection;
    property Style;
    property StyleScrollBox;
    property OnChange;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  // ACL
  ACL.Geometry,
  ACL.Utils.Common,
  ACL.MUI,
  ACL.Math;

{ TACLInnerMemo }

constructor TACLInnerMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BorderStyle := bsNone;
end;

procedure TACLInnerMemo.Change;
begin
  Container.Changed;
  Container.UpdateScrollBars;
end;

{$IFDEF DELPHI110ALEXANDRIA}
procedure TACLInnerMemo.UpdateEditMargins;
begin
  // do nothing
end;
{$ENDIF}

procedure TACLInnerMemo.WndProc(var Message: TMessage);
begin
  inherited WndProc(Message);
  case Message.Msg of
    WM_VSCROLL, WM_HSCROLL, WM_WINDOWPOSCHANGED:
      Container.UpdateScrollBars;
  end;
end;

procedure TACLInnerMemo.KeyDown(var Key: Word; Shift: TShiftState);
begin
  Container.KeyDown(Key, Shift);
end;

procedure TACLInnerMemo.KeyPress(var Key: Char);
begin
  Container.KeyPress(Key);
end;

procedure TACLInnerMemo.KeyUp(var Key: Word; Shift: TShiftState);
begin
  Container.KeyUp(Key, Shift);
end;

procedure TACLInnerMemo.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Container.MouseDown(Button, Shift, X, Y);
end;

procedure TACLInnerMemo.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  Container.MouseMove(Shift, X, Y);
end;

procedure TACLInnerMemo.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Container.MouseUp(Button, Shift, X, Y);
end;

function TACLInnerMemo.GetInnerContainer: TWinControl;
begin
  Result := TWinControl(Owner);
end;

procedure TACLInnerMemo.WMContextMenu(var Message: TWMContextMenu);
begin
  SetFocus;
  Message.Result := Parent.Perform(Message.Msg, Parent.Handle, TMessage(Message).LParam);
  if Message.Result = 0 then
    inherited;
end;

procedure TACLInnerMemo.WMNCCalcSize(var Message: TWMNCCalcSize);
var
  R: TRect;
begin
  R := Message.CalcSize_Params^.rgrc[0];
  inherited;
  Message.CalcSize_Params^.rgrc[0] := R;
end;

procedure TACLInnerMemo.WMNCHitTest(var Message: TWMNCHitTest);
begin
  if Container.IsDesigning then
    Message.Result := HTTRANSPARENT
  else
    Message.Result := HTCLIENT;
end;

procedure TACLInnerMemo.WMNCPaint(var Message: TWMNCPaint);
begin
  // do nothing
end;

function TACLInnerMemo.GetContainer: TACLMemo;
begin
  Result := TACLMemo(Owner);
end;

{ TACLCustomEditContainer }

constructor TACLCustomEditContainer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoHeight := False;
  ControlStyle := ControlStyle + [csOpaque];
  FStyleScrollBox := TACLStyleScrollBox.Create(Self);
  FScrollBarHorz := CreateScrollBar(sbHorizontal);
  FScrollBarVert := CreateScrollBar(sbVertical);
  DoubleBuffered := True;
  TabStop := True;
end;

destructor TACLCustomEditContainer.Destroy;
begin
  FreeAndNil(FScrollBarHorz);
  FreeAndNil(FScrollBarVert);
  FreeAndNil(FStyleScrollBox);
  inherited Destroy;
end;

function TACLCustomEditContainer.CreateScrollBar(AKind: TScrollBarKind): TACLScrollBar;
begin
  Result := TACLScrollBar.Create(Self);
  Result.ControlStyle := Result.ControlStyle + [csNoDesignVisible];
  Result.OnScroll := ScrollBarHandler;
  Result.Style := StyleScrollBox;
  Result.Parent := Self;
  Result.Kind := AKind;
end;

procedure TACLCustomEditContainer.CalculateContent(const R: TRect);
begin
  inherited CalculateContent(R);

  ScrollBarHorz.Visible := ScrollBars in [TScrollStyle.ssBoth, TScrollStyle.ssHorizontal];
  ScrollBarVert.Visible := ScrollBars in [TScrollStyle.ssBoth, TScrollStyle.ssVertical];

  if ScrollBarVert.Visible then
  begin
    ScrollBarVert.SetBounds(R.Right - ScrollBarVert.Width, R.Top, ScrollBarVert.Width,
      R.Height - IfThen(ScrollBarHorz.Visible, ScrollBarHorz.Height));
  end;

  if ScrollBarHorz.Visible then
  begin
    ScrollBarHorz.SetBounds(R.Left, R.Bottom - ScrollBarHorz.Height,
      R.Right - IfThen(ScrollBarVert.Visible, ScrollBarVert.Width), ScrollBarHorz.Height);
  end;

  UpdateScrollBars;
end;

function TACLCustomEditContainer.CalculateEditorPosition: TRect;
begin
  Result := inherited CalculateEditorPosition;
  if ScrollBarVert.Visible then
    Dec(Result.Right, ScrollBarVert.Width);
  if ScrollBarHorz.Visible then
    Dec(Result.Bottom, ScrollBarHorz.Height);
end;

procedure TACLCustomEditContainer.SetTargetDPI(AValue: Integer);
begin
  inherited;
  StyleScrollBox.TargetDPI := AValue;
end;

procedure TACLCustomEditContainer.DrawContent(ACanvas: TCanvas);
begin
  StyleScrollBox.DrawSizeGripArea(ACanvas.Handle, SizeGripArea);
end;

procedure TACLCustomEditContainer.ResourceChanged;
begin
  ScrollBarHorz.ResourceCollection := ResourceCollection;
  ScrollBarHorz.Style := StyleScrollBox;
  ScrollBarVert.ResourceCollection := ResourceCollection;
  ScrollBarVert.Style := StyleScrollBox;
  inherited;
end;

procedure TACLCustomEditContainer.Scroll(Kind: TScrollBarKind; ScrollCode: TScrollCode; var ScrollPos: Integer);

  function GetWParam: WParam;
  begin
    if (Kind = sbHorizontal) or not (ScrollCode in [scLineDown, scLineUp]) then
      Result := ScrollPos
    else
      Result := 0;

    Result := MakeWParam(Ord(ScrollCode), Result);
  end;

const
  ScrollBarIDs: array[TScrollBarKind] of Integer = (SB_HORZ, SB_VERT);
  ScrollMessages: array[TScrollBarKind] of UINT = (WM_HSCROLL, WM_VSCROLL);
begin
  FScrolling := True;
  try
    SetScrollPos(FEditor.Handle, ScrollBarIDs[Kind], ScrollPos, False);
    SendMessage(FEditor.Handle, ScrollMessages[Kind], GetWParam, 0);
    if ScrollCode <> scTrack then
      ScrollPos := GetScrollPos(FEditor.Handle, ScrollBarIDs[Kind]);
  finally
    FScrolling := False;
  end;
  if ScrollCode <> scTrack then
    UpdateScrollBars;
end;

procedure TACLCustomEditContainer.UpdateScrollBars;

  procedure SetScrollBarParameters(AScrollBar: TACLScrollBar);
  const
    BarFlags: array [TScrollBarKind] of Integer = (SB_HORZ, SB_VERT);
    ScrollBarOBJIDs: array[TScrollBarKind] of DWORD = (OBJID_HSCROLL, OBJID_VSCROLL);
  var
    AScrollBarInfo: TScrollBarInfo;
    AScrollInfo: TScrollInfo;
  begin
    if (FEditor <> nil) and FEditor.HandleAllocated and AScrollBar.Visible then
    begin
      AScrollBarInfo.cbSize := SizeOf(AScrollBarInfo);
      GetScrollBarInfo(FEditor.Handle, Integer(ScrollBarOBJIDs[AScrollBar.Kind]), AScrollBarInfo);

      AScrollInfo.cbSize := SizeOf(AScrollInfo);
      AScrollInfo.fMask := SIF_ALL;
      GetScrollInfo(FEditor.Handle, BarFlags[AScrollBar.Kind], AScrollInfo);
      AScrollBar.SetScrollParams(AScrollInfo);
      AScrollBar.Enabled :=
        (Integer(AScrollInfo.nPage) <= AScrollInfo.nMax) and
        (AScrollBarInfo.rgstate[0] and STATE_SYSTEM_UNAVAILABLE = 0);
    end
    else
      AScrollBar.Enabled := False;
  end;

begin
  if not FScrolling then
  begin
    SetScrollBarParameters(ScrollBarHorz);
    SetScrollBarParameters(ScrollBarVert);
  end;
end;

procedure TACLCustomEditContainer.ScrollBarHandler(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  if Sender = ScrollBarHorz then
    Scroll(sbHorizontal, ScrollCode, ScrollPos)
  else
    Scroll(sbVertical, ScrollCode, ScrollPos);
end;

function TACLCustomEditContainer.GetSizeGripArea: TRect;
begin
  if ScrollBarHorz.Visible and ScrollBarVert.Visible then
  begin
    Result := ScrollBarHorz.BoundsRect;
    Result.Left := Result.Right;
    Result.Right := ScrollBarVert.BoundsRect.Right;
  end
  else
    Result := NullRect;
end;

procedure TACLCustomEditContainer.SetDefaultSize;
begin
  SetBounds(Left, Top, 185, 90);
end;

procedure TACLCustomEditContainer.SetStyleScrollBox(AValue: TACLStyleScrollBox);
begin
  FStyleScrollBox.Assign(AValue);
end;

procedure TACLCustomEditContainer.WMCommand(var Message: TWMCommand);
begin
  inherited;

  case Message.NotifyCode of
    EN_VSCROLL, EN_HSCROLL:
      UpdateScrollBars;
  end;
end;

{ TACLMemo }

constructor TACLMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  EditorOpen;
  InnerMemo.ScrollBars := ssNone;
end;

procedure TACLMemo.Clear;
begin
  Lines.Clear;
end;

procedure TACLMemo.CopyToClipboard;
begin
  InnerMemo.CopyToClipboard;
end;

function TACLMemo.CanOpenEditor: Boolean;
begin
  Result := True;
end;

function TACLMemo.CreateEditor: TWinControl;
begin
  Result := TACLInnerMemo.Create(Self);
end;

procedure TACLMemo.CutToClipboard;
begin
  InnerMemo.CutToClipboard;
end;

function TACLMemo.GetCaretPos: TPoint;
begin
  Result := InnerMemo.CaretPos;
end;

function TACLMemo.GetHideSelection: Boolean;
begin
  Result := InnerMemo.HideSelection;
end;

function TACLMemo.GetInnerMemo: TACLInnerMemo;
begin
  Result := TACLInnerMemo(FEditor);
end;

function TACLMemo.GetLines: TStrings;
begin
  Result := InnerMemo.Lines;
end;

function TACLMemo.GetMaxLength: Integer;
begin
  Result := InnerMemo.MaxLength;
end;

function TACLMemo.GetReadOnly: Boolean;
begin
  Result := InnerMemo.ReadOnly;
end;

function TACLMemo.GetScrollBars: TScrollStyle;
begin
  Result := InnerMemo.ScrollBars;
end;

function TACLMemo.GetSelLength: Integer;
begin
  Result := InnerMemo.SelLength;
end;

function TACLMemo.GetSelLine: UnicodeString;
begin
  if (CaretPos.Y >= 0) and (CaretPos.Y < Lines.Count) then
    Result := Lines.Strings[CaretPos.Y]
  else
    Result := '';
end;

function TACLMemo.GetSelStart: Integer;
begin
  Result := InnerMemo.SelStart;
end;

function TACLMemo.GetSelText: UnicodeString;
begin
  Result := InnerMemo.SelText;
end;

function TACLMemo.GetText: UnicodeString;
begin
  Result := Lines.Text;
end;

procedure TACLMemo.PasteFromClipboard;
begin
  InnerMemo.PasteFromClipboard;
end;

procedure TACLMemo.SetCaretPos(const AValue: TPoint);
begin
  InnerMemo.CaretPos := AValue;
end;

procedure TACLMemo.SetHideSelection(const Value: Boolean);
begin
  InnerMemo.HideSelection := Value;
end;

procedure TACLMemo.SetLines(AValue: TStrings);
begin
  InnerMemo.Lines := AValue;
end;

procedure TACLMemo.SetMaxLength(AValue: Integer);
begin
  InnerMemo.MaxLength := AValue;
end;

procedure TACLMemo.SetReadOnly(AValue: Boolean);
begin
  InnerMemo.ReadOnly := AValue;
end;

procedure TACLMemo.SetScrollBars(AValue: TScrollStyle);
begin
  if ScrollBars <> AValue then
  begin
    InnerMemo.ScrollBars := AValue;
    FullRefresh;
    AdjustSize;
  end;
end;

procedure TACLMemo.SetSelLength(const Value: Integer);
begin
  InnerMemo.SelLength := Value;
end;

procedure TACLMemo.SetSelStart(const Value: Integer);
begin
  InnerMemo.SelStart := Value;
end;

procedure TACLMemo.SetSelText(const Value: UnicodeString);
begin
  InnerMemo.SelText := Value;
end;

procedure TACLMemo.SetText(const Value: UnicodeString);
begin
  Lines.Text := Value;
end;

end.
