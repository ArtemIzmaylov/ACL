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

unit ACL.UI.Controls.BindingDiagram.Types;

{$I ACL.Config.inc}

interface

uses
  System.Types,
  System.SysUtils,
  System.Classes,
  // Vcl
  Vcl.Controls,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.Geometry,
  ACL.Graphics,
  ACL.Graphics.Gdiplus,
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

type
  TACLBindingDiagramData = class;
  TACLBindingDiagramObjectPin = class;
  TACLBindingDiagramObjectPinMode = (opmInput, opmOutput);
  TACLBindingDiagramObjectPinModes = set of TACLBindingDiagramObjectPinMode;

  { TACLBindingDiagramObject }

  TACLBindingDiagramObject = class(TACLLockablePersistent)
  strict private
    FCanRemove: Boolean;
    FCaption: UnicodeString;
    FData: Pointer;
    FHint: string;
    FOwner: TACLBindingDiagramData;
    FPosition: TPoint;
    FTag: NativeInt;

    function GetPin(Index: Integer): TACLBindingDiagramObjectPin; inline;
    function GetPinCount: Integer; inline;
    procedure SetCanRemove(const Value: Boolean);
    procedure SetCaption(const Value: UnicodeString);
    procedure SetPosition(const Value: TPoint);
    //
    procedure ListChanged(Sender: TObject = nil);
  protected
    FPins: TACLObjectList;

    procedure DoChanged(AChanges: TACLPersistentChanges); override;
    procedure DoPinRemoving(Sender: TObject);
  public
    constructor Create(AOwner: TACLBindingDiagramData); virtual;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    function Add(const ACaption: string; AMode: TACLBindingDiagramObjectPinModes; ATag: NativeInt = 0): TACLBindingDiagramObjectPin;
    procedure Clear;
    procedure Delete(Index: Integer);
    function Find(const ACaption: string): TACLBindingDiagramObjectPin;
    //
    property CanRemove: Boolean read FCanRemove write SetCanRemove;
    property Caption: UnicodeString read FCaption write SetCaption;
    property Hint: string read FHint write FHint;
    property PinCount: Integer read GetPinCount;
    property Pins[Index: Integer]: TACLBindingDiagramObjectPin read GetPin;
    property Position: TPoint read FPosition write SetPosition;
    // CustomData
    property Data: Pointer read FData write FData;
    property Tag: NativeInt read FTag write FTag default 0;
  end;

  { TACLBindingDiagramObjectPin }

  TACLBindingDiagramObjectPin = class
  strict private
    FCaption: string;
    FMode: TACLBindingDiagramObjectPinModes;
    FOwner: TACLBindingDiagramObject;
    FTag: NativeInt;

    procedure SetCaption(const Value: string);
    procedure SetMode(const Value: TACLBindingDiagramObjectPinModes);
  private
    function GetIndex: Integer;
  protected
    procedure Changed;
  public
    constructor Create(AOwner: TACLBindingDiagramObject);
    procedure BeforeDestruction; override;
    //
    property Caption: string read FCaption write SetCaption;
    property Index: Integer read GetIndex;
    property Mode: TACLBindingDiagramObjectPinModes read FMode write SetMode;
    property Owner: TACLBindingDiagramObject read FOwner;
    property Tag: NativeInt read FTag write FTag;
  end;

  { TACLBindingDiagramLink }

  TACLBindingDiagramLinkArrow = (laInput, laOutput);
  TACLBindingDiagramLinkArrows = set of TACLBindingDiagramLinkArrow;

  TACLBindingDiagramLink = class(TACLLockablePersistent)
  strict private
    FArrows: TACLBindingDiagramLinkArrows;
    FHint: string;
    FOwner: TACLBindingDiagramData;
    FSource: TACLBindingDiagramObjectPin;
    FTag: NativeInt;
    FTarget: TACLBindingDiagramObjectPin;

    procedure SetArrows(AValue: TACLBindingDiagramLinkArrows);
  protected
    procedure DoChanged(AChanges: TACLPersistentChanges); override;
    function IsUsed(AObject: TObject): Boolean;
    procedure SetSource(AValue: TACLBindingDiagramObjectPin);
    procedure SetTarget(AValue: TACLBindingDiagramObjectPin);
  public
    constructor Create(AOwner: TACLBindingDiagramData);
    procedure BeforeDestruction; override;
    //
    property Arrows: TACLBindingDiagramLinkArrows read FArrows write SetArrows;
    property Hint: string read FHint write FHint;
    property Source: TACLBindingDiagramObjectPin read FSource;
    property Tag: NativeInt read FTag write FTag;
    property Target: TACLBindingDiagramObjectPin read FTarget;
  end;

  { TACLBindingDiagramData }

  TACLBindingDiagramData = class(TACLLockablePersistent)
  strict private
    FLinks: TACLList;
    FObjects: TACLList;

    function GetLink(Index: Integer): TACLBindingDiagramLink;
    function GetLinkCount: Integer;
    function GetObject(Index: Integer): TACLBindingDiagramObject; inline;
    function GetObjectCount: Integer; inline;
    procedure ListChanged(Sender: TObject = nil);
  protected
    FOnChange: TACLPersistentChangeEvent;

    procedure DoChanged(AChanges: TACLPersistentChanges); override;
    procedure DoLinkRemoving(Sender: TObject);
    procedure DoLinksValidate(Removing: TObject);
    procedure DoObjectRemoving(Sender: TObject);
    procedure DoPinRemoving(Sender: TObject);
  public
    constructor Create(AChangeEvent: TACLPersistentChangeEvent);
    destructor Destroy; override;
    function AddObject(const ACaption: string): TACLBindingDiagramObject;
    function AddLink(const ASource, ATarget: TACLBindingDiagramObjectPin; AArrows: TACLBindingDiagramLinkArrows = []): TACLBindingDiagramLink;
    procedure Clear;
    procedure ClearLinks;
    function ContainsLink(const ASource, ATarget: TACLBindingDiagramObjectPin): Boolean;
    //
    property ObjectCount: Integer read GetObjectCount;
    property Objects[Index: Integer]: TACLBindingDiagramObject read GetObject;
    property LinkCount: Integer read GetLinkCount;
    property Links[Index: Integer]: TACLBindingDiagramLink read GetLink;
  end;

