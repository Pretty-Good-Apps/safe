pragma SPARK_Mode (On);

package body Safe_Bounded_Strings is
   package body Generic_Bounded_String is
      function To_Bounded (Value : String) return Bounded_String is
         Result : Bounded_String := Empty;
      begin
         Result.Length := Value'Length;
         if Value'Length > 0 then
            Result.Data (1 .. Value'Length) := Value;
         end if;
         return Result;
      end To_Bounded;

      function To_String (Value : Bounded_String) return String is
      begin
         if Value.Length = 0 then
            return "";
         end if;
         return Value.Data (1 .. Value.Length);
      end To_String;

      function Length (Value : Bounded_String) return Natural is
      begin
         return Value.Length;
      end Length;

      function Element (Value : Bounded_String; Index : Positive) return String is
      begin
         return Value.Data (Index .. Index);
      end Element;

      function Slice (Value : Bounded_String; Low, High : Positive) return String is
      begin
         pragma Assert (Low in Value.Data'Range);
         pragma Assert (High in Value.Data'Range);
         return Value.Data (Low .. High);
      end Slice;

   end Generic_Bounded_String;
end Safe_Bounded_Strings;
