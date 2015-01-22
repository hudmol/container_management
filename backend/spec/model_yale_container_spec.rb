require 'spec_helper'
require_relative 'factories'


def create_tree(top_container_json)
  resource = create_resource
  grandparent = create(:json_archival_object, :resource => {"ref" => resource.uri})
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
                                   "instances" => [build_instance(box)]
                                 })


    expect { TopContainer[box.id].delete }.to raise_error(ConflictException)
  end

  it "can delete a TopContainer that has not been linked to a sub container" do
    box = create(:json_top_container)

    expect { TopContainer[box.id].delete }.to_not raise_error
  end


  describe "display strings" do

    let (:box) { create(:json_top_container, :indicator => "1", :barcode => "123") }
    let (:top_container) { TopContainer[box.id] }

    it "can show a display string for a top container that isn't linked to anything" do
      top_container.display_string.should eq("1 [123]")
    end


    it "can find an accession linked to a given top container" do
      accession = create_accession({"instances" => [build_instance(box)]})

      collection = top_container.collection
      collection.should be_instance_of(Accession)
      collection.id.should eq(accession.id)

      top_container.series.should be_nil
    end


    it "returns the series in the JSON output of a top container" do
      accession = create_accession({"instances" => [build_instance(box)]})

      json = TopContainer.to_jsonmodel(top_container.id)
      json.series.should be_nil
      json.collection.should eq({'ref' => accession.uri, 'display_string' => accession.display_string})
    end


    it "can find a resource linked to a given top container" do
      resource = create_resource({"instances" => [build_instance(box)]})

      collection = top_container.collection
      collection.should be_instance_of(Resource)
      collection.id.should eq(resource.id)

      top_container.series.should be_nil
    end


    describe "archival object tree" do

      it "can find the topmost archival object linked to a given top container" do
        (resource, grandparent, parent, child) = create_tree(box)

        series = top_container.series
        series.should be_instance_of(ArchivalObject)
        series.id.should eq(grandparent.id)
      end

      it "includes the series in its JSON output" do
        (resource, grandparent, parent, child) = create_tree(box)

        json = TopContainer.to_jsonmodel(top_container.id)
        json.series.should eq({'ref' => grandparent.uri, 'display_string' => grandparent.display_string})
      end

      it "can incorporates the series display string into the top container's display string" do
        (resource, grandparent, parent, child) = create_tree(box)

        top_container.display_string.should eq("1 [123] : #{grandparent.display_string}")
      end

      it "can get the collection linked to a given top container" do
        (resource, grandparent, parent, child) = create_tree(box)

        collection = top_container.collection
        collection.should be_instance_of(Resource)
        collection.id.should eq(resource.id)
      end

    end
  end


  it "incorporates container profile names into display strings" do
    test_container_profile = create(:json_container_profile, :name => "Cardboard box")

    container_with_profile = create(:json_top_container,
                                    'barcode' => '123',
                                    'indicator' => '1',
                                    'container_profile' => {'ref' => test_container_profile.uri})

    TopContainer[container_with_profile.id].display_string.should eq("Cardboard box 1 [123]")
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
      container1_original_display_string = container1.display_string

      ComponentTransfer.transfer(resource2.uri, parent1.uri)

      container1.refresh.system_mtime.should be > container1_original_mtime
      container2.refresh.system_mtime.should be > container2_original_mtime

      container1.refresh.display_string.should_not eq(container1_original_display_string)
    end

  end

end
