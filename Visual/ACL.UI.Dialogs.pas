////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   General Dialogs
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Dialogs;

{$I ACL.Config.inc}
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
{$IFDEF MSWINDOWS}
  Windows,
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
  System.UITypes,
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
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.ImageComboBox,
  ACL.UI.Controls.Labels,
  ACL.UI.Controls.Memo,
  ACL.UI.Controls.ProgressBar,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Forms,
  ACL.UI.Forms.Base,
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
    function DialogChar(var Message: TWMKey): Boolean; override;
    procedure DoApply(Sender: TObject = nil); virtual;
  public
    procedure AfterConstruction; override;
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
    function CreateImpl(ASaveDialog: Boolean; AOwnerWnd: TWndHandle = 0): TACLFileDialogImpl; virtual;
    function GetActualInitialDir: string;
  public
    class var MRUPaths: TACLStringList;
  public
    class constructor Create;
    class destructor Destroy;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute(ASaveDialog: Boolean; AOwnerWnd: TWndHandle = 0): Boolean; virtual;
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
    FOwnerWnd: TWndHandle;
    procedure PopulateDefaultExts;
  public
    constructor Create(AOwnerWnd: TWndHandle; ADialog: TACLFileDialog; ASaveDialog: Boolean);
    function Execute: Boolean; virtual;
    //# Properties
    property Dialog: TACLFileDialog read FDialog;
    property OwnerWnd: TWndHandle read FOwnerWnd;
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
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
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
  protected
    FEditors: TACLObjectList;
    FLabels: TACLObjectList;

    procedure CreateEditors(AValueCount: Integer); virtual;
    function GetEditClass: TControlClass; virtual; abstract;
    procedure InitializeEdit(AEdit: TWinControl); virtual; abstract;
    procedure PlaceControl(var R: TRect; AControl: TControl; AIndent: Integer);
    procedure PlaceControls(var R: TRect); override;
    procedure PlaceEditors(var R: TRect); virtual;
  public
    destructor Destroy; override;
    procedure Initialize(AValueCount: Integer);
    procedure InitializeField(AIndex: Integer; const ACaption: string);
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
    procedure InitializeEdit(AEdit: TWinControl); override;
  public
    class function Execute(const ACaption, APrompt: string; var AStr: string;
      AOwner: TComponent = nil; AValidateEvent: TACLInputQueryValidateEvent = nil): Boolean; overload;
    class function Execute(const ACaption: string; const APrompt: string;
      var AValue: Variant; AOwner: TComponent = nil;
      AValidateEvent: TACLInputQueryValidateEvent = nil): Boolean; overload;
    class function Execute(const ACaption: string; const APrompts: array of string;
      var AValues: array of Variant; AOwner: TComponent = nil;
      AValidateEvent: TACLInputQueryValidateEvent = nil): Boolean; overload;
    //# Instance
    procedure InitializeField(AIndex: Integer; const ACaption: string;
      const AValue: Variant; ASelStart: Integer = 0; ASelLength: Integer = -1);
    function GetFieldValue(AIndex: Integer): Variant;
    //# Events
    property OnValidate: TACLInputQueryValidateEvent read FOnValidate write FOnValidate;
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
    constructor Create(AOwnerHandle: TWndHandle); reintroduce;
    class function Execute(const ACaption: string; AItems: TStrings;
      APopupMenu: TPopupMenu = nil; AOwnerHandle: TWndHandle = 0): Boolean; overload;
    class function Execute(const ACaption: string; var AText: string;
      APopupMenu: TPopupMenu = nil; AOwnerHandle: TWndHandle = 0): Boolean; overload;
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

{$REGION ' ProgressDialog '}

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

{$ENDREGION}

