unit LinkedListArray;

interface

uses
  AuxTypes, AuxClasses;

type
  TLinkedListArrayItemPrivate = record
    Prev:     Integer;
    Next:     Integer;
    Flags:    Integer;
  {$IF SizeOf(Integer) = 4}
    Padding:  Integer;
  {$IFEND}
  end;
  PLinkedListArrayItemPrivate = ^TLinkedListArrayItemPrivate;

  TLinkedListArray = class(TCustomListObject)
  private
    fItemPublicSize:  Integer;
    fItemFullSize:    Integer;
    fMemory:          Pointer;
    fCapacity:        Integer;
    fCount:           Integer;
    fChangeCounter:   Integer;
    fChanged:         Boolean;
    fOnChange:        TNotifyEvent;
  protected
    fTempItem:        Pointer;
    fFirstEmpty:      Integer;
    fLastEmpty:       Integer;
    fFirstFull:       Integer;
    fLastFull:        Integer;
    Function PublicPtrFromPrivatePtr(PrivatePtr: PLinkedListArrayItemPrivate): Pointer; virtual;
    Function PrivatePtrFromPublicPtr(PublicPtr: Pointer): PLinkedListArrayItemPrivate; virtual;
    Function GetItemPrivatePtr(Index: Integer): PLinkedListArrayItemPrivate; virtual;
    Function GetItemPublicPtr(Index: Integer): Pointer; virtual;
    procedure SetItemPublicPtr(Index: Integer; Value: Pointer); virtual;
    Function GetCapacity: Integer; override;
    procedure SetCapacity(Value: Integer); override;
    Function GetCount: Integer; override;
    procedure SetCount(Value: Integer); override;
    Function CheckIndexAndRaise(Index: Integer; CallingMethod: String = 'CheckIndexAndRaise'): Boolean; virtual;
    procedure RaiseError(const ErrorMessage: String; Values: array of const); overload; virtual;
    procedure RaiseError(const ErrorMessage: String); overload; virtual;
    procedure ItemInit(Item: Pointer); virtual;
    procedure ItemFinal(Item: Pointer); virtual;
    procedure ItemCopy(SrcItem,DstItem: Pointer); virtual;
    Function ItemCompare(Item1,Item2: Pointer): Integer; virtual;
    Function ItemEquals(Item1,Item2: Pointer): Boolean; virtual;
    procedure FinalizeAllItems; virtual;
    procedure DoChange; virtual;
  public
    constructor Create(ItemSize: TMemSize);
    destructor Destroy; override;
    procedure BeginChanging; virtual;
    Function EndChanging: Integer; virtual;  
    Function LowIndex: Integer; override;
    Function HighIndex: Integer; override;
    Function Previous(Index: Integer): Integer; virtual;
    Function Next(Index: Integer): Integer; virtual;

    Function IndexOf(ListIndex: Integer): Integer; virtual;

    procedure Delete(Index: Integer); virtual; abstract;
    procedure Defragment(Order: Boolean = False); virtual; abstract;

    property ItemSize: Integer read fItemPublicSize;
    property Pointers[Index: Integer]: Pointer read GetItemPublicPtr;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
  end;

implementation

uses
  SysUtils;

const
  LLA_FLAG_FULL = $00000001;

//==============================================================================

Function TLinkedListArray.PublicPtrFromPrivatePtr(PrivatePtr: PLinkedListArrayItemPrivate): Pointer;
begin
Result := Pointer(PtrUInt(PrivatePtr) + PtrUInt(SizeOf(TLinkedListArrayItemPrivate)));
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.PrivatePtrFromPublicPtr(PublicPtr: Pointer): PLinkedListArrayItemPrivate;
begin
Result := PLinkedListArrayItemPrivate(PtrUInt(PublicPtr) - PtrUInt(SizeOf(TLinkedListArrayItemPrivate)));
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.GetItemPrivatePtr(Index: Integer): PLinkedListArrayItemPrivate;
begin
If CheckIndexAndRaise(Index,'GetItemPrivatePtr') then
  Result := PLinkedListArrayItemPrivate(PtrUInt(fMemory) + (PtrUInt(Index) * (PtrUInt(fItemFullSize))));
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.GetItemPublicPtr(Index: Integer): Pointer;
begin
Result := PublicPtrFromPrivatePtr(GetItemPrivatePtr(Index));
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.SetItemPublicPtr(Index: Integer; Value: Pointer);
var
  ItemPtr:  Pointer;
begin
ItemPtr := GetItemPublicPtr(Index);
System.Move(ItemPtr^,fTempItem^,fItemPublicSize);
System.Move(Value^,ItemPtr^,fItemPublicSize);
If not ItemEquals(fTempItem,Value) then
  DoChange;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.GetCapacity: Integer;
begin
Result := fCapacity;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.SetCapacity(Value: Integer);
var
  i:        Integer;
  OldCap:   Integer;
  ItemPtr:  PLinkedListArrayItemPrivate;
