package IO
  with SPARK_Mode
is
   procedure Put_Line (Text : String)
     with Global => null,
          Always_Terminates;
end IO;
