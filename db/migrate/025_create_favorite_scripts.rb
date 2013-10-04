class CreateFavoriteScripts < ActiveRecord::Migration
  def self.up
    create_table :favorite_scripts, :options => "ENGINE=MyISAM" do |t|
		t.column :procedure_id, :integer, :null => false
		t.column :person_id, :integer, :null => false
    end

	execute "ALTER TABLE favorite_scripts ADD CONSTRAINT fk_favorite_scripts_procedure_id FOREIGN KEY (procedure_id) REFERENCES procedures(id);"
	execute "ALTER TABLE favorite_scripts ADD CONSTRAINT fk_favorite_scripts_person_id FOREIGN KEY (person_id) REFERENCES people(id);"
  end

  def self.down
    drop_table :favorite_scripts
  end
end
