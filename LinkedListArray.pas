unit LinkedListArray;

interface

uses
  AuxTypes, AuxClasses;

type
  TListIndex  = Integer;
  TArrayIndex = Integer;

  TLinkedListArrayPayload = record end;
  PLinkedListArrayPayload = ^TLinkedListArrayPayload;

  TLinkedListArrayItem = record
    Prev:       TArrayIndex;
    Next:       TArrayIndex;
    Flags:      Integer;
  {$IF SizeOf(Integer) = 4}
    Padding:    Integer;
  {$IFEND}
    Payload:    TLinkedListArrayPayload;
  end;
  PLinkedListArrayItem = ^TLinkedListArrayItem;

  TLinkedListArray = class(TCustomListObject)
  private
    fPayloadSize:       TMemSize;
    fPayloadOffset:     PtrUInt;
    fItemSize:          TMemSize;
    fMemory:            Pointer;
    fCapacity:          Integer;
    fCount:             Integer;
    fChangeCounter:     Integer;
    fChanged:           Boolean;
    fOnChangeEvent:     TNotifyEvent;
    fOnChangeCallback:  TNotifyCallback;
  protected
    fTempPayload:       Pointer;
    fFirstFree:         TArrayIndex;
    fLastFree:          TArrayIndex;
    fFirstUsed:         TArrayIndex;
    fLastUsed:          TArrayIndex;
    Function PayloadPtrFromItemPtr(ItemPtr: PLinkedListArrayItem): PLinkedListArrayPayload; virtual;
    Function ItemPtrFromPayloadPtr(PayloadPtr: PLinkedListArrayPayload): PLinkedListArrayItem; virtual;

    Function GetItemPtr(ArrayIndex: TArrayIndex): PLinkedListArrayItem; virtual;
    Function GetPayloadPtr(ArrayIndex: TArrayIndex): PLinkedListArrayPayload; virtual;
    procedure SetPayloadPtr(ArrayIndex: TArrayIndex; Value: PLinkedListArrayPayload); virtual;
    Function GetPayloadPtrListIndex(ListIndex: TListIndex): PLinkedListArrayPayload; virtual;
    procedure SetPayloadPtrListIndex(ListIndex: TListIndex; Value: PLinkedListArrayPayload); virtual;

    Function GetCapacity: Integer; override;
    procedure SetCapacity(Value: Integer); override;
    Function GetCount: Integer; override;
    procedure SetCount(Value: Integer); override;

    Function CheckArrayIndex(ArrayIndex: TArrayIndex): Boolean; virtual;
    Function CheckListIndex(ListIndex: TListIndex): Boolean; virtual;
    Function CheckArrayIndexAndRaise(ArrayIndex: TArrayIndex; CallingMethod: String = 'CheckArrayIndexAndRaise'): Boolean; virtual;
    Function CheckListIndexAndRaise(ListIndex: TListIndex; CallingMethod: String = 'CheckListIndexAndRaise'): Boolean; virtual;
    procedure RaiseError(const ErrorMessage: String; Values: array of const); overload; virtual;
    procedure RaiseError(const ErrorMessage: String); overload; virtual;

    procedure PayloadInit(Payload: PLinkedListArrayPayload); virtual;                       // <<< *
    procedure PayloadFinal(Payload: PLinkedListArrayPayload); virtual;                      // <<< *
    procedure PayloadCopy(SrcPayload,DstPayload: PLinkedListArrayPayload); virtual;         // <<< *
    Function PayloadCompare(Payload1,Payload2: PLinkedListArrayPayload): Integer; virtual;  // <<<
    Function PayloadEquals(Payload1,Payload2: PLinkedListArrayPayload): Boolean; virtual;   // <<< *

    procedure DoChange; virtual;    
    procedure FinalizeAllItems; virtual;
    procedure Decouple(ArrayIndex: TArrayIndex); virtual;
    procedure ArrayIndices(ListIndex1,ListIndex2: TListIndex; out ArrayIndex1,ArrayIndex2: TArrayIndex); virtual;
    procedure InternalDelete(ArrayIndex: TArrayIndex); virtual;

    Function SortCompare(ListIndex1,ListIndex2: Integer): Integer; virtual;
    Function DefragCompare(Index1,Index2: Integer): Integer; virtual;
    procedure DefragExchange(Index1,Index2: Integer); virtual;
  public
    constructor Create(PayloadSize: TMemSize);
    destructor Destroy; override;

    procedure BeginChanging; virtual;
    Function EndChanging: Integer; virtual;

    Function LowIndex: Integer; override;
    Function HighIndex: Integer; override;
    Function LowArrayIndex: TArrayIndex; virtual;
    Function HighArrayIndex: TArrayIndex; virtual;
    Function LowListIndex: TListIndex; virtual;
    Function HighListIndex: TListIndex; virtual;

    Function PreviousByArray(ArrayIndex: TArrayIndex): TArrayIndex; virtual;
    Function NextByArray(ArrayIndex: TArrayIndex): TArrayIndex; virtual;
    Function PreviousByList(ListIndex: TListIndex): TArrayIndex; virtual;
    Function NextByList(ListIndex: TListIndex): TArrayIndex; virtual;

    Function FirstArrayIndex: TArrayIndex; virtual;
    Function LastArrayIndex: TArrayIndex; virtual;
    Function First: PLinkedListArrayPayload; virtual;   // <<<
    Function Last: PLinkedListArrayPayload; virtual;    // <<<

    Function CheckIndex(Index: Integer): Boolean; override;    
    Function ArrayIndex(ListIndex: TListIndex): TArrayIndex; virtual;
    Function ListIndex(ArrayIndex: TArrayIndex): TListIndex; virtual;

    Function IndicesOf(Item: Pointer; out ArrayIndex: TArrayIndex; out ListIndex: TListIndex): Boolean; virtual;  // <<<
    Function ArrayIndexOf(Item: Pointer): TArrayIndex; virtual;                                                   // <<<
    Function ListIndexOf(Item: Pointer): TListIndex; virtual;                                                     // <<<

    Function Add(Item: Pointer): TListIndex; virtual;                 // <<<
    procedure Insert(ListIndex: TListIndex; Item: Pointer); virtual;  // <<<
    Function Extract(Item: Pointer): Pointer; virtual;                // <<<
    Function Remove(Item: Pointer): TListIndex; virtual;              // <<<
    procedure Delete(ListIndex: TListIndex); virtual;
    procedure Move(SrcListIndex,DstListIndex: TListIndex); virtual;
    procedure Exchange(ListIndex1,ListIndex2: TListIndex); virtual;   

    procedure Clear; virtual;
    procedure Reverse; virtual;
    procedure Sort(Reversed: Boolean = False); virtual;

    procedure Defragment; virtual;
    Function ArrayItemIsUsed(ArrayIndex: TArrayIndex): Boolean; virtual;

    //Function IsEqual(List: TLinkedListArray): Boolean; virtual;
    //procedure Assign(List: TLinkedListArray); virtual;
    //procedure Append(List: TLinkedListArray); virtual;
    //procedure SaveToStream(Stream: TStream; Buffered: Boolean = False); virtual;
    //procedure LoadFromStream(Stream: TStream; Buffered: Boolean = False); virtual;
    //procedure SaveToFile(const FileName: String; Buffered: Boolean = False); virtual;
    //procedure LoadFromFile(const FileName: String; Buffered: Boolean = False); virtual;

    property PayloadSize: TMemSize read fPayloadSize;
    property ArrayPointers[ArrayIndex: TArrayIndex]: PLinkedListArrayPayload read GetPayloadPtr;
    property ListPointers[ListIndex: TListIndex]: PLinkedListArrayPayload read GetPayloadPtrListIndex;
    property OnChange: TNotifyEvent read fOnChangeEvent write fOnChangeEvent;
    property OnChangeEvent: TNotifyEvent read fOnChangeEvent write fOnChangeEvent;
    property OnChangeCallback: TNotifyCallback read fOnChangeCallback write fOnChangeCallback;
  end;

  TIntegerLinkedListArray = class(TLinkedListArray)
  protected
    Function GetItem(ListIndex: TListIndex): Integer; virtual;
    procedure SetItem(ListIndex: TListIndex; Value: Integer); virtual;
    Function PayloadCompare(Payload1,Payload2: PLinkedListArrayPayload): Integer; override;
  public
    constructor Create;
    Function First: Integer; reintroduce;
    Function Last: Integer; reintroduce;
    Function IndicesOf(Item: Integer; out ArrayIndex: TArrayIndex; out ListIndex: TListIndex): Boolean; reintroduce;
    Function ArrayIndexOf(Item: Integer): TArrayIndex; reintroduce;
    Function ListIndexOf(Item: Integer): TListIndex; reintroduce;
    Function Add(Item: Integer): Integer; reintroduce;
    procedure Insert(ListIndex: TListIndex; Item: Integer); reintroduce;
    Function Extract(Item: Integer): Integer; reintroduce;
    Function Remove(Item: Integer): Integer; reintroduce;
    property Items[ListIndex: TListIndex]: Integer read GetItem write SetItem; default;
  end;

