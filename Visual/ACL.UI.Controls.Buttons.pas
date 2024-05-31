{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Buttons Controls              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.Buttons;

{$I ACL.Config.inc} // FPC:OK

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
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
  ACL.ObjectLinks,
  ACL.UI.Animation,
  ACL.UI.Controls.BaseControls,
  ACL.UI.ImageList,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware;

const
  DefaultButtonHeight = 25;
  DefaultButtonWidth = 120;

type
  TACLCustomButtonSubClass = class;

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
    procedure Draw(ACanvas: TCanvas; const R: TRect;
      AState: TACLButtonState; APart: TACLButtonPart = abpButton); overload; virtual;
    procedure Draw(ACanvas: TCanvas; const R: TRect;
      AState: TACLButtonState; ACheckBoxState: TCheckBoxState); overload; virtual;
    //
    property ContentOffsets: TRect read GetContentOffsets;
    property TextColors[AState: TACLButtonState]: TColor read GetTextColor;
    // for backward compatibility with scripts
    property TextColor: TACLResourceColor index Ord(absNormal) read GetColor;
    property TextColorDisabled: TACLResourceColor index Ord(absDisabled) read GetColor;
    property TextColorHover: TACLResourceColor index Ord(absHover) read GetColor;
    property TextColorPressed: TACLResourceColor index Ord(absPressed) read GetColor;
  published
    property ColorText: TACLResourceColor index Ord(absNormal) read GetColor write SetColor stored IsColorStored;
    property ColorTextDisabled: TACLResourceColor index Ord(absDisabled) read GetColor write SetColor stored IsColorStored;
    property ColorTextHover: TACLResourceColor index Ord(absHover) read GetColor write SetColor stored IsColorStored;
    property ColorTextPressed: TACLResourceColor index Ord(absPressed) read GetColor write SetColor stored IsColorStored;
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

  { TACLCustomButtonSubClass }

  TACLButtonStateFlag = (bsfPressed, bsfActive, bsfEnabled, bsfFocused, bsfDown, bsfDefault);
  TACLButtonStateFlags = set of TACLButtonStateFlag;

  TACLCustomButtonSubClass = class(TACLUnknownObject,
    IACLAnimateControl,
    IACLObjectLinksSupport)
  strict private
    FBounds: TRect;
    FCaption: string;
    FFlags: TACLButtonStateFlags;
    FOwner: IACLButtonOwner;
    FState: TACLButtonState;
    FTag: Integer;

    FOnClick: TNotifyEvent;

    function GetCurrentDpi: Integer;
    function GetFlag(Index: TACLButtonStateFlag): Boolean;
    function GetFont: TFont;
    function GetStyle: TACLStyleButton;
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
    procedure StateChanged; virtual;
    // Drawing
    function AllowAnimation: Boolean; virtual;
    procedure AssignCanvasParameters(ACanvas: TCanvas); virtual;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); virtual; abstract;
    procedure DrawContent(ACanvas: TCanvas); virtual;
    procedure DrawFocusRect(ACanvas: TCanvas); virtual;
    // IACLAnimateControl
    procedure IACLAnimateControl.Animate = Invalidate;
    //# Properties
    property Flags: TACLButtonStateFlags read FFlags;
    property Owner: IACLButtonOwner read FOwner;
    property Style: TACLStyleButton read GetStyle;
  public
    constructor Create(AOwner: IACLButtonOwner); virtual;
    destructor Destroy; override;
    procedure Calculate(R: TRect); virtual;
    procedure Draw(ACanvas: TCanvas);
    procedure FullRefresh;
    procedure PerformClick; virtual;
    procedure Invalidate;
    // Keyboard
    procedure KeyDown(var Key: Word; Shift: TShiftState); virtual;
    procedure KeyUp(var Key: Word; Shift: TShiftState); virtual;
    // Mouse
    procedure MouseDown(Button: TMouseButton; const P: TPoint);
    procedure MouseMove(Shift: TShiftState; const P: TPoint);
    procedure MouseUp(Button: TMouseButton; const P: TPoint);
    // States
    procedure RefreshState;
    //# Properties
    property Alignment: TAlignment read FAlignment write SetAlignment;
    property Bounds: TRect read FBounds;
    property ButtonRect: TRect read FButtonRect;
    property Caption: string read FCaption write SetCaption;
    property CurrentDpi: Integer read GetCurrentDpi;
    property FocusRect: TRect read FFocusRect;
    property Font: TFont read GetFont;
    property State: TACLButtonState read FState;
    property Tag: Integer read FTag write FTag;
    property TextColor: TColor read GetTextColor;
    property TextRect: TRect read FTextRect;
    property TextureSize: TSize read GetTextureSize;
    property Transparent: Boolean read GetTransparent;
    //# States
    property IsActive: Boolean index bsfActive read GetFlag write SetFlag;
    property IsDefault: Boolean index bsfDefault read GetFlag write SetFlag;
    property IsDown: Boolean index bsfDown read GetFlag write SetFlag;
    property IsEnabled: Boolean index bsfEnabled read GetFlag write SetFlag;
    property IsFocused: Boolean index bsfFocused read GetFlag write SetFlag;
    property IsPressed: Boolean index bsfPressed read GetFlag write SetFlag;
    //# Events
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

  { TACLCustomButton }

  TACLCustomButton = class(TACLCustomControl,
    IACLButtonOwner,
    IACLFocusableControl)
  strict private
    FShowCaption: Boolean;
    FStyle: TACLStyleButton;
    FSubClass: TACLCustomButtonSubClass;

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
    function CreateSubClass: TACLCustomButtonSubClass; virtual; abstract;
    procedure DoGetHint(const P: TPoint; var AHint: string); override;
    procedure FocusChanged; override;
    procedure Paint; override;
    procedure ResourceChanged; override;
    procedure SetTargetDPI(AValue: Integer); override;
    procedure UpdateCaption;
    procedure UpdateTransparency; override;

    // Keyboard
    function DialogChar(var Message: TWMKey): Boolean; override;
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
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFontchanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;

    // Properties
    property SubClass: TACLCustomButtonSubClass read FSubClass;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
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

  TACLButtonSubClass = class(TACLCustomButtonSubClass)
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
    function GetGlyph: TACLGlyph; virtual;
    function GetImages: TCustomImageList; virtual;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); override;
    procedure DrawContent(ACanvas: TCanvas); override;
    //# Properties
    property Glyph: TACLGlyph read GetGlyph;
    property Images: TCustomImageList read GetImages;
    property Part: TACLButtonPart read FPart;
  public
    constructor Create(AOwner: IACLButtonOwner); override;
    procedure Calculate(R: TRect); override;
    //# Properties
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
    FCancel: Boolean;
    FDefault: Boolean;
    FGlyph: TACLGlyph;
    FImageChangeLink: TChangeLink;
    FImageIndex: TImageIndex;
    FImages: TCustomImageList;
    FModalResult: TModalResult;
  {$IFDEF FPC}
    FRolesUpdateLocked: Boolean;
  {$ELSE}
    procedure CMDialogKey(var Message: TCMDialogKey); message CM_DIALOGKEY;
    procedure CMFocusChanged(var Message: TCMFocusChanged); message CM_FOCUSCHANGED;
  {$ENDIF}
    procedure HandlerImageChange(Sender: TObject);
    function IsGlyphStored: Boolean;
    function GetDown: Boolean;
    function GetSubClass: TACLButtonSubClass;
    procedure SetCancel(AValue: Boolean);
    procedure SetDefault(AValue: Boolean);
    procedure SetDown(AValue: Boolean);
    procedure SetGlyph(const Value: TACLGlyph);
    procedure SetImageIndex(AIndex: TImageIndex);
    procedure SetImages(const AList: TCustomImageList);
    procedure UpdateRoles;
  protected
    function CreateStyle: TACLStyleButton; override;
    function CreateSubClass: TACLCustomButtonSubClass; override;
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
    //# Default/Cancel
  {$IFDEF FPC}
    procedure ActiveDefaultControlChanged(NewControl: TControl); override;
    procedure ExecuteCancelAction; override;
    procedure ExecuteDefaultAction; override;
    procedure UpdateRolesForForm; override;
  {$ENDIF}
    //# Properties
    property SubClass: TACLButtonSubClass read GetSubClass;
  published
    property Color;
    property Cancel: Boolean read FCancel write SetCancel default False;
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
    FDropDownSubClass: TACLButtonSubClass;
    FKind: TACLButtonKind;

    FOnDropDownClick: TNotifyEvent;

    procedure HandlerDropDownClick(Sender: TObject);
    procedure SetKind(AValue: TACLButtonKind);
  protected
    procedure Calculate(R: TRect); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure PerformClick; override;
    procedure UpdateTransparency; override;
    // Keyboard
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    // Mouse
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    // Messages
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ShowDropDownMenu;
    //# Properties
    property DropDownSubClass: TACLButtonSubClass read FDropDownSubClass;
  published
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

  { TACLStyleRadioBox }

  TACLStyleRadioBox = class(TACLStyleCheckBox)
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

  TACLCheckBoxSubClass = class(TACLCustomButtonSubClass)
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
    procedure CalculateTextSize(var R: TRect; out ATextSize: TSize); virtual;
    function GetTransparent: Boolean; override;
    procedure DrawBackground(ACanvas: TCanvas; const R: TRect); override;
    procedure DrawContent(ACanvas: TCanvas); override;
  public
    constructor Create(AOwner: IACLButtonOwner); override;
    procedure Calculate(R: TRect); override;
    procedure CalculateAutoSize(var AWidth, AHeight: Integer); virtual;
    //# Properties
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
    function GetSubClass: TACLCheckBoxSubClass;
    function GetWordWrap: Boolean;
    function IsCursorStored: Boolean;
    procedure SetChecked(AValue: Boolean);
    procedure SetShowCheckMark(AValue: Boolean);
    procedure SetShowLine(AValue: Boolean);
    procedure SetStyle(AStyle: TACLStyleCheckBox);
    procedure SetSubControl(AValue: TACLCheckBoxSubControlOptions);
    procedure SetWordWrap(AValue: Boolean);
    // Messages
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
    procedure WMMove(var Message: TMessage); message WM_MOVE;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  protected
    procedure Calculate(R: TRect); override;
    function CreateStyle: TACLStyleButton; override;
    function CreateSubControlOptions: TACLCheckBoxSubControlOptions; virtual;
    function CreateSubClass: TACLCustomButtonSubClass; override;
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
  strict private
    procedure CMHitTest(var Message: TWMNCHitTest); message CM_HITTEST;
  protected
    // IACLInplaceControl
    function InplaceGetValue: string;
    function IACLInplaceControl.InplaceIsFocused = Focused;
    procedure InplaceSetValue(const AValue: string);
    procedure IACLInplaceControl.InplaceSetFocus = SetFocus;
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
begin
  Texture.Draw(ACanvas, R, Ord(APart) * 5 + Ord(AState));
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

