{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*          Binding Diagram Control          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.BindingDiagram.SubClass;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.Types,
  System.SysUtils,
  System.Classes,
  // VCL
  Vcl.Graphics,
  Vcl.Controls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Gdiplus,
  ACL.Math,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.CompoundControl.SubClass.Scrollbox,
  ACL.UI.Controls.BindingDiagram.Types,
  ACL.UI.Forms,
  ACL.UI.HintWindow,
  ACL.UI.Resources,
  ACL.UI.Controls.ScrollBox,
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

const
  htObjectRemoveButton = -1;

type
  TACLBindingDiagramSubClass = class;
  TACLBindingDiagramSubClassViewInfo = class;
  TACLBindingDiagramLinkViewInfo = class;

  { TACLStyleBindingDiagram }

  TACLStyleBindingDiagram = class(TACLStyleContent)
  strict private const
    SelectionSize = 2;
  protected
    procedure InitializeResources; override;
  public
    procedure DrawObjectBorders(ACanvas: TCanvas; const R: TRect);
    procedure DrawSelection(ACanvas: TCanvas; const R: TRect);
  published
    property ColorObjectBorder: TACLResourceColor index 10 read GetColor write SetColor stored IsColorStored;
    property ColorObjectCaption: TACLResourceColor index 11 read GetColor write SetColor stored IsColorStored;
    property ColorObjectCaptionText: TACLResourceColor index 12 read GetColor write SetColor stored IsColorStored;
    property ColorObjectContent: TACLResourceColor index 13 read GetColor write SetColor stored IsColorStored;
    property ColorObjectDragHighlight: TACLResourceColor index 14 read GetColor write SetColor stored IsColorStored;
    property ColorObjectSelection: TACLResourceColor index 15 read GetColor write SetColor stored IsColorStored;
    property ColorLinkBaseColor: TACLResourceColor index 16 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLBindingDiagramCustomOptions }

  TACLBindingDiagramCustomOptions = class(TACLCustomOptionsPersistent)
  protected
    FDiagram: TACLBindingDiagramSubClass;

    procedure DoChanged(AChanges: TACLPersistentChanges); override;
  public
    constructor Create(ADiagram: TACLBindingDiagramSubClass); virtual;
  end;

  { TACLBindingDiagramOptionsBehavior }

  TACLBindingDiagramOptionsBehavior = class(TACLBindingDiagramCustomOptions)
  strict private
    FAllowCreateLinks: Boolean;
    FAllowDeleteLinks: Boolean;
    FAllowDeleteObjects: Boolean;
    FAllowEditLinks: Boolean;
    FAllowMoveObjects: Boolean;
  protected
    procedure DoAssign(Source: TPersistent); override;
  public
    procedure AfterConstruction; override;
  published
    property AllowCreateLinks: Boolean read FAllowCreateLinks write FAllowCreateLinks default True;
    property AllowDeleteLinks: Boolean read FAllowDeleteLinks write FAllowDeleteLinks default True;
    property AllowDeleteObjects: Boolean read FAllowDeleteObjects write FAllowDeleteObjects default True;
    property AllowEditLinks: Boolean read FAllowEditLinks write FAllowEditLinks default True;
    property AllowMoveObjects: Boolean read FAllowMoveObjects write FAllowMoveObjects default True;
  end;

  { TACLBindingDiagramOptionsView }

  TACLBindingDiagramOptionsView = class(TACLBindingDiagramCustomOptions)
  strict private
    FCardWidth: Integer;
    FRowHeight: Integer;
    FShowCaption: Boolean;

    procedure SetCardWidth(AValue: Integer);
    procedure SetRowHeight(AValue: Integer);
    procedure SetShowCaption(AValue: Boolean);
  protected
    procedure DoAssign(Source: TPersistent); override;
  public
    procedure AfterConstruction; override;
  published
    property CardWidth: Integer read FCardWidth write SetCardWidth default 0;
    property RowHeight: Integer read FRowHeight write SetRowHeight default 0;
    property ShowCaption: Boolean read FShowCaption write SetShowCaption default True;
  end;

  { TACLBindingDiagram }

  TACLBindingDiagramLinkAcceptEvent = procedure (Sender: TObject; ALink: TACLBindingDiagramLink; var AAccept: Boolean) of object;
  TACLBindingDiagramLinkChangingEvent = procedure (Sender: TObject; ALink: TACLBindingDiagramLink;
    ASourcePin, ATargetPin: TACLBindingDiagramObjectPin; var AAccept: Boolean) of object;
  TACLBindingDiagramLinkCreatingEvent = procedure (Sender: TObject;
    ASourcePin, ATargetPin: TACLBindingDiagramObjectPin; var AAccept: Boolean) of object;
  TACLBindingDiagramLinkNotifyEvent = procedure (Sender: TObject; ALink: TACLBindingDiagramLink) of object;
  TACLBindingDiagramObjectAcceptEvent = procedure (Sender: TObject; AObject: TACLBindingDiagramObject; var AAccept: Boolean) of object;

  { TACLBindingDiagramSubClass }

  TACLBindingDiagramSubClass = class(TACLCompoundControlSubClass)
  strict private
    FCaptionFont: TFont;
    FData: TACLBindingDiagramData;
    FOptionsBehavior: TACLBindingDiagramOptionsBehavior;
    FOptionsView: TACLBindingDiagramOptionsView;
    FSelectedObject: TObject;
    FStyle: TACLStyleBindingDiagram;

    FOnLinkChanged: TACLBindingDiagramLinkNotifyEvent;
    FOnLinkChanging: TACLBindingDiagramLinkChangingEvent;
    FOnLinkCreated: TACLBindingDiagramLinkNotifyEvent;
    FOnLinkCreating: TACLBindingDiagramLinkCreatingEvent;
    FOnLinkRemoving: TACLBindingDiagramLinkAcceptEvent;
    FOnObjectRemoving: TACLBindingDiagramObjectAcceptEvent;
    FOnSelectionChanged: TNotifyEvent;

    function GetViewInfo: TACLBindingDiagramSubClassViewInfo;
    procedure HandlerObjectsChanged(Sender: TObject; AChanges: TACLPersistentChanges);
    procedure SetSelectedObject(const Value: TObject);
  protected
    function CreateViewInfo: TACLCompoundControlSubClassCustomViewInfo; override;
    function DoLinkChanging(ALink: TACLBindingDiagramLink; ASourcePin, ATargetPin: TACLBindingDiagramObjectPin): Boolean; virtual;
    procedure DoLinkChanged(ALink: TACLBindingDiagramLink); virtual;
    function DoLinkCreating(ASourcePin, ATargetPin: TACLBindingDiagramObjectPin): Boolean; virtual;
    procedure DoLinkCreated(ALink: TACLBindingDiagramLink); virtual;
    procedure DoSelectionChanged; virtual;
    procedure DoDragStarted; override;
    procedure DoHoveredObjectChanged; override;
    procedure ProcessChanges(AChanges: TIntegerSet); override;
    procedure ProcessKeyUp(AKey: Word; AShift: TShiftState); override;
    procedure ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState); override;
    procedure ResourceChanged; override;
    procedure UpdateFonts;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RemoveLink(ALink: TACLBindingDiagramLink);
    procedure RemoveObject(AObject: TACLBindingDiagramObject);
    procedure RemoveSelected;
    //
    property CaptionFont: TFont read FCaptionFont;
    property Data: TACLBindingDiagramData read FData;
    property OptionsBehavior: TACLBindingDiagramOptionsBehavior read FOptionsBehavior;
    property OptionsView: TACLBindingDiagramOptionsView read FOptionsView;
    property SelectedObject: TObject read FSelectedObject write SetSelectedObject;
    property Style: TACLStyleBindingDiagram read FStyle;
    property ViewInfo: TACLBindingDiagramSubClassViewInfo read GetViewInfo;
    //
    property OnLinkChanged: TACLBindingDiagramLinkNotifyEvent read FOnLinkChanged write FOnLinkChanged;
    property OnLinkChanging: TACLBindingDiagramLinkChangingEvent read FOnLinkChanging write FOnLinkChanging;
    property OnLinkCreated: TACLBindingDiagramLinkNotifyEvent read FOnLinkCreated write FOnLinkCreated;
    property OnLinkCreating: TACLBindingDiagramLinkCreatingEvent read FOnLinkCreating write FOnLinkCreating;
    property OnLinkRemoving: TACLBindingDiagramLinkAcceptEvent read FOnLinkRemoving write FOnLinkRemoving;
    property OnObjectRemoving: TACLBindingDiagramObjectAcceptEvent read FOnObjectRemoving write FOnObjectRemoving;
    property OnSelectionChanged: TNotifyEvent read FOnSelectionChanged write FOnSelectionChanged;
  end;

  { TACLBindingDiagramObjectDragObject }

  TACLBindingDiagramObjectDragObject = class(TACLCompoundControlSubClassDragObject)
  strict private
    FObject: TACLBindingDiagramObject;
  public
    constructor Create(AObject: TACLBindingDiagramObject);
    function DragStart: Boolean; override;
    procedure DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer); override;
    procedure DragFinished(ACanceled: Boolean); override;
  end;

  { TACLBindingDiagramObjectViewInfo }

  TACLBindingDiagramObjectViewInfo = class(TACLCompoundControlSubClassContainerViewInfo,
    IACLDraggableObject)
  protected const
    BorderWidth = 2;
  strict private
    FCaptionRect: TRect;
    FCaptionSize: TSize;
    FObject: TACLBindingDiagramObject;
    FOwner: TACLBindingDiagramSubClassViewInfo;
    FRemoveButtonRect: TRect;

    function HasRemoveButton: Boolean;
    function GetBorderBounds: TRect;
    function GetCaptionTextRect: TRect;
    function GetContentRect: TRect;
    function GetStyle: TACLStyleBindingDiagram; inline;
    function GetSubClass: TACLBindingDiagramSubClass; inline;
  protected
    function CalculateCaptionSize: TSize;
    procedure CalculateSubCells(const AChanges: TIntegerSet); override;
    procedure DoCalculateHitTest(const AHitTest: TACLHitTestInfo); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure DoDrawBorders(ACanvas: TCanvas);
    procedure DoDrawCaption(ACanvas: TCanvas);
    procedure FlushCache; inline;
    procedure RecreateSubCells; override;
    // IACLDraggableObject
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
  public
    constructor Create(AOwner: TACLBindingDiagramSubClassViewInfo; AObject: TACLBindingDiagramObject); reintroduce;
    function IsSelected: Boolean;
    function MeasureSize: TSize;
    //
    property &Object: TACLBindingDiagramObject read FObject;
    property BorderBounds: TRect read GetBorderBounds;
    property CaptionRect: TRect read FCaptionRect;
    property CaptionTextRect: TRect read GetCaptionTextRect;
    property RemoveButtonRect: TRect read FRemoveButtonRect;
    property ContentRect: TRect read GetContentRect;
    property Owner: TACLBindingDiagramSubClassViewInfo read FOwner;
    property Style: TACLStyleBindingDiagram read GetStyle;
    property SubClass: TACLBindingDiagramSubClass read GetSubClass;
  end;

  { TACLBindingDiagramObjectPinViewInfo }

  TACLBindingDiagramObjectPinViewInfo = class(TACLCompoundControlSubClassCustomViewInfo,
    IACLDraggableObject)
  strict private
    FInputConnectorRect: TRect;
    FLinks: TList;
    FOutputConnectorRect: TRect;
    FOwner: TACLBindingDiagramObjectViewInfo;
    FPin: TACLBindingDiagramObjectPin;

    function GetInputConnectorHitTestRect: TRect;
    function GetOutputConnectorHitTestRect: TRect;
    function GetTextRect: TRect;
  protected const
    ConnectorHitTestSize = 6;
    ConnectorSize = 2;
  protected
    FHighlightedConnectors: TACLBindingDiagramObjectPinModes;

    procedure AddLink(ALink: TACLBindingDiagramLinkViewInfo);
    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    procedure DoDrawBackground(ACanvas: TCanvas);
    procedure DoDrawConnector(ACanvas: TCanvas; const R: TRect; AMode: TACLBindingDiagramObjectPinMode);
    // IACLDraggableObject
    function CreateDragObject(const AInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
  public
    constructor Create(AOwner: TACLBindingDiagramObjectViewInfo; APin: TACLBindingDiagramObjectPin); reintroduce;
    destructor Destroy; override;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; override;
    function MeasureSize: TSize;
    //
    property InputConnectorHitTestRect: TRect read GetInputConnectorHitTestRect;
    property InputConnectorRect: TRect read FInputConnectorRect;
    property OutputConnectorHitTestRect: TRect read GetOutputConnectorHitTestRect;
    property OutputConnectorRect: TRect read FOutputConnectorRect;
    property Owner: TACLBindingDiagramObjectViewInfo read FOwner;
    property Pin: TACLBindingDiagramObjectPin read FPin;
    property TextRect: TRect read GetTextRect;
  end;

  { TACLBindingDiagramLinkCustomPathBuilder }

  TACLBindingDiagramLinkCustomPathBuilder = class
  protected
    procedure AddPoint(APoints: TACLList<TPoint>; const P: TPoint); inline;
  public
    procedure Build(APoints: TACLList<TPoint>; ASource, ATarget: TACLBindingDiagramObjectPinViewInfo); virtual; abstract;
    procedure Initialize(AViewInfo: TACLBindingDiagramSubClassViewInfo); virtual; abstract;
  end;

  { TACLBindingDiagramComplexPathBuilder }

  TACLBindingDiagramComplexPathBuilder = class(TACLBindingDiagramLinkCustomPathBuilder)
  strict private const
    ID_EMPTY = 0;
    ID_OBJECT = -1;
  protected
    Columns: TACLList<Integer>;
    Matrix: array of array of Integer;
    Rows: TACLList<Integer>;

    procedure Add(const AObjectViewInfo: TACLBindingDiagramObjectViewInfo); overload;
    procedure Add(const R: TRect); overload;
    procedure Clean;
    function CheckBounds(X, Y: Integer): Boolean; inline;
    function IndexToPoint(X, Y: Integer): TPoint;
    procedure MarkObject(R: TRect);
    function MarkPath(X, Y, Level: Integer): Boolean; inline;
    function RectToIndexes(const R: TRect): TRect;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Build(APoints: TACLList<TPoint>; ASource, ATarget: TACLBindingDiagramObjectPinViewInfo); override;
    procedure Initialize(AViewInfo: TACLBindingDiagramSubClassViewInfo); override;
  end;

  { TACLBindingDiagramSimplePathBuilder }

  TACLBindingDiagramSimplePathBuilder = class(TACLBindingDiagramComplexPathBuilder)
  public
    procedure Build(APoints: TACLList<TPoint>; ASource, ATarget: TACLBindingDiagramObjectPinViewInfo); override;
    procedure Initialize(AViewInfo: TACLBindingDiagramSubClassViewInfo); override;
  end;

  { TACLBindingDiagramCustomLinkDragObject }

  TACLBindingDiagramCustomLinkDragObject = class(TACLCompoundControlSubClassDragObject)
  strict private
    FLineFinish: TPoint;
    FLineStart: TPoint;

    function GetPoint(APinViewInfo: TACLBindingDiagramObjectPinViewInfo; AMode: TACLBindingDiagramObjectPinMode): TPoint;
    function GetStyle: TACLStyleBindingDiagram;
    function GetSubClass: TACLBindingDiagramSubClass;
    function GetViewOrigin: TPoint;
  protected
    FStartPin: TACLBindingDiagramObjectPinViewInfo;
    FStartPinMode: TACLBindingDiagramObjectPinMode;
    FTargetPin: TACLBindingDiagramObjectPinViewInfo;
    FTargetPinMode: TACLBindingDiagramObjectPinMode;

    function CanLinkTo(APinViewInfo: TACLBindingDiagramObjectPinViewInfo): Boolean; virtual;
    procedure LinkObjects(ASourcePin, ATargetPin: TACLBindingDiagramObjectPin); virtual; abstract;
    procedure SetLine(const P1, P2: TPoint);
    procedure SetTargetPin(AValue: TACLBindingDiagramObjectPinViewInfo);
  public
    function DragStart: Boolean; override;
    procedure DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer); override;
    procedure DragFinished(ACanceled: Boolean); override;
    procedure Draw(ACanvas: TCanvas); override;
    //
    property Style: TACLStyleBindingDiagram read GetStyle;
    property SubClass: TACLBindingDiagramSubClass read GetSubClass;
    property TargetPin: TACLBindingDiagramObjectPinViewInfo read FTargetPin write SetTargetPin;
    property ViewOrigin: TPoint read GetViewOrigin;
  end;

  { TACLBindingDiagramLinkViewInfo }

  TACLBindingDiagramLinkViewInfo = class(TACLCompoundControlSubClassCustomViewInfo,
    IACLDraggableObject)
  public const
    ArrowSize = 3;
    HitTestSize = 6;
  protected
    FArrowInput: array[0..3] of TPoint;
    FArrowInputVisible: Boolean;
    FArrowOutput: array[0..3] of TPoint;
    FArrowOutputVisible: Boolean;
    FColor: TColor;
    FIsEditing: Boolean;
    FLink: TACLBindingDiagramLink;
    FOwner: TACLBindingDiagramSubClassViewInfo;
    FPoints: TACLList<TPoint>;
    FSourcePin: TACLBindingDiagramObjectPinViewInfo;
    FTargetPin: TACLBindingDiagramObjectPinViewInfo;

    procedure CalculateArrows;
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    // IACLDraggableObject
    function CreateDragObject(const AInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
  public
    constructor Create(ALink: TACLBindingDiagramLink; AOwner: TACLBindingDiagramSubClassViewInfo;
      ASourcePin, ATargetPin: TACLBindingDiagramObjectPinViewInfo; AColor: TColor); reintroduce;
    destructor Destroy; override;
    procedure Calculate(APathBuilder: TACLBindingDiagramLinkCustomPathBuilder); reintroduce;
    function CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean; override;
    function IsHighlighted: Boolean;
    //
    property Color: TColor read FColor;
    property Link: TACLBindingDiagramLink read FLink;
    property SourcePin: TACLBindingDiagramObjectPinViewInfo read FSourcePin;
    property TargetPin: TACLBindingDiagramObjectPinViewInfo read FTargetPin;
  end;

  { TACLBindingDiagramCreateLinkDragObject }

  TACLBindingDiagramCreateLinkDragObject = class(TACLBindingDiagramCustomLinkDragObject)
  protected
    procedure LinkObjects(ASourcePin, ATargetPin: TACLBindingDiagramObjectPin); override;
  public
    constructor Create(AStartPin: TACLBindingDiagramObjectPinViewInfo);
    function DragStart: Boolean; override;
  end;

  { TACLBindingDiagramEditLinkDragObject }

  TACLBindingDiagramEditLinkDragObject = class(TACLBindingDiagramCustomLinkDragObject)
  strict private
    FLink: TACLBindingDiagramLinkViewInfo;
  protected
    function CanLinkTo(APinViewInfo: TACLBindingDiagramObjectPinViewInfo): Boolean; override;
    procedure LinkObjects(ASourcePin, ATargetPin: TACLBindingDiagramObjectPin); override;
  public
    constructor Create(ALink: TACLBindingDiagramLinkViewInfo);
    procedure DragFinished(ACanceled: Boolean); override;
    function DragStart: Boolean; override;
  end;

  { TACLBindingDiagramScrollDragObject }

  TACLBindingDiagramScrollDragObject = class(TACLCompoundControlSubClassDragObject)
  strict private
    FOwner: TACLBindingDiagramSubClassViewInfo;
  public
    constructor Create(AOwner: TACLBindingDiagramSubClassViewInfo);
    procedure DragFinished(ACanceled: Boolean); override;
    procedure DragMove(const P: TPoint; var ADeltaX: Integer; var ADeltaY: Integer); override;
    function DragStart: Boolean; override;
  end;

  { TACLBindingDiagramSubClassViewInfo }

  TACLBindingDiagramSubClassViewInfo = class(TACLCompoundControlSubClassScrollContainerViewInfo,
    IACLDraggableObject)
  strict private const
    CellSize = 10;
    LineOffset = 6 +
      TACLBindingDiagramObjectPinViewInfo.ConnectorSize +
      TACLBindingDiagramLinkViewInfo.ArrowSize;
 strict private
    function GetSubClass: TACLBindingDiagramSubClass;
    // IACLDraggableObject
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
  protected
    FLineOffset: Integer;
    FLinkColors: TACLColorList;
    FLinks: TACLObjectList<TACLBindingDiagramLinkViewInfo>;
    FMoving: TACLBindingDiagramObject;
    FTextLineHeight: Integer;

    function AlignWithCells(const P: TPoint): TPoint; overload;
    function AlignWithCells(const S: TSize): TSize; overload;
    function AlignWithCells(const V: Integer): Integer; overload;
    procedure CalculateContentLayout; override;
    procedure CalculateLinks;
    procedure CalculateMetrics;
    procedure CalculateObjects;
    procedure CalculateSubCells(const AChanges: TIntegerSet); override;
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDrawCells(ACanvas: TCanvas); override;
    procedure FlushCache;
    procedure RecreateSubCells; override;
    procedure UpdateLinkColors;
  public
    constructor Create(AOwner: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    function FindViewInfo(ALink: TACLBindingDiagramLink; out AViewInfo: TACLBindingDiagramLinkViewInfo): Boolean; overload;
    function FindViewInfo(AObject: TACLBindingDiagramObject; out AViewInfo: TACLBindingDiagramObjectViewInfo): Boolean; overload;
    //
    property SubClass: TACLBindingDiagramSubClass read GetSubClass;
  end;

implementation

uses
  Math, Forms, ACL.Utils.DPIAware, ACL.Utils.Strings;

type
  TACLBindingDiagramLinkAccess = class(TACLBindingDiagramLink);

{ TACLStyleBindingDiagram }

procedure TACLStyleBindingDiagram.DrawObjectBorders(ACanvas: TCanvas; const R: TRect);
begin
  acDrawFrame(ACanvas.Handle, R, ColorObjectBorder.Value);
  acFillRect(ACanvas.Handle, acRectInflate(R, -1), ColorObjectContent.Value);
end;

procedure TACLStyleBindingDiagram.DrawSelection(ACanvas: TCanvas; const R: TRect);
var
  ASize: Integer;
begin
  ASize := MulDiv(TargetDPI, SelectionSize, acDefaultDPI);
  acDrawFrame(ACanvas.Handle, acRectInflate(R, ASize), ColorObjectSelection.Value, ASize);
end;

procedure TACLStyleBindingDiagram.InitializeResources;
begin
  inherited;
  ColorObjectBorder.InitailizeDefaults('Diagram.Colors.ObjectBorder', TAlphaColor.FromColor(clGray));
  ColorObjectCaption.InitailizeDefaults('Diagram.Colors.ObjectCaption', TAlphaColor.FromColor($404040));
  ColorObjectCaptionText.InitailizeDefaults('Diagram.Colors.ObjectCaptionText', clWhite);
  ColorObjectContent.InitailizeDefaults('Diagram.Colors.ObjectContent', TAlphaColor.FromColor(clWhite));
  ColorObjectDragHighlight.InitailizeDefaults('Diagram.Colors.ObjectDragHighlight', TAlphaColor($70FF0000));
  ColorObjectSelection.InitailizeDefaults('Diagram.Colors.ObjectSelection', TAlphaColor.FromColor(clNavy));
  ColorLinkBaseColor.InitailizeDefaults('Diagram.Colors.LinkBaseColor', $C00000);
end;

{ TACLBindingDiagramCustomOptions }

constructor TACLBindingDiagramCustomOptions.Create(ADiagram: TACLBindingDiagramSubClass);
begin
  inherited Create;
  FDiagram := ADiagram;
end;

procedure TACLBindingDiagramCustomOptions.DoChanged(AChanges: TACLPersistentChanges);
begin
  if [apcLayout, apcStruct] * AChanges <> [] then
    FDiagram.FullRefresh
  else
    FDiagram.Invalidate;
end;

{ TACLBindingDiagramOptionsBehavior }

procedure TACLBindingDiagramOptionsBehavior.AfterConstruction;
begin
  inherited;
  FAllowCreateLinks := True;
  FAllowMoveObjects := True;
  FAllowDeleteLinks := True;
  FAllowDeleteObjects := True;
  FAllowEditLinks := True;
end;

procedure TACLBindingDiagramOptionsBehavior.DoAssign(Source: TPersistent);
begin
  inherited;
  if Source is TACLBindingDiagramOptionsBehavior then
  begin
    AllowCreateLinks := TACLBindingDiagramOptionsBehavior(Source).AllowCreateLinks;
    AllowDeleteLinks := TACLBindingDiagramOptionsBehavior(Source).AllowDeleteLinks;
    AllowDeleteObjects := TACLBindingDiagramOptionsBehavior(Source).AllowDeleteObjects;
    AllowEditLinks := TACLBindingDiagramOptionsBehavior(Source).AllowEditLinks;
    AllowMoveObjects := TACLBindingDiagramOptionsBehavior(Source).AllowMoveObjects;
  end;
end;

{ TACLBindingDiagramOptionsView }

procedure TACLBindingDiagramOptionsView.AfterConstruction;
begin
  inherited;
  FShowCaption := True;
end;

procedure TACLBindingDiagramOptionsView.DoAssign(Source: TPersistent);
begin
  inherited;
  if Source is TACLBindingDiagramOptionsView then
  begin
    RowHeight := TACLBindingDiagramOptionsView(Source).RowHeight;
    CardWidth := TACLBindingDiagramOptionsView(Source).CardWidth;
    ShowCaption := TACLBindingDiagramOptionsView(Source).ShowCaption;
  end;
end;

procedure TACLBindingDiagramOptionsView.SetCardWidth(AValue: Integer);
begin
  SetIntegerFieldValue(FCardWidth, Max(AValue, 0));
end;

procedure TACLBindingDiagramOptionsView.SetRowHeight(AValue: Integer);
begin
  SetIntegerFieldValue(FRowHeight, Max(AValue, 0));
end;

procedure TACLBindingDiagramOptionsView.SetShowCaption(AValue: Boolean);
begin
  if FShowCaption <> AValue then
  begin
    FShowCaption := AValue;
    Changed([apcLayout]);
  end;
end;

{ TACLBindingDiagramSubClass }

constructor TACLBindingDiagramSubClass.Create(AOwner: TComponent);
begin
  inherited;
  FCaptionFont := TFont.Create;
  FStyle := TACLStyleBindingDiagram.Create(Self);
  FData := TACLBindingDiagramData.Create(HandlerObjectsChanged);
  FOptionsBehavior := TACLBindingDiagramOptionsBehavior.Create(Self);
  FOptionsView := TACLBindingDiagramOptionsView.Create(Self);
end;

destructor TACLBindingDiagramSubClass.Destroy;
begin
  FreeAndNil(FCaptionFont);
  FreeAndNil(FOptionsBehavior);
  FreeAndNil(FOptionsView);
  FreeAndNil(FData);
  FreeAndNil(FStyle);
  inherited;
end;

procedure TACLBindingDiagramSubClass.RemoveLink(ALink: TACLBindingDiagramLink);
var
  AAccepted: Boolean;
begin
  if OptionsBehavior.AllowDeleteLinks then
  begin
    AAccepted := True;
    if Assigned(OnLinkRemoving) then
      OnLinkRemoving(Self, ALink, AAccepted);
    if AAccepted then
      ALink.Free;
  end;
end;

procedure TACLBindingDiagramSubClass.RemoveObject(AObject: TACLBindingDiagramObject);
var
  AAccepted: Boolean;
begin
  if OptionsBehavior.AllowDeleteObjects and AObject.CanRemove then
  begin
    AAccepted := True;
    if Assigned(OnObjectRemoving) then
      OnObjectRemoving(Self, AObject, AAccepted);
    if AAccepted then
      AObject.Free;
  end;
end;

procedure TACLBindingDiagramSubClass.RemoveSelected;
var
  ASelectedObject: TObject;
begin
  ASelectedObject := SelectedObject;
  if ASelectedObject is TACLBindingDiagramObject then
    RemoveObject(TACLBindingDiagramObject(ASelectedObject));
  if ASelectedObject is TACLBindingDiagramLink then
    RemoveLink(TACLBindingDiagramLink(ASelectedObject));
end;

function TACLBindingDiagramSubClass.DoLinkChanging(
  ALink: TACLBindingDiagramLink; ASourcePin, ATargetPin: TACLBindingDiagramObjectPin): Boolean;
begin
  Result := True;
  if Assigned(OnLinkChanging) then
    OnLinkChanging(Self, ALink, ASourcePin, ATargetPin, Result);
end;

procedure TACLBindingDiagramSubClass.DoLinkChanged(ALink: TACLBindingDiagramLink);
begin
  if Assigned(OnLinkChanged) then
    OnLinkChanged(Self, ALink);
end;

function TACLBindingDiagramSubClass.DoLinkCreating(ASourcePin, ATargetPin: TACLBindingDiagramObjectPin): Boolean;
begin
  Result := True;
  if Assigned(OnLinkCreating) then
    OnLinkCreating(Self, ASourcePin, ATargetPin, Result);
end;

procedure TACLBindingDiagramSubClass.DoLinkCreated(ALink: TACLBindingDiagramLink);
begin
  if Assigned(OnLinkCreated) then
    OnLinkCreated(Self, ALink);
end;

procedure TACLBindingDiagramSubClass.DoSelectionChanged;
begin
  CallNotifyEvent(Self, OnSelectionChanged);
end;

procedure TACLBindingDiagramSubClass.ResourceChanged;
begin
  UpdateFonts;
  ViewInfo.UpdateLinkColors; // before inherited
  inherited ResourceChanged;
end;

procedure TACLBindingDiagramSubClass.UpdateFonts;
begin
  CaptionFont.Assign(Font);
  CaptionFont.Style := [fsBold];
end;

function TACLBindingDiagramSubClass.CreateViewInfo: TACLCompoundControlSubClassCustomViewInfo;
begin
  Result := TACLBindingDiagramSubClassViewInfo.Create(Self);
end;

procedure TACLBindingDiagramSubClass.HandlerObjectsChanged(Sender: TObject; AChanges: TACLPersistentChanges);
const
  Map: array[TACLPersistentChange] of TIntegerSet = ([cccnStruct, cccnLayout], [cccnLayout], [cccnContent]);
var
  C: TIntegerSet;
  I: TACLPersistentChange;
begin
  C := [];
  for I := Low(TACLPersistentChange) to High(TACLPersistentChange) do
  begin
    if I in AChanges then
      C := C + Map[I];
  end;
  Changed(C);
end;

function TACLBindingDiagramSubClass.GetViewInfo: TACLBindingDiagramSubClassViewInfo;
begin
  Result := TACLBindingDiagramSubClassViewInfo(inherited ViewInfo);
end;

procedure TACLBindingDiagramSubClass.DoDragStarted;
begin
  inherited;
  SelectedObject := nil;
end;

procedure TACLBindingDiagramSubClass.DoHoveredObjectChanged;
begin
  inherited;
  Invalidate;
end;

procedure TACLBindingDiagramSubClass.ProcessChanges(AChanges: TIntegerSet);
begin
  if cccnStruct in AChanges then
    SelectedObject := nil;
  inherited;
end;

procedure TACLBindingDiagramSubClass.ProcessKeyUp(AKey: Word; AShift: TShiftState);
begin
  if AKey = VK_DELETE then
    RemoveSelected
  else
    inherited;
end;

procedure TACLBindingDiagramSubClass.ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState);
begin
  if HitTest.HitObjectFlags[htObjectRemoveButton] then
    RemoveObject((HitTest.HitObject as TACLBindingDiagramObjectViewInfo).&Object)
  else
    if HitTest.HitObject is TACLBindingDiagramObjectViewInfo then
      SelectedObject := TACLBindingDiagramObjectViewInfo(HitTest.HitObject).&Object
    else if HitTest.HitObject is TACLBindingDiagramLinkViewInfo then
      SelectedObject := TACLBindingDiagramLinkViewInfo(HitTest.HitObject).Link
    else
      SelectedObject := nil;
end;

procedure TACLBindingDiagramSubClass.ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);
begin
  ViewInfo.ScrollByMouseWheel(ADirection, AShift);
