class CreateGroupTypes < ActiveRecord::Migration
  def self.up
    create_table :group_types do |t|
      t.column :name, :string
    end
    GroupType.create(:name=>"Location")
    GroupType.create(:name=>"Organization")
  end

  def self.down
    drop_table :group_types
  end
end
