{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Editors Controls              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.BaseEditors;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LazUTF8,
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // Vcl
  {Vcl.}ClipBrd,
  {Vcl.}Controls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}StdCtrls,
{$IFDEF FPC}
  {Vcl.}MaskEdit,
{$ELSE}
  {Vcl.}Mask,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Character,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // ACL
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.Parsers,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Forms,
  ACL.UI.ImageList,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type
  TACLEditButtons = class;

  TACLEditInputMask = (eimText, eimInteger, eimFloat, eimDateAndTime);
  TACLEditGetDisplayTextEvent = procedure (Sender: TObject;
    const AValue: Variant; var ADisplayText: string) of object;

  { IACLButtonEdit }

  IACLButtonEdit = interface(IACLButtonOwner)
  ['{D16C5FE2-3CBE-49C0-8C5B-8587CA868890}']
    function ButtonsGetEnabled: Boolean;
    function ButtonsGetOwner: TComponent;
  end;

  { TACLStyleEdit }

  TACLStyleEdit = class(TACLStyle)
  strict private
    function GetBorderColor(Focused: Boolean): TColor;
    function GetContentColor(Enabled: Boolean): TColor;
    function GetTextColor(Enabled: Boolean): TColor;
  protected
    procedure InitializeResources; override;
  public
    procedure DrawBorders(ACanvas: TCanvas; const R: TRect; AFocused: Boolean);
    //# Properties
    property ColorsBorder[Focused: Boolean]: TColor read GetBorderColor;
    property ColorsContent[Enabled: Boolean]: TColor read GetContentColor;
    property ColorsText[Enabled: Boolean]: TColor read GetTextColor;
  published
    property ColorBorder: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorBorderFocused: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorContent: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorContentDisabled: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
    property ColorText: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
    property ColorTextDisabled: TACLResourceColor index 5 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLStyleEditButton }

  TACLStyleEditButton = class(TACLStyleButton)
  protected
    procedure InitializeResources; override;
    procedure InitializeTextures; override;
  end;

  { TACLEditButton }

  TACLEditButton = class(TACLCollectionItem)
  strict private
    FCaption: string;
    FEnabled: Boolean;
    FHint: string;
    FSubClass: TACLButtonSubClass;
    FVisible: Boolean;
    FWidth: Integer;

    FOnClick: TNotifyEvent;

    function GetCollection: TACLEditButtons;
    function GetImageIndex: TImageIndex;
    procedure DoOnClick(Sender: TObject);
    procedure SetCaption(const AValue: string);
    procedure SetEnabled(AValue: Boolean);
    procedure SetImageIndex(AValue: TImageIndex);
    procedure SetVisible(AValue: Boolean);
    procedure SetWidth(AValue: Integer);
  protected
    procedure Calculate(var R: TRect);
    procedure UpdateSubClass;
    //# Properties
    property SubClass: TACLButtonSubClass read FSubClass;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    //# Properties
    property Collection: TACLEditButtons read GetCollection;
  published
    property Caption: string read FCaption write SetCaption;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Hint: string read FHint write FHint;
    property ImageIndex: TImageIndex read GetImageIndex write SetImageIndex default -1;
    property Index stored False;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Width: Integer read FWidth write SetWidth default 18;
    //# Events
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

  { TACLEditButtonSubClass }

  TACLEditButtonSubClass = class(TACLButtonSubClass)
  strict private
    function GetOwnerControl: TControl;
  protected
    procedure StateChanged; override;
  public
    property OwnerControl: TControl read GetOwnerControl;
  end;

  { TACLEditButtons }

  TACLEditButtons = class(TCollection)
  strict private
    FButtonEdit: IACLButtonEdit;

    function GetItem(AIndex: Integer): TACLEditButton;
  protected
    function GetHint(const P: TPoint): string;
    function GetOwner: TPersistent; override;
    procedure Draw(ACanvas: TCanvas);
    procedure MouseDown(Button: TMouseButton; const P: TPoint);
    procedure MouseLeave;
    procedure MouseMove(Shift: TShiftState; const P: TPoint);
    procedure MouseUp(Button: TMouseButton; const P: TPoint);
    procedure Update(Item: TCollectionItem); override;
    //# Properties
    property ButtonEdit: IACLButtonEdit read FButtonEdit;
  public
    constructor Create(AButtonEdit: IACLButtonEdit); virtual;
    function Add(const ACaption: string = ''): TACLEditButton;
    function Find(const P: TPoint; out AButton: TACLEditButton): Boolean;
    //# Properties
    property Items[Index: Integer]: TACLEditButton read GetItem; default;
  end;

  { TACLCustomEdit }

  TACLCustomEdit = class(TACLCustomControl,
    IACLButtonOwner,
    IACLButtonEdit,
    IACLCursorProvider)
  protected const
    ButtonsIndent = 1;
  strict private
    FButtons: TACLEditButtons;
    FButtonsImages: TCustomImageList;
    FButtonsImagesLink: TChangeLink;
    FStyle: TACLStyleEdit;
    FStyleButton: TACLStyleButton;

    FOnChange: TNotifyEvent;

    procedure HandlerEditorEnter(Sender: TObject);
    procedure HandlerEditorExit(Sender: TObject);
    procedure HandlerImageChange(Sender: TObject);
    //# Setters
    procedure SetBorders(AValue: Boolean);
    procedure SetButtons(AValue: TACLEditButtons);
    procedure SetButtonsImages(const AValue: TCustomImageList);
    procedure SetStyle(AValue: TACLStyleEdit);
    procedure SetStyleButton(AValue: TACLStyleButton);
    //# Messages
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
  protected
    FBorders: Boolean;
    FEditor: TWinControl;

    procedure AssignTextDrawParams(ACanvas: TCanvas); virtual;
    procedure BoundsChanged; override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure Changed; virtual;
    procedure CreateHandle; override;
    function CreateStyleButton: TACLStyleButton; virtual;
  {$IFDEF FPC}
    procedure DoAutoSize; override;
  {$ENDIF}
    procedure DoChange; virtual;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoFullRefresh; override;
    procedure FocusChanged; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure SetDefaultSize; override;
    procedure SetFocusToInnerEdit; virtual;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateBordersColor;

    // InnerEdit
    function CanOpenEditor: Boolean; virtual;
    function CreateEditor: TWinControl; virtual;
    procedure EditorClose; virtual;
    procedure EditorOpen;
    procedure EditorUpdateBounds;
    procedure EditorUpdateParams; inline;
    procedure EditorUpdateParamsCore; virtual;

    // Calculation
    function CalculateEditorPosition: TRect; virtual;
    function CalculateTextHeight: Integer; virtual;
    procedure Calculate(R: TRect); virtual;
    procedure CalculateAutoHeight(var ANewHeight: Integer); virtual;
    procedure CalculateButtons(var R: TRect); virtual;
    procedure CalculateContent(const R: TRect); virtual;

    // Drawing
    procedure DrawContent(ACanvas: TCanvas); virtual;
    procedure DrawEditorBackground(ACanvas: TCanvas; const R: TRect); virtual;

    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    // IACLButtonOwner
    procedure IACLButtonOwner.ButtonOwnerRecalculate = FullRefresh;
    function ButtonOwnerGetFont: TFont;
    function ButtonOwnerGetImages: TCustomImageList;
    function ButtonOwnerGetStyle: TACLStyleButton; virtual;

    // IACLButtonEdit
    procedure IACLButtonEdit.ButtonOwnerRecalculate = FullRefresh;
    function ButtonsGetEnabled: Boolean;
    function ButtonsGetOwner: TComponent;

    // IACLCursorProvider
    function GetCursor(const P: TPoint): TCursor; reintroduce; virtual;

    // Properties
    property Borders: Boolean read FBorders write SetBorders default True;
    property Buttons: TACLEditButtons read FButtons write SetButtons;
    property ButtonsImages: TCustomImageList read FButtonsImages write SetButtonsImages;
    property Style: TACLStyleEdit read FStyle write SetStyle;
    property StyleButton: TACLStyleButton read FStyleButton write SetStyleButton;
    // Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function Focused: Boolean; override;
    procedure GetTabOrderList(List: TTabOrderList); override;
    procedure Localize(const ASection: string); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    property AutoSize default True;
    property FocusOnClick;
  end;

  { TACLInnerEdit }

  TACLInnerEdit = class(TCustomMaskEdit, IACLInnerControl)
  strict private
    FInputMask: TACLEditInputMask;
    FOnValidate: TThreadMethod;

    procedure SetInputMask(const Value: TACLEditInputMask);
    // IACLInnerControl
    function GetContainer: TACLCustomEdit;
    function GetInnerContainer: TWinControl;
  protected
  {$IFDEF FPC}
    procedure CalculatePreferredSize(var
      PreferredWidth, PreferredHeight: Integer;
      WithThemeSpace: Boolean); override;
  {$ENDIF}
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure DeleteNearWord(AStartPosition, ADirection: Integer);
    procedure DeleteWordFromLeftOfCursor;
    procedure DeleteWordFromRightOfCursor;

    // Numberic
    function CanType(Key: WideChar): Boolean; virtual;
    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override; {$IFDEF FPC}final;{$ENDIF}
    procedure KeyPressCore(var Key: WideChar); virtual;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
  {$IFDEF FPC}
    procedure Utf8KeyPress(var Key: TUTF8Char); override; final;
  {$ENDIF}

    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    //# Messages
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMWantSpecialKey(var Message: TMessage); message CM_WANTSPECIALKEY;
    procedure WMContextMenu(var Message: TWMContextMenu); message WM_CONTEXTMENU;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMPaste(var Message: TMessage); message WM_PASTE;
    //# Properties
    property Container: TACLCustomEdit read GetContainer;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    //# Properties
    property AutoSelect;
    property BorderStyle;
    property InputMask: TACLEditInputMask read FInputMask write SetInputMask;
    property MaxLength;
    property PasswordChar;
    //# Events
    property OnChange;
    property OnValidate: TThreadMethod read FOnValidate write FOnValidate;
  end;

  { TACLCustomInplaceEdit }

  TACLCustomInplaceEdit = class(TACLCustomEdit, IACLInplaceControl)
  strict private
    FInplace: Boolean;
  protected
    // IACLInplaceControl
    function IACLInplaceControl.InplaceIsFocused = Focused;
    function InplaceGetValue: string; virtual; abstract;
    procedure InplaceSetFocus; virtual;
    procedure InplaceSetValue(const AValue: string); virtual; abstract;
    //# Properties
    property Inplace: Boolean read FInplace;
  public
    constructor CreateInplace(const AParams: TACLInplaceInfo); virtual;
  end;

  { TACLIncrementalSearch }

  TACLIncrementalSearchMode = (ismSearch, ismFilter);
  TACLIncrementalSearch = class
  public type
    TLookupEvent = procedure (Sender: TObject; var AFound: Boolean) of object;
  strict private
    FLocked: Boolean;
    FMode: TACLIncrementalSearchMode;
    FText: string;
    FTextLength: Integer;

    FOnLookup: TLookupEvent;
    FOnChange: TNotifyEvent;

    function GetActive: Boolean;
    procedure SetText(const AValue: string);
    procedure SetMode(const AValue: TACLIncrementalSearchMode);
  protected
    procedure Changed;
  public
    procedure Cancel;
    function CanProcessKey(Key: Word; Shift: TShiftState;
      ACanStartEvent: TACLKeyPreviewEvent = nil): Boolean;
    function Contains(const AText: string): Boolean;
    function GetHighlightBounds(const AText: string;
      out AHighlightStart, AHighlightFinish: Integer): Boolean;
    function ProcessKey(Key: WideChar): Boolean; overload;
    function ProcessKey(Key: Word; Shift: TShiftState): Boolean; overload;
    //# Properties
    property Active: Boolean read GetActive;
    property Mode: TACLIncrementalSearchMode read FMode write SetMode;
    property Text: string read FText write SetText;
    //# Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnLookup: TLookupEvent read FOnLookup write FOnLookup;
  end;

