{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*            ProgressBar Control            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.ProgressBar;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Types,
  System.Classes,
  // Vcl
  Vcl.Graphics,
  Vcl.Controls,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Resources,
  ACL.Utils.DPIAware;

type

  { TACLStyleProgress }

  TACLStyleProgress = class(TACLStyle)
  protected
    procedure InitializeResources; override;
  public
    procedure DrawBackground(DC: HDC; const R: TRect; AEnabled: Boolean);
    procedure DrawProgress(DC: HDC; const R: TRect);
  published
    property Texture: TACLResourceTexture index 0 read GetTexture write SetTexture stored IsTextureStored;
  end;

  { TACLProgressBar }

  TACLProgressBar = class(TACLGraphicControl)
  strict private
    FAnimPosition: Integer;
    FMax: Single;
    FMin: Single;
    FProgress: Single;
    FStyle: TACLStyleProgress;
    FTimer: TACLTimer;
    FWaitingMode: Boolean;

    function GetProgressAnimSize: Integer;
    function GetProgressAreaRect: TRect;
    function GetProgressRange: Single;
    function IsIndexStored(Index: Integer): Boolean;
    procedure SetIndex(AIndex: Integer; AValue: Single);
    procedure SetStyle(const Value: TACLStyleProgress);
    procedure SetWaitingMode(AValue: Boolean);
  protected
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    procedure CalculateProgressRect(var R1, R2: TRect);
    procedure SetTargetDPI(AValue: Integer); override;
    procedure DoTimer(Sender: TObject);
    procedure Paint; override;
    //
    property AnimPosition: Integer read FAnimPosition;
    property ProgressAnimSize: Integer read GetProgressAnimSize;
    property ProgressAreaRect: TRect read GetProgressAreaRect;
    property ProgressRange: Single read GetProgressRange;
    property Timer: TACLTimer read FTimer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    property Align;
    property Anchors;
    property Enabled;
    property Max: Single index 0 read FMax write SetIndex stored IsIndexStored;
    property Min: Single index 1 read FMin write SetIndex stored IsIndexStored;
    property ResourceCollection;
    property Style: TACLStyleProgress read FStyle write SetStyle;
    property Progress: Single index 2 read FProgress write SetIndex stored IsIndexStored;
    property Visible;
    property WaitingMode: Boolean read FWaitingMode write SetWaitingMode default False;

    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex.Gdip,
  ACL.UI.Forms,
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

{ TACLStyleProgress }

procedure TACLStyleProgress.DrawBackground(DC: HDC; const R: TRect; AEnabled: Boolean);
begin
  Texture.Draw(DC, R, 2 * Ord(not AEnabled));
end;

procedure TACLStyleProgress.DrawProgress(DC: HDC; const R: TRect);
begin
  Texture.Draw(DC, R, 1);
end;

procedure TACLStyleProgress.InitializeResources;
begin
  Texture.InitailizeDefaults('ProgressBar.Texture');
end;

{ TACLProgressBar }

constructor TACLProgressBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTimer := TACLTimer.CreateEx(DoTimer, 30);
  FStyle := TACLStyleProgress.Create(Self);
end;

destructor TACLProgressBar.Destroy;
begin
  FreeAndNil(FStyle);
  FreeAndNil(FTimer);
  inherited Destroy;
end;

procedure TACLProgressBar.CalculateProgressRect(var R1, R2: TRect);
var
  AHalfSize: Integer;
begin
  R1 := NullRect;
  R2 := NullRect;

  if WaitingMode then
  begin
    R1 := ProgressAreaRect;
    AHalfSize := ProgressAnimSize div 2;
    if AnimPosition < AHalfSize then
    begin
      R2 := R1;
      R2.Left := Width + AnimPosition - AHalfSize;
      R2.Right := R2.Left + ProgressAnimSize;
    end;
    if AnimPosition > Width - AHalfSize then
    begin
      R2 := R1;
      R2.Left := AnimPosition - Width - AHalfSize;
      R2.Right := R2.Left + ProgressAnimSize;
    end;
    R1.Left := AnimPosition - AHalfSize;
    R1.Right := AnimPosition + AHalfSize;
  end
  else
    if ProgressRange > 0 then
    begin
      R1 := ProgressAreaRect;
      R1.Right := R1.Left + Trunc(acRectWidth(R1) * (Progress - Min) / ProgressRange);
    end;
end;

procedure TACLProgressBar.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Style.SetTargetDPI(AValue);
  AdjustSize;
end;

procedure TACLProgressBar.DoTimer(Sender: TObject);
begin
  Inc(FAnimPosition, 5);
  if FAnimPosition > Width then
    FAnimPosition := 0;
  Invalidate;
end;

function TACLProgressBar.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if Style.Texture.HasAlpha then
    Result := cbsTransparent
  else
    Result := cbsOpaque;
end;

procedure TACLProgressBar.Paint;
var
  ASaveIndex: Integer;
  R1, R2: TRect;
begin
  Style.DrawBackground(Canvas.Handle, ClientRect, Enabled);
  if Enabled then
  begin
    ASaveIndex := SaveDC(Canvas.Handle);
    try
      if acIntersectClipRegion(Canvas.Handle, ProgressAreaRect) then
      begin
        CalculateProgressRect(R1, R2);
        Style.DrawProgress(Canvas.Handle, R1);
        Style.DrawProgress(Canvas.Handle, R2);
      end;
    finally
      RestoreDC(Canvas.Handle, ASaveIndex);
    end;
  end;
end;

procedure TACLProgressBar.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, dpiApply(18, FCurrentPPI));
end;

function TACLProgressBar.GetProgressAnimSize: Integer;
begin
  Result := Trunc(Width * 0.3);
end;

function TACLProgressBar.GetProgressAreaRect: TRect;
begin
  Result := acRectContent(ClientRect, Rect(1, 0, 1, 0));
end;

function TACLProgressBar.GetProgressRange: Single;
begin
  if (Max = 0) and (Min = 0) then
    Result := 100
  else
    Result := Max - Min;
end;

function TACLProgressBar.IsIndexStored(Index: Integer): Boolean;
begin
  Result := False;
  case Index of
    0: Result := not IsZero(FMax);
    1: Result := not IsZero(FMin);
    2: Result := not IsZero(FProgress);
  end;
end;

procedure TACLProgressBar.SetIndex(AIndex: Integer; AValue: Single);
var
  ANeedRedraw: Boolean;
begin
  ANeedRedraw := False;
  if Enabled then
  begin
    case AIndex of
      0: begin
           ANeedRedraw := not SameValue(FMax, AValue);
           FMax := AValue;
           FMin := System.Math.Min(FMin, FMax);
         end;
      1: begin
           ANeedRedraw := not SameValue(FMin, AValue);
           FMin := AValue;
           FMax := System.Math.Max(FMin, FMax);
         end;
      2: begin
           ANeedRedraw := not SameValue(FProgress, AValue);
           FProgress := AValue;
           if Progress > 0 then
             WaitingMode := False;
         end;
    end;
  end;
  if ANeedRedraw then
    Invalidate;
end;

procedure TACLProgressBar.SetStyle(const Value: TACLStyleProgress);
begin
  FStyle.Assign(Value);
end;

procedure TACLProgressBar.SetWaitingMode(AValue: Boolean);
begin
  if FWaitingMode <> AValue then
  begin
    FWaitingMode := AValue;
    FTimer.Enabled := WaitingMode;
    Invalidate;
    Update;
  end;
end;

end.
