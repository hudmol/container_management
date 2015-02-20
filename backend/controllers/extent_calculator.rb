class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/extent_calculator')
  .description("Calculate the extent of an archival object tree")
  .params(["record_uri", String, "The uri of the object"])
  .permissions([])
  .returns([200, "Calculation results"]) \
  do
    parsed = JSONModel.parse_reference(params[:record_uri])
    RequestContext.open(:repo_id => JSONModel(:repository).id_for(parsed[:repository])) do
      obj = Kernel.const_get(parsed[:type].to_s.camelize)[parsed[:id]]
      json_response(ExtentCalculator.new(obj).to_hash)
    end
  end

end
