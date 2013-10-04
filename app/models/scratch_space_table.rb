# (C) Copyright IBM Corp. 2010

require 'json'

class ScratchSpaceTable < ActiveRecord::Base
  belongs_to :scratch_space
  has_and_belongs_to_many :procedures
  
  #def data
  #  return JSON.parse(self.data_json)
  #end
  
  #def data=(value)
  #  self.data_json = JSON.to_json(value)
  #end
end
