# (C) Copyright IBM Corp. 2007
class RestoreNotnullSettingsToDb < ActiveRecord::Migration
  # The last migration erroneously discarded not-null constraints on
  # various columns.  Put them back in.
  def self.up
    execute "alter table changes modify body text not null"
    execute "alter table people modify email varchar(255) not null default ''"
    execute "alter table people modify name text not null"
    execute "alter table procedure_comments modify comment text not null"
    execute "alter table procedures modify title text not null"
    execute "alter table tags modify raw_name varchar(255) not null default ''"
    execute "alter table tags modify clean_name varchar(255) not null default ''"
    execute "alter table testcases modify html text not null"
    execute "alter table testcases modify action text not null"
    execute "alter table testcases modify target text not null"
    execute "alter table testcases modify html text not null"
    execute "alter table usage_logs modify extra text character set utf8"
    execute "alter table usage_logs modify version varchar(255) character set utf8 default null"
    execute "alter table user_datas modify name varchar(255) not null"
  end

  def self.down
  end
end
