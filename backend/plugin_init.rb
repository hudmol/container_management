Permission.define("manage_container",
                  "The ability to manage container records",
                  :level => "repository")

Permission.define("manage_container_profile_record",
				  "The ability to create/update/delete container profile records",
				  :level => "global")

require_relative "../yale_container_init"

Dir.glob(File.join(File.dirname(__FILE__), "lib", "*.rb")).sort.each do |file|
  require File.absolute_path(file)
end
