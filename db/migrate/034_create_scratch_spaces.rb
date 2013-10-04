class CreateScratchSpaces < ActiveRecord::Migration
  def self.up
    create_table :scratch_spaces, :options => "ENGINE=MyISAM" do |t|
      t.column :title, :text, :default => "", :null => false
      t.column :description, :text, :default => "", :null => false
      t.column :person_id, :integer, :null => false
      t.column :private, :boolean, {:null => false, :default => true}
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
    execute "ALTER TABLE scratch_spaces ADD CONSTRAINT fk_scratch_spaces_person_id FOREIGN KEY (person_id) REFERENCES people(id);"

    create_table :scratch_space_tables, :options => "ENGINE=MyISAM" do |t|
      t.column :scratch_space_id, :integer, :null => false
      t.column :title, :text, :default => "", :null => false
      t.column :data_json, :text, :default => "", :null => false
      t.column :notes, :text, :default => "", :null => false
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
    execute "ALTER TABLE scratch_space_tables ADD CONSTRAINT fk_scratch_spaces_tables_scratch_space_id FOREIGN KEY (scratch_space_id) REFERENCES scratch_spaces(id);"
    
    create_table :scratch_space_tables_procedures, :options => "ENGINE=MyISAM", :id => false do |t|
      t.column :scratch_space_table_id, :integer, :null => false
      t.column :procedure_id, :integer, :null => false
    end
    execute "ALTER TABLE scratch_space_tables_procedures ADD CONSTRAINT fk_scratch_spaces_tables_procedures_scratch_space_table_id FOREIGN KEY (scratch_space_table_id) REFERENCES scratch_space_tables(id);"
    execute "ALTER TABLE scratch_space_tables_procedures ADD CONSTRAINT fk_scratch_spaces_tables_procedures_procedure_id FOREIGN KEY (procedure_id) REFERENCES procedures(id);"
    
    add_index :scratch_space_tables_procedures, [:scratch_space_table_id, :procedure_id], :name => "index_scratch_table_procedures_table_and_procedure_ids"
    add_index :scratch_space_tables_procedures, :scratch_space_table_id, :name => "index_scratch_table_procedures_table_id"
end

  def self.down
    drop_table :scratch_space_tables_procedures
    drop_table :scratch_space_tables
    drop_table :scratch_spaces
  end
end
