require 'spec_helper'
require_relative 'factories'
require_relative 'container_spec_helper'


describe 'Yale Container compatibility' do

  describe "mapping yale containers to archivesspace containers" do

    before(:each) do
      MapToAspaceContainer.mapper = SubContainerToAspaceMapper
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

      JSONModel(:accession).from_hash(generated_container)

      p generated_container

      # generated_container['type_1'].should eq('carton')
      # generated_container['indicator_1'].should eq('1000')
      # generated_container['barcode_1'].should eq('9999')
      # 
      # generated_container['type_2'].should eq('folder')
      # generated_container['indicator_2'].should eq('222')
      # generated_container['type_3'].should eq('reel')
      # generated_container['indicator_3'].should eq('333')
    end


  end

end
