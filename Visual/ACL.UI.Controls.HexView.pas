{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*              HexView Control              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.HexView;

{$I ACL.Config.Inc}

interface

uses
  UITypes, Types, SysUtils, Windows, Messages, Classes, Graphics, Controls, Forms,
  // ACL
  ACL.Classes,
  ACL.Classes.ByteBuffer,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.FontCache,
  ACL.Graphics.Layers,
  ACL.Math,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Controls.CompoundControl.SubClass.Scrollbox,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.Clipboard,
  ACL.Utils.Strings;

const
  acHexViewBytesPerRow = 16;

  hvcLayout = cccnLayout;
  hvcMakeVisible = cccnLast + 1;
  hvcLast = hvcMakeVisible;

type
  TACLHexViewSubClassController = class;
  TACLHexViewSubClassViewInfo = class;

  { TACLHexViewStyle }

  TACLHexViewStyle = class(TACLStyle)
  protected
    procedure InitializeResources; override;
  public
    procedure DrawBorder(ACanvas: TCanvas; const R: TRect; const ABorders: TACLBorders);
    procedure DrawContent(ACanvas: TCanvas; const R: TRect);
    function IsTransparentBackground: Boolean;
  published
    property ColorBorder1: TACLResourceColor index 0 read GetColor write SetColor stored IsColorStored;
    property ColorBorder2: TACLResourceColor index 1 read GetColor write SetColor stored IsColorStored;
    property ColorContent1: TACLResourceColor index 2 read GetColor write SetColor stored IsColorStored;
    property ColorContent2: TACLResourceColor index 3 read GetColor write SetColor stored IsColorStored;
    property ColorContentFocused: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
    property ColorContentSelected: TACLResourceColor index 5 read GetColor write SetColor stored IsColorStored;
    property ColorContentSelectedInactive: TACLResourceColor index 6 read GetColor write SetColor stored IsColorStored;
    property ColorContentText1: TACLResourceColor index 7 read GetColor write SetColor stored IsColorStored;
    property ColorContentText2: TACLResourceColor index 8 read GetColor write SetColor stored IsColorStored;
    property ColorHeaderText: TACLResourceColor index 9 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLHexViewCharacterSet }

  TACLHexViewCharacterSet = class abstract
  strict private const
    EmptyChar = '.';
  strict private
    FData: array[Byte] of string;
    FEmptyCharView: TACLTextViewInfo;
    FFont: TACLFontInfo;
    FSize: TSize;
    FView: array[Byte] of TACLTextViewInfo;

    procedure CreateViewInfo;
    function GetView(Index: Byte): TACLTextViewInfo; inline;
    procedure ReleaseViewInfo;
    procedure SetFont(AValue: TACLFontInfo);
  protected
    function CreateData(AIndex: Byte): string; virtual;
  public
    destructor Destroy; override;
    //
    property Font: TACLFontInfo read FFont write SetFont;
    property Size: TSize read FSize;
    property View[Index: Byte]: TACLTextViewInfo read GetView;
  end;

  { TACLHexViewHexCharacterSet }

  TACLHexViewHexCharacterSet = class(TACLHexViewCharacterSet)
  protected
    function CreateData(AIndex: Byte): string; override;
  end;

  { TACLHexViewSubClass }

  TACLHexViewSubClass = class(TACLCompoundControlSubClass)
  public type
    TEncodeProc = reference to function (const ABytes: TBytes): string;
  strict private
    FCharacters: TACLHexViewCharacterSet;
    FCharactersHex: TACLHexViewHexCharacterSet;
    FCursor: Int64;
    FData: TStream;
    FDataSize: Int64;
    FSelLength: Int64;
    FSelStart: Int64;
    FStyle: TACLHexViewStyle;

    FOnSelect: TNotifyEvent;

    function GetController: TACLHexViewSubClassController; inline;
    function GetSelFinish: Int64;
    function GetViewInfo: TACLHexViewSubClassViewInfo; inline;
    procedure SetCursor(AValue: Int64);
    procedure SetData(AValue: TStream);
  protected
    function CreateController: TACLCompoundControlSubClassController; override;
    function CreateStyle: TACLHexViewStyle; virtual;
    function CreateViewInfo: TACLCompoundControlSubClassCustomViewInfo; override;
    procedure DoSelectionChanged; virtual;
    function GetPositionFromHitTest(AHitTestInfo: TACLHitTestInfo): Int64;
    procedure ProcessChanges(AChanges: TIntegerSet = []); override;
    procedure ResourceChanged; override;
    procedure UpdateCharacters;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    procedure CopyToClipboard; overload;
    procedure CopyToClipboard(AEncoding: TEncoding); overload;
    procedure CopyToClipboard(AEncodeProc: TEncodeProc); overload;
    function GetSelectedBytes: TBytes;
    procedure MakeVisible(const ACharPosition: Int64);
    procedure SelectAll;
    procedure SetSelection(AStart, ALength: Int64);
    procedure SetTargetDPI(AValue: Integer); override;
    //
    property Characters: TACLHexViewCharacterSet read FCharacters;
    property CharactersHex: TACLHexViewHexCharacterSet read FCharactersHex;
    property Controller: TACLHexViewSubClassController read GetController;
    property Cursor: Int64 read FCursor write SetCursor;
    property Data: TStream read FData write SetData;
    property DataSize: Int64 read FDataSize;
    property SelFinish: Int64 read GetSelFinish;
    property SelLength: Int64 read FSelLength;
    property SelStart: Int64 read FSelStart;
    property Style: TACLHexViewStyle read FStyle;
    property ViewInfo: TACLHexViewSubClassViewInfo read GetViewInfo;
    //
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
  end;

  { TACLHexViewSubClassController }

  TACLHexViewSubClassController = class(TACLCompoundControlSubClassController)
  strict private
    FSelectionStart: Int64;

    function GetSubClass: TACLHexViewSubClass; inline;
    function GetViewInfo: TACLHexViewSubClassViewInfo; inline;
  private
    function GetSelStart: Int64;
    function GetCursor: Int64;
  protected
    procedure ProcessKeyDown(AKey: Word; AShift: TShiftState); override;
    procedure ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState); override;
  public
    procedure SetSelection(AStart, ATarget: Int64);

    property Cursor: Int64 read GetCursor;
    property SelStart: Int64 read GetSelStart;
    property SubClass: TACLHexViewSubClass read GetSubClass;
    property ViewInfo: TACLHexViewSubClassViewInfo read GetViewInfo;
  end;

  { TACLHexViewSubClassChararterSetViewViewInfo }

  TACLHexViewSubClassChararterSetViewViewInfo = class(TACLCompoundControlSubClassCustomViewInfo,
    IACLDraggableObject)
  strict private
    FCharacterSet: TACLHexViewCharacterSet;
    FColorEven: TColor;
    FColorOdd: TColor;
    FIndentBetweenCharacters: Integer;
  protected
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    // IACLDraggableObject
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
  public
    constructor Create(ASubClass: TACLHexViewSubClass; ACharacterSet: TACLHexViewCharacterSet); reintroduce;
    procedure Draw(ACanvas: TCanvas; AData: PByte; ADataSize: Integer);
    function MeasureHeight: Integer;
    function MeasureWidth: Integer;
    //
    property CharacterSet: TACLHexViewCharacterSet read FCharacterSet;
    property ColorEven: TColor read FColorEven write FColorEven;
    property ColorOdd: TColor read FColorOdd write FColorOdd;
    property IndentBetweenCharacters: Integer read FIndentBetweenCharacters write FIndentBetweenCharacters;
  end;

  { TACLHexViewSubClassRowViewInfo }

  TACLHexViewSubClassRowViewInfo = class(TACLCompoundControlSubClassCustomViewInfo)
  strict private
    FHexView: TACLHexViewSubClassChararterSetViewViewInfo;
    FIndentBetweenViews: Integer;
    FLabelRect: TRect;
    FLabelText: string;
    FTextView: TACLHexViewSubClassChararterSetViewViewInfo;

    function GetSubClass: TACLHexViewSubClass; inline;
  protected
    FLabelAreaWidth: Integer;
    FLabelTextColor: TColor;

    procedure DoCalculate(AChanges: TIntegerSet); override;
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    procedure Draw(ACanvas: TCanvas; const AOrigin: TPoint; AData: PByte; ADataSize: Integer);
    function MeasureHeight: Integer; virtual;
    function MeasureWidth: Integer; virtual;

    property TextView: TACLHexViewSubClassChararterSetViewViewInfo read FTextView;
    property HexView: TACLHexViewSubClassChararterSetViewViewInfo read FHexView;
    property IndentBetweenViews: Integer read FIndentBetweenViews write FIndentBetweenViews;
    property LabelText: string read FLabelText write FLabelText;
    property SubClass: TACLHexViewSubClass read GetSubClass;
  end;

  { TACLHexViewSubClassHeaderViewInfo }

  TACLHexViewSubClassHeaderViewInfo = class(TACLHexViewSubClassRowViewInfo)
  strict private
    FLinespacing: Integer;
  protected
    procedure DoCalculate(AChanges: TIntegerSet); override;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass); override;
    function MeasureHeight: Integer; override;
  end;

  { TACLHexViewSubClassSelectionViewInfo }

  TACLHexViewSubClassSelectionViewInfo = class
  strict private
    FCharsetViewInfo: TACLHexViewSubClassChararterSetViewViewInfo;
    FCursor: TRect;
    FFocused: Boolean;
    FRects: array[0..2] of TRect;
    FViewInfo: TACLHexViewSubClassViewInfo;

    function GetStyle: TACLHexViewStyle; inline;
  public
    constructor Create(AViewInfo: TACLHexViewSubClassViewInfo;
      ACharsetViewInfo: TACLHexViewSubClassChararterSetViewViewInfo);
    procedure Calculate;
    function CalculateCharBounds(AOffset: Int64; ADiscardNegativeOffset: Boolean = False): TRect;
    procedure Draw(ACanvas: TCanvas; const AOrigin: TPoint);
    //
    property CharsetViewInfo: TACLHexViewSubClassChararterSetViewViewInfo read FCharsetViewInfo;
    property Focused: Boolean read FFocused write FFocused;
    property Style: TACLHexViewStyle read GetStyle;
    property ViewInfo: TACLHexViewSubClassViewInfo read FViewInfo;
  end;

  { TACLHexViewSubClassSelectionDragObject }

  TACLHexViewSubClassSelectionDragObject = class(TACLCompoundControlSubClassDragObject)
  strict private
    FContentArea: TRect;
    FSavedSelLength: Int64;
    FSavedSelStart: Int64;
    FScrollableArea: TRect;
    FStartPosition: Int64;
    FSubClass: TACLHexViewSubClass;

    function GetHitTest: TACLHitTestInfo;
    procedure UpdateSelection;
  public
    constructor Create(ASubClass: TACLHexViewSubClass);
    function DragStart: Boolean; override;
    procedure DragMove(const P: TPoint; var ADeltaX: Integer; var ADeltaY: Integer); override;
    procedure DragFinished(ACanceled: Boolean); override;
    //
    property HitTest: TACLHitTestInfo read GetHitTest;
    property SubClass: TACLHexViewSubClass read FSubClass;
  end;

  { TACLHexViewSubClassViewInfo }

  TACLHexViewSubClassViewInfo = class(TACLCompoundControlSubClassScrollContainerViewInfo)
  protected type
    TPane = (pHex, pText);
  strict private const
    HexHeaderData: array[0..acHexViewBytesPerRow - 1] of Byte = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
    IndentBetweenViews = 16;
    Padding = 6;
    function GetRowsAreaClipRect: TRect;
  strict private
    FBuffer: TACLByteBuffer;
    FBufferPosition: Int64;
    FFocusedPane: TPane;
    FHeaderHeight: Integer;
    FHeaderViewInfo: TACLHexViewSubClassHeaderViewInfo;
    FHexSelection: TACLHexViewSubClassSelectionViewInfo;
    FRowHeight: Integer;
    FRowViewInfo: TACLHexViewSubClassRowViewInfo;
    FTextSelection: TACLHexViewSubClassSelectionViewInfo;

    function GetRowsArea: TRect;
    function GetSubClass: TACLHexViewSubClass; inline;
    function GetVisibleRowCount: Integer;
    procedure SetBufferPosition(const AValue: Int64);
    procedure SetFocusedPane(const Value: TPane);
  protected
    procedure CalculateContentLayout; override;
    procedure CalculateSelection;
    procedure CalculateSubCells(const AChanges: TIntegerSet); override;
    procedure CheckBufferCapacity(ACapacity: Integer);
    procedure ContentScrolled(ADeltaX, ADeltaY: Integer); override;
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    procedure DoDraw(ACanvas: TCanvas); override;
    function GetScrollInfo(AKind: TScrollBarKind; out AInfo: TACLScrollInfo): Boolean; override;
    procedure PopulateData;
    procedure RecreateSubCells; override;
    //
    property BufferPosition: Int64 read FBufferPosition write SetBufferPosition;
    property RowHeight: Integer read FRowHeight;
    property RowsArea: TRect read GetRowsArea;
    property RowsAreaClipRect: TRect read GetRowsAreaClipRect;
    property VisibleRowCount: Integer read GetVisibleRowCount;
  public
    constructor Create(AOwner: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    //
    property FocusedPane: TPane read FFocusedPane write SetFocusedPane;
    property HexSelection: TACLHexViewSubClassSelectionViewInfo read FHexSelection;
    property SubClass: TACLHexViewSubClass read GetSubClass;
    property TextSelection: TACLHexViewSubClassSelectionViewInfo read FTextSelection;
  end;

  { TACLHexView }

  TACLHexView = class(TACLCompoundControl)
  strict private
    FBorders: TACLBorders;

    function GetData: TStream; inline;
    function GetOnSelect: TNotifyEvent;
    function GetSelLength: Int64;
    function GetSelStart: Int64;
    function GetStyle: TACLHexViewStyle; inline;
    function GetSubClass: TACLHexViewSubClass; inline;
    procedure SetBorders(AValue: TACLBorders);
    procedure SetData(AValue: TStream); inline;
    procedure SetOnSelect(const Value: TNotifyEvent);
    procedure SetSelLength(const Value: Int64);
    procedure SetSelStart(const Value: Int64);
    procedure SetStyle(AValue: TACLHexViewStyle); inline;
    //
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    function CreateSubClass: TACLCompoundControlSubClass; override;
    procedure DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect); override;
    function GetBackgroundStyle: TACLControlBackgroundStyle; override;
    function GetContentOffset: TRect; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure CopyToClipboard; overload;
    procedure CopyToClipboard(AEncoding: TEncoding); overload;
    function GetSelectedBytes: TBytes;
    procedure SelectAll;
    procedure SetSelection(const AStart, ALength: Int64);

    property Data: TStream read GetData write SetData;
    property FocusOnClick default True;
    property SelLength: Int64 read GetSelLength write SetSelLength;
    property SelStart: Int64 read GetSelStart write SetSelStart;
    property SubClass: TACLHexViewSubClass read GetSubClass;
  published
    property Borders: TACLBorders read FBorders write SetBorders default acAllBorders;
    property ResourceCollection;
    property Style: TACLHexViewStyle read GetStyle write SetStyle;
    property StyleScrollBox;
    property Transparent;

    property OnSelect: TNotifyEvent read GetOnSelect write SetOnSelect;
  end;

