{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*             Animation Manager             *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.Animation;

{$I ACL.Config.inc}

interface

uses
  UITypes, Types, Windows, Messages, Classes, Controls, Graphics, Generics.Collections,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Layers,
  ACL.UI.Forms,
  ACL.Utils.Common;

type
  TACLAnimation = class;

  { IACLAnimateControl }

  IACLAnimateControl = interface
  ['{49F437A3-B40C-4463-81E3-9F4462D956FD}']
    procedure Animate;
  end;

  TACLAnimationTransitionMode = (ateLinear, ateAccelerateDecelerate, ateTanh);
  TACLAnimationTransitionModeProc = function (AProgress: Single): Single;

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
    FTransitionModeProc: TACLAnimationTransitionModeProc;

    class function AccelerateDecelerateTransition(AProgress: Single): Single; static;
    class function LinearTransition(AProgress: Single): Single; static;
    class function TanhTransition(AProgress: Single): Single; static;

    procedure SetFinished(AValue: Boolean);
  protected
    procedure Animate;
    procedure InitializeTime;
    function IsCompatible(AAnimation: TACLAnimation): Boolean; virtual;
    // Events
    procedure DoAnimate; virtual;

    property CurrentTime: Int64 read FCurrentTime write FCurrentTime;
    property FinishTime: Int64 read FFinishTime write FFinishTime;
    property StartTime: Int64 read FStartTime write FStartTime;
    property TimerInterval: Cardinal read FTimerInterval write FTimerInterval;
    property TransitionModeProc: TACLAnimationTransitionModeProc read FTransitionModeProc;
  public
    constructor Create(const AControl: IACLAnimateControl; const ATime: Cardinal;
      ATransitionMode: TACLAnimationTransitionMode = ateLinear); virtual;
    destructor Destroy; override;
    procedure Draw(DC: HDC; const R: TRect); virtual;
    procedure Run;
    procedure RunImmediate;
    procedure Terminate;

    property Control: IACLAnimateControl read FControl;
    property Finished: Boolean read FFinished write SetFinished;
    property FreeOnTerminate: Boolean read FFreeOnTerminate write FFreeOnTerminate;
    property Progress: Single read FProgress;
    property Tag: NativeInt read FTag write FTag;
    property Time: Cardinal read FTime;
  end;

  { TACLAnimationText }

  TACLAnimationText = class(TACLAnimation)
  strict private
    FSourceText: string;
    FTargetText: string;
  private
    function GetActualText: string;
  public
    constructor Create(const ASourceText, ATargetText: string; const AControl: IACLAnimateControl;
      const ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode = ateLinear); reintroduce;
    //
    property ActualText: string read GetActualText;
    property SourceText: string read FSourceText;
    property TargetText: string read FTargetText;
  end;

  { TACLAnimationManager }

  TACLAnimationManager = class(TACLTimerList<TACLAnimation>)
  protected
    procedure DoAdding(const AObject: TACLAnimation); override;
    procedure TimerObject(const AObject: TACLAnimation); override;
  public
    constructor Create; reintroduce;
    function Find(AControl: IACLAnimateControl; out AAnimation: TACLAnimation; ATag: NativeInt = 0): Boolean;
    function Draw(AControl: IACLAnimateControl; DC: HDC; const R: TRect; ATag: NativeInt = 0): Boolean;
    procedure RemoveOwner(AOwnerObject: TObject);
  end;

  { TACLCustomBitmapAnimation }

  TACLCustomBitmapAnimation = class(TACLAnimation)
  strict private
    function CanAnimate(const R: TRect): Boolean;
  protected
    FFrame1: TACLBitmap;
    FFrame2: TACLBitmap;

    procedure DrawContent(DC: HDC; const R: TRect); virtual; abstract;
  public
    constructor Create(const AControl: IACLAnimateControl; const ATime: Cardinal;
      ATransitionMode: TACLAnimationTransitionMode = ateLinear); override;
    destructor Destroy; override;
    function AllocateFrame1(const R: TRect): TACLBitmap;
    function AllocateFrame2(const R: TRect): TACLBitmap;
    procedure Draw(DC: HDC; const R: TRect); override;

    property Frame1: TACLBitmap read FFrame1;
    property Frame2: TACLBitmap read FFrame2;
  end;

  { TACLBitmapFadingAnimation }

  TACLBitmapFadingAnimation = class(TACLCustomBitmapAnimation)
  strict private
    FLayer1: TACLBitmapLayer;
    FLayer2: TACLBitmapLayer;
  protected
    procedure DrawContent(DC: HDC; const R: TRect); override;
  public
    destructor Destroy; override;
  end;

  { TACLBitmapSlideAnimation }

  TACLBitmapSlideAnimationMode = (samLeftToRight, samRightToLeft, samTopToBottom, samBottomToTop);

  TACLBitmapSlideAnimation = class(TACLCustomBitmapAnimation)
  strict private
    FMode: TACLBitmapSlideAnimationMode;
  protected
    procedure DrawContent(DC: HDC; const R: TRect); override;
  public
    constructor Create(AMode: TACLBitmapSlideAnimationMode; AControl: IACLAnimateControl;
      ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode = ateLinear); reintroduce;
    //
    property Mode: TACLBitmapSlideAnimationMode read FMode;
  end;

  { TACLBitmapZoomAnimation }

  TACLBitmapZoomAnimationMode = (zamZoomIn, zamZoomOut);

  TACLBitmapZoomAnimation = class(TACLCustomBitmapAnimation)
  strict private
    FMode: TACLBitmapZoomAnimationMode;
  protected
    procedure DrawContent(DC: HDC; const R: TRect); override;
  public
    constructor Create(AMode: TACLBitmapZoomAnimationMode; AControl: IACLAnimateControl;
      ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode = ateLinear); reintroduce;
    //
    property Mode: TACLBitmapZoomAnimationMode read FMode;
  end;

  { TACLBitmapPaperSlideAnimation }

  TACLBitmapPaperSlideAnimation = class(TACLBitmapSlideAnimation)
  strict private
    FBackgroundOffsetInPercents: Single;
    FBackgroundOpacity: Single;
    FBackgroundOpacityAssigned: Boolean;
    FBackwardDirection: Boolean;
    FForegroundOpacity: Single;
    FForegroundOpacityAssigned: Boolean;

    function GetBackgroundAlpha: Byte;
    function GetForegroundAlpha: Byte;
    function GetProgress: Single;
  protected
    procedure DrawContent(DC: HDC; const R: TRect); override;
  public
    constructor Create(AMode: TACLBitmapSlideAnimationMode; AControl: IACLAnimateControl; ATime: Cardinal;
      ABackwardDirection: Boolean; ABackgroundOpacity, AForegroundOpacity, ABackgroundOffsetInPercents: Single;
      ATransitionMode: TACLAnimationTransitionMode = ateLinear); reintroduce;
    //
    property BackgroundOffsetInPercents: Single read FBackgroundOffsetInPercents;
    property BackgroundOpacity: Single read FBackgroundOpacity;
    property BackwardDirection: Boolean read FBackwardDirection;
    property ForegroundOpacity: Single read FForegroundOpacity;
    property Progress: Single read GetProgress;
  end;

function AnimationManager: TACLAnimationManager;
implementation

uses
  SysUtils, Math, Forms, StrUtils;

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
  const ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode = ateLinear);
