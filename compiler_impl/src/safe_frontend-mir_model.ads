with GNATCOLL.JSON;
with Safe_Frontend.Types;

package Safe_Frontend.Mir_Model is
   package FT renames Safe_Frontend.Types;

   type Mir_Format_Kind is (Mir_V1, Mir_V2);

   function Image (Item : Mir_Format_Kind) return String;

   type Mir_Document is record
      Format : Mir_Format_Kind := Mir_V1;
      Root   : GNATCOLL.JSON.JSON_Value := GNATCOLL.JSON.Create;
   end record;

   type Validation_Result (Success : Boolean := False) is record
      case Success is
         when True =>
            null;
         when False =>
            Message : FT.UString;
      end case;
   end record;

   function Ok return Validation_Result;
   function Error (Message : String) return Validation_Result;
end Safe_Frontend.Mir_Model;
