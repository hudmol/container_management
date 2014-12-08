{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/yale_containers",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "type" => {"type" => "string", "dynamic_enum" => "container_type", "ifmissing" => "error"},
      "indicator" => {"type" => "string", "maxLength" => 255, "minLength" => 1, "ifmissing" => "error" },

      "display_string" => {"type" => "string", "readonly" => true},

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

      "barcode" => {"type" => "string", "maxLength" => 255, "minLength" => 1},
      "voyager_id" => {"type" => "string", "maxLength" => 255, "minLength" => 1},
      "exported_to_voyager" => {"type" => "boolean", "default" => false},
      "restricted" => {"type" => "boolean", "default" => false},

      "level" => {"type" => "integer", "readonly" => true},

      "container_locations" => {
        "type" => "array",
        "items" => {
          "type" => "JSONModel(:container_location) object",
        }
      }

    },
  },
}
