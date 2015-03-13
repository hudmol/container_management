require 'db/migrations/utils'

Sequel.migration do

  up do
    # remove existing rights enums from note_multipart
    # @TODO

    # Add a new enum for a new note type
    create_enum("note_rights_condition", ["accessrestrict", "userestrict"])
  end

  down do
  end

end
