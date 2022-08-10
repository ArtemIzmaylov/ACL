{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Editors Controls              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.BaseEditors;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // Vcl
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.Mask,
  Vcl.StdCtrls,
  // System
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
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
  TACLEditGetDisplayTextEvent = procedure (Sender: TObject; const AValue: Variant; var ADisplayText: string) of object;

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
    //
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
    FCaption: UnicodeString;
    FEnabled: Boolean;
    FHint: UnicodeString;
    FViewInfo: TACLButtonViewInfo;
    FVisible: Boolean;
    FWidth: Integer;

    FOnClick: TNotifyEvent;

    function GetCollection: TACLEditButtons;
    function GetImageIndex: TImageIndex;
    procedure DoOnClick(Sender: TObject);
    procedure SetCaption(const AValue: UnicodeString);
    procedure SetEnabled(AValue: Boolean);
    procedure SetImageIndex(AValue: TImageIndex);
    procedure SetVisible(AValue: Boolean);
    procedure SetWidth(AValue: Integer);
  protected
    procedure Calculate(var R: TRect);
    procedure UpdateViewInfo;
    //
    property ViewInfo: TACLButtonViewInfo read FViewInfo;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    //
    property Collection: TACLEditButtons read GetCollection;
  published
    property Caption: UnicodeString read FCaption write SetCaption;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Hint: UnicodeString read FHint write FHint;
    property ImageIndex: TImageIndex read GetImageIndex write SetImageIndex default -1;
    property Index stored False;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Width: Integer read FWidth write SetWidth default 18;
    //
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

  { TACLEditButtonViewInfo }

  TACLEditButtonViewInfo = class(TACLButtonViewInfo)
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
    function GetHint(const P: TPoint): UnicodeString;
    function GetOwner: TPersistent; override;
    procedure Draw(ACanvas: TCanvas);
    procedure MouseDown(Button: TMouseButton; const P: TPoint);
    procedure MouseLeave;
    procedure MouseMove(Shift: TShiftState; const P: TPoint);
    procedure MouseUp(Button: TMouseButton; const P: TPoint);
    procedure Update(Item: TCollectionItem); override;
    //
    property ButtonEdit: IACLButtonEdit read FButtonEdit;
  public
    constructor Create(AButtonEdit: IACLButtonEdit); virtual;
    function Add(const ACaption: UnicodeString = ''): TACLEditButton;
    function Find(const P: TPoint; out AButton: TACLEditButton): Boolean;
    //
    property Items[Index: Integer]: TACLEditButton read GetItem; default;
  end;

  { TACLCustomEdit }

  TACLCustomEdit = class(TACLCustomControl,
    IACLButtonOwner,
    IACLButtonEdit)
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
    //
    procedure SetAutoHeight(AValue: Boolean);
    procedure SetBorders(AValue: Boolean);
    procedure SetButtons(AValue: TACLEditButtons);
    procedure SetButtonsImages(const AValue: TCustomImageList);
    procedure SetStyle(AValue: TACLStyleEdit);
    procedure SetStyleButton(AValue: TACLStyleButton);
    //
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
  protected
    FAutoHeight: Boolean;
    FBorders: Boolean;
    FEditor: TWinControl;

    function CreateStyleButton: TACLStyleButton; virtual;
    function GetCursor(const P: TPoint): TCursor; override;
    procedure AssignTextDrawParams(ACanvas: TCanvas); virtual;
    procedure Changed; virtual;
    procedure CreateHandle; override;
    procedure DoChange; virtual;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoFullRefresh; override;
    procedure FocusChanged; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure Resize; override;
    procedure SetDefaultSize; override;
    procedure SetFocusOnClick; override;
    procedure SetFocusToInnerEdit; virtual;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateBordersColor;

    // InnerEdit
    function CanOpenEditor: Boolean; virtual;
    function CreateEditor: TWinControl; virtual;
    function HasEditor: Boolean;
    procedure EditorClose; virtual;
    procedure EditorOpen;
    procedure EditorInitialize; virtual;
    procedure EditorUpdateBounds;
    procedure EditorUpdateParams;
    procedure EditorUpdateParamsCore; virtual;

    // Calculation
    function CalculateEditorPosition: TRect; virtual;
    function CalculateTextHeight: Integer; virtual;
    procedure Calculate(R: TRect); virtual;
    procedure CalculateAutoHeight(var ANewHeight: Integer); virtual;
    procedure CalculateButtons(var R: TRect); virtual;
    procedure CalculateContent(const R: TRect); virtual;
    procedure Recalculate;

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
    //
    property AutoHeight: Boolean read FAutoHeight write SetAutoHeight default True;
    property Borders: Boolean read FBorders write SetBorders default True;
    property Buttons: TACLEditButtons read FButtons write SetButtons;
    property ButtonsImages: TCustomImageList read FButtonsImages write SetButtonsImages;
    property Style: TACLStyleEdit read FStyle write SetStyle;
    property StyleButton: TACLStyleButton read FStyleButton write SetStyleButton;
    //
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    function Focused: Boolean; override;
    procedure GetTabOrderList(List: TList); override;
    procedure Localize(const ASection: string); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    property FocusOnClick;
  end;

  { TACLInnerEdit }

  TACLInnerEdit = class(TCustomMaskEdit, IACLInnerControl)
  strict private
    FInputMask: TACLEditInputMask;

    function GetContainer: TACLCustomEdit;
    procedure SetInputMask(const Value: TACLEditInputMask);
  protected
    procedure DeleteNearWord(AStartPosition, ADirection: Integer);
    procedure DeleteWordFromLeftOfCursor;
    procedure DeleteWordFromRightOfCursor;

    // Numberic
    function CanType(Key: Char): Boolean;
    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    // IACLInnerControl
    function GetInnerContainer: TWinControl;
    // Messages
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure CMWantSpecialKey(var Message: TMessage); message CM_WANTSPECIALKEY;
    procedure WMContextMenu(var Message: TWMContextMenu); message WM_CONTEXTMENU;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    //
    property Container: TACLCustomEdit read GetContainer;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    //
    property InputMask: TACLEditInputMask read FInputMask write SetInputMask;
    //
    property OnChange;
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
    //
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

    function GetIsActive: Boolean;
    procedure SetText(const AValue: string);
    procedure SetMode(const AValue: TACLIncrementalSearchMode);
  protected
    procedure Changed;
  public
    procedure Cancel;
    function CanProcessKey(Key: Word; Shift: TShiftState; ACanStartEvent: TACLKeyPreviewEvent = nil): Boolean;
    function Contains(const AText: string): Boolean;
    function GetHighlightBounds(const AText: string; out AHighlightStart, AHighlightFinish: Integer): Boolean;
    function ProcessKey(Key: Char): Boolean; overload;
    function ProcessKey(Key: Word; Shift: TShiftState): Boolean; overload;
    //
    property Active: Boolean read GetIsActive;
    property Mode: TACLIncrementalSearchMode read FMode write SetMode;
    property Text: string read FText;
    //
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnLookup: TLookupEvent read FOnLookup write FOnLookup;
  end;

function EditDateTimeFormat: TFormatSettings;
function EditDateTimeFormatToMask: string;
function EditDateTimeFormatToString: string;
implementation

uses
  System.Math,
  System.Character,
  // VCL
  Vcl.Consts;

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
begin
  Result := EditDateTimeFormatToString;
  for I := 1 to Length(Result) do
  begin
    if Result[I].IsLetter then
      Result[I] := '0';
  end;
  Result := Result + ';1;_';
end;

{ TACLStyleEdit }

procedure TACLStyleEdit.DrawBorders(ACanvas: TCanvas; const R: TRect; AFocused: Boolean);
var
  AFocusRect: TRect;
begin
  if IsWin11OrLater then
  begin
    acDrawFrame(ACanvas.Handle, R, ColorBorder.AsColor);
    if AFocused then
    begin
      AFocusRect := acRectSetBottom(R, R.Bottom, Scale(acTextIndent));
      acFillRect(ACanvas.Handle, AFocusRect, ColorBorderFocused.AsColor);
      acExcludeFromClipRegion(ACanvas.Handle, AFocusRect);
    end;
  end
  else
    acDrawFrame(ACanvas.Handle, R, ColorsBorder[AFocused]);
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
  FViewInfo := TACLEditButtonViewInfo.Create(TACLEditButtons(ACollection).ButtonEdit);
  inherited Create(ACollection);
  FViewInfo.OnClick := DoOnClick;
  ImageIndex := -1;
end;

destructor TACLEditButton.Destroy;
begin
  FreeAndNil(FViewInfo);
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
  if ViewInfo <> nil then
  begin
    ViewInfo.IsEnabled := Enabled and ((Collection.ButtonEdit = nil) or Collection.ButtonEdit.ButtonsGetEnabled);
    ViewInfo.Calculate(acRectSetLeft(R, IfThen(Visible, ViewInfo.ScaleFactor.Apply(Width))));
    R.Right := ViewInfo.Bounds.Left;
  end;
end;

procedure TACLEditButton.DoOnClick(Sender: TObject);
begin
  CallNotifyEvent(Sender, OnClick);
end;

procedure TACLEditButton.UpdateViewInfo;
begin
  ViewInfo.Caption := IfThenW(ViewInfo.ImageIndex < 0, Caption);
end;

function TACLEditButton.GetCollection: TACLEditButtons;
begin
  Result := TACLEditButtons(inherited Collection);
end;

function TACLEditButton.GetImageIndex: TImageIndex;
begin
  Result := ViewInfo.ImageIndex;
end;

procedure TACLEditButton.SetCaption(const AValue: UnicodeString);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    UpdateViewInfo;
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
    ViewInfo.ImageIndex := AValue;
    UpdateViewInfo;
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

function TACLEditButtons.Add(const ACaption: UnicodeString = ''): TACLEditButton;
begin
  BeginUpdate;
  try
    Result := TACLEditButton(inherited Add);
    Result.Caption := ACaption;
  finally
    EndUpdate;
  end;
end;

function TACLEditButtons.GetHint(const P: TPoint): UnicodeString;
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
    Items[I].ViewInfo.Draw(ACanvas);
end;

function TACLEditButtons.Find(const P: TPoint; out AButton: TACLEditButton): Boolean;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
    if PtInRect(Items[I].ViewInfo.Bounds, P) then
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
    Items[I].ViewInfo.MouseDown(Button, P);
end;

procedure TACLEditButtons.MouseLeave;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].ViewInfo.MouseMove(InvalidPoint);
end;

