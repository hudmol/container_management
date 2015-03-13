{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "parent" => "note_multipart",

    "properties" => {

      "type" => {
        "type" => "string",
        "ifmissing" => "error",
        "dynamic_enum" => "note_rights_condition"
      },

      "begin" => {"type" => "string", "maxLength" => 255},
      "end" => {"type" => "string", "maxLength" => 255},

    },
  },
}
