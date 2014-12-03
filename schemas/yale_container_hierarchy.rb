{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {

      "yale_container_1" => {"type" => "JSONModel(:yale_container) uri_or_object"},
      "yale_container_2" => {"type" => "JSONModel(:yale_container) uri_or_object"},
      "yale_container_3" => {"type" => "JSONModel(:yale_container) uri_or_object"},

    },
  },
}
