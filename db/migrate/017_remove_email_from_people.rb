# (C) Copyright IBM Corp. 2007
class RemoveEmailFromPeople < ActiveRecord::Migration
  def self.up
    remove_column(:people, :email)
  end

  def self.down
    add_column(:people, :email, :string)
    Person.find(:all).each{ |person| 
        person.email = $profile.email_for_id(person.profile_id)
        person.save
    }
  end
end
