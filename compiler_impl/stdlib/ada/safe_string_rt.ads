pragma SPARK_Mode (On);

package Safe_String_RT is
   type Safe_String is private;

   Empty : constant Safe_String;

   function From_Literal (Value : String) return Safe_String
      with Global => null,
           Depends => (From_Literal'Result => Value);
   function Clone (Source : Safe_String) return Safe_String
      with Global => null,
           Depends => (Clone'Result => Source);
   procedure Copy (Target : in out Safe_String; Source : Safe_String)
      with Global => null,
           Always_Terminates,
           Depends => (Target => (Target, Source));
   procedure Free (Value : in out Safe_String)
      with Global => null,
           Always_Terminates,
           Depends => (Value => Value);
   procedure Dispose (Value : Safe_String)
      with Global => null,
           Always_Terminates;

   function To_String (Value : Safe_String) return String
      with Global => null,
           Depends => (To_String'Result => Value);
   function Length (Value : Safe_String) return Natural
      with Global => null,
           Depends => (Length'Result => Value);
   function Slice (Value : Safe_String; Low, High : Natural) return Safe_String
      with Global => null,
           Depends => (Slice'Result => (Value, Low, High));
   function Concat (Left, Right : Safe_String) return Safe_String
      with Global => null,
           Depends => (Concat'Result => (Left, Right));
   function Equal (Left, Right : Safe_String) return Boolean
      with Global => null,
           Depends => (Equal'Result => (Left, Right));

private
   pragma SPARK_Mode (Off);
   type String_Access is access String;
   type Safe_String is record
      Data : String_Access := null;
   end record;
   Empty : constant Safe_String := (Data => null);
end Safe_String_RT;
