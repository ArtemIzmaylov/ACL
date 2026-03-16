////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Authorization Dialogs
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Dialogs.Auth;

{$I ACL.Config.inc}

interface

uses
  {System.}Classes,
  {System.}Math,
  {System.}Variants,
  {System.}SysUtils,
  {System.}Types,
  System.JSON,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Forms,
  // ACL
  ACL.Crypto,
  ACL.Graphics,
  ACL.Geometry,
  ACL.Threading,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Forms,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Shell,
  ACL.Utils.Strings,
  ACL.Web,
  ACL.Web.Auth;

type

  { TACLAuthDialog }

  TACLAuthDialog = class(TACLForm)
  strict private const
    DefaultCaption = 'Authorization Master';
    DefaultMessage =
      'Waiting for authorization...' + acCRLF +
      'Please complete authorization request in your browser.' + acCRLF + acCRLF +
      'To cancel the operation just close the window.';
    ContentIndent = 12;
  strict private
    FMessage: string;
    FReceiver: TConsumerC<String>;
    FRequestUrl: TFunc<String>;
    FServer: TObject;
    FUrl: TACLEdit;

    procedure OnReceive(const UnparsedParams: string);
    procedure SendAuthRequest;
  protected
    procedure DblClick; override;
    procedure DoShow; override;
    procedure Paint; override;
  public
    class var AppHomeUrl: string;
    class var Caption: string;
    class var Message: string;
  public
    constructor Create(AOwnerWnd: TWndHandle); reintroduce;
    destructor Destroy; override;
    class constructor Create;
    class function Execute(AOwnerWnd: TWndHandle;
      const AReceiver: TConsumerC<String>; const ARequestUrl: TFunc<String>;
      const AServiceName: string = ''; const AMessage: string = ''): Boolean;
  end;

implementation

{ TACLAuthDialog }

class constructor TACLAuthDialog.Create;
begin
  Caption := DefaultCaption;
  Message := DefaultMessage;
end;

constructor TACLAuthDialog.Create(AOwnerWnd: TWndHandle);
begin
  CreateDialog(AOwnerWnd, True);
  BorderStyle := bsDialog;
  Position := poMainFormCenter;
  SetBounds(Left, Top, 512, 160);

  FUrl := TACLEdit.Create(Self);
  FUrl.Align := alBottom;
  FUrl.Margins.All := ContentIndent;
  FUrl.ReadOnly := True;
  FUrl.Parent := Self;
  FUrl.Visible := False;

  FServer := TAuthServer.Create(TACLWebURL.Parse(acDefaultAuthRedirectURL).Port, OnReceive, AppHomeUrl);
end;

destructor TACLAuthDialog.Destroy;
begin
  FreeAndNil(FServer);
  inherited;
end;

class function TACLAuthDialog.Execute(AOwnerWnd: TWndHandle;
  const AReceiver: TConsumerC<String>; const ARequestUrl: TFunc<String>;
  const AServiceName: string = ''; const AMessage: string = ''): Boolean;
var
  LDialog: TACLAuthDialog;
begin
  LDialog := TACLAuthDialog.Create(AOwnerWnd);
  try
    LDialog.Text := TACLAuthDialog.Caption + IfThenW(AServiceName <> '', ' - ') + AServiceName;
    LDialog.FMessage := IfThenW(AMessage, TACLAuthDialog.Message);
    LDialog.FRequestUrl := ARequestUrl;
    LDialog.FReceiver := AReceiver;
    Result := LDialog.ShowModal = mrOk;
  finally
    LDialog.Free;
  end;
end;

procedure TACLAuthDialog.DblClick;
begin
  inherited;
  FUrl.Visible := True;
end;

procedure TACLAuthDialog.DoShow;
begin
  inherited;
  TACLMainThread.RunPostponed(SendAuthRequest, Self);
end;

procedure TACLAuthDialog.Paint;
begin
  inherited Paint;
  Canvas.Font := Font;
  Canvas.Font.Color := Style.ColorText.AsColor;
  acTextDraw(Canvas, FMessage,
    ClientRect.InflateTo(-dpiApply(ContentIndent, FCurrentPPI)),
    taLeftJustify, taVerticalCenter, False, False, True);
end;

procedure TACLAuthDialog.OnReceive(const UnparsedParams: string);
begin
  if ModalResult = mrNone then
  begin
    FReceiver(UnparsedParams);
    ModalResult := mrOk;
  end;
end;

procedure TACLAuthDialog.SendAuthRequest;
begin
  Update; // ensure, text drawn
  FUrl.Text := FRequestUrl();
  ShellExecuteURL(FUrl.Text);
end;

end.
