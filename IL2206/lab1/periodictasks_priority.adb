pragma Task_Dispatching_Policy(FIFO_Within_Priorities);

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Float_Text_IO;

with Ada.Real_Time; use Ada.Real_Time;

procedure PeriodicTasks_Priority is
   package Duration_IO is new Ada.Text_IO.Fixed_IO(Duration);
   package Int_IO is new Ada.Text_IO.Integer_IO(Integer);
	
   Start : Time; -- Start Time of the System
	Calibrator: constant Integer := 850; -- Calibration for correct timing
	                                     -- ==> Change parameter for your architecture!
	Warm_Up_Time: constant Integer := 100; -- Warmup time in milliseconds
	
	-- Conversion Function: Time_Span to Float
	function To_Float(TS : Time_Span) return Float is
        SC : Seconds_Count;
        Frac : Time_Span;
   begin
		Split(Time_Of(0, TS), SC, Frac);
		return Float(SC) + Time_Unit * Float(Frac/Time_Span_Unit);
   end To_Float;
	
	-- Function F is a dummy function that is used to model a running user program.
	function F(N : Integer) return Integer;

   function F(N : Integer) return Integer is
      X : Integer := 0;
   begin
      for Index in 1..N loop
         for I in 1..500 loop
            X := X + I;
         end loop;
      end loop;
      return X;
   end F;
	
	-- Workload Model for a Parametric Task
   task type T(Id: Integer; Prio: Integer; Phase: Integer; Period : Integer; 
									 Computation_Time : Integer; Relative_Deadline: Integer) is
      pragma Priority(Prio); -- A higher number gives a higher priority
   end;

   task body T is
      Next : Time;
		Release: Time;
		Completed : Time;
		Response : Time_Span;
		Average_Response : Float;
		Absolute_Deadline: Time;
		WCRT: Time_Span; -- measured WCRT (Worst Case Response Time)
      Dummy : Integer;
		Iterations : Integer;
   begin
		-- Initial Release - Phase
		Release := Clock + Milliseconds(Phase);
		delay until Release;
		Next := Release;
		Iterations := 0;
		Average_Response := 0.0;
		WCRT := Milliseconds(0);
      loop
         Next := Release + Milliseconds(Period);
			Absolute_Deadline := Release + Milliseconds(Relative_Deadline);
         -- Simulation of User Function
			for I in 1..Computation_Time loop
				Dummy := F(Calibrator); 
			end loop;	
			Completed := Clock;
			Response := Completed - Release;
			Average_Response := (Float(Iterations) * Average_Response + To_Float(Response)) / Float(Iterations + 1);
			if Response > WCRT then
				WCRT := Response;
			end if;
			Iterations := Iterations + 1;			
			Put("Task ");
			Int_IO.Put(Id, 1);
			Put("- Release: ");
			Duration_IO.Put(To_Duration(Release - Start), 2, 3);
			Put(", Completion: ");
			Duration_IO.Put(To_Duration(Completed - Start), 2, 3);
			Put(", Response: ");
			Duration_IO.Put(To_Duration(Response), 1, 3);
			Put(", WCRT: ");
			Ada.Float_Text_IO.Put(To_Float(WCRT), fore => 1, aft => 3, exp => 0);	
			Put(", Next Release: ");
			Duration_IO.Put(To_Duration(Next - Start), 2, 3);
			if Completed > Absolute_Deadline then 
				Put(" ==> Task ");
				Int_IO.Put(Id, 1);
				Put(" violates Deadline!");
			end if;
         Put_Line("");
			Release := Next;
         delay until Release;
      end loop;
   end T;

   -- Running Tasks
	-- NOTE: All tasks should have a minimum phase, so that they have the same time base!
	
   Task_1 : T(1, 20, Warm_Up_Time, 2000, 1000, 2000); -- ID: 1
	                                                   -- Priority: 20
                                                      --	Phase: Warm_Up_Time (100)
	                                                   -- Period 2000, 
	                                                   -- Computation Time: 1000 (if correctly calibrated) 
	                                                   -- Relative Deadline: 2000
	
-- Main Program: Terminates after measuring start time	
begin
   Start := Clock; -- Central Start Time
   null;
end PeriodicTasks_Priority;