{ TACLCustomButtonSubClass }

constructor TACLCustomButtonSubClass.Create(AOwner: IACLButtonOwner);
begin
  inherited Create;
  FOwner := AOwner;
  FAlignment := taCenter;
  FFlags := [bsfEnabled];
end;

destructor TACLCustomButtonSubClass.Destroy;
begin
  AnimationManager.RemoveOwner(Self);
  TACLObjectLinks.Release(Self);
  inherited Destroy;
end;

procedure TACLCustomButtonSubClass.Calculate(R: TRect);
begin
  FBounds := R;
  FButtonRect := R;
end;

procedure TACLCustomButtonSubClass.Draw(ACanvas: TCanvas);
var
  AClipRgn: TRegionHandle;
begin
  if acRectVisible(ACanvas, Bounds) then
  begin
    ACanvas.Font := Font;
    AClipRgn := acSaveClipRegion(ACanvas.Handle);
    try
      acIntersectClipRegion(ACanvas.Handle, Bounds);
      if not AnimationManager.Draw(Self, ACanvas, ButtonRect) then
        DrawBackground(ACanvas, ButtonRect);
      if IsFocused then
        DrawFocusRect(ACanvas);
      DrawContent(ACanvas);
    finally
      acRestoreClipRegion(ACanvas.Handle, AClipRgn);
    end;
  end;
