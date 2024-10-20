////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Animation Engine
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Animation;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Winapi.Messages,
  Winapi.Windows,
{$ENDIF}
  // System
  {System.}Types,
  {System.}Classes,
  {System.}Generics.Collections,
  System.UITypes,
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  // ACL
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Math,
  ACL.Timers,
  ACL.Utils.Common;

type

{$REGION ' Engine '}

  { IACLAnimateControl }

  IACLAnimateControl = interface
  ['{49F437A3-B40C-4463-81E3-9F4462D956FD}']
    procedure Animate;
  end;

  TACLAnimationDrawProc = procedure (ACanvas: TCanvas; const R: TRect) of object;
  TACLAnimationTransitionMode = (ateLinear, ateAccelerateDecelerate, ateTanh);
  TACLAnimationTransitionProc = function (AProgress: Single): Single;

  { TACLAnimation }

  TACLAnimation = class(TACLUnknownObject)
  strict private
    FControl: IACLAnimateControl;
    FCurrentTime: Int64;
    FFinished: Boolean;
    FFinishTime: Int64;
    FFreeOnTerminate: Boolean;
    FProgress: Single;
    FStartTime: Int64;
    FTag: NativeInt;
    FTerminating: Boolean;
    FTime: Cardinal;
    FTimerInterval: Cardinal;
    FTransition: TACLAnimationTransitionProc;

    procedure SetFinished(AValue: Boolean);
  protected
    procedure Animate;
    procedure Initialize; virtual;
    function IsCompatible(AAnimation: TACLAnimation): Boolean; virtual;
    function IsReady: Boolean; virtual;
    // Events
    procedure DoAnimate; virtual;
    //# Properties
    property CurrentTime: Int64 read FCurrentTime write FCurrentTime;
    property FinishTime: Int64 read FFinishTime write FFinishTime;
    property StartTime: Int64 read FStartTime write FStartTime;
    property TimerInterval: Cardinal read FTimerInterval write FTimerInterval;
    property Transition: TACLAnimationTransitionProc read FTransition;
  public
    constructor Create(const AControl: IACLAnimateControl; ATime: Cardinal;
      ATransition: TACLAnimationTransitionMode = ateLinear); virtual;
    destructor Destroy; override;
    procedure Draw(ACanvas: TCanvas; const R: TRect); virtual;
    procedure Run;
    procedure RunImmediate;
    procedure Terminate;
    //# Properties
    property Control: IACLAnimateControl read FControl;
    property Finished: Boolean read FFinished write SetFinished;
    property FreeOnTerminate: Boolean read FFreeOnTerminate write FFreeOnTerminate;
    property Progress: Single read FProgress;
    property Tag: NativeInt read FTag write FTag;
    property Time: Cardinal read FTime;
  end;

  { TACLAnimationTransition }

  TACLAnimationTransition = class
  public
    class function Get(AMode: TACLAnimationTransitionMode): TACLAnimationTransitionProc;
    // Procedures
    class function AccelerateDecelerate(AProgress: Single): Single; static;
    class function Linear(AProgress: Single): Single; static;
    class function Tanh(AProgress: Single): Single; static;
  end;

  { TACLAnimationManager }

  TACLAnimationManager = class(TACLTimerListOf<TACLAnimation>)
  protected
    procedure DoAdding(const AObject: TACLAnimation); override;
    procedure TimerObject(const AObject: TACLAnimation); override;
  public
    constructor Create; reintroduce;
    function Find(const AControl: IACLAnimateControl;
      out AAnimation: TACLAnimation; ATag: NativeInt = 0): Boolean;
    function Draw(const AControl: IACLAnimateControl;
      ACanvas: TCanvas; const ARect: TRect; ATag: NativeInt = 0): Boolean;
    procedure RemoveOwner(AOwnerObject: TObject);
  end;

{$ENDREGION}

