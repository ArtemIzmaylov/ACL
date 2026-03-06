{%MainUnit ACL.UI.DropSource.pas}

uses
  Glib2,
  Gtk3Objects,
  Gtk3Widgets,
  LazGObject2,
  LazGdk3,
  LazGtk3,
  LCLType,
  // ACL
  ACL.UI.Core.Impl.Gtk3;

type

  { TACLDropSourceImpl }

  // https://git.eclipse.org/r/plugins/gitiles/platform/eclipse.platform.swt/+/81633b430a87caf2f0c020f10e108754d81a4415/bundles/org.eclipse.swt/Eclipse%20SWT%20Drag%20and%20Drop/gtk/org/eclipse/swt/dnd/DragSource.java
  TACLDropSourceImpl = class(TACLDropSource)
  private
    FContext: PGdkDragContext;
    FDone: Boolean;
  protected
    procedure ExecuteImpl; override;
  public
    procedure Cancel; override;
  end;

  procedure gtk_signal_disconnect_by_func(w: PGtkWidget; proc, data: Pointer);
  begin
    g_signal_handlers_disconnect_matched(w,
      [G_SIGNAL_MATCH_FUNC, G_SIGNAL_MATCH_DATA], 0, 0, nil, proc, data);
  end;

  { TACLDropSourceImpl }

  procedure doGtkDropEnd(w: PGtkWidget; ctx: PGdkDragContext; impl: TACLDropSourceImpl); cdecl;
  var
    LActions: TGdkDragAction;
  begin
    try
      try
        LActions := ctx^.get_actions;
        impl.FDropResult := [];
        if GDK_ACTION_COPY in LActions then
          Include(impl.FDropResult, dsaCopy);
        if GDK_ACTION_MOVE in LActions then
          Include(impl.FDropResult, dsaMove);
        if GDK_ACTION_LINK in LActions then
          Include(impl.FDropResult, dsaLink);
      finally
        impl.FDone := True;
      end;
    except
      Application.HandleException(nil);
    end;
  end;

  procedure doGtkDropGetData(w: PGtkWidget; ctx: PGdkDragContext;
    data: PGtkSelectionData; info, time: guint; src: TACLDropSourceImpl); cdecl;
  var
    LFormat: TFormatEtc;
    LMedium: TStgMedium;
    I: Integer;
  begin
    try
      LFormat := MakeFormat(TClipboardFormat(data^.get_target));
      for I := 0 to src.DataProviders.Count - 1 do
      begin
        if src.DataProviders[I].IsSupported(LFormat) then
        begin
          if src.DataProviders[I].Store(LMedium, LFormat) then
          try
            gtk_selection_data_set(data, data^.get_target, 8, LMedium.Data, LMedium.Size);
          finally
            ReleaseStgMedium(LMedium)
          end;
          Break;
        end;
      end;
    except
      Application.HandleException(nil);
    end;
  end;

  procedure TACLDropSourceImpl.ExecuteImpl;
  var
    LActions: TGdkDragAction;
    LControl: TWinControl;
    LEntries: TACLListOf<TGtkTargetEntry>;
    LEntry: TGtkTargetEntry;
    LList: PGtkTargetList;
    LWidget: PGtkWidget;
    I: Integer;
  begin
    LActions := [];
    if dsaCopy in AllowedActions then
      LActions := LActions + [GDK_ACTION_COPY];
    if dsaMove in AllowedActions then
      LActions := LActions + [GDK_ACTION_MOVE];
    if dsaLink in AllowedActions then
      LActions := LActions + [GDK_ACTION_LINK];

    LControl := Control;
    while (LControl <> nil) and not LControl.Visible do
      LControl := LControl.Parent;
    if LControl = nil then
      raise EInvalidArgument.Create('Cannot start drop-source operation on invisible control');

    LList := gtk_target_list_new(nil, 0);
    for I := 0 to DataProviders.Count - 1 do
    begin
      if DataProviders[I].HasData then
        gtk_target_list_add(LList, PGdkAtom(DataProviders[I].GetFormat.cfFormat), 0, 0);
    end;

    FDone := False;
    LWidget := TGtk3Widget(LControl.Handle).GetContainerWidget;
    g_signal_connect_data(LWidget, 'drag_data_get', @doGtkDropGetData, Self, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(LWidget, 'drag_end', @doGtkDropEnd, Self, nil, G_CONNECT_DEFAULT);
    try
      try
        FContext := LWidget^.drag_begin_with_coordinates(LList, LActions, 1, nil, -1, -1);
        if FContext <> nil then
        repeat
          try
            TGtkApp.ProcessMessages;
          except
            Application.HandleException(Self);
          end;
          Application.Idle(True);
        until FDone;
      finally
        FContext := nil;
        //* Bug in GTK.  If a drag is initiated using gtk_drag_begin and the
        //* mouse is released immediately, the mouse and keyboard remain
        //* grabbed.  The fix is to release the grab on the mouse and keyboard
        //* whenever the drag is terminated.
        //gdk_keyboard_ungrab(GDK_CURRENT_TIME);
        gdk_pointer_ungrab(GDK_CURRENT_TIME);
      end;
    finally
      if Control <> nil then
      begin
        gtk_signal_disconnect_by_func(LWidget, @doGtkDropGetData, Self);
        gtk_signal_disconnect_by_func(LWidget, @doGtkDropEnd, Self);
      end;
    end;
  end;

  procedure TACLDropSourceImpl.Cancel;
  begin
    inherited;
    if FContext <> nil then
    try
      gtk_drag_cancel(FContext);
    except
      // do nothing
    end;
    FDone := True;
  end;
