require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:top_container) do
      add_index(:indicator)
    end
  end

  down do
  end

end
