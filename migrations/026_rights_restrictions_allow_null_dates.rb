require 'db/migrations/utils'

Sequel.migration do

  up do

    alter_table(:rights_restriction) do
      set_column_allow_null :begin
      set_column_allow_null :end
    end

  end

end
