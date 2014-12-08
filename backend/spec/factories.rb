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

end
