{%MainUnit ACL.UI.DropTarget.pas}

uses
  Glib2,
  Gtk3Objects,
  Gtk3Widgets,
  LazGObject2,
  LazGdk3,
  LazGtk3;

type

  { TACLDropTargetHookImpl }

  // https://www.manpagez.com/html/gdk2/gdk2-2.24.29/gdk2-Drag-and-Drop.php
  // https://www.manpagez.com/html/gtk2/gtk2-2.24.28/gtk2-Drag-and-Drop.php#gtk-drag-get-data
  // https://gitlab.gnome.org/GNOME/gtk/-/issues/5518
  TACLDropTargetHookImpl = class(TACLDropTargetHook)
  strict private
    FContext: PGdkDragContext;
    FData: PGtkSelectionData;
    FWidget: PGtkWidget;
  protected
    FRecursion: Integer;

    function GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean; override;
    function HasData(AFormat: TClipboardFormat): Boolean; override;
    procedure UpdateContext(AWidget: PGtkWidget; AContext: PGdkDragContext; AData: PGtkSelectionData);
    procedure UpdateMimeTypes; override;
    procedure UpdateRegistration(AHandle: TWndHandle; ARegister: Boolean); override;
  end;

  function GetWidgetClientOrigin(w: PGtkWidget): TPoint;
  var
    x, y: gint;
  begin
    gdk_window_get_origin(gtk_widget_get_window(w), @x, @y);
    Result := Point(X, Y);
  end;

  function doGtkGetAction(context: PGdkDragContext): TACLDropAction;
  begin
    Result := daCopy;
    if GDK_ACTION_LINK in context^.get_actions then
      Result := daLink;
    if GDK_ACTION_MOVE in context^.get_actions then
      Result := daMove;
  end;

  procedure doGtkDragOver(w: PGtkWidget; context: PGdkDragContext;
    x, y, time: guint; impl: TACLDropTargetHookImpl); cdecl;
  const
    Map: array[TACLDropAction] of TGdkDragAction = (
      [GDK_ACTION_COPY], [GDK_ACTION_MOVE], [GDK_ACTION_LINK]
    );
  var
    LAllow: Boolean;
    LAction: TACLDropAction;
    LCursor: TPoint;
  begin
    Inc(impl.FRecursion);
    try
      LAllow := True;
      LAction := doGtkGetAction(context);
      LCursor := GetWidgetClientOrigin(w);
      LCursor.Offset(x, y);
      impl.UpdateContext(w, context, nil);
      impl.DoDragOver(LCursor, KeyboardStateToShiftState, LAllow, LAction);
      if LAllow then
        gdk_drag_status(context, Map[LAction], time)
      else
        gdk_drag_status(context, [], time);
    finally
      Dec(impl.FRecursion);
    end;
  end;

  procedure doGtkDragLeave(w: PGtkWidget; context: PGdkDragContext;
    time: guint; impl: TACLDropTargetHookImpl); cdecl;
  begin
    impl.ActiveTarget := nil;
    impl.UpdateContext(nil, nil, nil);
    impl.HideHint;
  end;

  procedure doGtkDragDrop(w: PGtkWidget; context: PGdkDragContext; x, y:gint;
    data: PGtkSelectionData; info, time: guint; impl: TACLDropTargetHookImpl); cdecl;
  var
    LAllow: Boolean;
    LAction: TACLDropAction;
    LCursor: TPoint;
    LState: TShiftState;
  begin
    impl.UpdateContext(w, context, data);
    // The "data-received" может придти во время обработки "drag-motion"
    if impl.FRecursion = 0 then
    try
      LAllow := True;
      LAction := doGtkGetAction(context);
      LCursor := GetWidgetClientOrigin(w);
      LCursor.Offset(x, y);
      LState := KeyboardStateToShiftState;
      impl.DoDragOver(LCursor, LState, LAllow, LAction);
      impl.HideHint; // before drop, but after over
      if (impl.ActiveTarget <> nil) and LAllow then
        impl.ActiveTarget.DoDrop(LState, LCursor, LAction);
    finally
      doGtkDragLeave(w, context, time, impl);
      gtk_drag_finish(context, LAllow, LAction = daMove, time);
    end;
  end;

  function TACLDropTargetHookImpl.GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean;
  begin
    Result := (FData <> nil) and
      (TClipboardFormat(FData.get_target) = AFormat) and
      (FData^.get_length >= 0);
    if Result then
    begin
      AMedium.Data := FData^.get_data;
      AMedium.Size := FData^.get_length;
      AMedium.Owned := False;
    end;
  end;

  function TACLDropTargetHookImpl.HasData(AFormat: TClipboardFormat): Boolean;
  begin
    // Запрос во время drag-motion не работает...
    //if (FData = nil) and (FWidget <> nil) and (FContext <> nil) then
    //  gtk_drag_get_data(FWidget, FContext, AFormat, GDK_CURRENT_TIME);
    if FRecursion > 0{drag-motion?} then
      Exit(True); // на дропе разберемся...
    Result := (FData <> nil) and (TClipboardFormat(FData.get_target) = AFormat);
  end;

  procedure TACLDropTargetHookImpl.UpdateContext(
    AWidget: PGtkWidget; AContext: PGdkDragContext; AData: PGtkSelectionData);
  begin
    FData := AData;
    FContext := AContext;
    FWidget := AWidget;
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
    LWidget := PGtkWidget(TGtk3WIdget(AHandle).Widget);
    if ARegister then
    begin
      LMimeTypes := TACLStringList.Create;
      try
        LMimeTypes.Add(acMimeConfig);
        LMimeTypes.Add(acMimeInternalFileList);
        LMimeTypes.Add(acMimeLinuxFileList);
        for I := 0 to FTargets.Count - 1 do
          LMimeTypes.Append(FTargets.List[I].GetMimeTypes);
        LMimeTypes.RemoveDuplicates;

        SetLength(LFormats{%H-}, LMimeTypes.Count);
        for I := 0 to LMimeTypes.Count - 1 do
        begin
          LFormats[I].target := PChar(LMimeTypes.Strings[I]);
          LFormats[I].flags := 0;
          LFormats[I].info := 0;
        end;

        gtk_drag_dest_set(LWidget, GTK_DEST_DEFAULT_ALL,
          @LFormats[0], Length(LFormats), [GDK_ACTION_COPY, GDK_ACTION_MOVE]);
        gtk_drag_dest_add_text_targets(LWidget);

        g_signal_connect_data(LWidget, 'drag_data_received', @doGtkDragDrop, Self, nil, G_CONNECT_DEFAULT);
        g_signal_connect_data(LWidget, 'drag_motion', @doGtkDragOver, Self, nil, G_CONNECT_DEFAULT);
        g_signal_connect_data(LWidget, 'drag_leave', @doGtkDragLeave, Self, nil, G_CONNECT_DEFAULT);
      finally
        LMimeTypes.Free;
      end;
    end
    else
      gtk_drag_dest_unset(LWidget);
  end;

