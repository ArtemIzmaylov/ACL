////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Color Picker Dialog
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Dialogs.ColorPicker;

{$I ACL.Config.inc}

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
  ACL.UI.Controls.Base,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ColorPalette,
  ACL.UI.Controls.ColorPicker,
  ACL.UI.Controls.Panel,
  ACL.UI.Dialogs,
  ACL.UI.Resources,
  ACL.Utils.DPIAware,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type

  { TACLColorButton }

  TACLColorButton = class(TACLCustomButton)
  strict private
    FColorAllowEditAlpha: Boolean;
    function GetColor: TAlphaColor;
    procedure SetColor(AValue: TAlphaColor); reintroduce;
  protected
    procedure Click; override;
    function CreateStyle: TACLStyleButton; override;
    function CreateSubClass: TACLSimpleButtonSubClass; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Alignment default taLeftJustify;
    property Color: TAlphaColor read GetColor write SetColor default {TAlphaColor.None}0;
    property ColorAllowEditAlpha: Boolean read FColorAllowEditAlpha write FColorAllowEditAlpha default True;
  end;

  { TACLColorButtonSubClass }

  TACLColorButtonSubClass = class(TACLButtonSubClass)
  strict private
    FColor: TAlphaColor;
    procedure SetColor(AValue: TAlphaColor);
  protected
    procedure CalculateImageRect(var R: TRect); override;
    procedure DrawContent(ACanvas: TCanvas); override;
    function GetHasImage: Boolean; override;
  public
    property Color: TAlphaColor read FColor write SetColor;
  end;

  { TACLColorPickerDialog }

  TACLColorPickerDialog = class(TACLCustomInputDialog)
  strict private
    FPalette: TACLColorPalette;
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
      AOwnerWnd: TWndHandle = 0; const ACaption: string = ''): Boolean; overload;
    class function Execute(var AColor: TAlphaColor;
      AOwnerWnd: TWndHandle = 0; const ACaption: string = ''): Boolean; overload;
    class function Execute(var AColor: TAlphaColor; AAllowEditAlpha: Boolean;
      AOwnerWnd: TWndHandle = 0; const ACaption: string = ''; AOnApply: TProc = nil): Boolean; overload;
    class function ExecuteQuery(AColor: TAlphaColor;
      AOwnerWnd: TWndHandle = 0; const ACaption: string = ''): TAlphaColor; overload;
    class function ExecuteQuery(AColor: TAlphaColor; AAllowEditAlpha: Boolean;
      AOwnerWnd: TWndHandle = 0; const ACaption: string = ''): TAlphaColor; overload;
  end;

implementation

{ TACLColorButton }

constructor TACLColorButton.Create(AOwner: TComponent);
begin
  inherited;
  Alignment := taLeftJustify;
  FColorAllowEditAlpha := True;
end;

procedure TACLColorButton.Click;
var
  LColor: TAlphaColor;
begin
  LColor := Color;
  if TACLColorPickerDialog.Execute(LColor, ColorAllowEditAlpha, Handle, Caption) then
  begin
    Color := LColor;
    inherited;
  end;
end;

function TACLColorButton.CreateStyle: TACLStyleButton;
begin
  Result := TACLStyleButton.Create(Self);
end;

function TACLColorButton.CreateSubClass: TACLSimpleButtonSubClass;
begin
  Result := TACLColorButtonSubClass.Create(Self, Style);
end;

function TACLColorButton.GetColor: TAlphaColor;
begin
  Result := TACLColorButtonSubClass(SubClass).Color;
end;

procedure TACLColorButton.SetColor(AValue: TAlphaColor);
begin
  TACLColorButtonSubClass(SubClass).Color := AValue;
end;

{ TACLColorButtonSubClass }

procedure TACLColorButtonSubClass.CalculateImageRect(var R: TRect);
begin
  FImageRect := R;
  if Caption <> '' then
  begin
    FImageRect.Left := FImageRect.Right - FImageRect.Height;
    R.Right := FImageRect.Left - GetIndentBetweenElements;
  end
  else
    R := NullRect;
end;

procedure TACLColorButtonSubClass.DrawContent(ACanvas: TCanvas);
begin
  inherited;
  acDrawColorPreview(ACanvas, FImageRect, Color);
end;

function TACLColorButtonSubClass.GetHasImage: Boolean;
begin
  Result := True;
end;

procedure TACLColorButtonSubClass.SetColor(AValue: TAlphaColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    Invalidate;
  end;
end;

{ TACLColorPickerDialog }

class function TACLColorPickerDialog.Execute(
  var AColor: TColor; AOwnerWnd: TWndHandle; const ACaption: string): Boolean;
var
  AGpColor: TAlphaColor;
begin
  AGpColor := TAlphaColor.FromColor(AColor);
  Result := Execute(AGpColor, False, AOwnerWnd, ACaption);
  if Result then
    AColor := AGpColor.ToColor;
end;

class function TACLColorPickerDialog.Execute(
  var AColor: TAlphaColor; AOwnerWnd: TWndHandle; const ACaption: string): Boolean;
begin
  Result := Execute(AColor, True, AOwnerWnd, ACaption);
end;

class function TACLColorPickerDialog.Execute(
  var AColor: TAlphaColor; AAllowEditAlpha: Boolean; AOwnerWnd: TWndHandle;
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
  AColor: TAlphaColor; AOwnerWnd: TWndHandle; const ACaption: string): TAlphaColor;
begin
  Result := ExecuteQuery(AColor, True, AOwnerWnd, ACaption);
end;

class function TACLColorPickerDialog.ExecuteQuery(AColor: TAlphaColor;
  AAllowEditAlpha: Boolean; AOwnerWnd: TWndHandle; const ACaption: string): TAlphaColor;
begin
  Result := AColor;
  if not Execute(Result, AAllowEditAlpha, AOwnerWnd, ACaption) then
    Result := AColor;
end;

procedure TACLColorPickerDialog.AfterFormCreate;
begin
  inherited AfterFormCreate;
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
  FPicker := TACLColorPicker.Create(Self);
  FPicker.AutoSize := False;
  FPicker.Borders := [];
  FPicker.Padding.All := 0;
  FPicker.OnColorChanged := ColorChangeHandler;
  FPicker.Parent := Self;

  FPalette := TACLColorPalette.Create(Self);
  FPalette.Parent := Self;
  FPalette.FocusOnClick := True;
  FPalette.OptionsView.CellSize := 24;
  FPalette.OptionsView.CellSpacing := 2;
  FPalette.OptionsView.StyleOfficeTintCount := 4;
  FPalette.OnColorChanged := ColorChangeHandler;

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
var
  D, W, H: Integer;
begin
  D := dpiApply(8, FCurrentPPI);

  H := R.Height; W := R.Width;
  FPicker.CalculateAutoSize(W, H);
  FPicker.SetBounds(R.Left, R.Top, W, H);
  Inc(R.Top, D + H);
  R.Width := W;

  FPalette.CanAutoSize(W, H);
  FPalette.SetBounds(R.Left, R.Top, W, H);
  Inc(R.Top, D + H);

  inherited;
end;

end.
