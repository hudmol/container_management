require 'factory_girl'

FactoryGirl.define do

  factory :json_yale_container, class: JSONModel(:yale_container) do
    type { sample(JSONModel(:yale_container).schema['properties']['type']) }
    indicator { generate(:alphanumstr) }
    barcode { generate(:alphanumstr) }
    voyager_id { generate(:alphanumstr) }
    restricted { false }
    exported_to_voyager { true }
  end

  factory :json_container_profile, class: JSONModel(:container_profile) do
    name { generate(:alphanumstr) }
    url { generate(:alphanumstr) }
    dimension_units { sample(JSONModel(:container_profile).schema['properties']['dimension_units']) }
    extent_dimension { sample(JSONModel(:container_profile).schema['properties']['extent_dimension']) }
    depth { rand(100).to_s }
    height { rand(100).to_s }
    width { rand(100).to_s }
  end

end
