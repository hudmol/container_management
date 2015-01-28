require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:top_container) do
      drop_column(:voyager_id)
      drop_column(:exported_to_voyager)
      add_column(:ils_holding_id, String, :null => true)
      add_column(:ils_item_id, String, :null => true)
      add_column(:exported_to_ils, DateTime, :null => true)
    end
  end

  down do
  end

end
