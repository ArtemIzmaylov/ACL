{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*               Panel Control               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Panel;

{$I ACL.Config.inc}

interface

uses
  System.Types,
  System.SysUtils,
  System.Classes,
  System.Math,
  // VCL
  Vcl.Controls,
  Vcl.Consts,
  Vcl.Graphics,
  // ACL
  ACL.Classes,
  ACL.UI.Controls.BaseControls,
  ACL.Utils.Common;

type

  { TACLPanel }

  TACLPanel = class(TACLContainer)
  strict private
    FOnHandleCreate: TNotifyEvent;
    FOnHandleDestroy: TNotifyEvent;
    FOnPaint: TNotifyEvent;
  protected
    procedure CreateHandle; override;
    procedure DestroyHandle; override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Canvas;
  published
    property AutoSize;
    property Borders;
    property Transparent;
    property Padding;

    property OnHandleCreate: TNotifyEvent read FOnHandleCreate write FOnHandleCreate;
    property OnHandleDestroy: TNotifyEvent read FOnHandleDestroy write FOnHandleDestroy;
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
  end;

implementation

{ TACLPanel }

constructor TACLPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
end;

procedure TACLPanel.CreateHandle;
begin
  inherited;
  CallNotifyEvent(Self, OnHandleCreate);
end;

procedure TACLPanel.DestroyHandle;
begin
  inherited;
  CallNotifyEvent(Self, OnHandleDestroy);
end;

procedure TACLPanel.Paint;
begin
  inherited Paint;
  CallNotifyEvent(Self, OnPaint);
end;

end.
