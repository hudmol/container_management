class CommonIndexer

  # @@record_types << :yale_container
  #
  # # Resolve Yale Container parents two levels deep to ensure we always get all three.
  # add_attribute_to_resolve("parent::parent")
  #
  # add_indexer_initialize_hook do |indexer|
  #   indexer.add_document_prepare_hook {|doc, record|
  #     if record['record']['jsonmodel_type'] == 'yale_container'
  #       doc['title'] = record['record']['display_string']
  #
  #       p doc
  #     end
  #   }
  # end

end
