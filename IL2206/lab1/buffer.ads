package Buffer is
   Size: constant Integer := 3;
   subtype Item is Integer;
   type Index is mod Size;
   type Item_Array is array(Index) of Item;

   protected type CircularBuffer is
      entry Put(X: in Item);
      entry Get(X: out Item);
   private
      A: Item_Array;
      In_Ptr, Out_Ptr: Index := 0;
      Count: Integer range 0..Size := 0;
   end CircularBuffer;
end Buffer;

