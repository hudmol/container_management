# Take our record containing Yale containers and generate corresponding
# ArchivesSpace container records.
class SubContainerToAspaceJsonMapper

  include JSONModel

  def initialize(instance_json, instance_obj)
    @instance_json = instance_json
    @instance_obj = instance_obj
  end


  def to_hash
    result = Hash[JSONModel(:container).schema['properties'].map {|property, _| [property, self.send(property.intern)]}]

    result
  end


  def type_1
    'box'
  end


  def indicator_1
    top_container_jsonmodel['indicator']
  end


  def barcode_1
    top_container_jsonmodel['barcode']
  end


  def container_locations
    top_container_jsonmodel['container_locations']
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

  def top_container_jsonmodel
    @top_container_jsonmodel ||= TopContainer.to_jsonmodel(top_container)
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
