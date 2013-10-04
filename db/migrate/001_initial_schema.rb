# (C) Copyright IBM Corp. 2007
class InitialSchema < ActiveRecord::Migration
  # TODO: add in all foreign key constraints so that the next person using
  # this migration has a working database
  def self.up

    # people and admins
    create_table "people", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.column "email", :string, :default => "", :null => false
      t.column "name", :text
    end

    create_table "administrators", :force => true, :options => "ENGINE=MyISAM"  do |t|
      t.column "person_id", :integer, :default => 0, :null => false
    end
    execute "ALTER TABLE administrators ADD CONSTRAINT fk_administrators_person_id FOREIGN KEY (person_id) REFERENCES people(id);"

    # scripts
    create_table "procedures", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.column "title", :text, :default => "", :null => false
      t.column "person_id", :integer, :default => 0, :null => false
      t.column "created_at", :datetime, :null => false
      t.column "modified_at", :datetime, :null => false
      t.column "body", :text
    end
    execute "ALTER TABLE procedures ADD CONSTRAINT fk_procedures_person_id FOREIGN KEY (person_id) REFERENCES people(id);"
    execute "CREATE FULLTEXT INDEX FullText_Procedures_title_body ON procedures (title, body);"

    # editor's picks
    create_table "best_bets", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.column "procedure_id", :integer, :default => 0, :null => false
    end
    execute "ALTER TABLE best_bets ADD CONSTRAINT fk_best_bets_procedure_id FOREIGN KEY (procedure_id) REFERENCES procedures(id);"

    # script changelog
    create_table "changes", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.column "procedure_id", :integer, :default => 0, :null => false
      t.column "person_id", :integer, :default => 0, :null => false
      t.column "body", :text, :default => "", :null => false
      t.column "modified_at", :datetime, :null => false
    end
    execute "ALTER TABLE changes ADD CONSTRAINT fk_changes_procedure_id FOREIGN KEY (procedure_id) REFERENCES procedures(id);"
    execute "ALTER TABLE changes ADD CONSTRAINT fk_changes_person_id FOREIGN KEY (person_id) REFERENCES people(id);"

    # comments on scripts
    create_table "procedure_comments", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.column "procedure_id", :integer, :default => 0, :null => false
      t.column "person_id", :integer, :default => 0, :null => false
      t.column "comment", :text, :default => "", :null => false
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
    end
    execute "ALTER TABLE procedure_comments ADD CONSTRAINT fk_procedure_comments_procedure_id FOREIGN KEY (procedure_id) REFERENCES procedures(id);"
    execute "ALTER TABLE procedure_comments ADD CONSTRAINT fk_procedure_comments_person_id FOREIGN KEY (person_id) REFERENCES people(id);"

    # ratings
    create_table "ratings", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.column "procedure_id", :integer, :default => 0, :null => false
      t.column "rating", :integer, :default => 0, :null => false
      t.column "person_id", :integer, :default => 0, :null => false
    end
    execute "ALTER TABLE ratings ADD CONSTRAINT fk_ratings_procedure_id FOREIGN KEY (procedure_id) REFERENCES procedures(id);"
    execute "ALTER TABLE ratings ADD CONSTRAINT fk_ratings_person_id FOREIGN KEY (person_id) REFERENCES people(id);"

    # tags
    create_table "tags", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.column "procedure_id", :integer, :default => 0, :null => false
      t.column "raw_name", :string, :default => "", :null => false
      t.column "clean_name", :string, :default => "", :null => false
      t.column "person_id", :integer, :default => 0, :null => false
    end
    execute "ALTER TABLE tags ADD CONSTRAINT fk_tags_procedure_id FOREIGN KEY (procedure_id) REFERENCES procedures(id);"
    execute "ALTER TABLE tags ADD CONSTRAINT fk_tags_person_id FOREIGN KEY (person_id) REFERENCES people(id);"

    # ----------------------------------------------------------------------
    # test cases
    create_table "testcases", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.column "html", :text, :default => "", :null => false
      t.column "action", :text, :default => "", :null => false
      t.column "target", :text, :default => "", :null => false
      t.column "text", :text
      t.column "slop", :text
    end

    # ----------------------------------------------------------------------
    # usage logs

    create_table "procedure_executes", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.column "procedure_id", :integer, :default => 0, :null => false
      t.column "person_id", :integer, :default => 0, :null => false
      t.column "executed_at", :datetime, :null => false
    end
    execute "ALTER TABLE procedure_executes ADD CONSTRAINT fk_procedure_executes_procedure_id FOREIGN KEY (procedure_id) REFERENCES procedures(id);"
    execute "ALTER TABLE procedure_executes ADD CONSTRAINT fk_procedure_executes_person_id FOREIGN KEY (person_id) REFERENCES people(id);"

    create_table "procedure_views", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.column "procedure_id", :integer, :default => 0, :null => false
      t.column "person_id", :integer, :default => 0, :null => false
      t.column "viewed_at", :datetime, :null => false
    end
    execute "ALTER TABLE procedure_views ADD CONSTRAINT fk_procedure_views_procedure_id FOREIGN KEY (procedure_id) REFERENCES procedures(id);"
    execute "ALTER TABLE procedure_views ADD CONSTRAINT fk_procedure_views_person_id FOREIGN KEY (person_id) REFERENCES people(id);"

    create_table "usage_logs", :force => true, :options => "ENGINE=MyISAM" do |t|
      t.column "person_id", :integer, :default => 0, :null => false
      t.column "procedure_id", :integer
      t.column "created_at", :datetime, :null => false
      t.column "event", :integer, :default => 0, :null => false
      t.column "extra", :text
    end
    execute "ALTER TABLE usage_logs ADD CONSTRAINT fk_usage_logs_procedure_id FOREIGN KEY (procedure_id) REFERENCES procedures(id);"
    execute "ALTER TABLE usage_logs ADD CONSTRAINT fk_usage_logs_person_id FOREIGN KEY (person_id) REFERENCES people(id);"

  end

  def self.down
  end
end