implementation

uses
  SysUtils, Math,
  IndexSorters;

const
  LLA_FLAG_USED = $00000001;

//==============================================================================

Function TLinkedListArray.PayloadPtrFromItemPtr(ItemPtr: PLinkedListArrayItem): PLinkedListArrayPayload;
begin
Result := Pointer(PtrUInt(ItemPtr) + fPayloadOffset);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.ItemPtrFromPayloadPtr(PayloadPtr: PLinkedListArrayPayload): PLinkedListArrayItem;
begin
Result := PLinkedListArrayItem(PtrUInt(PayloadPtr) - fPayloadOffset);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.GetItemPtr(ArrayIndex: TArrayIndex): PLinkedListArrayItem;
begin
Result := nil;
If CheckArrayIndexAndRaise(ArrayIndex,'GetItemPtr') then
  Result := PLinkedListArrayItem(PtrUInt(fMemory) + (PtrUInt(ArrayIndex) * (PtrUInt(fItemSize))));
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.GetPayloadPtr(ArrayIndex: TArrayIndex): PLinkedListArrayPayload;
begin
Result := PayloadPtrFromItemPtr(GetItemPtr(ArrayIndex));
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.SetPayloadPtr(ArrayIndex: TArrayIndex; Value: PLinkedListArrayPayload);
var
  PayloadPtr: PLinkedListArrayPayload;
begin
PayloadPtr := GetPayloadPtr(ArrayIndex);
System.Move(PayloadPtr^,fTempPayload^,fPayloadSize);
System.Move(Value^,PayloadPtr^,fPayloadSize);
If not PayloadEquals(fTempPayload,Value) then
  DoChange;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.GetPayloadPtrListIndex(ListIndex: TListIndex): PLinkedListArrayPayload;
begin
Result := nil;
If CheckListIndexAndRaise(ListIndex,'GetPayloadPtrListIndex') then
  Result := GetPayloadPtr(ArrayIndex(ListIndex));
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.SetPayloadPtrListIndex(ListIndex: TListIndex; Value: PLinkedListArrayPayload);
begin
If CheckListIndexAndRaise(ListIndex,'SetPayloadPtrListIndex') then
  SetPayloadPtr(ArrayIndex(ListIndex),Value);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.GetCapacity: Integer;