{$REGION ' LanguageDialog '}

  { TACLCustomLanguageDialog }

  TACLLanguageDialogEnumProc = reference to procedure (ALang: TACLIniFile; ATag: NativeInt);
  TACLCustomLanguageDialog = class(TACLForm)
  strict private
    FEditor: TACLImageComboBox;
    FImages: TACLImageList;

    procedure Add(const AData: TACLLocalizationInfo; ATag, AIconIndex: NativeInt);
    function GetSelectedTag: NativeInt;
    procedure Populate;
  protected
    procedure EnumLangs(AProc: TACLLanguageDialogEnumProc); virtual; abstract;
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
    procedure EnumLangs(AProc: TACLLanguageDialogEnumProc); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class procedure Execute(AOwnerWnd: TWndHandle);
  end;

{$ENDREGION}

{$REGION ' MessageDialog '}

  { TACLMessageDialog }

  TACLMessageDialog = class(TACLCustomInputDialog)
  strict private
    FDlgType: TMsgDlgType;
    FImage: TACLDib;
    FImageBox: TRect;
    FMessage: TACLLabel;
    FSwitchToWindow: Boolean;
    function GetImageSize: Integer;
    procedure LoadImage;
  protected
    procedure AfterFormCreate; override;
    procedure CreateControls; override;
    procedure DoShow; override;
    procedure Paint; override;
    procedure PlaceControls(var R: TRect); override;
  public
    destructor Destroy; override;
    procedure Initialize(AFlags: LongWord);
    //# Properties
    property DlgType: TMsgDlgType read FDlgType write FDlgType;
    property Message: TACLLabel read FMessage;
  end;

{$ENDREGION}

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
    SearchHint: string;
    SearchNoResults: string;
  public
    class constructor Create;
    class procedure ApplyLocalization;
    class procedure ResetLocalization;
  end;

const
  // Ремапы, чтобы не использовать if-def на более высоком уровне
  ID_CANCEL           = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.ID_CANCEL;
  ID_OK               = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.ID_OK;
  ID_NO               = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.ID_NO;
  ID_YES              = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.ID_YES;
  MB_OK               = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.MB_OK;
  MB_OKCANCEL         = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.MB_OKCANCEL;
  MB_DEFBUTTON2       = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.MB_DEFBUTTON2;
  MB_DEFBUTTON3       = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.MB_DEFBUTTON3;
  MB_ICONINFORMATION  = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.MB_ICONINFORMATION;
  MB_ICONQUESTION     = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.MB_ICONQUESTION;
  MB_ICONWARNING      = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.MB_ICONWARNING;
  MB_ICONERROR        = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.MB_ICONERROR;
  MB_YESNO            = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.MB_YESNO;
  MB_YESNOCANCEL      = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.MB_YESNOCANCEL;
  MB_SYSTEMMODAL      = {$IFDEF FPC}$001000{$ELSE}Windows.MB_SYSTEMMODAL{$ENDIF};

function acMessageBox(AOwnerWnd: TWndHandle; const AMessage, ACaption: string; AFlags: Integer): Integer;
procedure acShowMessage(const AMessage: string);
implementation

uses
{$IF DEFINED(MSWINDOWS)}
  ACL.UI.Dialogs.Impl.Win32;
{$ELSEIF DEFINED(LCLGtk3)}
  ACL.UI.Core.Impl.Gtk3;
{$ELSEIF DEFINED(LCLGtk2)}
  ACL.UI.Core.Impl.Gtk2;
{$ENDIF}

type
  TControlAccess = class(TControl);

function acMessageBox(AOwnerWnd: TWndHandle; const AMessage, ACaption: string; AFlags: Integer): Integer;
begin
  if AOwnerWnd = 0 then
    AOwnerWnd := Application.MainFormHandle;

  with TACLMessageDialog.CreateDialog(AOwnerWnd, True) do
  try
    Caption := ACaption;
    Message.Caption := AMessage;
    Initialize(AFlags);
    Result := ShowModal;
  finally
    Free;
  end;

