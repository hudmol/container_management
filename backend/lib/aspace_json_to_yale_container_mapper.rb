class AspaceJsonToYaleContainerMapper

  include JSONModel

  def initialize(json)
    @json = json
  end


  def call
    @json['instances'].each do |instance|

      if instance['sub_container'] || instance['digital_object']
        # Just need to make sure there are no conflicting ArchivesSpace containers
        instance.delete('container')
        next
      end

      top_container = get_or_create_top_container(instance)

      ensure_harmonious_values(TopContainer.to_jsonmodel(top_container), instance['container'])

      instance['sub_container'] = {
        'top_container' => {'ref' => top_container.uri},
        'type_2' => instance['container']['type_2'],
        'indicator_2' => instance['container']['indicator_2'],
        'type_3' => instance['container']['type_3'],
        'indicator_3' => instance['container']['indicator_3'],
      }

      # No need for the original value now.
      instance.delete('container')
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
      rec = {:instance => instance, :record => @json}
      Log.warn("Hit unhandled mapping for top container: #{rec.inspect}")

      TopContainer.create_from_json(JSONModel(:top_container).from_hash('indicator' => get_default_indicator))
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
    # If we have a barcode, attempt to locate an existing top container but create one if needed
    barcode = container['barcode_1']

    if barcode
      if (top_container = TopContainer.for_barcode(barcode))
        top_container
      else
        indicator = container['indicator_1'] || get_default_indicator
        TopContainer.create_from_json(JSONModel(:top_container).from_hash('barcode' => barcode,
                                                                          'indicator' => indicator,
                                                                          'container_locations' => container['container_locations']
                                                                         ))
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
      find_top_container_for_indicator(ao.topmost_archival_object, indicator)
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


  def ensure_harmonious_values(top_container, aspace_container)
    properties = {:indicator => 'indicator_1', :barcode => 'barcode_1'}

    properties.each do |top_container_property, aspace_property|
      if aspace_container[aspace_property] && top_container[top_container_property] != aspace_container[aspace_property]
        raise ValidationException.new(:errors => ["Mismatch when mapping between #{top_container_property} and #{aspace_property}"],
                                      :object_context => {
                                        :top_container => top_container,
                                        :aspace_container => aspace_container
                                      })
      end
    end


    aspace_locations = Array(aspace_container['container_locations']).map {|container_location| container_location['ref']}
    top_container_locations = Array(top_container['container_locations']).map {|container_location| container_location['ref']}

    if aspace_locations.empty? || ((top_container_locations - aspace_locations).empty? && (aspace_locations - top_container_locations).empty?)
      # All OK!
    else
      raise ValidationException.new(:errors => ["Locations in ArchivesSpace container don't match locations in existing top container"],
                                    :object_context => {
                                      :top_container => top_container,
                                      :aspace_container => aspace_container
                                    })
    end

  end

end