implementation

uses
  ACL.Utils.Strings;

{ TACLBindingDiagramObject }

constructor TACLBindingDiagramObject.Create(AOwner: TACLBindingDiagramData);
begin
  inherited Create;
  FOwner := AOwner;
  FPins := TACLObjectList.Create;
  FPins.OnChanged := ListChanged;
  FPosition := InvalidPoint;
end;

destructor TACLBindingDiagramObject.Destroy;
begin
  FreeAndNil(FPins);
  inherited Destroy;
end;

procedure TACLBindingDiagramObject.BeforeDestruction;
begin
  inherited;
  FOwner.DoObjectRemoving(Self);
  FOwner := nil;
end;

function TACLBindingDiagramObject.Add(const ACaption: string;
  AMode: TACLBindingDiagramObjectPinModes; ATag: NativeInt): TACLBindingDiagramObjectPin;
begin
  BeginUpdate;
  try
    Result := TACLBindingDiagramObjectPin.Create(Self);
    Result.Caption := ACaption;
    Result.Mode := AMode;
    Result.Tag := ATag;
    FPins.Add(Result);
  finally
    EndUpdate;
  end;
end;

procedure TACLBindingDiagramObject.Clear;
begin
  BeginUpdate;
  try
    FPins.Clear;
  finally
    EndUpdate;
  end;
end;

procedure TACLBindingDiagramObject.Delete(Index: Integer);
begin
  FPins.Delete(Index);
end;

function TACLBindingDiagramObject.Find(const ACaption: string): TACLBindingDiagramObjectPin;
var
  I: Integer;
begin
  for I := 0 to PinCount - 1 do
  begin
    if acSameText(ACaption, Pins[I].Caption) then
      Exit(Pins[I]);
  end;
  Result := nil;