//  Application.ModalStarted;
//  try
//  {$IFDEF MSWINDOWS}
//    if acOSCheckVersion(6, 1) and UseLatestCommonDialogs then
//    begin
//      with TACLMessageTaskDialog.Create(AMessage, ACaption, AFlags) do
//      try
//        if Execute(AOwnerWnd) then
//          Exit(ModalResult);
//      finally
//        Free;
//      end;
//    end;
//  {$ENDIF}
//    Result := MessageBox(AOwnerWnd, PChar(AMessage), PChar(ACaption), AFlags);
//  finally
//    Application.ModalFinished;
//  end;
end;

procedure acShowMessage(const AMessage: string);
var
  LForm: TForm;
begin
  LForm := Screen.ActiveForm;
  if LForm <> nil then
    acMessageBox(LForm.Handle, AMessage, LForm.Caption, MB_OK)
  else
    acMessageBox(0, AMessage, Application.Title, MB_OK);
end;

{ TACLCustomDialog }

procedure TACLCustomDialog.AfterConstruction;
begin
  inherited;
  Position := poOwnerFormCenter;
  InitPopupMode(Safe.CastOrNil<TWinControl>(Owner));
end;

function TACLCustomDialog.CanApply: Boolean;
begin
  Result := True;
end;

procedure TACLCustomDialog.DoApply(Sender: TObject);
begin
  // do nothing
end;

function TACLCustomDialog.DialogChar(var Message: TWMKey): Boolean;
begin
  if ActiveControl <> nil then
  begin
    if ActiveControl.Perform({%H-}CM_DIALOGKEY,
      TMessage(Message).WParam,
      TMessage(Message).LParam) <> 0 then
    begin
      Message.Result := 1;
      Exit(True);
    end;
  end;

  case Message.CharCode of
    VK_ESCAPE:
    {$IFDEF FPC}
      if CancelControl = nil then
    {$ENDIF}
      begin
        ModalResult := mrCancel;
        Exit(True);
      end;

    VK_RETURN:
      if CanApply{$IFDEF FPC} and (DefaultControl = nil){$ENDIF} then
      begin
        DoApply;
        ModalResult := mrOk;
        Exit(True);
      end;
  end;
  Result := inherited;
end;

{ TACLDialogsStrs }

class constructor TACLDialogsStrs.Create;
begin
  ResetLocalization;
end;

class procedure TACLDialogsStrs.ApplyLocalization;
const
  Map: array[TACLEditAction] of string = ('B7', 'B6', 'B8', 'B5', 'SA', 'B9');
var
  LAction: TACLEditAction;
  LButton: TMsgDlgBtn;
  LSection: TACLIniFileSection;
  LType: TMsgDlgType;
  LValue: string;
begin
  ResetLocalization;

  LSection := LangFile.GetSection(LangSection, True);
  FolderBrowserCaption := LSection.ReadString('L1', FolderBrowserCaption);
  FolderBrowserRecursive := LSection.ReadString('L2', FolderBrowserRecursive);
  FolderBrowserNewFolder := LSection.ReadString('B3', FolderBrowserNewFolder);
  ButtonApply := LSection.ReadString('B4', ButtonApply);

  SearchHint := LSection.ReadString('Search', SearchHint);
  SearchNoResults := LSection.ReadString('SearchNoResults', SearchNoResults);

  LValue := LSection.ReadString('BS');
  for LButton := Low(LButton) to High(LButton) do
    MsgDlgButtons[LButton] := IfThenW(LangExtractPart(LValue, Ord(LButton)), MsgDlgButtons[LButton]);

  LValue := LSection.ReadString('MsgBoxCaptions');
  for LType := Low(LType) to High(LType) do
    MsgDlgCaptions[LType] := IfThenW(LangExtractPart(LValue, Ord(LType)), MsgDlgCaptions[LType]);

  LValue := LSection.ReadString('SizePrefixes');
  acLangSizeSuffixB  := IfThenW(LangExtractPart(LValue, 0), acLangSizeSuffixB);
  acLangSizeSuffixKB := IfThenW(LangExtractPart(LValue, 1), acLangSizeSuffixKB);
  acLangSizeSuffixMB := IfThenW(LangExtractPart(LValue, 2), acLangSizeSuffixMB);
  acLangSizeSuffixGB := IfThenW(LangExtractPart(LValue, 3), acLangSizeSuffixGB);

  for LAction := Low(LAction) to High(LAction) do
  begin
    TACLEditContextMenu.Captions[LAction] :=
      LSection.ReadString(Map[LAction], TACLEditContextMenu.Captions[LAction]);
  end;