function EditDateTimeFormat: TFormatSettings;
function EditDateTimeFormatToMask: string;
function EditDateTimeFormatToString: string;

procedure SkipDefaultHandler(WndHandle: HWND; var Message: TMessage);
implementation

{$IFDEF LCLGtk2}
uses
  glib2;
{$ENDIF}

type
  TWinControlAccess = class(TWinControl);

const
  EditorInnerBorderSize = 1;
  EditorOuterBorderSize = 1;
  EditorBorderSize = EditorInnerBorderSize + EditorOuterBorderSize;

function EditDateTimeFormat: TFormatSettings;
begin
  Result := InvariantFormatSettings;
  Result.LongTimeFormat := 'hh:mm:ss';
  Result.ShortDateFormat := 'yyyy.MM.dd';
  Result.TimeSeparator := ':';
  Result.DateSeparator := '.';
end;

function EditDateTimeFormatToString: string;
begin
  with EditDateTimeFormat do
    Result := ShortDateFormat + ' ' + LongTimeFormat;
end;

function EditDateTimeFormatToMask: string;
var
  I: Integer;
  U: UnicodeString;
begin
  U := _U(EditDateTimeFormatToString);
  for I := 1 to Length(U) do
  begin
    if U[I].IsLetter then
      U[I] := '0';
  end;
  Result := _S(U) + ';1;_';
