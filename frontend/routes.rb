ArchivesSpace::Application.routes.draw do

  match('/plugins/yale_containers/batch_delete' => 'yale_containers#batch_delete', :via => [:post])

end
