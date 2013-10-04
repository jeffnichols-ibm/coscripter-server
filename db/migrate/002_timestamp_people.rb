# (C) Copyright IBM Corp. 2007
class TimestampPeople < ActiveRecord::Migration
  def self.up
    # Add in a column to the people table recording when the account was
    # activated.  If no data is available, default to now.
    add_column(:people, :created_at, :datetime, {:null => false,
      :default => Time.now})
  end

  def self.down
    remove_column(:people, :created_at)
  end
end
