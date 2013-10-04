# (C) Copyright IBM Corp. 2007
class TimestampTags < ActiveRecord::Migration
  def self.up
    add_column(:tags, :created_at, :datetime, {:null => false})
    add_column(:tags, :updated_at, :datetime, {:null => false})
  end

  def self.down
    remove_column(:tags, :created_at)
    remove_column(:tags, :updated_at)
  end
end
