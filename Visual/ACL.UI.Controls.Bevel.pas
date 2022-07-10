{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*               Bevel Control               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Bevel;

{$I ACL.Config.inc}

interface

uses
  UITypes, Types, Windows, Messages, SysUtils, Classes, Controls, ImgList, Graphics, ActnList, ExtCtrls,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Layers,
  ACL.Graphics.SkinImage,
  ACL.Math,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Shell;

type

  { TACLStyleBevel }

  TACLBevelBorderStyle = (bbsNone, bbsSimple, bbs3D, bbsRounded);

  TACLStyleBevel = class(TACLStyle)
  strict private
    FBorders: TACLBorders;
    FBorderStyle: TACLBevelBorderStyle;

    procedure SetBorders(const Value: TACLBorders);
    procedure SetBorderStyle(const Value: TACLBevelBorderStyle);
  protected
    procedure DoAssign(ASource: TPersistent); override;
    procedure InitializeResources; override;
  public
    procedure Draw(ACanvas: TCanvas; R: TRect);
  published
    property Borders: TACLBorders read FBorders write SetBorders default acAllBorders;
    property BorderStyle: TACLBevelBorderStyle read FBorderStyle write SetBorderStyle default bbs3D;
    property ColorBorder1: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorBorder2: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLBevel }

  TACLBevel = class(TACLGraphicControl)
  strict private
    FStyle: TACLStyleBevel;

    procedure SetStyle(AValue: TACLStyleBevel);
  protected
    procedure SetTargetDPI(AValue: Integer); override;
    function CreateStyle: TACLStyleBevel; virtual;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Align;
    property Anchors;
    property ResourceCollection;
    property Style: TACLStyleBevel read FStyle write SetStyle;
    property Visible;
  end;

implementation

uses
  Math;

{ TACLStyleBevel }

procedure TACLStyleBevel.DoAssign(ASource: TPersistent);
begin
  inherited DoAssign(ASource);
  if ASource is TACLStyleBevel then
  begin
    Borders := TACLStyleBevel(ASource).Borders;
    BorderStyle := TACLStyleBevel(ASource).BorderStyle;
  end;
end;

procedure TACLStyleBevel.Draw(ACanvas: TCanvas; R: TRect);
var
  AClipRgn: HRGN;
begin
  case BorderStyle of
    bbsSimple:
      acDrawFrameEx(ACanvas.Handle, R, ColorBorder1.Value, Borders);
    bbs3D:
      acDrawComplexFrame(ACanvas.Handle, R, ColorBorder1.Value, ColorBorder2.Value, Borders);

    bbsRounded:
      begin
        AClipRgn := acSaveClipRegion(ACanvas.Handle);
        try
          acIntersectClipRegion(ACanvas.Handle, R);
          R := acRectInflate(R, Rect(5, 5, 5, 5), acAllBorders - Borders);
          ACanvas.Pen.Color := ColorBorder1.AsColor;
          ACanvas.Brush.Style := bsClear;
          ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 5, 5);
        finally
          acRestoreClipRegion(ACanvas.Handle, AClipRgn);
        end;
      end;
  end;
end;

procedure TACLStyleBevel.InitializeResources;
begin
  inherited InitializeResources;
  ColorBorder1.InitailizeDefaults('Bevels.Colors.Line1', True);
  ColorBorder2.InitailizeDefaults('Bevels.Colors.Line2', True);
  FBorders := acAllBorders;
  FBorderStyle := bbs3D;
end;

procedure TACLStyleBevel.SetBorders(const Value: TACLBorders);
begin
  if Value <> FBorders then
  begin
    FBorders := Value;
    Changed;
  end;
end;

procedure TACLStyleBevel.SetBorderStyle(const Value: TACLBevelBorderStyle);
begin
  if Value <> FBorderStyle then
  begin
    FBorderStyle := Value;
    Changed;
  end;
end;

{ TACLBevel }

constructor TACLBevel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStyle := CreateStyle;
end;

destructor TACLBevel.Destroy;
begin
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLBevel.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Style.SetTargetDPI(AValue);
end;

function TACLBevel.CreateStyle: TACLStyleBevel;
begin
  Result := TACLStyleBevel.Create(Self);
end;

function TACLBevel.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  Result := cbsTransparent;
end;

procedure TACLBevel.Paint;
begin
  Style.Draw(Canvas, ClientRect);
end;

procedure TACLBevel.SetStyle(AValue: TACLStyleBevel);
begin
  FStyle.Assign(AValue);
end;

end.
