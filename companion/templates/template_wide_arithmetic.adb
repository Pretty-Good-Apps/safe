--  Verified Emission Template: Wide Intermediate Arithmetic + Narrowing
--  See template_wide_arithmetic.ads for clause references.

pragma SPARK_Mode (On);

with Safe_Runtime; use Safe_Runtime;
with Safe_PO;      use Safe_PO;

package body Template_Wide_Arithmetic
  with SPARK_Mode => On
is

   -------------------------------------------------------------------
   --  Pattern 1: Accumulate-and-average
   --
   --  Emission pattern from translation_rules.md Section 8:
   --    1. Lift each Sensor_Value to Wide_Integer
   --    2. Accumulate in Wide_Integer (no overflow possible)
   --    3. Divide (by nonzero literal 10)
   --    4. Narrow the result at the return point
   -------------------------------------------------------------------
   function Average
     (Data : Sensor_Array) return Sensor_Value
   is
      --  Wide intermediate: sum computed in Wide_Integer.
      Sum : Wide_Integer := 0;
   begin
      for I in 1 .. 10 loop
         --  Loop invariant: Sum tracks accumulated values.
         --  Each Data element is in 0..1000, so after I
         --  iterations Sum is in 0 .. I * 1000.
         pragma Loop_Invariant (Sum >= 0);
         pragma Loop_Invariant
           (Sum <= Wide_Integer (I - 1) * 1000);

         --  Lift Data(I) to Wide_Integer and accumulate.
         Sum := Sum + Wide_Integer (Data (I));
      end loop;

      --  Post-loop: Sum is in 0 .. 10_000.
      pragma Assert (Sum >= 0 and then Sum <= 10_000);

      --  Division by nonzero literal 10.
      --  Result is in 0 .. 1000 = Sensor_Value range.
      declare
         Wide_Result : constant Wide_Integer := Sum / 10;
      begin
         pragma Assert
           (Wide_Result >= 0 and then Wide_Result <= 1000);

         --  Narrowing point (return): convert Wide_Integer
         --  to Long_Long_Integer for the PO hook, then
         --  narrow to Sensor_Value at the return statement.
         Narrow_Return
           (Long_Long_Integer (Wide_Result),
            Sensor_Value_Range);

         return Long_Long_Integer (Wide_Result);
      end;
   end Average;

   -------------------------------------------------------------------
   --  Pattern 2: Simple addition with narrowing at assignment
   --
   --  Emission pattern:
   --    1. Lift A and B to Wide_Integer
   --    2. Compute A + B in wide intermediate
   --    3. Narrow at assignment to Result
   -------------------------------------------------------------------
   procedure Add_Clamped
     (A      : Sensor_Value;
      B      : Sensor_Value;
      Result :    out Sensor_Value)
   is
      --  Lift operands to Wide_Integer for computation.
      Wide_Sum : constant Wide_Integer :=
        Wide_Integer (A) + Wide_Integer (B);
   begin
      --  Narrowing point (assignment): convert to
      --  Long_Long_Integer for the PO hook.
      Narrow_Assignment
        (Long_Long_Integer (Wide_Sum),
         Sensor_Value_Range);

      --  Narrow back to Sensor_Value.
      Result := Long_Long_Integer (Wide_Sum);
   end Add_Clamped;

end Template_Wide_Arithmetic;