end;

procedure TACLBindingDiagramSubClass.SetSelectedObject(const Value: TObject);
begin
  if FSelectedObject <> Value then
  begin
    FSelectedObject := Value;
    DoSelectionChanged;
    Invalidate;
  end;
end;

{ TACLBindingDiagramObjectDragObject }

constructor TACLBindingDiagramObjectDragObject.Create(AObject: TACLBindingDiagramObject);
begin
  FObject := AObject;
end;

procedure TACLBindingDiagramObjectDragObject.DragFinished(ACanceled: Boolean);
begin
  inherited;
  TACLBindingDiagramSubClass(SubClass).ViewInfo.FMoving := nil;
  TACLBindingDiagramSubClass(SubClass).ViewInfo.CalculateLinks;
end;

procedure TACLBindingDiagramObjectDragObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);
var
  APosition: TPoint;
begin
  APosition.X := Max(FObject.Position.X + ADeltaX, 0);
  APosition.Y := Max(FObject.Position.Y + ADeltaY, 0);
  ADeltaX := APosition.X - FObject.Position.X;
  ADeltaY := APosition.Y - FObject.Position.Y;
  FObject.Position := APosition;
end;

function TACLBindingDiagramObjectDragObject.DragStart: Boolean;
begin
  TACLBindingDiagramSubClass(SubClass).ViewInfo.FMoving := FObject;
  Result := True;
