require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:top_container) do
      drop_column :override_restricted
      drop_column :restricted
    end
  end

  down do
  end

end
