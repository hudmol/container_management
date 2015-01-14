class CommonIndexer

  @@record_types << :top_container

  add_indexer_initialize_hook do |indexer|
    indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'top_container'
        doc['title'] = record['record']['display_string']
        if record['record']['series']
          doc['series_uri_u_sstr'] = record['record']['series']['ref']
          doc['series_title_u_sstr'] = record['record']['series']['display_string']
        end
      end
    }
  end

  @@record_types << :container_profile

  self.add_indexer_initialize_hook do |indexer|
    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'container_profile'
        doc['json'] = record['record'].to_json
        doc['title'] = record['record']['name']

        ['width', 'height', 'depth'].each do |property|
          doc["container_profile_#{property}_u_sstr"] = record['record'][property]
        end

        doc["container_profile_dimension_units_u_sstr"] = record['record']['dimension_units']
      end
    }
  end

end
