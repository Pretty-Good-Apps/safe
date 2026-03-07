with Safe_Frontend.Mir_Model;
with Safe_Frontend.Types;

package Safe_Frontend.Mir_Json is
   package FT renames Safe_Frontend.Types;

   type Load_Result (Success : Boolean := False) is record
      case Success is
         when True =>
            Document : Safe_Frontend.Mir_Model.Mir_Document;
         when False =>
            Message : FT.UString;
      end case;
   end record;

   function Load_File (Path : String) return Load_Result;
end Safe_Frontend.Mir_Json;
