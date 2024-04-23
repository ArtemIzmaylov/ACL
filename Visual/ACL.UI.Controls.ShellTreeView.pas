{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             TreeList Control              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.ShellTreeView;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.ShellApi,
  Winapi.ShlObj,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}SysUtils,
  System.AnsiStrings,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Images,
  ACL.UI.Application,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.Options,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.Utils.Common,
  ACL.Utils.Shell,
  ACL.Utils.Strings;

type

  { TACLShellImageList }

  TACLShellImageList = class(TCustomImageList)
  strict private
    FCache: TACLDictionary<string, Integer>;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetImageIndex(AFolder: TACLShellFolder): Integer;
  end;

  { TACLShellTreeViewCustomOptions }

  TACLShellTreeViewCustomOptions = class(TACLCustomOptionsPersistent)
  protected
    FSource: TACLTreeListCustomOptions;
    procedure DoAssign(Source: TPersistent); override;
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
  public
    constructor Create(ASource: TACLTreeListCustomOptions);
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
  end;

  { TACLShellTreeViewOptionsBehavior }

  TACLShellTreeViewOptionsBehavior = class(TACLShellTreeViewCustomOptions)
  strict private
    FAllowLibraryPaths: Boolean;
    FSystemMenu: Boolean;

    function GetAutoCheckChildren: Boolean;
    function GetAutoCheckParents: Boolean;
    procedure SetAutoCheckChildren(const Value: Boolean);
    procedure SetAutoCheckParents(const Value: Boolean);
  protected
    procedure DoAssign(Source: TPersistent); override;
  published
    property AllowLibraryPaths: Boolean read FAllowLibraryPaths write FAllowLibraryPaths default False;
    property AutoCheckChildren: Boolean read GetAutoCheckChildren write SetAutoCheckChildren default False;
    property AutoCheckParents: Boolean read GetAutoCheckParents write SetAutoCheckParents default False;
    property SystemMenu: Boolean read FSystemMenu write FSystemMenu default False;
  end;

  { TACLShellTreeViewOptionsView }

  TACLShellTreeViewOptionsView = class(TACLShellTreeViewCustomOptions)
  strict private
    FShowFavorites: Boolean;
    FShowHidden: TACLBoolean;

    function GetBorders: TACLBorders;
    function GetCheckBoxes: Boolean;
    procedure SetBorders(AValue: TACLBorders);
    procedure SetCheckBoxes(AValue: Boolean);
    procedure SetShowFavorites(AValue: Boolean);
    procedure SetShowHidden(AValue: TACLBoolean);
  protected
    procedure DoAssign(Source: TPersistent); override;
  public
    procedure AfterConstruction; override;
  published
    property Borders: TACLBorders read GetBorders write SetBorders default acAllBorders;
    property CheckBoxes: Boolean read GetCheckBoxes write SetCheckBoxes default False;
    property ShowFavorites: Boolean read FShowFavorites write SetShowFavorites default False;
    property ShowHidden: TACLBoolean read FShowHidden write SetShowHidden default TACLBoolean.Default;
  end;

  { TACLShellTreeViewSubClass }

  TACLShellTreeViewSubClass = class(TACLTreeListSubClass)
  strict private const
    DefaultQuickAccessNodeState = True;
  strict private
    FImages: TACLShellImageList;
    FOptionsBehavior: TACLShellTreeViewOptionsBehavior;
    FOptionsView: TACLShellTreeViewOptionsView;
    FQuickAccessNode: TACLTreeListNode;
    FQuickAccessNodeState: Boolean;
    FSelectedPath: string;

    function AddNode(AFolder: TACLShellFolder; AParent: TACLTreeListNode): TACLTreeListNode;
    function GetQuickAccessNodeState: Boolean;
    procedure SetOptionsBehavior(AValue: TACLShellTreeViewOptionsBehavior);
    procedure SetOptionsView(AValue: TACLShellTreeViewOptionsView);
    procedure SetQuickAccessNodeState(AValue: Boolean);
    procedure SetSelectedPath(AValue: string);
    class function SortFolderNames(L, R: TACLTreeListNode): Integer; static;
  protected
    function CreateOptionsBehavior: TACLShellTreeViewOptionsBehavior; reintroduce; virtual;
    function CreateOptionsView: TACLShellTreeViewOptionsView; reintroduce; virtual;

    procedure DoCreateDirectory(const AFolder: string);
    procedure DoFocusedNodeChanged; override;
    procedure DoGetNodeChildren(ANode: TACLTreeListNode); override; final;
    procedure DoGetPathChildren(ANode: TACLTreeListNode); virtual;
    procedure DoGetRootChildren(ANode: TACLTreeListNode); virtual;

    procedure InvokeSystemMenu(AOwnerWindow: HWND; ANode: TACLTreeListNode);
    procedure NodeRemoving(ANode: TACLTreeListNode); override;
    procedure ProcessContextPopup(var AHandled: Boolean); override;
    procedure ProcessKeyDown(var AKey: Word; AShift: TShiftState); override;

    function FindNodeByPIDL(AAbsoluteID: PItemIDList; ANode: TACLTreeListNode): TACLTreeListNode;
    procedure SelectPathByPIDL(PIDL: PItemIDList);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ConfigLoad(AConfig: TACLIniFile; const ASection, AItem: string); override;
    procedure ConfigSave(AConfig: TACLIniFile; const ASection, AItem: string); override;
    procedure CreateDirectory(AFolder: string = '');
    function GetFullPath(ANode: TACLTreeListNode): string;
    //# Properties
    property OptionsBehavior: TACLShellTreeViewOptionsBehavior read FOptionsBehavior write SetOptionsBehavior;
    property OptionsView: TACLShellTreeViewOptionsView read FOptionsView write SetOptionsView;
    property QuickAccessNodeState: Boolean read GetQuickAccessNodeState write SetQuickAccessNodeState;
    property SelectedPath: string read FSelectedPath write SetSelectedPath;
  end;

  { TACLShellTreeView }

  TACLShellTreeView = class(TACLCustomTreeList)
  strict private
    function GetOptionsBehavior: TACLShellTreeViewOptionsBehavior;
    function GetOptionsView: TACLShellTreeViewOptionsView;
    function GetSelectedFolder: TACLShellFolder;
    function GetSelectedPath: string;
    function GetSubClass: TACLShellTreeViewSubClass;
    procedure SetOptionsBehavior(const Value: TACLShellTreeViewOptionsBehavior);
    procedure SetOptionsView(const Value: TACLShellTreeViewOptionsView);
    procedure SetSelectedPath(const Value: string);
  protected
    function CreateSubClass: TACLCompoundControlSubClass; override;
  public
    procedure CreateDirectory(const AFolder: string = '');
    function GetFullPath(ANode: TACLTreeListNode): string;
    //# Properties
    property SelectedFolder: TACLShellFolder read GetSelectedFolder;
    property SelectedPath: string read GetSelectedPath write SetSelectedPath;
    property SubClass: TACLShellTreeViewSubClass read GetSubClass;
  published
    property OptionsBehavior: TACLShellTreeViewOptionsBehavior read GetOptionsBehavior write SetOptionsBehavior;
    property OptionsView: TACLShellTreeViewOptionsView read GetOptionsView write SetOptionsView;
    //# Styles
    property ResourceCollection;
    property Style;
    property StyleInplaceEdit;
    property StyleScrollBox;
    //# CustomDraw
    property OnCustomDrawNode;
    property OnCustomDrawNodeCell;
    //# Events
    property OnCalculated;
    property OnDrop;
    property OnFocusedNodeChanged;
    property OnGetCursor;
    property OnGetNodeBackground;
    property OnGetNodeCellStyle;
    property OnNodeChecked;
    property OnSelectionChanged;
    //# Inherted
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
{$IFDEF MSWINDOWS}
  ACL.Utils.Desktop,
{$ELSE}
  ACL.Utils.FileSystem.GIO,
{$ENDIF}
  ACL.Utils.FileSystem,
  ACL.UI.Dialogs;

