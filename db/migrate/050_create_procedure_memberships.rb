class CreateProcedureMemberships < ActiveRecord::Migration
  def self.up
    create_table :procedure_memberships,:id=>false do |t|
      t.column "procedure_id", :integer
      t.column "person_id", :integer
    end
  end

  def self.down
    drop_table :procedure_memberships
  end
end
