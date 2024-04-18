{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*          Common Dialogs Wrappes           *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Dialogs;

{$I ACL.Config.inc} // FPC:OK
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ELSE}
  LCLIntf,
  LCLType,
  LMessages,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  {System.}Variants,
  // Vcl
  {Vcl.}ActnList,
  {Vcl.}Controls,
  {Vcl.}Dialogs,
  {Vcl.}ExtCtrls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}Menus,
  {Vcl.}StdCtrls,
{$IFDEF MSWINDOWS}
  Vcl.Consts,
{$ENDIF}
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Graphics,
  ACL.MUI,
  ACL.Threading,
  ACL.UI.AeroPeek,
  ACL.UI.Application,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.ImageComboBox,
  ACL.UI.Controls.Labels,
  ACL.UI.Controls.Memo,
  ACL.UI.Controls.ProgressBar,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Forms,
  ACL.UI.ImageList,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

type

  { TACLCustomDialog }

  TACLCustomDialog = class(TACLForm)
  protected const
    ButtonHeight = 25;
    ButtonWidth = 96;
  protected
    function CanApply: Boolean; virtual;
    procedure CreateParams(var Params: TCreateParams); override;
    function DialogChar(var Message: TWMKey): Boolean; override;
    procedure DoApply(Sender: TObject = nil); virtual;
  public
    procedure AfterConstruction; override;
    function IsShortCut(var Message: TWMKey): Boolean; override;
  end;

{$REGION ' FileDialogs '}

  { TACLFileDialog }

  TACLFileDialogImpl = class;

  TACLFileDialogOption = (ofOverwritePrompt, ofHideReadOnly, ofAllowMultiSelect,
    ofPathMustExist, ofFileMustExist, ofEnableSizing, ofForceShowHidden, ofAutoExtension);
  TACLFileDialogOptions = set of TACLFileDialogOption;

  TACLFileDialog = class(TComponent)
  public const
    DefaultOptions = [ofHideReadOnly, ofEnableSizing, ofOverwritePrompt, ofAutoExtension];
  strict private
    FFileName: string;
    FFiles: TACLStringList;
    FFilter: string;
    FFilterIndex: Integer;
    FInitialDir: string;
    FMRUId: string;
    FOptions: TACLFileDialogOptions;
    FTitle: string;
  protected
    function AutoExtension(const AFileName: string): string;
    function CreateImpl(ASaveDialog: Boolean; AOwnerWnd: HWND = 0): TACLFileDialogImpl; virtual;
    function GetActualInitialDir: string;
  public
    class var MRUPaths: TACLStringList;
  public
    class constructor Create;
    class destructor Destroy;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute(ASaveDialog: Boolean; AOwnerWnd: HWND = 0): Boolean; virtual;
    //# Properties
    property FileName: string read FFilename write FFileName;
    property Files: TACLStringList read FFiles;
    property InitialDir: string read FInitialDir write FInitialDir;
  published
    property Filter: string read FFilter write FFilter;
    property FilterIndex: Integer read FFilterIndex write FFilterIndex default 0;
    property MRUId: string read FMRUId write FMRUId;
    property Options: TACLFileDialogOptions read FOptions write FOptions default DefaultOptions;
    property Title: string read FTitle write FTitle;
  end;

  { TACLFileDialogImpl }

  TACLFileDialogImpl = class(TACLUnknownObject)
  strict private
    FDialog: TACLFileDialog;
    FSaveDialog: Boolean;
  protected
    FDefaultExts: string;
    FParentWnd: HWND;
    procedure PopulateDefaultExts;
  public
    constructor Create(AParentWnd: HWND;
      ADialog: TACLFileDialog; ASaveDialog: Boolean); virtual;
    function Execute: Boolean; virtual;
    //# Properties
    property Dialog: TACLFileDialog read FDialog;
    property ParentWnd: HWND read FParentWnd;
    property SaveDialog: Boolean read FSaveDialog;
  end;
{$ENDREGION}