type
  TACLTreeListNodeAccess = class(TACLTreeListNode);
  TACLTreeListCustomOptionsAccess = class(TACLTreeListCustomOptions);

{ TACLShellImageList }

constructor TACLShellImageList.Create(AOwner: TComponent);
{$IFDEF MSWINDOWS}
var
  LFileInfo: TSHFileInfoW;
begin
  inherited Create(AOwner);
  DrawingStyle := dsTransparent;
  ShareImages := True;
  ZeroMemory(@LFileInfo, SizeOf(LFileInfo));
  Handle := SHGetFileInfoW('', 0, LFileInfo, SizeOf(LFileInfo),
    SHGFI_USEFILEATTRIBUTES or SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
{$ELSE}
begin
  inherited Create(AOwner);
  FCache := TACLDictionary<string, Integer>.Create;;
{$ENDIF}
end;

destructor TACLShellImageList.Destroy;
begin
  FreeAndNil(FCache);
  inherited Destroy;
end;

function TACLShellImageList.GetImageIndex(AFolder: TACLShellFolder): Integer;
{$IFDEF MSWINDOWS}
var
  LFileInfo: TSHFileInfoW;
begin
  ZeroMemory(@LFileInfo, SizeOf(LFileInfo));
  SHGetFileInfoW(PWideChar(AFolder.AbsoluteID), 0, LFileInfo, SizeOf(LFileInfo),
    SHGFI_PIDL or SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
  Result := LFileInfo.iIcon;
{$ELSE}
const
  RegularFolderImageIndex = 0;

  function AddImageFile(const AFileName: string): Integer;
  var
    LBitmap: TBitmap;
    LImage: TACLImage;
  begin
    if not FCache.TryGetValue(AFileName, Result) then
    begin
      try
        LImage := TACLImage.Create(AFileName);
        try
          LBitmap := LImage.ToBitmap;
          try
            Result := Add(LBitmap, nil);
          finally
            LBitmap.Free;
          end;
        finally
          LImage.Free;
        end;
      except
        Result := RegularFolderImageIndex;
      end;
      FCache.Add(AFileName, Result);
    end;
  end;

  function FetchIcon(const APath: string): Integer;
  var
    LFileName: string;
  begin
    LFileName := gioGetIconFileNameForUri(APath, Width);
    if LFileName <> '' then
      Result := AddImageFile(LFileName)
    else
      Result := RegularFolderImageIndex;
  end;

begin
  // IL еще не готов - форсируем иконку для обычной папки
  if FCache.Count = 0 then
  begin
    FetchIcon(PathDelim);
    if FCache.Count = 0 then // FetchIcon облажалась
      FCache.Add('', RegularFolderImageIndex); // чтобы не было зацикливания
  end;
  if AFolder.ID^.Flags <> 0 then // спец.папка, для них спрашиваем свою иконку
    Result := FetchIcon(AFolder.Path)
  else
    Result := RegularFolderImageIndex;
{$ENDIF}
end;

{ TACLShellTreeViewCustomOptions }

constructor TACLShellTreeViewCustomOptions.Create(ASource: TACLTreeListCustomOptions);
begin
  inherited Create;
  FSource := ASource;
end;

procedure TACLShellTreeViewCustomOptions.BeginUpdate;
begin
  FSource.BeginUpdate;
end;

procedure TACLShellTreeViewCustomOptions.EndUpdate;
begin
  FSource.EndUpdate;
end;

procedure TACLShellTreeViewCustomOptions.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);
  if Source is TACLShellTreeViewCustomOptions then
    FSource.Assign(TACLShellTreeViewCustomOptions(Source).FSource);
end;

procedure TACLShellTreeViewCustomOptions.DoChanged(AChanges: TACLPersistentChanges);
begin
  TACLTreeListCustomOptionsAccess(FSource).DoChanged(AChanges);
  if apcStruct in AChanges then
    FSource.TreeList.ReloadData;
end;

{ TACLShellTreeViewOptionsBehavior }

procedure TACLShellTreeViewOptionsBehavior.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);
  if Source is TACLShellTreeViewOptionsBehavior then
  begin
    AllowLibraryPaths := TACLShellTreeViewOptionsBehavior(Source).AllowLibraryPaths;
    AutoCheckParents := TACLShellTreeViewOptionsBehavior(Source).AutoCheckParents;
    AutoCheckChildren := TACLShellTreeViewOptionsBehavior(Source).AutoCheckChildren;
    SystemMenu := TACLShellTreeViewOptionsBehavior(Source).SystemMenu;
  end;
