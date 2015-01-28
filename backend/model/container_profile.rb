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


  def display_string
    name
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['display_string'] = obj.display_string
    end

    jsons
  end


  def validate
    ['width', 'height', 'depth'].each do |dim|
      val = self.method(dim).call
      errors.add(dim.intern, "#{dim} must be a number with no more than 2 decimal places") unless val.match('\A\d+(\.\d\d?)?\Z')
    end

    super
  end

end
