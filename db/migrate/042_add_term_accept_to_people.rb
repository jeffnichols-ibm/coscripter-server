class AddTermAcceptToPeople < ActiveRecord::Migration
  def self.up
	add_column(:people, :accepted_alm_terms, :boolean, :default => false)
  end

  def self.down
	remove_column(:people, :accepted_alm_terms)
  end
end
