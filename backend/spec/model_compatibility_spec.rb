require 'spec_helper'
require_relative 'factories'
require_relative 'container_spec_helper'


describe 'Yale Container compatibility' do

  describe "mapping yale containers to archivesspace containers" do

    before(:each) do
      MapToAspaceContainer.mapper_to_aspace_json = SubContainerToAspaceJsonMapper
    end


    it "maps a subcontainer/topcontainer/container profile to an ArchivesSpace instance record" do
      test_container_profile = create(:json_container_profile,
                                      'name' => 'Flat Grey 16x20x3')

      container_with_profile = create(:json_top_container,
                                      'container_profile' => {'ref' => test_container_profile.uri},
                                      'barcode' => '9999',
                                      'indicator' => '1000')

      instance = build_instance(TopContainer.to_jsonmodel(container_with_profile.id),
                                'type_2' => 'folder',
                                'indicator_2' => '222',
                                'type_3' => 'reel',
                                'indicator_3' => '333')

      accession = create_accession({"instances" => [instance]})

      generated_container = Accession.to_jsonmodel(accession.id)['instances'].first['container']

      generated_container['type_1'].should eq('carton')
      generated_container['indicator_1'].should eq('1000')
      generated_container['barcode_1'].should eq('9999')

      generated_container['type_2'].should eq('folder')
      generated_container['indicator_2'].should eq('222')
      generated_container['type_3'].should eq('reel')
      generated_container['indicator_3'].should eq('333')
    end


    it "maps a minimal subcontainer/topcontainer/container profile to an ArchivesSpace instance record" do
      # no container profile, no barcode
      container = TopContainer.create_from_json(JSONModel(:top_container).from_hash('indicator' => '1234'))

      # top container but no subcontainer fields (they're all optional)
      instance = JSONModel(:instance).from_hash("instance_type" => "text",
                                                "sub_container" => JSONModel(:sub_container).from_hash(
                                                  "top_container" => {
                                                    "ref" => container.uri
                                                  }),
                                                "container" => nil
                                               )

      accession = create_accession({"instances" => [instance]})

      generated_container = Accession.to_jsonmodel(accession.id)['instances'].first['container']

      generated_container['type_1'].should eq('box')
      generated_container['indicator_1'].should eq('1234')
    end


    it "finds an existing top container by barcode when creating from an ArchivesSpace container" do
      container = TopContainer.create_from_json(JSONModel(:top_container).from_hash('indicator' => '1234', 'barcode' => '12345678'))

      instance = JSONModel(:instance).from_hash("instance_type" => "text",
                                                "container" => {
                                                  "barcode_1" => '12345678'
                                                })

      accession = create_accession({"instances" => [instance]})

      Accession.to_jsonmodel(accession.id)['instances'].first['sub_container']['top_container']['ref'].should eq(container.uri)
    end


    it "creates a top container with a barcode if none already exists" do
      instance = JSONModel(:instance).from_hash("instance_type" => "text",
                                                "container" => {
                                                  "barcode_1" => '12345678',
                                                  "indicator_1" => '999'
                                                })

      accession = create_accession({"instances" => [instance]})

      created = TopContainer[:barcode => '12345678']
      created.indicator.should eq('999')
    end


    it "creates a top container with a barcode if none already exists, defaulting the indicator if absent" do
      instance = JSONModel(:instance).from_hash("instance_type" => "text",
                                                "container" => {
                                                  "barcode_1" => '12345678',
                                                })

      accession = create_accession({"instances" => [instance]})

      created = TopContainer[:barcode => '12345678']
      created.indicator.should eq('1')
    end


    it "finds an existing top container linked within the same series where the ind_1 matches" do
      container = TopContainer.create_from_json(JSONModel(:top_container).from_hash('indicator' => '1234'))

      # child links to our top container
      (resource, grandparent, parent, child) = create_tree(container)

      # create a new archival object under grandparent with an instance with the same indicator
      new_ao = create(:json_archival_object,
                      "resource" => {"ref" => resource.uri},
                      "parent" => {"ref" => grandparent.uri},
                      "instances" => [JSONModel(:instance).from_hash("instance_type" => "text",
                                                                     "container" => {
                                                                       "type_1" => 'box',
                                                                       "indicator_1" => '1234'
                                                                     })])

      # and it's magically linked up with the right container
      ArchivalObject.to_jsonmodel(new_ao.id)['instances'].first['sub_container']['top_container']['ref'].should eq(container.uri)

      # a top-level AO in a different series doesn't match, though
      another_ao = create(:json_archival_object,
                          "resource" => {"ref" => resource.uri},
                          "parent" => nil,
                          "instances" => [JSONModel(:instance).from_hash("instance_type" => "text",
                                                                         "container" => {
                                                                           "type_1" => 'box',
                                                                           "indicator_1" => '1234'
                                                                         })])


      ArchivalObject.to_jsonmodel(another_ao.id)['instances'].first['sub_container']['top_container']['ref'].should_not eq(container.uri)
    end



  end



end
