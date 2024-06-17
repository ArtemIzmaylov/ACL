////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v6.0
//
//  Purpose:   Geometry Routines
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Geometry;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Windows,
  {Winapi.}Messages,
{$ENDIF}
  // System
  {System.}Types,
  {System.}SysUtils,
  {System.}Classes,
  {System.}Math,
  {System.}Generics.Collections,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type
  TACLBorder = (mLeft, mTop, mRight, mBottom);
  TACLBorders = set of TACLBorder;

  TACLFitMode = (afmNormal, afmStretch, afmProportionalStretch, afmFit, afmFill);
  TACLStretchMode = (isStretch, isTile, isCenter);

  TACLMarginPart = (
    mzLeftTop, mzLeft, mzLeftBottom,
    mzTop, mzBottom,
    mzRight, mzRightTop, mzRightBottom,
    mzClient
  );
  TACLMarginParts = set of TACLMarginPart;
  TACLMarginPartBounds = array[TACLMarginPart] of TRect;

const
  acAllBorders = [mLeft, mTop, mRight, mBottom];
  acBorderOffsets: TRect = (Left: 2; Top: 2; Right: 2; Bottom: 2);

type
  PRectArray = ^TRectArray;
  TRectArray = array [0..0] of TRect;

  { TACLRange }

  TACLRange = record
    Start: Integer;
    Finish: Integer;
    class function Create(AStart, AFinish: Integer): TACLRange; static;
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
    //# Properties
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
    //# Properties
    property DefaultValue: TSize read FDefaultValue write FDefaultValue;
    property Value: TSize read FValue write SetValue;
    //# Events
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
    //# Properties
    property DefaultValue: TRect read FDefaultValue write FDefaultValue;
    property Value: TRect read FValue write SetValue;
    //# Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnValidate: TACLRectValidateEvent read FOnValidate write FOnValidate;
  published
    property All: Integer read GetAll write SetAll stored False;
    property Left: Integer index 0 read GetSide write SetSide stored IsSideStored;
    property Top: Integer index 1 read GetSide write SetSide stored IsSideStored;
    property Right: Integer index 2 read GetSide write SetSide stored IsSideStored;
    property Bottom: Integer index 3 read GetSide write SetSide stored IsSideStored;
  end;

  { TACLPointHelper }

  TACLPointHelper = record helper for TPoint
  public
  {$IFNDEF FPC}
    class operator Multiply(const L: TPoint; Factor: Single): TPoint;
  {$ENDIF} // ref.to ACL.Geometry.Utils
    procedure Scale(ANumerator, ADenominator: Integer); inline;
    function ScaleTo(ANumerator, ADenominator: Integer): TPoint; inline;
  end;

  { TACLRectHelper }

  TACLRectHelper = record helper for TRect
  public
    class function Create(const Size: TSize): TRect; overload; static;
    class function Create(const Origin: TPoint; const Size: TSize): TRect; overload; static;

    //# Operators
  {$IFNDEF FPC}
    class operator Add(const L: TRect; const R: TPoint): TRect;
    class operator Implicit(const Value: TSize): TRect;
    class operator Multiply(const L: TRect; Borders: TACLBorders): TRect;
    class operator Multiply(const L: TRect; Factor: Single): TRect;
    class operator Subtract(const L: TRect; const R: TPoint): TRect;
  {$ENDIF} // ref.to ACL.Geometry.Utils

    //# Margins
    class function CreateMargins(const Rect, ContentRect: TRect): TRect; overload; static;
    class function CreateMargins(const Value: Integer): TRect; overload; static;
    procedure MarginsAdd(const Value: TRect); overload; inline;
    procedure MarginsAdd(const Value: Integer); overload; inline;
    procedure MarginsAdd(const L, T, R, B: Integer); overload; inline;
    function MarginsHeight: Integer; inline;
    function MarginsWidth: Integer; inline;

    //# Self-Modifiers
    procedure Add(const R: TRect); // Unline the Union, does not check the R to emptines
    procedure Center(const ASize: TSize);
    procedure CenterHorz(AWidth: Integer);
    procedure CenterVert(AHeight: Integer);
    procedure Content(const BorderWidth: Integer; Borders: TACLBorders); overload;
    procedure Content(const Margins: TRect); overload;
    procedure Content(const Margins: TRect; Borders: TACLBorders); overload;
    function EqualSizes(const R: TRect): Boolean;
    procedure Inflate(const Delta: Integer); overload; inline;
    procedure Inflate(const Margins: TRect); overload; inline;
    procedure Inflate(const Margins: TRect; Borders: TACLBorders); overload; inline;
    function IsZero: Boolean; inline;
    procedure Mirror(const ParentRect: TRect);
    procedure Rotate; inline;
    procedure Scale(Numerator, Denominator: Integer);

    //# Mutations
    function CenterTo(AWidth, AHeight: Integer): TRect; overload; inline;
    function CenterTo(const ASize: TSize): TRect; overload; inline;
    function InflateTo(Delta: Integer): TRect; overload; inline;
    function InflateTo(dX, dY: Integer): TRect; overload; inline;
    function OffsetTo(dX, dY: Integer): TRect; inline;
    function ScaleTo(Numerator, Denominator: Integer): TRect; inline;
    function Split(const Margins: TRect): TRect; overload;
    function Split(SplitType: TSplitRectType; Origin, Size: Integer): TRect; overload;
    function Split(SplitType: TSplitRectType; Size: Integer): TRect; overload;
  end;

  { TACLRectFHelper }

  TACLRectFHelper = record helper for TRectF
  public
  {$IFNDEF FPC}
    class operator Multiply(const L: TRectF; Factor: Single): TRectF;
  {$ENDIF} // ref.to ACL.Geometry.Utils
  end;

  { TACLSizeHelper }

  TACLSizeHelper = record helper for TSize
  public
    class function Create(const Value: Integer): TSize; overload; static;
    function IsEmpty: Boolean; inline;
    procedure Scale(ANumerator, ADenominator: Integer); inline;
    function ScaleTo(ANumerator, ADenominator: Integer): TSize; inline;
  end;