{$REGION ' Text Animation '}

  { TACLAnimationText }

  TACLAnimationText = class(TACLAnimation)
  strict private
    FSourceText: string;
    FTargetText: string;
    function GetActualText: string;
  public
    constructor Create(const ASourceText, ATargetText: string;
      const AControl: IACLAnimateControl; ATime: Cardinal;
      ATransition: TACLAnimationTransitionMode = ateLinear); reintroduce;
    //# Properties
    property ActualText: string read GetActualText;
    property SourceText: string read FSourceText;
    property TargetText: string read FTargetText;
  end;

{$ENDREGION}

{$REGION ' Frame-based Animations '}

  { TACLFramesAnimator }

  TACLFramesAnimator = class
  public
    procedure Calculate(AProgress: Single;
      const AFrame: TSize; const ATargetRect: TRect;
      out AFrame1Rect, AFrame2Rect: TRect;
      out AFrame1Alpha, AFrame2Alpha: Byte); virtual; abstract;
    function ReverseOrder: Boolean; virtual;
  end;

  { TACLFrameBasedAnimation }

  TACLFrameBasedAnimation = class(TACLAnimation)
  strict private
    FAnimator: TACLFramesAnimator;
  protected
    property Animator: TACLFramesAnimator read FAnimator;
  public
    constructor Create(const AControl: IACLAnimateControl;
      ATime: Cardinal; AAnimator: TACLFramesAnimator;
      ATransition: TACLAnimationTransitionMode = ateLinear); reintroduce;
    destructor Destroy; override;
  end;

  { TACLAnimatorCrossFade }

  TACLAnimatorCrossFade = class(TACLFramesAnimator)
  public
    procedure Calculate(AProgress: Single;
      const AFrame: TSize; const ATargetRect: TRect;
      out AFrame1Rect, AFrame2Rect: TRect;
      out AFrame1Alpha, AFrame2Alpha: Byte); override;
  end;

  { TACLAnimatorFadeIn }

  TACLAnimatorFadeIn = class(TACLFramesAnimator)
  public
    procedure Calculate(AProgress: Single;
      const AFrame: TSize; const ATargetRect: TRect;
      out AFrame1Rect, AFrame2Rect: TRect;
      out AFrame1Alpha, AFrame2Alpha: Byte); override;
  end;

  { TACLAnimatorFadeOut }

  TACLAnimatorFadeOut = class(TACLAnimatorFadeIn)
  public
    procedure Calculate(AProgress: Single;
      const AFrame: TSize; const ATargetRect: TRect;
      out AFrame1Rect, AFrame2Rect: TRect;
      out AFrame1Alpha, AFrame2Alpha: Byte); override;
    function ReverseOrder: Boolean; override;
  end;

  { TACLAnimatorSlideLeftToRight }

  TACLAnimatorSlideLeftToRight = class(TACLFramesAnimator)
  public
    procedure Calculate(AProgress: Single;
      const AFrame: TSize; const ATargetRect: TRect;
      out AFrame1Rect, AFrame2Rect: TRect;
      out AFrame1Alpha, AFrame2Alpha: Byte); override;
  end;

  { TACLAnimatorSlideRightToLeft }

  TACLAnimatorSlideRightToLeft = class(TACLFramesAnimator)
  public
    procedure Calculate(AProgress: Single;
      const AFrame: TSize; const ATargetRect: TRect;
      out AFrame1Rect, AFrame2Rect: TRect;
      out AFrame1Alpha, AFrame2Alpha: Byte); override;
  end;

  { TACLAnimatorSlideTopToBottom }

  TACLAnimatorSlideTopToBottom = class(TACLFramesAnimator)
  public
    procedure Calculate(AProgress: Single;
      const AFrame: TSize; const ATargetRect: TRect;
      out AFrame1Rect, AFrame2Rect: TRect;
      out AFrame1Alpha, AFrame2Alpha: Byte); override;
  end;

  { TACLAnimatorSlideBottomToTop }

  TACLAnimatorSlideBottomToTop = class(TACLFramesAnimator)
  public
    procedure Calculate(AProgress: Single;
      const AFrame: TSize; const ATargetRect: TRect;
      out AFrame1Rect, AFrame2Rect: TRect;
      out AFrame1Alpha, AFrame2Alpha: Byte); override;
  end;

  { TACLAnimatorPaperSlideTopToBottom }

  TACLAnimatorPaperSlideClass = class of TACLAnimatorPaperSlideTopToBottom;
  TACLAnimatorPaperSlideTopToBottom = class(TACLFramesAnimator)
  strict private
    FBackgroundOffsetInPercents: Single;
    FBackgroundOpacity: Single;
    FBackgroundOpacityAssigned: Boolean;
    FBackwardDirection: Boolean;
    FForegroundOpacity: Single;
    FForegroundOpacityAssigned: Boolean;
    FModifiers: TPoint;
  protected
    function GetModifiers: TPoint; virtual;
  public
    constructor Create(ABackwardDirection: Boolean;
      ABackgroundOpacity, AForegroundOpacity, ABackgroundOffsetInPercents: Single);
    procedure Calculate(AProgress: Single;
      const AFrame: TSize; const ATargetRect: TRect;
      out AFrame1Rect, AFrame2Rect: TRect;
      out AFrame1Alpha, AFrame2Alpha: Byte); override; final;
    function ReverseOrder: Boolean; override;
  end;

  { TACLAnimatorPaperSlideBottomToTop }

  TACLAnimatorPaperSlideBottomToTop = class(TACLAnimatorPaperSlideTopToBottom)
  protected
    function GetModifiers: TPoint; override;
  end;

  { TACLAnimatorPaperSlideLeftToRight }

  TACLAnimatorPaperSlideLeftToRight = class(TACLAnimatorPaperSlideTopToBottom)
  protected
    function GetModifiers: TPoint; override;
  end;

  { TACLAnimatorPaperSlideRightToLeft }

  TACLAnimatorPaperSlideRightToLeft = class(TACLAnimatorPaperSlideTopToBottom)
  protected
    function GetModifiers: TPoint; override;
  end;

  { TACLAnimatorZoomIn }

  TACLAnimatorZoomIn = class(TACLFramesAnimator)
  public
    procedure Calculate(AProgress: Single;
      const AFrame: TSize; const ATargetRect: TRect;
      out AFrame1Rect, AFrame2Rect: TRect;
      out AFrame1Alpha, AFrame2Alpha: Byte); override;
  end;

  { TACLAnimatorZoomOut }

  TACLAnimatorZoomOut = class(TACLAnimatorZoomIn)
  public
    procedure Calculate(AProgress: Single;
      const AFrame: TSize; const ATargetRect: TRect;
      out AFrame1Rect, AFrame2Rect: TRect;
      out AFrame1Alpha, AFrame2Alpha: Byte); override;
    function ReverseOrder: Boolean; override;
  end;

