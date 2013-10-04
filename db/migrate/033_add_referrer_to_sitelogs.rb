class AddReferrerToSitelogs < ActiveRecord::Migration
  def self.up
    add_column(:site_usage_logs, :referrer, :text)
  end

  def self.down
    remove_column(:site_usage_logs, :referrer)
  end
end