end;

function TACLShellTreeViewOptionsBehavior.GetAutoCheckParents: Boolean;
begin
  Result := TACLTreeListOptionsBehavior(FSource).AutoCheckParents;
end;

function TACLShellTreeViewOptionsBehavior.GetAutoCheckChildren: Boolean;
begin
  Result := TACLTreeListOptionsBehavior(FSource).AutoCheckChildren;
end;

procedure TACLShellTreeViewOptionsBehavior.SetAutoCheckParents(const Value: Boolean);
begin
  TACLTreeListOptionsBehavior(FSource).AutoCheckParents := Value;
end;

procedure TACLShellTreeViewOptionsBehavior.SetAutoCheckChildren(const Value: Boolean);
begin
  TACLTreeListOptionsBehavior(FSource).AutoCheckChildren := Value;
end;

{ TACLShellTreeViewOptionsView }

procedure TACLShellTreeViewOptionsView.AfterConstruction;
begin
  inherited AfterConstruction;
  TACLTreeListOptionsView(FSource).Columns.Visible := False;
  TACLTreeListOptionsView(FSource).Nodes.GridLines := [];
end;

procedure TACLShellTreeViewOptionsView.DoAssign(Source: TPersistent);
begin
  inherited DoAssign(Source);
  if Source is TACLShellTreeViewOptionsView then
  begin
    ShowHidden := TACLShellTreeViewOptionsView(Source).ShowHidden;
    ShowFavorites := TACLShellTreeViewOptionsView(Source).ShowFavorites;
  end;
