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


  SearchHelper.class_eval do

    alias_method :can_edit_search_result_pre_yale_container?, :can_edit_search_result?

    def can_edit_search_result?(record)
      return user_can?('update_container_record', record['id']) if record['primary_type'] === "top_container"
      can_edit_search_result_pre_yale_container?(record)
    end

  end


  ApplicationHelper.class_eval do
    alias_method :render_aspace_partial_pre_container_management, :render_aspace_partial
    def render_aspace_partial(args)
      result = render_aspace_partial_pre_container_management(args);

      if args[:partial] == "notes/template"
        render args.merge(:partial => "notes/template_override")
      end

      result
    end
  end

  # force load our JSONModels so the are registered rather than lazy initialised
  # we need this for parse_reference to work
  JSONModel(:top_container)
  JSONModel(:sub_container)
  JSONModel(:container_profile)

end
