////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Buttons
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.Buttons;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
  LMessages,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  {Winapi.}Messages,
  // VCL
  {Vcl.}ActnList,
  {Vcl.}Controls,
  {Vcl.}Forms,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}Menus,
  {Vcl.}StdCtrls,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Graphics,
  ACL.UI.Animation,
  ACL.UI.Controls.Base,
  ACL.UI.ImageList,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

const
  DefaultButtonHeight = 25;
  DefaultButtonWidth = 100;

type
  TACLButtonPart = (abpButton, abpDropDown, abpDropDownArrow);
  TACLButtonState = (absNormal, absHover, absPressed, absDisabled, absActive);

  { TACLStyleButton }

  TACLStyleButton = class(TACLStyle)
  strict private
    function GetContentOffsets: TRect;
    function GetTextColor(AState: TACLButtonState): TColor;
  protected
    procedure InitializeResources; override;
    procedure InitializeTextures; virtual;
  public
    procedure Draw(ACanvas: TCanvas; const R: TRect;
      AState: TACLButtonState; APart: TACLButtonPart = abpButton); overload; virtual;
    procedure Draw(ACanvas: TCanvas; const R: TRect;
      AState: TACLButtonState; ACheckBoxState: TCheckBoxState); overload; virtual;
    // Properties
    property ContentOffsets: TRect read GetContentOffsets;
    property TextColors[AState: TACLButtonState]: TColor read GetTextColor;
  published
    property ColorText: TACLResourceColor index Ord(absNormal) read GetColor write SetColor stored IsColorStored;
    property ColorTextDisabled: TACLResourceColor index Ord(absDisabled) read GetColor write SetColor stored IsColorStored;
    property ColorTextHover: TACLResourceColor index Ord(absHover) read GetColor write SetColor stored IsColorStored;
    property ColorTextPressed: TACLResourceColor index Ord(absPressed) read GetColor write SetColor stored IsColorStored;
    property Texture: TACLResourceTexture index 0 read GetTexture write SetTexture stored IsTextureStored;
  end;

  { TACLSimpleButtonSubClass }

  TACLButtonStateFlag = (bsfPressed, bsfHovered, bsfEnabled,
    bsfFocused, bsfDown, bsfDefault, bsfPerformClick);
  TACLButtonStateFlags = set of TACLButtonStateFlag;

  TACLSimpleButtonSubClass = class(TACLControlSubClass, IACLAnimateControl)
  strict private
    FCaption: string;
    FFlags: TACLButtonStateFlags;
    FState: TACLButtonState;
    FStyle: TACLStyleButton;
    FTag: Integer;

    FOnClick: TNotifyEvent;

    function GetCurrentDpi: Integer;
    function GetFlag(Index: TACLButtonStateFlag): Boolean;
    function GetTextureSize: TSize;
    procedure SetAlignment(AValue: TAlignment);
    procedure SetCaption(const AValue: string);
    procedure SetFlag(AFlag: TACLButtonStateFlag; AValue: Boolean);
  protected
    FAlignment: TAlignment;
    FButtonRect: TRect;
    FFocusRect: TRect;
    FTextRect: TRect;

    function CalculateState: TACLButtonState; virtual;
    function GetIndentBetweenElements: Integer; inline;
    function GetTextColor: TColor; virtual;
    function GetTransparent: Boolean; virtual;
    procedure RefreshState;
    procedure StateChanged; virtual;
    // Drawing
    function AllowAnimation: Boolean; virtual;
    procedure AssignCanvasParameters(ACanvas: TCanvas); virtual;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); virtual;
    procedure DrawContent(ACanvas: TCanvas); virtual;
    procedure DrawFocusRect(ACanvas: TCanvas); virtual;
    // IACLAnimateControl
    procedure IACLAnimateControl.Animate = Invalidate;
    // Messages
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    //# Properties
    property Flags: TACLButtonStateFlags read FFlags;
    property Style: TACLStyleButton read FStyle;
  public
    constructor Create(AOwner: IACLControl; AStyle: TACLStyleButton); virtual;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure Calculate(ARect: TRect); override;
    procedure CalculateAutoSize(var AWidth, AHeight: Integer); virtual;
    procedure Draw(ACanvas: TCanvas); override;
    procedure PerformClick;
    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; const P: TPoint); override;
    procedure MouseMove(Shift: TShiftState; const P: TPoint); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; const P: TPoint); override;
    //# Properties
    property Alignment: TAlignment read FAlignment write SetAlignment;
    property ButtonRect: TRect read FButtonRect;
    property Caption: string read FCaption write SetCaption;
    property CurrentDpi: Integer read GetCurrentDpi;
    property FocusRect: TRect read FFocusRect;
    property State: TACLButtonState read FState;
    property Tag: Integer read FTag write FTag;
    property TextColor: TColor read GetTextColor;
    property TextRect: TRect read FTextRect;
    property TextureSize: TSize read GetTextureSize;
    property Transparent: Boolean read GetTransparent;
    //# States
    property IsDefault: Boolean index bsfDefault read GetFlag write SetFlag;
    property IsDown: Boolean index bsfDown read GetFlag write SetFlag;
    property IsEnabled: Boolean index bsfEnabled read GetFlag write SetFlag;
    property IsFocused: Boolean index bsfFocused read GetFlag write SetFlag;
    property IsHovered: Boolean index bsfHovered read GetFlag write SetFlag;
    property IsPressed: Boolean index bsfPressed read GetFlag write SetFlag;
    //# Events
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

  { TACLCustomButton }

  TACLCustomButton = class(TACLCustomControl)
  strict private
    FShowCaption: Boolean;
    FStyle: TACLStyleButton;
    FSubClass: TACLSimpleButtonSubClass;

    procedure ClickHandler(Sender: TObject);
    function GetAlignment: TAlignment;
    procedure SetAlignment(AValue: TAlignment);
    procedure SetShowCaption(AValue: Boolean);
    procedure SetStyle(const Value: TACLStyleButton);
  protected
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); override;
    procedure BoundsChanged; override;
    procedure Calculate(R: TRect); virtual;
    function CreateStyle: TACLStyleButton; virtual; abstract;
    function CreateSubClass: TACLSimpleButtonSubClass; virtual; abstract;
    procedure DoGetHint(const P: TPoint; var AHint: string); override;
    procedure FocusChanged; override;
    procedure Paint; override;
    procedure ResourceChanged; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateTransparency; override;

    // Keyboard
    function DialogChar(var Message: TWMKey): Boolean; override;

    // Messages
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;

    // Properties
    property SubClass: TACLSimpleButtonSubClass read FSubClass;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function MeasureSize(AWidth: Integer = -1): TSize;
  published
    property Alignment: TAlignment read GetAlignment write SetAlignment default taCenter;
    property Action;
    property Align;
    property Anchors;
    property Caption;
    property Cursor default crHandPoint;
    property DoubleBuffered default True;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property FocusOnClick default True;
    property Font;
    property ResourceCollection;
    property Style: TACLStyleButton read FStyle write SetStyle;
    property ShowCaption: Boolean read FShowCaption write SetShowCaption default True;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabStop default True;
    property Visible;

    property OnClick;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

  { TACLButtonSubClass }

  TACLButtonSubClass = class(TACLSimpleButtonSubClass)
  strict private const
    FocusThickness = 1;
    TextIndent = acTextIndent - 1;
  strict private
    FHasArrow: Boolean;
    FImageIndex: Integer;
    FImageList: TCustomImageList;
    FPart: TACLButtonPart;

    function GetImageSize: TSize;
    procedure SetImageIndex(AValue: Integer);
  protected
    FArrowRect: TRect;
    FImageRect: TRect;

    procedure CalculateArrowRect(var R: TRect); virtual;
    procedure CalculateImageRect(var R: TRect); virtual;
    procedure CalculateTextRect(var R: TRect); virtual;
    function GetGlyph: TACLGlyph; virtual;
    function GetHasImage: Boolean; virtual;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); override;
    procedure DrawContent(ACanvas: TCanvas); override;
    //# Properties
    property Glyph: TACLGlyph read GetGlyph;
  public
    constructor Create(AOwner: IACLControl; AStyle: TACLStyleButton); override;
    procedure Calculate(ARect: TRect); override;
    procedure CalculateAutoSize(var AWidth, AHeight: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    //# Properties
    property ArrowRect: TRect read FArrowRect;
    property HasArrow: Boolean read FHasArrow write FHasArrow;
    property HasImage: Boolean read GetHasImage;
    property ImageIndex: Integer read FImageIndex write SetImageIndex;
    property ImageList: TCustomImageList read FImageList write FImageList; // just a reference! don't forget to remove it
    property ImageRect: TRect read FImageRect;
    property ImageSize: TSize read GetImageSize;
    property Part: TACLButtonPart read FPart write FPart;
  end;

  { TACLSimpleButton }

  TACLSimpleButton = class(TACLCustomButton, IACLGlyph)
  strict private
    FCancel: Boolean;
    FDefault: Boolean;
    FGlyph: TACLGlyph;
    FImageChangeLink: TChangeLink;
    FImageIndex: TImageIndex;
    FImages: TCustomImageList;
    FModalResult: TModalResult;
  {$IFDEF FPC}
    FRolesUpdateLocked: Boolean;
  {$ENDIF}
    FOnPaint: TNotifyEvent;
    procedure HandlerImageChange(Sender: TObject);
    function IsGlyphStored: Boolean;
    function IsImageIndexStored: Boolean;
    function GetDown: Boolean;
    function GetSubClass: TACLButtonSubClass;
    procedure SetCancel(AValue: Boolean);
    procedure SetDefault(AValue: Boolean);
    procedure SetDown(AValue: Boolean);
    procedure SetGlyph(const Value: TACLGlyph);
    procedure SetImageIndex(AIndex: TImageIndex);
    procedure SetImages(const AList: TCustomImageList);
    procedure UpdateRoles;
    // Messages
  {$IFDEF FPC}
    procedure WMKillFocus(var Message: TMessage); message WM_KILLFOCUS;
    procedure WMSetFocus(var Message: TMessage); message WM_SETFOCUS;
  {$ELSE}
    procedure CMFocusChanged(var Message: TMessage); message CM_FOCUSCHANGED;
    procedure CMDialogKey(var Message: TCMDialogKey); message {%H-}CM_DIALOGKEY;
  {$ENDIF}
  protected
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); override;
    function CreateStyle: TACLStyleButton; override;
    function CreateSubClass: TACLSimpleButtonSubClass; override;
    function GetActionLinkClass: TControlActionLinkClass; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure PerformClick; virtual;
    procedure SetTargetDPI(AValue: Integer); override;
    // IACLGlyph
    function GetGlyph: TACLGlyph;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    procedure Click; override;
    //# Default/Cancel
  {$IFDEF FPC}
    procedure ActiveDefaultControlChanged(NewControl: TControl); override;
    procedure ExecuteCancelAction; override;
    procedure ExecuteDefaultAction; override;
    procedure UpdateRolesForForm; override;
  {$ENDIF}
    //# Properties
    property Canvas;
    property SubClass: TACLButtonSubClass read GetSubClass;
  published
    property Cancel: Boolean read FCancel write SetCancel default False;
    property Default: Boolean read FDefault write SetDefault default False;
    property Down: Boolean read GetDown write SetDown default False;
    property Glyph: TACLGlyph read FGlyph write SetGlyph stored IsGlyphStored;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex stored IsImageIndexStored;
    property Images: TCustomImageList read FImages write SetImages;
    property ModalResult: TModalResult read FModalResult write FModalResult default mrNone;
    property ParentColor;
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
  end;

  { TACLSimpleButtonActionLink }

  TACLSimpleButtonActionLink = class(TWinControlActionLink)
  protected
    procedure SetImageIndex(Value: Integer); override;
  public
    function IsImageIndexLinked: Boolean; override;
  end;

  { TACLButton }

  TACLButtonKind = (sbkNormal, sbkDropDown, sbkDropDownButton);
  TACLButton = class(TACLSimpleButton)
  strict private
    FDropDownMenu: TPopupMenu;
    FDropDownSubClass: TACLButtonSubClass;
    FKind: TACLButtonKind;

    FOnDropDownClick: TNotifyEvent;

    procedure HandlerDropDownClick(Sender: TObject);
    procedure SetKind(AValue: TACLButtonKind);
  protected
    procedure Calculate(ARect: TRect); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure PerformClick; override;
    procedure UpdateTransparency; override;
  public
    constructor Create(AOwner: TComponent); override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure ShowDropDownMenu;
    //# Properties
    property DropDownSubClass: TACLButtonSubClass read FDropDownSubClass;
  published
    property AutoSize;
    property DropDownMenu: TPopupMenu read FDropDownMenu write FDropDownMenu;
    property Kind: TACLButtonKind read FKind write SetKind default sbkNormal;
    //# Events
    property OnDropDownClick: TNotifyEvent read FOnDropDownClick write FOnDropDownClick;
  end;

  TACLCustomCheckBox = class;

  { TACLStyleCheckBox }

  TACLStyleCheckBox = class(TACLStyleButton)
  protected
    procedure InitializeResources; override;
    procedure InitializeTextures; override;
  published
    property ColorLine1: TACLResourceColor index 10 read GetColor write SetColor stored IsColorStored;
    property ColorLine2: TACLResourceColor index 11 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLStyleRadioButton }

  TACLStyleRadioButton = class(TACLStyleCheckBox)
  protected
    procedure InitializeTextures; override;
  end;

  { TACLCheckBoxActionLink }

  TACLCheckBoxActionLink = class(TControlActionLink)
  protected
    procedure SetChecked(Value: Boolean); override;
  public
    function IsCheckedLinked: Boolean; override;
  end;

  { TACLCheckBoxSubControlOptions }

  TACLCheckBoxSubControlOptions = class(TACLSubControlOptions)
  strict private
    FEnabled: Boolean;
    function GetOwnerEx: TACLCustomCheckBox; inline;
    procedure SetEnabled(AValue: Boolean);
    procedure SyncEnabled;
  protected
    procedure AlignControl(var AClientRect: TRect); override;
    procedure Changed; override;
    procedure WindowProc(var Message: TMessage); override;
    //# Properties
    property Enabled: Boolean read FEnabled write SetEnabled;
    property Owner: TACLCustomCheckBox read GetOwnerEx;
  end;

  { TACLCheckBoxSubClass }

  TACLCheckBoxSubClass = class(TACLSimpleButtonSubClass)
  strict private
    FCheckState: TCheckBoxState;
    FShowCheckMark: Boolean;
    FShowLine: Boolean;
    FWordWrap: Boolean;

    function GetStyle: TACLStyleCheckBox;
    procedure SetCheckState(AValue: TCheckBoxState);
    procedure SetShowCheckMark(AValue: Boolean);
    procedure SetShowLine(AValue: Boolean);
    procedure SetWordWrap(AValue: Boolean);
  protected
    function GetTransparent: Boolean; override;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); override;
    procedure DrawContent(ACanvas: TCanvas); override;
    procedure MeasureText(var ARect: TRect); virtual;
  public
    constructor Create(AOwner: IACLControl; AStyle: TACLStyleButton); override;
    procedure Calculate(ARect: TRect); override;
    procedure CalculateAutoSize(var AWidth, AHeight: Integer); override;
    //# Properties
    property CheckState: TCheckBoxState read FCheckState write SetCheckState;
    property ShowCheckMark: Boolean read FShowCheckMark write SetShowCheckMark;
    property ShowLine: Boolean read FShowLine write SetShowLine;
    property Style: TACLStyleCheckBox read GetStyle;
    property WordWrap: Boolean read FWordWrap write SetWordWrap;
  end;

  { TACLCustomCheckBox }

  TACLCustomCheckBox = class(TACLCustomButton)
  strict private
    FAllowGrayed: Boolean;
    FSubControl: TACLCheckBoxSubControlOptions;

    function GetChecked: Boolean;
    function GetShowCheckMark: Boolean;
    function GetShowLine: Boolean;
    function GetState: TCheckBoxState;
    function GetStyle: TACLStyleCheckBox;
    function GetSubClass: TACLCheckBoxSubClass;
    function GetWordWrap: Boolean;
    function IsCursorStored: Boolean;
    function IsWidthMatters: Boolean;
    procedure SetChecked(AValue: Boolean);
    procedure SetShowCheckMark(AValue: Boolean);
    procedure SetShowLine(AValue: Boolean);
    procedure SetStyle(AStyle: TACLStyleCheckBox);
    procedure SetSubControl(AValue: TACLCheckBoxSubControlOptions);
    procedure SetWordWrap(AValue: Boolean);
    // Messages
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
    procedure WMMove(var Message: TMessage); message WM_MOVE;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  protected
    procedure Calculate(R: TRect); override;
    function CreateStyle: TACLStyleButton; override;
    function CreateSubControlOptions: TACLCheckBoxSubControlOptions; virtual;
    function CreateSubClass: TACLSimpleButtonSubClass; override;
    function GetActionLinkClass: TControlActionLinkClass; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure SetState(AValue: TCheckBoxState); virtual;
    procedure UpdateSubControlEnabled;
    //# Properties
    property AllowGrayed: Boolean read FAllowGrayed write FAllowGrayed default False;
    property Checked: Boolean read GetChecked write SetChecked;
    property State: TCheckBoxState read GetState write SetState default cbUnchecked;
    property SubControl: TACLCheckBoxSubControlOptions read FSubControl write SetSubControl;
    property SubClass: TACLCheckBoxSubClass read GetSubClass;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure Click; override;
    procedure ChangeState(AChecked: Boolean); overload;
    procedure ChangeState(AState: TCheckBoxState); overload;
    procedure ToggleState; virtual;
  {$IFDEF FPC}
    procedure ShouldAutoAdjust(var AWidth, AHeight: Boolean); override;
  {$ENDIF}
    function TextOffset: Integer;
  published
    property Alignment default taLeftJustify;
    property AutoSize default True;
    property Cursor stored IsCursorStored;
    property ShowCheckMark: Boolean read GetShowCheckMark write SetShowCheckMark default True;
    property ShowLine: Boolean read GetShowLine write SetShowLine default False;
    property Style: TACLStyleCheckBox read GetStyle write SetStyle;
    property Transparent;
    property WordWrap: Boolean read GetWordWrap write SetWordWrap default False;
  end;

  { TACLCheckBox }

  TACLCheckBox = class(TACLCustomCheckBox)
  published
    property AllowGrayed;
    property Checked stored False;
    property SubControl;
    property State;
  end;

  { TACLInplaceCheckBox }

  TACLInplaceCheckBox = class(TACLCustomCheckBox, IACLInplaceControl)
  protected
    // IACLInplaceControl
    function InplaceGetValue: string;
    function IACLInplaceControl.InplaceIsFocused = Focused;
    procedure InplaceSetValue(const AValue: string);
    procedure IACLInplaceControl.InplaceSetFocus = SetFocus;
    // Messages
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
  public
    constructor CreateInplace(const AParams: TACLInplaceInfo);
    property AllowGrayed;
  end;

  { TACLRadioButton }

  TACLRadioButton = class(TACLCustomCheckBox)
  strict private
    FGroupIndex: Integer;
    procedure SetGroupIndex(const Value: Integer);
  protected
    function CreateStyle: TACLStyleButton; override;
    procedure SetState(AValue: TCheckBoxState); override;
  public
    procedure ToggleState; override;
  published
    property Checked;
    property GroupIndex: Integer read FGroupIndex write SetGroupIndex default 0;
    property SubControl;
  end;