end;

procedure TACLBindingDiagramObject.DoChanged(AChanges: TACLPersistentChanges);
begin
  if FOwner <> nil then
    FOwner.Changed(AChanges);
end;

procedure TACLBindingDiagramObject.DoPinRemoving(Sender: TObject);
begin
  if FOwner <> nil then
    FOwner.DoPinRemoving(Sender);
  if FPins <> nil then
    FPins.Extract(Sender);
end;

function TACLBindingDiagramObject.GetPin(Index: Integer): TACLBindingDiagramObjectPin;
begin
  Result := FPins.List[Index];
end;

function TACLBindingDiagramObject.GetPinCount: Integer;
begin
  Result := FPins.Count;
end;

procedure TACLBindingDiagramObject.SetCanRemove(const Value: Boolean);
begin
  if FCanRemove <> Value then
  begin
    FCanRemove := Value;
    Changed;
  end;
end;

procedure TACLBindingDiagramObject.SetCaption(const Value: UnicodeString);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed;
  end;
end;

procedure TACLBindingDiagramObject.SetPosition(const Value: TPoint);
begin
  if FPosition <> Value then
  begin
    FPosition := Value;
    Changed([apcLayout]);
  end;
end;

procedure TACLBindingDiagramObject.ListChanged(Sender: TObject);
begin
  inherited Changed;
end;

{ TACLBindingDiagramObjectPin }

constructor TACLBindingDiagramObjectPin.Create(AOwner: TACLBindingDiagramObject);
begin
  FOwner := AOwner;
end;

procedure TACLBindingDiagramObjectPin.BeforeDestruction;
begin
  inherited;
  FOwner.DoPinRemoving(Self);
end;

procedure TACLBindingDiagramObjectPin.Changed;
begin
  FOwner.Changed;
end;

function TACLBindingDiagramObjectPin.GetIndex: Integer;
begin
  Result := FOwner.FPins.IndexOf(Self);
end;

procedure TACLBindingDiagramObjectPin.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed;
  end;
end;

procedure TACLBindingDiagramObjectPin.SetMode(const Value: TACLBindingDiagramObjectPinModes);
begin
  if FMode <> Value then
  begin
    FMode := Value;
    Changed;
  end;
end;

{ TACLBindingDiagramLink }

constructor TACLBindingDiagramLink.Create(AOwner: TACLBindingDiagramData);
begin
  FOwner := AOwner;
end;

procedure TACLBindingDiagramLink.BeforeDestruction;
begin
  inherited;
  FOwner.DoLinkRemoving(Self);
end;

procedure TACLBindingDiagramLink.DoChanged(AChanges: TACLPersistentChanges);
begin
  FOwner.Changed(AChanges);
end;

function TACLBindingDiagramLink.IsUsed(AObject: TObject): Boolean;
begin
  Result :=
    (Source <> nil) and ((Source = AObject) or (Source.Owner = AObject)) or
    (Target <> nil) and ((Target = AObject) or (Target.Owner = AObject));
end;

procedure TACLBindingDiagramLink.SetArrows(AValue: TACLBindingDiagramLinkArrows);
begin
  if FArrows <> AValue then
  begin
    FArrows := AValue;
    Changed([apcLayout]);
  end;
end;

procedure TACLBindingDiagramLink.SetSource(AValue: TACLBindingDiagramObjectPin);
begin
  if FSource <> AValue then
  begin
    FSource := AValue;
    Changed([apcStruct]);
  end;
end;

procedure TACLBindingDiagramLink.SetTarget(AValue: TACLBindingDiagramObjectPin);
begin
  if FTarget <> AValue then
  begin
    FTarget := AValue;
    Changed([apcStruct]);
  end;
end;

{ TACLBindingDiagramData }

constructor TACLBindingDiagramData.Create(AChangeEvent: TACLPersistentChangeEvent);
begin
  FOnChange := AChangeEvent;
  FLinks := TACLObjectList.Create;
  FLinks.OnChanged := ListChanged;
  FObjects := TACLObjectList.Create;
  FObjects.OnChanged := ListChanged;
