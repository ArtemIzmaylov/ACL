////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Font Picker Dialog
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Dialogs.FontPicker;

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
  {Vcl.}ExtCtrls,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.FontCache,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.GroupBox,
  ACL.UI.Controls.Panel,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.Options,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Dialogs,
  ACL.UI.Dialogs.ColorPicker,
  ACL.UI.Forms,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type

  { TACLFontPickerDialog }

  TACLFontPickerDialog = class(TACLCustomInputDialog)
  strict private const
    FontSizeValues: array[0..15] of Integer = (8, 9, 10, 11, 12, 14, 16, 18, 20, 22, 24, 26, 28, 36, 48, 72);
  protected const
    FontNameHeight = 260;
    FontNameWidth = 276;
  strict private
    FColorPicker: TACLButton;
    FFontName: TACLTreeList;
    FFontNameEdit: TACLEdit;
    FFontSize: TACLTreeList;
    FFontSizeEdit: TACLEdit;
    FFontStyleGroup: TACLPanel;
    FPreview: TPaintBox;
    FStyleHatch: TACLStyleHatch;

    procedure HandlerColorPickerClick(Sender: TObject);
    procedure HandlerFontModified(Sender: TObject);
    procedure HandlerFontPreview(Sender: TObject; ACanvas: TCanvas;
      var AData: TACLTreeListNodeCustomDrawData; var AHandled: Boolean);
    procedure HandlerFontNameListChanged(Sender: TObject);
    procedure HandlerFontSizeListChanged(Sender: TObject);
    procedure HandlerPreviewPaint(Sender: TObject);
  protected
    FFont: TFont;
    FFontOriginal: TFont;
    FFontSizeSign: Integer;
    FHasBeenApplied: Boolean;

    FOnApply: TProc;

    procedure CreateControls; override;
    function CreateSimpleListView: TACLTreeList;
    procedure DoApply(Sender: TObject); override;
    procedure DoCancel(Sender: TObject); override;
    procedure DrawPreview(ACanvas: TCanvas; const R: TRect);
    procedure DrawPreviewBackground(ACanvas: TCanvas; const R: TRect);
    procedure PlaceControls(var R: TRect); override;
    procedure PopulateFonts;
    procedure PopulateFontSize;
    procedure UpdateColorPickerPreview;

    procedure Initialize(AFont: TFont; AOnApply: TProc = nil);
    procedure LoadFontParams(AFont: TFont);
    procedure SaveFontParams(AFont: TFont);

    property ColorPicker: TACLButton read FColorPicker;
    property FontName: TACLTreeList read FFontName;
    property FontNameEdit: TACLEdit read FFontNameEdit;
    property FontSize: TACLTreeList read FFontSize;
    property FontSizeEdit: TACLEdit read FFontSizeEdit;
    property StyleHatch: TACLStyleHatch read FStyleHatch;
  public
    destructor Destroy; override;
    procedure AfterConstruction; override;
    class function Execute(AFont: TFont; AOwnerWnd: THandle = 0; AOnApply: TProc = nil): Boolean;
  end;

implementation

{ TACLFontPickerDialog }

procedure TACLFontPickerDialog.AfterConstruction;
begin
  inherited;
  FStyleHatch := TACLStyleHatch.Create(Self);
  FFontOriginal := TFont.Create;
  Caption := 'Font';
end;

destructor TACLFontPickerDialog.Destroy;
begin
  FreeAndNil(FStyleHatch);
  FreeAndNil(FFontOriginal);
  inherited;
end;

class function TACLFontPickerDialog.Execute(AFont: TFont; AOwnerWnd: THandle = 0; AOnApply: TProc = nil): Boolean;
begin
  with TACLFontPickerDialog.CreateDialog(AOwnerWnd, True) do
  try
    Initialize(AFont, AOnApply);
    Result := ShowModal = mrOk;
  finally
    Free;
  end;
