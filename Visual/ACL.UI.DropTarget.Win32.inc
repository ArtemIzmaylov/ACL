type

  { TACLDropTargetHookImpl }

  TACLDropTargetHookImpl = class(TACLDropTargetHook, IDropTarget)
  strict private
    FDataObject: IDataObject;
    function GetActionFromEffect(AEffect: Integer): TACLDropAction;
  protected
    // IDropTarget
    function DragEnter(const ADataObj: IDataObject; AKeyState: LongInt;
      P: TPoint; var AEffect: LongInt): HRESULT; stdcall;
    function DragLeave: HRESULT; stdcall;
    function DragOver(AKeyState: LongInt; P: TPoint; var AEffect: LongInt): HRESULT; stdcall;
    function Drop(const ADataObj: IDataObject; AKeyState: LongInt;
      P: TPoint; var AEffect: LongInt): HRESULT; stdcall;
    // IACLDropTargetHook
    function GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean; override;
    function HasData(AFormat: TClipboardFormat): Boolean; override;
    // General
    procedure UpdateRegistration(AHandle: TWndHandle; ARegister: Boolean); override;
    // Properties
    property DataObject: IDataObject read FDataObject;
  end;

  { TACLDropTargetHookImpl }

  function TACLDropTargetHookImpl.DragEnter(const ADataObj: IDataObject;
    AKeyState: Integer; P: TPoint; var AEffect: Integer): HRESULT;
  begin
    FDataObject := ADataObj;
    Result := S_OK;
  end;

  function TACLDropTargetHookImpl.DragLeave: HRESULT;
  begin
    try
      HideHint;
      ActiveTarget := nil;
      FDataObject := nil;
    except
      Application.HandleException(nil);
    end;
    Result := S_OK;
  end;

  function TACLDropTargetHookImpl.DragOver(AKeyState: Integer; P: TPoint; var AEffect: Integer): HRESULT;
  const
    Map: array[TACLDropAction] of Integer = (DROPEFFECT_COPY, DROPEFFECT_MOVE, DROPEFFECT_LINK);
  var
    LAction: TACLDropAction;
    LAllow: Boolean;
  begin
    Result := S_OK;
    try
      LAllow := AEffect <> DROPEFFECT_NONE;
      LAction := GetActionFromEffect(AEffect);
      DoDragOver(P, KeysToShiftState(AKeyState), LAllow, LAction);
      AEffect := IfThen(LAllow, Map[LAction], DROPEFFECT_NONE);
    except
      Application.HandleException(nil);
    end;
  end;

  function TACLDropTargetHookImpl.Drop(const ADataObj: IDataObject;
    AKeyState: Integer; P: TPoint; var AEffect: Integer): HRESULT;
  begin
    Result := S_OK;
    try
      try
        if (DataObject <> nil) and (AEffect <> DROPEFFECT_NONE) then
        begin
          HideHint;
          if ActiveTarget <> nil then
            ActiveTarget.DoDrop(KeysToShiftState(AKeyState), P, GetActionFromEffect(AEffect));
        end;
      finally
        DragLeave;
      end;
    except
      Application.HandleException(nil);
    end;
  end;

  function TACLDropTargetHookImpl.GetActionFromEffect(AEffect: Integer): TACLDropAction;
  begin
    case LoWord(AEffect) of
      DROPEFFECT_MOVE:
        Result := daMove;
      DROPEFFECT_LINK:
        Result := daLink;
    else
      Result := daCopy;
    end;
  end;

  function TACLDropTargetHookImpl.GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean;
  begin
    ZeroMemory(@AMedium, SizeOf(AMedium));
    Result := (DataObject <> nil) and
      Succeeded(DataObject.GetData(MakeFormat(AFormat), AMedium)) and
      (AMedium.tymed <> TYMED_NULL);
  end;

  function TACLDropTargetHookImpl.HasData(AFormat: TClipboardFormat): Boolean;
  begin
    Result := Succeeded(DataObject.QueryGetData(MakeFormat(AFormat)));
  end;

  procedure TACLDropTargetHookImpl.UpdateRegistration(AHandle: TWndHandle; ARegister: Boolean);
  begin
    if ARegister then
      RegisterDragDrop(AHandle, Self)
    else
      RevokeDragDrop(AHandle);
  end;
