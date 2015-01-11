require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:top_container) do
      drop_column(:type_id)
    end
  end

  down do
  end

end
