class MakeTestcaseActionOptional < ActiveRecord::Migration
  def self.up
    change_column :testcases, :action, :text, :default => "", :null => true
  end

  def self.down
    change_column :testcases, :action, :text, :default => "", :null => false
  end
end