procedure TACLEditButtons.MouseMove(Shift: TShiftState; const P: TPoint);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].ViewInfo.MouseMove(P);
end;

procedure TACLEditButtons.MouseUp(Button: TMouseButton; const P: TPoint);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].ViewInfo.MouseUp(Button, P);
end;

procedure TACLEditButtons.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  ButtonEdit.ButtonOwnerRecalculate;
end;

{ TACLEditButtonViewInfo }

procedure TACLEditButtonViewInfo.StateChanged;
begin
  if State = absHover then
    Application.CancelHint;
  inherited StateChanged;
end;

function TACLEditButtonViewInfo.GetOwnerControl: TControl;
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
  FAutoHeight := True;
  FBorders := True;
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
    R := acRectInflate(R, -EditorOuterBorderSize);
  CalculateButtons(R);
  if Borders then
    R := acRectInflate(R, -EditorInnerBorderSize);
  CalculateContent(R);
  EditorUpdateBounds;
end;

procedure TACLCustomEdit.CalculateAutoHeight(var ANewHeight: Integer);
begin
  ANewHeight := CalculateTextHeight + ScaleFactor.Apply(4) + IfThen(Borders, 2 * EditorBorderSize);
end;

procedure TACLCustomEdit.CalculateButtons(var R: TRect);
var
  AIndent: Integer;
  AIndex: Integer;
  ARect: TRect;
