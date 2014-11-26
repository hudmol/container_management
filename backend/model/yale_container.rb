class YaleContainer < Sequel::Model(:yale_container)
  include ASModel
  include Relationships

  corresponds_to JSONModel(:yale_container)

  set_model_scope :repository

  define_relationship(:name => :yale_container,
                      :json_property => 'parent',
                      :contains_references_to_types => proc {[YaleContainer]},
                      :is_array => false)
end
