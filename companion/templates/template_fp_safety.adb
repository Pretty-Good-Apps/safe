--  Verified Emission Template: Floating-Point Safety
--  See template_fp_safety.ads for clause references.

pragma SPARK_Mode (On);

with Safe_PO; use Safe_PO;

package body Template_FP_Safety
  with SPARK_Mode => On
is

   -------------------------------------------------------------------
   --  Pattern: Not-NaN check at narrowing point
   --
   --  Emission pattern from translation_rules.md Section 8.4:
   --    At each FP narrowing point, if the value may be NaN, the
   --    compiler emits FP_Not_NaN(V) to assert V = V.
   -------------------------------------------------------------------
   function Narrow_Not_NaN (V : Long_Float) return Long_Float is
   begin
      --  PO hook: verify value is not NaN.
      FP_Not_NaN (V);

      return V;
   end Narrow_Not_NaN;

   -------------------------------------------------------------------
   --  Pattern: Finite check at narrowing point
   --
   --  Emission pattern: FP_Not_NaN + FP_Not_Infinity to ensure
   --  the value is a finite number before narrowing.
   -------------------------------------------------------------------
   function Narrow_Finite (V : Long_Float) return Long_Float is
   begin
      --  PO hook: verify value is not NaN.
      FP_Not_NaN (V);

      --  PO hook: verify value is finite (not infinity).
      FP_Not_Infinity (V);

      return V;
   end Narrow_Finite;

   -------------------------------------------------------------------
   --  Pattern: Safe floating-point division
   --
   --  Emission pattern: the compiler delegates to FP_Safe_Div which
   --  requires both operands to be finite and the divisor nonzero.
   --  The justified float overflow (A-05) is inherited from
   --  Safe_PO.FP_Safe_Div — no template-specific annotation needed.
   -------------------------------------------------------------------
   procedure Safe_FP_Divide
     (X : Long_Float;
      Y : Long_Float;
      R : out Long_Float)
   is
   begin
      --  PO hook: safe floating-point division.
      FP_Safe_Div (X, Y, R);
   end Safe_FP_Divide;

   -------------------------------------------------------------------
   --  Pattern: Compound operation with intermediate narrowing
   --
   --  Models: result := narrow((A + B) / C)
   --  Steps:
   --    1. Compute intermediate sum (A + B)
   --    2. Check intermediate sum is finite
   --    3. Perform safe division
   --    4. Result inherits proof from FP_Safe_Div
   -------------------------------------------------------------------
   procedure Compute_And_Narrow
     (A : Long_Float;
      B : Long_Float;
      C : Long_Float;
      R : out Long_Float)
   is
      Sum : Long_Float;
   begin
      --  Step 1: Compute intermediate sum.
      Sum := A + B;

      --  Step 2: Narrow the intermediate — verify not NaN.
      FP_Not_NaN (Sum);

      --  Step 3: Narrow the intermediate — verify finite.
      FP_Not_Infinity (Sum);

      --  Step 4: Safe division of the narrowed intermediate.
      FP_Safe_Div (Sum, C, R);
   end Compute_And_Narrow;

end Template_FP_Safety;
