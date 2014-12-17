require 'spec_helper'
require_relative 'factories'

describe 'Container Profile model' do

  it "can be created from a JSON module" do
    cp = ContainerProfile.create_from_json(build(:json_container_profile, :name => "Big black bag"),
                                         :repo_id => $repo_id)

    ContainerProfile[cp[:id]].name.should eq("Big black bag")
  end


  it "enforces name uniqueness within a repository" do
      create(:json_container_profile, :name => "1234")

      expect {
        create(:json_container_profile, :name => "1234")
      }.to raise_error(ValidationException)
  end


  it "doesn't enforce name uniqueness between repositories" do
    repo1 = make_test_repo("REPO1")
    repo2 = make_test_repo("REPO2")

    expect {
      [repo1, repo2].each do |repo_id|
        ContainerProfile.create_from_json(build(:json_container_profile, {:name => "Gary"}), :repo_id => repo_id)
      end
    }.to_not raise_error
  end

  it "blows up if you don't specify which repository you're querying" do
    cp = create(:json_container_profile)

    expect {
      RequestContext.put(:repo_id, nil)
      ContainerProfile.to_jsonmodel(cp[:id])
    }.to raise_error
  end

end