{$REGION ' InputDialogs '}

  { TACLCustomInputDialog }

  TACLCustomInputDialog = class abstract(TACLCustomDialog)
  strict private
    FButtonApply: TACLButton;
    FButtonCancel: TACLButton;
    FButtonOK: TACLButton;
    FHasChanges: Boolean;
    FPrevClientRect: TRect;
  protected
    procedure AfterFormCreate; override;
    procedure CreateControls; virtual;
    procedure SetHasChanges(AValue: Boolean);

    procedure DoApply(Sender: TObject = nil); override;
    procedure DoCancel(Sender: TObject = nil); virtual;
    procedure DoModified(Sender: TObject = nil); virtual;
    procedure DoShow; override;
    procedure DoUpdateState;

    // Layout
    procedure DpiChanged; override;
    procedure PlaceControls(var R: TRect); virtual;
    procedure Resize; override;

    property ButtonApply: TACLButton read FButtonApply;
    property ButtonCancel: TACLButton read FButtonCancel;
    property ButtonOK: TACLButton read FButtonOK;
  end;

  { TACLCustomInputQueryDialog }

  TACLCustomInputQueryDialog = class abstract(TACLCustomInputDialog)
  strict private
    FEditors: TACLObjectList<TWinControl>;
    FLabels: TACLObjectList<TACLLabel>;
  protected
    procedure CreateEditors(AValueCount: Integer); virtual;
    function GetEditClass: TControlClass; virtual; abstract;
    procedure Initialize(AValueCount: Integer);
    procedure InitializeEdit(AEdit: TWinControl); virtual; abstract;
    procedure PlaceControl(var R: TRect; AControl: TControl; AIndent: Integer);
    procedure PlaceControls(var R: TRect); override;
    procedure PlaceEditors(var R: TRect); virtual;
    //# Properties
    property Editors: TACLObjectList<TWinControl> read FEditors;
    property Labels: TACLObjectList<TACLLabel> read FLabels;
  public
    destructor Destroy; override;
  end;

  { TACLInputQueryDialog }

  TACLInputQueryValidateEvent = reference to procedure (Sender: TObject;
    const AValueIndex: Integer; const AValue: string; var AIsValid: Boolean);

  TACLInputQueryDialog = class(TACLCustomInputQueryDialog)
  strict private
    FOnValidate: TACLInputQueryValidateEvent;
  protected
    function CanApply: Boolean; override;
    procedure DoModified(Sender: TObject = nil); override;
    function GetEditClass: TControlClass; override;
    function GetFieldValue(AIndex: Integer): Variant;
    procedure InitializeEdit(AEdit: TWinControl); override;
  protected
    procedure InitializeField(AIndex: Integer; const AFieldName: string;
      const AValue: Variant; ASelStart: Integer = 0; ASelLength: Integer = MaxInt);
    //# Events
    property OnValidate: TACLInputQueryValidateEvent read FOnValidate write FOnValidate;
  public
    class function Execute(const ACaption, APrompt: string; var AStr: string;
      AOwner: TComponent = nil; AValidateEvent: TACLInputQueryValidateEvent = nil): Boolean; overload;
    class function Execute(const ACaption, APrompt: string; var AStr: string;
      ASelStart, ASelLength: Integer; AOwner: TComponent = nil;
      AValidateEvent: TACLInputQueryValidateEvent = nil): Boolean; overload;
    class function Execute(const ACaption: string; const APrompt: string;
      var AValue: Variant; AOwner: TComponent = nil;
      AValidateEvent: TACLInputQueryValidateEvent = nil): Boolean; overload;
    class function Execute(const ACaption: string; const APrompts: array of string;
      var AValues: array of Variant; AOwner: TComponent = nil;
      AValidateEvent: TACLInputQueryValidateEvent = nil): Boolean; overload;
  end;

  { TACLMemoQueryDialog }

  TACLMemoQueryDialog = class(TACLCustomInputDialog)
  strict private class var
    FDialogSize: TSize;
    FDialogSizeAssigned: Boolean;
  strict private
    FMemo: TACLMemo;
    procedure HandleKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PrepareDialogSize;
  protected
    procedure CreateControls; override;
    procedure PlaceControls(var R: TRect); override;
    //# Properties
    property Memo: TACLMemo read FMemo;
  public
    constructor Create(AOwnerHandle: HWND); reintroduce;
    class function Execute(const ACaption: string; AItems: TStrings;
      APopupMenu: TPopupMenu = nil; AOwnerHandle: HWND = 0): Boolean; overload;
    class function Execute(const ACaption: string; var AText: string;
      APopupMenu: TPopupMenu = nil; AOwnerHandle: HWND = 0): Boolean; overload;
  end;

  { TACLSelectQueryDialog }

  TACLSelectQueryDialog = class(TACLCustomInputQueryDialog)
  strict private
    function GetEditor: TACLComboBox;
    procedure SelectHandler(Sender: TObject);
  protected
    function CanApply: Boolean; override;
    function GetEditClass: TControlClass; override;
    procedure InitializeEdit(AEdit: TWinControl); override;
    //# Properties
    property Editor: TACLComboBox read GetEditor;
  public
    class function Execute(const ACaption, APrompt: string;
      AValues: TACLStringList; var AItemIndex: Integer; AOwner: TComponent = nil): Boolean;
  end;

{$ENDREGION}

  { TACLProgressDialog }

  TACLProgressDialog = class(TACLForm)
  strict private
    FAeroPeak: TACLAeroPeek;
    FShowProgressInCaption: Boolean;
    FTextCaption: string;
    FTextProgress: string;

    FOnCancel: TNotifyEvent;

    procedure HandlerCancel(Sender: TObject);
    procedure HandlerFormClose(Sender: TObject; var Action: TCloseAction);
  protected
    FCancelButton: TACLButton;
    FProgressBar: TACLProgressBar;
    FTextLabel: TACLLabel;

    procedure DoShow; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Progress(const APosition, ATotal: Int64; const AText: string = ''); virtual;
    //# Properties
    property ShowProgressInCaption: Boolean read FShowProgressInCaption write FShowProgressInCaption;
    property TextCaption: string read FTextCaption write FTextCaption;
    property TextProgress: string read FTextProgress write FTextProgress;
    //# Events
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
  end;

  { TACLCustomLanguageDialog }

  TACLLanguageDialogEnumProc = reference to procedure (const ATag: NativeInt);

  TACLCustomLanguageDialog = class(TACLForm)
  strict private
    FEditor: TACLImageComboBox;
    FImages: TACLImageList;

    procedure Add(const AData: TACLLocalizationInfo; ATag, AIconIndex: NativeInt);
    function GetSelectedTag: NativeInt;
    procedure Populate;
  protected
    procedure EnumLangs(ALangFileBuffer: TACLIniFile;
      AProc: TACLLanguageDialogEnumProc); virtual; abstract;
    procedure SelectDefaultLanguage; virtual;
    //# Properties
    property SelectedTag: NativeInt read GetSelectedTag;
  public
    constructor Create(AOwner: TComponent); override;
    procedure AfterConstruction; override;
  end;

  { TACLLanguageDialog }

  TACLLanguageDialog = class(TACLCustomLanguageDialog)
  protected
    FLangFiles: TACLStringList;
    procedure EnumLangs(ALangFileBuffer: TACLIniFile;
      AProc: TACLLanguageDialogEnumProc); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class procedure Execute(AParentWnd: HWND);
  end;

  { TACLDialogsStrs }

  TACLDialogsStrs = class
  strict private const
    LangSection = 'CommonDialogs';
  public class var
    ButtonApply: string;
    FolderBrowserCaption: string;
    FolderBrowserNewFolder: string;
    FolderBrowserRecursive: string;
    MsgDlgButtons: array[TMsgDlgBtn] of string;
    MsgDlgCaptions: array[TMsgDlgType] of string;
  public
    class constructor Create;
    class procedure ApplyLocalization;
    class procedure ResetLocalization;
  end;