implementation

uses
{$IFNDEF FPC}
  ACL.Graphics.SkinImage,    // inlining
  ACL.Graphics.SkinImageSet, // inlining
{$ENDIF}
  ACL.UI.Controls.Labels,
  ACL.UI.Menus,
  ACL.Utils.Strings;

{ TACLStyleButton }

procedure TACLStyleButton.Draw(ACanvas: TCanvas; const R: TRect;
  AState: TACLButtonState; APart: TACLButtonPart = abpButton);
var
  LIndex: Integer;
begin
  LIndex := Ord(AState);
  if Texture.FrameCount >= 15 then
    Inc(LIndex, Ord(APart) * 5);
  Texture.Draw(ACanvas, R, LIndex);
end;

procedure TACLStyleButton.Draw(ACanvas: TCanvas; const R: TRect;
  AState: TACLButtonState; ACheckBoxState: TCheckBoxState);
begin
  Texture.Draw(ACanvas, R, Ord(ACheckBoxState) * 5 + Ord(AState));
end;

procedure TACLStyleButton.InitializeResources;
begin
  ColorText.InitailizeDefaults('Buttons.Colors.Text');
  ColorTextDisabled.InitailizeDefaults('Buttons.Colors.TextDisabled');
  ColorTextHover.InitailizeDefaults('Buttons.Colors.TextHover');
  ColorTextPressed.InitailizeDefaults('Buttons.Colors.TextPressed');
  InitializeTextures;
