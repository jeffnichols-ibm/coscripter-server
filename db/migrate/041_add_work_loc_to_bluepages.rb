class AddWorkLocToBluepages < ActiveRecord::Migration
  def self.up
	add_column(:bluepages, :workloc, :string)
	add_column(:bluepages, :hremployeetype, :string)
  end

  def self.down
	remove_column(:bluepages, :workloc)
	remove_column(:bluepages, :hremployeetyp)
  end
end
