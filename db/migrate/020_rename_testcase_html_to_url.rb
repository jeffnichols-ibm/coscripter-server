class RenameTestcaseHtmlToUrl < ActiveRecord::Migration
  def self.up
    rename_column("testcases", "html", "url")
  end

  def self.down
    rename_column("testcases", "url", "html")
  end
end
