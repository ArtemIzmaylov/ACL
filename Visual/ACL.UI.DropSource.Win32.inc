uses
  Winapi.ShlObj,
  Winapi.Windows,
  System.Win.ComObj;

type

  { TACLDropFormatEtcList }

  TACLDropFormatEtcList = class(TInterfacedObject, IEnumFormatEtc)
  strict private const
    ResultMap: array[Boolean] of Integer = (S_FALSE, S_OK);
  strict private
    FCursor: Integer;
    FList: TACLListOf<TFormatEtc>;

    function GetFormat(Index: Integer): TFormatEtc;
    function GetFormatCount: Integer;
  protected
    // IEnumFormatEtc
    function Clone(out AEnum: IEnumFormatEtc): HRESULT; stdcall;
    function Next(ACount: Longint; out AList; AFetched: PLongint): HRESULT; stdcall;
    function Reset: HRESULT; stdcall;
    function Skip(ACount: Longint) : HRESULT; stdcall;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AFormat: TFormatEtc);
    procedure Assign(ASource: TACLDropFormatEtcList);
    //# Properties
    property Cursor: Integer read FCursor;
    property Format[Index: Integer]: TFormatEtc read GetFormat;
    property FormatCount: Integer read GetFormatCount;
  end;

  { TACLDropSourceImpl }

  TACLDropSourceImpl = class(TACLDropSource, IDropSource, IDataObject)
  strict private
    function GetAttachThreadId: THandle;
  protected
    procedure ExecuteImpl; override;
    // IDataObject
    function DAdvise(const AFormat: TFormatEtc; advf: Longint;
      const advSink: IAdviseSink; out dwConnection: Longint): HRESULT; stdcall;
    function DUnadvise(AConnection: Longint): HRESULT; stdcall;
    function EnumDAdvise(out AEnumAdvise: IEnumStatData): HRESULT; stdcall;
    function EnumFormatEtc(ADirection: Longint; out AEnumFormat: IEnumFormatEtc): HRESULT; stdcall;
    function GetCanonicalFormatEtc(const AFormat: TFormatEtc; out AFormatOut: TFormatEtc): HRESULT; stdcall;
    function GetData(const AFormat: TFormatEtc; out AMedium: TStgMedium): HRESULT; stdcall;
    function GetDataHere(const AFormat: TFormatEtc; out AMedium: TStgMedium): HRESULT; stdcall;
    function QueryGetData(const AFormat: TFormatEtc): HRESULT; stdcall;
    function SetData(const Format: TFormatEtc; var Medium: TStgMedium; Release: BOOL): HRESULT; stdcall;
    // IDropSource
    function GiveFeedback(AEffect: LongInt): HRESULT; stdcall;
    function QueryContinueDrag(AEscapePressed: LongBool; AKeyState: LongInt): HRESULT; stdcall;
  public
    procedure Execute; override;
  end;

  { TACLDropFormatEtcList }

  constructor TACLDropFormatEtcList.Create;
  begin
    inherited Create;
    FList := TACLListOf<TFormatEtc>.Create;
  end;

  destructor TACLDropFormatEtcList.Destroy;
  begin
    FreeAndNil(FList);
    inherited Destroy;
  end;

  procedure TACLDropFormatEtcList.Add(const AFormat: TFormatEtc);
  begin
    FList.Add(AFormat);
  end;

  procedure TACLDropFormatEtcList.Assign(ASource: TACLDropFormatEtcList);
  var
    I: Integer;
  begin
    FList.Clear;
    FCursor := ASource.Cursor;
    for I := 0 to ASource.FormatCount - 1 do
      Add(ASource.Format[I]);
  end;

  function TACLDropFormatEtcList.Next(ACount: Longint; out AList; AFetched: PLongint): HRESULT;
  var
    AFormatList: PFormatEtc;
    AIndex: Integer;
  begin
    AFormatList := @AList;

    AIndex := 0;
    while (AIndex < ACount) and (Cursor < FormatCount) do
    begin
      AFormatList^ := Format[Cursor];
      Inc(AFormatList);
      Inc(FCursor);
      Inc(AIndex);
    end;
    if Assigned(AFetched) then
      AFetched^ := AIndex;
    Result := ResultMap[AIndex = ACount];
  end;

  function TACLDropFormatEtcList.Skip(ACount: Longint): HRESULT;
  begin
    Result := ResultMap[Cursor + ACount <= FormatCount];
    FCursor := Min(FormatCount, Cursor + ACount);
  end;

  function TACLDropFormatEtcList.Reset: HRESULT;
  begin
    FCursor := 0;
    Result := S_OK;
  end;

  function TACLDropFormatEtcList.Clone(out AEnum: IEnumFormatEtc): HRESULT;
  var
    AFormatEtc: TACLDropFormatEtcList;
  begin
    AFormatEtc := TACLDropFormatEtcList.Create;
    AFormatEtc.Assign(Self);
    AEnum := AFormatEtc;
    Result := S_OK;
  end;

  function TACLDropFormatEtcList.GetFormat(Index: Integer): TFormatEtc;
  begin
    Result := FList[Index];
  end;

  function TACLDropFormatEtcList.GetFormatCount: Integer;
  begin
    Result := FList.Count;
  end;

  { TACLDropSourceImpl }

  procedure TACLDropSourceImpl.Execute;
  begin
    if IsWine then
      ExecuteCore
    else
      TThread.CreateAnonymousThread(ExecuteCore).Start;
  end;

  procedure TACLDropSourceImpl.ExecuteImpl;
  var
    LActions: Integer;
    LResult: Integer;
    LThread1: THandle;
    LThread2: THandle;
  begin
    LThread1 := GetAttachThreadId;
    LThread2 := GetCurrentThreadId;
    if LThread1 <> LThread2 then
      AttachThreadInput(LThread1, LThread2, True);
    try
      LActions := 0;
      if dsaCopy in AllowedActions then
        LActions := LActions or DROPEFFECT_COPY;
      if dsaMove in AllowedActions then
        LActions := LActions or DROPEFFECT_MOVE;
      if dsaLink in AllowedActions then
        LActions := LActions or DROPEFFECT_LINK;

      OleInitialize(nil);
      try
        if DoDragDrop(Self, Self, LActions, LResult) = DRAGDROP_S_DROP then
        begin
          if LResult and DROPEFFECT_COPY <> 0 then
            Include(FDropResult, dsaCopy);
          if LResult and DROPEFFECT_MOVE <> 0 then
            Include(FDropResult, dsaMove);
          if LResult and DROPEFFECT_LINK <> 0 then
            Include(FDropResult, dsaLink);
        end;
      finally
        OleUninitialize;
      end;
    finally
      if LThread1 <> LThread2 then
        AttachThreadInput(LThread1, LThread2, False);
    end;
  end;

  function TACLDropSourceImpl.GiveFeedback(AEffect: LongInt): HRESULT; stdcall;
  begin
    Result := DRAGDROP_S_USEDEFAULTCURSORS;
  end;

  function TACLDropSourceImpl.QueryContinueDrag(AEscapePressed: LongBool; AKeyState: LongInt): HRESULT; stdcall;
  begin
    if AEscapePressed or (Handler = nil) then
      Exit(DRAGDROP_S_CANCEL);
    if AKeyState and (MK_LBUTTON or MK_RBUTTON) <> 0 then
      Exit(S_OK);
    Result := DRAGDROP_S_DROP;
  end;

  function TACLDropSourceImpl.DAdvise(const AFormat: TFormatEtc; advf: Longint;
    const advSink: IAdviseSink; out dwConnection: Longint): HRESULT; stdcall;
  begin
    Result := OLE_E_ADVISENOTSUPPORTED;
  end;

  function TACLDropSourceImpl.DUnadvise(AConnection: Longint):HRESULT; stdcall;
  begin
    Result := OLE_E_ADVISENOTSUPPORTED;
  end;

  function TACLDropSourceImpl.EnumDAdvise(out AEnumAdvise: IEnumStatData): HRESULT; stdcall;
  begin
    Result := OLE_E_ADVISENOTSUPPORTED;
  end;

  function TACLDropSourceImpl.EnumFormatEtc(
    ADirection: Longint; out AEnumFormat: IEnumFormatEtc): HRESULT; stdcall;
  const
    ResultMap: array[Boolean] of HRESULT = (E_NOTIMPL, S_OK);
  var
    ADataProvider: TACLDragDropDataProvider;
    AFormatEtcList: TACLDropFormatEtcList;
    I: Integer;
  begin
    AEnumFormat := nil;
    if ADirection = DATADIR_GET then
    try
      AFormatEtcList := TACLDropFormatEtcList.Create;
      for I := 0 to DataProviders.Count - 1 do
      begin
        ADataProvider := DataProviders[I];
        if ADataProvider.HasData then
          AFormatEtcList.Add(ADataProvider.GetFormat);
      end;
      if AFormatEtcList.FormatCount > 0 then
        AEnumFormat := AFormatEtcList;
    except
      Application.HandleException(nil);
    end;
    Result := ResultMap[AEnumFormat <> nil];
  end;

  function TACLDropSourceImpl.GetCanonicalFormatEtc(
    const AFormat: TFormatEtc; out AFormatOut: TFormatEtc): HRESULT; stdcall;
  begin
    AFormatOut.ptd := nil;
    Result := E_NOTIMPL;
  end;

  function TACLDropSourceImpl.QueryGetData(const AFormat: TFormatEtc): HRESULT; stdcall;
  var
    LProvider: TACLDragDropDataProvider;
    I: Integer;
  begin
    Result := DV_E_FORMATETC;
    if AFormat.dwAspect = DVASPECT_CONTENT then
    try
      for I := 0 to DataProviders.Count - 1 do
      begin
        LProvider := DataProviders[I];
        if LProvider.IsSupported(AFormat) and LProvider.HasData then
          Exit(S_OK);
      end;
    except
      Application.HandleException(nil);
    end;
  end;

  function TACLDropSourceImpl.GetAttachThreadId: THandle;
  var
    LWnd: TWndHandle;
  begin
    LWnd := GetForegroundWindow;
    // Fallback to the unsafe method in case GetForegroundWindow didn't work
    // out (from MSDN: The foreground window can be NULL in certain
    // circumstances, such as when a window is losing activation).
    if LWnd = 0 then
    begin
      // Get handle of window under mouse-cursor.
      // Warning: This introduces a race condition. The cursor might have moved
      // from the original drop source window to another window. This can happen
      // easily if the user moves the cursor rapidly or if sufficient time has
      // elapsed since DragDetect exited.
      LWnd := MouseCurrentWindow;
    end;
    if LWnd <> 0 then
      Result := GetWindowThreadProcessId(LWnd, nil)
    else
      Result := MainThreadID;
  end;

  function TACLDropSourceImpl.GetData(const AFormat: TFormatEtc; out AMedium: TStgMedium): HRESULT; stdcall;
  var
    LProvider: TACLDragDropDataProvider;
    I: Integer;
  begin
    ZeroMemory(@AMedium, SizeOf(AMedium));
    try
      for I := 0 to DataProviders.Count - 1 do
      begin
        LProvider := DataProviders[I];
        if LProvider.IsSupported(AFormat) and LProvider.HasData then
        begin
          if LProvider.Store(AMedium, AFormat) then
            Exit(S_OK);
        end;
      end;
    except
      Application.HandleException(nil);
    end;
    Result := DV_E_FORMATETC;
  end;

  function TACLDropSourceImpl.GetDataHere(const AFormat: TFormatEtc; out AMedium: TStgMedium): HRESULT; stdcall;
  begin
    Result := E_NOTIMPL;
  end;

  function TACLDropSourceImpl.SetData(const Format: TFormatEtc;
    var Medium: TStgMedium; Release: BOOL): HRESULT; stdcall;
  begin
    Result := E_NOTIMPL;
    try
  //    if (Format.tymed = TYMED_HGLOBAL) and (Format.cfFormat = CF_CONFIG) then
  //    begin
  //      StreamLoad(FTargetConfig.LoadFromStream, TACLGlobalMemoryStream.Create(Medium.hGlobal));
  //      Result := S_OK;
  //    end;
    finally
      if Release then
        ReleaseStgMedium(Medium);
    end;
  end;