end;

procedure TACLFontPickerDialog.Initialize(AFont: TFont; AOnApply: TProc = nil);
begin
  FFont := AFont;
  FFontOriginal.Assign(FFont);
  FOnApply := AOnApply;

  CreateControls;
  ButtonApply.Visible := Assigned(FOnApply);
  HandleNeeded;

  LoadFontParams(AFont);
  SetHasChanges(False);
end;

procedure TACLFontPickerDialog.LoadFontParams(AFont: TFont);
var
  AControl: TControl;
  I: Integer;
begin
  FFontSizeSign := Sign(AFont.Size);
  FontSizeEdit.Text := IntToStr(Abs(AFont.Size));
  FontNameEdit.Text := AFont.Name;
  ColorPicker.Tag := TAlphaColor.FromColor(AFont.Color);

  for I := 0 to FFontStyleGroup.ControlCount - 1 do
  begin
    AControl := FFontStyleGroup.Controls[I];
    if AControl is TACLCheckBox then
      TACLCheckBox(AControl).Checked := TFontStyle(AControl.Tag) in AFont.Style;
  end;

  UpdateColorPickerPreview;
end;

procedure TACLFontPickerDialog.SaveFontParams(AFont: TFont);

  function GetFontStyle: TFontStyles;
  var
    AControl: TControl;
    I: Integer;
  begin
    Result := [];
    for I := 0 to FFontStyleGroup.ControlCount - 1 do
    begin
      AControl := FFontStyleGroup.Controls[I];
      if AControl is TACLCheckBox then
      begin
        if TACLCheckBox(AControl).Checked then
          Include(Result, TFontStyle(AControl.Tag));
      end;
    end;
  end;

begin
  AFont.Name := FontNameEdit.Text;
  AFont.Style := GetFontStyle;
  AFont.Size := FFontSizeSign * StrToIntDef(FontSizeEdit.Text, 0);
  AFont.Color := TAlphaColor(FColorPicker.Tag).ToColor;
end;

procedure TACLFontPickerDialog.CreateControls;
const
  CaptionMap: array[TFontStyle] of string = ('B', 'I', 'U', 'S');
var
  ACheckBox: TACLCheckBox;
  AStyle: TFontStyle;
begin
  CreateControl(FFontNameEdit, TACLEdit, Self, NullRect);
  FFontNameEdit.Width := dpiApply(FontNameWidth, FCurrentPPI);
  FFontNameEdit.OnChange := HandlerFontModified;

  FFontName := CreateSimpleListView;
  FFontName.Parent := Self;
  FFontName.OnCustomDrawNodeCell := HandlerFontPreview;
  FFontName.OnSelectionChanged := HandlerFontNameListChanged;
  PopulateFonts;

  CreateControl(FFontSizeEdit, TACLEdit, Self, NullRect);
  FFontSizeEdit.OnChange := HandlerFontModified;
  FFontSizeEdit.Width := dpiApply(ButtonWidth, FCurrentPPI);

  FFontSize := CreateSimpleListView;
  FFontSize.Parent := Self;
  FFontSize.OnSelectionChanged := HandlerFontSizeListChanged;
  PopulateFontSize;

  CreateControl(FFontStyleGroup, TACLPanel, Self, NullRect);
  FFontStyleGroup.Borders := [];

  for AStyle := Low(AStyle) to High(AStyle) do
  begin
    CreateControl(ACheckBox, TACLCheckBox, FFontStyleGroup, Rect(MaxWord, 0, 0, 0), alLeft);
    ACheckBox.AlignWithMargins := True;
    ACheckBox.Caption := CaptionMap[AStyle];
    ACheckBox.Font.Style := ACheckBox.Font.Style + [AStyle];
    ACheckBox.Tag := Ord(AStyle);
    ACheckBox.OnClick := HandlerFontModified;
  end;

  CreateControl(FColorPicker, TACLButton, FFontStyleGroup,
    Rect(0, 0, FontSizeEdit.Width, dpiApply(ButtonHeight, FCurrentPPI)), alRight);
  FColorPicker.OnClick := HandlerColorPickerClick;
  FColorPicker.Margins.Margins := Rect(3, 0, 0, 0);
  FColorPicker.AlignWithMargins := True;

  CreateControl(FPreview, TPaintBox, Self, NullRect);
  FPreview.OnPaint := HandlerPreviewPaint;

  inherited;

  ActiveControl := FontName;
  AutoSize := True;
