////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Search thougth app controls
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Insight.Core;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLProc,
  LCLType,
{$ENDIF}
  {Winapi.}Messages,
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Generics.Defaults,
  {System.}Math,
  {System.}SysUtils,
  {System.}Types,
  {System.}TypInfo,
  System.UITypes,
  // Vcl
  {Vcl.}Menus,
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}Forms,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Geometry,
  ACL.Geometry.Utils,
  ACL.UI.Controls.Base,
  ACL.Utils.Strings;

type
  TACLUIInsightAdapter = class;
  TACLUIInsightAdapterClass = class of TACLUIInsightAdapter;
  TACLUIInsightSearchQueueBuilder = class;

  { TACLUIInsightCandidate }

  TACLUIInsightCandidate = class
  protected
    FLocation: TArray<TObject>;
    FLocationText: string;
    FText: string;
  public
    function Clone: TACLUIInsightCandidate;
    function GetLastVisibleObject: TObject;
    // Properties
    property Location: TArray<TObject> read FLocation;
    property LocationText: string read FLocationText;
    property Text: string read FText;
  end;

  { TACLUIInsightCandidates }

  TACLUIInsightCandidates = class(TACLObjectListOf<TACLUIInsightCandidate>);

  { TACLUIInsightSearchQueueBuilder }

  TACLUIInsightSearchQueueBuilder = class
  strict private
    FCandidates: TACLUIInsightCandidates;
    FNestedCaptions: TStack<string>;
    FNestedObjects: TStack<TObject>;

    function GetCurrentLocation: string;
  public
    constructor Create(ATarget: TACLUIInsightCandidates);
    destructor Destroy; override;
    procedure Add(AObject: TObject);
    procedure AddCandidate(AObject: TObject; const AValue: string);
    procedure AddChildren(AObject: TObject);
  end;

  { TACLUIInsight }

  TACLUIInsight = class
  strict private
    class var FClassAdapters: TACLClassMap<TACLUIInsightAdapterClass>;
    class var FObjectAdapters: TACLDictionary<TObject, TACLUIInsightAdapterClass>;
  public
    class constructor Create;
    class destructor Destroy;
    class function GetAdapter(AObject: TObject; out AAdapter: TACLUIInsightAdapterClass): Boolean;
    class procedure Register(AClass: TClass; AAdapter: TACLUIInsightAdapterClass); overload;
    class procedure Register(AObject: TObject; AAdapter: TACLUIInsightAdapterClass); overload;
    class procedure Unregister(AClass: TClass); overload;
    class procedure Unregister(AObject: TObject); overload;
  end;

  { TACLUIInsightAdapter }

  TACLUIInsightAdapter = class
  public
    class function GetCaption(AObject: TObject; out AValue: string): Boolean; virtual;
    class procedure GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder); virtual;
    class function GetGroupCaption(AObject: TObject; out AValue: string): Boolean; virtual;
    class function GetKeywors(AObject: TObject; out AValue: string): Boolean; virtual;
    class function GetPosition(AObject: TObject; out ABounds: TRect; out AParent: TWinControl): Boolean; virtual;
    class function MakeVisible(AObject: TObject): Boolean; virtual;
  end;

  { TACLUIInsightAdapterControl }

  TACLUIInsightAdapterControl = class(TACLUIInsightAdapter)
  public
    class function GetCaption(AObject: TObject; out AValue: string): Boolean; override;
    class function GetKeywors(AObject: TObject; out AValue: string): Boolean; override;
    class function GetPosition(AObject: TObject; out ABounds: TRect; out AParent: TWinControl): Boolean; override;
  end;

  { TACLUIInsightAdapterWinControl }

  TACLUIInsightAdapterWinControl = class(TACLUIInsightAdapterControl)
  public
    class procedure GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder); override;
  end;

implementation

function TryGetPropValue(AObject: TObject; const APropName: string; out AValue: string): Boolean;
var
  APropInfo: PPropInfo;
begin
  APropInfo := GetPropInfo(AObject, APropName);
  if APropInfo <> nil then
  begin
    AValue := GetStrProp(AObject, APropInfo);
    Result := AValue <> '';
  end
  else
    Result := False;
