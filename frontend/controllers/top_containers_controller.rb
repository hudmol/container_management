class TopContainersController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :typeahead],
                      "manage_container" => [:new, :create, :edit, :update, :batch_delete, :bulk_operations, :bulk_operation_search]


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
    @top_container = JSONModel(:top_container).find(params[:id], find_opts)
  end


  def update
    handle_crud(:instance => :top_container,
                :model => JSONModel(:top_container),
                :obj => JSONModel(:top_container).find(params[:id], find_opts),
                :on_invalid => ->(){
                  return render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("top_container._frontend.messages.updated")
                  redirect_to :controller => :top_containers, :action => :show, :id => id
                })
  end


  def delete
  end

  def batch_delete
  end


  def typeahead
    search_params = params_for_backend_search

    series_uri = series_for_uri(params['uri'])
    if (series_uri)
      search_params = search_params.merge({
                                            "filter_term[]" => [{"series_uri_u_sstr" => series_uri}.to_json]
                                          })
    end

    render :json => Search.all(session[:repo_id], search_params)
  end


  def bulk_operations

  end


  def bulk_operation_search
    search_params = params_for_backend_search.merge({
                                                      'type[]' => ['top_container'],
                                                    })

    filters = []
    filters.push({'series_uri_u_sstr' => params['series']['ref']}.to_json) if params['series']


    if (!filters.empty?)
      search_params = search_params.merge({
                                            "filter_term[]" => filters
                                          })
    end

    @search_data = Search.all(session[:repo_id], search_params)

    render :action => :bulk_operations
  end


  private

  helper_method :can_edit_search_result?
  def can_edit_search_result?(record)
    return user_can?('manage_container') if record['primary_type'] === "top_container"
    SearchHelper.can_edit_search_result?(record)
  end

  def series_for_uri(uri)
    return if uri.blank?

    parsed = JSONModel.parse_reference(uri)
    if parsed[:type] == :archival_object
      return JSONModel(:archival_object).find(parsed[:id]).series['ref']
    end

    uri
  end

end