end;

{ TACLBindingDiagramObjectViewInfo }

constructor TACLBindingDiagramObjectViewInfo.Create(
  AOwner: TACLBindingDiagramSubClassViewInfo; AObject: TACLBindingDiagramObject);
begin
  inherited Create(AOwner.SubClass);
  FObject := AObject;
  FOwner := AOwner;
  RecreateSubCells;
end;

function TACLBindingDiagramObjectViewInfo.IsSelected: Boolean;
begin
  Result := SubClass.SelectedObject = &Object;
end;

function TACLBindingDiagramObjectViewInfo.MeasureSize: TSize;
var
  I: Integer;
begin
  Result := CalculateCaptionSize;
  for I := 0 to ChildCount - 1 do
    Result.cx := Max(Result.cx, TACLBindingDiagramObjectPinViewInfo(Children[I]).MeasureSize.cx);
  Inc(Result.cx, 2 * BorderWidth + 4 * ScaleFactor.Apply(TACLBindingDiagramObjectPinViewInfo.ConnectorSize));
  Inc(Result.cy, 2 * BorderWidth + ChildCount * FOwner.FTextLineHeight);
end;

function TACLBindingDiagramObjectViewInfo.CalculateCaptionSize: TSize;
begin
  if (FCaptionSize = NullSize) and SubClass.OptionsView.ShowCaption then
  begin
    FCaptionSize := acTextSize(SubClass.CaptionFont, &Object.Caption);
    Inc(FCaptionSize.cx, 2 * ScaleFactor.Apply(acTextIndent));
    Inc(FCaptionSize.cy, 2 * ScaleFactor.Apply(acTextIndent));
    if HasRemoveButton then
      Inc(FCaptionSize.cx, FOwner.FTextLineHeight);
    FCaptionSize.cy := Max(FCaptionSize.cy, FOwner.FTextLineHeight);
  end;
  Result := FCaptionSize;