{$REGION ' Formats / Windows Specific '}

  { TACLDragDropDataProviderFileStream }

  constructor TACLDragDropDataProviderFileStream.Create(AData: IACLDropSourceDataFiles; AIndex: Integer);
  begin
    inherited Create(AData);
    FIndex := AIndex;
  end;

  function TACLDragDropDataProviderFileStream.GetFormat: TFormatEtc;
  begin
    Result := MakeFormat(RegisterClipboardFormat(CFSTR_FILECONTENTS));
    Result.tymed := TYMED_ISTREAM;
    Result.lindex := FIndex;
  end;

  function TACLDragDropDataProviderFileStream.IsSupported(const AFormat: TFormatEtc): Boolean;
  begin
    Result := (AFormat.cfFormat = GetFormat.cfFormat) and
      (AFormat.tymed and TYMED_ISTREAM <> 0) and (AFormat.lindex = FIndex);
  end;

  function TACLDragDropDataProviderFileStream.Store(
    out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean;
  begin
    Result := (AFormat.tymed and TYMED_ISTREAM <> 0) and (Data.Count > 0);
    if Result then
    begin
      AMedium.tymed := TYMED_ISTREAM;
      IStream(AMedium.stm) := TStreamAdapter.Create(Data.Streams[FIndex]);
    end;
  end;

  { TACLDragDropDataProviderFileStreamDescriptor }

  function TACLDragDropDataProviderFileStreamDescriptor.GetFormat: TFormatEtc;
  begin
    Result := MakeFormat(RegisterClipboardFormat(CFSTR_FILEDESCRIPTORW));
  end;

  function TACLDragDropDataProviderFileStreamDescriptor.Store(
    out AMedium: TStgMedium; const AFormat: TFormatEtc): Boolean;
  var
    ADescriptor: PFileGroupDescriptorW;
    ADescriptorSize: Integer;
    AFileDescriptor: PFileDescriptorW;
    AFileSize: Int64;
    I: Integer;
  begin
    ADescriptorSize := SizeOf(TFileGroupDescriptorW) + (Data.Count - 1) * SizeOf(TFileDescriptorW);
    ADescriptor := AllocMem(ADescriptorSize);
    try
      ADescriptor.cItems := Data.Count;
      for I := 0 to Data.Count - 1 do
      begin
        AFileDescriptor := @ADescriptor.fgd[I];
        StrLCopy(@AFileDescriptor.cFileName[0], PChar(acExtractFileName(Data.Names[I])), MAX_PATH);
        AFileSize := Data.Streams[I].Size;
        AFileDescriptor.dwFlags := FD_PROGRESSUI or FD_FILESIZE;
        AFileDescriptor.nFileSizeHigh := HiInteger(AFileSize);
        AFileDescriptor.nFileSizeLow := LoInteger(AFileSize);
      end;
      AMedium.tymed := TYMED_HGLOBAL;
      AMedium.hGlobal := TACLGlobalMemory.Alloc(PByte(ADescriptor), ADescriptorSize);
      Result := True;
    finally
      FreeMem(ADescriptor);
    end;
  end;

  { TACLDragDropDataProviderPIDL }

  function TACLDragDropDataProviderPIDL.StoreFiles(
    AFiles: TACLStringList; out AMedium: TStgMedium): Boolean;
  var
    LStream: TMemoryStream;
  begin
    Result := False;
    if TPIDLHelper.FilesToShellListStream(AFiles, LStream) then
    try
      Result := MediumAlloc(LStream.Memory, LStream.Size, AMedium);
    finally
      LStream.Free;
    end;
  end;

  function TACLDragDropDataProviderPIDL.GetFormat: TFormatEtc;
  begin
    Result := MakeFormat(CF_SHELLIDList);
  end;

{$ENDREGION}
