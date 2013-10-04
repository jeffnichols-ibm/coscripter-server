class CreatePeopleGroups < ActiveRecord::Migration
  def self.up
    create_table :groups_people, :id => false do |t|
      t.column :person_id, :integer
      t.column :group_id, :integer
    end
    add_index :groups_people, [:person_id]
    add_index :groups_people, [:group_id]

  end

  def self.down
    drop_table :groups_people
  end
end
