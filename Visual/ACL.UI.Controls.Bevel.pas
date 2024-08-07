////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Bevel
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.Bevel;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}ImgList,
  {Vcl.}Graphics,
  {Vcl.}ActnList,
  {Vcl.}ExtCtrls,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.SkinImage,
  ACL.UI.Controls.Base,
  ACL.UI.Resources,
  ACL.Utils.Common;

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
    function CreateStyle: TACLStyleBevel; virtual;
    procedure Paint; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateTransparency; override;
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
  AClipRgn: TRegionHandle;
begin
  case BorderStyle of
    bbsSimple:
      acDrawFrameEx(ACanvas, R, ColorBorder1.Value, Borders);
    bbs3D:
      acDrawComplexFrame(ACanvas, R, ColorBorder1.Value, ColorBorder2.Value, Borders);

    bbsRounded:
      begin
        AClipRgn := acSaveClipRegion(ACanvas.Handle);
        try
          acIntersectClipRegion(ACanvas.Handle, R);
          R.Inflate(Rect(5, 5, 5, 5), acAllBorders - Borders);
          ACanvas.Pen.Color := ColorBorder1.AsColor;
          ACanvas.Brush.Style := bsClear;
          ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 5, 5);
        finally
          acRestoreClipRegion(ACanvas.Handle, AClipRgn);
        end;
      end;
  else;
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

procedure TACLBevel.Paint;
begin
  Style.Draw(Canvas, ClientRect);
end;

procedure TACLBevel.SetStyle(AValue: TACLStyleBevel);
begin
  FStyle.Assign(AValue);
end;

procedure TACLBevel.UpdateTransparency;
begin
  ControlStyle := ControlStyle - [csOpaque];
end;

end.
