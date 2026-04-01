with Safe_Frontend.Check_Model;
with Safe_Frontend.Types;

package Safe_Frontend.Check_Resolve is
   package CM renames Safe_Frontend.Check_Model;
   package FT renames Safe_Frontend.Types;

   function Resolve
     (Unit        : CM.Parsed_Unit;
      Search_Dirs : FT.UString_Vectors.Vector := FT.UString_Vectors.Empty_Vector;
      Target_Bits : Positive := 64)
      return CM.Resolve_Result;
end Safe_Frontend.Check_Resolve;
