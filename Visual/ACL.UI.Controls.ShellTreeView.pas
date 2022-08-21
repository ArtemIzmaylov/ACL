{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             TreeList Control              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
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
    FShowHidden: TACLBoolean;

    function GetActualShowHidden: Boolean;
    function GetBorders: TACLBorders;
    function GetCheckBoxes: Boolean;
    procedure SetBorders(AValue: TACLBorders);
    procedure SetCheckBoxes(AValue: Boolean);
    procedure SetShowHidden(AValue: TACLBoolean);
  protected
    procedure DoAssign(Source: TPersistent); override;
  public
    procedure AfterConstruction; override;
    //
    property ActualShowHidden: Boolean read GetActualShowHidden;
  published
    property Borders: TACLBorders read GetBorders write SetBorders default acAllBorders;
    property CheckBoxes: Boolean read GetCheckBoxes write SetCheckBoxes default False;
    property ShowHidden: TACLBoolean read FShowHidden write SetShowHidden default TACLBoolean.Default;
  end;

  { TACLShellTreeViewSubClass }

  TACLShellTreeViewSubClass = class(TACLTreeListSubClass)
  strict private
    FOptionsBehavior: TACLShellTreeViewOptionsBehavior;
    FOptionsView: TACLShellTreeViewOptionsView;
    FSelectedPath: UnicodeString;

    function GetSelectedShellFolder: TACLShellFolder;
    procedure SetOptionsBehavior(AValue: TACLShellTreeViewOptionsBehavior);
    procedure SetOptionsView(AValue: TACLShellTreeViewOptionsView);
    procedure SetSelectedPath(AValue: UnicodeString);
  protected
    function CreateController: TACLCompoundControlSubClassController; override;
    function CreateOptionsBehavior: TACLShellTreeViewOptionsBehavior; reintroduce; virtual;
    function CreateOptionsView: TACLShellTreeViewOptionsView; reintroduce; virtual;
    function CreateShellImageList: TCustomImageList;

    procedure DoCreateDirectory(const AFolder: UnicodeString);
    procedure DoFocusedNodeChanged; override;
    procedure DoGetNodeChildren(ANode: TACLTreeListNode); override; final;
    procedure DoGetPathChildren(ANode: TACLTreeListNode); virtual;
    procedure DoGetRootChildren(ANode: TACLTreeListNode); virtual;

    procedure NodeRemoving(ANode: TACLTreeListNode); override;

    function AddFolderNode(ID: PItemIDList; AParent: TACLTreeListNode): TACLTreeListNode;
    function FindNodeByPIDL(ID: PItemIDList; ANode: TACLTreeListNode): TACLTreeListNode;
    procedure SelectPathByPIDL(PIDL: PItemIDList);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CreateDirectory(AFolder: UnicodeString = '');
    function GetFullPath(ANode: TACLTreeListNode): UnicodeString;
    //
    property SelectedPath: UnicodeString read FSelectedPath write SetSelectedPath;
    property SelectedShellFolder: TACLShellFolder read GetSelectedShellFolder;
    property OptionsBehavior: TACLShellTreeViewOptionsBehavior read FOptionsBehavior write SetOptionsBehavior;
    property OptionsView: TACLShellTreeViewOptionsView read FOptionsView write SetOptionsView;
  end;

  { TACLShellTreeViewSubClassController }

  TACLShellTreeViewSubClassController = class(TACLTreeListSubClassController)
  strict private
    function GetSubClass: TACLShellTreeViewSubClass;
  protected
    procedure InvokeSystemMenu(AOwnerWindow: HWND; ANode: TACLTreeListNode);
    procedure ProcessContextPopup(var AHandled: Boolean); override;
    procedure ProcessKeyDown(AKey: Word; AShift: TShiftState); override;
  public
    property SubClass: TACLShellTreeViewSubClass read GetSubClass;
  end;

  { TACLShellTreeView }

  TACLShellTreeView = class(TACLCustomTreeList)
  strict private
    function GetOptionsBehavior: TACLShellTreeViewOptionsBehavior;
    function GetOptionsView: TACLShellTreeViewOptionsView;
    function GetSelectedPath: UnicodeString;
    function GetSubClass: TACLShellTreeViewSubClass;
    procedure SetOptionsBehavior(const Value: TACLShellTreeViewOptionsBehavior);
    procedure SetOptionsView(const Value: TACLShellTreeViewOptionsView);
    procedure SetSelectedPath(const Value: UnicodeString);
  protected
    function CreateSubClass: TACLCompoundControlSubClass; override;
  public
    procedure CreateDirectory(const AFolder: UnicodeString = '');
    function GetFullPath(ANode: TACLTreeListNode): UnicodeString;
    //
    property SelectedPath: UnicodeString read GetSelectedPath write SetSelectedPath;
    property SubClass: TACLShellTreeViewSubClass read GetSubClass;
  published
    property OptionsBehavior: TACLShellTreeViewOptionsBehavior read GetOptionsBehavior write SetOptionsBehavior;
    property OptionsView: TACLShellTreeViewOptionsView read GetOptionsView write SetOptionsView;
    //
    property ResourceCollection;
    property Style;
    property StyleInplaceEdit;
    property StyleScrollBox;
    //
    property OnCustomDrawNode;
    property OnCustomDrawNodeCell;
    //
    property OnCalculated;
    property OnDrop;
    property OnFocusedNodeChanged;
    property OnGetCursor;
    property OnGetNodeBackground;
    property OnGetNodeCellStyle;
    property OnNodeChecked;
    property OnSelectionChanged;
    //
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

const
  sShellOpenVerb = 'open';

type
  TACLTreeListNodeAccess = class(TACLTreeListNode);
  TACLTreeListCustomOptionsAccess = class(TACLTreeListCustomOptions);

function SortFolderNames(Item1, Item2: TACLTreeListNode): Integer;
begin
  Result := TACLShellFolder(Item1.Data).Compare(TACLShellFolder(Item2.Data));
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
    ShowHidden := TACLShellTreeViewOptionsView(Source).ShowHidden;
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

  inherited OptionsBehavior.AutoBestFit := True;
  inherited OptionsBehavior.IncSearchColumnIndex := 0;
  inherited OptionsView.Nodes.Images := CreateShellImageList;
end;

destructor TACLShellTreeViewSubClass.Destroy;
begin
  FreeAndNil(FOptionsBehavior);
  FreeAndNil(FOptionsView);
  inherited Destroy;
end;

procedure TACLShellTreeViewSubClass.CreateDirectory(AFolder: UnicodeString = '');
begin
  if TACLInputQueryDialog.Execute(TACLDialogsStrs.FolderBrowserNewFolder, '', AFolder, Self) then
  begin
    if AFolder = '' then
      AFolder := TACLDialogsStrs.FolderBrowserNewFolder;
    DoCreateDirectory(AFolder);
  end;
end;

function TACLShellTreeViewSubClass.GetFullPath(ANode: TACLTreeListNode): UnicodeString;
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

function TACLShellTreeViewSubClass.CreateController: TACLCompoundControlSubClassController;
begin
  Result := TACLShellTreeViewSubClassController.Create(Self);
end;

function TACLShellTreeViewSubClass.CreateOptionsBehavior: TACLShellTreeViewOptionsBehavior;
begin
  Result := TACLShellTreeViewOptionsBehavior.Create(inherited OptionsBehavior);
end;

function TACLShellTreeViewSubClass.CreateOptionsView: TACLShellTreeViewOptionsView;
begin
  Result := TACLShellTreeViewOptionsView.Create(inherited OptionsView);
end;

function TACLShellTreeViewSubClass.CreateShellImageList: TCustomImageList;
begin
  Result := TImageList.Create(Self);
  Result.ShareImages := True;
  Result.Handle := ShellGetSystemImageList;
  Result.DrawingStyle := dsTransparent;
end;

procedure TACLShellTreeViewSubClass.DoCreateDirectory(const AFolder: UnicodeString);
var
  ACounter: Integer;
  S: UnicodeString;
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
    AResult := TACLShellFolder(ANode.Data).ShellFolder.EnumObjects(TACLApplication.GetHandle, GetObjectFlags, AEnumList);
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
begin
  ANode := AddFolderNode(TACLShellFolder.Root.AbsoluteID, RootNode);
  if ANode <> nil then
    ANode.Expanded := True;
end;

procedure TACLShellTreeViewSubClass.NodeRemoving(ANode: TACLTreeListNode);
begin
  TACLShellFolder(ANode.Data).Free;
  inherited NodeRemoving(ANode);
end;

function TACLShellTreeViewSubClass.AddFolderNode(ID: PItemIDList; AParent: TACLTreeListNode): TACLTreeListNode;
var
  AFolder: TACLShellFolder;
begin
  Result := nil;
  if ID <> nil then
  begin
    AFolder := TACLShellFolder.Create(TACLShellFolder(AParent.Data), ID);
    if AFolder.IsFileSystemPath and ([fscStream, fscFolder] * AFolder.StorageCapabilities <> [fscStream, fscFolder]) then
    begin
      Result := AParent.AddChild([AFolder.DisplayName]);
      Result.Data := AFolder;
      Result.ImageIndex := AFolder.ImageIndex;
      Result.HasChildren := AFolder.HasChildren;
    end
    else
      FreeAndNil(AFolder);
  end;
end;

function TACLShellTreeViewSubClass.FindNodeByPIDL(ID: PItemIDList; ANode: TACLTreeListNode): TACLTreeListNode;
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

function TACLShellTreeViewSubClass.GetSelectedShellFolder: TACLShellFolder;
begin
  if FocusedNode <> nil then
    Result := TACLShellFolder(FocusedNode.Data)
  else
    Result := nil;
end;

procedure TACLShellTreeViewSubClass.SetOptionsBehavior(AValue: TACLShellTreeViewOptionsBehavior);
begin
  FOptionsBehavior.Assign(AValue);
end;

procedure TACLShellTreeViewSubClass.SetOptionsView(AValue: TACLShellTreeViewOptionsView);
begin
  FOptionsView.Assign(AValue);
end;

procedure TACLShellTreeViewSubClass.SetSelectedPath(AValue: UnicodeString);
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

{ TACLShellTreeViewSubClassController }

procedure TACLShellTreeViewSubClassController.ProcessContextPopup(var AHandled: Boolean);
begin
  inherited ProcessContextPopup(AHandled);
  if not AHandled and HitTest.HitAtNode then
    InvokeSystemMenu(SubClass.Container.GetControl.Handle, HitTest.Node);
end;

procedure TACLShellTreeViewSubClassController.ProcessKeyDown(AKey: Word; AShift: TShiftState);
begin
  if AShift * [ssShift, ssAlt, ssCtrl] = [] then
    case AKey of
      VK_F5:
        begin
          SubClass.ReloadData;
          Exit;
        end;

      VK_DELETE:
        begin
          if ShellDeleteDirectory(SubClass.SelectedPath) then
            SubClass.ReloadData;
          Exit;
        end;
    end;

  inherited ProcessKeyDown(AKey, AShift);
end;

procedure TACLShellTreeViewSubClassController.InvokeSystemMenu(AOwnerWindow: HWND; ANode: TACLTreeListNode);
const
  TRACKMENU_FLAGS = TPM_LEFTALIGN or TPM_LEFTBUTTON or TPM_RIGHTBUTTON or TPM_RETURNCMD;
var
  ACmdInfo: TCMInvokeCommandInfo;
  ACommand: LongBool;
  AMenu: HMENU;
  CM: IContextMenu;
  ZVerb: array[0..255] of AnsiChar;
begin
  if SubClass.OptionsBehavior.SystemMenu then
  begin
    if TACLShellFolder(ANode.Data).GetUIObjectOf(AOwnerWindow, IID_IContextMenu, CM) then
    begin
      AMenu := CreatePopupMenu;
      try
        CM.QueryContextMenu(AMenu, 0, 1, $7FFF, CMF_EXPLORE);
        ACommand := TrackPopupMenu(AMenu, TRACKMENU_FLAGS, MouseCursorPos.X, MouseCursorPos.Y, 0, AOwnerWindow, nil);
        if ACommand then
        begin
          CM.GetCommandString(LongInt(ACommand) - 1, GCS_VERBA, nil, ZVerb, SizeOf(ZVerb));
          if acSameText(UnicodeString(System.AnsiStrings.StrPas(ZVerb)), sShellOpenVerb) then
          begin
            ANode.Expanded := True;
            Exit;
          end;
          FillChar(ACmdInfo, SizeOf(ACmdInfo), #0);
          ACmdInfo.cbSize := SizeOf(ACmdInfo);
          ACmdInfo.hwnd := AOwnerWindow;
          ACmdInfo.lpVerb := MakeIntResourceA(LongInt(ACommand) - 1);
          ACmdInfo.nShow := SW_SHOWNORMAL;
          CM.InvokeCommand(ACmdInfo);
          SubClass.ReloadData;
        end;
      finally
        DestroyMenu(AMenu);
      end;
    end;
  end;
end;

function TACLShellTreeViewSubClassController.GetSubClass: TACLShellTreeViewSubClass;
begin
  Result := TACLShellTreeViewSubClass(inherited SubClass);
end;

{ TACLShellTreeView }

procedure TACLShellTreeView.CreateDirectory(const AFolder: UnicodeString = '');
begin
  SubClass.CreateDirectory(AFolder);
end;

function TACLShellTreeView.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLShellTreeViewSubClass.Create(Self);
end;

function TACLShellTreeView.GetFullPath(ANode: TACLTreeListNode): UnicodeString;
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

function TACLShellTreeView.GetSelectedPath: UnicodeString;
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

procedure TACLShellTreeView.SetSelectedPath(const Value: UnicodeString);
begin
  SubClass.SelectedPath := Value;
end;

end.
