require 'db/migrations/utils'

Sequel.migration do

  up do

    create_table(:rights_restriction) do
      primary_key :id

      Integer :resource_id
      Integer :archival_object_id

      Date :begin, :null => false
      Date :end, :null => false
    end


    alter_table(:rights_restriction) do
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
    end



    create_table(:rights_restriction_type) do
      primary_key :id

      Integer :rights_restriction_id, :null => false
      String :restriction_type, :null => false
    end

    alter_table(:rights_restriction_type) do
      add_foreign_key([:rights_restriction_id], :rights_restriction, :key => :id, :on_delete => :cascade)
    end

  end

end
