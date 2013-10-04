# (C) Copyright IBM Corp. 2007
class FixTimestamp < ActiveRecord::Migration
  def self.up
    remove_column(:people, :created_at)
    add_column(:people, :created_at, :datetime, {:null => false})
    change_column(:people, :name, :text, {:null => false})
  end

  def self.down
  end
end