end;

function TACLShellTreeViewOptionsView.GetBorders: TACLBorders;
begin
  Result := TACLTreeListOptionsView(FSource).Borders;
end;

function TACLShellTreeViewOptionsView.GetCheckBoxes: Boolean;
begin
  Result := TACLTreeListOptionsView(FSource).CheckBoxes;
end;

procedure TACLShellTreeViewOptionsView.SetBorders(AValue: TACLBorders);
begin
  TACLTreeListOptionsView(FSource).Borders := AValue;
end;

procedure TACLShellTreeViewOptionsView.SetCheckBoxes(AValue: Boolean);
begin
  TACLTreeListOptionsView(FSource).CheckBoxes := AValue;
end;

procedure TACLShellTreeViewOptionsView.SetShowFavorites(AValue: Boolean);
begin
  if FShowFavorites <> AValue then
  begin
    FShowFavorites := AValue;
    Changed([apcStruct]);
  end;
end;

procedure TACLShellTreeViewOptionsView.SetShowHidden(AValue: TACLBoolean);
begin
  if AValue <> FShowHidden then
  begin
    FShowHidden := AValue;
    Changed([apcStruct]);
  end;
end;

{ TACLShellTreeViewSubClass }

constructor TACLShellTreeViewSubClass.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOptionsView := CreateOptionsView;
  FOptionsBehavior := CreateOptionsBehavior;
  FQuickAccessNodeState := DefaultQuickAccessNodeState;
  FImages := TACLShellImageList.Create(Self);

  inherited OptionsBehavior.AutoBestFit := True;
  inherited OptionsBehavior.IncSearchColumnIndex := 0;
  inherited OptionsView.Nodes.Images := FImages;
end;

destructor TACLShellTreeViewSubClass.Destroy;
begin
  FreeAndNil(FOptionsBehavior);
  FreeAndNil(FOptionsView);
  inherited Destroy;
end;

procedure TACLShellTreeViewSubClass.ConfigLoad(AConfig: TACLIniFile; const ASection, AItem: string);
begin
  inherited;
  if OptionsView.ShowFavorites then
  begin
    QuickAccessNodeState := AConfig.ReadBool(ASection,
      AItem + '.QuickAccessExpanded', DefaultQuickAccessNodeState);
  end;
end;

procedure TACLShellTreeViewSubClass.ConfigSave(AConfig: TACLIniFile; const ASection, AItem: string);
begin
  inherited;
  if OptionsView.ShowFavorites then
  begin
    AConfig.WriteBool(ASection, AItem + '.QuickAccessExpanded',
      QuickAccessNodeState, DefaultQuickAccessNodeState);
  end;
end;

procedure TACLShellTreeViewSubClass.CreateDirectory(AFolder: string = '');
begin
  if TACLInputQueryDialog.Execute(TACLDialogsStrs.FolderBrowserNewFolder, '', AFolder, Self) then
  begin
    if AFolder = '' then
      AFolder := TACLDialogsStrs.FolderBrowserNewFolder;
    DoCreateDirectory(AFolder);
  end;
end;

function TACLShellTreeViewSubClass.GetFullPath(ANode: TACLTreeListNode): string;
var
  AFolder: TACLShellFolder;
