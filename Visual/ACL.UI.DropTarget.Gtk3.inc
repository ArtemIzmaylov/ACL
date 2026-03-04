{%MainUnit ACL.UI.DropTarget.pas}

{$DEFINE DEBUG_DROP_TARGET}

uses
  Gtk3Objects,
  Gtk3Widgets,
  LazGLib2,
  LazGObject2,
  LazGdk3,
  LazGtk3;

type

  { TDropActionState }

  TDropActionState = record
    Action: TACLDropAction;
    Allow: Boolean;
    Cursor: TPoint;
    Shift: TShiftState;
    procedure Init(w: PGtkWidget; context: PGdkDragContext; x, y: guint);
  end;

  { TACLDropTargetHookImpl }

  // https://docs.gtk.org/gtk3/signal.Widget.drag-data-received.html
  // https://docs.gtk.org/gtk3/signal.Widget.drag-motion.html
  // https://gitlab.gnome.org/GNOME/gtk/-/issues/5518
  TACLDropTargetHookImpl = class(TACLDropTargetHook)
  public type
    TDataMap = TACLDictionary<TClipboardFormat, TMemoryStream>;
  protected
    FFinishRequested: Boolean;
    FSupportedFormats: PGtkTargetList;
    function GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean; override;
    function HasData(AFormat: TClipboardFormat): Boolean; override;
    procedure RequestData(ASource: PGtkWidget; ATime: gint);
    procedure UpdateMimeTypes; override;
    procedure UpdateRegistration(AHandle: TWndHandle; ARegister: Boolean); override;
  protected public
    class var Data: TDataMap;
    class var DataContext: PGdkDragContext;
    class var DataRequested: Integer;
    class var DataSource: PGtkWidget;
    class procedure SetContext(AContext: PGdkDragContext; ATime: gint);
  public
    class destructor Destroy;
  end;

  function doDropOver(w: PGtkWidget; context: PGdkDragContext;
    x, y, time: guint; impl: TACLDropTargetHookImpl): gboolean; cdecl;
  const
    Map: array[TACLDropAction] of TGdkDragAction = (
      [GDK_ACTION_COPY], [GDK_ACTION_MOVE], [GDK_ACTION_LINK]
    );
  var
    LState: TDropActionState;
  begin
    Result := True;
    try
    {$IFDEF DEBUG_DROP_TARGET}
      WriteLn('Gtk3.OnDropOver');
    {$ENDIF}
      LState.Init(w, context, x, y);
      impl.FFinishRequested := False;
      impl.SetContext(context, time);
      impl.DoDragOver(LState.Cursor, LState.Shift, LState.Allow, LState.Action);
      if LState.Allow then
        gdk_drag_status(context, Map[LState.Action], time)
      else
        gdk_drag_status(context, [], time);
    except
      Application.HandleException(nil);
    end;
  end;

  procedure doDropLeave(w: PGtkWidget; context: PGdkDragContext;
    time: guint; impl: TACLDropTargetHookImpl); cdecl;
  begin
    try
      // The signal is also emitted before the ::drag-drop signal, for instance to
      // allow cleaning up of a preview item created in the drag-motion signal handler
      // https://docs.gtk.org/gtk3/signal.Widget.drag-leave.html
    {$IFDEF DEBUG_DROP_TARGET}
      WriteLn('Gtk3.OnDropLeave');
    {$ENDIF}
      impl.HideHint;
      impl.ActiveTarget := nil;
    except
      Application.HandleException(nil);
    end;
  end;

  procedure doDropEnd(w: PGtkWidget; context: PGdkDragContext;
    x, y, time: guint; impl: TACLDropTargetHookImpl); cdecl;
  var
    LState: TDropActionState;
  begin
    try
      if impl.DataRequested < 0 then
      begin
      {$IFDEF DEBUG_DROP_TARGET}
        WriteLn('Gtk3.OnDrop');
      {$ENDIF}
        impl.FFinishRequested := True;
        impl.SetContext(context, time);
        impl.RequestData(w, time);
      end;
      if impl.DataRequested = 0 then
      begin
      {$IFDEF DEBUG_DROP_TARGET}
        WriteLn('Gtk3.OnDropEnd');
      {$ENDIF}
        LState.Init(w, context, x, y);
        try
          impl.DoDragOver(LState.Cursor, LState.Shift, LState.Allow, LState.Action);
          impl.HideHint; // before drop, but after over
          if (impl.ActiveTarget <> nil) and LState.Allow then
            impl.ActiveTarget.DoDrop(LState.Shift, LState.Cursor, LState.Action);
          impl.ActiveTarget := nil;
          impl.SetContext(nil, time);
        finally
          gtk_drag_finish(context, LState.Allow, LState.Action = daMove, time);
        end;
      end;
    except
      Application.HandleException(nil);
    end;
  end;

  procedure doDropData(w: PGtkWidget; context: PGdkDragContext; x, y:gint;
    data: PGtkSelectionData; info, time: guint; impl: TACLDropTargetHookImpl); cdecl;
  var
    LData: TMemoryStream;
    LDataLen: gint;
    LDataPtr: Pointer;
    LType: PGdkAtom;
  begin
    if impl.Data = nil then
    begin
    {$IFDEF DEBUG_DROP_TARGET}
      if impl.FFinishRequested then
        WriteLn('Gtk3.OnDropData(Unexpected Failure)');
    {$ENDIF}
      Exit;
    end;

    try
      LType := data^.get_data_type;
    {$IFDEF DEBUG_DROP_TARGET}
      WriteLn('Gtk3.OnDropData(', impl.DataRequested, ', ', TClipboardFormat(LType), ', ', LType^.name, ')');
    {$ENDIF}
      if impl.Data.ContainsKey(TClipboardFormat(LType)) then
      begin
        LDataPtr := data^.get_data;
        LDataLen := data^.get_length;
        if (LDataPtr <> nil) and (LDataLen >= 0) then // < 0 if request failed
        begin
          LData := TMemoryStream.Create;
          LData.WriteBuffer(LDataPtr^, LDataLen);
          impl.Data.AddOrSetValue(TClipboardFormat(LType), LData);
        end;
        Dec(impl.DataRequested);
      end;

      if impl.FFinishRequested and (impl.DataRequested <= 0) then
      begin
        impl.FFinishRequested := False;
        doDropEnd(w, context, x, y, time, impl);
      end;
    except
      Application.HandleException(nil);
    end;
  end;

  { TDropActionState }

  procedure TDropActionState.Init(w: PGtkWidget; context: PGdkDragContext; x, y: guint);
  var
    keymap: PGdkKeymap;
    state: TGdkModifierType;
    tx, ty: gint;
  begin
    Allow := True;
    w^.get_window^.get_origin(@tx, @ty);
    Cursor := Point(tx + x, ty + y);

    Action := daCopy;
    if GDK_ACTION_LINK in context^.get_actions then
      Action := daLink;
    if GDK_ACTION_MOVE in context^.get_actions then
      Action := daMove;

    Shift := [];
    keymap := gdk_keymap_get_for_display(TGdkDisplay.get_default);
    if keymap <> nil then
    begin
      state := TGdkModifierType(keymap^.get_modifier_state);
      if GDK_MOD1_MASK    in state then Include(Shift, ssAlt);
      if GDK_SHIFT_MASK   in state then Include(Shift, ssShift);
      if GDK_CONTROL_MASK in state then Include(Shift, ssCtrl);
    end;
  end;

  { TACLDropTargetHookImpl }

  class destructor TACLDropTargetHookImpl.Destroy;
  begin
    SetContext(nil, 0);
  end;

  function TACLDropTargetHookImpl.GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean;
  var
    LData: TMemoryStream;
  begin
    Result := (Data <> nil) and Data.TryGetValue(AFormat, LData) and (LData <> nil);
    if Result then
    begin
      AMedium.Data := LData.Memory;
      AMedium.Size := LData.Size;
      AMedium.Owned := False;
    end;
  end;

  function TACLDropTargetHookImpl.HasData(AFormat: TClipboardFormat): Boolean;
  begin
    Result := (Data <> nil) and Data.ContainsKey(AFormat);
  end;

  procedure TACLDropTargetHookImpl.RequestData(ASource: PGtkWidget; ATime: gint);
  var
    LNode: PGList;
  begin
    if DataRequested < 0 then
    begin
      DataRequested := 0;
      if (DataContext <> nil) and (FSupportedFormats <> nil) then
      begin
        // в случае перемещения внутри приложения, drag_get_data сразу
        // же дёрнет doDropData, асинхронного вызова не будет. Соответственно,
        // мы не должны завершать драг до тех пор, пока не получим все данные.
        Inc(DataRequested);
        try
          LNode := DataContext^.list_targets;
          while LNode <> nil do
          begin
            // Мы сможем получить данные только для тех mime-типов, которые
            // были декларированы через drag_dest_set_XXX
            if FSupportedFormats^.find(LNode^.data, nil) then
            begin
              Inc(DataRequested); // first
              ASource.drag_get_data(DataContext, LNode^.data, ATime);
            end;
            LNode := LNode^.next;
          end;
        finally
          Dec(DataRequested);
        end;
      end;
    end;
  end;

  class procedure TACLDropTargetHookImpl.SetContext(AContext: PGdkDragContext; ATime: gint);
  var
    LAtom: PGdkAtom;
    LNode: PGList;
  begin
    if AContext <> DataContext then
    begin
      FreeAndNil(Data);
      DataContext := AContext;
      DataRequested := -1;
      if DataContext <> nil then
      begin
        Data := TDataMap.Create([doOwnsValues], 16, nil);
        LNode := AContext^.list_targets;
        while LNode <> nil do
        begin
          LAtom := LNode^.data;
          Data.AddIfAbsent(TClipboardFormat(LAtom), nil);
        {$IFDEF DEBUG_DROP_TARGET}
          WriteLn('  (', TClipboardFormat(LAtom), ') ', LAtom^.name);
        {$ENDIF}
          LNode := LNode^.next;
        end;
      end;
    end;
  end;

  procedure TACLDropTargetHookImpl.UpdateMimeTypes;
  begin
    Registered := False;
    Registered := True;
  end;

  procedure TACLDropTargetHookImpl.UpdateRegistration(AHandle: TWndHandle; ARegister: Boolean);
  var
    I: Integer;
    LFormats: array of TGtkTargetEntry;
    LMimeTypes: TACLStringList;
    LWidget: PGtkWidget;
  begin
    LWidget := TGtk3Widget(AHandle).GetContainerWidget;
    if ARegister then
    begin
      LMimeTypes := TACLStringList.Create;
      try
        // keep the order
        for I := 0 to FTargets.Count - 1 do
          LMimeTypes.Append(FTargets.List[I].GetMimeTypes);
        LMimeTypes.Add(acMimeInternalFileList);
        LMimeTypes.Add(acMimeLinuxFileList);
        LMimeTypes.Add(acMimeConfig);
        LMimeTypes.RemoveDuplicates;

        SetLength(LFormats{%H-}, LMimeTypes.Count);
        for I := 0 to LMimeTypes.Count - 1 do
        begin
          LFormats[I].target := PChar(LMimeTypes.Strings[I]);
          LFormats[I].flags := 0;
          LFormats[I].info := 0;
        end;

        LWidget^.drag_dest_set([], @LFormats[0], Length(LFormats), [GDK_ACTION_COPY, GDK_ACTION_MOVE]);
        LWidget^.drag_dest_add_text_targets();
        FSupportedFormats := LWidget^.drag_dest_get_target_list;

        g_signal_connect_data(LWidget, 'drag_drop', @doDropEnd, Self, nil, G_CONNECT_DEFAULT);
        g_signal_connect_data(LWidget, 'drag_data_received', @doDropData, Self, nil, G_CONNECT_DEFAULT);
        g_signal_connect_data(LWidget, 'drag_motion', @doDropOver, Self, nil, G_CONNECT_DEFAULT);
        g_signal_connect_data(LWidget, 'drag_leave', @doDropLeave, Self, nil, G_CONNECT_DEFAULT);
      finally
        LMimeTypes.Free;
      end;
    end
    else
    begin
      FSupportedFormats := nil;
      gtk_drag_dest_unset(LWidget);
    end;
  end;

