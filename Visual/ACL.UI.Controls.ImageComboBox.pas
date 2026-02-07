////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   ImageComboBox
//
//  Author:    Artem Izmaylov
//             © 2006-2026
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
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.MUI,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Forms,
  ACL.UI.ImageList,
  ACL.UI.Insight.Core,
  ACL.UI.Resources;

type
  TACLBasicImageComboBox = class;

  { TACLImageComboBoxItem }

  TACLImageComboBoxItemClass = class of TACLImageComboBoxItem;
  TACLImageComboBoxItem = class(TACLCollectionItem)
  strict private
    FData: Pointer;
    FImageIndex: TImageIndex;
    FTag: NativeInt;
    FText: string;

    procedure SetImageIndex(AValue: TImageIndex);
    procedure SetText(const AValue: string);
  protected
    procedure AssignCore(Source: TPersistent); virtual;
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

  TACLImageComboBoxItems = class(TACLCollection)
  strict private
    FComboBox: TACLBasicImageComboBox;
    function GetItem(Index: Integer): TACLImageComboBoxItem;
  protected
    function GetClass: TACLImageComboBoxItemClass; virtual;
    function GetOwner: TPersistent; override;
    procedure UpdateCore(Item: TCollectionItem); override;
  public
    constructor Create(AComboBox: TACLBasicImageComboBox);
    function Add(const AText: string; AImageIndex: TImageIndex): TACLImageComboBoxItem;
    function FindByData(AData: Pointer; out AItem{: TACLImageComboBoxItem}): Boolean;
    function FindByTag(const ATag: NativeInt; out AItem{: TACLImageComboBoxItem}): Boolean;
    function FindByText(const AText: string; out AItem{: TACLImageComboBoxItem}): Boolean;
    // Properties
    property ComboBox: TACLBasicImageComboBox read FComboBox;
    property Items[Index: Integer]: TACLImageComboBoxItem read GetItem; default;
  end;

  { TACLBasicImageComboBox }

  TACLBasicImageComboBox = class(TACLBasicComboBox)
  strict private
    FImages: TCustomImageList;
    FImagesLink: TChangeLink;

    procedure SetImages(AValue: TCustomImageList);
  protected
    FItems: TACLImageComboBoxItems;

    procedure DoPrepareDropDownList(AList: TACLBasicDropDownList); override;
    function GetCount: Integer; override;
    procedure HandlerImageList(Sender: TObject); virtual;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Borders;
    property Buttons;
    property ButtonsImages;
    property DropDownListSize;
    property Images: TCustomImageList read FImages write SetImages;
    property ResourceCollection;
    property Style;
    property StyleButton;
    property StyleDropDownList;
    property StyleDropDownListScrollBox;
    //# Events
    property OnChange;
    property OnCustomDrawItem;
    property OnDeleteItemObject;
    property OnDropDown;
    property OnGetDisplayItemGroupName;
    property OnGetDisplayItemName;
    property OnGetDisplayText;
    property OnSelect;
  end;

  { TACLBasicImageComboBoxUIInsightAdapter }

  TACLBasicImageComboBoxUIInsightAdapter = class(TACLBasicComboBoxUIInsightAdapter)
  public
    class procedure GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder); override;
  end;

  { TACLImageComboBox }

  TACLImageComboBox = class(TACLBasicImageComboBox)
  strict private
    function GetImageSize: TSize;
    function GetSelectedItem: TACLImageComboBoxItem;
    procedure SetItems(AValue: TACLImageComboBoxItems);
  protected
    FImageRect: TRect;
    procedure CalculateContent(ARect: TRect); override;
    procedure ItemIndexChanged; override;
    procedure PaintCore; override;
    //# Properties
    property ImageSize: TSize read GetImageSize;
  public
    constructor Create(AOwner: TComponent); override;
    //# Properties
    property ImageRect: TRect read FImageRect;
    property SelectedItem: TACLImageComboBoxItem read GetSelectedItem;
  published
    property Items: TACLImageComboBoxItems read FItems write SetItems;
    property ItemIndex; // after Items
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
  if (Source <> nil) and Source.InheritsFrom(TACLImageComboBoxItems(Collection).GetClass) then
  begin
    AssignCore(Source);
    Changed(False);
  end;
end;

procedure TACLImageComboBoxItem.AssignCore(Source: TPersistent);
begin
  FImageIndex := TACLImageComboBoxItem(Source).ImageIndex;
  FText := TACLImageComboBoxItem(Source).FText;
  FTag := TACLImageComboBoxItem(Source).Tag;
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

constructor TACLImageComboBoxItems.Create(AComboBox: TACLBasicImageComboBox);
begin
  FComboBox := AComboBox;
  inherited Create(GetClass);
end;