end;

procedure SkipDefaultHandler(WndHandle: HWND; var Message: TMessage);
begin
{$IFDEF LCLGtk2}
  // AI: Простое выставление Result в 1 не работает - gtk2 все равно обрабатывает
  // вставку самостоятельно. Чтобы загасить стандартный обработчик нужно стопать сигнал.
  if Message.Msg = WM_PASTE then
    g_signal_stop_emission_by_name({%H-}Pointer(WndHandle), 'paste-clipboard');
  if Message.Msg = WM_COPY then
    g_signal_stop_emission_by_name({%H-}Pointer(WndHandle), 'copy-clipboard');
  if Message.Msg = WM_CUT then
    g_signal_stop_emission_by_name({%H-}Pointer(WndHandle), 'cut-clipboard');
{$ENDIF}
end;

{ TACLStyleEdit }

procedure TACLStyleEdit.DrawBorders(ACanvas: TCanvas; const R: TRect; AFocused: Boolean);
var
  AFocusRect: TRect;
begin
  if IsWin11OrLater then
  begin
    acDrawFrame(ACanvas, R, ColorBorder.AsColor);
    if AFocused then
    begin
      AFocusRect := R.Split(srBottom, Scale(acTextIndent));
      acFillRect(ACanvas, AFocusRect, ColorBorderFocused.AsColor);
      acExcludeFromClipRegion(ACanvas.Handle, AFocusRect);
    end;
  end
  else
    acDrawFrame(ACanvas, R, ColorsBorder[AFocused]);
end;

function TACLStyleEdit.GetBorderColor(Focused: Boolean): TColor;
begin
  if Focused then
    Result := ColorBorderFocused.AsColor
  else
    Result := ColorBorder.AsColor;
end;

function TACLStyleEdit.GetContentColor(Enabled: Boolean): TColor;
begin
  if Enabled then
    Result := ColorContent.AsColor
  else
    Result := ColorContentDisabled.AsColor;
end;

function TACLStyleEdit.GetTextColor(Enabled: Boolean): TColor;
begin
  if Enabled then
    Result := ColorText.AsColor
  else
    Result := ColorTextDisabled.AsColor
end;

procedure TACLStyleEdit.InitializeResources;
begin
  ColorBorder.InitailizeDefaults('EditBox.Colors.Border');
  ColorBorderFocused.InitailizeDefaults('EditBox.Colors.BorderFocused');
  ColorContent.InitailizeDefaults('EditBox.Colors.Content');
  ColorContentDisabled.InitailizeDefaults('EditBox.Colors.ContentDisabled');
  ColorText.InitailizeDefaults('EditBox.Colors.Text');
  ColorTextDisabled.InitailizeDefaults('EditBox.Colors.TextDisabled');
end;

{ TACLStyleEditButton }

procedure TACLStyleEditButton.InitializeResources;
begin
  ColorText.InitailizeDefaults('EditBox.Colors.ButtonText');
  ColorTextDisabled.InitailizeDefaults('EditBox.Colors.ButtonTextDisabled');
  ColorTextHover.InitailizeDefaults('EditBox.Colors.ButtonTextHover');
  ColorTextPressed.InitailizeDefaults('EditBox.Colors.ButtonTextPressed');
  InitializeTextures;
end;

procedure TACLStyleEditButton.InitializeTextures;
begin
  Texture.InitailizeDefaults('EditBox.Textures.Button');
end;

{ TACLEditButton }

