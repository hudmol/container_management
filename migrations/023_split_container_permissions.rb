require 'db/migrations/utils'

Sequel.migration do

  up do
    # Rename manage_container
    self[:permission].filter(:permission_code => "manage_container").update(:permission_code => "manage_container_record")

    # Find the IDs of our existing permissions
    manage_container_record_id = self[:permission].filter(:permission_code => 'manage_container_record').get(:id)
    update_container_record_id = self[:permission].filter(:permission_code => 'update_container_record').get(:id)

    # Create the new 'update_container_record' permission if it doesn't already exist
    if update_container_record_id.nil?
      update_container_record_id = self[:permission].insert(:permission_code => 'update_container_record',
                                                            :description => "The ability to create and update container records",
                                                            :level => 'repository',
                                                            :created_by => 'admin',
                                                            :last_modified_by => 'admin',
                                                            :create_time => Time.now,
                                                            :system_mtime => Time.now,
                                                            :user_mtime => Time.now)


      # and assign it to any groups that had the old permission
      groups = self[:group_permission].filter(:permission_id => manage_container_record_id).select(:group_id)

      groups.each do |group|
        self[:group_permission].insert(:permission_id => update_container_record_id, :group_id => group[:group_id])
      end
    end

  end

  down do
  end

end
