require 'spec_helper'
require_relative 'factories'

describe 'Yale Container model' do

  it "supports creating a top-level container" do
    yale_container = build(:json_yale_container, {})

    created_id = YaleContainer.create_from_json(yale_container, :repo_id => $repo_id).id

    fetched = YaleContainer.to_jsonmodel(created_id)

    fetched.type.should eq(yale_container.type)
    fetched.indicator.should eq(yale_container.indicator)
  end

end
