with Safe_Frontend.Mir_Model;

package Safe_Frontend.Builtin_Types is
   package GM renames Safe_Frontend.Mir_Model;

   subtype Target_Bits_Type is Positive
     with Static_Predicate => Target_Bits_Type in 32 | 64;

   function Is_Valid_Target_Bits (Value : Positive) return Boolean;
   function Integer_Type (Target_Bits : Target_Bits_Type := 64) return GM.Type_Descriptor;
   function Boolean_Type return GM.Type_Descriptor;
   function Character_Type return GM.Type_Descriptor;
   function String_Type return GM.Type_Descriptor;
   function Result_Type return GM.Type_Descriptor;
   function Binary_Type (Bit_Width : Positive) return GM.Type_Descriptor;
   function Float_Type (With_Analysis_Metadata : Boolean := False) return GM.Type_Descriptor;
   function Long_Float_Type (With_Analysis_Metadata : Boolean := False) return GM.Type_Descriptor;
   function Duration_Type (With_Analysis_Metadata : Boolean := False) return GM.Type_Descriptor;
end Safe_Frontend.Builtin_Types;