function acMessageBox(AHandle: HWND; const AMessage, ACaption: string; AFlags: Integer): Integer;
implementation

{$IFDEF MSWINDOWS}
uses
  ACL.UI.Dialogs.Impl.Windows;
{$ENDIF}

type
  TControlAccess = class(TControl);

function acMessageBox(AHandle: HWND; const AMessage, ACaption: string; AFlags: Integer): Integer;
begin
  if AHandle = 0 then
    AHandle := Application.MainFormHandle;

  Application.ModalStarted;
  try
  {$IFDEF MSWINDOWS}
    if IsWinSevenOrLater and UseLatestCommonDialogs then
    begin
      with TACLMessageTaskDialog.Create(AMessage, ACaption, AFlags) do
      try
        if Execute(AHandle) then
          Result := ModalResult
        else
          Result := mrNone;
      finally
        Free;
      end;
    end
    else
  {$ENDIF}
      Result := MessageBox(AHandle, PChar(AMessage), PChar(ACaption), AFlags);
  finally
    Application.ModalFinished;
  end;
end;

{$REGION 'FileDialogs'}

{ TACLFileDialog }

class constructor TACLFileDialog.Create;
begin
  MruPaths := TACLStringList.Create;
end;

class destructor TACLFileDialog.Destroy;
begin
  FreeAndNil(MruPaths);
end;

constructor TACLFileDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFiles := TACLStringList.Create;
  FOptions := DefaultOptions;
end;

destructor TACLFileDialog.Destroy;
begin
  FreeAndNil(FFiles);
  inherited Destroy;
end;

function TACLFileDialog.Execute(ASaveDialog: Boolean; AOwnerWnd: HWND): Boolean;
var
  AImpl: TACLFileDialogImpl;
  APrevPath: string;
begin
  APrevPath := acGetCurrentDir;
  try
    Application.ModalStarted;
    try
      AImpl := CreateImpl(ASaveDialog, AOwnerWnd);
      try
        Files.Clear;
        Result := AImpl.Execute;
        if Result then
        begin
          FFileName := '';
          if Files.Count > 0 then
            FFileName := Files.Strings[0];
          if ASaveDialog and (ofAutoExtension in Options) then
            FFileName := AutoExtension(FileName);
          if MRUId <> '' then
            MRUPaths.ValueFromName[MRUId] := acExtractFilePath(FileName);
        end;
      finally
        AImpl.Free;
      end;
    finally
      Application.ModalFinished;
    end;
  finally
    acSetCurrentDir(APrevPath);
  end;
end;

function TACLFileDialog.AutoExtension(const AFileName: string): string;

  function ExtractExt(const S: string): string;
  var
    ADelimPos: Integer;
  begin
    ADelimPos := acPos(';', S);
    if ADelimPos = 0 then
      ADelimPos := Length(S) + 1;
    Result := Copy(S, 2, ADelimPos - 2);
  end;

  function GetSelectedExt(out AExt: string): Boolean;
  var
    ACount: Integer;
    AParts: TStringDynArray;
  begin
    ACount := acExplodeString(Filter, '|', AParts);
    Result := (FilterIndex > 0) and (2 * (FilterIndex - 1) < ACount);
    if Result then
      AExt := ExtractExt(AParts[2 * FilterIndex - 1]);
  end;

var
  ASelectedExt: string;
begin
  if not GetSelectedExt(ASelectedExt) or (ASelectedExt = '*.*') then
    Result := AFileName
  else
    if acIsOurFile(Filter, AFileName) then
      Result := acChangeFileExt(AFileName, ASelectedExt)
    else
      Result := AFileName + ASelectedExt;
end;

function TACLFileDialog.CreateImpl(ASaveDialog: Boolean; AOwnerWnd: HWND): TACLFileDialogImpl;
begin
{$IFDEF MSWINDOWS}
  if IsWinVistaOrLater then
    Result := TACLFileDialogVistaImpl.Create(AOwnerWnd, Self, ASaveDialog)
  else
    Result := TACLFileDialogOldImpl.Create(AOwnerWnd, Self, ASaveDialog);
{$ELSE}
  Result := TACLFileDialogImpl.Create(AOwnerWnd, Self, ASaveDialog);
{$ENDIF}
end;

function TACLFileDialog.GetActualInitialDir: string;
begin
  if InitialDir <> '' then
    Result := InitialDir
  else if MRUId <> '' then
    Result := MRUPaths.ValueFromName[MRUId]
  else
    Result := EmptyStr;
end;

{ TACLFileDialogImpl }

constructor TACLFileDialogImpl.Create(
  AParentWnd: HWND; ADialog: TACLFileDialog; ASaveDialog: Boolean);
begin
  inherited Create;
  FDialog := ADialog;
  FSaveDialog := ASaveDialog;
  FParentWnd := AParentWnd;
  if ParentWnd = 0 then
    FParentWnd := TACLApplication.GetHandle;
  if ASaveDialog then
    PopulateDefaultExts;
end;

function TACLFileDialogImpl.Execute: Boolean;
var
  LDialog: TOpenDialog;
  LOptions: TOpenOptions;
