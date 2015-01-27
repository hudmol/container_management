class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/top_containers/search')
  .description("Delete a yale container")
  .params(["repo_id", :repo_id],
          *BASE_SEARCH_PARAMS)
  .permissions([:view_repository])
  .returns([200, "[(:top_container)]"]) \
  do

    [
      200,
      {'Content-Type' => 'application/json'},
      Enumerator.new do |y|
        TopContainer.search_stream(params.merge(:type => ['top_container']), params[:repo_id]) do |response|
          y << response.body
        end
      end
    ]

  end


  Endpoint.post('/repositories/:repo_id/top_containers/:id')
    .description("Update a yale container")
    .params(["id", :id],
            ["top_container", JSONModel(:top_container), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:manage_container])
    .returns([200, :updated]) \
  do
    handle_update(TopContainer, params[:id], params[:top_container])
  end


  Endpoint.post('/repositories/:repo_id/top_containers')
    .description("Create a yale container")
    .params(["top_container", JSONModel(:top_container), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:manage_container])
    .returns([200, :created]) \
  do
    handle_create(TopContainer, params[:top_container])
  end


  Endpoint.get('/repositories/:repo_id/top_containers')
    .description("Get a list of TopContainers for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:top_container)]"]) \
  do
    handle_listing(TopContainer, params)
  end


  Endpoint.get('/repositories/:repo_id/top_containers/:id')
    .description("Get a yale container by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:top_container)"]) \
  do
    json = TopContainer.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.delete('/repositories/:repo_id/top_containers/:id')
    .description("Delete a yale container")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:manage_container])
    .returns([200, :deleted]) \
  do
    handle_delete(TopContainer, params[:id])
  end


end
