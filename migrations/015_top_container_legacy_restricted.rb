require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:top_container) do
      add_column(:legacy_restricted, String, :default => 'none')
    end
  end

  down do
  end

end
