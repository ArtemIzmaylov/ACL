﻿////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   ImageComboBox
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.ImageComboBox;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  // System
  {System.}Classes,
  {System.}Types,
  {System.}Math,
  {System.}SysUtils,
  System.UITypes,
  // ACL
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Forms,
  ACL.UI.ImageList,
  ACL.UI.Insight,
  ACL.UI.Resources;

type
  TACLImageComboBox = class;

  { TACLImageComboBoxItem }

  TACLImageComboBoxItem = class(TCollectionItem)
  strict private
    FData: Pointer;
    FImageIndex: TImageIndex;
    FTag: NativeInt;
    FText: string;

    procedure SetImageIndex(AValue: TImageIndex);
    procedure SetText(const AValue: string);
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    property Data: Pointer read FData write FData;
  published
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property Tag: NativeInt read FTag write FTag default 0;
    property Text: string read FText write SetText;
  end;

  { TACLImageComboBoxItems }

  TACLImageComboBoxItems = class(TCollection)
  strict private
    FComboBox: TACLImageComboBox;

    function GetItem(Index: Integer): TACLImageComboBoxItem;
  protected
    function GetOwner: TPersistent; override;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AComboBox: TACLImageComboBox);
    function Add(const AText: string; AImageIndex: TImageIndex): TACLImageComboBoxItem;
    function FindByData(AData: Pointer; out AItem: TACLImageComboBoxItem): Boolean;
    function FindByText(const AText: string; out AItem: TACLImageComboBoxItem): Boolean;
    // Properties
    property ComboBox: TACLImageComboBox read FComboBox;
    property Items[Index: Integer]: TACLImageComboBoxItem read GetItem; default;
  end;

  { TACLImageComboBox }

  TACLImageComboBox = class(TACLBasicComboBox)
  strict private
    FImages: TCustomImageList;
    FImagesLink: TChangeLink;
    FItems: TACLImageComboBoxItems;

    function GetImageSize: TSize;
    function GetSelectedItem: TACLImageComboBoxItem;
    procedure ImageListChanged(Sender: TObject);
    procedure SetImages(AValue: TCustomImageList);
    procedure SetItems(AValue: TACLImageComboBoxItems);
  protected
    FImageRect: TRect;

    function CanDropDown(X, Y: Integer): Boolean; override;
    function CreateDropDownWindow: TACLPopupWindow; override;
    function GetCount: Integer; override;
    procedure CalculateContent(const R: TRect); override;
    procedure DrawEditorContent(ACanvas: TCanvas); override;
    procedure ItemIndexChanged; override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;

    //# Properties
    property ImageSize: TSize read GetImageSize;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //# Properties
    property ImageRect: TRect read FImageRect;
    property SelectedItem: TACLImageComboBoxItem read GetSelectedItem;
  published
    property Borders;
    property Buttons;
    property ButtonsImages;
    property DropDownListSize;
    property Images: TCustomImageList read FImages write SetImages;
    property Items: TACLImageComboBoxItems read FItems write SetItems;
    property ItemIndex; // after Items
    property ResourceCollection;
    property Style;
    property StyleButton;
    property StyleDropDownList;
    property StyleDropDownListScrollBox;

    property OnChange;
    property OnCustomDrawItem;
    property OnDeleteItemObject;
    property OnDropDown;
    property OnGetDisplayItemGroupName;
    property OnGetDisplayItemName;
    property OnSelect;
  end;

  { TACLImageComboBoxDropDown }

  TACLImageComboBoxDropDown = class(TACLBasicComboBoxDropDown)
  protected
    procedure PopulateListCore(AList: TACLTreeList); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  { TACLImageComboBoxUIInsightAdapter }

  TACLImageComboBoxUIInsightAdapter = class(TACLBasicComboBoxUIInsightAdapter)
  public
    class procedure GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder); override;
  end;

implementation

uses
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

{ TACLImageComboBoxItem }

constructor TACLImageComboBoxItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FImageIndex := -1;
end;

procedure TACLImageComboBoxItem.Assign(Source: TPersistent);
begin
  if Source is TACLImageComboBoxItem then
  begin
    FImageIndex := TACLImageComboBoxItem(Source).ImageIndex;
    FText := TACLImageComboBoxItem(Source).FText;
    FTag := TACLImageComboBoxItem(Source).Tag;
    Changed(False);
  end;
end;

procedure TACLImageComboBoxItem.SetImageIndex(AValue: TImageIndex);
begin
  if AValue <> FImageIndex then
  begin
    FImageIndex := AValue;
    Changed(False);
  end;
end;

procedure TACLImageComboBoxItem.SetText(const AValue: string);
begin
  if AValue <> FText then
  begin
    FText := AValue;
    Changed(False);
  end;
end;

{ TACLImageComboBoxItems }

constructor TACLImageComboBoxItems.Create(AComboBox: TACLImageComboBox);
begin
  FComboBox := AComboBox;
  inherited Create(TACLImageComboBoxItem);
end;