{$ENDREGION}

{$REGION ' Bitmap-based Animation '}

  { TACLBitmapAnimation }

  TACLBitmapAnimation = class(TACLFrameBasedAnimation)
  protected
    FFrame1: TACLDib;
    FFrame2: TACLDib;
    procedure Initialize; override;
    function IsReady: Boolean; override;
  public
    constructor Create(
      AControl: IACLAnimateControl; const ABounds: TRect;
      AAnimator: TACLFramesAnimator; ATime: Integer = -1;
      ATransition: TACLAnimationTransitionMode = ateLinear); reintroduce;
    destructor Destroy; override;
    function BuildFrame1: TACLDib; overload;
    function BuildFrame2: TACLDib; overload;
    procedure BuildFrame1(AProc: TACLAnimationDrawProc); overload;
    procedure BuildFrame2(AProc: TACLAnimationDrawProc); overload;
    procedure Draw(ACanvas: TCanvas; const R: TRect); override;
  end;

{$ENDREGION}

const
  acDefaultUIAnimations = True;

var
  acUIAnimations: Boolean = acDefaultUIAnimations;
  acUIAnimationTime: Integer = 200;

function AnimationManager: TACLAnimationManager;
implementation

uses
  {System.}Math,
  {System.}StrUtils,
  {System.}SysUtils,
  // VCL
  {Vcl.}Forms;