begin
Result := fCapacity;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.SetCapacity(Value: Integer);
var
  i:        TArrayIndex;
  OldCap:   Integer;
  ItemPtr:  PLinkedListArrayItem;
begin
If (Value <> fCapacity) and (Value >= 0) then
  begin
    If Value > fCapacity then
      begin
        // add new free items
        OldCap := fCapacity;
        ReallocMem(fMemory,TMemSize(Value) * TMemSize(fItemSize));
        fCapacity := Value;
        For i := TArrayIndex(OldCap) to HighArrayIndex do
          begin
            ItemPtr := GetItemPtr(i);
            If i = TArrayIndex(OldCap) then ItemPtr^.Prev := -1
              else ItemPtr^.Prev := i - 1;
            If i = HighArrayIndex then ItemPtr^.Next := -1
              else ItemPtr^.Next := i + 1;
            ItemPtr^.Flags := 0;
          end;
        If not CheckArrayIndex(fFirstFree) then
          fFirstFree := OldCap;
        If CheckArrayIndex(fLastFree) then
          begin
            GetItemPtr(fLastFree)^.Next := OldCap;
            GetItemPtr(OldCap)^.Prev := fLastFree;
          end;
        fLastFree := HighArrayIndex;
      end
    else
      begin
        Defragment;
        // remove existing items
        If Value < fCount then
          begin
            // some used items will be removed
            For i := HighArrayIndex downto TArrayIndex(Value) do
              If (GetItemPtr(i)^.Flags and LLA_FLAG_USED) <> 0 then
                PayloadFinal(GetPayloadPtr(i));
            ReallocMem(fMemory,TMemSize(Value) * TMemSize(fItemSize));
            fCapacity := Value;
            fCount := Value;
            GetItemPtr(HighArrayIndex)^.Next := -1;
            // there is no free item anymore
            fFirstFree := -1;
            fLastFree := -1;
            fLastUsed := HighArrayIndex;
            DoChange;
          end
        else
          begin
            // no used item is removed
            ReallocMem(fMemory,TMemSize(Value) * TMemSize(fItemSize));
            fCapacity := Value;
            GetItemPtr(HighArrayIndex)^.Next := -1;
            If fCount = fCapacity then
              begin
                fFirstFree := -1;
                fLastFree := -1;
                fLastUsed := HighArrayIndex;
              end
            else fLastFree := HighArrayIndex;
          end;
      end;
  end;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.GetCount: Integer;
begin
Result := fCount;
end;
 
//------------------------------------------------------------------------------

procedure TLinkedListArray.SetCount(Value: Integer);
begin
Exit;
{$message 'implement'}
If (Value <> fCount) and (Value >= 0) then
  begin
    If Value > fCount then
      begin
        // new items will be added
        If Value > fCapacity then
          SetCapacity(Value);

      end
    else
      begin
        // items will be removed
      end;
  end;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.CheckArrayIndex(ArrayIndex: TArrayIndex): Boolean;
begin
Result := (ArrayIndex >= LowArrayIndex) and (ArrayIndex <= HighArrayIndex);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.CheckListIndex(ListIndex: TListIndex): Boolean;
begin
Result := (ListIndex >= LowListIndex) and (ListIndex <= HighListIndex);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.CheckArrayIndexAndRaise(ArrayIndex: TArrayIndex; CallingMethod: String = 'CheckArrayIndexAndRaise'): Boolean;
begin
Result := CheckArrayIndex(ArrayIndex);
If not Result then
  RaiseError('%s: Array index (%d) out of bounds.',[CallingMethod,ArrayIndex]);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.CheckListIndexAndRaise(ListIndex: TListIndex; CallingMethod: String = 'CheckListIndexAndRaise'): Boolean;
begin
Result := CheckListIndex(ListIndex);
If not Result then
  RaiseError('%s: List index (%d) out of bounds.',[CallingMethod,ListIndex]);
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.RaiseError(const ErrorMessage: String; Values: array of const);
begin
raise Exception.CreateFmt(Format('%s.%s',[Self.ClassName,ErrorMessage]),Values);
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.RaiseError(const ErrorMessage: String);
begin
RaiseError(ErrorMessage,[]);
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.PayloadInit(Payload: PLinkedListArrayPayload);
begin
FillChar(Payload^,fPayloadSize,0);
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.PayloadFinal(Payload: PLinkedListArrayPayload);
begin
// nothing to do here
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.PayloadCopy(SrcPayload,DstPayload: PLinkedListArrayPayload);
begin
System.Move(SrcPayload^,DstPayload^,fPayloadSize);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.PayloadCompare(Payload1,Payload2: PLinkedListArrayPayload): Integer;
begin
Result := Integer(PtrUInt(Payload2) - PtrUInt(Payload1));
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.PayloadEquals(Payload1,Payload2: PLinkedListArrayPayload): Boolean;
begin
Result := PayloadCompare(Payload1,Payload2) = 0;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.DoChange;
begin
fChanged := True;
If (fChangeCounter <= 0) then
  begin
    If Assigned(fOnChangeEvent) then fOnChangeEvent(Self);
    If Assigned(fOnChangeCallback) then fOnChangeCallback(Self);
  end;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.FinalizeAllItems;
var
  i:        TArrayIndex;
  ItemPtr:  PLinkedListArrayItem;
