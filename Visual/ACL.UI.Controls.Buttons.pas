{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Buttons Controls              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Buttons;

{$I ACL.Config.inc}

interface

uses
  Winapi.Messages,
  Winapi.Windows,
  // VCL
  Vcl.ActnList,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.Menus,
  Vcl.StdCtrls,
  // System
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Types,
  System.UITypes,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.SkinImage,
  ACL.Graphics.SkinImageSet,
  ACL.ObjectLinks,
  ACL.UI.Animation,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Labels,
  ACL.UI.ImageList,
  ACL.UI.Resources,
  ACL.Utils.Common;

const
  DefaultButtonHeight = 25;
  DefaultButtonWidth = 120;

const
  BooleanToCheckBoxState: array[TACLBoolean] of TCheckBoxState = (cbGrayed, cbUnchecked, cbChecked);
  CheckBoxStateToBoolean: array[TCheckBoxState] of TACLBoolean = (acFalse, acTrue, acDefault);

type
  TACLCustomButtonViewInfo = class;

  { TACLStyleCustomButton }

  TACLButtonPart = (abpButton, abpDropDown, abpDropDownArrow);
  TACLButtonState = (absNormal, absHover, absPressed, absDisabled, absActive);

  TACLStyleButton = class(TACLStyle)
  strict private
    function GetContentOffsets: TRect;
    function GetTextColor(AState: TACLButtonState): TColor;
  protected
    procedure InitializeResources; override;
    procedure InitializeTextures; virtual;
  public
    procedure Draw(DC: HDC; const R: TRect; AState: TACLButtonState; APart: TACLButtonPart = abpButton); overload; virtual;
    procedure Draw(DC: HDC; const R: TRect; AState: TACLButtonState; ACheckBoxState: TCheckBoxState); overload; virtual;
    //
    property ContentOffsets: TRect read GetContentOffsets;
    property TextColors[AState: TACLButtonState]: TColor read GetTextColor;
    // for backward compatibility with scripts
    property TextColor: TACLResourceColor index absNormal read GetColor;
    property TextColorDisabled: TACLResourceColor index absDisabled read GetColor;
    property TextColorHover: TACLResourceColor index absHover read GetColor;
    property TextColorPressed: TACLResourceColor index absPressed read GetColor;
  published
    property ColorText: TACLResourceColor index absNormal read GetColor write SetColor stored IsColorStored;
    property ColorTextDisabled: TACLResourceColor index absDisabled read GetColor write SetColor stored IsColorStored;
    property ColorTextHover: TACLResourceColor index absHover read GetColor write SetColor stored IsColorStored;
    property ColorTextPressed: TACLResourceColor index absPressed read GetColor write SetColor stored IsColorStored;
    property Texture: TACLResourceTexture index 0 read GetTexture write SetTexture stored IsTextureStored;
  end;

  { IACLButtonOwner }

  IACLButtonOwner = interface(IACLControl)
  ['{DEFEC667-C49F-4D75-893A-D9CF9F803E01}']
    function ButtonOwnerGetFont: TFont;
    function ButtonOwnerGetImages: TCustomImageList;
    function ButtonOwnerGetStyle: TACLStyleButton;
    procedure ButtonOwnerRecalculate;
  end;

  { TACLCustomButtonViewInfo }

  TACLButtonStateFlag = (bsfPressed, bsfActive, bsfEnabled, bsfFocused, bsfDown, bsfDefault);
  TACLButtonStateFlags = set of TACLButtonStateFlag;

  TACLCustomButtonViewInfo = class(TACLUnknownObject,
    IACLAnimateControl,
    IACLObjectLinksSupport)
  strict private
    FBounds: TRect;
    FCaption: UnicodeString;
    FFlags: TACLButtonStateFlags;
    FOwner: IACLButtonOwner;
    FState: TACLButtonState;
    FTag: Integer;

    FOnClick: TNotifyEvent;

    function GetFlag(Index: TACLButtonStateFlag): Boolean;
    function GetFont: TFont;
    function GetScaleFactor: TACLScaleFactor;
    function GetStyle: TACLStyleButton;
    function GetTextureSize: TSize;
    procedure SetAlignment(AValue: TAlignment);
    procedure SetCaption(const AValue: UnicodeString);
    procedure SetFlag(AFlag: TACLButtonStateFlag; AValue: Boolean);
  protected
    FAlignment: TAlignment;
    FButtonRect: TRect;
    FFocusRect: TRect;
    FTextRect: TRect;

    function CalculateState: TACLButtonState; virtual;
    function CanClickOnDialogChar(Char: Word): Boolean; virtual;
    function GetIndentBetweenElements: Integer; inline;
    function GetTextColor: TColor; virtual;
    function GetTransparent: Boolean; virtual;
    procedure StateChanged; virtual;
    // Drawing
    procedure AssignCanvasParameters(ACanvas: TCanvas); virtual;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); virtual; abstract;
    procedure DrawContent(ACanvas: TCanvas); virtual;
    procedure DrawFocusRect(ACanvas: TCanvas); virtual;
    // Fading
    function FadingCanStarts: Boolean; virtual;
    procedure FadingPrepareBegin(out AAnimator: TACLBitmapFadingAnimation);
    procedure FadingPrepareEnd(AAnimator: TACLBitmapFadingAnimation);
    procedure FadingPrepareFrame(ATarget: TACLBitmap);
    // IACLAnimateControl
    procedure IACLAnimateControl.Animate = Invalidate;
    // Events
    procedure DoClick; virtual;
    procedure DoRecalculate; virtual;
    //
    property Flags: TACLButtonStateFlags read FFlags;
    property Owner: IACLButtonOwner read FOwner;
    property Style: TACLStyleButton read GetStyle;
  public
    constructor Create(AOwner: IACLButtonOwner); virtual;
    destructor Destroy; override;
    procedure Calculate(R: TRect); virtual;
    procedure Draw(ACanvas: TCanvas);
    procedure FullRefresh;
    procedure Invalidate;
    // Keyboard
    function DialogChar(Char: Word): Boolean; virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); virtual;
    procedure KeyUp(var Key: Word; Shift: TShiftState); virtual;
    // Mouse
    procedure MouseDown(Button: TMouseButton; const P: TPoint);
    procedure MouseMove(const P: TPoint);
    procedure MouseUp(Button: TMouseButton; const P: TPoint);

    procedure RefreshState;
    //
    property Alignment: TAlignment read FAlignment write SetAlignment;
    property Bounds: TRect read FBounds;
    property ButtonRect: TRect read FButtonRect;
    property Caption: UnicodeString read FCaption write SetCaption;
    property FocusRect: TRect read FFocusRect;
    property Font: TFont read GetFont;
    property ScaleFactor: TACLScaleFactor read GetScaleFactor;
    property State: TACLButtonState read FState;
    property Tag: Integer read FTag write FTag;
    property TextColor: TColor read GetTextColor;
    property TextRect: TRect read FTextRect;
    property TextureSize: TSize read GetTextureSize;
    property Transparent: Boolean read GetTransparent;
    //
    property IsActive: Boolean index bsfActive read GetFlag write SetFlag;
    property IsDefault: Boolean index bsfDefault read GetFlag write SetFlag;
    property IsDown: Boolean index bsfDown read GetFlag write SetFlag;
    property IsEnabled: Boolean index bsfEnabled read GetFlag write SetFlag;
    property IsFocused: Boolean index bsfFocused read GetFlag write SetFlag;
    property IsPressed: Boolean index bsfPressed read GetFlag write SetFlag;
    //
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

  { TACLCustomButton }

  TACLCustomButton = class(TACLCustomControl,
    IACLButtonOwner,
    IACLFocusableControl)
  strict private
    FShowCaption: Boolean;
    FStyle: TACLStyleButton;
    FViewInfo: TACLCustomButtonViewInfo;

    procedure ButtonClickHandler(Sender: TObject);
    function GetAlignment: TAlignment;
    procedure SetAlignment(AValue: TAlignment);
    procedure SetShowCaption(AValue: Boolean);
    procedure SetStyle(const Value: TACLStyleButton);
  protected
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); override;
    procedure BoundsChanged; override;
    procedure Calculate(R: TRect); virtual;
    function CreateStyle: TACLStyleButton; virtual; abstract;
    function CreateViewInfo: TACLCustomButtonViewInfo; virtual; abstract;
    procedure DoGetHint(const P: TPoint; var AHint: string); override;
    procedure FocusChanged; override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    procedure Paint; override;
    procedure ResourceChanged; override;
    procedure SetDefaultSize; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateCaption;

    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;

    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    // IACLButtonOwner
    procedure IACLButtonOwner.ButtonOwnerRecalculate = FullRefresh;
    function ButtonOwnerGetFont: TFont;
    function ButtonOwnerGetImages: TCustomImageList; virtual;
    function ButtonOwnerGetStyle: TACLStyleButton; virtual;

    // Messages
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFontchanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;

    // Properties
    property ViewInfo: TACLCustomButtonViewInfo read FViewInfo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Alignment: TAlignment read GetAlignment write SetAlignment default taCenter;
    property Action;
    property Align;
    property Anchors;
    property Caption;
    property Cursor;
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

  { TACLButtonViewInfo }

  TACLButtonViewInfoClass = class of TACLButtonViewInfo;
  TACLButtonViewInfo = class(TACLCustomButtonViewInfo)
  strict private
    FHasArrow: Boolean;
    FImageIndex: Integer;

    function GetHasImage: Boolean;
    function GetImageSize: TSize;
    procedure SetImageIndex(AValue: Integer);
  protected
    FArrowRect: TRect;
    FImageRect: TRect;
    FPart: TACLButtonPart;

    procedure CalculateArrowRect(var R: TRect); virtual;
    procedure CalculateImageRect(var R: TRect); virtual;
    procedure CalculateTextRect(var R: TRect); virtual;
    function CanClickOnDialogChar(Char: Word): Boolean; override;
    function GetGlyph: TACLGlyph; virtual;
    function GetImages: TCustomImageList; virtual;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); override;
    procedure DrawContent(ACanvas: TCanvas); override;
    //
    property Glyph: TACLGlyph read GetGlyph;
    property Images: TCustomImageList read GetImages;
    property Part: TACLButtonPart read FPart;
  public
    constructor Create(AOwner: IACLButtonOwner); override;
    procedure Calculate(R: TRect); override;

    property ArrowRect: TRect read FArrowRect;
    property HasArrow: Boolean read FHasArrow write FHasArrow;
    property HasImage: Boolean read GetHasImage;
    property ImageIndex: Integer read FImageIndex write SetImageIndex;
    property ImageRect: TRect read FImageRect;
    property ImageSize: TSize read GetImageSize;
  end;

  { TACLSimpleButton }

  TACLSimpleButton = class(TACLCustomButton, IACLGlyph)
  strict private
    FDefault: Boolean;
    FGlyph: TACLGlyph;
    FImageChangeLink: TChangeLink;
    FImageIndex: TImageIndex;
    FImages: TCustomImageList;
    FModalResult: TModalResult;

    procedure HandlerImageChange(Sender: TObject);
    function IsGlyphStored: Boolean;
    function GetDown: Boolean;
    function GetViewInfo: TACLButtonViewInfo;
    procedure SetDefault(AValue: Boolean);
    procedure SetDown(AValue: Boolean);
    procedure SetGlyph(const Value: TACLGlyph);
    procedure SetImageIndex(AIndex: TImageIndex);
    procedure SetImages(const AList: TCustomImageList);
    // Messages
    procedure CMFocusChanged(var Message: TCMFocusChanged); message CM_FOCUSCHANGED;
  protected
    function CreateStyle: TACLStyleButton; override;
    function CreateViewInfo: TACLCustomButtonViewInfo; override;
    function GetCursor(const P: TPoint): TCursor; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure PerformClick; virtual;
    procedure SetTargetDPI(AValue: Integer); override;
    // IACLButtonOwner
    function ButtonOwnerGetImages: TCustomImageList; override;
    // IACLGlyph
    function GetGlyph: TACLGlyph;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    procedure Click; override;
    //
    property ViewInfo: TACLButtonViewInfo read GetViewInfo;
  published
    property Color;
    property Default: Boolean read FDefault write SetDefault default False;
    property Down: Boolean read GetDown write SetDown default False;
    property Glyph: TACLGlyph read FGlyph write SetGlyph stored IsGlyphStored;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property Images: TCustomImageList read FImages write SetImages;
    property ModalResult: TModalResult read FModalResult write FModalResult default mrNone;
    property ParentColor;
  end;

  { TACLButton }

  TACLButtonKind = (sbkNormal, sbkDropDown, sbkDropDownButton);

  TACLButton = class(TACLSimpleButton)
  strict private
    FDropDownMenu: TPopupMenu;
    FDropDownViewInfo: TACLButtonViewInfo;
    FKind: TACLButtonKind;

    FOnDropDownClick: TNotifyEvent;

    procedure HandlerDropDownClick(Sender: TObject);
    procedure SetKind(AValue: TACLButtonKind);
  protected
    procedure Calculate(R: TRect); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    procedure Paint; override;
    procedure PerformClick; override;
    // Keyboard
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    // Messages
    procedure CMEnabledChanged(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ShowDropDownMenu;
    //
    property DropDownViewInfo: TACLButtonViewInfo read FDropDownViewInfo;
  published
    property DropDownMenu: TPopupMenu read FDropDownMenu write FDropDownMenu;
    property Kind: TACLButtonKind read FKind write SetKind default sbkNormal;
    //
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

  { TACLStyleRadioBox }

  TACLStyleRadioBox = class(TACLStyleCheckBox)
  protected
    procedure InitializeTextures; override;
  end;

  { TACLCheckBoxActionLink }

  TACLCheckBoxActionLink = class(TControlActionLink)
  protected
    function IsCheckedLinked: Boolean; override;
    procedure SetChecked(Value: Boolean); override;
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
    //
    property Enabled: Boolean read FEnabled write SetEnabled;
    property Owner: TACLCustomCheckBox read GetOwnerEx;
  end;

  { TACLCheckBoxViewInfo }

  TACLCheckBoxViewInfo = class(TACLCustomButtonViewInfo)
  strict private
    FCheckState: TCheckBoxState;
    FLineRect: TRect;
    FShowCheckMark: Boolean;
    FShowLine: Boolean;
    FTextSize: TSize;
    FWordWrap: Boolean;

    function GetStyle: TACLStyleCheckBox;
    procedure SetCheckState(AValue: TCheckBoxState);
    procedure SetShowCheckMark(AValue: Boolean);
    procedure SetShowLine(AValue: Boolean);
    procedure SetWordWrap(AValue: Boolean);
  protected
    procedure CalculateButtonRect(var R: TRect); virtual;
    procedure CalculateLineRect(var R: TRect); virtual;
    procedure CalculateTextRect(var R: TRect); virtual;
    procedure CalculateTextSize(var R: TRect; var ATextSize: TSize); virtual;
    function GetTransparent: Boolean; override;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); override;
    procedure DrawContent(ACanvas: TCanvas); override;
  public
    constructor Create(AOwner: IACLButtonOwner); override;
    procedure Calculate(R: TRect); override;
    procedure CalculateAutoSize(var AWidth, AHeight: Integer); virtual;
    //
    property CheckState: TCheckBoxState read FCheckState write SetCheckState;
    property LineRect: TRect read FLineRect;
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
    function GetViewInfo: TACLCheckBoxViewInfo;
    function GetWordWrap: Boolean;
    procedure SetChecked(AValue: Boolean);
    procedure SetShowCheckMark(AValue: Boolean);
    procedure SetShowLine(AValue: Boolean);
    procedure SetStyle(AStyle: TACLStyleCheckBox);
    procedure SetSubControl(AValue: TACLCheckBoxSubControlOptions);
    procedure SetWordWrap(AValue: Boolean);
  protected
    procedure Calculate(R: TRect); override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    function CreateStyle: TACLStyleButton; override;
    function CreateSubControlOptions: TACLCheckBoxSubControlOptions; virtual;
    function CreateViewInfo: TACLCustomButtonViewInfo; override;
    function GetActionLinkClass: TControlActionLinkClass; override;
    function GetCursor(const P: TPoint): TCursor; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure SetState(AValue: TCheckBoxState); virtual;
    procedure UpdateSubControlEnabled;
    // Messages
    procedure CMEnabledChanged(var Message: TMessage); override;
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
    procedure WMMove(var Message: TWMMove); message WM_MOVE;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    //
    property AllowGrayed: Boolean read FAllowGrayed write FAllowGrayed default False;
    property Checked: Boolean read GetChecked write SetChecked;
    property State: TCheckBoxState read GetState write SetState default cbUnchecked;
    property SubControl: TACLCheckBoxSubControlOptions read FSubControl write SetSubControl;
    property ViewInfo: TACLCheckBoxViewInfo read GetViewInfo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
    procedure ChangeState(AChecked: Boolean); overload;
    procedure ChangeState(AState: TCheckBoxState); overload;
    procedure ToggleState; virtual;
  published
    property Alignment default taLeftJustify;
    property AutoSize default True;
    property ShowCheckMark: Boolean read GetShowCheckMark write SetShowCheckMark default True;
    property ShowLine: Boolean read GetShowLine write SetShowLine default False;
    property Style: TACLStyleCheckBox read GetStyle write SetStyle;
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
    procedure SetDefaultSize; override;

    // IACLInplaceControl
    function InplaceGetValue: string;
    function IACLInplaceControl.InplaceIsFocused = Focused;
    procedure InplaceSetValue(const AValue: string);
    procedure IACLInplaceControl.InplaceSetFocus = SetFocus;
    //
    procedure CMHitTest(var Message: TWMNCHitTest); override;
  public
    constructor CreateInplace(const AParams: TACLInplaceInfo);
    property AllowGrayed;
  end;

  { TACLRadioBox }

  TACLRadioBox = class(TACLCustomCheckBox)
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
  System.Math,
  // ACL
  ACL.UI.PopupMenu,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

