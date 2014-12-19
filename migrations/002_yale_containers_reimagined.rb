require 'db/migrations/utils'

Sequel.migration do

  up do

    ## Start by dropping everything left over from the first prototype version
    ## (and any failed runs from this one)

    target_tables = [:yale_container, :yale_container_instance_rlshp,
                     :yale_container_housed_at_rlshp, :top_container, :sub_container,
                     :top_container_housed_at_rlshp, :top_container_link_rlshp,
                     :container_profile, :top_container_profile_rlshp]

    target_tables.length.times do
      target_tables.each do |table|
        begin
          drop_table(table)
          $stderr.puts("Dropped: #{table}")
        rescue
        end
      end
    end


    ## On with the show...

    create_table(:top_container) do
      primary_key :id

      Integer :repo_id, :null => false

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      String :barcode
      String :voyager_id
      Integer :exported_to_voyager, :default => 0
      Integer :restricted, :default => 0

      DynamicEnum :type_id, :null => false
      String :indicator, :null => false

      apply_mtime_columns
    end

    alter_table(:top_container) do
      add_unique_constraint([:repo_id, :barcode], :name => "yale_uniq_barcode")
    end


    create_table(:sub_container) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :instance_id

      DynamicEnum :type_2_id
      String :indicator_2

      DynamicEnum :type_3_id
      String :indicator_3

      apply_mtime_columns
    end

    alter_table(:sub_container) do
      add_foreign_key([:instance_id], :instance, :key => :id)
    end


    create_table(:top_container_housed_at_rlshp) do
      primary_key :id
      Integer :top_container_id
      Integer :location_id
      Integer :aspace_relationship_position

      String :jsonmodel_type, :null => false, :default => 'container_location'

      String :status
      Date :start_date
      Date :end_date
      String :note

      apply_mtime_columns(false)
    end

    alter_table(:top_container_housed_at_rlshp) do
      add_foreign_key([:top_container_id], :top_container, :key => :id)
      add_foreign_key([:location_id], :location, :key => :id)
    end


    create_table(:top_container_link_rlshp) do
      primary_key :id
      Integer :top_container_id
      Integer :sub_container_id
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:top_container_link_rlshp) do
      add_foreign_key([:top_container_id], :top_container, :key => :id)
      add_foreign_key([:sub_container_id], :sub_container, :key => :id)
    end


    create_table(:container_profile) do
      primary_key :id

      Integer :repo_id, :null => false
      Integer :lock_version, :default => 0, :null => false

      String :name                     # unique
      String :url, :null => true       # optional

      String :extent_dimension         # enum ('height', 'width', 'depth')
      DynamicEnum :dimension_units_id  # default 'inches'

      String :height                   # validates as float
      String :width                    # validates as float
      String :depth                    # validates as float

      apply_mtime_columns
    end

    alter_table(:container_profile) do
      add_unique_constraint([:name, :repo_id], :name => "container_profile_name_uniq")
    end

    if self[:enumeration].filter(:name => "dimension_units").count == 0
      create_enum("dimension_units", ["inches", "feet", "yards", "millimeters", "centimeters", "meters"])
    end

    create_table(:top_container_profile_rlshp) do
      primary_key :id

      Integer :top_container_id
      Integer :container_profile_id
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:top_container_profile_rlshp) do
      add_foreign_key([:top_container_id], :top_container, :key => :id)
      add_foreign_key([:container_profile_id], :container_profile, :key => :id)
    end
  end

  down do
  end

end
