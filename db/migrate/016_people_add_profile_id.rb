# (C) Copyright IBM Corp. 2007
class PeopleAddProfileId < ActiveRecord::Migration
  def self.up
    add_column(:people, :profile_id, :string)
    Person.find(:all).each{ |person| 
        person.profile_id = $profile.profile_id_for_email(person.email)
        person.save
    }
  end

  def self.down
    remove_column(:people, :profile_id)
  end
end