end;

procedure TACLCustomButtonSubClass.FullRefresh;
begin
  Owner.ButtonOwnerRecalculate;
  Invalidate;
end;

procedure TACLCustomButtonSubClass.Invalidate;
begin
  Owner.InvalidateRect(Bounds);
end;

procedure TACLCustomButtonSubClass.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
    IsPressed := True;
end;

procedure TACLCustomButtonSubClass.KeyUp(var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      IsPressed := False;

    VK_SPACE:
      if IsPressed then
      try
        PerformClick;
      finally
        IsPressed := False;
      end;
  end;
end;

procedure TACLCustomButtonSubClass.MouseDown(Button: TMouseButton; const P: TPoint);
begin
  IsPressed := IsEnabled and PtInRect(Bounds, P) and (Button = mbLeft);
end;

procedure TACLCustomButtonSubClass.MouseMove(Shift: TShiftState; const P: TPoint);
begin
  IsActive := IsEnabled and PtInRect(Bounds, P) and not (ssLeft in Shift);
end;

procedure TACLCustomButtonSubClass.MouseUp(Button: TMouseButton; const P: TPoint);
var
  ALink: TObject;
begin
  TACLObjectLinks.RegisterWeakReference(Self, @ALink);
  try
    if (Button = mbLeft) and IsPressed then
    begin
      if PtInRect(Bounds, P) then
        PerformClick;
    end;
  finally
    if ALink <> nil then
      IsPressed := False;
    TACLObjectLinks.UnregisterWeakReference(@ALink);
  end;
end;

procedure TACLCustomButtonSubClass.PerformClick;
begin
  CallNotifyEvent(Self, OnClick);
end;

procedure TACLCustomButtonSubClass.RefreshState;
var
  AAnimator: TACLCustomBitmapAnimation;
  ANewState: TACLButtonState;
begin
  ANewState := CalculateState;
  if ANewState <> FState then
  begin
    if AllowAnimation and not ButtonRect.IsEmpty and
      (FState = absHover) and (ANewState in [absActive, absNormal]) then
    begin
      AAnimator := TACLBitmapFadingAnimation.Create(Self, acUIFadingTime);
      AAnimator.AllocateFrame1(ButtonRect, DrawBackground);
      FState := ANewState;
      AAnimator.AllocateFrame2(ButtonRect, DrawBackground);
      AAnimator.Run;
    end;
    FState := ANewState;
    StateChanged;
    Invalidate;
  end;
end;

function TACLCustomButtonSubClass.CalculateState: TACLButtonState;
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

function TACLCustomButtonSubClass.GetFont: TFont;
begin
  Result := Owner.ButtonOwnerGetFont;
end;

function TACLCustomButtonSubClass.GetIndentBetweenElements: Integer;
begin
  Result := dpiApply(acIndentBetweenElements, CurrentDpi);
end;

function TACLCustomButtonSubClass.GetTextColor: TColor;
begin
  Result := Style.TextColors[State];
end;

function TACLCustomButtonSubClass.GetTransparent: Boolean;
begin
  Result := Style.Texture.HasAlpha;
end;

procedure TACLCustomButtonSubClass.StateChanged;
begin
  // do nothing
end;

function TACLCustomButtonSubClass.AllowAnimation: Boolean;
begin
  Result := True;
end;

procedure TACLCustomButtonSubClass.AssignCanvasParameters(ACanvas: TCanvas);
begin
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Font.Color := TextColor;
  ACanvas.Brush.Style := bsClear;
end;

procedure TACLCustomButtonSubClass.DrawContent(ACanvas: TCanvas);
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

procedure TACLCustomButtonSubClass.DrawFocusRect(ACanvas: TCanvas);
begin
  acDrawFocusRect(ACanvas, FocusRect, TextColor);
end;

function TACLCustomButtonSubClass.GetCurrentDpi: Integer;
begin
  Result := Owner.GetCurrentDpi;
end;

function TACLCustomButtonSubClass.GetFlag(Index: TACLButtonStateFlag): Boolean;
begin
  Result := Index in FFlags;
end;

function TACLCustomButtonSubClass.GetStyle: TACLStyleButton;
begin
  Result := Owner.ButtonOwnerGetStyle;
end;

function TACLCustomButtonSubClass.GetTextureSize: TSize;
begin
  Result := Style.Texture.FrameSize;
end;

procedure TACLCustomButtonSubClass.SetAlignment(AValue: TAlignment);
begin
  if AValue <> FAlignment then
  begin
    FAlignment := AValue;
    FullRefresh;
  end;
end;

procedure TACLCustomButtonSubClass.SetCaption(const AValue: string);
begin
  if AValue <> FCaption then
  begin
    FCaption := AValue;
    FullRefresh;
  end;
end;

procedure TACLCustomButtonSubClass.SetFlag(AFlag: TACLButtonStateFlag; AValue: Boolean);
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
  Cursor := crHandPoint;
  FocusOnClick := True;
  DoubleBuffered := True;
  TabStop := True;
  ControlStyle := ControlStyle - [csDoubleClicks, csClickEvents];
  FDefaultSize := TSize.Create(DefaultButtonWidth, DefaultButtonHeight);
  FSubClass := CreateSubClass;
  FSubClass.OnClick := ButtonClickHandler;
  FShowCaption := True;
  FStyle := CreateStyle;
end;

destructor TACLCustomButton.Destroy;
begin
  FreeAndNil(FSubClass);
  FreeAndNil(FStyle);
  inherited Destroy;
end;

procedure TACLCustomButton.DoGetHint(const P: TPoint; var AHint: string);
begin
  if not ShowCaption and (AHint = '') then
    AHint := Caption;
  inherited;
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
  if SubClass <> nil then
    Calculate(ClientRect);
end;

procedure TACLCustomButton.Calculate(R: TRect);
begin
  SubClass.Calculate(R);
end;

procedure TACLCustomButton.SetTargetDPI(AValue: Integer);
begin
  inherited;
  Style.SetTargetDPI(AValue);
end;

procedure TACLCustomButton.FocusChanged;
begin
  inherited FocusChanged;
  if not (csDesigning in ComponentState) then
  begin
    SubClass.IsFocused := Focused;
    SubClass.Invalidate;
  end;
end;

procedure TACLCustomButton.Paint;
begin
  SubClass.Draw(Canvas);
end;

procedure TACLCustomButton.ResourceChanged;
begin
  inherited;
  FullRefresh;
end;

procedure TACLCustomButton.UpdateCaption;
begin
  SubClass.Caption := IfThenW(ShowCaption, Caption);
end;

procedure TACLCustomButton.UpdateTransparency;
begin
  if SubClass.Transparent then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque];
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