{$IFDEF FPC}
  PXForm = ^TXForm;
  TXForm = packed record
    eM11, eM12, eM21, eM22, eDx, eDy: Single;
  end;
{$ENDIF}

  { TACLXFormHelper }

  TACLXFormHelper = record helper for TXForm
  public
    class function Combine(const AMatrix1, AMatrix2: TXForm): TXForm; static;
    class function CreateFlip(AFlipHorizontally, AFlipVertically: Boolean;
      const APivotPointX, APivotPointY: Single): TXForm; static;
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

procedure acCalcArcSegment(ACenterX, ACenterY, ARadiusX, ARadiusY: Single;
  AAngle1, AAngle2: Single{Rad}; out AStartPoint, AEndPoint: TPointF);
procedure acCalcPartBounds(out AParts: TACLMarginPartBounds; const AMargins: TRect;
  const ADestRect, ASourceRect: TRect; AStretchMode: TACLStretchMode = isStretch);
function acCalcPatternCount(ADestSize, APatternSize: Integer): Integer;
function acHalfCoordinate(ASize: Integer): Integer; inline;
procedure acReduceFraction(var A, B: Integer);

// Math
function Max(const S1, S2: TSize): TSize; overload; inline;
function Min(const S1, S2: TSize): TSize; overload; inline;

// Fit
procedure acFitSize(var ATargetWidth, ATargetHeight: Integer;
  SourceWidth, SourceHeight: Integer; AMode: TACLFitMode); overload;
function acFitSize(const DisplaySize, SourceSize: TSize;
  AMode: TACLFitMode): TSize; overload; inline;
function acFitSize(const DisplaySize: TSize; SourceWidth, SourceHeight: Integer;
  AMode: TACLFitMode): TSize; overload; inline;
function acFitRect(const R: TRect; ASourceWidth, ASourceHeight: Integer;
  AMode: TACLFitMode; ACenter: Boolean = True): TRect; overload;
function acFitRect(const R: TRect; const ASourceSize: TSize;
  AMode: TACLFitMode; ACenter: Boolean = True): TRect; overload; inline;

// Map
function acMapPoint(const ASource, ATarget: HWND; const P: TPoint): TPoint;
function acMapRect(const ASource, ATarget: HWND; const R: TRect): TRect;
implementation

procedure acCalcArcSegment(ACenterX, ACenterY, ARadiusX, ARadiusY: Single;
  AAngle1, AAngle2: Single; out AStartPoint, AEndPoint: TPointF);
//
//                      A * B
//  V = ---------------------------------------------
//      Sqrt(A^2 * Sin^2(Alpha) + B^2 * Cos^2(Alpha))
//
//  Radial.X = V * Cos(Alpha)
//  Radial.Y = V * Sin(Alpha)
//
//  where:
//    A - horizontal ellipse semiaxis
//    B - vertical ellipse semiaxis
//    Angle - an angle between Radius-Vector and A calculated in counterclockwise direction
//
var
  A, B, C: Double;
  ASin, ACos, AValue: Extended;