function TACLImageComboBoxItems.FindByData(AData: Pointer; out AItem): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
    if Items[I].Data = AData then
    begin
      TObject(AItem) := Items[I];
      Exit(True);
    end;
end;

function TACLImageComboBoxItems.FindByTag(const ATag: NativeInt; out AItem): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
    if Items[I].Tag = ATag then
    begin
      TObject(AItem) := Items[I];
      Exit(True);
    end;
end;

function TACLImageComboBoxItems.FindByText(const AText: string; out AItem): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
    if Items[I].Text = AText then
    begin
      TObject(AItem) := Items[I];
      Exit(True);
    end;
end;

function TACLImageComboBoxItems.Add(
  const AText: string; AImageIndex: TImageIndex): TACLImageComboBoxItem;
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

function TACLImageComboBoxItems.GetClass: TACLImageComboBoxItemClass;
begin
  Result := TACLImageComboBoxItem;
end;

function TACLImageComboBoxItems.GetItem(Index: Integer): TACLImageComboBoxItem;
begin
  Result := TACLImageComboBoxItem(inherited Items[Index]);
end;

function TACLImageComboBoxItems.GetOwner: TPersistent;
begin
  Result := ComboBox;
end;

procedure TACLImageComboBoxItems.UpdateCore(Item: TCollectionItem);
begin
  ComboBox.ItemIndex := ComboBox.ItemIndex;
  ComboBox.Changed;
end;

{ TACLBasicImageComboBox }

constructor TACLBasicImageComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FImagesLink := TChangeLink.Create;
  FImagesLink.OnChange := HandlerImageList;
  FItemIndex := -1;
end;

destructor TACLBasicImageComboBox.Destroy;
begin
  Images := nil;
  FreeAndNil(FImagesLink);
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TACLBasicImageComboBox.DoPrepareDropDownList(AList: TACLBasicDropDownList);
var
  LIndex: Integer;
  LItem: TACLImageComboBoxItem;
begin
  AList.OptionsView.Nodes.Images := Images;
  for LIndex := 0 to FItems.Count - 1 do
  begin
    LItem := FItems[LIndex];
    AList.Add(DoGetItemDisplayName(LIndex, LItem.Text)).ImageIndex := LItem.ImageIndex;
  end;
  inherited;
end;

procedure TACLBasicImageComboBox.HandlerImageList(Sender: TObject);
begin
  FullRefresh;
end;

procedure TACLBasicImageComboBox.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);
  if (AOperation = opRemove) and (AComponent = Images) then
    Images := nil;
end;

function TACLBasicImageComboBox.GetCount: Integer;
begin
  Result := FItems.Count;
end;

procedure TACLBasicImageComboBox.SetImages(AValue: TCustomImageList);
begin
  acSetImageList(AValue, FImages, FImagesLink, Self);
end;

{ TACLBasicImageComboBoxUIInsightAdapter }

class procedure TACLBasicImageComboBoxUIInsightAdapter.GetChildren(
  AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
var
  LImageComboBox: TACLBasicImageComboBox absolute AObject;
  I: Integer;
begin
  for I := 0 to LImageComboBox.Count - 1 do
    ABuilder.AddCandidate(LImageComboBox, LImageComboBox.FItems[I].Text);
end;

{ TACLImageComboBox }

constructor TACLImageComboBox.Create(AOwner: TComponent);
begin
  inherited;
  FItems := TACLImageComboBoxItems.Create(Self);
end;

procedure TACLImageComboBox.CalculateContent(ARect: TRect);
begin
  FImageRect := NullRect;
  if not ImageSize.IsEmpty then
  begin
    // ref.to: TACLTreeListNodeViewInfo.CalculateImageRect
    FImageRect := ARect.Split(srLeft, ImageSize.cx);
    FImageRect.Offset(dpiApply(StyleDropDownList.RowContentOffsets.Left, FCurrentPPI), 0);
    FImageRect.CenterVert(ImageSize.cy);
    ARect.Left := ImageRect.Right + dpiApply(acIndentBetweenElements, FCurrentPPI) - TextPadding.Left;
  end;
  inherited;
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

procedure TACLImageComboBox.ItemIndexChanged;
begin
  inherited;
  if ItemIndex = -1 then
    Text := ''
  else
    Text := Items[ItemIndex].Text;
end;

procedure TACLImageComboBox.PaintCore;
begin
  inherited;
  if (Images <> nil) and (ItemIndex >= 0) then
    acDrawImage(Canvas, ImageRect, Images, Items[ItemIndex].ImageIndex, Enabled);
end;

procedure TACLImageComboBox.SetItems(AValue: TACLImageComboBoxItems);
begin
  FItems.Assign(AValue);
end;

initialization
  TACLUIInsight.Register(TACLBasicImageComboBox, TACLBasicImageComboBoxUIInsightAdapter);
end.
