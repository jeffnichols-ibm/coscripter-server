# (C) Copyright IBM Corp. 2007
class AddProfileData < ActiveRecord::Migration
  def self.up
    add_column(:people, :description, :string)
    add_column(:people, :home_page_url, :string)
    add_column(:people, :home_page_name, :string)
    add_column(:people, :updated_at, :datetime, {:null => false})
  end

  def self.down
    remove_column(:people, :description)
    remove_column(:people, :home_page_url)
    remove_column(:people, :home_page_name)
    remove_column(:people, :updated_at)
  end
end
