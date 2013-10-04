class MakePersonOptionalInUsagelog < ActiveRecord::Migration
  def self.up
    change_column :usage_logs, :person_id, :integer, :default => 0, :null => true
  end

  def self.down
    change_column :usage_logs, :person_id, :integer, :default => 0, :null => false
  end
end