function FormatHex(const ABytes: TBytes): string;
implementation

uses
  Math, AnsiStrings, ACL.Utils.DPIAware;

const
  acHexViewHitDataOffset = 'DataOffset';

function FormatHex(const ABytes: TBytes): string;
var
  S: TStringBuilder;
  I: Integer;
begin
  if ABytes = nil then
    Exit(EmptyStr);

  S := TStringBuilder.Create;
  try
    S.Capacity := Length(ABytes) * 3;
    for I := 0 to Length(ABytes) - 1 do
    begin
      if I > 0 then
        S.Append(' ');
      S.Append(IntToHex(ABytes[I], 2));
    end;
    Result := S.ToString;
  finally
    S.Free;
  end;
end;

{ TACLHexViewStyle }

procedure TACLHexViewStyle.DrawBorder(ACanvas: TCanvas; const R: TRect; const ABorders: TACLBorders);
begin
  acDrawComplexFrame(ACanvas.Handle, R, ColorBorder1.Value, ColorBorder2.Value, ABorders);
end;

procedure TACLHexViewStyle.DrawContent(ACanvas: TCanvas; const R: TRect);
begin
  acDrawGradient(ACanvas.Handle, R, ColorContent1.Value, ColorContent2.Value);
end;

function TACLHexViewStyle.IsTransparentBackground: Boolean;
begin
  Result := acIsSemitransparentFill(ColorContent1, ColorContent2);
