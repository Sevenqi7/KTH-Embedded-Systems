with Ada.Text_IO; use Ada.Text_IO;
with Semaphores;

procedure Main is
    sema : Semaphores.CountingSemaphore (5, 0);
begin
    Ada.Text_IO.Put_Line ("nihao");
    sema.Signal;
    sema.Wait;
    Ada.Text_IO.Put_Line ("Test done.");
end Main;