begin
  LOptions := [];
  if ofOverwritePrompt in Dialog.Options then
    Include(LOptions, TOpenOption.ofOverwritePrompt);
  if ofHideReadOnly in Dialog.Options then
    Include(LOptions, TOpenOption.ofHideReadOnly);
  if ofAllowMultiSelect in Dialog.Options then
    Include(LOptions, TOpenOption.ofAllowMultiSelect);
  if ofPathMustExist in Dialog.Options then
    Include(LOptions, TOpenOption.ofPathMustExist);
  if ofFileMustExist in Dialog.Options then
    Include(LOptions, TOpenOption.ofFileMustExist);
  if ofEnableSizing in Dialog.Options then
    Include(LOptions, TOpenOption.ofEnableSizing);
  if ofForceShowHidden in Dialog.Options then
    Include(LOptions, TOpenOption.ofForceShowHidden);

  if SaveDialog then
    LDialog := TSaveDialog.Create(nil)
  else
    LDialog := TOpenDialog.Create(nil);
  try
    LDialog.InitialDir := Dialog.GetActualInitialDir;
    LDialog.Options := LOptions;
    Result := LDialog.Execute;
    if Result then
      Dialog.Files.Assign(LDialog.Files);
  finally
    LDialog.Free;
  end;
end;

procedure TACLFileDialogImpl.PopulateDefaultExts;
var
  F: TStringDynArray;
  I: Integer;
begin
  FDefaultExts := '';
  acExplodeString(Dialog.Filter, '|', F);
  for I := 0 to Length(F) div 2 - 1 do
  begin
    if (FDefaultExts.Length > 0) and (FDefaultExts[FDefaultExts.Length] <> ';') then
      FDefaultExts := FDefaultExts + ';';
    FDefaultExts := FDefaultExts + StringReplace(F[2 * I + 1], '*.', '', [rfReplaceAll]);
  end;
  if (FDefaultExts.Length > 0) and (FDefaultExts[FDefaultExts.Length] = ';') then
    Delete(FDefaultExts, Length(FDefaultExts), 1);
end;
{$ENDREGION}

{ TACLCustomDialog }

procedure TACLCustomDialog.AfterConstruction;
begin
  inherited;
  Position := poOwnerFormCenter;
end;

function TACLCustomDialog.IsShortCut(var Message: TWMKey): Boolean;
begin
  Result := inherited IsShortCut(Message);
  case Message.CharCode of
    VK_ESCAPE:
      ModalResult := mrCancel;

    VK_RETURN:
      if CanApply then
      begin
        if KeyDataToShiftState(Message.KeyData) * [ssAlt, ssCtrl, ssShift] = [ssCtrl] then
        begin
          DoApply;
          ModalResult := mrOk;
        end;
      end;
  end;
end;

function TACLCustomDialog.CanApply: Boolean;
begin
  Result := True;
end;

procedure TACLCustomDialog.CreateParams(var Params: TCreateParams);
var
  AForm: TCustomForm;
begin
  inherited CreateParams(Params);
  if Owner is TWinControl then
  begin
    AForm := GetParentForm(TWinControl(Owner));
    if AForm <> nil then
      Params.WndParent := AForm.Handle;
  end;
end;

procedure TACLCustomDialog.DoApply(Sender: TObject);
begin
  // do nothing
end;

function TACLCustomDialog.DialogChar(var Message: TWMKey): Boolean;
begin
  case Message.CharCode of
    VK_ESCAPE:
      begin
        ModalResult := mrCancel;
        Exit(True);
      end;

    VK_RETURN:
      if CanApply then
      begin
        DoApply;
        ModalResult := mrOk;
        Exit(True);
      end;
  end;
  Result := inherited;
end;

{$REGION ' InputDialogs '}

{ TACLCustomInputDialog }

procedure TACLCustomInputDialog.AfterFormCreate;
begin
  inherited;

  BorderStyle := bsDialog;
  DoubleBuffered := True;
  ClientWidth := dpiApply(335, FCurrentPPI);

  Padding.Left := dpiApply(7, FCurrentPPI);
  Padding.Top := dpiApply(7, FCurrentPPI);
  Padding.Right := dpiApply(7, FCurrentPPI);
  Padding.Bottom := dpiApply(7, FCurrentPPI);
end;

procedure TACLCustomInputDialog.CreateControls;
begin
  CreateControl(FButtonOK, TACLButton, Self, NullRect, alCustom);
  FButtonOK.Caption := TACLDialogsStrs.MsgDlgButtons[mbOK];
  FButtonOK.OnClick := DoApply;
  FButtonOK.Default := True;
  FButtonOK.ModalResult := mrOk;

  CreateControl(FButtonCancel, TACLButton, Self, NullRect, alCustom);
  FButtonCancel.Caption := TACLDialogsStrs.MsgDlgButtons[mbCancel];
  FButtonCancel.OnClick := DoCancel;
  FButtonCancel.ModalResult := mrCancel;
  FButtonCancel.Cursor := crHandPoint;

  CreateControl(FButtonApply, TACLButton, Self, NullRect, alCustom);
  FButtonApply.Caption := TACLDialogsStrs.ButtonApply;
  FButtonApply.Cursor := crHandPoint;
  FButtonApply.OnClick := DoApply;
  FButtonApply.Visible := False;
end;

procedure TACLCustomInputDialog.DoApply(Sender: TObject);
begin
  inherited;
  SetHasChanges(False);
end;

procedure TACLCustomInputDialog.DoCancel(Sender: TObject);
begin
  // do nothing
end;

procedure TACLCustomInputDialog.DoModified(Sender: TObject);
begin
  SetHasChanges(True);
end;

procedure TACLCustomInputDialog.DoShow;
var
  R: TRect;
begin
  inherited;

  R := ClientRect;
  R.Content(Rect(Padding.Left, Padding.Top, Padding.Right, Padding.Bottom));
  PlaceControls(R);
  ClientHeight := R.Bottom + Padding.Bottom;
  ClientWidth := R.Right + Padding.Right;

  DoUpdateState;
end;

procedure TACLCustomInputDialog.DoUpdateState;
var
  ACanApply: Boolean;
begin
  ACanApply := CanApply;
  ButtonApply.Enabled := ACanApply and FHasChanges;
  ButtonOK.Enabled := ACanApply;
end;

procedure TACLCustomInputDialog.PlaceControls(var R: TRect);
var
  AButtonIndent: Integer;
  AButtonRect: TRect;
