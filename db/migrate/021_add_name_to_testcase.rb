class AddNameToTestcase < ActiveRecord::Migration
  def self.up
    add_column(:testcases, :name, :string)
  end

  def self.down
    remove_column(:testcases, :name)
  end
end
