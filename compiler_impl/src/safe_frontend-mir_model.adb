package body Safe_Frontend.Mir_Model is
   function Image (Item : Mir_Format_Kind) return String is
   begin
      case Item is
         when Mir_V1 =>
            return "mir-v1";
         when Mir_V2 =>
            return "mir-v2";
      end case;
   end Image;

   function Ok return Validation_Result is
   begin
      return (Success => True);
   end Ok;

   function Error (Message : String) return Validation_Result is
   begin
      return (Success => False, Message => FT.To_UString (Message));
   end Error;
end Safe_Frontend.Mir_Model;
