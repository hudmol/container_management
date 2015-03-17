{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "begin" => {
        "type" => "string",
        "ifmissing" => "error",
      },

      "end" => {
        "type" => "string",
        "ifmissing" => "error",
      },

      # FIXME: This should ultimately be an enumeration
      "local_access_restriction_type" => {
        "type" => "array",
        "items" => {"type" => "string"},
      },
    }
  }
}