begin
  AIndent := ScaleFactor.Apply(ButtonsIndent);
  ARect := acRectInflate(R, -AIndent);
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
  Result := acRectInflate(ClientRect, -EditorBorderSize);
end;

function TACLCustomEdit.CalculateTextHeight: Integer;
begin
  Result := acFontHeight(Font);
end;

procedure TACLCustomEdit.Changed;
begin
  if not IsLoading then
    DoChange;
  Invalidate;
end;

procedure TACLCustomEdit.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Style.SetTargetDPI(AValue);
  StyleButton.TargetDPI := (AValue);
end;

procedure TACLCustomEdit.CreateHandle;
begin
  inherited CreateHandle;
  Recalculate;
  EditorOpen;
end;

procedure TACLCustomEdit.DoChange;
begin
  CallNotifyEvent(Self, OnChange);
end;

procedure TACLCustomEdit.DoEnter;
begin
  if not HasEditor then
    inherited DoEnter;
end;

procedure TACLCustomEdit.DoExit;
begin
  if not HasEditor then
    inherited DoExit;
end;

procedure TACLCustomEdit.DoFullRefresh;
begin
  inherited;
  if HasEditor then
    EditorUpdateParams;
  Recalculate;
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
  Result := not IsDesigning;
end;

function TACLCustomEdit.CreateEditor: TWinControl;
begin
  Result := nil;