begin
If fCount > 0 then
  For i := LowArrayIndex to HighArrayIndex do
    begin
      ItemPtr := GetItemPtr(i);
      If (ItemPtr^.Flags and LLA_FLAG_USED) <> 0 then
        PayloadFinal(PayloadPtrFromItemPtr(ItemPtr));
    end;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.Decouple(ArrayIndex: TArrayIndex);
var
  ItemPtr:  PLinkedListArrayItem;
begin
If CheckArrayIndexAndRaise(ArrayIndex,'Decouple') then
  begin
    ItemPtr := GetItemPtr(ArrayIndex);
    If CheckArrayIndex(ItemPtr^.Prev) then
      GetItemPtr(ItemPtr^.Prev)^.Next := ItemPtr^.Next;
    If CheckArrayIndex(ItemPtr^.Next) then
      GetItemPtr(ItemPtr^.Next)^.Prev := ItemPtr^.Prev;
    If ArrayIndex = fFirstFree then
      fFirstFree := ItemPtr^.Next;
    If ArrayIndex = fLastFree then
      fLastFree := ItemPtr^.Prev;      
    If ArrayIndex = fFirstUsed then
      fFirstUsed := ItemPtr^.Next;
    If ArrayIndex = fLastUsed then
      fLastUsed := ItemPtr^.Prev; 
    ItemPtr^.Prev := -1;
    ItemPtr^.Next := -1;
  end;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.ArrayIndices(ListIndex1,ListIndex2: TListIndex; out ArrayIndex1,ArrayIndex2: TArrayIndex);
var
  TempArrayIndex: TArrayIndex;
  TempListIndex:  TListIndex;
begin
ArrayIndex1 := -1;
ArrayIndex2 := -1;
If not CheckListIndex(ListIndex1) then
  ArrayIndex2 := ArrayIndex(ListIndex2)
else If not CheckListIndex(ListIndex2) then
  ArrayIndex1 := ArrayIndex(ListIndex1)
else
  begin
    // both list indices are valid
    TempArrayIndex := fFirstUsed;
    TempListIndex := LowListIndex;
    while CheckArrayIndex(TempArrayIndex) and
     (TempListIndex <= Max(ListIndex1,ListIndex2)) do
      begin
        If TempListIndex = ListIndex1 then
          ArrayIndex1 := TempArrayIndex;
        If TempListIndex = ListIndex2 then
          ArrayIndex2 := TempArrayIndex;
        TempArrayIndex := GetItemPtr(TempArrayIndex)^.Next;
        Inc(TempListIndex);
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.InternalDelete(ArrayIndex: TArrayIndex);
var
  ItemPtr:  PLinkedListArrayItem;
begin
If CheckArrayIndexAndRaise(ArrayIndex,'InternalDelete') then
  begin
    ItemPtr := GetItemPtr(ArrayIndex);
    If (ItemPtr^.Flags and LLA_FLAG_USED) <> 0 then
      begin
        // remove from list of used items
        Decouple(ArrayIndex);
        // add to list of free items
        ItemPtr^.Prev := fLastFree;
        ItemPtr^.Next := -1;
        If CheckArrayIndex(fLastFree) then
          GetItemPtr(fLastFree).Next := ArrayIndex;
        If not CheckArrayIndex(fFirstFree) then
          fFirstFree := ArrayIndex;
        fLastFree := ArrayIndex;
        // finalize item and set flags
        PayloadFinal(PayloadPtrFromItemPtr(ItemPtr));
        ItemPtr^.Flags := ItemPtr^.Flags and not LLA_FLAG_USED;
        Dec(fCount);
        Shrink;
        DoChange;
      end;
  end;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.SortCompare(ListIndex1,ListIndex2: Integer): Integer;
begin
Result := PayloadCompare(GetPayloadPtrListIndex(TListIndex(ListIndex1)),
                         GetPayloadPtrListIndex(TListIndex(ListIndex2)));
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.DefragCompare(Index1,Index2: Integer): Integer;
begin
Result := Integer(GetItemPtr(TArrayIndex(Index2))^.Prev - GetItemPtr(TArrayIndex(Index1))^.Prev); 
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.DefragExchange(Index1,Index2: Integer);
var
  Item1Ptr,Item2Ptr:  PLinkedListArrayItem;
  Temp:               Integer; 
begin
If Index1 <> Index2 then
  begin
    Item1Ptr := GetItemPtr(Index1);
    Item2Ptr := GetItemPtr(Index2);
    // exchange indices
    Temp := Item1Ptr^.Prev;
    Item1Ptr^.Prev := Item2Ptr^.Prev;
    Item2Ptr^.Prev := Temp;
    // exchange flags
    Temp := Item1Ptr^.Flags;
    Item1Ptr^.Flags := Item2Ptr^.Flags;
    Item2Ptr^.Flags := Temp;
    // exchange data
    System.Move(PayloadPtrFromItemPtr(Item1Ptr)^,fTempPayload^,fPayloadSize);
    System.Move(PayloadPtrFromItemPtr(Item2Ptr)^,PayloadPtrFromItemPtr(Item1Ptr)^,fPayloadSize);
    System.Move(fTempPayload^,PayloadPtrFromItemPtr(Item2Ptr)^,fPayloadSize);
  end;
end;

//==============================================================================

constructor TLinkedListArray.Create(PayloadSize: TMemSize);
begin
inherited Create;
fPayloadSize := PayloadSize;
fPayloadOffset := PtrUInt(Addr(PLinkedListArrayItem(nil)^.Payload));
fItemSize := fPayloadOffset + PayloadSize;  // add padding?
fMemory := nil;
fCapacity := 0;
fCount := 0;
fChangeCounter := 0;
fChanged := False;
fOnChangeEvent := nil;
fOnChangeCallback := nil;
GetMem(fTempPayload,fPayloadSize);
fFirstFree := -1;
fLastFree := -1;
fFirstUsed := -1;
fLastUsed := -1;
end;

