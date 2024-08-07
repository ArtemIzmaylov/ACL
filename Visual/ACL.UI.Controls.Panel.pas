////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Panel
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.Panel;

{$I ACL.Config.inc}

interface

uses
  {System.}Classes,
  {System.}SysUtils,
  // VCL
  {Vcl.}Controls,
  {Vcl.}Graphics,
  // ACL
  ACL.Classes,
  ACL.UI.Controls.Base,
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
