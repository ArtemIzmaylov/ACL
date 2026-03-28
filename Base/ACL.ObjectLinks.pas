////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Object Links (aka WeakReferences)
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.ObjectLinks;

{$I ACL.Config.inc}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows, // inlining
{$ENDIF}
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Generics.Defaults,
  {System.}SysUtils,
  {System.}Types,
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
    class var FLinks: TObject;
    class function SafeCreateLink(AObject: TObject): TObject;
  protected
    class var Lock: TACLCriticalSection;
  public
    class constructor Create;
    class destructor Destroy;
    class function GetExtension(AObject: TObject; const IID: TGUID): IUnknown; overload;
    class function GetExtension(AObject: TObject; const IID: TGUID; out Obj): Boolean; overload;
    class procedure Release(AObject: TObject);
    // Register/Unregister
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
    FRemoveListeners: TACLInterfaceList;
    FWeakReferences: TList;
  public
    // Вызываются откуда угодно
    constructor Create(AObject: TObject);
    destructor Destroy; override;
    // Вызываются исключительно из-под TACLObjectLinks.Lock
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
  Lock := TACLCriticalSection.Create(nil, ClassName);
  FLinks := TACLObjectDictionary.Create([doOwnsValues], TACLObjectOrdinalComparer.Create);
  FFreeNotifier := TFreeNotifier.Create(nil);
end;

class destructor TACLObjectLinks.Destroy;
begin
  FreeAndNil(FFreeNotifier);
  FreeAndNil(FLinks);
  FreeAndNil(Lock);
end;

class function TACLObjectLinks.GetExtension(AObject: TObject; const IID: TGUID): IUnknown;
begin
  if not GetExtension(AObject, IID, Result) then
    Result := nil;
end;

class function TACLObjectLinks.GetExtension(AObject: TObject; const IID: TGUID; out Obj): Boolean;
var
  LLink: TACLObjectLink;
begin
  Lock.Enter;
  try
    Result := (AObject <> nil) and TACLObjectDictionary(FLinks).TryGetValue(
      AObject, TObject(LLink)) and LLink.GetExtension(IID, Obj);
  finally
    Lock.Leave;
  end;
end;

class procedure TACLObjectLinks.Release(AObject: TObject);
var
  LValue: TObject;
begin
  if FLinks = nil then Exit;

  Lock.Enter;
  try
    if not TACLObjectDictionary(FLinks).TryExtract(AObject, LValue) then
      LValue := nil;
  finally
    Lock.Leave;
  end;

  // Тут надо быть аккуратным:
  // С одной стороны Link имеет ссылки на другие линки, и их надо чистить синхронно
  // С другой - уведомление Removing может спровоцировать ожидание потока,
  // который в свою очередь ждет разблокировки TACLObjectLinks
  if LValue <> nil then
    LValue.Free;
end;

class procedure TACLObjectLinks.RegisterBridge(AObject1, AObject2: TObject);
var
  LLink1, LLink2: TACLObjectLink;
begin
  if (AObject1 = nil) or (AObject2 = nil) then
    raise Exception.Create('Objects must not be nil');

  Lock.Enter;
  try
    LLink1 := TACLObjectLink(SafeCreateLink(AObject1));
    LLink2 := TACLObjectLink(SafeCreateLink(AObject2));
    LLink1.AddBridge(LLink2);
    LLink2.AddBridge(LLink1);
  finally
    Lock.Leave;
  end;
end;

class procedure TACLObjectLinks.RegisterExtension(AObject: TObject; AExtension: IInterface);
begin
  Lock.Enter;
  try
    TACLObjectLink(SafeCreateLink(AObject)).AddExtension(AExtension);
  finally
    Lock.Leave;
  end;
end;

class procedure TACLObjectLinks.RegisterRemoveListener(
  AObject: TObject; ARemoveListener: IACLObjectRemoveNotify);
begin
  Lock.Enter;
  try
    TACLObjectLink(SafeCreateLink(AObject)).AddRemoveListener(ARemoveListener);
  finally
    Lock.Leave;
  end;
end;

class procedure TACLObjectLinks.RegisterWeakReference(AObject: TObject; AWeakReference: PObject);
begin
  Lock.Enter;
  try
    TACLObjectLink(SafeCreateLink(AObject)).AddWeakReference(AWeakReference);
    AWeakReference^ := AObject;
  finally
    Lock.Leave;
  end;
