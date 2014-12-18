class ContainerProfile < Sequel::Model(:container_profile)
  include ASModel
  corresponds_to JSONModel(:container_profile)

  set_model_scope :repository
  repo_unique_constraint(:name,
                         :message => "container profile name not unique",
                         :json_property => :name)

  include Relationships
  define_relationship(:name => :top_container_profile,
                      :contains_references_to_types => proc {[TopContainer]},
                      :is_array => false)

end
