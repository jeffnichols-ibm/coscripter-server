# (C) Copyright IBM Corp. 2010

class ScratchSpace < ActiveRecord::Base
  belongs_to :person
  has_many :scratch_space_tables

    # ----------------------------------------------------------------------
    # For private pages
    # Intended usage:
    #    ScratchSpace.with_privacy(session[:user_id]) {
    #       ... code in controller to find scratch_spaces ...
    #    }
    def self.with_privacy(person_id = nil)
      if person_id.nil?
        person = nil
      else
        person = Person.find(person_id)
      end
      if person.nil?
        scope = { :find => { :conditions => ["scratch_spaces.private = false"] } }
      else
        scope = { :find => { :conditions => [
          "scratch_spaces.private = false or scratch_spaces.person_id = ?", person_id] } }
      end
      ScratchSpace.with_scope(scope) { yield }
    end

end
