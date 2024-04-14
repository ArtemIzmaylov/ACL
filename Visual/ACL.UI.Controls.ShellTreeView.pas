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

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.ShellApi,
  Winapi.ShlObj,
  // System
  System.Types,
  System.Classes,
  // Vcl
  Vcl.ImgList,
  Vcl.Controls,
  // ACL
  ACL.Classes,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Graphics,
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
  public
    constructor Create(AOwner: TComponent); override;
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

    function GetActualShowHidden: Boolean;
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
    //# Properties
    property ActualShowHidden: Boolean read GetActualShowHidden;
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

    function AddFolderNode(ID: PItemIDList; AParent: TACLTreeListNode): TACLTreeListNode;
    function FindNodeByPIDL(ID: PItemIDList; ANode: TACLTreeListNode): TACLTreeListNode;
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
  System.AnsiStrings,
  System.SysUtils,
  // ACL
  ACL.UI.Dialogs,
  ACL.Utils.FileSystem,
  ACL.Utils.Desktop;

type
  TACLTreeListNodeAccess = class(TACLTreeListNode);
  TACLTreeListCustomOptionsAccess = class(TACLTreeListCustomOptions);

{ TACLShellImageList }

constructor TACLShellImageList.Create(AOwner: TComponent);
var
  LFileInfo: TSHFileInfoW;
