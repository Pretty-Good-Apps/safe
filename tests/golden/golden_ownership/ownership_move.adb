with Ada.Unchecked_Deallocation;

package body ownership_Move with SPARK_Mode => On is

   procedure transfer is
      Source : payload_Ptr := new payload'(value => 42);
      Target : payload_Ptr := null;
      procedure Free_payload_Ptr is new Ada.Unchecked_Deallocation (payload, payload_Ptr);
   begin
      Target := Source;
      Source := null;
      Target.all.value := 100;
      Free_payload_Ptr (Target);
      Free_payload_Ptr (Source);
   end transfer;

end ownership_Move;