{ TACLStyleButton }

procedure TACLStyleButton.Draw(DC: HDC; const R: TRect; AState: TACLButtonState; APart: TACLButtonPart = abpButton);
begin
  Texture.Draw(DC, R, Ord(APart) * 5 + Ord(AState));
end;

procedure TACLStyleButton.Draw(DC: HDC; const R: TRect; AState: TACLButtonState; ACheckBoxState: TCheckBoxState);
begin
  Texture.Draw(DC, R, Ord(ACheckBoxState) * 5 + Ord(AState));
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
  Result := clDefault;
  case AState of
    absHover:
      Result := ColorTextHover.AsColor;
    absPressed:
      Result := ColorTextPressed.AsColor;
    absDisabled:
      Result := ColorTextDisabled.AsColor;
  end;
  if Result = clDefault then
    Result := ColorText.AsColor;
end;

{ TACLCustomButtonViewInfo }

constructor TACLCustomButtonViewInfo.Create(AOwner: IACLButtonOwner);
begin
  inherited Create;
  FOwner := AOwner;
  FAlignment := taCenter;
  FFlags := [bsfEnabled];
end;

destructor TACLCustomButtonViewInfo.Destroy;
begin
  AnimationManager.RemoveOwner(Self);
  TACLObjectLinks.Release(Self);
  inherited Destroy;
