class AddLastExecutionToProcedure < ActiveRecord::Migration
  def self.up
    add_column(:procedures, :last_executed_at, :datetime, :default => nil, :null => true )
    execute "UPDATE procedures SET last_executed_at = (SELECT MAX(procedure_executes.executed_at) FROM procedure_executes WHERE procedure_executes.procedure_id=procedures.id) ;"
  end

    def self.down
      remove_column(:procedures,  :last_executed_at)
    end
  end
