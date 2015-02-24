class AspaceJsonToYaleContainerMapper

  def initialize(json)
    @json = json
  end


  def call
    @json['instances'].each do |instance|

      if instance['sub_container']
        # Just need to make sure there are no conflicting ArchivesSpace containers
        instance.delete('container')
        next
      end

      top_container = get_or_create_top_container(instance)

      instance['sub_container'] = {
        'top_container' => {'ref' => top_container.uri}
      }
    end
  end


  private

  def get_or_create_top_container(instance)
    container = instance['container']

    result = (try_matching_barcode(container) ||
              try_matching_indicator_within_series(container) ||
              try_matching_indicator_within_resource(container))

    if result
      result
    else
      p "UNHANDLED MAPPING - generating new container"
      p ({:instance => instance, :record => @json})
      TopContainer.create_from_json(JSONModel(:top_container).from_hash('barcode' => SecureRandom.hex, 'indicator' => (rand() * 10000).to_i.to_s))
    end

  end


  def get_default_indicator
    if AppConfig.has_key?(:yale_containers_default_indicator)
      AppConfig[:yale_containers_default_indicator]
    else
      '1'
    end
  end


  def try_matching_barcode(container)
    # If we have a barcode, attempt to locate an existing top container
    barcode = container['barcode_1']

    if barcode
      if (top_container = TopContainer[:barcode => barcode])
        top_container
      else
        indicator = container['indicator_1'] || get_default_indicator
        TopContainer.create_from_json(JSONModel(:top_container).from_hash('barcode' => barcode, 'indicator' => indicator))
      end
    else
      nil
    end
  end


  def try_matching_indicator_within_series(container)
    indicator = container['indicator_1']

    return nil if !indicator || !@json.is_a?(JSONModel(:archival_object))

    ao = if @json['uri']
           ArchivalObject[JSONModel(:archival_object).id_for(@json['uri'])]
         elsif @json['parent']
           ArchivalObject[JSONModel(:archival_object).id_for(@json['parent']['ref'])]
         else
           nil
         end

    if ao
      find_top_container_for_indicator(ao.series, indicator)
    else
      nil
    end
  end


  def try_matching_indicator_within_resource(container)
    indicator = container['indicator_1']

    return nil if !indicator

    top_record = if @json.is_a?(JSONModel(:archival_object)) && @json['resource']
                   Resource[JSONModel(:resource).id_for(@json['resource']['ref'])]
                 elsif @json.is_a?(JSONModel(:resource)) && @json['uri']
                   Resource[JSONModel(:resource).id_for(@json['uri'])]
                 elsif @json.is_a?(JSONModel(:accession)) && @json['uri']
                   Accession[JSONModel(:accession).id_for(@json['uri'])]
                 else
                   nil
                 end

    if top_record
      find_top_container_for_indicator(top_record, indicator)
    else
      nil
    end

  end


  def find_top_container_for_indicator(top_record, indicator)
    object_graph = top_record.object_graph

    top_container_link_rlshp = SubContainer.find_relationship(:top_container_link)
    relationship_ids = object_graph.ids_for(top_container_link_rlshp)

    DB.open do |db|
      top_container_ids = db[:top_container_link_rlshp].filter(:id => relationship_ids).select(:top_container_id)
      TopContainer[:indicator => indicator, :id => top_container_ids]
    end

  end

end