{$REGION ' Engine '}
var
  FAnimationManager: TACLAnimationManager;

function AnimationManager: TACLAnimationManager;
begin
  if FAnimationManager = nil then
    FAnimationManager := TACLAnimationManager.Create;
  Result := FAnimationManager;
end;

{ TACLAnimation }

constructor TACLAnimation.Create(const AControl: IACLAnimateControl;
  ATime: Cardinal; ATransition: TACLAnimationTransitionMode = ateLinear);
begin
  inherited Create;
  FTime := ATime;
  FControl := AControl;
  FTransition := TACLAnimationTransition.Get(ATransition);
  FFreeOnTerminate := True;
end;

destructor TACLAnimation.Destroy;
begin
  if FAnimationManager <> nil then
    FAnimationManager.Remove(Self);
  inherited Destroy;
end;

procedure TACLAnimation.Draw(ACanvas: TCanvas; const R: TRect);
begin
  // do nothing
end;

procedure TACLAnimation.Run;
begin
  if IsReady then
  begin
    Initialize;
    AnimationManager.Add(Self);
  end
  else
    Terminate;
end;

procedure TACLAnimation.RunImmediate;
begin
  if IsReady then
  begin
    Initialize;
    while not Finished do
      Animate;
  end;
  Terminate;
end;

procedure TACLAnimation.Terminate;
begin
  if not FTerminating then
  begin
    FTerminating := True;
    Finished := True;
    if FreeOnTerminate then
      Free;
  end;
end;

procedure TACLAnimation.Animate;
begin
  CurrentTime := Min(FinishTime, GetExactTickCount);
  FFinished := Finished or (CurrentTime >= FinishTime);
  if Finished then
    CurrentTime := FinishTime;
  FProgress := Transition((CurrentTime - StartTime) / (FinishTime - StartTime));
  DoAnimate;
end;

procedure TACLAnimation.Initialize;
begin
  if (CurrentTime <> 0) and not Finished then
  begin
    CurrentTime := CurrentTime - StartTime;
    StartTime := GetExactTickCount - CurrentTime;
    CurrentTime := StartTime + CurrentTime;
  end
  else
    StartTime := GetExactTickCount;

  FinishTime := StartTime + TimeToTickCount(Time);
  FTerminating := False;
  FFinished := False;
end;

function TACLAnimation.IsCompatible(AAnimation: TACLAnimation): Boolean;
begin
  Result := AAnimation.Control <> Control;
end;

function TACLAnimation.IsReady: Boolean;
begin
  Result := True;
end;

procedure TACLAnimation.DoAnimate;
begin
  Control.Animate;
end;

procedure TACLAnimation.SetFinished(AValue: Boolean);
begin
  if AValue <> FFinished then
  begin
    FCurrentTime := FFinishTime;
    FFinished := AValue;
    if not Finished then
    begin
      FCurrentTime := 0;
      Initialize;
    end;
    Animate;
  end;
end;

{ TACLAnimationTransition }

class function TACLAnimationTransition.Get(AMode: TACLAnimationTransitionMode): TACLAnimationTransitionProc;
begin
  case AMode of
    ateAccelerateDecelerate:
      Result := AccelerateDecelerate;
    ateTanh:
      Result := Tanh;
  else
    Result := Linear;
  end;
end;

class function TACLAnimationTransition.AccelerateDecelerate(AProgress: Single): Single;
begin
  Result := -Power(AProgress - 1, 6) + 1;
end;

class function TACLAnimationTransition.Linear(AProgress: Single): Single;
begin
  Result := AProgress;
end;

