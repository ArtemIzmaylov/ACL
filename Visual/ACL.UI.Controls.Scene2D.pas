////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Extended Library-based PaintBox
//             with hardware acceleration via Direct2D
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.Scene2D;

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
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // ACL
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Ui.Controls.Base,
  // VCL
  {Vcl.}Controls;

type
  TACLRenderEvent = procedure (Sender: TObject; Render: TACL2DRender) of object;

  { TACLCustom2DScene }

  TACLCustom2DScene = class(TWinControl)
  strict private
    FRender: TACL2DRender;
    FUseHardwareAcceleration: Boolean;

    function CreateActualRender: TACL2DRender;
    procedure RecreateRenderRequested(Sender: TObject = nil);
    procedure SetUseHardwareAcceleration(AValue: Boolean);
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
  protected
    procedure CreateHandle; override;
    procedure DestroyHandle; override;
    procedure Paint(ARender: TACL2DRender); virtual;

    // events
    procedure DoCreate; virtual;
    procedure DoDestroy; virtual;

    property Render: TACL2DRender read FRender;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function IsHardwareAccelerationUsed: Boolean;
  published
    property UseHardwareAcceleration: Boolean read
      FUseHardwareAcceleration write SetUseHardwareAcceleration default True;
  end;

  { TACLPaintBox2D }

  TACLPaintBox2D = class(TACLCustom2DScene)
  strict private
    FOnDestroy: TACLRenderEvent;
    FOnCreate: TACLRenderEvent;
    FOnPaint: TACLRenderEvent;
  protected
    procedure DoCreate; override;
    procedure DoDestroy; override;
    procedure Paint(ARender: TACL2DRender); override;
  published
    property OnCreate: TACLRenderEvent read FOnCreate write FOnCreate;
    property OnDestroy: TACLRenderEvent read FOnDestroy write FOnDestroy;
    property OnPaint: TACLRenderEvent read FOnPaint write FOnPaint;
  end;

implementation

uses
{$IFDEF FPC}
  ACL.Graphics.Ex.Cairo;
{$ELSE}
  ACL.Graphics.Ex.D2D,
  ACL.Graphics.Ex.Gdip;
{$ENDIF}

{ TACLCustom2DScene }

constructor TACLCustom2DScene.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  FUseHardwareAcceleration := True;
end;

destructor TACLCustom2DScene.Destroy;
begin
  DoDestroy;
  FreeAndNil(FRender);
  inherited;
end;

function TACLCustom2DScene.CreateActualRender: TACL2DRender;
begin
{$IFDEF FPC}
  Result := TACLCairoRender.Create;
{$ELSE}
  if (csDesigning in ComponentState) or
    not HandleAllocated or
    not UseHardwareAcceleration or
    not TACLDirect2D.TryCreateRender(RecreateRenderRequested, WindowHandle, Result)
  then
    Result := TACLGdiplusRender.Create;
{$ENDIF}
end;

procedure TACLCustom2DScene.CreateHandle;
var
  LIntf: IACL2DRenderWndBased;
begin
  inherited;
  if Render = nil then
    FRender := CreateActualRender;
  if Supports(Render, IACL2DRenderWndBased, LIntf) then
  begin
    LIntf.SetWndHandle(Handle);
    LIntf := nil;
  end;
  DoCreate;
end;

procedure TACLCustom2DScene.DestroyHandle;
var
  LIntf: IACL2DRenderWndBased;
begin
  DoDestroy;
  if Supports(Render, IACL2DRenderWndBased, LIntf) then
  begin
    LIntf.SetWndHandle(0);
    LIntf := nil;
  end;
  inherited;
end;

procedure TACLCustom2DScene.DoCreate;
begin
  // do nothing
end;

procedure TACLCustom2DScene.DoDestroy;
begin
  // do nothing
end;

function TACLCustom2DScene.IsHardwareAccelerationUsed: Boolean;
begin
{$IFDEF FPC}
  Result := False;
{$ELSE}
  Result := Render is TACLDirect2DHwndBasedRender;
{$ENDIF}
end;

procedure TACLCustom2DScene.Paint(ARender: TACL2DRender);
begin
  // do nothing
end;

procedure TACLCustom2DScene.RecreateRenderRequested(Sender: TObject);
begin
  DoDestroy;
  FreeAndNil(FRender);
  if HandleAllocated then
  begin
    FRender := CreateActualRender;
    DoCreate;
    Invalidate;
  end;
end;

procedure TACLCustom2DScene.SetUseHardwareAcceleration(AValue: Boolean);
begin
  if FUseHardwareAcceleration <> AValue then
  begin
    FUseHardwareAcceleration := AValue;
  {$IFNDEF FPC}
    if not (csDesigning in ComponentState) then
    begin
      RecreateRenderRequested;
      if HandleAllocated then
        RecreateWnd;
    end;
  {$ENDIF}
  end;
end;

procedure TACLCustom2DScene.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TACLCustom2DScene.WMPaint(var Message: TWMPaint);
var
  APaintStruct: TPaintStruct;
begin
  if Message.DC <> 0 then
  begin
    Render.BeginPaint(Message.DC, ClientRect);
    try
      Paint(Render);
    finally
      Render.EndPaint;
    end;
  end
  else
    if Supports(Render, IACL2DRenderGdiCompatible) then
      TACLControls.BufferedPaint(Self)
    else
    begin
      BeginPaint(Handle, APaintStruct{%H-});
      try
        // We not need to copy directX frame's content to DC (its already been
        // drawn over our hwnd). So, what why we set DC to zero.
        Render.BeginPaint(0, ClientRect, APaintStruct.rcPaint);
        try
          Paint(Render);
        finally
          Render.EndPaint;
        end;
      finally
        EndPaint(Handle, APaintStruct);
      end;
    end;
end;

{ TACLPaintBox2D }

procedure TACLPaintBox2D.DoCreate;
begin
  if (Render <> nil) and Assigned(OnCreate) then
    OnCreate(Self, Render);
end;

procedure TACLPaintBox2D.DoDestroy;
begin
  if (Render <> nil) and Assigned(OnDestroy) then
    OnDestroy(Self, Render);
end;

procedure TACLPaintBox2D.Paint(ARender: TACL2DRender);
begin
  if csDesigning in ComponentState then
  begin
    ARender.FillRectangle(ClientRect, TAlphaColors.Black);
    ARender.DrawText('(' + Name + ')', ClientRect, TAlphaColors.White, Font, taCenter);
  end
  else
    if Assigned(OnPaint) then
      OnPaint(Self, ARender);
end;

end.
