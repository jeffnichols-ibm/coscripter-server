# (C) Copyright IBM Corp. 2007
class AddDateToRatings < ActiveRecord::Migration
  def self.up
    add_column(:ratings, :created_at, :datetime, {:null => false})
    add_column(:ratings, :updated_at, :datetime, {:null => false})
  end

  def self.down
    remove_column(:ratings, :created_at)
    remove_column(:ratings, :updated_at)
  end
end