class function TACLAnimationTransition.Tanh(AProgress: Single): Single;
const
  Exactitude = 3;
var
  LTanh: Double;
begin
  LTanh := Math.Tanh(AProgress * (2 * Exactitude) - Exactitude);
  Result := 1 / (2 * Math.Tanh(Exactitude)) * (LTanh - Math.Tanh(-Exactitude));
end;

{ TACLAnimationManager }

constructor TACLAnimationManager.Create;
begin
  inherited Create;
  Interval := 1;
end;

function TACLAnimationManager.Find(const AControl: IACLAnimateControl;
  out AAnimation: TACLAnimation; ATag: NativeInt = 0): Boolean;
var
  I: Integer;
begin
  for I := FList.Count - 1 downto 0 do
  begin
    AAnimation := TACLAnimation(FList.List[I]);
    if (AAnimation.Control = AControl) and (AAnimation.Tag = ATag) then
      Exit(True);
  end;
  Result := False;
end;

function TACLAnimationManager.Draw(const AControl: IACLAnimateControl;
  ACanvas: TCanvas; const ARect: TRect; ATag: NativeInt = 0): Boolean;
var
  LAnimation: TACLAnimation;
begin
  Result := Find(AControl, LAnimation, ATag);
  if Result then
    LAnimation.Draw(ACanvas, ARect)
end;

procedure TACLAnimationManager.RemoveOwner(AOwnerObject: TObject);
var
  AAnimation: TACLAnimation;
  AControl: IACLAnimateControl;
begin
  if Supports(AOwnerObject, IACLAnimateControl, AControl) then
  begin
    while Find(AControl, AAnimation) do
      AAnimation.Terminate;
  end;
end;

procedure TACLAnimationManager.DoAdding(const AObject: TACLAnimation);
var
  I: Integer;
begin
  for I := FList.Count - 1 downto 0 do
  begin
    if not FList.List[I].IsCompatible(AObject) then
      FList.List[I].Terminate;
  end;
end;

procedure TACLAnimationManager.TimerObject(const AObject: TACLAnimation);
begin
  AObject.Animate;
  if AObject.Finished then
  begin
    AObject.Terminate;
    Remove(AObject);
  end;
end;

{$ENDREGION}

{$REGION ' Text Animation '}

{ TACLAnimationText }

constructor TACLAnimationText.Create(const ASourceText, ATargetText: string;
  const AControl: IACLAnimateControl; ATime: Cardinal; ATransition: TACLAnimationTransitionMode);
var
  ASourceTextLength: Integer;
  ATargetTextLength: Integer;
begin
  inherited Create(AControl, ATime, ATransition);

  ASourceTextLength := Length(ASourceText);
  ATargetTextLength := Length(ATargetText);
  FSourceText := ASourceText + DupeString(' ', Max(ATargetTextLength, ASourceTextLength) - ASourceTextLength);
  FTargetText := ATargetText + DupeString(' ', Max(ATargetTextLength, ASourceTextLength) - ATargetTextLength);
end;

function TACLAnimationText.GetActualText: string;
var
  I, L: Integer;
begin
  L := Length(FSourceText);
  SetLength(Result{%H-}, L);
  for I := 1 to L do
    Result[I] := Char(Trunc(Ord(FSourceText[I]) * Progress + Ord(FTargetText[I]) * (1 - Progress)));
end;

{$ENDREGION}

{$REGION ' Image-based Animations '}

{ TACLFrameBasedAnimation }

constructor TACLFrameBasedAnimation.Create(
  const AControl: IACLAnimateControl; ATime: Cardinal;
  AAnimator: TACLFramesAnimator; ATransition: TACLAnimationTransitionMode);
begin
  inherited Create(AControl, ATime, ATransition);
  FAnimator := AAnimator;
end;

destructor TACLFrameBasedAnimation.Destroy;
begin
  FreeAndNil(FAnimator);
  inherited;
end;

{ TACLFramesAnimator }

