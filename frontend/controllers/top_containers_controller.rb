class TopContainersController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :typeahead],
                      "manage_container" => [:new, :create, :edit, :update, :batch_delete, :bulk_operations, :bulk_operation_search]


  def index
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
    raise "TODO"
  end

  def batch_delete
    raise "TODO"
  end


  def typeahead
    search_params = params_for_backend_search

    search_params = search_params.merge(search_filter_for(params[:uri]))

    render :json => Search.all(session[:repo_id], search_params)
  end


  def bulk_operation_search
    search_params = params_for_backend_search.merge({
                                                      'type[]' => ['top_container']
                                                    })

    filters = []
    filters.push({'series_uri_u_sstr' => params['series']['ref']}.to_json) if params['series']
    filters.push({'collection_uri_u_sstr' => params['collection']['ref']}.to_json) if params['collection']
    filters.push({'container_profile_uri_u_sstr' => params['container_profile']['ref']}.to_json) if params['container_profile']
    filters.push({'location_uri_u_sstr' => params['location']['ref']}.to_json) if params['location']

    if filters.empty? && params['q'].blank?
      return render :text => I18n.t("top_container._frontend.messages.filter_required"), :status => 500
    end

    unless filters.empty?
      search_params = search_params.merge({
                                            "filter_term[]" => filters
                                          })
    end

    container_search_url = "#{JSONModel(:top_container).uri_for("")}/search"
    results = JSONModel::HTTP::get_json(container_search_url, search_params)

    render_aspace_partial :partial => "top_containers/bulk_operations/results", :locals => {:results => results}
  end


  private

  helper_method :can_edit_search_result?
  def can_edit_search_result?(record)
    return user_can?('manage_container') if record['primary_type'] === "top_container"
    SearchHelper.can_edit_search_result?(record)
  end


  def search_filter_for(uri)
    return {} if uri.blank?

    parsed = JSONModel.parse_reference(uri)

    if parsed[:type] == "archival_object"
      series_uri = JSONModel(:archival_object).find(parsed[:id]).series['ref']
      return {
        "filter_term[]" => [{"series_uri_u_sstr" => series_uri}.to_json]
      }
    end

    return {
      "filter_term[]" => [{"collection_uri_u_sstr" => uri}.to_json]
    }
  end

end