end;

procedure TACLHexViewStyle.InitializeResources;
begin
  inherited;
  ColorBorder1.InitailizeDefaults('Common.Colors.Border1', True);
  ColorBorder2.InitailizeDefaults('Common.Colors.Border2', True);
  ColorContent1.InitailizeDefaults('Common.Colors.Background1', True);
  ColorContent2.InitailizeDefaults('Common.Colors.Background2', True);
  ColorHeaderText.InitailizeDefaults('Common.Colors.TextHeader');
  ColorContentText1.InitailizeDefaults('HexView.Colors.Text1');
  ColorContentText2.InitailizeDefaults('HexView.Colors.Text2');
  ColorContentFocused.InitailizeDefaults('HexView.Colors.Focused');
  ColorContentSelected.InitailizeDefaults('HexView.Colors.Selected');
  ColorContentSelectedInactive.InitailizeDefaults('HexView.Colors.SelectedInactive');
end;

{ TACLHexView }

constructor TACLHexView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FocusOnClick := True;
  FBorders := acAllBorders;
  TabStop := True;
end;

procedure TACLHexView.CopyToClipboard;
begin
  SubClass.CopyToClipboard;
end;

procedure TACLHexView.CopyToClipboard(AEncoding: TEncoding);
begin
  SubClass.CopyToClipboard(AEncoding);
end;

function TACLHexView.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLHexViewSubClass.Create(Self);
end;

procedure TACLHexView.DrawOpaqueBackground(ACanvas: TCanvas; const R: TRect);
begin
  Style.DrawContent(ACanvas, R);
  Style.DrawBorder(ACanvas, R, Borders);
end;

function TACLHexView.GetBackgroundStyle: TACLControlBackgroundStyle;
begin
  if Transparent then
    Result := cbsTransparent
  else
    if Style.IsTransparentBackground then
      Result := cbsSemitransparent
    else
      Result := cbsOpaque;
end;

function TACLHexView.GetContentOffset: TRect;
begin
  Result := acMarginGetReal(acBorderOffsets, Borders);
end;

function TACLHexView.GetData: TStream;
begin
  Result := SubClass.Data;
end;

function TACLHexView.GetOnSelect: TNotifyEvent;
begin
  Result := SubClass.OnSelect;
end;

function TACLHexView.GetSelLength: Int64;
begin
  Result := SubClass.SelLength;
end;

function TACLHexView.GetSelStart: Int64;
begin
  Result := SubClass.SelStart;
end;

function TACLHexView.GetStyle: TACLHexViewStyle;
begin
  Result := SubClass.Style;
end;

function TACLHexView.GetSubClass: TACLHexViewSubClass;
begin
  Result := TACLHexViewSubClass(inherited SubClass);
end;

procedure TACLHexView.SetBorders(AValue: TACLBorders);
begin
  if AValue <> FBorders then
  begin
    FBorders := AValue;
    BoundsChanged;
    Realign;
  end;
end;

procedure TACLHexView.SetData(AValue: TStream);
begin
  SubClass.Data := AValue;
end;

procedure TACLHexView.SetOnSelect(const Value: TNotifyEvent);
begin
  SubClass.OnSelect := Value;
end;

function TACLHexView.GetSelectedBytes: TBytes;
begin
  Result := SubClass.GetSelectedBytes;
end;

procedure TACLHexView.SelectAll;
begin
  SubClass.SelectAll;
end;

procedure TACLHexView.SetSelection(const AStart, ALength: Int64);
begin
  SubClass.SetSelection(AStart, ALength);
end;

procedure TACLHexView.SetSelLength(const Value: Int64);
begin
  SubClass.SetSelection(SelStart, Value);
end;

procedure TACLHexView.SetSelStart(const Value: Int64);
begin
  SubClass.SetSelection(Value, SelLength);
