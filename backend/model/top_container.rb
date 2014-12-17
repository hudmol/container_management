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


#  def self.create_from_json(json, opts = {})
#    super
#  end


#  def update_from_json(json, opts = {})
#    super
#  end


  def format_barcode
    self.barcode ? "[#{self.barcode}]" : ""
  end


  def display_string
    "#{I18n.t("enumerations.container_type.#{self.type}")} #{self.indicator} #{self.format_barcode}".strip
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


end
