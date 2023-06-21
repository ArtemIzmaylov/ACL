{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*          Texture Property Editor          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.DesignTime.PropEditors.Texture;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Types,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.ImageList,
  // Vcl
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ImgList,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Images,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.Category,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.DropDown,
  ACL.UI.Controls.GroupBox,
  ACL.UI.Controls.Labels,
  ACL.UI.Controls.Panel,
  ACL.UI.Controls.SpinEdit,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Dialogs,
  ACL.UI.Forms,
  ACL.UI.ImageList,
  ACL.UI.Resources;

type

  { TACLTextureEditorDialog }

  TACLTextureEditorDialog = class(TACLForm)
    btnCancel: TACLButton;
    btnClear: TACLButton;
    btnExport: TACLButton;
    btnImport: TACLButton;
    btnLoad: TACLButton;
    btnOk: TACLButton;
    btnSave: TACLButton;
    cbLayout: TACLComboBox;
    cbOverride: TACLCheckBox;
    cbSource: TACLComboBox;
    cbStretchMode: TACLComboBox;
    gbContentOffsets: TACLGroupBox;
    gbFrames: TACLGroupBox;
    gbMargins: TACLGroupBox;
    ilImages: TACLImageList;
    ImportExportDialog: TACLFileDialog;
    Label1: TACLLabel;
    Label2: TACLLabel;
    pbDisplay: TPaintBox;
    pnlButtons: TACLPanel;
    pnlPreview: TACLPanel;
    pnlSettings: TACLPanel;
    pnlToolbar: TACLPanel;
    pnlToolbarBottom: TACLPanel;
    seContentOffsetBottom: TACLSpinEdit;
    seContentOffsetLeft: TACLSpinEdit;
    seContentOffsetRight: TACLSpinEdit;
    seContentOffsetTop: TACLSpinEdit;
    seFrame: TACLSpinEdit;
    seMarginBottom: TACLSpinEdit;
    seMarginLeft: TACLSpinEdit;
    seMarginRight: TACLSpinEdit;
    seMarginTop: TACLSpinEdit;
    seMax: TACLSpinEdit;
    TextureFileDialog: TACLFileDialog;

    procedure btnClearClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure cbLayoutSelect(Sender: TObject);
    procedure cbSourceButtons0Click(Sender: TObject);
    procedure cbSourceButtons1Click(Sender: TObject);
    procedure cbSourceSelect(Sender: TObject);
    procedure cbStretchModeSelect(Sender: TObject);
    procedure pbDisplayMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pbDisplayMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pbDisplayMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pbDisplayPaint(Sender: TObject);
    procedure seContentOffsetTopChange(Sender: TObject);
    procedure seFrameChange(Sender: TObject);
    procedure seMarginLeftChange(Sender: TObject);
    procedure seMaxChange(Sender: TObject);
  private
    FImageSet: TACLSkinImageSet;
    FLoading: Boolean;
    FResizing: Boolean;
    FResizingLastPoint: TPoint;
    FResizingRect: TRect;

    function CanStartReSize(X, Y: Integer): Boolean;
    procedure InitializeImageSetSettings;
    procedure InitializeImageSettings;
    procedure TextureChanged(Sender: TObject);
    function GetImage: TACLSkinImage;
    //
    property Image: TACLSkinImage read GetImage;
    property ImageSet: TACLSkinImageSet read FImageSet;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class procedure Execute(ATexture: TACLResourceTexture);
  end;

implementation

uses
  System.Math;

{$R *.dfm}

{ TACLTextureEditorDialog }

class procedure TACLTextureEditorDialog.Execute(ATexture: TACLResourceTexture);
begin
  with TACLTextureEditorDialog.Create(nil) do
  try
    ImageSet.Assign(ATexture.ImageSet);
    ImageSet.MakeUnique;
    InitializeImageSetSettings;
    InitializeImageSettings;
    if ShowModal = mrOk then
    begin
      ATexture.Overriden := cbOverride.Checked;
      if ATexture.Overriden then
        ATexture.Assign(ImageSet);
    end;
  finally
    Free;
  end;
end;

constructor TACLTextureEditorDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FImageSet := TACLSkinImageSet.Create(TextureChanged);
end;

destructor TACLTextureEditorDialog.Destroy;
begin
  FreeAndNil(FImageSet);
  inherited Destroy;
end;

procedure TACLTextureEditorDialog.InitializeImageSetSettings;
var
  ASavedItemIndex: Integer;
  I: Integer;
begin
  FLoading := True;
  try
    ASavedItemIndex := cbSource.ItemIndex;
    cbSource.Items.BeginUpdate;
    try
      cbSource.Items.Clear;
      for I := 0 to ImageSet.Count - 1 do
        cbSource.Items.AddObject(ImageSet[I].ToString, ImageSet[I]);
    finally
      cbSource.ItemIndex := Max(0, ASavedItemIndex);
      cbSource.Items.EndUpdate;
    end;
  finally
    FLoading := False;
  end;
end;

procedure TACLTextureEditorDialog.InitializeImageSettings;
begin
  FLoading := True;
  try
    seMax.Value := Image.FrameCount;
    seFrame.Value := 1;

    seMarginBottom.Value := Image.Margins.Bottom;
    seMarginLeft.Value := Image.Margins.Left;
    seMarginRight.Value := Image.Margins.Right;
    seMarginTop.Value := Image.Margins.Top;

    seContentOffsetBottom.Value := Image.ContentOffsets.Bottom;
    seContentOffsetLeft.Value := Image.ContentOffsets.Left;
    seContentOffsetRight.Value := Image.ContentOffsets.Right;
    seContentOffsetTop.Value := Image.ContentOffsets.Top;

    cbLayout.ItemIndex := Ord(Image.Layout);
    cbStretchMode.ItemIndex := Ord(Image.StretchMode);
  finally
    FLoading := False;
  end;
end;

function TACLTextureEditorDialog.GetImage: TACLSkinImage;
begin
  Result := ImageSet.Items[cbSource.ItemIndex];
end;

procedure TACLTextureEditorDialog.btnClearClick(Sender: TObject);
begin
  Image.Clear;
  InitializeImageSettings;
end;

procedure TACLTextureEditorDialog.btnExportClick(Sender: TObject);
begin
  if ImportExportDialog.Execute(True, Handle) then
    ImageSet.SaveToFile(ImportExportDialog.FileName);
end;

procedure TACLTextureEditorDialog.btnImportClick(Sender: TObject);
begin
  if ImportExportDialog.Execute(False, Handle) then
  begin
    ImageSet.LoadFromFile(ImportExportDialog.FileName);
    InitializeImageSetSettings;
    InitializeImageSettings;
  end;
end;

procedure TACLTextureEditorDialog.btnLoadClick(Sender: TObject);
begin
  if TextureFileDialog.Execute(False, Handle) then
  begin
    Image.LoadFromFile(TextureFileDialog.FileName);
    if Image.Width > Image.Height then
      Image.Layout := ilHorizontal
    else
      Image.Layout := ilVertical;

    InitializeImageSetSettings;
    InitializeImageSettings;
  end;
end;

procedure TACLTextureEditorDialog.btnSaveClick(Sender: TObject);
begin
  if TextureFileDialog.Execute(True, Handle) then
    Image.SaveToFile(TextureFileDialog.FileName, TACLImageFormatPNG);
end;

function TACLTextureEditorDialog.CanStartReSize(X, Y: Integer): Boolean;
var
  R: TRect;
begin
  R := acRectSetLeft(Image.FrameRect[0], 6);
  R := acRectSetTop(R, 6);
  Result := PtInRect(R, Point(X, Y));
end;

procedure TACLTextureEditorDialog.cbLayoutSelect(Sender: TObject);
begin
  Image.Layout := TACLSkinImageLayout(cbLayout.ItemIndex);
end;

procedure TACLTextureEditorDialog.cbSourceButtons0Click(Sender: TObject);
var
  AValue: string;
begin
  if InputQuery(Caption, 'Enter the DPI:', AValue) then
  begin
    ImageSet.Add(StrToInt(AValue));
    InitializeImageSetSettings;
    InitializeImageSettings;
    cbSource.ChangeItemIndex(cbSource.Count - 1);
  end;
end;

procedure TACLTextureEditorDialog.cbSourceButtons1Click(Sender: TObject);
begin
  ImageSet.Delete(cbSource.ItemIndex);
  InitializeImageSetSettings;
  InitializeImageSettings;
end;

procedure TACLTextureEditorDialog.cbSourceSelect(Sender: TObject);
begin
  InitializeImageSettings;
  pbDisplay.Invalidate;
end;

procedure TACLTextureEditorDialog.cbStretchModeSelect(Sender: TObject);
begin
  Image.StretchMode := TACLStretchMode(cbStretchMode.ItemIndex);
end;

procedure TACLTextureEditorDialog.pbDisplayMouseDown(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FResizing := CanStartReSize(X, Y);
  FResizingRect := Image.ClientRect;
  FResizingLastPoint := Point(X, Y);
end;

procedure TACLTextureEditorDialog.pbDisplayMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if FResizing then
  begin
    FResizingRect.Right  := Image.FrameWidth  + X - FResizingLastPoint.X;
    FResizingRect.Bottom := Image.FrameHeight + Y - FResizingLastPoint.Y;
    pbDisplay.Invalidate;
  end
  else
    if CanStartReSize(X, Y) then
      pbDisplay.Cursor := crSizeNWSE
    else
      pbDisplay.Cursor := crDefault;
end;

procedure TACLTextureEditorDialog.pbDisplayMouseUp(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FResizing := False;
  pbDisplay.Invalidate;
end;

procedure TACLTextureEditorDialog.pbDisplayPaint(Sender: TObject);
var
  R: TRect;
begin
  if FResizing then
    R := FResizingRect
  else
    R := acRectSetSize(pbDisplay.ClientRect, Image.FrameSize);

  Image.Draw(pbDisplay.Canvas.Handle, R, seFrame.Value - 1);
  if not (FResizing or acMarginIsEmpty(Image.Margins)) then
  begin
    acFillRect(pbDisplay.Canvas.Handle, acRectSetLeft(R, Image.Margins.Left, 1), clRed);
    acFillRect(pbDisplay.Canvas.Handle, acRectSetTop(R, Image.Margins.Top, 1), clRed);
    acFillRect(pbDisplay.Canvas.Handle, acRectSetRight(R, R.Right - Image.Margins.Right, 1), clRed);
    acFillRect(pbDisplay.Canvas.Handle, acRectSetBottom(R, R.Bottom - Image.Margins.Bottom, 1), clRed);
  end;
end;

procedure TACLTextureEditorDialog.seContentOffsetTopChange(Sender: TObject);
begin
  if not FLoading then
    Image.ContentOffsets := Rect(
      seContentOffsetLeft.Value, seContentOffsetTop.Value,
      seContentOffsetRight.Value, seContentOffsetBottom.Value);
end;

procedure TACLTextureEditorDialog.seFrameChange(Sender: TObject);
begin
  pbDisplay.Invalidate;
end;

procedure TACLTextureEditorDialog.seMarginLeftChange(Sender: TObject);
begin
  if not FLoading then
  begin
    Image.Margins := Rect(seMarginLeft.Value, seMarginTop.Value, seMarginRight.Value, seMarginBottom.Value);
    pbDisplay.Invalidate;
  end;
end;

procedure TACLTextureEditorDialog.seMaxChange(Sender: TObject);
begin
  seFrame.OptionsValue.MaxValue := seMax.Value;
  Image.FrameCount := seMax.Value;
end;

procedure TACLTextureEditorDialog.TextureChanged(Sender: TObject);
begin
  pbDisplay.Invalidate;
end;

end.
