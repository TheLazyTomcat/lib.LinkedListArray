unit LinkedListArray;

interface

uses
  AuxTypes, AuxClasses;

type
  TListIndex =  Integer;
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
    fFirstEmpty:        TArrayIndex;
    fLastEmpty:         TArrayIndex;
    fFirstFull:         TArrayIndex;
    fLastFull:          TArrayIndex;
    Function PayloadPtrFromItemPtr(ItemPtr: PLinkedListArrayItem): PLinkedListArrayPayload; virtual;
    Function ItemPtrFromPayloadPtr(PayloadPtr: PLinkedListArrayPayload): PLinkedListArrayItem; virtual;

    Function GetItemPtr(ArrayIndex: TArrayIndex): PLinkedListArrayItem; virtual;
    Function GetPayloadPtr(ArrayIndex: TArrayIndex): PLinkedListArrayPayload; virtual;
    procedure SetPayloadPtr(ArrayIndex: TArrayIndex; Value: PLinkedListArrayPayload); virtual;
    Function GetPayloadPtrListIndex(ListIndex: TListIndex): PLinkedListArrayPayload; virtual;

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

    procedure PayloadInit(Payload: PLinkedListArrayPayload); virtual;
    procedure PayloadFinal(Payload: PLinkedListArrayPayload); virtual;
    procedure PayloadCopy(SrcPayload,DstPayload: PLinkedListArrayPayload); virtual;
    Function PayloadCompare(Payload1,Payload2: PLinkedListArrayPayload): Integer; virtual;
    Function PayloadEquals(Payload1,Payload2: PLinkedListArrayPayload): Boolean; virtual;

    procedure DoChange; virtual;    
    procedure FinalizeAllItems; virtual;
    procedure Decouple(ArrayIndex: TArrayIndex); virtual;
    procedure ArrayIndices(ListIndex1,ListIndex2: TListIndex; out ArrayIndex1,ArrayIndex2: TArrayIndex); virtual;
    procedure InternalDelete(ArrayIndex: TArrayIndex); virtual;
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
    Function First: Pointer; virtual;
    Function Last: Pointer; virtual;

    Function CheckIndex(Index: Integer): Boolean; override;    
    Function ArrayIndex(ListIndex: TListIndex): TArrayIndex; virtual;
    Function ListIndex(ArrayIndex: TArrayIndex): TListIndex; virtual;

    Function IndicesOf(Item: Pointer; out ListIndex: TListIndex; out ArrayIndex: TArrayIndex): Boolean; virtual;
    Function ArrayIndexOf(Item: Pointer): TArrayIndex; virtual;
    Function ListIndexOf(Item: Pointer): TListIndex; virtual;

    Function Add(Item: Pointer): TListIndex; virtual;
    procedure Insert(ListIndex: TListIndex; Item: Pointer); virtual;
    Function Extract(Item: Pointer): Pointer; virtual;
    Function Remove(Item: Pointer): TListIndex; virtual;
    procedure Delete(ListIndex: TListIndex); virtual;
    procedure Move(SrcListIndex,DstListIndex: TListIndex); virtual;
    procedure Exchange(ListIndex1,ListIndex2: TListIndex); virtual;

    procedure Reverse; virtual;
    procedure Clear; virtual;

    procedure Defragment; virtual;
    Function ArrayItemIsFull(ArrayIndex: TArrayIndex): Boolean; virtual;

    property PayloadSize: TMemSize read fPayloadSize;
    property ArrayPointers[ArrayIndex: TArrayIndex]: PLinkedListArrayPayload read GetPayloadPtr;
    property ListPointers[ListIndex: TListIndex]: PLinkedListArrayPayload read GetPayloadPtrListIndex;
    property OnChange: TNotifyEvent read fOnChangeEvent write fOnChangeEvent;
    property OnChangeEvent: TNotifyEvent read fOnChangeEvent write fOnChangeEvent;
    property OnChangeCallback: TNotifyCallback read fOnChangeCallback write fOnChangeCallback;
  end;

implementation

uses
  SysUtils, Math;

