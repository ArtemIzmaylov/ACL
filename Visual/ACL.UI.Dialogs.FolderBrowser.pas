////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Folder Browser Dialog
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Dialogs.FolderBrowser;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.ActiveX,
  Winapi.ShellApi,
  Winapi.ShlObj,
  Winapi.Windows,
{$ENDIF}
  {Winapi.}Messages,
  // System
  System.AnsiStrings,
  {System.}Classes,
  {System.}SysUtils,
  {System.}Types,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Dialogs,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}Themes,
  // ACL
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Parsers,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.ShellTreeView,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Controls.TreeList,
  ACL.UI.Controls.TreeList.Types,
  ACL.UI.Dialogs,
  ACL.UI.Forms,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.FileSystem,
  ACL.Utils.Shell,
  ACL.Utils.Strings;

type
  TACLFolderBrowserOption = (ssoRecursive, ssoMultiPath, ssoCustomPath, ssoLibraryPaths);
  TACLFolderBrowserOptions = set of TACLFolderBrowserOption;

  { TACLShellTreePaths }

  TACLShellTreePaths = class(TACLShellSearchPaths)
  public
    procedure RestoreTo(AView: TACLShellTreeView); virtual;
    procedure StoreFrom(AView: TACLShellTreeView); virtual;
  end;

  { TACLFolderBrowser }

  TACLFolderBrowser = class
  protected const
    ConfigDialog = 'Dialog';
    ConfigMruSuffix = '.MRU';
  strict private
    class var FPrivateConfig: TACLIniFile;
  protected
    class var FIsActive: Boolean;

    class function GetMruItem(const AKey, APath: string): string;
    class procedure SetMruItem(const AKey, APath: string);
    class procedure LoadPosition(ADialog: TACLForm);
    class procedure SavePosition(ADialog: TACLForm; const ADefaultBounds: TRect);
  public
    class constructor Create;
    class destructor Destroy;
    class procedure ConfigLoad(AConfig: TACLIniFile; const ASection: string);
    class procedure ConfigSave(AConfig: TACLIniFile; const ASection: string);

    class function Execute(const ASelectedPath: string; APaths: TACLShellTreePaths;
      var ARecurse: Boolean; AOptions: TACLFolderBrowserOptions; AOwnerWndHandle: HWND = 0;
      const ACaption: string = ''): Boolean; overload;
    class function Execute(const ASelectedPath, AMruKey: string; APaths: TACLShellTreePaths;
      var ARecurse: Boolean; AOptions: TACLFolderBrowserOptions; AOwnerWndHandle: HWND = 0;
      const ACaption: string = ''): Boolean; overload;

    class function Execute(var APath: string;
      AOwnerWndHandle: HWND = 0; const ACaption: string = ''): Boolean; overload;
    class function Execute(var APath: string; const AMruKey: string;
      AOwnerWndHandle: HWND = 0; const ACaption: string = ''): Boolean; overload;
    class function Execute(var APath: string; var ARecurse: Boolean;
      AOwnerWndHandle: HWND = 0; const ACaption: string = ''): Boolean; overload;
    class function Execute(var APath: string; const AMruKey: string; var ARecurse: Boolean;
      AOwnerWndHandle: HWND = 0; const ACaption: string = ''): Boolean; overload;
    class function ExecuteEx(const APath: string;
      AOwnerWndHandle: HWND = 0; const ACaption: string = ''): string;

    class property IsActive: Boolean read FIsActive;
  end;

  { TACLFolderBrowserDialog }

  TACLFolderBrowserDialog = class(TACLForm)
  strict private
    FControlApply: TACLButton;
    FControlCancel: TACLButton;
    FControlCreateNew: TACLButton;
    FControlCustomPath: TACLEdit;
    FControlRecursive: TACLCheckBox;
    FControlShellTree: TACLShellTreeView;
    FCustomPathSynchronizing: Boolean;
    FDefaultBounds: TRect;
    FOwnerHandle: HWND;
    FOptions: TACLFolderBrowserOptions;

    function GetRecurse: Boolean;
    procedure DoCustomPathChanged(Sender: TObject);
    procedure DoNewFolderClick(Sender: TObject);
    procedure DoRecursiveClick(Sender: TObject);
    procedure DoSelectionChanged(Sender: TObject);
    procedure SetRecurse(AValue: Boolean);
    //# Messages
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
  protected const
    ContentOffset = 7;
    ButtonHeight = 23;
    ButtonWidth  = 90;
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure CreateControl(out AControl; AClass: TACLCustomControlClass;
      AAlign: TAlign; AParent: TWinControl = nil);
    procedure CreateCustomControls; virtual;
    procedure CreateParams(var Params: TCreateParams); override;
    function GetConfigSection: string; override;
    procedure InitializeControls; virtual;
    procedure InitializePath(const APath: string);
    procedure LoadSelection(APaths: TACLShellTreePaths);
    procedure SaveSelection(APaths: TACLShellTreePaths);
    procedure PrepareForm;
    procedure UpdateState;
    //# Controls
    property ControlApply: TACLButton read FControlApply;
    property ControlCancel: TACLButton read FControlCancel;
    property ControlCreateNew: TACLButton read FControlCreateNew;
    property ControlCustomPath: TACLEdit read FControlCustomPath;
    property ControlRecursive: TACLCheckBox read FControlRecursive;
    property ControlShellTree: TACLShellTreeView read FControlShellTree;
    property Options: TACLFolderBrowserOptions read FOptions;
  public
    constructor CreateEx(AOwnerWndHandle: HWND; AOptions: TACLFolderBrowserOptions = []);
    destructor Destroy; override;
    function Execute: Boolean;
    function IsShortCut(var Message: TWMKey): Boolean; override;
    // Properties
    property Recurse: Boolean read GetRecurse write SetRecurse;
  end;