//------------------------------------------------------------------------------

destructor TLinkedListArray.Destroy;
begin
FinalizeAllItems;
FreeMem(fTempPayload,fPayloadSize);
FreeMem(fMemory,TMemSize(fCapacity) * TMemSize(fItemSize));
inherited;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.CheckIndex(Index: Integer): Boolean;
begin
Result := CheckListIndex(TListIndex(Index));
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.BeginChanging;
begin
If fChangeCounter <= 0 then
  fChanged := False;
Inc(fChangeCounter);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.EndChanging: Integer;
begin
Dec(fChangeCounter);
If fChangeCounter <= 0 then
  begin
    fChangeCounter := 0;
    If fChanged then
      DoChange;
    fChanged := False;
  end;
Result := fChangeCounter;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.LowIndex: Integer;
begin
Result := LowListIndex;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.HighIndex: Integer;
begin
Result := HighListIndex;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.LowArrayIndex: TArrayIndex;
begin
Result := 0;
end;

//------------------------------------------------------------------------------


Function TLinkedListArray.HighArrayIndex: TArrayIndex;
begin
Result := Pred(fCapacity);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.LowListIndex: TListIndex;
begin
Result := 0;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.HighListIndex: TListIndex;
begin
Result := Pred(fCount);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.PreviousByArray(ArrayIndex: TArrayIndex): TArrayIndex;
var
  ItemPtr:  PLinkedListArrayItem;
begin
Result := -1;
If CheckArrayIndex(ArrayIndex) then
  begin
    ItemPtr := GetItemPtr(Result);
    If (ItemPtr^.Flags and LLA_FLAG_USED) <> 0 then
      Result := ItemPtr^.Prev;
  end;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.NextByArray(ArrayIndex: TArrayIndex): TArrayIndex;
var
  ItemPtr:  PLinkedListArrayItem;
begin
Result := -1;
If CheckArrayIndex(ArrayIndex) then
  begin
    ItemPtr := GetItemPtr(Result);
    If (ItemPtr^.Flags and LLA_FLAG_USED) <> 0 then
      Result := ItemPtr^.Next;
  end;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.PreviousByList(ListIndex: TListIndex): TArrayIndex;
begin
Result := ArrayIndex(ListIndex);
If CheckArrayIndex(Result) then
  Result := GetItemPtr(Result)^.Prev
else
  Result := -1;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.NextByList(ListIndex: TListIndex): TArrayIndex;
begin
Result := ArrayIndex(ListIndex);
If CheckArrayIndex(Result) then
  Result := GetItemPtr(Result)^.Next
else
  Result := -1;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.FirstArrayIndex: Integer;
begin
Result := fFirstUsed;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.LastArrayIndex: Integer;
begin
Result := fLastUsed;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.First: PLinkedListArrayPayload;
begin
Result := GetPayloadPtr(fFirstUsed);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.Last: PLinkedListArrayPayload;
begin
Result := GetPayloadPtr(fLastUsed);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.ArrayIndex(ListIndex: TListIndex): TArrayIndex;
begin
If CheckListIndex(ListIndex) then
  begin
    Result := fFirstUsed;
    while CheckArrayIndex(Result) and (ListIndex > 0) do
      begin
        Result := GetItemPtr(Result)^.Next;
        Dec(ListIndex);
      end;
  end
else Result := -1;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.ListIndex(ArrayIndex: TArrayIndex): TListIndex;
var
  TempIndex:  TArrayIndex;
begin
If CheckArrayIndex(ArrayIndex) then
  begin
    If (GetItemPtr(ArrayIndex)^.Flags and LLA_FLAG_USED) <> 0 then
      begin
        Result := LowListIndex;
        TempIndex := fFirstUsed;
        while CheckArrayIndex(TempIndex) and (TempIndex <> ArrayIndex) do
          begin
            TempIndex := GetItemPtr(TempIndex)^.Next;
            Inc(Result);
          end;
        If TempIndex <> ArrayIndex then
          Result := -1;
      end
    else Result := -1;
  end
else Result := -1;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.IndicesOf(Item: Pointer; out ArrayIndex: TArrayIndex; out ListIndex: TListIndex): Boolean;
begin
Result := False;
// traverse list of used items
ArrayIndex := fFirstUsed;
ListIndex := LowListIndex;
while CheckArrayIndex(ArrayIndex) do
  begin
    If PayloadEquals(Item,GetPayloadPtr(ArrayIndex)) then
      begin
        Result := True;
        Break{while...};
      end
    else ArrayIndex := GetItemPtr(ArrayIndex)^.Next;
    Inc(ListIndex);
  end;
If not Result then
  begin
    ListIndex := -1;
    ArrayIndex := -1;
  end;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.ArrayIndexOf(Item: Pointer): TArrayIndex;
var
  ListIndex:  TListIndex;
begin
IndicesOf(Item,Result,ListIndex);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.ListIndexOf(Item: Pointer): TListIndex;
var
  ArrayIndex: TArrayIndex;
begin
IndicesOf(Item,ArrayIndex,Result);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.Add(Item: Pointer): TListIndex;
var
  ArrayIndex: TArrayIndex;
  ItemPtr:    PLinkedListArrayItem;
begin
Grow;
// at this point, there MUST be at least one free item
ArrayIndex := fFirstFree;
ItemPtr := GetItemPtr(ArrayIndex);
// remove from list of free items
Decouple(ArrayIndex);
// add to list of used items
If not CheckArrayIndex(fFirstUsed) then
  fFirstUsed := ArrayIndex;
