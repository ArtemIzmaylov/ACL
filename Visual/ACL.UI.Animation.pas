﻿////////////////////////////////////////////////////////////////////////////////
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
  ACL.Timers,
  ACL.Utils.Common;

type
  TACLAnimation = class;

  { IACLAnimateControl }

  IACLAnimateControl = interface
  ['{49F437A3-B40C-4463-81E3-9F4462D956FD}']
    procedure Animate;
  end;

  TACLAnimationDrawProc = procedure (ACanvas: TCanvas; const R: TRect) of object;

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
    //# Properties
    property CurrentTime: Int64 read FCurrentTime write FCurrentTime;
    property FinishTime: Int64 read FFinishTime write FFinishTime;
    property StartTime: Int64 read FStartTime write FStartTime;
    property TimerInterval: Cardinal read FTimerInterval write FTimerInterval;
    property TransitionModeProc: TACLAnimationTransitionModeProc read FTransitionModeProc;
  public
    constructor Create(const AControl: IACLAnimateControl; ATime: Cardinal;
      ATransitionMode: TACLAnimationTransitionMode = ateLinear); virtual;
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

  { TACLAnimationText }

  TACLAnimationText = class(TACLAnimation)
  strict private
    FSourceText: string;
    FTargetText: string;
  private
    function GetActualText: string;
  public
    constructor Create(const ASourceText, ATargetText: string;
      const AControl: IACLAnimateControl; ATime: Cardinal;
      ATransitionMode: TACLAnimationTransitionMode = ateLinear); reintroduce;
    //# Properties
    property ActualText: string read GetActualText;
    property SourceText: string read FSourceText;
    property TargetText: string read FTargetText;
  end;

  { TACLAnimationManager }

  TACLAnimationManager = class(TACLTimerListOf<TACLAnimation>)
  protected
    procedure DoAdding(const AObject: TACLAnimation); override;
    procedure TimerObject(const AObject: TACLAnimation); override;
  public
    constructor Create; reintroduce;
    function Find(AControl: IACLAnimateControl;
      out AAnimation: TACLAnimation; ATag: NativeInt = 0): Boolean;
    function Draw(AControl: IACLAnimateControl;
      ACanvas: TCanvas; const R: TRect; ATag: NativeInt = 0): Boolean;
    procedure RemoveOwner(AOwnerObject: TObject);
  end;

  { TACLCustomBitmapAnimation }

  TACLCustomBitmapAnimation = class(TACLAnimation)
  strict private
    FFrame1: TACLDib;
    FFrame2: TACLDib;
    function CanAnimate(const R: TRect): Boolean;
  protected
    procedure DrawContent(ACanvas: TCanvas; const R: TRect); virtual; abstract;
  public
    constructor Create(const AControl: IACLAnimateControl; ATime: Cardinal;
      ATransitionMode: TACLAnimationTransitionMode = ateLinear); override;
    destructor Destroy; override;
    function AllocateFrame1(const R: TRect): TACLDib; overload;
    function AllocateFrame2(const R: TRect): TACLDib; overload;
    procedure AllocateFrame1(const R: TRect; AProc: TACLAnimationDrawProc); overload;
    procedure AllocateFrame2(const R: TRect; AProc: TACLAnimationDrawProc); overload;
    procedure Draw(ACanvas: TCanvas; const R: TRect); override;
    //# Properties
    property Frame1: TACLDib read FFrame1;
    property Frame2: TACLDib read FFrame2;
  end;

  { TACLBitmapFadingAnimation }

  TACLBitmapFadingAnimation = class(TACLCustomBitmapAnimation)
  strict private
    FLayer1: TACLDib;
    FLayer2: TACLDib;
  protected
    procedure DrawContent(ACanvas: TCanvas; const R: TRect); override;
  public
    destructor Destroy; override;
  end;

  { TACLBitmapSlideAnimation }

  TACLBitmapSlideAnimationMode = (samLeftToRight, samRightToLeft, samTopToBottom, samBottomToTop);

  TACLBitmapSlideAnimation = class(TACLCustomBitmapAnimation)
  strict private
    FMode: TACLBitmapSlideAnimationMode;
  protected
    procedure DrawContent(ACanvas: TCanvas; const R: TRect); override;
  public
    constructor Create(AMode: TACLBitmapSlideAnimationMode; AControl: IACLAnimateControl;
      ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode = ateLinear); reintroduce;
    //# Properties
    property Mode: TACLBitmapSlideAnimationMode read FMode;
  end;

  { TACLBitmapZoomAnimation }

  TACLBitmapZoomAnimationMode = (zamZoomIn, zamZoomOut);

  TACLBitmapZoomAnimation = class(TACLCustomBitmapAnimation)
  strict private
    FMode: TACLBitmapZoomAnimationMode;
  protected
    procedure DrawContent(ACanvas: TCanvas; const R: TRect); override;
  public
    constructor Create(AMode: TACLBitmapZoomAnimationMode; AControl: IACLAnimateControl;
      ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode = ateLinear); reintroduce;
    //# Properties
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
    procedure DrawContent(ACanvas: TCanvas; const R: TRect); override;
  public
    constructor Create(AMode: TACLBitmapSlideAnimationMode; AControl: IACLAnimateControl; ATime: Cardinal;
      ABackwardDirection: Boolean; ABackgroundOpacity, AForegroundOpacity, ABackgroundOffsetInPercents: Single;
      ATransitionMode: TACLAnimationTransitionMode = ateLinear); reintroduce;
    //# Properties
    property BackgroundOffsetInPercents: Single read FBackgroundOffsetInPercents;
    property BackgroundOpacity: Single read FBackgroundOpacity;
    property BackwardDirection: Boolean read FBackwardDirection;
    property ForegroundOpacity: Single read FForegroundOpacity;
    property Progress: Single read GetProgress;
  end;

