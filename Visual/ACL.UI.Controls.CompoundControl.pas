{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*          Compoud Control Classes          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.CompoundControl;

{$I ACL.Config.inc} // FPC:OK

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
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}StdCtrls,
  // ACL
  ACL.MUI,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.HintWindow,
  ACL.UI.Resources;

type

  { TACLCompoundControl }

  TACLCompoundControl = class(TACLCustomControl,
    IACLCompoundControlSubClassContainer,
    IACLCursorProvider)
  strict private
    FSubClass: TACLCompoundControlSubClass;

    function GetOnCalculated: TNotifyEvent;
    function GetOnDropSourceData: TACLCompoundControlDropSourceDataEvent;
    function GetOnDropSourceFinish: TACLCompoundControlDropSourceFinishEvent;
    function GetOnDropSourceStart: TACLCompoundControlDropSourceStartEvent;
    function GetOnGetCursor: TACLCompoundControlGetCursorEvent;
    function GetOnUpdateState: TNotifyEvent;
    function GetStyleHint: TACLStyleHint;
    function GetStyleScrollBox: TACLStyleScrollBox;
    procedure SetOnCalculated(const AValue: TNotifyEvent);
    procedure SetOnDropSourceData(const AValue: TACLCompoundControlDropSourceDataEvent);
    procedure SetOnDropSourceFinish(const AValue: TACLCompoundControlDropSourceFinishEvent);
    procedure SetOnDropSourceStart(const AValue: TACLCompoundControlDropSourceStartEvent);
    procedure SetOnGetCursor(const AValue: TACLCompoundControlGetCursorEvent);
    procedure SetOnUpdateState(const Value: TNotifyEvent);
    procedure SetStyleScrollBox(const AValue: TACLStyleScrollBox);
    procedure SetStyleHint(const Value: TACLStyleHint);
    //# Messages
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMWantSpecialKey(var Message: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
    procedure WMHScroll(var Message: TWMHScroll); message WM_HSCROLL;
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
  protected
    procedure BoundsChanged; override;
    procedure LayoutChanged;
    procedure ResourceChanged; override;
    function CreateSubClass: TACLCompoundControlSubClass; virtual; abstract;

    // Ancestor
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
    procedure DoFullRefresh; override;
    procedure FocusChanged; override;
    procedure Loaded; override;
    procedure Paint; override;
    procedure SetDefaultSize; override;
    procedure SetTargetDPI(AValue: Integer); override;

    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
  {$IFDEF FPC}
    procedure UTF8KeyPress(var Key: TUTF8Char); override;
  {$ENDIF}

    // Mouse
    function DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    function DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    // Touch
  {$IFNDEF FPC}
    procedure DoGesture(const EventInfo: TGestureEventInfo; var Handled: Boolean); override;
  {$ENDIF}

    // IACLCompoundControlSubClassContainer
    function ClientToScreen(const P: TPoint): TPoint; reintroduce;
    function GetControl: TWinControl;
    function IACLCompoundControlSubClassContainer.GetFocused = Focused;
    function GetFont: TFont;
    function GetMouseCapture: Boolean; reintroduce;
    function ScreenToClient(const P: TPoint): TPoint; reintroduce;
    procedure SetMouseCapture(const AValue: Boolean);

    // IACLCursorProvider
    function GetCursor(const P: TPoint): TCursor; reintroduce; virtual;

    property StyleHint: TACLStyleHint read GetStyleHint write SetStyleHint;
    property StyleScrollBox: TACLStyleScrollBox read GetStyleScrollBox write SetStyleScrollBox;
    // Events
    property OnCalculated: TNotifyEvent read GetOnCalculated write SetOnCalculated;
    property OnDropSourceData: TACLCompoundControlDropSourceDataEvent read GetOnDropSourceData write SetOnDropSourceData;
    property OnDropSourceFinish: TACLCompoundControlDropSourceFinishEvent read GetOnDropSourceFinish write SetOnDropSourceFinish;
    property OnDropSourceStart: TACLCompoundControlDropSourceStartEvent read GetOnDropSourceStart write SetOnDropSourceStart;
    property OnGetCursor: TACLCompoundControlGetCursorEvent read GetOnGetCursor write SetOnGetCursor;
    property OnUpdateState: TNotifyEvent read GetOnUpdateState write SetOnUpdateState;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    function Focused: Boolean; override;
    procedure Localize(const ASection: string); override;
    // HourGlass notify
    procedure BeginLongOperation;
    procedure EndLongOperation;
    // Lock/unlock
    procedure BeginUpdate;
    procedure EndUpdate;
    function IsUpdateLocked: Boolean;
    // HitTest
    procedure UpdateHitTest(X, Y: Integer); overload;
    procedure UpdateHitTest(const P: TPoint); overload;
    procedure UpdateHitTest; overload;
    //# Properties
    property Canvas;
    property SubClass: TACLCompoundControlSubClass read FSubClass;
  published
    property DoubleBuffered default True;
  end;

implementation

uses
  ACL.Graphics,
  ACL.Utils.Common;

type
  TACLCompoundControlSubClassAccess = class(TACLCompoundControlSubClass);

{ TACLCompoundControl }

constructor TACLCompoundControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSubClass := CreateSubClass;
  DoubleBuffered := True;
end;

destructor TACLCompoundControl.Destroy;
begin
  FreeAndNil(FSubClass);
  inherited Destroy;
end;

procedure TACLCompoundControl.AfterConstruction;
begin
  inherited AfterConstruction;
  FullRefresh;
end;

function TACLCompoundControl.Focused: Boolean;
begin
{$IFDEF FPC}
  Result := acIsChild(Self, FindControl(GetFocus));
{$ELSE}
  var AHandle := GetFocus;
  Result := (AHandle <> 0) and (WindowHandle <> 0) and
    ((AHandle = WindowHandle) or IsChild(WindowHandle, AHandle));
{$ENDIF}
end;

procedure TACLCompoundControl.DoFullRefresh;
begin
  SubClass.FullRefresh;
end;

procedure TACLCompoundControl.Localize(const ASection: string);
begin
  inherited Localize(ASection);
  SubClass.Localize(ASection);
end;

procedure TACLCompoundControl.BeginLongOperation;
begin
  SubClass.BeginLongOperation;
end;

procedure TACLCompoundControl.EndLongOperation;
begin
  SubClass.EndLongOperation;
end;

procedure TACLCompoundControl.BeginUpdate;
begin
  SubClass.BeginUpdate;
end;

procedure TACLCompoundControl.EndUpdate;
begin
  SubClass.EndUpdate;
end;

function TACLCompoundControl.IsUpdateLocked: Boolean;
begin
  Result := SubClass.IsUpdateLocked;
end;

procedure TACLCompoundControl.UpdateHitTest(X, Y: Integer);
begin
  SubClass.UpdateHitTest(X, Y);
end;

procedure TACLCompoundControl.UpdateHitTest(const P: TPoint);
begin
  SubClass.UpdateHitTest(P);
end;

procedure TACLCompoundControl.UpdateHitTest;
begin
  SubClass.UpdateHitTest;
end;

procedure TACLCompoundControl.FocusChanged;
begin
  inherited FocusChanged;
  TACLCompoundControlSubClassAccess(SubClass).FocusChanged;
end;

procedure TACLCompoundControl.Loaded;
begin
  inherited Loaded;
  FullRefresh;
end;

procedure TACLCompoundControl.Paint;
begin
  SubClass.Draw(Canvas);
end;

procedure TACLCompoundControl.BoundsChanged;
var
  R: TRect;
begin
  if SubClass <> nil then
  begin
    R := ClientRect;
    AdjustClientRect(R);
    SubClass.Bounds := R;
  end;
end;

procedure TACLCompoundControl.LayoutChanged;
begin
  if SubClass <> nil then
    SubClass.Changed([cccnLayout]);
end;

procedure TACLCompoundControl.ResourceChanged;
begin
  if not (csDestroying in ComponentState) then
  begin
    SubClass.BeginUpdate;
    try
      TACLCompoundControlSubClassAccess(SubClass).ResourceChanged;
      inherited ResourceChanged;
    finally
      SubClass.EndUpdate;
    end;
  end;
end;

function TACLCompoundControl.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
var
  ARect: TRect;
begin
  Result := AutoSize and not SubClass.IsUpdateLocked;
  if Result and SubClass.CalculateAutoSize(NewWidth, NewHeight) then
  begin
    ARect := NullRect;
    AdjustClientRect(ARect);
    Inc(NewHeight, -ARect.Height);
    Inc(NewWidth, -ARect.Width);
  end;
end;

procedure TACLCompoundControl.SetDefaultSize;
begin
  SetBounds(Left, Top, 320, 240);
end;

procedure TACLCompoundControl.SetTargetDPI(AValue: Integer);
begin
  BeginUpdate;
  try
    inherited SetTargetDPI(AValue);
    SubClass.SetTargetDPI(AValue);
    SubClass.FullRefresh;
  finally
    EndUpdate;
  end;
end;

procedure TACLCompoundControl.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
begin
  SubClass.ContextPopup(MousePos, Handled);
  if not Handled then
    inherited DoContextPopup(MousePos, Handled);
end;

function TACLCompoundControl.GetCursor(const P: TPoint): TCursor;
begin
  Result := SubClass.GetCursor(P);
end;

procedure TACLCompoundControl.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  SubClass.KeyDown(Key, Shift);
end;

procedure TACLCompoundControl.KeyPress(var Key: Char);
begin
  inherited;
{$IFNDEF FPC}
  SubClass.KeyPress(Key);
{$ENDIF}
end;

procedure TACLCompoundControl.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  SubClass.KeyUp(Key, Shift);
end;

{$IFDEF FPC}
procedure TACLCompoundControl.UTF8KeyPress(var Key: TUTF8Char);
begin
  inherited;
  ProcessUtf8KeyPress(Key, SubClass.KeyPress);
end;
{$ENDIF}

function TACLCompoundControl.DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean;
begin
  if not inherited then
    SubClass.MouseWheel(mwdDown, Shift);
  Result := True;
end;

function TACLCompoundControl.DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean;
begin
  if not inherited then
    SubClass.MouseWheel(mwdUp, Shift);
  Result := True;
end;

procedure TACLCompoundControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SubClass.MouseDown(Button, Shift, X, Y);
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TACLCompoundControl.MouseLeave;
begin
  SubClass.MouseLeave;
  inherited MouseLeave;
end;

procedure TACLCompoundControl.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  SubClass.MouseMove(Shift, X, Y);
  inherited MouseMove(Shift, X, Y);
end;

procedure TACLCompoundControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SubClass.MouseUp(Button, Shift, X, Y);
  inherited MouseUp(Button, Shift, X, Y);
end;

{$IFNDEF FPC}
procedure TACLCompoundControl.DoGesture(const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  inherited DoGesture(EventInfo, Handled);
  if not Handled then
    SubClass.Gesture(EventInfo, Handled);
end;
{$ENDIF}

function TACLCompoundControl.ClientToScreen(const P: TPoint): TPoint;
begin
  if HandleAllocated then
    Result := inherited ClientToScreen(P)
  else
    Result := P;
end;

function TACLCompoundControl.ScreenToClient(const P: TPoint): TPoint;
begin
  if HandleAllocated then
    Result := inherited ScreenToClient(P)
  else
    Result := P;
end;

function TACLCompoundControl.GetControl: TWinControl;
begin
  Result := Self;
end;

function TACLCompoundControl.GetFont: TFont;
begin
  Result := Font;
end;

function TACLCompoundControl.GetMouseCapture: Boolean;
begin
  Result := MouseCapture;
end;

procedure TACLCompoundControl.SetMouseCapture(const AValue: Boolean);
begin
  MouseCapture := AValue;
end;

function TACLCompoundControl.GetOnCalculated: TNotifyEvent;
begin
  Result := SubClass.OnCalculated;
end;

function TACLCompoundControl.GetOnDropSourceData: TACLCompoundControlDropSourceDataEvent;
begin
  Result := SubClass.OnDropSourceData;
end;

function TACLCompoundControl.GetOnDropSourceFinish: TACLCompoundControlDropSourceFinishEvent;
begin
  Result := SubClass.OnDropSourceFinish;
end;

function TACLCompoundControl.GetOnDropSourceStart: TACLCompoundControlDropSourceStartEvent;
begin
  Result := SubClass.OnDropSourceStart;
end;

function TACLCompoundControl.GetOnGetCursor: TACLCompoundControlGetCursorEvent;
begin
  Result := SubClass.OnGetCursor;
end;

function TACLCompoundControl.GetOnUpdateState: TNotifyEvent;
begin
  Result := SubClass.OnUpdateState;
end;

function TACLCompoundControl.GetStyleHint: TACLStyleHint;
begin
  Result := SubClass.StyleHint;
end;

function TACLCompoundControl.GetStyleScrollBox: TACLStyleScrollBox;
begin
  Result := SubClass.StyleScrollBox;
end;

procedure TACLCompoundControl.SetOnCalculated(const AValue: TNotifyEvent);
begin
  SubClass.OnCalculated := AValue;
end;

procedure TACLCompoundControl.SetOnGetCursor(const AValue: TACLCompoundControlGetCursorEvent);
begin
  SubClass.OnGetCursor := AValue;
end;

procedure TACLCompoundControl.SetOnUpdateState(const Value: TNotifyEvent);
begin
  SubClass.OnUpdateState := Value;
end;

procedure TACLCompoundControl.SetStyleHint(const Value: TACLStyleHint);
begin
  SubClass.StyleHint := Value;
end;

procedure TACLCompoundControl.SetStyleScrollBox(const AValue: TACLStyleScrollBox);
begin
  SubClass.StyleScrollBox := AValue;
end;

procedure TACLCompoundControl.SetOnDropSourceData(const AValue: TACLCompoundControlDropSourceDataEvent);
begin
  SubClass.OnDropSourceData := AValue;
end;

procedure TACLCompoundControl.SetOnDropSourceFinish(const AValue: TACLCompoundControlDropSourceFinishEvent);
begin
  SubClass.OnDropSourceFinish := AValue;
end;

procedure TACLCompoundControl.SetOnDropSourceStart(const AValue: TACLCompoundControlDropSourceStartEvent);
begin
  SubClass.OnDropSourceStart := AValue;
end;

procedure TACLCompoundControl.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  SubClass.EnabledContent := Enabled;
end;

procedure TACLCompoundControl.CMFontChanged(var Message: TMessage);
begin
  inherited;
  ResourceChanged;
end;

procedure TACLCompoundControl.CMWantSpecialKey(var Message: TCMWantSpecialKey);
begin
  inherited;
  if Message.Result = 0 then
    Message.Result := Ord(SubClass.WantSpecialKey(
      Message.CharCode, KeyDataToShiftState(Message.KeyData)));
end;

procedure TACLCompoundControl.WMHScroll(var Message: TWMHScroll);
begin
  SubClass.ScrollHorizontally(TScrollCode(Message.ScrollCode));
  Message.Result := 1;
end;

procedure TACLCompoundControl.WMVScroll(var Message: TWMVScroll);
begin
  SubClass.ScrollVertically(TScrollCode(Message.ScrollCode));
  Message.Result := 1;
end;

end.
