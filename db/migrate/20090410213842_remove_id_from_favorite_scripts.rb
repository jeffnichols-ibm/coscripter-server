class RemoveIdFromFavoriteScripts < ActiveRecord::Migration
  def self.up
      remove_column :favorite_scripts, :id
  end

  def self.down
      add_column :favorite_scripts, :id
  end
end