end;

procedure TACLHexView.SetStyle(AValue: TACLHexViewStyle);
begin
  SubClass.Style.Assign(AValue);
end;

procedure TACLHexView.WMGetDlgCode(var AMessage: TWMGetDlgCode);
begin
  AMessage.Result := DLGC_WANTARROWS;
end;

{ TACLHexViewCharacterSet }

destructor TACLHexViewCharacterSet.Destroy;
begin
  ReleaseViewInfo;
  inherited;
end;

function TACLHexViewCharacterSet.CreateData(AIndex: Byte): string;
begin
  Result := WideChar(AIndex);
end;

procedure TACLHexViewCharacterSet.CreateViewInfo;
var
  AIndex: Byte;
begin
  FEmptyCharView := TACLTextViewInfo.Create(MeasureCanvas.Handle, Font, EmptyChar);
  FSize := FEmptyCharView.Size;
  for AIndex := Low(AIndex) to High(AIndex) do
  begin
    FData[AIndex] := CreateData(AIndex);
    FView[AIndex] := TACLTextViewInfo.Create(MeasureCanvas.Handle, Font, FData[AIndex]);
    FSize := acSizeMax(FSize, FView[AIndex].Size);
  end;
end;

procedure TACLHexViewCharacterSet.ReleaseViewInfo;
var
  AIndex: Byte;
begin
  FreeAndNil(FEmptyCharView);
  for AIndex := Low(AIndex) to High(AIndex) do
    FreeAndNil(FView[AIndex]);
end;

function TACLHexViewCharacterSet.GetView(Index: Byte): TACLTextViewInfo;
begin
  Result := FView[Index];
  if Result.Size.cx = 0 then
    Result := FEmptyCharView;
end;

procedure TACLHexViewCharacterSet.SetFont(AValue: TACLFontInfo);
begin
  if FFont <> AValue then
  begin
    ReleaseViewInfo;
    FFont := AValue;
    CreateViewInfo;
  end;
end;

{ TACLHexViewHexCharacterSet }

function TACLHexViewHexCharacterSet.CreateData(AIndex: Byte): string;
begin
  Result := IntToHex(AIndex, 2);
end;

{ TACLHexViewSubClass }

constructor TACLHexViewSubClass.Create(AOwner: TComponent);
begin
  FCharacters := TACLHexViewCharacterSet.Create;
  FCharactersHex := TACLHexViewHexCharacterSet.Create;
  FStyle := CreateStyle;
  inherited;
end;

destructor TACLHexViewSubClass.Destroy;
begin
  FreeAndNil(FCharactersHex);
  FreeAndNil(FCharacters);
  FreeAndNil(FStyle);
  inherited;
end;

procedure TACLHexViewSubClass.BeforeDestruction;
begin
  inherited;
  Data := nil;
end;

procedure TACLHexViewSubClass.CopyToClipboard;
begin
  if ViewInfo.FocusedPane = pHex then
    CopyToClipboard(FormatHex)
  else
    CopyToClipboard(acStringFromBytes);
end;

procedure TACLHexViewSubClass.CopyToClipboard(AEncoding: TEncoding);
begin
  CopyToClipboard(AEncoding.GetString);
end;

procedure TACLHexViewSubClass.CopyToClipboard(AEncodeProc: TEncodeProc);

  function BytesToString(const ABytes: TBytes): string;
  begin
    if ABytes <> nil then
    try
      Result := AEncodeProc(ABytes);
    except
      Result := '';
    end
    else
      Result := '';
  end;

begin
  acCopyStringToClipboard(BytesToString(GetSelectedBytes));
end;

function TACLHexViewSubClass.GetSelectedBytes: TBytes;
begin
  if Data <> nil then
  begin
    SetLength(Result, SelLength);
    Data.Position := SelStart;
    Data.ReadBuffer(Result, SelLength);
  end
  else
    Result := nil;
end;

procedure TACLHexViewSubClass.MakeVisible(const ACharPosition: Int64);
var
  ACharBounds: TRect;
  ADelta: TPoint;
  ASelection: TACLHexViewSubClassSelectionViewInfo;
  AViewBounds: TRect;
begin
  if ViewInfo.FocusedPane = pHex then
    ASelection := ViewInfo.HexSelection
  else
    ASelection := ViewInfo.TextSelection;

  AViewBounds := ViewInfo.RowsAreaClipRect;
  ACharBounds := ASelection.CalculateCharBounds(ACharPosition, False);
  ACharBounds := acRectOffset(ACharBounds, ViewInfo.RowsArea.TopLeft);
  ADelta.X := acCalculateMakeVisibleDelta(ACharBounds.Left, ACharBounds.Right, AViewBounds.Left, AViewBounds.Right);
  ADelta.Y := acCalculateMakeVisibleDelta(ACharBounds.Top, ACharBounds.Bottom, AViewBounds.Top, AViewBounds.Bottom);
  ViewInfo.Viewport := acPointOffset(ViewInfo.Viewport, ADelta);
end;

procedure TACLHexViewSubClass.SelectAll;
begin
  SetSelection(0, DataSize);
end;

procedure TACLHexViewSubClass.SetSelection(AStart, ALength: Int64);
begin
  AStart := MaxMin(AStart, 0, FDataSize - 1);
  ALength := MaxMin(ALength, 0, FDataSize - AStart);
  if (AStart <> FSelStart) or (ALength <> FSelLength) then
  begin
    BeginUpdate;
    try
      FSelStart := AStart;
      FSelLength := ALength;
      Cursor := Cursor;
      Changed([hvcLayout]);
    finally
      EndUpdate;
    end;
    DoSelectionChanged;
  end;
end;

procedure TACLHexViewSubClass.SetTargetDPI(AValue: Integer);
begin
  Style.SetTargetDPI(AValue);
  inherited SetTargetDPI(AValue);
end;

function TACLHexViewSubClass.CreateStyle: TACLHexViewStyle;
begin
  Result := TACLHexViewStyle.Create(Self);
end;

function TACLHexViewSubClass.CreateController: TACLCompoundControlSubClassController;
begin
  Result := TACLHexViewSubClassController.Create(Self);
end;

function TACLHexViewSubClass.CreateViewInfo: TACLCompoundControlSubClassCustomViewInfo;
begin
  Result := TACLHexViewSubClassViewInfo.Create(Self);
end;

procedure TACLHexViewSubClass.DoSelectionChanged;
begin
  CallNotifyEvent(Self, OnSelect);
end;

function TACLHexViewSubClass.GetController: TACLHexViewSubClassController;
begin
  Result := TACLHexViewSubClassController(inherited Controller);
end;

function TACLHexViewSubClass.GetPositionFromHitTest(AHitTestInfo: TACLHitTestInfo): Int64;
begin
  Result := ViewInfo.BufferPosition + Integer(AHitTestInfo.HitObjectData[acHexViewHitDataOffset]);
end;