If CheckArrayIndex(fLastUsed) then
  GetItemPtr(fLastUsed)^.Next := ArrayIndex;
ItemPtr^.Prev := fLastUsed;
ItemPtr^.Next := -1;
fLastUsed := ArrayIndex;
// add the data and set flags
System.Move(Item^,ItemPtr^.Payload,fPayloadSize);
ItemPtr^.Flags := ItemPtr^.Flags or LLA_FLAG_USED;
Result := fCount;
Inc(fCount);
DoChange;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.Insert(ListIndex: TListIndex; Item: Pointer);
var
  NewItemArrayIndex:  Integer;
  OldItemArrayIndex:  Integer;
  NewItemPtr:         PLinkedListArrayItem;
  OldItemPtr:         PLinkedListArrayItem;
begin
If CheckListIndex(ListIndex) then
  begin
    OldItemArrayIndex := ArrayIndex(ListIndex);
    If CheckArrayIndex(OldItemArrayIndex) then
      begin
        Grow;
        NewItemArrayIndex := fFirstFree;
        NewItemPtr := GetItemPtr(NewItemArrayIndex);
        OldItemPtr := GetItemPtr(OldItemArrayIndex);
        Decouple(NewItemArrayIndex);
        // insert to the list of used items
        NewItemPtr^.Prev := OldItemPtr^.Prev;
        NewItemPtr^.Next := OldItemArrayIndex;
        If CheckArrayIndex(OldItemPtr^.Prev) then
          GetItemPtr(OldItemPtr^.Prev)^.Next := NewItemArrayIndex;
        OldItemPtr^.Prev := NewItemArrayIndex;
        If fFirstUsed = OldItemArrayIndex then
          fFirstUsed := NewItemArrayIndex;
        // add the data and set flags
        System.Move(Item^,NewItemPtr^.Payload,fPayloadSize);
        NewItemPtr^.Flags := NewItemPtr^.Flags or LLA_FLAG_USED;
        Inc(fCount);
        DoChange;
      end;
  end
else Add(Item);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.Extract(Item: Pointer): Pointer;
var
  ArrayIndex: TArrayIndex;
  ItemPtr:    PLinkedListArrayItem;
begin
Result := nil;
ArrayIndex := ArrayIndexOf(Item);
If CheckArrayIndex(ArrayIndex) then
  begin
    ItemPtr := GetItemPtr(ArrayIndex);  
    Decouple(ArrayIndex);
    // add to list of free items
    ItemPtr^.Prev := fLastFree;
    ItemPtr^.Next := -1;
    If CheckArrayIndex(fLastFree) then
      GetItemPtr(fLastFree).Next := ArrayIndex;
    If not CheckArrayIndex(fFirstFree) then
      fFirstFree := ArrayIndex;
    fLastFree := ArrayIndex;
    // reset flag and return the item
    ItemPtr^.Flags := ItemPtr^.Flags and not LLA_FLAG_USED;
    Result := PayloadPtrFromItemPtr(ItemPtr);
    Dec(fCount);
    DoChange;
  end;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.Remove(Item: Pointer): TListIndex;
var
  ArrayIndex: TArrayIndex;
begin
IndicesOf(Item,ArrayIndex,Result);
If CheckListIndex(Result) then
  InternalDelete(ArrayIndex);
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.Delete(ListIndex: TListIndex);
begin
If CheckListIndexAndRaise(ListIndex,'Delete') then
  InternalDelete(ArrayIndex(ListIndex));
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.Move(SrcListIndex,DstListIndex: TListIndex);
var
  SrcArrayIndex,DstArrayIndex:  TArrayIndex;
  SrcItemPtr,DstItemPtr:        PLinkedListArrayItem;
begin
If SrcListIndex <> DstListIndex then
  begin
    CheckListIndexAndRaise(SrcListIndex,'Move');
    CheckListIndexAndRaise(DstListIndex,'Move');
    // get pointers
    ArrayIndices(SrcListIndex,DstListIndex,SrcArrayIndex,DstArrayIndex);
    SrcItemPtr := GetItemPtr(SrcArrayIndex);
    DstItemPtr := GetItemPtr(DstArrayIndex);
    // remove moved item from old position
    Decouple(SrcArrayIndex);
    // insert to new position
    If DstListIndex > SrcListIndex then
      begin
        // item is moved up
        SrcItemPtr^.Prev := DstArrayIndex;
        SrcItemPtr^.Next := DstItemPtr^.Next;
        If CheckArrayIndex(DstItemPtr^.Next) then
          GetItemPtr(DstItemPtr^.Next)^.Prev := SrcArrayIndex;
        DstItemPtr^.Next := SrcArrayIndex;
        If fLastUsed = DstArrayIndex then
          fLastUsed := SrcArrayIndex
      end
    else
      begin
        // item is moved down
        SrcItemPtr^.Prev := DstItemPtr^.Prev;
        SrcItemPtr^.Next := DstArrayIndex;
        If CheckArrayIndex(DstItemPtr^.Prev) then
          GetItemPtr(DstItemPtr^.Prev)^.Next := SrcArrayIndex;
        DstItemPtr^.Prev := SrcArrayIndex;
        If fFirstUsed = DstArrayIndex then
          fFirstUsed := SrcArrayIndex;        
      end;
    DoChange;
  end;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.Exchange(ListIndex1,ListIndex2: TListIndex);
var
  TempListIndex:            TListIndex;
  ArrayIndex1,ArrayIndex2:  TArrayIndex;
  ItemPtr1,ItemPtr2:        PLinkedListArrayItem;
  TempIndex1,TempIndex2:    TArrayIndex;
