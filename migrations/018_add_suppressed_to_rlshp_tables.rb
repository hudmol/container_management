require 'db/migrations/utils'

Sequel.migration do

  up do
    [:top_container_link_rlshp, :top_container_housed_at_rlshp,
     :top_container_profile_rlshp].each do |table|
      alter_table(:top_container_link_rlshp) do
        add_column(:suppressed, Integer, :null => false, :default => 0)
      end
    end
  end

  down do
  end

end
