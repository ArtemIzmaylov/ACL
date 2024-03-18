{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*         ImageList Property Editor         *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.DesignTime.PropEditors.ImageList;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.Messages,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Generics.Defaults,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  {System.}Variants,
  // VCL
  {Vcl.}ActnList,
  {Vcl.}ComCtrls,
  {Vcl.}Controls,
  {Vcl.}Dialogs,
  {Vcl.}ExtCtrls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}Menus,
  // ACL
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Images,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.GroupBox,
  ACL.UI.Controls.Panel,
  ACL.UI.Dialogs,
  ACL.UI.Forms,
  ACL.UI.ImageList,
  ACL.Utils.FileSystem;

type

  { TfrmImageListEditor }

  TfrmImageListEditor = class(TACLForm)
    acAdd: TAction;
    acDelete: TAction;
    acDeleteAll: TAction;
    acExportAsBMP: TAction;
    acExportAsPNG: TAction;
    acReplace: TAction;
    alActions: TActionList;
    btnAdd: TACLButton;
    btnCancel: TACLButton;
    btnDelete: TACLButton;
    btnDeleteAll: TACLButton;
    btnOK: TACLButton;
    btnReplace: TACLButton;
    btnSave: TACLButton;
    EditingImageList: TACLImageList;
    FileDialog: TACLFileDialog;
    gbImages: TACLGroupBox;
    gbPreview: TACLGroupBox;
    ilImages: TACLImageList;
    lvImages: TListView;
    miAdd: TMenuItem;
    miDelete: TMenuItem;
    miExportAsBMP: TMenuItem;
    miExportasBMP2: TMenuItem;
    miExportAsPNG: TMenuItem;
    miExportasPNG2: TMenuItem;
    miLine1: TMenuItem;
    miLine2: TMenuItem;
    miReplace: TMenuItem;
    pbPreview: TPaintBox;
    pmExport: TPopupMenu;
    pmImages: TPopupMenu;
    pnlBottom: TACLPanel;
    pnlRight: TACLPanel;
    pnlToolbar: TACLPanel;

    procedure acAddExecute(Sender: TObject);
    procedure acDeleteAllExecute(Sender: TObject);
    procedure acDeleteAllUpdate(Sender: TObject);
    procedure acDeleteExecute(Sender: TObject);
    procedure acDeleteUpdate(Sender: TObject);
    procedure acExportAsExecute(Sender: TObject);
    procedure acExportAsUpdate(Sender: TObject);
    procedure acReplaceExecute(Sender: TObject);
    procedure acReplaceUpdate(Sender: TObject);
    procedure EditingImageListChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lvImagesSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure pbPreviewPaint(Sender: TObject);
  strict private
    function GetSelectedItem: TListItem;
    function GetSelection: TACLList<Integer>;
    procedure SetSelection(AValue: TACLList<Integer>);
  protected
    function Export(AIndexes: TACLList<Integer>): TACLBitmap;
    function ExportSelected: TACLBitmap;
    function LoadImage(const AFileName: string): TACLBitmap;
    procedure PopulateImages;
    procedure Replace;
    procedure SaveAs(AAsPNG: Boolean);
    //# Properties
    property SelectedItem: TListItem read GetSelectedItem;
  public
    class function Execute(AOwnerWndHandle: THandle; AImageList: TCustomImageList): Boolean;
  end;

implementation

{$R *.dfm}

{ TfrmImageListEditor }

class function TfrmImageListEditor.Execute(
  AOwnerWndHandle: THandle; AImageList: TCustomImageList): Boolean;
begin
  with TfrmImageListEditor.CreateDialog(AOwnerWndHandle) do
  try
    EditingImageList.Assign(AImageList);
    PopulateImages;
    Result := ShowModal = mrOk;
    if Result then
    begin
      AImageList.Assign(EditingImageList);
      acDesignerSetModified(AImageList);
    end;
  finally
    Free;
  end;
end;

function TfrmImageListEditor.GetSelectedItem: TListItem;
begin
  if (lvImages.ItemFocused <> nil) and lvImages.ItemFocused.Selected then
    Result := lvImages.ItemFocused
  else
    Result := lvImages.Selected;
end;

function TfrmImageListEditor.GetSelection: TACLList<Integer>;
var
  I: Integer;
begin
  Result := TACLList<Integer>.Create;
  Result.Capacity := lvImages.SelCount;
  for I := 0 to lvImages.Items.Count - 1 do
  begin
    if lvImages.Items[I].Selected then
      Result.Add(I);
  end;
end;

