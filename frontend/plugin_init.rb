my_routes = [File.join(File.dirname(__FILE__), "routes.rb")]
ArchivesSpace::Application.config.paths['config/routes'].concat(my_routes)

Rails.application.config.after_initialize do
  require_relative "../yale_container_init"

  ApplicationController.class_eval do

    alias_method :find_opts_pre_yale_container, :find_opts

    def find_opts
      orig = find_opts_pre_yale_container
      orig.merge('resolve[]' => orig['resolve[]'] + ['top_container', 'container_profile'])
    end

  end

  # force load our JSONModels so the are registered rather than lazy initialised
  # we need this for parse_reference to work
  JSONModel(:top_container)
  JSONModel(:sub_container)
  JSONModel(:container_profile)


  # Temporary workaround to get multiple menu items.
  unless Plugins.repository_menu_items.include?('container_profiles')
    Plugins.instance_variable_get(:@config)[:repository_menu_items] << 'container_profiles'
  end
end
