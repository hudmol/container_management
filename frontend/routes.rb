ArchivesSpace::Application.routes.draw do

  match('/plugins/top_containers/batch_delete' => 'top_containers#batch_delete', :via => [:post])

end
