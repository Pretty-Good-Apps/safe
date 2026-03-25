with Safe_Frontend.Types;

package Safe_Frontend.Driver is
   package FT renames Safe_Frontend.Types;

   function Run_Lex (Path : String) return Integer;
   function Run_Validate_Mir (Path : String) return Integer;
   function Run_Analyze_Mir
     (Path      : String;
      Diag_Json : Boolean := False) return Integer;
   function Run_Ast
     (Path          : String;
      Search_Dirs   : FT.UString_Vectors.Vector := FT.UString_Vectors.Empty_Vector)
      return Integer;
   function Run_Check
     (Path      : String;
      Diag_Json : Boolean := False;
      Search_Dirs : FT.UString_Vectors.Vector := FT.UString_Vectors.Empty_Vector)
      return Integer;
   function Run_Emit
     (Path          : String;
      Out_Dir       : String;
      Interface_Dir : String;
      Ada_Out_Dir   : String := "";
      Search_Dirs   : FT.UString_Vectors.Vector := FT.UString_Vectors.Empty_Vector)
      return Integer;
end Safe_Frontend.Driver;