constructor TACLEditButton.Create(ACollection: TCollection);
begin
  FWidth := 18;
  FEnabled := True;
  FVisible := True;
  FSubClass := TACLEditButtonSubClass.Create(TACLEditButtons(ACollection).ButtonEdit);
  inherited Create(ACollection);
  FSubClass.OnClick := DoOnClick;
  ImageIndex := -1;
end;

destructor TACLEditButton.Destroy;
begin
  FreeAndNil(FSubClass);
  inherited Destroy;
end;

procedure TACLEditButton.Assign(Source: TPersistent);
begin
  if Source is TACLEditButton then
  begin
    Caption := TACLEditButton(Source).Caption;
    Hint := TACLEditButton(Source).Hint;
    ImageIndex := TACLEditButton(Source).ImageIndex;
    Visible := TACLEditButton(Source).Visible;
    Width := TACLEditButton(Source).Width;
  end;
end;

procedure TACLEditButton.Calculate(var R: TRect);
begin
  if SubClass <> nil then
  begin
    SubClass.IsEnabled := Enabled and ((Collection.ButtonEdit = nil) or Collection.ButtonEdit.ButtonsGetEnabled);
    SubClass.Calculate(R.Split(srRight, IfThen(Visible, dpiApply(Width, SubClass.CurrentDpi))));
    R.Right := SubClass.Bounds.Left;
  end;
end;

procedure TACLEditButton.DoOnClick(Sender: TObject);
begin
  CallNotifyEvent(Sender, OnClick);
end;

procedure TACLEditButton.UpdateSubClass;
begin
  SubClass.Caption := IfThenW(SubClass.ImageIndex < 0, Caption);
end;

function TACLEditButton.GetCollection: TACLEditButtons;
begin
  Result := TACLEditButtons(inherited Collection);
end;

function TACLEditButton.GetImageIndex: TImageIndex;
begin
  Result := SubClass.ImageIndex;
end;

procedure TACLEditButton.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    UpdateSubClass;
    Changed(False);
  end;
end;

procedure TACLEditButton.SetEnabled(AValue: Boolean);
begin
  if AValue <> Enabled then
  begin
    FEnabled := AValue;
    Changed(False);
  end;
end;

procedure TACLEditButton.SetImageIndex(AValue: TImageIndex);
begin
  if ImageIndex <> AValue then
  begin
    SubClass.ImageIndex := AValue;
    UpdateSubClass;
    Changed(False);
  end;
end;

procedure TACLEditButton.SetVisible(AValue: Boolean);
begin
  if Visible <> AValue then
  begin
    FVisible := AValue;
    Changed(True);
  end;
end;

procedure TACLEditButton.SetWidth(AValue: Integer);
begin
  if FWidth <> AValue then
  begin
    FWidth := AValue;
    Changed(True);
  end;
end;

{ TACLEditButtons }

constructor TACLEditButtons.Create(AButtonEdit: IACLButtonEdit);
begin
  FButtonEdit := AButtonEdit;
  inherited Create(TACLEditButton);
end;

function TACLEditButtons.Add(const ACaption: string = ''): TACLEditButton;
begin
  BeginUpdate;
  try
    Result := TACLEditButton(inherited Add);
    Result.Caption := ACaption;
  finally
    EndUpdate;
  end;
end;

function TACLEditButtons.GetHint(const P: TPoint): string;
var
  AItem: TACLEditButton;
begin
  if Find(P, AItem) then
    Result := AItem.Hint
  else
    Result := '';
end;

function TACLEditButtons.GetItem(AIndex: Integer): TACLEditButton;
begin
  Result := TACLEditButton(inherited Items[AIndex]);
end;

function TACLEditButtons.GetOwner: TPersistent;
begin
  if ButtonEdit <> nil then
    Result := ButtonEdit.ButtonsGetOwner
  else
    Result := inherited GetOwner;
end;

procedure TACLEditButtons.Draw(ACanvas: TCanvas);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].SubClass.Draw(ACanvas);
end;

function TACLEditButtons.Find(const P: TPoint; out AButton: TACLEditButton): Boolean;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
    if PtInRect(Items[I].SubClass.Bounds, P) then
    begin
      AButton := Items[I];
      Exit(True);
    end;
  Result := False;
end;

procedure TACLEditButtons.MouseDown(Button: TMouseButton; const P: TPoint);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].SubClass.MouseDown(Button, P);
end;

procedure TACLEditButtons.MouseLeave;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].SubClass.MouseMove([], InvalidPoint);
end;

procedure TACLEditButtons.MouseMove(Shift: TShiftState; const P: TPoint);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].SubClass.MouseMove(Shift, P);
end;

procedure TACLEditButtons.MouseUp(Button: TMouseButton; const P: TPoint);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].SubClass.MouseUp(Button, P);
end;

procedure TACLEditButtons.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  ButtonEdit.ButtonOwnerRecalculate;
end;

{ TACLEditButtonSubClass }

procedure TACLEditButtonSubClass.StateChanged;
begin
  if State = absHover then
    Application.CancelHint;
  inherited StateChanged;
end;

function TACLEditButtonSubClass.GetOwnerControl: TControl;
var
  AEdit: IACLButtonEdit;
begin
  if Supports(Owner, IACLButtonEdit, AEdit) and (AEdit.ButtonsGetOwner is TControl) then
    Result := TControl(AEdit.ButtonsGetOwner)
  else
    Result := nil;
end;

{ TACLCustomEdit }

constructor TACLCustomEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  FStyle := TACLStyleEdit.Create(Self);
  FStyleButton := CreateStyleButton;
  FButtons := TACLEditButtons.Create(Self);
  FButtonsImagesLink := TChangeLink.Create;
  FButtonsImagesLink.OnChange := HandlerImageChange;
  FBorders := True;
  AutoSize := True;
  TabStop := True;
end;

