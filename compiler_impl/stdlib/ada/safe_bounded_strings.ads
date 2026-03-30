pragma SPARK_Mode (On);

package Safe_Bounded_Strings
  with Pure
is
   generic
      Capacity : Positive;
   package Generic_Bounded_String
     with SPARK_Mode => On
   is
      type Bounded_String is private;

      Empty : constant Bounded_String;

      function To_Bounded (Value : String) return Bounded_String
        with Pre => Value'Length <= Capacity;

      function To_String (Value : Bounded_String) return String;

      function Length (Value : Bounded_String) return Natural;

      function "=" (Left, Right : Bounded_String) return Boolean;
      function "=" (Left : Bounded_String; Right : String) return Boolean;
      function "=" (Left : String; Right : Bounded_String) return Boolean;

   private
      type Bounded_String is record
         Data   : String (1 .. Capacity) := (others => ' ');
         Length : Natural range 0 .. Capacity := 0;
      end record;

      Empty : constant Bounded_String :=
        (Data => (others => ' '), Length => 0);
   end Generic_Bounded_String;
end Safe_Bounded_Strings;
