require 'db/migrations/utils'

Sequel.migration do

  up do
    self[:archival_object].update(:system_mtime => Time.now)
  end

  down do
  end

end