end;

function TACLCustomEdit.HasEditor: Boolean;
begin
  Result := FEditor <> nil;
end;

procedure TACLCustomEdit.SetDefaultSize;
begin
  SetBounds(Left, Top, 121, 21);
end;

procedure TACLCustomEdit.SetFocusOnClick;
begin
  if not IsChild(Handle, GetFocus) then
    inherited;
end;

procedure TACLCustomEdit.SetFocusToInnerEdit;
begin
  if FEditor <> nil then
    FEditor.SetFocus;
end;

procedure TACLCustomEdit.DrawEditorBackground(ACanvas: TCanvas; const R: TRect);
begin
  acFillRect(ACanvas.Handle, R, Style.ColorsContent[Enabled]);
  if Borders then
    Style.DrawBorders(ACanvas, R, not IsDesigning and Focused);
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
    if HasEditor then
    begin
      FEditor.Parent := Self;
      EditorUpdateBounds;
      EditorInitialize;
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

procedure TACLCustomEdit.EditorInitialize;
begin
  TWinControlAccess(FEditor).OnExit := HandlerEditorExit;
  TWinControlAccess(FEditor).OnEnter := HandlerEditorEnter;
  TWinControlAccess(FEditor).Anchors := AnchorClient;
end;

procedure TACLCustomEdit.EditorUpdateBounds;
var
  R: TRect;
begin
  if HasEditor then
  begin
    R := CalculateEditorPosition;
    FEditor.BoundsRect := R;
    if FEditor.Height > acRectHeight(R) then
    begin
      FEditor.BoundsRect := acRectCenterVertically(R, FEditor.Height);
      if HandleAllocated then
        SetWindowRgn(FEditor.Handle, CreateRectRgnIndirect(acMapRect(Handle, FEditor.Handle, R)), False);
    end
    else
      if HandleAllocated then
        SetWindowRgn(FEditor.Handle, 0, False);
  end;
end;

procedure TACLCustomEdit.EditorUpdateParams;
begin
  if HasEditor then
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

procedure TACLCustomEdit.Recalculate;
begin
  if not IsDestroying then
    Calculate(ClientRect);
end;

procedure TACLCustomEdit.Resize;
begin
  inherited;
  Recalculate;
end;

procedure TACLCustomEdit.UpdateBordersColor;
begin
  if HandleAllocated then Invalidate;
end;

procedure TACLCustomEdit.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  Invalidate;
end;

procedure TACLCustomEdit.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  SetFocusToInnerEdit;
end;

function TACLCustomEdit.Focused: Boolean;
begin
  Result := inherited Focused or HasEditor and FEditor.Focused;
end;

procedure TACLCustomEdit.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  EditorUpdateParams;
  if Buttons.Count > 0 then
    Recalculate;
  Invalidate;
end;

procedure TACLCustomEdit.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FullRefresh;
end;

procedure TACLCustomEdit.CMHintShow(var Message: TCMHintShow);
var
  AHint: UnicodeString;
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
    Result := inherited GetCursor(P);
end;

procedure TACLCustomEdit.GetTabOrderList(List: TList);
begin
  inherited GetTabOrderList(List);
  if HasEditor and (List.IndexOf(FEditor) >= 0) then
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

procedure TACLCustomEdit.SetAutoHeight(AValue: Boolean);
begin
  if AValue <> FAutoHeight then
  begin
    FAutoHeight := AValue;
    AdjustSize;
  end;
end;

procedure TACLCustomEdit.SetBorders(AValue: Boolean);
begin
  if AValue <> FBorders then
  begin
    FBorders := AValue;
    AdjustSize;
    Realign;
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
  if AutoHeight and not IsLoading then
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

procedure TACLInnerEdit.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if AutoSize then
    AHeight := acFontHeight(Font);
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
end;

procedure TACLInnerEdit.DeleteNearWord(AStartPosition, ADirection: Integer);

  function InBounds(const S: UnicodeString; APosition: Integer): Boolean;
  begin
    Result := InRange(APosition, 1, Length(S));
  end;

  function IsSpace(const S: UnicodeString; APosition: Integer): Boolean;
  begin
    Result := acPos(S[APosition], acParserDefaultDelimiterChars) > 0;
  end;