end;

procedure TACLStyleButton.InitializeTextures;
begin
  Texture.InitailizeDefaults('Buttons.Textures.Button');
end;

function TACLStyleButton.GetContentOffsets: TRect;
begin
  Result := Texture.ContentOffsets;
end;

function TACLStyleButton.GetTextColor(AState: TACLButtonState): TColor;
begin
  case AState of
    absHover:
      Result := ColorTextHover.AsColor;
    absPressed:
      Result := ColorTextPressed.AsColor;
    absDisabled:
      Result := ColorTextDisabled.AsColor;
  else
    Result := clDefault;
  end;
  if Result = clDefault then
    Result := ColorText.AsColor;
end;

{ TACLSimpleButtonSubClass }

constructor TACLSimpleButtonSubClass.Create(AOwner: IACLControl; AStyle: TACLStyleButton);
begin
  inherited Create(AOwner);
  FAlignment := taCenter;
  FFlags := [bsfEnabled];
  FStyle := AStyle;
end;

destructor TACLSimpleButtonSubClass.Destroy;
begin
  AnimationManager.RemoveOwner(Self);
  if GetFlag(bsfPerformClick) then
    raise EInvalidOperation.Create('Attempt to destroy the Form from OnClick handler');
  inherited Destroy;
end;

procedure TACLSimpleButtonSubClass.Calculate(ARect: TRect);
begin
  inherited;
  FButtonRect := Bounds;
end;

procedure TACLSimpleButtonSubClass.CalculateAutoSize(var AWidth, AHeight: Integer);
var
  LTextRect: TRect;
begin
  if Caption <> '' then
  begin
    LTextRect := Rect(0, 0, 1, 1);
    AssignCanvasParameters(MeasureCanvas);
    acSysDrawText(MeasureCanvas, LTextRect, Caption, DT_CALCRECT);
    AHeight := LTextRect.Height;
    AWidth := LTextRect.Width;
  end
  else
  begin
    AHeight := 0;
    AWidth := 0;
  end;
end;

procedure TACLSimpleButtonSubClass.Draw(ACanvas: TCanvas);
var
  LClipping: TRegionHandle;
begin
  if acStartClippedDraw(ACanvas, Bounds, LClipping) then
  try
    AssignCanvasParameters(ACanvas);
    if not AnimationManager.Draw(Self, ACanvas, ButtonRect) then
      DrawBackground(ACanvas, ButtonRect);
    if IsFocused then
      DrawFocusRect(ACanvas);
    DrawContent(ACanvas);
  finally
    acEndClippedDraw(ACanvas, LClipping);
  end;
end;

procedure TACLSimpleButtonSubClass.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Draw(ACanvas, R, State)
end;

procedure TACLSimpleButtonSubClass.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = vkSpace) and IsFocused then
  begin
    IsPressed := True;
    Key := 0;
  end;
end;

procedure TACLSimpleButtonSubClass.KeyUp(var Key: Word; Shift: TShiftState);
begin
  case Key of
    vkEscape:
      IsPressed := False;
    vkSpace:
      if IsPressed then
      try
        PerformClick;
      finally
        IsPressed := False;
      end;
  end;
end;

procedure TACLSimpleButtonSubClass.MouseDown(
  Button: TMouseButton; Shift: TShiftState; const P: TPoint);
begin
  IsPressed := IsEnabled and Bounds.Contains(P) and (Button = mbLeft);
end;

procedure TACLSimpleButtonSubClass.MouseMove(Shift: TShiftState; const P: TPoint);
begin
  IsHovered := IsEnabled and Bounds.Contains(P);
end;

procedure TACLSimpleButtonSubClass.MouseUp(
  Button: TMouseButton; Shift: TShiftState; const P: TPoint);
begin
  if IsPressed then
  try
    if (Button = mbLeft) and Bounds.Contains(P) then
      PerformClick;
  finally
    IsPressed := False;
  end;
end;

procedure TACLSimpleButtonSubClass.PerformClick;
begin
  SetFlag(bsfPerformClick, True);
  try
    CallNotifyEvent(Self, OnClick);
  finally
    SetFlag(bsfPerformClick, False);
  end;
end;

procedure TACLSimpleButtonSubClass.RefreshState;
var
  LAnimation: TACLBitmapAnimation;
  LNewState: TACLButtonState;