end;

procedure TACLCustomButtonViewInfo.Calculate(R: TRect);
begin
  FBounds := R;
  FButtonRect := R;
end;

procedure TACLCustomButtonViewInfo.Draw(ACanvas: TCanvas);
var
  AClipRgn: HRGN;
begin
  if RectVisible(ACanvas.Handle, Bounds) then
  begin
    ACanvas.Font := Font;
    AClipRgn := acSaveClipRegion(ACanvas.Handle);
    try
      acIntersectClipRegion(ACanvas.Handle, Bounds);
      if not AnimationManager.Draw(Self, ACanvas.Handle, ButtonRect) then
        DrawBackground(ACanvas, ButtonRect);
      if IsFocused then
        DrawFocusRect(ACanvas);
      DrawContent(ACanvas);
    finally
      acRestoreClipRegion(ACanvas.Handle, AClipRgn);
    end;
  end;
end;

procedure TACLCustomButtonViewInfo.FullRefresh;
begin
  DoRecalculate;
  Invalidate;
end;

procedure TACLCustomButtonViewInfo.Invalidate;
begin
  Owner.InvalidateRect(Bounds);
end;

function TACLCustomButtonViewInfo.DialogChar(Char: Word): Boolean;
var
  AFocusable: IACLFocusableControl;