implementation

{$IFNDEF FPC}
uses
  ACL.UI.Controls.TreeList.SubClass; // inlining
{$ENDIF}

type
  TACLFormAccess = class(TACLForm);

{ TACLFolderBrowser }

class constructor TACLFolderBrowser.Create;
begin
  FPrivateConfig := TACLIniFile.Create;
end;

class destructor TACLFolderBrowser.Destroy;
begin
  FreeAndNil(FPrivateConfig);
end;

class procedure TACLFolderBrowser.ConfigLoad(AConfig: TACLIniFile; const ASection: string);
begin
  TACLFileDialog.MRUPaths.Text := AConfig.SectionData[ASection + ConfigMruSuffix];
  FPrivateConfig.SectionData[ConfigDialog] := AConfig.SectionData[ASection];
end;

class procedure TACLFolderBrowser.ConfigSave(AConfig: TACLIniFile; const ASection: string);
begin
  AConfig.SectionData[ASection] := FPrivateConfig.SectionData[ConfigDialog];
  AConfig.SectionData[ASection + ConfigMruSuffix] := TACLFileDialog.MRUPaths.Text;
end;

class function TACLFolderBrowser.Execute(const ASelectedPath: string;
  APaths: TACLShellTreePaths; var ARecurse: Boolean; AOptions: TACLFolderBrowserOptions;
  AOwnerWndHandle: HWND; const ACaption: string): Boolean;
var
  ABrowser: TACLFolderBrowserDialog;
begin
  Result := False;
  if not IsActive then
  begin
    ABrowser := TACLFolderBrowserDialog.CreateEx(AOwnerWndHandle, AOptions);
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

class function TACLFolderBrowser.Execute(const ASelectedPath, AMruKey: string;
  APaths: TACLShellTreePaths; var ARecurse: Boolean; AOptions: TACLFolderBrowserOptions;
  AOwnerWndHandle: HWND = 0; const ACaption: string = ''): Boolean;
begin
  Result := Execute(GetMruItem(AMruKey, ASelectedPath),
    APaths, ARecurse, AOptions, AOwnerWndHandle, ACaption);
  if Result and (APaths.Count > 0) then
    SetMruItem(AMruKey, APaths[0]);
