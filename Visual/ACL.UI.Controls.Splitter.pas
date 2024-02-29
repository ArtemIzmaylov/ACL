{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Splitter Control              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Splitter;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Classes,
  System.SysUtils,
  System.Types,
  System.Math,
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Graphics,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.FileSystem;

type
  TACLSplitter = class;

  { TACLSplitterViewInfo }

  TACLSplitterViewInfo = class
  private
    FCursor: TCursor;
    FSplitter: TACLSplitter;
    FStoredSize: Integer;

    function GetControl: TControl;
  protected
    function GetControlSize: Integer; virtual;
    function GetParentSize: Integer; virtual;
    procedure SetControlSize(AValue: Integer); virtual;
  public
    constructor Create(ASplitter: TACLSplitter); virtual;
    procedure AdjustSize; virtual;
    function CalculateControlPosition(ADelta: Integer): Integer; overload;
    procedure CalculateControlPosition(var ADelta: TPoint); overload; virtual;
    function CalculateControlSize(APercents: Integer): Integer;
    // Storing
    procedure RestoreSize;
    procedure StoreSize;
    //
    property Control: TControl read GetControl;
    property ControlParentSize: Integer read GetParentSize;
    property ControlSize: Integer read GetControlSize write SetControlSize;
    property Cursor: TCursor read FCursor;
    property Splitter: TACLSplitter read FSplitter;
    property StoredSize: Integer read FStoredSize;
  end;

  { TACLSplitterVerticalViewInfo }

  TACLSplitterVerticalViewInfo = class(TACLSplitterViewInfo)
  protected
    function GetParentSize: Integer; override;
    function GetControlSize: Integer; override;
    procedure SetControlSize(AValue: Integer); override;
  public
    constructor Create(ASplitter: TACLSplitter); override;
    procedure AdjustSize; override;
    procedure CalculateControlPosition(var ADelta: TPoint); override;
  end;

  { TACLSplitter }

  TACLSplitter = class(TACLGraphicControl)
  strict private
    FCanToggle: Boolean;
    FControl: TControl;
    FLastPoint: TPoint;
    FMoving: Boolean;
    FViewInfo: TACLSplitterViewInfo;

    FOnPaint: TNotifyEvent;

    function GetAlign: TAlign;
    function GetIsControlVisible: Boolean;
    procedure DoToggle;
    procedure SetAlign(AValue: TAlign);
    procedure SetCanToggle(AValue: Boolean);
    procedure SetControl(AControl: TControl);
  protected
    function CreateViewInfo: TACLSplitterViewInfo;
    procedure DblClick; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure RecreateViewInfo;
    procedure UpdateControlBounds;
    procedure UpdateTransparency; override;
    //# Properties
    property Moving: Boolean read FMoving;
    property ViewInfo: TACLSplitterViewInfo read FViewInfo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdjustSize; override;
    procedure ConfigLoad(AConfig: TACLIniFile; const ASection, AItem: UnicodeString);
    procedure ConfigSave(AConfig: TACLIniFile; const ASection, AItem: UnicodeString);
    procedure Refresh;
    procedure Toggle;
  published
    property Align: TAlign read GetAlign write SetAlign stored False;
    property CanToggle: Boolean read FCanToggle write SetCanToggle default True;
    property Control: TControl read FControl write SetControl;
    property Cursor stored False;
    //# Events
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
  end;

implementation

uses
  ACL.Utils.Desktop;

{ TACLSplitter }

constructor TACLSplitter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alLeft;
  ControlStyle := [csCaptureMouse, csClickEvents, csDoubleClicks];
  FCanToggle := True;
  RecreateViewInfo;
  Height := 5;
  Width := 5;
end;

destructor TACLSplitter.Destroy;
begin
  FreeAndNil(FViewInfo);
  inherited Destroy;
end;

procedure TACLSplitter.AdjustSize;
begin
  if GetIsControlVisible then
    ViewInfo.AdjustSize
  else
    inherited AdjustSize;
end;

procedure TACLSplitter.DblClick;
var
  APoint: TPoint;
begin
  APoint := ScreenToClient(MouseCursorPos);
  Toggle;
  APoint := ClientToScreen(APoint);
  SetCursorPos(APoint.X, APoint.Y);
end;

procedure TACLSplitter.ConfigLoad(AConfig: TACLIniFile; const ASection, AItem: UnicodeString);
begin
  if Control <> nil then
  begin
    Control.Visible := AConfig.ReadBool(ASection, AItem + 'Visible', Control.Visible);
    ViewInfo.FStoredSize := dpiApply(AConfig.ReadInteger(ASection, AItem + 'StoredSize'), FCurrentPPI);
    if AConfig.ExistsKey(ASection, AItem + 'Value') then
      ViewInfo.ControlSize := dpiApply(AConfig.ReadInteger(ASection, AItem + 'Value'), FCurrentPPI);
  end;
end;

procedure TACLSplitter.ConfigSave(AConfig: TACLIniFile; const ASection, AItem: UnicodeString);
begin
  if Control <> nil then
  begin
    AConfig.WriteBool(ASection, AItem + 'Visible', Control.Visible);
    AConfig.WriteInteger(ASection, AItem + 'StoredSize', dpiRevert(ViewInfo.StoredSize, FCurrentPPI));
    AConfig.WriteInteger(ASection, AItem + 'Value', dpiRevert(ViewInfo.ControlSize, FCurrentPPI));
  end;
end;

function TACLSplitter.CreateViewInfo: TACLSplitterViewInfo;
begin
  if Align in [alLeft, alRight] then
    Result := TACLSplitterViewInfo.Create(Self)
  else
    Result := TACLSplitterVerticalViewInfo.Create(Self);
end;

procedure TACLSplitter.DoToggle;
begin
  if Control <> nil then
  begin
    if Control.Visible then
      ViewInfo.StoreSize
    else
      ViewInfo.RestoreSize;

    Control.Visible := not Control.Visible;
    UpdateControlBounds;
  end;
end;

procedure TACLSplitter.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  FMoving := Assigned(Control) and (Button = mbLeft) and not (ssDouble in Shift);
  if Moving and Control.Visible then
    ViewInfo.StoreSize;
  FLastPoint := MouseCursorPos;
end;

procedure TACLSplitter.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  inherited MouseMove(Shift, X, Y);
  if Moving then
  begin
    P := MouseCursorPos;
    P := Point(P.X - FLastPoint.X, P.Y - FLastPoint.Y);
    ViewInfo.CalculateControlPosition(P);
    Inc(FLastPoint.X, P.X);
    Inc(FLastPoint.Y, P.Y);
    AdjustSize;
    Parent.Update;
  end;
end;

procedure TACLSplitter.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FMoving := False;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TACLSplitter.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = Control then
      Control := nil;
  end;
end;

procedure TACLSplitter.Paint;
begin
  inherited Paint;
  CallNotifyEvent(Self, OnPaint);
end;

procedure TACLSplitter.RecreateViewInfo;
var
  AOldViewInfo: TACLSplitterViewInfo;
begin
  AOldViewInfo := FViewInfo;
  FViewInfo := CreateViewInfo;
  FreeAndNil(AOldViewInfo);
end;

procedure TACLSplitter.Refresh;
begin
  if Assigned(Control) then
  begin
    Align := Control.Align;
    Cursor := ViewInfo.Cursor;
    UpdateControlBounds;
  end;
  Invalidate;
end;

procedure TACLSplitter.Toggle;
begin
  if CanToggle then
    DoToggle;
end;

procedure TACLSplitter.UpdateControlBounds;
begin
  AdjustSize;
end;

procedure TACLSplitter.UpdateTransparency;
begin
  ControlStyle := ControlStyle - [csOpaque];
end;

function TACLSplitter.GetAlign: TAlign;
begin
  Result := inherited Align;
end;

function TACLSplitter.GetIsControlVisible: Boolean;
begin
  Result := Assigned(Control) and Control.Visible;
end;

procedure TACLSplitter.SetAlign(AValue: TAlign);
begin
  if Control <> nil then
    AValue := Control.Align;
  if AValue <> Align then
  begin
    inherited Align := AValue;
    RecreateViewInfo;
    Refresh;
  end;
end;

procedure TACLSplitter.SetCanToggle(AValue: Boolean);
begin
  if FCanToggle <> AValue then
  begin
    FCanToggle := AValue;
    if not (CanToggle or GetIsControlVisible) then
      DoToggle;
    Refresh;
  end;
end;

procedure TACLSplitter.SetControl(AControl: TControl);
begin
  if acComponentFieldSet(FControl, Self, AControl) then
    Refresh;
end;

{ TACLSplitterViewInfo }

constructor TACLSplitterViewInfo.Create(ASplitter: TACLSplitter);
begin
  inherited Create;
  FSplitter := ASplitter;
  FCursor := crHSplit;
end;

procedure TACLSplitterViewInfo.AdjustSize;
begin
  if Control <> nil then
  begin
    if Splitter.Align = alRight then
      Splitter.Left := Control.Left - Splitter.Width
    else
      Splitter.Left := Control.BoundsRect.Right;
  end;
end;

function TACLSplitterViewInfo.CalculateControlPosition(ADelta: Integer): Integer;

  function EncodeValue(AValue: Integer): Integer;
  begin
    if Splitter.Align in [alRight, alBottom] then
      Result := -AValue
    else
      Result := AValue;
  end;

var
  APrevSize: Integer;
  AValue: Integer;
begin
  APrevSize := IfThen(Control.Visible, ControlSize);
  AValue := Max(EncodeValue(ADelta) + APrevSize, 0);
  if (AValue <> 0) <> Control.Visible then
    Splitter.Toggle;
  if Control.Visible then
    ControlSize := AValue;
  Result := EncodeValue(IfThen(Control.Visible, ControlSize) - APrevSize);
end;

procedure TACLSplitterViewInfo.CalculateControlPosition(var ADelta: TPoint);
begin
  ADelta.X := CalculateControlPosition(ADelta.X);
end;

function TACLSplitterViewInfo.CalculateControlSize(APercents: Integer): Integer;
begin
  Result := MulDiv(ControlParentSize, APercents, 100);
end;

procedure TACLSplitterViewInfo.RestoreSize;
begin
  ControlSize := FStoredSize;
end;

procedure TACLSplitterViewInfo.StoreSize;
begin
  FStoredSize := ControlSize;
end;

function TACLSplitterViewInfo.GetControl: TControl;
begin
  Result := Splitter.Control;
end;

function TACLSplitterViewInfo.GetControlSize: Integer;
begin
  Result := Control.Width;
end;

function TACLSplitterViewInfo.GetParentSize: Integer;
begin
  Result := Control.Parent.Width;
end;

procedure TACLSplitterViewInfo.SetControlSize(AValue: Integer);
begin
  if Control.Constraints.MinWidth > 0 then
    AValue := Max(AValue, Control.Constraints.MinWidth);
  if Control.Constraints.MaxWidth > 0 then
    AValue := Min(AValue, Control.Constraints.MaxWidth);
  Control.Width := AValue;
end;

{ TACLSplitterVerticalViewInfo }

constructor TACLSplitterVerticalViewInfo.Create(ASplitter: TACLSplitter);
begin
  inherited Create(ASplitter);
  FCursor := crVSplit;
end;

procedure TACLSplitterVerticalViewInfo.AdjustSize;
begin
  if Control <> nil then
  begin
    if Splitter.Align = alBottom then
      Splitter.Top := Control.Top - Splitter.Height
    else
      Splitter.Top := Control.BoundsRect.Bottom;
  end;
end;

procedure TACLSplitterVerticalViewInfo.CalculateControlPosition(var ADelta: TPoint);
begin
  ADelta.Y := CalculateControlPosition(ADelta.Y);
end;

function TACLSplitterVerticalViewInfo.GetParentSize: Integer;
begin
  Result := Control.Parent.Height;
end;

function TACLSplitterVerticalViewInfo.GetControlSize: Integer;
begin
  Result := Control.Height;
end;

procedure TACLSplitterVerticalViewInfo.SetControlSize(AValue: Integer);
begin
  if Control.Constraints.MinHeight > 0 then
    AValue := Max(AValue, Control.Constraints.MinHeight);
  if Control.Constraints.MaxHeight > 0 then
    AValue := Min(AValue, Control.Constraints.MaxHeight);
  Control.Height := AValue;
end;

end.
