with Safe_Runtime;
use type Safe_Runtime.Wide_Integer;

package body sensor_Average with SPARK_Mode => On is

   function average(data : readings) return reading is
      sum : Safe_Runtime.Wide_Integer := Safe_Runtime.Wide_Integer (0);
   begin
      for I in sensor_Count loop
         sum := (Safe_Runtime.Wide_Integer (sum) + Safe_Runtime.Wide_Integer (data (I)));
      end loop;
      pragma Assert ((Safe_Runtime.Wide_Integer (sum) / Safe_Runtime.Wide_Integer (10)) >= Safe_Runtime.Wide_Integer (reading'First) and then (Safe_Runtime.Wide_Integer (sum) / Safe_Runtime.Wide_Integer (10)) <= Safe_Runtime.Wide_Integer (reading'Last));
      return reading ((Safe_Runtime.Wide_Integer (sum) / Safe_Runtime.Wide_Integer (10)));
   end average;

end sensor_Average;
