# (C) Copyright IBM Corp. 2007
class AddVersionToUsageLog < ActiveRecord::Migration
  def self.up
    add_column(:usage_logs, :version, :string)
  end

  def self.down
    remove_column(:usage_logs, :version)
  end
end
