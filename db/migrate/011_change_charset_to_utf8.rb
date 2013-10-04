# (C) Copyright IBM Corp. 2007
class ChangeCharsetToUtf8 < ActiveRecord::Migration
  def self.up
    # NOTE only works on mysql!

    # procedures table
    execute "drop index FullText_Procedures_title_body ON procedures"
    execute "alter table procedures modify title text character set utf8"
    execute "alter table procedures modify body text character set utf8"
    execute "create fulltext index FullText_Procedures_title_body on procedures (title, body)"

    # procedure comments
    execute "alter table procedure_comments modify comment text character set utf8"

    # people
    execute "alter table people modify email varchar(255) character set utf8"
    execute "alter table people modify name text character set utf8"

    # changes
    execute "alter table changes modify body text character set utf8"
    execute "alter table changes modify title varchar(255) character set utf8"

    # tags
    execute "alter table tags modify raw_name varchar(255) character set utf8"
    execute "alter table tags modify clean_name varchar(255) character set utf8"

    # testcases
    execute "alter table testcases modify html text character set utf8"
    execute "alter table testcases modify action text character set utf8"
    execute "alter table testcases modify target text character set utf8"
    execute "alter table testcases modify text text character set utf8"
    execute "alter table testcases modify slop text character set utf8"

    # user data
    execute "alter table user_datas modify name varchar(255) character set utf8"
    execute "alter table user_datas modify value text character set utf8"
  end

  def self.down
  end
end