begin
  if IsZero(ARadiusX) or IsZero(ARadiusY) then
  begin
    AStartPoint := PointF(ACenterX, ACenterY);
    AEndPoint := AStartPoint;
  end
  else
  begin
    C := ARadiusX * ARadiusY;
    A := Sqr(ARadiusX);
    B := Sqr(ARadiusY);

    SinCos(AAngle1, ASin, ACos);
    AValue := C / Sqrt(A * Sqr(ASin) + B * Sqr(ACos));
    AStartPoint.X := ACenterX + AValue * ACos;
    AStartPoint.Y := ACenterY - AValue * ASin;

    if SameValue(AAngle1, AAngle2) then
      AEndPoint := AStartPoint
    else
    begin
      SinCos(AAngle2, ASin, ACos);
      AValue := C / Sqrt(A * Sqr(ASin) + B * Sqr(ACos));
      AEndPoint.X := ACenterX + AValue * ACos;
      AEndPoint.Y := ACenterY - AValue * ASin;
    end;
  end;
end;

procedure acCalcPartBounds(out AParts: TACLMarginPartBounds; const AMargins: TRect;
  const ADestRect, ASourceRect: TRect; AStretchMode: TACLStretchMode = isStretch);

  function CalculateMargins: TRect;
  var
    ADelta: Integer;
    R: TRect;
  begin
    Result := AMargins;
    if AStretchMode = isCenter then
    begin
      R := ASourceRect;
      R.Content(AMargins);
      if (Result.Left <> 0) or (Result.Right <> 0) then
      begin
        ADelta := ADestRect.Width - R.Width;
        Result.Left := MulDiv(Result.Left, ADelta, Result.Left + Result.Right);
        Result.Right := ADelta - Result.Left;
      end;
      if (Result.Top <> 0) or (Result.Bottom <> 0) then
      begin
        ADelta := ADestRect.Height - R.Height;
        Result.Top := MulDiv(Result.Top, ADelta, Result.Top + Result.Bottom);
        Result.Bottom := ADelta - Result.Top;
      end;
    end;
  end;

var
  LPart: TACLMarginPart;
  LTemp: TRect;
begin
  LTemp := ADestRect;
  LTemp.Content(CalculateMargins);
  for LPart := Low(TACLMarginPart) to High(TACLMarginPart) do
  begin
    // Horizontal
    case LPart of
      mzClient:
        AParts[LPart] := LTemp;
      mzLeftTop, mzLeft, mzLeftBottom:
        begin
          AParts[LPart].Left := ADestRect.Left;
          AParts[LPart].Right := LTemp.Left;
        end;
      mzTop, mzBottom:
        begin
          AParts[LPart].Left := LTemp.Left;
          AParts[LPart].Right := LTemp.Right;
        end;
      mzRight, mzRightTop, mzRightBottom:
        begin
          AParts[LPart].Left := LTemp.Right;
          AParts[LPart].Right := ADestRect.Right;
        end;
    end;
    // Vertical
    case LPart of
      mzLeft, mzRight:
        begin
          AParts[LPart].Top := LTemp.Top;
          AParts[LPart].Bottom := LTemp.Bottom;
        end;
      mzLeftTop, mzTop, mzRightTop:
        begin
          AParts[LPart].Top := ADestRect.Top;
          AParts[LPart].Bottom := LTemp.Top;
        end;
      mzRightBottom, mzLeftBottom, mzBottom:
        begin
          AParts[LPart].Top := LTemp.Bottom;
          AParts[LPart].Bottom := ADestRect.Bottom;
        end;
    else;
    end;
  end;
end;

function acCalcPatternCount(ADestSize, APatternSize: Integer): Integer;
begin
  if (ADestSize <= 0) or (APatternSize = 0) then
    Result := 0
  else
    Result := ADestSize div APatternSize + Ord(ADestSize mod APatternSize <> 0);
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
// Sizes
//==============================================================================

function Max(const S1, S2: TSize): TSize;
begin
  Result.cx := Max(S1.cx, S2.cx);
  Result.cy := Max(S1.cy, S2.cy);
end;

function Min(const S1, S2: TSize): TSize;
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

function acHalfCoordinate(ASize: Integer): Integer; inline;
begin
  Result := (ASize - Integer(Odd(ASize))) div 2;
