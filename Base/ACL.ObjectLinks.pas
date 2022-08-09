{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*               Object Links                *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.ObjectLinks;

{$I ACL.Config.inc}

interface

uses
  Winapi.Windows,
  // System
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Types,
  // ACL
  ACL.Threading;

type

  { IACLObjectLinksSupport }

  // All Objects that implements the interface
  // MUST call the TACLObjectLinks.Release before destroy
  IACLObjectLinksSupport = interface
  ['{D42C92DE-D79D-42F0-9D1D-0301F0DD0F16}']
  end;

  { IACLObjectRemoveNotify }

  IACLObjectRemoveNotify = interface
  ['{05A1E546-86A9-4CDB-9D3F-9608A7B58034}']
    procedure Removing(AObject: TObject);
  end;

  { TACLObjectLinks }

  TACLObjectLinks = class sealed
  strict private
    class var FFreeNotifier: TComponent;
    class var FLinks: TDictionary<TObject, TObject>;
    class var FLock: TACLCriticalSection;

    class function SafeCreateLink(AObject: TObject): TObject;
  public
    class constructor Create;
    class destructor Destroy;
    class function GetExtension(AObject: TObject; const IID: TGUID; out Obj): Boolean;
    class procedure Release(AObject: TObject);
    //
    class procedure RegisterBridge(AObject1, AObject2: TObject); overload;
    class procedure RegisterExtension(AObject: TObject; AExtension: IUnknown); overload;
    class procedure RegisterRemoveListener(AObject: TObject; ARemoveListener: IACLObjectRemoveNotify); overload;
    class procedure RegisterWeakReference(AObject: TObject; AWeakReference: PObject); overload;
    class procedure UnregisterBridge(AObject1, AObject2: TObject);
    class procedure UnregisterExtension(AObject: TObject; AExtension: IUnknown); overload;
    class procedure UnregisterRemoveListener(ARemoveListener: IACLObjectRemoveNotify; AObject: TObject = nil); overload;
    class procedure UnregisterWeakReference(AWeakReference: PObject); overload;
  end;

implementation

uses
  ACL.Classes.Collections;

type

  { TFreeNotifier }

  TFreeNotifier = class(TComponent)
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  end;

  { TACLObjectLink }

  TACLObjectLink = class
  strict private
    FObject: TObject;

    FBridges: TList;
    FExtensions: TACLInterfaceList;
    FRemoveListeners: TACLList<IACLObjectRemoveNotify>;
    FWeakReferences: TList;
  public
    constructor Create(AObject: TObject);
    destructor Destroy; override;
    procedure AddBridge(const ALink: TACLObjectLink); inline;
    procedure AddExtension(const AIntf: IUnknown); inline;
    procedure AddRemoveListener(const ARemoveListener: IACLObjectRemoveNotify); inline;
    procedure AddWeakReference(AField: PObject); inline;
    function GetExtension(const IID: TGUID; out Obj): Boolean; inline;
    procedure RemoveBridge(const ALink: TACLObjectLink); inline;
    procedure RemoveExtension(const AIntf: IUnknown); inline;
    procedure RemoveRemoveListener(const ARemoveListener: IACLObjectRemoveNotify); inline;
    procedure RemoveWeakReference(AField: PObject); inline;
  end;

{ TACLObjectLinks }

class constructor TACLObjectLinks.Create;
begin
  FLock := TACLCriticalSection.Create(nil, ClassName);
  FLinks := TObjectDictionary<TObject, TObject>.Create([doOwnsValues]);
  FFreeNotifier := TFreeNotifier.Create(nil);
end;

class destructor TACLObjectLinks.Destroy;
begin
  FreeAndNil(FFreeNotifier);
  FreeAndNil(FLinks);
  FreeAndNil(FLock);
end;

class function TACLObjectLinks.GetExtension(AObject: TObject; const IID: TGUID; out Obj): Boolean;
var
  ALink: TACLObjectLink;
begin
  FLock.Enter;
  try
    Result := FLinks.TryGetValue(AObject, TObject(ALink)) and ALink.GetExtension(IID, Obj);
  finally
    FLock.Leave;
  end;
end;

class procedure TACLObjectLinks.Release(AObject: TObject);
var
  APair: TPair<TObject, TObject>;
begin
  FLock.Enter;
  try
    APair := FLinks.ExtractPair(AObject);
  finally
    FLock.Leave;
  end;
  if APair.Value <> nil then
    APair.Value.Free;
end;

class procedure TACLObjectLinks.RegisterBridge(AObject1, AObject2: TObject);
var
  ALink1, ALink2: TACLObjectLink;
begin
  FLock.Enter;
  try
    ALink1 := TACLObjectLink(SafeCreateLink(AObject1));
    ALink2 := TACLObjectLink(SafeCreateLink(AObject2));
    ALink1.AddBridge(ALink2);
    ALink2.AddBridge(ALink1);
  finally
    FLock.Leave;
  end;
end;

class procedure TACLObjectLinks.RegisterExtension(AObject: TObject; AExtension: IInterface);
begin
  FLock.Enter;
  try
    TACLObjectLink(SafeCreateLink(AObject)).AddExtension(AExtension);
  finally
    FLock.Leave;
  end;
end;

class procedure TACLObjectLinks.RegisterRemoveListener(AObject: TObject; ARemoveListener: IACLObjectRemoveNotify);
begin
  FLock.Enter;
  try
    TACLObjectLink(SafeCreateLink(AObject)).AddRemoveListener(ARemoveListener);
  finally
    FLock.Leave;
  end;
end;

class procedure TACLObjectLinks.RegisterWeakReference(AObject: TObject; AWeakReference: PObject);
begin
  FLock.Enter;
  try
    TACLObjectLink(SafeCreateLink(AObject)).AddWeakReference(AWeakReference);
    AWeakReference^ := AObject;
  finally
    FLock.Leave;
  end;
end;

class procedure TACLObjectLinks.UnregisterBridge(AObject1, AObject2: TObject);
var
  ALink1, ALink2: TACLObjectLink;
begin
  FLock.Enter;
  try
    if FLinks.TryGetValue(AObject1, TObject(ALink1)) and FLinks.TryGetValue(AObject2, TObject(ALink2)) then
    begin
      ALink1.RemoveBridge(ALink2);
      ALink2.RemoveBridge(ALink1);
    end;
  finally
    FLock.Leave;
  end;
end;

class procedure TACLObjectLinks.UnregisterExtension(AObject: TObject; AExtension: IInterface);
var
  AValue: TObject;
begin
  FLock.Enter;
  try
    if FLinks.TryGetValue(AObject, AValue) then
      TACLObjectLink(AValue).RemoveExtension(AExtension);
  finally
    FLock.Leave;
  end;
end;

class procedure TACLObjectLinks.UnregisterRemoveListener(ARemoveListener: IACLObjectRemoveNotify; AObject: TObject = nil);
var
  ALink: TObject;
begin
  FLock.Enter;
  try
    if AObject = nil then
    begin
      for ALink in FLinks.Values do
        TACLObjectLink(ALink).RemoveRemoveListener(ARemoveListener);
    end
    else
      if FLinks.TryGetValue(AObject, ALink) then
        TACLObjectLink(ALink).RemoveRemoveListener(ARemoveListener);
  finally
    FLock.Leave;
  end;
end;

class procedure TACLObjectLinks.UnregisterWeakReference(AWeakReference: PObject);
var
  AValue: TObject;
begin
  if AWeakReference^ <> nil then
  try
    FLock.Enter;
    try
      if FLinks.TryGetValue(AWeakReference^, AValue) then
        TACLObjectLink(AValue).RemoveWeakReference(AWeakReference);
    finally
      FLock.Leave;
    end;
  finally
    AWeakReference^ := nil;
  end;
end;

class function TACLObjectLinks.SafeCreateLink(AObject: TObject): TObject;
begin
  if not FLinks.TryGetValue(AObject, Result) then
  begin
    if not Supports(AObject, IACLObjectLinksSupport) then
    begin
      if AObject is TComponent then
        FFreeNotifier.FreeNotification(TComponent(AObject))
      else
        raise Exception.Create('Object must implement the IACLObjectLinksSupport interface');
    end;
    Result := TACLObjectLink.Create(AObject);
    FLinks.Add(AObject, Result);
  end;
end;

{ TFreeNotifier }

procedure TFreeNotifier.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
    TACLObjectLinks.Release(AComponent);
end;

{ TACLObjectLink }

constructor TACLObjectLink.Create(AObject: TObject);
begin
  FObject := AObject;
end;

destructor TACLObjectLink.Destroy;
var
  I: Integer;
begin

  if FWeakReferences <> nil then
  try
    for I := 0 to FWeakReferences.Count - 1 do
      PObject(FWeakReferences.List[I])^ := nil;
  finally
    FreeAndNil(FWeakReferences);
  end;

  if FBridges <> nil then
  try
    for I := FBridges.Count - 1 downto 0 do
      TACLObjectLink(FBridges.List[I]).RemoveBridge(Self);
  finally
    FreeAndNil(FBridges);
  end;

  if FRemoveListeners <> nil then
  try
    for I := FRemoveListeners.Count - 1 downto 0 do
    begin
      FRemoveListeners.List[I].Removing(FObject);
      FRemoveListeners.List[I] := nil;
    end;
  finally
    FreeAndNil(FRemoveListeners);
  end;

  // Must be called after weak references
  FreeAndNil(FExtensions);
  inherited Destroy;
end;

procedure TACLObjectLink.AddBridge(const ALink: TACLObjectLink);
begin
  if FBridges = nil then
    FBridges := TList.Create;
  FBridges.Add(ALink);
end;

procedure TACLObjectLink.AddExtension(const AIntf: IInterface);
begin
  if FExtensions = nil then
    FExtensions := TACLInterfaceList.Create;
  FExtensions.Add(AIntf);
end;

procedure TACLObjectLink.AddRemoveListener(const ARemoveListener: IACLObjectRemoveNotify);
begin
  if FRemoveListeners = nil then
    FRemoveListeners := TACLList<IACLObjectRemoveNotify>.Create;
  FRemoveListeners.Add(ARemoveListener);
end;

procedure TACLObjectLink.AddWeakReference(AField: PObject);
begin
  if FWeakReferences = nil then
    FWeakReferences := TList.Create;
  FWeakReferences.Add(AField);
end;

function TACLObjectLink.GetExtension(const IID: TGUID; out Obj): Boolean;
var
  I: Integer;
begin
  if FExtensions <> nil then
    for I := FExtensions.Count - 1 downto 0 do
    begin
      if Succeeded(FExtensions.List[I].QueryInterface(IID, Obj)) then
        Exit(True);
    end;

  if FBridges <> nil then
    for I := FBridges.Count - 1 downto 0 do
    begin
      if Supports(TACLObjectLink(FBridges.List[I]).FObject, IID, Obj) then
        Exit(True);
    end;

  Result := False;
end;

procedure TACLObjectLink.RemoveBridge(const ALink: TACLObjectLink);
begin
  if FBridges <> nil then
    FBridges.RemoveItem(ALink, TDirection.FromEnd);
end;

procedure TACLObjectLink.RemoveExtension(const AIntf: IInterface);
begin
  if FExtensions <> nil then
    FExtensions.Remove(AIntf);
end;

procedure TACLObjectLink.RemoveRemoveListener(const ARemoveListener: IACLObjectRemoveNotify);
begin
  if FRemoveListeners <> nil then
    FRemoveListeners.Remove(ARemoveListener);
end;

procedure TACLObjectLink.RemoveWeakReference(AField: PObject);
begin
  if FWeakReferences <> nil then
    FWeakReferences.Remove(AField);
end;

end.
