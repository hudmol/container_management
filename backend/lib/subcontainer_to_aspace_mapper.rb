class SubContainerToAspaceMapper

  def initialize(instance_json, instance_obj)
    @instance_json = instance_json
    @instance_obj = instance_obj
  end


  def to_hash
    Hash[JSONModel(:container).schema['properties'].map {|property, _| [property, self.send(property.intern)]}]
  end


  def type_1
    if container_profile.name =~ /Flat Grey/
      'carton'
    else
      raise "Unknown type_1: #{self}"
    end
  end


  def indicator_1
    top_container.indicator
  end


  def barcode_1
    top_container.barcode
  end


  def method_missing(method, *args)
    nil
  end


  private

  def container_profile
    @container_profile ||= top_container.related_records(:top_container_profile)
  end

  def top_container
    @top_container ||= sub_container.related_records(:top_container_link)
  end

  def sub_container
    @sub_container ||= @instance_obj.sub_container.first
  end

  def type_2
    sub_container.type_2
  end

  def indicator_2
    sub_container.indicator_2
  end

  def type_3
    sub_container.type_3
  end

  def indicator_3
    sub_container.indicator_3
  end


end