end;

function acMapPoint(const ASource, ATarget: HWND; const P: TPoint): TPoint;
begin
  Result := P;
{$IFDEF FPC}
  ClientToScreen(ASource, Result);
  ScreenToClient(ATarget, Result);
{$ELSE}
  MapWindowPoints(ASource, ATarget, Result, 1);
{$ENDIF}
end;

function acMapRect(const ASource, ATarget: HWND; const R: TRect): TRect;
begin
  Result := R;
{$IFDEF FPC}
  ClientToScreen(ASource, Result.TopLeft);
  ClientToScreen(ASource, Result.BottomRight);
  ScreenToClient(ATarget, Result.TopLeft);
  ScreenToClient(ATarget, Result.BottomRight);
{$ELSE}
  MapWindowPoints(ASource, ATarget, Result, 2);
{$ENDIF}
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
  else;
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
  LSize: TSize;
begin
  LSize := acFitSize(R.Size, ASourceWidth, ASourceHeight, AMode);
  Result := R;
  if ACenter then
    Result.Center(LSize)
  else
    Result.Size := LSize;
end;

{ TACLRange }

class function TACLRange.Create(AStart, AFinish: Integer): TACLRange;
begin
  Result.Start := AStart;
  Result.Finish := AFinish;
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
  Value := TSize.Create(AValue);
end;

procedure TACLSize.SetHeight(AValue: Integer);
begin
  if Height <> AValue then
    Value := TSize.Create(Width, AValue);
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
    Value := TSize.Create(AValue, Height);
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
{$IFDEF FPC}
  Result.eM11 := AMatrix1.eM11 * AMatrix2.eM11 + AMatrix1.eM12 * AMatrix2.eM21;
  Result.eM12 := AMatrix1.eM11 * AMatrix2.eM12 + AMatrix1.eM12 * AMatrix2.eM22;
  Result.eM21 := AMatrix1.eM21 * AMatrix2.eM11 + AMatrix1.eM22 * AMatrix2.eM21;
  Result.eM22 := AMatrix1.eM21 * AMatrix2.eM12 + AMatrix1.eM22 * AMatrix2.eM22;
  Result.eDx  := AMatrix1.eDx  * AMatrix2.eM11 + AMatrix1.eDy  * AMatrix2.eM21 + AMatrix2.eDx;
  Result.eDy  := AMatrix1.eDx  * AMatrix2.eM12 + AMatrix1.eDy  * AMatrix2.eM22 + AMatrix2.eDy;
{$ELSE}
  CombineTransform(Result, AMatrix1, AMatrix2);
{$ENDIF}
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

{ TACLRectHelper }

procedure TACLRectHelper.Add(const R: TRect);
begin
  if R.Left < Left then
    Left := R.Left;
  if R.Top < Top then
    Top := R.Top;
  if R.Right > Right then
    Right := R.Right;
  if R.Bottom > Bottom then
    Bottom := R.Bottom;
end;

procedure TACLRectHelper.Center(const ASize: TSize);
begin
  CenterHorz(ASize.Width);
  CenterVert(ASize.Height);
end;

procedure TACLRectHelper.CenterHorz(AWidth: Integer);
begin
  Left := acHalfCoordinate(Left + Right - AWidth);
  Right := Left + AWidth;
end;

function TACLRectHelper.CenterTo(AWidth, AHeight: Integer): TRect;
begin
  Result := Self;
  Result.CenterHorz(AWidth);
  Result.CenterVert(AHeight);
end;

function TACLRectHelper.CenterTo(const ASize: TSize): TRect;
begin
  Result := Self;
  Result.Center(ASize);
end;

procedure TACLRectHelper.CenterVert(AHeight: Integer);
begin
  Top := acHalfCoordinate(Top + Bottom - AHeight);
  Bottom := Top + AHeight;
end;

procedure TACLRectHelper.Content(const Margins: TRect; Borders: TACLBorders);
begin
  if mTop in Borders then
    Inc(Top, Margins.Top);
  if mLeft in Borders then
    Inc(Left, Margins.Left);
  if mRight in Borders then
    Dec(Right, Margins.Right);
  if mBottom in Borders then
    Dec(Bottom, Margins.Bottom);
end;

procedure TACLRectHelper.Content(const BorderWidth: Integer; Borders: TACLBorders);
begin
  if mTop in Borders then
    Inc(Top, BorderWidth);
  if mLeft in Borders then
    Inc(Left, BorderWidth);
  if mRight in Borders then
    Dec(Right, BorderWidth);
  if mBottom in Borders then
    Dec(Bottom, BorderWidth);
