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

    box.level.should eq(1)
    folder.level.should eq(2)
    reel.level.should eq(3)
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


  it "supports all kinds of wonderful metadata" do
    barcode = '12345678'
    voyager_id = '112358'
    exported_to_voyager = true
    restricted = false

    yale_box_container = build(:json_yale_container,
                               'barcode' => barcode,
                               'voyager_id' => voyager_id,
                               'exported_to_voyager' => exported_to_voyager,
                               'restricted' => restricted)

    box_id = YaleContainer.create_from_json(yale_box_container, :repo_id => $repo_id).id

    box = YaleContainer.to_jsonmodel(box_id)
    box.barcode.should eq(barcode)
    box.voyager_id.should eq(voyager_id)
    box.exported_to_voyager.should eq(exported_to_voyager)
    box.restricted.should eq(restricted)
  end


  it "can be linked to a location" do
    test_location = create(:json_location)

    container_location = JSONModel(:container_location).from_hash(
      'status' => 'current',
      'start_date' => '2000-01-01',
      'note' => 'test container location',
      'ref' => test_location.uri
    )

    container_with_location = create(:json_yale_container,
                                     'container_locations' => [container_location])

    json = YaleContainer.to_jsonmodel(container_with_location.id)
    json['container_locations'][0]['ref'].should eq(test_location.uri)
  end


  it "blows up if you don't provide a barcode for a top-level element" do
    expect {
      create(:json_yale_container, :barcode => nil)
    }.to raise_error(ValidationException)
  end


  it "lets you create a child container without a barcode" do
    # Box
    yale_box_container = build(:json_yale_container, {})
    box_id = YaleContainer.create_from_json(yale_box_container, :repo_id => $repo_id).id
    box_uri = JSONModel(:yale_container).uri_for(box_id)

    # Folder
    yale_folder_container = build(:json_yale_container, {"parent" => {"ref" => box_uri},
                                                         "barcode" => nil})

    expect {
      YaleContainer.create_from_json(yale_folder_container, :repo_id => $repo_id)
    }.to_not raise_error
  end


  it "enforces barcode uniqueness within a repository" do
      create(:json_yale_container, :barcode => "1234")

      expect {
        create(:json_yale_container, :barcode => "1234")
      }.to raise_error(ValidationException)
  end


  it "displays barcodes in the display string" do
    obj = create(:json_yale_container, :type => "box", :indicator => "1", :barcode => "1234")

    YaleContainer.to_jsonmodel(obj.id).display_string.should eq("Box 1 [1234]")
  end

  it "validates hierarchies correctly" do
    hierarchy = JSONModel(:yale_container_hierarchy).from_hash(
      :yale_container_1 => build(:json_yale_container, :barcode => nil),
    )

    begin
      YaleContainer.from_hierarchy(hierarchy)
    rescue Sequel::ValidationFailed => e
      e.errors.keys.first.should eq("yale_container_1/barcode")
    end
  end

end
