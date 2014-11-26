require 'spec_helper'
require_relative 'factories'

describe 'Yale Container model' do

  it "supports creating a three level container" do
    # Box
    yale_box_container = build(:json_yale_container, {})
    box_id = YaleContainer.create_from_json(yale_box_container, :repo_id => $repo_id).id
    box_uri = JSONModel(:yale_container).uri_for(box_id)

    # Folder
    yale_folder_container = build(:json_yale_container, {"parent" => {"ref" => box_uri}})
    folder_id = YaleContainer.create_from_json(yale_folder_container, :repo_id => $repo_id).id
    folder_uri = JSONModel(:yale_container).uri_for(folder_id)

    # Reel
    yale_reel_container = build(:json_yale_container, {"parent" => {"ref" => folder_uri}})
    reel_id = YaleContainer.create_from_json(yale_reel_container, :repo_id => $repo_id).id

    box = YaleContainer.to_jsonmodel(box_id)
    folder = YaleContainer.to_jsonmodel(folder_id)
    reel = YaleContainer.to_jsonmodel(reel_id)

    folder.parent["ref"].should eq(box.uri)
    reel.parent["ref"].should eq(folder.uri)
  end


end
