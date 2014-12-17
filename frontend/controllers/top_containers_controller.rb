class TopContainersController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "manage_container" => [:new, :create, :batch_delete]


  def index
    @search_data = Search.for_type(session[:repo_id], "top_container", params_for_backend_search)
  end


  def new
    @top_container = JSONModel(:top_container).new._always_valid!

    render_aspace_partial :partial => "top_containers/new" if inline?
  end


  def create
    handle_crud(:instance => :top_container,
                :model => JSONModel(:top_container),
                :on_invalid => ->(){
                  return render_aspace_partial :partial => "top_containers/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  if inline?
                    @top_container.refetch
                    render :json => @top_container.to_hash if inline?
                  else
                    flash[:success] = I18n.t("top_container._frontend.messages.created")
                    redirect_to :controller => :top_containers, :action => :show, :id => id
                  end
                })
  end


  def show
    @top_container = JSONModel(:top_container).find(params[:id], find_opts)
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

