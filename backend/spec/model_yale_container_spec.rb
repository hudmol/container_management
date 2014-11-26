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


  it "supports creating a two level container" do
    yale_parent_container = build(:json_yale_container, {})
    parent_id = YaleContainer.create_from_json(yale_parent_container, :repo_id => $repo_id).id
    parent_uri = JSONModel(:yale_container).uri_for(parent_id)

    yale_child_container = build(:json_yale_container, {
      "parent" => {
        "ref" => parent_uri
      }
    })

    child_id = YaleContainer.create_from_json(yale_child_container, :repo_id => $repo_id).id

    child = YaleContainer.to_jsonmodel(child_id)

    child.parent["ref"].should eq(parent_uri)
  end

end
