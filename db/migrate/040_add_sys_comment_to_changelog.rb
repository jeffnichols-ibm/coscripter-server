class AddSysCommentToChangelog < ActiveRecord::Migration
  def self.up
    add_column(:changes, :syslog, :text)
  end

  def self.down
    remove_column(:changes, :syslog)
  end
end
