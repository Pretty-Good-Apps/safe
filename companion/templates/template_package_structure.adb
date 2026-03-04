--  Verified Emission Template: Package Structure Emission
--  See template_package_structure.ads for clause references.

pragma SPARK_Mode (On);

with Safe_PO; use Safe_PO;

package body Template_Package_Structure
  with SPARK_Mode => On
is

   ----------------------------------------------------------------
   --  Pattern 1: Constructor with parameter narrowing
   --
   --  Emission pattern:
   --    Make(v, s) ->
   --      Narrow_Parameter(v, Value_Range);
   --      Narrow_Parameter(s, Scale_Range);
   --      (Value => v, Scale => s)
   ----------------------------------------------------------------
   function Make
     (Value : Integer;
      Scale : Integer) return Measurement
   is
   begin
      --  PO hooks: narrowing at parameter-passing points.
      Narrow_Parameter
        (Long_Long_Integer (Value), Value_Range);
      Narrow_Parameter
        (Long_Long_Integer (Scale), Scale_Range);

      return Measurement'(Value => Value, Scale => Scale);
   end Make;

   ----------------------------------------------------------------
   --  Pattern 2: Single declare block
   --  (interleaved declaration lowering)
   --
   --  Emission pattern (from Safe interleaved decls):
   --    Wide : LLI := LLI(M.Value);
   --    return Wide * LLI(M.Scale);
   --  Lowered to a single declare block in Ada.
   ----------------------------------------------------------------
   function Scaled_Value
     (M : Measurement) return Long_Long_Integer
   is
   begin
      declare
         Wide : constant Long_Long_Integer :=
           Long_Long_Integer (M.Value);
      begin
         return Wide * Long_Long_Integer (M.Scale);
      end;
   end Scaled_Value;

   ----------------------------------------------------------------
   --  Pattern 3: Nested declare blocks (2 levels)
   --
   --  Emission pattern (from Safe interleaved decls):
   --    SA : LLI := LLI(A.Value) * LLI(A.Scale);
   --    SB : LLI := LLI(B.Value) * LLI(B.Scale);
   --    Result := SA + SB;
   --  Lowered to nested declare blocks in Ada.
   ----------------------------------------------------------------
   procedure Combine
     (A, B   : Measurement;
      Result : out Long_Long_Integer)
   is
   begin
      declare
         SA : constant Long_Long_Integer :=
           Long_Long_Integer (A.Value)
           * Long_Long_Integer (A.Scale);
      begin
         declare
            SB : constant Long_Long_Integer :=
              Long_Long_Integer (B.Value)
              * Long_Long_Integer (B.Scale);
         begin
            Result := SA + SB;
         end;
      end;
   end Combine;

end Template_Package_Structure;
