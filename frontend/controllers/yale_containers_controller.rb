class YaleContainersController < ApplicationController

  set_access_control  "view_repository" => [:index],
                      "manage_yale_container" => [:new, :create, :batch_delete]


  def index
    @search_data = Search.for_type(session[:repo_id], "yale_container", params_for_backend_search)
  end


  def new
    @yale_container_hierarchy = JSONModel(:yale_container_hierarchy).new._always_valid!
    @yale_container_hierarchy["yale_container_1"] = JSONModel(:yale_container).new._always_valid!
    @yale_container_hierarchy["yale_container_2"] = JSONModel(:yale_container).new._always_valid!
    @yale_container_hierarchy["yale_container_2"] = JSONModel(:yale_container).new._always_valid!
  end


  def create
    begin
      values = cleanup_params_for_schema(params["yale_container_hierarchy"], JSONModel(:yale_container_hierarchy).schema)

      @yale_container_hierarchy = JSONModel(:yale_container_hierarchy).from_hash(values, false)

      if @yale_container_hierarchy._exceptions.blank?
        # save it
      else
        @exceptions = @yale_container_hierarchy._exceptions
        render :action => :new
      end
    end
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

