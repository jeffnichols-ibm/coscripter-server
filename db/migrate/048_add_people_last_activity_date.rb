class AddPeopleLastActivityDate < ActiveRecord::Migration
  def self.up
    add_column(:people, :last_active_at, :datetime)
    # to start with we set everyones last activity to their last script execution
    execute "update people set last_active_at = ( select max(executed_at) from procedure_executes where procedure_executes.person_id = people.id)"
  end

  def self.down
    remove_column(:people, :last_active_at)
  end
end