end;

function TACLFontPickerDialog.CreateSimpleListView: TACLTreeList;
begin
  Result := TACLTreeList.Create(Self);
  Result.Columns.Add;
  Result.OptionsBehavior.IncSearchColumnIndex := 0;
  Result.OptionsView.Columns.AutoWidth := True;
  Result.OptionsView.Columns.Visible := False;
  Result.OptionsView.Nodes.GridLines := [];
  Result.SortBy(Result.Columns.First);
end;

procedure TACLFontPickerDialog.DoApply(Sender: TObject);
begin
  FHasBeenApplied := True;
  SaveFontParams(FFont);
  inherited;
  if Assigned(FOnApply) then FOnApply();
end;

procedure TACLFontPickerDialog.DoCancel(Sender: TObject);
begin
  if Assigned(FOnApply) and FHasBeenApplied then
  begin
    FFont.Assign(FFontOriginal);
    FOnApply();
  end;
  inherited;
end;

procedure TACLFontPickerDialog.DrawPreview(ACanvas: TCanvas; const R: TRect);
begin
  SaveFontParams(ACanvas.Font);
  DrawPreviewBackground(ACanvas, R);
  ACanvas.Brush.Style := bsClear;
  acTextDraw(ACanvas, 'Sample', R, taCenter, taVerticalCenter);
end;

procedure TACLFontPickerDialog.DrawPreviewBackground(ACanvas: TCanvas; const R: TRect);
var
  ABackgroundColor: TColor;
  AForegroundColor: TColor;
begin
  //#StyleHatch.Draw(ACanvas, R, acAllBorders, 5);

  ABackgroundColor := FontNameEdit.Style.ColorsContent[True];
  AForegroundColor := FontNameEdit.Style.ColorsText[True];

  if TACLColors.IsDark(ACanvas.Font.Color) = TACLColors.IsDark(ABackgroundColor) then
    acExchangeIntegers(ABackgroundColor, AForegroundColor);

  acDrawFrame(ACanvas, R, FontNameEdit.Style.ColorBorder.AsColor);
  acFillRect(ACanvas, R.InflateTo(-1, -1), ABackgroundColor);
end;

procedure TACLFontPickerDialog.PlaceControls(var R: TRect);
var
  AIndent: Integer;
begin
  AIndent := dpiApply(6, FCurrentPPI);

  FontNameEdit.BoundsRect := Bounds(R.Left, R.Top, dpiApply(FontNameWidth, FCurrentPPI), FontNameEdit.Height);
  FontSizeEdit.BoundsRect := Bounds(FontNameEdit.BoundsRect.Right + AIndent, R.Top, FontSizeEdit.Width, FontSizeEdit.Height);

  R.Top := FontNameEdit.BoundsRect.Bottom + AIndent;
  FontSize.BoundsRect := Bounds(FontSizeEdit.Left, R.Top, FontSizeEdit.Width, dpiApply(FontNameHeight, FCurrentPPI));
  FontName.BoundsRect := Bounds(FontNameEdit.Left, R.Top, FontNameEdit.Width, dpiApply(FontNameHeight, FCurrentPPI));

  R.Left := FontName.Left;
  R.Right := FontSize.BoundsRect.Right;

  FFontStyleGroup.SetBounds(R.Left, FontName.BoundsRect.Bottom + AIndent, R.Width, dpiApply(ButtonHeight, FCurrentPPI));
  FPreview.SetBounds(R.Left, FFontStyleGroup.BoundsRect.Bottom + AIndent, R.Width, dpiApply(72, FCurrentPPI));

  R.Top := FPreview.BoundsRect.Bottom + AIndent;

  inherited;

  UpdateColorPickerPreview;
