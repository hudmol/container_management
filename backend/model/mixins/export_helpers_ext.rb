module ExportHelpers

  def generate_ead(id, include_unpublished, include_daos, use_numbered_c_tags)
    obj = resolve_references(Resource.to_jsonmodel(id), ['repository', 'linked_agents', 'subjects', 'tree', 'digital_object', 'top_container::container_profile'])
    opts = {
      :include_unpublished => include_unpublished,
      :include_daos => include_daos,
      :use_numbered_c_tags => use_numbered_c_tags
    }

    ead = ASpaceExport.model(:ead).from_resource(JSONModel(:resource).new(obj), opts)
    ASpaceExport::stream(ead)
  end

end