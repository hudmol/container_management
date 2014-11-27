class YaleContainersController < ApplicationController

  set_access_control  "view_repository" => [:index],
                      "manage_yale_container" => [:new, :batch_delete]


  def index
    @search_data = Search.for_type(session[:repo_id], "yale_container", params_for_backend_search)
  end


  def new
    @yale_container = JSONModel(:yale_container).new._always_valid!
  end


  def create
  end


  def edit
  end


  def update
  end


  def delete
  end

  def batch_delete
  end

end