end;

procedure TACLRectHelper.Content(const Margins: TRect);
begin
  Inc(Top, Margins.Top);
  Inc(Left, Margins.Left);
  Dec(Right, Margins.Right);
  Dec(Bottom, Margins.Bottom);
end;

class function TACLRectHelper.Create(const Size: TSize): TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := Size.cx;
  Result.Bottom := Size.cy;
end;

class function TACLRectHelper.Create(const Origin: TPoint; const Size: TSize): TRect;
begin
  Result.Left := Origin.X;
  Result.Top := Origin.Y;
  Result.Right := Origin.X + Size.cx;
  Result.Bottom := Origin.Y + Size.cy;
end;

class function TACLRectHelper.CreateMargins(const Value: Integer): TRect;
begin
  Result := Rect(Value, Value, Value, Value);
end;

class function TACLRectHelper.CreateMargins(const Rect, ContentRect: TRect): TRect;
begin
  Result.Left := ContentRect.Left - Rect.Left;
  Result.Top := ContentRect.Top - Rect.Top;
  Result.Right := Rect.Right - ContentRect.Right;
  Result.Bottom := Rect.Bottom - ContentRect.Bottom;
end;

function TACLRectHelper.EqualSizes(const R: TRect): Boolean;
begin
  Result :=
    ((Right - Left) = (R.Right - R.Left)) and
    ((Bottom - Top) = (R.Bottom - R.Top));
end;

procedure TACLRectHelper.Inflate(const Margins: TRect; Borders: TACLBorders);
begin
  if mTop in Borders then
    Dec(Top, Margins.Top);
  if mLeft in Borders then
    Dec(Left, Margins.Left);
  if mRight in Borders then
    Inc(Right, Margins.Right);
  if mBottom in Borders then
    Inc(Bottom, Margins.Bottom);
end;

function TACLRectHelper.InflateTo(Delta: Integer): TRect;
begin
  Result := Self;
  Result.Inflate(Delta, Delta);
end;

function TACLRectHelper.InflateTo(dX, dY: Integer): TRect;
begin
  Result := Self;
  Result.Inflate(DX, DY);
end;

function TACLRectHelper.IsZero: Boolean;
begin
  Result := (Left = 0) and (Top = 0) and (Right = 0) and (Bottom = 0);
end;

procedure TACLRectHelper.Inflate(const Delta: Integer);
begin
  Inflate(Delta, Delta);
end;

procedure TACLRectHelper.Inflate(const Margins: TRect);
begin
  Dec(Top, Margins.Top);
  Dec(Left, Margins.Left);
  Inc(Right, Margins.Right);
  Inc(Bottom, Margins.Bottom);
end;

procedure TACLRectHelper.MarginsAdd(const Value: Integer);
begin
  Inc(Bottom, Value);
  Inc(Left, Value);
  Inc(Right, Value);
  Inc(Top, Value);
end;

procedure TACLRectHelper.MarginsAdd(const L, T, R, B: Integer);
begin
  Inc(Bottom, B);
  Inc(Left, L);
  Inc(Right, R);
  Inc(Top, T);
end;

procedure TACLRectHelper.MarginsAdd(const Value: TRect);
begin
  Inc(Bottom, Value.Bottom);
  Inc(Left, Value.Left);
  Inc(Right, Value.Right);
  Inc(Top, Value.Top);
end;

function TACLRectHelper.MarginsHeight: Integer;
begin
  Result := Top + Bottom;
end;

function TACLRectHelper.MarginsWidth: Integer;
begin
  Result := Left + Right;
end;

procedure TACLRectHelper.Mirror(const ParentRect: TRect);
var
  LWidth: Integer;
begin
  LWidth := Width;
  Left := ParentRect.Left + ParentRect.Right - Right;
  Right := Left + LWidth;
end;

function TACLRectHelper.OffsetTo(dX, dY: Integer): TRect;
begin
  Result := Self;
  Result.Offset(dX, dY);
end;

procedure TACLRectHelper.Rotate;
begin
  acExchangeIntegers(Left, Top);
  acExchangeIntegers(Right, Bottom);
end;

