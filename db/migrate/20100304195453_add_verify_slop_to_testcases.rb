class AddVerifySlopToTestcases < ActiveRecord::Migration
  def self.up
      add_column :testcases, :verify_slop, :boolean, :default => true
  end

  def self.down

      remove_column :testcases, :verify_slop
  end
end
