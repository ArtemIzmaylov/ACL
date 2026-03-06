{%MainUnit ACL.UI.DropSource.pas}

uses
  Glib2,
  Gdk2,
  Gtk2,
  Gtk2Def,
  Gtk2Int,
  Gtk2Proc,
  // ACL
  ACL.UI.Core.Impl.Gtk2;

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

  { TACLDropSourceImpl }

  procedure doGtkDropEnd(w: PGtkWidget; ctx: PGdkDragContext; impl: TACLDropSourceImpl); cdecl;
  begin
    try
      try
        impl.FDropResult := [];
        case ctx^.action of
          GDK_ACTION_COPY:
            impl.FDropResult := [dsaCopy];
          GDK_ACTION_MOVE:
            impl.FDropResult := [dsaMove];
          GDK_ACTION_LINK:
            impl.FDropResult := [dsaLink];
        end;
      finally
        Impl.FDone := True;
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
      LFormat := MakeFormat(data^.target);
      for I := 0 to src.DataProviders.Count - 1 do
      begin
        if src.DataProviders[I].IsSupported(LFormat) then
        begin
          if src.DataProviders[I].Store(LMedium, LFormat) then
          try
            gtk_selection_data_set(data, data^.target, 8, LMedium.Data, LMedium.Size);
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
    LActions := 0;
    if dsaCopy in AllowedActions then
      LActions := LActions or GDK_ACTION_COPY;
    if dsaMove in AllowedActions then
      LActions := LActions or GDK_ACTION_MOVE;
    if dsaLink in AllowedActions then
      LActions := LActions or GDK_ACTION_LINK;

    LControl := Control;
    while (LControl <> nil) and not LControl.Visible do
      LControl := LControl.Parent;
    if LControl = nil then
      raise EInvalidArgument.Create('Cannot start drop-source operation on invisible control');

    LList := gtk_target_list_new(nil, 0);
    for I := 0 to DataProviders.Count - 1 do
    begin
      if DataProviders[I].HasData then
        gtk_target_list_add(LList, DataProviders[I].GetFormat.cfFormat, 0, 0);
    end;

    FDone := False;
    LWidget := PGtkWidget(LControl.Handle);
    ConnectSignal(PGtkObject(LWidget), 'drag_data_get', @doGtkDropGetData, Self);
    ConnectSignal(PGtkObject(LWidget), 'drag_end', @doGtkDropEnd, Self);
    try
      FContext := gtk_drag_begin(LWidget, LList, LActions, 1, nil);
      try
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
        gdk_keyboard_ungrab(GDK_CURRENT_TIME);
        gdk_pointer_ungrab(GDK_CURRENT_TIME);
      end;
    finally
      if Control <> nil then
      begin
        gtk_signal_disconnect_by_func(PGtkObject(LWidget), @doGtkDropGetData, Self);
        gtk_signal_disconnect_by_func(PGtkObject(LWidget), @doGtkDropEnd, Self);
      end;
    end;
  end;

  procedure TACLDropSourceImpl.Cancel;
  begin
    inherited;
    if FContext <> nil then
    try
      gtk_drag_finish(FContext, False, False, GDK_CURRENT_TIME);
    except
      // do nothing
    end;
    FDone := True;
  end;
