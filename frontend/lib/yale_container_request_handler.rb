[AccessionsController, ResourcesController, ArchivalObjectsController].each do |klass|
  klass.class_eval do
    alias_method :orig_create, :create
    alias_method :orig_update, :update

    def create
      puts "*** custom create"

      orig_create
    end

    def update
      puts "*** custom update"

      orig_update
    end
  end
end