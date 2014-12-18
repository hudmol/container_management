class CommonIndexer

  @@record_types << :top_container

  add_indexer_initialize_hook do |indexer|
    indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'top_container'
        doc['title'] = record['record']['display_string']
      end
    }
  end

  @@record_types << :container_profile

  self.add_indexer_initialize_hook do |indexer|
    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'container_profile'
        doc['json'] = record['record'].to_json
        doc['title'] = record['record']['name']
      end
    }
  end

end