begin
  R.Bottom := R.Top + dpiApply(ButtonHeight, FCurrentPPI);

  AButtonRect := R.Split(srRight, dpiApply(ButtonWidth, FCurrentPPI));
  AButtonIndent := dpiApply(6, FCurrentPPI) + dpiApply(ButtonWidth, FCurrentPPI);

  if ButtonApply.Visible then
  begin
    ButtonApply.BoundsRect := AButtonRect;
    AButtonRect.Offset(-AButtonIndent, 0);
  end;

  if ButtonCancel.Visible then
  begin
    ButtonCancel.BoundsRect := AButtonRect;
    AButtonRect.Offset(-AButtonIndent, 0);
  end;

  ButtonOK.BoundsRect := AButtonRect;
end;

procedure TACLCustomInputDialog.Resize;
var
  AClientRect: TRect;
begin
  inherited;
  AClientRect := ClientRect;
  if ButtonOk <> nil then
  begin
    AClientRect.Content(Rect(Padding.Left, Padding.Top, Padding.Right, Padding.Bottom));
    if FPrevClientRect <> AClientRect then
    begin
      FPrevClientRect := AClientRect;
      PlaceControls(AClientRect);
    end;
  end;
end;

procedure TACLCustomInputDialog.DpiChanged;
begin
  FPrevClientRect := NullRect;
  inherited;
  Resize;
end;

procedure TACLCustomInputDialog.SetHasChanges(AValue: Boolean);
begin
  if FHasChanges <> AValue then
  begin
    FHasChanges := AValue;
    DoUpdateState;
  end;
end;

{ TACLCustomInputQueryDialog }

destructor TACLCustomInputQueryDialog.Destroy;
begin
  FreeAndNil(FEditors);
  FreeAndNil(FLabels);
  inherited Destroy;
end;

procedure TACLCustomInputQueryDialog.CreateEditors(AValueCount: Integer);
var
  AEdit: TWinControl;
  ALabel: TACLLabel;
  I: Integer;
begin
  for I := 0 to AValueCount - 1 do
  begin
    CreateControl(ALabel, TACLLabel, Self, NullRect, alCustom);
    ALabel.AutoSize := True;
    FLabels.Add(ALabel);

    CreateControl(AEdit, GetEditClass, Self, NullRect, alCustom);
    FEditors.Add(AEdit);
    InitializeEdit(AEdit);
    AEdit.Tag := I;
  end;
end;

procedure TACLCustomInputQueryDialog.Initialize(AValueCount: Integer);
begin
  FLabels := TACLObjectList<TACLLabel>.Create;
  FEditors := TACLObjectList<TWinControl>.Create;
  CreateEditors(AValueCount);
  CreateControls;
  ActiveControl := FEditors[0];
end;

procedure TACLCustomInputQueryDialog.PlaceControl(var R: TRect; AControl: TControl; AIndent: Integer);
var
  AHeight: Integer;
  AWidth: Integer;
begin
  if TControlAccess(AControl).AutoSize then
  begin
    AWidth := R.Width;
    AHeight := R.Height;
    TControlAccess(AControl).CanAutoSize(AWidth, AHeight);
  end
  else
    AHeight := AControl.Height;

  AControl.BoundsRect := R.Split(srTop, AHeight);
  R.Top := AControl.BoundsRect.Bottom + dpiApply(AIndent, FCurrentPPI);
end;

procedure TACLCustomInputQueryDialog.PlaceControls(var R: TRect);
begin
  PlaceEditors(R);
  Inc(R.Top, dpiApply(10, FCurrentPPI) - dpiApply(acIndentBetweenElements, FCurrentPPI));
  inherited;
end;

procedure TACLCustomInputQueryDialog.PlaceEditors(var R: TRect);
var
  I: Integer;
begin
  for I := 0 to FLabels.Count - 1 do
  begin
    PlaceControl(R, FLabels.List[I], acTextIndent);
    PlaceControl(R, FEditors.List[I], acIndentBetweenElements);
  end;
end;

{ TACLInputQueryDialog }

class function TACLInputQueryDialog.Execute(const ACaption, APrompt: string;
  var AStr: string; ASelStart, ASelLength: Integer; AOwner: TComponent;
  AValidateEvent: TACLInputQueryValidateEvent): Boolean;
var
  ADialog: TACLInputQueryDialog;
begin
  ADialog := CreateNew(AOwner);
  try
    ADialog.Caption := ACaption;
    ADialog.OnValidate := AValidateEvent;
    ADialog.Initialize(1);
    ADialog.InitializeField(0, APrompt, AStr, ASelStart, ASelLength);
    Result := ADialog.ShowModal = mrOk;
    if Result then
      AStr := ADialog.GetFieldValue(0);
  finally
    ADialog.Free;
  end;
end;

class function TACLInputQueryDialog.Execute(const ACaption, APrompt: string;
  var AStr: string; AOwner: TComponent; AValidateEvent: TACLInputQueryValidateEvent): Boolean;
begin
  Result := Execute(ACaption, APrompt, AStr, 0, MaxInt, AOwner, AValidateEvent);
end;

class function TACLInputQueryDialog.Execute(const ACaption: string;
  const APrompts: array of string; var AValues: array of Variant;
  AOwner: TComponent; AValidateEvent: TACLInputQueryValidateEvent): Boolean;
var
  ADialog: TACLInputQueryDialog;
  I: Integer;
begin
  if Length(AValues) <> Length(APrompts) then
    raise EInvalidArgument.Create(ClassName);

  ADialog := CreateNew(AOwner);
  try
    ADialog.Caption := ACaption;
    ADialog.OnValidate := AValidateEvent;
    ADialog.Initialize(Length(AValues));
    for I := 0 to Length(AValues) - 1 do
      ADialog.InitializeField(I, APrompts[I], AValues[I]);

    Result := ADialog.ShowModal = mrOk;
    if Result then
    begin
      for I := 0 to Length(AValues) - 1 do
        AValues[I] := ADialog.GetFieldValue(I);
    end;
  finally
    ADialog.Free;
  end;
