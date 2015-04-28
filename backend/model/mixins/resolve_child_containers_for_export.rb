module ResolveChildContainersForExport

  def self.included(base)
    base.class_eval do
      child_class = base.instance_variable_get(:@ao)
      child_class.class_eval do
        def initialize(tree, repo_id)
          @repo_id = repo_id
          # @tree = tree
          @children = tree ? tree['children'] : []
          @child_class = self.class
          @json = nil
          RequestContext.open(:repo_id => repo_id) do
            rec = URIResolver.resolve_references(ArchivalObject.to_jsonmodel(tree['id']), ['subjects', 'linked_agents', 'digital_object', 'top_container::container_profile'], {'ASPACE_REENTRANT' => false})
            @json = JSONModel::JSONModel(:archival_object).new(rec)
          end
        end
      end
    end
  end

end