{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*              HexView Control              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Controls.HexView;

{$I ACL.Config.inc} // FPC:OK

interface

uses
  Messages,
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  System.AnsiStrings,
  System.UITypes,
  // Vcl
  {Vcl.}Graphics,
  {Vcl.}Controls,
  {Vcl.}Forms,
  // ACL
  ACL.Classes,
  ACL.Classes.ByteBuffer,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.Graphics,
  ACL.Graphics.Ex,
  ACL.Graphics.FontCache,
  ACL.Graphics.TextLayout,
  ACL.Math,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Clipboard,
  ACL.Utils.Strings;

const
  acHexViewBytesPerRow = 16;

  hvcLayout = cccnLayout;
  hvcMakeVisible = cccnLast + 1;
  hvcLast = hvcMakeVisible;

type
  TACLHexViewViewInfo = class;

  { TACLHexViewStyle }

  TACLHexViewStyle = class(TACLStyleBackground)
  protected
    procedure InitializeResources; override;
  published
    property ColorContentFocused: TACLResourceColor index 4 read GetColor write SetColor stored IsColorStored;
    property ColorContentSelected: TACLResourceColor index 5 read GetColor write SetColor stored IsColorStored;
    property ColorContentSelectedInactive: TACLResourceColor index 6 read GetColor write SetColor stored IsColorStored;
    property ColorContentText1: TACLResourceColor index 7 read GetColor write SetColor stored IsColorStored;
    property ColorContentText2: TACLResourceColor index 8 read GetColor write SetColor stored IsColorStored;
    property ColorHeaderText: TACLResourceColor index 9 read GetColor write SetColor stored IsColorStored;
  end;

  { TACLHexViewCharacterSet }

  TACLHexViewCharacterSet = class
  strict private const
    EmptyChar = '.';
  strict private
    FData: array[Byte] of string;
    FEmptyCharView: TACLTextViewInfo;
    FFont: TFont;
    FSize: TSize;
    FView: array[Byte] of TACLTextViewInfo;

    procedure CreateViewInfo;
    function GetView(Index: Byte): TACLTextViewInfo;
    procedure ReleaseViewInfo;
    procedure SetFont(AValue: TFont);
  protected
    function CreateData(AIndex: Byte): string; virtual;
  public
    destructor Destroy; override;
    //# Properties
    property Font: TFont read FFont write SetFont;
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
    TEncodeProc = reference to function (const ABytes: TBytes): UnicodeString;
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

    function GetSelFinish: Int64;
    function GetViewInfo: TACLHexViewViewInfo; inline;
    procedure SetCursor(AValue: Int64);
    procedure SetData(AValue: TStream);
  protected
    FSelectionStart: Int64;

    function CreateStyle: TACLHexViewStyle; virtual;
    function CreateViewInfo: TACLCompoundControlCustomViewInfo; override;
    procedure DoSelectionChanged; virtual;
    function GetPositionFromHitTest(AHitTestInfo: TACLHitTestInfo): Int64;
    procedure ProcessChanges(AChanges: TIntegerSet = []); override;
    procedure ProcessKeyDown(var AKey: Word; AShift: TShiftState); override;
    procedure ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState); override;
    procedure ProcessMouseWheel(ADirection: TACLMouseWheelDirection; AShift: TShiftState); override;
    procedure ResourceChanged; override;
    procedure Select(AStart, ATarget: Int64);
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
    //# Properties
    property Characters: TACLHexViewCharacterSet read FCharacters;
    property CharactersHex: TACLHexViewHexCharacterSet read FCharactersHex;
    property Cursor: Int64 read FCursor write SetCursor;
    property Data: TStream read FData write SetData;
    property DataSize: Int64 read FDataSize;
    property SelFinish: Int64 read GetSelFinish;
    property SelLength: Int64 read FSelLength;
    property SelStart: Int64 read FSelStart;
    property Style: TACLHexViewStyle read FStyle;
    property ViewInfo: TACLHexViewViewInfo read GetViewInfo;
    //# Events
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
  end;

  { TACLHexViewChararterSetViewViewInfo }

  TACLHexViewChararterSetViewViewInfo = class(TACLCompoundControlCustomViewInfo,
    IACLDraggableObject)
  strict private
    FCharacterSet: TACLHexViewCharacterSet;
    FColorEven: TColor;
    FColorOdd: TColor;
    FIndentBetweenCharacters: Integer;
  protected
    procedure DoCalculateHitTest(const AInfo: TACLHitTestInfo); override;
    // IACLDraggableObject
    function CreateDragObject(const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
  public
    constructor Create(ASubClass: TACLHexViewSubClass;
      ACharacterSet: TACLHexViewCharacterSet); reintroduce;
    procedure Draw(ACanvas: TCanvas; AData: PByte; ADataSize: Integer);
    function MeasureHeight: Integer;
    function MeasureWidth: Integer;
    //# Properties
    property CharacterSet: TACLHexViewCharacterSet read FCharacterSet;
    property ColorEven: TColor read FColorEven write FColorEven;
    property ColorOdd: TColor read FColorOdd write FColorOdd;
    property IndentBetweenCharacters: Integer read FIndentBetweenCharacters write FIndentBetweenCharacters;
  end;

  { TACLHexViewRowViewInfo }

  TACLHexViewRowViewInfo = class(TACLCompoundControlCustomViewInfo)
  strict private
    FHexView: TACLHexViewChararterSetViewViewInfo;
    FIndentBetweenViews: Integer;
    FLabelRect: TRect;
    FLabelText: string;
    FTextView: TACLHexViewChararterSetViewViewInfo;

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
    //# Properties
    property TextView: TACLHexViewChararterSetViewViewInfo read FTextView;
    property HexView: TACLHexViewChararterSetViewViewInfo read FHexView;
    property IndentBetweenViews: Integer read FIndentBetweenViews write FIndentBetweenViews;
    property LabelText: string read FLabelText write FLabelText;
    property SubClass: TACLHexViewSubClass read GetSubClass;
  end;

  { TACLHexViewHeaderViewInfo }

  TACLHexViewHeaderViewInfo = class(TACLHexViewRowViewInfo)
  strict private
    FLinespacing: Integer;
  protected
    procedure DoCalculate(AChanges: TIntegerSet); override;
  public
    constructor Create(ASubClass: TACLCompoundControlSubClass); override;
    function MeasureHeight: Integer; override;
  end;

  { TACLHexViewSelectionViewInfo }

  TACLHexViewSelectionViewInfo = class
  strict private
    FCharsetViewInfo: TACLHexViewChararterSetViewViewInfo;
    FCursor: TRect;
    FFocused: Boolean;
    FRects: array[0..2] of TRect;
    FViewInfo: TACLHexViewViewInfo;

    function GetStyle: TACLHexViewStyle; inline;
  public
    constructor Create(AViewInfo: TACLHexViewViewInfo;
      ACharsetViewInfo: TACLHexViewChararterSetViewViewInfo);
    procedure Calculate;
    function CalculateCharBounds(AOffset: Int64;
      ADiscardNegativeOffset: Boolean = False): TRect;
    procedure Draw(ACanvas: TCanvas; const AOrigin: TPoint);
    //# Properties
    property CharsetViewInfo: TACLHexViewChararterSetViewViewInfo read FCharsetViewInfo;
    property Focused: Boolean read FFocused write FFocused;
    property Style: TACLHexViewStyle read GetStyle;
    property ViewInfo: TACLHexViewViewInfo read FViewInfo;
  end;

  { TACLHexViewSelectionDragObject }

  TACLHexViewSelectionDragObject = class(TACLCompoundControlDragObject)
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
    //# Properties
    property HitTest: TACLHitTestInfo read GetHitTest;
    property SubClass: TACLHexViewSubClass read FSubClass;
  end;

  { TACLHexViewViewInfo }

  TACLHexViewViewInfo = class(TACLCompoundControlScrollContainerViewInfo)
  protected type
    TPane = (pHex, pText);
  strict private const
    HexHeaderData: array[0..acHexViewBytesPerRow - 1] of Byte = (
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
    );
    IndentBetweenViews = 16;
    Padding = 6;
    function GetRowsAreaClipRect: TRect;
  strict private
    FBuffer: TACLByteBuffer;
    FBufferPosition: Int64;
    FFocusedPane: TPane;
    FHeaderHeight: Integer;
    FHeaderViewInfo: TACLHexViewHeaderViewInfo;
    FHexSelection: TACLHexViewSelectionViewInfo;
    FRowHeight: Integer;
    FRowViewInfo: TACLHexViewRowViewInfo;
    FTextSelection: TACLHexViewSelectionViewInfo;

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
    //# Properties
    property BufferPosition: Int64 read FBufferPosition write SetBufferPosition;
    property RowHeight: Integer read FRowHeight;
    property RowsArea: TRect read GetRowsArea;
    property RowsAreaClipRect: TRect read GetRowsAreaClipRect;
    property VisibleRowCount: Integer read GetVisibleRowCount;
  public
    constructor Create(AOwner: TACLCompoundControlSubClass); override;
    destructor Destroy; override;
    //# Properties
    property FocusedPane: TPane read FFocusedPane write SetFocusedPane;
    property HexSelection: TACLHexViewSelectionViewInfo read FHexSelection;
    property SubClass: TACLHexViewSubClass read GetSubClass;
    property TextSelection: TACLHexViewSelectionViewInfo read FTextSelection;
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
    //# Messages
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    function CreateSubClass: TACLCompoundControlSubClass; override;
    function GetContentOffset: TRect; override;
    procedure Paint; override;
    procedure UpdateTransparency; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure CopyToClipboard; overload;
    procedure CopyToClipboard(AEncoding: TEncoding); overload;
    function GetSelectedBytes: TBytes;
    procedure SelectAll;
    procedure SetSelection(const AStart, ALength: Int64);
    //# Properties
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
    //# Events
    property OnSelect: TNotifyEvent read GetOnSelect write SetOnSelect;
  end;

function FormatHex(const ABytes: TBytes): UnicodeString;
implementation

const
  acHexViewHitDataOffset = 'DataOffset';

function FormatHex(const ABytes: TBytes): UnicodeString;
var
  I: Integer;
  S: TACLStringBuilder;
begin
  if ABytes = nil then
    Exit(acEmptyStr);

  S := TACLStringBuilder.Get(Length(ABytes) * 3);
  try
    S.Capacity := Length(ABytes) * 3;
    for I := 0 to Length(ABytes) - 1 do
    begin
      if I > 0 then
        S.Append(' ');
      S.Append(IntToHex(ABytes[I], 2));
    end;
    Result := acUString(S.ToString);
  finally
    S.Release;
  end;
end;

{ TACLHexViewStyle }

procedure TACLHexViewStyle.InitializeResources;
begin
  inherited;
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

procedure TACLHexView.Paint;
begin
  Style.Draw(Canvas, ClientRect, Transparent, Borders);
  inherited;
end;

function TACLHexView.GetContentOffset: TRect;
begin
  Result := acBorderOffsets * Borders;
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

procedure TACLHexView.UpdateTransparency;
begin
  if Transparent or Style.IsTransparentBackground then
    ControlStyle := ControlStyle - [csOpaque]
  else
    ControlStyle := ControlStyle + [csOpaque];
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
  if AIndex < Ord(' ') then
    Result := EmptyChar
  else
    Result := Char(AIndex);
end;

procedure TACLHexViewCharacterSet.CreateViewInfo;
var
  LIndex: Byte;
  LRender: TACLTextLayoutRender;
begin
  LRender := DefaultTextLayoutCanvasRender.Create(MeasureCanvas);
  try
    LRender.SetFont(Font);
    FEmptyCharView := TACLTextViewInfo.Create(EmptyChar);
    FSize := FEmptyCharView.Measure(LRender);
    for LIndex := Low(Byte) to High(Byte) do
    begin
      FData[LIndex] := CreateData(LIndex);
      FView[LIndex] := TACLTextViewInfo.Create(FData[LIndex]);
      FSize := Max(FSize, FView[LIndex].Measure(LRender));
    end;
  finally
    LRender.Free;
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
  if (Result = nil) or (Result.TextWidth = 0) then
    Result := FEmptyCharView;
end;

procedure TACLHexViewCharacterSet.SetFont(AValue: TFont);
begin
  ReleaseViewInfo;
  FFont := AValue;
  CreateViewInfo;
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
  UpdateCharacters;
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
  CopyToClipboard(
    function (const ABytes: TBytes): UnicodeString
    begin
      Result := AEncoding.GetString(ABytes);
    end); // to prevent from linking error in FPC
end;

procedure TACLHexViewSubClass.CopyToClipboard(AEncodeProc: TEncodeProc);

  function BytesToString(const ABytes: TBytes): UnicodeString;
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
    SetLength(Result{%H-}, SelLength);
    Data.Position := SelStart;
    Data.ReadBuffer(Result, SelLength);
  end
  else
    Result := nil;
end;

procedure TACLHexViewSubClass.MakeVisible(const ACharPosition: Int64);
var
  ACharBounds: TRect;
  ASelection: TACLHexViewSelectionViewInfo;
  AViewBounds: TRect;
begin
  if ViewInfo.FocusedPane = pHex then
    ASelection := ViewInfo.HexSelection
  else
    ASelection := ViewInfo.TextSelection;

  AViewBounds := ViewInfo.RowsAreaClipRect;
  ACharBounds := ASelection.CalculateCharBounds(ACharPosition, False);
  ACharBounds.Offset(ViewInfo.RowsArea.TopLeft);
  ViewInfo.Viewport := ViewInfo.Viewport -
    acCalculateScrollToDelta(ACharBounds, AViewBounds, TACLScrollToMode.MakeVisible);
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
  inherited SetTargetDPI(AValue);
  Style.TargetDPI := AValue;
end;

function TACLHexViewSubClass.CreateStyle: TACLHexViewStyle;
begin
  Result := TACLHexViewStyle.Create(Self);
end;

function TACLHexViewSubClass.CreateViewInfo: TACLCompoundControlCustomViewInfo;
begin
  Result := TACLHexViewViewInfo.Create(Self);
end;

procedure TACLHexViewSubClass.DoSelectionChanged;
begin
  CallNotifyEvent(Self, OnSelect);
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
begin
  Characters.Font := Font;
  CharactersHex.Font := Font;
end;

function TACLHexViewSubClass.GetViewInfo: TACLHexViewViewInfo;
begin
  Result := TACLHexViewViewInfo(inherited ViewInfo);
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

procedure TACLHexViewSubClass.ProcessKeyDown(var AKey: Word; AShift: TShiftState);

  procedure MoveCursor(ACursor: Int64; AGranularity: Integer = 0);
  begin
    while (ACursor < 0) and (AGranularity > 0) do
      Inc(ACursor, AGranularity);
    while (ACursor > DataSize) and (AGranularity > 0) do
      Dec(ACursor, AGranularity);
    if InRange(ACursor, 0, DataSize) then
    begin
      if ssShift in AShift then
        Select(FSelectionStart, ACursor)
      else
        Select(ACursor, ACursor);
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
        MoveCursor(DataSize)
      else
        MoveCursor(Cursor - Cursor mod acHexViewBytesPerRow + acHexViewBytesPerRow - 1);

    VK_HOME:
      if ssCtrl in AShift then
        MoveCursor(0)
      else
        MoveCursor(Cursor - Cursor mod acHexViewBytesPerRow);

    Ord('A'):
      if ssCtrl in AShift then
        SelectAll;
  else
    Exit;
  end;
  AKey := 0;
end;

procedure TACLHexViewSubClass.ProcessMouseClick(AButton: TMouseButton; AShift: TShiftState);
var
  ACursor: Integer;
begin
  if (AButton = mbLeft) and (HitTest.HitObject is TACLHexViewChararterSetViewViewInfo) then
  begin
    ACursor := GetPositionFromHitTest(HitTest);
    if ssShift in AShift then
      Select(FSelectionStart, ACursor)
    else
      Select(ACursor, ACursor);
  end;
  inherited;
end;

procedure TACLHexViewSubClass.ProcessMouseDown(AButton: TMouseButton; AShift: TShiftState);
begin
  inherited;
  if HitTest.HitObject is TACLHexViewChararterSetViewViewInfo then
  begin
    if TACLHexViewChararterSetViewViewInfo(HitTest.HitObject).CharacterSet = CharactersHex then
      ViewInfo.FocusedPane := pHex
    else
      ViewInfo.FocusedPane := pText;
  end;
end;

procedure TACLHexViewSubClass.ProcessMouseWheel(
  ADirection: TACLMouseWheelDirection; AShift: TShiftState);
begin
  ViewInfo.ScrollByMouseWheel(ADirection, AShift);
end;

procedure TACLHexViewSubClass.Select(AStart, ATarget: Int64);
var
  ACursor: Int64;
begin
  ACursor := ATarget;
  if ATarget < AStart then
    acExchangeInt64(AStart, ATarget);

  BeginUpdate;
  try
    SetSelection(AStart, ATarget - AStart + 1);
    Cursor := ACursor;
  finally
    EndUpdate;
  end;
end;

{ TACLHexViewChararterSetViewViewInfo }

constructor TACLHexViewChararterSetViewViewInfo.Create(
  ASubClass: TACLHexViewSubClass; ACharacterSet: TACLHexViewCharacterSet);
begin
  inherited Create(ASubClass);
  FCharacterSet := ACharacterSet;
end;

procedure TACLHexViewChararterSetViewViewInfo.Draw(
  ACanvas: TCanvas; AData: PByte; ADataSize: Integer);
var
  APrevTextColor: Cardinal;
  ASize: TSize;
  ARender: TACLTextLayoutRender;
  ATextColor1: Cardinal;
  ATextColor2: Cardinal;
  ATextViewInfo: TACLTextViewInfo;
  X, Y: Integer;
begin
  X := Bounds.Left;
  Y := Bounds.Top;
  ASize := FCharacterSet.Size;
  ATextColor1 := FColorOdd;
  ATextColor2 := FColorEven;
  APrevTextColor := ACanvas.Font.Color;
  ARender := DefaultTextLayoutCanvasRender.Create(ACanvas);
  try
    while ADataSize > 0 do
    begin
      ATextViewInfo := FCharacterSet.View[AData^];
      ACanvas.Font.Color := ATextColor1;
      ARender.SetFont(ACanvas.Font);
      ARender.TextOut(ATextViewInfo, X + (ASize.cx - ATextViewInfo.TextWidth) div 2, Y);
      acExchangeIntegers(ATextColor1, ATextColor2);
      Inc(X, ASize.cx + IndentBetweenCharacters);
      Dec(ADataSize);
      Inc(AData);
    end;
  finally
    ARender.Free;
    ACanvas.Font.Color := APrevTextColor;
  end;
end;

function TACLHexViewChararterSetViewViewInfo.MeasureHeight: Integer;
begin
  Result := FCharacterSet.Size.cy;
end;

function TACLHexViewChararterSetViewViewInfo.MeasureWidth: Integer;
begin
  Result := FCharacterSet.Size.cx * acHexViewBytesPerRow + FIndentBetweenCharacters * (acHexViewBytesPerRow - 1);
end;

function TACLHexViewChararterSetViewViewInfo.CreateDragObject(
  const AHitTestInfo: TACLHitTestInfo): TACLCompoundControlDragObject;
begin
  Result := TACLHexViewSelectionDragObject.Create(TACLHexViewSubClass(SubClass));
end;

procedure TACLHexViewChararterSetViewViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
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

{ TACLHexViewRowViewInfo }

constructor TACLHexViewRowViewInfo.Create;
begin
  inherited;
  FTextView := TACLHexViewChararterSetViewViewInfo.Create(SubClass, SubClass.Characters);
  FHexView := TACLHexViewChararterSetViewViewInfo.Create(SubClass, SubClass.CharactersHex);
end;

destructor TACLHexViewRowViewInfo.Destroy;
begin
  FreeAndNil(FTextView);
  FreeAndNil(FHexView);
  inherited;
end;

procedure TACLHexViewRowViewInfo.Draw(ACanvas: TCanvas; const AOrigin: TPoint; AData: PByte; ADataSize: Integer);
var
  AWindowOrg: TPoint;
begin
  AWindowOrg := acMoveWindowOrg(ACanvas.Handle, AOrigin);
  try
    ACanvas.Font.Color := FLabelTextColor;
    acTextOut(ACanvas, FLabelRect.Left, FLabelRect.Top, LabelText);
    HexView.Draw(ACanvas, AData, ADataSize);
    TextView.Draw(ACanvas, AData, ADataSize);
  finally
    acRestoreWindowOrg(ACanvas.Handle, AWindowOrg);
  end;
end;

function TACLHexViewRowViewInfo.MeasureHeight: Integer;
begin
  Result := Max(TextView.MeasureHeight, HexView.MeasureHeight);
end;

function TACLHexViewRowViewInfo.MeasureWidth: Integer;
begin
  Result := FLabelAreaWidth +
    IndentBetweenViews + HexView.MeasureWidth +
    IndentBetweenViews + TextView.MeasureWidth;
end;

procedure TACLHexViewRowViewInfo.DoCalculate(AChanges: TIntegerSet);
var
  LRect: TRect;
  LView: TRect;
begin
  inherited;

  HexView.IndentBetweenCharacters := dpiApply(4, CurrentDpi);

  LRect := Bounds;
  FLabelAreaWidth := acTextSize(SubClass.Font, '00000000').cx;
  FLabelRect := LRect;
  FLabelRect.Width := FLabelAreaWidth;
  LRect.Left := FLabelRect.Right + IndentBetweenViews;

  LView := LRect;
  LView.Width := HexView.MeasureWidth;
  HexView.Calculate(LView, []);
  LRect.Left := FHexView.Bounds.Right + IndentBetweenViews;

  LView := LRect;
  LView.Width := TextView.MeasureWidth;
  TextView.Calculate(LView, []);

  HexView.ColorOdd := SubClass.Style.ColorContentText1.AsColor;
  HexView.ColorEven := SubClass.Style.ColorContentText2.AsColor;
  TextView.ColorOdd := SubClass.Style.ColorContentText1.AsColor;
  TextView.ColorEven := SubClass.Style.ColorContentText1.AsColor;

  FLabelTextColor := SubClass.Style.ColorHeaderText.AsColor;
end;

procedure TACLHexViewRowViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
begin
  if not (HexView.CalculateHitTest(AInfo) or TextView.CalculateHitTest(AInfo)) then
    inherited;
end;

function TACLHexViewRowViewInfo.GetSubClass: TACLHexViewSubClass;
begin
  Result := TACLHexViewSubClass(inherited SubClass);
end;

{ TACLHexViewHeaderViewInfo }

constructor TACLHexViewHeaderViewInfo.Create(ASubClass: TACLCompoundControlSubClass);
begin
  inherited;
  LabelText := 'Offset (h)';
end;

procedure TACLHexViewHeaderViewInfo.DoCalculate(AChanges: TIntegerSet);
var
  AMetric: TTextMetric;
begin
  inherited;

  HexView.ColorOdd := FLabelTextColor;
  HexView.ColorEven := FLabelTextColor;
  TextView.ColorOdd := FLabelTextColor;
  TextView.ColorEven := FLabelTextColor;

  MeasureCanvas.Font := SubClass.Font;
  GetTextMetrics(MeasureCanvas.Handle, AMetric{%H-});
  FLinespacing := IndentBetweenViews - AMetric.tmDescent;
end;

function TACLHexViewHeaderViewInfo.MeasureHeight: Integer;
begin
  Result := inherited + FLinespacing;
end;

{ TACLHexViewSelectionViewInfo }

constructor TACLHexViewSelectionViewInfo.Create(AViewInfo: TACLHexViewViewInfo;
  ACharsetViewInfo: TACLHexViewChararterSetViewViewInfo);
begin
  FViewInfo := AViewInfo;
  FCharsetViewInfo := ACharsetViewInfo;
end;

procedure TACLHexViewSelectionViewInfo.Calculate;
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
    begin
      FRects[0].TopLeft := ASelStart.TopLeft;
      FRects[0].BottomRight := ASelFinish.BottomRight;
    end;
  end;

  if ViewInfo.SubClass.Data <> nil then
    FCursor := CalculateCharBounds(ViewInfo.SubClass.Cursor)
  else
    FCursor := NullRect;
end;

function TACLHexViewSelectionViewInfo.CalculateCharBounds(AOffset: Int64; ADiscardNegativeOffset: Boolean = False): TRect;
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

procedure TACLHexViewSelectionViewInfo.Draw(ACanvas: TCanvas; const AOrigin: TPoint);
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
      acFillRect(ACanvas, FRects[I], AColor);

    if Focused then
      acFillRect(ACanvas, FCursor, Style.ColorContentFocused.Value)
    else
      if FRects[0].IsEmpty then // no multiple selection
        acFillRect(ACanvas, FCursor, AColor);
  finally
    acRestoreWindowOrg(ACanvas.Handle, AWindowOrg);
  end;
end;

function TACLHexViewSelectionViewInfo.GetStyle: TACLHexViewStyle;
begin
  Result := FViewInfo.SubClass.Style;
end;

{ TACLHexViewSelectionDragObject }

constructor TACLHexViewSelectionDragObject.Create(ASubClass: TACLHexViewSubClass);
begin
  inherited Create;
  FSubClass := ASubClass;
  FStartPosition := SubClass.GetPositionFromHitTest(HitTest);
end;

procedure TACLHexViewSelectionDragObject.DragFinished(ACanceled: Boolean);
begin
  if ACanceled then
    SubClass.SetSelection(FSavedSelStart, FSavedSelLength)
  else
    UpdateSelection;

  inherited;
end;

procedure TACLHexViewSelectionDragObject.DragMove(const P: TPoint; var ADeltaX, ADeltaY: Integer);
var
  AHitPoint: TPoint;
begin
  if not PtInRect(FContentArea, P) then
  begin
    AHitPoint.X := EnsureRange(P.X, FContentArea.Left, FContentArea.Right - 1);
    AHitPoint.Y := EnsureRange(P.Y, FContentArea.Top, FContentArea.Bottom - 1);
    SubClass.UpdateHitTest(AHitPoint);
  end;

  UpdateAutoScrollDirection(P, FScrollableArea);
  UpdateSelection;
end;

function TACLHexViewSelectionDragObject.DragStart: Boolean;
begin
  CreateAutoScrollTimer;
  FSavedSelStart := SubClass.SelStart;
  FSavedSelLength := SubClass.SelLength;
  FContentArea := SubClass.ViewInfo.RowsArea;
  FScrollableArea := FContentArea;
  FScrollableArea.Inflate(0, -SubClass.ViewInfo.RowHeight);
  Result := True;
end;

function TACLHexViewSelectionDragObject.GetHitTest: TACLHitTestInfo;
begin
  Result := FSubClass.HitTest;
end;

procedure TACLHexViewSelectionDragObject.UpdateSelection;
begin
  if HitTest.HitObject is TACLHexViewChararterSetViewViewInfo then
    SubClass.Select(FStartPosition, SubClass.GetPositionFromHitTest(HitTest));
end;

{ TACLHexViewViewInfo }

constructor TACLHexViewViewInfo.Create(AOwner: TACLCompoundControlSubClass);
begin
  inherited;
  FBuffer := TACLByteBuffer.Create(2);
  FRowViewInfo := TACLHexViewRowViewInfo.Create(SubClass);
  FTextSelection := TACLHexViewSelectionViewInfo.Create(Self, FRowViewInfo.TextView);
  FHexSelection := TACLHexViewSelectionViewInfo.Create(Self, FRowViewInfo.HexView);
  FHexSelection.Focused := True;
  FHeaderViewInfo := TACLHexViewHeaderViewInfo.Create(SubClass);
end;

destructor TACLHexViewViewInfo.Destroy;
begin
  FreeAndNil(FHeaderViewInfo);
  FreeAndNil(FRowViewInfo);
  FreeAndNil(FHexSelection);
  FreeAndNil(FTextSelection);
  FreeAndNil(FBuffer);
  inherited Destroy;
end;

procedure TACLHexViewViewInfo.CalculateContentLayout;
begin
  FRowViewInfo.IndentBetweenViews := dpiApply(IndentBetweenViews, CurrentDpi);
  FRowViewInfo.Calculate(Bounds, []);

  FHeaderViewInfo.IndentBetweenViews := dpiApply(IndentBetweenViews, CurrentDpi);
  FHeaderViewInfo.Calculate(Bounds, []);
  FHeaderHeight := FHeaderViewInfo.MeasureHeight;

  FRowHeight := FRowViewInfo.MeasureHeight;
  FContentSize.cx := FRowViewInfo.MeasureWidth;
  FContentSize.cy := FRowHeight * Ceil(SubClass.DataSize / acHexViewBytesPerRow) + FHeaderViewInfo.MeasureHeight;

  if FRowHeight > 0 then
    CheckBufferCapacity(((Bounds.Height div FRowHeight) + 2) * acHexViewBytesPerRow);

  FHeaderViewInfo.Calculate(Rect(0, 0, ContentSize.cx, FHeaderHeight), []);
  FRowViewInfo.Calculate(Rect(0, 0, ContentSize.cx, FRowHeight), []);

  CalculateSelection;
end;

procedure TACLHexViewViewInfo.CalculateSelection;
begin
  FHexSelection.Calculate;
  FTextSelection.Calculate;
end;

procedure TACLHexViewViewInfo.CalculateSubCells(const AChanges: TIntegerSet);
begin
  inherited;
  FClientBounds.Inflate(-dpiApply(Padding, CurrentDpi));
end;

procedure TACLHexViewViewInfo.CheckBufferCapacity(ACapacity: Integer);
begin
  if (FBuffer = nil) or (FBuffer.Size < ACapacity) then
  begin
    FreeAndNil(FBuffer);
    FBuffer := TACLByteBuffer.Create(ACapacity);
    PopulateData;
  end;
end;

procedure TACLHexViewViewInfo.ContentScrolled(ADeltaX, ADeltaY: Integer);
begin
  BufferPosition := (ViewportY div FRowHeight) * acHexViewBytesPerRow;
  inherited;
end;

procedure TACLHexViewViewInfo.DoCalculateHitTest(const AInfo: TACLHitTestInfo);
var
  LDataOffset: Integer;
  ARowRect: TRect;
begin
  inherited;

  if (FRowHeight > 0) and PtInRect(RowsArea, AInfo.HitPoint) then
  begin
    LDataOffset := 0;
    ARowRect := RowsArea;
    ARowRect.Height := FRowHeight;
    while (ARowRect.Top < FClientBounds.Bottom) and (LDataOffset < FBuffer.Used) do
    begin
      if PtInRect(ARowRect, AInfo.HitPoint) then
      begin
        AInfo.HitPoint := AInfo.HitPoint - ARowRect.TopLeft;
        try
          if FRowViewInfo.CalculateHitTest(AInfo) then
            AInfo.HitObjectData[acHexViewHitDataOffset] :=
              TObject(LDataOffset + Integer(AInfo.HitObjectData[acHexViewHitDataOffset]));
        finally
          AInfo.HitPoint := AInfo.HitPoint + ARowRect.TopLeft;
        end;
        Break;
      end;
      ARowRect.Offset(0, FRowHeight);
      Inc(LDataOffset, acHexViewBytesPerRow);
    end;
  end;
end;

procedure TACLHexViewViewInfo.DoDraw(ACanvas: TCanvas);
var
  AClipRegion: TRegionHandle;
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
      ARowRect := FClientBounds;
      ARowRect.Height := FHeaderHeight;
      Dec(ARowRect.Left, ViewportX);
      FHeaderViewInfo.Draw(ACanvas, ARowRect.TopLeft, @HexHeaderData[0], Length(HexHeaderData));
      acExcludeFromClipRegion(ACanvas.Handle, ARowRect);

      ADataOffset := 0;
      ARowsArea := RowsArea;

      HexSelection.Draw(ACanvas, ARowsArea.TopLeft);
      TextSelection.Draw(ACanvas, ARowsArea.TopLeft);

      ARowRect := ARowsArea;
      ARowRect.Height := FRowHeight;
      while (ARowRect.Top < FClientBounds.Bottom) and (ADataOffset < FBuffer.Used) do
      begin
        AData := @FBuffer.DataArr^[ADataOffset];
        ADataSize := MinMax(FBuffer.Used - ADataOffset, 0, acHexViewBytesPerRow);
        FRowViewInfo.LabelText := IntToHex(FBufferPosition + ADataOffset, 8);
        FRowViewInfo.Draw(ACanvas, ARowRect.TopLeft, AData, ADataSize);
        ARowRect.Offset(0, FRowHeight);
        Inc(ADataOffset, acHexViewBytesPerRow);
      end;
    end;
  finally
    acRestoreClipRegion(ACanvas.Handle, AClipRegion);
  end;
end;

function TACLHexViewViewInfo.GetScrollInfo(AKind: TScrollBarKind; out AInfo: TACLScrollInfo): Boolean;
begin
  Result := inherited;
  if Result and (AKind = sbVertical) then
    AInfo.LineSize := FRowHeight;
end;

procedure TACLHexViewViewInfo.RecreateSubCells;
begin
  FreeAndNil(FBuffer);
end;

procedure TACLHexViewViewInfo.PopulateData;
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

function TACLHexViewViewInfo.GetRowsArea: TRect;
begin
  Result := RowsAreaClipRect;
  Dec(Result.Left, ViewportX);
  Dec(Result.Top, ViewportY mod FRowHeight);
end;

function TACLHexViewViewInfo.GetRowsAreaClipRect: TRect;
begin
  Result := ClientBounds;
  Inc(Result.Top, FHeaderHeight);
end;

function TACLHexViewViewInfo.GetSubClass: TACLHexViewSubClass;
begin
  Result := TACLHexViewSubClass(inherited SubClass);
end;

function TACLHexViewViewInfo.GetVisibleRowCount: Integer;
begin
  Result := RowsArea.Height div RowHeight;
end;

procedure TACLHexViewViewInfo.SetBufferPosition(const AValue: Int64);
begin
  if FBufferPosition <> AValue then
  begin
    FBufferPosition := AValue;
    PopulateData;
    CalculateSelection;
  end;
end;

procedure TACLHexViewViewInfo.SetFocusedPane(const Value: TPane);
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
