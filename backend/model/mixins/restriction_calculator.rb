module RestrictionCalculator

  def self.included(base)
    base.extend(ClassMethods)
  end

  def restrictions
    # top container -> instance -> linked record -> restriction

    relationship_model = TopContainer.find_relationship(:top_container_link)
    subcontainers_for_this_top_container = relationship_model.filter(:top_container_id => self.id).select(:sub_container_id)
    linked_instances = SubContainer.filter(:id => subcontainers_for_this_top_container).select(:instance_id)

    models_supporting_rights_restrictions = RightsRestriction.applicable_models.values

    models_supporting_rights_restrictions.map {|model|
      instance_link_column = model.association_reflection(:instance)[:key]

      id_set = Instance.filter(:id => linked_instances).where { Sequel.~(instance_link_column => nil) }.
               select(instance_link_column).
               map {|row| row[instance_link_column]}

      model_to_record_ids = Implementation.expand_to_tree(model, id_set)

      model_to_record_ids.map {|restriction_model, restriction_ids|
        restriction_link_column = restriction_model.association_reflection(:rights_restriction)[:key]
        RightsRestriction.filter(restriction_link_column => restriction_ids).all
      }
    }.flatten.uniq(&:id)
  end


  def active_restrictions(clock = Date)
    now = clock.today

    restrictions.select {|restriction|
      if restriction.rights_restriction_type.empty?
        false
      elsif restriction.begin && now < restriction.begin
        false
      elsif restriction.end && now > restriction.end
        false
      else
        true
      end
    }
  end


  module ClassMethods

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |json, obj|
        json['active_restrictions'] = obj.active_restrictions.map {|restriction|
          RightsRestriction.to_jsonmodel(restriction)
        }
      end

      jsons
    end

  end



  module Implementation

    def self.expand_to_tree(model, id_set)
      return {model => id_set} unless  model.included_modules.include?(TreeNodes)

      rec_ids = id_set
      new_rec_ids = rec_ids

      while true
        new_rec_ids = model.filter(:id => new_rec_ids).select(:parent_id).map(&:parent_id).compact

        if new_rec_ids.empty?
          break
        else
          rec_ids += new_rec_ids
        end
      end

      rec_ids = rec_ids.uniq

      {
        model => rec_ids,
        model.root_model => model.filter(:id => rec_ids).select(:root_record_id).map(&:root_record_id).uniq
      }
    end

  end
end
