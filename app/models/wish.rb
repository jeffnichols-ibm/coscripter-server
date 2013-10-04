# (C) Copyright IBM Corp. 2010

class Wish < ActiveRecord::Base
	belongs_to :person
	has_many :wish_comments
end
