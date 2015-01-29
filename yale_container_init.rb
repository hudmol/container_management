module JSONModel
  module Validations

    self.singleton_class.send(:alias_method, :check_instance_pre_yale_container, :check_instance)

    def self.check_instance(hash)
      if hash['sub_container']
        []
      else
        check_instance_pre_yale_container(hash)
      end
    end


    def self.check_sub_container(hash)
      errors = []

      if (!hash["type_2"].nil? && hash["indicator_2"].nil?) || (hash["type_2"].nil? && !hash["indicator_2"].nil?)
        errors << ["type_2", "container 2 requires both a type and indicator"]
      end

      if (hash["type_2"].nil? && hash["indicator_2"].nil? && (!hash["type_3"].nil? || !hash["indicator_3"].nil?))
        errors << ["type_2", "container 2 is required if container 3 is provided"]
      end

      if (!hash["type_3"].nil? && hash["indicator_3"].nil?) || (hash["type_3"].nil? && !hash["indicator_3"].nil?)
        errors << ["type_3", "container 3 requires both a type and indicator"]
      end

      errors
    end

    if JSONModel(:sub_container)
      JSONModel(:sub_container).add_validation("check_sub_container") do |hash|
        check_sub_container(hash)
      end
    end


    def self.check_container_profile(hash)
      errors = []

      # Ensure depth, width and height have no more than 2 decimal places
      ["depth", "width", "height"].each do |k|
        if hash[k] !~ /\A\d+(\.\d\d?)?\Z/
          errors << [k, "must be a number with no more than 2 decimal places"]
        end
      end

      errors
    end

    if JSONModel(:container_profile)
      JSONModel(:container_profile).add_validation("check_container_profile") do |hash|
        check_container_profile(hash)
      end
    end

  end
end