function TACLHexViewSubClass.GetSelFinish: Int64;
begin
  Result := SelStart + Max(SelLength - 1, 0);
end;

procedure TACLHexViewSubClass.ProcessChanges(AChanges: TIntegerSet = []);
begin
  inherited;
  if hvcMakeVisible in AChanges then
    MakeVisible(Cursor);
end;

procedure TACLHexViewSubClass.ResourceChanged;
begin
  UpdateCharacters;
  inherited;
end;

procedure TACLHexViewSubClass.UpdateCharacters;
var
  AFontInfo: TACLFontInfo;
begin
  AFontInfo := TACLFontCache.GetInfo(Font);
  Characters.Font := AFontInfo;
  CharactersHex.Font := AFontInfo;
end;

function TACLHexViewSubClass.GetViewInfo: TACLHexViewSubClassViewInfo;
begin
  Result := TACLHexViewSubClassViewInfo(inherited ViewInfo);
end;

procedure TACLHexViewSubClass.SetCursor(AValue: Int64);
begin
  AValue := EnsureRange(AValue, SelStart, SelFinish);
  if AValue <> FCursor then
  begin
    FCursor := AValue;
    Changed([hvcLayout, hvcMakeVisible]);
  end;
end;

procedure TACLHexViewSubClass.SetData(AValue: TStream);
begin
  if FData <> AValue then
  begin
    FData := AValue;
    if FData <> nil then
      FDataSize := FData.Size
    else
      FDataSize := 0;

    SetSelection(0, 0);
    FullRefresh;
  end;
end;

{ TACLHexViewSubClassController }

procedure TACLHexViewSubClassController.ProcessKeyDown(AKey: Word; AShift: TShiftState);

  procedure MoveCursor(ACursor: Int64; AGranularity: Integer = 0);
  begin
    while (ACursor < 0) and (AGranularity > 0) do
      Inc(ACursor, AGranularity);
    while (ACursor > SubClass.DataSize) and (AGranularity > 0) do
      Dec(ACursor, AGranularity);
    if InRange(ACursor, 0, SubClass.DataSize) then
    begin
      if ssShift in AShift then
        SetSelection(FSelectionStart, ACursor)
      else
        SetSelection(ACursor, ACursor);
    end;
  end;

begin
  inherited;

  case AKey of
    VK_SHIFT:
      FSelectionStart := SelStart;

    VK_LEFT:
      MoveCursor(Cursor - 1);
    VK_RIGHT:
      MoveCursor(Cursor + 1);
    VK_UP:
      MoveCursor(Cursor - acHexViewBytesPerRow, acHexViewBytesPerRow);
    VK_DOWN:
      MoveCursor(Cursor + acHexViewBytesPerRow, acHexViewBytesPerRow);
    VK_PRIOR:
      MoveCursor(Cursor - acHexViewBytesPerRow * ViewInfo.VisibleRowCount, acHexViewBytesPerRow);
    VK_NEXT:
      MoveCursor(Cursor + acHexViewBytesPerRow * ViewInfo.VisibleRowCount, acHexViewBytesPerRow);

    VK_END:
      if ssCtrl in AShift then
        MoveCursor(SubClass.DataSize)
      else
        MoveCursor(Cursor - Cursor mod acHexViewBytesPerRow + acHexViewBytesPerRow - 1);

    VK_HOME:
      if ssCtrl in AShift then
        MoveCursor(0)
      else
        MoveCursor(Cursor - Cursor mod acHexViewBytesPerRow);

    Ord('A'):
      if ssCtrl in AShift then
        SubClass.SelectAll;
  end;
end;

procedure TACLHexViewSubClassController.ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState);
var
  ACursor: Integer;
begin
  if (AButton = mbLeft) and (HitTest.HitObject is TACLHexViewSubClassChararterSetViewViewInfo) then
  begin
    ACursor := SubClass.GetPositionFromHitTest(HitTest);
    if ssShift in AShift then
      SetSelection(FSelectionStart, ACursor)
    else
      SetSelection(ACursor, ACursor);
  end;
  inherited;
end;

procedure TACLHexViewSubClassController.ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState);
begin
  inherited;

  if HitTest.HitObject is TACLHexViewSubClassChararterSetViewViewInfo then
  begin
    if TACLHexViewSubClassChararterSetViewViewInfo(HitTest.HitObject).CharacterSet = SubClass.CharactersHex then
      ViewInfo.FocusedPane := pHex
    else
      ViewInfo.FocusedPane := pText;
  end;
end;

procedure TACLHexViewSubClassController.ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState);
begin
  ViewInfo.ScrollByMouseWheel(ADirection, AShift);
end;

procedure TACLHexViewSubClassController.SetSelection(AStart, ATarget: Int64);
var
  ACursor: Int64;
begin
  ACursor := ATarget;
  if ATarget < AStart then
    acExchangeInt64(AStart, ATarget);

  SubClass.BeginUpdate;
  try
    SubClass.SetSelection(AStart, ATarget - AStart + 1);
    SubClass.Cursor := ACursor;
  finally
    SubClass.EndUpdate;
  end;
end;

function TACLHexViewSubClassController.GetCursor: Int64;
begin
  Result := SubClass.Cursor;
end;

function TACLHexViewSubClassController.GetSelStart: Int64;
begin
  Result := SubClass.SelStart;
end;

function TACLHexViewSubClassController.GetSubClass: TACLHexViewSubClass;
begin
  Result := TACLHexViewSubClass(inherited SubClass);
end;

function TACLHexViewSubClassController.GetViewInfo: TACLHexViewSubClassViewInfo;
begin
  Result := SubClass.ViewInfo;
end;

{ TACLHexViewSubClassChararterSetViewViewInfo }

constructor TACLHexViewSubClassChararterSetViewViewInfo.Create(ASubClass: TACLHexViewSubClass; ACharacterSet: TACLHexViewCharacterSet);
begin
  inherited Create(ASubClass);
  FCharacterSet := ACharacterSet;
end;

procedure TACLHexViewSubClassChararterSetViewViewInfo.Draw(ACanvas: TCanvas; AData: PByte; ADataSize: Integer);
var
  APrevTextColor: Cardinal;
  ASize: TSize;
  ATextColor1: Cardinal;
  ATextColor2: Cardinal;
  ATextViewInfo: TACLTextViewInfo;
  DC: HDC;
  X, Y: Integer;
begin
  X := Bounds.Left;
  Y := Bounds.Top;
  ASize := FCharacterSet.Size;
  DC := ACanvas.Handle;
  ATextColor1 := FColorOdd;
  ATextColor2 := FColorEven;
  APrevTextColor := GetTextColor(DC);
  while ADataSize > 0 do
  begin
    SetTextColor(DC, ATextColor1);
    ATextViewInfo := FCharacterSet.View[AData^];
    ATextViewInfo.Draw(ACanvas.Handle, X + (ASize.cx - ATextViewInfo.Size.cx) div 2, Y);
    acExchangeIntegers(ATextColor1, ATextColor2);
    Inc(X, ASize.cx + IndentBetweenCharacters);
    Dec(ADataSize);
    Inc(AData);
  end;
  SetTextColor(DC, APrevTextColor);