function TACLImageComboBoxItems.FindByData(AData: Pointer; out AItem: TACLImageComboBoxItem): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
    if Items[I].Data = AData then
    begin
      AItem := Items[I];
      Exit(True);
    end;
end;

function TACLImageComboBoxItems.FindByText(const AText: string; out AItem: TACLImageComboBoxItem): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
    if Items[I].Text = AText then
    begin
      AItem := Items[I];
      Exit(True);
    end;
end;

function TACLImageComboBoxItems.Add(const AText: string; AImageIndex: TImageIndex): TACLImageComboBoxItem;
begin
  BeginUpdate;
  try
    Result := TACLImageComboBoxItem(inherited Add);
    Result.ImageIndex := AImageIndex;
    Result.Text := AText;
  finally
    EndUpdate;
  end;
end;

function TACLImageComboBoxItems.GetItem(Index: Integer): TACLImageComboBoxItem;
begin
  Result := TACLImageComboBoxItem(inherited Items[Index]);
end;

function TACLImageComboBoxItems.GetOwner: TPersistent;
begin
  Result := ComboBox;
end;

procedure TACLImageComboBoxItems.Update(Item: TCollectionItem);
begin
  ComboBox.ItemIndex := ComboBox.ItemIndex;
  ComboBox.Changed;
end;

{ TACLImageComboBox }

constructor TACLImageComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FImagesLink := TChangeLink.Create;
  FImagesLink.OnChange := ImageListChanged;
  FItems := TACLImageComboBoxItems.Create(Self);
  FItemIndex := -1;
end;

destructor TACLImageComboBox.Destroy;
begin
  Images := nil;
  FreeAndNil(FImagesLink);
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TACLImageComboBox.CalculateContent(const R: TRect);
begin
  inherited CalculateContent(R);
  FImageRect := FTextRect.Split(srLeft, ImageSize.cx);
  FImageRect.CenterVert(ImageSize.cy);
  FTextRect.Left := ImageRect.Right + IfThen(ImageSize.cx > 0, dpiApply(acTextIndent, FCurrentPPI));
end;

function TACLImageComboBox.CreateDropDownWindow: TACLPopupWindow;
begin
  Result := TACLImageComboBoxDropDown.Create(Self);
end;

procedure TACLImageComboBox.ImageListChanged(Sender: TObject);
begin
  FullRefresh;
end;

procedure TACLImageComboBox.ItemIndexChanged;
begin
  inherited ItemIndexChanged;
  if ItemIndex = -1 then
    Text := ''
  else
    Text := Items[ItemIndex].Text;
end;

procedure TACLImageComboBox.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);
  if (AOperation = opRemove) and (AComponent = Images) then
    Images := nil;
end;

procedure TACLImageComboBox.DrawEditorContent(ACanvas: TCanvas);
begin
  inherited;
  if (Images <> nil) and (ItemIndex >= 0) then
    acDrawImage(ACanvas, ImageRect, Images, Items[ItemIndex].ImageIndex, Enabled);
end;

function TACLImageComboBox.CanDropDown(X, Y: Integer): Boolean;
begin
  Result := inherited CanDropDown(X, Y) or PtInRect(ImageRect, Point(X, Y));
end;

function TACLImageComboBox.GetCount: Integer;
begin
  Result := Items.Count;
end;

function TACLImageComboBox.GetImageSize: TSize;
begin
  Result := acGetImageListSize(Images, FCurrentPPI);
end;

function TACLImageComboBox.GetSelectedItem: TACLImageComboBoxItem;
begin
  if ItemIndex >= 0 then
    Result := Items[ItemIndex]
  else
    Result := nil;
end;

procedure TACLImageComboBox.SetImages(AValue: TCustomImageList);
begin
  acSetImageList(AValue, FImages, FImagesLink, Self);
end;

procedure TACLImageComboBox.SetItems(AValue: TACLImageComboBoxItems);
begin
  FItems.Assign(AValue);
end;

{ TACLImageComboBoxDropDown }

constructor TACLImageComboBoxDropDown.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Control.OptionsView.Nodes.Images := TACLImageComboBox(AOwner).Images;
end;

procedure TACLImageComboBoxDropDown.PopulateListCore(AList: TACLTreeList);
var
  LImages: TACLImageComboBoxItems;
  LItem: TACLImageComboBoxItem;
  I: Integer;
begin
  LImages := TACLImageComboBox(Owner).Items;
  for I := 0 to LImages.Count - 1 do
  begin
    LItem := LImages[I];
    AddItem(AList, LItem.Text).ImageIndex := LItem.ImageIndex;
  end;
end;

{ TACLImageComboBoxUIInsightAdapter }

class procedure TACLImageComboBoxUIInsightAdapter.GetChildren(
  AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
var
  LImageComboBox: TACLImageComboBox absolute AObject;
  I: Integer;
begin
  for I := 0 to LImageComboBox.Count - 1 do
    ABuilder.AddCandidate(LImageComboBox, LImageComboBox.Items[I].Text);
end;

initialization
  TACLUIInsight.Register(TACLImageComboBox, TACLImageComboBoxUIInsightAdapter);
end.
