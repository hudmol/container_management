require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:top_container) do
      if $db_type == :mysql
        drop_constraint(:top_container_ibfk_1, :type => :foreign_key)
      end
      drop_column(:type_id)
    end
  end

  down do
  end

end
