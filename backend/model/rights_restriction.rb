class RightsRestriction < Sequel::Model(:rights_restriction)

  one_to_many :rights_restriction_type

end
