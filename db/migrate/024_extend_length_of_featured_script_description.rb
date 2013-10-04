class ExtendLengthOfFeaturedScriptDescription < ActiveRecord::Migration
  def self.up
	change_column(:featured_scripts, :description, :text)
  end

  def self.down
	change_column(:featured_scripts, :description, :string)
  end
end