begin
  inherited Create;
  FTime := ATime;
  FControl := AControl;
  case ATransitionMode of
    ateAccelerateDecelerate:
      FTransitionModeProc := AccelerateDecelerateTransition;
    ateTanh:
      FTransitionModeProc := TanhTransition;
    else
      FTransitionModeProc := LinearTransition;
  end;
  FFreeOnTerminate := True;
end;

destructor TACLAnimation.Destroy;
begin
  if FAnimationManager <> nil then
    FAnimationManager.Remove(Self);
  inherited Destroy;
end;

procedure TACLAnimation.Draw(DC: HDC; const R: TRect);
begin
  // do nothing
end;

procedure TACLAnimation.Run;
begin
  InitializeTime;
  AnimationManager.Add(Self);
end;

procedure TACLAnimation.RunImmediate;
begin
  InitializeTime;
  while not Finished do
    Animate;
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
  FProgress := TransitionModeProc((CurrentTime - StartTime) / (FinishTime - StartTime));
  DoAnimate;
end;

procedure TACLAnimation.InitializeTime;
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

procedure TACLAnimation.DoAnimate;
begin
  Control.Animate;
end;

class function TACLAnimation.AccelerateDecelerateTransition(AProgress: Single): Single;
begin
  Result := -Power(AProgress - 1, 6) + 1;
