class AddOptOutFieldToPeople < ActiveRecord::Migration
  def self.up
    add_column(:people, :optout, :boolean, :default => false)
  end

  def self.down
    remove_column(:people, :optout)
  end
end