const
  LLA_FLAG_FULL = $00000001;

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
{$message 'check'}
If (Value <> fCapacity) and (Value >= 0) then
  begin
    If Value > fCapacity then
      begin
        // add new empty items
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
        If not CheckArrayIndex(fFirstEmpty) then
          fFirstEmpty := OldCap;
        If CheckArrayIndex(fLastEmpty) then
          begin
            GetItemPtr(fLastEmpty)^.Next := OldCap;
            GetItemPtr(OldCap)^.Prev := fLastEmpty;
          end;
        fLastEmpty := HighArrayIndex;
      end
    else
      begin
        Defragment;
        // remove existing items
        If Value < fCount then
          begin
            // some full items will be removed
            For i := HighArrayIndex downto TArrayIndex(Value) do
              If (GetItemPtr(i)^.Flags and LLA_FLAG_FULL) <> 0 then
                PayloadFinal(GetPayloadPtr(i));
            ReallocMem(fMemory,TMemSize(Value) * TMemSize(fItemSize));
            fCapacity := Value;
            fCount := Value;
            GetItemPtr(HighArrayIndex)^.Next := -1;
            // there is no empty item anymore
            fFirstEmpty := -1;
            fLastEmpty := -1;
            fLastFull := HighArrayIndex;
            DoChange;
          end
        else
          begin
            // no full item is removed
            ReallocMem(fMemory,TMemSize(Value) * TMemSize(fItemSize));
            fCapacity := Value;
            GetItemPtr(HighArrayIndex)^.Next := -1;
            If fCount = fCapacity then
              begin
                fFirstEmpty := -1;
                fLastEmpty := -1;
                fLastFull := HighArrayIndex;
              end
            else fLastEmpty := HighArrayIndex;
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
For i := LowArrayIndex to HighArrayIndex do
  begin
    ItemPtr := GetItemPtr(i);
    If (ItemPtr^.Flags and LLA_FLAG_FULL) <> 0 then
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
    If ArrayIndex = fFirstEmpty then
      fFirstEmpty := ItemPtr^.Next;
    If ArrayIndex = fLastEmpty then
      fLastEmpty := ItemPtr^.Prev;      
    If ArrayIndex = fFirstFull then
      fFirstFull := ItemPtr^.Next;
    If ArrayIndex = fLastFull then
      fLastFull := ItemPtr^.Prev; 
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
    TempArrayIndex := fFirstFull;
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
    If (ItemPtr^.Flags and LLA_FLAG_FULL) <> 0 then
      begin
        // remove the item from list of full
        Decouple(ArrayIndex);
        // add item to list of empty
        ItemPtr^.Prev := fLastEmpty;
        ItemPtr^.Next := -1;
        If CheckArrayIndex(fLastEmpty) then
          GetItemPtr(fLastEmpty).Next := ArrayIndex;
        If not CheckArrayIndex(fFirstEmpty) then
          fFirstEmpty := ArrayIndex;
        fLastEmpty := ArrayIndex;
        // finalize item and set flags
        PayloadFinal(PayloadPtrFromItemPtr(ItemPtr));
        ItemPtr^.Flags := ItemPtr^.Flags and not LLA_FLAG_FULL;
        Dec(fCount);
        Shrink;
        DoChange;
      end;
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
fFirstEmpty := -1;
fLastEmpty := -1;
fFirstFull := -1;
fLastFull := -1;
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
    If (ItemPtr^.Flags and LLA_FLAG_FULL) <> 0 then
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
    If (ItemPtr^.Flags and LLA_FLAG_FULL) <> 0 then
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
Result := fFirstFull;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.LastArrayIndex: Integer;
begin
Result := fLastFull;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.First: Pointer;
begin
Result := GetPayloadPtr(fFirstFull);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.Last: Pointer;
begin
Result := GetPayloadPtr(fLastFull);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.ArrayIndex(ListIndex: TListIndex): TArrayIndex;
begin
If CheckListIndex(ListIndex) then
  begin
    Result := fFirstFull;
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
    If (GetItemPtr(ArrayIndex)^.Flags and LLA_FLAG_FULL) <> 0 then
      begin
        Result := LowListIndex;
        TempIndex := fFirstFull;
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

Function TLinkedListArray.IndicesOf(Item: Pointer; out ListIndex: TListIndex; out ArrayIndex: TArrayIndex): Boolean;
begin
Result := False;
// traverse list of full
ArrayIndex := fFirstFull;
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
IndicesOf(Item,ListIndex,Result);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.ListIndexOf(Item: Pointer): TListIndex;
var
  ArrayIndex: TArrayIndex;
begin
IndicesOf(Item,Result,ArrayIndex);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.Add(Item: Pointer): TListIndex;
var
  ArrayIndex: TArrayIndex;
  ItemPtr:    PLinkedListArrayItem;
begin
Grow;
// at this point, there MUST be at least one empty item
ArrayIndex := fFirstEmpty;
ItemPtr := GetItemPtr(ArrayIndex);
// remove the item from list of empty
Decouple(ArrayIndex);
// add the item to list off full
If not CheckArrayIndex(fFirstFull) then
  fFirstFull := ArrayIndex;