end;

class function TACLAnimation.LinearTransition(AProgress: Single): Single;
begin
  Result := AProgress;
end;

class function TACLAnimation.TanhTransition(AProgress: Single): Single;
const
  AExactitude = 3;
var
  ATanh: Double;
begin
  ATanh := Tanh(AProgress * (2 * AExactitude) - AExactitude);
  Result := 1 / (2 * Tanh(AExactitude)) * (ATanh - Tanh(-AExactitude));
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
      InitializeTime;
    end;
    Animate;
  end;
end;

{ TACLAnimationText }

constructor TACLAnimationText.Create(const ASourceText, ATargetText: string;
  const AControl: IACLAnimateControl; const ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode);
var
  ASourceTextLength: Integer;
  ATargetTextLength: Integer;
begin
  inherited Create(AControl, ATime, ATransitionMode);

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
  SetLength(Result, L);
  for I := 1 to L do
    Result[I] := Char(Trunc(Ord(FSourceText[I]) * Progress + Ord(FTargetText[I]) * (1 - Progress)));
end;

{ TACLAnimationManager }

constructor TACLAnimationManager.Create;
begin
  inherited Create;
  Interval := 1;
end;

function TACLAnimationManager.Find(AControl: IACLAnimateControl; out AAnimation: TACLAnimation; ATag: NativeInt = 0): Boolean;
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

function TACLAnimationManager.Draw(AControl: IACLAnimateControl; DC: HDC; const R: TRect; ATag: NativeInt = 0): Boolean;
var
  AAnimation: TACLAnimation;
begin
  Result := Find(AControl, AAnimation, ATag);
  if Result then
    AAnimation.Draw(DC, R)
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

{ TACLCustomBitmapAnimation }

constructor TACLCustomBitmapAnimation.Create(const AControl: IACLAnimateControl;
  const ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode);
begin
  inherited Create(AControl, ATime, ATransitionMode);
  FFrame1 := TACLBitmap.CreateEx(0, 0, pf32bit);
  FFrame2 := TACLBitmap.CreateEx(0, 0, pf32bit);
end;

destructor TACLCustomBitmapAnimation.Destroy;
begin
  FreeAndNil(FFrame1);
  FreeAndNil(FFrame2);
  inherited Destroy;
end;

function TACLCustomBitmapAnimation.AllocateFrame1(const R: TRect): TACLBitmap;
begin
  Result := FFrame1;
  Result.SetSizeEx(R);
  Result.Reset;
end;

function TACLCustomBitmapAnimation.AllocateFrame2(const R: TRect): TACLBitmap;
begin
  Result := FFrame2;
  Result.SetSizeEx(R);
  Result.Reset;
end;

procedure TACLCustomBitmapAnimation.Draw(DC: HDC; const R: TRect);
var
  ASaveIndex: Integer;
begin
  if CanAnimate(R) then
  begin
    ASaveIndex := SaveDC(DC);
    try
      if acIntersectClipRegion(DC, R) then
        DrawContent(DC, R);
    finally
      RestoreDC(DC, ASaveIndex);
    end;
  end
  else
    Finished := True;
end;

function TACLCustomBitmapAnimation.CanAnimate(const R: TRect): Boolean;
begin
  Result := not FFrame1.Empty and not FFrame2.Empty and
    (R.Width = FFrame1.Width) and (R.Height = FFrame1.Height) and
    (FFrame1.Width = FFrame2.Width) and (FFrame1.Height = FFrame2.Height)
