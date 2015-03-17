require 'db/migrations/utils'

Sequel.migration do

  up do
    # set this permission to be repository scoped as there in new derived global permission
    self[:permission].filter(:permission_code => "manage_container_profile_record").update(:level => "repository")
  end

  down do
  end

end
