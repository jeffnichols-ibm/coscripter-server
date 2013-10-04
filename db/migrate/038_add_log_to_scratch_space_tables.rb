class AddLogToScratchSpaceTables < ActiveRecord::Migration
  def self.up
    add_column(:scratch_space_tables, :log, :text, :default => "", :null => false)
  end

  def self.down
    remove_column(:scratch_space_tables, :log)
  end
end
