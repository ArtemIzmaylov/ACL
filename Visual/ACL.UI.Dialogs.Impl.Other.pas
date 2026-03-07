////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Fallback to standard Dialogs
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Dialogs.Impl.Other;

{$I ACL.Config.inc}

interface

uses
  Dialogs,
  // ACL
  ACL.UI.Dialogs,
  ACL.Utils.Common;

type

  { TACLFileDialogImpl }

  TACLFileDialogImpl = class
  protected
    FDialog: TACLFileDialog;
    FSaveDialog: Boolean;
  public
    constructor Create(ADialog: TACLFileDialog; ASaveDialog: Boolean);
    function Execute(AOwnerWnd: TWndHandle): Boolean;
  end;

implementation

{ TACLFileDialogImpl }

constructor TACLFileDialogImpl.Create(ADialog: TACLFileDialog; ASaveDialog: Boolean);
begin
  inherited Create;
  FDialog := ADialog;
  FSaveDialog := ASaveDialog;
end;

function TACLFileDialogImpl.Execute(AOwnerWnd: TWndHandle): Boolean;
var
  LDialog: TOpenDialog;
  LOptions: TOpenOptions;
begin
  LOptions := [];
  if ofOverwritePrompt in FDialog.Options then
    Include(LOptions, TOpenOption.ofOverwritePrompt);
  if ofHideReadOnly in FDialog.Options then
    Include(LOptions, TOpenOption.ofHideReadOnly);
  if ofAllowMultiSelect in FDialog.Options then
    Include(LOptions, TOpenOption.ofAllowMultiSelect);
  if ofPathMustExist in FDialog.Options then
    Include(LOptions, TOpenOption.ofPathMustExist);
  if ofFileMustExist in FDialog.Options then
    Include(LOptions, TOpenOption.ofFileMustExist);
  if ofEnableSizing in FDialog.Options then
    Include(LOptions, TOpenOption.ofEnableSizing);
  if ofForceShowHidden in FDialog.Options then
    Include(LOptions, TOpenOption.ofForceShowHidden);

  if FSaveDialog then
    LDialog := TSaveDialog.Create(nil)
  else
    LDialog := TOpenDialog.Create(nil);
  try
    LDialog.Filter := FDialog.Filter;
    LDialog.FilterIndex := FDialog.FilterIndex;
    LDialog.InitialDir := FDialog.GetActualInitialDir;
    LDialog.Options := LOptions;
    Result := LDialog.Execute;
    if Result then
    begin
      FDialog.Files.Assign(LDialog.Files);
      FDialog.FilterIndex := LDialog.FilterIndex;
    end;
  finally
    LDialog.Free;
  end;
end;

end.