end;

class procedure TACLDialogsStrs.ResetLocalization;
const
  StdActions: array[TACLEditAction] of string = (
    'Copy', 'Cut', 'Paste', 'Undo', 'Select All', 'Delete'
  );
  StdButtons: array[TMsgDlgBtn] of string = (
    '&Yes', '&No', 'OK', 'Cancel', '&Abort', '&Retry', '&Ignore',
    '&All', 'N&o to All', 'Yes to &All', '&Help', '&Close'
  );
  StdCaptions: array[TMsgDlgType] of string = (
    'Warning', 'Error', 'Information', 'Confirm', ''
  );
var
  LAction: TACLEditAction;
  LButton: TMsgDlgBtn;
  LType: TMsgDlgType;
begin
  ButtonApply := 'Apply';

  FolderBrowserCaption := 'Browse Folder';
  FolderBrowserNewFolder := 'New folder';
  FolderBrowserRecursive := 'Include sub-folders';

  for LButton := Low(LButton) to High(LButton) do
    MsgDlgButtons[LButton] := StdButtons[LButton];
  for LType := Low(LType) to High(LType) do
    MsgDlgCaptions[LType] := StdCaptions[LType];
  for LAction := Low(LAction) to High(LAction) do
    TACLEditContextMenu.Captions[LAction] := StdActions[LAction];

  acLangSizeSuffixB  := 'B';
  acLangSizeSuffixKB := 'KB';
  acLangSizeSuffixMB := 'MB';
  acLangSizeSuffixGB := 'GB';

  SearchHint := 'Type here to search';
  SearchNoResults := 'No results matching your search query';
end;

{$REGION ' FileDialogs '}

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

function TACLFileDialog.Execute(ASaveDialog: Boolean; AOwnerWnd: TWndHandle): Boolean;
var
  LImpl: TACLFileDialogImpl;
  LPrevPath: string;
begin
  LPrevPath := acGetCurrentDir;
  try
    Application.ModalStarted;
    try
      LImpl := CreateImpl(ASaveDialog, AOwnerWnd);
      try
        Files.Clear;
        Result := LImpl.Execute;
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
        LImpl.Free;
      end;
    finally
      Application.ModalFinished;
    end;
  finally
    acSetCurrentDir(LPrevPath);
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
    ACount := acSplitString(Filter, '|', AParts);
    Result := (FilterIndex > 0) and (2 * (FilterIndex - 1) < ACount);
    if Result then
      AExt := ExtractExt(AParts[2 * FilterIndex - 1]);
  end;

var
  LSelectedExt: string;
begin
  if not GetSelectedExt(LSelectedExt) or (LSelectedExt = '*.*') then
    Result := AFileName
  else if acIsOurFile(Filter, AFileName) then
    Result := acChangeFileExt(AFileName, LSelectedExt)
  else
    Result := AFileName + LSelectedExt;
end;

function TACLFileDialog.CreateImpl(ASaveDialog: Boolean; AOwnerWnd: TWndHandle): TACLFileDialogImpl;
begin
{$IFDEF MSWINDOWS}
  Result := TACLFileDialogVistaImpl.TryCreate(AOwnerWnd, Self, ASaveDialog);
  if Result = nil then
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
  AOwnerWnd: TWndHandle; ADialog: TACLFileDialog; ASaveDialog: Boolean);
