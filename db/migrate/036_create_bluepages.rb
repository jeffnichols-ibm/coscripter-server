class CreateBluepages < ActiveRecord::Migration
  def self.up
    create_table :bluepages, :options => "ENGINE=MyISAM" do |t|
      t.column :person_id, :integer
	  t.column :email, :string
	  t.column :dept, :string
	  t.column :div, :string
	  t.column :bldg, :string
	  t.column :country, :string
	  t.column :mgrnum, :string
    end

    execute "ALTER TABLE bluepages ADD CONSTRAINT fk_bluepages_person_id FOREIGN KEY (person_id) REFERENCES people(id);"
  end


  def self.down
    drop_table :bluepages
  end
end