begin
  LNewState := CalculateState;
  if LNewState <> FState then
  begin
    if AllowAnimation and not ButtonRect.IsEmpty and
      (FState = absHover) and (LNewState in [absActive, absNormal]) then
    begin
      LAnimation := TACLBitmapAnimation.Create(Self, ButtonRect, TACLAnimatorFadeOut.Create);
      LAnimation.BuildFrame1(DrawBackground);
      FState := LNewState;
      LAnimation.BuildFrame2(DrawBackground);
      LAnimation.Run;
    end;
    FState := LNewState;
    StateChanged;
    Invalidate;
  end;
end;

function TACLSimpleButtonSubClass.CalculateState: TACLButtonState;
begin
  if not (IsEnabled and Owner.GetEnabled) then
    Result := absDisabled
  else if IsPressed or IsDown then
    Result := absPressed
  else if IsHovered then
    Result := absHover
  else if IsFocused or IsDefault then
    Result := absActive
  else
    Result := absNormal;
end;

procedure TACLSimpleButtonSubClass.CMEnabledChanged(var Message: TMessage);
begin
  RefreshState;
end;

function TACLSimpleButtonSubClass.GetIndentBetweenElements: Integer;
begin
  Result := dpiApply(acIndentBetweenElements, CurrentDpi);
end;

function TACLSimpleButtonSubClass.GetTextColor: TColor;
begin
  Result := Style.TextColors[State];
end;

function TACLSimpleButtonSubClass.GetTransparent: Boolean;
begin
  Result := Style.Texture.HasAlpha;
end;

procedure TACLSimpleButtonSubClass.StateChanged;
begin
  if State = absHover then
    Application.CancelHint;
end;

procedure TACLSimpleButtonSubClass.AfterConstruction;
begin
  inherited;
  FState := CalculateState;
end;

function TACLSimpleButtonSubClass.AllowAnimation: Boolean;
begin
  Result := True;
end;

procedure TACLSimpleButtonSubClass.AssignCanvasParameters(ACanvas: TCanvas);
begin
  ACanvas.SetScaledFont(Owner.GetFont);
  ACanvas.Font.Color := TextColor;
  ACanvas.Brush.Style := bsClear;
end;

procedure TACLSimpleButtonSubClass.DrawContent(ACanvas: TCanvas);
var
  LRect: TRect;
begin
  if Caption <> '' then
  begin
    AssignCanvasParameters(ACanvas);
    LRect := TextRect;
    acSysDrawText(ACanvas, LRect, Caption, acTextAlignHorz[Alignment] or
      DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS); // Keep the "&" Prefix in mind
  end;
end;

procedure TACLSimpleButtonSubClass.DrawFocusRect(ACanvas: TCanvas);
begin
  acDrawFocusRect(ACanvas, FocusRect, TextColor);
end;

function TACLSimpleButtonSubClass.GetCurrentDpi: Integer;
begin
  Result := Owner.GetCurrentDpi;
end;

function TACLSimpleButtonSubClass.GetFlag(Index: TACLButtonStateFlag): Boolean;
begin
  Result := Index in FFlags;
end;

function TACLSimpleButtonSubClass.GetTextureSize: TSize;
begin
  Result := Style.Texture.FrameSize;
end;

procedure TACLSimpleButtonSubClass.SetAlignment(AValue: TAlignment);
begin
  if AValue <> FAlignment then
  begin
    FAlignment := AValue;
    Refresh;
  end;
end;

procedure TACLSimpleButtonSubClass.SetCaption(const AValue: string);
begin
  if AValue <> FCaption then
  begin
    FCaption := AValue;
    RefreshAutoSize;
  end;
end;

procedure TACLSimpleButtonSubClass.SetFlag(AFlag: TACLButtonStateFlag; AValue: Boolean);
begin
  if GetFlag(AFlag) <> AValue then
  begin
    if AValue then
      Include(FFlags, AFlag)
    else
      Exclude(FFlags, AFlag);

    if AFlag = bsfFocused then
      IsPressed := IsPressed and IsFocused;
    RefreshState;
  end;
end;

{ TACLCustomButton }

constructor TACLCustomButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FocusOnClick := True;
  DoubleBuffered := True;
  TabStop := True;
  DefaultCursor := crHandPoint;
  ControlStyle := ControlStyle - [csDoubleClicks, csClickEvents];
  FDefaultSize := TSize.Create(DefaultButtonWidth, DefaultButtonHeight);
  FStyle := CreateStyle;
  FShowCaption := True;
  RegisterSubClass(FSubClass, CreateSubClass);
  FSubClass.OnClick := ClickHandler;
end;

destructor TACLCustomButton.Destroy;
begin
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLCustomButton.ActionChange(Sender: TObject; CheckDefaults: Boolean);
begin
  if Assigned(Sender) and (Sender is TCustomAction) then
    with TCustomAction(Sender) do
    begin
      Self.OnClick := OnExecute;
      Self.Caption := Caption;
      Self.Enabled := Enabled;
      Self.Visible := Visible;
      Self.Hint := Hint;
    end;
end;

procedure TACLCustomButton.BoundsChanged;
begin
  inherited;
  if not (csDestroying in ComponentState) then
    Calculate(ClientRect);
end;

procedure TACLCustomButton.Calculate(R: TRect);
begin
  SubClass.Calculate(R);
end;

procedure TACLCustomButton.ClickHandler(Sender: TObject);
begin
  Click;
end;

function TACLCustomButton.DialogChar(var Message: TWMKey): Boolean;
begin
  if IsAccel(Message.CharCode, Caption) and CanFocus then
  begin
    SetFocusOnClick;
    SubClass.PerformClick;
    Result := True;
  end
  else
    Result := inherited;
end;

procedure TACLCustomButton.DoGetHint(const P: TPoint; var AHint: string);
begin
  if not ShowCaption and (AHint = '') then
    AHint := Caption;
  inherited;
end;

procedure TACLCustomButton.FocusChanged;
begin
  inherited FocusChanged;
  SubClass.IsFocused := not (csDesigning in ComponentState) and Focused;
end;

procedure TACLCustomButton.Paint;
begin
  SubClasses.Draw(Canvas);
end;

procedure TACLCustomButton.ResourceChanged;
begin
  inherited;
  FullRefresh;
end;

procedure TACLCustomButton.UpdateTransparency;
begin
  if SubClass.Transparent then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque];
end;

procedure TACLCustomButton.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FullRefresh;
end;

procedure TACLCustomButton.CMHintShow(var Message: TCMHintShow);
begin
  if SubClass.IsPressed then // Bug fixed with Menu and Hint shadows
    Message.Result := 1
  else
    inherited;
end;

procedure TACLCustomButton.CMTextChanged(var Message: TMessage);
begin
  SubClass.Caption := IfThenW(ShowCaption, Caption);
  inherited;
end;

function TACLCustomButton.GetAlignment: TAlignment;
begin
  Result := SubClass.Alignment;
end;

function TACLCustomButton.MeasureSize(AWidth: Integer): TSize;
begin
  Result.cx := AWidth;
  Result.cy := -1;
  if not CanAutoSize(Result.cx, Result.cy) then
    Result := NullSize;
end;

procedure TACLCustomButton.SetAlignment(AValue: TAlignment);
begin
  SubClass.Alignment := AValue;
end;

procedure TACLCustomButton.SetShowCaption(AValue: Boolean);
begin
  if FShowCaption <> AValue then
  begin
    FShowCaption := AValue;
    Perform(CM_TEXTCHANGED, 0, 0);
  end;
end;

procedure TACLCustomButton.SetStyle(const Value: TACLStyleButton);
begin
  FStyle.Assign(Value);
end;

procedure TACLCustomButton.SetTargetDPI(AValue: Integer);
begin
  inherited;
  Style.SetTargetDPI(AValue);
end;

{ TACLButtonSubClass }

constructor TACLButtonSubClass.Create;
begin
  inherited;
  FImageIndex := -1;
end;

procedure TACLButtonSubClass.Calculate(ARect: TRect);
begin
  inherited;
  ARect.Content(Style.ContentOffsets);
  FFocusRect := ARect;
  ARect.Inflate(-FocusThickness);
  if HasArrow then
    CalculateArrowRect(ARect);
  if HasImage then
    CalculateImageRect(ARect);
  CalculateTextRect(ARect);
end;

procedure TACLButtonSubClass.CalculateArrowRect(var R: TRect);
var
  LIndent: Integer;
  LWidth: Integer;