procedure TfrmImageListEditor.SetSelection(AValue: TACLList<Integer>);
var
  I: Integer;
begin
  lvImages.ClearSelection;
  for I := 0 to AValue.Count - 1 do
    lvImages.Items[AValue[I]].Selected := True;
end;

function TfrmImageListEditor.Export(AIndexes: TACLList<Integer>): TACLBitmap;
var
  I: Integer;
begin
  Result := TACLBitmap.CreateEx(
    EditingImageList.Width * AIndexes.Count,
    EditingImageList.Height, pf32bit, True);
  if AIndexes.Count > 0 then
  begin
    Result.Canvas.Lock;
    try
      for I := 0 to AIndexes.Count - 1 do
        EditingImageList.Draw(Result.Canvas, I * EditingImageList.Width, 0, AIndexes[I]);
    finally
      Result.Canvas.Unlock;
    end;
  end;
end;

function TfrmImageListEditor.ExportSelected: TACLBitmap;
var
  AIndexes: TACLList<Integer>;
  AHasSelection: Boolean;
  I: Integer;
begin
  AIndexes := TACLList<Integer>.Create;
  try
    AIndexes.Capacity := lvImages.Items.Count;
    AHasSelection := SelectedItem <> nil;
    for I := 0 to lvImages.Items.Count - 1 do
    begin
      if not AHasSelection or lvImages.Items[I].Selected then
        AIndexes.Add(I);
    end;
    Result := Export(AIndexes);
  finally
    AIndexes.Free;
  end;
end;

function TfrmImageListEditor.LoadImage(const AFileName: string): TACLBitmap;
begin
  if acIsOurFile('*.bmp;', AFileName) then
  begin
    Result := TACLBitmap.Create;
    Result.LoadFromFile(AFileName);
    if not acIs32BitBitmap(Result) then
      Result.MakeTransparent(clFuchsia);
  end
  else
    with TACLImage.Create(AFileName) do
    try
      Result := ToBitmap;
    finally
      Free;
    end;
end;

procedure TfrmImageListEditor.PopulateImages;
var
  AItem: TListItem;
  I: Integer;
begin
  lvImages.Items.BeginUpdate;
  try
    lvImages.Clear;
    for I := 0 to EditingImageList.Count - 1 do
    begin
      AItem := lvImages.Items.Add;
      AItem.Caption := IntToStr(I);
      AItem.ImageIndex := I;
    end;
  finally
    lvImages.Items.EndUpdate;
  end;
end;

procedure TfrmImageListEditor.Replace;

  function ReplacePicture(AIndex: Integer; ABitmap: TACLBitmap): Integer; overload;
  var
    APrevCount: Integer;
  begin
    APrevCount := EditingImageList.Count;
    if AIndex >= 0 then
      EditingImageList.ReplaceBitmap(AIndex, ABitmap)
    else
      EditingImageList.AddBitmap(ABitmap);

    Result := EditingImageList.Count - APrevCount;
  end;

  function ReplacePicture(AIndex: Integer; const AFileName: string): Integer; overload;
  var
    ABitmap: TACLBitmap;
  begin
    ABitmap := LoadImage(AFileName);
    try
      Result := ReplacePicture(AIndex, ABitmap);
    finally
      ABitmap.Free;
    end;
  end;

var
  AFileIndex: Integer;
  AIndexesToReplace: TACLList<Integer>;
  AIndexesToSelect: TACLList<Integer>;
  AIndexToReplace: Integer;
  ASelectedCount: Integer;
begin
  FileDialog.Filter := 'All supported Images|*.bmp;*.png;*.jpg;';
  if FileDialog.Execute(False, Handle) then
  begin
    AIndexesToReplace := GetSelection;
    AIndexesToSelect := TACLList<Integer>.Create;
    try
      AIndexesToSelect.Capacity := lvImages.SelCount;

      for AFileIndex := 0 to FileDialog.Files.Count - 1 do
      begin
        if AIndexesToReplace.Count > 0 then
        begin
          AIndexToReplace := AIndexesToReplace.First;
          AIndexesToReplace.Delete(0);
          ASelectedCount := ReplacePicture(AIndexToReplace, FileDialog.Files[AFileIndex]);
        end
        else
        begin
          AIndexToReplace := EditingImageList.Count;
          ASelectedCount := ReplacePicture(-1, FileDialog.Files[AFileIndex]);
        end;

        while ASelectedCount > 0 do
        begin
          AIndexesToSelect.Add(AIndexToReplace);
          Inc(AIndexToReplace);
          Dec(ASelectedCount);
        end;
      end;

      PopulateImages;
      SetSelection(AIndexesToSelect);
    finally
      AIndexesToSelect.Free;
      AIndexesToReplace.Free;
    end;
  end;
