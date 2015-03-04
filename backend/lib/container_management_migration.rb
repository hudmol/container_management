class ContainerManagementMigration


  def run

    # THINKME: Need to preserve mtimes at all?

    mappings = [ArchivalObject, Resource, Accession]

    Repository.all.each do |repo|

      RequestContext.open(:repo_id => repo.id) do

        mappings.each do |clz|
          join_column = clz.association_reflection(:instance)[:key]

          records_with_containers = clz.join(:instance, join_column => :id).join(:container, :instance_id => :id)

          ids = clz.filter(:repo_id => repo.id, :id => records_with_containers.select(Sequel.qualify(clz.table_name, :id))).select(:id).map {|row| row[:id]}

          ids.each do |id|
            record = clz[id]
            json = clz.to_jsonmodel(record)
            record.update_from_json(json, {:skip_reindex_top_containers => true})

            Log.info("Updated #{clz} #{record.id}")
          end

        end

      end

    end

  end

end
