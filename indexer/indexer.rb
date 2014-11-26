class YaleContainerIndexedRecord

  def initialize(record)
    @record = record['record']
  end

  def title
    segments = []
    current = @record

    while current
      segments << "#{current['type']} #{current['indicator']}"
      current = current.fetch('parent', {}).fetch('_resolved', nil)
    end

    segments.join(" / ")
  end

end


class CommonIndexer

  @@record_types << :yale_container

  # Resolve Yale Container parents two levels deep to ensure we always get all three.
  add_attribute_to_resolve("parent::parent")

  add_indexer_initialize_hook do |indexer|
    indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'yale_container'
        container = YaleContainerIndexedRecord.new(record)
        doc['title'] = container.title

        p doc
      end
    }
  end

end