end;

destructor TACLBindingDiagramData.Destroy;
begin
  FOnChange := nil;
  FreeAndNil(FObjects);
  FreeAndNil(FLinks);
  inherited;
end;

function TACLBindingDiagramData.AddObject(const ACaption: string): TACLBindingDiagramObject;
begin
  BeginUpdate;
  try
    Result := TACLBindingDiagramObject.Create(Self);
    Result.Caption := ACaption;
    FObjects.Add(Result);
  finally
    EndUpdate;
  end;
end;

function TACLBindingDiagramData.AddLink(const ASource, ATarget: TACLBindingDiagramObjectPin; AArrows: TACLBindingDiagramLinkArrows = []): TACLBindingDiagramLink;
begin
  if not (opmOutput in ASource.Mode) then
    raise EInvalidInsert.Create('Source pin must support for "output" mode');
  if not (opmInput in ATarget.Mode) then
    raise EInvalidInsert.Create('Target pin must support for "input" mode');
  if ContainsLink(ASource, ATarget) then
    raise EInvalidInsert.Create('Link between these pins are already exists');

  BeginUpdate;
  try
    Result := TACLBindingDiagramLink.Create(Self);
    Result.Arrows := AArrows;
    Result.SetSource(ASource);
    Result.SetTarget(ATarget);
    FLinks.Add(Result);
  finally
    EndUpdate;
  end;
end;

procedure TACLBindingDiagramData.Clear;
begin
  BeginUpdate;
  try
    FLinks.Clear;
    FObjects.Clear;
  finally
    EndUpdate;
  end;
end;

procedure TACLBindingDiagramData.ClearLinks;
begin
  BeginUpdate;
  try
    FLinks.Clear;
  finally
    EndUpdate;
  end;
end;

function TACLBindingDiagramData.ContainsLink(const ASource, ATarget: TACLBindingDiagramObjectPin): Boolean;
var
  I: Integer;
begin
  for I := 0 to LinkCount - 1 do
  begin
    if (Links[I].Source = ASource) and (Links[I].Target = ATarget) then
      Exit(True);
  end;
  Result := False;
end;

procedure TACLBindingDiagramData.DoChanged(AChanges: TACLPersistentChanges);
begin
  if Assigned(FOnChange) then
    FOnChange(Self, AChanges);
end;

procedure TACLBindingDiagramData.DoLinkRemoving(Sender: TObject);
begin
  if FLinks <> nil then
    FLinks.Extract(Sender);
end;

procedure TACLBindingDiagramData.DoLinksValidate(Removing: TObject);
var
  I: Integer;
begin
  if FLinks = nil then
    Exit;

  BeginUpdate;
  try
    for I := LinkCount - 1 downto 0 do
    begin
      if Links[I].IsUsed(Removing) then
        Links[I].Free;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TACLBindingDiagramData.DoObjectRemoving(Sender: TObject);
begin
  BeginUpdate;
  try
    DoLinksValidate(Sender);
    if FObjects <> nil then
      FObjects.Extract(Sender);
  finally
    EndUpdate;
  end;
end;

procedure TACLBindingDiagramData.DoPinRemoving(Sender: TObject);
begin
  DoLinksValidate(Sender);
end;

function TACLBindingDiagramData.GetObjectCount: Integer;
begin
  Result := FObjects.Count;
end;

function TACLBindingDiagramData.GetObject(Index: Integer): TACLBindingDiagramObject;
begin
  Result := TACLBindingDiagramObject(FObjects.List[Index]);
end;

function TACLBindingDiagramData.GetLink(Index: Integer): TACLBindingDiagramLink;
begin
  Result := TACLBindingDiagramLink(FLinks.List[Index]);
end;

function TACLBindingDiagramData.GetLinkCount: Integer;
begin
  Result := FLinks.Count;
end;

procedure TACLBindingDiagramData.ListChanged(Sender: TObject);
begin
  Changed;
end;

end.
