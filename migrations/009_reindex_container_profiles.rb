require 'db/migrations/utils'

Sequel.migration do

  up do
    self[:container_profile].update(:system_mtime => Time.now)
    self[:top_container].update(:system_mtime => Time.now)
  end

  down do
  end

end