begin
{$message 'check'}
If (Value <> fCapacity) and (Value >= 0) then
  begin
    If Value > fCapacity then
      begin
        // add new empty items
        OldCap := fCapacity;
        ReallocMem(fMemory,TMemSize(Value) * TMemSize(fItemFullSize));
        fCapacity := Value;
        For i := OldCap to HighIndex do
          begin
            ItemPtr := GetItemPrivatePtr(i);
            If i = OldCap then ItemPtr^.Prev := -1
              else ItemPtr^.Prev := i - 1;
            If i = HighIndex then ItemPtr^.Next := -1
              else ItemPtr^.Next := i + 1;
            ItemPtr^.Flags := 0;
          end;
        If not CheckIndex(fFirstEmpty) then
          fFirstEmpty := OldCap;
        If CheckIndex(fLastEmpty) then
          begin
            GetItemPrivatePtr(fLastEmpty)^.Next := OldCap;
            GetItemPrivatePtr(OldCap)^.Prev := fLastEmpty;
          end;
        fLastEmpty := HighIndex;
      end
    else
      begin
        // remove existing items
        Defragment(True);
        If Value < fCount then
          begin
            // some full items will be removed
            For i := HighIndex downto Value do
              ItemFinal(GetItemPublicPtr(i));
            ReallocMem(fMemory,TMemSize(Value) * TMemSize(fItemFullSize));
            fCapacity := Value;
            fCount := Value;
            GetItemPrivatePtr(HighIndex)^.Next := -1;
            // there is no empty item anymore
            fFirstEmpty := -1;
            fLastEmpty := -1;
            fLastFull := HighIndex;
            DoChange;
          end
        else
          begin
            // no full item is removed
            ReallocMem(fMemory,TMemSize(Value) * TMemSize(fItemFullSize));
            fCapacity := Value;
            fCount := Value;
            GetItemPrivatePtr(HighIndex)^.Next := -1;
            If fCount = fCapacity then
              begin
                fFirstEmpty := -1;
                fLastEmpty := -1;
                fLastFull := HighIndex;
              end
            else fLastEmpty := HighIndex;
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

Function TLinkedListArray.CheckIndexAndRaise(Index: Integer; CallingMethod: String = 'CheckIndexAndRaise'): Boolean;
begin
Result := CheckIndex(Index);
If not Result then
  RaiseError('%s: Index (%d) out of bounds.',[CallingMethod,Index]);
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

procedure TLinkedListArray.ItemInit(Item: Pointer);
begin
FillChar(Item^,fItemPublicSize,0);
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.ItemFinal(Item: Pointer);
begin
// nothing to do here
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.ItemCopy(SrcItem,DstItem: Pointer);
begin
System.Move(SrcItem^,DstItem^,fItemPublicSize);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.ItemCompare(Item1,Item2: Pointer): Integer;
begin
Result := Integer(PtrUInt(Item2) - PtrUInt(Item1));
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.ItemEquals(Item1,Item2: Pointer): Boolean;
begin
Result := ItemCompare(Item1,Item2) = 0;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.FinalizeAllItems;
var
  i:        Integer;
  ItemPtr:  PLinkedListArrayItemPrivate;
begin
For i := LowIndex to HighIndex do
  begin
    ItemPtr := GetItemPrivatePtr(i);
    If (ItemPtr^.Flags and LLA_FLAG_FULL) <> 0 then
      ItemFinal(PublicPtrFromPrivatePtr(ItemPtr));
  end;
end;

//------------------------------------------------------------------------------

procedure TLinkedListArray.DoChange;
begin
fChanged := True;
If (fChangeCounter <= 0) and Assigned(fOnChange) then
  fOnChange(Self);
end;

//==============================================================================

constructor TLinkedListArray.Create(ItemSize: TMemSize);
begin
inherited Create;
fItemPublicSize := ItemSize;
fItemFullSize := fItemPublicSize + SizeOf(TLinkedListArrayItemPrivate); // add padding?
fMemory := nil;
fCapacity := 0;
fCount := 0;
fChangeCounter := 0;
fChanged := False;
fOnChange := nil;
GetMem(fTempItem,fItemPublicSize);
fFirstEmpty := -1;
fLastEmpty := -1;
fFirstFull := -1;
fLastFull := -1;
end;

//------------------------------------------------------------------------------

destructor TLinkedListArray.Destroy;
begin
FreeMem(fTempItem,fItemPublicSize);
FinalizeAllItems;
FreeMem(fMemory,TMemSize(fCapacity) * TMemSize(fItemFullSize));
inherited;
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
    If fChanged and Assigned(fOnChange) then
      fOnChange(Self);
    fChanged := False;
  end;
Result := fChangeCounter;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.LowIndex: Integer;
begin
Result := 0;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.HighIndex: Integer;
begin
Result := Pred(fCapacity);
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.Previous(Index: Integer): Integer;
var
  ItemPtr:  PLinkedListArrayItemPrivate;
begin
If CheckIndex(Index) then
  begin
    ItemPtr := GetItemPrivatePtr(Result);
    If (ItemPtr^.Flags and LLA_FLAG_FULL) <> 0 then
      Result := ItemPtr.Prev
    else
      Result := -1;
  end
else Result := -1;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.Next(Index: Integer): Integer;
var
  ItemPtr:  PLinkedListArrayItemPrivate;
begin
If CheckIndex(Index) then
  begin
    ItemPtr := GetItemPrivatePtr(Result);
    If (ItemPtr^.Flags and LLA_FLAG_FULL) <> 0 then
      Result := ItemPtr.Next
    else
      Result := -1;
  end
else Result := -1;
end;

//------------------------------------------------------------------------------

Function TLinkedListArray.IndexOf(ListIndex: Integer): Integer;
begin
Result := fFirstFull;
while CheckIndex(Result) and (ListIndex > 0) do
  begin
    Result := GetItemPrivatePtr(Result)^.Next;
    Dec(ListIndex);
  end;
end;

end.