begin
If ListIndex1 <> ListIndex2 then
  begin
    CheckListIndexAndRaise(ListIndex1,'Exchange');
    CheckListIndexAndRaise(ListIndex2,'Exchange');
    If ListIndex2 < ListIndex1 then
      begin
        TempListIndex := ListIndex1;
        ListIndex1 := ListIndex2;
        ListIndex2 := TempListIndex;
      end;
    // get pointers to items (indices are checked in GetItemPtr)
    ArrayIndices(ListIndex1,ListIndex2,ArrayIndex1,ArrayIndex2);
    ItemPtr1 := GetItemPtr(ArrayIndex1);
    ItemPtr2 := GetItemPtr(ArrayIndex2);
    // corrections when items are on any of the list ends
    If ArrayIndex1 = fFirstUsed then
      fFirstUsed := ArrayIndex2
    else If ArrayIndex2 = fFirstUsed then
      fFirstUsed := ArrayIndex1;
    If ArrayIndex1 = fLastUsed then
      fLastUsed := ArrayIndex2
    else If ArrayIndex2 = fLastUsed then
      fLastUsed := ArrayIndex1;
    // do exchange only by swapping indices
    If Abs(ListIndex1 - ListIndex2) > 1 then
      begin
        If CheckArrayIndex(ItemPtr1^.Prev) then
          GetItemPtr(ItemPtr1^.Prev)^.Next := ArrayIndex2;
        If CheckArrayIndex(ItemPtr1^.Next) then
          GetItemPtr(ItemPtr1^.Next)^.Prev := ArrayIndex2;
        If CheckArrayIndex(ItemPtr2^.Prev) then
          GetItemPtr(ItemPtr2^.Prev)^.Next := ArrayIndex1;
        If CheckArrayIndex(ItemPtr2^.Next) then
          GetItemPtr(ItemPtr2^.Next)^.Prev := ArrayIndex1;
        TempIndex1 := ItemPtr1^.Prev;
        TempIndex2 := ItemPtr1^.Next;
        ItemPtr1^.Prev := ItemPtr2^.Prev;
        ItemPtr1^.Next := ItemPtr2^.Next;
        ItemPtr2^.Prev := TempIndex1;
        ItemPtr2^.Next := TempIndex2;
      end
    else
      begin
        If CheckArrayIndex(ItemPtr1^.Prev) then
          GetItemPtr(ItemPtr1^.Prev)^.Next := ArrayIndex2;
        If CheckArrayIndex(ItemPtr2^.Next) then
          GetItemPtr(ItemPtr2^.Next)^.Prev := ArrayIndex1;
        TempIndex1 := ItemPtr1^.Prev;
        TempIndex2 := ItemPtr2^.Next;
        ItemPtr1^.Prev := ItemPtr1^.Next;
        ItemPtr1^.Next := TempIndex2;
        ItemPtr2^.Next := ItemPtr2^.Prev;
        ItemPtr2^.Prev := TempIndex1;
      end;
    DoChange;
  end;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.Clear;
var
  i:  TArrayIndex;
begin
If fCapacity > 0 then
  begin
    FinalizeAllItems;
    For i := LowArrayIndex to HighArrayIndex do
      with GetItemPtr(i)^ do
        begin
          If i > LowArrayIndex then Prev := i - 1
            else Prev := -1;
          If i < HighArrayIndex then Next := i + 1
            else Next := -1;
          Flags := 0;
        end;
    fCount := 0;
    fFirstFree := LowArrayIndex;
    fLastFree := HighArrayIndex;
    fFirstUsed := -1;
    fLastUsed := -1;
    DoChange;
  end;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.Reverse;
var
  TempIndex:  TArrayIndex;
begin
If fCount > 1 then
  begin
    TempIndex := fFirstUsed;
    fFirstUsed := fLastUsed;
    fLastUsed := TempIndex;
    while CheckArrayIndex(TempIndex) do
      with GetItemPtr(TempIndex)^ do
        begin
          TempIndex := Next;
          Next := Prev;
          Prev := TempIndex;
        end;
    DoChange;
  end;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.Sort(Reversed: Boolean = False);
var
  Sorter: TIndexSorter;
begin
If fCount > 1 then
  begin
    BeginChanging;
    try
      Sorter := TIndexQuickSorter.Create(SortCompare,Exchange);
      try
        Sorter.Reversed := Reversed;
        Sorter.Sort(LowListIndex,HighListIndex);
      finally
        Sorter.Free;
      end;
    finally
      EndChanging;
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.Defragment;
var
  ArrayIndex: TArrayIndex;
  ListIndex:  TListIndex;
  ItemIndex:  TArrayIndex;
  ArrayPtr:   PLinkedListArrayItem;
  ItemPtr:    PLinkedListArrayItem;
  i:          TArrayIndex;
