class AddClientVersionToSiteUsageLog < ActiveRecord::Migration
  def self.up
        add_column(:site_usage_logs, :client_version, :string)
  end

  def self.down
	remove_column(:site_usage_logs, :client_version)
  end
end
