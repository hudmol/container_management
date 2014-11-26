class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/yale_containers/:id')
    .description("Update a yale container")
    .params(["id", :id],
            ["yale_container", JSONModel(:yale_container), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:manage_yale_container])
    .returns([200, :updated]) \
  do
    handle_update(YaleContainer, params[:id], params[:yale_container])
  end


  Endpoint.post('/repositories/:repo_id/yale_containers')
    .description("Create a yale container")
    .params(["yale_container", JSONModel(:yale_container), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:manage_yale_container])
    .returns([200, :created]) \
  do
    handle_create(YaleContainer, params[:yale_container])
  end


  Endpoint.get('/repositories/:repo_id/yale_containers')
    .description("Get a list of YaleContainers for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:yale_container)]"]) \
  do
    handle_listing(YaleContainer, params)
  end


  Endpoint.get('/repositories/:repo_id/yale_containers/:id')
    .description("Get a yale container by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:yale_container)"]) \
  do
    json = YaleContainer.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.delete('/repositories/:repo_id/yale_containers/:id')
    .description("Delete a yale container")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:manage_yale_container])
    .returns([200, :deleted]) \
  do
    handle_delete(YaleContainer, params[:id])
  end

end
