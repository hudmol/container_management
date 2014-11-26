module YaleContainers

  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)

    # json
    $stderr.puts("\n*** DEBUG #{(Time.now.to_f * 1000).to_i} [yale_containers.rb:11 cb2c34]: " + {'json' => json}.inspect + "\n")

    super
  end


  module ClassMethods

    def create_from_json(json, opts = {})

      # json
      $stderr.puts("\n*** DEBUG #{(Time.now.to_f * 1000).to_i} [yale_containers.rb:20 bc4a3c]: " + {'json' => json}.inspect + "\n")

      super
    end


    def sequel_to_jsonmodel(objs, opts = {})

      # objs
      $stderr.puts("\n*** DEBUG #{(Time.now.to_f * 1000).to_i} [yale_containers.rb:29 b876cd]: " + {'objs' => objs}.inspect + "\n")

      super
    end

  end

end
