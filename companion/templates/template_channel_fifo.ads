--  Verified Emission Template: Bounded Channel FIFO
--
--  Clause: SAFE@468cf72:spec/04-tasks-and-channels.md#4.2.p15:b5b29b0e
--  Clause: SAFE@468cf72:spec/04-tasks-and-channels.md#4.2.p20:8aa1a21e
--  Clause: SAFE@468cf72:spec/04-tasks-and-channels.md#4.3.p27:ef0ce6bd
--  Clause: SAFE@468cf72:spec/04-tasks-and-channels.md#4.3.p28:ea6bd13c
--  Clause: SAFE@468cf72:spec/04-tasks-and-channels.md#4.3.p31:a7297e97
--  Reference: compiler/translation_rules.md Section 4
--  Reference: tests/golden/golden_pipeline/
--
--  Demonstrates the compiler emission pattern for channel operations.
--  In emitted code, channels become protected objects with ceiling
--  priority (see golden_pipeline/). This template verifies the
--  functional invariants the protected object must maintain:
--    - Channel capacity is positive at construction
--    - Send only when not full
--    - Receive only when not empty
--    - FIFO ordering: Receive returns the element at Head
--    - Send writes the element at Tail
--    - Buffer frame: operations only touch the affected slot
--    - Head and Tail advance circularly within 1..Capacity
--
--  The model is sequential (not a protected object) to enable full
--  GNATprove functional verification. The concurrency safety
--  guarantee comes from the Jorvik runtime model (ceiling locking).
--
--  PO hooks exercised: Check_Channel_Capacity_Positive,
--                       Check_Channel_Not_Full,
--                       Check_Channel_Not_Empty

pragma SPARK_Mode (On);
pragma Assertion_Policy (Check);

with Safe_Model;

package Template_Channel_FIFO
  with SPARK_Mode => On
is

   use type Safe_Model.Channel_State;

   Max_Capacity : constant := 16;

   subtype Element_Type is Integer;
   subtype Capacity_Range is Positive range 1 .. Max_Capacity;
   subtype Count_Range is Natural range 0 .. Max_Capacity;
   subtype Index_Range is Positive range 1 .. Max_Capacity;

   type Buffer_Array is array (Index_Range) of Element_Type;

   --  Sequential model of a bounded FIFO channel.
   --  In emitted code, this is a protected object.
   type Channel (Capacity : Capacity_Range) is record
      Buffer : Buffer_Array;
      Head   : Index_Range;
      Tail   : Index_Range;
      Count  : Count_Range;
   end record;

   function Offset_Index
     (Head   : Index_Range;
      Offset : Count_Range;
      Cap    : Capacity_Range) return Index_Range
   is (Index_Range (((Head - 1 + Offset) mod Cap) + 1))
     with Pre => Head <= Cap and then Offset <= Cap;

   --  Structural invariant: Head and Tail remain within 1..Capacity,
   --  Count does not exceed Capacity, and Tail is exactly the slot after
   --  the logical FIFO prefix rooted at Head.
   function Is_Valid (Ch : Channel) return Boolean is
     (Ch.Head <= Ch.Capacity
      and then Ch.Tail <= Ch.Capacity
      and then Ch.Count <= Ch.Capacity
      and then Ch.Tail = Offset_Index (Ch.Head, Ch.Count, Ch.Capacity));

   --  Circular index advancement helper (ghost).
   function Next_Index
     (Idx : Index_Range;
      Cap : Capacity_Range) return Index_Range
   is (if Idx = Cap then 1 else Idx + 1)
     with Ghost,
          Pre => Idx <= Cap;

   --  Construction: create an empty channel.
   function Make (Cap : Capacity_Range) return Channel
     with Post => Is_Valid (Make'Result)
                  and then Make'Result.Count = 0
                  and then Make'Result.Capacity = Cap;

   --  Query helpers.
   function Is_Empty (Ch : Channel) return Boolean is
     (Ch.Count = 0);

   function Is_Full (Ch : Channel) return Boolean is
     (Ch.Count = Ch.Capacity);

   function Length (Ch : Channel) return Count_Range is
     (Ch.Count);

   function Logical_Index
     (Ch  : Channel;
      Pos : Positive) return Index_Range
   is (Offset_Index (Ch.Head, Count_Range (Pos - 1), Ch.Capacity))
     with Ghost,
          Pre => Is_Valid (Ch) and then Pos <= Ch.Count;

   function Model_Of (Ch : Channel) return Safe_Model.Channel_State
     with Ghost,
          Pre => Is_Valid (Ch),
          Post =>
            Safe_Model.Is_Valid_Channel (Model_Of'Result)
            and then Safe_Model.Cap (Model_Of'Result) = Ch.Capacity
            and then Safe_Model.Len (Model_Of'Result) = Ch.Count
            and then
              (if Ch.Count = 0 then
                  True
               else
                  (for all Pos in 1 .. Ch.Count =>
                     Safe_Model.Element_At (Model_Of'Result, Pos) =
                       Ch.Buffer (Logical_Index (Ch, Pos))));

   --  Send: enqueue an element (requires valid + not full).
   --
   --  FIFO property: Item is written at Buffer(Tail).
   --  Frame: all other buffer slots are unchanged.
   --  Tail advances circularly; Head is unchanged.
   procedure Send
     (Ch   : in out Channel;
      Item : Element_Type)
     with Pre  =>
            Is_Valid (Ch)
            and then Ch.Count < Ch.Capacity,
          Post =>
            Is_Valid (Ch)
            and then Ch.Count = Ch.Count'Old + 1
            --  FIFO: Item placed at old Tail position.
            and then Ch.Buffer (Ch.Tail'Old) = Item
            --  Head unchanged by Send.
            and then Ch.Head = Ch.Head'Old
            --  Tail advances circularly.
            and then Ch.Tail =
              Next_Index (Ch.Tail'Old, Ch.Capacity)
            --  Frame: other buffer slots preserved.
            and then (for all I in Index_Range =>
                        (if I /= Ch.Tail'Old then
                           Ch.Buffer (I) =
                             Ch.Buffer'Old (I)))
            and then Model_Of (Ch) =
              Safe_Model.After_Append (Model_Of (Ch'Old), Item);

   --  Receive: dequeue an element (requires valid + not empty).
   --
   --  FIFO property: Item is read from Buffer(Head).
   --  Frame: buffer contents unchanged (slot not cleared).
   --  Head advances circularly; Tail is unchanged.
   procedure Receive
     (Ch   : in out Channel;
      Item : out Element_Type)
     with Pre  =>
            Is_Valid (Ch)
            and then Ch.Count > 0,
          Post =>
            Is_Valid (Ch)
            and then Ch.Count = Ch.Count'Old - 1
            --  FIFO: Item is the element at old Head.
            and then Item = Ch.Buffer'Old (Ch.Head'Old)
            --  Tail unchanged by Receive.
            and then Ch.Tail = Ch.Tail'Old
            --  Head advances circularly.
            and then Ch.Head =
              Next_Index (Ch.Head'Old, Ch.Capacity)
            --  Frame: buffer contents fully preserved.
            and then Ch.Buffer = Ch.Buffer'Old
            and then Item = Safe_Model.Front (Model_Of (Ch'Old))
            and then Model_Of (Ch) =
              Safe_Model.After_Remove (Model_Of (Ch'Old));

end Template_Channel_FIFO;