end;

{ TACLUIInsightCandidate }

function TACLUIInsightCandidate.Clone: TACLUIInsightCandidate;
begin
  Result := TACLUIInsightCandidate.Create;
  Result.FLocation := FLocation;
  Result.FLocationText := FLocationText;
  Result.FText := FText;
end;

function TACLUIInsightCandidate.GetLastVisibleObject: TObject;
var
  LAdapter: TACLUIInsightAdapterClass;
  LObject: TObject;
  I: Integer;
begin
  for I := 0 to Length(Location) - 1 do
  begin
    LObject := Location[I];
    if not TACLUIInsight.GetAdapter(LObject, LAdapter) then
      raise EInvalidOperation.CreateFmt('Adapter was not found for "%s"', [LObject.ClassName]);
    if not LAdapter.MakeVisible(LObject) then
      Exit(LObject);
  end;
  Result := Location[High(Location)];
end;

{ TACLUIInsightSearchQueueBuilder }

constructor TACLUIInsightSearchQueueBuilder.Create(ATarget: TACLUIInsightCandidates);
begin
  FCandidates := ATarget;
  FNestedCaptions := TStack<string>.Create;
  FNestedObjects := TStack<TObject>.Create;
end;

destructor TACLUIInsightSearchQueueBuilder.Destroy;
begin
  FreeAndNil(FNestedObjects);
  FreeAndNil(FNestedCaptions);
  inherited;
end;

procedure TACLUIInsightSearchQueueBuilder.Add(AObject: TObject);
var
  AAdapter: TACLUIInsightAdapterClass;
  AValue: string;
begin
  if TACLUIInsight.GetAdapter(AObject, AAdapter) then
  begin
    FNestedObjects.Push(AObject);
    try
      if AAdapter.GetCaption(AObject, AValue) then
        AddCandidate(AObject, AValue);
      if AAdapter.GetKeywors(AObject, AValue) then
        AddCandidate(AObject, AValue);
      if AAdapter.GetGroupCaption(AObject, AValue) and (AValue <> '') then
      begin
        FNestedCaptions.Push(AValue);
        try
          AAdapter.GetChildren(AObject, Self);
        finally
          FNestedCaptions.Pop;
        end;
      end
      else
        AAdapter.GetChildren(AObject, Self);
    finally
      FNestedObjects.Pop;
    end;
  end;
end;

procedure TACLUIInsightSearchQueueBuilder.AddChildren(AObject: TObject);
var
  AAdapter: TACLUIInsightAdapterClass;
begin
  if TACLUIInsight.GetAdapter(AObject, AAdapter) then
    AAdapter.GetChildren(AObject, Self);
end;

function TACLUIInsightSearchQueueBuilder.GetCurrentLocation: string;
var
  B: TACLStringBuilder;
{$IFNDEF DELPHI110ALEXANDRIA}
  C: TArray<string>;
{$ENDIF}
  I: Integer;
begin
  Result := '';
  if FNestedCaptions.Count > 0 then
  begin
    B := TACLStringBuilder.Get;
    try
    {$IFNDEF DELPHI110ALEXANDRIA}
      C := FNestedCaptions.ToArray;
    {$ENDIF}
      for I := 0 to FNestedCaptions.Count - 1 do
      begin
        if B.Length > 0 then
          B.Append(' » ');
      {$IFDEF DELPHI110ALEXANDRIA}
        B.Append(FNestedCaptions.List[I]);
      {$ELSE}
        B.Append(C[I]);
      {$ENDIF}
      end;
      Result := B.ToString;
    finally
      B.Release;
    end;
  end;
end;

procedure TACLUIInsightSearchQueueBuilder.AddCandidate(AObject: TObject; const AValue: string);
var
  ACandidate: TACLUIInsightCandidate;
begin
  if AValue <> '' then
  begin
    ACandidate := TACLUIInsightCandidate.Create;
    ACandidate.FLocation := FNestedObjects.ToArray;
    ACandidate.FLocationText := GetCurrentLocation;
    ACandidate.FText := AValue;
    FCandidates.Add(ACandidate);
  end;