end;

class function TACLInputQueryDialog.Execute(const ACaption, APrompt: string;
  var AValue: Variant; AOwner: TComponent; AValidateEvent: TACLInputQueryValidateEvent): Boolean;
var
  APrompts: array of string;
  AValues: array of Variant;
begin
  SetLength(APrompts{%H-}, 1);
  SetLength(AValues{%H-}, 1);
  APrompts[0] := APrompt;
  AValues[0] := AValue;
  Result := Execute(ACaption, APrompts, AValues, AOwner, AValidateEvent);
  if Result then
    AValue := AValues[0];
end;

function TACLInputQueryDialog.GetFieldValue(AIndex: Integer): Variant;
begin
  Result := TACLEdit(Editors.List[AIndex]).Value;
end;

procedure TACLInputQueryDialog.InitializeEdit(AEdit: TWinControl);
begin
  TACLEdit(AEdit).OnChange := DoModified;
end;

procedure TACLInputQueryDialog.InitializeField(
  AIndex: Integer; const AFieldName: string; const AValue: Variant;
  ASelStart, ASelLength: Integer);
var
  AEdit: TACLEdit;
begin
  AEdit := TACLEdit(Editors.List[AIndex]);

  if VarIsFloat(AValue) then
    AEdit.InputMask := eimFloat
  else if VarIsOrdinal(AValue) then
    AEdit.InputMask := eimInteger
  else
    AEdit.InputMask := eimText;

  AEdit.Text := AValue;
  AEdit.SelStart := ASelStart;
  AEdit.SelLength := ASelLength;
  Labels.List[AIndex].Caption := AFieldName;
end;

function TACLInputQueryDialog.GetEditClass: TControlClass;
begin
  Result := TACLEdit;
end;

function TACLInputQueryDialog.CanApply: Boolean;
var
  AIsValid: Boolean;
  I: Integer;
begin
  AIsValid := True;
  for I := 0 to Editors.Count - 1 do
  begin
    if Assigned(OnValidate) then
      OnValidate(Self, Editors[I].Tag, TACLEdit(Editors[I]).Text, AIsValid);
    if not AIsValid then
      Break;
  end;
  Result := AIsValid;
end;

procedure TACLInputQueryDialog.DoModified(Sender: TObject);
begin
  inherited;
  DoUpdateState;
end;

{ TACLMemoQueryDialog }

constructor TACLMemoQueryDialog.Create(AOwnerHandle: HWND);
begin
  CreateDialog(AOwnerHandle, True);
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu];
  Constraints.MinHeight := 240;
  Constraints.MinWidth := 320;
  DoubleBuffered := True;
  PrepareDialogSize;
  CreateControls;
end;

class function TACLMemoQueryDialog.Execute(const ACaption: string;
  AItems: TStrings; APopupMenu: TPopupMenu; AOwnerHandle: HWND): Boolean;
var
  AText: string;
begin
  AText := AItems.Text;
  Result := Execute(ACaption, AText, APopupMenu, AOwnerHandle);
  if Result then
    AItems.Text := AText;
end;

class function TACLMemoQueryDialog.Execute(const ACaption: string;
  var AText: string; APopupMenu: TPopupMenu; AOwnerHandle: HWND): Boolean;
var
  ADialog: TACLMemoQueryDialog;
begin
  ADialog := Create(AOwnerHandle);
  try
    ADialog.Caption := ACaption;
    ADialog.Memo.Text := AText;
    ADialog.Memo.PopupMenu := APopupMenu;
    Result := ADialog.ShowModal = mrOk;
    if Result then
      AText := ADialog.Memo.Text;
    ADialog.FDialogSize.cx := dpiRevert(ADialog.ClientWidth, ADialog.FCurrentPPI);
    ADialog.FDialogSize.cy := dpiRevert(ADialog.ClientHeight, ADialog.FCurrentPPI);
    ADialog.FDialogSizeAssigned := True;
  finally
    ADialog.Free;
  end;
end;

procedure TACLMemoQueryDialog.CreateControls;
begin
  FMemo := TACLMemo(CreateControl(TACLMemo, Self, NullRect, alCustom));
  FMemo.ScrollBars := ssBoth;
  FMemo.OnKeyDown := HandleKeyDown;
  inherited CreateControls;
end;

procedure TACLMemoQueryDialog.HandleKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    ModalResult := mrOk;
  end;
end;

procedure TACLMemoQueryDialog.PlaceControls(var R: TRect);
var
  LMemoRect: TRect;
begin
  LMemoRect := R;
  Dec(LMemoRect.Bottom, dpiApply(36, FCurrentPPI));
  FMemo.BoundsRect := LMemoRect;
  R.Top := LMemoRect.Bottom + dpiApply(10, FCurrentPPI);
  inherited;
end;

procedure TACLMemoQueryDialog.PrepareDialogSize;
begin
  if FDialogSizeAssigned then
  begin
    ClientHeight := FDialogSize.cy;
    ClientWidth := FDialogSize.cx;
  end
  else
  begin
    ClientHeight := dpiApply(230, FCurrentPPI);
    ClientWidth := dpiApply(360, FCurrentPPI);
  end;
end;

{ TACLSelectQueryDialog }

class function TACLSelectQueryDialog.Execute(const ACaption, APrompt: string;
  AValues: TACLStringList; var AItemIndex: Integer; AOwner: TComponent): Boolean;
var
  ADialog: TACLSelectQueryDialog;