function TACLFramesAnimator.ReverseOrder: Boolean;
begin
  Result := False;
end;

{ TACLAnimatorCrossFade }

procedure TACLAnimatorCrossFade.Calculate(
  AProgress: Single; const AFrame: TSize; const ATargetRect: TRect;
  out AFrame1Rect, AFrame2Rect: TRect;
  out AFrame1Alpha, AFrame2Alpha: Byte);
begin
  AFrame1Rect := ATargetRect;
  AFrame2Rect := ATargetRect;
  AFrame1Alpha := Trunc(MaxByte * (1 - Max(0, 2 * AProgress - 1)));
  AFrame2Alpha := Trunc(MaxByte * Min(1, 2 * AProgress));
end;

{ TACLAnimatorFadeIn }

procedure TACLAnimatorFadeIn.Calculate(
  AProgress: Single; const AFrame: TSize; const ATargetRect: TRect;
  out AFrame1Rect, AFrame2Rect: TRect;
  out AFrame1Alpha, AFrame2Alpha: Byte);
begin
  AFrame1Rect := ATargetRect;
  AFrame2Rect := ATargetRect;
  AFrame1Alpha := MaxByte;
  AFrame2Alpha := Trunc(MaxByte * AProgress);
end;

{ TACLAnimatorFadeOut }

procedure TACLAnimatorFadeOut.Calculate(AProgress: Single;
  const AFrame: TSize; const ATargetRect: TRect;
  out AFrame1Rect, AFrame2Rect: TRect;
  out AFrame1Alpha, AFrame2Alpha: Byte);
begin
  AProgress := 1 - AProgress;
  inherited;
end;

function TACLAnimatorFadeOut.ReverseOrder: Boolean;
begin
  Result := True;
end;

{ TACLAnimatorSlideLeftToRight }

procedure TACLAnimatorSlideLeftToRight.Calculate(
  AProgress: Single; const AFrame: TSize; const ATargetRect: TRect;
  out AFrame1Rect, AFrame2Rect: TRect;
  out AFrame1Alpha, AFrame2Alpha: Byte);
var
  LOffset: Integer;
begin
  LOffset := Round(AProgress * AFrame.Width);
  AFrame1Rect := ATargetRect.OffsetTo(LOffset, 0);
  AFrame2Rect := ATargetRect.OffsetTo(LOffset - ATargetRect.Width, 0);
  AFrame1Alpha := 255;
  AFrame2Alpha := 255;
end;

{ TACLAnimatorSlideRightToLeft }

procedure TACLAnimatorSlideRightToLeft.Calculate(
  AProgress: Single; const AFrame: TSize; const ATargetRect: TRect;
  out AFrame1Rect, AFrame2Rect: TRect;
  out AFrame1Alpha, AFrame2Alpha: Byte);
var
  LOffset: Integer;
begin
  LOffset := Round((1 - AProgress) * AFrame.Width);
  AFrame1Rect := ATargetRect.OffsetTo(LOffset - ATargetRect.Width, 0);
  AFrame2Rect := ATargetRect.OffsetTo(LOffset, 0);
  AFrame1Alpha := 255;
  AFrame2Alpha := 255;
end;

{ TACLAnimatorSlideTopToBottom }

procedure TACLAnimatorSlideTopToBottom.Calculate(
  AProgress: Single; const AFrame: TSize; const ATargetRect: TRect;
  out AFrame1Rect, AFrame2Rect: TRect;
  out AFrame1Alpha, AFrame2Alpha: Byte);
var
  LOffset: Integer;
begin
  LOffset := Round(AProgress * AFrame.Height);
  AFrame1Rect := ATargetRect.OffsetTo(0, LOffset);
  AFrame2Rect := ATargetRect.OffsetTo(0, LOffset - ATargetRect.Height);
  AFrame1Alpha := 255;
  AFrame2Alpha := 255;
end;

{ TACLAnimatorSlideBottomToTop }

