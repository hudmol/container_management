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

end
