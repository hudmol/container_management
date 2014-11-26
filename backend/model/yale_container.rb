class YaleContainer < Sequel::Model(:yale_container)
  include ASModel

  corresponds_to JSONModel(:yale_container)

  set_model_scope :repository
end
