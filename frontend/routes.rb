ArchivesSpace::Application.routes.draw do

  match('/plugins/yale_containers/batch_delete' => 'yale_containers#batch_delete', :via => [:post])

  match('/plugins/container_profiles/:id' => 'container_profiles#update', :via => [:post])
  match('/plugins/container_profiles/:id/delete' => 'container_profiles#delete', :via => [:post])

end
