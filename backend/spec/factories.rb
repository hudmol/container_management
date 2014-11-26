require 'factory_girl'

FactoryGirl.define do

  factory :json_yale_container, class: JSONModel(:yale_container) do
    type { sample(JSONModel(:yale_container).schema['properties']['type']) }
    indicator { generate(:alphanumstr) }
  end

end
