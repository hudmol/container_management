require 'spec_helper'
require_relative 'factories'
require_relative 'container_spec_helper'


DEFAULT_INDICATOR = 'default_indicator'


def stub_default_indicator
  AppConfig.stub(:[]).and_call_original
  AppConfig.stub(:has_key?).and_call_original

  AppConfig.stub(:has_key?).with(:yale_containers_default_indicator).and_return(true)
  AppConfig.stub(:[]).with(:yale_containers_default_indicator).and_return(DEFAULT_INDICATOR)
end


describe 'Yale Container compatibility' do

  describe "mapping yale containers to archivesspace containers" do

    it "maps a subcontainer/topcontainer/container profile to an ArchivesSpace instance record" do
      location = create(:json_location)

      test_container_profile = create(:json_container_profile,
                                      'name' => 'Flat Grey 16x20x3')

      container_with_profile = create(:json_top_container,
                                      'container_profile' => {'ref' => test_container_profile.uri},
                                      'barcode' => '9999',
                                      'indicator' => '1000',
                                      'container_locations' => [
                                        JSONModel(:container_location).from_hash('status' => 'current',
                                                                                 'start_date' => '2000-01-01',
                                                                                 'ref' => location.uri)
                                      ]
                                     )

      instance = build_instance(TopContainer.to_jsonmodel(container_with_profile.id),
                                'type_2' => 'folder',
                                'indicator_2' => '222',
                                'type_3' => 'reel',
                                'indicator_3' => '333')

      accession = create_accession({"instances" => [instance]})

      generated_container = Accession.to_jsonmodel(accession.id)['instances'].first['container']

      generated_container['type_1'].should eq('box')
      generated_container['indicator_1'].should eq('1000')
      generated_container['barcode_1'].should eq('9999')

      generated_container['type_2'].should eq('folder')
      generated_container['indicator_2'].should eq('222')
      generated_container['type_3'].should eq('reel')
      generated_container['indicator_3'].should eq('333')

      generated_container['container_locations'][0]['ref'].should eq(location.uri)
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
      stub_default_indicator

      instance = JSONModel(:instance).from_hash("instance_type" => "text",
                                                "container" => {
                                                  "barcode_1" => '12345678',
                                                })

      accession = create_accession({"instances" => [instance]})

      created = TopContainer[:barcode => '12345678']
      created.indicator.should eq(DEFAULT_INDICATOR)
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
    end



    it "finds an existing top container linked within the same resource if it can't find one in the series" do
      container = TopContainer.create_from_json(JSONModel(:top_container).from_hash('indicator' => '1234'))

      # child links to our top container
      (resource, grandparent, parent, child) = create_tree(container)

      # create a new archival object under grandparent with an instance with the same indicator
      new_ao = create(:json_archival_object,
                      "resource" => {"ref" => resource.uri},
                      "instances" => [JSONModel(:instance).from_hash("instance_type" => "text",
                                                                     "container" => {
                                                                       "type_1" => 'box',
                                                                       "indicator_1" => '1234'
                                                                     })])

      # and it's magically linked up with the right container (from the different series)
      ArchivalObject.to_jsonmodel(new_ao.id)['instances'].first['sub_container']['top_container']['ref'].should eq(container.uri)
    end


    it "updates and links the top container even if we're updating the series AO" do
      container = TopContainer.create_from_json(JSONModel(:top_container).from_hash('indicator' => '1234'))

      # child links to our top container
      (resource, grandparent, parent, child) = create_tree(container)


      json = ArchivalObject.to_jsonmodel(grandparent.id)

      json['instances'] =  [JSONModel(:instance).from_hash("instance_type" => "text",
                                                           "container" => {
                                                             "type_1" => 'box',
                                                             "indicator_1" => '1234'
                                                           }).to_hash]

      ArchivalObject[grandparent.id].update_from_json(json)

      # and it's magically linked up with the right container (from within the current series)
      ArchivalObject.to_jsonmodel(grandparent.id)['instances'].first['sub_container']['top_container']['ref'].should eq(container.uri)
    end


  end


  it "throws an exception if the incoming record has different field values to the top container we're linking against" do
    container = TopContainer.create_from_json(JSONModel(:top_container).from_hash('indicator' => '1234', 'barcode' => '12345678'))

    instance = JSONModel(:instance).from_hash("instance_type" => "text",
                                              "container" => {
                                                "barcode_1" => '12345678',
                                                "indicator_1" => 'different_to_1234'
                                              })

    expect {
      accession = create_accession({"instances" => [instance]})
    }.to raise_error(ValidationException)

  end



  it "maps location records when creating a new top container" do
    location = create(:json_location)

    instance = JSONModel(:instance).from_hash("instance_type" => "text",
                                              "container" => {
                                                "barcode_1" => '12345678',
                                                "indicator_1" => '123',
                                                "container_locations" => [
                                                  JSONModel(:container_location).from_hash('status' => 'current',
                                                                                           'start_date' => '2000-01-01',
                                                                                           'ref' => location.uri)
                                                ]
                                              })

    accession = create_accession({"instances" => [instance]})

    created = TopContainer[:barcode => '12345678']
    TopContainer.to_jsonmodel(created.id)['container_locations'][0]['ref'].should eq(location.uri)
  end

  it "checks for differences in location records when re-using top containers" do
    location_1 = create(:json_location)
    location_2 = create(:json_location)

    container = TopContainer.create_from_json(JSONModel(:top_container).from_hash('indicator' => '1234',
                                                                                  'barcode' => '12345678',
                                                                                  "container_locations" => [
                                                                                    JSONModel(:container_location).from_hash('status' => 'current',
                                                                                                                             'start_date' => '2000-01-01',
                                                                                                                             'ref' => location_1.uri)
                                                                                  ]))

    # Using a different location!
    instance = JSONModel(:instance).from_hash("instance_type" => "text",
                                              "container" => {
                                                "barcode_1" => '12345678',
                                                "container_locations" => [
                                                  JSONModel(:container_location).from_hash('status' => 'current',
                                                                                           'start_date' => '2000-01-01',
                                                                                           'ref' => location_2.uri)
                                                ]
                                              })

    expect {
      accession = create_accession({"instances" => [instance]})
    }.to raise_error(ValidationException)
  end


  it "lets it slide if the incoming ArchivesSpace container has no locations" do
    location = create(:json_location)

    container = TopContainer.create_from_json(JSONModel(:top_container).from_hash('indicator' => '1234',
                                                                                  'barcode' => '12345678',
                                                                                  "container_locations" => [
                                                                                    JSONModel(:container_location).from_hash('status' => 'current',
                                                                                                                             'start_date' => '2000-01-01',
                                                                                                                             'ref' => location.uri)
                                                                                  ]))

    # Using a different location!
    instance = JSONModel(:instance).from_hash("instance_type" => "text",
                                              "container" => {
                                                "barcode_1" => '12345678',
                                                "container_locations" => []
                                              })

    expect {
      accession = create_accession({"instances" => [instance]})
    }.to_not raise_error(ValidationException)
  end



  it "creates a subcontainer with type_{2,3}/indicator_{2,3}" do
    instance = JSONModel(:instance).from_hash("instance_type" => "text",
                                              "container" => {
                                                "barcode_1" => '12345678',
                                                "indicator_1" => '123',
                                                "type_2" => 'folder',
                                                "indicator_2" => 'ind2',
                                                "type_3" => 'reel',
                                                "indicator_3" => 'ind3'
                                              })

    accession = create_accession({"instances" => [instance]})

    subcontainer = Accession.to_jsonmodel(accession.id)['instances'].first['sub_container']

    subcontainer['type_2'].should eq('folder')
    subcontainer['type_3'].should eq('reel')

    subcontainer['indicator_2'].should eq('ind2')
    subcontainer['indicator_3'].should eq('ind3')
  end


end
