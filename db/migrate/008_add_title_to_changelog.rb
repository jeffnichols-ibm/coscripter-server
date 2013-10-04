# (C) Copyright IBM Corp. 2007
class AddTitleToChangelog < ActiveRecord::Migration
  def self.up
    add_column(:changes, :title, :string)
  end

  def self.down
    remove_column(:changes, :title)
  end
end
