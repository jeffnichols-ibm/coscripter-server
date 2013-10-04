class AddRecencyTable < ActiveRecord::Migration
  def self.up
    create_table :popularity_recencies, :force => true, :options => "ENGINE=MyISAM" do |t|
      t.column "days", :integer, :default => "1", :null => false
    end
    execute "insert into popularity_recencies (days) values (7)"
  end

  def self.down
    drop_table :popularity_recencies
  end
end
