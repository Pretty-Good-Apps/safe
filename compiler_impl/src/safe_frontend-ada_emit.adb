with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Containers.Indefinite_Vectors;
with Ada.Strings.Unbounded;

package body Safe_Frontend.Ada_Emit is
   package SU renames Ada.Strings.Unbounded;

   use type Ada.Containers.Count_Type;
   use type CM.Expr_Access;
   use type CM.Expr_Kind;
   use type CM.Statement_Access;
   use type CM.Statement_Kind;
   use type CM.Discrete_Range_Kind;
   use type CM.Select_Arm_Kind;
   use type FT.UString;

   Indent_Width : constant Positive := 3;

   Emitter_Unsupported : exception;
   Emitter_Internal    : exception;

   Runtime_Template : constant String :=
     "--  Safe Language Runtime Type Definitions" & ASCII.LF
     & "--" & ASCII.LF
     & "--  Clause: SAFE@468cf72:spec/02-restrictions.md#2.8.1.p126:812b54a8" & ASCII.LF
     & "--  Reference: compiler/translation_rules.md Section 8.1" & ASCII.LF
     & "--" & ASCII.LF
     & "--  Every integer arithmetic expression in the Safe language is evaluated" & ASCII.LF
     & "--  in a mathematical integer type. The compiler emits all intermediate" & ASCII.LF
     & "--  computations using Wide_Integer, which provides at least 64-bit signed" & ASCII.LF
     & "--  range. Range checks occur only at narrowing points: assignment," & ASCII.LF
     & "--  parameter passing, return, type conversion, and type annotation." & ASCII.LF
     & ASCII.LF
     & "pragma SPARK_Mode (On);" & ASCII.LF
     & ASCII.LF
     & "package Safe_Runtime" & ASCII.LF
     & "  with Pure" & ASCII.LF
     & "is" & ASCII.LF
     & ASCII.LF
     & "   type Wide_Integer is range -(2 ** 63) .. (2 ** 63 - 1);" & ASCII.LF
     & "   --  Wide intermediate type for all integer arithmetic in emitted code." & ASCII.LF
     & "   --  Corresponds to the mathematical integer semantics of the Safe language." & ASCII.LF
     & "   --  The compiler lifts all integer operands to Wide_Integer before" & ASCII.LF
     & "   --  performing arithmetic, then narrows at the five defined narrowing" & ASCII.LF
     & "   --  points (assignment, parameter, return, conversion, annotation)." & ASCII.LF
     & ASCII.LF
     & "end Safe_Runtime;" & ASCII.LF;

   Gnat_Adc_Contents : constant String :=
     "pragma Partition_Elaboration_Policy(Sequential);" & ASCII.LF
     & "pragma Profile(Jorvik);" & ASCII.LF;

   type Cleanup_Item is record
      Name      : FT.UString := FT.To_UString ("");
      Type_Name : FT.UString := FT.To_UString ("");
   end record;

   package Cleanup_Item_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type   => Positive,
      Element_Type => Cleanup_Item);

   type Cleanup_Frame is record
      Items : Cleanup_Item_Vectors.Vector;
   end record;

   package Cleanup_Frame_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type   => Positive,
      Element_Type => Cleanup_Frame);

   type Emit_State is record
      Needs_Safe_Runtime : Boolean := False;
      Needs_Gnat_Adc     : Boolean := False;
      Needs_Unchecked_Deallocation : Boolean := False;
      Wide_Local_Names   : FT.UString_Vectors.Vector;
      Unsupported_Span   : FT.Source_Span := FT.Null_Span;
      Unsupported_Message : FT.UString := FT.To_UString ("");
      Cleanup_Stack      : Cleanup_Frame_Vectors.Vector;
   end record;

   procedure Raise_Internal (Message : String);
   pragma No_Return (Raise_Internal);
   procedure Raise_Unsupported
     (State   : in out Emit_State;
      Span    : FT.Source_Span;
      Message : String);

   function Has_Text (Item : FT.UString) return Boolean;
   function Trim_Image (Value : Long_Long_Integer) return String;
   function Trim_Wide_Image (Value : CM.Wide_Integer) return String;
   function Indentation (Depth : Natural) return String;
   procedure Append_Line
     (Buffer : in out SU.Unbounded_String;
      Text   : String := "";
      Depth  : Natural := 0);
   function Join_Names (Items : FT.UString_Vectors.Vector) return String;
   function Contains_Name
     (Items : FT.UString_Vectors.Vector;
      Name  : String) return Boolean;
   procedure Add_Wide_Name
     (State : in out Emit_State;
      Name  : String);
   function Is_Wide_Name
     (State : Emit_State;
      Name  : String) return Boolean;
   function Names_Use_Wide_Storage
     (State : Emit_State;
      Names : FT.UString_Vectors.Vector) return Boolean;
   procedure Restore_Wide_Names
     (State           : in out Emit_State;
      Previous_Length : Ada.Containers.Count_Type);
   procedure Push_Cleanup_Frame (State : in out Emit_State);
   procedure Pop_Cleanup_Frame (State : in out Emit_State);
   procedure Add_Cleanup_Item
     (State     : in out Emit_State;
      Name      : String;
      Type_Name : String);
   procedure Register_Cleanup_Items
     (State        : in out Emit_State;
      Declarations : CM.Resolved_Object_Decl_Vectors.Vector);
   procedure Register_Cleanup_Items
     (State        : in out Emit_State;
      Declarations : CM.Object_Decl_Vectors.Vector);
   procedure Render_Cleanup_Item
     (Buffer : in out SU.Unbounded_String;
      Item   : Cleanup_Item;
      Depth  : Natural);
   procedure Render_Active_Cleanup
     (Buffer : in out SU.Unbounded_String;
      State  : Emit_State;
      Depth  : Natural);
   function Starts_With (Text : String; Prefix : String) return Boolean;
   function Normalize_Aspect_Name
     (Subprogram_Name : String;
      Raw_Name        : String) return String;

   function Lookup_Type
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Name     : String) return GM.Type_Descriptor;
   function Has_Type
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Name     : String) return Boolean;
   function Is_Integer_Type
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Name     : String) return Boolean;
   function Is_Integer_Type (Info : GM.Type_Descriptor) return Boolean;
   function Is_Access_Type (Info : GM.Type_Descriptor) return Boolean;
   function Is_Owner_Access (Info : GM.Type_Descriptor) return Boolean;
   function Render_Type_Name (Info : GM.Type_Descriptor) return String;
   function Render_Type_Name
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Name     : String) return String;
   function Lookup_Channel
     (Unit : CM.Resolved_Unit;
      Name : String) return CM.Resolved_Channel_Decl;
   function Render_Type_Decl
     (Type_Item : GM.Type_Descriptor;
      State     : in out Emit_State) return String;
   function Render_Object_Decl_Text
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      State    : in out Emit_State;
      Decl     : CM.Resolved_Object_Decl) return String;
   function Render_Object_Decl_Text
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      State    : in out Emit_State;
      Decl     : CM.Object_Decl) return String;

   function Render_Expr
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Expr     : CM.Expr_Access;
      State    : in out Emit_State) return String;
   function Render_Wide_Expr
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Expr     : CM.Expr_Access;
      State    : in out Emit_State) return String;
   function Uses_Wide_Arithmetic
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Expr     : CM.Expr_Access) return Boolean;
   function Uses_Wide_Value
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      State    : Emit_State;
      Expr     : CM.Expr_Access) return Boolean;
   function Render_Channel_Send_Value
     (Unit         : CM.Resolved_Unit;
      Document     : GM.Mir_Document;
      State        : in out Emit_State;
      Channel_Expr : CM.Expr_Access;
      Value        : CM.Expr_Access) return String;
   procedure Collect_Wide_Locals
     (Unit         : CM.Resolved_Unit;
      Document     : GM.Mir_Document;
      State        : in out Emit_State;
      Declarations : CM.Resolved_Object_Decl_Vectors.Vector;
      Statements   : CM.Statement_Access_Vectors.Vector);
   procedure Collect_Wide_Locals
     (Unit         : CM.Resolved_Unit;
      Document     : GM.Mir_Document;
      State        : in out Emit_State;
      Declarations : CM.Object_Decl_Vectors.Vector;
      Statements   : CM.Statement_Access_Vectors.Vector);

   procedure Render_Statements
     (Buffer     : in out SU.Unbounded_String;
      Unit       : CM.Resolved_Unit;
      Document   : GM.Mir_Document;
      Statements : CM.Statement_Access_Vectors.Vector;
      State      : in out Emit_State;
      Depth      : Natural;
      Return_Type : String := "");

   function Render_Subprogram_Params
     (Unit       : CM.Resolved_Unit;
      Document   : GM.Mir_Document;
      Params     : CM.Symbol_Vectors.Vector) return String;
   function Render_Subprogram_Return
     (Subprogram : CM.Resolved_Subprogram) return String;
   function Render_Initializes_Aspect (Bronze : MB.Bronze_Result) return String;
   function Render_Subprogram_Aspects
     (Subprogram : CM.Resolved_Subprogram;
      Bronze     : MB.Bronze_Result) return String;
   procedure Render_Channel_Spec
     (Buffer  : in out SU.Unbounded_String;
      Channel : CM.Resolved_Channel_Decl;
      Bronze  : MB.Bronze_Result);
   procedure Render_Channel_Body
     (Buffer  : in out SU.Unbounded_String;
      Channel : CM.Resolved_Channel_Decl);
   procedure Render_Free_Declarations
     (Buffer       : in out SU.Unbounded_String;
      Declarations : CM.Resolved_Object_Decl_Vectors.Vector;
      Depth        : Natural);
   procedure Render_Free_Declarations
     (Buffer       : in out SU.Unbounded_String;
      Declarations : CM.Object_Decl_Vectors.Vector;
      Depth        : Natural);
   procedure Render_Subprogram_Body
     (Buffer     : in out SU.Unbounded_String;
      Unit       : CM.Resolved_Unit;
      Document   : GM.Mir_Document;
      Subprogram : CM.Resolved_Subprogram;
      State      : in out Emit_State);
   procedure Render_Task_Body
     (Buffer   : in out SU.Unbounded_String;
      Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Task_Item : CM.Resolved_Task;
      State    : in out Emit_State);

   function Safe_Runtime_Text return String is
     (Runtime_Template);

   function Gnat_Adc_Text return String is
     (Gnat_Adc_Contents);

   procedure Raise_Internal (Message : String) is
   begin
      raise Emitter_Internal with Message;
   end Raise_Internal;

   procedure Raise_Unsupported
     (State   : in out Emit_State;
      Span    : FT.Source_Span;
      Message : String) is
   begin
      State.Unsupported_Span := Span;
      State.Unsupported_Message := FT.To_UString (Message);
      raise Emitter_Unsupported;
   end Raise_Unsupported;

   function Has_Text (Item : FT.UString) return Boolean is
   begin
      return FT.To_String (Item)'Length > 0;
   end Has_Text;

   function Trim_Image (Value : Long_Long_Integer) return String is
      Image : constant String := Long_Long_Integer'Image (Value);
   begin
      if Image'Length > 0 and then Image (Image'First) = ' ' then
         return Image (Image'First + 1 .. Image'Last);
      end if;
      return Image;
   end Trim_Image;

   function Trim_Wide_Image (Value : CM.Wide_Integer) return String is
      Image : constant String := CM.Wide_Integer'Image (Value);
   begin
      if Image'Length > 0 and then Image (Image'First) = ' ' then
         return Image (Image'First + 1 .. Image'Last);
      end if;
      return Image;
   end Trim_Wide_Image;

   function Indentation (Depth : Natural) return String is
   begin
      if Depth = 0 then
         return "";
      end if;
      return (1 .. Depth * Indent_Width => ' ');
   end Indentation;

   procedure Append_Line
     (Buffer : in out SU.Unbounded_String;
      Text   : String := "";
      Depth  : Natural := 0) is
   begin
      Buffer :=
        Buffer
        & SU.To_Unbounded_String (Indentation (Depth) & Text & ASCII.LF);
   end Append_Line;

   function Join_Names (Items : FT.UString_Vectors.Vector) return String is
      Result : SU.Unbounded_String;
      First  : Boolean := True;
   begin
      for Item of Items loop
         if not First then
            Result := Result & SU.To_Unbounded_String (", ");
         else
            First := False;
         end if;
         Result := Result & SU.To_Unbounded_String (FT.To_String (Item));
      end loop;
      return SU.To_String (Result);
   exception
      when Constraint_Error =>
         Raise_Internal ("malformed name vector during Ada emission");
   end Join_Names;

   function Contains_Name
     (Items : FT.UString_Vectors.Vector;
      Name  : String) return Boolean is
   begin
      for Item of Items loop
         if FT.To_String (Item) = Name then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Name;

   procedure Add_Wide_Name
     (State : in out Emit_State;
      Name  : String) is
   begin
      if not Contains_Name (State.Wide_Local_Names, Name) then
         State.Wide_Local_Names.Append (FT.To_UString (Name));
      end if;
   end Add_Wide_Name;

   function Is_Wide_Name
     (State : Emit_State;
      Name  : String) return Boolean is
   begin
      return Contains_Name (State.Wide_Local_Names, Name);
   end Is_Wide_Name;

   function Names_Use_Wide_Storage
     (State : Emit_State;
      Names : FT.UString_Vectors.Vector) return Boolean is
   begin
      for Name of Names loop
         if Is_Wide_Name (State, FT.To_String (Name)) then
            return True;
         end if;
      end loop;
      return False;
   end Names_Use_Wide_Storage;

   procedure Restore_Wide_Names
     (State           : in out Emit_State;
      Previous_Length : Ada.Containers.Count_Type) is
   begin
      while State.Wide_Local_Names.Length > Previous_Length loop
         State.Wide_Local_Names.Delete_Last;
      end loop;
   end Restore_Wide_Names;

   procedure Push_Cleanup_Frame (State : in out Emit_State) is
   begin
      State.Cleanup_Stack.Append ((Items => <>));
   end Push_Cleanup_Frame;

   procedure Pop_Cleanup_Frame (State : in out Emit_State) is
   begin
      if State.Cleanup_Stack.Is_Empty then
         Raise_Internal ("cleanup frame stack underflow during Ada emission");
      end if;
      State.Cleanup_Stack.Delete_Last;
   end Pop_Cleanup_Frame;

   procedure Add_Cleanup_Item
     (State     : in out Emit_State;
      Name      : String;
      Type_Name : String) is
   begin
      if State.Cleanup_Stack.Is_Empty then
         Raise_Internal ("cleanup item added outside an active cleanup scope during Ada emission");
      end if;

      declare
         Frame : Cleanup_Frame := State.Cleanup_Stack.Last_Element;
      begin
         Frame.Items.Append
           ((Name      => FT.To_UString (Name),
             Type_Name => FT.To_UString (Type_Name)));
         State.Cleanup_Stack.Replace_Element (State.Cleanup_Stack.Last_Index, Frame);
      end;
   end Add_Cleanup_Item;

   procedure Register_Cleanup_Items
     (State        : in out Emit_State;
      Declarations : CM.Resolved_Object_Decl_Vectors.Vector) is
   begin
      for Decl of Declarations loop
         if Is_Owner_Access (Decl.Type_Info) then
            for Name of Decl.Names loop
               Add_Cleanup_Item
                 (State,
                  FT.To_String (Name),
                  FT.To_String (Decl.Type_Info.Name));
            end loop;
         end if;
      end loop;
   end Register_Cleanup_Items;

   procedure Register_Cleanup_Items
     (State        : in out Emit_State;
      Declarations : CM.Object_Decl_Vectors.Vector) is
   begin
      for Decl of Declarations loop
         if Is_Owner_Access (Decl.Type_Info) then
            for Name of Decl.Names loop
               Add_Cleanup_Item
                 (State,
                  FT.To_String (Name),
                  FT.To_String (Decl.Type_Info.Name));
            end loop;
         end if;
      end loop;
   end Register_Cleanup_Items;

   procedure Render_Cleanup_Item
     (Buffer : in out SU.Unbounded_String;
      Item   : Cleanup_Item;
      Depth  : Natural) is
   begin
      Append_Line
        (Buffer,
         "if " & FT.To_String (Item.Name) & " /= null then",
         Depth);
      Append_Line
        (Buffer,
         "Free_" & FT.To_String (Item.Type_Name) & " (" & FT.To_String (Item.Name) & ");",
         Depth + 1);
      Append_Line (Buffer, "end if;", Depth);
   end Render_Cleanup_Item;

   procedure Render_Active_Cleanup
     (Buffer : in out SU.Unbounded_String;
      State  : Emit_State;
      Depth  : Natural) is
   begin
      if State.Cleanup_Stack.Is_Empty then
         return;
      end if;
      for Frame_Index in reverse State.Cleanup_Stack.First_Index .. State.Cleanup_Stack.Last_Index loop
         declare
            Frame : constant Cleanup_Frame := State.Cleanup_Stack (Frame_Index);
         begin
            for Item_Index in reverse Frame.Items.First_Index .. Frame.Items.Last_Index loop
               Render_Cleanup_Item (Buffer, Frame.Items (Item_Index), Depth);
            end loop;
         end;
      end loop;
   end Render_Active_Cleanup;

   function Starts_With (Text : String; Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Normalize_Aspect_Name
     (Subprogram_Name : String;
      Raw_Name        : String) return String is
   begin
      if Raw_Name = "return" then
         return Subprogram_Name & "'Result";
      elsif Starts_With (Raw_Name, "param:") then
         return Raw_Name (Raw_Name'First + 6 .. Raw_Name'Last);
      elsif Starts_With (Raw_Name, "global:") then
         return Raw_Name (Raw_Name'First + 7 .. Raw_Name'Last);
      else
         return Raw_Name;
      end if;
   end Normalize_Aspect_Name;

   function Lookup_Type
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Name     : String) return GM.Type_Descriptor
   is
   begin
      for Item of Unit.Types loop
         if FT.To_String (Item.Name) = Name then
            return Item;
         end if;
      end loop;
      for Item of Unit.Imported_Types loop
         if FT.To_String (Item.Name) = Name then
            return Item;
         end if;
      end loop;
      for Item of Document.Types loop
         if FT.To_String (Item.Name) = Name then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end Lookup_Type;

   function Has_Type
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Name     : String) return Boolean is
      Item : constant GM.Type_Descriptor := Lookup_Type (Unit, Document, Name);
   begin
      return Has_Text (Item.Name);
   end Has_Type;

   function Is_Integer_Type (Info : GM.Type_Descriptor) return Boolean is
      Kind : constant String := FT.To_String (Info.Kind);
   begin
      return Kind in "integer" | "subtype";
   end Is_Integer_Type;

   function Is_Integer_Type
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Name     : String) return Boolean
   is
   begin
      if Name in "Integer" | "Natural" | "Positive"
        | "Long_Long_Integer" | "Long_Long_Long_Integer"
        | "Safe_Runtime.Wide_Integer"
      then
         return True;
      elsif Has_Type (Unit, Document, Name) then
         return Is_Integer_Type (Lookup_Type (Unit, Document, Name));
      end if;
      return False;
   end Is_Integer_Type;

   function Is_Access_Type (Info : GM.Type_Descriptor) return Boolean is
   begin
      return FT.To_String (Info.Kind) = "access";
   end Is_Access_Type;

   function Is_Owner_Access (Info : GM.Type_Descriptor) return Boolean is
   begin
      return Is_Access_Type (Info)
        and then FT.To_String (Info.Access_Role) = "Owner";
   end Is_Owner_Access;

   function Render_Type_Name (Info : GM.Type_Descriptor) return String is
   begin
      if Info.Anonymous and then Is_Access_Type (Info) then
         return
           (if Info.Not_Null then "not null " else "")
           & "access "
           & (if Info.Is_Constant then "constant " else "")
           & FT.To_String (Info.Target);
      end if;
      return FT.To_String (Info.Name);
   end Render_Type_Name;

   function Render_Type_Name
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Name     : String) return String
   is
   begin
      if Has_Type (Unit, Document, Name) then
         return Render_Type_Name (Lookup_Type (Unit, Document, Name));
      end if;
      return Name;
   end Render_Type_Name;

   function Lookup_Channel
     (Unit : CM.Resolved_Unit;
      Name : String) return CM.Resolved_Channel_Decl
   is
   begin
      for Item of Unit.Channels loop
         if FT.To_String (Item.Name) = Name then
            return Item;
         end if;
      end loop;
      for Item of Unit.Imported_Channels loop
         if FT.To_String (Item.Name) = Name then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end Lookup_Channel;

   function Render_Type_Decl
     (Type_Item : GM.Type_Descriptor;
      State     : in out Emit_State) return String is
      Name : constant String := FT.To_String (Type_Item.Name);
      Kind : constant String := FT.To_String (Type_Item.Kind);
      Result : SU.Unbounded_String;
   begin
      if Kind = "incomplete" then
         return "type " & Name & ";";
      elsif Kind = "integer" then
         return
           "type "
           & Name
           & " is range "
           & Trim_Image (Type_Item.Low)
           & " .. "
           & Trim_Image (Type_Item.High)
           & ";";
      elsif Kind = "subtype" then
         if Type_Item.Has_Low and then Type_Item.Has_High then
            return
              "subtype "
              & Name
              & " is "
              & FT.To_String (Type_Item.Base)
              & " range "
              & Trim_Image (Type_Item.Low)
              & " .. "
              & Trim_Image (Type_Item.High)
              & ";";
         else
            return
              "subtype " & Name & " is " & FT.To_String (Type_Item.Base) & ";";
         end if;
      elsif Kind = "array" then
         return
           "type "
           & Name
           & " is array ("
           & Join_Names (Type_Item.Index_Types)
           & ") of "
           & FT.To_String (Type_Item.Component_Type)
           & ";";
      elsif Kind = "record" then
         if Type_Item.Has_Discriminant or else not Type_Item.Variant_Fields.Is_Empty then
            Raise_Unsupported
              (State,
               FT.Null_Span,
               "PR09 emitter does not yet support discriminated or variant record emission");
         end if;
         Result := SU.To_Unbounded_String ("type " & Name & " is record" & ASCII.LF);
         for Field of Type_Item.Fields loop
            Result :=
              Result
              & SU.To_Unbounded_String
                  (Indentation (1)
                   & FT.To_String (Field.Name)
                   & " : "
                   & FT.To_String (Field.Type_Name)
                   & ";"
                   & ASCII.LF);
         end loop;
         Result :=
           Result & SU.To_Unbounded_String ("end record;");
         return SU.To_String (Result);
      elsif Kind = "access" then
         return
           "type "
           & Name
           & " is "
           & (if Type_Item.Not_Null then "not null " else "")
           & "access "
           & (if Type_Item.Is_Constant then "constant " else "")
           & FT.To_String (Type_Item.Target)
           & ";";
      elsif Kind = "float" then
         if Type_Item.Has_Digits_Text then
            return
              "type "
              & Name
              & " is digits "
              & FT.To_String (Type_Item.Digits_Text)
              & ";";
         end if;
         return "type " & Name & " is digits 6;";
      end if;

      Raise_Unsupported
        (State,
         FT.Null_Span,
         "PR09 emitter does not yet support type kind '" & Kind & "'");
      return "";
   end Render_Type_Decl;

   function Map_Operator (Operator : String) return String is
   begin
      if Operator = "!=" then
         return "/=";
      elsif Operator = "==" then
         return "=";
      end if;
      return Operator;
   end Map_Operator;

   function Render_Expr
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Expr     : CM.Expr_Access;
      State    : in out Emit_State) return String
   is
      Result : SU.Unbounded_String;
   begin
      if Expr = null then
         Raise_Unsupported
           (State,
            FT.Null_Span,
            "encountered null expression during Ada emission");
      end if;

      case Expr.Kind is
         when CM.Expr_Int =>
            if Has_Text (Expr.Text) then
               return FT.To_String (Expr.Text);
            end if;
            return Trim_Wide_Image (Expr.Int_Value);
         when CM.Expr_Real =>
            if Has_Text (Expr.Text) then
               return FT.To_String (Expr.Text);
            end if;
            Raise_Unsupported
              (State,
               Expr.Span,
               "real literal missing source text");
         when CM.Expr_Bool =>
            return (if Expr.Bool_Value then "True" else "False");
         when CM.Expr_Null =>
            return "null";
         when CM.Expr_Ident =>
            return FT.To_String (Expr.Name);
         when CM.Expr_Select =>
            return
              Render_Expr (Unit, Document, Expr.Prefix, State)
              & "."
              & FT.To_String (Expr.Selector);
         when CM.Expr_Resolved_Index =>
            Result :=
              SU.To_Unbounded_String
                (Render_Expr (Unit, Document, Expr.Prefix, State) & " (");
            for Index in Expr.Args.First_Index .. Expr.Args.Last_Index loop
               if Index /= Expr.Args.First_Index then
                  Result := Result & SU.To_Unbounded_String (", ");
               end if;
               Result :=
                 Result
                 & SU.To_Unbounded_String
                     (Render_Expr (Unit, Document, Expr.Args (Index), State));
            end loop;
            Result := Result & SU.To_Unbounded_String (")");
            return SU.To_String (Result);
         when CM.Expr_Conversion =>
            return
              Render_Expr (Unit, Document, Expr.Target, State)
              & " ("
              & Render_Expr (Unit, Document, Expr.Inner, State)
              & ")";
         when CM.Expr_Call =>
            Result :=
              SU.To_Unbounded_String
                (Render_Expr (Unit, Document, Expr.Callee, State) & " (");
            for Index in Expr.Args.First_Index .. Expr.Args.Last_Index loop
               if Index /= Expr.Args.First_Index then
                  Result := Result & SU.To_Unbounded_String (", ");
               end if;
               Result :=
                 Result
                 & SU.To_Unbounded_String
                     (Render_Expr (Unit, Document, Expr.Args (Index), State));
            end loop;
            Result := Result & SU.To_Unbounded_String (")");
            return SU.To_String (Result);
         when CM.Expr_Allocator =>
            return "new " & Render_Expr (Unit, Document, Expr.Value, State);
         when CM.Expr_Aggregate =>
            Result := SU.To_Unbounded_String ("(");
            for Index in Expr.Fields.First_Index .. Expr.Fields.Last_Index loop
               declare
                  Field : constant CM.Aggregate_Field := Expr.Fields (Index);
               begin
                  if Index /= Expr.Fields.First_Index then
                     Result := Result & SU.To_Unbounded_String (", ");
                  end if;
                  Result :=
                    Result
                    & SU.To_Unbounded_String
                        (FT.To_String (Field.Field_Name)
                         & " => "
                         & Render_Expr (Unit, Document, Field.Expr, State));
               end;
            end loop;
            Result := Result & SU.To_Unbounded_String (")");
            return SU.To_String (Result);
         when CM.Expr_Annotated =>
            return
              Render_Expr (Unit, Document, Expr.Target, State)
              & "'"
              & Render_Expr (Unit, Document, Expr.Inner, State);
         when CM.Expr_Unary =>
            return
              "("
              & Map_Operator (FT.To_String (Expr.Operator))
              & (if FT.To_String (Expr.Operator) = "not" then " " else "")
              & Render_Expr (Unit, Document, Expr.Inner, State)
              & ")";
         when CM.Expr_Binary =>
            return
              "("
              & Render_Expr (Unit, Document, Expr.Left, State)
              & " "
              & Map_Operator (FT.To_String (Expr.Operator))
              & " "
              & Render_Expr (Unit, Document, Expr.Right, State)
              & ")";
         when CM.Expr_Subtype_Indication =>
            if Has_Text (Expr.Type_Name) then
               return Render_Type_Name (Unit, Document, FT.To_String (Expr.Type_Name));
            end if;
            Raise_Unsupported
              (State,
               Expr.Span,
               "subtype indication missing type name");
         when others =>
               Raise_Unsupported
                 (State,
                  Expr.Span,
                  "PR09 emitter does not yet support expression kind '"
                  & Expr.Kind'Image
                  & "'");
      end case;

      return "";
   end Render_Expr;

   function Uses_Wide_Arithmetic
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Expr     : CM.Expr_Access) return Boolean
   is
      Operator : constant String :=
        (if Expr = null then "" else FT.To_String (Expr.Operator));
   begin
      if Expr = null then
         return False;
      end if;

      case Expr.Kind is
         when CM.Expr_Unary =>
            return
              Operator = "-"
              and then Is_Integer_Type (Unit, Document, FT.To_String (Expr.Type_Name));
         when CM.Expr_Binary =>
            if Operator in "+" | "-" | "*" | "/" | "mod" | "rem" then
               return Is_Integer_Type (Unit, Document, FT.To_String (Expr.Type_Name));
            end if;
            return
              Uses_Wide_Arithmetic (Unit, Document, Expr.Left)
              or else Uses_Wide_Arithmetic (Unit, Document, Expr.Right);
         when CM.Expr_Conversion =>
            return Uses_Wide_Arithmetic (Unit, Document, Expr.Inner);
         when CM.Expr_Annotated =>
            return Uses_Wide_Arithmetic (Unit, Document, Expr.Inner);
         when CM.Expr_Call =>
            for Item of Expr.Args loop
               if Uses_Wide_Arithmetic (Unit, Document, Item) then
                  return True;
               end if;
            end loop;
            return False;
         when CM.Expr_Resolved_Index =>
            for Item of Expr.Args loop
               if Uses_Wide_Arithmetic (Unit, Document, Item) then
                  return True;
               end if;
            end loop;
            return False;
         when others =>
            return False;
      end case;
   end Uses_Wide_Arithmetic;

   function Uses_Wide_Value
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      State    : Emit_State;
      Expr     : CM.Expr_Access) return Boolean
   is
   begin
      if Expr = null then
         return False;
      elsif Uses_Wide_Arithmetic (Unit, Document, Expr) then
         return True;
      end if;

      case Expr.Kind is
         when CM.Expr_Ident =>
            return Is_Wide_Name (State, FT.To_String (Expr.Name));
         when CM.Expr_Unary | CM.Expr_Conversion | CM.Expr_Annotated =>
            return Uses_Wide_Value (Unit, Document, State, Expr.Inner);
         when CM.Expr_Binary =>
            return
              Uses_Wide_Value (Unit, Document, State, Expr.Left)
              or else Uses_Wide_Value (Unit, Document, State, Expr.Right);
         when CM.Expr_Call | CM.Expr_Resolved_Index =>
            for Item of Expr.Args loop
               if Uses_Wide_Value (Unit, Document, State, Item) then
                  return True;
               end if;
            end loop;
            return False;
         when CM.Expr_Select =>
            return Uses_Wide_Value (Unit, Document, State, Expr.Prefix);
         when others =>
            return False;
      end case;
   end Uses_Wide_Value;

   function Render_Channel_Send_Value
     (Unit         : CM.Resolved_Unit;
      Document     : GM.Mir_Document;
      State        : in out Emit_State;
      Channel_Expr : CM.Expr_Access;
      Value        : CM.Expr_Access) return String
   is
      Channel_Name : constant String :=
        (if Channel_Expr = null then "" else CM.Flatten_Name (Channel_Expr));
      Channel_Item : constant CM.Resolved_Channel_Decl :=
        Lookup_Channel (Unit, Channel_Name);
   begin
      if Has_Text (Channel_Item.Name)
        and then Is_Integer_Type (Channel_Item.Element_Type)
        and then Uses_Wide_Value (Unit, Document, State, Value)
      then
         return
           Render_Type_Name (Channel_Item.Element_Type)
           & " ("
           & Render_Wide_Expr (Unit, Document, Value, State)
           & ")";
      end if;
      return Render_Expr (Unit, Document, Value, State);
   end Render_Channel_Send_Value;

   procedure Collect_Wide_Locals_From_Statements
     (Unit        : CM.Resolved_Unit;
      Document    : GM.Mir_Document;
      State       : in out Emit_State;
      Local_Names : FT.UString_Vectors.Vector;
      Statements  : CM.Statement_Access_Vectors.Vector);

   procedure Collect_Local_Names
     (Declarations : CM.Resolved_Object_Decl_Vectors.Vector;
      Statements   : CM.Statement_Access_Vectors.Vector;
      Names        : in out FT.UString_Vectors.Vector) is
   begin
      for Decl of Declarations loop
         for Name of Decl.Names loop
            if not Contains_Name (Names, FT.To_String (Name)) then
               Names.Append (Name);
            end if;
         end loop;
      end loop;
      for Item of Statements loop
         if Item /= null and then Item.Kind = CM.Stmt_Object_Decl then
            for Name of Item.Decl.Names loop
               if not Contains_Name (Names, FT.To_String (Name)) then
                  Names.Append (Name);
               end if;
            end loop;
         end if;
      end loop;
   end Collect_Local_Names;

   procedure Collect_Local_Names
     (Declarations : CM.Object_Decl_Vectors.Vector;
      Statements   : CM.Statement_Access_Vectors.Vector;
      Names        : in out FT.UString_Vectors.Vector) is
   begin
      for Decl of Declarations loop
         for Name of Decl.Names loop
            if not Contains_Name (Names, FT.To_String (Name)) then
               Names.Append (Name);
            end if;
         end loop;
      end loop;
      for Item of Statements loop
         if Item /= null and then Item.Kind = CM.Stmt_Object_Decl then
            for Name of Item.Decl.Names loop
               if not Contains_Name (Names, FT.To_String (Name)) then
                  Names.Append (Name);
               end if;
            end loop;
         end if;
      end loop;
   end Collect_Local_Names;

   procedure Mark_Wide_Declaration
     (Unit      : CM.Resolved_Unit;
      Document  : GM.Mir_Document;
      State     : in out Emit_State;
      Decl      : CM.Resolved_Object_Decl) is
   begin
      if Is_Integer_Type (Decl.Type_Info)
        and then Decl.Has_Initializer
        and then Uses_Wide_Value (Unit, Document, State, Decl.Initializer)
      then
         for Name of Decl.Names loop
            Add_Wide_Name (State, FT.To_String (Name));
         end loop;
      end if;
   end Mark_Wide_Declaration;

   procedure Mark_Wide_Declaration
     (Unit      : CM.Resolved_Unit;
      Document  : GM.Mir_Document;
      State     : in out Emit_State;
      Decl      : CM.Object_Decl) is
   begin
      if Is_Integer_Type (Decl.Type_Info)
        and then Decl.Has_Initializer
        and then Uses_Wide_Value (Unit, Document, State, Decl.Initializer)
      then
         for Name of Decl.Names loop
            Add_Wide_Name (State, FT.To_String (Name));
         end loop;
      end if;
   end Mark_Wide_Declaration;

   procedure Collect_Wide_Locals_From_Statements
     (Unit        : CM.Resolved_Unit;
      Document    : GM.Mir_Document;
      State       : in out Emit_State;
      Local_Names : FT.UString_Vectors.Vector;
      Statements  : CM.Statement_Access_Vectors.Vector) is
   begin
      for Item of Statements loop
         if Item = null then
            null;
         else
            case Item.Kind is
               when CM.Stmt_Object_Decl =>
                  Mark_Wide_Declaration (Unit, Document, State, Item.Decl);
               when CM.Stmt_Assign =>
                  if Item.Target /= null
                    and then Item.Target.Kind = CM.Expr_Ident
                    and then Contains_Name (Local_Names, FT.To_String (Item.Target.Name))
                    and then Uses_Wide_Value (Unit, Document, State, Item.Value)
                  then
                     Add_Wide_Name (State, FT.To_String (Item.Target.Name));
                  end if;
               when CM.Stmt_If =>
                  Collect_Wide_Locals_From_Statements
                    (Unit, Document, State, Local_Names, Item.Then_Stmts);
                  for Part of Item.Elsifs loop
                     Collect_Wide_Locals_From_Statements
                       (Unit, Document, State, Local_Names, Part.Statements);
                  end loop;
                  if Item.Has_Else then
                     Collect_Wide_Locals_From_Statements
                       (Unit, Document, State, Local_Names, Item.Else_Stmts);
                  end if;
               when CM.Stmt_While | CM.Stmt_For | CM.Stmt_Loop =>
                  Collect_Wide_Locals_From_Statements
                    (Unit, Document, State, Local_Names, Item.Body_Stmts);
               when CM.Stmt_Block =>
                  declare
                     Block_Names : FT.UString_Vectors.Vector;
                  begin
                     Collect_Local_Names (Item.Declarations, Item.Body_Stmts, Block_Names);
                     for Decl of Item.Declarations loop
                        Mark_Wide_Declaration (Unit, Document, State, Decl);
                     end loop;
                     Collect_Wide_Locals_From_Statements
                       (Unit, Document, State, Block_Names, Item.Body_Stmts);
                  end;
               when CM.Stmt_Select =>
                  for Arm of Item.Arms loop
                     case Arm.Kind is
                        when CM.Select_Arm_Channel =>
                           Collect_Wide_Locals_From_Statements
                             (Unit, Document, State, Local_Names, Arm.Channel_Data.Statements);
                        when CM.Select_Arm_Delay =>
                           Collect_Wide_Locals_From_Statements
                             (Unit, Document, State, Local_Names, Arm.Delay_Data.Statements);
                        when others =>
                           null;
                     end case;
                  end loop;
               when others =>
                  null;
            end case;
         end if;
      end loop;
   end Collect_Wide_Locals_From_Statements;

   procedure Collect_Wide_Locals
     (Unit         : CM.Resolved_Unit;
      Document     : GM.Mir_Document;
      State        : in out Emit_State;
      Declarations : CM.Resolved_Object_Decl_Vectors.Vector;
      Statements   : CM.Statement_Access_Vectors.Vector) is
      Local_Names : FT.UString_Vectors.Vector;
   begin
      Collect_Local_Names (Declarations, Statements, Local_Names);
      for Decl of Declarations loop
         Mark_Wide_Declaration (Unit, Document, State, Decl);
      end loop;
      Collect_Wide_Locals_From_Statements
        (Unit, Document, State, Local_Names, Statements);
   end Collect_Wide_Locals;

   procedure Collect_Wide_Locals
     (Unit         : CM.Resolved_Unit;
      Document     : GM.Mir_Document;
      State        : in out Emit_State;
      Declarations : CM.Object_Decl_Vectors.Vector;
      Statements   : CM.Statement_Access_Vectors.Vector) is
      Local_Names : FT.UString_Vectors.Vector;
   begin
      Collect_Local_Names (Declarations, Statements, Local_Names);
      for Decl of Declarations loop
         Mark_Wide_Declaration (Unit, Document, State, Decl);
      end loop;
      Collect_Wide_Locals_From_Statements
        (Unit, Document, State, Local_Names, Statements);
   end Collect_Wide_Locals;

   function Render_Wide_Expr
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Expr     : CM.Expr_Access;
      State    : in out Emit_State) return String
   is
      Operator : constant String :=
        (if Expr = null then "" else Map_Operator (FT.To_String (Expr.Operator)));
   begin
      State.Needs_Safe_Runtime := True;

      if Expr = null then
         Raise_Unsupported
           (State,
            FT.Null_Span,
            "encountered null wide expression during Ada emission");
      end if;

      case Expr.Kind is
         when CM.Expr_Int =>
            return "Safe_Runtime.Wide_Integer (" & Render_Expr (Unit, Document, Expr, State) & ")";
         when CM.Expr_Ident | CM.Expr_Select | CM.Expr_Resolved_Index | CM.Expr_Call =>
            return "Safe_Runtime.Wide_Integer (" & Render_Expr (Unit, Document, Expr, State) & ")";
         when CM.Expr_Conversion =>
            return "Safe_Runtime.Wide_Integer (" & Render_Expr (Unit, Document, Expr, State) & ")";
         when CM.Expr_Unary =>
            return "(" & Operator & Render_Wide_Expr (Unit, Document, Expr.Inner, State) & ")";
         when CM.Expr_Binary =>
            if Operator in "+" | "-" | "*" | "/" | "mod" | "rem" then
               return
                 "("
                 & Render_Wide_Expr (Unit, Document, Expr.Left, State)
                 & " "
                 & Operator
                 & " "
                 & Render_Wide_Expr (Unit, Document, Expr.Right, State)
                 & ")";
            end if;
            return "Safe_Runtime.Wide_Integer (Boolean'Pos" & Render_Expr (Unit, Document, Expr, State) & ")";
         when others =>
            return "Safe_Runtime.Wide_Integer (" & Render_Expr (Unit, Document, Expr, State) & ")";
      end case;
   end Render_Wide_Expr;

   function Render_Object_Decl_Text
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      State    : in out Emit_State;
      Decl     : CM.Resolved_Object_Decl) return String
   is
      Result : SU.Unbounded_String;
      Type_Name : constant String :=
        (if Is_Integer_Type (Decl.Type_Info)
           and then Names_Use_Wide_Storage (State, Decl.Names)
         then "Safe_Runtime.Wide_Integer"
         else Render_Type_Name (Decl.Type_Info));
   begin
      if Type_Name = "Safe_Runtime.Wide_Integer" then
         State.Needs_Safe_Runtime := True;
      end if;
      for Index in Decl.Names.First_Index .. Decl.Names.Last_Index loop
         if Index /= Decl.Names.First_Index then
            Result := Result & SU.To_Unbounded_String ("; ");
         end if;
         Result :=
           Result
           & SU.To_Unbounded_String
               (FT.To_String (Decl.Names (Index))
                & " : "
                & (if Decl.Is_Constant then "constant " else "")
                & Type_Name);
         if Decl.Has_Initializer then
            if Type_Name = "Safe_Runtime.Wide_Integer" then
               Result :=
                 Result
                 & SU.To_Unbounded_String
                     (" := " & Render_Wide_Expr (Unit, Document, Decl.Initializer, State));
            elsif Is_Integer_Type (Decl.Type_Info)
              and then Uses_Wide_Value (Unit, Document, State, Decl.Initializer)
            then
               Result :=
                 Result
                 & SU.To_Unbounded_String
                     (" := "
                      & Render_Type_Name (Decl.Type_Info)
                      & " ("
                      & Render_Wide_Expr (Unit, Document, Decl.Initializer, State)
                      & ")");
            else
               Result :=
                 Result
                 & SU.To_Unbounded_String
                     (" := " & Render_Expr (Unit, Document, Decl.Initializer, State));
            end if;
         end if;
      end loop;
      return SU.To_String (Result) & ";";
   end Render_Object_Decl_Text;

   function Render_Object_Decl_Text
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      State    : in out Emit_State;
      Decl     : CM.Object_Decl) return String
   is
      Result : SU.Unbounded_String;
      Type_Name : constant String :=
        (if Is_Integer_Type (Decl.Type_Info)
           and then Names_Use_Wide_Storage (State, Decl.Names)
         then "Safe_Runtime.Wide_Integer"
         else Render_Type_Name (Decl.Type_Info));
   begin
      if Type_Name = "Safe_Runtime.Wide_Integer" then
         State.Needs_Safe_Runtime := True;
      end if;
      for Index in Decl.Names.First_Index .. Decl.Names.Last_Index loop
         if Index /= Decl.Names.First_Index then
            Result := Result & SU.To_Unbounded_String ("; ");
         end if;
         Result :=
           Result
           & SU.To_Unbounded_String
               (FT.To_String (Decl.Names (Index))
                & " : "
                & (if Decl.Is_Constant then "constant " else "")
                & Type_Name);
         if Decl.Has_Initializer then
            if Type_Name = "Safe_Runtime.Wide_Integer" then
               Result :=
                 Result
                 & SU.To_Unbounded_String
                     (" := " & Render_Wide_Expr (Unit, Document, Decl.Initializer, State));
            elsif Is_Integer_Type (Decl.Type_Info)
              and then Uses_Wide_Value (Unit, Document, State, Decl.Initializer)
            then
               Result :=
                 Result
                 & SU.To_Unbounded_String
                     (" := "
                      & Render_Type_Name (Decl.Type_Info)
                      & " ("
                      & Render_Wide_Expr (Unit, Document, Decl.Initializer, State)
                      & ")");
            else
               Result :=
                 Result
                 & SU.To_Unbounded_String
                     (" := " & Render_Expr (Unit, Document, Decl.Initializer, State));
            end if;
         end if;
      end loop;
      return SU.To_String (Result) & ";";
   end Render_Object_Decl_Text;

   function Render_Subprogram_Params
     (Unit       : CM.Resolved_Unit;
      Document   : GM.Mir_Document;
      Params     : CM.Symbol_Vectors.Vector) return String
   is
      pragma Unreferenced (Unit, Document);
      Result : SU.Unbounded_String := SU.To_Unbounded_String ("(");
   begin
      if Params.Is_Empty then
         return "";
      end if;

      for Index in Params.First_Index .. Params.Last_Index loop
         declare
            Param : constant CM.Symbol := Params (Index);
            Mode  : constant String := FT.To_String (Param.Mode);
         begin
            if Index /= Params.First_Index then
               Result := Result & SU.To_Unbounded_String ("; ");
            end if;
            Result :=
              Result
              & SU.To_Unbounded_String
                  (FT.To_String (Param.Name)
                   & " : "
                   & (if Mode = "in" or else Mode = "" then "" else Mode & " ")
                   & Render_Type_Name (Param.Type_Info));
         end;
      end loop;

      Result := Result & SU.To_Unbounded_String (")");
      return SU.To_String (Result);
   end Render_Subprogram_Params;

   function Render_Subprogram_Return
     (Subprogram : CM.Resolved_Subprogram) return String is
   begin
      if Subprogram.Has_Return_Type then
         return " return " & Render_Type_Name (Subprogram.Return_Type);
      end if;
      return "";
   end Render_Subprogram_Return;

   function Find_Graph_Summary
     (Bronze : MB.Bronze_Result;
      Name   : String) return MB.Graph_Summary
   is
   begin
      for Item of Bronze.Graphs loop
         if FT.To_String (Item.Name) = Name then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end Find_Graph_Summary;

   function Render_Initializes_Aspect (Bronze : MB.Bronze_Result) return String is
   begin
      if Bronze.Initializes.Is_Empty then
         return "null";
      elsif Bronze.Initializes.Length = 1 then
         return FT.To_String (Bronze.Initializes (Bronze.Initializes.First_Index));
      end if;
      return "(" & Join_Names (Bronze.Initializes) & ")";
   end Render_Initializes_Aspect;

   function Render_Global_Aspect (Summary : MB.Graph_Summary) return String is
      Inputs  : FT.UString_Vectors.Vector;
      Outputs : FT.UString_Vectors.Vector;
      In_Outs : FT.UString_Vectors.Vector;

      function Contains
        (Items : FT.UString_Vectors.Vector;
         Name  : String) return Boolean is
      begin
         for Item of Items loop
            if FT.To_String (Item) = Name then
               return True;
            end if;
         end loop;
         return False;
      end Contains;

      procedure Add_Unique
        (Items : in out FT.UString_Vectors.Vector;
         Name  : String) is
      begin
         if not Contains (Items, Name) then
            Items.Append (FT.To_UString (Name));
         end if;
      end Add_Unique;

      Result : SU.Unbounded_String := SU.To_Unbounded_String ("");
      First  : Boolean := True;
   begin
      for Item of Summary.Reads loop
         declare
            Name : constant String := Normalize_Aspect_Name ("", FT.To_String (Item));
         begin
            if Starts_With (FT.To_String (Item), "param:")
              or else FT.To_String (Item) = "return"
            then
               null;
            elsif Contains (Summary.Writes, FT.To_String (Item)) then
               Add_Unique (In_Outs, Name);
            else
               Add_Unique (Inputs, Name);
            end if;
         end;
      end loop;

      for Item of Summary.Writes loop
         declare
            Name : constant String := Normalize_Aspect_Name ("", FT.To_String (Item));
         begin
            if Starts_With (FT.To_String (Item), "param:")
              or else FT.To_String (Item) = "return"
            then
               null;
            elsif not Contains (Summary.Reads, FT.To_String (Item)) then
               Add_Unique (Outputs, Name);
            end if;
         end;
      end loop;

      if Inputs.Is_Empty and then Outputs.Is_Empty and then In_Outs.Is_Empty then
         return "null";
      end if;

      if not Inputs.Is_Empty then
         Result :=
           Result
           & SU.To_Unbounded_String
               ((if First then "" else ", ")
                & "Input => "
                & (if Inputs.Length = 1
                   then FT.To_String (Inputs (Inputs.First_Index))
                   else "(" & Join_Names (Inputs) & ")"));
         First := False;
      end if;

      if not Outputs.Is_Empty then
         Result :=
           Result
           & SU.To_Unbounded_String
               ((if First then "" else ", ")
                & "Output => "
                & (if Outputs.Length = 1
                   then FT.To_String (Outputs (Outputs.First_Index))
                   else "(" & Join_Names (Outputs) & ")"));
         First := False;
      end if;

      if not In_Outs.Is_Empty then
         Result :=
           Result
           & SU.To_Unbounded_String
               ((if First then "" else ", ")
                & "In_Out => "
                & (if In_Outs.Length = 1
                   then FT.To_String (In_Outs (In_Outs.First_Index))
                   else "(" & Join_Names (In_Outs) & ")"));
      end if;

      return "(" & SU.To_String (Result) & ")";
   end Render_Global_Aspect;

   function Render_Depends_Aspect
     (Subprogram : CM.Resolved_Subprogram;
      Summary    : MB.Graph_Summary) return String
   is
      Result : SU.Unbounded_String;
      Allowed_Outputs : FT.UString_Vectors.Vector;
      Allowed_Inputs  : FT.UString_Vectors.Vector;

      function Contains
        (Items : FT.UString_Vectors.Vector;
         Name  : String) return Boolean is
      begin
         for Item of Items loop
            if FT.To_String (Item) = Name then
               return True;
            end if;
         end loop;
         return False;
      end Contains;

      procedure Add_Unique
        (Items : in out FT.UString_Vectors.Vector;
         Name  : String) is
      begin
         if not Contains (Items, Name) then
            Items.Append (FT.To_UString (Name));
         end if;
      end Add_Unique;
   begin
      for Param of Subprogram.Params loop
         declare
            Name : constant String := FT.To_String (Param.Name);
            Mode : constant String := FT.To_String (Param.Mode);
         begin
            if Mode = "out" then
               Add_Unique (Allowed_Outputs, Name);
            elsif Mode = "in out" then
               Add_Unique (Allowed_Outputs, Name);
               Add_Unique (Allowed_Inputs, Name);
            else
               Add_Unique (Allowed_Inputs, Name);
            end if;
         end;
      end loop;

      if Subprogram.Has_Return_Type then
         Add_Unique
           (Allowed_Outputs,
            FT.To_String (Subprogram.Name) & "'Result");
      end if;

      for Item of Summary.Reads loop
         declare
            Name : constant String :=
              Normalize_Aspect_Name (FT.To_String (Subprogram.Name), FT.To_String (Item));
         begin
            if not Starts_With (FT.To_String (Item), "param:")
              and then FT.To_String (Item) /= "return"
            then
               Add_Unique (Allowed_Inputs, Name);
            end if;
         end;
      end loop;

      for Item of Summary.Writes loop
         declare
            Name : constant String :=
              Normalize_Aspect_Name (FT.To_String (Subprogram.Name), FT.To_String (Item));
         begin
            if not Starts_With (FT.To_String (Item), "param:")
              and then FT.To_String (Item) /= "return"
            then
               Add_Unique (Allowed_Outputs, Name);
            end if;
         end;
      end loop;

      if Summary.Depends.Is_Empty then
         return "";
      end if;

      for Index in Summary.Depends.First_Index .. Summary.Depends.Last_Index loop
         declare
            Item : constant MB.Depends_Entry := Summary.Depends (Index);
            Output_Name : constant String :=
              Normalize_Aspect_Name (FT.To_String (Subprogram.Name), FT.To_String (Item.Output_Name));
         begin
            if not Contains (Allowed_Outputs, Output_Name) then
               Raise_Internal
                 ("invalid Depends output `" & Output_Name
                  & "` while emitting `" & FT.To_String (Subprogram.Name) & "`");
            end if;
            if Index /= Summary.Depends.First_Index then
               Result := Result & SU.To_Unbounded_String (", ");
            end if;
            Result := Result & SU.To_Unbounded_String (Output_Name & " => ");
            if Item.Inputs.Is_Empty then
               Result := Result & SU.To_Unbounded_String ("null");
            elsif Item.Inputs.Length = 1 then
               declare
                  Name : constant String :=
                    Normalize_Aspect_Name
                      (FT.To_String (Subprogram.Name),
                       FT.To_String (Item.Inputs (Item.Inputs.First_Index)));
               begin
                  if not Contains (Allowed_Inputs, Name) then
                     Raise_Internal
                       ("invalid Depends input `" & Name
                        & "` while emitting `" & FT.To_String (Subprogram.Name) & "`");
                  end if;
                  Result := Result & SU.To_Unbounded_String (Name);
               end;
            else
               declare
                  Inputs : FT.UString_Vectors.Vector;
               begin
                  for Input of Item.Inputs loop
                     declare
                        Name : constant String :=
                          Normalize_Aspect_Name
                            (FT.To_String (Subprogram.Name),
                             FT.To_String (Input));
                     begin
                        if not Contains (Allowed_Inputs, Name) then
                           Raise_Internal
                             ("invalid Depends input `" & Name
                              & "` while emitting `" & FT.To_String (Subprogram.Name) & "`");
                        end if;
                        Inputs.Append (FT.To_UString (Name));
                     end;
                  end loop;
                  Result :=
                    Result
                    & SU.To_Unbounded_String ("(" & Join_Names (Inputs) & ")");
               end;
            end if;
         end;
      end loop;

      return SU.To_String (Result);
   end Render_Depends_Aspect;

   function Render_Subprogram_Aspects
     (Subprogram : CM.Resolved_Subprogram;
      Bronze     : MB.Bronze_Result) return String
   is
      Summary : constant MB.Graph_Summary :=
        Find_Graph_Summary (Bronze, FT.To_String (Subprogram.Name));
      Global_Image  : constant String := Render_Global_Aspect (Summary);
      Depends_Image : constant String :=
        Render_Depends_Aspect (Subprogram, Summary);
   begin
      if not Has_Text (Summary.Name) then
         return "";
      end if;

      if Depends_Image'Length = 0 then
         return " with Global => " & Global_Image;
      end if;
      return
        " with Global => "
        & Global_Image
        & "," & ASCII.LF
        & Indentation (4)
        & "Depends => "
        & "("
        & Depends_Image
        & ")";
   end Render_Subprogram_Aspects;

   function Render_Discrete_Range
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Item_Range : CM.Discrete_Range;
      State    : in out Emit_State) return String
   is
   begin
      case Item_Range.Kind is
         when CM.Range_Subtype =>
            return Render_Expr (Unit, Document, Item_Range.Name_Expr, State);
         when CM.Range_Explicit =>
            return
              Render_Expr (Unit, Document, Item_Range.Low_Expr, State)
              & " .. "
              & Render_Expr (Unit, Document, Item_Range.High_Expr, State);
         when others =>
            Raise_Unsupported
              (State,
               Item_Range.Span,
               "unsupported loop range in Ada emission");
      end case;
      return "";
   end Render_Discrete_Range;

   procedure Append_Narrowing_Assignment
     (Buffer     : in out SU.Unbounded_String;
      Unit       : CM.Resolved_Unit;
      Document   : GM.Mir_Document;
      State      : in out Emit_State;
      Target     : CM.Expr_Access;
      Value      : CM.Expr_Access;
      Depth      : Natural)
   is
      Target_Name : constant String := FT.To_String (Target.Type_Name);
      Target_Image : constant String := Render_Expr (Unit, Document, Target, State);
      Wide_Image   : constant String := Render_Wide_Expr (Unit, Document, Value, State);
   begin
      Append_Line
        (Buffer,
         "pragma Assert ("
         & Wide_Image
         & " >= Safe_Runtime.Wide_Integer ("
         & Target_Name
         & "'First) and then "
         & Wide_Image
         & " <= Safe_Runtime.Wide_Integer ("
         & Target_Name
         & "'Last));",
         Depth);
      Append_Line
        (Buffer,
         Target_Image & " := " & Target_Name & " (" & Wide_Image & ");",
         Depth);

      if Is_Integer_Type (Unit, Document, Target_Name)
        and then Has_Type (Unit, Document, Target_Name)
        and then Is_Owner_Access (Lookup_Type (Unit, Document, Target_Name))
      then
         null;
      end if;
   end Append_Narrowing_Assignment;

   procedure Append_Move_Null
     (Buffer     : in out SU.Unbounded_String;
      Unit       : CM.Resolved_Unit;
      Document   : GM.Mir_Document;
      State      : in out Emit_State;
      Value      : CM.Expr_Access;
      Depth      : Natural)
   is
      Type_Name : constant String := FT.To_String (Value.Type_Name);
      Info      : constant GM.Type_Descriptor := Lookup_Type (Unit, Document, Type_Name);
   begin
      if Has_Type (Unit, Document, Type_Name)
        and then Is_Owner_Access (Info)
        and then Value.Kind in CM.Expr_Ident | CM.Expr_Select | CM.Expr_Resolved_Index
      then
         Append_Line
           (Buffer,
            Render_Expr (Unit, Document, Value, State) & " := null;",
            Depth);
      end if;
   end Append_Move_Null;

   procedure Append_Assignment
     (Buffer   : in out SU.Unbounded_String;
      Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      State    : in out Emit_State;
      Stmt     : CM.Statement;
      Depth    : Natural)
   is
      Target_Type : constant String := FT.To_String (Stmt.Target.Type_Name);
      Target_Info : constant GM.Type_Descriptor :=
        (if Has_Type (Unit, Document, Target_Type)
         then Lookup_Type (Unit, Document, Target_Type)
         else (others => <>));
      Target_Image : constant String := Render_Expr (Unit, Document, Stmt.Target, State);
      Value_Image  : constant String := Render_Expr (Unit, Document, Stmt.Value, State);
   begin
      if Stmt.Target.Kind = CM.Expr_Ident
        and then Is_Wide_Name (State, FT.To_String (Stmt.Target.Name))
      then
         Append_Line
           (Buffer,
            Target_Image & " := " & Render_Wide_Expr (Unit, Document, Stmt.Value, State) & ";",
            Depth);
      elsif Is_Integer_Type (Unit, Document, Target_Type)
        and then Uses_Wide_Value (Unit, Document, State, Stmt.Value)
      then
         Append_Narrowing_Assignment
           (Buffer, Unit, Document, State, Stmt.Target, Stmt.Value, Depth);
      else
         Append_Line (Buffer, Target_Image & " := " & Value_Image & ";", Depth);
      end if;

      if Is_Owner_Access (Target_Info) then
         Append_Move_Null (Buffer, Unit, Document, State, Stmt.Value, Depth);
      end if;
   end Append_Assignment;

   procedure Append_Return
     (Buffer     : in out SU.Unbounded_String;
      Unit       : CM.Resolved_Unit;
      Document   : GM.Mir_Document;
      State      : in out Emit_State;
      Value      : CM.Expr_Access;
      Return_Type : String;
      Depth      : Natural)
   is
   begin
      if Return_Type'Length > 0
        and then Is_Integer_Type (Unit, Document, Return_Type)
        and then Uses_Wide_Value (Unit, Document, State, Value)
      then
         declare
            Wide_Image : constant String := Render_Wide_Expr (Unit, Document, Value, State);
         begin
            Append_Line
              (Buffer,
               "pragma Assert ("
               & Wide_Image
               & " >= Safe_Runtime.Wide_Integer ("
               & Return_Type
               & "'First) and then "
               & Wide_Image
               & " <= Safe_Runtime.Wide_Integer ("
               & Return_Type
               & "'Last));",
               Depth);
            Append_Line
              (Buffer,
               "return " & Return_Type & " (" & Wide_Image & ");",
               Depth);
         end;
      else
         Append_Line
           (Buffer,
            "return " & Render_Expr (Unit, Document, Value, State) & ";",
            Depth);
      end if;
   end Append_Return;

   procedure Render_Block_Declarations
     (Buffer       : in out SU.Unbounded_String;
      Unit         : CM.Resolved_Unit;
      Document     : GM.Mir_Document;
      Declarations : CM.Resolved_Object_Decl_Vectors.Vector;
      State        : in out Emit_State;
      Depth        : Natural)
   is
   begin
      for Decl of Declarations loop
         Append_Line
           (Buffer,
            Render_Object_Decl_Text (Unit, Document, State, Decl),
            Depth);
         if Is_Owner_Access (Decl.Type_Info) then
            State.Needs_Unchecked_Deallocation := True;
         end if;
      end loop;
   end Render_Block_Declarations;

   procedure Render_Block_Declarations
     (Buffer       : in out SU.Unbounded_String;
      Unit         : CM.Resolved_Unit;
      Document     : GM.Mir_Document;
      Declarations : CM.Object_Decl_Vectors.Vector;
      State        : in out Emit_State;
      Depth        : Natural)
   is
   begin
      for Decl of Declarations loop
         Append_Line
           (Buffer,
            Render_Object_Decl_Text (Unit, Document, State, Decl),
            Depth);
         if Is_Owner_Access (Decl.Type_Info) then
            State.Needs_Unchecked_Deallocation := True;
         end if;
      end loop;
   end Render_Block_Declarations;

   procedure Render_Cleanup
     (Buffer       : in out SU.Unbounded_String;
      Declarations : CM.Resolved_Object_Decl_Vectors.Vector;
      Depth        : Natural) is
   begin
      for Reverse_Index in reverse Declarations.First_Index .. Declarations.Last_Index loop
         declare
            Decl : constant CM.Resolved_Object_Decl := Declarations (Reverse_Index);
         begin
            if Is_Owner_Access (Decl.Type_Info) then
               for Name of Decl.Names loop
                  Render_Cleanup_Item
                    (Buffer,
                     (Name      => Name,
                      Type_Name => Decl.Type_Info.Name),
                     Depth);
               end loop;
            end if;
         end;
      end loop;
   exception
      when Constraint_Error =>
         Raise_Internal ("malformed cleanup declarations during Ada emission");
   end Render_Cleanup;

   procedure Render_Cleanup
     (Buffer       : in out SU.Unbounded_String;
      Declarations : CM.Object_Decl_Vectors.Vector;
      Depth        : Natural) is
   begin
      for Reverse_Index in reverse Declarations.First_Index .. Declarations.Last_Index loop
         declare
            Decl : constant CM.Object_Decl := Declarations (Reverse_Index);
         begin
            if Is_Owner_Access (Decl.Type_Info) then
               for Name of Decl.Names loop
                  Render_Cleanup_Item
                    (Buffer,
                     (Name      => Name,
                      Type_Name => Decl.Type_Info.Name),
                     Depth);
               end loop;
            end if;
         end;
      end loop;
   exception
      when Constraint_Error =>
         Raise_Internal ("malformed cleanup declarations during Ada emission");
   end Render_Cleanup;

   procedure Render_Statements
     (Buffer     : in out SU.Unbounded_String;
      Unit       : CM.Resolved_Unit;
      Document   : GM.Mir_Document;
      Statements : CM.Statement_Access_Vectors.Vector;
      State      : in out Emit_State;
      Depth      : Natural;
      Return_Type : String := "")
   is
   begin
      for Item of Statements loop
         if Item = null then
            Raise_Unsupported
              (State,
               FT.Null_Span,
               "encountered null statement during Ada emission");
         end if;

         case Item.Kind is
            when CM.Stmt_Null =>
               Append_Line (Buffer, "null;", Depth);
            when CM.Stmt_Object_Decl =>
               Append_Line
                 (Buffer,
                  Render_Object_Decl_Text (Unit, Document, State, Item.Decl),
                  Depth);
               if Is_Owner_Access (Item.Decl.Type_Info) then
                  State.Needs_Unchecked_Deallocation := True;
               end if;
            when CM.Stmt_Assign =>
               Append_Assignment (Buffer, Unit, Document, State, Item.all, Depth);
            when CM.Stmt_Call =>
               Append_Line
                 (Buffer,
                  Render_Expr (Unit, Document, Item.Call, State) & ";",
                  Depth);
            when CM.Stmt_Return =>
               Render_Active_Cleanup (Buffer, State, Depth);
               Append_Return
                 (Buffer,
                  Unit,
                  Document,
                  State,
                  Item.Value,
                  Return_Type,
                  Depth);
            when CM.Stmt_If =>
               Append_Line
                 (Buffer,
                  "if " & Render_Expr (Unit, Document, Item.Condition, State) & " then",
                  Depth);
               Render_Statements
                 (Buffer, Unit, Document, Item.Then_Stmts, State, Depth + 1, Return_Type);
               for Part of Item.Elsifs loop
                  Append_Line
                    (Buffer,
                     "elsif " & Render_Expr (Unit, Document, Part.Condition, State) & " then",
                     Depth);
                  Render_Statements
                    (Buffer, Unit, Document, Part.Statements, State, Depth + 1, Return_Type);
               end loop;
               if Item.Has_Else then
                  Append_Line (Buffer, "else", Depth);
                  Render_Statements
                    (Buffer, Unit, Document, Item.Else_Stmts, State, Depth + 1, Return_Type);
               end if;
               Append_Line (Buffer, "end if;", Depth);
            when CM.Stmt_While =>
               Append_Line
                 (Buffer,
                  "while " & Render_Expr (Unit, Document, Item.Condition, State) & " loop",
                  Depth);
               Render_Statements
                 (Buffer, Unit, Document, Item.Body_Stmts, State, Depth + 1, Return_Type);
               Append_Line (Buffer, "end loop;", Depth);
            when CM.Stmt_For =>
               Append_Line
                 (Buffer,
                  "for "
                  & FT.To_String (Item.Loop_Var)
                  & " in "
                  & Render_Discrete_Range (Unit, Document, Item.Loop_Range, State)
                  & " loop",
                  Depth);
               Render_Statements
                 (Buffer, Unit, Document, Item.Body_Stmts, State, Depth + 1, Return_Type);
               Append_Line (Buffer, "end loop;", Depth);
            when CM.Stmt_Block =>
               declare
                  Previous_Wide_Count : constant Ada.Containers.Count_Type :=
                    State.Wide_Local_Names.Length;
               begin
                  Collect_Wide_Locals
                    (Unit, Document, State, Item.Declarations, Item.Body_Stmts);
                  Push_Cleanup_Frame (State);
                  Register_Cleanup_Items (State, Item.Declarations);
                  Append_Line (Buffer, "declare", Depth);
                  Render_Block_Declarations
                    (Buffer, Unit, Document, Item.Declarations, State, Depth + 1);
                  Render_Free_Declarations (Buffer, Item.Declarations, Depth + 1);
                  Append_Line (Buffer, "begin", Depth);
                  Render_Statements
                    (Buffer, Unit, Document, Item.Body_Stmts, State, Depth + 1, Return_Type);
                  Render_Cleanup (Buffer, Item.Declarations, Depth + 1);
                  Append_Line (Buffer, "end;", Depth);
                  Pop_Cleanup_Frame (State);
                  Restore_Wide_Names (State, Previous_Wide_Count);
               end;
            when CM.Stmt_Loop =>
               Append_Line (Buffer, "loop", Depth);
               Render_Statements
                 (Buffer, Unit, Document, Item.Body_Stmts, State, Depth + 1, Return_Type);
               Append_Line (Buffer, "end loop;", Depth);
            when CM.Stmt_Exit =>
               if Item.Condition /= null then
                  Append_Line
                    (Buffer,
                     "exit when " & Render_Expr (Unit, Document, Item.Condition, State) & ";",
                     Depth);
               else
                  Append_Line (Buffer, "exit;", Depth);
               end if;
            when CM.Stmt_Send =>
               State.Needs_Gnat_Adc := True;
               Append_Line
                 (Buffer,
                  Render_Expr (Unit, Document, Item.Channel_Name, State)
                  & ".Send ("
                  & Render_Channel_Send_Value
                      (Unit, Document, State, Item.Channel_Name, Item.Value)
                  & ");",
                  Depth);
            when CM.Stmt_Receive =>
               State.Needs_Gnat_Adc := True;
               Append_Line
                 (Buffer,
                  Render_Expr (Unit, Document, Item.Channel_Name, State)
                  & ".Receive ("
                  & Render_Expr (Unit, Document, Item.Target, State)
                  & ");",
                  Depth);
            when CM.Stmt_Try_Send =>
               State.Needs_Gnat_Adc := True;
               Append_Line (Buffer, "select", Depth);
               Append_Line
                 (Buffer,
                  Render_Expr (Unit, Document, Item.Channel_Name, State)
                  & ".Send ("
                  & Render_Channel_Send_Value
                      (Unit, Document, State, Item.Channel_Name, Item.Value)
                  & ");",
                  Depth + 1);
               Append_Line
                 (Buffer,
                  Render_Expr (Unit, Document, Item.Success_Var, State) & " := True;",
                  Depth + 1);
               Append_Line (Buffer, "else", Depth);
               Append_Line
                 (Buffer,
                  Render_Expr (Unit, Document, Item.Success_Var, State) & " := False;",
                  Depth + 1);
               Append_Line (Buffer, "end select;", Depth);
            when CM.Stmt_Try_Receive =>
               State.Needs_Gnat_Adc := True;
               Append_Line (Buffer, "select", Depth);
               Append_Line
                 (Buffer,
                  Render_Expr (Unit, Document, Item.Channel_Name, State)
                  & ".Receive ("
                  & Render_Expr (Unit, Document, Item.Target, State)
                  & ");",
                  Depth + 1);
               Append_Line
                 (Buffer,
                  Render_Expr (Unit, Document, Item.Success_Var, State) & " := True;",
                  Depth + 1);
               Append_Line (Buffer, "else", Depth);
               Append_Line
                 (Buffer,
                  Render_Expr (Unit, Document, Item.Success_Var, State) & " := False;",
                  Depth + 1);
               Append_Line (Buffer, "end select;", Depth);
            when CM.Stmt_Select =>
               State.Needs_Gnat_Adc := True;
               declare
                  Has_Channel_Arms : Boolean := False;
               begin
                  for Arm of Item.Arms loop
                     if Arm.Kind = CM.Select_Arm_Channel then
                        Has_Channel_Arms := True;
                     end if;
                  end loop;

                  if Has_Channel_Arms then
                     Append_Line (Buffer, "declare", Depth);
                     for Arm of Item.Arms loop
                        if Arm.Kind = CM.Select_Arm_Channel then
                           Append_Line
                             (Buffer,
                              FT.To_String (Arm.Channel_Data.Variable_Name)
                              & " : "
                              & Render_Type_Name (Arm.Channel_Data.Type_Info)
                              & ";",
                              Depth + 1);
                        end if;
                     end loop;
                     Append_Line (Buffer, "begin", Depth);
                  end if;

                  Append_Line
                    (Buffer,
                     "select",
                     (if Has_Channel_Arms then Depth + 1 else Depth));

                  for Index in Item.Arms.First_Index .. Item.Arms.Last_Index loop
                     declare
                        Arm : constant CM.Select_Arm := Item.Arms (Index);
                        Arm_Depth : constant Natural :=
                          (if Has_Channel_Arms then Depth + 2 else Depth + 1);
                        Select_Depth : constant Natural :=
                          (if Has_Channel_Arms then Depth + 1 else Depth);
                     begin
                        if Index /= Item.Arms.First_Index then
                           Append_Line (Buffer, "or", Select_Depth);
                        end if;

                        case Arm.Kind is
                           when CM.Select_Arm_Channel =>
                              Append_Line
                                (Buffer,
                                 Render_Expr (Unit, Document, Arm.Channel_Data.Channel_Name, State)
                                 & ".Receive ("
                                 & FT.To_String (Arm.Channel_Data.Variable_Name)
                                 & ");",
                                 Arm_Depth);
                              Render_Statements
                                (Buffer,
                                 Unit,
                                 Document,
                                 Arm.Channel_Data.Statements,
                                 State,
                                 Arm_Depth,
                                 Return_Type);
                           when CM.Select_Arm_Delay =>
                              Append_Line
                                (Buffer,
                                 "delay "
                                 & Render_Expr (Unit, Document, Arm.Delay_Data.Duration_Expr, State)
                                 & ";",
                                 Arm_Depth);
                              Render_Statements
                                (Buffer,
                                 Unit,
                                 Document,
                                 Arm.Delay_Data.Statements,
                                 State,
                                 Arm_Depth,
                                 Return_Type);
                           when others =>
                              Raise_Unsupported
                                (State,
                                 Arm.Span,
                                 "unsupported select arm in Ada emission");
                        end case;
                     end;
                  end loop;

                  Append_Line
                    (Buffer,
                     "end select;",
                     (if Has_Channel_Arms then Depth + 1 else Depth));

                  if Has_Channel_Arms then
                     Append_Line (Buffer, "end;", Depth);
                  end if;
               end;
            when CM.Stmt_Delay =>
               State.Needs_Gnat_Adc := True;
               Append_Line
                 (Buffer,
                  "delay " & Render_Expr (Unit, Document, Item.Value, State) & ";",
                  Depth);
            when others =>
               Raise_Unsupported
                 (State,
                  Item.Span,
                  "PR09 emitter does not yet support statement kind '"
                  & Item.Kind'Image
                  & "'");
         end case;
      end loop;
   end Render_Statements;

   procedure Render_Channel_Spec
     (Buffer  : in out SU.Unbounded_String;
      Channel : CM.Resolved_Channel_Decl;
      Bronze  : MB.Bronze_Result)
   is
      Name          : constant String := FT.To_String (Channel.Name);
      Element_Type  : constant String := Render_Type_Name (Channel.Element_Type);
      Capacity      : constant String := Trim_Image (Channel.Capacity);
      Type_Name     : constant String := Name & "_Channel";
      Index_Subtype : constant String := Name & "_Index";
      Count_Subtype : constant String := Name & "_Count";
      Buffer_Type   : constant String := Name & "_Buffer";
      Ceiling       : Long_Long_Integer :=
        (if Channel.Has_Required_Ceiling then Channel.Required_Ceiling else 0);
   begin
      for Item of Bronze.Ceilings loop
         if FT.To_String (Item.Channel_Name) = Name then
            Ceiling := Item.Priority;
            exit;
         end if;
      end loop;
      Append_Line
        (Buffer,
         "subtype " & Index_Subtype & " is Positive range 1 .. " & Capacity & ";",
         1);
      Append_Line
        (Buffer,
         "subtype " & Count_Subtype & " is Natural range 0 .. " & Capacity & ";",
         1);
      Append_Line
        (Buffer,
         "type " & Buffer_Type & " is array (" & Index_Subtype & ") of " & Element_Type & ";",
         1);
      Append_Line
        (Buffer,
         "protected type "
         & Type_Name
         & " with Priority => " & Trim_Image (Ceiling)
         & " is",
         1);
      Append_Line (Buffer, "entry Send (Value : in " & Element_Type & ");", 2);
      Append_Line (Buffer, "entry Receive (Value : out " & Element_Type & ");", 2);
      Append_Line (Buffer, "private", 1);
      Append_Line (Buffer, "Buffer : " & Buffer_Type & ";", 2);
      Append_Line (Buffer, "Head   : " & Index_Subtype & " := " & Index_Subtype & "'First;", 2);
      Append_Line (Buffer, "Tail   : " & Index_Subtype & " := " & Index_Subtype & "'First;", 2);
      Append_Line (Buffer, "Count  : " & Count_Subtype & " := 0;", 2);
      Append_Line (Buffer, "end " & Type_Name & ";", 1);
      Append_Line (Buffer, Name & " : " & Type_Name & ";", 1);
      Append_Line (Buffer);
   end Render_Channel_Spec;

   procedure Render_Channel_Body
     (Buffer  : in out SU.Unbounded_String;
      Channel : CM.Resolved_Channel_Decl)
   is
      Name          : constant String := FT.To_String (Channel.Name);
      Capacity      : constant String := Trim_Image (Channel.Capacity);
      Type_Name     : constant String := Name & "_Channel";
      Index_Subtype : constant String := Name & "_Index";
   begin
      Append_Line (Buffer, "protected body " & Type_Name & " is", 1);
      Append_Line (Buffer, "entry Send (Value : in " & Render_Type_Name (Channel.Element_Type) & ")", 2);
      Append_Line (Buffer, "when Count < " & Capacity & " is", 3);
      Append_Line (Buffer, "begin", 2);
      Append_Line (Buffer, "Buffer (Tail) := Value;", 3);
      Append_Line (Buffer, "if Tail = " & Index_Subtype & "'Last then", 3);
      Append_Line (Buffer, "Tail := " & Index_Subtype & "'First;", 4);
      Append_Line (Buffer, "else", 3);
      Append_Line (Buffer, "Tail := " & Index_Subtype & "'Succ (Tail);", 4);
      Append_Line (Buffer, "end if;", 3);
      Append_Line (Buffer, "Count := Count + 1;", 3);
      Append_Line (Buffer, "end Send;", 2);
      Append_Line (Buffer);
      Append_Line (Buffer, "entry Receive (Value : out " & Render_Type_Name (Channel.Element_Type) & ")", 2);
      Append_Line (Buffer, "when Count > 0 is", 3);
      Append_Line (Buffer, "begin", 2);
      Append_Line (Buffer, "Value := Buffer (Head);", 3);
      Append_Line (Buffer, "if Head = " & Index_Subtype & "'Last then", 3);
      Append_Line (Buffer, "Head := " & Index_Subtype & "'First;", 4);
      Append_Line (Buffer, "else", 3);
      Append_Line (Buffer, "Head := " & Index_Subtype & "'Succ (Head);", 4);
      Append_Line (Buffer, "end if;", 3);
      Append_Line (Buffer, "Count := Count - 1;", 3);
      Append_Line (Buffer, "end Receive;", 2);
      Append_Line (Buffer, "end " & Type_Name & ";", 1);
      Append_Line (Buffer);
   end Render_Channel_Body;

   procedure Render_Free_Declarations
     (Buffer       : in out SU.Unbounded_String;
     Declarations : CM.Resolved_Object_Decl_Vectors.Vector;
     Depth        : Natural)
   is
      Seen : FT.UString_Vectors.Vector;

      function Contains
        (Items : FT.UString_Vectors.Vector;
         Name  : String) return Boolean is
      begin
         for Item of Items loop
            if FT.To_String (Item) = Name then
               return True;
            end if;
         end loop;
         return False;
      end Contains;
   begin
      for Decl of Declarations loop
         if Is_Owner_Access (Decl.Type_Info) then
            declare
               Type_Name : constant String := FT.To_String (Decl.Type_Info.Name);
            begin
               if not Contains (Seen, Type_Name) then
                  Seen.Append (FT.To_UString (Type_Name));
                  Append_Line
                    (Buffer,
                     "procedure Free_"
                     & Type_Name
                     & " is new Ada.Unchecked_Deallocation ("
                     & FT.To_String (Decl.Type_Info.Target)
                     & ", "
                     & Type_Name
                     & ");",
                     Depth);
               end if;
            end;
         end if;
      end loop;
   end Render_Free_Declarations;

   procedure Render_Free_Declarations
     (Buffer       : in out SU.Unbounded_String;
      Declarations : CM.Object_Decl_Vectors.Vector;
      Depth        : Natural)
   is
      Seen : FT.UString_Vectors.Vector;
   begin
      for Decl of Declarations loop
         if Is_Owner_Access (Decl.Type_Info) then
            declare
               Type_Name : constant String := FT.To_String (Decl.Type_Info.Name);
            begin
               if not Contains_Name (Seen, Type_Name) then
                  Seen.Append (FT.To_UString (Type_Name));
                  Append_Line
                    (Buffer,
                     "procedure Free_"
                     & Type_Name
                     & " is new Ada.Unchecked_Deallocation ("
                     & FT.To_String (Decl.Type_Info.Target)
                     & ", "
                     & Type_Name
                     & ");",
                     Depth);
               end if;
            end;
         end if;
      end loop;
   end Render_Free_Declarations;

   procedure Render_Subprogram_Body
     (Buffer     : in out SU.Unbounded_String;
      Unit       : CM.Resolved_Unit;
      Document   : GM.Mir_Document;
      Subprogram : CM.Resolved_Subprogram;
      State      : in out Emit_State)
   is
      Previous_Wide_Count : constant Ada.Containers.Count_Type :=
        State.Wide_Local_Names.Length;
   begin
      Collect_Wide_Locals
        (Unit, Document, State, Subprogram.Declarations, Subprogram.Statements);
      Push_Cleanup_Frame (State);
      Register_Cleanup_Items (State, Subprogram.Declarations);
      Append_Line
        (Buffer,
         FT.To_String (Subprogram.Kind)
         & " "
         & FT.To_String (Subprogram.Name)
         & Render_Subprogram_Params (Unit, Document, Subprogram.Params)
         & Render_Subprogram_Return (Subprogram)
         & " is",
         1);
      Render_Block_Declarations
        (Buffer, Unit, Document, Subprogram.Declarations, State, 2);
      Render_Free_Declarations (Buffer, Subprogram.Declarations, 2);
      Append_Line (Buffer, "begin", 1);
      Render_Statements
        (Buffer,
         Unit,
         Document,
         Subprogram.Statements,
         State,
         2,
         (if Subprogram.Has_Return_Type then Render_Type_Name (Subprogram.Return_Type) else ""));
      Render_Cleanup (Buffer, Subprogram.Declarations, 2);
      Append_Line (Buffer, "end " & FT.To_String (Subprogram.Name) & ";", 1);
      Append_Line (Buffer);
      Pop_Cleanup_Frame (State);
      Restore_Wide_Names (State, Previous_Wide_Count);
   end Render_Subprogram_Body;

   procedure Render_Task_Body
     (Buffer    : in out SU.Unbounded_String;
      Unit      : CM.Resolved_Unit;
      Document  : GM.Mir_Document;
      Task_Item : CM.Resolved_Task;
      State     : in out Emit_State)
   is
      Previous_Wide_Count : constant Ada.Containers.Count_Type :=
        State.Wide_Local_Names.Length;
   begin
      Collect_Wide_Locals
        (Unit, Document, State, Task_Item.Declarations, Task_Item.Statements);
      Append_Line (Buffer, "task body " & FT.To_String (Task_Item.Name) & " is", 1);
      Render_Block_Declarations
        (Buffer, Unit, Document, Task_Item.Declarations, State, 2);
      Render_Free_Declarations (Buffer, Task_Item.Declarations, 2);
      Append_Line (Buffer, "begin", 1);
      Render_Statements
        (Buffer, Unit, Document, Task_Item.Statements, State, 2, "");
      Render_Cleanup (Buffer, Task_Item.Declarations, 2);
      Append_Line (Buffer, "end " & FT.To_String (Task_Item.Name) & ";", 1);
      Append_Line (Buffer);
      Restore_Wide_Names (State, Previous_Wide_Count);
   end Render_Task_Body;

   function Unit_File_Stem (Unit_Name : String) return String is
      Result : String := Unit_Name;
   begin
      for Index in Result'Range loop
         if Result (Index) = '.' then
            Result (Index) := '-';
         else
            Result (Index) := Ada.Characters.Handling.To_Lower (Result (Index));
         end if;
      end loop;
      return Result;
   end Unit_File_Stem;

   function Emit
     (Unit     : CM.Resolved_Unit;
      Document : GM.Mir_Document;
      Bronze   : MB.Bronze_Result) return Artifact_Result
   is
      State      : Emit_State;
      Spec_Inner : SU.Unbounded_String;
      Body_Inner : SU.Unbounded_String;
      Spec_Text  : SU.Unbounded_String;
      Body_Text  : SU.Unbounded_String;
      Body_Withs : FT.UString_Vectors.Vector;

      procedure Add_Body_With (Name : String) is
      begin
         for Item of Body_Withs loop
            if FT.To_String (Item) = Name then
               return;
            end if;
         end loop;
         Body_Withs.Append (FT.To_UString (Name));
      end Add_Body_With;
   begin
      if not Unit.Channels.Is_Empty or else not Unit.Tasks.Is_Empty then
         State.Needs_Gnat_Adc := True;
      end if;

      Append_Line (Spec_Inner, "pragma SPARK_Mode (On);");
      Append_Line (Spec_Inner);
      Append_Line
        (Spec_Inner,
         "package "
         & FT.To_String (Unit.Package_Name)
         & ASCII.LF
         & Indentation (1)
         & "with SPARK_Mode => On,"
         & ASCII.LF
         & Indentation (1)
         & "     Initializes => "
         & Render_Initializes_Aspect (Bronze)
         & ASCII.LF
         & "is");

      for Type_Item of Unit.Types loop
         Append_Line (Spec_Inner, Render_Type_Decl (Type_Item, State), 1);
         if FT.To_String (Type_Item.Kind) = "record" then
            Append_Line (Spec_Inner);
         end if;
      end loop;

      if not Unit.Objects.Is_Empty then
         for Decl of Unit.Objects loop
            Append_Line
              (Spec_Inner,
               Render_Object_Decl_Text (Unit, Document, State, Decl),
               1);
         end loop;
         Append_Line (Spec_Inner);
      end if;

      if not Unit.Channels.Is_Empty then
         for Channel of Unit.Channels loop
            Render_Channel_Spec (Spec_Inner, Channel, Bronze);
         end loop;
      end if;

      if not Unit.Subprograms.Is_Empty then
         for Subprogram of Unit.Subprograms loop
            Append_Line
              (Spec_Inner,
               FT.To_String (Subprogram.Kind)
               & " "
               & FT.To_String (Subprogram.Name)
               & Render_Subprogram_Params (Unit, Document, Subprogram.Params)
               & Render_Subprogram_Return (Subprogram)
               & Render_Subprogram_Aspects (Subprogram, Bronze)
               & ";",
               1);
         end loop;
         Append_Line (Spec_Inner);
      end if;

      if not Unit.Tasks.Is_Empty then
         for Task_Item of Unit.Tasks loop
            Append_Line
              (Spec_Inner,
               "task "
               & FT.To_String (Task_Item.Name)
               & (if Task_Item.Has_Explicit_Priority
                  then " with Priority => " & Trim_Image (Task_Item.Priority)
                  else "")
               & ";",
               1);
         end loop;
         Append_Line (Spec_Inner);
      end if;

      Append_Line (Spec_Inner, "end " & FT.To_String (Unit.Package_Name) & ";");

      Append_Line (Body_Inner, "package body " & FT.To_String (Unit.Package_Name) & " is");
      Append_Line (Body_Inner);

      for Channel of Unit.Channels loop
         Render_Channel_Body (Body_Inner, Channel);
      end loop;

      for Subprogram of Unit.Subprograms loop
         Render_Subprogram_Body (Body_Inner, Unit, Document, Subprogram, State);
      end loop;

      for Task_Item of Unit.Tasks loop
         Render_Task_Body (Body_Inner, Unit, Document, Task_Item, State);
      end loop;

      Append_Line (Body_Inner, "end " & FT.To_String (Unit.Package_Name) & ";");

      if State.Needs_Unchecked_Deallocation then
         Add_Body_With ("Ada.Unchecked_Deallocation");
      end if;
      if State.Needs_Safe_Runtime then
         Add_Body_With ("Safe_Runtime");
      end if;

      for Item of Body_Withs loop
         Append_Line (Body_Text, "with " & FT.To_String (Item) & ";");
      end loop;
      if State.Needs_Safe_Runtime then
         Append_Line (Body_Text, "use type Safe_Runtime.Wide_Integer;");
      end if;
      if not Body_Withs.Is_Empty then
         Append_Line (Body_Text);
      end if;
      Body_Text := Body_Text & Body_Inner;
      Spec_Text := Spec_Inner;

      return
        (Success            => True,
         Unit_Name          => Unit.Package_Name,
         Spec_Text          => FT.To_UString (SU.To_String (Spec_Text)),
         Body_Text          => FT.To_UString (SU.To_String (Body_Text)),
         Needs_Safe_Runtime => State.Needs_Safe_Runtime,
         Needs_Gnat_Adc     => State.Needs_Gnat_Adc);
   exception
      when Emitter_Unsupported =>
         return
           (Success    => False,
            Diagnostic =>
              CM.Unsupported_Source_Construct
                (Path    => FT.To_String (Unit.Path),
                 Span    => State.Unsupported_Span,
                 Message => FT.To_String (State.Unsupported_Message)));
   end Emit;
end Safe_Frontend.Ada_Emit;
