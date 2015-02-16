require 'spec_helper'
require_relative 'factories'


def create_tree(top_container_json, opts = {})
  resource = create_resource
  grandparent = create(:json_archival_object, {:resource => {"ref" => resource.uri}}.merge(opts.fetch(:grandparent_properties, {})))
  parent = create(:json_archival_object, "resource" => {"ref" => resource.uri}, "parent" => {"ref" => grandparent.uri})
  child = create(:json_archival_object,
                 "resource" => {"ref" => resource.uri},
                 "parent" => {"ref" => parent.uri},
                 "instances" => [build_instance(top_container_json)])

  [resource, grandparent, parent, child]
end




def build_instance(top_container_json)
  build(:json_instance, {
          "instance_type" => "text",
          "sub_container" => build(:json_sub_container, {
                                     "top_container" => {
                                       "ref" => top_container_json.uri
                                     }
                                   })
        })
end


describe 'Yale Container model' do

  it "supports all kinds of wonderful metadata" do
    barcode = '12345678'
    ils_holding_id = '112358'
    ils_item_id = '853211'
    exported_to_ils = Time.at(1234567890).iso8601
    restricted = false

    yale_box_container = build(:json_top_container,
                               'barcode' => barcode,
                               'ils_holding_id' => ils_holding_id,
                               'ils_item_id' => ils_item_id,
                               'exported_to_ils' => exported_to_ils,
                               'restricted' => restricted)

    box_id = TopContainer.create_from_json(yale_box_container, :repo_id => $repo_id).id

    box = TopContainer.to_jsonmodel(box_id)
    box.barcode.should eq(barcode)
    box.ils_holding_id.should eq(ils_holding_id)
    box.ils_item_id.should eq(ils_item_id)
    box.exported_to_ils.should eq(exported_to_ils)
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


  it "doesn't blow up if you don't provide a barcode for a top-level element" do
    expect {
      create(:json_top_container, :barcode => nil)
    }.to_not raise_error(ValidationException)
  end


  it "enforces barcode uniqueness within a repository" do
    create(:json_top_container, :barcode => "1234")

    expect {
      create(:json_top_container, :barcode => "1234")
    }.to raise_error(ValidationException)
  end


  it "enforces barcode length according to config" do

    AppConfig.stub(:[]).and_call_original
    AppConfig.stub(:has_key?).and_call_original

    AppConfig.stub(:has_key?).with(:yale_containers_barcode_length).and_return(true)
    AppConfig.stub(:[]).with(:yale_containers_barcode_length).and_return({:system_default => {:min => 4, :max => 6}})

    expect {
      create(:json_top_container, :barcode => "1234")
    }.to_not raise_error(ValidationException)

    expect {
      create(:json_top_container, :barcode => "123")
    }.to raise_error(ValidationException)

    expect {
      create(:json_top_container, :barcode => "1234567")
    }.to raise_error(ValidationException)

  end


  it "can be linked to a container profile" do
    test_container_profile = create(:json_container_profile)

    container_with_profile = create(:json_top_container,
                                    'container_profile' => {'ref' => test_container_profile.uri})

    json = TopContainer.to_jsonmodel(container_with_profile.id)
    json['container_profile']['ref'].should eq(test_container_profile.uri)
  end


  it "deletes all related subcontainers and instances when deleted" do
    box1 = create(:json_top_container)
    box2 = create(:json_top_container)

    acc1 = create_accession({
                              "instances" => [build_instance(box1), build_instance(box1), build_instance(box2)]
                            })

    acc2 = create_accession({
                              "instances" => [build_instance(box1), build_instance(box2), build_instance(box2)]
                            })

    TopContainer[box1.id].delete

    acc1 = Accession[acc1.id]
    acc2 = Accession[acc2.id]
    acc1.instance.length.should eq(1)
    acc2.instance.length.should eq(2)
  end


  describe "display strings" do

    let (:box) { create(:json_top_container, :indicator => "1", :barcode => "123") }
    let (:top_container) { TopContainer[box.id] }

    it "can show a display string for a top container that isn't linked to anything" do
      top_container.display_string.should eq("Container 1: [123]")
    end


    it "can find an accession linked to a given top container" do
      accession = create_accession({"instances" => [build_instance(box)]})

      collection = top_container.collections.first
      collection.should be_instance_of(Accession)
      collection.id.should eq(accession.id)

      top_container.series.should be_empty
    end


    it "can find a resource linked to a given top container" do
      resource = create_resource({"instances" => [build_instance(box)]})

      collection = top_container.collections.first
      collection.should be_instance_of(Resource)
      collection.id.should eq(resource.id)

      top_container.series.should be_empty
    end


    describe "archival object tree" do

      it "can find the topmost archival object linked to a given top container" do
        (resource, grandparent, parent, child) = create_tree(box)

        series = top_container.series.first
        series.should be_instance_of(ArchivalObject)
        series.id.should eq(grandparent.id)
      end

      it "includes the series in its JSON output" do
        (resource, grandparent, parent, child) = create_tree(box,
                                                             :grandparent_properties => {
                                                              'component_id' => 'GP1',
                                                              'level' => 'series'
                                                             })

        json = TopContainer.to_jsonmodel(top_container.id)
        json.series.first.should eq({
          'ref' => grandparent.uri,
          'identifier' => grandparent.component_id,
          'display_string' => grandparent.display_string,
          'level_display_string' => 'Series'
        })
      end

      it "can get the collection linked to a given top container" do
        (resource, grandparent, parent, child) = create_tree(box)

        collection = top_container.collections.first
        collection.should be_instance_of(Resource)
        collection.id.should eq(resource.id)
      end

    end


    it "shows a display string for a linked series-level AO" do
      (resource, grandparent, parent, child) = create_tree(box,
                                                           :grandparent_properties => {
                                                             'level' => "series",
                                                             'component_id' => "3",
                                                           })

      top_container.display_string.should eq("Container 1: Series 3 [123]")
    end

    it "shows a display string for a linked other-level AO" do
      (resource, grandparent, parent, child) = create_tree(box,
                                                           :grandparent_properties => {
                                                             'component_id' => "9",
                                                             'level' => 'otherlevel',
                                                             'other_level' => 'Handbag'
                                                           })

      top_container.display_string.should eq("Container 1: Handbag 9 [123]")
    end

    it "shows a display string for a linked accession" do
      accession = create_accession({"instances" => [build_instance(box)]})

      top_container.display_string.should eq("Container 1: [123]")
    end


    it "shows a display string for a linked resource" do
      resource = create_resource({"instances" => [build_instance(box)]})

      top_container.display_string.should eq("Container 1: [123]")
    end

  end


  describe "indexing" do

    let (:container_profile_json) {
      create(:json_container_profile, :name => "Cardboard box")
    }

    let (:container_profile) { ContainerProfile[container_profile_json.id] }

    let (:top_container_json) {
      create(:json_top_container,
             'container_profile' => {'ref' => container_profile_json.uri})
    }

    let (:top_container) { TopContainer[top_container_json.id] }

    it "reindexes top containers when the container profile is updated" do
      original_mtime = top_container.refresh.system_mtime

      json = ContainerProfile.to_jsonmodel(container_profile)
      json.name = "Metal box"
      container_profile.update_from_json(json)

      top_container.refresh
      top_container.system_mtime.should be > original_mtime
    end


    it "reindexes top containers when a linked accession is updated" do
      accession = create_accession({"instances" => [build_instance(top_container_json)]})

      original_mtime = top_container.refresh.system_mtime

      json = Accession.to_jsonmodel(accession.id)
      json.title = "New accession title"
      accession.update_from_json(json)

      top_container.refresh.system_mtime.should be > original_mtime
    end


    it "reindexes top containers when an archival object is updated" do
      (resource, grandparent, parent, child) = create_tree(top_container_json)

      original_mtime = top_container.refresh.system_mtime

      json = ArchivalObject.to_jsonmodel(grandparent.id)
      json.title = "A better title"
      ArchivalObject[grandparent.id].update_from_json(json)

      top_container.refresh.system_mtime.should be > original_mtime
    end


    it "reindexes top containers when a tree is rearranged" do
      (resource, grandparent, parent, child) = create_tree(top_container_json)

      original_mtime = top_container.refresh.system_mtime

      ArchivalObject[child.id].update_position_only(grandparent.id, 1)

      top_container.refresh.system_mtime.should be > original_mtime
    end


    it "refreshes top containers when an archival object is deleted" do
      (resource, grandparent, parent, child) = create_tree(top_container_json)

      original_mtime = top_container.refresh.system_mtime
      ArchivalObject[child.id].delete
      top_container.refresh.system_mtime.should be > original_mtime
    end


    it "refreshes top containers (linked to each tree) when two resources are merged" do
      container1_json = create(:json_top_container)
      container1 = TopContainer[container1_json.id]

      container2_json = create(:json_top_container)
      container2 = TopContainer[container2_json.id]

      (resource1, grandparent1, parent1, child1) = create_tree(container1_json)
      (resource2, grandparent2, parent2, child2) = create_tree(container2_json)

      container1_original_mtime = container1.refresh.system_mtime
      container2_original_mtime = container2.refresh.system_mtime

      resource1.assimilate([resource2])

      container1.refresh.system_mtime.should be > container1_original_mtime
      container2.refresh.system_mtime.should be > container2_original_mtime
    end


    it "refreshes top containers when archival objects are transferred between resources (both trees)" do
      container1_json = create(:json_top_container)
      container1 = TopContainer[container1_json.id]

      container2_json = create(:json_top_container)
      container2 = TopContainer[container2_json.id]

      (resource1, grandparent1, parent1, child1) = create_tree(container1_json)
      (resource2, grandparent2, parent2, child2) = create_tree(container2_json)

      container1_original_mtime = container1.refresh.system_mtime
      container2_original_mtime = container2.refresh.system_mtime

      ComponentTransfer.transfer(resource2.uri, parent1.uri)

      container1.refresh.system_mtime.should be > container1_original_mtime
      container2.refresh.system_mtime.should be > container2_original_mtime
    end

  end

  describe "bulk action" do
    it "can set multiple valid barcodes" do
      container1_json = create(:json_top_container)
      container2_json = create(:json_top_container)

      barcode_data = {}
      barcode_data[container1_json.uri] = "987654321"
      barcode_data[container2_json.uri] = "876543210"

      results = TopContainer.bulk_update_barcodes(barcode_data)
      results.should include(container1_json.id, container2_json.id)

      TopContainer[container1_json.id].barcode.should eq("987654321")
      TopContainer[container2_json.id].barcode.should eq("876543210")
    end

    it "throws exception when attempt to update to an invalid barcode" do
      orig_barcode_config = AppConfig[:yale_containers_barcode_length]
      AppConfig[:yale_containers_barcode_length] = {
        :system_default => {:min => 4, :max => 6}
      }

      container1_json = create(:json_top_container)
      container2_json = create(:json_top_container)

      original_barcode_1 = TopContainer[container1_json.id].barcode
      original_barcode_2 = TopContainer[container2_json.id].barcode

      barcode_data = {}
      barcode_data[container1_json.uri] = "7777777"
      barcode_data[container2_json.uri] = "333"

      expect {
        TopContainer.bulk_update_barcodes(barcode_data)
      }.to raise_error(Sequel::ValidationFailed)

      AppConfig[:yale_containers_barcode_length] = orig_barcode_config
    end

    it "throws exception when attempt to set duplicate barcode" do
      container1_json = create(:json_top_container)
      container2_json = create(:json_top_container)

      barcode_data = {}
      barcode_data[container1_json.uri] = "7777777"
      barcode_data[container2_json.uri] = "7777777"

      expect {
        TopContainer.bulk_update_barcodes(barcode_data)
      }.to raise_error(Sequel::ValidationFailed)

    end

    it "avoids a duplicate barcode exception when switching barcodes" do
      container1_json = create(:json_top_container, {:barcode => "11111111"})
      container2_json = create(:json_top_container, {:barcode => "22222222"})

      barcode_data = {}
      barcode_data[container1_json.uri] = "22222222"
      barcode_data[container2_json.uri] = "11111111"

      expect {
        TopContainer.bulk_update_barcodes(barcode_data)
      }.to_not raise_error(Sequel::DatabaseError)

      TopContainer[container1_json.id].barcode.should eq("22222222")
      TopContainer[container2_json.id].barcode.should eq("11111111")
    end
  end

end
