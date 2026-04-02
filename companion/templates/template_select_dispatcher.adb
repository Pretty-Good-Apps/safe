--  Verified Emission Template: Dispatcher-Based Select Lowering
--  See template_select_dispatcher.ads for clause references.

pragma SPARK_Mode (On);

with Safe_PO; use Safe_PO;

package body Template_Select_Dispatcher
  with SPARK_Mode => On
is

   procedure Reset (D : out Dispatcher) is
   begin
      D.Signaled := False;
      D.Delay_Expired := False;
   end Reset;

   procedure Signal (D : in out Dispatcher) is
   begin
      D.Signaled := True;
   end Signal;

   procedure Signal_Delay (D : in out Dispatcher) is
   begin
      D.Delay_Expired := True;
   end Signal_Delay;

   procedure Await (D : in out Dispatcher; Timed_Out : out Boolean) is
   begin
      Timed_Out := D.Delay_Expired;
      D.Signaled := False;
      D.Delay_Expired := False;
   end Await;

   -------------------------------------------------------------------
   --  Try_Receive: non-blocking receive
   --
   --  Emission pattern from translation_rules.md Section 5.1:
   --    If channel is non-empty, dequeue and set Success := True.
   --    Otherwise, set Item := Default_Element and Success := False.
   --  The PO hook Check_Channel_Not_Empty is called when Count > 0.
   -------------------------------------------------------------------
   procedure Try_Receive
     (Ch      : in out Channel;
      Item    : out Element_Type;
      Success : out Boolean)
   is
   begin
      if Ch.Count > 0 then
         --  PO hook: verify channel is not empty.
         Check_Channel_Not_Empty (Ch.Count);

         --  Dequeue: read element at Head, advance Head circularly.
         Item := Ch.Buffer (Ch.Head);
         if Ch.Head = Ch.Capacity then
            Ch.Head := 1;
         else
            Ch.Head := Ch.Head + 1;
         end if;
         Ch.Count := Ch.Count - 1;
         Success := True;
      else
         --  Channel empty: no item available.
         Item := Default_Element;
         Success := False;
      end if;
   end Try_Receive;

   procedure Probe_Ready_Arms
     (Ch_A      : in out Channel;
      Ch_B      : in out Channel;
      Next_Arm  : in out Arm_Index;
      Item      : out Element_Type;
      Selected  : out Boolean)
     with Pre  => Is_Valid (Ch_A) and then Is_Valid (Ch_B),
          Post =>
            Is_Valid (Ch_A) and then Is_Valid (Ch_B)
            and then
              (if Next_Arm'Old = 1 and then Ch_A.Count'Old > 0 then
                 Selected
                 and then Ch_A.Count = Ch_A.Count'Old - 1
                 and then Ch_B.Count = Ch_B.Count'Old
                 and then Next_Arm = 2
               elsif Next_Arm'Old = 1
                 and then Ch_A.Count'Old = 0
                 and then Ch_B.Count'Old > 0
               then
                 Selected
                 and then Ch_A.Count = Ch_A.Count'Old
                 and then Ch_B.Count = Ch_B.Count'Old - 1
                 and then Next_Arm = 1
               elsif Next_Arm'Old = 2 and then Ch_B.Count'Old > 0 then
                 Selected
                 and then Ch_A.Count = Ch_A.Count'Old
                 and then Ch_B.Count = Ch_B.Count'Old - 1
                 and then Next_Arm = 1
               elsif Next_Arm'Old = 2
                 and then Ch_B.Count'Old = 0
                 and then Ch_A.Count'Old > 0
               then
                 Selected
                 and then Ch_A.Count = Ch_A.Count'Old - 1
                 and then Ch_B.Count = Ch_B.Count'Old
                 and then Next_Arm = 2
               else
                 not Selected
                 and then Ch_A.Count = Ch_A.Count'Old
                 and then Ch_B.Count = Ch_B.Count'Old
                 and then Next_Arm = Next_Arm'Old)
   is
   begin
      if Next_Arm = 1 then
         Try_Receive (Ch_A, Item, Selected);
         if Selected then
            Next_Arm := 2;
         else
            Try_Receive (Ch_B, Item, Selected);
            if Selected then
               Next_Arm := 1;
            end if;
         end if;
      else
         Try_Receive (Ch_B, Item, Selected);
         if Selected then
            Next_Arm := 1;
         else
            Try_Receive (Ch_A, Item, Selected);
            if Selected then
               Next_Arm := 2;
            end if;
         end if;
      end if;
   end Probe_Ready_Arms;

   -------------------------------------------------------------------
   --  Select_With_Delay: two-arm select with delay arm
   --
   --  Emission pattern from translation_rules.md Section 5:
   --    The precheck tests channel arms exactly once in circular order
   --    starting at Next_Arm.
   --    When neither arm is ready, the dispatcher awaits either:
   --      * a channel wake from a successful send
   --      * the one-shot delay wake from the timing handler
   --    A bounded wake schedule models the finite environment trace.
   -------------------------------------------------------------------
   procedure Select_With_Delay
     (Ch_A      : in out Channel;
      Ch_B      : in out Channel;
      Wakeups   : Delay_Wake_Schedule;
      Next_Arm  : in out Arm_Index;
      Result    : out Element_Type;
      Timed_Out : out Boolean)
   is
      Success     : Boolean;
      Item        : Element_Type;
      Disp        : Dispatcher;
      Timed_Wake  : Boolean;
      Initial_Count_A : constant Count_Range := Ch_A.Count;
      Initial_Count_B : constant Count_Range := Ch_B.Count;
      Initial_Next_Arm : constant Arm_Index := Next_Arm;
   begin
      Result    := Default_Element;
      Timed_Out := False;
      Reset (Disp);

      Probe_Ready_Arms (Ch_A, Ch_B, Next_Arm, Item, Success);
      pragma Assert
        ((if Initial_Next_Arm = 1 and then Initial_Count_A > 0 then
             Success
             and then Ch_A.Count = Initial_Count_A - 1
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = 2
           elsif Initial_Next_Arm = 1
             and then Initial_Count_A = 0
             and then Initial_Count_B > 0
           then
             Success
             and then Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B - 1
             and then Next_Arm = 1
           elsif Initial_Next_Arm = 2 and then Initial_Count_B > 0 then
             Success
             and then Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B - 1
             and then Next_Arm = 1
           elsif Initial_Next_Arm = 2
             and then Initial_Count_B = 0
             and then Initial_Count_A > 0
           then
             Success
             and then Ch_A.Count = Initial_Count_A - 1
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = 2
           else
             not Success
             and then Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = Initial_Next_Arm));
      if Success then
         Result := Item;
         return;
      end if;

      pragma Assert
        (Initial_Count_A = 0
         and then Initial_Count_B = 0
         and then Next_Arm = Initial_Next_Arm);

      for Iter in Wake_Range loop
         pragma Loop_Invariant (Is_Valid (Ch_A));
         pragma Loop_Invariant (Is_Valid (Ch_B));
         pragma Loop_Invariant (not Timed_Out);
         pragma Loop_Invariant (Is_Idle (Disp));
         pragma Loop_Invariant (Ch_A.Count = Initial_Count_A);
         pragma Loop_Invariant (Ch_B.Count = Initial_Count_B);
         pragma Loop_Invariant (Next_Arm = Initial_Next_Arm);

         case Wakeups (Iter) is
            when No_Wake =>
               null;
            when Channel_Wake =>
               Signal (Disp);
               Await (Disp, Timed_Wake);
               pragma Assert (not Timed_Wake);
            when Delay_Wake =>
               Signal_Delay (Disp);
               Await (Disp, Timed_Wake);
               if Timed_Wake then
                  Timed_Out := True;
                  exit;
               end if;
         end case;
      end loop;

      pragma Assert
        ((if Timed_Out then
             Any_Delay_Wake (Wakeups)
             and then Initial_Count_A = 0
             and then Initial_Count_B = 0
             and then Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = Initial_Next_Arm
           elsif Initial_Next_Arm = 1 and then Initial_Count_A > 0 then
             Ch_A.Count = Initial_Count_A - 1
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = 2
           elsif Initial_Next_Arm = 1
             and then Initial_Count_A = 0
             and then Initial_Count_B > 0
           then
             Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B - 1
             and then Next_Arm = 1
           elsif Initial_Next_Arm = 2 and then Initial_Count_B > 0 then
             Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B - 1
             and then Next_Arm = 1
           elsif Initial_Next_Arm = 2
             and then Initial_Count_B = 0
             and then Initial_Count_A > 0
           then
             Ch_A.Count = Initial_Count_A - 1
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = 2
           else
             Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = Initial_Next_Arm));
   end Select_With_Delay;

   -------------------------------------------------------------------
   --  Select_No_Delay: two-arm select without delay arm
   --
   --  Emission pattern from translation_rules.md Section 5:
   --    The precheck tests channel arms exactly once in circular order
   --    starting at Next_Arm.
   --    When neither arm is ready, the dispatcher blocks until a channel
   --    wake arrives; the bounded wake schedule models a finite trace.
   -------------------------------------------------------------------
   procedure Select_No_Delay
     (Ch_A   : in out Channel;
      Ch_B   : in out Channel;
      Wakeups  : Channel_Wake_Schedule;
      Next_Arm : in out Arm_Index;
      Result   : out Element_Type;
      Found    : out Boolean)
   is
      Success     : Boolean;
      Item        : Element_Type;
      Disp        : Dispatcher;
      Timed_Wake  : Boolean;
      Initial_Count_A : constant Count_Range := Ch_A.Count;
      Initial_Count_B : constant Count_Range := Ch_B.Count;
      Initial_Next_Arm : constant Arm_Index := Next_Arm;
   begin
      Result := Default_Element;
      Found  := False;
      Reset (Disp);

      Probe_Ready_Arms (Ch_A, Ch_B, Next_Arm, Item, Success);
      pragma Assert
        ((if Initial_Next_Arm = 1 and then Initial_Count_A > 0 then
             Success
             and then Ch_A.Count = Initial_Count_A - 1
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = 2
           elsif Initial_Next_Arm = 1
             and then Initial_Count_A = 0
             and then Initial_Count_B > 0
           then
             Success
             and then Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B - 1
             and then Next_Arm = 1
           elsif Initial_Next_Arm = 2 and then Initial_Count_B > 0 then
             Success
             and then Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B - 1
             and then Next_Arm = 1
           elsif Initial_Next_Arm = 2
             and then Initial_Count_B = 0
             and then Initial_Count_A > 0
           then
             Success
             and then Ch_A.Count = Initial_Count_A - 1
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = 2
           else
             not Success
             and then Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = Initial_Next_Arm));
      if Success then
         Result := Item;
         Found := True;
         return;
      end if;

      pragma Assert
        (Initial_Count_A = 0
         and then Initial_Count_B = 0
         and then Next_Arm = Initial_Next_Arm);

      for Iter in Wake_Range loop
         pragma Loop_Invariant (Is_Valid (Ch_A));
         pragma Loop_Invariant (Is_Valid (Ch_B));
         pragma Loop_Invariant (Is_Idle (Disp));
         pragma Loop_Invariant (not Found);
         pragma Loop_Invariant (Ch_A.Count = Initial_Count_A);
         pragma Loop_Invariant (Ch_B.Count = Initial_Count_B);
         pragma Loop_Invariant (Next_Arm = Initial_Next_Arm);

         if Wakeups (Iter) then
            Signal (Disp);
            Await (Disp, Timed_Wake);
            pragma Assert (not Timed_Wake);
         end if;
      end loop;

      pragma Assert
        ((if Initial_Next_Arm = 1 and then Initial_Count_A > 0 then
             Found
             and then Ch_A.Count = Initial_Count_A - 1
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = 2
           elsif Initial_Next_Arm = 1
             and then Initial_Count_A = 0
             and then Initial_Count_B > 0
           then
             Found
             and then Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B - 1
             and then Next_Arm = 1
           elsif Initial_Next_Arm = 2 and then Initial_Count_B > 0 then
             Found
             and then Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B - 1
             and then Next_Arm = 1
           elsif Initial_Next_Arm = 2
             and then Initial_Count_B = 0
             and then Initial_Count_A > 0
           then
             Found
             and then Ch_A.Count = Initial_Count_A - 1
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = 2
           else
             not Found
             and then Ch_A.Count = Initial_Count_A
             and then Ch_B.Count = Initial_Count_B
             and then Next_Arm = Initial_Next_Arm));
   end Select_No_Delay;

end Template_Select_Dispatcher;
