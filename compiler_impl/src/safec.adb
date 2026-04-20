with Ada.Command_Line;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Safe_Frontend;
with Safe_Frontend.Driver;
with Safe_Frontend.Types;

procedure Safec is
   package FT renames Safe_Frontend.Types;

   function Usage return Integer is
   begin
      Ada.Text_IO.Put_Line ("usage:");
      Ada.Text_IO.Put_Line ("  safec lex <file.safe>");
      Ada.Text_IO.Put_Line ("  safec validate-mir <file.mir.json>");
      Ada.Text_IO.Put_Line ("  safec analyze-mir <file.mir.json>");
      Ada.Text_IO.Put_Line ("  safec analyze-mir --diag-json <file.mir.json>");
      Ada.Text_IO.Put_Line ("  safec ast [--target-bits 32|64] <file.safe> [--interface-search-dir <dir>]...");
      Ada.Text_IO.Put_Line ("  safec check [--target-bits 32|64] <file.safe> [--interface-search-dir <dir>]...");
      Ada.Text_IO.Put_Line ("  safec check --diag-json [--target-bits 32|64] <file.safe> [--interface-search-dir <dir>]...");
      Ada.Text_IO.Put_Line
        ("  safec emit [--target-bits 32|64] <file.safe> --out-dir <dir> --interface-dir <dir> [--ada-out-dir <dir>] [--interface-search-dir <dir>]...");
      return Safe_Frontend.Exit_Usage;
   end Usage;

   function Argument (Index : Positive) return String is
   begin
      return Ada.Command_Line.Argument (Index);
   end Argument;

   function Has_Prefix (Value : String) return Boolean is
   begin
      return Value'Length > 0 and then Value (Value'First) = '-';
   end Has_Prefix;

   procedure Parse_Source_Args
     (Start_Index  : Positive;
      Allow_Diag   : Boolean;
      Need_Emit    : Boolean;
      Path         : out FT.UString;
      Diag_Json    : out Boolean;
      Out_Dir      : out FT.UString;
      Interface_Dir : out FT.UString;
      Ada_Out_Dir  : out FT.UString;
      Search_Dirs  : out FT.UString_Vectors.Vector;
      Target_Bits  : out Positive;
      Ok           : out Boolean)
   is
      Index : Natural := Start_Index;
   begin
      Path := FT.To_UString ("");
      Diag_Json := False;
      Out_Dir := FT.To_UString ("");
      Interface_Dir := FT.To_UString ("");
      Ada_Out_Dir := FT.To_UString ("");
      Search_Dirs.Clear;
      Target_Bits := 64;
      Ok := True;

      while Index <= Ada.Command_Line.Argument_Count loop
         declare
            Item : constant String := Argument (Positive (Index));
         begin
            if Item = "--diag-json" and then Allow_Diag then
               if Diag_Json then
                  Ok := False;
                  return;
               end if;
               Diag_Json := True;
               Index := Index + 1;
            elsif Item = "--target-bits" then
               if Index = Ada.Command_Line.Argument_Count then
                  Ok := False;
                  return;
               end if;
               declare
                  Value : constant String := Argument (Positive (Index + 1));
               begin
                  if Value = "32" then
                     Target_Bits := 32;
                  elsif Value = "64" then
                     Target_Bits := 64;
                  else
                     Ok := False;
                     return;
                  end if;
               end;
               Index := Index + 2;
            elsif Item = "--interface-search-dir" then
               if Index = Ada.Command_Line.Argument_Count then
                  Ok := False;
                  return;
               end if;
               Search_Dirs.Append (FT.To_UString (Argument (Positive (Index + 1))));
               Index := Index + 2;
            elsif Need_Emit and then Item = "--out-dir" then
               if Index = Ada.Command_Line.Argument_Count or else FT.To_String (Out_Dir)'Length > 0 then
                  Ok := False;
                  return;
               end if;
               Out_Dir := FT.To_UString (Argument (Positive (Index + 1)));
               Index := Index + 2;
            elsif Need_Emit and then Item = "--interface-dir" then
               if Index = Ada.Command_Line.Argument_Count or else FT.To_String (Interface_Dir)'Length > 0 then
                  Ok := False;
                  return;
               end if;
               Interface_Dir := FT.To_UString (Argument (Positive (Index + 1)));
               Index := Index + 2;
            elsif Need_Emit and then Item = "--ada-out-dir" then
               if Index = Ada.Command_Line.Argument_Count or else FT.To_String (Ada_Out_Dir)'Length > 0 then
                  Ok := False;
                  return;
               end if;
               Ada_Out_Dir := FT.To_UString (Argument (Positive (Index + 1)));
               Index := Index + 2;
            elsif Has_Prefix (Item) then
               Ok := False;
               return;
            elsif FT.To_String (Path)'Length = 0 then
               Path := FT.To_UString (Item);
               Index := Index + 1;
            else
               Ok := False;
               return;
            end if;
         end;
      end loop;

      if FT.To_String (Path)'Length = 0 then
         Ok := False;
      elsif Need_Emit
        and then
          (FT.To_String (Out_Dir)'Length = 0 or else FT.To_String (Interface_Dir)'Length = 0)
      then
         Ok := False;
      end if;
   end Parse_Source_Args;

   Exit_Code : Integer := Safe_Frontend.Exit_Usage;
