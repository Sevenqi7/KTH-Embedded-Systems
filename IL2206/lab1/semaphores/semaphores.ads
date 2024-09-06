-- Package: Semaphores
-- 
-- ==> Do not change this file!

package Semaphores is
   protected type CountingSemaphore(Max: Natural; Initial: Natural)  is
      entry Wait;
      entry Signal;
   private
      Count : Natural := Initial;
      MaxCount : Natural := Max;
   end CountingSemaphore;
end Semaphores;

