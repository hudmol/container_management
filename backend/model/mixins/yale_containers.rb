module YaleContainers

  def self.included(base)
    base.define_relationship(:name => :yale_container_instance,
                             :json_property => 'yale_container',
                             :contains_references_to_types => proc {[YaleContainer]},
                             :is_array => false)
  end

end
