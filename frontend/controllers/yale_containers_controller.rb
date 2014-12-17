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
    handle_crud(:instance => :yale_container,
                :model => JSONModel(:yale_container),
                :find_opts => find_opts,
                :on_invalid => ->(){
                  return render_aspace_partial :partial => "yale_containers/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  @yale_container.refetch

                  if inline?
                    render :json => @yale_container.to_hash if inline?
                  else
                    flash[:success] = I18n.t("yale_container._frontend.messages.created")
                    redirect_to :controller => :yale_containers, :action => :edit, :id => id
                  end
                })
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

