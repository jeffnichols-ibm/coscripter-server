# (C) Copyright IBM Corp. 2007
class CreateSiteUsageLog < ActiveRecord::Migration
  def self.up
    create_table :site_usage_logs, :options => "ENGINE=MyISAM" do |t|
      t.column :accessed_at, :datetime, :null => false
      t.column :controller, :string, :null => false
      t.column :action, :string, :null => false
      t.column :uri, :string
      t.column :person_id, :integer
      t.column :koala_session_id, :string
      t.column :ip, :string, :null => false
    end

    execute "ALTER TABLE site_usage_logs ADD CONSTRAINT fk_site_usage_logs_person_id FOREIGN KEY (person_id) REFERENCES people(id);"
  end

  def self.down
    drop_table :site_usage_logs
  end
end