end;

function TACLHexViewSubClassChararterSetViewViewInfo.MeasureHeight: Integer;
begin
  Result := FCharacterSet.Size.cy;
end;

function TACLHexViewSubClassChararterSetViewViewInfo.MeasureWidth: Integer;
begin
  Result := FCharacterSet.Size.cx * acHexViewBytesPerRow + FIndentBetweenCharacters * (acHexViewBytesPerRow - 1);
end;

function TACLHexViewSubClassChararterSetViewViewInfo.CreateDragObject(
  const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlSubClassDragObject;
begin
  Result := TACLHexViewSubClassSelectionDragObject.Create(TACLHexViewSubClass(SubClass));
end;

procedure TACLHexViewSubClassChararterSetViewViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
var
  I: Integer;
  O: Integer;
  W: Integer;
  X: Integer;
begin
  X := Bounds.Left;
  W := FCharacterSet.Size.cx;
  O := IndentBetweenCharacters div 2;
  for I := 0 to acHexViewBytesPerRow - 1 do
  begin
    if InRange(AInfo.HitPoint.X, X - O, X + W + O) then
    begin
      AInfo.HitObject := Self;
      AInfo.HitObjectData[acHexViewHitDataOffset] := TObject(I);
      Break;
    end;
    Inc(X, W + IndentBetweenCharacters);
  end;
end;

{ TACLHexViewSubClassRowViewInfo }

constructor TACLHexViewSubClassRowViewInfo.Create;
begin
  inherited;
  FTextView := TACLHexViewSubClassChararterSetViewViewInfo.Create(SubClass, SubClass.Characters);
  FHexView := TACLHexViewSubClassChararterSetViewViewInfo.Create(SubClass, SubClass.CharactersHex);
end;

destructor TACLHexViewSubClassRowViewInfo.Destroy;
begin
  FreeAndNil(FTextView);
  FreeAndNil(FHexView);
  inherited;
end;

procedure TACLHexViewSubClassRowViewInfo.Draw(ACanvas: TCanvas; const AOrigin: TPoint; AData: PByte; ADataSize: Integer);
var
  AWindowOrg: TPoint;
begin
  AWindowOrg := acMoveWindowOrg(ACanvas.Handle, AOrigin);
  try
    ACanvas.Font.Color := FLabelTextColor;
    acTextOut(ACanvas.Handle, FLabelRect.Left, FLabelRect.Top, LabelText, 0);
    HexView.Draw(ACanvas, AData, ADataSize);
    TextView.Draw(ACanvas, AData, ADataSize);
  finally
    acRestoreWindowOrg(ACanvas.Handle, AWindowOrg);
  end;
end;

function TACLHexViewSubClassRowViewInfo.MeasureHeight: Integer;
begin
  Result := Max(TextView.MeasureHeight, HexView.MeasureHeight);
end;

function TACLHexViewSubClassRowViewInfo.MeasureWidth: Integer;
begin
  Result := FLabelAreaWidth + IndentBetweenViews + HexView.MeasureWidth + IndentBetweenViews + TextView.MeasureWidth;
end;

procedure TACLHexViewSubClassRowViewInfo.DoCalculate(AChanges: TIntegerSet);
var
  ARect: TRect;
begin
  inherited;

  HexView.IndentBetweenCharacters := ScaleFactor.Apply(4);

  ARect := Bounds;
  FLabelAreaWidth := acTextSize(SubClass.Font, '00000000').cx;
  FLabelRect := acRectSetWidth(ARect, FLabelAreaWidth);
  Inc(ARect.Left, FLabelAreaWidth + IndentBetweenViews);
  HexView.Calculate(acRectSetWidth(ARect, HexView.MeasureWidth), []);
  ARect.Left := FHexView.Bounds.Right + IndentBetweenViews;
  TextView.Calculate(acRectSetWidth(ARect, TextView.MeasureWidth), []);

  HexView.ColorOdd := SubClass.Style.ColorContentText1.AsColor;
  HexView.ColorEven := SubClass.Style.ColorContentText2.AsColor;
  TextView.ColorOdd := SubClass.Style.ColorContentText1.AsColor;
  TextView.ColorEven := SubClass.Style.ColorContentText1.AsColor;

  FLabelTextColor := SubClass.Style.ColorHeaderText.AsColor;
end;

procedure TACLHexViewSubClassRowViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
begin
  if not (HexView.CalculateHitTest(AInfo) or TextView.CalculateHitTest(AInfo)) then
    inherited;
end;

function TACLHexViewSubClassRowViewInfo.GetSubClass: TACLHexViewSubClass;
begin
  Result := TACLHexViewSubClass(inherited SubClass);
end;

{ TACLHexViewSubClassHeaderViewInfo }

constructor TACLHexViewSubClassHeaderViewInfo.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited;
  LabelText := 'Offset (h)';
end;

procedure TACLHexViewSubClassHeaderViewInfo.DoCalculate(AChanges: TIntegerSet);
var
  AMetric: TTextMetric;
begin
  inherited;

  HexView.ColorOdd := FLabelTextColor;
  HexView.ColorEven := FLabelTextColor;
  TextView.ColorOdd := FLabelTextColor;
  TextView.ColorEven := FLabelTextColor;

  MeasureCanvas.Font := SubClass.Font;
  GetTextMetrics(MeasureCanvas.Handle, AMetric);
  FLinespacing := IndentBetweenViews - AMetric.tmDescent;
end;

function TACLHexViewSubClassHeaderViewInfo.MeasureHeight: Integer;
begin
  Result := inherited + FLinespacing;
end;

{ TACLHexViewSubClassSelectionViewInfo }

constructor TACLHexViewSubClassSelectionViewInfo.Create(AViewInfo: TACLHexViewSubClassViewInfo;
  ACharsetViewInfo: TACLHexViewSubClassChararterSetViewViewInfo);
begin
  FViewInfo := AViewInfo;
  FCharsetViewInfo := ACharsetViewInfo;
end;

procedure TACLHexViewSubClassSelectionViewInfo.Calculate;
var
  ASelFinish: TRect;
  ASelStart: TRect;
begin
  FRects[0] := NullRect;
  FRects[1] := NullRect;
  FRects[2] := NullRect;
  if ViewInfo.SubClass.SelLength > 1 then
  begin
    ASelStart := CalculateCharBounds(ViewInfo.SubClass.SelStart, True);
    ASelFinish := CalculateCharBounds(ViewInfo.SubClass.SelFinish, True);
    if ASelFinish.Top > ASelStart.Top then
    begin
      FRects[0] := Rect(ASelStart.Left, ASelStart.Top, CharsetViewInfo.Bounds.Right, ASelStart.Bottom);
      FRects[1] := Rect(CharsetViewInfo.Bounds.Left, ASelStart.Bottom, CharsetViewInfo.Bounds.Right, ASelFinish.Top);
      FRects[2] := Rect(CharsetViewInfo.Bounds.Left, ASelFinish.Top, ASelFinish.Right, ASelFinish.Bottom);
    end
    else
      FRects[0] := Rect(ASelStart.TopLeft, ASelFinish.BottomRight);
  end;

  if ViewInfo.SubClass.Data <> nil then
    FCursor := CalculateCharBounds(ViewInfo.SubClass.Cursor)
  else
    FCursor := NullRect;
end;

function TACLHexViewSubClassSelectionViewInfo.CalculateCharBounds(AOffset: Int64; ADiscardNegativeOffset: Boolean = False): TRect;
var
  AColIndex: Integer;
  AIndent: Integer;
  ARowIndex: Integer;
  ASize: TSize;
begin
  Dec(AOffset, ViewInfo.BufferPosition);
  if ADiscardNegativeOffset then
    AOffset := Max(AOffset, 0); // for optimization purposes only

  ARowIndex := AOffset div acHexViewBytesPerRow;
  if AOffset < 0 then
  begin
    Dec(AOffset, ARowIndex * acHexViewBytesPerRow);
    if AOffset < 0 then
    begin
      Dec(ARowIndex);
      Inc(AOffset, acHexViewBytesPerRow);
    end;
  end;
  AColIndex := AOffset mod acHexViewBytesPerRow;

  ASize := CharsetViewInfo.CharacterSet.Size;
  AIndent := CharsetViewInfo.IndentBetweenCharacters;
  Result.Left := CharsetViewInfo.Bounds.Left + Max((ASize.cx + AIndent) * AColIndex - AIndent div 2, 0);
  Result.Right := Min(CharsetViewInfo.Bounds.Right, Result.Left + ASize.cx + AIndent);
  Result.Top := CharsetViewInfo.Bounds.Top + ViewInfo.RowHeight * ARowIndex;
  Result.Bottom := Result.Top + ViewInfo.RowHeight;
end;

procedure TACLHexViewSubClassSelectionViewInfo.Draw(ACanvas: TCanvas; const AOrigin: TPoint);
var
  AColor: TAlphaColor;
  AWindowOrg: TPoint;
  I: Integer;
begin
  AWindowOrg := acMoveWindowOrg(ACanvas.Handle, AOrigin);
  try
    if Focused then
      AColor := Style.ColorContentSelected.Value
    else
      AColor := Style.ColorContentSelectedInactive.Value;

    for I := Low(FRects) to High(FRects) do
      acFillRect(ACanvas.Handle, FRects[I], AColor);

    if Focused then
      acFillRect(ACanvas.Handle, FCursor, Style.ColorContentFocused.Value)
    else
      if acRectIsEmpty(FRects[0]) then // no multiple selection
        acFillRect(ACanvas.Handle, FCursor, AColor);
  finally
    acRestoreWindowOrg(ACanvas.Handle, AWindowOrg);
  end;
end;

function TACLHexViewSubClassSelectionViewInfo.GetStyle: TACLHexViewStyle;
begin
  Result := FViewInfo.SubClass.Style;
end;

{ TACLHexViewSubClassSelectionDragObject }

constructor TACLHexViewSubClassSelectionDragObject.Create(ASubClass: TACLHexViewSubClass);
begin
  inherited Create;
  FSubClass := ASubClass;
  FStartPosition := SubClass.GetPositionFromHitTest(HitTest);
end;

procedure TACLHexViewSubClassSelectionDragObject.DragFinished(ACanceled: Boolean);
begin
  if ACanceled then
    SubClass.SetSelection(FSavedSelStart, FSavedSelLength)
  else
    UpdateSelection;

  inherited;
end;

procedure TACLHexViewSubClassSelectionDragObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);
var
  AHitPoint: TPoint;