begin
  Result := IsEnabled and CanClickOnDialogChar(Char);
  if Result then
  begin
    if Supports(Owner, IACLFocusableControl, AFocusable) then
    begin
      if AFocusable.CanFocus then
        AFocusable.SetFocus;
    end;
    if IsFocused then
      DoClick;
  end;
end;

procedure TACLCustomButtonViewInfo.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
    IsPressed := True;
end;

procedure TACLCustomButtonViewInfo.KeyUp(var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      IsPressed := False;

    VK_SPACE:
      if IsPressed then
      try
        DoClick;
      finally
        IsPressed := False;
      end;
  end;
end;

procedure TACLCustomButtonViewInfo.MouseDown(Button: TMouseButton; const P: TPoint);
begin
  IsPressed := IsEnabled and PtInRect(Bounds, P) and (Button = mbLeft);
end;

procedure TACLCustomButtonViewInfo.MouseMove(const P: TPoint);
begin
  IsActive := IsEnabled and PtInRect(Bounds, P);
end;

procedure TACLCustomButtonViewInfo.MouseUp(Button: TMouseButton; const P: TPoint);
var
  ALink: TObject;
begin
  TACLObjectLinks.RegisterWeakReference(Self, @ALink);
  try
    if (Button = mbLeft) and IsPressed then
    begin
      if PtInRect(Bounds, P) then
        DoClick;
    end;
  finally
    if ALink <> nil then
      IsPressed := False;
    TACLObjectLinks.UnregisterWeakReference(@ALink);
  end;
end;

procedure TACLCustomButtonViewInfo.RefreshState;
var
  AAnimator: TACLBitmapFadingAnimation;
  ANewState: TACLButtonState;
begin
  ANewState := CalculateState;
  if ANewState <> FState then
  begin
    if FadingCanStarts and (FState = absHover) and (ANewState in [absActive, absNormal]) then
    begin
      FadingPrepareBegin(AAnimator);
      FState := ANewState;
      FadingPrepareEnd(AAnimator);
    end;
    FState := ANewState;
    StateChanged;
    Invalidate;
  end;
end;

function TACLCustomButtonViewInfo.CalculateState: TACLButtonState;
begin
  if not IsEnabled then
    Result := absDisabled
  else if IsPressed or IsDown then
    Result := absPressed
  else if IsActive then
    Result := absHover
  else if IsFocused or IsDefault then
    Result := absActive
  else
    Result := absNormal;
end;

function TACLCustomButtonViewInfo.CanClickOnDialogChar(Char: Word): Boolean;
begin
  Result := IsAccel(Char, Caption);
end;

function TACLCustomButtonViewInfo.GetFont: TFont;
begin
  Result := Owner.ButtonOwnerGetFont;
end;

function TACLCustomButtonViewInfo.GetIndentBetweenElements: Integer;
begin
  Result := ScaleFactor.Apply(acIndentBetweenElements);
end;

function TACLCustomButtonViewInfo.GetTextColor: TColor;
begin
  Result := Style.TextColors[State];
end;

function TACLCustomButtonViewInfo.GetTransparent: Boolean;
begin
  Result := Style.Texture.HasAlpha;
end;

procedure TACLCustomButtonViewInfo.StateChanged;
begin
  // do nothing
end;

procedure TACLCustomButtonViewInfo.AssignCanvasParameters(ACanvas: TCanvas);
begin
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Font.Color := TextColor;
  ACanvas.Brush.Style := bsClear;
end;

procedure TACLCustomButtonViewInfo.DrawContent(ACanvas: TCanvas);
var
  ATextRect: TRect;
begin
  if Caption <> '' then
  begin
    AssignCanvasParameters(ACanvas);
    ATextRect := TextRect;
    acSysDrawText(ACanvas, ATextRect, Caption, acTextAlignHorz[Alignment] or
      DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS); // Keep the "&" Prefix in mind
  end;
end;

procedure TACLCustomButtonViewInfo.DrawFocusRect(ACanvas: TCanvas);
begin
  acDrawFocusRect(ACanvas.Handle, FocusRect, TextColor);
end;

function TACLCustomButtonViewInfo.FadingCanStarts: Boolean;
begin
  Result := [bsfEnabled, bsfPressed] * FFlags = [bsfEnabled];
end;

procedure TACLCustomButtonViewInfo.FadingPrepareBegin(out AAnimator: TACLBitmapFadingAnimation);
begin
  AAnimator := TACLBitmapFadingAnimation.Create(Self, acUIFadingTime);
  FadingPrepareFrame(AAnimator.AllocateFrame1(ButtonRect));
end;

procedure TACLCustomButtonViewInfo.FadingPrepareEnd(AAnimator: TACLBitmapFadingAnimation);
begin
  FadingPrepareFrame(AAnimator.AllocateFrame2(ButtonRect));
  AAnimator.Run;
end;

procedure TACLCustomButtonViewInfo.FadingPrepareFrame(ATarget: TACLBitmap);
begin
  DrawBackground(ATarget.Canvas, ATarget.ClientRect);
end;

procedure TACLCustomButtonViewInfo.DoClick;
begin
  CallNotifyEvent(Self, OnClick);
end;

procedure TACLCustomButtonViewInfo.DoRecalculate;
begin
  Owner.ButtonOwnerRecalculate;
end;

function TACLCustomButtonViewInfo.GetFlag(Index: TACLButtonStateFlag): Boolean;
begin
  Result := Index in FFlags;
end;

function TACLCustomButtonViewInfo.GetScaleFactor: TACLScaleFactor;
begin
  Result := Owner.GetScaleFactor;
end;

function TACLCustomButtonViewInfo.GetStyle: TACLStyleButton;
begin
  Result := Owner.ButtonOwnerGetStyle;
end;

function TACLCustomButtonViewInfo.GetTextureSize: TSize;
begin
  Result := Style.Texture.FrameSize;
end;

procedure TACLCustomButtonViewInfo.SetAlignment(AValue: TAlignment);
begin
  if AValue <> FAlignment then
  begin
    FAlignment := AValue;
    FullRefresh;
  end;
end;

procedure TACLCustomButtonViewInfo.SetCaption(const AValue: UnicodeString);
begin
  if AValue <> FCaption then
  begin
    FCaption := AValue;
    FullRefresh;
  end;
end;

procedure TACLCustomButtonViewInfo.SetFlag(AFlag: TACLButtonStateFlag; AValue: Boolean);
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
  ControlStyle := ControlStyle - [csDoubleClicks, csClickEvents];
  FViewInfo := CreateViewInfo;
  FViewInfo.OnClick := ButtonClickHandler;
  FShowCaption := True;
  FStyle := CreateStyle;
end;

destructor TACLCustomButton.Destroy;
begin
  FreeAndNil(FViewInfo);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLCustomButton.DoGetHint(const P: TPoint; var AHint: string);
begin
  if not ShowCaption and (AHint = '') then
    AHint := Caption;
  inherited;
end;

function TACLCustomButton.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if ViewInfo.Transparent then
    Result := cbsTransparent
  else
    Result := cbsOpaque;
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
  if ViewInfo <> nil then
    Calculate(ClientRect);
end;

procedure TACLCustomButton.Calculate(R: TRect);
begin
  ViewInfo.Calculate(R);
end;

procedure TACLCustomButton.SetTargetDPI(AValue: Integer);
begin
  inherited;
  Style.SetTargetDPI(AValue);
end;

procedure TACLCustomButton.FocusChanged;
begin
  inherited FocusChanged;
  if not IsDesigning then
  begin
    ViewInfo.IsFocused := Focused;
    ViewInfo.Invalidate;
  end;
end;

procedure TACLCustomButton.Paint;
begin
  ViewInfo.Draw(Canvas);
end;

procedure TACLCustomButton.ResourceChanged;
begin
  inherited;
  FullRefresh;
end;

procedure TACLCustomButton.UpdateCaption;
begin
  ViewInfo.Caption := IfThenW(ShowCaption, Caption);
end;

procedure TACLCustomButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  ViewInfo.KeyDown(Key, Shift);
end;

procedure TACLCustomButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  ViewInfo.KeyUp(Key, Shift);
end;

procedure TACLCustomButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  ViewInfo.MouseDown(Button, Point(X, Y));
end;

procedure TACLCustomButton.MouseEnter;
begin
  inherited MouseEnter;
  Invalidate;
end;

procedure TACLCustomButton.MouseLeave;
begin
  inherited MouseLeave;
  ViewInfo.MouseMove(InvalidPoint);
  ViewInfo.Invalidate;
end;

procedure TACLCustomButton.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  ViewInfo.MouseMove(Point(X, Y));
end;

procedure TACLCustomButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  ViewInfo.MouseUp(Button, Point(X, Y));
end;

function TACLCustomButton.ButtonOwnerGetFont: TFont;
begin
  Result := Font;
end;

function TACLCustomButton.ButtonOwnerGetImages: TCustomImageList;
begin
  Result := nil;
end;

function TACLCustomButton.ButtonOwnerGetStyle: TACLStyleButton;
begin
  Result := Style;
end;

procedure TACLCustomButton.CMDialogChar(var Message: TCMDialogChar);
begin
  if ViewInfo.DialogChar(Message.CharCode) then
    Message.Result := 1
  else
    inherited;
end;

procedure TACLCustomButton.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  ViewInfo.IsEnabled := Enabled;
end;

procedure TACLCustomButton.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FullRefresh;
end;

procedure TACLCustomButton.CMHintShow(var Message: TCMHintShow);
begin
  if ViewInfo.IsPressed then // Bug fixed with Menu and Hint shadows
    Message.Result := 1
  else
    inherited;
end;

procedure TACLCustomButton.CMTextChanged(var Message: TMessage);
begin
  inherited;
  UpdateCaption;
end;

procedure TACLCustomButton.ButtonClickHandler(Sender: TObject);
begin
  Click;
end;

function TACLCustomButton.GetAlignment: TAlignment;
begin
  Result := ViewInfo.Alignment;
end;

procedure TACLCustomButton.SetAlignment(AValue: TAlignment);
begin
  ViewInfo.Alignment := AValue;
end;

procedure TACLCustomButton.SetDefaultSize;
begin
  SetBounds(Left, Top, DefaultButtonWidth, DefaultButtonHeight);
end;

procedure TACLCustomButton.SetShowCaption(AValue: Boolean);
begin
  if FShowCaption <> AValue then
  begin
    FShowCaption := AValue;
    UpdateCaption;
  end;
end;

procedure TACLCustomButton.SetStyle(const Value: TACLStyleButton);
begin
  FStyle.Assign(Value);
end;

{ TACLButtonViewInfo }

procedure TACLButtonViewInfo.Calculate(R: TRect);
begin
  inherited;
  FButtonRect := R;
  R := acRectContent(R, Style.ContentOffsets);
  FFocusRect := R;
  R := acRectInflate(R, -1);
  CalculateArrowRect(R);
  CalculateImageRect(R);
  CalculateTextRect(R);
end;

procedure TACLButtonViewInfo.CalculateArrowRect(var R: TRect);
begin
  if HasArrow then
  begin
    FArrowRect := R;
    if Part <> abpDropDownArrow then
    begin
      FArrowRect.Right := FArrowRect.Right - GetIndentBetweenElements;
      FArrowRect.Left := FArrowRect.Right - ScaleFactor.Apply(acDropArrowSize.cx);
    end;
    R.Right := FArrowRect.Left - GetIndentBetweenElements;
  end;
end;

procedure TACLButtonViewInfo.CalculateImageRect(var R: TRect);
var
  AImageSize: TSize;
begin
  if HasImage then
  begin
    AImageSize := ImageSize;

    if Caption <> '' then
    begin
      FImageRect := acRectCenterVertically(R, AImageSize.cy);
      FImageRect := acRectSetWidth(FImageRect, AImageSize.cx);
    end
    else
      FImageRect := acRectCenter(R, AImageSize);

    R.Left := FImageRect.Right + GetIndentBetweenElements;
  end;
end;

procedure TACLButtonViewInfo.CalculateTextRect(var R: TRect);
begin
  FTextRect := acRectInflate(R, -ScaleFactor.Apply(acTextIndent - 1), 0);
end;

function TACLButtonViewInfo.CanClickOnDialogChar(Char: Word): Boolean;
begin
  Result := inherited CanClickOnDialogChar(Char) or (Char = VK_RETURN) and (IsDefault or IsFocused);
end;

constructor TACLButtonViewInfo.Create(AOwner: IACLButtonOwner);
begin
  inherited;
  FImageIndex := -1;
end;

function TACLButtonViewInfo.GetGlyph: TACLGlyph;
var
  AIntf: IACLGlyph;
begin
  if Supports(Owner, IACLGlyph, AIntf) then
    Result := AIntf.GetGlyph
  else
    Result := nil;
end;

function TACLButtonViewInfo.GetImages: TCustomImageList;
begin
  Result := Owner.ButtonOwnerGetImages;
end;

procedure TACLButtonViewInfo.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Draw(ACanvas.Handle, R, State, Part);
end;

procedure TACLButtonViewInfo.DrawContent(ACanvas: TCanvas);
begin
  inherited DrawContent(ACanvas);

  if FHasArrow then
    acDrawDropArrow(ACanvas.Handle, ArrowRect, TextColor, ScaleFactor.Apply(acDropArrowSize));

  if not acRectIsEmpty(ImageRect) then
  begin
    if Glyph <> nil then
      Glyph.Draw(ACanvas.Handle, ImageRect, IsEnabled)
    else
      acDrawImage(ACanvas, ImageRect, Images, ImageIndex, IsEnabled);
  end;
end;

function TACLButtonViewInfo.GetHasImage: Boolean;
begin
  Result := (Part <> abpDropDownArrow) and (Assigned(Images) and (ImageIndex >= 0) or Assigned(Glyph));
end;

function TACLButtonViewInfo.GetImageSize: TSize;
begin
  if Glyph <> nil then
    Result := Glyph.FrameSize
  else
    Result := acGetImageListSize(Images, ScaleFactor);
end;

procedure TACLButtonViewInfo.SetImageIndex(AValue: Integer);
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

procedure TACLSimpleButton.BeforeDestruction;
begin
  inherited BeforeDestruction;
  Images := nil;
end;

procedure TACLSimpleButton.Click;
var
  ALink: TObject;
begin
  if Enabled then
  begin
    TACLObjectLinks.RegisterWeakReference(Self, @ALink);
    try
      PerformClick;
      if ALink <> nil then
      begin
        if ModalResult <> mrNone then
          GetParentForm(Self).ModalResult := ModalResult;
      end;
    finally
      TACLObjectLinks.UnregisterWeakReference(@ALink);
    end;
  end;
end;

procedure TACLSimpleButton.CMFocusChanged(var Message: TCMFocusChanged);
begin
  if Message.Sender is TACLCustomButton then
    ViewInfo.IsDefault := Default and (Message.Sender = Self)
  else
    ViewInfo.IsDefault := Default;
  inherited;
end;

function TACLSimpleButton.CreateStyle: TACLStyleButton;
begin
  Result := TACLStyleButton.Create(Self);
end;

function TACLSimpleButton.CreateViewInfo: TACLCustomButtonViewInfo;
begin
  Result := TACLButtonViewInfo.Create(Self);
end;

function TACLSimpleButton.GetCursor(const P: TPoint): TCursor;
begin
  Result := inherited GetCursor(P);
  if Result = crDefault then
    Result := crHandPoint;
end;

procedure TACLSimpleButton.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = Images) then
    Images := nil;
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

