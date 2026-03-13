with Safe_Frontend.Check_Model;
with Safe_Frontend.Mir_Bronze;

package Safe_Frontend.Check_Emit is
   package CM renames Safe_Frontend.Check_Model;
   package MB renames Safe_Frontend.Mir_Bronze;

   function Ast_Json
     (Parsed   : CM.Parsed_Unit;
      Resolved : CM.Resolved_Unit) return String;

   function Typed_Json
     (Parsed   : CM.Parsed_Unit;
      Resolved : CM.Resolved_Unit) return String;

   function Interface_Json
     (Parsed   : CM.Parsed_Unit;
      Resolved : CM.Resolved_Unit;
      Bronze   : MB.Bronze_Result) return String;
end Safe_Frontend.Check_Emit;
