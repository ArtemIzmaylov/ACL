{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*            Shell Browse Dialog            *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Dialogs.FolderBrowser;

{$I ACL.Config.Inc}

interface

uses
  Winapi.ActiveX,
  Winapi.Messages,
  Winapi.ShellApi,
  Winapi.ShlObj,
  Winapi.Windows,
  // System
  System.AnsiStrings,
  System.Classes,
  System.Math,
  System.SysUtils,
  System.Types,
  System.Win.ComObj,
  // Vcl
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.StdCtrls,
  Vcl.Themes,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Parsers,
  ACL.FileFormats.INI,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ShellTreeView,
  ACL.UI.Forms,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Desktop,
  ACL.Utils.DPIAware,
  ACL.Utils.Shell;

type

  { TACLShellTreePaths }

  TACLShellTreePaths = class(TACLShellSearchPaths)
  public
    procedure RestoreTo(AView: TACLShellTreeView); virtual;
    procedure StoreFrom(AView: TACLShellTreeView); virtual;
  end;

  TACLShellSelectOption = (ssoRecursive, ssoMultiPath, ssoCustomPath, ssoLibraryPaths);
  TACLShellSelectOptions = set of TACLShellSelectOption;

  { TACLShellFolderBrowser }

  TACLShellFolderBrowser = class
  protected const
    ConfigDialog = 'Dialog';
    ConfigMruSuffix = '.MRU';
  strict private
    class var FPrivateConfig: TACLIniFile;
  protected
    class function GetMruItem(const AKey, APath: string): string;
    class procedure SetMruItem(const AKey, APath: string);
    class procedure LoadPosition(ADialog: TACLForm);
    class procedure SavePosition(ADialog: TACLForm; const ADefaultBounds: TRect);
  public
    class constructor Create;
    class destructor Destroy;
    class procedure ConfigLoad(AConfig: TACLIniFile; const ASection: string);
    class procedure ConfigSave(AConfig: TACLIniFile; const ASection: string);

    class function Execute(const ASelectedPath: UnicodeString; APaths: TACLShellTreePaths;
      var ARecurse: Boolean; AOptions: TACLShellSelectOptions; AOwnerWndHandle: THandle = 0;
      const ACaption: string = ''): Boolean; overload;
    class function Execute(const ASelectedPath, AMruKey: UnicodeString; APaths: TACLShellTreePaths;
      var ARecurse: Boolean; AOptions: TACLShellSelectOptions; AOwnerWndHandle: THandle = 0;
      const ACaption: string = ''): Boolean; overload;

    class function Execute(var APath: UnicodeString;
      AOwnerWndHandle: THandle = 0; const ACaption: string = ''): Boolean; overload;
    class function Execute(var APath: UnicodeString; const AMruKey: string;
      AOwnerWndHandle: THandle = 0; const ACaption: string = ''): Boolean; overload;
    class function Execute(var APath: UnicodeString; var ARecurse: Boolean;
      AOwnerWndHandle: THandle = 0; const ACaption: string = ''): Boolean; overload;
    class function Execute(var APath: UnicodeString; const AMruKey: string; var ARecurse: Boolean;
      AOwnerWndHandle: THandle = 0; const ACaption: string = ''): Boolean; overload;
    class function ExecuteEx(const APath: UnicodeString;
      AOwnerWndHandle: THandle = 0; const ACaption: string = ''): UnicodeString;

    class function IsActive: Boolean;
  end;

implementation

uses
  ACL.UI.Dialogs,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Controls.TreeList,
  ACL.Utils.Strings;

const
  ContentOffset = 7;
  ButtonHeight = 23;
  ButtonWidth  = 90;

type
  TACLFormAccess = class(TACLForm);

  { TACLShellFolderBrowserDialog }

  TACLShellFolderBrowserDialog = class(TACLForm)
  strict private
    FControlApply: TACLButton;
    FControlCancel: TACLButton;
    FControlCreateNew: TACLButton;
    FControlCustomPath: TACLEdit;
    FControlRecursive: TACLCheckBox;
    FControlShellTree: TACLShellTreeView;
    FCustomPathSynchronizing: Boolean;
    FDefaultBounds: TRect;
    FOwnerHandle: THandle;
    FOptions: TACLShellSelectOptions;

    function GetRecurse: Boolean;
    procedure DoCustomPathChanged(Sender: TObject);
    procedure DoNewFolderClick(Sender: TObject);
    procedure DoRecursiveClick(Sender: TObject);
    procedure DoSelectionChanged(Sender: TObject);
    procedure SetRecurse(AValue: Boolean);
    //
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure CreateParams(var Params: TCreateParams); override;
    function GetConfigSection: string; override;
    procedure InitializeControls;
    procedure InitializePath(const APath: UnicodeString);
    procedure PrepareForm;
    procedure LoadSelection(APaths: TACLShellTreePaths);
    procedure SaveSelection(APaths: TACLShellTreePaths);
    //
    property ControlApply: TACLButton read FControlApply;
    property ControlCancel: TACLButton read FControlCancel;
    property ControlCreateNew: TACLButton read FControlCreateNew;
    property ControlCustomPath: TACLEdit read FControlCustomPath;
    property ControlRecursive: TACLCheckBox read FControlRecursive;
    property ControlShellTree: TACLShellTreeView read FControlShellTree;
    property Options: TACLShellSelectOptions read FOptions;
  public
    constructor CreateEx(AOwnerWndHandle: THandle; AOptions: TACLShellSelectOptions = []);
    destructor Destroy; override;
    function Execute: Boolean;
    function IsShortCut(var Message: TWMKey): Boolean; override;
    // Properties
    property Recurse: Boolean read GetRecurse write SetRecurse;
  end;

var
  ShellIsDialogActive: Boolean;

{ TACLShellFolderBrowser }

class constructor TACLShellFolderBrowser.Create;
begin
  FPrivateConfig := TACLIniFile.Create;
end;

class destructor TACLShellFolderBrowser.Destroy;
begin
  FreeAndNil(FPrivateConfig);
end;

class procedure TACLShellFolderBrowser.ConfigLoad(AConfig: TACLIniFile; const ASection: string);
begin
  TACLFileDialog.MRUPaths.Text := AConfig.SectionData[ASection + ConfigMruSuffix];
  FPrivateConfig.SectionData[ConfigDialog] := AConfig.SectionData[ASection];
end;

class procedure TACLShellFolderBrowser.ConfigSave(AConfig: TACLIniFile; const ASection: string);
begin
  AConfig.SectionData[ASection] := FPrivateConfig.SectionData[ConfigDialog];
  AConfig.SectionData[ASection + ConfigMruSuffix] := TACLFileDialog.MRUPaths.Text;
end;

class function TACLShellFolderBrowser.Execute(const ASelectedPath: UnicodeString; APaths: TACLShellTreePaths;
  var ARecurse: Boolean; AOptions: TACLShellSelectOptions; AOwnerWndHandle: THandle; const ACaption: string): Boolean;
var
  ABrowser: TACLShellFolderBrowserDialog;
begin
  Result := False;
  if not IsActive then
  begin
    ABrowser := TACLShellFolderBrowserDialog.CreateEx(AOwnerWndHandle, AOptions);
    try
      ABrowser.Recurse := ARecurse;
      ABrowser.InitializePath(ASelectedPath);
      if ACaption <> '' then
        ABrowser.Caption := ACaption;
      if ASelectedPath = '' then
        ABrowser.LoadSelection(APaths);
      if ABrowser.Execute then
      begin
        ABrowser.SaveSelection(APaths);
        ARecurse := ABrowser.Recurse;
        Result := APaths.Count > 0;
      end;
    finally
      ABrowser.Free;
    end;
  end;
end;

class function TACLShellFolderBrowser.Execute(const ASelectedPath, AMruKey: UnicodeString;
  APaths: TACLShellTreePaths; var ARecurse: Boolean; AOptions: TACLShellSelectOptions;
  AOwnerWndHandle: THandle = 0; const ACaption: string = ''): Boolean;
begin
  Result := Execute(GetMruItem(AMruKey, ASelectedPath), APaths, ARecurse, AOptions, AOwnerWndHandle, ACaption);
  if Result and (APaths.Count > 0) then
    SetMruItem(AMruKey, APaths[0]);
end;

class function TACLShellFolderBrowser.Execute(var APath: UnicodeString; AOwnerWndHandle: THandle; const ACaption: string): Boolean;
begin
  Result := Execute(APath, '', AOwnerWndHandle, ACaption);
end;

class function TACLShellFolderBrowser.Execute(var APath: UnicodeString;
  var ARecurse: Boolean; AOwnerWndHandle: THandle; const ACaption: string): Boolean;
begin
  Result := Execute(APath, '', ARecurse, AOwnerWndHandle, ACaption);
end;

class function TACLShellFolderBrowser.Execute(var APath: UnicodeString;
  const AMruKey: string; AOwnerWndHandle: THandle; const ACaption: string): Boolean;
var
  APaths: TACLShellTreePaths;
  ARecurse: Boolean;
begin
  APaths := TACLShellTreePaths.Create;
  try
    Result := Execute(APath, AMruKey, APaths, ARecurse, [ssoCustomPath], AOwnerWndHandle, ACaption);
    if Result and (APaths.Count > 0) then
      APath := APaths[0];
  finally
    APaths.Free;
  end;
end;

class function TACLShellFolderBrowser.Execute(var APath: UnicodeString;
  const AMruKey: string; var ARecurse: Boolean; AOwnerWndHandle: THandle; const ACaption: string): Boolean;
var
  APaths: TACLShellTreePaths;
begin
  APaths := TACLShellTreePaths.Create;
  try
    Result := Execute(APath, AMruKey, APaths, ARecurse, [ssoRecursive, ssoCustomPath], AOwnerWndHandle, ACaption);
    if Result and (APaths.Count > 0) then
      APath := APaths[0];
  finally
    APaths.Free;
  end;
end;

class function TACLShellFolderBrowser.ExecuteEx(const APath: UnicodeString; AOwnerWndHandle: THandle; const ACaption: string): UnicodeString;
begin
  Result := APath;
  if not Execute(Result, AOwnerWndHandle, ACaption) then
    Result := APath;
end;

class function TACLShellFolderBrowser.GetMruItem(const AKey, APath: string): string;
begin
  if (AKey <> '') and (APath = '') then
    Result := TACLFileDialog.MRUPaths.ValueFromName[AKey]
  else
    Result := APath;
end;

class function TACLShellFolderBrowser.IsActive: Boolean;
begin
  Result := ShellIsDialogActive;
end;

class procedure TACLShellFolderBrowser.LoadPosition(ADialog: TACLForm);
begin
  ADialog.LoadPosition(FPrivateConfig);
end;

class procedure TACLShellFolderBrowser.SavePosition(ADialog: TACLForm; const ADefaultBounds: TRect);
begin
  if EqualRect(ADialog.BoundsRect, ADefaultBounds) then
    FPrivateConfig.DeleteSection(TACLFormAccess(ADialog).GetConfigSection)
  else
    ADialog.SavePosition(FPrivateConfig);
end;

class procedure TACLShellFolderBrowser.SetMruItem(const AKey, APath: string);
begin
  if (AKey <> '') and (APath <> '') then
    TACLFileDialog.MRUPaths.ValueFromName[AKey] := APath;
end;

{ TACLShellFolderBrowserDialog }

constructor TACLShellFolderBrowserDialog.CreateEx(AOwnerWndHandle: THandle; AOptions: TACLShellSelectOptions = []);
var
  AControl: TWinControl;
begin
  ShellIsDialogActive := True;
  FOwnerHandle := AOwnerWndHandle;
  AControl := FindControl(AOwnerWndHandle);
  if AControl <> nil then
    AControl := GetParentForm(AControl);
  inherited CreateNew(AControl);
  DoubleBuffered := True;
  SetBounds(Left, Top, dpiApply(360, FCurrentPPI), dpiApply(450, FCurrentPPI));
  Constraints.MinHeight := dpiApply(450, FCurrentPPI);
  Constraints.MinWidth := dpiApply(360, FCurrentPPI);
  PrepareForm;
  FOptions := AOptions;
  InitializeControls;
  TACLShellFolderBrowser.LoadPosition(Self);
end;

destructor TACLShellFolderBrowserDialog.Destroy;
begin
  ShellIsDialogActive := False;
  inherited Destroy;
end;

procedure TACLShellFolderBrowserDialog.AdjustClientRect(var Rect: TRect);
begin
  Rect.Inflate(-dpiApply(ContentOffset, FCurrentPPI));
end;

procedure TACLShellFolderBrowserDialog.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if FOwnerHandle <> 0 then
    Params.WndParent := FOwnerHandle;
end;

procedure TACLShellFolderBrowserDialog.DoCustomPathChanged(Sender: TObject);
begin
  if not FCustomPathSynchronizing then
  begin
    FCustomPathSynchronizing := True;
    ControlShellTree.FocusedNode := nil;
    FCustomPathSynchronizing := False;
  end;
end;

procedure TACLShellFolderBrowserDialog.DoNewFolderClick(Sender: TObject);
begin
  ControlShellTree.CreateDirectory(TACLDialogsStrs.FolderBrowserNewFolder);
end;

procedure TACLShellFolderBrowserDialog.DoRecursiveClick(Sender: TObject);
begin
  ControlShellTree.OptionsBehavior.AutoCheckChildren := ControlRecursive.Checked;
end;

procedure TACLShellFolderBrowserDialog.DoSelectionChanged(Sender: TObject);
begin
  ControlCreateNew.Enabled := ControlShellTree.FocusedNode <> nil;
  if ControlCustomPath <> nil then
  begin
    if not FCustomPathSynchronizing then
    begin
      FCustomPathSynchronizing := True;
      ControlCustomPath.Text := ControlShellTree.GetFullPath(ControlShellTree.FocusedNode);
      FCustomPathSynchronizing := False;
    end;
  end;
end;

function TACLShellFolderBrowserDialog.Execute: Boolean;
begin
  Result := ShowModal = mrOk;
  TACLShellFolderBrowser.SavePosition(Self, FDefaultBounds);
end;

procedure TACLShellFolderBrowserDialog.InitializeControls;

  procedure CreateControl(var AControl; AClass: TControlClass; AAlign: TAlign; AParent: TWinControl = nil);
  begin
    if AParent = nil then
      AParent := Self;

    TControl(AControl) := AClass.Create(Self);
    TControl(AControl).Parent := AParent;
    TControl(AControl).AlignWithMargins := True;
    TControl(AControl).Align := AAlign;
  end;

var
  APanel: TACLCustomControl;
begin
  if ssoRecursive in Options then
  begin
    CreateControl(FControlRecursive, TACLCheckBox, alTop);
    ControlRecursive.Caption := TACLDialogsStrs.FolderBrowserRecursive;
    ControlRecursive.OnClick := DoRecursiveClick;
  end;

  CreateControl(FControlShellTree, TACLShellTreeView, alClient);
  ControlShellTree.OptionsBehavior.AllowLibraryPaths := ssoLibraryPaths in Options;
  ControlShellTree.OptionsView.CheckBoxes := ssoMultiPath in Options;
  ControlShellTree.OnFocusedNodeChanged := DoSelectionChanged;
  ActiveControl := ControlShellTree;

  if ssoCustomPath in Options then
  begin
    CreateControl(FControlCustomPath, TACLEdit, alBottom);
    ControlCustomPath.OnChange := DoCustomPathChanged;
  end;

  CreateControl(APanel, TACLCustomControl, alBottom);
  APanel.AlignWithMargins := False;
  APanel.Height := dpiApply(ButtonHeight, FCurrentPPI) + 2 * dpiApply(3, FCurrentPPI);

  CreateControl(FControlCreateNew, TACLButton, alLeft, APanel);
  ControlCreateNew.Width := dpiApply(ButtonWidth, FCurrentPPI);
  ControlCreateNew.Caption := TACLDialogsStrs.FolderBrowserNewFolder;
  ControlCreateNew.OnClick := DoNewFolderClick;
  ControlCreateNew.Visible := [ssoMultiPath, ssoRecursive] * Options = [];
  ControlCreateNew.Enabled := False;

  CreateControl(FControlApply, TACLButton, alRight, APanel);
  ControlApply.Width := dpiApply(ButtonWidth, FCurrentPPI);
  ControlApply.Caption := TACLDialogsStrs.MsgDlgButtons[mbOk];
  ControlApply.ModalResult := mrOk;

  CreateControl(FControlCancel, TACLButton, alRight, APanel);
  ControlCancel.Width := dpiApply(ButtonWidth, FCurrentPPI);
  ControlCancel.Caption := TACLDialogsStrs.MsgDlgButtons[mbCancel];
  ControlCancel.ModalResult := mrCancel;
end;

procedure TACLShellFolderBrowserDialog.InitializePath(const APath: UnicodeString);
begin
  ControlShellTree.HandleNeeded;
  ControlShellTree.SelectedPath := APath;
end;

function TACLShellFolderBrowserDialog.IsShortCut(var Message: TWMKey): Boolean;
begin
  Result := True;
  case Message.CharCode of
    VK_RETURN:
      ModalResult := mrOk;
    VK_ESCAPE:
      ModalResult := mrCancel;
  else
    Result := False;
  end;
end;

procedure TACLShellFolderBrowserDialog.PrepareForm;
begin
  Caption := TACLDialogsStrs.FolderBrowserCaption;
  BorderIcons := [biSystemMenu];
  Position := poOwnerFormCenter;
end;

function TACLShellFolderBrowserDialog.GetConfigSection: string;
begin
  Result := TACLShellFolderBrowser.ConfigDialog;
end;

function TACLShellFolderBrowserDialog.GetRecurse: Boolean;
begin
  Result := Assigned(ControlRecursive) and ControlRecursive.Checked;
end;

procedure TACLShellFolderBrowserDialog.LoadSelection(APaths: TACLShellTreePaths);
begin
  APaths.RestoreTo(ControlShellTree);
end;

procedure TACLShellFolderBrowserDialog.SaveSelection(APaths: TACLShellTreePaths);
var
  APath: UnicodeString;
begin
  APaths.StoreFrom(ControlShellTree);
  if (ControlCustomPath <> nil) and (APaths.Count = 0) then
  begin
    APath := acTrim(ControlCustomPath.Text);
    acUnquot(APath);
    if not APaths.ContainsPathPart(APath) then
      APaths.Add(APath, Recurse);
  end;
end;

procedure TACLShellFolderBrowserDialog.SetRecurse(AValue: Boolean);
begin
  if ControlRecursive <> nil then
    ControlRecursive.ChangeState(AValue);
end;

procedure TACLShellFolderBrowserDialog.CMVisibleChanged(var Message: TMessage);
begin
  inherited;
  if Visible and (Position <> poDesigned) then
    FDefaultBounds := BoundsRect;
end;

{ TACLShellTreePaths }

procedure TACLShellTreePaths.RestoreTo(AView: TACLShellTreeView);

  procedure RestoreState(ANode: TACLTreeListNode; ARecursive: Boolean);
  begin
    if not ARecursive and AView.OptionsBehavior.AutoCheckChildren then
    begin
      AView.OptionsBehavior.AutoCheckChildren := False;
      ANode.Expanded := True;
      ANode.Checked := True;
      AView.OptionsBehavior.AutoCheckChildren := True;
    end
    else
      ANode.Checked := True;
  end;

var
  I: Integer;
begin
  AView.BeginUpdate;
  try
    for I := 0 to Count - 1 do
    begin
      AView.SelectedPath := Paths[I];
      if AView.FocusedNode <> nil then
        RestoreState(AView.FocusedNode, Recursive[I]);
    end;
  finally
    AView.EndUpdate;
  end;
end;

procedure TACLShellTreePaths.StoreFrom(AView: TACLShellTreeView);

  procedure DoAddPath(ANode: TACLTreeListNode; ARecursive: Boolean);
  var
    APath: UnicodeString;
  begin
    APath := AView.GetFullPath(ANode);
    if APath <> '' then
      Add(APath, ARecursive);
  end;

  function AddFolderNode(ANode: TACLTreeListNode): Integer;
  var
    ASubNodeIndex: Integer;
  begin
    Result := Ord(ANode.Checked);
    if ANode.Checked then
      DoAddPath(ANode, not (ANode.ChildrenLoaded and ANode.HasChildren));
    if ANode.ChildrenLoaded then
    begin
      for ASubNodeIndex := 0 to ANode.ChildrenCount - 1 do
        Inc(Result, AddFolderNode(ANode.Children[ASubNodeIndex]));
    end;
  end;

begin
  Clear;
  if AddFolderNode(AView.RootNode) = 0 then
  begin
    if AView.FocusedNode <> nil then
      DoAddPath(AView.FocusedNode, True);
  end;
end;

end.