end;

class function TACLFolderBrowser.Execute(
  var APath: string; AOwnerWndHandle: HWND; const ACaption: string): Boolean;
begin
  Result := Execute(APath, '', AOwnerWndHandle, ACaption);
end;

class function TACLFolderBrowser.Execute(var APath: string;
  var ARecurse: Boolean; AOwnerWndHandle: HWND; const ACaption: string): Boolean;
begin
  Result := Execute(APath, '', ARecurse, AOwnerWndHandle, ACaption);
end;

class function TACLFolderBrowser.Execute(var APath: string;
  const AMruKey: string; AOwnerWndHandle: HWND; const ACaption: string): Boolean;
var
  APaths: TACLShellTreePaths;
  ARecurse: Boolean;
begin
  APaths := TACLShellTreePaths.Create;
  try
    ARecurse := False;
    Result := Execute(APath, AMruKey, APaths, ARecurse, [ssoCustomPath], AOwnerWndHandle, ACaption);
    if Result and (APaths.Count > 0) then
      APath := APaths[0];
  finally
    APaths.Free;
  end;
end;

class function TACLFolderBrowser.Execute(var APath: string;
  const AMruKey: string; var ARecurse: Boolean; AOwnerWndHandle: HWND;
  const ACaption: string): Boolean;
var
  APaths: TACLShellTreePaths;
begin
  APaths := TACLShellTreePaths.Create;
  try
    Result := Execute(APath, AMruKey, APaths, ARecurse,
      [ssoRecursive, ssoCustomPath], AOwnerWndHandle, ACaption);
    if Result and (APaths.Count > 0) then
      APath := APaths[0];
  finally
    APaths.Free;
  end;
end;

class function TACLFolderBrowser.ExecuteEx(
  const APath: string; AOwnerWndHandle: HWND;
  const ACaption: string): string;
begin
  Result := APath;
  if not Execute(Result, AOwnerWndHandle, ACaption) then
    Result := APath;
end;

class function TACLFolderBrowser.GetMruItem(const AKey, APath: string): string;
begin
  if (AKey <> '') and (APath = '') then
    Result := TACLFileDialog.MRUPaths.ValueFromName[AKey]
  else
    Result := APath;
end;

class procedure TACLFolderBrowser.LoadPosition(ADialog: TACLForm);
begin
  ADialog.LoadPosition(FPrivateConfig);
end;

class procedure TACLFolderBrowser.SavePosition(
  ADialog: TACLForm; const ADefaultBounds: TRect);
begin
  if EqualRect(ADialog.BoundsRect, ADefaultBounds) then
    FPrivateConfig.DeleteSection(TACLFormAccess(ADialog).GetConfigSection)
  else
    ADialog.SavePosition(FPrivateConfig);
end;

class procedure TACLFolderBrowser.SetMruItem(const AKey, APath: string);
begin
  if (AKey <> '') and (APath <> '') then
    TACLFileDialog.MRUPaths.ValueFromName[AKey] := APath;
end;

{ TACLFolderBrowserDialog }

constructor TACLFolderBrowserDialog.CreateEx(
  AOwnerWndHandle: HWND; AOptions: TACLFolderBrowserOptions = []);
var
  AControl: TWinControl;
begin
  TACLFolderBrowser.FIsActive := True;
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
  TACLFolderBrowser.LoadPosition(Self);
  UpdateState;
end;

destructor TACLFolderBrowserDialog.Destroy;
begin
  TACLFolderBrowser.FIsActive := False;
  inherited Destroy;
end;

procedure TACLFolderBrowserDialog.AdjustClientRect(var Rect: TRect);
begin
  Rect.Inflate(-dpiApply(ContentOffset, FCurrentPPI));
end;

procedure TACLFolderBrowserDialog.CreateControl(out AControl;
  AClass: TACLCustomControlClass; AAlign: TAlign; AParent: TWinControl);
