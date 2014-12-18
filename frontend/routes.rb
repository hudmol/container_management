ArchivesSpace::Application.routes.draw do

  match('/plugins/top_containers/batch_delete' => 'top_containers#batch_delete', :via => [:post])
  match('/plugins/top_containers/:id' => 'top_containers#update', :via => [:post])

  match('/plugins/container_profiles/:id' => 'container_profiles#update', :via => [:post])
  match('/plugins/container_profiles/:id/delete' => 'container_profiles#delete', :via => [:post])


end