end;

procedure TACLFontPickerDialog.PopulateFonts;
begin
  TACLFontCache.EnumFonts(
    procedure (const S: string)
    var
      ANode: TACLTreeListNode;
    begin
      if not acBeginsWith(S, '@', False) then
      begin
        if not FontName.RootNode.Find(ANode, S) then
          FontName.RootNode.AddChild([S]);
      end;
    end);
end;

procedure TACLFontPickerDialog.PopulateFontSize;
var
  I: Integer;
begin
  FontSize.BeginUpdate;
  try
    for I := Low(FontSizeValues) to High(FontSizeValues) do
      FontSize.RootNode.AddChild(IntToStr(FontSizeValues[I]));
  finally
    FontSize.EndUpdate;
  end;
end;

procedure TACLFontPickerDialog.UpdateColorPickerPreview;
var
  ABitmap: TACLDib;
  AFocusRect: TRect;
begin
  if not ColorPicker.SubClass.FocusRect.IsEmpty then
  begin
    AFocusRect := ColorPicker.SubClass.FocusRect;
    AFocusRect.Inflate(-1);
    ABitmap := TACLDib.Create(AFocusRect);
    try
      acFillRect(ABitmap.Canvas, ABitmap.ClientRect, TAlphaColor(ColorPicker.Tag));
      ColorPicker.Glyph.Overriden := True;
      ColorPicker.Glyph.Scalable := TACLBoolean.False;
      ColorPicker.Glyph.Image.LoadFromBitmap(ABitmap);
    finally
      ABitmap.Free;
    end;
  end;
end;

procedure TACLFontPickerDialog.HandlerColorPickerClick(Sender: TObject);
var
  AColor: TAlphaColor;
begin
  AColor := FColorPicker.Tag;
  if TACLColorPickerDialog.Execute(AColor, False, Handle) then
  begin
    FColorPicker.Tag := AColor;
    FPreview.Invalidate;
    UpdateColorPickerPreview;
    DoModified;
  end;
end;

procedure TACLFontPickerDialog.HandlerFontModified(Sender: TObject);
begin
  DoModified;
  FontName.FocusedNode := FontName.RootNode.Find(FontNameEdit.Text);
  FontSize.FocusedNode := FontSize.RootNode.Find(FontSizeEdit.Text);
  FPreview.Invalidate;
end;

procedure TACLFontPickerDialog.HandlerFontNameListChanged(Sender: TObject);
begin
  DoModified;
  if FontName.FocusedNode <> nil then
    FontNameEdit.Text := FontName.FocusedNode.Caption;
end;

procedure TACLFontPickerDialog.HandlerFontPreview(
  Sender: TObject; ACanvas: TCanvas;
  var AData: TACLTreeListNodeCustomDrawData;
  var AHandled: Boolean);
begin
  TACLFontCache.GetInfo(AData.Node.Caption, [],
    ACanvas.Font.Height, acDefaultDPI, fqDefault).AssignTo(ACanvas.Font);
  ACanvas.Font.Color := FFontName.Style.RowColorsText[True];
end;

procedure TACLFontPickerDialog.HandlerFontSizeListChanged(Sender: TObject);
begin
  DoModified;
  if FontSize.FocusedNode <> nil then
    FontSizeEdit.Text := FontSize.FocusedNode.Caption;
end;

procedure TACLFontPickerDialog.HandlerPreviewPaint(Sender: TObject);
begin
  DrawPreview(FPreview.Canvas, FPreview.ClientRect);
end;

end.
