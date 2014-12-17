require 'spec_helper'
require_relative 'factories'

describe 'Yale Container mixin' do

  it "can create an Accession with a Sub Container" do
    top_container = build(:json_top_container, {})

    top_container_id = TopContainer.create_from_json(top_container, :repo_id => $repo_id).id
    top_container_uri = JSONModel(:top_container).uri_for(top_container_id)

    sub_container = build(:json_sub_container, {
      "top_container" => {
        "ref" => top_container_uri
      }
    })

    accession = create_accession({
      "instances" => [build(:json_instance, {
        "instance_type" => "accession",
        "sub_container" => sub_container
      })]
    })

    instances = Accession.to_jsonmodel(accession.id).instances
    instances.length.should eq(1)
    instances[0]["sub_container"].should_not be_nil
    instances[0]["sub_container"]["top_container"].should_not be_nil
    instances[0]["sub_container"]["top_container"]["ref"].should eq(top_container_uri)
  end

end
