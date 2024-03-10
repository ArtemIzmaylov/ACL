{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*            Font Select Dialog             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Dialogs.ColorPicker;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFNDEF FPC}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // Vcl
  {Vcl.}Graphics,
  {Vcl.}Controls,
  {Vcl.}Forms,
  {Vcl.}Dialogs,
  // ACL
  ACL.Graphics,
  ACL.Classes.Collections,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ColorPalette,
  ACL.UI.Controls.ColorPicker,
  ACL.UI.Controls.Panel,
  ACL.UI.Dialogs,
  ACL.Utils.DPIAware,
  ACL.Utils.Common,
  ACL.Utils.Strings;
type

  { TACLColorPickerDialog }

  TACLColorPickerDialog = class(TACLCustomInputDialog)
  strict private
    FPalette: TACLColorPalette;
    FPanel: TACLPanel;
    FPicker: TACLColorPicker;

    FColor: PAlphaColor;
    FColorOriginal: TAlphaColor;
    FOnApply: TProc;
  protected
    procedure AfterFormCreate; override;
    procedure ColorChangeHandler(Sender: TObject);
    procedure CreateControls; override;
    procedure DoApply(Sender: TObject = nil); override;
    procedure DoCancel(Sender: TObject = nil); override;
    procedure Initialize(AAllowEditAlpha: Boolean; AColor: PAlphaColor; AOnApply: TProc);
    procedure PlaceControls(var R: TRect); override;
  public
    class function Execute(var AColor: TColor;
      AOwnerWnd: THandle = 0; const ACaption: string = ''): Boolean; overload;
    class function Execute(var AColor: TAlphaColor;
      AOwnerWnd: THandle = 0; const ACaption: string = ''): Boolean; overload;
    class function Execute(var AColor: TAlphaColor; AAllowEditAlpha: Boolean;
      AOwnerWnd: THandle = 0; const ACaption: string = ''; AOnApply: TProc = nil): Boolean; overload;
    class function ExecuteQuery(AColor: TAlphaColor;
      AOwnerWnd: THandle = 0; const ACaption: string = ''): TAlphaColor; overload;
    class function ExecuteQuery(AColor: TAlphaColor; AAllowEditAlpha: Boolean;
      AOwnerWnd: THandle = 0; const ACaption: string = ''): TAlphaColor; overload;
  end;

implementation

{ TACLColorPickerDialog }

class function TACLColorPickerDialog.Execute(
  var AColor: TColor; AOwnerWnd: THandle; const ACaption: string): Boolean;
var
  AGpColor: TAlphaColor;
begin
  AGpColor := TAlphaColor.FromColor(AColor);
  Result := Execute(AGpColor, False, AOwnerWnd, ACaption);
  if Result then
    AColor := AGpColor.ToColor;
end;

class function TACLColorPickerDialog.Execute(
  var AColor: TAlphaColor; AOwnerWnd: THandle; const ACaption: string): Boolean;
begin
  Result := Execute(AColor, True, AOwnerWnd, ACaption);
end;

class function TACLColorPickerDialog.Execute(
  var AColor: TAlphaColor; AAllowEditAlpha: Boolean; AOwnerWnd: THandle;
  const ACaption: string; AOnApply: TProc): Boolean;
var
  ADialog: TACLColorPickerDialog;
begin
  ADialog := TACLColorPickerDialog.CreateDialog(AOwnerWnd, True);
  try
    ADialog.Caption := IfThenW(ACaption, 'Color');
    ADialog.Initialize(AAllowEditAlpha, @AColor, AOnApply);
    Result := ADialog.ShowModal = mrOk;
  finally
    ADialog.Free;
  end;
end;

class function TACLColorPickerDialog.ExecuteQuery(
  AColor: TAlphaColor; AOwnerWnd: THandle; const ACaption: string): TAlphaColor;
begin
  Result := ExecuteQuery(AColor, True, AOwnerWnd, ACaption);
end;

class function TACLColorPickerDialog.ExecuteQuery(AColor: TAlphaColor;
  AAllowEditAlpha: Boolean; AOwnerWnd: THandle; const ACaption: string): TAlphaColor;
begin
  Result := AColor;
  if not Execute(Result, AAllowEditAlpha, AOwnerWnd, ACaption) then
    Result := AColor;
end;

procedure TACLColorPickerDialog.AfterFormCreate;
begin
  inherited AfterFormCreate;
  Position := poMainFormCenter;
  BorderIcons := [biSystemMenu];
  BorderStyle := bsDialog;
  DoubleBuffered := True;
  AutoSize := True;
end;

procedure TACLColorPickerDialog.ColorChangeHandler(Sender: TObject);
begin
  SetHasChanges(True);
  if Sender = FPalette then
    FPicker.Color := FPalette.Color
  else
    FPalette.Color := FPicker.Color;
end;

procedure TACLColorPickerDialog.CreateControls;
begin
  CreateControl(FPanel, TACLPanel, Self, NullRect, alCustom);
  FPanel.Padding.All := 2;

  CreateControl(FPicker, TACLColorPicker, FPanel, NullRect, alTop);
  FPicker.Borders := [];
  FPicker.OnColorChanged := ColorChangeHandler;

  CreateControl(FPalette, TACLColorPalette, FPanel, Rect(0, MaxWord, 0, 0), alTop);
  FPalette.Margins.Left := 8;
  FPalette.Margins.Scalable := False;
  FPalette.AlignWithMargins := True;
  FPalette.FocusOnClick := True;
  FPalette.OptionsView.CellSize := 24;
  FPalette.OptionsView.CellSpacing := 2;
  FPalette.OptionsView.StyleOfficeTintCount := 4;
  FPalette.OnColorChanged := ColorChangeHandler;

  FPanel.AutoSize := True;
  inherited;
end;

procedure TACLColorPickerDialog.DoApply(Sender: TObject);
begin
  FColor^ := FPicker.Color;
  inherited;
  if Assigned(FOnApply) then FOnApply();
end;

procedure TACLColorPickerDialog.DoCancel(Sender: TObject);
begin
  if Assigned(FOnApply) and (FColor^ <> FColorOriginal) then
  begin
    FColor^ := FColorOriginal;
    FOnApply();
  end;
  inherited;
end;

procedure TACLColorPickerDialog.Initialize(
  AAllowEditAlpha: Boolean; AColor: PAlphaColor; AOnApply: TProc);
begin
  FColor := AColor;
  FColorOriginal := AColor^;
  FOnApply := AOnApply;

  CreateControls;
  ButtonApply.Visible := Assigned(FOnApply);
  HandleNeeded;

  FPalette.Items.Add(TAlphaColor.None);
  FPicker.Options.AllowEditAlpha := AAllowEditAlpha;
  FPicker.Color := AColor^;
  SetHasChanges(False);
end;

procedure TACLColorPickerDialog.PlaceControls(var R: TRect);
begin
  FPanel.Width := Max(FPicker.Width, FPalette.Width);
  R.Top := FPanel.BoundsRect.Bottom + dpiApply(8, FCurrentPPI);
  R.Right := FPanel.BoundsRect.Right;
  inherited;
end;

end.
