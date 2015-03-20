require 'uri'

class ExtentCalculatorController < ApplicationController

  set_access_control  "view_repository" => [:index]

  def index
    if params['record_uri']
      results = JSONModel::HTTP::get_json("/extent_calculator", {'record_uri' => params['record_uri']})

      extent = if params['referrer'] && params['referrer'].match('/edit(\#.*)?\Z')
                 extent = JSONModel(:extent).new
                 extent.number = results['total_extent']
                 units = results['volume'] ? 'cubic_' : 'linear_'
                 units += results['units']
                 extent.extent_type = units
                 container_cardinality = results['container_count'] == 1 ? 'container' : 'containers'
                 extent.container_summary = "(#{results['container_count']} #{container_cardinality})"
                 extent
               end

      render_aspace_partial :partial => "extent_calculator/show_calculation", :locals => {:results => results, :extent => extent}
    else
      render_aspace_partial :partial => "extent_calculator/no_object"
    end

  end

end