end;

procedure TfrmImageListEditor.SaveAs(AAsPNG: Boolean);
const
  FilterMap: array [Boolean] of string = (
    'Bitmaps (*.bmp)|*.bmp;',
    'Portable Network Graphics (*.png)|*.png;'
  );
var
  ABitmap: TACLBitmap;
begin
  FileDialog.Filter := FilterMap[AAsPng];
  if FileDialog.Execute(True, Handle) then
  begin
    ABitmap := ExportSelected;
    try
      if AAsPNG then
      begin
        with TACLImage.Create(ABitmap) do
        try
          SaveToFile(FileDialog.FileName, TACLImageFormatPNG);
        finally
          Free;
        end;
      end
      else
        ABitmap.SaveToFile(FileDialog.FileName);
    finally
      ABitmap.Free;
    end;
  end;
end;

procedure TfrmImageListEditor.acAddExecute(Sender: TObject);
begin
  lvImages.ClearSelection;
  Replace;
end;

procedure TfrmImageListEditor.acDeleteAllExecute(Sender: TObject);
begin
  EditingImageList.Clear;
  lvImages.Clear;
end;

procedure TfrmImageListEditor.acDeleteAllUpdate(Sender: TObject);
begin
  acDeleteAll.Enabled := lvImages.Items.Count > 0;
end;

procedure TfrmImageListEditor.acDeleteExecute(Sender: TObject);
var
  AItem: TListItem;
  ASavedIndex: Integer;
  I: Integer;
begin
  lvImages.Items.BeginUpdate;
  try
    ASavedIndex := SelectedItem.Index;

    for I := lvImages.Items.Count - 1 downto 0 do
    begin
      AItem := lvImages.Items[I];
      if AItem.Selected then
        EditingImageList.Delete(AItem.ImageIndex);
    end;
    PopulateImages;

    ASavedIndex := Min(ASavedIndex, lvImages.Items.Count - 1);
    if ASavedIndex >= 0 then
      lvImages.Selected := lvImages.Items[ASavedIndex];
  finally
    lvImages.Items.EndUpdate;
  end;
end;

procedure TfrmImageListEditor.acDeleteUpdate(Sender: TObject);
begin
  acDelete.Enabled := SelectedItem <> nil;
end;

procedure TfrmImageListEditor.acExportAsExecute(Sender: TObject);
begin
  SaveAs(TAction(Sender).Tag <> 0);
end;

procedure TfrmImageListEditor.acExportAsUpdate(Sender: TObject);
begin
  acExportAsBMP.Enabled := lvImages.Items.Count > 0;
  acExportAsPNG.Enabled := lvImages.Items.Count > 0;
end;

procedure TfrmImageListEditor.acReplaceExecute(Sender: TObject);
begin
  Replace;
end;

procedure TfrmImageListEditor.acReplaceUpdate(Sender: TObject);
begin
  acReplace.Enabled := SelectedItem <> nil;
end;

procedure TfrmImageListEditor.FormCreate(Sender: TObject);
begin
{$IFDEF FPC}
  lvImages.ViewStyle := vsIcon;
{$ELSE}
//  ToolBar.GradientStartColor := gbPreview.Style.ColorContent1.AsColor;
//  ToolBar.GradientEndColor := gbPreview.Style.ColorContent2.AsColor;
//  ToolBar.DrawingStyle := TTBDrawingStyle.dsGradient;
{$ENDIF}
end;

procedure TfrmImageListEditor.lvImagesSelectItem(
  Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  pbPreview.Invalidate;
end;

procedure TfrmImageListEditor.pbPreviewPaint(Sender: TObject);
var
  LImageIndex: Integer;
begin
  if SelectedItem <> nil then
    LImageIndex := SelectedItem.ImageIndex
  else
    LImageIndex := -1;

  acDrawHatch(pbPreview.Canvas.Handle, pbPreview.ClientRect);
  acDrawImage(pbPreview.Canvas, acFitRect(pbPreview.ClientRect,
    EditingImageList.Width, EditingImageList.Height, afmProportionalStretch),
    EditingImageList, LImageIndex, True, False);
  acDrawFrame(pbPreview.Canvas, pbPreview.ClientRect, clWindowFrame);
end;

procedure TfrmImageListEditor.EditingImageListChange(Sender: TObject);
begin
  pbPreview.Invalidate;
end;

end.