function AnimationManager: TACLAnimationManager;
implementation

uses
  {System.}Math,
  {System.}StrUtils,
  {System.}SysUtils,
  // VCL
  {Vcl.}Forms;

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
  ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode = ateLinear);
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

procedure TACLAnimation.Draw(ACanvas: TCanvas; const R: TRect);
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
  Exactitude = 3;
var
  ATanh: Double;
begin
  ATanh := Tanh(AProgress * (2 * Exactitude) - Exactitude);
  Result := 1 / (2 * Tanh(Exactitude)) * (ATanh - Tanh(-Exactitude));
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
  const AControl: IACLAnimateControl; ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode);
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
  SetLength(Result{%H-}, L);
  for I := 1 to L do
    Result[I] := Char(Trunc(Ord(FSourceText[I]) * Progress + Ord(FTargetText[I]) * (1 - Progress)));
end;

{ TACLAnimationManager }

constructor TACLAnimationManager.Create;
begin
  inherited Create;
  Interval := 1;
end;

function TACLAnimationManager.Find(AControl: IACLAnimateControl;
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

function TACLAnimationManager.Draw(AControl: IACLAnimateControl;
  ACanvas: TCanvas; const R: TRect; ATag: NativeInt = 0): Boolean;
var
  AAnimation: TACLAnimation;
begin
  Result := Find(AControl, AAnimation, ATag);
  if Result then
    AAnimation.Draw(ACanvas, R)
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
  ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode);
begin
  inherited Create(AControl, ATime, ATransitionMode);
  FFrame1 := TACLDib.Create(0, 0);
  FFrame2 := TACLDib.Create(0, 0);
end;

destructor TACLCustomBitmapAnimation.Destroy;
begin
  FreeAndNil(FFrame1);
  FreeAndNil(FFrame2);
  inherited Destroy;
end;

function TACLCustomBitmapAnimation.AllocateFrame1(const R: TRect): TACLDib;
begin
  Result := FFrame1;
  Result.Resize(R);
  Result.Reset;
end;

procedure TACLCustomBitmapAnimation.AllocateFrame1(const R: TRect; AProc: TACLAnimationDrawProc);
begin
  if not R.IsEmpty then
  begin
    with AllocateFrame1(R) do
      AProc(Canvas, ClientRect);
  end;
end;

function TACLCustomBitmapAnimation.AllocateFrame2(const R: TRect): TACLDib;
begin
  Result := FFrame2;
  Result.Resize(R);
  Result.Reset;
end;

procedure TACLCustomBitmapAnimation.AllocateFrame2(const R: TRect; AProc: TACLAnimationDrawProc);
begin
  if not R.IsEmpty then
  begin
    with AllocateFrame2(R) do
      AProc(Canvas, ClientRect);
  end;
end;

procedure TACLCustomBitmapAnimation.Draw(ACanvas: TCanvas; const R: TRect);
var
  LSaveRgn: TRegionHandle;
begin
  if CanAnimate(R) then
  begin
    LSaveRgn := acSaveClipRegion(ACanvas.Handle);
    try
      if acIntersectClipRegion(ACanvas.Handle, R) then
        DrawContent(ACanvas, R);
    finally
      acRestoreClipRegion(ACanvas.Handle, LSaveRgn);
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

procedure TACLBitmapFadingAnimation.DrawContent(ACanvas: TCanvas; const R: TRect);
var
  AAlpha: Byte;
  I: Integer;