end;

procedure TACLBindingDiagramObjectViewInfo.CalculateSubCells(const AChanges: TIntegerSet);
var
  ACell: TACLBindingDiagramObjectPinViewInfo;
  ACellHeight: Integer;
  R: TRect;
  I: Integer;
begin
  if cccnLayout in AChanges then
  begin
    FCaptionRect := acRectSetHeight(ContentRect, CalculateCaptionSize.cy);
    if HasRemoveButton then
    begin
      FRemoveButtonRect := acRectSetRight(CaptionRect, CaptionRect.Right, CaptionRect.Height);
      FRemoveButtonRect := acRectCenterVertically(RemoveButtonRect, FOwner.FTextLineHeight);
      FRemoveButtonRect := acRectInflate(RemoveButtonRect, -2 * ScaleFactor.Apply(acTextIndent));
    end
    else
      FRemoveButtonRect := NullRect;
  end;

  if ChildCount > 0 then
  begin
    R := ContentRect;
    R.Top := FCaptionRect.Bottom;
    ACellHeight := R.Height div ChildCount;
    for I := 0 to ChildCount - 2 do
    begin
      ACell := TACLBindingDiagramObjectPinViewInfo(Children[I]);
      ACell.Calculate(acRectSetHeight(R, ACellHeight), AChanges);
      R.Top := ACell.Bounds.Bottom;
    end;
    TACLBindingDiagramObjectPinViewInfo(Children[ChildCount - 1]).Calculate(R, AChanges);
  end;
  inherited;
end;

procedure TACLBindingDiagramObjectViewInfo.DoCalculateHitTest(const AHitTest: TACLHitTestInfo);
begin
  inherited DoCalculateHitTest(AHitTest);

  if AHitTest.HitObject = Self then
  begin
    if PtInRect(ContentRect, AHitTest.HitPoint) then
    begin
      AHitTest.HintData.Text := IfThenW(&Object.Hint, &Object.Caption);
      if PtInRect(RemoveButtonRect, AHitTest.HitPoint) then
      begin
        AHitTest.Cursor := crHandPoint;
        AHitTest.HitObjectFlags[htObjectRemoveButton] := True;
      end;
    end
    else
      AHitTest.HitObject := nil;
  end;
end;

procedure TACLBindingDiagramObjectViewInfo.DoDraw(ACanvas: TCanvas);
begin
  ACanvas.Brush.Style := bsClear;
  DoDrawBorders(ACanvas);
  DoDrawCaption(ACanvas);

  ACanvas.Font := SubClass.Font;
  ACanvas.Font.Color := SubClass.Style.ColorText.AsColor;
  inherited;
end;

procedure TACLBindingDiagramObjectViewInfo.DoDrawBorders(ACanvas: TCanvas);
begin
  Style.DrawObjectBorders(ACanvas, BorderBounds);
  if IsSelected then
    Style.DrawSelection(ACanvas, BorderBounds);
end;

procedure TACLBindingDiagramObjectViewInfo.DoDrawCaption(ACanvas: TCanvas);
begin
  if not IsRectEmpty(CaptionRect) then
  begin
    acFillRect(ACanvas.Handle, CaptionRect, Style.ColorObjectCaption.Value);

    ACanvas.Font := SubClass.CaptionFont;
    ACanvas.Font.Color := Style.ColorObjectCaptionText.AsColor;
    acTextDraw(ACanvas, &Object.Caption, CaptionTextRect, taCenter, taVerticalCenter, True);
  end;

  if not IsRectEmpty(RemoveButtonRect) then
  begin
    GpPaintCanvas.BeginPaint(ACanvas.Handle);
    try
      GPPaintCanvas.DrawLine(Style.ColorObjectCaptionText.Value,
        RemoveButtonRect.Left, RemoveButtonRect.Top, RemoveButtonRect.Right, RemoveButtonRect.Bottom, gpsSolid, 2);
      GPPaintCanvas.DrawLine(Style.ColorObjectCaptionText.Value,
        RemoveButtonRect.Right, RemoveButtonRect.Top, RemoveButtonRect.Left, RemoveButtonRect.Bottom, gpsSolid, 2);
    finally
      GPPaintCanvas.EndPaint;
    end;
  end;
end;

procedure TACLBindingDiagramObjectViewInfo.FlushCache;
begin
  FCaptionSize := NullSize;
end;

procedure TACLBindingDiagramObjectViewInfo.RecreateSubCells;
var
  I: Integer;
