-- Package: Semaphores
--
-- ==> Complete the code at the indicated places

--  with Ada.Text_IO; use Ada.Text_IO;

package body Semaphores is
   protected body CountingSemaphore is
      entry Wait -- To be completed
        when Count > 0 is
      begin
         Count := Count - 1;
         --  Put_Line("Wait" & Integer'Image(Count));
      end Wait;

      entry Signal -- To be completed
        when Count < MaxCount is
      begin
         Count := Count + 1;
         --  Put_Line("Signal" & Integer'Image(Count));
      end Signal;
   end CountingSemaphore;
end Semaphores;
