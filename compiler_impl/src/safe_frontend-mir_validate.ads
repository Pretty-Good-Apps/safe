with Safe_Frontend.Mir_Model;

package Safe_Frontend.Mir_Validate is
   function Validate
     (Document : Safe_Frontend.Mir_Model.Mir_Document)
      return Safe_Frontend.Mir_Model.Validation_Result;

   function Validate_File
     (Path : String) return Safe_Frontend.Mir_Model.Validation_Result;
end Safe_Frontend.Mir_Validate;
