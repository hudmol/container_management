module RightsStatementRestrictions

  def restricted_by_rights?
    rights_statement.any? do |rs|
      if rs.active == 1
        start = rs.restriction_start_date
        start &&= start.to_time
        enddd = rs.restriction_end_date
        enddd &&= enddd.to_time

        now = Time.now

        if enddd && (enddd < now)
          # end date has already happened.  Not applicable.
          return false
        elsif start && (start > now)
          # start date hasn't been reached yet.  Not applicable
          return false
        else
          return true
        end

      end
    end
  end

end