begin
  if AParent = nil then
    AParent := Self;

  TACLCustomControl(AControl) := AClass.Create(Self);
  TACLCustomControl(AControl).Parent := AParent;
  TACLCustomControl(AControl).AlignWithMargins := True;
  TACLCustomControl(AControl).Align := AAlign;
end;

procedure TACLFolderBrowserDialog.CreateCustomControls;
begin
  if ssoCustomPath in Options then
  begin
    CreateControl(FControlCustomPath, TACLEdit, alBottom);
    ControlCustomPath.OnChange := DoCustomPathChanged;
  end;
end;

procedure TACLFolderBrowserDialog.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if FOwnerHandle <> 0 then
    Params.WndParent := FOwnerHandle;
end;

procedure TACLFolderBrowserDialog.DoCustomPathChanged(Sender: TObject);
begin
  if not FCustomPathSynchronizing then
  begin
    FCustomPathSynchronizing := True;
    ControlShellTree.FocusedNode := nil;
    FCustomPathSynchronizing := False;
  end;
  UpdateState;
end;

procedure TACLFolderBrowserDialog.DoNewFolderClick(Sender: TObject);
begin
  ControlShellTree.CreateDirectory(TACLDialogsStrs.FolderBrowserNewFolder);
end;

procedure TACLFolderBrowserDialog.DoRecursiveClick(Sender: TObject);
begin
  ControlShellTree.OptionsBehavior.AutoCheckChildren := ControlRecursive.Checked;
end;

procedure TACLFolderBrowserDialog.DoSelectionChanged(Sender: TObject);
begin
  ControlCreateNew.Enabled := ControlShellTree.FocusedNode <> nil;
  if ControlCustomPath <> nil then
  begin
    if not FCustomPathSynchronizing then
    begin
      FCustomPathSynchronizing := True;
      ControlCustomPath.Text := ControlShellTree.SelectedPath;
      FCustomPathSynchronizing := False;
    end;
  end;
  UpdateState;
end;

function TACLFolderBrowserDialog.Execute: Boolean;
begin
  Result := ShowModal = mrOk;
  TACLFolderBrowser.SavePosition(Self, FDefaultBounds);
end;

procedure TACLFolderBrowserDialog.InitializeControls;
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

  CreateCustomControls;

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

procedure TACLFolderBrowserDialog.InitializePath(const APath: string);
begin
  ControlShellTree.HandleNeeded;
  ControlShellTree.SelectedPath := APath;
end;

function TACLFolderBrowserDialog.IsShortCut(var Message: TWMKey): Boolean;
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

procedure TACLFolderBrowserDialog.PrepareForm;
begin
  Caption := TACLDialogsStrs.FolderBrowserCaption;
  BorderIcons := [biSystemMenu];
  Position := poOwnerFormCenter;
end;

function TACLFolderBrowserDialog.GetConfigSection: string;
begin
  Result := TACLFolderBrowser.ConfigDialog;
end;

function TACLFolderBrowserDialog.GetRecurse: Boolean;
begin
  Result := Assigned(ControlRecursive) and ControlRecursive.Checked;
end;

procedure TACLFolderBrowserDialog.LoadSelection(APaths: TACLShellTreePaths);
begin
  APaths.RestoreTo(ControlShellTree);
end;

procedure TACLFolderBrowserDialog.SaveSelection(APaths: TACLShellTreePaths);
var
  APath: string;
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

procedure TACLFolderBrowserDialog.SetRecurse(AValue: Boolean);
begin
  if ControlRecursive <> nil then
    ControlRecursive.ChangeState(AValue);
end;

procedure TACLFolderBrowserDialog.UpdateState;
begin
  ControlApply.Enabled :=
    (ControlShellTree.OptionsView.CheckBoxes) or
    (ControlShellTree.SelectedPath <> '');
end;

procedure TACLFolderBrowserDialog.CMVisibleChanged(var Message: TMessage);
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
    APath: string;
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
