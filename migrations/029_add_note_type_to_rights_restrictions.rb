require 'db/migrations/utils'

Sequel.migration do

  up do

    alter_table(:rights_restriction) do
      add_column :restriction_note_type, String
    end

  end

end