begin
  if not acPointInRect(FContentArea, P) then
  begin
    AHitPoint.X := EnsureRange(P.X, FContentArea.Left, FContentArea.Right - 1);
    AHitPoint.Y := EnsureRange(P.Y, FContentArea.Top, FContentArea.Bottom - 1);
    SubClass.Controller.UpdateHitTest(AHitPoint);
  end;

  UpdateAutoScrollDirection(P, FScrollableArea);
  UpdateSelection;
  inherited;
end;

function TACLHexViewSubClassSelectionDragObject.DragStart: Boolean;
begin
  CreateAutoScrollTimer;
  FSavedSelStart := SubClass.SelStart;
  FSavedSelLength := SubClass.SelLength;
  FContentArea := SubClass.ViewInfo.RowsArea;
  FScrollableArea := acRectInflate(FContentArea, 0, -SubClass.ViewInfo.RowHeight);
  Result := True;
end;

function TACLHexViewSubClassSelectionDragObject.GetHitTest: TACLHitTestInfo;
begin
  Result := FSubClass.Controller.HitTest;
end;

procedure TACLHexViewSubClassSelectionDragObject.UpdateSelection;
begin
  if HitTest.HitObject is TACLHexViewSubClassChararterSetViewViewInfo then
    SubClass.Controller.SetSelection(FStartPosition, SubClass.GetPositionFromHitTest(HitTest));
end;

{ TACLHexViewSubClassViewInfo }

constructor TACLHexViewSubClassViewInfo.Create(AOwner: TACLCompoundControlSubClass);
begin
  inherited;
  FBuffer := TACLByteBuffer.Create(2);
  FRowViewInfo := TACLHexViewSubClassRowViewInfo.Create(SubClass);
  FTextSelection := TACLHexViewSubClassSelectionViewInfo.Create(Self, FRowViewInfo.TextView);
  FHexSelection := TACLHexViewSubClassSelectionViewInfo.Create(Self, FRowViewInfo.HexView);
  FHexSelection.Focused := True;
  FHeaderViewInfo := TACLHexViewSubClassHeaderViewInfo.Create(SubClass);
end;

destructor TACLHexViewSubClassViewInfo.Destroy;
begin
  FreeAndNil(FHeaderViewInfo);
  FreeAndNil(FRowViewInfo);
  FreeAndNil(FHexSelection);
  FreeAndNil(FTextSelection);
  FreeAndNil(FBuffer);
  inherited Destroy;
end;

