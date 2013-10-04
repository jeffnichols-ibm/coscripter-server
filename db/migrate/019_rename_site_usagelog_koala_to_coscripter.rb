# (C) Copyright IBM Corp. 2007
class RenameSiteUsagelogKoalaToCoscripter < ActiveRecord::Migration
  def self.up
    rename_column("site_usage_logs", "koala_session_id", "coscripter_session_id")
  end

  def self.down
    rename_column("site_usage_logs", "coscripter_session_id", "koala_session_id")
  end
end
