Permission.define("manage_container",
                  "The ability to manage container records",
                  :level => "repository")

Permission.define("manage_container_profile_record",
                  "The ability to create, modify and delete a container profile record",
                  :level => "repository")

Permission.define("update_container_profile_record",
                  "The ability to create/update/delete container profile records",
                  :implied_by => 'manage_container_profile_record',
                  :level => "global")

require_relative "../yale_container_init"

Dir.glob(File.join(File.dirname(__FILE__), "lib", "*.rb")).sort.each do |file|
  require File.absolute_path(file)
end


# Any record supporting instances needs our compatibility mixin added as well.
# This allows mappings between ArchivesSpace containers and the new container
# model.
ASModel.all_models.each do |model|
  if model.included_modules.include?(Instances)
    model.include(MapToAspaceContainer)
  end
end

if AppConfig.has_key?(:migrate_to_container_management) && AppConfig[:migrate_to_container_management]

  Log.info("Migrating existing containers to the new container model...")

  ContainerManagementMigration.new.run

  Log.info("Completed: existing containers have been migrated to the new container model.")

end