begin
  FArrowRect := R;
  if Part <> abpDropDownArrow then
  begin
    LIndent := GetIndentBetweenElements;
    LWidth := acGetArrowSize(makBottom, CurrentDpi).cx;
    FArrowRect.Right := FArrowRect.Right - LIndent;
    FArrowRect.Left := FArrowRect.Right - LWidth;
    if FArrowRect.Left < R.Left + LIndent then
    begin
      FArrowRect := R;
      FArrowRect.CenterHorz(LWidth);
    end;
    R.Right := FArrowRect.Left - LIndent;
  end;
end;

procedure TACLButtonSubClass.CalculateAutoSize(var AWidth, AHeight: Integer);
var
  LSize: TSize;
begin
  inherited;
  if HasArrow then
  begin
    Inc(AWidth, acGetArrowSize(makBottom, CurrentDpi).cx);
    Inc(AWidth, GetIndentBetweenElements);
  end;
  if HasImage then
  begin
    LSize := ImageSize;
    Inc(AWidth, LSize.cx);
    Inc(AWidth, GetIndentBetweenElements);
    AHeight := Max(AHeight, LSize.cy);
  end;
  Inc(AHeight, 2 * FocusThickness);
  Inc(AHeight, 2 * dpiApply(TextIndent, CurrentDpi));
  Inc(AHeight, Style.ContentOffsets.MarginsHeight);
  Inc(AWidth, 2 * FocusThickness);
  Inc(AWidth, 2 * dpiApply(TextIndent, CurrentDpi));
  Inc(AWidth, Style.ContentOffsets.MarginsWidth);
end;

procedure TACLButtonSubClass.CalculateImageRect(var R: TRect);
var
  LImageSize: TSize;
begin
  LImageSize := ImageSize;
  FImageRect := R;
  if Caption <> '' then
  begin
    FImageRect.CenterVert(LImageSize.cy);
    FImageRect.Width := LImageSize.cx;
  end
  else
    FImageRect.Center(LImageSize);

  R.Left := FImageRect.Right + GetIndentBetweenElements;
end;

procedure TACLButtonSubClass.CalculateTextRect(var R: TRect);
begin
  FTextRect := R;
  FTextRect.Inflate(-dpiApply(TextIndent, CurrentDpi), 0);
end;

function TACLButtonSubClass.GetGlyph: TACLGlyph;
var
  LIntf: IACLGlyph;
begin
  if Supports(Owner, IACLGlyph, LIntf) then
    Result := LIntf.GetGlyph
  else
    Result := nil;
end;

procedure TACLButtonSubClass.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Draw(ACanvas, R, State, Part);
end;

procedure TACLButtonSubClass.DrawContent(ACanvas: TCanvas);
begin
  inherited DrawContent(ACanvas);

  if FHasArrow then
    acDrawArrow(ACanvas, ArrowRect, TextColor, makBottom, CurrentDpi);

  if not ImageRect.IsEmpty then
  begin
    if Glyph <> nil then
      Glyph.Draw(ACanvas, ImageRect, State <> absDisabled)
    else
      acDrawImage(ACanvas, ImageRect, ImageList, ImageIndex, State <> absDisabled);
  end;
end;

function TACLButtonSubClass.GetHasImage: Boolean;
begin
  Result := (Part <> abpDropDownArrow) and
    ((ImageList <> nil) and (ImageIndex >= 0) or (Glyph <> nil));
end;

function TACLButtonSubClass.GetImageSize: TSize;
begin
  if Glyph <> nil then
    Result := Glyph.FrameSize
  else
    Result := acGetImageListSize(ImageList, CurrentDpi);
end;

procedure TACLButtonSubClass.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Part = abpDropDownArrow) and acIsDropDownCommand(Key, Shift) then
  begin
    IsPressed := True;
    try
      PerformClick;
    finally
      IsPressed := False;
      Key := 0;
    end;
  end
  else
    inherited;
end;

procedure TACLButtonSubClass.SetImageIndex(AValue: Integer);
begin
  if FImageIndex <> AValue then
  begin
    FImageIndex := AValue;
    Invalidate;
  end;
end;

{ TACLSimpleButton }

constructor TACLSimpleButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IFDEF FPC}
  ControlStyle := ControlStyle + [csHasDefaultAction, csHasCancelAction];
{$ENDIF}
  FGlyph := TACLGlyph.Create(Self);
  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := HandlerImageChange;
  FImageIndex := -1;
end;

destructor TACLSimpleButton.Destroy;
begin
  FreeAndNil(FImageChangeLink);
  FreeAndNil(FGlyph);
  inherited Destroy;
end;

procedure TACLSimpleButton.ActionChange(Sender: TObject; CheckDefaults: Boolean);
begin
  inherited;
  if Sender is TCustomAction then
  begin
    if not CheckDefaults or (ImageIndex = -1) then
      ImageIndex := TCustomAction(Sender).ImageIndex;
  end;
end;

procedure TACLSimpleButton.BeforeDestruction;
begin
  inherited BeforeDestruction;
  Images := nil;
end;

procedure TACLSimpleButton.Click;
begin
  if Enabled then
  begin
    PerformClick;
    if ModalResult <> mrNone then
      GetParentForm(Self).ModalResult := ModalResult;
  end;
end;

{$IFDEF FPC}
procedure TACLSimpleButton.ActiveDefaultControlChanged(NewControl: TControl);
var
  AForm: TCustomForm;
begin
  AForm := GetParentForm(Self);
  if NewControl = Self then
  begin
    SubClass.IsDefault := True;
    if AForm <> nil then
      AForm.ActiveDefaultControl := Self;
  end
  else
    if NewControl <> nil then
      SubClass.IsDefault := False
    else
    begin
      SubClass.IsDefault := Default;
      if (AForm <> nil) and (AForm.ActiveDefaultControl = Self) then
        AForm.ActiveDefaultControl := nil;
    end;
end;

procedure TACLSimpleButton.ExecuteCancelAction;
begin
  if Cancel then
    SubClass.PerformClick;
end;

procedure TACLSimpleButton.ExecuteDefaultAction;
begin
  if SubClass.IsFocused or SubClass.IsDefault then
    SubClass.PerformClick;
end;

procedure TACLSimpleButton.UpdateRolesForForm;
var
  LForm: TCustomForm;
  LRole: TControlRolesForForm;
begin
  if FRolesUpdateLocked then
    Exit;
  LForm := GetParentForm(Self);
  if LForm <> nil then
  begin
    LRole := LForm.GetRolesForControl(Self);
    Cancel := crffCancel in LRole;
    Default := crffDefault in LRole;
  end;
end;

procedure TACLSimpleButton.WMKillFocus(var Message: TMessage);
begin
  ActiveDefaultControlChanged(nil);
  inherited;
end;

procedure TACLSimpleButton.WMSetFocus(var Message: TMessage);
begin
  inherited;
  ActiveDefaultControlChanged(Self);
end;

{$ELSE}

procedure TACLSimpleButton.CMFocusChanged(var Message: TMessage);
var
  LSender: TControl;
begin
  LSender := TControl(Message.LParam);
  if LSender is TACLSimpleButton then
    SubClass.IsDefault := Default and (LSender = Self)
  else
    SubClass.IsDefault := Default;

  inherited;
end;

procedure TACLSimpleButton.CMDialogKey(var Message: TCMDialogKey);
begin
  if (Message.CharCode = vkReturn) and (SubClass.IsFocused or SubClass.IsDefault) or
     (Message.CharCode = vkEscape) and Cancel
  then
    if (KeyDataToShiftState(Message.KeyData) = []) and CanFocus then
    begin
      SubClass.PerformClick;
      Message.Result := 1;
      Exit;
    end;

  inherited;
end;

{$ENDIF}

function TACLSimpleButton.CreateStyle: TACLStyleButton;
begin
  Result := TACLStyleButton.Create(Self);
end;

function TACLSimpleButton.CreateSubClass: TACLSimpleButtonSubClass;
begin
  Result := TACLButtonSubClass.Create(Self, Style);
end;

procedure TACLSimpleButton.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = Images) then
    Images := nil;
end;

procedure TACLSimpleButton.Paint;
begin
  inherited;
  CallNotifyEvent(Self, OnPaint);
end;

procedure TACLSimpleButton.PerformClick;
begin
  inherited Click;
end;

procedure TACLSimpleButton.SetTargetDPI(AValue: Integer);
begin
  inherited SetTargetDPI(AValue);
  Glyph.TargetDPI := AValue;
end;

function TACLSimpleButton.GetGlyph: TACLGlyph;
begin
  if not FGlyph.Empty then
    Result := FGlyph
  else
    Result := nil;
