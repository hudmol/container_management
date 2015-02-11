require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:container_profile) do
      drop_constraint("container_profile_name_uniq", :type => :unique)
      drop_column(:repo_id)
      # wow is this allowed? should blow up if the constraint is broken
      add_unique_constraint(:name, :name => "container_profile_name_uniq")
    end

    # trigger reindex
    self[:container_profile].update(:system_mtime => Time.now)
    self[:top_container].update(:system_mtime => Time.now)

    # make the container profile manage permission global
    self[:permission].filter(:permission_code => "manage_container_profile_record").update(:level => "global")
  end

  down do
  end

end
