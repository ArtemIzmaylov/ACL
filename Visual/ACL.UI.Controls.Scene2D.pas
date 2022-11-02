{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*         2D Render based Controls          *}
{* (with hardware acceleration via Direct2D) *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Scene2D;

{$I ACL.Config.Inc}

interface

uses
  Winapi.Messages,
  Winapi.Windows,
  // System
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // ACL
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.Ex.D2D,
  ACL.Graphics.Ex.Gdip,
  // VCL
  Vcl.Controls;

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
  published
    property UseHardwareAcceleration: Boolean read FUseHardwareAcceleration write SetUseHardwareAcceleration default True;
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
  if (csDesigning in ComponentState) or
    not HandleAllocated or
    not UseHardwareAcceleration or
    not TACLDirect2D.TryCreateRender(RecreateRenderRequested, WindowHandle, Result)
  then
    Result := TACLGdiplusRender.Create;
end;

procedure TACLCustom2DScene.CreateHandle;
begin
  inherited;
  if Render = nil then
    FRender := CreateActualRender;
  if Render is TACLDirect2DHwndBasedRender then
    TACLDirect2DHwndBasedRender(Render).SetWndHandle(Handle);
  DoCreate;
end;

procedure TACLCustom2DScene.DestroyHandle;
begin
  DoDestroy;
  if Render is TACLDirect2DHwndBasedRender then
    TACLDirect2DHwndBasedRender(Render).SetWndHandle(0);
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
    if not (csDesigning in ComponentState) then
    begin
      RecreateRenderRequested;
      if HandleAllocated then
        RecreateWnd;
    end;
  end;
end;

procedure TACLCustom2DScene.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TACLCustom2DScene.WMPaint(var Message: TWMPaint);
var
  AClipRgn: HRGN;
  AMemBmp: HBITMAP;
  AMemDC: HDC;
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
  begin
    BeginPaint(Handle, APaintStruct);
    try
      if Supports(Render, IACL2DRenderGdiCompatible) then
      begin
        AMemDC := acCreateMemDC(APaintStruct.hdc, APaintStruct.rcPaint, AMemBmp, AClipRgn);
        try
          Message.DC := AMemDC;
          Perform(WM_PAINT, Message.DC, 0);
          Message.DC := 0;
          acBitBlt(APaintStruct.hdc, AMemDC, APaintStruct.rcPaint, APaintStruct.rcPaint.TopLeft);
        finally
          acDeleteMemDC(AMemDC, AMemBmp, AClipRgn);
        end;
      end
      else
      begin
        // We not need to copy directX frame's content to DC (its already been drawn over our hwnd).
        // So, set DC to zero.
        Render.BeginPaint(0, ClientRect, APaintStruct.rcPaint);
        try
          Paint(Render);
        finally
          Render.EndPaint;
        end;
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