function TACLSimpleButton.ButtonOwnerGetImages: TCustomImageList;
begin
  Result := Images;
end;

function TACLSimpleButton.IsGlyphStored: Boolean;
begin
  Result := not FGlyph.Empty;
end;

function TACLSimpleButton.GetDown: Boolean;
begin
  Result := ViewInfo.IsDown;
end;

function TACLSimpleButton.GetViewInfo: TACLButtonViewInfo;
begin
  Result := TACLButtonViewInfo(inherited ViewInfo);
end;

procedure TACLSimpleButton.SetDefault(AValue: Boolean);
var
  AForm: TCustomForm;
begin
  if FDefault <> AValue then
  begin
    FDefault := AValue;
    if HandleAllocated then
    begin
      AForm := GetParentForm(Self);
      if AForm <> nil then
        AForm.Perform(CM_FOCUSCHANGED, 0, LPARAM(AForm.ActiveControl));
    end;
  end;
end;

procedure TACLSimpleButton.SetDown(AValue: Boolean);
begin
  ViewInfo.IsDown := AValue;
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

procedure TACLSimpleButton.HandlerImageChange(Sender: TObject);
begin
  FullRefresh;
end;

{ TACLButton }

constructor TACLButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDropDownViewInfo := TACLButtonViewInfo.Create(Self);
  FDropDownViewInfo.OnClick := HandlerDropDownClick;
  FDropDownViewInfo.FPart := abpDropDownArrow;