end;

function TACLSimpleButton.IsGlyphStored: Boolean;
begin
  Result := not FGlyph.Empty;
end;

function TACLSimpleButton.IsImageIndexStored: Boolean;
begin
  if ActionLink <> nil then
    Result := not TACLSimpleButtonActionLink(ActionLink).IsImageIndexLinked
  else
    Result := ImageIndex <> -1;
end;

function TACLSimpleButton.GetActionLinkClass: TControlActionLinkClass;
begin
  Result := TACLSimpleButtonActionLink;
end;

function TACLSimpleButton.GetDown: Boolean;
begin
  Result := SubClass.IsDown;
end;

function TACLSimpleButton.GetSubClass: TACLButtonSubClass;
begin
  Result := TACLButtonSubClass(inherited SubClass);
end;

procedure TACLSimpleButton.SetCancel(AValue: Boolean);
begin
  if FCancel <> AValue then
  begin
    FCancel := AValue;
    UpdateRoles;
  end;
end;

procedure TACLSimpleButton.SetDefault(AValue: Boolean);
begin
  if FDefault <> AValue then
  begin
    FDefault := AValue;
  {$IFNDEF FPC}
    if HandleAllocated then
    begin
      var AForm := GetParentForm(Self);
      if AForm <> nil then
        AForm.Perform(CM_FOCUSCHANGED, 0, LPARAM(AForm.ActiveControl));
    end;
  {$ENDIF}
    UpdateRoles;
  end;
end;

procedure TACLSimpleButton.SetDown(AValue: Boolean);
begin
  SubClass.IsDown := AValue;
end;

procedure TACLSimpleButton.SetGlyph(const Value: TACLGlyph);
begin
  FGlyph.Assign(Value);
end;

procedure TACLSimpleButton.SetImageIndex(AIndex: TImageIndex);
begin
  if AIndex <> FImageIndex then
  begin
    FImageIndex := AIndex;
    if Images <> nil then
      FullRefresh;
  end;
end;

procedure TACLSimpleButton.SetImages(const AList: TCustomImageList);
begin
  acSetImageList(AList, FImages, FImageChangeLink, Self);
end;

procedure TACLSimpleButton.UpdateRoles;
{$IFDEF FPC}
var
  LForm: TCustomForm;
begin
  LForm := GetParentForm(Self);
  if LForm <> nil then
  begin
    FRolesUpdateLocked := True;
    try
      if Default then
        LForm.DefaultControl := Self
      else if LForm.DefaultControl = Self then
        LForm.DefaultControl := nil;

      if Cancel then
        LForm.CancelControl := Self
      else if LForm.CancelControl = Self then
        LForm.CancelControl := nil;
    finally
      FRolesUpdateLocked := False;
    end;
  end;
end;
{$ELSE}
begin
end;
{$ENDIF}

procedure TACLSimpleButton.HandlerImageChange(Sender: TObject);
begin
  SubClass.ImageList := Images;
  FullRefresh;
end;

{ TACLSimpleButtonActionLink }

function TACLSimpleButtonActionLink.IsImageIndexLinked: Boolean;
begin
  Result := inherited IsImageIndexLinked and
    (TACLSimpleButton(FClient).ImageIndex = TCustomAction(Action).ImageIndex);
end;

procedure TACLSimpleButtonActionLink.SetImageIndex(Value: Integer);
begin
  if IsImageIndexLinked then
    TACLSimpleButton(FClient).ImageIndex := Value;
end;

{ TACLButton }

constructor TACLButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  RegisterSubClass(FDropDownSubClass, TACLButtonSubClass.Create(Self, Style));
  FDropDownSubClass.OnClick := HandlerDropDownClick;
  FDropDownSubClass.HasArrow := True;
  FDropDownSubClass.Part := abpDropDownArrow;
end;

procedure TACLButton.Calculate(ARect: TRect);
const
  PartMap: array [Boolean] of TACLButtonPart = (abpButton, abpDropDown);
begin
  DropDownSubClass.Calculate(ARect.Split(srRight,
    IfThen(Kind = sbkDropDownButton, DropDownSubClass.TextureSize.cx)));
  ARect.Right := FDropDownSubClass.ButtonRect.Left;
  SubClass.ImageIndex := ImageIndex;
  SubClass.HasArrow := Kind = sbkDropDown;
  SubClass.Part := PartMap[Kind = sbkDropDownButton];
  SubClass.Calculate(ARect);
end;

function TACLButton.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  NewWidth := -1;
  NewHeight := -1;
  SubClass.CalculateAutoSize(NewWidth, NewHeight);
  if Kind = sbkDropDownButton then
    Inc(NewWidth, DropDownSubClass.TextureSize.cx);
  NewHeight := Max(NewHeight, dpiApply(DefaultButtonHeight, FCurrentPPI));
  Result := True;
end;

procedure TACLButton.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = DropDownMenu then
      DropDownMenu := nil;
  end;
end;

procedure TACLButton.Paint;
begin
  DropDownSubClass.IsDefault := SubClass.IsDefault or SubClass.IsFocused;
  inherited Paint;
end;

procedure TACLButton.PerformClick;
begin
  if Assigned(OnClick) or (ActionLink <> nil) or (ModalResult <> mrNone) then
    inherited PerformClick
  else
    if Assigned(DropDownMenu) then
    begin
      if (Kind = sbkDropDownButton) and (DropDownMenu.Items.DefaultItem <> nil) then
        DropDownMenu.Items.DefaultItem.Click
      else
        ShowDropDownMenu;
    end;
end;

procedure TACLButton.HandlerDropDownClick(Sender: TObject);
begin
  if Assigned(OnDropDownClick) then
    OnDropDownClick(Self)
  else
    ShowDropDownMenu;
end;

procedure TACLButton.SetKind(AValue: TACLButtonKind);
const
  DropDownKinds = [sbkDropDown, sbkDropDownButton];
begin
  if FKind <> AValue then
  begin
    if [csDesigning, csReading, csLoading] * ComponentState = [csDesigning] then
    begin
      if (Kind in DropDownKinds) <> (AValue in DropDownKinds) then
        Width := Width + Signs[AValue in DropDownKinds] * DropDownSubClass.TextureSize.cx;
    end;
    FKind := AValue;
    UpdateTransparency;
    FullRefresh;
  end;
end;

procedure TACLButton.ShowDropDownMenu;
var
  LMenu: IACLPopup;
  LPosition: TPoint;
begin
  if Assigned(DropDownMenu) then
  begin
    DropDownMenu.PopupComponent := Self;
    LPosition := ClientToScreen(NullPoint);
    if Supports(DropDownMenu, IACLPopup, LMenu) then
      LMenu.PopupUnderControl(Bounds(LPosition.X, LPosition.Y - 1, Width, Height + 2))
    else
      DropDownMenu.Popup(LPosition.X, LPosition.Y + Height + 1);
  end;
end;

procedure TACLButton.UpdateTransparency;
begin
  if SubClass.Transparent or (Kind = sbkDropDownButton) and DropDownSubClass.Transparent then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque];
end;

{ TACLStyleCheckBox }

procedure TACLStyleCheckBox.InitializeResources;
begin
  inherited;
  ColorLine1.InitailizeDefaults('Labels.Colors.Line1', True);
  ColorLine2.InitailizeDefaults('Labels.Colors.Line2', True);
end;

procedure TACLStyleCheckBox.InitializeTextures;
begin
  Texture.InitailizeDefaults('Buttons.Textures.CheckBox');
end;

{ TACLStyleRadioButton }

procedure TACLStyleRadioButton.InitializeTextures;
begin
  Texture.InitailizeDefaults('Buttons.Textures.RadioBox');
end;

{ TACLCheckBoxActionLink }

function TACLCheckBoxActionLink.IsCheckedLinked: Boolean;
begin
  Result := (Action is TCustomAction) and
    (TACLCustomCheckBox(FClient).Checked = TCustomAction(Action).Checked);
end;

procedure TACLCheckBoxActionLink.SetChecked(Value: Boolean);
begin
  if IsCheckedLinked then
    TACLCustomCheckBox(FClient).Checked := TCustomAction(Action).Checked;
end;

{ TACLCheckBoxSubControlOptions }

procedure TACLCheckBoxSubControlOptions.AlignControl(var AClientRect: TRect);
var
  LIndent: Integer;