begin
  ADialog := CreateNew(AOwner);
  try
    ADialog.Caption := ACaption;
    ADialog.Initialize(1);
    ADialog.Labels.First.Caption := APrompt;
    ADialog.Editor.Items.Text := AValues.Text;
    ADialog.Editor.ItemIndex := AItemIndex;
    ADialog.Editor.Enabled := AValues.Count > 0;
    Result := ADialog.ShowModal = mrOk;
    if Result then
      AItemIndex := ADialog.Editor.ItemIndex;
  finally
    ADialog.Free;
  end;
end;

function TACLSelectQueryDialog.CanApply: Boolean;
begin
  Result := Editor.ItemIndex >= 0;
end;

function TACLSelectQueryDialog.GetEditClass: TControlClass;
begin
  Result := TACLComboBox;
end;

procedure TACLSelectQueryDialog.InitializeEdit(AEdit: TWinControl);
begin
  TACLComboBox(AEdit).Mode := cbmList;
  TACLComboBox(AEdit).OnSelect := SelectHandler;
end;

function TACLSelectQueryDialog.GetEditor: TACLComboBox;
begin
  Result := TACLComboBox(Editors[0]);
end;

procedure TACLSelectQueryDialog.SelectHandler(Sender: TObject);
begin
  DoUpdateState;
end;

{$ENDREGION}

{ TACLProgressDialog }

constructor TACLProgressDialog.Create(AOwner: TComponent);
begin
  CreateNew(AOwner);

  KeyPreview := True;
  Position := poOwnerFormCenter;
  BorderStyle := bsToolWindow;
  ClientHeight := dpiApply(87, FCurrentPPI);
  ClientWidth := dpiApply(502, FCurrentPPI);
  Padding.Bottom := dpiApply(5, FCurrentPPI);
  Padding.Left := dpiApply(5, FCurrentPPI);
  Padding.Right := dpiApply(5, FCurrentPPI);
  Padding.Top := dpiApply(5, FCurrentPPI);

  CreateControl(FTextLabel, TACLLabel, Self, dpiApply(Rect(0, 0, 0, 15), FCurrentPPI), alTop);
  FTextLabel.AlignWithMargins := True;

  CreateControl(FProgressBar, TACLProgressBar, Self, dpiApply(Bounds(0, 15, 0, 18), FCurrentPPI), alTop);
  FProgressBar.AlignWithMargins := True;

  CreateControl(FCancelButton, TACLButton, Self, dpiApply(Bounds(195, 54, 115, 25), FCurrentPPI), alNone);
  FCancelButton.Caption := TACLDialogsStrs.MsgDlgButtons[mbCancel];
  FCancelButton.OnClick := HandlerCancel;

  OnClose := HandlerFormClose;
end;

destructor TACLProgressDialog.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FAeroPeak);
end;

procedure TACLProgressDialog.Progress(const APosition, ATotal: Int64; const AText: string);
begin
  if ShowProgressInCaption then
    Caption := Format('[%d/%d] %s', [APosition, ATotal, TextCaption]);
  FProgressBar.Progress := MulDiv(100, APosition, Max(1, ATotal));
  FProgressBar.Update;
  FTextLabel.Caption := IfThenW(AText, TextProgress);
  FTextLabel.Update;
  if FAeroPeak <> nil then
    FAeroPeak.UpdateProgress(APosition, ATotal);
end;

procedure TACLProgressDialog.DoShow;
begin
  Caption := TextCaption;
  if ShowInTaskBar = stAlways then
    FAeroPeak := TACLAeroPeek.Create(Handle);
  FCancelButton.Enabled := Assigned(OnCancel);
  inherited DoShow;
  Progress(0, 0);
end;

procedure TACLProgressDialog.HandlerCancel(Sender: TObject);
begin
  FCancelButton.Enabled := False;
  CallNotifyEvent(Self, OnCancel);
end;

procedure TACLProgressDialog.HandlerFormClose(Sender: TObject; var Action: TCloseAction);
begin
  FCancelButton.Click;
  Action := caNone;
end;

procedure TACLProgressDialog.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_ESCAPE) and ([ssShift, ssCtrl, ssAlt] * Shift = []) then
    HandlerCancel(nil);
end;

{ TACLDialogsStrs }

class constructor TACLDialogsStrs.Create;
begin
  ResetLocalization;
end;

class procedure TACLDialogsStrs.ApplyLocalization;
var
  AButton: TMsgDlgBtn;
  AType: TMsgDlgType;
  AValue: string;
begin
  ResetLocalization;

  FolderBrowserCaption := LangGet(LangSection, 'L1', FolderBrowserCaption);
  FolderBrowserRecursive := LangGet(LangSection, 'L2', FolderBrowserRecursive);
  FolderBrowserNewFolder := LangGet(LangSection, 'B3', FolderBrowserNewFolder);
  ButtonApply := LangGet(LangSection, 'B4', ButtonApply);

  AValue := LangGet(LangSection, 'BS');
  for AButton := Low(AButton) to High(AButton) do
    MsgDlgButtons[AButton] := IfThenW(LangExtractPart(AValue, Ord(AButton)), MsgDlgButtons[AButton]);

  AValue := LangGet(LangSection, 'MsgBoxCaptions');
  for AType := Low(AType) to High(AType) do
    MsgDlgCaptions[AType] := IfThenW(LangExtractPart(AValue, Ord(AType)), MsgDlgCaptions[AType]);

  AValue := LangGet(LangSection, 'SizePrefixes');
  acLangSizeSuffixB  := IfThenW(LangExtractPart(AValue, 0), acLangSizeSuffixB);
  acLangSizeSuffixKB := IfThenW(LangExtractPart(AValue, 1), acLangSizeSuffixKB);
  acLangSizeSuffixMB := IfThenW(LangExtractPart(AValue, 2), acLangSizeSuffixMB);
  acLangSizeSuffixGB := IfThenW(LangExtractPart(AValue, 3), acLangSizeSuffixGB);
end;

