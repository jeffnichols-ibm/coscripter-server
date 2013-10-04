class CreateWishes < ActiveRecord::Migration
	def self.up
		create_table :wishes, :options => "ENGINE=MyISAM" do |t|
			t.column :wish, :text
			t.column :person_id, :integer
			t.column :url, :text
			t.column :title, :text
			t.column :created_at, :datetime
		end

		execute "ALTER TABLE wishes ADD CONSTRAINT fk_wishes_person_id FOREIGN KEY (person_id) REFERENCES people(id);"
	end

	def self.down
		drop_table :wishes
	end
end
