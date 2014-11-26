class YaleContainersController < ApplicationController

  set_access_control  "view_repository" => [:index],
                      "manage_yale_container" => [:new]


  def index
    @search_data = Search.for_type(session[:repo_id], "yale_container", params_for_backend_search)
  end


  def new
  end

end

