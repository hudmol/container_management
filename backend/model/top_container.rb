class TopContainer < Sequel::Model(:top_container)
  include ASModel

  include Relationships

  corresponds_to JSONModel(:top_container)

  set_model_scope :repository


  def validate
    validates_unique([:repo_id, :barcode],
                     :message => "A barcode must be unique within a repository")
    map_validation_to_json_property([:repo_id, :barcode], :barcode)



    errors.add("barcode", "You must provide a barcode for top-level containers") if barcode.nil?

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
    self.barcode ? "[#{self.barcode}]" : ""
  end


  # For Archival Objects, the series is the topmost record in the tree.
  def tree_top(obj)
    return obj if !obj.is_a?(TreeNodes)

    while obj.parent_id
      obj = obj.class[obj.parent_id]
    end

    obj
  end


  def series
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
        return tree_top(model[instance[key]])
      end
    end

    nil
  end


  def series_display_string
    series_record = series

    if series_record
      ": #{series_record.display_string}"
    else
      ""
    end
  end


  def container_profile_display_string
    container_profile = related_records(:top_container_profile)
    if container_profile
      container_profile.display_string
    else
      ""
    end
  end


  def display_string
    "#{self.container_profile_display_string} #{self.indicator} #{self.format_barcode} #{self.series_display_string}".strip
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['display_string'] = obj.display_string
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

end