procedure TACLCustomButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  SubClass.KeyDown(Key, Shift);
end;

procedure TACLCustomButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  SubClass.KeyUp(Key, Shift);
end;

procedure TACLCustomButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  SubClass.MouseDown(Button, Point(X, Y));
end;

procedure TACLCustomButton.MouseEnter;
begin
  inherited MouseEnter;
  Invalidate;
end;

procedure TACLCustomButton.MouseLeave;
begin
  inherited MouseLeave;
  SubClass.MouseMove([], InvalidPoint);
  SubClass.Invalidate;
end;

procedure TACLCustomButton.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  SubClass.MouseMove(Shift, Point(X, Y));
end;

procedure TACLCustomButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  SubClass.MouseUp(Button, Point(X, Y));
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

procedure TACLCustomButton.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  SubClass.IsEnabled := Enabled;
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
  inherited;
  UpdateCaption;
end;

procedure TACLCustomButton.ButtonClickHandler(Sender: TObject);
begin
  Click;
end;

function TACLCustomButton.GetAlignment: TAlignment;
begin
  Result := SubClass.Alignment;
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
    UpdateCaption;
  end;
end;

procedure TACLCustomButton.SetStyle(const Value: TACLStyleButton);
begin
  FStyle.Assign(Value);
