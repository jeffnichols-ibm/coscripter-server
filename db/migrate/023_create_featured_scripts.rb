class CreateFeaturedScripts < ActiveRecord::Migration
  def self.up
    create_table :featured_scripts, :options => "ENGINE=MyISAM" do |t|
      t.column :procedure_id, :integer, :null => false
	  t.column :description, :string
    end
	
	execute "ALTER TABLE featured_scripts ADD CONSTRAINT fk_featured_scripts_procedure_id FOREIGN KEY (procedure_id) REFERENCES procedures(id);"
  end

  def self.down
	drop_table :featured_scripts
  end
end