procedure TACLHexViewSubClassViewInfo.CalculateContentLayout;
begin
  FRowViewInfo.IndentBetweenViews := ScaleFactor.Apply(IndentBetweenViews);
  FRowViewInfo.Calculate(Bounds, []);

  FHeaderViewInfo.IndentBetweenViews := ScaleFactor.Apply(IndentBetweenViews);
  FHeaderViewInfo.Calculate(Bounds, []);
  FHeaderHeight := FHeaderViewInfo.MeasureHeight;

  FRowHeight := FRowViewInfo.MeasureHeight;
  FContentSize.cx := FRowViewInfo.MeasureWidth;
  FContentSize.cy := FRowHeight * Ceil(SubClass.DataSize / acHexViewBytesPerRow) + FHeaderViewInfo.MeasureHeight;

  if FRowHeight > 0 then
    CheckBufferCapacity(((acRectHeight(Bounds) div FRowHeight) + 2) * acHexViewBytesPerRow);

  FHeaderViewInfo.Calculate(Rect(0, 0, ContentSize.cx, FHeaderHeight), []);
  FRowViewInfo.Calculate(Rect(0, 0, ContentSize.cx, FRowHeight), []);

  CalculateSelection;
end;

procedure TACLHexViewSubClassViewInfo.CalculateSelection;
begin
  FHexSelection.Calculate;
  FTextSelection.Calculate;
end;

procedure TACLHexViewSubClassViewInfo.CalculateSubCells(const AChanges: TIntegerSet);
begin
  inherited;
  FClientBounds := acRectInflate(FClientBounds, -ScaleFactor.Apply(Padding));
end;

procedure TACLHexViewSubClassViewInfo.CheckBufferCapacity(ACapacity: Integer);
begin
  if (FBuffer = nil) or (FBuffer.Size < ACapacity) then
  begin
    FreeAndNil(FBuffer);
    FBuffer := TACLByteBuffer.Create(ACapacity);
    PopulateData;
  end;
end;

procedure TACLHexViewSubClassViewInfo.ContentScrolled(ADeltaX, ADeltaY: Integer);
begin
  BufferPosition := (ViewportY div FRowHeight) * acHexViewBytesPerRow;
  inherited;
end;

procedure TACLHexViewSubClassViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
var
  ADataOffset: Integer;
  ARowRect: TRect;
begin
  inherited;

  if (FRowHeight > 0) and acPointInRect(RowsArea, AInfo.HitPoint) then
  begin
    ADataOffset := 0;
    ARowRect := acRectSetHeight(RowsArea, FRowHeight);
    while (ARowRect.Top < FClientBounds.Bottom) and (ADataOffset < FBuffer.Used) do
    begin
      if acPointInRect(ARowRect, AInfo.HitPoint) then
      begin
        AInfo.HitPoint := acPointOffset(AInfo.HitPoint, -ARowRect.Left, -ARowRect.Top);
        try
          if FRowViewInfo.CalculateHitTest(AInfo) then
            AInfo.HitObjectData[acHexViewHitDataOffset] := TObject(ADataOffset + Integer(AInfo.HitObjectData[acHexViewHitDataOffset]));
        finally
          AInfo.HitPoint := acPointOffset(AInfo.HitPoint, ARowRect.Left, ARowRect.Top);
        end;
        Break;
      end;
      ARowRect := acRectOffset(ARowRect, 0, FRowHeight);
      Inc(ADataOffset, acHexViewBytesPerRow);
    end;
  end;
end;

procedure TACLHexViewSubClassViewInfo.DoDraw(ACanvas: TCanvas);
var
  AClipRegion: HRGN;
  AData: PByte;
  ADataOffset: Integer;
  ADataSize: Integer;
  ARowRect: TRect;
  ARowsArea: TRect;
begin
  inherited;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Font := SubClass.Font;

  AClipRegion := acSaveClipRegion(ACanvas.Handle);
  try
    if acIntersectClipRegion(ACanvas.Handle, FClientBounds) then
    begin
      ARowRect := acRectSetHeight(FClientBounds, FHeaderHeight);
      Dec(ARowRect.Left, ViewportX);
      FHeaderViewInfo.Draw(ACanvas, ARowRect.TopLeft, @HexHeaderData[0], Length(HexHeaderData));
      acExcludeFromClipRegion(ACanvas.Handle, ARowRect);

      ADataOffset := 0;
      ARowsArea := RowsArea;

      HexSelection.Draw(ACanvas, ARowsArea.TopLeft);
      TextSelection.Draw(ACanvas, ARowsArea.TopLeft);

      ARowRect := acRectSetHeight(ARowsArea, FRowHeight);
      while (ARowRect.Top < FClientBounds.Bottom) and (ADataOffset < FBuffer.Used) do
      begin
        AData := @FBuffer.DataArr^[ADataOffset];
        ADataSize := MinMax(FBuffer.Used - ADataOffset, 0, acHexViewBytesPerRow);
        FRowViewInfo.LabelText := IntToHex(FBufferPosition + ADataOffset, 8);
        FRowViewInfo.Draw(ACanvas, ARowRect.TopLeft, AData, ADataSize);
        ARowRect := acRectOffset(ARowRect, 0, FRowHeight);
        Inc(ADataOffset, acHexViewBytesPerRow);
      end;
    end;
  finally
    acRestoreClipRegion(ACanvas.Handle, AClipRegion);
  end;
end;

function TACLHexViewSubClassViewInfo.GetScrollInfo(AKind: TScrollBarKind; out AInfo: TACLScrollInfo): Boolean;
begin
  Result := inherited;
  if Result and (AKind = sbVertical) then
    AInfo.LineSize := FRowHeight;
end;

procedure TACLHexViewSubClassViewInfo.RecreateSubCells;
begin
  FreeAndNil(FBuffer);
end;

procedure TACLHexViewSubClassViewInfo.PopulateData;
var
  AData: TStream;
begin
  AData := SubClass.Data;
  if AData <> nil then
  begin
    AData.Position := FBufferPosition;
    FBuffer.Used := AData.Read(FBuffer.Data^, FBuffer.Size);
  end
  else
    FBuffer.Used := 0;
end;

function TACLHexViewSubClassViewInfo.GetRowsArea: TRect;
begin
  Result := RowsAreaClipRect;
  Dec(Result.Left, ViewportX);
  Dec(Result.Top, ViewportY mod FRowHeight);
end;

function TACLHexViewSubClassViewInfo.GetRowsAreaClipRect: TRect;
begin
  Result := ClientBounds;
  Inc(Result.Top, FHeaderHeight);
end;

function TACLHexViewSubClassViewInfo.GetSubClass: TACLHexViewSubClass;
begin
  Result := TACLHexViewSubClass(inherited SubClass);
end;

function TACLHexViewSubClassViewInfo.GetVisibleRowCount: Integer;
begin
  Result := acRectHeight(RowsArea) div RowHeight;
end;

procedure TACLHexViewSubClassViewInfo.SetBufferPosition(const AValue: Int64);
begin
  if FBufferPosition <> AValue then
  begin
    FBufferPosition := AValue;
    PopulateData;
    CalculateSelection;
  end;
end;

procedure TACLHexViewSubClassViewInfo.SetFocusedPane(const Value: TPane);
begin
  if FFocusedPane <> Value then
  begin
    FFocusedPane := Value;
    TextSelection.Focused := FocusedPane = pText;
    HexSelection.Focused := FocusedPane = pHex;
    SubClass.Invalidate;
  end;
end;

end.
