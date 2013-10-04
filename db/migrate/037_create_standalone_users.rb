class CreateStandaloneUsers < ActiveRecord::Migration
  def self.up
    create_table :standalone_users, :options => "ENGINE=MyISAM" do |t|
		# Email is the primary key
		# Password is an encoded version of the password
		t.column :email, :string
		t.column :password, :string
    end
  end

  def self.down
    drop_table :standalone_users
  end
end
