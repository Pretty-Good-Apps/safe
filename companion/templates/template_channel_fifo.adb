--  Verified Emission Template: Bounded Channel FIFO
--  See template_channel_fifo.ads for clause references.

pragma SPARK_Mode (On);

with Safe_PO; use Safe_PO;
with Safe_Model;

package body Template_Channel_FIFO
  with SPARK_Mode => On
is

   use type Safe_Model.Channel_State;

   function Model_Of (Ch : Channel) return Safe_Model.Channel_State is
      Result : Safe_Model.Channel_State (Ch.Capacity) :=
        Safe_Model.Make_Channel (Ch.Capacity);
   begin
      if Ch.Count > 0 then
         for Pos in 1 .. Ch.Count loop
            pragma Loop_Invariant (Safe_Model.Is_Valid_Channel (Result));
            pragma Loop_Invariant
              (Safe_Model.Cap (Result) = Ch.Capacity);
            pragma Loop_Invariant (Result.Length = Pos - 1);
            pragma Loop_Invariant
              ((if Pos = 1 then
                   True
                else
                   (for all I in 1 .. Pos - 1 =>
                      Safe_Model.Element_At (Result, I) =
                        Ch.Buffer (Logical_Index (Ch, I)))));
            Result :=
              Safe_Model.After_Append
                (Result,
                 Ch.Buffer (Logical_Index (Ch, Pos)));
         end loop;
      end if;

      return Result;
   end Model_Of;

   -------------------------------------------------------------------
   --  Construction: create an empty channel
   --
   --  Emission pattern from translation_rules.md Section 4:
   --    ch : Channel(T, N) -> protected object with capacity N
   --  The compiler emits Check_Channel_Capacity_Positive at construction.
   -------------------------------------------------------------------
   function Make (Cap : Capacity_Range) return Channel is
   begin
      --  PO hook: verify capacity is positive.
      Check_Channel_Capacity_Positive (Cap);

      return Channel'(Capacity => Cap,
                      Buffer   => [others => 0],
                      Head     => 1,
                      Tail     => 1,
                      Count    => 0);
   end Make;

   -------------------------------------------------------------------
   --  Send: enqueue an element
   --
   --  Emission pattern:
   --    ch.send(item) -> protected entry call with barrier (Count < Cap)
   --  The compiler emits Check_Channel_Not_Full before the entry call.
   --  In the protected object, the barrier blocks until space is available.
   -------------------------------------------------------------------
   procedure Send
     (Ch   : in out Channel;
      Item : Element_Type)
   is
      Old_Model : constant Safe_Model.Channel_State := Model_Of (Ch)
        with Ghost;
   begin
      --  PO hook: verify channel is not full.
      Check_Channel_Not_Full (Ch.Count, Ch.Capacity);

      --  Enqueue: write element at Tail, advance Tail circularly.
      Ch.Buffer (Ch.Tail) := Item;
      if Ch.Tail = Ch.Capacity then
         Ch.Tail := 1;
      else
         Ch.Tail := Ch.Tail + 1;
      end if;
      Ch.Count := Ch.Count + 1;

      declare
         New_Model : constant Safe_Model.Channel_State := Model_Of (Ch)
           with Ghost;
         Expected  : constant Safe_Model.Channel_State :=
           Safe_Model.After_Append (Old_Model, Item)
           with Ghost;
      begin
         pragma Assert (Safe_Model.Cap (New_Model) = Safe_Model.Cap (Expected));
         pragma Assert (Safe_Model.Len (New_Model) = Safe_Model.Len (Expected));
         pragma Assert
           (for all Pos in 1 .. Safe_Model.Len (Expected) =>
              Safe_Model.Element_At (New_Model, Pos) =
                Safe_Model.Element_At (Expected, Pos));
         Safe_Model.Prove_Same_Channel_State (New_Model, Expected);
         pragma Assert (New_Model = Expected);
      end;
   end Send;

   -------------------------------------------------------------------
   --  Receive: dequeue an element
   --
   --  Emission pattern:
   --    item := ch.receive() -> protected entry call with barrier (Count > 0)
   --  The compiler emits Check_Channel_Not_Empty before the entry call.
   -------------------------------------------------------------------
   procedure Receive
     (Ch   : in out Channel;
      Item : out Element_Type)
   is
      Old_Model : constant Safe_Model.Channel_State := Model_Of (Ch)
        with Ghost;
   begin
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

      pragma Assert (Item = Safe_Model.Front (Old_Model));

      declare
         New_Model : constant Safe_Model.Channel_State := Model_Of (Ch)
           with Ghost;
         Expected  : constant Safe_Model.Channel_State :=
           Safe_Model.After_Remove (Old_Model)
           with Ghost;
      begin
         pragma Assert (Safe_Model.Cap (New_Model) = Safe_Model.Cap (Expected));
         pragma Assert (Safe_Model.Len (New_Model) = Safe_Model.Len (Expected));
         pragma Assert
           ((if Safe_Model.Len (Expected) = 0 then
                True
             else
                (for all Pos in 1 .. Safe_Model.Len (Expected) =>
                   Safe_Model.Element_At (New_Model, Pos) =
                     Safe_Model.Element_At (Expected, Pos))));
         Safe_Model.Prove_Same_Channel_State (New_Model, Expected);
         pragma Assert (New_Model = Expected);
      end;
   end Receive;

end Template_Channel_FIFO;
