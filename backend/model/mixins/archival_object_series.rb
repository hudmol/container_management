module ArchivalObjectSeries

  def self.included(base)
    base.extend(ClassMethods)
  end

  def series
    if self.parent_id
      self.class[self.parent_id].series
    else
      self
    end
  end


  module ClassMethods

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |json, obj|
        series = obj.series
        if series
          json['series'] = { 'ref' => series.uri }
        end
      end

      jsons
    end

  end

end
