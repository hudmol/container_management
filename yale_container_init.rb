module JSONModel
  module Validations

    self.singleton_class.send(:alias_method, :check_instance_pre_yale_container, :check_instance)

    def self.check_instance(hash)
      if hash['yale_container']
        []
      else
        check_instance_pre_yale_container(hash)
      end
    end

    JSONModel(:yale_container).add_validation("top_level_yale_container_must_have_barcode") do |hash|
      if hash['parent'].nil? && hash['barcode'].nil?
        [["barcode", "You must provide a barcode for top-level containers"]]
      else
        []
      end
    end

  end
end