begin
  if FLayer1 = nil then
    FLayer1 := TACLDib.Create(R);
  if FLayer2 = nil then
    FLayer2 := TACLDib.Create(R);

  AAlpha := Trunc(MaxByte * Progress);
  FLayer1.Assign(Frame1);
  FLayer2.Assign(Frame2);
  for I := 0 to FLayer1.ColorCount - 1 do
    TACLColors.AlphaBlend(FLayer1.Colors^[I], FLayer2.Colors^[I], AAlpha, False);
  FLayer1.DrawBlend(ACanvas, R);
end;

{ TACLBitmapSlideAnimation }

constructor TACLBitmapSlideAnimation.Create(AMode: TACLBitmapSlideAnimationMode;
  AControl: IACLAnimateControl; ATime: Cardinal; ATransitionMode: TACLAnimationTransitionMode);
begin
  inherited Create(AControl, ATime, ATransitionMode);
  FMode := AMode;
end;

procedure TACLBitmapSlideAnimation.DrawContent(ACanvas: TCanvas; const R: TRect);
var
  LOffset: Integer;
begin
  case Mode of
    samLeftToRight:
      begin
        LOffset := Round(Progress * Frame1.Width);
        Frame1.DrawBlend(ACanvas, R.OffsetTo(LOffset, 0));
        Frame2.DrawBlend(ACanvas, R.OffsetTo(LOffset - R.Width, 0));
      end;

    samRightToLeft:
      begin
        LOffset := Round((1 - Progress) * Frame1.Width);
        Frame1.DrawBlend(ACanvas, R.OffsetTo(LOffset - R.Width, 0));
        Frame2.DrawBlend(ACanvas, R.OffsetTo(LOffset, 0));
      end;

    samTopToBottom:
      begin
        LOffset := Round(Progress * Frame1.Height);
        Frame1.DrawBlend(ACanvas, R.OffsetTo(0, LOffset));
        Frame2.DrawBlend(ACanvas, R.OffsetTo(0, LOffset - R.Height));
      end;

    samBottomToTop:
      begin
        LOffset := Round((1 - Progress) * Frame1.Height);
        Frame1.DrawBlend(ACanvas, R.OffsetTo(0, LOffset - R.Height));
        Frame2.DrawBlend(ACanvas, R.OffsetTo(0, LOffset));
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

procedure TACLBitmapZoomAnimation.DrawContent(ACanvas: TCanvas; const R: TRect);
var
  ABitmap1: TACLDib;
  ABitmap2: TACLDib;
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

  ADeltaX := R.Width div 2;
  ADeltaY := R.Height div 2;
  ABitmap1.DrawBlend(ACanvas,
    R.InflateTo(-Round(ADeltaX * AProgress), -Round(ADeltaY * AProgress)),
    Round(MaxByte * (1 - AProgress)));
  ABitmap2.DrawBlend(ACanvas,
    R.InflateTo(Round(ADeltaX * (1 - AProgress)), Round(ADeltaY * (1 - AProgress))),
    Round(MaxByte * AProgress));
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

procedure TACLBitmapPaperSlideAnimation.DrawContent(ACanvas: TCanvas; const R: TRect);

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
        Frame2.DrawBlend(ACanvas, R.OffsetTo(GetFrame2Offset(Frame2.Width), 0), GetBackgroundAlpha);
        Frame1.DrawBlend(ACanvas, R.OffsetTo(GetFrame1Offset(Frame1.Width), 0), GetForegroundAlpha);
      end;

    samRightToLeft:
      begin
        Frame2.DrawBlend(ACanvas, R.OffsetTo(-GetFrame2Offset(Frame2.Width), 0), GetBackgroundAlpha);
        Frame1.DrawBlend(ACanvas, R.OffsetTo(-GetFrame1Offset(Frame1.Width), 0), GetForegroundAlpha);
      end;

    samTopToBottom:
      begin
        Frame2.DrawBlend(ACanvas, R.OffsetTo(0, GetFrame2Offset(Frame2.Height)), GetBackgroundAlpha);
        Frame1.DrawBlend(ACanvas, R.OffsetTo(0, GetFrame1Offset(Frame1.Height)), GetForegroundAlpha);
      end;

    samBottomToTop:
      begin
        Frame2.DrawBlend(ACanvas, R.OffsetTo(0, -GetFrame2Offset(Frame2.Height)), GetBackgroundAlpha);
        Frame1.DrawBlend(ACanvas, R.OffsetTo(0, -GetFrame1Offset(Frame1.Height)), GetForegroundAlpha);
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
