class AddPopularityToProcedures < ActiveRecord::Migration
  def self.up
     add_column(:procedures,:popularity, :integer, :default => 0 , :null =>false)
  end

  def self.down
    remove_column(:procedures,:popularity)
  end
end