begin
  for I := 0 to &Object.PinCount - 1 do
    FChildren.Add(TACLBindingDiagramObjectPinViewInfo.Create(Self, &Object.Pins[I]));
end;

function TACLBindingDiagramObjectViewInfo.CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
begin
  if SubClass.OptionsBehavior.AllowMoveObjects then
    Result := TACLBindingDiagramObjectDragObject.Create(&Object)
  else
    Result := nil;
end;

function TACLBindingDiagramObjectViewInfo.HasRemoveButton: Boolean;
begin
  Result := &Object.CanRemove and SubClass.OptionsBehavior.AllowDeleteObjects and SubClass.OptionsView.ShowCaption;
end;

function TACLBindingDiagramObjectViewInfo.GetBorderBounds: TRect;
begin
  Result := acRectInflate(Bounds, -ScaleFactor.Apply(TACLBindingDiagramObjectPinViewInfo.ConnectorSize), 0);
end;

function TACLBindingDiagramObjectViewInfo.GetCaptionTextRect: TRect;
begin
  Result := CaptionRect;
  if not IsRectEmpty(RemoveButtonRect) then
    Result.Right := RemoveButtonRect.Left;
  Result := acRectInflate(Result, -ScaleFactor.Apply(acTextIndent));
end;

function TACLBindingDiagramObjectViewInfo.GetContentRect: TRect;
begin
  Result := acRectInflate(BorderBounds, -BorderWidth);
end;

function TACLBindingDiagramObjectViewInfo.GetStyle: TACLStyleBindingDiagram;
begin
  Result := SubClass.Style;
end;

function TACLBindingDiagramObjectViewInfo.GetSubClass: TACLBindingDiagramSubClass;
begin
  Result := TACLBindingDiagramSubClass(inherited SubClass);
end;

{ TACLBindingDiagramObjectPinViewInfo }

constructor TACLBindingDiagramObjectPinViewInfo.Create(
  AOwner: TACLBindingDiagramObjectViewInfo; APin: TACLBindingDiagramObjectPin);
begin
  inherited Create(AOwner.SubClass);
  FPin := APin;
  FOwner := AOwner;
  FLinks := TList.Create;
end;

destructor TACLBindingDiagramObjectPinViewInfo.Destroy;
begin
  FreeAndNil(FLinks);
  inherited;
end;

function TACLBindingDiagramObjectPinViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
begin
  if PtInRect(InputConnectorHitTestRect, AInfo.HitPoint) or PtInRect(OutputConnectorHitTestRect, AInfo.HitPoint) then
  begin
    if Owner.SubClass.OptionsBehavior.AllowCreateLinks then
      AInfo.Cursor := crDragLink;
    AInfo.HitObject := Self;
    Result := True;
  end
  else
    Result := inherited;
end;

function TACLBindingDiagramObjectPinViewInfo.MeasureSize: TSize;
begin
  Result := acTextSize(SubClass.Font, Pin.Caption);
  Result.cx := Result.cx + 2 * ScaleFactor.Apply(acTextIndent);
  Result.cy := FOwner.Owner.FTextLineHeight;
end;

procedure TACLBindingDiagramObjectPinViewInfo.AddLink(ALink: TACLBindingDiagramLinkViewInfo);
begin
  if ALink.FSourcePin = Self then
    FLinks.Add(ALink)
  else
    FLinks.Insert(0, ALink);
end;

procedure TACLBindingDiagramObjectPinViewInfo.DoCalculate(AChanges: TIntegerSet);
begin
  inherited;

  if opmInput in Pin.Mode then
  begin
    FInputConnectorRect := Bounds;
    FInputConnectorRect.Right := Bounds.Left + ScaleFactor.Apply(ConnectorSize) - 1;
    FInputConnectorRect.Left := Bounds.Left - ScaleFactor.Apply(ConnectorSize) - FOwner.BorderWidth;
    FInputConnectorRect := acRectCenterVertically(FInputConnectorRect, FInputConnectorRect.Width);
  end
  else
    FInputConnectorRect := NullRect;

  if opmOutput in Pin.Mode then
  begin
    FOutputConnectorRect := Bounds;
    FOutputConnectorRect.Right := Bounds.Right + ScaleFactor.Apply(ConnectorSize) + FOwner.BorderWidth;
    FOutputConnectorRect.Left := Bounds.Right - ScaleFactor.Apply(ConnectorSize) + 1;
    FOutputConnectorRect := acRectCenterVertically(FOutputConnectorRect, FOutputConnectorRect.Width);
  end
  else
    FOutputConnectorRect := NullRect;
end;

procedure TACLBindingDiagramObjectPinViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
var
  AIndex: Integer;
begin
  inherited;

  if (FLinks.Count > 0) and PtInRect(Bounds, AInfo.HitPoint) and not SubClass.DragAndDropController.IsActive then
  begin
    AIndex := (AInfo.HitPoint.X - Bounds.Left) div Max(Bounds.Width div FLinks.Count, 1);
    if InRange(AIndex, 0, FLinks.Count - 1) then
      TACLBindingDiagramLinkViewInfo(FLinks[AIndex]).DoCalculateHitTest(AInfo);
  end;
end;

procedure TACLBindingDiagramObjectPinViewInfo.DoDraw(ACanvas: TCanvas);
begin
  DoDrawBackground(ACanvas);

  acTextDraw(ACanvas, Pin.Caption, TextRect, taLeftJustify, taVerticalCenter);

  DoDrawConnector(ACanvas, InputConnectorRect, opmInput);
  DoDrawConnector(ACanvas, OutputConnectorRect, opmOutput);
end;

procedure TACLBindingDiagramObjectPinViewInfo.DoDrawBackground(ACanvas: TCanvas);

  function GetColor(ALink: TACLBindingDiagramLinkViewInfo): TAlphaColor;
  begin
    Result := TAlphaColor.FromColor(ALink.Color, IfThen(ALink.IsHighlighted, 128, 48));
  end;

var
  AColorArea: TRect;
  I: Integer;
begin
  if FLinks.Count > 0 then
  begin
    AColorArea := Bounds;
    AColorArea.Right := AColorArea.Left + AColorArea.Width div FLinks.Count;
    for I := 0 to FLinks.Count - 2 do
    begin
      acFillRect(ACanvas.Handle, AColorArea, GetColor(FLinks.List[I]));
      AColorArea := acRectOffset(AColorArea, AColorArea.Width, 0);
    end;
    AColorArea.Right := Bounds.Right;
    acFillRect(ACanvas.Handle, AColorArea, GetColor(FLinks.Last));
  end;
end;

procedure TACLBindingDiagramObjectPinViewInfo.DoDrawConnector(ACanvas: TCanvas; const R: TRect; AMode: TACLBindingDiagramObjectPinMode);
begin
  if not acRectIsEmpty(R) then
  begin
    FOwner.Style.DrawObjectBorders(ACanvas, R);
    if AMode in FHighlightedConnectors then
      acFillRect(ACanvas.Handle, R, FOwner.Style.ColorObjectDragHighlight.AsColor);
  end;
end;

