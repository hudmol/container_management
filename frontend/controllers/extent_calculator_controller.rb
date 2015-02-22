require 'uri'

class ExtentCalculatorController < ApplicationController

  set_access_control  "view_repository" => [:index]

  def index
    if params['record_uri']
      @results = JSONModel::HTTP::get_json("/extent_calculator", {'record_uri' => params['record_uri']})
    else
      @results = "no object"
    end
  end

end

