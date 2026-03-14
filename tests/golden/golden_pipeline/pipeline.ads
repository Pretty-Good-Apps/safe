pragma SPARK_Mode (On);

package Pipeline
   with SPARK_Mode => On,
        Initializes => null
is
   type Sample is range 0 .. 10000;
   subtype Raw_Ch_Index is Positive range 1 .. 4;
   subtype Raw_Ch_Count is Natural range 0 .. 4;
   type Raw_Ch_Buffer is array (Raw_Ch_Index) of Sample;
   protected type Raw_Ch_Channel is
      entry Send (Value : in Sample);
      entry Receive (Value : out Sample);
   private
      Buffer : Raw_Ch_Buffer;
      Head   : Raw_Ch_Index := Raw_Ch_Index'First;
      Tail   : Raw_Ch_Index := Raw_Ch_Index'First;
      Count  : Raw_Ch_Count := 0;
   end Raw_Ch_Channel;
   Raw_Ch : Raw_Ch_Channel;

   subtype Filtered_Ch_Index is Positive range 1 .. 4;
   subtype Filtered_Ch_Count is Natural range 0 .. 4;
   type Filtered_Ch_Buffer is array (Filtered_Ch_Index) of Sample;
   protected type Filtered_Ch_Channel is
      entry Send (Value : in Sample);
      entry Receive (Value : out Sample);
   private
      Buffer : Filtered_Ch_Buffer;
      Head   : Filtered_Ch_Index := Filtered_Ch_Index'First;
      Tail   : Filtered_Ch_Index := Filtered_Ch_Index'First;
      Count  : Filtered_Ch_Count := 0;
   end Filtered_Ch_Channel;
   Filtered_Ch : Filtered_Ch_Channel;

   task Producer;
   task Filter;
   task Consumer;

end Pipeline;