end;

{ TACLButtonSubClass }

procedure TACLButtonSubClass.Calculate(R: TRect);
begin
  inherited;
  FButtonRect := R;
  R.Content(Style.ContentOffsets);
  FFocusRect := R;
  R.Inflate(-1);
  CalculateArrowRect(R);
  CalculateImageRect(R);
  CalculateTextRect(R);
end;

procedure TACLButtonSubClass.CalculateArrowRect(var R: TRect);
begin
  if HasArrow then
  begin
    FArrowRect := R;
    if Part <> abpDropDownArrow then
    begin
      FArrowRect.Right := FArrowRect.Right - GetIndentBetweenElements;
      FArrowRect.Left := FArrowRect.Right - dpiApply(acDropArrowSize.cx, CurrentDpi);
    end;
    R.Right := FArrowRect.Left - GetIndentBetweenElements;
  end;
end;

procedure TACLButtonSubClass.CalculateImageRect(var R: TRect);
var
  LImageSize: TSize;
begin
  if HasImage then
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
end;

procedure TACLButtonSubClass.CalculateTextRect(var R: TRect);
begin
  FTextRect := R;
  FTextRect.Inflate(-dpiApply(acTextIndent - 1, CurrentDpi), 0);
end;

constructor TACLButtonSubClass.Create(AOwner: IACLButtonOwner);
begin
  inherited;
  FImageIndex := -1;