begin
If fCount > 0 then
  begin
    // set prev to list index and next to -1
    ArrayIndex := fFirstUsed;
    ListIndex := 0;
    while CheckArrayIndex(ArrayIndex) do
      begin
        ArrayPtr := GetItemPtr(ArrayIndex);
        ArrayIndex := ArrayPtr^.Next;
        ArrayPtr^.Prev := ListIndex;
        ArrayPtr^.Next := -1;
        Inc(ListIndex);
      end;
    // compress items
    If fCount <> fCapacity then
      begin
        ArrayIndex := LowArrayIndex;
        ItemIndex := HighArrayIndex;
        repeat
          while CheckArrayIndex(ArrayIndex) do
            If (GetItemPtr(ArrayIndex)^.Flags and LLA_FLAG_USED) <> 0 then
              Inc(ArrayIndex)
            else
              Break{while};
          while CheckArrayIndex(ItemIndex) do
            If (GetItemPtr(ItemIndex)^.Flags and LLA_FLAG_USED) = 0 then
              Dec(ItemIndex)
            else
              Break{while};
          If CheckArrayIndex(ArrayIndex) and CheckArrayIndex(ItemIndex) and (ArrayIndex < ItemIndex) then
            begin
              ArrayPtr := GetItemPtr(ArrayIndex);
              ItemPtr := GetItemPtr(ItemIndex);
              System.Move(ItemPtr^.Payload,ArrayPtr^.Payload,fPayloadSize);
              ArrayPtr^.Flags := ItemPtr^.Flags;
              ItemPtr^.Flags := 0;
              ArrayPtr^.Prev := ItemPtr^.Prev;
              ItemPtr^.Prev := -1;
              Inc(ArrayIndex);
              Dec(ItemIndex);
            end
           else Break{Repeat};
        until not CheckArrayIndex(ArrayIndex) or not CheckArrayIndex(ItemIndex);
      end;
    // sort items
    with TIndexQuickSorter.Create(DefragCompare,DefragExchange) do
    try
      Sort(LowArrayIndex,HighListIndex);
    finally
      Free;
    end;
    // reinitialize all indices (first for used, then for free items)
    For i := LowArrayIndex to TArrayIndex(HighListIndex) do
      with GetItemPtr(i)^ do
        begin
          If i > LowArrayIndex then Prev := i - 1
            else Prev := -1;
          If i < TArrayIndex(HighListIndex) then Next := i + 1
            else Next := -1;
        end;
    For i := TArrayIndex(Succ(HighListIndex)) to HighArrayIndex do
      with GetItemPtr(i)^ do
        begin
          If i > TArrayIndex(Succ(HighListIndex)) then Prev := i - 1
            else Prev := -1;
          If i < HighArrayIndex then Next := i + 1
            else Next := -1;
        end;
    If fCount <> fCapacity then
      begin
        fFirstFree := TArrayIndex(Succ(HighListIndex));
        fLastFree := HighArrayIndex;
      end;
    fFirstUsed := LowArrayIndex;
    fLastUsed := TArrayIndex(HighListIndex);
    DoChange;
  end
else Clear; // this will reinitialize the empty space
end;
 
//------------------------------------------------------------------------------

Function TLinkedListArray.ArrayItemIsUsed(ArrayIndex: TArrayIndex): Boolean;
begin
Result := False;
If CheckArrayIndexAndRaise(ArrayIndex,'ArrayItemIsUsed') then
  Result := (GetItemPtr(ArrayIndex)^.Flags and LLA_FLAG_USED) <> 0;
end;

//******************************************************************************
//******************************************************************************
//******************************************************************************

Function TIntegerLinkedListArray.GetItem(ListIndex: TListIndex): Integer;
begin
Result := Integer(Pointer(GetPayloadPtrListIndex(ListIndex))^);
end;

//------------------------------------------------------------------------------

procedure TIntegerLinkedListArray.SetItem(ListIndex: TListIndex; Value: Integer);
begin
SetPayloadPtrListIndex(ListIndex,PLinkedListArrayPayload(@Value));
end;

//------------------------------------------------------------------------------

Function TIntegerLinkedListArray.PayloadCompare(Payload1,Payload2: PLinkedListArrayPayload): Integer;
begin
Result := Integer(Pointer(Payload2)^) - Integer(Pointer(Payload1)^);
end;

//==============================================================================

constructor TIntegerLinkedListArray.Create;
begin
inherited Create(SizeOf(Integer));
end;

//------------------------------------------------------------------------------

Function TIntegerLinkedListArray.First: Integer;
begin
Result := Integer(Pointer(inherited First)^);
end;

//------------------------------------------------------------------------------

Function TIntegerLinkedListArray.Last: Integer;
begin
Result := Integer(Pointer(inherited Last)^);
end;

//------------------------------------------------------------------------------

Function TIntegerLinkedListArray.IndicesOf(Item: Integer; out ArrayIndex: TArrayIndex; out ListIndex: TListIndex): Boolean;
begin
Result := inherited IndicesOf(PLinkedListArrayPayload(@Item),ArrayIndex,ListIndex);
end;

//------------------------------------------------------------------------------

Function TIntegerLinkedListArray.ArrayIndexOf(Item: Integer): TArrayIndex;
begin
Result := inherited ArrayIndexOf(PLinkedListArrayPayload(@Item));
end;

//------------------------------------------------------------------------------

Function TIntegerLinkedListArray.ListIndexOf(Item: Integer): TListIndex;
begin
Result := inherited ListIndexOf(PLinkedListArrayPayload(@Item));
end;

//------------------------------------------------------------------------------

Function TIntegerLinkedListArray.Add(Item: Integer): Integer;
begin
Result := inherited Add(PLinkedListArrayPayload(@Item));
end;

//------------------------------------------------------------------------------

procedure TIntegerLinkedListArray.Insert(ListIndex: TListIndex; Item: Integer);
begin
inherited Insert(ListIndex,PLinkedListArrayPayload(@Item));
end;

//------------------------------------------------------------------------------

Function TIntegerLinkedListArray.Extract(Item: Integer): Integer;
begin
Result := Integer(Pointer(inherited Extract(PLinkedListArrayPayload(@Item)))^);
end;

//------------------------------------------------------------------------------

Function TIntegerLinkedListArray.Remove(Item: Integer): Integer;
begin
Result := inherited Remove(PLinkedListArrayPayload(@Item));
end;


end.
