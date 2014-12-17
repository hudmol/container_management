my_routes = [File.join(File.dirname(__FILE__), "routes.rb")]
ArchivesSpace::Application.config.paths['config/routes'].concat(my_routes)

Rails.application.config.after_initialize do
  require_relative "../yale_container_init"
  require_relative "lib/yale_container_request_handler"

  ApplicationController.class_eval do

    alias_method :find_opts_pre_yale_container, :find_opts

    def find_opts
      orig = find_opts_pre_yale_container
      orig['resolve[]'] = orig['resolve[]'] + ['yale_container']
      orig
    end

  end

  YaleContainerRequestHandler.new(AccessionsController, :accession)
  YaleContainerRequestHandler.new(ResourcesController, :resource)
  YaleContainerRequestHandler.new(ArchivalObjectsController, :archival_object)

end