begin
  if (Position = mBottom) and Owner.ShowCheckMark then
  begin
    // ref. TACLCheckBoxSubClass.Calculate
    // ref. TACLCheckBoxSubClass.CalculateAutoSize
    LIndent :=
      Owner.SubClass.TextureSize.cx +
      Owner.SubClass.GetIndentBetweenElements - acTextIndent;
    Inc(AClientRect.Left, LIndent);
    inherited AlignControl(AClientRect);
    Dec(AClientRect.Left, LIndent);
  end
  else
    inherited AlignControl(AClientRect);
end;

procedure TACLCheckBoxSubControlOptions.Changed;
begin
  SyncEnabled;
  inherited;
end;

procedure TACLCheckBoxSubControlOptions.WindowProc(var Message: TMessage);
begin
  if Message.Msg = CM_ENABLEDCHANGED then
    SyncEnabled;
  inherited;
end;

procedure TACLCheckBoxSubControlOptions.SetEnabled(AValue: Boolean);
begin
  if FEnabled <> AValue then
  begin
    FEnabled := AValue;
    SyncEnabled;
  end;
end;

procedure TACLCheckBoxSubControlOptions.SyncEnabled;
begin
  if Control <> nil then
    Control.Enabled := Enabled;
end;

function TACLCheckBoxSubControlOptions.GetOwnerEx: TACLCustomCheckBox;
begin
  Result := TACLCustomCheckBox(inherited Owner);
end;

{ TACLCheckBoxSubClass }

constructor TACLCheckBoxSubClass.Create;
begin
  inherited;
  FAlignment := taLeftJustify;
  FShowCheckMark := True;
end;

procedure TACLCheckBoxSubClass.Calculate(ARect: TRect);
var
  LGap: Integer;
  LSize: TSize;
begin
  inherited;

{$REGION ' CheckMark '}
  if ShowCheckMark then
  begin
    if WordWrap then
    begin
      FButtonRect.Left := Bounds.Left;
      FButtonRect.Top := Bounds.Top + acFocusRectIndent;
      FButtonRect.Size := TextureSize;
    end
    else
    begin
      LSize := TextureSize;
      FButtonRect := Bounds;
      FButtonRect.CenterVert(LSize.cy);
      FButtonRect.Width := LSize.cx;
    end;
    // ref. TACLCheckBoxSubControlOptions.AlignControl
    // ref. TACLCheckBoxSubClass.CalculateAutoSize
    LGap := IfThen(Caption <> '', GetIndentBetweenElements - acTextIndent);
    if (Alignment = taCenter) and (Caption = '') then
      FButtonRect.Offset((Bounds.Width - FButtonRect.Width) div 2, 0)
    else
      if Alignment = taRightJustify then
      begin
        FButtonRect.Left := Bounds.Right - FButtonRect.Width;
        FButtonRect.Right := Bounds.Right;
        ARect.Right := ButtonRect.Left - LGap;
      end
      else
        ARect.Left := ButtonRect.Right + LGap;
  end
  else
  begin
    FButtonRect := Bounds;
    FButtonRect.Size := NullSize;
  end;
{$ENDREGION}

{$REGION ' Text '}
  FTextRect := ARect;
  MeasureText(ARect);
  ARect.Width := Min(ARect.Width, FTextRect.Width);
  case Alignment of
    taCenter:
      FTextRect.CenterHorz(ARect.Width);
    taRightJustify:
      FTextRect.Left := FTextRect.Right - ARect.Width;
  else
    FTextRect.Width := ARect.Width;
  end;
  FTextRect.CenterVert(ARect.Height);
  FTextRect.Offset(0, -1);
{$ENDREGION}

{$REGION ' FocusRect '}
  if FTextRect.IsEmpty or (Caption = '') then
  begin
    FFocusRect := ButtonRect;
    FFocusRect.Inflate(-2);
    if FFocusRect.IsEmpty then
      FFocusRect := Bounds;
  end
  else
    if ShowCheckMark then
    begin
      FFocusRect := TextRect;
      FFocusRect.Inflate(acTextIndent, acFocusRectIndent);
      FFocusRect := TRect.Intersect(FFocusRect, Bounds);
    end
    else
      FFocusRect := NullRect;
{$ENDREGION}
end;

procedure TACLCheckBoxSubClass.CalculateAutoSize(var AWidth, AHeight: Integer);
var
  LTextRect: TRect;
begin
  LTextRect := Rect(0, 0, IfThen(AWidth < 0, MaxWord, AWidth), MaxWord);
  if ShowCheckMark then
    // ref. TACLCheckBoxSubClass.Calculate
    // ref. TACLCheckBoxSubControlOptions.AlignControl
    Inc(LTextRect.Left, TextureSize.cx + GetIndentBetweenElements - acTextIndent);
  MeasureText(LTextRect);

  AHeight := Max(TextureSize.cy, LTextRect.Height + 2 * acFocusRectIndent);
  AWidth := LTextRect.Width;
  if ShowCheckMark then
  begin
    if AWidth > 0 then
      Inc(AWidth, GetIndentBetweenElements);
    Inc(AWidth, TextureSize.cx);
  end;
end;

procedure TACLCheckBoxSubClass.MeasureText(var ARect: TRect);
begin
  AssignCanvasParameters(MeasureCanvas);
  if ShowCheckMark then
    ARect.Inflate(-acTextIndent, -acFocusRectIndent);
  acSysDrawText(MeasureCanvas, ARect, Caption,
    DT_CALCRECT or IfThen(WordWrap, DT_WORDBREAK));
  if WordWrap or (ARect.Height = 0) then
    ARect.Height := Max(ARect.Height, acFontHeight(MeasureCanvas));
end;

function TACLCheckBoxSubClass.GetStyle: TACLStyleCheckBox;
begin
  Result := inherited Style as TACLStyleCheckBox;
end;

function TACLCheckBoxSubClass.GetTransparent: Boolean;
begin
  Result := True;
end;

procedure TACLCheckBoxSubClass.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Draw(ACanvas, R, State, CheckState);
end;

procedure TACLCheckBoxSubClass.DrawContent(ACanvas: TCanvas);
begin
  if Caption <> '' then
  begin
    AssignCanvasParameters(ACanvas);
    //#AI:
    // Always use acSysDrawText to make layout consistent between
    // singleline and multiline checkboxes
    acSysDrawText(ACanvas, FTextRect, Caption, DT_END_ELLIPSIS or
      DT_VCENTER or acTextAlignHorz[Alignment] or IfThen(WordWrap, DT_WORDBREAK));
  end;
  if ShowLine then
  begin
    acDrawLabelLine(ACanvas, Bounds,
      TRect.Union(ButtonRect, TextRect),
      Style.ColorLine1.Value,
      Style.ColorLine2.Value,
      Alignment);
  end;
end;

procedure TACLCheckBoxSubClass.SetCheckState(AValue: TCheckBoxState);
begin
  if FCheckState <> AValue then
  begin
    FCheckState := AValue;
    Invalidate;
  end;
end;

procedure TACLCheckBoxSubClass.SetShowCheckMark(AValue: Boolean);
begin
  if ShowCheckMark <> AValue then
  begin
    FShowCheckMark := AValue;
    RefreshAutoSize;
  end;
end;

procedure TACLCheckBoxSubClass.SetShowLine(AValue: Boolean);
begin
  if AValue <> FShowLine then
  begin
    if AValue then
      FWordWrap := False;
    FShowLine := AValue;
    RefreshAutoSize;
  end;
end;

procedure TACLCheckBoxSubClass.SetWordWrap(AValue: Boolean);
begin
  if AValue <> FWordWrap then
  begin
    if AValue then
      FShowLine := False;
    FWordWrap := AValue;
    RefreshAutoSize;
  end;
end;

{ TACLCustomCheckBox }

constructor TACLCustomCheckBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSubControl := CreateSubControlOptions;
  AutoSize := True;
end;

destructor TACLCustomCheckBox.Destroy;
begin
  FreeAndNil(FSubControl);
  inherited;
end;

procedure TACLCustomCheckBox.Click;
begin
  if ShowCheckMark then
    ToggleState;
  inherited Click;
end;

procedure TACLCustomCheckBox.ChangeState(AState: TCheckBoxState);
begin
  State := AState;
  inherited Click;
end;

procedure TACLCustomCheckBox.ChangeState(AChecked: Boolean);
begin
  if AChecked then
    ChangeState(cbChecked)
  else
    ChangeState(cbUnchecked);
end;

procedure TACLCustomCheckBox.SetStyle(AStyle: TACLStyleCheckBox);
begin
  GetStyle.Assign(AStyle);
end;