begin
   if Ada.Command_Line.Argument_Count < 2 then
      Exit_Code := Usage;
      GNAT.OS_Lib.OS_Exit (Exit_Code);
   end if;

   declare
      Command : constant String := Argument (1);
   begin
      if Command = "lex" and then Ada.Command_Line.Argument_Count = 2 then
         Exit_Code := Safe_Frontend.Driver.Run_Lex (Argument (2));
      elsif Command = "validate-mir"
        and then Ada.Command_Line.Argument_Count = 2
      then
         Exit_Code := Safe_Frontend.Driver.Run_Validate_Mir (Argument (2));
      elsif Command = "analyze-mir" then
         if Ada.Command_Line.Argument_Count = 2 then
            Exit_Code := Safe_Frontend.Driver.Run_Analyze_Mir (Argument (2));
         elsif Ada.Command_Line.Argument_Count = 3
           and then Argument (2) = "--diag-json"
         then
            Exit_Code :=
              Safe_Frontend.Driver.Run_Analyze_Mir
                (Path      => Argument (3),
                 Diag_Json => True);
         else
            Exit_Code := Usage;
         end if;
      elsif Command = "ast" then
         declare
            Path         : FT.UString;
            Diag_Json    : Boolean;
            Out_Dir      : FT.UString;
            Interface_Dir : FT.UString;
            Ada_Out_Dir  : FT.UString;
            Search_Dirs  : FT.UString_Vectors.Vector;
            Target_Bits  : Positive;
            Ok           : Boolean;
         begin
            Parse_Source_Args
              (Start_Index   => 2,
               Allow_Diag    => False,
               Need_Emit     => False,
               Path          => Path,
               Diag_Json     => Diag_Json,
               Out_Dir       => Out_Dir,
               Interface_Dir => Interface_Dir,
               Ada_Out_Dir   => Ada_Out_Dir,
               Search_Dirs   => Search_Dirs,
               Target_Bits   => Target_Bits,
               Ok            => Ok);
            pragma Unreferenced (Diag_Json, Out_Dir, Interface_Dir, Ada_Out_Dir);
            if not Ok then
               Exit_Code := Usage;
            else
               Exit_Code :=
                 Safe_Frontend.Driver.Run_Ast
                   (Path        => FT.To_String (Path),
                    Search_Dirs => Search_Dirs,
                    Target_Bits => Target_Bits);
            end if;
         end;
      elsif Command = "check" then
         declare
            Path         : FT.UString;
            Diag_Json    : Boolean;
            Out_Dir      : FT.UString;
            Interface_Dir : FT.UString;
            Ada_Out_Dir  : FT.UString;
            Search_Dirs  : FT.UString_Vectors.Vector;
            Target_Bits  : Positive;
            Ok           : Boolean;
         begin
            Parse_Source_Args
              (Start_Index   => 2,
               Allow_Diag    => True,
               Need_Emit     => False,
               Path          => Path,
               Diag_Json     => Diag_Json,
               Out_Dir       => Out_Dir,
               Interface_Dir => Interface_Dir,
               Ada_Out_Dir   => Ada_Out_Dir,
               Search_Dirs   => Search_Dirs,
               Target_Bits   => Target_Bits,
               Ok            => Ok);
            pragma Unreferenced (Out_Dir, Interface_Dir, Ada_Out_Dir);
            if not Ok then
               Exit_Code := Usage;
            else
               Exit_Code :=
                 Safe_Frontend.Driver.Run_Check
                   (Path        => FT.To_String (Path),
                    Diag_Json   => Diag_Json,
                    Search_Dirs => Search_Dirs,
                    Target_Bits => Target_Bits);
            end if;
         end;
      elsif Command = "emit" then
         declare
            Path         : FT.UString;
            Diag_Json    : Boolean;
            Out_Dir      : FT.UString;
            Interface_Dir : FT.UString;
            Ada_Out_Dir  : FT.UString;
            Search_Dirs  : FT.UString_Vectors.Vector;
            Target_Bits  : Positive;
            Ok           : Boolean;
         begin
            Parse_Source_Args
              (Start_Index   => 2,
               Allow_Diag    => False,
               Need_Emit     => True,
               Path          => Path,
               Diag_Json     => Diag_Json,
               Out_Dir       => Out_Dir,
               Interface_Dir => Interface_Dir,
               Ada_Out_Dir   => Ada_Out_Dir,
               Search_Dirs   => Search_Dirs,
               Target_Bits   => Target_Bits,
               Ok            => Ok);
            pragma Unreferenced (Diag_Json);
            if not Ok then
               Exit_Code := Usage;
            else
               Exit_Code :=
                 Safe_Frontend.Driver.Run_Emit
                   (Path          => FT.To_String (Path),
                    Out_Dir       => FT.To_String (Out_Dir),
                    Interface_Dir => FT.To_String (Interface_Dir),
                    Ada_Out_Dir   => FT.To_String (Ada_Out_Dir),
                    Search_Dirs   => Search_Dirs,
                    Target_Bits   => Target_Bits);
            end if;
         end;
      else
         Exit_Code := Usage;
      end if;
   end;

   GNAT.OS_Lib.OS_Exit (Exit_Code);
end Safec;
