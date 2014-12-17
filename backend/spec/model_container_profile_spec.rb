require 'spec_helper'
require_relative 'factories'

describe 'Container Profile model' do

  it "supports creating a container profile" do
    
    container_profile = build(:json_container_profile, {})
    # this should then probably 'expect' something
  end

  it "enforces name uniqueness within a repository" do
      create(:json_container_profile, :name => "1234")

      expect {
        create(:json_container_profile, :name => "1234")
      }.to raise_error(ValidationException)
  end

end
