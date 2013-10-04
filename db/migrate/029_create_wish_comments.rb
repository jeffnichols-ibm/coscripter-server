class CreateWishComments < ActiveRecord::Migration
  def self.up
    create_table :wish_comments, :options => "ENGINE=MyISAM" do |t|
		t.column "wish_id", :integer, :default => 0, :null => false
		t.column "person_id", :integer, :default => 0, :null => false
		t.column "comment", :text, :default => "", :null => false
		t.column "created_at", :datetime, :null => false
		t.column "updated_at", :datetime, :null => false
    end

	execute "ALTER TABLE wish_comments ADD CONSTRAINT fk_wish_comments_person_id FOREIGN KEY (person_id) REFERENCES people(id);"
	execute "ALTER TABLE wish_comments ADD CONSTRAINT fk_wish_comments_wish_id FOREIGN KEY (wish_id) REFERENCES wishes(id);"
  end

  def self.down
    drop_table :wish_comments
  end
end
