class YaleContainersController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "manage_yale_container" => [:new, :create, :batch_delete]


  def index
    @search_data = Search.for_type(session[:repo_id], "yale_container", params_for_backend_search)
  end


  def new
    @yale_container = JSONModel(:yale_container).new._always_valid!

    render_aspace_partial :partial => "yale_containers/new" if inline?
  end


  def create
    begin
      values = cleanup_params_for_schema(params["yale_container_hierarchy"], JSONModel(:yale_container_hierarchy).schema)

      if values["yale_container_3"].values.all?(&:blank?)
        values.delete("yale_container_3")

        values.delete("yale_container_2") if values["yale_container_2"].values.all?(&:blank?)
      end

      @yale_container_hierarchy = JSONModel(:yale_container_hierarchy).from_hash(values, false)

      if @yale_container_hierarchy._exceptions.blank?
        begin
          result = @yale_container_hierarchy.save({}, true)

          if result["uris"].length > 0
            yale_container_uri = result["uris"].last
          else
            # if we didn't create a container then we just take the third container
            yale_container_uri = @yale_container_hierarchy["yale_container_3"]
          end

          yale_container_id = JSONModel(:yale_container).id_for(yale_container_uri)

          if inline?
            render :json => JSONModel(:yale_container).find(yale_container_id)
          else
            redirect_to(:controller => :yale_containers, :action => :show, :id => yale_container_id)
          end
        rescue JSONModel::ValidationException => ex
          handle_error
        end
      else
        handle_error
      end
    end
  end


  def show
    @yale_container = JSONModel(:yale_container).find(params[:id], find_opts)
  end


  def edit
  end


  def update
  end


  def delete
  end

  def batch_delete
  end


  private

  def handle_error
    @exceptions = @yale_container_hierarchy._exceptions

    @yale_container_hierarchy["ref"] = params["yale_container_hierarchy"]["ref"]

    if params["yale_container_hierarchy"] && params["yale_container_hierarchy"]["_resolved"]
      @yale_container_hierarchy["_resolved"] = ASUtils.json_parse(params["yale_container_hierarchy"]["_resolved"])
    end

    if inline?
      render_aspace_partial :partial => "yale_containers/new"
    else
      render :action => :new
    end
  end

end