begin
  Result := '';
  if ANode <> nil then
  begin
    AFolder := TACLShellFolder(ANode.Data);
    if AFolder <> nil then
    begin
      if OptionsBehavior.AllowLibraryPaths and AFolder.IsLibrary then
        Result := AFolder.PathForParsing
      else
        Result := acIncludeTrailingPathDelimiter(AFolder.Path);
    end;
  end
end;

function TACLShellTreeViewSubClass.GetQuickAccessNodeState: Boolean;
begin
  if FQuickAccessNode <> nil then
    Result := FQuickAccessNode.Expanded
  else
    Result := FQuickAccessNodeState;
end;

function TACLShellTreeViewSubClass.CreateOptionsBehavior: TACLShellTreeViewOptionsBehavior;
begin
  Result := TACLShellTreeViewOptionsBehavior.Create(inherited OptionsBehavior);
end;

function TACLShellTreeViewSubClass.CreateOptionsView: TACLShellTreeViewOptionsView;
begin
  Result := TACLShellTreeViewOptionsView.Create(inherited OptionsView);
end;

procedure TACLShellTreeViewSubClass.DoCreateDirectory(const AFolder: string);
var
  ACounter: Integer;
  S: string;
  X: TACLTreeListNode;
begin
  if FocusedNode <> nil then
  begin
    BeginUpdate;
    try
      S := AFolder;
      ACounter := 2;
      while FocusedNode.Find(X, S, 0, False) do
      begin
        S := AFolder + ' (' + IntToStr(ACounter) + ')';
        Inc(ACounter);
      end;
      S := GetFullPath(FocusedNode) + S;
      acMakePath(S);
      FocusedNode.DeleteChildren;
      FocusedNode.HasChildren := True;
      FocusedNode.ChildrenNeeded;
      SelectedPath := S;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TACLShellTreeViewSubClass.DoFocusedNodeChanged;
begin
  FSelectedPath := acExcludeTrailingPathDelimiter(GetFullPath(FocusedNode));
  inherited DoFocusedNodeChanged;
end;

procedure TACLShellTreeViewSubClass.DoGetNodeChildren(ANode: TACLTreeListNode);
begin
  if ANode = RootNode then
    DoGetRootChildren(ANode)
  else
    DoGetPathChildren(ANode);
end;

procedure TACLShellTreeViewSubClass.DoGetPathChildren(ANode: TACLTreeListNode);
var
  LFolderParent: TACLShellFolder;
begin
  LFolderParent := ANode.Data;
  LFolderParent.Enum(TACLApplication.GetHandle,
    OptionsView.ShowHidden.ActualValue(TACLShellFolder.ShowHidden),
    procedure (ID: PItemIDList)
    var
      LFolder: TACLShellFolder;
    begin
      LFolder := TACLShellFolder.Create(LFolderParent, ID);
      if LFolder.IsFileSystemFolder then
        AddNode(LFolder, ANode)
      else
        LFolder.Free;
    end);
  if ANode.ChildrenCount > 1 then
    TACLTreeListNodeAccess(ANode).FSubNodes.Sort(@SortFolderNames);
end;

procedure TACLShellTreeViewSubClass.DoGetRootChildren(ANode: TACLTreeListNode);

  function AddNodeSpecial(const Uri: string): TACLTreeListNode;
  var
    LPIDL: PItemIDList;
  begin
    Result := nil;
    try
      LPIDL := TPIDLHelper.GetFolderPIDL(TACLApplication.GetHandle, Uri);
      if LPIDL <> nil then
      try
        Result := AddNode(TACLShellFolder.CreateSpecial(LPIDL), ANode);
      finally
        TPIDLHelper.DisposePIDL(LPIDL);
      end;
    except
      Result := nil;
    end;
  end;

begin
  if OptionsView.ShowFavorites then
  begin
    FQuickAccessNode := AddNodeSpecial(TPIDLHelper.Favorites);
    if FQuickAccessNode <> nil then
      FQuickAccessNode.Expanded := FQuickAccessNodeState;
  end;
{$IFDEF MSWINDOWS}
  AddNode(TACLShellFolder.Create, RootNode).Expanded := True;
{$ELSE}
  AddNodeSpecial(GetUserDir).Expanded := True;
  AddNode(TACLShellFolder.Create, RootNode);
{$ENDIF}
end;

procedure TACLShellTreeViewSubClass.NodeRemoving(ANode: TACLTreeListNode);
begin
  if ANode = FQuickAccessNode then
    FQuickAccessNode := nil;
  TACLShellFolder(ANode.Data).Free;
  inherited NodeRemoving(ANode);