end;

function TACLButtonSubClass.GetGlyph: TACLGlyph;
var
  AIntf: IACLGlyph;
begin
  if Supports(Owner, IACLGlyph, AIntf) then
    Result := AIntf.GetGlyph
  else
    Result := nil;
end;

function TACLButtonSubClass.GetImages: TCustomImageList;
begin
  Result := Owner.ButtonOwnerGetImages;
end;

procedure TACLButtonSubClass.DrawBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.Draw(ACanvas, R, State, Part);
end;

procedure TACLButtonSubClass.DrawContent(ACanvas: TCanvas);
begin
  inherited DrawContent(ACanvas);

  if FHasArrow then
    acDrawDropArrow(ACanvas.Handle, ArrowRect, TextColor, dpiApply(acDropArrowSize, CurrentDpi));

  if not ImageRect.IsEmpty then
  begin
    if Glyph <> nil then
      Glyph.Draw(ACanvas, ImageRect, IsEnabled)
    else
      acDrawImage(ACanvas, ImageRect, Images, ImageIndex, IsEnabled);
  end;
end;

function TACLButtonSubClass.GetHasImage: Boolean;
begin
  Result := (Part <> abpDropDownArrow) and
    ((Images <> nil) and (ImageIndex >= 0) or (Glyph <> nil));
end;

function TACLButtonSubClass.GetImageSize: TSize;
begin
  if Glyph <> nil then
    Result := Glyph.FrameSize
  else
    Result := acGetImageListSize(Images, CurrentDpi);
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
  if Cancel then Click;
end;

procedure TACLSimpleButton.ExecuteDefaultAction;
begin
  if Default or SubClass.IsDefault then Click;
end;

procedure TACLSimpleButton.UpdateRolesForForm;
var
  AForm: TCustomForm;
begin
  if FRolesUpdateLocked then
    Exit;
  AForm := GetParentForm(Self);
  if AForm <> nil then
    Default := crffDefault in AForm.GetRolesForControl(Self);
end;

{$ELSE}

procedure TACLSimpleButton.CMDialogKey(var Message: TCMDialogKey);
begin
  if (Message.CharCode = VK_RETURN) and SubClass.IsDefault or
     (Message.CharCode = VK_ESCAPE) and Cancel
  then
    if (KeyDataToShiftState(Message.KeyData) = []) and CanFocus then
    begin
      SubClass.PerformClick;
      Message.Result := 1;
      Exit;
    end;

  inherited;
