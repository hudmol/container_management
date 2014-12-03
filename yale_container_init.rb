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

  end
end
