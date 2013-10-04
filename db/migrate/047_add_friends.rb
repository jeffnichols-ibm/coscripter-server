class AddFriends < ActiveRecord::Migration
  def self.up
      create_table :friends_people, :id => false  do |t|
	t.column "person_id", :integer
	t.column "friend_id", :integer
      end
  end

  def self.down
      drop_table :friends_people
  end
end
