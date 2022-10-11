{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*          Compoud Control Classes          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.CompoundControl.SubClass.ContentCells;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.SysUtils,
  System.Types,
  System.Classes,
  System.Generics.Collections,
  // Vcl
  Vcl.Controls,
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Graphics,
  ACL.Geometry,
  ACL.UI.Controls.CompoundControl.SubClass;

type
  TACLCompoundControlBaseContentCellViewInfo = class;

  { IACLCompoundControlSubClassContent }

  IACLCompoundControlSubClassContent = interface
  ['{EE51759E-3F6D-4449-A331-B16EB4FBB9A2}']
    function GetContentWidth: Integer;
    function GetViewItemsArea: TRect;
    function GetViewItemsOrigin: TPoint;
  end;

  { TACLCompoundControlBaseContentCell }

  TACLCompoundControlBaseContentCellClass = class of TACLCompoundControlBaseContentCell;
  TACLCompoundControlBaseContentCell = class(TACLUnknownObject)
  strict private
    FData: TObject;

    function GetBounds: TRect; inline;
  protected
    FHeight: Integer;
    FTop: Integer;
    FViewInfo: TACLCompoundControlBaseContentCellViewInfo;

    function GetClientBounds: TRect; virtual;
  public
    constructor Create(AData: TObject; AViewInfo: TACLCompoundControlBaseContentCellViewInfo);
    procedure CalculateHitTest(AInfo: TACLHitTestInfo);
    procedure Draw(ACanvas: TCanvas);
    function MeasureHeight: Integer;
    //
    property Bounds: TRect read GetBounds;
    property Data: TObject read FData;
    property Height: Integer read FHeight;
    property Top: Integer read FTop;
    property ViewInfo: TACLCompoundControlBaseContentCellViewInfo read FViewInfo;
  end;

  { TACLCompoundControlBaseContentCellViewInfo }

  TACLCompoundControlBaseContentCellViewInfo = class(TACLUnknownObject)
  strict private
    FOwner: IACLCompoundControlSubClassContent;

    function GetBounds: TRect;
  protected
    FData: TObject;
    FHeight: Integer;
    FWidth: Integer;

    procedure DoDraw(ACanvas: TCanvas); virtual; abstract;
    procedure DoGetHitTest(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo); virtual;
    function GetFocusRect: TRect; virtual;
    function GetFocusRectColor: TColor; virtual;
    function HasFocusRect: Boolean; virtual;
  public
    constructor Create(AOwner: IACLCompoundControlSubClassContent);
    procedure Calculate; overload;
    procedure Calculate(AWidth, AHeight: Integer); overload; virtual;
    procedure CalculateHitTest(AData: TObject; const ABounds: TRect; AInfo: TACLHitTestInfo);
    procedure Draw(ACanvas: TCanvas; AData: TObject; const ABounds: TRect);
    procedure Initialize(AData: TObject); overload; virtual;
    procedure Initialize(AData: TObject; AHeight: Integer); overload; virtual;
    function MeasureHeight: Integer; virtual;
    //
    property Bounds: TRect read GetBounds;
    property Owner: IACLCompoundControlSubClassContent read FOwner;
  end;

  { TACLCompoundControlBaseCheckableContentCellViewInfo }

  TACLCompoundControlBaseCheckableContentCellViewInfo = class(TACLCompoundControlBaseContentCellViewInfo)
  protected
    FCheckBoxRect: TRect;
    FExpandButtonRect: TRect;
    FExpandButtonVisible: Boolean;

    procedure DoGetHitTest(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo); override;
    function IsCheckBoxEnabled: Boolean; virtual;
  public
    property CheckBoxRect: TRect read FCheckBoxRect;
    property ExpandButtonRect: TRect read FExpandButtonRect;
    property ExpandButtonVisible: Boolean read FExpandButtonVisible;
  end;

  { TACLCompoundControlContentCellList }

  TACLCompoundControlContentCellList<T: TACLCompoundControlBaseContentCell> = class(TACLObjectList<T>)
  strict private
    FFirstVisible: Integer;
    FLastVisible: Integer;
    FOwner: IACLCompoundControlSubClassContent;
  protected
    FCellClass: TACLCompoundControlBaseContentCellClass;

    function GetClipRect: TRect; virtual;
  public
    constructor Create(AOwner: IACLCompoundControlSubClassContent);
    function Add(AData: TObject; AViewInfo: TACLCompoundControlBaseContentCellViewInfo): T;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
    procedure Clear;
    procedure Draw(ACanvas: TCanvas);
    function Find(AData: TObject; out ACell: T): Boolean;
    function FindFirstVisible(AStartFromIndex: Integer; ADirection: Integer; ADataClass: TClass; out ACell: T): Boolean;
    function GetCell(Index: Integer; out ACell: TACLCompoundControlBaseContentCell): Boolean;
    function GetContentSize: Integer;
    procedure UpdateVisibleBounds;
    //
    property FirstVisible: Integer read FFirstVisible;
    property LastVisible: Integer read FLastVisible;
  end;

  { TACLCompoundControlContentCellList }

  TACLCompoundControlContentCellList = class(TACLCompoundControlContentCellList<TACLCompoundControlBaseContentCell>)
  public
    constructor Create(AOwner: IACLCompoundControlSubClassContent; ACellClass: TACLCompoundControlBaseContentCellClass);
  end;

implementation

uses
  System.Math;

{ TACLCompoundControlBaseContentCell }

constructor TACLCompoundControlBaseContentCell.Create(AData: TObject; AViewInfo: TACLCompoundControlBaseContentCellViewInfo);
begin
  inherited Create;
  FData := AData;
  FViewInfo := AViewInfo;
end;

procedure TACLCompoundControlBaseContentCell.CalculateHitTest(AInfo: TACLHitTestInfo);
begin
  ViewInfo.CalculateHitTest(Data, Bounds, AInfo);
end;

procedure TACLCompoundControlBaseContentCell.Draw(ACanvas: TCanvas);
begin
  ViewInfo.Draw(ACanvas, Data, Bounds);
end;

function TACLCompoundControlBaseContentCell.MeasureHeight: Integer;
begin
  ViewInfo.Initialize(Data);
  Result := ViewInfo.MeasureHeight;
end;

function TACLCompoundControlBaseContentCell.GetClientBounds: TRect;
begin
  Result := System.Types.Bounds(0, Top, ViewInfo.Owner.GetContentWidth, Height);
end;

function TACLCompoundControlBaseContentCell.GetBounds: TRect;
begin
  Result := acRectOffset(GetClientBounds, ViewInfo.Owner.GetViewItemsOrigin);
end;

{ TACLCompoundControlBaseContentCellViewInfo }

constructor TACLCompoundControlBaseContentCellViewInfo.Create(AOwner: IACLCompoundControlSubClassContent);
begin
  FOwner := AOwner;
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Calculate;
begin
  Calculate(FWidth, FHeight);
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Calculate(AWidth, AHeight: Integer);
begin
  FWidth := AWidth;
  FHeight := AHeight;
end;

procedure TACLCompoundControlBaseContentCellViewInfo.CalculateHitTest(
  AData: TObject; const ABounds: TRect; AInfo: TACLHitTestInfo);
begin
  Initialize(AData, ABounds.Height);
  AInfo.HitObject := AData;
  AInfo.HitObjectData['ViewInfo'] := Self;
  DoGetHitTest(acPointOffsetNegative(AInfo.HitPoint, ABounds.TopLeft), ABounds.TopLeft, AInfo);
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Draw(ACanvas: TCanvas; AData: TObject; const ABounds: TRect);
begin
  MoveWindowOrg(ACanvas.Handle, ABounds.Left, ABounds.Top);
  try
    Initialize(AData, ABounds.Height);
    DoDraw(ACanvas);
    if HasFocusRect then
      acDrawFocusRect(ACanvas.Handle, GetFocusRect, acGetActualColor(GetFocusRectColor, ACanvas.Font.Color));
  finally
    MoveWindowOrg(ACanvas.Handle, -ABounds.Left, -ABounds.Top);
  end;
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Initialize(AData: TObject);
begin
  FData := AData;
end;

procedure TACLCompoundControlBaseContentCellViewInfo.Initialize(AData: TObject; AHeight: Integer);
begin
  FHeight := AHeight;
  Initialize(AData);
end;

function TACLCompoundControlBaseContentCellViewInfo.MeasureHeight: Integer;
begin
  Result := Bounds.Height;
end;

procedure TACLCompoundControlBaseContentCellViewInfo.DoGetHitTest(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo);
begin
  // do nothing
end;

function TACLCompoundControlBaseContentCellViewInfo.GetFocusRect: TRect;
begin
  Result := Bounds;
end;

function TACLCompoundControlBaseContentCellViewInfo.GetFocusRectColor: TColor;
begin
  Result := clDefault;
end;

function TACLCompoundControlBaseContentCellViewInfo.HasFocusRect: Boolean;
begin
  Result := False;
end;

function TACLCompoundControlBaseContentCellViewInfo.GetBounds: TRect;
begin
  Result := Rect(0, 0, FWidth, FHeight);
end;

{ TACLCompoundControlBaseCheckableContentCellViewInfo }

procedure TACLCompoundControlBaseCheckableContentCellViewInfo.DoGetHitTest(const P, AOrigin: TPoint; AInfo: TACLHitTestInfo);
begin
  if acPointInRect(CheckBoxRect, P) and IsCheckBoxEnabled then
  begin
    AInfo.Cursor := crHandPoint;
    AInfo.IsCheckable := True;
  end
  else
    if ExpandButtonVisible and acPointInRect(ExpandButtonRect, P) then
    begin
      AInfo.Cursor := crHandPoint;
      AInfo.IsExpandable := True;
    end;
end;

function TACLCompoundControlBaseCheckableContentCellViewInfo.IsCheckBoxEnabled: Boolean;
begin
  Result := True;
end;

{ TACLCompoundControlContentCellList }

constructor TACLCompoundControlContentCellList<T>.Create(AOwner: IACLCompoundControlSubClassContent);
begin
  inherited Create;
  FLastVisible := -1;
  FOwner := AOwner;
  FCellClass := TACLCompoundControlBaseContentCellClass(T);
end;

function TACLCompoundControlContentCellList<T>.Add(
  AData: TObject; AViewInfo: TACLCompoundControlBaseContentCellViewInfo): T;
begin
  Result := T(FCellClass.Create(AData, AViewInfo));
  inherited Add(Result);
end;

function TACLCompoundControlContentCellList<T>.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
var
  I: Integer;
begin
  for I := FirstVisible to LastVisible do
    if PtInRect(List[I].Bounds, AInfo.HitPoint) then
    begin
      List[I].CalculateHitTest(AInfo);
      Exit(True);
    end;
  Result := False;
end;

procedure TACLCompoundControlContentCellList<T>.Clear;
begin
  inherited Clear;
  UpdateVisibleBounds;
end;

procedure TACLCompoundControlContentCellList<T>.Draw(ACanvas: TCanvas);
var
  ASaveIndex: HRGN;
  I: Integer;
begin
  ASaveIndex := acSaveClipRegion(ACanvas.Handle);
  try
    if acIntersectClipRegion(ACanvas.Handle, GetClipRect) then
    begin
      for I := FirstVisible to LastVisible do
        List[I].Draw(ACanvas);
    end;
  finally
    acRestoreClipRegion(ACanvas.Handle, ASaveIndex);
  end;
end;

function TACLCompoundControlContentCellList<T>.Find(AData: TObject; out ACell: T): Boolean;
var
  I: Integer;
begin
  if AData <> nil then
    for I := 0 to Count - 1 do
      if List[I].Data = AData then
      begin
        ACell := List[I];
        Exit(True);
      end;
  Result := False;
end;

function TACLCompoundControlContentCellList<T>.FindFirstVisible(
  AStartFromIndex: Integer; ADirection: Integer; ADataClass: TClass; out ACell: T): Boolean;
var
  AIndex: Integer;
begin
  ACell := nil;
  AIndex := AStartFromIndex;
  while (AIndex <> -1) and (AIndex >= FirstVisible) and (AIndex <= LastVisible) do
  begin
    if Items[AIndex].Data is ADataClass then
    begin
      ACell := Items[AIndex];
      Break;
    end;
    Inc(AIndex, ADirection);
  end;
  Result := ACell <> nil;
end;

function TACLCompoundControlContentCellList<T>.GetCell(
  Index: Integer; out ACell: TACLCompoundControlBaseContentCell): Boolean;
begin
  Result := (Index >= 0) and (Index < Count);
  if Result then
    ACell := Items[Index];
end;

function TACLCompoundControlContentCellList<T>.GetClipRect: TRect;
begin
  Result := FOwner.GetViewItemsArea;
end;

function TACLCompoundControlContentCellList<T>.GetContentSize: Integer;
begin
  if Count > 0 then
    Result := Last.Bounds.Bottom - First.Bounds.Top
  else
    Result := 0;
end;

procedure TACLCompoundControlContentCellList<T>.UpdateVisibleBounds;
var
  ACell: TACLCompoundControlBaseContentCell;
  I: Integer;
  R: TRect;
begin
  R := acRectOffset(FOwner.GetViewItemsArea, 0, -FOwner.GetViewItemsOrigin.Y);

  FFirstVisible := Count;
  for I := 0 to Count - 1 do
  begin
    ACell := List[I];
    if ACell.Top + ACell.Height > R.Top then
    begin
      FFirstVisible := I;
      Break;
    end;
  end;

  FLastVisible := Count - 1;
  for I := Count - 1 downto FFirstVisible do
    if List[I].Top < R.Bottom then
    begin
      FLastVisible := I;
      Break;
    end;
end;

{ TACLCompoundControlContentCellList }

constructor TACLCompoundControlContentCellList.Create(
  AOwner: IACLCompoundControlSubClassContent; ACellClass: TACLCompoundControlBaseContentCellClass);
begin
  inherited Create(AOwner);
  FCellClass := ACellClass;
end;

end.