destructor TACLCustomEdit.Destroy;
begin
  ButtonsImages := nil;
  FreeAndNil(FButtonsImagesLink);
  FreeAndNil(FStyleButton);
  FreeAndNil(FButtons);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLCustomEdit.AfterConstruction;
begin
  inherited AfterConstruction;
  EditorOpen;
end;

procedure TACLCustomEdit.BeforeDestruction;
begin
  inherited BeforeDestruction;
  EditorClose;
end;

procedure TACLCustomEdit.AssignTextDrawParams(ACanvas: TCanvas);
begin
  ACanvas.Font := Font;
  ACanvas.Font.Color := Style.ColorsText[Enabled];
  ACanvas.Brush.Color := Style.ColorsContent[Enabled];
end;

function TACLCustomEdit.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  if AutoSize then
    CalculateAutoHeight(NewHeight);
  Result := True;
end;

function TACLCustomEdit.ButtonsGetEnabled: Boolean;
begin
  Result := Enabled;
end;

function TACLCustomEdit.ButtonsGetOwner: TComponent;
begin
  Result := Self;
end;

function TACLCustomEdit.ButtonOwnerGetFont: TFont;
begin
  Result := Font;
end;

function TACLCustomEdit.ButtonOwnerGetImages: TCustomImageList;
begin
  Result := ButtonsImages;
end;

function TACLCustomEdit.ButtonOwnerGetStyle: TACLStyleButton;
begin
  Result := StyleButton;
end;

procedure TACLCustomEdit.Calculate(R: TRect);
begin
  if Borders then
    R.Inflate(-EditorOuterBorderSize);
  CalculateButtons(R);
  if Borders then
    R.Inflate(-EditorInnerBorderSize);
  CalculateContent(R);
  EditorUpdateBounds;
end;

procedure TACLCustomEdit.CalculateAutoHeight(var ANewHeight: Integer);
begin
  ANewHeight := CalculateTextHeight + dpiApply(4, FCurrentPPI);
  if Borders then
    Inc(ANewHeight, 2 * EditorBorderSize);
end;

procedure TACLCustomEdit.CalculateButtons(var R: TRect);
var
  AIndent: Integer;
  AIndex: Integer;
  ARect: TRect;
begin
  AIndent := dpiApply(ButtonsIndent, FCurrentPPI);
  ARect := R;
  ARect.Inflate(-AIndent);
  for AIndex := Buttons.Count - 1 downto 0 do
  begin
    Buttons.Items[AIndex].Calculate(ARect);
    Dec(ARect.Right, AIndent);
  end;
  R.Right := ARect.Right + AIndent;
end;

procedure TACLCustomEdit.CalculateContent(const R: TRect);
begin
  // do nothing
end;

function TACLCustomEdit.CalculateEditorPosition: TRect;
begin
  Result := ClientRect;
  Result.Inflate(-EditorBorderSize);
end;

function TACLCustomEdit.CalculateTextHeight: Integer;
begin
  Result := acFontHeight(Font);
end;

procedure TACLCustomEdit.Changed;
begin
  if not (csLoading in ComponentState) then
    DoChange;
  Invalidate;
end;

procedure TACLCustomEdit.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Style.TargetDPI := AValue;
  StyleButton.TargetDPI := AValue;
end;

procedure TACLCustomEdit.CreateHandle;
begin
  inherited CreateHandle;
  BoundsChanged;
end;

{$IFDEF FPC}
procedure TACLCustomEdit.DoAutoSize;
begin
  // do nothing
end;
{$ENDIF}

procedure TACLCustomEdit.DoChange;
begin
  CallNotifyEvent(Self, OnChange);
end;

procedure TACLCustomEdit.DoEnter;
begin
  if FEditor = nil then
    inherited DoEnter;
end;

procedure TACLCustomEdit.DoExit;
begin
  if FEditor = nil then
    inherited DoExit;
end;

procedure TACLCustomEdit.DoFullRefresh;
begin
  if FEditor <> nil then
    EditorUpdateParams;
  BoundsChanged;
end;

procedure TACLCustomEdit.FocusChanged;
begin
  inherited;
  Invalidate;
end;

function TACLCustomEdit.CreateStyleButton: TACLStyleButton;
begin
  Result := TACLStyleEditButton.Create(Self);
end;

function TACLCustomEdit.CanOpenEditor: Boolean;
begin
  Result := not (csDesigning in ComponentState);
end;

function TACLCustomEdit.CreateEditor: TWinControl;
begin
  Result := nil;
end;

procedure TACLCustomEdit.SetDefaultSize;
begin
  SetBounds(Left, Top, 121, 21);
end;

procedure TACLCustomEdit.SetFocusToInnerEdit;
begin
  if FEditor <> nil then
    FEditor.SetFocus;
end;

procedure TACLCustomEdit.DrawEditorBackground(ACanvas: TCanvas; const R: TRect);
begin
  acFillRect(ACanvas, R, Style.ColorsContent[Enabled]);
  if Borders then
    Style.DrawBorders(ACanvas, R, Focused and not (csDesigning in ComponentState));
end;

procedure TACLCustomEdit.DrawContent(ACanvas: TCanvas);
begin
  // do nothing
end;

procedure TACLCustomEdit.EditorOpen;
begin
  if (FEditor = nil) and CanOpenEditor then
  begin
    FEditor := CreateEditor;
    if FEditor <> nil then
    begin
      TWinControlAccess(FEditor).OnExit := HandlerEditorExit;
      TWinControlAccess(FEditor).OnEnter := HandlerEditorEnter;
      TWinControlAccess(FEditor).Parent := Self;
      EditorUpdateBounds;
      EditorUpdateParams;
      EditorUpdateBounds;
    end;
  end;
end;