end;

procedure TACLSimpleButton.CMFocusChanged(var Message: TCMFocusChanged);
begin
  if Message.Sender is TACLSimpleButton then
    SubClass.IsDefault := Default and (Message.Sender = Self)
  else
    SubClass.IsDefault := Default;

  inherited;
end;
{$ENDIF}

function TACLSimpleButton.CreateStyle: TACLStyleButton;
begin
  Result := TACLStyleButton.Create(Self);
end;

function TACLSimpleButton.CreateSubClass: TACLCustomButtonSubClass;
begin
  Result := TACLButtonSubClass.Create(Self);
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
  FullRefresh;
end;

{ TACLButton }

constructor TACLButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDropDownSubClass := TACLButtonSubClass.Create(Self);
  FDropDownSubClass.OnClick := HandlerDropDownClick;
  FDropDownSubClass.FPart := abpDropDownArrow;
end;

destructor TACLButton.Destroy;
begin
  FreeAndNil(FDropDownSubClass);
  inherited Destroy;
end;

procedure TACLButton.Calculate(R: TRect);
const
  PartMap: array [Boolean] of TACLButtonPart = (abpButton, abpDropDown);
var
  DR: TRect;
begin
  DR := R.Split(srRight, IfThen(Kind = sbkDropDownButton, DropDownSubClass.TextureSize.cx));
  R.Right := DR.Left;

  DropDownSubClass.HasArrow := True;
  DropDownSubClass.Calculate(DR);

  SubClass.ImageIndex := ImageIndex;
  SubClass.HasArrow := Kind = sbkDropDown;
  SubClass.FPart := PartMap[Kind = sbkDropDownButton];
  SubClass.Calculate(R);
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
  DropDownSubClass.Draw(Canvas);
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

procedure TACLButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  if (Kind = sbkDropDownButton) and acIsDropDownCommand(Key, Shift) then
  begin
    DropDownSubClass.IsPressed := True;
    DropDownSubClass.PerformClick;
    DropDownSubClass.IsPressed := False;
  end
end;

procedure TACLButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  DropDownSubClass.MouseDown(Button, Point(X, Y));
end;

procedure TACLButton.MouseLeave;
begin
  inherited MouseLeave;
  DropDownSubClass.MouseMove([], InvalidPoint);
end;

procedure TACLButton.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  DropDownSubClass.MouseMove(Shift, Point(X, Y));
end;

procedure TACLButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  DropDownSubClass.MouseUp(Button, Point(X, Y));
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
  DropDownSubClass.IsEnabled := Enabled;
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
    AIndent := Owner.SubClass.TextureSize.cx + Owner.SubClass.GetIndentBetweenElements;
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

{ TACLCheckBoxSubClass }

constructor TACLCheckBoxSubClass.Create(AOwner: IACLButtonOwner);
begin
  inherited Create(AOwner);
  FAlignment := taLeftJustify;
  FShowCheckMark := True;
end;

procedure TACLCheckBoxSubClass.Calculate(R: TRect);
begin
  inherited Calculate(R);
  CalculateButtonRect(R);
  CalculateTextRect(R);
  CalculateLineRect(R);
end;

procedure TACLCheckBoxSubClass.CalculateAutoSize(var AWidth, AHeight: Integer);
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

procedure TACLCheckBoxSubClass.CalculateButtonRect(var R: TRect);
var
  ASize: TSize;
begin
  if ShowCheckMark then
  begin
    ASize := TextureSize;
    FButtonRect := R;
    FButtonRect.Width := ASize.cx;
    if WordWrap then
    begin
      FButtonRect.Top := R.Top + acFocusRectIndent;
      FButtonRect.Height := ASize.cy;
    end
    else
      FButtonRect.Center(ASize);

    R.Left := FButtonRect.Right + GetIndentBetweenElements - acTextIndent;
  end
  else
    FButtonRect := NullRect;
end;