function TACLBindingDiagramObjectPinViewInfo.CreateDragObject(const AInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
begin
  if TACLBindingDiagramSubClass(SubClass).OptionsBehavior.AllowCreateLinks and (Pin.Mode <> []) then
    Result := TACLBindingDiagramCreateLinkDragObject.Create(Self)
  else
    Result := nil;
end;

function TACLBindingDiagramObjectPinViewInfo.GetInputConnectorHitTestRect: TRect;
begin
  Result := InputConnectorRect;
  if not acRectIsEmpty(Result) then
    Result := acRectCenter(Result, 2 * ScaleFactor.Apply(ConnectorHitTestSize));
end;

function TACLBindingDiagramObjectPinViewInfo.GetOutputConnectorHitTestRect: TRect;
begin
  Result := OutputConnectorRect;
  if not acRectIsEmpty(Result) then
    Result := acRectCenter(Result, 2 * ScaleFactor.Apply(ConnectorHitTestSize));
end;

function TACLBindingDiagramObjectPinViewInfo.GetTextRect: TRect;
begin
  Result := acRectInflate(Bounds, -ScaleFactor.Apply(ConnectorSize) - ScaleFactor.Apply(acTextIndent), 0);
end;

{ TACLBindingDiagramLinkCustomPathBuilder }

procedure TACLBindingDiagramLinkCustomPathBuilder.AddPoint(APoints: TACLList<TPoint>; const P: TPoint);

  function IsMiddle(const P, P0, P1: TPoint): Boolean; inline;
  begin
    Result := (P.X = P0.X) and (P1.X = P0.X) or (P.Y = P0.Y) and (P1.Y = P0.Y);
  end;

begin
  if (APoints.Count > 2) and IsMiddle(APoints.Last, APoints.List[APoints.Count - 2], P) then
    APoints.List[APoints.Count - 1] := P
  else
    APoints.Add(P);
end;

{ TACLBindingDiagramComplexPathBuilder }

constructor TACLBindingDiagramComplexPathBuilder.Create;
begin
  Rows := TACLList<Integer>.Create;
  Columns := TACLList<Integer>.Create;
end;

destructor TACLBindingDiagramComplexPathBuilder.Destroy;
begin
  FreeAndNil(Columns);
  FreeAndNil(Rows);
  inherited;
end;

procedure TACLBindingDiagramComplexPathBuilder.Build(APoints: TACLList<TPoint>; ASource, ATarget: TACLBindingDiagramObjectPinViewInfo);

  function BuildPath(X, Y, ALevel: Integer): Boolean;
  begin
    Result := CheckBounds(X, Y) and (ALevel > ID_EMPTY) and (Matrix[Y, X] = ALevel);
    if Result then
    begin
      AddPoint(APoints, IndexToPoint(X, Y));
      Dec(ALevel);

      Result := (ALevel <= 0) or
        BuildPath(X - 1, Y, ALevel) or
        BuildPath(X + 1, Y, ALevel) or
        BuildPath(X, Y - 1, ALevel) or
        BuildPath(X, Y + 1, ALevel);
    end;
  end;

  // https://ru.wikipedia.org/wiki/%D0%90%D0%BB%D0%B3%D0%BE%D1%80%D0%B8%D1%82%D0%BC_%D0%9B%D0%B8
  procedure TracePath(const AStart, AFinish: TPoint);
  var
    ALevel: Integer;
    AMarked: Boolean;
    AWaveBounds: TRect;
    X, Y: Integer;
  begin
    ALevel := 1;
    Matrix[AStart.Y, AStart.X] := ALevel;
    Matrix[AFinish.Y, AFinish.X] := ID_EMPTY;
    AWaveBounds := acRect(AStart);
    repeat
      AMarked := False;
      for Y := AWaveBounds.Top to AWaveBounds.Bottom do
        for X := AWaveBounds.Left to AWaveBounds.Right do
        begin
          if Matrix[Y, X] <> ALevel then
            Continue;

          if MarkPath(X - 1, Y, ALevel + 1) then
          begin
            AWaveBounds.Left := Min(AWaveBounds.Left, X - 1);
            AMarked := True;
          end;

          if MarkPath(X + 1, Y, ALevel + 1) then
          begin
            AWaveBounds.Right := Max(AWaveBounds.Right, X + 1);
            AMarked := True;
          end;

          if MarkPath(X, Y - 1, ALevel + 1) then
          begin
            AWaveBounds.Top := Min(AWaveBounds.Top, Y - 1);
            AMarked := True;
          end;

          if MarkPath(X, Y + 1, ALevel + 1) then
          begin
            AWaveBounds.Bottom := Max(AWaveBounds.Bottom, Y + 1);
            AMarked := True;
          end;
        end;

      Inc(ALevel);
    until not AMarked or (Matrix[AFinish.Y, AFinish.X] > 0);
  end;

var
  S, T: TRect;
  AFinish: TPoint;
  AFinishPoint: TPoint;
  AStart: TPoint;
  AStartPoint: TPoint;
begin
  S := RectToIndexes(acRectCenterVertically(ASource.OutputConnectorRect, 1));;
  T := RectToIndexes(acRectCenterVertically(ATarget.InputConnectorRect, 1));;

  AFinish := Point(T.Left - 1, T.Top);
  AStart := Point(S.Right, S.Top);

  AStartPoint := acRectCenter(acRectSetWidth(ATarget.InputConnectorRect, 0));
  AFinishPoint := acRectCenter(acRectSetRight(ASource.OutputConnectorRect, ASource.OutputConnectorRect.Right - 1, 0));

  APoints.Count := 0;
  TracePath(AStart, AFinish);
  AddPoint(APoints, AStartPoint);

  if not BuildPath(AFinish.X, AFinish.Y, Matrix[AFinish.Y, AFinish.X]) then
  begin
    AddPoint(APoints, Point((AStartPoint.X + AFinishPoint.X) div 2, AStartPoint.Y));
    AddPoint(APoints, Point((AStartPoint.X + AFinishPoint.X) div 2, AFinishPoint.Y));
  end;

  AddPoint(APoints, AFinishPoint);
  Clean;
end;

procedure TACLBindingDiagramComplexPathBuilder.Initialize(AViewInfo: TACLBindingDiagramSubClassViewInfo);
var
  I: Integer;
begin
  Columns.Capacity := 8 * AViewInfo.ChildCount;
  Rows.Capacity := Columns.Capacity;

  for I := 0 to AViewInfo.ChildCount - 1 do
    Add(TACLBindingDiagramObjectViewInfo(AViewInfo.FChildren.List[I]));

  SetLength(Matrix, Rows.Count, Columns.Count);

  for I := 0 to AViewInfo.ChildCount - 1 do
    MarkObject(AViewInfo.Children[I].Bounds);
end;

procedure TACLBindingDiagramComplexPathBuilder.Add(const AObjectViewInfo: TACLBindingDiagramObjectViewInfo);
var
  APinViewInfo: TACLBindingDiagramObjectPinViewInfo;
  I: Integer;
begin
  Add(AObjectViewInfo.Bounds);
  Add(acRectInflate(AObjectViewInfo.BorderBounds, AObjectViewInfo.Owner.FLineOffset));
  for I := 0 to AObjectViewInfo.ChildCount - 1 do
  begin
    APinViewInfo := TACLBindingDiagramObjectPinViewInfo(AObjectViewInfo.FChildren.List[I]);
    if not acRectIsEmpty(APinViewInfo.InputConnectorRect) then
      Add(acRectCenterVertically(APinViewInfo.InputConnectorRect, 1));
    if not acRectIsEmpty(APinViewInfo.OutputConnectorRect) then
      Add(acRectCenterVertically(APinViewInfo.OutputConnectorRect, 1));
  end;
end;

procedure TACLBindingDiagramComplexPathBuilder.Add(const R: TRect);

  procedure AddToStortedList(L: TACLList<Integer>; V: Integer);
  var
    AIndex: Integer;
  begin
    if not L.BinarySearch(V, AIndex) then
      L.Insert(AIndex, V);
  end;

begin
  AddToStortedList(Columns, R.Left);
  AddToStortedList(Columns, R.Right);
  AddToStortedList(Rows, R.Top);
  AddToStortedList(Rows, R.Bottom);
end;

function TACLBindingDiagramComplexPathBuilder.CheckBounds(X, Y: Integer): Boolean;
begin
  Result := (X >= 0) and (X < Columns.Count) and (Y >= 0) and (Y < Rows.Count);
end;

procedure TACLBindingDiagramComplexPathBuilder.Clean;
var
  I, J: Integer;
begin
  for I := 0 to Columns.Count - 1 do
    for J := 0 to Rows.Count - 1 do
    begin
      if Matrix[J, I] <> ID_OBJECT then
        Matrix[J, I] := ID_EMPTY;
    end;
end;

procedure TACLBindingDiagramComplexPathBuilder.MarkObject(R: TRect);
var
  I, J: Integer;
begin
  R := RectToIndexes(R);
  for I := R.Left to R.Right do
    for J := R.Top to R.Bottom do
      Matrix[J, I] := ID_OBJECT;
end;

function TACLBindingDiagramComplexPathBuilder.MarkPath(X, Y, Level: Integer): Boolean;
begin
  Result := CheckBounds(X, Y) and (Matrix[Y, X] = ID_EMPTY);
  if Result then
    Matrix[Y, X] := Level;
end;

function TACLBindingDiagramComplexPathBuilder.IndexToPoint(X, Y: Integer): TPoint;
begin
  Result.X := Columns[X];
  Result.Y := Rows[Y];
end;

function TACLBindingDiagramComplexPathBuilder.RectToIndexes(const R: TRect): TRect;

  function IndexOf(L: TACLList<Integer>; V: Integer): Integer; inline;
  begin
    if not L.BinarySearch(V, Result) then
      raise EInvalidArgument.Create('Specified rect was not indexed');
  end;

begin
  Result.Bottom := IndexOf(Rows, R.Bottom);
  Result.Left := IndexOf(Columns, R.Left);
  Result.Right := IndexOf(Columns, R.Right);
  Result.Top := IndexOf(Rows, R.Top);
end;

{ TACLBindingDiagramSimplePathBuilder }

procedure TACLBindingDiagramSimplePathBuilder.Build(
  APoints: TACLList<TPoint>; ASource, ATarget: TACLBindingDiagramObjectPinViewInfo);
begin
  Rows.Count := 0;
  Columns.Count := 0;

  Add(ASource.Owner);
  Add(ATarget.Owner);

  SetLength(Matrix, Rows.Count, Columns.Count);

  MarkObject(ASource.Owner.Bounds);
  MarkObject(ATarget.Owner.Bounds);

  inherited;
end;

procedure TACLBindingDiagramSimplePathBuilder.Initialize(AViewInfo: TACLBindingDiagramSubClassViewInfo);
begin
  // do nothing
end;

{ TACLBindingDiagramScrollDragObject }

constructor TACLBindingDiagramScrollDragObject.Create(AOwner: TACLBindingDiagramSubClassViewInfo);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TACLBindingDiagramScrollDragObject.DragFinished(ACanceled: Boolean);
begin
  inherited;
  Cursor := crDefault;
end;

procedure TACLBindingDiagramScrollDragObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);
var
  APrevViewport: TPoint;
begin
  Cursor := crSizeAll;
  APrevViewport := FOwner.Viewport;
  FOwner.Viewport := acPointOffset(FOwner.Viewport, -ADeltaX, -ADeltaY);
  ADeltaX := APrevViewport.X - FOwner.ViewportX;
  ADeltaY := APrevViewport.Y - FOwner.ViewportY;
end;

function TACLBindingDiagramScrollDragObject.DragStart: Boolean;
begin
  Result := True;
end;

{ TACLBindingDiagramSubClassViewInfo }

constructor TACLBindingDiagramSubClassViewInfo.Create(AOwner: TACLCompoundControlSubClass);
begin
  inherited;
  FLinkColors := TACLColorList.Create;
  FLinks := TACLObjectList<TACLBindingDiagramLinkViewInfo>.Create;
end;

destructor TACLBindingDiagramSubClassViewInfo.Destroy;
begin
  FreeAndNil(FLinkColors);
  FreeAndNil(FLinks);
  inherited;
end;

function TACLBindingDiagramSubClassViewInfo.FindViewInfo(
  AObject: TACLBindingDiagramObject; out AViewInfo: TACLBindingDiagramObjectViewInfo): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to ChildCount - 1 do
  begin
    Result := TACLBindingDiagramObjectViewInfo(FChildren.List[I]).&Object = AObject;
    if Result then
    begin
      AViewInfo := TACLBindingDiagramObjectViewInfo(FChildren.List[I]);
      Break;
    end;
  end;
end;

procedure TACLBindingDiagramSubClassViewInfo.FlushCache;
var
  I: Integer;
begin
  for I := 0 to ChildCount - 1 do
    TACLBindingDiagramObjectViewInfo(FChildren.List[I]).FlushCache;
end;

