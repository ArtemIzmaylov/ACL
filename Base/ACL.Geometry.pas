{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*             Geometry Routines             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Geometry;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // Vcl
{$IFNDEF ACL_BASE_NOVCL}
  Vcl.Controls,
{$ENDIF}
  // System
  System.Types,
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Generics.Collections,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Strings;

type
  TACLBorder = (mLeft, mTop, mRight, mBottom);
  TACLBorders = set of TACLBorder;

  TACLFitMode = (afmNormal, afmStretch, afmProportionalStretch, afmFit, afmFill);
  TACLStretchMode = (isStretch, isTile, isCenter);

  TACLMarginPart = (mzLeftTop, mzLeft, mzLeftBottom, mzTop, mzBottom, mzRight, mzRightTop, mzRightBottom, mzClient);
  TACLMarginPartBounds = array[TACLMarginPart] of TRect;

const
  acAllBorders = [mLeft, mTop, mRight, mBottom];
  acBorderOffsets: TRect = (Left: 2; Top: 2; Right: 2; Bottom: 2);

type

  { TACLRange }

  TACLRange = record
    Start: Integer;
    Finish: Integer;

    class function Create(AStart, AFinish: Integer): TACLRange; static;
  end;

  { TACLScaleFactor }

  TACLScaleFactor = class
  strict private
    FDenominator: Integer;
    FListeners: TACLList<TNotifyEvent>;
    FNumerator: Integer;
    FOwner: TPersistent;

    function GetAssigned: Boolean; inline;
  protected
    procedure AssignCore(ANumerator, ADenominator: Integer);
  public
    constructor Create(AChangeEvent: TNotifyEvent = nil); overload;
    constructor Create(AOwner: TPersistent; AChangeEvent: TNotifyEvent = nil); overload;
    destructor Destroy; override;
    procedure Assign(ANumerator, ADenominator: Integer); overload;
    procedure Assign(ASource: TACLScaleFactor); overload;
    procedure Change(ANumerator, ADenominator: Integer);
    function Clone: TACLScaleFactor;

    function Apply(const V: Integer): Integer; overload; inline;
    function Apply(const V: TPoint): TPoint; overload; inline;
    function Apply(const V: TRect): TRect; overload; inline;
    function Apply(const V: TSize): TSize; overload; inline;
    function ApplyF(const V: Single): Single; inline;

    function Revert(const V: Integer): Integer; overload; inline;
    function Revert(const V: TPoint): TPoint; overload; inline;
    function Revert(const V: TRect): TRect; overload; inline;
    function Revert(const V: TSize): TSize; overload; inline;

    procedure ListenerAdd(AEvent: TNotifyEvent);
    procedure ListenerRemove(AEvent: TNotifyEvent);

    property Assigned: Boolean read GetAssigned;
    property Denominator: Integer read FDenominator;
    property Numerator: Integer read FNumerator;
    property Owner: TPersistent read FOwner;
  end;

  { IACLScaleFactor }

  IACLScaleFactor = interface
  ['{F4BFC126-06AD-4895-A002-67DC336C2F6B}']
    function GetScaleFactor: TACLScaleFactor;
    property Value: TACLScaleFactor read GetScaleFactor;
  end;

  { TACLAutoSizeItem }

  TACLAutoSizeItem = class
  public
    Size, MinSize, MaxSize: Integer;
  end;

  { TACLAutoSizeCalculator }

  TACLAutoSizeCalculator = class(TACLObjectList<TACLAutoSizeItem>)
  strict private
    FAvailableSize: Integer;
  public
    procedure Add(AMinSize, AMaxSize: Integer; ACanResize: Boolean); overload;
    procedure Add(ASize, AMinSize, AMaxSize: Integer; ACanResize: Boolean); overload;
    procedure Calculate;
    //
    property AvailableSize: Integer read FAvailableSize write FAvailableSize;
  end;

  { TACLSize }

  TACLSizeValidateEvent = procedure (Sender: TObject; var AValue: TSize) of object;

  TACLSize = class(TACLUnknownPersistent)
  strict private
    FDefaultValue: TSize;
    FValue: TSize;

    FOnChange: TNotifyEvent;
    FOnValidate: TACLSizeValidateEvent;

    function GetAll: Integer;
    function GetHeight: Integer;
    function GetWidth: Integer;
    function IsHeightStored: Boolean;
    function IsWidthStored: Boolean;
    procedure SetAll(AValue: Integer);
    procedure SetHeight(AValue: Integer);
    procedure SetValue(AValue: TSize);
    procedure SetWidth(AValue: Integer);
  protected
    procedure Changed; virtual;
    procedure ValidateValue(var AValue: TSize); virtual;
  public
    constructor Create(AChangeEvent: TNotifyEvent); overload;
    constructor Create(AChangeEvent: TNotifyEvent; const ADefaultValue: TSize); overload;
    procedure Assign(Source: TPersistent); override;
    function IsEmpty: Boolean;
    procedure Reset;
    function ToString: string; override;
    //
    property DefaultValue: TSize read FDefaultValue write FDefaultValue;
    property Value: TSize read FValue write SetValue;
    //
    property OnValidate: TACLSizeValidateEvent read FOnValidate write FOnValidate;
  published
    property All: Integer read GetAll write SetAll stored False;
    property Height: Integer read GetHeight write SetHeight stored IsHeightStored;
    property Width: Integer read GetWidth write SetWidth stored IsWidthStored;
  end;

  { TACLRect }

  TACLRectValidateEvent = procedure (Sender: TObject; var AValue: TRect) of object;

  TACLRect = class(TACLUnknownPersistent)
  strict private
    FDefaultValue: TRect;
    FValue: TRect;

    FOnChange: TNotifyEvent;
    FOnValidate: TACLRectValidateEvent;

    function GetAll: Integer;
    function GetSide(const AIndex: Integer): Integer;
    function GetSideOfRect(const ARect: TRect; const AIndex: Integer): Integer;
    function IsSideStored(const AIndex: Integer): Boolean;
    procedure SetAll(const AValue: Integer);
    procedure SetSide(const AIndex, AValue: Integer);
    procedure SetValue(AValue: TRect);
  protected
    procedure Changed; virtual;
    procedure ValidateValue(var AValue: TRect); virtual;
  public
    constructor Create(AChangeEvent: TNotifyEvent = nil); overload;
    constructor Create(AChangeEvent: TNotifyEvent; const ADefaultValue: TRect); overload;
    procedure Assign(Source: TPersistent); override;
    procedure Reset;
    function ToString: string; override;
    //
    property DefaultValue: TRect read FDefaultValue write FDefaultValue;
    property Value: TRect read FValue write SetValue;
    //
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnValidate: TACLRectValidateEvent read FOnValidate write FOnValidate;
  published
    property All: Integer read GetAll write SetAll stored False;
    property Left: Integer index 0 read GetSide write SetSide stored IsSideStored;
    property Top: Integer index 1 read GetSide write SetSide stored IsSideStored;
    property Right: Integer index 2 read GetSide write SetSide stored IsSideStored;
    property Bottom: Integer index 3 read GetSide write SetSide stored IsSideStored;
  end;

  { TACLXFormHelper }

  TACLXFormHelper = record helper for TXForm
  public
    class function Combine(const AMatrix1, AMatrix2: TXForm): TXForm; static;
    class function CreateFlip(AFlipHorizontally, AFlipVertically: Boolean; const APivotPointX, APivotPointY: Single): TXForm; static;
    class function CreateIdentityMatrix: TXForm; static;
    class function CreateMatrix(M11, M12, M21, M22, DX, DY: Single): TXForm; static;
    class function CreateRotationMatrix(AAngle: Single): TXForm; static;
    class function CreateScaleMatrix(AScale: Single): TXForm; overload; static;
    class function CreateScaleMatrix(AScaleX, AScaleY: Single): TXForm; overload; static;
    class function CreateTranslateMatrix(AOffsetX, AOffsetY: Single): TXForm; static;
    class function IsEqual(const AMatrix1, AMatrix2: TXForm): Boolean; static;
    class function IsIdentity(const AMatrix: TXForm): Boolean; overload; static;
    function IsIdentity: Boolean; overload;
    function Transform(const P: TPointF): TPointF;
  end;

function acCalcPatternCount(ADestSize, APatternSize: Integer): Integer;
function acHighestCommonFactor(A, B: Integer): Integer;
procedure acReduceFraction(var A, B: Integer);

// Margins
procedure acMarginAdd(var AMargins: TRect; ALeft, ATop, ARight, ABottom: Integer); overload;
procedure acMarginAdd(var AMargins: TRect; const AAddition: Integer); overload;
procedure acMarginAdd(var AMargins: TRect; const AAddition: TRect); overload;
procedure acMarginCalculateRects(const ADestRect, AMargins, ASourceRect: TRect;
  out AParts: TACLMarginPartBounds; AStretchMode: TACLStretchMode = isStretch);
function acMarginGetReal(const R: TRect; ABorders: TACLBorders): TRect;
function acMarginIsEmpty(const AMargins: TRect): Boolean;
function acMarginIsPartFixed(APart: TACLMarginPart; AStretchMode: TACLStretchMode = isStretch): Boolean;
function acMarginHeight(const R: TRect): Integer; inline;
function acMarginWidth(const R: TRect): Integer; inline;
function acMargins(const ARect, AContentRect: TRect): TRect; overload;
function acMargins(const AValue: Integer): TRect; overload;

// Points
function acPointDistance(const P1, P2: TPoint): Double;
function acPointInRect(const R: TRect; const P: TPoint): Boolean; inline;
function acPointIsEqual(const P1, P2: TPoint): Boolean; inline;
function acPointOffset(const P, AOffset: TPoint): TPoint; overload; inline;
function acPointOffset(const P: TPoint; X, Y: Integer): TPoint; overload;inline;
function acPointOffsetNegative(const P, AOffset: TPoint): TPoint; inline;
function acPointScale(const P: TPoint; AScaleFactor: Single): TPoint; overload;inline;

// Sizes
function acSize(Value: Integer): TSize; overload; inline;
function acSize(X, Y: Integer): TSize; overload; inline;
function acSize(const R: TRect): TSize; overload; inline;
function acSizeIsEmpty(const S: TSize): Boolean; inline;
function acSizeIsEqual(const R1, R2: TRect): Boolean; overload; inline;
function acSizeIsEqual(const S1, S2: TSize): Boolean; overload; inline;
function acSizeMax(const S1, S2: TSize): TSize; inline;
function acSizeMin(const S1, S2: TSize): TSize; inline;
function acSizeScale(const S: TSize; ANumerator, ADenominator: Integer): TSize;

// Rects
{$IFNDEF ACL_BASE_NOVCL}
procedure acRectToMargins(const R: TRect; Margins: TMargins);
{$ENDIF}
function acHalfCoordinate(const ASize: Integer): Integer; inline;
function acRect(const S: TSize): TRect; overload; inline;
function acRect(const S: TPoint): TRect; overload; inline;
function acRect(const ALeftTop: TPoint; const ASize: TSize): TRect; overload; inline;
function acRectAdjust(const R: TRect): TRect; inline;
function acRectCenter(const R: TRect): TPoint; overload;
function acRectCenter(const R: TRect; W, H: Integer): TRect; overload; inline;
function acRectCenter(const R: TRect; const S: Integer): TRect; overload; inline;
function acRectCenter(const R: TRect; const S: TSize): TRect; overload; inline;
function acRectCenterHorizontally(const R: TRect; Width: Integer): TRect; inline;
function acRectCenterVertically(const R: TRect; AHeight: Integer): TRect; inline;
function acRectContent(const ARect, AMargins: TRect): TRect; overload;
function acRectContent(const ARect, AMargins: TRect; ABorders: TACLBorders): TRect; overload;
function acRectContent(const ARect: TRect; ABorderWidth: Integer; ABorders: TACLBorders): TRect; overload;
function acRectIsEqualSizes(const R1, R2: TRect): Boolean; inline;
function acRectHeight(const R: TRect): Integer; inline;
function acRectInflate(const ARect, AMargins: TRect): TRect; overload; inline;
function acRectInflate(const ARect: TRect; AMargins: TRect; ABorders: TACLBorders): TRect; overload; inline;
function acRectInflate(const ARect: TRect; d: Integer): TRect; overload; inline;
function acRectInflate(const ARect: TRect; dx, dy: Integer): TRect; overload; inline;
function acRectInRect(const ATestRect, ARect: TRect): Boolean; inline;
function acRectIsEmpty(const R: TRect): Boolean; inline;
function acRectMirror(const ARect, AParentRect: TRect): TRect; inline;
function acRectOffset(const ARect: TRect; const P: TPoint): TRect; overload; inline;
function acRectOffsetNegative(const ARect: TRect; const P: TPoint): TRect; inline;
function acRectOffset(const ARect: TRect; dx, dy: Integer): TRect; overload; inline;
function acRectRotate(const R: TRect): TRect; inline;
function acRectScale(const R: TRect; ANumeratorX, ADenominatorX, ANumeratorY, ADenominatorY: Integer): TRect; overload;
function acRectScale(const R: TRect; ANumerator, ADenominator: Integer): TRect; overload; inline;
function acRectScale(const R: TRect; AScaleFactor: Single): TRect; overload;
function acRectScale(const R: TRectF; AScale: Single): TRectF; overload;
function acRectSetBottom(const R: TRect; ABottom, AHeight: Integer): TRect; overload;inline;
function acRectSetHeight(const R: TRect; AHeight: Integer): TRect; inline;
function acRectSetLeft(const R: TRect; ALeft, AWidth: Integer): TRect; overload; inline;
function acRectSetLeft(const R: TRect; AWidth: Integer): TRect; overload; inline;
function acRectSetPos(const R: TRect; const P: TPoint): TRect; inline;
function acRectSetRight(const R: TRect; ARight, AWidth: Integer): TRect; overload; inline;
function acRectSetSize(const R: TRect; const ASize: TSize): TRect; overload; inline;
function acRectSetSize(const P: TPoint; const ASize: TSize): TRect; overload; inline;
function acRectSetSize(const R: TRect; W, H: Integer): TRect; overload; inline;
function acRectSetTop(const R: TRect; AHeight: Integer): TRect; overload;inline;
function acRectSetTop(const R: TRect; ATop, AHeight: Integer): TRect; overload;inline;
function acRectSetWidth(const R: TRect; AWidth: Integer): TRect; inline;
function acRectWidth(const R: TRect): Integer; inline;
procedure acRectUnion(var ATarget: TRect; const R: TRect); inline; overload;

// Fit
procedure acFitSize(var ATargetWidth, ATargetHeight: Integer; SourceWidth, SourceHeight: Integer; AMode: TACLFitMode); overload;
function acFitSize(const DisplaySize, SourceSize: TSize; AMode: TACLFitMode): TSize; overload; inline;
function acFitSize(const DisplaySize: TSize; SourceWidth, SourceHeight: Integer; AMode: TACLFitMode): TSize; overload; inline;
function acFitRect(const R: TRect; ASourceWidth, ASourceHeight: Integer; AMode: TACLFitMode; ACenter: Boolean = True): TRect; overload;
function acFitRect(const R: TRect; const ASourceSize: TSize; AMode: TACLFitMode; ACenter: Boolean = True): TRect; overload; inline;

// Map
function acMapPoint(const ASource, ATarget: HWND; const P: TPoint): TPoint;
function acMapRect(const ASource, ATarget: HWND; const R: TRect): TRect;
implementation

function acCalcPatternCount(ADestSize, APatternSize: Integer): Integer;
begin
  if (ADestSize <= 0) or (APatternSize = 0) then
    Result := 0
  else
    Result := ADestSize div APatternSize + Ord(ADestSize mod APatternSize <> 0);
end;

function acHighestCommonFactor(A, B: Integer): Integer;
var
  FA, FB: Integer;
begin
  if A = 0 then
    Exit(0);

  FA := Abs(A);
  FB := Abs(B);
  acReduceFraction(FA, FB);
  Result := A div FA;
end;

procedure acReduceFraction(var A, B: Integer);
var
  AIndex: Integer;
begin
  AIndex := 2;
  while (AIndex <= A) and (AIndex <= B) do
  begin
    if (A mod AIndex = 0) and (B mod AIndex = 0) then
    begin
      A := A div AIndex;
      B := B div AIndex;
      AIndex := 2;
    end
    else
      Inc(AIndex);
  end;
end;

//==============================================================================
// Margins
//==============================================================================

procedure acMarginCalculateRects(const ADestRect, AMargins, ASourceRect: TRect;
  out AParts: TACLMarginPartBounds; AStretchMode: TACLStretchMode = isStretch);

  function CalculateMargins: TRect;
  var
    ADelta: Integer;
    R: TRect;
  begin
    Result := AMargins;
    if AStretchMode = isCenter then
    begin
      R := acRectContent(ASourceRect, AMargins);
      if (Result.Left <> 0) or (Result.Right <> 0) then
      begin
        ADelta := acRectWidth(ADestRect) - acRectWidth(R);
        Result.Left := MulDiv(Result.Left, ADelta, Result.Left + Result.Right);
        Result.Right := ADelta - Result.Left;
      end;
      if (Result.Top <> 0) or (Result.Bottom <> 0) then
      begin
        ADelta := acRectHeight(ADestRect) - acRectHeight(R);
        Result.Top := MulDiv(Result.Top, ADelta, Result.Top + Result.Bottom);
        Result.Bottom := ADelta - Result.Top;
      end;
    end;
  end;

var
  AIndex: TACLMarginPart;
  R: TRect;
begin
  R := acRectContent(ADestRect, CalculateMargins);
  for AIndex := Low(TACLMarginPart) to High(TACLMarginPart) do
  begin
    // Horizontal
    case AIndex of
      mzClient:
        AParts[AIndex] := R;
      mzLeftTop, mzLeft, mzLeftBottom:
        begin
          AParts[AIndex].Left := ADestRect.Left;
          AParts[AIndex].Right := R.Left;
        end;
      mzTop, mzBottom:
        begin
          AParts[AIndex].Left := R.Left;
          AParts[AIndex].Right := R.Right;
        end;
      mzRight, mzRightTop, mzRightBottom:
        begin
          AParts[AIndex].Left := R.Right;
          AParts[AIndex].Right := ADestRect.Right;
        end;
    end;
    // Vertical
    case AIndex of
      mzLeft, mzRight:
        begin
          AParts[AIndex].Top := R.Top;
          AParts[AIndex].Bottom := R.Bottom;
        end;
      mzLeftTop, mzTop, mzRightTop:
        begin
          AParts[AIndex].Top := ADestRect.Top;
          AParts[AIndex].Bottom := R.Top;
        end;
      mzRightBottom, mzLeftBottom, mzBottom:
        begin
          AParts[AIndex].Top := R.Bottom;
          AParts[AIndex].Bottom := ADestRect.Bottom;
        end;
    end;
  end;
end;

procedure acMarginAdd(var AMargins: TRect; ALeft, ATop, ARight, ABottom: Integer);
begin
  Inc(AMargins.Bottom, ABottom);
  Inc(AMargins.Left, ALeft);
  Inc(AMargins.Right, ARight);
  Inc(AMargins.Top, ATop);
end;

procedure acMarginAdd(var AMargins: TRect; const AAddition: Integer);
begin
  acMarginAdd(AMargins, AAddition, AAddition, AAddition, AAddition);
end;

procedure acMarginAdd(var AMargins: TRect; const AAddition: TRect);
begin
  acMarginAdd(AMargins, AAddition.Left, AAddition.Top, AAddition.Right, AAddition.Bottom);
end;

function acMarginGetReal(const R: TRect; ABorders: TACLBorders): TRect;
begin
  Result := NullRect;
  if mTop in ABorders then
    Result.Top := R.Top;
  if mBottom in ABorders then
    Result.Bottom := R.Bottom;
  if mLeft in ABorders then
    Result.Left := R.Left;
  if mRight in ABorders then
    Result.Right := R.Right;
end;

function acMargins(const AValue: Integer): TRect;
begin
  Result.Left := AValue;
  Result.Top := AValue;
  Result.Right := AValue;
  Result.Bottom := AValue;
end;

function acMargins(const ARect, AContentRect: TRect): TRect;
begin
  Result.Left := AContentRect.Left - ARect.Left;
  Result.Top := AContentRect.Top - ARect.Top;
  Result.Right := ARect.Right - AContentRect.Right;
  Result.Bottom := ARect.Bottom - AContentRect.Bottom;
end;

function acMarginIsEmpty(const AMargins: TRect): Boolean;
begin
  with AMargins do
    Result := (Left = 0) and (Top = 0) and (Bottom = 0) and (Right = 0);
end;

function acMarginIsPartFixed(APart: TACLMarginPart; AStretchMode: TACLStretchMode = isStretch): Boolean;
begin
  if AStretchMode = isCenter then
    Result := APart = mzClient
  else
    Result := APart in [mzLeftTop, mzLeftBottom, mzRightTop, mzRightBottom];
end;

function acMarginHeight(const R: TRect): Integer;
begin
  Result := R.Top + R.Bottom;
end;

function acMarginWidth(const R: TRect): Integer;
begin
  Result := R.Left + R.Right;
end;

//==============================================================================
// Points
//==============================================================================

function acPointDistance(const P1, P2: TPoint): Double;
begin
  try
    Result := Sqrt(Sqr(P1.X - P2.X) + Sqr(P1.Y - P2.Y));
  except
    Result := MaxInt;
  end;
end;

function acPointInRect(const R: TRect; const P: TPoint): Boolean;
begin
  Result := (P.X >= R.Left) and (P.X < R.Right) and (P.Y >= R.Top) and (P.Y < R.Bottom);
end;

function acPointIsEqual(const P1, P2: TPoint): Boolean;
begin
  Result := (P1.X = P2.X) and (P1.Y = P2.Y);
end;

function acPointOffset(const P, AOffset: TPoint): TPoint;
begin
  Result.X := P.X + AOffset.X;
  Result.Y := P.Y + AOffset.Y;
end;

function acPointOffset(const P: TPoint; X, Y: Integer): TPoint;
begin
  Result.X := P.X + X;
  Result.Y := P.Y + Y;
end;

function acPointOffsetNegative(const P, AOffset: TPoint): TPoint;
begin
  Result.X := P.X - AOffset.X;
  Result.Y := P.Y - AOffset.Y;
end;

function acPointScale(const P: TPoint; AScaleFactor: Single): TPoint;
begin
  Result.X := Round(P.X * AScaleFactor);
  Result.Y := Round(P.Y * AScaleFactor);
end;

//==============================================================================
// Sizes
//==============================================================================

function acSize(Value: Integer): TSize;
begin
  Result.cx := Value;
  Result.cy := Value;
end;

function acSize(X, Y: Integer): TSize;
begin
  Result.cx := X;
  Result.cy := Y;
end;

function acSize(const R: TRect): TSize;
begin
  Result.cx := R.Right - R.Left;
  Result.cy := R.Bottom - R.Top;
end;

function acSizeIsEmpty(const S: TSize): Boolean;
begin
  Result := (S.cx = 0) or (S.cy = 0);
end;

function acSizeIsEqual(const S1, S2: TSize): Boolean;
begin
  Result := (S1.cx = S2.cx) and (S1.cy = S2.cy);
end;

function acSizeIsEqual(const R1, R2: TRect): Boolean;
begin
  Result :=
    ((R1.Right - R1.Left) = (R2.Right - R2.Left)) and
    ((R1.Bottom - R1.Top) = (R2.Bottom - R2.Top));
end;

function acSizeMax(const S1, S2: TSize): TSize;
begin
  Result.cx := Max(S1.cx, S2.cx);
  Result.cy := Max(S1.cy, S2.cy);
end;

function acSizeMin(const S1, S2: TSize): TSize;
begin
  Result.cx := Min(S1.cx, S2.cx);
  Result.cy := Min(S1.cy, S2.cy);
end;

function acSizeScale(const S: TSize; ANumerator, ADenominator: Integer): TSize;
begin
  Result.cx := MulDiv(S.cx, ANumerator, ADenominator);
  Result.cy := MulDiv(S.cy, ANumerator, ADenominator);
end;

//==============================================================================
// Rects
//==============================================================================

function acHalfCoordinate(const ASize: Integer): Integer; inline;
begin
  Result := (ASize - Integer(Odd(ASize))) div 2;
end;

function acRectIsEqualSizes(const R1, R2: TRect): Boolean;
begin
  Result :=
    ((R1.Right - R1.Left) = (R2.Right - R2.Left)) and
    ((R1.Bottom - R1.Top) = (R2.Bottom - R2.Top));
end;

function acRectContent(const ARect, AMargins: TRect): TRect; overload;
begin
  Result.Top := ARect.Top + AMargins.Top;
  Result.Left := ARect.Left + AMargins.Left;
  Result.Right := ARect.Right - AMargins.Right;
  Result.Bottom := ARect.Bottom - AMargins.Bottom;
end;

function acRectContent(const ARect, AMargins: TRect; ABorders: TACLBorders): TRect;
begin
  Result.Top := ARect.Top + IfThen(mTop in ABorders, AMargins.Top);
  Result.Left := ARect.Left + IfThen(mLeft in ABorders, AMargins.Left);
  Result.Right := ARect.Right - IfThen(mRight in ABorders, AMargins.Right);
  Result.Bottom := ARect.Bottom - IfThen(mBottom in ABorders, AMargins.Bottom);
end;

function acRectContent(const ARect: TRect; ABorderWidth: Integer; ABorders: TACLBorders): TRect;
begin
  Result.Top := ARect.Top + IfThen(mTop in ABorders, ABorderWidth);
  Result.Left := ARect.Left + IfThen(mLeft in ABorders, ABorderWidth);
  Result.Right := ARect.Right - IfThen(mRight in ABorders, ABorderWidth);
  Result.Bottom := ARect.Bottom - IfThen(mBottom in ABorders, ABorderWidth);
end;

function acRectSetRight(const R: TRect; ARight, AWidth: Integer): TRect;
begin
  Result := R;
  Result.Right := ARight;
  Result.Left := Result.Right - AWidth;
end;

function acRectSetSize(const R: TRect; const ASize: TSize): TRect;
begin
  Result := acRectSetSize(R, ASize.cx, ASize.cy);
end;

function acRectSetSize(const P: TPoint; const ASize: TSize): TRect; overload; inline;
begin
  Result := Rect(P.X, P.Y, P.X + ASize.cx, P.Y + ASize.cy);
end;

function acRectSetSize(const R: TRect; W, H: Integer): TRect;
begin
  Result := R;
  Result.Right := R.Left + W;
  Result.Bottom := R.Top + H;
end;

function acRect(const S: TSize): TRect;
begin
  Result := Rect(0, 0, S.cx, S.cy);
end;

function acRect(const S: TPoint): TRect;
begin
  Result := Rect(S.X, S.Y, S.X, S.Y);
end;

function acRect(const ALeftTop: TPoint; const ASize: TSize): TRect;
begin
  Result := Rect(ALeftTop.X, ALeftTop.Y, ALeftTop.X + ASize.cx, ALeftTop.Y + ASize.cy);
end;

function acRectAdjust(const R: TRect): TRect; inline;
begin
  Result := Rect(Min(R.Left, R.Right), Min(R.Top, R.Bottom), Max(R.Left, R.Right), Max(R.Top, R.Bottom));
end;

function acRectCenter(const R: TRect): TPoint; overload;
begin
  Result.X := acHalfCoordinate(R.Left + R.Right);
  Result.Y := acHalfCoordinate(R.Top + R.Bottom);
end;

function acRectCenter(const R: TRect; const S: Integer): TRect;
begin
  Result := acRectCenter(R, S, S);
end;

function acRectCenter(const R: TRect; const S: TSize): TRect;
begin
  Result := acRectCenter(R, S.cx, S.cy);
end;

function acRectCenter(const R: TRect; W, H: Integer): TRect;
begin
  Result := R;
  Result.Left := acHalfCoordinate(R.Left + R.Right - W);
  Result.Right := Result.Left + W;
  Result.Top := acHalfCoordinate(R.Top + R.Bottom - H);
  Result.Bottom := Result.Top + H;
end;

function acRectInflate(const ARect: TRect; d: Integer): TRect;
begin
  Result := acRectInflate(ARect, d, d);
end;

function acRectInflate(const ARect, AMargins: TRect): TRect;
begin
  Result := ARect;
  Dec(Result.Top, AMargins.Top);
  Dec(Result.Left, AMargins.Left);
  Inc(Result.Right, AMargins.Right);
  Inc(Result.Bottom, AMargins.Bottom);
end;

function acRectInflate(const ARect: TRect; AMargins: TRect; ABorders: TACLBorders): TRect;
begin
  AMargins.Bottom := IfThen(mBottom in ABorders, AMargins.Bottom);
  AMargins.Left := IfThen(mLeft in ABorders, AMargins.Left);
  AMargins.Right := IfThen(mRight in ABorders, AMargins.Right);
  AMargins.Top := IfThen(mTop in ABorders, AMargins.Top);
  Result := acRectInflate(ARect, AMargins);
end;

function acRectInflate(const ARect: TRect; dx, dy: Integer): TRect;
begin
  Result := ARect;
  Dec(Result.Top, dy);
  Dec(Result.Left, dx);
  Inc(Result.Right, dx);
  Inc(Result.Bottom, dy);
end;

function acRectInRect(const ATestRect, ARect: TRect): Boolean;
begin
  Result :=
    (ATestRect.Left >= ARect.Left) and (ATestRect.Top >= ARect.Top) and
    (ATestRect.Right <= ARect.Right) and (ATestRect.Bottom <= ARect.Bottom);
end;

function acRectIsEmpty(const R: TRect): Boolean;
begin
  Result := (R.Bottom <= R.Top) or (R.Right <= R.Left);
end;

function acRectMirror(const ARect, AParentRect: TRect): TRect; inline;
begin
  Result := ARect;
  Result.Left := AParentRect.Left + AParentRect.Right - ARect.Right;
  Result.Right := Result.Left + ARect.Width;
end;

function acRectOffset(const ARect: TRect; const P: TPoint): TRect;
begin
  Result := acRectOffset(ARect, P.X, P.Y);
end;

function acRectOffsetNegative(const ARect: TRect; const P: TPoint): TRect;
begin
  Result := acRectOffset(ARect, -P.X, -P.Y);
end;

function acRectOffset(const ARect: TRect; dx, dy: Integer): TRect;
begin
  Result := Rect(ARect.Left + dX, ARect.Top + dY, ARect.Right + dX, ARect.Bottom + dY);
end;

{$IFNDEF ACL_BASE_NOVCL}
procedure acRectToMargins(const R: TRect; Margins: TMargins);
begin
  Margins.Left := R.Left;
  Margins.Bottom := R.Bottom;
  Margins.Right := R.Right;
  Margins.Top := R.Top;
end;
{$ENDIF}

procedure acRectUnion(var ATarget: TRect; const R: TRect);
begin
  if R.Left < ATarget.Left then
    ATarget.Left := R.Left;
  if R.Top < ATarget.Top then
    ATarget.Top := R.Top;
  if R.Right > ATarget.Right then
    ATarget.Right := R.Right;
  if R.Bottom > ATarget.Bottom then
    ATarget.Bottom := R.Bottom;
end;

function acRectWidth(const R: TRect): Integer;
begin
  Result := R.Right - R.Left;
end;

function acRectRotate(const R: TRect): TRect;
begin
  Result := Rect(R.Top, R.Left, R.Bottom, R.Right);
end;

function acRectScale(const R: TRect; AScaleFactor: Single): TRect;
begin
  Result.Bottom := Round(R.Bottom * AScaleFactor);
  Result.Left := Round(R.Left * AScaleFactor);
  Result.Right := Round(R.Right * AScaleFactor);
  Result.Top := Round(R.Top * AScaleFactor);
end;

function acRectScale(const R: TRectF; AScale: Single): TRectF;
begin
  Result.Bottom := R.Bottom * AScale;
  Result.Left := R.Left * AScale;
  Result.Right := R.Right * AScale;
  Result.Top := R.Top * AScale;
end;

function acRectScale(const R: TRect; ANumeratorX, ADenominatorX, ANumeratorY, ADenominatorY: Integer): TRect;
begin
  Result.Bottom := MulDiv(R.Bottom, ANumeratorY, ADenominatorY);
  Result.Left := MulDiv(R.Left, ANumeratorX, ADenominatorX);
  Result.Right := MulDiv(R.Right, ANumeratorX, ADenominatorX);
  Result.Top := MulDiv(R.Top, ANumeratorY, ADenominatorY);
end;

function acRectScale(const R: TRect; ANumerator, ADenominator: Integer): TRect;
begin
  Result := acRectScale(R, ANumerator, ADenominator, ANumerator, ADenominator);
end;

function acRectSetBottom(const R: TRect; ABottom, AHeight: Integer): TRect;
begin
  Result := R;
  Result.Bottom := ABottom;
  Result.Top := ABottom - AHeight;
end;

function acRectSetHeight(const R: TRect; AHeight: Integer): TRect;
begin
  Result := R;
  Result.Bottom := R.Top + AHeight;
end;

function acRectSetLeft(const R: TRect; AWidth: Integer): TRect;
begin
  Result := R;
  Result.Left := Result.Right - AWidth;
end;

function acRectSetLeft(const R: TRect; ALeft, AWidth: Integer): TRect;
begin
  Result := R;
  Result.Left := ALeft;
  Result.Right := Result.Left + AWidth;
end;

function acRectSetWidth(const R: TRect; AWidth: Integer): TRect;
begin
  Result := R;
  Result.Right := Result.Left + AWidth;
end;

function acRectSetTop(const R: TRect; AHeight: Integer): TRect;
begin
  Result := R;
  Result.Top := R.Bottom - AHeight;
end;

function acRectSetTop(const R: TRect; ATop, AHeight: Integer): TRect;
begin
  Result := R;
  Result.Top := ATop;
  Result.Bottom := Result.Top + AHeight;
end;

function acRectSetPos(const R: TRect; const P: TPoint): TRect;
begin
  Result := Rect(P.X, P.Y, P.X + R.Right - R.Left, P.Y + R.Bottom - R.Top);
end;

function acRectCenterHorizontally(const R: TRect; Width: Integer): TRect;
begin
  Result := R;
  Result.Left := acHalfCoordinate(R.Left + R.Right - Width);
  Result.Right := Result.Left + Width;
end;

function acRectCenterVertically(const R: TRect; AHeight: Integer): TRect;
begin
  Result := R;
  Result.Top := acHalfCoordinate(R.Top + R.Bottom - AHeight);
  Result.Bottom := Result.Top + AHeight;
end;

function acRectHeight(const R: TRect): Integer;
begin
  Result := R.Bottom - R.Top;
end;

function acMapPoint(const ASource, ATarget: HWND; const P: TPoint): TPoint;
begin
  Result := P;
  MapWindowPoints(ASource, ATarget, Result, 1);
end;

function acMapRect(const ASource, ATarget: HWND; const R: TRect): TRect;
begin
  Result := R;
  MapWindowPoints(ASource, ATarget, Result, 2);
end;

// ---------------------------------------------------------------------------------------------------------------------
// Fit
// ---------------------------------------------------------------------------------------------------------------------

procedure acFitSize(var ATargetWidth, ATargetHeight: Integer; SourceWidth, SourceHeight: Integer; AMode: TACLFitMode);
var
  K1, K2: Double;
begin
  if (SourceWidth <= 0) or (SourceHeight <= 0) then
  begin
    ATargetHeight := 0;
    ATargetWidth := 0;
    Exit;
  end;

  K1 := ATargetWidth / SourceWidth;
  K2 := ATargetHeight / SourceHeight;

  case AMode of
    afmStretch:
      begin
        SourceHeight := ATargetHeight;
        SourceWidth := ATargetWidth;
      end;

    afmFill, afmProportionalStretch:
      if (K1 > K2) = (AMode = afmFill) then
      begin
        SourceHeight := Round(SourceHeight * K1);
        SourceWidth := ATargetWidth;
      end
      else
      begin
        SourceHeight := ATargetHeight;
        SourceWidth := Round(SourceWidth * K2);
      end;

    afmFit:
      if Min(K1, K2) < 1 then
      begin
        if K1 < K2 then
        begin
          SourceHeight := Round(SourceHeight * K1);
          SourceWidth := ATargetWidth;
        end
        else
        begin
          SourceHeight := ATargetHeight;
          SourceWidth := Round(SourceWidth * K2);
        end;
      end;
  end;
  ATargetHeight := SourceHeight;
  ATargetWidth := SourceWidth;
end;

function acFitSize(const DisplaySize, SourceSize: TSize; AMode: TACLFitMode): TSize;
begin
  Result := acFitSize(DisplaySize, SourceSize.cx, SourceSize.cy, AMode);
end;

function acFitSize(const DisplaySize: TSize; SourceWidth, SourceHeight: Integer; AMode: TACLFitMode): TSize;
begin
  Result := DisplaySize;
  acFitSize(Result.cx, Result.cy, SourceWidth, SourceHeight, AMode);
end;

function acFitRect(const R: TRect; const ASourceSize: TSize; AMode: TACLFitMode; ACenter: Boolean = True): TRect;
begin
  Result := acFitRect(R, ASourceSize.cx, ASourceSize.cy, AMode, ACenter);
end;

function acFitRect(const R: TRect; ASourceWidth, ASourceHeight: Integer; AMode: TACLFitMode; ACenter: Boolean = True): TRect;
var
  ASize: TSize;
begin
  ASize := acFitSize(acSize(R), ASourceWidth, ASourceHeight, AMode);
  if ACenter then
    Result := acRectCenter(R, ASize)
  else
    Result := acRectSetSize(R, ASize);
end;

{ TACLRange }

class function TACLRange.Create(AStart, AFinish: Integer): TACLRange;
begin
  Result.Start := AStart;
  Result.Finish := AFinish;
end;

{ TACLScaleFactor }

constructor TACLScaleFactor.Create(AChangeEvent: TNotifyEvent = nil);
begin
  Create(nil, AChangeEvent);
end;

constructor TACLScaleFactor.Create(AOwner: TPersistent; AChangeEvent: TNotifyEvent = nil);
begin
  FDenominator := 1;
  FNumerator := 1;
  FOwner := AOwner;
  ListenerAdd(AChangeEvent);
end;

destructor TACLScaleFactor.Destroy;
begin
  FreeAndNil(FListeners);
  inherited;
end;

procedure TACLScaleFactor.Assign(ANumerator, ADenominator: Integer);
var
  I: Integer;
begin
  acReduceFraction(ANumerator, ADenominator);
  if (ADenominator <> FDenominator) or (ANumerator <> FNumerator) then
  begin
    AssignCore(ANumerator, ADenominator);
    if FListeners <> nil then
    begin
      for I := 0 to FListeners.Count - 1 do
        FListeners.List[I](Self);
    end;
  end;
end;

procedure TACLScaleFactor.Assign(ASource: TACLScaleFactor);
begin
  Assign(ASource.Numerator, ASource.Denominator);
end;

procedure TACLScaleFactor.Change(ANumerator, ADenominator: Integer);
begin
  Assign(FNumerator * ANumerator, FDenominator * ADenominator);
end;

function TACLScaleFactor.Clone: TACLScaleFactor;
begin
  Result := TACLScaleFactor.Create;
  Result.Assign(Self);
end;

function TACLScaleFactor.Apply(const V: TPoint): TPoint;
begin
  Result.X := Apply(V.X);
  Result.Y := Apply(V.Y);
end;

function TACLScaleFactor.Apply(const V: Integer): Integer;
begin
  if Numerator <> Denominator then
    Result := MulDiv(V, Numerator, Denominator)
  else
    Result := V;
end;

function TACLScaleFactor.Apply(const V: TSize): TSize;
begin
  if Numerator <> Denominator then
    Result := acSizeScale(V, Numerator, Denominator)
  else
    Result := V;
end;

function TACLScaleFactor.ApplyF(const V: Single): Single;
begin
  Result := V * Numerator / Denominator;
end;

function TACLScaleFactor.Apply(const V: TRect): TRect;
begin
  if Numerator <> Denominator then
    Result := acRectScale(V, Numerator, Denominator)
  else
    Result := V;
end;

function TACLScaleFactor.Revert(const V: TPoint): TPoint;
begin
  Result.X := Revert(V.X);
  Result.Y := Revert(V.Y);
end;

function TACLScaleFactor.Revert(const V: Integer): Integer;
begin
  if Numerator <> Denominator then
    Result := MulDiv(V, Denominator, Numerator)
  else
    Result := V;
end;

function TACLScaleFactor.Revert(const V: TSize): TSize;
begin
  if Numerator <> Denominator then
    Result := acSizeScale(V, Denominator, Numerator)
  else
    Result := V;
end;

function TACLScaleFactor.Revert(const V: TRect): TRect;
begin
  if Numerator <> Denominator then
    Result := acRectScale(V, Denominator, Numerator)
  else
    Result := V;
end;

procedure TACLScaleFactor.AssignCore(ANumerator, ADenominator: Integer);
begin
  FNumerator := ANumerator;
  FDenominator := ADenominator;
end;

function TACLScaleFactor.GetAssigned: Boolean;
begin
  Result := Numerator <> Denominator;
end;

procedure TACLScaleFactor.ListenerAdd(AEvent: TNotifyEvent);
begin
  if System.Assigned(AEvent) then
  begin
    if FListeners = nil then
      FListeners := TACLList<TNotifyEvent>.Create;
    FListeners.Add(AEvent);
  end;
end;

procedure TACLScaleFactor.ListenerRemove(AEvent: TNotifyEvent);
begin
  if FListeners <> nil then
  begin
    FListeners.Remove(AEvent);
    if FListeners.Count = 0 then
      FreeAndNil(FListeners);
  end;
end;

{ TACLAutoSizeCalculator }

procedure TACLAutoSizeCalculator.Add(AMinSize, AMaxSize: Integer; ACanResize: Boolean);
begin
  Add(AMinSize, AMinSize, AMaxSize, ACanResize);
end;

procedure TACLAutoSizeCalculator.Add(ASize, AMinSize, AMaxSize: Integer; ACanResize: Boolean);
var
  AInfo: TACLAutoSizeItem;
begin
  if AMaxSize = 0 then
    AMaxSize := MaxInt;
  AInfo := TACLAutoSizeItem.Create;
  AInfo.MinSize := AMinSize;
  AInfo.MaxSize := IfThen(ACanResize, AMaxSize, AMinSize);
  AInfo.Size := Max(ASize, AMinSize);
  inherited Add(AInfo);
end;

procedure TACLAutoSizeCalculator.Calculate;
var
  AInfo: TACLAutoSizeItem;
  APrevSize: Integer;
  ASize: Integer;
  AStep: Integer;
  I: Integer;
begin
  // Step 1: Adjust all items
  ASize := 0;
  repeat
    APrevSize := ASize;
    ASize := AvailableSize;
    for I := 0 to Count - 1 do
      Dec(ASize, List[I].Size);

    if ASize < Count then
      Break
    else
      for I := 0 to Count - 1 do
      begin
        AInfo := List[I];
        AInfo.Size := Min(AInfo.Size + MulDiv(AInfo.Size, ASize, AvailableSize), AInfo.MaxSize);
      end;

  until (ASize = 0) or (ASize = APrevSize);

  // Step 2: Put left data to last adjustable item
  ASize := 0;
  repeat
    APrevSize := ASize;
    ASize := AvailableSize;
    for I := 0 to Count - 1 do
      Dec(ASize, List[I].Size);

    AStep := Sign(ASize);
    if AStep <> 0 then
      for I := Count - 1 downto 0 do
      begin
        AInfo := List[I];
        Inc(AInfo.Size, AStep);
        if InRange(AInfo.Size, AInfo.MinSize, AInfo.MaxSize) then
          Dec(ASize, AStep)
        else
          Dec(AInfo.Size, AStep);

        if ASize = 0 then
          Break;
      end;

  until (ASize = 0) or (ASize = APrevSize);
end;

{ TACLSize }

constructor TACLSize.Create(AChangeEvent: TNotifyEvent);
begin
  inherited Create;
  FOnChange := AChangeEvent;
end;

constructor TACLSize.Create(AChangeEvent: TNotifyEvent; const ADefaultValue: TSize);
begin
  Create(AChangeEvent);
  FDefaultValue := ADefaultValue;
end;

procedure TACLSize.Assign(Source: TPersistent);
begin
  if Source is TACLSize then
    Value := TACLSize(Source).Value;
end;

function TACLSize.IsEmpty: Boolean;
begin
  Result := (Width = 0) or (Height = 0);
end;

procedure TACLSize.Reset;
begin
  Value := DefaultValue;
end;

function TACLSize.ToString: string;
begin
  Result := acSizeToString(Value);
end;

procedure TACLSize.Changed;
begin
  CallNotifyEvent(Self, FOnChange);
end;

procedure TACLSize.ValidateValue(var AValue: TSize);
begin
  AValue.cx := Max(AValue.cx, 0);
  AValue.cy := Max(AValue.cy, 0);
  if Assigned(OnValidate) then
    OnValidate(Self, AValue);
end;

function TACLSize.GetAll: Integer;
begin
  if Width = Height then
    Result := Width
  else
    Result := 0;
end;

function TACLSize.GetHeight: Integer;
begin
  Result := Value.cy;
end;

function TACLSize.GetWidth: Integer;
begin
  Result := Value.cx;
end;

function TACLSize.IsHeightStored: Boolean;
begin
  Result := FValue.cy <> FDefaultValue.cy;
end;

function TACLSize.IsWidthStored: Boolean;
begin
  Result := FValue.cx <> FDefaultValue.cx;
end;

procedure TACLSize.SetAll(AValue: Integer);
begin
  Value := acSize(AValue);
end;

procedure TACLSize.SetHeight(AValue: Integer);
begin
  if Height <> AValue then
    Value := acSize(Width, AValue);
end;

procedure TACLSize.SetValue(AValue: TSize);
begin
  ValidateValue(AValue);
  if AValue <> FValue then
  begin
    FValue := AValue;
    Changed;
  end;
end;

procedure TACLSize.SetWidth(AValue: Integer);
begin
  if Width <> AValue then
    Value := acSize(AValue, Height);
end;

{ TACLRect }

constructor TACLRect.Create(AChangeEvent: TNotifyEvent);
begin
  inherited Create;
  FOnChange := AChangeEvent;
end;

constructor TACLRect.Create(AChangeEvent: TNotifyEvent; const ADefaultValue: TRect);
begin
  Create(AChangeEvent);
  FDefaultValue := ADefaultValue;
end;

procedure TACLRect.Assign(Source: TPersistent);
begin
  if Source is TACLRect then
    Value := TACLRect(Source).Value;
end;

function TACLRect.ToString: string;
begin
  Result := acRectToString(Value);
end;

procedure TACLRect.Reset;
begin
  Value := DefaultValue;
end;

procedure TACLRect.Changed;
begin
  CallNotifyEvent(Self, FOnChange);
end;

procedure TACLRect.ValidateValue(var AValue: TRect);
begin
  if Assigned(OnValidate) then
    OnValidate(Self, AValue);
end;

function TACLRect.GetAll: Integer;
begin
  if (Left = Top) and (Top = Right) and (Right = Bottom) then
    Result := Left
  else
    Result := 0;
end;

function TACLRect.GetSide(const AIndex: Integer): Integer;
begin
  Result := GetSideOfRect(FValue, AIndex);
end;

function TACLRect.GetSideOfRect(const ARect: TRect; const AIndex: Integer): Integer;
begin
  case AIndex of
    0: Result := ARect.Left;
    1: Result := ARect.Top;
    2: Result := ARect.Right;
  else
    Result := ARect.Bottom;
  end;
end;

function TACLRect.IsSideStored(const AIndex: Integer): Boolean;
begin
  Result := GetSide(AIndex) <> GetSideOfRect(FDefaultValue, AIndex);
end;

procedure TACLRect.SetAll(const AValue: Integer);
begin
  Value := Rect(AValue, AValue, AValue, AValue);
end;

procedure TACLRect.SetSide(const AIndex, AValue: Integer);
var
  R: TRect;
begin
  if GetSide(AIndex) <> AValue then
  begin
    R := Value;
    case AIndex of
      0: R.Left := AValue;
      1: R.Top := AValue;
      2: R.Right := AValue;
      3: R.Bottom := AValue;
    end;
    Value := R;
  end;
end;

procedure TACLRect.SetValue(AValue: TRect);
begin
  ValidateValue(AValue);
  if AValue <> FValue then
  begin
    FValue := AValue;
    Changed;
  end;
end;

{ TACLXFormHelper }

class function TACLXFormHelper.Combine(const AMatrix1, AMatrix2: TXForm): TXForm;
begin
  CombineTransform(Result, AMatrix1, AMatrix2);
end;

class function TACLXFormHelper.CreateFlip(
  AFlipHorizontally, AFlipVertically: Boolean; const APivotPointX, APivotPointY: Single): TXForm;
const
  FlipValueMap: array[Boolean] of Integer = (1, -1);
begin
  Result := CreateMatrix(
    FlipValueMap[AFlipHorizontally], 0, 0, FlipValueMap[AFlipVertically],
    IfThen(AFlipHorizontally, 2 * APivotPointX),
    IfThen(AFlipVertically, 2 * APivotPointY));
end;

class function TACLXFormHelper.CreateIdentityMatrix: TXForm;
begin
  Result := CreateMatrix(1, 0, 0, 1, 0, 0);
end;

class function TACLXFormHelper.CreateMatrix(M11, M12, M21, M22, DX, DY: Single): TXForm;
begin
  Result.eM11 := M11;
  Result.eM12 := M12;
  Result.eM21 := M21;
  Result.eM22 := M22;
  Result.eDx := DX;
  Result.eDy := DY;
end;

class function TACLXFormHelper.CreateRotationMatrix(AAngle: Single): TXForm;
begin
  AAngle := DegToRad(AAngle);
  Result := CreateMatrix(Cos(AAngle), Sin(AAngle), -Sin(AAngle), Cos(AAngle), 0, 0);
end;

class function TACLXFormHelper.CreateScaleMatrix(AScale: Single): TXForm;
begin
  Result := CreateScaleMatrix(AScale, AScale);
end;

class function TACLXFormHelper.CreateScaleMatrix(AScaleX, AScaleY: Single): TXForm;
begin
  Result := CreateMatrix(AScaleX, 0, 0, AScaleY, 0, 0);
end;

class function TACLXFormHelper.CreateTranslateMatrix(AOffsetX, AOffsetY: Single): TXForm;
begin
  Result := CreateMatrix(1, 0, 0, 1, AOffsetX, AOffsetY);
end;

class function TACLXFormHelper.IsEqual(const AMatrix1, AMatrix2: TXForm): Boolean;
begin
  Result :=
    SameValue(AMatrix1.eM11, AMatrix2.eM11) and
    SameValue(AMatrix1.eM12, AMatrix2.eM12) and
    SameValue(AMatrix1.eM21, AMatrix2.eM21) and
    SameValue(AMatrix1.eM22, AMatrix2.eM22) and
    SameValue(AMatrix1.eDx, AMatrix2.eDx) and
    SameValue(AMatrix1.eDy, AMatrix2.eDy);
end;

class function TACLXFormHelper.IsIdentity(const AMatrix: TXForm): Boolean;
begin
  Result :=
    (AMatrix.eM11 = 1) and (AMatrix.eM12 = 0) and
    (AMatrix.eM21 = 0) and (AMatrix.eM22 = 1) and
    (AMatrix.eDx = 0) and (AMatrix.eDy = 0);
end;

function TACLXFormHelper.IsIdentity: Boolean;
begin
  Result := TXForm.IsIdentity(Self);
end;

function TACLXFormHelper.Transform(const P: TPointF): TPointF;
begin
  Result.X := P.X * eM11 + P.Y * eM21 + eDX;
  Result.Y := P.X * eM12 + P.Y * eM22 + eDY;
end;

end.
