////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   CompoundControl Classes
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.CompoundControl;

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
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}StdCtrls,
  // ACL
  ACL.MUI,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.ScrollBar,
  ACL.UI.HintWindow,
  ACL.UI.Resources;

type

  { TACLCompoundControl }

  TACLCompoundControl = class(TACLCustomControl, IACLCompoundControlSubClassContainer)
  strict private
    FSubClass: TACLCompoundControlSubClass;

    function GetOnCalculated: TNotifyEvent;
    function GetOnDropSourceData: TACLCompoundControlDropSourceDataEvent;
    function GetOnDropSourceFinish: TACLCompoundControlDropSourceFinishEvent;
    function GetOnDropSourceStart: TACLCompoundControlDropSourceStartEvent;
    function GetOnUpdateState: TNotifyEvent;
    function GetStyleScrollBox: TACLStyleScrollBox;
    procedure SetOnCalculated(const AValue: TNotifyEvent);
    procedure SetOnDropSourceData(const AValue: TACLCompoundControlDropSourceDataEvent);
    procedure SetOnDropSourceFinish(const AValue: TACLCompoundControlDropSourceFinishEvent);
    procedure SetOnDropSourceStart(const AValue: TACLCompoundControlDropSourceStartEvent);
    procedure SetOnUpdateState(const Value: TNotifyEvent);
    procedure SetStyleScrollBox(const AValue: TACLStyleScrollBox);
    //# Messages
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMWantSpecialKey(var Message: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
    procedure WMHScroll(var Message: TWMHScroll); message WM_HSCROLL;
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
  protected
    function CreateSubClass: TACLCompoundControlSubClass; virtual; abstract;

    // Ancestor
    procedure BoundsChanged; override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
    procedure DoFullRefresh; override;
    procedure FocusChanged; override;
    procedure LayoutChanged;
    procedure Loaded; override;
    procedure Paint; override;
    procedure ResourceChanged; override;
    procedure SetTargetDPI(AValue: Integer); override;

    // Mouse
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    function MouseWheel(Direction: TACLMouseWheelDirection;
      Shift: TShiftState; const MousePos: TPoint): Boolean; override;

    // Touch
  {$IFNDEF FPC}
    procedure DoGesture(const EventInfo: TGestureEventInfo; var Handled: Boolean); override;
  {$ENDIF}

    // IACLCompoundControlSubClassContainer
    function IACLCompoundControlSubClassContainer.GetFocused = Focused;
    function ClientToScreen(const P: TPoint): TPoint; reintroduce;
    function GetControl: TWinControl;
    function ScreenToClient(const P: TPoint): TPoint; reintroduce;
    procedure UpdateCursor;

    property StyleScrollBox: TACLStyleScrollBox read GetStyleScrollBox write SetStyleScrollBox;
    // Events
    property OnCalculated: TNotifyEvent read GetOnCalculated write SetOnCalculated;
    property OnDropSourceData: TACLCompoundControlDropSourceDataEvent read GetOnDropSourceData write SetOnDropSourceData;
    property OnDropSourceFinish: TACLCompoundControlDropSourceFinishEvent read GetOnDropSourceFinish write SetOnDropSourceFinish;
    property OnDropSourceStart: TACLCompoundControlDropSourceStartEvent read GetOnDropSourceStart write SetOnDropSourceStart;
    property OnUpdateState: TNotifyEvent read GetOnUpdateState write SetOnUpdateState;
  public
    constructor Create(AOwner: TComponent); override;
    procedure AfterConstruction; override;
    procedure CalculateAutoSize(var AWidth, AHeight: Integer; AMinSize: Boolean = False);
    function Focused: Boolean; override;
    procedure Localize(const ASection, AName: string); override;
    // HourGlass notify
    procedure BeginLongOperation;
    procedure EndLongOperation;
    // Lock/unlock
    procedure BeginUpdate;
    procedure EndUpdate;
    function IsUpdateLocked: Boolean;
    // HitTest
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
  RegisterSubClass(FSubClass, CreateSubClass);
  FDefaultSize := TSize.Create(320, 240);
  DoubleBuffered := True;
end;

procedure TACLCompoundControl.AfterConstruction;
begin
  inherited AfterConstruction;
  FullRefresh;
end;

procedure TACLCompoundControl.CalculateAutoSize(
  var AWidth, AHeight: Integer; AMinSize: Boolean = False);
var
  LPadding: TRect;
begin
  LPadding := NullRect;
  AdjustClientRect(LPadding);
  Inc(AHeight, LPadding.Height);
  Inc(AWidth, LPadding.Width);
  SubClass.CalculateAutoSize(AWidth, AHeight, AMinSize);
  Dec(AHeight, LPadding.Height);
  Dec(AWidth, LPadding.Width);
end;

function TACLCompoundControl.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  Result := AutoSize and not SubClass.IsUpdateLocked;
  if Result then
    CalculateAutoSize(NewWidth, NewHeight);
end;

function TACLCompoundControl.Focused: Boolean;
begin
{$IFDEF FPC}
  Result := acIsChildOrSelf(Self, FindControl(GetFocus));
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

procedure TACLCompoundControl.Localize(const ASection, AName: string);
begin
  inherited;
  SubClass.Localize(LangSubSection(ASection, AName));
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

procedure TACLCompoundControl.UpdateHitTest(const P: TPoint);
begin
  SubClass.UpdateHitTest(P, []);
end;

procedure TACLCompoundControl.UpdateCursor;
begin
  if SubClass <> nil then
    Cursor := SubClass.Cursor;
end;

procedure TACLCompoundControl.UpdateHitTest;
begin
  SubClass.UpdateHitTest;
end;

procedure TACLCompoundControl.FocusChanged;
begin
  inherited FocusChanged;
  if not (csDestroying in ComponentState) then // can be invoked from WM_KillFocus on DestroyWnd
    TACLCompoundControlSubClassAccess(SubClass).FocusChanged;
end;

procedure TACLCompoundControl.Loaded;
begin
  inherited;
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
  if not (csDestroying in ComponentState) then
  begin
    R := ClientRect;
    AdjustClientRect(R);
    SubClass.Calculate(R);
  end;
end;

procedure TACLCompoundControl.LayoutChanged;
begin
  if not (csDestroying in ComponentState) then
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

procedure TACLCompoundControl.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  UpdateCursor;
end;

function TACLCompoundControl.MouseWheel(Direction: TACLMouseWheelDirection;
  Shift: TShiftState; const MousePos: TPoint): Boolean;
begin
  if not inherited then
    SubClass.MouseWheel(Direction, Shift);
  Result := True;
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

function TACLCompoundControl.GetOnUpdateState: TNotifyEvent;
begin
  Result := SubClass.OnUpdateState;
end;

function TACLCompoundControl.GetStyleScrollBox: TACLStyleScrollBox;
begin
  Result := SubClass.StyleScrollBox;
end;

procedure TACLCompoundControl.SetOnCalculated(const AValue: TNotifyEvent);
begin
  SubClass.OnCalculated := AValue;
end;

procedure TACLCompoundControl.SetOnUpdateState(const Value: TNotifyEvent);
begin
  SubClass.OnUpdateState := Value;
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

procedure TACLCompoundControl.CMHintShow(var Message: TCMHintShow);
begin
  SubClasses.Dispatch(Message);
  inherited; // last, to make possible to customize the hint via event
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