end;

{ TACLUIInsight }

class constructor TACLUIInsight.Create;
begin
  Register(TControl, TACLUIInsightAdapterControl);
  Register(TWinControl, TACLUIInsightAdapterWinControl);
end;

class destructor TACLUIInsight.Destroy;
begin
  FreeAndNil(FObjectAdapters);
  FreeAndNil(FClassAdapters);
end;

class function TACLUIInsight.GetAdapter(AObject: TObject; out AAdapter: TACLUIInsightAdapterClass): Boolean;
begin
  if (FObjectAdapters <> nil) and FObjectAdapters.TryGetValue(AObject, AAdapter) then
    Exit(True);
  if (FClassAdapters <> nil) and FClassAdapters.TryGetValue(AObject, AAdapter) then
    Exit(True);
  Result := False;
end;

class procedure TACLUIInsight.Register(AObject: TObject; AAdapter: TACLUIInsightAdapterClass);
begin
  if FObjectAdapters = nil then
    FObjectAdapters := TACLDictionary<TObject, TACLUIInsightAdapterClass>.Create;
  FObjectAdapters.Add(AObject, AAdapter);
end;

class procedure TACLUIInsight.Register(AClass: TClass; AAdapter: TACLUIInsightAdapterClass);
begin
  if FClassAdapters = nil then
    FClassAdapters := TACLClassMap<TACLUIInsightAdapterClass>.Create;
  FClassAdapters.Add(AClass, AAdapter);
end;

class procedure TACLUIInsight.Unregister(AClass: TClass);
begin
  if FClassAdapters <> nil then
    FClassAdapters.Remove(AClass);
end;

class procedure TACLUIInsight.Unregister(AObject: TObject);
begin
  if FObjectAdapters <> nil then
    FObjectAdapters.Remove(AObject);
end;

{ TACLUIInsightAdapter }

class function TACLUIInsightAdapter.GetCaption(AObject: TObject; out AValue: string): Boolean;
begin
  Result := False;
end;

class procedure TACLUIInsightAdapter.GetChildren(AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
begin
  // do nothing
end;

class function TACLUIInsightAdapter.GetGroupCaption(AObject: TObject; out AValue: string): Boolean;
begin
  Result := GetCaption(AObject, AValue);
end;

class function TACLUIInsightAdapter.GetKeywors(AObject: TObject; out AValue: string): Boolean;
begin
  Result := False;
end;

class function TACLUIInsightAdapter.GetPosition(
  AObject: TObject; out ABounds: TRect; out AParent: TWinControl): Boolean;
begin
  Result := False;
end;

class function TACLUIInsightAdapter.MakeVisible(AObject: TObject): Boolean;
begin
  Result := True;
end;

{ TACLUIInsightAdapterControl }

class function TACLUIInsightAdapterControl.GetPosition(
  AObject: TObject; out ABounds: TRect; out AParent: TWinControl): Boolean;
var
  LControl: TControl absolute AObject;
begin
  Result := TACLControls.IsVisible(LControl.Parent);
  if Result then
  begin
    AParent := LControl.Parent;
    ABounds := LControl.BoundsRect;
  end;
end;

class function TACLUIInsightAdapterControl.GetCaption(AObject: TObject; out AValue: string): Boolean;
begin
  Result := TryGetPropValue(AObject, 'Caption', AValue);
end;

class function TACLUIInsightAdapterControl.GetKeywors(AObject: TObject; out AValue: string): Boolean;
begin
  Result := TryGetPropValue(AObject, 'Hint', AValue);
end;

{ TACLUIInsightAdapterWinControl }

class procedure TACLUIInsightAdapterWinControl.GetChildren(
  AObject: TObject; ABuilder: TACLUIInsightSearchQueueBuilder);
var
  AControl: TControl;
  AWinControl: TWinControl absolute AObject;
  I: Integer;
begin
  for I := 0 to AWinControl.ControlCount - 1 do
  begin
    AControl := AWinControl.Controls[I];
    if AControl.Visible then
      ABuilder.Add(AControl);
  end;
end;

end.
