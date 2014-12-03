class YaleContainer < Sequel::Model(:yale_container)
  include ASModel

  corresponds_to JSONModel(:yale_container)

  set_model_scope :repository

  def self.create_from_json(json, opts = {})
    parent = get_parent(json)
    parent_id = parent ? parent.id : nil

    super(json, opts.merge(:parent_id => parent_id))
  end


  def update_from_json(json, opts = {})
    parent = self.class.get_parent(json)

    if parent && parent.id == self.id
      parent_id = nil
    else
      parent_id = parent.id
    end

    super(json, opts.merge(:parent_id => parent_id))
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      if obj.parent_id
        json['parent'] = {'ref' => uri_for(:yale_container, obj.parent_id)}
      end
    end

    jsons
  end


  def self.get_parent(json)
    if json.parent
      parent_id = JSONModel.parse_reference(json.parent['ref'])[:id]
      YaleContainer.get_or_die(parent_id)
    else
       nil
    end
  end


  def self.from_hierarchy(hierarchy)
    created = []
    parent_uri = nil

    (1..3).each do |container_number|
      prop = :"yale_container_#{container_number}"

      break unless hierarchy[prop]
      new_container_definition = hierarchy[prop]

      if new_container_definition.is_a?(String)
        # A reference to an existing container
        parent_uri = new_container_definition
      else
        # Set the parent
        parent_ref = parent_uri ? {'parent' => {'ref' => parent_uri}} : {}

        json = JSONModel(:yale_container).from_hash(new_container_definition.merge(parent_ref))
        new_container = self.create_from_json(json)

        parent_uri = new_container.uri
        created << new_container
      end
    end

    created
  end

end
