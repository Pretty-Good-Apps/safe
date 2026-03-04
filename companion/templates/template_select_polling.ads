--  Verified Emission Template: Select-to-Polling-Loop Lowering
--
--  Clause: SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p33:7a94ab51
--  Clause: SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p39:1012f4db
--  Clause: SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p41:cdf6a558
--  Clause: SAFE@4aecf21:spec/04-tasks-and-channels.md#4.4.p42:dce8ac38
--  Reference: compiler/translation_rules.md Section 5
--
--  Demonstrates the compiler emission pattern for select statement lowering:
--    1. Each channel arm becomes a Try_Receive call in declaration order
--    2. Arms are tested in priority order (declaration order per spec)
--    3. A delay arm is modeled as a Boolean flag (Deadline_Elapsed)
--    4. The polling loop is bounded (for loop) for proof termination
--
--  SPARK constraints:
--    - Ada.Real_Time and delay statements are not provable in SPARK.
--      The deadline check is abstracted to a Boolean parameter (T-01).
--    - Bounded for loop avoids need for pragma Loop_Variant.
--    - Item := 0 on failure paths satisfies SPARK flow analysis for
--      out parameter initialization.
--
--  PO hooks exercised: Check_Channel_Not_Empty

pragma SPARK_Mode (On);
pragma Assertion_Policy (Check);

package Template_Select_Polling
  with SPARK_Mode => On
is

   Max_Capacity : constant := 16;
   Max_Poll_Iterations : constant := 100;

   subtype Element_Type is Integer;
   subtype Capacity_Range is Positive range 1 .. Max_Capacity;
   subtype Count_Range is Natural range 0 .. Max_Capacity;
   subtype Index_Range is Positive range 1 .. Max_Capacity;

   type Buffer_Array is array (Index_Range) of Element_Type;

   --  Channel record compatible with template_channel_fifo pattern.
   type Channel (Capacity : Capacity_Range) is record
      Buffer : Buffer_Array;
      Head   : Index_Range;
      Tail   : Index_Range;
      Count  : Count_Range;
   end record;

   --  Structural invariant.
   function Is_Valid (Ch : Channel) return Boolean is
     (Ch.Head <= Ch.Capacity
      and then Ch.Tail <= Ch.Capacity
      and then Ch.Count <= Ch.Capacity);

   function Is_Empty (Ch : Channel) return Boolean is
     (Ch.Count = 0);

   --  Non-blocking receive: attempts to dequeue one element.
   --  Success = True iff the channel was non-empty and an item was received.
   procedure Try_Receive
     (Ch      : in out Channel;
      Item    : out Element_Type;
      Success : out Boolean)
     with Pre  => Is_Valid (Ch),
          Post => Is_Valid (Ch)
                  and then (if Success then
                              Ch.Count = Ch.Count'Old - 1
                            else
                              Ch.Count = Ch.Count'Old);

   --  Two-arm select with delay arm.
   --  Arms are tested in declaration order: Ch_A (Arm 1), Ch_B (Arm 2).
   --  If Deadline_Elapsed is True, the delay arm fires immediately.
   --
   --  Assumption T-01: Deadline_Elapsed faithfully represents wall-clock
   --  elapsed time (see companion/assumptions.yaml T-01).
   procedure Select_With_Delay
     (Ch_A             : in out Channel;
      Ch_B             : in out Channel;
      Deadline_Elapsed : Boolean;
      Result           : out Element_Type;
      Timed_Out        : out Boolean)
     with Pre  => Is_Valid (Ch_A) and then Is_Valid (Ch_B),
          Post => Is_Valid (Ch_A) and then Is_Valid (Ch_B);

   --  Two-arm select without delay arm.
   --  Arms are tested in declaration order: Ch_A (Arm 1), Ch_B (Arm 2).
   --  Found = True iff an item was successfully received from either channel.
   procedure Select_No_Delay
     (Ch_A   : in out Channel;
      Ch_B   : in out Channel;
      Result : out Element_Type;
      Found  : out Boolean)
     with Pre  => Is_Valid (Ch_A) and then Is_Valid (Ch_B),
          Post => Is_Valid (Ch_A) and then Is_Valid (Ch_B);

end Template_Select_Polling;