class procedure TACLDialogsStrs.ResetLocalization;
const
  StdButtons: array[TMsgDlgBtn] of string = (
    '&Yes', '&No', 'OK', 'Cancel', '&Abort', '&Retry', '&Ignore',
    '&All', 'N&o to All', 'Yes to &All', '&Help', '&Close'
  );
  StdCaptions: array[TMsgDlgType] of string = (
    'Warning', 'Error', 'Information', 'Confirm', ''
  );
var
  AButton: TMsgDlgBtn;
  AType: TMsgDlgType;
begin
  ButtonApply := 'Apply';

  FolderBrowserCaption := 'Browse Folder';
  FolderBrowserNewFolder := 'New folder';
  FolderBrowserRecursive := 'Include sub-folders';

  for AButton := Low(AButton) to High(AButton) do
    MsgDlgButtons[AButton] := StdButtons[AButton];
  for AType := Low(AType) to High(AType) do
    MsgDlgCaptions[AType] := StdCaptions[AType];

  acLangSizeSuffixB  := 'B';
  acLangSizeSuffixKB := 'KB';
  acLangSizeSuffixMB := 'MB';
  acLangSizeSuffixGB := 'GB';
end;

{ TACLCustomLanguageDialog }

constructor TACLCustomLanguageDialog.Create(AOwner: TComponent);
var
  AButton: TACLButton;
begin
  CreateNew(AOwner);
  Caption := 'Select Language';
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  BorderIcons := [];
  FormStyle := fsStayOnTop;
  DoubleBuffered := True;

  ClientWidth := dpiApply(220, FCurrentPPI);
  ClientHeight := dpiApply(75, FCurrentPPI);
  Constraints.MinHeight := Height;
  Constraints.MinWidth := Width;
  Constraints.MaxWidth := Width;

  AButton := TACLButton.Create(Self);
  AButton.Align := alBottom;
  AButton.AlignWithMargins := True;
  AButton.Margins.Margins := Rect(60, 0, 60, 8);
  AButton.ModalResult := mrOk;
  AButton.Caption := 'OK';
  AButton.Parent := Self;

  FImages := TACLImageList.Create(Self);
  FImages.Width := 16;
  FImages.Height := 16;

  FEditor := TACLImageComboBox.Create(Self);
  FEditor.Parent := Self;
  FEditor.Align := alTop;
  FEditor.AlignWithMargins := True;
  FEditor.Images := FImages;
  FEditor.Margins.Margins := Rect(8, 8, 8, 8);
end;

procedure TACLCustomLanguageDialog.AfterConstruction;
begin
  inherited AfterConstruction;
  Populate;
end;

procedure TACLCustomLanguageDialog.Add(const AData: TACLLocalizationInfo; ATag, AIconIndex: NativeInt);

  function GetInsertionIndex(const AName: string): Integer;
  begin
    Result := FEditor.Items.Count;
    while (Result > 0) and (acCompareStrings(AName, FEditor.Items[Result - 1].Text) < 0) do
      Dec(Result);
  end;

var
  AItem: TACLImageComboBoxItem;
begin
  AItem := FEditor.Items.Insert(GetInsertionIndex(AData.Name)) as TACLImageComboBoxItem;
  AItem.Text := AData.Name;
  AItem.ImageIndex := AIconIndex;
  AItem.Data := {%H-}Pointer(AData.LangID);
  AItem.Tag := ATag;
end;

function TACLCustomLanguageDialog.GetSelectedTag: NativeInt;
begin
  if FEditor.ItemIndex >= 0 then
    Result := FEditor.Items[FEditor.ItemIndex].Tag
  else
    Result := -1;
end;

procedure TACLCustomLanguageDialog.Populate;
var
  AData: TACLLocalizationInfo;
  AIcon: TIcon;
  ALangInfo: TACLIniFile;
begin
  AIcon := TIcon.Create;
  ALangInfo := TACLIniFile.Create;
  try
    EnumLangs(ALangInfo,
      procedure (const ATag: NativeInt)
      var
        AIconIndex: Integer;
      begin
        LangGetInfo(ALangInfo, AData, AIcon);
        try
          AIconIndex := FImages.AddIcon(AIcon);
        except
          AIconIndex := -1;
        end;
        Add(AData, ATag, AIconIndex);
      end);
  finally
    ALangInfo.Free;
    AIcon.Free;
  end;
  SelectDefaultLanguage;
end;

procedure TACLCustomLanguageDialog.SelectDefaultLanguage;
var
  AItem: TACLImageComboBoxItem;
begin
  if
  {$IFDEF MSWINDOWS}
     FEditor.Items.FindByData(Pointer(GetUserDefaultUILanguage), AItem) or
  {$ENDIF}
     FEditor.Items.FindByData(Pointer(LANG_EN_US), AItem)
  then
    FEditor.ItemIndex := AItem.Index
  else
    FEditor.ItemIndex := 0;
end;

{ TACLLanguageDialog }

constructor TACLLanguageDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLangFiles := TACLStringList.Create;
  LangGetFiles(FLangFiles);
end;

destructor TACLLanguageDialog.Destroy;
begin
  FreeAndNil(FLangFiles);
  inherited Destroy;
end;

class procedure TACLLanguageDialog.Execute(AParentWnd: HWND);
begin
  with TACLLanguageDialog.CreateDialog(AParentWnd, False) do
  try
    ShowModal;
    if SelectedTag >= 0 then
      LangFile.LoadFromFile(acExtractFileName(FLangFiles[SelectedTag]));
  finally
    Free;
  end;
end;

procedure TACLLanguageDialog.EnumLangs(ALangFileBuffer: TACLIniFile; AProc: TACLLanguageDialogEnumProc);
var
  I: Integer;
begin
  for I := 0 to FLangFiles.Count - 1 do
  begin
    ALangFileBuffer.LoadFromFile(FLangFiles[I]);
    AProc(I);
  end;
end;

end.
