Permission.define("manage_container",
                  "The ability to manage container records",
                  :level => "repository")

Permission.define("manage_container_profile_record",
				  "The ability to create/update/delete container profile records",
				  :level => "repository")

require_relative "../yale_container_init"
