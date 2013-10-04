# (C) Copyright IBM Corp. 2010

class WishComment < ActiveRecord::Base
	belongs_to :person
	belongs_to :wish
end
