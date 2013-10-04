# (C) Copyright IBM Corp. 2010

class SiteUsageLog < ActiveRecord::Base
    belongs_to :procedure
    belongs_to :person
end