procedure TACLRectHelper.Scale(Numerator, Denominator: Integer);
begin
  Top := MulDiv(Top, Numerator, Denominator);
  Left := MulDiv(Left, Numerator, Denominator);
  Right := MulDiv(Right, Numerator, Denominator);
  Bottom := MulDiv(Bottom, Numerator, Denominator);
end;

function TACLRectHelper.ScaleTo(Numerator, Denominator: Integer): TRect;
begin
  Result := Self;
  Result.Scale(Numerator, Denominator);
end;

function TACLRectHelper.Split(SplitType: TSplitRectType; Size: Integer): TRect;
begin
  Result := Self;
  case SplitType of
    srLeft:
      Result.Right := Left + Size;
    srRight:
      Result.Left := Right - Size;
    srTop:
      Result.Bottom := Top + Size;
    srBottom:
      Result.Top := Bottom - Size;
  end;
end;

function TACLRectHelper.Split(const Margins: TRect): TRect;
begin
  Result := Self;
  Result.Content(Margins);
end;

function TACLRectHelper.Split(SplitType: TSplitRectType; Origin, Size: Integer): TRect;
begin
  case SplitType of
    srLeft:
      Result := Rect(Origin, Top, Origin + Size, Bottom);
    srRight:
      Result := Rect(Origin - Size, Top, Origin, Bottom);
    srTop:
      Result := Rect(Left, Origin, Right, Origin + Size);
    srBottom:
      Result := Rect(Left, Origin - Size, Right, Origin);
  else
    Result := Self{%H-};
  end;
end;

{$IFNDEF FPC}
class operator TACLRectHelper.Add(const L: TRect; const R: TPoint): TRect;
begin
  Result := L;
  Result.Offset(R.X, R.Y);
end;

class operator TACLRectHelper.Implicit(const Value: TSize): TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := Value.cx;
  Result.Bottom := Value.cy;
end;

class operator TACLRectHelper.Multiply(const L: TRect; Borders: TACLBorders): TRect;
begin
  Result := NullRect;
  if mLeft in Borders then
    Result.Left := L.Left;
  if mRight in Borders then
    Result.Right := L.Right;
  if mTop in Borders then
    Result.Top := L.Top;
  if mBottom in Borders then
    Result.Bottom := L.Bottom;
end;

class operator TACLRectHelper.Multiply(const L: TRect; Factor: Single): TRect;
begin
  Result.Bottom := Round(L.Bottom * Factor);
  Result.Right := Round(L.Right * Factor);
  Result.Left := Round(L.Left * Factor);
  Result.Top := Round(L.Top * Factor);
end;

class operator TACLRectHelper.Subtract(const L: TRect; const R: TPoint): TRect;
begin
  Result := L;
  Result.Offset(-R.X, -R.Y);
end;
{$ENDIF}

{ TACLRectFHelper }

{$IFNDEF FPC}
class operator TACLRectFHelper.Multiply(const L: TRectF; Factor: Single): TRectF;
begin
  Result.Bottom := L.Bottom * Factor;
  Result.Right := L.Right * Factor;
  Result.Left := L.Left * Factor;
  Result.Top := L.Top * Factor;
end;
{$ENDIF}

{ TACLPointHelper }

{$IFNDEF FPC}
class operator TACLPointHelper.Multiply(const L: TPoint; Factor: Single): TPoint;
begin
  Result.X := Round(L.X * Factor);
  Result.Y := Round(L.Y * Factor);
end;
{$ENDIF}

procedure TACLPointHelper.Scale(ANumerator, ADenominator: Integer);
begin
  X := MulDiv(X, ANumerator, ADenominator);
  Y := MulDiv(Y, ANumerator, ADenominator);
end;

function TACLPointHelper.ScaleTo(ANumerator, ADenominator: Integer): TPoint;
begin
  Result := Self;
  Result.Scale(ANumerator, ADenominator);
end;

{ TACLSizeHelper }

class function TACLSizeHelper.Create(const Value: Integer): TSize;
begin
  Result.cx := Value;
  Result.cy := Value;
end;

function TACLSizeHelper.IsEmpty: Boolean;
begin
  Result := (cx <= 0) or (cy <= 0);
end;

procedure TACLSizeHelper.Scale(ANumerator, ADenominator: Integer);
begin
  cx := MulDiv(cx, ANumerator, ADenominator);
  cy := MulDiv(cy, ANumerator, ADenominator);
end;

function TACLSizeHelper.ScaleTo(ANumerator, ADenominator: Integer): TSize;
begin
  Result := Self;
  Result.Scale(ANumerator, ADenominator);
end;

end.
