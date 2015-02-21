class ExtentCalculator

  def initialize(obj, calculate = true)
    @root_object = obj
    @resource = obj.respond_to?(:root_record_id) ? obj.class.root_model[obj.root_record_id] : nil
    @calculated_extent = nil
    @units = nil
    @container_count = 0
    @containers = {}
    @calculated = false

    @unit_conversions = {
      :inches => {
        :centimeters => 2.54,
        :feet => 1/12,
        :meters => 0.0254
      },
      :centimeters => {
        :inches => 0.393701,
        :feet => 0.0328084,
        :meters => 0.01
      },
      :feet => {
        :inches => 12,
        :centimeters => 2.54*12,
        :meters => 0.3048
      },
      :meters => {
        :inches => 39.3701,
        :feet => 3.28084,
        :centimeters => 100
      }
    }
    total_extent if calculate
  end


  def units(unit = nil)
    return @units unless unit
    return @units if @units == unit
    raise "Unrecognized unit" unless @unit_conversions.keys.include? unit
    old_unit = @units
    @units = unit
    if @calculated_extent
      @calculated_extent = convert(@calculated_extent, old_unit)
      @containers.each_value do |val|
        val[:extent] = convert(val[:extent], old_unit)
      end
    end
  end


  def containers(name = nil)
    if name
      con = @containers[name]
      {:count => con[:count], :extent => published_extent(con[:extent])}
    else
      pub_containers = {}
      @containers.each_key do |k|
        con = @containers[k]
        pub_containers[k] = {:count => con[:count], :extent => published_extent(con[:extent])}
      end
      return pub_containers
    end
  end


  def total_extent(recalculate = false)
    return published_extent if @calculated_extent && !recalculate

    extent = 0

    topcon_rlshp = SubContainer.find_relationship(:top_container_link)
    rel_ids = @root_object.object_graph.ids_for(topcon_rlshp)

    DB.open do |db|
      db[:top_container_link_rlshp].
        filter(:id => rel_ids).
        select(:top_container_id).
        distinct().map{|hash| hash[:top_container_id]}.each do |tc_id|
        rec = TopContainer[tc_id].related_records(:top_container_profile)
        @container_count += 1
        @containers[rec.name] ||= {:count => 0, :extent => 0}
        @containers[rec.name][:count] += 1
        ext = convert(rec.send(rec.extent_dimension.intern).to_f, rec.dimension_units.intern)
        @containers[rec.name][:extent] += ext
        extent += ext
      end
    end

    @calculated = true
    @calculated_extent = extent
    published_extent
  end


  def to_hash
    out = {
      :object => {:uri => @root_object.uri, :title => @root_object.title || @root_object.display_string},
      :total_extent => published_extent,
      :container_count => @container_count,
      :units => @units,
      :containers => containers
    }
    out[:resource] = {:uri => @resource.uri, :title => @resource.title} if @resource
    out
  end


  private

  def convert(val, unit)
    @units ||= unit
    return val if unit == @units
    val * @unit_conversions[unit][@units]    
  end


  def published_extent(extent = nil)
    extent ? extent.round(2) : @calculated_extent.round(2)
  end

end
