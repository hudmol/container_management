module ReindexTopContainers

  def reindex_top_containers
    # get out if we aren't part of a resource tree
    # TODO: look at this - we probably need to touch this record's top containers at least
    return unless self.root_record_id
    # Find any relationships between a top container and any instance within the current tree.
    tree_object_graph = self.class.root_model[self.root_record_id].object_graph
    top_container_link_rlshp = SubContainer.find_relationship(:top_container_link)
    relationship_ids = tree_object_graph.ids_for(top_container_link_rlshp)

    # Update the mtimes of each top containers
    DB.open do |db|
      top_container_ids = db[:top_container_link_rlshp].filter(:id => relationship_ids).select(:top_container_id)
      TopContainer.filter(:id => top_container_ids).update(:system_mtime => Time.now)
    end
  end


  def update_position_only(*)
    super
    reindex_top_containers
  end


  def delete
    reindex_top_containers
    super
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    result = super

    reindex_top_containers

    result
  end

end