procedure TACLAnimatorSlideBottomToTop.Calculate(
  AProgress: Single; const AFrame: TSize; const ATargetRect: TRect;
  out AFrame1Rect, AFrame2Rect: TRect;
  out AFrame1Alpha, AFrame2Alpha: Byte);
var
  LOffset: Integer;
begin
  LOffset := Round((1 - AProgress) * AFrame.Height);
  AFrame1Rect := ATargetRect.OffsetTo(0, LOffset - ATargetRect.Height);
  AFrame2Rect := ATargetRect.OffsetTo(0, LOffset);
  AFrame1Alpha := 255;
  AFrame2Alpha := 255;
end;

{ TACLAnimatorPaperSlideTopToBottom }

constructor TACLAnimatorPaperSlideTopToBottom.Create(ABackwardDirection: Boolean;
  ABackgroundOpacity, AForegroundOpacity, ABackgroundOffsetInPercents: Single);
begin
  FBackwardDirection := ABackwardDirection;
  FBackgroundOffsetInPercents := ABackgroundOffsetInPercents;
  FBackgroundOpacity := ABackgroundOpacity;
  FBackgroundOpacityAssigned := not SameValue(FBackgroundOpacity, 1);
  FForegroundOpacity := AForegroundOpacity;
  FForegroundOpacityAssigned := not SameValue(FForegroundOpacity, 1);
  FModifiers := GetModifiers;
end;

procedure TACLAnimatorPaperSlideTopToBottom.Calculate(
  AProgress: Single; const AFrame: TSize; const ATargetRect: TRect;
  out AFrame1Rect, AFrame2Rect: TRect; out AFrame1Alpha, AFrame2Alpha: Byte);
var
  LFrame1Offset: Single;
  LFrame2Offset: Single;
begin
  if FBackwardDirection then
    AProgress := 1 - AProgress;

  if FBackgroundOpacityAssigned then
    AFrame1Alpha := Round(MaxByte * (AProgress + FBackgroundOpacity * (1 - AProgress)))
  else
    AFrame1Alpha := MaxByte;

  if FForegroundOpacityAssigned then
    AFrame2Alpha := Round(MaxByte * ((1 - AProgress) + FForegroundOpacity * AProgress))
  else
    AFrame2Alpha := MaxByte;

  LFrame1Offset := FBackgroundOffsetInPercents * (1 - AProgress);
  LFrame2Offset := AProgress;

  AFrame1Rect := ATargetRect.OffsetTo(
    FModifiers.X * Round(LFrame1Offset * AFrame.Width),
    FModifiers.Y * Round(LFrame1Offset * AFrame.Height));
  AFrame2Rect := ATargetRect.OffsetTo(
    FModifiers.X * Round(LFrame2Offset * AFrame.Width),
    FModifiers.Y * Round(LFrame2Offset * AFrame.Height));
end;

function TACLAnimatorPaperSlideTopToBottom.GetModifiers: TPoint;
begin
  Result := Point(0, 1);
end;

function TACLAnimatorPaperSlideTopToBottom.ReverseOrder: Boolean;
begin
  Result := True;
end;

{ TACLAnimatorPaperSlideBottomToTop }

function TACLAnimatorPaperSlideBottomToTop.GetModifiers: TPoint;
begin
  Result := Point(0, -1);
end;

{ TACLAnimatorPaperSlideLeftToRight }

function TACLAnimatorPaperSlideLeftToRight.GetModifiers: TPoint;
begin
  Result := Point(1, 0);
end;

{ TACLAnimatorPaperSlideRightToLeft }

function TACLAnimatorPaperSlideRightToLeft.GetModifiers: TPoint;
begin
  Result := Point(-1, 0);
end;

{ TACLAnimatorZoomIn }

procedure TACLAnimatorZoomIn.Calculate(
  AProgress: Single; const AFrame: TSize; const ATargetRect: TRect;
  out AFrame1Rect, AFrame2Rect: TRect;
  out AFrame1Alpha, AFrame2Alpha: Byte);
