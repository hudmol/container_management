module MapToAspaceContainer

  def self.included(base)
    base.extend(ClassMethods)
  end


  # FIXME Test this...
  def self.mapper
    if AppConfig.has_key?(:map_to_aspace_container_class)
      @mapper ||= Kernel.const_get(AppConfig[:map_to_aspace_container_class].intern)
    else
      @mapper ||= SubContainerToAspaceMapper
    end
  end


  def self.mapper=(clz)
    @mapper = clz
  end


  module ClassMethods

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |instance_json, instance_obj|
        next unless instance_json['sub_container']

        instance_json['container'] = map_yale_container(instance_json, instance_obj)
      end

      jsons
    end


    private

    def map_yale_container(instance_json, instance_object)
      mapper = MapToAspaceContainer.mapper.new(instance_json, instance_object)
      mapper.to_hash
    end

  end

end
