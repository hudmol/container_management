Permission.define("manage_yale_container",
                  "The ability to manage yale container records",
                  :level => "repository")

Permission.define("manage_container_profile_record", 
				  "The ability to create/update/delete container profile records", 
				  :level => "repository")

require_relative "../yale_container_init"
