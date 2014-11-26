{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/yale_containers/:id",
    "properties" => {

      "barcode" => {"type" => "string", "maxLength" => 255, "minLength" => 1},
      "voyager_id" => {"type" => "string", "maxLength" => 255, "minLength" => 1},
      "exported_to_voyager" => {"type" => "boolean", "default" => false},
      "restricted" => {"type" => "boolean", "default" => false},

      "container_locations" => {
        "type" => "array",
        "items" => {
          "type" => "JSONModel(:container_location) object",
        }
      }

    },
  },
}