end;

function TACLShellTreeViewSubClass.AddNode(
  AFolder: TACLShellFolder; AParent: TACLTreeListNode): TACLTreeListNode;
begin
  Result := AParent.AddChild([AFolder.DisplayName]);
  Result.Data := AFolder;
  Result.HasChildren := AFolder.HasChildren;
  Result.ImageIndex := FImages.GetImageIndex(AFolder);
end;

function TACLShellTreeViewSubClass.FindNodeByPIDL(
  AAbsoluteID: PItemIDList; ANode: TACLTreeListNode): TACLTreeListNode;
var
  LFolder: TACLShellFolder;
  I: Integer;
begin
  if ANode <> nil then
  begin
    for I := 0 to ANode.ChildrenCount - 1 do
    begin
      LFolder := ANode.Children[I].Data;
      if TACLShellFolder.Root.Compare(AAbsoluteID, LFolder.AbsoluteID) = 0 then
        Exit(ANode.Children[I]);
    end;
  end;
  Result := nil;
end;

procedure TACLShellTreeViewSubClass.SelectPathByPIDL(PIDL: PItemIDList);
var
  LCandidate: TACLTreeListNode;
  LCurrPIDL: PItemIDList;
  LLastNode: TACLTreeListNode;
  LNextNode: TACLTreeListNode;
  LStack: TList;
  I: Integer;
begin
  if (PIDL <> nil) and (RootNode.ChildrenCount > 0) then
  begin
    LStack := TList.Create;
    try
      LCandidate := nil;
      LCurrPIDL := TPIDLHelper.CopyPIDL(PIDL);
      repeat
        LLastNode := FindNodeByPIDL(LCurrPIDL, RootNode);
        if LLastNode <> nil then
        begin
          for I := LStack.Count - 1 downto 0 do
          begin
            LNextNode := FindNodeByPIDL(LStack.List[I], LLastNode);
            if LNextNode = nil then Break;
            LLastNode := LNextNode;
          end;
          // По этой ветке прошли глубже?
          if (LCandidate = nil) or (LLastNode.Level > LCandidate.Level) then
            LCandidate := LLastNode;
          // Дошли до конца?
          if TACLShellFolder.Root.Compare(PIDL, TACLShellFolder(LCandidate.Data).AbsoluteID) = 0 then
            Break;
        end;
        LStack.Add(LCurrPIDL);
        LCurrPIDL := TPIDLHelper.GetParentPIDL(LCurrPIDL);
      until LCurrPIDL = nil;

      if LCandidate <> nil then
      begin
        FocusedNode := LCandidate;
        MakeTop(FocusedNode);
      end;
    finally
      TPIDLHelper.DisposePIDL(LCurrPIDL);
      for I := LStack.Count - 1 downto 0 do
        TPIDLHelper.DisposePIDL(PItemIDList(LStack.List[I]));
      LStack.Free;
    end;
  end;
end;

procedure TACLShellTreeViewSubClass.SetOptionsBehavior(AValue: TACLShellTreeViewOptionsBehavior);
begin
  FOptionsBehavior.Assign(AValue);
end;

procedure TACLShellTreeViewSubClass.SetOptionsView(AValue: TACLShellTreeViewOptionsView);
begin
  FOptionsView.Assign(AValue);
end;

procedure TACLShellTreeViewSubClass.SetQuickAccessNodeState(AValue: Boolean);
begin
  FQuickAccessNodeState := AValue;
  if FQuickAccessNode <> nil then
    FQuickAccessNode.Expanded := AValue;
end;

procedure TACLShellTreeViewSubClass.SetSelectedPath(AValue: string);
var
  APIDL: PItemIDList;
begin
  AValue := acExcludeTrailingPathDelimiter(AValue);
  if not acSameText(SelectedPath, AValue) then
  try
    FSelectedPath := AValue;
    APIDL := TPIDLHelper.GetFolderPIDL(TACLApplication.GetHandle, AValue);
    try
      SelectPathByPIDL(APIDL);
    finally
      TPIDLHelper.DisposePIDL(APIDL);
    end;
  except
    // do nothing
  end;
end;

class function TACLShellTreeViewSubClass.SortFolderNames(L, R: TACLTreeListNode): Integer;
begin
  Result := TACLShellFolder(L.Data).Compare(
    TACLShellFolder(L.Data).ID,
    TACLShellFolder(R.Data).ID);
