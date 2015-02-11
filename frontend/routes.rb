ArchivesSpace::Application.routes.draw do
  match('/plugins/top_containers/search/typeahead' => 'top_containers#typeahead', :via => [:get])
  match('/plugins/top_containers/bulk_operations/search' => 'top_containers#bulk_operations', :via => [:get])
  match('/plugins/top_containers/bulk_operations/search' => 'top_containers#bulk_operation_search', :via => [:post])
  match('/plugins/top_containers/bulk_operations/browse' => 'top_containers#bulk_operations_browse', :via => [:get])
  match('/plugins/top_containers/bulk_operations/update' => 'top_containers#bulk_operation_update', :via => [:post])
  match('/plugins/top_containers/batch_delete' => 'top_containers#batch_delete', :via => [:post])
  match('/plugins/top_containers/:id' => 'top_containers#update', :via => [:post])
  match('/plugins/top_containers/:id/delete' => 'top_containers#delete', :via => [:post])

  match('/plugins/container_profiles/bulk_operations/update_barcodes' => 'top_containers#update_barcodes', :via => [:post])

  match('/plugins/container_profiles/:id' => 'container_profiles#update', :via => [:post])
  match('/plugins/container_profiles/:id/delete' => 'container_profiles#delete', :via => [:post])
end
