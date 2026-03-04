{%MainUnit ACL.UI.DropTarget.pas}

uses
  glib2,
  Gdk2,
  Gtk2,
  Gtk2Def,
  Gtk2Int,
  Gtk2Proc;

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

  function doGtkGetAction(context: PGdkDragContext): TACLDropAction;
  begin
    case context^.action of
      GDK_ACTION_LINK:
        Result := daLink;
      GDK_ACTION_MOVE:
        Result := daMove;
    else
      Result := daCopy;
    end;
  end;

  function doGtkDragOver(w: PGtkWidget; context: PGdkDragContext;
    x, y, time: guint; impl: TACLDropTargetHookImpl): gboolean; cdecl;
  const
    Map: array[TACLDropAction] of TGdkDragAction = (
      GDK_ACTION_COPY, GDK_ACTION_MOVE, GDK_ACTION_LINK
    );
  var
    LAllow: Boolean;
    LAction: TACLDropAction;
    LCursor: TPoint;
  begin
    try
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
          gdk_drag_status(context, 0, time);
      finally
        Dec(impl.FRecursion);
      end;
    except
      Application.HandleException(nil);
    end;
    Result := gTrue;
  end;

  procedure doGtkDragLeave(w: PGtkWidget; context: PGdkDragContext;
    time: guint; impl: TACLDropTargetHookImpl); cdecl;
  begin
    try
      impl.ActiveTarget := nil;
      impl.UpdateContext(nil, nil, nil);
      impl.HideHint;
    except
      Application.HandleException(nil);
    end;
  end;

  procedure doGtkDragDrop(w: PGtkWidget; context: PGdkDragContext; x, y:gint;
    data: PGtkSelectionData; info, time: guint; impl: TACLDropTargetHookImpl); cdecl;
  var
    LAllow: Boolean;
    LAction: TACLDropAction;
    LCursor: TPoint;
    LState: TShiftState;
  begin
    try
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
    except
      Application.HandleException(nil);
    end;
  end;

  function TACLDropTargetHookImpl.GetData(AFormat: TClipboardFormat; out AMedium: TStgMedium): Boolean;
  begin
    Result := (FData <> nil) and (FData^.target = AFormat) and (FData^.length >= 0);
    if Result then
    begin
      AMedium.Data := FData^.data;
      AMedium.Size := FData.length;
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
    Result := (FData <> nil) and (FData^.target = AFormat);
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
    LWidget := PGtkWidget(AHandle);
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

        gtk_drag_dest_set(LWidget, GTK_DEST_DEFAULT_ALL,
          @LFormats[0], Length(LFormats), GDK_ACTION_COPY or GDK_ACTION_MOVE);
        gtk_drag_dest_add_text_targets(LWidget);

        ConnectSignal(PGtkObject(LWidget), 'drag_data_received', @doGtkDragDrop, Self);
        ConnectSignal(PGtkObject(LWidget), 'drag_motion', @doGtkDragOver, Self);
        ConnectSignal(PGtkObject(LWidget), 'drag_leave', @doGtkDragLeave, Self);
      finally
        LMimeTypes.Free;
      end;
    end
    else
      gtk_drag_dest_unset(LWidget);
  end;