end;

{ TACLBitmapFadingAnimation }

destructor TACLBitmapFadingAnimation.Destroy;
begin
  FreeAndNil(FLayer1);
  FreeAndNil(FLayer2);
  inherited;
end;

procedure TACLBitmapFadingAnimation.DrawContent(DC: HDC; const R: TRect);
var
  AAlpha: Byte;
  I: Integer;
begin
  if FLayer1 = nil then
    FLayer1 := TACLBitmapLayer.Create(R);
  if FLayer2 = nil then
    FLayer2 := TACLBitmapLayer.Create(R);

  AAlpha := Trunc(MaxByte * Progress);
  acBitBlt(FLayer1.Handle, FFrame1, NullPoint);
  acBitBlt(FLayer2.Handle, FFrame2, NullPoint);
  for I := 0 to FLayer1.ColorCount - 1 do
    TACLColors.AlphaBlend(FLayer1.Colors^[I], FLayer2.Colors^[I], AAlpha, False);
  FLayer1.DrawBlend(DC, R.TopLeft);
end;

{ TACLBitmapSlideAnimation }

constructor TACLBitmapSlideAnimation.Create(AMode: TACLBitmapSlideAnimationMode;
  AControl: IACLAnimateControl; ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode);
begin
  inherited Create(AControl, ATime, ATransitionMode);
  FMode := AMode;
end;

procedure TACLBitmapSlideAnimation.DrawContent(DC: HDC; const R: TRect);
var
  AOffset: Integer;
begin
  case Mode of
    samLeftToRight:
      begin
        AOffset := Round(Progress * FFrame1.Width);
        acAlphaBlend(DC, FFrame1, acRectOffset(R, AOffset, 0));
        acAlphaBlend(DC, FFrame2, acRectOffset(R, AOffset - R.Width, 0));
      end;

    samRightToLeft:
      begin
        AOffset := Round((1 - Progress) * FFrame1.Width);
        acAlphaBlend(DC, FFrame1, acRectOffset(R, AOffset - R.Width, 0));
        acAlphaBlend(DC, FFrame2, acRectOffset(R, AOffset, 0));
      end;

    samTopToBottom:
      begin
        AOffset := Round(Progress * FFrame1.Height);
        acAlphaBlend(DC, FFrame1, acRectOffset(R, 0, AOffset));
        acAlphaBlend(DC, FFrame2, acRectOffset(R, 0, AOffset - R.Height));
      end;

    samBottomToTop:
      begin
        AOffset := Round((1 - Progress) * FFrame1.Height);
        acAlphaBlend(DC, FFrame1, acRectOffset(R, 0, AOffset - R.Height));
        acAlphaBlend(DC, FFrame2, acRectOffset(R, 0, AOffset));
      end;
  end;
end;

{ TACLBitmapZoomAnimation }

constructor TACLBitmapZoomAnimation.Create(AMode: TACLBitmapZoomAnimationMode;
  AControl: IACLAnimateControl; ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode);
begin
  inherited Create(AControl, ATime, ATransitionMode);
  FMode := AMode;
end;

procedure TACLBitmapZoomAnimation.DrawContent(DC: HDC; const R: TRect);
var
  ABitmap1: TACLBitmap;
  ABitmap2: TACLBitmap;
  ADeltaX: Integer;
  ADeltaY: Integer;
  AProgress: Single;
begin
  if Mode = zamZoomOut then
  begin
    AProgress := Progress;
    ABitmap1 := Frame1;
    ABitmap2 := Frame2;
  end
  else
  begin
    AProgress := 1 - Progress;
    ABitmap1 := Frame2;
    ABitmap2 := Frame1;
  end;

  ADeltaX := acRectWidth(R) div 2;
  ADeltaY := acRectHeight(R) div 2;
  acAlphaBlend(DC, ABitmap1, acRectInflate(R, -Round(ADeltaX * AProgress), -Round(ADeltaY * AProgress)), Round(MaxByte * (1 - AProgress)));
  acAlphaBlend(DC, ABitmap2, acRectInflate(R, Round(ADeltaX * (1 - AProgress)), Round(ADeltaY * (1 - AProgress))), Round(MaxByte * AProgress));
