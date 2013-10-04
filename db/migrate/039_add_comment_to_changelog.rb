class AddCommentToChangelog < ActiveRecord::Migration
  def self.up
    add_column(:changes, :log, :text)
  end

  def self.down
    remove_column(:changes, :log)
  end
end
