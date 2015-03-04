require 'spec_helper'
require_relative 'factories'


def create_container_profile(name, depth, height, width, dim_units, ext_dim)
  create(:json_container_profile, :name => name,
         :depth => depth,
         :height => height,
         :width => width,
         :dimension_units => dim_units,
         :extent_dimension => ext_dim)
end


def create_containers(container_profile, num = 1)
  containers = []
  num.times do |n|
    containers << create(:json_top_container, 'container_profile' => {'ref' => container_profile.uri})
  end
  containers
end


def create_ao_with_instances(resource, parent, containers = [])
  create(:json_archival_object,
         "resource" => {"ref" => resource.uri},
         "parent" => {"ref" => parent.uri},
         "instances" => containers.map{|con| build_instance(con)})
end


describe 'Extent Calculator model' do

  before(:each) do
    stub_barcode_length(0, 255)
  end

  let (:inch_to_cm) { 2.54 }
  let (:bigbox_extent) { 15 }
  let (:bigbox_profile) { create_container_profile("big box", "18", "12", bigbox_extent.to_s, "inches", "width") }
  let (:a_bigbox) { create(:json_top_container, 'container_profile' => {'ref' => bigbox_profile.uri}) }

  it "can calculate the total extent for a resource" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.total_extent.should eq(bigbox_extent)
  end


  it "can tell you the dimension units it used" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.units.should eq(:inches)
  end


  it "allows you to change the dimension units" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.units(:centimeters)
    ext_cal.total_extent.should eq(bigbox_extent*inch_to_cm)
  end


  it "tells you how many of each kind of container it found" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.containers("big box")[:count].should eq(1)
  end


  it "deals with large resources" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    boxes = create_containers(bigbox_profile, 100)
    create_ao_with_instances(resource, child, boxes)
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.total_extent.should eq(bigbox_extent*101)
  end


  it "doesn't mind different kinds of containers" do
    tinybox_profile = create_container_profile("tiny box", "1.5", "4.5", "3", "centimeters", "depth")
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    boxes = create_containers(bigbox_profile, 10)
    baby = create_ao_with_instances(resource, child, boxes)
    tiny_boxes = create_containers(tinybox_profile, 21)
    create_ao_with_instances(resource, baby, tiny_boxes)
    
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.units(:centimeters)
    ext_cal.total_extent.should eq(bigbox_extent*11*inch_to_cm+21*1.5)
    ext_cal.containers("big box")[:count].should eq(11)
    ext_cal.containers("big box")[:extent].should eq(bigbox_extent*11*inch_to_cm)
    ext_cal.containers("tiny box")[:count].should eq(21)
    ext_cal.containers("tiny box")[:extent].should eq(21*1.5)
  end


  it "doesn't count containers twice" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    create_ao_with_instances(resource, child, [a_bigbox])
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.total_extent.should eq(bigbox_extent)
  end


  it "can calculate extent for subtrees" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    boxes = create_containers(bigbox_profile, 10)
    baby = create_ao_with_instances(resource, child, boxes)
    more_boxes = create_containers(bigbox_profile, 10)
    egg = create_ao_with_instances(resource, baby, more_boxes)
    ext_cal = ExtentCalculator.new(ArchivalObject[baby.id])
    ext_cal.total_extent.should eq(bigbox_extent*20)
    ext_cal = ExtentCalculator.new(ArchivalObject[egg.id])
    ext_cal.total_extent.should eq(bigbox_extent*10)
  end


  it "can provide a hash rendering of itself" do
    tinybox_profile = create_container_profile("tiny box", "1.5", "4.5", "3", "centimeters", "depth")
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    boxes = create_containers(bigbox_profile, 10)
    baby = create_ao_with_instances(resource, child, boxes)
    tiny_boxes = create_containers(tinybox_profile, 21)
    create_ao_with_instances(resource, baby, tiny_boxes)
    
    ext_cal = ExtentCalculator.new(ArchivalObject[parent.id])
    ext_cal.units(:centimeters)

    ec_hash = ext_cal.to_hash
    ec_hash[:container_count].should eq(32)
  end

  it "objects if you try to set a unit it doesn't recognize" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    ext_cal = ExtentCalculator.new(resource)
    expect {
      ext_cal.units(:cubits)
    }.to raise_error
  end

end