end;

destructor TACLButton.Destroy;
begin
  FreeAndNil(FDropDownViewInfo);
  inherited Destroy;
end;

procedure TACLButton.ShowDropDownMenu;
var
  AMenu: IACLPopup;
  APosition: TPoint;
begin
  if Assigned(DropDownMenu) then
  begin
    DropDownMenu.PopupComponent := Self;
    APosition := ClientToScreen(NullPoint);
    if Supports(DropDownMenu, IACLPopup, AMenu) then
      AMenu.PopupUnderControl(Bounds(APosition.X, APosition.Y, Width, Height))
    else
      DropDownMenu.Popup(APosition.X, APosition.Y + Height + 1);
  end;
end;

function TACLButton.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if ViewInfo.Transparent or (Kind = sbkDropDownButton) and DropDownViewInfo.Transparent then
    Result := cbsTransparent
  else
    Result := cbsOpaque;
end;

procedure TACLButton.Calculate(R: TRect);
const
  PartMap: array [Boolean] of TACLButtonPart = (abpButton, abpDropDown);
var
  DR: TRect;
begin
  DR := acRectSetLeft(R, IfThen(Kind = sbkDropDownButton, DropDownViewInfo.TextureSize.cx));
  R.Right := DR.Left;

  DropDownViewInfo.HasArrow := True;
  DropDownViewInfo.Calculate(DR);

  ViewInfo.ImageIndex := ImageIndex;
  ViewInfo.HasArrow := Kind = sbkDropDown;
  ViewInfo.FPart := PartMap[Kind = sbkDropDownButton];
  ViewInfo.Calculate(R);
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
  inherited Paint;
  DropDownViewInfo.Draw(Canvas);
end;

procedure TACLButton.PerformClick;
begin
  if Assigned(OnClick) or (ActionLink <> nil) or (ModalResult <> mrNone) then
    inherited PerformClick
  else
    if (Kind = sbkDropDownButton) and Assigned(DropDownMenu) and (DropDownMenu.Items.DefaultItem <> nil) then
      DropDownMenu.Items.DefaultItem.Click
    else
      ShowDropDownMenu;
end;

