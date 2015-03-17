require 'uri'

class ExtentCalculatorController < ApplicationController

  set_access_control  "view_repository" => [:index]

  def index
    if params['record_uri']
      results = JSONModel::HTTP::get_json("/extent_calculator", {'record_uri' => params['record_uri'], 'unit' => 'feet'})
      extent = JSONModel(:extent).new
      extent.number = results['total_extent']
      extent.extent_type = 'linear_feet'
      container_cardinality = results['container_count'] == 1 ? 'container' : 'containers'
      extent.container_summary = "(#{results['container_count']} #{container_cardinality})"
      render_aspace_partial :partial => "extent_calculator/show_calculation", :locals => {:results => results, :extent => extent}
    else
      results = "no object"
    end

  end

end

