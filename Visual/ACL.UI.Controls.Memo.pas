////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Memo
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       Partial (scrollbars are not get skinned)
//
unit ACL.UI.Controls.Memo;

{$I ACL.Config.inc}

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

  { TACLCustomMemoContainerStyle }

  TACLCustomMemoContainerStyle = class(TACLScrollBoxStyle)
  public
    procedure DrawBorder(ACanvas: TCanvas;
      const R: TRect; const ABorders: TACLBorders); override;
  end;

  { TACLCustomMemoContainer }

  TACLCustomMemoContainer = class(TACLCustomScrollingControl)
  strict private
    FScrolling: Boolean;
    FStyle: TACLStyleEdit;

    function GetStyleScrollBox: TACLStyleScrollBox;
    procedure SetStyle(AValue: TACLStyleEdit);
    procedure SetStyleScrollBox(AValue: TACLStyleScrollBox);
    //# Messages
  {$IFNDEF FPC}
    procedure WMCommand(var Message: TWMCommand); message WM_COMMAND;
  {$ENDIF}
  protected
    function CreateStyle: TACLScrollBoxStyle; override;
    procedure EditorUpdateBounds; override;
    procedure EditorUpdateParamsCore; override;
    procedure EditorWndProc(var Message: TMessage); override;
    procedure FocusChanged; override;
    procedure SetTargetDPI(AValue: Integer); override;

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
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
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

  TACLMemo = class(TACLCustomMemoContainer)
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
    function CreateEditor: TACLInnerMemo; virtual;
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

{ TACLCustomMemoContainer }

constructor TACLCustomMemoContainer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csAcceptsControls];
  FStyle := TACLStyleEdit.Create(Self);
  TabStop := True;
end;

destructor TACLCustomMemoContainer.Destroy;
begin
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLCustomMemoContainer.AlignScrollBars(const ARect: TRect);
begin
  HorzScrollBar.Visible := {$IFDEF FPC}False{$ELSE}ScrollBars in [ssHorizontal, ssBoth]{$ENDIF};
  VertScrollBar.Visible := {$IFDEF FPC}False{$ELSE}ScrollBars in [ssVertical, ssBoth]{$ENDIF};
  UpdateScrollBars;
  inherited;
end;

function TACLCustomMemoContainer.CreateStyle: TACLScrollBoxStyle;
begin
  Result := TACLCustomMemoContainerStyle.Create(Self);
end;

procedure TACLCustomMemoContainer.EditorUpdateBounds;
begin
  inherited;
  UpdateScrollBars;
end;

procedure TACLCustomMemoContainer.EditorUpdateParamsCore;
begin
  inherited;
  FEditor.Align := alClient;
  Style.ApplyColors(FEditor, Enabled);
end;

procedure TACLCustomMemoContainer.EditorWndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_NCCALCSIZE, WM_NCPAINT:
      Exit;
    WM_NCHITTEST:
      begin
        Message.Result := IfThen(csDesigning in ComponentState, HTTRANSPARENT, HTCLIENT);
        Exit;
      end;
  end;
  inherited;
  case Message.Msg of
    WM_VSCROLL, WM_HSCROLL, WM_WINDOWPOSCHANGED:
      if not (csDestroying in ComponentState) then
      begin
        UpdateScrollBars;
        UpdateBorders;
      end;
  end;
end;

procedure TACLCustomMemoContainer.FocusChanged;
begin
  inherited;
  UpdateBorders;
end;

function TACLCustomMemoContainer.GetStyleScrollBox: TACLStyleScrollBox;
begin
  Result := inherited Style;
end;

procedure TACLCustomMemoContainer.Scroll(
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

procedure TACLCustomMemoContainer.ScrollContent(dX, dY: Integer);
begin
  // do nothing
end;

procedure TACLCustomMemoContainer.SetStyle(AValue: TACLStyleEdit);
begin
  FStyle.Assign(AValue);
end;

procedure TACLCustomMemoContainer.SetStyleScrollBox(AValue: TACLStyleScrollBox);
begin
  StyleScrollBox.Assign(AValue);
end;

procedure TACLCustomMemoContainer.SetTargetDPI(AValue: Integer);
begin
  inherited;
  Style.TargetDPI := AValue;
end;

procedure TACLCustomMemoContainer.UpdateScrollBars;
{$IFNDEF FPC}

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
    SetScrollBarParameters(HorzScrollBar);
    SetScrollBarParameters(VertScrollBar);
  end;
{$ELSE}
begin
{$ENDIF}
end;

{$IFNDEF FPC}
procedure TACLCustomMemoContainer.WMCommand(var Message: TWMCommand);
begin
  inherited;
  case Message.NotifyCode of
    EN_VSCROLL, EN_HSCROLL:
      UpdateScrollBars;
  end;
end;
{$ENDIF}

{ TACLCustomMemoContainerStyle }

procedure TACLCustomMemoContainerStyle.DrawBorder(
  ACanvas: TCanvas; const R: TRect; const ABorders: TACLBorders);
var
  LEdit: TACLCustomMemoContainer;
begin
  LEdit := TACLCustomMemoContainer(Owner);
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
  inherited;
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
  FEditor := CreateEditor;
  ScrollBars := ssNone;
  EditorHook(True);
end;

function TACLMemo.CreateEditor: TACLInnerMemo;
begin
  Result := TACLInnerMemo.Create(Self);
end;

procedure TACLMemo.Clear;
begin
  Lines.Clear;
end;

procedure TACLMemo.CopyToClipboard;
begin
  InnerMemo.CopyToClipboard;
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
  if InRange(CaretPos.Y, 0, Lines.Count - 1) then
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
