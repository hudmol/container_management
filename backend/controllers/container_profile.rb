class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/container_profiles/:id')
    .description("Update a Container Profile")
    .params(["id", :id],
            ["container_profile", JSONModel(:container_profile), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:manage_container_profile_record])
    .returns([200, :updated]) \
  do
    handle_update(ContainerProfile, params[:id], params[:container_profile])
  end


  Endpoint.post('/repositories/:repo_id/container_profiles')
    .description("Create a Container_Profile")
    .params(["container_profile", JSONModel(:container_profile), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:manage_container_profile_record])
    .returns([200, :created]) \
  do
    handle_create(ContainerProfile, params[:container_profile])
  end


  Endpoint.get('/repositories/:repo_id/container_profiles')
    .description("Get a list of Container Profiles for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:container_profile)]"]) \
  do
    handle_listing(ContainerProfile, params)
  end


  Endpoint.get('/repositories/:repo_id/container_profiles/:id')
    .description("Get a Container Profile by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:container_profile)"]) \
  do
    json = ContainerProfile.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.delete('/repositories/:repo_id/container_profiles/:id')
    .description("Delete an Container Profile")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_archival_record])
    .returns([200, :deleted]) \
  do
    handle_delete(ContainerProfile, params[:id])
  end

end
