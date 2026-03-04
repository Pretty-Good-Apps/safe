--  Verified Emission Template: Borrow and Observe Ownership Patterns
--  See template_borrow_observe.ads for clause references.

pragma SPARK_Mode (On);

with Safe_Model; use Safe_Model;
with Safe_PO;    use Safe_PO;

package body Template_Borrow_Observe
  with SPARK_Mode => On
is

   --  Ghost helper: map Boolean flags to Ownership_State for PO hooks.
   --  Priority: Borrowed > Observed > Moved > Null > Owned.
   function To_State (P : Ptr_Model) return Ownership_State
   is (if P.Is_Borrowed then Borrowed
       elsif P.Is_Observed then Observed
       elsif P.Is_Moved then Moved
       elsif P.Is_Null then Null_State
       else Owned)
     with Ghost;

   -------------------------------------------------------------------
   --  Pattern: Exclusive borrow scope
   --
   --  Emission pattern from translation_rules.md Section 7:
   --    1. Assert lender is owned (Check_Borrow_Exclusive)
   --    2. Set lender to Borrowed (frozen)
   --    3. Modify through borrower
   --    4. Restore lender to Owned
   -------------------------------------------------------------------
   procedure Borrow_And_Modify
     (Lender    : in out Ptr_Model;
      New_Value : Integer;
      Result    : out Integer)
   is
   begin
      --  PO hook: verify lender is owned before borrow.
      Check_Borrow_Exclusive (To_State (Lender));

      --  Enter borrow scope: freeze lender.
      Lender.Is_Borrowed := True;
      pragma Assert (Is_Consistent (Lender));  --  Borrowed

      --  Modify through borrower (models: *borrower = New_Value).
      Lender.Value := New_Value;
      Result := New_Value;

      --  Exit borrow scope: restore lender to Owned.
      Lender.Is_Borrowed := False;
      pragma Assert (Is_Consistent (Lender));  --  Owned
   end Borrow_And_Modify;

   -------------------------------------------------------------------
   --  Pattern: Observe scope
   --
   --  Emission pattern from translation_rules.md Section 7:
   --    1. Assert lender is owned (Check_Observe_Shared)
   --    2. Set lender to Observed
   --    3. Read through observer
   --    4. Restore lender to Owned
   -------------------------------------------------------------------
   procedure Observe_And_Read
     (Lender : in out Ptr_Model;
      Result : out Integer)
   is
   begin
      --  PO hook: verify lender is owned or observed.
      Check_Observe_Shared (To_State (Lender));

      --  Enter observe scope.
      Lender.Is_Observed := True;
      pragma Assert (Is_Consistent (Lender));  --  Observed

      --  Read through observer (models: result = *observer).
      Result := Lender.Value;

      --  Exit observe scope: restore lender to Owned.
      Lender.Is_Observed := False;
      pragma Assert (Is_Consistent (Lender));  --  Owned
   end Observe_And_Read;

   -------------------------------------------------------------------
   --  Pattern: Nested observe scopes (two observers)
   --
   --  The first Check_Observe_Shared is called when lender is Owned.
   --  The second Check_Observe_Shared is called when lender is already
   --  Observed, exercising the Pre => State = Owned or else State = Observed
   --  disjunction on the Observed branch.
   -------------------------------------------------------------------
   procedure Two_Observers
     (Lender : in out Ptr_Model;
      R1     : out Integer;
      R2     : out Integer)
   is
   begin
      --  PO hook: verify lender is owned (first observer).
      Check_Observe_Shared (To_State (Lender));

      --  Enter first observe scope.
      Lender.Is_Observed := True;
      pragma Assert (Is_Consistent (Lender));  --  Observed

      --  Read through first observer.
      R1 := Lender.Value;

      --  PO hook: verify lender is observed (second observer).
      --  This exercises the Observed -> Observed transition.
      Check_Observe_Shared (To_State (Lender));

      --  Read through second observer.
      R2 := Lender.Value;

      --  Exit both observe scopes: restore lender to Owned.
      Lender.Is_Observed := False;
      pragma Assert (Is_Consistent (Lender));  --  Owned
   end Two_Observers;

end Template_Borrow_Observe;
