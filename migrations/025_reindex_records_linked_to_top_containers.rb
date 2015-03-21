require 'db/migrations/utils'

Sequel.migration do

  up do
    now = Time.now
    self[:resource].update(:system_mtime => now)
    self[:archival_object].update(:system_mtime => now)
    self[:accession].update(:system_mtime => now)
  end

  down do
  end

end
