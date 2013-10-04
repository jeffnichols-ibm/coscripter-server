class FixJoinTableForProceduresToScratchSpaceTables < ActiveRecord::Migration
  def self.up
    # The original name of the join table between procedures and 
    # scratch_space_tables didn't follow Rails convention
    rename_table :scratch_space_tables_procedures, :procedures_scratch_space_tables
  end

  def self.down
    rename_table :procedures_scratch_space_tables, :scratch_space_tables_procedures
  end
end
