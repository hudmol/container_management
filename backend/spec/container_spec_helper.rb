def create_tree(top_container_json, opts = {})
  resource = create_resource
  grandparent = create(:json_archival_object, {:resource => {"ref" => resource.uri}, :level => "series", :component_id => SecureRandom.hex}.merge(opts.fetch(:grandparent_properties, {})))
  parent = create(:json_archival_object, "resource" => {"ref" => resource.uri}, "parent" => {"ref" => grandparent.uri})
  child = create(:json_archival_object,
                 "resource" => {"ref" => resource.uri},
                 "parent" => {"ref" => parent.uri},
                 "instances" => [build_instance(top_container_json)])

  [resource, grandparent, parent, child]
end




def build_instance(top_container_json, subcontainer_opts = {})
  build(:json_instance, {
          "instance_type" => "text",
          "sub_container" => build(:json_sub_container, {
                                     "top_container" => {
                                       "ref" => top_container_json.uri
                                     }
                                   }.merge(subcontainer_opts)),
          "container" => nil
        })
end
