class YaleContainerRequestHandler

  def initialize(controller_class, jsonmodel_type)
    @controller_class = controller_class
    @jsonmodel_type = jsonmodel_type

    override_controller_methods
  end


  def override_controller_methods
    jsonmodel_type = @jsonmodel_type

    @controller_class.class_eval do
      alias_method :create_pre_yale_container, :create
      alias_method :update_pre_yale_container, :update

      def create
        resolve_yale_containers

        create_pre_yale_container
      end

      def update
        resolve_yale_containers

        update_pre_yale_container
      end

      def self.jsonmodel_type=(jsonmodel_type)
        @jsonmodel_type = jsonmodel_type
      end

      def self.jsonmodel_type
        @jsonmodel_type
      end

      private

      def resolve_yale_containers
        instance = params[self.class.jsonmodel_type]

        raise instance.inspect
      end
    end

    @controller_class.jsonmodel_type=@jsonmodel_type
  end

end