procedure TACLCheckBoxSubClass.CalculateLineRect(var R: TRect);
begin
  if ShowLine then
  begin
    if Odd(R.Height) then
      Inc(R.Bottom);
    FLineRect := R;
    FLineRect.CenterVert(2);
  end
  else
    FLineRect := NullRect;
end;

procedure TACLCheckBoxSubClass.CalculateTextRect(var R: TRect);
var
  LTextWidth: Integer;
begin
  CalculateTextSize(R, FTextSize);

  FTextRect := R;
  LTextWidth := Min(FTextSize.cx, R.Width);
  case Alignment of
    taCenter:
      FTextRect.CenterHorz(LTextWidth);
    taRightJustify:
      FTextRect.Left := FTextRect.Right - LTextWidth;
  else
    FTextRect.Width := LTextWidth;
  end;

  FTextRect.CenterVert(FTextSize.cy);
  FTextRect.Offset(0, -1);

  if TextRect.IsEmpty or (Caption = '') then
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
end;

procedure TACLCheckBoxSubClass.CalculateTextSize(var R: TRect; out ATextSize: TSize);
var
  ATextRect: TRect;
begin
  MeasureCanvas.Font := Font;
  if ShowCheckMark then
    R.Inflate(-acTextIndent, -acFocusRectIndent);

  ATextRect := R;
  acSysDrawText(MeasureCanvas, ATextRect, Caption, DT_CALCRECT or IfThen(WordWrap, DT_WORDBREAK));
  ATextSize := ATextRect.Size;

  if WordWrap or (FTextSize.cy = 0) then
    ATextSize.cy := Max(ATextSize.cy, acFontHeight(MeasureCanvas));
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
    acSysDrawText(ACanvas, FTextRect, Caption, DT_END_ELLIPSIS or DT_NOPREFIX or
      DT_VCENTER or acTextAlignHorz[Alignment] or IfThen(WordWrap, DT_WORDBREAK));
  end;
  if ShowLine then
    acDrawLabelLine(ACanvas, FLineRect, TextRect, Style.ColorLine1.Value, Style.ColorLine2.Value);
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
    FullRefresh;
  end;
end;

procedure TACLCheckBoxSubClass.SetShowLine(AValue: Boolean);
begin
  if AValue <> FShowLine then
  begin
    if AValue then
      FWordWrap := False;
    FShowLine := AValue;
    FullRefresh;
  end;
end;

procedure TACLCheckBoxSubClass.SetWordWrap(AValue: Boolean);
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
  SubClass.Calculate(R);
end;

function TACLCustomCheckBox.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  NewHeight := -1;
  if (Align in [alNone, alLeft, alRight]) and not (WordWrap or ShowLine) then
    NewWidth := -1;
  SubControl.BeforeAutoSize(NewWidth, NewHeight);
  SubClass.CalculateAutoSize(NewWidth, NewHeight);
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

function TACLCustomCheckBox.CreateSubClass: TACLCustomButtonSubClass;
begin
  Result := TACLCheckBoxSubClass.Create(Self);
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
    PtInRect(SubClass.LineRect, P));
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

function TACLInplaceCheckBox.InplaceGetValue: string;
begin
  Result := BoolToStr(Checked, True)
end;

procedure TACLInplaceCheckBox.InplaceSetValue(const AValue: string);
begin
  Checked := (AValue = BoolToStr(True, True)) or (StrToIntDef(AValue, 0) <> 0);
  Caption := InplaceGetValue;
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
  I: Integer;
begin
  if State <> AValue then
  begin
    if AValue = cbChecked then
    begin
      if Parent <> nil then
        for I := 0 to Parent.ControlCount - 1 do
        begin
          AControl := Parent.Controls[I];
          if (AControl is TACLRadioBox) and (AControl <> Self) then
          begin
            if TACLRadioBox(AControl).GroupIndex = GroupIndex then
            begin
              TACLRadioBox(AControl).SubClass.CheckState := cbUnchecked;
              TACLRadioBox(AControl).UpdateSubControlEnabled;
            end;
          end;
        end;
    end;
    inherited;
  end;
end;

end.