procedure TACLCustomEdit.EditorClose;
begin
  FreeAndNil(FEditor);
  UpdateBordersColor;
end;

procedure TACLCustomEdit.EditorUpdateBounds;
var
  LTemp: TRect;
  LTempHeight: Integer;
  LTempWidth: Integer;
begin
  if FEditor <> nil then
  begin
    LTemp := CalculateEditorPosition;
    LTempHeight := LTemp.Height;
    LTempWidth := LTemp.Width;
    TWinControlAccess(FEditor).CanAutoSize(LTempWidth, LTempHeight);
    if LTempHeight <> LTemp.Height then
      LTemp.CenterVert(LTempHeight);
    FEditor.BoundsRect := LTemp;
    if HandleAllocated then
    begin
      if FEditor.Height > LTemp.Height then
      begin
        LTemp.Offset(-FEditor.Left, -FEditor.Top);
        SetWindowRgn(FEditor.Handle, CreateRectRgnIndirect(LTemp), False);
      end
      else
        SetWindowRgn(FEditor.Handle, 0, False);
    end;
  end;
end;

procedure TACLCustomEdit.EditorUpdateParams;
begin
  if FEditor <> nil then
    EditorUpdateParamsCore;
end;

procedure TACLCustomEdit.EditorUpdateParamsCore;
begin
  TWinControlAccess(FEditor).Color := Style.ColorsContent[Enabled];
  TWinControlAccess(FEditor).Font := Font;
  TWinControlAccess(FEditor).Font.Color := Style.ColorsText[Enabled];
end;

procedure TACLCustomEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  Buttons.MouseDown(Button, Point(X, Y));
end;

procedure TACLCustomEdit.MouseLeave;
begin
  inherited MouseLeave;
  Buttons.MouseLeave;
end;

procedure TACLCustomEdit.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  Buttons.MouseMove(Shift, Point(X, Y));
end;

procedure TACLCustomEdit.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  Buttons.MouseUp(Button, Point(X, Y));
end;

procedure TACLCustomEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = ButtonsImages then
      ButtonsImages := nil;
  end;
end;

procedure TACLCustomEdit.Paint;
begin
  DrawEditorBackground(Canvas, ClientRect);
  DrawContent(Canvas);
  Buttons.Draw(Canvas);
end;

procedure TACLCustomEdit.BoundsChanged;
begin
  inherited;
  if not (csDestroying in ComponentState) then
    Calculate(ClientRect);
{$IFDEF FPC}
  // RedrawOnResize? TACLTextureEditorDialog
  if (Parent <> nil) and (wcfAligningControls in TWinControlAccess(Parent).FWinControlFlags) then
    Invalidate;
{$ENDIF}
end;

procedure TACLCustomEdit.UpdateBordersColor;
begin
  if HandleAllocated then Invalidate;
end;

procedure TACLCustomEdit.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  SetFocusToInnerEdit;
end;

function TACLCustomEdit.Focused: Boolean;
begin
  Result := inherited Focused or (FEditor <> nil) and FEditor.Focused;
end;

procedure TACLCustomEdit.CMEnabledChanged(var Message: TMessage);
begin
  EditorUpdateParams;
  BoundsChanged;
  inherited;
end;

procedure TACLCustomEdit.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FullRefresh;
end;

procedure TACLCustomEdit.CMHintShow(var Message: TCMHintShow);
var
  AHint: string;
begin
  AHint := Buttons.GetHint(Message.HintInfo^.CursorPos);
  if AHint <> '' then
    Message.HintInfo^.HintStr := AHint
  else
    inherited;
end;

function TACLCustomEdit.GetCursor(const P: TPoint): TCursor;
var
  AItem: TACLEditButton;
begin
  if Buttons.Find(P, AItem) and AItem.Enabled then
    Result := crHandPoint
  else
    Result := Cursor;
end;

procedure TACLCustomEdit.GetTabOrderList(List: TTabOrderList);
begin
  inherited GetTabOrderList(List);
  if (FEditor <> nil) and (List.IndexOf(FEditor) >= 0) then
    List.Remove(Self);
end;

procedure TACLCustomEdit.Localize(const ASection: string);
var
  I: Integer;
begin
  inherited Localize(ASection);

  if LangFile.ExistsSection(ASection) then
  begin
    Buttons.BeginUpdate;
    try
      for I := 0 to Buttons.Count - 1 do
        Buttons[I].Caption := LangGet(ASection, 'b[' + IntToStr(I) + ']');
    finally
      Buttons.EndUpdate;
    end;
  end;
end;

procedure TACLCustomEdit.HandlerEditorEnter(Sender: TObject);
begin
  FocusChanged;
  CallNotifyEvent(Self, OnEnter);
end;

procedure TACLCustomEdit.HandlerEditorExit(Sender: TObject);
begin
  FocusChanged;
  CallNotifyEvent(Self, OnExit);
end;

procedure TACLCustomEdit.HandlerImageChange(Sender: TObject);
begin
  FullRefresh;
end;

procedure TACLCustomEdit.SetBorders(AValue: Boolean);
begin
  if AValue <> FBorders then
  begin
    FBorders := AValue;
    AdjustSize;
    Realign;
    Invalidate;
  end;
end;

procedure TACLCustomEdit.SetButtonsImages(const AValue: TCustomImageList);
begin
  acSetImageList(AValue, FButtonsImages, FButtonsImagesLink, Self);
end;

procedure TACLCustomEdit.SetButtons(AValue: TACLEditButtons);
begin
  Buttons.Assign(AValue);
end;

procedure TACLCustomEdit.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if AutoSize and not (csLoading in ComponentState) then
    CalculateAutoHeight(AHeight);
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
end;

