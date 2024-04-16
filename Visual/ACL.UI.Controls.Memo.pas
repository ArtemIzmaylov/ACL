{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Editors Controls              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Memo;

{$I ACL.Config.inc} // FPC:Partical

// FPC: TODO - scrollbars not skinned

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  // VCL
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
  {Vcl.}Menus,
  {Vcl.}StdCtrls,
{$IFNDEF FPC}
  System.UITypes,
{$ENDIF}
  // ACL
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.Controls.ScrollBox,
  ACL.UI.Resources;

type

  { TACLCustomEditContainerStyle }

  TACLCustomEditContainerStyle = class(TACLScrollBoxStyle)
  public
    procedure DrawBorder(ACanvas: TCanvas;
      const R: TRect; const ABorders: TACLBorders); override;
  end;

  { TACLCustomEditContainer }

  TACLCustomEditContainer = class(TACLCustomScrollingControl)
  strict private
    FOnChange: TNotifyEvent;
    FScrolling: Boolean;
    FStyle: TACLStyleEdit;

    function GetStyleScrollBox: TACLStyleScrollBox;
    procedure SetStyle(AValue: TACLStyleEdit);
    procedure SetStyleScrollBox(AValue: TACLStyleScrollBox);
    //# Messages
    procedure CMChanged(var Message: TMessage); message CM_CHANGED;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  {$IFNDEF FPC}
    procedure WMCommand(var Message: TWMCommand); message WM_COMMAND;
  {$ENDIF}
  protected
    FEditor: TWinControl;
    FEditorWndProc: TWndMethod;

    function CreateEditor: TWinControl; virtual; abstract;
    function CreateStyle: TACLScrollBoxStyle; override;
    procedure EditorWndProc(var Message: TMessage); virtual;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure ResourceChanged; override;

    // ScrollBars
    procedure AlignScrollBars(const ARect: TRect); override;
    function GetScrollBars: TScrollStyle; virtual; abstract;
    procedure SetScrollBars(AValue: TScrollStyle); virtual; abstract;
    procedure Scroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer); override;
    procedure ScrollContent(dX, dY: Integer); override;
    procedure UpdateScrollBars;

    // Properties
    property ScrollBars: TScrollStyle read GetScrollBars write SetScrollBars;
    property Style: TACLStyleEdit read FStyle write SetStyle;
    property StyleScrollBox: TACLStyleScrollBox read GetStyleScrollBox write SetStyleScrollBox;
    // Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Focused: Boolean; override;
    procedure SetFocus; override;
  end;

  { TACLInnerMemo }

  TACLInnerMemo = class(TMemo, IACLInnerControl)
  protected
    procedure Change; override;
    // IACLInnerControl
    function GetInnerContainer: TWinControl;
  {$IFDEF DELPHI110ALEXANDRIA}
    procedure UpdateEditMargins; override;
  {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
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
    function GetSelLine: string;
    function GetSelStart: Integer;
    function GetSelText: string;
    function GetText: string;
    procedure SetCaretPos(const AValue: TPoint);
    procedure SetHideSelection(const Value: Boolean);
    procedure SetLines(AValue: TStrings);
    procedure SetMaxLength(AValue: Integer);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetSelLength(const Value: Integer);
    procedure SetSelStart(const Value: Integer);
    procedure SetSelText(const Value: string);
    procedure SetText(const Value: string);
  protected
    function CreateEditor: TWinControl; override;
    function GetScrollBars: TScrollStyle; override;
    procedure SetScrollBars(AValue: TScrollStyle); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Clear;
    procedure CopyToClipboard;
    procedure CutToClipboard;
    procedure PasteFromClipboard;
    //# Properties
    property CaretPos: TPoint read GetCaretPos write SetCaretPos;
    property InnerMemo: TACLInnerMemo read GetInnerMemo;
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelLine: string read GetSelLine;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelText: string read GetSelText write SetSelText;
    property Text: string read GetText write SetText;
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
    //# Events
    property OnChange;
  end;

implementation

uses
  ACL.MUI,
  ACL.Utils.Common;

type
  TWinControlAccess = class(TWinControl);

{ TACLCustomEditContainer }

constructor TACLCustomEditContainer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEditor := CreateEditor;
  FEditor.Align := alClient;
  FEditor.Parent := Self;
  FEditorWndProc := FEditor.WindowProc;
  FEditor.WindowProc := EditorWndProc;
  FStyle := TACLStyleEdit.Create(Self);
  TabStop := True;
end;

function TACLCustomEditContainer.CreateStyle: TACLScrollBoxStyle;
begin
  Result := TACLCustomEditContainerStyle.Create(Self);
end;

destructor TACLCustomEditContainer.Destroy;
begin
  FreeAndNil(FEditor);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLCustomEditContainer.AlignScrollBars(const ARect: TRect);
begin
  HorzScrollBar.Visible := {$IFDEF FPC}False{$ELSE}ScrollBars in [ssHorizontal, ssBoth]{$ENDIF};
  VertScrollBar.Visible := {$IFDEF FPC}False{$ELSE}ScrollBars in [ssVertical, ssBoth]{$ENDIF};
  UpdateScrollBars;
  inherited;
end;

procedure TACLCustomEditContainer.CMChanged(var Message: TMessage);
begin
  inherited;
  CallNotifyEvent(Self, OnChange)
end;

procedure TACLCustomEditContainer.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  ResourceChanged;
end;

procedure TACLCustomEditContainer.EditorWndProc(var Message: TMessage);
begin
  case Message.Msg of
    CN_CHAR:
      if DoKeyPress(TWMKey(Message)) then Exit;

    CN_KEYDOWN:
    {$IFDEF FPC}
      WMKeyDown(TWMKey(Message));
    {$ELSE}
      if DoKeyDown(TWMKey(Message)) then Exit;
    {$ENDIF}

    CN_KEYUP:
    {$IFDEF FPC}
      WMKeyUp(TWMKey(Message));
    {$ELSE}
      if DoKeyUp(TWMKey(Message)) then Exit;
    {$ENDIF}

    WM_MOUSEFIRST..WM_MOUSELAST:
      WindowProc(Message);

    WM_NCCALCSIZE, WM_NCPAINT:
      Exit;

    WM_NCHITTEST:
      begin
        Message.Result := IfThen(csDesigning in ComponentState, HTTRANSPARENT, HTCLIENT);
        Exit;
      end;

    WM_CONTEXTMENU:
      begin
        FEditor.SetFocus;
        Message.Result := Perform(Message.Msg, Handle, TMessage(Message).LParam);
        if Message.Result <> 0 then Exit;
      end;

    WM_VSCROLL, WM_HSCROLL, WM_WINDOWPOSCHANGED:
      begin
        FEditorWndProc(Message);
        UpdateScrollBars;
        UpdateBorders;
        Exit;
      end;

    WM_SETFOCUS, WM_KILLFOCUS:
      UpdateBorders;
  end;
  FEditorWndProc(Message);
end;

function TACLCustomEditContainer.Focused: Boolean;
begin
  Result := inherited or FEditor.Focused;
end;

procedure TACLCustomEditContainer.SetTargetDPI(AValue: Integer);
begin
  inherited;
  Style.TargetDPI := AValue;
end;

procedure TACLCustomEditContainer.UpdateScrollBars;
{$IFNDEF FPC}

  procedure SetScrollBarParameters(AScrollBar: TACLScrollBar);
  const
    BarFlags: array [TScrollBarKind] of Integer = (SB_HORZ, SB_VERT);
    ScrollBarOBJIDs: array[TScrollBarKind] of DWORD = (OBJID_HSCROLL, OBJID_VSCROLL);
  var
    AScrollBarInfo: TScrollBarInfo;
    AScrollInfo: TScrollInfo;
  begin
    if FEditor.HandleAllocated and AScrollBar.Visible then
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
    SetScrollBarParameters(HorzScrollBar);
    SetScrollBarParameters(VertScrollBar);
  end;
{$ELSE}
begin
{$ENDIF}
end;

function TACLCustomEditContainer.GetStyleScrollBox: TACLStyleScrollBox;
begin
  Result := inherited Style;
end;

procedure TACLCustomEditContainer.ResourceChanged;
begin
  inherited;
  TWinControlAccess(FEditor).Font := Font;
  TWinControlAccess(FEditor).Font.Color := Style.ColorsText[Enabled];
  TWinControlAccess(FEditor).Color := Style.ColorsContent[Enabled];
end;

procedure TACLCustomEditContainer.Scroll(
  Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);

  function GetWParam: WParam;
  begin
    if (Sender = HorzScrollBar) or not (ScrollCode in [scLineDown, scLineUp]) then
      Result := ScrollPos
    else
      Result := 0;

    Result := MakeWParam(Ord(ScrollCode), Result);
  end;

const
  ScrollBarIDs: array[Boolean] of Integer = (SB_HORZ, SB_VERT);
  ScrollMessages: array[Boolean] of UINT = (WM_HSCROLL, WM_VSCROLL);
begin
  FScrolling := True;
  try
    SetScrollPos(FEditor.Handle, ScrollBarIDs[Sender = VertScrollBar], ScrollPos, False);
    SendMessage(FEditor.Handle, ScrollMessages[Sender = VertScrollBar], GetWParam, 0);
    if ScrollCode <> scTrack then
      ScrollPos := GetScrollPos(FEditor.Handle, ScrollBarIDs[Sender = VertScrollBar]);
  finally
    FScrolling := False;
  end;
  if ScrollCode <> scTrack then
    UpdateScrollBars
  else
    Update;
end;

procedure TACLCustomEditContainer.ScrollContent(dX, dY: Integer);
begin
  // do nothing
end;

procedure TACLCustomEditContainer.SetFocus;
begin
  FEditor.SetFocus;
end;

procedure TACLCustomEditContainer.SetStyle(AValue: TACLStyleEdit);
begin
  FStyle.Assign(AValue);
end;

procedure TACLCustomEditContainer.SetStyleScrollBox(AValue: TACLStyleScrollBox);
begin
  StyleScrollBox.Assign(AValue);
end;

{$IFNDEF FPC}
procedure TACLCustomEditContainer.WMCommand(var Message: TWMCommand);
begin
  inherited;
  case Message.NotifyCode of
    EN_VSCROLL, EN_HSCROLL:
      UpdateScrollBars;
  end;
end;
{$ENDIF}

{ TACLCustomEditContainerStyle }

procedure TACLCustomEditContainerStyle.DrawBorder(
  ACanvas: TCanvas; const R: TRect; const ABorders: TACLBorders);
var
  LEdit: TACLCustomEditContainer;
begin
  LEdit := TACLCustomEditContainer(Owner);
  LEdit.Style.DrawBorders(ACanvas, R, LEdit.Focused);
  acDrawFrame(ACanvas, R.InflateTo(-1), LEdit.Style.ColorContent.AsColor);
end;

{ TACLInnerMemo }

constructor TACLInnerMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BorderStyle := bsNone;
end;

procedure TACLInnerMemo.Change;
var
  LMemo: TACLMemo;
begin
  LMemo := TACLMemo(GetInnerContainer);
  LMemo.Changed;
  LMemo.UpdateScrollBars;
end;

function TACLInnerMemo.GetInnerContainer: TWinControl;
begin
  Result := TWinControl(Owner);
end;

{$IFDEF DELPHI110ALEXANDRIA}
procedure TACLInnerMemo.UpdateEditMargins;
begin
  // do nothing
end;
{$ENDIF}

{ TACLMemo }

constructor TACLMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ScrollBars := ssNone;
end;

procedure TACLMemo.Clear;
begin
  Lines.Clear;
end;

procedure TACLMemo.CopyToClipboard;
begin
  InnerMemo.CopyToClipboard;
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

function TACLMemo.GetSelLine: string;
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

function TACLMemo.GetSelText: string;
begin
  Result := InnerMemo.SelText;
end;

function TACLMemo.GetText: string;
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

procedure TACLMemo.SetSelText(const Value: string);
begin
  InnerMemo.SelText := Value;
end;

procedure TACLMemo.SetText(const Value: string);
begin
  Lines.Text := Value;
end;

end.
