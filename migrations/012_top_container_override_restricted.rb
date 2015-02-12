require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:top_container) do
      add_column(:override_restricted, Integer, :default => 0)
    end
  end

  down do
  end

end
