# (C) Copyright IBM Corp. 2010

class BestBet < ActiveRecord::Base
    belongs_to :procedure

    def self.find_all_procedures
	bestbets = find :all
        # The reason we filter out nil procedures here is because some best
        # bets might have been marked as private, so we don't have access
        # to them here.  This would show up in the list as the procedure
        # field of the bestbet object being nil, so we filter them out at
        # this point.   (Perhaps this also happens when the bestbet has
        # been deleted, yet its record still exists in the bestbet table.)
	bestbets.map { |bestbet| bestbet.procedure }.delete_if {|p| p.nil?}
    end
end
