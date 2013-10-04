require 'find'
require 'ftools'

namespace :db do  
  desc "Backup the database to a file. Options: DIR=base_dir RAILS_ENV=production MAX=20" 
  task :backup => [:environment] do
    RAILS_ENV = ENV["RAILS_ENV"] || "production"
    puts "env: #{RAILS_ENV}"
    datestamp = Time.now.strftime("%Y-%m-%d_%H-%M-%S")    
    base_path = ENV["DIR"] || "db" 
    backup_folder = File.join(base_path, 'backup')
    backup_file = File.join(backup_folder, "#{datestamp}_dump.sql.gz")    
    File.makedirs(backup_folder)    
    db_config = ActiveRecord::Base.configurations[RAILS_ENV]    
    sh "mysqldump -u #{db_config['username']} -p#{db_config['password']} #{db_config['database']} | gzip -c > #{backup_file}"     

    puts "Created backup: #{backup_file}"
    end
end