function TACLBindingDiagramSubClassViewInfo.FindViewInfo(
  ALink: TACLBindingDiagramLink; out AViewInfo: TACLBindingDiagramLinkViewInfo): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FLinks.Count - 1 do
  begin
    Result := FLinks[I].Link = ALink;
    if Result then
    begin
      AViewInfo := FLinks[I];
      Break;
    end;
  end;
end;

function TACLBindingDiagramSubClassViewInfo.AlignWithCells(const P: TPoint): TPoint;
begin
  Result.X := AlignWithCells(P.X);
  Result.Y := AlignWithCells(P.Y);
end;

function TACLBindingDiagramSubClassViewInfo.AlignWithCells(const S: TSize): TSize;
begin
  Result.cx := AlignWithCells(S.cx);
  Result.cy := AlignWithCells(S.cy);
end;

function TACLBindingDiagramSubClassViewInfo.AlignWithCells(const V: Integer): Integer;
begin
  Result := Ceil(V / CellSize) * CellSize;
end;

procedure TACLBindingDiagramSubClassViewInfo.CalculateContentLayout;
var
  ABoundingRect: TRect;
  I: Integer;
begin
  if ChildCount > 0 then
  begin
    ABoundingRect := Children[0].Bounds;
    for I := 1 to ChildCount - 1 do
      acRectUnion(ABoundingRect, Children[I].Bounds);
    for I := 0 to FLinks.Count - 1 do
      acRectUnion(ABoundingRect, FLinks[I].Bounds);
    FContentSize := acSize(ABoundingRect.Right, ABoundingRect.Bottom);
  end
  else
    FContentSize := NullSize;
end;

procedure TACLBindingDiagramSubClassViewInfo.CalculateLinks;
var
  APathBuilder: TACLBindingDiagramComplexPathBuilder;
  I: Integer;
begin
  if FLinks.Count > 0 then
  begin
    if FLinks.Count > 40 then
      APathBuilder := TACLBindingDiagramSimplePathBuilder.Create
    else
      APathBuilder := TACLBindingDiagramComplexPathBuilder.Create;

    try
      APathBuilder.Initialize(Self);
      for I := 0 to FLinks.Count - 1 do
        FLinks[I].Calculate(APathBuilder);
    finally
      APathBuilder.Free;
    end;
  end;
end;

procedure TACLBindingDiagramSubClassViewInfo.CalculateMetrics;
begin
  FLineOffset := ScaleFactor.Apply(LineOffset);
  if SubClass.OptionsView.RowHeight > 0 then
    FTextLineHeight := ScaleFactor.Apply(SubClass.OptionsView.RowHeight)
  else
    FTextLineHeight := acFontHeight(SubClass.Font) + 2 * ScaleFactor.Apply(acTextIndent);
end;

procedure TACLBindingDiagramSubClassViewInfo.CalculateObjects;
var
  ABasePosition: TPoint;
  ACanvas: TCanvas;
  AObjectBounds: TRect;
  AObjectViewInfo: TACLBindingDiagramObjectViewInfo;
  ACardWidth: Integer;
  I: Integer;
begin
  ACanvas := MeasureCanvas;
  ACanvas.Font := SubClass.Font;
  ABasePosition := acPointOffset(Bounds.TopLeft, FLineOffset, FLineOffset);
  ACardWidth := SubClass.OptionsView.CardWidth;

  for I := 0 to ChildCount - 1 do
  begin
    AObjectViewInfo := TACLBindingDiagramObjectViewInfo(Children[I]);
    AObjectBounds := acRectSetSize(AlignWithCells(AObjectViewInfo.&Object.Position), AObjectViewInfo.MeasureSize);
    if ACardWidth > 0 then
      AObjectBounds := acRectSetWidth(AObjectBounds, ACardWidth);
    AObjectBounds := acRectOffset(AObjectBounds, ABasePosition);
    AObjectViewInfo.Calculate(AObjectBounds, [cccnLayout]);
  end;
end;

procedure TACLBindingDiagramSubClassViewInfo.CalculateSubCells(const AChanges: TIntegerSet);
begin
  if cccnStruct in AChanges then
  begin
    FlushCache;
    CalculateMetrics;
  end;
  if cccnLayout in AChanges then
  begin
    CalculateObjects;
    CalculateLinks;
  end;
  inherited;
end;

procedure TACLBindingDiagramSubClassViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
var
  I: Integer;
begin
  AInfo.HitPoint := acPointOffset(AInfo.HitPoint, Viewport);
  try
    inherited;
    if AInfo.HitObject = Self then
      for I := FLinks.Count - 1 downto 0 do
      begin
        if FLinks[I].CalculateHitTest(AInfo) then
          Break;
      end;
  finally
    AInfo.HitPoint := acPointOffsetNegative(AInfo.HitPoint, Viewport);
  end;
end;

procedure TACLBindingDiagramSubClassViewInfo.DoDrawCells(ACanvas: TCanvas);
var
  I: Integer;
begin
  MoveWindowOrg(ACanvas.Handle, -ViewportX, -ViewportY);
  for I := 0 to FLinks.Count - 1 do
    FLinks[I].Draw(ACanvas);
  inherited;
end;

procedure TACLBindingDiagramSubClassViewInfo.RecreateSubCells;
var
  ALink: TACLBindingDiagramLink;
  AMap: TACLObjectDictionary;
  AObject: TACLBindingDiagramObject;
  AObjectViewInfo: TACLBindingDiagramObjectViewInfo;
  I, J: Integer;
begin
  if FLinkColors.Count = 0 then
    UpdateLinkColors;

  AMap := TACLObjectDictionary.Create;
  try
    for I := 0 to SubClass.Data.ObjectCount - 1 do
    begin
      AObject := SubClass.Data.Objects[I];
      AddCell(TACLBindingDiagramObjectViewInfo.Create(Self, AObject), AObjectViewInfo);
      for J := 0 to AObject.PinCount - 1 do
        AMap.Add(AObject.Pins[J], AObjectViewInfo.Children[J]);
    end;

    FLinks.Clear;
    for I := 0 to SubClass.Data.LinkCount - 1 do
    begin
      ALink := SubClass.Data.Links[I];
      FLinks.Add(TACLBindingDiagramLinkViewInfo.Create(ALink, Self,
        TACLBindingDiagramObjectPinViewInfo(AMap.Items[ALink.Source]),
        TACLBindingDiagramObjectPinViewInfo(AMap.Items[ALink.Target]),
        FLinkColors.List[I mod FLinkColors.Count]));
    end;
  finally
    AMap.Free;
  end;
end;

procedure TACLBindingDiagramSubClassViewInfo.UpdateLinkColors;
begin
  acBuildColorPalette(FLinkColors, SubClass.Style.ColorLinkBaseColor.AsColor);
end;

function TACLBindingDiagramSubClassViewInfo.GetSubClass: TACLBindingDiagramSubClass;
begin
  Result := TACLBindingDiagramSubClass(inherited SubClass);
end;

function TACLBindingDiagramSubClassViewInfo.CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
begin
  Result := TACLBindingDiagramScrollDragObject.Create(Self);
end;

{ TACLBindingDiagramCustomLinkDragObject }

function TACLBindingDiagramCustomLinkDragObject.DragStart: Boolean;
const
  OppositeMap: array[TACLBindingDiagramObjectPinMode] of TACLBindingDiagramObjectPinMode = (opmOutput, opmInput);
begin
  Result := (FStartPin <> nil) and (FStartPinMode in FStartPin.Pin.Mode);
  if Result then
  begin
    FStartPin.FHighlightedConnectors := [FStartPinMode];
    FTargetPinMode := OppositeMap[FStartPinMode];
  end;
end;

procedure TACLBindingDiagramCustomLinkDragObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);
const
  CursorMap: array[Boolean] of TCursor = (crNoDrop, crDrag);
begin
  if HitTest.HitObject is TACLBindingDiagramObjectPinViewInfo then
    TargetPin := TACLBindingDiagramObjectPinViewInfo(HitTest.HitObject)
  else
    TargetPin := nil;

  if TargetPin <> nil then
    SetLine(GetPoint(FStartPin, FStartPinMode), GetPoint(FTargetPin, FTargetPinMode))
  else
    SetLine(GetPoint(FStartPin, FStartPinMode), P);

  Cursor := CursorMap[TargetPin <> nil];
end;

procedure TACLBindingDiagramCustomLinkDragObject.DragFinished(ACanceled: Boolean);
begin
  SubClass.BeginUpdate;
  try
    if not ACanceled and (TargetPin <> nil) then
    begin
      if FStartPinMode = opmOutput then
        LinkObjects(FStartPin.Pin, TargetPin.Pin)
      else
        LinkObjects(TargetPin.Pin, FStartPin.Pin);
    end;
    SetLine(NullPoint, NullPoint);
    FStartPin.FHighlightedConnectors := [];
    TargetPin := nil;
  finally
    SubClass.EndUpdate;
  end;
end;

procedure TACLBindingDiagramCustomLinkDragObject.Draw(ACanvas: TCanvas);
begin
  ACanvas.Pen.Color := Style.ColorObjectDragHighlight.AsColor;
  ACanvas.Pen.Width := 1;
  ACanvas.MoveTo(FLineStart.X, FLineStart.Y);
  ACanvas.LineTo(FLineFinish.X, FLineFinish.Y);
end;

function TACLBindingDiagramCustomLinkDragObject.CanLinkTo(APinViewInfo: TACLBindingDiagramObjectPinViewInfo): Boolean;
begin
  Result := (APinViewInfo <> nil) and (FTargetPinMode in APinViewInfo.Pin.Mode) and (APinViewInfo.Pin.Owner <> FStartPin.Pin.Owner);
  if Result then
  begin
    if FStartPinMode = opmOutput then
      Result := not SubClass.Data.ContainsLink(FStartPin.Pin, APinViewInfo.Pin)
    else
      Result := not SubClass.Data.ContainsLink(APinViewInfo.Pin, FStartPin.Pin);
  end;
end;

procedure TACLBindingDiagramCustomLinkDragObject.SetLine(const P1, P2: TPoint);
begin
  if (FLineStart <> P1) or (FLineFinish <> P2) then
  begin
    FLineFinish := P2;
    FLineStart := P1;
    SubClass.Invalidate;
  end;