procedure TACLCustomCheckBox.SetSubControl(AValue: TACLCheckBoxSubControlOptions);
begin
  SubControl.Assign(AValue);
end;

function TACLCustomCheckBox.TextOffset: Integer;
begin
  Result := SubClass.TextRect.Left;
end;

procedure TACLCustomCheckBox.ToggleState;
const
  SwitchMap: array[TCheckBoxState] of TCheckBoxState = (cbChecked, cbGrayed, cbUnchecked);
begin
  if AllowGrayed then
    State := SwitchMap[State]
  else
    Checked := not Checked;
end;

procedure TACLCustomCheckBox.Calculate(R: TRect);
begin
  TabStop := ShowCheckMark;
  FocusOnClick := ShowCheckMark;
  SubControl.AlignControl(R);
  SubClass.Calculate(R);
end;

function TACLCustomCheckBox.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  NewHeight := -1;
  if not IsWidthMatters then
    NewWidth := -1;
  SubControl.BeforeAutoSize(NewWidth, NewHeight);
  SubClass.CalculateAutoSize(NewWidth, NewHeight);
  SubControl.AfterAutoSize(NewWidth, NewHeight);
  Result := True;
end;

{$IFDEF FPC}
procedure TACLCustomCheckBox.ShouldAutoAdjust(var AWidth, AHeight: Boolean);
begin
  AWidth  := not AutoSize or IsWidthMatters;
  AHeight := not AutoSize;
end;
{$ENDIF}

function TACLCustomCheckBox.CreateStyle: TACLStyleButton;
begin
  Result := TACLStyleCheckBox.Create(Self);
end;

function TACLCustomCheckBox.CreateSubControlOptions: TACLCheckBoxSubControlOptions;
begin
  Result := TACLCheckBoxSubControlOptions.Create(Self);
end;

function TACLCustomCheckBox.CreateSubClass: TACLSimpleButtonSubClass;
begin
  Result := TACLCheckBoxSubClass.Create(Self, Style);
end;

function TACLCustomCheckBox.GetActionLinkClass: TControlActionLinkClass;
begin
  Result := TACLCheckBoxActionLink;
end;

procedure TACLCustomCheckBox.SetChecked(AValue: Boolean);
begin
  if AValue then
    State := cbChecked
  else
    State := cbUnchecked;
end;

procedure TACLCustomCheckBox.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  UpdateSubControlEnabled;
end;

procedure TACLCustomCheckBox.CMHitTest(var Message: TCMHitTest);
var
  P: TPoint;
begin
  P := SmallPointToPoint(Message.Pos);
  Message.Result := Ord(
    PtInRect(SubClass.ButtonRect, P) or
    PtInRect(SubClass.FocusRect, P) or
    ShowLine and PtInRect(SubClass.Bounds, P)
  {$IFDEF LCLGtk2}
    // Gtk2: не приходит MouseUp, если отвести мышь за пределы контрола
    or MouseCapture
  {$ENDIF}
  );
end;

procedure TACLCustomCheckBox.CMTextChanged(var Message: TMessage);
begin
  inherited;
  if AutoSize then
    AdjustSize;
end;

procedure TACLCustomCheckBox.CMVisibleChanged(var Message: TMessage);
begin
  SubControl.UpdateVisibility;
  inherited;
end;

procedure TACLCustomCheckBox.WMMove(var Message: TMessage);
begin
  inherited;
  if (SubControl <> nil) and (SubControl.Control <> nil) then
    BoundsChanged;
end;

procedure TACLCustomCheckBox.WMNCHitTest(var Message: TCMHitTest);
begin
  if Perform(CM_HITTEST, 0, PointToLParam(ScreenToClient(Message.Pos))) <> 0 then
    Message.Result := HTCLIENT
  else
    Message.Result := HTTRANSPARENT;
end;

function TACLCustomCheckBox.GetSubClass: TACLCheckBoxSubClass;
begin
  Result := TACLCheckBoxSubClass(inherited SubClass);
end;

function TACLCustomCheckBox.GetShowCheckMark: Boolean;
begin
  Result := SubClass.ShowCheckMark;
end;

function TACLCustomCheckBox.GetShowLine: Boolean;
begin
  Result := SubClass.ShowLine;
end;

function TACLCustomCheckBox.GetChecked: Boolean;
begin
  Result := State = cbChecked;
end;

function TACLCustomCheckBox.GetState: TCheckBoxState;
begin
  Result := SubClass.CheckState;
end;

function TACLCustomCheckBox.GetStyle: TACLStyleCheckBox;
begin
  Result := TACLStyleCheckBox(inherited Style);
end;

function TACLCustomCheckBox.GetWordWrap: Boolean;
begin
  Result := SubClass.WordWrap;
end;

function TACLCustomCheckBox.IsCursorStored: Boolean;
begin
  if ShowCheckMark then
    Result := Cursor <> crHandPoint
  else
    Result := Cursor <> crDefault;
end;

function TACLCustomCheckBox.IsWidthMatters: Boolean;
begin
  Result := (Align in [alTop, alBottom, alClient]) or WordWrap or ShowLine;
end;

procedure TACLCustomCheckBox.Loaded;
begin
  inherited;
  UpdateSubControlEnabled;
end;

procedure TACLCustomCheckBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if SubControl <> nil then
    SubControl.Notification(AComponent, Operation);
end;

procedure TACLCustomCheckBox.SetShowCheckMark(AValue: Boolean);
begin
  if not IsCursorStored then
  begin
    if AValue then
      Cursor := crHandPoint
    else
      Cursor := crDefault;
  end;
  SubClass.ShowCheckMark := AValue;
end;

procedure TACLCustomCheckBox.SetShowLine(AValue: Boolean);
begin
  SubClass.ShowLine := AValue;
end;

procedure TACLCustomCheckBox.SetState(AValue: TCheckBoxState);
begin
  SubClass.CheckState := AValue;
  UpdateSubControlEnabled;
end;

procedure TACLCustomCheckBox.UpdateSubControlEnabled;
begin
  SubControl.Enabled := Enabled and (not ShowCheckMark or Checked);
end;

procedure TACLCustomCheckBox.SetWordWrap(AValue: Boolean);
begin
  SubClass.WordWrap := AValue;
end;

{ TACLInplaceCheckBox }

constructor TACLInplaceCheckBox.CreateInplace(const AParams: TACLInplaceInfo);
begin
  inherited Create(nil);
  AutoSize := False;
  Parent := AParams.Parent;
  SetBounds(AParams.TextBounds.Left, AParams.Bounds.Top, AParams.Bounds.Width, AParams.Bounds.Height);
  OnClick := AParams.OnApply;
  OnKeyDown := AParams.OnKeyDown;
end;

procedure TACLInplaceCheckBox.CMHitTest(var Message: TCMHitTest);
begin
  if PtInRect(ClientRect, SmallPointToPoint(Message.Pos)) then
    Message.Result := HTCLIENT
  else
    Message.Result := HTTRANSPARENT;
end;

function TACLInplaceCheckBox.InplaceGetValue: string;
begin
  Result := BoolToStr(Checked, True)
end;

procedure TACLInplaceCheckBox.InplaceSetValue(const AValue: string);
begin
  Checked := (AValue = BoolToStr(True, True)) or (StrToIntDef(AValue, 0) <> 0);
  Caption := InplaceGetValue;
end;

{ TACLRadioButton }

function TACLRadioButton.CreateStyle: TACLStyleButton;
begin
  Result := TACLStyleRadioButton.Create(Self);
end;

procedure TACLRadioButton.ToggleState;
begin
  Checked := True;
end;

procedure TACLRadioButton.SetGroupIndex(const Value: Integer);
begin
  if FGroupIndex <> Value then
  begin
    FGroupIndex := Value;
    SetState(State);
  end;
end;

procedure TACLRadioButton.SetState(AValue: TCheckBoxState);
var
  LControl: TControl;
  I: Integer;
begin
  if State <> AValue then
  begin
    if AValue = cbChecked then
    begin
      if Parent <> nil then
        for I := 0 to Parent.ControlCount - 1 do
        begin
          LControl := Parent.Controls[I];
          if (LControl is TACLRadioButton) and (LControl <> Self) then
          begin
            if TACLRadioButton(LControl).GroupIndex = GroupIndex then
            begin
              TACLRadioButton(LControl).SubClass.CheckState := cbUnchecked;
              TACLRadioButton(LControl).UpdateSubControlEnabled;
            end;
          end;
        end;
    end;
    inherited;
  end;
end;

end.
