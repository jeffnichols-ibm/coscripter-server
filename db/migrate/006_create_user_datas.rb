# (C) Copyright IBM Corp. 2007
class CreateUserDatas < ActiveRecord::Migration
  def self.up
    create_table :user_datas, :options => "ENGINE=MyISAM" do |t|
      t.column :person_id, :integer, :null => false
      t.column :name, :string, :null => false
      t.column :value, :text
    end
    add_index :user_datas, [:person_id, :name]
    execute "ALTER TABLE user_datas ADD CONSTRAINT fk_user_datas_person_id FOREIGN KEY (person_id) REFERENCES people(id);"
  end

  def self.down
    drop_table :user_datas
  end
end
