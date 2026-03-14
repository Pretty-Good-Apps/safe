with Safe_Runtime;
use type Safe_Runtime.Wide_Integer;

package body Pipeline is

   protected body Raw_Ch_Channel is
      entry Send (Value : in Sample)
         when Count < 4 is
      begin
         Buffer (Tail) := Value;
         if Tail = Raw_Ch_Index'Last then
            Tail := Raw_Ch_Index'First;
         else
            Tail := Raw_Ch_Index'Succ (Tail);
         end if;
         Count := Count + 1;
      end Send;

      entry Receive (Value : out Sample)
         when Count > 0 is
      begin
         Value := Buffer (Head);
         if Head = Raw_Ch_Index'Last then
            Head := Raw_Ch_Index'First;
         else
            Head := Raw_Ch_Index'Succ (Head);
         end if;
         Count := Count - 1;
      end Receive;
   end Raw_Ch_Channel;

   protected body Filtered_Ch_Channel is
      entry Send (Value : in Sample)
         when Count < 4 is
      begin
         Buffer (Tail) := Value;
         if Tail = Filtered_Ch_Index'Last then
            Tail := Filtered_Ch_Index'First;
         else
            Tail := Filtered_Ch_Index'Succ (Tail);
         end if;
         Count := Count + 1;
      end Send;

      entry Receive (Value : out Sample)
         when Count > 0 is
      begin
         Value := Buffer (Head);
         if Head = Filtered_Ch_Index'Last then
            Head := Filtered_Ch_Index'First;
         else
            Head := Filtered_Ch_Index'Succ (Head);
         end if;
         Count := Count - 1;
      end Receive;
   end Filtered_Ch_Channel;

   task body Producer is
      Counter : Safe_Runtime.Wide_Integer := Safe_Runtime.Wide_Integer (0);
   begin
      loop
         Raw_Ch.Send (Sample (Safe_Runtime.Wide_Integer (Counter)));
         if (Counter < 10_000) then
            Counter := (Safe_Runtime.Wide_Integer (Counter) + Safe_Runtime.Wide_Integer (1));
         else
            Counter := Safe_Runtime.Wide_Integer (0);
         end if;
      end loop;
   end Producer;

   task body Filter is
      Input : Sample;
      Output : Safe_Runtime.Wide_Integer;
   begin
      loop
         Raw_Ch.Receive (Input);
         Output := (Safe_Runtime.Wide_Integer (Input) / Safe_Runtime.Wide_Integer (2));
         Filtered_Ch.Send (Sample (Safe_Runtime.Wide_Integer (Output)));
      end loop;
   end Filter;

   task body Consumer is
      Data : Sample;
      Sum : Safe_Runtime.Wide_Integer := Safe_Runtime.Wide_Integer (0);
   begin
      loop
         Filtered_Ch.Receive (Data);
         Sum := (Safe_Runtime.Wide_Integer (Sum) + Safe_Runtime.Wide_Integer (Natural (Data)));
         if (Sum > 1_000_000) then
            Sum := Safe_Runtime.Wide_Integer (0);
         end if;
      end loop;
   end Consumer;

end Pipeline;
