require 'spec_helper'
require_relative 'factories'

describe 'Yale Container mixin' do

  it "can link an Accession to a Yale Container" do
    yale_container = build(:json_yale_container, {})

    created_id = YaleContainer.create_from_json(yale_container, :repo_id => $repo_id).id
    created_uri = JSONModel(:yale_container).uri_for(created_id)

    accession = create_accession({
      "instances" => [build(:json_instance, {
        "instance_type" => "accession",
        "yale_container" => {
          "ref" => created_uri
        }
      })]
    })

    Accession.to_jsonmodel(accession.id).instances[0]["yale_container"]["ref"].should eq(created_uri)
  end

end