begin
  inherited Create;
  FDialog := ADialog;
  FSaveDialog := ASaveDialog;
  FOwnerWnd := AOwnerWnd;
  if OwnerWnd = 0 then
    FOwnerWnd := TACLApplication.GetHandle;
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
    LDialog.Filter := Dialog.Filter;
    LDialog.InitialDir := Dialog.GetActualInitialDir;
    LDialog.Options := LOptions;
    Result := LDialog.Execute;
    if Result then
    begin
      Dialog.Files.Assign(LDialog.Files);
      Dialog.FilterIndex := LDialog.FilterIndex;
    end;
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
  acSplitString(Dialog.Filter, '|', F);
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

{$REGION ' InputDialogs '}

{ TACLCustomInputDialog }

procedure TACLCustomInputDialog.AfterFormCreate;
begin
  inherited;
  Padding.All := 7;
  BorderStyle := bsDialog;
  DoubleBuffered := True;
  ClientWidth := dpiApply(335, FCurrentPPI);
end;

procedure TACLCustomInputDialog.AlignControls(AControl: TControl; var ARect: TRect);
begin
  if InCreation = TACLBoolean.False then
  begin
    ARect := ClientRect;
    AdjustClientRect(ARect);
    PlaceControls(ARect);
  end;
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

  CreateControl(FButtonApply, TACLButton, Self, NullRect, alCustom);
  FButtonApply.Caption := TACLDialogsStrs.ButtonApply;
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
  LMargins: TRect;
  LRect: TRect;
begin
  inherited;

  LRect := ClientRect;
  AdjustClientRect(LRect);
  LMargins := TRect.CreateMargins(ClientRect, LRect);
  PlaceControls(LRect);
  ClientHeight := LRect.Bottom + LMargins.Bottom;
  ClientWidth := LRect.Right + LMargins.Right;

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
  LBtnIndent: Integer;
  LBtnRect: TRect;
begin
  R.Bottom := R.Top + dpiApply(ButtonHeight, FCurrentPPI);

  LBtnRect := R.Split(srRight, dpiApply(ButtonWidth, FCurrentPPI));
  LBtnIndent := dpiApply(6, FCurrentPPI) + dpiApply(ButtonWidth, FCurrentPPI);

  if ButtonApply.Visible then
  begin
    ButtonApply.BoundsRect := LBtnRect;
    LBtnRect.Offset(-LBtnIndent, 0);
  end;

  if ButtonCancel.Visible then
  begin
    ButtonCancel.BoundsRect := LBtnRect;
    LBtnRect.Offset(-LBtnIndent, 0);
  end;

  ButtonOK.BoundsRect := LBtnRect;
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
  FLabels := TACLObjectList.Create;
  FEditors := TACLObjectList.Create;
  CreateEditors(AValueCount);
  CreateControls;
  if FEditors.Count > 0 then
    ActiveControl := FEditors.List[0];
end;

procedure TACLCustomInputQueryDialog.InitializeField(AIndex: Integer; const ACaption: string);
begin
  TACLLabel(FLabels[AIndex]).Caption := ACaption;
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
  var AStr: string; AOwner: TComponent; AValidateEvent: TACLInputQueryValidateEvent): Boolean;
var
  LDialog: TACLInputQueryDialog;
begin
  LDialog := CreateNew(AOwner);
  try
    LDialog.Caption := ACaption;
    LDialog.OnValidate := AValidateEvent;
    LDialog.Initialize(1);
    LDialog.InitializeField(0, APrompt, AStr);
    Result := LDialog.ShowModal = mrOk;
    if Result then
      AStr := LDialog.GetFieldValue(0);
  finally
    LDialog.Free;
  end;
end;

class function TACLInputQueryDialog.Execute(const ACaption: string;
  const APrompts: array of string; var AValues: array of Variant;
  AOwner: TComponent; AValidateEvent: TACLInputQueryValidateEvent): Boolean;
