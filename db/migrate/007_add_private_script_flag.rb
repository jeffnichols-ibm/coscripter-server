# (C) Copyright IBM Corp. 2007
class AddPrivateScriptFlag < ActiveRecord::Migration
  def self.up
    add_column(:procedures, :private, :boolean, {:null => false,
      :default => false})
  end

  def self.down
    remove_column(:procedures, :private)
  end
end