var
  AFinishPosition: Integer;
  AText: UnicodeString;
begin
  AText := Text;
  AFinishPosition := AStartPosition + ADirection;

  // Skip spaces
  while InBounds(AText, AFinishPosition) and IsSpace(AText, AFinishPosition) do
    Inc(AFinishPosition, ADirection);

  // Skip first word
  while InBounds(AText, AFinishPosition) and not IsSpace(AText, AFinishPosition) do
    Inc(AFinishPosition, ADirection);
    
  Text := Copy(AText, 1, Min(AStartPosition, AFinishPosition)) + Copy(AText, Max(AStartPosition, AFinishPosition) + 1, MaxInt);
  SelStart := Min(AStartPosition, AFinishPosition);  
end;

procedure TACLInnerEdit.DeleteWordFromLeftOfCursor;
begin
  DeleteNearWord(SelStart, -1);
end;

procedure TACLInnerEdit.DeleteWordFromRightOfCursor;
begin
  DeleteNearWord(SelStart, 1);
end;

function TACLInnerEdit.CanType(Key: Char): Boolean;
var
  AValueD: Double;
  AValueI: Integer;
  S: string;
begin
  Result := True;
  S := Copy(Text, 1, SelStart) + Key + Copy(Text, SelStart + SelLength + 1, MaxInt);
  if (S <> '-') and (S <> '+') then
    case InputMask of
      eimInteger:
        Result := TryStrToInt(S, AValueI);
      eimFloat:
        Result := TryStrToFloat(S, AValueD) or TryStrToFloat(S, AValueD, InvariantFormatSettings);
    end;

{$IFDEF DEBUG}
  if not Result and (InputMask = eimFloat) and (Key = '.') then
    raise Exception.CreateFmt('Test: %d, %d, (%s)', [SelStart, SelLength, S]);
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
    if Key = VK_DELETE then
    begin
      DeleteWordFromRightOfCursor;
      Key := 0;
    end;
  end;
end;

procedure TACLInnerEdit.KeyPress(var Key: Char);
begin
  inherited;

  if not IsMasked and (InputMask <> eimText) then
  begin
    if not Key.IsControl then
    begin
      if not CanType(Key) then
        Key := #0;
    end;
  end;

  case Ord(Key) of
    $7F: {Ctrl+Backspace}
      begin
        DeleteWordFromLeftOfCursor;
        Key := #0;
      end;
    VK_RETURN, VK_ESCAPE:
      Key := #0;
  end;

  Container.KeyPress(Key);
end;

procedure TACLInnerEdit.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited;
  Container.KeyUp(Key, Shift);
end;

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
  if Container.IsDesigning then
    Message.Result := HTTRANSPARENT
  else
    inherited;
end;

function TACLInnerEdit.GetContainer: TACLCustomEdit;
begin
  Result := Parent as TACLCustomEdit;
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

{ TACLCustomInplaceEdit }

constructor TACLCustomInplaceEdit.CreateInplace(const AParams: TACLInplaceInfo);
var
  ARect: TRect;
begin
  FInplace := True;
  Create(nil);
  Borders := False;
  AutoHeight := False;
  OnKeyDown := AParams.OnKeyDown;
  OnExit := AParams.OnApply;
  Parent := AParams.Parent;

  ARect := AParams.Bounds;
  ARect.Left := AParams.TextBounds.Left - 2;
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

function TACLIncrementalSearch.CanProcessKey(Key: Word; Shift: TShiftState; ACanStartEvent: TACLKeyPreviewEvent = nil): Boolean;
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

function TACLIncrementalSearch.ProcessKey(Key: Char): Boolean;
begin
  Result := not Key.IsControl and (Key <> #8) and (Active or (Key <> ' '));
  if Result then
    SetText(Text + Key);
end;

function TACLIncrementalSearch.ProcessKey(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True;
  case Key of
    VK_ESCAPE:
      Cancel;
    VK_BACK:
      SetText(Copy(Text, 1, Length(Text) - 1));
    VK_SPACE:
      Result := Active and ([ssAlt, ssCtrl] * Shift = []);
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

function TACLIncrementalSearch.GetHighlightBounds(const AText: string; out AHighlightStart, AHighlightFinish: Integer): Boolean;
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

function TACLIncrementalSearch.GetIsActive: Boolean;
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
