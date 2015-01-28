require 'uri'
require 'net/http'

class TopContainer < Sequel::Model(:top_container)
  include ASModel

  include Relationships

  corresponds_to JSONModel(:top_container)

  set_model_scope :repository


  def validate
    validates_unique([:repo_id, :barcode],
                     :message => "A barcode must be unique within a repository")
    map_validation_to_json_property([:repo_id, :barcode], :barcode)

    super
  end


  def delete
    DB.attempt {
      super
    }.and_if_constraint_fails {
      raise ConflictException.new("Top container in use")
    }

  end


  def format_barcode
    if self.barcode
      "[#{self.barcode}]"
    end
  end


  # For Archival Objects, the series is the topmost record in the tree.
  def tree_top(obj)
    if obj.respond_to?(:series)
      obj.series
    else
      nil
    end
  end


  # return the first archival record linked to this top container
  def linked_archival_record
    # Take the first linked subcontainer
    subcontainer = related_records(:top_container_link).first
    return nil if !subcontainer

    # Take its first instance
    instance = Instance[subcontainer.instance_id] or raise "Instance not found: #{subcontainer.instance_id}"

    # Find the record that links to that instance
    ASModel.all_models.each do |model|
      next unless model.associations.include?(:instance)

      association = model.association_reflection(:instance)

      key = association[:key]

      if instance[key]
        return model[instance[key]]
      end
    end

    nil
  end


  def collection
    obj = linked_archival_record

    if obj.respond_to?(:series)
      obj.class.root_model[obj.root_record_id]
    else
      obj
    end
  end


  def series
    tree_top(linked_archival_record)
  end


  def self.find_title_for(series)
    series.respond_to?(:display_string) ? series.display_string : series.title
  end


  def series_label
    series_record = series

    if series
      level = series.other_level || I18n.t("enumerations.archival_record_level.#{series.level}", series.level)
      "#{level} #{series.component_id}"
    end
  end


  def display_string
    ["Container", "#{indicator}:", series_label, format_barcode].compact.join(" ")
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['display_string'] = obj.display_string

      if series = obj.series
        json['series'] = {
          'ref' => series.uri,
          'identifier' => series.component_id,
          'display_string' => find_title_for(series)
        }
      end
      if collection = obj.collection
        json['collection'] = {
          'ref' => collection.uri,
          'identifier' => Identifiers.format(Identifiers.parse(collection.identifier)),
          'display_string' => find_title_for(collection)
        }
      end

      if json['exported_to_ils']
        json['exported_to_ils'] = json['exported_to_ils'].getlocal.iso8601
      end

    end

    jsons
  end


  define_relationship(:name => :top_container_housed_at,
                      :json_property => 'container_locations',
                      :contains_references_to_types => proc {[Location]},
                      :class_callback => proc { |clz|
                        clz.instance_eval do
                          plugin :validation_helpers

                          define_method(:validate) do
                            if self[:status] === "previous" && !Location[self[:location_id]].temporary
                              errors.add("container_locations/#{self[:aspace_relationship_position]}/status",
                                         "cannot be previous if Location is not temporary")
                            end

                            super
                          end

                        end
                      })

  define_relationship(:name => :top_container_profile,
                      :json_property => 'container_profile',
                      :contains_references_to_types => proc {[ContainerProfile]},
                      :is_array => false)

  define_relationship(:name => :top_container_link,
                      :contains_references_to_types => proc {[SubContainer]},
                      :is_array => true)


  # Only allow delete if the top containers aren't linked to subcontainers.
  def self.handle_delete(ids)
    linked_subcontainers = find_relationship(:top_container_link).find_by_participant_ids(TopContainer, ids)

    if !linked_subcontainers.empty?
      raise ConflictException.new("Can't remove a Top Container that is still in use")
    end

    super
  end


  def self.search_stream(params, repo_id, &block)
    query = if params[:q]
              Solr::Query.create_keyword_search(params[:q])
            else
              Solr::Query.create_match_all_query
            end


    max_results = AppConfig.has_key?(:max_top_container_results) ? AppConfig[:max_top_container_results] : 10000

    query.pagination(1, max_results).
      set_repo_id(repo_id).
      set_record_types(params[:type]).
      set_filter_terms(params[:filter_term]).
      set_facets(params[:facet])


    query.add_solr_param(:qf, "series_identifier_u_stext collection_identifier_u_stext")

    url = query.to_solr_url
    req = Net::HTTP::Get.new(url.request_uri)

    Net::HTTP.start(url.host, url.port) do |http|
      http.request(req, nil) do |response|
        if response.code =~ /^4/
          raise response.body
        end

        block.call(response)
      end
    end
  end

end