procedure TACLButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  if (Kind = sbkDropDownButton) and acIsDropDownCommand(Key, Shift) then
  begin
    DropDownViewInfo.IsPressed := True;
    DropDownViewInfo.DoClick;
    DropDownViewInfo.IsPressed := False;
  end
end;

procedure TACLButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  DropDownViewInfo.MouseDown(Button, Point(X, Y));
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TACLButton.MouseLeave;
begin
  DropDownViewInfo.MouseMove(InvalidPoint);
  inherited MouseLeave;
end;

procedure TACLButton.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  DropDownViewInfo.MouseMove(Point(X, Y));
  inherited MouseMove(Shift, X, Y);
end;

procedure TACLButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  DropDownViewInfo.MouseUp(Button, Point(X, Y));
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TACLButton.HandlerDropDownClick(Sender: TObject);
begin
  if Assigned(OnDropDownClick) then
    OnDropDownClick(Self)
  else
    ShowDropDownMenu;
end;

procedure TACLButton.SetKind(AValue: TACLButtonKind);
begin
  if FKind <> AValue then
  begin
    FKind := AValue;
    UpdateTransparency;
    FullRefresh;
  end;
end;

procedure TACLButton.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  DropDownViewInfo.IsEnabled := Enabled;
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

{ TACLStyleRadioBox }

procedure TACLStyleRadioBox.InitializeTextures;
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
  AIndent: Integer;
begin
  if (Position = mBottom) and Owner.ShowCheckMark then
  begin
    AIndent := Owner.ViewInfo.TextureSize.cx + Owner.ViewInfo.GetIndentBetweenElements;
    Inc(AClientRect.Left, AIndent);
    inherited AlignControl(AClientRect);
    Dec(AClientRect.Left, AIndent);
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

{ TACLCheckBoxViewInfo }

constructor TACLCheckBoxViewInfo.Create(AOwner: IACLButtonOwner);
begin
  inherited Create(AOwner);
  FAlignment := taLeftJustify;
  FShowCheckMark := True;
end;

procedure TACLCheckBoxViewInfo.Calculate(R: TRect);
begin
  inherited Calculate(R);
  CalculateButtonRect(R);
  CalculateTextRect(R);
  CalculateLineRect(R);
end;

procedure TACLCheckBoxViewInfo.CalculateAutoSize(var AWidth, AHeight: Integer);
var
  ATextRect: TRect;
  ATextSize: TSize;
begin
  ATextRect := Rect(0, 0, IfThen(AWidth < 0, MaxWord, AWidth), MaxWord);
  if ShowCheckMark then
    Inc(ATextRect.Left, TextureSize.cx + GetIndentBetweenElements - acTextIndent);

  CalculateTextSize(ATextRect, ATextSize);

  if AHeight < 0 then
    AHeight := Max(TextureSize.cy, ATextSize.cy + 2 * acFocusRectIndent);
  if AWidth < 0 then
  begin
    AWidth := ATextSize.cx;
    if ShowCheckMark then
    begin
      if ATextSize.cx > 0 then
        Inc(AWidth, 2 * acTextIndent + GetIndentBetweenElements);
      Inc(AWidth, TextureSize.cx);
    end;
  end;
end;

procedure TACLCheckBoxViewInfo.CalculateButtonRect(var R: TRect);
var
  ASize: TSize;
begin
  if ShowCheckMark then
  begin
    ASize := TextureSize;
    FButtonRect := acRectSetWidth(R, ASize.cx);
    if WordWrap then
      FButtonRect := acRectSetTop(FButtonRect, FButtonRect.Top + acFocusRectIndent, ASize.cy)
    else
      FButtonRect := acRectCenter(FButtonRect, ASize);

    R.Left := FButtonRect.Right + GetIndentBetweenElements - acTextIndent;
  end
  else
    FButtonRect := NullRect;
end;

procedure TACLCheckBoxViewInfo.CalculateLineRect(var R: TRect);
begin
  if ShowLine then
  begin
    if Odd(R.Height) then
      Inc(R.Bottom);
    FLineRect := acRectCenterVertically(R, 2);
  end
  else
    FLineRect := NullRect;
end;

procedure TACLCheckBoxViewInfo.CalculateTextRect(var R: TRect);
var
  ATextWidth: Integer;
begin
  CalculateTextSize(R, FTextSize);

  ATextWidth := Min(FTextSize.cx, R.Width);
  case Alignment of
    taCenter:
      FTextRect := acRectCenterHorizontally(R, ATextWidth);
    taRightJustify:
      FTextRect := acRectSetRight(R, R.Right, ATextWidth);
  else
    FTextRect := acRectSetWidth(R, ATextWidth);
  end;

  FTextRect := acRectCenterVertically(FTextRect, FTextSize.cy);
  FTextRect.Offset(0, -1);

  if TextRect.IsEmpty or (Caption = '') then
  begin
    FFocusRect := acRectInflate(ButtonRect, -2);
    if FFocusRect.IsEmpty then
      FFocusRect := Bounds;
  end
  else
    if ShowCheckMark then
    begin
      FFocusRect := acRectInflate(TextRect, acTextIndent, acFocusRectIndent);
      FFocusRect := TRect.Intersect(FFocusRect, Bounds);
    end
    else
      FFocusRect := NullRect;
end;

procedure TACLCheckBoxViewInfo.CalculateTextSize(var R: TRect; var ATextSize: TSize);
var
  ATextRect: TRect;
begin
  MeasureCanvas.Font := Font;
  if ShowCheckMark then
    R := acRectInflate(R, -acTextIndent, -acFocusRectIndent);

  ATextRect := R;
  acSysDrawText(MeasureCanvas, ATextRect, Caption, DT_CALCRECT or IfThen(WordWrap, DT_WORDBREAK));
  ATextSize := acSize(ATextRect);

  if WordWrap or (FTextSize.cy = 0) then
    ATextSize.cy := Max(ATextSize.cy, acFontHeight(MeasureCanvas));
end;

function TACLCheckBoxViewInfo.GetStyle: TACLStyleCheckBox;
begin
  Result := inherited Style as TACLStyleCheckBox;
end;

function TACLCheckBoxViewInfo.GetTransparent: Boolean;
begin
  Result := True;
end;

procedure TACLCheckBoxViewInfo.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Draw(ACanvas.Handle, R, State, CheckState);
end;

procedure TACLCheckBoxViewInfo.DrawContent(ACanvas: TCanvas);
begin
  if Caption <> '' then
  begin
    AssignCanvasParameters(ACanvas);
    //#AI: Use the acSysDrawText always to make layout consistent between singleline and multiline checkboxes
    acSysDrawText(ACanvas, FTextRect, Caption,
      DT_END_ELLIPSIS or DT_NOPREFIX or acTextAlignHorz[Alignment] or IfThen(WordWrap, DT_WORDBREAK));
  end;
  if ShowLine then
    acDrawLabelLine(ACanvas, FLineRect, TextRect, Style.ColorLine1.Value, Style.ColorLine2.Value);
