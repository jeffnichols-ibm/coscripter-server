# (C) Copyright IBM Corp. 2010

class Change < ActiveRecord::Base
    belongs_to :person
    belongs_to :procedure
end