end;

class function TACLObjectLinks.SafeCreateLink(AObject: TObject): TObject;
begin
  if not TACLObjectDictionary(FLinks).TryGetValue(AObject, Result) then
  begin
    if not Supports(AObject, IACLObjectLinksSupport) then
    begin
      if AObject is TComponent then
        FFreeNotifier.FreeNotification(TComponent(AObject))
      else
        raise Exception.Create('Object must implement the IACLObjectLinksSupport interface');
    end;
    Result := TACLObjectLink.Create(AObject);
    TACLObjectDictionary(FLinks).Add(AObject, Result);
  end;
end;

class procedure TACLObjectLinks.UnregisterBridge(AObject1, AObject2: TObject);
var
  LLink1, LLink2: TACLObjectLink;
begin
  if (AObject1 = nil) or (AObject2 = nil) then Exit;

  Lock.Enter;
  try
    if TACLObjectDictionary(FLinks).TryGetValue(AObject1, TObject(LLink1)) and
       TACLObjectDictionary(FLinks).TryGetValue(AObject2, TObject(LLink2)) then
    begin
      LLink1.RemoveBridge(LLink2);
      LLink2.RemoveBridge(LLink1);
    end;
  finally
    Lock.Leave;
  end;
end;

class procedure TACLObjectLinks.UnregisterExtension(AObject: TObject; AExtension: IInterface);
var
  AValue: TObject;
begin
  if AObject = nil then Exit;
  Lock.Enter;
  try
    if TACLObjectDictionary(FLinks).TryGetValue(AObject, AValue) then
      TACLObjectLink(AValue).RemoveExtension(AExtension);
  finally
    Lock.Leave;
  end;
end;

class procedure TACLObjectLinks.UnregisterRemoveListener(
  ARemoveListener: IACLObjectRemoveNotify; AObject: TObject = nil);
var
  ALink: TObject;
begin
  Lock.Enter;
  try
    if AObject = nil then
    begin
      for ALink in TACLObjectDictionary(FLinks).GetValues do
        TACLObjectLink(ALink).RemoveRemoveListener(ARemoveListener);
    end
    else
      if TACLObjectDictionary(FLinks).TryGetValue(AObject, ALink) then
        TACLObjectLink(ALink).RemoveRemoveListener(ARemoveListener);
  finally
    Lock.Leave;
  end;
end;

class procedure TACLObjectLinks.UnregisterWeakReference(AWeakReference: PObject);
var
  AValue: TObject;
begin
  if AWeakReference^ <> nil then
  try
    Lock.Enter;
    try
      if TACLObjectDictionary(FLinks).TryGetValue(AWeakReference^, AValue) then
        TACLObjectLink(AValue).RemoveWeakReference(AWeakReference);
    finally
      Lock.Leave;
    end;
  finally
    AWeakReference^ := nil;
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
  LIntf: IACLObjectRemoveNotify;
  I: Integer;
begin
  if FWeakReferences <> nil then
  try
    for I := 0 to FWeakReferences.Count - 1 do
      PObject(FWeakReferences.List[I])^ := nil;
  finally
    FreeAndNil(FWeakReferences);
  end;

  // Тут надо быть аккуратным:
  // С одной стороны Link имеет ссылки на другие линки, и их надо чистить синхронно
  // С другой - уведомление Removing может спровоцировать ожидание потока,
  // который в свою очередь ждет разблокировки TACLObjectLinks
  if FBridges <> nil then
  try
    TACLObjectLinks.Lock.Enter;
    try
      for I := FBridges.Count - 1 downto 0 do
        TACLObjectLink(FBridges.List[I]).RemoveBridge(Self);
    finally
      TACLObjectLinks.Lock.Leave;
    end;
  finally
    FreeAndNil(FBridges);
  end;

  if FRemoveListeners <> nil then
  try
    for I := FRemoveListeners.Count - 1 downto 0 do
    begin
      LIntf := IACLObjectRemoveNotify(FRemoveListeners.List[I]);
      LIntf.Removing(FObject);
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
    FRemoveListeners := TACLInterfaceList.Create;
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
      if FExtensions.List[I].QueryInterface(IID, Obj) = 0 then
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
  {$IFDEF DELPHI}
    FBridges.RemoveItem(ALink, TDirection.FromEnd);
  {$ELSE}
    FBridges.Remove(ALink);
  {$ENDIF}
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