end;

procedure TACLCheckBoxViewInfo.SetCheckState(AValue: TCheckBoxState);
begin
  if FCheckState <> AValue then
  begin
    FCheckState := AValue;
    Invalidate;
  end;
end;

procedure TACLCheckBoxViewInfo.SetShowCheckMark(AValue: Boolean);
begin
  if ShowCheckMark <> AValue then
  begin
    FShowCheckMark := AValue;
    FullRefresh;
  end;
end;

procedure TACLCheckBoxViewInfo.SetShowLine(AValue: Boolean);
begin
  if AValue <> FShowLine then
  begin
    if AValue then
      FWordWrap := False;
    FShowLine := AValue;
    FullRefresh;
  end;
end;

procedure TACLCheckBoxViewInfo.SetWordWrap(AValue: Boolean);
begin
  if AValue <> FWordWrap then
  begin
    if AValue then
      FShowLine := False;
    FWordWrap := AValue;
    FullRefresh;
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
  ViewInfo.Calculate(R);
end;

function TACLCustomCheckBox.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  NewHeight := -1;
  if (Align in [alNone, alLeft, alRight]) and not (WordWrap or ShowLine) then
    NewWidth := -1;
  SubControl.BeforeAutoSize(NewWidth, NewHeight);
  ViewInfo.CalculateAutoSize(NewWidth, NewHeight);
  SubControl.AfterAutoSize(NewWidth, NewHeight);
  Result := True;
end;

function TACLCustomCheckBox.CreateStyle: TACLStyleButton;
begin
  Result := TACLStyleCheckBox.Create(Self);
end;

function TACLCustomCheckBox.CreateSubControlOptions: TACLCheckBoxSubControlOptions;
begin
  Result := TACLCheckBoxSubControlOptions.Create(Self);
end;

function TACLCustomCheckBox.CreateViewInfo: TACLCustomButtonViewInfo;
begin
  Result := TACLCheckBoxViewInfo.Create(Self);
end;

function TACLCustomCheckBox.GetActionLinkClass: TControlActionLinkClass;
begin
  Result := TACLCheckBoxActionLink;
end;

function TACLCustomCheckBox.GetCursor(const P: TPoint): TCursor;
begin
  Result := inherited GetCursor(P);
  if (Result = crDefault) and ShowCheckMark then
    Result := crHandPoint;
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
    PtInRect(ViewInfo.ButtonRect, P) or
    PtInRect(ViewInfo.FocusRect, P) or
    PtInRect(ViewInfo.LineRect, P));
end;

procedure TACLCustomCheckBox.WMMove(var Message: TWMMove);
begin
  inherited;
  if (SubControl <> nil) and (SubControl.Control <> nil) then
    BoundsChanged;
end;

procedure TACLCustomCheckBox.WMNCHitTest(var Message: TCMHitTest);
begin
  if Perform(CM_HITTEST, 0, PointToLParam(ScreenToClient(SmallPointToPoint(Message.Pos)))) <> 0 then
    Message.Result := HTCLIENT
  else
    Message.Result := HTTRANSPARENT;
end;

function TACLCustomCheckBox.GetViewInfo: TACLCheckBoxViewInfo;
begin
  Result := TACLCheckBoxViewInfo(inherited ViewInfo);
end;

function TACLCustomCheckBox.GetShowCheckMark: Boolean;
begin
  Result := ViewInfo.ShowCheckMark;
end;

function TACLCustomCheckBox.GetShowLine: Boolean;
begin
  Result := ViewInfo.ShowLine;
end;

function TACLCustomCheckBox.GetChecked: Boolean;
begin
  Result := State = cbChecked;
end;

function TACLCustomCheckBox.GetState: TCheckBoxState;
begin
  Result := ViewInfo.CheckState;
end;

function TACLCustomCheckBox.GetStyle: TACLStyleCheckBox;
begin
  Result := TACLStyleCheckBox(inherited Style);
end;

function TACLCustomCheckBox.GetWordWrap: Boolean;
begin
  Result := ViewInfo.WordWrap;
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
  ViewInfo.ShowCheckMark := AValue;
end;

procedure TACLCustomCheckBox.SetShowLine(AValue: Boolean);
begin
  ViewInfo.ShowLine := AValue;
end;

procedure TACLCustomCheckBox.SetState(AValue: TCheckBoxState);
begin
  ViewInfo.CheckState := AValue;
  UpdateSubControlEnabled;
end;

procedure TACLCustomCheckBox.UpdateSubControlEnabled;
begin
  SubControl.Enabled := Enabled and (not ShowCheckMark or Checked);
end;

procedure TACLCustomCheckBox.SetWordWrap(AValue: Boolean);
begin
  ViewInfo.WordWrap := AValue;
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

function TACLInplaceCheckBox.InplaceGetValue: string;
begin
  Result := BoolToStr(Checked, True)
end;

procedure TACLInplaceCheckBox.InplaceSetValue(const AValue: string);
begin
  Caption := AValue;
  Checked := AValue = BoolToStr(True, True);
end;

procedure TACLInplaceCheckBox.SetDefaultSize;
begin
  // do nothing
end;

procedure TACLInplaceCheckBox.CMHitTest(var Message: TWMNCHitTest);
begin
  if PtInRect(ClientRect, SmallPointToPoint(Message.Pos)) then
    Message.Result := HTCLIENT
  else
    Message.Result := HTTRANSPARENT;
end;

{ TACLRadioBox }

function TACLRadioBox.CreateStyle: TACLStyleButton;
begin
  Result := TACLStyleRadioBox.Create(Self);
end;

procedure TACLRadioBox.ToggleState;
begin
  Checked := True;
end;

procedure TACLRadioBox.SetGroupIndex(const Value: Integer);
begin
  if FGroupIndex <> Value then
  begin
    FGroupIndex := Value;
    SetState(State);
  end;
end;

procedure TACLRadioBox.SetState(AValue: TCheckBoxState);
var
  AControl: TControl;
begin
  if State <> AValue then
  begin
    if AValue = cbChecked then
    begin
      if Parent <> nil then
        for var I := 0 to Parent.ControlCount - 1 do
        begin
          AControl := Parent.Controls[I];
          if (AControl is TACLRadioBox) and (AControl <> Self) then
          begin
            if TACLRadioBox(AControl).GroupIndex = GroupIndex then
              TACLRadioBox(AControl).ViewInfo.CheckState := cbUnchecked;
          end;
        end;
    end;
    inherited;
  end;
end;

end.