end;

procedure TACLShellTreeViewSubClass.ProcessContextPopup(var AHandled: Boolean);
begin
  inherited ProcessContextPopup(AHandled);
  if not AHandled and HitTest.HitAtNode and OptionsBehavior.SystemMenu then
    InvokeSystemMenu(Container.GetControl.Handle, HitTest.Node);
end;

procedure TACLShellTreeViewSubClass.ProcessKeyDown(var AKey: Word; AShift: TShiftState);
begin
  if AKey = VK_F5 then
    ReloadData
  else
    inherited ProcessKeyDown(AKey, AShift);
end;

procedure TACLShellTreeViewSubClass.InvokeSystemMenu(AOwnerWindow: HWND; ANode: TACLTreeListNode);
{$IFDEF MSWINDOWS}
const
  TRACKMENU_FLAGS = TPM_LEFTALIGN or TPM_LEFTBUTTON or TPM_RIGHTBUTTON or TPM_RETURNCMD;
var
  ACmdInfo: TCMInvokeCommandInfo;
  ACommand: LongBool;
  AContextMenu: IContextMenu;
  AMenu: HMENU;
  APoint: TPoint;
  AVerb: array[0..255] of AnsiChar;
begin
  if TACLShellFolder(ANode.Data).GetUIObjectOf(AOwnerWindow, IID_IContextMenu, AContextMenu) then
  begin
    AMenu := CreatePopupMenu;
    try
      APoint := MouseCursorPos;
      AContextMenu.QueryContextMenu(AMenu, 0, 1, $7FFF, CMF_EXPLORE);
      ACommand := TrackPopupMenu(AMenu, TRACKMENU_FLAGS, APoint.X, APoint.Y, 0, AOwnerWindow, nil);
      if ACommand then
      begin
        AContextMenu.GetCommandString(LongInt(ACommand) - 1, GCS_VERBA, nil, AVerb, SizeOf(AVerb));
        if acSameText(string(System.AnsiStrings.StrPas(AVerb)), 'open') then
        begin
          ANode.Expanded := True;
          Exit;
        end;
        FillChar(ACmdInfo, SizeOf(ACmdInfo), #0);
        ACmdInfo.cbSize := SizeOf(ACmdInfo);
        ACmdInfo.hwnd := AOwnerWindow;
        ACmdInfo.lpVerb := MakeIntResourceA(LongInt(ACommand) - 1);
        ACmdInfo.nShow := SW_SHOWNORMAL;
        AContextMenu.InvokeCommand(ACmdInfo);
        ReloadData;
      end;
    finally
      DestroyMenu(AMenu);
    end;
  end;
{$ELSE}
begin
{$ENDIF}
end;

{ TACLShellTreeView }

procedure TACLShellTreeView.CreateDirectory(const AFolder: string = '');
begin
  SubClass.CreateDirectory(AFolder);
end;

function TACLShellTreeView.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLShellTreeViewSubClass.Create(Self);
end;

function TACLShellTreeView.GetFullPath(ANode: TACLTreeListNode): string;
begin
  Result := SubClass.GetFullPath(ANode);
end;

function TACLShellTreeView.GetOptionsBehavior: TACLShellTreeViewOptionsBehavior;
begin
  Result := SubClass.OptionsBehavior;
end;

function TACLShellTreeView.GetOptionsView: TACLShellTreeViewOptionsView;
begin
  Result := SubClass.OptionsView;
end;

function TACLShellTreeView.GetSelectedFolder: TACLShellFolder;
begin
  Result := FocusedNodeData;
end;

function TACLShellTreeView.GetSelectedPath: string;
begin
  Result := SubClass.SelectedPath;
end;

function TACLShellTreeView.GetSubClass: TACLShellTreeViewSubClass;
begin
  Result := TACLShellTreeViewSubClass(inherited SubClass);
end;

procedure TACLShellTreeView.SetOptionsBehavior(const Value: TACLShellTreeViewOptionsBehavior);
begin
  SubClass.OptionsBehavior := Value;
end;

procedure TACLShellTreeView.SetOptionsView(const Value: TACLShellTreeViewOptionsView);
begin
  SubClass.OptionsView := Value;
end;

procedure TACLShellTreeView.SetSelectedPath(const Value: string);
begin
  SubClass.SelectedPath := Value;
end;

end.