procedure TACLCustomEdit.SetStyle(AValue: TACLStyleEdit);
begin
  FStyle.Assign(AValue);
end;

procedure TACLCustomEdit.SetStyleButton(AValue: TACLStyleButton);
begin
  FStyleButton.Assign(AValue);
end;

{ TACLInnerEdit }

constructor TACLInnerEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BorderStyle := bsNone;
  AutoSelect := True;
end;

procedure TACLInnerEdit.DeleteNearWord(AStartPosition, ADirection: Integer);
const
  Delims: UnicodeString = acParserDefaultDelimiterChars;
var
  LPosition: Integer;
  LText: UnicodeString;
  LTextLen: Integer;
begin
  LText := _U(Text);
  LTextLen := Length(LText);
  LPosition := AStartPosition + ADirection;

  // Skip spaces
  while InRange(LPosition, 1, LTextLen) and acContains(LText[LPosition], Delims) do
    Inc(LPosition, ADirection);

  // Skip first word
  while InRange(LPosition, 1, LTextLen) and not acContains(LText[LPosition], Delims) do
    Inc(LPosition, ADirection);
    
  Text := _S(
    Copy(LText, 1, Min(AStartPosition, LPosition)) +
    Copy(LText, Max(AStartPosition, LPosition) + 1));
  SelStart := Min(AStartPosition, LPosition);
end;

procedure TACLInnerEdit.DeleteWordFromLeftOfCursor;
begin
  DeleteNearWord(SelStart, -1);
end;

procedure TACLInnerEdit.DeleteWordFromRightOfCursor;
begin
  DeleteNearWord(SelStart, 1);
end;

function TACLInnerEdit.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  NewHeight := acFontHeight(Font);
  Result := True;
end;

function TACLInnerEdit.CanType(Key: WideChar): Boolean;
var
  LTemp: string;
  LTempD: Double;
  LTempI: Integer;
  LText: UnicodeString;
begin
  Result := True;
  if InputMask in [eimInteger, eimFloat] then
  begin
    LText := _U(Text);
    LTemp := _S(Copy(LText, 1, SelStart) + Key + Copy(LText, SelStart + SelLength + 1));
    if (LTemp <> '-') and (LTemp <> '+') then
    begin
      if InputMask = eimFloat then
        Result := TryStrToFloat(LTemp, LTempD) or TryStrToFloat(LTemp, LTempD, InvariantFormatSettings)
      else
        Result := TryStrToInt(LTemp, LTempI);
    end;
  end;
{$IFDEF DEBUG}
  if not Result and (InputMask = eimFloat) and (Key = '.') then
    raise Exception.CreateFmt('Test: %d, %d, (%s)', [SelStart, SelLength, LTemp]);
{$ENDIF}
end;

procedure TACLInnerEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  Container.KeyDown(Key, Shift);
  if [ssCtrl, ssShift, ssAlt] * Shift = [ssCtrl] then
  begin
    if (Key = 65) and ReadOnly then
      SelectAll;
    if Key = VK_BACK then
      DeleteWordFromLeftOfCursor
    else if Key = VK_DELETE then
      DeleteWordFromRightOfCursor
    else
      Exit;
    Key := 0;
  end;
end;

procedure TACLInnerEdit.KeyPress(var Key: Char);
begin
  inherited;
{$IFNDEF FPC}
  KeyPressCore(Key);
{$ENDIF}
  Container.KeyPress(Key);
end;

procedure TACLInnerEdit.KeyPressCore(var Key: WideChar);
begin
  if not IsMasked and (InputMask <> eimText) and not Key.IsControl then
  begin
    if (InputMask = eimFloat) and (Key = '.') then
      Key := FormatSettings.DecimalSeparator;
    if not CanType(Key) then
      Key := #0;
  end;
  case Ord(Key) of
    VK_RETURN, VK_ESCAPE:
      Key := #0;
  end;
end;

procedure TACLInnerEdit.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited;
  Container.KeyUp(Key, Shift);
end;

{$IFDEF FPC}
procedure TACLInnerEdit.Utf8KeyPress(var Key: TUTF8Char);
begin
  inherited;
  ProcessUtf8KeyPress(Key, KeyPressCore);
  Container.UTF8KeyPress(Key);
end;
{$ENDIF}

procedure TACLInnerEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  Container.MouseDown(Button, Shift, X + Left, Y + Top);
end;

procedure TACLInnerEdit.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  Container.MouseMove(Shift, X + Left, Y + Top);
end;

procedure TACLInnerEdit.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  Container.MouseUp(Button, Shift, X + Left, Y + Top);
end;

function TACLInnerEdit.GetInnerContainer: TWinControl;
begin
  Result := Parent;
end;

procedure TACLInnerEdit.CMEnter(var Message: TCMEnter);
begin
  inherited;
  Parent.Perform(CM_ENTER, 0, 0);
end;

procedure TACLInnerEdit.CMExit(var Message: TCMExit);
begin
  inherited;
  Parent.Perform(CM_EXIT, 0, 0);
end;

procedure TACLInnerEdit.CMTextChanged(var Message: TMessage);
begin
  if (Parent = nil) or not (csLoading in Parent.ComponentState) then
    inherited;
end;

procedure TACLInnerEdit.CMWantSpecialKey(var Message: TMessage);
begin
  Message.Result := Parent.Perform(Message.Msg, Message.WParam, Message.LParam);
  if Message.Result = 0 then
    inherited;
end;

procedure TACLInnerEdit.WMContextMenu(var Message: TWMContextMenu);
begin
  if not Focused then
  begin
    SetFocus;
    SelectAll;
  end;

  Message.Result := Parent.Perform(Message.Msg, Parent.Handle, TMessage(Message).LParam);
  if Message.Result = 0 then
    inherited;
