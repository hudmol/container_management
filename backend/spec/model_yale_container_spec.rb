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


  it "can create a container from a hierarchy" do
    hierarchy = JSONModel(:yale_container_hierarchy).from_hash(
      :yale_container_1 => build(:json_yale_container),
      :yale_container_2 => build(:json_yale_container),
      :yale_container_3 => build(:json_yale_container)
    )

    created = YaleContainer.from_hierarchy(hierarchy)

    created.length.should eq(3)

    created.map(&:class).uniq.should eq([YaleContainer])
  end


  it "can reuse existing Yale Containers as required (create only the missing ones)" do
    yale_box_container = build(:json_yale_container, {})
    box = YaleContainer.create_from_json(yale_box_container, :repo_id => $repo_id)


    hierarchy = JSONModel(:yale_container_hierarchy).from_hash(
      :yale_container_1 => box.uri,
      :yale_container_2 => build(:json_yale_container),
      :yale_container_3 => build(:json_yale_container)
    )

    created = YaleContainer.from_hierarchy(hierarchy)

    created.length.should eq(2)
    created[0].parent_id.should eq(box.id)
  end


  it "can deal with creating under three containers" do
    yale_box_container = build(:json_yale_container, {})
    box = YaleContainer.create_from_json(yale_box_container, :repo_id => $repo_id)


    hierarchy = JSONModel(:yale_container_hierarchy).from_hash(
      :yale_container_1 => box.uri,
      :yale_container_2 => build(:json_yale_container),
    )

    created = YaleContainer.from_hierarchy(hierarchy)

    created.length.should eq(1)
  end


end
