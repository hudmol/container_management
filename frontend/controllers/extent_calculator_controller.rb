require 'uri'

class ExtentCalculatorController < ApplicationController

  set_access_control  "view_repository" => [:index]

  def index
    if params['record_uri']
      @results = JSONModel::HTTP::get_json("/extent_calculator", {'record_uri' => params['record_uri']})
    else
      record_uri = nil
      ref = request.referer
      if ref.match /archival_object_(\d+)/
        record_uri = "#{session[:repo]}/archival_objects/#{$1}"
      elsif ref.match /\/([^\/]+\/\d+)/
        record_uri = "#{session[:repo]}/#{$1}"
      else
      end
      if record_uri
        @results = JSONModel::HTTP::get_json("/extent_calculator", {'record_uri' => record_uri})
      else
        @results = "no object"
      end
    end

  end

end