If CheckArrayIndex(fLastFull) then
  GetItemPtr(fLastFull)^.Next := ArrayIndex;
ItemPtr^.Prev := fLastFull;
ItemPtr^.Next := -1;
fLastFull := ArrayIndex;
// add the data and set flags
System.Move(Item^,PayloadPtrFromItemPtr(ItemPtr)^,fPayloadSize);
ItemPtr^.Flags := ItemPtr^.Flags or LLA_FLAG_FULL;
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
        NewItemArrayIndex := fFirstEmpty;
        NewItemPtr := GetItemPtr(NewItemArrayIndex);
        OldItemPtr := GetItemPtr(OldItemArrayIndex);
        Decouple(NewItemArrayIndex);
        // insert to the list of full
        NewItemPtr^.Prev := OldItemPtr^.Prev;
        NewItemPtr^.Next := OldItemArrayIndex;
        If CheckArrayIndex(OldItemPtr^.Prev) then
          GetItemPtr(OldItemPtr^.Prev)^.Next := NewItemArrayIndex;
        OldItemPtr^.Prev := NewItemArrayIndex;
        If fFirstFull = OldItemArrayIndex then
          fFirstFull := NewItemArrayIndex;
        // add the data and set flags
        System.Move(Item^,PayloadPtrFromItemPtr(NewItemPtr)^,fPayloadSize);
        NewItemPtr^.Flags := NewItemPtr^.Flags or LLA_FLAG_FULL;
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
    // add item to list of empty
    ItemPtr^.Prev := fLastEmpty;
    ItemPtr^.Next := -1;
    If CheckArrayIndex(fLastEmpty) then
      GetItemPtr(fLastEmpty).Next := ArrayIndex;
    If not CheckArrayIndex(fFirstEmpty) then
      fFirstEmpty := ArrayIndex;
    fLastEmpty := ArrayIndex;
    // reset flag and return the item
    ItemPtr^.Flags := ItemPtr^.Flags and not LLA_FLAG_FULL;
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
IndicesOf(Item,Result,ArrayIndex);
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
        If fLastFull = DstArrayIndex then
          fLastFull := SrcArrayIndex
      end
    else
      begin
        // item is moved down
        SrcItemPtr^.Prev := DstItemPtr^.Prev;
        SrcItemPtr^.Next := DstArrayIndex;
        If CheckArrayIndex(DstItemPtr^.Prev) then
          GetItemPtr(DstItemPtr^.Prev)^.Next := SrcArrayIndex;
        DstItemPtr^.Prev := SrcArrayIndex;
        If fFirstFull = DstArrayIndex then
          fFirstFull := SrcArrayIndex;        
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
    If ArrayIndex1 = fFirstFull then
      fFirstFull := ArrayIndex2
    else If ArrayIndex2 = fFirstFull then
      fFirstFull := ArrayIndex1;
    If ArrayIndex1 = fLastFull then
      fLastFull := ArrayIndex2
    else If ArrayIndex2 = fLastFull then
      fLastFull := ArrayIndex1;
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

procedure TLinkedListArray.Reverse;
var
  TempIndex:  TArrayIndex;
begin
If fCount > 1 then
  begin
    TempIndex := fFirstFull;
    fFirstFull := fLastFull;
    fLastFull := TempIndex;
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

procedure TLinkedListArray.Clear;
var
  i:  TArrayIndex;
begin
FinalizeAllItems;
For i := LowArrayIndex to HighArrayIndex do
  with GetItemPtr(i)^ do
    begin
      Prev :=  i - 1;
      If i < HighArrayIndex then
        Next := i + 1
      else
        Next := -1;
      Flags := 0;
    end;
fCount := 0;
fFirstEmpty := LowArrayIndex;
fLastEmpty := HighArrayIndex;
fFirstFull := -1;
fLastFull := -1;
DoChange;
end; 

//------------------------------------------------------------------------------

procedure TLinkedListArray.Defragment;
begin
{$message 'implement'}
end;
 
//------------------------------------------------------------------------------

Function TLinkedListArray.ArrayItemIsFull(ArrayIndex: TArrayIndex): Boolean;
begin
Result := False;
If CheckArrayIndexAndRaise(ArrayIndex,'ArrayItemIsFull') then
  Result := (GetItemPtr(ArrayIndex)^.Flags and LLA_FLAG_FULL) <> 0;
end;

end.
