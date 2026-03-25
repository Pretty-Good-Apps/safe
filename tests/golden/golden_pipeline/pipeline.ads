pragma SPARK_Mode (On);

package pipeline
   with SPARK_Mode => On,
        Initializes => (Raw_Ch, Filtered_Ch, Producer, Filter, Consumer)
is
   pragma Elaborate_Body;

   type sample is range 0 .. 10000;
   subtype Raw_Ch_Index is Positive range 1 .. 4;
   subtype Raw_Ch_Count is Natural range 0 .. 4;
   type Raw_Ch_Buffer is array (Raw_Ch_Index) of sample;
   protected type Raw_Ch_Channel with Priority => 10 is
      entry Send (Value : in sample);
      entry Receive (Value : out sample);
      procedure Try_Send (Value : in sample; Success : out Boolean);
      procedure Try_Receive (Value : in out sample; Success : out Boolean);
   private
      Buffer : Raw_Ch_Buffer := (others => sample'First);
      Head   : Raw_Ch_Index := Raw_Ch_Index'First;
      Tail   : Raw_Ch_Index := Raw_Ch_Index'First;
      Count  : Raw_Ch_Count := 0;
   end Raw_Ch_Channel;
   Raw_Ch : Raw_Ch_Channel;

   subtype Filtered_Ch_Index is Positive range 1 .. 4;
   subtype Filtered_Ch_Count is Natural range 0 .. 4;
   type Filtered_Ch_Buffer is array (Filtered_Ch_Index) of sample;
   protected type Filtered_Ch_Channel with Priority => 10 is
      entry Send (Value : in sample);
      entry Receive (Value : out sample);
      procedure Try_Send (Value : in sample; Success : out Boolean);
      procedure Try_Receive (Value : in out sample; Success : out Boolean);
   private
      Buffer : Filtered_Ch_Buffer := (others => sample'First);
      Head   : Filtered_Ch_Index := Filtered_Ch_Index'First;
      Tail   : Filtered_Ch_Index := Filtered_Ch_Index'First;
      Count  : Filtered_Ch_Count := 0;
   end Filtered_Ch_Channel;
   Filtered_Ch : Filtered_Ch_Channel;

   task Producer with Priority => 10;
   task Filter with Priority => 10;
   task Consumer with Priority => 10;

end pipeline;