begin
  AFrame1Rect := ATargetRect.InflateTo(
    Round((ATargetRect.Width  div 2) * AProgress),
    Round((ATargetRect.Height div 2) * AProgress));
  AFrame2Rect := ATargetRect.InflateTo(
    Round(-(ATargetRect.Width  div 2) * (1 - AProgress)),
    Round(-(ATargetRect.Height div 2) * (1 - AProgress)));
  AFrame1Alpha := MaxByte;
  AFrame2Alpha := Round(MaxByte * AProgress);
end;

{ TACLAnimatorZoomOut }

procedure TACLAnimatorZoomOut.Calculate(
  AProgress: Single; const AFrame: TSize; const ATargetRect: TRect;
  out AFrame1Rect, AFrame2Rect: TRect;
  out AFrame1Alpha, AFrame2Alpha: Byte);
begin
  inherited Calculate(1 - AProgress, AFrame, ATargetRect,
    AFrame1Rect, AFrame2Rect, AFrame1Alpha, AFrame2Alpha);
end;

function TACLAnimatorZoomOut.ReverseOrder: Boolean;
begin
  Result := True;
end;
{$ENDREGION}

{$REGION ' Bitmap-based Animation '}

constructor TACLBitmapAnimation.Create(AControl: IACLAnimateControl;
  const ABounds: TRect; AAnimator: TACLFramesAnimator; ATime: Integer;
  ATransition: TACLAnimationTransitionMode);
begin
  if ATime < 0 then ATime := acUIAnimationTime;
  inherited Create(AControl, ATime, AAnimator, ATransition);
  FFrame1 := TACLDib.Create(ABounds);
  FFrame2 := TACLDib.Create(ABounds);
end;

destructor TACLBitmapAnimation.Destroy;
begin
  FreeAndNil(FFrame1);
  FreeAndNil(FFrame2);
  inherited;
end;

function TACLBitmapAnimation.BuildFrame1: TACLDib;
begin
  Result := FFrame1;
  Result.Reset;
end;

function TACLBitmapAnimation.BuildFrame2: TACLDib;
begin
  Result := FFrame2;
  Result.Reset;
end;

procedure TACLBitmapAnimation.BuildFrame1(AProc: TACLAnimationDrawProc);
begin
  if not FFrame1.Empty then
    AProc(BuildFrame1.Canvas, FFrame1.ClientRect);
end;

procedure TACLBitmapAnimation.BuildFrame2(AProc: TACLAnimationDrawProc);
begin
  if not FFrame2.Empty then
    AProc(BuildFrame2.Canvas, FFrame2.ClientRect);
end;

procedure TACLBitmapAnimation.Draw(ACanvas: TCanvas; const R: TRect);
var
  LAlpha1: Byte;
  LAlpha2: Byte;
  LRect1: TRect;
  LRect2: TRect;
  LSaveRgn: TRegionHandle;
begin
  LSaveRgn := acSaveClipRegion(ACanvas.Handle);
  try
    if acIntersectClipRegion(ACanvas.Handle, R) then
    begin
      Animator.Calculate(Progress, FFrame1.Size, R, LRect1, LRect2, LAlpha1, LAlpha2);
      FFrame1.DrawBlend(ACanvas, LRect1, LAlpha1);
      FFrame2.DrawBlend(ACanvas, LRect2, LAlpha2);
    end;
  finally
    acRestoreClipRegion(ACanvas.Handle, LSaveRgn);
  end;
end;

procedure TACLBitmapAnimation.Initialize;
begin
  if Animator.ReverseOrder then
    TACLMath.ExchangePtr(FFrame1, FFrame2);
  inherited;
end;

function TACLBitmapAnimation.IsReady: Boolean;
begin
  Result := not (FFrame1.Empty or FFrame2.Empty);
end;
{$ENDREGION}

initialization

finalization
  FreeAndNil(FAnimationManager);
end.