end;

procedure TACLInnerEdit.WMNCHitTest(var Message: TWMNCHitTest);
begin
  if csDesigning in Container.ComponentState then
    Message.Result := HTTRANSPARENT
  else
    inherited;
end;

procedure TACLInnerEdit.WMPaste(var Message: TMessage);
begin
  SelText := Clipboard.AsText;
  SkipDefaultHandler(Handle, Message);
  if Assigned(OnValidate) then OnValidate();
end;

function TACLInnerEdit.GetContainer: TACLCustomEdit;
begin
  Result := Parent as TACLCustomEdit;
end;

procedure TACLInnerEdit.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if AutoSize then
    AHeight := acFontHeight(Font);
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
end;

procedure TACLInnerEdit.SetInputMask(const Value: TACLEditInputMask);
begin
  if FInputMask <> Value then
  begin
    FInputMask := Value;
    EditMask := IfThenW(InputMask = eimDateAndTime, EditDateTimeFormatToMask);
    Hint := IfThenW(InputMask = eimDateAndTime, EditDateTimeFormatToString);
  end;
end;

{$IFDEF FPC}
procedure TACLInnerEdit.CalculatePreferredSize(
  var PreferredWidth, PreferredHeight: Integer; WithThemeSpace: Boolean);
begin
  CanAutoSize(PreferredWidth, PreferredHeight);
end;
{$ENDIF}

{ TACLCustomInplaceEdit }

constructor TACLCustomInplaceEdit.CreateInplace(const AParams: TACLInplaceInfo);
var
  ARect: TRect;
begin
  FInplace := True;
  Create(nil);
  Borders := False;
  AutoSize := False;
  OnKeyDown := AParams.OnKeyDown;
  OnExit := AParams.OnApply;
  Parent := AParams.Parent;

  ARect := AParams.Bounds;
  ARect.Left := AParams.TextBounds.Left - dpiApply(2, FCurrentPPI);
  BoundsRect := ARect;
end;

procedure TACLCustomInplaceEdit.InplaceSetFocus;
begin
  SetFocus;
end;

{ TACLIncrementalSearch }

procedure TACLIncrementalSearch.Cancel;
begin
  SetText('');
end;

function TACLIncrementalSearch.CanProcessKey(Key: Word;
  Shift: TShiftState; ACanStartEvent: TACLKeyPreviewEvent = nil): Boolean;
const
  ControlKeys = [91, VK_F1..VK_F20, VK_CONTROL, VK_SHIFT, VK_MENU, VK_RETURN, VK_DELETE, VK_INSERT];
begin
  Result := True;
  if [ssShift, ssCtrl, ssAlt] * Shift <> [] then
    Exit(False);
  if Key in ControlKeys then
    Exit(False);
  if not Active then
  begin
    if Key = VK_SPACE then
      Exit(False);
    if Assigned(ACanStartEvent) then
      ACanStartEvent(Key, Shift, Result);
  end;
end;

function TACLIncrementalSearch.ProcessKey(Key: WideChar): Boolean;
begin
  Result := not Key.IsControl and (Key <> #8) and (Active or (Key <> ' '));
  if Result then
    SetText(Text + _S(Key));
end;

function TACLIncrementalSearch.ProcessKey(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True;
  case Key of
    VK_ESCAPE:
      Cancel;
    VK_SPACE:
      Result := Active and ([ssAlt, ssCtrl] * Shift = []);
    VK_BACK:
    {$IFDEF FPC}
      SetText(UTF8Copy(Text, 1, UTF8Length(Text) - 1));
    {$ELSE}
      SetText(Copy(Text, 1, Length(Text) - 1));
    {$ENDIF}
  else
    Result := False;
  end;
end;

function TACLIncrementalSearch.Contains(const AText: string): Boolean;
var
  X: Integer;
begin
  Result := not Active or GetHighlightBounds(AText, X, X);
end;

function TACLIncrementalSearch.GetHighlightBounds(
  const AText: string; out AHighlightStart, AHighlightFinish: Integer): Boolean;
var
  APosition: Integer;
begin
  Result := False;
  if Active then
  begin
    APosition := 0;
    if Mode = ismSearch then
    begin
      if acBeginsWith(AText, Text) then
        APosition := 1;
    end
    else
      APosition := acPos(Text, AText, True);

    if APosition > 0 then
    begin
      AHighlightStart := APosition - 1;
      AHighlightFinish := AHighlightStart + FTextLength;
      Result := True;
    end;
  end;
end;

function TACLIncrementalSearch.GetActive: Boolean;
begin
  Result := FTextLength > 0;
end;

procedure TACLIncrementalSearch.Changed;
begin
  CallNotifyEvent(Self, OnChange);
end;

procedure TACLIncrementalSearch.SetMode(const AValue: TACLIncrementalSearchMode);
begin
  if FMode <> AValue then
  begin
    FMode := AValue;
    if Active then
      Changed;
  end;
end;

procedure TACLIncrementalSearch.SetText(const AValue: string);
var
  AFound: Boolean;
  APrevText: string;
  APrevTextLength: Integer;
begin
  if not FLocked and (FText <> AValue) then
  begin
    FLocked := True;
    try
      APrevText := FText;
      APrevTextLength := FTextLength;

      FText := AValue;
      FTextLength := Length(FText);

      if {(Mode = ismSearch) and} (AValue <> '') and Assigned(OnLookup) then
      begin
        AFound := False;
        OnLookup(Self, AFound);
        if not AFound then
        begin
          FText := APrevText;
          FTextLength := APrevTextLength;
        end;
      end;

      Changed;
    finally
      FLocked := False;
    end;
  end;
end;

end.
