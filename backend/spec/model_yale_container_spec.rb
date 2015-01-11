require 'spec_helper'
require_relative 'factories'

describe 'Yale Container model' do

  it "supports all kinds of wonderful metadata" do
    barcode = '12345678'
    voyager_id = '112358'
    exported_to_voyager = true
    restricted = false

    yale_box_container = build(:json_top_container,
                               'barcode' => barcode,
                               'voyager_id' => voyager_id,
                               'exported_to_voyager' => exported_to_voyager,
                               'restricted' => restricted)

    box_id = TopContainer.create_from_json(yale_box_container, :repo_id => $repo_id).id

    box = TopContainer.to_jsonmodel(box_id)
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

    container_with_location = create(:json_top_container,
                                     'container_locations' => [container_location])

    json = TopContainer.to_jsonmodel(container_with_location.id)
    json['container_locations'][0]['ref'].should eq(test_location.uri)
  end


  it "blows up if you don't provide a barcode for a top-level element" do
    expect {
      create(:json_top_container, :barcode => nil)
    }.to raise_error(ValidationException)
  end


  it "enforces barcode uniqueness within a repository" do
      create(:json_top_container, :barcode => "1234")

      expect {
        create(:json_top_container, :barcode => "1234")
      }.to raise_error(ValidationException)
  end


  it "displays barcodes in the display string" do
    obj = create(:json_top_container, :indicator => "1", :barcode => "1234")

    TopContainer.to_jsonmodel(obj.id).display_string.should eq("1 [1234]")
  end


  it "can be linked to a container profile" do
    test_container_profile = create(:json_container_profile)

    container_with_profile = create(:json_top_container,
                                    'container_profile' => {'ref' => test_container_profile.uri})

    json = TopContainer.to_jsonmodel(container_with_profile.id)
    json['container_profile']['ref'].should eq(test_container_profile.uri)
  end


  it "can't delete a TopContainer that has been linked to a sub container" do
    box = create(:json_top_container)

    accession = create_accession({
                         "instances" => [build(:json_instance, {
                           "instance_type" => "accession",
                           "sub_container" => build(:json_sub_container, {
                            "top_container" => {
                              "ref" => box.uri
                            }
                           })
                         })]
                       })

    expect { TopContainer[box.id].delete }.to raise_error(ConflictException)
  end

  it "can delete a TopContainer that has not been linked to a sub container" do
    box = create(:json_top_container)

    expect { TopContainer[box.id].delete }.to_not raise_error
  end

end
