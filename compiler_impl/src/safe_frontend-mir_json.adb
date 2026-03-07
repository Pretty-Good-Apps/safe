with GNATCOLL.JSON;

package body Safe_Frontend.Mir_Json is
   package GM renames Safe_Frontend.Mir_Model;

   function Load_File (Path : String) return Load_Result is
      use GNATCOLL.JSON;

      Parsed  : constant Read_Result := Read_File (Path);
      Root    : JSON_Value;
      Format  : JSON_Value;
      Kind    : GM.Mir_Format_Kind;
   begin
      if not Parsed.Success then
         return
           (Success => False,
            Message =>
              FT.To_UString
                (Path
                 & ": invalid JSON: "
                 & Format_Parsing_Error (Parsed.Error)));
      end if;

      Root := Parsed.Value;
      if Root.Kind /= JSON_Object_Type then
         return
           (Success => False,
            Message =>
              FT.To_UString (Path & ": top-level payload must be an object"));
      end if;

      if not Has_Field (Root, "format") then
         return
           (Success => False,
            Message =>
              FT.To_UString (Path & ": expected format mir-v1 or mir-v2"));
      end if;

      Format := Get (Root, "format");
      if Format.Kind /= JSON_String_Type then
         return
           (Success => False,
            Message =>
              FT.To_UString (Path & ": expected format mir-v1 or mir-v2"));
      end if;

      declare
         Value : constant String := Get (Format);
      begin
         if Value = "mir-v1" then
            Kind := GM.Mir_V1;
         elsif Value = "mir-v2" then
            Kind := GM.Mir_V2;
         else
            return
              (Success => False,
               Message =>
                 FT.To_UString (Path & ": expected format mir-v1 or mir-v2"));
         end if;
      end;

      return
        (Success  => True,
         Document => (Format => Kind, Root => Root));
   end Load_File;
end Safe_Frontend.Mir_Json;
