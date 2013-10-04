class AddUsageCount < ActiveRecord::Migration
  def self.up
    add_column(:procedures,:usagecount, :integer, :default => 0 , :null =>false)
    execute "UPDATE procedures SET usagecount= (SELECT COUNT(procedure_executes.procedure_id) FROM procedure_executes WHERE procedure_executes.procedure_id=procedures.id) ;"

  end

  def self.down
    remove_column(:procedures,:usagecount)
  end
end