var
  LDialog: TACLInputQueryDialog;
  I: Integer;
begin
  if Length(AValues) <> Length(APrompts) then
    raise EInvalidArgument.Create(ClassName);

  LDialog := CreateNew(AOwner);
  try
    LDialog.Caption := ACaption;
    LDialog.OnValidate := AValidateEvent;
    LDialog.Initialize(Length(AValues));
    for I := 0 to Length(AValues) - 1 do
      LDialog.InitializeField(I, APrompts[I], AValues[I]);

    Result := LDialog.ShowModal = mrOk;
    if Result then
    begin
      for I := 0 to Length(AValues) - 1 do
        AValues[I] := LDialog.GetFieldValue(I);
    end;
  finally
    LDialog.Free;
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
  Result := TACLEdit(FEditors.List[AIndex]).Value;
end;

procedure TACLInputQueryDialog.InitializeEdit(AEdit: TWinControl);
begin
  TACLEdit(AEdit).OnChange := DoModified;
end;

procedure TACLInputQueryDialog.InitializeField(
  AIndex: Integer; const ACaption: string; const AValue: Variant;
  ASelStart: Integer = 0; ASelLength: Integer = -1);
var
  LEdit: TACLEdit;
begin
  LEdit := FEditors.List[AIndex];
  if VarIsFloat(AValue) then
    LEdit.NumbersOnly := DefaultNumbersOnlyFloat
  else if VarIsOrdinal(AValue) then
    LEdit.NumbersOnly := DefaultNumbersOnlyInteger
  else
    LEdit.NumbersOnly := [];

  LEdit.Text := AValue;
  if ASelLength >= 0 then
  begin
    LEdit.Select(ASelStart, ASelLength);
    LEdit.AutoSelect := False;
  end;
  inherited InitializeField(AIndex, ACaption);
end;

function TACLInputQueryDialog.GetEditClass: TControlClass;
begin
  Result := TACLEdit;
end;

function TACLInputQueryDialog.CanApply: Boolean;
var
  I: Integer;
  LEdit: TACLEdit;
  LValid: Boolean;
begin
  LValid := True;
  for I := 0 to FEditors.Count - 1 do
  begin
    LEdit := FEditors.List[I];
    if Assigned(OnValidate) then
      OnValidate(Self, LEdit.Tag, LEdit.Text, LValid);
    if not LValid then
      Break;
  end;
  Result := LValid;
end;

procedure TACLInputQueryDialog.DoModified(Sender: TObject);
begin
  inherited;
  DoUpdateState;
end;

{ TACLMemoQueryDialog }

constructor TACLMemoQueryDialog.Create(AOwnerHandle: TWndHandle);
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
  AItems: TStrings; APopupMenu: TPopupMenu; AOwnerHandle: TWndHandle): Boolean;
var
  AText: string;
begin
  AText := AItems.Text;
  Result := Execute(ACaption, AText, APopupMenu, AOwnerHandle);
  if Result then
    AItems.Text := AText;
end;

class function TACLMemoQueryDialog.Execute(const ACaption: string;
  var AText: string; APopupMenu: TPopupMenu; AOwnerHandle: TWndHandle): Boolean;
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
    ADialog.InitializeField(0, APrompt);
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
  Result := TACLComboBox(FEditors[0]);
end;

procedure TACLSelectQueryDialog.SelectHandler(Sender: TObject);
begin
  DoUpdateState;
end;

{$ENDREGION}

{$REGION ' ProgressDialog '}

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

  CreateControl(FTextLabel, TACLLabel, Self, dpiApply(Rect(0, 0, 0, 16), FCurrentPPI), alTop);
  FTextLabel.Margins.All := TACLMargins.Default;
  FTextLabel.AutoSize := True;

  CreateControl(FProgressBar, TACLProgressBar, Self, dpiApply(Bounds(0, 16, 0, 18), FCurrentPPI), alTop);
  FProgressBar.Margins.All := TACLMargins.Default;

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
    FAeroPeak := TACLAeroPeek.Create(Self);
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

