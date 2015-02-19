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

    check = BarcodeCheck.new(Repository[self.class.active_repository].repo_code)

    if !check.valid?(self[:barcode])
      errors.add(:barcode, "Length must be within the range set in configuration")
    end

    super
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


  # return all archival records linked to this top container
  def linked_archival_records
    related_records(:top_container_link).map {|subcontainer|
      linked_archival_record_for(subcontainer)
    }.compact.uniq {|obj| obj.uri}
  end


  def linked_archival_record_for(subcontainer)
    # Find its linked instance
    instance = Instance[subcontainer.instance_id]

    return nil unless instance

    # Find the record that links to that instance
    ASModel.all_models.each do |model|
      next unless model.associations.include?(:instance)

      association = model.association_reflection(:instance)

      key = association[:key]

      if instance[key]
        return model[instance[key]]
      end
    end
  end


  def collections
    linked_archival_records.map {|obj|
      if obj.respond_to?(:series)
        # An Archival Object
        if obj.root_record_id
          obj.class.root_model[obj.root_record_id]
        else
          # An Archival Object without a resource.  Doesn't really happen in
          # normal usage, but the data model does support this...
          nil
        end
      else
        obj
      end
    }.compact.uniq {|obj| obj.uri}
  end


  def series
    linked_archival_records.map {|record| tree_top(record)}.compact.uniq {|obj| obj.uri}
  end


  def self.find_title_for(series)
    series.respond_to?(:display_string) ? series.display_string : series.title
  end


  def level_display_string(series)
    series.other_level || I18n.t("enumerations.archival_record_level.#{series.level}", series.level)
  end

  def series_label
    attached_series = self.series
    if attached_series.empty?
      nil
    else
      attached_series.map {|s| "#{level_display_string(s)} #{s.component_id}" }.join("; ")
    end
  end


  def display_string
    ["Container", "#{indicator}:", series_label, format_barcode].compact.join(" ")
  end


  def long_display_string
    resource = collections.first
    resource &&= resource.title
    container_profile = related_records(:top_container_profile)
    container_profile &&= container_profile.name
    container_bit = ["Container", "#{indicator}", format_barcode].compact.join(" ")

    [resource, series_label, container_bit, container_profile].compact.join(", ")
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['display_string'] = obj.display_string
      json['long_display_string'] = obj.long_display_string

      obj.series.each do |series|
        json['series'] ||= []
        json['series'] << {
          'ref' => series.uri,
          'identifier' => series.component_id,
          'display_string' => find_title_for(series),
          'level_display_string' => obj.level_display_string(series)
        }
      end

      obj.collections.each do |collection|
        json['collection'] ||= []
        json['collection'] << {
          'ref' => collection.uri,
          'identifier' => Identifiers.format(Identifiers.parse(collection.identifier)),
          'display_string' => find_title_for(collection)
        }
      end

      if json['exported_to_ils']
        json['exported_to_ils'] = json['exported_to_ils'].getlocal.iso8601
      end

      obj.rights_restricted_contents.each do |contents|
        json['rights_restricted_contents'] ||= []
        json['rights_restricted_contents'] << {
          'ref' => contents.uri,
          'type' => contents.class.my_jsonmodel.record_type,
          'display_string' => find_title_for(contents)
        }
      end

      if obj.override_restricted == 0
        json['restricted'] = !json['rights_restricted_contents'].empty?
      end
    end

    jsons
  end


  def rights_restricted_contents
    linked_archival_records.select {|ao| ao.restricted_by_rights?}.uniq(&:uri)
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


  # When deleting a top_container, delete all related instances and their subcontainers
  def delete
    related_records(:top_container_link).map {|sub| Instance[sub.instance_id].delete }
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


  def self.batch_update(ids, fields)
    out = {}
    begin
      n = self.filter(:id => ids).update(fields.merge({:system_mtime => Time.now, :user_mtime => Time.now}))
      out[:records_updated] = n
    rescue
      out[:error] = $!
    end
    out
  end


  def self.bulk_update_container_profile(ids, container_profile_uri)
    out = {}
    cp_id = JSONModel(:container_profile).id_for(container_profile_uri)
    now = Time.now
    begin
      DB.open do |db|
        db[:top_container_profile_rlshp].filter(:top_container_id => ids).delete
        
        ids.each do |id|
          db[:top_container_profile_rlshp].insert(:top_container_id => id,
                                                  :container_profile_id => cp_id,
                                                  :aspace_relationship_position => 1,
                                                  :system_mtime => now,
                                                  :user_mtime => now)
          db[:top_container].filter(:id => id).update(:system_mtime => now)
          out[:records_updated] ||= 0
          out[:records_updated] += 1
        end
        db[:container_profile].filter(:id => cp_id).update(:system_mtime => now)
      end
    rescue
      out[:error] = $!
    end
    out
  end


  def self.bulk_update_barcodes(barcode_data)
    updated = []

    # null out barcodes to avoid duplicate error as bulk updates are applied
    TopContainer.filter(:id => barcode_data.map{|uri,_| my_jsonmodel.id_for(uri)}).update(:barcode => nil)

    barcode_data.each do |uri, barcode|
      id = my_jsonmodel.id_for(uri)

      top_container = TopContainer[id]
      top_container.barcode = barcode
      top_container.system_mtime = Time.now
      top_container.save(:columns => [:barcode, :system_mtime])

      updated << id
    end

    updated
  end
end
