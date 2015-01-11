require 'factory_girl'

FactoryGirl.define do

  factory :json_top_container, class: JSONModel(:top_container) do
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

  factory :json_sub_container, class: JSONModel(:sub_container) do
    type_2 { sample(JSONModel(:sub_container).schema['properties']['type_2']) }
    indicator_2 { generate(:alphanumstr) }
    type_3 { sample(JSONModel(:sub_container).schema['properties']['type_3']) }
    indicator_3 { generate(:alphanumstr) }
  end

end
