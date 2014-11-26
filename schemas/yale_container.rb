{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/yale_containers",
    "properties" => {

      "type" => {"type" => "string", "dynamic_enum" => "container_type", "required" => true},
      "indicator" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "required" => true },

      "parent" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "JSONModel(:yale_container) uri"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "metadata" => {"type" => "JSONModel(:yale_container_metadata) object"},

    },
  },
}
