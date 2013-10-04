class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.column :name, :string
      t.column :group_type_id, :integer
      t.column :separation, :integer
    end
  end

  def self.down
    drop_table :groups
  end
end