begin
  inherited Create(AOwner);
  DrawingStyle := dsTransparent;
  ShareImages := True;
  ZeroMemory(@LFileInfo, SizeOf(LFileInfo));
  Handle := SHGetFileInfoW('', 0, LFileInfo, SizeOf(LFileInfo),
    SHGFI_USEFILEATTRIBUTES or SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
end;

function TACLShellImageList.GetImageIndex(AFolder: TACLShellFolder): Integer;
var
  LFileInfo: TSHFileInfoW;
begin
  ZeroMemory(@LFileInfo, SizeOf(LFileInfo));
  SHGetFileInfoW(PWideChar(AFolder.FullPIDL), 0, LFileInfo, SizeOf(LFileInfo),
    SHGFI_PIDL or SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
  Result := LFileInfo.iIcon;
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

function TACLShellTreeViewOptionsView.GetActualShowHidden: Boolean;
begin
  if ShowHidden = TACLBoolean.Default then
    Result := ShellShowHiddenByDefault
  else
    Result := ShowHidden = TACLBoolean.True;
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
  FSelectedPath := ExcludeTrailingPathDelimiter(GetFullPath(FocusedNode));
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

  function GetObjectFlags: Integer;
  begin
    Result := SHCONTF_FOLDERS;
    if OptionsView.ActualShowHidden then
      Inc(Result, SHCONTF_INCLUDEHIDDEN);
  end;

var
  AEnumList: IEnumIDList;
  ANumIDs: LongWord;
  AResult: HRESULT;
  ID: PItemIDList;
begin
  try
    AResult := TACLShellFolder(ANode.Data).ShellFolder.EnumObjects(
      TACLApplication.GetHandle, GetObjectFlags, AEnumList);
    if AResult <> 0 then
      Exit;
  except
    on E: Exception do
  end;
  while AEnumList.Next(1, ID, ANumIDs) = S_OK do
    AddFolderNode(ID, ANode);
  if ANode.ChildrenCount > 1 then
    TACLTreeListNodeAccess(ANode).FSubNodes.Sort(@SortFolderNames);
end;

procedure TACLShellTreeViewSubClass.DoGetRootChildren(ANode: TACLTreeListNode);
var
  LFolder: TACLShellFolder;
  LPIDL: PItemIDList;
begin
  if OptionsView.ShowFavorites then
  try
    LPIDL := TPIDLHelper.GetFolderPIDL(TACLApplication.GetHandle, TPIDLHelper.QuickAccessPath);
    if LPIDL <> nil then
    try
      try
        LFolder := TACLShellFolder.CreateSpecial(LPIDL);
      except
        LFolder := nil;
      end;
      if LFolder <> nil then
      begin
        FQuickAccessNode := RootNode.AddChild([LFolder.DisplayName]);
        FQuickAccessNode.Data := LFolder;
        FQuickAccessNode.ImageIndex := FImages.GetImageIndex(LFolder);
        FQuickAccessNode.HasChildren := LFolder.HasChildren;
        FQuickAccessNode.Expanded := FQuickAccessNodeState;
      end;
    finally
      TPIDLHelper.DisposePIDL(LPIDL);
    end;
  except
    // do nothing
  end;

  ANode := AddFolderNode(TACLShellFolder.Root.AbsoluteID, RootNode);
  if ANode <> nil then
    ANode.Expanded := True;
end;

procedure TACLShellTreeViewSubClass.NodeRemoving(ANode: TACLTreeListNode);
begin
  if ANode = FQuickAccessNode then
    FQuickAccessNode := nil;
  TACLShellFolder(ANode.Data).Free;
  inherited NodeRemoving(ANode);
end;

function TACLShellTreeViewSubClass.AddFolderNode(
  ID: PItemIDList; AParent: TACLTreeListNode): TACLTreeListNode;
var
  LFolder: TACLShellFolder;
begin
  Result := nil;
  if ID <> nil then
  begin
    LFolder := TACLShellFolder.Create(TACLShellFolder(AParent.Data), ID);
    if LFolder.IsFolder then
    begin
      Result := AParent.AddChild([LFolder.DisplayName]);
      Result.Data := LFolder;
      Result.HasChildren := LFolder.HasChildren;
      Result.ImageIndex := FImages.GetImageIndex(LFolder);
    end
    else
      FreeAndNil(LFolder);
  end;
end;

function TACLShellTreeViewSubClass.FindNodeByPIDL(
  ID: PItemIDList; ANode: TACLTreeListNode): TACLTreeListNode;
var
  AFolder: TACLShellFolder;
  I: Integer;
begin
  Result := nil;
  if ANode <> nil then
    for I := 0 to ANode.ChildrenCount - 1 do
    begin
      AFolder := TACLShellFolder(ANode.Children[I].Data);
      if AFolder.Root.ShellFolder.CompareIDs(0, ID, AFolder.AbsoluteID) = 0 then
        Exit(ANode.Children[I]);
    end;
end;

procedure TACLShellTreeViewSubClass.SelectPathByPIDL(PIDL: PItemIDList);
var
  ALast: TACLTreeListNode;
  AList: TList;
  I, R: Integer;
begin
  if Assigned(PIDL) and (RootNode.ChildrenCount > 0) then
  begin
    AList := TPIDLHelper.CreatePIDLList(PIDL);
    try
      for R := 0 to RootNode.ChildrenCount - 1 do
      begin
        ALast := RootNode.Children[R];
        for I := 1 to AList.Count - 1 do
        begin
          ALast := FindNodeByPIDL(AList.Items[I], ALast);
          if ALast = nil then Break;
          ALast.Expanded := True;
        end;
        if ALast <> nil then
        begin
          FocusedNode := FindNodeByPIDL(PIDL, ALast);
          MakeTop(FocusedNode);
          Break;
        end;
      end;
    finally
      TPIDLHelper.DestroyPIDLList(AList);
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
  AValue := ExcludeTrailingPathDelimiter(AValue);
  if not acSameText(SelectedPath, AValue) then
  try
    FSelectedPath := AValue;
    if not ShellIsLibraryPath(AValue) then
      AValue := acIncludeTrailingPathDelimiter(AValue);

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
  Result := TACLShellFolder(L.Data).Compare(TACLShellFolder(R.Data));
end;

procedure TACLShellTreeViewSubClass.ProcessContextPopup(var AHandled: Boolean);
begin
  inherited ProcessContextPopup(AHandled);
  if not AHandled and HitTest.HitAtNode and OptionsBehavior.SystemMenu then
    InvokeSystemMenu(Container.GetControl.Handle, HitTest.Node);
end;

procedure TACLShellTreeViewSubClass.ProcessKeyDown(var AKey: Word; AShift: TShiftState);
begin
  if AShift * [ssShift, ssAlt, ssCtrl] = [] then
    case AKey of
      VK_F5:
        begin
          ReloadData;
          Exit;
        end;

      VK_DELETE:
        begin
          if ShellDelete(SelectedPath, [sofCanUndo]) then
            ReloadData;
          Exit;
        end;
    end;

  inherited ProcessKeyDown(AKey, AShift);
end;

procedure TACLShellTreeViewSubClass.InvokeSystemMenu(AOwnerWindow: HWND; ANode: TACLTreeListNode);
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
