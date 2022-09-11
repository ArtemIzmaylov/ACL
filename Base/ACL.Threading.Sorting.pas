{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*         Multi Threading Routines          *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Threading.Sorting;

{$I ACL.Config.inc}

interface

uses
  System.Classes,
  System.Generics.Defaults,
  System.SysUtils,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Threading,
  ACL.Utils.Common;

type

  { TACLCustomMultithreadedSorter }

  TACLCustomMultithreadedSorter = class
  strict private type

    PMergeChunk = ^TMergeChunk;
    TMergeChunk = record
      FinishIndex: Integer;
      MiddleIndex: Integer;
      Sorter: TACLCustomMultithreadedSorter;
      StartIndex: Integer;
    end;

    PSortChunk = ^TSortChunk;
    TSortChunk = record
      Sorter: TACLCustomMultithreadedSorter;
      StartIndex: Integer;
      FinishIndex: Integer;
    end;

  strict private
    FActiveThreadCount: Integer;
    FEvent: TACLEvent;
    FMergeChunks: TArray<TMergeChunk>;
    FSortChunks: TArray<TSortChunk>;

    function GetSortChunkCount: Integer;
    class function MergeFunction(AChunk: PMergeChunk): Integer; static; stdcall;
    class function QuickSortFunction(AChunk: PSortChunk): Integer; static; stdcall;
  protected
    FCount: Integer;

    procedure CheckDone;
    procedure CreateSortChunks;
    procedure DoMerge; virtual;
    procedure DoSort(Multithreadeding: Boolean); virtual;
    procedure DoSortChunks;
    //
    procedure Merge(ALowBound, ADivider, AHiBound: Integer); virtual; abstract;
    procedure QuickSort(L, R: Integer); virtual; abstract;
  end;

  { TACLMultithreadedListSorter }

  TACLMultithreadedListSorter = class(TACLCustomMultithreadedSorter)
  protected
    FCompareProc: TACLListCompareProc;
    FList: PPointerArray;
    FTempList: PPointerArray;

    procedure DoMerge; override;
    procedure Merge(ALowBound, ADivider, AHiBound: Integer); override;
    procedure QuickSort(L, R: Integer); override;
  public
    class procedure Sort(List: PPointerArray; Count: Integer; CompareProc: TACLListCompareProc; Multithreadeding: Boolean = True); overload;
    class procedure Sort(List: TList; CompareProc: TACLListCompareProc; Multithreadeding: Boolean = True); overload;
  end;

  { TACLMultithreadedStringListSorter }

  TACLMultithreadedStringListSorter = class(TACLCustomMultithreadedSorter)
  protected
    FCompareProc: TACLStringListCompareProc;
    FList: PACLStringListItemList;
    FTempList: PACLStringListItemList;

    procedure DoMerge; override;
    procedure Merge(ALowBound, ADivider, AHiBound: Integer); override;
    procedure QuickSort(L, R: Integer); override;
  public
    class procedure Sort(List: TACLStringList; CompareProc: TACLStringListCompareProc; Multithreadeding: Boolean = True);
  end;

implementation

uses
  ACL.FastCode;

type
  TACLStringListAccess = class(TACLStringList);

{ TACLCustomMultithreadedSorter }

procedure TACLCustomMultithreadedSorter.CreateSortChunks;
var
  AChunkCount: Integer;
  AChunkSize: Integer;
  AFinishIndex: Integer;
  AChunksLeft: Integer;
  AStartIndex: Integer;
  I: Integer;
begin
  AChunkCount := GetSortChunkCount;
  AChunkSize := FCount div AChunkCount;
  AChunksLeft := FCount mod AChunkCount;

  AStartIndex := 0;
  SetLength(FSortChunks, AChunkCount);
  for I := 0 to AChunkCount - 1 do
  begin
    AFinishIndex := AStartIndex + AChunkSize - 1;
    if AChunksLeft > 0 then
    begin
      Inc(AFinishIndex);
      Dec(AChunksLeft);
    end;

    FSortChunks[I].Sorter := Self;
    FSortChunks[I].StartIndex := AStartIndex;
    FSortChunks[I].FinishIndex := AFinishIndex;

    AStartIndex := AFinishIndex + 1;
  end;
end;

procedure TACLCustomMultithreadedSorter.DoMerge;
var
  AMergeChunkCount: Integer;
  I: Integer;
begin
  AMergeChunkCount := Length(FSortChunks) shr 1;
  SetLength(FMergeChunks, AMergeChunkCount);
  while AMergeChunkCount > 0 do
  begin
    FEvent.Reset;
    FActiveThreadCount := AMergeChunkCount;
    for I := 0 to AMergeChunkCount - 1 do
    begin
      FMergeChunks[I].Sorter := Self;
      FMergeChunks[I].StartIndex := FSortChunks[I * 2].StartIndex;
      FMergeChunks[I].MiddleIndex := FSortChunks[I * 2].FinishIndex;
      FMergeChunks[I].FinishIndex := FSortChunks[I * 2 + 1].FinishIndex;

      RunInThread(@MergeFunction, @FMergeChunks[I]);

      FSortChunks[I].StartIndex := FSortChunks[I * 2].StartIndex;
      FSortChunks[I].FinishIndex := FSortChunks[I * 2 + 1].FinishIndex;
    end;
    FEvent.WaitForNoSynchronize(INFINITE);
    AMergeChunkCount := AMergeChunkCount shr 1;
  end;
end;

procedure TACLCustomMultithreadedSorter.DoSort(Multithreadeding: Boolean);
begin
  if Multithreadeding and (GetSortChunkCount > 1) and (FCount > GetSortChunkCount) and (FCount > 100) then
  begin
    FEvent := TACLEvent.Create(True, False);
    try
      DoSortChunks;
      DoMerge;
    finally
      FreeAndNil(FEvent);
    end;
  end
  else
    QuickSort(0, FCount - 1);
end;

procedure TACLCustomMultithreadedSorter.DoSortChunks;
var
  I: Integer;
begin
  FEvent.Reset;
  CreateSortChunks;
  FActiveThreadCount := Length(FSortChunks);
  for I := 0 to Length(FSortChunks) - 1 do
    RunInThread(@QuickSortFunction, @FSortChunks[I]);
  FEvent.WaitForNoSynchronize;
end;

procedure TACLCustomMultithreadedSorter.CheckDone;
begin
  if AtomicDecrement(FActiveThreadCount) = 0 then
    FEvent.Signal;
end;

function TACLCustomMultithreadedSorter.GetSortChunkCount: Integer;
begin
  case CPUCount of
    1:
      Result := 1;
    2..3:
      Result := 8;
  else
    Result := 16;
  end;
end;

class function TACLCustomMultithreadedSorter.MergeFunction(AChunk: PMergeChunk): Integer;
begin
  Result := 0;
  try
    try
      AChunk^.Sorter.Merge(AChunk^.StartIndex, AChunk^.MiddleIndex, AChunk^.FinishIndex);
    except
      // do nothing
    end;
  finally
    AChunk^.Sorter.CheckDone;
  end;
end;

class function TACLCustomMultithreadedSorter.QuickSortFunction(AChunk: PSortChunk): Integer;
begin
  Result := 0;
  try
    try
      AChunk^.Sorter.QuickSort(AChunk^.StartIndex, AChunk^.FinishIndex);
    except
      // do nothing
    end;
  finally
    AChunk^.Sorter.CheckDone;
  end;
end;

{ TACLMultithreadedListSorter }

class procedure TACLMultithreadedListSorter.Sort(List: PPointerArray; Count: Integer;
  CompareProc: TACLListCompareProc; Multithreadeding: Boolean = True);
begin
  if Count > 1 then
  begin
    with Create do
    try
      FList := List;
      FCount := Count;
      FCompareProc := CompareProc;
      DoSort(Multithreadeding);
    finally
      Free;
    end;
  end;
end;

class procedure TACLMultithreadedListSorter.Sort(List: TList; CompareProc: TACLListCompareProc; Multithreadeding: Boolean = True);
begin
  Sort(@List.List[0], List.Count, CompareProc, Multithreadeding);
end;

procedure TACLMultithreadedListSorter.DoMerge;
begin
  FTempList := AllocMem(FCount * SizeOf(Pointer));
  try
    inherited DoMerge;
  finally
    FreeMem(FTempList);
  end;
end;

procedure TACLMultithreadedListSorter.Merge(ALowBound, ADivider, AHiBound: Integer);
var
  ACount: Integer;
  ADest: PPointer;
  AHighA: PPointer;
  AHighB: PPointer;
  AIndexA: Integer;
  AIndexB: Integer;
  AItemA: PPointer;
  AItemB: PPointer;
  ATempSize: Integer;
begin
  ADest := @FList[ALowBound];
  ATempSize := (AHiBound - ALowBound + 1) * SizeOf(Pointer);
  FastMove(ADest^, Pointer(@FTempList[ALowBound])^, ATempSize);
  AIndexA := ALowBound;
  AIndexB := ADivider + 1;
  AItemA := @FTempList[AIndexA];
  AHighA := @FTempList[ADivider];
  AItemB := AHighA;
  Inc(AItemB);
  AHighB := @FTempList[AHiBound];
  while (NativeUInt(AItemA) <= NativeUInt(AHighA)) and (NativeUInt(AItemB) <= NativeUInt(AHighB)) do
  begin
    if FCompareProc(AItemA^, AItemB^) < 0 then
    begin
      ADest^ := AItemA^;
      Inc(AItemA);
      Inc(AIndexA);
    end
    else
    begin
      ADest^ := AItemB^;
      Inc(AItemB);
      Inc(AIndexB);
    end;
    Inc(ADest);
  end;
  if AIndexB > AHiBound then
  begin
    ACount := ADivider - AIndexA + 1;
    AItemA := @FTempList[AIndexA];
  end
  else
  begin
    ACount := AHiBound - AIndexB + 1;
    AItemA := @FTempList[AIndexB];
  end;
  if ACount > 0 then
    FastMove(AItemA^, ADest^, ACount * SizeOf(Pointer));
end;

procedure TACLMultithreadedListSorter.QuickSort(L, R: Integer);
var
  APivot: Pointer;
  ATemp: Pointer;
  I, J, P: Integer;
begin
  repeat
    I := L;
    J := R;
    P := (L + R) shr 1;
    repeat
      APivot := FList[P];
      while FCompareProc(FList[I], APivot) < 0 do
        Inc(I);
      while FCompareProc(FList[J], APivot) > 0 do
        Dec(J);
      if I <= J then
      begin
        if I <> J then
        begin
          ATemp := FList[I];
          FList[I] := FList[J];
          FList[J] := ATemp;
        end;
        if P = I then P := J else
        if P = J then P := I;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSort(L, J);
    L := I;
  until I >= R;
end;

{ TACLMultithreadedStringListSorter }

class procedure TACLMultithreadedStringListSorter.Sort(List: TACLStringList;
  CompareProc: TACLStringListCompareProc; Multithreadeding: Boolean);
begin
  if List.Count > 1 then
  begin
    with Create do
    try
      FCount := List.Count;
      FCompareProc := CompareProc;
      FList := TACLStringListAccess(List).List;
      DoSort(Multithreadeding);
    finally
      Free;
    end;
  end;
end;

procedure TACLMultithreadedStringListSorter.DoMerge;
begin
  FTempList := AllocMem(FCount * SizeOf(TACLStringListItem));
  try
    inherited DoMerge;
  finally
    FreeMem(FTempList);
  end;
end;

procedure TACLMultithreadedStringListSorter.Merge(ALowBound, ADivider, AHiBound: Integer);
var
  ACount: Integer;
  ADest: PACLStringListItem;
  AHighA: PACLStringListItem;
  AHighB: PACLStringListItem;
  AIndexA: Integer;
  AIndexB: Integer;
  AItemA: PACLStringListItem;
  AItemB: PACLStringListItem;
  ATempSize: Integer;
begin
  ADest := @FList[ALowBound];
  ATempSize := (AHiBound - ALowBound + 1) * SizeOf(TACLStringListItem);
  FastMove(ADest^, Pointer(@FTempList[ALowBound])^, ATempSize);
  AIndexA := ALowBound;
  AIndexB := ADivider + 1;
  AItemA := @FTempList[AIndexA];
  AHighA := @FTempList[ADivider];
  AItemB := AHighA;
  Inc(AItemB);
  AHighB := @FTempList[AHiBound];
  while (NativeUInt(AItemA) <= NativeUInt(AHighA)) and (NativeUInt(AItemB) <= NativeUInt(AHighB)) do
  begin
    if FCompareProc(AItemA^, AItemB^) < 0 then
    begin
      ADest^.MoveFrom(AItemA^);
      Inc(AItemA);
      Inc(AIndexA);
    end
    else
    begin
      ADest^.MoveFrom(AItemB^);
      Inc(AItemB);
      Inc(AIndexB);
    end;
    Inc(ADest);
  end;
  if AIndexB > AHiBound then
  begin
    ACount := ADivider - AIndexA + 1;
    AItemA := @FTempList[AIndexA];
  end
  else
  begin
    ACount := AHiBound - AIndexB + 1;
    AItemA := @FTempList[AIndexB];
  end;
  if ACount > 0 then
    FastMove(AItemA^, ADest^, ACount * SizeOf(TACLStringListItem));
end;

procedure TACLMultithreadedStringListSorter.QuickSort(L, R: Integer);
var
  APivot: PACLStringListItem;
  I, J, P: Integer;
begin
  repeat
    I := L;
    J := R;
    P := (L + R) shr 1;
    repeat
      APivot := @FList[P];
      while FCompareProc(FList[I], APivot^) < 0 do
        Inc(I);
      while FCompareProc(FList[J], APivot^) > 0 do
        Dec(J);
      if I <= J then
      begin
        if I <> J then
          FList[I].Exchange(FList[J]);
        if P = I then P := J else
        if P = J then P := I;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSort(L, J);
    L := I;
  until I >= R;
end;

end.