{$ENDREGION}

{$REGION ' LanguageDialog '}

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
  AButton.Margins.Rect := Rect(60, 0, 60, 8);
  AButton.ModalResult := mrOk;
  AButton.Caption := 'OK';
  AButton.Parent := Self;

  FImages := TACLImageList.Create(Self);
  FImages.SetSize(16);

  FEditor := TACLImageComboBox.Create(Self);
  FEditor.Parent := Self;
  FEditor.Align := alTop;
  FEditor.Images := FImages;
  FEditor.Margins.All := 8;
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
  LIcon: TIcon;
begin
  LIcon := TIcon.Create;
  try
    EnumLangs(
      procedure (ALang: TACLIniFile; ATag: NativeInt)
      var
        LData: TACLLocalizationInfo;
        LIconIndex: Integer;
      begin
        LangGetInfo(ALang, LData, LIcon);
        try
          LIconIndex := FImages.AddIcon(LIcon);
        except
          LIconIndex := -1;
        end;
        Add(LData, ATag, LIconIndex);
      end);
  finally
    LIcon.Free;
  end;
  SelectDefaultLanguage;
end;

procedure TACLCustomLanguageDialog.SelectDefaultLanguage;
var
  LItem: TACLImageComboBoxItem;
begin
  if FEditor.Items.FindByData({%H-}Pointer(GetUserDefaultUILanguage), LItem) or
     FEditor.Items.FindByData({%H-}Pointer(LANG_EN_US), LItem)
  then
    FEditor.ItemIndex := LItem.Index
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

class procedure TACLLanguageDialog.Execute(AOwnerWnd: TWndHandle);
begin
  with TACLLanguageDialog.CreateDialog(AOwnerWnd, False) do
  try
    ShowModal;
    if SelectedTag >= 0 then
      LangFile.LoadFromFile(acExtractFileName(FLangFiles[SelectedTag]));
  finally
    Free;
  end;
end;

procedure TACLLanguageDialog.EnumLangs(AProc: TACLLanguageDialogEnumProc);
var
  I: Integer;
  LLang: TACLIniFile;
begin
  LLang := TACLIniFile.Create;
  try
    for I := 0 to FLangFiles.Count - 1 do
    begin
      LLang.LoadFromFile(FLangFiles[I]);
      AProc(LLang, I);
    end;
  finally
    LLang.Free;
  end;
end;

{$ENDREGION}

{$REGION ' MessageDialog '}

{ TACLMessageDialog }

destructor TACLMessageDialog.Destroy;
begin
  FreeAndNil(FImage);
  inherited;
end;

procedure TACLMessageDialog.AfterFormCreate;
begin
  inherited;
  ClientWidth := dpiApply(400, FCurrentPPI);
  CreateControls;
end;

procedure TACLMessageDialog.CreateControls;
begin
  inherited;
  // ModalResults only!
  ButtonCancel.OnClick := nil;
  ButtonApply.OnClick := nil;
  ButtonOK.OnClick := nil;

  CreateControl(FMessage, TACLLabel, Self, NullRect, alCustom);
  FMessage.AutoSize := True;
  FMessage.Style.WordWrap := True;
end;

procedure TACLMessageDialog.DoShow;
begin
  LoadImage;
  inherited;
  acMessageBeep(DlgType);
  if FSwitchToWindow then
    acSwitchToWindow(Handle);
end;

