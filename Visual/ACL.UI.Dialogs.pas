{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*          Common Dialogs Wrappes           *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Dialogs;

{$I ACL.Config.INC}
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  Winapi.ActiveX,
  Winapi.CommDlg,
  Winapi.Messages,
  Winapi.ShlObj,
  Winapi.Windows,
  // System
  System.Classes,
  System.Generics.Collections,
  System.Math,
  System.SysUtils,
  System.Types,
  System.Variants,
  // Vcl
  Vcl.ActnList,
  Vcl.Consts,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.Menus,
  Vcl.StdCtrls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Graphics,
  ACL.MUI,
  ACL.Parsers,
  ACL.Threading,
  ACL.UI.AeroPeek,
  ACL.UI.Application,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.ComboBox,
  ACL.UI.Controls.ImageComboBox,
  ACL.UI.Controls.TextEdit,
  ACL.UI.Controls.Memo,
  ACL.UI.Forms,
  ACL.UI.Controls.Labels,
  ACL.UI.ImageList,
  ACL.UI.Controls.ProgressBar,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

type
{$REGION 'FileDialogs'}

  { TACLFileDialog }

  TACLFileDialogCustomWrapper = class;

  TACLFileDialogOption = (ofOverwritePrompt, ofHideReadOnly, ofNoChangeDir, ofNoValidate, ofAllowMultiSelect,
    ofPathMustExist, ofFileMustExist,  ofCreatePrompt, ofShareAware, ofNoReadOnlyReturn, ofNoTestFileCreate,
    ofNoNetworkButton, ofNoDereferenceLinks, ofEnableIncludeNotify, ofEnableSizing, ofDontAddToRecent,
    ofForceShowHidden, ofAutoExtension);
  TACLFileDialogOptions = set of TACLFileDialogOption;

  TACLFileDialog = class(TComponent)
  public const
    DefaultOptions = [ofHideReadOnly, ofEnableSizing, ofOverwritePrompt, ofAutoExtension];
  strict private
    FFileName: UnicodeString;
    FFiles: TACLStringList;
    FFilter: UnicodeString;
    FFilterIndex: Integer;
    FInitialDir: UnicodeString;
    FMRUId: UnicodeString;
    FOptions: TACLFileDialogOptions;
    FTitle: UnicodeString;
  protected
    function AutoExtension(const AFileName: UnicodeString): UnicodeString;
    function CreateWrapper(ASaveDialog: Boolean; AOwner: THandle = 0): TACLFileDialogCustomWrapper; virtual;
    function GetActualInitialDir: UnicodeString;
  public
    class var MRUPaths: TACLStringList;
  public
    class constructor Create;
    class destructor Destroy;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute(ASaveDialog: Boolean; AOwner: THandle = 0): Boolean; virtual;
    //
    property FileName: UnicodeString read FFilename write FFileName;
    property Files: TACLStringList read FFiles;
    property InitialDir: UnicodeString read FInitialDir write FInitialDir;
  published
    property Filter: UnicodeString read FFilter write FFilter;
    property FilterIndex: Integer read FFilterIndex write FFilterIndex default 0;
    property MRUId: UnicodeString read FMRUId write FMRUId;
    property Options: TACLFileDialogOptions read FOptions write FOptions default DefaultOptions;
    property Title: UnicodeString read FTitle write FTitle;
  end;

  { TACLFileDialogCustomWrapper }

  TACLFileDialogCustomWrapper = class(TACLUnknownObject)
  strict private
    FDialog: TACLFileDialog;
    FSaveDialog: Boolean;
  protected
    FDefaultExts: UnicodeString;
    FParent: THandle;

    procedure PopulateDefaultExts;
  public
    constructor Create(AParent: THandle; ADialog: TACLFileDialog; ASaveDialog: Boolean); virtual;
    function Execute: Boolean; virtual; abstract;
    //
    property SaveDialog: Boolean read FSaveDialog;
    property Dialog: TACLFileDialog read FDialog;
    property Parent: THandle read FParent;
  end;

  { TACLFileDialogOldStyleWrapper }

  TACLFileDialogOldStyleWrapper = class(TACLFileDialogCustomWrapper)
  strict private
    FStruct: TOpenFilenameW;
    FTempBuffer: PWideChar;
    FTempBufferSize: Cardinal;
    FTempFilter: UnicodeString;
    FTempInitialPath: string;

    class function DialogHook(Wnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): UINT_PTR; stdcall; static;
  protected
    function AllocFilterStr(const S: UnicodeString): UnicodeString;
    procedure GetFileNames(AFileList: TACLStringList);
    procedure PrepareConst(var AStruct: TOpenFilenameW);
    procedure PrepareFlags(var AStruct: TOpenFilenameW);
  public
    constructor Create(AParent: THandle; ADialog: TACLFileDialog; ASaveDialog: Boolean); override;
    destructor Destroy; override;
    function Execute: Boolean; override;
  end;

  { TACLFileDialogVistaStyleWrapper }

  TACLFileDialogVistaStyleWrapper = class(TACLFileDialogCustomWrapper, IFileDialogEvents)
  strict private
    FFileDialog: IFileDialog;
  protected
    FExts: UnicodeString;
    FFilter: TStringDynArray;

    function GetItemName(const AItem: IShellItem): UnicodeString;
    procedure Initialize; virtual;
    procedure InitializeFilter; virtual;
    procedure QuerySeletectedFiles(AFileList: TACLStringList);
    // IFileDialogEvents
    function OnFileOk(const pfd: IFileDialog): HRESULT; virtual; stdcall;
    function OnFolderChange(const pfd: IFileDialog): HRESULT; virtual; stdcall;
    function OnFolderChanging(const pfd: IFileDialog; const psiFolder: IShellItem): HRESULT; virtual; stdcall;
    function OnOverwrite(const pfd: IFileDialog; const psi: IShellItem; out pResponse: Cardinal): HRESULT; virtual; stdcall;
    function OnSelectionChange(const pfd: IFileDialog): HRESULT; virtual; stdcall;
    function OnShareViolation(const pfd: IFileDialog; const psi: IShellItem; out pResponse: Cardinal): HRESULT; virtual; stdcall;
    function OnTypeChange(const pfd: IFileDialog): HRESULT; virtual; stdcall;
    //
    property FileDialog: IFileDialog read FFileDialog;
  public
    constructor Create(AParent: THandle; ADialog: TACLFileDialog; ASaveDialog: Boolean); override;
    function Execute: Boolean; override;
  end;

{$ENDREGION}

  { TACLCustomDialog }

  TACLCustomDialog = class(TACLForm)
  strict private
    procedure CMDialogKey(var Message: TCMDialogKey); message CM_DIALOGKEY;
  protected const
    ButtonHeight = 25;
    ButtonWidth = 96;
  protected
    function CanApply: Boolean; virtual;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DoApply(Sender: TObject = nil); virtual;
  public
    procedure AfterConstruction; override;
    function IsShortCut(var Message: TWMKey): Boolean; override;
  end;

{$REGION 'InputDialogs'}

  { TACLCustomInputDialog }

  TACLCustomInputDialog = class abstract(TACLCustomDialog)
  strict private
    FButtonApply: TACLButton;
    FButtonCancel: TACLButton;
    FButtonOK: TACLButton;
    FHasChanges: Boolean;
    FPrevClientRect: TRect;
  strict protected
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
  strict protected
    procedure CreateEditors(AValueCount: Integer); virtual;
    function GetEditClass: TControlClass; virtual; abstract;
    procedure InitializeEdit(AEdit: TWinControl); virtual; abstract;
    procedure PlaceControl(var R: TRect; AControl: TControl; AIndent: Integer);
    procedure PlaceControls(var R: TRect); override;
    procedure PlaceEditors(var R: TRect); virtual;
    //
    property Editors: TACLObjectList<TWinControl> read FEditors;
    property Labels: TACLObjectList<TACLLabel> read FLabels;
  protected
    procedure Initialize(AValueCount: Integer);
  public
    destructor Destroy; override;
  end;

  { TACLInputQueryDialog }

  TACLInputQueryValidateEvent = reference to procedure (Sender: TObject;
    const AValueIndex: Integer; const AValue: UnicodeString; var AIsValid: Boolean);

  TACLInputQueryDialog = class(TACLCustomInputQueryDialog)
  strict private
    FOnValidate: TACLInputQueryValidateEvent;
  strict protected
    function CanApply: Boolean; override;
    procedure DoModified(Sender: TObject = nil); override;
    function GetEditClass: TControlClass; override;
    function GetFieldValue(AIndex: Integer): Variant;
    procedure InitializeEdit(AEdit: TWinControl); override;
  protected
    procedure InitializeField(AIndex: Integer; const AFieldName: UnicodeString;
      const AValue: Variant; ASelStart: Integer = 0; ASelLength: Integer = MaxInt);

    property OnValidate: TACLInputQueryValidateEvent read FOnValidate write FOnValidate;
  public
    class function Execute(const ACaption, APrompt: UnicodeString; var AStr: UnicodeString;
      AOwner: TComponent = nil; AValidateEvent: TACLInputQueryValidateEvent = nil): Boolean; overload;
    class function Execute(const ACaption, APrompt: UnicodeString; var AStr: UnicodeString;
      ASelStart, ASelLength: Integer; AOwner: TComponent = nil; AValidateEvent: TACLInputQueryValidateEvent = nil): Boolean; overload;
    class function Execute(const ACaption: UnicodeString; const APrompt: UnicodeString;
      var AValue: Variant; AOwner: TComponent = nil; AValidateEvent: TACLInputQueryValidateEvent = nil): Boolean; overload;
    class function Execute(const ACaption: UnicodeString; const APrompts: array of UnicodeString;
      var AValues: array of Variant; AOwner: TComponent = nil; AValidateEvent: TACLInputQueryValidateEvent = nil): Boolean; overload;
  end;

  { TACLMemoQueryDialog }

  TACLMemoQueryDialog = class(TACLCustomInputDialog)
  strict private class var
    FDialogSize: TSize;
    FDialogSizeAssigned: Boolean;
  strict private
    FMemo: TACLMemo;

    procedure MemoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PrepareDialogSize;
  strict protected
    procedure CreateControls; override;
    procedure PlaceControls(var R: TRect); override;

    property Memo: TACLMemo read FMemo;
  public
    constructor Create(AOwnerHandle: THandle); reintroduce;
    class function Execute(const ACaption: UnicodeString; AItems: TStrings;
      APopupMenu: TPopupMenu = nil; AOwnerHandle: THandle = 0): Boolean; overload;
    class function Execute(const ACaption: UnicodeString; var AText: UnicodeString;
      APopupMenu: TPopupMenu = nil; AOwnerHandle: THandle = 0): Boolean; overload;
  end;

  { TACLSelectQueryDialog }

  TACLSelectQueryDialog = class(TACLCustomInputQueryDialog)
  strict private
    function GetEditor: TACLComboBox;
    procedure SelectHandler(Sender: TObject);
  strict protected
    function CanApply: Boolean; override;
    function GetEditClass: TControlClass; override;
    procedure InitializeEdit(AEdit: TWinControl); override;
    //
    property Editor: TACLComboBox read GetEditor;
  public
    class function Execute(const ACaption, APrompt: UnicodeString;
      AValues: TACLStringList; var AItemIndex: Integer; AOwner: TComponent = nil): Boolean;
  end;

{$ENDREGION}

  { TACLProgressDialog }

  TACLProgressDialog = class(TACLForm)
  strict private
    FAeroPeak: TACLAeroPeek;
    FShowProgressInCaption: Boolean;
    FTextCaption: UnicodeString;
    FTextProgress: UnicodeString;

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
    procedure Progress(const APosition, ATotal: Int64; const AText: UnicodeString = ''); virtual;
    //
    property ShowProgressInCaption: Boolean read FShowProgressInCaption write FShowProgressInCaption;
    property TextCaption: UnicodeString read FTextCaption write FTextCaption;
    property TextProgress: UnicodeString read FTextProgress write FTextProgress;
    //
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
    procedure EnumLangs(ALangFileBuffer: TACLIniFile; AProc: TACLLanguageDialogEnumProc); virtual; abstract;
    procedure SelectDefaultLanguage; virtual;
    //
    property SelectedTag: NativeInt read GetSelectedTag;
  public
    constructor Create(AOwner: TComponent); override;
    procedure AfterConstruction; override;
  end;

  { TACLLanguageDialog }

  TACLLanguageDialog = class(TACLCustomLanguageDialog)
  protected
    FLangFiles: TACLStringList;

    procedure EnumLangs(ALangFileBuffer: TACLIniFile; AProc: TACLLanguageDialogEnumProc); override;
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
    ButtonApply: UnicodeString;
    FolderBrowserCaption: UnicodeString;
    FolderBrowserNewFolder: UnicodeString;
    FolderBrowserRecursive: UnicodeString;
    MsgDlgButtons: array[TMsgDlgBtn] of UnicodeString;
    MsgDlgCaptions: array[TMsgDlgType] of UnicodeString;
  public
    class constructor Create;
    class procedure ApplyLocalization;
    class procedure ResetLocalization;
  end;

function acMessageBox(AHandle: THandle; const AMessage, ACaption: UnicodeString; AFlags: Integer): Integer;
implementation

type
  TControlAccess = class(TControl);

  { TACLExceptionMessageDialog }

  // Provides per-monitor dpi support for Exception Messages
  TACLExceptionMessageDialog = class
  protected
    class procedure ShowException(E: Exception);
  public
    class destructor Destroy;
    class procedure Register;
  end;

  { TACLMessageTaskDialog }

  // Provides per-monitor dpi support
  TACLMessageTaskDialog = class(TTaskDialog)
  strict private const
    IconMap: array[TMsgDlgType] of TTaskDialogIcon = (
      tdiWarning, tdiError, tdiInformation, tdiInformation, tdiNone
    );
    ModalResults: array[TMsgDlgBtn] of Integer = (
      mrYes, mrNo, mrOk, mrCancel, mrAbort, mrRetry, mrIgnore, mrAll, mrNoToAll, mrYesToAll, -1, mrClose
    );
  strict private type
    TMsgDlgBtns = array of TMsgDlgBtn;
  strict private
    function FlagsToButtons(AFlags: Integer): TMsgDlgBtns;
    function FlagsToDefaultButton(AFlags: Integer; AButtons: TMsgDlgBtns): TMsgDlgBtn;
    function FlagsToDialogType(AFlags: Integer): TMsgDlgType;
  public
    constructor Create(const AMessage, ACaption: UnicodeString; AFlags: Integer); reintroduce;
  end;

function acMessageBox(AHandle: THandle; const AMessage, ACaption: UnicodeString; AFlags: Integer): Integer;
begin
  if AHandle = 0 then
    AHandle := Application.MainFormHandle;

  Application.ModalStarted;
  try
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
      Result := MessageBoxW(AHandle, PWideChar(AMessage), PWideChar(ACaption), AFlags);
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

function TACLFileDialog.Execute(ASaveDialog: Boolean; AOwner: THandle = 0): Boolean;
var
  AWrapper: TACLFileDialogCustomWrapper;
  APrevPath: UnicodeString;
begin
  APrevPath := acGetCurrentDir;
  try
    Application.ModalStarted;
    try
      AWrapper := CreateWrapper(ASaveDialog, AOwner);
      try
        Files.Clear;
        Result := AWrapper.Execute;
        if Result then
        begin
          FFileName := '';
          if Result and (Files.Count > 0) then
            FFileName := Files.Strings[0];
          if Result and ASaveDialog and (ofAutoExtension in Options) then
            FFileName := AutoExtension(FileName);
          if Result and (MRUId <> '') then
            MRUPaths.ValueFromName[MRUId] := acExtractFilePath(FileName);
        end;
      finally
        AWrapper.Free;
      end;
    finally
      Application.ModalFinished;
    end;
  finally
    acSetCurrentDir(APrevPath);
    CoFreeUnusedLibraries;
  end;
end;

function TACLFileDialog.AutoExtension(const AFileName: UnicodeString): UnicodeString;

  function ExtractExt(const S: UnicodeString): UnicodeString;
  var
    ADelimPos: Integer;
  begin
    ADelimPos := acPos(';', S);
    if ADelimPos = 0 then
      ADelimPos := Length(S) + 1;
    Result := Copy(S, 2, ADelimPos - 2);
  end;

  function GetSelectedExt(out AExt: UnicodeString): Boolean;
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
  ASelectedExt: UnicodeString;
begin
  if not GetSelectedExt(ASelectedExt) or (ASelectedExt = '*.*') then
    Result := AFileName
  else
    if acIsOurFile(Filter, AFileName) then
      Result := acChangeFileExt(AFileName, ASelectedExt)
    else
      Result := AFileName + ASelectedExt;
end;

function TACLFileDialog.CreateWrapper(ASaveDialog: Boolean; AOwner: THandle = 0): TACLFileDialogCustomWrapper;
begin
  if IsWinVistaOrLater then
    Result := TACLFileDialogVistaStyleWrapper.Create(AOwner, Self, ASaveDialog)
  else
    Result := TACLFileDialogOldStyleWrapper.Create(AOwner, Self, ASaveDialog);
end;

function TACLFileDialog.GetActualInitialDir: UnicodeString;
begin
  if InitialDir <> '' then
    Result := InitialDir
  else if MRUId <> '' then
    Result := MRUPaths.ValueFromName[MRUId]
  else
    Result := EmptyStr;
end;

{ TACLFileDialogCustomWrapper }

constructor TACLFileDialogCustomWrapper.Create(AParent: THandle; ADialog: TACLFileDialog; ASaveDialog: Boolean);
begin
  inherited Create;
  FDialog := ADialog;
  FSaveDialog := ASaveDialog;
  if AParent = 0 then
    FParent := TACLApplication.GetHandle
  else
    FParent := AParent;

  if ASaveDialog then
    PopulateDefaultExts;
end;

procedure TACLFileDialogCustomWrapper.PopulateDefaultExts;
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

{ TACLFileDialogOldStyleWrapper }

constructor TACLFileDialogOldStyleWrapper.Create(AParent: THandle; ADialog: TACLFileDialog; ASaveDialog: Boolean);
begin
  inherited Create(AParent, ADialog, ASaveDialog);
  FTempInitialPath := ADialog.GetActualInitialDir;
  FTempFilter := AllocFilterStr(ADialog.Filter);
  FTempBufferSize := MAXWORD;
  FTempBuffer := AllocMem(FTempBufferSize);
  ZeroMemory(@FStruct, SizeOf(FStruct));
  FStruct.FlagsEx := 0;
  FStruct.hInstance := HINSTANCE;
  FStruct.hWndOwner := Parent;
  FStruct.lpfnHook := DialogHook;
  FStruct.lpstrFilter := PWideChar(FTempFilter);
  FStruct.lpstrInitialDir := PWideChar(FTempInitialPath);
  FStruct.lpstrTitle := PWideChar(ADialog.Title);
  FStruct.lStructSize := SizeOf(TOpenFilenameW);
  FStruct.nFilterIndex := ADialog.FilterIndex;
  if FDefaultExts <> '' then
    FStruct.lpstrDefExt := PWideChar(FDefaultExts);
  PrepareFlags(FStruct);
  PrepareConst(FStruct);
end;

destructor TACLFileDialogOldStyleWrapper.Destroy;
begin
  FreeMemAndNil(Pointer(FTempBuffer));
  inherited Destroy;
end;

function TACLFileDialogOldStyleWrapper.Execute: Boolean;
begin
  if SaveDialog then
    Result := GetSaveFileNameW(FStruct)
  else
    Result := GetOpenFileNameW(FStruct);

  if Result then
  begin
    GetFileNames(Dialog.Files);
    Dialog.FilterIndex := FStruct.nFilterIndex;
  end;
end;

function TACLFileDialogOldStyleWrapper.AllocFilterStr(const S: UnicodeString): UnicodeString;
var
  P: PWideChar;
begin
  Result := '';
  if S <> '' then
  begin
    Result := S + #0;  // double null terminators
    P := WStrScan(PWideChar(Result), '|');
    while P <> nil do
    begin
      P^ := #0;
      Inc(P);
      P := WStrScan(P, '|');
    end;
  end;
end;

procedure TACLFileDialogOldStyleWrapper.PrepareConst(var AStruct: TOpenFilenameW);
const
  MultiSelectBufferSize = High(Word) - 16;
begin
//  if WindowsVersion in [wvWinME, wvWin2K] then
//    Dec(AStruct.lStructSize, SizeOf(DWORD) shl 1 + SizeOf(Pointer));
  AStruct.nMaxFile := FTempBufferSize - 2; // two zeros in end
  ZeroMemory(FTempBuffer, FTempBufferSize);
  AStruct.lpstrFile := FTempBuffer;
  acStrLCopy(FTempBuffer, Dialog.FileName, Length(Dialog.Filename));
end;

procedure TACLFileDialogOldStyleWrapper.PrepareFlags(var AStruct: TOpenFilenameW);
const
  OpenOptions: array [TACLFileDialogOption] of DWORD = (
    OFN_OVERWRITEPROMPT, OFN_HIDEREADONLY, OFN_NOCHANGEDIR, OFN_NOVALIDATE,
    OFN_ALLOWMULTISELECT, OFN_PATHMUSTEXIST, OFN_FILEMUSTEXIST, OFN_CREATEPROMPT, OFN_SHAREAWARE,
    OFN_NOREADONLYRETURN, OFN_NOTESTFILECREATE, OFN_NONETWORKBUTTON,
    OFN_NODEREFERENCELINKS, OFN_ENABLEINCLUDENOTIFY,
    OFN_ENABLESIZING, OFN_DONTADDTORECENT, OFN_FORCESHOWHIDDEN, 0
  );
var
  Option: TACLFileDialogOption;
begin
  AStruct.Flags := OFN_ENABLEHOOK;
  for Option := Low(TACLFileDialogOption) to High(TACLFileDialogOption) do
  begin
    if Option in Dialog.Options then
      AStruct.Flags := AStruct.Flags or OpenOptions[Option];
  end;
  AStruct.Flags := AStruct.Flags xor OFN_EXPLORER;
end;

procedure TACLFileDialogOldStyleWrapper.GetFileNames(AFileList: TACLStringList);

  function ExtractFileName(P: PWideChar; var S: UnicodeString): PWideChar;
  begin
    Result := WStrScan(P, #0);
    if Result = nil then
    begin
      S := P;
      Result := StrEnd(P);
    end
    else
    begin
      SetString(S, P, Result - P);
      Inc(Result);
    end;
  end;

  procedure ExtractFileNames(P: PWideChar);
  var
    ADirName, AFileName: UnicodeString;
  begin
    P := ExtractFileName(P, ADirName);
    P := ExtractFileName(P, AFileName);
    if AFileName = '' then
      AFileList.Add(ADirName, nil)
    else
    begin
      ADirName := acIncludeTrailingPathDelimiter(ADirName);
      repeat
        if (AFileName[1] <> '\') and ((Length(AFileName) <= 3) or
           (AFileName[2] <> ':') or  (AFileName[3] <> '\'))
        then
          AFileName := ADirName + AFileName;
        AFileList.Add(AFileName, nil);
        P := ExtractFileName(P, AFileName);
      until AFileName = '';
    end;
  end;

begin
  if not (ofAllowMultiSelect in Dialog.Options) or SaveDialog then
    AFileList.Add(FTempBuffer)
  else
    ExtractFileNames(FTempBuffer);
end;

class function TACLFileDialogOldStyleWrapper.DialogHook(Wnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): UINT_PTR;

  procedure CenterWindow(Wnd: HWnd);
  var
    Monitor: TMonitor;
    Rect: TRect;
  begin
    GetWindowRect(Wnd, Rect);
    if Application.MainForm = nil then
      Monitor := Screen.Monitors[0]
    else
      if Assigned(Screen.ActiveForm) then
        Monitor := Screen.ActiveForm.Monitor
      else
        Monitor := Application.MainForm.Monitor;

    SetWindowPos(Wnd, HWND_TOP,
      Monitor.Left + ((Monitor.Width - Rect.Right + Rect.Left) div 2),
      Monitor.Top + ((Monitor.Height - Rect.Bottom + Rect.Top) div 3),
      0, 0, SWP_NOSIZE);
  end;

var
  AParent: HWND;
begin
  if Msg = WM_INITDIALOG then
    CenterWindow(Wnd)
  else
    if (Msg = WM_NOTIFY) and (POFNotify(LParam)^.hdr.code = CDN_INITDONE) then
    begin
      AParent := GetWindowLong(Wnd, GWL_HWNDPARENT);
      CenterWindow(AParent);
      SetForegroundWindow(AParent);
    end;

  Result := DefWindowProc(Wnd, Msg, WParam, LParam);
end;

{ TACLFileDialogVistaStyleWrapper }

constructor TACLFileDialogVistaStyleWrapper.Create(AParent: THandle; ADialog: TACLFileDialog; ASaveDialog: Boolean);
begin
  inherited Create(AParent, ADialog, ASaveDialog);
  if ASaveDialog then
    CoCreateInstance(CLSID_FileSaveDialog, nil, CLSCTX_INPROC_SERVER, IFileSaveDialog, FFileDialog)
  else
    CoCreateInstance(CLSID_FileOpenDialog, nil, CLSCTX_INPROC_SERVER, IFileOpenDialog, FFileDialog);
end;

function TACLFileDialogVistaStyleWrapper.Execute: Boolean;
var
  AFilterIndex: Cardinal;
begin
  Initialize;
  InitializeFilter;
  Result := Succeeded(FileDialog.Show(FParent));
  if Result then
  begin
    QuerySeletectedFiles(Dialog.Files);
    if Succeeded(FileDialog.GetFileTypeIndex(AFilterIndex)) then
      Dialog.FilterIndex := AFilterIndex;
  end;
end;

procedure TACLFileDialogVistaStyleWrapper.Initialize;
const
  DialogOptions: array[TACLFileDialogOption] of DWORD = (
    FOS_OVERWRITEPROMPT, 0, FOS_NOCHANGEDIR, FOS_NOVALIDATE, FOS_ALLOWMULTISELECT,
    FOS_PATHMUSTEXIST, FOS_FILEMUSTEXIST, FOS_CREATEPROMPT, FOS_SHAREAWARE,
    FOS_NOREADONLYRETURN, FOS_NOTESTFILECREATE, 0, FOS_NODEREFERENCELINKS, 0, 0,
    FOS_DONTADDTORECENT, FOS_FORCESHOWHIDDEN, 0
  );
var
  ACookie: DWORD;
  AFlags: DWORD;
  AOption: TACLFileDialogOption;
  ASelectedPath: UnicodeString;
  AShellItem: IShellItem;
begin
  ASelectedPath := Dialog.GetActualInitialDir;
  if Dialog.Title <> '' then
    FFileDialog.SetTitle(PWideChar(Dialog.Title));
  if FDefaultExts <> '' then
    FFileDialog.SetDefaultExtension(PWideChar(FDefaultExts));
  if Dialog.FileName <> '' then
  begin
    FFileDialog.SetFileName(PWideChar(acExtractFileName(Dialog.FileName)));
    if ASelectedPath = '' then
      ASelectedPath := acExtractFilePath(Dialog.FileName);
  end;
  if ASelectedPath <> '' then
  begin
    if Succeeded(SHCreateItemFromParsingName(PWideChar(ASelectedPath), nil, StringToGUID(SID_IShellItem), AShellItem)) then
      FFileDialog.SetFolder(AShellItem);
  end;

  AFlags := 0;
  for AOption := Low(TACLFileDialogOption) to High(TACLFileDialogOption) do
  begin
    if AOption in Dialog.Options then
      AFlags := AFlags or DialogOptions[AOption];
  end;
  FFileDialog.SetOptions(AFlags);

  FFileDialog.Advise(Self, ACookie);
end;

procedure TACLFileDialogVistaStyleWrapper.InitializeFilter;
var
  AFilterStr: TComdlgFilterSpecArray;
  I: Integer;
begin
  acExplodeString(Dialog.Filter, '|', FFilter);
  SetLength(AFilterStr, Length(FFilter) div 2);
  if Length(AFilterStr) > 0 then
  begin
    for I := 0 to Length(AFilterStr) - 1 do
    begin
      AFilterStr[I].pszName := PWideChar(FFilter[2 * I]);
      AFilterStr[I].pszSpec := PWideChar(FFilter[2 * I + 1]);
    end;
    FFileDialog.SetFileTypes(Length(AFilterStr), AFilterStr);
    FFileDialog.SetFileTypeIndex(Dialog.FilterIndex);
  end;
end;

procedure TACLFileDialogVistaStyleWrapper.QuerySeletectedFiles(AFileList: TACLStringList);

  procedure OpenDialogPopulateSelectedFiles(AFileList: TACLStringList);
  var
    ACount: Integer;
    AEnumerator: IEnumShellItems;
    AItems: IShellItemArray;
    AResult: HRESULT;
    AShellItem: IShellItem;
  begin
    if Succeeded((FFileDialog as IFileOpenDialog).GetResults(AItems)) then
    begin
      if Succeeded(AItems.EnumItems(AEnumerator)) then
      begin
        AResult := AEnumerator.Next(1, AShellItem, @ACount);
        while Succeeded(AResult) and (ACount <> 0) do
        begin
          AFileList.Add(GetItemName(AShellItem));
          AResult := AEnumerator.Next(1, AShellItem, @ACount);
        end;
      end;
    end;
  end;

  procedure SaveDialogPopulateSelectedFileName(AFileList: TACLStringList);
  var
    AItem: IShellItem;
  begin
    if Succeeded((FFileDialog as IFileSaveDialog).GetResult(AItem)) then
      AFileList.Add(GetItemName(AItem));
  end;

begin
  AFileList.Clear;
  if SaveDialog then
    SaveDialogPopulateSelectedFileName(AFileList)
  else
    OpenDialogPopulateSelectedFiles(AFileList);
end;

function TACLFileDialogVistaStyleWrapper.OnFileOk(const pfd: IFileDialog): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaStyleWrapper.OnFolderChange(const pfd: IFileDialog): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaStyleWrapper.OnFolderChanging(const pfd: IFileDialog; const psiFolder: IShellItem): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaStyleWrapper.OnOverwrite(const pfd: IFileDialog; const psi: IShellItem; out pResponse: Cardinal): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaStyleWrapper.OnSelectionChange(const pfd: IFileDialog): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaStyleWrapper.OnShareViolation(const pfd: IFileDialog; const psi: IShellItem; out pResponse: Cardinal): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaStyleWrapper.OnTypeChange(const pfd: IFileDialog): HRESULT;
begin
  Result := S_OK;
end;

function TACLFileDialogVistaStyleWrapper.GetItemName(const AItem: IShellItem): UnicodeString;
var
  AError: HRESULT;
  AName: PWideChar;
begin
  Result := '';
  AError := AItem.GetDisplayName(SIGDN_FILESYSPATH, AName);
  if Failed(AError) then
    AError := AItem.GetDisplayName(SIGDN_NORMALDISPLAY, AName);
  if Succeeded(AError) then
  try
    Result := acSimplifyLongFileName(AName);
  finally
    CoTaskMemFree(AName);
  end;
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

procedure TACLCustomDialog.CMDialogKey(var Message: TCMDialogKey);
begin
  case Message.CharCode of
    VK_ESCAPE:
      ModalResult := mrCancel;
    VK_RETURN:
      if CanApply then
      begin
        DoApply;
        ModalResult := mrOk;
      end;
  else
    inherited;
  end;
end;

{$REGION 'InputDialogs'}

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
  FButtonOK := TACLButton(CreateControl(TACLButton, Self, NullRect));
  FButtonOK.Caption := TACLDialogsStrs.MsgDlgButtons[mbOK];
  FButtonOK.OnClick := DoApply;
  FButtonOK.Default := True;
  FButtonOK.ModalResult := mrOk;

  FButtonCancel := TACLButton(CreateControl(TACLButton, Self, NullRect));
  FButtonCancel.Caption := TACLDialogsStrs.MsgDlgButtons[mbCancel];
  FButtonCancel.OnClick := DoCancel;
  FButtonCancel.ModalResult := mrCancel;
  FButtonCancel.Cursor := crHandPoint;

  FButtonApply := TACLButton(CreateControl(TACLButton, Self, NullRect));
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

  R := acRectContent(ClientRect, Rect(Padding.Left, Padding.Top, Padding.Right, Padding.Bottom));
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

  AButtonRect := acRectSetRight(R, R.Right, dpiApply(ButtonWidth, FCurrentPPI));
  AButtonIndent := dpiApply(6, FCurrentPPI) + dpiApply(ButtonWidth, FCurrentPPI);

  if ButtonApply.Visible then
  begin
    ButtonApply.BoundsRect := AButtonRect;
    OffsetRect(AButtonRect, -AButtonIndent, 0);
  end;

  if ButtonCancel.Visible then
  begin
    ButtonCancel.BoundsRect := AButtonRect;
    OffsetRect(AButtonRect, -AButtonIndent, 0);
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
    AClientRect := acRectContent(AClientRect, Rect(Padding.Left, Padding.Top, Padding.Right, Padding.Bottom));
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
    AWidth := acRectWidth(R);
    AHeight := acRectHeight(R);
    TControlAccess(AControl).CanAutoSize(AWidth, AHeight);
  end
  else
    AHeight := AControl.Height;

  AControl.BoundsRect := acRectSetHeight(R, AHeight);
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

class function TACLInputQueryDialog.Execute(const ACaption, APrompt: UnicodeString; var AStr: UnicodeString;
  ASelStart, ASelLength: Integer; AOwner: TComponent; AValidateEvent: TACLInputQueryValidateEvent): Boolean;
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

class function TACLInputQueryDialog.Execute(const ACaption, APrompt: UnicodeString;
  var AStr: UnicodeString; AOwner: TComponent; AValidateEvent: TACLInputQueryValidateEvent): Boolean;
begin
  Result := Execute(ACaption, APrompt, AStr, 0, MaxInt, AOwner, AValidateEvent);
end;

class function TACLInputQueryDialog.Execute(const ACaption: UnicodeString; const APrompts: array of UnicodeString;
  var AValues: array of Variant; AOwner: TComponent; AValidateEvent: TACLInputQueryValidateEvent): Boolean;
var
  ADialog: TACLInputQueryDialog;
begin
  if Length(AValues) <> Length(APrompts) then
    raise EInvalidArgument.Create(ClassName);

  ADialog := CreateNew(AOwner);
  try
    ADialog.Caption := ACaption;
    ADialog.OnValidate := AValidateEvent;
    ADialog.Initialize(Length(AValues));
    for var I := 0 to Length(AValues) - 1 do
      ADialog.InitializeField(I, APrompts[I], AValues[I]);

    Result := ADialog.ShowModal = mrOk;
    if Result then
    begin
      for var I := 0 to Length(AValues) - 1 do
        AValues[I] := ADialog.GetFieldValue(I);
    end;
  finally
    ADialog.Free;
  end;
end;

class function TACLInputQueryDialog.Execute(const ACaption, APrompt: UnicodeString;
  var AValue: Variant; AOwner: TComponent; AValidateEvent: TACLInputQueryValidateEvent): Boolean;
var
  APrompts: array of UnicodeString;
  AValues: array of Variant;
begin
  SetLength(APrompts, 1);
  SetLength(AValues, 1);
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
  AIndex: Integer; const AFieldName: UnicodeString; const AValue: Variant;
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
begin
  AIsValid := True;
  for var I := 0 to Editors.Count - 1 do
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

constructor TACLMemoQueryDialog.Create(AOwnerHandle: THandle);
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

class function TACLMemoQueryDialog.Execute(const ACaption: UnicodeString;
  AItems: TStrings; APopupMenu: TPopupMenu; AOwnerHandle: THandle): Boolean;
var
  AText: UnicodeString;
begin
  AText := AItems.Text;
  Result := Execute(ACaption, AText, APopupMenu, AOwnerHandle);
  if Result then
    AItems.Text := AText;
end;

class function TACLMemoQueryDialog.Execute(const ACaption: UnicodeString;
  var AText: UnicodeString; APopupMenu: TPopupMenu; AOwnerHandle: THandle): Boolean;
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
  FMemo := TACLMemo(CreateControl(TACLMemo, Self, NullRect, alClient));
  FMemo.AlignWithMargins := True;
  FMemo.ScrollBars := ssBoth;
  FMemo.Margins.Margins := Rect(0, 0, 0, 36);
  FMemo.OnKeyDown := MemoKeyDown;

  inherited CreateControls;
end;

procedure TACLMemoQueryDialog.PlaceControls(var R: TRect);
begin
  R.Top := FMemo.BoundsRect.Bottom + dpiApply(10, FCurrentPPI);
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

procedure TACLMemoQueryDialog.MemoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    ModalResult := mrOk;
  end;
end;

{ TACLSelectQueryDialog }

class function TACLSelectQueryDialog.Execute(const ACaption, APrompt: UnicodeString;
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

procedure TACLProgressDialog.Progress(const APosition, ATotal: Int64; const AText: UnicodeString);
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
  if ShowOnTaskBar then
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
  AValue: UnicodeString;
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
  StdButtons: array[TMsgDlgBtn] of UnicodeString = (
    '&Yes', '&No', 'OK', 'Cancel', '&Abort', '&Retry', '&Ignore', '&All', 'N&o to All', 'Yes to &All', '&Help', '&Close'
  );
  StdCaptions: array[TMsgDlgType] of UnicodeString = (
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
  BorderIcons := [biSystemMenu];
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

  FormDisableCloseButton(Handle);
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
  AItem.Data := Pointer(AData.LangID);
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
  if FEditor.Items.FindByData(Pointer(GetUserDefaultUILanguage), AItem) or
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

{ TACLExceptionMessageDialog }

class procedure TACLExceptionMessageDialog.Register;
begin
  ApplicationShowException := ShowException;
end;

class destructor TACLExceptionMessageDialog.Destroy;
begin
  ApplicationShowException := nil;
end;

class procedure TACLExceptionMessageDialog.ShowException(E: Exception);
var
  AMessage: string;
  ASubException: Exception;
  AWndHandle: THandle;
begin
  AMessage := E.Message;
  while True do
  begin
    ASubException := E.GetBaseException;
    if ASubException <> E then
    begin
      E := ASubException;
      if E.Message <> '' then
        AMessage := E.Message;
    end
    else
      Break;
  end;
  AWndHandle := Application.ActiveFormHandle;
  if AWndHandle = 0 then
    AWndHandle := Application.MainFormHandle;
  acMessageBox(AWndHandle, AMessage, Application.Title, MB_OK or MB_ICONSTOP);
end;

{ TACLMessageTaskDialog }

constructor TACLMessageTaskDialog.Create(const AMessage, ACaption: UnicodeString; AFlags: Integer);
var
  AButton: TTaskDialogBaseButtonItem;
  AButtons: TMsgDlgBtns;
  ADefaultButton: TMsgDlgBtn;
  ADialogType: TMsgDlgType;
  I: Integer;
begin
  inherited Create(nil);

  CommonButtons := [];
  ADialogType := FlagsToDialogType(AFlags);
  MainIcon := IconMap[ADialogType];
  Caption := IfThenW(ACaption, TACLDialogsStrs.MsgDlgCaptions[ADialogType]);
  Text := AMessage;

  AButtons := FlagsToButtons(AFlags);
  ADefaultButton := FlagsToDefaultButton(AFlags, AButtons);
  for I := Low(AButtons) to High(AButtons) do
  begin
    AButton := Buttons.Add;
    AButton.Caption := TACLDialogsStrs.MsgDlgButtons[AButtons[I]];
    AButton.Default := AButtons[I] = ADefaultButton;
    AButton.ModalResult := ModalResults[AButtons[I]];
  end;
end;

function TACLMessageTaskDialog.FlagsToButtons(AFlags: Integer): TMsgDlgBtns;
begin
  if AFlags and MB_RETRYCANCEL = MB_RETRYCANCEL then
    Result := [mbRetry, mbCancel]
  else if AFlags and MB_YESNO = MB_YESNO then
    Result := [mbYes, mbNo]
  else if AFlags and MB_YESNOCANCEL = MB_YESNOCANCEL then
    Result := [mbYes, mbNo, mbCancel]
  else if AFlags and MB_ABORTRETRYIGNORE = MB_ABORTRETRYIGNORE then
    Result := [mbAbort, mbRetry, mbIgnore]
  else if AFlags and MB_OKCANCEL = MB_OKCANCEL then
    Result := [mbOK, mbCancel]
  else
    Result := [mbOK];
end;

function TACLMessageTaskDialog.FlagsToDefaultButton(AFlags: Integer; AButtons: TMsgDlgBtns): TMsgDlgBtn;
const
  Masks: array[0..3] of Integer = (MB_DEFBUTTON1, MB_DEFBUTTON2, MB_DEFBUTTON3, MB_DEFBUTTON4);
var
  I: Integer;
begin
  for I := Min(High(Masks), High(AButtons)) downto 0 do
  begin
    if AFlags and Masks[I] <> 0 then
      Exit(AButtons[I]);
  end;
  Result := AButtons[0];
end;

function TACLMessageTaskDialog.FlagsToDialogType(AFlags: Integer): TMsgDlgType;
const
  Map: array[TMsgDlgType] of Integer = (MB_ICONWARNING, MB_ICONERROR, MB_ICONINFORMATION, MB_ICONQUESTION, 0);
var
  AIndex: TMsgDlgType;
begin
  for AIndex := Low(AIndex) to High(AIndex) do
  begin
    if AFlags and Map[AIndex] = Map[AIndex] then
      Exit(AIndex);
  end;
  Result := mtCustom;
end;

initialization
  if IsWinSevenOrLater then
    TACLExceptionMessageDialog.Register;
end.
