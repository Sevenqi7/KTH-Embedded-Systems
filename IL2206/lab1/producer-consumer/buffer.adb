package body Buffer is
   protected body CircularBuffer is

      entry Put(X: Item) when Count < Size is
      begin
         A(In_Ptr) := X;
         In_Ptr := In_Ptr + 1;
         Count := Count + 1;
      end Put;

      entry Get(X: out Item) when Count > 0 is
      begin
         X := A(Out_Ptr);
         Out_Ptr := Out_Ptr + 1;
         Count := Count - 1;
      end Get;
   end CircularBuffer;
end Buffer;
