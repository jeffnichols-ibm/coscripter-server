# (C) Copyright IBM Corp. 2007
class Utf8Encoding < ActiveRecord::Migration
  def self.up
    # Note: "utf8" works for mysql only; postgres uses "unicode"
    execute "alter table people charset=utf8";
    execute "alter table procedures charset=utf8";
    execute "alter table administrators charset=utf8";
    execute "alter table best_bets charset=utf8";
    execute "alter table changes charset=utf8";
    execute "alter table people charset=utf8";
    execute "alter table procedure_comments charset=utf8";
    execute "alter table procedure_executes charset=utf8";
    execute "alter table procedure_views charset=utf8";
    execute "alter table procedures charset=utf8";
    execute "alter table ratings charset=utf8";
    execute "alter table schema_migrations charset=utf8";
    execute "alter table sessions charset=utf8";
    execute "alter table site_usage_logs charset=utf8";
    execute "alter table tags charset=utf8";
    execute "alter table testcases charset=utf8";
    execute "alter table usage_logs charset=utf8";
    execute "alter table user_datas charset=utf8";
  end

  def self.down
  end
end