end;

procedure TACLBindingDiagramCustomLinkDragObject.SetTargetPin(AValue: TACLBindingDiagramObjectPinViewInfo);
begin
  if not CanLinkTo(AValue) then
    AValue := nil;

  if FTargetPin <> AValue then
  begin
    if FTargetPin <> nil then
    begin
      FTargetPin.FHighlightedConnectors := [];
      FTargetPin := nil;
    end;
    if AValue <> nil then
    begin
      FTargetPin := AValue;
      FTargetPin.FHighlightedConnectors := [FTargetPinMode];
    end;
  end;
end;

function TACLBindingDiagramCustomLinkDragObject.GetPoint(
  APinViewInfo: TACLBindingDiagramObjectPinViewInfo; AMode: TACLBindingDiagramObjectPinMode): TPoint;
begin
  if AMode = opmOutput then
    Result := Point(APinViewInfo.OutputConnectorRect.Right, APinViewInfo.OutputConnectorRect.CenterPoint.Y)
  else
    Result := Point(APinViewInfo.InputConnectorRect.Left, APinViewInfo.InputConnectorRect.CenterPoint.Y);

  Result := acPointOffset(Result, ViewOrigin);
end;

function TACLBindingDiagramCustomLinkDragObject.GetStyle: TACLStyleBindingDiagram;
begin
  Result := TACLBindingDiagramSubClass(SubClass).Style;
end;

function TACLBindingDiagramCustomLinkDragObject.GetSubClass: TACLBindingDiagramSubClass;
begin
  Result := TACLBindingDiagramSubClass(inherited SubClass);
end;

function TACLBindingDiagramCustomLinkDragObject.GetViewOrigin: TPoint;
begin
  Result := TACLBindingDiagramSubClassViewInfo(SubClass.ViewInfo).Viewport;
end;

{ TACLBindingDiagramLinkViewInfo }

constructor TACLBindingDiagramLinkViewInfo.Create(
  ALink: TACLBindingDiagramLink; AOwner: TACLBindingDiagramSubClassViewInfo;
  ASourcePin, ATargetPin: TACLBindingDiagramObjectPinViewInfo; AColor: TColor);
begin
  inherited Create(ASourcePin.SubClass);
  FLink := ALink;
  FColor := AColor;
  FOwner := AOwner;
  FSourcePin := ASourcePin;
  FSourcePin.AddLink(Self);
  FTargetPin := ATargetPin;
  FTargetPin.AddLink(Self);
  FPoints := TACLList<TPoint>.Create;
end;

destructor TACLBindingDiagramLinkViewInfo.Destroy;
begin
  FreeAndNil(FPoints);
  inherited;
end;

procedure TACLBindingDiagramLinkViewInfo.Calculate(APathBuilder: TACLBindingDiagramLinkCustomPathBuilder);
var
  I: Integer;
begin
  if (FOwner.FMoving = nil) or (FOwner.FMoving = FSourcePin.Owner.&Object) or (FOwner.FMoving = FTargetPin.Owner.&Object) then
  begin
    APathBuilder.Build(FPoints, FSourcePin, FTargetPin);
    CalculateArrows;

    FBounds := acRect(FPoints.First);
    for I := 1 to FPoints.Count - 1 do
      acRectUnion(FBounds, acRect(FPoints.List[I]));
    FBounds := acRectInflate(FBounds, ScaleFactor.Apply(HitTestSize));
  end;
end;

function TACLBindingDiagramLinkViewInfo.CalculateHitTest(const AInfo: TACLHitTestInfo): Boolean;
var
  I: Integer;
  R: TRect;
begin
  Result := False;
  if PtInRect(Bounds, AInfo.HitPoint) then
  begin
    for I := 0 to FPoints.Count - 2 do
    begin
      R := acRectAdjust(Rect(FPoints.List[I], FPoints.List[I + 1]));
      R := acRectInflate(R, ScaleFactor.Apply(HitTestSize));
      if PtInRect(R, AInfo.HitPoint) then
      begin
        DoCalculateHitTest(AInfo);
        Exit(True);
      end;
    end;
  end;
end;

function TACLBindingDiagramLinkViewInfo.IsHighlighted: Boolean;
begin
  Result :=
    (TACLBindingDiagramSubClass(SubClass).HoveredObject = Self) or
    (TACLBindingDiagramSubClass(SubClass).SelectedObject = Link);
end;

procedure TACLBindingDiagramLinkViewInfo.CalculateArrows;
var
  AArrowSize: Integer;
  APoint: TPoint;
begin
  AArrowSize := ScaleFactor.Apply(ArrowSize);

  if laOutput in Link.Arrows then
  begin
    APoint := FPoints.Last;
    FArrowOutputVisible := True;
    FArrowOutput[0] := APoint;
    FArrowOutput[1] := Point(APoint.X, APoint.Y - 1);
    FArrowOutput[2] := Point(APoint.X + AArrowSize, APoint.Y - 1 + AArrowSize);
    FArrowOutput[3] := Point(APoint.X + AArrowSize, APoint.Y - AArrowSize);
    FPoints.List[FPoints.Count - 1].X := FArrowOutput[3].X;
  end
  else
    FArrowOutputVisible := False;

  if laInput in Link.Arrows then
  begin
    APoint := FPoints.First;
    FArrowInputVisible := True;
    FArrowInput[0] := Point(APoint.X, APoint.Y);
    FArrowInput[1] := Point(APoint.X, APoint.Y - 1);
    FArrowInput[2] := Point(APoint.X - AArrowSize, APoint.Y - 1 + AArrowSize);
    FArrowInput[3] := Point(APoint.X - AArrowSize, APoint.Y - AArrowSize);
    FPoints.List[0].X := FArrowInput[3].X;
  end
  else
    FArrowInputVisible := False;
end;

procedure TACLBindingDiagramLinkViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
begin
  inherited;
  AInfo.HintData.Text := Link.Hint;
end;

procedure TACLBindingDiagramLinkViewInfo.DoDraw(ACanvas: TCanvas);
begin
  if FIsEditing then Exit;

  ACanvas.Pen.Color := FColor;
  ACanvas.Pen.Width := IfThen(IsHighlighted, 3, 1);
  ACanvas.Brush.Color := FColor;
  ACanvas.Polyline(FPoints.ToArray);

  if FArrowOutputVisible then
    ACanvas.Polygon(FArrowOutput);
  if FArrowInputVisible then
    ACanvas.Polygon(FArrowInput);
end;

function TACLBindingDiagramLinkViewInfo.CreateDragObject(const AInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
begin
  if TACLBindingDiagramSubClass(SubClass).OptionsBehavior.AllowEditLinks then
    Result := TACLBindingDiagramEditLinkDragObject.Create(Self)
  else
    Result := nil;
end;

{ TACLBindingDiagramCreateLinkDragObject }

constructor TACLBindingDiagramCreateLinkDragObject.Create(AStartPin: TACLBindingDiagramObjectPinViewInfo);
begin
  FStartPin := AStartPin;
end;

function TACLBindingDiagramCreateLinkDragObject.DragStart: Boolean;
var
  AIsLeftSide: Boolean;
begin
  AIsLeftSide := (HitTest.HitPoint.X - FStartPin.Bounds.Left < FStartPin.Bounds.Right - HitTest.HitPoint.X);
  if AIsLeftSide and (opmInput in FStartPin.Pin.Mode) or not AIsLeftSide and not (opmOutput in FStartPin.Pin.Mode) then
    FStartPinMode := opmInput
  else
    FStartPinMode := opmOutput;

  Result := inherited;
end;

procedure TACLBindingDiagramCreateLinkDragObject.LinkObjects(ASourcePin, ATargetPin: TACLBindingDiagramObjectPin);
begin
  if SubClass.DoLinkCreating(ASourcePin, ATargetPin) then
    SubClass.DoLinkCreated(SubClass.Data.AddLink(ASourcePin, ATargetPin));
end;

{ TACLBindingDiagramEditLinkDragObject }

constructor TACLBindingDiagramEditLinkDragObject.Create(ALink: TACLBindingDiagramLinkViewInfo);
begin
  FLink := ALink;
end;

procedure TACLBindingDiagramEditLinkDragObject.DragFinished(ACanceled: Boolean);
begin
  FLink.FIsEditing := False;
  inherited;
end;

function TACLBindingDiagramEditLinkDragObject.DragStart: Boolean;
var
  ADistanceToSource: Double;
  ADistanceToTarget: Double;
begin
  ADistanceToSource := acPointDistance(HitTest.HitPoint, FLink.FSourcePin.OutputConnectorRect.CenterPoint);
  ADistanceToTarget := acPointDistance(HitTest.HitPoint, FLink.FTargetPin.InputConnectorRect.CenterPoint);
  if ADistanceToSource < ADistanceToTarget then
  begin
    FStartPin := FLink.FTargetPin;
    FStartPinMode := opmInput;
  end
  else
  begin
    FStartPin := FLink.FSourcePin;
    FStartPinMode := opmOutput;
  end;
  Result := inherited;
  if Result then
    FLink.FIsEditing := True;
end;

function TACLBindingDiagramEditLinkDragObject.CanLinkTo(APinViewInfo: TACLBindingDiagramObjectPinViewInfo): Boolean;
begin
  Result := inherited or
    (FLink.FSourcePin = FStartPin) and (APinViewInfo = FLink.FTargetPin) or
    (FLink.FTargetPin = FStartPin) and (APinViewInfo = FLink.FSourcePin);
end;

procedure TACLBindingDiagramEditLinkDragObject.LinkObjects(ASourcePin, ATargetPin: TACLBindingDiagramObjectPin);
begin
  if SubClass.DoLinkChanging(FLink.Link, ASourcePin, ATargetPin) then
  begin
    TACLBindingDiagramLinkAccess(FLink.Link).SetSource(ASourcePin);
    TACLBindingDiagramLinkAccess(FLink.Link).SetTarget(ATargetPin);
    SubClass.DoLinkChanged(FLink.Link);
  end;
end;

end.
