require 'factory_girl'

FactoryGirl.define do

  factory :json_top_container, class: JSONModel(:top_container) do
    type { sample(JSONModel(:top_container).schema['properties']['type']) }
    indicator { generate(:alphanumstr) }
    barcode { generate(:alphanumstr) }
    voyager_id { generate(:alphanumstr) }
    restricted { false }
    exported_to_voyager { true }
  end


  factory :json_sub_container, class: JSONModel(:sub_container) do
    type_2 { sample(JSONModel(:sub_container).schema['properties']['type_2']) }
    indicator_2 { generate(:alphanumstr) }
    type_3 { sample(JSONModel(:sub_container).schema['properties']['type_3']) }
    indicator_3 { generate(:alphanumstr) }
  end

end