end;

{ TACLBitmapPaperSlideAnimation }

constructor TACLBitmapPaperSlideAnimation.Create(AMode: TACLBitmapSlideAnimationMode;
  AControl: IACLAnimateControl; ATime: Cardinal; ABackwardDirection: Boolean;
  ABackgroundOpacity, AForegroundOpacity, ABackgroundOffsetInPercents: Single;
  ATransitionMode: TACLAnimationTransitionMode);
begin
  inherited Create(AMode, AControl, ATime, ATransitionMode);
  FBackgroundOffsetInPercents := ABackgroundOffsetInPercents;
  FBackwardDirection := ABackwardDirection;
  FBackgroundOpacity := ABackgroundOpacity;
  FBackgroundOpacityAssigned := not SameValue(BackgroundOpacity, 1);
  FForegroundOpacity := AForegroundOpacity;
  FForegroundOpacityAssigned := not SameValue(ForegroundOpacity, 1);
end;

procedure TACLBitmapPaperSlideAnimation.DrawContent(DC: HDC; const R: TRect);

  function GetFrame1Offset(const ASize: Integer): Integer;
  begin
    Result := Round(Progress * ASize);
  end;

  function GetFrame2Offset(const ASize: Integer): Integer;
  begin
    Result := Round((1 - Progress) * BackgroundOffsetInPercents * ASize);
  end;

begin
  case Mode of
    samLeftToRight:
      begin
        acAlphaBlend(DC, FFrame2, acRectOffset(R, GetFrame2Offset(FFrame2.Width), 0), GetBackgroundAlpha);
        acAlphaBlend(DC, FFrame1, acRectOffset(R, GetFrame1Offset(FFrame1.Width), 0), GetForegroundAlpha);
      end;

    samRightToLeft:
      begin
        acAlphaBlend(DC, FFrame2, acRectOffset(R, -GetFrame2Offset(FFrame2.Width), 0), GetBackgroundAlpha);
        acAlphaBlend(DC, FFrame1, acRectOffset(R, -GetFrame1Offset(FFrame1.Width), 0), GetForegroundAlpha);
      end;

    samTopToBottom:
      begin
        acAlphaBlend(DC, FFrame2, acRectOffset(R, 0, GetFrame2Offset(FFrame2.Height)), GetBackgroundAlpha);
        acAlphaBlend(DC, FFrame1, acRectOffset(R, 0, GetFrame1Offset(FFrame1.Height)), GetForegroundAlpha);
      end;

    samBottomToTop:
      begin
        acAlphaBlend(DC, FFrame2, acRectOffset(R, 0, -GetFrame2Offset(FFrame2.Height)), GetBackgroundAlpha);
        acAlphaBlend(DC, FFrame1, acRectOffset(R, 0, -GetFrame1Offset(FFrame1.Height)), GetForegroundAlpha);
      end;
  end;
end;

function TACLBitmapPaperSlideAnimation.GetBackgroundAlpha: Byte;
begin
  if FBackgroundOpacityAssigned then
    Result := Round(MaxByte * (Progress + BackgroundOpacity * (1 - Progress)))
  else
    Result := MaxByte;
end;

function TACLBitmapPaperSlideAnimation.GetForegroundAlpha: Byte;
begin
  if FForegroundOpacityAssigned then
    Result := Round(MaxByte * ((1 - Progress) + ForegroundOpacity * Progress))
  else
    Result := MaxByte;
end;

function TACLBitmapPaperSlideAnimation.GetProgress: Single;
begin
  Result := inherited Progress;
  if BackwardDirection then
    Result := 1.0 - Result;
end;

initialization

finalization
  FreeAndNil(FAnimationManager);
end.
