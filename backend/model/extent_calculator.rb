class ExtentCalculator

  def initialize(obj, calculate = true)
    @root_object = obj
    @calculated_extent = nil
    @units = nil
    @container_count = 0
    @containers = {}
    @calculated = false

    @unit_conversions = {
      :inches => {
        :centimeters => 2.54
      },
      :centimeters => {
        :inches => 0.393701
      }
    }
    total_extent if calculate
  end


  def dimension_units(unit = nil)
    return @units unless unit
    return @units if @units == unit
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

    tc_ids = []
    DB.open do |db|
      tc_ids = db[:top_container_link_rlshp].
        filter(:id => rel_ids).
        select(:top_container_id).
        distinct().map{|hash| hash[:top_container_id]}
    end
    tc_ids.each do |tc_id|
      rec = TopContainer[tc_id].related_records(:top_container_profile)
      @container_count += 1
      @containers[rec.name] ||= {:count => 0, :extent => 0}
      @containers[rec.name][:count] += 1
      ext = convert(rec.send(rec.extent_dimension.intern).to_f, rec.dimension_units.intern)
      @containers[rec.name][:extent] += ext
      extent += ext
    end

    @calculated = true
    @calculated_extent = extent
    published_extent
  end


  def to_hash
    {
      :total_extent => published_extent,
      :container_count => @container_count,
      :units => @units,
      :containers => containers
    }
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
