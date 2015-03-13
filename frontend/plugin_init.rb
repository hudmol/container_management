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
      return user_can?('manage_container', record['id']) if record['primary_type'] === "top_container"
      can_edit_search_result_pre_yale_container?(record)
    end

  end


  NotesHelper.class_eval do

    alias_method :note_types_for_pre_yale_container, :note_types_for
    def note_types_for(jsonmodel_type)
      result = note_types_for_pre_yale_container(jsonmodel_type)

      if jsonmodel_type =~ /resource/ or jsonmodel_type =~ /archival_object/
        # add the note_rights_restriction
        result.merge!(rights_condition_notes)
      end

      result
    end

    def rights_condition_notes
      note_types = {}

      JSONModel.enum_values(JSONModel(:note_rights_condition).schema['properties']['type']['dynamic_enum']).each do |type|
        note_types[type] = {
          :target => :note_rights_condition,
          :enum => JSONModel(:note_rights_condition).schema['properties']['type']['dynamic_enum'],
          :value => type,
          :i18n => I18n.t("enumerations.#{JSONModel(:note_rights_condition).schema['properties']['type']['dynamic_enum']}.#{type}", :default => type)
        }
      end

      note_types
    end

  end


  # force load our JSONModels so the are registered rather than lazy initialised
  # we need this for parse_reference to work
  JSONModel(:top_container)
  JSONModel(:sub_container)
  JSONModel(:container_profile)

end