procedure TACLMessageDialog.Initialize(AFlags: LongWord);

  procedure InitButtons(
    const Buttons: array of TMsgDlgBtn;
    const Results: array of TModalResult);

    procedure InitButton(AButton: TACLButton; AIndex: Integer);
    const
      DefMap: array[0..2] of Integer = (MB_DEFBUTTON1, MB_DEFBUTTON2, MB_DEFBUTTON3);
    begin
      AButton.Visible := AIndex < Length(Buttons);
      if AButton.Visible then
      begin
        AButton.Caption := TACLDialogsStrs.MsgDlgButtons[Buttons[AIndex]];
        AButton.Cancel := Buttons[AIndex] = mbCancel;
        AButton.Default := AFlags and DefMap[AIndex] <> 0;
        AButton.ModalResult := Results[AIndex];
        if AButton.Default then
          ActiveControl := AButton;
      end;
    end;

  begin
    if (Length(Buttons) = 0) or (Length(Buttons) > 3) then
      raise EInvalidArgument.Create('MsgDlg: button limit has been exceed');
    InitButton(ButtonOK, 0);
    InitButton(ButtonCancel, 1);
    InitButton(ButtonApply, 2);
  end;

begin
  SetHasChanges(True);

  if AFlags and MB_ICONINFORMATION = MB_ICONINFORMATION then
    DlgType := TMsgDlgType.mtInformation
  else if AFlags and MB_ICONWARNING = MB_ICONWARNING then
    DlgType := TMsgDlgType.mtWarning
  else if AFlags and MB_ICONQUESTION = MB_ICONQUESTION then
    DlgType := TMsgDlgType.mtConfirmation
  else if AFlags and MB_ICONERROR = MB_ICONERROR then
    DlgType := TMsgDlgType.mtError
  else
    DlgType := TMsgDlgType.mtCustom;

  case AFlags and $F of
    MB_ABORTRETRYIGNORE:
      InitButtons([mbAbort, mbRetry, mbIgnore], [mrAbort, mrRetry, mrIgnore]);
    MB_RETRYCANCEL:
      InitButtons([mbRetry, mbCancel], [mrRetry, mrCancel]);
    MB_YESNOCANCEL:
      InitButtons([mbYes, mbNo, mbCancel], [mrYes, mrNo, mrCancel]);
    MB_YESNO:
      InitButtons([mbYes, mbNo], [mrYes, mrNo]);
    MB_OKCANCEL:
      InitButtons([mbOk, mbCancel], [mrOk, mrCancel]);
  else
    InitButtons([mbOk], [mrOk]);
  end;

  if Caption = '' then
    Caption := TACLDialogsStrs.MsgDlgCaptions[DlgType];
  FSwitchToWindow := AFlags and MB_SYSTEMMODAL <> 0;
end;

function TACLMessageDialog.GetImageSize: Integer;
begin
  Result := dpiApply(32, CurrentDpi);
end;

procedure TACLMessageDialog.LoadImage;
begin
  try
    FImage := LoadDialogIcon(Handle, DlgType, GetImageSize);
  except
    FImage := nil;
  end;
end;

procedure TACLMessageDialog.Paint;
begin
  inherited;
  if FImage <> nil then
    FImage.DrawBlend(Canvas, FImageBox, 255, True);
end;

procedure TACLMessageDialog.PlaceControls(var R: TRect);
var
  LIndent: Integer;
  LMessage: TRect;
begin
  FImageBox := R;
  FImageBox.Size := TSize.Create(IfThen(FImage <> nil, GetImageSize));
  LIndent := dpiApply(Padding.Left, CurrentDpi);

  LMessage := R;
  LMessage.Left := FImageBox.Right + IfThen(FImage <> nil, LIndent);
  LMessage.Size := FMessage.MeasureSize(LMessage.Width);
  LMessage.Width := Min(LMessage.Width, Screen.Width div 2);
  FMessage.BoundsRect := LMessage;

  LMessage := FMessage.BoundsRect;
  R.Right := Max(R.Right, LMessage.Right);
  R.Top := Max(FImageBox.Bottom, LMessage.Bottom) + LIndent * 2;

  inherited;
end;

{$ENDREGION}

end.
